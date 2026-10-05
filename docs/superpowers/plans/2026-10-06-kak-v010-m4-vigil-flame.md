# KAK v0.10 M4 — The Vigil Flame and Halcyon's Searchlight Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** the Theft path's Night 2, *The Vigil Flame*, becomes a real mission. Wren the urchin swaps Halcyon's eternal flame out of the flame-bearer's lantern unseen, then carries it to Mira's shrine at the west forest edge while Halcyon's Searchlight sweeps the town from the Temple's spire.

**Architecture:**
- **`VigilFlameDirector`** replaces the placeholder (`MissionBook.vigil_flame()` held until dawn). It runs the night in two phases.
  - **Phase 1, the swap:**
    - The flame-bearer walks the Vigil's route (the six wayside shrines' points from Broken Lanterns, no shrines placed) with two acolytes, looping, at a solemn pace. The flame passes to an acolyte if he falls.
    - At 0:50 **Wren** comes. He is the lay citizen nearest the lantern who is not of the Faith, in his own look, marked on the HUD.
    - Whispered within `SWAP_REACH` of the lantern, Wren takes hold, and the swap takes 3 s.
    - It is judged by Silent Doom's witness rule: a Faithful other than the bearer within `Crowd.DOOM_WITNESS`, not held by the god, sees it and reports it (`TempleReport`).
    - Left 30 s without a whisper, Wren tries it himself.
    - At 1:30 the route shortens straight to the Temple. The bearer reaching it with the real flame loses the night.
  - **Phase 2, Halcyon's Searchlight:**
    - From the swap until the flame is home, beams sweep the town: one, then a second 30 s after the swap. A Will-o'-Wisp is a decoy. In the last 20 s a beam stops to search at the latest noise.
    - A touch on Wren adds +50 to the Gaze. A Faithful touched by a beam stops and prays.
    - Wren carries the flame to Mira's shrine to win.
- **`Searchlight`** is pure logic, a `RefCounted`: the beams' sweep, the second beam, the decoy, the search stop and `touches(pos)`. Headless tests run it with no FX node.
- **`SearchlightFx`** is an `FxTimeline` that only draws a `Searchlight`:
  - the spire's lighthouse glow;
  - additive gold cones;
  - ground light pools registered with the `LightField`, so building faces in a beam light up;
  - drifting dust;
  - the impact dim.

  The director casts it at the swap when it has an `FxContext` (never in tests).
- **Shared pieces, lifted rather than copied:**
  - `MissionDirector` gains `reports`, `reports_started`, `_report(seer, door)`, `_step_reports(delta)`, `_carrying(p)`, `BLIND` and `faithful_seeing(at, reach, exclude)`, all lifted out of `MirasHouseDirector`, which then uses them unchanged in play.
  - `VigilRoute` gains `shorten_to(at)`.
- **Objectives:**
  - `GazeObjective`;
  - `FlameObjective`: wins on `flame`, loses on `kept` or `wren`;
  - a dawn `ClockObjective` (`late`);
  - the bonus `UnseenHandsObjective`.
- **Tools:**
  - a `flame` behaviour scenario (`--case=none|play`);
  - `--show=flame` and `--show=flame-beams` photographs;
  - a `--bench-beams` bench hook for spec §7's frame-rate check.

**Tech Stack:** Godot 4.7.2, GDScript; headless tests in `tests/run_all.gd`; scripted scenarios in `tools/dev/behaviour_check.gd`.

**Spec:** `docs/superpowers/specs/2026-10-05-kak-v010-lantern-campaign-design.md`. Read §3.4, §4.1 ("Night 2 — the Vigil" and "Theft — The Vigil Flame": Phase 1, the swap, and Phase 2, Halcyon's Searchlight), §6, §7 (including the searchlight bench) and §8.4 before any task. This plan covers **M4**. M2's plan (`docs/superpowers/plans/2026-10-05-kak-v010-m2-gaze-miras-house.md`) and M3's (`docs/superpowers/plans/2026-10-06-kak-v010-m3-broken-lanterns.md`) built the pieces reused here.

## Global Constraints

- **Baseline:** branch `claude/lantern-campaign-spec` at `5a41ff6`: M3 complete (its tag `kak-v010-m3` is the controller's to set) with origin's art animation round merged. The milestone tag is `kak-v010-m4`.
- **No playtest notes yet:** the user has not playtested M2 or M3. Every number below is a starting value from the spec, and Task 7 measures it.
- **Machine:** the BURIN_NITRO laptop.
  - **Repository:** the main checkout is `C:\BURIN_NITRO\Godot\GIT\vfxProve` (Git Bash `/c/BURIN_NITRO/Godot/GIT/vfxProve`). Work in the checkout the controller names: this plan was written in the worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve/.claude/worktrees/game-concept-story-review-636208` on `claude/lantern-campaign-spec`. Never touch other sessions' worktrees.
  - **In a fresh worktree,** run the import first.
  - **Godot:** `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`.
- **Commands:**
  - **Import** (after a new `class_name` or a new test file): `timeout 900 $G --headless --editor --path . --import >/dev/null 2>&1`.
  - **Tests:** `timeout 1200 $G --headless --path . --script res://tests/run_all.gd 2>&1 | grep -v '^\s*at:' | grep -n "FAIL\|SCRIPT ERROR\|Parse Error\|checks="`. Expected: `checks=N failures=0`.
    - The baseline after M3 was **3235**. The merged tree includes origin's art tests, so it may be higher: **take the baseline from your first run** and report it. New suites add to it.
    - The `leaked` / `still in use` lines at exit are there at baseline too.
  - **Digest:** `$G --headless --path . -s tools/dev/state_digest.gd`. Expected: `digest=61267b7e90524d800bf1c3473a71146b`.
  - **crowd_check:** `$G --headless --path . --fixed-fps 60 -s tools/dev/crowd_check.gd`. Expected: `checksum=-346732806`.
  - **Behaviour (exact):** `$G --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=<name>`.
    - Give each run `timeout 600`. Run the ten in the background with a long limit: they take about 15 min.
    - The baseline is from the VFX merge; M2 and M3 moved none of them. A gate run on the merged tree is in progress: if it moves them, the controller updates this list.
    - `calm --seconds=60`: -355092532
    - `gates`: 589794389
    - `fire`: 250399241
    - `rite --interrupt`: -948525703
    - `soldiers --case=escort`: -778609674
    - `warning --case=none|doom|whisper|discord|mix`: -489775734, -905773030, -588314462, -997640091, -206935500
  - **Mira's House stays exact through M4:** `--scenario=miras --case=play` prints `BEHAVIOUR miras result won=false reason=gaze time=94.9 believers=3 gaze=100 reports=3` and `BEHAVIOUR checksum=-200101558`. Task 1 Step 1 records them on your tree; Tasks 1 and 4 compare against them.
  - **Broken Lanterns stays as it is:**
    - `--scenario=lanterns --case=none --seed=1` loses with `reason=relit`;
    - `--case=play --seed=1|2|3` each win, at 141–172 s.

    Task 1 Step 1 records the four result lines.
  - **FLOW:** `$G --path . --audio-driver Dummy --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep "FLOW"`. Expected: `failures=0`. The baseline is **82**. Task 4 changes what one step checks (the Vigil Flame night is won by the flame home instead of held), not how many steps there are.
  - **Mission tests:** `--mission-test` within a few of: buildings about 53, citizens 184–193, escaped 0–1, stability 67–71%, citadel 50%. `--mission=warning --mission-test` gives `won=false reason=bell time≈24`. These are not exact (memory: hitstop wall clock).
  - **Captures:** `GODOT=$G SCENE=res://scenes/game.tscn bash tools/capture.sh --show=<name> --capture`.
  - **Bench:** `$G --path . --audio-driver Dummy --scene res://scenes/mission.tscn -- --bench` (Last Judgement). Task 8 has the full alternating procedure. Bench on a quiet machine: close Discord, Edge, Chrome, ChatGPT and other Godot windows.
- **Powers:** 38 powers; the Authorities are Ruin, Veil, Dominion, Passage, Death, Decree. The Vigil Flame's pool stays `MissionBook.VIGIL_POOL`: whisper, doom, wisp, discord, thorns.
- **Test style:** as in M2 and M3.
  - `extends RefCounted`, `static func run(t)`, `t.check` / `t.near`.
  - Register each new file at the end of `SUITES` in `tests/run_all.gd`.
  - Build the town and crowd like `tests/test_broken_lanterns.gd`'s `_setup()`, and step `crowd.advance(DT)` then `rules.advance(DT)`.
  - **Headless tests never move or think people:** `Crowd.advance()` does not call `Person.frame()`. Put people where a test needs them with `_arrive()`, and set a mind by hand to stand for what thinking would do. A whisper never wears off headless (nothing counts it down).
  - **Tests run with ctx null:** no FX. The Searchlight's logic (`touches`, the beams' paths, the decoy, the search) lives in `Searchlight` and is tested alone. `SearchlightFx` is checked by its pure `cone_points()` and by eye.
- **Code style:**
  - tabs; `##` docs in full sentences; `UPPER_CASE` constants with a `##` comment.
  - **No enum gains a value.** `CitizenProfile.Role`, `CitizenProfile.Faith`, `Structure.Kind` and `Person.Corps` stay as they are. Wren is an existing lay citizen in his own look, with no `URCHIN` role, because a new role would need art on both art paths.
  - **Mission-only scales for balance** (M3's lesson: `GazeMeter`'s numbers are shared by Mira's House and Broken Lanterns): `FlameGaze` with `SEEN_DEATH_SCALE`, plus `PRAYER_SCALE`, both 1.0 to start.
- **Nothing outside the Vigil Flame may change.** The Warning, The Long Night, Last Judgement, Mira's House and Broken Lanterns play exactly as before. Every exact gate stays identical.
  - Task 1 lifts Mira's House's report and sight helpers into `MissionDirector` with no change in play, and proves it with the Mira's House reference.
  - `VigilRoute.shorten_to()` is new and opt-in.
  - The Vigil Flame places no structure.
- **Git:**
  - stage explicit paths, with each new script's `.gd.uid` file;
  - never stage `default_bus_layout.tres`, `captures/`, `.codex/` or `concepts/`;
  - commit subjects are tagged `(v0.10)` and end with a `Co-Authored-By:` line naming the model that commits. The blocks below show `Claude Opus 5.5`; write your own model's name if it is different;
  - **do not push or tag:** the controller does that at the gate.
- **Tuning latitude:** the code was written against `5a41ff6` and has not been run.
  - Fix real bugs and keep each test's intent.
  - **Placement constants may move** when the town's geometry needs it: `MIRA_SHRINE`, `CAMERA_AT`, `WATCH_DIST`, `SearchlightFx.SPIRE_PX` / `SPIRE_GLOW_PX` / `LAMP_HALF`, the cones' and dust's look, and the tests' `OUT` / `AWAY`. These two must stay beyond `Searchlight.FAR + POOL_R` of the spire; `_cast` checks it.
  - **Gameplay numbers move only in Task 7.**
  - Report every deviation.

## Review Focus

These are inputs the spec implies but no feature test exercises. Each line has its test in the owning task.

1. **The flame-bearer and both acolytes are struck down before the swap.** The flame passes to the first acolyte, then the next. With all three dead, the lantern lies where its last bearer fell. The HUD still marks it, Wren can still take it there, and there is no SCRIPT ERROR. *Test:* Task 4 (`_focus`).
2. **Wren is held or frightened mid-swap** (a Discord meant for an acolyte catches him). The swap is broken. Once Wren is whispered back, it starts again from the full 3 s. *Test:* Task 4 (`_focus`).
3. **Nobody is left to be Wren at 0:50:** everyone outside the Faith is dead or indoors. The night is lost ("wren") at once, with no SCRIPT ERROR. *Test:* Task 4 (`_focus`).
4. **A beam rests on Wren:** a search stopped at his own noise, or a decoy over him. It counts **one** touch until he leaves the light, not +50 every frame. *Test:* Task 5 (`_touches`).
5. **The night is let go mid-Phase 2** (Restart, Pause → Campaign, quit). The light goes out, the Faithful at prayer get up, the cast and kill signals are let go, and there is no SCRIPT ERROR. *Test:* Task 5 (`_teardown`).

## Where this plan departs from the spec

The controller reports these to the user at the gate.

1. **The swap is judged as it completes.** A Faithful other than the bearer within `Crowd.DOOM_WITNESS` (2.0) of Wren, not held by the god (Discord, a whisper), sees it. The bearer is the one robbed and never sees it. The acolytes walk 0.7 from him, so they must be drawn off, held or killed first.
2. **Wren takes hold and keeps pace.** Contact within `SWAP_REACH` (whispered there, or on his own try) starts the swap. He keeps pace on a duty for 3 s within `SWAP_HOLD`, so a walking bearer does not break it.
3. **Wren is a lay citizen in his own look,** the one nearest the lantern at 0:50. A blue diamond and the HUD's arrow mark him. **Mira's shrine is a marked spot outside the west wall, not a structure.** The urchin's and the shrine's art wait for M5.
4. **What the light hears.** Every cast but Mind Whisper (it speaks in the mind) and every death is a noise. A Will-o'-Wisp is both a noise and a decoy. The search uses the latest noise, even one made before the light woke.
5. **A touch counts once each time Wren comes into a beam** (edge-triggered).
   - A Faithful a beam touches prays for 5 s where he stands, not only while lit.
   - The Vigil's walkers and report carriers never stop to pray.
6. **The flame passes on** when the bearer falls (as in M3). With all three dead, the lantern lies where the last one fell, and Wren can take it there.
7. **Shape of the light.** A beam is a pool of light (radius 2) on the ground, swept round the spire, with a cone drawn down to it. Only the pool touches, not the cone's whole wedge.
8. **Words.** Banners stand in for Cael's lines (M5).
9. **The bench.** `--bench-beams` lights both beams at once under the mission's opening camera, then benches.

---

## File structure

| File | Responsibility |
|---|---|
| `src/game/mission/mission_director.gd` | Shared: `BLIND`, `reports`, `reports_started`, `faithful_seeing()`, `_report()`, `_step_reports()`, `_carrying()` |
| `src/game/mission/miras_house_director.gd` | Uses the shared helpers (no change in play) |
| `src/game/mission/vigil_route.gd` | `shorten_to(at)` |
| `src/game/mission/searchlight.gd` | **New.** `Searchlight`: the beams' logic |
| `src/fx/searchlight_fx.gd` | **New.** `SearchlightFx`: draws a `Searchlight` |
| `src/game/mission/vigil_flame_director.gd` | **New.** The Vigil Flame |
| `src/game/mission/flame_objective.gd`, `unseen_hands_objective.gd` | **New.** The night's win and losses, and its bonus |
| `src/game/mission/mission_book.gd` | `vigil_flame()` becomes the real mission |
| `src/game/ui/results_screen.gd` | The titles `flame`, `kept`, `wren`, `late` |
| `src/game/game.gd` | FLOW's Night 2 wins the Vigil Flame; `--show=flame`, `--show=flame-beams` |
| `src/game/mission.gd` | The `--bench-beams` hook |
| `tools/dev/behaviour_check.gd` | The `flame` scenario |
| `tests/test_searchlight.gd`, `tests/test_vigil_flame.gd` | **New** tests |
| `tests/test_vigil_route.gd`, `tests/test_mission_book.gd` | New checks |

---

## Milestone 4 — The Vigil Flame

### Task 1: Shared reports and sight; the Vigil's route shortened

**Files:**
- Modify: `src/game/mission/mission_director.gd`, `src/game/mission/miras_house_director.gd`, `src/game/mission/vigil_route.gd`, `tests/test_vigil_route.gd`

**Interfaces:**
- Consumes: `TempleReport.new(p, door)`, `TempleReport.step()`, `.carrier`, `.delivered`, `.is_open()`; `MissionDirector.faithful`, `gaze`, `rules`, `crowd`.
- Produces, on `MissionDirector`:
  - `const BLIND := [Person.Mind.CONFUSED, Person.Mind.WHISPERED]`;
  - `var reports: Array[TempleReport]`, `var reports_started := 0`;
  - `func faithful_seeing(at: Vector2, reach: float, exclude: Person = null) -> Person`;
  - `func _report(seer: Person, door: Vector2) -> void`;
  - `func _step_reports(delta: float) -> void`;
  - `func _carrying(p: Person) -> bool`.
- Produces, on `VigilRoute`: `func shorten_to(at: Vector2) -> void`.

- [ ] **Step 1: Record the references.** Run Import, Tests (keep the count as your baseline), and:
  - `--scenario=miras --case=play`;
  - `--scenario=lanterns --case=none --seed=1`;
  - `--scenario=lanterns --case=play --seed=1`, `--seed=2` and `--seed=3`.

  Keep each `BEHAVIOUR … result …` line, and the miras run's `BEHAVIOUR checksum=…`. Compare them with Global Constraints and report any difference before going on.

- [ ] **Step 2: Write the failing test.** In `tests/test_vigil_route.gd`, insert just before the final `_done(s)`:

```gdscript
	# v0.10 M4, for the Vigil Flame: the route shortened, straight to one place, where the walk ends.
	var b6: Person = crowd.citizens[24]
	var a6: Array[Person] = [crowd.citizens[26]]
	var v6 := VigilRoute.new().setup(points, b6, a6)
	v6.loop = true
	v6.start()
	var home := grid.nearest_walkable(points[0] + Vector2(0.0, -3.0))
	v6.shorten_to(home)
	t.check(v6.route.size() == 1 and v6.route[0] == home and v6.leg == 0 and not v6.loop and v6.detour == Vector2.INF
		and b6.mind == Person.Mind.DUTY and b6.anchor.distance_to(home) < 0.01,
		"the route shortened, the bearer makes straight for the one place")
	_arrive(b6, home)
	_tick(v6)
	t.check(v6.finished and not v6.active, "and there the walk is over")
```

- [ ] **Step 3: Run the tests to verify they fail.** Expected: a Parse Error naming `shorten_to`.

- [ ] **Step 4: `shorten_to()`.** In `src/game/mission/vigil_route.gd`:
  - At the end of the header comment, add the line: `## The Vigil Flame (M4) shortens it: straight back to the Temple, where it ends (shorten_to()).`
  - After `divert()`, add:

```gdscript
## Send the walk straight to `at`, where it ends (v0.10 M4: the Vigil Flame's suspicious priest turns it home). It no
## longer loops, and any detour is called off; on his way, the bearer makes for `at` at once.
func shorten_to(at: Vector2) -> void:
	route = PackedVector2Array([at])
	leg = 0
	loop = false
	divert(Vector2.INF)
```

- [ ] **Step 5: Lift the reports and the Faithful's sight into `MissionDirector`.** In `src/game/mission/mission_director.gd`:
  - Under `var faithful: Array[Person] = []`, add:

```gdscript
## Reports of the god at work on their way to the Temple (v0.10: Mira's House, the Vigil Flame), and how many began.
var reports: Array[TempleReport] = []
var reports_started := 0

## Minds a Faithful does not see from (v0.10): the god's own holds.
const BLIND := [Person.Mind.CONFUSED, Person.Mind.WHISPERED]
```

  - At the end of the file, add:

```gdscript
## The nearest Faithful within `reach` of `at` who is out in the open, alive, not held by the god and not `exclude`
## (v0.10: who sees what the god does); else null.
func faithful_seeing(at: Vector2, reach: float, exclude: Person = null) -> Person:
	var best: Person = null
	for f in faithful:
		if not _alive(f) or f.inside or f.mind in BLIND or f == exclude:
			continue
		var d := f.ground_pos.distance_to(at)
		if d <= reach and (best == null or d < best.ground_pos.distance_to(at)):
			best = f
	return best


## `seer` runs to the Temple's door `door` to report what they saw, unless already carrying a report.
func _report(seer: Person, door: Vector2) -> void:
	if _carrying(seer):
		return
	reports.append(TempleReport.new(seer, door))
	reports_started += 1
	rules.banner.emit("A FAITHFUL RUNS TO THE TEMPLE")


## Each report runs on; one delivered fills the Gaze. Reports delivered or ended are let go.
func _step_reports(delta: float) -> void:
	for r in reports:
		r.step(delta, crowd)
		if r.delivered:
			gaze.fill()
	reports.assign(reports.filter(func(r: TempleReport) -> bool: return r.is_open()))


## `p` is carrying a report to the Temple.
func _carrying(p: Person) -> bool:
	for r in reports:
		if r.carrier == p:
			return true
	return false
```

- [ ] **Step 6: Mira's House uses them.** In `src/game/mission/miras_house_director.gd`:
  - Delete the two lines `## Minds a Faithful does not see from: the god's own holds.` and `const BLIND := [Person.Mind.CONFUSED, Person.Mind.WHISPERED]`.
  - Delete the two lines `var reports: Array[TempleReport] = []` and `var reports_started := 0`.
  - In `step()`, replace these four lines with `_step_reports(delta)`:

```gdscript
	for r in reports:
		r.step(delta, crowd)
		if r.delivered:
			gaze.fill()
	reports.assign(reports.filter(func(r: TempleReport) -> bool: return r.is_open()))
```

  - Replace every call `_report(seer)`, `_report(venn)` and `_report(heard)` with `_report(seer, temple_door)`, `_report(venn, temple_door)` and `_report(heard, temple_door)`. There are four calls: two `seer`, one `venn`, one `heard`.
  - Delete the whole `_report(seer: Person)` function with its `## A Faithful runs to the Temple, unless already carrying a report.` line.
  - Delete the whole `faithful_seeing(at, reach)` function with its `##` line.
  - Delete the whole `_carrying(p)` function.

  The lifted versions do exactly what these did, in the same order (`exclude` defaults to null, and no living Faithful is null), so Mira's House plays the same.

- [ ] **Step 7: Run the tests to verify they pass.** Run Import, then Tests. Expected: `checks=N failures=0`, with N your baseline plus 2. `tests/test_miras_house.gd` passes unchanged.
- [ ] **Step 8: Check that Mira's House and Broken Lanterns are unchanged.** Run the five scenario runs of Step 1 again. Expected: the same lines.
- [ ] **Step 9: Commit.**

```bash
git add src/game/mission/mission_director.gd src/game/mission/miras_house_director.gd src/game/mission/vigil_route.gd tests/test_vigil_route.gd
git commit -m "refactor: share the Faithful's reports and sight; the Vigil's route can shorten (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 2: Halcyon's Searchlight, the logic

**Files:**
- Create: `src/game/mission/searchlight.gd`, `tests/test_searchlight.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Produces `Searchlight extends RefCounted`:
  - constants `MAX_BEAMS`, `POOL_R`, `SPIN`, `NEAR`, `FAR`, `REACH_PERIOD`, `START`, `TURN`, `SECOND_AFTER`, `SEARCH_LAST`, `DECOY_SECONDS`, `BEAM_SPEED`;
  - vars `spire: Vector2`, `on: bool`, `age: float`, `noise: Vector2`, `decoy: Vector2`, `decoy_left: float`, `decoy_beam: int`, `searching: bool`, `search_beam: int`;
  - funcs:
    - `setup(at: Vector2) -> Searchlight`;
    - `light(from := 0.0)`, `put_out()`;
    - `beams() -> int`, `beam_age(i) -> float`, `sweep_point(i, t) -> Vector2`, `aim(i) -> Vector2` (`Vector2.INF` for an unlit beam);
    - `touches(at) -> bool`;
    - `hear(at)`, `lure(at)`;
    - `step(delta, time_left)`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_searchlight.gd`:

```gdscript
extends RefCounted
## v0.10 M4 Halcyon's Searchlight (Searchlight), the logic alone: beams from the Temple's spire, each a pool of light
## swept round it on a predictable path; a second beam 30 s after the first; a Will-o'-Wisp's decoy holding the nearest
## beam 5 s; in the clock's last 20 s a beam stopping to search at the latest noise; touches() within a pool.

const DT := 0.05
const SPIRE := Vector2(0.8, -8.7)


static func _run(l: Searchlight, seconds: float, time_left := 999.0) -> void:
	for i in roundi(seconds / DT):
		l.step(DT, time_left)


static func run(t) -> void:
	_sweep(t)
	_second(t)
	_decoy(t)
	_search(t)
	_out(t)


static func _sweep(t) -> void:
	var l := Searchlight.new().setup(SPIRE)
	t.check(l.beams() == 0 and not l.touches(SPIRE) and l.aim(0) == Vector2.INF, "asleep, there is no beam and nothing is seen")
	l.light()
	t.check(l.on and l.beams() == 1 and l.aim(0).distance_to(l.sweep_point(0, 0.0)) < 0.001
		and absf(l.aim(0).distance_to(SPIRE) - Searchlight.NEAR) < 0.001, "lit: one beam, starting near the spire")
	_run(l, 10.0)
	t.check(l.aim(0).distance_to(l.sweep_point(0, 10.0)) < 0.05, "it follows its predictable path (%s)" % l.aim(0))
	var within := true
	for k in 80:
		var r := l.sweep_point(0, float(k) * 0.5).distance_to(SPIRE)
		within = within and r >= Searchlight.NEAR - 0.001 and r <= Searchlight.FAR + 0.001
	t.check(within, "its pool swings between NEAR and FAR of the spire")
	var turned := (l.sweep_point(0, 5.0) - SPIRE).angle() - (PI * 0.5 + Searchlight.SPIN * 5.0)
	t.check(absf(wrapf(turned, -PI, PI)) < 0.001, "and turns round the spire at SPIN")
	var at := l.aim(0)
	t.check(l.touches(at) and l.touches(at + Vector2(Searchlight.POOL_R - 0.05, 0.0)), "within its pool, it touches")
	t.check(not l.touches(at + Vector2(Searchlight.POOL_R + 0.05, 0.0)), "just outside, it does not")


static func _second(t) -> void:
	var l := Searchlight.new().setup(SPIRE)
	l.light()
	_run(l, Searchlight.SECOND_AFTER - 1.0)
	t.check(l.beams() == 1 and l.aim(1) == Vector2.INF, "one beam until 30 s after it lit")
	_run(l, 1.5)
	t.check(l.beams() == 2 and l.aim(1).distance_to(l.sweep_point(1, l.beam_age(1))) < 0.05 and l.touches(l.aim(1)),
		"then a second, on its own path, and it touches too")
	var turned := (l.sweep_point(1, 2.0) - SPIRE).angle() - (-PI * 0.5 - Searchlight.SPIN * 2.0)
	t.check(absf(wrapf(turned, -PI, PI)) < 0.001, "turning the other way")
	var bench := Searchlight.new().setup(SPIRE)
	bench.light(Searchlight.SECOND_AFTER)
	t.check(bench.beams() == 2 and bench.aim(1).distance_to(bench.sweep_point(1, 0.0)) < 0.001,
		"lit from 30 s in (the bench), both beams sweep at once")


## A Will-o'-Wisp before the light wakes decoys nothing (review focus 4's noise and decoy); after, the nearest beam goes
## to it, stays DECOY_SECONDS, and takes up its sweep again.
static func _decoy(t) -> void:
	var l := Searchlight.new().setup(SPIRE)
	l.lure(SPIRE + Vector2(0.0, 10.0))
	t.check(l.decoy_beam == -1 and l.decoy_left == 0.0, "a wisp before the light wakes decoys nothing")
	l.light()
	_run(l, 2.0)
	var lure_at := l.aim(0) + Vector2(4.0, 0.0)
	l.lure(lure_at)
	t.check(l.decoy_beam == 0 and is_equal_approx(l.decoy_left, Searchlight.DECOY_SECONDS), "a wisp: the nearest beam takes the decoy")
	_run(l, 1.0)
	t.check(l.aim(0).distance_to(lure_at) < 0.05, "it goes to the light")
	_run(l, Searchlight.DECOY_SECONDS - 1.2)
	t.check(l.aim(0).distance_to(lure_at) < 0.05, "and stays on it for 5 s")
	_run(l, 10.0)
	t.check(l.decoy_beam == -1 and l.aim(0).distance_to(l.sweep_point(0, l.age)) < 0.05, "then takes up its sweep again")


## Noise moves no beam until the clock's last 20 s; then the nearest beam goes to the latest noise and stops there, a
## newer noise moves it, and a noise heard before the light woke still counts. With two beams, one follows a decoy and
## the other searches; with one, the decoy holds it first.
static func _search(t) -> void:
	var l := Searchlight.new().setup(SPIRE)
	var early := SPIRE + Vector2(-6.0, 12.0)
	l.hear(early)
	l.light()
	_run(l, 5.0, 60.0)
	t.check(not l.searching and l.search_beam == -1 and l.aim(0).distance_to(l.sweep_point(0, l.age)) < 0.05,
		"before the last 20 s, noise moves no beam")
	_run(l, 8.0, Searchlight.SEARCH_LAST)
	t.check(l.searching and l.search_beam == 0 and l.aim(0).distance_to(early) < 0.05,
		"in the last 20 s the beam goes to the latest noise (heard before it woke) and stops there")
	_run(l, 3.0, Searchlight.SEARCH_LAST - 8.0)
	t.check(l.aim(0).distance_to(early) < 0.05, "it searches there")
	var later := SPIRE + Vector2(8.0, 10.0)
	l.hear(later)
	_run(l, 5.0, 5.0)
	t.check(l.aim(0).distance_to(later) < 0.05, "a newer noise moves the search")

	var l2 := Searchlight.new().setup(SPIRE)
	l2.light()
	_run(l2, Searchlight.SECOND_AFTER + 1.0)
	var wisp_at := l2.aim(0) + Vector2(-1.0, 1.0)
	var noise_at := l2.aim(1) + Vector2(1.0, 1.0)
	l2.hear(noise_at)
	l2.lure(wisp_at)
	_run(l2, 2.0, Searchlight.SEARCH_LAST)
	t.check(l2.decoy_beam >= 0 and l2.search_beam >= 0 and l2.decoy_beam != l2.search_beam
		and l2.aim(l2.decoy_beam).distance_to(wisp_at) < 0.05 and l2.aim(l2.search_beam).distance_to(noise_at) < 0.05,
		"with two beams, one follows the decoy and the other searches")

	var l3 := Searchlight.new().setup(SPIRE)
	l3.light()
	_run(l3, 2.0)
	var w3 := l3.aim(0) + Vector2(2.0, 0.0)
	var n3 := l3.aim(0) + Vector2(-2.0, 0.0)
	l3.hear(n3)
	l3.lure(w3)
	_run(l3, 2.0, 10.0)
	t.check(l3.aim(0).distance_to(w3) < 0.05, "one beam: the decoy holds it before the search")
	_run(l3, Searchlight.DECOY_SECONDS, 10.0)
	t.check(l3.search_beam == 0 and l3.aim(0).distance_to(n3) < 0.05, "then it searches")


static func _out(t) -> void:
	var l := Searchlight.new().setup(SPIRE)
	l.light()
	_run(l, Searchlight.SECOND_AFTER + 1.0)
	var at := l.aim(0)
	l.put_out()
	t.check(not l.on and l.beams() == 0 and l.aim(0) == Vector2.INF and not l.touches(at), "put out, the beams die")
	_run(l, 1.0)
	t.check(l.beams() == 0 and l.age > 0.0, "and stepping it does nothing")
```

Register it at the end of `SUITES`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `Searchlight`.

- [ ] **Step 3: Write `Searchlight`.** Create `src/game/mission/searchlight.gd`:

```gdscript
class_name Searchlight
extends RefCounted
## Halcyon's Searchlight (v0.10 M4, spec §4.1, the Vigil Flame's Phase 2): beams of gold light from the Temple's spire.
## Each beam is a pool of light on the ground, POOL_R round, swept about the town on a slow, predictable path: turning
## round the spire at SPIN while reaching in and out between NEAR and FAR over REACH_PERIOD. One beam lights first, a
## second SECOND_AFTER later, turning the other way. A Will-o'-Wisp is a decoy (lure()): the beam nearest it goes to it
## and stays DECOY_SECONDS. In the clock's last SEARCH_LAST seconds a beam stops to search at the latest noise (hear():
## the director hears casts and deaths), and a newer noise moves it. A beam moves at most BEAM_SPEED, so it slides
## rather than jumps. touches() is the night's test of being seen. Pure logic, stepped by VigilFlameDirector: headless
## tests run it alone, and SearchlightFx draws it.

## How many beams there can be, and the radius of each beam's pool of light (ground units).
const MAX_BEAMS := 2
const POOL_R := 2.0
## The sweep: radians a second round the spire (one round in 40 s), and how near and far from it the pool swings, there
## and back over REACH_PERIOD seconds.
const SPIN := TAU / 40.0
const NEAR := 5.0
const FAR := 18.0
const REACH_PERIOD := 26.0
## Where each beam's sweep starts (radians from ground +x: PI / 2 points from the spire towards the market) and which
## way it turns.
const START := [PI * 0.5, -PI * 0.5]
const TURN := [1.0, -1.0]
## The second beam lights this long after the first.
const SECOND_AFTER := 30.0
## The clock's last seconds, in which a beam stops to search at the latest noise.
const SEARCH_LAST := 20.0
## How long a decoy holds its beam.
const DECOY_SECONDS := 5.0
## The fastest a beam's pool moves (ground units a second): faster than its sweep, so it can catch a decoy or a noise
## and catch its sweep up again.
const BEAM_SPEED := 6.0

var spire := Vector2.ZERO
var on := false
## Seconds since the light woke.
var age := 0.0
## The latest noise, or Vector2.INF before any.
var noise := Vector2.INF
## A Will-o'-Wisp's light, how long it holds its beam, and which beam (-1: none).
var decoy := Vector2.INF
var decoy_left := 0.0
var decoy_beam := -1
## Searching (the clock's last seconds, with a noise heard), and which beam searches (-1: none).
var searching := false
var search_beam := -1
var _aims: Array[Vector2] = [Vector2.INF, Vector2.INF]
## The noise the searching beam was sent to: a newer one sends a beam again.
var _searched := Vector2.INF


func setup(at: Vector2) -> Searchlight:
	spire = at
	return self


## Wake the light, `from` seconds into its sweep (the bench lights both beams at once).
func light(from := 0.0) -> void:
	if on:
		return
	on = true
	age = from
	for i in MAX_BEAMS:
		_aims[i] = sweep_point(i, beam_age(i)) if i < beams() else Vector2.INF


func put_out() -> void:
	on = false
	searching = false
	search_beam = -1
	decoy_left = 0.0
	decoy_beam = -1


## How many beams are lit.
func beams() -> int:
	if not on:
		return 0
	return MAX_BEAMS if age >= SECOND_AFTER else 1


## Beam i's own time: seconds since it lit.
func beam_age(i: int) -> float:
	return age - (SECOND_AFTER if i == 1 else 0.0)


## Where beam i's sweep has its pool `t` seconds after the beam lit.
func sweep_point(i: int, t: float) -> Vector2:
	var angle := float(START[i]) + float(TURN[i]) * SPIN * t
	var reach := lerpf(NEAR, FAR, 0.5 - 0.5 * cos(TAU * t / REACH_PERIOD))
	return spire + Vector2.from_angle(angle) * reach


## Where beam i's pool is now, or Vector2.INF while it is not lit.
func aim(i: int) -> Vector2:
	return _aims[i] if i < beams() else Vector2.INF


## A lit beam's pool covers `at`: whoever stands there is seen.
func touches(at: Vector2) -> bool:
	for i in beams():
		if _aims[i].distance_to(at) <= POOL_R:
			return true
	return false


## A noise at `at` (a cast, a death): the latest is where a searching beam stops.
func hear(at: Vector2) -> void:
	noise = at


## A Will-o'-Wisp at `at`: the nearest lit beam goes to it for DECOY_SECONDS. Nothing while the light sleeps.
func lure(at: Vector2) -> void:
	if not on:
		return
	decoy = at
	decoy_left = DECOY_SECONDS
	decoy_beam = _nearest(at, -1)


func step(delta: float, time_left: float) -> void:
	if not on:
		return
	age += delta
	decoy_left = maxf(0.0, decoy_left - delta)
	if decoy_left <= 0.0:
		decoy_beam = -1
	searching = time_left <= SEARCH_LAST and noise != Vector2.INF
	if not searching:
		search_beam = -1
	elif search_beam < 0 or _searched != noise:
		_searched = noise
		search_beam = _nearest(noise, decoy_beam if beams() > 1 else -1)
	for i in beams():
		if _aims[i] == Vector2.INF:
			_aims[i] = sweep_point(i, beam_age(i))  # the second beam lights where its sweep begins
		_aims[i] = _aims[i].move_toward(_want(i), BEAM_SPEED * delta)


## Where beam i is going: its decoy, else its search, else its sweep. A decoy holds a beam before a search does.
func _want(i: int) -> Vector2:
	if i == decoy_beam:
		return decoy
	if i == search_beam:
		return noise
	return sweep_point(i, beam_age(i))


## The lit beam nearest `at`, other than `skip`; -1 when there is none.
func _nearest(at: Vector2, skip: int) -> int:
	var best := -1
	for i in beams():
		if i == skip:
			continue
		if best < 0 or _aims[i].distance_to(at) < _aims[best].distance_to(at):
			best = i
	return best
```

- [ ] **Step 4: Run the tests to verify they pass.** Run Import, then Tests. Expected: `checks=N failures=0`.
- [ ] **Step 5: Commit.**

```bash
git add src/game/mission/searchlight.gd src/game/mission/searchlight.gd.uid tests/test_searchlight.gd tests/test_searchlight.gd.uid tests/run_all.gd
git commit -m "feat: Halcyon's Searchlight, the beams' logic (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 3: The Searchlight drawn

**Files:**
- Create: `src/fx/searchlight_fx.gd`
- Modify: `tests/test_searchlight.gd`

**Interfaces:**
- Consumes: `Searchlight` (Task 2); `FxTimeline` (`ctx`, `extra`, `track()`, `t`, `duration`, `end_now()`); `FxParts.quad()`, `FxParts.bloom()`, `FxParts.particles()`, `FxParts.SH_LIGHT`; `LightField.register_quad(quad, center, radius, color, getter)`; `Impact.dim(amount, speed)`; `Iso.ground_to_screen()`, `Iso.radius_to_screen()`.
- Produces `SearchlightFx extends FxTimeline`:
  - cast with `FxTimeline.cast(SearchlightFx, ctx, spire, {"light": searchlight})`;
  - lasts until `end_now()`;
  - `static func cone_points(top: Vector2, aim: Vector2, r: float) -> PackedVector2Array`;
  - constants `SPIRE_PX`, `SPIRE_GLOW_PX`, `LAMP_HALF`, `COL_CONE`, `CONE_TOP_A`, `CONE_FOOT_A`, `COL_POOL`, `POOL_INTENSITY`, `DIM`, `DIM_SPEED`, `FADE_SECONDS`, `DUST`, `DUST_RATE`.

- [ ] **Step 1: Write the failing test.** In `tests/test_searchlight.gd`, add `_cone(t)` as the last line of `run()`, and add:

```gdscript
## The cone SearchlightFx draws: from the lamp, narrow, down onto its pool's two sides across the beam.
static func _cone(t) -> void:
	var top := Vector2(0.0, -200.0)
	var pts := SearchlightFx.cone_points(top, Vector2.ZERO, Searchlight.POOL_R)
	var semi := Iso.radius_to_screen(Searchlight.POOL_R)
	t.check(pts.size() == 4 and pts[0].distance_to(top) <= SearchlightFx.LAMP_HALF + 0.001
		and pts[1].distance_to(top) <= SearchlightFx.LAMP_HALF + 0.001, "the cone starts narrow at the lamp")
	t.check(absf(pts[2].distance_to(pts[3]) - semi.x * 2.0) < 0.01 and ((pts[2] + pts[3]) * 0.5).length() < 0.01,
		"and spans its pool's width across the beam, centred on the pool")
```

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `SearchlightFx`.

- [ ] **Step 3: Write `SearchlightFx`.** Create `src/fx/searchlight_fx.gd`:

```gdscript
class_name SearchlightFx
extends FxTimeline
## Halcyon's Searchlight drawn (v0.10 M4, spec §4.1 "Look"). It reads a Searchlight (extra "light") every frame and
## changes nothing in the world:
## - the Temple's spire glows like a lighthouse;
## - from the spire's lamp each lit beam falls as an additive gold cone onto its pool of light, with dust drifting in it;
## - each pool is a ground light registered with the LightField, so building faces and people in a beam light up;
## - while the light is on, the town is darkened with the impact dim.
## It lasts until end_now() (the director let go). The light put out (the flame home) fades the cones, the pools and
## the dim away over FADE_SECONDS.

## The spire's lamp: how far above the Temple's ground point it stands (screen pixels), its glow's radius, and the
## cone's half-width at the lamp.
const SPIRE_PX := 96.0
const SPIRE_GLOW_PX := 22.0
const LAMP_HALF := 2.0
## The cones: additive gold, brighter at the lamp than at the foot.
const COL_CONE := Color(1.0, 0.84, 0.45)
const CONE_TOP_A := 0.28
const CONE_FOOT_A := 0.08
## The pools of light on the ground (and in the LightField).
const COL_POOL := Color(1.0, 0.86, 0.52)
const POOL_INTENSITY := 1.0
## How dark the town goes under the light (Impact.dim(), scaled by the mission's dim_scale), how fast, and how long the
## light takes to come up or fade.
const DIM := 0.6
const DIM_SPEED := 0.8
const FADE_SECONDS := 1.0
## Dust drifting in each beam: its colours and motes a second.
const DUST := [Color("fff6d8"), Color("ffe08a"), Color(1.0, 0.82, 0.45, 0.6)]
const DUST_RATE := 10.0

var light: Searchlight
var _cones: Node2D
var _glow: QuadFx
var _pools: Array[QuadFx] = []
var _dust: Array[PixelParticles] = []
var _fade := 0.0


## The cone from the lamp at `top` (screen) onto a pool of ground radius `r` at ground `aim`: the lamp's two sides,
## then the pool's two sides across the beam's direction (its ellipse's reach that way). Pure, for the tests.
static func cone_points(top: Vector2, aim: Vector2, r: float) -> PackedVector2Array:
	var foot := Iso.ground_to_screen(aim)
	var along := foot - top
	var across := along.orthogonal().normalized() if along.length() > 0.01 else Vector2.RIGHT
	var semi := Iso.radius_to_screen(r)
	var half := sqrt(pow(semi.x * across.x, 2.0) + pow(semi.y * across.y, 2.0))
	return PackedVector2Array([top + across * LAMP_HALF, top - across * LAMP_HALF, foot - across * half,
		foot + across * half])


func _build() -> void:
	duration = 1.0e9
	light = extra.get("light") as Searchlight
	_cones = Node2D.new()
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_cones.material = add
	_cones.z_index = 4
	_cones.draw.connect(_draw_cones)
	track(_cones, ctx.overhead)
	if light == null:
		return
	_glow = FxParts.bloom(self, _lamp(), SPIRE_GLOW_PX, COL_CONE, 0.0)
	for i in Searchlight.MAX_BEAMS:
		var q := FxParts.quad(self, FxParts.SH_LIGHT, Vector2.ONE * Searchlight.POOL_R * 2.0, ctx.ground)
		q.position = light.spire
		q.z_index = 6
		q.set_param("color", COL_POOL)
		q.set_param("intensity", 0.0)
		if ctx.lights != null:
			var k := i
			ctx.lights.register_quad(q, light.spire, Searchlight.POOL_R * 1.15, COL_POOL, func() -> Vector2: return _lit_at(k))
		_pools.append(q)
		var d := FxParts.particles(self, ctx.overhead, Iso.ground_to_screen(light.spire), PixelParticles.Shape.SQUARE, DUST)
		d.auto_free = false
		d.gravity = -6.0
		d.rate = DUST_RATE
		d.spec = {"radius": 22.0, "speed": Vector2(1, 5), "alt": Vector2(2, 30), "alt_speed": Vector2(2, 8),
			"life": Vector2(1.0, 2.0), "size": Vector2(1, 1)}
		_dust.append(d)
	ctx.play(&"grav_shimmer", light.spire, -6.0)


func _fx_process(delta: float) -> void:
	if light == null:
		return
	var was := _fade
	_fade = move_toward(_fade, 1.0 if light.on else 0.0, delta / FADE_SECONDS)
	if ctx.impact != null and (_fade > 0.0 or was > 0.0):
		ctx.impact.dim(DIM * _fade, DIM_SPEED)
	if is_instance_valid(_glow):
		_glow.set_param("intensity", _fade * (0.85 + 0.15 * sin(t * 2.4)))
	for i in _pools.size():
		var lit := i < light.beams()
		var at := _lit_at(i)
		_pools[i].position = at
		_pools[i].set_param("intensity", POOL_INTENSITY * _fade if lit else 0.0)
		_dust[i].emitting = lit
		_dust[i].position = Iso.ground_to_screen(at)
	_cones.queue_redraw()


## Where beam i's pool is, or the spire while the beam is not lit (its light then has no intensity).
func _lit_at(i: int) -> Vector2:
	return light.aim(i) if i < light.beams() else light.spire


func _lamp() -> Vector2:
	return Iso.ground_to_screen(light.spire) + Vector2(0.0, -SPIRE_PX)


func _draw_cones() -> void:
	if light == null or _fade <= 0.0:
		return
	var top := _lamp()
	var top_c := Color(COL_CONE, CONE_TOP_A * _fade)
	var foot_c := Color(COL_CONE, CONE_FOOT_A * _fade)
	for i in light.beams():
		_cones.draw_polygon(cone_points(top, light.aim(i), Searchlight.POOL_R),
			PackedColorArray([top_c, top_c, foot_c, foot_c]))
```

  (`FxTimeline.busy` does not matter here: Rules locks slots only for its own casts, and this effect is never one.)

- [ ] **Step 4: Run the tests to verify they pass.** Run Import, then Tests. Expected: `checks=N failures=0`. Task 6 photographs the effect.
- [ ] **Step 5: Commit.**

```bash
git add src/fx/searchlight_fx.gd src/fx/searchlight_fx.gd.uid tests/test_searchlight.gd
git commit -m "feat: the Searchlight drawn: spire glow, gold cones, light pools, dust and dim (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 4: The Vigil Flame — the Vigil, Wren, the swap and the flame home

**Files:**
- Create: `src/game/mission/vigil_flame_director.gd`, `src/game/mission/flame_objective.gd`, `tests/test_vigil_flame.gd`
- Modify: `src/game/mission/mission_book.gd` (`miras_house()`'s comment, `vigil_flame()`), `src/game/ui/results_screen.gd` (`ACT_TITLES`), `src/game/game.gd` (`_flow_campaign`), `tests/test_mission_book.gd`, `tests/run_all.gd`

**Interfaces:**
- Consumes:
  - Task 1: `MissionDirector.faithful_seeing()`, `_report()`, `_step_reports()`, `_carrying()`, `reports`, `reports_started`, `BLIND`; `VigilRoute.shorten_to()`;
  - Task 2: `Searchlight.new().setup(at)`, `searchlight.on`;
  - M2/M3: `VigilRoute` (`loop`, `pass_flame`, `busy`, `flame_passed`, `walkers()`, `bearer`, `acolytes`, `route`), `GazeMeter` (`note_death`, `judge_deaths`, `fill`), `BrokenLanternsDirector.SHRINE_SPOTS`, `RELIGHT_OFF`;
  - `MissionDirector._sort_citizens()`, `_make_faithful()`, `_spread_faithful()`, `_walkable()`, `_alive()`, `_unhook_kills()`.
- Produces, on `VigilFlameDirector extends MissionDirector`:
  - constants `MIRA_SHRINE`, `SHRINE_REACH`, `FAITHFUL`, `VIGIL_PACE`, `WREN_AT`, `WATCH_DIST`, `WREN_OWN_AFTER`, `SWAP_REACH`, `SWAP_HOLD`, `SWAP_SECONDS`, `WREN_PACE`, `ROUTE_AT`, `HOME_REACH`, `CAMERA_AT`, `MARK_WREN`, `MARK_FLAME`, `MARK_SHRINE`, `TICK`, `RESUMABLE`, `SEEN_DEATH_SCALE`;
  - vars `vigil: VigilRoute`, `temple_door`, `shrine`, `searchlight: Searchlight`, `wren: Person`, `appeared`, `whispered`, `attempting`, `swapping`, `swap_left`, `swapped`, `swap_seen`, `home`, `kept`, `no_wren`, `homeward`;
  - funcs `flame_at() -> Vector2`, `wren_lost() -> bool`, `marks()`, `marker()`, `report()` (`{"swapped", "seen", "reports", "home"}`);
  - Task 5's hooks, empty here: `_listen()`, `_add_events()`, `_phase2_begin()`, `_phase2_step(delta)`, `_noise(at)`, `_phase2_end()`;
  - inner class `FlameGaze extends GazeMeter`.
- Also produced:
  - `FlameObjective`: label `"The flame"`, reasons `"flame"` (won), `"kept"`, `"wren"` (lost);
  - `MissionBook.vigil_flame()`, the real mission: objectives `[GazeObjective, FlameObjective, ClockObjective(false, "Dawn", "late")]`;
  - `ResultsScreen.ACT_TITLES` gains `"flame": "THE FLAME IS STOLEN"`, `"kept": "THE FLAME IS KEPT"`, `"wren": "THE BOY IS DEAD"`, `"late": "DAWN FINDS THE FLAME"`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_vigil_flame.gd`:

```gdscript
extends RefCounted
## v0.10 M4 The Vigil Flame (VigilFlameDirector). The flame-bearer walks the Vigil's route with two acolytes; at 0:50
## Wren comes to watch the lantern; whispered to it he swaps the real flame in 3 s, seen if a Faithful other than the
## bearer stands within Crowd.DOOM_WITNESS; left alone 30 s he tries it himself; at 1:30 the route shortens and the
## bearer home with the real flame loses; Wren carrying the flame to Mira's shrine wins. Task 5 adds Phase 2: the
## Searchlight, its touches, the Faithful's prayer in it, noise and the decoy, and the bonus.

const DT := 0.05
## Where the tests stage the swap and park watchers: beyond every beam's reach (Searchlight.FAR + POOL_R from the
## spire), so nothing the light does there is an accident.
const OUT := Vector2(-12.0, 12.0)
const AWAY := Vector2(16.0, 14.0)


static func _setup() -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.unaware()
	crowd.spawn()
	# The town's alarm hushed: deaths in a test never call the bellkeeper (the bell's own case sets it rung).
	crowd.hush(9999.0)
	var def := MissionBook.vigil_flame()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := (def.director.new() as MissionDirector).setup(rules, crowd, town, null) as VigilFlameDirector
	rules.director = director
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd, "rules": rules,
		"d": director, "banners": banners}


static func _done(s: Dictionary) -> void:
	var rules: Rules = s.rules
	rules.teardown()
	rules.free()
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


static func _run(s: Dictionary, seconds: float) -> void:
	for i in roundi(seconds / DT):
		(s.crowd as Crowd).advance(DT)
		(s.rules as Rules).advance(DT)


static func _arrive(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()


static func _slot(rules: Rules, key: String) -> int:
	for i in rules.loadout.size():
		if rules.key(i) == key:
			return i
	return -1


## 0:50 now: Wren comes.
static func _wren_now(d: VigilFlameDirector) -> void:
	d.timeline.step(VigilFlameDirector.WREN_AT)


## The bearer set down at OUT, and the lantern with him (one step for the director to see it).
static func _bearer_out(s: Dictionary) -> void:
	_arrive((s.d as VigilFlameDirector).vigil.bearer, OUT)
	_run(s, DT)


## Every Faithful but the bearer parked AWAY, a little apart.
static func _clear_watchers(d: VigilFlameDirector) -> void:
	var i := 0
	for f in d.faithful:
		if f == d.vigil.bearer:
			continue
		_arrive(f, AWAY + Vector2(float(i % 8) * 0.6, floorf(float(i) / 8.0) * 0.6))
		i += 1


## Wren whispered to the lantern and set down beside it.
static func _bring_wren(d: VigilFlameDirector) -> void:
	var w := d.wren
	w.whisper(d.flame_at(), 8.0)
	_arrive(w, d.flame_at() + Vector2(0.5, 0.0))


## Wren comes and makes the swap unseen at OUT.
static func _do_swap(s: Dictionary) -> void:
	var d: VigilFlameDirector = s.d
	_wren_now(d)
	_bearer_out(s)
	_clear_watchers(d)
	_bring_wren(d)
	_run(s, VigilFlameDirector.SWAP_SECONDS + 0.2)


static func run(t) -> void:
	_cast(t)
	_wren(t)
	_swap(t)
	_own_try(t)
	_route(t)
	_carry(t)
	_ending(t)
	_focus(t)


static func _cast(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	var grid: WalkGrid = s.grid
	var faithful_ok := d.faithful.size() >= VigilFlameDirector.FAITHFUL
	for f in d.faithful:
		faithful_ok = faithful_ok and f.profile.faith == CitizenProfile.Faith.FAITHFUL
	t.check(faithful_ok, "the Faithful chosen (%d)" % d.faithful.size())
	var route_ok := d.vigil != null and d.vigil.route.size() == BrokenLanternsDirector.SHRINE_SPOTS.size()
	if route_ok:
		for i in BrokenLanternsDirector.SHRINE_SPOTS.size():
			route_ok = route_ok and d.vigil.route[i].distance_to(BrokenLanternsDirector.SHRINE_SPOTS[i]) < 2.0
	t.check(route_ok and d.vigil.active and d.vigil.loop and d.vigil.pass_flame and d.vigil.walkers().size() == 3
		and d.faithful.has(d.vigil.bearer), "the Vigil sets out on the six shrines' route, looping, the flame passing on")
	var slow := true
	for p in d.vigil.walkers():
		slow = slow and p.pace <= Person.PACE_RANGE.y * VigilFlameDirector.VIGIL_PACE + 0.001
	t.check(slow, "its three walk at the Vigil's solemn pace")
	var reach := grid.walkable(d.shrine) and d.shrine.distance_to(VigilFlameDirector.MIRA_SHRINE) < 2.0 and d.shrine.x < -12.0
	for pt in d.vigil.route:
		reach = reach and not grid.path(pt, d.shrine).is_empty()
	t.check(reach, "Mira's shrine stands at the west edge, and Wren can walk to it from anywhere on the route")
	t.check(d.gaze != null and d.gaze.value == 0.0 and d.wren == null and not d.appeared and not d.swapped
		and d.searchlight != null and not d.searchlight.on, "the Gaze at 0, no Wren yet, the light asleep")
	var marks := d.marks()
	t.check(marks.size() == 2 and (marks[0][1] as Color) == VigilFlameDirector.MARK_SHRINE
		and (marks[1][0] as Vector2) == d.vigil.bearer.ground_pos and (marks[1][1] as Color) == VigilFlameDirector.MARK_FLAME,
		"the HUD marks Mira's shrine and the lantern")
	var next := d.timeline.upcoming(2)
	t.check(d.marker() == Vector2.INF and next.size() == 2 and next[0].id == "wren" and next[1].id == "route",
		"no arrow yet; the strip shows Wren coming and the route shortening")
	t.check(OUT.distance_to(d.searchlight.spire) > Searchlight.FAR + Searchlight.POOL_R
		and AWAY.distance_to(d.searchlight.spire) > Searchlight.FAR + Searchlight.POOL_R, "the tests' staging lies beyond the light")
	_done(s)


static func _wren(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	_wren_now(d)
	var w := d.wren
	t.check(d.appeared and _alive(w) and not d.faithful.has(w) and w.profile.faith == CitizenProfile.Faith.NONE
		and (s.banners as Array).has("A BOY WATCHES THE LANTERN"), "0:50: Wren comes, a citizen not of the Faith")
	_run(s, VigilFlameDirector.TICK + DT)
	t.check(w.mind == Person.Mind.DUTY and absf(w.anchor.distance_to(d.flame_at()) - VigilFlameDirector.WATCH_DIST) < 1.0,
		"he keeps watch a few steps from the lantern (%.1f)" % w.anchor.distance_to(d.flame_at()))
	var seen := false
	for m: Array in d.marks():
		seen = seen or ((m[0] as Vector2) == w.ground_pos and (m[1] as Color) == VigilFlameDirector.MARK_WREN)
	t.check(seen and d.marker() == w.ground_pos, "the HUD marks him, and points at him")
	_done(s)


static func _swap(t) -> void:
	# Unseen: nobody of the Faith near but the bearer, and the bearer, robbed, sees nothing.
	var s := _setup()
	var d: VigilFlameDirector = s.d
	_wren_now(d)
	_bearer_out(s)
	_clear_watchers(d)
	_bring_wren(d)
	_run(s, DT * 2.0)
	t.check(d.swapping and d.whispered and d.wren.mind == Person.Mind.DUTY, "whispered to the lantern, Wren takes hold")
	_run(s, VigilFlameDirector.SWAP_SECONDS - 0.5)
	t.check(d.swapping and not d.swapped, "the swap takes 3 s")
	_run(s, 0.6)
	t.check(d.swapped and not d.swap_seen and d.reports.is_empty() and (s.banners as Array).has("THE FLAME IS TAKEN"),
		"then he has the real flame, unseen (the bearer at his side sees nothing)")
	t.check(d.wren.mind == Person.Mind.DUTY and d.wren.anchor.distance_to(d.shrine) < 0.01 and d.flame_at() == d.wren.ground_pos
		and d.wren.pace <= Person.PACE_RANGE.y * VigilFlameDirector.WREN_PACE + 0.001,
		"and carries it carefully toward Mira's shrine")
	var lantern_marked := false
	for m: Array in d.marks():
		lantern_marked = lantern_marked or (m[1] as Color) == VigilFlameDirector.MARK_FLAME
	t.check(not lantern_marked, "the HUD no longer marks the lantern")
	_done(s)

	# Seen: an acolyte at Wren's side runs to the Temple; the flame is taken all the same; the report home fills the Gaze.
	var s2 := _setup()
	var d2: VigilFlameDirector = s2.d
	_wren_now(d2)
	_bearer_out(s2)
	_clear_watchers(d2)
	var acolyte: Person = d2.vigil.acolytes[0]
	_bring_wren(d2)
	_arrive(acolyte, d2.wren.ground_pos + Vector2(0.0, 1.2))
	_run(s2, VigilFlameDirector.SWAP_SECONDS + 0.2)
	t.check(d2.swapped and d2.swap_seen and d2.reports.size() == 1 and d2.reports[0].carrier == acolyte
		and (s2.banners as Array).has("A FAITHFUL RUNS TO THE TEMPLE"),
		"a swap an acolyte sees is reported, and the flame is taken all the same")
	_arrive(acolyte, d2.temple_door)
	_run(s2, DT * 2.0)
	t.check((s2.rules as Rules).finished and (s2.rules as Rules).over_reason == "gaze" and d2.gaze.is_full(),
		"the report reaching the Temple fills the Gaze: the night is lost")
	_done(s2)

	# Held: an acolyte at his side, but confused by Discord, sees nothing.
	var s3 := _setup()
	var d3: VigilFlameDirector = s3.d
	_wren_now(d3)
	_bearer_out(s3)
	_clear_watchers(d3)
	var held: Person = d3.vigil.acolytes[0]
	_bring_wren(d3)
	_arrive(held, d3.wren.ground_pos + Vector2(0.0, 1.2))
	held.confuse(15.0)
	_run(s3, VigilFlameDirector.SWAP_SECONDS + 0.2)
	t.check(d3.swapped and not d3.swap_seen and d3.reports.is_empty(), "an acolyte held by Discord sees nothing")
	_done(s3)


static func _own_try(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	_wren_now(d)
	_run(s, VigilFlameDirector.WREN_OWN_AFTER - 1.0)
	t.check(not d.attempting, "left alone, Wren only watches at first")
	_run(s, 1.0 + VigilFlameDirector.TICK + DT)
	t.check(d.attempting and d.wren.mind == Person.Mind.DUTY and d.wren.anchor.distance_to(d.flame_at()) < 0.6
		and (s.banners as Array).has("THE BOY TRIES FOR THE LANTERN"), "30 s without a whisper, he goes for the lantern himself")
	_arrive(d.wren, d.flame_at() + Vector2(0.5, 0.0))
	_run(s, DT * 2.0)
	t.check(d.swapping, "and takes hold of it without the god")
	_done(s)

	var s2 := _setup()
	var d2: VigilFlameDirector = s2.d
	_wren_now(d2)
	_run(s2, DT)
	d2.wren.whisper(d2.wren.ground_pos + Vector2(1.0, 0.0), 8.0)
	_run(s2, DT)
	t.check(d2.whispered, "whispered once, he is the god's")
	_run(s2, VigilFlameDirector.WREN_OWN_AFTER + 1.0)
	t.check(not d2.attempting, "and never tries on his own")
	_done(s2)


static func _route(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	var rules: Rules = s.rules
	d.timeline.step(VigilFlameDirector.ROUTE_AT)
	t.check(d.homeward and d.vigil.route.size() == 1 and d.vigil.route[0] == d.temple_door and not d.vigil.loop
		and (s.banners as Array).has("THE ROUTE SHORTENS"), "1:30: a suspicious priest sends the Vigil straight home")
	_arrive(d.vigil.bearer, d.temple_door)
	_run(s, DT)
	t.check(rules.finished and not rules.won and rules.over_reason == "kept" and d.kept
		and ResultsScreen.title_for(false, "kept") == "THE FLAME IS KEPT", "the bearer home with the real flame: the night is lost")
	_done(s)

	var s2 := _setup()
	var d2: VigilFlameDirector = s2.d
	_do_swap(s2)
	d2.timeline.step(VigilFlameDirector.ROUTE_AT)
	_arrive(d2.vigil.bearer, d2.temple_door)
	_run(s2, DT)
	t.check(d2.homeward and not d2.kept and not (s2.rules as Rules).finished, "home with the false flame, nothing is lost")
	_done(s2)


static func _carry(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	var rules: Rules = s.rules
	_do_swap(s)
	var w := d.wren
	w.whisper(w.ground_pos + Vector2(1.0, 0.0), 8.0)
	_run(s, VigilFlameDirector.TICK + DT)
	t.check(w.mind == Person.Mind.WHISPERED, "whispered on his way, Wren is the god's to steer")
	w.mind = Person.Mind.RECOVER
	_run(s, VigilFlameDirector.TICK + DT)
	t.check(w.mind == Person.Mind.DUTY and w.anchor.distance_to(d.shrine) < 0.01, "back on his feet, he makes for the shrine again")
	_arrive(w, d.shrine)
	_run(s, DT)
	t.check(rules.finished and rules.won and rules.over_reason == "flame" and d.home
		and (s.banners as Array).has("MIRA'S SHRINE BURNS AGAIN") and ResultsScreen.title_for(true, "flame") == "THE FLAME IS STOLEN",
		"the flame at Mira's shrine wins the night")
	t.check(bool(rules.result().get("home", false)) and bool(rules.result().get("swapped", false)), "the results report it")
	_done(s)


static func _ending(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	_wren_now(d)
	(s.crowd as Crowd)._field.kill(d.wren, &"doom")
	_run(s, DT * 3.0)
	t.check((s.rules as Rules).finished and (s.rules as Rules).over_reason == "wren"
		and ResultsScreen.title_for(false, "wren") == "THE BOY IS DEAD", "Wren dead loses the night")
	_done(s)

	var s2 := _setup()
	(s2.d as VigilFlameDirector).gaze.fill()
	_run(s2, DT)
	t.check((s2.rules as Rules).finished and (s2.rules as Rules).over_reason == "gaze", "a full Gaze loses it")
	_done(s2)

	var s3 := _setup()
	(s3.rules as Rules).time_left = DT
	_run(s3, DT * 2.0)
	t.check((s3.rules as Rules).finished and not (s3.rules as Rules).won and (s3.rules as Rules).over_reason == "late"
		and ResultsScreen.title_for(false, "late") == "DAWN FINDS THE FLAME", "dawn first loses it")
	_done(s3)

	var s4 := _setup()
	var crowd4: Crowd = s4.crowd
	if crowd4.bell != null:
		crowd4.bell.state = BellNetwork.State.RUNG
	_run(s4, DT * 2.0)
	t.check(crowd4.bell == null or ((s4.d as VigilFlameDirector).gaze.is_full() and (s4.rules as Rules).over_reason == "gaze"),
		"the bell fills the Gaze")
	_done(s4)

	var s5 := _setup()
	var d5: VigilFlameDirector = s5.d
	var victim := d5.faithful[5]
	d5.faithful[6].ground_pos = victim.ground_pos + Vector2(1.0, 0.0)
	(s5.crowd as Crowd)._field.kill(victim, &"doom")
	_run(s5, DT * 3.0)
	t.near(d5.gaze.value, GazeMeter.SEEN_DEATH * VigilFlameDirector.SEEN_DEATH_SCALE, 0.001, "a seen death adds to the Gaze")
	_done(s5)


## Review focus 1-3: the Vigil struck down before the swap; Wren held mid-swap; nobody left to be Wren.
static func _focus(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	var crowd: Crowd = s.crowd
	_wren_now(d)
	_bearer_out(s)
	_clear_watchers(d)
	var acolyte: Person = d.vigil.acolytes[0]
	crowd._field.kill(d.vigil.bearer, &"doom")
	_run(s, VigilRoute.TICK + DT)
	t.check(d.vigil.bearer == acolyte and (s.banners as Array).has("AN ACOLYTE TAKES UP THE FLAME"),
		"the bearer struck down, an acolyte takes up the flame")
	_arrive(acolyte, OUT + Vector2(2.0, 0.0))
	_run(s, DT)
	var fell := acolyte.ground_pos
	for p in d.vigil.walkers():
		crowd._field.kill(p, &"doom")
	_run(s, VigilRoute.TICK * 2.0)
	var marked := false
	for m: Array in d.marks():
		marked = marked or ((m[0] as Vector2) == fell and (m[1] as Color) == VigilFlameDirector.MARK_FLAME)
	t.check(not d.vigil.active and d.flame_at() == fell and marked,
		"all three dead, the lantern lies where its last bearer fell, still marked")
	_bring_wren(d)
	_run(s, VigilFlameDirector.SWAP_SECONDS + 0.2)
	t.check(d.swapped and not d.swap_seen, "Wren takes the flame from the fallen lantern")
	_done(s)

	var s2 := _setup()
	var d2: VigilFlameDirector = s2.d
	_wren_now(d2)
	_bearer_out(s2)
	_clear_watchers(d2)
	_bring_wren(d2)
	_run(s2, 1.0)
	t.check(d2.swapping and d2.swap_left < VigilFlameDirector.SWAP_SECONDS, "a swap under way")
	d2.wren.confuse(5.0)
	_run(s2, DT)
	t.check(not d2.swapping and not d2.swapped, "Wren held by Discord mid-swap: it is broken")
	_bring_wren(d2)
	_run(s2, DT * 2.0)
	t.check(d2.swapping and d2.swap_left > VigilFlameDirector.SWAP_SECONDS - 0.2, "whispered back, it starts again from the beginning")
	_done(s2)

	var s3 := _setup()
	var d3: VigilFlameDirector = s3.d
	for p in (s3.crowd as Crowd).citizens:
		if not d3.faithful.has(p):
			p.inside = true
	_wren_now(d3)
	_run(s3, DT)
	t.check(d3.no_wren and d3.wren == null and (s3.rules as Rules).finished and (s3.rules as Rules).over_reason == "wren",
		"with nobody left to be Wren, the night is lost")
	_done(s3)
```

Register it at the end of `SUITES`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `VigilFlameDirector`.

- [ ] **Step 3: Write `FlameObjective`.** Create `src/game/mission/flame_objective.gd`:

```gdscript
class_name FlameObjective
extends Objective
## The Vigil Flame (v0.10): Halcyon's flame at Mira's shrine wins the night ("flame"); the bearer home at the Temple with
## the real flame ("kept"), or Wren dead or never come ("wren"), loses it. Its line tells the player where the flame is.


func _init() -> void:
	label = "The flame"
	reason = "flame"


func check(rules: Rules) -> Status:
	var d := rules.director as VigilFlameDirector
	if d == null:
		return Status.PENDING
	if d.home:
		reason = "flame"
		return Status.DONE
	if d.kept:
		reason = "kept"
		return Status.FAILED
	if d.wren_lost():
		reason = "wren"
		return Status.FAILED
	return Status.PENDING


func hud_text(rules: Rules) -> String:
	var d := rules.director as VigilFlameDirector
	if d == null or not d.appeared:
		return "The flame: in its lantern"
	if d.home:
		return "The flame: home"
	if d.swapped:
		var at := d.flame_at()
		return "The flame to Mira's shrine: %d" % roundi(at.distance_to(d.shrine)) if at != Vector2.INF else "The flame: lost"
	if d.swapping:
		return "Swapping %d / %d s" % [ceili(VigilFlameDirector.SWAP_SECONDS - d.swap_left), roundi(VigilFlameDirector.SWAP_SECONDS)]
	return "The flame: swap it"
```

- [ ] **Step 4: Write the director.** Create `src/game/mission/vigil_flame_director.gd`:

```gdscript
class_name VigilFlameDirector
extends MissionDirector
## The Vigil Flame (v0.10 M4, the Theft path's Night 2): Halcyon's eternal flame holds part of the power he gave the
## town, and a god cannot hold it: a mortal hand must take it.
## - The Vigil: the flame-bearer walks the six wayside shrines' route (Broken Lanterns' points; no shrines stand here)
##   with two acolytes, round and round at a solemn pace. The flame passes to an acolyte if he falls; with all three
##   dead the lantern lies where the last one fell.
## - Wren: at 0:50 a street urchin comes to watch the silver lantern. Whispered within SWAP_REACH of it, he takes hold
##   and swaps the real flame for a false one in SWAP_SECONDS. A Faithful other than the bearer (the one robbed) within
##   Crowd.DOOM_WITNESS of him as it is done, not held by the god, sees it (Silent Doom's witness rule) and runs to the
##   Temple to report it (TempleReport); a report reaching the Temple fills Halcyon's Gaze. Left WREN_OWN_AFTER seconds
##   without a whisper, Wren tries the swap himself.
## - 1:30: a suspicious priest sends the Vigil straight back to the Temple. The bearer reaching it with the real flame
##   keeps it, and the night is lost.
## - The flame home: Wren carries it to Mira's shrine at the west forest edge; there it relights with the god's own
##   flame and the night is won. Wren dead, or dawn first, loses it. A death someone sees adds to the Gaze, and the bell
##   fills it.
## - Phase 2 (Task 5): from the swap until the flame is home, Halcyon's Searchlight sweeps the town.

## Mira's shrine at the west forest edge, outside the west wall (ground units; moved to the nearest open ground), and how
## near Wren must bring the flame.
const MIRA_SHRINE := Vector2(-17.6, 12.0)
const SHRINE_REACH := 1.0
## How many Faithful there are besides the clergy (spec §4.1: about 20 devout citizens).
const FAITHFUL := 20
## The Vigil's solemn pace: the share of their own pace its three walk at.
const VIGIL_PACE := 0.5
## 0:50 -- Wren comes to watch the lantern, keeping WATCH_DIST from it; left WREN_OWN_AFTER seconds without a whisper,
## he tries the swap himself.
const WREN_AT := 50.0
const WATCH_DIST := 3.0
const WREN_OWN_AFTER := 30.0
## The swap: begun within SWAP_REACH of the lantern (whispered there, or on his own try), it takes SWAP_SECONDS while
## Wren keeps within SWAP_HOLD of it on his duty; any farther, or Wren off his duty (frightened, held), breaks it.
const SWAP_REACH := 1.0
const SWAP_HOLD := 1.6
const SWAP_SECONDS := 3.0
## Wren with the flame walks carefully: the share of his own pace he keeps.
const WREN_PACE := 0.75
## 1:30 -- the route shortens, straight back to the Temple; the bearer within HOME_REACH of its door with the real flame
## keeps it.
const ROUTE_AT := 90.0
const HOME_REACH := 1.0
## Where the camera opens: by the Temple, where the Vigil sets out.
const CAMERA_AT := Vector2(3.0, -2.0)
## The marks: Wren, the real flame (in its lantern, or fallen), and Mira's shrine.
const MARK_WREN := Color("8fe0ff")
const MARK_FLAME := Color(0.95, 0.82, 0.42, 0.9)
const MARK_SHRINE := Color("ff9a3a")
## Seconds between the director's looks at Wren's errand.
const TICK := 0.5
## Minds Wren picks his errand up again from.
const RESUMABLE := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.REGROUP]
## A death someone sees adds this share of GazeMeter.SEEN_DEATH in this mission (FlameGaze): Task 7's lever, so the
## shared GazeMeter stays as Mira's House and Broken Lanterns have it.
const SEEN_DEATH_SCALE := 1.0

var vigil: VigilRoute
var temple_door := Vector2.INF
## Mira's shrine, on open ground.
var shrine := Vector2.INF
var searchlight: Searchlight
var wren: Person
var appeared := false
## Wren has been whispered (he never tries on his own then), or is trying the swap himself.
var whispered := false
var attempting := false
## The swap under way, and its seconds left.
var swapping := false
var swap_left := 0.0
## The real flame has left the lantern (Phase 2), and whether a Faithful saw it go.
var swapped := false
var swap_seen := false
## The flame is home at Mira's shrine (the win); the bearer kept it (a loss); nobody could be Wren (a loss).
var home := false
var kept := false
var no_wren := false
## The route has shortened: the Vigil is going home.
var homeward := false
## Where the real flame is while in its lantern: with its bearer, or where the last bearer fell.
var _lantern := Vector2.INF
var _appeared_at := 0.0
var _tick := 0.0


func _begin() -> void:
	gaze = FlameGaze.new()
	temple_door = _walkable(Vector2(TownLayout.TEMPLE.get_center().x, TownLayout.TEMPLE.end.y + 0.6))
	shrine = _walkable(MIRA_SHRINE)
	searchlight = Searchlight.new().setup(TownLayout.TEMPLE.get_center())
	_choose_faithful()
	_start_vigil()
	crowd._field.enemy_killed.connect(_on_killed)
	_listen()
	timeline = EventTimeline.new()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	timeline.add(WREN_AT, "wren", "A boy watches the lantern", _wren_comes)
	timeline.add(ROUTE_AT, "route", "The route shortens", _route_home, func() -> bool: return vigil != null and vigil.active)
	_add_events()
	rules.banner.emit("STEAL HALCYON'S FLAME")


## The clergy, and FAITHFUL lay citizens spread through the rest, are Halcyon's Faithful.
func _choose_faithful() -> void:
	var lay: Array[Person] = []
	var clergy: Array[Person] = []
	_sort_citizens(clergy, lay)
	for p in clergy:
		_make_faithful(p)
	_spread_faithful(lay, FAITHFUL)


## The flame-bearer and his two acolytes are the clergy nearest the Temple's door (else any Faithful). They walk the six
## shrines' route round and round at VIGIL_PACE, the flame passing on if the bearer falls.
func _start_vigil() -> void:
	var pool: Array[Person] = faithful.duplicate()
	pool.sort_custom(func(a: Person, b: Person) -> bool:
		var ca := a.profile.role == CitizenProfile.Role.CLERGY
		var cb := b.profile.role == CitizenProfile.Role.CLERGY
		if ca != cb:
			return ca
		return a.ground_pos.distance_to(temple_door) < b.ground_pos.distance_to(temple_door))
	if pool.is_empty():
		return
	var route := PackedVector2Array()
	for spot: Vector2 in BrokenLanternsDirector.SHRINE_SPOTS:
		route.append(_walkable(_walkable(spot) + BrokenLanternsDirector.RELIGHT_OFF))
	var acolytes: Array[Person] = []
	acolytes.assign(pool.slice(1, 3))
	vigil = VigilRoute.new().setup(route, pool[0], acolytes)
	vigil.loop = true
	vigil.pass_flame = true
	vigil.busy = _carrying
	vigil.flame_passed.connect(func(_to: Person) -> void: rules.banner.emit("AN ACOLYTE TAKES UP THE FLAME"))
	for p in vigil.walkers():
		p.pace *= VIGIL_PACE
	vigil.start()
	_lantern = vigil.bearer.ground_pos


func step(delta: float) -> void:
	timeline.step(delta)
	gaze.judge_deaths(crowd)
	if vigil != null:
		vigil.step(delta)
		if vigil.active and _alive(vigil.bearer):
			_lantern = vigil.bearer.ground_pos
	_step_reports(delta)
	if not swapped:
		_home_check()
		_swap_step(delta)
	_wren_step(delta)
	_phase2_step(delta)
	if crowd.bell != null and crowd.bell.state == BellNetwork.State.RUNG:
		gaze.fill()


func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	gaze.note_death(e.ground_pos)
	for r in reports:
		r.on_killed(e)
	_noise(e.ground_pos)


## 0:50 -- the living lay citizen nearest the lantern who is not of the Faith becomes Wren and comes to watch it. With
## nobody left to be him, the night is lost.
func _wren_comes() -> void:
	var lay: Array[Person] = []
	var clergy: Array[Person] = []
	_sort_citizens(clergy, lay)
	for p in lay:
		if faithful.has(p):
			continue
		if wren == null or p.ground_pos.distance_to(_lantern) < wren.ground_pos.distance_to(_lantern):
			wren = p
	if wren == null:
		no_wren = true
		return
	appeared = true
	_appeared_at = timeline.elapsed()
	_tick = 0.0


## 1:30 -- a suspicious priest sends the Vigil straight back to the Temple.
func _route_home() -> void:
	homeward = true
	vigil.shorten_to(temple_door)


## The route shortened, the bearer at the Temple's door with the real flame keeps it: the night is lost.
func _home_check() -> void:
	if not homeward or vigil == null or not _alive(vigil.bearer):
		return
	if vigil.bearer.ground_pos.distance_to(temple_door) <= HOME_REACH:
		kept = true


## The swap: begun when Wren, whispered there or on his own try, comes within SWAP_REACH of the lantern. It runs while
## he keeps within SWAP_HOLD of it on his duty (keeping pace with the bearer), and is broken otherwise.
func _swap_step(delta: float) -> void:
	if not appeared or not _alive(wren) or wren.inside or _lantern == Vector2.INF:
		swapping = false
		return
	var gap := wren.ground_pos.distance_to(_lantern)
	if not swapping:
		if gap <= SWAP_REACH and (wren.mind == Person.Mind.WHISPERED or attempting):
			whispered = whispered or wren.mind == Person.Mind.WHISPERED
			swapping = true
			swap_left = SWAP_SECONDS
			wren.go_duty(_lantern)
		return
	if gap > SWAP_HOLD or wren.mind != Person.Mind.DUTY:
		swapping = false
		return
	if wren.anchor.distance_to(_lantern) > 0.3:
		wren.go_duty(_lantern)
	swap_left -= delta
	if swap_left <= 0.0:
		_swap()


## The real flame leaves the lantern: Wren has it, and a false one burns in its place. A Faithful who saw it (Silent
## Doom's witness rule, the bearer aside) runs to the Temple. Phase 2 begins either way.
func _swap() -> void:
	swapping = false
	swapped = true
	var seer := faithful_seeing(wren.ground_pos, Crowd.DOOM_WITNESS, vigil.bearer if vigil != null else null)
	if seer != null:
		swap_seen = true
		_report(seer, temple_door)
	rules.banner.emit("THE FLAME IS TAKEN")
	wren.pace *= WREN_PACE
	wren.go_duty(shrine)
	_tick = TICK
	_phase2_begin()


## Wren's errand, looked at every TICK: to watch the lantern, to try for it himself, or to carry the flame to Mira's
## shrine. A whisper is the god's: he is left to it, and picks his errand up again once back on his feet.
func _wren_step(delta: float) -> void:
	if not appeared or not _alive(wren) or home:
		return
	if wren.mind == Person.Mind.WHISPERED:
		whispered = true
	if swapped and not wren.inside and wren.ground_pos.distance_to(shrine) <= SHRINE_REACH:
		_flame_home()
		return
	if not swapped and not whispered and not attempting and timeline.elapsed() - _appeared_at >= WREN_OWN_AFTER:
		attempting = true
		_tick = 0.0
		rules.banner.emit("THE BOY TRIES FOR THE LANTERN")
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = TICK
	if swapping or wren.inside or not (wren.mind == Person.Mind.DUTY or wren.mind in RESUMABLE):
		return
	var goal := _wren_goal()
	if wren.mind != Person.Mind.DUTY or wren.anchor.distance_to(goal) > 0.3:
		wren.go_duty(goal)


## Where Wren is making for: Mira's shrine with the flame; else the lantern on his own try; else a place WATCH_DIST from
## the lantern on his side of it.
func _wren_goal() -> Vector2:
	if swapped:
		return shrine
	if _lantern == Vector2.INF:
		return wren.ground_pos
	if attempting:
		return _lantern
	var away := wren.ground_pos - _lantern
	var dir := away.normalized() if away.length() > 0.01 else Vector2.DOWN
	return _walkable(_lantern + dir * WATCH_DIST)


## The flame reaches Mira's shrine: it relights with the god's own flame (the win), and the light dies.
func _flame_home() -> void:
	home = true
	rules.banner.emit("MIRA'S SHRINE BURNS AGAIN")
	if wren.mind == Person.Mind.DUTY:
		wren.leave_shelter(false)
	_phase2_end()


## Where the real flame is: with Wren once swapped; else in its lantern (with its bearer, or where the last bearer
## fell); Vector2.INF when it is nowhere (Wren dead with it, or no Vigil at all).
func flame_at() -> Vector2:
	if swapped:
		return wren.ground_pos if _alive(wren) else Vector2.INF
	return _lantern


## Wren is gone: dead once he came, or nobody could be him.
func wren_lost() -> bool:
	return no_wren or (appeared and not _alive(wren))


func marks() -> Array:
	var out := [[shrine, MARK_SHRINE]]
	if not swapped and _lantern != Vector2.INF:
		out.append([_lantern, MARK_FLAME])
	if appeared and _alive(wren) and not wren.inside:
		out.append([wren.ground_pos, MARK_WREN])
	return out


## The HUD's arrow: Wren, once he has come, until the flame is home.
func marker() -> Vector2:
	return wren.ground_pos if appeared and _alive(wren) and not home else Vector2.INF


func report() -> Dictionary:
	return {"swapped": swapped, "seen": swap_seen, "reports": reports_started, "home": home}


func teardown() -> void:
	_unhook_kills(_on_killed)
	_phase2_end()
	vigil = null
	timeline = null


## Task 5 fills these in: Phase 2's Searchlight -- listening for casts, the strip's search, the light lit at the swap
## and stepped, a noise heard, and the light put out.
func _listen() -> void:
	pass


func _add_events() -> void:
	pass


func _phase2_begin() -> void:
	pass


func _phase2_step(_delta: float) -> void:
	pass


func _noise(_at: Vector2) -> void:
	pass


func _phase2_end() -> void:
	pass


## The Vigil Flame's Gaze: a seen death adds SEEN_DEATH_SCALE of GazeMeter.SEEN_DEATH; all else is GazeMeter's.
class FlameGaze extends GazeMeter:
	func seen_death() -> void:
		add(GazeMeter.SEEN_DEATH * SEEN_DEATH_SCALE)
```

- [ ] **Step 5: The mission.** In `src/game/mission/mission_book.gd`:
  - In `miras_house()`'s doc comment, replace "Broken Lanterns (the Ruin path) is M3's; the Vigil Flame is still M1's placeholder held until dawn, with the spec's brief and pool, until M4 builds it." with "Broken Lanterns (the Ruin path) is M3's, and the Vigil Flame (the Theft path) M4's."
  - Replace `vigil_flame()` with:

```gdscript
## Night 2 of the campaign, the Theft path (v0.10 M4): Wren swaps Halcyon's flame out of the Vigil's lantern unseen and
## carries it to Mira's shrine under the Searchlight (VigilFlameDirector). The default loadout costs 5 DP, so it fits a
## Night 2 after a bite.
static func vigil_flame() -> MissionDef:
	var m := _vigil(VIGIL_FLAME, "The Vigil Flame", PackedStringArray(["A priest carries Halcyon's flame.",
		"A mortal hand must steal it."]), PackedStringArray(VIGIL_POOL))
	m.goal = "Have Wren swap Halcyon's flame unseen, and carry it to Mira's shrine under the searchlight"
	m.goal_label = "The flame is stolen"
	m.lose = "The Lantern looks, Wren dies, the flame goes home to the Temple, or dawn comes first"
	m.clock = 180.0
	m.camera_at = VigilFlameDirector.CAMERA_AT
	m.intro_from = VigilFlameDirector.CAMERA_AT + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["whisper", "discord", "wisp"])
	m.director = VigilFlameDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [GazeObjective.new(), FlameObjective.new(), ClockObjective.new(false, "Dawn", "late")]
		return out
	return m
```

- [ ] **Step 6: The titles.** In `src/game/ui/results_screen.gd`, add `"flame": "THE FLAME IS STOLEN", "kept": "THE FLAME IS KEPT", "wren": "THE BOY IS DEAD", "late": "DAWN FINDS THE FLAME"` to `ACT_TITLES`. These four reasons are new: no other mission ends with them.

- [ ] **Step 7: The mission book's test.** In `tests/test_mission_book.gd`, replace these lines:

```gdscript
	var vf := MissionBook.vigil_flame()
	var held := []
	for o in vf.objectives():
		held.append(o.reason)
	t.check(vf.director == null and held == ["held"], "the Vigil Flame is still a placeholder held until dawn")
```

  with:

```gdscript
	var vf := MissionBook.vigil_flame()
	var vf_reasons := []
	for o in vf.objectives():
		vf_reasons.append(o.reason)
	var vf_dp := 0
	for key in vf.default_loadout:
		vf_dp += int(PowerBook.get_power(key).dp)
	t.check(vf.tier == 2 and vf.profile == "unaware" and not vf.scored and vf.director == VigilFlameDirector
		and vf_reasons == ["gaze", "flame", "late"] and is_equal_approx(vf.clock, 180.0),
		"the Vigil Flame is Tier 2, Unaware, on 3:00: lost to the Gaze, won by the flame home, lost at dawn (%s)" % [vf_reasons])
	t.check(vf_dp <= 5 and Array(vf.default_loadout).all(func(k: String) -> bool: return vf.allows(k)),
		"its default loadout is in its pool and fits a bitten Night 2's 5 DP (%d)" % vf_dp)
```

  Also change that block's comment `# Night 2's placeholders (M1): Tier 2, an Unaware town, unscored, held until dawn.` to `# Night 2's three missions (M2-M4): Tier 2, an Unaware town, unscored.`

- [ ] **Step 8: FLOW wins the Vigil Flame.** The placeholder is gone, so FLOW's campaign night can no longer be "held". In `src/game/game.gd`'s `_flow_campaign()`:
  - In its doc comment, replace "Night 2's three cards and the Theft placeholder held" with "Night 2's three cards and the Vigil Flame won with its flame home".
  - Replace `	# Night 2: three cards, the Theft placeholder held until dawn.` with `	# Night 2: three cards, the Vigil Flame won by bringing its flame home.`
  - Replace these four lines:

```gdscript
	_mission.rules().time_left = 0.01
	await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	step.call(save.campaign.night == 2 and save.campaign.path() == CampaignDef.THEFT and save.campaign.dp == dp1 + 2
		and String(result.get("reason", "")) == "held", "the night held: Night 3 next, on the Theft path, %d DP" % (dp1 + 2))
```

  with:

```gdscript
	(_mission.rules().director as VigilFlameDirector).home = true
	await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	# The flame home with no beam ever on Wren earns its bonus (Task 5): +1 DP on top of the win's 2.
	var dp2 := dp1 + CampaignDef.WIN_DP + (CampaignDef.BONUS_DP if CampaignState._bonus_earned(result) else 0)
	step.call(save.campaign.night == 2 and save.campaign.path() == CampaignDef.THEFT and save.campaign.dp == dp2
		and String(result.get("reason", "")) == "flame", "the flame home: Night 3 next, on the Theft path, %d DP" % dp2)
```

  - In the Night 3 part, replace `prep.draft.capacity == dp1 + 2, "with 4 slots and %d DP" % (dp1 + 2))` with `prep.draft.capacity == dp2, "with 4 slots and %d DP" % dp2)`.
  - Replace `save.campaign.bites == 1 and save.campaign.dp == dp1 + 1` with `save.campaign.bites == 1 and save.campaign.dp == dp2 - CampaignDef.BITE_DP`.

  FLOW keeps its 82 steps.

- [ ] **Step 9: Run the tests to verify they pass.** Run Import, then Tests. Expected: `checks=N failures=0`.
  - If `_cast`'s "Wren can walk to it" check fails, the walk grid has no way out of the walls to `MIRA_SHRINE`: the postern opens only in a town with river boats, so the way out may be the Main Gate and round the south-west corner. Move `MIRA_SHRINE` to the nearest reachable open ground at the west edge (outside the wall if any is reachable, else just inside it, west of x = -12) and report it.
- [ ] **Step 10: Run Digest, crowd_check, FLOW and the Mira's House reference.** Expected: Digest and crowd_check unchanged; FLOW `failures=0` with 82 steps; Mira's House identical to Task 1 Step 1.
- [ ] **Step 11: Commit.**

```bash
git add src/game/mission/vigil_flame_director.gd src/game/mission/vigil_flame_director.gd.uid src/game/mission/flame_objective.gd src/game/mission/flame_objective.gd.uid src/game/mission/mission_book.gd src/game/ui/results_screen.gd src/game/game.gd tests/test_vigil_flame.gd tests/test_vigil_flame.gd.uid tests/test_mission_book.gd tests/run_all.gd
git commit -m "feat: The Vigil Flame: the Vigil, Wren, the swap and the flame home (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 5: The Vigil Flame — Phase 2, Halcyon's Searchlight

**Files:**
- Create: `src/game/mission/unseen_hands_objective.gd`
- Modify: `src/game/mission/vigil_flame_director.gd`, `src/game/mission/mission_book.gd`, `tests/test_vigil_flame.gd`, `tests/test_mission_book.gd`

**Interfaces:**
- Consumes:
  - Task 2's `Searchlight` (`light()`, `put_out()`, `step()`, `beams()`, `touches()`, `hear()`, `lure()`, `aim()`, `SEARCH_LAST`, `SECOND_AFTER`);
  - Task 3's `SearchlightFx`;
  - Task 4's director and hooks;
  - `Rules.cast_made(slot, key, at)`;
  - `GazeMeter.add()`, `pray()`, `SEARCHLIGHT`, `PRAYER_PER_SECOND`;
  - `FxTimeline.cast()`, `end_now()`;
  - `Impact.dim()`.
- Produces, on `VigilFlameDirector`:
  - constants `TOUCH_GAZE`, `PRAY_SECONDS`, `PRAY_REACH`, `PRAYER_SCALE`, `UNHEARD`;
  - vars `touches: int`, `praying: Dictionary` (Person -> [seconds left, Vector2]), `benching: bool`;
  - funcs `praying_count() -> int`, `bench_beams()`, `_on_cast(slot, key, at)`; `report()` gains `"touches"`.
- Also produced: `UnseenHandsObjective`: label `"Unseen hands"`, reason `"unseen_hands"`.

- [ ] **Step 1: Write the failing tests.** In `tests/test_vigil_flame.gd`:
  - Add `_light(t)`, `_touches(t)`, `_prayer(t)`, `_heard(t)`, `_bonus(t)` and `_teardown(t)` to `run()` after `_focus(t)`.
  - Add these functions:

```gdscript
## The swap wakes the Searchlight: one beam, a second 30 s on, the strip's search in the clock's last 20 s.
static func _light(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	var banners: Array = s.banners
	_do_swap(s)
	t.check(d.searchlight.on and d.searchlight.beams() == 1 and banners.has("THE SPIRE FLARES"),
		"the swap wakes the Searchlight: one beam")
	_run(s, Searchlight.SECOND_AFTER)
	t.check(d.searchlight.beams() == 2 and banners.has("A SECOND BEAM"), "30 s on, a second")
	(s.rules as Rules).time_left = Searchlight.SEARCH_LAST
	d.timeline.step(200.0)
	_run(s, DT)
	t.check(banners.has("THE LIGHT SEARCHES"), "in the last 20 s the light searches")
	_done(s)


## A beam on Wren adds TOUCH_GAZE once each time he comes into the light (review focus 4: a beam resting on him counts
## once); found twice, the Gaze is full.
static func _touches(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	_do_swap(s)
	var w := d.wren
	_arrive(w, d.searchlight.aim(0))
	_run(s, DT)
	t.check(d.touches == 1 and is_equal_approx(d.gaze.value, VigilFlameDirector.TOUCH_GAZE)
		and (s.banners as Array).has("THE LIGHT FINDS THE BOY"), "a beam touching Wren adds 50 to the Gaze")
	for i in 20:
		_arrive(w, d.searchlight.aim(0))
		_run(s, DT)
	t.check(d.touches == 1 and is_equal_approx(d.gaze.value, VigilFlameDirector.TOUCH_GAZE),
		"a beam resting on him counts once, until he leaves the light")
	_arrive(w, OUT)
	_run(s, DT)
	_arrive(w, d.searchlight.aim(0))
	_run(s, DT)
	t.check(d.touches == 2 and d.gaze.is_full() and (s.rules as Rules).finished and (s.rules as Rules).over_reason == "gaze",
		"found twice, the Gaze is full: the night is lost")
	_done(s)


## A Faithful a beam touches stops and prays PRAY_SECONDS where he stands, feeding the Gaze; one held does not.
static func _prayer(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	_do_swap(s)
	var free: Array[Person] = []
	for x in d.faithful:
		if not d.vigil.walkers().has(x):
			free.append(x)
	var f := free[0]
	_arrive(f, d.searchlight.aim(0))
	_run(s, DT)
	t.check(d.praying.has(f) and f.mind == Person.Mind.DUTY and f.anchor.distance_to(f.ground_pos) < 0.01
		and d.praying_count() == 1, "a Faithful the beam touches stops and prays where he stands")
	var g0 := d.gaze.value
	_run(s, 1.0)
	t.near(d.gaze.value - g0, GazeMeter.PRAYER_PER_SECOND * VigilFlameDirector.PRAYER_SCALE, 0.06, "his prayer feeds the Gaze")
	_run(s, VigilFlameDirector.PRAY_SECONDS)
	t.check(not d.praying.has(f) and f.mind != Person.Mind.DUTY, "his prayer done, he goes back to his day")
	var h := free[1]
	h.confuse(15.0)
	_arrive(h, d.searchlight.aim(0))
	_run(s, DT)
	t.check(not d.praying.has(h), "one held by Discord does not pray")
	_done(s)


## What the light hears: a cast (even before it wakes), not a whisper; a Will-o'-Wisp is a decoy and a noise; a death
## is a noise.
static func _heard(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	var rules: Rules = s.rules
	var crowd: Crowd = s.crowd
	var at := Vector2(4.0, 6.0)
	rules.cast(_slot(rules, "discord"), at)
	t.check(d.searchlight.noise == at, "a cast is a noise, heard even before the light wakes")
	var c: Person = crowd.citizens[3]
	rules.cast(_slot(rules, "whisper"), c.ground_pos, {"target": c, "to": c.ground_pos + Vector2(1.0, 0.0)})
	t.check(d.searchlight.noise == at, "a Mind Whisper is unheard")
	_do_swap(s)
	var lure_at := d.searchlight.aim(0) + Vector2(3.0, 0.0)
	rules.cast(_slot(rules, "wisp"), lure_at)
	t.check(d.searchlight.decoy_beam == 0 and d.searchlight.decoy == lure_at and d.searchlight.noise == lure_at,
		"a Will-o'-Wisp is a decoy the beam follows, and a noise")
	var victim: Person = null
	for p in crowd.citizens:
		if _alive(p) and p != d.wren and not p.inside:
			victim = p
			break
	crowd._field.kill(victim, &"doom")
	t.check(d.searchlight.noise == victim.ground_pos, "a death is a noise")
	_done(s)


## Home with no beam ever on Wren: won, with Unseen hands, and the light dies; found once on the way: won without it.
static func _bonus(t) -> void:
	for touched in [false, true]:
		var s := _setup()
		var d: VigilFlameDirector = s.d
		var rules: Rules = s.rules
		_do_swap(s)
		if touched:
			_arrive(d.wren, d.searchlight.aim(0))
			_run(s, DT)
		_arrive(d.wren, d.shrine)
		_run(s, DT)
		var res := rules.result()
		var earned: bool = not res.bonuses.is_empty() and bool(res.bonuses[0].earned)
		if not touched:
			t.check(rules.won and earned and res.bonuses[0].label == "Unseen hands" and not d.searchlight.on,
				"home unseen by any beam: won, and Unseen hands; the light dies")
		else:
			t.check(rules.won and not earned and int(res.get("touches", 0)) == 1, "found once on the way: won, without the bonus")
		_done(s)


## Review focus 5: let go mid-Phase 2, the light is out, the prayers get up, and the world's signals are let go.
static func _teardown(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	var rules: Rules = s.rules
	_do_swap(s)
	var f: Person = null
	for x in d.faithful:
		if not d.vigil.walkers().has(x):
			f = x
			break
	_arrive(f, d.searchlight.aim(0))
	_run(s, DT)
	d.teardown()
	t.check(not d.searchlight.on and d.praying.is_empty() and f.mind != Person.Mind.DUTY
		and not rules.cast_made.is_connected(d._on_cast)
		and not (s.crowd as Crowd)._field.enemy_killed.is_connected(d._on_killed),
		"let go mid-search: the light out, the prayers released, the world's signals let go")
	_done(s)
```

  In `tests/test_mission_book.gd`, after the Vigil Flame's default-loadout check added in Task 4, add:

```gdscript
	t.check(vf.bonuses().size() == 1 and vf.bonuses()[0].label == "Unseen hands", "one bonus, Unseen hands")
```

- [ ] **Step 2: Run the tests to verify they fail.** Expected: a Parse Error naming `TOUCH_GAZE`, `praying`, `_on_cast` or `UnseenHandsObjective`.

- [ ] **Step 3: Write `UnseenHandsObjective`.** Create `src/game/mission/unseen_hands_objective.gd`:

```gdscript
class_name UnseenHandsObjective
extends Objective
## The Vigil Flame's bonus (v0.10): no beam of the Searchlight ever touches Wren.


func _init() -> void:
	label = "Unseen hands"
	reason = "unseen_hands"


func check(rules: Rules) -> Status:
	var d := rules.director as VigilFlameDirector
	return Status.FAILED if d != null and d.touches > 0 else Status.PENDING
```

  In `src/game/mission/mission_book.gd`'s `vigil_flame()`, before `return m`, add:

```gdscript
	m.make_bonuses = func() -> Array[Objective]:
		var out: Array[Objective] = [UnseenHandsObjective.new()]
		return out
```

- [ ] **Step 4: Phase 2 in the director.** In `src/game/mission/vigil_flame_director.gd`:
  - In the header comment, replace the last line `## - Phase 2 (Task 5): from the swap until the flame is home, Halcyon's Searchlight sweeps the town.` with:

```gdscript
## - Phase 2: from the swap until the flame is home, Halcyon's Searchlight (Searchlight, drawn by SearchlightFx) sweeps
##   the town from the Temple's spire: one beam, a second 30 s on, a Will-o'-Wisp a decoy, and in the clock's last 20 s
##   a beam stopping to search at the latest noise (any cast but a whisper, any death). A beam touching Wren adds
##   TOUCH_GAZE (two fill the Gaze); a Faithful it touches stops and prays.
```

  - Under `const SEEN_DEATH_SCALE := 1.0`, add:

```gdscript
## Phase 2 (spec §4.1): a beam touching Wren adds TOUCH_GAZE, once each time he comes into the light (two fill the Gaze).
## A Faithful a beam touches stops and prays PRAY_SECONDS where he stands; on his duty within PRAY_REACH of that spot
## he prays, feeding the Gaze (GazeMeter.pray(), scaled by PRAYER_SCALE: Task 7's lever for this mission alone). The
## Vigil's walkers and report carriers never stop to pray.
const TOUCH_GAZE := GazeMeter.SEARCHLIGHT
const PRAY_SECONDS := 5.0
const PRAY_REACH := 0.6
const PRAYER_SCALE := 1.0
## Casts the light does not hear: a Mind Whisper speaks in the mind.
const UNHEARD := ["whisper"]
```

  - Under `var _tick := 0.0`, add:

```gdscript
## Phase 2: how many times a beam has found Wren; the Faithful at prayer in the light -> [seconds left, where they
## kneel]; the bench's light, with no quarry (bench_beams()).
var touches := 0
var praying := {}
var benching := false
var _in_light := false
var _fx: SearchlightFx
```

  - Replace `report()` with:

```gdscript
func report() -> Dictionary:
	return {"swapped": swapped, "seen": swap_seen, "reports": reports_started, "home": home, "touches": touches}
```

  - Replace `teardown()` with:

```gdscript
func teardown() -> void:
	_unhook_kills(_on_killed)
	if is_instance_valid(rules) and rules.cast_made.is_connected(_on_cast):
		rules.cast_made.disconnect(_on_cast)
	_phase2_end()
	if is_instance_valid(_fx):
		_fx.end_now()
	_fx = null
	if ctx != null and ctx.impact != null:
		ctx.impact.dim(0.0, 4.0)
	vigil = null
	timeline = null
```

  - Replace the six Task 4 stubs (from the `## Task 5 fills these in` comment through the `_phase2_end()` stub) with:

```gdscript
func _listen() -> void:
	rules.cast_made.connect(_on_cast)


## The strip's search: in the clock's last Searchlight.SEARCH_LAST seconds, while the light is awake.
func _add_events() -> void:
	timeline.add(maxf(rules.time_left - Searchlight.SEARCH_LAST, 0.0), "search", "The light searches", Callable(),
		func() -> bool: return searchlight.on)


## The real flame leaves the lantern: the spire flares and the Searchlight wakes, one beam.
func _phase2_begin() -> void:
	searchlight.light()
	rules.banner.emit("THE SPIRE FLARES")
	_show_light()


func _phase2_step(delta: float) -> void:
	if not searchlight.on:
		return
	var had := searchlight.beams()
	searchlight.step(delta, rules.time_left)
	if searchlight.beams() > had:
		rules.banner.emit("A SECOND BEAM")
	if benching:
		return
	_touch()
	_pray(delta)


## A noise at `at` (any cast but a whisper, any death): where a searching beam stops in the clock's last seconds.
func _noise(at: Vector2) -> void:
	searchlight.hear(at)


## The light put out (the flame home, or the director let go): the beams die, the Faithful at prayer get up, and the
## drawing fades the dim away (SearchlightFx).
func _phase2_end() -> void:
	searchlight.put_out()
	for k: Variant in praying.keys():
		if _alive(k) and (k as Person).mind == Person.Mind.DUTY:
			(k as Person).leave_shelter(false)
	praying.clear()
	_in_light = false


## A cast the light hears (Rules.cast_made): a noise, unless UNHEARD; a Will-o'-Wisp a decoy too.
func _on_cast(_slot: int, key: String, at: Vector2) -> void:
	if key in UNHEARD:
		return
	_noise(at)
	if key == "wisp":
		searchlight.lure(at)


## The Searchlight drawn, when the director has the battlefield's effects (never in tests).
func _show_light() -> void:
	if ctx != null and ctx.overhead != null and not is_instance_valid(_fx):
		_fx = FxTimeline.cast(SearchlightFx, ctx, searchlight.spire, {"light": searchlight}) as SearchlightFx


## A beam coming onto Wren adds TOUCH_GAZE, once each time he comes into the light.
func _touch() -> void:
	var lit := _alive(wren) and not wren.inside and searchlight.touches(wren.ground_pos)
	if lit and not _in_light:
		touches += 1
		gaze.add(TOUCH_GAZE)
		rules.banner.emit("THE LIGHT FINDS THE BOY")
	_in_light = lit


## The Faithful a beam touches stop and pray where they stand for PRAY_SECONDS; at prayer they feed the Gaze. The Vigil's
## walkers, report carriers and anyone held, frightened or busy elsewhere do not stop.
func _pray(delta: float) -> void:
	var walking: Array[Person] = vigil.walkers() if vigil != null else ([] as Array[Person])
	for f in faithful:
		if praying.has(f) or not _alive(f) or f.inside or f.mind in BLIND or walking.has(f) or _carrying(f):
			continue
		if not (f.mind in RESUMABLE or f.mind == Person.Mind.DUTY):
			continue
		if searchlight.touches(f.ground_pos):
			praying[f] = [PRAY_SECONDS, f.ground_pos]
			f.go_duty(f.ground_pos)
	for k: Variant in praying.keys():
		var e: Array = praying[k]
		e[0] = float(e[0]) - delta
		if _alive(k) and float(e[0]) > 0.0:
			continue
		praying.erase(k)
		if _alive(k) and (k as Person).mind == Person.Mind.DUTY:
			(k as Person).leave_shelter(false)
	gaze.pray(praying_count(), delta * PRAYER_SCALE)


## The Faithful at prayer now: alive and out, on their duty within PRAY_REACH of where they knelt.
func praying_count() -> int:
	var n := 0
	for k: Variant in praying.keys():
		if not _alive(k):
			continue
		var p := k as Person
		var spot: Vector2 = praying[k][1]
		if not p.inside and p.mind == Person.Mind.DUTY and p.ground_pos.distance_to(spot) <= PRAY_REACH:
			n += 1
	return n


## The bench and the photograph (v0.10 M4, spec §7): the Searchlight lit at once with both beams, sweeping with no
## quarry. Nothing it touches counts and no Faithful prays, so the night runs on.
func bench_beams() -> void:
	benching = true
	searchlight.light(Searchlight.SECOND_AFTER)
	_show_light()
```

- [ ] **Step 5: Run the tests to verify they pass.** Run Import, then Tests. Expected: `checks=N failures=0`. Task 4's checks pass unchanged: the swap tests stage at `OUT` and `AWAY`, beyond the light.
- [ ] **Step 6: Run Digest, crowd_check and FLOW.** Expected: unchanged; FLOW `failures=0`, 82 steps. FLOW's flame-home night earns Unseen hands, and its DP is counted from the result.
- [ ] **Step 7: Commit.**

```bash
git add src/game/mission/vigil_flame_director.gd src/game/mission/unseen_hands_objective.gd src/game/mission/unseen_hands_objective.gd.uid src/game/mission/mission_book.gd tests/test_vigil_flame.gd tests/test_mission_book.gd
git commit -m "feat: The Vigil Flame: Phase 2, Halcyon's Searchlight (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 6: The `flame` scenario, the photographs and the bench hook

**Files:**
- Modify: `tools/dev/behaviour_check.gd`, `src/game/game.gd`, `src/game/mission.gd`

**Interfaces:**
- Consumes:
  - `VigilFlameDirector` (Tasks 4–5): `appeared`, `wren`, `swapping`, `swapped`, `swap_seen`, `home`, `touches`, `reports_started`, `flame_at()`, `faithful_seeing()`, `vigil`, `temple_door`, `searchlight`, `praying_count()`, `gaze`, `bench_beams()`;
  - `Searchlight.aim()`, `beams()`, `decoy_beam`, `SEARCH_LAST`;
  - `Rules.cast()`, `Rules.refusal()`, `Rules.key()`;
  - `_slot_ready()` (M3).
- Produces:
  - `--scenario=flame --case=none|play [--seed=N]`. Every 10 s it prints `BEHAVIOUR flame t=… phase=… touches=… praying=… reports=… gaze=… beams=…`. At the end it prints `BEHAVIOUR flame result won=… reason=… time=… swapped=… seen=… touches=… gaze=… bonus=…`;
  - `--show=flame` and `--show=flame-beams` on the game scene;
  - `--mission=vigil_flame --bench --bench-beams [--bench-after=SECONDS]` on the mission scene.

- [ ] **Step 1: The scenario.** In `tools/dev/behaviour_check.gd`:
  - Add to the scenario list in the header comment, after the `lanterns` lines:

```gdscript
##   flame  (v0.10 M4) The Vigil Flame, --case=none (nothing cast) or play (Mind Whisper, Discord, Will-o'-Wisp: Discord on
##          the Faithful watching the lantern, then Wren whispered to it; with the flame, a wisp to draw off a beam
##          coming at him, else a whisper out of its way; Discord at the Temple's door in the last 20 s). --seed= picks
##          the town.
```

  - Under `const LANTERN_BONUS_SPARE := 10.0`, add:

```gdscript
## The Vigil Flame policy (v0.10 M4): how near the lantern a Faithful counts as a watcher of the swap (Crowd.DOOM_WITNESS
## and a margin for his walk), how near a beam may come to Wren before the policy acts, and how far it moves him or the
## beam.
const FLAME_WATCH_R := 3.0
const FLAME_DANGER := 4.5
const FLAME_DODGE := 5.0
```

  - In the setup block, after the `elif scenario == "lanterns":` branch, add:

```gdscript
	elif scenario == "flame":
		powers = PackedStringArray(["whisper", "discord", "wisp"])
		mission.mission_id = MissionBook.VIGIL_FLAME
```

  - In the `match scenario:`, after `"lanterns":`, add:

```gdscript
		"flame":
			await _flame(Battlefield.arg_value(args, "--case"))
```

  - After `_lantern_target()`, add:

```gdscript
## The Vigil Flame (v0.10 M4), played every LOOK_FRAMES by a simple policy with Mind Whisper, Discord and Will-o'-Wisp.
## Before the swap: Discord on the Faithful watching the lantern (other than the bearer), then, nobody watching, a
## whisper sending Wren to it. With the flame: a beam within FLAME_DANGER of Wren is drawn off by a Will-o'-Wisp on its
## far side, else a whisper sends Wren FLAME_DODGE out of its way; in the clock's last 20 s, Discord at the Temple's door
## gives the searching beam a noise far from him. `none` casts nothing.
func _flame(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as VigilFlameDirector
	var slots := {}
	for slot in rules.loadout.size():
		if rules.key(slot) != "":
			slots[rules.key(slot)] = slot
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	var t := 0.0
	var frames := 0
	var report_at := 10.0
	while not rules.finished and frames < max_frames:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		if t >= report_at:
			report_at += 10.0
			print("BEHAVIOUR flame t=%d phase=%s touches=%d praying=%d reports=%d gaze=%d beams=%d" % [roundi(t),
				_flame_phase(d), d.touches, d.praying_count(), d.reports_started, roundi(d.gaze.value), d.searchlight.beams()])
		if which != "play" or frames % LOOK_FRAMES != 0:
			continue
		if not d.appeared or not is_instance_valid(d.wren) or not d.wren.is_alive() or d.home:
			continue
		if not d.swapped:
			_flame_swap(rules, d, slots)
		else:
			_flame_carry(rules, d, slots)
	var res := rules.result()
	var bonus: bool = not res.bonuses.is_empty() and bool(res.bonuses[0].earned)
	print("BEHAVIOUR flame result won=%s reason=%s time=%.1f swapped=%s seen=%s touches=%d gaze=%d bonus=%s" % [res.won,
		res.reason, float(res.time), d.swapped, d.swap_seen, d.touches, roundi(d.gaze.value), bonus])


func _flame_phase(d: VigilFlameDirector) -> String:
	if d.home:
		return "home"
	if d.swapped:
		return "carry"
	if d.swapping:
		return "swap"
	return "watch" if d.appeared else "wait"


## Before the swap: Discord on the watchers (their middle), then Wren whispered to the lantern.
func _flame_swap(rules: Rules, d: VigilFlameDirector, slots: Dictionary) -> void:
	var lantern := d.flame_at()
	if lantern == Vector2.INF or d.swapping:
		return
	var bearer: Person = d.vigil.bearer if d.vigil != null else null
	var watchers: Array[Person] = []
	for f in d.faithful:
		if f != bearer and d.faithful_seeing(f.ground_pos, 0.01, bearer) == f and f.ground_pos.distance_to(lantern) <= FLAME_WATCH_R:
			watchers.append(f)
	if not watchers.is_empty():
		if _slot_ready(rules, slots, "discord"):
			var mid := Vector2.ZERO
			for f in watchers:
				mid += f.ground_pos
			rules.cast(slots.discord, mid / float(watchers.size()))
		return
	var w := d.wren
	if w.mind != Person.Mind.WHISPERED and not w.shaken() and _slot_ready(rules, slots, "whisper"):
		rules.cast(slots.whisper, w.ground_pos, {"target": w, "to": lantern})


## With the flame: Discord at the Temple's door in the last 20 s; else, a beam closing on Wren drawn off by a wisp, or
## Wren whispered out of its way.
func _flame_carry(rules: Rules, d: VigilFlameDirector, slots: Dictionary) -> void:
	var w := d.wren
	var light := d.searchlight
	if rules.time_left <= Searchlight.SEARCH_LAST + 1.0 and _slot_ready(rules, slots, "discord"):
		rules.cast(slots.discord, d.temple_door)
		return
	var near_i := -1
	for i in light.beams():
		var gap := light.aim(i).distance_to(w.ground_pos)
		if gap <= FLAME_DANGER and (near_i < 0 or gap < light.aim(near_i).distance_to(w.ground_pos)):
			near_i = i
	if near_i < 0:
		return
	var beam := light.aim(near_i)
	var off := (beam - w.ground_pos).normalized() if beam.distance_to(w.ground_pos) > 0.01 else Vector2.RIGHT
	if light.decoy_beam < 0 and _slot_ready(rules, slots, "wisp"):
		rules.cast(slots.wisp, beam + off * FLAME_DODGE)
		return
	if w.mind == Person.Mind.WHISPERED or w.shaken() or not _slot_ready(rules, slots, "whisper"):
		return
	var to := mission._crowd._grid.nearest_walkable(w.ground_pos - off * FLAME_DODGE)
	rules.cast(slots.whisper, w.ground_pos, {"target": w, "to": to if to != Vector2.INF else w.ground_pos})
```

  (`d.faithful_seeing(f.ground_pos, 0.01, bearer) == f` is a short way to ask "f can see": alive, out, not held, not the bearer.)

- [ ] **Step 2: Run the scenario.** Run `--scenario=flame --case=none` and `--scenario=flame --case=play`, each with `timeout 600`.
  - Expected: no SCRIPT ERROR either way.
  - `none`: Wren tries the lantern himself at about 1:20, an acolyte sees it, and the report most likely fills the Gaze (`reason=gaze`).
  - `play` prints its result line.

  Record both lines for Task 7. This step only checks that the night runs.

- [ ] **Step 3: The photographs.** In `src/game/game.gd`'s `_ready()`:
  - In `match show:`, before `_:`, add:

```gdscript
		"flame", "flame-beams":
			# The Vigil Flame as its intro lands (v0.10 M4), for the photograph of the Vigil, its marks and the objectives;
			# flame-beams lights the Searchlight's two beams at once (VigilFlameDirector.bench_beams()) for the cones,
			# the pools of light and the dim (unpaused, as Mira's House's).
			mission_id = MissionBook.VIGIL_FLAME
			loadout = MissionBook.vigil_flame().default_loadout
			go_to(Screen.MISSION)
```

  - In the `if "--capture" in args:` branch, replace `		await get_tree().create_timer(1.0).timeout` with:

```gdscript
		if show == "flame-beams" and is_instance_valid(_mission) and _mission.rules() != null \
				and _mission.rules().director is VigilFlameDirector:
			(_mission.rules().director as VigilFlameDirector).bench_beams()
		await get_tree().create_timer(2.0 if show == "flame-beams" else 1.0).timeout
```

  Every other photograph keeps its one second.

- [ ] **Step 4: The bench hook.** In `src/game/mission.gd`:
  - In `_ready()`'s `elif "--bench" in args:` branch, replace:

```gdscript
		var bench_act := Battlefield.arg_value(args, "--bench-act")
		if bench_act != "":
			await _bench_jump(bench_act, args)
		await _bf.bench("mission" if bench_act == "" else "night-" + bench_act)
```

  with:

```gdscript
		var bench_act := Battlefield.arg_value(args, "--bench-act")
		var label := "mission"
		if bench_act != "":
			await _bench_jump(bench_act, args)
			label = "night-" + bench_act
		elif "--bench-beams" in args:
			await _bench_beams(args)
			label = "flame-beams"
		await _bf.bench(label)
```

  - After `_bench_jump()`, add:

```gdscript
## Bench aid (v0.10 M4, spec §7): `--mission=vigil_flame --bench --bench-beams` lights Halcyon's Searchlight with both
## beams at once (VigilFlameDirector.bench_beams()), then lets it sweep `--bench-after=SECONDS` (default 5) so the dim,
## the cones and the pools are up before the frames are timed. The Vigil Flame only: every other bench is untouched.
func _bench_beams(args: PackedStringArray) -> void:
	var d := _director as VigilFlameDirector
	if d != null:
		d.bench_beams()
	var after := Battlefield.arg_value(args, "--bench-after")
	await get_tree().create_timer(float(after) if after != "" else 5.0).timeout
```

- [ ] **Step 5: Take the photographs.** Capture `--show=flame`, `--show=flame-beams`, and `--show=flame-beams` again with `-- --art=procedural` added.
  - **`flame`, check by eye:**
    - the Vigil's three walkers near the Temple, a gold diamond over the bearer (the lantern);
    - the objective rows read "Halcyon's Gaze 0%", "The flame: in its lantern" and "Dawn 3:00";
    - the event strip shows "0:50 A boy watches the lantern" and "1:30 The route shortens".
  - **`flame-beams`, check by eye, on both art paths:**
    - a glow at the Temple's spire;
    - two gold cones falling from it onto two pools of light;
    - building faces and people in a pool lit warm;
    - the town darker around them;
    - dust motes in the beams.

  Fix `SPIRE_PX` (the lamp should sit at the spire's tip), the cone alphas or `CAMERA_AT` if needed, and report what changed.
- [ ] **Step 6: Try the bench hook once.** Run `timeout 120 $G --path . --audio-driver Dummy --scene res://scenes/mission.tscn -- --mission=vigil_flame --bench --bench-beams 2>&1 | grep "bench\["`. Expected: one `bench[flame-beams] …` line and no SCRIPT ERROR. Task 8 measures it properly.
- [ ] **Step 7: Run Tests, Digest, crowd_check and FLOW.** Expected: unchanged counts.
- [ ] **Step 8: Commit.**

```bash
git add tools/dev/behaviour_check.gd src/game/game.gd src/game/mission.gd
git commit -m "test: the flame scenario, the Vigil Flame photographs and the beams bench (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 7: Balance

**Files:** numbers only, in:
- `src/game/mission/vigil_flame_director.gd`;
- `src/game/mission/searchlight.gd`;
- `src/game/mission/mission_book.gd` (the clock);
- `tools/dev/behaviour_check.gd` (the policy's loadout and its `FLAME_*` numbers);
- the tests that pin a changed number.

- [ ] **Step 1: Measure.** Run `--case=none` three times and `--case=play` three times, with seeds `--seed=1|2|3`. Record each result line, and each play run's 10-second lines.
- [ ] **Step 2: Compare with the spec's intent** (§7: "each Night 2 mission winnable at 8 DP by a scripted policy"):
  - doing nothing loses, 3 seeds out of 3;
  - the policy wins at least 2 seeds out of 3;
  - no win comes before about 1:30 (`time` ≥ ~90), so the swap and the carry both matter.

  The scripted policy is a measuring tool. It may play like a sensible player, but it must stay within the pool, 3 slots and 8 DP.
- [ ] **Step 3: Expect prayer to be the wall,** as it was in Broken Lanterns. A beam crossing the town touches many Faithful. Six at prayer already reach `GazeMeter.PRAYER_CAP`, so prayer alone can fill the Gaze within a minute of Phase 2. If `play` loses to `gaze` and the 10-second lines show `praying=` at 4 or more, try these levers first, in order:
  1. `PRAYER_SCALE` (this mission only; `GazeMeter`'s constants stay, for Mira's House and Broken Lanterns);
  2. `PRAY_SECONDS`;
  3. `Searchlight.POOL_R`.

  If seen deaths are the wall instead (the reports or the Gaze rising on kills), use `SEEN_DEATH_SCALE`.
- [ ] **Step 4: Other walls you may meet.**
  - **The swap never starts** (phase `watch` until Wren's own try): the walking bearer leaves Wren's whisper spot behind. Try `SWAP_REACH`, then `VIGIL_PACE`.
  - **The carry is too short,** a win before 1:30: try `WREN_PACE`, then `MIRA_SHRINE` (placement).
  - **The beams never find Wren,** so the bonus is trivial and Phase 2 is empty: try `SPIN`, `FAR` and `REACH_PERIOD`.
- [ ] **Step 5: Tune only these:**
  - in the director: `PRAYER_SCALE`, `PRAY_SECONDS`, `PRAY_REACH`, `SEEN_DEATH_SCALE`, `TOUCH_GAZE` (a multiple of `GazeMeter.SEARCHLIGHT`), `VIGIL_PACE`, `WREN_PACE`, `WATCH_DIST`, `WREN_AT`, `WREN_OWN_AFTER`, `SWAP_REACH`, `SWAP_HOLD`, `SWAP_SECONDS`, `ROUTE_AT`, `HOME_REACH`, `SHRINE_REACH`, `FAITHFUL`;
  - in `Searchlight`: `POOL_R`, `SPIN`, `NEAR`, `FAR`, `REACH_PERIOD`, `SECOND_AFTER`, `SEARCH_LAST`, `DECOY_SECONDS`, `BEAM_SPEED`;
  - the clock;
  - the policy's loadout and its `FLAME_*` numbers.

  Keep `BEAM_SPEED` above the sweep's own speed (`SPIN × FAR` plus `(FAR − NEAR) × π / REACH_PERIOD`): the tests rely on a beam keeping to its path. If `FAR` grows, check that the tests' `OUT` and `AWAY` still lie beyond it (`_cast` says so). Record each change with before and after result lines.
- [ ] **Step 6: Run Tests.** Retune any test that pins a changed number.
- [ ] **Step 7: Run the Mira's House and Broken Lanterns references again.** Expected: identical to Task 1 Step 1. Shared numbers must not move.
- [ ] **Step 8: Commit** with the measurements in the message body.

```bash
git add src/game/mission/vigil_flame_director.gd src/game/mission/searchlight.gd src/game/mission/mission_book.gd tools/dev/behaviour_check.gd tests/test_vigil_flame.gd tests/test_searchlight.gd
git commit -m "tune: The Vigil Flame balance from measured runs (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 8: The Searchlight bench (spec §7)

**Files:** none unless the budget is missed. Then only `src/fx/searchlight_fx.gd`'s look (`DUST_RATE`, the dust itself, `SPIRE_GLOW_PX`) or how the cones are drawn.

Spec §7: "the searchlight with two beams over the full town stays within 5 fps of Last Judgement's bench at `kak-v0.09`".

- [ ] **Step 1: A quiet machine.** Close Discord, Edge, Chrome, ChatGPT, screen sharing and every other Godot window (memory: a busy machine swings one build 98–120 fps). Plug the laptop in.
- [ ] **Step 2: The old build in a scratch worktree.** In Git Bash, from this checkout:

```bash
S=/c/Users/dorae/AppData/Local/Temp/kak-bench    # any scratch folder outside the repository
mkdir -p "$S"
git worktree add "$S/v009" kak-v0.09
cp -r .godot "$S/v009/"
timeout 900 $G --headless --editor --path "$S/v009" --import >/dev/null 2>&1
```

- [ ] **Step 3: Alternating pairs.** Run six alternating pairs: `kak-v0.09`'s Last Judgement, then this tree's two beams.

```bash
for i in 1 2 3 4 5 6; do
  timeout 120 $G --path "$S/v009" --audio-driver Dummy --scene res://scenes/mission.tscn -- --bench 2>&1 | grep "bench\["
  timeout 120 $G --path . --audio-driver Dummy --scene res://scenes/mission.tscn -- --mission=vigil_flame --bench --bench-beams 2>&1 | grep "bench\["
done
```

  Then three runs of this tree's own Last Judgement, to tell the beams' cost from the tree's drift:

```bash
for i in 1 2 3; do
  timeout 120 $G --path . --audio-driver Dummy --scene res://scenes/mission.tscn -- --bench 2>&1 | grep "bench\["
done
```

- [ ] **Step 4: Judge.**
  - Use only pairs where both runs are above 100 fps; the rest are machine noise. Report every line.
  - **Pass:** the mean `avg_fps` of `bench[flame-beams]` is at least the mean of `kak-v0.09`'s `bench[mission]` minus 5.
  - Also report `draw_calls` for both. Draw calls do not depend on how busy the machine is.
- [ ] **Step 5: If it misses,** profile before changing anything (memory: the frame is CPU-bound; count draw calls; hide node categories).
  - The likely costs: the two dynamic lights every structure and person samples (`LightField._dynamic`), the dust's redraw, and the full-screen dim.
  - Try, in order: drop the dust; lower `DUST_RATE`; draw both cones in one polygon call.
  - Do not change the beams' logic. Commit as `perf: …` with before and after numbers.
- [ ] **Step 6: Clean up.** Run `git worktree remove --force "$S/v009"`, and report the table to the controller.

### Task 9 (controller): M4 gate

- [ ] **Step 1: Gates:**
  - Tests: `failures=0`, with the count reported;
  - Digest and crowd_check unchanged;
  - the ten exact behaviour checksums identical to Global Constraints (or to the controller's updated list after the merged-tree gate run);
  - `--scenario=miras --case=play` identical to Task 1 Step 1;
  - the four Broken Lanterns result lines identical to Task 1 Step 1;
  - FLOW: `failures=0`, 82 steps;
  - Mission tests in range.
- [ ] **Step 2: Photographs:**
  - `--show=flame`;
  - `--show=flame-beams`, with the default art and with `--art=procedural`;
  - `--show=miras`, `--show=lanterns` and `--show=campaign-choice`, unchanged.

  Show them to the user.
- [ ] **Step 3: Playtest by hand:** Campaign, then on Night 2 choose The Vigil Flame.
- [ ] **Step 4: Land:** fast-forward `feat/Develop-Main`. If origin moved, merge it first and rerun the gates on the merged code. With the user's go-ahead, tag `kak-v010-m4` and push. Report:
  - the plan's departures from the spec (above);
  - Task 7's measurements;
  - Task 8's bench table.
- [ ] **Step 5: Update the Dev Ledger:** M4 to done; `meta/project` with the new counts (tests, FLOW, the bench).
- [ ] **Step 6: Write the M5 plan** (story and balance).
