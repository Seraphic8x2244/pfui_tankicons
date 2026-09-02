# pfUI_TankIcons 0.3.5

Displays pfUI tank-role assignments on the Blizzard Raid tab and pfUI group/raid frames.

## Tank role sync

This build deliberately uses a minimal Vanilla 1.12.1 comm path:

- No startup messages.
- No sync requests.
- No snapshots.
- No retries.
- No raw pipe characters in payloads.
- A message is sent only after pfUI's tank role actually changes from the unit popup.
- Party: only the party leader sends accepted changes.
- Raid: raid leader and raid assistants send accepted changes.
- Receivers independently verify the sender's current group authority.

Wire format: prefix `PFTI`, payload `T:1:Name` or `T:0:Name`, channel `PARTY` or `RAID`.

Because there is intentionally no snapshot protocol yet, a player who joins/reloads after tank roles were assigned will only learn about later changes. Snapshot sync can be added after this minimal live-toggle path is proven stable.
