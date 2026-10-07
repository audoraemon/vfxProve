# KAK board missions adopt the objective layer (design)

Date: 2026-10-07. Status: approved in chat ("Yes please" to giving The Warning, The Long Night's acts and Last
Judgement their own map tags, how-to-win lines and tours). Builds on
`2026-10-07-kak-v010-m6-objective-clarity-design.md` (M6), whose §6 left the board missions out.

## 1. Why

The playtest of Mira's House asked for every mission to show its objective clearly on the map and in a short line.
M6 did that for the Night 2 missions. This change does it for the board: The Warning (and The Long Night's Act I,
which plays it), the Festival, the Procession, Judgement and Last Judgement.

The rules are M6's: tags, phases and tours only read. They change no state and draw no random numbers, so every
behaviour checksum stays the same. No new art.

## 2. Map tags

Each list is in order, most important first, because label overlap keeps the first. Colours: gold `d8b23a`, steel
blue `8fb8e8`, orange `ff9a3a`, red `c8342a`, and pale gold for crowd pips.

### 2.1 The Warning (and Act I, `omen`)

- **The warning's carrier:** a gold person tag with an edge arrow. It replaces v0.08's marker.
  - `WATCHMAN` before he runs (OMEN, STARE).
  - `BELLKEEPER` once the keeper carries it.
  - Otherwise `MESSENGER`.
- **The bellkeeper**, while someone else carries the warning: `BELLKEEPER`, steel blue. Its edge arrow shows only
  while the messenger runs to him.
- **The bell tower:** `BELL TOWER`, red, raised by the tower's height, with no edge arrow.
- **Witnesses**, from the run on: a red diamond on each living person out of doors within `Crowd.DOOM_WITNESS` of the
  carrier. This is `Crowd.nearest_witness()`'s rule, so these are the people who would see the kill.
- Nothing is tagged once the warning is dead or the act is over.

The marker goes: `MissionDirector.marker()`, `Hud.marker_shown()`, `marker_screen()`, `edge_arrow()`,
`edge_point()`, `_draw_marker()` and `MARKER_LIFT`. No director used them any more.

### 2.2 The Festival

- **The Mayor:** `MAYOR`, orange. Its edge arrow shows while he speaks.
- **The feast:** `THE FEAST`, gold, at the fountain, raised by its height, with an edge arrow. Shown until the
  festival is broken.
- **Goers still to break:** a pale gold pip on each goer who is alive and out of doors, and neither broken nor gone.
  Shown until the festival is broken.

### 2.3 The Procession

All of these show only while the Prince is alive and has not boarded.

- **The Prince:** `PRINCE`, gold, with an edge arrow.
- **The ship:** `THE SHIP`, red, at the boarding point, with no edge arrow.
- **The cathedral steps:** `CATHEDRAL STEPS`, orange, until he has left them.
- **Witnesses:** a red diamond on each person who would see him die (as in §2.1).
- **His escort:** a steel blue diamond on each escort not already marked red.

### 2.4 Last Judgement and Judgement (Act III)

- **The Citadel:** `CITADEL`, gold, on its keep, raised by the keep's height, with an edge arrow. Shown until it
  falls.
- **The Banishing Rite:** `BANISHING RITE`, red, with an edge arrow, while the clergy gather or chant.
- **The boats:** `BOATS`, red, with an edge arrow, while the ferry is a way out (`RiverFerry.open()`).
- **Each gate:** `GATE`, red, raised by its height, with no edge arrow. These are the main gate, the side gate and
  the postern.

Last Judgement had no director. It now has `LastJudgementDirector`, which runs no actors and only tags.
`JudgementDirector` extends it, so Act III tags the same things.

## 3. How to win

New and changed `MissionHints` lines (`"<id>.<phase>"` for a phase):

| Key | Line |
|---|---|
| `warning`, `omen` | Kill the messenger (gold) with no one near (red) before he warns the bellkeeper (blue), or outlast the omen. |
| `warning.relay`, `omen.relay` | Someone saw: a witness (gold) carries the warning on. Strike again where no one (red) is near. |
| `warning.bell`, `omen.bell` | The bell is called. Kill its ringer (gold) unseen before the bell tolls, or outlast the omen. |
| `festival` | Break the festival: kill or scatter fifty of its crowd (gold) before the guard closes the square. |
| `festival.packed` | The bonfire packs the crowd (gold) round the fountain: one strike there breaks many. |
| `festival.address` | The Mayor (orange) speaks from the fountain. Kill him and the crowd round it panics. |
| `procession` | Kill the Prince (gold) before he boards. If no one near (red) sees it, the town is left leaderless. |
| `procession.blessing` | The Prince holds at the cathedral steps for the blessing. Strike while he stands still. |
| `procession.dock` | The Prince waits at the dock. He boards as soon as his ship is in: kill him first. |
| `judgement` | Bring the Citadel (gold) down before dawn, before too many of its people escape by the gates (red). |
| `judgement.rite`, `last_judgement.rite` | The clergy gather for the Banishing Rite (red). Break it, or it cuts your time short. |
| `judgement.fallen` | The Citadel is down. Break the city's stability before dawn, and keep its people in. |
| `last_judgement` | Destroy the Citadel (gold) and break the city in time. Fifty escaping by the gates (red) loses it. |
| `last_judgement.fallen` | The Citadel is down. Break the city's stability before time runs out. Fifty escaping loses it. |

Phases:
- **The Warning:** `bell` once the warning is delivered; else `relay` while a witness runs with it; else `""`.
- **The Festival:** `address` while the Mayor speaks (and lives); else `packed` once the bonfire is lit; else `""`.
- **The Procession:**
  - `dock` once he is on the dock's leg;
  - else `blessing` while he is at the steps in the blessing's window;
  - else `""`.
- **Last Judgement and Judgement:** `rite` while the rite runs; else `fallen` once the Citadel is down; else `""`.

## 4. Tours

- **The Warning and Act I:**
  1. the watchman: "The watchman. When the star falls, he runs to warn the town.";
  2. the bellkeeper: "The bellkeeper. Once warned, he rings the bell, and you lose.".
- **The Festival:**
  1. the fountain: "The Feast of Lanterns. Break fifty of its crowd.";
  2. the Mayor: "The Mayor. Mid-feast he speaks from the fountain.".
- **The Procession:**
  1. the Prince: "The Prince leaves the Citadel for his ship.";
  2. the steps: "The cathedral steps. He stops here to be blessed.";
  3. the dock: "The dock. Once his ship is in, he boards.".
- **Judgement:**
  1. the keep: "The Citadel. Bring it down before dawn.";
  2. the Main Gate: "The gates. Too many escaping loses the night.".
- **Last Judgement:** no tour. Its 2 s sweep stays, as FLOW times it.

## 5. Gates

- **Tests:** all pass; `tests/test_board_tags.gd` is new.
- **Identical to `kak-v010-m6` (9cd85d8):**
  - the state digest;
  - `crowd_check`;
  - the 12 behaviour checksums;
  - FLOW.
- **The campaign Feast:** still wins 6/6.
