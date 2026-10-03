# PixelLab town batch 2: defences, townhouses, civic, market — design

**Date:** 2026-10-03 · **Branch:** `feat/pixellab-structures` (worktree `C:\BURIN_NITRO\Godot\GIT\vfxProve-pixellab`)
**Follows:** `2026-10-02-pixellab-structures-proof-design.md` (batch 1: cottages, tavern, smithy, cathedral, Citadel) and `2026-10-03-pixellab-people-design.md`.

## Goal

Replace the next most visible procedural town components with PixelLab sprites, matching the reference sheets in
`concepts/TOWN REF/`: `TownMap_Component4.png` (town wall, towers, gatehouse, bell tower), `TownMap_Component2.png`
(market stalls), `TownMap_Component1.png` and `Final Town_Ref01-04.png` (townhouses, civic buildings, the town as a whole).
Success: in the mission and town debug, F7 shows these components in the reference's style, with intact, damaged and
ruins states and the right collapse, while gameplay stays identical.

## Decisions (user, 2026-10-03)

- **Budget:** 873 PixelLab generations left. Spend about 690 on the most visible groups. Mills, fountains, wells,
  torches, lamps, bridge, dock and all non-destructible decor wait for a top-up (batch 3).
- **Collapse:** mixed. Unique buildings get a PixelLab-generated collapse; repeated pieces (wall, towers, postern,
  stalls) use the engine's existing sink-and-squeeze.
- **Walls:** one seamless strip. Each wall piece draws its own stretch of a long wall texture.
- **Scale:** native 1:1, as batch 1.

## Scope: 15 sprite sets

| Set | Replaces (kind / role / tag) | Count in town | Footprint | Collapse |
|---|---|---|---|---|
| `town_wall` (strip) | `CASTLE_WALL` / `wall` | ~30 pieces | runs of 0.6–2.8 × 0.7 | engine |
| `town_postern` | `GATE` / `gate` / `postern` | 1 | one wall piece | engine |
| `town_tower` | `KEEP` / `tower`, 1.6 (wall and gate towers) | ~16 | 1.6 × 1.6 | engine |
| `town_tower_corner` | `KEEP` / `tower`, 2.0 | 4 | 2.0 × 2.0 | engine |
| `town_gate` | `GATE` / `gate`, main and side (`SIDE_GATE` is `MAIN_GATE` turned, so it draws mirrored) | 2 | 2.0 × 1.1 | generated |
| `townhouse_a`, `townhouse_b` | `HOUSE` / `house` / `townhouse` | ~18 | 1.3 × 0.95, either way round (mirror) | generated |
| `barn` | `HOUSE` / `farm` / no tag | 4 | 1.3 × 1.5 | generated |
| `barracks` | `BARRACKS` / `barracks` | 1 | 4.4 × 1.9 | generated |
| `workshop` | `HOUSE` / `house` / `workshop` | 1 | 2.6 × 1.5 | generated |
| `carpenter` | `HOUSE` / `house` / `carpenter` | 1 | 2.3 × 1.15 | generated |
| `bell_tower` | `KEEP` / `tower` / `bell_tower` | 1 | 1.1 × 1.1 | generated |
| `stall_red`, `stall_blue`, `stall_cream` | `MARKET_STALL` / `market`, by `art.cloth` 0/1/2 | 29 | 0.9 × 0.7 | engine |

Every set has `intact`, `damaged` and `ruins` stills. The laser cut, scorch, frost, blight tint and F7 work for all of
them through the existing `SpriteView` and shader. Exact heights and footprints come from `town_layout.gd`; the manifest
records them per set.

Out of scope: the windmill and watermill (their turning parts need idle animation), fountains, wells, torches, lamps,
bridge, dock, trees, fields and all `town_decor.gd` props.

## Engine changes

### Mapping (`SpriteArt.name_for`)

New cases, keeping the existing ones:

- `KEEP`, role `tower`: `bell_tower` for tag `bell_tower`; otherwise `town_tower_corner` when the footprint is ≥ 1.8,
  else `town_tower`.
- `GATE`, role `gate`: `town_postern` for tag `postern`; otherwise `town_gate` (the side gate draws it mirrored).
- `CASTLE_WALL`, role `wall`: `town_wall`.
- `HOUSE`, role `house`: tag `townhouse` → `townhouse_a` or `townhouse_b` by `ArtKit.hash01(seed, …)`, as the cottages
  pick their roof; tags `workshop` and `carpenter` map to their sets.
- `HOUSE`, role `farm`, no tag: `barn`. Tags `windmill` and `watermill` stay procedural.
- `BARRACKS`: `barracks`.
- `MARKET_STALL`: `stall_red`, `stall_blue` or `stall_cream` from the stall's existing `art.cloth` index, so each stall
  keeps today's colour.

Orientation: a footprint turned the other way from its sprite's draws mirrored (`scale.x = -1`), as batch 1 does.

### Wall strip

- Manifest flag `strip: true` on `town_wall`. Its stills (`intact`, `damaged`, `ruins`) are long textures of one wall
  run along the ground x axis.
- A piece's stretch is chosen by its distance along the run, from its footprint's world position, not from its index.
  Neighbouring pieces therefore read neighbouring stretches and join without a seam at any length. Runs along y use
  the strip mirrored.
- `SpriteView` draws a source region of the strip instead of a whole frame. The ground-line clip, light and molten cut
  work in that region's texture space as they do for whole frames.
- A damaged or ruined piece swaps only its own stretch to the damaged or ruins strip.
- The postern is its own set (a wall stretch with a small door), not part of the strip.

### Collapse

Sets without `collapse_frames` already fall back to the engine's gravity sink and squeeze; no new code. Generated
collapses use the batch 1 path unchanged.

### Glow and effects

- Forge glow (barracks) and torch flames painted in sprites use the existing glow rule (warm, bright pixels skip
  lighting). `tools/dev/check_sprite_glow.py` must report under 5% glowing pixels for every new sprite.
- Today's procedural flame and light nodes stay on top where they exist, as the cottages' chimney smoke does.
- The stall awning's wind ripple is lost on sprites; accepted.

### Unchanged

`Structure` state, its rng stream, hits and gameplay. The state digest stays `61267b7e90524d800bf1c3473a71146b`.

## Pipeline

Per set, as `docs/HANDOFF_pixellab.md` "A building":

1. Add the manifest entry and render its composition reference (`render_sprite_refs.gd`).
2. `generate` at the canvas size with three refs: the composition reference, a style crop from the matching reference
   sheet (`make_style_refs.py`), and the family's first approved part (the defences use `town_tower` once approved).
3. Pick a candidate that does not clip; fix its anchor (`sprite_fix.py profile`, `footprint`).
4. `edit` to damaged and ruins; `sprite_fix.py shift` the ruins onto the base.
5. Unique buildings only: `animate` damaged → ruins, 8 frames; `strip` to `collapse.png`; set `collapse_frames`.
6. Wall strip: generate a long run, then check that its two ends join (tile test) before the edits.
7. Stalls: generate `stall_red`, then `edit` it to the blue and cream awnings.

Every call (prompt, seed, cost, pick, fix) goes into `docs/pixellab_structures_log.md`.

## Order, budget and review

| Group | Sets | Budget share |
|---|---|---|
| 1. Defences | `town_tower` → `town_tower_corner` → `town_wall` → `town_gate`, `town_postern` | ~260 |
| 2. Houses | `townhouse_a`, `townhouse_b`, `barn` | ~120 |
| 3. Civic | `barracks`, `workshop`, `carpenter`, `bell_tower` | ~220 |
| 4. Market | `stall_red`, `stall_blue`, `stall_cream` | ~50 |

- After each group: stop for the user's in-game review (F7), then commit and push that group.
- A set whose picks fail review after it has used its share stays procedural; it is logged and listed as open.
- Leftover budget stays unspent unless the user directs it.

## Testing

- `tests/test_sprite_art.gd`: one check per new mapping (each kind/role/tag/size case above, including the stall
  colours and the windmill/watermill staying procedural), and strip-offset checks: two adjacent wall pieces read
  adjacent regions, and a mirrored run reads the mirrored strip.
- `bash tools/test.sh`: `checks` ≥ 1333 plus the new ones, `failures=0`, no `SCRIPT ERROR` in the output.
- `tools/dev/state_digest.gd`: unchanged digest.
- `tools/dev/check_sprite_glow.py`: every new sprite under 5%.
- `tools/dev/sprite_states.gd`: a capture of every new set through its states, for the user's review.
- Mission bench (`tools/capture.sh --bench`) once per group: fps within noise of the procedural art, draw calls not
  above it.

## Laptop notes

`GODOT` is set to `C:/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`; Python 3.12 + Pillow and the PixelLab
key are set up. The `Kak v0.08` session's clone `C:\BURIN_NITRO\Godot\GIT\vfxProve` is not touched.
