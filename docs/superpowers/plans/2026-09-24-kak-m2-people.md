# KAK Milestone 2 — The People of Aldermere Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fill the town with 110 citizens and 50 soldiers who walk real paths: citizens wander, panic, flee to the exits and queue at the gates; soldiers hold their posts, rally to the Citadel when the alarm rises or it is first hit, and hold their ground in its rubble. Every effect keeps killing, knocking, pulling, freezing and lifting them.

**Architecture:** People are the existing unit (`DummyEnemy`) with two new looks and a brain (`Person`), so all eleven effects' reactions keep working unchanged. Walkability moves out of "is a building here" into a `WalkGrid` (an `AStarGrid2D` over the map) that knows the river is impassable, that a fallen bridge closes the south route, and that rubble can be walked over. `Crowd` owns spawning, panic, gate queues, the alarm, the rally and escapes, and it is driven by the signals the town already emits.

**Tech Stack:** Godot 4.7.2 (GDScript, GL Compatibility), headless test runner `tests/run_all.gd`, capture/bench tools in `tools/`.

**Spec:** `docs/superpowers/specs/2026-09-19-kak-one-mission-game-design.md` — §3 (people), §2 (the town's routes and exits), §7 (testing and performance). This is milestone 2 of its §8 build order. Milestone 1 (shared Battlefield, the town, the fortified Citadel, the debug scene) is done and tagged `kak-m1-town`; milestones 3–5 (rules + HUD, screens, polish) come later.

## Global Constraints

- Engine: `F:\Godot\Godot_v4.7.2-stable_win64_console.exe` (Git Bash: `/f/Godot/Godot_v4.7.2-stable_win64_console.exe`), renderer `gl_compatibility`.
- Viewport 640×360, nearest filtering, `2d/snap/snap_2d_vertices_to_pixel=true`: pixel lines are hairlines (`width = -1.0`); never `draw_line` with width ≥ 1.
- Iso: one ground unit = one 64×32 cell; `Iso.ground_to_screen(g) = ((g.x - g.y) * 32, (g.x + g.y) * 16)`. Town coordinates: origin at the town centre, plan north = −y.
- The 11 approved effects and the effect toolkit (`src/fx/`) do not change. People must stay ordinary `DummyEnemy` instances in `EnemyField`, so every effect's kill, knock, pull, freeze and lift keeps working on them.
- New game code lives in `src/game/` (town pieces in `src/game/town/`, people in `src/game/crowd/`).
- Art is procedural, in the existing pixel-unit style (see `DummyEnemy._draw_body` and `_draw_orc`); no new external assets.
- Tests: `bash tools/test.sh` must end `checks=<N> failures=0`; the 296 checks from milestone 1 keep passing. Suites are `extends RefCounted` scripts with `static func run(t) -> void`, registered in `tests/run_all.gd`; use `t.check(cond, msg)` and `t.near(a, b, eps, msg)`.
- Behaviour gate for changes to `Structure`/`EnvironmentField`/`DummyEnemy`: `/f/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tools/dev/state_digest.gd` must keep printing `rows=19`, `digest=61267b7e90524d800bf1c3473a71146b`, `blocked=000000111000000000000011000000000000000000001110000000000000`, `emitters=45`. Never edit that tool or those values. Screenshots are the weaker check — the sandbox's hit-stop is timed against real time, so effect frames drift between identical runs; the `idle.png` frame is exact.
- Performance (spec §7): the full town with 160 people must average **50+ fps during Cinderfall**. Milestone 1 left the town at ~123 fps idle and ~37.6 fps during Cinderfall with 40 units, and measured each unit at ~0.047 ms/frame — so people get cheaper before they get numerous (Task 1).
- The game's name in any text is **Kingdoms Amid Kataclysm** / **KAK** (never KWAI or HUM).
- GDScript style: tabs, typed vars; explicit types when a value comes from an untyped Array/Dictionary; `##` doc comments like the surrounding code.
- Commit after each task; every message ends with a blank line and `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`. Commit new scripts with their generated `.gd.uid` files.
- Leave the untracked `.codex/` folder and `docs/HUM_Game_Design_Document_v1.docx` alone.
- **User checkpoints:** after Task 3 (how citizens and soldiers look) and after Task 5 (the town alive, with the crowd captures and the bench numbers), the controller shows the images to the user and waits for approval.

## Numbers from the spec (§3)

| Thing | Value |
|---|---|
| Citizens / soldiers | 110 / 50 |
| Escape limit | 38 citizens escaped = mission failed (milestone 3 enforces it; milestone 2 counts) |
| Fleeing speed | 1.2 units/s (calm 0.6, panicked 0.9) |
| Panic triggers | a power cast within ~7 units, a building destroyed within ~4 units, or the alarm |
| Alarm | +2 per building destroyed, +0.5 per person killed, +10 on the first Citadel hit; 25% = soldiers rally, 50% = every citizen flees |
| Gates | about one person through every 0.6 s |
| Soldier posts | 20 drilling in the barracks yard, 12 on wall towers and gates, 10 guarding the Citadel, 8 patrolling the streets in pairs |
| After the Citadel falls | soldiers hold their ground in its rubble |

## File Structure

| File | Change | Responsibility |
|---|---|---|
| `src/enemies/dummy_enemy.gd` | modify | redraw only when its art changes; `walk_speed` as a variable; two new looks (`CITIZEN`, `SOLDIER`) |
| `src/game/town_debug.gd` | modify | `--units=N` for benching; then the crowd, its HUD counts, and the crowd capture/bench modes |
| `src/game/town/walk_grid.gd` | new | `class_name WalkGrid`: where people may walk (A* grid, river, bridge, rubble) |
| `src/game/crowd/person.gd` | new | `class_name Person extends DummyEnemy`: citizen/soldier looks and brain |
| `src/game/crowd/crowd.gd` | new | `class_name Crowd extends Node`: spawning, panic, gates, alarm, rally, escapes |
| `src/game/town/town.gd` | modify | `teardown()` so a mission can be rebuilt without clearing the whole field |
| `src/game/town/citadel.gd` | modify | `setup()` resets its own state so it can be rebuilt |
| `tests/test_walk_grid.gd`, `tests/test_person.gd`, `tests/test_crowd.gd`, `tests/test_rebuild.gd` | new | headless suites |
| `tests/run_all.gd` | modify | registers the new suites |
| `README.md` | modify | crowd controls, checks and numbers |

Expected `checks=` after each task: Task 1 → 296, Task 2 → 312, Task 3 → 328, Task 4 → 351, Task 5 → 351, Task 6 → 362.

---

### Task 1: Cheaper people

**Files:**
- Modify: `src/enemies/dummy_enemy.gd`, `src/game/town_debug.gd`

**Interfaces:**
- Consumes: `LightField.sample_signature(g: Vector2, color_steps: float, dir_steps: float) -> int` (added in milestone 1's performance pass).
- Produces:
  - `DummyEnemy.walk_speed: float` (defaults to `WALK_SPEED` = 0.6) used by the WANDER state, so a brain can walk faster.
  - `DummyEnemy` redraws only when its own art changes, not every frame.
  - `town_debug.gd` accepts `--units=N` (default `UNIT_COUNT`) so the bench can run with 160 units.

**Why:** milestone 1 measured `DummyEnemy` at ~0.047 ms per unit per frame, because every unit samples the light field and calls `queue_redraw()` every frame for art that only changes a few times a second. 160 units would add ~7.6 ms to a frame that already costs 25.9 ms during Cinderfall. Cut the per-unit cost first; the brains in Task 3 add their own.

- [ ] **Step 1: Measure first**

```bash
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/town_debug.tscn --audio-driver Dummy --disable-vsync --max-fps 0 -- --bench
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/town_debug.tscn --audio-driver Dummy --disable-vsync --max-fps 0 -- --bench --only=cinder
```

Run each twice and note the medians (this machine's numbers swing 10–15%). These are your "40 units" baseline.

- [ ] **Step 2: Add `--units=N` to the debug scene**

In `src/game/town_debug.gd`, `_rebuild()` currently ends with:

```gdscript
	_bf.ctx.field.spawn(UNIT_COUNT, _bf.ctx.world, _bf.rng)
```

Replace that line with:

```gdscript
	var wanted := Battlefield.arg_value(OS.get_cmdline_user_args(), "--units")
	_bf.ctx.field.spawn(int(wanted) if wanted != "" else UNIT_COUNT, _bf.ctx.world, _bf.rng)
```

Then measure the cost of 160 of today's units, twice each:

```bash
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/town_debug.tscn --audio-driver Dummy --disable-vsync --max-fps 0 -- --bench --units=160
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/town_debug.tscn --audio-driver Dummy --disable-vsync --max-fps 0 -- --bench --only=cinder --units=160
```

Record all four medians in your report — they are the numbers Task 1 has to beat and the numbers milestone 2's acceptance is judged against.

- [ ] **Step 3: Make the unit's speed a variable**

In `src/enemies/dummy_enemy.gd`, after the line `const WALK_SPEED := 0.6`, the class already declares its other tunables. Add this variable next to `lift_target` (after the line `var lift_target := 3.0`):

```gdscript
## Ground units per second while wandering; a brain raises it to run (Person's flee speed).
var walk_speed := WALK_SPEED
```

Then in `tick()`, in the `State.WANDER` branch, change:

```gdscript
					_move(to.normalized() * WALK_SPEED * delta)
```

to:

```gdscript
					_move(to.normalized() * walk_speed * delta)
```

- [ ] **Step 4: Redraw only when the art changes**

`_process()` currently is:

```gdscript
func _process(delta: float) -> void:
	tick(delta)
	if lights != null:
		var l := lights.sample(ground_pos)
		var amb := lights.ambient
		modulate = Color(amb + l.r * 2.5, amb + l.g * 2.5, amb + l.b * 2.5, modulate.a)
	queue_redraw()
```

Replace it, and add the helper below it:

```gdscript
func _process(delta: float) -> void:
	tick(delta)
	if lights != null:
		var l := lights.sample(ground_pos)
		var amb := lights.ambient
		modulate = Color(amb + l.r * 2.5, amb + l.g * 2.5, amb + l.b * 2.5, modulate.a)
	# Pixel art changes a few times a second, not every frame: redraw only when something visible moved.
	var sig := _art_signature()
	if sig != _drawn_art:
		_drawn_art = sig
		queue_redraw()


## Everything the unit's drawing depends on, quantized to what a pixel can show. Equal signatures draw
## identically, so the frame can be skipped.
func _art_signature() -> int:
	if state == State.DEAD:
		# Death animations move every frame; let them redraw.
		return int(_dead_time * 1000.0) + 1
	var walk := int(_anim * (5.0 if look == Look.ORC else 6.0)) % 2
	var sig := hash([walk, _facing, int(_lift), int(_frozen * 8.0), int(_flash * 40.0), state])
	return hash([sig, int(modulate.r * 24.0), int(modulate.g * 24.0), int(modulate.b * 24.0)])
```

and declare the cache next to the other private state (after `var _shards: Array[Vector4] = []`):

```gdscript
## Last drawn art signature; -1 forces the first draw.
var _drawn_art := -1
```

Note: the unit's node position still follows `ground_pos` every frame through `_sync_position()`, so a walking unit keeps moving smoothly without redrawing its pixels — only its limbs' two-frame walk cycle, facing, lift, freeze, flash, state and light tint need a redraw.

- [ ] **Step 5: Measure again and decide whether that is enough**

Re-run all four benches from Steps 1–2 (twice each, medians). Expected shape of the result: 40 units roughly unchanged (they were never the bottleneck at that count), 160 units much closer to the 40-unit numbers than before.

Gate for this task: **with 160 units, idle ≥ 90 fps and Cinderfall ≥ 45 fps.** The milestone's real target (50+ fps with 160 people during Cinderfall) has to survive the brains added in Tasks 3–4, so leave headroom here.

If the gate is not met, measure what dominates before changing anything else — the same way milestone 1's performance pass did (`.git/sdd/perf-report.md` records its method and its attribution table; read it). Report the attribution and the smallest fix you found. Do not convert unit drawing to `draw_primitive` in this task: `DummyEnemy` draws rects, which the renderer already batches, and the report shows polygons were the problem.

- [ ] **Step 6: Check nothing else moved**

```bash
bash tools/test.sh
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tools/dev/state_digest.gd
bash tools/dev/sandbox_baseline.sh captures/m2_task1
python tools/dev/compare_captures.py captures/m1_base_a captures/m2_task1 'idle.png'
```

Expected: `checks=296 failures=0`; the digest exactly as in the Global Constraints; `idle.png` `worst_mean_diff=0.000`. Then open two or three of `captures/m2_task1/judgement_*.png` and `cinder_*.png` and confirm the units look the same as in `captures/m1_base_a/` (same poses, same tint) — those frames drift run to run, so judge them by eye, not by number.

If `captures/m1_base_a/` is missing, recreate the reference from the previous commit first: `git stash`, `bash tools/dev/sandbox_baseline.sh captures/m1_base_a`, `git stash pop`.

- [ ] **Step 7: Commit**

```bash
git add src/enemies/dummy_enemy.gd src/game/town_debug.gd
git commit -m "perf: units redraw only when their art changes" -m "Every unit sampled the light field and redrew its pixels 60 times a second for a two-frame walk cycle. The drawing now follows a quantized art signature, the wander speed is a variable a brain can raise, and the debug scene takes --units=N so the crowd's cost can be measured before it exists." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 2: Where people may walk

**Files:**
- Create: `src/game/town/walk_grid.gd`
- Modify: `tests/run_all.gd`
- Test: `tests/test_walk_grid.gd`

**Interfaces:**
- Consumes: `EnvironmentField.structures()` / `structure_destroyed(s)`, `Structure.footprint` / `walkable` / `destroyed`, `Town.bridge`, `TownLayout.MAP` / `RIVER` / `EXITS`.
- Produces (`class_name WalkGrid extends RefCounted`):
  - `const CELL := 0.5`, `const BODY := 0.15`
  - `func setup(env: EnvironmentField, town: Town) -> WalkGrid` — builds the grid and connects `structure_destroyed`
  - `func walkable(g: Vector2) -> bool`
  - `func path(from: Vector2, to: Vector2) -> PackedVector2Array` — waypoints in ground units, empty when there is no route; a goal inside a building routes to the nearest free cell beside it
  - `func nearest_exit(from: Vector2) -> Vector2` — the closest exit with a route, or `Vector2.INF`
  - `func nearest_walkable(g: Vector2, max_cells := 8) -> Vector2` — `g` if free, else the closest free cell's centre, or `Vector2.INF`
  - `func world_to_id(g: Vector2) -> Vector2i`, `func id_to_world(id: Vector2i) -> Vector2`
- Rules: a standing, non-walkable building's footprint (grown by `BODY`) is solid; rubble is not; the river is solid except where the bridge still stands; when the bridge falls the river closes under it. Gates, the bridge and farm fields are walkable while they stand (`Structure.walkable`).

- [ ] **Step 1: Write the failing test**

Create `tests/test_walk_grid.gd`:

```gdscript
extends RefCounted
## Where people may walk: buildings block, rubble does not, the river blocks except at the bridge, and a
## fallen bridge closes the south route.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)

	t.check(grid.walkable(Vector2(0, 0)), "the market crossroads is walkable")
	t.check(not grid.walkable(TownLayout.TEMPLE.get_center()), "the temple blocks")
	t.check(not grid.walkable(Vector2(-6.0, 12.2)), "the river blocks")
	t.check(grid.walkable(Vector2(0, 12.2)), "the bridge crosses it")
	t.check(not grid.walkable(Vector2(0, -8.7)), "the town wall blocks")
	t.check(grid.walkable(TownLayout.MAIN_GATE.get_center()), "the main gate is a way through")

	# A route out of town uses the gate and the bridge.
	var south := grid.path(Vector2(0, 0), TownLayout.EXITS[0])
	var over_water := false
	var through_gate := false
	for p: Vector2 in south:
		over_water = over_water or (p.y > 11.4 and p.y < 13.0)
		through_gate = through_gate or TownLayout.MAIN_GATE.grow(0.3).has_point(p)
	t.check(south.size() > 0 and over_water and through_gate, "the south route runs through the gate and over the bridge (%d points)" % south.size())
	t.check(grid.path(Vector2(0, 0), TownLayout.EXITS[1]).size() > 0, "the east route is open too")
	t.near(grid.nearest_exit(Vector2(0, 6.0)).y, TownLayout.EXITS[0].y, 0.001, "from the south of town the south exit is nearest")

	# A goal inside a building still gives a route to its doorstep.
	var to_temple := grid.path(Vector2(0, 0), TownLayout.TEMPLE.get_center())
	t.check(to_temple.size() > 0 and not grid.walkable(TownLayout.TEMPLE.get_center()), "a goal inside a building routes beside it")

	# Rubble is walkable: destroying the temple opens its ground.
	for s in env.structures():
		if s.role == &"temple":
			s.destroy(Vector2(0, 0), &"stone")
	t.check(grid.walkable(TownLayout.TEMPLE.get_center()), "the temple's rubble can be walked over")
	t.check(not grid.walkable(Vector2(0, -8.7)), "the wall beside it still blocks")

	# The bridge is the only way south: when it falls the river closes.
	town.bridge.destroy(Vector2(0, 12.0), &"water")
	t.check(not grid.walkable(Vector2(0, 12.2)), "the fallen bridge does not carry anyone")
	t.check(grid.path(Vector2(0, 0), TownLayout.EXITS[0]).is_empty(), "the south route is closed")
	t.near(grid.nearest_exit(Vector2(0, 6.0)).x, TownLayout.EXITS[1].x, 0.001, "so the east exit becomes the nearest open one")
	t.check(grid.nearest_walkable(Vector2(-6.0, 12.2)) != Vector2.INF, "a point in the river snaps to the nearest bank")
	env.clear()
	env.free()
	town.free()
```

Register it: add `"res://tests/test_walk_grid.gd",` as the last entry of `SUITES` in `tests/run_all.gd`.

- [ ] **Step 2: Run the tests to see the new suite fail**

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_walk_grid.gd` and `checks=297 failures=1`.

- [ ] **Step 3: Create `src/game/town/walk_grid.gd`**

```gdscript
class_name WalkGrid
extends RefCounted
## Where the people of Aldermere may walk: an A* grid over the map at half-unit cells. A standing building
## blocks, its rubble does not, the river blocks except where the bridge still stands, and a fallen bridge
## closes the water under it. The grid is patched in place when a building falls, never rebuilt.

const CELL := 0.5
## People are about this wide, so a footprint is grown by it before being stamped solid.
const BODY := 0.15
## How far nearest_walkable() and path() will look for a free cell beside a blocked goal.
const SNAP_CELLS := 8

var grid := AStarGrid2D.new()

var _env: EnvironmentField
var _bridge: Structure


func setup(env: EnvironmentField, town: Town) -> WalkGrid:
	_env = env
	_bridge = town.bridge
	var m := TownLayout.MAP
	grid.region = Rect2i(Vector2i(floori(m.position.x / CELL), floori(m.position.y / CELL)),
		Vector2i(roundi(m.size.x / CELL), roundi(m.size.y / CELL)))
	grid.cell_size = Vector2(CELL, CELL)
	grid.offset = Vector2(CELL, CELL) * 0.5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.update()
	stamp(TownLayout.RIVER, true)
	for s in env.structures():
		_apply(s)
	env.structure_destroyed.connect(_on_destroyed)
	return self


func world_to_id(g: Vector2) -> Vector2i:
	return Vector2i(floori(g.x / CELL), floori(g.y / CELL))


func id_to_world(id: Vector2i) -> Vector2:
	return Vector2(id) * CELL + grid.offset


func walkable(g: Vector2) -> bool:
	var id := world_to_id(g)
	return grid.is_in_boundsv(id) and not grid.is_point_solid(id)


## `g` itself when it is free, otherwise the centre of the nearest free cell (searched in rings), or
## Vector2.INF when everything within max_cells is solid.
func nearest_walkable(g: Vector2, max_cells := SNAP_CELLS) -> Vector2:
	var id := world_to_id(g)
	if grid.is_in_boundsv(id) and not grid.is_point_solid(id):
		return g
	for r in range(1, max_cells + 1):
		var best := Vector2i.ZERO
		var found := false
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := id + Vector2i(dx, dy)
				if not grid.is_in_boundsv(c) or grid.is_point_solid(c):
					continue
				if not found or id_to_world(c).distance_squared_to(g) < id_to_world(best).distance_squared_to(g):
					best = c
					found = true
		if found:
			return id_to_world(best)
	return Vector2.INF


## Waypoints from `from` to `to` in ground units (empty when there is no route). A goal inside a building
## routes to the nearest free cell beside it, so "walk home" works even though home is solid.
func path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var start := nearest_walkable(from)
	var goal := nearest_walkable(to)
	if start == Vector2.INF or goal == Vector2.INF:
		return PackedVector2Array()
	return grid.get_point_path(world_to_id(start), world_to_id(goal))


## The closest exit there is still a route to, or Vector2.INF when the town is sealed.
func nearest_exit(from: Vector2) -> Vector2:
	var exits: Array[Vector2] = []
	for e: Vector2 in TownLayout.EXITS:
		exits.append(e)
	exits.sort_custom(func(a: Vector2, b: Vector2): return a.distance_squared_to(from) < b.distance_squared_to(from))
	for e in exits:
		if not path(from, e).is_empty():
			return e
	return Vector2.INF


## Mark every cell whose centre lies in `rect` solid or free.
func stamp(rect: Rect2, solid: bool) -> void:
	var c0 := world_to_id(rect.position)
	var c1 := world_to_id(rect.end)
	for y in range(c0.y, c1.y + 1):
		for x in range(c0.x, c1.x + 1):
			var id := Vector2i(x, y)
			if grid.is_in_boundsv(id) and rect.has_point(id_to_world(id)):
				grid.set_point_solid(id, solid)


func _apply(s: Structure) -> void:
	if not is_instance_valid(s):
		return
	if s.destroyed or s.walkable:
		return
	stamp(s.footprint.grow(BODY), true)


## A building fell: its ground opens up (rubble is walkable), except the bridge, whose fall closes the river.
func _on_destroyed(s: Structure) -> void:
	if s == _bridge:
		stamp(s.footprint, true)
		return
	stamp(s.footprint.grow(BODY), false)
	# Freeing a footprint can free cells a standing neighbour or the river needs, so put those back.
	var area := s.footprint.grow(BODY + CELL)
	if area.intersects(TownLayout.RIVER):
		var water := area.intersection(TownLayout.RIVER)
		stamp(water, true)
		if is_instance_valid(_bridge) and not _bridge.destroyed:
			stamp(_bridge.footprint.intersection(water), false)
	for other in _env.structures():
		if other != s and is_instance_valid(other) and not other.destroyed and not other.walkable \
				and other.footprint.grow(BODY).intersects(area):
			_apply(other)
```

- [ ] **Step 4: Run the tests**

Run: `bash tools/test.sh`
Expected: `checks=312 failures=0`.

- [ ] **Step 5: Commit**

```bash
git add src/game/town/walk_grid.gd src/game/town/walk_grid.gd.uid tests/test_walk_grid.gd tests/test_walk_grid.gd.uid tests/run_all.gd
git commit -m "feat: a walk grid that knows water from rubble" -m "WalkGrid is an A* grid over Aldermere at half-unit cells: standing buildings block and their rubble does not, the river blocks except where the bridge stands, and the bridge's fall closes the south route. It patches itself when a building falls instead of rebuilding." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---
### Task 3: Citizens and soldiers

**Files:**
- Create: `src/game/crowd/person.gd`
- Modify: `tests/run_all.gd`
- Test: `tests/test_person.gd`

**Interfaces:**
- Consumes: `DummyEnemy` (`tick`, `_pick_target`, `_move`, `_px`, `_anim`, `_facing`, `_idle`, `state`, `walk_speed` from Task 1, `is_frozen`, `is_alive`, `rng`, `ground_pos`, `bounds`), `WalkGrid.path/nearest_exit/nearest_walkable`, `TownLayout.MARKET_SQUARE`.
- Produces (`class_name Person extends DummyEnemy`):
  - `enum Mind { CALM, PANIC, FLEE, POST, RALLY, HOLD }`, `var mind`, `var soldier`, `var anchor`, `var grid`, `var wait`
  - `func setup_person(is_soldier: bool, at: Vector2, w: WalkGrid) -> Person`
  - `func set_goal(g: Vector2) -> void`, `func panic(from: Vector2) -> void`, `func flee() -> void`, `func send_to_post(at: Vector2, rally := false) -> void`, `func hold_ground() -> void`, `func has_escaped() -> bool`
  - Speeds: calm 0.6 (`DummyEnemy.WALK_SPEED`), panicked 0.9, fleeing 1.2. `wait` seconds make a person stand still (the gate queue sets it).
  - Drawing: overrides `_draw_body()`, so citizens and soldiers get their own pixel bodies and every death, freeze and lift animation keeps working. `DummyEnemy` itself is not touched by this task.

- [ ] **Step 1: Write the failing test**

Create `tests/test_person.gd`:

```gdscript
extends RefCounted
## A person walks the grid's paths, panics away from a blow, flees to an exit and escapes there; a soldier
## ignores all of that, marches to its rally ring and holds its ground.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)

	# A citizen walks to a goal across town.
	var goal := Vector2(0.0, 6.0)
	var c := Person.new()
	c.rng.seed = 11
	c.bounds = TownLayout.MAP
	c.setup_person(false, Vector2(0.0, 2.0), grid)
	c.set_goal(goal)
	var steps := 0
	while steps < 2400 and c.ground_pos.distance_to(goal) > 0.5:
		c.tick(1.0 / 60.0)
		steps += 1
	t.check(c.ground_pos.distance_to(goal) <= 0.5, "a citizen walks to its goal (%s after %d steps)" % [c.ground_pos, steps])

	# Panic runs away from the blow, then turns into flight.
	var start := c.ground_pos
	c.panic(start + Vector2(0.0, -1.0))
	c.tick(1.0 / 60.0)
	t.check(c.mind == Person.Mind.PANIC and c.walk_speed > DummyEnemy.WALK_SPEED, "panic runs faster than a stroll")
	for i in 200:
		c.tick(1.0 / 60.0)
	t.check(c.ground_pos.y >= start.y - 0.05, "it runs away from the blow, not into it")
	for i in 240:
		c.tick(1.0 / 60.0)
	t.check(c.mind == Person.Mind.FLEE, "panic turns into flight")
	var fled := 0
	while fled < 9000 and not c.has_escaped():
		c.tick(1.0 / 60.0)
		fled += 1
	t.check(c.has_escaped(), "it reaches an exit (%s after %d steps)" % [c.ground_pos, fled])
	t.near(c.walk_speed, 1.2, 0.001, "fleeing at the spec's 1.2 units per second")

	# Soldiers never flee; they march where they are posted and then hold.
	var s := Person.new()
	s.rng.seed = 12
	s.bounds = TownLayout.MAP
	s.setup_person(true, TownLayout.BARRACKS_YARD.get_center(), grid)
	t.check(s.mind == Person.Mind.POST, "a soldier starts at its post")
	s.panic(s.ground_pos + Vector2(1.0, 0.0))
	s.flee()
	t.check(s.mind == Person.Mind.POST, "and ignores panic and flight")
	var ring := TownLayout.CITADEL_ORIGIN + Vector2(0.0, 3.6)
	s.send_to_post(ring, true)
	t.check(s.mind == Person.Mind.RALLY, "the rally moves it")
	var marched := 0
	while marched < 6000 and s.ground_pos.distance_to(ring) > 0.6:
		s.tick(1.0 / 60.0)
		marched += 1
	t.check(s.ground_pos.distance_to(ring) <= 0.6, "it reaches the rally ring (%s after %d steps)" % [s.ground_pos, marched])
	s.hold_ground()
	var held := s.ground_pos
	for i in 120:
		s.tick(1.0 / 60.0)
	t.check(s.ground_pos.distance_to(held) < 0.3, "and holds its ground")

	# A frozen person cannot walk, and a queued one stands still until the gate lets it through.
	c.freeze(1.0)
	var frozen_at := c.ground_pos
	for i in 30:
		c.tick(1.0 / 60.0)
	t.check(c.ground_pos == frozen_at, "a frozen person cannot walk")

	var w := Person.new()
	w.rng.seed = 13
	w.bounds = TownLayout.MAP
	w.setup_person(false, Vector2(0.0, 7.0), grid)
	w.set_goal(Vector2(0.0, 10.0))
	w.wait = 0.5
	var waited := w.ground_pos
	for i in 20:
		w.tick(1.0 / 60.0)
	t.check(w.ground_pos.distance_to(waited) < 0.05, "a queued person stands still")
	for i in 90:
		w.tick(1.0 / 60.0)
	t.check(w.ground_pos.distance_to(waited) > 0.05, "and walks on when the gate lets it through")

	# Everything the effects do to a unit still applies.
	t.check(w.is_alive() and w is DummyEnemy, "people are ordinary units")
	w.die(&"nova", w.ground_pos + Vector2(1, 0))
	t.check(not w.is_alive(), "and they die like units")
	env.clear()
	env.free()
	town.free()
	c.free()
	s.free()
	w.free()
```

Register it: add `"res://tests/test_person.gd",` as the last entry of `SUITES` in `tests/run_all.gd`.

- [ ] **Step 2: Run the tests to see the new suite fail**

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_person.gd` and `checks=313 failures=1`.

- [ ] **Step 3: Create `src/game/crowd/person.gd`**

```gdscript
class_name Person
extends DummyEnemy
## A citizen or a soldier of Aldermere: the same unit every effect already kills, knocks, pulls, freezes and
## lifts, with a brain that walks the town's paths. Citizens go calm -> panicked -> fleeing -> escaped, queueing
## at the gates on the way out. Soldiers hold a post, march to the Citadel when the rally sounds, and never flee.

enum Mind { CALM, PANIC, FLEE, POST, RALLY, HOLD }

const PANIC_SPEED := 0.9
const FLEE_SPEED := 1.2
## How long a fright lasts before it turns into flight.
const PANIC_SECONDS := 1.6
## Close enough to count as arrived.
const GOAL_REACH := 0.45
## Seconds before a person gives a stuck goal another try.
const REPATH := 2.5
## Chance per frame that a calm citizen strolls to the market or back home.
const STROLL_CHANCE := 0.004
## How far a calm citizen drifts from home, and a posted soldier from its spot.
const CALM_SPREAD := 1.4
const POST_SPREAD := 0.35

const CIT_SKIN := [Color("c89a72"), Color("b07a52"), Color("8a5a3a")]
const CIT_TUNIC := [Color("8a5a3a"), Color("6a6a4a"), Color("7a4a4a"), Color("4a5a6a"), Color("8a7a4a"), Color("6a5a7a")]
const CIT_HAIR := [Color("3a2a1a"), Color("5a4a2a"), Color("24201c"), Color("7a5a3a")]
const CIT_LEGS := Color("453c33")
const SOL_MAIL := Color("6a6f78")
const SOL_MAIL_HI := Color("8d939c")
const SOL_HELM := Color("484d56")
const SOL_TABARD := Color("1f3f8a")
const SOL_SHIELD := Color("2f5cc0")
const SOL_GOLD := Color("d8b23a")
const SOL_HAFT := Color("5a4a3a")
const SOL_TIP := Color("b8bcc4")

var mind := Mind.CALM
var soldier := false
## Home for a citizen, posted spot for a soldier: where it drifts around when it has nowhere to be.
var anchor := Vector2.ZERO
var grid: WalkGrid
## Seconds this person must stand still (a gate queue sets it every frame it holds someone back).
var wait := 0.0

var _path := PackedVector2Array()
var _leg := 0
var _goal := Vector2.INF
var _panic_left := 0.0
var _repath_in := 0.0
var _skin := Color.WHITE
var _tunic := Color.WHITE
var _hair := Color.WHITE


## `at` is where it stands and what it treats as home (or its post). Seed `rng` before calling this.
func setup_person(is_soldier: bool, at: Vector2, w: WalkGrid) -> Person:
	soldier = is_soldier
	grid = w
	anchor = at
	ground_pos = at
	mind = Mind.POST if is_soldier else Mind.CALM
	_skin = CIT_SKIN[rng.randi() % CIT_SKIN.size()]
	_tunic = CIT_TUNIC[rng.randi() % CIT_TUNIC.size()]
	_hair = CIT_HAIR[rng.randi() % CIT_HAIR.size()]
	_pick_target()
	return self


# --- Brain -------------------------------------------------------------------

func tick(delta: float) -> void:
	if state == State.WANDER and not is_frozen():
		_think(delta)
	super(delta)


func _think(delta: float) -> void:
	if wait > 0.0:
		# Held in a gate queue: stand still, but keep the fright timer running.
		wait = maxf(wait - delta, 0.0)
		_panic_left = maxf(_panic_left - delta, 0.0)
		_idle = maxf(_idle, 0.05)
		return
	_repath_in = maxf(_repath_in - delta, 0.0)
	walk_speed = _mind_speed()
	if mind == Mind.PANIC:
		_panic_left -= delta
		if _panic_left <= 0.0:
			flee()
	match mind:
		Mind.FLEE:
			if _goal == Vector2.INF:
				if _repath_in <= 0.0:
					_plan_exit()
				else:
					_idle = maxf(_idle, 0.05)
			elif _path.is_empty() and _repath_in <= 0.0 and ground_pos.distance_to(_goal) > GOAL_REACH:
				# The way changed under us (a bridge fell): plan again.
				_goal = Vector2.INF
				_repath_in = 0.3
		Mind.POST, Mind.RALLY:
			if _goal == Vector2.INF and _repath_in <= 0.0 and ground_pos.distance_to(anchor) > GOAL_REACH * 2.0:
				set_goal(anchor)
		Mind.CALM:
			if _goal == Vector2.INF and rng.randf() < STROLL_CHANCE:
				set_goal(TownLayout.MARKET_SQUARE.get_center() if rng.randf() < 0.5 else anchor)
		Mind.HOLD:
			_idle = maxf(_idle, 0.2)


func _mind_speed() -> float:
	match mind:
		Mind.PANIC, Mind.RALLY:
			return PANIC_SPEED
		Mind.FLEE:
			return FLEE_SPEED
		_:
			return WALK_SPEED


## Walk to `g` along the grid's path. A goal inside a building routes to its doorstep.
func set_goal(g: Vector2) -> void:
	_goal = g
	_leg = 0
	_path = grid.path(ground_pos, g) if grid != null else PackedVector2Array()
	_repath_in = REPATH
	_idle = 0.0
	_pick_target()


## Next waypoint, or a drift around the anchor when there is nothing to walk to. DummyEnemy calls this
## whenever it reaches its current target.
func _pick_target() -> void:
	while _leg < _path.size():
		var p := _path[_leg]
		_leg += 1
		if ground_pos.distance_to(p) > 0.08:
			_target = p
			return
	_path = PackedVector2Array()
	_leg = 0
	if _goal != Vector2.INF and ground_pos.distance_to(_goal) > GOAL_REACH:
		# Out of waypoints but not there: hold position until the next plan.
		_target = ground_pos
		_repath_in = minf(_repath_in, 0.3)
		return
	_goal = Vector2.INF
	_drift()


## A small aimless step: citizens milling about their street, soldiers shifting at their post.
func _drift() -> void:
	var spread := CALM_SPREAD if mind == Mind.CALM else POST_SPREAD
	var to := anchor + Vector2(rng.randf_range(-spread, spread), rng.randf_range(-spread, spread))
	if grid != null:
		var free := grid.nearest_walkable(to, 3)
		to = free if free != Vector2.INF else ground_pos
	_target = to


# --- What the town does to a person ------------------------------------------

## A power landed, or a building fell, at `from`: bolt away from it, then flee for good. Soldiers do not.
func panic(from: Vector2) -> void:
	if soldier or mind == Mind.FLEE or state == State.DEAD:
		return
	mind = Mind.PANIC
	_panic_left = PANIC_SECONDS
	var away := ground_pos - from
	var to := ground_pos + (away.normalized() if away.length() > 0.01 else Vector2.RIGHT) * 3.0
	if grid != null:
		var free := grid.nearest_walkable(to, 6)
		to = free if free != Vector2.INF else ground_pos
	set_goal(to)


## Head for the nearest exit there is still a route to. The plan itself is staggered, so a town-wide panic
## does not ask for a hundred paths in the same frame.
func flee() -> void:
	if soldier or mind == Mind.FLEE or state == State.DEAD:
		return
	mind = Mind.FLEE
	_panic_left = 0.0
	_goal = Vector2.INF
	_path = PackedVector2Array()
	_leg = 0
	_repath_in = rng.randf_range(0.05, 1.2)


func _plan_exit() -> void:
	var exit := grid.nearest_exit(ground_pos) if grid != null else Vector2.INF
	if exit == Vector2.INF:
		# Sealed in: mill about and try again shortly.
		_repath_in = 1.5
		_drift()
		return
	set_goal(exit)


## Soldiers only: stand at `at` (its starting post, or a slot on the Citadel's rally ring).
func send_to_post(at: Vector2, rally := false) -> void:
	if state == State.DEAD:
		return
	anchor = at
	mind = Mind.RALLY if rally else Mind.POST
	set_goal(at)


## Stop caring: soldiers hold the Citadel's rubble once it has fallen.
func hold_ground() -> void:
	if state == State.DEAD:
		return
	mind = Mind.HOLD
	_goal = Vector2.INF
	_path = PackedVector2Array()
	_leg = 0
	_target = ground_pos


## True once a fleeing citizen has reached the exit it was walking to; the Crowd then removes it.
func has_escaped() -> bool:
	return mind == Mind.FLEE and _goal != Vector2.INF and ground_pos.distance_to(_goal) <= GOAL_REACH


# --- Drawing -----------------------------------------------------------------

func _draw_body(lift: int, top_only: int) -> void:
	if soldier:
		_draw_soldier(lift, top_only)
	else:
		_draw_citizen(lift, top_only)


## Townsfolk: bare head, tunic, no armour. Smaller than the soldiers so a crowd reads at a glance.
func _draw_citizen(lift: int, top_only: int) -> void:
	var step := int(_anim * 6.0) % 2 if state != State.DEAD and not is_frozen() else 0
	var f := _facing
	if top_only == 0:
		_px(-2, -4 + lift, 2, 4 - step, CIT_LEGS)
		_px(1, -4 + lift, 2, 3 + step, CIT_LEGS)
	_px(-3, -10 + lift, 6, 6, _tunic)
	_px(-3, -10 + lift, 6, 1, _tunic.lightened(0.18))
	_px(-4, -9 + lift, 1, 3, _skin)
	_px(3, -9 + lift, 1, 3, _skin)
	_px(-2, -13 + lift, 4, 3, _skin)
	_px(-2, -13 + lift, 4, 1, _hair)
	if state != State.DEAD or _char < 0.5:
		_px(0 if f > 0 else -1, -12 + lift, 1, 1, COL_DARK)


## Town guard: mail, royal blue tabard, helmet, spear and shield.
func _draw_soldier(lift: int, top_only: int) -> void:
	var step := int(_anim * 5.0) % 2 if state != State.DEAD and not is_frozen() else 0
	var f := _facing
	if top_only == 0:
		_px(-3, -5 + lift, 2, 5 - step, SOL_HELM)
		_px(1, -5 + lift, 2, 4 + step, SOL_HELM)
	_px(-4, -11 + lift, 8, 6, SOL_MAIL)
	_px(-4, -11 + lift, 8, 1, SOL_MAIL_HI)
	_px(-2, -9 + lift, 4, 4, SOL_TABARD)
	_px(-5, -10 + lift, 1, 3, _skin)
	_px(4, -10 + lift, 1, 3, _skin)
	_px(-3, -15 + lift, 6, 4, SOL_HELM)
	_px(-3, -15 + lift, 6, 1, SOL_MAIL_HI)
	if state != State.DEAD or _char < 0.5:
		_px(-1 if f > 0 else -2, -13 + lift, 3, 1, COL_DARK)
	# Spear in the leading hand, shield on the other arm.
	_px(5 * f, -17 + lift, 1, 12, SOL_HAFT)
	_px(5 * f, -18 + lift, 1, 2, SOL_TIP)
	_px(-5 * f, -10 + lift, 2 * f, 5, SOL_SHIELD)
	_px(-4 * f, -8 + lift, 1, 1, SOL_GOLD)
```

- [ ] **Step 4: Run the tests**

Run: `bash tools/test.sh`
Expected: `checks=328 failures=0`.

If a walking test times out, print the person's `mind`, `_goal`, `_path.size()` and `ground_pos` in a scratch run to see where it stalls — do not raise the step limits to make it pass.

- [ ] **Step 5: Look at them**

The debug scene does not spawn people until Task 5, so preview them on their own. Create `tools/dev/preview_people.gd`:

```gdscript
extends SceneTree
## Dev preview: citizens and soldiers, walking and standing, at 1x and 4x.
## Usage (writes captures/people_preview.png): godot --path . --audio-driver Dummy -s tools/dev/preview_people.gd


func _init() -> void:
	RenderingServer.set_default_clear_color(Color("6a8e3a"))
	var root2 := Node2D.new()
	get_root().add_child(root2)
	var cam := Camera2D.new()
	cam.position = Vector2(0, -10)
	root2.add_child(cam)
	cam.make_current()
	var rows := [[false, 1.0, -70.0], [true, 1.0, -30.0], [false, 4.0, 20.0], [true, 4.0, 90.0]]
	for row in rows:
		var holder := Node2D.new()
		holder.scale = Vector2.ONE * float(row[1])
		holder.position = Vector2(0, float(row[2]))
		root2.add_child(holder)
		for i in 6:
			var p := Person.new()
			p.rng.seed = 40 + i
			p.bounds = Rect2(-50, -50, 100, 100)
			p.setup_person(row[0], Vector2.ZERO, null)
			p.position = Vector2(-120.0 + i * 48.0, 0)
			p._facing = 1 if i % 2 == 0 else -1
			p._anim = 0.0 if i < 3 else 0.09
			holder.add_child(p)
	for f in 20:
		await process_frame
	var dir := ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(dir)
	get_root().get_texture().get_image().save_png(dir.path_join("people_preview.png"))
	print("captured people_preview.png")
	quit()
```

Run it, then open the PNG with the Read tool:

```bash
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --audio-driver Dummy -s tools/dev/preview_people.gd
```

Check: citizens read as townsfolk (bare head, coloured tunics, visibly varied), soldiers as guards (helmet, blue tabard, spear, shield), both facings look right, the walk pose differs from the standing pose, and neither is taller than the sandbox's trooper at the same scale. Fix the pixel work in `person.gd` until it reads, and say in your report what you changed.

- [ ] **Step 6: Commit**

```bash
git add src/game/crowd/person.gd src/game/crowd/person.gd.uid tests/test_person.gd tests/test_person.gd.uid tests/run_all.gd tools/dev/preview_people.gd tools/dev/preview_people.gd.uid
git commit -m "feat: citizens and soldiers with brains" -m "Person is the existing unit with a path-walking brain and its own pixel body: citizens wander, panic away from a blow, flee to the nearest open exit and wait their turn at a gate; soldiers hold a post, march to the Citadel on the rally and hold their ground. Every effect's kill, knock, pull, freeze and lift still applies." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 4: The crowd

**Files:**
- Create: `src/game/crowd/crowd.gd`
- Modify: `tests/run_all.gd`
- Test: `tests/test_crowd.gd`

**Interfaces:**
- Consumes: `Person` (Task 3), `WalkGrid` (Task 2), `EnemyField.add/alive/bounds/enemy_killed`, `EnvironmentField.structure_destroyed`, `Town.gates/citadel`, `Citadel.health_changed/fallen`, `TownLayout`.
- Produces (`class_name Crowd extends Node`):
  - `signal escaped(person: Person)`, `signal alarm_changed(value: float)`, `signal rallied`
  - `var citizens: Array[Person]`, `var soldiers: Array[Person]`, `var alarm: float`, `var escaped_count: int`, `var killed_citizens: int`, `var killed_soldiers: int`
  - `func setup(field: EnemyField, env: EnvironmentField, town: Town, grid: WalkGrid, parent: Node2D, seed_value: int) -> Crowd`
  - `func spawn(citizen_count := CITIZENS, soldier_count := SOLDIERS) -> void`
  - `func on_cast(ground: Vector2) -> void` — the player cast a power there
  - `func add_alarm(points: float) -> void`, `func rally() -> void`, `func clear() -> void`
  - `func advance(delta: float) -> void` — gate queues, escapes and the crowd clock; `_process` calls it, tests call it directly
  - `func alive_citizens() -> int`, `func alive_soldiers() -> int`
- Numbers, all from the spec's table in this plan's header: 110 citizens, 50 soldiers (20 yard / 12 walls and gates / 10 Citadel / 8 patrols), panic within 7 of a cast and 4 of a collapse, alarm +2 / +0.5 / +10 with the rally at 25 and a town-wide flight at 50, one person through a gate every 0.6 s.

- [ ] **Step 1: Write the failing test**

Create `tests/test_crowd.gd`:

```gdscript
extends RefCounted
## The crowd: who spawns where, what frightens them, the alarm's thresholds, the gate queue, escapes, the
## soldiers' rally, and what happens once the Citadel falls.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()

	t.check(crowd.citizens.size() == 110 and crowd.soldiers.size() == 50, "110 citizens and 50 soldiers (%d / %d)" % [crowd.citizens.size(), crowd.soldiers.size()])
	var off_grid := 0
	for p in crowd.citizens + crowd.soldiers:
		if not grid.walkable(p.ground_pos):
			off_grid += 1
	t.check(off_grid == 0, "everyone stands on walkable ground (%d do not)" % off_grid)
	var in_yard := 0
	var at_citadel := 0
	for p in crowd.soldiers:
		if TownLayout.BARRACKS_YARD.grow(0.6).has_point(p.anchor):
			in_yard += 1
		elif p.anchor.distance_to(TownLayout.CITADEL_ORIGIN) <= Crowd.RING_RADIUS + 1.2:
			at_citadel += 1
	t.check(in_yard == 20, "20 soldiers drill in the yard (%d)" % in_yard)
	t.check(at_citadel >= 10, "at least 10 guard the Citadel (%d)" % at_citadel)
	var soldiers_calm := true
	for p in crowd.soldiers:
		soldiers_calm = soldiers_calm and p.mind == Person.Mind.POST
	t.check(soldiers_calm, "soldiers start at their posts")

	# A cast frightens the people near it and nobody else.
	var near := crowd.citizens[0]
	near.ground_pos = Vector2(0.0, 0.0)
	var far := crowd.citizens[1]
	far.ground_pos = Vector2(0.0, 8.0)
	crowd.on_cast(Vector2(0.0, 0.0))
	t.check(near.mind == Person.Mind.PANIC, "a cast nearby starts a panic")
	t.check(far.mind == Person.Mind.CALM, "one 8 units away is not frightened")

	# A building falling frightens the people beside it and raises the alarm.
	var alarm_before := crowd.alarm
	var market: Structure = null
	for s in env.structures():
		if s.role == &"market":
			market = s
			break
	var beside := crowd.citizens[2]
	beside.ground_pos = market.center() + Vector2(1.0, 0.0)
	market.destroy(market.center() + Vector2(2.0, 0.0), &"stone")
	t.near(crowd.alarm - alarm_before, Crowd.ALARM_BUILDING, 0.001, "a destroyed building is worth 2 alarm")
	t.check(beside.mind == Person.Mind.PANIC, "and frightens the people beside it")

	# The Citadel's parts do not each count as a building, but the first hit on it is worth 10 and rallies.
	alarm_before = crowd.alarm
	town.citadel.parts[0].destroy(TownLayout.CITADEL_ORIGIN, &"stone")
	t.near(crowd.alarm, alarm_before, 0.001, "a Citadel part is not counted as a building")
	town.citadel.keep.damage(20.0, TownLayout.CITADEL_ORIGIN, &"stone")
	t.check(crowd.alarm >= alarm_before + Crowd.ALARM_CITADEL_HIT, "the first hit on the Citadel is worth 10")
	var rallying := 0
	for p in crowd.soldiers:
		if p.mind == Person.Mind.RALLY:
			rallying += 1
	t.check(rallying == crowd.soldiers.size(), "every soldier rallies to the Citadel (%d)" % rallying)

	# Kills raise the alarm and are counted by kind.
	alarm_before = crowd.alarm
	field.kill(crowd.citizens[3], &"nova")
	field.kill(crowd.soldiers[0], &"nova")
	t.near(crowd.alarm - alarm_before, Crowd.ALARM_KILL * 2.0, 0.001, "each death is worth half a point")
	t.check(crowd.killed_citizens == 1 and crowd.killed_soldiers == 1, "deaths are counted per kind")

	# At 50 alarm every citizen runs.
	crowd.add_alarm(50.0)
	var still_calm := 0
	for p in crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and p.mind != Person.Mind.FLEE:
			still_calm += 1
	t.check(still_calm == 0, "at 50%% alarm nobody stays (%d did)" % still_calm)

	# A gate passes one person every 0.6 s and holds the rest.
	var gate: Structure = town.gates[0]
	var queue: Array[Person] = []
	for i in 4:
		var p: Person = crowd.citizens[10 + i]
		p.ground_pos = gate.center() + Vector2(0.1 * i, -0.4)
		p.wait = 0.0
		queue.append(p)
	crowd.advance(0.0)
	var passing := 0
	for p in queue:
		if p.wait <= 0.0:
			passing += 1
	t.check(passing == 1, "one person is let through at a time (%d were)" % passing)
	crowd.advance(0.3)
	passing = 0
	for p in queue:
		if p.wait <= 0.0:
			passing += 1
	t.check(passing == 0, "the next one still waits after 0.3 s")
	crowd.advance(0.4)
	passing = 0
	for p in queue:
		if p.wait <= 0.0:
			passing += 1
	t.check(passing == 1, "and goes through after 0.6 s (%d)" % passing)

	# Reaching an exit escapes.
	var runner: Person = crowd.citizens[20]
	var before_count := crowd.citizens.size()
	runner.ground_pos = TownLayout.EXITS[1]
	runner.set_goal(TownLayout.EXITS[1])
	var reported: Array = []
	crowd.escaped.connect(func(p: Person): reported.append(p))
	crowd.advance(0.1)
	t.check(crowd.escaped_count == 1 and reported.size() == 1, "reaching an exit counts as an escape")
	t.check(crowd.citizens.size() == before_count - 1, "and takes them off the streets")

	# Once the Citadel falls the soldiers hold its rubble.
	for i in 12:
		town.citadel.advance(1.01)
		env.damage_radius(TownLayout.CITADEL_ORIGIN, 4.0, 99999.0, &"nova")
	t.check(town.citadel.is_fallen(), "the Citadel fell")
	var holding := true
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.is_alive():
			holding = holding and p.mind == Person.Mind.HOLD
	t.check(holding, "the surviving soldiers hold their ground")

	crowd.clear()
	t.check(crowd.citizens.is_empty() and crowd.soldiers.is_empty(), "clear() empties the town")
	field.clear()
	field.free()
	env.clear()
	env.free()
	town.free()
	crowd.free()
	world.free()
```

Register it: add `"res://tests/test_crowd.gd",` as the last entry of `SUITES` in `tests/run_all.gd`.

- [ ] **Step 2: Run the tests to see the new suite fail**

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_crowd.gd` and `checks=329 failures=1`.

- [ ] **Step 3: Create `src/game/crowd/crowd.gd`**

```gdscript
class_name Crowd
extends Node
## The people of Aldermere: 110 citizens who wander their street, panic, flee to the exits and queue at the
## gates, and 50 soldiers who hold their posts until the alarm or the first blow on the Citadel sends them to
## ring it. Everyone is an ordinary unit in EnemyField, so every effect kills, knocks, pulls, freezes and lifts
## them as it does the sandbox's troopers. Numbers are the spec's starting values (§3).

signal escaped(person: Person)
signal alarm_changed(value: float)
signal rallied

const CITIZENS := 110
const SOLDIERS := 50
## Soldier posts: drilling in the yard, on the walls and gates, guarding the Citadel, patrolling in pairs.
const POST_YARD := 20
const POST_WALLS := 12
const POST_CITADEL := 10
const POST_PATROL := 8
const ALARM_BUILDING := 2.0
const ALARM_KILL := 0.5
const ALARM_CITADEL_HIT := 10.0
const ALARM_RALLY := 25.0
const ALARM_FLEE_ALL := 50.0
## A cast this close frightens a citizen; a collapse this close does too.
const PANIC_CAST := 7.0
const PANIC_DESTROY := 4.0
## One person through a gate this often, and how close counts as queueing for it.
const GATE_INTERVAL := 0.6
const GATE_QUEUE := 1.6
## Where the soldiers ring the Citadel.
const RING_RADIUS := 3.4

var citizens: Array[Person] = []
var soldiers: Array[Person] = []
var alarm := 0.0
var escaped_count := 0
var killed_citizens := 0
var killed_soldiers := 0

var _field: EnemyField
var _env: EnvironmentField
var _town: Town
var _grid: WalkGrid
var _parent: Node2D
var _rng := RandomNumberGenerator.new()
## Gate -> the crowd clock time it may pass someone again.
var _gate_next := {}
var _clock := 0.0
var _rallied := false
var _citadel_hit := false


func setup(field: EnemyField, env: EnvironmentField, town: Town, grid: WalkGrid, parent: Node2D,
		seed_value: int) -> Crowd:
	_field = field
	_env = env
	_town = town
	_grid = grid
	_parent = parent
	_rng.seed = seed_value
	env.structure_destroyed.connect(_on_structure_destroyed)
	field.enemy_killed.connect(_on_killed)
	if town.citadel != null:
		town.citadel.health_changed.connect(_on_citadel_health)
		town.citadel.fallen.connect(_on_citadel_fallen)
	return self


func spawn(citizen_count := CITIZENS, soldier_count := SOLDIERS) -> void:
	var homes: Array[Structure] = []
	for s in _env.structures():
		if s.role == &"house":
			homes.append(s)
	for i in citizen_count:
		var home: Structure = homes[i % maxi(homes.size(), 1)] if not homes.is_empty() else null
		var at := _spot_near(home.center() if home != null else Vector2.ZERO, 1.6)
		var p := _add_person(false, at)
		p.anchor = at
		citizens.append(p)
	for spot in _soldier_posts(soldier_count):
		soldiers.append(_add_person(true, spot))


## Walkable ground within `spread` of `about`, or the nearest walkable point to it.
func _spot_near(about: Vector2, spread: float) -> Vector2:
	for attempt in 8:
		var candidate := about + Vector2(_rng.randf_range(-spread, spread), _rng.randf_range(-spread, spread))
		if _grid.walkable(candidate):
			return candidate
	var free := _grid.nearest_walkable(about)
	return free if free != Vector2.INF else about


func _add_person(is_soldier: bool, at: Vector2) -> Person:
	var p := Person.new()
	p.rng.seed = _rng.randi()
	_field.add(p)
	p.setup_person(is_soldier, at, _grid)
	_parent.add_child(p)
	return p


## The spec's posting: the yard, the wall towers and gates, the Citadel, and street patrols in pairs.
func _soldier_posts(count: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in POST_YARD:
		out.append(_spot_near(TownLayout.BARRACKS_YARD.get_center(), 1.4))
	var guard_spots: Array[Vector2] = []
	for s in _env.structures():
		if s.role == &"tower" or s.role == &"gate":
			guard_spots.append(s.center())
	for i in POST_WALLS:
		var about: Vector2 = guard_spots[i % maxi(guard_spots.size(), 1)] if not guard_spots.is_empty() else Vector2.ZERO
		out.append(_spot_near(about, 1.2))
	for i in POST_CITADEL:
		var a := TAU * float(i) / float(POST_CITADEL)
		out.append(_spot_near(TownLayout.CITADEL_ORIGIN + Vector2(cos(a), sin(a)) * RING_RADIUS, 0.8))
	for i in POST_PATROL:
		# Pairs walk the two streets; their post is a point on the road.
		var along := -6.0 + 4.0 * float(i / 2)
		var road_point := Vector2(0.0, along) if i % 4 < 2 else Vector2(along, 0.0)
		out.append(_spot_near(road_point, 0.8))
	while out.size() > count:
		out.pop_back()
	while out.size() < count:
		out.append(_spot_near(TownLayout.BARRACKS_YARD.get_center(), 1.4))
	return out


func alive_citizens() -> int:
	return _alive(citizens)


func alive_soldiers() -> int:
	return _alive(soldiers)


func _alive(list: Array[Person]) -> int:
	var n := 0
	for p in list:
		if is_instance_valid(p) and p.is_alive():
			n += 1
	return n


func _process(delta: float) -> void:
	advance(delta)


## Gate queues, escapes and the crowd clock. Runs from _process; tests call it directly.
func advance(delta: float) -> void:
	_clock += delta
	_gates()
	_escapes()


func _gates() -> void:
	for gate in _town.gates:
		if not is_instance_valid(gate) or gate.destroyed:
			continue  # rubble is no bottleneck
		var centre := gate.center()
		var queue: Array[Person] = []
		for p in citizens:
			if is_instance_valid(p) and p.is_alive() and p.mind == Person.Mind.FLEE \
					and p.ground_pos.distance_to(centre) <= GATE_QUEUE:
				queue.append(p)
		if queue.is_empty():
			continue
		queue.sort_custom(func(a: Person, b: Person) -> bool:
			return a.ground_pos.distance_squared_to(centre) < b.ground_pos.distance_squared_to(centre))
		var open: bool = _clock >= float(_gate_next.get(gate, -1.0))
		for i in queue.size():
			if i == 0 and open:
				_gate_next[gate] = _clock + GATE_INTERVAL
				queue[0].wait = 0.0
			else:
				queue[i].wait = maxf(queue[i].wait, 0.25)


func _escapes() -> void:
	for p in citizens.duplicate():
		if not is_instance_valid(p):
			citizens.erase(p)
		elif p.is_alive() and p.has_escaped():
			citizens.erase(p)
			escaped_count += 1
			escaped.emit(p)
			p.queue_free()


## The player cast a power here: everyone close enough panics.
func on_cast(ground: Vector2) -> void:
	for p in citizens:
		if is_instance_valid(p) and p.is_alive() and p.ground_pos.distance_to(ground) <= PANIC_CAST:
			p.panic(ground)


func add_alarm(points: float) -> void:
	var before := alarm
	alarm = clampf(alarm + points, 0.0, 100.0)
	if alarm != before:
		alarm_changed.emit(alarm)
	if alarm >= ALARM_RALLY:
		rally()
	if alarm >= ALARM_FLEE_ALL:
		for p in citizens:
			if is_instance_valid(p) and p.is_alive():
				p.flee()


## Every soldier leaves its post for a slot on the Citadel's ring.
func rally() -> void:
	if _rallied:
		return
	_rallied = true
	for i in soldiers.size():
		var p := soldiers[i]
		if not is_instance_valid(p) or not p.is_alive():
			continue
		var a := TAU * float(i) / float(maxi(soldiers.size(), 1))
		p.send_to_post(_spot_near(TownLayout.CITADEL_ORIGIN + Vector2(cos(a), sin(a)) * RING_RADIUS, 0.6), true)
	rallied.emit()


func clear() -> void:
	for p in citizens + soldiers:
		if is_instance_valid(p):
			if p.is_inside_tree():
				p.queue_free()
			else:
				p.free()
	citizens.clear()
	soldiers.clear()
	_gate_next.clear()
	alarm = 0.0
	escaped_count = 0
	killed_citizens = 0
	killed_soldiers = 0
	_rallied = false
	_citadel_hit = false
	_clock = 0.0


func _on_structure_destroyed(s: Structure) -> void:
	if s.role != &"citadel":
		add_alarm(ALARM_BUILDING)
	var at := s.center()
	for p in citizens:
		if is_instance_valid(p) and p.is_alive() and p.ground_pos.distance_to(at) <= PANIC_DESTROY:
			p.panic(at)


func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	var p := e as Person
	if p == null:
		return
	if p.soldier:
		killed_soldiers += 1
	else:
		killed_citizens += 1
	add_alarm(ALARM_KILL)


## The Citadel reports every hit that takes health; the first one is the alarm bell.
func _on_citadel_health(_fraction: float) -> void:
	if _citadel_hit:
		return
	_citadel_hit = true
	add_alarm(ALARM_CITADEL_HIT)
	rally()


func _on_citadel_fallen() -> void:
	for p in soldiers:
		if is_instance_valid(p) and p.is_alive():
			p.hold_ground()
```

- [ ] **Step 4: Run the tests**

Run: `bash tools/test.sh`
Expected: `checks=351 failures=0`.

- [ ] **Step 5: Commit**

```bash
git add src/game/crowd/crowd.gd src/game/crowd/crowd.gd.uid tests/test_crowd.gd tests/test_crowd.gd.uid tests/run_all.gd
git commit -m "feat: the crowd of Aldermere" -m "Crowd spawns 110 citizens by their houses and 50 soldiers on the spec's posts, frightens people near a cast or a collapse, keeps the alarm (buildings, deaths, the first blow on the Citadel), rallies every soldier at 25% or that first blow, passes one person per gate every 0.6 s, counts escapes, and makes the soldiers hold the Citadel's rubble once it falls." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---
### Task 5: The town alive

**Files:**
- Modify: `src/game/town_debug.gd`, `README.md`

**Interfaces:**
- Consumes: `WalkGrid`, `Person`, `Crowd` (Tasks 2–4), the existing `Battlefield`/`Town`/`PowerBook` wiring in the debug scene.
- Produces: the debug scene builds a `WalkGrid` and a `Crowd` instead of 40 placeholder orcs; every cast tells the crowd; the HUD reports the people; `--people=N` scales the crowd for benching; `--crowd-test` is a scripted run that logs the crowd each second; the town captures include the crowd.

- [ ] **Step 1: Wire the crowd into the debug scene**

In `src/game/town_debug.gd`:

1a. Replace the units constants at the top:

```gdscript
const UNIT_COUNT := 40
## Placeholder units stay inside the town walls until the people milestone gives them real brains.
const UNIT_BOUNDS := Rect2(-8.3, -8.3, 16.6, 16.6)
```

with:

```gdscript
## The spec's crowd: 110 citizens and 50 soldiers. --people=N scales both for benching.
const PEOPLE := Crowd.CITIZENS + Crowd.SOLDIERS
```

1b. Add the two new members next to `var _town: Town`:

```gdscript
var _grid: WalkGrid
var _crowd: Crowd
```

1c. In `_ready()`, delete the two lines that set up the placeholder units:

```gdscript
	_bf.ctx.field.look = DummyEnemy.Look.ORC
	_bf.ctx.field.bounds = UNIT_BOUNDS
```

and put in their place:

```gdscript
	_bf.ctx.field.bounds = TownLayout.MAP
```

1d. Replace the tail of `_rebuild()` — everything from `_town.build(...)` to the end of the function — with:

```gdscript
	_town.build(_bf.ctx.env, _bf.ground_plane, _bf.camera)
	_grid = WalkGrid.new().setup(_bf.ctx.env, _town)
	_crowd = Crowd.new()
	_crowd.name = "Crowd"
	add_child(_crowd)
	_crowd.setup(_bf.ctx.field, _bf.ctx.env, _town, _grid, _bf.ctx.world, seed_value)
	var wanted := Battlefield.arg_value(OS.get_cmdline_user_args(), "--people")
	var people := int(wanted) if wanted != "" else PEOPLE
	var citizens := roundi(float(people) * float(Crowd.CITIZENS) / float(PEOPLE))
	_crowd.spawn(citizens, people - citizens)
```

and at the top of `_rebuild()`, where the old town is released, release the old crowd too — after the `if is_instance_valid(_town):` block add:

```gdscript
	if is_instance_valid(_crowd):
		_crowd.clear()
		if _crowd.is_inside_tree():
			_crowd.queue_free()
		else:
			_crowd.free()
```

1e. Tell the crowd about every cast: in `_cast()`, after the `if power.is_empty():` guard and before the `return`, the function becomes:

```gdscript
func _cast(power: Dictionary, ground: Vector2, extra := {}) -> FxTimeline:
	if power.is_empty():
		push_warning("Unknown power")
		return null
	if is_instance_valid(_crowd):
		_crowd.on_cast(ground)
	return FxTimeline.cast(load(power.path), _bf.ctx, ground, extra)
```

1f. Report the people in the HUD. Replace `_update_hud()` with:

```gdscript
func _update_hud() -> void:
	if _town == null or not is_instance_valid(_town.citadel) or not is_instance_valid(_crowd):
		return
	var power: Dictionary = PowerBook.POWERS[_selected]
	var cit := _town.citadel
	var text := "KAK town debug   [%s] %s  (%s, %d DP)\nCitadel %d%%   parts %d/9   buildings down %d\nCitizens %d   soldiers %d   escaped %d   alarm %d%%\n1-9 0 - pick   LMB cast (drag: line powers)   WASD / middle-drag pan   wheel zoom   R rebuild   Esc quit" % [
		KEY_LABELS[_selected], power.name, power.aim, power.dp, roundi(cit.fraction() * 100.0), cit.standing_parts(),
		_destroyed, _crowd.alive_citizens(), _crowd.alive_soldiers(), _crowd.escaped_count, roundi(_crowd.alarm)]
	if _hud.text != text:
		_hud.text = text
```

- [ ] **Step 2: Add the crowd's scripted run**

In `src/game/town_debug.gd`, add two constants next to `CITADEL_SHOTS`:

```gdscript
## [time, power key, ground point] for --crowd-test: enough violence to start a panic and a rally.
const CROWD_CASTS := [
	[1.0, "heaven", Vector2(-4.0, 4.0)],
	[8.0, "tornado", Vector2(3.0, 3.0)],
	[18.0, "cinder", Vector2(0.0, -2.0)],
]
const CROWD_SHOTS := [0.5, 3.0, 10.0, 16.0, 24.0, 34.0]
const CROWD_TEST_END := 40.0
```

and the mode itself, next to `_citadel_test()`:

```gdscript
## Scripted run for the people: a few casts in the streets, then a log of what the crowd does — how many are
## alive, fleeing, queueing and escaped, and what the alarm is doing.
func _crowd_test() -> void:
	_bf.camera.zoom = Vector2.ONE * 0.6
	_bf.camera.position = (Iso.ground_to_screen(Vector2(0.0, 2.0)) + Vector2(0, -30)).round()
	await _bf.wait_frames(10)
	_t = 0.0
	var casts := CROWD_CASTS.duplicate()
	var shots := CROWD_SHOTS.duplicate()
	var next_log := 0.0
	while _t < CROWD_TEST_END:
		while not casts.is_empty() and _t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			print("CAST %s t=%.1f" % [c[1], _t])
			_cast(PowerBook.get_power(c[1]), c[2])
		if not shots.is_empty() and _t >= float(shots[0]):
			await _bf.save_capture("crowd_%05d.png" % int(float(shots.pop_front()) * 1000.0))
		if _t >= next_log:
			next_log += 1.0
			var fleeing := 0
			var waiting := 0
			for p in _crowd.citizens:
				if not is_instance_valid(p) or not p.is_alive():
					continue
				if p.mind == Person.Mind.FLEE:
					fleeing += 1
				if p.wait > 0.0:
					waiting += 1
			print("CROWD t=%.1f citizens=%d soldiers=%d fleeing=%d queued=%d escaped=%d alarm=%d rallied=%s" % [
				_t, _crowd.alive_citizens(), _crowd.alive_soldiers(), fleeing, waiting, _crowd.escaped_count,
				roundi(_crowd.alarm), _crowd.soldiers.size() > 0 and _crowd.soldiers[0].mind == Person.Mind.RALLY])
		await get_tree().process_frame
	print("CROWD result citizens=%d escaped=%d alarm=%d" % [_crowd.alive_citizens(), _crowd.escaped_count, roundi(_crowd.alarm)])
	await _bf.quit()
```

Register the flag in `_ready()`, where the other modes are chosen — the chain becomes:

```gdscript
	if "--capture-town" in args:
		_capture_town()
	elif "--citadel-test" in args:
		_citadel_test()
	elif "--crowd-test" in args:
		_crowd_test()
	elif "--bench" in args:
		_run_bench(Battlefield.arg_value(args, "--only"))
```

and include it in the `scripted` test in `_ready()` so it runs on seed 7:

```gdscript
	var scripted := "--capture-town" in args or "--citadel-test" in args or "--crowd-test" in args or "--bench" in args
```

Add one shot of the crowd to `TOWN_SHOTS`, after the market entry:

```gdscript
	["town_crowd.png", Vector2(0.0, 3.0), 0.9],
```

Finally, make `tools/capture.sh` use fixed frames for the new mode: in the line

```bash
if [[ "$*" == *--capture* || "$*" == *--citadel-test* ]]; then EXTRA=(--fixed-fps 60); fi
```

add the new flag:

```bash
if [[ "$*" == *--capture* || "$*" == *--citadel-test* || "$*" == *--crowd-test* ]]; then EXTRA=(--fixed-fps 60); fi
```

- [ ] **Step 3: Run the tests and look at the town**

```bash
bash tools/test.sh
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --capture-town
```

Expected: `checks=351 failures=0`; seven `captured …` lines and no `SCRIPT ERROR`. Open `captures/town_crowd.png`, `town_market.png` and `town_overview.png` and check: people stand and walk in the streets, not inside buildings or in the river; soldiers are visible in the barracks yard and around the Citadel; citizens are spread across the districts rather than clumped on one spot; nobody is stuck on a wall corner.

- [ ] **Step 4: Run the crowd's scripted test**

```bash
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --crowd-test 2>&1 | grep -E "CROWD|CAST|ERROR"
```

Expected in the log:
- `citizens=160`-ish at the start (110 citizens, 50 soldiers reported separately), `alarm=0`, `fleeing=0`;
- after the first cast, `fleeing` climbs and `alarm` rises as buildings fall and people die;
- `queued` is non-zero at some point (people waiting at a gate);
- `escaped` climbs once the first citizens reach an exit;
- `rallied=true` after the alarm passes 25;
- no `ERROR` lines.

Open the `captures/crowd_*.png` frames: people running for the gates, a queue at a gate, soldiers ringing the Citadel. If people bunch up and stop moving, or nobody ever escapes, report the log and the frame rather than raising the timings.

- [ ] **Step 5: The milestone's performance gate**

```bash
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/town_debug.tscn --audio-driver Dummy --disable-vsync --max-fps 0 -- --bench
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/town_debug.tscn --audio-driver Dummy --disable-vsync --max-fps 0 -- --bench --only=cinder
```

Run each twice, report the medians. The spec's target is **50+ fps average during Cinderfall with the full crowd**. The bench spawns the full 160 people now, so these numbers are the milestone's acceptance.

If Cinderfall is below 50 fps, measure before changing anything (the method and the attribution table from milestone 1's pass are in `.git/sdd/perf-report.md`), then use the cheapest lever that keeps the behaviour:
- let people think at half rate — `Person._think` on alternating frames (keep `super(delta)` every frame so movement stays smooth), which halves the brain cost;
- sample the light field for units a few times a second instead of every frame (`DummyEnemy._process`), reusing the last tint in between;
- raise `Person.REPATH` or the stagger window so fewer paths are planned per second.
Report what you measured, what you changed, and the resulting numbers. Do not cut the crowd's size, and do not change any effect.

- [ ] **Step 6: Update the README**

In `README.md`, in the KAK section:

6a. Replace the sentence that begins "Milestone 1: the walled town of Aldermere" with:

```markdown
Milestone 2: the town is inhabited — 110 citizens who wander, panic, flee to the exits and queue at the gates, and 50 soldiers who hold their posts, rally to the Citadel when the alarm rises, and hold their ground in its rubble. Milestone 1 built the shared `Battlefield`, the walled town of Aldermere and its fortified Royal Citadel.
```

6b. Add these two lines to the check commands in that section:

```bash
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --crowd-test    # scripted panic; logs CROWD t= fleeing= queued= escaped= alarm=
```

6c. In the `## Layout` block, add after the `src/game/town/` line:

```
src/game/crowd/  the people: Person (citizen/soldier brains and bodies), Crowd (spawning, panic, gates, alarm, rally)
```

6d. In `## Verify`, change the check count to `checks=351 failures=0` (Task 6 raises it again, to 362).

- [ ] **Step 7: Commit**

```bash
git add src/game/town_debug.gd tools/capture.sh README.md
git commit -m "feat: Aldermere is inhabited" -m "The debug scene now builds the walk grid and the crowd instead of placeholder units, tells the crowd about every cast, and reports citizens, soldiers, escapes and the alarm in its HUD. --people=N scales the crowd, --crowd-test runs a scripted panic and logs it." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

- [ ] **Step 8: User checkpoint (controller)**

Show the user `captures/town_crowd.png`, two or three `captures/crowd_*.png` frames, the crowd log summary and the bench numbers, and ask them to playtest with `town.bat`. Milestone 3 (rules and HUD) gets its own plan once they approve.

---

### Task 6: Rebuilding the town

**Files:**
- Modify: `src/environment/environment_field.gd`, `src/game/town/town.gd`, `src/game/town/citadel.gd`
- Test: `tests/test_rebuild.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Produces:
  - `EnvironmentField.remove(s: Structure) -> void` — take one structure out of the field and free it (the spatial index is rebuilt).
  - `Town.teardown() -> void` — remove every building this town added (its own and the Citadel's), free the floor, and forget them. A torn-down `Town` can be `build()`-ed again.
  - `Citadel.setup()` resets its own state (health, marks, the rolling window, the stage flags, the part list), so the same instance can be rebuilt.
- Why: milestone 3's mission restart and the debug scene's `R` both need the town to go away without clearing everything else in the field, and milestone 1's review found `Town`/`Citadel` were single-use.

- [ ] **Step 1: Write the failing test**

Create `tests/test_rebuild.gd`:

```gdscript
extends RefCounted
## Tearing the town down and building it again leaves exactly one town behind: no leftover buildings, no second
## floor, a Citadel back at full health and a crowd of the right size.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var ground := Node2D.new()
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()

	var town := Town.new()
	town.build(env, ground)
	var first := env.structures().size()
	var grid := WalkGrid.new().setup(env, town)
	var crowd := Crowd.new().setup(field, env, town, grid, world, 3)
	crowd.spawn(20, 10)
	t.check(first == TownLayout.structures().size() + 9, "the first town is complete (%d)" % first)
	t.check(ground.get_child_count() == 1, "one floor under the ground plane")

	# Knock a few things down and hurt the Citadel, so the rebuild has state to clear.
	env.damage_radius(Vector2(0.0, 2.0), 3.0, 99999.0, &"stone")
	town.citadel.keep.damage(300.0, TownLayout.CITADEL_ORIGIN, &"stone")
	t.check(town.citadel.fraction() < 1.0, "the Citadel took damage")

	crowd.clear()
	town.teardown()
	t.check(env.structures().is_empty(), "teardown leaves no buildings behind (%d)" % env.structures().size())
	t.check(not env.blocked(TownLayout.TEMPLE.get_center()), "and nothing blocks where the temple stood")

	town.build(env, ground)
	t.check(env.structures().size() == first, "the rebuilt town has the same buildings (%d)" % env.structures().size())
	t.check(ground.get_child_count() == 1, "and still one floor")
	t.near(town.citadel.fraction(), 1.0, 0.001, "the Citadel is whole again")
	t.check(town.citadel.standing_parts() == 9 and town.citadel.parts.size() == 9, "with all nine parts")
	var grid2 := WalkGrid.new().setup(env, town)
	t.check(not grid2.walkable(TownLayout.TEMPLE.get_center()), "the temple blocks again")
	crowd = Crowd.new().setup(field, env, town, grid2, world, 4)
	crowd.spawn(20, 10)
	t.check(crowd.citizens.size() == 20 and crowd.soldiers.size() == 10, "and the crowd comes back")
	crowd.clear()
	town.teardown()
	env.clear()
	env.free()
	field.clear()
	field.free()
	town.free()
	crowd.free()
	world.free()
	ground.free()
```

Register it: add `"res://tests/test_rebuild.gd",` as the last entry of `SUITES` in `tests/run_all.gd`.

- [ ] **Step 2: Run the tests to see the new suite fail**

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_rebuild.gd` and `checks=352 failures=1`.

- [ ] **Step 3: Let the field give a building back**

In `src/environment/environment_field.gd`, add after `clear()`:

```gdscript
## Take one structure out of the field and free it (the town's teardown). The spatial index is rebuilt, so
## this is for the handful of times a map is torn down, not for destruction — destroyed buildings stay.
func remove(s: Structure) -> void:
	_structures.erase(s)
	if is_instance_valid(s):
		if s.light_id != 0 and lights != null:
			lights.remove(s.light_id)
			s.light_id = 0
		if s.is_inside_tree():
			s.queue_free()
		else:
			s.free()
	_reindex()


func _reindex() -> void:
	_grid.clear()
	for s in _structures:
		if is_instance_valid(s):
			_index(s)
```

`clear()` stays as it is — it already empties both the list and the index.

- [ ] **Step 4: Let the town be torn down**

In `src/game/town/town.gd`:

4a. Record what was built. Add next to the other members:

```gdscript
## Everything this town put into the field, so teardown() can take exactly that back out.
var _built: Array[Structure] = []
```

4b. In `build()`, remember each building — the loop becomes:

```gdscript
	for d in TownLayout.structures():
		var s := env.add_structure(d.rect, d.height, d.kind, d.role)
		_built.append(s)
		if s.kind == Structure.Kind.GATE:
			gates.append(s)
		elif s.kind == Structure.Kind.BRIDGE:
			bridge = s
```

and remember the Citadel's parts too, right after `citadel.setup(...)`:

```gdscript
	_built.append_array(citadel.parts)
```

4c. Add `teardown()` after `build()`:

```gdscript
## Take this town out of the world: its buildings (the Citadel's parts included) leave the field, the floor is
## freed, and the town forgets them so build() can run again.
func teardown() -> void:
	for s in _built:
		if is_instance_valid(s):
			_env.remove(s)
	_built.clear()
	gates.clear()
	bridge = null
	_free_floor()
```

4d. `teardown()` needs the field it built into. Add a member and set it in `build()`:

```gdscript
var _env: EnvironmentField
```

and as the first line of `build()`:

```gdscript
	_env = env
```

- [ ] **Step 5: Let the Citadel be rebuilt**

In `src/game/town/citadel.gd`, `setup()` currently sets `origin` and `health` and appends the parts. Replace its first lines so it also clears the state a previous life left behind — the function becomes:

```gdscript
func setup(env: EnvironmentField, at: Vector2, shake: CameraShake = null) -> Citadel:
	_env = env
	_shake = shake
	origin = at
	health = max_health
	parts.clear()
	keep = null
	_window.clear()
	_clock = 0.0
	_marks = 0
	_fires_lit = false
	_banner_dropped = false
	_fallen = false
	for r: Rect2 in TOWERS:
		_add_part(r, TOWER_H, Structure.Kind.KEEP)
	for r: Rect2 in WALLS:
		_add_part(r, WALL_H, Structure.Kind.CASTLE_WALL)
	keep = _add_part(KEEP, KEEP_H, Structure.Kind.KEEP)
	return self
```

- [ ] **Step 6: Run the tests**

Run: `bash tools/test.sh`
Expected: `checks=362 failures=0`.

- [ ] **Step 7: Check the debug scene's rebuild really works**

The `R` key is the only thing that exercises a rebuild in the running game, and milestone 1's review flagged that it had no coverage. Make the debug scene use the new teardown — in `src/game/town_debug.gd`, `_rebuild()`, replace the block that releases the old town:

```gdscript
	if is_instance_valid(_town):
		# Parents may be mid-teardown here, so never free a tree-resident town immediately.
		if _town.is_inside_tree():
			_town.queue_free()
		else:
			_town.free()
```

with:

```gdscript
	if is_instance_valid(_town):
		_town.teardown()
		if _town.is_inside_tree():
			_town.queue_free()
		else:
			_town.free()
```

Then run the scripted crowd test again and confirm it still ends cleanly (it rebuilds once at startup):

```bash
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --crowd-test 2>&1 | grep -E "CROWD result|ERROR"
```

Expected: one `CROWD result ...` line, no `ERROR` lines.

- [ ] **Step 8: Commit and push the milestone**

```bash
git add src/environment/environment_field.gd src/game/town/town.gd src/game/town/citadel.gd src/game/town_debug.gd tests/test_rebuild.gd tests/test_rebuild.gd.uid tests/run_all.gd
git commit -m "feat: the town can be torn down and rebuilt" -m "EnvironmentField.remove() gives one building back, Town.teardown() takes exactly what it built (the Citadel's parts and the floor included), and Citadel.setup() clears its own state, so a mission can restart. A headless test builds, damages, tears down and rebuilds, checking no building, floor or Citadel state survives." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
git tag kak-m2-people
git -c credential.helper= -c 'credential.helper=!"/c/Program Files/GitHub CLI/gh.exe" auth git-credential' push origin feat/vfx-proof
git -c credential.helper= -c 'credential.helper=!"/c/Program Files/GitHub CLI/gh.exe" auth git-credential' push origin kak-m2-people
```
