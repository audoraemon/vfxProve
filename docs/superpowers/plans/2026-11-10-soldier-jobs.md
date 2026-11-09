# Soldier Jobs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ordinary guards leave their posts to fight fires and dig street piles until the rally; fallen buildings stay blocked ruins and drop a street pile that blocks until cleared; no pile ever seals a route; three missions see a lured guard as gone.

**Architecture:** A small `GuardJobs` board in the crowd decides who is an ordinary guard at his post, keeps "a few stay" per post group, and records who is away on which job; `FireManager` and a new `PileManager` take guards from it. `WalkGrid` keeps a fallen building's cells closed and owns pile cells and slow-crossing cells; `PileManager` chooses, draws, guards (gap rule, once per collapse) and clears piles. Missions read a new `Person.on_watch()` instead of the spawn `post`.

**Tech Stack:** Godot 4.7.2, GDScript; headless test suites (`tests/test_*.gd`, `static func run(t)`), exact references (`tools/dev/refs/*.tsv`).

**Spec:** `docs/superpowers/specs/2026-11-10-soldier-jobs-design.md` (read it first; this plan argues from it).

## Global Constraints

- Godot 4.7.2, GDScript. Deterministic at fixed fps: no wall clock, no unseeded rng, no dictionary/sort order that depends on instance ids. `sort_custom` is not stable: break every tie by `Person.stagger` (people) or by cell id `(y, x)` (cells).
- Ordinary guards only: corps NONE, standing at the post the town gave them. Mission-placed soldiers (escort charges, festival guards, procession escorts, knights, wish soldiers, director-reserved soldiers) never take a job.
- Jobs stop at the rally (`Crowd.rally()`, also the first Citadel hit). `Crowd.forgo_rally()` (leaderless town) is not a rally: guards keep taking jobs there.
- Only buildings leave a blocked ruin and drop a pile: kinds HOUSE, TEMPLE, BARRACKS, not walkable, role not `citadel`, not a Capital prop (`Structure.NOT_BUILDINGS`). Walls, gates, towers (incl. the Bell Tower, a KEEP), Citadel pieces, market stalls, crates, trees, thorns, bridges, fountains, shrines, BLOCKs keep today's fall rule.
- The gap check runs once per pile placed (once per collapse), never per frame.
- Both towns: Aldermere (100 soldiers, groups 30/30/20/20) and the Capital (~180, `CapitalCity.soldier_posts()`); both use `Crowd.post_counts` yard/walls/citadel/patrol.
- No PixelLab, no new art: piles reuse the building rubble look (`Structure._build_rubble`).
- New `class_name` files: run `"$G" --headless --path . --import` before any headless run (memory: godot-class-cache-import). `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`.
- Focused test run: `"$G" --headless --path . --script res://tests/run_part.gd -- --only=<suite name>`; expect `failures=0`. New suites are added to `tests/run_all.gd` SUITES (next to `test_fire.gd`).
- Every task before commit: `bash tools/dev/run_suite_parallel.sh 8` → `checks=N failures=0`, plus the task's `refs_check.sh --only=...` line. Stage files by name. Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- References: Task 1 must leave every reference exact. Tasks 2-7 move references on purpose (fires, collapses); they do NOT re-record per task: each task runs its sentinel `refs_check` and writes the mismatching names in its commit body ("moves on purpose: <feature>"). Task 8 re-records all of them once, with reasons and the win/loss flip list. Outcome rows (`outcome:`) must never break: one that does is a bug or a scripted-policy fix in that task.
- Numbers to tune (one place each): `GuardJobs.SHARE = 0.5`, `GuardJobs.GROUP_KEEP = 1`, `Person.WATCH_REACH = 1.0`, guard reach = `FireManager.RECRUIT_REACH` (10.0) for fires and `PileManager.REACH = 10.0` for piles, `PileManager.DIGGERS = 2`, `PileManager.SECONDS = 20.0` (with two diggers; one digger half rate), `PileManager.MAX_CELLS = 3`, `PileManager.EVERY = 1.0` (assign tick), `PileManager.LOCAL_CELLS = 16` (local detour search box half-size), `WalkGrid.SLOW_CROSSING = 0.3`, dig reach = `RescueManager.DIG_REACH` (1.2).

## Review Focus

1. A guard held by the god (whisper, confuse, lure) while on a job must come back to his job or his post, never stand at a cleared pile's spot for ever (anchor ≠ post makes him permanently ineligible) → Task 6 test `_held_digger`.
2. A guard taken mid-job by a mission director (`go_duty`, `send_to_post`) or killed: the job record and `Pile.diggers` drop him, and the pile is re-manned at the next tick; no stale `assist_fire` → Task 6 test `_taken_digger`, Task 2 test `_rally_clears`.
3. Many falls at once (Cinderfall, a quake): a second pile next to the first, or on a cell the first left as the gap; the sum of piles must still leave a route → Task 5 test `_two_piles`.
4. A wall, tower, stall or gate falling next to a ruin or a pile: `WalkGrid._on_destroyed`'s area re-stamp must not reopen the ruin's or the pile's cells → Task 3 test `_neighbour_fall`, Task 4 test `_pile_survives_neighbour`.
5. A new act / mission restart (`Crowd.clear()`, `mission.gd` teardown): piles, slow cells, guard-job records and the mission hooks are reset; no Callable to a freed director is called → Task 1 test `_hooks_cleared`, Task 4 test `_clear_resets`.

---

## File map

| File | Responsibility | Tasks |
|---|---|---|
| `src/game/crowd/guard_jobs.gd` (new, `class_name GuardJobs`) | who is an ordinary guard at his post, group keep, picking, job records, close at rally | 1, 2, 6 |
| `src/game/crowd/pile_manager.gd` (new, `class_name PileManager`) | pile choice, place/clear, gap rule, drawing layer, diggers | 4, 5, 6 |
| `src/game/crowd/person.gd` | `town_post`, `post_group`, `WATCH_REACH`, `on_watch()`, `back_to_post()`, slow-cell pace | 1, 5 |
| `src/game/crowd/crowd.gd` | create the two managers, posts/groups, rally close, mission hooks, `clear_ground()`, `route_points()`, step order | 1-6 |
| `src/game/crowd/fire_manager.gd` | guard phase in `_recruit` | 2 |
| `src/game/crowd/rescue_manager.gd` | idle squads to piles after the rally | 6 |
| `src/environment/structure.gd` | `leaves_ruin()`, `NOT_BUILDINGS`, `rubble_polys()` | 3, 4 |
| `src/environment/environment_field.gd` | `blocked()` counts ruins | 3 |
| `src/game/town/walk_grid.gd` | ruins stay closed, pile cells, slow cells, `pace_at()` | 3, 4, 5 |
| `src/game/mission/mission_director.gd`, `src/game/mission.gd`, `src/game/rules.gd` | register/clear mission hooks; `route_points()` virtual | 1, 5 |
| `src/game/mission/heretic_hunt_director.gd`, `informer_director.gd`, `heart_of_faith_director.gd` | watch from where the guard is | 7 |
| tests: `test_guard_jobs.gd`, `test_ruins.gd`, `test_piles.gd`, `test_watch_posts.gd` (new); `test_corps.gd`, `test_walk_grid.gd`, `test_rescue.gd`, `test_soldier_minds.gd` (changed/checked) | | |
| `tools/dev/refs/*.tsv` | re-recorded once | 8 |

---

### Task 1: Guard bookkeeping (no behaviour change)

**Files:**
- Create: `src/game/crowd/guard_jobs.gd`
- Modify: `src/game/crowd/person.gd` (fields near `post` ~195; new funcs near `send_to_post` ~1821), `src/game/crowd/crowd.gd` (`setup` ~285, `_assign_corps` ~602, `_walk_loops` ~667, `_investigate` ~1634, `rally` ~1668, `clear`), `src/game/mission/mission_director.gd` (`setup` ~47), `src/game/mission.gd` (teardown sites ~290 and ~535), `src/game/rules.gd` (~633)
- Test: `tests/test_guard_jobs.gd` (new), add to `tests/run_all.gd`

**Interfaces:**
- Produces (Person): `var town_post := Vector2.INF` (the post the town gave him: spawn post, or his current loop point; never set by a director); `var post_group := -1` (0 yard, 1 walls, 2 citadel, 3 patrol; -1 for `add_soldier()` soldiers and citizens); `const WATCH_REACH := 1.0`; `func on_watch() -> bool` (alive soldier, mind POST or HOLD, `not held_by_god()`, `anchor.is_equal_approx(post)`, `ground_pos.distance_to(anchor) <= WATCH_REACH`); `func back_to_post() -> void` (held by the god with a saved hold: rewrite the saved hold to `_held_mind = POST`, `_held_anchor = post`, `_held_hurrying = false`; else `send_to_post(post)`).
- Produces (Crowd): `var guard_jobs: GuardJobs` (made in `setup()` beside `fires`); `var mission_holds: Array[Callable] = []` (each `func(p: Person) -> bool`); `var mission_points: Array[Callable] = []` (each `func() -> Array[Vector2]`; used from Task 5); `func held_by_mission(p: Person) -> bool` (any valid callable says true; invalid callables skipped); `func clear_mission_hooks() -> void`.
- Produces (GuardJobs): `const SHARE := 0.5`, `const GROUP_KEEP := 1`; `func setup(crowd: Crowd) -> GuardJobs`; `func is_open() -> bool`; `func at_post(p: Variant) -> bool`; `func eligible(p: Variant) -> bool` (`at_post` and not on a job); `func free_near(at: Vector2, reach: float) -> Array[Person]` (eligible within reach, nearest first, ties by `stagger`); `func pick(at: Vector2, reach: float, on_here: int, cap: int) -> Array[Person]`; `func take(p: Person, job: Variant) -> void`; `func job_of(p: Variant) -> Variant` (null when none); `func on_job(p: Variant) -> bool`; `func release(p: Variant) -> void`; `func prune() -> void`; `func close() -> void`; `func clear() -> void`.
- Produces (MissionDirector): `func _holds_soldier(p: Person) -> bool` (`reserved.has(p) or busy(p)`), registered in `setup()` with `c.mission_holds.append(_holds_soldier)`.

Rules the implementer cannot guess:
- `at_post(p)`: valid, alive, `soldier`, `corps == NONE`, not `inside`, `town_post != INF`, `post.is_equal_approx(town_post)`, `p.on_watch()`, `not p.has_goal()`, not `crowd._looking(p)`, not `crowd.escorts.guarding(p)` (when escorts exists), not `crowd.held_by_mission(p)`, `post_group >= 0`.
- `pick()`: `free := free_near(at, reach)`; `want := mini(ceili(float(on_here + free.size()) * SHARE) - on_here, cap)`; walk `free` in order, taking one only while its group's `at_post` count (counted once at the start of the call over all soldiers, decremented as you take) stays `>= GROUP_KEEP` after he leaves. Returns the taken (does not call `take()`).
- `post_group` in `_assign_corps()`: index ranges of `post_counts` (yard, walls, citadel, patrol); soldiers past the sum (filled in the yard) get 0. Set `town_post = post` there too. `_walk_loops()` sets `p.town_post = p.post` whenever it moves the post.
- `prune()`: drop a record whose person is invalid, dead, or no longer on that job (fire: `mind != ASSIST or assist_fire != job`; pile: see Task 6) — except while `held_by_god()` (keep it; Review Focus 1). Never sends anyone anywhere.
- `close()`: `open = false`; every fire-job holder `stand_down()`; every pile-job holder released from its pile (Task 6 fills this in; in Task 1 records can only be fire jobs); records cleared. `Crowd.rally()` calls `guard_jobs.close()` right after `_rallied = true`, before the ring loop. `forgo_rally()` does not.
- `_investigate()` pool also requires `not guard_jobs.on_job(p)`.
- `mission.gd` (both teardown sites) and `rules.gd:633` call `crowd.clear_mission_hooks()` after the director's teardown (guard `is_instance_valid`/null crowd). `Crowd.clear()` also calls it and `guard_jobs.clear()`.

- [ ] **Step 1: Write the failing tests** in `tests/test_guard_jobs.gd` (crowd built like `test_corps._crowd()`):
  - `_posts_and_groups`: every spawned soldier has `town_post == post` and `post_group == expected group from post_counts`; `add_soldier()` gives `post_group == -1`; Aldermere group sizes are 30/30/20/20 by `post_group` count.
  - `_on_watch`: a soldier at spawn → `on_watch()`; `send_to_post(post + Vector2(5, 0))` → false; `assist(house, true)` → false; `confuse(3.0)` → false.
  - `_eligible`: an ordinary NONE guard at spawn → `eligible`; RESCUE/MARSHAL/ESCORT → false; a guard with `post` overwritten (`post = post + Vector2(3,0); anchor = post`) → false; a guard covered by `crowd.mission_holds.append(func(p): return p == g)` → false; an investigator (`crowd._investigate(at)`) → false.
  - `_pick_share`: with `n := free_near(c, 10.0).size()` for a point `c` in the barracks yard, `pick(c, 10.0, 0, 1000).size() == ceili(n * 0.5)`; `pick(c, 10.0, 0, 2).size() <= 2`.
  - `_group_keep`: near the Citadel, set all but 2 citadel-group guards to `send_to_post(post + Vector2(0.0, 6.0))` (not at post); `pick(citadel_origin, 10.0, 0, 1000)` takes exactly 1 citadel-group guard.
  - `_hooks_cleared`: a hook registered, `crowd.clear_mission_hooks()` → `held_by_mission(g) == false`; a Callable whose object was freed is skipped without error.
  - `_close`: `take(g, house)` after `g.assist(house, true)`; `crowd.rally()` → `not is_open()`, `not on_job(g)`, `g.assist_fire == null`, `g.mind == RALLY`.
- [ ] **Step 2: Run** `"$G" --headless --path . --import` then `--only=test_guard_jobs`. Expected: FAIL (GuardJobs undefined / fields missing).
- [ ] **Step 3: Implement** the Interfaces above.
- [ ] **Step 4: Run** `--only=test_guard_jobs`, `--only=test_corps`, `--only=test_soldier_minds`. Expected: `failures=0`.
- [ ] **Step 5: Gate** `bash tools/dev/run_suite_parallel.sh 8` → `failures=0`; `bash tools/dev/refs_check.sh --only='^(digest|crowd_check|hunt_play_1|heart_play_1|informer_play_1|capital_tax_none_1)$'` → all OK (no behaviour change is allowed here).
- [ ] **Step 6: Commit** `feat: guard job board (ordinary guards at their posts, post groups, mission hooks)`.

### Task 2: Guards at fires

**Files:**
- Modify: `src/game/crowd/fire_manager.gd` (`_recruit` ~194)
- Modify: `tests/test_corps.gd` (~106-123)
- Test: `tests/test_guard_jobs.gd` (fire section)

**Interfaces:**
- Consumes: `GuardJobs.pick/take/prune/is_open/job_of`, `FireManager.enlist(p, s)`.
- Produces: `func guards_on(s: Structure) -> int` in FireManager (responders on `s` that are guard-job holders).

Rules:
- `_recruit()` keeps its early return (stage < `profile.fire_from`, ≥ EVACUATION, no fires). Per fire, the shared "fightable" checks (not veiled, not cursed, below `ABANDON`, a water point) gate both phases. Citizen phase: unchanged, but its cap count (`crew.size() >= most`) counts responders **excluding guard-job holders**, so `fire_crew` means citizens as today. Guard phase (only `if _crowd.guard_jobs.is_open()`): `guard_jobs.prune()` once per `_recruit`, then `pick(s.center(), RECRUIT_REACH, guards_on(s), 1 << 20)`, each `enlist(p, s)` then `take(p, s)` if `p.mind == ASSIST`.
- Stand-down paths are today's (`_put_out`, `_tend_responders`: out, fallen, `ABANDON`, evacuation since `assist_stays` is false) → `stand_down()` → `send_to_post(post)`; the record then fails `prune()` and is dropped.
- `Person.assist()` keeps its soldier gate (`soldier and not force`): ordinary guards come only through the brigade.

- [ ] **Step 1: Write the failing tests** (`tests/test_guard_jobs.gd`, `_fires`):
  - set `crowd.alarms.stage = crowd.profile.fire_from`; ignite the house nearest the barracks yard; `n := guard_jobs.free_near(house.center(), FireManager.RECRUIT_REACH).size()`; `crowd.fires._recruit()` → corps-NONE ASSIST guards on that fire `== ceili(n * 0.5)` (n > 0 checked); citizens on it `<= profile.fire_crew`; every post group still has `>= GROUP_KEEP` guards `at_post`.
  - no mission-held or corps soldier is on the fire (a guard sent to a spot, a post-overwritten guard, a `mission_holds` guard, RESCUE/MARSHAL/ESCORT/KNIGHT made with `MissionDirector`-style `corps = KNIGHT`).
  - douse until out (`fires.douse(house)` loop) → each of those guards `mind == POST and anchor == post`, and `not guard_jobs.on_job(g)` after `prune()`.
  - `_rally_clears`: a second fire with guards on it; `crowd.rally()` → no corps-NONE soldier in ASSIST, none with `assist_fire != null`; a new `_recruit()` adds no guard.
  - `_unprepared`: `ResponseProfile.for_tier(UNPREPARED)`, `crowd._on_stage(CITY_EMERGENCY, "")`, stage set, `_recruit()` → no guard on a fire (rally came first).
  - `_capital_fire`: `test_capital_people._build()`, ignite a burning capital plot (`FireManager.burns`) nearest the yard, stage `fire_from`, `_recruit()` → ≥ 1 corps-NONE guard in ASSIST; every group keeps ≥ 1 at post.
- [ ] **Step 2: Change `tests/test_corps.gd` ~119**: `soldiers[0]` is a RESCUE soldier: relabel the check "a rescue soldier is not sent to a fire unasked" (still true); add after it: an ordinary corps-NONE guard (first `post_group == 0` NONE soldier) near a fire at `fire_from` IS taken by `crowd.fires._recruit()` before the rally ("an ordinary guard joins the brigade before the rally"), and after `crowd.rally()` a fresh fire takes none.
- [ ] **Step 3: Run** `--only=test_guard_jobs`, `--only=test_corps`: FAIL.
- [ ] **Step 4: Implement** the guard phase.
- [ ] **Step 5: Run** `--only=test_guard_jobs`, `--only=test_corps`, `--only=test_fire`, `--only=test_rescue` (lines ~137-140: `>= RESCUE_SQUAD` should still hold with guards on the crew; change only if it fails, and say why in the commit), `--only=test_soldier_minds` (~505-519). Expected `failures=0`.
- [ ] **Step 6: Gate** suite; `refs_check.sh --only='^(digest|crowd_check|hunt_play_1|panic_play_1|capital_tax_none_1)$'` — mismatches allowed only where fires burn before the rally; list them in the commit body.
- [ ] **Step 7: Commit** `feat: ordinary guards join the fire brigade until the rally; a few stay per post group`.

### Task 3: Ruins stay blocked; people pushed out

**Files:**
- Modify: `src/environment/structure.gd` (setup ~217, new `leaves_ruin()`), `src/environment/environment_field.gd` (`blocked` ~276), `src/game/town/walk_grid.gd` (`_apply`, `_reopen`, `_on_destroyed`), `src/game/crowd/crowd.gd` (`_on_structure_destroyed` ~1922, new `clear_ground`)
- Modify: `tests/test_walk_grid.gd` (~37-41)
- Test: `tests/test_ruins.gd` (new)

**Interfaces:**
- Produces (Structure): `const NOT_BUILDINGS := [&"gpt_handcart", &"gpt_wagon", &"gpt_noticeboard", &"gpt_tiltbarrier", &"gpt_beehives", &"gpt_pens"]`; `var _ruin_blocks := false` computed once in `setup()`; `func leaves_ruin() -> bool` (kind in [HOUSE, TEMPLE, BARRACKS], not `walkable`, `role != &"citadel"`, not (`role == CapitalPlots.ROLE` and `art_tag in NOT_BUILDINGS`)).
- Produces (WalkGrid): `func _free_ground(s: Structure) -> void` (today's `_on_destroyed` body after the bridge branch); `_on_destroyed` = bridge rule, else `if s.leaves_ruin(): return` (cells stay closed), else `_free_ground(s)`; `_reopen(s)` (structure removed) always `_free_ground(s)` (a removed ruin opens); `_apply(s)` stamps a ruin too (`s.destroyed and not s.leaves_ruin()` → skip); in `_free_ground`'s neighbour re-apply loop a destroyed neighbour that `leaves_ruin()` is re-applied too.
- Produces (EnvironmentField): `blocked()` treats `s.destroyed and s.leaves_ruin()` as standing.
- Produces (Crowd): `func clear_ground(r: Rect2) -> int` — every citizen and soldier, alive, not `inside`, whose `ground_pos` is in `r` or on a non-walkable cell inside `r`, is set to `_grid.nearest_walkable(ground_pos)` (left alone if INF), `_target = ground_pos`, and re-planned (`set_goal(goal())` when it has a goal); returns how many moved. `_on_structure_destroyed` calls `clear_ground(WalkGrid.solid_rect(s.footprint))` when `s.leaves_ruin()` (after the existing reactions). Trapped and sheltered people are `inside` and untouched (RescueManager still frees them at the edge via `_spot_near`).

- [ ] **Step 1: Write the failing tests** (`tests/test_ruins.gd`):
  - `_kinds`: `leaves_ruin()` true for an Aldermere house, the temple, the barracks, a farm barn; false for a tower, a wall run, a gate, the Bell Tower, a market stall, a tree, a fountain, the bridge, a Citadel part, a `Kind.BLOCK`/`SHRINE` made with `env.add_structure`.
  - `_temple_stays`: destroy the temple → `not grid.walkable(TownLayout.TEMPLE.get_center())` and `env.blocked(TownLayout.TEMPLE.get_center())`; `restore()` → still not walkable.
  - `_others_open`: a market stall and a tower fall → their centres walkable (today's rule); the gate falls → walkable.
  - `_neighbour_fall`: a house next to another structure (find a pair whose `solid_rect`s, grown by `WalkGrid.CELL`, intersect): destroy the house, then the neighbour → every cell centre in the house's `solid_rect` still not walkable.
  - `_pushed`: a citizen placed at a point inside the house's `solid_rect` (outside its footprint, inside the BODY margin); destroy → `grid.walkable(p.ground_pos)`; a citizen with `inside = true` at the centre keeps its `ground_pos`.
  - `_capital`: in the Capital, a `gpt_tenement` (or any HOUSE-kind plot) falls → centre not walkable; a `gpt_wagon` falls → its centre walkable; `gpt_alleysteps` `leaves_ruin() == false`.
- [ ] **Step 2: Change `tests/test_walk_grid.gd` ~37-41**: "the temple's rubble can be walked over" becomes `not grid.walkable(...)` with label "a fallen temple stays a blocked ruin (soldier jobs, decision 4)"; add "a fallen wall tower opens its ground" (destroy a `role == &"tower"` structure → its centre walkable).
- [ ] **Step 3: Run** `--only=test_ruins`, `--only=test_walk_grid`: FAIL.
- [ ] **Step 4: Implement.**
- [ ] **Step 5: Run** both, plus `--only=test_environment` (its BLOCK rubble stays walkable), `--only=test_rescue`, `--only=test_engineers`, `--only=test_crowns_bread`, `--only=test_solaris`, `--only=test_capital_evac`, `--only=test_shelter`; a suite asserting a fallen *building*'s ground opens is changed on purpose (say which in the commit body); anything else failing is a bug.
- [ ] **Step 6: Gate** suite; `refs_check.sh --only='^(digest|crowd_check|hunt_play_1|bread_play_1|capital_tax_none_1)$'`; list moved names.
- [ ] **Step 7: Commit** `feat: fallen buildings stay blocked ruins; people standing in a falling footprint step out`.

### Task 4: Street piles (choose, place, block, draw)

**Files:**
- Create: `src/game/crowd/pile_manager.gd`
- Modify: `src/environment/structure.gd` (`_build_rubble` ~1440 → `rubble_polys`), `src/game/town/walk_grid.gd` (pile cells), `src/game/crowd/crowd.gd` (setup, spawn layer, `_on_structure_destroyed`, `_advance` step after `rescue.step`, `clear`)
- Test: `tests/test_piles.gd` (new)

**Interfaces:**
- Produces (Structure): `static func rubble_polys(area: Rect2, origin: Vector2, pal: Array, count: int, rng: RandomNumberGenerator) -> Array` (each `[PackedVector2Array screen poly relative to origin, Color]`; the exact rng call order of today's `_build_rubble`: x, y, size, then 5 × (randf, randf_range), then randi for the colour). `_build_rubble()` becomes `_rubble = rubble_polys(footprint.grow(0.25), _base, _palette(), count, rng)` with today's `count`.
- Produces (WalkGrid): `var _piles := {}` (Vector2i → true); `func set_pile(ids: Array[Vector2i], on: bool) -> void` (stamps each cell solid/open, records/erases, `version += 1`); `func is_pile(id: Vector2i) -> bool`; `_free_ground()` ends by re-closing every pile cell in its `area`.
- Produces (PileManager): inner `class Pile` with `var cells: Array[Vector2i]`, `var gap := NO_GAP` (`const NO_GAP := Vector2i(-2147483648, -2147483648)`; Task 5), `var site: Structure`, `var work := 0.0` (0..1), `var diggers: Array = []`, `var pieces: Array = []`; `const MAX_CELLS := 3`; `var piles: Array[Pile] = []`; `func setup(crowd: Crowd, env: EnvironmentField, grid: WalkGrid) -> PileManager`; `func attach(parent: Node2D) -> void` (makes the draw layer once); `func cells_for(s: Structure) -> Array[Vector2i]`; `func place(cells: Array[Vector2i], site: Structure = null) -> Pile` (null when `cells` is empty); `func on_fall(s: Structure) -> void` (`if s.leaves_ruin(): place(cells_for(s), s)`); `func clear_pile(p: Pile) -> void`; `func step(delta: float) -> void` (Task 6 fills digging; here nothing); `func clear() -> void` (opens every pile cell, empties `piles`, redraws).
- Produces (Crowd): `var piles: PileManager` (made in `setup()` after `fires`; `attach(_parent)` in `spawn()` beside the drawers; `piles.on_fall(s)` from `_on_structure_destroyed` after `clear_ground`; `piles.step(delta)` in `_advance` right after `rescue.step`; `piles.clear()` in `clear()`).

Rules:
- `cells_for(s)`: n = 3 if the footprint's longer side ≥ 2.0, 2 if ≥ 1.0, else 1. For each side of `WalkGrid.solid_rect(s.footprint)` in the order +y, +x, -y, -x, score = walkable cells in the band 3 cells deep outward along that whole side; take the highest score (first in order on a tie). From the walk-grid cell just outside that side's midpoint, step outward up to n cells; stop at the first cell that is not walkable, already a pile, inside any walkable structure's footprint (gates, bridges, fields, passages, over-water sets) or a river rect, or holding one of `City.current().exits()` / `gate_exits()` (snapped by `world_to_id`). Spec "door side": no building in either town carries a door, so the widest-street side is always used.
- `place()`: drop cells that are no longer walkable; `grid.set_pile(cells, true)`; `crowd.clear_ground(rect of each cell)`; build `pieces` with `site.rubble_polys(cells_rect.grow(0.1), Vector2.ZERO, site._palette(), clampi(cells.size() * 5, 5, 15), rng)` mapped to absolute screen points (`Iso.ground_to_screen`), or a stone palette when `site` is null; append; redraw.
- Drawing: a `PileLayer extends Node2D` (inner class), `z_index = -3` like the ground drawer, child of the crowd's parent; draws every pile's visible pieces with `draw_colored_polygon`; `queue_redraw()` only when a pile is placed, cleared, or its visible piece count (`ceili(pieces.size() * (1.0 - work))`) changes — never every frame.
- The PileManager rng is seeded `seed + 53` in `setup()` (no other rng consumed).

- [ ] **Step 1: Write the rubble guard test first, against today's code** (`tests/test_piles.gd`, `_rubble_same`): a house made with a fixed seed is destroyed; record `_rubble.size()` and the first poly's first point and colour as literals; run it → PASS on the old code. This pins `rubble_polys`'s rng order.
- [ ] **Step 2: Write the failing tests:**
  - `_pile_drops`: a town house with a street on one side (pick the first `role == &"house"` whose `cells_for()` is non-empty) falls → `crowd.piles.piles.size() == 1`; its cells are 1..3, each was walkable before the fall and is not after, each `grid.is_pile`, the first touches the house's `solid_rect` grown by one cell, they form a straight outward line.
  - `_no_pile`: a tower, a stall, a tree fall → no pile.
  - `_cells_valid_everywhere`: for every building in Aldermere and in the Capital (`leaves_ruin()`), every cell of `cells_for(s)` is walkable, not in any walkable structure's footprint, not in a river rect, and `size() <= 3`; at least 80% of buildings get ≥ 1 cell (print the share).
  - `_pile_pushes`: a citizen standing on the first pile cell (computed with `cells_for` before the fall) ends on a walkable cell.
  - `_pile_survives_neighbour`: a pile, then a structure beside it falls (or `grid._free_ground()` on an area covering it) → pile cells still not walkable.
  - `_clear_resets`: `clear_pile()` → cells walkable, `not is_pile`; a second pile then `crowd.piles.clear()` → walkable, `piles.is_empty()`.
  - `_drawn`: a placed pile has `pieces.size() >= 5`; stepping the crowd 60 frames does not call the layer's redraw more than once (count via a `redraws` counter on PileLayer).
- [ ] **Step 3: Run** `--import`, `--only=test_piles`: FAIL (except `_rubble_same`).
- [ ] **Step 4: Implement.**
- [ ] **Step 5: Run** `--only=test_piles`, `--only=test_ruins`, `--only=test_building_kinds`, `--only=test_walk_grid`: `failures=0`.
- [ ] **Step 6: Gate** suite; `refs_check.sh --only='^(digest|crowd_check|hunt_play_1|panic_play_1|capital_tax_none_1)$'`; list moved names.
- [ ] **Step 7: Commit** `feat: a fallen building drops a street pile that blocks the way`.

### Task 5: The gap rule and the slow crossing

**Files:**
- Modify: `src/game/town/walk_grid.gd`, `src/game/crowd/pile_manager.gd` (`place`), `src/game/crowd/person.gd` (`_mind_speed` ~676), `src/game/crowd/crowd.gd` (`route_points`), `src/game/mission/mission_director.gd` (`route_points` virtual + registration)
- Test: `tests/test_piles.gd` (gap section)

**Interfaces:**
- Produces (WalkGrid): `const SLOW_CROSSING := 0.3`; `var _slow := {}` (Vector2i → factor); `func set_slow(id: Vector2i, factor: float) -> void` (factor < 1 records it and sets `grid.set_point_weight_scale(id, 1.0 / factor)`; factor 1.0 erases and resets the weight to 1.0); `func pace_at(g: Vector2) -> float` (1.0 at once when `_slow` is empty); `func reaches(from: Vector2, to: Vector2) -> bool` (`not path(from, to).is_empty()`).
- Produces (Person): `_mind_speed()` multiplies by `grid.pace_at(ground_pos)` when `grid != null`.
- Produces (Crowd): `func route_points() -> Array[Vector2]`: `City.current().exits()`, `gate_exits()`, each `_town.gates` centre, `citadel_origin()` when not INF, then every valid `mission_points` callable's points; each snapped with `_grid.nearest_walkable` (INF dropped).
- Produces (MissionDirector): virtual `func route_points() -> Array[Vector2]` (default: each `tags()` entry's `at`, then each `reserved_places` centre); registered in `setup()` with `c.mission_points.append(route_points)`.
- Produces (PileManager): `const LOCAL_CELLS := 16`; `var gap_checks := 0` (counts key-point checks); `func _seals(cells: Array[Vector2i]) -> bool`; in `place()`, after closing the cells: if `_seals(cells)`, try each cell in order (nearest the pile's middle first, ties by id) as the gap: reopen it with `set_pile([c], false)` + `set_slow(c, SLOW_CROSSING)`; keep the first that makes `_seals` false; if none does, open all the cells as slow and keep the pile drawn (never seal). `clear_pile()` resets the gap's slow factor.

The check (decides what nothing else does):
```
_seals(cells):
  # 1. local detour: the open 8-neighbour cells around the pile, inside a box of LOCAL_CELLS cells around it,
  #    flood-filled (BFS, box-bounded) from the first one: all of them reached -> false (nothing can be cut).
  # 2. else gap_checks += 1; ref := crowd.route_points()[0..]: the first point reachable with the cells OPEN
  #    (computed before closing: `before` = the set of route points reachable from ref);
  #    with the cells closed, any point of `before` not reachable from ref -> true.
```
Compute `before` in `place()` before stamping (step 2 needs it only when step 1 fails, so do step 1 on the closed grid, and if it fails, briefly reopen to take `before`, close, and compare). A ruin is never checked: its cells were closed while it stood (Task 3), so it cannot cut a route that existed.

- [ ] **Step 1: Write the failing tests** (`tests/test_piles.gd`):
  - `_seal_bridge`: Aldermere; cells = every walkable cell in the row just north of `town.bridge.footprint` (y one cell above its top, x across its width plus the street either side until a solid cell). `crowd.piles.place(cells)` → exactly one of them walkable, its `grid.pace_at(cell centre) == WalkGrid.SLOW_CROSSING`, `grid.grid.get_point_weight_scale(id)` ≈ `1.0 / 0.3`, and `grid.reaches(TownLayout.TEMPLE.get_center() + Vector2(0, 3), TownLayout.EXITS[0])`; `clear_pile()` → all walkable and `pace_at == 1.0`.
  - `_detour_no_gap`: a 1-cell pile in an open square (market square centre) → `gap == NO_GAP`, `gap_checks` unchanged.
  - `_two_piles`: after `_seal_bridge`'s pile, a second pile on the remaining open cells of that row → a route to `EXITS[0]` still exists.
  - `_mission_point`: `crowd.mission_points.append(func() -> Array[Vector2]: return [pt])` appears in `crowd.route_points()`; `clear_mission_hooks()` removes it.
  - `_slow_pace`: a soldier on the gap cell: `_mind_speed()` ≈ 0.3 × the same call one cell off it.
  - `_once_per_fall`: `gap_checks` after one `place()` that needed step 2 is +1; 120 `crowd.advance(1/60)` frames later it is unchanged.
- [ ] **Step 2: Run** `--only=test_piles`: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `--only=test_piles`, `--only=test_walk_grid`, `--only=test_crowd`, `--only=test_capital_evac`: `failures=0`.
- [ ] **Step 5: Gate** suite; same refs sentinel as Task 4; list moved names.
- [ ] **Step 6: Commit** `feat: the gap rule: a pile never seals the last route; a slow crossing is left`.

### Task 6: Clearing piles (guards, then idle rescue squads)

**Files:**
- Modify: `src/game/crowd/pile_manager.gd` (`step`, assign, dig), `src/game/crowd/guard_jobs.gd` (pile records in `prune`/`close`), `src/game/crowd/rescue_manager.gd` (`_assign` ~107)
- Test: `tests/test_piles.gd` (clearing section)

**Interfaces:**
- Consumes: `GuardJobs.pick/take/release/job_of/prune`, `Person.dig_shown`, `Person.back_to_post()`, `RescueManager.DIG_REACH`.
- Produces (PileManager): `const DIGGERS := 2`, `const SECONDS := 20.0`, `const REACH := 10.0`, `const EVERY := 1.0`; `func dig_spots(p: Pile) -> Array[Vector2]` (walkable cells 4-adjacent to the pile's cells, nearest the pile middle first, ties by id; centres); `func needing_hands() -> Array[Pile]` (fewer than DIGGERS living diggers); `func take_squad(crew: Array) -> bool` (the nearest pile needing hands to `crew[0]` gets the whole crew; false when none); `func digging(p: Variant) -> bool`; `func release(p: Variant) -> void` (removes from its pile's diggers; no walk).
- GuardJobs `prune()` pile rule: drop the record when the person is no longer `mind == POST` with `anchor` on one of that pile's dig spots (unless `held_by_god()`); `close()` releases pile holders with `piles.release(p)` (the rally then walks them).

Rules:
- `step(delta)`: every EVERY seconds assign; every frame dig. Assign: guards only while `guard_jobs.is_open()` and `crowd.alarms.stage >= crowd.profile.fire_from` and `< EVACUATION`: for each pile in placement order, `pick(centre, REACH, guards_on_pile, DIGGERS - living_diggers)`; each taken: `take(p, pile)`, append to `pile.diggers`, `send_to_post(dig_spots[k % size])` at a walk (k = his index among the pile's diggers). Rescue squads are put on piles by RescueManager (below), never by this assign.
- Dig: a digger counts when alive, `not has_goal()` and within `RescueManager.DIG_REACH` of his spot; he gets `dig_shown = 0.3`. `work += delta / SECONDS * mini(counting, DIGGERS) / DIGGERS`. At `work >= 1.0`: `clear_pile()`; each guard digger `guard_jobs.release(p)` then `p.back_to_post()`; each rescue digger `send_to_post(post)`; redraw when the visible piece count drops.
- Prune each assign: diggers invalid, dead, or (not `held_by_god()` and not POST on a dig spot of this pile) are removed from `pile.diggers` and from `guard_jobs`.
- RescueManager `_assign()`: the trapped-site search also treats a squad whose members are pile diggers as free (trapped first: `release` them from the pile before sending). For a squad with no site and not at a fire: `fire` as today (`null` when evacuating); else, only when `_crowd._rallied` (guards' jobs are over) — including during EVACUATION — `_crowd.piles.take_squad(crew)`; else back to posts as today. A squad already digging a pile is left alone. Order: trapped > fire > pile.

- [ ] **Step 1: Write the failing tests** (`tests/test_piles.gd`):
  - `_guards_dig`: a pile by the barracks yard (place one with `cells_for` of the yard-nearest house), stage `fire_from`; `crowd.piles.step(1.0)` → `diggers.size() == mini(DIGGERS, ceili(n * 0.5))` with `n` the eligible guards near it (assert n ≥ 4 so 2), all corps NONE; teleport them to their goals; step 60 × (1/60) → each `dig_shown > 0`, their pose code anim is 15 when the art has it; step until `SECONDS` (+1 s slack) → cells walkable, `piles.is_empty()`, each digger `mind == POST and anchor == post`.
  - `_one_digger`: the same with one digger: still blocked at 21 s, clear by 41 s.
  - `_too_early`: stage below `fire_from` → no diggers after 3 s.
  - `_fire_first`: a fire and a pile both near the yard; `fires._recruit()` then `piles.step(1.0)` → guards on the fire `== ceili(n0 * 0.5)` where `n0` was the eligible count before either; no guard is both.
  - `_held_digger`: a digger confused (`confuse(5.0)`) while digging; the pile is cleared by the other (or force `work = 1.0`); let 40 s pass → he is `mind == POST`, `anchor == post`.
  - `_taken_digger`: a digger `go_duty(elsewhere)` → after the next assign he is not in `diggers`, `not guard_jobs.on_job(him)`, and a new guard was taken.
  - `_squads_after_rally`: `crowd.rally()`; no guard is a digger; `crowd.rescue.step(0.6)` → a squad's members are diggers of the pile; it clears; with `crowd.alarms.stage = EVACUATION` a new pile still gets a squad.
  - `_trapped_first`: a squad on a pile; `rescue.trap([citizen], house)` → after `rescue.step(0.6)` that squad's `site == house` and none of its members dig the pile.
  - `_capital_pile`: Capital build, a pile by the yard, stage `fire_from` → 2 corps-NONE diggers, and it clears.
- [ ] **Step 2: Run** `--only=test_piles`: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `--only=test_piles`, `--only=test_guard_jobs`, `--only=test_rescue`, `--only=test_soldier_minds`, `--only=test_corps`: `failures=0`.
- [ ] **Step 5: Gate** suite; refs sentinel as Task 4 plus `'^(festival_b_play_1|procession_play_1)$'` (mission soldiers must not dig; outcome rows must hold).
- [ ] **Step 6: Commit** `feat: guards dig street piles clear until the rally; idle rescue squads after it`.

### Task 7: Missions see the empty post

**Files:**
- Modify: `src/game/mission/heretic_hunt_director.gd` (`_watched` ~117), `src/game/mission/informer_director.gd` (`_watched` ~181), `src/game/mission/heart_of_faith_director.gd` (`_quiet` ~374)
- Test: `tests/test_watch_posts.gd` (new)

**Interfaces:**
- Consumes: `Person.on_watch()`.
- Each check becomes "some living soldier `on_watch()` stands within R of the point" with `p.ground_pos` in place of `p.post`: Heretic Hunt R = `QUIET_R` (2.0), Informer R = `SPEAK_SEEN` (2.0), Heart of Faith R = `QUIET` (2.5) and Knights still left out (`corps != KNIGHT`). Doc comments say "where he stands, at his post" instead of "post".

Note for the reviewer: all three are called at setup (`_cellar_house`, `_contact_house` in `_begin`, `_spread`), when every guard stands at his post, so their picks barely move; Heart of Faith's `_apart()` runs mid-mission (Odran's bearers) and there a lured guard now counts as gone.

- [ ] **Step 1: Write the failing tests** (`tests/test_watch_posts.gd`): for each of `HereticHuntDirector`, `InformerDirector`, `HeartOfFaithDirector` made with `.new()` and `d.crowd = crowd` (no setup): pick an ordinary guard `g` with no other soldier within 2R; point `at := g.ground_pos + Vector2(0.3, 0)`:
  - at post → watched (`_watched(at)` true / `_quiet(at)` false);
  - `g.assist(house, true)` (away at a fire) → not watched, even with `g.ground_pos` set back to `at`;
  - `g.send_to_post(g.post + Vector2(6, 0))` and stepped 1 s (walking off, `has_goal`) → not watched at `at`;
  - a guard digging a pile (anchor on a dig spot ≠ post) standing at `at` → not watched;
  - Heart of Faith: a Knight (`corps = KNIGHT`) at `at` → still quiet.
- [ ] **Step 2: Run** `--only=test_watch_posts`: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `--only=test_watch_posts`, `--only=test_heretic_hunt`, `--only=test_informer`, `--only=test_heart_of_faith`: `failures=0`.
- [ ] **Step 5: Gate** suite; `refs_check.sh --only='^(hunt|informer|heart)_'`; list moved names.
- [ ] **Step 6: Commit** `feat: Heretic Hunt, Informer and Heart of Faith judge a watch from where the guard stands`.

### Task 8: References re-recorded, flips listed, landing checks

**Files:**
- Modify: `tools/dev/refs/*.tsv` (checksum rows only)
- Possibly modify: the scripted player (`tools/dev/behaviour_check.gd`, `tools/dev/routes/*`) when a reference mission now fails because of a block (fix the policy, never the rule)

- [ ] **Step 1: Baseline, alone on a quiet machine** (no other Godot: `powershell "Get-Process Godot*"`): `git worktree add ../vfxProve-soldier-jobs-base 983fe927`, there `"$G" --headless --path . --import`, then `bash tools/dev/refs_check.sh > <scratch>/refs_base.txt`. Expected: `refs ok=286 bad=0` (if not, note which were already bad and exclude them from the flip list). Remove the worktree after.
- [ ] **Step 2: Run** `bash tools/dev/land.sh` on the branch (suite, every reference, FLOW alone). Save its refs section to `<scratch>/refs_new.txt`. Expected: suite `failures=0`; FLOW passes (rerun alone if it aborts under load: memory flow-needs-quiet-machine); reference MISMATCHes are the moved ones.
- [ ] **Step 3: Any `outcome:` row that fails, or any won=true→false flip**, is checked against the anti-goals: a sealed route or an unwarned loss is a bug (fix the code, re-run); a scripted player walking into a pile or a ruin is fixed in its policy/route; a real, visible lure effect is accepted and listed.
- [ ] **Step 4: Re-record**: write each MISMATCH row's new checksum into its tsv (column 3 of the row with that name; leave `outcome:` rows alone), e.g. with an awk pass keyed on name. Re-run `bash tools/dev/refs_check.sh` → `refs ok=286 bad=0`.
- [ ] **Step 5: Flip list**: join `refs_base.txt` and the new run on the name; list every row whose `won=` or `reason=` differs, as `name: won=a reason=x -> won=b reason=y`. Also the count of rows that moved checksum but not outcome.
- [ ] **Step 6: Commit** `test: re-record references for soldier jobs` with a body: why they move (guards leave posts for fires before the rally; ruins stay blocked; piles block streets until dug; the three missions watch from where the guard stands), the per-feature reasons from Tasks 2-7's commit bodies, and the full flip list. Do not push, merge or tag (the controller lands).

---

## Self-review notes

- Spec A (who/when/how many/what/end, a few stay, ordinary only, tests to change) → Tasks 1-2. B (ruins, buildings only, restore, bridges, people in footprint) → Task 3. C (shape, blocks walking, two diggers ~20 s, dig clip, priority, guards until the rally then idle squads incl. EVACUATION) → Tasks 4 and 6. D (gap rule, slow crossing ~0.3, once per collapse) → Task 5. E (three missions) → Task 7. Checks + landing + flips → Task 8.
- Spec D's "a ruin's gap cell stays as long as the ruin" never triggers: a ruin keeps exactly the cells its standing building closed, so it cannot cut a route that existed; only piles are checked.
- Spec C's "door side": no building in either town has a door; the widest-street side is always used.
- Rescue squads help with piles only from the rally on (spec C "When"); before it piles are the guards' alone.
- Animals standing in a falling footprint are not moved (people only).
