# Fair Life Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Market Panic's fair crowd acts like people: a burning man always runs, steadied goers flinch at what happens near them, and goers stand in talking groups that stroll about the fair, with no rule change.

**Architecture:** Two small Person additions (burning beats fearless; a flinch that changes no mind) and one new helper, `FairLife`, owned by `MarketPanicDirector`, that groups goers, picks their spots and moves the groups. Goers stay on duty, so the warden rule and the town's alarm handling are untouched.

**Tech Stack:** Godot 4.7.2, GDScript. Tests: `tests/*.gd` suites run by `tests/run_part.gd`, registered in `tests/run_all.gd`.

**Spec:** `docs/superpowers/specs/2026-11-20-kak-fair-life-design.md`

## Global Constraints

- Godot: `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`. One suite: `$G --headless --path . --script res://tests/run_part.gd -- --only=<suite>` from the worktree root. New `class_name` or fresh worktree: run `$G --headless --path . --import` first.
- No rule or number change: FAIR_NEED 36, WAVE 11, WAVE_NEED 11, WAVE_AT [0, 75, 150, 220], CHAIN 45, WARDENS 3, WARD_R 5.5, FAIR_R 5.5, MARKET_CLOSE 300, Burning.BURN_FOR 4.0, HarvestDirector.GUARD_REACH 2.5 all stay.
- A god's absolute hold (`held_by_will(Person.WILL_ABSOLUTE)`) and `resists_mind()` still win over a burning run and over a flinch.
- New draws never come from `crowd._rng` or any town stream: FairLife has its own `RandomNumberGenerator`; Person's flinch uses no rng (fixed hashes of `rng.seed`, as `startle_seconds()` does).
- Talk uses the existing talk art (anim 13, `_own_art(13)`); no new art.
- Commit trailer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` (or the implementer's own model line). Never commit the generated `.uid` files of untracked tools or `grep.exe.stackdump`.
- Comments follow the file's house style (`##` doc lines, plain English, the date/version tag `(fair life, 2026-11-20)`).

## Review Focus

1. A warden flinching must never leave his post: he turns and stares, no step (Task 2 test `_warden_no_step`).
2. A burning goer must not be pulled back to his spot by `_hold_fair()` / `go_duty()` (Task 1 test `_burning_goer_runs`).
3. A flinch on someone already flinching, frightened, fleeing, dead, indoors or asleep does nothing (Task 2 test `_flinch_refused`).
4. Strolls must keep every group centre within FAIR_R of HEART and reachable by each member, and groups must not clump (Task 3 tests `_stroll_inside`, `_apart`).
5. A goer who breaks, dies or leaves drops out of his group, and a lone goer joins another group at the next stroll; a broken goer shows no talk (Task 3 test `_group_losses`).

---

### Task 1: Burning beats fearless

**Files:**
- Modify: `src/game/crowd/person.gd` (`panic()` ~line 1329, `can_take_duty()`, `send_to_post()` ~2845)
- Modify: `src/game/crowd/burning.gd` (`_free_to_run()` ~176)
- Test: `tests/test_burning.gd`, `tests/test_market_panic.gd`

**Interfaces:**
- Produces: `Person.panic()` no longer returns early for `fearless_left > 0.0` when `burning()` is true. `Person.can_take_duty()` is false while `burning()`. `Person.send_to_post()` does nothing while `burning()`. `Burning._free_to_run()` ignores `fearless_left` (still returns for `resists_mind()` and `WILL_ABSOLUTE`).

- [ ] **Step 1: Write the failing tests**

In `tests/test_burning.gd`, add `_runs_fearless(t, made)` to `run()`:
- a citizen with `fearless_left = 5.0`, `crowd.burn(p, Burning.BURN_FOR, p.ground_pos + Vector2(0.5, 0))` -> `t.check(p.mind == Person.Mind.PANIC, ...)`; after `_advance(crowd, 1.0)` his ground_pos moved more than 0.5.
- the same with `p.go_duty(p.ground_pos)` called after the burn: still `Person.Mind.PANIC` and not DUTY.
- one held by `WILL_ABSOLUTE` (use the hold the existing `_runs_free` test uses): not PANIC.
- a fearless witness within `Burning.SEE_R` with a clear line: not PANIC after one `Burning.SPREAD_EVERY + DT`.

In `tests/test_market_panic.gd`, add `_burning_goer_runs(t)` to `run()`:
- first-wave goer `g` arrived at his spot, warden 1.5 away, `Kit.run_for(s, TICK + DT)`, `t.check(d.steadied(g))`.
- `crowd.burn(g, Burning.BURN_FOR, g.ground_pos + Vector2(0.5, 0))`, `Kit.run_for(s, 1.5)`: `g.mind == Person.Mind.PANIC`, `g.ground_pos.distance_to(spot) > 1.0`, `d.broke_list().has(g)`.
- `Kit.run_for(s, Burning.BURN_FOR)`: `not g.is_alive()` and `d.count()` counted him once (count before + 1).

- [ ] **Step 2: Run to see them fail**

Run: `$G --headless --path . --script res://tests/run_part.gd -- --only=test_burning` and `--only=test_market_panic`
Expected: failures on the new checks only.

- [ ] **Step 3: Implement** the four Interfaces changes. In `panic()`, the early return becomes `if held_by_will(WILL_ABSOLUTE) or (fearless_left > 0.0 and not burning()): return`.

- [ ] **Step 4: Run** both suites plus `--only=test_harvest`, `--only=test_festival`, `--only=test_soldiers` (whichever exist). Expected: `failures=0`.

- [ ] **Step 5: Commit** `feat: a man on fire runs, steadied or not (fair life T1)`.

---

### Task 2: The flinch

**Files:**
- Modify: `src/game/crowd/person.gd`
- Create: `tests/test_flinch.gd`; register it in `tests/run_all.gd` next to `test_burning.gd`.

**Interfaces:**
- Consumes: Task 1's `panic()` order (a burning man panics; everyone else fearless flinches).
- Produces:
  - `const FLINCH_STEP := 0.5`, `const FLINCH_SECONDS := 2.0` on Person.
  - `func flinch(from: Vector2) -> void` and `func flinching() -> bool`.
  - Called from `panic()` and `observe()` in place of their `fearless_left > 0.0` early return (not for `resists_mind()`, `WILL_ABSOLUTE`, dead, inside, asleep, PANIC, FLEE, SHELTER).

Behaviour of a flinch (no mind, anchor or awareness change; no rng draw):
1. Refused while `flinching()`, dead, inside, `night_indoors`, asleep, or mind in PANIC/FLEE/SHELTER.
2. Freeze `startle_seconds()` facing `from` (reuse the startle drawing: cower within COWER_REACH, point beyond).
3. Then, only if mind is DUTY, not `soldier`, and `profile.role != CitizenProfile.Role.WATCHMAN`: walk straight to `ground_pos + (ground_pos - from).normalized() * FLINCH_STEP` if `straight_clear()` allows, else stay.
4. Stare at `from` until FLINCH_SECONDS from the start, then resume (DUTY walks back to its anchor as now).

- [ ] **Step 1: Write the failing tests** in `tests/test_flinch.gd` (set-up as `test_burning.gd`: `RD._setup()`):
- `_steadied_flinch`: DUTY citizen, `fearless_left = 5.0`, `p.panic(p.ground_pos + Vector2(1, 0), 1.0)` -> `p.flinching()`, `p.mind == Person.Mind.DUTY`, `p.fearless_left > 0.0`; after `startle_seconds() + 0.6` s his distance from the anchor is between 0.2 and FLINCH_STEP + 0.05 and he moved away from `from`; after FLINCH_SECONDS + 3.0 s he is within 0.3 of the anchor and not flinching.
- `_observe_flinch`: the same through `observe()`: flinching, mind unchanged.
- `_warden_no_step`: DUTY citizen with role WATCHMAN, fearless: flinches, never more than 0.05 from where he stood through FLINCH_SECONDS. Same for a soldier at POST with `fearless_left > 0`.
- `_flinch_refused`: a flinch while flinching does not restart it (`_flinch_left` not reset: check `flinching()` ends at the first FLINCH_SECONDS); PANIC, FLEE, dead and inside people do not flinch.
- `_absolute_wins`: held by WILL_ABSOLUTE: `panic()` neither panics nor flinches.

- [ ] **Step 2: Run** `--only=test_flinch`. Expected: fails (no `flinch`).
- [ ] **Step 3: Implement** in `person.gd` (state `_flinch_left`, `_flinch_from`; movement in the same place `_startle_left` and the duty walk are handled).
- [ ] **Step 4: Run** `--only=test_flinch`, `--only=test_burning`, `--only=test_market_panic`, `--only=test_harvest`, `--only=test_festival`. Expected: `failures=0`. The existing `_ember_breaks` checks must still pass (a flinch is not a break).
- [ ] **Step 5: Commit** `feat: steadied people flinch -- turn, step back, stare, carry on (fair life T2)`.

---

### Task 3: Talking groups that stroll

**Files:**
- Create: `src/game/mission/fair_life.gd` (`class_name FairLife extends RefCounted`)
- Modify: `src/game/mission/market_panic_director.gd` (`_send_wave()`, `_to_fair()`, `_fair_spot()`, `_hold_fair()`, `step()`, the broke/left/end paths)
- Modify: `src/game/crowd/person.gd` (`var chat_at := Vector2.INF`; `_interact_anim()`; standing facing)
- Create: `tests/test_fair_life.gd`; register in `tests/run_all.gd` after `test_market_panic.gd`.

**Interfaces:**
- Consumes: `MarketPanicDirector.HEART`, `FAIR_R`, `_reaches(p, at)`, `_walkable(at)`, `_spots`, `_broke`, `_left`; Person `go_duty()`.
- Produces (FairLife):
  - consts `GROUP_MIN := 2`, `GROUP_MAX := 4`, `RING := 0.45`, `APART := 1.6` (centre to centre, floor), `STROLL := Vector2(20.0, 40.0)`.
  - `func _init(seed: int, heart: Vector2, radius: float, reaches: Callable, walkable: Callable)`.
  - `func form(people: Array) -> void`: splits one crowd, in its order, into groups of GROUP_MIN..GROUP_MAX (a last single joins the group before), draws each a centre.
  - `func spot_of(p: Person) -> Vector2` (Vector2.INF if not grouped) and `func centre_of(p: Person) -> Vector2`.
  - `func step(delta: float) -> Array` -> the people whose spot changed this step (a group whose stroll time came).
  - `func drop(p: Person) -> void` (broken, dead, left: out of his group; a group left with one is merged into the nearest group with room at its next stroll).
  - `func groups() -> Array` (Arrays of Person) for tests.
- Director: `var life: FairLife`, made in `_begin()` with `seed = hash(crowd._rng.seed) ^ 0x7A1E` (reads the seed only, draws nothing). `_send_wave(i)` calls `life.form(waves[i] that set out)`; `_to_fair(p)` stores `life.spot_of(p)` in `_spots`; `step()` applies `life.step(delta)` by updating `_spots` (and clearing `_arrived`) for the people it returns; `_hold_fair()` sets `p.chat_at = life.centre_of(p)` once arrived and `Vector2.INF` while walking; a goer added to `_broke`/`_left`, dead or at the market's close gets `life.drop(p)` and `chat_at = Vector2.INF`.
- Person: standing DUTY with `chat_at != Vector2.INF` and no goal faces `chat_at` (as the drill_face code does) and `_interact_anim()` returns 13 if `_own_art(13)`.

Centre rule: drawn uniformly in the disk of radius FAIR_R about HEART, walkable, reachable by every member, at least APART from every other live group centre; up to 16 tries, then the try farthest from the other centres. Members stand on the ring RING round it, evenly spaced, each slot nudged to `walkable`.

- [ ] **Step 1: Write the failing tests** in `tests/test_fair_life.gd` (world as `test_market_panic.gd`'s `_world()`):
- `_groups_form`: after the first wave sets out every goer of it is in exactly one group of 2..4, the groups cover the wave, `d._spots[id] == life.spot_of(p)`.
- `_talk`: a goer arrived at his spot: `p.mind == DUTY`, `p.chat_at == life.centre_of(p)`, `p._interact_anim() == 13` (when `p._own_art(13)`), facing toward the centre.
- `_stroll_inside`: run 120 s with no casts: every group moved at least once; every centre ever drawn is within FAIR_R + 0.01 of HEART and `_reaches` for each member.
- `_apart`: at each stroll, live centres are pairwise >= APART - 0.01 (or the fallback was logged: allow at most 1 pair under per 120 s).
- `_group_losses`: kill one member of a 2-group, break another goer (`d._broke[p] = true` via the director's own path, as `test_market_panic` does): dropped, `chat_at == Vector2.INF`, no talk anim; the lone survivor is in a group of 2+ after the next stroll.
- `_rules_kept`: `d.steadied()` and `_may_break()` give the same answers as before for a goer at his group spot by a warden (copy the `_ember_breaks` set-up, with the house fire: not broken, flinching allowed).
- `_no_town_draw`: `crowd._rng.state` after `form()` + 60 s of `life.step()` alone (no crowd advance) equals before.

- [ ] **Step 2: Run** `--only=test_fair_life` (after `--import`). Expected: fails.
- [ ] **Step 3: Implement** FairLife, the director hooks and the Person talk/facing.
- [ ] **Step 4: Run** `--only=test_fair_life`, `--only=test_market_panic`, `--only=test_flinch`, `--only=test_burning`, `--only=test_festival`, `--only=test_clarity_raze` and `--only=test_mission_hints` (Market Panic's clarity block). Expected: `failures=0`. If `test_market_panic` `_hold` reads a stale spot, it must read `d._spots` after the stroll; fix the test only if the rule it checks is unchanged.
- [ ] **Step 5: Commit** `feat: the fair's goers stand in talking groups and stroll (fair life T3)`.

---

### Task 4: The mission's gate and the references

**Files:**
- Modify: `tools/dev/refs/references.tsv` (the 9 `panic_*` rows; any other row only with a stated cause)
- Modify: `docs/KAK_Version_0.11_Summary.md` (one paragraph: what moved and why) or a new `docs/KAK_Fair_Life_Notes.md`

- [ ] **Step 1: Market Panic gate.** Run `--scenario=panic --case=none|play --seed=1..3` and `--case=play --route=b` as the refs rows do (`$G --headless --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- <args>`). Pass: `play` wins >= 2 of 3 with median win time 180-240 s; `none` loses 3 of 3; longest idle <= 45 s; `b_play` wins as its rows did (won/lost per seed unchanged). If it fails, tune only FairLife's GROUP_MAX (down to 3) and APART (up to 2.2), never a rule number, and re-run.
- [ ] **Step 2: All references.** `bash tools/dev/refs_check.sh --jobs=4`. The `panic_*` rows are expected to move. Any other row that moves: find whether a burning person under fearless or a flinch is in it (run the row with the change reverted on a scratch commit); if yes, re-record with that cause written in the commit; if no, it is a bug: stop and report.
- [ ] **Step 3: Re-record** the moved rows in `references.tsv` (new checksum, same args).
- [ ] **Step 4: Suite.** `bash tools/dev/run_suite_parallel.sh 8`. Expected: failures=0 except the known perf flakes under load (the "220 inside", "horde" and decree_cage perf checks); rerun any other failure alone.
- [ ] **Step 5: Notes and commit** `test: fair life gate and re-recorded references (fair life T4)`, with the gate numbers and every moved row in the notes.
