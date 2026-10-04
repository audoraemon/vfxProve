# Decor batch 4 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** draw every town decor piece (`Decor.Kind`, the floor's baked shrubs, the forest layer) from sprites in the reference sheets' style, switched by F7 together with the building sprites, at no generation cost.

**Architecture:**
- A new `DecorSprites` registry reads `assets/pixellab/decor/manifest.json`. It maps a decor piece to a set, or to the batch 3 tree sets for OAK and PINE.
- `DecorArt.paint()` and `DecorArt.tree()` ask `DecorSprites.paint()` first. It queues textured quads through a new `ArtKit.tex()` and returns true, or returns false so the polygons draw as today.
- Live decor, piles, the floor bake and the forest layer all go through those two functions, so they switch together. F7 redraws them, re-baking the floor.

**Tech Stack:** Godot 4.7.2 GDScript (GL Compatibility); Python 3.12 + Pillow + numpy for the art tools.

**Spec:** `docs/superpowers/specs/2026-10-05-decor-batch4-design.md`

## Global Constraints

- **Where:** work only in `C:\BURIN_NITRO\Godot\GIT\vfxProve-decor`, on branch `feat/decor-batch4` (cut from `feat/ref-batch3` after Task 15 of batch 3). Never touch `vfxProve`, `vfxProve-pixellab`, `vfxProve-integrate`, `vfxProve-gpt` or `vfxProve-ref3`.
- **No AI generation calls:** no PixelLab, OpenAI or Codex.
- **Gameplay unchanged:** `"$G" --headless --path . -s tools/dev/state_digest.gd 2>&1 | grep digest=` must stay `digest=61267b7e90524d800bf1c3473a71146b`.
- **Tests:**
  - Run `"$G" --headless --path . --import > /dev/null 2>&1` first whenever PNGs changed.
  - Then `GODOT=$G bash tools/test.sh > <scratch>/t.txt 2>&1` (~5 min).
  - `grep -o "checks=[0-9]* failures=[0-9]*" <scratch>/t.txt | tail -1` must show `failures=0`.
  - `grep -c "SCRIPT ERROR" <scratch>/t.txt` must print `0`.
- **Glow:** `$PY tools/dev/check_sprite_glow.py` must show every sprite under 5%. Point it at the decor folder too if it takes a path; otherwise extend it in Task 3.
- **Commits:** stage by name, never `git commit -a`. Messages end with a blank line, then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Shell:**
  - `G=C:/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`
  - `PY=/c/Users/dorae/AppData/Local/Programs/Python/Python312/python.exe` (Git Bash `python` is a stub)
- **Scratch:** `C:\Users\dorae\AppData\Local\Temp\claude\C--BURIN-NITRO-Godot-GIT-vfxProve-pixellab\64321455-71f5-4ef9-84ed-ba260def80dc\scratchpad\decor\`
- **Manifest format:** one entry per line, tab indent, LF newlines.
- **Art rules (user feedback):**
  - Light from the left.
  - Clean shapes with a fixed tone pattern: the drawn batch 3 dock is the bar. No sampled-texture noise ("a mess and rough" was the user's rejection).
  - Native scale: no rescale after placing. The fit-time downscale is allowed.
  - Size: about the procedural piece's size, up to 1.3×.
- **Captures:**
  - `GODOT=$G SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --capture-town [--only=<shot>]`
  - Shots live in `src/game/town_debug.gd` `TOWN_SHOTS` (dev-only; add shots there).
  - Read every capture.

## Review Focus

1. **Painter order in mixed piles:** a PILE whose parts are partly sprites and partly procedural (a kind with no set yet) must keep back-to-front order: no barrel drawn over a crate standing in front of it. Test in Task 2: segments emit in call order.
2. **F7 round trip:** toggling twice must restore exactly the procedural output: live decor, floor bake and forest. Re-baking the floor must free the old SubViewport (no leak). Test in Task 4.
3. **Run tiling:**
   - Runs of any length: shorter than one segment, exact multiples, negative direction (`size` pointing −x or −y).
   - No gaps, no overdraw past the run's end, and the last tile cropped.
   - Test in Task 3.
4. **Headless and missing assets:** a manifest entry whose PNG is missing must fall back to procedural with one warning, not crash or spam. In a headless run (tests, digest) the paint path must still work. Test in Task 1.
5. **Forest sway:** textured trees in the forest layer must sway through `wind.gdshader` without breaking the polygon trees still in the same band (mixed bands while only some sets exist). Check visually in the Task 14 captures; Task 2 covers the shader branch by code review.

---

### Task 0: Branch and worktree (controller)

- [ ] **Step 1:** wait for batch 3 Task 15 (audit quick fixes) to be committed on `feat/ref-batch3`.
- [ ] **Step 2:** create the worktree and branch:

```bash
cd /c/BURIN_NITRO/Godot/GIT/vfxProve-ref3
git worktree add ../vfxProve-decor -b feat/decor-batch4 feat/ref-batch3
```

- [ ] **Step 3:** move the spec and plan into the new worktree and commit them there. Delete the untracked copies in `vfxProve-ref3`.

```bash
cd /c/BURIN_NITRO/Godot/GIT/vfxProve-decor
mkdir -p docs/superpowers/specs docs/superpowers/plans
mv ../vfxProve-ref3/docs/superpowers/specs/2026-10-05-decor-batch4-design.md docs/superpowers/specs/
mv ../vfxProve-ref3/docs/superpowers/plans/2026-10-05-decor-batch4.md docs/superpowers/plans/
git add docs/superpowers/specs/2026-10-05-decor-batch4-design.md docs/superpowers/plans/2026-10-05-decor-batch4.md
git commit -m "docs: decor batch 4 spec and plan

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 4:** run `"$G" --headless --path . --import` once (a fresh worktree has no `.godot` cache), then the test suite to get a baseline.
- [ ] **Step 5:** create the SDD ledger at `.superpowers/sdd/2026-10-05-decor-batch4/progress.md`.
- [ ] **Step 6:** add desktop shortcuts "KAK decor - Town/Mission" pointing at `vfxProve-decor`, copying the batch 3 shortcuts' targets with the path changed.

---

### Task 1: `DecorSprites` registry and mapping

**Files:**
- Create: `src/environment/art/decor_sprites.gd`
- Create: `assets/pixellab/decor/manifest.json` (contents `{}` plus a trailing newline)
- Create: `tests/test_decor_sprites.gd`
- Modify: `tests/run_all.gd` (register the new test file next to `res://tests/test_sprite_art.gd`)

**Interfaces:**
- Consumes:
  - `SpriteArt.on() -> bool`
  - `SpriteArt.sprite(n: String) -> Dictionary` (keys `stills` {intact, damaged, ruins}, `size`, `anchor`)
  - `SpriteArt.variants(prefix) -> Array`
  - `ArtKit.pick(seed, salt, n) -> int`
- Produces:
  - `DecorSprites.DIR`, `DecorSprites.MANIFEST`
  - `DecorSprites.manifest() -> Dictionary`
  - `DecorSprites.reload() -> void`
  - `DecorSprites.decor_set(n: String) -> Dictionary`: keys `name`, `tex` (Texture2D), `size` (Vector2), `anchor` (Vector2), `segment` (float, 0 = not a run); {} when missing
  - `DecorSprites.name_for(kind: int, seed_value: int, size: Vector2) -> String`: "" = stay procedural
  - `DecorSprites.tree_set(kind: int, seed_value: int) -> Dictionary`: the batch 3 tree set (`SpriteArt.sprite` result) or {}
  - `DecorSprites.RUNS`: kinds tiled along `at → at + size`
  - `DecorSprites._variants_cache` (tests clear it)

- [ ] **Step 1: Write the failing test**

Create `tests/test_decor_sprites.gd`:

```gdscript
extends RefCounted
## DecorSprites: which decor piece draws from which sprite set (decor batch 4).

const D := Decor.Kind


static func run(t) -> void:
	_mapping(t)
	_trees(t)
	_missing(t)
	DecorSprites.reload()
	SpriteArt.set_enabled(true)


## Fake decor entries (name -> {}) in the cached manifest; returns the names added, for _unfake().
static func _fake(names: Array) -> Array:
	var m := DecorSprites.manifest()
	var added := []
	for n: String in names:
		if not m.has(n):
			m[n] = {}
			added.append(n)
	DecorSprites._variants_cache.clear()
	return added


static func _unfake(added: Array) -> void:
	var m := DecorSprites.manifest()
	for n: String in added:
		m.erase(n)
	DecorSprites._variants_cache.clear()


static func _mapping(t) -> void:
	var fakes := _fake(["barrel_1", "barrel_2", "crates_1", "ship", "fence_x", "fence_y", "sheep_1", "lamp_house"])
	t.check(DecorSprites.name_for(D.BARREL, 7, Vector2.ZERO).begins_with("barrel_"), "a barrel maps to a barrel set")
	var seen := {}
	for s in 64:
		seen[DecorSprites.name_for(D.BARREL, s * 977, Vector2.ZERO)] = true
	t.check(seen.size() == 2, "both barrel variants appear over seeds (got %s)" % [seen.keys()])
	t.check(DecorSprites.name_for(D.SHIP, 1, Vector2.ZERO) == "ship", "a single set maps by its bare name")
	t.check(DecorSprites.name_for(D.LAMP, 1, Vector2.ZERO) == "lamp_house", "a house-front lamp maps to lamp_house")
	t.check(DecorSprites.name_for(D.FENCE, 1, Vector2(2.0, 0.0)) == "fence_x", "an x-run fence takes fence_x")
	t.check(DecorSprites.name_for(D.FENCE, 1, Vector2(0.0, -1.5)) == "fence_y", "a -y run fence takes fence_y")
	t.check(DecorSprites.name_for(D.COW, 1, Vector2.ZERO) == "", "a kind with no set stays procedural")
	SpriteArt.set_enabled(false)
	t.check(DecorSprites.name_for(D.BARREL, 7, Vector2.ZERO) == "", "F7 off: every decor piece is procedural")
	SpriteArt.set_enabled(true)
	_unfake(fakes)


static func _trees(t) -> void:
	# OAK and PINE use the batch 3 building sets: oaks over oak_* and the leafy tree_*, pines over the pine tree_*.
	for s in 16:
		var oak: String = DecorSprites.tree_set(D.OAK, s * 31).get("name", "")
		t.check(oak in DecorSprites.OAK_SETS, "a decor oak takes a leafy set (got '%s')" % oak)
		var pine: String = DecorSprites.tree_set(D.PINE, s * 31).get("name", "")
		t.check(pine in DecorSprites.PINE_SETS, "a decor pine takes a pine set (got '%s')" % pine)
	SpriteArt.set_enabled(false)
	t.check(DecorSprites.tree_set(D.OAK, 3).is_empty(), "F7 off: decor trees are procedural")
	SpriteArt.set_enabled(true)


static func _missing(t) -> void:
	# An entry whose PNG is missing falls back to procedural instead of failing.
	var fakes := _fake(["rock_9"])
	t.check(DecorSprites.decor_set("rock_9").is_empty(), "a set without its PNG reads as missing")
	_unfake(fakes)
```

Register it in `tests/run_all.gd`: add `"res://tests/test_decor_sprites.gd",` on the line after `"res://tests/test_sprite_art.gd",`.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `GODOT=$G bash tools/test.sh > <scratch>/t.txt 2>&1; grep -n "DecorSprites\|SCRIPT ERROR" <scratch>/t.txt | head`
Expected: a SCRIPT ERROR, because `DecorSprites` is not declared.

- [ ] **Step 3: Write the implementation**

Create `src/environment/art/decor_sprites.gd`:

```gdscript
class_name DecorSprites
extends RefCounted
## Decor sprites (decor batch 4, docs/superpowers/specs/2026-10-05-decor-batch4-design.md): which decor piece draws
## from which sprite set, read from assets/pixellab/decor/manifest.json. A set is one still, intact.png, anchored at
## the piece's ground point ("anchor", sprite px). A run kind's set ("segment", ground units) repeats along the run.
## Oaks and pines draw the batch 3 tree sets (SpriteArt). Shown while SpriteArt.on(): F7 switches decor too.

const DIR := "res://assets/pixellab/decor/"
const MANIFEST := DIR + "manifest.json"
## ArtKit.pick salts: a decor piece's variant, a decor tree's set.
const SALT_VARIANT := 97
const SALT_TREE := 98
## Kinds drawn as a run from `at` to `at + size`, one set per run direction ("<base>_x" / "<base>_y").
const RUNS := [Decor.Kind.FENCE, Decor.Kind.BUNTING, Decor.Kind.BENCH, Decor.Kind.GARDEN]
## Each kind's set base name; DOCK has none (the dock is a Structure since batch 3).
const BASE := {
	Decor.Kind.BARREL: "barrel", Decor.Kind.CRATES: "crates", Decor.Kind.BENCH: "bench", Decor.Kind.FENCE: "fence",
	Decor.Kind.GARDEN: "garden", Decor.Kind.BUSH: "bush", Decor.Kind.ROCK: "rock", Decor.Kind.LAMP: "lamp_house",
	Decor.Kind.BUNTING: "bunting", Decor.Kind.SCARECROW: "scarecrow", Decor.Kind.SIGNPOST: "signpost",
	Decor.Kind.REEDS: "reeds", Decor.Kind.FLOWERS: "flowers", Decor.Kind.TABLE: "table", Decor.Kind.SHIP: "ship",
	Decor.Kind.BOAT: "boat", Decor.Kind.SHEEP: "sheep", Decor.Kind.COW: "cow", Decor.Kind.CART: "cart",
	Decor.Kind.LOGS: "logs",
}
## The batch 3 tree sets a decor oak or pine picks from (SpriteArt names): leafy ones for oaks, pines for pines.
const OAK_SETS := ["oak_1", "oak_2", "oak_3", "tree_1", "tree_3", "tree_4"]
const PINE_SETS := ["tree_2", "tree_5"]

static var _manifest := {}
static var _loaded := false
static var _sets := {}
static var _variants_cache := {}


static func manifest() -> Dictionary:
	if not _loaded:
		_loaded = true
		_manifest = {}
		if FileAccess.file_exists(MANIFEST):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
			if parsed is Dictionary:
				_manifest = parsed
	return _manifest


static func reload() -> void:
	_loaded = false
	_sets.clear()
	_variants_cache.clear()


## The set named `n`: {name, tex, size, anchor, segment}; {} when it is not in the manifest or its PNG is missing
## (warned once).
static func decor_set(n: String) -> Dictionary:
	if _sets.has(n):
		return _sets[n]
	var m: Dictionary = manifest().get(n, {})
	var path := DIR + n + "/intact.png"
	if m.is_empty() or not ResourceLoader.exists(path):
		if not m.is_empty():
			push_warning("DecorSprites: missing " + path)
		_sets[n] = {}
		return {}
	var tex: Texture2D = load(path)
	var size := Vector2(m.size[0], m.size[1]) if m.has("size") else Vector2(tex.get_size())
	var built := {
		"name": n, "tex": tex, "size": size,
		"anchor": Vector2(m.anchor[0], m.anchor[1]) if m.has("anchor") else Vector2(roundf(size.x * 0.5), size.y - 2.0),
		"segment": float(m.get("segment", 0.0)),
	}
	_sets[n] = built
	return built


## "<base>_<n>" variant numbers in the manifest, ascending (cached per load).
static func variants(base: String) -> Array:
	if _variants_cache.has(base):
		return _variants_cache[base]
	var out := []
	for key: String in manifest():
		if key.begins_with(base + "_"):
			var rest := key.trim_prefix(base + "_")
			if rest.is_valid_int() and int(rest) > 0:
				out.append(int(rest))
	out.sort()
	_variants_cache[base] = out
	return out


## The set a decor piece draws, or "" (procedural): off while SpriteArt is off; a run takes its direction's set; a
## kind with one set takes its bare name, else a variant picked from the seed.
static func name_for(kind: int, seed_value: int, size: Vector2) -> String:
	if not SpriteArt.on() or not BASE.has(kind):
		return ""
	var base: String = BASE[kind]
	if kind in RUNS:
		var n := base + ("_x" if absf(size.x) >= absf(size.y) else "_y")
		return n if manifest().has(n) else ""
	if manifest().has(base):
		return base
	var v := variants(base)
	if v.is_empty():
		return ""
	return "%s_%d" % [base, v[ArtKit.pick(seed_value, SALT_VARIANT, v.size())]]


## A decor oak's or pine's batch 3 tree set (SpriteArt.sprite()), picked from the seed over the sets that exist;
## {} while SpriteArt is off or none exist.
static func tree_set(kind: int, seed_value: int) -> Dictionary:
	if not SpriteArt.on():
		return {}
	var pool: Array = []
	for n: String in (PINE_SETS if kind == Decor.Kind.PINE else OAK_SETS):
		if not SpriteArt.sprite(n).is_empty():
			pool.append(n)
	if pool.is_empty():
		return {}
	return SpriteArt.sprite(pool[ArtKit.pick(seed_value, SALT_TREE, pool.size())])
```

Create `assets/pixellab/decor/manifest.json` containing `{}` and a trailing newline.

- [ ] **Step 4: Run the tests to verify they pass**

Run the suite. Expected: `failures=0` and 0 SCRIPT ERROR.
- The `_missing` check expects exactly one warning line `DecorSprites: missing res://assets/pixellab/decor/rock_9/intact.png`.
- Confirm that `SpriteArt.sprite("tree_2")` has a `name` key; the `_trees` check reads it. If not, read the set name off the pool instead and return it.

- [ ] **Step 5: Run the digest** — it must be unchanged.

- [ ] **Step 6: Commit**

```bash
git add src/environment/art/decor_sprites.gd assets/pixellab/decor/manifest.json tests/test_decor_sprites.gd tests/run_all.gd
git commit -m "feat: DecorSprites registry: decor kinds map to decor sets (variants by seed, runs by direction), oaks and pines to the batch 3 tree sets, procedural fallback

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: `ArtKit.tex()` textured quads in painter order, and textured wind

**Files:**
- Modify: `src/environment/art/art_kit.gd` (`begin`, `flush`, a new `tex`, and the `_segs` state next to `_pts`)
- Modify: `shaders/wind.gdshader`
- Test: `tests/test_art_kit.gd` (append a `_tex` case to its `run`)

**Interfaces:**
- Consumes: the `ArtKit` collection arrays (`_idx`, `_pts`, `_cols`, `_uvs`, `_line_pts`, `_line_cols`), `color_mul`, `_emit`, `_recording`.
- Produces:
  - `ArtKit.tex(tex: Texture2D, src: Rect2, dst: Vector2, c := Color.WHITE) -> void`: queues `src` of `tex` drawn with its top-left at `dst` (screen px, the flush target's space), tinted by `c * color_mul`.
  - `ArtKit.segments() -> Array` (test hook): the pending segments as `["poly", vertex_count]` / `["tex", texture, quad_count]`.
- **Painter order:**
  - `tex()` closes the pending polygon arrays into a `"poly"` segment, then appends its quad to the last segment if that is a `"tex"` segment with the same texture; otherwise it starts a new `"tex"` segment.
  - `flush()` emits the segments in order, then the trailing polygons, then the lines on top, as today.
  - `tex()` while recording is an error (`push_error`, quad dropped): decor never records.
- **Wind:**
  - Untextured polygons keep UV = (light code, wind weight).
  - Textured quads carry real texture UVs. In `wind.gdshader`, a vertex whose `TEXTURE_PIXEL_SIZE.x < 1.0` (a real texture bound, not the 1×1 default) sways by `sprite_sway * (1.0 - UV.y)`, with the same phase formula, as a positive sway.

- [ ] **Step 1: Write the failing test**

Append to `tests/test_art_kit.gd`, and call `_tex(t)` from its `run`:

```gdscript
## Textured quads keep painter order with the polygons around them, and same-texture neighbours share one batch.
static func _tex(t) -> void:
	var a := ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8))
	var b := ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8))
	ArtKit.begin()
	ArtKit.poly(PackedVector2Array([Vector2(0, 0), Vector2(4, 0), Vector2(0, 4)]), Color.RED, 0.0)
	ArtKit.tex(a, Rect2(0, 0, 4, 4), Vector2(1, 1))
	ArtKit.tex(a, Rect2(0, 0, 4, 4), Vector2(5, 1))
	ArtKit.tex(b, Rect2(0, 0, 2, 4), Vector2(9, 1))
	ArtKit.poly(PackedVector2Array([Vector2(0, 0), Vector2(4, 0), Vector2(0, 4)]), Color.BLUE, 0.0)
	ArtKit.tex(a, Rect2(0, 0, 4, 4), Vector2(1, 9))
	var s := ArtKit.segments()
	t.check(s.size() == 5, "poly, tex a x2, tex b, poly, tex a: five segments in call order (got %d)" % s.size())
	t.check(s[0][0] == "poly" and s[1][0] == "tex" and s[1][2] == 2, "the first two a-quads share one batch")
	t.check(s[2][0] == "tex" and s[2][1] == b and s[3][0] == "poly" and s[4][1] == a,
		"a later a-quad after a polygon starts a new batch (painter order kept)")
	var node := Node2D.new()
	ArtKit.flush(node)
	t.check(ArtKit.segments().is_empty(), "flush hands every segment over and starts over")
	node.free()
```

- [ ] **Step 2: Run the tests to verify they fail**

Expected: a SCRIPT ERROR, because `ArtKit.tex` / `ArtKit.segments` don't exist.

- [ ] **Step 3: Write the implementation in `art_kit.gd`**

Add next to the other collection statics:

```gdscript
## Drawing closed off by tex() calls, in call order: ["poly", idx, pts, cols, uvs] fills and
## ["tex", texture, idx, pts, cols, uvs] textured quads (same-texture neighbours share one). flush() emits these, then
## the open fills, then every line on top.
static var _segs: Array = []
```

In `begin()` add `_segs.clear()`.

Add:

```gdscript
## The textured rectangle `src` of `tex`, top-left at `dst` (px, in the flush target's space), tinted `c` (and by
## color_mul), drawn in call order with the fills around it (decor sprites, DecorSprites). Not while recording.
static func tex(t: Texture2D, src: Rect2, dst: Vector2, c := Color.WHITE) -> void:
	if _recording:
		push_error("ArtKit.tex: textured quads are not recorded")
		return
	if color_mul != Color.WHITE:
		c = Color(c.r * color_mul.r, c.g * color_mul.g, c.b * color_mul.b, c.a)
	_close_fills()
	var seg: Array
	if not _segs.is_empty() and _segs[-1][0] == "tex" and _segs[-1][1] == t:
		seg = _segs[-1]
	else:
		seg = ["tex", t, PackedInt32Array(), PackedVector2Array(), PackedColorArray(), PackedVector2Array()]
		_segs.append(seg)
	var ts := Vector2(t.get_size())
	var base := (seg[3] as PackedVector2Array).size()
	var corners := [Vector2.ZERO, Vector2(src.size.x, 0), src.size, Vector2(0, src.size.y)]
	for k in 4:
		seg[3].append(dst + corners[k])
		seg[4].append(c)
		seg[5].append((src.position + corners[k]) / ts)
	for k in [0, 1, 2, 0, 2, 3]:
		seg[2].append(base + k)


## Close the open fills into a "poly" segment (tex() keeps them under what it draws next).
static func _close_fills() -> void:
	if _idx.is_empty():
		return
	_segs.append(["poly", _idx, _pts, _cols, _uvs])
	_idx = PackedInt32Array()
	_pts = PackedVector2Array()
	_cols = PackedColorArray()
	_uvs = PackedVector2Array()


## The pending segments, for tests: ["poly", vertex count] or ["tex", texture, quad count].
static func segments() -> Array:
	var out := []
	for s: Array in _segs:
		if s[0] == "poly":
			out.append(["poly", (s[2] as PackedVector2Array).size()])
		else:
			out.append(["tex", s[1], (s[3] as PackedVector2Array).size() / 4])
	return out
```

At the start of `flush(ci)`, before the existing `_emit(...)` line, emit the segments:

```gdscript
	for s: Array in _segs:
		if s[0] == "poly":
			RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), s[1], s[2], s[3], s[4])
		else:
			RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), s[2], s[3], s[4], s[5],
				PackedInt32Array(), PackedFloat32Array(), (s[1] as Texture2D).get_rid())
	_segs.clear()
```

Leave the rest of `flush` as it is: the open fills, then the lines. In the `_recording` branch `_segs` is always empty, because `tex()` refuses while recording.

- [ ] **Step 4: Add the textured branch to the wind shader**

In `shaders/wind.gdshader`:
- Add the uniform `uniform float sprite_sway = 1.5;`.
- Change `vertex()` so that a textured vertex sways by its height in the sprite:

```glsl
void vertex() {
	vec2 at = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
	float ph = at.x * 0.013 + at.y * 0.021 + VERTEX.x * 0.011 + VERTEX.y * 0.017;
	if (TEXTURE_PIXEL_SIZE.x < 1.0) {
		// A decor sprite's quad (ArtKit.tex): UV is the texture's, so the weight is the vertex's height in the sprite.
		VERTEX.x += round(sprite_sway * (1.0 - UV.y) * sin(TIME * 1.3 + ph) * wind);
	} else if (UV.y != 0.0) {
		float w = abs(UV.y);
		vec2 off;
		if (UV.y > 0.0) {
			off = w * vec2(sin(TIME * 1.3 + ph), 0.0);
		} else {
			off = w * vec2(0.4 * sin(TIME * 2.1 + ph), sin(TIME * 6.0 + VERTEX.x * 0.45 + ph));
		}
		VERTEX += round(off * wind);
	}
}
```

Keep the existing comment header and add one line about the textured branch. If `TEXTURE_PIXEL_SIZE` is not available in `vertex()` under GL Compatibility (shader compile error in the log), use this fallback instead:
- `tex()` writes vertex colour alpha `0.998`;
- the shader tests `COLOR.a > 0.997 && COLOR.a < 0.999`;
- the fragment restores `COLOR.a = 1.0` for those vertices.

Report which branch was used.

- [ ] **Step 5: Run the tests**

Expected: `failures=0`, 0 SCRIPT ERROR, and no shader compile error in `<scratch>/t.txt`. Also run one capture, `--only=town_forest`, and grep its log for `SHADER ERROR`: there must be none.

- [ ] **Step 6: Commit**

```bash
git add src/environment/art/art_kit.gd shaders/wind.gdshader tests/test_art_kit.gd
git commit -m "feat: ArtKit.tex: textured quads drawn in painter order with the fills (same-texture neighbours batched); wind shader sways textured quads by their height in the sprite

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Paint switch, runs, down trees, and the barrel proof set

**Files:**
- Modify: `src/environment/art/decor_sprites.gd` (add `paint()`)
- Modify: `src/environment/art/decor_art.gd` (the first line of `paint()` and of `tree()`)
- Create: `tools/dev/ref_convert/decor_common.py` (writes a decor set and its manifest line)
- Create: `tools/dev/ref_convert/decor_goods.py` (the barrel only, for now; Task 5 extends it)
- Create: `assets/pixellab/decor/barrel_1/intact.png`, plus a manifest line
- Modify: `tools/dev/check_sprite_glow.py` (also scan `assets/pixellab/decor/*/intact.png`, if it doesn't already)
- Test: `tests/test_decor_sprites.gd` (add `_paint`, `_runs`, `_down`)

**Interfaces:**
- Consumes:
  - Task 1: `name_for`, `tree_set`, `decor_set`, `RUNS`
  - Task 2: `ArtKit.tex`, `ArtKit.segments`
  - `Iso.ground_to_screen(g: Vector2) -> Vector2`
- Produces:
  - `DecorSprites.paint(kind: int, at: Vector2, size: Vector2, seed_value: int, origin: Vector2, down := false) -> bool`: true when it drew (or deliberately drew nothing); false means draw procedurally.
  - `decor_common.write_set(name, img, anchor, segment=None)`, used by every later art task:
    - saves `assets/pixellab/decor/<name>/intact.png`;
    - inserts or replaces `"<name>": {"size": [w,h], "anchor": [x,y][, "segment": s]}` in the decor manifest, keeping one entry per line, tab indent and LF.
- **Placement:**
  - A still's top-left is at `Iso.ground_to_screen(at) - origin - anchor`.
  - A run of length `L = (size).length()` along `dir = size / L`, with segment length `g`, draws `ceil(L / g - 0.001)` tiles. Tile `i` is anchored at ground point `at + dir * g * i`.
  - The last tile's `src` width is `size.x * (L - g * (n - 1)) / g`, rounded, at least 1 px.
  - For a run in the negative direction (dir.x < 0 or dir.y < 0), start from `at + size` and run back, so tiles still go back-to-front and use the same set.
- **Down:**
  - A down oak or pine with a tree set draws the set's `ruins` still (stump and log) at the set's anchor.
  - A down piece of any other kind with a set draws nothing and returns true (as the procedural path does now).

- [ ] **Step 1: Write the failing tests** (append to `tests/test_decor_sprites.gd`, and call them from `run`):

```gdscript
static func _paint(t) -> void:
	var fakes := _fake(["barrel_1"])
	DecorSprites._sets["barrel_1"] = {"name": "barrel_1", "tex": _tex(10, 12), "size": Vector2(10, 12),
		"anchor": Vector2(5, 11), "segment": 0.0}
	ArtKit.begin()
	t.check(DecorSprites.paint(Decor.Kind.BARREL, Vector2(2, 3), Vector2.ZERO, 5, Vector2.ZERO),
		"a barrel with a set paints from it")
	var s := ArtKit.segments()
	t.check(s.size() == 1 and s[0][0] == "tex" and s[0][2] == 1, "one textured quad, no polygons")
	ArtKit.begin()
	t.check(not DecorSprites.paint(Decor.Kind.COW, Vector2(2, 3), Vector2.ZERO, 5, Vector2.ZERO),
		"a kind without a set is left to the procedural art")
	t.check(ArtKit.segments().is_empty(), "and queues nothing")
	ArtKit.begin()
	DecorSprites._sets.erase("barrel_1")
	_unfake(fakes)


static func _runs(t) -> void:
	var fakes := _fake(["fence_x"])
	DecorSprites._sets["fence_x"] = {"name": "fence_x", "tex": _tex(32, 20), "size": Vector2(32, 20),
		"anchor": Vector2(0, 18), "segment": 1.0}
	for c in [[Vector2(3.0, 0.0), 3], [Vector2(2.5, 0.0), 3], [Vector2(0.4, 0.0), 1], [Vector2(-2.0, 0.0), 2]]:
		ArtKit.begin()
		DecorSprites.paint(Decor.Kind.FENCE, Vector2(5, 5), c[0], 1, Vector2.ZERO)
		var s := ArtKit.segments()
		var quads: int = s[0][2] if s.size() == 1 else -1
		t.check(quads == c[1], "a fence run of %s draws %d tiles (got %d)" % [c[0], c[1], quads])
	ArtKit.begin()
	DecorSprites._sets.erase("fence_x")
	_unfake(fakes)


static func _down(t) -> void:
	# A felled decor oak shows its tree set's ruins (stump and log); a knocked-over barrel shows nothing.
	ArtKit.begin()
	var drew := DecorSprites.paint(Decor.Kind.OAK, Vector2(1, 1), Vector2.ZERO, 9, Vector2.ZERO, true)
	var s := ArtKit.segments()
	t.check(drew and s.size() == 1 and s[0][0] == "tex", "a down oak draws its set's stump")
	var tree := DecorSprites.tree_set(Decor.Kind.OAK, 9)
	t.check(s.size() == 1 and s[0][1] == tree.stills[&"ruins"], "the stump is the set's ruins still")
	ArtKit.begin()


static func _tex(w: int, h: int) -> Texture2D:
	return ImageTexture.create_from_image(Image.create(w, h, false, Image.FORMAT_RGBA8))
```

- [ ] **Step 2: Run the tests to verify they fail**

Expected: a SCRIPT ERROR, because `DecorSprites.paint` doesn't exist.

- [ ] **Step 3: Implement `DecorSprites.paint()`**

```gdscript
## Draw a decor piece from its sprite (ArtKit.tex) and return true; false leaves it to DecorArt's polygons. A down
## tree shows its set's ruins; any other down piece with a set draws nothing. A run repeats its set's segment from
## its back end, the last tile cut to the run's length.
static func paint(kind: int, at: Vector2, size: Vector2, seed_value: int, origin: Vector2, down := false) -> bool:
	if kind == Decor.Kind.OAK or kind == Decor.Kind.PINE:
		var tr := tree_set(kind, seed_value)
		if tr.is_empty():
			return false
		var still: Texture2D = tr.stills[&"ruins" if down else &"intact"]
		ArtKit.tex(still, Rect2(Vector2.ZERO, tr.size), Iso.ground_to_screen(at) - origin - tr.anchor)
		return true
	var n := name_for(kind, seed_value, size)
	if n == "":
		return false
	var d := decor_set(n)
	if d.is_empty():
		return false
	if down:
		return true
	if kind in RUNS and d.segment > 0.0:
		var length := size.length()
		if length <= 0.0:
			return true
		var dir := size / length
		var start := at
		if dir.x < 0.0 or dir.y < 0.0:
			start = at + size
			dir = -dir
		var count := ceili(length / d.segment - 0.001)
		for i in count:
			var w: float = d.size.x
			if i == count - 1:
				w = maxf(1.0, roundf(d.size.x * (length - d.segment * float(count - 1)) / d.segment))
			var g := start + dir * d.segment * float(i)
			ArtKit.tex(d.tex, Rect2(0, 0, w, d.size.y), Iso.ground_to_screen(g) - origin - d.anchor)
		return true
	ArtKit.tex(d.tex, Rect2(Vector2.ZERO, d.size), Iso.ground_to_screen(at) - origin - d.anchor)
	return true
```

- [ ] **Step 4: Hook it into `DecorArt`**

In `src/environment/art/decor_art.gd`:
- The first statement of `paint(...)` becomes:

```gdscript
	if DecorSprites.paint(kind, at, size, seed_value, origin, down):
		return
```

- The first statement of `tree(...)` becomes:

```gdscript
	if DecorSprites.paint(kind, at, size, seed_value, origin):
		return
```

- [ ] **Step 5: Run the tests to verify they pass**

Expected: `failures=0`, 0 SCRIPT ERROR. The `_down` test needs the batch 3 tree sets, which are on the branch.

- [ ] **Step 6: The barrel proof set**

- `tools/dev/ref_convert/decor_common.py`: `write_set(name, img, anchor, segment=None)` as defined in Interfaces, plus `DECOR = Path("assets/pixellab/decor")`. Re-running it on an existing name replaces that line in place.
- `tools/dev/ref_convert/decor_goods.py barrel`:
  - Find a barrel on the four `concepts/TOWN REF/TownMap_Component*.png` sheets (Component1 and 2 have barrels by buildings and stalls). Read the crops at 3×.
  - Cut it with `convert.py`'s cut/fit functions (import them), fit to about the procedural barrel's size, and mirror if it's lit from the right.
  - Write `barrel_1` with its anchor at the base centre.
  - If no clean cut exists, draw it clean (staves, two hoops, a lit left side) in the sheet's wood tones.
- Run `--import`, the tests, the digest and glow.
- Capture `town_market` and `town_east_quarter`, and Read them:
  - Barrels draw from the sprite both live and baked inside the walls.
  - Barrels inside PILEs keep their order with crates.

- [ ] **Step 7: Commit**

```bash
git add src/environment/art/decor_sprites.gd src/environment/art/decor_art.gd tests/test_decor_sprites.gd tools/dev/ref_convert/decor_common.py tools/dev/ref_convert/decor_goods.py tools/dev/check_sprite_glow.py assets/pixellab/decor/manifest.json assets/pixellab/decor/barrel_1/intact.png
git commit -m "feat: decor draws from its sprite set when one exists (DecorSprites.paint in DecorArt.paint/tree): stills, runs tiled from their back end, felled trees' stumps; barrel_1 proof set

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Also stage the `.import` file Godot wrote next to the PNG, if the project tracks them (check with `git ls-files "assets/pixellab/buildings/*.import" | head -1`).

---

### Task 4: F7 redraws decor, re-bakes the floor, redraws the forest

**Files:**
- Modify: `src/game/ui/art_toggle.gd` (`toggle()`)
- Modify: `src/environment/decor.gd` (join group `&"decor_art"` in `_ready`; add `art_changed()`)
- Modify: `src/game/town/forest_layer.gd` (each `Band` joins `&"decor_art"`; `art_changed()` does `queue_redraw()`)
- Modify: `src/game/town/town_floor.gd` (join `&"decor_art"`; `art_changed()` re-bakes, freeing the old SubViewport)
- Modify: `src/game/town/town_floor.gd` `_shrubs()` (the leafy shrubs draw a `bush_<n>` sprite when one exists; flowers too)
- Test: `tests/test_decor_sprites.gd` (`_toggle`)

**Interfaces:**
- Consumes: Task 3 paint switch; `SpriteArt.set_enabled`; `ArtToggle.toggle()`.
- Produces:
  - Group `&"decor_art"`, whose members implement `art_changed() -> void`.
  - `ArtToggle.toggle()` calls `get_tree().call_group(&"decor_art", &"art_changed")` after flipping `SpriteArt`, and `DecorSprites.reload()` is not needed there.
  - `TownFloor.rebake() -> void`: frees the `FloorBake` SubViewport and runs `_bake()` again. It does nothing headless (`_texture == null` path).

- [ ] **Step 1: Write the failing test**

```gdscript
static func _toggle(t) -> void:
	# F7 reaches every decor drawer: a live Decor in the group redraws, and the floor re-bakes once.
	var d := Decor.new().setup(Decor.Kind.BARREL, Vector2(1, 1), Vector2.ZERO, 3)
	var root := Node.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(root)
	root.add_child(d)
	t.check(d.is_in_group(&"decor_art"), "a live decor piece listens for art changes")
	t.check(d.has_method("art_changed"), "and has art_changed()")
	var floor_node := TownFloor.new()
	t.check(floor_node.has_method("rebake"), "the floor can re-bake")
	floor_node.free()
	root.queue_free()
```

If the test runner's root is not in a scene tree (see the batch 3 note in `tests/test_sprite_art.gd` `_idle_clock_frozen`: "The test runner's root is never inside a scene tree"), check group membership after `_ready()` by calling `d._ready()` directly, and don't use `get_tree()`.

- [ ] **Step 2: Run the test to verify it fails.**

- [ ] **Step 3: Implement**

- `decor.gd` `_ready()`: add `add_to_group(&"decor_art")`, and add:

```gdscript
## F7 switched the art (ArtToggle): draw again from the sprite or the polygons.
func art_changed() -> void:
	queue_redraw()
```

- `forest_layer.gd` `Band`: in `_ready()` (add one), `add_to_group(&"decor_art")`, and add `func art_changed() -> void: queue_redraw()`.
- `town_floor.gd`:

```gdscript
## F7 switched the art (ArtToggle): bake the floor again, so its baked decor and shrubs follow.
func art_changed() -> void:
	rebake()


func rebake() -> void:
	if _texture == null:
		return
	var old := get_node_or_null("FloorBake")
	if old != null:
		remove_child(old)
		old.queue_free()
	_bake()
```

  In `_ready()` add `add_to_group(&"decor_art")`.
- `town_floor.gd` `_shrubs()`:
  - Before `PropArt.leafy(...)` for a bush, try `DecorSprites.paint(Decor.Kind.BUSH, g, Vector2.ZERO, h, Vector2.ZERO)`.
  - For a flower clump, try `DecorSprites.paint(Decor.Kind.FLOWERS, g, Vector2.ZERO, h, Vector2.ZERO)`.
  - If it returns true, skip the procedural drawing for that shrub. The existing `ArtKit.begin()`/`flush(ci)` around it stays.
  - The paint origin is the detail canvas's: check how `paint_detail` positions its canvas (`detail.position = -bounds.position`). Pass the same origin as the procedural call would, which there is screen `p`. Since `DecorSprites.paint` computes `Iso.ground_to_screen(g) - origin`, pass `origin = Vector2.ZERO` and verify the bush lands where the procedural one did, in a capture.
- `art_toggle.gd` `toggle()`: after the structures loop, add:

```gdscript
	if is_inside_tree():
		get_tree().call_group(&"decor_art", &"art_changed")
```

- [ ] **Step 4: Run the tests and the digest.**

- [ ] **Step 5: Check by hand**

Run the town debug scene with the barrel set present. Press F7 twice and watch the log: there must be no errors, and memory must not grow per toggle. Check that with `print(Performance.get_monitor(Performance.OBJECT_COUNT))` before and after 4 toggles, in a dev-only check you remove afterwards. Report the numbers.

- [ ] **Step 6: Commit**

```bash
git add src/game/ui/art_toggle.gd src/environment/decor.gd src/game/town/forest_layer.gd src/game/town/town_floor.gd tests/test_decor_sprites.gd
git commit -m "feat: F7 switches decor too: live decor and the forest bands redraw, the floor re-bakes (old bake freed); floor shrubs and flower clumps draw bush/flowers sets when present

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Group 0 check (controller)

- **Bench:** 3 alternating pairs (`--disable-vsync`, as batch 3 Task 7 did). Report the medians, with the other Godot processes noted.
- **Captures:** `town_market`, `town_forest`, `town_overview`.
- **Review:** if nothing is wrong, continue without a user stop (group 0 is engine plus one proof set).

---

### Task 6: Town goods (barrel variants, crates, bench, table, logs, cart, signpost)

**Files:**
- Modify: `tools/dev/ref_convert/decor_goods.py` (one subcommand per set; `all` runs them all)
- Create: `assets/pixellab/decor/<set>/intact.png` for `barrel_2`, `crates_1`, `crates_2` (the stacked pair), `bench_x`, `bench_y`, `table_1`, `table_2`, `logs_1`, `cart_1`, `cart_2`, `signpost`, plus manifest lines

**Interfaces:**
- Consumes: `decor_common.write_set`; `convert.py` cut and fit; `DecorSprites.BASE` names (Task 1).
- Produces: the manifest names above.
  - The bench is a run kind, so its sets have `segment`: the bench's procedural length (`size`) per tile. Check what `TownDecor` gives benches (`_bench(at, size, ...)`). If benches always have one fixed size, give a segment equal to that size, so each bench is one tile.

- [ ] **Step 1:** for each set, find its candidates on the four sheets, Read the crops at 3×, and pick the cleanest.
  - Market tables come from the Component2 stall goods.
  - Carts come from Component1 and 3.
  - The signpost is on Component3.
  - Crates and barrels come from Component1 and 2.
- [ ] **Step 2:** convert or draw each set.
  - **Size:** measure the procedural size in a capture (`town_market`, `town_east_quarter`, `town_crowd`) and target up to 1.3× of it.
  - **Crates:** the procedural one draws a second, smaller crate on top for half the seeds. `crates_1` is the single crate and `crates_2` is the stacked pair, and the seed picks between them.
  - **Anchors:** the ground point is the base centre for stills, and the back end of the run for `bench_x/_y`.
  - **Direction:** `bench_x` runs down-right and `bench_y` down-left. Draw each in its own direction; don't mirror one from the other.
- [ ] **Step 3:** run `--import`, the tests, the digest and glow.
- [ ] **Step 4:** add a test case to `_mapping` in `tests/test_decor_sprites.gd` checking that every Task 6 name in the real manifest loads (`decor_set(n)` is not empty):

```gdscript
	for n: String in ["barrel_1", "barrel_2", "crates_1", "crates_2", "bench_x", "bench_y", "table_1", "table_2",
			"logs_1", "cart_1", "cart_2", "signpost"]:
		t.check(not DecorSprites.decor_set(n).is_empty(), "decor set %s loads" % n)
```

- [ ] **Step 5: Captures**
  - Take `town_market`, `town_east_quarter`, `town_crowd` and `town_side_gate`. Read them and compare with the procedural captures (`-- --art=procedural`).
  - **Check:** goods sit on their spots and piles keep their order. Nothing floats or sinks.
- [ ] **Step 6: Commit**

```bash
git add tools/dev/ref_convert/decor_goods.py assets/pixellab/decor tests/test_decor_sprites.gd
git commit -m "feat: decor sets for town goods: barrels, crates (single and stacked), benches, market tables, log piles, carts, signpost

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: House-front lamp and bunting

**Files:**
- Create: `tools/dev/ref_convert/decor_street.py`
- Create: `assets/pixellab/decor/lamp_house/intact.png`, `bunting_x/intact.png`, `bunting_y/intact.png`, plus manifest lines
- Modify: `src/environment/decor.gd`, only if the lamp glow's position must move to the sprite's lantern (the glow is a `QuadFx` child at the node's origin; check where it sits)

**Interfaces:**
- Consumes: `decor_common.write_set`; the batch 3 `lamp_post` set (`assets/pixellab/buildings/lamp_post/intact.png`) as the style source.
- Produces: `lamp_house`, `bunting_x`, `bunting_y`.

- [ ] **Step 1: `lamp_house`.**
  - Make it a small wall or post lamp in the `lamp_post` style: the same wood, iron and lantern tones, scaled to the procedural `_lamp(o)` size.
  - The lantern's glass is unlit (dark). The glow stays the procedural `QuadFx`, so there is no painted glow (glow check under 5%).
  - Check that the procedural glow sits on the sprite's lantern. If it doesn't, add an optional manifest key `"glow": [x, y]` (sprite px from the anchor), and move `_glow` to it in `Decor._ready()` when the sprite is on. Add a test in `tests/test_decor_sprites.gd` that the glow offset is read from the manifest.
- [ ] **Step 2: `bunting_x/_y`.**
  - A segment of pennant string, one tile per `segment` ground units, coloured like the procedural `_bunting` pennants.
  - Bunting sways: `Decor.SWAYS` includes BUNTING, so the node already has the wind material, and the textured branch from Task 2 sways it.
  - **Anchor:** the string's start point at its hang height. The procedural bunting is strung high above the street (`z_index = 1`), so its drawing offset upward must match the procedural one. Read `_bunting` for the height.
- [ ] **Step 3:** run the tests, the digest and glow. Capture `town_market` and `town_lamps` (with `--dim` for the lamps, from batch 3 Task 6), and Read them.
- [ ] **Step 4: Commit.**

---

### Task 8: Water: ship and rowing boats

**Files:**
- Create: `tools/dev/ref_convert/decor_water.py`
- Create: `assets/pixellab/decor/ship/intact.png`, `boat_1`, `boat_2`, plus manifest lines

**Interfaces:**
- Consumes: `decor_common.write_set`.
- Produces: `ship`, `boat_1`, `boat_2`.

- [ ] **Step 1:**
  - Find ships and boats on the sheets; Component3's river edge and Component1's harbour are the likely places. Read the crops at 3×.
  - The ship moors at `TownLayout.SHIP_AT` beside the batch 3 dock. Keep its hull length and draft like the procedural `_ship`, so it still lies along the dock.
  - Boats are smaller, in 2 variants.
  - Light from the left. Waterline: anchor at the hull's waterline centre, so the hull sits in the water at the same depth as the procedural one.
- [ ] **Step 2: Check the leftover decor DOCK kind.**
  - Run `grep -n "Kind.DOCK" src/game/town/town_decor.gd`.
  - If nothing places it, report "unused, no set".
  - If something places it, map it in `DecorSprites.BASE` to the building `dock` set via a special case like OAK/PINE, and add a test.
- [ ] **Step 3:** run the tests, the digest and glow. Capture `town_dock`, `town_river_farms` and `town_bridge`, and Read them. The ship must not cover people on the dock any more than before.
- [ ] **Step 4: Commit.**

---

### Task 9: Group 1 checkpoint (controller)

- tests and digest; glow;
- bench: market and meadow views, 3 alternating pairs, medians, other Godot processes noted;
- captures sent to the user: market, east quarter, dock, lamps;
- push `feat/decor-batch4`;
- KAK Dev Ledger update;
- **stop for the user's review.**

---

### Task 10: Fences, garden beds, scarecrow

**Files:**
- Create: `tools/dev/ref_convert/decor_farm.py`
- Create: `assets/pixellab/decor/fence_x`, `fence_y`, `garden_x`, `garden_y`, `scarecrow`, plus manifest lines

**Interfaces:**
- Consumes: `decor_common.write_set`; the batch 3 field fences (`tools/dev/ref_convert/fields.py`) as the style and tone source (round posts, pale cut tops, two rails), so pasture and field fences match.
- Produces: the five names above.

- [ ] **Step 1: Fence segments.**
  - Draw one segment per run direction, with the post at the segment's start: one post plus two rails to the next post.
  - The procedural fence is 14 px tall (`_fence(at, at + size, origin, 14.0)`); match it.
  - Segment length: the post spacing used by the batch 3 field fence, about 0.5 ground units.
  - **Run end:** the last post comes from the last tile's start. A run needs a closing post at its far end, so draw one extra post-only quad at `at + size`. Add `"end_post": [x, y, w, h]` (the post's rect in the sprite) to the manifest, and in `DecorSprites.paint` draw that sub-rect at the run's far end when present.
  - Extend `_runs` in `tests/test_decor_sprites.gd`: a run with `end_post` draws `tiles + 1` quads.
- [ ] **Step 2: Garden beds.**
  - Read `_garden(at, size, ...)` in `decor_art.gd` and the `GARDEN` placements in `town_decor.gd`: a garden is a small plot, so check its sizes.
  - If the sizes are few and fixed, make one still per size instead of runs. In that case change `RUNS` to drop GARDEN, map it by size class (`garden_<n>` picked by size), update the Task 1 test, and explain.
  - Otherwise use row segments along the longer side.
- [ ] **Step 3: Scarecrow.**
  - Cut from the sheet (Component3 farm area), or draw it in the batch 3 field style.
- [ ] **Step 4:** run the tests, the digest and glow. Capture `town_pasture_east`, `town_windmill`, `town_oaks` and `town_crowd` (house gardens), and Read them.
- [ ] **Step 5: Commit.**

---

### Task 11: Sheep and cows

**Files:**
- Create: `tools/dev/ref_convert/decor_animals.py`
- Create: `assets/pixellab/decor/sheep_1`, `sheep_2`, `cow_1`, `cow_2`, plus manifest lines
- Modify: `src/environment/art/decor_sprites.gd` (mirror by seed for animals)

**Interfaces:**
- Consumes: `decor_common.write_set`; `DecorSprites.paint`.
- Produces:
  - the four sets;
  - `DecorSprites.MIRRORED := [Decor.Kind.SHEEP, Decor.Kind.COW]`: kinds drawn flipped for half the seeds (`ArtKit.hash01(seed, SALT_VARIANT + 1) < 0.5`).

- [ ] **Step 1:** add the mirror support with a test.
  - `ArtKit.tex` gains an optional `flip_h := false` argument. It swaps the quad's left and right UVs, so the drawn rect is the same.
  - In `paint`, a mirrored kind passes `flip_h` and the anchor's x becomes `size.x - anchor.x`.
  - Test:

```gdscript
static func _mirror(t) -> void:
	var fakes := _fake(["sheep_1"])
	DecorSprites._sets["sheep_1"] = {"name": "sheep_1", "tex": _tex(12, 9), "size": Vector2(12, 9),
		"anchor": Vector2(4, 8), "segment": 0.0}
	var flips := {}
	for s in 32:
		ArtKit.begin()
		DecorSprites.paint(Decor.Kind.SHEEP, Vector2(1, 1), Vector2.ZERO, s * 131, Vector2.ZERO)
		flips[ArtKit.last_flip()] = true
	t.check(flips.size() == 2, "sheep face both ways over seeds")
	ArtKit.begin()
	DecorSprites._sets.erase("sheep_1")
	_unfake(fakes)
```

  - Add `ArtKit.last_flip() -> bool` as a test hook: it returns the `flip_h` of the last `tex()` call.
- [ ] **Step 2: Animals.**
  - Find sheep and cows on the sheets (Component3 pastures). Convert or draw them clean, at the procedural size (`_sheep`, `_cow`).
  - Light from the left in the base pose. Mirrored animals are lit from the right; that's accepted, as the procedural animals don't shade by facing. Note it in the report.
- [ ] **Step 3:** run the tests, the digest and glow. Capture `town_pasture_east` and `town_windmill`, and Read them.
- [ ] **Step 4: Commit.**

---

### Task 12: Group 2 checkpoint (controller)

Same as Task 9:
- tests and digest; glow;
- bench: the pasture and meadow views;
- captures sent to the user;
- push; KAK Dev Ledger update;
- **stop for the user's review.**

---

### Task 13: Bushes, rocks, flowers, reeds

**Files:**
- Create: `tools/dev/ref_convert/decor_nature.py`
- Create: `assets/pixellab/decor/bush_1..3`, `rock_1..3`, `flowers_1..3`, `reeds_1..2`, plus manifest lines

**Interfaces:**
- Consumes: `decor_common.write_set`; Task 4's floor shrub hook (it picks these up automatically).
- Produces: the names above.

- [ ] **Step 1:** cut the sets from the sheets.
  - Bushes and rocks: Component3 has many.
  - Flowers and reeds: the riverbanks on Component3.
  - Greens are muted toward the batch 3 tree greens, the same treatment as `trees.py`.
  - Size: the procedural `_bush(o, seed, 1.2)`, `_rock`, `_flowers` and `_reeds`.
- [ ] **Step 2:** run the tests, the digest and glow.
- [ ] **Step 3:** capture `town_overview`, `town_river_farms`, `town_corner_east` and `town_oaks`, and Read them.
  - The floor shrubs (baked) and the live bushes must match.
  - Reeds must line the banks as before.
- [ ] **Step 4: Commit.**

---

### Task 14: Forest and town decor trees from the batch 3 tree sets

**Files:**
- Modify: `src/game/town/forest_layer.gd`, only if needed (the `FOREST_CLUSTERS` path is bypassed by the sprite path automatically through `DecorArt.tree`)
- Modify: `shaders/wind.gdshader` `sprite_sway`, if tuning is needed
- Test: `tests/test_decor_sprites.gd` (a forest band with sprites queues textured quads only)

**Interfaces:**
- Consumes: `DecorSprites.tree_set`, `OAK_SETS`, `PINE_SETS` (Task 1); Task 2's wind branch; Task 3's `paint`.
- Produces: nothing new. This task checks and tunes the forest and town decor trees, which switch as soon as Task 3 lands.

- [ ] **Step 1: Test**

```gdscript
static func _forest(t) -> void:
	ArtKit.begin()
	for i in 6:
		DecorArt.tree(Decor.Kind.OAK if i % 2 == 0 else Decor.Kind.PINE, Vector2(i, i), Vector2.ZERO, i * 17,
			Vector2.ZERO, ForestLayer.FOREST_CLUSTERS)
	var polys := 0
	for s: Array in ArtKit.segments():
		if s[0] == "poly":
			polys += 1
	t.check(polys == 0, "with the tree sets present, forest trees queue sprites only")
	ArtKit.begin()
```

- [ ] **Step 2:** run the tests, then capture `town_forest`, `town_overview`, `town_corner_east` and `town_oaks`. Read them and check:
  - the forest and the ring trees now match in style and size;
  - the sway reads gently: take 3 frames 0.25 s apart, as batch 3 did. Tune `sprite_sway` (1–2 px) if it's too strong or too weak;
  - no tree draws in front of a wall it stands behind. The forest layer is under the world and baked trees are only where nothing overlaps, so this should hold. Report any exception.
- [ ] **Step 3: Bench.** 3 alternating pairs over the forest and overview views, vsync off, medians, other Godot processes noted.
  - The forest has hundreds of trees, so sprite quads must stay within ~3 fps of the procedural trees.
  - If they don't, report it with numbers. A candidate fix: drop forest sway for distant bands, or batch the forest by texture.
- [ ] **Step 4: Commit.**

---

### Task 15: Group 3 checkpoint and wrap-up (controller)

- [ ] Run the tests, the digest, glow and the full bench.
- [ ] Send captures to the user: overview, forest, river farms, market.
- [ ] Write the docs:
  - `tools/dev/ref_convert/README.md`: add a decor section covering `decor_common.write_set`, the decor manifest keys (`size`, `anchor`, `segment`, `end_post`, `glow`), and one script per group.
  - `docs/HANDOFF_pixellab.md`: add a short decor batch 4 section listing what's sprite, what's still procedural (effects only), and how F7 covers decor.
- [ ] Commit; push `feat/decor-batch4`; update the KAK Dev Ledger.
- [ ] **Stop for the user's review.** Then merge, in order: `feat/ref-re-texture`, `feat/ref-batch3`, `feat/decor-batch4` into `feat/Develop-Main`.
  - Do a trial merge with a throwaway commit first (memory: merge-tree misses uncommitted work), and run the tests.
  - Ask before pushing.
