# PixelLab structures proof — summary

**Branch:** `feat/pixellab-structures` (worktree `F:\Godot\Git\vfxProve-pixellab`), off `feat/vfx-proof` at `21c28c5`.

**Spec:** `docs/superpowers/specs/2026-10-02-pixellab-structures-proof-design.md`. **Plan:** `docs/superpowers/plans/2026-10-02-pixellab-structures-proof.md`. **Every PixelLab call:** `docs/pixellab_structures_log.md`.

**Question:** can the town's procedural buildings be replaced by high-detail PixelLab pixel art in the style of `concepts/TOWN REF/`, with idle, damaged and collapse states, without changing the game?

**Answer: yes.** Two parts of the setup made it work:
- the composition reference fixes each building's footprint, angle and size;
- the first good piece of a set becomes the style reference for the rest of it.

The engine plays every state, the game plays exactly as before, and the frame rate is unchanged. 678 of 2000 generations for 10 sprites.

## What was replaced

| Building | In town | Intact, damaged, ruins | Collapse | Idle |
|---|---|---|---|---|
| Cottage (red, blue) | all 57 plain houses, roof by seed. The 18 townhouses keep their procedural art | PixelLab | PixelLab (1 generation each) | chimney smoke, from each sprite's own chimney |
| Tavern | 3 (2.4×1.5, 1.6×2.4 mirrored, 2.8×1.8) | PixelLab | PixelLab: falls in a dust cloud | smoke drawn in |
| Smithy | 1 | PixelLab | PixelLab: catches fire and burns down | forge fire and smoke loop (5 frames) |
| Cathedral | 1 | PixelLab | the engine's sink (at 360 px it is too big to animate) | — |
| Citadel keep | 1 | PixelLab | PixelLab: crumbles from the top | flag and braziers loop (4 frames) |
| Citadel towers | 4 | PixelLab | PixelLab | — |
| Citadel walls (long, short, gateway) | 4 | PixelLab | PixelLab | — |

Everything else is still procedural: the town walls, gates, bell tower, barracks, townhouses, workshop, carpenter, barns, mills, stalls and props.

Captures, procedural on the left and sprites on the right (local to the worktree: `captures/` is gitignored; regenerate them with `tools/dev/sprite_states.gd` and `tools/capture.sh --capture-town`):
- `captures/sprite_proof/compare_town_overview.png`
- `captures/sprite_proof/compare_town_citadel.png`
- `captures/sprite_proof/compare_town_market.png`
- `captures/sprite_proof/compare_town_crowd.png`
- `captures/sprite_proof/compare_town_main_gate.png`

Each building through its states (procedural, intact, damaged, blast mid-fall, ruins, laser cut, gravity pull): `captures/sprite_states/<name>.png`.

## How it works

- **`SpriteArt`** (`src/environment/art/sprite_art.gd`) decides which structure is drawn from which sprite, and reads `assets/pixellab/buildings/manifest.json`. Each manifest entry gives:
  - canvas, footprint and anchor (the footprint's front corner, measured per sprite);
  - idle strip, collapse strip and chimney.
- **`SpriteView`** (`src/environment/art/sprite_view.gd`, `structure_sprite.gdshader`) draws one still or strip frame. Like the procedural art, it is lit by the effects' light, charred by scorch and frosted by ice; lit windows and the forge still glow in the dim. It clips along the footprint's ground line for the engine's falls.
- **`Structure`** keeps all its state and its random stream as before, and only chooses what its views show:
  - intact, then damaged once it cracks (at 65%, or when the Citadel cracks a part);
  - on a fall: the PixelLab collapse; or, for gravity and for the cathedral, the engine's sink over the ruins (gravity squeezes inward as it sinks);
  - a laser slices it: the stump stays, its top slides off;
  - then the ruins;
  - a rebuild brings back the intact sprite.
- **Toggles:**
  - **F7** in the mission or town debug flips between sprites and procedural, live;
  - `-- --art=procedural` starts procedural;
  - `-- --collapse=engine` plays the engine's sink instead of the PixelLab collapses.
- **Tools:**
  - `tools/dev/render_sprite_refs.gd`: references and placeholders, cut from today's art;
  - `tools/dev/make_style_refs.py`: style crops from the concept sheet;
  - `tools/dev/pixellab_api.py`: PixelLab's REST API, straight from disk;
  - `tools/dev/sprite_states.gd`: the state captures.

## Proof criteria

| # | Criterion | Result |
|---|---|---|
| 1 | Look | Captures above. The Citadel, tavern, smithy and cottages read as the reference sheet's style. Detail per pixel is clearly up from the procedural art at the same 1:1 scale |
| 2 | States | Every sprite shows intact, damaged, fall, ruins, laser and gravity (`captures/sprite_states/`) |
| 3 | Gameplay unchanged | `tests/test_sprite_art.gd` puts the proof's buildings through the same hits with sprites on and off and gets the same state, random streams included. `state_digest` gives `61267b7e…` either way. 1170 checks, 0 failures |
| 4 | Speed | Mission bench, alternating, 3 runs each, machine busy (another session running): sprites **102.5** fps (103.5 / 100.4 / 103.7), procedural **101.3** (99.5 / 100.6 / 103.9). Draw calls 1034 against 1052. The worst single frame is 1–5 ms higher with sprites in most runs (17–21 ms against 16) |
| 5 | Generated vs engine collapse | Generated, clearly: the roof caves in, the walls fall, the smithy burns. It costs 1–4 generations. The engine's sink is the fallback above 256 px, and keeps the gravity and laser reactions |

## Findings

- **Composition reference:** today's render as the reference fixes the iso angle and canvas position. PixelLab still draws its own proportions (a cottage 6–9 px taller), so each sprite's front corner is measured and set in the manifest. Several parts (keep, tower, walls) came back 10–15% under their footprint and are centred on it.
- **Consistency within a set:** the first good part becomes the style reference for the rest; the keep re-rolled with the tower as reference matched it. The concept art alone gave a plain first keep.
- **Size cap ~256 px:** the cathedral came back 256 px wide on a 360 canvas. It is undersized for its plot, and too big to animate.
- **Ruins edits drift up**, by 5–22 px, and sometimes sideways. A whole-pixel move puts them back; once (the keep) a floating piece had to be removed. Damaged edits never drifted.
- **Animated collapses can "heal" midway.** "Crumbles from the top down… never repaired" fixed it, for 2–4 generations.
- **Style mix:** sprite buildings next to procedural townhouses, walls and the bell tower look like two art sets. Converting the rest would remove it.
- **Lighting:** sprites take the effects' light evenly. They lose the procedural art's per-face light, which the captures do not make obvious.
- **Generations:** 678 for 10 sprites (about 62–90 each). 26 went on rejected results. Converting the remaining ~25 component kinds the same way would take roughly 1500–2000.

## Before merging

1. **Worst-frame bump:** the first draw of each sprite likely compiles the shader and uploads textures. Warm them up at load, then re-bench on a quiet machine.
2. **The keep's falling banner:** at 20% health the procedural banner drops; it is hidden on the sprite keep. Animate it, or leave it out.
3. **The cathedral:** accept the 256-px cathedral, or generate it in two parts.
4. **Decide on the rest:** convert the remaining components (the recipe is in the log) or keep the mix.
5. `concepts/TOWN REF/` is untracked in both checkouts. The style refs were cut from it and committed; whether to commit the sheet is your call.
