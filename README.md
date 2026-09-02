# pfUI_TankIcons

A small standalone pfUI component for Vanilla WoW 1.12.1.

## What it does

- Uses pfUI's existing `pfUI.uf.raid.tankrole` assignments.
- Shows a shield icon in the Blizzard Raid tab.
- Shows a shield icon on pfUI group frames.
- Shows a shield icon on pfUI raid frames.
- Synchronises tank-role toggles between other users of pfUI_TankIcons.
- Uses pfUI's own configuration database; no addon-specific SavedVariables.
- Has no external addon or library dependencies.

## Tank-role sync

TankIcons never trusts authority claimed in an addon message. The sender name comes from WoW's `CHAT_MSG_ADDON` event and each receiving client validates that sender against its own live group roster.

- Party: only the party leader may broadcast/apply tank changes.
- Raid: raid leader and raid assistants may broadcast/apply tank changes.
- Raid-leader direct changes outrank later raid-assistant changes for that player.
- Normal members' local pfUI toggles are not broadcast.
- Messages for players who are not in the receiver's current group are ignored.
- On group/raid roster changes, clients request a baseline sync. In raids the raid leader is the snapshot authority; in parties the party leader is the snapshot authority.

The wire protocol contains only version/action/state/name data. It contains no authority field.

## Options

Available under **pfUI > Thirdparty > TankIcons**:

- Tank Role Sync (default: enabled)
- RaidTab Visibility
- RaidTab Justification: Left / Centre / Right
- GroupFrame Visibility
- GroupFrame Justification: Top Left / Top / Top Right / Left / Centre / Right / Bottom Left / Bottom / Bottom Right
- RaidFrame Visibility
- RaidFrame Justification: Top Left / Top / Top Right / Left / Centre / Right / Bottom Left / Bottom / Bottom Right

## Compatibility

Designed for pfUI versions/forks that expose the standard Shagu tank-role table:

`pfUI.uf.raid.tankrole[name]`

If that table is unavailable, the addon simply shows no tank icons.

## Installation

Place the `pfUI_TankIcons` folder in:

`Interface\\AddOns\\`

The final path should be:

`Interface\\AddOns\\pfUI_TankIcons\\pfUI_TankIcons.toc`

## Version 0.3.2

- Adds authorised tank-role synchronisation over Vanilla 1.12 addon messages.
- Hardcodes authority from the receiver's own party/raid roster; authority is never accepted from message payloads.
- Party leader only in parties.
- Raid leader + raid assistants in raids, with raid-leader direct changes taking precedence per player.
- Adds a baseline sync request/snapshot on group changes.
- Adds **Tank Role Sync** to the pfUI Thirdparty options.
- Retains the v0.2.3 group-frame timing and high-frame-level icon fixes.


## Hidden diagnostics

`/pfti status` shows sync channel/authority. `/pfti debug` toggles comm send/receive diagnostics. `/pfti request` requests a fresh snapshot.


## 0.3.4 communication fix

The synchronization protocol now uses only plain chat-safe separators. Earlier 0.3.x builds used raw `|` characters in addon payloads; those builds are withdrawn because they could provoke `invalid escape code` errors in other addons on Vanilla clients.

Wire messages are now `V1:REQ`, `V1:T:1:Name`, and `V1:S:Name1,Name2`.
