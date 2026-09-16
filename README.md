# VFX Prove

Real-time Godot proof of four sci-fi skill effects from the concept sheets in `concepts/`, built for a 2D isometric pixel-art game:

| Key | Effect | Stages |
|---|---|---|
| 1 | **Nuclear Nova** | target rings → warhead descent → white-hot core swells slowly → plasma dome (boiling veins, meridian energy lines, rising pulses) + shockwave accelerate outward with god-rays, rubble and a rolling dust ring → shader mushroom cloud rising and cooling from fire to smoke with a condensation ring, heat haze, crater, radiation fog |
| 2 | **Orbital Strike** | zone + pips → ~30 Poisson-disc strike points covering the whole radius, lock-on in bursts of 1–3 → beam impacts with light pools, rays, fireballs, heat haze → crater field, smoke, ion sparks |
| 3 | **Gravity Distortion** | sky beam seeds the field → screen-lensing singularity with wispy accretion disk, photon ring, lightning arcs and orbiting rubble pulls enemies in → compression → implosion with refraction shock ring and starburst → warped scar with hovering fragments |
| 4 | **Walking Laser Grid** | lane telegraph → emitter drones descend → wide glowing beams (core + additive halo, contact rings) link into a wall → wall sweeps the lane with red floor light, heat haze, flames and burn flashes → molten lava corridor (crack network shader) that cools to crust |

**Impact toolkit** (`src/core/impact.gd`): anticipation dimming of the world under the effect layers, inverted two-tone impact frames, hit-stop (real-time, audio keeps its pitch), RGB split, directional camera kicks. Enemies react per damage type: blasts throw and char them, gravity stretches them into the core, lasers cut them apart into embers. Smoke lives in `OverheadBackLayer` so fireballs always read in front of it.

Everything is procedural: canvas shaders, a small pixel particle system, code-drawn sprites, and synthesized audio. No external art or sound assets.

Settings match the sibling KWAI project: Godot 4.7.2, GL Compatibility, 640×360 viewport scaled ×2 with nearest filtering, 64×32 iso cells.

## Run

```powershell
$godot = 'F:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godot --path .
```

Or open the folder in the Godot 4.7.2 editor and press F5.

### Controls

| Input | Action |
|---|---|
| `1`–`4` | select effect |
| Left click | cast at cursor |
| Left drag (Laser Grid) | press = lane start, drag direction = walk direction (short click walks down-right) |
| `R` | respawn 40 enemies |
| `Space` | toggle 0.25× slow motion (audio pitch follows) |
| `WASD` / arrows | pan camera |
| `Esc` | quit |

## Layout

```
src/core/        iso projection, camera shake
src/enemies/     dummy troopers + EnemyField (radius/lane queries, pull, knockback, kill)
src/fx/          FxTimeline base, QuadFx, PixelParticles, FxParts builders, the 4 effects
src/audio/       Sfx cue catalog + pooled positional playback
src/sandbox/     scene assembly, input, HUD, capture/bench modes
shaders/         iso_rings, shockwave, fireball_dome, beam_glow, beam_add, scorch_decal, fog, singularity,
                 light_glow, god_rays, heat_haze, refract_ring, impact_post, molten_trail, mushroom_cloud
assets/audio/    generated WAV cues (committed)
tools/           test runner, capture runner, contact sheets, audio synth
docs/superpowers design spec + implementation plan
```

Each effect is a `FxTimeline` subclass: `_build()` schedules stage callbacks with `at(time, fn)`, `_fx_process()` runs per-frame logic. Effects reach gameplay only through `EnemyField` and audio only through `Sfx` (via `FxContext`). Ground-plane effects are children of a node whose transform is the iso basis, so they are authored in ground units and project to iso automatically.

## Verify

```bash
bash tools/test.sh                                   # headless tests → checks=98 failures=0
python tools/audio/synth.py --verify                 # audio cue checks → 33 cues, 0 problems
bash tools/capture.sh --capture-all [--only=nova]    # PNG frames at key stage times → captures/
python tools/contact_sheet.py nova 4                 # tile captures into captures/sheet_nova.png
```

Benchmark (all four effects at once, or one with `--only=`):

```powershell
& $godot --path . --audio-driver Dummy --disable-vsync --max-fps 0 -- --bench
```

Dev machine results after the impact pass (RTX 3060 Ti; another game was running and using ~2 CPU cores, so numbers swing a lot between identical runs — the empty scene alone varied 380–448 FPS; rerun on an idle machine for real numbers):

| Bench | Avg FPS | Worst frame |
|---|---|---|
| nova | 250 | 20.0 ms |
| orbital | 140–157 | 31–35 ms |
| gravity | 253 | 15.7 ms |
| laser | 263 | 16.5 ms |
| all four at once | 96 | 46.9 ms |

All shaders are drawn once at startup (`FxParts.prewarm`) — without it the Compatibility renderer compiled them on each effect's first impact frame (~30 ms hitch).

## Audio

`python tools/audio/synth.py` regenerates all 33 cues deterministically (numpy + scipy); `--only <cue>` for one, `--spectrograms captures` renders a review sheet. Cue timings per stage are in the design spec.

## Gotchas

- Smoke puffs draw cached pixel-disc textures (`PixelParticles._disc_texture`) rather than `draw_circle`; polygons per puff were the biggest CPU cost.
- `project.godot` enables `snap_2d_vertices_to_pixel`: `draw_line` with width ≥ 1 builds quads that can collapse to nothing. Use hairlines (`width = -1`) and stack them for thick pixel lines.
- Shader timing uses `uniform float u_time` driven by `QuadFx`, not `TIME`, so effects honor `Engine.time_scale`.
- The first headless import of new files occasionally crashes; `tools/test.sh` retries once.
