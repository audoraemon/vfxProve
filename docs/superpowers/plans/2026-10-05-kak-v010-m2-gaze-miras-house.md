# KAK v0.10 M2 — Halcyon's Gaze and Mira's House Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** the Faith path's Night 2, *Mira's House*, becomes a real mission. Lead the grieving to Mira's journal while the Faithful don't see, under Halcyon's Gaze, through four timed events: the Inquisitor's search, a loud convert, the Vigil passing, and the house set on fire.

**Architecture:**
- **`GazeMeter`** is a 0–100 meter that never falls. It lives on `MissionDirector.gaze`, so M3 and M4's directors reuse it.
  - `GazeObjective` fails the night when the meter is full.
  - The HUD draws it as a bar under the clock.
- **The Faithful report what they see:** a report is a `TempleReport`, one Faithful running to the Temple. A death someone sees passes the report on to the witness. A report that arrives fills the Gaze.
  - The messenger logic is The Warning's pattern, written fresh, so The Warning's code (and its exact checksums) does not change.
- **`MirasHouseDirector`** handles the rest:
  - the house and its door;
  - choosing the Grieving and the Faithful;
  - going in, reading and coming out a Believer;
  - the seen checks;
  - the timed events, on an `EventTimeline`;
  - the fire, and the roof falling.
- **`VigilRoute`** walks the flame-bearer and two acolytes along a route. M3 and M4 walk it around the six shrines.
- **Faith on people:** `CitizenProfile.faith` marks the Faithful, the Grieving and Believers. The HUD draws a small mark over the Grieving and Believers through a new `MissionDirector.marks()`.

**Tech Stack:** Godot 4.7.2, GDScript; headless tests in `tests/run_all.gd`; scripted scenarios in `tools/dev/behaviour_check.gd`.

**Spec:** `docs/superpowers/specs/2026-10-05-kak-v010-lantern-campaign-design.md`. Read §3.4, §4.1 (the Vigil, and Faith — Mira's House), §6, §7 and §8.2 before any task. This plan covers **M2**.

## Global Constraints

- **Baseline:** `feat/Develop-Main` at `cba4649` (tag `kak-v010-m1`; M1 plus the merged PixelLab art). The milestone tag is `kak-v010-m2`.
- **No playtest notes yet:** the user asked for this plan before playtesting M1. Every number below is a starting value from the spec, and Task 7 measures it.
- **Machine:** the BURIN_NITRO laptop.
  - **Repository:** the main checkout is `C:\BURIN_NITRO\Godot\GIT\vfxProve` (Git Bash `/c/BURIN_NITRO/Godot/GIT/vfxProve`) on `feat/Develop-Main`. Work in the checkout the controller names: the main checkout, or a session worktree on a branch made from `feat/Develop-Main`. Never touch other sessions' worktrees.
  - **In a fresh worktree,** run the import first.
  - **Godot:** `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`.
- **Commands:**
  - **Import** (after a new `class_name` or a new test file): `timeout 900 $G --headless --editor --path . --import >/dev/null 2>&1`.
  - **Tests:** `timeout 1200 $G --headless --path . --script res://tests/run_all.gd 2>&1 | grep -v '^\s*at:' | grep -n "FAIL\|SCRIPT ERROR\|Parse Error\|checks="`. Expected: `checks=N failures=0`. The baseline is **2858**. The `leaked` / `still in use` lines at exit are there at baseline too.
  - **Digest:** `$G --headless --path . -s tools/dev/state_digest.gd`. Expected: `digest=61267b7e90524d800bf1c3473a71146b`.
  - **crowd_check:** `$G --headless --path . --fixed-fps 60 -s tools/dev/crowd_check.gd`. Expected: `checksum=-346732806`.
  - **Behaviour (exact):** `$G --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=<name>`. Give each run `timeout 600`, and run them in the background with a long limit, since the ten take about 15 min:
    - `calm --seconds=60`: -695580348
    - `gates`: 619520995
    - `fire`: -16560442
    - `rite --interrupt`: -129298221
    - `soldiers --case=escort`: -935015846
    - `warning --case=none|doom|whisper|discord|mix`: -446012507, -999129915, 442055066, -909358062, -430643507
  - **FLOW:** `$G --path . --audio-driver Dummy --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep "FLOW"`. Expected: `failures=0`. The baseline is **82**.
  - **Mission tests:** `--mission-test` within a few of: buildings 53–57, citizens 184–193, escaped 0–1, stability 67–71%, citadel 50%. `--mission=warning --mission-test` gives `won=false reason=bell time≈24`.
  - **Captures:** `GODOT=$G SCENE=res://scenes/game.tscn bash tools/capture.sh --show=<name> --capture`.
- **Test style:** as in M1.
  - `extends RefCounted`, `static func run(t)`, `t.check` / `t.near`.
  - Register each new file at the end of `SUITES`.
  - Build the town and crowd like `tests/test_warning.gd`'s `_setup()`, and step `crowd.advance(DT)` then `rules.advance(DT)`.
  - Move people by hand with `_arrive()` / `_clear_round()`, copied from `test_warning.gd`.
- **Code style:** tabs; `##` docs in full sentences; `UPPER_CASE` constants with a `##` comment; **new enum values go at the end**. `CitizenProfile.Role` gains nothing in M2: Venn and the Vigil's priests are clergy, wearing the clergy look.
- **Nothing outside Mira's House may change.** The Warning, The Long Night, Last Judgement and the two Night 2 placeholders still in M2 (The Vigil Flame, Broken Lanterns) play exactly as before. Every exact gate stays identical.
- **Git:** explicit paths with `.gd.uid` files; never `default_bus_layout.tres`, `captures/`, `.codex/`, `concepts/`; subjects tagged `(v0.10)`, ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. **Do not push or tag:** the controller does that at the gate.
- **Tuning latitude:** the code was written against `cba4649` and has not been run. Fix real bugs and keep each test's intent. Placement constants (`MIRA_SPOT`, the door offset, the Vigil's route, `LINE_SPOTS`, screen pixels) may move when the town's geometry needs it. Gameplay numbers move only in Task 7. Report every deviation.

## Review Focus

These are inputs the spec implies but no feature test exercises. Each line has its test in the owning task.

1. **The people an event needs are already dead or busy:** Venn killed before 0:40; no Believer outside at 1:15; the shouter killed during the window; a liner or Vigil walker already carrying a report. The event is skipped or shortened quietly, with no SCRIPT ERROR and no report from a dead Faithful. *Test:* Task 5.
2. **Mira's house destroyed early** (a Heaven Splitter on it, or the fire spreading) while people are inside. Everyone inside comes out at the door, there are no new entries, no SCRIPT ERROR, and the roof at dawn does nothing more. *Test:* Task 5.
3. **Two reports at once, or a report's carrier killed in front of the other carrier.** Each report runs on its own; a report passed to someone already carrying one is not counted twice, and the Gaze fills once. *Test:* Task 2.
4. **The bell rings from the town's own alarm** (killings in the square) rather than a report. The Gaze fills and the night is lost, with the reason `gaze`. *Test:* Task 4.
5. **A Grieving citizen walks past the door on their own day,** neither whispered nor lured. They do not go in and nothing is reported. *Test:* Task 4.

## Where this plan departs from the spec

The controller reports these to the user at the gate.

1. **The fire flushes the house.** The spec says anyone inside when the roof falls dies. But a reading takes 10 s, so everyone inside would walk out long before 2:30 and the twist would never bite. In this plan, at 2:00 everyone inside runs out into the street in a fright, unconverted if their reading was not done, under any Faithful eyes nearby. The roof still falls at dawn, and kills anyone still inside (nobody, normally). So 2:00 is a soft deadline for finishing readings.
2. **A seen entry turns the reader away.** The spec says a conversion under way fails when its reader is seen going in. Here the reader does not go in at all, and the Faithful who saw it reports.
3. **Venn wears the clergy look.** The spec's new `INQUISITOR` look waits for M5's PixelLab pass. Adding a role means art on both art paths.
4. **`TempleReport` copies The Warning's messenger logic** instead of sharing code with `WarningDirector`. That keeps The Warning's exact checksums safe.
5. **The Faithful who see are those not held:** anyone confused by Discord or under a Mind Whisper sees nothing. That gives Discord its role here.

---

## File structure

| File | Responsibility |
|---|---|
| `src/game/mission/gaze_meter.gd` | **New.** `GazeMeter`: the 0–100 meter and its sources |
| `src/game/mission/gaze_objective.gd` | **New.** Fails the night when the Gaze is full |
| `src/game/mission/temple_report.gd` | **New.** One report on its way to the Temple, passed on by a seen death |
| `src/game/mission/vigil_route.gd` | **New.** The flame-bearer and two acolytes walking a route |
| `src/game/mission/miras_house_director.gd` | **New.** Mira's House |
| `src/game/mission/believers_objective.gd`, `pure_faith_objective.gd`, `journal_objective.gd` | **New.** The night's objective and bonuses |
| `src/game/mission/mission_director.gd` | `gaze`, `marks()` |
| `src/game/mission/mission_book.gd` | `miras_house()` becomes the real mission |
| `src/game/crowd/citizen_profile.gd` | `enum Faith`, `var faith` |
| `src/game/ui/hud.gd` | The Gaze bar; the marks |
| `src/game/ui/results_screen.gd` | The titles `gaze`, `believers`, `few` |
| `tools/dev/behaviour_check.gd` | The `miras` scenario |
| `tests/test_gaze.gd`, `test_temple_report.gd`, `test_vigil_route.gd`, `test_miras_house.gd` | **New** tests |
| `tests/test_mission_book.gd` | Mira's House is no longer a placeholder |

---

## Milestone 2 — The Gaze and Mira's House

### Task 1: Halcyon's Gaze

**Files:**
- Create: `src/game/mission/gaze_meter.gd`, `src/game/mission/gaze_objective.gd`, `tests/test_gaze.gd`
- Modify: `src/game/mission/mission_director.gd`, `src/game/ui/hud.gd`, `src/game/ui/results_screen.gd`, `tests/run_all.gd`

**Interfaces:**
- Produces:
  - `GazeMeter`:
    - `signal filled`;
    - constants `FULL := 100.0`, `SEEN_DEATH := 10.0`, `PRAYER_PER_SECOND := 1.0`, `PRAYER_CAP := 6.0`, `SEARCHLIGHT := 50.0`;
    - `var value: float`;
    - `add(amount: float)`, `seen_death()`, `pray(praying: int, delta: float)`, `fill()`, `fraction() -> float`, `is_full() -> bool`.
  - `GazeObjective extends Objective`: label `"Halcyon's Gaze"`, reason `"gaze"`; FAILED once `rules.director.gaze.is_full()`; `hud_text` gives `"Halcyon's Gaze 40%"`, or `""` without a gaze.
  - `MissionDirector`: `var gaze: GazeMeter` (null unless a director makes one); `func marks() -> Array` (`[Vector2, Color]` pairs; `[]` by default).
  - `Hud`: `static gaze_of(rules: Rules) -> float` (-1.0 without a gaze); `_draw_gaze(w)`; `_draw_marks()`.
  - `ResultsScreen.ACT_TITLES` gains `"gaze": "THE LANTERN LOOKS"`, `"believers": "THEY BELIEVE"`, `"few": "TOO FEW BELIEVE"`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_gaze.gd`:

```gdscript
extends RefCounted
## v0.10 Halcyon's Gaze (spec §3.4): a meter from 0 to 100 that never falls; a seen death adds 10, prayer adds up to 6 a
## second, a report or the bell fills it; full, it fails the night. The HUD reads it; the results name the ending.


static func run(t) -> void:
	var g := GazeMeter.new()
	var fills := [0]
	g.filled.connect(func() -> void: fills[0] += 1)
	t.check(g.value == 0.0 and g.fraction() == 0.0 and not g.is_full(), "the Gaze starts at 0")
	g.seen_death()
	t.near(g.value, 10.0, 0.001, "a seen death adds 10")
	g.pray(3, 1.0)
	t.near(g.value, 13.0, 0.001, "three praying for a second add 3")
	g.pray(20, 1.0)
	t.near(g.value, 19.0, 0.001, "prayer is capped at 6 a second")
	g.add(-50.0)
	t.near(g.value, 19.0, 0.001, "the Gaze never falls")
	g.add(GazeMeter.SEARCHLIGHT)
	g.add(GazeMeter.SEARCHLIGHT)
	t.check(g.is_full() and g.value == GazeMeter.FULL and fills[0] == 1, "two searchlight touches fill it, once")
	g.fill()
	t.check(fills[0] == 1, "filling a full Gaze says nothing more")
	var h := GazeMeter.new()
	h.fill()
	t.check(h.is_full() and h.fraction() == 1.0, "a report fills it at once")

	# The objective, and the HUD's reading, through a director that has a Gaze.
	var d := MissionDirector.new()
	var rules := Rules.new()
	rules.director = d
	var o := GazeObjective.new()
	t.check(o.check(rules) == Objective.Status.PENDING and o.hud_text(rules) == "" and Hud.gaze_of(rules) == -1.0,
		"without a Gaze the objective waits, shows nothing, and the HUD draws no bar")
	d.gaze = GazeMeter.new()
	d.gaze.add(40.0)
	t.check(o.check(rules) == Objective.Status.PENDING and o.hud_text(rules) == "Halcyon's Gaze 40%",
		"the objective's line: %s" % o.hud_text(rules))
	t.near(Hud.gaze_of(rules), 0.4, 0.001, "the HUD's bar reads 40%")
	d.gaze.fill()
	t.check(o.check(rules) == Objective.Status.FAILED and o.reason == "gaze", "a full Gaze fails the night")
	t.check(MissionDirector.new().marks().is_empty(), "a director marks nobody by default")
	t.check(ResultsScreen.title_for(false, "gaze") == "THE LANTERN LOOKS" and ResultsScreen.title_for(true, "believers")
		== "THEY BELIEVE" and ResultsScreen.title_for(false, "few") == "TOO FEW BELIEVE", "the night's endings have titles")
	rules.free()
```

Register it at the end of `SUITES`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `GazeMeter`.

- [ ] **Step 3: Write `GazeMeter`.** Create `src/game/mission/gaze_meter.gd`:

```gdscript
class_name GazeMeter
extends RefCounted
## Halcyon's Gaze (v0.10, spec §3.4): how near the Lantern is to looking at the town, from 0 to FULL. It never falls
## during a night. A death someone sees adds SEEN_DEATH; each Faithful praying adds PRAYER_PER_SECOND, at most
## PRAYER_CAP a second in all; the searchlight touching its quarry adds SEARCHLIGHT; a report reaching the Temple, or
## the bell, fills it. Full, it says so once (`filled`), and GazeObjective loses the night.

signal filled

const FULL := 100.0
const SEEN_DEATH := 10.0
const PRAYER_PER_SECOND := 1.0
const PRAYER_CAP := 6.0
const SEARCHLIGHT := 50.0

var value := 0.0


func add(amount: float) -> void:
	if amount <= 0.0 or is_full():
		return
	value = minf(FULL, value + amount)
	if is_full():
		filled.emit()


func seen_death() -> void:
	add(SEEN_DEATH)


## `praying` Faithful at prayer for `delta` seconds.
func pray(praying: int, delta: float) -> void:
	add(minf(float(praying) * PRAYER_PER_SECOND, PRAYER_CAP) * delta)


func fill() -> void:
	add(FULL)


func fraction() -> float:
	return value / FULL


func is_full() -> bool:
	return value >= FULL
```

- [ ] **Step 4: Write `GazeObjective`.** Create `src/game/mission/gaze_objective.gd`:

```gdscript
class_name GazeObjective
extends Objective
## Halcyon's Gaze full (v0.10): the Lantern looks, and the night is lost. Waits while the mission's director has no Gaze.


func _init() -> void:
	label = "Halcyon's Gaze"
	reason = "gaze"


func check(rules: Rules) -> Status:
	var g := _gaze(rules)
	return Status.FAILED if g != null and g.is_full() else Status.PENDING


func hud_text(rules: Rules) -> String:
	var g := _gaze(rules)
	return "" if g == null else "Halcyon's Gaze %d%%" % roundi(g.fraction() * 100.0)


static func _gaze(rules: Rules) -> GazeMeter:
	return rules.director.gaze if rules != null and rules.director != null else null
```

- [ ] **Step 5: The director's Gaze and marks.** In `src/game/mission/mission_director.gd`, under `var timeline: EventTimeline`, add:

```gdscript
## Halcyon's Gaze (v0.10), for the campaign's Night 2 missions; null elsewhere.
var gaze: GazeMeter
```

and after `marker()`:

```gdscript
## Ground points the HUD marks with a small coloured diamond over the head (v0.10: Mira's House's grieving and
## Believers), as [Vector2, Color] pairs; none by default.
func marks() -> Array:
	return []
```

- [ ] **Step 6: The HUD.** In `src/game/ui/hud.gd`:
  - Under `const EVENTS_TOP`, add:

```gdscript
## Halcyon's Gaze under the clock (v0.10), where the Banishing Rite's bar would sit (an Unaware town has no rite).
const GAZE_BAR := Vector2(120.0, 4.0)
const GAZE_TOP := 30.0
## How far above a marked person's feet their mark sits, and its half size (v0.10).
const MARK_LIFT := 22.0
const MARK_R := 2.0
```

  - In `_draw()`, add `_draw_gaze(w)` right after `_draw_rite(w)`, and `_draw_marks()` right before `_draw_marker()`.
  - Add, after `marker_shown()`:

```gdscript
## How full Halcyon's Gaze is (v0.10), or -1.0 when the mission's director keeps none.
static func gaze_of(rules: Rules) -> float:
	if rules == null or rules.director == null or rules.director.gaze == null:
		return -1.0
	return rules.director.gaze.fraction()


func _draw_gaze(w: float) -> void:
	var f := gaze_of(_rules)
	if f < 0.0:
		return
	var at := Vector2(roundf((w - GAZE_BAR.x) * 0.5), GAZE_TOP)
	draw_rect(Rect2(at, GAZE_BAR), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(at, Vector2(roundf(GAZE_BAR.x * f), GAZE_BAR.y)), UiTheme.COL_GOLD.lerp(UiTheme.COL_BAD, f))


## A small diamond over each person the director marks (v0.10).
func _draw_marks() -> void:
	if _rules.director == null:
		return
	var xf := get_viewport().get_canvas_transform() if is_inside_tree() else Transform2D.IDENTITY
	for m: Array in _rules.director.marks():
		var c: Vector2 = (xf * Iso.ground_to_screen(m[0] as Vector2) - Vector2(0.0, MARK_LIFT)).round()
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -MARK_R), c + Vector2(MARK_R, 0), c + Vector2(0, MARK_R),
			c + Vector2(-MARK_R, 0)]), m[1] as Color)
```

- [ ] **Step 7: The titles.** In `src/game/ui/results_screen.gd`, add `"gaze": "THE LANTERN LOOKS", "believers": "THEY BELIEVE", "few": "TOO FEW BELIEVE"` to `ACT_TITLES`.

- [ ] **Step 8: Run the tests to verify they pass.** Run Import, then Tests. Expected: `checks=N failures=0`. Then run Digest and crowd_check: unchanged.

- [ ] **Step 9: Commit.**

```bash
git add src/game/mission/gaze_meter.gd src/game/mission/gaze_meter.gd.uid src/game/mission/gaze_objective.gd src/game/mission/gaze_objective.gd.uid src/game/mission/mission_director.gd src/game/ui/hud.gd src/game/ui/results_screen.gd tests/test_gaze.gd tests/test_gaze.gd.uid tests/run_all.gd
git commit -m "feat: Halcyon's Gaze: the meter, its objective, its bar (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 2: Faith on people, and the report to the Temple

**Files:**
- Create: `src/game/mission/temple_report.gd`, `tests/test_temple_report.gd`
- Modify: `src/game/crowd/citizen_profile.gd`, `tests/run_all.gd`

**Interfaces:**
- Produces:
  - `CitizenProfile.Faith { NONE, FAITHFUL, GRIEVING, BELIEVER }` and `var faith := Faith.NONE`.
  - `TempleReport`:
    - `_init(p: Person, temple_door: Vector2)`;
    - `var carrier: Person`, `var door: Vector2`, `var delivered: bool`, `var dead: bool`, `var relays: int`;
    - `step(delta: float, crowd: Crowd)`, `on_killed(e: DummyEnemy)`, `is_open() -> bool`;
    - constants `REACH := 1.0`, `RETARGET := 0.5`.
  - On delivery, the carrier goes back to their day (`leave_shelter(false)`).

- [ ] **Step 1: Write the failing test.** Create `tests/test_temple_report.gd`:

```gdscript
extends RefCounted
## v0.10 a report to the Temple (TempleReport): a Faithful who saw the god at work runs to the Temple's door; there the
## report is delivered. A death nobody sees ends it; a seen one passes it to the witness, who runs on. Fright and the
## god's holds interrupt the run until the carrier is back on its feet. Two reports run apart (review focus 3).

const DT := 0.05


static func _crowd() -> Dictionary:
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
	var door := grid.nearest_walkable(Vector2(TownLayout.TEMPLE.get_center().x, TownLayout.TEMPLE.end.y + 0.6))
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "door": door}


static func _done(s: Dictionary) -> void:
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


static func _run(s: Dictionary, reports: Array, seconds: float) -> void:
	for i in roundi(seconds / DT):
		(s.crowd as Crowd).advance(DT)
		for r: TempleReport in reports:
			r.step(DT, s.crowd)


## Everyone but `keep` within `reach` of `at` moved well away.
static func _clear_round(crowd: Crowd, at: Vector2, reach: float, keep: Array) -> void:
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and not keep.has(p) and p.ground_pos.distance_to(at) <= reach:
				p.ground_pos = at + (p.ground_pos - at).normalized() * (reach + 6.0) if p.ground_pos != at \
					else at + Vector2(reach + 6.0, 0.0)


static func run(t) -> void:
	t.check(CitizenProfile.new().faith == CitizenProfile.Faith.NONE, "nobody is of any faith by default")
	var s := _crowd()
	var crowd: Crowd = s.crowd
	var door: Vector2 = s.door
	var a: Person = crowd.citizens[3]
	var r := TempleReport.new(a, door)
	t.check(a.mind == Person.Mind.DUTY and r.is_open() and r.carrier == a, "the Faithful runs to the Temple")
	a.ground_pos = door + Vector2(0.4, 0.0)
	_run(s, [r], DT * 2.0)
	t.check(r.delivered and not r.is_open() and a.mind != Person.Mind.DUTY, "at the door the report is delivered")

	# An unseen death ends a report.
	var b: Person = crowd.citizens[7]
	var rb := TempleReport.new(b, door)
	_clear_round(crowd, b.ground_pos, Crowd.DOOM_WITNESS + 1.0, [b])
	crowd._field.kill(b, &"doom")
	rb.on_killed(b)
	_run(s, [rb], DT * 2.0)
	t.check(rb.dead and not rb.delivered and not rb.is_open(), "a death nobody sees ends the report")

	# A seen death passes it on.
	var c: Person = crowd.citizens[11]
	var w: Person = crowd.citizens[12]
	var rc := TempleReport.new(c, door)
	_clear_round(crowd, c.ground_pos, Crowd.DOOM_WITNESS + 1.0, [c])
	w.ground_pos = c.ground_pos + Vector2(1.0, 0.0)
	crowd._field.kill(c, &"doom")
	rc.on_killed(c)
	_run(s, [rc], DT * 2.0)
	t.check(rc.carrier == w and rc.relays == 1 and rc.is_open() and w.mind == Person.Mind.DUTY,
		"a seen death passes the report to the witness, who runs on")

	# A whisper holds the carrier; once it wears off they run on.
	var d: Person = crowd.citizens[15]
	var rd := TempleReport.new(d, door)
	d.whisper(d.ground_pos + Vector2(1.0, 0.0), 1.0)
	_run(s, [rd], 0.5)
	t.check(d.mind == Person.Mind.WHISPERED and rd.is_open(), "a whisper holds the carrier")
	_run(s, [rd], 8.0)
	t.check(d.mind == Person.Mind.DUTY or rd.delivered, "once it wears off they run on (%s)" % Person.Mind.keys()[d.mind])

	# Review focus 3: two reports apart; one carrier killed in front of the other carrier.
	var e1: Person = crowd.citizens[20]
	var e2: Person = crowd.citizens[21]
	var r1 := TempleReport.new(e1, door)
	var r2 := TempleReport.new(e2, door)
	_clear_round(crowd, e1.ground_pos, Crowd.DOOM_WITNESS + 1.0, [e1])
	e2.ground_pos = e1.ground_pos + Vector2(1.0, 0.0)
	crowd._field.kill(e1, &"doom")
	r1.on_killed(e1)
	r2.on_killed(e1)
	_run(s, [r1, r2], DT * 2.0)
	t.check(r1.carrier == e2 and r2.carrier == e2 and r2.relays == 0, "the witness carries both, the second never relayed")
	e2.ground_pos = door + Vector2(0.3, 0.0)
	_run(s, [r1, r2], DT * 2.0)
	t.check(r1.delivered and r2.delivered, "and both arrive with them")
	_done(s)
```

Register it at the end of `SUITES`.

- [ ] **Step 2: Run the tests to verify they fail.** Expected: a Parse Error naming `Faith` or `TempleReport`.

- [ ] **Step 3: Faith on profiles.** In `src/game/crowd/citizen_profile.gd`, under `enum Role`, add:

```gdscript
## Where a citizen stands with the gods (v0.10, the campaign's Night 2): one of Halcyon's Faithful, who report the god
## at work; one of the grieving, who can be led to Mira's journal; or a Believer, who has read it.
enum Faith { NONE, FAITHFUL, GRIEVING, BELIEVER }
```

and under `var family := -1`:

```gdscript
var faith := Faith.NONE
```

- [ ] **Step 4: Write `TempleReport`.** Create `src/game/mission/temple_report.gd`:

```gdscript
class_name TempleReport
extends RefCounted
## A report of the god at work on its way to the Temple (v0.10): one of the Faithful runs (a duty) to the Temple's door,
## re-aimed every RETARGET; within REACH of it the report is delivered and the carrier goes back to their day. A carrier
## killed with nobody living near enough to see it (Crowd.DOOM_WITNESS) ends the report; a death that is seen passes
## it to the nearest witness, who runs on. Judged once a cast's other victims have fallen (Crowd._settle_doom()), as
## The Warning judges its messenger. A frightened, confused or whispered carrier drops the run and picks it up again
## once back on its feet; only a relay overrides a fright.

const REACH := 1.0
const RETARGET := 0.5
## Minds a carrier picks the run up again from.
const RESUMABLE := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.REGROUP]
## Minds a relay leaves alone: the god's own hold wears off first.
const HELD := [Person.Mind.CONFUSED, Person.Mind.WHISPERED]

var carrier: Person
var door := Vector2.INF
var delivered := false
## Ended by a death nobody saw.
var dead := false
var relays := 0
var _fell_at := Vector2.INF
var _retarget_in := 0.0


func _init(p: Person, temple_door: Vector2) -> void:
	carrier = p
	door = temple_door
	_send(true)


## Still on its way: neither delivered nor ended.
func is_open() -> bool:
	return not delivered and not dead


func step(delta: float, crowd: Crowd) -> void:
	if not is_open():
		return
	if _fell_at != Vector2.INF and crowd._doomed.is_empty():
		_judge(crowd)
		if not is_open():
			return
	if not _alive(carrier):
		return
	if carrier.ground_pos.distance_to(door) <= REACH:
		delivered = true
		if carrier.mind == Person.Mind.DUTY:
			carrier.leave_shelter(false)
		return
	_retarget_in -= delta
	if _retarget_in <= 0.0:
		_retarget_in = RETARGET
		_send(false)


func on_killed(e: DummyEnemy) -> void:
	if is_open() and e == carrier and _fell_at == Vector2.INF:
		_fell_at = e.ground_pos


func _judge(crowd: Crowd) -> void:
	var at := _fell_at
	_fell_at = Vector2.INF
	var witness := crowd.nearest_witness(at)
	if witness == null:
		dead = true
		return
	if witness != carrier:
		relays += 1
	carrier = witness
	_send(true)


## On the run: re-aimed only when it has stopped short. Off it: again once back on its feet, or at once for a relay
## unless the god holds the witness.
func _send(relay: bool) -> void:
	if not _alive(carrier):
		return
	if carrier.mind == Person.Mind.DUTY:
		if not carrier.has_goal() or carrier.anchor.distance_to(door) > 0.3:
			carrier.go_duty(door)
		return
	if carrier.mind in RESUMABLE or carrier.soldier or (relay and not carrier.mind in HELD):
		carrier.go_duty(door)


static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()
```

The second report's carrier after the shared death: `r2.on_killed(e1)` sets `_fell_at` only when `e1` is `r2`'s carrier, and it is not (e2 is). So `r2` keeps e2 with `relays == 0`. `r1` passes to e2 (`relays` 1). That matches the test's "the second never relayed".

- [ ] **Step 5: Run the tests to verify they pass.** Run Import, then Tests. Expected: `checks=N failures=0`. If the whisper case fails because `Person.whisper()` refuses (shake-off from an earlier test), pick another citizen index, and report it.

- [ ] **Step 6: Run Digest and crowd_check.** Expected: unchanged. The new profile field is not hashed.

- [ ] **Step 7: Commit.**

```bash
git add src/game/crowd/citizen_profile.gd src/game/mission/temple_report.gd src/game/mission/temple_report.gd.uid tests/test_temple_report.gd tests/test_temple_report.gd.uid tests/run_all.gd
git commit -m "feat: the Faithful and their report to the Temple (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 3: The Vigil's walk

**Files:**
- Create: `src/game/mission/vigil_route.gd`, `tests/test_vigil_route.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: `Person.go_duty()`, `Person.leave_shelter()`.
- Produces: `VigilRoute`:
  - `setup(points: PackedVector2Array, bearer_p: Person, acolyte_ps: Array[Person]) -> VigilRoute`, `start()`, `step(delta: float)`, `finish()`;
  - `var bearer: Person`, `var acolytes: Array[Person]`, `var route: PackedVector2Array`, `var leg: int`, `var active: bool`, `var finished: bool`;
  - `walkers() -> Array[Person]` (the living bearer and acolytes);
  - constants `ARRIVE := 0.6`, `TICK := 0.5`, `ACOLYTE_OFFSETS`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_vigil_route.gd`:

```gdscript
extends RefCounted
## v0.10 the Vigil's walk (VigilRoute): the flame-bearer walks his route point by point with two acolytes keeping beside
## him; a fright stops him, and he takes the route up where he left it; at the last point the walk is over and all three
## go back to their day. A dead bearer ends it.

const DT := 0.05


static func _crowd() -> Dictionary:
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
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd}


static func _done(s: Dictionary) -> void:
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


static func run(t) -> void:
	var s := _crowd()
	var crowd: Crowd = s.crowd
	var grid: WalkGrid = s.grid
	var bearer: Person = crowd.citizens[2]
	var acolytes: Array[Person] = [crowd.citizens[4], crowd.citizens[6]]
	var start := bearer.ground_pos
	var points := PackedVector2Array([grid.nearest_walkable(start + Vector2(2.0, 0.0)),
		grid.nearest_walkable(start + Vector2(4.0, 0.0))])
	var v := VigilRoute.new().setup(points, bearer, acolytes)
	t.check(not v.active and not v.finished and v.walkers().size() == 3, "a Vigil waits until it starts, three walking")
	v.start()
	t.check(v.active and v.leg == 0 and bearer.mind == Person.Mind.DUTY and bearer.anchor.distance_to(points[0]) < 0.01,
		"the bearer sets out for the first point")
	bearer.ground_pos = points[0]
	bearer._goal = Vector2.INF
	bearer._path = PackedVector2Array()
	for i in roundi(VigilRoute.TICK / DT) + 1:
		v.step(DT)
	t.check(v.leg == 1 and bearer.anchor.distance_to(points[1]) < 0.01, "at a point he goes on to the next")
	t.check(acolytes[0].mind == Person.Mind.DUTY and acolytes[0].anchor.distance_to(bearer.ground_pos) < 2.0,
		"the acolytes keep beside him")
	bearer.panic(bearer.ground_pos + Vector2(0.5, 0.0), 1.0)
	for i in roundi(VigilRoute.TICK / DT) + 1:
		v.step(DT)
	t.check(v.leg == 1 and bearer.mind != Person.Mind.DUTY, "a fright stops him where he is")
	bearer.mind = Person.Mind.CALM
	for i in roundi(VigilRoute.TICK / DT) + 1:
		v.step(DT)
	t.check(v.leg == 1 and bearer.mind == Person.Mind.DUTY and bearer.anchor.distance_to(points[1]) < 0.01,
		"back on his feet he takes the route up again")
	bearer.ground_pos = points[1]
	bearer._goal = Vector2.INF
	bearer._path = PackedVector2Array()
	for i in roundi(VigilRoute.TICK / DT) + 1:
		v.step(DT)
	t.check(v.finished and not v.active and bearer.mind != Person.Mind.DUTY and acolytes[1].mind != Person.Mind.DUTY,
		"at the last point the walk is over and all three go back to their day")

	var b2: Person = crowd.citizens[8]
	var v2 := VigilRoute.new().setup(points, b2, [] as Array[Person])
	v2.start()
	crowd._field.kill(b2, &"doom")
	for i in roundi(VigilRoute.TICK / DT) + 1:
		v2.step(DT)
	t.check(v2.finished and v2.walkers().is_empty(), "a dead bearer ends the Vigil")
	_done(s)
```

Register it at the end of `SUITES`.

- [ ] **Step 2: Run the tests to verify they fail.** Expected: a Parse Error naming `VigilRoute`.

- [ ] **Step 3: Write `VigilRoute`.** Create `src/game/mission/vigil_route.gd`:

```gdscript
class_name VigilRoute
extends RefCounted
## The Vigil (v0.10, spec §4.1): a priest, the flame-bearer, walks a route point by point, two acolytes keeping beside
## him. A fright stops him; once on his feet again he takes the route up where he left it. At the last point the walk is
## over and all three go back to their day; a dead bearer ends it at once. Mira's House walks it past her door; M3 and
## M4 walk it round Halcyon's six wayside shrines.

## How near a point counts as reached, and seconds between looks at the walk.
const ARRIVE := 0.6
const TICK := 0.5
## Where each acolyte keeps beside the bearer (ground units), and how far off their place they may drift.
const ACOLYTE_OFFSETS := [Vector2(-0.7, 0.4), Vector2(0.7, 0.4)]
const ACOLYTE_DRIFT := 0.5
## Minds the bearer takes the route up again from.
const RESUMABLE := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.REGROUP]

var bearer: Person
var acolytes: Array[Person] = []
var route := PackedVector2Array()
var leg := 0
var active := false
var finished := false
var _tick := 0.0


func setup(points: PackedVector2Array, bearer_p: Person, acolyte_ps: Array[Person]) -> VigilRoute:
	route = points
	bearer = bearer_p
	acolytes = acolyte_ps
	return self


func start() -> void:
	if route.is_empty() or not _alive(bearer):
		finish()
		return
	active = true
	leg = 0
	_tick = TICK
	bearer.go_duty(route[0])
	_keep_acolytes()


## The living bearer and acolytes.
func walkers() -> Array[Person]:
	var out: Array[Person] = []
	for p in [bearer] + acolytes:
		if _alive(p):
			out.append(p)
	return out


func step(delta: float) -> void:
	if not active:
		return
	if not _alive(bearer):
		finish()
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = TICK
	if bearer.mind != Person.Mind.DUTY:
		if bearer.mind in RESUMABLE:
			bearer.go_duty(route[leg])
		return
	if bearer.ground_pos.distance_to(route[leg]) <= ARRIVE or not bearer.has_goal():
		if bearer.ground_pos.distance_to(route[leg]) <= ARRIVE:
			leg += 1
			if leg >= route.size():
				finish()
				return
		bearer.go_duty(route[leg])
	_keep_acolytes()


## The walk is over: everyone still on it goes back to their day.
func finish() -> void:
	active = false
	finished = true
	for p in walkers():
		if p.mind == Person.Mind.DUTY:
			p.leave_shelter(false)


func _keep_acolytes() -> void:
	for i in acolytes.size():
		var a := acolytes[i]
		if not _alive(a) or not (a.mind == Person.Mind.DUTY or a.mind in RESUMABLE):
			continue
		var place := bearer.ground_pos + (ACOLYTE_OFFSETS[i % ACOLYTE_OFFSETS.size()] as Vector2)
		if a.mind != Person.Mind.DUTY or a.anchor.distance_to(place) > ACOLYTE_DRIFT:
			a.go_duty(place)


static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()
```

- [ ] **Step 4: Run the tests to verify they pass.** Expected: `checks=N failures=0`.
- [ ] **Step 5: Commit.**

```bash
git add src/game/mission/vigil_route.gd src/game/mission/vigil_route.gd.uid tests/test_vigil_route.gd tests/test_vigil_route.gd.uid tests/run_all.gd
git commit -m "feat: the Vigil's walk: the flame-bearer and his acolytes (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 4: Mira's House — the door, the reading and the Believers

**Files:**
- Create: `src/game/mission/miras_house_director.gd`, `src/game/mission/believers_objective.gd`, `src/game/mission/pure_faith_objective.gd`, `src/game/mission/journal_objective.gd`, `tests/test_miras_house.gd`
- Modify: `src/game/mission/mission_book.gd`, `tests/test_mission_book.gd`, `tests/run_all.gd`

**Interfaces:**
- Consumes: `GazeMeter`, `GazeObjective` (Task 1); `CitizenProfile.Faith`, `TempleReport` (Task 2).
- Produces:
  - `MirasHouseDirector extends MissionDirector`:
    - `house: Structure`, `door: Vector2`, `temple_door: Vector2`;
    - `grieving`, `faithful`, `believers: Array[Person]`; `reports: Array[TempleReport]`; `venn: Person`; `journal: Person`; `burning: bool`; `roof_fallen: bool`;
    - `believers_outside() -> int`, `inside() -> Array[Person]`, `faithful_seeing(at: Vector2, reach: float) -> Person`;
    - `marks()`, `marker()`, `report()`;
    - constants as in Step 3. Task 5 adds the events.
  - `BelieversObjective` (`NEED := 5`; reason `believers`, or `few` when it fails), `PureFaithObjective`, `JournalObjective`.
  - `MissionBook.miras_house()`: the real mission (clock 150, director, objectives `[GazeObjective, BelieversObjective]`, bonuses `[PureFaithObjective, JournalObjective]`, default loadout `whisper, wisp, discord`).

- [ ] **Step 1: Write the failing test.** Create `tests/test_miras_house.gd`:

```gdscript
extends RefCounted
## v0.10 Mira's House (MirasHouseDirector): ten grieving near her door, Halcyon's Faithful about the town; a grieving
## citizen whispered or lured to the door goes in, reads for 10 s and comes out a Believer; a Faithful who sees someone
## go in turns them away and reports, one who sees a Believer come out reports; a report delivered, a seen death or the
## bell fills the Gaze; five Believers out at dawn win.

const DT := 0.05


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
	var def := MissionBook.miras_house()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := (def.director.new() as MissionDirector).setup(rules, crowd, town, null) as MirasHouseDirector
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


## Every Faithful moved well away from `at` (nobody of the Faith can see there).
static func _blind(d: MirasHouseDirector, at: Vector2) -> void:
	for f in d.faithful:
		if is_instance_valid(f) and f.ground_pos.distance_to(at) <= MirasHouseDirector.SIGHT + 1.0:
			f.ground_pos = at + Vector2(MirasHouseDirector.SIGHT + 8.0, 0.0)


## Grieving `g` whispered to the door and standing there.
static func _bring(d: MirasHouseDirector, g: Person) -> void:
	g.whisper(d.door, 8.0)
	_arrive(g, d.door)


static func run(t) -> void:
	_cast(t)
	_reading(t)
	_seen(t)
	_gaze(t)
	_ending(t)


static func _cast(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	t.check(d.house != null and d.house.kind == Structure.Kind.HOUSE and d.door != Vector2.INF
		and d.door.distance_to(d.house.center()) < 3.0, "Mira's house is a west-quarter house with a door")
	t.check(d.grieving.size() == MirasHouseDirector.GRIEVING and d.gaze != null and d.gaze.value == 0.0,
		"ten grieving, and the Gaze at 0")
	var faithful_ok := d.faithful.size() >= MirasHouseDirector.FAITHFUL
	for f in d.faithful:
		faithful_ok = faithful_ok and f.profile.faith == CitizenProfile.Faith.FAITHFUL and not d.grieving.has(f)
	t.check(faithful_ok, "at least twenty Faithful, none of them grieving (%d)" % d.faithful.size())
	t.check(d.venn != null and d.faithful.has(d.venn), "the Inquisitor is one of the Faithful")
	t.check(d.marks().size() == MirasHouseDirector.GRIEVING, "the HUD marks the ten grieving")
	t.check(d.timeline != null and d.timeline.upcoming(4).size() >= 3, "the night's windows are on the strip")
	_done(s)


static func _reading(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	var g := d.grieving[0]
	_blind(d, d.door)
	_bring(d, g)
	_run(s, DT * 2.0)
	t.check(g.inside and not g.visible and d.inside().has(g), "a whispered grieving citizen at the door goes in")
	_run(s, MirasHouseDirector.READ_SECONDS - 1.0)
	t.check(g.inside and d.believers.is_empty(), "still reading after 9 s")
	_blind(d, d.door)
	_run(s, 1.5)
	t.check(not g.inside and g.visible and d.believers.has(g) and g.profile.faith == CitizenProfile.Faith.BELIEVER
		and d.journal == g and d.believers_outside() == 1, "after 10 s they come out a Believer, carrying the journal")
	t.check(d.reports.is_empty(), "nobody of the Faith saw")
	var marked_believer := false
	for m: Array in d.marks():
		marked_believer = marked_believer or ((m[0] as Vector2) == g.ground_pos and (m[1] as Color) == MirasHouseDirector.MARK_BELIEVER)
	t.check(marked_believer, "the Believer wears the ember mark")

	# Review focus 5: a grieving citizen walking past on their own day does not go in.
	var h := d.grieving[1]
	_blind(d, d.door)
	_arrive(h, d.door)
	h.mind = Person.Mind.CALM
	_run(s, DT * 2.0)
	t.check(not h.inside and d.reports.is_empty(), "a grieving citizen passing the door on their own day stays out")
	_done(s)


static func _seen(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	var g := d.grieving[0]
	_blind(d, d.door)
	var f := d.faithful[0]
	f.ground_pos = d.door + Vector2(2.0, 0.0)
	_bring(d, g)
	_run(s, DT * 2.0)
	t.check(not g.inside and d.reports.size() == 1 and d.reports[0].carrier == f,
		"a Faithful who sees someone go in turns them away and runs to report")
	_run(s, 1.0)
	t.check(not g.inside and d.reports.size() == 1, "the turned-away reader does not slip in while still at the door")

	# A Faithful held by Discord sees nothing.
	var s2 := _setup()
	var d2: MirasHouseDirector = s2.d
	var g2 := d2.grieving[0]
	_blind(d2, d2.door)
	var f2 := d2.faithful[0]
	f2.ground_pos = d2.door + Vector2(2.0, 0.0)
	f2.confuse(10.0)
	_bring(d2, g2)
	_run(s2, DT * 2.0)
	t.check(g2.inside and d2.reports.is_empty(), "a Faithful confused by Discord sees nothing")
	# Seen coming out.
	_run(s2, MirasHouseDirector.READ_SECONDS - 0.5)
	var f3 := d2.faithful[1]
	f3.ground_pos = d2.door + Vector2(-2.0, 0.0)
	_run(s2, 1.0)
	t.check(d2.believers.has(g2) and d2.reports.size() == 1, "a Believer seen coming out is reported, but believes")
	_done(s)
	_done(s2)


static func _gaze(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	var rules: Rules = s.rules
	var f := d.faithful[0]
	f.ground_pos = d.door + Vector2(2.0, 0.0)
	_bring(d, d.grieving[0])
	_run(s, DT * 2.0)
	t.check(d.reports.size() == 1, "a report is on its way")
	_arrive(d.reports[0].carrier, d.temple_door)
	_run(s, DT * 3.0)
	t.check(d.gaze.is_full() and rules.finished and not rules.won and rules.over_reason == "gaze",
		"a report reaching the Temple fills the Gaze, and the night is lost (%s)" % rules.over_reason)
	_done(s)

	# A seen death adds 10.
	var s2 := _setup()
	var d2: MirasHouseDirector = s2.d
	var victim := d2.faithful[3]
	var near := d2.faithful[4]
	near.ground_pos = victim.ground_pos + Vector2(1.0, 0.0)
	(s2.crowd as Crowd)._field.kill(victim, &"doom")
	_run(s2, DT * 3.0)
	t.near(d2.gaze.value, GazeMeter.SEEN_DEATH, 0.001, "a seen death adds 10 to the Gaze")
	_done(s2)

	# Review focus 4: the bell, rung by the town's own alarm, fills it.
	var s3 := _setup()
	var d3: MirasHouseDirector = s3.d
	var crowd3: Crowd = s3.crowd
	if crowd3.bell != null:
		crowd3.bell.state = BellNetwork.State.RUNG
	_run(s3, DT * 2.0)
	t.check(crowd3.bell == null or ((s3.rules as Rules).finished and (s3.rules as Rules).over_reason == "gaze"),
		"the bell filling the Gaze loses the night")
	_done(s3)


static func _ending(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	var rules: Rules = s.rules
	for i in BelieversObjective.NEED:
		var g := d.grieving[i]
		g.profile.faith = CitizenProfile.Faith.BELIEVER
		d.believers.append(g)
	d.journal = d.grieving[0]
	rules.time_left = DT
	_run(s, DT * 2.0)
	t.check(rules.finished and rules.won and rules.over_reason == "believers", "five Believers out at dawn win the night")
	var res := rules.result()
	t.check(int(res.get("believers", -1)) == 5, "the results count them")
	var earned := []
	for b: Dictionary in res.bonuses:
		earned.append(bool(b.earned))
	t.check(earned == [true, true], "no death and the journal out: both bonuses (%s)" % [earned])
	_done(s)

	var s2 := _setup()
	var d2: MirasHouseDirector = s2.d
	for i in BelieversObjective.NEED - 1:
		d2.believers.append(d2.grieving[i])
	(s2.rules as Rules).time_left = DT
	_run(s2, DT * 2.0)
	t.check((s2.rules as Rules).finished and not (s2.rules as Rules).won and (s2.rules as Rules).over_reason == "few",
		"four at dawn lose it")
	_done(s2)
```

Register it at the end of `SUITES`. In `tests/test_mission_book.gd`, replace the placeholder check on Mira's House (the `mh` block: Tier 2, director null, `held`) with:

```gdscript
	var mh := MissionBook.miras_house()
	var mh_reasons := []
	for o in mh.objectives():
		mh_reasons.append(o.reason)
	t.check(mh.tier == 2 and mh.profile == "unaware" and not mh.scored and mh.director == MirasHouseDirector
		and mh_reasons == ["gaze", "believers"] and is_equal_approx(mh.clock, 150.0),
		"Mira's House is Tier 2, Unaware, on 2:30, lost to the Gaze, won by Believers (%s)" % [mh_reasons])
	var vf := MissionBook.vigil_flame()
	var held := []
	for o in vf.objectives():
		held.append(o.reason)
	t.check(vf.director == null and held == ["held"], "the Vigil Flame is still a placeholder held until dawn")
```

Keep the existing pool check (`Array(mh.powers()) == MissionBook.VIGIL_POOL ...`).

- [ ] **Step 2: Run the tests to verify they fail.** Expected: a Parse Error naming `MirasHouseDirector`.

- [ ] **Step 3: Write the objectives.** Create `src/game/mission/believers_objective.gd`:

```gdscript
class_name BelieversObjective
extends Objective
## Mira's House (v0.10): at dawn, NEED Believers alive and out of the house win the night ("believers"); fewer lose it
## ("few").

const NEED := 5


func _init() -> void:
	label = "Believers"
	reason = "believers"


func check(rules: Rules) -> Status:
	var d := rules.director as MirasHouseDirector
	if d == null or rules.time_left > 0.0:
		return Status.PENDING
	if d.believers_outside() >= NEED:
		reason = "believers"
		return Status.DONE
	reason = "few"
	return Status.FAILED


func hud_text(rules: Rules) -> String:
	var d := rules.director as MirasHouseDirector
	return "Believers %d / %d" % [d.believers_outside() if d != null else 0, NEED]
```

Create `src/game/mission/pure_faith_objective.gd`:

```gdscript
class_name PureFaithObjective
extends Objective
## Mira's House's bonus (v0.10): nobody dies tonight.


func _init() -> void:
	label = "Pure faith"
	reason = "pure"


func check(rules: Rules) -> Status:
	return Status.FAILED if rules.citizens_killed_this_act() + rules.soldiers_killed_this_act() > 0 else Status.PENDING
```

Create `src/game/mission/journal_objective.gd`:

```gdscript
class_name JournalObjective
extends Objective
## Mira's House's bonus (v0.10): Cael's journal goes with the last Believer to finish reading it, and is saved when they
## are alive and out of the house at dawn.


func _init() -> void:
	label = "The journal"
	reason = "journal"


func check(rules: Rules) -> Status:
	var d := rules.director as MirasHouseDirector
	if d == null:
		return Status.PENDING
	var carrier := d.journal
	if carrier == null:
		return Status.FAILED if rules.time_left <= 0.0 else Status.PENDING
	if not (is_instance_valid(carrier) and carrier.is_alive()):
		return Status.FAILED
	if rules.time_left <= 0.0:
		return Status.DONE if not carrier.inside else Status.FAILED
	return Status.PENDING
```

- [ ] **Step 4: Write the director's core.** Create `src/game/mission/miras_house_director.gd`:

```gdscript
class_name MirasHouseDirector
extends MissionDirector
## Mira's House (v0.10 M2, the Faith path's Night 2): Mira's house in the west quarter has been shut since the burning;
## inside are her shrine and Cael's journal. A grieving citizen brought to its door -- by Mind Whisper, or a
## Will-o'-Wisp's lure -- goes in, reads for READ_SECONDS and comes out a Believer. Halcyon's Faithful must not see it: a
## Faithful who sees someone go in turns them away, one who sees a Believer come out lets them go; either runs to the
## Temple to report it (TempleReport), and a report reaching the Temple fills Halcyon's Gaze. A death someone sees adds to
## it; the bell fills it. A Faithful held by Discord or a whisper sees nothing. Task 5's windows: the Inquisitor's search,
## a Believer crying out, the Vigil passing the door, and the priests burning the house.

## Where Mira lived: her house is the one nearest this point (ground units).
const MIRA_SPOT := Vector2(-12.0, 2.0)
## How many grieving there are, and how many Faithful besides the clergy.
const GRIEVING := 10
const FAITHFUL := 20
## How near the door a person must stand to go in; how long a reading takes.
const DOOR_REACH := 0.7
const READ_SECONDS := 10.0
## How far a Faithful sees someone at the door, and hears a Believer crying out.
const SIGHT := 4.0
const HEAR := 6.0
## The marks over the grieving and the Believers.
const MARK_GRIEVING := Color(0.85, 0.75, 0.45, 0.8)
const MARK_BELIEVER := Color("ff9a3a")
## Minds a Faithful does not see from: the god's own holds.
const BLIND := [Person.Mind.CONFUSED, Person.Mind.WHISPERED]
## Minds a person going in may be in: brought by the god (a whisper, or a lure's watching mind).
const BROUGHT := [Person.Mind.WHISPERED, Person.Mind.OBSERVE]

var house: Structure
var door := Vector2.INF
var temple_door := Vector2.INF
## The ten grieving, Believers among them once they have read.
var grieving: Array[Person] = []
var faithful: Array[Person] = []
var believers: Array[Person] = []
var reports: Array[TempleReport] = []
var reports_started := 0
var venn: Person
## The last Believer to finish reading: the journal goes with them.
var journal: Person
var burning := false
var roof_fallen := false
## Person -> seconds of reading left, for everyone inside.
var _reading := {}
## Persons turned away at the door, until they step away from it.
var _turned := {}
## Where people died this step, judged once the crowd has judged its own doomed.
var _deaths: Array[Vector2] = []


func _begin() -> void:
	gaze = GazeMeter.new()
	house = _find_house()
	door = _door_of(house) if house != null else _walkable(MIRA_SPOT)
	temple_door = _walkable(Vector2(TownLayout.TEMPLE.get_center().x, TownLayout.TEMPLE.end.y + 0.6))
	_choose_people()
	crowd._field.enemy_killed.connect(_on_killed)
	timeline = EventTimeline.new()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	_add_events()
	rules.banner.emit("LEAD THE GRIEVING TO MIRA'S HOUSE")


## Task 5 fills this in with the night's windows.
func _add_events() -> void:
	pass


func _find_house() -> Structure:
	var best: Structure = null
	for s: Structure in town._built:
		if s.kind != Structure.Kind.HOUSE or s.role != &"house" or s.destroyed:
			continue
		if best == null or s.center().distance_to(MIRA_SPOT) < best.center().distance_to(MIRA_SPOT):
			best = s
	return best


## A house's door: free ground just off its front (its +y face).
func _door_of(s: Structure) -> Vector2:
	return _walkable(s.center() + Vector2(0.0, s.footprint.size.y * 0.5 + 0.5))


func _walkable(g: Vector2) -> Vector2:
	var w := crowd._grid.nearest_walkable(g) if crowd._grid != null else g
	return w if w != Vector2.INF else g


## The ten lay citizens nearest the door grieve; the clergy and FAITHFUL others, spread through the rest, are Halcyon's
## Faithful; the cleric nearest the Temple is the Inquisitor.
func _choose_people() -> void:
	var keeper: Person = crowd.bell.keeper if crowd.bell != null else null
	var lay: Array[Person] = []
	var clergy: Array[Person] = []
	for p in crowd.citizens:
		if not _alive(p) or p.profile == null or p.inside or p == keeper:
			continue
		if p.profile.role == CitizenProfile.Role.CLERGY:
			clergy.append(p)
		elif not p.profile.role in [CitizenProfile.Role.ENGINEER, CitizenProfile.Role.BELLKEEPER]:
			lay.append(p)
	lay.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_to(door) < b.ground_pos.distance_to(door))
	for i in mini(GRIEVING, lay.size()):
		lay[i].profile.faith = CitizenProfile.Faith.GRIEVING
		grieving.append(lay[i])
	for p in clergy:
		_make_faithful(p)
	var rest := lay.slice(GRIEVING)
	if not rest.is_empty():
		var stride := maxi(1, rest.size() / FAITHFUL)
		var i := stride / 2
		var added := 0
		while i < rest.size() and added < FAITHFUL:
			_make_faithful(rest[i])
			added += 1
			i += stride
	var pool := clergy if not clergy.is_empty() else faithful
	for p in pool:
		if venn == null or p.ground_pos.distance_to(temple_door) < venn.ground_pos.distance_to(temple_door):
			venn = p


func _make_faithful(p: Person) -> void:
	p.profile.faith = CitizenProfile.Faith.FAITHFUL
	faithful.append(p)


func step(delta: float) -> void:
	timeline.step(delta)
	_judge_deaths()
	_doors()
	_read(delta)
	for r in reports:
		r.step(delta, crowd)
		if r.delivered:
			gaze.fill()
	reports.assign(reports.filter(func(r: TempleReport) -> bool: return r.is_open()))
	_step_events(delta)
	if crowd.bell != null and crowd.bell.state == BellNetwork.State.RUNG:
		gaze.fill()
	if rules.time_left <= 0.0 and not roof_fallen:
		_roof()


## Task 5's windows, stepped each frame.
func _step_events(_delta: float) -> void:
	pass


## A death someone saw adds to the Gaze, judged once the cast's other victims are dead too.
func _judge_deaths() -> void:
	if _deaths.is_empty() or not crowd._doomed.is_empty():
		return
	for at in _deaths:
		if crowd.nearest_witness(at) != null:
			gaze.seen_death()
	_deaths.clear()


func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	_deaths.append(e.ground_pos)
	for r in reports:
		r.on_killed(e)


## The grieving the god has brought to the door go in, unless a Faithful sees: then they are turned away and reported.
## Once the house burns, nobody goes in.
func _doors() -> void:
	if burning or roof_fallen:
		return
	for p in grieving:
		if not _alive(p) or p.inside or _reading.has(p):
			continue
		if p.ground_pos.distance_to(door) > DOOR_REACH:
			_turned.erase(p)
			continue
		if _turned.has(p) or not p.mind in BROUGHT:
			continue
		var seer := faithful_seeing(door, SIGHT)
		if seer != null:
			_turned[p] = true
			_report(seer)
			continue
		_enter(p)


func _enter(p: Person) -> void:
	p.inside = true
	p.visible = false
	p.ground_pos = house.center() if house != null else door
	crowd._field.remove(p)
	_reading[p] = READ_SECONDS
	_entered(p)


## Task 5: someone went in (the crying Believer whispered back resolves the cry).
func _entered(_p: Person) -> void:
	pass


func _read(delta: float) -> void:
	for p: Person in _reading.keys():
		if not is_instance_valid(p):
			_reading.erase(p)
			continue
		_reading[p] = float(_reading[p]) - delta
		if float(_reading[p]) > 0.0:
			continue
		_reading.erase(p)
		if not believers.has(p):
			believers.append(p)
			p.profile.faith = CitizenProfile.Faith.BELIEVER
			journal = p
			rules.banner.emit("%d BELIEVE" % believers.size())
		_exit(p)


## Out at the door, back to their day -- and reported if a Faithful sees.
func _exit(p: Person) -> void:
	p.inside = false
	p.visible = true
	p.ground_pos = door
	crowd._field.add(p)
	p.leave_shelter(false)
	var seer := faithful_seeing(door, SIGHT)
	if seer != null:
		_report(seer)


## A Faithful runs to the Temple, unless already carrying a report.
func _report(seer: Person) -> void:
	for r in reports:
		if r.carrier == seer:
			return
	reports.append(TempleReport.new(seer, temple_door))
	reports_started += 1
	rules.banner.emit("A FAITHFUL RUNS TO THE TEMPLE")


## Dawn: the roof falls on whoever is still inside, and the house is gone.
func _roof() -> void:
	roof_fallen = true
	for p: Person in _reading.keys():
		if not is_instance_valid(p):
			continue
		p.inside = false
		p.visible = true
		p.ground_pos = door
		crowd._field.add(p)
		crowd._field.kill(p, &"fire")
	_reading.clear()
	if house != null and not house.destroyed:
		house.destroy(house.center(), &"fire")


## The nearest Faithful within `reach` of `at` who is out in the open, alive, and not held by the god; else null.
func faithful_seeing(at: Vector2, reach: float) -> Person:
	var best: Person = null
	for f in faithful:
		if not _alive(f) or f.inside or f.mind in BLIND:
			continue
		var d := f.ground_pos.distance_to(at)
		if d <= reach and (best == null or d < best.ground_pos.distance_to(at)):
			best = f
	return best


func believers_outside() -> int:
	var n := 0
	for p in believers:
		n += 1 if _alive(p) and not p.inside else 0
	return n


func inside() -> Array[Person]:
	var out: Array[Person] = []
	for p: Person in _reading.keys():
		out.append(p)
	return out


func marks() -> Array:
	var out := []
	for p in grieving:
		if _alive(p) and not p.inside:
			out.append([p.ground_pos, MARK_BELIEVER if believers.has(p) else MARK_GRIEVING])
	return out


func report() -> Dictionary:
	return {"believers": believers_outside(), "reports": reports_started}


func teardown() -> void:
	if is_instance_valid(crowd) and crowd._field != null and crowd._field.enemy_killed.is_connected(_on_killed):
		crowd._field.enemy_killed.disconnect(_on_killed)
	timeline = null


static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()
```

- [ ] **Step 5: The mission.** In `src/game/mission/mission_book.gd`, replace `miras_house()` with:

```gdscript
## Night 2 of the campaign, the Faith path (v0.10 M2): lead five of the grieving to Mira's journal unseen, before dawn
## (MirasHouseDirector).
static func miras_house() -> MissionDef:
	var m := _vigil(MIRAS_HOUSE, "Mira's House", PackedStringArray(["Her journal waits in a shuttered house.",
		"Lead the grieving to it unseen."]), PackedStringArray(VIGIL_POOL))
	m.goal = "Lead five of the grieving to Mira's journal, unseen, before dawn"
	m.goal_label = "Five believe"
	m.lose = "The Lantern looks, or fewer than five believe by dawn"
	m.clock = 150.0
	m.camera_at = MirasHouseDirector.MIRA_SPOT
	m.intro_from = MirasHouseDirector.MIRA_SPOT + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["whisper", "wisp", "discord"])
	m.director = MirasHouseDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [GazeObjective.new(), BelieversObjective.new()]
		return out
	m.make_bonuses = func() -> Array[Objective]:
		var out: Array[Objective] = [PureFaithObjective.new(), JournalObjective.new()]
		return out
	return m
```

- [ ] **Step 6: Run the tests to verify they pass.** Run Import, then Tests. Expected: `checks=N failures=0`.
  - If the bell case cannot set `crowd.bell.state` directly (for example, a setter refuses), ring it through `BellNetwork`'s own API instead (read `src/game/crowd/bell_network.gd`), and report it.
  - If `_cast`'s door check fails because the house's front is not its +y face, choose the door with `crowd.shelters._door(house, house.center() + Vector2.DOWN)` instead (`ShelterManager._door`), and report it.
- [ ] **Step 7: Run Digest, crowd_check and FLOW.** Expected: unchanged. FLOW plays the Vigil Flame placeholder, not Mira's House.
- [ ] **Step 8: Commit.**

```bash
git add src/game/mission/miras_house_director.gd src/game/mission/miras_house_director.gd.uid src/game/mission/believers_objective.gd src/game/mission/believers_objective.gd.uid src/game/mission/pure_faith_objective.gd src/game/mission/pure_faith_objective.gd.uid src/game/mission/journal_objective.gd src/game/mission/journal_objective.gd.uid src/game/mission/mission_book.gd tests/test_miras_house.gd tests/test_miras_house.gd.uid tests/test_mission_book.gd tests/run_all.gd
git commit -m "feat: Mira's House: the door, the reading, the Believers and the Gaze (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 5: Mira's House — the night's windows

**Files:**
- Modify: `src/game/mission/miras_house_director.gd`
- Test: `tests/test_miras_house.gd`

**Interfaces:**
- Consumes: Task 4's director; `VigilRoute` (Task 3).
- Produces, on `MirasHouseDirector`:
  - constants `VENN_AT := 40.0`, `VENN_STOP := 3.0`, `VENN_REACH := 1.0`, `VENN_HOUSES := 6`, `SHOUT_AT := 75.0`, `SHOUT_SECONDS := 15.0`, `SHOUT_OFF := Vector2(0.0, 3.0)`, `VIGIL_AT := 105.0`, `VIGIL_SECONDS := 30.0`, `LINE_SPOTS`, `FIRE_AT := 120.0`, `FIRE_LEVEL := 0.6`;
  - `var vigil: VigilRoute`, `var liners: Array[Person]`, `var shouter: Person`, `var venn_searching: bool`;
  - `marker()` (the shouter).

- [ ] **Step 1: Write the failing tests.** In `tests/test_miras_house.gd`, add `_events(t)` and `_focus(t)` to `run()` after `_ending(t)`, and add:

```gdscript
static func _events(t) -> void:
	# 0:40 -- the Inquisitor searches; at Mira's door with someone inside, she reports at once.
	var s := _setup()
	var d: MirasHouseDirector = s.d
	_run(s, MirasHouseDirector.VENN_AT + DT)
	t.check(d.venn_searching and d.venn.mind == Person.Mind.DUTY, "at 0:40 the Inquisitor starts her search")
	_blind(d, d.door)
	_bring(d, d.grieving[0])
	_run(s, DT * 2.0)
	t.check(d.grieving[0].inside, "someone is inside")
	d._venn_i = d._venn_houses.size() - 1
	_arrive(d.venn, d.door)
	d.venn.go_duty(d.door)
	_arrive(d.venn, d.door)
	_run(s, DT * 2.0)
	t.check(d.reports.size() == 1 and d.reports[0].carrier == d.venn and not d.venn_searching,
		"at Mira's door with someone inside, the Inquisitor reports")
	_done(s)

	# 1:15 -- a Believer cries out; whispered back in, no report.
	var s2 := _setup()
	var d2: MirasHouseDirector = s2.d
	var b := d2.grieving[0]
	b.profile.faith = CitizenProfile.Faith.BELIEVER
	d2.believers.append(b)
	_run(s2, MirasHouseDirector.SHOUT_AT + DT)
	t.check(d2.shouter == b and b.mind == Person.Mind.DUTY and d2.marker() == b.ground_pos,
		"at 1:15 the newest Believer runs out crying, and the HUD marks them")
	_blind(d2, d2.door)
	_bring(d2, b)
	_run(s2, DT * 2.0)
	t.check(b.inside and d2.shouter == null, "whispered back into the house, the cry is over")
	_run(s2, 5.0)
	t.check(d2.reports.is_empty(), "and nobody reports the cry (still reading inside)")
	_done(s2)

	# ... and left crying with a Faithful in earshot: a report.
	var s3 := _setup()
	var d3: MirasHouseDirector = s3.d
	var b3 := d3.grieving[0]
	d3.believers.append(b3)
	_run(s3, MirasHouseDirector.SHOUT_AT + DT)
	_run(s3, MirasHouseDirector.SHOUT_SECONDS - DT * 4.0)
	var f3 := d3.faithful[2]
	f3.ground_pos = b3.ground_pos + Vector2(3.0, 0.0)
	f3.mind = Person.Mind.CALM
	_run(s3, DT * 8.0)
	t.check(d3.shouter == null and d3.reports.size() == 1, "a cry left 15 s with a Faithful in earshot is reported")
	_done(s3)

	# 1:45 -- the Vigil passes; liners stand by the door for 30 s.
	var s4 := _setup()
	var d4: MirasHouseDirector = s4.d
	_run(s4, MirasHouseDirector.VIGIL_AT + DT)
	t.check(d4.vigil != null and d4.vigil.active and d4.liners.size() > 0, "at 1:45 the Vigil sets out and Faithful line the street")
	var lined := true
	for f in d4.liners:
		lined = lined and f.mind == Person.Mind.DUTY and f.anchor.distance_to(d4.door) <= MirasHouseDirector.SIGHT
	t.check(lined, "each liner stands within sight of the door")
	_run(s4, MirasHouseDirector.VIGIL_SECONDS)
	t.check(d4.liners.is_empty(), "after 30 s the liners go back to their day")
	_done(s4)

	# 2:00 -- the house burns: everyone inside runs out, unconverted; nobody goes in; at dawn the roof falls.
	var s5 := _setup()
	var d5: MirasHouseDirector = s5.d
	_run(s5, MirasHouseDirector.FIRE_AT - 3.0)
	_blind(d5, d5.door)
	var g5 := d5.grieving[0]
	_bring(d5, g5)
	_run(s5, DT * 2.0)
	t.check(g5.inside, "a reader goes in at 1:57")
	_run(s5, 3.0)
	t.check(d5.burning and not g5.inside and not d5.believers.has(g5), "at 2:00 the fire drives them out, unread")
	_blind(d5, d5.door)
	_bring(d5, d5.grieving[1])
	_run(s5, DT * 2.0)
	t.check(not d5.grieving[1].inside, "nobody goes into a burning house")
	(s5.rules as Rules).time_left = DT
	_run(s5, DT * 2.0)
	t.check(d5.roof_fallen and d5.house.destroyed, "at dawn the roof falls")
	_done(s5)


## Review focus 1 and 2: the people an event needs are gone; the house falls early with people inside.
static func _focus(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	(s.crowd as Crowd)._field.kill(d.venn, &"doom")
	_run(s, MirasHouseDirector.SHOUT_AT + DT)
	t.check(not d.venn_searching and d.shouter == null and d.reports.is_empty(),
		"a dead Inquisitor never searches, and with no Believer out nobody cries")
	_run(s, MirasHouseDirector.VIGIL_AT - MirasHouseDirector.SHOUT_AT)
	var none_dead := true
	for f in d.liners:
		none_dead = none_dead and f.is_alive()
	t.check(none_dead, "no dead Faithful lines the street")
	_done(s)

	var s2 := _setup()
	var d2: MirasHouseDirector = s2.d
	_blind(d2, d2.door)
	_bring(d2, d2.grieving[0])
	_run(s2, DT * 2.0)
	d2.house.destroy(d2.house.center(), &"lightning")
	_run(s2, DT * 2.0)
	t.check(not d2.grieving[0].inside and d2.grieving[0].visible and d2.inside().is_empty(),
		"a house destroyed early lets everyone inside out at the door")
	_blind(d2, d2.door)
	_bring(d2, d2.grieving[1])
	_run(s2, DT * 2.0)
	t.check(not d2.grieving[1].inside, "and nobody goes into its ruins")
	(s2.rules as Rules).time_left = DT
	_run(s2, DT * 2.0)
	t.check(d2.roof_fallen, "dawn passes over the ruins quietly")
	_done(s2)
```

- [ ] **Step 2: Run the tests to verify they fail.** Expected: a Parse Error naming `VENN_AT`, `venn_searching` or `vigil`.

- [ ] **Step 3: The events.** In `src/game/mission/miras_house_director.gd`:
  - Add the constants under `BROUGHT`:

```gdscript
## 0:40 -- the Inquisitor searches the west quarter house by house, ending at Mira's: she stops VENN_STOP seconds at each
## of the VENN_HOUSES houses nearest the door (farthest first), and at Mira's, with anyone inside, she reports at once.
const VENN_AT := 40.0
const VENN_STOP := 3.0
const VENN_REACH := 1.0
const VENN_HOUSES := 6
## 1:15 -- the newest Believer out runs into the street crying (SHOUT_OFF from the door); left SHOUT_SECONDS with a
## Faithful within HEAR, it is reported.
const SHOUT_AT := 75.0
const SHOUT_SECONDS := 15.0
const SHOUT_OFF := Vector2(0.0, 3.0)
## 1:45 -- the Vigil passes the door, and Faithful line the street by it for VIGIL_SECONDS (offsets from the door).
const VIGIL_AT := 105.0
const VIGIL_SECONDS := 30.0
const LINE_SPOTS := [Vector2(-1.5, 2.0), Vector2(1.5, 2.0), Vector2(-1.5, -2.0), Vector2(1.5, -2.0)]
## The Vigil's way past the door (offsets from it).
const VIGIL_ROUTE := [Vector2(6.0, -4.0), Vector2(0.0, -2.5), Vector2(0.0, 2.5), Vector2(6.0, 4.0)]
## 2:00 -- the priests burn the house.
const FIRE_AT := 120.0
const FIRE_LEVEL := 0.6
## Minds a searcher takes the search up again from.
const RESUMABLE := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.REGROUP]
```

  - Add the fields under `var roof_fallen`:

```gdscript
var venn_searching := false
var shouter: Person
var vigil: VigilRoute
var liners: Array[Person] = []
var _venn_houses: Array[Vector2] = []
var _venn_i := 0
var _venn_wait := 0.0
var _shout_left := 0.0
var _liners_left := 0.0
```

  - Replace `_add_events()`, `_step_events()` and `_entered()` with:

```gdscript
func _add_events() -> void:
	timeline.add(VENN_AT, "venn", "The Inquisitor searches", _venn_starts, func() -> bool: return _alive(venn))
	timeline.add(SHOUT_AT, "shout", "A believer cries out", _shout, func() -> bool: return _newest_outside() != null)
	timeline.add(VIGIL_AT, "vigil", "The Vigil passes", _vigil_passes)
	timeline.add(FIRE_AT, "fire", "They burn her house", _burn, func() -> bool: return house != null and not house.destroyed)


func _step_events(delta: float) -> void:
	_venn_step(delta)
	_shout_step(delta)
	if vigil != null:
		vigil.step(delta)
	_liners_step(delta)
	if not burning and house != null and house.destroyed:
		_flush()  # destroyed before the fire (review focus 2)


## The crying Believer whispered back in: the cry is over.
func _entered(p: Person) -> void:
	if p == shouter:
		shouter = null
```

  - Add the event functions:

```gdscript
func _venn_starts() -> void:
	var near: Array[Structure] = []
	for s: Structure in town._built:
		if s.kind == Structure.Kind.HOUSE and s.role == &"house" and not s.destroyed and s != house \
				and s.center().distance_to(door) <= 9.0:
			near.append(s)
	near.sort_custom(func(a: Structure, b: Structure) -> bool: return a.center().distance_to(door) > b.center().distance_to(door))
	_venn_houses = []
	for s in near.slice(maxi(0, near.size() - VENN_HOUSES)):
		_venn_houses.append(_door_of(s))
	_venn_houses.append(door)
	_venn_i = 0
	_venn_wait = 0.0
	venn_searching = true
	venn.go_duty(_venn_houses[0])


func _venn_step(delta: float) -> void:
	if not venn_searching:
		return
	if not _alive(venn) or _carrying(venn):
		venn_searching = false
		return
	var goal := _venn_houses[_venn_i]
	if venn.mind != Person.Mind.DUTY:
		if venn.mind in RESUMABLE:
			venn.go_duty(goal)
		return
	if venn.ground_pos.distance_to(goal) > VENN_REACH and venn.has_goal():
		return
	if goal == door and not _reading.is_empty():
		venn_searching = false
		_report(venn)
		return
	_venn_wait += delta
	if _venn_wait >= VENN_STOP:
		_venn_wait = 0.0
		_venn_i = (_venn_i + 1) % _venn_houses.size()
		venn.go_duty(_venn_houses[_venn_i])


func _newest_outside() -> Person:
	for i in range(believers.size() - 1, -1, -1):
		var p := believers[i]
		if _alive(p) and not p.inside:
			return p
	return null


func _shout() -> void:
	shouter = _newest_outside()
	if shouter == null:
		return
	_shout_left = SHOUT_SECONDS
	shouter.go_duty(_walkable(door + SHOUT_OFF))


func _shout_step(delta: float) -> void:
	if shouter == null:
		return
	if not _alive(shouter):
		shouter = null
		return
	_shout_left -= delta
	if _shout_left > 0.0:
		return
	var heard := faithful_seeing(shouter.ground_pos, HEAR)
	if shouter.mind == Person.Mind.DUTY:
		shouter.leave_shelter(false)
	shouter = null
	if heard != null:
		_report(heard)


## The flame-bearer and his acolytes: the clergy nearest the Temple (not the Inquisitor), else any Faithful.
func _vigil_passes() -> void:
	var free: Array[Person] = []
	for f in faithful:
		if _alive(f) and not f.inside and f != venn and not _carrying(f):
			free.append(f)
	free.sort_custom(func(a: Person, b: Person) -> bool:
		var ca := a.profile.role == CitizenProfile.Role.CLERGY
		var cb := b.profile.role == CitizenProfile.Role.CLERGY
		if ca != cb:
			return ca
		return a.ground_pos.distance_to(temple_door) < b.ground_pos.distance_to(temple_door))
	if not free.is_empty():
		var route := PackedVector2Array()
		for off in VIGIL_ROUTE:
			route.append(_walkable(door + (off as Vector2)))
		var acolytes: Array[Person] = []
		acolytes.assign(free.slice(1, 3))
		vigil = VigilRoute.new().setup(route, free[0], acolytes)
		vigil.start()
	var walking := vigil.walkers() if vigil != null else ([] as Array[Person])
	var lining: Array[Person] = []
	for f in free:
		if not walking.has(f):
			lining.append(f)
	lining.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_to(door) < b.ground_pos.distance_to(door))
	liners = []
	for i in mini(LINE_SPOTS.size(), lining.size()):
		lining[i].go_duty(_walkable(door + (LINE_SPOTS[i] as Vector2)))
		liners.append(lining[i])
	_liners_left = VIGIL_SECONDS


func _liners_step(delta: float) -> void:
	if liners.is_empty():
		return
	_liners_left -= delta
	if _liners_left > 0.0:
		return
	for f in liners:
		if _alive(f) and f.mind == Person.Mind.DUTY and not _carrying(f):
			f.leave_shelter(false)
	liners = []


func _burn() -> void:
	burning = true
	if crowd.fires != null:
		crowd.fires.ignite(house, FIRE_LEVEL)
	_flush()


## Everyone inside runs out at the door in a fright, unconverted if their reading was not done.
func _flush() -> void:
	burning = true
	for p: Person in _reading.keys():
		_reading.erase(p)
		if not is_instance_valid(p):
			continue
		_exit(p)
		p.panic(house.center() if house != null else door, 2.0)


func _carrying(p: Person) -> bool:
	for r in reports:
		if r.carrier == p:
			return true
	return false
```

  - Add `marker()` after `marks()`:

```gdscript
## The HUD's arrow: the Believer crying in the street.
func marker() -> Vector2:
	return shouter.ground_pos if _alive(shouter) else Vector2.INF
```

  - In `teardown()`, add `vigil = null` before `timeline = null`.

- [ ] **Step 4: Run the tests to verify they pass.** Expected: `checks=N failures=0`.
  - The Venn test drives her to the door by hand, so her search route's geometry does not matter to it.
  - If the Vigil's route points snap onto the same free cell (`_walkable` on a solid point), widen `VIGIL_ROUTE` within the tuning latitude, and report it.
- [ ] **Step 5: Run Digest, crowd_check and FLOW.** Expected: unchanged.
- [ ] **Step 6: Commit.**

```bash
git add src/game/mission/miras_house_director.gd tests/test_miras_house.gd
git commit -m "feat: Mira's House's windows: the Inquisitor, the cry, the Vigil, the fire (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 6: The `miras` scenario, and the HUD photograph

**Files:**
- Modify: `tools/dev/behaviour_check.gd`, `src/game/game.gd`

**Interfaces:**
- Consumes: `MirasHouseDirector` (Tasks 4–5), `Rules.cast(slot, ground, extra)`, Mind Whisper's `{"target", "to"}` extras, `MindWhisper.REACH`.
- Produces:
  - `--scenario=miras --case=none|play`, printing `BEHAVIOUR miras t=… believers=… gaze=… reports=…` every 10 s and a final `BEHAVIOUR miras result won=… reason=… time=… believers=… gaze=… reports=…`;
  - `--show=miras` on the game scene: Mira's House paused just after its intro, for the photograph.

- [ ] **Step 1: The scenario.** In `tools/dev/behaviour_check.gd`:
  - Add a line to the scenario list in the file's header comment: `##   miras  (v0.10 M2) Mira's House, --case=none (nothing cast) or play (whisper the grieving in when nobody of the Faith watches the door; Discord on the nearest watcher).`
  - In the setup block, beside `elif scenario == "night":`, add:

```gdscript
	elif scenario == "miras":
		powers = PackedStringArray(["whisper", "wisp", "discord"])
		mission.mission_id = MissionBook.MIRAS_HOUSE
```

  - In the `match scenario:`, add:

```gdscript
		"miras":
			await _miras(Battlefield.arg_value(args, "--case"))
```

  - Add:

```gdscript
## Mira's House (v0.10 M2), played by a simple policy: every tenth of a second, Discord on the nearest Faithful who can
## see the door (when ready), else a whisper sending the nearest unread grieving citizen in reach to the door when nobody
## of the Faith watches it. `none` casts nothing.
func _miras(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as MirasHouseDirector
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
			print("BEHAVIOUR miras t=%d believers=%d inside=%d gaze=%d reports=%d" % [roundi(t), d.believers_outside(),
				d.inside().size(), roundi(d.gaze.value), d.reports_started])
		if which != "play" or frames % 6 != 0:
			continue
		var watcher := d.faithful_seeing(d.door, MirasHouseDirector.SIGHT)
		if watcher != null:
			if slots.has("discord") and rules.refusal(slots.discord) == "":
				rules.cast(slots.discord, watcher.ground_pos)
			continue
		if not slots.has("whisper") or rules.refusal(slots.whisper) != "":
			continue
		var best: Person = null
		for g in d.grieving:
			if not is_instance_valid(g) or not g.is_alive() or g.inside or d.believers.has(g) or g.shaken():
				continue
			if g.ground_pos.distance_to(d.door) > MindWhisper.REACH:
				continue
			if best == null or g.ground_pos.distance_to(d.door) < best.ground_pos.distance_to(d.door):
				best = g
		if best != null:
			rules.cast(slots.whisper, best.ground_pos, {"target": best, "to": d.door})
	var res := rules.result()
	print("BEHAVIOUR miras result won=%s reason=%s time=%.1f believers=%d gaze=%d reports=%d" % [res.won, res.reason,
		float(res.time), d.believers_outside(), roundi(d.gaze.value), d.reports_started])
```

- [ ] **Step 2: Run the scenario.** Run `--scenario=miras --case=none` and `--scenario=miras --case=play`.
  - Expected: no SCRIPT ERROR either way.
  - `none` loses with reason `few` or `gaze`.
  - `play` prints its result line. Record both lines for Task 7: this step checks only that the night runs.
- [ ] **Step 3: The photograph.** In `src/game/game.gd`'s `_ready()` `match show:`, add before `_:`:

```gdscript
		"miras":
			# Mira's House a few seconds in (v0.10 M2), paused, for the photograph of its HUD: the Gaze bar and the marks.
			mission_id = MissionBook.MIRAS_HOUSE
			loadout = MissionBook.miras_house().default_loadout
			go_to(Screen.MISSION)
			_open_pause()
```

  Capture `--show=miras`. Check by eye:
  - the Gaze bar sits under the clock, clear of the event strip;
  - the gold diamonds sit over the grieving's heads;
  - the objective rows read "Halcyon's Gaze 0%" and "Believers 0 / 5".

  The pause menu covers the middle of the screen; that is fine. Fix placement constants if needed, and report what changed.
- [ ] **Step 4: Run Tests, Digest and crowd_check.** Expected: unchanged counts apart from the new suites.
- [ ] **Step 5: Commit.**

```bash
git add tools/dev/behaviour_check.gd src/game/game.gd
git commit -m "test: the miras scenario and Mira's House photograph (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 7: Balance

**Files:** `src/game/mission/miras_house_director.gd`, `src/game/mission/gaze_meter.gd`, `src/game/mission/believers_objective.gd`, `src/game/mission/mission_book.gd` (numbers only).

- [ ] **Step 1: Measure.** Run `--case=none` three times and `--case=play` three times (seeds `--seed=1|2|3`). Record each result line.
- [ ] **Step 2: Compare with the spec's intent (§7: "each Night 2 mission winnable at 8 DP by a scripted policy"):**
  - doing nothing loses;
  - the policy wins at least two seeds out of three;
  - the night is not won before about 1:30 (the windows must matter).
- [ ] **Step 3: Tune only these:** `GRIEVING`, `FAITHFUL`, `SIGHT`, `HEAR`, `READ_SECONDS`, `BelieversObjective.NEED`, the event times, the clock, `GazeMeter.SEEN_DEATH`. Record each change with before/after result lines.
- [ ] **Step 4: Run Tests.** Retune any test that pins a changed number.
- [ ] **Step 5: Commit** with the measurements in the message body.

```bash
git add src/game/mission/miras_house_director.gd src/game/mission/gaze_meter.gd src/game/mission/believers_objective.gd src/game/mission/mission_book.gd tests/test_miras_house.gd
git commit -m "tune: Mira's House balance from measured runs (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 8 (controller): M2 gate

- [ ] **Step 1: Gates:**
  - Tests: `failures=0`;
  - Digest and crowd_check unchanged;
  - the ten exact behaviour checksums identical;
  - FLOW: `failures=0`;
  - Mission tests in range.
- [ ] **Step 2: Photographs:** `--show=miras`, plus `--show=campaign-choice` (unchanged). Show them to the user.
- [ ] **Step 3: Playtest by hand:** Campaign, then on Night 2 choose Mira's House.
- [ ] **Step 4: Land:** fast-forward `feat/Develop-Main` (merge origin first if it moved, and rerun the gates on the merged code). Tag `kak-v010-m2` and push, with the user's go-ahead.
- [ ] **Step 5: Update the Dev Ledger:** M2 to done; `meta/project` with the new counts.
- [ ] **Step 6: Write the M3 plan** (Broken Lanterns).
