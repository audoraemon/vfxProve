# KAK Town Visual Upgrade (step 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Execution note:** the art bodies (the exact pixels of a roof, a merlon, a tree) cannot be written well blind.
> This plan fixes files, interfaces, data, tests and the look targets. The controller authors each art body inline,
> rendering and comparing it against the reference crops (`tools/dev/preview_kinds.gd` and `--capture-town`)
> until it matches. Then the phase's visual checkpoint goes to the user.

**Goal:** Aldermere looks like `concepts/TOWN REF/Town Visual Upgrade.png` — every component redrawn procedurally,
decor added, layout unchanged except a market fountain.

**Architecture:**
- Per-kind art moves out of `Structure` into static art classes under `src/environment/art/`. Each art class has a
  pure `plan()` that is computed once in `Structure.setup()` from a hash of the seed (never `rng`), and a `draw()` that
  paints through `Structure`'s batched primitives and `_face_color()`.
- Decor is a new lightweight y-sorted `Decor` node, placed by a pure `TownDecor.spots()` and registered with
  `EnvironmentField` so blasts char it.
- The ground is rendered once into a texture.

**Tech Stack:** Godot 4.7.2, GDScript, gl_compatibility, 640×360 viewport, headless test runner `tests/run_all.gd`.

**Spec:** `docs/superpowers/specs/2026-09-26-kak-town-visual-upgrade-design.md`

## Global Constraints

- `godot --headless --path . -s tools/dev/state_digest.gd` prints exactly
  `rows=19 digest=61267b7e90524d800bf1c3473a71146b blocked=000000111000000000000011000000000000000000001110000000000000 emitters=45`
  after every task.
- Art never calls `Structure.rng` (or `EnvironmentField.rng`); variety comes from `ArtKit.hash01(seed, salt)`.
  `_build_windows()` and the count of `_windows` entries are unchanged.
- No `draw_colored_polygon` / `draw_circle` / `draw_polyline` in per-building art: `_quad()` (3 or 4 points via
  `draw_primitive`), `draw_rect`, `draw_line(..., -1.0)` only. Existing uses in rubble, cracks and the jagged
  collapse top stay.
- Every material colour passes through `Structure._face_color()`, or is emissive: window glow and flames only.
  Scorch and frost must visibly apply to the new art.
- `src/fx/` does not change. `tools/audio/` does not change.
- `bash tools/test.sh` passes after every task. Never commit `default_bus_layout.tres` (revert it with
  `git checkout -- default_bus_layout.tres`) or anything in `captures/`. Never touch `.codex/`,
  `docs/HUM_Game_Design_Document_v1.docx` or `concepts/`.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Push: `git -c credential.helper= -c 'credential.helper=!"/c/Program Files/GitHub CLI/gh.exe" auth git-credential' push origin feat/vfx-proof`.

## File Structure

| File | Responsibility |
|---|---|
| `src/environment/art/art_kit.gd` (new, `ArtKit`) | Palette constants, `hash01`/`pick`, face-space helpers (`face_pt`, `face_quad`), shared window/door/shingle drawers |
| `src/environment/art/house_art.gd` (new, `HouseArt`) | House + barn plan/draw |
| `src/environment/art/stone_art.gd` (new, `StoneArt`) | Block masonry, merlons, walkway, portcullis, keep extras, static banners |
| `src/environment/art/civic_art.gd` (new, `CivicArt`) | Temple, barracks, fountain |
| `src/environment/art/prop_art.gd` (new, `PropArt`) | Stall, bridge, field, tree (oak/pine), torch — shared with Decor |
| `src/environment/structure.gd` | Keeps state/damage/effects; `setup()` stores `art := ArtKit.plan_for(self)`; `_draw()` dispatches; flame child node |
| `src/environment/decor.gd` (new, `Decor`) | One decor prop: kind, ground point, char/knock state, draw via `PropArt`/`DecorArt` |
| `src/environment/art/decor_art.gd` (new, `DecorArt`) | Barrel, crates, bench, fence, garden, bush, rock, lamp, bunting, scarecrow, signpost, reeds, flowers |
| `src/environment/environment_field.gd` | `add_decor()`, decor list, decor hits in `damage_radius`/`damage_lane` |
| `src/game/town/town_decor.gd` (new, `TownDecor`) | Pure placement data `spots() -> Array[Dictionary]` |
| `src/game/town/chimney_smoke.gd` (new, `ChimneySmoke`) | One node drawing all standing houses' smoke |
| `src/game/town/town_floor.gd` | Restyled ground + one-time bake |
| `src/game/town/town.gd` | Builds decor, fountain, smoke; sets wall `outer` hints |
| `src/game/town/town_layout.gd` | `FOUNTAIN` rect |
| `tests/test_art_kit.gd`, `tests/test_town_decor.gd` (new) | Hash/plan determinism + rng safety; decor placement + damage + fountain |

---

### Task 0: Baseline

- [ ] **Step 1:** Save the baseline shots. Run `SCENE=res://scenes/town_debug.tscn tools/capture.sh --capture-town`
  at `prototype-v0.01`, then run `godot --path . --audio-driver Dummy -s tools/dev/preview_kinds.gd`, and copy
  `captures/town_*.png` and `captures/kinds_*.png` to `<scratchpad>/visual/before/`.
- [ ] **Step 2:** Bench Cinderfall at `prototype-v0.01`: `SCENE=res://scenes/town_debug.tscn tools/capture.sh --bench --only=cinderfall`.
  Record the fps line in the ledger `.git/sdd/progress.md`.

### Task 1 (Phase 1): ArtKit + houses and barns

**Files:** Create `src/environment/art/art_kit.gd`, `src/environment/art/house_art.gd`, `tests/test_art_kit.gd`.
Modify `src/environment/structure.gd` (setup stores the plan; `_draw` dispatches HOUSE; `_palette` HOUSE → plaster),
`tests/run_all.gd` (register the new test).

**Interfaces (produced):**
- `ArtKit.hash01(seed: int, salt: int) -> float` in [0, 1), pure.
- `ArtKit.pick(seed: int, salt: int, n: int) -> int` in [0, n).
- `ArtKit.plan_for(s: Structure) -> Dictionary`: dispatches on kind to `HouseArt.plan(s)` and friends; `{}` for kinds without art.
- `ArtKit.face_pt(s: Structure, face: int, u: float, h: float) -> Vector2`: face 3 = the +y face (left on screen),
  1 = the +x face (right); u runs 0 at the far corner to 1 at `_s[2]`; h is px above the ground.
- `ArtKit.face_quad(s: Structure, face: int, u0: float, u1: float, h0: float, h1: float, c: Color) -> void`.
- `HouseArt.plan(s: Structure) -> Dictionary` with keys `chimney_u` (float, along the ridge), `door_face` (1|3),
  `door_u` (float), `roof_shade` (-1|0|1), `barn` (bool; true when `s.role == &"farm"`).
- `HouseArt.draw(s: Structure, light: Color, dir: Vector2) -> void`.
- `Structure.art: Dictionary` (the plan); `Structure.setup()` sets it **after** `_build_windows()` so the rng
  stream is untouched.

- [ ] **Step 1: Write the failing test** `tests/test_art_kit.gd`:

```gdscript
extends RefCounted
## ArtKit: hashed variety is deterministic, in range, and never touches a structure's rng stream.


func run(t) -> void:
	var a := ArtKit.hash01(12345, 3)
	t.check(a == ArtKit.hash01(12345, 3), "hash01 is deterministic")
	var in_range := true
	var seen := {}
	for i in 200:
		var h := ArtKit.hash01(i * 7919, i % 5)
		in_range = in_range and h >= 0.0 and h < 1.0
		seen[ArtKit.pick(i * 31, 1, 4)] = true
	t.check(in_range, "hash01 stays in [0, 1)")
	t.check(seen.size() == 4, "pick reaches every option")
	var s := Structure.new().setup(Rect2(0, 0, 1.3, 0.95), 23.0, Structure.Kind.HOUSE, 99)
	var twin := Structure.new().setup(Rect2(0, 0, 1.3, 0.95), 23.0, Structure.Kind.HOUSE, 99)
	t.check(s.art == twin.art and not s.art.is_empty(), "same seed, same house plan")
	t.check(s.rng.state == twin.rng.state, "planning leaves the rng stream alone")
	var fresh := RandomNumberGenerator.new()
	fresh.seed = 99
	for w in s._windows:
		fresh.randf()
	t.check(s.rng.randi() == fresh.randi(), "the rng stream after setup is exactly the windows' draws")
	var barn := Structure.new()
	barn.role = &"farm"
	barn.setup(Rect2(0, 0, 1.2, 1.4), 20.0, Structure.Kind.HOUSE, 5)
	t.check(barn.art.barn and not s.art.barn, "farm houses plan as barns")
	t.check(s.art.door_face in [1, 3] and s.art.roof_shade in [-1, 0, 1], "door face and roof shade in range")
	s.free()
	twin.free()
	barn.free()
```

(`role` must be set before `setup()` for the barn case. `Structure.setup()` reads `role` when planning, and
`EnvironmentField.add_structure()` sets `role` after `setup()`, so Step 3 also moves the `s.role = role` assignment
in `add_structure` into a `setup()` parameter: `setup(rect, h, k, seed, role := &"")`.)

- [ ] **Step 2:** Run `bash tools/test.sh`. Expected: FAIL (`ArtKit` not found).
- [ ] **Step 3: Implement.**
  - `ArtKit`: `hash01` is `float(absi(hash(Vector2i(seed, salt))) % 100003) / 100003.0`. Add `pick`, `face_pt`,
    `face_quad` and the palette constants from the spec table.
  - `Structure.setup(rect, h, k, seed_value, role_value := &"")` sets `role` first, then does everything it did
    before, then `art = ArtKit.plan_for(self)`. `EnvironmentField.add_structure()` passes `role` through, and keeps
    its `s.role = role` line (harmless).
  - `HouseArt.draw` look targets (spec §Components 1, reference crops `houses_nw`, `north_houses`, `south_houses`):
    stone base course, plaster faces, timber frame, slate roof with overhang, courses, ridge, gable triangle,
    chimney, framed windows (lit flag = `s._windows[i % n][3]`, or hashed when `n == 0`), plank door. Barns: red
    tile roof, plank walls.
  - `Structure._draw()`: for `HOUSE`, when the house is standing and not collapsing, call
    `HouseArt.draw(self, light, dir)` instead of `_draw_box` + `_draw_windows` + `_draw_roof`. Collapsing,
    destroyed and laser-cut houses keep the generic path, with `_palette()` HOUSE changed to plaster tones.
- [ ] **Step 4:** Run `bash tools/test.sh` and the digest. Expected: all pass, and the digest line is unchanged.
- [ ] **Step 5: Visual iteration.** Run `preview_kinds.gd` and `--capture-town`; crop the house districts; compare
  against the reference crops; iterate.
- [ ] **Step 6:** Bench Cinderfall. Commit `feat: town houses redrawn to the visual-upgrade reference`.
- [ ] **Step 7: CHECKPOINT.** Show the user before/after crops (town_market, town_overview district, a sandbox
  house) and wait for approval.

### Task 2 (Phase 2): Stone — walls, towers, gates, Citadel

**Files:** Create `src/environment/art/stone_art.gd`. Modify `structure.gd` (dispatch for CASTLE_WALL/KEEP/GATE;
`var outer := Vector2.ZERO`; `var art_tag := &""`; a `_flames` child node for wall-top torches; banner restyle),
`src/game/town/town.gd` (outer hints), `src/game/town/citadel.gd` (`keep.art_tag = &"keep"`), `tests/test_art_kit.gd`.

**Interfaces:**
- `Structure.outer: Vector2`: the unit ground direction toward the outside of the curtain. ZERO means merlons on
  every edge, which keeps the sandbox and Citadel look.
- `Town.build()` sets it for every CASTLE_WALL piece from `TownLayout.TOWN` (north run (0,-1), south (0,1),
  west (-1,0), east (1,0)). Pieces are identified by comparing the rect's centre to TOWN's edges.
- `StoneArt.plan(s) -> Dictionary` keys: `torch` (bool; hashed, about 1 in 3 CASTLE_WALL pieces with outer != ZERO),
  `banners` (Array of face ids for KEEP: faces whose width ≥ 36 px get one).
- `StoneArt.draw(s, top_c, right_c, left_c, light, dir)`.

- [ ] **Step 1: Failing tests** (append to `tests/test_art_kit.gd`):

```gdscript
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var outer_ok := true
	var torches := 0
	var pieces := 0
	for st in env.structures():
		if st.kind == Structure.Kind.CASTLE_WALL and st.role == &"wall":
			pieces += 1
			outer_ok = outer_ok and st.outer.length() == 1.0
			var c := st.center()
			if st.outer == Vector2(0, -1):
				outer_ok = outer_ok and c.y < 0.0
			elif st.outer == Vector2(1, 0):
				outer_ok = outer_ok and c.x > 0.0
			if st.art.torch:
				torches += 1
	t.check(outer_ok, "every town wall piece knows which way is out")
	t.check(torches >= pieces / 5 and torches <= pieces / 2, "about a third of the wall pieces carry a torch")
	t.check(town.citadel.keep.art_tag == &"keep", "the Citadel keep is tagged for its extras")
	town.teardown()
	town.free()
	env.free()
```

- [ ] **Step 2:** `bash tools/test.sh`. Expected: FAIL.
- [ ] **Step 3: Implement.** Look targets (reference crops `citadel`, `wall_se`, `river_bridge`):
  - big-block masonry with a hashed tint per block;
  - on walls with an outer hint, merlons on the outer edge only, a pale walkway and a low inner lip;
  - hashed wall-top torches whose flame animates on the `_flames` child at 8 Hz steps. The child is not the
    building, so the piece stays cached;
  - KEEP banners blue with a white cross and gold finials (the moving `_banner` node too), lit slit windows;
  - GATE: a black portcullis grid;
  - keep (`art_tag == &"keep"`): a flag pole with a waving flag drawn by `_banner`, and steps plus an arched door
    on its left face.
- [ ] **Step 4:** Tests + digest. Expected: pass and unchanged.
- [ ] **Step 5:** Visual iteration (town_citadel, town_main_gate, town_side_gate, sandbox castle).
- [ ] **Step 6:** Bench. Commit `feat: stone walls, towers, gates and the Citadel redrawn`.
- [ ] **Step 7: CHECKPOINT** with the user.

### Task 3 (Phase 3): Temple, barracks, stalls, bridge, fields, trees, torch

**Files:** Create `src/environment/art/civic_art.gd`, `src/environment/art/prop_art.gd`. Modify `structure.gd`
(dispatch; delete `_draw_roof`, `_draw_stall`, `_draw_bridge`, `_draw_furrows`, `_draw_tree` and `_draw_torch`
once their replacements land; delete `_draw_opening`/`_draw_gate` if StoneArt replaced them), `tests/test_art_kit.gd`.

**Interfaces:**
- `PropArt.tree(ci: CanvasItem, base: Vector2, size: float, species: int, cols: Array, scorch: float) -> void`
  (species 0 = oak, 1 = pine). `cols` = [lit, mid, dark, outline]. It is shared with `Decor`.
- `PropArt.plan(s)` keys: `species` (TREE), `crop` (FARM_FIELD: 0 wheat, 1 cabbage), `cloth` (MARKET_STALL: the
  existing `rng.seed % 3` rule stays, so stalls keep their colours).
- `CivicArt.plan(s)` keys: `forge_end` (BARRACKS: 1 = the +x end).

- [ ] **Step 1: Failing tests:**

```gdscript
	var species := {}
	var crops := {}
	for i in 40:
		var tr := Structure.new().setup(Rect2(0, 0, 0.7, 0.7), 26.0, Structure.Kind.TREE, i * 104729)
		species[tr.art.species] = true
		tr.free()
		var fd := Structure.new().setup(Rect2(0, 0, 2.6, 1.8), 3.0, Structure.Kind.FARM_FIELD, i * 7907)
		crops[fd.art.crop] = true
		fd.free()
	t.check(species.size() == 2, "trees come as oaks and pines")
	t.check(crops.size() == 2, "fields come as wheat and cabbages")
	var bar := Structure.new().setup(Rect2(0, 0, 4.2, 1.9), 36.0, Structure.Kind.BARRACKS, 3)
	t.check(bar.art.forge_end == 1, "the barracks forge stands at its east end")
	bar.free()
```

- [ ] **Step 2:** `bash tools/test.sh`. Expected: FAIL.
- [ ] **Step 3: Implement** (reference crops `temple`, `barracks`, `center_market`, `river_bridge`, `farms`,
  `ground_trees`), following spec §Components 4–10.
- [ ] **Step 4:** Tests + digest. Also run `preview_kinds.gd` for the destroyed row: rubble, burnt fields and
  felled stumps must still read.
- [ ] **Step 5:** Visual iteration.
- [ ] **Step 6:** Bench. Commit `feat: temple, barracks, stalls, bridge, fields and trees redrawn`.
- [ ] **Step 7: CHECKPOINT** with the user.

### Task 4 (Phase 4): Ground bake and river

**Files:** Modify `src/game/town/town_floor.gd`. Test in `tests/test_town_decor.gd` (new; also registered in
`run_all.gd`).

**Interfaces:**
- `TownFloor.TRAILS: Array[PackedVector2Array]`: decorative dirt-trail polylines in ground units, clear of the
  walls. `TownDecor` reads it to keep decor off the trails.
- `TownFloor` builds a `SubViewport` (`render_target_update_mode = UPDATE_ONCE`, transparent background off) sized
  to the iso bounds of `FILL`. Inside it sit a ground-unit layer (under `Iso.BASIS`) and a screen-space detail
  layer. It shows the result through a `Sprite2D` placed so the pixels line up with the old drawing.
  `RiverGlints` stays live. Headless (dummy renderer): skip the bake and draw directly as today.

- [ ] **Step 1: Failing test:**

```gdscript
extends RefCounted
## Town decor placement, the fountain, and the floor's trails.


func run(t) -> void:
	var trails_ok := not TownFloor.TRAILS.is_empty()
	for tr: PackedVector2Array in TownFloor.TRAILS:
		for p in tr:
			trails_ok = trails_ok and not TownLayout.TOWN.grow(0.8).has_point(p)
	t.check(trails_ok, "dirt trails stay outside the walls")
```

- [ ] **Step 2:** `bash tools/test.sh`. Expected: FAIL.
- [ ] **Step 3: Implement.** Organic grass (value noise over several greens instead of 1-unit cells), screen-space
  tufts/flowers/pebbles, trails, tan earth, irregular cobbles, plaza, saturated river with stone banks. Then the
  bake.
- [ ] **Step 4:** Tests + digest.
- [ ] **Step 5:** Visual iteration (town_overview, town_river_farms). Also bench idle and Cinderfall: the bake
  should not cost frames.
- [ ] **Step 6:** Commit `feat: the ground, redrawn and baked once`.
- [ ] **Step 7: CHECKPOINT** with the user.

### Task 5 (Phase 5a): Decor node, placement and damage

**Files:** Create `src/environment/decor.gd`, `src/environment/art/decor_art.gd`, `src/game/town/town_decor.gd`.
Modify `environment_field.gd`, `town.gd` (build/teardown decor), `tests/test_town_decor.gd`.

**Interfaces:**
- `Decor.Kind { BARREL, CRATES, BENCH, FENCE, GARDEN, BUSH, ROCK, OAK, PINE, LAMP, BUNTING, SCARECROW, SIGNPOST, REEDS, FLOWERS }`.
- `Decor.setup(kind: Decor.Kind, at: Vector2, size: Vector2, seed_value: int) -> Decor`. `at` is the ground point
  of its sort corner (south-east), and `position = Iso.ground_to_screen(at)`.
- `Decor.char := 0.0` (0..1), `Decor.down := false`, `Decor.hit(amount: float, kind: StringName) -> void`:
  amount ≥ 30 or `kind == &"stone"` knocks it down (hidden, or a stump for trees); otherwise it chars by
  `amount / 60`.
- `EnvironmentField.add_decor(d: Decor) -> void` and `EnvironmentField.decor() -> Array[Decor]`. `damage_radius`
  and `damage_lane` call `d.hit()` for decor in range, after the structures loop. With no decor they do nothing.
- `TownDecor.spots() -> Array[Dictionary]` of `{kind, at, size, seed}`, deterministic.

- [ ] **Step 1: Failing tests** (append to `tests/test_town_decor.gd`):

```gdscript
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var spots := TownDecor.spots()
	t.check(spots.size() >= 120, "the town gets plenty of decor")
	var inside_ok := true
	var outside_ok := true
	var no_overlap := true
	for d in spots:
		var at: Vector2 = d.at
		for st in env.structures():
			if not st.walkable and st.footprint.grow(-0.05).has_point(at):
				no_overlap = false
		if TownLayout.TOWN.has_point(at):
			inside_ok = inside_ok and grid.is_blocked(at)
		else:
			for road: Rect2 in TownLayout.ROADS:
				outside_ok = outside_ok and not road.grow(1.0).has_point(at)
			for ex: Vector2 in TownLayout.EXITS:
				outside_ok = outside_ok and at.distance_to(ex) >= 1.0
			outside_ok = outside_ok and not TownLayout.RIVER.has_point(at)
	t.check(inside_ok, "decor inside the walls only stands where people already cannot walk")
	t.check(outside_ok, "decor outside keeps off the roads, the exits and the river")
	t.check(no_overlap, "no decor stands inside a building")
	var d0 := Decor.new().setup(Decor.Kind.BARREL, Vector2(0.5, 0.5), Vector2(0.3, 0.3), 1)
	env.add_decor(d0)
	env.damage_radius(Vector2(0.5, 0.5), 1.0, 12.0, &"nova")
	t.check(d0.char > 0.0 and not d0.down, "a light hit chars decor")
	env.damage_radius(Vector2(0.5, 0.5), 1.0, 99999.0, &"nova")
	t.check(d0.down, "a lethal hit knocks it down")
	town.teardown()
	town.free()
	env.free()
```

(If `WalkGrid` has no `is_blocked(g: Vector2) -> bool`, add one: `grid.is_point_solid(_cell_of(g))`.)

- [ ] **Step 2:** `bash tools/test.sh`. Expected: FAIL.
- [ ] **Step 3: Implement.** Placement rules:
  - Barrels and crates against house and barracks walls.
  - Gardens and benches in the blocked strips between houses.
  - Bunting between two market torches.
  - Lamps beside the market and gates.
  - Bushes and flowers along the inside of the walls.
  - Outside: oaks, pines, rocks, bushes, fences along the trails, reeds on both river banks, a scarecrow by the
    fields, a signpost at the east road.
  Every spot is validated by the rules the test checks. `Decor` draws only through `DecorArt`/`PropArt` with
  batched primitives, and redraws only when hit or when its light bucket changes (checked at 4 Hz, staggered).
- [ ] **Step 4:** Tests + digest + `--flow-test` + `--mission-test`. Decor changes no pathing, so escaped stays 21.
- [ ] **Step 5:** Visual iteration + bench.
- [ ] **Step 6:** Commit `feat: decor fills the town`.

### Task 6 (Phase 5b): Fountain and chimney smoke

**Files:** Modify `structure.gd` (`Kind.FOUNTAIN` appended last, hp 80, not walkable), `civic_art.gd`
(fountain draw), `town_layout.gd` (`const FOUNTAIN := Rect2(-0.45, -0.45, 0.9, 0.9)`), `town.gd` (add the
fountain **after** the Citadel so every other seed is unchanged; build `ChimneySmoke`). Create
`src/game/town/chimney_smoke.gd`. Update `tests/test_town_decor.gd`.

**Interfaces:**
- `Town.fountain: Structure`.
- `ChimneySmoke.setup(houses: Array[Structure]) -> ChimneySmoke`, and `ChimneySmoke.wisp_count() -> int` (standing
  houses with a chimney).

- [ ] **Step 1: Failing tests:**

```gdscript
	var env2 := EnvironmentField.new()
	var town2 := Town.new()
	town2.build(env2)
	t.check(town2.fountain != null and town2.fountain.kind == Structure.Kind.FOUNTAIN, "the market has a fountain")
	t.check(env2.blocked(Vector2(0, 0)), "people walk round the fountain")
	var houses: Array[Structure] = []
	for st in env2.structures():
		if st.kind == Structure.Kind.HOUSE and st.role == &"house":
			houses.append(st)
	var smoke := ChimneySmoke.new().setup(houses)
	var before := smoke.wisp_count()
	t.check(before == houses.size(), "every house smokes")
	houses[0].destroy(houses[0].center(), &"nova")
	t.check(smoke.wisp_count() == before - 1, "a fallen house stops smoking")
	smoke.free()
	town2.teardown()
	town2.free()
	env2.free()
```

- [ ] **Step 2:** `bash tools/test.sh`. Expected: FAIL.
- [ ] **Step 3: Implement.**
  - Fountain look: a round stone basin as an octagon of quads, blue water, a pillar with a small upper bowl, and
    a stepped sparkle.
  - The smoke node sits in the fx back layer and redraws at 8 Hz: each wisp is 4 pale puffs rising and fading.
- [ ] **Step 4:** Tests + digest + flow. Run `--mission-test` and record the new escaped number (the fountain
  moves paths). Update any test that pins `escaped`.
- [ ] **Step 5:** Visual iteration + bench.
- [ ] **Step 6:** Commit `feat: a market fountain and chimney smoke`.
- [ ] **Step 7: CHECKPOINT** (Phase 5) with the user.

### Task 7: Wrap

- [ ] Full gates: tests, digest, flow 24/24, mission-test, the bench beside `prototype-v0.01` in the same hour.
- [ ] Append "Changes made while executing" to this plan. Commit `docs: record what changed during the town
  visual upgrade`. Tag `kak-visual-v1` and push the branch and the tag.
