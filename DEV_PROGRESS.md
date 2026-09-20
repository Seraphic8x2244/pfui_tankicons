# Development Progress

## Current
- Branch: `dev`
- Version: `0.3.7-dev`
- Goal: Refine the pfUI TankIcons options-page presentation while preserving existing behaviour.

## Recent Commits
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

## Implemented / Awaiting Test
- Entire `0.3.7-dev` migration is implemented and statically checked.
- No in-game verification has yet been performed for the migrated build.

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
- Confirm `pfUI -> Thirdparty -> pfUI TankIcons` appears.
- Confirm all existing visibility/justification/sync controls and dropdown labels display correctly.
- Confirm at least one assigned tank icon appears on the expected frame.
- Change one icon justification and confirm the icon moves correctly.
- Sync behaviour is unchanged by this migration and only needs retesting if a regression is observed.

## Planned / To-do
- Refine the options-page layout per the latest requested grouping/title order.
- Run the in-game migration test above.
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
Adjust the options layout on `dev`: add a small title, move sync to the top and rename it to `Sync Tank Toggle with other pfUI_TankIcons users`, then visually separate Group, Raid, and Raid Tab option pairs with one blank line between sections. Confirm the pfUI GUI API's supported heading/spacing mechanism before implementation.
