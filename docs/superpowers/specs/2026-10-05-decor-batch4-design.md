# Decor batch 4: sprite decor from the reference sheets — design

**Date:** 2026-10-05

**Branch:** `feat/decor-batch4`, in a new worktree `C:\BURIN_NITRO\Godot\GIT\vfxProve-decor`.
- It is cut from `feat/ref-batch3` after the audit quick fixes (Task 15) land.
- It merges after `feat/ref-re-texture` and `feat/ref-batch3`.

**Follows:** batch 3 (`docs/superpowers/specs/2026-10-04-ref-convert-batch3-design.md`). It reuses that batch's conversion tools in `tools/dev/ref_convert/` and its sprite sets.

## Goal

Replace the town's procedurally drawn decor with sprites in the reference sheets' style (`concepts/TOWN REF/TownMap_Component1–4.png`), at no generation cost. That decor is every `Decor.Kind`, plus the floor's baked leafy bushes and the forest layer.

- **Pass:** in town and in a mission, F7 shows all decor in the new style, consistent with the batch 1–3 sprites.
  - Baked and live pieces must match: the same barrel looks the same everywhere.
  - The forest no longer mixes old and new trees.
- **Gameplay:** unchanged.

## Decisions (user, 2026-10-05)

- **Scope:** all four groups.
  - Town goods: barrels, crates, log piles, piles, benches, market tables, carts, house-front lamps, signposts, bunting.
  - Water: the ship and the rowing boats.
  - Farm and animals: fences, scarecrows, garden beds, sheep, cows.
  - Nature and forest: bushes, rocks, flowers, reeds, and the forest oaks and pines.
- **Approach:** one switch inside `DecorArt.paint()` / `DecorArt.tree()`. Live decor, piles, the floor bake and the forest layer all switch together.
- **Cost:** free. No PixelLab, ChatGPT or Codex calls.
- **Review:** the user reviews after each group.

## Engine

### `DecorSprites` (new, `src/environment/art/decor_sprites.gd`)

- **Manifest:**
  - The manifest is `assets/pixellab/decor/manifest.json`, in the building manifest's format (one entry per line, tab indent, LF).
  - Each set is a folder holding `intact.png`. Down trees use their batch 3 set's `ruins` still (stump and log).
  - Entry keys: `size`, `anchor` (the ground point in sprite px), `sway` (0 or 1), and for a repeating segment `segment` (the run length in ground units that one tile covers).
- **`name_for(kind, seed, size) -> String`:** maps a decor piece to a set.
  - Variants named `<kind>_<n>` are picked by `ArtKit.hash01(seed, SALT)` among the sets present, as `SpriteArt._pick_variant` does.
  - OAK and PINE map to the batch 3 building sets `oak_<n>` / `tree_<n>`. They are read through `SpriteArt.sprite()`, not duplicated.
  - Returns "" when no set exists, and the piece stays procedural.
- **Gate:** sprites are used only while the F7 art toggle is on (the same flag `SpriteArt` uses).

### `ArtKit.tex()` (new)

- **Signature:** `ArtKit.tex(texture, src_rect, dst_pos, color)` queues a textured quad in the current collection, next to `poly()` / `poly_wind()`.
- **Flush:** `ArtKit.flush(ci)` draws the queued quads grouped by texture, after the polygons of the same depth slot, keeping painter order.
  - A PILE stays one node, with one draw call per texture it uses.
- **Wind:** a textured quad keeps its texture UVs. `wind.gdshader` detects a bound texture and sways the vertex by its height in the sprite (`sprite_sway * (1 - UV.y)`), so there is no CPU cost.
- **Colour:** `color_mul` (ArtTuning tint, PILE part tint) and the live node's `self_modulate` (char tint) apply as they do to polygons, so charring still works.

### `DecorArt.paint()` / `DecorArt.tree()`

- At the top of each kind's branch:
  - if `DecorSprites.name_for(...)` returns a set, queue `ArtKit.tex` at `Iso.ground_to_screen(at) - origin - anchor`, then return;
  - otherwise draw the polygons as today.
- **Runs** (FENCE, BUNTING, GARDEN, and any run-sized kind):
  - repeat the set's segment along `at → at + size`, cropping the last tile;
  - choose the segment orientation from the run's iso direction (x-run or y-run sets, `<kind>_x` / `<kind>_y`).
- **Down:**
  - trees draw their set's `ruins` still (stump and log);
  - every other kind draws nothing, as now.

### F7 toggle

- Live `Decor` nodes `queue_redraw()`.
- `TownFloor` re-bakes its detail layer, which includes the baked low decor and the leafy bushes painted through `PropArt.leafy`. Those switch to bush sprites when they exist.
- `ForestLayer` redraws its bands.
- The cost is one hitch per toggle; acceptable for a dev toggle.

### Not changed

- `TownDecor` placement data and `Decor` hit logic (`KNOCK_AT`, `CHAR_PER`).
- The `bake` rules, pile merging, `SWAYS`, and the lamp glow.
- `Structure`, the rng streams, crowd, gameplay.
- `state_digest` stays `61267b7e90524d800bf1c3473a71146b`.

## Sets

**Sources:** each set is cut with `convert.py`, or drawn clean on the game's 2:1 geometry in the sheets' colours, as for the batch 3 dock, mills and fields. The bar is the user-approved drawn dock: clean shapes and a fixed tone pattern, no sampled noise.

**Style:**
- Light from the left.
- Native scale: about the procedural piece's size, up to 1.3× for readability.

**Variants:** 2–3 per kind where the sheets offer them.

| Group | Sets |
|---|---|
| 1. Town goods + water | `barrel_<n>`, `crates_<n>` (single, and the stacked pair the procedural one draws by seed), `bench_x/_y`, `table_<n>`, `logs_<n>`, `cart_<n>`, `lamp_house` (matches the batch 3 `lamp_post` style; glow kept), `signpost`, `bunting_x/_y` (segment), `ship`, `boat_<n>` |
| 2. Farm + animals | `fence_x/_y` (segment), `scarecrow`, `garden_x/_y` (segment), `sheep_<n>`, `cow_<n>` (mirrored by seed for facing) |
| 3. Nature + forest | `bush_<n>`, `rock_<n>`, `flowers_<n>`, `reeds_<n>`; forest and town OAK/PINE use the batch 3 `oak_<n>` / `tree_<n>` (down: ruins still) |

**Leftover decor DOCK:** check whether `Decor.Kind.DOCK` is still placed now that the dock is a Structure.
- If unused, leave its procedural branch and add no set.
- If used, map it to the batch 3 `dock` set.

**Forest trees:** the batch 3 tree sets sway as building idle strips. In the forest they sway through the wind shader instead, using frame 0 of the intact still. One sway system per layer; no idle strips in the bake.

## Order and review

| Group | Sets | Then |
|---|---|---|
| 0 | `DecorSprites`, `ArtKit.tex`, the paint switch, F7 rebake, tests, with one barrel set as the proof | controller check |
| 1 | town goods + water | user review |
| 2 | farm + animals | user review |
| 3 | nature + forest | user review, then wrap-up docs |

**After each group:**
- tests: failures=0, 0 SCRIPT ERROR;
- the digest;
- glow under 5%;
- a bench, sprites against procedural, medians over market, meadow and forest views, with the other Godot processes noted;
- town captures sent to the user, then a stop for the user's review;
- commit and push of `feat/decor-batch4`;
- a KAK Dev Ledger update.

## Testing

- **Mapping:**
  - every `Decor.Kind` maps to a set or falls back to "", with fake manifest entries injected and restored;
  - variants spread across seeds;
  - OAK/PINE resolve to the batch 3 sets.
- **Paint path:** with a set present, `DecorArt.paint` queues a texture quad and no polygons; with none, it queues polygons only.
- **Runs:**
  - a fence run of length L draws `ceil(L / segment)` quads;
  - the last quad is cropped;
  - the orientation follows the run direction.
- **Piles:** a PILE of three barrels flushes one texture batch.
- **Wind:** the textured shader branch is checked by code review and in forest captures (shaders do not run headless).
- **F7:** toggling switches live decor and re-bakes the floor and forest; toggling back restores the procedural output.
- **Down:** a down tree draws its stump; a down barrel draws nothing.
- **Bench:** forest, meadow and market views. The sprites must stay within ~3 fps of procedural, or the gap gets reported with evidence.

## Risks

- **Bake size:** the floor bake with thousands of textured quads. Mitigation: quads batch per texture, and the bake happens once.
- **Forest sway:** the trees' look in the wind shader (a quad shear) against the batch 3 idle sway. Check it in the captures.
- **Mixed decor in a run:** the pile batching order when kinds are mixed. Painter order is kept per depth slot.
