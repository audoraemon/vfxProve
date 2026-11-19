# Smite and Ember Adjustments Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Smite's level 5 becomes a drag-to-widen bolt (Gathered Storm), and Ember can set a person alight, with a
Fire Trail at level 5.

**Architecture:**
- Smite: a level row may override the power's `aim`. Targeting reads it, so level 5 aims as a drag. `SmiteFx` scales
  its radii by the drag.
- Ember: a new crowd status `Burning` (modelled on `Withering`) holds the person on fire. `EmberFx` picks a person or
  a building. Level 5 lays `GroundFire` patches through `FireManager.lay()`.

**Tech Stack:** Godot 4.7.2 GDScript; headless test suites via `tests/run_part.gd`.

**Spec:** `docs/superpowers/specs/2026-11-19-kak-smite-ember-adjust-design.md`

## Global Constraints

- Branch `god/ruin-adjust` from `origin/feat/Develop-Main` acb82b96. It merges into Develop-Main only on the user's
  word.
- Smite cap `GROW_MAX = 2.5`. `GROW_PER` is about 1.5 units of drag.
- Ember: `PERSON_R 0.6`, `BURN_FOR 4.0`, `SPREAD_EVERY 0.5`, `SPREAD_R 0.8`, `SEE_R 4.0`, `TRAIL_STEP 1.0`,
  `TRAIL_MOST 8`. The burning man's death kind is the existing fire kind (find it; fire deaths leave no raisable body).
- No hard-coding of power behaviour into Person or CitizenAgent: Burning is a reusable status like `Withering`.
- No luck: picks by rule (nearest, then instance id).
- crowd_check: `$G --headless --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/crowd_check.gd` must print
  `checksum=-535548941`. `--fixed-fps` is an engine arg and goes before `-s`.
- Ember stays quiet when cast.

## Review Focus

1. **A drag that starts on Smite's level 4 and is released after the level changes:** use the level at the press. Test
   in Task 1.
2. **The burning man killed by something else, freed, or taken indoors mid-burn:** no fire death, no more trail, no
   errors. Test in Task 2.
3. **A click with a person and a house both in reach:** the person wins only within `PERSON_R`, and the nearest person
   when there are several. Test in Task 2.
4. **The fire trail on narrow or blocked ground:** patches only on walkable ground, never inside a building. Test in
   Task 2.
5. **Many burning people at once:** caps hold and there is no per-frame allocation storm. Task 2 includes a perf check
   in the style of `test_gravetide._perf`.

---

### Task 1: Smite, Gathered Storm

**Files:**
- Modify: `src/fx/ruin/smite.gd`.
- Modify: `src/game/power_book.gd`, the smite level-5 row: `"aim": "drag"` and the new `twist_text`.
- Modify: `src/game/targeting.gd`: `_aim_kind()` honours a level row's `aim`; the smite preview ring grows with the
  drag up to the cap.
- Modify: `src/game/rules.gd`, only if casting needs the level's aim.
- Test: `tests/test_ruin_twist_smite.gd` (rewrite the fork checks), `tests/test_targeting.gd`.

**Interfaces (produces):**
- `SmiteFx`:
  - `const GROW_PER := 1.5`, `const GROW_MAX := 2.5`;
  - `static func grow_for(drag_len: float) -> float` (pure: `clampf(1.0 + drag_len / GROW_PER, 1.0, GROW_MAX)`);
  - `var grow := 1.0` (read from `extra`'s drag at level 5, else 1.0).
- The fork (`FORK_R`, `FORK_DELAY`, `forked_at`, `_fork_target`, `_fork`) is deleted.
- `PowerBook`: a level row's `"aim"` overrides the power's aim (one helper, e.g.
  `static func aim_at(key: String, level: int) -> String`).

- [ ] **Step 1: Tests (RED):**
  - `grow_for(0) == 1.0`, `grow_for(1.5) == 2.0`, `grow_for(9.0) == 2.5`.
  - A level 5 cast with no drag kills within `KILL_R(level 5)` exactly as level 4 does with the level 5 numbers, and
    lays no fork.
  - A level 5 drag of 1.5 kills a citizen at `1.9 * KILL_R(level 5)` and spares one at `2.1 *`. Every building within
    `HIT_R * 2.0` takes `DAMAGE`.
  - A drag of 10: the radius is capped at `2.5 *`.
  - Targeting: at smite level 5, `_aim_kind() == "drag"`; at levels 1-4 it is `"click"`. The press level is kept if the
    level changes mid-drag (Review Focus 1).
- [ ] **Step 2:** Implement. The bolt, flash and light draw scaled by `grow` (staged only).
- [ ] **Step 3:** Run `test_ruin_twist_smite`, `test_ruin_levels`, `test_power_levels`, `test_targeting`,
  `test_power_book`, `test_skill_tree`, `test_tree_detail`, and crowd_check.
- [ ] **Step 4:** Commit: `feat: Smite level 5 -- Gathered Storm: drag to widen the bolt, 2.5x at most`.

### Task 2: Burning, and Ember on people with a Fire Trail

**Files:**
- Create: `src/game/crowd/burning.gd`.
- Modify: `src/game/crowd/crowd.gd` (`var burning: Burning`, `func burn(p, seconds, from) -> bool`, step and clear
  beside `withering`), `src/game/crowd/person.gd` (`func burning() -> bool`, flame tint/draw hook, as `withered()`),
  `src/fx/ruin/ember.gd`, `src/game/power_book.gd` (ember blurb, shape, level 5 `twist_text`).
- Test: create `tests/test_burning.gd` and register it in `tests/run_all.gd`; rewrite `tests/test_ruin_twist_ember.gd`
  (the Leaping Spark checks become Fire Trail checks).

**Interfaces (produces):**
- `class_name Burning`:
  - consts `BURN_FOR := 4.0`, `SPREAD_EVERY := 0.5`, `SPREAD_R := 0.8`, `SEE_R := 4.0`, `KIND :=` the existing fire
    kill kind;
  - `func lay(p: Person, seconds: float, from: Vector2) -> bool`, `func step(delta)`, `func clear()`,
    `func count() -> int`;
  - a per-person trail hook: `func trail(p: Person, on_step: Callable)` or a signal `moved(p, at)`, so Ember can lay
    patches.
- `EmberFx`:
  - consts `PERSON_R := 0.6`, `TRAIL_STEP := 1.0`, `TRAIL_MOST := 8`; `var victim: Person`;
  - `static func pick_person(field, at: Vector2) -> Person` (the nearest living, not inside, not guised within
    `PERSON_R`, tie by instance id; null if none);
  - `static func ring_spots(s: Structure, step: float) -> Array[Vector2]` (pure: the walkable points about 0.6 outside
    the footprint, spaced `step`).
  - Leap code (`LEAP_R`, `LEAP_DELAY`, the second spark) deleted.

- [ ] **Step 1: Tests (RED):**
  - **`test_burning`:**
    - a laid person panics with no shelter roll (Withering's `may_shelter=false` path);
    - after `BURN_FOR` he is dead with the fire kind, and no raisable remain;
    - a house within 0.8 of his path catches within one `SPREAD_EVERY`;
    - a citizen at 3.0 who can see him is frightened, one at 5.0 is not;
    - indoors mid-burn: it lapses, no death;
    - killed by something else or freed mid-burn: no error, no fire death (Review Focus 2);
    - perf: 12 burning people in the 220-person town, step cost under 1 ms averaged over 200 frames (Review Focus 5).
  - **`test_ruin_twist_ember`:**
    - a person 0.4 from the click burns and no house is lit by the cast itself;
    - a person at 0.8 and a house in reach: the house is lit;
    - two people within 0.6: the nearer burns (Review Focus 3);
    - a guised person is skipped;
    - the cast is quiet;
    - level 5 on a house: patches round it, each within 0.6-1.2 of the footprint, about `perimeter / TRAIL_STEP`;
    - level 5 on a man: patches behind him every `TRAIL_STEP`, never more than `TRAIL_MOST`, all on walkable ground
      and none inside a building (Review Focus 4);
    - levels 1-4 lay no patch.
- [ ] **Step 2:** Implement. Burning is stepped and cleared beside `withering` in `Crowd`. Flames on the person are
  draw-only.
- [ ] **Step 3:** Run `test_burning`, `test_ruin_twist_ember`, `test_ruin_levels`, `test_power_levels`,
  `test_power_book`, `test_skill_tree`, `test_tree_detail`, the fire suites (`grep -ln FireManager tests/`),
  `test_death_kit`, `test_awareness`, and crowd_check.
- [ ] **Step 4:** Commit: `feat: Ember sets people alight; level 5 leaves a fire trail`.

### Task 3: Bots and references

- [ ] **Step 1:** Find every route and hunt bot that casts `smite` at level 5 or `ember` (`grep -rn "smite\|ember"
  tools/dev/routes`), and the refs rows they drive.
- [ ] **Step 2:** Run `bash tools/dev/refs_check.sh --only='<those families>' --jobs=4`. Re-gate any moved night
  (`tools/dev/gate.sh` / `hunt_gate.sh`, `--jobs=2`; wins at least 2/3, idle at most 45 s, with the user's existing
  idle exceptions only).
  - No filler casts.
  - No `src/` change to make a night pass.
  - An Ember click near people that now ignites a person instead of a house is acceptable if the night is still won;
    if not, the bot aims at a house honestly.
- [ ] **Step 3:** Re-record moved rows, with the reason in the commit body: `dev: refs re-recorded for Gathered Storm
  and the burning man`.

### Task 4: Gate and land

- [ ] **Step 1:** Import twice and restore `default_bus_layout.tres`. Run the suite in 5 parts, then crowd_check. A
  refs comparison for the Ruin rows and the `_none` rows must show only Task 3's rows moved.
- [ ] **Step 2:** Final whole-branch review on the most capable model; one fix wave.
- [ ] **Step 3:** Land:
  - Fetch and trial-merge against `origin/feat/Develop-Main`; stop on any conflict.
  - Ask the user before merging into Develop-Main.
  - On their word, fast-forward or merge and push. Post to #ability-changelog or #changelog per the Discord memory,
    update the Ledger, refresh #board, close the #ideas post as DONE, and update memory.
