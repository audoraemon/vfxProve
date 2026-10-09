# The capital: summary

**Branch:** `feat/capital-city`. Not merged into `feat/Develop-Main`; merging is the user's call.
**Spec:** `docs/superpowers/specs/2026-10-09-capital-city-design.md`.
**Plan:** `docs/superpowers/plans/2026-10-09-capital-city.md`.
**Overview capture:** `docs/superpowers/specs/2026-10-09-capital-overview.png`.

## What it is

The capital is a second, river-port city about twice the size of Aldermere. Aldermere and every existing mission are unchanged. The capital is played through a dev-only sandbox mission.

**Size and layout**
- Map: 80×80.
- Water: a river and a harbour basin, crossed by two stone bridges and a footbridge.
- Walls: two rings, with 9 gates including the south barbican, the west gate and a harbour gate.
- Districts: 18.

**Buildings**
- 71 of the 73 ChatGPT building sets stand on 132 plots. The other two, the wagon and hand cart, are props.
- 162 houses.
- The existing town sets: cathedral, barracks, taverns, smithy, stalls and farms.

**People**
- 422 citizens with routines: bread queue, wash houses, harbour, market and chapels.
- 5 new roles: baker, washer, dockworker, monk and beggar. Monks count as clergy.
- 182 soldiers: the Keep garrison, gates, patrols on both wall rings, the harbour and the bridges.

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

## Gates (final, HEAD abfae36)

| Check | Result |
|---|---|
| Full suite | 5967 checks, 0 failures, 0 SCRIPT ERROR |
| FLOW | 109 checks, 0 failures |
| Aldermere digest | `61267b7e90524d800bf1c3473a71146b` (unchanged) |
| crowd_check | `-346732806` (unchanged) |
| Behaviour checksums | calm, gates, fire, rite, boats, clip, powers, soldiers, warning and miras all unchanged |
| capital_calm | `-370675099` |
| capital_evac | `-870513036` |
| Reachability | 1461 targets from every exit, all reachable; all 18 districts |
| Evacuation, 60 fps | 419 of 422 escape, 0 stuck, 0 in the river |
| Evacuation, 30 fps | 419 of 422 escape, 0 stuck, 0 in the river |

## Bench

Medians of 3 alternating pairs. Another session's Godot was open in most runs, so the numbers are noisy.

| View | Capital | Aldermere |
|---|---|---|
| Default zoom | 128–136 fps | 115–122 fps (same as before the branch, within noise) |
| Zoom 0.5 (furthest a player can reach) | 123.5 | 103.6 |
| Whole map at once (not reachable by the player) | 58.0 | 75.3 |

## Accepted gaps and choices

**Art gaps** (nothing generated):
- a long footbridge;
- an aqueduct end piece;
- a dry-ground gatehouse and drawbridge;
- a ragged look for beggars.

**Placement compromises:**
- The drawbridge's moat sits on dry ground in the Keep.
- The barbican set is a Keep outwork.
- The district gate is a freestanding arch.
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
