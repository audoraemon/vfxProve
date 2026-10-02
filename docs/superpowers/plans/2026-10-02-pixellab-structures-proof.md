# PixelLab Structures Proof Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** draw the cottage, tavern, smithy, cathedral and Citadel parts from PixelLab sprites (intact, damaged, ruins), with the collapse played in-engine, switchable live against the procedural art.

**Architecture:**
- `SpriteArt` (static) decides which structure gets which sprite set, from `assets/pixellab/buildings/manifest.json`.
- `SpriteView` (a Node2D child of a Structure) draws one still through `structure_sprite.gdshader`. The shader lights, chars and frosts the sprite, and clips it along the footprint's ground line for collapses and laser cuts.
- `Structure` keeps all its state and its random stream exactly as today. It only chooses what its views show.
- Phase 1 runs on placeholder sprites rendered from today's procedural art.
- Phase 2 replaces them with PixelLab art once the subscription is renewed.

**Tech Stack:** Godot 4.7.2 (GDScript, GL Compatibility canvas shaders), PixelLab MCP, Python 3 + Pillow for the dev scripts.

**Spec:** `docs/superpowers/specs/2026-10-02-pixellab-structures-proof-design.md`

## Global Constraints

- Work only in the worktree `F:\Godot\Git\vfxProve-pixellab`, on branch `feat/pixellab-structures`. Never commit with `-a`: stage files by name.
- Native 1:1: sprites are drawn at world-pixel size. Never scale a sprite up or down. A mirror (scale.x = −1) is the only transform besides the gravity squeeze during a fall.
- The sprite path must never draw from `Structure.rng`. The building's state with sprites on or off must be identical (Task 4's test).
- Godot: `F:\Godot\Godot_v4.7.2-stable_win64_console.exe`. Tests: `bash tools/test.sh` → `checks=N failures=0`.
- Code style: match the files around it. Tabs, `##` doc comments that explain why, typed GDScript, no trailing summaries.
- Commit messages: conventional (`feat:`, `test:`, `docs:`), ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## File map

| File | Responsibility |
|---|---|
| `assets/pixellab/buildings/manifest.json` (new) | Per sprite: canvas size, the footprint and height it was drawn for, the procedural building it replaces (kind, role, tag, seed), optional anchor override, idle frames and fps |
| `assets/pixellab/buildings/<name>/{reference,intact,damaged,ruins}.png` (new) | The reference render for PixelLab, and the three stills (placeholders first) |
| `src/environment/art/sprite_art.gd` (new) | Which structure gets which sprite; loading sets; on/off switch |
| `src/environment/art/structure_sprite.gdshader` (new) | Lighting, char, frost, glow, ground-line clip, molten cut edge |
| `src/environment/art/sprite_view.gd` (new) | One drawn still or idle frame, its shader parameters |
| `src/environment/structure.gd` (modify) | Holds `sprite`, syncs views to its state, shadow and light for sprite buildings |
| `src/game/ui/art_toggle.gd` (new), `src/game/battlefield.gd` (modify) | F7 live toggle |
| `tools/dev/render_sprite_refs.gd` (new) | Renders references and placeholders from the procedural art |
| `tools/dev/sprite_states.gd` (new) | Proof captures: each sprite through its states |
| `tools/dev/make_style_refs.py` (new) | Style crops from `TownMap_Component1.png` for PixelLab |
| `tests/test_sprite_art.gd` (new), `tests/run_all.gd` (modify) | Tests |
| `docs/pixellab_structures_log.md` (new) | Every PixelLab call: prompt, references, seed, cost, pick |

---

## Phase 1 — Engine on placeholders (no generations needed)

### Task 1: SpriteArt mapping and the manifest

**Files:**
- Create: `assets/pixellab/buildings/manifest.json`
- Create: `src/environment/art/sprite_art.gd`
- Create: `tests/test_sprite_art.gd`
- Modify: `tests/run_all.gd` (SUITES)

**Interfaces:**
- Produces:
  - `SpriteArt.on() -> bool`, `SpriteArt.set_enabled(value: bool)`;
  - `SpriteArt.manifest() -> Dictionary`, `SpriteArt.reload()`;
  - `SpriteArt.name_for(s: Structure) -> String`;
  - `SpriteArt.default_anchor(size: Vector2, fp: Vector2) -> Vector2`;
  - `SpriteArt.sprite(n: String) -> Dictionary`;
  - `SpriteArt.set_for(s: Structure) -> Dictionary`, returning `{name, stills: {&"intact", &"damaged", &"ruins": Texture2D}, idle: Texture2D|null, frames: int, fps: float, size: Vector2, footprint: Vector2, anchor: Vector2, mirror: bool}`;
  - `SpriteArt.DIR`, `SpriteArt.STILLS`.

- [ ] **Step 1: Write the failing test**

Create `tests/test_sprite_art.gd`:

```gdscript
extends RefCounted
## SpriteArt and the sprite-drawn buildings of the PixelLab structures proof.

const K := Structure.Kind
const NAMES := ["cottage_red", "cottage_blue", "tavern", "smithy", "cathedral", "citadel_keep", "citadel_tower",
	"citadel_wall", "citadel_wall_side"]


static func _make(rect: Rect2, h: float, kind: Structure.Kind, sd: int, role: StringName, tag := &"") -> Structure:
	return Structure.new().setup(rect, h, kind, sd, role, tag)


static func run(t) -> void:
	_mapping(t)
	SpriteArt.set_enabled(true)


## Which building gets which sprite, and the manifest behind them.
static func _mapping(t) -> void:
	var cases := [
		[Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, &"house", &"", "cottage"],
		[Rect2(0, 0, 1.3, 0.95), 29.0, K.HOUSE, &"house", &"townhouse", ""],
		[Rect2(0, 0, 1.3, 1.5), 20.0, K.HOUSE, &"farm", &"", ""],
		[Rect2(0, 0, 2.4, 1.5), 30.0, K.HOUSE, &"house", &"tavern", "tavern"],
		[Rect2(0, 0, 1.5, 1.25), 20.0, K.HOUSE, &"house", &"smithy", "smithy"],
		[Rect2(0, 0, 2.6, 1.5), 22.0, K.HOUSE, &"house", &"workshop", ""],
		[Rect2(0, 0, 4.2, 6.2), 56.0, K.TEMPLE, &"temple", &"cathedral", "cathedral"],
		[Rect2(0, 0, 2.0, 2.0), 118.0, K.KEEP, &"citadel", &"", "citadel_keep"],
		[Rect2(0, 0, 1.3, 1.3), 84.0, K.KEEP, &"citadel", &"", "citadel_tower"],
		[Rect2(0, 0, 1.5, 1.5), 50.0, K.KEEP, &"tower", &"", ""],
		[Rect2(0, 0, 2.8, 0.6), 40.0, K.CASTLE_WALL, &"citadel", &"", "citadel_wall"],
		[Rect2(0, 0, 0.6, 2.0), 40.0, K.CASTLE_WALL, &"citadel", &"", "citadel_wall_side"],
		[Rect2(0, 0, 1.2, 0.6), 34.0, K.CASTLE_WALL, &"wall", &"", ""],
	]
	for c in cases:
		var s := _make(c[0], c[1], c[2], 5, c[3], c[4])
		var got := SpriteArt.name_for(s)
		var want: String = c[5]
		var ok := got.begins_with("cottage_") if want == "cottage" else got == want
		t.check(ok, "sprite for %s/%s/%s is '%s' (got '%s')" % [K.keys()[c[2]], c[3], c[4], want, got])
		s.free()
	# Cottages pick a roof from their seed: stable per seed, and both roofs appear.
	var seen := {}
	for sd in 40:
		var a := _make(Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, sd, &"house")
		var b := _make(Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, sd, &"house")
		t.check(SpriteArt.name_for(a) == SpriteArt.name_for(b), "a cottage's roof is stable for its seed")
		seen[SpriteArt.name_for(a)] = true
		a.free()
		b.free()
	t.check(seen.has("cottage_red") and seen.has("cottage_blue"), "both cottage roofs appear")
	for n in NAMES:
		var m: Dictionary = SpriteArt.manifest().get(n, {})
		t.check(m.has("size") and m.has("footprint") and m.has("height") and m.has("kind") and m.has("seed"),
			"the manifest describes " + n)
	t.check(SpriteArt.default_anchor(Vector2(76, 64), Vector2(0.95, 0.75)) == Vector2(41, 60),
		"the anchor centres the footprint's diamond across the canvas, 4 px above its bottom")
```

Add `"res://tests/test_sprite_art.gd",` to `SUITES` in `tests/run_all.gd`, right after `"res://tests/test_art_tuning.gd",`.

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tools/test.sh 2>&1 | tail -5`
Expected: FAIL. The suite fails to load (`SpriteArt` is not declared) or reports `suite failed to load: res://tests/test_sprite_art.gd`.

- [ ] **Step 3: Write the manifest**

Create `assets/pixellab/buildings/manifest.json`. Sizes are today's renders plus margin. Task 2's tool fails on any canvas that clips its building.

```json
{
	"cottage_red": {"size": [76, 64], "footprint": [0.95, 0.75], "height": 17, "seed": 11, "kind": "HOUSE", "role": "house", "tag": ""},
	"cottage_blue": {"size": [76, 64], "footprint": [0.95, 0.75], "height": 17, "seed": 12, "kind": "HOUSE", "role": "house", "tag": ""},
	"tavern": {"size": [140, 128], "footprint": [2.4, 1.5], "height": 30, "seed": 13, "kind": "HOUSE", "role": "house", "tag": "tavern"},
	"smithy": {"size": [108, 104], "footprint": [1.5, 1.25], "height": 20, "seed": 14, "kind": "HOUSE", "role": "house", "tag": "smithy"},
	"cathedral": {"size": [352, 232], "footprint": [4.2, 6.2], "height": 56, "seed": 31, "kind": "TEMPLE", "role": "temple", "tag": "cathedral"},
	"citadel_keep": {"size": [140, 196], "footprint": [2.0, 2.0], "height": 118, "seed": 22, "kind": "KEEP", "role": "citadel", "tag": ""},
	"citadel_tower": {"size": [96, 140], "footprint": [1.3, 1.3], "height": 84, "seed": 23, "kind": "KEEP", "role": "citadel", "tag": ""},
	"citadel_wall": {"size": [116, 108], "footprint": [2.8, 0.6], "height": 40, "seed": 41, "kind": "CASTLE_WALL", "role": "citadel", "tag": ""},
	"citadel_wall_side": {"size": [88, 96], "footprint": [2.0, 0.6], "height": 40, "seed": 42, "kind": "CASTLE_WALL", "role": "citadel", "tag": ""}
}
```

- [ ] **Step 4: Write SpriteArt**

Create `src/environment/art/sprite_art.gd`:

```gdscript
class_name SpriteArt
extends RefCounted
## Building sprites for the PixelLab structures proof (docs/superpowers/specs/2026-10-02-pixellab-structures-proof-
## design.md): which structures are drawn from a sprite instead of their procedural art, and the sprite sets, read from
## assets/pixellab/buildings/manifest.json. A set is three stills on one canvas -- intact, damaged, ruins -- and an
## optional idle strip, all anchored at the footprint's front corner, where Structure.position sits.
##
## `-- --art=procedural` starts with the sprites off for old-vs-new captures; F7 (ArtToggle) flips them live.
##
## The manifest is read with FileAccess: an exported build must include *.json in its export filter.

const DIR := "res://assets/pixellab/buildings/"
const MANIFEST := DIR + "manifest.json"
const STILLS := [&"intact", &"damaged", &"ruins"]
## Pixels kept under the front corner, for steps, eaves and rubble spilling forward.
const FOOT_ROOM := 4.0
## ArtKit.hash01 salt for a cottage's roof.
const SALT_ROOF := 90

static var _enabled := true
static var _args_read := false
static var _manifest := {}
static var _loaded := false
## Built sprite sets by name ({} for one whose stills are missing).
static var _sets := {}


static func on() -> bool:
	if not _args_read:
		_args_read = true
		if "--art=procedural" in OS.get_cmdline_user_args():
			_enabled = false
	return _enabled


static func set_enabled(value: bool) -> void:
	_args_read = true
	_enabled = value


## The manifest's entries by sprite name: size, footprint, height, seed, kind, role, tag; optionally anchor, frames, fps.
static func manifest() -> Dictionary:
	if not _loaded:
		_loaded = true
		_manifest = {}
		if FileAccess.file_exists(MANIFEST):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
			if parsed is Dictionary:
				_manifest = parsed
	return _manifest


## Read the manifest and the stills again (the reference tool rewrites them).
static func reload() -> void:
	_loaded = false
	_sets.clear()


## The sprite that replaces `s`, or "" (only the proof's buildings have one).
static func name_for(s: Structure) -> String:
	match s.kind:
		Structure.Kind.HOUSE:
			if s.role != &"house":
				return ""
			match s.art_tag:
				&"":
					return "cottage_red" if ArtKit.hash01(s.rng.seed, SALT_ROOF) < 0.5 else "cottage_blue"
				&"tavern":
					return "tavern"
				&"smithy":
					return "smithy"
		Structure.Kind.TEMPLE:
			if s.art_tag == &"cathedral":
				return "cathedral"
		Structure.Kind.KEEP:
			# The Citadel's keep and towers share their kind and role; only their size tells them apart.
			if s.role == &"citadel":
				return "citadel_keep" if s.footprint.size.x >= 1.8 else "citadel_tower"
		Structure.Kind.CASTLE_WALL:
			if s.role == &"citadel":
				var long := maxf(s.footprint.size.x, s.footprint.size.y)
				return "citadel_wall" if long >= 2.4 else "citadel_wall_side"
	return ""


## The front corner's pixel in a sprite of `size` drawn for footprint `fp` (ground units): the footprint's diamond
## centred across the canvas, FOOT_ROOM pixels above its bottom.
static func default_anchor(size: Vector2, fp: Vector2) -> Vector2:
	return Vector2(roundf(size.x * 0.5 + 16.0 * (fp.x - fp.y)), size.y - FOOT_ROOM)


## The sprite set named `n` ({} when its stills are missing or it is not in the manifest). Shared: never edit it.
static func sprite(n: String) -> Dictionary:
	if _sets.has(n):
		return _sets[n]
	var m: Dictionary = manifest().get(n, {})
	if m.is_empty():
		return {}
	var stills := {}
	for st: StringName in STILLS:
		var path := DIR + n + "/" + String(st) + ".png"
		if not ResourceLoader.exists(path):
			push_warning("SpriteArt: missing " + path)
			_sets[n] = {}
			return {}
		stills[st] = load(path)
	var size := Vector2(m.size[0], m.size[1])
	var fp := Vector2(m.footprint[0], m.footprint[1])
	var idle_path := DIR + n + "/idle.png"
	var frames := int(m.get("frames", 1))
	var idle: Texture2D = load(idle_path) if frames > 1 and ResourceLoader.exists(idle_path) else null
	var built := {
		"name": n, "stills": stills, "size": size, "footprint": fp,
		"anchor": Vector2(m.anchor[0], m.anchor[1]) if m.has("anchor") else default_anchor(size, fp),
		"idle": idle, "frames": frames if idle != null else 1, "fps": float(m.get("fps", 8.0)), "mirror": false,
	}
	_sets[n] = built
	return built


## The sprite set drawn for `s`, or {} when sprites are off or it has none. A sprite drawn for a wide footprint stands
## mirrored on a deep one: mirroring an iso picture swaps its ground axes.
static func set_for(s: Structure) -> Dictionary:
	if not on():
		return {}
	var n := name_for(s)
	if n == "":
		return {}
	var base := sprite(n)
	if base.is_empty():
		return {}
	var out := base.duplicate()
	var fp: Vector2 = base.footprint
	out.mirror = not is_equal_approx(fp.x, fp.y) and (fp.x >= fp.y) != (s.footprint.size.x >= s.footprint.size.y)
	return out
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `bash tools/test.sh 2>&1 | tail -5`
Expected: `checks=N failures=0`, with N about 1035 + 66 (13 mapping, 40 stability, 1 both roofs, 9 manifest, 1 anchor).

- [ ] **Step 6: Commit**

```bash
git add assets/pixellab/buildings/manifest.json src/environment/art/sprite_art.gd src/environment/art/sprite_art.gd.uid tests/test_sprite_art.gd tests/test_sprite_art.gd.uid tests/run_all.gd
git commit -m "feat: SpriteArt picks which buildings the PixelLab proof draws from sprites

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
(Stage the `.uid` files only if Godot created them; `git status --short` shows them.)

### Task 2: Reference renders and placeholder stills

**Files:**
- Create: `tools/dev/render_sprite_refs.gd`
- Create (generated): `assets/pixellab/buildings/<name>/{reference,intact,damaged,ruins}.png` for the 9 names
- Modify: `tests/test_sprite_art.gd` (add `_sets`)

**Interfaces:**
- Consumes: `SpriteArt.manifest()`, `SpriteArt.default_anchor()`, `SpriteArt.set_enabled()`, `SpriteArt.DIR`.
- Produces: the stills that `SpriteArt.sprite(n)` loads.

- [ ] **Step 1: Write the failing test**

In `tests/test_sprite_art.gd`, add `_sets(t)` to `run()` after `_mapping(t)`, and add:

```gdscript
## Every set loads: three stills on the manifest's canvas, mirrored only on the other footprint orientation.
static func _sets(t) -> void:
	SpriteArt.set_enabled(true)
	for n in NAMES:
		var sp := SpriteArt.sprite(n)
		t.check(not sp.is_empty(), "the %s set loads" % n)
		if sp.is_empty():
			continue
		for st in SpriteArt.STILLS:
			var tex: Texture2D = sp.stills[st]
			t.check(Vector2(tex.get_size()) == sp.size, "%s/%s is %s" % [n, st, sp.size])
	var wide := _make(Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, 5, &"house")
	var deep := _make(Rect2(0, 0, 0.75, 0.95), 17.0, K.HOUSE, 5, &"house")
	var side := _make(Rect2(0, 0, 0.6, 2.0), 40.0, K.CASTLE_WALL, 5, &"citadel")
	var keep := _make(Rect2(0, 0, 2.0, 2.0), 118.0, K.KEEP, 5, &"citadel")
	t.check(not SpriteArt.set_for(wide).mirror and SpriteArt.set_for(deep).mirror, "a deep cottage is the wide one mirrored")
	t.check(SpriteArt.set_for(side).mirror and not SpriteArt.set_for(keep).mirror,
		"a west or east wall is mirrored, the square keep never")
	SpriteArt.set_enabled(false)
	t.check(SpriteArt.set_for(wide).is_empty(), "with sprites off nothing gets a set")
	SpriteArt.set_enabled(true)
	for s in [wide, deep, side, keep]:
		s.free()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tools/test.sh 2>&1 | tail -12`
Expected: FAIL lines `the cottage_red set loads` (and the other eight), plus `SpriteArt: missing res://assets/pixellab/buildings/cottage_red/intact.png` warnings.

- [ ] **Step 3: Write the render tool**

Create `tools/dev/render_sprite_refs.gd`:

```gdscript
extends SceneTree
## Dev tool (PixelLab structures proof): for every sprite in assets/pixellab/buildings/manifest.json, render today's
## procedural building on that sprite's canvas, anchored where SpriteArt anchors the sprite, in neutral light, without
## its ground shadow (the Structure draws that):
##   reference.png -- intact; the composition reference handed to PixelLab;
##   with --placeholders also intact.png, damaged.png (cracked, scorched) and ruins.png (collapsed), the stand-ins until
##   PixelLab's sprites replace them.
## Exits 1 if a render touches its canvas edge: grow that sprite's "size" in the manifest and run it again.
## Usage: godot --path . --audio-driver Dummy -s tools/dev/render_sprite_refs.gd -- [--placeholders]

const BG := Color(1, 0, 1)
## Where the front corner lands on the 640x360 screen: low and centred, so the tallest canvas fits above it.
const SCREEN_AT := Vector2(320, 340)
## The footprint's far end: a whole number on both axes puts the front corner on a whole pixel.
const END := Vector2(3, 3)

var _cam: Camera2D
var _world: Node2D
var _lights: LightField
var _bad := 0


func _init() -> void:
	RenderingServer.set_default_clear_color(BG)
	SpriteArt.set_enabled(false)
	Structure.wind = 0.0
	var root2 := Node2D.new()
	get_root().add_child(root2)
	# The only camera, so it is current once the tree runs.
	_cam = Camera2D.new()
	root2.add_child(_cam)
	_world = Node2D.new()
	root2.add_child(_world)
	_lights = LightField.new()
	root2.add_child(_lights)
	var shots := {"reference": &"intact"}
	if "--placeholders" in OS.get_cmdline_user_args():
		shots = {"reference": &"intact", "intact": &"intact", "damaged": &"damaged", "ruins": &"ruins"}
	var m := SpriteArt.manifest()
	for n: String in m:
		var e: Dictionary = m[n]
		var dir := ProjectSettings.globalize_path(SpriteArt.DIR + n)
		DirAccess.make_dir_recursive_absolute(dir)
		var size := Vector2i(int(e.size[0]), int(e.size[1]))
		var fp := Vector2(e.footprint[0], e.footprint[1])
		var anchor := SpriteArt.default_anchor(Vector2(size), fp)
		for file: String in shots:
			var s := Structure.new().setup(Rect2(END - fp, fp), float(e.height), Structure.Kind[e.kind], int(e.seed),
				StringName(e.role), StringName(e.get("tag", "")))
			s.lights = _lights
			_world.add_child(s)
			_pose(s, shots[file])
			var img: Image = await _shoot(s, anchor, size)
			s.free()
			if _touches_edge(img):
				printerr("CLIPPED: %s/%s touches its %dx%d canvas; grow its size" % [n, file, size.x, size.y])
				_bad += 1
			img.save_png(dir.path_join(file + ".png"))
			print("rendered ", n, "/", file)
	root2.queue_free()
	await process_frame
	quit(1 if _bad > 0 else 0)


## A fresh building put into the state a still shows.
func _pose(s: Structure, state: StringName) -> void:
	match state:
		&"damaged":
			s.crack()
			s.scorch = 0.35
		&"ruins":
			s.destroy(s.center() + Vector2(3, 3), &"stone")
			for i in 90:
				s._process(1.0 / 60.0)


func _shoot(s: Structure, anchor: Vector2, size: Vector2i) -> Image:
	# The camera's centre is the screen's (320, 180): put the front corner (the node's position) at SCREEN_AT.
	_cam.position = s.position - (SCREEN_AT - Vector2(320, 180))
	for f in 6:
		await process_frame
	_hide_glows(s)
	await process_frame
	var shot := get_root().get_texture().get_image()
	var img := shot.get_region(Rect2i(Vector2i(SCREEN_AT - anchor), size))
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			# The background, and the ground shadow over it (magenta darkened): both go transparent.
			if c.g < 0.02 and absf(c.r - c.b) < 0.02 and c.r > 0.5:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return img


func _touches_edge(img: Image) -> bool:
	var w := img.get_width()
	var h := img.get_height()
	for x in w:
		if img.get_pixel(x, 0).a > 0.0 or img.get_pixel(x, h - 1).a > 0.0:
			return true
	for y in h:
		if img.get_pixel(0, y).a > 0.0 or img.get_pixel(w - 1, y).a > 0.0:
			return true
	return false


func _hide_glows(n: Node) -> void:
	for c in n.get_children():
		if c is QuadFx:
			c.visible = false
		_hide_glows(c)
```

- [ ] **Step 4: Render the references and placeholders**

Run: `"/f/Godot/Godot_v4.7.2-stable_win64_console.exe" --path . --audio-driver Dummy -s tools/dev/render_sprite_refs.gd -- --placeholders 2>&1 | grep -v '^\s*at:' | tail -40`
Expected: `rendered <name>/<file>` for 9 names × 4 files, and exit 0.
- **On `CLIPPED: ...`:** grow that name's `size` in `manifest.json` by 8 on the clipped axis and run it again.
- Then open three renders (`cottage_red/intact.png`, `cathedral/reference.png`, `citadel_keep/ruins.png`) with the Read tool. Check the building sits whole on transparency with no magenta fringe.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `bash tools/test.sh 2>&1 | tail -5`
Expected: `checks=N failures=0`. The import inside test.sh picks up the new PNGs.

- [ ] **Step 6: Commit**

```bash
git add tools/dev/render_sprite_refs.gd assets/pixellab/buildings tests/test_sprite_art.gd
git commit -m "feat: reference renders and placeholder stills for the PixelLab sprites

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 3: The sprite shader and SpriteView

**Files:**
- Create: `src/environment/art/structure_sprite.gdshader`
- Create: `src/environment/art/sprite_view.gd`
- Modify: `tests/test_sprite_art.gd` (add `_view`)

**Interfaces:**
- Consumes: a set from `SpriteArt.sprite()` / `SpriteArt.set_for()`.
- Produces:
  - `SpriteView.setup(sprite_set: Dictionary, left: Vector2, right: Vector2) -> SpriteView`;
  - `show_still(st: StringName, frame_index := 0)`, `set_color(c: Color)`, `set_cut(mode: int, lift: float, molten := 0.0)`, `set_light(light: Color, ambient: float, scorch: float, frost: float, tint: Color)`;
  - consts `KEEP_ALL = 0`, `KEEP_ABOVE = 1`, `KEEP_BELOW = -1`;
  - read-only fields `still`, `frame`, `color`.

- [ ] **Step 1: Write the failing test**

In `tests/test_sprite_art.gd`, add `_view(t)` to `run()` after `_sets(t)`, and add:

```gdscript
## A view shows one still, mirrors with its set, and carries the footprint's corners into the sprite's own pixels.
static func _view(t) -> void:
	var sp := SpriteArt.sprite("cottage_red")
	var left := Vector2(-30.4, -15.2)
	var right := Vector2(24.0, -12.0)
	var v := SpriteView.new().setup(sp, left, right)
	var mat := v.material as ShaderMaterial
	t.check(v.scale == Vector2.ONE and mat.get_shader_parameter("anchor") == sp.anchor, "a view anchors its sprite")
	t.check(mat.get_shader_parameter("corner_left") == left and mat.get_shader_parameter("corner_right") == right,
		"and knows its footprint's corners")
	v.show_still(&"damaged")
	t.check(v.still == &"damaged" and v.frame == 0, "it shows the still it is given")
	v.set_cut(SpriteView.KEEP_BELOW, 12.0, 0.5)
	t.check(mat.get_shader_parameter("cut_mode") == -1 and is_equal_approx(mat.get_shader_parameter("cut_lift"), 12.0),
		"a cut is the shader's to draw")
	v.free()
	var mirrored := sp.duplicate()
	mirrored.mirror = true
	# A deep cottage's corners (0.75 x 0.95): mirrored, they are the wide sprite's own again.
	var m := SpriteView.new().setup(mirrored, Vector2(-24.0, -12.0), Vector2(30.4, -15.2))
	var mm := m.material as ShaderMaterial
	t.check(m.scale.x == -1.0, "a mirrored set flips its view")
	t.check(mm.get_shader_parameter("corner_left") == left and mm.get_shader_parameter("corner_right") == right,
		"and sees the deep footprint as the wide one it was drawn for")
	m.free()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tools/test.sh 2>&1 | tail -5`
Expected: the suite fails to load (`SpriteView` not declared).

- [ ] **Step 3: Write the shader**

Create `src/environment/art/structure_sprite.gdshader`:

```glsl
shader_type canvas_item;
// A building sprite (SpriteView), lit as structure_art.gdshader lights the procedural art, but with one even facing:
// a sprite has no per-face normals. Bright warm pixels (lit windows, a forge) glow: they skip the dim, the light and
// the char. cut_mode clips the sprite along its footprint's front ground line raised by cut_lift (sprite px): 1 keeps
// what is above the line (a building sinking into the ground, a sliced-off top), -1 what is below (the stump), whose
// top edge glows molten while `molten` lasts.

uniform vec3 light_col = vec3(0.0);
uniform float ambient = 1.0;
uniform float scorch = 0.0;
uniform float frost = 0.0;
// The world's light colour (LightField.tint).
uniform vec3 tint = vec3(1.0);
uniform int cut_mode = 0;
uniform float cut_lift = 0.0;
uniform float molten = 0.0;
// The drawn frame's top-left in the texture (px), the footprint's front corner within the frame (px), and the
// footprint's left and right corners relative to that front corner (px, the sprite's own unmirrored space).
uniform vec2 frame_origin = vec2(0.0);
uniform vec2 anchor = vec2(0.0);
uniform vec2 corner_left = vec2(-32.0, -16.0);
uniform vec2 corner_right = vec2(32.0, -16.0);

const vec3 CHAR = vec3(0.078431, 0.066667, 0.070588);
const vec3 FROST = vec3(0.62, 0.78, 0.92);
const vec3 MOLTEN = vec3(1.0, 0.690196, 0.25098);
// The procedural art's facing is 0.35 away from a light and up to 1.25 toward it; a sprite takes the middle.
const float FACING = 0.62;

// The footprint's front edges: down from the left corner to the front corner, up to the right one; flat beyond.
float ground_y(float x) {
	if (x < 0.0) {
		return corner_left.y * clamp(x / corner_left.x, 0.0, 1.0);
	}
	return corner_right.y * clamp(x / corner_right.x, 0.0, 1.0);
}

bool glows(vec3 c) {
	return c.r > 0.85 && c.g > 0.5 && c.b < 0.55 && c.r - c.b > 0.4;
}

void fragment() {
	vec4 px = texture(TEXTURE, UV);
	vec2 p = floor(UV / TEXTURE_PIXEL_SIZE) + 0.5 - frame_origin - anchor;
	float line = ground_y(p.x) - cut_lift;
	if ((cut_mode == 1 && p.y > line) || (cut_mode == -1 && p.y < line)) {
		discard;
	}
	vec3 c = px.rgb;
	if (!glows(c)) {
		vec3 lit = light_col * FACING;
		lit = lit / (1.0 + lit);
		float lum = dot(c, vec3(0.2126, 0.7152, 0.0722));
		float head = 1.0 - lum;
		float t = clamp((lum - 0.25) / 0.4, 0.0, 1.0);
		float gain = mix(4.0, 1.2, t) * head;
		float add = mix(0.35, 0.12, t) * head;
		c = min(c * ambient * (1.0 + lit * gain) + lit * add, vec3(1.0));
		c = mix(c, CHAR, scorch * 0.65);
		c = mix(c, FROST, frost * 0.35) * tint;
	}
	if (cut_mode == -1 && p.y < line + 2.0) {
		c = mix(c, MOLTEN, molten);
	}
	COLOR = vec4(c, px.a) * COLOR;
}
```

- [ ] **Step 4: Write SpriteView**

Create `src/environment/art/sprite_view.gd`:

```gdscript
class_name SpriteView
extends Node2D
## One building sprite (SpriteArt) on a Structure: a still, or a frame of its idle strip, drawn with the footprint's
## front corner at this node's origin through structure_sprite.gdshader, which lights, chars and frosts it like the
## procedural art and clips it along the footprint's ground line for a collapse or a laser cut. A deep footprint shows a
## wide sprite mirrored (scale.x = -1); the clip works in the sprite's own pixels, so it mirrors with it.

const SHADER := preload("res://src/environment/art/structure_sprite.gdshader")
## Clip modes (the shader's cut_mode): everything, what is above the cut line, or what is below it.
const KEEP_ALL := 0
const KEEP_ABOVE := 1
const KEEP_BELOW := -1

var sprite := {}
var still := &"intact"
var frame := 0
## The draw's modulate: the blight's tint, a fade.
var color := Color.WHITE
var _mat: ShaderMaterial


## `left` and `right`: the footprint's left and right corners relative to its front corner, in the structure's space
## (Structure._s[3] and _s[1]).
func setup(sprite_set: Dictionary, left: Vector2, right: Vector2) -> SpriteView:
	sprite = sprite_set
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material = _mat
	var m := -1.0 if sprite.mirror else 1.0
	scale = Vector2(m, 1.0)
	# In the sprite's own pixels a mirrored right corner is the left one.
	var a := Vector2(left.x * m, left.y)
	var b := Vector2(right.x * m, right.y)
	_mat.set_shader_parameter("corner_left", a if a.x < b.x else b)
	_mat.set_shader_parameter("corner_right", b if a.x < b.x else a)
	_mat.set_shader_parameter("anchor", sprite.anchor)
	return self


## Show `st` (&"intact", &"damaged", &"ruins"). The intact still plays its idle strip's `frame_index` when the set
## has one. Redraws only on a change.
func show_still(st: StringName, frame_index := 0) -> void:
	var f := frame_index % int(sprite.frames) if st == &"intact" and sprite.idle != null else 0
	if st == still and f == frame:
		return
	still = st
	frame = f
	queue_redraw()


func set_color(c: Color) -> void:
	if c != color:
		color = c
		queue_redraw()


## Clip along the ground line raised by `lift` px (see the shader); `molten` lights a stump's cut edge.
func set_cut(mode: int, lift: float, molten := 0.0) -> void:
	_mat.set_shader_parameter("cut_mode", mode)
	_mat.set_shader_parameter("cut_lift", lift)
	_mat.set_shader_parameter("molten", molten)


func set_light(light: Color, ambient: float, scorch: float, frost: float, tint: Color) -> void:
	_mat.set_shader_parameter("light_col", Vector3(light.r, light.g, light.b))
	_mat.set_shader_parameter("ambient", ambient)
	_mat.set_shader_parameter("scorch", scorch)
	_mat.set_shader_parameter("frost", frost)
	_mat.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))


func _draw() -> void:
	var size: Vector2 = sprite.size
	var at: Vector2 = sprite.anchor
	var strip := still == &"intact" and sprite.idle != null
	var tex: Texture2D = sprite.idle if strip else sprite.stills[still]
	var origin := Vector2(frame * size.x, 0.0)
	_mat.set_shader_parameter("frame_origin", origin)
	draw_texture_rect_region(tex, Rect2(-at, size), Rect2(origin, size), color)
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `bash tools/test.sh 2>&1 | tail -5`
Expected: `checks=N failures=0`, and no shader compile error in the output. The view only builds its material headless, so also run `"/f/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --quit 2>&1 | grep -i shader`. Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add src/environment/art/structure_sprite.gdshader src/environment/art/sprite_view.gd tests/test_sprite_art.gd
git commit -m "feat: SpriteView draws a building sprite lit, charred and clipped at its ground line

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
(Add the `.uid` files Godot made for the new script and shader.)

### Task 4: Structures drawn from sprites

**Files:**
- Modify: `src/environment/structure.gd`
- Modify: `tests/test_sprite_art.gd` (add `_structure`, `_battered`)

**Interfaces:**
- Consumes: `SpriteArt.set_for()`, `SpriteView.*`.
- Produces:
  - `Structure.sprite: Dictionary`;
  - `Structure.sprite_state() -> StringName` (`&""`, `&"intact"`, `&"damaged"`, `&"falling"`, `&"cut"`, `&"ruins"`);
  - `Structure.refresh_sprite()`.

- [ ] **Step 1: Write the failing test**

In `tests/test_sprite_art.gd`, add `_structure(t)` to `run()` after `_view(t)`, and add:

```gdscript
## A sprite building goes intact -> damaged -> falling -> ruins (or cut, under a laser), and back on a rebuild; its
## view box holds the whole sprite; and sprites change only what is drawn.
static func _structure(t) -> void:
	SpriteArt.set_enabled(true)
	var cot := _make(Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, 5, &"house")
	t.check(not cot.sprite.is_empty() and cot.sprite_state() == &"intact", "a cottage stands as its intact sprite")
	cot.damage(cot.max_hp * 0.4, Vector2(-5, -5), &"blast")
	t.check(cot.sprite_state() == &"damaged", "cracked under 65%, it shows the damaged sprite")
	cot.destroy(Vector2(-5, -5), &"blast")
	t.check(cot.sprite_state() == &"falling", "a blast brings it down")
	for i in 90:
		cot._process(1.0 / 60.0)
	t.check(cot.sprite_state() == &"ruins", "and leaves its ruins")
	cot.restore()
	for i in 2:
		cot._process(1.0 / 60.0)
	t.check(cot.sprite_state() == &"intact", "rebuilt, it stands intact again")
	cot.free()
	var tav := _make(Rect2(0, 0, 2.4, 1.5), 30.0, K.HOUSE, 6, &"house", &"tavern")
	tav.destroy(Vector2(-5, -5), &"laser")
	t.check(tav.sprite_state() == &"cut", "a laser slices a tall building")
	tav.free()
	var cat := _make(Rect2(0, 0, 4.2, 6.2), 56.0, K.TEMPLE, 7, &"temple", &"cathedral")
	var at: Vector2 = cat.sprite.anchor
	t.check(cat.view_box().encloses(Rect2(cat.base_position() - at, cat.sprite.size)),
		"the view box holds the whole sprite")
	cat.free()
	var proc := _make(Rect2(0, 0, 1.3, 0.95), 29.0, K.HOUSE, 8, &"house", &"townhouse")
	t.check(proc.sprite.is_empty() and proc.sprite_state() == &"", "a building without a sprite keeps its art")
	proc.free()
	t.check(_battered(true) == _battered(false), "sprites on or off, the same hits leave the same buildings")
	SpriteArt.set_enabled(true)


## The proof's buildings put through the same hits, with sprites on or off: their state, as text.
static func _battered(sprites: bool) -> String:
	SpriteArt.set_enabled(sprites)
	var rows := PackedStringArray()
	var specs := [
		[Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, &"house", &"", &"blast"],
		[Rect2(0, 0, 0.75, 0.95), 18.0, K.HOUSE, &"house", &"", &"gravity"],
		[Rect2(0, 0, 2.4, 1.5), 30.0, K.HOUSE, &"house", &"tavern", &"laser"],
		[Rect2(0, 0, 1.5, 1.25), 20.0, K.HOUSE, &"house", &"smithy", &"ice"],
		[Rect2(0, 0, 4.2, 6.2), 56.0, K.TEMPLE, &"temple", &"cathedral", &"stone"],
		[Rect2(0, 0, 2.0, 2.0), 118.0, K.KEEP, &"citadel", &"", &"nova"],
	]
	for i in specs.size():
		var c: Array = specs[i]
		var s := _make(c[0], c[1], c[2], 100 + i, c[3], c[4])
		s.damage(s.max_hp * 0.3, Vector2(-4, -4), c[5])
		s.damage(s.max_hp * 0.3, Vector2(-4, -4), c[5])
		for f in 20:
			s._process(1.0 / 60.0)
		s.damage(s.max_hp, Vector2(-4, -4), c[5])
		for f in 90:
			s._process(1.0 / 60.0)
		var rubble := 0.0
		for r in s._rubble:
			for p in r[0]:
				rubble += p.x * 1.7 + p.y * 2.3
		rows.append("%s hp=%.2f h=%.2f sc=%.3f fr=%.3f cr=%d rub=%.3f col=%.3f st=%d pos=%s" % [s.tuning_key(), s.hp,
			s.height, s.scorch, s.frost, s._cracks.size(), rubble, s._collapse, s.rng.state, s.position])
		s.free()
	return "\n".join(rows)
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tools/test.sh 2>&1 | tail -5`
Expected: the suite fails to load (`sprite_state` not a member of Structure).

- [ ] **Step 3: Add the state and the views to Structure**

In `src/environment/structure.gd`, after the `art_tag` declaration (the `var art_tag := &""` line and its comment), add:

```gdscript
## Sprite set from setup() (SpriteArt.set_for, the PixelLab proof): when it has one, the building is drawn from it by
## its SpriteViews instead of its procedural art. Only the drawing changes; its state and rng stream never do.
var sprite := {}
## Its sprite's views: the building; its ruins, under it while it falls and after; a top a laser sliced off.
var _sprite_view: SpriteView
var _ruins_view: SpriteView
var _top_view: SpriteView
## The last light handed to the views [light, ambient, world tint], for views made after it (the ruins, a top).
var _sprite_light := [Color.BLACK, 1.0, Color.WHITE]
```

In `setup()`, after `art = ArtKit.plan_for(self)` and before `return self`:

```gdscript
	sprite = SpriteArt.set_for(self)
	_grow_view_box_for_sprite()
```

At the end of `_ready()`:

```gdscript
	if not sprite.is_empty():
		_sync_sprite()
```

In `_process()`, change the two visibility lines so a sprite building hides the procedural banner and flames (its sprite has its own):
- `_banner.visible = not destroyed` becomes `_banner.visible = not destroyed and sprite.is_empty()`;
- `_flame.visible = not destroyed` becomes `_flame.visible = not destroyed and sprite.is_empty()`.

In `_process()`, directly before `var shake_step := int(_time * SHAKE_HZ) if _shake > 0.0 else -1`, add:

```gdscript
	if not sprite.is_empty():
		_sync_sprite()
```

In `_can_idle()`, append to the returned expression: `and (sprite.is_empty() or int(sprite.frames) <= 1)`. A sprite with an idle strip keeps stepping.

In `_draw()`, directly after `var dir := lights.sample_dir(center()) if lights else Vector2.ZERO`, add:

```gdscript
	if not sprite.is_empty():
		_draw_sprite_frame(light)
		return
```

Then add these functions after `restore()`:

```gdscript
## Re-read the sprite set (SpriteArt turned on or off, ArtToggle) and redraw either way.
func refresh_sprite() -> void:
	sprite = SpriteArt.set_for(self)
	_grow_view_box_for_sprite()
	for v in [_sprite_view, _ruins_view, _top_view]:
		if is_instance_valid(v):
			v.queue_free()
	_sprite_view = null
	_ruins_view = null
	_top_view = null
	wake()
	_dirty = true
	queue_redraw()


## What a sprite building shows now: &"intact", &"damaged" (cracked), &"falling" (collapsing), &"cut" (a laser's stump;
## only a laser leaves a building destroyed without a collapse) or &"ruins"; &"" without a sprite.
func sprite_state() -> StringName:
	if sprite.is_empty():
		return &""
	if destroyed:
		if _collapse < 0.0:
			return &"cut"
		return &"falling" if _collapse < 1.0 else &"ruins"
	return &"intact" if _cracks.is_empty() else &"damaged"


## Its view box takes in the whole sprite: a spire or a chimney can rise above the procedural box.
func _grow_view_box_for_sprite() -> void:
	if sprite.is_empty():
		return
	var size: Vector2 = sprite.size
	var at: Vector2 = sprite.anchor
	var x0 := _base.x - (size.x - at.x if sprite.mirror else at.x)
	_view_box = _view_box.merge(Rect2(Vector2(x0, _base.y - at.y), size).grow(VIEW_BOX_MARGIN))


## Points the views at what the building shows now (sprite_state()): standing, damaged, sinking into the ground (gravity
## squeezes it inward as it goes) over its ruins, sliced by a laser with the top sliding off, or its ruins. Setters
## that change nothing redraw nothing, so this runs every processed frame.
func _sync_sprite() -> void:
	var state := sprite_state()
	if not is_instance_valid(_sprite_view):
		_sprite_view = _new_view()
	var ruins := state == &"falling" or state == &"ruins"
	if ruins and not is_instance_valid(_ruins_view):
		_ruins_view = _new_view()
		move_child(_ruins_view, _sprite_view.get_index())
		_ruins_view.show_still(&"ruins")
	elif not ruins and is_instance_valid(_ruins_view):
		_ruins_view.queue_free()
		_ruins_view = null
	if is_instance_valid(_ruins_view):
		_ruins_view.set_color(Color(self_modulate, clampf(_collapse * 3.0, 0.0, 1.0)))
	var m := -1.0 if sprite.mirror else 1.0
	_sprite_view.visible = state != &"ruins"
	_sprite_view.set_color(self_modulate)
	match state:
		&"intact", &"damaged":
			_sprite_view.show_still(state, int(_time * float(sprite.fps)))
			_sprite_view.position = Vector2.ZERO
			_sprite_view.scale = Vector2(m, 1.0)
			_sprite_view.set_cut(SpriteView.KEEP_ALL, 0.0)
		&"falling":
			var k := _collapse * _collapse
			var at: Vector2 = sprite.anchor
			var sink := roundf(k * at.y)
			var squeeze := 1.0 - 0.35 * k if destroy_kind == &"gravity" else 1.0
			_sprite_view.show_still(&"damaged")
			_sprite_view.position = Vector2(0.0, sink)
			_sprite_view.scale = Vector2(m * squeeze, 1.0)
			_sprite_view.set_cut(SpriteView.KEEP_ABOVE, sink)
		&"cut":
			_sprite_view.show_still(&"damaged")
			_sprite_view.position = Vector2.ZERO
			_sprite_view.scale = Vector2(m, 1.0)
			_sprite_view.set_cut(SpriteView.KEEP_BELOW, height, _molten)
	var top := state == &"cut" and not _top_piece.is_empty()
	if top and not is_instance_valid(_top_view):
		_top_view = _new_view()
		_top_view.show_still(&"damaged")
		_top_view.set_cut(SpriteView.KEEP_ABOVE, float(_top_piece.h0))
	elif not top and is_instance_valid(_top_view):
		_top_view.queue_free()
		_top_view = null
	if is_instance_valid(_top_view):
		_top_view.position = ((_top_piece.off as Vector2) + Vector2(0.0, float(_top_piece.fall))).round()
		var gone := clampf(float(_top_piece.fall) / (float(_top_piece.h0) + 4.0), 0.0, 1.0)
		_top_view.set_color(Color(self_modulate, 1.0 - gone))


func _new_view() -> SpriteView:
	var v := SpriteView.new().setup(sprite, _s[3], _s[1])
	v.set_light(_sprite_light[0], _sprite_light[1], scorch, frost, _sprite_light[2])
	add_child(v)
	return v


## A sprite building's own drawing: its ground shadow while it stands, and the light handed to its views (they draw
## the sprite; see _sync_sprite()).
func _draw_sprite_frame(light: Color) -> void:
	if not destroyed:
		_quad(_shadow(), SHADOW)
	var amb := lights.ambient if lights else 1.0
	var t := lights.tint if lights else Color.WHITE
	_sprite_light = [light, amb, t]
	for v in [_sprite_view, _ruins_view, _top_view]:
		if is_instance_valid(v):
			v.set_light(light, amb, scorch, frost, t)
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tools/test.sh 2>&1 | tail -5`
Expected: `checks=N failures=0`.

- [ ] **Step 5: Check the sandbox digest is unchanged**

Run on both trees and compare the last line. In this worktree:
`"/f/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless --path . -s tools/dev/state_digest.gd 2>&1 | tail -1`
Then the same with `-- --art=procedural` appended.
Expected: the same digest line both times. The sandbox has no sprite buildings, so this guards against side effects of the new code in setup.

- [ ] **Step 6: Commit**

```bash
git add src/environment/structure.gd tests/test_sprite_art.gd
git commit -m "feat: proof buildings draw from their sprites, collapsing and slicing in-engine

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 5: F7 live toggle

**Files:**
- Create: `src/game/ui/art_toggle.gd`
- Modify: `src/game/battlefield.gd` (after the FpsMeter block, ~line 118)
- Modify: `tests/test_sprite_art.gd` (add `_toggle`)

**Interfaces:**
- Consumes: `SpriteArt.on()`, `SpriteArt.set_enabled()`, `Structure.refresh_sprite()`, `EnvironmentField.structures()`.
- Produces: `ArtToggle` (Node) with `env: EnvironmentField` and `toggle()`.

- [ ] **Step 1: Write the failing test**

In `tests/test_sprite_art.gd`, add `_toggle(t)` to `run()` after `_structure(t)`, and add:

```gdscript
## F7 turns every building's sprite off and on again.
static func _toggle(t) -> void:
	SpriteArt.set_enabled(true)
	var env := EnvironmentField.new()
	var s := env.add_structure(Rect2(0, 0, 1.5, 1.25), 20.0, K.HOUSE, &"house", &"smithy")
	t.check(not s.sprite.is_empty(), "the smithy starts as a sprite")
	var toggle := ArtToggle.new()
	toggle.env = env
	toggle.toggle()
	t.check(not SpriteArt.on() and s.sprite.is_empty(), "F7 turns the sprites off for every building")
	toggle.toggle()
	t.check(SpriteArt.on() and s.sprite.name == "smithy", "and on again")
	toggle.free()
	env.clear()
	env.free()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tools/test.sh 2>&1 | tail -5`
Expected: the suite fails to load (`ArtToggle` not declared).

- [ ] **Step 3: Write ArtToggle and add it to the Battlefield**

Create `src/game/ui/art_toggle.gd`:

```gdscript
class_name ArtToggle
extends Node
## F7 flips the buildings between their PixelLab sprites and the procedural art (SpriteArt), live, for old-vs-new
## comparisons in the PixelLab structures proof. `-- --art=procedural` starts with the procedural art.

const TOGGLE_KEY := KEY_F7

var env: EnvironmentField


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == TOGGLE_KEY:
		toggle()


func toggle() -> void:
	SpriteArt.set_enabled(not SpriteArt.on())
	if env != null:
		for s in env.structures():
			if is_instance_valid(s):
				s.refresh_sprite()
	print("Building art: ", "sprites" if SpriteArt.on() else "procedural")
```

In `src/game/battlefield.gd`, right after the three FpsMeter lines (`add_child(fps_meter)`), add:

```gdscript

	# F7 flips the buildings between their sprites and the procedural art (PixelLab structures proof).
	var art_toggle := ArtToggle.new()
	art_toggle.name = "ArtToggle"
	art_toggle.env = env
	add_child(art_toggle)
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tools/test.sh 2>&1 | tail -5`
Expected: `checks=N failures=0`.

- [ ] **Step 5: Commit**

```bash
git add src/game/ui/art_toggle.gd src/game/battlefield.gd tests/test_sprite_art.gd
git commit -m "feat: F7 flips the buildings between sprites and procedural art

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 6: Proof captures and the Phase 1 check

**Files:**
- Create: `tools/dev/sprite_states.gd`
- Output (not committed unless asked): `captures/sprite_states/*.png`, `captures/sprite_proof/{sprites,procedural}/*.png`

**Interfaces:**
- Consumes: `SpriteArt`, `Structure.sprite_state()`, `Structure.destroy()`, `Structure._process()`.

- [ ] **Step 1: Write the states tool**

Create `tools/dev/sprite_states.gd`:

```gdscript
extends SceneTree
## Dev capture (PixelLab structures proof): each sprite building in a row of panels at zoom 1 in the town's evening
## light -- procedural, then sprite: intact, damaged, a blast's fall at 40%, ruins, a laser's cut mid-slide, gravity's
## fall at 50% -- saved to captures/sprite_states/<name>.png at 2x, nearest.
## Usage: godot --path . --audio-driver Dummy -s tools/dev/sprite_states.gd

const BG := Color("3b3a34")
const SCREEN_AT := Vector2(320, 340)
const END := Vector2(3, 3)
const PAD := 8
## [label, sprites on, damage kind ("" = none), seconds after the hit, crack first].
const PANELS := [
	["procedural", false, &"", 0.0, false],
	["intact", true, &"", 0.0, false],
	["damaged", true, &"", 0.0, true],
	# COLLAPSE_TIME is 0.8 s: 40% of the fall is 0.32 s.
	["blast_40", true, &"blast", 0.32, true],
	["ruins", true, &"stone", 1.5, true],
	["laser", true, &"laser", 0.45, true],
	["gravity_50", true, &"gravity", 0.4, true],
]

var _cam: Camera2D
var _world: Node2D
var _lights: LightField


func _init() -> void:
	RenderingServer.set_default_clear_color(BG)
	Structure.wind = 0.0
	var root2 := Node2D.new()
	get_root().add_child(root2)
	_cam = Camera2D.new()
	root2.add_child(_cam)
	_world = Node2D.new()
	root2.add_child(_world)
	_lights = LightField.new()
	_lights.tint = Town.EVENING
	root2.add_child(_lights)
	var out := ProjectSettings.globalize_path("res://captures/sprite_states")
	DirAccess.make_dir_recursive_absolute(out)
	var m := SpriteArt.manifest()
	for n: String in m:
		var e: Dictionary = m[n]
		var size := Vector2i(int(e.size[0]), int(e.size[1]))
		var fp := Vector2(e.footprint[0], e.footprint[1])
		var anchor := SpriteArt.default_anchor(Vector2(size), fp)
		var row := Image.create(PANELS.size() * (size.x + PAD) + PAD, size.y + PAD * 2, false, Image.FORMAT_RGBA8)
		row.fill(BG)
		for i in PANELS.size():
			var p: Array = PANELS[i]
			SpriteArt.set_enabled(p[1])
			var s := Structure.new().setup(Rect2(END - fp, fp), float(e.height), Structure.Kind[e.kind], int(e.seed),
				StringName(e.role), StringName(e.get("tag", "")))
			s.lights = _lights
			_world.add_child(s)
			if p[4]:
				s.crack()
				s.scorch = 0.2
			if p[2] != &"":
				s.destroy(s.center() + Vector2(-2, -2), p[2])
				for f in int(float(p[3]) * 60.0):
					s._process(1.0 / 60.0)
			s.set_process(false)
			s.queue_redraw()
			_cam.position = s.position - (SCREEN_AT - Vector2(320, 180))
			for f in 4:
				await process_frame
			var shot := get_root().get_texture().get_image()
			row.blit_rect(shot, Rect2i(Vector2i(SCREEN_AT - anchor), size), Vector2i(PAD + i * (size.x + PAD), PAD))
			s.free()
		row.resize(row.get_width() * 2, row.get_height() * 2, Image.INTERPOLATE_NEAREST)
		row.save_png(out.path_join(n + ".png"))
		print("captured ", n)
	SpriteArt.set_enabled(true)
	root2.queue_free()
	await process_frame
	quit()
```

- [ ] **Step 2: Run it and look**

Run: `"/f/Godot/Godot_v4.7.2-stable_win64_console.exe" --path . --audio-driver Dummy -s tools/dev/sprite_states.gd 2>&1 | grep -v '^\s*at:' | tail -12`
Expected: `captured <name>` ×9.
- Open `captures/sprite_states/cottage_red.png`, `tavern.png` and `citadel_keep.png` with the Read tool.
- Check the panels match their labels:
  - **intact** = **procedural**: placeholders are today's art, so these two panels should match apart from the even sprite lighting;
  - **damaged** has cracks;
  - **blast_40** is sunk partway, clipped at the ground with ruins showing;
  - **ruins** is a heap;
  - **laser** is a stump with an orange edge and the top offset;
  - **gravity_50** is narrower and sunk.
- **If a check fails, stop:** use superpowers:systematic-debugging on the failing state.

- [ ] **Step 3: Town captures, sprites vs procedural**

Run:
```bash
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --capture-town --only=town_market
mkdir -p captures/sprite_proof/sprites && cp captures/town_market*.png captures/sprite_proof/sprites/
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --capture-town --only=town_market --art=procedural
mkdir -p captures/sprite_proof/procedural && cp captures/town_market*.png captures/sprite_proof/procedural/
```
Expected: two captures of the same view. With placeholders they look near-identical, which proves the swap in place: right anchor, right sort order, shadows present. Read both and compare. (Check `TOWN_SHOTS` in `src/game/town_debug.gd` for the shot names. If `town_market` is not one, use the one that shows the market and taverns.)

- [ ] **Step 4: Mission bench**

Run three times each, alternating:
- `SCENE=res://scenes/mission.tscn bash tools/capture.sh --bench`
- `SCENE=res://scenes/mission.tscn bash tools/capture.sh --bench --art=procedural`

Expected: mean fps with sprites ≥ procedural − 5 (the 5-fps budget; v0.07 baseline ~116). Record the six figures and the draw calls for the summary.

- [ ] **Step 5: Commit the tool**

```bash
git add tools/dev/sprite_states.gd
git commit -m "feat: sprite_states capture shows each proof building through its states

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Phase 2 — PixelLab art (needs the subscription active)

**Gate:** the balance must report an active subscription with generations left. While it reports expired, stop here and tell the user.

**Route:** PixelLab's REST API (`https://api.pixellab.ai/v2`, OpenAPI at `/v2/openapi.json`) through `tools/dev/pixellab_api.py`, which sends files straight from disk. Where a step names an MCP tool, use its REST endpoint:

| MCP tool | Endpoint |
|---|---|
| `create_image_pro` | `POST /generate-image-v2` |
| `edit_image` | `POST /edit-images-v2` |
| `animate_image` | `POST /animate-with-text-v3` |
| `get_image` / `wait_for_jobs` | `GET /background-jobs/{job_id}` |
| `get_balance` | `GET /balance` |

The helper reads the key from `PIXELLAB_API_KEY`, or else from the `pixellab` MCP entry in `~/.claude.json`, and never prints it. It needs no session restart after a key change. Read each endpoint's request schema from the OpenAPI document before its first call.

**Budget guard:** before each call, note the balance. If a building's re-rolls pass 120 generations, stop and show the user the candidates.

### Task 7: Style references

**Files:**
- Create: `tools/dev/make_style_refs.py`
- Output: `assets/pixellab/buildings/<name>/style_ref.png`

- [ ] **Step 1: Copy the reference sheet into the worktree (untracked)**

```bash
mkdir -p "concepts/TOWN REF" && cp "/f/Godot/Git/vfxProve/concepts/TOWN REF/TownMap_Component1.png" "concepts/TOWN REF/"
```

- [ ] **Step 2: Write the crop tool**

Create `tools/dev/make_style_refs.py`:

```python
"""Style references for PixelLab (PixelLab structures proof): crop each building from the concept sheet
concepts/TOWN REF/TownMap_Component1.png and scale it to fit its sprite's canvas (nearest), on transparency.
Usage: python tools/dev/make_style_refs.py [--sheet] ; --sheet also writes captures/style_refs_sheet.png to check the boxes.
"""
import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "concepts" / "TOWN REF" / "TownMap_Component1.png"
OUT = ROOT / "assets" / "pixellab" / "buildings"
# Boxes (x0, y0, x1, y1) on the 1448x1086 sheet; the keep and towers both take the castle, the walls its curtain.
BOXES = {
    "cottage_red": (35, 5, 310, 265),
    "cottage_blue": (385, 5, 660, 265),
    "tavern": (1075, 5, 1390, 262),
    "smithy": (10, 280, 352, 545),
    "cathedral": (370, 255, 702, 580),
    "citadel_keep": (110, 780, 665, 1082),
    "citadel_tower": (110, 780, 665, 1082),
    "citadel_wall": (110, 780, 665, 1082),
    "citadel_wall_side": (110, 780, 665, 1082),
}


def main():
    sheet = Image.open(SRC).convert("RGBA")
    manifest = json.loads((OUT / "manifest.json").read_text(encoding="utf-8"))
    crops = []
    for name, box in BOXES.items():
        w, h = manifest[name]["size"]
        crop = sheet.crop(box)
        # The sheet's background is near-black: make it transparent.
        px = crop.load()
        for y in range(crop.height):
            for x in range(crop.width):
                r, g, b, a = px[x, y]
                if r < 18 and g < 18 and b < 18:
                    px[x, y] = (0, 0, 0, 0)
        crop.thumbnail((w, h), Image.NEAREST)
        canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        canvas.paste(crop, ((w - crop.width) // 2, h - crop.height))
        canvas.save(OUT / name / "style_ref.png")
        crops.append(canvas)
        print("style ref", name, canvas.size)
    if "--sheet" in sys.argv:
        W = sum(c.width for c in crops) + 8 * len(crops)
        H = max(c.height for c in crops)
        out = Image.new("RGBA", (W, H), (60, 58, 52, 255))
        x = 0
        for c in crops:
            out.alpha_composite(c, (x, H - c.height))
            x += c.width + 8
        out.resize((W * 2, H * 2), Image.NEAREST).save(ROOT / "captures" / "style_refs_sheet.png")


if __name__ == "__main__":
    main()
```

- [ ] **Step 3: Run it and check the boxes**

Run: `python tools/dev/make_style_refs.py --sheet`
Then Read `captures/style_refs_sheet.png`.
Expected: each crop holds its whole building, and no neighbour. If a box cuts a building or takes in another, adjust it in `BOXES` and run again.

- [ ] **Step 4: Commit**

```bash
git add tools/dev/make_style_refs.py assets/pixellab/buildings/*/style_ref.png
git commit -m "feat: style references for the PixelLab building sprites

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 8: The cottage, end to end (judge before the rest)

**Files:**
- Overwrite: `assets/pixellab/buildings/cottage_red/{intact,damaged,ruins}.png`, `cottage_blue/…`
- Create: `docs/pixellab_structures_log.md`
- Modify: `assets/pixellab/buildings/manifest.json` (anchor override only if needed)

- [ ] **Step 1: Encode the references**

Run: `python -c "import base64,sys;print(base64.b64encode(open(sys.argv[1],'rb').read()).decode())" assets/pixellab/buildings/cottage_red/reference.png`. Do the same for `style_ref.png`. Keep the two strings for the call.

- [ ] **Step 2: Generate the intact cottage**

Call `mcp__pixellab__create_image_pro` with:
- `description`: "isometric pixel art medieval cottage, red clay tile roof, timber-framed cream plaster walls, small chimney, warm lit windows, wooden door, high detail, crisp single-pixel dark outline, no ground, no grass, no fence, transparent background"
- `width` 76, `height` 64, `no_background` true;
- `reference_images`:
  - `[{"base64": <reference>, "usage": "exact footprint, isometric 2:1 camera angle, silhouette, proportions and size of the building; keep this composition and position on the canvas"}, {"base64": <style_ref>, "usage": "art style: palette, outline, texture detail and shading"}]`.

Poll with `mcp__pixellab__wait_for_jobs`, then `mcp__pixellab__get_image(job_id)`. A 76×64 canvas returns 16 candidates.

- [ ] **Step 3: Pick and fit**

- Download the 2–3 best candidates from the URLs to the scratchpad. Read them, and show them to the user if unsure.
- For the pick, compare its alpha bounding box with `reference.png`'s: bottom row and centre x.
  - If they differ by more than 2 px, add `"anchor": [x, y]` to `cottage_red` in the manifest: `default_anchor` plus the offset.
- Save the pick as `cottage_red/intact.png`.
- Log the call in `docs/pixellab_structures_log.md`: the tool, the prompt, the references, the seed, the cost (the balance before and after) and the candidate kept.

- [ ] **Step 4: Damaged and ruins**

- **Damaged:** call `mcp__pixellab__edit_image` with `images_base64=[<intact>]` and `description`: "the same cottage damaged: cracked plaster walls, missing and broken roof tiles, a hole in the roof, scorch marks, one broken window; same building, same position, transparent background". Save to `damaged.png`.
- **Ruins:** call `edit_image` again with `description`: "the same cottage collapsed into ruins: a low heap of rubble, broken roof tiles, charred timber beams, two short stumps of wall, on the same footprint, transparent background". Save to `ruins.png`. If the edit keeps too much of the building standing, use `create_image_pro` with the ruins description and the intact sprite as the composition reference.
- Log both calls.

- [ ] **Step 5: The blue cottage**

Repeat Steps 2–4 for `cottage_blue`, with "slate blue tile roof" in place of "red clay tile roof".

- [ ] **Step 6: The comparison collapse**

- Call `mcp__pixellab__animate_image` with `first_frame_base64=<cottage_red damaged>`, `last_frame_base64=<cottage_red ruins>`, `action`: "the building collapses: the roof caves in, the walls crumble and fall inward into a heap, dust", `frame_count` 8.
- Save the 9 frames as a strip, `cottage_red/collapse_generated.png` (9×76 wide).
- Log the call.

- [ ] **Step 7: Judge in-game**

- Run `godot --path . --audio-driver Dummy -s tools/dev/sprite_states.gd` and the town capture from Task 6 Step 3.
- Read both. Show the user the cottage panels and the market capture, and ask whether the look is what they want before spending on the other buildings.

- [ ] **Step 8: Commit**

```bash
git add assets/pixellab/buildings/cottage_red assets/pixellab/buildings/cottage_blue assets/pixellab/buildings/manifest.json docs/pixellab_structures_log.md
git commit -m "feat: PixelLab cottages: intact, damaged, ruins, and a generated collapse to compare

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 9: The tavern, smithy and Citadel parts

Same steps as Task 8 Steps 1–4, for each name below, with its canvas from the manifest. Damaged and ruins use the same `edit_image` wording, with the building's name in place of "cottage". Log every call.

| Name | `create_image_pro` description |
|---|---|
| `tavern` | "isometric pixel art two-storey medieval tavern, red tile roof with dormers, timber-framed plaster walls, hanging tavern sign, covered porch, warm lit windows, high detail, crisp dark outline, no ground, transparent background" |
| `smithy` | "isometric pixel art medieval blacksmith forge, dark slate roof, stone chimney, open front with glowing orange forge fire, anvil, timber frame, high detail, crisp dark outline, no ground, transparent background" |
| `citadel_keep` | "isometric pixel art tall square stone castle keep, pale grey stone blocks, crenellated top, arrow slits, blue banners with a white cross, high detail, crisp dark outline, no ground, transparent background" |
| `citadel_tower` | "isometric pixel art round-cornered square stone castle tower, pale grey stone blocks, crenellated top with a torch, arrow slits, blue banner with a white cross, high detail, crisp dark outline, no ground, transparent background" |
| `citadel_wall` | "isometric pixel art straight castle curtain wall section, pale grey stone blocks, crenellated walkway on top, high detail, crisp dark outline, no ground, transparent background" |
| `citadel_wall_side` | the `citadel_wall` description |

Then the idle loops:
- **smithy:** call `mcp__pixellab__animate_image` with `first_frame_base64=<smithy intact>`, `action`: "the forge fire flickers and glows, small sparks rise; the building does not move", `frame_count` 4. Save the 4 generated frames (indices 1–4) as `smithy/idle.png`, a 4-frame horizontal strip. Set `"frames": 4, "fps": 8` on `smithy` in the manifest.
- **citadel_keep:** same, with `action`: "the blue banners wave in the wind; the stone keep does not move". Set `"frames": 4, "fps": 6`.

Run Task 6 Steps 1–2 again and read the captures. Commit per building:

```bash
git add assets/pixellab/buildings/<name> assets/pixellab/buildings/manifest.json docs/pixellab_structures_log.md
git commit -m "feat: PixelLab <name> sprite

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 10: The cathedral

`create_image_pro` at 352×232 returns 1 candidate a call. `edit_image` takes up to 512×512. No idle, no generated collapse: at 352 px it is beyond `animate_image`'s 256.

- [ ] **Step 1:** Generate the intact cathedral as in Task 8 Step 2, with description: "isometric pixel art gothic stone cathedral, long nave with teal-green copper roof, sandstone walls with buttresses, tall pointed arched stained-glass windows, bell tower with a spire at the front, high detail, crisp dark outline, no ground, transparent background".
- [ ] **Step 2:** Pick, fit and log as in Task 8 Step 3. Allow up to 3 calls, then show the user the best.
- [ ] **Step 3:** Damaged and ruins as in Task 8 Step 4.
- [ ] **Step 4:** Run Task 6 Steps 1–3 again and read the cathedral panels and town capture.
- [ ] **Step 5:** Commit as in Task 9.

---

## Phase 3 — The proof

### Task 11: Run the criteria and write the summary

**Files:**
- Create: `docs/PixelLab_Structures_Proof.md`
- Modify: `docs/superpowers/specs/2026-10-02-pixellab-structures-proof-design.md` (as-built notes)

- [ ] **Step 1:** `bash tools/test.sh 2>&1 | tail -3` → `failures=0`.
- [ ] **Step 2:** State digest: run Task 4 Step 5 again → the same line with sprites on and off.
- [ ] **Step 3:** Run Task 6 Steps 1, 3 and 4 again with the PixelLab art. Keep the captures in `captures/sprite_proof/` and the six bench figures.
- [ ] **Step 4:** Capture the comparison collapse.
  - Add a `--compare` flag to `tools/dev/sprite_states.gd` that, for `cottage_red` only, writes `captures/sprite_states/cottage_red_compare.png`:
    - top row: the 9 frames of `collapse_generated.png`;
    - bottom row: the engine's fall at the same 9 times (0, 0.1 … 0.8 s).
  - Run it and read it.
- [ ] **Step 5:** Write `docs/PixelLab_Structures_Proof.md`:
  - what was replaced;
  - the captures (relative links);
  - the bench table;
  - generations spent, per building, from the log;
  - the generated vs engine collapse, with the user's call;
  - the honest findings: style clash with procedural neighbours, flat lighting, the iso-angle drift and its fixes;
  - what it would take to do every component.
- [ ] **Step 6:** Add as-built notes to the spec (the wall split, the tavern footprint, the laser stump).
- [ ] **Step 7:** Commit.

```bash
git add docs/PixelLab_Structures_Proof.md docs/superpowers/specs/2026-10-02-pixellab-structures-proof-design.md tools/dev/sprite_states.gd
git commit -m "docs: PixelLab structures proof summary

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
