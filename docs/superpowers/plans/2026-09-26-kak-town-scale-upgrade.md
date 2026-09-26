# KAK Town Visual and Scale Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Execution note:** as in the visual upgrade, the art bodies and the layout numbers are authored inline by the
> controller against the reference, with the measuring tools in the loop. This plan fixes the files, interfaces,
> data, tests and targets.

**Goal:** Aldermere becomes the Scale reference's town — 32 × 32 inside 60 × 60 — laid out as the reference, with its
new buildings and countryside. The mission scales with it, and the Citadel stands in the north corner.

**Architecture:**
- TownLayout is rewritten as data for the new map: walls, towers, gatehouses, streets, landmarks, districts
  (cottages, gardens, trees), river branches, bridge, countryside.
- The code that assumed the old town reads TownLayout instead: soldier posts, the gate queue's outward direction,
  camera limits and capture shots.
- New components are art classes in `src/environment/art/`, measured by the component tool against boxes in the
  Scale reference.
- Two tools join the loop: `tune_components.py` (automatic size and colour tuning through `art_tuning.json`) and
  `match_layout.py` (landmark positions against the reference).

**Tech Stack:** Godot 4.7.2 / GDScript; Python 3 with numpy, scipy and Pillow for the tools.

**Spec:** `docs/superpowers/specs/2026-09-26-kak-town-scale-upgrade-design.md`

## Global Constraints

- `godot --headless --path . -s tools/dev/state_digest.gd` prints exactly
  `rows=19 digest=61267b7e90524d800bf1c3473a71146b blocked=000000111000000000000011000000000000000000001110000000000000 emitters=45`.
- `src/fx/` does not change. Structure art never draws from `rng` (hash the seed).
- `bash tools/test.sh` passes after every task. Changed counts and coordinates are updated to the new layout's
  exact values; a test's intent is never dropped.
- `--flow-test` passes after every phase. `--mission-test`, `--crowd-test` and the bench are re-recorded and
  reported.
- Never commit `default_bus_layout.tres` or `captures/`; never touch `.codex/`,
  `docs/HUM_Game_Design_Document_v1.docx` or `concepts/`.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Push with the gh credential helper
  (see the visual-upgrade plan).

---

### Task 0a: Tuning knobs and the automatic tuning loop

**Files:**
- Create `src/environment/art/art_tuning.gd` (`ArtTuning`) and `src/environment/art/art_tuning.json` (`{}`), plus
  `tools/dev/tune_components.py`.
- Modify `tools/dev/match_components.py`: importable `score_all()`, per-entry reference and scale, a tuning key per
  component.
- Modify `src/environment/decor.gd` (scale and tint), `src/environment/structure.gd` and
  `src/environment/art/structure_art.gdshader` (an `art_tint` uniform), and `tools/dev/preview_components.gd` (reads
  the tuning, `--only=` names).

**Interfaces:**
- `ArtTuning.scale(key: String) -> float` (default 1.0) and `ArtTuning.tint(key: String) -> Color` (default white).
  The JSON is loaded once, and `ArtTuning.reload()` rereads it.
- Keys: decor kinds lower-case (`"barrel"`), structures `"<kind>"` or `"<kind>_<tag>"` (`"house"`,
  `"house_tavern"`, `"keep"`).
- `Decor._draw` scales its art about its ground point by `ArtTuning.scale` and multiplies `self_modulate` by
  `ArtTuning.tint`. A structure multiplies its lit art by `ArtTuning.tint` in the shader (`art_tint`). Structures take
  no scale: their size is their footprint.
- `match_components.score_all(ref_images) -> dict[name, dict]`. `tune_components.py`:
  - Coordinate descent per round over (scale, r, g, b): try +step on every component at once, render once, keep
    what improved; the same for −step.
  - Steps start at 0.12 for scale and 0.06 for tint, and halve when a round gains nothing.
  - Stops after 8 rounds or when nothing improves, and writes `art_tuning.json`.

**Test:** `tests/test_art_tuning.gd` (new):
- defaults with no entry;
- a JSON entry read back;
- a Decor's draw transform scaled;
- the digest unchanged (the sandbox has no entries).

### Task 0b: The layout check

**Files:** create `tools/dev/dump_layout.gd` (writes `captures/layout.json`: every structure's rect, kind, role
and tag; the Citadel origin; the decor spots) and `tools/dev/match_layout.py`.

**`match_layout.py`:**
- Anchors the Scale reference with the corner-tower homography (spec).
- Reports each landmark's distance from the reference's (in ground units): the Citadel is exempt; the Temple,
  fountains, taverns, barracks, forge, gates, bridge, windmill, watermill and dock are measured.
- Counts the houses per district against the reference's detected roofs.
- Draws our structures over the reference to `captures/layout_overlay.png`.
- `--min-landmarks N`: exit 1 when fewer than N landmarks are within 1.5 units.

### Task 1: The new layout (Phase 1)

**Files:**
- Rewrite `src/game/town/town_layout.gd`.
- Modify `town.gd`, `town_floor.gd`, `town_decor.gd`, `walk_grid.gd`, `citadel.gd` (unchanged parts, new origin),
  `crowd.gd` (posts, gate direction, counts), `mission.gd` (pan, zoom, intro, test casts), `rules.gd` (timer,
  escape limit, ranks), `town_debug.gd` (shots).
- Update the tests to the new layout.

**Layout data (ground units), from the blueprint:**
- `MAP = Rect2(-30, -30, 60, 60)` and `TOWN = Rect2(-16, -16, 32, 32)`. Wall bands 0.7 thick inside TOWN's edge,
  cut into ≤ `WALL_PIECE` pieces.
- Corner towers 2.0 square at the corners. Wall towers 1.6 square every ~8 units along each run, leaving the gates
  clear.
- South gatehouse: the GATE `Rect2(1.7, 15.2, 2.0, 1.4)` between towers `Rect2(0.2, 14.9, 1.5, 2.0)` and
  `Rect2(3.7, 14.9, 1.5, 2.0)`. East gatehouse: the GATE `Rect2(15.2, 8.0, 1.4, 2.0)` between towers
  `Rect2(14.9, 6.5, 2.0, 1.5)` and `Rect2(14.9, 10.0, 2.0, 1.5)`.
- ROADS: N–S `Rect2(2.0, -4.6, 1.4, 20.6)`; E–W `Rect2(-15.3, 8.3, 31.3, 1.4)`; `Rect2(-15.3, -5.6, 31.3, 1.0)`;
  `Rect2(-6.5, -15.3, 1.0, 23.6)`; `Rect2(9.0, -15.3, 1.0, 23.6)`; south road `Rect2(2.0, 16.0, 1.4, 14.0)`; east
  road `Rect2(16.0, 8.3, 14.0, 1.4)`; `Rect2(-6.5, 9.7, 1.0, 5.6)`; `Rect2(9.0, 9.7, 1.0, 5.6)`.
- MARKET_SQUARE `Rect2(-3.5, -3.5, 8.5, 11.5)`: FOUNTAIN at (0.9, 5.7), and 14 stalls in rows.
- A second fountain plaza at (10, −9.8).
- TEMPLE (cathedral) `Rect2(-1.3, -11.8, 4.2, 6.2)`.
- CITADEL_ORIGIN (−10.5, −10.5), with CITADEL_AREA and COURT around it.
- Taverns: `Rect2(-11.0, -7.4, 2.4, 1.5)`, `Rect2(-5.3, -0.6, 1.6, 2.4)` and `Rect2(5.6, 2.4, 2.8, 1.8)`.
- BARRACKS `Rect2(10.3, 3.9, 4.4, 1.9)` with its yard `Rect2(10.3, 6.0, 4.6, 2.1)`; a workshop hall
  `Rect2(10.4, -1.2, 3.1, 1.6)`; the SMITHY `Rect2(13.8, -1.4, 1.5, 1.25)` with its yard.
- RIVER (south) `Rect2(-30, 20.0, 60, 3.3)`, plus RIVER_WEST `Rect2(-30, -2.0, 3.2, 22.0)`. The BRIDGE
  `Rect2(1.7, 18.6, 2.0, 6.2)`.
- EXITS: `(2.7, 29.6)` and `(29.6, 9.0)`.
- DISTRICTS: the blocks between streets, filled by `houses()` at the reference's density (≈ 80 cottages), then
  gardens and trees.
- Countryside: fields north (y −28…−24) and south (y 25…28.5), the east fields; pastures `Rect2(18.5, 1.5, 7, 5.5)`
  and `Rect2(-9, -26.5, 6.5, 5)`; a windmill at (−11.5, −24.5); a watermill `Rect2(-6, 24.6, 2, 1.6)`; a dock
  `Rect2(-2.2, 23.3, 3, 1.4)`.

**Mission scaling:**
- `Crowd.CITIZENS` 220 and `SOLDIERS` 100; posts: yard 30, walls 30, Citadel 20, patrol 20.
- `Rules.MISSION_SECONDS` 360 and `ESCAPE_LIMIT` 76; RANKS ×1.6.
- `Mission.ZOOM_MIN` 0.3, PLAY_ZOOM 0.6, and the pan limits from MAP.

**Crowd fixes:**
- A gate's outward direction is the axis away from the town (`|x| > |y|` → (±1, 0)), not `center().normalized()`.
- Patrol posts sit on the streets' centre lines from TownLayout.ROADS.

**Test:** the layout, town, walk-grid, crowd, rules, score, stability, rebuild and decor tests take the new numbers.
The Crowd yard, gate-queue and escape tests keep their intent.

**Checkpoint:** overview and landmark captures beside the reference, the layout check's numbers, the bench, and
the mission test.

### Task 2: New buildings (Phase 2)

Gatehouse (StoneArt), arched stone bridge (PropArt, BRIDGE tag `stone`), cathedral (CivicArt TEMPLE tag
`cathedral`: front towers with spires), tavern variants (HouseArt), workshop hall (CivicArt, BARRACKS-style,
tag `workshop`), farmhouses (HouseArt, `farm` role variants).
- Each gets a box in the Scale reference in `match_components.py`.
- Then the tuning loop, then the shape loop, to ≥ 85%.

### Task 3: Countryside (Phase 3)

- Windmill (a structure; its sails turn on a child node at 8 Hz steps).
- Watermill (a turning wheel).
- Dock and pier, rowing boats, a sailing ship (on the river; decor).
- Sheep and cows (decor with a two-frame idle).
- Carts, hay, the west river's waterfall (floor), and forest and rocks at the reference's density.
- All measured the same way.

### Task 4: Measure and balance (Phase 4)

- Component match (both references) and layout match.
- Bench beside `prototype-v0.02` in the same hour.
- `--mission-test` and `--crowd-test` recorded.
- Append "Changes made while executing" and tag `kak-scale-v1`.

## Changes made while executing

**Phase 0:**
- `tools/dev/tune_components.py` adds a hue guard: no tint channel strays more than 0.06 from the tint's mean. Without it the score turned the reeds blue to match the water in their crop.
- It writes `art_tuning.json` with LF endings.

**Phase 1:**
- Cottages keep 0.95 clear of the streets.
- Gate plazas stay clear for the queue. The gate-queue test counts a person within 0.6 of a spacing of their spot as settled.
- Wall towers are nudged off the streets.
- The ground inside the gates is cobbled.

**Crowd performance** (a checkpoint decision, not in the plan). Doubling the crowd halved the frame rate. Three fixes:
- LightField keeps its static lights in a 3-unit cell grid.
- People off screen are updated every third frame.
- A person's position is re-sent only when it changes.

Result: mission 63 → 77 fps, Cinderfall 28 → 35 fps.

**Phase 2:**
- The river widened to 4.4 and the stone bridge grew to 7.6. The market grew to 20 stalls.
- Not built: the gatehouse art (the gates stay between two towers), tavern variants and farmhouse variants. The existing tavern and barn art is used instead.

**Phase 3:**
- The windmill is a 0.9 × 0.9 tower, 60 px high. The watermill is `Rect2(-6.9, 25.0, 2.4, 1.9)`, 34 px high. Its wheel turns against the front (left) wall over a mill race.
- `ArtKit.fan()` draws convex polygons with more than 4 points. `poly()` only fills the first triangle of those.
- Sheep, cows, carts, the ship and the boats are decor drawn at the reference's size. The animals are static, with no idle frames.
- The west branch's head has a waterfall. Hay and the extra rocks were not added.
- Pasture animals sit on a jittered 3 × 3 grid, so none of them overlap.

**Phase 4 results** (2026-09-27):

Component match: ALL 90%. By group:

| Group | Match |
|---|---|
| Buildings | 91% |
| Fortifications | 93% |
| Land & nature | 90% |
| Props | 87% |
| Scale buildings | 87% |
| Countryside | 89% |

Countryside components, in order: windmill 89%, watermill 85%, ship 85%, boat 90%, sheep 88%, cow 93%, cart 96%.

Layout match: 15 of 15 landmarks within 1.5 units.

Bench against `prototype-v0.02`, same hour:

| Scene | v0.02 fps | Now fps |
|---|---|---|
| Mission | 106.7 | 72.7 |
| Cinderfall | 39.5 | 34.8 |

The spec estimated ~75 and ~28.

Tests and scripted runs:
- 712 checks. The digest is unchanged. FLOW 24/24.
- `--mission-test`: `dp=21.5 buildings=58 citizens=188 escaped=11 alarm=100 stability=51% citadel=0%`.
- `--crowd-test`: `citizens=167 escaped=16 alarm=93`. Queues reach about 130 at the two gates.

Escape limit (unchanged at 76):
- Escapes flow at about 0.9/s once the queues form.
- At that rate the limit falls about 106 s into the 360 s mission, or 29% of the way through. In v0.02 it fell about 69 s into 240 s, also 29%.

## Follow-up: a denser, warmer interior (2026-09-27)

Asked for after `kak-scale-v1`. A new check, `tools/dev/match_interior.py`, compares the town inside the walls as a whole. It lays the reference and our overview flat onto the ground inside the walls, then scores five things:

- how warm the colours are;
- how green;
- how saturated;
- red against blue;
- how busy the surface is.

It also reports how grey and how flat the interior is, but does not score them. The reference's walls bulge into the area it samples, so most of its grey is wall and awning stripe.

The score went from **67% to 89%** (warm 34 → 91, R-B 60 → 94, sat 66 → 84, detail 83 → 88, green 90 → 89):

- **Ground:**
  - Cobbles and flagstones are light warm beige.
  - The lawn in the house blocks is now worn ground, from bare earth to patches of grass.
  - Low shrubs and flower clumps are painted into the floor over the blocks (`SHRUB_STEP` 0.6, `SHRUB_CHANCE` 0.8).
- **Light:**
  - The ground takes a deeper gold (`Town.GROUND_EVENING` 1.06, 0.92, 0.74) than lit things (`EVENING` 1.03, 0.93, 0.80).
  - Tinting everything that gold cost the parts their colour match: component match 90% → 88%, because stone went brown and slate went grey. The split keeps component match at 89%.
- **Trees:**
  - Town trees can stand at grid corners and half-way along cell sides (`TOWN_TREE_CHANCE` 0.8): 85 inside the walls, up from 15.
  - They are always leafy oaks (tag `oak`), drawn with 16 leaf clusters instead of 30.
- **Gardens:** 85% of cottages try for a garden, up from 45%.
- **Roofs:** 30% of cottages are roofed in red tile (`HouseArt.TILE_SHARE`).

Checks and costs:
- 712 checks pass. The digest is unchanged. FLOW 24/24.
- Crowd test: escaped 15 (16 before). Mission test: escaped 10, stability 49%.
- Mission frame rate is 72.5 → 66.3 fps against `kak-scale-v1`, same hour. The cost is the ~70 extra tree nodes, not their triangles: cutting the leaf clusters took 11k primitives off and did not change the frame rate.

**Street trees (same day):**
- Trees now line the streets on the open ground between each street and its cottages (`TownLayout._street_trees()`).
- Each stands 0.3 off the street's edge, every 2.2 units, with 85% of spots planted and the two sides staggered.
- None stands at a junction, in a square or by a lamp. The street itself stays clear, and the gaps between trees let people cross.
- That adds 27 trees, for 112 inside the walls. The interior score went from 89% to 91% (green 89 → 94).
- Crowd test: 13 escaped (was 15). Mission test: 169 citizens left alive (was 177), 11 escaped.

**Hitch fix.** The crowd's walking map, `WalkGrid`, called `TownLayout.blockers()` every time a building fell. That call lays out every house, garden and tree again, and took 8.2 ms. With the extra trees, a Cinderfall felling 13 at once hitched 150 ms. `WalkGrid` now works the blockers out once, when the town is built, and a fall costs 0.22 ms.

Frame rate against `kak-scale-v1`, same hour:

| Scene | kak-scale-v1 | Now |
|---|---|---|
| Cinderfall average | 34.3 fps | 30.0 fps |
| Cinderfall worst frame | 69 ms | 66–69 ms |
| Mission | 70.4 fps | 62.0 fps |

The mission loss (about 12%) comes from the ~100 extra trees in the interior, each updated every frame.
