# KAK Town Visual Upgrade (step 1: "Town Visual Upgrade") — Design

**Date:** 2026-09-26 · **Baseline:** tag `prototype-v0.01` (= `76d3088`, milestone 6 done)

## Goal

Aldermere should look like `concepts/TOWN REF/Town Visual Upgrade.png`: the same town (layout, house count,
walls, gates, Citadel, Temple, barracks, market, river, bridge, farms) redrawn as rich, warm, dusk-lit pixel art
and filled with decor. Later steps — `Town Visual and Scale Upgrade.png` (a bigger town) and the four
`Final Town_Ref0x.png` images — are **not** part of this step. The `TownMap_Component*.png` sheets are style
references only.

User choice (2026-09-26): **Restyle + Decor**. Every component is redrawn procedurally; decor is added only where
people already cannot walk; the layout and house count stay; the only new building is a market fountain.

## Approach

Everything stays procedural in code: no PixelLab, no image assets. Buildings keep drawing with the batched primitives
the perf work settled on (`_quad` → `draw_primitive`, `draw_rect`, `width = -1` hairlines; no
`draw_colored_polygon` or `draw_circle` in per-building art, because `gl_compatibility` cannot batch them). Every
visible material goes through `Structure._face_color()` so torch light, ambient, scorch and frost apply to the new
art exactly as they do to the old boxes. Cracks, collapse, laser cuts, rubble and fire are untouched.

The per-kind art leaves `src/environment/structure.gd` (947 lines) for focused art files that draw onto the
structure. `Structure` keeps its state, damage, signatures, effects and the generic box.

## Reference palette (sampled from the reference, dusk-lit)

| Material | Colours |
|---|---|
| Plaster (houses) | lit `d9c39a`, mid `c4a97c`, shade `a88c62` |
| Timber / beams | `523a29`, dark `3a2a1e` |
| Slate roof | lit `5f6c87`, mid `566684`, dark `4f5e7e`, course line `454752`, ridge `8a93a8` |
| Red tile roof | lit `b4623c`, mid `a7512e`, dark `944729`, course `6c3a28` |
| Teal roof | lit `43949b`, mid `3e8f97`, dark `367178`, seam `2f5f64` |
| Town stone | `c6b4a3`, `bfad9f`, `9f938e`, `867d7c`, `6a6466`; mortar `55545a`; walkway `9e9692` |
| Sandstone | `d7b578`, `c19f68`, `a38352`; mortar `5d4528` |
| Banner | blue `1d479a`, dark `09389b`, cross `ddd0b6`, finial `d8b23a` |
| Portcullis | void `171210`, bars `5c4f4d` / `726361` |
| Wood (barrels, posts, planks) | `8c6036`, `6e4926`, `5b3b1f`, `462d17`, `311f0f` |
| Grass | `94923b`, `80912b`, `818732`, `697131`; forest floor `5e6d24`, `434e1e` |
| Dirt path | `bf955d`, `ba8f58`, `9d8143` |
| Cobble street | `b7a591`, `a5927e`, `98806a`; joints `514d5d` |
| Plaza | `b29f8b`, `ad9881`, `a18b73`; joints `7e695f` |
| Water | `276698`, `1f5d92`, deep `1c588d`, glint `74a2b3` |
| Wheat | `f8c44d`, `f1b843`, `e6ab3b`, `d0942e`, `a67021` |
| Crops | `7d9525`, `6e8623`, `607521`, `4f5b1e`, `41431b` |
| Pine | `45763c`, `396534`, `335a30`, `274629`, `192d1d` |
| Window glow | `ffd27a` core, `ffb45a` rim, frame = timber |

These are starting values; each phase ends with a side-by-side against the reference and the user's approval.

## Components

1. **House** (40 in town, plus the sandbox's). Plaster walls with dark timber corner posts, sill and mid beams and
   a diagonal brace per panel. A stone base course 3 px tall. A slate roof whose eaves overhang the walls by about
   0.08 units, with shingle courses every 3 px, staggered joint ticks, a lighter ridge cap, and a timber gable
   triangle on the gable face. A stone chimney with a dark red cap. Framed windows (3×3 glow, timber frame, cross
   mullion) and one plank door on a visible face. Variety comes from a hash of the seed, never from `rng`: chimney
   end, door face and position, roof shade (±1 step).
   **Barns** (`role == &"farm"` houses) get the red tile roof and wood-plank walls.
2. **Stone (CASTLE_WALL, KEEP, GATE).**
   - Big blocks in courses of 6 px with a hashed tint per block and dark mortar joints.
   - Merlons along the outer edge only, and a pale walkway top.
   - Wall pieces whose hash picks them (about 1 in 3) carry a torch on the walkway. Its flame animates on a small
     child node, the way the keep's banner already does, so the piece itself stays cached.
   - KEEP (corner towers, side towers, Citadel towers and keep): banners are blue with a white cross and gold finials.
   - GATE: a black portcullis grid in the arch.
3. **Citadel.** The same stone and banners, lit slit windows, a flag pole with a waving flag on the keep, and steps
   up to an arched door on the keep's south-west face.
4. **Temple.** Sandstone blocks and a teal seamed roof with a lighter ridge. Glowing pointed-arch windows along
   the long face. On the gable face: an arched door with two banners beside it, steps, and a small bell turret.
5. **Barracks.** An open shed: red tile roof on grey stone pillars and a dark interior with racks and tables. At the
   east end, a stone forge chimney with a glowing furnace mouth. Everything stays inside the existing footprint.
6. **Market stall.** A sloped striped awning (red/white, blue/white, cream/tan) on four posts, with a scalloped
   front edge, over a wooden counter with produce dots.
7. **Bridge.** Planks across the span, four corner posts topped with torch flames, and sagging rope rails.
8. **Farm field.** Picked by hash: golden wheat (dense vertical stalk strokes) or cabbage rows (dark-green blobs,
   yellow flower dots) on brown soil. Both have a post-and-rail fence.
9. **Tree** (the TREE structures and the decor trees share one drawing). Picked by hash:
   - an oak: a lumpy canopy of 5–7 overlapping clumps, a dark outline, lit tops;
   - a pine: 3–4 stacked tiers, dark greens.
   Built from quads and rects only.
10. **Torch.** Unchanged in behaviour, with an iron bracket look.
11. **Ground** (TownFloor):
    - organic grass patches instead of the 1-unit checker, plus a screen-space layer of tufts, flowers and pebbles;
    - winding dirt trails in the meadow and forest;
    - a tan earth town floor, irregular cobble streets and a plaza pattern in the market and Citadel court;
    - a saturated river with lighter edges and stone banks, with reeds along them.
    The whole floor is rendered **once** into a texture (a SubViewport updated once) and shown as one sprite. The
    river's glints stay a live child.

## Decor (new)

- **What it is.** `Decor` nodes: lightweight `Node2D`s in the y-sorted world. No `_process`; each redraws only on
  a light-bucket change (throttled like `Structure`) or when hit.
- **Kinds.** Barrel, crate stack, bench/table, fence run, garden plot (fenced, plants/flowers), bush, rock, oak,
  pine, lamp post (with a `QuadFx` glow like a torch's), bunting (pennants strung between two posts), scarecrow,
  signpost, reeds, flowers.
- **Placement.** `TownDecor.spots()` generates it as deterministic data from `TownLayout`:
  - Inside the walls, only on walk-grid cells that the town's structures already block (against houses, the
    Temple, the barracks and the walls).
  - Outside, only at least 1.0 unit from every road, the river's bridge approach and both exits.
  - A test enforces both rules.
- **Damage.** `EnvironmentField` keeps a decor list. `damage_radius`/`damage_lane` char decor in range, and knock
  down or remove it on a lethal amount. With no decor registered (the sandbox), behaviour is byte-identical.
- **Fountain.** A new `Structure.Kind.FOUNTAIN` (appended to the enum), role `&"decor"`, at the market
  crossroads: a round stone basin, a pillar and water. It blocks walking like any building, so people path around it.
- **Chimney smoke.** One shared node draws every standing house's smoke wisps, stepped at about 8 Hz, and a house
  that falls stops smoking.

## Constraints (behaviour gates)

- `tools/dev/state_digest.gd` output stays exactly
  `rows=19 digest=61267b7e90524d800bf1c3473a71146b blocked=000000111000000000000011000000000000000000001110000000000000 emitters=45`.
  Art variety never calls `rng` (it hashes `rng.seed`). `_build_windows()` and the number of `_windows` entries per
  structure are unchanged; the new window art reads lit flags from `_windows` by index.
- `src/fx/` does not change. The Tornado wander is still deferred.
- `bash tools/test.sh` passes, with new tests for decor placement, the fountain and digest safety.
- `--flow-test` 24/24. `--mission-test` is re-recorded once the fountain lands (the only intended pathing change).
- Perf: bench Cinderfall at `prototype-v0.01` and at the phase head in the same hour. A phase may not make it
  worse by more than measurement noise (~3 fps) without the user's say-so.
- Never commit `default_bus_layout.tres` or `captures/`. Never touch `.codex/` or `docs/HUM_Game_Design_Document_v1.docx`.

## Out of scope

Guards standing on the walls (the people system); a tavern, blacksmith or any new buildings besides the fountain
(layout); everything in the Scale step (more houses, windmill, boats, bigger map).

## Phases (each ends with before/after captures shown to the user for approval)

1. Houses and barns.
2. Stone: walls, towers, gates, Citadel.
3. Temple, barracks, stalls, bridge, fields, trees, torch.
4. Ground bake and river.
5. Decor, fountain, chimney smoke.
