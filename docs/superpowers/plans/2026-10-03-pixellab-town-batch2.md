# PixelLab Town Batch 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the town's defences, townhouses, barns, civic buildings and market stalls with PixelLab sprites in the reference's style, with gameplay unchanged.

**Architecture:** The batch 1 sprite path (`SpriteArt` → `SpriteView` → `structure_sprite.gdshader`) gains new name mappings and one new feature: *strip* sets, where every wall piece draws its own stretch of one long, repeating wall texture, chosen from where the piece stands, so neighbours join at any length. Everything else is assets made with the batch 1 recipe and recorded in `assets/pixellab/buildings/manifest.json`.

**Tech Stack:** Godot 4.7.2 (GDScript, GL Compatibility), Python 3.12 + Pillow, PixelLab REST via `tools/dev/pixellab_api.py`.

**Spec:** `docs/superpowers/specs/2026-10-03-pixellab-town-batch2-design.md`

## Global Constraints

- Branch `feat/pixellab-structures`, worktree `C:\BURIN_NITRO\Godot\GIT\vfxProve-pixellab`. Never touch `C:\BURIN_NITRO\Godot\GIT\vfxProve` (another session works there).
- Native 1:1 scale: never resize a sprite to fit; fix the canvas or the anchor instead.
- `Structure` state, its rng stream, hits and gameplay must not change. `state_digest` stays `61267b7e90524d800bf1c3473a71146b`.
- PixelLab budget for this batch: ~690 generations of the 873 left. Group shares: defences ~260, houses ~120, civic ~220, market ~50. A set that has used its share without an acceptable pick stays procedural (remove its manifest entry) and is logged as open.
- Every PixelLab call is logged in `docs/pixellab_structures_log.md` (tool, prompt, refs, seed, cost from `balance` before/after, pick, fix).
- Glow: `tools/dev/check_sprite_glow.py` must report every sprite under 5%.
- Commits: stage files by name, never `git commit -a`. Messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Shell paths on this laptop (Git Bash):
  - `G=C:/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe` (Godot console exe)
  - `PY=/c/Users/dorae/AppData/Local/Programs/Python/Python312/python.exe` (Bash's `python` is the Store stub; always use `$PY`)
  - Tests: `GODOT=$G bash tools/test.sh 2>&1 | tail -3` and `GODOT=$G bash tools/test.sh 2>&1 | grep -c "SCRIPT ERROR"` (must print `0`).
  - Digest: `"$G" --headless --path . -s tools/dev/state_digest.gd 2>&1 | tail -1`
- Never print or paste the PixelLab key.

## Review Focus

1. **A wall run crossing the strip's period boundary** (a piece whose `u0 + length` passes `period`, and the next piece wrapping to small `u0`): it must still join its neighbour with no jog — pinned in Task 1's wrap test.
2. **Wall runs along y (west/east walls)**: they draw the strip mirrored and measure along y; a y-run piece must read the same stretch an x-run piece at the same coordinate does — pinned in Task 1's mirror test.
3. **Sprites turned off (F7) or a set missing its stills**: every town structure falls back to its procedural art with no warnings spam and no crash — pinned in Task 1 (no manifest entries yet → `set_for` returns `{}`), and by the existing toggle test.
4. **The side gate** (`SIDE_GATE` 1.1 × 2.0) draws `town_gate` mirrored, and the **postern** (a wall piece tagged `postern`) gets its own sprite, not a strip stretch — pinned in Task 1's mapping cases.
5. **Windmill and watermill** (role `farm`, tags `windmill`/`watermill`) must stay procedural while barns (role `farm`, no tag) get `barn` — pinned in Task 1's mapping cases.

---

## Sprite recipe (used by Tasks 3–14)

Each asset task gives a **parameters table** (name, manifest entry, canvas, style ref, prompts, collapse yes/no, generation cap). Run these steps with those values. `<n>` is the set name; `D=assets/pixellab/buildings/<n>`; `S=<scratchpad>/<n>` (the session scratchpad dir, never committed).

- **R1 — Manifest entry and reference.** Add the entry to `assets/pixellab/buildings/manifest.json` (keys: `size`, `footprint`, `height`, `seed`, `kind`, `role`, `tag`; add `"collapse_frames": 9` later only if a collapse is made). Then:
  ```bash
  "$G" --path . --audio-driver Dummy -s tools/dev/render_sprite_refs.gd 2>&1 | grep -v '^\s*at:' | tail -20
  ```
  It writes `$D/reference.png` for every entry (never run it with `--placeholders` now: that overwrites real stills). If it exits 1 ("touches its canvas edge"), grow that entry's `size` and run again. Read `$D/reference.png`.
- **R2 — Style ref.** Add the set's box to `tools/dev/make_style_refs.py` (Task 2 adds per-sheet support), run `$PY tools/dev/make_style_refs.py --sheet`, read `captures/style_refs_sheet.png` and `$D/style_ref.png`; adjust the box until the crop holds exactly the reference building.
- **R3 — Balance.** `$PY tools/dev/pixellab_api.py balance` → note it in the log.
- **R4 — Generate.**
  ```bash
  $PY tools/dev/pixellab_api.py generate --size <W>x<H> --out $S/gen1 \
    --desc "<intact prompt>" \
    --ref "$D/reference.png=exact footprint, isometric 2:1 camera angle, silhouette, proportions and size of the building; keep this composition and position on the canvas" \
    --ref "$D/style_ref.png=art style only: palette, outline, texture detail and shading" \
    [--ref "<family ref intact.png>=the same town: match this building's stone, roof and trim exactly"]
  ```
  Then make a review sheet: `$PY tools/dev/sprite_fix.py sheet $D/reference.png $S/gen1 <prefix> $S/sheet1.png 3 6` (`<prefix>` = the file prefix the helper printed, e.g. `generate`). Read the sheet. Pick a candidate that does not touch the canvas edge, sits on the reference's footprint (bbox `bottom dy` within ±3, `centre dx` within ±4), and matches the style ref. If none fits, re-roll once with a sharper prompt (a new `--out` dir); stop at the task's cap.
- **R5 — Fit.** Copy the pick to `$D/intact.png`. Run `$PY tools/dev/sprite_fix.py profile $D/intact.png 2` and `$PY tools/dev/sprite_fix.py footprint $D/intact.png $S/fp.png <fw> <fd> <ax>,<ay>` with the default anchor and ±2 px variants; read `$S/fp.png`; set `"anchor": [x, y]` in the manifest to the variant whose cyan diamond sits on the building's base.
- **R6 — Damaged and ruins.**
  ```bash
  $PY tools/dev/pixellab_api.py edit --image $D/intact.png --out $S/dmg --desc "<damaged prompt>"
  $PY tools/dev/pixellab_api.py edit --image $D/intact.png --out $S/ruin --desc "<ruins prompt>"
  ```
  Pick each (same canvas, same position). Save as `$D/damaged.png`, `$D/ruins.png`. Ruins usually come back 5–22 px high: find the shift with `$PY tools/dev/sprite_fix.py corner $D/intact.png $D/ruins.png` (compare lowest rows) and apply `$PY tools/dev/sprite_fix.py shift $D/ruins.png $D/ruins.png 0 <dy>`. If a floating piece stays in the ruins, `$PY tools/dev/sprite_fix.py largest $D/ruins.png $D/ruins.png`. If a still comes back on a white background, `$PY tools/dev/sprite_fix.py unwhite <in> <out>`.
- **R7 — Collapse (only where the table says yes).**
  ```bash
  $PY tools/dev/pixellab_api.py animate --first $D/damaged.png --last $D/ruins.png --frames 8 --out $S/col \
    --action "the building crumbles from the top down into a heap of rubble, dust; it is never repaired"
  $PY tools/dev/sprite_fix.py strip "$S/col/*.png" $D/collapse.png
  ```
  Check the frames never "heal" (a later frame more intact than an earlier one); re-roll once if they do. Set `"collapse_frames": <frame count>` in the manifest.
- **R8 — Check and capture.**
  ```bash
  $PY tools/dev/check_sprite_glow.py
  "$G" --path . --audio-driver Dummy -s tools/dev/sprite_states.gd 2>&1 | grep -v '^\s*at:' | tail -5
  ```
  Glow under 5% for the new set (if over, darken the offending bright warm pixels a touch with Pillow and re-check). Read `captures/sprite_states/<n>.png`: intact, damaged, falling and ruins sit on the same footprint with no jump.
- **R9 — Register and test.** Add `<n>` to `NAMES` in `tests/test_sprite_art.gd`. Run the tests (Global Constraints); expect `failures=0` and `0` script errors.
- **R10 — Log and commit.** Log every call (R3–R7) in `docs/pixellab_structures_log.md` under a `## Batch 2` heading, then:
  ```bash
  git add assets/pixellab/buildings/<n> assets/pixellab/buildings/manifest.json tests/test_sprite_art.gd docs/pixellab_structures_log.md tools/dev/make_style_refs.py
  git commit -m "feat: PixelLab <n> sprite: intact, damaged, ruins[, generated collapse]

  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  ```

---

### Task 1: Engine — new mappings and wall strips

**Files:**
- Modify: `src/environment/art/sprite_art.gd` (`name_for`, `sprite`, `set_for`; new `strip_piece`, consts)
- Modify: `src/environment/art/sprite_view.gd` (`_draw`)
- Modify: `src/environment/structure.gd:460-466` (`_grow_view_box_for_sprite`)
- Test: `tests/test_sprite_art.gd`

**Interfaces:**
- Produces: `SpriteArt.name_for(s)` returns `"town_tower"`, `"town_tower_corner"`, `"bell_tower"`, `"town_wall"`, `"town_gate"`, `"town_postern"`, `"townhouse_a"`, `"townhouse_b"`, `"barn"`, `"barracks"`, `"workshop"`, `"carpenter"`, `"stall_red"`, `"stall_blue"`, `"stall_cream"` for the cases below.
- Produces: manifest keys `"strip": true` and `"period": <units>` (a multiple of 1/16) on strip sets; built sets carry `"strip": bool`, `"period": float`, `"region": Rect2` (`Rect2()` = whole frame).
- Produces: `static func strip_piece(base: Dictionary, fp: Rect2, mirrored: bool) -> Dictionary` → `{"anchor": Vector2, "region": Rect2}`.

- [ ] **Step 1: Write the failing tests**

In `tests/test_sprite_art.gd`, replace the `cases` array in `_mapping` with:

```gdscript
	var cases := [
		[Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, &"house", &"", "cottage"],
		[Rect2(0, 0, 1.3, 0.95), 29.0, K.HOUSE, &"house", &"townhouse", "townhouse"],
		[Rect2(0, 0, 1.3, 1.5), 20.0, K.HOUSE, &"farm", &"", "barn"],
		[Rect2(0, 0, 0.9, 0.9), 60.0, K.HOUSE, &"farm", &"windmill", ""],
		[Rect2(0, 0, 2.4, 1.9), 34.0, K.HOUSE, &"farm", &"watermill", ""],
		[Rect2(0, 0, 2.4, 1.5), 30.0, K.HOUSE, &"house", &"tavern", "tavern"],
		[Rect2(0, 0, 1.5, 1.25), 20.0, K.HOUSE, &"house", &"smithy", "smithy"],
		[Rect2(0, 0, 2.6, 1.5), 22.0, K.HOUSE, &"house", &"workshop", "workshop"],
		[Rect2(0, 0, 2.3, 1.15), 20.0, K.HOUSE, &"house", &"carpenter", "carpenter"],
		[Rect2(0, 0, 4.2, 6.2), 56.0, K.TEMPLE, &"temple", &"cathedral", "cathedral"],
		[Rect2(0, 0, 2.0, 2.0), 118.0, K.KEEP, &"citadel", &"", "citadel_keep"],
		[Rect2(0, 0, 1.3, 1.3), 84.0, K.KEEP, &"citadel", &"", "citadel_tower"],
		[Rect2(0, 0, 1.6, 1.6), 46.0, K.KEEP, &"tower", &"", "town_tower"],
		[Rect2(0, 0, 2.0, 2.0), 50.0, K.KEEP, &"tower", &"", "town_tower_corner"],
		[Rect2(0, 0, 1.1, 1.1), 60.0, K.KEEP, &"tower", &"bell_tower", "bell_tower"],
		[Rect2(0, 0, 2.8, 0.6), 40.0, K.CASTLE_WALL, &"citadel", &"", "citadel_wall"],
		[Rect2(0, 0, 0.6, 2.0), 40.0, K.CASTLE_WALL, &"citadel", &"", "citadel_wall_side"],
		[Rect2(0, 0, 2.8, 0.6), 40.0, K.CASTLE_WALL, &"citadel", &"gate", "citadel_gate"],
		[Rect2(0, 0, 1.2, 0.7), 34.0, K.CASTLE_WALL, &"wall", &"", "town_wall"],
		[Rect2(0, 0, 0.7, 1.1), 34.0, K.CASTLE_WALL, &"wall", &"", "town_wall"],
		[Rect2(0, 0, 2.0, 1.1), 34.0, K.GATE, &"gate", &"", "town_gate"],
		[Rect2(0, 0, 1.1, 2.0), 34.0, K.GATE, &"gate", &"", "town_gate"],
		[Rect2(0, 0, 1.15, 0.7), 34.0, K.GATE, &"gate", &"postern", "town_postern"],
		[Rect2(0, 0, 4.4, 1.9), 36.0, K.BARRACKS, &"barracks", &"", "barracks"],
		[Rect2(0, 0, 0.9, 0.7), 10.0, K.MARKET_STALL, &"market", &"", "stall"],
	]
	for c in cases:
		var s := _make(c[0], c[1], c[2], 5, c[3], c[4])
		var got := SpriteArt.name_for(s)
		var want: String = c[5]
		var ok := got.begins_with(want + "_") if want in ["cottage", "townhouse", "stall"] else got == want
		t.check(ok, "sprite for %s/%s/%s is '%s' (got '%s')" % [K.keys()[c[2]], c[3], c[4], want, got])
		s.free()
```

Directly after the cottage-roof block (after `t.check(seen.has("cottage_red") and seen.has("cottage_blue"), ...)`), add:

```gdscript
	# Townhouses pick one of two looks from their seed, as cottages pick a roof.
	var looks := {}
	for sd in 40:
		var th := _make(Rect2(0, 0, 1.3, 0.95), 29.0, K.HOUSE, sd, &"house", &"townhouse")
		looks[SpriteArt.name_for(th)] = true
		th.free()
	t.check(looks.has("townhouse_a") and looks.has("townhouse_b") and looks.size() == 2, "both townhouse looks appear")
	# A stall keeps today's awning: PropArt picks cloth = seed % 3 (red, blue, cream).
	for sd in [3, 4, 5]:
		var st := _make(Rect2(0, 0, 0.9, 0.7), 10.0, K.MARKET_STALL, sd, &"market")
		var want: String = ["stall_red", "stall_blue", "stall_cream"][int(st.art.cloth)]
		t.check(SpriteArt.name_for(st) == want, "a stall with cloth %d is %s" % [int(st.art.cloth), want])
		st.free()
```

Add a new test function and call it from `run` (after `_view(t)`):

```gdscript
## A wall piece reads its own stretch of its strip, from where it stands: neighbours join, a run wraps at the strip's
## period without a jog, and a run along y reads the strip mirrored the way a run along x reads it.
static func _strip(t) -> void:
	# A strip spanning 3.7 units (period 2.5 + one 1.2 piece) whose run starts (u = 0) at pixel (30, 100).
	var base := {"anchor": Vector2(30, 100) + Vector2(32, 16) * 3.7, "footprint": Vector2(3.7, 0.7),
		"size": Vector2(170, 170), "period": 2.5}
	var a := SpriteArt.strip_piece(base, Rect2(10.0, 3.0, 1.2, 0.7), false)
	var b := SpriteArt.strip_piece(base, Rect2(11.2, 3.0, 1.1, 0.7), false)
	var c := SpriteArt.strip_piece(base, Rect2(12.3, 3.0, 1.2, 0.7), false)
	var d := SpriteArt.strip_piece(base, Rect2(13.5, 3.0, 1.0, 0.7), false)
	t.check(a.region.position.is_equal_approx(Vector2(30, 0)) and is_equal_approx(a.region.size.x, 38.4)
		and is_equal_approx(a.region.size.y, 170.0), "a piece at the period's start reads the strip's first stretch")
	t.check(a.anchor.is_equal_approx(Vector2(30, 100) + Vector2(32, 16) * 1.2), "anchored at its own front corner")
	t.check(is_equal_approx(b.region.position.x, a.region.end.x) and is_equal_approx(c.region.position.x, b.region.end.x),
		"each piece starts where the one before it ends")
	t.check((b.anchor - a.anchor).is_equal_approx(Vector2(32, 16) * 1.1)
		and (c.anchor - b.anchor).is_equal_approx(Vector2(32, 16) * 1.2), "and is placed one piece further along")
	t.check(c.region.end.x <= 170.0 + 0.001, "a piece running past the period stays inside the strip")
	# d wraps to the period's start: its stretch is c's continuation one period back.
	t.check(d.anchor.x < c.anchor.x and (d.anchor + Vector2(32, 16) * 2.5 - c.anchor).is_equal_approx(Vector2(32, 16) * 1.0),
		"a run wraps at the period without a jog")
	var y := SpriteArt.strip_piece(base, Rect2(3.0, 10.0, 0.7, 1.2), true)
	t.check(y.anchor.is_equal_approx(a.anchor) and y.region.is_equal_approx(a.region),
		"a run along y reads the strip mirrored, measured along y")
	for n in SpriteArt.manifest():
		var m: Dictionary = SpriteArt.manifest()[n]
		if m.get("strip", false):
			t.check(float(m.footprint[0]) >= float(m.period) + 1.2 - 0.001 and is_equal_approx(fmod(float(m.period) * 16.0, 1.0), 0.0),
				"%s spans a period plus a piece, and its period is a whole number of pixels" % n)
```

In `_structure`, replace the no-sprite case:

```gdscript
	var proc := _make(Rect2(0, 0, 0.9, 0.9), 60.0, K.HOUSE, 8, &"farm", &"windmill")
	t.check(proc.sprite.is_empty() and proc.sprite_state() == &"", "a building without a sprite keeps its art")
	proc.free()
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `GODOT=$G bash tools/test.sh 2>&1 | grep -E "FAIL|SCRIPT ERROR|checks=" | head -20`
Expected: FAILs on the new mapping cases (e.g. `sprite for KEEP/tower/ is 'town_tower' (got '')`) and a `SCRIPT ERROR` for the missing `strip_piece`.

- [ ] **Step 3: Implement the mappings**

In `src/environment/art/sprite_art.gd`, after `const SALT_ROOF := 90` add:

```gdscript
## ArtKit.hash01 salt for a townhouse's look.
const SALT_TOWNHOUSE := 91
## A market stall's sprite by its awning (PropArt.CLOTH's index, the stall's art.cloth).
const STALLS := ["stall_red", "stall_blue", "stall_cream"]
## The longest piece a wall run is cut into (TownLayout.WALL_PIECE): a strip spans its period plus this.
const STRIP_PIECE := 1.2
```

Replace `name_for` with:

```gdscript
## The sprite that replaces `s`, or "" (only buildings with a set in the manifest are drawn from one).
static func name_for(s: Structure) -> String:
	match s.kind:
		Structure.Kind.HOUSE:
			if s.role == &"farm":
				# A barn; the windmill and watermill keep their turning procedural art.
				return "barn" if s.art_tag == &"" else ""
			if s.role != &"house":
				return ""
			match s.art_tag:
				&"":
					return "cottage_red" if ArtKit.hash01(s.rng.seed, SALT_ROOF) < 0.5 else "cottage_blue"
				&"townhouse":
					return "townhouse_a" if ArtKit.hash01(s.rng.seed, SALT_TOWNHOUSE) < 0.5 else "townhouse_b"
				&"tavern":
					return "tavern"
				&"smithy":
					return "smithy"
				&"workshop":
					return "workshop"
				&"carpenter":
					return "carpenter"
		Structure.Kind.TEMPLE:
			if s.art_tag == &"cathedral":
				return "cathedral"
		Structure.Kind.KEEP:
			# The Citadel's keep and towers share their kind and role; only their size tells them apart. So do the town's
			# corner towers (2.0) and wall and gate towers (1.6).
			if s.role == &"citadel":
				return "citadel_keep" if s.footprint.size.x >= 1.8 else "citadel_tower"
			if s.role == &"tower":
				if s.art_tag == &"bell_tower":
					return "bell_tower"
				return "town_tower_corner" if s.footprint.size.x >= 1.8 else "town_tower"
		Structure.Kind.CASTLE_WALL:
			if s.role == &"citadel":
				if s.art_tag == &"gate":
					return "citadel_gate"
				var long := maxf(s.footprint.size.x, s.footprint.size.y)
				return "citadel_wall" if long >= 2.4 else "citadel_wall_side"
			if s.role == &"wall":
				return "town_wall"
		Structure.Kind.GATE:
			# The side gate is the main gate turned, so it draws the same sprite mirrored.
			if s.role == &"gate":
				return "town_postern" if s.art_tag == &"postern" else "town_gate"
		Structure.Kind.BARRACKS:
			return "barracks"
		Structure.Kind.MARKET_STALL:
			return STALLS[int(s.art.get("cloth", 0)) % STALLS.size()]
	return ""
```

- [ ] **Step 4: Implement strips**

In `sprite()`, add to the `built` dictionary (after `"shadow": ...`):

```gdscript
		# A strip set (the town wall): one long run of wall repeating every `period` ground units; each piece draws its
		# own stretch of it (strip_piece()), so `region` is set per structure in set_for(). Rect2() = the whole frame.
		"strip": bool(m.get("strip", false)), "period": float(m.get("period", 0.0)), "region": Rect2(),
```

In `set_for`, replace `return out` with:

```gdscript
	if out.strip:
		var piece := strip_piece(base, s.footprint, out.mirror)
		out.anchor = piece.anchor
		out.region = piece.region
	return out
```

Add after `set_for`:

```gdscript
## A wall piece's stretch of its strip set `base`. The strip is a run along ground x drawn on its canvas with its
## footprint's front corner at `anchor` (as every set); its front edge at run distance u sits at pixel
## anchor - (32, 16) * (footprint.x - u), and it repeats every `period` units. A piece covering [start, start + length)
## of its run reads u0 = start mod period onward: the strip's columns for its stretch, anchored at its own front corner.
## Pieces read their stretch from where they stand, so neighbours join, and a run wraps at the period without a jog
## (the strip spans a period plus the longest piece, STRIP_PIECE). A run along y is the strip mirrored (`mirrored`),
## measured along y. Nothing is rounded: rounding would shift a piece a pixel against its neighbour.
static func strip_piece(base: Dictionary, fp: Rect2, mirrored: bool) -> Dictionary:
	var start := fp.position.y if mirrored else fp.position.x
	var length := fp.size.y if mirrored else fp.size.x
	var u0 := fposmod(start, float(base.period))
	var span: float = (base.footprint as Vector2).x
	var run0: Vector2 = (base.anchor as Vector2) - Vector2(32.0, 16.0) * span
	var size: Vector2 = base.size
	var x0 := run0.x + 32.0 * u0
	return {"anchor": run0 + Vector2(32.0, 16.0) * (u0 + length), "region": Rect2(x0, 0.0, 32.0 * length, size.y)}
```

- [ ] **Step 5: Draw regions**

In `src/environment/art/sprite_view.gd`, replace the last three lines of `_draw` (from `var origin := ...`) with:

```gdscript
	var origin := Vector2(frame * size.x, 0.0)
	var src := Rect2(origin, size)
	# A strip piece draws only its stretch of the strip (SpriteArt.strip_piece); strips have no idle or collapse, so
	# its frame is always 0.
	var region: Rect2 = sprite.get("region", Rect2())
	if region.has_area():
		src = region
	_mat.set_shader_parameter("frame_origin", origin)
	draw_texture_rect_region(tex, Rect2(src.position - origin - at, src.size), src, color)
```

In `src/environment/structure.gd`, replace `_grow_view_box_for_sprite` with:

```gdscript
## Its view box takes in the whole sprite: a spire or a chimney can rise above the procedural box. A strip piece takes in
## only its own stretch of the strip.
func _grow_view_box_for_sprite() -> void:
	if sprite.is_empty():
		return
	var size: Vector2 = sprite.size
	var at: Vector2 = sprite.anchor
	var region: Rect2 = sprite.get("region", Rect2())
	if region.has_area():
		size = region.size
		at -= region.position
	var x0 := _base.x - (size.x - at.x if sprite.mirror else at.x)
	_view_box = _view_box.merge(Rect2(Vector2(x0, _base.y - at.y), size).grow(VIEW_BOX_MARGIN))
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `GODOT=$G bash tools/test.sh 2>&1 | tail -3` → `checks=` above 1333, `failures=0`.
Run: `GODOT=$G bash tools/test.sh 2>&1 | grep -c "SCRIPT ERROR"` → `0`.
Run the digest → `61267b7e90524d800bf1c3473a71146b`.

- [ ] **Step 7: Commit**

```bash
git add src/environment/art/sprite_art.gd src/environment/art/sprite_view.gd src/environment/structure.gd tests/test_sprite_art.gd
git commit -m "feat: sprite mappings for the town's defences, houses, civic buildings and stalls; wall strips

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Tools — style refs from any sheet, and the strip tiler

**Files:**
- Modify: `tools/dev/make_style_refs.py` (per-entry source sheet)
- Modify: `tools/dev/sprite_fix.py` (new `tile` command)

**Interfaces:**
- Produces: `BOXES` entries may be `(sheet_name, (x0, y0, x1, y1))`; a bare 4-tuple still means `TownMap_Component1.png`.
- Produces: `python tools/dev/sprite_fix.py tile <src> <dst> <u0x>,<u0y> <period> <span>` — builds a strip; prints the manifest values `size`, `anchor`, `footprint[0]`.

- [ ] **Step 1: Per-entry sheet in `make_style_refs.py`**

Change `SRC` to a sheets folder and resolve per entry. Replace `SRC = ROOT / "concepts" / "TOWN REF" / "TownMap_Component1.png"` with:

```python
SHEETS = ROOT / "concepts" / "TOWN REF"
DEFAULT_SHEET = "TownMap_Component1.png"
```

Add these entries to `BOXES` (start boxes; R2 adjusts them with `--sheet`):

```python
    "town_tower": ("TownMap_Component4.png", (40, 470, 185, 695)),
    "town_tower_corner": ("TownMap_Component4.png", (40, 470, 185, 695)),
    "town_wall": ("TownMap_Component4.png", (40, 40, 300, 245)),
    "town_gate": ("TownMap_Component4.png", (35, 210, 405, 495)),
    "town_postern": ("TownMap_Component4.png", (425, 280, 610, 470)),
    "bell_tower": ("TownMap_Component4.png", (495, 470, 620, 700)),
    "stall_red": ("TownMap_Component2.png", (10, 20, 155, 165)),
    "stall_blue": ("TownMap_Component2.png", (150, 20, 295, 165)),
    "stall_cream": ("TownMap_Component2.png", (15, 170, 155, 295)),
```

Where the script opens the sheet and loops `BOXES`, open each entry's own sheet (cache opened sheets in a dict):

```python
def _box(entry):
    """(sheet path, box) for a BOXES entry; a bare box is on the default sheet."""
    if isinstance(entry[0], str):
        return SHEETS / entry[0], entry[1]
    return SHEETS / DEFAULT_SHEET, entry
```

Use `_box(BOXES[name])` wherever the script currently uses `SRC` and `BOXES[name]`, opening each sheet once (`sheets.setdefault(path, Image.open(path).convert("RGBA"))`). In `--sheet` mode draw each box on its own sheet and save one check image per sheet: `captures/style_refs_sheet_<sheet stem>.png` (keep `captures/style_refs_sheet.png` for the default sheet). Only entries present in the manifest are written (skip names whose `assets/pixellab/buildings/<name>/` folder does not exist yet: create the folder only when the manifest has the entry).

Run: `$PY tools/dev/make_style_refs.py --sheet` → no error; batch 1 `style_ref.png` files are unchanged (`git status --short assets/` shows nothing).

- [ ] **Step 2: The strip tiler in `sprite_fix.py`**

Add to the docstring: `tile <src> <dst> <u0x>,<u0y> <period> <span>   repeat one generated wall run into a seamless strip`. Add `import math` at the top, and:

```python
def tile(src, dst, u0, period, span):
    """A seamless wall strip from one generated run along ground x. `u0` is the pixel of the run's front edge at
    u = 0; `period` (ground units, a multiple of 1/16 so it shifts by whole pixels) is where the art repeats -- pick it
    at matching merlons. The strip keeps the source's columns left of u = period, then repeats the band of columns for
    u in [0, period) every period (32*period px right, 16*period px down) until it spans `span` units plus the wall's
    0.7-unit depth. Prints the manifest values for the strip."""
    im = _rgba(src)
    ux, uy = (float(v) for v in u0.split(","))
    S, span = float(period), float(span)
    dx, dy = 32.0 * S, 16.0 * S
    if dx != int(dx) or dy != int(dy):
        sys.exit("period must be a multiple of 1/16 unit")
    dx, dy = int(dx), int(dy)
    ax = int(round(ux))
    cut = ax + dx
    w = int(math.ceil(ux + 32.0 * (span + 0.7))) + 2
    h = im.height + int(math.ceil(16.0 * (span - S)))
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(im.crop((0, 0, min(cut, im.width), im.height)), (0, 0))
    band = im.crop((ax, 0, cut, im.height))
    k = 1
    while ax + k * dx < w:
        out.paste(band, (ax + k * dx, k * dy))
        k += 1
    out.save(dst)
    anchor = (ux + 32.0 * span, uy + 16.0 * span)
    print("size", [w, h], "anchor", [round(anchor[0], 3), round(anchor[1], 3)], "footprint", [span, 0.7], "period", S)
```

Register it: add `"tile": tile` to the command dict at the bottom.

Run a smoke test on any batch 1 still: `$PY tools/dev/sprite_fix.py tile assets/pixellab/buildings/citadel_wall/intact.png $S/tile_test.png 20,60 1.0 2.2` → prints `size`, `anchor`, `footprint`, `period`; no error.

- [ ] **Step 3: Commit**

```bash
git add tools/dev/make_style_refs.py tools/dev/sprite_fix.py
git commit -m "feat: style refs from any reference sheet; sprite_fix tile builds seamless wall strips

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: `town_tower` (the defences' family ref)

Run the **Sprite recipe** R1–R10 with:

| Key | Value |
|---|---|
| Manifest | `"town_tower": {"size": [112, 136], "footprint": [1.6, 1.6], "height": 46, "seed": 41, "kind": "KEEP", "role": "tower", "tag": ""}` |
| Style ref | `TownMap_Component4.png` square tower with blue fleur-de-lis banner and a lit torch on top |
| Intact prompt | "isometric pixel art medieval town wall tower, square, grey limestone blocks, crenellated top with a burning torch brazier, a blue banner with a gold fleur-de-lis hanging on the front face, small arched window, moss at the foot, high detail, crisp dark outline, no ground, transparent background" |
| Damaged prompt | "the same tower damaged: cracked and missing stone blocks, broken merlons, the banner torn, scorch marks, torch out; same tower, same position, transparent background" |
| Ruins prompt | "the same tower collapsed into ruins: a low heap of grey stone rubble with a short broken stump of wall, on the same footprint, transparent background" |
| Collapse | no (engine sink) |
| Cap | 70 generations |

Extra step after R8: show the user `captures/sprite_states/town_tower.png` next to the style ref and confirm the look before Tasks 4–6 use it as the family ref (the controller does this).

---

### Task 4: `town_tower_corner`

Recipe with:

| Key | Value |
|---|---|
| Manifest | `"town_tower_corner": {"size": [140, 152], "footprint": [2.0, 2.0], "height": 50, "seed": 42, "kind": "KEEP", "role": "tower", "tag": ""}` |
| Style ref | same box as `town_tower` |
| Family ref | `assets/pixellab/buildings/town_tower/intact.png` (third `--ref`) |
| Intact prompt | "isometric pixel art medieval town wall corner tower, larger and squarer than the wall towers, grey limestone blocks, crenellated top with a burning torch brazier at each front corner, two blue banners with gold fleur-de-lis, moss at the foot, high detail, crisp dark outline, no ground, transparent background" |
| Damaged / ruins prompts | as Task 3, with "corner tower" for "tower" |
| Collapse | no |
| Cap | 60 |

---

### Task 5: `town_wall` (the strip)

**Files:** as the recipe, plus `$D/run_intact.png`, `$D/run_damaged.png`, `$D/run_ruins.png` (the untiled sources, committed for re-tiling).

- [ ] **Step 1: Generate one long run** — manifest entry first as a plain set for the reference render: `"town_wall": {"size": [192, 152], "footprint": [4.0, 0.7], "height": 34, "seed": 43, "kind": "CASTLE_WALL", "role": "wall", "tag": ""}`; R1–R4 with:
  - prompt: "isometric pixel art medieval town wall, a straight run of grey limestone blocks with regular crenellations (merlons evenly spaced), a walkway behind the parapet, a few moss patches and small bushes at the foot, no towers, no gate, both ends cut straight, high detail, crisp dark outline, no ground, transparent background";
  - family ref: `town_tower/intact.png` ("the same town wall: match this tower's stone and merlons exactly").
  - Pick the candidate with the most regular merlon spacing. Save as `$D/run_intact.png`.
- [ ] **Step 2: Find u = 0 and the period.** `$PY tools/dev/sprite_fix.py profile $D/run_intact.png 2` gives the base line. The front edge pixel at u = 0 is the front-left end of the run's base (`u0x`, `u0y`); confirm with `footprint` drawn at the derived front corner `u0 + (128, 64)` for a 4.0 run. Choose `period` (a multiple of 0.0625, between 1.5 and 2.6) as the distance between two merlons whose shapes match, so the column at `u0x + 32*period` looks like the column at `u0x`.
- [ ] **Step 3: Tile and check the seam.** `$PY tools/dev/sprite_fix.py tile $D/run_intact.png $D/intact.png <u0x>,<u0y> <period> <period+1.2>`. Read `$S/seam.png` made by `$PY tools/dev/sprite_fix.py view $S/seam.png 4 $D/intact.png`. If the join at `u0x + 32*period` shows a step or a broken merlon, inpaint a mask over the seam column band on `run_intact.png` (`$PY tools/dev/pixellab_api.py inpaint --image $D/run_intact.png --mask <mask.png> --desc "continue the wall seamlessly" --out $S/seam`), then tile again.
- [ ] **Step 4: Damaged and ruins** — R6 on `$D/run_intact.png` → `$D/run_damaged.png`, `$D/run_ruins.png` (shift ruins as usual), then tile each with the same `u0`, `period`, `span` into `$D/damaged.png` and `$D/ruins.png`. Prompts: damaged "the same wall damaged: cracked and missing blocks, broken merlons, scorch marks; same wall, same position"; ruins "the same wall collapsed into a low line of grey stone rubble with short broken stumps, same footprint". All three must tile with identical parameters.
- [ ] **Step 5: Manifest as a strip** — replace the entry with the tiler's printout: `"town_wall": {"size": [W, H], "footprint": [span, 0.7], "height": 34, "seed": 43, "kind": "CASTLE_WALL", "role": "wall", "tag": "", "anchor": [ax, ay], "strip": true, "period": S}`. Do **not** re-run `render_sprite_refs.gd` after this (its reference for the strip is irrelevant now).
- [ ] **Step 6: In-town check** — R8, R9, then a town capture: `GODOT=$G SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --capture-town --only=town_market`. Read it: the north and west walls run continuously between towers, no 1 px jogs or gaps at piece joins, the west wall mirrored.
- [ ] **Step 7:** R10 (add the `run_*.png` files to the `git add`). Cap for the whole task: 80.

---

### Task 6: `town_gate` and `town_postern`

`town_gate` recipe:

| Key | Value |
|---|---|
| Manifest | `"town_gate": {"size": [124, 132], "footprint": [2.0, 1.1], "height": 34, "seed": 44, "kind": "GATE", "role": "gate", "tag": ""}` |
| Style ref | `TownMap_Component4.png` gatehouse with portcullis |
| Family ref | `town_tower/intact.png` |
| Intact prompt | "isometric pixel art medieval town gatehouse, grey limestone, a round-arched gateway with a raised iron portcullis and open wooden doors, crenellated top, two wall torches lit beside the arch, a blue fleur-de-lis banner, high detail, crisp dark outline, no ground, transparent background" |
| Damaged / ruins | "the same gatehouse damaged: cracked stone, broken merlons, the portcullis bent, scorch marks" / "the same gatehouse collapsed into rubble around a broken arch stump, same footprint" |
| Collapse | yes (R7) |
| Cap | 60 |

`town_postern`: first find its exact footprint: run `"$G" --headless --path . --script` is not needed — read `TownLayout.walls()`/`wall_pieces()` and `POSTERN_AT` (-5.75, 15.65) in `src/game/town/town_layout.gd`; compute the piece containing it with a one-off GDScript in the scratchpad (`for r in TownLayout.walls(): for p in TownLayout.wall_pieces(r): if p.has_point(TownLayout.POSTERN_AT): print(p)`) run via `"$G" --headless --path . -s <scratch>.gd`. Use that size as the footprint.

| Key | Value |
|---|---|
| Manifest | `"town_postern": {"size": [80, 96], "footprint": [<w>, <d>], "height": 34, "seed": 45, "kind": "GATE", "role": "gate", "tag": "postern"}` |
| Style ref | `TownMap_Component4.png` small arched door tower box |
| Family ref | `town_wall/run_intact.png` ("the same wall: match its stone and merlons exactly") |
| Intact prompt | "isometric pixel art piece of medieval town wall with a small arched wooden postern door at its foot, grey limestone, crenellated top, high detail, crisp dark outline, no ground, transparent background" |
| Damaged / ruins | as Task 5's wall prompts, "with the small door" |
| Collapse | no |
| Cap | 40 |

Commit each set separately (R10).

---

### Task 7: Group 1 checkpoint (controller + user)

- [ ] Tests, glow, digest (Global Constraints).
- [ ] Bench: `GODOT=$G SCENE=res://scenes/mission.tscn bash tools/capture.sh --bench` and again with `--art=procedural`; record fps and draw calls in `docs/PixelLab_Structures_Proof.md` under a new "Batch 2" section. Sprites must be within noise (±2 fps) of procedural, draw calls not above.
- [ ] Town capture (Task 5 Step 6 command) and `captures/sprite_states/town_*.png`: show them to the user. **Stop for the user's review.** Apply requested fixes within the group's remaining budget.
- [ ] `git push origin feat/pixellab-structures`. Update the KAK Dev Ledger (controller, ArtifactData).

---

### Task 8: `townhouse_a` and `townhouse_b`

Recipe for each:

| Key | `townhouse_a` | `townhouse_b` |
|---|---|---|
| Manifest | `{"size": [88, 104], "footprint": [1.3, 0.95], "height": 30, "seed": 46, "kind": "HOUSE", "role": "house", "tag": "townhouse"}` | same with `"seed": 47` |
| Style ref | `TownMap_Component1.png` two-storey timber-framed house box (pick with `--sheet`) | a second two-storey house box, different roof colour |
| Family ref | `cottage_red/intact.png` ("the same town: match its plaster, timber and roof tiles") | `townhouse_a/intact.png` |
| Intact prompt | "isometric pixel art medieval two-storey townhouse, timber-framed cream plaster upper floor over stone ground floor, steep red clay tile roof, chimney, warm lit windows with shutters, wooden door, high detail, crisp dark outline, no ground, transparent background" | same with "steep slate blue tile roof, a small dormer window" |
| Damaged / ruins | "the same townhouse damaged: cracked plaster, broken roof tiles, a hole in the roof, scorch marks, a broken window" / "the same townhouse collapsed into a heap of rubble, broken tiles and charred beams, two short wall stumps, same footprint" | same |
| Collapse | yes | yes |
| Cap | 45 | 40 |

If either has a chimney, add `"chimney": [x, y]` (the chimney top pixel, as batch 1's cottages) so `ChimneySmoke` uses it.

---

### Task 9: `barn`

| Key | Value |
|---|---|
| Manifest | `"barn": {"size": [104, 100], "footprint": [1.3, 1.5], "height": 20, "seed": 48, "kind": "HOUSE", "role": "farm", "tag": ""}` |
| Style ref | `TownMap_Component1.png` / `Final Town_Ref01.png` farmhouse or barn box (pick with `--sheet`) |
| Family ref | `cottage_red/intact.png` |
| Intact prompt | "isometric pixel art medieval farm barn, weathered timber plank walls on a low stone base, steep brown thatched or wooden shingle roof, wide double barn door, a hay bale beside it, high detail, crisp dark outline, no ground, transparent background" |
| Damaged / ruins | "the same barn damaged: broken planks, holes in the roof, scorch marks" / "the same barn collapsed into a heap of planks, straw and beams, same footprint" |
| Collapse | yes |
| Cap | 35 |

---

### Task 10: Group 2 checkpoint (controller + user)

As Task 7 (tests, glow, digest, bench, captures `captures/sprite_states/townhouse_*.png`, `barn.png`, town capture; **stop for the user's review**; push; ledger).

---

### Task 11: `barracks`

| Key | Value |
|---|---|
| Manifest | `"barracks": {"size": [216, 172], "footprint": [4.4, 1.9], "height": 36, "seed": 49, "kind": "BARRACKS", "role": "barracks", "tag": ""}` |
| Style ref | `Final Town_Ref01.png` barracks yard / long timber hall box (pick with `--sheet`) |
| Family ref | `town_tower/intact.png` |
| Intact prompt | "isometric pixel art medieval soldiers' barracks, a long open-sided timber hall on stone footings, red tile roof, weapon racks with spears and shields, a small forge glowing orange at one end, a blue fleur-de-lis banner, high detail, crisp dark outline, no ground, transparent background" |
| Damaged / ruins | "the same barracks damaged: broken roof tiles, snapped posts, scorch marks, forge out" / "the same barracks collapsed into a long heap of timber, tiles and fallen racks, same footprint" |
| Collapse | yes |
| Cap | 80 |

The forge glow must pass the glow check (R8).

---

### Task 12: `workshop` and `carpenter`

| Key | `workshop` | `carpenter` |
|---|---|---|
| Manifest | `{"size": [148, 124], "footprint": [2.6, 1.5], "height": 22, "seed": 50, "kind": "HOUSE", "role": "house", "tag": "workshop"}` | `{"size": [128, 108], "footprint": [2.3, 1.15], "height": 20, "seed": 51, "kind": "HOUSE", "role": "house", "tag": "carpenter"}` |
| Style ref | `TownMap_Component1.png` open workshop box | `TownMap_Component1.png` / `TownMap_Component2.png` timber shed box |
| Family ref | `smithy/intact.png` | `workshop/intact.png` |
| Intact prompt | "isometric pixel art medieval craft workshop, an open-sided timber pavilion on stone footings, red tile roof, workbenches with tools, crates and barrels inside, high detail, crisp dark outline, no ground, transparent background" | "isometric pixel art medieval carpenter's shed, timber frame with plank walls, wooden shingle roof, stacked planks and logs, a saw horse, high detail, crisp dark outline, no ground, transparent background" |
| Damaged / ruins | "…damaged: broken roof, snapped posts, scorch marks" / "…collapsed into a heap of timber and tiles, same footprint" | same pattern |
| Collapse | yes | yes |
| Cap | 55 | 45 |

---

### Task 13: `bell_tower`

| Key | Value |
|---|---|
| Manifest | `"bell_tower": {"size": [84, 132], "footprint": [1.1, 1.1], "height": 60, "seed": 52, "kind": "KEEP", "role": "tower", "tag": "bell_tower"}` |
| Style ref | `TownMap_Component4.png` stone tower with open timber belfry and blue slate roof |
| Family ref | `town_tower/intact.png` |
| Intact prompt | "isometric pixel art medieval bell tower, slender square grey limestone tower, an open timber belfry at the top with a bronze bell visible, steep blue slate pyramid roof with a small flag, high detail, crisp dark outline, no ground, transparent background" |
| Damaged / ruins | "the same bell tower damaged: cracked stone, broken belfry posts, missing roof slates" / "the same bell tower collapsed into a heap of stone and timber with the bell on top, same footprint" |
| Collapse | yes |
| Cap | 40 |

---

### Task 14: Group 3 checkpoint (controller + user)

As Task 7 for `barracks`, `workshop`, `carpenter`, `bell_tower`; **stop for the user's review**; push; ledger.

---

### Task 15: Market stalls

- [ ] `stall_red` by the recipe:

| Key | Value |
|---|---|
| Manifest | `"stall_red": {"size": [68, 72], "footprint": [0.9, 0.7], "height": 10, "seed": 3, "kind": "MARKET_STALL", "role": "market", "tag": ""}` (seed 3: `3 % 3 = 0`, the red cloth) |
| Style ref | `TownMap_Component2.png` red-and-white striped stall |
| Intact prompt | "isometric pixel art medieval market stall, red and white striped scalloped awning on four wooden posts, a wooden counter heaped with fruit and vegetables in baskets, high detail, crisp dark outline, no ground, transparent background" |
| Damaged / ruins | "the same stall damaged: torn awning, a snapped post, spilled produce" / "the same stall collapsed: the awning fallen over a heap of broken planks and spilled baskets, same footprint" |
| Collapse | no |
| Cap | 25 |

- [ ] `stall_blue` (seed 4) and `stall_cream` (seed 5): copy the folder layout; make each still by **editing** `stall_red`'s stills — `$PY tools/dev/pixellab_api.py edit --image assets/pixellab/buildings/stall_red/<still>.png --out $S/<name>_<still> --desc "the same stall, same position, with a blue and white striped awning"` (cream: "with a cream and tan striped awning"). Same manifest entry shape (seeds 4 and 5), same anchor as `stall_red`. Cap 12 each.
- [ ] R8–R10 for all three (one commit).

---

### Task 16: Group 4 checkpoint and wrap-up (controller + user)

- [ ] As Task 7 for the stalls; **stop for the user's review**; push.
- [ ] Docs: in `docs/PixelLab_Structures_Proof.md` "Batch 2" (what was replaced, bench numbers, findings, sets left procedural); in `docs/HANDOFF_pixellab.md` update "Where things stand", "Open work" (batch 3 list: windmill, watermill, fountains, wells, torches, lamps, bridge, dock, decor) and the budget left; the strip recipe (Task 5) under "Recipes that worked".
- [ ] Commit the docs, push, update the KAK Dev Ledger and the `kak-pixellab-art` memory note (budget left, batch 2 done).
