# Set2 Fantasy Skill VFX — Design

Date: 2026-09-16
Status: Approved decisions (setting, creatures, review pace); per-effect details reviewed one effect at a time.

## Goal

Build the seven KWAI fantasy skill concepts in `concepts/Set2/` as real-time effects in the existing sandbox, matching each sheet's five stages, component breakdown and gameplay feel, at the same quality bar as Set1 (impact kit, lighting, destruction, synthesized audio).

## Decisions

- **Setting:** a second, fantasy map. Stone paving with grass and dirt, castle walls, towers and a keep that can be destroyed, torches that light the scene, and a horde of armored enemies. Set1 keeps the sci-fi city. `Tab` switches effect set, and the map switches with it.
- **Creatures:** procedural. The golem is built from lit stone blocks and animated in code; the dragon is built from chained flame-scale segments with a fire shader. No external art.
- **Review pace:** one effect at a time, in this order: Glacial Cataclysm → Heaven Splitter → Cinderfall Barrage → Tsunami Breaker → Tornado Tempest → Judgement of the Ancients → Dragonfire Parade.

## Shared additions

| Piece | Purpose |
|---|---|
| Effect sets | `EFFECT_SETS` in sandbox: Set1 sci-fi (4), Set2 fantasy (7); keys `1`–`7`, `Tab` switches set and rebuilds the map |
| Fantasy ground | `ground_tiles.gd` theme: warm stone flags, mortar, moss and dirt patches |
| Fantasy structures | New `Structure.Kind`s: `KEEP` (tower with crenellations, banners, lit slit windows), `CASTLE_WALL` (crenellated), `HOUSE` (timber walls, pitched roof), `TORCH` (post with a flame that lights the scene via `LightField`). `EnvironmentField.build_castle()` layout |
| Fantasy enemies | `DummyEnemy.skin`: `TROOPER` (sci-fi), `ORC` (red/dark armored horde) |
| Status: frozen | `DummyEnemy.freeze(seconds)`: ice shell overlay, no movement or pull, thaws; `die(&"ice")` shatters into shards. `EnemyField.freeze_radius(center, r, seconds)` |
| Palettes | `ICE`, `ICE_LIFE` ramps in `FxParts` |

## Glacial Cataclysm (~10 s, radius 5)

| Stage | Time | Visual | Gameplay |
|---|---|---|---|
| Telegraph | 0–1.2 | Pale-blue frost rune (rings + six-arm snowflake + rune ticks) on the ground, cold mist ring rolling inward, snow motes rising, world dims cold | none |
| Ice eruption | 1.2–2.2 | Ice spike clusters burst up from center outward with overshoot, ground cracks, flying ice shards, impact frame (white/navy), hit-stop, shake | enemies within 1.4 killed (shatter); structures within 1.4 destroyed |
| Radius freeze | 2.2–3.2 | Radial frost wave expands to radius 5, frozen-ground decal spreads with it, snow spray | enemies reached by the wave are frozen (ice shell) for 6 s; structures reached get frost-coated and damaged |
| Crystal peak | 3.2–4.6 | Central crystal mountain surges to full height, brilliant white-blue bloom, light rays, second shard burst, blue light on buildings | frozen enemies within 2.5 shatter |
| Aftermath | 4.6–10 | Outer spikes crack and shatter into shards, crystal residue remains and fades, icy fog, drifting snow, frozen ground slowly fades | outer enemies stay frozen until thaw |

Components (from sheet): frost warning rune, cold mist ring, ice spike cluster, central spike mountain, shard burst, radial frost wave, freeze overlay, snow particle spray, frost decals, frozen ground decal, icy fog, crystal residue.

Rendering:
- `IceSpike` (y-sorted world node): faceted crystal. Left face darker, right face lighter, translucent lower band, bright facet edge, inner crack lines, grow with overshoot, shatter.
- `shaders/frost_ground.gdshader`: radial reveal, ice plates with bright cracks, sparkle, dithered edge.
- Reused: iso_rings (rune), shockwave (ICE ramp), fog (icy fog / mist), light_glow, god_rays, bloom, impact kit, `PixelParticles` (shards as STREAK, snow as SQUARE).

Audio cues: `glac_rune` (chime shimmer + wind), `glac_erupt` (crystal crunch + deep boom), `glac_freeze` (crackling freeze sweep), `glac_peak` (resonant crystal chord + boom), `glac_wind` (loop, cold wind), `glac_shatter_1..3` (glass shatter).

## Remaining effects (detailed when reached)

- **Heaven Splitter:** line telegraph and storm sigil → sky lightning column → 8 radial magma fissures → lightning erupts from fissures → scorched cracks, residual arcs, smoke.
- **Cinderfall Barrage:** magma sigil → volcano rises from cracked earth → crater launches fire stones → stones rain radially → burning craters, lava pools, embers.
- **Tsunami Breaker:** lane path marker → curling wave wall rises → sweeps the lane pushing enemies → terminal splash → flooded ground, puddles, mist.
- **Tornado Tempest:** spiral wind rune → tornado forms from dust → pulls enemies and debris → walks forward → dust trail, scarred ground.
- **Judgement of the Ancients:** golden earth rune → stone hands rise → golem torso knuckle slams (combo) → two-hand final slam shockwave → rubble.
- **Dragonfire Parade:** dragon sigil → ground eruption → fire dragon rises → head sweeps left→right breathing a fire cone → burning patches.

## Verification

Same as Set1: headless tests (`tools/test.sh`), audio `--verify`, `tools/capture.sh --capture-all --only=<key>` contact sheets compared against the concept sheet, zero console errors.
