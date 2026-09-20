# Development Progress

## Current
- Branch: `dev`
- Version: `0.3.7-dev`
- Goal: Refine the pfUI TankIcons options-page presentation while preserving existing behaviour.

## Recent Commits
- `075b14f` — increase only the pfUI TankIcons page-title font by +2 px relative to pfUI's configured font size.
- `43abaf0` — refine TankIcons options layout using native pfUI header/spacer widgets.
- `33b7577` — record options layout refinement.
- `6595c81` — migrate TankIcons naming, locales, and version metadata.
- `53b7984` — adopt VanillaTemplate development workflow.
- Stable baseline: `main` at `1ee31b3` / `0.3.6`.

## Completed / Verified
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
- Page title now keeps pfUI's native header styling but uses only a +2 px font-size increase; this latest title-size change awaits in-game visual confirmation.

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
- Run the in-game migration/options-layout test above.
- If it passes, mark `0.3.7-dev` user tested.
- Promote to stable `0.3.7` on `main` only after explicit user confirmation.

## Ideas / Backlog
- Additional locale translations can be added later if wanted.

## Deferred
- Tank assignment logic changes.
- Communication protocol changes.
- Frame discovery/compatibility fallback refactors.
- SavedVariables changes.
- Addon-owned artwork; none is currently needed.
- `Debug.lua`; add only if a development need arises.

## Exact Next Step
Reload the current `0.3.7-dev` build and confirm the `pfUI TankIcons` page title is appropriately larger without affecting any other option text. If it looks right, continue with the remaining icon display/justification migration test before release.
