# KAK playtest batch — design

After playing the scaled town the user asked for six things. The first four are theirs from the playtest; the last
two finish the town upgrade and the Tornado change that was parked since milestone 4.

Decisions taken with the user (2026-09-27):
- **Temple:** restores 70% of max DP when it falls.
- **Zoom:** the zoom-out cap is 0.5.
- **Animations:** the fountain, stall awnings and bunting, trees, and the cathedral's banners all move.
- **Tornado:** it locks onto the nearest building inside its ring.

## 1. The Temple restores Divine Power

- When the Temple (role `temple`, the cathedral) is destroyed, the player gains `TEMPLE_DP_SHARE` (0.7) × `DP_MAX`, capped at `DP_MAX`.
  - It pays even though `dp_recovery` is off: it is the one deliberate refill.
  - It happens once a mission, because there is one Temple.
  - The DP popup shows at the Temple. A banner reads "THE TEMPLE FALLS — DIVINE POWER RESTORED".
- The Temple leaves `DP_FOR_ROLE`, so it can never pay twice if recovery is turned back on.
- The Prepare screen's briefing gains the line "Destroying the Temple restores 70 DP", read from the constant.
- **Test:** `test_rules`.
  - From 10 DP the Temple's fall gives 80.
  - From 50 DP it caps at 100.
  - A house pays nothing.

## 2. Zoom-out cap

- The mission's `ZOOM_MIN` goes from 0.3 to 0.5.
  - Below 0.5 the minified pixel art shimmers: the cobbles moiré and people vanish (see the zoom sheet from the brainstorm).
  - The intro's fly-in starts from 0.5 (`INTRO_FROM_ZOOM`) and eases to the play zoom of 0.6.
- `town_debug` is a dev scene and keeps its own limits, so the overview capture still works.

## 3. Structure animations

### 3a. Wind, on the GPU

Moving parts sway in the vertex shader, so nothing redraws for them.
- **Weights in UV.y.** Art marks each vertex with a wind weight in UV.y. `ArtKit` gains `wind_from_y` / `wind_span` / `wind_gain`: while `wind_gain > 0`, `poly()` sets UV.y = `wind_gain` × clamp((`wind_from_y` − y) / `wind_span`, 0, 1). So weight grows with height above a base line, and the art resets the gain after the moving part.
- **Structures.** `structure_art.gdshader` gets a `vertex()` stage.
  - Art vertices (UV.x ≥ 1.5) with UV.y > 0 move by UV.y × (sin(TIME·1.3 + φ), 0.5·sin(TIME·5 + VERTEX.x·0.35 + φ)).
  - φ comes from the node's position (`MODEL_MATRIX`), so neighbours don't move in step.
  - The offset is rounded to whole pixels, so it reads as pixel-art motion. Coincident vertices get identical offsets, so shapes do not tear.
  - A `wind` uniform (1 in play) scales it. Component previews set it to 0 so their captures stay still.
- **Decor and the forest.** Decor art uses the pass-through code, so it gets its own small `wind.gdshader` with the same vertex motion and a plain fragment. It is shared by every swaying decor piece: position-based phase needs no per-node uniform.
- **What moves:**
  - Trees: town and outside `TREE` structures, live decor oaks and pines. The crown sways; the trunk stays.
  - The forest ring: its trees move out of the floor texture into one `ForestLayer` node, drawn between the floor and the world as a single triangle batch with the wind shader. Only trees move there; baked rocks, bushes, reeds, flowers and fences stay in the floor.
  - Stall awnings: the front edge ripples.
  - Bunting: the flags flutter.
  - The cathedral's three banners: they wave, more at the foot.

### 3b. Fountain water

A child node on the fountain, like the mills' sail node, redrawn in 12 Hz steps:
- a jet rising from the top spout, bobbing;
- drops looping down from both bowls' rims;
- two ripple rings widening in the basin.

It stops when the fountain is destroyed and draws nothing while unseen, like the mills.

## 4. Collapse sounds

- **Three families, three variants each**, synthesized in `tools/audio/synth.py` like every KAK sound:

  | Family | Used for | Sound | Length |
  |---|---|---|---|
  | `collapse_stone` | walls, towers, gates, keeps, the Citadel's parts, the temple, the barracks, the bridge | low rumble, gritty crumble, stone knocks | ~1.4 s |
  | `collapse_timber` | houses, taverns, stalls, farm buildings, mills, the workshop | crack, splintering, thud | ~1.1 s |
  | `collapse_tree` | trees | crack, leaf swish, thud | ~0.8 s |

- **Playback:**
  - A listener on `EnvironmentField.structure_destroyed` (in `Town`) plays the family's cue at the structure's ground position through `Sfx.play`.
  - A bigger footprint plays up to 4 dB louder.
  - Each family is voice-capped (4, with pitch jitter), so a Cinderfall felling a dozen things does not pile up.
  - Torch and lamp posts stay silent.

## 5. Closing the gaps to the Scale reference

- **Measure first.** `match_interior.py --band outside` runs the same metrics on the ground between the walls and 6 units beyond them (warmth, green, saturation, red over blue, busyness), and the baseline is recorded.
- **Forest ring.** Thicker and warmer: more trees and bushes, fewer bare patches, a warmer meadow. Iterate until the outside score stops rising.
- **Props.** Their material match is 77%. The tuner runs on props under 85%, then the worst are redrawn (street lamp 78%, torch post 77%, reeds 81%), each to at least 85% where the shape allows.
- **Market.** Crates, barrels, baskets, sacks, benches and a cart between the stall rows, all on blocked cells, so nobody walks through them.
- **Success:**
  - the interior score stays at 91% or better;
  - the outside score rises from its baseline;
  - the component match stays at 89% or better overall, with props at 85% or better.

## 6. Tornado Tempest locks on

- **Target.** The nearest standing building inside the ring (`WANDER_RADIUS`, 7 units from the cast point).
  - A building here is a structure that is not walkable and whose role is not `decor` or `wall`.
  - The choice is re-made every 0.5 s and whenever the target falls. It switches only to one at least 1 unit nearer, so it doesn't dither between two.
  - The choice is a static function (`pick_target`) so it can be tested.
- **Soft lock.** The existing steering (turn rate and sway) aims at the target. Within 1.2 units it slows and circles it, grinding it down, rather than stopping dead. With nothing left in the ring it idles in a slow circle round the cast point.
- **`WANDER_BOUNDS` goes.** It pinned the roaming to ±5.5 around the map's middle, a leftover from the small town: cast anywhere else, the tornado drifted to the town centre.
- **Aim ring.** It stays at `WANDER_RADIUS`, now the lock range, so the targeting test is unchanged.
- **Knock-on changes.** The sandbox digest changes, because the tornado moves differently; the new digest becomes the baseline, and every other effect is verified unchanged. The Tornado's draft clip is re-recorded (`capture.sh --capture-clip --only=tornado`).
- **Tests.**
  - `pick_target` picks the nearest building inside the ring.
  - It ignores decor, walls, fields and fallen buildings.
  - It keeps its target unless another is 1 unit nearer.
  - It returns nothing when the ring is empty.

## Global constraints

- Of `src/fx/`, only `tornado_tempest.gd` changes. Every other effect stays as approved.
- Gates after each phase:
  - all tests pass;
  - FLOW 24/24;
  - the digest stays unchanged until phase 6, then gets its new baseline;
  - `tools/dev/crowd_check.gd` shows the crowd unchanged, except where a phase means to change it.
- The frame rate is benched against `kak-perf-v1` in the same hour at the end. The wind is GPU-only, so a cost under 2 fps is expected.
- Images are shown at every visual checkpoint. Sounds are for the user to hear in play.
