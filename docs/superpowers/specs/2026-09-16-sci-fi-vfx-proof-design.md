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
  src/audio/sfx.gd             cue catalog + pooled positional playback (see Audio)
  default_bus_layout.tres      SFX bus, master compressor + limiter
  assets/audio/<effect>/*.wav  generated cues (committed)
  tools/audio/synth.py         cue synthesizer + --verify
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

## Audio

Procedurally synthesized SFX, one or more cue per visual stage. No downloaded assets.

### Generation

- `tools/audio/synth.py` (Python 3.12 + numpy + scipy) builds every cue from oscillators, filtered noise, pitch envelopes, distortion and a simple convolution/feedback reverb.
- Deterministic: fixed seed per cue, so re-running produces identical files.
- Output: `assets/audio/<effect>/<cue>.wav`, 44.1 kHz, 16-bit, mono. Peak normalized to −1 dBFS, 5 ms fade in/out on one-shots, loops cut at zero crossings with crossfaded seam.
- Generated WAVs are committed so the game runs without Python.
- `python tools/audio/synth.py` regenerates all; `--only <cue>` regenerates one.

### Cue list

| Effect | Cue id | Stage / trigger time | Length | Character |
|---|---|---|---|---|
| Nova | `nova_alarm` | Telegraph, 0 | 1.5 s | two-tone warning beeps, speeding up |
| Nova | `nova_lock` | end of telegraph, 1.3 | 0.3 s | rising lock-on tone |
| Nova | `nova_descent` | Descent, 1.5 | 0.8 s | falling pitch scream/whistle + air noise, ends at impact |
| Nova | `nova_crack` | Impact, 2.3 | 0.4 s | bright transient crack |
| Nova | `nova_boom` | Impact, 2.3 | 3.0 s | sub-bass sine drop + saturated low noise |
| Nova | `nova_shockwave` | Blast wave, 2.3 | 1.2 s | band-passed noise sweep high→low |
| Nova | `nova_rumble` | Aftermath, 3.0 | 5.0 s | low filtered rumble with debris ticks, decaying |
| Nova | `nova_geiger` (loop) | Aftermath, 3.3–9, fading | 2.0 s loop | random Geiger clicks over faint hiss |
| Orbital | `orb_target` | Target zone, 0 | 0.8 s | scanning chirps |
| Orbital | `orb_charge` | each strike reticle | 0.4 s | rising charge whine |
| Orbital | `orb_hit_1..4` | each strike beam | 0.9 s | beam zap + thud + short boom; 4 variants, random pick + ±8% pitch |
| Orbital | `orb_embers` (loop) | Aftermath, 4.5–6.5, fading | 2.0 s loop | crackle and hiss |
| Gravity | `grav_field` | Field, 0 | 0.8 s | warping pitch-bent tone |
| Gravity | `grav_drone` (loop) | 0–4.1 | 2.0 s loop | low detuned drone, volume/pitch rise with pull strength |
| Gravity | `grav_suction` | Pull, 0.8 | 2.7 s | reversed whoosh rising in pitch |
| Gravity | `grav_compress` | Compression, 3.5 | 0.6 s | fast wobble/flutter, tightening |
| Gravity | `grav_implode` | Implosion, 4.1 | 2.5 s | all other gravity cues cut to silence for 0.08 s, then deep boom + reverse-tail snap |
| Gravity | `grav_shimmer` | Aftermath, 4.3 | 2.4 s | airy high shimmer, decaying |
| Laser | `laser_scan` | Path lock, 0 | 1.0 s | grid-scan sweep hum |
| Laser | `laser_thrusters` | Emitter arrival, 1.0 | 0.6 s | jet thruster descent, landing clunk |
| Laser | `laser_ignite` | Beam link, 1.6 | 0.4 s | "vvvm" beam ignition |
| Laser | `laser_hum` (loop) | Walk, 2–5.5 | 1.0 s loop | buzzing electric hum, slight wobble |
| Laser | `laser_sizzle_1..3` | each kill during walk | 0.3 s | burn sizzle; 3 variants |
| Laser | `laser_powerdown` | Aftermath, 5.5 | 0.8 s | falling power-down |
| Laser | `laser_depart` | Aftermath, 5.7 | 1.5 s | thrusters lifting off, fading |

### Playback (Godot)

- `src/audio/sfx.gd` — `Sfx` node in sandbox; catalog maps cue id → stream path + options (volume dB, voice limit, pitch jitter, loop).
- `Sfx.play(cue, ground_pos) -> AudioStreamPlayer2D` plays positionally from pooled `AudioStreamPlayer2D` (pool 32). Returns handle so loops can be faded/stopped (`Sfx.fade_out(handle, seconds)`).
- Loops set `AudioStreamWAV.loop_mode = LOOP_FORWARD`, `loop_end` = sample count, at load time.
- Voice limits: `orb_hit_*` 4, `laser_sizzle_*` 3, others 2; oldest voice stolen when limit hit.
- Pitch follows slow-mo: `pitch_scale = base_pitch * Engine.time_scale`, updated each frame for active voices.
- Stereo panning: `AudioListener2D` on camera; `max_distance` ~900 px, `attenuation` 1.0 so any on-screen source is clearly audible and panned.
- Bus layout `default_bus_layout.tres`: `SFX` bus → Master; Master has Compressor + HardLimiter (ceiling −0.5 dB) so stacked explosions don't clip.
- Effects call audio only through `Sfx`, receive it at setup alongside `field` and `shake`.
- Capture mode (`--capture-all`) runs with audio muted via `--audio-driver Dummy`.

## Sandbox

- Iso tile ground ~20×20 cells, dark sci-fi floor with subtle panel variation, drawn procedurally.
- 40 dummy enemies wandering randomly within the map.
- Controls: `1`–`4` select effect; left-click casts at cursor (laser grid: drag for direction); `R` respawn enemies; `Space` toggle 0.25× time scale; `Esc` quit.
- HUD label shows selected effect + controls.
- Camera2D centered on map with shake.

## Verification

1. **Headless tests**: `Godot_console --headless --path . --script res://tests/run_all.gd` prints `failures=0`, exit 0. Covers iso round-trip, ellipse/lane containment, pull convergence, kill.
2. **Error-free run**: console output of sandbox run contains no `ERROR`/`SCRIPT ERROR`/shader compile errors.
3. **Visual capture mode**: `Godot_console --path . --audio-driver Dummy -- --capture-all` casts each effect in turn with a fixed seed and saves PNGs from the viewport at key stage times to `res://captures/<effect>_<t>.png` (project-root `captures/`, git-ignored), then quits. Claude inspects the images against the concept sheets and iterates.
4. **Audio checks**: `python tools/audio/synth.py --verify` asserts every catalog cue file exists, length within ±5% of spec, peak ≤ −1 dBFS, no NaN/DC offset > 1%, loop wrap-around step no larger than the signal's own 99.9th-percentile sample step (no click); one-shots start/end within ±0.02. Godot test asserts every `Sfx` catalog path loads as `AudioStreamWAV`. Final listen check is by the user (Claude cannot hear).
5. **Performance sanity**: FPS printed in capture mode; target ≥60 FPS during every effect on the dev machine.

## Out of scope

- Integration into x-siege-godot.
- Networking, damage numbers, music, recorded/downloaded audio, real enemy art, cooldowns/UI skill bar.
