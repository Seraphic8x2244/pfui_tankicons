# Development Progress

## Current
- Branch: `dev`
- Version: `0.3.7-dev`
- Goal: Migrate pfUI TankIcons to the VanillaTemplate development workflow without changing tank assignment, sync, or frame behaviour.

## Recent Commits
- `1ee31b3` — stable `0.3.6` baseline on `main`; README clarity update.
- Migration branch created from `1ee31b3`.

## Completed / Verified
- Stable baseline remains `0.3.6` on `main`.
- Existing addon architecture reviewed against VanillaTemplate.
- Migration scope agreed: workflow docs, localisation, TOC-sourced version metadata, and user-facing name normalisation to `pfUI TankIcons`.

## Implemented / Awaiting Test
- `dev` branch established.
- VanillaTemplate development documentation being adopted.

## Current Issues
- Hardcoded Lua version duplicates the TOC version.
- User-facing GUI strings are currently hardcoded in the main Lua file.
- User-facing name is not yet normalised consistently.

## Testing

### Last Test
- Version/commit: `0.3.6` / `1ee31b3`
- Passed: Existing stable release baseline.
- Failed: None recorded.
- Not tested: Migration work has not yet been applied or tested in game.

### Next Test
- Load the completed `0.3.7-dev` migration in WoW 1.12.1 and confirm the addon loads cleanly, the pfUI Thirdparty > TankIcons page appears with unchanged controls, and a tank icon still displays/moves correctly.

## Planned / To-do
- Add `locales/enUS.lua` and move addon-owned GUI strings into it.
- Replace hardcoded Lua version with `GetAddOnMetadata`.
- Normalise user-facing name to `pfUI TankIcons`.
- Update TOC to `0.3.7-dev` and load locale before the main Lua file.
- Perform static migration review.

## Ideas / Backlog
- Additional locale translations can be added later if wanted.

## Deferred
- No changes to tank assignment logic, communication protocol, frame discovery, compatibility fallbacks, or SavedVariables.
- No artwork directory unless addon-owned assets are introduced.
- No Debug.lua unless a development need arises.

## Exact Next Step
Apply the agreed localisation, metadata/version, and user-facing naming migration on `dev`, then update this file with the exact resulting commit and in-game test state.
