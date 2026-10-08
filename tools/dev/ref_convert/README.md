# Reference conversion tools (free, no AI)

Turn the user's reference sheets (`concepts/TOWN REF/TownMap_Component1-4.png`) into game sprites. No PixelLab, ChatGPT or Codex calls: every script is crop, fit, draw and write. Python 3 with Pillow. Run from anywhere; paths resolve from the repo root. Most scripts take `[all | <name> ...]` and `--out <scratch dir>` (write PNGs there, touch no asset or manifest).

Each script's module docstring is the full spec of its sets. This page is the map.

## Building sets (batch 3, `assets/pixellab/buildings/`)

Each set has `intact.png`, `damaged.png`, `ruins.png`, and often `idle.png` (a strip of frames). The manifest is `assets/pixellab/buildings/manifest.json`, read by `src/environment/art/sprite_art.gd`.

### The generic converter

`convert.py <set> --sheet <png> --box x0,y0,x1,y1 --footprint W,D [options]`

- Pipeline: crop, keep the largest shape, scale so the body width matches the plot's diamond, then unsharp, hard alpha, median-cut palette, 1 px outline. It sets the anchor at the lowest body pixel.
- Options: `--mirror`, `--colors 40`, `--harmonize`, `--keep-green`, `--canvas-pad 6`, `--width-rows 0.62,0.78`, `--measure body|bbox`, `--kind --role --tag --height --seed`.
- `convert.py selftest` converts the bell tower into a scratch folder and checks its silhouette against the committed `bell_tower` intact (within 2 px). No committed asset is touched.

### Per-family scripts

| Script | Sets |
|---|---|
| `stalls.py` | `stall_<n>` (12 designs) and `stall_<n>_<red\|blue\|cream>` tints (`huemap`); awning-ripple idle. `cut` writes only a review sheet |
| `fountains.py` | `fountain` (water shimmer idle), `well` |
| `posts.py` | `torch_post`, `lamp_post` (painted flame cut off; the engine's flame burns there: `keep_flames`) |
| `trees.py` | `tree_1..5` (forest, meadow), `oak_1..3` (town garden); crown-sway idle |
| `bridges.py` | `bridge_stone` (sheet surfaces laid on the iso geometry, 8 torch piers, end steps), `dock` (drawn clean) |
| `warehouse.py` | `barn`, `carpenter` from the timber warehouse, crane dropped |
| `gpt_convert.py` | The ChatGPT sheets, one `SHEETS` entry each (GPT buildings proof; plots in `src/environment/art/gpt_proof.gd`): `gpt_townhall`, `gpt_armoury`, `gpt_jail`, `gpt_courthouse`, `gpt_watchtower`, `gpt_treasury` from `concepts/GPT/defence_sheet_v1.webp`; `gpt_chapel`, `gpt_monastery`, `gpt_graveyard`, `gpt_hospital`, `gpt_leperhouse`, `gpt_bathhouse` from `concepts/GPT/faith_sheet_v1.webp` |
| `mills.py` | `windmill`, `watermill`: bodies drawn clean, sails and wheel rasterised per frame (never a bitmap rotation) |
| `fields.py` | `field_0`, `field_0_2` (wheat, sway), `field_1`, `field_1_2` (cabbage) |
| `corner_roof.py` | Gives the corner towers town_tower's roof. Runs once; it refuses a set whose torches are gone |

### The bell tower (from `feat/ref-re-texture`)

| Script | Does |
|---|---|
| `convert_bell.py` | First conversion of the sheet's bell tower |
| `retexture_bell.py` | Repaints the walls with the town tower's brick pattern |
| `finish_bell.py` | Arch frames round window and door, then the damaged and ruins states |
| `bell_ruins_from_tower.py` | Ruins from the approved `town_tower` ruins, scaled to the 1.1 plot (run after `finish_bell.py`) |
| `bell_flag_wave.py` | The flag's travelling-wave idle strip |
| `banner_sway.py <set> ...` `[--frames 6 --fps 6 --amp 1.6]` | Hanging banners sway; extends a set's idle strip |

### Manifest keys in use

| Key | Meaning |
|---|---|
| `size` | Canvas `[w, h]` in px |
| `footprint` | Plot `[w, d]` in ground units |
| `anchor` | The footprint's front corner in sprite px (where `Structure.position` sits) |
| `kind`, `role`, `tag`, `height`, `seed` | How `SpriteArt.name_for` maps a structure to the set |
| `frames`, `fps` | Idle strip length and speed. The shared idle clock steps it (`SpriteView`) |
| `keep_flames` | The engine still draws its procedural flames and glow over the sprite |
| `flame` | `[x, y]` flame point, sprite px |
| `glass` | `[x, y, w, h]` lantern glass rect, lit by the engine |
| `strip`, `period` | A wall strip tiled along a run; `period` is its repeat in ground units |
| `chimney` | `[x, y]` smoke point |
| `collapse_frames` | A generated collapse strip (batch 1-2 only; batch 3 uses the engine sink) |

## Decor sets (batch 4, `assets/pixellab/decor/`)

Each set is one folder with `intact.png` (plus `stump.png` for trees). The manifest is `assets/pixellab/decor/manifest.json`, read by `src/environment/art/decor_sprites.gd`. Sheet cuts came out as speckle at decor size, so nearly all of these are drawn.

### Writer and keys

`decor_common.write_set(name, img, anchor, segment=None, glow=None, end_post=None, footprint=None)` saves the PNG and inserts or replaces the set's manifest line (one entry per line, tab indent, LF; new names are appended). Always write through it.

| Key | Meaning |
|---|---|
| `size` | Canvas `[w, h]` |
| `anchor` | The piece's ground point in sprite px |
| `segment` | Ground units one tile covers; the set repeats along a run |
| `end_post` | `[x, y, w, h]` sub-rect drawn at a run's far end (fence closing post) |
| `glow` | `[x, y]` px from the anchor where a lamp's light pool sits |
| `footprint` | `[w, d]` ground units; `DecorSprites` picks the nearest (garden plots) |

### One script per group

| Script | Sets |
|---|---|
| `decor_goods.py` | `barrel_1..2`, `crates_1..2`, `bench_x/_y`, `table_1..2`, `logs_1`, `cart_1..2`, `signpost` |
| `decor_street.py` | `lamp_house` (lit lantern, a still: `glow`, `glass`), `bunting_x/_y` (segment 1.0) |
| `decor_water.py` | `ship`, `boat_1` (along x), `boat_2` (along y) |
| `decor_farm.py` | `fence_x/_y` (segment 0.5, `end_post`), `garden_1..4` (by plot size), `scarecrow` |
| `decor_animals.py` | `sheep_1..2`, `cow_1..2` (face right; the engine mirrors half) |
| `decor_nature.py` | `bush_1..3`, `rock_1..3`, `flowers_1..3`, `reeds_1..2`, and the floor's small `shrub_1..3`, `flowerbed_1..3` |
| `decor_trees.py` | `forest_oak_1..3`, `forest_pine_1..2`, `town_oak_1..3`, `town_pine_1..2`, each with `stump.png`. `--preview DIR` |

### Runtime atlas for trees

Each tree family (forest, town) is packed at load into one texture: stills side by side along x, 1 px gap, **bottom-aligned**. A forest band then draws in one call. `wind.gdshader` sways by `1 - UV.y`, the height in the texture, so bottom alignment keeps the sway growing from a tree's foot to its top. No atlas PNG is committed; `DecorSprites` builds it.

## Rules learned

- **Draw clean at decor size.** Sheet cuts come out as mottled speckle at a quarter of the sheet's scale. Draw on a fixed tone pattern in the sheet's tones, with a 1 px outline. The bar is the user-approved drawn dock.
- **Light from the left.** The sheets light some pieces from the right: mirror them. Mirrored animals are lit from the right, as the procedural ones.
- **Native scale.** About the procedural piece's size, up to 1.3x for readability. A sheet person is ~50 px, a game person ~17: scale 0.33.
- **No sampled noise.** The user rejects patched or rough texture.
- **Ruins are clean.** Reuse the approved ruins of the nearest set, or draw a clean one. No rubble spray.
- **Never re-run `convert.py` on `bell_tower`.** Normal mode would overwrite its hand-set size and anchor.
- **Each decor set is its own texture**, except the tree atlas (horizontal, bottom-aligned for the wind shader). The textured-quad sway weight is the whole texture's `UV.y`.
- **`stump.png` shares the intact canvas** and anchor, so a felled tree draws at the same point.
- **Decor strips are the exception (art animation round, below).** Only a manifest `frames`/`fps` set animates; flames, smoke, glows and banners stay procedural.

## Animation (`feat/art-animation`, free, no AI)

Spec: `docs/superpowers/specs/2026-10-05-art-animation-design.md`. Frames are drawn locally from the existing sprites and step in shaders on the shared idle clock.

### Tools

- **`bonfire_flicker.py <set>... [--check]`**: finds each painted fire-basket flame (warm, bright pixels grown from the pale core, held to the dark basket's columns) and redraws it as a 6-frame loop in the set's idle strip. Frame 6 equals frame 0, so the loop has no pop.
  - `--check` verifies the written strips and manifest (loop, frame count, fps) and exits 1 on a failure. Run it after any edit.
  - **Frames and fps:** a flame loop is 6 frames at 6 fps. A set that already has a banner strip of `n` frames becomes `lcm(n, 6)` frames when that is at most 12, with the flame pasted over every banner frame; otherwise the banner frames are re-timed to 6. `fps` keeps the banner's cycle time within 15%. A set with no strip gets a new 6-frame strip at 6 fps.
  - The Citadel keep's strip is PixelLab's own; its flames are read from that strip's frame 0, not from the intact still.
- **`banner_sway.py`**: the banners' sway strips (towers, and now the barracks banner). Citadel wall, wall-side, cathedral and postern have no banner.
- **`window_glow.py <set>... [--dry]`**: writes `<set>/glow_mask.png`, one frame in size, white on the lit window panes and transparent elsewhere.
  - **Masks:** a pane is a warm, lamp-bright core with dark bars round it, grown 4-connected over its own rare tones (a seeded, bounded flood fill) and kept only if it fits a window and is framed.
  - **Guards:** saturation, lamp-brightness and yellow-orange tests drop cream plaster, sandstone and roof highlights; clusters over `MAX_CLUSTER` px are flames or lit floor and are dropped; flame boxes from `bonfire_flicker.flames()` are excluded; a set with an idle strip is read from frame 0 and a pixel must pass in every frame; set names are validated before anything is written; each set has a lower-bound pixel count in the tests.
  - **It refuses strip sets** (manifest `strip`: the town wall and postern). A piece there draws a region wider than one frame, so the mask lookup would stretch.
  - `window_glow.lit(frames)` is the finder alone; `style_match.py` runs it on a converted sprite before its palette lock.
- **`style_stats.py [<set>...] [--state] [--dir]`**: the style numbers of intact stills (outline luminance, edge contrast, distinct colours, saturation, luminance) and each set's dominant material against the references.
- **`style_match.py [--palette]`**: the style match pass, `gpt_convert.py`'s final step: saturation per material, local contrast, a lock to the game palette (`game_palette.png`, rebuilt from the reference sets with `--palette`) within each pixel's material, speck clean, darker eaves, the in-game outline colours and the lit-window ramp (it writes the `gpt_*` glow masks).

### Engine

- **`glow_mask.png` and `WINDOW_AMP`:** `SpriteArt` loads the optional mask. On the intact still and its idle strip, `structure_sprite.gdshader` multiplies masked pixels by `1 + WINDOW_AMP * flicker`, with `WINDOW_AMP = 0.15` (`sprite_view.gd`). Each 3x3 pixel cell has its own phase, so windows flicker apart. No mask, no change. Damaged and ruins stills never flicker.
- **Decor manifest keys:** `frames` and `fps` on a decor set. `intact.png` is then a horizontal strip of `frames` equal-width frames, and `size` is one frame. Written by `decor_common.write_set`.
- **Motion classes** (`Decor.material_for(kind)`, shared materials): `tree` (sway weight 1.5), `plant` (1.5 since art polish 2, for reeds, bushes and flowers, which join `Decor.SWAYS`: at 1.0 the rounded offset left short plants still much of the time), and `bob` (ships and boats: a whole-pixel rise and fall, about a 3 s period, no shear).
- **Plant layer:** low plants (the floor's meadow shrubs and flower clumps, and the baked reeds, bushes and flowers) leave the floor bake and draw in wind bands, like `ForestLayer`. Only pieces nothing stands in front of go there: a plant the bake paints something over (a garden plot, a moored boat, a rock) is marked "under" and stays in the bake, still, and so, transitively, does any plant behind an "under" plant that overlaps it.

### Rules

- **Frame stepping runs on `idle_time`.** It freezes with the mission and follows time scale and hit-stop. Each piece has its own phase.
- **Wind sway and bob run on `TIME`**, like the trees and bunting always did, so they keep moving on a frozen mission.
- **Animated decor stays live.** It is never baked into the floor and never merged into a pile.
- **The front covers go live.** Baked pieces in front of and overlapping an animated live piece also go live, so y-sort draws them over it. Pieces marked "under" stay baked and do not animate. Cover tests use each set's real drawn box.
- **Live stand-ins take the bake tint** (`GROUND_EVENING` / `EVENING`), set before `add_child`, so they match the baked neighbours.
- **F7 off** draws everything procedurally, exactly as before.

## Gates

Run from the repo root. `GODOT` is the console exe (`Godot_v4.7.2-stable_win64_console.exe`).

```
GODOT=<console exe> bash tools/test.sh
"$GODOT" --headless --path . -s tools/dev/state_digest.gd
python tools/dev/check_sprite_glow.py
"$GODOT" --path . --audio-driver Dummy --disable-vsync --scene res://scenes/mission.tscn -- --bench   # add --art=procedural after --bench for the procedural run; grep bench[mission]
```

- **Tests:** need `failures=0`, and grep the output for `SCRIPT ERROR` (the runner does not count it). Check counts at wrap-up: batch 3 `2167`, decor `2305` or more.
- **Digest:** must stay `61267b7e90524d800bf1c3473a71146b`.
- **Glow:** no sprite over 5% glowing. `--masks DIR` writes a mask per sprite.
- **Bench:** the mission bench, sprites against procedural (`-- --bench --art=procedural`); grep the output for `bench[mission]`. Run 3 alternating pairs and report the medians; other Godot processes make it noisy, so note how many ran. `capture.sh --bench` is not used: it never passes `--disable-vsync`, so vsync caps it at about 142 fps and two runs read as equal. Sprites should stay within ~3 fps of procedural.

## Adding a new set

1. **Buildings:** a `convert.py` call, or a script like the nearest family (copy its states code), with `--kind --role --tag --height --seed`. **Decor:** a `decor_<group>.py` function that draws the image, then calls `decor_common.write_set`.
2. Fit the base to the footprint diamond (corners within +-3 px) and pad the canvas; never rescale after placing. For decor, anchor at the piece's ground point.
3. Make damaged and ruins for buildings. Decor has no states: a down tree draws its `stump.png`, everything else nothing.
4. For a run, add `segment` (and `end_post`); name variants `<kind>_<n>` and runs `<kind>_x` / `_y`.
5. Map it: `SpriteArt.name_for` (buildings) or `DecorSprites.name_for` and its kind tables (decor).
6. Add tests (mapping, fallback to `""` when missing) and run the gates above.
7. Look at it in a capture with F7 on, send the user a capture and wait for review.
