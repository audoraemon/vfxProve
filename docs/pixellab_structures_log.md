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

town_wall total: 80 generations (773 → 693), at its cap; no seam inpaint was needed. Strip: u0 = (41, 83) (the front edge of the run at x = 41, inside the left end's outline; front corner of the run at (147, 136)), period 1.5 (48 px, about three merlon pitches, chosen by matching columns 41.. against 89.. shifted 24 down and keeping the torch out of the repeated band), span 2.7. `sprite_fix.py tile` on all three runs: size [152, 172], anchor [127.4, 126.2], footprint [2.7, 0.7], period 1.5. Glow 0% on the stills (runs 0.1-0.2%). In town (main gate, side gate captures) the south and east walls join without jogs; the y-runs read mirrored.

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

town_tower_corner: 40 generations, no candidate fills the 2.0 plot; stopped because a third generate plus two edits (60) would take the balance under the 473 floor. Interim: the corner reuses the new town_tower stills (size [120, 180], anchor [60, 178.4] = the tower's anchor + 6.4 px, shadow [1.6, 1.6]), so its corners still sit ~13 px inside the 2.0 diamond. Superseded: the corner was regenerated at 2.0 in Task 6b (see below). Rejected candidates kept in the session scratchpad (tower2/cgen1, tower2/cgen2).

Corner, second attempt (controller ruling, floor 443): composition ref rendered on a 140x156 canvas at height 60 (squat full-footprint block, bbox 6..134), only that ref plus the Component4 style ref, no family ref.

| Set | Call | Prompt / refs | Seed | Cost | Result |
|---|---|---|---|---|---|
| town_tower_corner | `generate` 140x156 | wide square corner bastion, broad, massive and squat, as wide as it is tall, walls flush with the footprint edges, cool grey limestone blocks, crenellations, two torches, blue fleur-de-lis banners, small arched windows, moss; refs: reference.png (2.0 squat block), style_ref.png (TownMap_Component4 tower) | 344 | 25 (508 → 483) | 4 images, all with body outline x 7..132 (outer edges 7/133) vs diamond 6..134 at anchor x 70: base corners 1 px inside. Kept #00 (two torches, moss like town_tower). Touched canvas top/bottom: padded to 148x168 (+4, +4). Anchor [74, 157] from overlays |
| town_tower_corner | `edit` (damaged) on intact | the same wide bastion damaged: cracks, missing blocks, broken merlons, scorch, torn banners, torches out | 345 | 20 (483 → 463) | Kept edit_00; came back 4 px low (whole sprite), moved (0, -4); a 2 px smoke wisp on row 0..1 cleared |
| town_tower_corner | `edit` (ruins) on damaged | destroyed: short wall stumps on the same wide base, rubble heap, banner on the rubble, nothing floating | 346 | 20 (463 → 443) | Kept edit_00; lowest row 115 vs 159, moved (0, +44) |

town_tower_corner total: 105 generations over both attempts (548 → 443). Manifest: size [148, 168], height 50, anchor [74, 157], no shadow. Glow 0.3% / 0% / 0%. New capture shots town_corner_south.png and town_corner_east.png (town_debug.gd TOWN_SHOTS): both walls meet the bastion's faces with no ground between.

### Fix: one stone colour for the defences

0 generations (local recolour, no PixelLab calls). The user saw the walls, towers and gate in town not matching in colour and mood and chose the grey limestone of concepts/TOWN REF/TownMap_Component4.png. New `sprite_fix.py harmonize <target> <box|all> <png> [...]` (and `stonemean`): stone pixels are the low-chroma ones (neutral greys; slate hues 150..290 up to chroma 18; light warm limestone up to chroma 24), with transparent, outline-dark (L < 14), banners, fire, torch light, moss and wood left exactly as they were (soft 4-unit fade at the edges of the mask). Their Lab mean is moved onto the target's, chroma spread matched (gain 0.5..2), lightness spread scaled 0.75..1.25, so each pixel keeps its light-dark order. The first png of a call sets the source statistics, so damaged and ruins keep their scorch relative to intact. Alpha untouched on all stills.

Target: the TownMap_Component4 wall box (310,66,535,250), stone Lab (47.4, 4.4, 3.6), mean RGB about (123, 111, 107): a warm-leaning grey limestone; the tower box gives a near-identical hue but lighter (138, 121, 113) because torch light spills over it. town_tower intact was not used: its slate is blue (Lab a -2.1, b -6.5).

Applied per set (intact first): town_tower, town_tower_corner, town_gate, and town_wall's run_intact/run_damaged/run_ruins, then the strip re-tiled with `tile ... 41,83 1.5 2.7` (re-tiling the old runs with these values reproduces the old stills pixel for pixel; new output size [152, 172], anchor [127.4, 126.2], as in the manifest). town_postern copies town_wall's stills byte for byte.

Stone mean RGB (intact) before → after: town_tower (103, 115, 124) → (120, 109, 107); town_tower_corner (134, 126, 125) → (124, 113, 111); town_wall (119, 110, 107) → (118, 107, 105); town_gate (126, 113, 108) → (122, 110, 106). Max pairwise distance intact 33.2 → 10.7, damaged 26.0 → 4.7, ruins 24.0 → 16.7 (ruins keep their own rubble/scorch mix). Glow unchanged: town_tower 2.3%, corner 0.3%, gate 3.3% / 2.2%, walls 0%. Tests 1387 checks 0 failures; digest unchanged. Captures: main gate, side gate, corner south/east now read as one castle in one warm-grey stone.

### Fix: a taller gatehouse

User review 2: the gatehouse (~34 px of wall) looked tiny between the regenerated towers. Regenerated `town_gate` taller, filling its 2.0 x 1.1 plot. Composition ref: `render_sprite_refs.gd` with the manifest temporarily at size [112, 152], height 68 (a plain full-footprint block, bbox 6..105 = the diamond at the default anchor [70, 142], walls ~76 px incl. merlons); height put back to 34 afterwards (the Structure's own height, gameplay unchanged). reference.png = that render.

| Set | Call | Prompt / refs | Seed | Cost | Result |
|---|---|---|---|---|---|
| town_gate | `generate` 112x152 | tall massive medieval stone gatehouse, one solid rectangular block of grey limestone; long left face with a big round-arched gateway, raised iron portcullis, two open wooden doors, a torch either side, blue fleur-de-lis banner above the arch; crenellated walkway along the whole top; both short end walls flat and full height; no towers; refs: reference.png (tall full-footprint block), style_ref.png (TownMap_Component4 gate), town_tower/intact.png (stone/merlons only) | 441 | 25 (443 → 418) | 4 images, same shape (00/01 grey, 02 slate, 03 pink). All ~0.88x the block: base x 14..98 vs diamond 6..105 (long side 56 px of 64, short side 28 of 35). Kept #00. Fitted locally (0 gens) by isometric strip duplication, no resampling: long axis +6 px (cut at the front corner x 70, the strip of plain wall/torch glow x 64..69 repeated, back of the roof moved along the axis), short axis +6 px (cut x 84 on the plain right face, roof line through (84, 56)): one merlon a little wider at the front corner, back parapet slightly denser. Base now x 8..105, front corner (70, 131) |
| town_gate | `edit` (damaged) on intact | battle damage: cracked/missing blocks, broken merlons, scorch, torn banner, torches out and smoking, a door hanging broken; same size and position | 442 | 20 (418 → 398) | 2 near-identical images; kept edit_00. Came back (+4, +3): moved (-4, -3); a smoke wisp at x < 7 cleared (it ran off the canvas edge). Silhouette then matches intact |
| town_gate | `edit` (ruins) on damaged | destroyed: short wall stumps on the same base, arch collapsed, rubble heap, broken door and torn banner on the rubble, nothing floating | 443 | 20 (398 → 378) | 2 identical images; the stumps came back on a squarer base filling the whole 112 px canvas (front corner (60, 117), short side 52 px). Fitted locally: short axis -16 px (slab of rubble/stump dropped beyond x 84 / roof line through (84, 94)), moved (+10, +14), long axis +4 px (cut x 36). Base x 6..105, front corner (70, 131) |

town_gate total: 65 generations (443 → 378; floor 373). Manifest: size [112, 152], anchor [70, 131] (overlays at y 129/131/133; 131 puts the diamond on the base: left corner art (8, 101) vs diamond (6, 99), right (105, 114) vs (105.2, 113.4), front (70, 131) on the anchor). Height: merlon top at the left/right ends 71 / 68 px above the base, sprite top 117 px above the anchor (town_tower: 168 → 0.70; wall faces 71 vs the tower's ~120 → 0.59). **Walkway (parapet walk, the crenel floor) ~62 px above the base** (merlons ~9 px tall above it). Stone: `harmonize "concepts/TOWN REF/TownMap_Component4.png" 310,66,535,250` on intact; damaged and ruins harmonized each on their own statistics (the edits came back darker, and with intact's statistics they went brown, (103, 92, 85)): stone mean RGB intact (137, 128, 127) → (126, 114, 111), damaged (118, 110, 107) → (123, 110, 107), ruins (115, 107, 102) → (123, 111, 107). Glow 0.2% / 0% / 0%. No collapse (engine sink). Captures: main and side gate show a substantial gatehouse between the towers, its walkway ends meeting the tower faces.

### Fix: walkway doors

User review: a wall walk ended against a blank tower face ("like a dead end"). The reference (TownMap_Component4) has dark arched doorways where a wall meets a tower. A tower shows its south side (left face) and east side (right face); `TownLayout.door_tag` names which of those a wall run / the postern (LOW) or a gatehouse (HIGH) meets, and SpriteArt maps the tag to a doored variant (`door_e_s` -> `town_tower_corner_e_s`; a missing variant falls back to the plain set).

Before inpainting, the banner and window on the door faces were patched out locally (0 gens; best-matching offset copy of the same face's stone, scratchpad doors/doors.py `clean`), so a door face carries no banner through its doorway.

| Set | Call | Prompt | Seed | Cost | Result |
|---|---|---|---|---|---|
| town_tower | `inpaint` the cleaned intact, mask = 4 arched door shapes (16 x ~24 px) centred on both faces, bottoms 38 and 62 px above the face's ground line | dark arched stone doorways in a pale grey stone castle tower wall, deep black shadowed opening with a stone arch frame, opening onto the wall walk; same stone blocks, same lighting, same pixel art style | 601 | 20 (378 → 358) | 2 identical images; 4 dark arched openings with a lit sill, 1097 px changed (3 outside the mask). Kept |
| town_tower_corner | `inpaint` the cleaned intact, 2 LOW door masks | same | 602 | 20 (358 → 338) | 2 identical images; 2 dark openings under a pale stone voussoir arch. Kept |

Variants composited locally (0 gens): plain still + the door face's cleaned banner/window boxes + the door patch (the inpaint mask's pixels). Damaged: the same over the plain damaged still, the patch's stone shifted by the mean change of the stone round it (scorch/dust). Ruins: the plain ruins. LOW doors moved up 10 px (tower: two 5 px courses) / 9 px (corner) after the first capture showed the wall's merlons covering all but the arch tops: in town the walk lands ~47 px up the tower face, not the 38 px measured on the wall strip. Sets (manifest entries copy the base, with the tag): town_tower_e, _s, _e_hi, _s_hi; town_tower_corner_e, _s, _e_s. town_tower / town_tower_corner stay for towers joined on no visible face (the SE corner). No harmonize needed (the patches are the image's own stone). Glow: tower variants 2.3% (the brazier, as the base), corner 0.2%, damaged/ruins 0%.

Doors total: 40 generations (378 → 338; floor 318).

### Townhouses (townhouse_a, townhouse_b)

Two-storey townhouses (~18 in town, footprint 1.3 x 0.95, tag townhouse; `SpriteArt.name_for` picks a or b by the structure's seed, deep plots draw it mirrored). Style ref: the two-storey timber-framed house with dormers on TownMap_Component1.png, box (720, 15, 1050, 270) (`make_style_refs.py`). Composition ref: `render_sprite_refs.gd` at size [88, 104], height 30 (diamond left corner = anchor x - 32 * 1.3: the long side runs to the left). Balance before: 338 (floor for the task 268).

| Set | Call | Prompt / refs | Seed | Cost | Result |
|---|---|---|---|---|---|
| townhouse_a | `generate` 88x104 | isometric pixel art medieval two-storey townhouse, timber-framed cream plaster upper floor over stone ground floor, steep red clay tile roof, chimney, warm lit windows with shutters, wooden door, high detail, crisp dark outline, no ground, transparent background; refs: reference.png ("walls stand exactly on this footprint's edges, same base width, fill the whole footprint"), style_ref.png (art style only), cottage_red/intact.png (plaster, timber, roof tiles: materials and colours only) | 46 | 20 (338 → 318) | 4 images, all ~0.8 x 0.8 squares with the gable on the LEFT face (left face 24-26 px, right 25-28 px vs the plot's 41.6 / 30.4). #00/#01 sat 10-15 px high. Kept #02 (stone ground floor, shutters, jettied timber upper floor, chimney) and fitted locally (below) |
| townhouse_a | `edit` (damaged) on intact | the same townhouse damaged: cracked plaster, broken roof tiles, a hole in the roof, scorch marks, a broken window; same size and position on the canvas | 461 | 20 (318 → 298) | 2 near-identical images on the same bbox; kept edit_00 (roof hole, broken/dark windows, cracks, a few tile fragments at the front-left foot) |
| townhouse_a | `edit` (ruins) on damaged | the same townhouse collapsed into a heap of rubble, broken tiles and charred beams, two short wall stumps, same footprint, same position on the canvas, nothing floating | 462 | 20 (298 → 278) | 2 identical images; heap 13 px high (lowest row 77 vs 90): moved (0, +13). The heap spreads a few px past the side corners (gable stumps at both ends) |
| townhouse_a | `animate` (collapse) damaged → ruins, 8 frames | the building crumbles from the top down into a heap of rubble, dust; it is never repaired | 463 | 2 (278 → 276) | 9 frames; frames 1-6 drift down 1-3 px (whole house): moved up by 1, 2, 2, 3, 3, 3 so the base stays put. No healing (the roof hole fills with falling beams in frame 6, then the heap) |

Local fit of the intact (0 gens, native scale, no resampling; scratchpad townhouse/{chim,wstretch,rakefix}.py and gate2/stretch.py):
1. Mirrored #02 so the long eave wall faces left (the plot's long axis) and the gable faces right.
2. Lifted the chimney off the roof (roof refilled from the same 2:1 tile row 12 px along), so it is not cut by the stretch.
3. Long axis +16 px: canvas padded (+4, +4); cut on the left face at x 43 (strip x 27..42 repeated: an upper window bay and a ground-floor window, plus the edge of the door -> ground floor reads door, window, door, window) and on the roof along a line 2 px inside the front rake.
4. Short axis +6 px: `stretch.py d` with the cut at x 52 on the gable face (strip of plaster/brace and stone repeated) and on the roof along a line parallel to the eave (a 3 px band of tiles repeated); ridge, chimney and back corner move rigidly. A 6 px ledge where the cut met the back rake was smoothed by hand (rows 24-29).
5. Chimney pasted back at (+2, -3) on the stretched roof; canvas cropped to 96 x 104.

Fit (anchor [49, 90], overlays at y 88/90/92: 90 sits the diamond on the base): diamond left corner (7.4, 69.2) vs art (7, 69): 0.4 px; right corner (79.4, 74.8) vs art (80, 75): 0.6 px; front corner (49, 90) on the base outline (x 48-51). Chimney top [44, 7].

townhouse_b (0 gens): townhouse_a's stills and collapse recoloured locally with the new `sprite_fix.py huemap`: tile-roof pixels (hue 0-24, saturation >= 0.4, inside the roof polygon (20,2)(72,28)(54,60)(1,33), chimney box skipped) take the nearest-lightness colour of cottage_blue's slate roof palette (its intact box 30,0,84,40, hues 190-250, 10 colours), lightness mapped linearly from 0.149..0.476 onto the palette's range; a second pass catches 4 light orange tile specks (hue 25-30). Rubble (ruins, collapse frames 7-8) and the damaged still's loose tile fragments: same mapping on the whole image (hue 0-19, saturation >= 0.45). Brick chimney, timber, plaster, stone and windows unchanged. Same size, anchor, collapse_frames and chimney as townhouse_a; seed 47.

Manifest: size [96, 104], footprint [1.3, 0.95], height 30, anchor [49, 90], collapse_frames 9, chimney [44, 7] for both. reference.png = render at the final size. Glow: intact 0.9%, damaged/ruins/collapse 0% (both). Captures: town_crowd/town_bell_tower show both roofs in the default orientation next to the cottages; town_citadel shows a mirrored (deep) townhouse_b.

Townhouses total: 62 generations (338 → 276).

### Barracks

One long open-sided hall (footprint 4.4 x 1.9, beside the side gate; the soldiers drill in its yard). Style ref: Final Town_Ref01.png, the long timber-framed hall with the lit open front in the barracks yard, box (38, 156, 135, 232) (an opaque sheet, so the crop keeps some yard ground). Family ref: townhouse_a/intact.png rather than town_tower: the barracks is a timber-and-tile building, so the house gives the town's exact roof red and timber; the town_tower ref has pulled shapes narrower before (Task 6b). Its stone footings were harmonized to the town stone afterwards. Composition ref: `render_sprite_refs.gd` at size [232, 172] (216 clipped the eaves), height 36. Balance before: 276 (floor 206).

| Set | Call | Prompt / refs | Seed | Cost | Result |
|---|---|---|---|---|---|
| barracks | `generate` 232x172 | isometric pixel art medieval soldiers' barracks, a long open-sided timber hall on low grey stone footings, its long side facing left along the whole length of the footprint, red clay tile roof, weapon racks with spears and shields under the roof, a small forge glowing orange at the right end, a blue fleur-de-lis banner, high detail, crisp dark outline, no ground, transparent background; refs: reference.png (fill the whole footprint), style_ref.png (art style only), townhouse_a/intact.png (roof tiles, timber, plaster: materials and colours only) | 49 | 20 (276 → 256) | 1 image, kept: open hall on stone post pads, cross gable with the banner, racks, benches, barrels, hay, a stone forge with a fire under the right gable, chimney. Base corners (pad outer vertices) left (17, 90), front (152.5, 156), right (217, 121): long side 135.5 px of 140.8, short side 64.5 of 60.8, so the corners sat ~4.5 px off the diamond vertically. Fitted locally (below) |
| barracks | `edit` (damaged) on intact | the same barracks damaged: broken roof tiles and a hole in the roof, snapped posts, scorch marks, a torn banner, weapon racks knocked over, forge out and cold; same size and position on the canvas | 491 | 20 (256 → 236) | 2 near-identical images on the intact's bbox; kept edit_00 (two roof holes, scorch, racks down, debris, forge cold). No shift |
| barracks | `edit` (ruins) on damaged | the same barracks collapsed into a long low heap of charred timber, broken red roof tiles and fallen weapon racks, a few snapped post stumps on their stone footings, the cold forge as a pile of stones, same footprint, same position on the canvas, nothing floating | 492 | 20 (236 → 216) | 2 identical images; heap came back 50 px high (lowest row 110 vs 160): moved (0, +50). Post stumps then stand on the intact's pads |
| barracks | `animate` (collapse) damaged → ruins, 8 frames | the building crumbles from the top down into a heap of rubble, dust; it is never repaired | 493 | 5 (216 → 211) | 9 frames (745 s job), every frame on the same base (lowest row 160, front x 152-153); the roof sinks steadily, no healing. Kept as is |

Local fit of the intact (0 gens, native scale, pixel copy only; scratchpad barracks/{lstretch,rshrink2}.py):
1. Canvas padded 8 px on top (232 x 180).
2. Long axis +6 px: cut at x 40 on the left face (first bay: a weapon rack, so the bay reads one more spear) and on the roof along a line parallel to the left-end rake (37 across per 35 up); the left end moves (-6, -3).
3. Short axis -4 px at the right gable end: for x >= 207 the source is x + 4; roof/eave rows (src y <= 85) move along the eave (-4, -2) so the roof tip stays continuous, the post, wall and floor move along the short axis (-4, +2) so the floor edge stays continuous, the 4 rows between repeat the post top. A bucket now stands half behind the right post pad.
4. Cropped the 4 empty top rows: 232 x 176.

Stone: `harmonize "concepts/TOWN REF/TownMap_Component4.png" 310,66,535,250` on a copy of the intact holding only pixels with Lab L < 74 (the cream plaster, which the warm-limestone rule would also catch, left out), merged back: footings, forge and chimney stone (103, 98, 86) → (122, 110, 105); timber, roof, plaster, banner, fire untouched. Damaged and ruins came from the harmonized intact and were not re-harmonized (their low-chroma mean is darker, ~(92, 82, 74), from scorch and charred timber, not from the stone).

Fit (anchor [152, 159.5]; diamond left = ax - 32 * 4.4, the long side runs left): left corner diamond (11.2, 89.1) vs art (11, 91): 0.2 / 1.9 px; front (152, 159.5) vs art (152.5, 160): 0.5 / 0.5; right (212.8, 129.1) vs art (213, 127): 0.2 / 2.1. Same for damaged, ruins and every collapse frame (same pads).

Manifest: size [232, 176], footprint [4.4, 1.9], height 36, seed 49, anchor [152, 159.5], collapse_frames 9. reference.png = render at the final size. Glow: intact 0.1% (forge), damaged 0%, ruins 0.2%, collapse 0%. Captures: town_side_gate shows the hall behind the gatehouse with the soldiers drilling in front; town_overview shows it on its plot by the side gate.

Barracks total: 65 generations (276 → 211).

### Workshop

One open-sided craft hall (footprint 2.6 x 1.5, height 22, seed 50, tag workshop; east quarter beside the smithy and the barracks). Carpenter moved to batch 3 (controller ruling), so this task made the workshop only. Style ref: TownMap_Component1.png, the open-sided timber hall with the red tile roof (middle right), box (1085, 300, 1430, 555) (its yard ground comes along). Family ref: smithy/intact.png, used for stone footings, timber and outline only (its roof is slate; the prompt and ref note ask for red clay tile). Composition ref: `render_sprite_refs.gd` at size [164, 128] (148 x 124 clipped). Balance before: 211 (floor 146).

| Set | Call | Prompt / refs | Seed | Cost | Result |
|---|---|---|---|---|---|
| workshop | `generate` 164x128 | isometric pixel art medieval craft workshop, an open-sided timber pavilion on low grey stone footings, filling the whole footprint, red clay tile roof, workbenches with tools, crates and barrels inside, high detail, crisp dark outline, no ground, transparent background; refs: reference.png (exact footprint, fill the whole footprint), style_ref.png (art style only), smithy/intact.png (stone footings, timber, outline: materials and colours only; this roof is red clay tile) | 50 | 25 (211 → 186) | 4 images, all the same shape: a square (~2.0 x 2.0) pavilion with an L-shaped roof wrapping the two back sides round an open front courtyard, grey footings. 00 crates/carpentry, 01 anvil (too close to the smithy), 02 leather/tailor (tables, hung hides), 03 potter with a lit kiln (glow). Picked 02. Base corners left (17, 86), front (81.5, 117.5), right (146, 85): 64.5 px each side vs the plot's 83.2 (long, left) and 48 (short, right). Fitted locally (below) |
| workshop | `edit` (damaged) on intact | the same open craft workshop damaged: broken red roof tiles and a hole in the roof, a snapped post, scorch marks, workbenches overturned, hides torn down; same size and position on the canvas | 501 | 20 (186 → 166) | 2 near-identical images on the intact's bbox; kept edit_00 (three roof holes, scorch, left post snapped, debris). No shift |
| workshop | `edit` (ruins) on damaged | the same workshop collapsed into a long low heap of charred timber, broken red roof tiles and smashed workbenches, a few snapped post stumps on their grey stone footings, same footprint, same position on the canvas, nothing floating | 502 | 20 (166 → 146) | 2 near-identical images; heap came back 13 px high and 1 px left (lowest row 104 vs 117): moved (+1, +13). Stumps then stand on the intact's footings |

No collapse animation: the generate cost 25 (not 20), so generate + two edits used the whole 65 and an `animate` (2-5) would have crossed the floor. The set has no `collapse_frames`; it falls with the engine's fallback like the sets without a collapse strip.

Local fit of the intact (0 gens, native scale, pixel copy only; scratchpad workshop/fit.py). The roof is two gable wings (left wing along the back-left side, ridge along the short axis; right wing along the back-right side, ridge along the long axis) meeting in a valley, so each axis has a wing that is invariant along it:
1. Short axis -16 px: output pixels right of a cut through the left wing (ridge (28,42) → eave (50,58) → down x 50 to the floor → along the floor (2,1) to the front-right edge at (92,112)) take the source moved (-16, +8); the 16 px slab of left wing and courtyard beside the cut is dropped. The right wing, the mid-right post and the right corner post move with it.
2. Long axis +18 px: output pixels left of a cut through the right wing (x 98 down to its ridge at y 26 → its eave at (76,62) → down x 76 to the floor → along the floor (-2,1) to the front-left edge at (65.6,109)) take the step-1 result moved (-18, -9); the 18 px strip right of the cut shows twice (a second work table and hide). The cut crosses the ridge where it runs straight along the long axis (x >= 96) and stays left of the mid-right post, so no post is duplicated.
3. Shifted 16 px right on the 164 x 128 canvas.

Stone: `harmonize "concepts/TOWN REF/TownMap_Component4.png" 310,66,535,250` on a copy holding only the cool stone (Lab hue 150..290 or chroma <= 3, chroma <= 18, L >= 14: footings and the back stone walls; the tan floor, hides, timber and roof left out), merged back: (104, 105, 106) → (124, 111, 107). Damaged and ruins came from the harmonized intact.

Fit (anchor [98, 117.5]; diamond left = ax - 32 * 2.6, the long side runs left): left corner diamond (14.8, 75.9) vs art (14, 76): 0.8 / 0.1 px; front (98, 117.5) vs art (97.5, 117): 0.5 / 0.5; right (146, 93.5) vs art (145, 93): 1 / 0.5. Lower edges within 1.5 px of the diamond along both sides. Damaged and ruins (after the shift) sit on the same base (lowest row 117, front x 96-97).

Manifest: size [164, 128], footprint [2.6, 1.5], height 22, seed 50, anchor [98, 117.5], no collapse_frames, no chimney (an open pavilion: it does not smoke; tests/test_town_decor.gd now counts only houses with a chimney). reference.png = render at the final size. Glow: intact, damaged, ruins 0%. Captures: captures/sprite_states/workshop.png; new shot town_east_quarter.png (town_debug.gd TOWN_SHOTS, dev-only) shows the hall on its plot between the barracks and the smithy.

Workshop total: 65 generations (211 → 146).

### Market stalls (stall_red, stall_blue, stall_cream)

29 stalls in the market square (footprint 0.9 x 0.7, height 10). Each keeps today's awning: PropArt cloth = seed % 3 → stall_red / stall_blue / stall_cream (SpriteArt.STALLS). Style ref: TownMap_Component2.png, red-and-white stall, box (10, 20, 155, 165). Composition ref: `render_sprite_refs.gd` at [68, 72]. Balance before: 146 (floor 81). No collapse for any of them (the engine's sink, by ruling).

| Set | Call | Prompt / refs | Seed | Cost | Result |
|---|---|---|---|---|---|
| stall_red | `generate` 68x72 | isometric pixel art medieval market stall, red and white striped scalloped awning on four wooden posts, a wooden counter heaped with fruit and vegetables in baskets, high detail, crisp dark outline, no ground, transparent background; refs: reference.png (exact footprint …), style_ref.png (art style only) | 3 | 25 (146 → 121) | 16 images, all bigger than the reference (~64 x 65 vs 58 x 52, several touch the canvas edge), long side running RIGHT from a front post at x ~21 (posts 37 px right / 15 px left vs the plot's 28.8 left / 22.4 right), a row of produce baskets in front. Picked 09 (pears, apples, oranges: reads at 1x). Fitted locally (below) |
| stall_red | `edit` (damaged) on intact | the same stall damaged: torn awning, a snapped post, spilled produce | 31 | 20 (121 → 101) | 2 near-identical images on the intact's bbox: hole torn in the awning, pears and an orange spilled on the ground (no snapped post). Kept edit_00, no shift |
| stall_red | `edit` (ruins) on damaged | the same stall collapsed: the awning fallen over a heap of broken planks and spilled baskets, same footprint | 32 | 20 (101 → 81) | 2 images, NOT collapsed: the awning still stands on its posts, broken planks added round the baskets. Floor reached, so the ruins were made locally from edit_01 (below) |

Local fit of the intact (0 gens, native scale, pixel copy only; scratchpad stalls/fit.py, `fit.py generate_09.png intact.png 10 5 4 0`):
1. Awning cut out by a hand polygon; the rest (posts, counter, produce) is the ground layer.
2. Ground, long axis -10 px: pixels right of a cut (x 29.5 down to the counter's back edge (29.5, 44.5), along the ground (2,1) to the front edge (44.5, 52.5), then down) take the source moved (-10, +5); the 10 px slab is dropped (part of the back produce).
3. Awning: three cuts parallel to the stripes (x = x0 + 1.2 (y - 20), x0 44 / 33.5 / 23.5, inside the three wide stripes), each moving the part right of it (-2, +1): stripes come out 6-8 px wide, the back and front edges stay straight.
4. Awning dropped 5 px over the ground layer (shorter posts: 65 → 58 px tall overall, the old procedural stall is 52; width 57 vs 58).
5. Mirrored (the plot's long side runs left) and moved 4 px left on the 68 x 72 canvas.

Fit (anchor [41, 65]; the long side runs left): the front post stands at (41.5, 64) on the diamond's front corner; back-left post (14.5, ~51) vs the left corner (12.2, 50.6); the produce baskets reach x 9 (left) and x 63 (right corner 63.4). The front row of baskets hangs ~7 px in front of the front-left edge (lowest row 66 at x 25-33), like the procedural stall's basket and crate.

Ruins (0 gens; scratchpad stalls/ruins.py, `ruins.py ruin/edit_01.png awnmask.png ruins.png 16 8 44`): the awning (its pixels in edit_01 under the intact's awning mask) lifted off and dropped 16 px onto the heap, its left end 8 px more (column-wise shift: tilted), the uncovered old awning area cleared, and ground pixels above row 44 (the post tops) cleared: the awning lies over the broken planks and baskets. Same canvas and base as the intact (lowest row 69 = the spilled fruit, as in damaged).

stall_blue (seed 4) and stall_cream (seed 5), 0 gens: the stall_red stills with only the awning's red recoloured, `sprite_fix.py huemap <red still> <dst> 345,22 <ramp> 0,0,12,1 minsat=0.3 lrange=0.125,0.520 mask=<awning mask>` (huemap gained hue wrap, h0 > h1, and `mask=`). Ramps are 12-step HSL swatches at the procedural cloth hues: blue hsl(220, 0.60, 0.12..0.56) (CLOTH 2f5fb8 = hsl(220, 0.59, 0.45); the Component2 blue stall averages (18, 92, 198)), tan hsl(36, 0.40, 0.16..0.62) (CLOTH c0a070). White/cream stripes, produce and wood untouched, so blue = blue and white, cream = cream and tan. Masks: intact = fit.py's awning mask; damaged = the same dilated 1 px, plus a second pass in poly 57,14..67,32 for the torn right edge (11 px); ruins = ruins.py's fallen-awning mask dilated 1 px. Same size and anchor as stall_red.

Manifest (all three): size [68, 72], footprint [0.9, 0.7], height 10, role market, anchor [41, 65], seeds 3 / 4 / 5, no collapse_frames. Glow: intact 0.5%, damaged 0.6%, ruins 1.0% (all three). Captures: captures/sprite_states/stall_{red,blue,cream}.png; captures/town_market.png and town_crowd.png show the three colours in orderly rows on their plots.

Market stalls total: 65 generations (146 → 81).
