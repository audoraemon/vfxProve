# KAK Soldier Duties Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** At City Emergency a 15-20 man Citadel guard forms in still ranks while the rest of the soldiers keep the city: street beats, corpse duty, cordons, sweeps, gate checks and shelter escorts, each a job kind on the one guard job board.
**Architecture:** `GuardJobs` (src/game/crowd/guard_jobs.gd) becomes the one scheduler: a 1 s tick that prunes, lets each registered `Duty` post jobs, then fills open jobs in kind priority order from the free men, keeping one per post group. Each new kind is a small `Duty` subclass in its own file under src/game/crowd/ that owns its steps, tags and drawing but never picks men; FIRE and PILE keep their own managers and callers and only share the board's records, "who is free" and keep-one rule.
**Tech Stack:** Godot 4.7.2, GDScript, the project's own test runner
**Spec:** docs/superpowers/specs/2026-11-20-kak-soldier-duties-design.md

Task list as asked, with one change forced by the code: the street beats need a second walker list beside `_loops` (crowd.gd:276), because `Crowd.loop_of()` is read by tests/test_capital_evac.gd:225-235 as "walks a wall loop"; beats get `beat_of()`.

## Global Constraints

- Determinism: fixed fps; no number for a duty is drawn from any rng (not `Crowd._rng`, not `Person.rng`); `Crowd._spot_near()` (crowd.gd:710) draws from `_rng`, so duties snap with `_grid.nearest_walkable()` only; every sort breaks ties by `Person.stagger`, cells by `(y, x)`.
- The board ticks once a second (`GuardJobs.EVERY := 1.0`, as `PileManager.EVERY`); `prune()` still runs every frame as today; a duty's `tick()` per frame only counts clocks, never searches; one path search per man per order (one `send_to_post`/`set_goal` per order), never per frame.
- No hidden losses: every cost has a tag or a banner shown before or as it lands (tag/banner texts below are exact).
- Never seal a route: nobody fleeing, panicking, on duty (`Mind.DUTY`), assisting, sheltering, or a soldier is ever turned back by a cordon; the gate check never slows a gate.
- `GuardJobs.GROUP_KEEP` 1 per post group, counted over all kinds; `SHARE` 0.5 stays for FIRE and PILE only; new kinds start only with a full crew and then run short-handed.
- Mission men are never taken by a town duty and never stood down; at the call-up every mission man joins the Citadel guard for good. One function decides it: `GuardJobs.mission_man(p)`.
- Alarm: this work may only CALL `Crowd._hear_alarm()` (crowd.gd:1690) and `AlarmManager.incident()` (alarm_manager.gd:60); READ `AlarmManager.district_of()`, `alarms.stage`, `Crowd.is_hushed()`/`is_hushed_at()`, `Crowd.is_veiled()`; LISTEN to `Crowd.danger_landed` (crowd.gd:18, emitted crowd.gd:1536), the seen branch of `_settle_doom()` (crowd.gd:2517) and the three `_investigate()` sites (crowd.gd:2420, 2475, 2523). It must not touch `on_cast()` (crowd.gd:1481), `add_alarm()` (crowd.gd:1844), stage thresholds or `UNWARNED_ALARM`.
- No new art: stand-ins only. Crouch = `stumble` (anim 3) held on its last frame; carry = two `walk`ing men with the body drawn between them; door knocks, gate checks, turning back = `talk` (anim 13). Sounds reuse `sol_order`, `sol_rally`.
- Both towns: numbers are Aldermere's; caps scale `ceili(cap * crowd.spawned_soldiers / 100.0)` (`GuardJobs.cap()`); the Citadel guard does not scale: 20 slots, floor 15, in any town; up to 2 checkers per gate, not scaled. Every test that switches to the Capital ends with `City.use(&"aldermere")`.
- No reference row may move outside the slice's may-move column (spec table, "References, tests and gates per slice").
- Project style: a `##` doc comment on every new member; no commented-out code; tests `extends RefCounted` with `static func run(t) -> void` and `t.check(cond, msg)` / `t.near(a, b, eps, msg)`; new suites registered in tests/run_all.gd SUITES (next to `res://tests/test_guard_jobs.gd`, line 69); a test that writes uses `user://test_*` names only.
- Commands: `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`; after a new `class_name` run `"$G" --headless --path . --import`; one suite: `"$G" --headless --path . -s res://tests/run_part.gd -- --only=test_x`, expect `failures=0`. Implementers run only the suites their task lists; the whole suite, references and gates are the controller's.
- Commit messages end with `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`. Never push from a task.

## Review Focus

1. **The god's hand on a duty man** (whisper, confuse, compel, lure). Spec: a held man keeps his record but does not count; corpse duty drops the job if either man is held before the 4 s end, a held carrier drops the body back with a fresh clock, a held sweep man is "not in the district", a held cordon man "does not stand his end". Failure: a body found by a lured man, a body lost off the ledger, a sweep that never breaks. Pins: Task 4 `_held_inspector_drops`, `_held_carrier_drops_body`; Task 6 `_held_squad_breaks`; Task 5 `_held_ends_cordon`.
2. **A mission man slipping into a town duty or the yard.** The definition is inferred (Risks). Festival square guards, Lost Lamb's watch (`send_to_post` away), wish soldiers from `add_soldier()` (`post_group -1`), a man on `go_duty`. Failure: a director's watch carries a corpse or is stood down to the yard, a mission's win flips. Pins: Task 1 `_mission_man_kinds`; Task 2 `_mission_men_first`, `_stand_down_never_mission`.
3. **The guard's count while men march and die.** `ring_count()` must count only men within `RING_REACH` of their own slot; pulling under 15 must never take a shelter escort or a carrier; `_refill()` taking a guard man must re-open his slot. Failure: a Citadel that is easier to burst than the spec allows, or a garrison that counts walkers. Pins: Task 2 `_count_only_on_slot`, `_pull_under_min`, `_refill_from_guard`.
4. **A cordon that strands people.** `hold_off()`'s path case keeps a citizen's goal; when the cordon ends he must take it up again (`end_hold_off()`), and a fleeing or panicking citizen or any soldier must never be held. Failure: citizens milling for ever by a ruin, a blocked evacuation. Pins: Task 5 `_never_turns_back`, `_ends_releases`.
5. **Restart and teardown.** `Crowd.clear()` and a new act must drop every job, cordon rect, carried body, `watch_far`, `talk_left`, `crouching`, `stand_face`, badges; Pale Reign's or Death Mark's put-back must never switch the always-on ledger off. Failure: a stale cordon blocking lures next act, a body drawn for ever, no bodies after a Pale Reign. Pins: Task 1 `_clear_resets_jobs`; Task 4 `_pale_keeps_ledger`.

## File Structure

| File | Responsibility |
|---|---|
| Modify `src/game/crowd/guard_jobs.gd` | The one scheduler: kinds, records, tick, who is free, mission man, keep-one, caps, pulling, tags. Alone decides who goes where. |
| Create `src/game/crowd/duty.gd` | `class_name Duty`: the base a job kind extends (post jobs, steps, interrupts, tags, drawing). Picks nobody. |
| Create `src/game/crowd/citadel_guard.gd` | CITADEL: slots and geometry, call-up, stand-down to the yard, refill/pull targets, `on_slot()`. |
| Create `src/game/crowd/corpse_duty.gd` | CORPSE: notice, inspect, found, lift, carry, lay down, drop back. |
| Create `src/game/crowd/cordon_duty.gd` | CORDON: rect, ends, turning back, `blocks()` for lures, the rope. |
| Create `src/game/crowd/sweep_duty.gd` | SWEEP: request (replaces `_investigate()`), doors, extra alarm, break. |
| Create `src/game/crowd/gate_check.gd` | GATE: checkers per gate, spots, spotting. |
| Create `src/game/crowd/shelter_escort.gd` | SHELTER: household pick, lead to the door, steadying, scatter. |
| Modify `src/game/crowd/crowd.gd` | Signal `duty_event`, `called_up()`, call-up wiring, beats, `on_ring`, `_refill`, `power_witness`, `cordon_blocks`, `WATCH_SIGHT`, hooks. |
| Modify `src/game/crowd/person.gd` | Guard march and stand, `stand_face`, `beat_index`/`on_beat()`, `crouching`, `talk_left`, `watch_far`, `unmask()`, hooks in `panic`/`lure`/`hold_off`/`on_watch`. |
| Modify `src/game/town/city_def.gd`, `src/game/town/cities/capital_city.gd` | `street_beats()` generated from `roads()`. |
| Modify `src/game/crowd/remains.gd`, `src/game/rules.gd`, `src/fx/death/pale_reign.gd`, `src/fx/death/death_mark.gd` | Ledger always on; `Remain.counted`; `of_body()`. |
| Modify `src/game/crowd/fire_manager.gd`, `rescue_manager.gd`, `shelter_manager.gd`, `marshal_manager.gd` | Cordon trigger, `called_up()`, `room()`, public `spot()`. |
| Modify `src/game/mission.gd`, `src/game/ui/hud.gd`, `src/game/mission/mission_director.gd`, `src/game/mission/temple_report.gd`, `src/fx/control/will_o_wisp.gd` | Banner, tags, `_free_soldiers()` after the call-up, witness copy, Wisp preview. |
| Modify `src/game/game.gd`, `tools/dev/behaviour_check.gd` | `--show=duty-*` photographs; bot policy fixes only if a gate pair drops. |
| Tests | New `test_citadel_guard.gd`, `test_beats.gd`, `test_corpse_duty.gd`, `test_cordon.gd`, `test_sweep.gd`, `test_gate_check.gd`, `test_shelter_escort.gd`; changed `test_guard_jobs.gd`, `test_crowd.gd`, `test_corps.gd`, `test_lost_lamb.gd`, `test_person.gd`, `test_piles.gd`, `test_watch_posts.gd`, `test_capital_evac.gd`, `test_alarm.gd`, `test_remains.gd`. |
| `tools/dev/refs/*.tsv` | Re-recorded per slice by the controller, with reasons. |

---

### Task 0: Baseline (controller, no code)

**Files:** none. Output: `<feature worktree>/.gate-baseline/` (untracked; add `.gate-baseline/` and `.gate-after/` to `.git/info/exclude`, never to `.gitignore`).

- [ ] Step: create a detached worktree of the branch base for the runs (`git worktree add --detach ../soldier-duties-base 21150731`; code equals a5825501), so the feature tree can change meanwhile. Run everything below from there and write results into the feature worktree's `.gate-baseline/`.
- [ ] Step: `"$G" --headless --path . --import`.
- [ ] Step: for `s` in `warning tax harvest lamb prayers`, one after another: `bash tools/dev/god_gate.sh --only=$s --jobs=3 > .gate-baseline/god_$s.txt 2>&1`.
- [ ] Step: for each Hunt `hide_faithful silence_witness expel_inquisitor break_hunt face_halcyon` and each type `ruin death veil passage decree dominion`: `bash tools/dev/hunt_gate.sh --only=<hunt> --type=<type> --save=.gate-baseline --jobs=3` (add `--with-none` on `ruin` only). Then `bash tools/dev/hunt_gate.sh --only=<hunt> --judge=.gate-baseline > .gate-baseline/hunt_<hunt>.txt` (`--except=decree` for silence_witness, expel_inquisitor, break_hunt).
- [ ] Step: `bash tools/dev/refs_check.sh > .gate-baseline/refs.txt`: expect `refs ok=K bad=0`.
- [ ] Step: write `.gate-baseline/SUMMARY.txt`: each file's last line and each pair's row; a pair already FAIL is recorded "failed before soldier duties" (the bar is "no pair worse than its baseline row").

---

### Task 1: The board becomes the one scheduler (no behaviour change)

**Files:** Modify `src/game/crowd/guard_jobs.gd` (whole file), `src/game/crowd/crowd.gd` (signal block 10-18; `setup` 329-360; `_advance` 1167; `clear` 2276-2390), `src/game/ui/hud.gd:745-755`, `src/game/mission.gd:668-670`. Create `src/game/crowd/duty.gd`. Test: `tests/test_guard_jobs.gd` (new functions, added to its `run`).

**Interfaces:**
- Produces (GuardJobs):
  ```gdscript
  enum Kind { CITADEL, FIRE, PILE, SHELTER, SWEEP, CORPSE, CORDON, GATE }   # priority order, highest first
  const EVERY := 1.0
  class Job:                       # one open job of a new kind (FIRE/PILE keep their Structure/Pile records)
      var kind: int                # Kind
      var at := Vector2.INF        # where the crew is wanted (nearest free man first from here)
      var born := 0.0              # board clock when posted (oldest first)
      var seq := 0                 # posting order (last tie-break)
      var need := 0                # the full crew
      var reach := INF             # free men only within this of `at`
      var crew: Array[Person] = []
      var started := false         # a full crew was once assigned (fixed-crew rule)
      var ended := false
      var data := {}               # the kind's own state
  var jobs: Array[Job] = []
  var duties := {}                 # Kind -> Duty
  var clock := 0.0
  func add_duty(d: Duty) -> void
  func post(kind: int, at: Vector2, need: int, reach := INF, data := {}) -> Job
  func step(delta: float) -> void                  # prune() every call; every EVERY: each duty's post_jobs(), _fill(), end ended jobs
  func is_free(p: Variant) -> bool                 # Task 1: == eligible(p); widened in Tasks 3 and 7
  func mission_man(p: Variant) -> bool
  func cap(base: int) -> int                       # ceili(base * crowd.spawned_soldiers / 100.0), at least base when spawned_soldiers == 0
  func assign(job: Job, p: Person) -> void         # take(p, job), job.crew.append(p), duties[job.kind].on_taken(job, p)
  func drop(job: Job, p: Person) -> void           # crew.erase, duties[kind].on_dropped(job, p), then _drop(p, true)
  func end_job(job: Job) -> void                   # drop every crew man, ended = true, erase from jobs
  func kind_of(p: Variant) -> int                  # FIRE for a Structure record, PILE for a Pile, job.kind for a Job, -1 none
  func live(kind: int) -> Array[Job]               # open jobs of that kind, posting order
  func tags() -> Array[MapTag]                     # each live job's duties[kind].tags(job), priority order
  ```
- Produces (Duty, `src/game/crowd/duty.gd`, `class_name Duty extends RefCounted`): `var board: GuardJobs`, `var crowd: Crowd`; `func setup(b: GuardJobs, c: Crowd) -> Duty`; virtuals with no-op defaults: `func kind() -> int` (-1), `func post_jobs() -> void`, `func may_take(job: GuardJobs.Job, p: Person) -> bool` (true), `func target(job) -> Vector2` (`job.at`: where "nearest" is measured from), `func refills(job) -> int` (0: men still wanted by a started job; the fixed-crew rule), `func may_pull(job) -> bool` (false), `func on_taken(job, p) -> void`, `func still_on(job, p) -> bool` (true), `func on_dropped(job, p) -> void`, `func tick(job, delta: float) -> void`, `func done(job) -> bool` (false), `func tags(job) -> Array[MapTag]` ([]), `func draw(canvas: Node2D) -> void`, `func showing() -> bool` (false; ResponseDrawer redraws while any duty shows), `func clear() -> void`.
- Produces (Crowd fields, each made in `setup()` and `add_duty()`ed by the task that creates its file, null before): `var guard: CitadelGuard` (Task 2), `var corpses: CorpseDuty` (Task 4), `var cordon: CordonDuty` (Task 5), `var sweep: SweepDuty` (Task 6), `var gate_check: GateCheck` (Task 7), `var shelter_escort: ShelterEscort` (Task 8). ResponseDrawer (crowd.gd:290-319) calls each duty's `draw()` and ORs its `showing()`.
- Produces (Crowd): `signal duty_event(kind: int, text: String, at: Vector2)`; `func called_up() -> bool` (true after `rally()` ran; false after `forgo_rally()` alone; a new `var _called_up := false`, reset in `clear()`).
- Produces (Hud): `all_tags()` appends `_crowd.guard_jobs.tags()` after the director's, lantern's and descent's (hud.gd:754), before `MapTag.shown()`.
- Produces (Mission): in `_wire_responses()` (mission.gd:669-670) `_crowd.duty_event.connect(func(_k: int, text: String, _at: Vector2): _rules.banner.emit(text))`.

Rules the implementer cannot guess:
- `mission_man(p)`: valid, alive, `soldier`, `corps == NONE`, and any of: `post_group < 0` (an `add_soldier()` soldier: no town post); `not post.is_equal_approx(town_post)`; `crowd.held_by_mission(p)`; `mind == Mind.DUTY`; `not anchor.is_equal_approx(post) and not on_job(p) and not crowd._looking(p) and mind in [POST, HOLD]` (a director's `send_to_post()`; an investigator is not one, Task 6 removes that clause with `_looking`). `at_post()` gains `and not mission_man(s)`: provably no change (every clause is already excluded there).
- `_fill()` (Task 1 has no duty, so it does nothing): open jobs sorted by `(kind, born, seq)`; per job, candidates = men with `is_free(p) and duties[kind].may_take(job, p)` within `reach` of `target(job)`, nearest first, ties by `stagger`; keep-one: count `is_free` men per `post_group` once at the start of `_fill()`, decrement as men are assigned, skip a man whose group would drop under `GROUP_KEEP`; a job not `started` is assigned only if candidates cover `need - crew.size()` (then `started = true`); a started job takes up to `refills(job)` more, and when `may_pull(job)` and no free candidate is left, the nearest `pullable` man (`pull()` first; Task 2).
- `prune()` also drops a Job crew man when `not p.is_alive()`, `p.mind == Mind.FIGHT`, `mission_man(p)` (a director took him: the director wins), or `not duties[kind].still_on(job, p)`; a man `held_by_god()` keeps his record as today. A job with `duties[kind].done(job)` true, or started and with an empty crew, is ended at the next tick.
- `clear()` also `end_job`s nothing (records just go), empties `jobs`, calls each duty's `clear()`, `clock = 0.0`. `Crowd.clear()` already calls `guard_jobs.clear()`.
- crowd.gd:1167 `guard_jobs.prune()` becomes `guard_jobs.step(delta)`.

- [ ] Step: write the failing tests in `tests/test_guard_jobs.gd`:
  ```gdscript
  static func _kinds_order(t) -> void:      # GuardJobs.Kind.CITADEL == 0, ..., GATE == 7, in the spec's order
      t.check(GuardJobs.Kind.keys() == ["CITADEL", "FIRE", "PILE", "SHELTER", "SWEEP", "CORPSE", "CORDON", "GATE"], "kinds in priority order")
  static func _mission_man_kinds(t) -> void:
      # an ordinary guard at spawn: not a mission man; post overwritten (post += (3,0); anchor = post): yes;
      # a mission_holds hook naming him: yes; go_duty(spot): yes; send_to_post(post + (4,0)) arrived: yes;
      # add_soldier(at): yes; a guard on a fire job (assist + take): no; crowd._investigate(at) men: no
  static func _step_no_change(t) -> void:
      # two crowds built alike, one stepped with guard_jobs.prune() per frame and one with guard_jobs.step(1/60) for 600 frames
      # after a yard fire at fire_from: every soldier's mind, anchor and on_guard_job equal in both
  static func _cap_scales(t) -> void:
      t.check(gj.cap(2) == 2, "Aldermere (100): cap 2 stays 2")       # crowd.spawned_soldiers == 100
      # the Capital (CapPeople._build()): gj.cap(2) == ceili(2 * spawned / 100.0) == 4 for 180; City.use(&"aldermere")
  static func _tags_empty(t) -> void:      # no job: guard_jobs.tags().is_empty(); Hud.all_tags() unchanged count
  static func _duty_event_banner(t) -> void:  # a Mission-like listener on duty_event receives (Kind.SWEEP, "X", at)
  static func _clear_resets_jobs(t) -> void:
      # a stub Duty (inner class in the test, kind() = CORDON, need 1) posts one job; step(1.0) assigns a free man;
      # crowd.clear() -> guard_jobs.jobs.is_empty(), not on_job(man), stub.cleared == true
  ```
- [ ] Step: run `--only=test_guard_jobs`: RED (Kind, step, mission_man undefined).
- [ ] Step: implement the Interfaces in `src/game/crowd/guard_jobs.gd`, `src/game/crowd/duty.gd`, `crowd.gd`, `hud.gd`, `mission.gd` (run `--import`: new `class_name Duty`).
- [ ] Step: run `--only=test_guard_jobs`: GREEN.
- [ ] Step: focused suites: `test_corps`, `test_piles`, `test_fire`, `test_watch_posts`, `test_soldier_minds`, `test_legend`.
- [ ] Step (controller): `bash tools/dev/refs_check.sh`: all OK (nothing may move; a mismatch is a bug in this task).
- [ ] Step: commit `feat: the guard job board becomes the one scheduler (kinds, records, mission man, no behaviour change)`.

### Task 2 (slice a1): The Citadel guard

**Files:** Create `src/game/crowd/citadel_guard.gd`, `tests/test_citadel_guard.gd` (register in run_all.gd after test_guard_jobs). Modify `crowd.gd` (`rally` 2071-2086, `on_ring` 2092-2098, `_refill` 2115-2136, `_on_citadel_fallen` 2576-2580, `setup` add the duty), `person.gd` (`_base_speed` 880-899, `_pick_target` 996-1007, pose 3178, `send_to_post` 2845-2853), `guard_jobs.gd`, `rescue_manager.gd:159`, `mission.gd:670`, `mission_director.gd:314-323`. Change tests: `test_crowd.gd:116-123`, `test_lost_lamb.gd:400-426`, `test_corps.gd:57-103, 124-144, 159-248`, `test_guard_jobs.gd` (`_close`, `_forgo`, `_rally_clears`, `_unprepared`), `test_piles.gd:783` (`_squads_after_rally`), `test_person.gd:82-87` if its step count no longer reaches the ring.

**Interfaces:**
- Consumes: `GuardJobs.post/assign/drop/is_free/mission_man/live`, `Duty`, `Crowd.called_up()`.
- Produces (CitadelGuard extends Duty):
  ```gdscript
  const GUARD_SLOTS := 20
  const GUARD_MIN := 15
  const RANK_STEP := 0.6
  const SIDES: Array[Vector2] = [Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)]   # south (the gateway) first
  const BANNER := "THE CITADEL GUARD FORMS"
  var job: GuardJobs.Job                 # the one CITADEL job (null before the call-up)
  static func slot_at(origin: Vector2, k: int) -> Dictionary   # {"at": Vector2 (unsnapped), "face": Vector2}
  func call_up() -> void                 # forms the guard (called by Crowd.rally())
  func slot_of(p: Variant) -> Vector2    # his slot (snapped), INF when not a guard man
  func on_slot(p: Variant) -> bool       # living, corps NONE, CITADEL job, Mind.RALLY, within Crowd.RING_REACH of his slot
  func count() -> int                    # guard men (crew), walking or standing
  # overrides: target(job) = slot_at(free_slot()) snapped; refills(job) = GUARD_SLOTS - count(); may_pull(job) = count() < GUARD_MIN
  func answered(p: Variant) -> bool      # assigned at the call-up itself (marked once, never cleared until clear())
  func free_slot() -> int                # lowest empty slot index < GUARD_SLOTS, -1 none
  ```
- Produces (Person): `var stand_face := Vector2.INF` (the way he faces standing at his anchor; every `send_to_post()` and `hold_ground()` clears it, so a caller sets it right after its `send_to_post()`; used by the guard, the corpse watcher, cordon ends).
- Produces (GuardJobs): `func pull(p: Person) -> void` (a FIRE man `stand_down()`, a PILE man `crowd.piles.release(p)`, a Job man `drop()`; then `release(p)`); `func pullable(p: Variant) -> bool` (on a job, not CITADEL, not SHELTER, not a CORPSE job with `data.get("carrying", false)`; CorpseDuty sets `carrying` in Task 4).

Rules:
- Slot geometry (the code block is binding):
  ```gdscript
  # slot k: side = SIDES[k % 4]; i = (k % GUARD_SLOTS) / 4 (0..4, centre out); rank = k / GUARD_SLOTS (0 = front)
  # off = RANK_STEP * ((i + 1) / 2) * (1 if i % 2 == 1 else -1)          # 0, +0.6, -0.6, +1.2, -1.2
  # along = Vector2(-side.y, side.x)
  # at = origin + side * (Crowd.RING_RADIUS + RANK_STEP * rank) + along * off ; face = side
  # snapped: _grid.nearest_walkable(at), INF -> at (never _spot_near: it draws from the shared rng)
  ```
  The facing: `_facing = 1 if face.x - face.y > 0.0 else -1`, `_back = face.x + face.y < 0.0` (as the drill branch, person.gd:1003-1005).
- `call_up()` order: (1) every `mission_man` (corps NONE, alive, not inside) in `crowd.soldiers` order gets slots 0.. (past 20: rear ranks); (2) town men while `crew.size() < GUARD_SLOTS`: the Citadel group (`post_group == 2`) first in soldiers order, nearest their slot; then the nearest `is_free` men to the next free slot (keep-one applies to these, not to mission men); a man on a FIRE/PILE job is taken only via `pullable` while the guard is under `GUARD_MIN`; (3) every other living Citadel-group corps-NONE man who is not a mission man is stood down: `post = town_post = ` the nearest of `crowd.yard_spots()` not yet given, `post_group = 0`, `send_to_post(post)`. Every guard man: `board.assign(job, p)`, `p.send_to_post(slot, true)`, `p.stand_face = face`. `answered` marks exactly these men.
- `Crowd.yard_spots(n: int) -> Array[Vector2]`: walkable cell centres on a 0.5 grid within 3.0 of `landmark(&"barracks_yard").get_center()`, not within 0.3 of any living soldier's `town_post`, nearest the centre first, ties by `(y, x)`; at most `n`.
- `rally()` keeps `_rallied = true`, sets `_called_up = true`, no longer calls `guard_jobs.close()`, replaces the ring loop with `guard.call_up()`, keeps `sol_rally` and `rallied.emit()`. `forgo_rally()` unchanged (no guard; board open). `_on_citadel_fallen()` calls `guard_jobs.close()` first (close now also `end_job`s every Job), then the `hold_ground()` loop.
- March and stand: `_base_speed()` `Mind.RALLY` returns `WALK_SPEED * ASSIST_PACE * pace` (0.9 x pace); pose line 3178 drops `or mind == Mind.RALLY` (walk clip); `_pick_target()` gains, before the POST branch at 996: `if (mind == Mind.RALLY or mind == Mind.POST) and stand_face != Vector2.INF and ground_pos.distance_to(anchor) <= GOAL_REACH * 2.0:` `hurrying = false`, stand on the anchor, face `stand_face`, return (no `_drift()`); `_interact_anim()` already returns -1 for RALLY (no talk).
- `on_ring(p)` = `guard.on_slot(p)`; `ring_count()` unchanged (still 0 before `_rallied`).
- Refill (through the overrides above; the board's `_fill()` does the picking): while `count() < GUARD_SLOTS` the nearest `is_free` town man to the free slot; while `count() < GUARD_MIN` also the nearest `pullable` man (`board.pull(p)` first). A town man leaves the guard only by `_refill()` or death; a mission man never.
- `_refill(dead)`: `if not called_up()` return (was `_rallied`); best = nearest `is_free` board man to the dead; none: nearest guard man (`job.crew`), whose record is dropped (his slot re-opens, the next tick refills it). One per death. The rest of the function as today.
- `_free_soldiers()` (mission_director.gd:314): before `crowd.called_up()`: as today, and `crowd.guard_jobs.release(p)` for each returned (the director wins). After: the pool is only `guard.answered(p)` men with `mind in [POST, HOLD]` and not on the CITADEL job.
- rescue_manager.gd:159 `not _crowd.guard_jobs.is_open()` becomes `_crowd.called_up()`.
- mission.gd:670 banner text becomes `CitadelGuard.BANNER`.

- [ ] Step: write the failing tests in `tests/test_citadel_guard.gd`:
  ```gdscript
  static func _slots(t) -> void:
      t.check(CitadelGuard.slot_at(o, 0).face == Vector2(0, 1) and CitadelGuard.slot_at(o, 1).face == Vector2(1, 0), "south first, then round")
      t.near(CitadelGuard.slot_at(o, 0).at.distance_to(o), Crowd.RING_RADIUS, 0.001, "front rank at RING_RADIUS")
      t.near(CitadelGuard.slot_at(o, 4).at.distance_to(CitadelGuard.slot_at(o, 0).at), 0.6, 0.001, "ranks 0.6 apart")
      # slots 0..14 cover all four sides; slot 20 is the rear rank (distance RING_RADIUS + 0.6 along its side)
  static func _guard_of_twenty(t) -> void:        # Aldermere: crowd.rally() -> guard.count() == 20, the rest corps-NONE stay POST
  static func _mission_men_first(t) -> void:      # 3 mission men (hook, post overwritten, go_duty) -> all 3 in the guard, slots 0-2, Mind.RALLY
  static func _more_than_twenty(t) -> void:       # 22 mission men -> 22 guard men, slots 20-21 at rank 1, no town man
  static func _stand_down_yard(t) -> void:        # Aldermere with 2 mission men: 2 Citadel-group men get post_group 0, post == town_post near the yard
  static func _stand_down_never_mission(t) -> void:  # a mission man of the Citadel group is never stood down
  static func _march_walk(t) -> void:             # a guard man: walk_speed == 0.6 * 1.5 * pace; pose anim 1 while striding
  static func _stand_still(t) -> void:            # arrived: 300 frames -> ground_pos unchanged (<0.01), facing from stand_face
  static func _count_only_on_slot(t) -> void:     # ring_count() counts only men within 1.0 of their own slot; 15 on slot -> garrison_cut() == 0.30
  static func _refill_under_twenty(t) -> void:    # kill a guard man; 1 tick -> nearest free town man assigned, marching
  static func _pull_under_min(t) -> void:         # guard at 14, no free man: a FIRE man is pulled; a SHELTER/carrier stub job man is not
  static func _refill_from_guard(t) -> void:      # all free men busy: a marshal dies -> a guard man takes MARSHAL, his slot reopens
  static func _board_open(t) -> void:             # after rally(): is_open(); a fresh yard fire at fire_from takes a guard (FIRE pick)
  static func _fallen_closes(t) -> void:          # citadel fallen -> not is_open(), every corps-NONE HOLD, jobs empty
  static func _forgo_no_guard(t) -> void:         # forgo_rally(): guard.count() == 0, is_open(), called_up() == false
  static func _late_appointment(t) -> void:       # after rally(): MissionDirector._free_soldiers(at, 5) is empty; a guard man sent back to POST is returned
  static func _capital_guard(t) -> void:          # Capital: guard.count() == 20; 10 of the 30 Citadel group stood down; City.use(&"aldermere")
  ```
  Rewrite `test_crowd.gd:116-123` to: the first Citadel hit forms the guard: `RALLY` count == 20 and every other corps-NONE soldier keeps a non-RALLY mind ("the first Citadel hit forms a guard of 20; the rest keep the city"). Rewrite `test_lost_lamb.gd:417-422`: `back` is the first `crowd.guard.answered(p)` non-watcher (assert it is one), the rest unchanged; label "one guard man back on his post is the only searcher". `test_guard_jobs` `_close`/`_rally_clears`/`_unprepared`: the call-up leaves the fire fighter on his fire and the board open; `_forgo`: unchanged meaning. `test_corps.gd:74-78`: patrols rallying count becomes "not in the guard unless chosen"; 96-103 "only corps NONE join the guard"; 137-144 "after the call-up a fresh fire still takes a guard"; 159-248 reserve checks use `crowd.on_ring()` with slots. `test_piles._squads_after_rally`: guards may dig after the call-up; idle rescue squads still help (`called_up()`).
- [ ] Step: run `--only=test_citadel_guard`: RED.
- [ ] Step: implement (run `--import`).
- [ ] Step: run `--only=test_citadel_guard`, `--only=test_guard_jobs`: GREEN.
- [ ] Step: focused suites: `test_crowd`, `test_corps`, `test_citadel`, `test_alarm`, `test_soldier_minds`, `test_person`, `test_lost_lamb`, `test_judgement`, `test_escorts`, `test_marshals`, `test_rescue`, `test_piles`, `test_legend`. Every other mission suite that asserts `Mind.RALLY` after `crowd.rally()` must pass unedited; one that fails is a bug in `mission_man()`, not a test to edit.
- [ ] Step (controller): re-record the references that moved, each with its reason; any row outside the slice's may-move column (a1: rows that reach the call-up; never rows that do not) is a bug to fix first.
- [ ] Step (controller): rerun the gates for the missions this slice can touch: god_gate `lamb warning` (late appointments, loud rows), hunt_gate `hide_faithful expel_inquisitor face_halcyon break_hunt silence_witness` (watch at the call-up) into `.gate-after/`; compare each pair with its baseline row: none worse.
- [ ] Step: commit `feat: the Citadel guard (20 slots, floor 15, march at a walk, stand in ranks); the board stays open until the Citadel falls`.

### Task 3 (slice a2): Street beats

**Files:** Modify `src/game/town/city_def.gd` (after `loop_start` :56), `src/game/town/cities/capital_city.gd:1395-1407`, `crowd.gd` (`_start_loops` 824-840, `_walk_loops` 852-871, `_soldier_posts` 908-920, `_advance` 1209, `clear` 2366), `person.gd` (`on_watch` 2866-2869), `guard_jobs.gd` (`is_free`). Create `tests/test_beats.gd`. Change `tests/test_watch_posts.gd:42-53` (`_lone` excludes beat men), `tests/test_capital_evac.gd:235` (`loop_of(p) < 0 and crowd.beat_of(p) < 0`).

**Interfaces:**
- Produces (CityDef): `const BEAT_STEP := 3.0`; `static func beat_of_road(road: Rect2, at: Vector2) -> Dictionary` (`{"points": Array[Vector2], "start": int}`: the long-axis centre line from one end to the other, a point every BEAT_STEP (`n = maxi(1, roundi(len / BEAT_STEP))`, n+1 points), then back without repeating the ends, so a closed walk is there and back; `start` = the point nearest `at`, ties lowest index); `func street_beats() -> Array` (one `{"points", "start", "post"}` per street pair in post order; base implementation = Aldermere's formula at crowd.gd:908-920: streets = `roads()` that `town().encloses()`, pair `k` on `streets[k % streets.size()]`, `post` = the unspread point that formula gives; no streets: []).
- Produces (CapitalCity): `street_beats()` override with its own `streets` and `STREET_PAIRS` loop (capital_city.gd:1395-1407), same `beat_of_road()`; the post-point formula moves into a shared private `_street_pair_points() -> Array` used by both `soldier_posts()` and `street_beats()` so they cannot drift.
- Produces (Crowd): `var _beats: Array = []` (entries shaped as `_loops`' `[soldier, points, at, k, -1.0]`, k = beat index); `func beat_of(p: Variant) -> int` (-1 none).
- Produces (Person): `var beat_index := -1`; `func on_beat() -> bool` (`beat_index >= 0 and corps == NONE and post.is_equal_approx(town_post) and anchor.is_equal_approx(post)`).
- Produces (GuardJobs): `func beat_walker(p: Variant) -> bool` (alive, soldier, NONE, not inside, `on_beat()`, `mind == POST`, not `held_by_god()`, not `held_by_mission`, not escort-guarding, not `on_job`); `is_free(p)` = `eligible(p) or beat_walker(p)`; keep-one counts `is_free` men.

Rules:
- `_start_loops()`: after the wall loops, `i` continues over the patrol group: for beat `k` of `City.current().street_beats()`, the next 2 patrol soldiers get an entry in `_beats` (points snapped with `_grid.nearest_walkable`, INF keeps the raw point), `at = start`, `beat_index = k`. Escort-corps men get entries but `_walk_loops` skips them (corps != NONE, as today).
- `_walk_loops()` walks both lists with the same body; the `_rallied` test applies to `_loops` only: beats continue after the call-up. The pause is `LOOP_PAUSE` 2.0 and the `talk` clip shows in it (mind POST, no goal: `_interact_anim()` as today).
- `on_watch()` returns false when `on_beat()`; still a witness within `DOOM_WITNESS` (nearest_witness unchanged).
- crowd.gd:1209 `if not _loops.is_empty()` becomes `if not _loops.is_empty() or not _beats.is_empty()`; `clear()` empties `_beats`.

- [ ] Step: write the failing tests in `tests/test_beats.gd`:
  ```gdscript
  static func _beat_shape(t) -> void:        # beat_of_road(Rect2(0,0,1,12), (0.5,0)): 5 points forward (0,3,..12), then 3 back; start 0
  static func _beats_aldermere(t) -> void:   # street_beats().size() == Crowd.POST_PATROL / 2 (10); each post within 0.01 of the post formula's point
  static func _beats_capital(t) -> void:     # street_beats().size() == CapitalCity.STREET_PAIRS; every point inside a roads() rect grown 0.5; City.use(&"aldermere")
  static func _pairs_walk(t) -> void:        # 120 s of steps: >= 80% of corps-NONE beat men have post != their first post
  static func _pause_talks(t) -> void:       # a beat man at a point: mind POST, no goal, stays >= 2.0 s (LOOP_PAUSE) before moving on
  static func _after_call_up(t) -> void:     # crowd.rally(); 30 s -> beat men not in the guard keep moving on; wall loop men stop (Capital)
  static func _off_watch(t) -> void:         # a beat man paused at his point: on_watch() false; a guard at his post: true
  static func _director_station_watches(t) -> void:  # a beat man send_to_post(spot) by a director: on_beat() false, on_watch() true at the spot
  static func _walker_free(t) -> void:       # a beat man mid-leg (has_goal): guard_jobs.is_free() true; a wall loop man mid-leg: false
  static func _escort_stands(t) -> void:     # an ESCORT-corps patrol man never moves off his post in 60 s
  static func _mission_man_never(t) -> void: # a beat man named by a mission hook: not is_free, his entry never re-posts him
  ```
  test_watch_posts: `_lone()` adds `p.beat_index < 0`; add `_beat_man_off_watch` (each of hunt/informer/heart: a door next to a paused beat man is not watched).
- [ ] Step: run `--only=test_beats`: RED.
- [ ] Step: implement.
- [ ] Step: run `--only=test_beats`: GREEN.
- [ ] Step: focused suites: `test_watch_posts`, `test_capital_evac`, `test_capital_people`, `test_guard_jobs`, `test_citadel_guard`, `test_expel_inquisitor` (its `_round_loops`), `test_corps`.
- [ ] Step (controller): re-record the references that moved, each with its reason; any row outside the slice's may-move column (a2: every row may move; judge by the gates) is a bug to fix first. Record a2 separately from a1 (Risks).
- [ ] Step (controller): rerun the gates for the missions this slice can touch: all five god_gate scenarios and all five Hunts (every row moves; Heretic Hunt, Informer and Heart of Faith read `on_watch()`); compare each pair with its baseline row: none worse; report every win/loss flip of the three `on_watch()` missions to the user.
- [ ] Step: commit `feat: street pairs walk generated beats in both towns; a beat man is off watch but free for jobs`.

### Task 4 (slice b): Bodies in every mission and corpse duty

**Files:** Create `src/game/crowd/corpse_duty.gd`, `tests/test_corpse_duty.gd`. Modify `src/game/crowd/remains.gd` (Remain class 27-38; new `of_body`, `always`), `src/game/rules.gd:246-248`, `src/fx/death/pale_reign.gd:467-470`, `src/fx/death/death_mark.gd:230-237`, `crowd.gd` (`_on_killed` 2474-2476; ResponseDrawer 290-319), `person.gd` (pose: crouch branch beside the stumble branch 3142-3144). Change `tests/test_remains.gd` (add the always-on checks).

**Interfaces:**
- Produces (Remains): `var always := false` (set by Rules; `enabled` is never switched off while true); `Remain.counted := false`; `func of_body(p: Person) -> Remain` (the newest remain whose `body.get_ref() == p`, or null; Remains' own `_on_killed` is connected at crowd.gd:348 before the crowd's at :352, so the remain exists when the crowd's handler runs).
- Produces (Person): `var crouching := false` (pose anim 3 at `t = STUMBLE_SECONDS`, held, while true and not striding).
- Produces (CorpseDuty extends Duty):
  ```gdscript
  const CORPSE_NOTICE := 4.0
  const INSPECT := 4.0
  const CARRY_REACH := 4.0
  const WATCH_OFF := 0.8         # the watcher stands this far from the body, facing out
  const TAKEN_SHOW := 2.0
  const BANNER := "A BODY IS FOUND"
  enum { WALK, INSPECT_PHASE, CARRY, LAY }   # job.data.phase; data.carrying = phase in [CARRY, LAY] (read by GuardJobs.pullable())
  func assigned(r: Remains.Remain) -> bool
  func found_in(job: GuardJobs.Job) -> int  # ceili(inspector distance to the body / walk_speed + inspect left)
  ```
  Job data: `remain`, `phase`, `inspector`, `watcher`, `left` (inspect seconds), `to` (lay-down spot), `taken_left`, `fade_left`.

Rules:
- rules.gd:247-248: `crowd.remains.enabled = true` and `crowd.remains.always = true` for every loadout (drop the `wants()` guard; `Remains.wants()` stays for other readers). Both `_put_ledger_back()`s set `enabled = false` only when `not rem.always`.
- crowd.gd:2476: before `_hear_alarm(ALARM_KILL)`, `var r := remains.of_body(p) if remains != null else null; if r != null: r.counted = not is_hushed()` (a hushed kill reaches this line but adds no alarm).
- `post_jobs()` (needs `crowd.remains.enabled`): for each beat (the two men with the same `beat_index` in `crowd._beats`, both `is_free`), the first unhidden, unassigned remain from `remains.near(m.ground_pos, reach)` for either man, where `reach = crowd.sight(m, r.pos, CORPSE_NOTICE * crowd.sight_scale)` and `not crowd.is_veiled(r.pos)`; post `Job(CORPSE, r.pos, need 2, reach INF)` with `data.pair = [a, b]`; `may_take` accepts only that pair. One body per pair, one pair per body.
- Steps: both `send_to_post(spot)` (inspector = the nearer, spot = `nearest_walkable(r.pos)`; watcher spot = `r.pos + (r.pos - inspector.ground_pos).normalized() * WATCH_OFF`, snapped, `stand_face` outward). The inspect clock runs only while the inspector stands within `GOAL_REACH * 2.0` of his spot and neither man is `held_by_god()`; `crouching = true` meanwhile. At 0: found: `crowd.alarms.incident(r.pos)` (if it returns true also `crowd._investigate(r.pos)`, the sweep from Task 6), plus `crowd._hear_alarm(Crowd.ALARM_KILL)` only if `not r.counted`; `crowd.duty_event.emit(Kind.CORPSE, BANNER, r.pos)`; then lift: `remains.take(r)`, phase CARRY, `to` = the nearest walkable cell centre within `CARRY_REACH` of `r.pos` not inside any `City.current().roads()` rect, ties `(y, x)` (none: `to = r.pos`, lay down at once); both walk there; at `to`: phase LAY, `fade_left = DummyEnemy.DEATH_FADE`; then both `back_to_post()` and the job ends.
- Interrupts: before found, either man dead, FIGHT, held, taken by a director or pulled: the job ends, nothing found, the tag goes. During CARRY, a carrier dead or held: `remains.move(r, midpoint of the carriers, false)` (fresh clock), job ends; CARRY men are not `pullable`. The body is used (no longer on the ledger, before the lift) or lapses: the job ends.
- Drawing (`draw()`, from ResponseDrawer's `ground == false` pass; `showing()` true while a CARRY/LAY job lives): the remain's death frame at the carriers' midpoint (as `Remains._draw()`), alpha `fade_left / DEATH_FADE` in LAY.
- Tags: from assignment until found `MapTag.place(r.pos, <colour>, "FOUND IN %d" % found_in(job))`; `TAKEN_SHOW` 2.0 s after the lift `MapTag.place(r.pos, <colour>, "TAKEN")`.

- [ ] Step: write the failing tests in `tests/test_corpse_duty.gd` (each builds with `crowd.remains.enabled = true; crowd.remains.always = true` as Rules would):
  ```gdscript
  static func _bodies_every_loadout(t) -> void:  # Rules built with a Ruin-only loadout: remains.enabled and always
  static func _pale_keeps_ledger(t) -> void:     # always on; a Pale Reign cast ends (_put_ledger_back) -> still enabled; Death Mark Wake too
  static func _notice(t) -> void:                # a mob kill 3.5 from a paused beat pair -> 1 CORPSE job after 1 tick; at 4.5 -> none
  static func _veiled_unnoticed(t) -> void:      # crowd.veil(at, 3, 30) over the body -> no job
  static func _no_sight(t) -> void:              # a NO SIGHT law over the pair -> reach 2.0 (LawZone.SIGHT_CAP): body at 3.0 unnoticed
  static func _crew_pair_only(t) -> void:        # only that pair is on it; a second body near the same pair -> no second job
  static func _keep_one(t) -> void:              # patrol group with 3 free men: a pair job never leaves it under GROUP_KEEP
  static func _mission_man_never(t) -> void:     # one of the pair named by a hook -> no job
  static func _inspect_four(t) -> void:          # arrived: found exactly after 4.0 s (240 frames at 60 fps, not 239); banner "A BODY IS FOUND"
  static func _found_tag(t) -> void:             # tag "FOUND IN n": n strictly non-increasing each second, 0 at found
  static func _incident_and_alarm(t) -> void:    # uncounted (hushed kill): _events[d] += 1 and alarm += 0.5 * UNWARNED_ALARM
  static func _counted_no_alarm(t) -> void:      # a seen mob kill (counted): incident +1, alarm unchanged by the find
  static func _lift_takes(t) -> void:            # after found: remains.pick(r.pos) == null; tag "TAKEN" 2.0 s; laid off every road within 4.0
  static func _held_inspector_drops(t) -> void:  # lure the inspector at 2 s -> job ends, nothing found, remain still on the ledger, no tag
  static func _held_carrier_drops_body(t) -> void:  # confuse a carrier mid-carry -> remain back on the ledger at the midpoint, age 0
  static func _pulled_by_guard(t) -> void:       # guard under 15 pulls an inspecting man (job ends); never a carrier
  static func _lapse_ends(t) -> void:            # remain lapses (age 45) before found -> job ends
  static func _capital_corpse(t) -> void:        # Capital: a body near a beat pair is noticed and carried; City.use(&"aldermere")
  ```
  test_remains: `_always_on` (Rules with any loadout: enabled; `Remains.wants([])` still false).
- [ ] Step: run `--only=test_corpse_duty`: RED.
- [ ] Step: implement (run `--import`).
- [ ] Step: run `--only=test_corpse_duty`: GREEN.
- [ ] Step: focused suites: `test_remains`, `test_death_twist_deathmark`, the Pale Reign suite (`grep -l pale_reign tests/*.gd`), `test_beats`, `test_guard_jobs`, `test_citadel_guard`.
- [ ] Step (controller): re-record the references that moved, each with its reason; any row outside the slice's may-move column (b: rows with a whole body near a beat; never `none` cases or rows with no body kind) is a bug to fix first.
- [ ] Step (controller): rerun the gates for the missions this slice can touch: all five god_gate scenarios and all five Hunts (bodies are now kept in every mission; Death rows first); compare each pair with its baseline row: none worse.
- [ ] Step: commit `feat: bodies stay 45 s in every mission; a beat pair inspects a body 4 s, reports it, carries it off the street`.

### Task 5 (slice c): Cordon

**Files:** Create `src/game/crowd/cordon_duty.gd`, `tests/test_cordon.gd`. Modify `fire_manager.gd:261-274` (`_put_out`), `crowd.gd:2430-2432` (`_on_structure_destroyed`), `person.gd` (`hold_off` 1562-1590; `lure` 1458-1467), `will_o_wisp.gd:75-88` (`drawn`), `crowd.gd` (ResponseDrawer; `nearest_witness` 2489-2500).

**Interfaces:**
- Produces (CordonDuty extends Duty):
  ```gdscript
  const CORDONS := 2               # scaled by board.cap()
  const CREW := 2
  const REACH := 10.0              # PileManager.REACH
  const CORDON_HALF := 3.0
  const CORDON_SECONDS := 40.0
  const FOOT_GROW := 0.5
  const PATH_AHEAD := 24
  const TURN_BACK := 1.5           # hold_off seconds, renewed every tick while live
  func request(site: Structure, street_at: Vector2) -> void
  func blocks(a: Vector2, b: Vector2) -> bool        # the segment a-b crosses a live cordon's rect; false at once when none is live
  func rect_of(job: GuardJobs.Job) -> Rect2
  func inside(at: Vector2) -> bool                    # in any live cordon's rect
  static func stretch(roads: Array, near: Vector2, half: float) -> Array   # [end_a: Vector2, end_b: Vector2, rect: Rect2] on the road rect nearest `near`
  ```
- Produces (Crowd): `func cordon_blocks(a: Vector2, b: Vector2) -> bool` (`cordon != null and cordon.blocks(a, b)`).
- Produces (Person): `hold_off(r: Rect2, seconds: float, heading: Vector2, walk_away: float, path_too := false) -> bool` (with `path_too`, a goal outside `r` whose path `path_crosses(r, CordonDuty.PATH_AHEAD)` is kept too). FoldWard's call (fold_ward.gd:166) is unchanged.

Rules:
- Triggers: `_put_out(s, true)` with `not s.destroyed` → `request(s, s.center())`; `_on_structure_destroyed` with `s.leaves_ruin()`, after `piles.on_fall(s)` → `request(s, centre of the pile just placed, else s.center())`. `request` does nothing when `crowd.is_veiled(s.center())` or `stage >= EVACUATION`; a site whose centre lies in a live cordon's rect restarts that cordon's clock instead; else posts `Job(CORDON, mid of the ends, need 2, reach REACH)` while `live(CORDON).size() < board.cap(CORDONS)`.
- `stretch()`: the road rect (from `City.current().roads()`) nearest `near` (distance to the rect, ties first in list); its long axis; the centre line point nearest `near`, clamped to the road; ends at ±`half` along the axis (clamped); rect = the road-width stretch between the ends. The cordon rect = `stretch.rect.merge(site.footprint.grow(FOOT_GROW))`.
- Steps: each man walks to one end (`send_to_post`, snapped), stands facing away from the rect's centre (`stand_face`). Every tick, every citizen with `mind in [CALM, RECOVER]`, alive, not inside, `not crowd.held_by_mission(p)`, whose goal lies in the rect or whose path crosses it, gets `hold_off(rect, TURN_BACK, p.ground_pos - rect.get_center(), 1.0, true)`; the nearer end man gets `talk_left = 1.0`. This task defines `Person.talk_left := 0.0` (counted down in `tick()`; while > 0 and not striding, `_interact_anim()` returns 13 for a soldier in any mind); Tasks 6 and 7 reuse it.
- Never turned back: FLEE, PANIC, DUTY, ASSIST, SHELTER, REGROUP, any soldier.
- `lure()` (person.gd:1466): a citizen returns false when `crowd != null and crowd.cordon_blocks(ground_pos, at)`. `WillOWisp.drawn()` skips such a citizen the same way.
- Witness: in `nearest_witness()` a cordon crew man does not witness a point with `cordon.rect_of(his job).has_point(at)`; his reach stays `doom_witness()`.
- Ends (job ends, every crew `back_to_post()`, every held-off citizen `end_hold_off()` if `held_off()` by this rect): `CORDON_SECONDS` 40 after the (last) start; stage reaches EVACUATION; no crew man within `GOAL_REACH * 2.0` of his end and unheld.
- Drawing (ResponseDrawer `ground == true`): at each end two short posts and a rope between them across the road (lines in screen space via `Iso.ground_to_screen`); tag `MapTag.place(centre, <colour>, "CORDON %d" % ceili(left))`.

- [ ] Step: write the failing tests in `tests/test_cordon.gd`:
  ```gdscript
  static func _fire_out_trigger(t) -> void:     # douse a burning house until out -> 1 CORDON job; a burnt-down house -> none from _put_out
  static func _fall_trigger(t) -> void:         # a house falls (leaves_ruin) -> 1 job on the pile's street
  static func _veiled_none(t) -> void:          # veiled site -> none; stage EVACUATION -> none
  static func _restart_inside(t) -> void:       # a second site inside a live rect -> still 1 job, clock back to 40
  static func _cap_two(t) -> void:              # three sites far apart -> 2 jobs (Aldermere); Capital cap 4; City.use(&"aldermere")
  static func _crew_within_reach(t) -> void:    # both crew men were free and within 10.0; none from 10.5
  static func _full_crew_only(t) -> void:       # 1 free man in reach -> no job starts
  static func _keep_one(t) -> void:             # never leaves a post group under GROUP_KEEP
  static func _mission_man_never(t) -> void
  static func _shape(t) -> void:                # stretch(): ends 6.0 apart on the road centre line; rect contains footprint.grow(0.5)
  static func _turns_back(t) -> void:           # a CALM citizen with a goal inside -> held_off() within 1 tick; a path-crossing one too
  static func _never_turns_back(t) -> void:     # FLEE, PANIC, DUTY, REGROUP citizens and a soldier walk through: not held_off()
  static func _lure_fails(t) -> void:           # citizen outside, lure point beyond the rect: lure() false; WillOWisp.drawn() excludes him
  static func _lure_o1(t) -> void:              # no cordon live: cordon_blocks() returns false without looping (cordon.live count 0)
  static func _inside_unwatched(t) -> void:     # a death inside the rect, only the crew within 2.0 -> nearest_witness() == null
  static func _ends_forty(t) -> void:           # 40.0 s -> job ends, crew back_to_post, held citizens end_hold_off and take up their goals
  static func _ends_releases(t) -> void:        # the held-off citizen's goal is restored (bound_for() equals the old goal)
  static func _held_ends_cordon(t) -> void:     # kill one, lure the other -> ends at the next tick
  static func _evacuation_ends(t) -> void
  ```
- [ ] Step: run `--only=test_cordon`: RED.
- [ ] Step: implement (run `--import`).
- [ ] Step: run `--only=test_cordon`: GREEN.
- [ ] Step: focused suites: `test_piles`, `test_fire`, the FoldWard suite (`grep -l fold_ward tests/*.gd`), the Will-o'-Wisp suite (`grep -l WillOWisp tests/*.gd`), `test_guard_jobs`.
- [ ] Step (controller): re-record the references that moved, each with its reason; any row outside the slice's may-move column (c: rows with a fire put out or a fall; never `none` cases or quiet rows) is a bug to fix first.
- [ ] Step (controller): rerun the gates for the missions this slice can touch: all five god_gate scenarios (Ruin's fires and falls), hunt_gate `--type=ruin` and `--type=passage` for all five Hunts (re-judge each Hunt with the other saved types from the last run); compare each pair with its baseline row: none worse.
- [ ] Step: commit `feat: two soldiers cordon a doused fire or a fall for 40 s; citizens turn back, lures through it fail`.

### Task 6 (slice d): Sweep

**Files:** Create `src/game/crowd/sweep_duty.gd`, `tests/test_sweep.gd`. Modify `crowd.gd` (constants near 75; `_investigate`/`_return_investigators`/`_looking` 874-878, 2035-2066; `_advance` 1208; `_settle_doom` 2517-2524; `nearest_witness` 2489-2500; `clear`), `temple_report.gd:161-172`, `person.gd` (`talk_left` already from Task 5; `watch_far`), `guard_jobs.gd` (`mission_man` drops the `_looking` clause; `at_post` drops `_looking`). Change `tests/test_alarm.gd` (investigator checks become sweep checks).

**Interfaces:**
- Produces (Crowd): `const WATCH_SIGHT := 4.0` (beside `COLLAPSE_SIGHT`); `func power_witness(points: Array[Vector2], radius: float) -> Person` (the nearest living person, citizen or soldier, not inside, `mind != ASLEEP`, not `held_by_god()`, not guised, not `LawMark.unseen_by_all`, within his reach of a point or within `radius` of it; reach = `WATCH_SIGHT * sight_scale` for `watch_far` men else `doom_witness()`, capped by `sight(p, point, reach)`); `_investigate(at)` becomes `if sweep != null: sweep.request(at)`.
- Produces (Person): `var watch_far := false` (set and cleared only by SweepDuty and GateCheck).
- Produces (SweepDuty extends Duty):
  ```gdscript
  const SWEEPS := 2                # scaled
  const CREW := 4
  const SWEEP_DOORS := 6
  const SWEEP_STAND := 3.0
  const SWEEP_SECONDS := 30.0
  const SWEEP_ALARM := 2.0         # == Crowd.ALARM_BUILDING
  const SWEEP_ALARM_CAP := 6.0
  const BANNER := "SOLDIERS SWEEP THE DISTRICT"
  const BANNER_HEARS := "THE SWEEP HEARS IT"
  const BANNER_BROKEN := "THE SWEEP IS BROKEN"
  func request(at: Vector2) -> void
  func on_seen(at: Vector2) -> void          # a power seen at `at`: extra alarm if a sweep of that district has a man inside
  func swept(district: int) -> bool
  func doors(district: int, from: Vector2) -> Array[Vector2]   # up to SWEEP_DOORS, nearest-next order
  ```
- Produces (GuardJobs): `const GLYPH_EYE: Array[int] = [0b00000, 0b01110, 0b11011, 0b01110, 0b00000]`.

Rules:
- Triggers: `danger_landed` (connected in `SweepDuty.setup`): `if crowd.power_witness(points, radius) != null` → `on_seen(points[0])` then `request(points[0])`; the seen branch of `_settle_doom()` (after line 2517 `if not seen: continue`) → `on_seen(at)` and `request(at)`; the three `_investigate()` sites through the forwarder. `request(at)` does nothing when `is_hushed() or is_hushed_at(at) or is_veiled(at)`, when `swept(district_of(at))`, or when `live(SWEEP).size() >= board.cap(SWEEPS)`; else posts `Job(SWEEP, at, need 4, reach INF)` with `data.district`, `data.seen_at`.
- `on_seen(at)` runs before `request(at)` and only for a live sweep of `district_of(at)` that has a living, unheld crew man inside the district rect and has added less than `SWEEP_ALARM_CAP`: `_hear_alarm(SWEEP_ALARM)`, banner `BANNER_HEARS`. The witness test that gates it is the trigger's (`power_witness`, a sweep man's 4.0 counts).
- Doors: houses (`kind == HOUSE`, not destroyed) whose centre is in the district rect; door = `_grid.nearest_walkable(h.center() + dir * (h.footprint.size.length() * 0.5 + 0.3))`, dir = from the house centre toward `seen_at` (Vector2.DOWN when equal); first the nearest to `seen_at`, then nearest-next from the last door; ties by the house's position `(y, x)`.
- Steps: crew `send_to_post(first door spot, false, true)` (hurried), `watch_far = true`, eye badge (`set_badge(GLYPH_EYE, <colour>, 1.5)` renewed each tick). The 30 s clock starts when the first crew man is inside the district rect. At each door all crew stand on spots 0.6 apart around it for `SWEEP_STAND` 3.0 with `talk_left = SWEEP_STAND`, then the next door (walking); after the last door they wait at it. End: clock 30.0; stage EVACUATION; no living, unheld crew man inside the district rect after the clock started (banner `BANNER_BROKEN`). On end: `watch_far = false`, `clear_badge()`, `back_to_post()`. Banner `BANNER` when the job starts (full crew assigned).
- `nearest_witness()` and `TempleReport._witness()`: a `watch_far` man's reach is `WATCH_SIGHT * sight_scale` (TempleReport: `WATCH_SIGHT`), others unchanged; pick the nearest within its own reach.
- Remove `_investigating`, `_return_investigators()` and `_looking()` (and their uses in `at_post`, `_walk_loops`, `mission_man`); `INVESTIGATORS`/`INVESTIGATE_SECONDS` go.
- Tag over the lead (`crew[0]`): `MapTag.person(lead, <colour>, "SWEEP %d" % ceili(left))`.

- [ ] Step: write the failing tests in `tests/test_sweep.gd`:
  ```gdscript
  static func _seen_trigger(t) -> void:         # danger_landed with a citizen 1.5 from the point -> 1 SWEEP job in that district
  static func _unseen_none(t) -> void:          # same landing in an empty district (nobody within 2.0 or the radius) -> none
  static func _witness_rules(t) -> void:        # only an asleep, a god-held, a guised or an inside person near -> none; inside the radius at 3.0 -> yes
  static func _doom_seen(t) -> void:            # a Silent Doom kill with a witness (_settle_doom) -> a sweep; unwitnessed -> none
  static func _local_emergency(t) -> void:      # the 4th incident in a district (alarms.incident true) -> a sweep there
  static func _hushed_veiled_none(t) -> void
  static func _one_per_district(t) -> void      # a second seen power there -> still 1
  static func _cap_two(t) -> void               # three districts -> 2; Capital -> 4; City.use(&"aldermere")
  static func _crew_four(t) -> void             # 4 nearest free men of any group; keep-one holds; 3 free -> no sweep
  static func _mission_man_never(t) -> void
  static func _clock_starts_inside(t) -> void   # 30.0 s counted from the first man inside the district rect
  static func _doors_six(t) -> void             # doors() <= 6, each a walkable point, first nearest seen_at; 3.0 s stand each
  static func _watch_sight(t) -> void           # a death 3.5 from a sweep man and nobody else -> nearest_witness() is him; at 4.5 -> null
  static func _watch_sight_report(t) -> void    # TempleReport._witness finds the same sweep man at 3.5
  static func _extra_alarm(t) -> void           # bell rung; 4 further seen powers in the district -> alarm += 2.0 three times (6.0 cap), banners "THE SWEEP HEARS IT" x3
  static func _not_on_watch(t) -> void          # a sweep man: on_watch() false
  static func _ends_thirty(t) -> void           # crew back_to_post, watch_far false, badges cleared
  static func _held_squad_breaks(t) -> void     # all four lured out of the district -> "THE SWEEP IS BROKEN"
  static func _evacuation_ends(t) -> void
  static func _capital_sweep(t) -> void         # Capital district: doors found, crew assigned; City.use(&"aldermere")
  ```
  test_alarm: the investigator checks become "a Local Emergency posts a sweep of 4 in that district" (`crowd.guard_jobs.live(GuardJobs.Kind.SWEEP)`), the 20 s return becomes the 30 s end.
- [ ] Step: run `--only=test_sweep`: RED.
- [ ] Step: implement (run `--import`).
- [ ] Step: run `--only=test_sweep`: GREEN.
- [ ] Step: focused suites: `test_alarm`, `test_lantern_knight`, the TempleReport suite (`grep -l TempleReport tests/*.gd`), the Silent Doom suite (`grep -l _settle_doom tests/*.gd`), `test_guard_jobs`, `test_beats`.
- [ ] Step (controller): re-record the references that moved, each with its reason; any row outside the slice's may-move column (d: rows with a seen power or a Local Emergency; never `none` cases with no incident) is a bug to fix first.
- [ ] Step (controller): rerun the gates for the missions this slice can touch: all five god_gate scenarios and all five Hunts (any seen power); compare each pair with its baseline row: none worse.
- [ ] Step: commit `feat: a seen power brings a 4-man sweep of the district for 30 s (replaces the investigators)`.

### Task 7 (slice e): Gate check

**Files:** Create `src/game/crowd/gate_check.gd`, `tests/test_gate_check.gd`. Modify `crowd.gd` (`_gates` release 1368-1369; setup), `marshal_manager.gd:88` (`_spot` becomes public `spot`, `_spot` kept as a one-line call so old callers stay), `person.gd` (`unmask()`), `guard_jobs.gd` (`is_free`, `GLYPH_ALERT`).

**Interfaces:**
- Produces (GateCheck extends Duty):
  ```gdscript
  const PER_GATE := 2
  const POST_REACH := 2.5
  const GATE_LOOK := 2.5
  const GATE_SPOT_ALARM := 2.0
  const STAND_DOWN := 5.0          # nobody near the mouth this long: a corps-NONE checker steps back to his post
  const TAG := "GATE CHECK"
  const BANNER := "THE GATE GUARD SEES THROUGH IT"
  func checkers(gate: Structure) -> Array[Person]   # up to PER_GATE: corps NONE or MARSHAL, wall group, town_post within 2.5 of the gate
  func checked(gate: Structure) -> bool             # at least one checker on his spot (NONE) or within GATE_LOOK of the mouth (MARSHAL), free, unheld
  func check(p: Person, gate: Structure) -> bool    # spots p if guised() or held_by_god() and within the checker's sight; true when spotted
  ```
- Produces (Person): `func unmask() -> bool` (erases `statuses[&"guise"]`; ends a hold: WHISPERED `end_whisper()`, CONFUSED `_come_to()`, COMPELLED `release_compulsion()`, lured OBSERVE `_observe_left = 0.0`; true when anything ended).
- Produces (GuardJobs): `const GLYPH_ALERT: Array[int] = [0b00100, 0b00100, 0b00100, 0b00000, 0b00100]`; `is_free(p)` also true for a man whose only record is a GATE job (a gate checker is lowest priority: any other kind may take him; that is not a pull); keep-one counts a GATE checker as staying.
- Produces (MarshalManager): `func spot(mouth: Vector2, out_dir: Vector2, j: int) -> Vector2`.

Rules:
- `post_jobs()`: for each standing, walkable gate of `_town.gates` (not destroyed), one GATE job per corps-NONE checker not yet on it (`need 1`, `may_take` only that man, who must be `is_free`); MARSHAL checkers need no record (corps men are not board men). Checkers chosen nearest the gate first, ties by `stagger`.
- A corps-NONE checker steps to `marshals.spot(mouth, out, profile.marshals_per_exit + k)` (k = his index among the gate's checkers; mouth/out as `MarshalManager.exits()` computes them) when `waiting_at(gate) > 0` or anyone alive is within `GATE_LOOK` of the mouth; he steps back to his post after `STAND_DOWN` 5.0 with neither. Each step is one `send_to_post`. At the spot he faces the nearest person within GATE_LOOK with `talk_left = 1.0`.
- Spotting, once a tick over the people within `GATE_LOOK` of each checked gate's mouth, and at crowd.gd:1368 for the one released: `check(p, gate)`: `not crowd.is_veiled(p.ground_pos)`, some checker with `p.ground_pos.distance_to(c.ground_pos) <= crowd.sight(c, p.ground_pos, Crowd.WATCH_SIGHT * crowd.sight_scale)`, and `p.guised() or p.held_by_god()` → `p.unmask()`, `crowd.alarms.incident(gate.center())`, `crowd._hear_alarm(GATE_SPOT_ALARM)`, `c.set_badge(GLYPH_ALERT, <colour>, 2.0)`, `duty_event.emit(Kind.GATE, BANNER, gate.center())`. A person is checked at most once per gate per 10 s (a `{instance_id: clock}` map; ids are only keys, never sorted).
- The check never touches `_gate_next`, `gate_interval` or the queue order.
- Every checker on his spot (or a marshal at his gate) has `watch_far = true` and an eye badge; off it, false.
- Tags: `MapTag.place(gate.center(), <colour>, TAG)` on every gate with an assigned free, unheld checker.

- [ ] Step: write the failing tests in `tests/test_gate_check.gd`:
  ```gdscript
  static func _checkers(t) -> void:             # Aldermere: every standing gate has 1..2 checkers, each wall group, town_post within 2.5
  static func _marshal_checks(t) -> void:       # a gate whose in-gate guards are marshals is checked (high tier profile)
  static func _step_on_approach(t) -> void:     # a calm walker within 2.5 of the mouth -> the NONE checker walks to his spot; 5.0 s after -> back
  static func _spot_guised(t) -> void:          # a guised citizen crosses a checked gate: guise gone, incident +1, alarm += 2.0 (x UNWARNED before the bell), banner
  static func _spot_held(t) -> void:            # a whispered citizen released from the queue at a checked gate -> no longer held_by_god()
  static func _unchecked_passes(t) -> void:     # checkers killed -> the same guised citizen passes; no tag "GATE CHECK"
  static func _no_sight(t) -> void:             # NO SIGHT on the checker, the person 2.5 away -> not spotted
  static func _veiled(t) -> void
  static func _never_slows(t) -> void:          # the same fleeing queue with and without checkers: identical release clocks for 60 s
  static func _fire_takes_checker(t) -> void:   # a fire's pick() takes a NONE checker (his GATE job ends); a marshal is never taken
  static func _once_per_ten(t) -> void          # a person standing at the mouth is checked once in 10 s
  static func _mission_man_never(t) -> void
  static func _capital_gates(t) -> void:        # every Capital gate has a marshal checker; City.use(&"aldermere")
  ```
- [ ] Step: run `--only=test_gate_check`: RED.
- [ ] Step: implement (run `--import`).
- [ ] Step: run `--only=test_gate_check`: GREEN.
- [ ] Step: focused suites: `test_marshals`, `test_capital_evac`, the Corpse Guise suite (`grep -l CorpseGuise tests/*.gd`), `test_guard_jobs`, `test_sweep`.
- [ ] Step (controller): re-record the references that moved, each with its reason; any row outside the slice's may-move column (e: rows where someone held or guised passes a manned gate, or a queue forms; never calm rows with nobody at a gate) is a bug to fix first.
- [ ] Step (controller): rerun the gates for the missions this slice can touch: god_gate `lamb warning`, hunt_gate `hide_faithful expel_inquisitor face_halcyon break_hunt` (escort-type missions, Death rows: Corpse Guise at gates); compare each pair with its baseline row: none worse.
- [ ] Step: commit `feat: gate guards check everyone passing a manned gate; a guise or the god's hold is seen through`.

### Task 8 (slice f): Shelter escort

**Files:** Create `src/game/crowd/shelter_escort.gd`, `tests/test_shelter_escort.gd`. Modify `crowd.gd` (`_tend_households` 1913-1930), `person.gd` (`panic` 1329-1334), `shelter_manager.gd` (new `room()`, `nearest_with_room()`), `guard_jobs.gd` (`GLYPH_SHIELD`).

**Interfaces:**
- Produces (ShelterManager): `func room(s: Structure) -> int` (`capacity(s) - inside - coming`, large for a hallowed one; 0 when not `_usable` or `_barred`); `func nearest_with_room(at: Vector2, reach: float, need: int) -> Structure` (nearest by `s.distance_to(at)`, ties in `shelters` order).
- Produces (ShelterEscort extends Duty):
  ```gdscript
  const ESCORT_SQUADS := 3          # scaled
  const CREW := 2
  const SHELTER_REACH := 12.0
  const STEADY_R := 2.0             # EscortManager.STEADY_R
  const KEEP := 1.5                 # EscortManager.REACH
  const TAG := "ESCORT"
  const BANNER := "A HOUSEHOLD SCATTERS"
  func escorting(family: int) -> bool
  func steadied(p: Person, from: Vector2, radius: float) -> bool
  ```
- Produces (GuardJobs): `const GLYPH_SHIELD: Array[int] = [0b11111, 0b11111, 0b11111, 0b01110, 0b00100]`.

Rules:
- `post_jobs()`, only while `CITY_EMERGENCY <= stage < EVACUATION`: households (`crowd._households` keys, in key order) with at least one member in `Mind.REGROUP`, without a goal, within `HOME_REACH` 1.2 of `profile.home`, not `escorting()`, and `nearest_with_room(home, SHELTER_REACH, members)` not null; nearest household to the nearest free man first; at most `board.cap(ESCORT_SQUADS)` live. `Job(SHELTER, home, need 2, reach INF)`, `data.family`, `data.shelter`.
- `_tend_households()` skips a family `escorting()` (else it would send them to flee: a fully home family flees at once, others after HOUSEHOLD_WAIT).
- Steps: squad `send_to_post(home spot, false, true)`; when both stand within `GOAL_REACH * 2.0` of home, every living REGROUP member of the family `regroup(door)` (door = `ShelterManager._door(s, home)`); the squad re-anchors once a tick to the group's centroid offset by `EscortManager.OFFSETS[i]` when it has drifted more than `KEEP` from it; a member within `ShelterManager.DOOR_REACH` of the door is sent in with `shelters.send_in(p, s)`; members get a shield badge (`set_badge(GLYPH_SHIELD, <colour>, 1.5)` renewed); tag `MapTag.person(crew[0], <colour>, TAG)`.
- `panic()` (person.gd:1332, before the shelter roll so no rng is drawn): `if crowd != null and crowd.shelter_escort != null and crowd.shelter_escort.steadied(self, from, radius): return`. `steadied` = he is a member of a live escort job, `ground_pos.distance_to(from) > radius`, and a living, unheld crew man is within `STEADY_R` 2.0. O(1) with no escort live (`live(SHELTER).is_empty()` first).
- Ends: all members inside or dead; stage EVACUATION (members untouched: `_evacuate()` makes them flee; the squad `back_to_post()`); the last crew man dies: every member still outside `panic(his ground_pos, 1.0)` and banner `BANNER`. A held crew man does not count for `steadied` (the group is unsteadied). Pull never takes a SHELTER man.

- [ ] Step: write the failing tests in `tests/test_shelter_escort.gd`:
  ```gdscript
  static func _trigger(t) -> void:              # City Emergency; a household's first member home, a shelter with room 8.0 away -> 1 job
  static func _no_shelter_none(t) -> void       # nearest shelter 12.5 away or full -> none
  static func _before_after(t) -> void          # stage LOCAL_EMERGENCY -> none; EVACUATION -> none
  static func _cap_three(t) -> void             # 5 waiting households -> 3 jobs; Capital -> 6; City.use(&"aldermere")
  static func _crew_two(t) -> void              # nearest free; keep-one; 1 free -> none
  static func _mission_man_never(t) -> void
  static func _not_tended(t) -> void            # an escorted family is not sent to flee by _tend_households for 30 s
  static func _walk_in(t) -> void               # members walk in REGROUP (walk_speed of REGROUP) and end inside the shelter (Mind.SHELTER)
  static func _steady(t) -> void                # a near miss (from 3.0, radius 1.0) on a member 1.5 from a squad man: mind stays REGROUP, rng state unchanged
  static func _direct_hit(t) -> void            # the same member inside the danger's radius -> PANIC
  static func _held_unsteadies(t) -> void       # both squad men confused -> the near miss panics him
  static func _scatter(t) -> void               # kill both squad men -> every member outside PANIC, banner "A HOUSEHOLD SCATTERS"
  static func _evacuation_ends(t) -> void       # members flee as today, squad back to post
  static func _capital_escort(t) -> void        # Capital: one household led into a shelter; City.use(&"aldermere")
  ```
- [ ] Step: run `--only=test_shelter_escort`: RED.
- [ ] Step: implement (run `--import`).
- [ ] Step: run `--only=test_shelter_escort`: GREEN.
- [ ] Step: focused suites: `test_shelter`, `test_escorts`, `test_alarm`, `test_guard_jobs`, `test_citadel_guard`.
- [ ] Step (controller): re-record the references that moved, each with its reason; any row outside the slice's may-move column (f: rows that reach City Emergency; never rows that do not) is a bug to fix first.
- [ ] Step (controller): rerun the gates for the missions this slice can touch: all five god_gate scenarios and all five Hunts (loud rows reach City Emergency); compare each pair with its baseline row: none worse.
- [ ] Step: commit `feat: soldier pairs lead waiting households to shelter; an escorted group holds against a near miss`.

### Task 9: Photographs, bots, full checks (controller + one implementer step)

**Files:** Modify `src/game/game.gd` (the `match show` at 426-480), `tools/dev/behaviour_check.gd` (only if needed).

- [ ] Step (implementer): add `--show=` cases `duty-guard`, `duty-beat`, `duty-corpse`, `duty-cordon`, `duty-sweep`, `duty-gate`, `duty-escort`: each `go_to(Screen.MISSION)` as `"play"` does (line 459), then on the next frame stages its duty through the crowd's own calls (`rally()` and arrival; 30 s of steps; a `field.kill(p, &"mob")` 3 m from a beat pair; a house ignited and doused; a `danger_landed`-raising cast beside a citizen; a guised citizen walked to a gate; `_on_stage(CITY_EMERGENCY)` and a household home) and stops the clock with its tag/banner on show; the save is the show's own (`save_path_for`). Test: `test_game_show` style check that each name is matched (if such a suite exists: `grep -l "save_path_for" tests/*.gd`), else none.
- [ ] Step (controller): `SCENE=res://scenes/game.tscn bash tools/capture.sh --show=duty-<x> --capture` for each; look at the frames: ranks facing out, walking pairs, the crouch, the rope, eye/shield badges, tags readable at 640x360.
- [ ] Step (controller): if a gate pair is below its baseline row, fix the scripted policy in `tools/dev/behaviour_check.gd` (fix a policy, never the rule) and re-run that pair.
- [ ] Step (controller): `bash tools/dev/run_suite_parallel.sh 6` → `failures=0`; `bash tools/dev/refs_check.sh` → all OK after the last re-record; all ten gates into `.gate-after/`, judged against `.gate-baseline/`; FLOW alone on a quiet machine (`--flow-test`; memory: fails alone = a real bug); a quiet-machine frame-rate pair within noise.

### Task 10: Land (controller)

- [ ] Step: `git fetch`; trial-merge origin/feat/Develop-Main on a throwaway commit (memory: merge-tree misses uncommitted work). Check the alarm entry points named in Global Constraints against the incoming "alarm and alert on ability use" changes: `_hear_alarm`, `AlarmManager.incident`, `district_of`, `alarms.stage`, `is_hushed`/`is_hushed_at`, `is_veiled`, `danger_landed`, `_settle_doom`'s seen branch, the three `_investigate()` sites; a renamed or moved one is fixed on this branch before landing.
- [ ] Step: `bash tools/dev/land.sh`; then fast-forward feat/Develop-Main and push by hand. The Dev Ledger and the Discord posts are the controller's.

---

## Rulings this plan made where the spec left a choice

- Corpse duty's found incident that puts its district into Local Emergency also requests a sweep (through `_investigate()`), as every other Local Emergency does.
- Sides of the guard are dealt S, E, N, W; stood-down men join post group 0 (the yard).
- A gate checker's GATE record yields to any other kind; that is not a pull.

## Gaps

- None found that no task covers. The spec's "frame rate within noise on a quiet machine" is checked once, in Task 9, not per slice (the machine is rarely quiet).

## Contradictions found

1. **forgo_rally sets `_rallied`.** Spec: rescue_manager.gd:159 "reads `Crowd._rallied`". Code: `forgo_rally()` (crowd.gd:2272-2273) also sets `_rallied = true`, so a leaderless town would send squads to piles and `_free_soldiers()` would hand out nobody although no guard formed. Ruling: a new `Crowd.called_up()` (true only after `rally()`) is read there, in `_refill()` and in `_free_soldiers()`.
2. **Households do not wait at home.** Spec (f): trigger "a household in `Mind.REGROUP` waiting at home". Code: `_tend_households()` (crowd.gd:1913-1930) makes a household flee the moment all its members are home, and the rest after `HOUSEHOLD_WAIT` 20 s, so a whole household never waits. Ruling: the trigger is the first member home; an escorted family is skipped by `_tend_households()`.
3. **A stepped-aside gate checker looks like a mission man.** Spec: checkers "step to spots behind the marshals'" and "nobody is re-posted"; the inferred mission-man rule counts "anchored away from his post with no board job". Ruling: a corps-NONE checker holds a GATE record (so he is not a mission man) and that record yields to any higher kind, which the spec asks for ("a fire or a sweep may take a corps-NONE checker"), although the spec also says "only CITADEL may pull".
4. **`_spot_near()` draws from the shared rng** (crowd.gd:710-723 uses `_rng`). Spec: "snapped to open ground" for slots and "nearest free yard spots". Ruling: duties snap with `_grid.nearest_walkable()` and `Crowd.yard_spots()`, never `_spot_near()`.
5. **`nearest_witness()` counts the asleep and the god-held** (crowd.gd:2489-2500). Spec (d): a "seen" power needs a witness "awake, not held by the god". Changing `nearest_witness()` would move Silent Doom and The Warning rows. Ruling: a new `power_witness()` for the sweep; `nearest_witness()` changes only for `watch_far` men's 4.0.
6. **A hushed kill reaches crowd.gd:2476.** Spec: set `Remain.counted` "where `_on_killed()` reaches `_hear_alarm`", but `_hear_alarm()` adds nothing when hushed (crowd.gd:1691), and the spec counts a hushed kill as never counted. Ruling: `counted = not is_hushed()` there.
7. **A beat flag would un-watch a director's man.** Spec: "a man on a beat is not a posted watch". A director may station a beat man (`_free_soldiers()` picks patrol men). Ruling: `on_beat()` is true only while his anchor is his town post (`post == town_post == anchor`), so a stationed man watches as today.
