# PixelLab structures proof — design

**Branch:** `feat/pixellab-structures`, off `feat/vfx-proof` at `21c28c5`. Nothing merges back until the proof is judged.

**Goal:** prove that the town's procedural buildings can be replaced by high-detail pixel-art sprites made with PixelLab, in the style of `concepts/TOWN REF/` (`TownMap_Component1.png`, `Town Visual Upgrade.png`), with an idle state, a damaged state and a collapse, and without changing how the game plays.

## Decisions (with the user, 2026-10-02)

| Topic | Decision |
|---|---|
| Scale | **Native 1:1.** Sprites are drawn at today's building size on the 640×360 grid. Detail comes from shading and texture, not extra pixels. The render resolution and the town layout do not change |
| Buildings | Cottage, Tavern, Smithy, Cathedral, Citadel (keep, towers, walls). Every other component comes later, made the same way |
| Animation | **Hybrid plus one comparison.** PixelLab makes the key frames (intact, damaged, ruins) and small idle loops; the engine plays the collapse. One PixelLab-generated collapse (the Cottage) is made to compare against the engine's |

## 1. Assets

### 1.1 Targets

Canvas sizes are today's renders from `tools/dev/preview_components.gd` (zoom 1, `captures/components/`), padded to a multiple of 4.

| Sprite | Replaces (role / `tuning_key()`) | Footprint | Today's render | Canvas |
|---|---|---|---|---|
| `cottage_red`, `cottage_blue` | `house` / `house` | 0.95×0.75 (wide); 0.75×0.95 (deep) = mirrored | 69×56 | 72×60 |
| `tavern` | `house` / `house_tavern` | 2.4×1.5, 1.6×2.4, 2.8×1.8 | 127×105 | 128×108 |
| `smithy` | `house` / `house_smithy` | 1.5×1.25 | 102×99 | 104×100 |
| `cathedral` | `temple` / `temple_cathedral` | 4.2×6.2 | 344×223 | 348×224 |
| `citadel_keep` | `citadel` / Kind.KEEP, 2.0×2.0 | 2.0×2.0 | 133×189 | 136×192 |
| `citadel_tower` | `citadel` / Kind.KEEP, 1.3×1.3 | 1.3×1.3 | 89×133 | 92×136 |
| `citadel_wall` | `citadel` / Kind.CASTLE_WALL | 2.8×0.6 (N, S); 0.6×2.0 (W, E) = mirrored | ≈109×103 (computed: footprint 109 px across, 40 high plus crenels) | 112×108 |

The three taverns have different footprints. The proof makes one tavern sprite for the 2.8×1.8 footprint and checks how it sits on the other two. If it reads badly, a second sprite is generated.

### 1.2 Per sprite

Each sprite has three stills on the same canvas and the same anchor:

- **intact** — `create_image_pro`, with two labelled references:
  - **today's render** of the building, cropped from `captures/components/` on transparency: "exact footprint, iso camera angle, silhouette and size";
  - **a crop of the matching building** from `TownMap_Component1.png`: "art style, palette, detail and shading".

  Fixing the composition to today's render keeps the 2:1 iso angle and the footprint diamond, so the anchor is known: the front corner of the footprint, where `Structure.position` sits. If the result drifts by more than 2 px from the diamond, it is re-rolled or shifted by hand.
- **damaged** — `edit_image` on the intact sprite: "cracked walls, missing roof tiles, scorch marks, a broken window". Sprites of one size go in one batched call, so they get one edit and one charge.
- **ruins** — `edit_image` on the intact sprite (or `create_image_pro` if the edit keeps too much of the building): a rubble heap with stumps of wall, on the same footprint.

Idle loops (`animate_image`, 4–8 frames) are made only where something moves:
- **smithy:** the forge fire;
- **citadel keep:** its banner.

Chimney smoke stays procedural (`ChimneySmoke`).

**The comparison:** an `animate_image` collapse of `cottage_red`, with the damaged sprite as the first frame and the ruins sprite pinned as the last (8 frames).

### 1.3 Files

- `assets/pixellab/buildings/<sprite>/intact.png`, `damaged.png`, `ruins.png`, and `idle.png` (a horizontal strip) where one exists.
- `assets/pixellab/buildings/manifest.json`: each sprite's canvas size, anchor (px, the footprint's front corner), idle frame count and fps.
- `docs/pixellab_structures_log.md`: each call's tool, prompt, references, seed and cost, and which candidate was kept. This is the recipe for the remaining components.

## 2. Engine

### 2.1 SpriteArt

`src/environment/art/sprite_art.gd` (new, static, like the other art classes):
- `SpriteArt.set_for(s: Structure) -> Dictionary` returns the sprite set that replaces this structure, or `{}`. It matches on role, kind, art tag and footprint (the Citadel's keep and towers share Kind.KEEP and role `citadel` and differ only in size). Cottages pick red or blue from a hash of the structure's seed, as `ArtKit.plan_for` does. **It never draws from `s.rng`**: the state digest covers each building's random stream.
- A set holds its textures, its anchor, whether it is mirrored (a deep footprint drawn from a wide sprite), and its idle frames and fps.
- Loaded once from `manifest.json` and cached.

### 2.2 Structure

- `setup()` stores `sprite = SpriteArt.set_for(self)` next to `art`.
- In `_draw()`, a structure with a sprite set draws it instead of its procedural art, its windows and its cracks. The ground shadow stays. Structures without a set are untouched.
- **Which still:**
  - **intact** while standing;
  - **damaged** once it has cracked — at 65% health, or when the Citadel cracks a part (`crack()`), the moment cracks appear today; the repair path (`ease_marks`) clears the cracks and so brings back the intact sprite;
  - **ruins** once destroyed and the collapse has finished.
- **Idle frames** step on a node of their own, the way the banner and flame nodes do now, so the building stays cached and can still idle (`_can_idle()`).
- **Collapse** (`_collapse` 0→1, `COLLAPSE_TIME` as today): the damaged sprite shakes and sinks by its own height, clipped at the ground line so it disappears into the ground. The ruins sprite is drawn beneath it, fading in over the first third. Today's debris, dust and fire spawn unchanged.
  - **Gravity** pulls inward instead: the sinking sprite also squeezes horizontally toward its centre.
  - **Laser:** the cut height is today's. The sprite is drawn in two parts, split at the cut: the stump stays with a molten line, the top slides off along `_top_piece` and fades. The ruins sprite appears under the stump once the top has fallen.
- `_build_rubble()` still runs (the digest hashes its shapes and the walk grid reads them), but a structure with a sprite set does not draw the rubble fans.

### 2.3 Lighting

`src/environment/art/structure_sprite.gdshader` (new) takes the art shader's uniforms (`light_col`, `light_dir`, `ambient`, `scorch`, `frost`, `tint`), filled by `_light_art()`. Per pixel:
- lit by the same formula as `structure_art.gdshader`, with an even facing (no per-face normals on a sprite);
- charred toward `CHAR` by `scorch`, frosted by `frost`, as now;
- **glow pixels** (bright, saturated warm: lit windows, the forge) skip `ambient` and `scorch`, so windows still glow in the dim;
- a `clip_y` uniform hides pixels below the ground line, for the collapse.

### 2.4 Toggle

- Command line `-- --art=procedural` turns sprite sets off (`SpriteArt.enabled = false`) for old-vs-new captures. It defaults to on in this branch.
- `F7` in the mission and in `town_debug` flips it live: every structure re-reads its set and redraws.
- `preview_components.gd` renders sprite and procedural versions side by side.

## 3. Proof criteria

1. **Look:** old vs new captures of the town at play zoom, plus each sprite alone from `preview_components.gd`.
2. **States:** for each sprite type, a capture series of a scripted hit: intact → damaged → collapse midway → ruins, under a blast, a laser and gravity.
3. **Gameplay unchanged:** `tools/dev/state_digest.gd` gives the same digest with sprites on and off.
4. **Speed:** mission bench no worse than the ~116 fps baseline (v0.07), on a quiet machine.
5. **Comparison:** the generated Cottage collapse plays next to the engine collapse in one capture, for the user to judge.

## 4. Order

1. **Engine first, with placeholders.** Build SpriteArt, the sprite path, the shader, the collapse and the toggle, using today's renders (cut from `captures/components/` onto transparency) as placeholder sprites. Criteria 2–4 can be proven before any generation is spent.
2. **Generation** (needs the PixelLab subscription renewed; it expired 2026-09-26 and its 1999 generations are frozen):
   1. Cottage first. Judge the look in-game before going on.
   2. Then the tavern, smithy, citadel parts and cathedral.
   3. Then the damaged and ruins stills, the idle loops and the comparison collapse.
3. Swap the placeholders for the generated sprites and run the criteria again.

**Budget:** about 600–900 generations including re-rolls (Pro calls cost 20–40 each; the stills for one size share a call). The log records the real figure.

## 5. Risks

- **The iso angle drifts.** PixelLab may not hold the 2:1 iso angle. Mitigation: today's render is the composition reference; drift beyond 2 px is re-rolled or fixed by hand.
- **Style clash.** Detailed sprites next to procedural neighbours (townhouses, walls, stalls) can look patchy. The proof captures show this honestly; it is a finding, not something to hide.
- **The Cathedral is too big to animate.** At 348 px it is beyond `animate_image`'s 256 px limit. That is why its collapse is the engine's, and it has no idle loop.
- **Lighting looks flat.** Even facing on a sprite loses the procedural art's per-face light from fireballs. If the captures show it, a second pass can split a sprite's left and right walls with a mask.
