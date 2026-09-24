# Development Progress

## Current
- Branch: `dev`
- Version: `0.3.7-dev`
- Development head before this documentation-only migration: `f855a5cad94753f6868fc1947dc74632c2934de6`.
- Handoff head: the current `dev` commit containing this file; its exact SHA is reported with the migration result because a commit cannot embed its own SHA.
- Stable baseline: `0.3.7` on `main` at `9274af7e8e007b863fb8b148b6630004d6dc9e12`.
- Goal: No active runtime implementation work. Keep the released `0.3.7` behaviour stable and reopen development only for a defined new requirement or pfUI compatibility change.
- Current scope boundary: Documentation/workflow migration only; do not change addon runtime behaviour as part of this migration.

## Current Design / Development Contract

### Architecture / Ownership
- Runtime is a small pfUI plugin: `locales/enUS.lua` loads before the single runtime file `pfUI_TankIcons.lua`.
- Technical addon/folder identity remains `pfUI_TankIcons`; user-facing name is `pfUI TankIcons`.
- Register as pfUI module `tankicons`; pfUI remains the authoritative owner of tank-role state through `pfUI.uf.raid.tankrole`.
- Store settings in pfUI's configuration database under the `tankicons` module. The addon owns no SavedVariables.
- Discover pfUI group/raid unit frames primarily through `pfUI.uf.frames`; retain the `pfGroup*` / `pfRaid*` global-name fallbacks for older or forked pfUI builds.
- Blizzard Raid-tab icons are attached to `RaidGroupButton1..40`; pfUI unit-frame icons use a child holder above the frame so pfUI child frames do not cover the marker.
- No TOC dependency is declared. Register immediately when pfUI is already present, otherwise wait for `ADDON_LOADED`; remain inert if pfUI is absent.

### Invariants
- TankIcons reflects and synchronizes pfUI's existing tank assignments; it must not introduce a competing tank-role state store or assignment system.
- Preserve current group-frame, raid-frame and Blizzard Raid-tab icon visibility/justification behaviour unless a future requirement explicitly changes it.
- Preserve optional tank-role sync semantics unless protocol work is explicitly in scope.
- Remote tank changes must be accepted only from an authoritative current group member and only for a current group member.
- Raid authority is raid leader > raid assistant > ordinary member; party authority is party leader only.
- The external tank-role watcher exists because raw writes to `pfUI.uf.raid.tankrole` have no event; its current 0.20-second observation cadence is product behaviour and must not be changed casually.
- User-facing addon-owned strings remain localized through `pfUI_TankIcons_L`.
- Version comes from `pfUI_TankIcons.toc` via `GetAddOnMetadata("pfUI_TankIcons", "Version")`.

### Protocol / Data Model
- Addon-message prefix: `PFTI`.
- Tank-change payload: `T:<0|1>:<name>`.
- Transport channel: `RAID` when raided, otherwise `PARTY` when grouped; no transmission while solo.
- Sync is controlled by pfUI config key `sync_enabled`.
- Local sends require local authority and a target name currently in the group.
- Remote receives require sync enabled, an authoritative sender, a valid payload, and a target name currently in the group.
- Received changes mutate the authoritative `pfUI.uf.raid.tankrole` table and refresh displayed icons.

### Active Decisions
- GUI remains under `pfUI -> Thirdparty -> TankIcons`.
- The page header remains `pfUI TankIcons`, uses pfUI's native header widget, is +2 px over the configured pfUI font size, and is top-aligned.
- Options remain ordered: sync first, then Group, Raid, and Raid Tab sections separated with native pfUI spacers.
- Group/Raid frame justification supports the nine current anchor positions; Raid Tab supports left/centre/right.
- Additional locale translations are optional future work, not current scope.

## Recent Relevant Commits
- Current migration commit — adopt the current VanillaTemplate `dev_rulebook.md`, centralize live project state here, and remove `DEV_GUIDE.md`; documentation only.
- `f855a5c` — mark pfUI TankIcons complete after the `0.3.7` release.
- `9274af7` (`main`) — release stable `0.3.7`.
- `838e7c7` — record user approval of the current `0.3.7-dev` build for release.
- `980adba` — top-align the enlarged options-page title; this was the final runtime-changing dev commit before release approval.

## Completed / User-Verified
- User explicitly confirmed the `0.3.7-dev` build at `980adba5a54264887caeb3aafa23d908fcb71a8b` as stable and approved promotion.
- Stable `0.3.7` was released to `main` at `9274af7e8e007b863fb8b148b6630004d6dc9e12`.
- User-facing naming was normalized to `pfUI TankIcons` while preserving technical identity `pfUI_TankIcons`.
- Addon-owned GUI strings were moved to `locales/enUS.lua`; the TOC loads the locale before the runtime Lua file.
- Runtime version lookup uses TOC metadata rather than a separately hardcoded Lua version.
- Options-page presentation was refined with pfUI native header/spacer widgets, sync-first ordering, Group -> Raid -> Raid Tab grouping, and the approved title sizing/alignment.
- Existing tank icon rendering, justification, and synchronization behaviour was preserved through the `0.3.7` release.

## Implemented / Awaiting Runtime Test
- None. This workflow migration changes documentation only.

## Static / Automated Checks
- Prior `0.3.7` migration review confirmed locale load order, localized GUI labels, metadata-based version lookup, and clean derivation from the prior stable `0.3.6` baseline.
- Stable release verification confirmed stable TOC title/version, no `-dev` marker on `main`, development status files absent from the release tree, locale present, and the final menu/title presentation code included.
- This workflow migration was reviewed to ensure only development documentation changes: add `dev_rulebook.md`, rewrite `DEV_PROGRESS.md`, delete `DEV_GUIDE.md`.

## Current Issues
- None currently known.
- Historical note removed from active status: the old progress file still named `0.3.6` as the "Last Test" even though later commit `838e7c7` explicitly records user approval of the final `0.3.7-dev` build. The explicit release approval is treated as the authoritative runtime state.

## Testing

### Last Runtime Test
- Version/commit: `0.3.7-dev` at `980adba5a54264887caeb3aafa23d908fcb71a8b`.
- Passed: User confirmed the current build stable and approved release.
- Failed: None recorded.
- Not tested: The documentation-only commits after `980adba` do not alter runtime behaviour; no separate runtime test is required for this migration.

### Next Runtime Test
- None while the project remains complete.
- If future runtime work begins, test only the new delta against stable `0.3.7`, plus any adjacent behavior that the change could affect.

## Planned / Next Work
- None.
- For a future development cycle, define the requested scope first and bump `dev` to the appropriate next `-dev` version before runtime implementation.

## Deferred / Out of Scope
- Compatibility changes required by future pfUI tank-toggle implementation changes.
- Tank assignment logic changes.
- Communication protocol changes.
- Frame discovery or compatibility-fallback refactors.
- SavedVariables changes.
- Additional locale translations.
- Addon-owned artwork; none is currently needed.
- `Debug.lua`; add only if a concrete future development need arises.

## Release / Promotion Notes
- Main-only or release-only content to preserve: stable TOC Title/Version metadata; `main` currently intentionally omits live development/status documentation.
- Stable `main` baseline is `0.3.7` at `9274af7e8e007b863fb8b148b6630004d6dc9e12`.
- Known validation debt accepted for release: None recorded.
- External/runtime prerequisites: pfUI is required for functionality. The addon has no TOC dependency and safely remains inert when pfUI is unavailable.

## Exact Next Step
None. The project is complete at stable `0.3.7`. Reopen development only when a concrete new requirement or pfUI compatibility change is defined; at that point verify the actual `dev` and `main` heads, define scope, and bump the development version before changing runtime code.
