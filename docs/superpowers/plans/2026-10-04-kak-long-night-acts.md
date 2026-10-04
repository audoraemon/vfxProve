# KAK v0.09 The Long Night Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** a new Tier 3 mission, *The Long Night*. It is played in three acts on one map. A choice card between acts picks the path, timed events give each act windows to seize, and each act's outcome shapes the next town.

**Architecture:**
- **Acts are data:**
  - `ActDef` extends `MissionDef`, so an act already has its own clock, objectives, bonuses, director, camera and banner.
  - It adds the town it wants (given the night so far) and the acts that may follow.
  - A `MissionDef` with `acts` is played in acts. The Warning and Last Judgement have none and are unchanged.
- **One town, a new Rules per act:** `Mission` keeps one town and one crowd for the whole night and builds a fresh `Rules`, director, `Targeting` and `Hud` for each act.
- **Per-act counting:** `Rules` counts escapes and kills from its own start (baselines), so an act's score and escape limit are its own.
- **What carries over:** `NightState` holds it. `Crowd.raise_profile()` turns on town responses mid-mission and never lowers them.
- **Timed events:** an act's director owns an `EventTimeline`, and the HUD shows its next two events.
- **Between acts:** Game gets an `INTERLUDE` screen (the act's result and the choice card), then reuses Prepare in "act mode" with a BEGIN button. It continues the same `Mission` node instead of building a new one.

**Tech Stack:** Godot 4.7.2, GDScript; headless tests in `tests/run_all.gd`; scripted scenarios in `tools/dev/behaviour_check.gd`; the screen-flow test `--flow-test`.

**Spec:** `docs/superpowers/specs/2026-10-04-kak-long-night-acts-design.md`. Read it before any task.

## Global Constraints

- **Baseline:** `feat/Develop-Main` at `c09141b`: v0.08.2 plus the PixelLab art, already merged and pushed. This plan's version is **v0.09**. Milestone tags are `kak-v009-m1` … `kak-v009-m4`, then `kak-v0.09`.
- **Open points assumed** (the spec's §6 defaults; the user did not answer them before this plan was written, so the controller reports them):
  1. **Version:** v0.09. Resonance, Trials and the campaign save move to v0.10.
  2. **Early end:** an act ends as soon as an objective decides it; the existing 3 s slow-motion ending is the beat.
  3. **The Procession:** on foot. There is no carriage.
  4. **Starting numbers:**
     - 4 slots and 10 DP for the night;
     - festival success at 50 of 80;
     - escape limits of 50, or 40 when the Prince escaped;
     - act clocks of 120 / 150 / 150 / 180 s.
- **Machine:** the BURIN_NITRO laptop.
  - **Repository:** `C:\BURIN_NITRO\Godot\GIT\vfxProve` (Git Bash `/c/BURIN_NITRO/Godot/GIT/vfxProve`). Work in that checkout. Other worktrees belong to other sessions; never touch them:
    - `vfxProve-pixellab`;
    - `vfxProve-integrate`;
    - `.claude/worktrees/*`.
  - **Branch:** `feat/Develop-Main`. Check `git branch --show-current` before every commit.
  - **Godot:** `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`. The user env var `GODOT` is set to it, so `tools/test.sh` and `tools/capture.sh` work.
- **Commands:**
  - **Import** (after a new `class_name`, a new test file or new PNGs): `timeout 180 $G --headless --editor --path . --import >/dev/null 2>&1`.
  - **Tests:** `timeout 900 $G --headless --path . --script res://tests/run_all.gd 2>&1 | grep -v '^\s*at:' | grep -n "FAIL\|SCRIPT ERROR\|Parse Error\|checks="`. Expected: `checks=N failures=0`, with no SCRIPT ERROR or Parse Error lines. The baseline is 1755.
  - **Digest:** `$G --headless --path . -s tools/dev/state_digest.gd`. Expected: `digest=61267b7e90524d800bf1c3473a71146b`.
  - **crowd_check:** `$G --headless --path . --fixed-fps 60 -s tools/dev/crowd_check.gd`. Expected: `checksum=-346732806`.
  - **FLOW:** `$G --path . --audio-driver Dummy --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep "FLOW result"`. Expected: `failures=0`. The baseline is 35 checks.
  - **Behaviour:** `$G --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=<name>`. The exact baselines:
    - `calm --seconds=60`: -695580348
    - `gates`: 619520995
    - `fire`: -16560442
    - `rite --interrupt`: -129298221
    - `soldiers --case=escort`: -935015846
    - The Warning cases (`--scenario=warning --case=`):
      - `none`: -446012507
      - `doom`: -999129915
      - `whisper`: 442055066
      - `discord`: -909358062
      - `mix`: -430643507
  - **Mission tests:** `$G --path . --audio-driver Dummy --scene res://scenes/mission.tscn -- --mission-test 2>&1 | grep MISSION`. It is not exact; within a few of: buildings 51–56, citizens 184–193, escaped 0–1, stability 67–71%, citadel 50%. With `--mission=warning` it must print `won=false reason=bell time≈24`.
  - **Do not touch any game window while a run goes:** an R key restarts the mission.
- **Test style:**
  - A test file is `extends RefCounted` with `static func run(t) -> void:`, using `t.check(cond, "msg")` and `t.near(a, b, eps, "msg")`.
  - Register a new file in `tests/run_all.gd` at the end of `SUITES`.
  - Build the crowd with `_crowd()` from `tests/test_corps.gd`, and the Rules plus a director like `tests/test_warning.gd`'s `_setup()`. Copy those helpers into each new test file and adapt them.
  - Tests step `crowd.advance(dt)` and then `rules.advance(dt)` by hand, in that order (the tree's order).
- **Code style:**
  - tabs; `##` doc comments in full sentences; constants `UPPER_CASE` with a `##` comment;
  - match the surrounding comment density;
  - **new enum values go at the end** (`int(p.mind)` and the roles are hashed by the checksums and indexed by `PeopleArt.CITIZEN`).
- **The Warning and Last Judgement must not change.** Every exact gate above must stay identical through every milestone. The night's code runs only for a `MissionDef` with acts.
- **Git:**
  - `git add` explicit paths only, including new `.gd.uid` and `.import` files;
  - never add `default_bus_layout.tres` (restore it with `git checkout -- default_bus_layout.tres`), `captures/`, `.codex/`, `concepts/`;
  - every commit message ends with a blank line, then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; tag the subject `(v0.09)`;
  - **do not push or tag:** the controller does that at each milestone gate.
- **Tuning latitude:**
  - The code was written against `c09141b` and has not been run. Fix real bugs and keep each test's intent.
  - You may change placement constants (spots, routes, offsets, screen pixels) when the town's geometry or the 640×360 screen needs it.
  - Gameplay numbers change only in Task 19.
  - Report every deviation.

## Review Focus

These are inputs the spec implies but no feature test exercises. Each line has its test in the owning task.

1. **An actor dead or missing before its event:** the Mayor killed before 1:30, the Prince killed in his first second, no watchman, a dead keeper. The event is skipped quietly, with no SCRIPT ERROR, and the act still ends by its objectives. *Tests:* Tasks 13 and 16.
2. **Restart, Change powers or Missions mid-night,** from Pause during Act II, or Esc on the interlude. You get a fresh night from Act I, or the board. No old `Rules` or director stays connected: one destroyed building counts once. *Test:* Task 5's FLOW steps.
3. **A town response whose building is already gone when it is raised:** the cathedral fallen before the rite is enabled, the dock ruined before the boats. The raise skips it with no error, and the event that would use it is not added. *Tests:* Tasks 7 and 10.
4. **An act ends while a power is still running** or the time scale is dipped by a hit. The next act starts at time scale 1.0, the old effect's kills are not credited to the new `Rules`, and the new act's cooldowns are all ready. *Test:* Task 3.
5. **An old save with no night section, or a night never played:** the board card shows "Not yet played", and the first Prepare preselects the night's default loadout. *Test:* Task 6.

---

## File structure

| File | Responsibility |
|---|---|
| `src/game/mission/act_def.gd` | **New.** `ActDef extends MissionDef`: its town rule, what follows, per-night objectives |
| `src/game/mission/night_state.gd` | **New.** `NightState`: act results, the path, carry-over flags, the night score and rank, the night's result |
| `src/game/mission/event_timeline.gd` | **New.** `EventTimeline`: timed events that fire once |
| `src/game/mission/festival_director.gd`, `procession_director.gd`, `judgement_director.gd` | **New.** The acts' directors |
| `src/game/mission/festival_objective.gd`, `prince_objective.gd`, `bell_quiet_objective.gd`, `quiet_succession_objective.gd`, `dawn_objective.gd` | **New.** The acts' objectives and bonuses |
| `src/game/mission/mission_def.gd`, `mission_book.gd`, `mission_director.gd` | `acts`; `long_night()`; `timeline`, `night`, `carry()` |
| `src/game/mission/escape_limit_objective.gd`, `warning_director.gd` | Escapes per act; `hold_on_death` reset |
| `src/game/rules.gd` | Per-act baselines, `escaped_this_act()`, `force_end()` |
| `src/game/mission.gd` | Night mode: `act_over`, `next_act()`, `next_choices()`, rebuilding the HUD and aim, the intro per act, `_wire_responses()` |
| `src/game/game.gd` | The `INTERLUDE` screen, FLOW entries, continuing the night, the FLOW test |
| `src/game/ui/interlude_screen.gd` | **New.** The act's result and the choice card |
| `src/game/ui/prepare_screen.gd`, `results_screen.gd`, `mission_board.gd`, `hud.gd` | The BEGIN label; the night's results; the night card; the event strip |
| `src/game/save_file.gd` | `paths_won` per mission |
| `src/game/response_profile.gd` | `level()` |
| `src/game/crowd/crowd.gd`, `banishing_rite.gd`, `river_ferry.gd`, `src/game/town/town.gd` | `raise_profile()`, `hold_gate()`, `forgo_rally()`, `off_by_profile`, `open_postern()`, `RiverFerry.close()` |
| `src/game/crowd/citizen_profile.gd`, `routine_manager.gd`, `person.gd`, `src/environment/art/people_art.gd` | `Role.MAYOR`, `Role.NOBLE`, and their looks on both art paths |
| `src/fx/omen/bonfire.gd` | **New.** `BonfireFx` (light only, no danger) |
| `tools/dev/behaviour_check.gd` | The `night` scenario |
| `tests/test_night.gd`, `test_raise.gd`, `test_events.gd`, `test_festival.gd`, `test_procession.gd`, `test_judgement.gd` | **New** tests |

---

## Milestone 1 — Acts

### Task 1: ActDef, NightState and The Long Night's book entry

**Files:**
- Create: `src/game/mission/act_def.gd`, `src/game/mission/night_state.gd`, `tests/test_night.gd`
- Modify: `src/game/mission/mission_def.gd`, `src/game/mission/mission_book.gd`, `tests/run_all.gd`, `tests/test_mission_book.gd`

**Interfaces:**
- Produces:
  - `ActDef extends MissionDef`:
    - `var next := PackedStringArray()`, `var make_town: Callable` (`func(night: NightState) -> ResponseProfile`);
    - `var make_act_objectives: Callable` and `var make_act_bonuses: Callable` (`func(night: NightState) -> Array[Objective]`);
    - `var make_card_line: Callable` (`func(night: NightState) -> String`);
    - `var events_text := PackedStringArray()`, `var night: NightState`;
    - `func town(night: NightState) -> ResponseProfile`, `func is_last() -> bool`, `func card_line(night: NightState) -> String`;
    - overrides `objectives()` and `bonuses()`.
  - `MissionDef`: `var acts: Array = []` (of `ActDef`), `func has_acts() -> bool`, `func act(id: String) -> ActDef`, `func first_act() -> ActDef`.
    - `response_profile()` returns `ResponseProfile.unaware()` for `profile == "night"`, and `chooses_difficulty()` is false for it.
  - `NightState`:
    - `results: Array[Dictionary]`, `path`, `bell_rang`, `festival`, `prince`, `festival_broke: Array[Person]`;
    - `record(act_id, result, crowd)`, `act_result(id) -> Dictionary`, `acts_won() -> int`, `bonuses_earned() -> int`, `escape_limit() -> int`;
    - `night_score(final_score: int) -> int`, `static rank_for(score: int) -> String`;
    - `result(final: Dictionary, mission_id: String) -> Dictionary`;
    - constants `ACT_POINTS := 2000`, `BONUS_POINTS := 500`, `PRINCE_ESCAPED_LIMIT := 40`, `NIGHT_RANKS := [[20000, "S"], [15000, "A"], [10000, "B"], [5000, "C"]]`.
  - `MissionBook.LONG_NIGHT := "long_night"`, `MissionBook.long_night() -> MissionDef`. `all()` becomes `[warning(), long_night(), last_judgement()]`.
    - **In M1, the acts are:**
      - `omen`: Warning-like, with the WarningDirector;
      - `festival` and `procession`: placeholders, "Hold until the act ends" — `ClockObjective(true, "Hold", "held")` and no director;
      - `judgement`: Citadel, escapes, clock 180.
    - M3 and M4 replace the placeholders.

- [ ] **Step 1: Write the failing test.** Create `tests/test_night.gd`:

```gdscript
extends RefCounted
## v0.09 The Long Night as data: three acts with a choice after the first, the town each act wants given the night so
## far, what carries between acts, and the night's score and rank.


static func run(t) -> void:
	var m := MissionBook.long_night()
	t.check(m.id == "long_night" and m.tier == 3 and m.has_acts() and not m.chooses_difficulty(),
		"The Long Night is a Tier 3 mission in acts, its town set by the night")
	t.check(m.slots == 4 and m.dp_capacity == 10 and m.powers() == PowerBook.keys(), "4 slots, 10 DP, every power")
	var first := m.first_act()
	t.check(first.id == "omen" and Array(first.next) == ["festival", "procession"], "Act I leads to a choice of two")
	t.check(Array(m.act("festival").next) == ["judgement"] and Array(m.act("procession").next) == ["judgement"],
		"both paths lead to Judgement")
	t.check(m.act("judgement").is_last() and not first.is_last(), "Judgement is the last act")
	t.check(m.act("nonsense") == null, "an unknown act is null")
	t.near(first.clock, 120.0, 0.001, "Act I is two minutes")
	t.near(m.act("judgement").clock, 180.0, 0.001, "Act III is three")
	t.check(MissionBook.all()[1].id == "long_night", "the board lists it between The Warning and Last Judgement")

	# The night remembers what each act did.
	var n := NightState.new()
	n.record("omen", {"won": true, "reason": "warning", "time": 40.0, "bonuses": [{"label": "Unseen", "earned": true}]}, null)
	n.path = "procession"
	n.record("procession", {"won": false, "reason": "sailed", "time": 150.0, "bonuses": [], "prince": "escaped"}, null)
	t.check(n.acts_won() == 1 and n.bonuses_earned() == 1, "one act won, one bonus (%d, %d)" % [n.acts_won(), n.bonuses_earned()])
	t.check(n.prince == "escaped" and n.escape_limit() == NightState.PRINCE_ESCAPED_LIMIT,
		"the Prince escaping lowers Act III's escape limit to 40")
	t.check(NightState.new().escape_limit() == Rules.ESCAPE_LIMIT, "otherwise it is 50")
	t.check(n.act_result("omen").reason == "warning" and n.act_result("judgement").is_empty(), "results by act")
	t.check(n.night_score(9000) == 9000 + NightState.ACT_POINTS + NightState.BONUS_POINTS, "the night's score")
	t.check(NightState.rank_for(20000) == "S" and NightState.rank_for(4999) == "D", "and its rank")
	var final := {"won": true, "reason": "citadel", "time": 170.0, "score": 9000, "lines": [], "bonuses": []}
	var r := n.result(final, "long_night")
	t.check(r.mission == "long_night" and r.won and r.path == "procession" and (r.acts as Array).size() == 2,
		"the night's result keeps every act and the path")
	t.check(int(r.score) == n.night_score(9000) and String(r.rank) == NightState.rank_for(int(r.score)),
		"scored as the night, not the last act")
	t.check(String(r.reason) == "citadel", "and ends on the last act's reason")

	# The town each act wants: Act I asleep; a rung bell wakes Act II; the Procession's outcome sets Act III.
	var asleep := NightState.new()
	t.check(m.act("festival").town(asleep).tier_name() == "Unaware", "no bell in Act I: Act II's town still sleeps")
	asleep.bell_rang = true
	t.check(m.act("festival").town(asleep).tier == ResponseProfile.Tier.ORGANIZED
		and m.act("festival").town(asleep).title == "", "a rung bell: Organized")
	var seen := NightState.new()
	seen.prince = "seen"
	t.check(m.act("judgement").town(seen).tier == ResponseProfile.Tier.PREPARED, "a seen killing: Prepared")
	var unseen := NightState.new()
	unseen.prince = "unseen"
	t.check(m.act("judgement").town(unseen).tier == ResponseProfile.Tier.ORGANIZED, "unseen: Organized")
	# Act III's escape limit comes from the night it is given.
	var j := m.act("judgement")
	j.night = n
	var limit := -1
	for o in j.objectives():
		if o is EscapeLimitObjective:
			limit = (o as EscapeLimitObjective).limit
	t.check(limit == 40, "Act III's escape limit is the night's (%d)" % limit)
```

  Register it in `tests/run_all.gd`.

  In `tests/test_mission_book.gd`, change the `all()` order check to `[warning, long_night, last_judgement]`, keeping the other checks.

- [ ] **Step 2: Run the tests.** They fail with Parse Errors (`ActDef` and `NightState` are unknown).
- [ ] **Step 3: Write `act_def.gd`:**

```gdscript
class_name ActDef
extends MissionDef
## One act of a mission played in acts (v0.09): everything a MissionDef has -- clock, objectives, bonuses, director,
## camera, banner -- plus the town it wants given the night so far, and the acts that may follow it. Rules, the HUD and
## Prepare take an ActDef wherever they take a MissionDef.

## The acts that may follow, by id: none (the last act), one, or two (the choice card).
var next := PackedStringArray()
## func(night: NightState) -> ResponseProfile: the town this act wants. Crowd.raise_profile() never lowers it.
var make_town: Callable
## func(night: NightState) -> Array[Objective], for objectives that depend on the night (Act III's escape limit).
## When unset, MissionDef's make_objectives / make_bonuses are used.
var make_act_objectives: Callable
var make_act_bonuses: Callable
## func(night: NightState) -> String: the choice card's line on how the town will meet the player.
var make_card_line: Callable
## The act's timed events, one short line each, for the choice card ("1:30 The Mayor's address").
var events_text := PackedStringArray()
## The night so far; Mission sets it before Rules.setup() asks for the objectives.
var night: NightState


func town(n: NightState) -> ResponseProfile:
	return make_town.call(n) if make_town.is_valid() else ResponseProfile.unaware()


func is_last() -> bool:
	return next.is_empty()


func card_line(n: NightState) -> String:
	return String(make_card_line.call(n)) if make_card_line.is_valid() else ""


func objectives() -> Array[Objective]:
	if not make_act_objectives.is_valid():
		return super()
	var out: Array[Objective] = []
	out.assign(make_act_objectives.call(night if night != null else NightState.new()))
	return out


func bonuses() -> Array[Objective]:
	if not make_act_bonuses.is_valid():
		return super()
	var out: Array[Objective] = []
	out.assign(make_act_bonuses.call(night if night != null else NightState.new()))
	return out
```

  **In `mission_def.gd`:**
  - Add, after `make_bonuses`:

```gdscript
## A mission played in acts (v0.09, The Long Night): its ActDefs, the first one first. Empty for a single act.
var acts: Array = []


func has_acts() -> bool:
	return not acts.is_empty()


func first_act() -> ActDef:
	return acts[0] if has_acts() else null


func act(id: String) -> ActDef:
	for a in acts:
		if (a as ActDef).id == id:
			return a
	return null
```

  - `chooses_difficulty()` returns `profile == ""`. Since `"night"` is not empty, it is false already; check that.
  - `response_profile()`: add `if profile == "night": return ResponseProfile.unaware()` beside the `"unaware"` case. The night's first town is asleep.

  **`night_state.gd`:**

```gdscript
class_name NightState
extends RefCounted
## What carries between the acts of a night (v0.09): each act's result, the path chosen after Act I, and the outcomes
## that shape the next town (the bell rang; the festival broke or held; the Prince died unseen, seen, or escaped).

## Points for each act won and each bonus earned, on top of the last act's score (the night's rank).
const ACT_POINTS := 2000
const BONUS_POINTS := 500
## Act III's escape limit when the Prince escaped: the kingdom rallied.
const PRINCE_ESCAPED_LIMIT := 40
## Score floors for the night's rank, best first; under the last one is a D. Starting values, tuned in Task 19.
const NIGHT_RANKS := [[20000, "S"], [15000, "A"], [10000, "B"], [5000, "C"]]

## One dictionary per act played: its Rules.result() plus "act" (the act's id).
var results: Array[Dictionary] = []
## The path chosen on the choice card: "festival" or "procession" ("" before the choice).
var path := ""
var bell_rang := false
## "broken" or "held" once the Festival is over.
var festival := ""
## "unseen", "seen" or "escaped" once the Procession is over.
var prince := ""
## The festival-goers who broke and still live when the Festival ends (Act III sends them fleeing).
var festival_broke: Array[Person] = []


## Keep an act's result and read what it changed. A town whose bell has rung stays warned.
func record(act_id: String, result: Dictionary, crowd: Crowd) -> void:
	var r := result.duplicate(true)
	r["act"] = act_id
	results.append(r)
	if crowd != null and (crowd.alarms.bell_rung or (crowd.bell != null and crowd.bell.state == BellNetwork.State.RUNG)):
		bell_rang = true
	if result.has("festival"):
		festival = String(result.festival)
	if result.has("prince"):
		prince = String(result.prince)


func act_result(id: String) -> Dictionary:
	for r in results:
		if String(r.get("act", "")) == id:
			return r
	return {}


func acts_won() -> int:
	var n := 0
	for r in results:
		n += 1 if bool(r.get("won", false)) else 0
	return n


func bonuses_earned() -> int:
	var n := 0
	for r in results:
		for b in r.get("bonuses", []):
			n += 1 if bool((b as Dictionary).get("earned", false)) else 0
	return n


func escape_limit() -> int:
	return PRINCE_ESCAPED_LIMIT if prince == "escaped" else Rules.ESCAPE_LIMIT


func night_score(final_score: int) -> int:
	return final_score + acts_won() * ACT_POINTS + bonuses_earned() * BONUS_POINTS


static func rank_for(score: int) -> String:
	for r: Array in NIGHT_RANKS:
		if score >= int(r[0]):
			return String(r[1])
	return "D"


## The night's result for the Results screen and the save: the last act decides won and reason; the score is the night's.
## `final` is the last act's Rules.result(), already recorded with record().
func result(final: Dictionary, mission_id: String) -> Dictionary:
	var acts := []
	var time := 0.0
	for r in results:
		acts.append({"act": r.act, "won": bool(r.get("won", false)), "reason": String(r.get("reason", "")),
			"bonuses": r.get("bonuses", []), "time": float(r.get("time", 0.0))})
		time += float(r.get("time", 0.0))
	var score := night_score(int(final.get("score", 0)))
	return {"mission": mission_id, "won": bool(final.get("won", false)), "reason": String(final.get("reason", "")),
		"time": time, "acts": acts, "path": path, "score": score, "rank": rank_for(score),
		"lines": final.get("lines", []), "bonuses": final.get("bonuses", []),
		"goal": {"label": "The night is yours", "done": bool(final.get("won", false))}}
```

  **`mission_book.gd`:** add `const LONG_NIGHT := "long_night"`, make `all()` return `[warning(), long_night(), last_judgement()]`, and add:

```gdscript
## The Long Night (v0.09, Tier 3): three acts in one town. Act I is The Warning; the choice card picks the Festival
## or the Procession; Act III is Judgement in the town the night has made. M1's middle acts are placeholders.
static func long_night() -> MissionDef:
	var m := MissionDef.new()
	m.id = LONG_NIGHT
	m.name = "The Long Night"
	m.tier = 3
	m.brief = PackedStringArray(["Three acts, one night.", "Your choices shape the town you face."])
	m.goal = "Stop the warning, strike the town's heart, then bring the Citadel down by dawn"
	m.goal_label = "The night is yours"
	m.lose = "The town holds until dawn"
	m.slots = 4
	m.dp_capacity = 10
	m.clock = 120.0
	m.profile = "night"
	m.scored = true
	m.default_loadout = PackedStringArray(["whisper", "doom", "discord"])
	m.intro_from = TownLayout.MAIN_GATE.get_center() + Vector2(0.0, 6.0)
	m.camera_at = TownLayout.MAIN_GATE.get_center().lerp(TownLayout.BELL_TOWER.get_center(), 0.35)
	m.acts = [_omen(m), _festival(m), _procession(m), _judgement(m)]
	m.make_objectives = (m.acts[0] as ActDef).make_objectives
	m.make_bonuses = (m.acts[0] as ActDef).make_bonuses
	return m


## An act with the night's loadout rules.
static func _act(m: MissionDef, id: String, name: String, clock: float) -> ActDef:
	var a := ActDef.new()
	a.id = id
	a.name = name
	a.tier = m.tier
	a.slots = m.slots
	a.dp_capacity = m.dp_capacity
	a.clock = clock
	a.profile = "night"
	a.default_loadout = m.default_loadout
	return a


static func _omen(m: MissionDef) -> ActDef:
	var w := warning()
	var a := _act(m, "omen", "Act I: The Omen", 120.0)
	a.brief = w.brief
	a.goal = w.goal
	a.goal_label = w.goal_label
	a.lose = w.lose
	a.intro_from = w.intro_from
	a.camera_at = w.camera_at
	a.intro_banner = "ACT I - THE OMEN"
	a.director = WarningDirector
	a.make_objectives = w.make_objectives
	a.make_bonuses = w.make_bonuses
	a.next = PackedStringArray(["festival", "procession"])
	a.make_town = func(_n: NightState) -> ResponseProfile: return ResponseProfile.unaware()
	return a


## The town Act II meets: still asleep if the warning died, Organized if the bell rang.
static func _act2_town(n: NightState) -> ResponseProfile:
	return ResponseProfile.for_tier(ResponseProfile.Tier.ORGANIZED) if n.bell_rang else ResponseProfile.unaware()


static func _festival(m: MissionDef) -> ActDef:
	var a := _act(m, "festival", "Act II: The Festival", 150.0)
	a.brief = PackedStringArray(["The market fills for the Feast of Lanterns.", "Break the festival."])
	a.goal = "Hold until the act ends"  # M3 replaces this placeholder
	a.goal_label = "Hold"
	a.camera_at = TownLayout.MARKET_SQUARE.get_center()
	a.intro_from = TownLayout.MARKET_SQUARE.get_center() + Vector2(0.0, 8.0)
	a.intro_banner = "ACT II - THE FESTIVAL"
	a.next = PackedStringArray(["judgement"])
	a.make_town = _act2_town
	a.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [ClockObjective.new(true, "Hold", "held")]
		return out
	a.make_card_line = func(n: NightState) -> String:
		return "The bell rang: soldiers watch the square." if n.bell_rang else "The town suspects nothing."
	return a


static func _procession(m: MissionDef) -> ActDef:
	var a := _act(m, "procession", "Act II: The Procession", 150.0)
	a.brief = PackedStringArray(["The Prince leaves the Citadel for the ship.", "Stop him before he sails."])
	a.goal = "Hold until the act ends"  # M4 replaces this placeholder
	a.goal_label = "Hold"
	a.camera_at = TownLayout.CITADEL_ORIGIN.lerp(TownLayout.DOCK.get_center(), 0.3)
	a.intro_from = TownLayout.CITADEL_ORIGIN
	a.intro_banner = "ACT II - THE PROCESSION"
	a.next = PackedStringArray(["judgement"])
	a.make_town = _act2_town
	a.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [ClockObjective.new(true, "Hold", "held")]
		return out
	a.make_card_line = func(n: NightState) -> String:
		return "The bell rang: his escort is wary." if n.bell_rang else "The Prince travels light."
	return a


## The town Act III meets (spec §2): the Procession's outcome decides it; otherwise Organized.
static func _act3_town(n: NightState) -> ResponseProfile:
	if n.prince == "seen" or n.prince == "escaped":
		return ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)
	return ResponseProfile.for_tier(ResponseProfile.Tier.ORGANIZED)


static func _judgement(m: MissionDef) -> ActDef:
	var a := _act(m, "judgement", "Act III: Judgement", 180.0)
	a.brief = PackedStringArray(["Dawn is coming.", "Bring the Citadel down before it does."])
	a.goal = "Destroy the Citadel and break the city before dawn"
	a.goal_label = "The city has fallen"
	a.lose = "The people escape, or dawn comes"
	a.scored = true
	a.intro_from = TownLayout.MAIN_GATE.get_center()
	a.camera_at = TownLayout.CITADEL_ORIGIN
	a.intro_banner = "ACT III - JUDGEMENT"
	a.make_town = _act3_town
	a.make_act_objectives = func(n: NightState) -> Array[Objective]:
		var out: Array[Objective] = [CitadelObjective.new(), EscapeLimitObjective.new(n.escape_limit()), ClockObjective.new()]
		return out
	return a
```

  Notes:
  - `_act2_town` and `_act3_town` are passed as Callables (`a.make_town = _act2_town`); a static function reference works as a Callable in Godot 4. If the parser refuses, wrap them in lambdas.
  - **Check this:** `ResponseProfile.for_tier(...)` leaves `title` as `""`. The test relies on it.
- [ ] **Step 4: Import, then run the tests.** They pass. The board now shows three cards: capture it and check they fit (`GODOT=$G SCENE=res://scenes/game.tscn bash tools/capture.sh --show=board --capture`, then read `captures/screen_board.png`). If they don't fit, make `MissionBoard`'s card width depend on the count, as `card_rect(i, count)` already allows.
- [ ] **Step 5: Run the exact gates.** Digest, crowd_check, the five behaviour checksums and FLOW must all be unchanged. FLOW picks missions by id.
- [ ] **Step 6: Commit.** Message: `feat: The Long Night as acts -- ActDef, NightState, the book entry with placeholder middle acts (v0.09)`.

### Task 2: Rules count per act; tools can end an act

**Files:**
- Modify: `src/game/rules.gd`, `src/game/mission/escape_limit_objective.gd`, `src/game/mission/warning_director.gd`, `tests/test_rules.gd`, `tests/test_warning.gd`

**Interfaces:**
- Produces:
  - `Rules.escaped_this_act() -> int`, `Rules.citizens_killed_this_act() -> int`, `Rules.soldiers_killed_this_act() -> int`;
  - `Rules.force_end(win: bool, reason: String)`, for tools and tests.
  - `EscapeLimitObjective` uses `escaped_this_act()`.
  - `WarningDirector.teardown()` sets `crowd.bell.hold_on_death = false`.

- [ ] **Step 1: Tests.**
  - **`test_rules.gd`, at the end:**
    - build a second `Rules` on the same crowd after setting `crowd.escaped_count = 7`, `crowd.killed_citizens = 3`, `crowd.killed_soldiers = 2`;
    - then `escaped_this_act() == 0`, and `score()` counts none of those kills;
    - after `crowd.escaped_count += 2`, `escaped_this_act() == 2`;
    - an `EscapeLimitObjective.new(2)` reports FAILED, and `EscapeLimitObjective.new(3)` reports PENDING;
    - `force_end(true, "test")` sets `finished`, `won` and `over_reason`, and emits `over` once; a second `force_end` does nothing.
  - **`test_warning.gd`:** after `_done()`'s teardown of a setup, `crowd.bell.hold_on_death == false`. Check before freeing, by calling `director.teardown()` then reading.
- [ ] **Step 2: Implement.**
  - **In `Rules`:**
    - Add `var _escaped0 := 0`, `var _citizens0 := 0`, `var _soldiers0 := 0`, with the doc comment "the crowd's counts when this act began (v0.09): an act counts from its own start; a single mission starts from 0".
    - Set them in `setup()` from `crowd.escaped_count`, `crowd.killed_citizens` and `crowd.killed_soldiers`.
    - Add the three `_this_act()` getters.
    - `score()` and `stat_lines()` use `citizens_killed_this_act()` and `soldiers_killed_this_act()` in place of `_crowd.killed_citizens` and `_crowd.killed_soldiers`. "Citizens escaped" uses `escaped_this_act()`.
    - `force_end(win, reason)`: `if not finished: _finish(win, reason)`.
  - **`EscapeLimitObjective.check`:** `rules.escaped_this_act() >= limit`.
  - **`WarningDirector.teardown()`:** add `if is_instance_valid(crowd) and crowd.bell != null: crowd.bell.hold_on_death = false` (the bell waits for a relay only while the warning lives).
- [ ] **Step 3: Run the tests and every exact gate.** For Last Judgement and The Warning the baselines are 0, so the digest, crowd_check, the behaviour checksums, the Warning cases, the mission test and FLOW are all unchanged.
- [ ] **Step 4: Commit.** Message: `feat: Rules counts escapes and kills from its own start; force_end for tools (v0.09)`.

### Task 3: Mission plays a night

**Files:**
- Modify: `src/game/mission.gd`, `src/game/mission/mission_director.gd`
- Modify: `tools/dev/behaviour_check.gd` (a `night` scenario skeleton for smoke runs)

**Interfaces:**
- Consumes: Tasks 1–2.
- Produces:
  - `Mission.signal act_over(result: Dictionary)`;
  - `Mission.next_act(powers: PackedStringArray, path := "") -> void`;
  - `Mission.next_choices() -> Array` (the `ActDef`s that may follow the current act);
  - `Mission.night() -> NightState` (null for a single mission), `Mission.act() -> ActDef`.
  - `MissionDirector`: `var night: NightState`, `var timeline: EventTimeline` (null until Task 9), and the virtual `func carry(_n: NightState) -> void`, called before teardown.
  - `MissionDirector.setup(r, c, t, x, n: NightState = null)`.
  - For a night, `finished(result)` carries `NightState.result(...)`.

- [ ] **Step 1: MissionDirector.**
  - `setup(r: Rules, c: Crowd, t: Town, x: FxContext, n: NightState = null)` stores `night = n` before `_begin()`.
  - Add `var timeline: EventTimeline` with the doc comment "the act's timed events (v0.09), or null".
  - Add `func carry(_n: NightState) -> void:` with the doc comment "Virtual: what this act hands the next one, written into the night before the director is let go".
  - `EventTimeline` does not exist until Task 9. Declare the var untyped for now (`var timeline = null`) with a comment, and type it in Task 9.
- [ ] **Step 2: Mission's night mode.** Add the fields `var _night: NightState` and `var _act: ActDef`.

  **In `start()`:**
  - After `_def = _mission_def(args)`, add:

```gdscript
	_night = NightState.new() if _def.has_acts() else null
	_act = _def.first_act() if _night != null else null
	if _act != null:
		_act.night = _night
	var play: MissionDef = _act if _act != null else _def
```

  - The profile line becomes `_crowd.profile = _act.town(_night) if _act != null else _def.response_profile(tier)`.
  - Every later use of `_def` in `start()` (`_rules.setup(..., _def)`, the director, `_def.intro_*`, `_def.camera_at`, the scripted framing) uses `play`.
  - The director is built with `.setup(_rules, _crowd, _town, _bf.ctx, _night)`.
  - Move the response-manager banner wiring (from `_crowd.rallied.connect` through the rite's signals) into a new `_wire_responses()`. Keep it idempotent with `var _wired := {}`, keyed by `get_instance_id()` of each manager, so a manager is wired once. Task 8 calls it again after a raise.
  - These lambdas read the `_rules` member when they fire, so the current act's Rules shows the banner.
  - Move the camera, intro and banner block at the end into `_begin_intro(play: MissionDef)` so `next_act()` can reuse it.

  **Add `next_act()`:**

```gdscript
## The next act of the night (v0.09), in the same town: the old act's director hands over what it carries and lets go,
## the old Rules let go of the world, and the act chosen (`path` after a choice card, else the only one) begins with a
## fresh Rules, director, aim and HUD -- every cooldown ready -- after its own intro sweep.
func next_act(powers: PackedStringArray, path := "") -> void:
	if _night == null or _act == null or _act.is_last():
		return
	var ids := _act.next
	var id := path if path != "" and ids.has(path) else String(ids[0])
	if ids.size() > 1:
		_night.path = id
	if _director != null:
		_director.carry(_night)
		_director.teardown()
		_rules.director = null
	_director = null
	_rules.teardown()
	_rules.queue_free()
	_aim.queue_free()
	_hud.queue_free()
	_act = _def.act(id)
	_act.night = _night
	Engine.time_scale = 1.0
	_bf.ctx.impact.set_base_time_scale(1.0)
	_ending = false
	_build_act(powers if not powers.is_empty() else _act.default_loadout)
	_begin_intro(_act)
```

  `_build_act(powers)` is new. It holds the part of `start()` that makes the Rules (with `_act`), connects `_rules.over` to `_on_over`, builds the director with the night, calls `_wire_responses()`, and makes `_aim` and `_hud`. `start()` calls it too, so the two paths share one builder.

  - `func next_choices() -> Array`: `[]` when there is no night or the act is the last; otherwise `_def.act(id)` for each id in `_act.next`.
  - `func night() -> NightState: return _night` and `func act() -> ActDef: return _act`.

  **`_play_ending()`:** replace its last line:

```gdscript
	var res := _rules.result()
	if _night == null:
		finished.emit(res)
		return
	_night.record(_act.id, res, _crowd)
	if _act.is_last():
		finished.emit(_night.result(res, _def.id))
	else:
		act_over.emit(res)
```

  **`_on_over`'s scripted print:** for a night act, print `MISSION act=%s won=%s reason=%s time=%.1f` before the existing lines.

- [ ] **Step 3: A smoke scenario.** In `behaviour_check.gd`:
  - Add `night` to the usage comment: "(v0.09) The Long Night forced through its acts: `--path=festival|procession`, `--act1=win|lose|skip`, `--act2=…`, `--act3=…`; each act ends as asked (skip lets it run to its clock); prints each act's result, the town's tier at each act's start, and the night's result".
  - In `_run()`, `scenario == "night"` sets `mission.mission_id = MissionBook.LONG_NIGHT`, with powers `["whisper", "doom", "discord"]`.
  - The function:

```gdscript
func _night() -> void:
	var args := OS.get_cmdline_user_args()
	var path := Battlefield.arg_value(args, "--path")
	path = path if path != "" else "festival"
	var outcome := {"omen": Battlefield.arg_value(args, "--act1"), "festival": Battlefield.arg_value(args, "--act2"),
		"procession": Battlefield.arg_value(args, "--act2"), "judgement": Battlefield.arg_value(args, "--act3")}
	var done := [false]
	var acts := [0]
	mission.act_over.connect(func(r: Dictionary) -> void:
		print("BEHAVIOUR night act=%s won=%s reason=%s time=%.1f" % [mission.act().id, r.won, r.reason, float(r.time)])
		acts[0] += 1)
	mission.finished.connect(func(r: Dictionary) -> void:
		print("BEHAVIOUR night end won=%s reason=%s path=%s acts=%d score=%d rank=%s" % [r.won, r.reason, r.path,
			(r.acts as Array).size(), int(r.score), r.rank])
		done[0] = true)
	var seen := -1
	while not done[0]:
		if acts[0] != seen:
			seen = acts[0]
			if seen > 0:
				await _frames(10)
				mission.next_act(PackedStringArray(), path)
				mission._intro_left = 0.0
				mission._rules.set_process(true)
			print("BEHAVIOUR night start act=%s town=%s" % [mission.act().id, mission._crowd.profile.tier_name()])
			await _frames(60)
			_force_act(String(outcome.get(mission.act().id, "")))
		await _frames(1)


## End the current act as asked: "win", "lose", or anything else to let it run.
func _force_act(how: String) -> void:
	var rules: Rules = mission._rules
	if how == "win":
		rules.force_end(true, "forced")
	elif how == "lose":
		if mission.act().id == "omen":
			mission._crowd.ring_bell()  # a lost Act I is a rung bell, as the night reads it
		rules.force_end(false, "forced")
```

  - Add `"night": await _night()` to the match.
- [ ] **Step 4: Run it.** `--scenario=night --act1=win --act2=win --act3=lose` prints three `start` lines and two `act=` lines, then one `end` line with `acts=3`, and no SCRIPT ERROR.
  - Run it again with `--act1=skip --act2=skip --act3=skip`: each act runs to its clock (about 7.5 minutes of game time).
  - Check that Act II's town reads Unaware after an Act I win, and Organized after `--act1=lose`. Until Task 8 the crowd's profile does not change; record what it prints.
- [ ] **Step 5: Review focus 4 (a dipped time scale).** In the scenario, before `next_act()`, set `Engine.time_scale = 0.3` and start a Heaven Splitter with `_force_cast(…)`. After `next_act()`:
  - `Engine.time_scale == 1.0`;
  - `mission._rules.buildings_down == 0` right after the act starts, so the old cast is not credited to the new act;
  - every `cooldown_left(i) == 0`.

  Print these as `BEHAVIOUR night handover time_scale=… buildings=… cooldowns=…` and check them.
- [ ] **Step 6: Run every exact gate.** Unchanged. `_build_act()` must keep Last Judgement's and The Warning's construction order, because the instance creation order feeds the staggers. Run the Warning cases too.
- [ ] **Step 7: Commit.** Message: `feat: Mission plays a night -- next_act, a fresh Rules/aim/HUD per act, the night's result (v0.09)`.

### Task 4: The interlude, and Prepare in act mode

**Files:**
- Create: `src/game/ui/interlude_screen.gd`
- Modify: `src/game/ui/prepare_screen.gd`, `src/game/game.gd`, `tests/test_flow.gd`, `tests/test_draft.gd`

**Interfaces:**
- Produces:
  - `Game.Screen.INTERLUDE`, appended last.
  - FLOW entries:
    - `"mission:act_over": INTERLUDE`
    - `"interlude:draft": PREPARE`
    - `"interlude:missions": BOARD`
    - `"prepare:begin": MISSION`
  - `InterludeScreen`:
    - `setup(result: Dictionary, choices: Array, night: NightState) -> InterludeScreen`;
    - `signal action(name)` with `"draft"` or `"missions"`;
    - `var chosen := ""`, `func choose(id: String)`, `static func card_rect(i: int, count: int) -> Rect2`.
  - `PrepareScreen.confirm_label := "MANIFEST"`, set to `"BEGIN"` in act mode.

- [ ] **Step 1: Tests.**
  - **`test_flow.gd`:**
    - the four new entries lead where listed;
    - `results:title` still leads nowhere;
    - all six screens are reachable.
  - **`test_draft.gd`:** a `PrepareScreen` set up with `MissionBook.long_night().act("festival")` has `draft.slots == 4`, `draft.capacity == 10`, and no difficulty arrows (`hit()` never returns them).
  - **A new block in `tests/test_flow.gd`, for `InterludeScreen`:**
    - With two choices, `chosen == ""` until `choose("procession")`. The "draft" action is refused (buzz, no emit) while nothing is chosen.
    - With one choice, it is chosen at setup.
    - `card_rect(0, 2)` and `card_rect(1, 2)` fit inside 640×360 and do not overlap.
- [ ] **Step 2: `InterludeScreen`.** It follows `ResultsScreen`'s structure: a `CanvasLayer` at layer 10, a dim over the frozen mission, a framed panel, `Menu` buttons and `UiTheme`.
  - **Top:**
    - the act's name;
    - ✔ or ✘ for `result.goal.done` (`UiTheme.mark`) with the goal label;
    - each bonus with its mark;
    - `"Time m:ss"`.
  - **With choices.size() == 2: two cards side by side.** Each shows:
    - the act's name;
    - `brief[0]` and `brief[1]`;
    - each line of `events_text` (empty until M3/M4);
    - `card_line(night)` in gold.

    Clicks, Left/Right and Enter choose a card.
  - **With one choice:** a single line, "Next: Act III: Judgement", plus its `card_line`.
  - **Buttons:** `"Choose powers"` (`draft`) and `"Missions"` (`missions`). Esc emits `missions`.
  - **Sounds:** as on the board.
- [ ] **Step 3: Prepare in act mode.**
  - Add `var confirm_label := "MANIFEST"`; `_draw_loadout` draws it in place of the literal.
  - The panel's goal lines come from the act (it is a MissionDef).
- [ ] **Step 4: Game.**
  - Add `INTERLUDE` and the FLOW entries.
  - Add the fields `var _between_acts := false`, `var _next_path := ""` and `var _interlude: InterludeScreen`.
  - **`_build_mission()`:** also `mission.act_over.connect(_on_act_over)`.
  - **`_on_act_over(res)`:**

```gdscript
func _on_act_over(res: Dictionary) -> void:
	_between_acts = true
	_next_path = ""
	result = res
	save.remember_loadout(mission_id, loadout)
	save.save_to(save_path)
	on_action("mission:act_over")
```

  - **`go_to()`:**
    - Keep `_mission` when `to == INTERLUDE`, or `to == PREPARE and _between_acts`, as well as for RESULTS.
    - INTERLUDE freezes the mission like RESULTS, then builds the interlude with `(result, _mission.next_choices(), _mission.night())` and connects its action:
      - `"draft"`: set `_next_path = _interlude.chosen` and call `on_action("interlude:draft")`;
      - `"missions"`: `on_action("interlude:missions")`.
    - In PREPARE with `_between_acts`, build Prepare from the next act: `_mission.act()`'s choice `_next_path`, or the only next act. Use `prep.setup(next_act_def, loadout, save.difficulty)` and `prep.confirm_label = "BEGIN"`.
    - Any screen other than INTERLUDE or PREPARE sets `_between_acts = false`.
  - **`_on_prepare_action`:** while `_between_acts`, a manifest sets `loadout` and saves it, then calls `on_action("prepare:begin")`, and `back` calls `go_to(Screen.INTERLUDE)`.
  - **`on_action()`:** `prepare:begin` calls `_continue_night()` instead of `_faded_into_mission()`.
  - **`_continue_night()`:**

```gdscript
## On into the next act of the night, behind the same fade as a fresh mission: the same Mission node continues.
func _continue_night() -> void:
	if _fading or not is_instance_valid(_mission):
		return
	_fading = true
	await _fader.fade_out(FADE_OUT)
	if is_instance_valid(_screen_node):
		_screen_node.queue_free()
		_screen_node = null
	_between_acts = false
	screen = Screen.MISSION
	_mission.next_act(loadout, _next_path)
	_mission.set_frozen(false)
	Music.play(&"battle")
	await get_tree().process_frame
	await get_tree().process_frame
	await _fader.fade_in(FADE_IN)
	_fading = false
```

  - **`_on_mission_finished`:** set `_between_acts = false` first.
- [ ] **Step 5: Run the tests.** Capture the interlude with a new `--show=interlude`. It builds Game's sample: `SAMPLE_WARNING_RESULT`, the Long Night's two Act II choices, and an empty night. Check the capture.
- [ ] **Step 6: Commit.** Message: `feat: the interlude between acts -- the act's result, the choice card, Prepare with BEGIN (v0.09)`.

### Task 5: The FLOW test plays a night

**Files:** Modify `src/game/game.gd` (`_flow_test`).

- [ ] **Step 1: Add a pass to `_flow_test()`**, after The Warning's pass and before the final back-to-title steps:
  1. From the board, `choose(LONG_NIGHT)`. Prepare shows 4 slots; preselect the default loadout and MANIFEST.
  2. After the intro: `_mission.act().id == "omen"`. Set `_mission.rules().time_left = 0.01`, which wins on the omen. Wait for `screen == INTERLUDE` (up to 6 s; the ending takes 3 s).
  3. The interlude has two choices. `choose("festival")`, then emit `draft`: PREPARE shows the BEGIN label with the mission still alive (`is_instance_valid(_mission)`). MANIFEST continues to MISSION, and `_mission.act().id == "festival"` with `_mission.night().path == "festival"`.
  4. Count one destroyed building exactly once: call `_mission.rules()._on_structure_destroyed(<a house>, &"stone")` directly, and check `buildings_down == 1`. Only one Rules is connected, which covers review focus 2.
  5. Set `time_left = 0.01`: INTERLUDE with one choice. Draft and BEGIN: `act().id == "judgement"`.
  6. Set `time_left = 0.01`: RESULTS with `result.acts.size() == 3`, `result.path == "festival"`, `result.has("rank")`, and reason `"timeout"`.
  7. **Review focus 2:** start a new night. During Act I, open Pause and choose Restart: a fresh night, with `act().id == "omen"` and `night().results.is_empty()`. Then Pause → Missions → the board, with the mission gone.
  8. Back to the title, as today.
- [ ] **Step 2: Run FLOW** three times in a row. Each run has 0 failures.
- [ ] **Step 3: Commit.** Message: `test: the screen flow plays a whole night (v0.09)`.

### Task 6: The night's results, save and board card

**Files:**
- Modify: `src/game/ui/results_screen.gd`, `src/game/save_file.gd`, `src/game/ui/mission_board.gd`, `src/game/game.gd` (`SAMPLE_NIGHT_RESULT`, `--show=results-night`)
- Modify tests: `tests/test_results.gd`, `tests/test_save_file.gd`

**Interfaces:**
- Produces:
  - `SaveFile.best(id)` adds `"paths_won": PackedStringArray`.
  - `record()`: a won night adds its `path`; that is a new best when the path is new, or when the score is better.
  - `ResultsScreen._draw_night()`, used when the result `has("acts")`.
  - `MissionBoard.best_marks()` for a night: `"Festival ✔  Procession ✘"`, plus the best rank.

- [ ] **Step 1: Tests.**
  - **`test_save_file.gd`:**
    - a won night `{"score": 12000, "rank": "B", "won": true, "path": "festival", "acts": [...]}` is a new best, and `best("long_night").paths_won == ["festival"]`;
    - the same score on the procession path is a new best (a new path);
    - a lower score on a known path is not;
    - a lost night adds no path;
    - **review focus 5:** a save file with no `mission.long_night` section loads `paths_won` empty, `loadout_for("long_night")` is empty, and the board shows "Not yet played".
  - **`test_results.gd`:** `title_for(true, "citadel")` is unchanged.
- [ ] **Step 2: SaveFile.**
  - `_entry()` defaults to `"paths_won": PackedStringArray()`.
  - `save_to` and `load_from` write and read `paths_won`.
  - In `record()`'s scored branch, before the score comparison:

```gdscript
		var new_path := false
		var path := String(result.get("path", ""))
		if won and path != "" and not (entry.paths_won as PackedStringArray).has(path):
			(entry.paths_won as PackedStringArray).append(path)
			new_path = true
```

  - It returns `new_path or <the score was better>`, keeping the existing assignments.
- [ ] **Step 3: Results.** `_draw_night()` is drawn when `_result.has("acts")`:
  - the title (`title_for`);
  - the rank and score as in the scored layout;
  - on the right, one row per act: the act's name (`MissionBook.long_night().act(id).name`), its mark, and its bonuses' marks;
  - a "Path: The Festival" row;
  - Act III's `lines` underneath, if they fit. Otherwise show only the night total.

  Add `SAMPLE_NIGHT_RESULT` with `--show=results-night`, capture it and check it.
- [ ] **Step 4: Board.** The night card's foot reads `best_line()` (the best rank), then the path marks.
- [ ] **Step 5: Run the tests and FLOW, then commit.** Message: `feat: the night's results, its save (paths won) and its board card (v0.09)`.

### Task 7 (controller): M1 gate

- [ ] Run every gate in the Global Constraints.
  - Last Judgement and The Warning: identical, including the 10 behaviour checksums.
  - `--scenario=night` with each `--act1/--act2/--act3` combination of win and lose on both paths: 8 runs, no SCRIPT ERROR.
- [ ] Capture the board, the interlude and the night's results.
- [ ] Append the results under `## Execution notes` → `### M1 gate`, commit, tag `kak-v009-m1`, push, and update the ledger (the `ln-plan` card done; an M1 card done).

---

## Milestone 2 — The town between acts and timed events

### Task 8: `Crowd.raise_profile`

**Files:**
- Modify: `src/game/response_profile.gd`, `src/game/crowd/crowd.gd`, `src/game/crowd/banishing_rite.gd`, `src/game/crowd/river_ferry.gd`, `src/game/town/town.gd`, `src/game/mission.gd`
- Create: `tests/test_raise.gd`

**Interfaces:**
- Produces:
  - `ResponseProfile.level() -> int`: Unprepared 0, Unaware 1, Organized 2, Prepared 3, God-Resistant 4.
  - `BanishingRite.off_by_profile: bool` and `RiverFerry.off_by_profile: bool`: they were ENDED only because the profile lacked them.
  - `Town.open_postern()`: the inverse of `bar_postern()`.
  - `Crowd.raise_profile(p: ResponseProfile) -> PackedStringArray`, returning what turned on (`"rite"`, `"boats"`, `"engineers"`, `"marshals"`).
  - `Crowd.hold_gate(g: Structure, seconds: float)`, `Crowd.forgo_rally()`.
  - `Mission.next_act()` raises the town to `_act.town(_night)`, calls `_wire_responses()`, and shows a banner when anything turned on: `"THE TOWN PREPARES: " + ", ".join(names).to_upper()`.

- [ ] **Step 1: Write `tests/test_raise.gd`.** Use `_crowd(ResponseProfile.Tier.ORGANIZED)`, but set `crowd.profile = ResponseProfile.unaware()` before `spawn()`. The cases:
  - **Never lower:** `raise_profile(ResponseProfile.unaware())` on an Organized town returns `[]` and the profile is unchanged.
  - **Unaware to Organized:** `escorts_per_duty` becomes 1, and nothing new turns on (`[]`, since Organized has no rite, boats or engineers).
  - **Organized to Prepared:**
    - it returns `rite`, `boats`, `engineers` and `marshals`;
    - `crowd.rite.state == IDLE`, `crowd.ferry.state == MOORED`, `crowd.engineers.teams.size() == 2`;
    - the postern is walkable;
    - the soldiers with `corps == MARSHAL` number `4 * 4` (marshals per exit times exits with boats). Count them.
  - **Responses already due:** with the alarm already at City Emergency (`crowd.alarms.update(AlarmManager.CITY_ALARM, 0, 0.0)` and then a few steps), raising to Prepared begins the rite gathering (state `GATHERING`) and `engineers.active`.
  - **Review focus 3:** destroy the cathedral, then raise to Prepared: `rite` is not in the returned list, the rite stays ENDED, and there is no error. The same holds for a destroyed dock and the boats.
  - **`hold_gate(main_gate, 5)`:** no one passes for 5 s of `advance`, then they pass. Watch `waiting_at(main_gate)` grow, then shrink.
  - **`forgo_rally()`:** a later `rally()` moves nobody to the ring.
- [ ] **Step 2: Implement.**
  - **`ResponseProfile.level()`:** `return 1 if title == "Unaware" else [0, 2, 3, 4][tier]`.
  - **`BanishingRite.setup` and `RiverFerry.setup`:** set `off_by_profile = not crowd.profile.rite` (or `boats`) at the line where the state becomes ENDED.
  - **`Town.open_postern()`:** read `bar_postern()` (`town.gd:142`) and write its inverse: the postern walkable and its art opened. The caller refreshes the grid.
  - **`Crowd`:** store the spawn's workshop point as `var _workshop := Vector2.INF`, set in `spawn()`. Then:

```gdscript
## Raise the town's readiness mid-mission (v0.09, between the acts of a night): never lower. Responses the old profile
## lacked turn on -- the rite, the boats (and the postern), the engineers, more marshals -- unless their building is
## gone; ones already due by the alarm stage start at once. Returns what turned on.
func raise_profile(p: ResponseProfile) -> PackedStringArray:
	var on := PackedStringArray()
	if p.level() <= profile.level():
		return on
	profile = p
	alarms.regroup_seconds = p.regroup_seconds
	if bell != null and bell.state in [BellNetwork.State.IDLE, BellNetwork.State.WAITING]:
		bell.climb = p.bell_climb
	if p.rite and rite != null and rite.off_by_profile:
		rite = BanishingRite.new().setup(self, _env, _grid)
		if rite.state != BanishingRite.State.ENDED:
			on.append("rite")
	if p.boats and ferry != null and ferry.off_by_profile:
		if is_instance_valid(_town.postern) and not _town.postern.walkable and not _town.postern.destroyed:
			_town.open_postern()
			_grid.refresh(_town.postern)
		ferry = RiverFerry.new().setup(self, _env, _grid, _field)
		if ferry.state != RiverFerry.State.ENDED:
			evac.add_boat_exit(ferry.board_at, ferry)
			on.append("boats")
	if p.engineer_teams > 0 and engineers != null and engineers.teams.is_empty():
		engineers = EngineerManager.new().setup(self, _env, _grid, _town, _appoint_engineers(_workshop), _workshop)
		if not engineers.teams.is_empty():
			on.append("engineers")
	if _raise_marshals() > 0:
		on.append("marshals")
	if alarms.stage >= AlarmManager.Stage.CITY_EMERGENCY:
		if on.has("rite"):
			rite.begin()
		if on.has("engineers"):
			engineers.begin()
	if alarms.stage >= AlarmManager.Stage.EVACUATION:
		if on.has("boats"):
			ferry.begin()
		if marshals != null:
			marshals.begin()
	return on


## More marshals for a raised profile: soldiers on the walls without a role take it, in post order, up to the new count.
func _raise_marshals() -> int:
	var exits := 2 + (2 if profile.boats else 0)
	var want := profile.marshals_per_exit * exits
	var have := 0
	for p in soldiers:
		if is_instance_valid(p) and p.is_alive() and p.corps == Person.Corps.MARSHAL:
			have += 1
	var added := 0
	for i in range(POST_YARD, mini(POST_YARD + POST_WALLS, soldiers.size())):
		if have + added >= want:
			break
		var p := soldiers[i]
		if is_instance_valid(p) and p.is_alive() and p.corps == Person.Corps.NONE:
			p.corps = Person.Corps.MARSHAL
			added += 1
	return added


## Hold a gate shut for `seconds` (v0.09: the festival's crowd jams the gates): its queue waits, nobody passes.
func hold_gate(g: Structure, seconds: float) -> void:
	_held[g] = _clock + seconds


## The leaderless town (v0.09: the Prince died unseen): the soldiers never rally on the Citadel.
func forgo_rally() -> void:
	_rallied = true
```

  - **Holding a gate:**
    - Add `var _held := {}` beside `_jams`.
    - In `_gates()`, a held gate is treated like a blighted one: `and not gate.blighted and _clock >= float(_held.get(gate, -1.0))`.
    - `clear()` empties `_held`.
  - **Rescue squads are not raised.** `RescueManager` groups its squads at setup. Note this in the doc comment.
  - **`Mission.next_act()`:** after `_act = …`, add:

```gdscript
	var raised := _crowd.raise_profile(_act.town(_night))
	_wire_responses()
```

    After `_build_act()`, if `raised` is not empty, emit `_rules.banner.emit("THE TOWN PREPARES: " + ", ".join(raised).to_upper())`.
- [ ] **Step 3: Run the tests and every exact gate.** They are unchanged: `raise_profile` only runs between the acts of a night.
- [ ] **Step 4: Run the night scenario.** `--scenario=night --path=procession --act1=lose --act2=win --act3=lose` prints Act II's town as Organized and Act III's as Organized.
  - Prince outcomes are not set until M4. Until then, add a temporary `--prince=seen` option to `_force_act` that writes `mission.night().prince` before the act ends. Keep it as a documented test aid.
  - With it, Act III reads Prepared.
- [ ] **Step 5: Commit.** Message: `feat: the town rises between acts -- Crowd.raise_profile, held gates, a forgone rally (v0.09)`.

### Task 9: Timed events and the HUD's event strip

**Files:**
- Create: `src/game/mission/event_timeline.gd`, `tests/test_events.gd`
- Modify: `src/game/mission/mission_director.gd` (type `timeline`), `src/game/ui/hud.gd`, `tests/test_hud.gd`

**Interfaces:**
- Produces:
  - `EventTimeline`:
    - `signal fired(id: String, label: String)`;
    - `add(at: float, id: String, label: String, fn := Callable()) -> EventTimeline`;
    - `step(delta: float)`, `upcoming(n := 2) -> Array[Dictionary]` (each `{"at", "id", "label", "in"}`);
    - `fired_ids() -> PackedStringArray`, `elapsed() -> float`.
  - `Hud.event_rows() -> Array`: `[["0:23", "The bonfire lights"], …]`.

- [ ] **Step 1: Write `tests/test_events.gd`.** The cases:
  - Events added out of order fire in time order, each once, with `fired` emitted.
  - A big `step(100)` fires every due event in order.
  - `upcoming(2)` lists the next two with their `in`. After all have fired it is empty.
  - An event's `fn` runs once.
  - An event added after its time has passed fires on the next `step`.
  - **HUD (in `test_hud.gd`):**
    - with a director whose `timeline` has events at 45 and 90, `event_rows()` after 10 s is `[["0:35", …], ["1:20", …]]`;
    - with no timeline, `[]`.
- [ ] **Step 2: Implement `EventTimeline`:**

```gdscript
class_name EventTimeline
extends RefCounted
## An act's timed events (v0.09): each fires once, in time order, when the act has run `at` seconds -- its callback, then
## `fired` (the director shows it as a banner). The HUD shows the next few so the player can see the windows coming.

signal fired(id: String, label: String)

var _events: Array[Dictionary] = []
var _elapsed := 0.0


func add(at: float, id: String, label: String, fn := Callable()) -> EventTimeline:
	_events.append({"at": at, "id": id, "label": label, "fn": fn, "done": false})
	_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.at) < float(b.at))
	return self


func step(delta: float) -> void:
	_elapsed += delta
	for e in _events:
		if bool(e.done) or float(e.at) > _elapsed:
			continue
		e.done = true
		if (e.fn as Callable).is_valid():
			(e.fn as Callable).call()
		fired.emit(String(e.id), String(e.label))


func upcoming(n := 2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in _events:
		if not bool(e.done) and out.size() < n:
			out.append({"at": e.at, "id": e.id, "label": e.label, "in": maxf(float(e.at) - _elapsed, 0.0)})
	return out


func fired_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for e in _events:
		if bool(e.done):
			out.append(String(e.id))
	return out


func elapsed() -> float:
	return _elapsed
```

  - **`MissionDirector`:** type it as `var timeline: EventTimeline`.
  - **`Hud`:**
    - `event_rows()` reads `_rules.director.timeline.upcoming(2)` when present, giving `[UiTheme.clock(in), label]`.
    - Draw them centred under the clock at `EVENTS_TOP := 44.0`, below the rite's bar: dim time, light label, on a `COL_PANEL` plate.
    - Add the rows to `_signature()`.
- [ ] **Step 3: Run the tests, then commit.** Message: `feat: timed events for an act, and the HUD's strip of what comes next (v0.09)`.

### Task 10: Act III — Judgement's director

**Files:**
- Create: `src/game/mission/judgement_director.gd`, `src/game/mission/dawn_objective.gd`, `tests/test_judgement.gd`
- Modify: `src/game/crowd/river_ferry.gd` (`close(reason)`), `src/game/mission/mission_book.gd` (Judgement's director, bonus and `events_text`)

**Interfaces:**
- Consumes: `NightState` (Task 1), `raise_profile`, `hold_gate` and `forgo_rally` (Task 8), `EventTimeline` (Task 9).
- Produces:
  - `JudgementDirector`;
  - `DawnObjective` (a bonus, label "Dawn never comes", FAILED once `time_left < DAWN_LEFT` 30);
  - `RiverFerry.close(reason: String)`: the boats stop taking people.
  - **Constants:** `JAM_SECONDS := 40.0`, `RITE_AT := 90.0`, `BOATS_AT := 120.0`, `LAST_FERRY_AT := 150.0`.

**Carry-overs** in `_begin()`, from the night:

| Night | Act III start |
|---|---|
| `festival == "broken"` | every walkable gate held for `JAM_SECONDS`; every living person in `night.festival_broke` flees |
| `festival == "held"` | `crowd.marshals.begin()` (the marshals hold the gates from the start) |
| `prince == "escaped"` | `crowd.rally()` |
| `prince == "unseen"` | `crowd.forgo_rally()` |

**Events**, each added only when the response exists:
- `RITE_AT` "The clergy gather": `rite.begin()`, when `crowd.rite.state == IDLE`.
- `BOATS_AT` "The boats sail": `ferry.begin()`, when `ferry.state == MOORED`.
- `LAST_FERRY_AT` "The last ferry leaves": `ferry.close("the last ferry")`, when the ferry is not ENDED.

- [ ] **Step 1: Write `tests/test_judgement.gd`.** Each case builds a Prepared or Organized crowd, a `Rules` for `MissionBook.long_night().act("judgement")` with a prepared `NightState`, and a `JudgementDirector` set up with that night. The cases:
  - **Festival broken:** with 5 citizens in `night.festival_broke`, after `_begin`:
    - each is `FLEE`;
    - the Main Gate lets nobody out for 39 s, then does.
  - **Festival held:** `crowd.marshals.active`.
  - **The Prince escaped:** `crowd._rallied` is true and soldiers walk to the ring. The escape limit is 40: an `EscapeLimitObjective` in `rules.objectives` with `limit == 40`.
  - **The Prince unseen:** `forgo_rally()`, so a City Emergency later rallies nobody.
  - **Events on a Prepared town:**
    - the timeline lists "The clergy gather", "The boats sail" and "The last ferry leaves";
    - at 90 s the rite is GATHERING;
    - at 120 s the ferry is LOADING or AWAY;
    - at 150 s it is closed.
  - **On an Organized town:** none of those events.
  - **Review focus 3:** the cathedral destroyed before `_begin`: no rite event, and no error.
  - **`DawnObjective`:**
    - won with 31 s left: earned (`rules.result().bonuses`);
    - won with 29 s left: not earned.
- [ ] **Step 2: Implement.**
  - **`RiverFerry.close(reason)`:** read the private `_stop()` and expose it as `close(reason: String)` with the same effect. If `_stop()` already takes a reason, `close()` just calls it.
  - **`JudgementDirector`:**

```gdscript
class_name JudgementDirector
extends MissionDirector
## Act III of The Long Night (v0.09): Last Judgement in the town the night has made. It starts the night's carry-overs --
## a broken festival's crowd still fleeing into gates it jams, marshals already at the gates, a rallied or a leaderless
## Citadel -- and runs the act's windows: the clergy gather, the boats sail, the last ferry leaves.

const JAM_SECONDS := 40.0
const RITE_AT := 90.0
const BOATS_AT := 120.0
const LAST_FERRY_AT := 150.0


func _begin() -> void:
	timeline = EventTimeline.new()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	var n := night if night != null else NightState.new()
	if n.festival == "broken":
		for g in town.gates:
			if is_instance_valid(g) and g.walkable:
				crowd.hold_gate(g, JAM_SECONDS)
		for p in n.festival_broke:
			if is_instance_valid(p) and p.is_alive():
				p.flee()
	elif n.festival == "held" and crowd.marshals != null:
		crowd.marshals.begin()
	if n.prince == "escaped":
		crowd.rally()
	elif n.prince == "unseen":
		crowd.forgo_rally()
	if crowd.rite != null and crowd.rite.state == BanishingRite.State.IDLE:
		timeline.add(RITE_AT, "rite", "The clergy gather", func() -> void: crowd.rite.begin())
	if crowd.ferry != null and crowd.ferry.state != RiverFerry.State.ENDED:
		timeline.add(BOATS_AT, "boats", "The boats sail", func() -> void: crowd.ferry.begin())
		timeline.add(LAST_FERRY_AT, "last_ferry", "The last ferry leaves", func() -> void: crowd.ferry.close("the last ferry"))


func step(delta: float) -> void:
	timeline.step(delta)
```

  - **Check:** whether the Town's gates list is `town.gates`. If it is named differently, use the name Mission uses in `_mission_test` / `_clip_report` (`mission._town.gates`).
  - **`DawnObjective`:** `label = "Dawn never comes"`, `reason = "dawn"`, `const DAWN_LEFT := 30.0`. `check` returns FAILED when `rules.time_left < DAWN_LEFT`, else PENDING. `hud_text` gives `"Dawn never comes"`.
  - **The book:** Judgement gets `a.director = JudgementDirector`, `a.make_act_bonuses = func(_n): return [DawnObjective.new()]` (typed array), and `a.events_text = ["1:30 The clergy gather (if Prepared)", "2:00 The boats sail", "2:30 The last ferry leaves"]`.
- [ ] **Step 3: Run the tests, every exact gate and the night scenario.** The night scenario covers both paths and the forced outcomes.
- [ ] **Step 4: Commit.** Message: `feat: Act III Judgement -- the night's carry-overs and its windows (v0.09)`.

### Task 11 (controller): M2 gate

- [ ] Run every gate; Last Judgement and The Warning are unchanged.
- [ ] **The night scenario, for each row of spec §2:** use `--prince=`, and the forced festival outcome (`--festival=broken|held`, written the same way as `--prince` until M3). Check that each row's Act III town and carry-overs are as the table says, and record the lines.
- [ ] Capture the HUD's event strip in Act III.
- [ ] Notes, then commit, tag `kak-v009-m2`, push, and update the ledger.

---

## Milestone 3 — Act II-A, The Festival

### Task 12: The Mayor, and the festival crowd

**Files:**
- Modify:
  - `src/game/crowd/citizen_profile.gd` (`Role.MAYOR`, `Role.NOBLE`, appended);
  - `src/game/crowd/routine_manager.gd` (`WEIGHTS` for both);
  - `src/game/crowd/person.gd` (both looks, both art paths);
  - `src/environment/art/people_art.gd` (`CITIZEN` entries and stand-ins)
- Create: `src/game/mission/festival_director.gd`, `src/fx/omen/bonfire.gd`, `tests/test_festival.gd`
- Modify: `src/game/mission/mission_book.gd` (the Festival act's director)

**Interfaces:**
- Produces:
  - `CitizenProfile.Role.MAYOR` and `Role.NOBLE`, both after `WATCHMAN`.
  - `RoutineManager.WEIGHTS[MAYOR] = [0.3, 0.6, 0.1, 0.0]` and `WEIGHTS[NOBLE] = [0.9, 0.0, 0.1, 0.0]`.
  - **The looks:**
    - procedural: MAYOR in a dark red robe (`MAYOR_ROBE := Color("7a1e22")`) with a gold chain of office (`MAYOR_CHAIN`, 3 px across the chest); NOBLE in a purple cape (`NOBLE_CAPE := Color("4a2a6a")`) with a gold crown (`NOBLE_CROWN`, 3×1 px plus 3 points);
    - sprite path: `PeopleArt.CITIZEN` gains `["mayor"]` and `["noble"]`, with `STAND_INS["mayor"] = "merchant_a"` and `STAND_INS["noble"] = "resident_a"`. `_draw_sprite` draws the chain or crown pixels over the stand-in, as it draws the watchman's lantern (`_is_watchman()`, `_sprite_lantern()`).
  - **`FestivalDirector`:**
    - `goers: Array[Person]`, `mayor: Person`, `need := FESTIVAL_NEED`;
    - `count() -> int`, `broken() -> bool`, `broke_list() -> Array[Person]`;
    - constants `FESTIVAL_CROWD := 80`, `FESTIVAL_NEED := 50`, `PACK_R := 3.0`, `SAMPLE := 0.25`, `GUARDS := 6`.
  - `BonfireFx` (a `FxTimeline`): flames and a ground light at its origin for `extra.seconds`. **No impact, no threat, no damage.**

- [ ] **Step 1: Write `tests/test_festival.gd`.** Use the `_setup()` pattern from `test_warning.gd`, with `MissionBook.long_night().act("festival")`, a crowd at `unaware()`, and the `FestivalDirector`. The cases:
  - **The crowd:** `goers.size() == FESTIVAL_CROWD`. None of them is the bellkeeper, the watchman, clergy, an engineer or the Mayor. Each has `stay_left > 100` and a goal inside `MARKET_SQUARE.grow(0.5)`.
  - **The Mayor:** his role is MAYOR, and he is not a goer.
  - **Counting:** panic 10 goers (`p.panic(p.ground_pos, 1.0)`), sample, and `count() == 10`. Kill 5 others (`field.kill`): `count() == 15`.
  - **Guards:** with `night.bell_rang = true` at setup, `GUARDS` soldiers have anchors inside the square. Without it, none do.
  - **Looks:** a citizen given role MAYOR draws without error on both art paths. Call `queue_redraw()` and `_draw_body(0, 0)` through a test node if needed. Otherwise check that `PeopleArt.design_for(false, CitizenProfile.Role.MAYOR, 0, 0)` returns `"merchant_a"`, the stand-in.
- [ ] **Step 2: Implement the roles and looks.**
  - Check `PeopleArt.wanted()`'s clamp: the role index must reach the new entries.
  - **The chain and crown:** add `_is_mayor()` and `_is_noble()` like `_is_watchman()`. In the procedural `_draw_citizen`, the robe and cape follow the bellkeeper and watchman coat branch.
  - **A new role's look is in no signature.** The role is set before the first draw. In the director, set the role before any frame passes.
- [ ] **Step 3: Implement `FestivalDirector`** (the crowd part; the events come in Task 13):

```gdscript
class_name FestivalDirector
extends MissionDirector
## Act II-A of The Long Night (v0.09): the Feast of Lanterns. FESTIVAL_CROWD citizens fill the market square and stay;
## bonfires light it; the Mayor is among them. The festival is broken when FESTIVAL_NEED of the goers are dead or have
## broken and fled (a fright, flight or a dash for shelter). If the bell rang in Act I, GUARDS soldiers watch the square.

const FESTIVAL_CROWD := 80
const FESTIVAL_NEED := 50
const PACK_R := 3.0
const SAMPLE := 0.25
const GUARDS := 6
const SKIP_ROLES := [CitizenProfile.Role.BELLKEEPER, CitizenProfile.Role.WATCHMAN, CitizenProfile.Role.CLERGY,
	CitizenProfile.Role.ENGINEER, CitizenProfile.Role.MAYOR, CitizenProfile.Role.NOBLE]
const BROKE_MINDS := [Person.Mind.PANIC, Person.Mind.FLEE, Person.Mind.SHELTER]

var goers: Array[Person] = []
var mayor: Person
var need := FESTIVAL_NEED
var _broke := {}
var _sample_in := 0.0


func _begin() -> void:
	timeline = EventTimeline.new()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	mayor = _appoint_mayor()
	_gather()
	if night != null and night.bell_rang:
		_post_guards()
	if ctx != null:
		for at in [TownLayout.MARKET_SQUARE.get_center() + Vector2(-2.0, -2.5), TownLayout.MARKET_SQUARE.get_center() + Vector2(2.5, 2.0)]:
			FxTimeline.cast(BonfireFx, ctx, at, {"seconds": rules.time_left})


## The merchant living nearest the market square is the Mayor tonight.
func _appoint_mayor() -> Person:
	var best: Person = null
	var c := TownLayout.MARKET_SQUARE.get_center()
	for p in crowd.citizens:
		if WarningDirector._alive(p) and p.profile != null and not p.inside \
				and p.profile.role == CitizenProfile.Role.MERCHANT \
				and (best == null or p.profile.home.distance_to(c) < best.profile.home.distance_to(c)):
			best = p
	if best != null:
		best.profile.role = CitizenProfile.Role.MAYOR
	return best


## The FESTIVAL_CROWD calm citizens nearest the square walk to a spot in it and stay.
func _gather() -> void:
	var c := TownLayout.MARKET_SQUARE.get_center()
	var pool: Array[Person] = []
	for p in crowd.citizens:
		if WarningDirector._alive(p) and p.profile != null and not p.inside and not p.profile.role in SKIP_ROLES \
				and p.mind in WarningDirector.RESUMABLE:
			pool.append(p)
	pool.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_squared_to(c) < b.ground_pos.distance_squared_to(c))
	for p in pool.slice(0, FESTIVAL_CROWD):
		goers.append(p)
		_send(p, crowd._spot_near(c, TownLayout.MARKET_SQUARE.size.x * 0.4))


func _send(p: Person, at: Vector2) -> void:
	p.mind = Person.Mind.CALM
	p.stay_left = 1000.0
	p.last_place = RoutineManager.Place.LEISURE
	p.walk_to(at)


## The bell rang in Act I: soldiers with no role, nearest the square, stand watch in it.
func _post_guards() -> void:
	var c := TownLayout.MARKET_SQUARE.get_center()
	var pool: Array[Person] = []
	for s in crowd.soldiers:
		if WarningDirector._alive(s) and s.corps == Person.Corps.NONE and s.mind == Person.Mind.POST:
			pool.append(s)
	pool.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_squared_to(c) < b.ground_pos.distance_squared_to(c))
	for s in pool.slice(0, GUARDS):
		s.send_to_post(crowd._spot_near(c, 3.0), false, true)


func step(delta: float) -> void:
	timeline.step(delta)
	_sample_in -= delta
	if _sample_in <= 0.0:
		_sample_in = SAMPLE
		for p in goers:
			if is_instance_valid(p) and p.is_alive() and p.mind in BROKE_MINDS:
				_broke[p] = true


func count() -> int:
	var n := 0
	for p in goers:
		if not is_instance_valid(p) or not p.is_alive() or _broke.has(p):
			n += 1
	return n


func broken() -> bool:
	return count() >= need


func broke_list() -> Array[Person]:
	var out: Array[Person] = []
	for p in goers:
		if is_instance_valid(p) and p.is_alive() and _broke.has(p):
			out.append(p)
	return out


func carry(n: NightState) -> void:
	n.festival_broke = broke_list()


func report() -> Dictionary:
	return {"festival": "broken" if broken() else "held", "festival_count": count()}
```

  - **Freed goers:** `count()` counts a freed goer (one who escaped) as broken. That is consistent with "fled".
  - **`step()`:** call `timeline.step` before sampling.
  - **`BonfireFx`:** `duration = extra.get("seconds", 150.0)` and `busy = 0.0`. It uses `FxParts.ground_light` with a warm colour and a flame emitter, modelled on `will_o_wisp.gd`'s light and motes. Read `src/fx/omen/falling_star.gd` for this project's no-impact style. There is no `ctx.impact` call.
  - **The book:** the Festival act gets `a.director = FestivalDirector`.
- [ ] **Step 4: Run the tests and every exact gate.** The new roles are appended, so the checksums are unchanged.
- [ ] **Step 5: Commit.** Message: `feat: the Festival's crowd, its Mayor and bonfires; the Mayor's and the Prince's looks (v0.09)`.

### Task 13: The Festival's events, objective and bonus

**Files:**
- Create: `src/game/mission/festival_objective.gd`, `src/game/mission/bell_quiet_objective.gd`
- Modify: `src/game/mission/festival_director.gd`, `src/game/mission/mission_book.gd`, `tests/test_festival.gd`

**Interfaces:**
- Produces:
  - **The events:**
    - `BONFIRE_AT := 45.0`, "The bonfire lights": every calm goer walks to a spot within `PACK_R` of the fountain.
    - `ADDRESS_AT := 90.0`, "The Mayor's address": the Mayor goes on duty at the fountain (`go_duty`) for `ADDRESS_SECONDS := 30.0`, and the calm goers `observe(mayor, 30)`.
    - `ADDRESS_AT + ADDRESS_SECONDS`, "The address ends": `crowd.off_duty(mayor)`.
    - `CLOSE_AT := 150.0`, "The guard closes the square": no callback. The act's clock ends it.
  - **The Mayor's death,** at any time during the act: every living goer `panic(at, 1.0, &"mayor")`, and the banner `"THE MAYOR FALLS - THE FEAST BREAKS"`.
  - **`FestivalObjective`:** DONE when the director is `broken()`. Label `"Break the festival"`, `hud_text` `"Break the festival %d/%d"`, reason `"festival"`.
  - **`BellQuietObjective`** (a bonus, label `"Before the bell"`, reason `"bell_quiet"`): remembers on its first check whether the bell had already rung, and FAILS if it rings during the act.
  - **The act's objectives:** `[FestivalObjective, ClockObjective(false, "Square closes", "closed")]`. Bonus: `[BellQuietObjective]`. `events_text`: `["0:45 The bonfire lights", "1:30 The Mayor's address", "2:30 The guard closes the square"]`.
  - `make_card_line` keeps Task 1's line.

- [ ] **Step 1: Tests**, appended to `test_festival.gd`:
  - **The bonfire:** after 45 s, the calm goers' goals lie within `PACK_R + 0.5` of the fountain.
  - **The address:** at 90 s the Mayor is DUTY at the fountain, and at 120 s he is off duty.
  - **The Mayor's death:** kill him at 95 s, step once, and every living goer is PANIC. The banner fired, and `count() >= need`, so the act is won.
  - **Review focus 1:** kill the Mayor at 10 s. The 90 s and 120 s events then run without error and without sending a dead man anywhere. The panic still happened at 10 s. A null Mayor (no merchants) also works.
  - **The clock:** reaching 150 s without breaking the festival loses with reason `"closed"`. `report().festival == "held"`.
  - **`BellQuietObjective`:**
    - the bell rung before its first check: earned on a win;
    - rung during the act: not earned.
- [ ] **Step 2: Implement.**
  - In `_begin()`, add the events to the timeline. Each callback checks `WarningDirector._alive(mayor)` first.
  - Connect `crowd._field.enemy_killed` to catch the Mayor's death; disconnect it in `teardown()`.
  - The objectives follow `WarningObjective`'s pattern: `var d := rules.director as FestivalDirector`.
- [ ] **Step 3: Run the tests, the exact gates, and `--scenario=night --path=festival --act1=win`** with Act II played out (`--act2=skip`). Record the festival count at the end. Then capture a mid-festival frame:
  - add a `night` capture aid: `--shots` takes frames at 30, 50 and 95 s of Act II;
  - read the frames: the bonfires, the packed crowd, the Mayor on the fountain, the event strip.
- [ ] **Step 4: Commit.** Message: `feat: the Festival's windows -- the bonfire, the Mayor's address, the closing of the square (v0.09)`.

### Task 14 (controller): M3 gate

- [ ] Run every gate.
- [ ] Run the night on the festival path with Act II played, three times. Record the results, then tag `kak-v009-m3`, push, and update the ledger.

---

## Milestone 4 — Act II-B, The Procession

### Task 15: The Prince, his escort and the route

**Files:**
- Create: `src/game/mission/procession_director.gd`, `tests/test_procession.gd`
- Modify: `src/game/mission/mission_book.gd` (the Procession act's director)

**Interfaces:**
- Produces:
  - **`ProcessionDirector`:**
    - `prince: Person`, `attendants: Array[Person]`, `escorts: Array[Person]`;
    - `leg: int`, `route: PackedVector2Array`, `boarded: bool`, `unseen: bool`, `judged: bool`;
    - `frightened() -> bool`.
  - **Constants:**
    - `ATTENDANTS := 6`, `ESCORTS := 4`;
    - `ESCORT_R := 1.6`, `ESCORT_CLOSE := 0.8`, `ATTEND_R := 1.2`;
    - `TICK := 0.5`, `ARRIVE := 0.6`.
  - **The route,** from `_route()`, each point snapped to walkable ground:
    1. the Citadel's exit: `Vector2(CITADEL_COURT.get_center().x, CITADEL_COURT.end.y + 0.6)`;
    2. the cathedral steps: `Vector2(TEMPLE.get_center().x, TEMPLE.end.y + 0.5)`;
    3. the market's south side: `Vector2(MARKET_SQUARE.get_center().x, MARKET_SQUARE.end.y - 0.5)`;
    4. `DOCK_WAIT.get_center()`;
    5. the boarding point: `Vector2(DOCK.get_center().x, DOCK.position.y - 0.4)`.

**The rules:**
- **At `_begin`:**
  - the RESIDENT living nearest the Citadel becomes the Prince (role NOBLE) and is placed at route[0];
  - ATTENDANTS more residents are placed around him;
  - ESCORTS soldiers with no role from the Citadel's posts (soldier indices `POST_YARD + POST_WALLS` up to `+ POST_CITADEL`) escort him.
  - Each moved person gets the `_goal`/`_path`/`_target` reset that WarningDirector does.
- **Every TICK:**
  - When the Prince is in a calm mind (`RESUMABLE`) and not held by the blessing or the dock wait (Task 16): his mind becomes CALM and his `stay_left` is 1000. If he has no goal, he walks to `route[leg]`; on arrival (within ARRIVE) he moves on to the next leg.
  - The escorts `send_to_post(prince + offset_i, false, true)` on a ring of radius `ESCORT_CLOSE` when `frightened()`, else `ESCORT_R`. They are re-sent only if their anchor moved more than 0.3.
  - Attendants in a calm mind `walk_to(prince + offset)` on a radius-`ATTEND_R` ring, when they have no goal or their anchor is more than 0.5 off.
- `frightened()`: the Prince's mind is PANIC, FLEE or SHELTER.

- [ ] **Step 1: Write `tests/test_procession.gd`.** It follows `test_warning.gd`'s setup with the Procession act. The cases:
  - **The cast:**
    - the Prince is NOBLE, standing at route[0];
    - 6 attendants, and 4 soldier escorts each with corps NONE;
    - every route point is walkable.
  - **The walk:** with arrivals forced (`_arrive`), the Prince's goal moves along `route` leg by leg. He never runs: `walk_speed <= WALK_SPEED * pace + 0.01`.
  - **The escort:** after `prince.panic(...)` and one tick, every escort's anchor is within `ESCORT_CLOSE + 0.4` of the Prince.
  - **After a fright:** set his mind to RECOVER and tick: he walks his route again, not home.
  - **Review focus 1:** kill the Prince at t=0.1 (before any tick). Ticking then raises no error, and the act is won (Task 16's objective). For now, check `prince.is_alive() == false` and that 5 s of `rules.advance` raises no SCRIPT ERROR.
- [ ] **Step 2: Implement** with the rules above. The style follows `WarningDirector`: `_alive()`, `_clear_round`-free placement, and `crowd._spot_near` for the offsets.
- [ ] **Step 3: Run the tests and every exact gate, then commit.** Message: `feat: the Procession -- the Prince, his attendants and escort, walking to the dock (v0.09)`.

### Task 16: The Procession's events, objective and bonus

**Files:**
- Create: `src/game/mission/prince_objective.gd`, `src/game/mission/quiet_succession_objective.gd`
- Modify: `src/game/mission/procession_director.gd`, `src/game/mission/mission_book.gd`, `tests/test_procession.gd`

**Interfaces:**
- Produces:
  - **The events:**
    - `BLESSING_AT := 60.0`, "The blessing": the Prince holds at the cathedral steps until `BLESSING_AT + BLESSING_SECONDS` (`BLESSING_SECONDS := 20.0`). He waits there if he arrives early, and walks to the steps first if he is late. Up to `ONLOOKERS := 10` calm citizens within 8 of the steps `observe(prince, 20)`.
    - `SHIP_AT := 120.0`, "The ship docks": the Prince waits at `DOCK_WAIT` until then; afterwards he goes on to the boarding point.
    - `TIDE_AT := 150.0`, "The last tide": no callback. The clock ends the act.
  - **Boarding:** once he is within ARRIVE of the boarding point after `SHIP_AT`, `boarded = true` and `crowd.escape(prince)`. That counts toward Act II's escapes only, through `escaped_this_act`.
  - **His death:** caught on `enemy_killed`. `killed_by` is recorded as in WarningDirector. The kill is judged once `crowd._doomed.is_empty()`: `unseen = crowd.nearest_witness(at) == null`, then `judged = true`.
  - **`PrinceObjective`:** DONE when the Prince is dead; FAILED when `boarded` (reason `"sailed"`). Label `"Stop the Prince"`, reason `"prince"`.
  - **`QuietSuccessionObjective`** (a bonus, label `"A quiet succession"`): PENDING until judged, then FAILED unless `unseen`.
  - **`report()`:** `{"prince": "unseen" | "seen" | "escaped"}`. It is `"escaped"` when boarded, or alive at the act's end.
  - **The act:** objectives `[PrinceObjective, ClockObjective(false, "The tide", "tide")]`, bonus `[QuietSuccessionObjective]`. `events_text`: `["1:00 The blessing", "2:00 The ship docks", "2:30 The last tide"]`.
  - Task 8's temporary `--prince=` aid stays only for forcing outcomes in the scenario.

- [ ] **Step 1: Tests**, appended to `test_procession.gd`:
  - **The blessing:** forced arrival at the steps at 30 s: he stays until 80 s, then leaves. The onlookers are OBSERVE.
  - **The ship:** forced arrival at `DOCK_WAIT` at 100 s: he waits until 120 s, walks to the boarding point, boards, and the act is lost with reason `"sailed"`. `report().prince == "escaped"`.
  - **An unseen kill:** clear everyone within 3 (like `_clear_round` in `test_warning.gd`), kill him with `&"doom"`, and step twice: won with reason `"prince"`, the bonus earned, and `report().prince == "unseen"`.
  - **A seen kill:** one citizen at 1.0: won, the bonus not earned, `"seen"`.
  - **Review focus 1:** he dies before the blessing. The blessing and the ship events then do nothing, the onlookers are not called, and there is no error.
  - **The clock:** at 150 s with him alive and not boarded, lost with reason `"tide"` and `"escaped"`.
- [ ] **Step 2: Implement.**
  - Judge the kill as `WarningDirector._judge` does, waiting for `crowd._doomed` to empty.
  - The events must respect a dead Prince.
- [ ] **Step 3: Run the tests, the exact gates and the night on the procession path,** with Act II played out three times. Capture frames at the blessing and at the dock, and read them.
- [ ] **Step 4: Commit.** Message: `feat: the Procession's windows -- the blessing, the ship, a quiet succession (v0.09)`.

### Task 17 (controller): M4 gate

- [ ] Run every gate.
- [ ] Run the night on both paths. Remove the `--prince` and `--festival` forcing aids, or keep them documented as test aids.
- [ ] Tag `kak-v009-m4`, push, and update the ledger.

---

## Milestone 5 — Wrap-up

### Task 18: The `night` scenario plays the acts

**Files:** Modify `tools/dev/behaviour_check.gd`.

- [ ] **Step 1: Give `--act1/2/3=play` scripted policies.** Each prints a line per cast and an `end` line per act.
  - **Act I:** reuse the Warning `mix` policy (whisper the runner, then doom him when alone).
  - **The Festival:** at 95 s, Silent Doom on the Mayor, which is the windowed target. If his death is seen, it panics the crowd anyway. Then Discord on the densest goer cluster whenever it is ready.
  - **The Procession:** whisper an escort away when ready; Doom on the Prince when `nearest_witness(prince, prince) == null`.
  - **Act III:** the `judgement` greedy policy (Task 7 of v0.08) with the act's loadout.

  The Prepare re-draft between acts is simulated: the policy's loadout for each act is passed to `next_act()`.
- [ ] **Step 2: Run each path with all three acts on `play`,** three times each. Record every line in the Execution notes under `### Task 18 night scenario`.
- [ ] **Step 3: Commit.** Message: `tools: the night scenario plays each act with a policy (v0.09)`.

### Task 19: Balance

**Files:** `src/game/mission/mission_book.gd`, `night_state.gd`, `festival_director.gd`, `procession_director.gd`, `judgement_director.gd` (numbers only).

- [ ] **Step 1: Compare with the spec's intent.** Each act is winnable by a sensible policy, losable by doing nothing, and takes about its clock. A whole night runs 6–10 minutes of play. Measure with `--act=skip` (doing nothing loses each act) and `--act=play`.
- [ ] **Step 2: Tune within these numbers only:**
  - the night's slots and DP;
  - `FESTIVAL_CROWD`, `FESTIVAL_NEED`;
  - the act clocks;
  - the event times;
  - `JAM_SECONDS`;
  - `PRINCE_ESCAPED_LIMIT`;
  - `NIGHT_RANKS`, `ACT_POINTS`, `BONUS_POINTS`;
  - `ESCORT_R` and `ESCORT_CLOSE`.

  Record each change with before/after measurements.
  - **Ranks:** set `NIGHT_RANKS` so that a policy night that wins all three acts lands an A.
  - **Anything else** that looks off (a power that solos an act, an act no power can solve) goes to the controller as options for the user. Do not change it.
- [ ] **Step 3: Run the tests and the exact gates, then commit.** Message: `tune: The Long Night's numbers from measured nights (v0.09)`.

### Task 20 (controller): Bench, summary, tag

- [ ] **The bench:**
  - Last Judgement against `kak-v0.08.2`, six alternating pairs, in a scratch worktree with `.godot` copied. It must stay within 5 fps.
  - Add one bench run of the Festival act with its crowd packed: a `--bench` hook, or `--mission=long_night` with a forced jump to the Festival. Record it.
- [ ] **The final gates:** all of them, plus every night case.
- [ ] **The summary:** write `docs/KAK_Version_0.09_Summary.md` in the v0.08 summary's style. Cover:
  - the night, its acts and paths;
  - the town between acts (the §2 table, measured);
  - the events;
  - the gates, the bench and the balance;
  - the assumed open points;
  - what moves to v0.10 (Resonance, Trials, the campaign save, civilization memory);
  - the VFX branch's `person.gd` conflict, if it is still unmerged.
- [ ] **Release:** commit, tag `kak-v0.09`, push, and update the ledger (the release row, the cards, the meta row).

---

## Self-review against the spec

| Spec | Task |
|---|---|
| §1 the board card, Tier 3, 4 slots and 10 DP, re-draft each act, all cooldowns reset | 1, 3, 4 |
| §1 Act I = The Warning on an Unaware town | 1, 3 |
| §1 the interlude (result, choice card, re-draft, BEGIN) | 4, 5 |
| §1 The Festival (crowd, bonfires, Mayor, 0:45 / 1:30 / 2:30, success, bonus, carry) | 12, 13, 10 |
| §1 The Procession (Prince, escorts closing in, route, blessing, ship, tide, quiet succession, carry) | 15, 16, 10 |
| §1 Judgement (objectives, limits 50/40, events 1:30 / 2:00 / 2:30, Dawn bonus) | 1, 10 |
| §1 the night's results and save (acts, path, rank; paths won on the board) | 1, 6 |
| §2 fail forward, the town never lowered, the dead and ruins kept, escapes per act | 2, 8, 10 |
| §3 ActDef, NightState, Rules per act, raise_profile, EventTimeline, the directors, the Interlude, the new roles | 1–4, 8–16 |
| §4 the tests listed, the `night` scenario, the gates, the bench | 1–20 |
| §6 open points | Global Constraints (assumed) |

## Execution notes

### M1 gate (at 0213f0b)

- Tests `checks=1833 failures=0`; digest unchanged; crowd_check `-346732806`; FLOW `checks=54 failures=0`. FLOW plays a whole night, with a restart from Act I and from Act II.
- All 10 exact behaviour checksums identical: the 5 town scenarios and the 5 Warning cases.
- Mission test, three runs: buildings 57/55/53, citizens 180/189/190, escaped 0/1/1. The Warning unhindered: bell at 24.1.
- `--scenario=night`, forced act outcomes, 8 runs, no SCRIPT ERROR:
  - festival, Act I win, Act III win: won, A (16620)
  - festival, Act I win, Act III lose: lost, C (5120)
  - festival, Act I lose, Act III win: won, B (14120)
  - festival, Act I lose, Act III lose: lost, D (2645)
  - procession: A (16560), C (5085), B (14060), D (2585)
- Captures checked: the interlude (the act result and two path cards) and the night's results.
- Plan fixes made by the implementers:
  - `SaveFile` appended to a copy of `paths_won` (it now reassigns).
  - The first Prepare of a never-played night opened empty; `Game.starting_loadout()` now falls back to the night's default loadout.
  - Prepare between acts showed Unaware; `ActDef.response_profile()` now returns the act's town.
  - A stale `_play_ending` could emit for the wrong act; it is now guarded.
