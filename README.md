# VFX Prove

Real-time Godot proof of four sci-fi skill effects from the concept sheets in `concepts/`, built for a 2D isometric pixel-art game:

| Key | Effect | Stages |
|---|---|---|
| 1 | **Nuclear Nova** | target rings → warhead descent → flash + pillar → shockwave + fireball dome → smoke column, crater, radiation fog |
| 2 | **Orbital Strike** | zone + pips → per-point lock-on + aim beam → 12 beam impacts → craters, smoke, ion sparks |
| 3 | **Gravity Distortion** | field rings → screen-warping singularity pulls enemies in → compression → implosion → warped scar |
| 4 | **Walking Laser Grid** | lane telegraph → emitter drones descend → beam wall links → wall sweeps the lane → molten corridor |

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
shaders/         iso_rings, shockwave, fireball_dome, beam_glow, scorch_decal, fog, singularity
assets/audio/    generated WAV cues (committed)
tools/           test runner, capture runner, contact sheets, audio synth
docs/superpowers design spec + implementation plan
```

Each effect is a `FxTimeline` subclass: `_build()` schedules stage callbacks with `at(time, fn)`, `_fx_process()` runs per-frame logic. Effects reach gameplay only through `EnemyField` and audio only through `Sfx` (via `FxContext`). Ground-plane effects are children of a node whose transform is the iso basis, so they are authored in ground units and project to iso automatically.

## Verify

```bash
bash tools/test.sh                                   # headless tests → checks=90 failures=0
python tools/audio/synth.py --verify                 # audio cue checks → 30 cues, 0 problems
bash tools/capture.sh --capture-all [--only=nova]    # PNG frames at key stage times → captures/
python tools/contact_sheet.py nova 4                 # tile captures into captures/sheet_nova.png
```

Benchmark (all four effects at once, or one with `--only=`):

```powershell
& $godot --path . --audio-driver Dummy --disable-vsync --max-fps 0 -- --bench
```

Dev machine results (RTX 3060 Ti; another game was running in the background, so worst frames are noisy):

| Bench | Avg FPS | Worst frame |
|---|---|---|
| nova | 291 | 12.5 ms |
| orbital | 351 | 10.8 ms |
| gravity | 567 | 6.4 ms |
| laser | 331 | 9.5 ms |
| all four at once | 232 | 20.7 ms |

All shaders are drawn once at startup (`FxParts.prewarm`) — without it the Compatibility renderer compiled them on each effect's first impact frame (~30 ms hitch).

## Audio

`python tools/audio/synth.py` regenerates all 30 cues deterministically (numpy + scipy); `--only <cue>` for one, `--spectrograms captures` renders a review sheet. Cue timings per stage are in the design spec.

## Gotchas

- `project.godot` enables `snap_2d_vertices_to_pixel`: `draw_line` with width ≥ 1 builds quads that can collapse to nothing. Use hairlines (`width = -1`) and stack them for thick pixel lines.
- Shader timing uses `uniform float u_time` driven by `QuadFx`, not `TIME`, so effects honor `Engine.time_scale`.
- The first headless import of new files occasionally crashes; `tools/test.sh` retries once.
