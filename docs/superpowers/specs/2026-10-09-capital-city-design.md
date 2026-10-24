# The capital: a second, larger city — design

**Date:** 2026-10-09
**Branch:** `feat/capital-city`, worktree `C:\BURIN_NITRO\Godot\GIT\vfxProve-capital`, cut from `feat/Develop-Main` c924088.
**District plan:** `2026-10-09-capital-district-plan.png` (beside this file).

## Goal

Add a second, larger city to KAK: a river-port capital, about twice the size of Aldermere. It uses every building type from the ChatGPT art pipeline, about 73 sets, plus the existing town art, and it is the setting for the next campaign chapter.

**Pass when:**
- The capital builds and plays in a sandbox mission with every power.
- It has about 420 citizens with district routines, about 180 soldiers, and working panic and evacuation.
- It runs at 60 fps or better on BURIN_NITRO.
- Aldermere and every existing mission are byte-for-byte unchanged.

## Decisions (user, 2026-10-09)

- **City role:** a new second city. Aldermere and all current missions stay exactly as they are.
- **Size:** about 2× Aldermere. That means an 80×80 map (`Rect2(-40,-40,80,80)`) against Aldermere's 60×60, about 420 citizens and about 180 soldiers.
- **Use:** the setting of a new campaign chapter. The chapter itself (story, nights, objectives) is a separate, later spec.
- **Geography:** a river-port capital.
- **Engine approach:** A, a shared city format. Aldermere becomes one city definition and the capital a second, both on the same builder, crowd and art.
- **Art:** the approved ChatGPT pipeline. Use the existing sets; don't generate new art in this project unless a gap is found.

## Dependency

The 73 `gpt_*` sets and the tools `gpt_convert.py` and `style_match.py` live on `feat/gpt-buildings-proof`, which is not merged.
- Before M2, that branch's art and tools merge into `feat/Develop-Main` with the full checks: digest, crowd_check and the deterministic behaviour checksums.
- The dev-only showcase can merge with them; it never builds outside `town_debug`.
- Merge `feat/capital-city` with Develop-Main after that.

## 1. City layout (from the approved district plan)

Coordinates are ground cells, 1 cell = 64×32 px iso. North is −y.

| Area | Approx. rect (x0,y0,x1,y1) | Contents |
|---|---|---|
| Royal Keep (hill) | (−8,−30,8,−21) | citadel keep, towers, inner wall and gate (existing citadel sets); barracks, armoury, treasury |
| Noble quarter | (−24,−21,−9,−9) | manor, patrician houses, library, school, pavilion, gardens |
| Cathedral and civic square | (−9,−21,8,−9) | cathedral (existing), town hall, courthouse, jail with stocks, bell tower, monument, notice board |
| Guild quarter | (8,−21,18,−9) | guild hall(s), weavers, shop-houses |
| Great Market | (−24,−9,−2,4) | stalls (existing 12 designs), covered market hall, weigh house, fountain, inn, crier stage |
| Old town houses | (−2,−9,18,4) | townhouses, cottages, tavern, bathhouse, hospital, cistern (aqueduct end) |
| Old town wall | ring around (−24,−30,18,4) | existing wall, tower and gate sets; district gate arches between quarters |
| Harbour district | (18,−22,40,−2) | dock warehouse, warehouses, harbour crane, fish market, ferry landing, stables, inn |
| River | band y 6..12 across the map | widens into a harbour basin (22,−2,40,18); 2 stone bridges (x≈−14, x≈4) and a footbridge (x≈14) |
| Banks | along the river | wash houses, sluice gates, footbridge pieces |
| Crafts quarter | (−30,12,−8,22) | bakery, butcher, brewery, potter, cooper, mason's yard, lumber yard |
| New town | (−8,12,10,22) | row houses, shop-houses, chapel, wash houses on the bank |
| Tanners and dyers | (10,12,22,22) | tannery, dyers, glassworks (downstream, east) |
| Poor quarter | (−30,22,−4,34) | tenements, shacks, latrines, notice board |
| Road quarter | (−4,22,22,34) | coaching inns, stables, carts, district gate |
| New town wall | ring around (−30,12,22,34) | existing wall sets; barbican on the south road (≈7,34) |
| Monastery hill (outside, NW) | (−40,−40,−24,−12) | monastery, graveyard, chapel; leper house far off; west gate (≈−24,−13) |
| Northern woods (NE) | (14,−40,40,−22) | forest, charcoal kilns, aqueduct springs; aqueduct runs to the cistern |
| West farms | (−40,12,−30,40) | fields, barns, windmill, orchard |
| South-east fields | (22,18,40,40) | vineyard, beehives, dovecote, granary |
| Suburbs / gallows hill | (−30,34,6,40) | huts, gallows |
| Tournament field | (6,34,22,40) | grandstand, tilt barriers |

**Placement rules:**
- Each building sits on its blockout footprint (`concepts/GPT/blockout_sheets.py`).
- Streets are at least 1 cell wide between blocks, and the main avenues are 2 cells.
- Nothing taller stands directly in front of a landmark that must be seen: keep, cathedral, town hall, market hall.
- Use the existing street art (cobbles and dirt roads from the floor painter) and decor (decor batch 4) everywhere.

## 2. Engine: shared city format

### `CityDef` (new, `src/game/town/city_def.gd`)

The data for one city:
- `map: Rect2`;
- river and water rects, plus the harbour basin;
- bridges;
- roads and avenues (polylines);
- wall rings (segments, towers, gates);
- districts (`name`, `rect`, `kind`);
- plots: `{rect, height, kind, role, tag, art}` for every structure;
- landmarks, by name: `market_square`, `temple`, `citadel_origin`, `citadel_court`, `bell_tower`, `dock`, `dock_wait`, `main_gate`, `fountains`, `wells`, and others;
- routine points by kind: `home`, `work`, `queue`, `wash`, `pray`, `market`, `harbour`, `gate`, `field`, …;
- spawn rules: citizen roles and counts per district; soldier posts.

### `AldermereCity` (new, `src/game/town/cities/aldermere_city.gd`)

- Today's `TownLayout` data, moved into a `CityDef`.
- Its build functions return the same structures in the same order with the same seeds.

### `TownLayout` stays the way in

- It reads from the active city (`TownLayout.city: CityDef`, defaulting to Aldermere), so the 26 dependent files keep working.
- Constants that name Aldermere landmarks become landmark lookups (`TownLayout.landmark(&"market_square")`) where code must work in both cities. Aldermere-only mission directors (Mira's House, the Vigil, the Festival, the Procession, the Warning, the broken lanterns) keep using Aldermere's data.

### Missions pick their city

- `MissionDef` gets `city: StringName = &"aldermere"`.
- `Mission` sets the active city before building the town.
- `Town`, `TownFloor`, `ForestLayer`, `PlantLayer`, `TownDecor`, `WalkGrid` and the crowd all build from the active city.

### `CapitalCity` (new, `src/game/town/cities/capital_city.gd`)

- The layout in §1, as data plus generators for its blocks: house rows, the market, fields and forest.
- It is deterministic from its seed.

### New building types

- Each `gpt_*` set maps to a structure: an existing `Structure.Kind` plus a role or tag where that fits; otherwise a new kind.
- Each one has its own gameplay values:
  - hp;
  - height;
  - walkable or flat: bridges, the footbridge, paving, the tournament ground, fields and the vineyard;
  - fire behaviour;
  - whether it smokes (chimney keys are already in the art);
  - collapse via the engine sink.
- Damaged and ruins states come from the art sets.
- Props (wagon, hand cart) are decor pieces, not structures.

## 3. People and soldiers

- **Citizens:** about 420. The existing roles are spread per district. New roles reuse the existing person sprites and looks unless art is missing:
  - baker;
  - washer;
  - dockworker / ferryman;
  - monk;
  - trader;
  - guild craftsman;
  - noble;
  - beggar;
  - innkeeper / stable hand.
- **Routines** (data-driven from `CityDef` routine points; same scheduler as Aldermere):
  - a morning bread queue at the bakery;
  - washing at the river wash houses;
  - market traffic between the Great Market and the harbour;
  - harbour loading at the crane and warehouses;
  - chapel visits, and funerals at the graveyard after deaths;
  - cart and wagon traffic on the south road and the bridges (decor props moving on a path; no new vehicle simulation unless it's cheap).
- **Panic and evacuation:**
  - Each district escapes through its own exits: gates, bridges, the ferry, the barbican.
  - The river is a chokepoint, and bridges can be cut by destruction.
  - This reuses the alarm, bell and evacuation managers, with exit points from `CityDef`.
- **Soldiers:** about 180.
  - Posts: the Keep garrison, every gate including the barbican, wall patrol loops on both rings, the harbour watch, and bridge posts.
  - They reuse the existing soldier roles: marshals, escorts, rescue squads.

## 4. Frame rate

- **Target:** a capital mission bench of 60 fps or better on BURIN_NITRO.
  - Command: `"$G" --path . --audio-driver Dummy --disable-vsync --scene res://scenes/mission.tscn -- --bench --mission=<capital sandbox>`.
  - Take medians, on a quiet machine.
- **Aldermere:** must stay within about 3 fps of Develop-Main.
- **Profile first, then fix.** Likely levers:
  - people far off screen think less often;
  - wider structure sleep and culling;
  - larger forest and plant bands;
  - walk-grid path caching.

## Milestones (each lands with full checks)

| M | Work | Done when |
|---|---|---|
| M1 | Move Aldermere into the city format: `CityDef`, `AldermereCity`, `TownLayout` reading the active city, and the mission city field. | The digest, crowd_check, the 10 deterministic behaviour checksums, FLOW, the mission test and the bench are all identical or within noise; the test count is unchanged or higher. |
| M2 | Capital geography and plots: river, harbour, bridges, walls, roads, districts, every building on its plot, floor, forest and decor. | The capital builds in a dev scene with no errors. Each plot is on walkable or blocked ground as intended. Every district reaches every exit. Town shots are taken. |
| M3 | New building types: kinds, tags, hp, fire, smoke, walkable kinds, collapse. | Powers damage and destroy them. Tests for every type. |
| M4 | People: roles, routines, soldier posts, evacuation exits. | A sandbox shows routines and a full evacuation, with a capital crowd checksum scenario. |
| M5 | Frame rate. | Capital bench at 60 fps or better; Aldermere within about 3 fps. |
| M6 | Capital sandbox mission: free play with all powers, reachable from the mission board as a dev entry. | Playable end to end; FLOW unaffected. |

## Out of scope

- The campaign chapter's story, nights and objectives (a separate spec).
- Any Aldermere gameplay change.
- New art generation, unless a gap is found in M2. Gaps go to a ChatGPT sheet using the approved pipeline.

## Testing

- **M1:** exact equality checks on Aldermere before and after the move. They are the proof the move is safe.
- **Capital (new tests):**
  - the build succeeds with no SCRIPT ERROR;
  - plot overlap is zero;
  - walkability per kind;
  - routes are reachable between every district and every exit (walk-grid flood);
  - landmark lookups resolve in both cities;
  - a capital crowd checksum scenario, deterministic at a fixed step.
- **Performance:** the M5 bench numbers are recorded in the milestone summary.
