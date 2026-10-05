# KAK v0.10 M1 — Campaign spine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** the Lantern campaign playable end to end: four nights in Aldermere chosen from a night screen, Cael's memory fragments, Divine Power that grows and is bitten, the path tally, a campaign save, and the four endings as text screens. Night 2's three missions are placeholders ("hold until dawn") that M2–M4 replace.

**Architecture:**
- **The campaign is data and state:**
  - `CampaignDef` lists the nights, the missions each offers and their paths, and the numbers.
  - `CampaignState` holds where a campaign stands. Its `record(mission_id, result)` applies a night's result: DP growth, bites, the path tally, Night 1's bell and the ending.
  - `CampaignText` holds every word of the story.
- **Missions:**
  - The campaign's own missions live in `MissionBook.campaign_missions()`: three Vigil placeholders, and the two Feast nights (each one of The Long Night's middle acts, played as a night of one act).
  - They are found by `get_mission()`, but never listed on the board.
- **Screens:**
  - `Game` gains two screens: `CAMPAIGN` (the night screen: status, fragment, choice cards) and `ENDING`.
  - While `_in_campaign` is set: Prepare drafts within the campaign's slots and budget; a finished mission is recorded on the campaign; Results offers Continue; Pause offers Campaign.
- **The town remembers Night 1:** `Mission.bell_rang` seeds the night's `NightState`, so the Feast's act meets a warned town after a rung Night 1.

**Tech Stack:** Godot 4.7.2, GDScript; headless tests in `tests/run_all.gd`; the screen-flow test `--flow-test`.

**Spec:** `docs/superpowers/specs/2026-10-05-kak-v010-lantern-campaign-design.md`. Read it before any task. This plan covers its **M1** (§8.1). M2–M5 each get their own plan after this milestone's gate, since they build on what M1 and its playtest show.

## Global Constraints

- **Baseline:** `feat/Develop-Main` at `234a04d` (v0.09 plus the v0.10 spec). This plan's version is **v0.10**. The milestone tag is `kak-v010-m1`.
- **Machine:** the BURIN_NITRO laptop.
  - **Repository:** the main checkout is `C:\BURIN_NITRO\Godot\GIT\vfxProve` (Git Bash `/c/BURIN_NITRO/Godot/GIT/vfxProve`), on `feat/Develop-Main`. The controller names the checkout to work in: the main checkout, or a session worktree on a branch made from `feat/Develop-Main`. Never touch other sessions' worktrees: `vfxProve-pixellab`, `vfxProve-integrate`, other `.claude/worktrees/*`.
  - **In a fresh worktree** run the import below before anything else: it has no `.godot` cache.
  - **Godot:** `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`.
- **Commands:**
  - **Import** (after a new `class_name` or a new test file): `timeout 180 $G --headless --editor --path . --import >/dev/null 2>&1`.
  - **Tests:** `timeout 900 $G --headless --path . --script res://tests/run_all.gd 2>&1 | grep -v '^\s*at:' | grep -n "FAIL\|SCRIPT ERROR\|Parse Error\|checks="`. Expected: `checks=N failures=0`, no SCRIPT ERROR or Parse Error lines. The baseline is **2087**.
  - **Digest:** `$G --headless --path . -s tools/dev/state_digest.gd`. Expected: `digest=61267b7e90524d800bf1c3473a71146b`.
  - **crowd_check:** `$G --headless --path . --fixed-fps 60 -s tools/dev/crowd_check.gd`. Expected: `checksum=-346732806`.
  - **FLOW:** `$G --path . --audio-driver Dummy --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep "FLOW"`. Expected: `FLOW result ... failures=0`. The baseline is **62** checks. One step ("and then restarts the night from Act I") is load-sensitive: on a busy machine, rerun before calling it a failure.
  - **Behaviour (exact):** `$G --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=<name>`:
    - `calm --seconds=60`: -695580348
    - `gates`: 619520995
    - `fire`: -16560442
    - `rite --interrupt`: -129298221
    - `soldiers --case=escort`: -935015846
    - `warning --case=none|doom|whisper|discord|mix`: -446012507, -999129915, 442055066, -909358062, -430643507
  - **Captures:** `SCENE=res://scenes/game.tscn bash tools/capture.sh --show=<name> --capture` writes `captures/screen_<name>.png`.
  - **Do not touch any game window while a run goes:** an R key restarts the mission.
- **Test style:**
  - A test file is `extends RefCounted` with `static func run(t) -> void:`, using `t.check(cond, "msg")` and `t.near(a, b, eps, "msg")`.
  - Register a new file in `tests/run_all.gd` at the end of `SUITES`.
  - UI screens are tested without a tree, as `tests/test_flow.gd` tests `InterludeScreen`: `setup()`, `click()`, then `free()`.
- **Code style:**
  - tabs; `##` doc comments in full sentences; constants `UPPER_CASE` with a `##` comment;
  - match the surrounding comment density;
  - **new enum values go at the end**.
- **Nothing that is not the campaign may change.** The Warning, The Long Night and Last Judgement from the board play exactly as before: every exact gate above stays identical. The campaign's code runs only from the night screen.
- **Git:**
  - `git add` explicit paths only, including new `.gd.uid` files;
  - never add `default_bus_layout.tres` (restore it with `git checkout -- default_bus_layout.tres`), `captures/`, `.codex/`, `concepts/`;
  - every commit message ends with a blank line, then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; tag the subject `(v0.10)`;
  - **do not push or tag:** the controller does that at the gate.
- **Tuning latitude:**
  - The code was written against `234a04d` and has not been run. Fix real bugs and keep each test's intent.
  - You may change placement constants (screen pixels, rects) when the 640×360 screen needs it.
  - Campaign numbers (`CampaignDef`'s DP, bites, slots) are the spec's and do not change in M1.
  - Report every deviation.

## Review Focus

These are inputs the spec implies but no feature test exercises. Each line has its test in the owning task.

1. **A saved loadout that costs more than the campaign's budget after a bite:** Prepare opens with the picks that fit, in order, and no error. *Test:* Task 4.
2. **Leaving a night unfinished** (Pause, Campaign; Pause, Restart; Back from Prepare) records nothing: no bite, no DP, the same night next time. *Test:* Task 6.
3. **A damaged, old or finished save:** values out of range are pulled back, a missing section means no campaign, three bites with no ending reads as Eaten, and Campaign after an ending starts a fresh one. *Tests:* Task 3 and Task 6.
4. **"New campaign" pressed by accident** does not wipe progress: it needs a second press. *Test:* Task 4.
5. **The board after the campaign:** leaving for the title and playing a board mission uses that mission's own slots and DP and never records onto the campaign. *Test:* Task 6.

## Where this plan departs from the spec

The controller reports these to the user at the gate.

1. **Fragments are on a new night screen, not on `InterludeScreen`.** The interlude is built around an act's result and `ActDef` cards, and a campaign night has neither before it starts. `CampaignScreen` shows the status, the fragment and the cards together, following the interlude's layout and input.
2. **The spec's `campaign` behaviour scenario (§7) is a headless test.** Its job is to reach every branch and ending with forced outcomes. The branching lives in `CampaignState`, not in a mission, so `test_campaign.gd`'s `_branches()` walks all 24 combinations directly. The FLOW test plays one campaign through the real screens. The per-mission Night 2 scenarios come with M2–M4.
3. **Night 3's card lines** are The Long Night's own act lines ("The bell rang: soldiers watch the square."). The spec gives Cael lines only for Night 2's cards.
4. **The title's "Play" button is now labelled "Missions"**, under a new "Campaign" button. Its action and the Enter key are unchanged.

---

## File structure

| File | Responsibility |
|---|---|
| `src/game/campaign/campaign_def.gd` | **New.** `CampaignDef`: the nights, their missions and paths, the numbers, `path_of()`, `ending_for()` |
| `src/game/campaign/campaign_state.gd` | **New.** `CampaignState`: where a campaign stands; `record()`; `mission()`; its save section |
| `src/game/campaign/campaign_text.gd` | **New.** `CampaignText`: fragments, card lines, titles, path names, endings |
| `src/game/ui/campaign_screen.gd` | **New.** `CampaignScreen`: status, fragment, choice cards, buttons |
| `src/game/ui/ending_screen.gd` | **New.** `EndingScreen`: the last fragment, then the ending |
| `src/game/mission/mission_book.gd` | The campaign's missions: three Vigil placeholders and two Feast nights; `get_mission()` finds them |
| `src/game/mission/mission_def.gd` | `response_profile()` for a night reads its first act's town |
| `src/game/mission.gd` | `bell_rang` seeds the night |
| `src/game/save_file.gd` | `campaign` and its `[campaign]` section |
| `src/game/ui/results_screen.gd` | Campaign mode: Continue and the DP/bite line; the `held` title |
| `src/game/ui/pause_menu.gd`, `title_screen.gd` | The Campaign buttons |
| `src/game/game.gd` | The two screens, the FLOW entries, campaign mode, `--show=campaign|campaign-choice|ending`, the FLOW test |
| `tests/test_campaign.gd`, `tests/test_campaign_screens.gd` | **New** tests |
| `tests/test_mission_book.gd`, `tests/test_flow.gd`, `tests/run_all.gd` | Added checks and registration |

---

## Milestone 1 — Campaign spine

### Task 1: The campaign's missions in the book

**Files:**
- Modify: `src/game/mission/mission_book.gd`, `src/game/mission/mission_def.gd`, `src/game/ui/results_screen.gd`
- Test: `tests/test_mission_book.gd`

**Interfaces:**
- Produces:
  - `MissionBook` constants `MIRAS_HOUSE := "miras_house"`, `VIGIL_FLAME := "vigil_flame"`, `BROKEN_LANTERNS := "broken_lanterns"`, `FEAST_FESTIVAL := "feast_festival"`, `FEAST_PROCESSION := "feast_procession"`, `VIGIL_POOL`, `RUIN_POOL`.
  - `MissionBook.campaign_missions() -> Array[MissionDef]`, `miras_house()`, `vigil_flame()`, `broken_lanterns()`, `feast(act_id: String) -> MissionDef`.
  - `MissionBook.get_mission(id)` also finds the campaign's missions. `all()` is unchanged.
  - `MissionDef.response_profile()`: a mission with acts and `profile == "night"` answers with its first act's town.
  - `ResultsScreen.ACT_TITLES["held"] == "THE NIGHT PASSES"`.

- [ ] **Step 1: Write the failing test.** Append to the end of `run()` in `tests/test_mission_book.gd`:

```gdscript
	# The Lantern campaign's missions (v0.10): found by their ids, never on the board.
	var board := []
	for m in MissionBook.all():
		board.append(m.id)
	for id in [MissionBook.MIRAS_HOUSE, MissionBook.VIGIL_FLAME, MissionBook.BROKEN_LANTERNS,
			MissionBook.FEAST_FESTIVAL, MissionBook.FEAST_PROCESSION]:
		t.check(MissionBook.get_mission(id).id == id, "the campaign's %s is found by its id" % id)
		t.check(not board.has(id), "and it is not on the board (%s)" % id)
	t.check(board == ["warning", "long_night", "last_judgement"], "the board lists what it did (%s)" % [board])

	# Night 2's placeholders (M1): Tier 2, an Unaware town, unscored, held until dawn.
	var mh := MissionBook.miras_house()
	var held := []
	for o in mh.objectives():
		held.append(o.reason)
	t.check(mh.tier == 2 and mh.profile == "unaware" and not mh.scored and mh.director == null and held == ["held"],
		"Mira's House is a Tier 2 placeholder held until dawn (%s)" % [held])
	t.check(Array(mh.powers()) == MissionBook.VIGIL_POOL and Array(MissionBook.vigil_flame().powers()) == MissionBook.VIGIL_POOL,
		"Mira's House and the Vigil Flame draft from the quiet five (%s)" % [mh.powers()])
	var bl := MissionBook.broken_lanterns()
	t.check(bl.allows("thorns") and bl.allows("heaven") and bl.allows("gravity") and not bl.allows("nova"),
		"Broken Lanterns adds four Ruin powers, not Nova")
	t.check(ResultsScreen.title_for(true, "held") == "THE NIGHT PASSES", "a held night has its own title")

	# Night 3, the Feast (v0.10): one of The Long Night's middle acts as a night of one act.
	var fe := MissionBook.feast("festival")
	t.check(fe.id == MissionBook.FEAST_FESTIVAL and fe.name == "The Festival" and fe.tier == 3 and fe.has_acts()
		and fe.acts.size() == 1 and fe.first_act().id == "festival" and fe.first_act().is_last()
		and fe.first_act().director == FestivalDirector, "the Feast's Festival is The Long Night's act, alone and last")
	t.check(MissionBook.feast("procession").first_act().director == ProcessionDirector, "and so is the Procession")
	var warned := NightState.new()
	warned.bell_rang = true
	fe.first_act().night = warned
	t.check(fe.response_profile(ResponseProfile.DEFAULT).tier == ResponseProfile.Tier.ORGANIZED,
		"after a rung bell the Feast's Prepare shows the Organized town")
	t.check(MissionBook.long_night().response_profile(ResponseProfile.DEFAULT).tier_name() == "Unaware",
		"The Long Night still opens on a sleeping town")
```

- [ ] **Step 2: Run the tests to verify they fail.** Run the Tests command. Expected: Parse Error or FAIL lines naming `MIRAS_HOUSE`, `miras_house` or `feast`.

- [ ] **Step 3: Add the missions.** In `src/game/mission/mission_book.gd`, under the existing `const LAST_JUDGEMENT` line, add:

```gdscript
## The Lantern campaign's own missions (v0.10): Night 2's three, one per path, and Night 3's two Feast nights.
const MIRAS_HOUSE := "miras_house"
const VIGIL_FLAME := "vigil_flame"
const BROKEN_LANTERNS := "broken_lanterns"
const FEAST_FESTIVAL := "feast_festival"
const FEAST_PROCESSION := "feast_procession"
## The Vigil's pools (v0.10 spec §4.1): the quiet five, and for Broken Lanterns four Ruin powers besides.
const VIGIL_POOL := ["whisper", "doom", "wisp", "discord", "thorns"]
const RUIN_POOL := ["heaven", "tornado", "dragon", "gravity"]
```

Replace `get_mission()` with:

```gdscript
## The mission with this id, on the board or in the campaign; an unknown id gives Last Judgement.
static func get_mission(id: String) -> MissionDef:
	for m in all():
		if m.id == id:
			return m
	for m in campaign_missions():
		if m.id == id:
			return m
	return last_judgement()


## The Lantern campaign's missions (v0.10): played from the campaign's night screen, never listed on the board.
static func campaign_missions() -> Array[MissionDef]:
	var out: Array[MissionDef] = [miras_house(), vigil_flame(), broken_lanterns(), feast("festival"), feast("procession")]
	return out
```

At the end of the file, add:

```gdscript
## Night 2 of the campaign, the Vigil (v0.10 M1): three placeholders held until dawn, one per path, with the spec's
## briefs and pools. M2, M3 and M4 replace each with its real night.
static func miras_house() -> MissionDef:
	return _vigil(MIRAS_HOUSE, "Mira's House", PackedStringArray(["Her journal waits in a shuttered house.",
		"Lead the grieving to it unseen."]), PackedStringArray(VIGIL_POOL))


static func vigil_flame() -> MissionDef:
	return _vigil(VIGIL_FLAME, "The Vigil Flame", PackedStringArray(["A priest carries Halcyon's flame.",
		"A mortal hand must steal it."]), PackedStringArray(VIGIL_POOL))


static func broken_lanterns() -> MissionDef:
	return _vigil(BROKEN_LANTERNS, "Broken Lanterns", PackedStringArray(["Six shrines anchor the Lantern.",
		"Break them before they are relit."]), PackedStringArray(VIGIL_POOL + RUIN_POOL))


static func _vigil(id: String, name: String, brief: PackedStringArray, pool: PackedStringArray) -> MissionDef:
	var m := MissionDef.new()
	m.id = id
	m.name = name
	m.tier = 2
	m.brief = brief
	m.goal = "Hold until dawn: this night is still being built"
	m.goal_label = "Dawn comes"
	m.lose = "Nothing yet"
	m.slots = 3
	m.dp_capacity = 8
	m.pool = pool
	m.clock = 120.0
	m.profile = "unaware"
	m.intro_banner = name.to_upper()
	m.default_loadout = PackedStringArray(["whisper", "doom", "discord"])
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [ClockObjective.new(true, "Dawn", "held")]
		return out
	return m


## Night 3 of the campaign, the Feast of Lanterns (v0.10): one of The Long Night's middle acts played on its own, as a
## night of one act. Its town comes from Night 1 through Mission.bell_rang; the act's rules are unchanged.
static func feast(act_id: String) -> MissionDef:
	var ln := long_night()
	var a := ln.act(act_id)
	a.next = PackedStringArray()
	var m := MissionDef.new()
	m.id = "feast_" + act_id
	m.name = a.name.trim_prefix("Act II: ")
	m.tier = 3
	m.brief = a.brief
	m.goal = a.goal
	m.goal_label = a.goal_label
	m.lose = a.lose
	m.slots = 4
	m.dp_capacity = 10
	m.clock = a.clock
	m.profile = "night"
	m.scored = true
	m.default_loadout = ln.default_loadout
	m.intro_from = a.intro_from
	m.camera_at = a.camera_at
	a.intro_banner = "NIGHT 3 - " + m.name.to_upper()
	m.intro_banner = a.intro_banner
	m.acts = [a]
	m.make_objectives = a.make_objectives
	m.make_bonuses = a.make_bonuses
	return m
```

- [ ] **Step 4: A night's Prepare shows its first act's town.** In `src/game/mission/mission_def.gd`, replace `response_profile()` with:

```gdscript
## The town's response for this mission: the difficulty chosen on Prepare, unless the mission sets its own. A night
## (v0.10) answers with its first act's town, which reads the night it is given: the campaign's Feast after a rung bell.
func response_profile(chosen: ResponseProfile.Tier) -> ResponseProfile:
	if profile == "night" and has_acts():
		return first_act().response_profile(chosen)
	if profile == "unaware" or profile == "night":
		return ResponseProfile.unaware()
	return ResponseProfile.for_tier(chosen)
```

`ActDef` keeps its own override and has no acts, so this never recurses. The Long Night's first act is the Omen, whose town is Unaware, so the board's Long Night does not change.

- [ ] **Step 5: The held night's title.** In `src/game/ui/results_screen.gd`, add `"held": "THE NIGHT PASSES"` to `ACT_TITLES`:

```gdscript
const ACT_TITLES := {"festival": "THE FEAST IS BROKEN", "closed": "THE SQUARE IS CLOSED", "prince": "THE PRINCE IS DEAD",
	"sailed": "THE PRINCE HAS SAILED", "tide": "THE TIDE HAS TURNED", "held": "THE NIGHT PASSES"}
```

- [ ] **Step 6: Run the tests to verify they pass.** Run Import, then Tests. Expected: `checks=N failures=0`, N above 2087.

- [ ] **Step 7: Run the Digest and crowd_check.** Expected: unchanged.

- [ ] **Step 8: Commit.**

```bash
git add src/game/mission/mission_book.gd src/game/mission/mission_def.gd src/game/ui/results_screen.gd tests/test_mission_book.gd
git commit -m "feat: the campaign's missions: Vigil placeholders and the Feast nights (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 2: CampaignDef, CampaignText and CampaignState

**Files:**
- Create: `src/game/campaign/campaign_def.gd`, `src/game/campaign/campaign_text.gd`, `src/game/campaign/campaign_state.gd`, `tests/test_campaign.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: `MissionBook.get_mission()` and the ids from Task 1; `NightState.bell_rang`.
- Produces:
  - `CampaignDef`:
    - `FAITH`, `THEFT`, `RUIN`, `PATHS`;
    - `NEW_FAITH`, `FALSE_LANTERN`, `KATACLYSM`, `EATEN`, `ENDINGS`;
    - `START_DP := 6`, `WIN_DP := 2`, `BONUS_DP := 1`, `BITE_DP := 1`, `MIN_DP := 4`, `MAX_BITES := 3`, `FINALE := 3`, `NIGHTS`;
    - `static night(i: int) -> Dictionary` (`tier`, `slots`, `fragment`, `options: [{mission, path}]`);
    - `static path_of(i: int, mission_id: String) -> String`, `static ending_for(path: String) -> String`.
  - `CampaignText`: `FRAGMENTS` (id → `{title, text}`), `CARD_LINES` (mission id → line), `TITLES` (path or "" → title), `PATH_NAMES`, `ENDINGS` (ending → `{title, text, note}`).
  - `CampaignState`:
    - `night: int`, `dp: int`, `bites: int`, `tally: Dictionary`, `last_path: String`, `bell_rang: bool`, `nights_won: int`, `ending: String`;
    - `slots() -> int`, `options() -> Array`, `path() -> String`, `title() -> String`, `ending_fragment() -> String`;
    - `mission(id: String) -> MissionDef`: a fresh def with the night's slots and the campaign's DP; a night's first act carries the campaign's bell;
    - `record(mission_id: String, result: Dictionary) -> Dictionary`: returns `{won, dp_gain, bite, dp, bites, ending, path}`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_campaign.gd`:

```gdscript
extends RefCounted
## v0.10 the Lantern campaign as data and state: four nights and their missions, Divine Power that grows with each won
## night and is bitten by each lost one, the path tally and its ties, Night 1's bell carried to Night 3, and every way a
## campaign ends.


static func run(t) -> void:
	_def(t)
	_growth(t)
	_paths(t)
	_branches(t)


static func _won(bonus := false) -> Dictionary:
	return {"won": true, "reason": "held", "bonuses": [{"label": "Bonus", "earned": bonus}]}


static func _lost(reason := "timeout") -> Dictionary:
	return {"won": false, "reason": reason, "bonuses": []}


static func _def(t) -> void:
	t.check(CampaignDef.NIGHTS.size() == 4, "the prototype campaign has four nights")
	var slots := []
	var tiers := []
	for i in 4:
		var n := CampaignDef.night(i)
		slots.append(int(n.slots))
		tiers.append(int(n.tier))
		t.check(CampaignText.FRAGMENTS.has(String(n.fragment)), "night %d's fragment has its words (%s)" % [i + 1, n.fragment])
		for o: Dictionary in n.options:
			t.check(MissionBook.get_mission(String(o.mission)).id == String(o.mission),
				"night %d offers a real mission (%s)" % [i + 1, o.mission])
	t.check(slots == [3, 3, 4, 6] and tiers == [1, 2, 3, 5], "slots %s and Tiers %s are the spec's" % [slots, tiers])
	var paths := []
	for o: Dictionary in CampaignDef.night(1).options:
		paths.append(String(o.path))
	t.check(paths == ["faith", "theft", "ruin"], "Night 2 offers one mission per path (%s)" % [paths])
	t.check(CampaignDef.path_of(1, "vigil_flame") == "theft" and CampaignDef.path_of(0, "warning") == ""
		and CampaignDef.path_of(1, "warning") == "", "path_of() names a night's path, and nothing it does not offer")
	t.check(CampaignDef.ending_for("faith") == "new_faith" and CampaignDef.ending_for("theft") == "false_lantern"
		and CampaignDef.ending_for("ruin") == "kataclysm", "each path has its ending")
	for e in CampaignDef.ENDINGS:
		t.check(CampaignText.ENDINGS.has(e), "the %s ending has its words" % e)
	for p in CampaignDef.PATHS:
		t.check(CampaignText.TITLES.has(p) and CampaignText.PATH_NAMES.has(p), "the %s path has a title and a name" % p)
	for id in ["miras_house", "vigil_flame", "broken_lanterns"]:
		t.check(CampaignText.CARD_LINES.has(id), "Cael has a line for the %s card" % id)


static func _growth(t) -> void:
	var s := CampaignState.new()
	t.check(s.night == 0 and s.dp == 6 and s.bites == 0 and s.slots() == 3 and s.ending == "" and s.title() == "The Forgotten",
		"a fresh campaign: Night 1, 6 DP, 3 slots, no bites, the Forgotten")
	var c := s.record("warning", {"won": true, "reason": "omen", "bonuses": [{"label": "Unseen", "earned": false}]})
	t.check(s.dp == 8 and s.night == 1 and int(c.dp_gain) == 2 and not bool(c.bite) and not s.bell_rang and s.nights_won == 1,
		"a won night: +2 DP and on to Night 2 (dp %d)" % s.dp)
	var m := s.mission("broken_lanterns")
	t.check(m.slots == 3 and m.dp_capacity == 8, "a mission from the campaign has the night's slots and the god's DP")
	s = CampaignState.new()
	s.record("warning", {"won": true, "reason": "warning", "bonuses": [{"label": "Unseen", "earned": true}]})
	t.check(s.dp == 9, "a won night with its bonus: +3 (dp %d)" % s.dp)
	s = CampaignState.new()
	c = s.record("warning", _lost("bell"))
	t.check(s.dp == 5 and s.bites == 1 and s.night == 1 and s.bell_rang and bool(c.bite) and int(c.dp_gain) == 0,
		"a lost night is a bite: -1 DP, and the story goes on; the bell is remembered")
	var f := s.mission("feast_festival")
	t.check(f.first_act().night != null and f.first_act().night.bell_rang
		and f.response_profile(ResponseProfile.DEFAULT).tier == ResponseProfile.Tier.ORGANIZED,
		"Night 1's bell reaches the Feast's act and its Prepare")
	s = CampaignState.new()
	s.dp = 4
	s.record("warning", _lost())
	t.check(s.dp == 4, "a bite never takes the budget under 4 (dp %d)" % s.dp)
	s = CampaignState.new()
	s.record("warning", _lost())
	s.record("vigil_flame", _lost())
	c = s.record("feast_festival", _lost())
	t.check(s.bites == 3 and s.ending == "eaten" and String(c.ending) == "eaten", "the third bite: Halcyon has eaten the god")


static func _paths(t) -> void:
	var s := CampaignState.new()
	t.check(s.path() == "", "no path before a path night")
	s.tally = {"faith": 1, "theft": 1, "ruin": 0}
	s.last_path = "theft"
	t.check(s.path() == "theft", "a tie goes to the most recent path night (%s)" % s.path())
	s.last_path = "faith"
	t.check(s.path() == "faith", "whichever it was (%s)" % s.path())
	s.tally = {"faith": 0, "theft": 0, "ruin": 2}
	t.check(s.path() == "ruin" and s.title() == "The Kataclysm", "the strongest path gives the title (%s)" % s.title())
	s = CampaignState.new()
	s.record("warning", _won())
	s.record("miras_house", _lost())
	t.check(int(s.tally["faith"]) == 1 and s.last_path == "faith" and s.title() == "The Prophet's God",
		"a path night counts for its path won or lost")
	t.check(CampaignState.new().ending_fragment() == "", "no fragment before an ending")
	s.ending = "new_faith"
	t.check(s.ending_fragment() == "vision", "The Vision comes before the Faith ending")
	s.ending = "kataclysm"
	t.check(s.ending_fragment() == "", "but not before the Kataclysm (seen before Night 4)")


## Every way through the prototype campaign (spec §7's forced outcomes): Night 1 won or lost, each Night 2 path won or
## lost, Night 3 won or lost, and on the Ruin path the finale lost once, then won.
static func _branches(t) -> void:
	var bad := PackedStringArray()
	for n1 in [true, false]:
		for n2 in ["miras_house", "vigil_flame", "broken_lanterns"]:
			for n2won in [true, false]:
				for n3won in [true, false]:
					var label := "n1 %s, %s %s, n3 %s" % [n1, n2, n2won, n3won]
					var s := CampaignState.new()
					s.record("warning", _won() if n1 else _lost("bell"))
					s.record(n2, _won() if n2won else _lost())
					s.record("feast_procession", _won() if n3won else _lost())
					var bites := int(not n1) + int(not n2won) + int(not n3won)
					var want := ""
					if bites >= 3:
						want = "eaten"
					elif n2 == "miras_house":
						want = "new_faith"
					elif n2 == "vigil_flame":
						want = "false_lantern"
					if s.ending != want:
						bad.append("%s: ending '%s'" % [label, s.ending])
						continue
					if want != "":
						continue
					if s.night != CampaignDef.FINALE:
						bad.append("%s: not at the finale" % label)
						continue
					s.record("last_judgement", _lost())
					if s.bites >= 3:
						if s.ending != "eaten":
							bad.append("%s: the finale's third bite is not Eaten" % label)
						continue
					if s.night != CampaignDef.FINALE or s.ending != "":
						bad.append("%s: a lost finale is not played again" % label)
					s.record("last_judgement", _won())
					if s.ending != "kataclysm":
						bad.append("%s: a won finale is not the Kataclysm" % label)
	t.check(bad.is_empty(), "every branch ends where the spec says (%s)" % ", ".join(bad))
	var r := CampaignState.new()
	var dps := [r.dp]
	for id in ["warning", "broken_lanterns", "feast_festival"]:
		r.record(id, _won())
		dps.append(r.dp)
	t.check(dps == [6, 8, 10, 12] and r.night == CampaignDef.FINALE and r.slots() == 6,
		"a Ruin run that wins every night: %s DP, then the finale with 6 slots" % [dps])
```

Register it: add `"res://tests/test_campaign.gd",` at the end of `SUITES` in `tests/run_all.gd`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: Parse Error naming `CampaignDef`, or `suite failed to load: res://tests/test_campaign.gd`.

- [ ] **Step 3: Write `CampaignDef`.** Create `src/game/campaign/campaign_def.gd`:

```gdscript
class_name CampaignDef
extends RefCounted
## The Lantern campaign as data (v0.10, spec §3-§4): four nights in Aldermere, the missions each night offers with the
## path each belongs to, and the numbers by which the god's Divine Power grows and Halcyon bites it.

const FAITH := "faith"
const THEFT := "theft"
const RUIN := "ruin"
## The paths, in the tally's order.
const PATHS := ["faith", "theft", "ruin"]
## The endings: a path's, after its last night, or Halcyon's, after the third bite.
const NEW_FAITH := "new_faith"
const FALSE_LANTERN := "false_lantern"
const KATACLYSM := "kataclysm"
const EATEN := "eaten"
const ENDINGS := ["new_faith", "false_lantern", "kataclysm", "eaten"]
## The budget the god wakes with; what a won night, its bonus and a bite change; the floor; the bites that end it.
const START_DP := 6
const WIN_DP := 2
const BONUS_DP := 1
const BITE_DP := 1
const MIN_DP := 4
const MAX_BITES := 3
## The nights in order: the Awakening Tier, the slots, the memory fragment shown before it (CampaignText.FRAGMENTS), and
## the missions it offers, {mission, path}: one, or a choice card. Night 4 is the finale, on the Ruin path only.
const NIGHTS := [
	{"tier": 1, "slots": 3, "fragment": "shrine", "options": [{"mission": "warning", "path": ""}]},
	{"tier": 2, "slots": 3, "fragment": "pyre", "options": [{"mission": "miras_house", "path": "faith"},
		{"mission": "vigil_flame", "path": "theft"}, {"mission": "broken_lanterns", "path": "ruin"}]},
	{"tier": 3, "slots": 4, "fragment": "lanterns", "options": [{"mission": "feast_festival", "path": ""},
		{"mission": "feast_procession", "path": ""}]},
	{"tier": 5, "slots": 6, "fragment": "vision", "options": [{"mission": "last_judgement", "path": ""}]},
]
## Night 4's index: the finale.
const FINALE := 3


static func night(i: int) -> Dictionary:
	return NIGHTS[clampi(i, 0, NIGHTS.size() - 1)]


## The path a mission belongs to on night `i`: "" for a night without paths, or a mission the night does not offer.
static func path_of(i: int, mission_id: String) -> String:
	for o: Dictionary in night(i).options:
		if String(o.mission) == mission_id:
			return String(o.path)
	return ""


## The ending a path reaches: Faith and Theft after Night 3, Ruin after the finale.
static func ending_for(path: String) -> String:
	match path:
		FAITH:
			return NEW_FAITH
		THEFT:
			return FALSE_LANTERN
	return KATACLYSM
```

- [ ] **Step 4: Write `CampaignText`.** Create `src/game/campaign/campaign_text.gd`:

```gdscript
class_name CampaignText
extends RefCounted
## The Lantern campaign's words (v0.10, spec §5), kept apart from its logic so a writing change never touches it: Cael's
## memory fragments, the choice cards' lines, the titles a path gives the god, and the endings. Every name is a
## placeholder the user may change.

## Cael's memory fragments by id: shown on the night screen before the night that names them (CampaignDef.NIGHTS), and
## The Vision before the Faith and Theft endings.
const FRAGMENTS := {
	"shrine": {"title": "The Shrine", "text": "I climbed to her shrine with the dusk bells behind me. Mira kept it " +
		"for a god no one remembered. I never learned your name. She knew it. Take what's left of me. Wake."},
	"pyre": {"title": "The Pyre", "text": "Odran read the order. Venn lit the wood. I stood on the Temple steps and " +
		"said nothing. She looked for me in the crowd. Tonight they carry his flame through the streets as if nothing " +
		"happened."},
	"lanterns": {"title": "The Lanterns", "text": "She hated the Feast. Every lantern is a prayer to him, she said, " +
		"and he never looks at who lights them. Tomorrow the whole town lights one."},
	"vision": {"title": "The Vision", "text": "My vision said a heretic kept the old shrine. Odran asked me who. I " +
		"told him. That is why I gave you my life. Not faith. Debt."},
}
## Cael's line on a Night 2 card, by mission (spec §5.3). Night 3's cards use The Long Night's own lines.
const CARD_LINES := {
	"miras_house": "She'd want them to know you. Let them find her words.",
	"vigil_flame": "He gave this town his light. Take it back.",
	"broken_lanterns": "Break his lanterns. Let him feel how small his town is.",
}
## The god's title by its strongest path; "" before any path night.
const TITLES := {"": "The Forgotten", "faith": "The Prophet's God", "theft": "The Deceiver", "ruin": "The Kataclysm"}
## A path's name on its card.
const PATH_NAMES := {"faith": "Faith", "theft": "Theft", "ruin": "Ruin"}
## The endings (spec §5.4): a title, Cael's epilogue, and a note for the two that have no playable last night yet.
const ENDINGS := {
	"new_faith": {"title": "The New Faith", "text": "They pray at her shrine now, quietly, in the dark. They don't " +
		"know your name either. They call you hers.", "note": "A playable last night for this path comes later."},
	"false_lantern": {"title": "The False Lantern", "text": "The lanterns still burn and they still pray to him. " +
		"But it's you who hears them now, and he hasn't noticed yet.",
		"note": "A playable last night for this path comes later."},
	"kataclysm": {"title": "The Kataclysm", "text": "There's no one left to light a lantern. He's starving. So are " +
		"you. Was this what she prayed for?", "note": ""},
	"eaten": {"title": "Eaten", "text": "He found us. I'm sorry, Mira.", "note": ""},
}
```

If Godot refuses `+` between string literals in a `const`, join each text into one literal on one line instead (a long line is acceptable here) and report it.

- [ ] **Step 5: Write `CampaignState`.** Create `src/game/campaign/campaign_state.gd`:

```gdscript
class_name CampaignState
extends RefCounted
## Where a Lantern campaign stands (v0.10, spec §3): the night to play next, the Divine Power the god has regained,
## Halcyon's bites, the path tally, and Night 1's bell. record() takes each night's result and moves the campaign on.

## The night to play next, from 0 (Night 1).
var night := 0
## The loadout budget the god has regained.
var dp := CampaignDef.START_DP
var bites := 0
## Path -> the path nights played on it, won or lost.
var tally := {"faith": 0, "theft": 0, "ruin": 0}
## The path of the most recent path night ("" before Night 2): a tie goes to it.
var last_path := ""
## Night 1's bell rang: Night 3's act starts in a warned town.
var bell_rang := false
var nights_won := 0
## "" while the campaign runs, else the ending it reached (CampaignDef.ENDINGS).
var ending := ""


func slots() -> int:
	return int(CampaignDef.night(night).slots)


## The missions tonight offers, [{mission, path}]: one, or a choice card.
func options() -> Array:
	return CampaignDef.night(night).options


## The strongest path, a tie going to the most recent path night; "" before any path night.
func path() -> String:
	var best := ""
	var most := 0
	for p in CampaignDef.PATHS:
		var n := int(tally.get(p, 0))
		if n > most or (n == most and n > 0 and p == last_path):
			best = p
			most = n
	return best


func title() -> String:
	return String(CampaignText.TITLES.get(path(), CampaignText.TITLES[""]))


## The memory fragment the ending opens with: The Vision before the Faith and Theft endings (on the Ruin path it was
## shown before Night 4), none before Eaten.
func ending_fragment() -> String:
	return "vision" if ending == CampaignDef.NEW_FAITH or ending == CampaignDef.FALSE_LANTERN else ""


## A mission tonight offers, ready for Prepare: a fresh def with the night's slots and the god's budget. A night's
## first act carries Night 1's bell, so the Feast's Prepare shows the town the act will meet.
func mission(id: String) -> MissionDef:
	var def := MissionBook.get_mission(id)
	def.slots = slots()
	def.dp_capacity = dp
	if def.has_acts():
		var n := NightState.new()
		n.bell_rang = bell_rang
		def.first_act().night = n
	return def


## Take tonight's result (Rules.result(), or NightState.result() for a Feast) for the mission played, and move on (spec
## §3): a path night counts for its path; a win adds DP and its bonus one more; a loss is a bite. Returns what changed,
## for the results: {won, dp_gain, bite, dp, bites, ending, path}.
func record(mission_id: String, result: Dictionary) -> Dictionary:
	var won := bool(result.get("won", false))
	var p := CampaignDef.path_of(night, mission_id)
	if p != "":
		tally[p] = int(tally.get(p, 0)) + 1
		last_path = p
	if night == 0:
		bell_rang = String(result.get("reason", "")) == "bell"
	var gain := 0
	if won:
		gain = CampaignDef.WIN_DP + (CampaignDef.BONUS_DP if _bonus_earned(result) else 0)
		dp += gain
		nights_won += 1
	else:
		bites += 1
		dp = maxi(CampaignDef.MIN_DP, dp - CampaignDef.BITE_DP)
	_advance(won)
	return {"won": won, "dp_gain": gain, "bite": not won, "dp": dp, "bites": bites, "ending": ending, "path": p}


## On to the next night, or to an ending: the third bite ends it; a won finale is the Kataclysm and a lost one is played
## again; after Night 3 the Faith and Theft paths reach their endings and the Ruin path goes on to the finale.
func _advance(won: bool) -> void:
	if bites >= CampaignDef.MAX_BITES:
		ending = CampaignDef.EATEN
		return
	if night == CampaignDef.FINALE:
		if won:
			ending = CampaignDef.KATACLYSM
		return
	var p := path()
	if night == CampaignDef.FINALE - 1 and p != "" and p != CampaignDef.RUIN:
		ending = CampaignDef.ending_for(p)
		return
	night += 1


## At most one bonus counts toward DP a night (spec §3.1).
static func _bonus_earned(result: Dictionary) -> bool:
	for b in result.get("bonuses", []):
		if bool((b as Dictionary).get("earned", false)):
			return true
	return false
```

- [ ] **Step 6: Run the tests to verify they pass.** Run Import, then Tests. Expected: `checks=N failures=0`.

- [ ] **Step 7: Commit.**

```bash
git add src/game/campaign/campaign_def.gd src/game/campaign/campaign_def.gd.uid src/game/campaign/campaign_text.gd src/game/campaign/campaign_text.gd.uid src/game/campaign/campaign_state.gd src/game/campaign/campaign_state.gd.uid tests/test_campaign.gd tests/test_campaign.gd.uid tests/run_all.gd
git commit -m "feat: the Lantern campaign as data and state (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 3: The campaign in the save file

**Files:**
- Modify: `src/game/campaign/campaign_state.gd`, `src/game/save_file.gd`
- Test: `tests/test_campaign.gd`

**Interfaces:**
- Consumes: `CampaignState` from Task 2.
- Produces:
  - `CampaignState.SECTION := "campaign"`, `CampaignState.write(cfg: ConfigFile) -> void`, `static CampaignState.read(cfg: ConfigFile) -> CampaignState` (null when the file has no campaign).
  - `SaveFile.campaign: CampaignState` (null when none was begun), loaded and saved with the rest.

- [ ] **Step 1: Write the failing test.** In `tests/test_campaign.gd`, add `_save(t)` as the last call in `run()`, and add:

```gdscript
## The campaign's section of the save file (spec §6): a round trip keeps everything, no section means no campaign, and a
## damaged section is pulled back into range (review focus 3).
static func _save(t) -> void:
	var path := "user://test_campaign.cfg"
	var s := CampaignState.new()
	s.record("warning", _lost("bell"))
	s.record("vigil_flame", _won(true))
	var save := SaveFile.new()
	save.campaign = s
	save.save_to(path)
	var c := SaveFile.new().load_from(path).campaign
	t.check(c != null and c.night == 2 and c.dp == 8 and c.bites == 1 and c.bell_rang and int(c.tally["theft"]) == 1
		and c.last_path == "theft" and c.nights_won == 1 and c.ending == "",
		"a campaign survives the save file (night %d, dp %d)" % [c.night if c else -1, c.dp if c else -1])
	t.check(SaveFile.new().load_from("user://no_such_campaign.cfg").campaign == null, "no save file: no campaign")
	SaveFile.new().save_to(path)
	t.check(SaveFile.new().load_from(path).campaign == null, "a save without a campaign has none")
	var cfg := ConfigFile.new()
	cfg.set_value(CampaignState.SECTION, "night", 9)
	cfg.set_value(CampaignState.SECTION, "dp", -3)
	cfg.set_value(CampaignState.SECTION, "bites", 7)
	cfg.set_value(CampaignState.SECTION, "tally_ruin", -2)
	cfg.set_value(CampaignState.SECTION, "last_path", "nonsense")
	cfg.set_value(CampaignState.SECTION, "ending", "nonsense")
	var d := CampaignState.read(cfg)
	t.check(d.night == CampaignDef.FINALE and d.dp == CampaignDef.MIN_DP and d.bites == CampaignDef.MAX_BITES
		and int(d.tally["ruin"]) == 0 and d.last_path == "" and d.ending == "eaten",
		"a damaged campaign is pulled back into range, and three bites read as Eaten")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
```

- [ ] **Step 2: Run the tests to verify they fail.** Expected: Parse Error naming `campaign` on `SaveFile`, or `SECTION`.

- [ ] **Step 3: The section in `CampaignState`.** Add to `src/game/campaign/campaign_state.gd`, under the class doc comment:

```gdscript
## The save file's section for the campaign (spec §6).
const SECTION := "campaign"
```

and at the end of the file:

```gdscript
func write(cfg: ConfigFile) -> void:
	cfg.set_value(SECTION, "night", night)
	cfg.set_value(SECTION, "dp", dp)
	cfg.set_value(SECTION, "bites", bites)
	for p in CampaignDef.PATHS:
		cfg.set_value(SECTION, "tally_" + p, int(tally.get(p, 0)))
	cfg.set_value(SECTION, "last_path", last_path)
	cfg.set_value(SECTION, "bell_rang", bell_rang)
	cfg.set_value(SECTION, "nights_won", nights_won)
	cfg.set_value(SECTION, "ending", ending)


## A campaign from the save file, or null when it holds none. Values out of range are pulled back in, so a hand-edited
## or older file cannot put the campaign on a night that does not exist; three bites with no ending read as Eaten.
static func read(cfg: ConfigFile) -> CampaignState:
	if not cfg.has_section(SECTION):
		return null
	var s := CampaignState.new()
	s.night = clampi(int(cfg.get_value(SECTION, "night", 0)), 0, CampaignDef.FINALE)
	s.dp = maxi(int(cfg.get_value(SECTION, "dp", CampaignDef.START_DP)), CampaignDef.MIN_DP)
	s.bites = clampi(int(cfg.get_value(SECTION, "bites", 0)), 0, CampaignDef.MAX_BITES)
	for p in CampaignDef.PATHS:
		s.tally[p] = maxi(int(cfg.get_value(SECTION, "tally_" + p, 0)), 0)
	var lp := String(cfg.get_value(SECTION, "last_path", ""))
	s.last_path = lp if CampaignDef.PATHS.has(lp) else ""
	s.bell_rang = bool(cfg.get_value(SECTION, "bell_rang", false))
	s.nights_won = maxi(int(cfg.get_value(SECTION, "nights_won", 0)), 0)
	var e := String(cfg.get_value(SECTION, "ending", ""))
	s.ending = e if CampaignDef.ENDINGS.has(e) else ""
	if s.bites >= CampaignDef.MAX_BITES and s.ending == "":
		s.ending = CampaignDef.EATEN
	return s
```

- [ ] **Step 4: The campaign in `SaveFile`.** In `src/game/save_file.gd`:
  - Add a line to the class doc comment, after the `[mission.<id>]` line: `##   [campaign]            night, dp, bites, tally_<path>, last_path, bell_rang, nights_won, ending (v0.10)`.
  - Under `var last_mission`, add:

```gdscript
## The Lantern campaign begun or ended (v0.10), or null when none was ever begun.
var campaign: CampaignState
```

  - In `load_from()`, just before its final `return self`, add `campaign = CampaignState.read(cfg)`.
  - In `save_to()`, just before `var err := cfg.save(path)`, add:

```gdscript
	if campaign != null:
		campaign.write(cfg)
```

- [ ] **Step 5: Run the tests to verify they pass.** Expected: `checks=N failures=0`, with the existing `test_save_file` checks still passing.

- [ ] **Step 6: Commit.**

```bash
git add src/game/campaign/campaign_state.gd src/game/save_file.gd tests/test_campaign.gd
git commit -m "feat: the campaign in the save file (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 4: The night screen and the ending screen

**Files:**
- Create: `src/game/ui/campaign_screen.gd`, `src/game/ui/ending_screen.gd`, `tests/test_campaign_screens.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: `CampaignState`, `CampaignDef`, `CampaignText` (Tasks 2–3); `Menu`, `UiTheme`, `UiSound`.
- Produces:
  - `CampaignScreen`:
    - `signal action(name: String)`: `"draft"` (with `chosen`), `"restart"` (only on a second press), `"title"`;
    - `chosen: String`, `options: Array` (of `MissionDef`, from `CampaignState.mission()`), `selected: int`, `confirming: bool`;
    - `setup(state: CampaignState) -> CampaignScreen`, `choose(id: String)`, `click(point: Vector2)`, `button_rect(what: String) -> Rect2`, `hit(point: Vector2) -> int`;
    - `static card_rect(i: int, count: int) -> Rect2`, `static status_text(s: CampaignState) -> String`, `static card_line(def: MissionDef, s: CampaignState) -> String`;
    - `PANEL`, `HINT_Y`.
  - `EndingScreen`: `signal action(name: String)` (`"title"`), `pages: Array[Dictionary]`, `page: int`, `setup(ending: String, fragment: String) -> EndingScreen`, `turn()`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_campaign_screens.gd`:

```gdscript
extends RefCounted
## v0.10 the campaign's screens: the night screen's cards fit and choose like the interlude's, Choose powers waits for a
## card, "New campaign" asks twice (review focus 4), the status line names the budget, bites and title; a draft opened
## after a bite keeps what fits (review focus 1); the ending turns its pages.


static func run(t) -> void:
	for count in [1, 2, 3]:
		var bad := 0
		for i in count:
			var r := CampaignScreen.card_rect(i, count)
			if not CampaignScreen.PANEL.encloses(r) or r.end.y > CampaignScreen.HINT_Y - 8.0:
				bad += 100
			for j in range(i + 1, count):
				if r.intersects(CampaignScreen.card_rect(j, count)):
					bad += 1
		t.check(bad == 0, "%d night card(s) fit the panel above the hint without touching (%d)" % [count, bad])

	var s := CampaignState.new()
	s.night = 1
	var night := CampaignScreen.new()
	night.setup(s)
	var emitted: Array[String] = []
	night.action.connect(func(what: String) -> void: emitted.append(what))
	t.check(night.options.size() == 3 and night.chosen == "", "Night 2 shows three cards, none chosen")
	t.check((night.options[2] as MissionDef).slots == 3 and (night.options[2] as MissionDef).dp_capacity == 6,
		"each card's mission carries the campaign's slots and budget")
	night.click(night.button_rect("draft").get_center())
	t.check(emitted.is_empty(), "Choose powers is refused until a card is chosen (%s)" % [emitted])
	night.click(CampaignScreen.card_rect(2, 3).get_center())
	t.check(night.chosen == MissionBook.BROKEN_LANTERNS, "a click on the third card chooses Broken Lanterns (%s)" % night.chosen)
	night.click(night.button_rect("restart").get_center())
	t.check(emitted.is_empty() and night.confirming, "New campaign asks again before it starts over")
	night.click(night.button_rect("restart").get_center())
	night.click(night.button_rect("draft").get_center())
	t.check(",".join(emitted) == "restart,draft", "the second press starts over; Choose powers goes (%s)" % [emitted])
	night.free()

	var one := CampaignScreen.new()
	one.setup(CampaignState.new())
	t.check(one.options.size() == 1 and one.chosen == MissionBook.WARNING, "Night 1's one mission is chosen at setup")
	one.free()
	t.check(CampaignScreen.status_text(CampaignState.new()) == "6 DP   3 slots   Bites 0 / 3   The Forgotten",
		"the status line: %s" % CampaignScreen.status_text(CampaignState.new()))
	t.check(CampaignScreen.card_line(MissionBook.vigil_flame(), s) == CampaignText.CARD_LINES["vigil_flame"],
		"a Night 2 card carries Cael's line")
	var warned := CampaignState.new()
	warned.night = 2
	warned.bell_rang = true
	t.check(CampaignScreen.card_line(warned.mission(MissionBook.FEAST_FESTIVAL), warned)
		== "The bell rang: soldiers watch the square.", "a Feast card carries The Long Night's line for the town it meets")

	# Review focus 1: after a bite the budget is 4; a saved 6-DP loadout opens with what fits, in its order.
	var bitten := CampaignState.new()
	bitten.dp = 4
	var draft := Draft.new().for_mission(bitten.mission(MissionBook.WARNING))
	draft.preselect(PackedStringArray(["wisp", "discord", "whisper"]))
	t.check(draft.picks == PackedStringArray(["wisp", "discord"]) and draft.spent() == 4,
		"a loadout over the bitten budget keeps what fits (%s)" % [draft.picks])

	var end := EndingScreen.new()
	end.setup(CampaignDef.FALSE_LANTERN, "vision")
	var out: Array[String] = []
	end.action.connect(func(what: String) -> void: out.append(what))
	t.check(end.pages.size() == 2 and end.page == 0 and String(end.pages[0].title) == "The Vision"
		and String(end.pages[1].title) == "The False Lantern", "the Theft ending: The Vision, then The False Lantern")
	end.turn()
	t.check(end.page == 1 and out.is_empty(), "a turn shows the ending")
	end.turn()
	t.check(",".join(out) == "title", "a turn on the last page leaves for the title (%s)" % [out])
	end.free()
	var eaten := EndingScreen.new()
	eaten.setup(CampaignDef.EATEN, "")
	t.check(eaten.pages.size() == 1 and String(eaten.pages[0].title) == "Eaten", "Eaten has one page")
	eaten.free()
```

Register it: add `"res://tests/test_campaign_screens.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: `suite failed to load: res://tests/test_campaign_screens.gd` or a Parse Error naming `CampaignScreen`.

- [ ] **Step 3: Write `CampaignScreen`.** Create `src/game/ui/campaign_screen.gd`:

```gdscript
class_name CampaignScreen
extends Node
## The Lantern campaign between nights (v0.10, spec §4-§5): where the campaign stands -- the night and its Tier, the
## god's Divine Power and slots, Halcyon's bites, the title its path has given it -- Cael's memory fragment for tonight,
## and tonight's mission: one line, or a choice card per mission. "Choose powers" goes on to Prepare with `chosen`;
## "New campaign" asks twice before it starts over; "Title", or Esc, leaves.

## "draft" (on to Prepare with `chosen`), "restart" (on the second press) or "title".
signal action(name: String)

const PANEL := Rect2(16.0, 10.0, 608.0, 340.0)
## The baselines of the night's name and the status line; the fragment's title, and the width its text wraps to.
const HEAD_Y := 36.0
const STATUS_Y := 54.0
const FRAGMENT_Y := 80.0
const FRAGMENT_W := 560.0
## The cards: their row's top, their height, the widest a card gets, the gap between two and the padding inside one.
const CARD_TOP := 168.0
const CARD_H := 128.0
const CARD_MAX_W := 284.0
const CARD_GAP := 10.0
const PAD := 8.0
## The single mission's line, the hint over the buttons, and the buttons' row.
const ONE_Y := 210.0
const HINT_Y := 310.0
const BUTTONS_Y := 318.0

## The mission chosen for tonight ("" until a card is chosen); with one mission, that one from setup().
var chosen := ""
## Tonight's missions, ready for Prepare (CampaignState.mission()), and the card the keyboard is on.
var options: Array = []
var selected := 0
## True once "New campaign" has been pressed once: the next press starts over, any other press forgets it.
var confirming := false

var _state: CampaignState
var _ui: Control
var _menu: Menu
var _hover := ""


## Where card `i` of `count` sits: side by side inside the panel, the row centred on 320.
static func card_rect(i: int, count: int) -> Rect2:
	var n := maxi(count, 1)
	var w := minf(CARD_MAX_W, floorf((PANEL.size.x - PAD * 2.0 - float(n - 1) * CARD_GAP) / float(n)))
	var total := float(n) * w + float(n - 1) * CARD_GAP
	var left := roundf(320.0 - total * 0.5)
	return Rect2(Vector2(left + float(i) * (w + CARD_GAP), CARD_TOP), Vector2(w, CARD_H))


## "8 DP   3 slots   Bites 1 / 3   The Deceiver".
static func status_text(s: CampaignState) -> String:
	return "%d DP   %d slots   Bites %d / %d   %s" % [s.dp, s.slots(), s.bites, CampaignDef.MAX_BITES, s.title()]


## Cael's line on a card: his own for a Night 2 mission, else the night's first act's line on how the town will meet the
## player (the Feast, from The Long Night).
static func card_line(def: MissionDef, s: CampaignState) -> String:
	if CampaignText.CARD_LINES.has(def.id):
		return String(CampaignText.CARD_LINES[def.id])
	if def.has_acts():
		var n := NightState.new()
		n.bell_rang = s.bell_rang
		return def.first_act().card_line(n)
	return ""


func setup(state: CampaignState) -> CampaignScreen:
	_state = state
	options = []
	for o: Dictionary in state.options():
		options.append(state.mission(String(o.mission)))
	if options.size() == 1:
		chosen = (options[0] as MissionDef).id
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	_menu = Menu.row(["draft", "restart", "title"], ["Choose powers", "New campaign", "Title"], 320.0, BUTTONS_Y, 128.0)
	return self


## Choose tonight's mission by id, as a click on its card would (the FLOW test).
func choose(id: String) -> void:
	for i in options.size():
		if (options[i] as MissionDef).id == id:
			selected = i
			chosen = id
			if _ui != null:
				_ui.queue_redraw()
			return
	push_warning("KAK has no mission called %s tonight" % id)


func button_rect(what: String) -> Rect2:
	return _menu.rect_of(what)


## The card under a point, or -1. With one mission there are no cards.
func hit(point: Vector2) -> int:
	if options.size() < 2:
		return -1
	for i in options.size():
		if card_rect(i, options.size()).has_point(point):
			return i
	return -1


func click(point: Vector2) -> void:
	var i := hit(point)
	if i >= 0:
		confirming = false
		UiSound.play(&"ui_manifest")
		choose((options[i] as MissionDef).id)
		return
	var a := _menu.at(point)
	if a != "":
		_press(a)


## "Choose powers" goes once a mission is chosen; "New campaign" asks twice; "Title" always goes.
func _press(what: String) -> void:
	if what == "restart" and not confirming:
		confirming = true
		UiSound.play(&"ui_buzz")
		_ui.queue_redraw()
		return
	if what != "restart":
		confirming = false
	if what == "draft" and chosen == "":
		UiSound.play(&"ui_buzz")
		return
	UiSound.play(&"ui_click")
	action.emit(what)


func _select(i: int) -> void:
	if options.size() < 2:
		return
	i = posmod(i, options.size())
	if i != selected:
		selected = i
		UiSound.play(&"ui_hover")
		_ui.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			UiSound.play(&"ui_click")
			action.emit("title")
		elif event.physical_keycode == KEY_LEFT:
			_select(selected - 1)
		elif event.physical_keycode == KEY_RIGHT:
			_select(selected + 1)
		elif event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
			# Enter chooses the card the keyboard is on; once it is chosen, Enter goes on to the draft.
			if options.size() >= 2 and chosen != (options[selected] as MissionDef).id:
				UiSound.play(&"ui_manifest")
				choose((options[selected] as MissionDef).id)
			else:
				_press("draft")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var card := hit(event.position)
		if card >= 0:
			_select(card)
		var h := _menu.at(event.position)
		if h != _hover:
			_hover = h
			if h != "":
				UiSound.play(&"ui_hover")
			_ui.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click(event.position)


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.0, 0.0, 0.0, 0.85))
	_ui.draw_rect(PANEL, Color(0.03, 0.03, 0.05, 0.92))
	UiTheme.frame(_ui, PANEL, true)
	var n := CampaignDef.night(_state.night)
	_centred("NIGHT %d - TIER %d" % [_state.night + 1, int(n.tier)], HEAD_Y, UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	_centred(status_text(_state), STATUS_Y, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)

	var fragment: Dictionary = CampaignText.FRAGMENTS.get(String(n.fragment), {})
	var y := FRAGMENT_Y
	_centred(String(fragment.get("title", "")), y, UiTheme.SIZE_BODY, UiTheme.COL_GOLD_DARK)
	y += UiTheme.LINE_BODY + 4.0
	for line in UiTheme.wrap(String(fragment.get("text", "")), FRAGMENT_W, UiTheme.SIZE_BODY):
		_centred(line, y, UiTheme.SIZE_BODY, UiTheme.COL_TEXT)
		y += UiTheme.LINE_BODY

	if options.size() >= 2:
		for i in options.size():
			_draw_card(card_rect(i, options.size()), options[i] as MissionDef, i)
		var hint := "Left and Right, then Enter, to choose tonight's mission" if chosen == "" \
			else "Enter or Choose powers to draft for it"
		if confirming:
			hint = "Press New campaign again to start over"
		_centred(hint, HINT_Y, UiTheme.SIZE_SMALL, UiTheme.COL_BAD if confirming else UiTheme.COL_DIM)
	elif options.size() == 1:
		var def := options[0] as MissionDef
		_centred("Tonight: " + def.name, ONE_Y, UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
		var by := ONE_Y + 22.0
		for k in mini(def.brief.size(), 2):
			_centred(def.brief[k], by, UiTheme.SIZE_BODY, UiTheme.COL_TEXT)
			by += UiTheme.LINE_BODY
		if confirming:
			_centred("Press New campaign again to start over", HINT_Y, UiTheme.SIZE_SMALL, UiTheme.COL_BAD)
	_menu.draw_on(_ui, _hover, PackedStringArray(["draft"]) if chosen == "" else PackedStringArray())


func _centred(s: String, y: float, size: int, col: Color) -> void:
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(s, size) * 0.5), y), s, size, col)


## One card, top to bottom: the mission's name, its path, its brief, then Cael's line in gold at the foot. The chosen
## card wears the bright frame; the one the keyboard is on is lit.
func _draw_card(r: Rect2, def: MissionDef, i: int) -> void:
	var on := def.id == chosen
	_ui.draw_rect(r, Color(0.12, 0.1, 0.05, 0.95) if on else (Color(0.1, 0.09, 0.07, 0.9) if i == selected
		else UiTheme.COL_PANEL))
	UiTheme.frame(_ui, r, on)
	var x := r.position.x + PAD
	var room := r.size.x - PAD * 2.0
	var y := r.position.y + PAD + 12.0
	UiTheme.text(_ui, Vector2(x, y), UiTheme.fit(def.name, room, UiTheme.SIZE_BIG), UiTheme.SIZE_BIG,
		UiTheme.COL_GOLD if on else UiTheme.COL_GOLD_DARK)
	y += UiTheme.LINE_BODY
	var p := CampaignDef.path_of(_state.night, def.id)
	if p != "":
		UiTheme.text(_ui, Vector2(x, y), String(CampaignText.PATH_NAMES.get(p, "")), UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	y += UiTheme.LINE_SMALL + 4.0
	var text_col := UiTheme.COL_TEXT if on or i == selected else UiTheme.COL_DIM
	for k in mini(def.brief.size(), 2):
		for line in UiTheme.wrap(def.brief[k], room, UiTheme.SIZE_SMALL):
			UiTheme.text(_ui, Vector2(x, y), line, UiTheme.SIZE_SMALL, text_col)
			y += UiTheme.LINE_SMALL
	var meet := UiTheme.wrap(card_line(def, _state), room, UiTheme.SIZE_SMALL)
	var foot := r.end.y - PAD - UiTheme.LINE_SMALL * float(maxi(meet.size() - 1, 0))
	for line in meet:
		UiTheme.text(_ui, Vector2(x, foot), line, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
		foot += UiTheme.LINE_SMALL
```

`UiTheme.fit(s, room, size)` exists at `src/game/ui/ui_theme.gd:85` (it trims a string to fit). If its signature differs, use `UiTheme.wrap(...)[0]`.

- [ ] **Step 4: Write `EndingScreen`.** Create `src/game/ui/ending_screen.gd`:

```gdscript
class_name EndingScreen
extends Node
## The campaign's ending (v0.10, spec §5.4): Cael's last memory first when the path has one (The Vision, before the
## Faith and Theft endings), then the ending's title, its epilogue and, for an ending with no playable last night yet,
## a note saying so. Enter or a click turns the page; on the last page it leaves for the title, as Esc always does.

## "title".
signal action(name: String)

const PANEL := Rect2(56.0, 40.0, 528.0, 280.0)
## The page's title baseline, the width its text wraps to, and the button's row.
const TITLE_Y := 100.0
const TEXT_W := 440.0
const BUTTON_Y := 288.0

## The pages in order: {title, text, note}.
var pages: Array[Dictionary] = []
var page := 0

var _ui: Control
var _menu: Menu
var _hover := ""


func setup(ending: String, fragment: String) -> EndingScreen:
	if fragment != "" and CampaignText.FRAGMENTS.has(fragment):
		pages.append(CampaignText.FRAGMENTS[fragment])
	pages.append(CampaignText.ENDINGS.get(ending, CampaignText.ENDINGS[CampaignDef.EATEN]))
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	_build_menu()
	return self


## The next page, or the title from the last one.
func turn() -> void:
	if page < pages.size() - 1:
		page += 1
		_build_menu()
		_ui.queue_redraw()
		return
	action.emit("title")


func _build_menu() -> void:
	var last := page >= pages.size() - 1
	_menu = Menu.row(["next"], ["Title" if last else "Continue"], 320.0, BUTTON_Y, 120.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			UiSound.play(&"ui_click")
			action.emit("title")
		elif event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
			UiSound.play(&"ui_click")
			turn()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := _menu.at(event.position)
		if h != _hover:
			_hover = h
			_ui.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _menu.at(event.position) != "":
			UiSound.play(&"ui_click")
			turn()


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.0, 0.0, 0.0, 0.9))
	_ui.draw_rect(PANEL, Color(0.03, 0.03, 0.05, 0.92))
	UiTheme.frame(_ui, PANEL, true)
	var p := pages[page]
	var title := String(p.get("title", ""))
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(title, UiTheme.SIZE_TITLE) * 0.5), TITLE_Y), title,
		UiTheme.SIZE_TITLE, UiTheme.COL_GOLD)
	var y := TITLE_Y + 36.0
	for line in UiTheme.wrap(String(p.get("text", "")), TEXT_W, UiTheme.SIZE_BODY):
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(line, UiTheme.SIZE_BODY) * 0.5), y), line, UiTheme.SIZE_BODY)
		y += UiTheme.LINE_BODY
	var note := String(p.get("note", ""))
	if note != "":
		y += 12.0
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(note, UiTheme.SIZE_SMALL) * 0.5), y), note,
			UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	_menu.draw_on(_ui, _hover)
```

- [ ] **Step 5: Run the tests to verify they pass.** Run Import, then Tests. Expected: `checks=N failures=0`.

- [ ] **Step 6: Commit.**

```bash
git add src/game/ui/campaign_screen.gd src/game/ui/campaign_screen.gd.uid src/game/ui/ending_screen.gd src/game/ui/ending_screen.gd.uid tests/test_campaign_screens.gd tests/test_campaign_screens.gd.uid tests/run_all.gd
git commit -m "feat: the campaign's night screen and ending screen (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 5: The campaign in the game's flow

**Files:**
- Modify: `src/game/game.gd`, `src/game/mission.gd`, `src/game/ui/results_screen.gd`, `src/game/ui/pause_menu.gd`, `src/game/ui/title_screen.gd`
- Test: `tests/test_flow.gd`, `tests/test_campaign_screens.gd`

**Interfaces:**
- Consumes: everything from Tasks 1–4.
- Produces:
  - `Game.Screen` gains `CAMPAIGN` and `ENDING` (at the end).
  - FLOW gains `"title:campaign"`, `"campaign:draft"`, `"campaign:title"`, `"prepare:campaign"`, `"results:next"`, `"results:ending"`, `"pause:campaign"`, `"ending:title"`.
  - `Game._in_campaign: bool`.
  - `Mission.bell_rang: bool`, which seeds `NightState.bell_rang` at `start()`.
  - `ResultsScreen.campaign: bool`, `static ResultsScreen.campaign_line(c: Dictionary) -> String`.
  - `PauseMenu.setup(campaign := false)`: its last button is `"campaign"` / "Campaign" in a campaign.
  - Title: a "Campaign" button (`"campaign"`) above "Missions" (the old "Play", action still `"play"`).

- [ ] **Step 1: Write the failing tests.** In `tests/test_flow.gd`:
  - Replace the check `reachable.size() == Game.Screen.size() and Game.Screen.size() == 6` with `reachable.size() == Game.Screen.size() and Game.Screen.size() == 8` and its message with `"all eight screens are reachable (%d)"`.
  - After the `"prepare:begin"` check, add:

```gdscript
	# The Lantern campaign (v0.10): the night screen, its draft, the night's results, Pause's way back, the ending.
	t.check(Game.next_screen("title:campaign") == Game.Screen.CAMPAIGN, "Campaign leads to the night screen")
	t.check(Game.next_screen("campaign:draft") == Game.Screen.PREPARE, "its Choose powers leads to Prepare")
	t.check(Game.next_screen("campaign:title") == Game.Screen.TITLE, "and its Title to the title")
	t.check(Game.next_screen("prepare:campaign") == Game.Screen.CAMPAIGN, "Back from a campaign draft returns to the night")
	t.check(Game.next_screen("results:next") == Game.Screen.CAMPAIGN, "a campaign night's Continue leads to the next night")
	t.check(Game.next_screen("results:ending") == Game.Screen.ENDING, "or to the ending")
	t.check(Game.next_screen("pause:campaign") == Game.Screen.CAMPAIGN, "Pause can leave a night for the night screen")
	t.check(Game.next_screen("ending:title") == Game.Screen.TITLE, "and the ending leads to the title")
```

  In `tests/test_campaign_screens.gd`, at the end of `run()`, add:

```gdscript
	# Results in a campaign: one Continue, and the line on what the night did.
	var res := ResultsScreen.new()
	res.setup({"mission": "warning", "won": true, "reason": "omen", "goal": {"label": "Stop the warning", "done": true},
		"campaign": {"won": true, "dp_gain": 2, "dp": 8, "bites": 0, "ending": ""}})
	t.check(res.campaign and res._menu.items.size() == 1 and String(res._menu.items[0].action) == "next",
		"a campaign night's results offer one Continue")
	res.free()
	t.check(ResultsScreen.campaign_line({"won": true, "dp_gain": 3, "dp": 9}) == "The god grows: +3 DP, 9 DP now.",
		"a won night's line")
	t.check(ResultsScreen.campaign_line({"won": false, "dp": 5, "bites": 1}) == "Halcyon bites: 5 DP now. Bites 1 / 3.",
		"a lost night's line")
	t.check(ResultsScreen.campaign_line({"won": false, "dp": 4, "bites": 3, "ending": "eaten"}) == "Halcyon has eaten you.",
		"the last bite's line")
	var pause := PauseMenu.new()
	pause.setup(true)
	t.check(String(pause._menu.items[3].action) == "campaign" and String(pause._menu.items[3].label) == "Campaign",
		"in a campaign, Pause's last button is Campaign")
	pause.free()
```

- [ ] **Step 2: Run the tests to verify they fail.** Expected: Parse Error naming `CAMPAIGN`, or FAIL lines for the new checks.

- [ ] **Step 3: Mission seeds the night's bell.** In `src/game/mission.gd`:
  - Under `var mission_id := ...`, add:

```gdscript
## A night that starts with its town already warned (v0.10: the campaign's Feast after a rung Night 1). Game sets it
## before start(); a mission without acts ignores it.
var bell_rang := false
```

  - In `start()`, directly after `_night = NightState.new() if _def.has_acts() else null`, add:

```gdscript
	if _night != null:
		_night.bell_rang = bell_rang
```

- [ ] **Step 4: Results in a campaign.** In `src/game/ui/results_screen.gd`:
  - Under `var _hover := ""`, add:

```gdscript
## A campaign night's results (v0.10): one Continue, and a line on what the night did to the god's power.
var campaign := false
```

  - Add a constant under `NOBODY`:

```gdscript
## The baseline of a campaign night's line, over the button.
const CAMPAIGN_Y := 304.0
```

  - In `setup()`, replace the `_menu = Menu.row([...])` line with:

```gdscript
	campaign = result.has("campaign")
	if campaign:
		_menu = Menu.row(["next"], ["Continue"], 320.0, PANEL.end.y - 28.0, 120.0)
	else:
		_menu = Menu.row(["replay", "change", "missions"], ["Replay", "Change powers", "Missions"], 320.0,
			PANEL.end.y - 28.0, 120.0)
```

  - At the start of `_unhandled_input()`'s key branch, before the Enter check, add:

```gdscript
		if campaign:
			if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
				action.emit("next")
			return
```

  - Add:

```gdscript
## What a campaign night did to the god (v0.10): grown, bitten, or eaten.
static func campaign_line(c: Dictionary) -> String:
	if String(c.get("ending", "")) == CampaignDef.EATEN:
		return "Halcyon has eaten you."
	if bool(c.get("won", false)):
		return "The god grows: +%d DP, %d DP now." % [int(c.get("dp_gain", 0)), int(c.get("dp", 0))]
	return "Halcyon bites: %d DP now. Bites %d / %d." % [int(c.get("dp", 0)), int(c.get("bites", 0)), CampaignDef.MAX_BITES]


## The buttons, and over them a campaign night's line.
func _draw_menu() -> void:
	if campaign:
		var c: Dictionary = _result.campaign
		var line := campaign_line(c)
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(line, UiTheme.SIZE_BODY) * 0.5), CAMPAIGN_Y), line,
			UiTheme.SIZE_BODY, UiTheme.COL_GOLD if bool(c.get("won", false)) else UiTheme.COL_BAD)
	_menu.draw_on(_ui, _hover)
```

  - Replace every `_menu.draw_on(_ui, _hover)` in `results_screen.gd` (there are three, one per kind of result) with `_draw_menu()`.

- [ ] **Step 5: Pause and the title.**
  - In `src/game/ui/pause_menu.gd`, replace `setup()`'s signature and menu line:

```gdscript
## `campaign` (v0.10): the last button leads back to the campaign's night screen instead of the board.
func setup(campaign := false) -> PauseMenu:
```

```gdscript
	_menu = Menu.column(["resume", "restart", "change", "campaign" if campaign else "missions"],
		["Resume", "Restart", "Change powers", "Campaign" if campaign else "Missions"], 320.0, 148.0, 140.0)
```

  - Update the signal's doc comment to add `"campaign"` (v0.10).
  - In `src/game/ui/title_screen.gd`:
    - Replace the menu line with `_menu = Menu.column(["campaign", "play", "sandbox", "quit"], ["Campaign", "Missions", "VFX Sandbox", "Quit"], 320.0, 184.0, 132.0)`.
    - Update the class doc ("four ways on: the Campaign, the Missions board, the VFX Sandbox, Quit") and the signal's doc (`"campaign"`, `"play"`, `"sandbox"` or `"quit"`). Enter still emits `"play"`.

- [ ] **Step 6: Game's screens and flow.** In `src/game/game.gd`:
  - Replace the enum with `enum Screen {TITLE, BOARD, PREPARE, MISSION, RESULTS, INTERLUDE, CAMPAIGN, ENDING}`.
  - Add to `FLOW`, after `"prepare:begin"`:

```gdscript
	# The Lantern campaign (v0.10): its night screen, the draft for tonight, the night's results leading on to the next
	# night or the ending, and Pause's way back to the night screen.
	"title:campaign": Screen.CAMPAIGN,
	"campaign:draft": Screen.PREPARE,
	"campaign:title": Screen.TITLE,
	"prepare:campaign": Screen.CAMPAIGN,
	"results:next": Screen.CAMPAIGN,
	"results:ending": Screen.ENDING,
	"pause:campaign": Screen.CAMPAIGN,
	"ending:title": Screen.TITLE,
```

  - Under `var _interlude: InterludeScreen`, add:

```gdscript
## True while the Lantern campaign is being played (v0.10), from its night screen until the title or the board: Prepare
## drafts within the campaign's slots and budget, a finished night is recorded on it, and Pause and Results lead back to
## its night screen.
var _in_campaign := false
```

  - In `go_to()`, right after `screen = to`, add:

```gdscript
	if to == Screen.TITLE or to == Screen.BOARD:
		_in_campaign = false
	elif to == Screen.CAMPAIGN:
		_in_campaign = true
```

  - In `go_to()`'s `Screen.PREPARE` branch, turn the `else:` into an `elif` chain:

```gdscript
			elif _in_campaign and save.campaign != null:
				prep.setup(save.campaign.mission(mission_id), loadout, save.difficulty)
			else:
				prep.setup(MissionBook.get_mission(mission_id), loadout, save.difficulty)
```

  - In `go_to()`'s `Screen.RESULTS` branch, replace the `res.action.connect(...)` line with `res.action.connect(func(what: String) -> void: on_action(_results_action(what)))`.
  - Add two branches to `go_to()`'s first `match to:`, before `_:`:

```gdscript
		Screen.CAMPAIGN:
			var night := CampaignScreen.new()
			night.name = "Campaign"
			add_child(night)
			night.setup(save.campaign)
			night.action.connect(_on_campaign_action.bind(night))
			_screen_node = night
		Screen.ENDING:
			var end := EndingScreen.new()
			end.name = "Ending"
			add_child(end)
			end.setup(save.campaign.ending, save.campaign.ending_fragment())
			end.action.connect(func(what: String) -> void: on_action("ending:" + what))
			_screen_node = end
```

  - In the music `match to:`, change `Screen.TITLE, Screen.BOARD, Screen.PREPARE:` to `Screen.TITLE, Screen.BOARD, Screen.PREPARE, Screen.CAMPAIGN, Screen.ENDING:`.
  - In `_build_mission()`, after `mission.mission_id = mission_id`, add `mission.bell_rang = _in_campaign and save.campaign != null and save.campaign.bell_rang`.
  - In `_on_mission_finished()`, after `result = outcome`, add:

```gdscript
	if _in_campaign and save.campaign != null:
		result["campaign"] = save.campaign.record(mission_id, result)
```

  - In `_on_prepare_action()`, after the `if _between_acts:` block and before `if what == "manifest":`, add:

```gdscript
	if what == "back" and _in_campaign:
		on_action("prepare:campaign")
		return
```

  - In `_open_pause()`, change `_pause.setup()` to `_pause.setup(_in_campaign)`.
  - In `_on_title_action()`, add before `_:`:

```gdscript
		"campaign":
			# A campaign that has reached its ending is over: Campaign begins a fresh one (review focus 3).
			if save.campaign == null or save.campaign.ending != "":
				save.campaign = CampaignState.new()
				save.save_to(save_path)
			on_action("title:campaign")
```

  - Add these functions after `_on_board_action()`:

```gdscript
## The night screen's buttons (v0.10): on to Prepare for tonight's mission, with the loadout last drafted for it; a
## fresh campaign; or back to the title, where the board's mission is the one last picked there.
func _on_campaign_action(what: String, night: CampaignScreen) -> void:
	match what:
		"draft":
			mission_id = night.chosen
			loadout = save.loadout_for(mission_id)
			if loadout.is_empty():
				loadout = MissionBook.get_mission(mission_id).default_loadout
			on_action("campaign:draft")
		"restart":
			save.campaign = CampaignState.new()
			save.save_to(save_path)
			go_to(Screen.CAMPAIGN)
		"title":
			mission_id = save.last_mission
			loadout = starting_loadout(save, mission_id)
			on_action("campaign:title")


## A Results button's action (v0.10): a campaign night's Continue leads to the ending once the campaign has one.
func _results_action(what: String) -> String:
	if what == "next" and _in_campaign and save.campaign != null and save.campaign.ending != "":
		return "results:ending"
	return "results:" + what
```

  - In `_ready()`'s `match show:`, add before `_:`:

```gdscript
			"campaign":
				if save.campaign == null:
					save.campaign = CampaignState.new()
				go_to(Screen.CAMPAIGN)
			"campaign-choice":
				# Night 2's three cards (v0.10), for the photograph; the save is not written.
				save.campaign = CampaignState.new()
				save.campaign.night = 1
				save.campaign.dp = 8
				go_to(Screen.CAMPAIGN)
			"ending":
				save.campaign = CampaignState.new()
				save.campaign.ending = CampaignDef.FALSE_LANTERN
				go_to(Screen.ENDING)
```

- [ ] **Step 7: Run the tests to verify they pass.** Run Import, then Tests. Expected: `checks=N failures=0`.

- [ ] **Step 8: Run the exact gates.** Digest, crowd_check, the ten behaviour checksums, FLOW (the old 62 checks must still pass) and the Mission test. Expected: all unchanged. The campaign code runs only from the night screen.

- [ ] **Step 9: Photographs.** Capture `--show=campaign`, `--show=campaign-choice` and `--show=ending`. Check them by eye:
  - no text runs off a card or the panel;
  - the hint does not touch the buttons;
  - the fragment's text fits above the cards.

  Fix placement constants if needed, and report what changed.

- [ ] **Step 10: Commit.**

```bash
git add src/game/game.gd src/game/mission.gd src/game/ui/results_screen.gd src/game/ui/pause_menu.gd src/game/ui/title_screen.gd tests/test_flow.gd tests/test_campaign_screens.gd
git commit -m "feat: the campaign in the game's flow: night screen, results, pause, ending (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 6: The FLOW test plays a campaign

**Files:**
- Modify: `src/game/game.gd`

**Interfaces:**
- Consumes: Task 5's flow, `CampaignScreen.choose()`, `click()`, `button_rect()`; `EndingScreen.turn()`; `ResultsScreen.action`.

- [ ] **Step 1: Write the FLOW steps.** In `src/game/game.gd`, in `_flow_test()`, just before the final `print("FLOW result ...")` line, add `await _flow_campaign(step)`. The test is then on the title. Add the function after `_night_to_redraft()`:

```gdscript
## The Lantern campaign through the screens (v0.10), from the title: Night 1 won on its clock, Night 2's three cards
## and the Theft placeholder held, Night 3's Festival lost on its clock (a bite, and the Theft ending), then the ending's
## two pages; a fresh campaign after it; nights left unfinished (review focus 2); the board after the campaign (review
## focus 5). Starts and ends on the title.
func _flow_campaign(step: Callable) -> void:
	var quiet := PackedStringArray(["whisper", "doom", "discord"])
	(_screen_node as TitleScreen).action.emit("campaign")
	var night := _screen_node as CampaignScreen
	step.call(screen == Screen.CAMPAIGN and night != null and save.campaign != null and save.campaign.night == 0
		and night.chosen == MissionBook.WARNING, "Campaign opens Night 1 of a fresh campaign, The Warning chosen")
	night.click(night.button_rect("draft").get_center())
	var prep := _screen_node as PrepareScreen
	step.call(screen == Screen.PREPARE and prep != null and prep.mission.id == MissionBook.WARNING
		and prep.draft.slots == 3 and prep.draft.capacity == 6, "its draft has the campaign's 3 slots and 6 DP")

	# Review focus 2: Back from the draft records nothing.
	_on_prepare_action("back", prep)
	step.call(screen == Screen.CAMPAIGN and save.campaign.night == 0 and save.campaign.dp == 6,
		"Back from a campaign draft returns to the night, nothing recorded")
	(_screen_node as CampaignScreen).click((_screen_node as CampaignScreen).button_rect("draft").get_center())
	prep = _screen_node as PrepareScreen
	prep.draft.preselect(quiet)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)

	# Review focus 2: Restart and Pause, Campaign record nothing either.
	var old := _mission
	_open_pause()
	on_action("pause:restart")
	await _until(func() -> bool: return _mission_up(old), 10.0)
	step.call(save.campaign.night == 0 and save.campaign.bites == 0, "Restart in a campaign night records nothing")
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	_open_pause()
	on_action("pause:campaign")
	await get_tree().process_frame
	step.call(screen == Screen.CAMPAIGN and not is_instance_valid(_mission) and save.campaign.night == 0
		and save.campaign.bites == 0, "Pause, Campaign leaves the night unplayed: no bite, the same night")

	# Night 1 won on its clock.
	night = _screen_node as CampaignScreen
	night.click(night.button_rect("draft").get_center())
	(_screen_node as PrepareScreen).draft.preselect(quiet)
	_on_prepare_action("manifest", _screen_node as PrepareScreen)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	_mission.rules().time_left = 0.01
	await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	var res := _screen_node as ResultsScreen
	step.call(res != null and res.campaign and save.campaign.night == 1 and save.campaign.dp == 8,
		"Night 1 won: the results offer Continue, and the god has 8 DP (%d)" % save.campaign.dp)
	var reread := SaveFile.new().load_from(save_path)
	step.call(reread.campaign != null and reread.campaign.night == 1 and reread.campaign.dp == 8, "and the save holds it")

	# Night 2: three cards, the Theft placeholder held until dawn.
	res.action.emit("next")
	night = _screen_node as CampaignScreen
	step.call(screen == Screen.CAMPAIGN and night != null and night.options.size() == 3 and night.chosen == "",
		"Continue opens Night 2's three cards, none chosen")
	night.choose(MissionBook.VIGIL_FLAME)
	night.click(night.button_rect("draft").get_center())
	prep = _screen_node as PrepareScreen
	step.call(prep != null and prep.mission.id == MissionBook.VIGIL_FLAME and prep.draft.capacity == 8
		and not prep.draft.pool.has("heaven"), "the Vigil Flame's draft: 8 DP, the quiet pool")
	prep.draft.preselect(quiet)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	_mission.rules().time_left = 0.01
	await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	step.call(save.campaign.night == 2 and save.campaign.path() == CampaignDef.THEFT and save.campaign.dp == 10
		and String(result.get("reason", "")) == "held", "the night held: Night 3 next, on the Theft path, 10 DP")

	# Night 3: the Festival alone, in an unwarned town, lost on its clock.
	(_screen_node as ResultsScreen).action.emit("next")
	night = _screen_node as CampaignScreen
	step.call(night != null and night.options.size() == 2, "Night 3 offers the Festival and the Procession")
	night.choose(MissionBook.FEAST_FESTIVAL)
	night.click(night.button_rect("draft").get_center())
	prep = _screen_node as PrepareScreen
	step.call(prep != null and prep.draft.slots == 4 and prep.draft.capacity == 10, "with 4 slots and 10 DP")
	prep.draft.preselect(quiet)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	step.call(_mission.act() != null and _mission.act().id == "festival" and _mission.act().is_last()
		and not _mission.night().bell_rang, "the Festival plays as a night of one act, its town unwarned")
	_mission.rules().time_left = 0.01
	await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	step.call(save.campaign.bites == 1 and save.campaign.dp == 9 and save.campaign.ending == CampaignDef.FALSE_LANTERN,
		"the square closed: a bite, and the Theft path's ending (%s)" % save.campaign.ending)

	# The ending's two pages, then the title.
	(_screen_node as ResultsScreen).action.emit("next")
	var end := _screen_node as EndingScreen
	step.call(screen == Screen.ENDING and end != null and end.pages.size() == 2,
		"Continue opens the ending: The Vision, then The False Lantern")
	end.turn()
	end.turn()
	step.call(screen == Screen.TITLE and _screen_node is TitleScreen and not _in_campaign,
		"turning its last page returns to the title, the campaign left")

	# Review focus 3: after an ending, Campaign begins a fresh one.
	(_screen_node as TitleScreen).action.emit("campaign")
	step.call(screen == Screen.CAMPAIGN and save.campaign.night == 0 and save.campaign.ending == ""
		and save.campaign.dp == CampaignDef.START_DP, "after an ending, Campaign begins a fresh one")

	# Review focus 5: the board after the campaign drafts within its own mission's numbers.
	(_screen_node as CampaignScreen).action.emit("title")
	(_screen_node as TitleScreen).action.emit("play")
	(_screen_node as MissionBoard).choose(MissionBook.LAST_JUDGEMENT)
	prep = _screen_node as PrepareScreen
	step.call(prep != null and prep.draft.slots == 6 and prep.draft.capacity == 14 and not _in_campaign,
		"the board after the campaign: Last Judgement's own 6 slots and 14 DP")
	on_action("prepare:back")
	(_screen_node as MissionBoard).action.emit("back")
	step.call(screen == Screen.TITLE, "and back to the title")
```

- [ ] **Step 2: Run FLOW.** Expected: `FLOW result checks=N failures=0`, N about 62 + 19. If the board's slots differ, check whether `MissionBoard.choose()` opens Prepare at once, as `_flow_test()` assumes. A step that times out under load is a wait to raise, not a bug: raise its `_until` limit and report it.

- [ ] **Step 3: Run Tests and the exact gates.** Expected: unchanged.

- [ ] **Step 4: Commit.**

```bash
git add src/game/game.gd
git commit -m "test: the FLOW test plays a campaign to its ending (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 7 (controller): M1 gate

- [ ] **Step 1: Gates on the milestone's head:**
  - Tests: `failures=0`, no SCRIPT ERROR or Parse Error;
  - Digest and crowd_check unchanged;
  - the ten exact behaviour checksums unchanged;
  - FLOW: `failures=0` (rerun once under load before calling a failure);
  - Mission tests within range; `--mission=warning --mission-test` gives `won=false reason=bell time≈24`.
- [ ] **Step 2: Photographs:** `--show=campaign`, `--show=campaign-choice`, `--show=ending`, plus `--show=results` (unchanged). Show them to the user.
- [ ] **Step 3: Playtest by hand:** run `play.bat`, then Campaign, and play Night 1 to Night 3 on any path. Record what feels wrong for the M2 plan.
- [ ] **Step 4: Land:**
  - If the work was on a worktree branch, fast-forward `feat/Develop-Main` to it. The main checkout must be clean first.
  - Tag `kak-v010-m1`, and push with `git push origin feat/Develop-Main --tags`.
- [ ] **Step 5: Update the KAK Dev Ledger:**
  - M1 task to done;
  - a task for each of M2–M5 as `todo`;
  - `meta/project` with the new test and FLOW counts.
- [ ] **Step 6: Write the M2 plan** (the Gaze and Mira's House) from the spec's §3.4, §4.1 and §8.2 and the playtest notes.
