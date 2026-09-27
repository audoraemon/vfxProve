# KAK town density — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** a town as dense as the Scale reference: people in the streets, a packed market, less bare paving, props
lining the streets, and a filled bottom of town.

**Spec:** `docs/superpowers/specs/2026-09-27-kak-density-design.md`.

**Tag first:** `kak-density-start`.

## Global Constraints

- Gates after every task:
  - `bash tools/test.sh` passes;
  - FLOW 24/24;
  - the digest is unchanged;
  - the gate-queue tests pass.
- **Crowd baseline.** `tools/dev/crowd_check.gd` changes on purpose in Tasks 1–5; record each new checksum in the plan's changes.
- **Decor inside the walls** stands on blocked cells only (blockers).
- **Queue fans.** Nothing blocks a gate's queue fan (`Crowd.queue_spots()`). A test asserts that every spot the fan would have on an empty town is still walkable.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never commit `captures/` or `default_bus_layout.tres`.

---

### Task 0: Density measure

1. Promote the scratchpad analysis to `tools/dev/match_density.py`:
   - roof (slate, red, teal) and canopy coverage in both images;
   - our open-ground share from `captures/layout.json`.
2. Record the baseline.
3. Commit.

### Task 1: Queue fans as the keep-clear, and a fan test

**Files:** `src/game/town/town_layout.gd`, `tests/test_town_layout.gd`.

1. Add `static func queue_fans() -> Array[PackedVector2Array]`: each gate's fan trapezoid, computed with `Crowd`'s own constants (`QUEUE_DEPTH0`, `QUEUE_REACH`, the half-width `1.2 + depth * 0.6`, `GATE_DOOR`), grown by 0.3.
2. `houses()`, `gardens()` and `town_trees()` keep clear of the fans instead of `GATE_PLAZAS`. The rectangles remain for the floor's cobbles only.
3. Test: every queue spot of a town built with no houses is still walkable in the real town.
4. Gates, then commit.

### Task 2: Street margins and townhouses

**Files:** `town_layout.gd` (`STREET_CLEAR` 0.6, `TOWNHOUSE` sizes, a house mix by hash), `src/environment/art/house_art.gd` (the `townhouse` tag: two storeys without sign or awning), `tools/dev/match_components.py` (a townhouse box in the Scale reference), `tools/dev/preview_components.gd`, and the tests' counts.

1. Implement.
2. Measure the townhouse to at least 85% with the loop.
3. Run the crowd test: escapes still flow.
4. Gates, then commit.

### Task 3: The bottom of the town

**Files:**
- `town_layout.gd`: the south quarter's rects;
- `src/environment/art/civic_art.gd`: the carpenter's yard, from `workshop()`;
- `town_floor.gd`: the plaza rosette and wear;
- `town_decor.gd`: the carpenter's yard's logs and fences.

1. Implement.
2. Capture the bottom before and after.
3. Gates, then commit.

### Task 4: Packing the market

**Files:** `town_layout.gd` (`STALLS` regenerated as tighter rows by a function; `MARKET_PILES` extended), `town_decor.gd` (tables, crates, barrels and baskets on the piles), `LAMPS`.

1. Keep the aisles ≥ 0.8 and the fountain plaza clear.
2. Capture the market before and after.
3. Gates, then commit.

### Task 5: Street life

**Files:** `town_layout.gd` (`STREET_PROPS`: blockers along streets every ~3.5 per side, staggered, clear of junctions, gates, plazas, the market and the fans), `town_decor.gd` (carts, benches, crates with a barrel, barrel pairs, lamp posts).

1. Gates, then commit.

### Task 6: People in public

**Files:** `src/game/crowd/crowd.gd` (`PUBLIC_SHARE` 0.4; public anchor spots: market floor, street centre lines away from junctions, plaza edges outside the fans), `tests/test_crowd.gd`.

1. Tests:
   - 40% ± 2 of citizens are anchored in public ground;
   - everyone stands on walkable ground.
2. Crowd test and mission test: report the escapes.
3. Gates, then commit.

**Checkpoint:** show the overview beside the reference, and the market and the bottom of the town, before and after. Show the density numbers.

### Task 7: Wrap-up

1. Bench against `kak-playtest-2` in the same hour (a loss of 5 fps or less).
2. Record the interior score and the density numbers.
3. Append "Changes made while executing".
4. Tag `kak-density`, then push.
