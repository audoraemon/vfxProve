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
