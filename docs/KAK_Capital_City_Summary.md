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
- 69 of the 73 ChatGPT building sets are placed. Unused: the footbridge and drawbridge (the third crossing is a stone bridge, and no gate faces open water), and since polish 3 the barbican and both alley steps (the Keep's gate at the avenue's head read as a gatehouse in a lawn). The wagon (both facings) and hand carts stand parked in the Keep's service yard.
- Water-side sets (crane, ferry landing, dock warehouses, wash houses, sluice) have their painted water cut out and stand over the real river (`cut_water` in `gpt_convert.py`, `BuildingTypes.OVER_WATER`).
- The Keep courtyard: a royal garden (fountain, monument, pavilion, paths, hedges, flowers, benches) and a drill yard where eight Keep soldiers drill, each facing one of eight practice dummies in two tidy rows (polish 3: the scarecrow art drawn at a soldier's height through a decor scale, `CapitalCity.DUMMY_SCALE`).
- The Keep's grounds (polish 3): the watchtower on the Keep's wall line, in line with the Citadel's south wall beside its south-east tower, the Keep's two guards at its foot, and three trees round it. The passages (`BuildingTypes.PASSAGE`) stay in the code for a later use.
- The Keep's service yard, east of the Keep: two royal stables, the horse pens, a granary, a well, wagons, hand carts, wood piles, barrels and crates; three stable hands work there.
- The cathedral close: a churchyard east of the cathedral (graveyard set, wayside cross, yews) and a paved pilgrim plaza before its steps (well, benches, the notice board, a crier stage, four pilgrim stalls).
- The aqueduct: nine arches from a spring in the northern woods to the old town's north-east corner tower; the cistern stands just inside the wall there. No trees under or beside the arches.
- The district gate stands across the lane between the poor and road quarters; the lane runs on through its arch.
- 151 houses (`houses()`; the test floor is 143). Since polish 3 the house blocks mix in the GPT housing sets by district, each in rows of its own on its own footprint: patrician rows in the noble quarter and by the Keep, shop-house rows on blocks fronting an avenue (and four more shop-houses on the cross avenue), shacks and tenements in the poor quarter, shacks by the tanners; the new town is plain cottages.
- The existing town sets: cathedral, barracks, taverns, smithy, stalls and farms.
- The avenues (polish 3): a tree and a lamp post in turn every 2.5 cells along both sides of each avenue inside the walls, where the spot is clear (46 pieces).
- Pocket gardens and market corners (polish 3): eight small gardens (flower beds, benches, a tree, a lamp) and four market corners (one or two stalls, crates, barrels) on the larger leftover strips; the shrubs over the house blocks are thinned (0.35 of the grid) and none grows in a pocket.
- The south outside the walls (polish 3): the gallows on its rocky hill, two fields and a barn in the suburbs, a hamlet of fourteen huts round a well, the tournament field (two grandstands facing a fenced tilt yard, the play stage), and more fields and barns at the west farms and the south-east fields. The south road to the barbican stays clear.
- The border band (polish 3): about 12 cells of distant meadow and woods drawn past the map's edge on every side (`CityDef.border()`, Aldermere's too), the river, the harbour basin and the roads carried out through it; the camera never pans the view off the drawn ground (`Mission.clamp_view()`).

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

## Gates (HEAD after polish 3)

| Check | Result |
|---|---|
| Full suite | 6304 checks, 0 failures, 0 SCRIPT ERROR |
| FLOW | 109 checks, 0 failures |
| Aldermere digest | `61267b7e90524d800bf1c3473a71146b` (unchanged) |
| crowd_check | `-346732806` (unchanged) |
| Behaviour checksums | calm, gates, fire, rite, boats, clip, powers, soldiers, warning and miras all unchanged |
| capital_calm | `-713901328` |
| capital_evac | `731230687` (60 fps); `962336456` (30 fps) |
| Reachability | 3387 targets (3 exits, 414 anchors) all reachable; all 18 districts |
| Evacuation, 60 fps | 425 of 427 escape (2 calm stragglers), 0 stuck, 0 in the river; 6 caught on the falling span, ashore within 3.3 s |
| Evacuation, 30 fps | 423 of 427 escape (4 calm stragglers), 0 stuck, 0 in the river |

## Bench

After polish 3: medians of 3 pairs, alternating the branch's start (2578c6e) with HEAD on the same machine, at the
default zoom. Other sessions' Godot was running in most runs, and the machine was slower than at polish 2, so compare
the pairs, not the absolute numbers.

| | Capital | Aldermere |
|---|---|---|
| 2578c6e | 94.0 fps, 575 draw calls | 83.1 fps, 1085 draw calls |
| HEAD | 87.0 fps, 644 draw calls | 80.6 fps, 1092 draw calls |

- The capital's extra draw calls are the avenues' lamps and trees, the pockets and the south's buildings. Aldermere's
  7 are the border trees' bands.
- The border band paints in a second bake pass, starting `TownFloor.BAND_DELAY` (1.5 s) after a town is built. It is
  spread over frames, a strip piece a frame, and the forest layer adds the border trees one band a frame. The worst
  frame in the bench is 32–45 ms (2578c6e: 18–33 ms).

Before polish 3 (quieter machine):

| View | Capital | Aldermere |
|---|---|---|
| Default zoom | 128–136 fps | 115–122 fps |
| Zoom 0.5 (furthest a player can reach) | 123.5 | 103.6 |
| Whole map at once (not reachable by the player) | 58.0 | 75.3 |

## Accepted gaps and choices

**Art gaps** (nothing generated):
- an aqueduct end piece (the corner tower hides the west end; the spring end shows the cut pier face);
- hay (the service yard has wood piles, barrels and crates, no hay);
- single graves (the churchyard uses the graveyard set once more);
- training dummies, weapon racks and true hedges (the drill yard uses scarecrows drawn at a soldier's height; the garden uses bushes);
- for the south (polish 3): tents or pavilions for the lists, banner poles, a hill or mound (the gallows stands on an outcrop's rocks), stocks or a pillory;
- a `gpt_townhouse` set (the town's own townhouse art stays the townhouse);
- a ragged look for beggars.

**Placement compromises:**
- The district gate is a freestanding arch across a lane.
- The Keep has no gatehouse of its own (polish 3): the barbican and alley steps are unused.
- The great market's blocks have room for one house only, so its shop-houses stand along the cross avenue instead.
- The border band (polish 3) appears about 2 s after a town is built (the bake's second pass); a player at play zoom never sees the map's edge that early.
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
