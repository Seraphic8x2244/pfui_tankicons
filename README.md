# pfUI_TankIcons

A small standalone pfUI component for Vanilla WoW 1.12.1.

## What it does

- Uses pfUI's existing `pfUI.uf.raid.tankrole` assignments.
- Shows a shield icon in the Blizzard Raid tab.
- Shows a shield icon on pfUI group frames.
- Shows a shield icon on pfUI raid frames.
- Uses pfUI's own configuration database; no addon-specific SavedVariables.
- Does not maintain a separate tank-role database.
- Has no external addon or library dependencies.

## Options

Available under **pfUI > Thirdparty > TankIcons**:

- RaidTab Visibility
- RaidTab Justification: Left / Centre / Right
- GroupFrame Visibility
- GroupFrame Justification: Top Left / Top / Top Right / Left / Centre / Right / Bottom Left / Bottom / Bottom Right
- RaidFrame Visibility
- RaidFrame Justification: Top Left / Top / Top Right / Left / Centre / Right / Bottom Left / Bottom / Bottom Right

Defaults preserve the original v0.1.0 placement: all icons visible, RaidTab Right, GroupFrame Top Right, RaidFrame Top Right.

### 0.2.3

- Fixes group-frame icons when pfUI group frames were created before TankIcons installed its unitframe refresh hook.
- Uses pfUI's stable `Group0`–`Group4` / `Raid1`–`Raid40` frame identities before compatibility fallbacks.

## Compatibility

Designed for pfUI versions/forks that expose the standard Shagu tank-role table:

`pfUI.uf.raid.tankrole[name]`

If that table is unavailable, the addon simply shows no tank icons.

## Installation

Place the `pfUI_TankIcons` folder in:

`Interface\\AddOns\\`

The final path should be:

`Interface\\AddOns\\pfUI_TankIcons\\pfUI_TankIcons.toc`

## Version

0.2.3

Tank markers on pfUI group/raid unitframes are rendered through a high-level child frame so they stay above health and power bars.

### 0.2.3

- Discover pfUI group/raid frames from `pfUI.uf.frames`.
- Refresh tank icons one frame after the popup toggle so pfUI has finished updating `tankrole`.
- No polling loop is used.
