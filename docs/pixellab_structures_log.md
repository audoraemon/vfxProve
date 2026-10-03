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

### Tavern, smithy, Citadel, cathedral

One row per building. Every call's job log is in the session scratchpad; the prompts are in `docs/superpowers/plans/2026-10-02-pixellab-structures-proof.md` Task 9, with "only the building: no ground tile…" added.

| Sprite | Canvas | Intact (seed, cost, pick) | Damaged / ruins | Collapse / idle | Fits | Total |
|---|---|---|---|---|---|---|
| tavern | 156×136 | 103, 25, **02** of 4 | 203 / 303, 20 + 20. Ruins moved (−6, +7) | collapse 3: falls in a dust cloud | anchor (84, 121) | 68 |
| smithy | 108×116 | 104, 20, **01** of 4. **Came back on white**, so its background was flood-filled out | 204 / 304, 20 + 20. Ruins: a burnt-out shell, moved (0, +17) | collapse 2: catches fire and burns down. Idle 1: forge fire and smoke, 5 frames | anchor (54, 112), the yard's front corner | 63 |
| citadel_tower | 96×148 | 106, 20, **01** of 4. Machicolations, brazier; the stone reference for the rest of the Citadel | 206 / 306, 20 + 20. Ruins moved (0, +16) | collapse 2, then a re-roll (2): the first shrank and "healed" midway | 1.15 cells on a 1.3 footprint: centred, anchor (50, 131) | 64 |
| citadel_keep | 140×204 | 105, 20: **rejected**, too small (104×163) and plain. Re-rolled with the tower as a reference: 115, 20, kept | 205 / 305, 20 + 20. The ruins left the battlement ring floating: dropped it (largest connected shape), moved (0, +5) | collapse 4, then a re-roll (4): the first shrank and "healed" midway. Idle 2: flag and braziers, frames 1–4 (the first sits 1 px lower) | 1.7 cells on 2.0: centred, anchor (69, 197) | 90 |
| citadel_wall | 124×116 | 107, 20, **02** of 4 (machicolations, like the tower) | 207 / 307, 20 + 20. Ruins moved (0, +22) | collapse 2: smoke, then it crumbles | 2.4 cells on 2.8: centred between its towers, anchor (97, 115) | 62 |
| citadel_wall_side | 100×104 | 108, 20, **00** of 4, with the wall as the reference | 208 / 308, 20 + 20. Ruins moved (0, +8) | collapse 2 | 2.0 cells, exact; anchor (77, 94) | 62 |
| citadel_gate | 124×116 | 109, 20, **00** of 4: portcullis arch, torches, banner | 209 / 309, 20 + 20. Ruins moved (0, +14): the portcullis lies in the heap | collapse 2 | 2.4 on 2.8: centred, anchor (98, 107) | 62 |
| cathedral | 360×240 | 110, 25, 1 candidate. Gothic, flying buttresses, spire. **Only 256 px wide** against the footprint's 333 | 210 / 310, 25 + 25. Lined up; no move | none: over 256 px, the engine's sink plays | 2.6 × 4.9 cells on 4.2 × 6.2: centred, anchor (147, 252) | 75 |

**Grand total: 678 generations** (2000 → 1322), across 44 calls. 26 of them went on rejected results (the first keep, two collapses).

**Fix (2026-10-03, user review):** the cathedral's ruins left arches, pinnacles and wall stumps standing, so its fall did not read as a collapse. Re-edited with "completely destroyed and flattened… no walls, arches, buttresses, pinnacles, towers or spire left standing, nothing taller than a few blocks" (seed 311, 25). The result was a flat heap of stone, beams, copper sheets and glass, drawn 53 px high and 20 px right; moved (−20, +53). Total 703.

## Findings

- **The composition reference is followed loosely.** PixelLab keeps the iso angle and the canvas position, but draws its own cottage: 62 px wide against the reference's 69, and 6–9 px taller. That reads fine on a cottage's footprint. Measure the anchor per pick; don't assume it.
- **Candidates come in a 4×4 grid whose rows sit at different heights.** The first rows can clip at the top and the last ones at the bottom. Check the alpha bbox, not just the look.
- **Damaged edits keep the outline exactly.** They can go straight in.
- **Ruins edits drift up and right, by 15–19 px and 6 px on 84×76.** A whole-pixel move puts the heap back on the footprint. Check the lowest row against the intact sprite's.
- **Costs by size.** A still costs 25 up to 85 px (16 candidates) and 20 from 86 to 170 px (4 candidates). Above 170 px a still costs 20–25 for a single candidate, so a bad roll means paying again. Edits cost 20, or 25 on the cathedral. Animations cost 1–4.
- **Use the first good part as the style reference for the rest of a set.** The tower, passed as a reference, made the keep, walls and gateway one castle. Given only the concept art, the first keep came out plain.
- **The subject is capped near 256 px whatever the canvas.** The cathedral came back exactly 256 px wide on a 360 canvas. Anything bigger is undersized, or needs another approach (generate it in parts).
- **A candidate can come back on white despite `no_background`** (the smithy, which filled its canvas). Flood-fill the edge colour out, and clear pockets of it seen through openings.
- **A collapse can "heal" midway:** the damage fades and the building shrinks before snapping to the ruins. Asking for "crumbles from the top down… it is never repaired" fixed both the keep's and the tower's.
- **An idle loop's generated frames can sit 1 px off frame 0.** Loop the generated frames only.
- **Generated collapses cost 1 generation, against 20–25 for each still, and look good.** With the damaged and ruins sprites pinned as first and last frames, PixelLab fills the fall in between. Every building up to 256 px can have one. The engine plays it on a fall (`collapse_frames` in the manifest). Gravity keeps the engine's inward squeeze, and the laser its slice.

## People (2026-10-03)

Characters made with `tools/dev/pixellab_api.py character --size 16` (standard mode, 8 rotations, low top-down), then `char-anim` with the templates `breathing-idle`, `walking-4-frames`, `running-4-frames`, `crouching` and `falling-back-death` in south-east, south-west, north-east and north-west. Prompts are in `docs/superpowers/plans/2026-10-03-pixellab-people.md`.

| Step | Cost | Result |
|---|---|---|
| Size tests: resident and guard at 24 and 32, then 16 and 20 | 7 | 24 → 27 px figures, 32 → 35 px, 20 → 22 px, 16 → 18–19 px. **Chose 16**: native beside the doors and stalls |
| Pilot: resident_a and guard, 5 animations × 4 directions | 41 | The first batch landed only some directions (PixelLab drops what has no job slot); the helper now fills in the missing ones |
| 14 designs (resident_b … escort), character + 20 animation directions each | 294 | All complete, 4–7 frames a direction |
| Rescue | 21 + 21 | First: no visible shovel, red like the marshal. Re-rolled: "holding a big iron shovel in both hands, no spear, no shield" |

**People total: 384 generations** (1297 → 913). **Everything so far: 1087** (2000 → 913).

## Fixes (2026-10-03)

| Call | Cost | Result |
|---|---|---|
| `inpaint` the keep's intact still: banners and flag masked (`tools/dev/banner_mask.py`), "bare pale grey cut stone… only the bare flagpole", seed 801 | 20 | Clean. 711 px changed, all inside the mask but 3 |
| `inpaint` the keep's damaged still, the same with "cracked… scorch marks", seed 802 | 20 | The banner patches come out a little paler than the wall round them; they read as where the banners hung. Kept |

**Total so far: 1127** (2000 → 873).
