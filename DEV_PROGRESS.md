# Development Progress

## Current
- Branch: `dev`
- Version: `0.3.7-dev` (current TOC state; bump to `0.3.8-dev` before runtime implementation of the performance rewrite).
- Development head before this planning update: `be0e51f02f5590ac8df3409188d0a405cc4e0176`.
- Handoff head: the current `dev` commit containing this file; its exact SHA is reported with the planning-update result because a commit cannot embed its own SHA.
- Stable baseline: `0.3.7` on `main` at `9274af7e8e007b863fb8b148b6630004d6dc9e12`.
- Goal: Replace the continuous 0.20-second tank-state watcher with event/action-driven synchronization and a one-shot 1-second roster resolver, preserving existing TankIcons behaviour and protocol semantics.
- Current scope boundary: Design is agreed and documented. No runtime code has been changed yet for this rewrite.

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
- Upstream pfUI `shagu/pfUI` `modules/raid.lua` was inspected during planning (master blob `5aaca7c8fa5d89b79afeb8692b907ea1fc9d89ff`).
- pfUI defines `PF_TANK_TOGGLE` in `pfUI.uf.raid.tanksfirst`.
- pfUI installs a `hooksecurefunc("UnitPopup_OnClick", ...)` callback.
- Inside that callback, when the clicked popup entry belongs to `pfUI.uf.raid.tanksfirst` and has a name, pfUI performs:
  - `pfUI.uf.raid.tankrole[name] = not pfUI.uf.raid.tankrole[name]`;
  - then `pfUI.uf.raid:Show()`.
- The toggle is inline rather than exposed as a narrower named pfUI setter function.
- Therefore the likely TankIcons integration is a later/post hook on the same popup action, but implementation must first verify pfUI module execution order and the Vanilla `hooksecurefunc` chaining/order semantics so TankIcons reliably observes the already-updated value rather than assuming hook order.

### Active Decisions
- GUI remains under `pfUI -> Thirdparty -> TankIcons`.
- The page header remains `pfUI TankIcons`, uses pfUI's native header widget, is +2 px over the configured pfUI font size, and is top-aligned.
- Options remain ordered: sync first, then Group, Raid, and Raid Tab sections separated with native pfUI spacers.
- Group/Raid frame justification supports the nine current anchor positions; Raid Tab supports left/centre/right.
- Additional locale translations are optional future work, not current scope.
- This rewrite is a performance/dispatch refactor, not a protocol redesign or UI redesign.

## Recent Relevant Commits
- Current planning commit — document the agreed event-driven performance rewrite and one-second roster batching model; documentation only.
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
- None for the performance rewrite. It is design-only at this handoff.

## Static / Automated Checks
- Prior `0.3.7` migration/release checks confirmed locale load order, localized GUI labels, metadata-based version lookup, stable TOC metadata, development files absent from `main`, and final menu/title code present.
- Workflow migration was documentation-only.
- Performance-rewrite planning verified the actual upstream pfUI tank-toggle implementation in `modules/raid.lua`; implementation and runtime behaviour have not yet changed.

## Current Issues
- Continuous 0.20-second polling is unnecessary for the actual ownership model: pfUI owns local tank toggles, while TankIcons itself owns remote synchronized mutations. The watcher therefore performs permanent background work to rediscover state changes whose mutation paths can be observed directly.
- The remaining implementation question is hook ordering/chaining: confirm TankIcons can attach to the pfUI popup-toggle path such that it reads the state after pfUI's inline toggle.
- No known functional defect exists in stable `0.3.7`; this is a performance rewrite intended to reduce cumulative addon background machinery.

## Testing

### Last Runtime Test
- Version/commit: `0.3.7-dev` at `980adba5a54264887caeb3aafa23d908fcb71a8b`.
- Passed: User confirmed the current build stable and approved release.
- Failed: None recorded.
- Not tested: The planned performance rewrite has not been implemented.

### Next Runtime Test
After the rewrite is implemented and statically checked, exercise the new `0.3.8-dev` delta in WoW 1.12.1:
- login/reload with pfUI present: no Lua errors and icons initialize correctly;
- local pfUI `Toggle as Tank` on/off: TankIcons sees the post-toggle state immediately, updates icons, and sends exactly the expected sync change;
- remote TankIcons toggle message: authoritative remote changes apply immediately and update icons without any polling watcher;
- non-authoritative/invalid remote messages remain rejected exactly as before;
- burst several raid/party roster changes inside one second and confirm they produce one delayed resolver, not one refresh per event and not a sliding/resetting deadline;
- trigger a new roster change after the previous resolver fires and confirm it schedules a fresh one-second resolver;
- verify Group, Raid, and Raid Tab icon visibility/justification remain unchanged;
- verify idle operation has no permanent TankIcons state-watcher `OnUpdate` loop.

## Planned / Next Work
- Verify the Vanilla/pfUI `hooksecurefunc` chaining and pfUI module execution order around `UnitPopup_OnClick`.
- Choose the narrowest reliable post-toggle integration that observes pfUI's already-mutated `tankrole[name]` without modifying pfUI itself.
- Bump `dev` TOC metadata to `0.3.8-dev` immediately before the runtime rewrite.
- Remove the 0.20-second observed-state watcher machinery.
- Route local pfUI toggle detection directly into the existing send/update path.
- Keep `CHAT_MSG_ADDON` remote application immediate.
- Replace immediate roster-event refresh churn with the agreed fixed-window one-second resolver.
- Perform static Lua 5.0/API review, then the focused runtime test above.

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
Inspect pfUI's Vanilla `hooksecurefunc` implementation and module initialization/execution order to prove how a TankIcons hook on the `PF_TANK_TOGGLE` / `UnitPopup_OnClick` path can reliably run after pfUI's inline `tankrole[name]` mutation. Do not implement the rewrite until that ordering is established. Once established, bump the TOC to `0.3.8-dev` and implement the event-driven watcher removal plus fixed one-second roster resolver as one coherent runtime change.
