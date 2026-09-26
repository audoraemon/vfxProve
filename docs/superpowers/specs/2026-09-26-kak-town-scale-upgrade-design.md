# KAK Town Visual and Scale Upgrade — Design

**Date:** 2026-09-26 · **Baseline:** tag `prototype-v0.02` (= `d1fd243`, component match 89%)
**Reference:** `concepts/TOWN REF/Town Visual and Scale Upgrade.png`

## Goal

Aldermere grows into the reference's town: about 1.8× wider and deeper (≈3× the area), laid out as the reference
lays it out, with the reference's new buildings and countryside. The mission scales with it. The Citadel stays the
mission's heart.

## Decisions (user, 2026-09-26)

- **Citadel:** kept, in the town's **north corner** (top of the screen). The reference has none; its spired
  cathedral becomes our Temple, and everything else follows the reference's layout.
- **Mission scales with the town:**
  - about 2× the people (220 citizens + 100 soldiers, from 110 + 50);
  - escape limit and scoring scaled to match;
  - the timer goes from 4 to 6 minutes;
  - the camera zooms out further.
  - Frame rate will be measured and reported. The estimate is ~75 fps normal and ~28 fps in Cinderfall
    (now 104/39).

## Mapping the reference

The reference is anchored to game ground units by a homography through its four corner towers.
- **Ground towers:** (±16.2, ±16.2).
- **Reference pixels:** N (655, 38), E (1428, 482), S (975, 905), W (42, 338), moved down 58 px to their feet.

Through it, the reference unprojects into a top-down plan in ground units, and any reference point at ground level
converts to ground. Landmarks were read this way:
- the cathedral steps (0.7, −4.2);
- the market fountain (0.8, 5.7);
- taverns (−9, −7), (−5, 0.5) and (7, 3.6);
- workshops and forge (11–14, 0–5);
- the second fountain (10, −10);
- the south gate at x 2.8 and the east gate at y 9;
- the river at y 20–23 and the bridge to y 27;
- a windmill (−11.5, −24.5), a dock (−0.4, 24.7) and a watermill across the river;
- pastures north and east.

The reference's walls are not a clean square (it is a painting). Ours stay straight; its gates and landmarks keep
their places.

The blueprint (scratch `blueprint_ref.png`, sent to the user) draws this layout over the reference.

## Layout (ground units)

| Item | Now | New |
|---|---|---|
| Map | 28 × 28 | 60 × 60 (−30…30) |
| Inside the walls | 18 × 18 | 32 × 32 (−16…16) |
| Walls | 4 runs, 6 towers | 4 runs with a tower every ~8 units (≈12 towers) |
| Gates | a wall-sized gate | 2 stone gatehouses (arch between two towers): south at x ≈ 2.7, east at y ≈ 9 |
| Streets | 2 crossing | main N–S (x 2–3.4) and E–W (y 8.3–9.7) plus secondary streets at y −5.1, x −6 and x 9.5 |
| Market | 5.8 × 5 | 8.5 × 11.5, ~14 stalls, fountain at (0.9, 5.7) |
| Citadel | (0, −5.9) | north corner, origin (−10.5, −10.5) |
| Temple | small | the cathedral (spired front towers), (−1.3…2.9, −11.8…−5.6) |
| Taverns | 1 | 3 (north, west of the market, east of the market) |
| Blacksmith quarter | forge + yard | workshop hall, forge, barracks and its drill yard in the east quarter |
| Homes | 36 | ≈ 80 cottages in blocks with gardens and trees, plus the taverns |
| River | one band | the south river (y 20–23.3) and a west branch up to a waterfall at the map edge |
| Bridge | wooden, 2 × 2.4 | arched stone, 2 × 6.2 |
| Countryside | fields, 2 barns | north farms with a windmill, a pasture and farmhouses; an east pasture; south fields, a dock with boats and a sailing ship, and a watermill; forest and rocks around |
| Exits | south road, east road | the same two roads at the new map edge |

## New components (drawn with the component workflow)

- a gatehouse;
- an arched stone bridge;
- the cathedral (front towers, spires, rose-free front);
- tavern variants;
- a workshop hall;
- a windmill (turning sails on a child node);
- a watermill (turning wheel);
- a dock and pier;
- rowing boats and a sailing ship;
- farmhouses;
- sheep and cows (small idle animals);
- carts;
- wall towers along the runs.

Each new component gets a box in the Scale reference in `tools/dev/match_components.py` and is iterated to at least
85%.

## Workflow: the redraw loop

1. **Automatic tuning.** `tools/dev/tune_components.py` adjusts each component's size and colour settings
   (`src/environment/art/art_tuning.json`, read by the art code). It renders, measures, keeps changes that raise the
   score, and repeats until no setting helps (or 8 rounds).
2. **Shape loop (me).** For a component below target: redraw, re-render, re-measure, and repeat until it reaches the
   target or two rounds in a row gain under 1%.

A layout check is added beside the component check: each landmark's position against the reference's, in ground
units.

## Constraints

- `tools/dev/state_digest.gd` keeps its exact output (the sandbox is untouched).
- `src/fx/` does not change; the Tornado wander is still deferred.
- Tests are updated to the new layout's numbers, never loosened into meaninglessness.
- `--flow-test` passes.
- `--mission-test` and the bench are re-recorded and reported.

## Phases (a checkpoint after the layout)

0. The tuning loop and the layout check.
1. **Layout:** the new TownLayout, walls, gates, streets, river, bridge, landmarks and districts; the Citadel in the
   north corner; camera, map and exits; mission scaling. *Checkpoint.*
2. **New buildings:** gatehouses, arched bridge, cathedral, taverns, workshop hall, farmhouses.
3. **Countryside:** windmill, watermill, dock, boats, pastures and animals, carts, farms, forest.
4. **Measure and balance:** component and layout match, bench, mission test.
