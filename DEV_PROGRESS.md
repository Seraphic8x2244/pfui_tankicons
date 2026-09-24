# Development Progress

## Current
- Branch: `dev`
- Version: `0.3.8-dev`.
- Runtime implementation commit: `594643f8f5586817e8a7a98c5772f21f4c913d8e`.
- Handoff head: the current `dev` commit containing this file; its exact SHA is reported with the status-update result because a commit cannot embed its own SHA.
- Stable baseline: `0.3.7` on `main` at `9274af7e8e007b863fb8b148b6630004d6dc9e12`.
- Goal: Runtime-validate the completed event-driven performance rewrite against the stable `0.3.7` behaviour.
- Current scope boundary: The rewrite is implemented and statically checked, including a real Lua 5.0.2 compiler pass. It remains untested in WoW 1.12.1 and must not be promoted until the focused runtime test passes and the user explicitly accepts it.

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
  - `observedTankState`;
  - `observedSeen`;
  - `RefreshObservedTankState()`;
  - `CheckObservedTankState()`;
  - the permanent watcher frame/`OnUpdate` loop.
- Local pfUI tank toggles become action-driven:
  - detect the pfUI tank-toggle action;
  - run after pfUI has changed `pfUI.uf.raid.tankrole[name]`;
  - read the resulting boolean state directly;
  - call the existing TankIcons send/update path immediately.
- Remote TankIcons changes remain event-driven through `CHAT_MSG_ADDON` / `ApplyRemoteTankChange()`; no watcher is needed because TankIcons itself owns this mutation path.
- `RAID_ROSTER_UPDATE` and `PARTY_MEMBERS_CHANGED` should no longer trigger repeated immediate reconciliation. They queue one roster resolve exactly one second after the first event in the current batch.
- While that one-second resolver is pending, further roster events do not create another timer and do not push the existing deadline later.
- When the resolver fires, perform one settled-state refresh/reconciliation using the then-current roster/state and disable the temporary timer.
- If another roster event occurs after that resolver has fired (for example at T+1.1s), queue a new resolve for one second later (T+2.1s in that example).
- `PLAYER_ENTERING_WORLD` remains an initialization concern; preserve correct initial icon/state population without reintroducing continuous polling.
- Expected idle behaviour after the rewrite: no TankIcons frame-time polling. Work occurs only on actual tank-toggle actions, addon messages, initialization, relevant UI/frame refresh hooks, or a pending one-shot roster resolver.

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
- Current status commit — record the successful Lua 5.0.2 compiler pass; documentation only.
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
- `0.3.8-dev` at `594643f8f5586817e8a7a98c5772f21f4c913d8e` implements the performance rewrite.
- Removed `observedTankState`, `observedSeen`, `RefreshObservedTankState()`, `CheckObservedTankState()`, and the permanent 0.20-second watcher `OnUpdate`.
- Local `PF_TANK_TOGGLE` actions are observed through a later `UnitPopup_OnClick` post-hook; TankIcons reads pfUI's resulting state, sends through the existing authority/sync path, and refreshes icons immediately.
- Remote `PFTI` changes remain immediate through `CHAT_MSG_ADDON` / `ApplyRemoteTankChange()`; the remote path directly mutates pfUI's authoritative `tankrole` table and refreshes icons.
- `RAID_ROSTER_UPDATE` and `PARTY_MEMBERS_CHANGED` now queue a fixed one-second resolver from the first event in the batch. Later events while pending do not move the deadline.
- The roster resolver installs `OnUpdate` only while pending, clears the script before performing the resolve, and can then be queued again by a later roster event.

## Static / Automated Checks
- Prior `0.3.7` migration/release checks confirmed locale load order, localized GUI labels, metadata-based version lookup, stable TOC metadata, development files absent from `main`, and final menu/title code present.
- Hook ordering was verified against both upstream Vanilla pfUI and the current brues pfUI + ClassicAPI implementation as documented above.
- Implementation diff from `d2b1e20` to `594643f` changes only `pfUI_TankIcons.lua` and `pfUI_TankIcons.toc` (runtime: +55/-80 lines; TOC: version only).
- Static source review confirms the old observed-state symbols/watcher are absent, `0.3.8-dev` metadata is present, the local toggle path is narrowed to `PF_TANK_TOGGLE`, and the only new TankIcons `OnUpdate` is the temporary roster resolver that removes its own script before resolving.
- Lua 5.0/API compatibility was reviewed manually; no modern Lua syntax or new WoW API dependency was introduced.
- VanillaTemplate's canonical `tools/lua50/check_lua50.sh` was run against the exact `594643f` TankIcons Lua inputs. The runtime blob `de460d539dcc6208b9b29e0066d18b1632534f1d` and locale blob `4795dd369b3d25db4161cc8260dcb6a4cd40b81c` were hash-verified before the check; GitHub Actions run `36006885763` / job `107657212356` completed successfully with `Lua 5.0.2 syntax check passed: 2 file(s).`
- No in-game runtime claim is made by these checks.

## Current Issues
- No known functional defect exists in stable `0.3.7`.
- The `0.3.8-dev` rewrite has a partial runtime pass. Manual pfUI tank toggling and group-frame display are working, with no reported failure so far. Remaining runtime risk is cross-client sync authority handling, 40-man/fixed-window roster batching, full raid/Raid Tab coverage, and continued idle observation.

## Testing

### Current Runtime Test
- Version/commit: `0.3.8-dev` runtime at `594643f8f5586817e8a7a98c5772f21f4c913d8e`.
- Passed so far: manual pfUI `Toggle as Tank` on/off updates the TankIcons group-frame marker immediately with no reported error; a SoloCraftBots-driven external tank-state change also appeared correctly on the group frame; current icon positioning appears unchanged.
- Pending: two-client authoritative/non-authoritative sync validation; 40-man raid/roster burst validation of the fixed one-second resolver; continued idle/runtime observation; full Raid/Raid Tab confirmation during raid testing.
- Failed: None reported so far.

### Last Completed Runtime Test
- Version/commit: `0.3.7-dev` at `980adba5a54264887caeb3aafa23d908fcb71a8b`.
- Passed: User confirmed the current build stable and approved release.
- Failed: None recorded.

### Next Runtime Test
Exercise the statically checked `0.3.8-dev` delta in WoW 1.12.1:
- login/reload with pfUI present: no Lua errors and icons initialize correctly;
- local pfUI `Toggle as Tank` on/off: TankIcons sees the post-toggle state immediately, updates icons, and sends exactly the expected sync change;
- remote TankIcons toggle message: authoritative remote changes apply immediately and update icons without any polling watcher;
- non-authoritative/invalid remote messages remain rejected exactly as before;
- burst several raid/party roster changes inside one second and confirm they produce one delayed resolver, not one refresh per event and not a sliding/resetting deadline;
- trigger a new roster change after the previous resolver fires and confirm it schedules a fresh one-second resolver;
- verify Group, Raid, and Raid Tab icon visibility/justification remain unchanged;
- verify idle operation has no permanent TankIcons state-watcher `OnUpdate` loop.

## Planned / Next Work
- Run the documented focused `0.3.8-dev` runtime test.
- If runtime behaviour passes, record the exact tested commit and user acceptance before preparing stable promotion.
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
- Do not promote the performance rewrite until the focused `0.3.8-dev` runtime test is complete and the user explicitly accepts it.

## Exact Next Step
Continue the focused `0.3.8-dev` runtime test at `594643f8f5586817e8a7a98c5772f21f4c913d8e`: test authoritative two-client sync and non-authoritative rejection, then use a 40-man raid/roster-change burst to validate the fixed one-second resolver and a fresh post-resolve window. Confirm Raid/Raid Tab visuals and keep watching for idle/runtime errors. Do not promote until the remaining checks pass and the user explicitly accepts this exact runtime delta.
