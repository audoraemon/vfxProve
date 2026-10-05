# Reference-converted town art, batch 3 — design

**Date:** 2026-10-04. **Branch:** `feat/ref-batch3`, worktree `C:\BURIN_NITRO\Godot\GIT\vfxProve-ref3`.
It is based on `feat/ref-re-texture` because it reuses that branch's conversion scripts and the self-animating sprite views, so that branch merges first.
**Follows:** the bell tower proof on `feat/ref-re-texture` (`tools/dev/ref_convert/`).

## Goal

Replace every remaining procedurally drawn destructible town component with sprites converted from the user's reference sheets (`concepts/TOWN REF/TownMap_Component1–4.png`). The method costs no AI generations.
- **Pass:** in town and mission, F7 shows each component in the reference's style, blending with the existing sprites, with correct intact, damaged and ruins states.
- **Gameplay:** unchanged.

## Decisions (user, 2026-10-04)

- **Scope:** groups A + B + C. That is stalls, fountains, wells, torches, lamps, trees, bridge, dock, barns, carpenter, windmill, watermill and farm fields.
- **Small decor is out of scope** (crates, carts, flowers, rocks, reeds, fences, boats, animals); it needs new engine support and comes in a later round.
- **Market stalls:** all ~10 designs on `TownMap_Component2` are used. Each of the 29 stalls picks one design from its seed. Striped awnings are tinted to the stall's existing cloth colour (red, blue, cream).
- **Barns:** adapted from `Component1`'s timber warehouse, without its crane.
- **Mills:** the body comes from the sheet. The sails and the water wheel turn as frames of an idle strip; the old procedural spin overlay is hidden.
- **Cost:** free. No PixelLab, ChatGPT or Codex calls.
- **Review:** the user reviews after each group.

## Method (per set)

1. **Cut:** take the component from its sheet. Keep only the largest shape, which drops neighbouring sheet items; small attached details stay.
2. **Fit:**
   - Measure the body's width on its lower rows. Walls are vertical in iso, so that width equals the footprint diamond's width.
   - Scale by target / measured width, using a premultiplied-alpha Lanczos downscale.
   - Apply a light unsharp mask, then hard alpha at 110, then a median-cut palette of 32–48 colours, then a 1 px dark outline.
3. **Match:**
   - Mirror so the light comes from the left, as on every town sprite.
   - Tone stone toward the town stone with `sprite_fix.py harmonize`; target is the Component4 wall crop.
   - Re-texture only where a surface clashes with its neighbours, as was done for the bell tower's walls.
4. **Place:** set the anchor so the base corners sit within ±3 px of the footprint diamond's corners, and pad the canvas so nothing touches an edge. Never rescale after placing.
5. **States:**
   - **Damaged:** drawn locally on the same outline (cracks, holes, scorch, torn cloth, broken parts).
   - **Ruins:** the approved ruins of the closest existing set, scaled to this plot, as for the bell tower. Otherwise a clean local ruin; the user rejects rough rubble.
   - **Collapse:** the engine sink. No generated collapse.
6. **Life (idle strips through the self-animating view):** awnings ripple, fountain water shimmers, tree crowns sway, mill sails and wheel turn, field crops sway. Torches and lamps keep their procedural flame and light on top (the `keep_flames` flag).

## Engine changes

- **`SpriteArt.name_for` mappings:**
  - **MARKET_STALL** → `stall_<n>`, with design `n` from `ArtKit.hash01(seed, SALT)` over the designs present in the manifest. The stall's cloth colour selects the awning tint variant `stall_<n>_<red|blue|cream>`. These are generated per design that has stripes; designs without stripes ignore the cloth.
  - **FOUNTAIN:** tag "" → `fountain`; tag `well` → `well`.
  - **TORCH:** tag "" → `torch_post`; tag `lamp` → `lamp_post`. Both keep their flames (`keep_flames`).
  - **TREE:** tag "" → `tree_<n>` (forest and meadow variants); tag `oak` → `oak_<n>`. Variant chosen by seed hash.
  - **BRIDGE:** tag `stone` → `bridge_stone`; tag `dock` → `dock`. Both are flat walkable kinds and must keep drawing under people.
  - **HOUSE:**
    - role `farm`, tag "" → `barn`; tag `windmill` → `windmill`; tag `watermill` → `watermill`;
    - role `house`, tag `carpenter` → `carpenter`;
    - `_spin` stays hidden for sprite mills.
  - **FARM_FIELD** → `field_<crop>`, crop from the field's existing `art.crop` plan.
  - **Fallbacks:** a variant missing from the manifest falls back to the procedural art, so the name map returns "".
- **Flat sprites** (bridge, dock, fields): drawn on the ground layer like their procedural versions. The test suite checks that people walking on them draw above them.
- **Tests:** mapping cases for every new name and fallback; every new set added to `NAMES`; existing tests unchanged in meaning.

## Unchanged

- `Structure` state, the rng streams, hits, crowd and gameplay.
- `state_digest` stays `61267b7e90524d800bf1c3473a71146b`.

## Order and review

| Group | Sets |
|---|---|
| 1 | stalls, fountains, wells |
| 2 | torches, lamps, trees |
| 3 | bridge, dock |
| 4 | barns, carpenter, windmill, watermill, fields |

After each group:
- tests (failures=0, 0 SCRIPT ERROR) and the digest;
- glow under 5%;
- a mission bench, sprites against procedural; noisy while other Godot sessions run, so report the medians;
- town captures sent to the user, then a stop for the user's review;
- commit and push of `feat/ref-batch3`;
- a KAK Dev Ledger update.

## Testing

- **Python tooling:** `tools/dev/ref_convert/convert.py`, the generic converter, has a self-test. It converts the bell tower's crop and must reproduce the committed `bell_tower` intact silhouette within 2 px at the corners.
- **GDScript:** the mapping and fallback tests in `tests/test_sprite_art.gd`, plus a flat-sprite draw-order test for the bridge, dock and fields.
