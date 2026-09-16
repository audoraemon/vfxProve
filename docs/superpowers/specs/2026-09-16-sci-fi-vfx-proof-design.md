# Sci-Fi VFX Proof — Design

Date: 2026-09-16
Status: Approved (design), pending spec review

## Goal

Prove the four concept sheets in this folder (`VFXConcept_*.png`) can be built as real-time effects in Godot for a 2D isometric pixel-art game:

1. Nuclear Nova — warhead descends onto target, explodes in a huge circular shockwave.
2. Orbital Strike — multiple orbital cannon shots hit random points inside a radius.
3. Gravity Distortion — pulls enemies in the area to the center, then detonates.
4. Walking Laser Grid — a row of overhead emitters forms a laser wall that walks forward, killing enemies it passes.

Success = each effect plays its five concept stages (telegraph → arrival → impact → main action → aftermath) in a playable sandbox, reads clearly at native pixel resolution, and enemies react as gameplay would expect.

## Constraints

- Godot `4.7.2.stable`, GDScript, **GL Compatibility** renderer.
- Match sibling project `x-siege-godot` (KWAI) so effects can transfer later:
  - Root viewport 640×360, `stretch/mode="viewport"`, `aspect="keep"`, window override 1280×720.
  - Isometric cell 64×32 px = 1 ground unit. Gameplay math in Cartesian ground coordinates; projection is presentation-only.
  - Default texture filter: nearest.
- **Procedural art only**: shaders, particles, and code-drawn pixel sprites. No external image assets.
- No MCP required; files authored directly and verified through the Godot console executable.

## Approach

Native low-res rendering. Everything draws into the 640×360 viewport and is upscaled with nearest filtering, so shader and particle output is inherently pixel-sized. Shaders quantize color into short palette ramps (3–5 steps) to get pixel-art shading instead of smooth gradients. Rejected: high-res + pixelate post pass (mixed pixel sizes, extra cost); pre-baked flipbooks (defeats tweakability).

### Palettes

- Nova / Orbital / Laser: white → pale yellow → orange → red → dark red; smoke greys; ion sparks cyan-blue (Orbital); radiation fog green (Nova).
- Gravity: white → lavender → violet → deep purple → near-black core.
- Telegraphs: red (hostile-area warning), purple for Gravity.

## Architecture

```
vfxProve/
  project.godot
  scenes/sandbox.tscn
  src/core/iso.gd              ground<->screen (64x32), iso ellipse/lane helpers
  src/core/camera_shake.gd     trauma-based shake on Camera2D
  src/sandbox/sandbox.gd       tile ground, input, HUD label, effect picker, respawn, slow-mo, capture mode
  src/enemies/dummy_enemy.gd   code-drawn pixel soldier; states WANDER / KNOCKBACK / PULLED / DEAD
  src/enemies/enemy_field.gd   registry + queries: in_radius, in_lane_band, apply_impulse, set_pull, kill
  src/fx/fx_timeline.gd        base: stage schedule by time, helpers to spawn shader quads/particles, auto-free
  src/fx/nuclear_nova.gd
  src/fx/orbital_strike.gd
  src/fx/gravity_distortion.gd
  src/fx/walking_laser_grid.gd
  src/fx/fx_parts.gd           shared builders: particle bursts, flashes, decals, beams
  shaders/iso_rings.gdshader         dashed concentric rings, scan sweep, pips (flattened 2:1)
  shaders/shockwave.gdshader         expanding ring band with inner glow
  shaders/fireball_dome.gdshader     banded dome with noise, grow/collapse param
  shaders/singularity.gdshader       screen-texture swirl distortion + dark core + rim
  shaders/beam_glow.gdshader         vertical/horizontal beam core + quantized falloff + flicker
  shaders/scorch_decal.gdshader      noisy crater/char with glowing edge, fade param
  shaders/fog.gdshader               drifting quantized noise fog (radiation / smoke haze)
tests/
  run_all.gd                   headless test entry, prints failures=N, exits with code
  test_iso.gd                  projection round-trip, ellipse containment
  test_enemy_field.gd          radius/lane queries, pull convergence, kill
```

### Units

- **iso.gd** — pure static functions. `ground_to_screen(Vector2) -> Vector2`, `screen_to_ground(Vector2) -> Vector2`, radius in ground units converts to a 2:1 screen ellipse. No scene dependencies.
- **enemy_field.gd** — owns the list of enemies (Node), exposes queries in ground space. Effects talk only to this, never to enemies directly.
- **dummy_enemy.gd** — Node2D; stores `ground_pos`, updates screen position via iso; draws ~10×16 px soldier with `_draw()`; white hit flash; on death spawns a small burst and fades.
- **fx_timeline.gd** — base Node2D. Subclass declares `duration` and implements `_stage(t)` callbacks via a schedule of `(time, callable)` entries plus per-frame `_fx_process(t, delta)`. Frees itself after `duration`. Receives `field`, `shake`, `layers` (ground / world / overhead) on setup.
- **sandbox.gd** — builds scene, handles input, spawns effects with target ground position (and direction for laser grid).

### Draw layers

1. `GroundLayer` (z low): iso tiles, telegraphs, scorch decals, fog base.
2. `WorldLayer` (`y_sort_enabled`): enemies, warhead, laser posts/beams per emitter, beam columns.
3. `OverheadLayer` (z high): flashes, fireball dome, smoke tops, sparks, HUD-independent screen flash.
4. `CanvasLayer` HUD: current effect name, controls hint.

## Effects

Radii in ground units (1 unit = one 64×32 cell). Times in seconds from cast.

### Nuclear Nova (~9 s, radius 5)

| Stage | Time | Visual | Gameplay |
|---|---|---|---|
| Telegraph | 0–1.5 | red dashed concentric iso rings, rotating scan line, center crosshair, pulse | none |
| Descent | 1.5–2.3 | warhead sprite falls diagonally from off-screen top, fire trail + smoke particles | none |
| Impact | 2.3 | full-screen white flash (fast fade), vertical light pillar, heavy shake | enemies within 1.2 killed |
| Blast wave | 2.3–3.3 | shockwave ring expands 0→5; fireball dome grows then collapses; debris burst; ground crack decal | enemies killed when ring front passes; enemies 5–7 knocked outward |
| Aftermath | 3.3–9 | smoke column, scorched crater decal, green radiation fog, green fallout particles, all fading | none |

### Orbital Strike (~6.5 s, radius 4.5, 12 strikes)

| Stage | Time | Visual | Gameplay |
|---|---|---|---|
| Target zone | 0–1 | red area rings with scattered pips | none |
| Salvo | 1–4.5 | per strike at random point (uniform in disc, min spacing 0.8): reticle ring + thin aim beam for 0.4 s, then heavy beam column 0.15 s, impact flash, explosion burst, debris, small crater decal, small shake | enemies within 1.0 of strike killed, 1.0–1.8 knocked back |
| Aftermath | 4.5–6.5 | craters remain and fade, smoke plumes, cyan ion sparks, embers | none |

### Gravity Distortion (~6.5 s, radius 4.5)

| Stage | Time | Visual | Gameplay |
|---|---|---|---|
| Field | 0–0.8 | purple rings form outward, screen-texture ripple warp, small core appears | none |
| Pull | 0.8–3.5 | swirl distortion intensifies, radial pull-line streak particles, rubble spiraling in, core grows | enemies in radius pulled toward center; strength ramps up; tangential component gives spiral; pulled enemies stop wandering |
| Compression | 3.5–4.1 | core shrinks and flickers, rings contract, bright rim | pull continues at max, enemies clamp near center |
| Implosion | 4.1 | inverse flash (dark then bright), purple burst ring, radial sparks, shake | all enemies within 1.5 of center killed; enemies still in radius knocked outward |
| Aftermath | 4.1–6.5 | warped ground scar decal, floating purple sparks, fading | none |

### Walking Laser Grid (~7 s, lane width 5, length 10)

Cast: press at start point, drag to set direction (release). Quick click without drag uses screen-down-right iso axis.

| Stage | Time | Visual | Gameplay |
|---|---|---|---|
| Path lock | 0–1 | lane rectangle projected on ground with grid lines, boundary node markers, pulsing | none |
| Emitter arrival | 1–1.6 | 5 emitter drones (code-drawn) descend to hover height along start edge, vertical lock beams to ground | none |
| Beam link | 1.6–2 | horizontal beams connect adjacent emitters at two heights, intersection sparks | none |
| Walk | 2–5.5 | whole row advances along lane; beams flicker; motion streaks; molten scorched trail decal left behind with glowing edge | any enemy whose ground position is within the lane width and within ±0.35 of wall line is killed with contact burn flash |
| Aftermath | 5.5–7 | beams shut off, drones ascend out, smoke wisps and heat haze along trail, trail fades | none |

## Sandbox

- Iso tile ground ~20×20 cells, dark sci-fi floor with subtle panel variation, drawn procedurally.
- 40 dummy enemies wandering randomly within the map.
- Controls: `1`–`4` select effect; left-click casts at cursor (laser grid: drag for direction); `R` respawn enemies; `Space` toggle 0.25× time scale; `Esc` quit.
- HUD label shows selected effect + controls.
- Camera2D centered on map with shake.

## Verification

1. **Headless tests**: `Godot_console --headless --path . --script res://tests/run_all.gd` prints `failures=0`, exit 0. Covers iso round-trip, ellipse/lane containment, pull convergence, kill.
2. **Error-free run**: console output of sandbox run contains no `ERROR`/`SCRIPT ERROR`/shader compile errors.
3. **Visual capture mode**: `Godot_console --path . -- --capture-all` casts each effect in turn with a fixed seed and saves PNGs from the viewport at key stage times to `res://captures/<effect>_<t>.png` (project-root `captures/`, git-ignored), then quits. Claude inspects the images against the concept sheets and iterates.
4. **Performance sanity**: FPS printed in capture mode; target ≥60 FPS during every effect on the dev machine.

## Out of scope

- Integration into x-siege-godot.
- Networking, damage numbers, audio, real enemy art, cooldowns/UI skill bar.
