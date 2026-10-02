# PixelLab structures log

Every PixelLab call made for the building sprites: what was asked, with what, what it cost, and what was kept.

- **Route:** PixelLab's REST API (`https://api.pixellab.ai/v2`) through `tools/dev/pixellab_api.py`.
- **References:**
  - `reference.png` is today's procedural building, from `tools/dev/render_sprite_refs.gd`: its footprint, angle and size;
  - `style_ref.png` is the matching building cut from `concepts/TOWN REF/TownMap_Component1.png` by `tools/dev/make_style_refs.py`.
- **Costs** are in subscription generations: the balance before and after each call.

## Recipe

1. `generate`, at the sprite's canvas size, with both references (usage text below).
   - At most 85 px on the longer side returns 16 candidates, up to 170 px returns 4, above that 1.
2. Pick a candidate that fits on the canvas without touching its top.
   - Find its front corner (the lowest opaque pixel at the building's front).
   - If that is off `SpriteArt.default_anchor`, set `"anchor"` in the manifest.
3. `edit` the kept sprite twice: damaged, then ruins.

Usage text for the two references:
- reference: "exact footprint, isometric 2:1 camera angle, silhouette, proportions, size and position of the building on the canvas; keep this composition"
- style: "art style only: palette, outline, texture detail and shading; ignore its ground, fence and trees"

## Calls

| # | Sprite | Call | Prompt (short) | Seed | Cost | Result |
|---|---|---|---|---|---|---|
| 1 | cottage_red | generate 84×76, 2 refs | red clay tile roof, timber-framed cream plaster walls, brick chimney, lit windows; only the building | 101 | 25 | 16 candidates. Rows 1–2 (00–07) clip at the canvas top. Kept **11**: front corner (40, 69), anchor set |
| 2 | cottage_red | edit (damaged) | cracked plaster, missing and broken tiles, a roof hole, scorch, a broken window; same building and position | 201 | 20 | Kept as is: same outline, holes in the roof, dark windows |
| 3 | cottage_red | edit (ruins) | collapsed: low rubble heap, broken tiles, charred beams, two wall stumps, same footprint | 301 | 20 | Good rubble, but drawn 15 px high and 6 px right of the house. Moved by (−6, +15) whole pixels |
| 4 | cottage_blue | generate 84×76, 2 refs | slate blue tile roof, otherwise as #1 | 102 | 25 | 16 candidates, two-storey timber houses. 00–03 clip at the top, 08–15 at the bottom. Kept **04**: front corner at its corner post's foot, (41, 70) |
| 5 | cottage_red | animate (collapse) | first frame damaged, last frame ruins; "the roof caves in, the walls crumble and fall inward…", 8 frames | 401 | **1** | 9 frames from damaged to ruins: the roof caves in, then the walls fall. Kept as `collapse.png` |
| 6 | cottage_blue | edit (damaged) | as #2 | 202 | 20 | Kept as is |
| 7 | cottage_blue | edit (ruins) | as #3, with slate tiles and "exactly where the house stood" | 302 | 20 | Charred beams and slate. Again drawn high: moved by (−6, +19) |
| 8 | cottage_blue | animate (collapse) | as #5 | 402 | **1** | Kept as `collapse.png` |

**Cottages total: 132 generations** (2000 → 1868).

## Findings

- **The composition reference is followed loosely.** PixelLab keeps the iso angle and the canvas position, but draws its own cottage: 62 px wide against the reference's 69, and 6–9 px taller. That reads fine on a cottage's footprint. Measure the anchor per pick; don't assume it.
- **Candidates come in a 4×4 grid whose rows sit at different heights.** The first rows can clip at the top and the last ones at the bottom. Check the alpha bbox, not just the look.
- **Damaged edits keep the outline exactly.** They can go straight in.
- **Ruins edits drift up and right, by 15–19 px and 6 px on 84×76.** A whole-pixel move puts the heap back on the footprint. Check the lowest row against the intact sprite's.
- **Generated collapses cost 1 generation, against 20–25 for each still, and look good.** With the damaged and ruins sprites pinned as first and last frames, PixelLab fills the fall in between. Every building up to 256 px can have one. The engine plays it on a fall (`collapse_frames` in the manifest). Gravity keeps the engine's inward squeeze, and the laser its slice.
