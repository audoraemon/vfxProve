# Art animation round: design

**Date:** 2026-10-05

**Branch:** `feat/art-animation`, worktree `C:\BURIN_NITRO\Godot\GIT\vfxProve-anim`, cut from `feat/Develop-Main` 30b435c (all town art merged).

**Follows:**
- the reference-converted art (batch 3): `docs/superpowers/specs/2026-10-04-ref-convert-batch3-design.md`;
- decor batch 4: `docs/superpowers/specs/2026-10-05-decor-batch4-design.md`.

## Goal

Make the town feel alive where the art is still static.
- **Pass:** in town and in a mission, with sprites on (F7), these all move:
  - tower and keep bonfires flicker;
  - every banner sways;
  - lit windows flicker softly;
  - boats and the ship bob;
  - reeds, bushes and flowers sway with the trees;
  - the scarecrow's cloth flutters;
  - house lanterns flicker;
  - sheep and cows graze.
- **Unchanged:** gameplay (digest `61267b7e90524d800bf1c3473a71146b`) and the frame rate (within ~3 fps of 30b435c).

## Decisions (user, 2026-10-05)

- **Scope:** all four groups:
  - bonfires and banners;
  - water and wind decor (bob, pennant, sway, scarecrow, lantern flicker);
  - animals;
  - window flicker.
- **Cost:** free, no AI generations. Animation frames are drawn locally from the existing sprites.
- **Review:** the user reviews after each group.

## Shared rules

- **One clock:** every animation runs on the shared idle clock.
  - `SpriteView.idle_time`, advanced by `EnvironmentField`, so it holds while the mission is frozen and follows time scale and hit-stop.
  - Each structure or decor piece has its own phase, so nothing moves in step.
- **No per-frame CPU work per piece:** frames step in shaders, as batch 3's idle strips do.
- **Damaged, ruins and collapse stills don't animate,** unless a group says otherwise.
- **Art rules:**
  - light from the left;
  - clean shapes in a fixed tone pattern, with no sampled noise;
  - native scale.
  - **Glow under 5%:** flames and lit glass are allowed, but `check_sprite_glow.py` must pass.
- **F7:** with sprites off, everything is procedural exactly as now.

## Group A: tower and keep bonfires, and static banners

- **Bonfires:** a new tool, `tools/dev/ref_convert/bonfire_flicker.py`.
  - It finds each painted fire-basket flame: a warm, bright region above a basket.
  - It redraws the flame as a 6-frame loop (tongues rising and shifting, embers blinking, light core and colours fixed per frame) and writes the frames into the set's idle strip.
  - **Sets with a banner strip** (`town_tower*`, `town_gate`, `citadel_keep`, `citadel_tower`):
    - Composite the flame frames into the existing frames.
    - If the frame counts differ, use their least common multiple only if it is at most 12. Otherwise re-time the banner sway to the flame's count.
    - Keep `fps` such that the banner sway reads as before.
  - **Sets without a strip** (`town_tower_s`, `town_tower_s_hi`, `town_tower_corner_e_s`, and any other basket-bearing set) get a new 6-frame strip, with `frames`/`fps` added to the manifest.
- **Static banners:** the barracks banner, and the Citadel wall and wall-side banners if present, get a sway strip via `tools/dev/ref_convert/banner_sway.py`, the same as the towers.
- **Loop check:** frame 6 must equal frame 0, with no pop.

## Group B: window candle flicker

- **Mask tool:** `tools/dev/ref_convert/window_glow.py` writes `glow_mask.png` per set, beside `intact.png`.
  - The mask keeps the lit-window pixels: warm, bright pixels inside window frames. Flame pixels (bonfires, the forge, torches) are excluded.
  - Sets: cottages, townhouses, the tavern, barracks, workshop, smithy (house windows only), cathedral (lit glass, if any), the Citadel keep and towers, and the barn and carpenter if they have lit windows.
- **`SpriteArt`:** loads an optional `glow_mask` texture into the set.
- **`SpriteView` / `structure_sprite.gdshader`:**
  - When the set has a mask and the view shows the intact still or its idle strip, the shader multiplies the masked pixels' brightness by `1 + amp * flicker(idle_time, phase + hash(pixel / 3))`, with `amp` around 0.12.
  - `flicker` is a smooth sum of two sines plus a rare dip.
  - Windows flicker independently, because the phase comes from a hash of the pixel's 3×3 cell.
  - A mask used with an idle strip lines up with every frame, since the strip frames share the intact still's layout. Take the mask from frame 0.
- **Night:** keep the flicker subtle in daylight and let it read at dusk. It must never brighten a pixel above the glow limit.

## Group C: animated decor

- **Manifest:** a decor set may have `frames` and `fps`. Its `intact.png` is then a horizontal strip of `frames` equal-width frames. `size` is one frame.
- **Rendering:**
  - **Live nodes:** an animated decor piece always stays live, never baked into the floor. If `TownDecor` marks one `bake`, the renderer still draws it live (check `TownFloor._paint_decor` and `TownDecor` bake flags).
  - **No gameplay effect:** placement data and seeds don't change, and the digest stays the same.
  - **Shader:** a decor sprite shader steps the frame from `idle_time * fps + phase`. The phase comes from the piece's seed. It's a new `decor_sprite.gdshader`, or the textured branch of `wind.gdshader`, with the frame count and fps passed per node through material instance uniforms (`instance uniform`).
  - **Piles:** animated kinds are never merged into a PILE.
- **Users:**
  - **Sheep and cows:** 4-frame grazing (head dips to the grass and back, tail flick), 2–3 fps. The mirroring and variant rules of decor batch 4 still apply.
  - **Scarecrow:** 4-frame cloth flutter, about 4 fps.
  - **House-front lantern:** 3–4 frame flame flicker in the glass, about 6 fps, glow under 5%.
  - **Ship:** 4-frame pennant flutter, combined with the Group D bob.

## Group D: decor motion (bob and sway)

- **Bob:** ship and boats rise and fall by a whole pixel on a slow sine (period about 3 s, with a per-piece phase). The whole quad moves; there is no shear.
  - This is a `bob` mode for textured quads in the decor shader path, set per node (`instance uniform`) for ON_WATER kinds.
- **Sway:**
  - Reeds, bushes and flowers sway with the wind, like the trees (`Decor.SWAYS` gains REEDS, BUSH, FLOWERS).
  - Baked pieces of these kinds, and the floor's small shrubs, flowerbeds and reeds, move from the static floor bake into wind bands drawn like `ForestLayer` (one batch per band, the wind material, no per-frame CPU).
  - Bands are culled whole off screen.
  - A piece that buildings or people can overlap must still sort correctly: only pieces that were bakeable (nothing ever stands in front) go into bands.
- **Sway amount:**
  - Low plants sway less than trees: about 1 px at the top.
  - The textured branch currently uses one `sprite_sway`. Make the sway per node or per band, so trees keep theirs.

## Order and review

| Group | Content |
|---|---|
| A | bonfires and banners |
| B | window flicker |
| D | water bob and wind sway |
| C | animated decor (animals, scarecrow, lantern, pennant) |

**After each group:**
- tests (failures=0, 0 SCRIPT ERROR) and the digest;
- glow;
- bench: 3 alternating pairs against `feat/Develop-Main` 30b435c with `--disable-vsync`, medians;
- captures of 3 frames 0.25 s apart, sent to the user, then a stop for review;
- push `feat/art-animation`;
- update the KAK Dev Ledger card p11.

## Testing

- **Group A:**
  - every basket-bearing set has an idle strip;
  - the strip's frame count matches the manifest;
  - the loop is seamless (tool check).
- **Group B:**
  - the mask loads;
  - the shader gets it only for the intact state and the idle strip;
  - no mask means no change (regression on a set without one).
- **Group C:**
  - an animated decor set is never baked and never piled;
  - its frame count is read;
  - the phase differs between two pieces;
  - F7 off draws it procedurally.
- **Group D:**
  - bobbing kinds get the bob mode;
  - swaying low plants land in wind bands, not the floor bake;
  - the floor bake no longer contains them while sprites are on;
  - toggling F7 restores exactly the procedural output.
- **Freeze:** all of it holds while the mission is frozen (the shared clock stops).
