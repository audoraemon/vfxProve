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

---

## Changes made while executing

- **Task 1.** Step 2 (houses, gardens and trees keep clear of the fans instead of the plaza rectangles) moved to Task 3, where it opened the plazas' corners.
- **Task 3: the bottom of town.**
  - No hand-placed south-quarter rects. An infill pass (`TownLayout._infill()`) scans the southern districts every 0.25 units from the wall up and puts a townhouse, else a cottage, wherever one fits: clear of the streets, the fans, the landmarks, and 0.5 from every other house. Houses 71 → 81.
  - The carpenter's yard sits in the south-east corner under the Side Gate's queue: a shed drawn by the workshop's art, with log piles and sawhorses among the benches, and a log pile (the new `Decor.Kind.LOGS`) with a barrel on a blocker beside it.
  - Rosettes stand at fixed spots inside the fans (`TownFloor.ROSETTES`): the Side Gate plaza's centre lay outside its fan, under a new house.
  - Ruts are strips of stone darker than the mortar. A mortar-coloured line vanished among the cobbles.
  - A lamp moved out of the shed, from (13.5, 13.9) to (11.35, 13.3).
  - The plaza test checks the fans themselves (no margin). The barracks is exempt: it has always cut the Side fan's far corner, and the queue-room test counts the spots actually free (Main 219, Side 213, unchanged).
- **Task 4: the market.**
  - Rows are 1.5 apart, not 1.2. With 0.7-deep stalls, 1.2 could not keep 0.8 aisles.
  - Three stalls per row west of the street (not four), leaving a walkway along the street for the piles. The east column goes from 5 to 8 stalls. 20 → 30 stalls, kept as a const list.
  - Six piles: tables of goods and crate stacks at the rows' street ends, and a cart by the fountain. A seventh, south of the fountain, was dropped: the walk-grid test keeps that ground open.
  - Two lamps at the aisle heads.
- **Task 5: street props.**
  - The step is 1.75, not 3.5. At 3.5 only 20 props stood: junctions, trees, lamps, squares and the fans rule out most spots. 48 stand now.
  - Carts only along east-west streets (the cart is drawn along the ground's x axis).
  - Props stand 0.15 off the street's edge, so the cells people walk in the street stay open. The crowd test's escapes were unchanged: 16 with and without props.
- **Task 6: people in public.** Two of every five citizens by spawn order (88 of 220): half on the market's walkable floor, half on the street centre lines and round the plazas outside the fans.
- **crowd_check** by task: −881706988 (Task 3), −232271476 (Task 4), −417410755 (Task 5), −245538477 (Task 6, the new baseline).

### Results

- **Density** (`match_density.py`):

  | | Reference | Before | After |
  |---|---|---|---|
  | All roofs | 15.9% | 12.8% | 16.1% |
  | Canopy | 11.5% | 11.4% | 9.6% |
  | Open ground (ours, from the layout) | ~30–40% (judged) | 67% | 61% |

  The target of ~50% open ground was not reached. What stays open is mostly the streets and the two queue fans, which must stay walkable. Canopy fell as houses took tree spots.
- **Interior score:** 91%.
- **Crowd test:** 140 alive, 17 escaped (from 162 and 16). The scripted powers land on the market, where more people now stand.
- **Mission test:** `citizens=143 escaped=10 stability=45%` (from 162, 12, 46%).
- **Bench** against `kak-playtest-2`, same hour, three alternating runs:
  - `kak-playtest-2`: 79.4, 94.5, 85.2 fps (median 85.2);
  - now: 90.0, 66.5, 83.0 fps (median 83.0);
  - draw calls 1064 → 1201.

  The median cost is about 2 fps, inside the 5-fps budget. The draw calls predict ~0.5 ms (3.5 µs each).
- **Tests:** 749 checks.
