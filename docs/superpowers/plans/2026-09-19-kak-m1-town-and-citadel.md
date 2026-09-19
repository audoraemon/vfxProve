# KAK Milestone 1 — Battlefield, Town and Fortified Citadel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build milestone 1 of the Kingdoms Amid Kataclysm (KAK) one-mission game: a shared `Battlefield` world (moved out of the VFX sandbox), the walled town of Aldermere with every building, the fortified nine-part Royal Citadel, and a debug scene that casts any of the 11 approved powers on the town.

**Architecture:** The sandbox's world setup (ground plane, draw layers, camera, sound, lights, buildings, units, glow, impact post, screen flash, `FxContext`) moves into `src/game/battlefield.gd`; the sandbox and the new debug scene each add one `Battlefield` child. Buildings stay `Structure` nodes in `EnvironmentField`; they gain a role tag, walkability, a damage filter and a `broken` signal, plus seven new kinds. `TownLayout` is pure data, `Town` builds it, `Citadel` owns nine parts through their damage filter (a shared health pool that loses at most 25% per rolling second). The 11 effects in `src/fx/` do not change.

**Tech Stack:** Godot 4.7.2 (GDScript, GL Compatibility), headless test runner `tests/run_all.gd`, capture/bench tools in `tools/`, Python 3 + Pillow for capture comparison.

**Spec:** `docs/superpowers/specs/2026-09-19-kak-one-mission-game-design.md` (milestone 1 of its §8 build order). Milestones 2–5 (people, rules + HUD, screens, polish) get their own plans after this one is playable.

## Global Constraints

- Engine: `F:\Godot\Godot_v4.7.2-stable_win64_console.exe` (Git Bash: `/f/Godot/Godot_v4.7.2-stable_win64_console.exe`), renderer `gl_compatibility`.
- Viewport 640×360, stretch mode viewport, nearest filtering, `2d/snap/snap_2d_vertices_to_pixel=true`: draw pixel lines as hairlines (`width = -1.0`); never `draw_line` with width ≥ 1.
- Iso: one ground unit = one 64×32 cell; `Iso.ground_to_screen(g) = ((g.x - g.y) * 32, (g.x + g.y) * 16)`. Town coordinates: origin at the town centre, plan north = −y.
- The 11 approved effects and the effect toolkit (`src/fx/`) do not change.
- New game code lives in `src/game/` (town pieces in `src/game/town/`).
- City art is procedural, in the existing pixel-box `Structure` style; no new external assets.
- The VFX sandbox (`scenes/sandbox.tscn`, still the main scene) must look and work exactly as before; checked with before/after captures.
- Tests: `bash tools/test.sh` must end with `checks=<N> failures=0`; the existing 217 checks keep passing. Suites are `extends RefCounted` scripts with `static func run(t) -> void`, registered in `tests/run_all.gd` `SUITES`; use `t.check(cond, msg)` and `t.near(a, b, eps, msg)`.
- The game's name in any text is **Kingdoms Amid Kataclysm** / **KAK** (never KWAI or HUM).
- GDScript style: tabs, typed vars; give an explicit type (`var x: float = ...`) when the value comes from an untyped Array/Dictionary; `##` doc comments like the surrounding code.
- Commit after each task. Every commit message ends with a blank line and `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`. Commit new scripts together with their generated `.gd.uid` files.
- Leave the untracked `.codex/` folder and `docs/HUM_Game_Design_Document_v1.docx` alone (never add them).
- **User checkpoints:** the user approves visual steps from images. After Task 3 (building kinds preview) and after Task 8 (town captures and Citadel test), the controller shows the PNGs to the user and waits for approval before moving on.

## File Structure

| File | Change | Responsibility |
|---|---|---|
| `src/game/battlefield.gd` | new | `class_name Battlefield extends Node2D`: the shared world (layers, camera, sound, lights, buildings, units, glow, impact, flash, `FxContext`) plus reset, capture, bench and quit helpers |
| `src/sandbox/sandbox.gd` | modify | VFX sandbox on top of one `Battlefield`: effect list, floor tiles, drag preview, HUD, camera push-in, capture/bench |
| `src/environment/structure.gd` | modify | role, walkable, damage filter, `broken` signal, stage helpers (`mark_hit`, `crack`, `ignite`, `dust_burst`, `drop_banner`), 7 new kinds and their drawing |
| `src/environment/environment_field.gd` | modify | `structure_destroyed` signal, role on add, walkable-aware `blocked()` with a spatial index |
| `src/game/town/town_layout.gd` | new | `class_name TownLayout`: Aldermere as pure data |
| `src/game/town/citadel.gd` | new | `class_name Citadel extends Node`: nine-part fortified compound on one health pool |
| `src/game/town/town_floor.gd` | new | `class_name TownFloor extends Node2D`: the town's ground drawing and river glints |
| `src/game/town/town.gd` | new | `class_name Town extends Node`: builds the layout, the Citadel and the floor |
| `src/game/power_book.gd` | new | `class_name PowerBook`: the 11 powers (cost, cooldown, aim, effect script, icons) |
| `src/game/town_debug.gd`, `scenes/town_debug.tscn` | new | M1 debug scene: cast any power on the town; `--capture-town`, `--citadel-test`, `--bench` |
| `town.bat` | new | launches the debug scene |
| `tools/capture.sh` | modify | `SCENE` env var; fixed fps for `--citadel-test` |
| `tools/dev/compare_captures.py`, `tools/dev/sandbox_baseline.sh` | new | before/after capture comparison for refactors |
| `tools/dev/preview_kinds.gd` | new | renders the new building kinds standing and destroyed |
| `tests/test_structure_roles.gd`, `tests/test_building_kinds.gd`, `tests/test_town_layout.gd`, `tests/test_citadel.gd`, `tests/test_town.gd`, `tests/test_power_book.gd` | new | headless suites |
| `tests/run_all.gd` | modify | registers the new suites |
| `README.md` | modify | KAK section, layout, check count |

Expected `checks=` after each task: Task 1 → 217, Task 2 → 235, Task 3 → 247, Task 4 → 263, Task 5 → 279, Task 6 → 288, Task 7 → 294, Task 8 → 294.

---

### Task 1: Shared Battlefield (moved out of the sandbox)

**Files:**
- Create: `src/game/battlefield.gd`, `tools/dev/compare_captures.py`, `tools/dev/sandbox_baseline.sh`
- Modify: `src/sandbox/sandbox.gd`

**Interfaces:**
- Consumes: existing `FxContext`, `CameraShake`, `Sfx`, `LightField`, `EnvironmentField`, `EnemyField`, `Impact`, `Iso`.
- Produces (`class_name Battlefield extends Node2D`, builds everything in `_ready()`, so add it to the tree first):
  - `var ctx: FxContext` (all fields wired: `field`, `env`, `lights`, `shake`, `sfx`, `ground`, `world`, `overhead_back`, `overhead`, `impact`, `distort`, `rng`, `flash`)
  - `var rng: RandomNumberGenerator`, `var camera: CameraShake`, `var ground_plane: Node2D` (transform `Iso.BASIS`, z −10), `var hud_layer: CanvasLayer` (layer 5, empty)
  - `func flash(color: Color, seconds: float) -> void`
  - `func reset(seed_value: int) -> void` (reseeds `rng` and `ctx.env.rng`, clears dim, effects, units, lights and buildings; the owner then builds its map and spawns units)
  - `func clear_effects() -> void`, `func mouse_ground() -> Vector2`
  - `func save_capture(file_name: String) -> void` (await it; writes `res://captures/<file_name>` at 2×), `func wait_frames(n: int) -> void` (await it), `func bench(label: String, seconds := 9.0) -> void` (await it; prints `bench[<label>] frames=… avg_ms=… avg_fps=… worst_ms=… min_fps=…`), `func quit() -> void`
  - `static func arg_value(args: PackedStringArray, key: String) -> String` (value of `key=value`, or `""`)
  - `_process` sets `ctx.lights.ambient = 1.0 - ctx.impact.dim_level() * 0.85`.

- [ ] **Step 1: Tag the starting point and run the baseline tests**

```bash
git tag kak-m1-start
bash tools/test.sh
```

Expected: last line `checks=217 failures=0`. The import step creates `.import` files for the ability icons and the pixel font added in the last session. Commit them on their own so later commits stay clean:

```bash
git status --short
git add assets/pixellab/icons assets/fonts
git commit -m "chore: add Godot import files for the ability icons and pixel font" -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

(`assets/pixellab/icons/candidates/` is git-ignored, so only the tracked icons' `.import` files are added. If `git status` shows other new files, stop and report them.)

- [ ] **Step 2: Write the capture comparison tools**

`tools/dev/compare_captures.py`:

```python
"""Mean absolute pixel difference between same-named PNGs in two folders (0-255 scale, averaged over RGB).
usage: python tools/dev/compare_captures.py <dir_a> <dir_b>"""
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageStat

a_dir, b_dir = Path(sys.argv[1]), Path(sys.argv[2])
worst = 0.0
count = 0
for a in sorted(a_dir.glob('*.png')):
    b = b_dir / a.name
    if not b.exists():
        print('missing', b)
        continue
    ia = Image.open(a).convert('RGB')
    ib = Image.open(b).convert('RGB')
    if ia.size != ib.size:
        print('size differs', a.name, ia.size, ib.size)
        continue
    diff = sum(ImageStat.Stat(ImageChops.difference(ia, ib)).mean) / 3.0
    worst = max(worst, diff)
    count += 1
    print('%-28s %.3f' % (a.name, diff))
print('files=%d worst_mean_diff=%.3f' % (count, worst))
```

`tools/dev/sandbox_baseline.sh`:

```bash
#!/usr/bin/env bash
# Capture the sandbox reference frames (idle, nova, judgement, cinder) into <out_dir> for before/after checks.
# usage: bash tools/dev/sandbox_baseline.sh captures/<name>
set -e
cd "$(dirname "$0")/../.."
OUT="$1"
rm -rf "$OUT"
mkdir -p "$OUT"
rm -f captures/idle.png captures/nova_*.png captures/judgement_*.png captures/cinder_*.png
bash tools/capture.sh --capture-idle
for key in nova judgement cinder; do
	bash tools/capture.sh --capture-all --only=$key
done
cp captures/idle.png captures/nova_*.png captures/judgement_*.png captures/cinder_*.png "$OUT/"
echo "frames: $(ls "$OUT" | wc -l)"
```

- [ ] **Step 3: Capture the sandbox twice before changing it (noise floor)**

```bash
bash tools/dev/sandbox_baseline.sh captures/m1_base_a
bash tools/dev/sandbox_baseline.sh captures/m1_base_b
python tools/dev/compare_captures.py captures/m1_base_a captures/m1_base_b
```

Expected: `frames: 28` twice, then `files=28 worst_mean_diff=<noise>`. Write down `<noise>`: hitstop runs on real time, so identical runs may differ slightly. Each capture run takes up to a minute.

- [ ] **Step 4: Create `src/game/battlefield.gd`**

```gdscript
class_name Battlefield
extends Node2D
## The shared world effects play in: iso ground plane, y-sorted world layer, overhead and distortion layers,
## camera with shake, positional sound, lights, destructible buildings, units, screen glow, impact post and
## screen flash, all wired into one FxContext. The VFX sandbox and the KAK game each add one as a child.

var ctx := FxContext.new()
## Seeds unit spawns and effect randomness; reseeded by reset().
var rng := RandomNumberGenerator.new()
var camera: CameraShake
## Transform Iso.BASIS: floors and ground previews added here are authored in ground units.
var ground_plane: Node2D
## CanvasLayer 5 for HUD controls (empty until the owner adds some).
var hud_layer: CanvasLayer

var _flash_rect: ColorRect
var _flash_tween: Tween


func _ready() -> void:
	ground_plane = Node2D.new()
	ground_plane.name = "GroundPlane"
	ground_plane.transform = Iso.BASIS
	ground_plane.z_index = -10
	add_child(ground_plane)

	var world := Node2D.new()
	world.name = "WorldLayer"
	world.y_sort_enabled = true
	add_child(world)

	# Dim only darkens the ground; buildings and enemies darken themselves via LightField.ambient
	# so effect light on them still reads in the dark.
	var dim_layer := Node2D.new()
	dim_layer.name = "DimLayer"
	dim_layer.z_index = -6
	add_child(dim_layer)

	var overhead_back := Node2D.new()
	overhead_back.name = "OverheadBackLayer"
	overhead_back.z_index = 8
	add_child(overhead_back)

	var overhead := Node2D.new()
	overhead.name = "OverheadLayer"
	overhead.z_index = 10
	add_child(overhead)

	var distort := Node2D.new()
	distort.name = "DistortLayer"
	distort.z_index = 20
	add_child(distort)

	camera = CameraShake.new()
	camera.name = "Camera"
	add_child(camera)
	camera.make_current()
	var listener := AudioListener2D.new()
	camera.add_child(listener)
	listener.make_current()

	var sfx := Sfx.new()
	sfx.name = "Sfx"
	add_child(sfx)

	var lights := LightField.new()
	lights.name = "Lights"
	add_child(lights)
	var env := EnvironmentField.new()
	env.name = "Environment"
	add_child(env)
	env.lights = lights
	env.world_parent = world
	env.fx_parent = overhead
	env.fx_back = overhead_back

	var field := EnemyField.new()
	field.env = env
	field.lights = lights
	field.name = "EnemyField"
	add_child(field)

	hud_layer = CanvasLayer.new()
	hud_layer.name = "HudLayer"
	hud_layer.layer = 5
	add_child(hud_layer)

	# Glow sits above the world and effects, below the impact post and flash.
	var glow_layer := CanvasLayer.new()
	glow_layer.layer = 2
	add_child(glow_layer)
	var glow := ColorRect.new()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	var glow_mat := ShaderMaterial.new()
	glow_mat.shader = preload("res://shaders/glow_post.gdshader")
	glow.material = glow_mat
	glow_layer.add_child(glow)

	var post_layer := CanvasLayer.new()
	post_layer.layer = 3
	add_child(post_layer)
	var impact := Impact.new()
	impact.name = "Impact"
	add_child(impact)
	impact.setup(post_layer, dim_layer, camera)

	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 4
	add_child(flash_layer)
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_layer.add_child(_flash_rect)

	ctx.field = field
	ctx.env = env
	ctx.lights = lights
	ctx.shake = camera
	ctx.sfx = sfx
	ctx.ground = ground_plane
	ctx.world = world
	ctx.overhead_back = overhead_back
	ctx.overhead = overhead
	ctx.impact = impact
	ctx.distort = distort
	ctx.rng = rng
	ctx.flash = flash


func _process(_delta: float) -> void:
	ctx.lights.ambient = 1.0 - ctx.impact.dim_level() * 0.85


## Full-screen flash of `color` that fades out over `seconds`.
func flash(color: Color, seconds: float) -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash_rect.color = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash_rect, "color:a", 0.0, seconds) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Reseed, lift the dim and clear effects, units, lights and buildings. The owner then builds its map and spawns
## its units (in that order, so spawns avoid the new buildings).
func reset(seed_value: int) -> void:
	rng.seed = seed_value
	ctx.impact.dim(0.0, 100.0)
	clear_effects()
	ctx.field.clear()
	ctx.lights.clear()
	ctx.env.clear()
	ctx.env.rng.seed = seed_value


## Free every effect node in the overhead and distortion layers.
func clear_effects() -> void:
	for layer in [ctx.overhead_back, ctx.overhead, ctx.distort]:
		for c in layer.get_children():
			c.queue_free()


## Ground point under the mouse.
func mouse_ground() -> Vector2:
	return Iso.screen_to_ground(get_global_mouse_position())


## Save the next drawn frame, scaled 2x with nearest filtering, to res://captures/<file_name>.
func save_capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var dir := ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join(file_name)
	img.save_png(path)
	print("captured ", path)


func wait_frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## Time frames for `seconds` of real time and print one bench line.
func bench(label: String, seconds := 9.0) -> void:
	var worst := 0.0
	var total := 0.0
	var frames := 0
	var last := Time.get_ticks_usec()
	var start := last
	while Time.get_ticks_usec() - start < int(seconds * 1_000_000.0):
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		var ms := (now - last) / 1000.0
		last = now
		if frames > 2:
			worst = maxf(worst, ms)
		total += ms
		frames += 1
	print("bench[%s] frames=%d avg_ms=%.2f avg_fps=%.1f worst_ms=%.2f min_fps=%.1f" % [
		label, frames, total / frames, 1000.0 * frames / total, worst, 1000.0 / worst])


## Stop voices and effects before quitting so the audio server does not leak playbacks.
func quit() -> void:
	ctx.sfx.stop_all("")
	clear_effects()
	await wait_frames(3)
	# Stopped playbacks are released by the audio thread; give it real time (fixed-fps frames can be ~1 ms).
	OS.delay_msec(150)
	await wait_frames(1)
	Sfx.clear_cache()
	get_tree().quit()


## Value of a `key=value` command-line argument, or "".
static func arg_value(args: PackedStringArray, key: String) -> String:
	for a in args:
		if a.begins_with(key + "="):
			return a.substr(key.length() + 1)
	return ""
```

- [ ] **Step 5: Rebuild the sandbox on top of the Battlefield**

Edit `src/sandbox/sandbox.gd` as follows. Everything not mentioned (the `SETS`, `EFFECTS`, `CAPTURES` tables, `_has_any_flag`, `_visible_effects`, `cast`, `_cast_entry`, `_focus_camera`, `_on_fx_done`, `_mouse_ground`, `_draw_drag_preview`, `_update_hud`) stays exactly as it is.

5a. Replace the first two lines (the `extends` line and the `## VFX sandbox: …` doc line) with:

```gdscript
extends Node2D
## VFX sandbox: iso floor, dummy enemies, effect picker, capture and bench modes. The world itself (layers, camera,
## sound, lights, buildings, units, glow, impact, flash) is the shared Battlefield.
```

5b. Replace the whole variable block, from `var ctx := FxContext.new()` down to and including `var _follow_slack := 0.0`, with:

```gdscript
var ctx: FxContext
var selected := 0
var set_index := 0
var _bf: Battlefield
var _tiles: Node2D

var _field: EnemyField
var _camera: CameraShake
var _hud: Label
var _drag_preview: Node2D
var _press_ground := Vector2.ZERO
var _pressing := false
var _rng: RandomNumberGenerator
var _active_fx: Array[FxTimeline] = []
var _home_position := Vector2.ZERO
var _camera_tween: Tween
## Effect the camera keeps following (entries with "follow"), and how far above its ground point to look.
var _follow_fx: FxTimeline
var _follow_up := 0.0
## 0..1: ramps up once the follow camera has centred on the cast, letting the effect roam inside FOLLOW_SLACK.
var _follow_slack := 0.0
```

5c. Replace `_ready()` with (only `_arg_value` → `Battlefield.arg_value` changes):

```gdscript
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("07080d"))
	_build_world()
	var args := OS.get_cmdline_user_args()
	var seed_value := 7 if _has_any_flag(args) else Time.get_ticks_usec()
	if Battlefield.arg_value(args, "--set") != "":
		set_index = int(Battlefield.arg_value(args, "--set"))
	var only := Battlefield.arg_value(args, "--only")
	if only != "":
		for e in EFFECTS:
			if e.key == only:
				set_index = e.set
	_reset_world(seed_value)
	_update_hud()
	await FxParts.prewarm(ctx.distort)
	if "--capture-idle" in args:
		_capture_idle()
	elif "--capture-all" in args:
		_capture_all(Battlefield.arg_value(args, "--only"))
	elif "--bench" in args:
		_bench(Battlefield.arg_value(args, "--only"))
```

5d. Delete the whole `func _arg_value(...)` function.

5e. Replace the whole `func _build_world() -> void:` function with:

```gdscript
func _build_world() -> void:
	_bf = Battlefield.new()
	_bf.name = "Battlefield"
	add_child(_bf)
	ctx = _bf.ctx
	_field = ctx.field
	_camera = _bf.camera
	_rng = _bf.rng

	_tiles = Node2D.new()
	_tiles.name = "Tiles"
	_tiles.set_script(preload("res://src/sandbox/ground_tiles.gd"))
	_bf.ground_plane.add_child(_tiles)

	_drag_preview = Node2D.new()
	_drag_preview.name = "DragPreview"
	_drag_preview.z_index = 5
	_drag_preview.draw.connect(_draw_drag_preview)
	_bf.ground_plane.add_child(_drag_preview)

	_hud = Label.new()
	_hud.position = Vector2(6, 4)
	_hud.add_theme_font_size_override("font_size", 8)
	_hud.add_theme_color_override("font_color", Color("cfd8e8"))
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 2)
	_bf.hud_layer.add_child(_hud)
```

5f. Delete the whole `func _screen_flash(...)` function.

5g. Replace the whole `func _reset_world(seed_value: int) -> void:` function with:

```gdscript
func _reset_world(seed_value: int) -> void:
	var theme: String = SETS[set_index].theme
	RenderingServer.set_default_clear_color(SETS[set_index].clear)
	_tiles.theme = theme
	_field.look = DummyEnemy.Look.ORC if theme == "fantasy" else DummyEnemy.Look.TROOPER
	ctx.impact.dim_scale = SETS[set_index].dim_scale
	_active_fx.clear()
	_follow_fx = null
	if _camera_tween:
		_camera_tween.kill()
	_camera.zoom = Vector2.ONE
	_bf.reset(seed_value)
	if theme == "fantasy":
		ctx.env.build_castle()
	else:
		ctx.env.build_city()
	_field.spawn(ENEMY_COUNT, ctx.world, _rng)
```

5h. In `_unhandled_input`, change the `KEY_ESCAPE:` branch body from `_quit()` to `_bf.quit()`.

5i. In `_process`, delete the last line `ctx.lights.ambient = 1.0 - ctx.impact.dim_level() * 0.85` (the Battlefield does it now).

5j. Replace everything from the line `## Stop voices before quitting so the audio server does not leak playbacks.` to the end of the file with:

```gdscript
# --- Capture / bench -------------------------------------------------------

func _capture_idle() -> void:
	await _bf.wait_frames(30)
	await _bf.save_capture("idle.png")
	await _bf.quit()


func _capture_all(only: String) -> void:
	for entry in EFFECTS:
		var key: String = entry.key
		if only != "" and only != key:
			continue
		if not ResourceLoader.exists(entry.path) or not CAPTURES.has(key):
			print("skip (not built): ", key)
			continue
		var plan: Dictionary = CAPTURES[key]
		set_index = entry.set
		_reset_world(7)
		_hud.text = entry.name
		await _bf.wait_frames(10)
		var extra := {}
		if plan.has("dir"):
			extra["dir"] = plan.dir
		var fx := _cast_entry(entry, plan.target, extra)
		for time in plan.times:
			while is_instance_valid(fx) and fx.t < time:
				await get_tree().process_frame
			await _bf.save_capture("%s_%04d.png" % [key, int(time * 1000)])
		while is_instance_valid(fx):
			await get_tree().process_frame
	await _bf.quit()


func _bench(only: String) -> void:
	await _bf.wait_frames(10)
	var spots := [Vector2(-3, -3), Vector2(3, -3), Vector2(-3, 3), Vector2(-5, 3)]
	var list := _visible_effects()
	for i in list.size():
		if only != "" and only != list[i].key:
			continue
		if ResourceLoader.exists(list[i].path):
			_cast_entry(list[i], spots[i % spots.size()], {"dir": Vector2(1, 0)})
	await _bf.bench(only if only != "" else "all")
	await _bf.quit()
```

- [ ] **Step 6: Check nothing old is left and the tests still pass**

```bash
grep -nE "_quit\(|_save_capture|_wait_frames|_screen_flash|_arg_value|_capture_dir|_ground_plane|_flash_rect|_glow" src/sandbox/sandbox.gd
bash tools/test.sh
```

Expected: the grep prints nothing; the tests end with `checks=217 failures=0`.

- [ ] **Step 7: Capture after the refactor and compare**

```bash
bash tools/dev/sandbox_baseline.sh captures/m1_task1
python tools/dev/compare_captures.py captures/m1_base_a captures/m1_task1
```

Expected: `frames: 28`, then `files=28` and `worst_mean_diff` no more than the Step 3 noise value + 0.5. If it is higher, open the worst pair of PNGs side by side, find what differs (missing glow, layer order, HUD) and fix the refactor before continuing.

- [ ] **Step 8: Commit**

```bash
git add src/game/battlefield.gd src/game/battlefield.gd.uid src/sandbox/sandbox.gd tools/dev/compare_captures.py tools/dev/sandbox_baseline.sh
git commit -m "refactor: move the sandbox world into a shared Battlefield" -m "The ground plane, draw layers, camera, sound, lights, buildings, units, glow, impact post, screen flash and FxContext wiring now live in src/game/battlefield.gd so the KAK game can reuse them. The sandbox adds one Battlefield and keeps its effect list, floor, HUD, camera push-in and capture/bench modes; before/after captures match." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---
### Task 2: Building roles, walkability, damage filter and destroy signal

**Files:**
- Modify: `src/environment/structure.gd`, `src/environment/environment_field.gd`, `tests/run_all.gd`
- Test: `tests/test_structure_roles.gd`

**Interfaces:**
- Consumes: existing `Structure` and `EnvironmentField`.
- Produces on `Structure`:
  - `signal broken(s: Structure)`: emitted once, at the end of `destroy()`, whatever the cause.
  - `var role := &""`: game role tag (`&"house"`, `&"wall"`, `&"tower"`, `&"gate"`, `&"bridge"`, `&"temple"`, `&"barracks"`, `&"market"`, `&"farm"`, `&"citadel"`, `&"decor"`; empty in the sandbox).
  - `var walkable := false`: units pass over it while it stands.
  - `var damage_filter := Callable()`: when valid, `damage(amount, source, kind)` calls `damage_filter.call(self, amount, source, kind)` and returns without touching `hp` (the Citadel owns its parts' health).
  - `func mark_hit(share: float, damage_kind: StringName) -> void`: hit reaction without health (scorch `+share*0.9`, or frost `+share*3` for `&"ice"`, and a shake).
  - `func crack() -> void` (adds wall cracks once), `func ignite(offset: Vector2, seconds: float) -> void` (fire + smoke at `position + offset`), `func dust_burst(amount: float) -> void`, `func drop_banner() -> void` (the keep's banner falls and fades over `BANNER_FALL_TIME` = 1.0 s, then is freed).
- Produces on `EnvironmentField`:
  - `signal structure_destroyed(s: Structure)`.
  - `func add_structure(rect: Rect2, height: float, kind: Structure.Kind, role := &"") -> Structure`.
  - `blocked(g, margin)` ignores walkable structures and uses a spatial index (`CELL := 2.0`, margins up to `MAX_MARGIN := 0.5`; larger margins fall back to a full scan).
- The sandbox must stay pixel-identical: the random-number calls in `damage()` and `destroy()` keep their order.

- [ ] **Step 1: Write the failing test**

Create `tests/test_structure_roles.gd`:

```gdscript
extends RefCounted
## Structure roles, walkability, the damage filter, the destroy signal and the stage helpers the Citadel uses.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var down: Array = []
	env.structure_destroyed.connect(func(s: Structure) -> void: down.append(s))

	var house := env.add_structure(Rect2(0, 0, 1, 1), 24.0, Structure.Kind.HOUSE, &"house")
	var plain := env.add_structure(Rect2(3, 0, 1, 1), 24.0, Structure.Kind.HOUSE)
	t.check(house.role == &"house", "role tag stored")
	t.check(plain.role == &"", "role defaults to empty")
	env.damage_radius(Vector2(0.5, 0.5), 0.6, 99999.0, &"nova")
	t.check(down == [house], "structure_destroyed fires for the destroyed house (%s)" % [down])
	house.destroy(Vector2.ZERO, &"nova")
	t.check(down.size() == 1, "a second destroy does not signal again")

	# Walkable structures never block units.
	t.check(env.blocked(Vector2(3.5, 0.5)), "a standing house blocks")
	plain.walkable = true
	t.check(not env.blocked(Vector2(3.5, 0.5)), "a walkable structure does not block")

	# A damage filter owns the hp: it receives every hit and the building's own hp stays put.
	var wall := env.add_structure(Rect2(-4, 0, 2, 0.6), 34.0, Structure.Kind.CASTLE_WALL)
	var hits: Array = []
	wall.damage_filter = func(s: Structure, amount: float, source: Vector2, kind: StringName) -> void:
		hits.append([s, amount, source, kind])
	wall.damage(500.0, Vector2(-3, 1), &"stone")
	t.check(hits.size() == 1 and hits[0] == [wall, 500.0, Vector2(-3, 1), &"stone"], "filter receives the hit (%s)" % [hits])
	t.check(not wall.destroyed and wall.hp == wall.max_hp, "a filtered hit leaves hp to the filter")

	# Hit reactions and stage helpers work without touching hp.
	wall.mark_hit(0.5, &"nova")
	t.near(wall.scorch, 0.45, 0.001, "mark_hit scorches by share")
	wall.mark_hit(0.2, &"ice")
	t.near(wall.frost, 0.6, 0.001, "mark_hit frosts on ice")
	t.check(wall._cracks.is_empty(), "no cracks before crack()")
	wall.crack()
	var n := wall._cracks.size()
	wall.crack()
	t.check(n > 0 and wall._cracks.size() == n, "crack() adds cracks once")
	wall.ignite(Vector2(0, -10), 1.0)
	wall.dust_burst(1.0)
	wall.drop_banner()
	t.check(wall.hp == wall.max_hp and not wall.destroyed, "stage helpers are safe headless and leave hp alone")

	# The keep's banner can be dropped: it falls, fades and is removed.
	var keep := env.add_structure(Rect2(10, 10, 2, 2), 96.0, Structure.Kind.KEEP)
	t.root.add_child(keep)
	t.check(is_instance_valid(keep._banner), "the keep builds its banner when it enters the tree")
	keep.drop_banner()
	keep._process(0.5)
	var alpha := keep._banner.modulate.a
	keep._process(0.6)
	t.check(alpha < 1.0 and keep._banner.is_queued_for_deletion(), "a dropped banner fades and is removed")
	keep.free()

	# Plain damage works as before: cracks under 65% and destroys at 0.
	var hut := env.add_structure(Rect2(20, 0, 1, 1), 22.0, Structure.Kind.HOUSE)
	hut.damage(hut.max_hp * 0.5, Vector2(19, 0), &"orbital")
	t.check(not hut.destroyed and not hut._cracks.is_empty(), "half damage cracks without destroying")
	hut.damage(hut.max_hp, Vector2(19, 0), &"orbital")
	t.check(hut.destroyed and down.has(hut), "full damage destroys and signals")
	env.clear()
	env.free()

	# The spatial index answers blocked() exactly like a full scan.
	var castle := EnvironmentField.new()
	castle.build_castle()
	var mismatches := 0
	for i in 400:
		var p := Vector2(fposmod(i * 0.731, 14.0) - 7.0, fposmod(i * 0.377, 14.0) - 7.0)
		for margin in [0.15, 0.3]:
			var scan := false
			for s in castle.structures():
				scan = scan or (not s.destroyed and not s.walkable and s.contains(p, margin))
			if scan != castle.blocked(p, margin):
				mismatches += 1
	t.check(mismatches == 0, "indexed blocked() matches a full scan (%d mismatches)" % mismatches)
	castle.clear()
	castle.free()
```

Register it: in `tests/run_all.gd`, add `"res://tests/test_structure_roles.gd",` as the last entry of `SUITES`.

- [ ] **Step 2: Run the tests to see the new suite fail**

Run: `bash tools/test.sh`
Expected: parse errors for the missing members, `FAIL: suite failed to load: res://tests/test_structure_roles.gd`, and `checks=218 failures=1`.

- [ ] **Step 3: Add roles, walkability, the filter and the signal to `Structure`**

Edit `src/environment/structure.gd`:

3a. Add the signal between the class doc comment and `enum Kind`. Find:

```gdscript
## rubble with dust and debris, reacting to the damage type (blast, beam cut, gravity).

enum Kind { TOWER, BLOCK, WALL, CRATES, KEEP, CASTLE_WALL, HOUSE, TORCH }
```

Replace with:

```gdscript
## rubble with dust and debris, reacting to the damage type (blast, beam cut, gravity).

## Emitted once, when the building is destroyed by any cause.
signal broken(s: Structure)

enum Kind { TOWER, BLOCK, WALL, CRATES, KEEP, CASTLE_WALL, HOUSE, TORCH }
```

3b. After the line `const TORCH_LIGHT := Color(1.0, 0.55, 0.22)` add:

```gdscript
## Seconds a dropped banner takes to fall and fade.
const BANNER_FALL_TIME := 1.0
```

3c. After the line `var rng := RandomNumberGenerator.new()` add:

```gdscript
## Game role for rules and scoring (&"house", &"citadel", ...); empty in the sandbox.
var role := &""
## Units walk over it while it stands (gates, the bridge, fields).
var walkable := false
## Optional owner of this building's health: func(s: Structure, amount: float, source: Vector2, kind: StringName).
## When set, damage() hands every hit to it instead of lowering hp (the Citadel's damage budget).
var damage_filter := Callable()
```

3d. After the line `var _dirty := true` add:

```gdscript
## Seconds since drop_banner() (-1 = the banner still hangs).
var _banner_fall := -1.0
```

3e. Replace the whole `func damage(amount: float, source: Vector2, damage_kind: StringName) -> void:` function with:

```gdscript
func damage(amount: float, source: Vector2, damage_kind: StringName) -> void:
	if destroyed:
		return
	if damage_filter.is_valid():
		# Someone else (the Citadel) owns this building's health and decides when it falls.
		damage_filter.call(self, amount, source, damage_kind)
		return
	hp -= amount
	mark_hit(amount / max_hp, damage_kind)
	if hp <= 0.0:
		destroy(source, damage_kind)
		return
	if hp < max_hp * 0.65:
		crack()
	for w in _windows:
		if rng.randf() < 0.3:
			w[3] = false
	if (damage_kind == &"nova" or damage_kind == &"orbital") and hp < max_hp * 0.7 and not _burning:
		_burning = true
		_spawn_fire(Vector2(0, -height), 3.5)


## Hit reaction without health: scorch (or frost, for ice) by `share` of the building, and a shake.
func mark_hit(share: float, damage_kind: StringName) -> void:
	if destroyed:
		return
	_dirty = true
	if damage_kind == &"ice":
		frost = minf(frost + share * 3.0, 1.0)
	else:
		scorch = minf(scorch + share * 0.9, 1.0)
	_shake = maxf(_shake, 2.5)


## Cracks up the visible walls (once).
func crack() -> void:
	if destroyed or not _cracks.is_empty():
		return
	_build_cracks()
	_dirty = true
```

3f. After the whole `func shake(amount: float) -> void:` function add:

```gdscript
## Fire and smoke on the building for `seconds`; `offset` is in px from its front corner (its position).
func ignite(offset: Vector2, seconds: float) -> void:
	_spawn_fire(offset, seconds)


func dust_burst(amount: float) -> void:
	_spawn_dust(amount)


## The banner comes loose and slides down the wall, fading (the Citadel at 20%).
func drop_banner() -> void:
	if is_instance_valid(_banner) and _banner_fall < 0.0:
		_banner_fall = 0.0
```

3g. Replace the whole `func destroy(source: Vector2, damage_kind: StringName) -> void:` function with the two functions below (the body is the same; only the tail moves into `_fall_apart` and the signal is added):

```gdscript
func destroy(source: Vector2, damage_kind: StringName) -> void:
	if destroyed:
		return
	destroyed = true
	_dirty = true
	hp = 0.0
	_destroy_kind = damage_kind
	if damage_kind != &"ice":
		scorch = maxf(scorch, 0.6)
	for w in _windows:
		w[3] = false
	if light_id != 0 and lights != null:
		lights.remove(light_id)
		light_id = 0
	if is_instance_valid(_glow):
		_glow.queue_free()
	_fall_apart(source, damage_kind)
	broken.emit(self)


## How the building comes down: a laser slices the top off; anything else collapses into rubble with debris,
## dust and, for hot damage, fire.
func _fall_apart(source: Vector2, damage_kind: StringName) -> void:
	_build_rubble()
	if damage_kind == &"laser" and max_height > 20.0:
		# Cut clean through: the top slides off and falls, a molten stump remains.
		var cut := clampf(max_height * 0.35, 10.0, 28.0)
		var away := (Iso.ground_to_screen(center()) - Iso.ground_to_screen(source)).normalized()
		_top_piece = {"h0": cut, "h1": max_height, "off": Vector2.ZERO, "vel": away * 55.0, "fall": 0.0, "t": 0.0}
		height = cut
		_molten = 1.0
		_spawn_sparks(Vector2(0, -cut), 26)
	else:
		_collapse = 0.0
		_collapse_from = height
		var toward := damage_kind == &"gravity"
		_spawn_debris(source, toward)
		_spawn_dust(1.0)
		if not damage_kind in [&"gravity", &"ice", &"water", &"wind", &"stone"]:
			_spawn_fire(Vector2.ZERO, 3.0)
```

3h. In `_process`, find the banner block:

```gdscript
	if is_instance_valid(_banner):
		_banner.visible = not destroyed
		_banner.position = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).round() * _shake if _shake > 0.2 else Vector2.ZERO
		_banner.queue_redraw()
```

Replace with:

```gdscript
	if is_instance_valid(_banner):
		_banner.visible = not destroyed
		if _banner_fall >= 0.0:
			_banner_fall += delta
			_banner.position = Vector2(0, roundf(90.0 * _banner_fall * _banner_fall))
			_banner.modulate.a = clampf(1.0 - _banner_fall / BANNER_FALL_TIME, 0.0, 1.0)
			if _banner_fall >= BANNER_FALL_TIME:
				_banner.queue_free()
		else:
			_banner.position = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).round() * _shake if _shake > 0.2 else Vector2.ZERO
		_banner.queue_redraw()
```

- [ ] **Step 4: Replace `src/environment/environment_field.gd`**

Write the whole file (layouts, damage queries and `shake_radius` are unchanged; new: the signal, `role`, the index, walkable-aware `blocked`):

```gdscript
class_name EnvironmentField
extends Node
## Registry of destructible structures with ground-space damage queries, like EnemyField for props.

## A structure was destroyed (any cause); the game's rules count these.
signal structure_destroyed(s: Structure)

## Spatial index cell (ground units) for blocked(); query margins up to MAX_MARGIN use it.
const CELL := 2.0
const MAX_MARGIN := 0.5

var lights: LightField
## Y-sorted world layer structures are added to (null in headless tests).
var world_parent: Node
var fx_parent: Node
var fx_back: Node
var rng := RandomNumberGenerator.new()

var _structures: Array[Structure] = []
## Vector2i cell -> structures whose footprint, grown by MAX_MARGIN, touches that cell.
var _grid := {}


func add_structure(rect: Rect2, height: float, kind: Structure.Kind, role := &"") -> Structure:
	var s := Structure.new().setup(rect, height, kind, rng.randi())
	s.role = role
	s.lights = lights
	s.fx_parent = fx_parent
	s.fx_back = fx_back
	s.broken.connect(_on_structure_broken)
	if kind == Structure.Kind.TORCH and lights != null:
		s.light_id = lights.add_static(rect.get_center(), 2.4, Structure.TORCH_LIGHT, 0.55, 1.0)
	_structures.append(s)
	_index(s)
	if world_parent != null:
		world_parent.add_child(s)
	return s


## A small ruined city block around the 14x14 sandbox, leaving the middle open for enemies.
func build_city() -> void:
	var T := Structure.Kind.TOWER
	var B := Structure.Kind.BLOCK
	var W := Structure.Kind.WALL
	var C := Structure.Kind.CRATES
	var layout := [
		[Rect2(-6.4, -6.4, 1.6, 1.6), 92.0, T], [Rect2(4.6, -6.3, 1.8, 1.4), 84.0, T],
		[Rect2(-6.3, 4.4, 1.5, 1.9), 78.0, T], [Rect2(4.9, 4.9, 1.4, 1.4), 30.0, B],
		[Rect2(-3.6, -6.0, 2.2, 1.2), 46.0, B], [Rect2(0.8, -6.1, 2.0, 1.2), 40.0, B],
		[Rect2(-6.2, -2.2, 1.2, 2.4), 44.0, B], [Rect2(5.3, -1.6, 1.2, 2.2), 50.0, B],
		[Rect2(-2.2, 5.0, 2.4, 1.2), 42.0, B], [Rect2(2.4, 5.2, 1.8, 1.2), 36.0, B],
		[Rect2(-3.4, -3.0, 1.8, 0.35), 14.0, W], [Rect2(2.0, 1.6, 0.35, 1.8), 14.0, W],
		[Rect2(1.8, -3.2, 1.6, 0.35), 14.0, W], [Rect2(-3.2, 1.8, 0.35, 1.6), 14.0, W],
		[Rect2(0.6, -1.8, 0.6, 0.6), 12.0, C], [Rect2(-1.9, 0.9, 0.7, 0.5), 10.0, C],
		[Rect2(3.4, 0.4, 0.6, 0.6), 12.0, C], [Rect2(-4.4, -0.6, 0.6, 0.6), 11.0, C],
	]
	for item in layout:
		add_structure(item[0], item[1], item[2])


## Castle courtyard: keeps on the corners, crenellated walls along the back edges, timber houses,
## barricades and torches, leaving the middle open for the horde.
func build_castle() -> void:
	var K := Structure.Kind.KEEP
	var W := Structure.Kind.CASTLE_WALL
	var H := Structure.Kind.HOUSE
	var T := Structure.Kind.TORCH
	var C := Structure.Kind.CRATES
	var layout := [
		[Rect2(-6.6, -6.6, 1.8, 1.8), 96.0, K], [Rect2(4.8, -6.6, 1.8, 1.8), 88.0, K],
		[Rect2(-6.6, 4.9, 1.6, 1.6), 80.0, K],
		[Rect2(-4.6, -6.5, 9.2, 0.7), 34.0, W], [Rect2(-6.5, -4.6, 0.7, 9.3), 34.0, W],
		[Rect2(-3.0, -4.9, 1.8, 1.2), 24.0, H], [Rect2(1.0, -5.0, 1.4, 1.4), 22.0, H],
		[Rect2(-5.2, 1.4, 1.2, 1.8), 24.0, H], [Rect2(4.8, 2.0, 1.4, 1.6), 22.0, H],
		[Rect2(2.2, 4.8, 1.8, 1.2), 22.0, H],
		[Rect2(-2.6, 2.6, 1.4, 0.4), 12.0, C], [Rect2(2.4, -1.8, 0.5, 1.2), 12.0, C],
		[Rect2(-3.4, -2.2, 0.5, 0.5), 10.0, C],
		[Rect2(-4.2, -5.6, 0.2, 0.2), 16.0, T], [Rect2(3.6, -5.6, 0.2, 0.2), 16.0, T],
		[Rect2(-5.6, -1.2, 0.2, 0.2), 16.0, T], [Rect2(-5.6, 3.4, 0.2, 0.2), 16.0, T],
		[Rect2(0.2, 3.2, 0.2, 0.2), 16.0, T], [Rect2(4.2, -0.6, 0.2, 0.2), 16.0, T],
	]
	for item in layout:
		add_structure(item[0], item[1], item[2])


func clear() -> void:
	for s in _structures:
		if not is_instance_valid(s):
			continue
		if s.is_inside_tree():
			s.queue_free()
		else:
			s.free()
	_structures.clear()
	_grid.clear()


func structures() -> Array[Structure]:
	return _structures


## True when a standing structure units cannot walk through occupies the ground point (rubble, gates, the bridge
## and fields are walkable). Only the structures indexed in g's cell are checked.
func blocked(g: Vector2, margin := 0.15) -> bool:
	var candidates: Array = _structures if margin > MAX_MARGIN else _grid.get(_cell(g), [])
	for s in candidates:
		if is_instance_valid(s) and not s.destroyed and not s.walkable and s.contains(g, margin):
			return true
	return false


func damage_radius(center: Vector2, radius: float, amount: float, kind: StringName) -> void:
	for s in _structures:
		if is_instance_valid(s) and not s.destroyed and s.distance_to(center) <= radius:
			s.damage(amount, center, kind)


## Anything the lane band [along_min, along_max] x [-half_width, half_width] overlaps is cut down.
func damage_lane(origin: Vector2, dir: Vector2, half_width: float, along_min: float, along_max: float, kind: StringName) -> void:
	var side := dir.orthogonal()
	for s in _structures:
		if not is_instance_valid(s) or s.destroyed:
			continue
		var half := s.footprint.size * 0.5
		var rel := s.center() - origin
		var along := rel.dot(dir)
		var across := rel.dot(side)
		var ext_along := absf(half.x * dir.x) + absf(half.y * dir.y)
		var ext_side := absf(half.x * side.x) + absf(half.y * side.y)
		if along + ext_along >= along_min and along - ext_along <= along_max and absf(across) <= half_width + ext_side:
			s.damage(99999.0, s.center() - dir, kind)


func shake_radius(center: Vector2, radius: float, amount: float) -> void:
	for s in _structures:
		if is_instance_valid(s) and not s.destroyed and s.distance_to(center) <= radius:
			s.shake(amount)


func _on_structure_broken(s: Structure) -> void:
	structure_destroyed.emit(s)


func _cell(g: Vector2) -> Vector2i:
	return Vector2i(floori(g.x / CELL), floori(g.y / CELL))


func _index(s: Structure) -> void:
	var r := s.footprint.grow(MAX_MARGIN)
	var c0 := _cell(r.position)
	var c1 := _cell(r.end)
	for y in range(c0.y, c1.y + 1):
		for x in range(c0.x, c1.x + 1):
			var key := Vector2i(x, y)
			if not _grid.has(key):
				_grid[key] = []
			_grid[key].append(s)
```

- [ ] **Step 5: Run the tests**

Run: `bash tools/test.sh`
Expected: `checks=235 failures=0`.

- [ ] **Step 6: Check the sandbox is unchanged**

`damage()` and `destroy()` were reorganised; their random-number calls must keep the same order.

```bash
bash tools/dev/sandbox_baseline.sh captures/m1_task2
python tools/dev/compare_captures.py captures/m1_base_a captures/m1_task2
```

Expected: `files=28` and `worst_mean_diff` no more than the Task 1 noise value + 0.5.

- [ ] **Step 7: Commit**

```bash
git add src/environment/structure.gd src/environment/environment_field.gd tests/test_structure_roles.gd tests/test_structure_roles.gd.uid tests/run_all.gd
git commit -m "feat: building roles, walkability, damage filter and destroy signal" -m "Structures get a role tag, a walkable flag, an optional damage filter that owns their health, a broken signal and stage helpers (mark_hit, crack, ignite, dust_burst, drop_banner). EnvironmentField forwards destroys as structure_destroyed, takes a role on add, and answers blocked() from a spatial index that skips walkable buildings." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 3: The Aldermere building kinds

**Files:**
- Modify: `src/environment/structure.gd`, `tests/run_all.gd`
- Create: `tools/dev/preview_kinds.gd`
- Test: `tests/test_building_kinds.gd`

**Interfaces:**
- Consumes: Task 2's `Structure` (`walkable`, `crack()`, `_fall_apart()`).
- Produces:
  - `Structure.Kind` gains, in this order after `TORCH`: `TEMPLE, BARRACKS, MARKET_STALL, GATE, BRIDGE, FARM_FIELD, TREE` (existing values keep their numbers).
  - Health: TEMPLE 200, BARRACKS 150, MARKET_STALL 25, GATE 120, BRIDGE 140, FARM_FIELD 20, TREE 30.
  - `const WALKABLE := [Kind.GATE, Kind.BRIDGE, Kind.FARM_FIELD]`; `setup()` sets `walkable = k in WALKABLE`.
  - Farm fields burn flat when destroyed (no rubble or collapse; fully charred, or iced over by `&"ice"`); trees are felled to a stump with leaf rubble (no collapse, never laser-sliced); fields and trees never crack.
  - Drawing in the current pixel-box style: temple (limestone, verdigris roof, gold sun, door), barracks (grey stone, terracotta roof, red shields, door), market stall (counter + striped canopy), gate (masonry, crenellations, arch with raised portcullis on its long face), bridge (planks and rails), farm field (wheat with furrows), tree (trunk and round canopy). The Citadel's parts and the barns reuse `KEEP`, `CASTLE_WALL` and `HOUSE`.

- [ ] **Step 1: Write the failing test**

Create `tests/test_building_kinds.gd`:

```gdscript
extends RefCounted
## The Aldermere building kinds: health, walkability, and how fields and trees come down.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var kinds := [Structure.Kind.TEMPLE, Structure.Kind.BARRACKS, Structure.Kind.MARKET_STALL, Structure.Kind.GATE,
		Structure.Kind.BRIDGE, Structure.Kind.FARM_FIELD, Structure.Kind.TREE]
	var ok := true
	for k in kinds:
		var s := env.add_structure(Rect2(k * 4, 30, 1, 1), 20.0, k)
		ok = ok and s.max_hp > 0.0 and s.hp == s.max_hp
	t.check(ok, "every new kind has health")

	var gate := env.add_structure(Rect2(0, 0, 2.8, 1.0), 40.0, Structure.Kind.GATE)
	var bridge := env.add_structure(Rect2(0, 5, 2.0, 2.4), 6.0, Structure.Kind.BRIDGE)
	var field := env.add_structure(Rect2(0, 10, 2.6, 1.8), 3.0, Structure.Kind.FARM_FIELD)
	var temple := env.add_structure(Rect2(10, 0, 2.7, 3.1), 56.0, Structure.Kind.TEMPLE)
	var stall := env.add_structure(Rect2(10, 5, 0.9, 0.7), 10.0, Structure.Kind.MARKET_STALL)
	t.check(gate.walkable and bridge.walkable and field.walkable, "gate, bridge and field are walkable")
	t.check(not temple.walkable and not stall.walkable, "temple and stall are not")
	t.check(not env.blocked(Vector2(1.4, 0.5)) and not env.blocked(Vector2(1, 6.2)), "units pass the gate and the bridge")
	t.check(env.blocked(Vector2(11.3, 1.5)) and env.blocked(Vector2(10.45, 5.35)), "units walk round the temple and stalls")

	# Fields burn flat: no rubble, no collapse, fully charred.
	field.destroy(Vector2(1, 11), &"cinder")
	t.check(field.destroyed and field._rubble.is_empty() and field._collapse < 0.0, "a field burns flat without rubble")
	t.near(field.scorch, 1.0, 0.001, "a burnt field is fully charred")
	var frozen := env.add_structure(Rect2(4, 10, 2.6, 1.8), 3.0, Structure.Kind.FARM_FIELD)
	frozen.destroy(Vector2(5, 11), &"ice")
	t.near(frozen.frost, 1.0, 0.001, "a frozen field is iced over")

	# Trees are felled to a stump among leaves: no cracks, no collapse, and a laser does not slice them.
	var tree := env.add_structure(Rect2(20, 0, 0.7, 0.7), 26.0, Structure.Kind.TREE)
	tree.damage(tree.max_hp * 0.5, Vector2(19, 0), &"fire")
	t.check(tree._cracks.is_empty(), "trees do not crack")
	tree.destroy(Vector2(19, 0), &"laser")
	t.check(tree.destroyed and not tree._rubble.is_empty() and tree._top_piece.is_empty() and tree._collapse < 0.0,
		"a tree is felled into leaves, not sliced or collapsed")

	# Big buildings still collapse into rubble.
	temple.destroy(Vector2(9, 0), &"stone")
	t.check(temple._collapse == 0.0 and not temple._rubble.is_empty(), "the temple collapses into rubble")
	t.check(Structure.WALKABLE.size() == 3, "three walkable kinds")
	env.clear()
	env.free()
```

Register it: add `"res://tests/test_building_kinds.gd",` as the last entry of `SUITES` in `tests/run_all.gd`.

- [ ] **Step 2: Run the tests to see the new suite fail**

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_building_kinds.gd` and `checks=236 failures=1`.

- [ ] **Step 3: Add the kinds, their rules and their drawing**

Edit `src/environment/structure.gd`:

3a. Replace the line `enum Kind { TOWER, BLOCK, WALL, CRATES, KEEP, CASTLE_WALL, HOUSE, TORCH }` with:

```gdscript
enum Kind {
	TOWER, BLOCK, WALL, CRATES, KEEP, CASTLE_WALL, HOUSE, TORCH,
	TEMPLE, BARRACKS, MARKET_STALL, GATE, BRIDGE, FARM_FIELD, TREE,
}
```

3b. After the line `const BANNER_FALL_TIME := 1.0` add:

```gdscript
## Kinds with lit windows; the fantasy ones get framed windows (houses) or arrow slits (keeps).
const WINDOWED := [Kind.TOWER, Kind.BLOCK, Kind.KEEP, Kind.HOUSE, Kind.TEMPLE, Kind.BARRACKS]
const FANTASY_WINDOWS := [Kind.KEEP, Kind.HOUSE, Kind.TEMPLE, Kind.BARRACKS]
## Stone kinds that show mortar courses.
const MASONRY := [Kind.KEEP, Kind.CASTLE_WALL, Kind.GATE, Kind.TEMPLE, Kind.BARRACKS]
## Units walk over these while they stand.
const WALKABLE := [Kind.GATE, Kind.BRIDGE, Kind.FARM_FIELD]
## Nothing to crack on these.
const NO_CRACKS := [Kind.FARM_FIELD, Kind.TREE]
const TEMPLE_ROOF := [Color("4f8a8a"), Color("3f7070"), Color("2f5656")]
const BARRACKS_ROOF := [Color("9a5a3a"), Color("7e4a30"), Color("623a26")]
const STALL_CANOPY := [[Color("b8322a"), Color("e8dcc4")], [Color("2f5ca8"), Color("e8dcc4")], [Color("3f7a34"), Color("d8b23a")]]
const COL_DOOR := Color("1a1614")
const COL_IRON := Color("4a4540")
const COL_SHIELD := Color("9a2420")
```

3c. In `setup()`, find:

```gdscript
	max_hp = {Kind.TOWER: 160.0, Kind.BLOCK: 110.0, Kind.WALL: 60.0, Kind.CRATES: 30.0,
		Kind.KEEP: 180.0, Kind.CASTLE_WALL: 90.0, Kind.HOUSE: 50.0, Kind.TORCH: 10.0}[k]
	hp = max_hp
```

Replace with:

```gdscript
	max_hp = {Kind.TOWER: 160.0, Kind.BLOCK: 110.0, Kind.WALL: 60.0, Kind.CRATES: 30.0,
		Kind.KEEP: 180.0, Kind.CASTLE_WALL: 90.0, Kind.HOUSE: 50.0, Kind.TORCH: 10.0,
		Kind.TEMPLE: 200.0, Kind.BARRACKS: 150.0, Kind.MARKET_STALL: 25.0, Kind.GATE: 120.0,
		Kind.BRIDGE: 140.0, Kind.FARM_FIELD: 20.0, Kind.TREE: 30.0}[k]
	hp = max_hp
	walkable = k in WALKABLE
```

and find:

```gdscript
	if k == Kind.TOWER or k == Kind.BLOCK or k == Kind.KEEP or k == Kind.HOUSE:
		_build_windows()
```

Replace with:

```gdscript
	if k in WINDOWED:
		_build_windows()
```

3d. In `crack()`, change the guard line `if destroyed or not _cracks.is_empty():` to:

```gdscript
	if destroyed or not _cracks.is_empty() or kind in NO_CRACKS:
```

3e. In `_fall_apart()`, find:

```gdscript
func _fall_apart(source: Vector2, damage_kind: StringName) -> void:
	_build_rubble()
	if damage_kind == &"laser" and max_height > 20.0:
```

Replace with:

```gdscript
func _fall_apart(source: Vector2, damage_kind: StringName) -> void:
	if kind == Kind.FARM_FIELD:
		# Crops burn flat (or freeze, or drown): no rubble, just a ruined field.
		if damage_kind == &"ice":
			frost = 1.0
		elif damage_kind != &"water":
			scorch = 1.0
			_spawn_fire(Vector2.ZERO, 2.5)
		_spawn_dust(0.4)
		return
	_build_rubble()
	if kind == Kind.TREE:
		# Felled: a stump among its leaves (the rubble), never sliced or slumped like a building.
		_spawn_dust(0.4)
		if not damage_kind in [&"gravity", &"ice", &"water", &"wind", &"stone"]:
			_spawn_fire(Vector2.ZERO, 2.0)
	elif damage_kind == &"laser" and max_height > 20.0:
```

3f. In `_palette()`, find:

```gdscript
		Kind.KEEP, Kind.CASTLE_WALL:
			return [Color("a4a2a0"), Color("86858a"), Color("6a6a74")]
		Kind.HOUSE:
			return [Color("7a3a26"), Color("a8987a"), Color("8a7c64")]
		Kind.TORCH:
			return [Color("4a3a2a"), Color("3a2c20"), Color("2c2118")]
```

Replace with:

```gdscript
		Kind.KEEP, Kind.CASTLE_WALL, Kind.GATE:
			return [Color("a4a2a0"), Color("86858a"), Color("6a6a74")]
		Kind.HOUSE:
			return [Color("7a3a26"), Color("a8987a"), Color("8a7c64")]
		Kind.TORCH:
			return [Color("4a3a2a"), Color("3a2c20"), Color("2c2118")]
		Kind.TEMPLE:
			return [Color("d6cba8"), Color("b8aa86"), Color("998c6a")]
		Kind.BARRACKS:
			return [Color("9a9486"), Color("7e796d"), Color("656157")]
		Kind.MARKET_STALL, Kind.BRIDGE:
			return [Color("9a7a4c"), Color("7c6038"), Color("604a2c")]
		Kind.FARM_FIELD:
			return [Color("c9a94f"), Color("7a5c3a"), Color("634a2f")]
		Kind.TREE:
			return [Color("6a9a3a"), Color("54803a"), Color("3e6230")]
```

3g. In `_draw()`, find:

```gdscript
	# Ground shadow toward the back.
	draw_colored_polygon(PackedVector2Array([_s[0], _s[1] + Vector2(6, -3), _s[2] + Vector2(6, -3), _s[3]]),
		Color(0, 0, 0, 0.25))

	var rubble_top := _collapse >= 0.0
	if kind == Kind.TORCH and not destroyed:
		_draw_torch(right_c, left_c)
	else:
		_draw_box(0.0, height, top_c, right_c, left_c, rubble_top)
	if not rubble_top and not destroyed and (kind == Kind.KEEP or kind == Kind.CASTLE_WALL):
		_draw_masonry(right_c, left_c)
	if not rubble_top and (kind == Kind.TOWER or kind == Kind.BLOCK or kind == Kind.KEEP or kind == Kind.HOUSE):
		_draw_windows(light)
```

Replace with:

```gdscript
	# Ground shadow toward the back (fields lie flat and cast none).
	if kind != Kind.FARM_FIELD:
		draw_colored_polygon(PackedVector2Array([_s[0], _s[1] + Vector2(6, -3), _s[2] + Vector2(6, -3), _s[3]]),
			Color(0, 0, 0, 0.25))

	var rubble_top := _collapse >= 0.0
	if kind == Kind.TORCH and not destroyed:
		_draw_torch(right_c, left_c)
	elif kind == Kind.TREE:
		_draw_tree(top_c, right_c, left_c)
	else:
		_draw_box(0.0, height, top_c, right_c, left_c, rubble_top)
	if not rubble_top and not destroyed and kind in MASONRY:
		_draw_masonry(right_c, left_c)
	if not rubble_top and kind in WINDOWED:
		_draw_windows(light)
```

3h. In `_build_windows()` change `if kind == Kind.KEEP or kind == Kind.HOUSE:` to `if kind in FANTASY_WINDOWS:`, and in `_draw_windows(light)` change `if kind == Kind.KEEP or kind == Kind.HOUSE:` to `if kind in FANTASY_WINDOWS:`.

3i. In `_draw_kind_details()`, find:

```gdscript
		Kind.HOUSE:
			_draw_roof()
		Kind.CRATES:
```

Replace with:

```gdscript
		Kind.HOUSE:
			_draw_roof(COL_ROOF, 14.0, true)
		Kind.TEMPLE:
			_draw_roof(TEMPLE_ROOF, 22.0, false)
			_draw_opening(3, 0.42, 0.58, 16.0, COL_DOOR)
			var sun := (_s[3].lerp(_s[2], 0.5) + Vector2(0, -height + 8.0)).round()
			var gold := COL_GOLD.lerp(COL_CHAR, scorch)
			draw_rect(Rect2(sun + Vector2(-2, -2), Vector2(5, 5)), gold)
			draw_rect(Rect2(sun + Vector2(-1, -3), Vector2(3, 7)), gold)
		Kind.BARRACKS:
			_draw_roof(BARRACKS_ROOF, 12.0, false)
			_draw_opening(3, 0.45, 0.58, 12.0, COL_DOOR)
			for u in [0.2, 0.8]:
				var p := (_s[3].lerp(_s[2], u) + Vector2(0, -height * 0.6)).round()
				draw_rect(Rect2(p + Vector2(-2, -3), Vector2(4, 5)), COL_SHIELD.lerp(COL_CHAR, scorch))
				draw_rect(Rect2(p + Vector2(-1, -2), Vector2(2, 2)), COL_GOLD.lerp(COL_CHAR, scorch))
		Kind.MARKET_STALL:
			_draw_stall()
		Kind.GATE:
			_draw_crenellations(top_c, right_c, left_c, 0.22)
			_draw_gate()
		Kind.BRIDGE:
			_draw_bridge(top_c)
		Kind.FARM_FIELD:
			_draw_furrows(top_c)
		Kind.CRATES:
```

3j. Give `_draw_roof` its colours, rise and timber flag. Find:

```gdscript
func _draw_roof() -> void:
	# Ridge runs along the longer ground axis; two sloped planes plus gable ends.
	var r := footprint
	var rise := 14.0
	var along_x := r.size.x >= r.size.y
```

Replace with:

```gdscript
## Pitched roof in `cols` (lit, mid, dark) rising `rise` px; `timber` adds the house's timber frame on the walls.
func _draw_roof(cols: Array, rise: float, timber: bool) -> void:
	# Ridge runs along the longer ground axis; two sloped planes plus gable ends.
	var r := footprint
	var along_x := r.size.x >= r.size.y
```

then find:

```gdscript
	var roof_dark: Color = COL_ROOF[2].lerp(COL_CHAR, scorch)
	var roof_mid: Color = COL_ROOF[1].lerp(COL_CHAR, scorch)
	var roof_lit: Color = COL_ROOF[0].lerp(COL_CHAR, scorch)
```

Replace with:

```gdscript
	var roof_dark: Color = cols[2].lerp(COL_CHAR, scorch)
	var roof_mid: Color = cols[1].lerp(COL_CHAR, scorch)
	var roof_lit: Color = cols[0].lerp(COL_CHAR, scorch)
```

then find:

```gdscript
	# Timber frame on the plaster walls.
	for face in [3, 1]:
```

Replace with:

```gdscript
	if not timber:
		return
	# Timber frame on the plaster walls.
	for face in [3, 1]:
```

3k. After the whole `func _draw_torch(right_c: Color, left_c: Color) -> void:` function add:

```gdscript
## Dark doorway or arch at the foot of a face (3 = the +y face on the left, 1 = the +x face on the right),
## spanning u0..u1 along it, h px tall with a pointed top.
func _draw_opening(face: int, u0: float, u1: float, h: float, col: Color) -> void:
	var a := _s[face].lerp(_s[2], u0)
	var b := _s[face].lerp(_s[2], u1)
	var apex := a.lerp(b, 0.5) + Vector2(0, -h - 3.0)
	draw_colored_polygon(PackedVector2Array([a, b, b + Vector2(0, -h), apex, a + Vector2(0, -h)]), col)


## Gatehouse arch with a raised portcullis, on the long face the road runs through.
func _draw_gate() -> void:
	var face := 3 if footprint.size.x >= footprint.size.y else 1
	var arch_h := roundf(height * 0.62)
	_draw_opening(face, 0.3, 0.7, arch_h, COL_DOOR)
	var iron := COL_IRON.lerp(COL_CHAR, scorch)
	for u in [0.38, 0.5, 0.62]:
		var p := _s[face].lerp(_s[2], u)
		draw_line(p + Vector2(0, -arch_h * 0.45), p + Vector2(0, -arch_h), iron, -1.0)
	draw_line(_s[face].lerp(_s[2], 0.3) + Vector2(0, -arch_h * 0.45), _s[face].lerp(_s[2], 0.7) + Vector2(0, -arch_h * 0.45),
		iron, -1.0)


## Striped cloth canopy on poles above the counter; the stripe colours come from the stall's seed.
func _draw_stall() -> void:
	var r := footprint
	var h := height + 9.0
	var cloth: Array = STALL_CANOPY[rng.seed % STALL_CANOPY.size()]
	var pole := COL_BEAM.lerp(COL_CHAR, scorch)
	for corner in [Vector2(r.position.x, r.end.y), r.end, Vector2(r.end.x, r.position.y)]:
		draw_line(_gp(corner, height), _gp(corner, h), pole, -1.0)
	var stripes := 4
	for i in stripes:
		var x0 := lerpf(r.position.x - 0.08, r.end.x + 0.08, float(i) / stripes)
		var x1 := lerpf(r.position.x - 0.08, r.end.x + 0.08, float(i + 1) / stripes)
		var col: Color = cloth[i % 2].lerp(COL_CHAR, scorch)
		draw_colored_polygon(PackedVector2Array([
			_gp(Vector2(x0, r.position.y - 0.08), h), _gp(Vector2(x1, r.position.y - 0.08), h),
			_gp(Vector2(x1, r.end.y + 0.08), h - 3.0), _gp(Vector2(x0, r.end.y + 0.08), h - 3.0)]), col)


## Deck planks across the span and a rail on posts along both long sides.
func _draw_bridge(top_c: Color) -> void:
	var r := footprint
	var plank := top_c.darkened(0.25)
	var along_y := r.size.y >= r.size.x
	var span := r.size.y if along_y else r.size.x
	var n := int(span / 0.3)
	for i in range(1, n):
		var k := float(i) / n
		if along_y:
			var y := lerpf(r.position.y, r.end.y, k)
			draw_line(_gp(Vector2(r.position.x, y), height), _gp(Vector2(r.end.x, y), height), plank, -1.0)
		else:
			var x := lerpf(r.position.x, r.end.x, k)
			draw_line(_gp(Vector2(x, r.position.y), height), _gp(Vector2(x, r.end.y), height), plank, -1.0)
	var rail := COL_BEAM.lerp(COL_CHAR, scorch)
	var sides := [[r.position, Vector2(r.position.x, r.end.y)], [Vector2(r.end.x, r.position.y), r.end]] if along_y \
		else [[r.position, Vector2(r.end.x, r.position.y)], [Vector2(r.position.x, r.end.y), r.end]]
	for side in sides:
		var a: Vector2 = side[0]
		var b: Vector2 = side[1]
		draw_line(_gp(a, height + 5.0), _gp(b, height + 5.0), rail, -1.0)
		var posts := maxi(int(a.distance_to(b) / 0.6), 1)
		for i in posts + 1:
			var p := a.lerp(b, float(i) / posts)
			draw_line(_gp(p, height), _gp(p, height + 5.0), rail, -1.0)


## Crop rows across a field.
func _draw_furrows(top_c: Color) -> void:
	var r := footprint
	var col := top_c.darkened(0.25)
	var rows := int(r.size.y / 0.22)
	for i in range(1, rows):
		var y := lerpf(r.position.y, r.end.y, float(i) / rows)
		draw_line(_gp(Vector2(r.position.x, y), height), _gp(Vector2(r.end.x, y), height), col, -1.0)


## Round pixel tree: a trunk and a lumpy three-tone canopy; once felled, just the stump (its leaves are the rubble).
func _draw_tree(top_c: Color, right_c: Color, left_c: Color) -> void:
	var base := _gp(center(), 0.0).round()
	var bark := COL_BEAM.lerp(COL_CHAR, scorch)
	if destroyed:
		draw_rect(Rect2(base + Vector2(-1, -4), Vector2(3, 4)), bark)
		return
	var trunk_h := roundf(max_height * 0.35)
	draw_rect(Rect2(base + Vector2(-1, -trunk_h), Vector2(3, trunk_h)), bark)
	var r := roundf(max_height * 0.3)
	var c := base + Vector2(0, -trunk_h - r * 0.7)
	draw_circle(c + Vector2(-2, 2), r, left_c)
	draw_circle(c + Vector2(2, 1), r * 0.85, right_c)
	draw_circle(c + Vector2(1, -2), r * 0.55, top_c)
```

- [ ] **Step 4: Run the tests**

Run: `bash tools/test.sh`
Expected: `checks=247 failures=0`.

- [ ] **Step 5: Preview the new kinds**

Create `tools/dev/preview_kinds.gd`:

```gdscript
extends SceneTree
## Dev preview: the Aldermere building kinds standing, then destroyed (fields burn flat, trees are felled).
## Usage (writes captures/kinds_standing.png and captures/kinds_destroyed.png):
##   godot --path . --audio-driver Dummy -s tools/dev/preview_kinds.gd


func _init() -> void:
	RenderingServer.set_default_clear_color(Color("5d7a3a"))
	var root2 := Node2D.new()
	get_root().add_child(root2)
	var cam := Camera2D.new()
	cam.position = Vector2(30, 0)
	cam.zoom = Vector2(0.9, 0.9)
	root2.add_child(cam)
	cam.make_current()
	var world := Node2D.new()
	world.y_sort_enabled = true
	root2.add_child(world)
	var fx := Node2D.new()
	fx.z_index = 10
	root2.add_child(fx)
	var env := EnvironmentField.new()
	env.world_parent = world
	env.fx_parent = fx
	env.fx_back = fx
	root2.add_child(env)
	var items := [
		[Rect2(-4.0, -4.0, 2.7, 3.1), 56.0, Structure.Kind.TEMPLE],
		[Rect2(-0.5, -4.0, 4.2, 1.9), 36.0, Structure.Kind.BARRACKS],
		[Rect2(-4.0, 0.2, 2.8, 1.0), 40.0, Structure.Kind.GATE],
		[Rect2(4.6, -4.0, 1.0, 2.6), 40.0, Structure.Kind.GATE],
		[Rect2(0.0, 0.0, 0.9, 0.7), 10.0, Structure.Kind.MARKET_STALL],
		[Rect2(1.2, 0.0, 0.9, 0.7), 10.0, Structure.Kind.MARKET_STALL],
		[Rect2(2.4, 0.0, 0.9, 0.7), 10.0, Structure.Kind.MARKET_STALL],
		[Rect2(4.2, 0.0, 2.0, 2.4), 6.0, Structure.Kind.BRIDGE],
		[Rect2(-4.0, 2.4, 2.6, 1.8), 3.0, Structure.Kind.FARM_FIELD],
		[Rect2(-0.8, 2.4, 0.7, 0.7), 26.0, Structure.Kind.TREE],
		[Rect2(0.4, 2.9, 0.7, 0.7), 29.0, Structure.Kind.TREE],
		[Rect2(1.6, 2.4, 1.3, 0.95), 22.0, Structure.Kind.HOUSE],
		[Rect2(3.3, 2.6, 1.3, 1.3), 84.0, Structure.Kind.KEEP],
	]
	var built: Array[Structure] = []
	for item in items:
		built.append(env.add_structure(item[0], item[1], item[2]))
	for f in 30:
		await process_frame
	_save("kinds_standing.png")
	for s in built:
		s.destroy(s.center() + Vector2(0.6, 0.6), &"cinder")
	for f in 150:
		await process_frame
	_save("kinds_destroyed.png")
	quit()


func _save(file_name: String) -> void:
	var dir := ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(dir)
	get_root().get_texture().get_image().save_png(dir.path_join(file_name))
	print("captured ", file_name)
```

Run:

```bash
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --audio-driver Dummy -s tools/dev/preview_kinds.gd
```

Expected: `captured kinds_standing.png` and `captured kinds_destroyed.png`. Open both PNGs and check: every building is readable in the pixel-box style; the gate arches sit on the long faces (the wide gate's arch on its lower-left face, the deep gate's on its lower-right face); stalls have striped canopies on poles; the bridge shows planks and rails; the field shows furrows and no shadow; the trees are round and lit from above; in the destroyed shot the field is a flat charred patch, the trees are stumps among green rubble, the others are rubble piles with fire and smoke. Fix any drawing error (inverted polygon, colour clash, detail floating off a face) before continuing.

- [ ] **Step 6: Check the sandbox is unchanged**

```bash
bash tools/dev/sandbox_baseline.sh captures/m1_task3
python tools/dev/compare_captures.py captures/m1_base_a captures/m1_task3
```

Expected: `files=28`, `worst_mean_diff` no more than the Task 1 noise value + 0.5 (the house roof now goes through `_draw_roof(COL_ROOF, 14.0, true)`, which must draw exactly as before).

- [ ] **Step 7: Commit**

```bash
git add src/environment/structure.gd tests/test_building_kinds.gd tests/test_building_kinds.gd.uid tests/run_all.gd tools/dev/preview_kinds.gd tools/dev/preview_kinds.gd.uid
git commit -m "feat: Aldermere building kinds" -m "Temple, barracks, market stall, gate, bridge, farm field and tree, drawn in the pixel-box style. Gates, the bridge and fields are walkable; fields burn flat and trees are felled instead of collapsing. tools/dev/preview_kinds.gd renders them standing and destroyed." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

(If `tools/dev/preview_kinds.gd.uid` was not generated because the file was never imported, run `bash tools/test.sh` once more and retry the `git add`.)

- [ ] **Step 8: User checkpoint (controller)**

Show the user `captures/kinds_standing.png` and `captures/kinds_destroyed.png` and wait for approval. Apply requested look changes in `structure.gd` (rerun Steps 4–6 and amend with a new commit) before starting Task 4.

---
### Task 4: The Aldermere layout (pure data)

**Files:**
- Create: `src/game/town/town_layout.gd`
- Modify: `tests/run_all.gd`
- Test: `tests/test_town_layout.gd`

**Interfaces:**
- Consumes: `Structure.Kind` (Task 3), `Structure.WALKABLE`.
- Produces (`class_name TownLayout extends RefCounted`, everything static/const, ground units):
  - `MAP := Rect2(-12, -12, 28, 28)`, `TOWN := Rect2(-9, -9, 18, 18)`, `RIVER := Rect2(-12, 11.4, 28, 1.6)`
  - `ROADS: Array` of two `Rect2` (north–south `Rect2(-0.4, -3.5, 0.8, 19.5)`, east–west `Rect2(-8.4, -0.4, 24.4, 0.8)`)
  - `MARKET_SQUARE := Rect2(-2.9, -2.4, 5.8, 5.0)`, `BARRACKS_YARD := Rect2(3.9, 0.7, 4.2, 2.4)`
  - `CITADEL_AREA := Rect2(-2.7, -8.2, 5.4, 4.6)` (the nine parts stay inside), `CITADEL_COURT := Rect2(-2.9, -8.4, 5.8, 5.0)` (paved), `CITADEL_ORIGIN := Vector2(0, -5.9)` (centre of the keep)
  - `EXITS: Array` of `Vector2(0, 15.6)` (south road) and `Vector2(15.6, 0)` (east forest road)
  - `MAIN_GATE`, `SIDE_GATE`, `TEMPLE`, `BARRACKS`, `BRIDGE` rects and the `WALLS`, `CORNER_TOWERS`, `SIDE_TOWERS`, `STALLS`, `FIELDS`, `BARNS`, `TORCHES`, `DISTRICTS` arrays
  - `static func structures() -> Array[Dictionary]`: every building except the Citadel as `{"rect": Rect2, "height": float, "kind": Structure.Kind, "role": StringName}`. Counts: 8 walls (`&"wall"`), 6 wall towers (`&"tower"`), 2 gates (`&"gate"`), temple, barracks, bridge, 7 market stalls (`&"market"`), 40 houses (`&"house"`), 7 fields + 2 barns (`&"farm"`), 39 trees + 10 torches (`&"decor"`).
  - `static func houses() -> Array[Rect2]`, `static func trees() -> Array[Vector2]` (top-left corners of 0.7×0.7 trees).
- The numbers below were checked with a script: nothing overlaps, everything is on the map, and roads, river, barracks yard and Citadel ground stay clear.

- [ ] **Step 1: Write the failing test**

Create `tests/test_town_layout.gd`:

```gdscript
extends RefCounted
## Aldermere's layout data: counts per role, everything on the map, nothing overlapping, and roads, river,
## barracks yard and Citadel ground kept clear; exits on roads.


static func run(t) -> void:
	var items := TownLayout.structures()
	var counts := {}
	for d in items:
		counts[d.role] = int(counts.get(d.role, 0)) + 1
	var want := {&"house": 40, &"wall": 8, &"tower": 6, &"gate": 2, &"temple": 1, &"barracks": 1, &"bridge": 1,
		&"market": 7, &"farm": 9, &"decor": 49}
	for role in want:
		t.check(counts.get(role, 0) == want[role], "%d x %s (got %d)" % [want[role], role, counts.get(role, 0)])
	t.check(counts.size() == want.size(), "no unexpected roles (%s)" % [counts.keys()])

	var problems: Array[String] = []
	for d in items:
		var r: Rect2 = d.rect
		if not TownLayout.MAP.encloses(r):
			problems.append("off the map: %s %s" % [d.role, r])
		if r.intersects(TownLayout.CITADEL_AREA):
			problems.append("on the Citadel ground: %s %s" % [d.role, r])
		if Structure.WALKABLE.has(d.kind):
			continue
		for road: Rect2 in TownLayout.ROADS:
			if r.intersects(road):
				problems.append("on a road: %s %s" % [d.role, r])
		if r.intersects(TownLayout.RIVER):
			problems.append("in the river: %s %s" % [d.role, r])
		if r.intersects(TownLayout.BARRACKS_YARD):
			problems.append("in the barracks yard: %s %s" % [d.role, r])
	for i in items.size():
		var a: Rect2 = items[i].rect
		for j in range(i + 1, items.size()):
			var b: Rect2 = items[j].rect
			if a.grow(-0.01).intersects(b.grow(-0.01)):
				problems.append("overlap: %s %s / %s %s" % [items[i].role, a, items[j].role, b])
	t.check(problems.is_empty(), "layout problems: %s" % [problems])

	for e: Vector2 in TownLayout.EXITS:
		var on_road := false
		for road: Rect2 in TownLayout.ROADS:
			on_road = on_road or road.has_point(e)
		t.check(on_road and TownLayout.MAP.has_point(e), "exit %s is on a road inside the map" % e)
	var bridge: Rect2 = TownLayout.BRIDGE
	t.check(bridge.position.y < TownLayout.RIVER.position.y and bridge.end.y > TownLayout.RIVER.end.y, "the bridge spans the river")
	t.check(TownLayout.CITADEL_AREA.has_point(TownLayout.CITADEL_ORIGIN), "the Citadel origin is inside its ground")
```

Register it: add `"res://tests/test_town_layout.gd",` as the last entry of `SUITES` in `tests/run_all.gd`.

- [ ] **Step 2: Run the tests to see the new suite fail**

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_town_layout.gd` and `checks=248 failures=1`.

- [ ] **Step 3: Create `src/game/town/town_layout.gd`**

```gdscript
class_name TownLayout
extends RefCounted
## Aldermere, the town of the one-mission game, as pure data in ground units: origin at the town centre, plan
## north = -y (on screen the Citadel sits upper right, the Main Gate lower left). Town builds it; the Citadel's
## nine parts live in citadel.gd. Numbers follow the spec's town table.

const MAP := Rect2(-12, -12, 28, 28)
## Inside the town walls.
const TOWN := Rect2(-9, -9, 18, 18)
const RIVER := Rect2(-12, 11.4, 28, 1.6)
## North-south street from the Citadel gate out through the Main Gate and over the bridge; east-west street from
## the west wall out through the Side Gate along the forest road.
const ROADS := [Rect2(-0.4, -3.5, 0.8, 19.5), Rect2(-8.4, -0.4, 24.4, 0.8)]
const MARKET_SQUARE := Rect2(-2.9, -2.4, 5.8, 5.0)
const BARRACKS_YARD := Rect2(3.9, 0.7, 4.2, 2.4)
## The Citadel's ground (its nine parts stay inside) and its paved court.
const CITADEL_AREA := Rect2(-2.7, -8.2, 5.4, 4.6)
const CITADEL_COURT := Rect2(-2.9, -8.4, 5.8, 5.0)
## Centre of the keep.
const CITADEL_ORIGIN := Vector2(0, -5.9)
## Reaching one of these means a citizen escaped: the south road and the east forest road at the map edge.
const EXITS := [Vector2(0, 15.6), Vector2(15.6, 0)]

const WALLS := [
	Rect2(-7.95, -9.0, 15.9, 0.6), Rect2(-9.0, -7.95, 0.6, 15.9),
	Rect2(-7.95, 8.4, 6.55, 0.6), Rect2(1.4, 8.4, 6.55, 0.6),
	Rect2(8.4, -7.95, 0.6, 2.35), Rect2(8.4, -4.3, 0.6, 3.0), Rect2(8.4, 1.3, 0.6, 2.7), Rect2(8.4, 5.3, 0.6, 2.65),
]
const CORNER_TOWERS := [
	Rect2(-9.45, -9.45, 1.5, 1.5), Rect2(7.95, -9.45, 1.5, 1.5), Rect2(-9.45, 7.95, 1.5, 1.5), Rect2(7.95, 7.95, 1.5, 1.5),
]
const SIDE_TOWERS := [Rect2(8.05, -5.6, 1.3, 1.3), Rect2(8.05, 4.0, 1.3, 1.3)]
const MAIN_GATE := Rect2(-1.4, 8.2, 2.8, 1.0)
const SIDE_GATE := Rect2(8.2, -1.3, 1.0, 2.6)
const TEMPLE := Rect2(3.5, -7.6, 2.7, 3.1)
const BARRACKS := Rect2(3.9, -2.5, 4.2, 1.9)
const BRIDGE := Rect2(-1.0, 11.0, 2.0, 2.4)
const STALLS := [
	Rect2(-2.5, -2.0, 0.9, 0.7), Rect2(-1.4, -2.0, 0.9, 0.7), Rect2(0.6, -2.0, 0.9, 0.7), Rect2(1.7, -2.0, 0.9, 0.7),
	Rect2(-2.5, 1.4, 0.9, 0.7), Rect2(0.6, 1.4, 0.9, 0.7), Rect2(1.7, 1.4, 0.9, 0.7),
]
const FIELDS := [
	Rect2(-10.5, 13.7, 2.6, 1.8), Rect2(-7.7, 13.7, 2.6, 1.8), Rect2(-4.9, 13.7, 2.6, 1.8),
	Rect2(2.5, 13.7, 2.8, 1.8), Rect2(5.5, 13.7, 2.8, 1.8), Rect2(8.5, 13.7, 2.8, 1.8), Rect2(11.5, 13.7, 2.8, 1.8),
]
const BARNS := [Rect2(-11.9, 13.7, 1.2, 1.4), Rect2(14.5, 13.7, 1.2, 1.4)]
## Torch posts: the market corners, both sides of the Main Gate and the Citadel gate, outside the Side Gate.
const TORCHES := [
	Vector2(-2.9, -2.45), Vector2(2.8, -2.45), Vector2(-2.9, 2.35), Vector2(2.8, 2.35),
	Vector2(-1.8, 8.0), Vector2(1.6, 8.0), Vector2(-0.9, -3.3), Vector2(0.7, -3.3),
	Vector2(9.6, -1.8), Vector2(9.6, 1.6),
]
## Residential blocks filled with rows of houses (see houses()): north-west, south-west, south-middle, south-east.
const DISTRICTS := [Rect2(-8.1, -7.8, 4.9, 6.9), Rect2(-8.1, 0.9, 4.9, 6.9), Rect2(-2.6, 3.6, 2.0, 4.3), Rect2(0.7, 3.6, 7.1, 4.3)]
const HOUSE_WIDE := Vector2(1.3, 0.95)
const HOUSE_DEEP := Vector2(0.95, 1.25)
const HOUSE_GAP := Vector2(0.45, 0.5)
const TREE_SIZE := Vector2(0.7, 0.7)


## Every building except the Citadel, as {rect, height, kind, role}.
static func structures() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Rect2 in WALLS:
		_add(out, r, 34.0, Structure.Kind.CASTLE_WALL, &"wall")
	for r: Rect2 in CORNER_TOWERS:
		_add(out, r, 70.0, Structure.Kind.KEEP, &"tower")
	for r: Rect2 in SIDE_TOWERS:
		_add(out, r, 60.0, Structure.Kind.KEEP, &"tower")
	_add(out, MAIN_GATE, 40.0, Structure.Kind.GATE, &"gate")
	_add(out, SIDE_GATE, 40.0, Structure.Kind.GATE, &"gate")
	_add(out, TEMPLE, 56.0, Structure.Kind.TEMPLE, &"temple")
	_add(out, BARRACKS, 36.0, Structure.Kind.BARRACKS, &"barracks")
	for r: Rect2 in STALLS:
		_add(out, r, 10.0, Structure.Kind.MARKET_STALL, &"market")
	var house_rects := houses()
	for i in house_rects.size():
		_add(out, house_rects[i], 20.0 + float(i * 7 % 5) * 1.5, Structure.Kind.HOUSE, &"house")
	_add(out, BRIDGE, 6.0, Structure.Kind.BRIDGE, &"bridge")
	for r: Rect2 in FIELDS:
		_add(out, r, 3.0, Structure.Kind.FARM_FIELD, &"farm")
	for r: Rect2 in BARNS:
		_add(out, r, 20.0, Structure.Kind.HOUSE, &"farm")
	var tree_spots := trees()
	for i in tree_spots.size():
		_add(out, Rect2(tree_spots[i], TREE_SIZE), 26.0 + float(i % 3) * 3.0, Structure.Kind.TREE, &"decor")
	for p: Vector2 in TORCHES:
		_add(out, Rect2(p, Vector2(0.2, 0.2)), 16.0, Structure.Kind.TORCH, &"decor")
	return out


## House footprints: rows filling each district, alternating wide (1.3 x 0.95) and deep (0.95 x 1.25) houses,
## deep rows nudged sideways so the streets are not a perfect grid. 12 + 12 + 3 + 13 = 40 houses.
static func houses() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for d: Rect2 in DISTRICTS:
		var y := d.position.y
		var row := 0
		while true:
			var size: Vector2 = HOUSE_WIDE if row % 2 == 0 else HOUSE_DEEP
			if y + size.y > d.end.y + 0.001:
				break
			var x := d.position.x + (0.2 if row % 2 == 1 else 0.0)
			while x + size.x <= d.end.x + 0.001:
				out.append(Rect2(Vector2(x, y), size))
				x += size.x + HOUSE_GAP.x
			y += size.y + HOUSE_GAP.y
			row += 1
	return out


## Tree spots (top-left corners): a row along the north edge, a column along the west edge and two columns on
## the east edge that leave the forest road clear, each nudged a little so the forest does not look planted.
static func trees() -> Array[Vector2]:
	var spots: Array[Vector2] = []
	for i in 14:
		spots.append(Vector2(-11.4 + 2.0 * i, -10.6))
	for i in 9:
		spots.append(Vector2(-10.6, -8.5 + 2.2 * i))
	for x: float in [10.6, 13.0]:
		for i in 9:
			var y := -8.5 + 2.2 * i
			if absf(y) < 1.4:
				continue
			spots.append(Vector2(x, y))
	for i in spots.size():
		spots[i] += Vector2(_jitter(i * 2), _jitter(i * 2 + 1))
	return spots


static func _jitter(n: int) -> float:
	return (float((n * 37 + 11) % 7) / 6.0 - 0.5) * 0.6


static func _add(out: Array[Dictionary], rect: Rect2, height: float, kind: Structure.Kind, role: StringName) -> void:
	out.append({"rect": rect, "height": height, "kind": kind, "role": role})
```

- [ ] **Step 4: Run the tests**

Run: `bash tools/test.sh`
Expected: `checks=263 failures=0`. If the layout check fails, its message lists each offending rect: fix the numbers in `town_layout.gd`, not the test.

- [ ] **Step 5: Commit**

```bash
git add src/game/town/town_layout.gd src/game/town/town_layout.gd.uid tests/test_town_layout.gd tests/test_town_layout.gd.uid tests/run_all.gd
git commit -m "feat: Aldermere town layout data" -m "TownLayout holds the one-mission town as pure data: map, walls and towers, two gates, temple, barracks, market stalls, 40 houses, river, bridge, farms, forest edge, torches, roads and exits. A headless suite checks counts, bounds, overlaps and the clear roads, river, yard and Citadel ground." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 5: The fortified Royal Citadel

**Files:**
- Create: `src/game/town/citadel.gd`
- Modify: `tests/run_all.gd`
- Test: `tests/test_citadel.gd`

**Interfaces:**
- Consumes: `EnvironmentField.add_structure(rect, height, kind, role)`, `Structure.damage_filter`, `mark_hit`, `crack`, `ignite`, `dust_burst`, `drop_banner`, `destroy`, `distance_to`, `footprint`, `position` (Tasks 2–3); `TownLayout.CITADEL_ORIGIN`, `TownLayout.CITADEL_AREA` (Task 4, test only); `CameraShake.add_trauma`.
- Produces (`class_name Citadel extends Node`):
  - `signal health_changed(fraction: float)`, `signal part_collapsed(part: Structure)` (every part, keep included), `signal fallen`
  - `var max_health := 1000.0`, `var budget_per_second := 0.25`, `var health`, `var origin: Vector2` (keep centre), `var parts: Array[Structure]` (NW, NE, SW, SE towers; N, S, W, E walls; keep last), `var keep: Structure`
  - `func setup(env: EnvironmentField, at: Vector2, shake: CameraShake = null) -> Citadel` (adds the nine parts with role `&"citadel"`, each routed through the damage filter)
  - `func fraction() -> float`, `func standing_parts() -> int`, `func is_fallen() -> bool`
  - `func advance(delta: float) -> void`: the Citadel's clock for the rolling one-second budget; `_process` calls it, tests call it directly.
- Behaviour (spec §4.5): every hit on a part is a hit on the shared pool, capped by what is left of the rolling one-second budget (25% of max health). Each 10% mark crossed (90% … 20%) collapses the standing outer part nearest the hit's source. Courtyard fires at 40%, the keep's banner falls at 20%, and at 0% the keep collapses last with a big dust cloud and shake, then `fallen` fires. Parts never lose their own hp.

- [ ] **Step 1: Write the failing test**

Create `tests/test_citadel.gd`:

```gdscript
extends RefCounted
## The fortified Citadel: nine parts on one hidden health pool, at most 25% lost per rolling second, the part
## nearest each blow collapses at every 10% mark, and the keep falls last.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var c := Citadel.new().setup(env, TownLayout.CITADEL_ORIGIN)
	t.check(c.parts.size() == 9 and c.keep == c.parts[8], "nine parts, keep last")
	var ok := true
	for p in c.parts:
		ok = ok and p.role == &"citadel" and p.damage_filter.is_valid() and TownLayout.CITADEL_AREA.encloses(p.footprint)
	t.check(ok, "parts are tagged, routed through the budget and inside the Citadel ground")
	var down: Array = []
	c.part_collapsed.connect(func(p: Structure) -> void: down.append(p))
	var fell := [false]
	c.fallen.connect(func() -> void: fell[0] = true)
	var reported: Array = []
	c.health_changed.connect(func(f: float) -> void: reported.append(f))

	# A colossal blast from the north-west takes only this second's budget (25%): two 10% marks, so the two
	# parts nearest the blast collapse, nearest first.
	var nw := Vector2(-4.5, -7.2)
	env.damage_radius(nw, 3.0, 99999.0, &"stone")
	t.near(c.fraction(), 0.75, 0.001, "one blast takes only 25%")
	t.check(down == [c.parts[0], c.parts[6]], "the NW tower then the W wall collapse (%s)" % [_indices(c, down)])
	t.check(c.keep.hp == c.keep.max_hp and c.standing_parts() == 7, "parts keep their own hp; 7 still stand")

	# The budget is a rolling second.
	env.damage_radius(nw, 3.0, 99999.0, &"stone")
	c.advance(0.6)
	env.damage_radius(nw, 3.0, 99999.0, &"stone")
	t.near(c.fraction(), 0.75, 0.001, "no more loss inside the same second")
	c.advance(0.4)
	env.damage_radius(nw, 3.0, 99999.0, &"stone")
	t.near(c.fraction(), 0.5, 0.001, "the budget refills after one second")
	t.check(down.size() == 5 and down.slice(2) == [c.parts[2], c.parts[4], c.parts[5]],
		"then the SW tower, N wall and S wall (%s)" % [_indices(c, down)])

	# Small hits add up.
	c.advance(1.0)
	for i in 5:
		c.keep.damage(20.0, c.origin, &"orbital")
	t.near(c.fraction(), 0.4, 0.001, "five small hits take 10%")
	t.check(down.size() == 6, "the 40% mark drops a sixth part")

	# At 15% every outer part is down and only the keep stands.
	c.advance(1.0)
	env.damage_radius(c.origin, 4.0, 99999.0, &"nova")
	t.near(c.fraction(), 0.15, 0.001, "another 25%")
	t.check(c.standing_parts() == 1 and not c.keep.destroyed and not fell[0], "only the keep stands at 15%")

	# The keep falls last, at 0%.
	c.advance(1.0)
	env.damage_radius(c.origin, 4.0, 99999.0, &"nova")
	t.check(c.is_fallen() and fell[0] and c.keep.destroyed and c.fraction() == 0.0, "the keep falls at 0%")
	t.check(down.size() == 9 and down[8] == c.keep, "the keep collapses last")
	t.near(reported[-1], 0.0, 0.0001, "health_changed reports the fall")
	c.advance(1.0)
	env.damage_radius(c.origin, 4.0, 99999.0, &"nova")
	t.check(down.size() == 9 and c.standing_parts() == 0, "nothing more happens after the fall")
	env.clear()
	env.free()
	c.free()


static func _indices(c: Citadel, list: Array) -> Array:
	return list.map(func(p): return c.parts.find(p))
```

Register it: add `"res://tests/test_citadel.gd",` as the last entry of `SUITES` in `tests/run_all.gd`.

Why these parts: from the blast point (-4.5, -7.2) the outer parts' distances are NW tower 1.80, W wall 1.92, SW tower 2.92, N wall 3.11, S wall 4.24, NE tower 5.90, SE tower 6.33, E wall 6.51 (keep excluded).

- [ ] **Step 2: Run the tests to see the new suite fail**

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_citadel.gd` and `checks=264 failures=1`.

- [ ] **Step 3: Create `src/game/town/citadel.gd`**

```gdscript
class_name Citadel
extends Node
## The Royal Citadel: a fortress of nine real buildings (4 corner towers, 4 curtain walls, the central keep) sharing
## one hidden health pool. It loses at most `budget_per_second` of its health in any rolling second, so no single
## strike flattens it. Every 10% lost collapses the standing outer part nearest the blow; the keep falls last, at 0%.
## Hits show before anything falls: parts shake, crack and scorch; courtyard fires start at 40% and the keep's
## banner falls at 20%.

signal health_changed(fraction: float)
## Every part as it collapses, the keep included (last).
signal part_collapsed(part: Structure)
signal fallen

## Part footprints relative to the keep's centre (ground units): NW, NE, SW, SE towers; N, S, W, E walls; keep.
const TOWERS := [Rect2(-2.7, -2.3, 1.3, 1.3), Rect2(1.4, -2.3, 1.3, 1.3), Rect2(-2.7, 1.0, 1.3, 1.3), Rect2(1.4, 1.0, 1.3, 1.3)]
const WALLS := [Rect2(-1.4, -2.2, 2.8, 0.6), Rect2(-1.4, 1.6, 2.8, 0.6), Rect2(-2.6, -1.0, 0.6, 2.0), Rect2(2.0, -1.0, 0.6, 2.0)]
const KEEP := Rect2(-1.0, -1.0, 2.0, 2.0)
const TOWER_H := 84.0
const WALL_H := 40.0
const KEEP_H := 118.0
const OUTER := 8
## Health share of each outer part; the keep holds the last 20%.
const STEP := 0.1
const FIRE_AT := 0.4
const BANNER_AT := 0.2
## Courtyard spots (relative to the keep's centre) that catch fire at FIRE_AT.
const FIRE_POINTS := [Vector2(-1.7, -1.3), Vector2(1.6, 1.3), Vector2(-1.5, 1.4)]
const FIRE_SECONDS := 120.0

var max_health := 1000.0
## Largest share of max_health lost in any rolling second.
var budget_per_second := 0.25
var health := 1000.0
## Centre of the keep, in ground units.
var origin := Vector2.ZERO
## NW, NE, SW, SE towers, then N, S, W, E walls, then the keep.
var parts: Array[Structure] = []
var keep: Structure

var _env: EnvironmentField
var _shake: CameraShake
var _clock := 0.0
## Recent losses as [time, amount] for the rolling budget.
var _window: Array = []
## 10% marks passed so far (0..OUTER).
var _marks := 0
var _fires_lit := false
var _banner_dropped := false
var _fallen := false


func setup(env: EnvironmentField, at: Vector2, shake: CameraShake = null) -> Citadel:
	_env = env
	_shake = shake
	origin = at
	health = max_health
	for r: Rect2 in TOWERS:
		_add_part(r, TOWER_H, Structure.Kind.KEEP)
	for r: Rect2 in WALLS:
		_add_part(r, WALL_H, Structure.Kind.CASTLE_WALL)
	keep = _add_part(KEEP, KEEP_H, Structure.Kind.KEEP)
	return self


func fraction() -> float:
	return health / max_health


func standing_parts() -> int:
	var n := 0
	for p in parts:
		if is_instance_valid(p) and not p.destroyed:
			n += 1
	return n


func is_fallen() -> bool:
	return _fallen


## The Citadel's clock: forgets losses older than one second. Runs in _process; tests call it directly.
func advance(delta: float) -> void:
	_clock += delta
	while not _window.is_empty() and _window[0][0] <= _clock - 1.0:
		_window.pop_front()


func _process(delta: float) -> void:
	advance(delta)


func _add_part(rel: Rect2, h: float, kind: Structure.Kind) -> Structure:
	var s := _env.add_structure(Rect2(rel.position + origin, rel.size), h, kind, &"citadel")
	s.damage_filter = _on_part_hit
	parts.append(s)
	return s


func _budget_left() -> float:
	var used := 0.0
	for e in _window:
		used += e[1]
	return max_health * budget_per_second - used


## Every hit on any part lands here instead of on the part's own health.
func _on_part_hit(part: Structure, amount: float, source: Vector2, kind: StringName) -> void:
	if _fallen:
		return
	part.mark_hit(minf(amount / part.max_hp, 1.0) * 0.25, kind)
	var loss := minf(amount, _budget_left())
	if loss <= 0.0:
		return
	_window.append([_clock, loss])
	health = maxf(health - loss, 0.0)
	if fraction() < 0.9:
		part.crack()
	health_changed.emit(fraction())
	_advance_stages(source, kind)


func _advance_stages(source: Vector2, kind: StringName) -> void:
	var f := fraction()
	while _marks < OUTER and f <= 1.0 - STEP * (_marks + 1) + 0.0001:
		_marks += 1
		var p := _nearest_standing_outer(source)
		if p != null:
			_collapse(p, source, kind)
	if f <= FIRE_AT and not _fires_lit:
		_fires_lit = true
		for spot: Vector2 in FIRE_POINTS:
			keep.ignite(Iso.ground_to_screen(origin + spot) - keep.position, FIRE_SECONDS)
	if f <= BANNER_AT and not _banner_dropped:
		_banner_dropped = true
		keep.drop_banner()
	if f <= 0.0:
		_fall(source, kind)


func _nearest_standing_outer(source: Vector2) -> Structure:
	var best: Structure = null
	var best_d := INF
	for i in OUTER:
		var p := parts[i]
		if p.destroyed:
			continue
		var d := p.distance_to(source)
		if d < best_d:
			best = p
			best_d = d
	return best


func _collapse(p: Structure, source: Vector2, kind: StringName) -> void:
	p.destroy(source, kind)
	p.dust_burst(1.0)
	if _shake != null:
		_shake.add_trauma(0.3)
	part_collapsed.emit(p)


func _fall(source: Vector2, kind: StringName) -> void:
	_fallen = true
	for i in OUTER:
		if not parts[i].destroyed:
			_collapse(parts[i], source, kind)
	keep.destroy(source, kind)
	keep.dust_burst(2.5)
	if _shake != null:
		_shake.add_trauma(0.8)
	part_collapsed.emit(keep)
	fallen.emit()
```

- [ ] **Step 4: Run the tests**

Run: `bash tools/test.sh`
Expected: `checks=279 failures=0`.

- [ ] **Step 5: Commit**

```bash
git add src/game/town/citadel.gd src/game/town/citadel.gd.uid tests/test_citadel.gd tests/test_citadel.gd.uid tests/run_all.gd
git commit -m "feat: fortified nine-part Royal Citadel" -m "Four towers, four curtain walls and the keep share one hidden health pool through their damage filter. At most 25% can go per rolling second; each 10% mark collapses the standing outer part nearest the blow, courtyard fires start at 40%, the banner falls at 20% and the keep falls last." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---
### Task 6: Town builder and town floor

**Files:**
- Create: `src/game/town/town.gd`, `src/game/town/town_floor.gd`
- Modify: `tests/run_all.gd`
- Test: `tests/test_town.gd`

**Interfaces:**
- Consumes: `TownLayout.structures()` and its rects (Task 4), `Citadel` (Task 5), `EnvironmentField.add_structure(..., role)`.
- Produces:
  - `class_name Town extends Node`: `var citadel: Citadel`, `var bridge: Structure`, `var gates: Array[Structure]`, `var floor_node: TownFloor`; `func build(env: EnvironmentField, ground: Node2D = null, shake: CameraShake = null) -> void` (adds every layout building, then the Citadel as a child node; with a `ground` plane, adds the floor as its first child so it draws under everything). Freeing or removing the Town frees its floor.
  - `class_name TownFloor extends Node2D`: drawn once in ground units under the iso ground plane (meadow, forest floor, packed earth inside the walls, cobbled streets, dirt roads outside, market and Citadel flagstones, sandy barracks yard, farm soil, river with banks) plus a `RiverGlints` child that redraws ~8 times a second.

- [ ] **Step 1: Write the failing test**

Create `tests/test_town.gd`:

```gdscript
extends RefCounted
## Town builds Aldermere into an EnvironmentField: every layout building with its role, the Citadel, and gates and
## a bridge that units can pass.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var counts := {}
	for s in env.structures():
		counts[s.role] = int(counts.get(s.role, 0)) + 1
	t.check(env.structures().size() == TownLayout.structures().size() + 9, "every layout building plus the 9 Citadel parts")
	t.check(counts.get(&"citadel", 0) == 9 and counts.get(&"house", 0) == 40 and counts.get(&"gate", 0) == 2,
		"roles carried over (%s)" % [counts])
	t.check(town.gates.size() == 2 and town.bridge != null and town.bridge.walkable, "gates and bridge found")
	t.check(town.citadel != null and town.citadel.fraction() == 1.0 and town.citadel.standing_parts() == 9, "the Citadel is intact")
	t.check(not env.blocked(Vector2(0, 8.7)) and not env.blocked(Vector2(8.7, 0)), "both gates are passable")
	t.check(not env.blocked(Vector2(0, 12.2)), "the bridge is passable")
	t.check(env.blocked(Vector2(0, -8.7)) and env.blocked(Vector2(-8.7, 3.0)), "the town walls block")
	t.check(town.floor_node == null, "no floor without a ground plane")
	var down: Array = []
	env.structure_destroyed.connect(func(s: Structure) -> void: down.append(s))
	env.damage_radius(Vector2(0, 12.2), 0.3, 99999.0, &"stone")
	t.check(town.bridge.destroyed and down == [town.bridge], "the bridge can be destroyed and reports it")
	env.clear()
	env.free()
	town.free()
```

Register it: add `"res://tests/test_town.gd",` as the last entry of `SUITES` in `tests/run_all.gd`.

- [ ] **Step 2: Run the tests to see the new suite fail**

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_town.gd` and `checks=280 failures=1`.

- [ ] **Step 3: Create `src/game/town/town_floor.gd`**

```gdscript
class_name TownFloor
extends Node2D
## Aldermere's ground, drawn once in ground units under the iso ground plane: meadow, with forest floor beyond the
## west, north and east walls; packed earth inside the walls; cobbled streets that turn into dirt roads outside;
## flagstones for the market and the Citadel court; the sandy barracks yard; farm soil; and the river. The river's
## glints are a small child node that redraws on its own, so this big drawing never has to.

## Drawn area: past the map so zoomed-out views rarely show the void.
const FILL := Rect2(-20, -20, 44, 44)
const GRASS := [Color("587a30"), Color("6a8e3a"), Color("4a6a2a")]
const FOREST := [Color("3e5a26"), Color("46632a"), Color("365020")]
const EARTH := [Color("8a7658"), Color("826e52"), Color("7a684c")]
const TRACK := [Color("7e6a50"), Color("76624a")]
const COBBLE := [Color("8a8274"), Color("958c7d"), Color("7f786c"), Color("777064")]
const FLAG := [Color("a09884"), Color("aaa18d"), Color("968e7b")]
const MORTAR := Color("4e4840")
const SAND := [Color("b09a6c"), Color("a88f62")]
const SOIL := [Color("6e5a3c"), Color("64523a")]
const WATER := Color("3a6a8a")
const WATER_DEEP := Color("2f5a78")
const BANK := Color("5a4a34")
## Tilled soil band the farm fields sit in.
const FARM_BAND := Rect2(-12, 13.4, 28, 2.4)


## Light glints drifting down the river, redrawn a few times a second for a stepped pixel flow.
class RiverGlints extends Node2D:
	const STEP := 0.12
	var _time := 0.0
	var _next := 0.0

	func _process(delta: float) -> void:
		_time += delta
		if _time >= _next:
			_next = _time + STEP
			queue_redraw()

	func _draw() -> void:
		var r := TownLayout.RIVER
		for i in 70:
			var h := (i * 7919 + 13) % 997
			var y := r.position.y + 0.15 + float(h % 61) / 61.0 * (r.size.y - 0.3)
			var x := r.position.x + fposmod(float(h) * 0.53 + _time * (0.5 + float(h % 5) * 0.1), r.size.x)
			draw_rect(Rect2(x, y, 0.3 + float(h % 3) * 0.1, 0.04), Color(0.78, 0.9, 1.0, 0.55))


func _ready() -> void:
	var glints := RiverGlints.new()
	glints.name = "RiverGlints"
	add_child(glints)


func _draw() -> void:
	_meadow()
	_fill(TownLayout.TOWN, EARTH, 0.5)
	_fill(FARM_BAND, SOIL, 0.5)
	_fill(TownLayout.BARRACKS_YARD, SAND, 0.25)
	for road: Rect2 in TownLayout.ROADS:
		_fill(road, TRACK, 0.25)
		_paving(road.intersection(TownLayout.TOWN), COBBLE, 0.25)
	_paving(TownLayout.MARKET_SQUARE, FLAG, 0.4)
	_paving(TownLayout.CITADEL_COURT, FLAG, 0.4)
	_river()


func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663)) % 997


## Grass (or darker forest floor) cell by cell with small tufts, so the ground never reads as one flat colour.
func _meadow() -> void:
	for y in range(int(FILL.position.y), int(FILL.end.y)):
		for x in range(int(FILL.position.x), int(FILL.end.x)):
			var pal: Array = FOREST if _forest(Vector2(x + 0.5, y + 0.5)) else GRASS
			draw_rect(Rect2(x, y, 1, 1), pal[_hash(x, y) % 3])
			for k in 4:
				var hk := _hash(x * 13 + k, y * 29 - k)
				var p := Vector2(x + float(hk % 89) / 89.0, y + float((hk / 89) % 83) / 83.0)
				draw_rect(Rect2(p, Vector2(0.06, 0.12)), (pal[(hk + 1) % 3] as Color).lightened(0.12))


## Forest floor beyond the walls on the west, north and east, north of the river and off the east road.
func _forest(g: Vector2) -> bool:
	if g.y > TownLayout.RIVER.position.y or (absf(g.y) < 0.8 and g.x > TownLayout.TOWN.end.x):
		return false
	var town := TownLayout.TOWN.grow(0.6)
	return g.x < town.position.x or g.y < town.position.y or g.x > town.end.x


## Tile a rect with cell-sized squares in hashed palette colours.
func _fill(r: Rect2, pal: Array, cell: float) -> void:
	var nx := int(ceilf(r.size.x / cell))
	var ny := int(ceilf(r.size.y / cell))
	var ox := int(r.position.x * 8.0)
	var oy := int(r.position.y * 8.0)
	for j in ny:
		for i in nx:
			var sq := Rect2(r.position + Vector2(i, j) * cell, Vector2(cell, cell)).intersection(r)
			draw_rect(sq, pal[_hash(i + ox, j + oy) % pal.size()])


## Stones in staggered rows with mortar gaps; every fourth stone catches the light on its top edge.
func _paving(r: Rect2, pal: Array, stone: float) -> void:
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return
	draw_rect(r, MORTAR)
	var nx := int(ceilf(r.size.x / stone)) + 1
	var ny := int(ceilf(r.size.y / stone))
	var ox := int(r.position.x * 8.0)
	var oy := int(r.position.y * 8.0)
	for j in ny:
		var shift := stone * 0.5 if j % 2 == 1 else 0.0
		for i in nx:
			var sq := Rect2(r.position + Vector2(i * stone - shift, j * stone), Vector2(stone, stone)).intersection(r).grow(-0.02)
			if sq.size.x <= 0.0 or sq.size.y <= 0.0:
				continue
			var h := _hash(i * 3 + ox, j * 5 + oy)
			var c: Color = pal[h % pal.size()]
			draw_rect(sq, c)
			if h % 4 == 0:
				draw_rect(Rect2(sq.position, Vector2(sq.size.x, 0.04)), c.lightened(0.15))


## Water across the whole drawn width (the gameplay river is the map-wide TownLayout.RIVER), deeper in the middle,
## with earthen banks.
func _river() -> void:
	var r := TownLayout.RIVER
	var x0 := FILL.position.x
	var w := FILL.size.x
	draw_rect(Rect2(x0, r.position.y, w, r.size.y), WATER)
	draw_rect(Rect2(x0, r.position.y + r.size.y * 0.3, w, r.size.y * 0.4), WATER_DEEP)
	draw_rect(Rect2(x0, r.position.y - 0.08, w, 0.08), BANK)
	draw_rect(Rect2(x0, r.end.y, w, 0.08), BANK)
```

- [ ] **Step 4: Create `src/game/town/town.gd`**

```gdscript
class_name Town
extends Node
## Builds Aldermere (TownLayout) into an EnvironmentField: every building with its role, the fortified Citadel, and
## the town floor on the battlefield's ground plane.

var citadel: Citadel
var bridge: Structure
var gates: Array[Structure] = []
## Null when built without a ground plane (headless tests).
var floor_node: TownFloor


## ground: the battlefield's ground plane, or null for no floor. shake: camera the Citadel shakes when parts fall.
func build(env: EnvironmentField, ground: Node2D = null, shake: CameraShake = null) -> void:
	for d in TownLayout.structures():
		var s := env.add_structure(d.rect, d.height, d.kind, d.role)
		if s.kind == Structure.Kind.GATE:
			gates.append(s)
		elif s.kind == Structure.Kind.BRIDGE:
			bridge = s
	citadel = Citadel.new()
	citadel.name = "Citadel"
	add_child(citadel)
	citadel.setup(env, TownLayout.CITADEL_ORIGIN, shake)
	if ground != null:
		floor_node = TownFloor.new()
		floor_node.name = "TownFloor"
		ground.add_child(floor_node)
		ground.move_child(floor_node, 0)


func _exit_tree() -> void:
	if is_instance_valid(floor_node):
		floor_node.queue_free()
```

- [ ] **Step 5: Run the tests**

Run: `bash tools/test.sh`
Expected: `checks=288 failures=0`.

- [ ] **Step 6: Commit**

```bash
git add src/game/town/town.gd src/game/town/town.gd.uid src/game/town/town_floor.gd src/game/town/town_floor.gd.uid tests/test_town.gd tests/test_town.gd.uid tests/run_all.gd
git commit -m "feat: Town builder and Aldermere floor" -m "Town adds every layout building with its role, the fortified Citadel and a procedural town floor (meadow and forest edge, packed earth, cobbled streets, dirt roads, flagstone market and Citadel court, barracks yard, farm soil, river with drifting glints)." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 7: Power book

**Files:**
- Create: `src/game/power_book.gd`
- Modify: `tests/run_all.gd`
- Test: `tests/test_power_book.gd`

**Interfaces:**
- Consumes: the 11 effect scripts; icons `assets/pixellab/icons/<key>.png` (84×84) and `assets/pixellab/icons/hud/<key>.png` (42×42).
- Produces (`class_name PowerBook extends RefCounted`):
  - `const POWERS: Array` of dictionaries `{"key": String, "name": String, "path": String, "dp": int, "cooldown": float, "aim": "click"|"drag", "shape": String}` in the spec's order (cheapest first): heaven, tornado, dragon, tsunami, gravity, laser, orbital, cinder, judgement, glacial, nova.
  - `static func get_power(key: String) -> Dictionary` (`{}` if unknown), `static func keys() -> PackedStringArray`, `static func icon(key: String) -> Texture2D`, `static func hud_icon(key: String) -> Texture2D`.

- [ ] **Step 1: Write the failing test**

Create `tests/test_power_book.gd`:

```gdscript
extends RefCounted
## The power book: 11 draftable powers with valid effect scripts, icons, costs, cooldowns and aim.


static func run(t) -> void:
	t.check(PowerBook.POWERS.size() == 11, "11 powers")
	var keys := {}
	var drag := []
	var problems: Array[String] = []
	for p: Dictionary in PowerBook.POWERS:
		if keys.has(p.key):
			problems.append("duplicate key %s" % p.key)
		keys[p.key] = true
		if not ResourceLoader.exists(p.path):
			problems.append("missing effect %s" % p.path)
		if not p.aim in ["click", "drag"]:
			problems.append("bad aim for %s" % p.key)
		if p.dp <= 0 or p.cooldown <= 0.0:
			problems.append("bad cost or cooldown for %s" % p.key)
		var big := PowerBook.icon(p.key)
		var small := PowerBook.hud_icon(p.key)
		if big == null or big.get_width() != 84 or small == null or small.get_width() != 42:
			problems.append("icon sizes for %s" % p.key)
		if p.aim == "drag":
			drag.append(p.key)
	t.check(problems.is_empty(), "power book problems: %s" % [problems])
	t.check(drag == ["heaven", "tsunami", "laser"], "drag powers (%s)" % [drag])
	var nova := PowerBook.get_power("nova")
	t.check(nova.dp == 40 and nova.cooldown == 120.0 and nova.name == "Nuclear Nova", "the nova entry")
	t.check(PowerBook.get_power("nope").is_empty(), "an unknown key gives an empty entry")
	t.check(PowerBook.keys()[0] == "heaven" and PowerBook.keys()[10] == "nova", "spec order, cheapest first")
```

Register it: add `"res://tests/test_power_book.gd",` as the last entry of `SUITES` in `tests/run_all.gd`.

- [ ] **Step 2: Run the tests to see the new suite fail**

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_power_book.gd` and `checks=289 failures=1`.

- [ ] **Step 3: Create `src/game/power_book.gd`**

```gdscript
class_name PowerBook
extends RefCounted
## The 11 draftable powers: Divine Power cost, cooldown (seconds), how they are aimed, their effect script and icons.
## Costs and cooldowns are the spec's starting values (§4.2); aim "drag" = press at the start point, drag the
## direction, release.

const POWERS := [
	{"key": "heaven", "name": "Heaven Splitter", "path": "res://src/fx/set2/heaven_splitter.gd",
		"dp": 10, "cooldown": 20.0, "aim": "drag", "shape": "line + 8 fissures"},
	{"key": "tornado", "name": "Tornado Tempest", "path": "res://src/fx/set2/tornado_tempest.gd",
		"dp": 15, "cooldown": 30.0, "aim": "click", "shape": "roaming vortex, 10 s"},
	{"key": "dragon", "name": "Dragonfire Parade", "path": "res://src/fx/set2/dragonfire_parade.gd",
		"dp": 18, "cooldown": 35.0, "aim": "click", "shape": "cone, faces down-right on screen"},
	{"key": "tsunami", "name": "Tsunami Breaker", "path": "res://src/fx/set2/tsunami_breaker.gd",
		"dp": 20, "cooldown": 40.0, "aim": "drag", "shape": "moving wall"},
	{"key": "gravity", "name": "Gravity Distortion", "path": "res://src/fx/gravity_distortion.gd",
		"dp": 20, "cooldown": 45.0, "aim": "click", "shape": "pull field"},
	{"key": "laser", "name": "Walking Laser Grid", "path": "res://src/fx/walking_laser_grid.gd",
		"dp": 22, "cooldown": 45.0, "aim": "drag", "shape": "moving lane"},
	{"key": "orbital", "name": "Orbital Strike", "path": "res://src/fx/orbital_strike.gd",
		"dp": 22, "cooldown": 45.0, "aim": "click", "shape": "random bombardment"},
	{"key": "cinder", "name": "Cinderfall Barrage", "path": "res://src/fx/set2/cinderfall_barrage.gd",
		"dp": 25, "cooldown": 50.0, "aim": "click", "shape": "volcano + stone rain"},
	{"key": "judgement", "name": "Judgement of the Ancients", "path": "res://src/fx/set2/judgement_of_the_ancients.gd",
		"dp": 30, "cooldown": 60.0, "aim": "click", "shape": "8 punches + slam"},
	{"key": "glacial", "name": "Glacial Cataclysm", "path": "res://src/fx/set2/glacial_cataclysm.gd",
		"dp": 30, "cooldown": 60.0, "aim": "click", "shape": "burst + freeze + ice"},
	{"key": "nova", "name": "Nuclear Nova", "path": "res://src/fx/nuclear_nova.gd",
		"dp": 40, "cooldown": 120.0, "aim": "click", "shape": "huge circle"},
]
const ICON_DIR := "res://assets/pixellab/icons/"


static func get_power(key: String) -> Dictionary:
	for p: Dictionary in POWERS:
		if p.key == key:
			return p
	return {}


static func keys() -> PackedStringArray:
	var out := PackedStringArray()
	for p: Dictionary in POWERS:
		out.append(p.key)
	return out


## 84x84 painted icon (Prepare cards).
static func icon(key: String) -> Texture2D:
	return load(ICON_DIR + key + ".png")


## 42x42 copy for the HUD slots.
static func hud_icon(key: String) -> Texture2D:
	return load(ICON_DIR + "hud/" + key + ".png")
```

- [ ] **Step 4: Run the tests**

Run: `bash tools/test.sh`
Expected: `checks=294 failures=0`.

- [ ] **Step 5: Commit**

```bash
git add src/game/power_book.gd src/game/power_book.gd.uid tests/test_power_book.gd tests/test_power_book.gd.uid tests/run_all.gd
git commit -m "feat: power book for the 11 draftable powers" -m "Cost, cooldown, aim, shape, effect script and icons for each power in the spec's order; a headless suite checks scripts and icons exist and the numbers are sane." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 8: Town debug scene

**Files:**
- Create: `src/game/town_debug.gd`, `scenes/town_debug.tscn`, `town.bat`
- Modify: `tools/capture.sh`, `README.md`

**Interfaces:**
- Consumes: `Battlefield` (Task 1), `Town`, `Citadel`, `TownLayout` (Tasks 4–6), `PowerBook` (Task 7), `FxTimeline.cast(script, ctx, ground, extra)`, `FxParts.prewarm`, `DummyEnemy.Look.ORC`, `EnemyField.bounds`.
- Produces: the M1 playable debug scene. Keys `1`–`9`, `0`, `-` pick `PowerBook.POWERS[0..10]`; left click casts point powers; left drag aims line powers; WASD/arrows or middle drag pan; wheel zooms (0.5–1.6); `R` rebuilds; `Esc` quits. Flags after `--`: `--capture-town`, `--citadel-test`, `--bench [--only=<key>]`. `tools/capture.sh` runs another scene when `SCENE` is set.

- [ ] **Step 1: Create the scene and its script**

`scenes/town_debug.tscn`:

```
[gd_scene format=3]

[ext_resource type="Script" path="res://src/game/town_debug.gd" id="1_town"]

[node name="TownDebug" type="Node2D"]
script = ExtResource("1_town")
```

`src/game/town_debug.gd`:

```gdscript
extends Node2D
## Milestone 1 debug scene for Kingdoms Amid Kataclysm: the town of Aldermere and its fortified Royal Citadel on the
## shared Battlefield, 40 placeholder units inside the walls, and every power castable from the keyboard. No rules,
## HUD or people yet (milestones 2 and 3).
## Flags after `--`: --capture-town (screenshots), --citadel-test (scripted strikes on the Citadel, logged),
## --bench [--only=<power key>] (frame times while that power plays beside the Citadel).

const UNIT_COUNT := 40
## Placeholder units stay inside the town walls until the people milestone gives them real brains.
const UNIT_BOUNDS := Rect2(-8.3, -8.3, 16.6, 16.6)
const PAN_SPEED := 320.0
const PAN_MIN := Vector2(-760, -380)
const PAN_MAX := Vector2(760, 520)
const ZOOM_MIN := 0.5
const ZOOM_MAX := 1.6
const DRAG_MIN := 0.5
## Keys 1-9, 0 and - pick PowerBook.POWERS[0..10].
const POWER_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0, KEY_MINUS]
const KEY_LABELS := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-"]
const CLEAR := Color("2a2e24")
## [file, ground point to look at, zoom] for --capture-town.
const TOWN_SHOTS := [
	["town_overview.png", Vector2(2, 2), 0.5],
	["town_citadel.png", Vector2(0, -5.9), 1.1],
	["town_market.png", Vector2(0, 0), 1.2],
	["town_main_gate.png", Vector2(0, 8.7), 1.1],
	["town_side_gate.png", Vector2(8.7, 0), 1.1],
	["town_river_farms.png", Vector2(1, 13), 0.8],
]
## [time, power key, ground point] for --citadel-test.
const CITADEL_CASTS := [
	[0.5, "judgement", Vector2(0, -5.9)],
	[12.0, "cinder", Vector2(-4.5, -5.0)],
	[22.0, "nova", Vector2(0, -5.9)],
	[30.0, "judgement", Vector2(0, -5.9)],
	[40.0, "nova", Vector2(0, -5.9)],
	[48.0, "orbital", Vector2(0, -5.9)],
]
const CITADEL_SHOTS := [0.3, 4.0, 9.5, 14.0, 18.0, 25.5, 33.0, 43.5, 52.0]
const CITADEL_TEST_END := 60.0

var _bf: Battlefield
var _town: Town
var _selected := 0
var _pressing := false
var _press_ground := Vector2.ZERO
var _hud: Label
var _drag_line: Node2D
var _destroyed := 0
## Game-time seconds since the scene started (follows Engine.time_scale like the effects' clocks).
var _t := 0.0


func _ready() -> void:
	RenderingServer.set_default_clear_color(CLEAR)
	_bf = Battlefield.new()
	_bf.name = "Battlefield"
	add_child(_bf)
	_bf.ctx.impact.dim_scale = 0.4
	_bf.ctx.field.look = DummyEnemy.Look.ORC
	_bf.ctx.field.bounds = UNIT_BOUNDS
	_bf.ctx.env.structure_destroyed.connect(_on_structure_destroyed)
	_drag_line = Node2D.new()
	_drag_line.name = "DragLine"
	_drag_line.z_index = 5
	_drag_line.draw.connect(_draw_drag_line)
	_bf.ground_plane.add_child(_drag_line)
	_hud = Label.new()
	_hud.position = Vector2(6, 4)
	_hud.add_theme_font_size_override("font_size", 8)
	_hud.add_theme_color_override("font_color", Color("cfd8e8"))
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 2)
	_bf.hud_layer.add_child(_hud)
	var args := OS.get_cmdline_user_args()
	var scripted := "--capture-town" in args or "--citadel-test" in args or "--bench" in args
	_rebuild(7 if scripted else Time.get_ticks_usec())
	_bf.camera.zoom = Vector2.ONE * 0.75
	_bf.camera.position = Iso.ground_to_screen(Vector2(0, -2)).round()
	await FxParts.prewarm(_bf.ctx.distort)
	if "--capture-town" in args:
		_capture_town()
	elif "--citadel-test" in args:
		_citadel_test()
	elif "--bench" in args:
		_run_bench(Battlefield.arg_value(args, "--only"))


## Fresh town: clear the battlefield, build Aldermere and its Citadel, spawn the placeholder units.
func _rebuild(seed_value: int) -> void:
	_bf.reset(seed_value)
	_destroyed = 0
	if is_instance_valid(_town):
		_town.free()
	_town = Town.new()
	_town.name = "Town"
	add_child(_town)
	_town.build(_bf.ctx.env, _bf.ground_plane, _bf.camera)
	_bf.ctx.field.spawn(UNIT_COUNT, _bf.ctx.world, _bf.rng)


func _cast(power: Dictionary, ground: Vector2, extra := {}) -> FxTimeline:
	if power.is_empty():
		push_warning("Unknown power")
		return null
	return FxTimeline.cast(load(power.path), _bf.ctx, ground, extra)


func _on_structure_destroyed(_s: Structure) -> void:
	_destroyed += 1


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var i := POWER_KEYS.find(event.physical_keycode)
		if i >= 0:
			_selected = i
		elif event.physical_keycode == KEY_R:
			_rebuild(Time.get_ticks_usec())
		elif event.physical_keycode == KEY_ESCAPE:
			_bf.quit()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		_pan(-event.relative / _bf.camera.zoom.x)
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var z := _bf.camera.zoom.x * (1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.1)
		_bf.camera.zoom = Vector2.ONE * clampf(z, ZOOM_MIN, ZOOM_MAX)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressing = true
			_press_ground = _bf.mouse_ground()
		elif _pressing:
			_pressing = false
			_drag_line.queue_redraw()
			var power: Dictionary = PowerBook.POWERS[_selected]
			var extra := {}
			if power.aim == "drag":
				var drag := _bf.mouse_ground() - _press_ground
				extra["dir"] = drag.normalized() if drag.length() >= DRAG_MIN else Vector2(1, 0)
			_cast(power, _press_ground, extra)


func _process(delta: float) -> void:
	_t += delta
	var pan := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		pan.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		pan.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		pan.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		pan.y += 1
	if pan != Vector2.ZERO:
		# Pan in real time regardless of hit-stop, faster when zoomed out.
		var real_delta := delta / maxf(Engine.time_scale, 0.001)
		_pan(pan.normalized() * PAN_SPEED * real_delta / _bf.camera.zoom.x)
	if _pressing:
		_drag_line.queue_redraw()
	_update_hud()


func _pan(by: Vector2) -> void:
	_bf.camera.position = (_bf.camera.position + by).clamp(PAN_MIN, PAN_MAX)


func _draw_drag_line() -> void:
	if not _pressing or PowerBook.POWERS[_selected].aim != "drag":
		return
	var col := Color(1, 0.35, 0.2, 0.9)
	_drag_line.draw_line(_press_ground, _bf.mouse_ground(), col, -1.0)
	_drag_line.draw_rect(Rect2(_press_ground - Vector2(0.08, 0.08), Vector2(0.16, 0.16)), col)


func _update_hud() -> void:
	if _town == null or not is_instance_valid(_town.citadel):
		return
	var power: Dictionary = PowerBook.POWERS[_selected]
	var cit := _town.citadel
	var text := "KAK town debug   [%s] %s  (%s, %d DP)\nCitadel %d%%   parts %d/9   buildings down %d\n1-9 0 - pick   LMB cast (drag: line powers)   WASD / middle-drag pan   wheel zoom   R rebuild   Esc quit" % [
		KEY_LABELS[_selected], power.name, power.aim, power.dp, roundi(cit.fraction() * 100.0), cit.standing_parts(),
		_destroyed]
	if _hud.text != text:
		_hud.text = text


# --- Scripted runs ---------------------------------------------------------

func _capture_town() -> void:
	_hud.visible = false
	for shot in TOWN_SHOTS:
		_bf.camera.zoom = Vector2.ONE * float(shot[2])
		_bf.camera.position = (Iso.ground_to_screen(shot[1]) + Vector2(0, -30)).round()
		await _bf.wait_frames(20)
		await _bf.save_capture(shot[0])
	await _bf.quit()


## Scripted strikes on the Citadel: the titan's punches, a volcano beside it, then novas, the titan again and an
## orbital strike until it falls. Logs its health every second and at each collapse, and captures key moments.
func _citadel_test() -> void:
	var cit := _town.citadel
	cit.part_collapsed.connect(_log_part)
	_bf.camera.zoom = Vector2.ONE * 0.8
	_bf.camera.position = (Iso.ground_to_screen(TownLayout.CITADEL_ORIGIN) + Vector2(0, -60)).round()
	await _bf.wait_frames(10)
	_t = 0.0
	var casts := CITADEL_CASTS.duplicate()
	var shots := CITADEL_SHOTS.duplicate()
	var next_log := 0.0
	var fall_time := -1.0
	while _t < CITADEL_TEST_END:
		while not casts.is_empty() and _t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			print("CAST %s t=%.2f" % [c[1], _t])
			_cast(PowerBook.get_power(c[1]), c[2])
		if not shots.is_empty() and _t >= float(shots[0]):
			await _bf.save_capture("citadel_%05d.png" % int(float(shots.pop_front()) * 1000.0))
		if _t >= next_log:
			next_log += 1.0
			print("CITADEL t=%.1f frac=%.2f standing=%d" % [_t, cit.fraction(), cit.standing_parts()])
		if cit.is_fallen() and fall_time < 0.0:
			fall_time = _t
			print("CITADEL FALLEN t=%.2f" % _t)
		if fall_time >= 0.0 and _t >= fall_time + 3.0:
			await _bf.save_capture("citadel_fallen.png")
			break
		await get_tree().process_frame
	print("CITADEL result fallen=%s frac=%.2f standing=%d t=%.1f" % [cit.is_fallen(), cit.fraction(), cit.standing_parts(), _t])
	await _bf.quit()


func _log_part(_p: Structure) -> void:
	var cit := _town.citadel
	print("CITADEL part down t=%.2f frac=%.2f standing=%d" % [_t, cit.fraction(), cit.standing_parts()])


func _run_bench(only: String) -> void:
	_hud.visible = false
	_bf.camera.zoom = Vector2.ONE * 0.75
	_bf.camera.position = Iso.ground_to_screen(TownLayout.CITADEL_ORIGIN).round()
	await _bf.wait_frames(10)
	if only != "":
		_cast(PowerBook.get_power(only), TownLayout.CITADEL_ORIGIN + Vector2(-3.0, 2.0), {"dir": Vector2(1, 0)})
	await _bf.bench("town-" + (only if only != "" else "idle"))
	await _bf.quit()
```

- [ ] **Step 2: Launcher and capture tool**

`town.bat` (same style as `play.bat`):

```bat
@echo off
rem Launch the KAK town debug scene (milestone 1). Override the engine path with: set GODOT=C:\path\to\Godot.exe
setlocal
if "%GODOT%"=="" set "GODOT=F:\Godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" (
	echo Godot not found at "%GODOT%".
	echo Set the GODOT environment variable to your Godot 4.7.2 executable.
	pause
	exit /b 1
)
start "" "%GODOT%" --path "%~dp0." --scene res://scenes/town_debug.tscn
```

Replace `tools/capture.sh` with:

```bash
#!/usr/bin/env bash
# Run a scene windowed with a capture/bench flag. Usage: tools/capture.sh --capture-all [--only=nova]
# Another scene: SCENE=res://scenes/town_debug.tscn tools/capture.sh --capture-town
cd "$(dirname "$0")/.."
G="${GODOT:-/f/Godot/Godot_v4.7.2-stable_win64_console.exe}"
EXTRA=()
if [[ "$*" == *--capture* || "$*" == *--citadel-test* ]]; then EXTRA=(--fixed-fps 60); fi
if [[ -n "$SCENE" ]]; then EXTRA+=(--scene "$SCENE"); fi
timeout 300 "$G" --path . --audio-driver Dummy "${EXTRA[@]}" -- "$@" 2>&1 | grep -v '^\s*at:'
exit ${PIPESTATUS[0]}
```

- [ ] **Step 3: Tests still pass; capture the town**

```bash
bash tools/test.sh
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --capture-town
```

Expected: `checks=294 failures=0`; then six `captured …/captures/town_*.png` lines and no `SCRIPT ERROR`. Open all six PNGs and check:
- `town_overview.png`: the whole walled town; Citadel upper right of centre, Main Gate lower left, Side Gate lower right; river and bridge beyond the Main Gate with farms past it; forest along the west, north and east edges; the floor draws under every building (no building half-covered by ground).
- `town_citadel.png`: four tall towers, curtain walls, a taller keep, banners, paved court.
- `town_market.png`: seven striped stalls round the crossroads, torches, cobbled streets.
- `town_main_gate.png` / `town_side_gate.png`: arch and portcullis on the outward face, walls meeting the gate, road running through.
- `town_river_farms.png`: water with banks and glints, the bridge with rails, wheat fields and two barns.
Fix layout or drawing problems before continuing (a layout change must keep Task 4's test passing).

- [ ] **Step 4: Run the scripted Citadel test**

```bash
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --citadel-test 2>&1 | grep -E "CITADEL|CAST|ERROR"
```

Expected in the log:
- `frac` never drops by more than 0.25 (allow 0.01 for frame timing) between two `CITADEL t=` lines one second apart;
- `CITADEL part down` lines arrive one or two at a time; the keep goes last (`standing=0` appears only with or after `frac=0.00`);
- `CITADEL FALLEN t=…` before t=60, then `CITADEL result fallen=true frac=0.00 standing=0`;
- no `ERROR` lines.
Open the `captures/citadel_*.png` frames: parts crumble one by one into rubble, fires burn in the courtyard once it is below 40%, the keep's banner is gone below 20%, `citadel_fallen.png` shows the whole compound as rubble. If the Citadel does not fall by t=60, report the last `frac` (the numbers are tuned in milestone 5) but the budget and order rules above must still hold.

- [ ] **Step 5: Benchmark the town**

```bash
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/town_debug.tscn --audio-driver Dummy --disable-vsync --max-fps 0 -- --bench
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/town_debug.tscn --audio-driver Dummy --disable-vsync --max-fps 0 -- --bench --only=cinder
```

Expected: one `bench[town-idle] …` and one `bench[town-cinder] …` line. Record both in the task report. Milestone 2 must reach 50+ fps with 160 people during Cinderfall; if `town-cinder` is already under 60 fps average with 40 units, say so in the report so the next plan budgets for optimisation.

- [ ] **Step 6: Update the README**

In `README.md`:

6a. After the `## Run` section's controls table (before `## Layout`), add:

````markdown
## Kingdoms Amid Kataclysm (KAK) — game slice in progress

The approved effects are becoming a one-mission game (spec: `docs/superpowers/specs/2026-09-19-kak-one-mission-game-design.md`). Milestone 1: the walled town of Aldermere and its fortified Royal Citadel, on the same `Battlefield` world the sandbox uses. Open it with `town.bat`, or:

```powershell
& $godot --path . --scene res://scenes/town_debug.tscn
```

| Input | Action |
|---|---|
| `1`–`9`, `0`, `-` | pick a power (Heaven Splitter … Nuclear Nova, cheapest first) |
| Left click | cast a point power at the cursor |
| Left drag | line powers (Heaven Splitter, Tsunami Breaker, Walking Laser Grid): press = start, drag = direction |
| `WASD` / arrows, middle drag | pan |
| Mouse wheel | zoom |
| `R` | rebuild the town |
| `Esc` | quit |

The Citadel is nine buildings on one hidden health pool: at most 25% can go per second, every 10% lost drops the part nearest the blow, and the keep falls last.

```bash
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --capture-town   # town screenshots → captures/town_*.png
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --citadel-test   # scripted strikes; logs CITADEL t= frac= standing=
```
````

6b. In the `## Layout` block, replace the line `src/sandbox/     scene assembly, input, HUD, capture/bench modes` with:

```
src/sandbox/     VFX sandbox: effect picker, floor tiles, input, HUD, camera push-in, capture/bench modes
src/game/        KAK game: Battlefield (shared world), PowerBook, town debug scene
src/game/town/   Aldermere layout, Town builder, town floor, fortified Citadel
```

and add `scenes/          sandbox.tscn (main scene), town_debug.tscn` after the `docs/superpowers` line.

6c. In `## Verify`, change `checks=217 failures=0` to `checks=294 failures=0`.

- [ ] **Step 7: Commit, tag and push**

```bash
git add src/game/town_debug.gd src/game/town_debug.gd.uid scenes/town_debug.tscn town.bat tools/capture.sh README.md
git commit -m "feat: town debug scene for casting powers on Aldermere" -m "scenes/town_debug.tscn builds the town and fortified Citadel on the shared Battlefield with 40 placeholder units; keys pick any of the 11 powers, click or drag casts. Scripted modes capture the town, strike the Citadel until it falls (logged), and bench frame times. town.bat launches it; tools/capture.sh takes a SCENE." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
git tag kak-m1-town
git -c credential.helper= -c 'credential.helper=!"/c/Program Files/GitHub CLI/gh.exe" auth git-credential' push origin feat/vfx-proof
git -c credential.helper= -c 'credential.helper=!"/c/Program Files/GitHub CLI/gh.exe" auth git-credential' push origin kak-m1-start kak-m1-town
```

- [ ] **Step 8: User checkpoint (controller)**

Show the user the six `captures/town_*.png` shots, a few `captures/citadel_*.png` frames plus `citadel_fallen.png`, the Citadel log summary and the bench numbers, and ask them to playtest with `town.bat`. Milestone 2 (people) gets its own plan once they approve.
