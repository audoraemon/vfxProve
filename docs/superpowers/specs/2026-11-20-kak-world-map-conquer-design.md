# KAK World Map and Conquer Progress: design (God's Chamber step 8)

Date: 2026-11-20. Source: the user's Discord #ideas posts "God's Chamber" and "Conquer Progress" (2026-11-18) and the answers
given in chat on 2026-11-20. Branch: `feat/god-chamber` (worktree `vfxProve-chamber`). Builds on
`2026-11-19-kak-god-chamber-design.md`. Nothing on this branch lands until every Chamber step is done (the user's rule).

## 1. Goal

The god keeps the believers they win. Each town has a conquer percent: believers out of its population. The World Table in the
God's Chamber opens a map of the kingdom, where the player sees every town's percent, picks a town and descends. Winning
Aldermere far enough opens the Capital; a fully conquered town pays Faith every night.

Success: a player can raise Aldermere's percent over several nights, see who believes during a night, lose believers by killing
them, open the Capital at the threshold and play nights there, all from the map; old saves load; no replay reference moves.

## 2. Decisions taken with the user

| Question | Answer |
|---|---|
| What the map shows | A whole kingdom: Aldermere and the Capital playable, 4 more town spots drawn but sealed. |
| What the percent does | Unlocks the next town at a threshold; at 100% the town is conquered and pays a permanent Faith bonus. |
| Who converts | The mission's named people first, then a fill from living unbelievers nearest to where the god's powers landed. |
| Believer view | A toggle key, off by default: a gold mark over believers, and a believer count in the aim preview. |
| What is remembered | A believer count per town in the god's save. No lasting individuals (may come later). |
| World Table flow | The table opens the map; pick a town, then Descend. Enter on the map descends to the last town played. |

## 3. What exists already

- `Person.Faith.BELIEVER` and `Wish.grant()`: a granted wish makes its people believers during a night.
- `Descent.report()` gives `descend.earned`; `GodNight.bank()` pays `earned * GodSlot.FAITH_PER_BELIEVER` Faith.
- `MapTag.person()` and `Person.tag_head()`: marks over heads. `Targeting`: the aim preview, which already rings people.
- `Crowd.danger_landed(key, points, radius)`: where a power lands. Nothing keeps it after the moment.
- Towns: `City` registry; `MissionBook.hostable(id, city)`; `<mission>@<city>` ids are dev-only today; wishes and believers
  (`Mission.has_descent()`) run only in Aldermere. The god game never chooses a town: every night is Aldermere.

## 4. Rules

### 4.1 The count

- `GodSlot` gains `believers`: town id to whole number, default empty (every town 0), and `last_town` (default `aldermere`).
  A missing key reads as the default, so old saves load unchanged. A town id the game does not know is dropped on read.
- A town's population is `City.by_id(id).citizens()`. Soldiers are never believers and are not counted.
- Conquer percent = `floor(100 * believers / population)`, with believers clamped to 0..population.

### 4.2 A night

- **At spawn:** `believers[town]` citizens are marked as carried believers (`Person.faith = BELIEVER`, plus a `carried` flag).
  They are chosen with a random stream of their own, seeded from the night, so no other random draw in the night changes. The
  mission's reserved people (`MissionDirector.reserved`) are skipped. With a count of 0 the night is bit-for-bit what it is
  today.
- **Carried believers are not earned again:** `descend.earned` and its Faith count only people who became believers this night.
- **Deaths:** every carried or newly made believer who dies is counted (`believers_lost`).
- **At the end,** on a successful night (`descend.main`):
  - named converts: the living people this night's wishes made believers (today's rule);
  - fill converts: `FILL_CAUGHT` (3) on a caught night, `FILL_CLEAN` (6) on a clean one, taken from living citizens who are not
    believers and not reserved, nearest first to any point where a power landed this night. With no power cast, nearest to the
    named converts; with neither, in spawn order. Fewer are taken if fewer exist.
- **Banking:** `believers[town] = clamp(carried_alive + named + fill, 0, population)`. On a failed or abandoned night there are
  no converts and the count becomes `carried_alive`: deaths still cost.
- **Faith:** named and fill converts both pay `FAITH_PER_BELIEVER`. The results screen shows the converts, the believers lost
  and the town's new percent.

### 4.3 Thresholds

- `UNLOCK_PERCENT` (60): at or above it in Aldermere, the Capital opens. An opened town stays open if the percent falls.
  `GodSlot` gains `opened`: the list of opened town ids (Aldermere always).
- 100%: the town is conquered while it stays at 100%. Each conquered town adds `CONQUER_FAITH` (5) Faith when a night is banked,
  whichever town the night was in.

### 4.4 Believer view

- Key B toggles it during a night; off at the start of every night; the keys hint names it.
- On: every living believer carries a small gold head mark (through `MapTag.person`, no label text), under the mission's own tags
  when both apply.
- On: the aim preview shows "N believers" beside the shape when N > 0, counting living believers inside the area it would hit.
- Off: nothing extra is drawn or counted.

### 4.5 The World Map page

- New screen `WorldMap` on a new `Game.Screen.WORLD`. Routes: `hub:descend` goes to WORLD; `world:descend` goes to PREPARE;
  `world:back` goes to HUB. The Chamber's zoom on the World Table plays as it does for the other stations, and the Chamber
  zooms back from the table on return.
- The map is drawn in the UI layer's 640 x 360 design units with the `ChamberArt` hook: `res://assets/chamber/map.png` when it
  exists, else a greybox (land shape, a road between spots).
- Six spots from a data table (`WorldLayout`): id, name, place, state source. Aldermere and the Capital are real towns; four
  more are sealed spots with a name and the line "Beyond your reach". Sealed spots cannot be selected.
- An open town shows its name, a percent bar, "believers / population", and a seal when conquered. The locked Capital shows
  "Conquer 60% of Aldermere".
- Selection starts on `last_town`. Arrow keys and the mouse move it between open towns. Enter or a click on the selected town
  descends; a click on another open town selects it. Esc or the Back button returns to the Chamber. So a normal night is Enter
  (table), Enter (descend).
- Refusals keep today's words: with nothing to draft the map still opens, and Descend buzzes with `HubStatus.BLOCKED`.
- The Chamber's top bar gains the last town's name and percent, left of "Night n".

### 4.6 Nights in the Capital

- `GodNight.draw()` takes the town and draws only missions the town can host (`MissionBook.hostable`). If the town can host
  none of the god's current tier, Descend on that town buzzes with "No night waits there yet" and the town is drawn dim.
- A god night in a town is not a dev mission: it banks fully (night, Faith, DP, notice, believers), unlike today's `@city` ids.
- `Mission.has_descent()` becomes true for any town whose data allows wishes; the Capital is switched on. Where a wish needs a
  place the Capital lacks, that wish is not offered there.
- Capital missions were built for the dev tab and are untuned for god nights. Tuning them is part of this step's play test,
  not of the first build.

## 5. Structure

| Unit | File | Job |
|---|---|---|
| `GodSlot` | `src/game/god/god_slot.gd` | `believers`, `opened`, `last_town`; read, write, clamps. |
| `Conquest` | `src/game/god/conquest.gd` (new, static) | The arithmetic: percent, unlock, conquered, the bank step, the Faith bonus. No nodes. |
| `BelieverRoll` | `src/game/god/believer_roll.gd` (new) | One night's believers: mark carried at spawn, record power landings and deaths, pick the fill, report. Owned by `Mission`. |
| `WorldLayout` | `src/game/ui/world_layout.gd` (new, static data) | The six spots: id, name, place. |
| `WorldMap` | `src/game/ui/world_map.gd` (new, Node) | The page: selection, drawing, emits `action`. |
| `GodNight` | `src/game/god/god_night.gd` | `draw` and `def_for` take the town; `bank` calls `Conquest`. |
| `Game` | `src/game/game.gd` | The WORLD screen and routes; passes the town to the night; FLOW steps. |
| `Targeting`, `HUD` | existing | The believer count and the head marks, behind the toggle. |

## 6. Errors and edge cases

- A save naming an unknown town, or a count above the population (a town shrank): dropped or clamped on read.
- `last_town` locked or unknown: falls back to Aldermere.
- More carried believers than unreserved citizens: as many as fit are marked; the saved count is not reduced by that.
- A believer who escapes the map alive is alive.
- Rites, the Hunt and the dev Awaken: no town count changes, no converts.
- Campaign, tier board and dev-tab missions: no believers are marked, nothing is banked. They behave as today.

## 7. Tests

- `test_conquest.gd`: percent, clamps, unlock stays open, conquered bonus, bank arithmetic for clean, caught, failed, abandoned.
- `test_god_slot` additions: new keys round-trip; an old save without them loads; unknown town dropped; over-count clamped.
- `test_believer_roll.gd`: marks exactly N, skips reserved, same seed same people, a count of 0 draws nothing from any stream;
  fill is nearest to landings, falls back as written, never picks believers, reserved or dead; deaths counted once.
- `test_world_map.gd`: six spots, sealed and locked spots refuse, selection starts on the last town, Enter descends, Esc backs,
  the lock line, the conquered seal, the four window sizes.
- `test_god_chamber` and `test_hub_status`: the table opens the map; the bar shows the town and percent.
- Targeting and HUD: the count and marks appear only with the view on.
- FLOW and `real_path_probe.gd`: the god route gains the map step.
- Replay references: `refs_check.sh` must show no row moved.

## 8. Order of work

1. `GodSlot` fields and `Conquest`.
2. `BelieverRoll`: carried believers at spawn, deaths, banking in Aldermere; the percent in the top bar and on the results screen.
3. Converts: power landings recorded, named plus fill.
4. Believer view: the toggle, head marks, aim count.
5. `WorldMap` page and routes, sealed spots, unlock and conquered bonus; FLOW and probe.
6. Capital nights: town-aware draw and banking, wishes switched on.
7. The user plays it; numbers tuned (`FILL_CAUGHT`, `FILL_CLEAN`, `UNLOCK_PERCENT`, `CONQUER_FAITH`).

## 9. Not in this step

- Lasting individuals (names, homes, the same faces each night).
- Believers changing how a night plays (helping or resisting).
- Building the four sealed towns.
- The painted map (joins the Chamber's art pass).
