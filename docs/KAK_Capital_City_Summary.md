# The capital: summary

**Branch:** `feat/capital-city`. Not merged into `feat/Develop-Main`; merging is the user's call.
**Spec:** `docs/superpowers/specs/2026-10-09-capital-city-design.md`.
**Plan:** `docs/superpowers/plans/2026-10-09-capital-city.md`.
**Overview capture:** `docs/superpowers/specs/2026-10-09-capital-overview.png`.

## What it is

The capital is a second, river-port city about twice the size of Aldermere. Aldermere and every existing mission are unchanged. The capital is played through a dev-only sandbox mission.

**Size and layout**
- Map: 80×80.
- Water: a river and a harbour basin, crossed by three stone bridges.
- Walls: two rings, with 9 gates including the south barbican, the west gate and a harbour gate.
- Districts: 18.

**Buildings**
- 71 of the 73 ChatGPT building sets are placed. The footbridge and drawbridge are unused (the third crossing is a stone bridge, and no gate faces open water). The wagon (both facings) and hand carts stand parked in the Keep's service yard.
- Water-side sets (crane, ferry landing, dock warehouses, wash houses, sluice) have their painted water cut out and stand over the real river (`cut_water` in `gpt_convert.py`, `BuildingTypes.OVER_WATER`).
- The Keep courtyard: a royal garden (fountain, monument, pavilion, paths, hedges, flowers, benches) and a drill yard where Keep soldiers drill at practice dummies.
- The Keep's gate (polish 2): the barbican at the head of the avenue from the cathedral square, the watchtower beside it, and both alley steps at its foot as one flight. Its arch and the steps' stair are walkable passages with solid sides (`BuildingTypes.PASSAGE`); it is no crowd gate.
- The Keep's service yard, east of the Keep: two royal stables, the horse pens, a granary, a well, wagons, hand carts, wood piles, barrels and crates; three stable hands work there.
- The cathedral close: a churchyard east of the cathedral (graveyard set, wayside cross, yews) and a paved pilgrim plaza before its steps (well, benches, the notice board, a crier stage, four pilgrim stalls).
- The aqueduct: nine arches from a spring in the northern woods to the old town's north-east corner tower; the cistern stands just inside the wall there. No trees under or beside the arches.
- The district gate stands across the lane between the poor and road quarters; the lane runs on through its arch.
- 142 houses (`houses()`; the 162 written here before was out of date: the count was 141 at the start of polish 2).
- The existing town sets: cathedral, barracks, taverns, smithy, stalls and farms.

**People**
- 427 citizens with routines: bread queue, wash houses, harbour, market, chapels, the Keep's stables and the cathedral close.
- 5 new roles: baker, washer, dockworker, monk and beggar. Monks count as clergy.
- 180 soldiers: the Keep garrison, gates, patrols on both wall rings, the harbour and the bridges.

**Evacuation**
- Each district leaves by its own exits.
- A destroyed bridge closes and its users reroute.

## How it is built

**City format**
- `CityDef` interface; `AldermereCity` delegates to `TownLayout`; `CapitalCity`; the `City` registry (`use`, `current`, `by_id`).
- `MissionDef.city` (default `&"aldermere"`). `Mission.start()`, the title screen and `town_debug --city=<id>` choose the city before building.
- The town builder, floor, decor, walk grid, crowd, art and powers read `City.current()`.
- Aldermere-only mission directors keep reading `TownLayout`.
- A grep guard (`tests/test_city.gd`) forbids direct `TownLayout.` reads in shared code.

**Building types**
- `src/game/town/building_types.gd` has one row per `gpt_*` set: kind, hp, walkable, flat, burns and smokes.
- `CapitalPlots` reads it, so it is the single source.

**Frame rate**
- Gates only check fleeing or passing people.
- A per-city off-screen LOD: the capital updates calm off-screen people every 6th frame; Aldermere keeps every 3rd.
- Long movement steps land on their waypoint, so the evacuation result does not depend on frame rate.

**Dev access**
- `--mission=capital_sandbox`.
- The `--dev` flag shows a DEV tab on the mission board (or press D).
- Desktop shortcuts: `KAK Tests\4 Capital\`, with Town and Mission.

## Gates (HEAD after polish 2)

| Check | Result |
|---|---|
| Full suite | 6202 checks, 0 failures, 0 SCRIPT ERROR |
| FLOW | 109 checks, 0 failures |
| Aldermere digest | `61267b7e90524d800bf1c3473a71146b` (unchanged) |
| crowd_check | `-346732806` (unchanged) |
| Behaviour checksums | calm, gates, fire, rite, boats, clip, powers, soldiers, warning and miras all unchanged |
| capital_calm | `-555183701` |
| capital_evac | `711112309` (60 fps); `-469839136` (30 fps) |
| Reachability | 3332 targets (3 exits, 376 anchors) all reachable; all 18 districts |
| Evacuation, 60 fps | 424 of 427 escape (3 calm stragglers), 0 stuck, 0 in the river; 7 caught on the falling span, ashore within 2.3 s |
| Evacuation, 30 fps | 422 of 427 escape (5 calm stragglers), 0 stuck, 0 in the river |

## Bench

Medians of 3 alternating pairs. Another session's Godot was open in most runs, so the numbers are noisy.

| View | Capital | Aldermere |
|---|---|---|
| Default zoom | 128–136 fps | 115–122 fps (same as before the branch, within noise) |
| Zoom 0.5 (furthest a player can reach) | 123.5 | 103.6 |
| Whole map at once (not reachable by the player) | 58.0 | 75.3 |

## Accepted gaps and choices

**Art gaps** (nothing generated):
- an aqueduct end piece (the corner tower hides the west end; the spring end shows the cut pier face);
- hay (the service yard has wood piles, barrels and crates, no hay);
- single graves (the churchyard uses the graveyard set once more);
- training dummies, weapon racks and true hedges (the drill yard uses scarecrows; the garden uses bushes);
- a ragged look for beggars.

**Placement compromises:**
- The barbican is the Keep's freestanding gatehouse (the Keep has no curtain wall to join).
- The district gate is a freestanding arch across a lane.
- The alley steps' 0.34-wide stair is one walk cell; their solid block covers the next one.
- The new town's corner towers stand 0.7 cells into the river.

**Not built:**
- No time of day, so the bread queue is not a morning queue.
- Funerals and cart traffic were skipped.

**Untuned:** hp values (15–180) have not been balanced against the powers.

**Behaviour choices:**
- Capital gates pass one person a second, because the barbican is the only way out for the whole new town.
- One change applies to Aldermere too, outside the scripted scenarios: people can't step from dry ground into the river, and people stranded on a fallen bridge wade ashore.

**Pre-existing bug, separate task:** evacuation stragglers. People who are busy when the flee order goes out and calm down later are never sent out. This affects Aldermere too.

## What the campaign chapter can build on

- **New missions:** `MissionDef.city = &"capital"` builds the capital. A chapter needs its own directors, intro camera (`camera_at`) and objectives.
- **Landmarks:** `City.current().landmark(name)` and `anchors()` give its places, such as the cathedral, market, harbour and bridges.
- **Exits:** `exits()` and `gate_exits()` give its ways out.
- **People:** `spawn_roles()` and the routine points drive its crowd.
- **Mira-style directors:** Aldermere-only directors read `TownLayout`. Capital versions must read `City.current()`. The grep guard covers `src/fx`, `src/game/crowd`, `src/game/descend`, `src/game/town` and `src/environment`.
