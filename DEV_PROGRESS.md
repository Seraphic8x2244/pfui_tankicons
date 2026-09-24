# Development Progress

## Current
- Branch: `dev`
- Version: `0.3.9-dev`.
- Runtime implementation commit: `0f73ffab2315cfde250a99266a5a020462a3b017`.
- Handoff head: the current `dev` commit containing this file; its exact SHA is reported with the status-update result because a commit cannot embed its own SHA.
- Stable baseline: `0.3.7` on `main` at `9274af7e8e007b863fb8b148b6630004d6dc9e12`.
- Goal: Runtime-validate the event-driven performance rewrite while preserving broadcast of pfUI tank-role changes made directly by other addons such as SoloCraftBots.
- Current scope boundary: `0.3.9-dev` is implemented and statically checked, including a real Lua 5.0.2 compiler pass. The `0.3.8-dev` runtime test exposed a direct-writer broadcast regression; `0.3.9-dev` fixes that path without restoring permanent polling and now requires focused in-game retesting before any promotion.

## Current Design / Development Contract

### Architecture / Ownership
- Runtime is a small pfUI plugin: `locales/enUS.lua` loads before the single runtime file `pfUI_TankIcons.lua`.
- Technical addon/folder identity remains `pfUI_TankIcons`; user-facing name is `pfUI TankIcons`.
- Register as pfUI module `tankicons`; pfUI remains the authoritative owner of tank-role state through `pfUI.uf.raid.tankrole`.
- TankIcons does not provide its own tank-assignment UI or competing tank-role state. It displays pfUI's state and communicates pfUI tank-toggle changes to other TankIcons users.
- Store settings in pfUI's configuration database under the `tankicons` module. The addon owns no SavedVariables.
- Discover pfUI group/raid unit frames primarily through `pfUI.uf.frames`; retain the `pfGroup*` / `pfRaid*` global-name fallbacks for older or forked pfUI builds.
- Blizzard Raid-tab icons are attached to `RaidGroupButton1..40`; pfUI unit-frame icons use a child holder above the frame so pfUI child frames do not cover the marker.
- No TOC dependency is declared. Register immediately when pfUI is already present, otherwise wait for `ADDON_LOADED`; remain inert if pfUI is absent.

### Invariants
- TankIcons reflects and synchronizes pfUI's existing tank assignments; it must not introduce a competing tank-role state store or assignment system.
- Preserve current group-frame, raid-frame and Blizzard Raid-tab icon visibility/justification behaviour unless a future requirement explicitly changes it.
- Preserve current `PFTI` communication format, authority checks, sync toggle, and remote-apply semantics during the performance rewrite.
- Remote tank changes must be accepted only from an authoritative current group member and only for a current group member.
- Raid authority is raid leader > raid assistant > ordinary member; party authority is party leader only.
- Local pfUI tank toggles and remote TankIcons sync changes should remain immediate; only roster-driven reconciliation is intentionally delayed/batched.
- Roster batching must be a fixed one-second window, not a reset-on-every-event debounce: the first roster event queues one resolve for T+1s; additional roster events while that resolve is pending are absorbed without moving the deadline; an event after the resolve starts a new one-second window.
- The rewrite should leave no permanent TankIcons `OnUpdate` polling loop. A temporary timer/resolver may use `OnUpdate` only while a roster resolve is pending, then disable itself after firing.
- User-facing addon-owned strings remain localized through `pfUI_TankIcons_L`.
- Version comes from `pfUI_TankIcons.toc` via `GetAddOnMetadata("pfUI_TankIcons", "Version")`.

### Protocol / Data Model
- Addon-message prefix: `PFTI`.
- Tank-change payload: `T:<0|1>:<name>`.
- Transport channel: `RAID` when raided, otherwise `PARTY` when grouped; no transmission while solo.
- Sync is controlled by pfUI config key `sync_enabled`.
- Local sends require local authority and a target name currently in the group.
- Remote receives require sync enabled, an authoritative sender, a valid payload, and a target name currently in the group.
- Received changes mutate the authoritative `pfUI.uf.raid.tankrole` table and refresh displayed icons immediately.

### Performance Rewrite Design
- Remove the continuous 0.20-second external tank-state polling machinery:
  - no permanent watcher frame/`OnUpdate` loop;
  - no periodic whole-roster `CheckObservedTankState()`;
  - no `observedSeen` scratch table maintained on a frame-time cadence.
- Retain only lightweight per-name `observedTankState` memory so supported direct writers of `pfUI.uf.raid.tankrole` can still be detected without polling.
- Direct tank-table changes are observed only at existing action/event boundaries:
  - pfUI `RefreshUnit` hooks call `UpdatePfUIFrame()`, which compares that frame member's current tank state against `observedTankState`;
  - normal TankIcons `UpdateAll()` passes reuse the same tracked-frame comparison;
  - a newly seen true state is broadcast because another addon may have marked the member before TankIcons first observed it;
  - a newly seen false state is baseline only and is not broadcast.
- Local pfUI tank toggles remain action-driven through the later `UnitPopup_OnClick` post-hook, but now use the same observation function as direct writers. This makes refresh-before-hook and hook-before-refresh both converge on exactly one send.
- Remote TankIcons changes remain event-driven through `CHAT_MSG_ADDON` / `ApplyRemoteTankChange()`; the observed state is updated before `UpdateAll()` so accepted remote changes are not echoed back.
- `RefreshObservedTankState()` is initialization-only, establishing a baseline at module start / `PLAYER_ENTERING_WORLD`; it is not a timer.
- `PruneObservedTankState()` runs only in the already-batched roster resolver so departed names do not leave stale baselines.
- `RAID_ROSTER_UPDATE` and `PARTY_MEMBERS_CHANGED` queue one roster resolve exactly one second after the first event in the current batch.
- While that one-second resolver is pending, further roster events do not create another timer and do not push the existing deadline later.
- When the resolver fires, prune departed observed names, perform one settled-state refresh/reconciliation, and disable the temporary timer.
- If another roster event occurs after that resolver has fired (for example at T+1.1s), queue a new resolve for one second later (T+2.1s in that example).
- Expected idle behaviour remains: no permanent TankIcons frame-time polling. Work occurs only on actual tank-toggle actions, addon messages, initialization, existing pfUI/UI refresh hooks, or a pending one-shot roster resolver.

### Verified pfUI Integration Point
- Upstream Vanilla pfUI `shagu/pfUI` was inspected directly:
  - `compat/vanilla.lua` blob `abc817a5c4f51790b6fa1532ccf15f6afc22410a` implements `hooksecurefunc` by capturing the function currently installed in the target slot as `old`; without `prepend`, the wrapper calls `old` first and the new callback second.
  - `modules/raid.lua` blob `5aaca7c8fa5d89b79afeb8692b907ea1fc9d89ff` installs its own `UnitPopup_OnClick` post-hook and mutates `pfUI.uf.raid.tankrole[name]` inline before returning.
  - Therefore a later hook on the same global necessarily executes after pfUI's mutation: the later wrapper calls the already-wrapped pfUI function first, then TankIcons.
- The current `brues-code/pfUI` / ClassicAPI path was also verified:
  - `brues-code/pfUI` `modules/raid.lua` blob `f4022de63247f1da7475041042653a44d9fb6ae9` uses the same inline tank toggle and post-hook design.
  - ClassicAPI `src/HookSecureFunc.cpp` blob `85e839eebaf63c538b704fb5a1f01aaeb7c4e510` implements the same chaining semantics: each hook captures the current function as `orig`, calls `orig` first, then invokes the new callback.
  - `pfUI_ClassicAPI.toc` loads `pfUI.lua` before `init/modules.xml`; module files register callbacks while `pfUI.bootup` is true, and pfUI's `ADDON_LOADED` handler executes registered modules before clearing `bootup`. A module registered after boot is loaded immediately.
- TankIcons therefore does not assume addon/event callback ordering. `HookTankToggle()` attaches only when `pfUI.uf.raid.tanksfirst` already exists. Module execution is synchronous, so if a separately executing TankIcons module can see that table, pfUI's raid module has completed and its hook is already installed. If TankIcons executes before the raid module, it does not hook; later event handling retries, with `PLAYER_ENTERING_WORLD` providing a guaranteed post-boot opportunity before the player can use the popup toggle.
- This establishes the required ordering without modifying pfUI and without reintroducing polling.
### Active Decisions
- GUI remains under `pfUI -> Thirdparty -> TankIcons`.
- The page header remains `pfUI TankIcons`, uses pfUI's native header widget, is +2 px over the configured pfUI font size, and is top-aligned.
- Options remain ordered: sync first, then Group, Raid, and Raid Tab sections separated with native pfUI spacers.
- Group/Raid frame justification supports the nine current anchor positions; Raid Tab supports left/centre/right.
- Additional locale translations are optional future work, not current scope.
- This rewrite is a performance/dispatch refactor, not a protocol redesign or UI redesign.

## Recent Relevant Commits
- Current status commit — record the `0.3.8-dev` runtime regression, the `0.3.9-dev` direct-writer fix, compiler result, and focused retest gate; documentation only.
- `0f73ffa` — bump to `0.3.9-dev` and restore external direct-writer broadcasting through event-driven per-name state observation on existing pfUI/TankIcons refresh boundaries, without restoring permanent polling.
- `702d4a4` — record the partial `0.3.8-dev` runtime pass before the SoloCraftBots broadcast regression was identified; documentation only.
- `594643f` — implement the `0.3.8-dev` event-driven rewrite: remove permanent state polling, hook pfUI tank toggles after pfUI, keep remote sync immediate, and batch roster refreshes in a fixed one-second window.
- `d2b1e20` — document the agreed performance rewrite and one-second roster batching model; documentation only.
- `be0e51f` — migrate development workflow to the current VanillaTemplate rulebook.
- `f855a5c` — mark pfUI TankIcons complete after the `0.3.7` release.
- `9274af7` (`main`) — release stable `0.3.7`.
- `838e7c7` — record user approval of the final `0.3.7-dev` build for release.
- `980adba` — final runtime-changing dev commit before `0.3.7` release approval.

## Completed / User-Verified
- User explicitly confirmed the `0.3.7-dev` build at `980adba5a54264887caeb3aafa23d908fcb71a8b` as stable and approved promotion.
- Stable `0.3.7` was released to `main` at `9274af7e8e007b863fb8b148b6630004d6dc9e12`.
- User-facing naming was normalized to `pfUI TankIcons` while preserving technical identity `pfUI_TankIcons`.
- Addon-owned GUI strings were moved to `locales/enUS.lua`; the TOC loads the locale before the runtime Lua file.
- Runtime version lookup uses TOC metadata rather than a separately hardcoded Lua version.
- Options-page presentation was refined with pfUI native header/spacer widgets, sync-first ordering, Group -> Raid -> Raid Tab grouping, and the approved title sizing/alignment.
- Existing tank icon rendering, justification, and synchronization behaviour was preserved through the `0.3.7` release.

## Implemented / Awaiting Runtime Test
- `0.3.9-dev` at `0f73ffab2315cfde250a99266a5a020462a3b017` contains the current runtime candidate.
- The `0.3.8-dev` rewrite correctly removed the permanent 0.20-second watcher and retained immediate manual pfUI toggle handling, but runtime testing proved that another addon could still write `pfUI.uf.raid.tankrole[name]` directly, update the local icon, and bypass TankIcons' new send path.
- SoloCraftBots `dev` was inspected: `SCB_MarkPfUITank(name)` writes `pfUI.uf.raid.tankrole[name] = true` directly. This exactly explains the observed regression.
- `0.3.9-dev` restores only event-driven state memory:
  - `ObserveTankState(name)` compares the current pfUI tank value to the last observed value and sends only on a real transition, or on a newly observed true value;
  - `UpdatePfUIFrame()` invokes that observer when an existing pfUI unit-frame refresh exposes a direct mutation;
  - manual `PF_TANK_TOGGLE` uses the same observer, preventing duplicate sends regardless of whether pfUI refreshes the frame before or after TankIcons' popup post-hook;
  - accepted remote `PFTI` mutations update the observed value before refreshing, preventing echo;
  - initialization snapshots current state once, and the fixed one-second roster resolver prunes departed names before refreshing.
- The permanent watcher remains absent. The only TankIcons `OnUpdate` remains the temporary roster resolver while a one-second batch is pending.

## Static / Automated Checks
- Prior `0.3.7` migration/release checks confirmed locale load order, localized GUI labels, metadata-based version lookup, stable TOC metadata, development files absent from `main`, and final menu/title code present.
- Hook ordering was verified against both upstream Vanilla pfUI and the current brues pfUI + ClassicAPI implementation as documented above.
- Implementation diff from `d2b1e20` to `594643f` changes only `pfUI_TankIcons.lua` and `pfUI_TankIcons.toc` (runtime: +55/-80 lines; TOC: version only).
- Static source review of `0.3.9-dev` confirms there is still no permanent watcher. `observedTankState` is now event-driven state memory only; the sole TankIcons `OnUpdate` remains the temporary roster resolver that removes its own script before resolving.
- Lua 5.0/API compatibility was reviewed manually; no modern Lua syntax or new WoW API dependency was introduced.
- Baseline `0.3.8-dev`: VanillaTemplate's canonical `tools/lua50/check_lua50.sh` was run against the exact `594643f` TankIcons Lua inputs. Runtime blob `de460d539dcc6208b9b29e0066d18b1632534f1d` and locale blob `4795dd369b3d25db4161cc8260dcb6a4cd40b81c` were hash-verified; Actions run `36006885763` / job `107657212356` passed.
- Current `0.3.9-dev`: the same canonical checker was run against exact commit `0f73ffab2315cfde250a99266a5a020462a3b017`. Runtime blob `ee98b8c00463227d13f5a5515315a96d1cc082d4` and locale blob `4795dd369b3d25db4161cc8260dcb6a4cd40b81c` were hash-verified; Actions run `36041311931` / job `107773878217` completed successfully with `Lua 5.0.2 syntax check passed: 2 file(s).`
- No in-game runtime claim is made for the `0.3.9-dev` fix by these static checks.

## Current Issues
- No known functional defect exists in stable `0.3.7`.
- `0.3.8-dev` runtime testing found one regression: SoloCraftBots automatic tank marking still updated the local TankIcons group-frame icon, but the change was no longer broadcast to other TankIcons users because the rewrite only sent from pfUI's manual popup action.
- `0.3.9-dev` implements the event-driven fix for that regression, has passed the real Lua 5.0.2 compiler gate, and has now passed the focused two-client regression retest for both SoloCraftBots automatic tank marking and manual pfUI tank toggles.
- Runtime validation is now complete on `0.3.9-dev`: automatic/manual comms, 40-man raid operation, Raid Tab display, and extended AQ40/Stratholme observation all passed with no reported regression.

## Testing

### Latest Runtime Result
- Version/commit: `0.3.8-dev` runtime at `594643f8f5586817e8a7a98c5772f21f4c913d8e`.
- Passed: manual pfUI `Toggle as Tank` on/off updated the TankIcons group-frame marker immediately; SoloCraftBots automatic tank marking updated the local group-frame marker; current icon positioning appeared unchanged.
- Failed: SoloCraftBots automatic tank marking did not broadcast the new tank state to other TankIcons users.
- Pending from that test cycle: two-client authoritative/non-authoritative sync validation beyond the reproduced external-writer failure; 40-man raid/roster burst validation; continued idle/runtime observation; full Raid/Raid Tab confirmation.

### Current Candidate Runtime Test
- Version/commit: `0.3.9-dev` at `0f73ffab2315cfde250a99266a5a020462a3b017`.
- Static result: real Lua 5.0.2 compiler pass succeeded.
- Passed: SoloCraftBots automatic tank marking broadcasts correctly to other TankIcons clients; manual pfUI tank toggles broadcast correctly; local markers update correctly; 40-man raid operation works; Blizzard Raid Tab markers/positioning work; no other bad behaviour was observed during the remainder of AQ40 or during Stratholme.
- Failed: None reported on `0.3.9-dev`.
- Runtime status: focused validation is complete for this exact runtime candidate. Promotion still requires explicit user acceptance per the development contract.

### Last Completed Runtime Test
- Version/commit: `0.3.7-dev` at `980adba5a54264887caeb3aafa23d908fcb71a8b`.
- Passed: User confirmed the current build stable and approved release.
- Failed: None recorded.

### Next Runtime Test
No further focused runtime test is currently required for `0.3.9-dev` at `0f73ffab2315cfde250a99266a5a020462a3b017`. The tested candidate passed automatic/manual comms, 40-man raid operation, Raid Tab display, and extended AQ40/Stratholme observation with no reported bad behaviour. Await explicit user acceptance before stable promotion.

## Planned / Next Work
- The SoloCraftBots automatic-tank broadcast regression retest has passed on `0.3.9-dev`.
- Runtime validation is complete for the exact `0.3.9-dev` candidate.
- Await explicit user acceptance, then prepare stable `0.3.9` promotion to `main` while preserving main-only/release-only content.
## Deferred / Out of Scope
- Changes to pfUI itself or a pull request to pfUI.
- Tank assignment logic changes.
- Communication protocol redesign.
- Changes to authority rules.
- Frame discovery or compatibility-fallback refactors unrelated to the watcher removal.
- SavedVariables changes.
- Additional locale translations.
- Addon-owned artwork.
- `Debug.lua` unless concrete instrumentation is needed during this rewrite.

## Release / Promotion Notes
- Main-only or release-only content to preserve: stable TOC Title/Version metadata; `main` intentionally omits live development/status documentation.
- Stable `main` baseline is `0.3.7` at `9274af7e8e007b863fb8b148b6630004d6dc9e12`.
- Known validation debt accepted for release: None recorded.
- External/runtime prerequisites: pfUI is required for functionality. The addon has no TOC dependency and safely remains inert when pfUI is unavailable.
- Do not promote the performance rewrite until `0.3.9-dev` at `0f73ffab2315cfde250a99266a5a020462a3b017` completes the focused runtime test and the user explicitly accepts it.

## Exact Next Step
Obtain explicit user acceptance of `0.3.9-dev` at `0f73ffab2315cfde250a99266a5a020462a3b017`. Once accepted, prepare stable `0.3.9` promotion to `main`, preserving intended release-only/main-only content and excluding live development status files as required.