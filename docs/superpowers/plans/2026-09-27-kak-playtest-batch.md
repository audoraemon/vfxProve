# KAK playtest batch — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:**
- The Temple refills DP.
- A zoom-out cap.
- Wind, fountain and banner animation.
- Collapse sounds.
- The town closer to its reference.
- A Tornado that locks onto buildings.

**Spec:** `docs/superpowers/specs/2026-09-27-kak-playtest-batch-design.md`.

**Tag first:** `kak-playtest-2-start` on the current HEAD.

## Global Constraints

- Of `src/fx/`, only `src/fx/set2/tornado_tempest.gd` changes.
- Gates after every task:
  - `bash tools/test.sh` passes;
  - FLOW 24/24;
  - the digest (`tools/dev/state_digest.gd`) is unchanged until Task 6;
  - `tools/dev/crowd_check.gd` shows `checksum=-890235158` unless a task says why it changes.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never commit `captures/` or `default_bus_layout.tres`.

---

### Task 1: The Temple restores DP

**Files:** `src/game/rules.gd`, `src/game/ui/prepare_screen.gd`, `tests/test_rules.gd`.

1. Add `TEMPLE_DP_SHARE := 0.7` to `rules.gd` and remove `&"temple"` from `DP_FOR_ROLE`.
2. In `_on_structure_destroyed`, when `s.role == &"temple"`:
   - add `minf(DP_MAX, dp + DP_MAX * TEMPLE_DP_SHARE)`, whatever `dp_recovery` says;
   - emit `dp_changed` and `dp_gained(applied, s.center())`;
   - emit `banner("THE TEMPLE FALLS — DIVINE POWER RESTORED")`.
3. In the Prepare briefing's POWER line, append "; destroying the Temple restores %d DP", with the number from the constant.
4. Tests:
   - 10 DP → 80;
   - 50 DP → 100;
   - a house pays nothing;
   - with `dp_recovery` off the Temple still pays.
5. Run the gates, then commit "feat: the Temple's fall restores 70% of Divine Power".

### Task 2: Zoom-out cap

**Files:** `src/game/mission.gd`.

1. Set `ZOOM_MIN := 0.5` and `INTRO_FROM_ZOOM := 0.5`.
2. Update the comment: "below 0.5 the pixel art shimmers".
3. Run the gates and the mission test, then commit.

### Task 3: Collapse sounds

**Files:**
- `tools/audio/synth.py`: three generators × 3 variants;
- `assets/audio/collapse/*.wav`;
- `src/audio/sfx.gd`: three cues with 3 variants each, `voices: 4`, jitter 0.08;
- `src/game/town/town.gd`: a listener on `env.structure_destroyed` that picks the family by kind and role and scales the level by footprint area.

1. Generate the sounds with `python tools/audio/synth.py collapse`, following the existing generators' style.
2. Test (`test_town` or a new `test_collapse_sound`): the family per kind and role is stone for keep, wall, gate, temple and barracks; timber for house and stall; tree for tree; none for torch.
3. Run the gates, then commit.

### Task 4: Wind shader and swaying art

**Files:**
- `src/environment/art/art_kit.gd`: `wind_from_y`, `wind_span`, `wind_gain` static vars, applied to UV.y in `poly()`;
- `src/environment/art/structure_art.gdshader`: a `vertex()` stage and a `wind` uniform;
- `shaders/wind.gdshader`: new, for decor and the forest layer;
- `src/environment/structure.gd`: set `wind` in `_light_art()`; `static var wind := 1.0`;
- `src/environment/art/prop_art.gd`: tree crowns and stall awnings;
- `src/environment/art/civic_art.gd`: banners;
- `src/environment/decor.gd`: the shared wind material for OAK, PINE and BUNTING;
- `src/environment/art/decor_art.gd`: bunting weights;
- `src/game/town/town_floor.gd` + `src/game/town/forest_layer.gd` (new): forest trees leave the floor bake for `ForestLayer`, one batch with the wind material, under the world;
- `tools/dev/preview_components.gd`: sets `Structure.wind = 0` and the decor material's wind to 0.

1. Implement, then check:
   - captures in and out of town at two moments 0.5 s apart show motion;
   - the component match with wind 0 is unchanged.
2. Bench against `kak-perf-v1` in the same hour. Expected cost under 2 fps.
3. Run the gates, then commit.

### Task 5: Fountain water

**Files:** `src/environment/structure.gd` (the spin node also for the fountain, 12 Hz) and `src/environment/art/prop_art.gd` (`fountain_water(s, ci, step)`).

1. Implement, capture a 6-frame strip for the checkpoint, run the gates, then commit.

**Checkpoint A:** show the town captures, the fountain strip and a sway strip. The user tries the sounds in play.

### Task 6: Tornado locks on

**Files:** `src/fx/set2/tornado_tempest.gd` and `tests/test_tornado_lock.gd` (new).

1. `static func pick_target(center, origin, current, structures) -> Structure`: the nearest building (not walkable, role not decor or wall, not destroyed) with its centre within `WANDER_RADIUS` of `origin`. Keep `current` unless the best is at least `LOCK_SWITCH` (1.0) nearer.
2. `_wander()` re-picks every `LOCK_REPICK` (0.5 s) or when the target is gone.
   - The goal is the target's centre, keeping the sway.
   - Inside `LOCK_CLOSE` (1.2) the speed eases to 45% and the heading circles the target.
   - With no target, a slow circle of radius 1.5 round the origin.
3. Remove `WANDER_BOUNDS` and `_pick_goal()`.
4. Tests:
   - nearest in ring;
   - ignores decor, walls, walkable and destroyed structures;
   - the switch threshold;
   - an empty ring gives null.
5. Run the gates.
   - The digest changes: confirm with the effect list that only the tornado's own entries differ, then record the new digest in the plan's changes.
   - `tools/dev/crowd_check.gd` does not involve the tornado and stays unchanged.
6. Re-record the clip with `SCENE=res://scenes/sandbox.tscn bash tools/capture.sh --capture-clip --only=tornado`.
7. Update the memory note on the Tornado's wander (done).
8. Commit.

**Checkpoint B:** a capture strip of the tornado homing and grinding.

### Task 7: Closing the gaps

**Files:** `tools/dev/match_interior.py` (`--band outside`), `src/game/town/town_decor.gd`, `src/game/town/town_floor.gd`, `src/environment/art/art_tuning.json`, the prop art as needed.

1. Record the outside baseline.
2. Forest ring:
   - thicker: more trees and bushes, in `_outside`;
   - warmer: the GRASS and FOREST palettes toward the reference.
   - Loop until the outside score stops rising.
3. Props: `tune_components.py --below 85` on props, then redraw lamp, torch and reeds and re-measure.
4. Market clutter: `_market()` places crates, barrels, baskets, sacks, benches and a cart between the stall rows, on blocked cells.
5. Gates: the interior score ≥ 91%, the component match ≥ 89% overall, props ≥ 85%.
6. Commit.

**Checkpoint C:** the town beside the reference, with the outside and interior numbers.

### Task 8: Wrap-up

1. Bench against `kak-perf-v1` in the same hour.
2. Record the mission test and crowd test.
3. Append "Changes made while executing".
4. Tag `kak-playtest-2`, push, and show the final sheets.
