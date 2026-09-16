# Sci-Fi VFX Proof Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Playable Godot 4.7.2 sandbox proving four sci-fi skill VFX (Nuclear Nova, Orbital Strike, Gravity Distortion, Walking Laser Grid) with procedural pixel-art visuals and synthesized audio, in a 640×360 isometric view.

**Architecture:** Native 640×360 render upscaled with nearest filter. Ground-plane effects live under a `GroundPlane` node whose transform is the iso basis, so they are authored in ground units and project automatically. Vertical/overhead effects live in screen-space layers (y-sorted world, overhead, distortion). Each effect is an `FxTimeline` subclass scheduling stage callbacks, talking to gameplay only through `EnemyField` and to audio only through `Sfx`. Audio cues synthesized offline by Python into committed WAVs.

**Tech Stack:** Godot 4.7.2 (GDScript, GL Compatibility, canvas_item shaders), Python 3.12 + numpy + scipy.

## Global Constraints

- Godot `F:\Godot\Godot_v4.7.2-stable_win64_console.exe`, renderer `gl_compatibility`.
- Viewport 640×360, `stretch/mode="viewport"`, `aspect="keep"`, window override 1280×720, default texture filter nearest.
- Iso cell 64×32 px = 1 ground unit. `screen = ((gx - gy) * 32, (gx + gy) * 16)`.
- Procedural art only; no downloaded/external assets.
- Shaders use `uniform float u_time` driven from script (respects `Engine.time_scale`), never built-in `TIME`.
- Audio: 44.1 kHz, 16-bit mono WAV, peak −1 dBFS, deterministic seeds, WAVs committed.
- Tests: `& $godot --headless --path . --script res://tests/run_all.gd` prints `failures=0`, exit code 0.
- Commit after each task; messages end with `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.

---

## File Structure

| File | Responsibility |
|---|---|
| `project.godot` | engine config (constraints above), main scene, bus layout |
| `default_bus_layout.tres` | `SFX` bus; Master compressor + hard limiter |
| `src/core/iso.gd` | `class_name Iso` — pure projection math |
| `src/core/camera_shake.gd` | `class_name CameraShake extends Camera2D` — trauma shake, integer offsets |
| `src/enemies/dummy_enemy.gd` | `class_name DummyEnemy extends Node2D` — ground-space state machine + pixel draw |
| `src/enemies/enemy_field.gd` | `class_name EnemyField extends Node` — registry, spatial queries, pull/knock/kill |
| `src/fx/fx_context.gd` | `class_name FxContext extends RefCounted` — handles passed to effects |
| `src/fx/fx_timeline.gd` | `class_name FxTimeline extends Node2D` — time-scheduled stage base |
| `src/fx/quad_fx.gd` | `class_name QuadFx extends Node2D` — shader quad, drives `u_time`, anchor |
| `src/fx/pixel_particles.gd` | `class_name PixelParticles extends Node2D` — square/puff/streak particles with altitude |
| `src/fx/fx_parts.gd` | `class_name FxParts` — static builders (rings, shockwave, beam, decal, bursts, smoke) |
| `src/fx/nuclear_nova.gd` etc. | the four effects |
| `src/audio/sfx.gd` | `class_name Sfx extends Node` — cue catalog, pooled positional playback |
| `src/sandbox/ground_tiles.gd` | draws tile floor in ground units |
| `src/sandbox/sandbox.gd` | scene assembly, input, HUD, capture/bench modes |
| `scenes/sandbox.tscn` | root node with `sandbox.gd` |
| `shaders/*.gdshader` | iso_rings, shockwave, fireball_dome, singularity, beam_glow, scorch_decal, fog |
| `tools/audio/synth.py` | cue synthesis + `--verify` |
| `tests/run_all.gd`, `tests/test_*.gd` | headless tests |

---

### Task 1: Project scaffold, Iso math, test harness

**Files:**
- Create: `project.godot`, `icon.svg`, `src/core/iso.gd`, `tests/run_all.gd`, `tests/test_iso.gd`

**Interfaces:**
- Produces: `Iso.CELL_W := 64`, `Iso.CELL_H := 32`, `Iso.BASIS: Transform2D` (x=(32,16), y=(-32,16)), `Iso.ground_to_screen(g: Vector2) -> Vector2`, `Iso.screen_to_ground(s: Vector2) -> Vector2`, `Iso.radius_to_screen(r: float) -> Vector2` (semi-axes). Test harness: suite scripts expose `static func run(t) -> void`; `t.check(cond: bool, msg: String)`, `t.near(a: float, b: float, eps: float, msg: String)`.

- [ ] **Step 1: Write project.godot + harness + failing iso test**

`tests/run_all.gd`:
```gdscript
extends SceneTree

const SUITES := ["res://tests/test_iso.gd"]

var failures := 0
var checks := 0

func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: ", msg)

func near(a: float, b: float, eps: float, msg: String) -> void:
	check(absf(a - b) <= eps, "%s (got %f expected %f)" % [msg, a, b])

func _initialize() -> void:
	for path in SUITES:
		var suite = load(path)
		suite.run(self)
	print("checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)
```

`tests/test_iso.gd`:
```gdscript
extends RefCounted

static func run(t) -> void:
	var s := Iso.ground_to_screen(Vector2(1, 0))
	t.check(s == Vector2(32, 16), "unit x projects to (32,16)")
	t.check(Iso.ground_to_screen(Vector2(0, 1)) == Vector2(-32, 16), "unit y projects to (-32,16)")
	for g in [Vector2(3.5, -2.25), Vector2(-7, 4), Vector2.ZERO]:
		var back := Iso.screen_to_ground(Iso.ground_to_screen(g))
		t.check(back.is_equal_approx(g), "round trip %s" % g)
	var axes := Iso.radius_to_screen(1.0)
	t.near(axes.x, 32.0 * sqrt(2.0), 0.001, "ellipse semi-axis x")
	t.near(axes.y, 16.0 * sqrt(2.0), 0.001, "ellipse semi-axis y")
	t.check(Iso.BASIS * Vector2(2, 3) == Iso.ground_to_screen(Vector2(2, 3)), "BASIS matches projection")
```

- [ ] **Step 2: Import + run, verify FAIL** (`Iso` undefined)

```powershell
$godot = 'F:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godot --headless --editor --path . --import
& $godot --headless --path . --script res://tests/run_all.gd
```

- [ ] **Step 3: Implement `src/core/iso.gd`**

```gdscript
class_name Iso
extends RefCounted

const CELL_W := 64
const CELL_H := 32
const BASIS := Transform2D(Vector2(32, 16), Vector2(-32, 16), Vector2.ZERO)

static func ground_to_screen(g: Vector2) -> Vector2:
	return Vector2((g.x - g.y) * 32.0, (g.x + g.y) * 16.0)

static func screen_to_ground(s: Vector2) -> Vector2:
	var a := s.x / 32.0
	var b := s.y / 16.0
	return Vector2((a + b) * 0.5, (b - a) * 0.5)

static func radius_to_screen(r: float) -> Vector2:
	return Vector2(32.0, 16.0) * sqrt(2.0) * r
```

- [ ] **Step 4: Re-import, run tests → `failures=0`**
- [ ] **Step 5: Commit** `feat: project scaffold, iso projection, test harness`

---

### Task 2: EnemyField + DummyEnemy

**Files:**
- Create: `src/enemies/dummy_enemy.gd`, `src/enemies/enemy_field.gd`, `tests/test_enemy_field.gd`
- Modify: `tests/run_all.gd` (add suite)

**Interfaces:**
- Consumes: `Iso.ground_to_screen`
- Produces:
  - `DummyEnemy`: `enum State { WANDER, KNOCKBACK, PULLED, DEAD }`, `ground_pos: Vector2`, `state: State`, `bounds: Rect2` (ground), `knock(v: Vector2)`, `pull_step(center: Vector2, strength: float, swirl: float, delta: float)`, `release()`, `die(kind: StringName)`, `is_alive() -> bool`, `flash(seconds: float)`, `tick(delta: float)` (called from `_process`; tests call directly).
  - `EnemyField`: `signal enemy_killed(enemy: DummyEnemy, kind: StringName)`, `bounds: Rect2`, `spawn(count: int, parent: Node, rng: RandomNumberGenerator)`, `clear()`, `alive() -> Array[DummyEnemy]`, `in_radius(center: Vector2, r: float) -> Array[DummyEnemy]`, `in_lane(origin: Vector2, dir: Vector2, half_width: float, along_min: float, along_max: float) -> Array[DummyEnemy]`, `kill(e: DummyEnemy, kind: StringName) -> bool`, `knock_from(center: Vector2, r_min: float, r_max: float, force: float)`, `pull(center: Vector2, radius: float, strength: float, swirl: float, delta: float)`, `release_all()`, `add(e: DummyEnemy)`.

- [ ] **Step 1: Failing tests**

`tests/test_enemy_field.gd`:
```gdscript
extends RefCounted

static func _field_with(points: Array) -> EnemyField:
	var f := EnemyField.new()
	f.bounds = Rect2(-50, -50, 100, 100)
	for p in points:
		var e := DummyEnemy.new()
		e.ground_pos = p
		f.add(e)
	return f

static func run(t) -> void:
	var f := _field_with([Vector2(0, 0), Vector2(2, 0), Vector2(5, 5)])
	t.check(f.in_radius(Vector2.ZERO, 2.5).size() == 2, "in_radius finds 2")
	var lane := f.in_lane(Vector2(-1, 0), Vector2(1, 0), 0.5, 0.0, 2.5)
	t.check(lane.size() == 1, "lane length excludes far enemy")
	lane = f.in_lane(Vector2(-1, 0), Vector2(1, 0), 0.5, 0.0, 3.5)
	t.check(lane.size() == 2, "lane covers two on axis")

	var e: DummyEnemy = f.alive()[0]
	t.check(f.kill(e, &"test"), "kill returns true first time")
	t.check(not f.kill(e, &"test"), "kill returns false when already dead")
	t.check(f.alive().size() == 2, "dead removed from alive")

	var g := _field_with([Vector2(4, 0), Vector2(0, -3)])
	var before := [g.alive()[0].ground_pos.length(), g.alive()[1].ground_pos.length()]
	for i in 180:
		g.pull(Vector2.ZERO, 4.5, 3.0, 1.0, 1.0 / 60.0)
	for i in 2:
		var d: float = g.alive()[i].ground_pos.length()
		t.check(d < before[i] * 0.3, "pull converges enemy %d (d=%f)" % [i, d])
		t.check(g.alive()[i].state == DummyEnemy.State.PULLED, "pulled state")
	g.release_all()
	t.check(g.alive()[0].state == DummyEnemy.State.WANDER, "release returns to wander")

	var k := _field_with([Vector2(3, 0)])
	k.knock_from(Vector2.ZERO, 0.0, 5.0, 6.0)
	for i in 30:
		k.alive()[0].tick(1.0 / 60.0)
	t.check(k.alive()[0].ground_pos.x > 3.2, "knockback pushes outward")
	for x in [f, g, k]:
		x.clear()
		x.free()
```

- [ ] **Step 2: Run → FAIL**
- [ ] **Step 3: Implement** `dummy_enemy.gd` (state machine in `tick(delta)` called from `_process`; wander picks random ground target inside `bounds` at 0.6 u/s; knock sets velocity decaying 6/s; pull_step moves toward center at `strength * (0.5 + 0.5 * (1 - d/5))` plus perpendicular `swirl * strength * 0.5`, clamped to not overshoot min distance 0.15; `_draw` pixel soldier ~9×15 px with shadow, armor, red visor, 2-frame walk bob; flash draws white; DEAD: charred colors, fade 1.2 s then `queue_free`; `position = Iso.ground_to_screen(ground_pos).round()`) and `enemy_field.gd` (array registry, queries in ground space, emits `enemy_killed`).
- [ ] **Step 4: Run → `failures=0`**
- [ ] **Step 5: Commit** `feat: enemy field and dummy enemies`

---

### Task 3: Sandbox scene, FX framework, capture mode

**Files:**
- Create: `src/core/camera_shake.gd`, `src/fx/fx_context.gd`, `src/fx/fx_timeline.gd`, `src/fx/quad_fx.gd`, `src/fx/pixel_particles.gd`, `src/sandbox/ground_tiles.gd`, `src/sandbox/sandbox.gd`, `scenes/sandbox.tscn`, `tests/test_fx_timeline.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Produces:
  - `CameraShake.add_trauma(amount: float)`; offset = `trauma² * 8px * noise`, rounded; decay 1.6/s.
  - `FxContext` fields: `field: EnemyField`, `shake: CameraShake`, `sfx: Sfx` (null until Task 10), `ground: Node2D` (iso-basis plane), `world: Node2D` (y-sorted), `overhead: Node2D`, `distort: Node2D`, `rng: RandomNumberGenerator`, `flash: Callable` (`func(color: Color, seconds: float)`).
  - `FxTimeline`: `ctx: FxContext`, `origin: Vector2` (ground), `t: float`, `duration: float`, `at(time: float, fn: Callable)`, `track(node: Node, parent: Node) -> Node` (adds child, frees on effect end), virtual `_build()`, virtual `_fx_process(delta: float)`, `static func cast(script: GDScript, ctx: FxContext, origin: Vector2, extra := {}) -> FxTimeline`.
  - `QuadFx`: `setup(shader: Shader, size: Vector2, anchor := Vector2(0.5, 0.5)) -> QuadFx`, `set_param(name: StringName, value)`, `tween_param(name, from, to, seconds, trans := Tween.TRANS_LINEAR) -> Tween`, `life: float` (auto free when > 0 and elapsed). Updates `u_time` each frame.
  - `PixelParticles`: `enum Shape { SQUARE, PUFF, STREAK }`, properties `shape`, `ramp: PackedColorArray`, `gravity: float` (px/s² on altitude), `drag: float`, `iso_squash := 0.5`, `bounce := false`, `emitting := false`, `rate: float`, `spec: Dictionary`, `burst(count: int, spec: Dictionary)`. Spec keys: `radius`, `speed`: Vector2(min,max), `alt_speed`: Vector2, `alt`: Vector2, `life`: Vector2, `size`: Vector2, `size_end_mul`, `angle`: Vector2 (radians). Auto-frees when `auto_free` and empty and not emitting.
  - Sandbox command-line: `--capture-all` (fixed seed 7, casts each effect, saves 2× nearest-scaled PNGs to `res://captures/<effect>_<ms>.png`, quits), `--bench` (casts all four simultaneously, logs min/avg FPS over 9 s, quits).
- [ ] **Step 1: Failing test** `tests/test_fx_timeline.gd` — timeline with events at 0.1 and 0.5 fires in order after manual `_process` steps; tracked node freed on end.

```gdscript
extends RefCounted

class Probe extends FxTimeline:
	var events: Array = []
	func _build() -> void:
		duration = 1.0
		at(0.5, func(): events.append("b"))
		at(0.1, func(): events.append("a"))

static func run(t) -> void:
	var p := Probe.new()
	var holder := Node.new()
	var part := Node.new()
	p._build()
	p.track(part, holder)
	for i in 30:
		p._process(1.0 / 60.0)
	t.check(p.events == ["a", "b"], "events fire in time order (%s)" % [p.events])
	t.check(not p.is_queued_for_deletion(), "not finished at 0.5s")
	for i in 40:
		p._process(1.0 / 60.0)
	t.check(p.finished, "finished after duration")
	t.check(not is_instance_valid(part) or part.is_queued_for_deletion(), "tracked part freed")
	holder.free()
	if is_instance_valid(p):
		p.free()
```
- [ ] **Step 2: Run → FAIL**
- [ ] **Step 3: Implement framework files** (FxTimeline sorts events by time, fires all `<= t`, sets `finished`, frees tracked nodes and `queue_free()` self).
- [ ] **Step 4: Implement sandbox**: `GroundPlane` transform `Iso.BASIS`, `GroundTiles` draws 14×14 cells (dark blue-grey 3 shades, 1px seams, sparse cyan light dots), `WorldLayer` `y_sort_enabled`, `OverheadLayer` z 10, `DistortLayer` z 20, camera centered on map, WASD/arrow pan, HUD label (CanvasLayer), full-screen flash ColorRect. Input: `1-4` select, LMB press/release cast (laser uses drag direction, default `Vector2(1,0)` ground when drag < 0.5 u), `R` respawn 40, `Space` toggle `Engine.time_scale` 1.0/0.25, `Esc` quit.
- [ ] **Step 5: Tests pass; run sandbox capture of idle scene** `& $godot --path . --audio-driver Dummy -- --capture-idle` → `captures/idle.png`; inspect: tiles visible, enemies drawn, no errors in console.
- [ ] **Step 6: Commit** `feat: sandbox scene, fx framework, capture mode`

---

### Task 4: Nuclear Nova (+ shared shaders)

**Files:**
- Create: `shaders/iso_rings.gdshader`, `shaders/shockwave.gdshader`, `shaders/fireball_dome.gdshader`, `shaders/beam_glow.gdshader`, `shaders/scorch_decal.gdshader`, `shaders/fog.gdshader`, `src/fx/fx_parts.gd`, `src/fx/nuclear_nova.gd`
- Modify: `src/sandbox/sandbox.gd` (register effect 1, capture times)

**Interfaces:**
- Produces `FxParts` static builders used by all later effects:
  - `rings(ctx, parent: Node2D, center: Vector2, radius: float, color: Color, ring_count: int, dashes: int) -> QuadFx` (ground plane; params `reveal`, `alpha`, `scan`, `pulse`)
  - `shockwave(ctx, center, radius, ramp: PackedColorArray, seconds) -> QuadFx`
  - `beam(parent, screen_pos: Vector2, width: float, height: float, colors: PackedColorArray) -> QuadFx` (anchor bottom center; param `intensity`)
  - `link_beam(parent, a: Vector2, b: Vector2, width: float, colors) -> QuadFx` (rotated quad between screen points)
  - `decal(ctx, center, radius, char_color, edge_color, life: float, warp := 0.0) -> QuadFx`
  - `fog(ctx, center, radius, color, life) -> QuadFx`
  - `debris(parent, screen_pos, count, radius) -> PixelParticles`
  - `sparks(parent, screen_pos, count, ramp, speed) -> PixelParticles`
  - `smoke(parent, screen_pos, count, spread, rise, life) -> PixelParticles`
  - Palettes: `FxParts.FIRE: PackedColorArray` (white→yellow→orange→red→dark red), `FxParts.VOID` (white→lavender→violet→purple→near black), `FxParts.SMOKE`, `FxParts.RAD` (greens), `FxParts.ION` (cyans)
- Shader contract: every shader quantizes intensity to ≤5 steps and maps to palette colors passed as uniforms `c0..c4`; uses `u_time`.

- [ ] **Step 1: Write shaders + FxParts**
- [ ] **Step 2: Write `nuclear_nova.gd`** per spec stage table: telegraph rings radius 5 (reveal 0→1 over 0.6 s, scan on) + center crosshair; 1.5 s warhead (code-drawn 7×16 px sprite node in world layer, falling from screen offset (-140,-260) to target over 0.8 s, ease-in, emits fire streak + smoke puffs); 2.3 s: `ctx.flash(white, 0.25)`, shake 1.0, pillar beam (w 20, h 360) fading 0.6 s, kill radius 1.2; shockwave 0→5 over 1.0 s, kills enemies when `dist <= wave_radius`, knock 5–7 at wave end; dome quad grows 0→1 over 0.35 s, holds, collapses/dissolves by 1.4 s; debris 120, sparks 80; crater decal radius 2.2 life 8; aftermath smoke column (continuous puffs 2.2 s), rad fog radius 4 life 6, fallout green squares rising slowly.
- [ ] **Step 3: Capture** `& $godot --path . --audio-driver Dummy -- --capture-all --only=nova`; view each PNG against `VFXConcept_Nuclear Nova.png` stages; iterate shader/params until each stage reads (telegraph clear, descent visible, flash+pillar, ring + dome, aftermath green haze). Console: zero errors.
- [ ] **Step 4: Tests still pass; commit** `feat: nuclear nova effect and shared vfx shaders`

---

### Task 5: Orbital Strike

**Files:** Create `src/fx/orbital_strike.gd`; Modify `src/sandbox/sandbox.gd`.

**Interfaces:** Consumes `FxParts.rings/beam/debris/sparks/smoke/decal`, `EnemyField.in_radius/kill/knock_from`.

- [ ] **Step 1: Implement**: area rings radius 4.5 + 10 static pips (small crosses drawn by a ground-plane `_draw` node) for 0–1 s; strike points: 12 samples uniform in disc (`sqrt(u)` radius) with rejection for min spacing 0.8 (max 200 attempts), times spread 1.0–4.1 s with random jitter ±0.08; per strike: at `ts` reticle rings (radius 0.7, 2 rings, reveal 0.2 s) + thin aim beam (w 2, alpha 0.5, from above screen) ; at `ts+0.4`: heavy beam (w 12→0 over 0.25 s), flash quad small, kill ≤1.0, knock 1.0–1.8 force 4, debris 30, sparks 25, smoke 8, crater decal radius 0.9 life 6, shake 0.35; aftermath 4.5–6.5: cyan ion sparks crackling at 5 random crater points, embers.
- [ ] **Step 2: Capture `--only=orbital`**, compare with concept sheet; iterate.
- [ ] **Step 3: Commit** `feat: orbital strike effect`

---

### Task 6: Gravity Distortion

**Files:** Create `shaders/singularity.gdshader`, `src/fx/gravity_distortion.gd`; Modify `src/sandbox/sandbox.gd`.

**Interfaces:** Consumes `EnemyField.pull/release_all/in_radius/kill/knock_from`, `FxParts.rings/shockwave/decal/sparks`, `FxParts.VOID`.

- [ ] **Step 1: Singularity shader**: `hint_screen_texture, filter_nearest`; swirl rotation `strength * (1-r)^2`, pinch, purple tint rising toward center, spiral arm bands quantized, black core radius `core` with lavender rim, zero outside r>1.
- [ ] **Step 2: Effect**: 0–0.8 purple rings (radius 4.5, reveal), singularity quad in distort layer sized to `Iso.radius_to_screen(4.5)*2`, strength 0→0.6, core 0→0.06; 0.8–3.5 pull strength ramps 0.8→3.2 u/s swirl 1.0 (`field.pull` per frame), strength 0.6→2.2, core 0.06→0.14, inward streak particles (STREAK spawned on ring edge with velocity toward center), rubble squares spiraling (manually integrated in `_fx_process`); 3.5–4.1 compression: core 0.14→0.05 with flicker, rings reveal 1→0.3, pull 4.0; 4.1: flash dark (`Color(0.1,0,0.15)` 0.06 s) then lavender flash 0.2 s, shake 0.9, kill ≤1.5, knock others outward force 7, `release_all`, void shockwave 0→4.5 over 0.6 s, sparks 120 radial; aftermath decal warp 1.0 purple edge life 6, floating sparks rising 2.4 s.
- [ ] **Step 3: Capture `--only=gravity`**, compare, iterate.
- [ ] **Step 4: Commit** `feat: gravity distortion effect`

---

### Task 7: Walking Laser Grid

**Files:** Create `src/fx/walking_laser_grid.gd`; Modify `src/sandbox/sandbox.gd`.

**Interfaces:** Consumes `EnemyField.in_lane/kill`, `FxParts.beam/link_beam/sparks/smoke/decal`. Extra cast data: `extra.dir: Vector2` (normalized ground direction).

- [ ] **Step 1: Implement**: lane frame: `dir`, `side = dir.orthogonal()`, width 5, length 10. Ground-plane `_draw` node transformed by basis (rotation from `dir`) draws lane rect + 1-unit grid lines + boundary node markers, reveal sweep along length 0–1 s, pulsing alpha. 5 emitters at `origin + side * (-2, -1, 0, 1, 2)`, code-drawn drone (11×7 px body, two blue thruster pixels) descending from altitude 180 px to 70 px over 0.6 s (ease-out) with vertical lock beams (w 3) to ground; 1.6 s link beams at altitude 20 and 45 between adjacent emitters + intersection sparks; walk 2.0–5.5 s: `front = (t-2)/3.5 * length`, per frame: move posts, kill enemies `in_lane(origin, dir, 2.6, front-0.35, front+0.35)` → contact burn sparks + enemy flash; scorched trail decal = ground `_draw` strip from 0 to front with molten edge pixels (noise), fading after end; motion streaks behind wall; 5.5 s beams intensity→0 0.3 s, drones rise to 260 px & fade 1.5 s; smoke wisps along trail.
- [ ] **Step 2: Capture `--only=laser`**, compare, iterate.
- [ ] **Step 3: Commit** `feat: walking laser grid effect`

---

### Task 8: Audio synthesis

**Files:** Create `tools/audio/synth.py`, `assets/audio/{nova,orbital,gravity,laser}/*.wav` (generated).

**Interfaces:** Produces WAV files at `assets/audio/<effect>/<cue>.wav` for every cue in spec table (variants `orb_hit_1..4`, `laser_sizzle_1..3`). CLI: `python tools/audio/synth.py [--only CUE] [--verify]`. Verify prints `audio verify: N cues, 0 problems`, exit 1 on problems.

- [ ] **Step 1: Write DSP helpers**: `sine_sweep(f0,f1,dur)`, `noise(dur,seed)`, `bandpass/lowpass/highpass(x, f, q)` via `scipy.signal.butter` sos, `env_adsr`, `exp_decay`, `saturate(x, drive)` (tanh), `reverb(x, decay, mix)` (sum of 4 feedback comb filters + 2 allpass), `normalize(x, -1 dBFS)`, `fade(x, ms)`, `loopify(x, crossfade_ms)`.
- [ ] **Step 2: Write cue functions** (one per cue id, registered in `CUES = {id: (effect, fn, length, loop)}`) and `--verify` checks (exists, length ±5%, peak ≤ −1 dBFS + 0.05 tolerance, finite, |mean| < 0.01, loops: first/last sample |x| < 0.02).
- [ ] **Step 3: Generate + verify** `python tools/audio/synth.py; python tools/audio/synth.py --verify` → `0 problems`. Render spectrogram PNGs to scratchpad for sanity (shape of sweeps/booms visible).
- [ ] **Step 4: Commit** `feat: synthesized sfx cues`

---

### Task 9: Sfx playback + hook cues into effects

**Files:** Create `src/audio/sfx.gd`, `default_bus_layout.tres`, `tests/test_sfx_catalog.gd`; Modify `project.godot` (`audio/buses/default_bus_layout`), `src/sandbox/sandbox.gd` (create `Sfx`, `AudioListener2D` on camera, ctx.sfx), four effect scripts, `tests/run_all.gd`.

**Interfaces:**
- Produces: `Sfx.CATALOG: Dictionary` (`&"nova_alarm": {path, db, voices, jitter, loop}`, variants via `variants: int`), `Sfx.play(cue: StringName, ground_pos: Vector2, db_offset := 0.0) -> AudioStreamPlayer2D`, `Sfx.fade_out(p: AudioStreamPlayer2D, seconds: float)`, `Sfx.stop_all(prefix: String)`, `Sfx.set_voice_pitch(p, mul: float)`.
- [ ] **Step 1: Failing test** `test_sfx_catalog.gd`: every catalog entry (expanding variants) loads as `AudioStreamWAV`; loop entries report `loop_mode == AudioStreamWAV.LOOP_FORWARD` after `Sfx.load_stream(cue)`.
- [ ] **Step 2: Implement Sfx** (pool 32 `AudioStreamPlayer2D` on bus `SFX`, `max_distance 900`, per-cue voice limit steals oldest, pitch = base × jitter × `Engine.time_scale` updated in `_process`) + bus layout (Master: Compressor threshold −12 dB ratio 4, HardLimiter ceiling −0.5 dB).
- [ ] **Step 3: Hook cues** at spec trigger times in each effect `_build()`; loops faded at stage end; gravity implode cuts other gravity voices then plays boom after 0.08 s; laser sizzle on each kill; orbital charge + hit per strike.
- [ ] **Step 4: Import, tests pass, sandbox run 10 s with real audio driver → console no errors.**
- [ ] **Step 5: Commit** `feat: positional sfx playback wired to effects`

---

### Task 10: Bench, final verification, README

**Files:** Create `README.md`; Modify `src/sandbox/sandbox.gd` if bench needs fixes.

- [ ] **Step 1:** `& $godot --path . --audio-driver Dummy -- --bench` → record min/avg FPS; target min ≥ 60. If below, reduce particle counts / shader loops and rerun.
- [ ] **Step 2:** Full `--capture-all`, review all captures one final time.
- [ ] **Step 3:** Tests + audio verify both green.
- [ ] **Step 4:** README: run command, controls, file map, how to regenerate audio, how to capture.
- [ ] **Step 5: Commit** `docs: readme, bench results`
