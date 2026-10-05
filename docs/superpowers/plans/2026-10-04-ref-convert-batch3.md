# Reference-converted town art, batch 3 — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task by task.

**Goal:** turn the remaining procedural town components (stalls, fountains, wells, torches, lamps, trees, bridge, dock, barns, carpenter, mills, fields) into sprites converted from the reference sheets, at no generation cost.

**Architecture:**
- A generic converter, `tools/dev/ref_convert/convert.py`, does cut → fit → match → place, and writes each set's stills and manifest entry.
- Local scripts draw the damaged states and the idle strips.
- `SpriteArt.name_for` maps each structure kind/role/tag to a set, falling back to procedural art when a set is missing.

**Tech stack:** Godot 4.7.2 GDScript; Python 3.12 + Pillow + numpy.

**Spec:** `docs/superpowers/specs/2026-10-04-ref-convert-batch3-design.md`

## Global constraints

- **Where:** work only in `C:\BURIN_NITRO\Godot\GIT\vfxProve-ref3`, on branch `feat/ref-batch3`. Never touch the other worktrees (`vfxProve`, `vfxProve-pixellab`, `vfxProve-integrate`, `vfxProve-gpt`).
- **No AI generation calls:** no PixelLab, OpenAI or Codex.
- **Native scale:** after placing, never rescale a sprite. Pad canvases instead. The fit-time downscale in convert.py is allowed.
- **Gameplay unchanged:** `"$G" --headless --path . -s tools/dev/state_digest.gd 2>&1 | grep digest=` must stay `digest=61267b7e90524d800bf1c3473a71146b`.
- **Tests:**
  - Run `GODOT=$G bash tools/test.sh > <scratch>/t.txt 2>&1`.
  - `grep -o "checks=[0-9]* failures=[0-9]*" <scratch>/t.txt | tail -1` must show `failures=0`.
  - `grep -c "SCRIPT ERROR"` on the same file must print `0`.
  - Run `"$G" --headless --path . --import > /dev/null 2>&1` first whenever PNGs changed.
- **Glow:** `$PY tools/dev/check_sprite_glow.py` must show every sprite under 5%. Lit windows and flames are fine.
- **Commits:** stage by name, never `git commit -a`. Messages end with a blank line, then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Shell:**
  - `G=C:/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`
  - `PY=/c/Users/dorae/AppData/Local/Programs/Python/Python312/python.exe`
- **Reference sheets:** `concepts/TOWN REF/TownMap_Component1.png` through `TownMap_Component4.png` (1448×1086, transparent backgrounds).
- **Blend rules (user feedback):**
  - Light comes from the left (mirror when the sheet lights from the right).
  - Tone stone toward the town stone, using the harmonize target `concepts/TOWN REF/TownMap_Component4.png` box `40,40,300,245`.
  - No stone arch frames around openings.
  - Ruins must be clean: not rough, scattered rubble.
- **Captures:**
  - `GODOT=$G SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --capture-town [--only=<shot>]`
  - Shots are listed in `src/game/town_debug.gd` (`TOWN_SHOTS`). Add shots there if a set isn't framed; it's dev-only.

## Review focus

1. **Stall variety:** neighbouring stalls must not repeat a design. The seed hash must spread the ~10 designs across the 29 stalls, and a test checks that more than 6 distinct designs appear.
2. **Flat sprites** (bridge, dock, fields) must draw under the people walking on them. People crossing the bridge must stay visible.
3. **Fallbacks:** a mapped name with no manifest entry yet must leave the structure procedural, with no warnings spam.
4. **Torches and lamps** keep their procedural flame and glow on top, with no double flame.
5. **Mills:** the turning parts loop seamlessly (the last frame leads into the first), and the old spin overlay never draws over the sprite.

---

### Task 1: Generic converter tool

**Files:** create `tools/dev/ref_convert/convert.py`.

`python tools/dev/ref_convert/convert.py <set> --sheet <png> --box x0,y0,x1,y1 --footprint W,D [--mirror] [--colors 40] [--harmonize] [--keep-green] [--canvas-pad 6] [--width-rows 0.62,0.78] [--measure body|bbox]`
1. Crop the box and keep the largest solid shape. Small separate pieces of at least 20 px below its middle are kept (like `sprite_fix.py largest`).
2. Measure the body width:
   - `--measure body` (default): the median opaque, non-green width over the given fraction of rows.
   - `--measure bbox`: the full width.
   - The target width is `32 * (W + D)`; scale is target / measured.
3. Fit and finish:
   - downscale with premultiplied-alpha Lanczos;
   - unsharp mask (radius 1, 60%);
   - hard alpha at 110;
   - median-cut palette of `--colors` colours, with no dither;
   - 1 px dark outline, blending each edge pixel 55% toward (34,26,24) unless it is already dark.
4. Apply `--mirror`, then `--harmonize` (run `sprite_fix.py harmonize` with the Component4 target).
5. Place and save:
   - Pad by `--canvas-pad`.
   - The anchor is the lowest body pixel row, at that row's middle x.
   - Write `assets/pixellab/buildings/<set>/intact.png`.
   - Print `size`, `anchor` and the base-corner errors against the diamond. The left corner is anchor − (32·D, 16·D) and the right corner is anchor + (32·W, −16·W); measure each corner's nearest opaque base pixel.
6. Add or update the manifest entry for `<set>`, keeping any keys already there. Required keys: size, footprint, anchor; `kind`/`role`/`tag`/`height`/`seed` come from `--kind/--role/--tag/--height/--seed` arguments.
7. `convert.py selftest`: convert the bell tower (sheet Component4, box `470,460,640,710`, footprint 1.1,1.1, `--mirror`) into a scratch folder. Its silhouette bbox must be within 2 px of the bbox of the committed `bell_tower` intact, before re-texturing; compare against the mirrored, harmonized conversion stage in `tools/dev/ref_convert/convert_bell.py` + `retexture_bell.py`. Print pass or fail. A non-zero exit on fail.

Verify with the selftest. Commit.

### Task 2: Engine mappings for all batch 3 sets (fallback to procedural)

**Files:** `src/environment/art/sprite_art.gd` (`name_for`), `tests/test_sprite_art.gd`.

TDD. Add the mappings exactly as the spec lists them:
- stall design + cloth tint;
- fountain and well;
- torch_post and lamp_post;
- tree and oak variants;
- bridge_stone and dock;
- barn, windmill, watermill, carpenter;
- field crops.

Rules:
- **Variants:** a variant name counts only if it is in the manifest. Pick the design index from the seed hash among the existing ones, e.g. via a helper `_variants(prefix)` cached per manifest load.
- **No variants:** return "", so the structure stays procedural.
- **Torches and lamps:** `keep_flames` comes from their manifest entries in later tasks; nothing in code yet.
- **Tests:**
  - every mapping and fallback, using fake manifest entries injected and restored inside the test, or real entries as later tasks add them;
  - the stall-variety check from Review focus 1;
  - a flat-kind draw-order check: a BRIDGE or FARM_FIELD sprite structure has `z_index` -1, like its procedural version.
- **Gameplay:** the digest must stay unchanged.

Commit.

### Task 3: Market stalls (all Component2 designs)

1. **Find the stall designs:**
   - Open `concepts/TOWN REF/TownMap_Component2.png`. Stalls sit in rows 1–2, roughly y 0–300.
   - Find each stall's box. Use alpha connected components on that region of the sheet; the sheet has transparency.
   - Read crops at 2× to confirm each one is a single stall.
   - Expect about 10 designs: striped red, blue and yellow awnings, cream canopies, banner tents, a red-and-white circus tent, and so on.
2. **Convert each design** with convert.py at footprint `0.9,0.7`:
   - Use the stall structures' kind, role, tag and height: MARKET_STALL / market / "" / 10.
   - Set names `stall_1`..`stall_N`.
   - Mirror only if the design's light comes from the right.
3. **Awning tints:**
   - **Striped designs:** make `_red`, `_blue` and `_cream` variants with `sprite_fix.py huemap` on the stripe colour, so each stall keeps its old cloth colour (`prop_art.gd` CLOTH: `c8342a/ece2c8`, `2f5fb8/ece2c8`, `ece2c8/c0a070`).
   - **Designs with fixed colours:** a single set.
4. **Damaged state** (local): torn awning (bite holes along the edge), a snapped corner post, spilled goods at the foot.
5. **Ruins:** the awning collapsed flat over a low heap of planks and crates, inside the footprint. Clean shapes, no speckle.
6. **Idle:** a 4-frame awning ripple at 4 fps. The awning's front scalloped edge rows shift ±1 px vertically along a travelling wave; nothing else moves. Write it into each set's `idle.png`, and set `frames` 4 and `fps` 4 in the manifest.
7. **Wire up and check:**
   - Add all names to `NAMES`.
   - Run the tests, digest and glow checks.
   - Capture `town_market` and Read it. The 29 stalls must show mixed designs, sit on their plots, and look less crowded than the rejected PixelLab stalls.
8. Commit.

### Task 4: Fountains and wells

1. **Fountains:**
   - Convert the best matching fountain on `Component2` (row 3, x≈20–470). Footprint `1.2,1.2`; FOUNTAIN / decor / "" / height 24.
   - Damaged: a cracked basin rim and a dry spout.
   - Ruins: a broken low basin ring with rubble inside, clean.
   - Idle: a 4-frame water shimmer at 6 fps. Light ripple pixels on the water surface move, and the jet tip alternates.
   - Keep the procedural `_spin` hidden for the sprite.
2. **Wells:** convert the roofed stone well on `Component2` (row 3, ~x 480–580). Footprint `0.5,0.5`; FOUNTAIN / decor / well / height 12. Damaged and ruins as for the fountains, scaled to the well.
3. **Wire up and check:** NAMES, tests, digest, glow.
4. **Captures:** capture a shot showing a fountain (`town_market` or the fountain plaza) and a well. Add shots to `TOWN_SHOTS` if needed.
5. Commit.

### Task 5: Group 1 checkpoint (controller)

- Run the bench: 3 alternating pairs, report medians, and note any other Godot processes running.
- Send captures to the user and stop for review.
- Push `feat/ref-batch3` and update the Dev Ledger.

### Tasks 6–14 (groups 2–4)

These follow the same recipe. Each task's brief is written at dispatch time, from the spec's per-set lines and the lessons of the previous group.
- **Task 6:** `torch_post` and `lamp_post`, with `keep_flames` and a check against double flames.
- **Task 7:** trees: forest and meadow variants plus town oaks, each with a crown-sway idle.
- **Task 8:** checkpoint for group 2.
- **Task 9:** `bridge_stone` and `dock`, flat, with the draw-order check.
- **Task 10:** checkpoint for group 3.
- **Task 11:** barn and carpenter, from the Component1 warehouse.
- **Task 12:** windmill and watermill: split the combined mill, then build the turning-parts idle strips.
- **Task 13:** fields: wheat and crops, with a sway idle.
- **Task 14:** checkpoint for group 4 and wrap-up docs: the HANDOFF and Proof docs, plus the `tools/dev/ref_convert/README`.
