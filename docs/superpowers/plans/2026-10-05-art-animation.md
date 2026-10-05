# Art animation round: implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** bring the static town art to life. That means:
- tower and keep bonfires flicker, and every banner sways;
- lit windows flicker;
- boats bob, and low plants sway;
- sheep, cows, the scarecrow, house lanterns and the ship's pennant animate.

All of it runs on the shared idle clock, with no per-piece CPU work.

**Architecture:**
- **Building animation** uses the batch 3 idle-strip machinery: shader-stepped frames, `SpriteView.idle_time`, a per-view phase.
- **Window flicker** is a mask texture per set, read by `structure_sprite.gdshader`.
- **Decor animation** goes through `wind.gdshader`'s textured branch, using a few shared materials keyed by mode, frames and fps. The phase comes from the node's world position, as the wind sway's does.
- **Swaying low plants** move from the static floor bake into wind bands, like `ForestLayer`.

**Tech stack:** Godot 4.7.2 GDScript and shaders (GL Compatibility); Python 3.12 + Pillow + numpy for frame tools.

**Spec:** `docs/superpowers/specs/2026-10-05-art-animation-design.md`

## Global constraints

- **Where:** work only in `C:\BURIN_NITRO\Godot\GIT\vfxProve-anim`, on branch `feat/art-animation`, cut from `feat/Develop-Main` 30b435c. Never edit the other worktrees. `vfxProve` is the KAK v0.09 session's.
- **No AI generation calls.**
- **Gameplay unchanged:** `"$G" --headless --path . -s tools/dev/state_digest.gd 2>&1 | grep digest=` must stay `digest=61267b7e90524d800bf1c3473a71146b`.
- **Tests:**
  - Run `"$G" --headless --path . --import > /dev/null 2>&1` after PNG changes.
  - Then run `GODOT=$G bash tools/test.sh > <scratch>/t.txt 2>&1`.
  - `checks=… failures=0`, and `grep -c "SCRIPT ERROR"` must print 0.
- **Glow:** `$PY tools/dev/check_sprite_glow.py` must keep every sprite under 5%. Flames and lit glass are allowed.
- **Bench:** run `"$G" --path . --audio-driver Dummy --disable-vsync --scene res://scenes/mission.tscn -- --bench` and grep `bench[mission]`.
  - Do 3 alternating pairs against `feat/Develop-Main` 30b435c (a temporary worktree, or `vfxProve-integrate` on `feat/art-merge`, which is 30b435c).
  - Report medians, and drop throttled runs under 50 fps by rerunning them.
  - Must be within ~3 fps.
- **Shared clock:** every animation runs on `SpriteView.idle_time` (a shader global `idle_time`, advanced by `EnvironmentField`). That clock holds while the mission is frozen. Each piece has its own phase.
- **Art rules:**
  - light from the left;
  - clean shapes in a fixed tone pattern; no sampled noise;
  - native scale.
- **F7 off:** everything procedural, exactly as now.
- **Commits:**
  - Stage by name.
  - Include new `.uid` / `.import` files.
  - Message ends with a blank line, then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Shell:**
  - `G=C:/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`
  - `PY=/c/Users/dorae/AppData/Local/Programs/Python/Python312/python.exe`
  - Scratch: `C:\Users\dorae\AppData\Local\Temp\claude\C--BURIN-NITRO-Godot-GIT-vfxProve-pixellab\64321455-71f5-4ef9-84ed-ba260def80dc\scratchpad\anim\`
- **Captures:** `GODOT=$G SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --capture-town --only=<shot> [--frames …]`. Check `town_debug.gd` for the multi-frame option batch 3 used, and Read every capture.

## Review focus

1. **Idle strips change size:** strips that grow (more frames, or a new strip) must keep their damaged, ruins and collapse stills, and the `_sprite_settled`/sleep behaviour. A structure with a new strip must still go idle. Test in Task 1.
2. **Window mask only on the right states:** the mask applies only to the intact still and its idle strip. Damaged and ruins stills keep their own look, and a laser-cut stump never flickers. Test in Task 4.
3. **Wind bands sort correctly:** only pieces the bake rules call bakeable (nothing ever stands in front of them) leave the floor for wind bands. Anything else keeps sorting with people. Test in Task 8.
4. **F7 round trip:** toggling twice restores the procedural floor bake (low plants back in the bake), the decor and the buildings. Test in Task 8.
5. **Frozen mission:** frame-stepped animation (building strips, window flicker, decor frames) uses `idle_time`, so it holds while the mission is frozen.
   - Wind motion (sway and bob) uses the wind shader's `TIME`, as the trees and bunting already do. That keeps every wind motion consistent with today's trees, which keep swaying while frozen.
   - Test in Task 10: decor frames use `idle_time`.

---

### Task 0: Setup (controller)

- [ ] The worktree `vfxProve-anim` already exists at 8fa9e25 (the spec commit). Commit this plan.
- [ ] Run `--import`, then a baseline test run.
- [ ] Create the SDD ledger.
- [ ] Add desktop shortcuts "KAK anim - Town/Mission" pointing at `vfxProve-anim`.

---

### Task 1: Bonfire flicker on every fire basket (Group A)

**Files:**
- Create: `tools/dev/ref_convert/bonfire_flicker.py`
- Modify: `assets/pixellab/buildings/<set>/idle.png` and manifest lines for every basket-bearing set
- Test: `tests/test_sprite_art.gd`

**Interfaces:**
- Consumes:
  - the existing idle strips (`idle.png`, manifest `frames` / `fps`) and `SpriteView.play_idle()`;
  - `tools/dev/ref_convert/banner_sway.py` (its frame-writing helpers).
- Produces:
  - every basket-bearing set has `frames ≥ 6`, a valid `idle.png`, and a seamless flame loop;
  - `bonfire_flicker.py <set>... [--check]`, where `--check` verifies the loop and that frame 0 equals intact outside the flame and banner regions.

- [ ] **Step 1: Find the basket sets.** Scan the manifest sets' `intact.png` for warm, bright flame clusters above a dark basket. Candidates:
  - `town_tower*` (all variants, including the corner towers' new basket);
  - `town_gate`, `town_postern` if it has one;
  - `citadel_keep`, `citadel_tower`, `citadel_gate`, `bell_tower` (check each).
  - Read crops at 3×. List them in the report.
- [ ] **Step 2: Write the failing test.** Add to `tests/test_sprite_art.gd`:

```gdscript
## Every set with a fire basket animates its flame (art animation round, Group A).
const BASKET_SETS := ["town_tower", "town_tower_corner", "town_tower_e", "town_tower_s", "town_tower_e_hi",
	"town_tower_s_hi", "town_tower_corner_e", "town_tower_corner_s", "town_tower_corner_e_s", "town_gate",
	"citadel_keep", "citadel_tower"]


static func _bonfires(t) -> void:
	for n: String in BASKET_SETS:
		var s := SpriteArt.sprite(n)
		t.check(not s.is_empty() and int(s.frames) >= 6 and s.idle != null,
			"%s has a flame idle strip (frames %s)" % [n, s.get("frames", 0)])
```

  Adjust `BASKET_SETS` to Step 1's actual list, and call `_bonfires(t)` from `run`. Run it: the sets without a strip fail.
- [ ] **Step 3: Write `bonfire_flicker.py`.**
  - **Flame mask:** pixels with high luminance and a warm hue (R > G > B, R ≥ 200), connected to a dark basket below. Grow the mask by 1 px.
  - **Frames:** for each of 6 frames, redraw the flame inside the mask's bounding box, extended 3 px up:
    - Use 3–5 tongues, each a column with a height `h_i(f) = base_i + amp_i * sin(2π(f/6) + φ_i)`.
    - Colour the tongues pale core → amber → deep orange from the bottom up, with the tones taken from the original flame.
    - Add 2–3 ember pixels that blink.
    - Keep the outline dark.
  - Frame 0 should stay close to the original painted flame.
  - **Sets with an existing strip (banner sway):**
    - Read every frame and composite the flame frame onto it.
    - If the strip has `n` frames and `n ≠ 6`: when `lcm(n, 6) ≤ 12`, build `lcm` frames by cycling both. Otherwise, re-time the banners to 6 frames (sample the banner frames by `round(i*n/6)`).
    - Set `fps` so the banner's cycle time stays within ±15% of before. Report the old and new `frames`/`fps` per set.
  - **Sets without a strip:** write a new 6-frame `idle.png` from `intact.png`. Set `frames` 6 and `fps` 8.
  - **`--check`:**
    - The frame after the last equals frame 0 (the loop is seamless by construction; assert that frame 0 ≈ the original intact in the flame box).
    - Pixels outside the flame and banner masks are identical across frames.
- [ ] **Step 4: Run it on every set from Step 1.** Run `--import`, the tests and the digest. Check glow, since flames grow the warm area; it must stay under 5%.
- [ ] **Step 5: Captures.**
  - `town_corner_south`, `town_main_gate` and `town_citadel`: 3 frames each, 0.25 s apart.
  - Read them: the flames move, the banners still sway, and nothing pops.
- [ ] **Step 6: Commit.**

---

### Task 2: Sway the static banners (Group A)

**Files:**
- Modify: `assets/pixellab/buildings/{barracks,citadel_wall,citadel_wall_side}/` (`idle.png`, manifest `frames` / `fps`), plus any other set Step 1 finds with an unswayed banner.
- Test: `tests/test_sprite_art.gd`

**Interfaces:**
- Consumes: `tools/dev/ref_convert/banner_sway.py` (`--frames --fps --amp --min-px --max-top`).
- Produces: those sets play an idle strip.

- [ ] **Step 1: Find the sets.** List the sets with painted banners but no idle strip: Read the `intact.png` crops of barracks, citadel_wall, citadel_wall_side, cathedral and town_postern.
- [ ] **Step 2: Write the failing test.** Extend `_bonfires`'s sibling with a `_banners` check: each listed set has `frames ≥ 4`.
- [ ] **Step 3: Generate the strips.** Run `banner_sway.py` per set, with 6 frames at 6 fps to match the towers. `citadel_wall` is a strip set: check that the `strip`/`period` sets play idle strips at all (`SpriteView`/`SpriteArt.strip_piece`).
  - If they can't, report it and skip that set, with a ledger note. Don't build new strip-plus-idle engine support in this task.
- [ ] **Step 4:** run the tests, the digest and glow. Capture `town_side_gate` (barracks) and `town_citadel` with 3 frames, and Read them.
- [ ] **Step 5: Commit.**

### Task 3: Group A checkpoint (controller)

Bench, captures to the user, push, Dev Ledger p11 update, then **stop for the user's review**.

---

### Task 4: Window glow mask in the sprite shader (Group B engine)

**Files:**
- Modify:
  - `src/environment/art/sprite_art.gd` (`sprite()` loads an optional `glow_mask.png` into key `"glow_mask"`)
  - `src/environment/art/sprite_view.gd` (passes the mask and a `window_flicker` flag)
  - `src/environment/art/structure_sprite.gdshader`
- Test: `tests/test_sprite_art.gd`

**Interfaces:**
- Consumes: `SpriteArt.sprite(n)`; `SpriteView.show_still` / `play_idle`; `idle_time`.
- Produces:
  - Set key `"glow_mask"`: a Texture2D or null. It is the size of one frame (`size`); it is not a strip.
  - Shader uniforms `glow_mask` (sampler2D) and `window_flicker` (bool), plus a module-level `const WINDOW_AMP := 0.12` in `sprite_view.gd`, passed as uniform `window_amp`.
  - `SpriteView` sets `window_flicker = true` only while `still == &"intact"` (the still or its idle strip) and the set has a mask.

- [ ] **Step 1: Write the failing test.**

```gdscript
static func _window_mask(t) -> void:
	# A fake set with a mask: the view enables window flicker for the intact still only.
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	var tex := ImageTexture.create_from_image(img)
	var set := SpriteArt.sprite("cottage_red").duplicate()
	set["glow_mask"] = tex
	var v := SpriteView.new()
	v.sprite = set
	v._ready()
	v.show_still(&"intact")
	t.check(v._mat.get_shader_parameter("window_flicker") == true, "intact cottage with a mask flickers")
	v.show_still(&"damaged")
	t.check(v._mat.get_shader_parameter("window_flicker") == false, "damaged still does not flicker")
	set["glow_mask"] = null
	v.show_still(&"intact")
	t.check(v._mat.get_shader_parameter("window_flicker") == false, "no mask, no flicker")
	v.free()
```

  Adapt it to how `SpriteView` builds `_mat`: read `sprite_view.gd` `_ready()`/setup first, and keep the test's meaning. Call it from `run`.
- [ ] **Step 2: Run it to verify it fails.**
- [ ] **Step 3: Implement.**
  - `sprite_art.gd` `sprite()`: after loading the stills, add `"glow_mask": load(DIR + n + "/glow_mask.png") if ResourceLoader.exists(DIR + n + "/glow_mask.png") else null`.
  - `sprite_view.gd`: in `_show()` and `play_idle()`, set:
    - `_mat.set_shader_parameter("window_flicker", still == &"intact" and sprite.get("glow_mask") != null)`;
    - `glow_mask`, when present;
    - `window_amp`, once.
  - `structure_sprite.gdshader`:

```glsl
uniform sampler2D glow_mask : filter_nearest;
uniform bool window_flicker = false;
uniform float window_amp = 0.12;
// in fragment(), after the colour is computed and before lighting/scorch is applied:
//   vec2 local = (UV - frame offset) in frame pixels;  m = texture(glow_mask, local / frame_size).r;
//   if (window_flicker && m > 0.5) {
//     vec2 cell = floor(local / 3.0);
//     float ph = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453) * 6.2831;
//     float f = 0.6 * sin(idle_time * 7.0 + ph) + 0.4 * sin(idle_time * 13.0 + ph * 1.7);
//     f -= step(0.97, fract(sin(floor(idle_time * 3.0) + ph) * 9871.0)) * 0.8;   // a rare dip
//     col.rgb *= 1.0 + window_amp * f;
//   }
```

  - Use the shader's existing frame maths (`frame_origin`, `frame_w`, `idle_frames`) to get the pixel inside the current frame, so the mask lines up with every strip frame.
  - Clamp the result, so a pixel never goes above its brightest original value × (1 + window_amp).
- [ ] **Step 4:** run the tests and the digest. No captures yet (no masks exist).
- [ ] **Step 5: Commit.**

---

### Task 5: Window masks for every lit-window set (Group B art)

**Files:**
- Create: `tools/dev/ref_convert/window_glow.py`
- Create: `assets/pixellab/buildings/<set>/glow_mask.png` for each lit-window set
- Test: `tests/test_sprite_art.gd`

**Interfaces:**
- Consumes: Task 4's `"glow_mask"` key and shader.
- Produces: `glow_mask.png` = white where a lit window is, transparent elsewhere, at the intact still's size.

- [ ] **Step 1: Write the tool.** `window_glow.py <set>...`:
  - **Keep** warm, bright pixels (R ≥ 180, R > G > B, luminance ≥ 150) whose 5×5 neighbourhood holds dark frame pixels (window bars and frames).
  - **Exclude** flame clusters, using the same mask rules as `bonfire_flicker.py` (import its flame finder): baskets, the forge, torches.
  - **Exclude** any cluster larger than 60 px; it's a flame or a lit floor, not a window.
  - Write the mask, then print the pixel count and window-cluster count per set.
- [ ] **Step 2:** run it on these sets, then Read each mask beside its intact at 3×, and drop sets with no lit windows:
  - cottage_red, cottage_blue, townhouse_a, townhouse_b, tavern;
  - barracks, workshop, smithy;
  - cathedral, citadel_keep, citadel_tower;
  - barn, carpenter.
- [ ] **Step 3: Add a test.** The sets listed in the report each load a non-null `glow_mask` the size of `size`.
- [ ] **Step 4:** run `--import`, the tests, the digest and glow (the mask PNGs are white; exclude `glow_mask.png` from the glow scan if it picks them up, and say so).
- [ ] **Step 5: Captures.**
  - Shots: `town_crowd`, `town_east_quarter` and `town_lamps --dim=0.8`, with 3 frames each.
  - Read them. Windows should flicker visibly at dusk and subtly by day, never in step.
  - Also run the bench: 3 pairs.
- [ ] **Step 6: Commit.**

### Task 6: Group B checkpoint (controller)

Bench, captures, push, Dev Ledger update, then **stop for the user's review**.

---

### Task 7: Decor bob and per-material sway amount (Group D engine)

**Files:**
- Modify:
  - `shaders/wind.gdshader` (modes; `sprite_sway` becomes a uniform per material)
  - `src/environment/decor.gd` (`wind_material()` becomes a small cache keyed by mode)
- Test: `tests/test_decor_sprites.gd`

**Interfaces:**
- Consumes: `Decor.SWAYS`, `Decor.ON_WATER`, `Decor.wind_material()`, and the textured branch of `wind.gdshader` (`TEXTURE_PIXEL_SIZE.x < 1.0`).
- Produces:
  - `Decor.material_for(kind: int) -> ShaderMaterial`. It returns a shared material per motion class:
    - `"tree"`: sway 1.5;
    - `"plant"`: sway 1.0;
    - `"bob"`;
    - `null` for still kinds.
    It always uses the same `wind.gdshader`, with uniforms `sprite_sway: float` and `bob: float` (bob amplitude in px, 0 = off).
  - `Decor.SWAYS` gains `REEDS`, `BUSH` and `FLOWERS`. `Decor.BOBS := [Kind.SHIP, Kind.BOAT]`.
  - `ForestLayer` bands keep the `"tree"` material.
- **Bob:** in the textured branch, if `bob > 0`, the whole quad moves: `VERTEX.y += round(bob * sin(TIME * 2.1 + ph))`, with the same `ph` as the sway. There is no shear, and `bob` overrides the sway.
- **Procedural pieces:** they keep today's motion. The untextured branch is unchanged, so with F7 off a procedural reed doesn't sway. That matches today's procedural behaviour.

- [ ] **Step 1: Write the failing tests.**
  - `Decor.material_for` returns the same material object for two reeds, a different one for a tree, the bob material for SHIP/BOAT, and null for a barrel.
  - The bob material has `bob > 0` and the plant material has `sprite_sway < 1.5`.
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Implement.**
  - `Decor._ready()` uses `material_for(kind)` instead of the single `wind_material()`.
  - Keep `wind_material()` as the `"tree"` entry, so `ForestLayer` is unchanged.
  - Write the shader modes as above.
- [ ] **Step 4:** run the tests and the digest.
- [ ] **Step 5: Captures.** Take 3 frames of `town_dock` and `town_river_farms`, and Read them. The ship and boats must rise and fall 1 px. The live reeds and bushes now sway; baked ones don't yet, until Task 8.
- [ ] **Step 6: Commit.**

---

### Task 8: Low plants leave the floor bake for wind bands (Group D)

**Files:**
- Create: `src/game/town/plant_layer.gd` (wind bands for low plants, modelled on `forest_layer.gd`)
- Modify:
  - `src/game/town/town_floor.gd` (`_shrubs()` and `_paint_decor()`: skip low plants while sprites are on and a set exists)
  - `src/game/town/town.gd` (add the PlantLayer next to the ForestLayer)
  - `src/game/ui/art_toggle.gd`, if the layer needs a refresh (the `decor_art` group)
- Test: `tests/test_decor_sprites.gd`

**Interfaces:**
- Consumes:
  - `TownFloor.baked_decor`;
  - the floor shrub spots (`_shrubs()` computes them; factor their computation into `static func shrub_spots() -> Array[Dictionary]` so both the floor and the layer use it);
  - `DecorSprites.paint` / `paint_named`;
  - `Decor.material_for`.
- Produces:
  - `PlantLayer` (Node2D), with `plants: Array[Dictionary]` holding {kind or base name, at, seed}. It is drawn in bands by x + y, with the `"plant"` material, and is in group `&"decor_art"`.
  - `TownFloor.plant_in_layer(d: Dictionary) -> bool`: true when sprites are on and the piece is a REEDS/BUSH/FLOWERS kind (or a floor shrub/flowerbed spot) with a set.
- **Sorting:** both kinds of piece were already bakeable, so nothing ever stands in front of them. That makes drawing them in a layer under the world (like the forest) correct.

- [ ] **Step 1: Write the failing tests.**
  - With sprites on and the real sets, `TownFloor.plant_in_layer` is true for a baked reed and false for a baked rock.
  - With sprites off, it is false for both.
  - `shrub_spots()` returns the same count both times it is called (it is deterministic).
  - The PlantLayer receives every floor shrub spot plus the baked low plants.
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Implement.** Factor out `shrub_spots()`, add `plant_in_layer`, and make the floor skip what the layer draws. Build `PlantLayer` like `ForestLayer`: bands, and one ArtKit batch per band. On F7, `art_changed()` redraws the layer and the floor re-bakes, so the plants move between bake and layer.
- [ ] **Step 4:** run the tests and the digest. Do the F7 round trip by hand, as decor batch 4 Task 4 did: object count stable across 4 toggles, one FloorBake.
- [ ] **Step 5: Captures.** Take 3 frames of `town_corner_east`, `town_river_farms` and `town_overview`.
  - Read them: reeds, bushes and flowers sway gently.
  - Compare with `--art=procedural`: it must match the old static look.
  - Run the bench.
- [ ] **Step 6: Commit.**

### Task 9: Group D checkpoint (controller)

Bench, captures, push, ledger, then **stop for the user's review**.

---

### Task 10: Animated decor frames (Group C engine)

**Files:**
- Modify:
  - `src/environment/art/decor_sprites.gd` (`decor_set` reads `frames` / `fps`; `paint` draws frame 0's rect and tags the quad)
  - `shaders/wind.gdshader` (frame stepping for textured quads)
  - `src/environment/decor.gd` (animated pieces get an animated material)
  - `src/game/town/town_decor.gd` or `town_floor.gd` (animated kinds are never baked and never piled, while sprites are on)
- Test: `tests/test_decor_sprites.gd`

**Interfaces:**
- Consumes: `Decor.material_for`, `DecorSprites.decor_set`, `ArtKit.tex`, and the shader global `idle_time`.
- Produces:
  - Decor set keys `frames: int` (default 1) and `fps: float`. `size` is one frame. The texture is a horizontal strip.
  - `Decor.material_for(kind)` returns, for an animated set, a shared material keyed by `(motion class, frames, fps)`, with uniforms `anim_frames: int`, `anim_fps: float` and `frame_u: float` (one frame's width in UV).
  - In the textured branch, `fragment()` shifts `UV.x += mod(floor(idle_time * anim_fps + ph), anim_frames) * frame_u`. Here `ph` is a phase from the node's world position, as in the vertex branch. Pass it through a varying, or recompute it from `MODEL_MATRIX` in the fragment.
  - `DecorSprites.animated(kind: int, seed: int) -> bool`: true when the piece's set has `frames > 1`.
  - Never bake or pile: when sprites are on and `animated()` is true, the piece is drawn live.
    - Check how `TownDecor` decides `bake` and `_merge_piles`. Decide at render time, without changing the placement data, so the digest holds. For example, `TownFloor._paint_decor` skips it and the town spawns a live `Decor` node for it instead.
    - Pick the least invasive route and explain it.
- **Freeze:** frame stepping uses `idle_time`, which holds while the mission is frozen (`EnvironmentField` owns it).

- [ ] **Step 1: Write the failing tests.**
  - A fake set `{frames: 4, fps: 3, size, anchor}` loads `frames` 4.
  - `animated()` is true for it and false for `barrel_1`.
  - `material_for` gives two sheep with the same set the same material object, with `anim_frames` 4.
  - An animated piece flagged `bake` in the spot data is drawn live, not in the floor (assert on the floor's bake list or the live node list, whichever the chosen route changes).
  - With F7 off, the piece is procedural.
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Implement.** Keep painting frame 0's rect: `src = Rect2(0, 0, size)` inside the strip; the shader shifts it.
- [ ] **Step 4:** run the tests and the digest.
- [ ] **Step 5: Commit.**

---

### Task 11: Grazing animals, scarecrow, lantern and pennant strips (Group C art)

**Files:**
- Modify:
  - `tools/dev/ref_convert/decor_animals.py`, `decor_farm.py`, `decor_street.py` and `decor_water.py` (add frame output)
  - the decor sets `sheep_1/2`, `cow_1/2`, `scarecrow`, `lamp_house` and `ship` (their `intact.png` becomes a strip; manifest `frames` / `fps`)
- Test: `tests/test_decor_sprites.gd`

**Interfaces:**
- Consumes: Task 10's decor `frames` / `fps` and the animated material; `decor_common.write_set` (extend it with `frames` / `fps`).
- Produces the animated sets:

| Set | Frames | fps | Motion |
|---|---|---|---|
| sheep, cows | 4 | 2.5 | grazing: head dips to the grass, holds, rises; tail flick on frame 3 |
| scarecrow | 4 | 4 | cloth and sleeves flutter by ±1 px rows |
| lamp_house | 4 | 6 | flame shapes in the glass |
| ship | 4 | 5 | pennant flutter; it still bobs (Task 7) |

  Mirroring by seed still works: the flip swaps UVs within frame 0's rect, and the shader shifts by whole frames. Verify a mirrored, animated sheep in a test, or by hand in a capture.

- [ ] **Step 1: Write the failing test.** Every listed set loads with `frames == 4`, and its texture width equals `size.x * 4`.
- [ ] **Step 2: Run it to verify it fails.**
- [ ] **Step 3: Draw the frames.** Frame 0 equals today's still. Each loop is seamless (frame 4 = frame 0). Keep the glow under 5% for the lantern.
- [ ] **Step 4:** run `--import`, the tests, the digest and glow.
- [ ] **Step 5: Captures.** Take 3 frames of `town_pasture_east`, `town_windmill`, `town_lamps` and `town_dock`, and Read them. The animals graze out of step, mirrored animals look right, and the pennant flutters.
- [ ] **Step 6: Commit.**

### Task 12: Group C checkpoint, docs and final review (controller)

- [ ] Run the tests, the digest, glow and the full bench.
- [ ] Docs:
  - `tools/dev/ref_convert/README.md`: add an Animation section covering `bonfire_flicker.py`, `window_glow.py`, the decor `frames`/`fps` keys and motion classes.
  - `docs/HANDOFF_pixellab.md`: add a short section on the animation round.
- [ ] Run the final whole-branch review on the most capable model.
- [ ] Send one fix wave, then a scoped re-review.
- [ ] Send captures to the user, push, update the Dev Ledger, then **stop for the user's review**.
- [ ] Merge into `feat/Develop-Main` only after the user approves. Do a trial merge with tests first, and ask before pushing.
