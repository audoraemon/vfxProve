# Kingdoms Amid Kataclysm (KAK) - Version 0.12 Summary

*Engine: Godot 4.7.2. Branch `feat/v012` (from feat/Develop-Main `1c28dc0`, tag `kak-v0.11.2` plus the F1 hide-interface change). v0.12 is **Many Towns**: the missions stop reading Aldermere's coordinates, and the five Tier 1 missions can be played in the Capital. Built 2026-10-23 to 2026-10-24, straight through and subagent-driven: 15 tasks in two milestones, with a fix wave after each milestone review. Spec: `docs/superpowers/specs/2026-10-23-kak-v012-many-towns.md`. Plan: `docs/superpowers/plans/2026-10-23-kak-v012-many-towns.md`. Every ruling is in `docs/KAK_v012_Rulings.md`.*

## What you asked

You asked whether the missions can be played in a new town, such as the Capital. Before v0.12 they could not. Nineteen mission and descend scripts read Aldermere's `TownLayout` directly, and about fifty director spots were Aldermere coordinates. A mission put in the Capital would have sent people to places that do not exist there.

## What v0.12 did

### M1 - Merge and groundwork (tag `kak-v012-m1`, landed 2026-10-24)

- **Merge.** The branch `feat/capital-city` (the Capital, its sandbox, the DEV tab) was merged into the v0.11.2 line. Aldermere's rows did not move. The Capital's two crowd rules for walkers (do not step into the river; wade ashore from a fallen bridge span) sit behind `CityDef.river_rules()`. The Capital's long-step rule sits behind `CityDef.long_steps()`. Both are off for Aldermere, so Aldermere walks as before the merge, also at 30 fps.
- **Places by name.** A town names its places (`CityDef.landmark()`, `place()`, `gate_towers()`, `barns()`). Missions read them through the `Places` helper. An unknown name is an error, not a silent wrong point. The Citadel's gate became the place `citadel_gate` (Aldermere `(-10.5, -7.6)`, Capital `(0, -22.6)`).
- **Needs.** One table, `MissionNeeds.TABLE`, lists what each of the 28 missions needs from a town. A test checks that every place a director reads is in the table. A mission is hostable in a town when the town has all its needs and either is the mission's home town or has an overrides file for it.
- **Overrides.** A town may change a mission's spots and numbers in `src/game/town/cities/<city>_missions/<mission_id>.gd`. Each Tier 1 director lists the names a town may change (`TOWN_VARS`); any other key is refused. A mission started in a town that cannot host it is refused with an error (and `gate.sh` fails).
- **Run a mission in a town.** Composite ids `<mission>@<city>`, the `--city=` argument, and the board's DEV tab. A night in another town has no Descent in v0.12 (no wishes, no believers, no banking, no tier progress), and it counts as a dev night (every power open).
- **Tools.** `gate.sh --city=<id>` and `--with-none` (proves that doing nothing loses); `land.sh --bench-only`.
- **Tests.** The guard test now also scans `src/game/mission`, `tools/dev/routes` and the Tier 1 policies for hard-coded Aldermere places.

### M2 - Tier 1 in the Capital (merged on `feat/v012`; tag `kak-v012-m2` not yet made)

Each of the five missions has its own overrides file, its own references, its own test file and its own gates.

| Mission | Capital version |
|---|---|
| The Warning (as Starfall, the board version) | Stars fall over the harbour gate, the west river gate and the west gate. The tower is the Bell Tower. |
| The Tax Collector | The counting-house is the Great Market's weigh-house. Three rounds of debtors walk inside the old town. The collectors end at the Keep's gate. |
| Spoiled Harvest | Three granaries are old-town dwellings (west, south, east). The carter empties them in turn. |
| The Lost Lamb | The acolyte hides near the civic square and leaves by the old town's west gate. The camera is fixed at `(-12, -2)`. |
| First Prayers | The shrine is on the Great Market's south promenade `(-9.25, 0.75)`. The poor are in the west market. |

All five are played inside the old town's wall ring, which is about Aldermere's size. No route crosses the river, because the river gatehouses let one person through each second and that would make the night depend on traffic (luck). The Capital's street patrols and wall loops are the town's own and not part of a mission's opposition.

Tours and hints never name an Aldermere place in the Capital. Where the copy named one, it is now a town var (`hideout_name`, `poor_quarter`). The Capital's label "THE WEST RIVER GATE" is unambiguous (the old town has three river gates).

## How to play a Capital mission

These nights are dev-only in v0.12. The town screen for players is a later step.

1. Run the game with `--dev`: `& $godot --path . --scene res://scenes/game.tscn -- --dev`. (`play.bat` passes no arguments, so use this command.)
2. Open the Missions board from the title and press `D`. This is the **DEV tab**.
3. The tab lists the Capital Sandbox and the five Capital missions. Each card shows the mission's name, the word `CAPITAL` in gold, and its type.
4. Pick a card and press Enter. Choose powers as usual. Every power is open on a dev night.
5. `Esc`, then the board, brings you back to the DEV tab.

For a scripted run (no window needed, fixed 60 fps):

```bash
# one run, prints the result and a checksum
$G --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=tax --case=play --city=capital
# a mission started on its own, in the Capital
$G --path . --audio-driver Dummy --scene res://scenes/mission.tscn -- --mission=tax_collector@capital --city=capital
# the three seeds, both routes, with the pass or fail line
bash tools/dev/gate.sh tax --city=capital            # route a (add --route=b for route b)
bash tools/dev/gate.sh warning --city=capital --route=b --board --with-none
```

The scenario names are `warning` (Starfall, with `--board`), `tax`, `harvest`, `lamb` and `prayers`. A scripted run in a town that cannot host the mission exits with code 1 and prints `BEHAVIOUR refused`.

## How to add a town (for the future)

1. **CityDef.** Write `src/game/town/cities/<name>_city.gd` extending `CityDef` and add the id to `City.IDS` and `City.by_id()`. It gives the map, walls, rivers, structures and so on (see `capital_city.gd`). Remember `river_rules()` and `long_steps()` (false is the Aldermere behaviour).
2. **Places.** Give it the landmarks and places that missions read: `landmark(&"temple")`, `&"bell_tower"`, `&"market_square"`, `&"fountain"`, `&"workshop"`, `&"citadel_court"` and so on; `place(&"citadel_gate")` and `place(&"citadel")`; `gate_towers()`, `barns()`, `districts()`, `wells()`, `taverns()` as needed. `citadel_origin()` must not be `Vector2.INF` if a mission needs the Citadel.
3. **MissionNeeds.** The table says which places each mission needs. A town is offered a mission when `Places.can_host()` is true. Run `tests/test_mission_needs.gd` to see what is missing.
4. **Overrides.** For each mission you want, add `src/game/town/cities/<name>_missions/<mission_id>.gd` with `static func overrides() -> Dictionary` returning `{"def": {...}, "director": {...}}`. The `def` part may change any `MissionDef` property (always change `camera_at` and `intro_from` together). The `director` part may change only the names in the director's `TOWN_VARS`. Write floats with a decimal point and names as `&"..."`: the check is strict about types. Copy the Capital's files (`capital_missions/`) as a model.
5. **Tests.** Copy one of the `tests/test_capital_*.gd` files: overrides valid, hostable, walk-length parity with Aldermere (0.75 to 1.35 times), spots land on walkable ground, camera and arrows clear of the HUD, tour text true. Add the file to `tests/run_all.gd`.
6. **Gates and references.** Run `gate.sh <scenario> --city=<id>` for both routes and the toll case, then record references as one TSV per mission (`tools/dev/refs/<city>_<scenario>.tsv`, rows `<city>_<scenario>_<none|play|b_play|toll>_<n>`, with `--city=<id>` in `how`). The mission design rules still bind: no waiting over 60 s, doing nothing loses, an acting player idles 45 s at most, opposition spread more than 1.6 apart, no luck from traffic, the bell never loses.

## Gates (Task 14, on the merged tree `c806eee0`, plus the M2 fix)

Each gate is three seeds at a fixed 60 fps, so the checksums are exact.

| Check | Result |
|---|---|
| Suite (8 parts) | checks=10077 failures=0 |
| References | ok=286 bad=0 (235 unchanged + 51 new Capital rows; see next section) |
| FLOW (run alone) | checks=134 failures=0 (131 at M1, +3 for the Capital Tax Collector step) |
| Trial merge of origin/feat/Develop-Main | 0 incoming commits, clean |

| Capital gate | None (does nothing) | Play | Verdict |
|---|---|---|---|
| Starfall, route b `--board --with-none` | lost 3/3 (Lantern at 63.7 / 67.5 / 63.6 s) | won 3/3, 157.1 / 146.0 / 152.5 s, idle 44 / 40 / 44 | `none_lost=3/3 wins=3/3 median=152 idle_max=44 PASS` |
| Starfall, toll (herald) | - | won 3/3, 142.2 / 157.9 / 142.2 s, idle 45 / 46 / 44 | `wins=3/3 median=142 idle_max=46 PASS` (toll idle is reported only) |
| Tax, route a | lost 3/3 | won 3/3, 185.1 / 202.1 / 194.9 s, idle 36 / 38 / 38 | `none_lost=3/3 wins=3/3 median=195 idle_max=38 PASS` |
| Tax, route b | - | won 214.2 s, **lost at dawn 277.5 s**, won 243.7 s, idle 35 | `wins=2/3 median=229 idle_max=35 PASS` (Aldermere's B is also 2/3) |
| Tax, toll (watch) | - | won 3/3, 163.2 / 148.8 / 174.8 s, idle 27 / 30 / 32 | `wins=3/3 median=163 idle_max=32 PASS` |
| Harvest, route a | lost 3/3 | won 3/3, 182.2 / 182.4 / 182.2 s, idle 40 | `none_lost=3/3 wins=3/3 median=182 idle_max=40 PASS` |
| Harvest, route b | - | won 3/3, 150.1 s x3, idle 30 | `wins=3/3 median=150 idle_max=30 PASS` |
| Lamb, route a | lost 3/3 (the lamb is taken at about 173 s) | won 3/3, 219.0 / 244.8 / 215.8 s, idle 27 / 25 / 25 | `none_lost=3/3 wins=3/3 median=219 idle_max=27 PASS` |
| Lamb, route b | - | won 3/3, 228.8 / 254.4 / 254.2 s, idle 30 | `wins=3/3 median=254 idle_max=30 PASS` |
| Prayers, route a | lost 3/3 | won 3/3, 202.0 / 133.8 / 205.8 s, idle 19 / 21 / 29 | `none_lost=3/3 wins=3/3 median=202 idle_max=29 PASS` |
| Prayers, route b (final, no filler) | - | won 3/3, 255.5 / 259.0 / 233.4 s, idle **48** / 43 / 38 | `wins=3/3 median=256 idle_max=48`: idle over 45, **REPORTED** (C10) |
| Prayers, toll (C12) | - | won 211.7 s, won 157.5 s, lost by Gaze at 112.3 s | `wins=2/3 median=185 idle_max=31 PASS` (the toll never lost outright; it lost by the Gaze filling, as Aldermere's does) |

The Task 14 table showed Prayers b with idle 40 / 39 / 38. That came from a Capital-only extra cast that only reset the idle counter. The M2 review (C10) removed it. The final line above is the honest one.

## References

- **235 rows unchanged:** 233 Aldermere rows (`references.tsv`, `routes_t1..t5`, `lantern_*`) and the two Capital crowd rows `capital_calm` (-713901328) and `capital_evac` (122086902). `crowd_check` is -935602679 and the digest is unchanged. The `capital_evac` value is the merged one; the old value 731230687 differed only by the v0.11.2 startle, proven by switching the startle off.
- **51 new Capital rows**, one TSV per mission: `capital_starfall.tsv` 9, `capital_tax.tsv` 12, `capital_harvest.tsv` 9, `capital_lamb.tsv` 9, `capital_prayers.tsv` 12. Nothing in M2 moved an existing row. The two Prayers route-b rows touched by the review were put back to -252052717 and -531737743.

## Benches

All numbers need your eye. They were taken on a shared machine.

- **Aldermere's five boards against `kak-v012-m1` (M2) and `kak-v0.11.2` (M1).** Every pair is within 1 fps: warning 29.4 / 30.3, miras_house 25.0 / 25.9, vigil_flame 27.3 / 27.2, procession 23.4 / 24.1, last_judgement 24.8 / 24.7 (A / B, median of 3). The absolute numbers are 23 to 30 fps because another session was running its landing. Your quiet-machine figure is about 124 fps. So the claim is "no difference seen at parity", not a quiet-machine proof. At M1 the Warning pair was 2 fps apart once and read as noise (a quiet re-pair: 115.2 / 111.0). A quiet rerun is cheap: `bash tools/dev/land.sh --bench-only --bench=kak-v012-m1`.
- **Capital Starfall (this tree only, board version):** 126.0 / 126.1 / 125.3 fps, median 126.0. Draw calls 449.
- **Capital sandbox at M1:** 52.4 fps against 51.1 at the Capital branch's tip (the new tree is not slower).

## REPORTED items (not binding, for your eye)

- **First Prayers route b, Capital: idle about 48 s (Aldermere 42).** Between the first prayer and the market window the player has little to do. Aldermere fills the gap by dooming a Faithful where nobody sees; in the busier Capital streets that cast has no safe target. Two rounds of moving the shrine or the poor's spot made route a or b worse, so Aldermere's numbers stay.
- **Tax Collector route b, Capital: 2 wins out of 3.** Seed 2 loses at dawn (277.5 s). Aldermere's B also wins 2 of 3. The cause of the Capital loss was **not diagnosed** (which collector lived, and whether his kill was seen).
- **Thin idle margins.** Starfall idles 44 / 40 / 44 against a limit of 45 (toll 44 to 46). The cause is the design: Death Mark's 10 s fuse, the 30 s stop wait and about 4 s of reaction. Aldermere's Starfall B is 40. A Capital-only `stop_wait` of 26 would give about 4 s of room, but the Capital Starfall rows would have to be re-recorded. Harvest route a runs a median of 182 s against a floor of 180: the carter's schedule allows nothing earlier. The Capital Harvest uses the same three houses as three of Tax's debtors (the old town has only 18 dwellings); harmless now, because the nights are separate and have no wishes.
- **The Capital's border band and camera clamp now show in Aldermere (C9).** The Capital branch added a band of distant meadow and woods drawn about 12 cells past the map's edge (`CityDef.border()`), and the camera is kept on the drawn ground (`Mission.clamp_view()`, `TownFloor`). Aldermere draws the band too, and its camera is clamped too; a mouse-wheel zoom re-clamps it. The band appears about 1.5 s after a town is built. The clamp has a second effect: `Person.view` (the camera's view) decides which off-screen people update and how often, so in real play the camera now decides who ticks at what cadence. The references never pan the camera, so they cannot see this. Drawing the band cost Aldermere about 2.5 fps on the Capital branch (83.1 to 80.6); no extra drop was seen at parity here, but that is the first place to look if Aldermere feels slower.
- **Starfall policy fallback.** When a street has no 4.5-unit corner, the Starfall route policy takes the emptiest corner (never under 3.0). Aldermere's recorded rows never reach that case, so they are unchanged; nothing guards it by construction.
- **Incident.** During the M2 landing a subagent stopped a `refs_check.sh` run that belonged to another session (the feat/town-lighting landing) by mistake. That session must rerun its references. The cause was that `land.sh` and `refs_check.sh` shared one fixed folder; `land.sh` now uses a private folder per run (commit 93a08366), and the implementer rules say to stop only processes you launched.

## Out of scope: what comes next

- **Player-facing town UX.** There is no way to choose a town in the campaign or the normal board. The Capital nights are on the DEV tab only, with no Descent, no wishes, no believers and no progress. Their best time is saved under the composite id (for example `tax_collector@capital`).
- **Citadel missions.** The Capital does have a Citadel (the Royal Keep's hill, `citadel_origin()` `(0, -25.5)`), so Tax and Harvest were ported. The Keep and Citadel missions of the higher tiers stay out by decision.
- **Tiers 2-5 in the Capital.** Their `MissionNeeds` rows exist, but no Capital overrides files do. Later tiers' names are wider than a six-card DEV row and would need a narrower name or a smaller font.
- **Wishes elsewhere.** Descent is Aldermere-only.
- **Copy numbers in towns.** Numbers written in the game's words (Harvest's 10 s and 3 s, First Prayers' three) are not overridable; a town must never make the game's words false.

## Worth checking when you play

1. **The five Capital missions from the DEV tab** (run with `--dev`, open the board, press `D`). Play each once with your own hands: The Warning (Starfall), The Tax Collector, Spoiled Harvest, The Lost Lamb, First Prayers. The scripts win them; a human may feel gaps the scripts do not.
2. **The off-screen Lamb acolyte.** In the Capital's Lost Lamb the camera rests at `(-12, -2)` and the acolyte starts off screen; only his edge arrow shows (it points east). The cause: any camera that has him in view puts the WEST GATE arrow under the HUD stack. Tell me if you want him in view.
3. **Aldermere's border band.** Look at the edge of Aldermere's map, pan to the edge and zoom out. The band of meadow and woods and the camera that stops at its edge are new in Aldermere. Check that it looks right and that nothing feels slower or different in how far-away people move.
4. **The Prayers lull and Tax B loss** in the Capital (the REPORTED items above), if they feel slow or unfair.
5. **Aldermere's missions and the campaign** should feel exactly as in v0.11.2. Nothing in them was meant to change.

## What changed, by task

| Task | Commit | What |
|---|---|---|
| 1 | `b7b7a937` + `79e20d9a` | Merge of feat/capital-city; `river_rules()`; the suite runner checks the active city before and after each suite (C3) |
| 2 | `322f3311` | `CityDef.place()`, the Citadel's gate and side gate as places; `Places` and `MissionNeeds` helpers |
| 3 | `19e09a76` | Missions, descend and routes read places from the town; each of the 28 ids lists its needs; guard test |
| 4 | `a63c927c` + `dd23dc25` | Overrides, `<mission>@<city>`, `--city=`, hostable check, no Descent off Aldermere |
| 5 | `d64355cb` | `gate.sh --city` and `--with-none`; `land.sh --bench-only` |
| 6 | `fd9ee293` | Tier 1 directors read their spots and numbers from town vars |
| 7 | `fb56a632` | DEV tab lists a town's hostable missions; FLOW walks a Capital night and back |
| 8 | (no commit) | M1 landing: gates on the tree; tag `kak-v012-m1` |
| M1 fix | `c8ae1747`, `81260880`, `d06cfe2c`, `2d38d781`, `db291cda` | `long_steps()` flag (C8); `TOWN_VARS` (C7); refuse unhosted starts (C6); review minors |
| 9 | `3eec9b7b` | Starfall in the Capital |
| 10 | `b6a1ff93` | The Tax Collector in the Capital |
| 11 | `36a7f8eb` | Spoiled Harvest in the Capital |
| 12 | `1d105ba7` | The Lost Lamb in the Capital |
| 13 | `da363f0d` + `9996f67e` | First Prayers in the Capital |
| M2 fix | `96d3e063` | Prayers filler reverted (C10); copy and test fixes (C11) |
| 14 | `c806eee0` | M2 landing; FLOW step `tax_collector@capital` from the DEV tab |
| 15 | this commit | These notes |
