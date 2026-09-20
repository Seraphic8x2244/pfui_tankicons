# Development Progress

## Current
- Branch: `dev`
- Version: `0.3.7-dev`
- Stable release: `0.3.7` on `main` at `9274af7`.
- Status: Complete.
- Goal: No active implementation work. Revisit only if pfUI's tank-toggle behaviour changes or a new requirement is introduced.

## Recent Commits
- `9274af7` (`main`) — release pfUI TankIcons `0.3.7`.
- `838e7c7` (`dev`) — record `0.3.7` release approval.
- `075b14f` — increase only the pfUI TankIcons page-title font by +2 px relative to pfUI's configured font size.
- `43abaf0` — refine TankIcons options layout using native pfUI header/spacer widgets.
- `33b7577` — record options layout refinement.
- `6595c81` — migrate TankIcons naming, locales, and version metadata.
- `53b7984` — adopt VanillaTemplate development workflow.
- Stable baseline: `main` at `1ee31b3` / `0.3.6`.

## Completed / Verified
- User explicitly confirmed the current `0.3.7-dev` build is stable and approved promotion to `main`.
- Stable `0.3.7` released to `main` at `9274af7`.
- Release verification confirmed: stable TOC title/version, no `-dev` marker, dev-only docs absent from `main`, locale present, and final menu/title presentation code included.
- Created `dev` from the known-good `0.3.6` main release.
- Added `DEV_GUIDE.md` from VanillaTemplate unchanged.
- Added and adopted `DEV_PROGRESS.md`.
- Normalised the user-facing addon name to `pfUI TankIcons`.
- Kept the technical addon/folder identity `pfUI_TankIcons`.
- Added `locales/enUS.lua` and moved addon-owned GUI labels/options into it.
- Updated the TOC to load `locales\enUS.lua` before `pfUI_TankIcons.lua`.
- Replaced the hardcoded Lua version with `GetAddOnMetadata(ADDON_NAME, "Version")`.
- Updated development TOC metadata to `0.3.7-dev` and a `-dev` title.
- Static migration review passed: locale loads first, GUI labels reference the locale table, no hardcoded `0.3.6` Lua version remains, and `dev` is based cleanly on `main`.
- Options-page refinement implemented with pfUI's native `header` widget and `CreateConfig(nil)` spacers.
- User confirmed the options layout looks good before the title-size adjustment.
- Thirdparty entry remains `TankIcons`; page header displays `pfUI TankIcons`.
- Sync option moved to the top and renamed to `Sync Tank Toggle with other pfUI_TankIcons users`.
- Option groups now appear Group -> Raid -> Raid Tab, with one spacer between sections.

## Implemented / Awaiting Test
- Entire `0.3.7-dev` migration and options-layout refinement are implemented and statically checked.
- Page title keeps pfUI's native header styling, uses a +2 px font-size increase, and is top-aligned so the header's remaining height becomes spacing below the title; this latest presentation change awaits in-game visual confirmation.

## Current Issues
- None identified by static review.

## Testing

### Last Test
- Version/commit: stable `0.3.6` / `1ee31b3`
- Passed: Existing stable release baseline.
- Failed: None recorded.
- Not tested: `0.3.7-dev` migration in game.

### Next Test
- Load `0.3.7-dev` in WoW 1.12.1.
- Confirm no Lua errors on login/reload.
- Confirm `pfUI -> Thirdparty -> TankIcons` appears.
- Confirm the page shows a `pfUI TankIcons` header.
- Confirm `Sync Tank Toggle with other pfUI_TankIcons users` is first.
- Confirm the layout is: Group pair, blank line, Raid pair, blank line, Raid Tab pair.
- Confirm all visibility/justification controls and dropdown labels display correctly.
- Confirm at least one assigned tank icon appears on the expected frame.
- Change one icon justification and confirm the icon moves correctly.
- Sync behaviour is unchanged by this migration and only needs retesting if a regression is observed.

## Planned / To-do
- None.
- If it passes, mark `0.3.7-dev` user tested.
- Promote to stable `0.3.7` on `main` only after explicit user confirmation.

## Ideas / Backlog
- Additional locale translations can be added later if wanted.

## Deferred
- Any future compatibility work required by changes to pfUI's tank-toggle implementation.
- Tank assignment logic changes.
- Communication protocol changes.
- Frame discovery/compatibility fallback refactors.
- SavedVariables changes.
- Addon-owned artwork; none is currently needed.
- `Debug.lua`; add only if a future development need arises.

## Exact Next Step
None. Project is complete at stable `0.3.7`. Reopen development only if pfUI changes tank-toggle behaviour or a new requirement is defined.
