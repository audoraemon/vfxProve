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

## Batch 2 (2026-10-03)

Balance at start: 873.

| Set | Call | Prompt / refs | Seed | Cost | Result |
|---|---|---|---|---|---|
| town_tower | `generate` 112x136 | grey limestone square wall tower, torch brazier, blue fleur-de-lis banner, arched window, moss; refs: reference.png (footprint), style_ref.png (TownMap_Component4 tower) | 41 | 20 (873 → 853) | 4 candidates; picked #03: banner, window, torch, bottom dy +3, centre dx +2, nothing touches the canvas edge. #00/#01 sat 8 px high; #02 had no banner. Taller than the procedural block (117 px), reads as the reference's tower. Anchor (58, 125) |
| town_tower | `edit` (damaged) | cracked and missing blocks, broken merlons, torn banner, scorch, torch out | default | 20 (853 → 833) | Rejected: the output was a 2x4 tiling of small towers |
| town_tower | `edit` (ruins) | collapsed into a low heap of rubble with a short broken stump | default | 20 (a first attempt, orphaned when the shell timed out, was billed too: 40 in all, 833 → 793) | Kept edit_00; lowest row 106 vs intact 128, moved (0, +22) |
| town_tower | `edit` (damaged, re-roll) | as above plus "one single tower… same size" | 202 | 20 (793 → 773) | Kept edit_00: cracks, scorch, torn banner, torch out, same outline |

town_tower total: 100 generations (873 → 773), 30 over its 70 cap: the orphaned ruins job (20) and the tiled damaged edit (20) were wasted. Lesson: run `edit` calls with `run_in_background` or a long timeout, one at a time. Glow 1.4% intact, 0% damaged, 0% ruins. No collapse (engine sink).

town_tower_corner: reuses town_tower's stills (0 generations), anchor [58, 131.4] centres the 1.6 tower on the 2.0 corner plot, shadow [1.6, 1.6].

| Set | Call | Prompt / refs | Seed | Cost | Result |
|---|---|---|---|---|---|
| town_wall | `generate` 192x152 | straight run of grey limestone with evenly spaced merlons, walkway, moss and bushes, no towers/gate, ends cut straight; refs: reference.png (4.0 x 0.7 run), style_ref.png (TownMap_Component4 plain wall, box moved off the bannered wall to (310, 66, 535, 250)), town_tower/intact.png (family) | 43 | 20 (773 → 753) | 1 image. Rejected: not 2:1 (edges slope ~0.3-0.4, merlon spacing grows left to right, like the sheet's perspective); a 2:1 period shift would step at every seam |
| town_wall | `generate` 192x152 (re-roll) | as above plus "strict 2:1 isometric projection with no perspective: top and bottom edges parallel, 1 px down per 2 px across", "identical merlons evenly spaced like a repeating pattern"; refs: reference.png, town_tower/intact.png (style and family; the sheet style ref dropped because its camera is not 2:1) | 143 | 20 (753 → 733) | Kept: edges and brick courses on 2:1 guides, merlon pitch ~15 px, one torch at x≈95-101. Saved as run_intact.png |
| town_wall | `edit` (damaged) on run_intact.png | the same wall damaged: cracked and missing blocks, broken merlons, scorch marks; same wall, same position | default | 20 (733 → 713) | 2 images, same bbox. Kept edit_00 (more scorch and cracks inside the tiled band) as run_damaged.png |
| town_wall | `edit` (ruins) on run_intact.png | the same wall collapsed into a low line of grey stone rubble with short broken stumps, same footprint | default | 20 (713 → 693) | 2 near-identical images. Kept edit_00; its base line sat 15.5 px high (median of lowest-row − x/2: 52.0 vs 67.5), moved (0, +16). Saved as run_ruins.png |

town_wall total: 80 generations (773 → 693), at its cap; no seam inpaint was needed. Strip: u0 = (41, 83) (the front edge of the run at x = 41, inside the left end's outline; front corner of the run at (147, 136)), period 1.5 (48 px, about three merlon pitches, chosen by matching columns 41.. against 89.. shifted 24 down and keeping the torch out of the repeated band), span 2.7. `sprite_fix.py tile` on all three runs: size [152, 172], anchor [127.4, 126.2], footprint [2.7, 0.7], period 1.5. Glow 0% on the stills (runs 0.1-0.2%). In town (main gate, side gate captures) the north-south and east walls join without jogs; the y-runs read mirrored.

town_postern: copies town_wall's strip stills (0 generations), same strip entry with seed 45, kind GATE, role gate, tag postern. The postern piece now draws its stretch of the plain wall: no door.

| Set | Call | Prompt / refs | Seed | Cost | Result |
|---|---|---|---|---|---|
| town_gate | `generate` 124x132 | gatehouse, round arch, raised portcullis, open doors, torches, fleur-de-lis banner; refs: reference.png, style_ref.png (TownMap_Component4 gatehouse, box 125,262,285,440), town_tower/intact.png | 44 | 25 (693 -> 668) | 4 images; picked #03 (grey stone matches the tower). Door leaves touched the canvas bottom |
| town_gate | `edit` (damaged) on intact | cracked stone, broken merlons, bent portcullis, scorch | default | 20 (668 -> 648) | Kept edit_00 |
| town_gate | `edit` (ruins) on intact | collapsed into rubble around a broken arch stump | default | 20 (648 -> 628) | Rejected: arch and merlons still standing |
| town_gate | `edit` (ruins) on damaged | destroyed: lower third of walls as stumps, fallen arch, rubble, fallen portcullis, banner on rubble | default | 20 (628 -> 608) | Kept edit_00, shifted (0, +21) |

town_gate total: 85 generations (693 -> 608). No generated collapse (budget ruling): engine sink. Stills padded locally to 136x144 (6 px left/right, 12 px bottom), anchor [76, 114]. Glow 3.3% intact, 2.2% damaged, 0% ruins.

### Fix: towers fill their plots

The batch-2 tower's art was 76 px wide on a 102 px footprint diamond (1.6 x 1.6), so ground showed where wall runs end at the footprint edge; the corner tower (2.0 x 2.0, 128 px) reused it with ~26 px gaps. Composition ref: `render_sprite_refs.gd` with the manifest height raised to 96 (tower) / 100 (corner) only for the render, so the procedural block is tall and full-width; heights put back to 46 / 50 afterwards.

| Set | Call | Prompt / refs | Seed | Cost | Result |
|---|---|---|---|---|---|
| town_tower | `generate` 112x172 | massive square isometric stone tower whose walls rise straight from the full width of its base, cool grey limestone, merlons, torch brazier with warm light, blue fleur-de-lis banner, arched window, arched door, moss; refs: reference.png (tall full-footprint block: "walls stand exactly on this footprint's edges, same base width, fill the whole footprint"), style_ref.png (TownMap_Component4 tower) | 241 | 20 (608 → 588) | 1 image, kept. Wall outline x 7..104 (outer edges 7 and 105) vs diamond 4.8..107.2 at anchor x 56: left and right base corners 2.2 px inside, front corner on the anchor. Touched the canvas top and bottom: padded locally to 120x180 (+4, +4). Anchor [60, 172] from overlay variants 170/172/174 |
| town_tower | `edit` (damaged) on intact | the same single tower damaged: cracked and missing blocks, broken merlons, scorch, torn banner, torch out and smoking; same size and position | 242 | 20 (588 → 568) | 2 images, same bbox; kept edit_00 |
| town_tower | `edit` (ruins) on damaged | destroyed: only short broken wall stumps on the same square base, rubble heap filling the base, banner lying on the rubble | 243 | 20 (568 → 548) | Kept edit_00: the stump base was right but the cut-off top and the hanging banner floated above it; cleared rows < 93 and the banner (x 24..42, y ≤ 113) locally, `largest`. Same lowest row as intact (175), no shift |
| town_tower_corner | `generate` 136x200 | massive heavy corner tower, walls from the full width of its broad base, two torches, two banners, windows, no door; refs: reference.png (2.0 tall block), town_tower/intact.png (family), style_ref.png | 342 | 20 (548 → 528) | Rejected: body x 14..121 vs diamond 4..132 (10 px short each side; cornice 9..126) |
| town_tower_corner | `generate` 136x200 (re-roll) | as above plus "very wide ... as wide as the whole canvas ... no overhang"; family ref demoted to style only ("ignore its size and proportions"), TownMap style ref dropped | 343 | 20 (528 → 508) | Rejected: body x 16..119 (12 px short each side) |

town_tower total: 60 generations (cap 70). Glow 2.3% intact, 0% damaged, 0% ruins. No collapse (engine sink). In town (main gate, side gate captures) the wall runs meet the tower faces with no ground between.

town_tower_corner: 40 generations, no candidate fills the 2.0 plot; stopped because a third generate plus two edits (60) would take the balance under the 473 floor. Interim: the corner reuses the new town_tower stills (size [120, 180], anchor [60, 178.4] = the tower's anchor + 6.4 px, shadow [1.6, 1.6]), so its corners still sit ~13 px inside the 2.0 diamond. Open. Rejected candidates kept in the session scratchpad (tower2/cgen1, tower2/cgen2).
