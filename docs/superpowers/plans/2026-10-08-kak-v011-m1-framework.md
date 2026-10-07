# KAK v0.11 M1: The Tiers Framework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The title's Missions button opens a five-tier board. Its eight ★ missions are played at their tier's clock, readiness and budget, with 2-3 random wishes each night. A done main objective holds the night open until the god ascends or is caught. Believers bank, buy upgrades and open the tiers, and the no-waiting changes reach The Warning and Mira's House.

**Architecture:**
- **Data:**
  - `TierBook` holds the five tiers' numbers and builds a board mission from a ★ mission (`board(id, state)`): the tier's clock, a readiness floor, the budget, stretched timelines, no bonuses.
  - `DescendState` is the save's `[descend]` section: nights, believers, open tier, cleared missions, upgrades, unlocked powers, bests. It also holds the unlock rule and the prices.
- **Run time:**
  - A `Descent` per board night is handed to each act's `Rules`. It hears the wishes, keeps the Tier 5 Gaze and reports what the night earned.
  - `Rules` holds a night open once its main objective is done (`main_done`), ends it on `ascend()` or catches it (`caught`).
  - Wishes are `Objective`s (`Wish` and five kinds) drawn by `WishBook`.
- **Screens:**
  - `MissionBoard` is rewritten in place as the tier board.
  - The HUD gains the wish list, the wish tags, the prayers plate, the ASCEND plate and the ascent's light.
  - `ResultsScreen` gains a board layout, and the new `UpgradesScreen` spends believers.

**Tech Stack:** Godot 4.7.2 GDScript. Headless test runner `tests/run_all.gd`. Behaviour scenarios in `tools/dev/behaviour_check.gd`. The FLOW test in `src/game/game.gd`.

**Spec:** `docs/superpowers/specs/2026-10-08-kak-v011-tiers-design.md`. This plan covers **M1 Framework only**: spec §2 row M1, §3, §4, §5, §6, §7.2 for the 8 ★ missions, §7.3, and §9's framework tests. M2-M6 are later plans.

## Global Constraints

- **Baseline:** branch `claude/lantern-campaign-spec` at `aced836` (= `feat/Develop-Main` `92e0dcc` + the v0.11 spec commits).
  - Tests baseline **3874** (`checks=3874 failures=0` at `92e0dcc`).
  - FLOW **91/0**.
- **Machine:** the BURIN_NITRO laptop.
  - Work in the worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve/.claude/worktrees/game-concept-story-review-636208` (Git Bash path `/c/BURIN_NITRO/...`) on `claude/lantern-campaign-spec`.
  - Never touch other sessions' worktrees.
  - **Godot:** `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`.
- **Commands:**
  - **Import** (after a new `class_name` file or a new test file): `timeout 900 $G --headless --editor --path . --import >/dev/null 2>&1`.
  - **Tests:** `timeout 1200 $G --headless --path . --script res://tests/run_all.gd 2>&1 | grep -v '^\s*at:' | grep -n "FAIL\|SCRIPT ERROR\|Parse Error\|checks="`.
    - Expected: `checks=N failures=0`. Each task adds to it; report the count.
    - The `leaked` / `still in use` lines at exit are there at baseline too.
  - **FLOW:** `timeout 900 $G --path . --audio-driver Dummy --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep "FLOW"`.
    - Expected: `FLOW result checks=N failures=0`.
    - The counts by task: 91 through Task 7, 93 from Task 8, 99 from Task 10, 108 from Task 11.
  - **Behaviour:** `timeout 600 $G --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- <args>`.
  - **Photos:** `GODOT=$G SCENE=res://scenes/game.tscn bash tools/capture.sh --show=<name> --capture`.
    - Writes `captures/screen_<name>.png` at twice the 640x360 size.
- **Exact references that must NOT move** (every task that touches `Rules`, a director, `EventTimeline`, `WarningDirector` or `Mission._build_act` runs the ones it names; the controller runs all at landing):
  - Digest `61267b7e90524d800bf1c3473a71146b` (`$G --headless --path . -s tools/dev/state_digest.gd`).
  - crowd_check `-346732806` (`$G --headless --path . --fixed-fps 60 -s tools/dev/crowd_check.gd`).
  - Behaviour checksums:
    - calm `--scenario=calm --seconds=60`: `-355092532`
    - gates `--scenario=gates`: `927388410`
    - fire `--scenario=fire`: `243410460`
    - rite `--scenario=rite --interrupt`: `-555358538`
    - soldiers `--scenario=soldiers --case=escort`: `-778609674`
    - Broken Lanterns `--scenario=lanterns --case=none --seed=1`: `424350965`
  - Behaviour outcomes:
    - Vigil Flame `--scenario=flame --case=none --seed=1`: outcome `won=false reason=gaze`.
    - Feast `--scenario=feast --case=play --seed=1`: won festival.
- **References that move ON PURPOSE in M1 (spec §7.3):**
  - The five `--scenario=warning --case=none|doom|whisper|discord|mix`. Today: `-489775734`, `-905773030`, `-588314462`, `-997640091`, `-206935500`.
  - Mira's House `--scenario=miras --case=play`. Today: `-200101558`, `won=false reason=gaze time=94.9 believers=3`.
  - Only Task 1 may move them. It records the new values and why. Nothing else may move them: Tasks 3, 4 and 5 re-run them against Task 1's values.
- **Text and drawn shapes only:** no PixelLab, no new image assets, no new fonts.
- **The campaign:**
  - The `[campaign]` save section and the campaign flow stay as they are.
  - FLOW's campaign steps must still pass.
  - Only §7.3's two changes reach the campaign, through the shared directors and `MissionBook.warning()` / `BelieversObjective`.
- **MissionBook's own missions** (the campaign's, the scripted runs', `--mission=` runs) are not changed except by §7.3. Board versions are built by `TierBook.board()` on copies.
- **Style:**
  - Tabs. Static types.
  - A `##` doc comment on every new const, var and func, in full sentences, in the file's own voice, tagged "v0.11 M1".
  - Match the neighbouring code.
  - Never name a member `seed` or `script`: the first shadows a global function, the second Object's own property.
- **Test style:**
  - `extends RefCounted`, `static func run(t)`, `t.check` / `t.near`.
  - Register each new file at the end of `SUITES` in `tests/run_all.gd`.
  - Build worlds like `tests/test_warning.gd`'s `_setup()`. Step `crowd.advance(DT)` then `rules.advance(DT)`.
  - Headless tests never think people: place them with `_arrive()`.
  - ctx is null: no FX.
- **Commits:** one per task. End every message with the line `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Controller's gates at landing:** the digest, `crowd_check`, every exact checksum above, the moved references named and traced, the full suite, FLOW 108/0, and a bench of one mission per tier against `92e0dcc` (memory: bench on a quiet machine).

## Review Focus

1. **A Tier 5 night with the Banishing Rite running.**
   - The situation: Last Judgement or The Long Night's Act III is God-Resistant, so the rite exists and gathers. The Tier 5 Gaze bar sits where the rite's plate does (`GAZE_TOP` = `RITE_TOP`).
   - Expected: the rite's plate shows, and the Gaze stays readable (the scored panel's "Gaze N%", or the objective row).
   - Pinned by: Task 10 `_gaze_display`.
2. **A wish's people gone before it can be done.**
   - The situation: the wisher dies, a target dies by another hand or leaves the town alive, the child dies before anyone engages, or a family member dies unshown.
   - Expected: the wish fails at once (a building destroyed by anything still grants it), and a freed person is never touched or tagged.
   - Pinned by: Task 6 `_wisher`, `_punish`; Task 7 `_rescue`, `_family`.
3. **A restart or an abandoned night.**
   - Expected: R, Pause > Restart or Pause > Missions banks nothing and does not move the night counter, and the same night hears the same wishes again. A counted night redraws.
   - Pinned by: Task 5 `_seed`, Task 6 `_descent`, Task 11 FLOW "a restart banks nothing".
4. **ASCEND pressed when there is nothing to ascend from.**
   - The situation: F before the main objective, F or a plate click during the intro or the ending, F twice.
   - Expected: nothing happens, nothing is cast by the plate's click, and the night is not ended twice.
   - Pinned by: Task 5 `_held` (ascend twice, ascend before main), Task 10 `_ascend` and its FLOW step "F before the main objective does nothing".
5. **The Long Night on the board.**
   - Expected: no ASCEND until Act III's objective is done (Acts I and II end as before), the wishes are heard once at Act I, and one Tier 5 Gaze carries through all three acts.
   - Pinned by: Task 5 `_acts` and `_tier_gaze`.

## Plan decisions

The controller records these as rulings. Each fills a detail the spec leaves open, or settles a clash with the code.

1. **Board ids:** the ★ missions keep their ids (`warning`, `miras_house`, `broken_lanterns`, `vigil_flame`, `last_judgement`, `long_night`). The Festival and the Procession are `festival` and `procession`, built from The Long Night's acts as single missions (`TierBook._from_act()`).
2. **The tier board keeps the class `MissionBoard`**, rewritten in place, so `Game`'s BOARD screen and FLOW's `choose(id)` calls stay. Its v0.08 helpers that no longer apply (`loadout_line`, `best_marks`) go, with their checks.
3. **Stretch** = tier clock ÷ the mission's own clock: Mira's House 2.2, Broken Lanterns 1.8333, the Vigil Flame 2.0, the Procession 2.6.
   - The Festival stretches to its 4:30 close (1.8).
   - It is implemented as `EventTimeline` story time (`stretched()`), so a director's comparisons with `timeline.elapsed()` stretch too. Real-time waits (Mira's shout, the Vigil's 30 s) do not.
   - The Long Night keeps its acts' clocks (2:00 + 2:30 + 5:00) and timelines. Last Judgement has no timeline.
   - The Vigil Flame's search event, set from `rules.time_left`, is divided by the stretch.
4. **The Warning's three stars:** the postern at 0:10, the Main Gate at 1:30, the Side Gate at 3:00, farthest from the bell first (spec §8's twist).
   - Each star is a `WarningDirector` set up `OMEN_AT` (2 s) before it falls, so its watchman is appointed then.
   - The main objective is `StarsObjective` (all three stopped). Its clock-out reason is `dawn`.
5. **The board's Festival:** need 80 (spec), and the crowd rises from 80 to **120**, since 80 of 80 would need every goer. The square closes at 4:30 as a deadline (`EventObjective`); dawn is the tier's 6:00.
6. **Board missions have no bonuses:** spec §6 lists only the main objective and the wishes. `scored` is kept, so Last Judgement and The Long Night keep their HUD panel and their internal score. The board's results show no score.
7. **Readiness:** `MissionDef.tier_floor`, on `ResponseProfile.level()`'s scale (Unaware 1, Organized 2, Prepared 3, God-Resistant 4), raises the mission's own town and never lowers it. The Long Night's acts take it too, so at Tier 5 every act is God-Resistant.
8. **Slots are capped at 6** (keys 1-6, the HUD's row of six). Tier 5's base 6 + the +1 slot upgrade stays 6.
9. **The Long Night's acts all take the tier's budget** on the board (6 / 16 + upgrades). v0.09.1's growing budget stays in `MissionBook.long_night()`.
10. **The Tier 5 Gaze:**
    - A seen death adds 0.5 (`GazeMeter.SEEN_DEATH` × `TierBook.GAZE_SHARE` 0.05, Broken Lanterns' share).
    - One Gaze for the whole night, shared by The Long Night's acts. The bell does not fill it.
11. **After the main objective, the night ends on:**
    - the clock: caught `dawn`;
    - any primary objective failing, except the main one and deadlines (`Objective.deadline`: the Festival's close).
12. **The Warning's clock-out** (§7.3) loses with reason `dawn` ("DAWN COMES"), and its HUD row reads "Dawn".
13. **Wish seed** = `hash([nights played, mission id])`. A restart or an abandoned night replays the draw; a counted night redraws.
14. **Wish targets:**
    - **Lay citizens:** alive, out of doors, faith NONE, no role among clergy, engineer, bellkeeper, watchman, mayor or noble. No person or building is shared between two wishes.
    - **House:** role `house`, kind HOUSE, art tag none or `townhouse`.
    - **Watchtower:** role `tower`, not the bell tower.
    - **The child:** a lay citizen of the wisher's household (`profile.family`). The town has no ages.
    - **The family:** the three lay citizens living nearest the wisher's home, within 6 units.
    - **"Any exit":** one of the town's three gates (Main Gate, Side Gate, postern), reached within 1.5 while whispered. The map's exits lie 15+ units past the walls.
    - **The Citadel's gate:** walkable ground at (-10.5, -7.6).
15. **Save my child:**
    - Engaging: a click within 8 px of the child's or the soldier's tag, or a cast within 2 units of either.
    - Once engaged, the soldier (corps NONE, the nearest free soldier to the child) walks to the child, then both walk to the Citadel's gate, the child following.
    - Granted: the soldier is dead or off his duty, with the child alive.
    - Failed: the child dies, he reaches the gate, or 45 s pass.
16. **Show me a sign:** a cast within 4 units of a living wisher out of doors.
    - **Kill the informer, unseen:** judged as The Warning judges (`Crowd.nearest_witness()` once the doom has settled). A seen kill fails it, and the wisher counts as a witness.
    - **Show yourself to my family:** each member counts once whispered. One dying unshown fails it.
17. **Mission tags:** The Warning declares `unaware_town` and Mira's House `spares_houses`. No other M1 mission declares any.
18. **Rewards** × the tier multiplier are rounded with `roundi` (half away from zero): 15 × 1.5 = 23.
19. **Lost wishes:** granted wishes are lost on any night not ascended, before the main objective too (a loss banks nothing).
    - The texts: "lost: Halcyon saw you" (gaze), "lost: the bell tolled", "lost: the people escaped", "lost: dawn came" (any clock end).
    - Anything else: "lost: the night was lost".
20. **The ascent:**
    - A pale gold column rises over the god's last cast spot (the mission's camera spot if none), drawn by the HUD.
    - The ending's slow motion lasts 2 s (`Mission.ASCEND_SECONDS`) instead of 3, under the banner "YOU ASCEND".
21. **Night numbering:** the board header shows the night about to be played (counter + 1); the results show the night just played.
22. **Bests:**
    - "Fastest" = seconds from the night's start to the main objective (The Long Night counts its earlier acts).
    - "Most wishes" = granted wishes banked by an ascent.
23. **v0.10 carry-over:** a won Warning, Long Night or Last Judgement becomes cleared, and tiers open by the rule. v0.10 saves hold no times, so no best time carries over.
24. **Prices:** starting powers are DP ≤ 2 (15 of 38). Unlocking costs 15 × DP; the n-th +1 DP costs 25 × n (six at most); +1 slot costs 150 (once).
25. **The HUD after the main objective:**
    - The hint is "Grant the wishes still open (blue), or ascend when you are ready: press F.", or with none open "Ascend when you are ready: press F."
    - The ASCEND plate ("ASCEND" with an F plate) sits centred at y 272, above a focused power's modes row.
26. **Results buttons:** Board / Again / Upgrades are `results:missions` / `results:replay` / `results:upgrades`. Upgrades' Back always leads to the board.
27. **Hints:** The Warning's lines drop "or outlast the omen". The Festival's drops "fifty" (the board needs 80). A new phase line `warning.waiting` covers the time between stars.
28. **The Tier 5 Gaze on the HUD:**
    - In a scored panel (Last Judgement, The Long Night's Act III), "Gaze N%" sits beside the escapes.
    - The Gaze bar gives way to the rite's plate while the rite shows, for every mission.
29. **The prayers plate** shows during the intro of the night's first act only ("THE TOWN PRAYS..." over the wishes), and not at all when none was drawn.
30. **Mira's House's `four` hint line stays** but is no longer reached: the campaign night ends at the fourth Believer, and on the board the hint switches to the wishes once the main objective is done.

### Where the spec does not fit the code

- §3.5 "carry over ... as cleared and best time": a v0.10 save stores no times. Only "cleared" carries (decision 23).
- §3.4 + §4: Tier 5's 6 slots plus the +1 slot upgrade is 7. The game has six slot keys and a HUD row of six (decision 8).
- §7.2 "need from 50 to 80 goers": the Festival has 80 goers, so the need would be all of them (decision 5).
- §4 "the clock is at least 5:00 everywhere": The Long Night's acts run 2:00, 2:30 and 5:00 (spec §8 row 22 keeps "the acts' own").
- §7.3 / §9 expect the five Warning checksums and Mira's House's to move. By the code, the changes only alter what happens at the clock's end (The Warning) and at a fourth Believer (Mira's House).
  - v0.08's records have every Warning case ending by bell or by kill well before 2:00.
  - Mira's play run ends at 94.9 s with three Believers.
  - So some or all may stay put. Task 1 records whatever they print.
- §5.3 "a child-age citizen": the town has no ages (decision 14). "Any exit": the map's exits are beyond any whisper's reach (decision 14).

---

## File Structure

- **Created:**
  - `src/game/descend/tier_book.gd`: the tiers' numbers, the board's missions, `board()` (Tasks 2, 3, 4).
  - `src/game/descend/descend_state.gd`: the `[descend]` section, the unlock rule, prices, banking (Task 2).
  - `src/game/descend/descent.gd`: one board night at run time (Tasks 5, 6, 7).
  - `src/game/descend/wish_def.gd`, `wish_book.gd`, `wish.gd`: the wishes' data, pool and draw, and the run-time base (Task 6).
  - `src/game/descend/ruin_wish.gd`, `punish_wish.gd`, `sign_wish.gd` (Task 6); `rescue_wish.gd`, `mercy_wish.gd`, `family_wish.gd` (Task 7).
  - `src/game/mission/event_objective.gd` (Task 3); `starfall_director.gd`, `stars_objective.gd` (Task 4).
  - `src/game/ui/upgrades_screen.gd` (Task 11).
  - Tests: `tests/test_tiers.gd`, `test_board_missions.gd`, `test_starfall.gd`, `test_descent.gd`, `test_wishes.gd`, `test_wish_kinds.gd`, `test_tier_board.gd`, `test_board_nights.gd`, `test_descend_hud.gd`, `test_descend_screens.gd`.
  - Docs: `docs/KAK_Version_0.11_Summary.md` (Task 12).
- **Modified:**
  - `src/game/mission/mission_book.gd`, `believers_objective.gd`, `warning_director.gd`, `mission_hints.gd`, `results_screen.gd` (Task 1; results also Task 11).
  - `src/game/save_file.gd` (Task 2).
  - `src/game/mission/objective.gd`, `event_timeline.gd`, `mission_def.gd`, `act_def.gd`, `mission_director.gd`, `src/game/response_profile.gd`.
  - The six timeline directors (`miras_house`, `broken_lanterns`, `festival`, `procession`, `vigil_flame`, `judgement`) and `src/game/mission.gd` (Task 3).
  - `src/game/rules.gd` (Task 5).
  - `src/game/ui/mission_board.gd` (rewrite), `src/game/draft.gd`, `src/game/ui/prepare_screen.gd` (Task 8).
  - `src/game/mission.gd`, `src/game/game.gd` (Tasks 1, 8, 9, 10, 11, 12).
  - `src/game/ui/hud.gd` (Task 10).
  - Existing tests:
    - Task 1: `test_warning.gd`, `test_miras_house.gd`, `test_mission_book.gd`, `test_hud.gd`, `test_mission_hints.gd`, `test_results.gd`.
    - Task 3: `test_mission_hints.gd`.
    - Task 8: `test_night.gd`, `test_save_file.gd`.
    - Task 11: `test_flow.gd`.
    - `run_all.gd` in each task that adds a suite.
  - `README.md` (Task 12).

---

### Task 1: The no-waiting changes (spec §7.3)

**Files:**
- Modify: `src/game/mission/mission_book.gd` (`warning()`, lines 45-74)
- Modify: `src/game/mission/believers_objective.gd`
- Modify: `src/game/mission/warning_director.gd` (the class doc, lines 3-12)
- Modify: `src/game/mission/mission_hints.gd` (`WARNING_LINE`, `WARNING_BELL`)
- Modify: `src/game/ui/results_screen.gd` (`ACT_TITLES`)
- Modify: `src/game/game.gd` (three FLOW steps that won The Warning on its clock)
- Test: `tests/test_warning.gd`, `tests/test_miras_house.gd`, `tests/test_mission_book.gd`, `tests/test_hud.gd`, `tests/test_mission_hints.gd`, `tests/test_results.gd`

**Interfaces:**
- Consumes: nothing new.
- Produces:
  - `MissionBook.warning()`'s objectives are `[WarningObjective, BellSilentObjective, ClockObjective(false, "Dawn", "dawn")]`.
  - `BelieversObjective.check()` is DONE at `NEED` Believers out at any time, FAILED (`few`) at dawn with fewer.
  - `ResultsScreen.ACT_TITLES["dawn"] == "DAWN COMES"`.
  - `MissionHints.WARNING_LINE == "Kill the messenger (gold) with no one near (red) before he warns the bellkeeper (blue)."` and `MissionHints.WARNING_BELL == "The bell is called. Kill its ringer (gold) unseen before the bell tolls."`

- [ ] **Step 1: Write the failing tests.**
  - `tests/test_warning.gd`:
    - Replace the header's fifth line (`## bell ringing loses, and the omen fading at 0:00 wins. ...`) with:

```gdscript
## bell ringing loses, and dawn with the warning alive loses too (v0.11 M1, spec §7.3: no waiting). Fright, Discord and
## Mind Whisper interrupt the errand until
```

    - Replace the comment above `_endings` with `## The bell rings: lost. Dawn with the warning alive: lost too (v0.11 M1, spec §7.3), its delays still reported.`
    - Replace the three checks after `_run(s, 0.1)` in `_endings`' second part (`"the omen fades: won ..."`, `"solved by DOMINION ..."`, `"and the results carry it"`) with:

```gdscript
	t.check(rules.finished and not rules.won and rules.over_reason == "dawn",
		"no waiting (v0.11 M1, spec §7.3): dawn with the warning alive loses (%s)" % rules.over_reason)
	t.check(d.report().solved_by == PackedStringArray(["DOMINION"]), "the delays are still reported (%s)" % [d.report()])
	t.check(ResultsScreen.solved_text(rules.result()) == ResultsScreen.NOBODY, "but a loss is solved by nobody")
```

  - `tests/test_miras_house.gd`:
    - Change the header's line 5 ending to `...; BelieversObjective.NEED (4) Believers out win at once (v0.11 M1, spec §7.3).`
    - Replace `_ending`'s first block (from `var s := _setup()` down to its `_done(s)`) with:

```gdscript
	var s := _setup()
	var d: MirasHouseDirector = s.d
	var rules: Rules = s.rules
	for i in BelieversObjective.NEED - 1:
		var g := d.grieving[i]
		g.profile.faith = CitizenProfile.Faith.BELIEVER
		d.believers.append(g)
	_run(s, DT * 2.0)
	t.check(not rules.finished, "three Believers out: the night goes on")
	var fourth := d.grieving[BelieversObjective.NEED - 1]
	fourth.profile.faith = CitizenProfile.Faith.BELIEVER
	d.believers.append(fourth)
	d.journal = d.grieving[0]
	_run(s, DT * 2.0)
	t.check(rules.finished and rules.won and rules.over_reason == "believers" and rules.time_left > 100.0,
		"no waiting (v0.11 M1, spec §7.3): the fourth Believer out wins at once (%.1f s before dawn)" % rules.time_left)
	var res := rules.result()
	t.check(int(res.get("believers", -1)) == BelieversObjective.NEED, "the results count them")
	var earned := []
	for b: Dictionary in res.bonuses:
		earned.append(bool(b.earned))
	t.check(earned == [true, true], "no death and the journal out: both bonuses (%s)" % [earned])
	_done(s)
```

  - `tests/test_mission_book.gd:42`: `t.check(w_reasons == ["warning", "bell", "dawn"], "its objectives in order: no win at the clock's end (v0.11 M1) (%s)" % [w_reasons])`
  - `tests/test_hud.gd:183-184`:

```gdscript
	t.check(rows == [["Stop the warning", ""], ["Dawn 2:00", ""], ["Unseen", "ok"]],
		"The Warning's panel: the warning, dawn's clock (v0.11 M1), and Unseen ticked (%s)" % [rows])
```

  - `tests/test_mission_hints.gd`, rows `warning`, `warning.bell`, `omen` and `omen.bell` of `SPEC`:

```gdscript
	["warning", "Kill the messenger (gold) with no one near (red) before he warns the bellkeeper (blue)."],
	["warning.relay", "Someone saw: a witness (gold) carries the warning on. Strike again where no one (red) is near."],
	["warning.bell", "The bell is called. Kill its ringer (gold) unseen before the bell tolls."],
	["omen", "Kill the messenger (gold) with no one near (red) before he warns the bellkeeper (blue)."],
	["omen.relay", "Someone saw: a witness (gold) carries the warning on. Strike again where no one (red) is near."],
	["omen.bell", "The bell is called. Kill its ringer (gold) unseen before the bell tolls."],
```

  - `tests/test_results.gd`: after `t.check(ResultsScreen.title_for(false, "bell") == "THE BELL TOLLS", "and its loss THE BELL TOLLS")` add:

```gdscript
	t.check(ResultsScreen.title_for(false, "dawn") == "DAWN COMES", "dawn with the warning alive reads DAWN COMES (v0.11 M1)")
```

- [ ] **Step 2: Run the tests to verify they fail.** Run Tests.
  - Expected: FAILs naming "no waiting ... dawn with the warning alive loses", "the fourth Believer out wins at once", "its objectives in order", "The Warning's panel", "the lines are the spec's" and "DAWN COMES".

- [ ] **Step 3: The Warning.** In `src/game/mission/mission_book.gd`, replace `warning()`'s doc comment and the lines from `m.goal = ...` to `m.lose = ...` and the `m.make_objectives` lambda:

```gdscript
## The Warning (v0.08 M4): a star falls over the Main Gate and a watchman runs to wake the bell; kill whoever carries
## the warning unseen (WarningDirector). v0.08.1 left Thornwall out of its pool: a 3-unit wall is walked round in at most
## 1.5 s, once a mission -- a Last Judgement tool (gates, evacuees). v0.11 M1 (no waiting, spec §7.3): holding the warning
## off until the omen fades no longer wins; dawn with the warning alive loses, as any other dawn does.
```

```gdscript
	m.goal = "Stop the warning before the bell tolls"
	m.goal_label = "Stop the warning"
	m.lose = "The bell tolls, or dawn comes with the warning alive"
```

```gdscript
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [WarningObjective.new(), BellSilentObjective.new(),
			ClockObjective.new(false, "Dawn", "dawn")]
		return out
```

  - In `src/game/mission/warning_director.gd`, replace the class doc's sentence `The player wins by killing whoever carries the warning (the messenger) with nobody living near enough to see it (Crowd.DOOM_WITNESS), or by holding the warning off until the omen fades.` with: `The player wins by killing whoever carries the warning (the messenger) with nobody living near enough to see it (Crowd.DOOM_WITNESS); dawn with the warning alive loses (v0.11 M1, spec §7.3: no waiting).`

- [ ] **Step 4: Mira's House.** Replace `src/game/mission/believers_objective.gd` with:

```gdscript
class_name BelieversObjective
extends Objective
## Mira's House (v0.10): NEED Believers alive and out of the house win the night ("believers"); fewer at dawn lose it
## ("few"). Four, not the spec's starting five (Task 7: a scripted policy reached 3-7 Believers, most often 4).
## v0.11 M1 (no waiting, spec §7.3): won the moment the fourth Believer walks out, not at dawn.

const NEED := 4


func _init() -> void:
	label = "Believers"
	reason = "believers"


func check(rules: Rules) -> Status:
	var d := rules.director as MirasHouseDirector
	if d == null:
		return Status.PENDING
	if d.believers_outside() >= NEED:
		reason = "believers"
		return Status.DONE
	if rules.time_left > 0.0:
		return Status.PENDING
	reason = "few"
	return Status.FAILED


func hud_text(rules: Rules) -> String:
	var d := rules.director as MirasHouseDirector
	return "Believers %d / %d" % [d.believers_outside() if d != null else 0, NEED]
```

- [ ] **Step 5: The words.**
  - In `src/game/mission/mission_hints.gd`:

```gdscript
const WARNING_LINE := "Kill the messenger (gold) with no one near (red) before he warns the bellkeeper (blue)."
```

```gdscript
const WARNING_BELL := "The bell is called. Kill its ringer (gold) unseen before the bell tolls."
```

  - In `src/game/ui/results_screen.gd`, add `"dawn": "DAWN COMES"` to `ACT_TITLES`, after `"late": "DAWN FINDS THE FLAME"`, with a comment line above the const:

```gdscript
## v0.11 M1: "dawn" is The Warning's loss at the clock's end (no waiting, spec §7.3) and a board night caught by dawn.
```

- [ ] **Step 6: FLOW wins The Warning by stopping it.** In `src/game/game.gd`:
  - The board's Warning (the block starting `# The Warning (v0.08): picked by its id`):
    - Replace its comment with `# The Warning (v0.08): picked by its id, its default loadout manifested, won by stopping the warning (v0.11 M1, spec §7.3: the omen fading no longer wins) -- an unscored result -- and Missions goes back to the board.`
    - Replace `_mission.rules().time_left = 0.01` (the one after `await _past_intro()` in that block) and the step after it with:

```gdscript
	(_mission.rules().director as WarningDirector).warning_dead = true
	var faded := await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	step.call(faded and _screen_node is ResultsScreen and String(result.get("reason", "")) == "warning"
		and bool(result.get("won", false)) and not result.has("score"),
		"stopping the warning wins it, on unscored results (%s)" % result.get("reason", "?"))
```

  - `_flow_night`: replace `# Act I wins on its clock, and the interlude after it is for that act.` and the `_mission.rules().time_left = 0.01` under it with:

```gdscript
	# Act I wins by stopping the warning (v0.11 M1: its clock no longer wins), and the interlude after it is for that act.
	(_mission.rules().director as WarningDirector).warning_dead = true
```

  - `_flow_campaign`: replace `# Night 1 won on its clock.` with `# Night 1 won by stopping the warning (v0.11 M1, spec §7.3: dawn no longer wins it).`, and the `_mission.rules().time_left = 0.01` under that block's `await _past_intro()` with `(_mission.rules().director as WarningDirector).warning_dead = true`.
  - `_night_to_redraft()` and the other Act I clock-outs stay. A lost Act I still opens the interlude (`Mission._play_ending()` emits `act_over` win or lose).

- [ ] **Step 7: Run the tests to verify they pass.** Run Tests. Expected: `failures=0`, 3876 (+2).

- [ ] **Step 8: FLOW.** Run FLOW. Expected: `FLOW result checks=91 failures=0`. Paste any `FLOW FAIL` line.

- [ ] **Step 9: The moving references.** Run the five `--scenario=warning --case=none|doom|whisper|discord|mix` and `--scenario=miras --case=play`.
  - For each, report the `BEHAVIOUR warning end ...` / `BEHAVIOUR miras result ...` line and the `BEHAVIOUR checksum=` line, beside today's value.
  - For each that moved, say why. A run can only move where it reached:
    - the clock's end with the warning alive, where it now loses with `reason=dawn`;
    - or a fourth Believer out, where it now wins at once.
  - For each that did not move, write "unchanged: the run never reached the changed condition", with the run's own reason and time.
  - These six lines are the references from here on. Put them in the commit message body.

- [ ] **Step 10: The fixed references.** Run Broken Lanterns (`424350965`) and the Vigil Flame (`won=false reason=gaze`). Expected: unchanged.

- [ ] **Step 11: Commit.**

```bash
git add src/game/mission/mission_book.gd src/game/mission/believers_objective.gd src/game/mission/warning_director.gd src/game/mission/mission_hints.gd src/game/ui/results_screen.gd src/game/game.gd tests/test_warning.gd tests/test_miras_house.gd tests/test_mission_book.gd tests/test_hud.gd tests/test_mission_hints.gd tests/test_results.gd
git commit -m "feat: no waiting -- The Warning lost at dawn, Mira's House won at the fourth Believer (v0.11 M1)" -m "<the six reference lines from Step 9, old -> new, and why>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: The tiers and the `[descend]` save

**Files:**
- Create: `src/game/descend/tier_book.gd`, `src/game/descend/descend_state.gd`, `tests/test_tiers.gd`
- Modify: `src/game/save_file.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: `PowerBook.keys()`, `PowerBook.get_power(key)`, `UiTheme.clock()`, `SaveFile.best(id)`.
- Produces:
  - **`TierBook`, consts:**
    - `NAMES`, `MISSIONS`, `READINESS`, `SLOTS`, `DP`, `CLOCKS`, `WISHES`, `MULTIPLIERS` (five entries each, Tier 1 first);
    - `NEED := 3`, `MAX_SLOTS := 6`, `GAZE_TIER := 5`, `GAZE_SHARE := 0.05`;
    - `TYPES: Dictionary`, `MISSION_TAGS: Dictionary`.
  - **`TierBook`, static:**
    - `tier_name(tier: int) -> String`, `missions(tier: int) -> PackedStringArray`;
    - `readiness(tier: int) -> int`, `slots(tier: int) -> int`, `dp(tier: int) -> int`, `clock(tier: int) -> float`, `wishes(tier: int) -> int`, `multiplier(tier: int) -> float`, `need(tier: int) -> int`;
    - `tier_of(id: String) -> int` (0 when not on the board), `has(id: String) -> bool`, `all() -> PackedStringArray`;
    - `type_of(id: String) -> String`, `mission_tags(id: String) -> PackedStringArray`;
    - `believers(base: int, tier: int) -> int`.
  - **`DescendState`, consts:** `SECTION := "descend"`, `DP_STEP := 25`, `DP_LIMIT := 6`, `SLOT_PRICE := 150`, `SLOT_LIMIT := 1`, `UNLOCK_PER_DP := 15`, `STARTING_DP := 2`, `CARRIED`.
  - **`DescendState`, vars:** `night: int`, `believers: int`, `open_tier: int`, `cleared: PackedStringArray`, `dp_bought: int`, `slot_bought: int`, `unlocked: PackedStringArray`, `fastest: Dictionary` (id → float), `most_wishes: Dictionary` (id → int).
  - **`DescendState`, funcs:**
    - powers: `static starting(key) -> bool`, `is_unlocked(key) -> bool`, `locked() -> PackedStringArray`;
    - prices: `dp_price() -> int`, `static unlock_price(key) -> int`, `price(what) -> int`, `refusal(what) -> String` ("", "limit", "owned", "unknown", "believers"), `buy(what) -> bool`;
    - tiers: `cleared_in(tier) -> int`, `is_open(tier) -> bool`, `refresh_open() -> int`, `static lock_text(tier) -> String`, `progress_line(tier) -> String`;
    - banking: `bank(id: String, outcome: Dictionary) -> Dictionary`. `outcome` keys: `main: bool`, `main_time: float`, `earned: int`, `kept: int`. Returns `{believers, total, night, cleared, first_clear, opened, progress, bests: PackedStringArray}`;
    - the file: `write(cfg)`, `static read(cfg) -> DescendState`, `carry_over(save: SaveFile)`.
  - **`SaveFile`:** `var descend: DescendState` (never null); `last_mission` accepts a board id.

- [ ] **Step 1: Write the failing test.** Create `tests/test_tiers.gd`:

```gdscript
extends RefCounted
## v0.11 M1 the tiers (spec §3-§4): each tier's numbers as the spec's table gives them, its missions, the unlocking rule with
## the short-tier rule, the upgrade prices, banking a night won, lost or caught, and the [descend] save -- a round trip, a
## hand-edited file, and a v0.10 save's board wins carried over (review focus 3's counter only moves when banked).


static func run(t) -> void:
	_table(t)
	_unlock(t)
	_prices(t)
	_bank(t)
	_save(t)


static func _table(t) -> void:
	t.check(Array(TierBook.NAMES) == ["Whisper", "Omen", "Wrath", "Reckoning", "Ascendance"], "the five tiers' names")
	var rows := []
	for tier in range(1, 6):
		rows.append([TierBook.readiness(tier), TierBook.slots(tier), TierBook.dp(tier), TierBook.clock(tier),
			TierBook.wishes(tier), TierBook.multiplier(tier)])
	t.check(rows == [[1, 3, 6, 300.0, 2, 1.0], [2, 3, 8, 330.0, 2, 1.5], [3, 4, 10, 360.0, 3, 2.0], [4, 5, 13, 390.0, 3, 2.5],
		[4, 6, 16, 420.0, 3, 3.0]], "each tier's readiness, slots, DP, clock, wishes and multiplier (spec §4) (%s)" % [rows])
	t.check(Array(TierBook.missions(1)) == ["warning"] and Array(TierBook.missions(2)) == ["miras_house", "broken_lanterns"]
		and Array(TierBook.missions(3)) == ["vigil_flame", "festival"] and Array(TierBook.missions(4)) == ["procession"]
		and Array(TierBook.missions(5)) == ["last_judgement", "long_night"], "the eight ★ missions on their tiers (spec §8)")
	t.check(TierBook.all().size() == 8 and TierBook.tier_of("festival") == 3 and TierBook.tier_of("feast_festival") == 0
		and not TierBook.has("feast_festival") and TierBook.has("long_night"), "found by id; the campaign's Feast is not one")
	var needs := []
	for tier in range(1, 6):
		needs.append(TierBook.need(tier))
	t.check(needs == [1, 2, 2, 1, 2], "while tiers are short, all of a tier's missions open the next (%s)" % [needs])
	t.check(TierBook.believers(10, 1) == 10 and TierBook.believers(15, 2) == 23 and TierBook.believers(10, 5) == 30
		and TierBook.believers(5, 4) == 13, "believers times the multiplier, rounded")
	t.check(TierBook.type_of("warning") == "Intercept" and TierBook.type_of("last_judgement") == "Destroy"
		and TierBook.type_of("nowhere") == "", "each card's type")
	t.check(Array(TierBook.mission_tags("warning")) == ["unaware_town"] and Array(TierBook.mission_tags("miras_house")) == ["spares_houses"]
		and TierBook.mission_tags("festival").is_empty(), "the mission tags the wishes filter on")


static func _unlock(t) -> void:
	var s := DescendState.new()
	t.check(s.open_tier == 1 and s.is_open(1) and not s.is_open(2) and not s.is_open(0), "Tier 1 is open from the start")
	t.check(DescendState.lock_text(2) == "Clear 1 Whisper mission" and DescendState.lock_text(3) == "Clear 2 Omen missions",
		"a locked tier's rule (%s; %s)" % [DescendState.lock_text(2), DescendState.lock_text(3)])
	s.cleared.append("warning")
	t.check(s.refresh_open() == 2 and s.open_tier == 2, "The Warning cleared opens Omen")
	s.cleared.append("miras_house")
	t.check(s.refresh_open() == 0 and s.open_tier == 2, "one of Omen's two does not open Wrath")
	s.cleared.append("broken_lanterns")
	t.check(s.refresh_open() == 3 and s.open_tier == 3, "both open it")
	s.cleared.clear()
	t.check(s.refresh_open() == 0 and s.open_tier == 3, "a tier never closes again")
	var far := DescendState.new()
	far.cleared = PackedStringArray(["warning", "miras_house", "broken_lanterns", "vigil_flame", "festival", "procession"])
	t.check(far.refresh_open() == 5 and far.open_tier == 5, "tiers open one after another, up to Ascendance")
	t.check(far.progress_line(1) == "Whisper 1 / 1 cleared: Omen is open" and s.progress_line(3) == "Wrath 0 / 2 cleared: 2 more open Reckoning"
		and far.progress_line(5) == "Ascendance 0 / 2 cleared", "the results' tier line (%s; %s)" % [far.progress_line(1), s.progress_line(3)])
	var one := DescendState.new()
	one.cleared.append("warning")
	one.refresh_open()
	one.cleared.append("miras_house")
	t.check(one.progress_line(2) == "Omen 1 / 2 cleared: one more opens Wrath", "one more (%s)" % one.progress_line(2))


static func _prices(t) -> void:
	var s := DescendState.new()
	var starting := 0
	for key in PowerBook.keys():
		starting += 1 if DescendState.starting(key) else 0
	t.check(starting == 15 and s.locked().size() == PowerBook.keys().size() - 15, "the 1 and 2 DP powers start unlocked: 15")
	t.check(s.is_unlocked("doom") and s.is_unlocked("heaven") and not s.is_unlocked("tsunami"), "Heaven Splitter (2 DP) is; Tsunami (4) is not")
	t.check(DescendState.unlock_price("tornado") == 45 and DescendState.unlock_price("tsunami") == 60
		and DescendState.unlock_price("voice") == 75 and DescendState.unlock_price("schism") == 90, "unlocking costs 15 x its DP")
	t.check(s.dp_price() == 25 and s.refusal("dp") == "believers" and not s.buy("dp"), "the first +1 DP is 25: too few believers")
	s.believers = 25
	t.check(s.buy("dp") and s.dp_bought == 1 and s.believers == 0 and s.dp_price() == 50, "bought for 25; the second is 50")
	s.believers = 10000
	for i in 5:
		s.buy("dp")
	t.check(s.dp_bought == DescendState.DP_LIMIT and s.refusal("dp") == "limit" and not s.buy("dp"), "six at most")
	t.check(s.buy("slot") and s.slot_bought == 1 and s.refusal("slot") == "limit", "one slot, once")
	var before := s.believers
	t.check(s.buy("tsunami") and s.unlocked.has("tsunami") and s.believers == before - 60 and s.refusal("tsunami") == "owned",
		"a power unlocked for its price, once")
	t.check(s.refusal("heaven") == "owned" and s.refusal("frog") == "unknown", "a starting power is owned; an unknown one refused")


static func _bank(t) -> void:
	var s := DescendState.new()
	var won := s.bank("warning", {"main": true, "main_time": 200.0, "earned": 10, "kept": 0})
	t.check(s.night == 1 and s.believers == 10 and s.cleared.has("warning") and bool(won.first_clear) and int(won.opened) == 2
		and String(won.progress) == "Whisper 1 / 1 cleared: Omen is open", "a night won: counted, banked, cleared, Omen open (%s)" % [won])
	t.check(Array(won.bests) == ["Fastest clear 3:20"] and is_equal_approx(float(s.fastest.warning), 200.0), "its time is a best")
	var lost := s.bank("warning", {"main": false, "main_time": 0.0, "earned": 0, "kept": 0})
	t.check(s.night == 2 and s.believers == 10 and not bool(lost.cleared) and (lost.bests as PackedStringArray).is_empty()
		and int(lost.night) == 2 and int(lost.total) == 10, "a night lost still counts, banks nothing")
	var slow := s.bank("warning", {"main": true, "main_time": 250.0, "earned": 10, "kept": 2})
	t.check(s.believers == 20 and not bool(slow.first_clear) and Array(slow.bests) == ["Most wishes granted: 2"]
		and int(s.most_wishes.warning) == 2, "a slower clear is no best; two wishes banked are")
	t.check(s.bank("warning", {"earned": -5}).believers == 0 and s.believers == 20, "a negative purse banks nothing")


static func _save(t) -> void:
	var path := "user://test_tiers.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	t.check(SaveFile.new().load_from(path).descend.night == 0, "no file: a fresh board")
	var save := SaveFile.new()
	save.descend.night = 4
	save.descend.believers = 77
	save.descend.cleared = PackedStringArray(["warning", "miras_house"])
	save.descend.dp_bought = 2
	save.descend.slot_bought = 1
	save.descend.unlocked = PackedStringArray(["tsunami"])
	save.descend.fastest = {"warning": 190.5}
	save.descend.most_wishes = {"warning": 2}
	save.descend.refresh_open()
	save.last_mission = "festival"
	save.save_to(path)
	var back := SaveFile.new().load_from(path).descend
	t.check(back.night == 4 and back.believers == 77 and Array(back.cleared) == ["warning", "miras_house"] and back.open_tier == 2
		and back.dp_bought == 2 and back.slot_bought == 1 and Array(back.unlocked) == ["tsunami"]
		and is_equal_approx(float(back.fastest.warning), 190.5) and int(back.most_wishes.warning) == 2, "the board comes back from the file")
	t.check(SaveFile.new().load_from(path).last_mission == "festival", "a board id is a mission the board remembers")

	var odd := ConfigFile.new()
	odd.set_value("descend", "night", -3)
	odd.set_value("descend", "open_tier", 9)
	odd.set_value("descend", "cleared", ["warning", "frog", "warning"])
	odd.set_value("descend", "dp_bought", 40)
	odd.set_value("descend", "unlocked", ["doom", "frog", "nova"])
	odd.set_value("descend", "fastest", {"frog": 5.0, "warning": "fast"})
	odd.set_value("descend", "most_wishes", 7)
	odd.save(path)
	var fixed := SaveFile.new().load_from(path).descend
	t.check(fixed.night == 0 and fixed.open_tier == 5 and Array(fixed.cleared) == ["warning"] and fixed.dp_bought == DescendState.DP_LIMIT
		and Array(fixed.unlocked) == ["nova"] and fixed.fastest.is_empty() and fixed.most_wishes.is_empty(),
		"a hand-edited board is pulled back into range, the unknown dropped")

	# A v0.10 save (spec §3.5): no [descend]; its board wins carry over as cleared, with no time.
	var old := ConfigFile.new()
	old.set_value("kak", "last_mission", "warning")
	old.set_value("mission.warning", "won", true)
	old.set_value("mission.last_judgement", "won", true)
	old.set_value("mission.last_judgement", "best_score", 9000)
	old.set_value("mission.long_night", "won", false)
	old.save(path)
	var carried := SaveFile.new().load_from(path).descend
	t.check(Array(carried.cleared) == ["warning", "last_judgement"] and carried.open_tier == 2 and carried.fastest.is_empty()
		and carried.night == 0 and carried.believers == 0, "a v0.10 save's wins carry over as cleared, Omen open, no time (%s)" % [carried.cleared])
	var with := ConfigFile.new()
	with.set_value("mission.warning", "won", true)
	with.set_value("descend", "night", 1)
	with.save(path)
	t.check(SaveFile.new().load_from(path).descend.cleared.is_empty(), "a save with its own [descend] carries nothing over")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
```

  - Add `"res://tests/test_tiers.gd",` at the end of `SUITES` in `tests/run_all.gd`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `TierBook` or `DescendState`.

- [ ] **Step 3: Create `src/game/descend/tier_book.gd`:**

```gdscript
class_name TierBook
extends RefCounted
## The god's five Awakening Tiers on the board (v0.11 M1, spec §3-§4): each tier's name and missions, and what it sets --
## the town's readiness, the base slots and Divine Power, the clock, the wishes heard and the believers' multiplier -- and
## the unlocking rule's count. First guesses, tuned per milestone. board() builds a board mission from a ★ mission.

## The tiers' names, Tier 1 first (2-4 are placeholders the user may rename).
const NAMES := ["Whisper", "Omen", "Wrath", "Reckoning", "Ascendance"]
## The board's missions on each tier, by id: spec §8's ★ missions (M2-M6 add the rest).
const MISSIONS := [["warning"], ["miras_house", "broken_lanterns"], ["vigil_flame", "festival"], ["procession"],
	["last_judgement", "long_night"]]
## The town's readiness on each tier, as ResponseProfile.level(): Unaware, Organized, Prepared, God-Resistant twice.
const READINESS := [1, 2, 3, 4, 4]
## The base slots and Divine Power on each tier; the upgrades add to them.
const SLOTS := [3, 3, 4, 5, 6]
const DP := [6, 8, 10, 13, 16]
## The clock (dawn) on each tier, in seconds.
const CLOCKS := [300.0, 330.0, 360.0, 390.0, 420.0]
## The wishes heard at each tier's descent, and the believers' multiplier.
const WISHES := [2, 2, 3, 3, 3]
const MULTIPLIERS := [1.0, 1.5, 2.0, 2.5, 3.0]
## Cleared missions of a tier that open the next (spec §3.2), fewer while a tier has fewer missions (before M6).
const NEED := 3
## The most slots a loadout can have: the HUD's row and the keys 1-6.
const MAX_SLOTS := 6
## The tier from which every mission keeps Halcyon's Gaze (spec §4), and the share of GazeMeter.SEEN_DEATH a seen death adds
## there: Broken Lanterns' share, a first guess for nights that kill hundreds.
const GAZE_TIER := 5
const GAZE_SHARE := 0.05
## Each board mission's type on its card (spec §3.1, §8).
const TYPES := {"warning": "Intercept", "miras_house": "Cult", "broken_lanterns": "Anchors", "vigil_flame": "Cult",
	"festival": "Break", "procession": "Kill", "last_judgement": "Destroy", "long_night": "Three acts"}
## The tags a mission declares for the wishes to filter on (spec §5.1): a wish listing one of them is never drawn there.
const MISSION_TAGS := {"warning": ["unaware_town"], "miras_house": ["spares_houses"]}


## A tier's entry in `table`, tiers counted from 1 (outside 1-5, the nearest tier's).
static func _at(table: Array, tier: int) -> Variant:
	return table[clampi(tier, 1, table.size()) - 1]


static func tier_name(tier: int) -> String:
	return String(_at(NAMES, tier))


static func missions(tier: int) -> PackedStringArray:
	return PackedStringArray(_at(MISSIONS, tier))


static func readiness(tier: int) -> int:
	return int(_at(READINESS, tier))


static func slots(tier: int) -> int:
	return int(_at(SLOTS, tier))


static func dp(tier: int) -> int:
	return int(_at(DP, tier))


static func clock(tier: int) -> float:
	return float(_at(CLOCKS, tier))


static func wishes(tier: int) -> int:
	return int(_at(WISHES, tier))


static func multiplier(tier: int) -> float:
	return float(_at(MULTIPLIERS, tier))


## Cleared missions of `tier` that open the next: NEED, or all of them while the tier has fewer (spec §3.2).
static func need(tier: int) -> int:
	return mini(NEED, missions(tier).size())


## The tier the board mission `id` is on, or 0 when it is not on the board.
static func tier_of(id: String) -> int:
	for tier in range(1, NAMES.size() + 1):
		if missions(tier).has(id):
			return tier
	return 0


static func has(id: String) -> bool:
	return tier_of(id) > 0


## Every board mission, tier by tier.
static func all() -> PackedStringArray:
	var out := PackedStringArray()
	for tier in range(1, NAMES.size() + 1):
		out.append_array(missions(tier))
	return out


static func type_of(id: String) -> String:
	return String(TYPES.get(id, ""))


static func mission_tags(id: String) -> PackedStringArray:
	return PackedStringArray(MISSION_TAGS.get(id, []))


## Believers paid on `tier` for `base` (spec §4): times the tier's multiplier, rounded.
static func believers(base: int, tier: int) -> int:
	return roundi(float(base) * multiplier(tier))
```

- [ ] **Step 4: Create `src/game/descend/descend_state.gd`:**

```gdscript
class_name DescendState
extends RefCounted
## Where the god stands on the tier board (v0.11 M1, spec §3): the nights played, the believers banked, the highest tier
## open, the missions cleared, the upgrades bought and the powers unlocked, and each mission's bests. It is the save's
## [descend] section; [campaign] is the Lantern campaign's and never touched here.

const SECTION := "descend"
## The upgrades (spec §3.4, first guesses): the n-th +1 DP costs DP_STEP x n believers, DP_LIMIT at most; the one +1 slot
## costs SLOT_PRICE; unlocking a power costs UNLOCK_PER_DP x its DP. A power costing STARTING_DP or less starts unlocked.
const DP_STEP := 25
const DP_LIMIT := 6
const SLOT_PRICE := 150
const SLOT_LIMIT := 1
const UNLOCK_PER_DP := 15
const STARTING_DP := 2
## The v0.10 board missions whose wins carry over to their ★ missions as cleared (spec §3.5).
const CARRIED := ["warning", "long_night", "last_judgement"]

## Board nights played to their end, won or lost (spec §3.3).
var night := 0
var believers := 0
## The highest tier open (spec §3.2); a tier never closes again.
var open_tier := 1
## Missions whose main objective was done in some night, ascended or caught after it.
var cleared := PackedStringArray()
var dp_bought := 0
var slot_bought := 0
## Powers bought on the Upgrades screen; the starting ones are never listed.
var unlocked := PackedStringArray()
## Per mission (spec §3.5): seconds from the night's start to its main objective at its fastest clear, and the most wishes
## granted and banked in one night.
var fastest := {}
var most_wishes := {}


## The power starts unlocked: it costs STARTING_DP or less (15 of today's 38).
static func starting(key: String) -> bool:
	var p := PowerBook.get_power(key)
	return not p.is_empty() and int(p.dp) <= STARTING_DP


func is_unlocked(key: String) -> bool:
	return starting(key) or unlocked.has(key)


## Every power still locked, in PowerBook's order: greyed in the board's draft (spec §3.4).
func locked() -> PackedStringArray:
	var out := PackedStringArray()
	for key in PowerBook.keys():
		if not is_unlocked(key):
			out.append(key)
	return out


## The next +1 DP's price: DP_STEP x n for the n-th.
func dp_price() -> int:
	return DP_STEP * (dp_bought + 1)


static func unlock_price(key: String) -> int:
	return UNLOCK_PER_DP * int(PowerBook.get_power(key).get("dp", 0))


## What `what` costs: "dp", "slot", or a power key.
func price(what: String) -> int:
	match what:
		"dp":
			return dp_price()
		"slot":
			return SLOT_PRICE
	return unlock_price(what)


## Why `what` cannot be bought, or "" when it can: "limit" (none left to buy), "unknown" (no such power), "owned" (a power
## already unlocked), "believers" (too few).
func refusal(what: String) -> String:
	if what == "dp":
		if dp_bought >= DP_LIMIT:
			return "limit"
	elif what == "slot":
		if slot_bought >= SLOT_LIMIT:
			return "limit"
	elif PowerBook.get_power(what).is_empty():
		return "unknown"
	elif is_unlocked(what):
		return "owned"
	if believers < price(what):
		return "believers"
	return ""


## Buys `what`, spending its price; false, and nothing spent, when refusal() says why not.
func buy(what: String) -> bool:
	if refusal(what) != "":
		return false
	believers -= price(what)
	match what:
		"dp":
			dp_bought += 1
		"slot":
			slot_bought += 1
		_:
			unlocked.append(what)
	return true


## How many of `tier`'s missions are cleared.
func cleared_in(tier: int) -> int:
	var n := 0
	for id in TierBook.missions(tier):
		n += 1 if cleared.has(id) else 0
	return n


func is_open(tier: int) -> bool:
	return tier >= 1 and tier <= open_tier


## Opens every tier the rule now opens (spec §3.2: Tier T+1 once TierBook.need(T) of Tier T's missions are cleared), never
## closing one. Returns the highest tier newly opened, or 0.
func refresh_open() -> int:
	var was := open_tier
	while open_tier < TierBook.NAMES.size() and cleared_in(open_tier) >= TierBook.need(open_tier):
		open_tier += 1
	return open_tier if open_tier > was else 0


## A locked tier's rule (spec §3.1): "Clear 3 Omen missions" -- how many of the tier before it.
static func lock_text(tier: int) -> String:
	var n := TierBook.need(tier - 1)
	return "Clear %d %s mission%s" % [n, TierBook.tier_name(tier - 1), "" if n == 1 else "s"]


## The results' tier line (spec §6): "Omen 1 / 2 cleared: one more opens Wrath", "...: Wrath is open", or for the last tier
## its count alone.
func progress_line(tier: int) -> String:
	var n := cleared_in(tier)
	var need := TierBook.need(tier)
	var head := "%s %d / %d cleared" % [TierBook.tier_name(tier), mini(n, need), need]
	if tier >= TierBook.NAMES.size():
		return head
	var next := TierBook.tier_name(tier + 1)
	if is_open(tier + 1):
		return "%s: %s is open" % [head, next]
	var left := need - n
	return "%s: %s" % [head, ("one more opens " + next) if left == 1 else ("%d more open %s" % [left, next])]


## Banks a finished board night for the mission `id` (spec §3.3, §6) and returns what changed, for the results. `outcome` is
## Descent.report()'s "descend": `main` (its main objective done), `main_time` (seconds from the night's start to it),
## `earned` (the believers it banks; Descent has already counted a loss or a caught night out) and `kept` (wishes granted and
## banked). Every night counts, won or lost.
func bank(id: String, outcome: Dictionary) -> Dictionary:
	night += 1
	var earned := maxi(int(outcome.get("earned", 0)), 0)
	believers += earned
	var main := bool(outcome.get("main", false))
	var first := main and not cleared.has(id)
	if first:
		cleared.append(id)
	var bests := PackedStringArray()
	var time := float(outcome.get("main_time", 0.0))
	if main and time > 0.0 and (not fastest.has(id) or time < float(fastest[id])):
		fastest[id] = time
		bests.append("Fastest clear %s" % UiTheme.clock(time))
	var kept := int(outcome.get("kept", 0))
	if kept > int(most_wishes.get(id, 0)):
		most_wishes[id] = kept
		bests.append("Most wishes granted: %d" % kept)
	var opened := refresh_open()
	return {"believers": earned, "total": believers, "night": night, "cleared": main, "first_clear": first, "opened": opened,
		"progress": progress_line(maxi(TierBook.tier_of(id), 1)), "bests": bests}


func write(cfg: ConfigFile) -> void:
	cfg.set_value(SECTION, "night", night)
	cfg.set_value(SECTION, "believers", believers)
	cfg.set_value(SECTION, "open_tier", open_tier)
	cfg.set_value(SECTION, "cleared", cleared)
	cfg.set_value(SECTION, "dp_bought", dp_bought)
	cfg.set_value(SECTION, "slot_bought", slot_bought)
	cfg.set_value(SECTION, "unlocked", unlocked)
	cfg.set_value(SECTION, "fastest", fastest)
	cfg.set_value(SECTION, "most_wishes", most_wishes)


## The board as the file holds it (spec §3.5); a fresh board when the file has no [descend] section. A hand-edited value out
## of range is pulled back into it, and an unknown mission or power is dropped.
static func read(cfg: ConfigFile) -> DescendState:
	var s := DescendState.new()
	if not cfg.has_section(SECTION):
		return s
	s.night = maxi(int(cfg.get_value(SECTION, "night", 0)), 0)
	s.believers = maxi(int(cfg.get_value(SECTION, "believers", 0)), 0)
	s.open_tier = clampi(int(cfg.get_value(SECTION, "open_tier", 1)), 1, TierBook.NAMES.size())
	for id in _strings(cfg.get_value(SECTION, "cleared", PackedStringArray())):
		if TierBook.has(id) and not s.cleared.has(id):
			s.cleared.append(id)
	s.dp_bought = clampi(int(cfg.get_value(SECTION, "dp_bought", 0)), 0, DP_LIMIT)
	s.slot_bought = clampi(int(cfg.get_value(SECTION, "slot_bought", 0)), 0, SLOT_LIMIT)
	for key in _strings(cfg.get_value(SECTION, "unlocked", PackedStringArray())):
		if not PowerBook.get_power(key).is_empty() and not starting(key) and not s.unlocked.has(key):
			s.unlocked.append(key)
	var times = cfg.get_value(SECTION, "fastest", {})
	if times is Dictionary:
		for id in times:
			if TierBook.has(String(id)) and (times[id] is float or times[id] is int) and float(times[id]) > 0.0:
				s.fastest[String(id)] = float(times[id])
	var counts = cfg.get_value(SECTION, "most_wishes", {})
	if counts is Dictionary:
		for id in counts:
			if TierBook.has(String(id)) and counts[id] is int:
				s.most_wishes[String(id)] = maxi(int(counts[id]), 0)
	s.refresh_open()
	return s


## A list read from the file, as strings; anything else reads as none.
static func _strings(v: Variant) -> PackedStringArray:
	return PackedStringArray(v) if v is PackedStringArray or v is Array else PackedStringArray()


## A v0.10 save, with no [descend] section (spec §3.5): its board wins of The Warning, The Long Night and Last Judgement
## carry over to their ★ missions as cleared, and the tiers open by the rule. v0.10 kept no times, so no fastest clear comes.
func carry_over(save: SaveFile) -> void:
	for id: String in CARRIED:
		if bool(save.best(id).get("won", false)) and not cleared.has(id):
			cleared.append(id)
	refresh_open()
```

- [ ] **Step 5: The save.** In `src/game/save_file.gd`:
  - In the class doc's section list, add after the `[campaign]` line:

```gdscript
##   [descend]             night, believers, open_tier, cleared, dp_bought, slot_bought, unlocked, fastest, most_wishes (v0.11)
```

  - Add after `var campaign: CampaignState`:

```gdscript
## The tier board (v0.11 M1): its nights, believers, open tiers, cleared missions, upgrades and bests. Never null: a fresh
## board until a file says otherwise.
var descend := DescendState.new()
```

  - In `load_from()`, replace the `last_mission = ...` line with:

```gdscript
	var known := MissionBook.get_mission(wanted).id == wanted or TierBook.has(wanted)
	last_mission = wanted if known else MissionBook.LAST_JUDGEMENT
```

  - Then replace `campaign = CampaignState.read(cfg)` with:

```gdscript
	campaign = CampaignState.read(cfg)
	descend = DescendState.read(cfg)
	if not cfg.has_section(DescendState.SECTION):
		descend.carry_over(self)  # a v0.10 save: its board wins open their ★ missions (spec §3.5)
```

  - In `save_to()`, after the `campaign.write(cfg)` lines, add `descend.write(cfg)`.

- [ ] **Step 6: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`, the count up by about 25.

- [ ] **Step 7: Commit.**

```bash
git add src/game/descend/tier_book.gd src/game/descend/descend_state.gd src/game/save_file.gd tests/test_tiers.gd tests/run_all.gd
git commit -m "feat: the five tiers and the [descend] save, with unlocking, prices and banking (v0.11 M1)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

(Add the new scripts' `.uid` files if Godot made them.)

---

### Task 3: Board versions of the ★ missions

**Files:**
- Create: `src/game/mission/event_objective.gd`, `tests/test_board_missions.gd`
- Modify: `src/game/descend/tier_book.gd` (`board()` and its helpers)
- Modify: `src/game/mission/objective.gd`, `src/game/mission/event_timeline.gd`, `src/game/mission/mission_def.gd`, `src/game/mission/act_def.gd`, `src/game/response_profile.gd`, `src/game/mission/mission_director.gd`
- Modify: the timeline lines of six directors:
  - `miras_house_director.gd:90`, `broken_lanterns_director.gd:101`, `festival_director.gd:61`, `procession_director.gd:72`, `vigil_flame_director.gd:123`, `judgement_director.gd:17`;
  - `vigil_flame_director.gd` `_add_events()`;
  - `festival_director.gd` (`crowd_size`, line 107).
- Modify: `src/game/mission.gd` (`_build_act()`)
- Modify: `src/game/mission/mission_hints.gd` (the `festival` line), `tests/test_mission_hints.gd`, `tests/run_all.gd`

**Interfaces:**
- Consumes: `TierBook` (Task 2), `DescendState.dp_bought` / `slot_bought` (Task 2).
- Produces:
  - **`Objective`:** `var deadline := false`.
  - **`EventObjective`:** `new(id := "", text := "", why := "")`, `event_id: String`; always a deadline.
  - **`EventTimeline`:** `stretched(factor: float) -> EventTimeline`, `stretch_factor() -> float`, `has_come(id: String) -> bool`, `seconds_to(id: String) -> float`. `upcoming()`'s `at` and `in` are real seconds.
  - **`MissionDef`:**
    - vars: `tier_floor := -1`, `stretch := 1.0`, `tune: Callable` (`func(d: MissionDirector) -> void`), `mission_tags := PackedStringArray()`;
    - `make_director() -> MissionDirector` (made, stretched and tuned, not set up).
  - **`MissionDirector`:** `var stretch := 1.0`, `_new_timeline() -> EventTimeline`.
  - **`ResponseProfile`:** `static for_level(rank: int) -> ResponseProfile`, `at_least(rank: int) -> ResponseProfile`.
  - **`FestivalDirector`:** `var crowd_size := FESTIVAL_CROWD`.
  - **`TierBook`:**
    - `static board(id: String, state: DescendState = null) -> MissionDef` (null off the board);
    - consts `FESTIVAL_NEED := 80`, `FESTIVAL_CROWD := 120`, `FESTIVAL_CLOSE := 270.0`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_board_missions.gd`:

```gdscript
extends RefCounted
## v0.11 M1 board versions (spec §4, §7.2): each ★ mission at its tier's clock, readiness (a floor: raised, never lowered),
## base budget plus upgrades (six slots at most) and no bonuses; timelines stretched to the longer clock -- story time, so
## a director's own waits stretch with it; the Festival's raised need and its 4:30 close, a deadline; the Gaze objective at
## Tier 5; MissionBook's own missions untouched.

const DT := 0.05


static func run(t) -> void:
	_timeline(t)
	_profiles(t)
	_defs(t)
	_directors(t)


## A world for `def`: its town at the readiness the board sets, its director made by the def (stretched and tuned).
static func _world(def: MissionDef) -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := def.make_director().setup(rules, crowd, town, null)
	rules.director = director
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director}


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


static func _timeline(t) -> void:
	var plain := EventTimeline.new()
	plain.add(10.0, "a", "A")
	plain.step(10.0)
	t.check(Array(plain.fired_ids()) == ["a"] and plain.stretch_factor() == 1.0, "an unstretched timeline fires on time")
	var tl := EventTimeline.new().stretched(2.0)
	tl.add(10.0, "a", "A")
	tl.add(30.0, "b", "B")
	tl.step(19.9)
	t.check(tl.fired_ids().is_empty() and is_equal_approx(tl.elapsed(), 9.95), "stretched x2: not yet at 19.9 s (%f)" % tl.elapsed())
	var next: Dictionary = tl.upcoming(1)[0]
	t.check(is_equal_approx(float(next["in"]), 0.1) and is_equal_approx(float(next["at"]), 20.0),
		"the strip reads real seconds (%s)" % [next])
	tl.step(0.2)
	t.check(Array(tl.fired_ids()) == ["a"] and tl.has_come("a") and not tl.has_come("b") and tl.seconds_to("a") == 0.0
		and is_equal_approx(tl.seconds_to("b"), (30.0 - 10.05) * 2.0), "fired at 20 s; the next in real seconds")
	t.check(not tl.has_come("nowhere") and tl.seconds_to("nowhere") == 0.0, "an unknown event has not come")
	var obj := EventObjective.new("b", "Square closes", "closed")
	t.check(obj.deadline and obj.reason == "closed" and not Objective.new().deadline, "an event's objective is a deadline")


static func _profiles(t) -> void:
	var names := []
	for rank in range(0, 5):
		names.append(ResponseProfile.for_level(rank).tier_name())
	t.check(names == ["Unprepared", "Unaware", "Organized", "Prepared", "God-Resistant"], "a rank's profile (%s)" % [names])
	var aware := ResponseProfile.unaware()
	t.check(aware.at_least(2).tier_name() == "Organized" and aware.at_least(1) == aware and aware.at_least(-1) == aware,
		"a floor raises the town, never lowers it")
	var ready := ResponseProfile.for_tier(ResponseProfile.Tier.GOD_RESISTANT)
	t.check(ready.at_least(3) == ready, "a town above the floor stays as it is")


static func _defs(t) -> void:
	for id in TierBook.all():
		var def := TierBook.board(id)
		var tier := TierBook.tier_of(id)
		var ok := def != null and def.id == id and def.tier == tier and def.slots == TierBook.slots(tier)
		ok = ok and def.dp_capacity == TierBook.dp(tier) and not def.chooses_difficulty() and def.bonuses().is_empty()
		ok = ok and def.response_profile(ResponseProfile.Tier.UNPREPARED).level() >= TierBook.readiness(tier)
		if not def.has_acts():
			ok = ok and is_equal_approx(def.clock, TierBook.clock(tier))
		t.check(ok, "%s at Tier %d: its clock, readiness and budget, no bonuses, no difficulty" % [id, tier])
	t.check(TierBook.board("feast_festival") == null and TierBook.board("nowhere") == null, "no board version off the board")
	t.check(TierBook.board("miras_house").response_profile(ResponseProfile.DEFAULT).tier_name() == "Organized"
		and TierBook.board("warning").response_profile(ResponseProfile.DEFAULT).tier_name() == "Unaware"
		and TierBook.board("last_judgement").response_profile(ResponseProfile.Tier.UNPREPARED).tier_name() == "God-Resistant",
		"Mira's House is raised to Organized; The Warning stays Unaware; Last Judgement ignores a chosen difficulty")
	var ln := TierBook.board("long_night")
	var acts_ok := ln.scored and ln.acts.size() == 4
	for a: ActDef in ln.acts:
		acts_ok = acts_ok and a.slots == 6 and a.dp_capacity == 16 and a.tier_floor == 4
	t.check(acts_ok and ln.first_act().town(NightState.new()).tier_name() == "God-Resistant"
		and is_equal_approx(ln.act("judgement").clock, 300.0), "The Long Night: every act at the tier's budget and readiness, its own clocks")
	var stretches := [TierBook.board("miras_house").stretch, TierBook.board("broken_lanterns").stretch,
		TierBook.board("vigil_flame").stretch, TierBook.board("procession").stretch, TierBook.board("festival").stretch]
	t.check(is_equal_approx(stretches[0], 2.2) and is_equal_approx(stretches[1], 330.0 / 180.0) and is_equal_approx(stretches[2], 2.0)
		and is_equal_approx(stretches[3], 2.6) and is_equal_approx(stretches[4], 1.8), "event times stretch with the clock (%s)" % [stretches])
	var state := DescendState.new()
	state.dp_bought = 2
	state.slot_bought = 1
	var w := TierBook.board("warning", state)
	var lj := TierBook.board("last_judgement", state)
	t.check(w.slots == 4 and w.dp_capacity == 8 and lj.slots == TierBook.MAX_SLOTS and lj.dp_capacity == 18,
		"upgrades add to the base; six slots at most (%d)" % lj.slots)
	t.check(Array(TierBook.board("warning").mission_tags) == ["unaware_town"] and TierBook.board("festival").mission_tags.is_empty(),
		"each carries its mission tags")
	var gazes := []
	for o in lj.objectives():
		gazes.append(o is GazeObjective)
	var omen_gaze := false
	for o in ln.act("omen").objectives():
		omen_gaze = omen_gaze or o is GazeObjective
	var judged := false
	for o in ln.act("judgement").objectives():
		judged = judged or o is GazeObjective
	var t4 := false
	for o in TierBook.board("procession").objectives():
		t4 = t4 or o is GazeObjective
	t.check(gazes == [false, false, false, true] and omen_gaze and judged and not t4, "Tier 5 keeps the Gaze, in every act; Tier 4 does not")
	t.check(lj.goal == "Destroy the Citadel and break the city before dawn", "Last Judgement's goal no longer names 6:00")
	var fest := TierBook.board("festival")
	var reasons := []
	for o in fest.objectives():
		reasons.append([o.reason, o.deadline])
	t.check(reasons == [["festival", false], ["closed", true]] and fest.name == "The Festival" and fest.director == FestivalDirector,
		"the Festival: break it before the square closes, a deadline (%s)" % [reasons])
	var act_reasons := []
	for o in MissionBook.long_night().act("festival").objectives():
		act_reasons.append([o.reason, o.deadline])
	t.check(act_reasons == [["festival", false], ["closed", false]], "The Long Night's own Festival is untouched (%s)" % [act_reasons])
	var book := MissionBook.miras_house()
	t.check(is_equal_approx(book.clock, 150.0) and book.stretch == 1.0 and book.tier_floor == -1 and not book.bonuses().is_empty(),
		"MissionBook's own Mira's House is left as it was")


static func _directors(t) -> void:
	var s := _world(TierBook.board("miras_house"))
	var m: MirasHouseDirector = s.d
	var venn: Dictionary = m.timeline.upcoming(1)[0]
	t.check(m.stretch == 2.2 and String(venn.id) == "venn" and is_equal_approx(float(venn["in"]), 88.0),
		"Mira's House: the Inquisitor searches at 1:28, not 0:40 (%s)" % [venn])
	_done(s)

	var f := _world(TierBook.board("festival"))
	var fd: FestivalDirector = f.d
	var close := (f.rules as Rules).objectives[1]
	t.check(fd.need == TierBook.FESTIVAL_NEED and fd.crowd_size == TierBook.FESTIVAL_CROWD and fd.goers.size() > TierBook.FESTIVAL_NEED
		and is_equal_approx(fd.timeline.seconds_to("close"), TierBook.FESTIVAL_CLOSE) and close.hud_text(f.rules) == "Square closes 4:30",
		"the Festival: %d goers, %d needed, the square closing at 4:30" % [fd.goers.size(), fd.need])
	fd.timeline.step(TierBook.FESTIVAL_CLOSE + DT)  # real seconds: the timeline divides by its stretch itself
	t.check(close.check(f.rules) == Objective.Status.FAILED, "the close fails it once it comes")
	_done(f)

	var v := _world(TierBook.board("vigil_flame"))
	var vd: VigilFlameDirector = v.d
	# Read from the events themselves: the strip leaves the search off while the light sleeps (its guard).
	var search := -1.0
	for e: Dictionary in vd.timeline._events:
		if String(e.id) == "search":
			search = float(e.at) * vd.timeline.stretch_factor()
	t.check(absf(search - (360.0 - Searchlight.SEARCH_LAST)) < 0.01, "the Vigil Flame's search keeps the clock's last 20 s (%f)" % search)
	_done(v)

	var book := _world(MissionBook.miras_house())
	t.check((book.d as MirasHouseDirector).stretch == 1.0
		and is_equal_approx(float((book.d as MirasHouseDirector).timeline.upcoming(1)[0]["in"]), MirasHouseDirector.VENN_AT),
		"the campaign's Mira's House searches at 0:40 as before")
	_done(book)
```

  - Add `"res://tests/test_board_missions.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `EventObjective`, `stretched`, `for_level`, `board` or `make_director`.

- [ ] **Step 3: Objectives.**
  - In `src/game/mission/objective.gd`, add after `var reason := ""`:

```gdscript
## A limit on the main objective alone (v0.11 M1: the board's Festival, its square closing before dawn): once a board night's
## main objective is done, a deadline no longer applies (Rules._check_caught()).
var deadline := false
```

  - Create `src/game/mission/event_objective.gd`:

```gdscript
class_name EventObjective
extends Objective
## A deadline set by the director's timeline (v0.11 M1, spec §7.2): FAILED once the event `event_id` has come -- the board's
## Festival, its square closing at 4:30 with dawn at 6:00. A deadline is on the main objective alone (Objective.deadline).

var event_id := ""


func _init(id := "", text := "", why := "") -> void:
	event_id = id
	label = text
	reason = why
	deadline = true


func check(rules: Rules) -> Status:
	var tl := _timeline(rules)
	return Status.FAILED if tl != null and tl.has_come(event_id) else Status.PENDING


## "Square closes 3:12": the real seconds until the event, as the clock reads them; "" with no label or no timeline.
func hud_text(rules: Rules) -> String:
	var tl := _timeline(rules)
	if label == "" or tl == null:
		return ""
	return "%s %s" % [label, UiTheme.clock(tl.seconds_to(event_id))]


static func _timeline(rules: Rules) -> EventTimeline:
	return rules.director.timeline if rules != null and rules.director != null else null
```

- [ ] **Step 4: The stretched timeline.** In `src/game/mission/event_timeline.gd`:
  - Add after `var _elapsed := 0.0`:

```gdscript
## How many times slower the timeline's own seconds run than the night's (v0.11 M1, stretched()): an event `at` seconds in,
## and every wait a director measures with elapsed(), comes that many times later in real seconds. 1 off the board.
var _scale := 1.0


## A timeline whose events and elapsed() run `factor` times slower than real time (v0.11 M1, spec §7.2: a board mission's
## windows stretched to its tier's longer clock). 1 leaves it as it was.
func stretched(factor: float) -> EventTimeline:
	_scale = maxf(factor, 0.01)
	return self


func stretch_factor() -> float:
	return _scale
```

  - In `step()`, replace `_elapsed += delta` with `_elapsed += delta / _scale`.
  - In `upcoming()`, replace the `out.append(...)` line with:

```gdscript
			out.append({"at": float(e.at) * _scale, "id": e.id, "label": e.label,
				"in": maxf((float(e.at) - _elapsed) * _scale, 0.0)})
```

  - Add after `fired_ids()`:

```gdscript
## The event `id` has come, fired or dropped by its guard (v0.11 M1: EventObjective's deadline); false for none.
func has_come(id: String) -> bool:
	for e in _events:
		if String(e.id) == id:
			return bool(e.done)
	return false


## Real seconds until the event `id` comes (v0.11 M1); 0 once it has, or for no such event.
func seconds_to(id: String) -> float:
	for e in _events:
		if String(e.id) == id and not bool(e.done):
			return maxf((float(e.at) - _elapsed) * _scale, 0.0)
	return 0.0
```

  - At `_scale` 1, `delta / 1.0` and `x * 1.0` are exact, so every timeline off the board runs as before.

- [ ] **Step 5: Readiness floors.**
  - In `src/game/response_profile.gd`, add after `level()`:

```gdscript
## The profile for a readiness rank (v0.11 M1: a board tier's floor), level() turned back: 0 Unprepared, 1 Unaware,
## 2 Organized, 3 Prepared, 4 and above God-Resistant.
static func for_level(rank: int) -> ResponseProfile:
	match rank:
		0:
			return for_tier(Tier.UNPREPARED)
		1:
			return unaware()
		2:
			return for_tier(Tier.ORGANIZED)
		3:
			return for_tier(Tier.PREPARED)
	return for_tier(Tier.GOD_RESISTANT)


## This profile, or `rank`'s when this one is less ready (v0.11 M1, spec §4: a mission may raise its tier's town, never lower
## it). A rank below 0 leaves it as it is.
func at_least(rank: int) -> ResponseProfile:
	return self if rank < 0 or level() >= rank else for_level(rank)
```

  - In `src/game/mission/mission_def.gd`, add after `var make_bonuses: Callable`:

```gdscript
## The board's town readiness for its tier (v0.11 M1, spec §4), as ResponseProfile.level(): the town is at least this ready,
## whatever the mission sets; -1 off the board.
var tier_floor := -1
## How much slower the director's timeline runs (v0.11 M1, spec §7.2): a board mission's tier clock over its own, so its
## windows still fall inside the night; 1 off the board.
var stretch := 1.0
## func(director: MissionDirector) -> void: a board version's tuning of its director before its setup (v0.11 M1: the
## Festival's raised need); unset elsewhere.
var tune: Callable
## The tags the mission declares for the wishes to filter on (v0.11 M1, spec §5.1): "unaware_town", "spares_houses".
var mission_tags := PackedStringArray()
```

  - Replace `chooses_difficulty()` and `response_profile()` (with their comments):

```gdscript
## Prepare's difficulty picker applies: the mission does not set the town's readiness itself, nor does its board tier
## (v0.11 M1, spec §4: board missions drop the picker).
func chooses_difficulty() -> bool:
	return profile == "" and tier_floor < 0


## The town's response for this mission: the difficulty chosen on Prepare, unless the mission sets its own. A night
## (v0.10) answers with its first act's town, which reads the night it is given: the campaign's Feast after a rung bell.
## On the board (v0.11 M1) the tier's readiness is a floor: raised to, never lowered.
func response_profile(chosen: ResponseProfile.Tier) -> ResponseProfile:
	var own: ResponseProfile
	if profile == "night" and has_acts():
		own = first_act().response_profile(chosen)
	elif profile == "unaware" or profile == "night":
		own = ResponseProfile.unaware()
	elif tier_floor >= 0:
		own = ResponseProfile.for_level(tier_floor)
	else:
		own = ResponseProfile.for_tier(chosen)
	return own.at_least(tier_floor)


## The mission's director, made and tuned but not yet set up (v0.11 M1): its timeline's stretch, and any tuning a board
## version asks for, are in place before its _begin() runs. Null for a mission without one.
func make_director() -> MissionDirector:
	if director == null:
		return null
	var d := director.new() as MissionDirector
	d.stretch = stretch
	if tune.is_valid():
		tune.call(d)
	return d
```

  - In `src/game/mission/act_def.gd`, replace `town()`:

```gdscript
## The town this act wants (v0.09), at least as ready as the board's tier sets (v0.11 M1, tier_floor).
func town(n: NightState) -> ResponseProfile:
	var own: ResponseProfile = make_town.call(n) if make_town.is_valid() else ResponseProfile.unaware()
	return own.at_least(tier_floor)
```

- [ ] **Step 6: Directors take the stretch.**
  - In `src/game/mission/mission_director.gd`, add after `var reports_started := 0`:

```gdscript
## How much slower the director's timeline runs (v0.11 M1, spec §7.2): MissionDef.stretch, set before setup(); 1 off the
## board.
var stretch := 1.0
```

  - Add after `_walkable()`:

```gdscript
## A fresh timeline for the director's events (v0.11 M1): stretched by `stretch`, so a board mission's windows fall inside
## its longer night. Off the board it is EventTimeline.new()'s own.
func _new_timeline() -> EventTimeline:
	return EventTimeline.new().stretched(stretch)
```

  - Replace `timeline = EventTimeline.new()` with `timeline = _new_timeline()` at exactly these six lines:
    - `miras_house_director.gd:90`
    - `broken_lanterns_director.gd:101`
    - `festival_director.gd:61`
    - `procession_director.gd:72`
    - `vigil_flame_director.gd:123`
    - `judgement_director.gd:17`
  - In `vigil_flame_director.gd`, replace `_add_events()`:

```gdscript
## The strip's search: in the clock's last Searchlight.SEARCH_LAST seconds, while the light is awake (v0.11 M1: in the
## timeline's own seconds, which a board mission stretches).
func _add_events() -> void:
	timeline.add(maxf(rules.time_left - Searchlight.SEARCH_LAST, 0.0) / stretch, "search", "The light searches", Callable(),
		func() -> bool: return searchlight.on)
```

  - In `festival_director.gd`:
    - add after `var need := FESTIVAL_NEED`:

```gdscript
## How many come to the square (v0.11 M1: the board's Festival raises it with the need, TierBook.FESTIVAL_CROWD).
var crowd_size := FESTIVAL_CROWD
```

    - replace `for p in pool.slice(0, FESTIVAL_CROWD):` with `for p in pool.slice(0, crowd_size):`.
  - In `src/game/mission.gd` `_build_act()`, replace the `if play.director != null:` block with:

```gdscript
	var made := play.make_director()
	if made != null:
		_director = made.setup(_rules, _crowd, _town, _bf.ctx, _night)
		_rules.director = _director
```

- [ ] **Step 7: `TierBook.board()`.** Add to `src/game/descend/tier_book.gd`, after `MISSION_TAGS`:

```gdscript
## The board's Festival (spec §7.2): the need rises to FESTIVAL_NEED, more come (FESTIVAL_CROWD) so it can be met, and the
## guard closes the square at FESTIVAL_CLOSE, before dawn.
const FESTIVAL_NEED := 80
const FESTIVAL_CROWD := 120
const FESTIVAL_CLOSE := 270.0
```

  - Add after `believers()`:

```gdscript
## A board mission (v0.11 M1, spec §4, §7.2): the ★ mission `id` at its tier.
## - The tier's clock (The Long Night keeps its acts').
## - Its readiness as a floor.
## - The base slots and DP plus `state`'s upgrades (MAX_SLOTS at most).
## - Its event times stretched to the longer clock.
## - No bonuses: the wishes take their place.
## - Its mission tags, and at GAZE_TIER the Gaze objective.
## Null for an id not on the board. MissionBook's own missions are fresh copies each call, so nothing here reaches them.
static func board(id: String, state: DescendState = null) -> MissionDef:
	var tier := tier_of(id)
	if tier == 0:
		return null
	var m: MissionDef = _from_act(id) if id == "festival" or id == "procession" else MissionBook.get_mission(id)
	var own_clock := m.clock
	m.tier = tier
	m.tier_floor = readiness(tier)
	m.make_bonuses = Callable()
	m.mission_tags = mission_tags(id)
	_budget(m, tier, state)
	if not m.has_acts():
		m.clock = clock(tier)
		m.stretch = m.clock / own_clock
	match id:
		"festival":
			_festival(m)
		"last_judgement":
			m.goal = "Destroy the Citadel and break the city before dawn"
	if tier >= GAZE_TIER:
		_gaze(m)
	return m


## The tier's slots and DP plus the upgrades bought, for the mission and each of its acts, which take its tier and floor.
static func _budget(m: MissionDef, tier: int, state: DescendState) -> void:
	m.slots = mini(slots(tier) + (state.slot_bought if state != null else 0), MAX_SLOTS)
	m.dp_capacity = dp(tier) + (state.dp_bought if state != null else 0)
	for a: ActDef in m.acts:
		a.tier = tier
		a.tier_floor = m.tier_floor
		a.slots = m.slots
		a.dp_capacity = m.dp_capacity


## The Festival or the Procession as a mission of its own (spec §8 rows 12 and 16): The Long Night's act -- its director,
## objectives and windows -- on a night of its own, in a town the floor raises. Its id is the act's.
static func _from_act(id: String) -> MissionDef:
	var a := MissionBook.long_night().act(id)
	var m := MissionDef.new()
	m.id = id
	m.name = a.name.trim_prefix("Act II: ")
	m.brief = a.brief
	m.goal = a.goal
	m.goal_label = a.goal_label
	m.lose = a.lose
	m.clock = a.clock
	m.profile = "unaware"
	m.pool = a.pool
	m.default_loadout = a.default_loadout
	m.intro_from = a.intro_from
	m.camera_at = a.camera_at
	m.intro_banner = m.name.to_upper()
	m.director = a.director
	m.make_objectives = a.make_objectives
	return m


## The board's Festival (spec §7.2): its windows stretched to the 4:30 close, the need and the crowd raised before the
## director gathers it, and the close a deadline -- dawn is the tier's.
static func _festival(m: MissionDef) -> void:
	m.stretch = FESTIVAL_CLOSE / FestivalDirector.CLOSE_AT
	m.goal = "Break the festival before the guard closes the square at %s" % UiTheme.clock(FESTIVAL_CLOSE)
	m.tune = func(d: MissionDirector) -> void:
		var f := d as FestivalDirector
		if f != null:
			f.need = FESTIVAL_NEED
			f.crowd_size = FESTIVAL_CROWD
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [FestivalObjective.new(), EventObjective.new("close", "Square closes", "closed")]
		return out


## Halcyon's Gaze in a Tier 5 mission (spec §4): a GazeObjective after its own objectives, in the mission and in each act. It
## waits while the director has no Gaze; the night's Descent gives one to a director that keeps none.
static func _gaze(m: MissionDef) -> void:
	m.make_objectives = _with_gaze(m.make_objectives)
	for a: ActDef in m.acts:
		a.make_objectives = _with_gaze(a.make_objectives)
		if a.make_act_objectives.is_valid():
			a.make_act_objectives = _with_gaze_for_night(a.make_act_objectives)


static func _with_gaze(make: Callable) -> Callable:
	return func() -> Array[Objective]:
		var out: Array[Objective] = []
		if make.is_valid():
			out.assign(make.call())
		out.append(GazeObjective.new())
		return out


static func _with_gaze_for_night(make: Callable) -> Callable:
	return func(n: NightState) -> Array[Objective]:
		var out: Array[Objective] = []
		out.assign(make.call(n))
		out.append(GazeObjective.new())
		return out
```

- [ ] **Step 8: The Festival's hint.**
  - In `src/game/mission/mission_hints.gd`: `"festival": "Break the festival: kill or scatter enough of its crowd (gold) before the guard closes the square.",`
  - Make the same text the `festival` row of `tests/test_mission_hints.gd`'s `SPEC`.
  - The board's Festival needs 80, The Long Night's 50; the objective row shows the count.

- [ ] **Step 9: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`, the count up by about 25.

- [ ] **Step 10: The references.** Every stretch off the board is 1.
  - Run Broken Lanterns (`424350965`), the Vigil Flame (`won=false reason=gaze`), the Feast (won festival), Mira's House and `--scenario=warning --case=none`.
  - Expected: identical to Global Constraints, and to Task 1's recorded values for Mira's House and the Warning.

- [ ] **Step 11: FLOW.** Run FLOW. Expected: `checks=91 failures=0`.

- [ ] **Step 12: Commit.**

```bash
git add src/game/descend/tier_book.gd src/game/mission/event_objective.gd src/game/mission/objective.gd src/game/mission/event_timeline.gd src/game/mission/mission_def.gd src/game/mission/act_def.gd src/game/response_profile.gd src/game/mission/mission_director.gd src/game/mission/miras_house_director.gd src/game/mission/broken_lanterns_director.gd src/game/mission/festival_director.gd src/game/mission/procession_director.gd src/game/mission/vigil_flame_director.gd src/game/mission/judgement_director.gd src/game/mission.gd src/game/mission/mission_hints.gd tests/test_board_missions.gd tests/test_mission_hints.gd tests/run_all.gd
git commit -m "feat: board versions of the ★ missions -- tier clock, readiness floor, budget, stretched timelines, the Festival's close (v0.11 M1)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: The Warning's three stars

**Files:**
- Create: `src/game/mission/starfall_director.gd`, `src/game/mission/stars_objective.gd`, `tests/test_starfall.gd`
- Modify: `src/game/mission/warning_director.gd` (`post`, `post_name`; `_begin()`, `_omen()`)
- Modify: `src/game/descend/tier_book.gd` (`board()`'s match, `_warning()`)
- Modify: `src/game/mission/mission_hints.gd` (`warning.waiting`), `tests/test_mission_hints.gd`, `tests/run_all.gd`

**Interfaces:**
- Consumes:
  - `WarningDirector` (`OMEN_AT`, `GATE_SPOT`, `MARK_MESSENGER`, `warning_dead`, `omen_fallen`, `phase`, `relays`, `tags()`, `hint_phase()`, `teardown()`);
  - `TierBook.board()` (Task 3), `MapTag.place()`.
- Produces:
  - **`WarningDirector`:** `var post := GATE_SPOT`, `var post_name := "THE MAIN GATE"`.
  - **`StarfallDirector`:**
    - `const STARS`: `[seconds, post: Vector2, gate name]` ×3;
    - vars: `stars: Array[WarningDirector]`, `_clock: float`;
    - funcs: `stopped() -> int`, `running() -> WarningDirector`, `next_star() -> int`, and its `tags()`, `hint_phase()` (`"waiting"` between stars), `tour()` and `report()` (`{stopped, relays}`).
  - **`StarsObjective`:** label "Stop the warnings", reason "warning"; HUD "Warnings stopped N / 3".
  - **`TierBook.board("warning")`:** `director == StarfallDirector`, `stretch == 1.0`, objectives `[StarsObjective, BellSilentObjective, ClockObjective(false, "Dawn", "dawn")]`, `goal_label == "The warnings die"`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_starfall.gd`:

```gdscript
extends RefCounted
## v0.11 M1 the board's Warning (spec §7.2): three stars over three gates at 0:10, 1:30 and 3:00, each a WarningDirector set
## up 2 s before its star, so its watchman is appointed at its gate then; all three stopped wins, a bell rung loses; the
## stars' tags, phases and tour. The campaign's Warning keeps one star over the Main Gate.

const DT := 0.05


static func run(t) -> void:
	_stars(t)
	_bell(t)
	_forced(t)
	_single(t)


static func _world() -> Dictionary:
	var def := TierBook.board("warning")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := def.make_director().setup(rules, crowd, town, null) as StarfallDirector
	rules.director = director
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director,
		"banners": banners}


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


## The tags labelled `label`.
static func _labelled(d: MissionDirector, label: String) -> Array[MapTag]:
	var out: Array[MapTag] = []
	for m in d.tags():
		if m.label == label:
			out.append(m)
	return out


static func _stars(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	var rules: Rules = s.rules
	t.check(d.stars.size() == 3 and d.stars[0].rules == null and d.stopped() == 0 and d.hint_phase() == "",
		"three stars, none set up before its time")
	var next := _labelled(d, "NEXT STAR")
	t.check(next.size() == 1 and next[0].at == StarfallDirector.STARS[0][1] and next[0].edge, "the first star's gate is pointed at")
	var stops := d.tour()
	t.check(stops.size() == 4 and String(stops[0][1]) == "The Postern. A star falls here at 0:10."
		and String(stops[2][1]) == "The Side Gate. A star falls here at 3:00.", "the tour: the three gates, then the bellkeeper")
	t.check(rules.objectives[0].hud_text(rules) == "Warnings stopped 0 / 3", "the HUD counts them")
	d._clock = 7.95
	_run(s, 0.1)
	var first := d.stars[0]
	t.check(first.rules != null and d.stars[1].rules == null and is_instance_valid(first.watchman)
		and first.watchman.ground_pos.distance_to(StarfallDirector.STARS[0][1]) < 1.5,
		"at 0:08 the postern's watchman is appointed at his gate")
	_run(s, 2.2)
	t.check((s.banners as Array).has("A STAR FALLS OVER THE POSTERN") and first.omen_fallen, "at 0:10 its star falls")
	first.warning_dead = true
	first.phase = WarningDirector.Phase.OVER
	_run(s, DT)
	t.check(d.stopped() == 1 and not rules.finished and d.hint_phase() == "waiting" and d.running() == null,
		"one stopped: the night goes on, waiting for the next star")
	d._clock = 87.95
	_run(s, 2.3)
	t.check(d.stars[1].rules != null and (s.banners as Array).has("A STAR FALLS OVER THE MAIN GATE") and d.running() == d.stars[1],
		"at 1:30 the Main Gate's")
	d.stars[1].warning_dead = true
	d._clock = 177.95
	_run(s, 2.3)
	t.check((s.banners as Array).has("A STAR FALLS OVER THE SIDE GATE") and d.next_star() == -1, "at 3:00 the Side Gate's, the last")
	d.stars[2].warning_dead = true
	_run(s, DT)
	t.check(rules.finished and rules.won and rules.over_reason == "warning" and d.report().stopped == 3,
		"all three stopped: won (%s)" % rules.over_reason)
	_done(s)


static func _bell(t) -> void:
	var s := _world()
	(s.crowd as Crowd).bell.state = BellNetwork.State.RUNG
	_run(s, DT)
	t.check((s.rules as Rules).finished and not (s.rules as Rules).won and (s.rules as Rules).over_reason == "bell",
		"a warning reaching the bell loses the night")
	_done(s)


static func _forced(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	for w in d.stars:
		w.warning_dead = true
	d._clock = 200.0
	_run(s, DT)
	t.check(d.stars[1].rules == null and d.stars[2].rules == null and (s.rules as Rules).finished,
		"a star already stopped is never set up")
	d.teardown()
	t.check((s.crowd as Crowd).bell.hold_on_death == false, "teardown lets the bell go")
	_done(s)


static func _single(t) -> void:
	var w := WarningDirector.new()
	t.check(w.post == WarningDirector.GATE_SPOT and w.post_name == "THE MAIN GATE", "a lone Warning's star falls over the Main Gate")
	t.check(MissionBook.warning().director == WarningDirector, "and the campaign's Warning is the lone one")
	var b := TierBook.board("warning")
	var reasons := []
	for o in b.objectives():
		reasons.append(o.reason)
	t.check(b.director == StarfallDirector and b.stretch == 1.0 and reasons == ["warning", "bell", "dawn"]
		and b.goal_label == "The warnings die", "the board's: three stars, stop them all (%s)" % [reasons])
```

  - Add `"res://tests/test_starfall.gd",` at the end of `SUITES`.
  - Add the row `["warning.waiting", "That warning is dead. Watch the next star's gate (gold): its watchman runs when it falls."],` to `tests/test_mission_hints.gd`'s `SPEC`, after the `warning.bell` row.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `StarfallDirector`, `StarsObjective` or `post`.

- [ ] **Step 3: One Warning per gate.** In `src/game/mission/warning_director.gd`:
  - Add after `var gate_spot := Vector2.INF`:

```gdscript
## Where the watchman keeps his post, snapped to walkable ground in gate_spot, and the gate's name for the star's banner
## (v0.11 M1: the board's three stars fall over three gates). Set before setup(); the Main Gate's by default.
var post := GATE_SPOT
var post_name := "THE MAIN GATE"
```

  - In `_begin()`, replace its first two lines with:

```gdscript
	var free := crowd._grid.nearest_walkable(post) if crowd._grid != null else post
	gate_spot = free if free != Vector2.INF else post
```

  - In `_omen()`, replace `rules.banner.emit("A STAR FALLS OVER THE MAIN GATE")` with `rules.banner.emit("A STAR FALLS OVER %s" % post_name)`.

- [ ] **Step 4: Create `src/game/mission/starfall_director.gd`:**

```gdscript
class_name StarfallDirector
extends MissionDirector
## The Warning on the tier board (v0.11 M1, spec §7.2): three stars fall through the night, each over a gate, and each sends
## that gate's watchman running to the bellkeeper. Each star is a WarningDirector of its own -- the omen, the stare, the run,
## the relay, the unseen kill -- set up WarningDirector.OMEN_AT before its star, so its watchman is appointed then. The main
## objective (StarsObjective) is all three warnings stopped; any one reaching the bell loses the night (BellSilentObjective).
## Each later runner starts nearer the bell (spec §8): the postern, the Main Gate, then the Side Gate.

## Each star: [seconds into the night it falls, the watchman's post just inside its gate, the gate's name for the banner].
const STARS := [
	[10.0, Vector2(-5.75, 14.9), "THE POSTERN"],
	[90.0, Vector2(2.7, 14.5), "THE MAIN GATE"],
	[180.0, Vector2(14.5, 9.0), "THE SIDE GATE"],
]

## The three warnings, in the order their stars fall; each is set up when its time comes (its `rules` is null until then).
var stars: Array[WarningDirector] = []
## Seconds into the night.
var _clock := 0.0


func _begin() -> void:
	for s: Array in STARS:
		var w := WarningDirector.new()
		w.post = s[1]
		w.post_name = String(s[2])
		stars.append(w)


## Sets up each star's warning OMEN_AT before it falls -- unless it is already stopped -- and steps those set up.
func step(delta: float) -> void:
	_clock += delta
	for i in stars.size():
		var w := stars[i]
		if w.rules == null:
			if not w.warning_dead and _clock >= float(STARS[i][0]) - WarningDirector.OMEN_AT:
				w.setup(rules, crowd, town, ctx, night)
		else:
			w.step(delta)


## How many warnings have been stopped (killed unseen with their messenger).
func stopped() -> int:
	var n := 0
	for w in stars:
		n += 1 if w.warning_dead else 0
	return n


## The warning running now: the latest star set up whose warning lives; null between stars.
func running() -> WarningDirector:
	for i in range(stars.size() - 1, -1, -1):
		var w := stars[i]
		if w.rules != null and not w.warning_dead and w.phase != WarningDirector.Phase.OVER:
			return w
	return null


## The next star still to fall, by index; -1 once all have fallen (or been stopped).
func next_star() -> int:
	for i in stars.size():
		if not stars[i].omen_fallen and not stars[i].warning_dead:
			return i
	return -1


## The tags (v0.11 M1): every set-up warning's own (WarningDirector.tags()), the latest first; and the next star's gate,
## pointed at from the edge, until it falls.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for i in range(stars.size() - 1, -1, -1):
		if stars[i].rules != null:
			out.append_array(stars[i].tags())
	var next := next_star()
	if next >= 0:
		out.append(MapTag.place(STARS[next][1], WarningDirector.MARK_MESSENGER, "NEXT STAR", 0.0, true))
	return out


## The hint's phase (v0.11 M1): the running warning's ("relay", "bell" or its own ""), else "waiting" between stars.
func hint_phase() -> String:
	var w := running()
	if w != null:
		return w.hint_phase()
	return "waiting" if stopped() > 0 and next_star() >= 0 else ""


## The tour (v0.11 M1): the three gates the stars fall over, then the bellkeeper.
func tour() -> Array:
	var out := []
	for s: Array in STARS:
		out.append([_walkable(s[1]), "%s. A star falls here at %s." % [String(s[2]).capitalize(), UiTheme.clock(float(s[0]))]])
	var bell := crowd.bell
	if bell != null and _alive(bell.keeper):
		out.append([bell.keeper.ground_pos, "The bellkeeper. Warned, he rings the bell, and you lose."])
	return out


## The results' report (v0.11 M1): the warnings stopped, and the relays all three made.
func report() -> Dictionary:
	var relays := 0
	for w in stars:
		relays += w.relays
	return {"stopped": stopped(), "relays": relays}


func teardown() -> void:
	for w in stars:
		if w.rules != null:
			w.teardown()
```

- [ ] **Step 5: Create `src/game/mission/stars_objective.gd`:**

```gdscript
class_name StarsObjective
extends Objective
## The board's Warning (v0.11 M1, spec §7.2): every one of its three warnings stopped (StarfallDirector).


func _init() -> void:
	label = "Stop the warnings"
	reason = "warning"


func check(rules: Rules) -> Status:
	var d := rules.director as StarfallDirector
	return Status.DONE if d != null and not d.stars.is_empty() and d.stopped() >= d.stars.size() else Status.PENDING


func hud_text(rules: Rules) -> String:
	var d := rules.director as StarfallDirector
	return "Warnings stopped %d / %d" % [d.stopped() if d != null else 0, StarfallDirector.STARS.size()]
```

- [ ] **Step 6: The board's Warning.**
  - In `src/game/descend/tier_book.gd` `board()`'s `match id:`, add a branch before `"festival":`:

```gdscript
		"warning":
			_warning(m)
```

  - Add after `_festival()`:

```gdscript
## The board's Warning (spec §7.2): three stars, three runners (StarfallDirector), all three to stop. No stretch: the stars
## keep the spec's own times.
static func _warning(m: MissionDef) -> void:
	m.director = StarfallDirector
	m.stretch = 1.0
	m.brief = PackedStringArray(["Three stars fall through the night.", "Each sends a runner to wake the bell."])
	m.goal = "Stop all three warnings before the bell tolls"
	m.goal_label = "The warnings die"
	m.lose = "The bell tolls, or dawn comes with a warning alive"
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [StarsObjective.new(), BellSilentObjective.new(), ClockObjective.new(false, "Dawn", "dawn")]
		return out
```

  - In `src/game/mission/mission_hints.gd` `LINES`, add after `"warning.bell": WARNING_BELL,`:

```gdscript
	"warning.waiting": "That warning is dead. Watch the next star's gate (gold): its watchman runs when it falls.",
```

- [ ] **Step 7: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`, the count up by about 16.

- [ ] **Step 8: The references.** Run the five `--scenario=warning` cases. Expected: identical to Task 1's recorded values: the lone Warning's post and banner are as before.

- [ ] **Step 9: Commit.**

```bash
git add src/game/mission/starfall_director.gd src/game/mission/stars_objective.gd src/game/mission/warning_director.gd src/game/descend/tier_book.gd src/game/mission/mission_hints.gd tests/test_starfall.gd tests/test_mission_hints.gd tests/run_all.gd
git commit -m "feat: the board's Warning -- three stars over three gates, all three to stop (v0.11 M1)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: The main objective held: `Rules` and the `Descent`

**Files:**
- Create: `src/game/descend/descent.gd`, `tests/test_descent.gd`
- Modify: `src/game/rules.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: `TierBook` (`believers()`, `GAZE_TIER`, `GAZE_SHARE`), `Objective.deadline` (Task 3), `GazeMeter`, `StarfallDirector` (Task 4, in tests).
- Produces:
  - **`Rules`:**
    - `signal main_won`, `const MAIN_BANNER := "THE NIGHT IS YOURS"`;
    - vars: `descent: Descent`, `main_done: bool`, `main_time: float`, `ascended: bool`, `caught: String`, `last_cast: Vector2` (INF before any);
    - funcs: `ascend() -> bool`, `elapsed() -> float`.
  - **`Descent`:**
    - consts: `MAIN_REWARD := 10`, `LOST: Dictionary`, `LOST_DAWN := "lost: dawn came"`, `LOST_ANY := "lost: the night was lost"`, `DAWNS`;
    - inner class `TierGaze extends GazeMeter`;
    - vars: `def: MissionDef`, `tier: int`, `wish_seed: int`, `gaze: GazeMeter`;
    - funcs:
      - `static seed_for(night: int, id: String) -> int`, `setup(def: MissionDef, seed: int) -> Descent`, `holds(m: MissionDef) -> bool`;
      - `attach(rules: Rules, director: MissionDirector) -> void`, `next_act(rules: Rules) -> void`, `step(rules: Rules, delta: float) -> void`, `release() -> void`;
      - `reward(base: int) -> int`, `main_reward() -> int`, `earned(rules: Rules) -> int`, `lost_text(rules: Rules) -> String`;
      - `report(rules: Rules) -> Dictionary`: `{"descend": {tier, main, main_time, main_reward, ascended, caught, wishes: [], lost_text, earned, kept}}`. Task 6 fills `wishes` and `kept`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_descent.gd`:

```gdscript
extends RefCounted
## v0.11 M1 the main objective held (spec §6): on the board the first DONE holds the night -- THE NIGHT IS YOURS, the clock
## running -- until the god ascends (won) or is caught (won, the catch named: the bell, the Gaze, dawn); a deadline and the
## main objective itself never catch it; off the board the night ends at once, as before. The Descent: what the night earns,
## the lost wishes' words, the seed, The Long Night's acts (review focus 5) and Tier 5's Gaze.

const DT := 0.05


## The test's own objectives: one done at once, and one that fails when told to (a deadline or not).
class Done extends Objective:
	func _init() -> void:
		label = "Done"
		reason = "done"

	func check(_rules: Rules) -> Status:
		return Status.DONE


class Fails extends Objective:
	var on := false

	func _init(is_deadline := false) -> void:
		reason = "fails"
		deadline = is_deadline

	func check(_rules: Rules) -> Status:
		return Status.FAILED if on else Status.PENDING


static func run(t) -> void:
	_held(t)
	_caught(t)
	_deadline(t)
	_acts(t)
	_tier_gaze(t)
	_seed(t)


## A world for `def` with its director (made by the def) and, unless `board` is false, a Descent attached.
static func _world(def: MissionDef, board := true) -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var made := def.make_director()
	var director: MissionDirector = made.setup(rules, crowd, town, null) if made != null else null
	rules.director = director
	var descent: Descent = null
	if board:
		descent = Descent.new().setup(def, 7)
		descent.attach(rules, director)
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director,
		"descent": descent, "banners": banners}


static func _done(s: Dictionary) -> void:
	if s.descent != null:
		(s.descent as Descent).release()
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


## The board's Warning, its three warnings stopped: its main objective done.
static func _stop_all(s: Dictionary) -> void:
	for w in (s.d as StarfallDirector).stars:
		w.warning_dead = true


## A mission of the test's own objectives, `extra` after Done.
static func _test_def(extra: Array) -> MissionDef:
	var m := MissionDef.new()
	m.id = "test"
	m.clock = 60.0
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [Done.new()]
		for o in extra:
			out.append(o)
		return out
	return m


static func _held(t) -> void:
	var s := _world(TierBook.board("warning"))
	var rules: Rules = s.rules
	var d: Descent = s.descent
	var won := [0]
	rules.main_won.connect(func() -> void: won[0] += 1)
	t.check(not rules.ascend() and not rules.main_done, "nothing to ascend from before the main objective (review focus 4)")
	t.check(d.earned(rules) == 0 and d.lost_text(rules) == Descent.LOST_ANY, "nothing earned yet")
	_stop_all(s)
	_run(s, DT)
	t.check(rules.main_done and not rules.finished and won[0] == 1 and (s.banners as Array).has(Rules.MAIN_BANNER)
		and is_equal_approx(rules.main_time, DT), "the warnings stopped: THE NIGHT IS YOURS, and the night held open")
	var clock := rules.time_left
	_run(s, 1.0)
	t.check(rules.time_left < clock and not rules.finished and won[0] == 1, "the clock keeps running")
	t.check(d.earned(rules) == 10 and d.main_reward() == 10, "the main objective's 10 believers, at Tier 1")
	t.check(rules.ascend() and rules.finished and rules.won and rules.ascended and rules.over_reason == "warning"
		and rules.caught == "", "ascending ends it, won")
	t.check(not rules.ascend(), "and cannot be done twice (review focus 4)")
	var rep: Dictionary = d.report(rules).descend
	t.check(bool(rep.main) and bool(rep.ascended) and int(rep.earned) == 10 and String(rep.lost_text) == ""
		and int(rep.tier) == 1 and is_equal_approx(float(rep.main_time), DT), "the night's report (%s)" % [rep])
	_done(s)


static func _caught(t) -> void:
	var s := _world(TierBook.board("warning"))
	var rules: Rules = s.rules
	_stop_all(s)
	_run(s, DT)
	(s.crowd as Crowd).bell.state = BellNetwork.State.RUNG
	_run(s, DT)
	t.check(rules.finished and rules.won and not rules.ascended and rules.caught == "bell" and rules.over_reason == "warning",
		"the bell after the main objective: caught, the main win standing")
	t.check((s.descent as Descent).earned(rules) == 10 and (s.descent as Descent).lost_text(rules) == "lost: the bell tolled",
		"its believers banked, the wishes lost to the bell")
	_done(s)

	var s2 := _world(TierBook.board("warning"))
	_stop_all(s2)
	_run(s2, DT)
	(s2.rules as Rules).time_left = 0.01
	_run(s2, DT)
	t.check((s2.rules as Rules).finished and (s2.rules as Rules).won and (s2.rules as Rules).caught == "dawn"
		and (s2.descent as Descent).lost_text(s2.rules) == Descent.LOST_DAWN, "dawn after the main objective: caught by dawn")
	_done(s2)

	var s3 := _world(TierBook.board("warning"))
	(s3.crowd as Crowd).bell.state = BellNetwork.State.RUNG
	_run(s3, DT)
	t.check((s3.rules as Rules).finished and not (s3.rules as Rules).won and not (s3.rules as Rules).main_done
		and (s3.descent as Descent).earned(s3.rules) == 0, "a loss before the main objective earns nothing")
	_done(s3)


static func _deadline(t) -> void:
	var s := _world(_test_def([Fails.new(true), Fails.new(false)]))
	var rules: Rules = s.rules
	_run(s, DT)
	t.check(rules.main_done and not rules.finished, "the test's main objective holds the night")
	(rules.objectives[1] as Fails).on = true
	_run(s, DT)
	t.check(not rules.finished, "a deadline failing after the main objective does not catch it")
	(rules.objectives[2] as Fails).on = true
	_run(s, DT)
	t.check(rules.finished and rules.won and rules.caught == "fails", "any other failing does")
	_done(s)

	var off := _world(_test_def([]), false)
	_run(off, DT)
	t.check((off.rules as Rules).finished and (off.rules as Rules).won and not (off.rules as Rules).main_done,
		"off the board the first DONE ends the mission at once, as before")
	_done(off)


static func _acts(t) -> void:
	var ln := TierBook.board("long_night")
	var d := Descent.new().setup(ln, 1)
	t.check(not d.holds(ln.act("omen")) and not d.holds(ln.act("festival")) and d.holds(ln.act("judgement"))
		and d.holds(TierBook.board("warning")), "a night holds only in its last act (review focus 5)")
	t.check(d.tier == 5 and d.main_reward() == 30 and Descent.new().setup(TierBook.board("miras_house"), 1).main_reward() == 15,
		"the main objective pays 10 at the tier's multiplier")


static func _tier_gaze(t) -> void:
	var s := _world(TierBook.board("last_judgement"))
	var rules: Rules = s.rules
	var d: Descent = s.descent
	t.check(rules.director.gaze != null and rules.director.gaze == d.gaze and d.gaze is Descent.TierGaze,
		"a Tier 5 director that keeps no Gaze gets the night's")
	var crowd: Crowd = s.crowd
	var victim: Person = null
	var witness: Person = null
	for p in crowd.citizens:
		if MissionDirector._alive(p) and not p.inside:
			if victim == null:
				victim = p
			elif witness == null:
				witness = p
	witness.ground_pos = victim.ground_pos + Vector2(1.0, 0.0)
	(s.field as EnemyField).kill(victim, &"doom")
	_run(s, DT)
	t.near(d.gaze.value, GazeMeter.SEEN_DEATH * TierBook.GAZE_SHARE, 0.001, "a seen death adds 0.5 at Tier 5")
	var other := MissionDirector.new()
	d.attach(rules, other)
	t.check(other.gaze == d.gaze, "the next act's director shares the night's Gaze (review focus 5)")
	d.gaze.fill()
	_run(s, DT)
	t.check(rules.finished and not rules.won and rules.over_reason == "gaze" and d.lost_text(rules) == "lost: Halcyon saw you",
		"a full Gaze loses the night")
	_done(s)
	var low := _world(TierBook.board("procession"))
	t.check((low.d as MissionDirector).gaze == null and (low.descent as Descent).gaze == null, "below Tier 5 no Gaze is added")
	_done(low)


static func _seed(t) -> void:
	t.check(Descent.seed_for(3, "warning") == Descent.seed_for(3, "warning") and Descent.seed_for(3, "warning") != Descent.seed_for(4, "warning")
		and Descent.seed_for(3, "warning") != Descent.seed_for(3, "festival"),
		"the same night of the same mission draws alike; a counted night redraws (review focus 3)")
	var d := Descent.new().setup(TierBook.board("long_night"), 1)
	var def := _test_def([])
	var s := _world(def, false)
	(s.rules as Rules)._elapsed = 70.0
	d.next_act(s.rules)
	(s.rules as Rules).main_done = true
	(s.rules as Rules).main_time = 30.0
	t.check(is_equal_approx(float(d.report(s.rules).descend.main_time), 100.0), "a night's time counts its earlier acts")
	_done(s)
```

  - Add `"res://tests/test_descent.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `Descent`, `main_done` or `main_won`.

- [ ] **Step 3: Create `src/game/descend/descent.gd`:**

```gdscript
class_name Descent
extends RefCounted
## One night on the tier board (v0.11 M1, spec §4-§6): its tier, Halcyon's Gaze at Tier 5 for a director that keeps none,
## the wishes heard at the descent (Task 6), and what the night earns. Mission makes one per board night and hands it to
## each act's Rules (attach()), which step it every frame before the objectives are checked and hold the night open once
## its main objective is done.

## The main objective's believers before the tier's multiplier (spec §4).
const MAIN_REWARD := 10
## Granted wishes lost on a night not ascended (spec §6), by the reason it ended; any clock's end is dawn's.
const LOST := {"gaze": "lost: Halcyon saw you", "bell": "lost: the bell tolled", "escapes": "lost: the people escaped"}
const LOST_DAWN := "lost: dawn came"
const LOST_ANY := "lost: the night was lost"
## The reasons that are a clock's end: dawn, Last Judgement's timeout, the Vigil Flame's, Broken Lanterns', the tide, Mira's
## too few.
const DAWNS := ["dawn", "timeout", "late", "relit", "tide", "few"]


## Halcyon's Gaze at Tier 5 (spec §4): a seen death adds TierBook.GAZE_SHARE of GazeMeter.SEEN_DEATH.
class TierGaze extends GazeMeter:
	func seen_death() -> void:
		add(GazeMeter.SEEN_DEATH * TierBook.GAZE_SHARE)


var def: MissionDef
var tier := 1
## The seed the wishes are drawn from (seed_for()).
var wish_seed := 0
## Tier 5's Gaze, shared by every act of the night; null below TierBook.GAZE_TIER.
var gaze: GazeMeter
## Seconds the night's earlier acts took (The Long Night), for the time to the main objective.
var _before := 0.0
var _crowd: Crowd


## The seed a board night's wishes are drawn from (spec §5.1): the nights played and the mission, so a restart -- or a night
## abandoned and begun again -- hears the same wishes, and a counted night redraws.
static func seed_for(night: int, id: String) -> int:
	return hash([night, id])


func setup(p_def: MissionDef, p_seed: int) -> Descent:
	def = p_def
	tier = maxi(p_def.tier, 1)
	wish_seed = p_seed
	return self


## `m` -- the mission, or the act being played -- holds the win (spec §6): a single mission does; a night only in its last act.
func holds(m: MissionDef) -> bool:
	return not (m is ActDef) or (m as ActDef).is_last()


## An act begins (Mission._build_act()): its Rules step this night, and at Tier 5 a director with no Gaze of its own gets
## the night's -- one Gaze for every act.
func attach(rules: Rules, director: MissionDirector) -> void:
	rules.descent = self
	_crowd = rules.crowd()
	if tier >= TierBook.GAZE_TIER and director != null and (director.gaze == null or director.gaze == gaze):
		if gaze == null:
			gaze = TierGaze.new()
			_crowd._field.enemy_killed.connect(_on_killed)
		director.gaze = gaze


## An act is over and another follows (The Long Night): its seconds count toward the night's time.
func next_act(rules: Rules) -> void:
	_before += rules.elapsed()


## One frame of the night, from Rules.advance(): Tier 5's Gaze judges the deaths noted.
func step(_rules: Rules, _delta: float) -> void:
	if gaze is TierGaze and _crowd != null:
		gaze.judge_deaths(_crowd)


func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	if gaze != null:
		gaze.note_death(e.ground_pos)


## Lets go of the world's signals (Mission.start() before a fresh night).
func release() -> void:
	if is_instance_valid(_crowd) and _crowd._field != null and _crowd._field.enemy_killed.is_connected(_on_killed):
		_crowd._field.enemy_killed.disconnect(_on_killed)


## A reward at the night's multiplier (spec §4).
func reward(base: int) -> int:
	return TierBook.believers(base, tier)


func main_reward() -> int:
	return reward(MAIN_REWARD)


## What the night banks (spec §6): nothing before the main objective; its believers once it is done; and, ascended, every
## granted wish's too (Task 6).
func earned(rules: Rules) -> int:
	return main_reward() if rules.main_done else 0


## Why granted wishes are lost (spec §6), from how the night ended; "" for an ascent.
func lost_text(rules: Rules) -> String:
	if rules.ascended:
		return ""
	var why := rules.caught if rules.main_done else rules.over_reason
	if why in DAWNS:
		return LOST_DAWN
	return String(LOST.get(why, LOST_ANY))


## The night's report for the results and the save (spec §6), merged into the result by Mission.
func report(rules: Rules) -> Dictionary:
	return {"descend": {"tier": tier, "main": rules.main_done, "main_time": _before + rules.main_time if rules.main_done else 0.0,
		"main_reward": main_reward(), "ascended": rules.ascended, "caught": rules.caught, "wishes": [],
		"lost_text": lost_text(rules), "earned": earned(rules), "kept": 0}}
```

- [ ] **Step 4: `Rules` holds the night.** In `src/game/rules.gd`:
  - Add after `signal over(...)`:

```gdscript
## A board night's main objective is done (v0.11 M1, spec §6): the night goes on -- the clock running, every way of losing
## still there -- until the god ascends or is caught.
signal main_won
```

  - Add after `const WARD_GONE := 1000.0`:

```gdscript
## The banner when a board night's main objective is done (v0.11 M1, spec §6).
const MAIN_BANNER := "THE NIGHT IS YOURS"
```

  - Add after `var director: MissionDirector`:

```gdscript
## The board's night (v0.11 M1): its Tier 5 Gaze, its wishes, and whether this act holds the win (Descent.holds()); null off
## the board.
var descent: Descent
## The main objective is done (v0.11 M1, spec §6), and the seconds into the act it was.
var main_done := false
var main_time := 0.0
## The god ascended (spec §6); or, caught after the main objective, why the night ended ("dawn", "bell", "gaze", ...).
var ascended := false
var caught := ""
## Where the last cast landed (v0.11 M1: the ascent rises over it); Vector2.INF before any.
var last_cast := Vector2.INF
## The objective that did the main objective, while the night is held.
var _main: Objective
```

  - In `advance()`, replace `if director != null: director.step(delta)` and the `_check_end()` after it with:

```gdscript
	if director != null:
		director.step(delta)
	if descent != null:
		descent.step(self, delta)
	_check_end()
```

  - In `cast()`, add `last_cast = ground` on the line before `cast_made.emit(slot, String(p.key), ground)`.
  - Replace `_check_end()` and its comment with:

```gdscript
## The mission's primary objectives decide it, in their order (v0.08): the first DONE wins, the first FAILED loses.
## Last Judgement lists the Citadel first, so a city that falls on the last tick of the clock still counts. On the tier
## board (v0.11 M1, spec §6) the first DONE holds the night instead (_hold()), and from then on _check_caught() decides.
func _check_end() -> void:
	if finished:
		return
	if main_done:
		_check_caught()
		return
	for o in objectives:
		match o.check(self):
			Objective.Status.DONE:
				if descent != null and descent.holds(mission):
					_hold(o)
					return
				_finish(true, o.reason)
				return
			Objective.Status.FAILED:
				_finish(false, o.reason)
				return


## A board night's main objective is done (v0.11 M1, spec §6): its banner, and the night held open for the wishes.
func _hold(o: Objective) -> void:
	main_done = true
	main_time = _elapsed
	_main = o
	banner.emit(MAIN_BANNER)
	main_won.emit()


## After the main objective (spec §6): dawn, or any primary objective failing but the main one and a deadline on it, ends
## the night, the main win standing.
func _check_caught() -> void:
	if time_left <= 0.0:
		_catch("dawn")
		return
	for o in objectives:
		if o == _main or o.deadline:
			continue
		if o.check(self) == Objective.Status.FAILED:
			_catch(o.reason)
			return


func _catch(why: String) -> void:
	caught = why
	_finish(true, _main.reason)


## The god ascends (v0.11 M1, spec §6): a held night ends at once, won. False when there is nothing to ascend from.
func ascend() -> bool:
	if finished or not main_done:
		return false
	ascended = true
	_finish(true, _main.reason)
	return true


## Seconds since the act started (v0.11 M1: a board night's time to its main objective).
func elapsed() -> float:
	return _elapsed
```

  - With `descent` null, `_check_end()` takes the loop exactly as before, so every mission off the board ends as it did.

- [ ] **Step 5: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`, the count up by about 30.

- [ ] **Step 6: The references.** Run calm `--seconds=60`, Broken Lanterns, Mira's House and `--scenario=warning --case=none`. Expected: identical (to Task 1's values for the last two).

- [ ] **Step 7: FLOW.** Run FLOW. Expected: `checks=91 failures=0`.

- [ ] **Step 8: Commit.**

```bash
git add src/game/descend/descent.gd src/game/rules.gd tests/test_descent.gd tests/run_all.gd
git commit -m "feat: a board night holds after its main objective -- ascend or be caught; the Descent and Tier 5's Gaze (v0.11 M1)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Wishes I: the pool, the draw, and five wishes

**Files:**
- Create: `src/game/descend/wish_def.gd`, `wish_book.gd`, `wish.gd`, `ruin_wish.gd`, `punish_wish.gd`, `sign_wish.gd`, `tests/test_wishes.gd`
- Modify: `src/game/descend/descent.gd` (wishes heard, stepped, engaged, reported; tags)
- Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: `Descent` (Task 5), `MapTag`, `MissionDirector._alive()`, `Crowd.nearest_witness()`, `Crowd._doomed`.
- Produces:
  - **`WishDef`:**
    - vars: `id`, `text`, `kind`, `reward: int`, `runner: GDScript`, `params: Dictionary`, `clashes: PackedStringArray`;
    - funcs: `static make(id, text, kind, reward, runner, params := {}, clashes := PackedStringArray()) -> WishDef`, `instance() -> Wish`.
  - **`WishBook`:** `static pool() -> Array[WishDef]`, `static draw(defs: Array[WishDef], count: int, tags: PackedStringArray, crowd: Crowd, town: Town, rng: RandomNumberGenerator) -> Array[Wish]`, `static clashes(d: WishDef, tags: PackedStringArray) -> bool`.
  - **`Wish extends Objective`:**
    - consts: `COLOR := Color("8fb8ff")`, `WISHER_LABEL := "WISH"`, `UNANSWERED`, `NOT_LAY`;
    - vars: `def`, `reward`, `wisher: Person`, `status: Status`;
    - funcs:
      - `static state_name(s: Status) -> String`, `static lay(crowd, taken) -> Array[Person]`, `static pick_lay(crowd, rng, taken) -> Person`;
      - virtuals: `choose(crowd, town, rng, taken: Array) -> bool`, `step(rules, delta)`, `on_cast(key, at)`, `_act(rules) -> Status`, `_target_tags() -> Array[MapTag]`, `timed() -> bool`, `waiting() -> bool`, `engage() -> bool`, `release()`;
      - `check(rules) -> Status` (latched), `grant()`, `hud_text(rules)`, `tags() -> Array[MapTag]`.
  - **`RuinWish`:** `target: Structure`, `static fits(s: Structure, role: String) -> bool`. **`PunishWish`:** `target: Person`. **`SignWish`:** `const REACH := 4.0`.
  - **`Descent`:**
    - consts: `GRANTED_BANNER`, `FAILED_BANNER`;
    - vars: `wishes: Array[Wish]`;
    - funcs: `hear(crowd: Crowd, town: Town) -> void`, `engage(i: int) -> bool`, `tags() -> Array[MapTag]`;
    - `earned()` and `report()` now count the wishes.

- [ ] **Step 1: Write the failing test.** Create `tests/test_wishes.gd`:

```gdscript
extends RefCounted
## v0.11 M1 wishes (spec §5): the pool's words and rewards; the draw -- seeded (a restart hears the same, review focus 3),
## filtered by clashes and by what the town can give, never two sharing a person; five wishes' acts; a wisher dying fails a
## wish, a granted one makes them a Believer (review focus 2); and the Descent hearing, stepping, banking and losing them.

const DT := 0.05


static func run(t) -> void:
	_pool(t)
	_draw(t)
	_ruin(t)
	_punish(t)
	_sign(t)
	_wisher(t)
	_descent(t)


static func _world() -> Dictionary:
	var def := TierBook.board("warning")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := def.make_director().setup(rules, crowd, town, null)
	rules.director = director
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	return {"def": def, "env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules,
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


static func _rng(n: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = n
	return r


static func _def(id: String) -> WishDef:
	for d in WishBook.pool():
		if d.id == id:
			return d
	return null


## A wish of the pool's `id`, given its people from the world (with `seed`); null when the town cannot give them.
static func _wish(s: Dictionary, id: String, seed_n := 3) -> Wish:
	var w := _def(id).instance()
	return w if w.choose(s.crowd, s.town, _rng(seed_n), []) else null


static func _ids(wishes: Array[Wish]) -> Array:
	var out := []
	for w in wishes:
		out.append(w.def.id)
	return out


static func _release(wishes: Array[Wish]) -> void:
	for w in wishes:
		w.release()


## Everyone but `keep` within `reach` of `at` moved well away, so nobody but `keep` can witness there.
static func _clear_round(s: Dictionary, at: Vector2, reach: float, keep: Array) -> void:
	var crowd: Crowd = s.crowd
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and not keep.has(p) and p.ground_pos.distance_to(at) <= reach:
				p.ground_pos = at + Vector2(reach + 6.0, reach + 6.0)


static func _pool(t) -> void:
	var rows := {}
	for d in WishBook.pool():
		rows[d.id] = [d.text, d.kind, d.reward]
	t.check(rows.get("moneylender") == ["Burn the moneylender's house", "ruin", 10]
		and rows.get("watchtower") == ["Bring down the watchtower", "ruin", 15]
		and rows.get("tax_collector") == ["Strike down the cruel tax collector", "punish", 10]
		and rows.get("informer") == ["Kill the informer, unseen", "punish", 15]
		and rows.get("sign") == ["Show me a sign", "sign", 5], "the spec's wishes, word for word (%s)" % [rows])
	t.check(Array(_def("moneylender").clashes) == ["spares_houses"] and _def("watchtower").clashes.is_empty(),
		"the moneylender's house clashes with spares_houses")
	var w := _def("sign").instance()
	t.check(w is SignWish and w.def.id == "sign" and w.status == Objective.Status.PENDING and not w.timed() and not w.engage(),
		"a fresh wish of its kind, open, not timed")
	t.check(Wish.state_name(Objective.Status.PENDING) == "open" and Wish.state_name(Objective.Status.DONE) == "granted"
		and Wish.state_name(Objective.Status.FAILED) == "failed", "its states' names")


static func _draw(t) -> void:
	var s := _world()
	var a := WishBook.draw(WishBook.pool(), 2, PackedStringArray(), s.crowd, s.town, _rng(11))
	var b := WishBook.draw(WishBook.pool(), 2, PackedStringArray(), s.crowd, s.town, _rng(11))
	t.check(a.size() == 2 and _ids(a) == _ids(b) and a[0].wisher == b[0].wisher and a[1].wisher == b[1].wisher,
		"the same seed hears the same wishes, from the same wishers (%s)" % [_ids(a)])
	_release(a)
	_release(b)
	var lists := {}
	for n in range(1, 11):
		var drawn := WishBook.draw(WishBook.pool(), 2, PackedStringArray(), s.crowd, s.town, _rng(n))
		lists[str(_ids(drawn))] = true
		_release(drawn)
	t.check(lists.size() > 1, "other seeds draw otherwise (%d different draws in 10)" % lists.size())
	var clashed := false
	for n in range(1, 21):
		var drawn := WishBook.draw(WishBook.pool(), 5, PackedStringArray(["spares_houses"]), s.crowd, s.town, _rng(n))
		clashed = clashed or _ids(drawn).has("moneylender")
		_release(drawn)
	t.check(not clashed, "a wish that clashes with the mission's tags is never drawn")
	var all := WishBook.draw(WishBook.pool(), 10, PackedStringArray(), s.crowd, s.town, _rng(4))
	var people := []
	var shared := false
	for w in all:
		for p: Variant in [w.wisher, w.get("target")]:
			if p != null:
				shared = shared or people.has(p)
				people.append(p)
	t.check(all.size() == WishBook.pool().size() and not shared, "asked for more than there are, it offers what it can; none share")
	_release(all)
	for st: Structure in (s.town as Town)._built:
		if RuinWish.fits(st, "house"):
			st.destroyed = true
	var no_house := WishBook.draw(WishBook.pool(), 10, PackedStringArray(), s.crowd, s.town, _rng(4))
	t.check(not _ids(no_house).has("moneylender") and _ids(no_house).has("watchtower"), "no house standing: no moneylender")
	_release(no_house)
	for p in (s.crowd as Crowd).citizens:
		if is_instance_valid(p) and p.profile != null:
			p.profile.faith = CitizenProfile.Faith.FAITHFUL
	t.check(WishBook.draw(WishBook.pool(), 3, PackedStringArray(), s.crowd, s.town, _rng(4)).is_empty(),
		"nobody to wish: no wishes, and no error")
	_done(s)


static func _ruin(t) -> void:
	var s := _world()
	var w := _wish(s, "moneylender") as RuinWish
	t.check(w != null and RuinWish.fits(w.target, "house") and w.target.art_tag in [&"", &"townhouse"], "the moneylender's is a dwelling")
	var tags := w.tags()
	t.check(tags.size() == 2 and tags[0].label == "MONEYLENDER" and tags[0].color == Wish.COLOR and tags[0].at == w.target.center()
		and tags[1].label == Wish.WISHER_LABEL and tags[1].at == w.wisher.ground_pos, "its house and its wisher are tagged in blue")
	t.check(w.check(s.rules) == Objective.Status.PENDING and w.hud_text(s.rules) == "Burn the moneylender's house (+0)", "open")
	w.target.destroyed = true
	t.check(w.check(s.rules) == Objective.Status.DONE and w.tags().is_empty(), "destroyed: granted, its tags gone")
	w.target.destroyed = false
	t.check(w.check(s.rules) == Objective.Status.DONE, "and it stays granted")
	var tower := _wish(s, "watchtower") as RuinWish
	t.check(tower != null and tower.target.role == &"tower" and tower.target.art_tag != &"bell_tower", "the watchtower is no bell tower")
	_done(s)


static func _punish(t) -> void:
	var s := _world()
	var w := _wish(s, "tax_collector") as PunishWish
	t.check(w != null and w.target != w.wisher and w.tags()[0].label == "TAX COLLECTOR", "the tax collector, tagged")
	(s.field as EnemyField).kill(w.target, &"doom")
	w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.DONE, "struck down: granted, seen or not")
	w.release()
	var seen := _wish(s, "informer", 5) as PunishWish
	var witness: Person = null
	for p in (s.crowd as Crowd).citizens:
		if MissionDirector._alive(p) and p != seen.target and p != seen.wisher:
			witness = p
			break
	witness.ground_pos = seen.target.ground_pos + Vector2(1.0, 0.0)
	(s.field as EnemyField).kill(seen.target, &"doom")
	seen.step(s.rules, DT)
	t.check(seen.check(s.rules) == Objective.Status.FAILED, "the informer killed with a witness near: failed")
	seen.release()
	var unseen := _wish(s, "informer", 6) as PunishWish
	_clear_round(s, unseen.target.ground_pos, Crowd.DOOM_WITNESS + 0.5, [unseen.target])
	(s.field as EnemyField).kill(unseen.target, &"doom")
	unseen.step(s.rules, DT)
	t.check(unseen.check(s.rules) == Objective.Status.DONE, "killed with nobody near: granted")
	unseen.release()
	_done(s)


static func _sign(t) -> void:
	var s := _world()
	var w := _wish(s, "sign") as SignWish
	w.on_cast("doom", w.wisher.ground_pos + Vector2(SignWish.REACH + 0.5, 0.0))
	t.check(w.check(s.rules) == Objective.Status.PENDING, "a cast too far is not seen")
	w.wisher.inside = true
	w.on_cast("doom", w.wisher.ground_pos)
	t.check(w.check(s.rules) == Objective.Status.PENDING, "nor one cast while they are indoors")
	w.wisher.inside = false
	w.on_cast("doom", w.wisher.ground_pos + Vector2(SignWish.REACH - 0.1, 0.0))
	t.check(w.check(s.rules) == Objective.Status.DONE, "one within 4 is a sign: granted")
	_done(s)


static func _wisher(t) -> void:
	var s := _world()
	var w := _wish(s, "watchtower")
	(s.field as EnemyField).kill(w.wisher, &"doom")
	t.check(w.check(s.rules) == Objective.Status.FAILED and w.tags().is_empty(), "the wisher dead first: the prayer goes unanswered")
	var g := _wish(s, "sign", 9)
	g.on_cast("doom", g.wisher.ground_pos)
	g.check(s.rules)
	g.grant()
	t.check(g.wisher.profile.faith == CitizenProfile.Faith.BELIEVER, "a granted wish makes its wisher a Believer")
	_done(s)


static func _descent(t) -> void:
	var s := _world()
	var rules: Rules = s.rules
	var d := Descent.new().setup(s.def, 7)
	d.attach(rules, s.d)
	t.check(d.wishes.size() == TierBook.wishes(1) and not _ids(d.wishes).has("child"), "Tier 1 hears two (%s)" % [_ids(d.wishes)])
	var again := Descent.new().setup(s.def, 7)
	again.attach(rules, MissionDirector.new())
	t.check(_ids(again.wishes) == _ids(d.wishes), "a restart of the night hears the same wishes (review focus 3)")
	again.release()
	d.attach(rules, s.d)
	t.check(d.wishes.size() == TierBook.wishes(1), "a later act hears none again (review focus 5)")
	d.release()
	var sign := _wish(s, "sign", 9)
	sign.reward = d.reward(sign.def.reward)
	d.wishes.assign([sign])
	rules.cast_made.emit(0, "doom", sign.wisher.ground_pos)
	_run_rules(rules)
	t.check(sign.status == Objective.Status.DONE and (s.banners as Array).has(Descent.GRANTED_BANNER)
		and sign.wisher.profile.faith == CitizenProfile.Faith.BELIEVER, "a cast by the wisher grants it: its banner, a Believer")
	t.check(d.tags().is_empty(), "a granted wish is no longer tagged")
	for w in (s.d as StarfallDirector).stars:
		w.warning_dead = true
	_run_rules(rules)
	var rep: Dictionary = d.report(rules).descend
	t.check(int(rep.earned) == 10 and bool((rep.wishes as Array)[0].lost) and String(rep.lost_text) == Descent.LOST_ANY
		and int(rep.kept) == 0, "held open, the granted wish is not yet banked (%s)" % [rep])
	rules.ascend()
	rep = d.report(rules).descend
	var row: Dictionary = (rep.wishes as Array)[0]
	t.check(int(rep.earned) == 15 and int(rep.kept) == 1 and String(row.state) == "granted" and not bool(row.lost)
		and String(row.text) == "Show me a sign" and int(row.reward) == 5, "ascended: the main 10 and the sign's 5 (%s)" % [rep])
	_done(s)


static func _run_rules(rules: Rules) -> void:
	rules.advance(DT)
```

  - Add `"res://tests/test_wishes.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `WishBook`, `WishDef`, `Wish` or `RuinWish`.

- [ ] **Step 3: Create `src/game/descend/wish_def.gd`:**

```gdscript
class_name WishDef
extends RefCounted
## One wish of the pool (v0.11 M1, spec §5.3): its words on the HUD, its kind, its believers before the tier's multiplier,
## the Wish script that runs it with that script's settings, and the mission tags it is never drawn beside.

var id := ""
## "Burn the moneylender's house": the HUD's line, and the results'.
var text := ""
## "ruin", "punish", "rescue", "mercy" or "sign".
var kind := ""
var reward := 0
## A Wish script (RuinWish, PunishWish, ...), made fresh for each night the wish is heard.
var runner: GDScript
## The script's own settings: a target's role and label, "unseen", ...
var params := {}
## Mission tags (MissionDef.mission_tags) the wish is never drawn beside.
var clashes := PackedStringArray()


static func make(p_id: String, p_text: String, p_kind: String, p_reward: int, p_runner: GDScript, p_params := {},
		p_clashes := PackedStringArray()) -> WishDef:
	var d := WishDef.new()
	d.id = p_id
	d.text = p_text
	d.kind = p_kind
	d.reward = p_reward
	d.runner = p_runner
	d.params = p_params
	d.clashes = p_clashes
	return d


## A fresh Wish for one night, not yet given its people (Wish.choose()).
func instance() -> Wish:
	var w := runner.new() as Wish
	w.def = self
	return w
```

- [ ] **Step 4: Create `src/game/descend/wish_book.gd`:**

```gdscript
class_name WishBook
extends RefCounted
## The wishes a board night may hear (v0.11 M1, spec §5): the pool, and the draw. The draw is seeded, so a restart hears the
## same. It is filtered: a wish whose tags clash with the mission's, or whose targets the town cannot give, is left out, and
## a mission with too few eligible wishes offers what it can, possibly none.


## The pool at M1 (spec §5.3), in the spec's order; Task 7 adds the Rescue, Mercy and family wishes.
static func pool() -> Array[WishDef]:
	var out: Array[WishDef] = [
		WishDef.make("moneylender", "Burn the moneylender's house", "ruin", 10, RuinWish,
			{"role": "house", "label": "MONEYLENDER"}, PackedStringArray(["spares_houses"])),
		WishDef.make("watchtower", "Bring down the watchtower", "ruin", 15, RuinWish, {"role": "tower", "label": "WATCHTOWER"}),
		WishDef.make("tax_collector", "Strike down the cruel tax collector", "punish", 10, PunishWish,
			{"label": "TAX COLLECTOR", "unseen": false}),
		WishDef.make("informer", "Kill the informer, unseen", "punish", 15, PunishWish, {"label": "INFORMER", "unseen": true}),
		WishDef.make("sign", "Show me a sign", "sign", 5, SignWish),
	]
	return out


## Up to `count` wishes for a night (spec §5.1), tried in an order `rng` shuffles. A wish whose clashes meet `tags` is
## skipped, as is one whose choose() finds no targets in the town. No two share a person or a building.
static func draw(defs: Array[WishDef], count: int, tags: PackedStringArray, crowd: Crowd, town: Town,
		rng: RandomNumberGenerator) -> Array[Wish]:
	var order: Array[WishDef] = defs.duplicate()
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := order[i]
		order[i] = order[j]
		order[j] = swap
	var out: Array[Wish] = []
	var taken := []
	for d in order:
		if out.size() >= count:
			break
		if clashes(d, tags):
			continue
		var w := d.instance()
		if w.choose(crowd, town, rng, taken):
			out.append(w)
	return out


## The wish lists a tag the mission declares.
static func clashes(d: WishDef, tags: PackedStringArray) -> bool:
	for tag in d.clashes:
		if tags.has(tag):
			return true
	return false
```

- [ ] **Step 5: Create `src/game/descend/wish.gd`:**

```gdscript
class_name Wish
extends Objective
## A wish heard at a board night's descent (v0.11 M1, spec §5), run as an Objective: check() is where it stands -- PENDING,
## DONE (granted) or FAILED -- and it stays where it ends. Each has a wisher, a real citizen tagged WISH; the wisher dying
## before it is granted fails it ("Their prayer goes unanswered"). Granted, the wisher becomes a Believer. A kind's script
## chooses its targets (choose()), watches them (step(), on_cast()) and judges its act (_act()).

## The wishes' colour on the map and the HUD (spec §5.1): soft blue.
const COLOR := Color("8fb8ff")
## The wisher's tag.
const WISHER_LABEL := "WISH"
## A failed wish's words (spec §5.1).
const UNANSWERED := "Their prayer goes unanswered"
## Roles a wisher or a target never has: the town's responders and the directors' own people.
const NOT_LAY := [CitizenProfile.Role.CLERGY, CitizenProfile.Role.ENGINEER, CitizenProfile.Role.BELLKEEPER,
	CitizenProfile.Role.WATCHMAN, CitizenProfile.Role.MAYOR, CitizenProfile.Role.NOBLE]

var def: WishDef
## The believers it pays, at the night's multiplier (Descent.hear()).
var reward := 0
var wisher: Person
## Where it ended: PENDING while open.
var status := Status.PENDING
var _crowd: Crowd


## "open", "granted" or "failed", for the HUD and the results.
static func state_name(s: Status) -> String:
	match s:
		Status.DONE:
			return "granted"
		Status.FAILED:
			return "failed"
	return "open"


## Virtual: chooses the wisher and the targets from the town (spec §5.1), none of them in `taken` (each added to it); false
## when the town cannot give them, and the wish is not heard. The base takes a wisher among the lay citizens.
func choose(crowd: Crowd, _town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	_crowd = crowd
	wisher = pick_lay(crowd, rng, taken)
	return wisher != null


## Virtual: one frame of the night, while the wish is open.
func step(_rules: Rules, _delta: float) -> void:
	pass


## Virtual: a power was cast at `at` (Descent passes Rules.cast_made on).
func on_cast(_key: String, _at: Vector2) -> void:
	pass


## Virtual: where the wish's own act stands, the wisher aside.
func _act(_rules: Rules) -> Status:
	return Status.PENDING


## Where the wish stands (spec §5.2): granted the moment its act is done; failed when its act fails or its wisher dies
## first. Once ended, it stays ended.
func check(rules: Rules) -> Status:
	if status != Status.PENDING:
		return status
	var s := _act(rules)
	if s == Status.PENDING and not MissionDirector._alive(wisher):
		s = Status.FAILED
	status = s
	return status


## Granted (spec §5.2): the wisher believes.
func grant() -> void:
	if MissionDirector._alive(wisher) and wisher.profile != null:
		wisher.profile.faith = CitizenProfile.Faith.BELIEVER


## "Burn the moneylender's house (+10)".
func hud_text(_rules: Rules) -> String:
	return "%s (+%d)" % [def.text, reward]


## The map's tags while open (spec §5.1-§5.2): the act's targets first, then the wisher, WISH.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if status != Status.PENDING:
		return out
	out.append_array(_target_tags())
	if MissionDirector._alive(wisher) and not wisher.inside:
		out.append(MapTag.person(wisher.ground_pos, COLOR, WISHER_LABEL))
	return out


## Virtual: the act's targets' tags.
func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	return out


## Virtual: a timed wish (spec §5.2: the Rescue kind) waits for the player to engage it.
func timed() -> bool:
	return false


## Virtual: open and not yet engaged (a timed wish); its tag answers a click.
func waiting() -> bool:
	return false


## Virtual: the player engages it; true when it was waiting and now runs.
func engage() -> bool:
	return false


## Virtual: lets go of the world's signals.
func release() -> void:
	pass


## A lay citizen at random for a wisher or a target, added to `taken`; null when there is none.
static func pick_lay(crowd: Crowd, rng: RandomNumberGenerator, taken: Array) -> Person:
	var pool := lay(crowd, taken)
	if pool.is_empty():
		return null
	var p := pool[rng.randi_range(0, pool.size() - 1)]
	taken.append(p)
	return p


## The lay citizens not in `taken`, in the crowd's order: alive, out of doors, of no faith, of no role in NOT_LAY.
static func lay(crowd: Crowd, taken: Array) -> Array[Person]:
	var out: Array[Person] = []
	for p in crowd.citizens:
		if MissionDirector._alive(p) and not p.inside and p.profile != null and not p.profile.role in NOT_LAY \
				and p.profile.faith == CitizenProfile.Faith.NONE and not taken.has(p):
			out.append(p)
	return out
```

- [ ] **Step 6: The kinds.**
  - Create `src/game/descend/ruin_wish.gd`:

```gdscript
class_name RuinWish
extends Wish
## "Burn the moneylender's house", "Bring down the watchtower" (v0.11 M1, spec §5.3, Ruin): destroy the marked building, by
## any means. params: "role" -- "house" or "tower" (fits()) -- and "label", its tag's.

var target: Structure


func choose(crowd: Crowd, town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	var pool: Array[Structure] = []
	for s: Structure in town._built:
		if is_instance_valid(s) and not s.destroyed and not taken.has(s) and fits(s, String(def.params.get("role", ""))):
			pool.append(s)
	if pool.is_empty() or not super(crowd, town, rng, taken):
		return false
	target = pool[rng.randi_range(0, pool.size() - 1)]
	taken.append(target)
	return true


## A building of `role`: "house" a dwelling (a HOUSE-kind house with no art tag, or a townhouse: not a tavern, smithy,
## workshop or carpenter's), "tower" a tower of the walls (not the bell tower).
static func fits(s: Structure, role: String) -> bool:
	match role:
		"house":
			return s.role == &"house" and s.kind == Structure.Kind.HOUSE and s.art_tag in [&"", &"townhouse"]
		"tower":
			return s.role == &"tower" and s.art_tag != &"bell_tower"
	return false


func _act(_rules: Rules) -> Status:
	return Status.DONE if is_instance_valid(target) and target.destroyed else Status.PENDING


func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if is_instance_valid(target) and not target.destroyed:
		out.append(MapTag.place(target.center(), COLOR, String(def.params.get("label", "")), target.height, false))
	return out
```

  - Create `src/game/descend/punish_wish.gd`:

```gdscript
class_name PunishWish
extends Wish
## "Strike down the cruel tax collector", "Kill the informer, unseen" (v0.11 M1, spec §5.3, Punish): kill the marked citizen.
## params: "label", its tag's; "unseen", the kill must leave no living witness -- judged as The Warning judges
## (Crowd.nearest_witness(), once a Silent Doom's victims have all fallen) -- and a seen kill fails it. A target who leaves
## the town alive is beyond the god's reach: failed.

var target: Person
## Where the target fell, waiting to be judged; its death once judged, and whether anyone saw it.
var _fell_at := Vector2.INF
var _dead := false
var _seen := false


func choose(crowd: Crowd, town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	if not super(crowd, town, rng, taken):
		return false
	target = Wish.pick_lay(crowd, rng, taken)
	if target == null:
		return false
	crowd._field.enemy_killed.connect(_on_killed)
	return true


func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	if e == target and not _dead and _fell_at == Vector2.INF:
		_fell_at = e.ground_pos


## Judges the death once the crowd has judged its own doomed, so a cast's victims never witness each other.
func step(_rules: Rules, _delta: float) -> void:
	if _fell_at == Vector2.INF or not _crowd._doomed.is_empty():
		return
	_dead = true
	_seen = bool(def.params.get("unseen", false)) and _crowd.nearest_witness(_fell_at) != null
	_fell_at = Vector2.INF


func _act(_rules: Rules) -> Status:
	if _dead:
		return Status.FAILED if _seen else Status.DONE
	if _fell_at == Vector2.INF and not is_instance_valid(target):
		return Status.FAILED
	return Status.PENDING


func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if MissionDirector._alive(target) and not target.inside:
		out.append(MapTag.person(target.ground_pos, COLOR, String(def.params.get("label", ""))))
	return out


func release() -> void:
	if is_instance_valid(_crowd) and _crowd._field != null and _crowd._field.enemy_killed.is_connected(_on_killed):
		_crowd._field.enemy_killed.disconnect(_on_killed)
```

  - Create `src/game/descend/sign_wish.gd`:

```gdscript
class_name SignWish
extends Wish
## "Show me a sign" (v0.11 M1, spec §5.3, Sign): any power cast within REACH of the wisher while they live and can see it --
## out of doors -- grants it.

const REACH := 4.0

var _seen := false


func on_cast(_key: String, at: Vector2) -> void:
	if MissionDirector._alive(wisher) and not wisher.inside and wisher.ground_pos.distance_to(at) <= REACH:
		_seen = true


func _act(_rules: Rules) -> Status:
	return Status.DONE if _seen else Status.PENDING
```

- [ ] **Step 7: The Descent hears and keeps them.** In `src/game/descend/descent.gd`:
  - Add after `LOST_ANY`:

```gdscript
## The banners when a wish is granted, and when one fails (spec §5.1-§5.2).
const GRANTED_BANNER := "A WISH IS GRANTED"
const FAILED_BANNER := "A PRAYER GOES UNANSWERED"
```

  - Add after `var gaze: GazeMeter`:

```gdscript
## The wishes heard at the descent (spec §5), in the order drawn.
var wishes: Array[Wish] = []
## The wishes have been heard: only once a night, at its first act.
var _heard := false
```

  - Replace `attach()` with:

```gdscript
## An act begins (Mission._build_act()): its Rules step this night and pass its casts to the wishes; at Tier 5 a director
## with no Gaze of its own gets the night's, one Gaze for every act; the first act hears the wishes (spec §5.1).
func attach(rules: Rules, director: MissionDirector) -> void:
	rules.descent = self
	_crowd = rules.crowd()
	if not rules.cast_made.is_connected(_on_cast):
		rules.cast_made.connect(_on_cast)
	if tier >= TierBook.GAZE_TIER and director != null and (director.gaze == null or director.gaze == gaze):
		if gaze == null:
			gaze = TierGaze.new()
			_crowd._field.enemy_killed.connect(_on_killed)
		director.gaze = gaze
	if not _heard:
		_heard = true
		hear(rules.crowd(), rules.town())


## The town prays (spec §5.1): TierBook.wishes(tier) wishes drawn with the night's seed, filtered by the mission's tags and by
## what the town can give, each paying its believers at the tier's multiplier.
func hear(crowd: Crowd, town: Town) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = wish_seed
	wishes = WishBook.draw(WishBook.pool(), TierBook.wishes(tier), def.mission_tags, crowd, town, rng)
	for w in wishes:
		w.reward = reward(w.def.reward)
```

  - Replace `step()` with:

```gdscript
## One frame of the night, from Rules.advance(): Tier 5's Gaze judges the deaths noted, and each open wish runs and is judged
## -- granted (its wisher believes) or failed, each with its banner.
func step(rules: Rules, delta: float) -> void:
	if gaze is TierGaze and _crowd != null:
		gaze.judge_deaths(_crowd)
	for w in wishes:
		if w.status != Objective.Status.PENDING:
			continue
		w.step(rules, delta)
		match w.check(rules):
			Objective.Status.DONE:
				w.grant()
				rules.banner.emit(GRANTED_BANNER)
			Objective.Status.FAILED:
				rules.banner.emit(FAILED_BANNER)


func _on_cast(_slot: int, key: String, at: Vector2) -> void:
	for w in wishes:
		if w.status == Objective.Status.PENDING:
			w.on_cast(key, at)


## The player engages the timed wish `i` (spec §5.2: its tag clicked); true when it was waiting and now runs.
func engage(i: int) -> bool:
	return i >= 0 and i < wishes.size() and wishes[i].engage()


## The wishes' tags (spec §5.1), each open wish's in turn.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for w in wishes:
		out.append_array(w.tags())
	return out
```

  - In `release()`, add first:

```gdscript
	for w in wishes:
		w.release()
```

  - Replace `earned()` and `report()`:

```gdscript
## What the night banks (spec §6): nothing before the main objective; its believers once it is done; and, ascended, every
## granted wish's too.
func earned(rules: Rules) -> int:
	if not rules.main_done:
		return 0
	var total := main_reward()
	if rules.ascended:
		for w in wishes:
			total += w.reward if w.status == Objective.Status.DONE else 0
	return total


## The night's report for the results and the save (spec §6), merged into the result by Mission: {"descend": {tier, main,
## main_time, main_reward, ascended, caught, wishes, lost_text, earned, kept}}. Each wish is {text, reward, state, lost}.
## `lost` marks a granted wish not banked; `kept` counts the banked ones.
func report(rules: Rules) -> Dictionary:
	var lost := lost_text(rules)
	var rows := []
	var kept := 0
	for w in wishes:
		var state := Wish.state_name(w.status)
		var gone := state == "granted" and lost != ""
		kept += 1 if state == "granted" and not gone else 0
		rows.append({"text": w.def.text, "reward": w.reward, "state": state, "lost": gone})
	return {"descend": {"tier": tier, "main": rules.main_done, "main_time": _before + rules.main_time if rules.main_done else 0.0,
		"main_reward": main_reward(), "ascended": rules.ascended, "caught": rules.caught, "wishes": rows, "lost_text": lost,
		"earned": earned(rules), "kept": kept}}
```

- [ ] **Step 8: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`, the count up by about 30.

- [ ] **Step 9: Commit.**

```bash
git add src/game/descend/wish_def.gd src/game/descend/wish_book.gd src/game/descend/wish.gd src/game/descend/ruin_wish.gd src/game/descend/punish_wish.gd src/game/descend/sign_wish.gd src/game/descend/descent.gd tests/test_wishes.gd tests/run_all.gd
git commit -m "feat: wishes -- the pool, the seeded draw and its filters, Ruin, Punish and the sign (v0.11 M1)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Wishes II: the child, the brother, the family

**Files:**
- Create: `src/game/descend/rescue_wish.gd`, `mercy_wish.gd`, `family_wish.gd`, `tests/test_wish_kinds.gd`
- Modify: `src/game/descend/wish_book.gd` (`pool()`)
- Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: `Wish` (Task 6), `Crowd.off_duty()`, `Crowd.escape()`, `EnemyField.remove()`, `Person.go_duty()`, `Person.whisper()`.
- Produces:
  - **`RescueWish`:**
    - consts: `SECONDS := 45.0`, `ENGAGE_REACH := 2.0`, `GATE`, `GATE_REACH := 1.0`, `TAKE_REACH := 0.9`, `RETARGET := 0.5`;
    - vars: `child`, `soldier`, `engaged`, `dragging`, `seconds_left`;
    - `timed()`, `waiting()` and `engage()` true while it applies.
  - **`MercyWish`:** `static exits() -> Array[Vector2]`, `const EXIT_REACH := 1.5`, `target`.
  - **`FamilyWish`:** `const COUNT := 3`, `const REACH := 6.0`, `family: Array` and `shown: Array` (untyped: they may hold freed bodies).
  - `WishBook.pool()` holds all eight, in the spec's order.

- [ ] **Step 1: Write the failing test.** Create `tests/test_wish_kinds.gd`:

```gdscript
extends RefCounted
## v0.11 M1 the rest of the pool (spec §5.3): "Save my child" -- waits until engaged (a cast near the child or the soldier;
## the tag's click is the HUD's), then the soldier drags the child toward the Citadel's gate; stopped or turned within 45 s
## grants it, the child dead, the gate reached or the time out fails it (review focus 2); "Lead my brother out" -- whispered
## to a gate, he escapes; "Show yourself to my family" -- three whispered. The pool is the spec's eight.

const DT := 0.05


static func run(t) -> void:
	_pool(t)
	_rescue(t)
	_mercy(t)
	_family(t)


static func _world() -> Dictionary:
	var def := TierBook.board("vigil_flame")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules}


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


static func _def(id: String) -> WishDef:
	for d in WishBook.pool():
		if d.id == id:
			return d
	return null


static func _wish(s: Dictionary, id: String, seed_n := 3) -> Wish:
	var r := RandomNumberGenerator.new()
	r.seed = seed_n
	var w := _def(id).instance()
	return w if w.choose(s.crowd, s.town, r, []) else null


static func _arrive(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


static func _pool(t) -> void:
	var ids := []
	for d in WishBook.pool():
		ids.append(d.id)
	t.check(ids == ["moneylender", "watchtower", "tax_collector", "informer", "child", "brother", "sign", "family"],
		"the pool at M1: the spec's eight, in its order (%s)" % [ids])
	var child := _def("child")
	t.check(child.text == "Save my child" and child.kind == "rescue" and child.reward == 15 and Array(child.clashes) == ["unaware_town"]
		and _def("brother").text == "Lead my brother out" and _def("brother").reward == 10
		and _def("family").text == "Show yourself to my family" and _def("family").reward == 10, "their words and rewards")
	var s := _world()
	var drawn := false
	for n in range(1, 21):
		var r := RandomNumberGenerator.new()
		r.seed = n
		var got := WishBook.draw(WishBook.pool(), 8, PackedStringArray(["unaware_town"]), s.crowd, s.town, r)
		for w in got:
			drawn = drawn or w.def.id == "child"
			w.release()
	t.check(not drawn, "Save my child is never heard in an unaware town")
	_done(s)


static func _rescue(t) -> void:
	var s := _world()
	var w := _wish(s, "child") as RescueWish
	t.check(w != null and w.child.profile.family == w.wisher.profile.family and w.child != w.wisher
		and w.soldier.soldier and w.soldier.corps == Person.Corps.NONE, "the child of the wisher's household, and a soldier")
	t.check(w.timed() and w.waiting() and not w.engaged and w.check(s.rules) == Objective.Status.PENDING, "it waits, unengaged")
	var labels := []
	for tag in w.tags():
		labels.append(tag.label)
	t.check(labels == ["THE CHILD", "SOLDIER", Wish.WISHER_LABEL], "the child, the soldier and the wisher tagged (%s)" % [labels])
	w.on_cast("doom", w.child.ground_pos + Vector2(RescueWish.ENGAGE_REACH + 1.0, 0.0))
	t.check(not w.engaged, "a cast too far from them does not engage it")
	w.on_cast("doom", w.child.ground_pos + Vector2(RescueWish.ENGAGE_REACH - 0.2, 0.0))
	t.check(w.engaged and not w.waiting() and w.soldier.mind == Person.Mind.DUTY and not w.engage(),
		"one near the child engages it: the soldier sets out; once only")
	t.check(w.hud_text(s.rules) == "Save my child (+0) 0:45", "its clock shows (%s)" % w.hud_text(s.rules))
	_arrive(w.soldier, w.child.ground_pos)
	w.step(s.rules, RescueWish.RETARGET)
	t.check(w.dragging and w.child.mind == Person.Mind.DUTY and w.soldier.goal().distance_to(RescueWish.GATE) < 1.5,
		"he takes the child toward the Citadel's gate")
	w.soldier.mind = Person.Mind.CONFUSED
	t.check(w.check(s.rules) == Objective.Status.DONE and w.child.mind != Person.Mind.DUTY, "turned: granted, the child let go")
	_done(s)

	var late := _world()
	var l := _wish(late, "child") as RescueWish
	l.engage()
	l.step(late.rules, RescueWish.SECONDS + 1.0)
	t.check(l.check(late.rules) == Objective.Status.FAILED and l.soldier.mind != Person.Mind.DUTY, "45 s gone: failed, the soldier let go")
	_done(late)

	var gate := _world()
	var g := _wish(gate, "child") as RescueWish
	g.engage()
	g.dragging = true
	_arrive(g.soldier, g._gate)
	t.check(g.check(gate.rules) == Objective.Status.FAILED, "the gate reached: failed")
	_done(gate)

	var lost := _world()
	var c := _wish(lost, "child") as RescueWish
	(lost.field as EnemyField).kill(c.child, &"doom")
	t.check(c.check(lost.rules) == Objective.Status.FAILED and c.tags().is_empty(), "the child dead, unengaged: failed (review focus 2)")
	_done(lost)

	var stopped := _world()
	var k := _wish(stopped, "child") as RescueWish
	k.engage()
	(stopped.field as EnemyField).kill(k.soldier, &"doom")
	t.check(k.check(stopped.rules) == Objective.Status.DONE, "the soldier dead: granted")
	_done(stopped)


static func _mercy(t) -> void:
	var s := _world()
	var w := _wish(s, "brother") as MercyWish
	var exit: Vector2 = MercyWish.exits()[0]
	_arrive(w.target, exit)
	w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.PENDING, "at a gate unwhispered: nothing")
	var escaped := (s.crowd as Crowd).escaped_count
	w.target.whisper(exit, 8.0)
	_arrive(w.target, exit)
	w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.DONE and (s.crowd as Crowd).escaped_count == escaped + 1
		and not (s.crowd as Crowd).citizens.has(w.target), "whispered to a gate: he escapes, granted")
	var dead := _wish(s, "brother", 8) as MercyWish
	(s.field as EnemyField).kill(dead.target, &"doom")
	t.check(dead.check(s.rules) == Objective.Status.FAILED, "dead first: failed")
	_done(s)


static func _family(t) -> void:
	var s := _world()
	var w := _wish(s, "family") as FamilyWish
	var near := true
	for p: Person in w.family:
		near = near and p != w.wisher and p.profile.home.distance_to(w.wisher.profile.home) <= FamilyWish.REACH
	t.check(w.family.size() == FamilyWish.COUNT and near, "three living near the wisher's home")
	var first: Person = w.family[0]
	first.whisper(first.ground_pos + Vector2(1.0, 0.0), 8.0)
	w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.PENDING and w.hud_text(s.rules) == "Show yourself to my family (+0) 1 / 3",
		"one shown (%s)" % w.hud_text(s.rules))
	for p: Person in w.family:
		p.whisper(p.ground_pos + Vector2(1.0, 0.0), 8.0)
	w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.DONE, "all three shown: granted")
	var other := _wish(s, "family", 11) as FamilyWish
	(s.field as EnemyField).kill(other.family[1], &"doom")
	t.check(other.check(s.rules) == Objective.Status.FAILED, "one dead before being shown: failed")
	_done(s)
```

  - Add `"res://tests/test_wish_kinds.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `RescueWish`, `MercyWish` or `FamilyWish`.

- [ ] **Step 3: Create `src/game/descend/rescue_wish.gd`:**

```gdscript
class_name RescueWish
extends Wish
## "Save my child" (v0.11 M1, spec §5.3, Rescue): a timed wish. It waits until the player engages it -- the child's or the
## soldier's tag clicked, or a power cast within ENGAGE_REACH of either -- then a soldier walks to the child and drags them
## toward the Citadel's gate. Stop him (dead) or turn him (off his duty: frightened, confused, held) within SECONDS, the
## child alive, and it is granted. The child dying, the gate reached, or the time run out fails it. Unengaged, it waits as
## long as the night lasts. The child is a lay citizen of the wisher's household (CitizenProfile.family: the town has no
## ages).

const SECONDS := 45.0
const ENGAGE_REACH := 2.0
## The Citadel's gate the child is dragged to (snapped to walkable ground), and how near counts as there.
const GATE := Vector2(-10.5, -7.6)
const GATE_REACH := 1.0
## How near the soldier must come to take the child, and how often the pair are re-aimed.
const TAKE_REACH := 0.9
const RETARGET := 0.5

var child: Person
var soldier: Person
var engaged := false
var dragging := false
var seconds_left := SECONDS
var _gate := GATE
var _retarget_in := 0.0
var _ended := false


func choose(crowd: Crowd, _town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	_crowd = crowd
	var homes := Wish.lay(crowd, taken)
	var parents: Array[Person] = []
	for p in homes:
		if p.profile.family >= 0 and _child_of(p, homes) != null:
			parents.append(p)
	if parents.is_empty():
		return false
	var parent := parents[rng.randi_range(0, parents.size() - 1)]
	var kid := _child_of(parent, homes)
	var guard := _soldier_near(crowd, kid.ground_pos, taken)
	if guard == null:
		return false
	wisher = parent
	child = kid
	soldier = guard
	taken.append_array([wisher, child, soldier])
	var free := crowd._grid.nearest_walkable(GATE) if crowd._grid != null else GATE
	_gate = free if free != Vector2.INF else GATE
	return true


## The first of `homes` but `p` in `p`'s household, or null.
static func _child_of(p: Person, homes: Array[Person]) -> Person:
	for q in homes:
		if q != p and q.profile.family == p.profile.family:
			return q
	return null


## The free soldier nearest `at`: alive, out of doors, of no corps, not in `taken`; null for none.
static func _soldier_near(crowd: Crowd, at: Vector2, taken: Array) -> Person:
	var best: Person = null
	for s in crowd.soldiers:
		if MissionDirector._alive(s) and not s.inside and s.corps == Person.Corps.NONE and not taken.has(s) \
				and (best == null or s.ground_pos.distance_to(at) < best.ground_pos.distance_to(at)):
			best = s
	return best


func timed() -> bool:
	return true


func waiting() -> bool:
	return not engaged and status == Status.PENDING


## Engaged (spec §5.2): the soldier sets out for the child and the clock starts. Once only, while both live.
func engage() -> bool:
	if not waiting() or not MissionDirector._alive(soldier) or not MissionDirector._alive(child):
		return false
	engaged = true
	seconds_left = SECONDS
	_retarget_in = 0.0
	soldier.go_duty(child.ground_pos)
	return true


func on_cast(_key: String, at: Vector2) -> void:
	if engaged:
		return
	for p: Variant in [child, soldier]:
		if MissionDirector._alive(p) and (p as Person).ground_pos.distance_to(at) <= ENGAGE_REACH:
			engage()
			return


## The clock runs; every RETARGET the soldier is re-aimed at the child, then, once he has them, at the gate, the child
## following him.
func step(_rules: Rules, delta: float) -> void:
	if not engaged or status != Status.PENDING:
		return
	seconds_left = maxf(seconds_left - delta, 0.0)
	_retarget_in -= delta
	if _retarget_in > 0.0 or not MissionDirector._alive(soldier) or not MissionDirector._alive(child) \
			or soldier.mind != Person.Mind.DUTY:
		return
	_retarget_in = RETARGET
	if not dragging and soldier.ground_pos.distance_to(child.ground_pos) <= TAKE_REACH:
		dragging = true
	if dragging:
		soldier.go_duty(_gate)
		child.go_duty(soldier.ground_pos)
	else:
		soldier.go_duty(child.ground_pos)


func _act(_rules: Rules) -> Status:
	if not MissionDirector._alive(child):
		return Status.FAILED
	if not MissionDirector._alive(soldier):
		return Status.DONE
	if not engaged:
		return Status.PENDING
	if soldier.mind != Person.Mind.DUTY:
		return Status.DONE
	if dragging and soldier.ground_pos.distance_to(_gate) <= GATE_REACH:
		return Status.FAILED
	return Status.FAILED if seconds_left <= 0.0 else Status.PENDING


## Once ended, whoever is still on its errand is let go (Crowd.off_duty()): the child home, the soldier to his post.
func check(rules: Rules) -> Status:
	var s := super(rules)
	if s != Status.PENDING and not _ended:
		_ended = true
		for p: Variant in [child, soldier]:
			if MissionDirector._alive(p) and (p as Person).mind == Person.Mind.DUTY:
				_crowd.off_duty(p)
	return s


func hud_text(_rules: Rules) -> String:
	var clock := " %s" % UiTheme.clock(seconds_left) if engaged and status == Status.PENDING else ""
	return "%s (+%d)%s" % [def.text, reward, clock]


func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if MissionDirector._alive(child) and not child.inside:
		out.append(MapTag.person(child.ground_pos, COLOR, "THE CHILD", engaged))
	if MissionDirector._alive(soldier) and not soldier.inside:
		out.append(MapTag.person(soldier.ground_pos, COLOR, "SOLDIER", engaged))
	return out
```

- [ ] **Step 4: Create `src/game/descend/mercy_wish.gd`:**

```gdscript
class_name MercyWish
extends Wish
## "Lead my brother out" (v0.11 M1, spec §5.3, Mercy): whisper the marked citizen to a way out and he escapes, granting the
## wish; him dying first fails it. A way out is one of the town's gates (exits()): the map's own exits lie past the river
## and the fields, beyond any whisper's reach.

## How near a gate a whispered brother must come.
const EXIT_REACH := 1.5

var target: Person
var _out := false


## The ways out: the Main Gate, the Side Gate and the postern.
static func exits() -> Array[Vector2]:
	var out: Array[Vector2] = [TownLayout.MAIN_GATE.get_center(), TownLayout.SIDE_GATE.get_center(), TownLayout.POSTERN_AT]
	return out


func choose(crowd: Crowd, town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	if not super(crowd, town, rng, taken):
		return false
	target = Wish.pick_lay(crowd, rng, taken)
	return target != null


## Whispered and at a gate: he escapes (Crowd.escape(), as a boat's passenger does; it counts as an escape).
func step(_rules: Rules, _delta: float) -> void:
	if _out or not MissionDirector._alive(target) or target.mind != Person.Mind.WHISPERED:
		return
	for e in exits():
		if target.ground_pos.distance_to(e) <= EXIT_REACH:
			_out = true
			_crowd._field.remove(target)
			_crowd.escape(target)
			return


func _act(_rules: Rules) -> Status:
	if _out:
		return Status.DONE
	return Status.PENDING if MissionDirector._alive(target) else Status.FAILED


func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if not _out and MissionDirector._alive(target) and not target.inside:
		out.append(MapTag.person(target.ground_pos, COLOR, "BROTHER"))
	return out
```

- [ ] **Step 5: Create `src/game/descend/family_wish.gd`:**

```gdscript
class_name FamilyWish
extends Wish
## "Show yourself to my family" (v0.11 M1, spec §5.3, Sign): whisper three of the wisher's household -- the three lay citizens
## living nearest the wisher's home, within REACH of it, marked -- each once; the third granted. One dying before being shown
## fails it. The lists are untyped: a member may die and be freed while the wish still holds them.

const COUNT := 3
const REACH := 6.0
const LABEL := "FAMILY"

var family := []
var shown := []


func choose(crowd: Crowd, _town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	_crowd = crowd
	var pool := Wish.lay(crowd, taken)
	if pool.is_empty():
		return false
	var start := rng.randi_range(0, pool.size() - 1)
	for k in pool.size():
		var w := pool[(start + k) % pool.size()]
		var near := _household(w, pool)
		if near.size() >= COUNT:
			wisher = w
			family = near.slice(0, COUNT)
			taken.append(wisher)
			taken.append_array(family)
			return true
	return false


## The lay citizens of `pool` but `w` living within REACH of `w`'s home, nearest first.
static func _household(w: Person, pool: Array[Person]) -> Array[Person]:
	var out: Array[Person] = []
	for p in pool:
		if p != w and p.profile.home.distance_to(w.profile.home) <= REACH:
			out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		return a.profile.home.distance_to(w.profile.home) < b.profile.home.distance_to(w.profile.home))
	return out


## Each member whispered counts once, shown.
func step(_rules: Rules, _delta: float) -> void:
	for p in family:
		if MissionDirector._alive(p) and p.mind == Person.Mind.WHISPERED and not shown.has(p):
			shown.append(p)


func _act(_rules: Rules) -> Status:
	if shown.size() >= COUNT:
		return Status.DONE
	for p in family:
		if not shown.has(p) and not MissionDirector._alive(p):
			return Status.FAILED
	return Status.PENDING


## "Show yourself to my family (+10) 1 / 3".
func hud_text(_rules: Rules) -> String:
	return "%s (+%d) %d / %d" % [def.text, reward, shown.size(), COUNT]


func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for p in family:
		if MissionDirector._alive(p) and not p.inside and not shown.has(p):
			out.append(MapTag.person(p.ground_pos, COLOR, LABEL))
	return out
```

- [ ] **Step 6: The pool's eight.** In `src/game/descend/wish_book.gd`:
  - Replace `pool()`'s comment with `## The pool at M1 (spec §5.3), in the spec's order.`
  - Replace its array with:

```gdscript
	var out: Array[WishDef] = [
		WishDef.make("moneylender", "Burn the moneylender's house", "ruin", 10, RuinWish,
			{"role": "house", "label": "MONEYLENDER"}, PackedStringArray(["spares_houses"])),
		WishDef.make("watchtower", "Bring down the watchtower", "ruin", 15, RuinWish, {"role": "tower", "label": "WATCHTOWER"}),
		WishDef.make("tax_collector", "Strike down the cruel tax collector", "punish", 10, PunishWish,
			{"label": "TAX COLLECTOR", "unseen": false}),
		WishDef.make("informer", "Kill the informer, unseen", "punish", 15, PunishWish, {"label": "INFORMER", "unseen": true}),
		WishDef.make("child", "Save my child", "rescue", 15, RescueWish, {}, PackedStringArray(["unaware_town"])),
		WishDef.make("brother", "Lead my brother out", "mercy", 10, MercyWish),
		WishDef.make("sign", "Show me a sign", "sign", 5, SignWish),
		WishDef.make("family", "Show yourself to my family", "sign", 10, FamilyWish),
	]
```

- [ ] **Step 7: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`, the count up by about 24.
  - `test_wishes.gd`'s `_draw` asks for 10 wishes and expects `WishBook.pool().size()`. In its town every one of the eight is eligible: Tier 1's tags are passed empty there. If one is not, report which and why before changing anything.

- [ ] **Step 8: Commit.**

```bash
git add src/game/descend/rescue_wish.gd src/game/descend/mercy_wish.gd src/game/descend/family_wish.gd src/game/descend/wish_book.gd tests/test_wish_kinds.gd tests/run_all.gd
git commit -m "feat: wishes -- save my child (timed, engaged), lead my brother out, show yourself to my family (v0.11 M1)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: The tier board

**Files:**
- Modify: `src/game/ui/mission_board.gd` (rewritten in place: the tier board)
- Modify: `src/game/draft.gd` (`locked`), `src/game/ui/prepare_screen.gd` (`setup()`'s `locked`, greyed locked cards, the refusal's words)
- Modify: `src/game/game.gd` (FLOW: `_flow_board()`, `_veteran()`)
- Create: `tests/test_tier_board.gd`
- Modify: `tests/test_night.gd` (two checks go), `tests/test_save_file.gd` (the board's checks), `tests/run_all.gd`

**Interfaces:**
- Consumes: `TierBook` (Tasks 2-4), `DescendState` (Task 2), `SaveFile.descend`.
- Produces:
  - **`MissionBoard`:**
    - `signal action(name)`: "pick", "upgrades" or "back";
    - consts: `TAB_TOP`, `TAB_H`, `TAB_GAP`, `BOARD_MARGIN`, `CARD`, `CARD_GAP`, `CARD_TOP`, `PAD`, `UPGRADES_RECT`;
    - vars: `chosen`, `tier`, `selected`;
    - funcs:
      - `setup(save: SaveFile, current: String) -> MissionBoard`;
      - `static tab_rect(i: int) -> Rect2`, `static card_rect(i: int, count: int) -> Rect2`;
      - `missions() -> PackedStringArray`, `open_tab(t: int)`, `choose(id: String)` (picks only an open tier's mission);
      - `lock_line() -> String`, `header_text() -> String`, `best_line(id: String) -> String`, `hit(point) -> String` ("upgrades", "tab:N", "card:i", "").
  - **`Draft`:** `var locked := PackedStringArray()`; `refusal()` may answer `"locked"`.
  - **`PrepareScreen`:** `setup(def, preselect, tier := ResponseProfile.DEFAULT, locked := PackedStringArray())`; `REFUSALS["locked"]`.
  - **`Game` (FLOW):** `_flow_board(step)`, `_veteran()`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_tier_board.gd`:

```gdscript
extends RefCounted
## v0.11 M1 the tier board (spec §3.1): five tabs and the cards of the open one fit the screen; a fresh board opens on Whisper,
## a locked tier shows its rule and its missions cannot be picked; the header; a card's best; the board's draft greys and
## refuses the locked powers (spec §3.4); Prepare for a board mission has no difficulty picker.


static func run(t) -> void:
	_layout(t)
	_tabs(t)
	_best(t)
	_draft(t)


static func _layout(t) -> void:
	var bad := 0
	for i in 5:
		var r := MissionBoard.tab_rect(i)
		if not Rect2(0, 0, 640, 360).encloses(r) or r.position.y >= MissionBoard.CARD_TOP:
			bad += 100
		for j in range(i + 1, 5):
			if r.intersects(MissionBoard.tab_rect(j)):
				bad += 1
	t.check(bad == 0, "the five tabs fit above the cards without touching (%d)" % bad)
	for count in [4, 5]:
		var over := 0
		for i in count:
			var r := MissionBoard.card_rect(i, count)
			if not Rect2(0, 0, 640, 310).encloses(r):
				over += 100
			for j in range(i + 1, count):
				if r.intersects(MissionBoard.card_rect(j, count)):
					over += 1
		t.check(over == 0, "%d cards fit the screen without touching (%d)" % [count, over])


static func _tabs(t) -> void:
	var save := SaveFile.new()
	var board := MissionBoard.new().setup(save, "warning")
	var picked := []
	board.action.connect(func(what: String) -> void: picked.append(what))
	t.check(board.tier == 1 and Array(board.missions()) == ["warning"] and board.lock_line() == ""
		and board.header_text() == "Night 1   Believers 0", "a fresh board: Whisper, The Warning, Night 1 (%s)" % board.header_text())
	board.open_tab(2)
	t.check(board.tier == 2 and board.lock_line() == "Clear 1 Whisper mission", "Omen is locked, its rule shown")
	board.choose("miras_house")
	t.check(picked.is_empty() and board.chosen == "" and board.tier == 2, "a locked mission cannot be picked")
	board.choose("warning")
	t.check(picked == ["pick"] and board.chosen == "warning" and board.tier == 1, "an open one is")
	save.descend.cleared.append("warning")
	save.descend.refresh_open()
	board.choose("broken_lanterns")
	t.check(board.chosen == "broken_lanterns" and board.lock_line() == "", "Omen open: its mission picked")
	var u := InputEventKey.new()
	u.physical_keycode = KEY_U
	u.pressed = true
	board._unhandled_input(u)
	t.check(picked.back() == "upgrades", "U asks for the Upgrades")
	t.check(board.hit(MissionBoard.UPGRADES_RECT.get_center()) == "upgrades" and board.hit(MissionBoard.tab_rect(2).get_center()) == "tab:3"
		and board.hit(MissionBoard.card_rect(0, 2).get_center()) == "card:0", "what is under the mouse")
	board.free()
	var back := MissionBoard.new().setup(save, "broken_lanterns")
	t.check(back.tier == 2 and back.selected == 1, "it opens on the mission last picked, when its tier is open")
	back.free()
	var shut := MissionBoard.new().setup(SaveFile.new(), "festival")
	t.check(shut.tier == 1 and shut.selected == 0, "and on Whisper when it is not")
	shut.free()


static func _best(t) -> void:
	var save := SaveFile.new()
	var board := MissionBoard.new().setup(save, "warning")
	t.check(board.best_line("warning") == "Not yet cleared", "never cleared")
	save.descend.cleared.append("warning")
	t.check(board.best_line("warning") == "Cleared", "cleared, no best yet")
	save.descend.fastest["warning"] = 192.0
	save.descend.most_wishes["warning"] = 2
	t.check(board.best_line("warning") == "Cleared  best 3:12  wishes 2", "its fastest and most wishes (%s)" % board.best_line("warning"))
	board.free()


static func _draft(t) -> void:
	# Last Judgement's pool is every power, so the lock is what refuses (The Warning's pool would refuse first).
	var d := Draft.new().for_mission(TierBook.board("last_judgement"))
	d.locked = PackedStringArray(["tsunami", "nova"])
	t.check(d.refusal("tsunami") == "locked" and d.toggle("tsunami") == "locked" and d.refusal("doom") == "", "a locked power is refused")
	d.preselect(PackedStringArray(["tsunami", "doom"]))
	t.check(d.picks == PackedStringArray(["doom"]), "and left out of a saved loadout")
	var prep := PrepareScreen.new().setup(TierBook.board("warning"), PackedStringArray(), ResponseProfile.DEFAULT,
		DescendState.new().locked())
	t.check(prep.draft.locked.size() == 23 and prep.budget_text() == "0 / 3 slots   0 / 6 DP"
		and prep.hit(PrepareScreen.arrow_rect(-1).get_center()) == "" and not prep.mission.chooses_difficulty(),
		"the board's Prepare: Tier 1's budget, the locked powers, no difficulty picker")
	t.check(String(PrepareScreen.REFUSALS["locked"]) == "Locked: unlock it on the Upgrades screen", "and says why it refuses one")
	prep.free()
```

  - Add `"res://tests/test_tier_board.gd",` at the end of `SUITES`.
  - `tests/test_night.gd`: delete the two checks that call `MissionBoard.loadout_line(...)` (lines 23-27). The tier board's cards show no loadout line; the night's budget is the tier's.
  - `tests/test_save_file.gd`, the block from `var board := MissionBoard.new().setup(old_save, "warning")` to `board.free()`:
    - Keep the three `Game.starting_loadout` checks and the `old_save.remember_loadout` line.
    - Replace `var board := ...` and the "Not yet played" check with:

```gdscript
	var board := MissionBoard.new().setup(old_save, "warning")
	t.check(board.best_line(ln) == "Not yet cleared", "the night's card says Not yet cleared (%s)" % board.best_line(ln))
```

    - Delete the lines from `# The night's card: its best rank` through `marks.free()`, the `half` save with them (the tier board shows no path marks).
    - Keep `board.free()`.
    - In the comment above that block, change `the board says "Not yet played"` to `the board says "Not yet cleared"`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `tab_rect`, `lock_line`, `locked` or `UPGRADES_RECT`.

- [ ] **Step 3: The draft's locked powers.**
  - In `src/game/draft.gd`, add after `var picks := PackedStringArray()`:

```gdscript
## Powers the god has not unlocked (v0.11 M1, spec §3.4): the board's draft shows them greyed with their price and refuses
## them; empty off the board.
var locked := PackedStringArray()
```

  - In `refusal()`, after the `"pool"` return, add:

```gdscript
	if locked.has(key):
		return "locked"
```

    and add `"locked" (v0.11 M1: not yet unlocked on the board), ` to its doc's list.
  - In `src/game/ui/prepare_screen.gd`:
    - Replace `const REFUSALS := {...}` with:

```gdscript
const REFUSALS := {"dp": "Not enough Divine Power", "slots": "No free slot", "pool": "Not a power of this mission",
	"locked": "Locked: unlock it on the Upgrades screen"}
```

    - Replace `setup()`'s signature and its first three lines with:

```gdscript
## `locked` (v0.11 M1): on the board, the powers not yet unlocked, greyed and refused; empty elsewhere.
func setup(def: MissionDef, preselect: PackedStringArray, tier := ResponseProfile.DEFAULT,
		locked := PackedStringArray()) -> PrepareScreen:
	mission = def
	draft = Draft.new().for_mission(mission)
	draft.locked = locked
	draft.preselect(preselect)
```

    - In `_draw_card()`, replace `var cost := "%d DP  %s" % [int(p.dp), cooldown_text(p)]` with:

```gdscript
	# A locked power (v0.11 M1, spec §3.4) shows its unlocking price instead.
	var cost := "%d DP  %s" % [int(p.dp), cooldown_text(p)]
	if draft.locked.has(key):
		cost = "Locked: %d" % DescendState.unlock_price(key)
```

- [ ] **Step 4: Rewrite `src/game/ui/mission_board.gd`** as the tier board:

```gdscript
class_name MissionBoard
extends Node
## The tier board (v0.11 M1, spec §3.1), between the Title and Prepare, in place of v0.08's board of three cards.
## - Five tabs, one per Awakening Tier, and the open tab's missions as cards: name, type, two-line brief, best result, and a
##   tick once cleared.
## - A locked tier shows a padlock and its rule.
## - The header holds the night to come, the believers and an Upgrades button.
## - Input: the mouse, Left and Right choose a card; Tab or 1-5 a tier; a click or Enter picks the card (an open tier's
##   only); U opens the Upgrades; Esc goes back to the title.

## "pick" (the player chose `chosen`), "upgrades" or "back" (Esc).
signal action(name: String)

## The tabs' row under the title: five tabs sharing the screen less its margins.
const TAB_TOP := 34.0
const TAB_H := 18.0
const TAB_GAP := 4.0
const BOARD_MARGIN := 8.0
## A card at most CARD wide, the gap between cards, the top of their row (centred on the screen), and a card's padding.
const CARD := Vector2(300.0, 230.0)
const CARD_GAP := 12.0
const CARD_TOP := 62.0
const PAD := 10.0
## The header's Upgrades button.
const UPGRADES_RECT := Rect2(548.0, 8.0, 84.0, 20.0)

## The mission picked, once "pick" is emitted.
var chosen := ""
## The tier whose tab is open (1-5), and the selected card on it.
var tier := 1
var selected := 0

var _save: SaveFile
var _ui: Control
var _hover := ""
## Each board mission's def, for its card's words (built once).
var _defs := {}


func setup(save: SaveFile, current: String) -> MissionBoard:
	_save = save
	for id in TierBook.all():
		_defs[id] = TierBook.board(id)
	tier = 1
	selected = 0
	var at := TierBook.tier_of(current)
	if at > 0 and _state().is_open(at):
		tier = at
		selected = maxi(TierBook.missions(at).find(current), 0)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	return self


## The board's state: the save's, or a fresh one with no save.
func _state() -> DescendState:
	if _save == null:
		_save = SaveFile.new()
	return _save.descend


## Tab `i` (from 0): the five share the screen less its margins.
static func tab_rect(i: int) -> Rect2:
	var count := TierBook.NAMES.size()
	var w := floorf((640.0 - BOARD_MARGIN * 2.0 - TAB_GAP * float(count - 1)) / float(count))
	return Rect2(Vector2(BOARD_MARGIN + float(i) * (w + TAB_GAP), TAB_TOP), Vector2(w, TAB_H))


## Where card `i` of `count` sits: side by side, the row centred on 320; a card narrows when `count` of CARD's width would
## not fit (five missions a tier from M6).
static func card_rect(i: int, count: int) -> Rect2:
	var size := CARD
	size.x = minf(CARD.x, floorf((640.0 - BOARD_MARGIN * 2.0 - float(maxi(count - 1, 0)) * CARD_GAP) / float(maxi(count, 1))))
	var total := float(count) * size.x + float(maxi(count - 1, 0)) * CARD_GAP
	var left := roundf(320.0 - total * 0.5)
	return Rect2(Vector2(left + float(i) * (size.x + CARD_GAP), CARD_TOP), size)


## The open tab's missions, by id.
func missions() -> PackedStringArray:
	return TierBook.missions(tier)


## The open tier's rule while it is locked (spec §3.1: "Clear 3 Omen missions"); "" while open.
func lock_line() -> String:
	return "" if _state().is_open(tier) else DescendState.lock_text(tier)


## The header's line (spec §3.1): the night about to be played, and the believers.
func header_text() -> String:
	return "Night %d   Believers %d" % [_state().night + 1, _state().believers]


## A card's best (spec §3.1, §3.5): "Not yet cleared", or "Cleared" with its fastest clear and most wishes when it has them.
func best_line(id: String) -> String:
	var s := _state()
	if not s.cleared.has(id):
		return "Not yet cleared"
	var parts := PackedStringArray(["Cleared"])
	if s.fastest.has(id):
		parts.append("best %s" % UiTheme.clock(float(s.fastest[id])))
	if int(s.most_wishes.get(id, 0)) > 0:
		parts.append("wishes %d" % int(s.most_wishes[id]))
	return "  ".join(parts)


## Opens tier `t`'s tab -- locked or not: a locked one shows its rule -- on its first card.
func open_tab(t: int) -> void:
	t = clampi(t, 1, TierBook.NAMES.size())
	if t == tier:
		return
	tier = t
	selected = 0
	UiSound.play(&"ui_click")
	_redraw()


## Picks a mission by id, as a click on its card would (the FLOW test, --show): its tier's tab opens, and the mission is
## picked only when that tier is open.
func choose(id: String) -> void:
	var t := TierBook.tier_of(id)
	if t == 0:
		push_warning("KAK has no board mission called " + id)
		return
	tier = t
	selected = maxi(TierBook.missions(t).find(id), 0)
	if _state().is_open(t):
		_pick()
	else:
		_redraw()


## What is under a point: "upgrades", "tab:<tier>", "card:<i>" (the open tier's), or "".
func hit(point: Vector2) -> String:
	if UPGRADES_RECT.has_point(point):
		return "upgrades"
	for i in TierBook.NAMES.size():
		if tab_rect(i).has_point(point):
			return "tab:%d" % (i + 1)
	var ids := missions()
	for i in ids.size():
		if card_rect(i, ids.size()).has_point(point):
			return "card:%d" % i
	return ""


func _pick() -> void:
	if not _state().is_open(tier) or missions().is_empty():
		return
	chosen = missions()[selected]
	UiSound.play(&"ui_manifest")
	_redraw()
	action.emit("pick")


func _select(i: int) -> void:
	var ids := missions()
	if ids.is_empty():
		return
	i = posmod(i, ids.size())
	if i != selected:
		selected = i
		UiSound.play(&"ui_hover")
		_redraw()


func _redraw() -> void:
	if _ui != null:
		_ui.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.physical_keycode
		if key == KEY_ESCAPE:
			UiSound.play(&"ui_click")
			action.emit("back")
		elif key == KEY_U:
			UiSound.play(&"ui_click")
			action.emit("upgrades")
		elif key == KEY_LEFT:
			_select(selected - 1)
		elif key == KEY_RIGHT:
			_select(selected + 1)
		elif key == KEY_TAB:
			open_tab(posmod(tier - 1 + (-1 if event.shift_pressed else 1), TierBook.NAMES.size()) + 1)
		elif key >= KEY_1 and key <= KEY_5:
			open_tab(key - KEY_1 + 1)
		elif key in [KEY_ENTER, KEY_KP_ENTER]:
			_pick()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := hit(event.position)
		if h != _hover:
			_hover = h
			if h.begins_with("card:"):
				_select(int(h.substr(5)))
			_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var h := hit(event.position)
		if h == "upgrades":
			UiSound.play(&"ui_click")
			action.emit("upgrades")
		elif h.begins_with("tab:"):
			open_tab(int(h.substr(4)))
		elif h.begins_with("card:"):
			selected = int(h.substr(5))
			_pick()


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.03, 0.05, 1.0))
	UiTheme.text(_ui, Vector2(8, 24), "THE TIERS", UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	var head := header_text()
	UiTheme.text(_ui, Vector2(UPGRADES_RECT.position.x - 10.0 - UiTheme.width(head, UiTheme.SIZE_SMALL), 22.0), head,
		UiTheme.SIZE_SMALL)
	_ui.draw_rect(UPGRADES_RECT, Color(0.04, 0.04, 0.06, 0.85))
	UiTheme.frame(_ui, UPGRADES_RECT, _hover == "upgrades")
	UiTheme.text(_ui, Vector2(roundf(UPGRADES_RECT.get_center().x - UiTheme.width("Upgrades") * 0.5), UPGRADES_RECT.position.y + 14.0),
		"Upgrades", UiTheme.SIZE_BODY, UiTheme.COL_GOLD if _hover == "upgrades" else UiTheme.COL_TEXT)
	for i in TierBook.NAMES.size():
		_draw_tab(i)
	if _state().is_open(tier):
		var ids := missions()
		for i in ids.size():
			_draw_card(card_rect(i, ids.size()), ids[i], i == selected)
	else:
		_draw_locked()
	var hint := "Left and Right: missions   Tab or 1-5: tiers   Enter: prepare   U: upgrades   Esc: title"
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(hint, UiTheme.SIZE_SMALL) * 0.5), 322.0), hint,
		UiTheme.SIZE_SMALL, UiTheme.COL_DIM)


## Tab `i`: "1 WHISPER", gold-framed while open; a locked tier's dim, with a padlock.
func _draw_tab(i: int) -> void:
	var r := tab_rect(i)
	var open := i + 1 == tier
	var unlocked := _state().is_open(i + 1)
	_ui.draw_rect(r, Color(0.12, 0.1, 0.05, 0.95) if open else (Color(0.1, 0.09, 0.07, 0.9) if _hover == "tab:%d" % (i + 1)
		else UiTheme.COL_PANEL))
	UiTheme.frame(_ui, r, open)
	var label := "%d %s" % [i + 1, TierBook.tier_name(i + 1).to_upper()]
	UiTheme.text(_ui, Vector2(r.position.x + 5.0, r.end.y - 5.0), label, UiTheme.SIZE_SMALL,
		UiTheme.COL_GOLD if open and unlocked else (UiTheme.COL_TEXT if unlocked else UiTheme.COL_DIM))
	if not unlocked:
		_padlock(Vector2(r.end.x - 12.0, r.position.y + 6.0), 1.0, UiTheme.COL_DIM)


## A padlock drawn in lines, its body's top-left at `at`, `k` times its small size.
func _padlock(at: Vector2, k: float, col: Color) -> void:
	_ui.draw_arc(at + Vector2(3.5, 0.0) * k, 2.5 * k, PI, TAU, 8, col, maxf(k, 1.0))
	_ui.draw_rect(Rect2(at, Vector2(7.0, 6.0) * k), col)


## A locked tier's body (spec §3.1): a large padlock and the rule that opens it.
func _draw_locked() -> void:
	_padlock(Vector2(306.0, 140.0), 4.0, UiTheme.COL_GOLD_DARK)
	var rule := lock_line()
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(rule, UiTheme.SIZE_BIG) * 0.5), 196.0), rule, UiTheme.SIZE_BIG,
		UiTheme.COL_GOLD)


## One card, top to bottom: its name and a tick once cleared, its type, its brief, then under a rule its best.
func _draw_card(r: Rect2, id: String, on: bool) -> void:
	var def: MissionDef = _defs.get(id)
	_ui.draw_rect(r, Color(0.1, 0.09, 0.07, 0.9) if on else UiTheme.COL_PANEL)
	UiTheme.frame(_ui, r, on)
	var x := r.position.x + PAD
	var room := r.size.x - PAD * 2.0
	var text_col := UiTheme.COL_TEXT if on else UiTheme.COL_DIM
	var y := r.position.y + PAD + 14.0
	for line in UiTheme.wrap(def.name, room - 12.0, UiTheme.SIZE_BIG):
		UiTheme.text(_ui, Vector2(x, y), line, UiTheme.SIZE_BIG, UiTheme.COL_GOLD if on else UiTheme.COL_GOLD_DARK)
		y += UiTheme.LINE_BODY + 3.0
	if _state().cleared.has(id):
		UiTheme.mark(_ui, Vector2(r.end.x - PAD - 7.0, r.position.y + PAD + 2.0), true)
	UiTheme.text(_ui, Vector2(x, y), TierBook.type_of(id).to_upper(), UiTheme.SIZE_SMALL, UiTheme.COL_GOLD if on else UiTheme.COL_DIM)
	y += UiTheme.LINE_SMALL + 8.0
	for brief in def.brief:
		for line in UiTheme.wrap(brief, room, UiTheme.SIZE_BODY):
			UiTheme.text(_ui, Vector2(x, y), line, UiTheme.SIZE_BODY, text_col)
			y += UiTheme.LINE_BODY
	var rule := r.end.y - PAD - UiTheme.LINE_SMALL - 6.0
	_ui.draw_line(Vector2(x, rule), Vector2(r.end.x - PAD, rule), UiTheme.COL_GOLD_DARK, -1.0)
	UiTheme.text(_ui, Vector2(x, rule + 4.0 + UiTheme.LINE_SMALL), best_line(id), UiTheme.SIZE_SMALL,
		UiTheme.COL_GOLD if on else UiTheme.COL_DIM)
```

- [ ] **Step 5: FLOW's board steps.** In `src/game/game.gd`:
  - In `_flow_test()`, right after `step.call(Music.current() == &"theme", "the board plays the theme")`, add:

```gdscript
	await _flow_board(step)
	_veteran()
```

  - Add after `_mission_up()`:

```gdscript
## v0.11 M1 (spec §3.1-§3.2): on a fresh save the tier board opens on Whisper, The Warning its one card; Omen is locked,
## its rule shown, and its missions cannot be picked. Ends on the board, Whisper open.
func _flow_board(step: Callable) -> void:
	var board := _screen_node as MissionBoard
	step.call(board != null and board.tier == 1 and Array(board.missions()) == ["warning"] and save.descend.open_tier == 1,
		"a fresh board opens on Whisper, The Warning its only card")
	board.open_tab(2)
	board.choose(MissionBook.MIRAS_HOUSE)
	step.call(screen == Screen.BOARD and _screen_node == board and board.chosen == "" and board.lock_line() == "Clear 1 Whisper mission",
		"Omen is locked: its rule shows, and Mira's House cannot be picked (%s)" % board.lock_line())
	board.open_tab(1)


## The steps from before the tier board (FLOW, v0.11 M1) play Last Judgement, The Long Night and their drafts as a veteran
## god would: every tier open, every power unlocked, no upgrades bought (so the tiers' own budgets are checked).
func _veteran() -> void:
	save.descend.open_tier = TierBook.NAMES.size()
	save.descend.dp_bought = 0
	save.descend.slot_bought = 0
	for key in save.descend.locked():
		save.descend.unlocked.append(key)
```

  - Until Task 9, Prepare and the mission are still MissionBook's: the board only lists and picks.

- [ ] **Step 6: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`. Report the count: about +20, less the checks removed from `test_night.gd` (2) and `test_save_file.gd` (3).

- [ ] **Step 7: FLOW.** Run FLOW. Expected: `checks=93 failures=0` (91 + 2).

- [ ] **Step 8: Photograph.** Run `--show=board` and Read `captures/screen_board.png`. Report:
  - the tabs (Whisper open, four locked with padlocks);
  - The Warning's card (name, INTERCEPT, brief, "Not yet cleared");
  - the header and the Upgrades button.

- [ ] **Step 9: Commit.**

```bash
git add src/game/ui/mission_board.gd src/game/draft.gd src/game/ui/prepare_screen.gd src/game/game.gd tests/test_tier_board.gd tests/test_night.gd tests/test_save_file.gd tests/run_all.gd
git commit -m "feat: the tier board -- five tabs, cards, locks, night and believers; locked powers in the board's draft (v0.11 M1)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: Board nights in play

**Files:**
- Modify: `src/game/mission.gd`, `src/game/game.gd`
- Create: `tests/test_board_nights.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes:
  - `TierBook.board()` (Tasks 3-4), `Descent` (Tasks 5-7);
  - `Rules.main_done` / `ascend()` / `ascended` (Task 5);
  - `PrepareScreen.setup(..., locked)` (Task 8), `DescendState.locked()`.
- Produces:
  - **`Mission`:**
    - consts: `ASCEND_SECONDS := 2.0`, `ASCEND_BANNER := "YOU ASCEND"`;
    - vars: `board: bool`, `descend: DescendState`, `wish_seed: int`;
    - funcs: `static def_for(id: String, on_board: bool, state: DescendState) -> MissionDef`, `static ascends(event: InputEvent) -> bool`, `ascend() -> bool`, `descent() -> Descent`;
    - a board night's `finished` result carries `"descend"`.
  - **`Game`:** `static locked_for(save: SaveFile, in_campaign: bool) -> PackedStringArray`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_board_nights.gd`:

```gdscript
extends RefCounted
## v0.11 M1 board nights (spec §3.1, §4, §6): a mission played from the board is TierBook's version with the god's upgrades,
## one played in the campaign or alone is MissionBook's; F is the ascent's key and nothing else; the board's draft knows the
## locked powers, the campaign's does not.


static func run(t) -> void:
	var state := DescendState.new()
	state.dp_bought = 1
	var w := Mission.def_for("warning", true, state)
	t.check(w.director == StarfallDirector and w.dp_capacity == 7 and w.tier_floor == 1, "from the board: the three stars, +1 DP")
	t.check(Mission.def_for("warning", false, state).director == WarningDirector
		and Mission.def_for("feast_festival", true, state).id == "feast_festival", "in the campaign: MissionBook's own")
	t.check(Mission.def_for("festival", true, null).name == "The Festival", "the board's Festival is found by its id")
	var f := InputEventKey.new()
	f.physical_keycode = KEY_F
	f.pressed = true
	var echo := InputEventKey.new()
	echo.physical_keycode = KEY_F
	echo.pressed = true
	echo.echo = true
	var g := InputEventKey.new()
	g.physical_keycode = KEY_G
	g.pressed = true
	var up := InputEventKey.new()
	up.physical_keycode = KEY_F
	t.check(Mission.ascends(f) and not Mission.ascends(echo) and not Mission.ascends(g) and not Mission.ascends(up),
		"F pressed ascends; an echo, a release or another key does not")
	var save := SaveFile.new()
	t.check(Game.locked_for(save, false).size() == 23 and Game.locked_for(save, true).is_empty(),
		"the board's draft greys the locked powers; the campaign's keeps its own rules")
```

  - Add `"res://tests/test_board_nights.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `def_for`, `ascends` or `locked_for`.

- [ ] **Step 3: The mission plays a board night.** In `src/game/mission.gd`:
  - Add after `const ENDING_TIME_SCALE := 0.3`:

```gdscript
## The ascent's slow motion (v0.11 M1, spec §6: about 2 s) in place of the ending's ENDING_SECONDS, and its banner.
const ASCEND_SECONDS := 2.0
const ASCEND_BANNER := "YOU ASCEND"
```

  - Add after `var bell_rang := false`:

```gdscript
## A night on the tier board (v0.11 M1): Game sets it before start() for every mission played outside the campaign. The
## mission is then TierBook.board()'s version with `descend`'s upgrades, and its night has a Descent.
var board := false
var descend: DescendState
## The seed the board night's wishes are drawn from (Descent.seed_for()): Game sets it, and an R restart keeps it.
var wish_seed := 0
## The board night being played (v0.11 M1), or null off the board.
var _descent: Descent
```

  - In `start()`, after `_director = null`, add:

```gdscript
	if _descent != null:
		_descent.release()
		_descent = null
```

  - In `start()`, after `_def = _mission_def(args)`, add:

```gdscript
	# A board night (v0.11 M1): its wishes, its Tier 5 Gaze and its ascent, handed to each act's Rules in _build_act().
	_descent = Descent.new().setup(_def, wish_seed) if board and TierBook.has(_def.id) else null
```

  - In `_build_act()`, right after the `var made := play.make_director()` block (Task 3), add:

```gdscript
	if _descent != null:
		_descent.attach(_rules, _director)
```

  - In `next_act()`, before `_rules.teardown()`, add:

```gdscript
	if _descent != null:
		_descent.next_act(_rules)  # its seconds count toward the night's time
```

  - Replace `_mission_def()` with:

```gdscript
## The mission to play: Game's choice, or for a standalone run the command line's --mission=<id> (v0.08); on the board, its
## tier's version (v0.11 M1).
func _mission_def(args: PackedStringArray) -> MissionDef:
	var wanted_mission := Battlefield.arg_value(args, "--mission") if autostart else ""
	return def_for(wanted_mission if wanted_mission != "" else mission_id, board, descend)


## The mission for `id` (v0.11 M1): on the board, its tier's version (TierBook.board(), with `state`'s upgrades); else
## MissionBook's -- the campaign's, a standalone run's, a scripted run's.
static func def_for(id: String, on_board: bool, state: DescendState) -> MissionDef:
	if on_board and TierBook.has(id):
		return TierBook.board(id, state)
	return MissionBook.get_mission(id)
```

  - Add after `act()`:

```gdscript
## The board night being played (v0.11 M1), or null.
func descent() -> Descent:
	return _descent


## The god ascends (v0.11 M1, spec §6): once a board night's main objective is done, F (or the ASCEND plate) ends it, won.
## False when there is nothing to ascend from: off the board, before the main objective, in the intro or the ending.
func ascend() -> bool:
	if not started() or _ending or in_intro() or _descent == null or not _rules.main_done or _rules.finished:
		return false
	return _rules.ascend()


## The ascent's key (spec §6): F pressed -- not an echo, nor a release. Nothing else in a mission uses it.
static func ascends(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo and event.physical_keycode == KEY_F
	return false
```

  - In `_unhandled_input()`'s key branch, add before `elif event.physical_keycode == KEY_ESCAPE:`:

```gdscript
		elif ascends(event):
			ascend()
```

  - In `_on_over()`, replace its first line with `_rules.banner.emit(ASCEND_BANNER if _rules.ascended else ResultsScreen.title_for(won, reason))`.
  - In `_play_ending()`:
    - replace `await get_tree().create_timer(ENDING_SECONDS, true, false, true).timeout` with:

```gdscript
		var wait := ASCEND_SECONDS if _rules.ascended else ENDING_SECONDS
		await get_tree().create_timer(wait, true, false, true).timeout
```

    - replace `finished.emit(res)` with `finished.emit(_with_descent(res))`;
    - replace `finished.emit(_night.result(res, _def.id, _def.scored))` with `finished.emit(_with_descent(_night.result(res, _def.id, _def.scored)))`.
  - Add after `_play_ending()`:

```gdscript
## A board night's result (v0.11 M1) with its Descent's report merged in ("descend"); any other as it is.
func _with_descent(res: Dictionary) -> Dictionary:
	if _descent != null:
		res.merge(_descent.report(_rules))
	return res
```

- [ ] **Step 4: Game plays the board's version.** In `src/game/game.gd`:
  - In `_build_mission()`, after `mission.mission_id = mission_id`, add:

```gdscript
	# Outside the campaign every mission is a board night (v0.11 M1): its tier's version, the god's upgrades, and wishes
	# drawn from the nights played -- the same again on a Restart, redrawn once a night is counted.
	mission.board = not _in_campaign
	mission.descend = save.descend
	mission.wish_seed = Descent.seed_for(save.descend.night, mission_id)
```

  - In `go_to()`'s `Screen.PREPARE` branch:
    - replace `prep.setup(act, loadout, save.difficulty)` with `prep.setup(act, loadout, save.difficulty, locked_for(save, _in_campaign))`;
    - replace the final `prep.setup(MissionBook.get_mission(mission_id), loadout, save.difficulty)` with:

```gdscript
				prep.setup(Mission.def_for(mission_id, true, save.descend), loadout, save.difficulty, locked_for(save, false))
```

  - Add after `starting_loadout()`:

```gdscript
## The powers the draft greys and refuses (v0.11 M1, spec §3.4): on the board those not yet unlocked; none in the campaign,
## which keeps its own DP rules.
static func locked_for(from: SaveFile, in_campaign: bool) -> PackedStringArray:
	return PackedStringArray() if in_campaign else from.descend.locked()
```

- [ ] **Step 5: FLOW plays the board's versions.** In `src/game/game.gd`:
  - The board's Warning block (Task 1's version). Replace `(_mission.rules().director as WarningDirector).warning_dead = true` and the step after it with:

```gdscript
	for w: WarningDirector in (_mission.rules().director as StarfallDirector).stars:
		w.warning_dead = true
	await _until(func() -> bool: return _mission.rules().main_done, 3.0)
	_mission.ascend()
	var faded := await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	step.call(faded and _screen_node is ResultsScreen and String(result.get("reason", "")) == "warning"
		and bool(result.get("won", false)) and not result.has("score") and result.has("descend"),
		"stopping the three warnings and ascending wins the board's Warning (%s)" % result.get("reason", "?"))
```

    and its comment's first line becomes `# The board's Warning (v0.11 M1): three stars; all three stopped holds the night, and ascending ends it, won.`
  - `_flow_night`:
    - first step: replace `and prep.draft.slots == 3 and prep.draft.capacity == 6` with `and prep.draft.slots == 6 and prep.draft.capacity == 16`, and its text with `"picking The Long Night opens its draft on Tier 5's 6 slots and 16 DP (v0.11 M1)"`;
    - the Festival's re-draft step: replace `prep.draft.slots == 4 and prep.draft.capacity == 10` with `prep.draft.slots == 6 and prep.draft.capacity == 16`, and `Act II's 4 slots and 10 DP` in its text with `the tier's 6 slots and 16 DP`;
    - Act III's re-draft step: replace `prep.draft.slots == 4 and prep.draft.capacity == 14` with `prep.draft.slots == 6 and prep.draft.capacity == 16`, and its text with `"Choose powers shows Act III's draft with BEGIN, the tier's 6 slots and 16 DP"`.
  - `_flow_campaign`'s last board step: replace `prep.draft.slots == 6 and prep.draft.capacity == 14` with `prep.draft.slots == 6 and prep.draft.capacity == 16`, and its text with `"the board after the campaign: Last Judgement at Tier 5, 6 slots and 16 DP"`.
  - Nothing else in FLOW changes:
    - Act I of The Long Night is still a lone `WarningDirector`, and not its last act, so it ends at once.
    - Every other step reaches its result by the clock, before any main objective.

- [ ] **Step 6: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`, the count up by 5.

- [ ] **Step 7: FLOW.** Run FLOW. Expected: `checks=93 failures=0`. Paste every `FLOW FAIL` line if there are any.

- [ ] **Step 8: Commit.**

```bash
git add src/game/mission.gd src/game/game.gd tests/test_board_nights.gd tests/run_all.gd
git commit -m "feat: the board plays its tier versions -- a Descent per night, ascend with F, results carry the night (v0.11 M1)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: The mission HUD: wishes, the prayers, ASCEND, the light

**Files:**
- Modify: `src/game/ui/hud.gd`, `src/game/mission.gd`, `src/game/mission/mission_hints.gd`, `src/game/game.gd` (FLOW `_flow_ascend()`)
- Create: `tests/test_descend_hud.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes:
  - `Descent.wishes` / `tags()` / `engage()` (Tasks 6-7), `Wish.COLOR` / `state_name()` / `waiting()`;
  - `Rules.main_done` / `last_cast`, `Mission.ascend()` (Task 9).
- Produces:
  - **`Hud`, consts:** `WISH_BOX`, `ASCEND_SIZE`, `ASCEND_TOP`, `ASCEND_TEXT`, `ASCEND_KEY`, `PRAYERS_TOP`, `PRAYERS_TITLE`, `RISE_SECONDS`, `RISE_COL`, `ENGAGE_PX`.
  - **`Hud`, vars:** `praying: bool`.
  - **`Hud`, funcs:**
    - wishes: `wish_rows() -> Array` (`[text, state]`), `wishes_top() -> float`, `wish_at(point: Vector2) -> int`;
    - the plate: `ascend_shown() -> bool`, `ascend_rect() -> Rect2`;
    - tags: `all_tags() -> Array[MapTag]`;
    - the light: `rise(at: Vector2)`, `rising() -> bool`;
    - the Gaze: `gaze_bar_shown() -> bool`, `gaze_readout() -> String`.
  - **`MissionHints`:** `ASCEND_LINE := "Ascend when you are ready: press F."`, `WISHES_LINE := "Grant the wishes still open (blue), or ascend when you are ready: press F."`

- [ ] **Step 1: Write the failing test.** Create `tests/test_descend_hud.gd`:

```gdscript
extends RefCounted
## v0.11 M1 the mission HUD on the board (spec §5.1-§5.2, §6): the wishes' rows under the how-to-win plate; THE NIGHT IS
## YOURS, the ASCEND plate above the slots and the hint switching to the wishes or the ascent; the wishes' tags after the
## director's; a waiting wish's tag answers a click; the ascent's light; the Tier 5 Gaze readable while the rite shows
## (review focus 1).

const DT := 0.05


static func run(t) -> void:
	_rows(t)
	_ascend(t)
	_tags(t)
	_rise(t)
	_gaze_display(t)


static func _world(def: MissionDef) -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := def.make_director().setup(rules, crowd, town, null)
	rules.director = director
	var descent := Descent.new().setup(def, 7)
	descent.attach(rules, director)
	var hud := Hud.new().setup(rules, crowd, town, null)
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director,
		"descent": descent, "hud": hud}


static func _done(s: Dictionary) -> void:
	(s.hud as Hud).free()
	(s.descent as Descent).release()
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


static func _stop_all(s: Dictionary) -> void:
	for w in (s.d as StarfallDirector).stars:
		w.warning_dead = true
	(s.rules as Rules).advance(DT)


static func _rows(t) -> void:
	var s := _world(TierBook.board("warning"))
	var hud: Hud = s.hud
	var d: Descent = s.descent
	var rows := hud.wish_rows()
	t.check(rows.size() == d.wishes.size() and rows.size() == 2 and String(rows[0][1]) == "open"
		and String(rows[0][0]) == d.wishes[0].hud_text(s.rules), "the wishes heard, each a row, open (%s)" % [rows])
	d.wishes[0].status = Objective.Status.DONE
	d.wishes[1].status = Objective.Status.FAILED
	t.check(String(hud.wish_rows()[0][1]) == "granted" and String(hud.wish_rows()[1][1]) == "failed", "granted ticks, failed crosses")
	t.check(hud.wishes_top() >= hud.hint_rect().end.y, "under the how-to-win plate")
	var before := hud._signature()
	hud.praying = true
	t.check(hud._signature() != before, "the prayers plate going up redraws the HUD")
	_done(s)


static func _ascend(t) -> void:
	var s := _world(TierBook.board("warning"))
	var hud: Hud = s.hud
	var rules: Rules = s.rules
	t.check(not hud.ascend_shown() and hud.hint_text() == MissionHints.line("warning", (s.d as StarfallDirector).hint_phase()),
		"no ASCEND before the main objective (review focus 4); the mission's own hint")
	_stop_all(s)
	var r := hud.ascend_rect()
	t.check(hud.ascend_shown() and is_equal_approx(r.get_center().x, 320.0) and r.end.y <= Hud.SLOT_TOP - Hud.PLATE_H - 3.0,
		"main objective done: the ASCEND plate, centred above the slots and their modes (%s)" % r)
	t.check(hud.hint_text() == MissionHints.WISHES_LINE, "the hint turns to the wishes still open")
	for w in (s.descent as Descent).wishes:
		w.status = Objective.Status.FAILED
	t.check(hud.hint_text() == MissionHints.ASCEND_LINE, "with none open, to the ascent")
	var fits := Hud.hint_lines(MissionHints.WISHES_LINE).size() <= Hud.HINT_LINES and Hud.hint_lines(MissionHints.ASCEND_LINE).size() == 1
	t.check(fits, "both fit the plate")
	rules.ascend()
	t.check(not hud.ascend_shown(), "ascended: the plate goes")
	_done(s)


static func _tags(t) -> void:
	var s := _world(TierBook.board("warning"))
	var hud: Hud = s.hud
	var all := hud.all_tags()
	var own := (s.d as StarfallDirector).tags()
	t.check(all.size() == own.size() + (s.descent as Descent).tags().size() and all.back().color == Wish.COLOR
		and all[0].label == own[0].label, "the director's tags first, then the wishes' in blue")
	var rescue := RescueWish.new()
	for d in WishBook.pool():
		if d.id == "child":
			rescue.def = d
	var r := RandomNumberGenerator.new()
	r.seed = 3
	rescue.choose(s.crowd, s.town, r, [])
	# The wisher and the soldier stood well away, so only the child's tag is under the clicks below.
	rescue.wisher.ground_pos = rescue.child.ground_pos + Vector2(10.0, 0.0)
	rescue.soldier.ground_pos = rescue.child.ground_pos + Vector2(0.0, 10.0)
	(s.descent as Descent).wishes.assign([rescue])
	var child_tag := rescue.tags()[0]
	var at := Hud.tag_point(child_tag, Transform2D.IDENTITY)
	t.check(hud.wish_at(at) == 0 and hud.wish_at(at + Vector2(Hud.ENGAGE_PX + 3.0, 0.0)) == -1,
		"a click on the waiting wish's tag finds it; one beside it does not")
	rescue.engage()
	t.check(hud.wish_at(at) == -1, "engaged, it answers no more clicks")
	var bare := MissionDirector.new()
	(s.rules as Rules).director = bare
	(s.descent as Descent).wishes.clear()
	t.check(not Hud.tags_shown(s.rules), "nothing tagged: nothing shown")
	(s.rules as Rules).director = s.d
	_done(s)


static func _rise(t) -> void:
	var s := _world(TierBook.board("warning"))
	var hud: Hud = s.hud
	t.check(not hud.rising(), "no light before the ascent")
	hud.rise(Vector2(2.0, 3.0))
	t.check(hud.rising(), "the ascent's light rises")
	hud.advance(Hud.RISE_SECONDS + 0.1)
	t.check(not hud.rising(), "and is gone after its two seconds")
	_done(s)


static func _gaze_display(t) -> void:
	var s := _world(TierBook.board("last_judgement"))
	var hud: Hud = s.hud
	var crowd: Crowd = s.crowd
	t.check(hud.gaze_bar_shown() and hud.gaze_readout() == "Gaze 0%", "Tier 5: the Gaze bar, and its readout in the panel")
	crowd.rite.state = BanishingRite.State.GATHERING
	t.check(hud.rite_text() != "" and not hud.gaze_bar_shown() and hud.gaze_readout() == "Gaze 0%",
		"the rite gathering takes the bar's place; the panel still reads the Gaze (review focus 1)")
	crowd.rite.state = BanishingRite.State.ENDED
	_done(s)
	var plain := _world(TierBook.board("warning"))
	t.check(not (plain.hud as Hud).gaze_bar_shown() and (plain.hud as Hud).gaze_readout() == "", "no Gaze below Tier 5")
	_done(plain)
```

  - Add `"res://tests/test_descend_hud.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `wish_rows`, `ascend_shown`, `ASCEND_LINE`, `all_tags` or `rise`.

- [ ] **Step 3: The hint's two lines.** In `src/game/mission/mission_hints.gd`, add after `RITE_LINE`:

```gdscript
## Once a board night's main objective is done (v0.11 M1, spec §6): the open wishes, or the ascent when none is open. Kept
## out of LINES: they belong to no mission, and replace any.
const WISHES_LINE := "Grant the wishes still open (blue), or ascend when you are ready: press F."
const ASCEND_LINE := "Ascend when you are ready: press F."
```

- [ ] **Step 4: The HUD.** In `src/game/ui/hud.gd`:
  - Add after `SKIP_TEXT`:

```gdscript
## The wishes (v0.11 M1, spec §5.2): a row each under the how-to-win plate, ROW_H tall, with an open box (WISH_BOX square), a
## tick once granted, or a cross and the words struck through once failed.
const WISH_BOX := 7.0
## The ASCEND plate (spec §6): centred above the slot row, clear of a focused power's modes; its word and its key.
const ASCEND_SIZE := Vector2(96.0, 20.0)
const ASCEND_TOP := 272.0
const ASCEND_TEXT := "ASCEND"
const ASCEND_KEY := "F"
## The town prays (spec §5.1): the plate over the wishes heard during the night's first intro, its top and its title.
const PRAYERS_TOP := 166.0
const PRAYERS_TITLE := "THE TOWN PRAYS..."
## The ascent (spec §6): a pale gold column rising over the god's last cast spot for RISE_SECONDS of real time.
const RISE_SECONDS := 2.0
const RISE_COL := Color(1.0, 0.93, 0.7)
## How near a click must come to a waiting wish's tag to engage it (spec §5.2).
const ENGAGE_PX := 8.0
```

  - Add after `var _canvas: CanvasItem = self`:

```gdscript
## The night's first intro is up (v0.11 M1): Mission sets it, and the prayers plate shows the wishes heard.
var praying := false
## The ascent's column (v0.11 M1): its ground point (Vector2.INF for none) and its real seconds so far.
var _rise_at := Vector2.INF
var _rise_age := 0.0
```

  - In `advance()`, add after the `_age(_subtitles, ...)` line:

```gdscript
	if _rise_at != Vector2.INF:
		_rise_age += delta / maxf(Engine.time_scale, 0.001)  # real seconds, through the ascent's slow motion
```

    and add `or rising()` to the `if flashing or not _banners.is_empty() ...` condition.
  - Replace `hint_text()`:

```gdscript
## The how-to-win line for the mission or act being played, in its director's phase (v0.10 M6, MissionHints); once a board
## night's main objective is done (v0.11 M1, spec §6), the open wishes' or the ascent's; "" for none.
func hint_text() -> String:
	if _rules == null or _rules.mission == null:
		return ""
	if _rules.main_done:
		return MissionHints.WISHES_LINE if _open_wishes() else MissionHints.ASCEND_LINE
	return MissionHints.line(_rules.mission.id, _rules.director.hint_phase() if _rules.director != null else "")


## A wish of the night is still open (v0.11 M1).
func _open_wishes() -> bool:
	if _rules.descent == null:
		return false
	for w in _rules.descent.wishes:
		if w.status == Objective.Status.PENDING:
			return true
	return false
```

  - Add after `hint_rect()`:

```gdscript
## The wishes heard (v0.11 M1, spec §5.2) as [text, state] rows, state "open", "granted" or "failed"; none off the board.
func wish_rows() -> Array:
	var rows := []
	if _rules == null or _rules.descent == null:
		return rows
	for w in _rules.descent.wishes:
		rows.append([w.hud_text(_rules), Wish.state_name(w.status)])
	return rows


## Where the wishes' rows start (v0.11 M1): under the how-to-win plate, or where it would be with no line.
func wishes_top() -> float:
	var hint := hint_rect()
	return hint.end.y + 4.0 if hint.size != Vector2.ZERO else hint_top()


## The ASCEND plate is up (spec §6): a board night's main objective done, the night not over.
func ascend_shown() -> bool:
	return _rules != null and _rules.descent != null and _rules.main_done and not _rules.finished


func ascend_rect() -> Rect2:
	return Rect2(roundf((_view().x - ASCEND_SIZE.x) * 0.5), ASCEND_TOP, ASCEND_SIZE.x, ASCEND_SIZE.y)


## Everything on the map's tag layer (v0.11 M1): the director's tags, then the wishes' (spec §5.1), so a crowded view keeps
## the mission's own labels.
func all_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if _rules == null:
		return out
	if _rules.director != null:
		out.append_array(_rules.director.tags())
	if _rules.descent != null:
		out.append_array(_rules.descent.tags())
	return out


## The waiting timed wish whose tag is within ENGAGE_PX of the screen point `point` (spec §5.2: clicking its tag engages it),
## as its index among the night's wishes; -1 for none.
func wish_at(point: Vector2) -> int:
	if _rules == null or _rules.descent == null:
		return -1
	var xf := get_viewport().get_canvas_transform() if is_inside_tree() else Transform2D.IDENTITY
	var wishes := _rules.descent.wishes
	for i in wishes.size():
		if not wishes[i].waiting():
			continue
		for tag in wishes[i].tags():
			if tag.valid() and tag_point(tag, xf).distance_to(point) <= ENGAGE_PX:
				return i
	return -1


## The ascent begins (v0.11 M1, spec §6): a column of light over the ground point `at`.
func rise(at: Vector2) -> void:
	_rise_at = at
	_rise_age = 0.0


func rising() -> bool:
	return _rise_at != Vector2.INF and _rise_age < RISE_SECONDS


## The Gaze bar shows (v0.11 M1): the director keeps a Gaze, and the Banishing Rite is not showing in its place (review
## focus 1: a Tier 5 town has the rite, and both sit under the clock).
func gaze_bar_shown() -> bool:
	return gaze_of(_rules) >= 0.0 and rite_text() == ""


## "Gaze 12%" for a scored mission's panel (v0.11 M1: Tier 5's Gaze in Last Judgement and Act III); "" with no Gaze.
func gaze_readout() -> String:
	var f := gaze_of(_rules)
	return "" if f < 0.0 else "Gaze %d%%" % roundi(f * 100.0)
```

  - Replace `tags_shown()`:

```gdscript
## Something is tagged (v0.10 M6; v0.11 M1 the wishes too): the tags follow people and the camera, so their layer redraws.
static func tags_shown(rules: Rules) -> bool:
	if rules == null:
		return false
	if rules.director != null and not rules.director.tags().is_empty():
		return true
	return rules.descent != null and not rules.descent.tags().is_empty()
```

  - In `_draw_gaze()`, replace `if f < 0.0:` with `if not gaze_bar_shown():`.
  - In `_draw_tags()`, delete the two lines `if _rules.director == null:` / `return`, and in the `_layout = tag_layout(...)` call replace `_rules.director.tags()` with `all_tags()`.
  - In `_tag_signature()`, replace everything before its `var xf := ...` line (the director check, `var tags := _rules.director.tags()` and the empty check) with:

```gdscript
	var tags := all_tags()
	if tags.is_empty():
		return ""
```

  - In `_signature()`, after `out += "|" + _caption`, add:

```gdscript
	out += "|%s|%s|%s|%d" % [str(wish_rows()), ascend_shown(), praying, roundi(gaze_of(_rules) * 100.0)]
```

  - In `_draw()`:
    - add `_draw_rise()` as the first call after `var w := ...`;
    - add `_draw_wishes()` after `_draw_hint()`;
    - add `_draw_prayers(w)` after `_draw_subtitle(w)`;
    - add `_draw_ascend()` after `_draw_caption(w)`.
  - At the end of `_draw_objectives()`, add:

```gdscript
	var gaze := gaze_readout()
	if gaze != "":
		# Tier 5's Gaze (v0.11 M1) beside the escapes, readable while the rite's plate takes the bar's place.
		UiTheme.text(self, Vector2(OBJECTIVE_PANEL.end.x - 6.0 - UiTheme.width(gaze, UiTheme.SIZE_SMALL), 54.0), gaze,
			UiTheme.SIZE_SMALL, UiTheme.COL_GOLD.lerp(UiTheme.COL_BAD, gaze_of(_rules)))
```

  - Add after `_draw_hint()`:

```gdscript
## The wishes' rows (v0.11 M1, spec §5.2) on a plate under the how-to-win line: an open box, a tick once granted, a cross and
## the words struck through once failed.
func _draw_wishes() -> void:
	var rows := wish_rows()
	if rows.is_empty():
		return
	var wide := 0.0
	for row: Array in rows:
		wide = maxf(wide, UiTheme.width(String(row[0]), UiTheme.SIZE_SMALL))
	var top := wishes_top()
	draw_rect(Rect2(2.0, top, wide + 22.0, 5.0 + ROW_H * float(rows.size())), UiTheme.COL_PANEL)
	var y := top + 12.0
	for row: Array in rows:
		var text := String(row[0])
		var state := String(row[1])
		var box := Vector2(6.0, y - 8.0)
		if state == "granted":
			UiTheme.mark(self, box, true)
		elif state == "failed":
			UiTheme.mark(self, box, false)
		else:
			draw_rect(Rect2(box, Vector2(WISH_BOX - 1.0, WISH_BOX - 1.0)), Wish.COLOR, false, -1.0)
		var col := Wish.COLOR if state == "open" else (UiTheme.COL_GOLD if state == "granted" else UiTheme.COL_DIM)
		UiTheme.text(self, Vector2(18.0, y), text, UiTheme.SIZE_SMALL, col)
		if state == "failed":
			draw_line(Vector2(18.0, y - 4.0), Vector2(18.0 + UiTheme.width(text, UiTheme.SIZE_SMALL), y - 4.0), UiTheme.COL_DIM, -1.0)
		y += ROW_H


## The town prays (v0.11 M1, spec §5.1): during the night's first intro, a plate in the middle of the screen with
## PRAYERS_TITLE over the wishes heard; none when no wish was.
func _draw_prayers(w: float) -> void:
	if not praying:
		return
	var rows := wish_rows()
	if rows.is_empty():
		return
	var wide := UiTheme.width(PRAYERS_TITLE, UiTheme.SIZE_BODY)
	for row: Array in rows:
		wide = maxf(wide, UiTheme.width(String(row[0]), UiTheme.SIZE_SMALL))
	draw_rect(Rect2(roundf((w - wide) * 0.5) - 8.0, PRAYERS_TOP, wide + 16.0, 22.0 + UiTheme.LINE_SMALL * float(rows.size())),
		Color(0.03, 0.03, 0.05, 0.78))
	UiTheme.text(self, Vector2(roundf((w - UiTheme.width(PRAYERS_TITLE, UiTheme.SIZE_BODY)) * 0.5), PRAYERS_TOP + 14.0),
		PRAYERS_TITLE, UiTheme.SIZE_BODY, Wish.COLOR)
	var y := PRAYERS_TOP + 16.0 + UiTheme.LINE_SMALL
	for row: Array in rows:
		var text := String(row[0])
		UiTheme.text(self, Vector2(roundf((w - UiTheme.width(text, UiTheme.SIZE_SMALL)) * 0.5), y), text, UiTheme.SIZE_SMALL)
		y += UiTheme.LINE_SMALL


## The ASCEND plate (v0.11 M1, spec §6): a gold-framed button above the slots, its key on a plate beside the word.
func _draw_ascend() -> void:
	if not ascend_shown():
		return
	var r := ascend_rect()
	draw_rect(r, Color(0.12, 0.1, 0.04, 0.92))
	UiTheme.frame(self, r, true)
	var word_w := UiTheme.width(ASCEND_TEXT, UiTheme.SIZE_BODY)
	var x := roundf(r.get_center().x - (word_w + 6.0 + plate_size(ASCEND_KEY).x) * 0.5)
	UiTheme.text(self, Vector2(x, r.position.y + 14.0), ASCEND_TEXT, UiTheme.SIZE_BODY, UiTheme.COL_GOLD)
	_plate(Vector2(x + word_w + 6.0, r.position.y + 4.0), ASCEND_KEY, UiTheme.COL_TEXT)


## The ascent's light (v0.11 M1, spec §6): a pale gold column over its ground point, growing to the top of the screen over
## the first half of RISE_SECONDS and fading over all of it, three widths brightening to its core.
func _draw_rise() -> void:
	if not rising():
		return
	var xf := get_viewport().get_canvas_transform() if is_inside_tree() else Transform2D.IDENTITY
	var foot := (xf * Iso.ground_to_screen(_rise_at)).round()
	var k := clampf(_rise_age / RISE_SECONDS, 0.0, 1.0)
	var top := lerpf(foot.y, 0.0, minf(k * 2.0, 1.0))
	for i in 3:
		var half := (9.0 - float(i) * 3.0) * (1.0 - k * 0.5)
		var col := RISE_COL
		col.a = (0.16 + 0.18 * float(i)) * (1.0 - k)
		draw_rect(Rect2(foot.x - half, top, half * 2.0, maxf(foot.y - top, 1.0)), col)
```

- [ ] **Step 5: The mission's prayers, plate and clicks.** In `src/game/mission.gd`:
  - In `start()`, after `_begin_intro(play)`, add:

```gdscript
	if _descent != null and not _scripted and is_instance_valid(_hud):
		_hud.praying = true  # the town prays during the night's first intro (v0.11 M1, spec §5.1)
```

  - In `_land()`, inside `if is_instance_valid(_hud):`, add `_hud.praying = false` after `_hud.set_caption("")`.
  - In `ascend()`, replace `return _rules.ascend()` with:

```gdscript
	if is_instance_valid(_hud):
		var play: MissionDef = _act if _act != null else _def
		_hud.rise(_rules.last_cast if _rules.last_cast != Vector2.INF else play.camera_at)
	return _rules.ascend()
```

  - In `_unhandled_input()`, inside `if event.pressed:` of the left-button branch, add before `var on_slot := _hud.slot_at(event.position)`:

```gdscript
				# The ASCEND plate (v0.11 M1, spec §6) and a waiting wish's tag (§5.2) answer a click before anything is cast.
				if _hud.ascend_shown() and _hud.ascend_rect().has_point(event.position):
					ascend()
					return
				var wish := _hud.wish_at(event.position)
				if wish >= 0 and _descent != null and _descent.engage(wish):
					UiSound.play(&"ui_click")
					return
```

    The click returns before `_aim.press()`, and its release finds `_pressing` false, so it casts nothing (review focus 4).

- [ ] **Step 6: FLOW: the ascent.** In `src/game/game.gd`:
  - In `_flow_test()`, right after `await _flow_board(step)`, add:

```gdscript
	await _flow_ascend(step)
	on_action("results:missions")
	await get_tree().process_frame
```

  - Add after `_flow_board()`:

```gdscript
## v0.11 M1 (spec §4, §5.1, §6): The Warning from the board's card.
## - Prepare has no difficulty picker, Tier 1's 3 slots and 6 DP, and refuses the locked powers.
## - The town prays during the intro.
## - F before the main objective does nothing (review focus 4).
## - Its three warnings stopped: THE NIGHT IS YOURS, the ASCEND plate up, the clock running on.
## - F ascends to the results. Ends on the results.
func _flow_ascend(step: Callable) -> void:
	(_screen_node as MissionBoard).choose(MissionBook.WARNING)
	var prep := _screen_node as PrepareScreen
	step.call(prep != null and prep.draft.slots == 3 and prep.draft.capacity == 6 and not prep.mission.chooses_difficulty()
		and prep.draft.locked.has("tsunami") and prep.draft.locked.size() == 23,
		"its Prepare: Tier 1's 3 slots and 6 DP, no difficulty, the locked powers greyed")
	prep.draft.preselect(MissionBook.warning().default_loadout)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await get_tree().process_frame
	var heard := _mission.descent().wishes.size() if _mission.descent() != null else 0
	step.call(heard > 0 and heard <= TierBook.wishes(1) and _mission._hud.praying, "the town prays during the intro: %d wishes" % heard)
	await _past_intro()
	var f := InputEventKey.new()
	f.physical_keycode = KEY_F
	f.pressed = true
	Input.parse_input_event(f)
	await get_tree().process_frame
	await get_tree().process_frame
	step.call(not _mission.rules().finished and not _mission.rules().main_done and not _mission._hud.praying,
		"F before the main objective does nothing")
	for w: WarningDirector in (_mission.rules().director as StarfallDirector).stars:
		w.warning_dead = true
	await _until(func() -> bool: return _mission.rules().main_done, 3.0)
	await get_tree().process_frame
	var clock0 := _mission.rules().time_left
	step.call(_mission._hud.banners().has(Rules.MAIN_BANNER) and _mission._hud.ascend_shown() and not _mission.rules().finished,
		"the warnings stopped: THE NIGHT IS YOURS, the ASCEND plate up")
	await get_tree().create_timer(0.5).timeout
	step.call(_mission.rules().time_left < clock0 and not _mission.rules().finished,
		"and the clock runs on (%.2f)" % _mission.rules().time_left)
	Input.parse_input_event(f)
	var up := await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	var d: Dictionary = result.get("descend", {})
	step.call(up and bool(d.get("ascended", false)) and bool(d.get("main", false)) and bool(result.get("won", false)),
		"F ascends: the results, won")
```

- [ ] **Step 7: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`, the count up by about 20.

- [ ] **Step 8: FLOW.** Run FLOW. Expected: `checks=99 failures=0` (93 + 6).

- [ ] **Step 9: The references.** Run calm `--seconds=60` and Broken Lanterns. Expected: identical. The HUD is not in the scripted runs' state, and the mission's new code runs only on the board.

- [ ] **Step 10: Commit.**

```bash
git add src/game/ui/hud.gd src/game/mission.gd src/game/mission/mission_hints.gd src/game/game.gd tests/test_descend_hud.gd tests/run_all.gd
git commit -m "feat: the board's HUD -- the wishes and their tags, the town's prayers, ASCEND above the slots, the ascent's light (v0.11 M1)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11: Results, banking and the Upgrades

**Files:**
- Create: `src/game/ui/upgrades_screen.gd`, `tests/test_descend_screens.gd`
- Modify: `src/game/ui/results_screen.gd`, `src/game/game.gd`
- Modify: `tests/test_flow.gd`, `tests/run_all.gd`

**Interfaces:**
- Consumes: `DescendState.bank()` / `buy()` / `refusal()` / `price()` (Task 2), `Descent.report()` (Tasks 5-6), `TierBook.board()`, `Menu`.
- Produces:
  - **`Game`:**
    - `Screen.UPGRADES`;
    - FLOW routes `"board:upgrades"` and `"results:upgrades"` → UPGRADES, `"upgrades:back"` → BOARD;
    - a board night's result gains `descend.bank` (`DescendState.bank()`'s return).
  - **`ResultsScreen`:**
    - `var descend: bool`, the board's buttons `missions` / `replay` / `upgrades` (Board / Again / Upgrades);
    - `static descend_rows(result) -> Array` (`[label, value, mark, note]`, mark "ok" / "x" / "lost" / "open"), `static summary_lines(result) -> PackedStringArray`.
  - **`UpgradesScreen`:**
    - `signal action(name)` ("bought" or "back");
    - consts: `DP_RECT`, `SLOT_RECT`, `GRID_AT`, `CELL`, `CELL_GAP`, `COLUMNS`, `BACK_RECT`, `REFUSE_SECONDS`, `REFUSALS`;
    - vars: `powers`, `refused_reason`;
    - funcs: `setup(state: DescendState) -> UpgradesScreen`, `static cell_rect(i: int) -> Rect2`, `hit(point) -> String`, `button_rect(what: String) -> Rect2`, `click(point)`, `buy(what: String) -> bool`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_descend_screens.gd`:

```gdscript
extends RefCounted
## v0.11 M1 the board's screens (spec §3.4, §6): the results' rows -- the main objective, each wish granted, failed or lost
## with why -- and lines -- believers banked and the total, the night, the tier's progress, bests beaten -- and its Board,
## Again and Upgrades; the Upgrades screen's buttons and grid fit, a click buys what it can afford and refuses what it cannot.

const RESULT := {
	"mission": "warning", "won": true, "reason": "warning", "goal": {"label": "The warnings die", "done": true},
	"descend": {"tier": 1, "main": true, "main_time": 201.0, "main_reward": 10, "ascended": false, "caught": "dawn",
		"lost_text": "lost: dawn came", "earned": 10, "kept": 0,
		"wishes": [{"text": "Burn the moneylender's house", "reward": 10, "state": "granted", "lost": true},
			{"text": "Show me a sign", "reward": 5, "state": "failed", "lost": false},
			{"text": "Lead my brother out", "reward": 10, "state": "open", "lost": false}],
		"bank": {"believers": 10, "total": 35, "night": 3, "cleared": true, "first_clear": true, "opened": 2,
			"progress": "Whisper 1 / 1 cleared: Omen is open", "bests": PackedStringArray(["Fastest clear 3:21"])}},
}


static func run(t) -> void:
	_results(t)
	_upgrades(t)


static func _results(t) -> void:
	var rows := ResultsScreen.descend_rows(RESULT)
	t.check(rows == [["The warnings die", "+10", "ok", ""], ["Burn the moneylender's house", "", "lost", "lost: dawn came"],
		["Show me a sign", "", "x", Wish.UNANSWERED], ["Lead my brother out", "", "open", ""]],
		"the main objective banked; a granted wish lost to dawn; a failed one; one never answered (%s)" % [rows])
	t.check(Array(ResultsScreen.summary_lines(RESULT)) == ["Believers +10, 35 now", "Night 3", "Whisper 1 / 1 cleared: Omen is open",
		"New best: Fastest clear 3:21"], "the believers, the night, the tier's progress, the best (%s)" % [ResultsScreen.summary_lines(RESULT)])
	var won := RESULT.duplicate(true)
	won.descend.ascended = true
	won.descend.wishes[0].lost = false
	t.check(ResultsScreen.descend_rows(won)[1] == ["Burn the moneylender's house", "+10", "ok", ""], "ascended: the wish banked")
	var lost := {"mission": "warning", "won": false, "reason": "bell", "goal": {"label": "The warnings die", "done": false},
		"descend": {"main": false, "main_reward": 10, "wishes": [], "bank": {"believers": 0, "total": 5, "night": 4}}}
	t.check(ResultsScreen.descend_rows(lost) == [["The warnings die", "", "x", ""]]
		and ResultsScreen.summary_lines(lost)[0] == "Believers +0, 5 now", "a loss: the main objective crossed, nothing banked")
	var screen := ResultsScreen.new().setup(RESULT)
	var emitted := []
	screen.action.connect(func(what: String) -> void: emitted.append(what))
	t.check(screen.descend and not screen.campaign, "a board night's results")
	for a in ["missions", "replay", "upgrades"]:
		var r := screen._menu.rect_of(a)
		screen._on_gui_input(_click(r.get_center()))
	t.check(emitted == ["missions", "replay", "upgrades"], "Board, Again and Upgrades (%s)" % [emitted])
	screen.free()


static func _click(at: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	return e


static func _upgrades(t) -> void:
	var bad := 0
	var state := DescendState.new()
	var up := UpgradesScreen.new().setup(state)
	for i in up.powers.size():
		var r := UpgradesScreen.cell_rect(i)
		if not Rect2(0, 0, 640, 316).encloses(r) or r.intersects(UpgradesScreen.DP_RECT) or r.intersects(UpgradesScreen.SLOT_RECT):
			bad += 1
	t.check(up.powers.size() == 23 and bad == 0, "the 23 locked powers' grid fits beside the upgrades (%d)" % bad)
	var emitted := []
	up.action.connect(func(what: String) -> void: emitted.append(what))
	up.click(up.button_rect("dp").get_center())
	t.check(state.dp_bought == 0 and up.refused_reason == "Not enough believers" and emitted.is_empty(), "too few believers: refused, and why")
	state.believers = 100
	up.click(up.button_rect("dp").get_center())
	t.check(state.dp_bought == 1 and state.believers == 75 and emitted == ["bought"], "a click buys the first +1 DP for 25")
	up.click(up.button_rect("tsunami").get_center())
	t.check(state.is_unlocked("tsunami") and state.believers == 15 and up.button_rect("tsunami").has_area(),
		"a locked power unlocked for 60, its cell kept in place")
	up.click(up.button_rect("tsunami").get_center())
	t.check(up.refused_reason == "Already unlocked" and state.believers == 15, "and not bought twice")
	t.check(up.hit(UpgradesScreen.BACK_RECT.get_center()) == "back", "Board goes back")
	up.click(UpgradesScreen.BACK_RECT.get_center())
	t.check(emitted.back() == "back", "to the tier board")
	up.free()
```

  - In `tests/test_flow.gd`:
    - replace `t.check(reachable.size() == Game.Screen.size() and Game.Screen.size() == 8, "all eight screens are reachable (%d)" % reachable.size())` with:

```gdscript
	t.check(reachable.size() == Game.Screen.size() and Game.Screen.size() == 9,
		"all nine screens are reachable, the Upgrades too (v0.11 M1) (%d)" % reachable.size())
```

    - add after the `title:ending` check:

```gdscript
	# The tier board (v0.11 M1): the Upgrades from the board's header and from the results, and back to the board.
	t.check(Game.next_screen("board:upgrades") == Game.Screen.UPGRADES, "the board's Upgrades button opens the Upgrades")
	t.check(Game.next_screen("results:upgrades") == Game.Screen.UPGRADES, "and so do the results'")
	t.check(Game.next_screen("upgrades:back") == Game.Screen.BOARD, "whose Back is the board")
```

  - Add `"res://tests/test_descend_screens.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `UpgradesScreen`, `descend_rows` or `UPGRADES`.

- [ ] **Step 3: Create `src/game/ui/upgrades_screen.gd`:**

```gdscript
class_name UpgradesScreen
extends Node
## The Upgrades (v0.11 M1, spec §3.4): believers spent on the tier board's god -- +1 Divine Power (the n-th for 25 x n, six
## at most), +1 slot (150, once) and each locked power (15 x its DP). Board missions only: the campaign keeps its own DP. A
## click buys what it can afford; one it cannot buzzes and says why. Esc or Board goes back to the tier board.

## "bought" (something was bought: Game writes the save) or "back".
signal action(name: String)

## The two upgrades' buttons on the left, the locked powers' grid beside them (COLUMNS a row), the Board button, and how long
## a refusal's reason stays up.
const DP_RECT := Rect2(8.0, 52.0, 196.0, 40.0)
const SLOT_RECT := Rect2(8.0, 100.0, 196.0, 40.0)
const GRID_AT := Vector2(216.0, 52.0)
const CELL := Vector2(136.0, 20.0)
const CELL_GAP := 4.0
const COLUMNS := 3
const BACK_RECT := Rect2(8.0, 322.0, 100.0, 20.0)
const REFUSE_SECONDS := 1.5
## What a refused purchase says, by DescendState.refusal().
const REFUSALS := {"believers": "Not enough believers", "limit": "None left to buy", "owned": "Already unlocked",
	"unknown": "Not a power"}

## The powers locked when the screen opened, in PowerBook's order: the grid keeps their places as they are bought.
var powers := PackedStringArray()
## Why the last click bought nothing, shown for REFUSE_SECONDS; "" for none.
var refused_reason := ""
var _refuse_left := 0.0
var _state: DescendState
var _ui: Control
var _hover := ""


func setup(state: DescendState) -> UpgradesScreen:
	_state = state
	powers = state.locked()
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	return self


## The grid's cell `i`.
static func cell_rect(i: int) -> Rect2:
	var col := i % COLUMNS
	var row := i / COLUMNS
	return Rect2(GRID_AT + Vector2(float(col) * (CELL.x + CELL_GAP), float(row) * (CELL.y + CELL_GAP)), CELL)


## What is under a point: "dp", "slot", "back", a power key, or "".
func hit(point: Vector2) -> String:
	if DP_RECT.has_point(point):
		return "dp"
	if SLOT_RECT.has_point(point):
		return "slot"
	if BACK_RECT.has_point(point):
		return "back"
	for i in powers.size():
		if cell_rect(i).has_point(point):
			return powers[i]
	return ""


## Where `what` is drawn: "dp", "slot", "back" or a power key's cell; an empty Rect2 for none.
func button_rect(what: String) -> Rect2:
	match what:
		"dp":
			return DP_RECT
		"slot":
			return SLOT_RECT
		"back":
			return BACK_RECT
	var i := powers.find(what)
	return cell_rect(i) if i >= 0 else Rect2()


## A left click at a screen point: Board goes back; anything else is bought if it can be.
func click(point: Vector2) -> void:
	var h := hit(point)
	if h == "":
		return
	if h == "back":
		UiSound.play(&"ui_click")
		action.emit("back")
		return
	buy(h)


## Buys `what`; true when bought. A refusal buzzes and says why for REFUSE_SECONDS.
func buy(what: String) -> bool:
	var why := _state.refusal(what)
	if why != "":
		UiSound.play(&"ui_buzz")
		refused_reason = String(REFUSALS.get(why, why))
		_refuse_left = REFUSE_SECONDS
		_redraw()
		return false
	_state.buy(what)
	UiSound.play(&"ui_manifest")
	refused_reason = ""
	_redraw()
	action.emit("bought")
	return true


func _redraw() -> void:
	if _ui != null:
		_ui.queue_redraw()


func _process(delta: float) -> void:
	if _refuse_left > 0.0:
		_refuse_left -= delta
		if _refuse_left <= 0.0:
			refused_reason = ""
			_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		UiSound.play(&"ui_click")
		action.emit("back")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := hit(event.position)
		if h != _hover:
			_hover = h
			if h != "":
				UiSound.play(&"ui_hover")
			_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click(event.position)


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.03, 0.05, 1.0))
	UiTheme.text(_ui, Vector2(8, 24), "UPGRADES", UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	var purse := "Believers %d" % _state.believers
	UiTheme.text(_ui, Vector2(632.0 - UiTheme.width(purse, UiTheme.SIZE_BODY), 24.0), purse, UiTheme.SIZE_BODY, UiTheme.COL_GOLD)
	var dp_line := "All six bought" if _state.dp_bought >= DescendState.DP_LIMIT else "%d believers   %d / %d" % [_state.dp_price(),
		_state.dp_bought, DescendState.DP_LIMIT]
	_draw_button(DP_RECT, "+1 DIVINE POWER", dp_line, "dp")
	var slot_line := "Bought" if _state.slot_bought >= DescendState.SLOT_LIMIT else "%d believers" % DescendState.SLOT_PRICE
	_draw_button(SLOT_RECT, "+1 SLOT", slot_line, "slot")
	var budget := "Board missions: their tier's budget +%d DP, +%d slot" % [_state.dp_bought, _state.slot_bought]
	for i in UiTheme.wrap(budget, DP_RECT.size.x, UiTheme.SIZE_SMALL).size():
		UiTheme.text(_ui, Vector2(8.0, SLOT_RECT.end.y + 16.0 + UiTheme.LINE_SMALL * float(i)),
			UiTheme.wrap(budget, DP_RECT.size.x, UiTheme.SIZE_SMALL)[i], UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	UiTheme.text(_ui, Vector2(GRID_AT.x, GRID_AT.y - 6.0), "UNLOCK A POWER", UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
	for i in powers.size():
		_draw_cell(i, powers[i])
	_ui.draw_rect(BACK_RECT, Color(0.04, 0.04, 0.06, 0.85))
	UiTheme.frame(_ui, BACK_RECT, _hover == "back")
	UiTheme.text(_ui, Vector2(roundf(BACK_RECT.get_center().x - UiTheme.width("Board") * 0.5), BACK_RECT.position.y + 14.0),
		"Board", UiTheme.SIZE_BODY, UiTheme.COL_GOLD if _hover == "back" else UiTheme.COL_TEXT)
	var hint := refused_reason if refused_reason != "" else "Click to buy. Esc for the board."
	UiTheme.text(_ui, Vector2(BACK_RECT.end.x + 12.0, BACK_RECT.position.y + 14.0), hint, UiTheme.SIZE_SMALL,
		UiTheme.COL_BAD if refused_reason != "" else UiTheme.COL_DIM)


## An upgrade's button: its name, and under it its price and count; dim when it cannot be bought now.
func _draw_button(r: Rect2, title: String, line: String, what: String) -> void:
	var can := _state.refusal(what) == ""
	_ui.draw_rect(r, Color(0.1, 0.09, 0.07, 0.9) if _hover == what else UiTheme.COL_PANEL)
	UiTheme.frame(_ui, r, can and _hover == what)
	UiTheme.text(_ui, r.position + Vector2(8.0, 16.0), title, UiTheme.SIZE_BODY, UiTheme.COL_GOLD if can else UiTheme.COL_DIM)
	UiTheme.text(_ui, r.position + Vector2(8.0, 32.0), line, UiTheme.SIZE_SMALL, UiTheme.COL_TEXT if can else UiTheme.COL_DIM)


## A locked power's cell: its name cut to fit and its price; "Unlocked" once bought; dim when unaffordable.
func _draw_cell(i: int, key: String) -> void:
	var r := cell_rect(i)
	var owned := _state.is_unlocked(key)
	var can := _state.refusal(key) == ""
	_ui.draw_rect(r, Color(0.1, 0.09, 0.07, 0.9) if _hover == key else UiTheme.COL_PANEL)
	UiTheme.frame(_ui, r, owned or (can and _hover == key))
	var price := "Unlocked" if owned else "%d" % DescendState.unlock_price(key)
	var price_w := UiTheme.width(price, UiTheme.SIZE_SMALL)
	var name := UiTheme.fit(String(PowerBook.get_power(key).name), r.size.x - price_w - 14.0)
	UiTheme.text(_ui, r.position + Vector2(4.0, 14.0), name, UiTheme.SIZE_SMALL,
		UiTheme.COL_GOLD if owned else (UiTheme.COL_TEXT if can else UiTheme.COL_DIM))
	UiTheme.text(_ui, Vector2(r.end.x - 4.0 - price_w, r.position.y + 14.0), price, UiTheme.SIZE_SMALL,
		UiTheme.COL_GOLD if owned else UiTheme.COL_DIM)
```

- [ ] **Step 4: The board's results.** In `src/game/ui/results_screen.gd`:
  - Add after `var campaign := false`:

```gdscript
## A board night's results (v0.11 M1, spec §6): Board, Again and Upgrades, and the night's rows and lines.
var descend := false
```

  - Add after `CAMPAIGN_Y`:

```gdscript
## A board night's table (v0.11 M1): its labels' left edge, its values' and marks' right edge, the first row and the step.
const DESCEND_L := 120.0
const DESCEND_R := 520.0
const DESCEND_TOP := 112.0
const DESCEND_ROW := 18.0
```

  - In `setup()`, replace the menu's `if campaign: ... else: ...` with:

```gdscript
	campaign = result.has("campaign")
	descend = result.has("descend") and not campaign
	if campaign:
		_menu = Menu.row(["next"], ["Continue"], 320.0, PANEL.end.y - 28.0, 120.0)
	elif descend:
		_menu = Menu.row(["missions", "replay", "upgrades"], ["Board", "Again", "Upgrades"], 320.0, PANEL.end.y - 28.0, 120.0)
	else:
		_menu = Menu.row(["replay", "change", "missions"], ["Replay", "Change powers", "Missions"], 320.0,
			PANEL.end.y - 28.0, 120.0)
```

    (The existing `campaign = result.has("campaign")` line above it goes: it is now the first line of this block.)
  - In `_draw_ui()`, after the title is drawn, add before `if not _result.has("score"):`:

```gdscript
	if descend:
		_draw_descend()
		_draw_menu()
		return
```

  - Add after `campaign_line()`:

```gdscript
## A board night's rows (v0.11 M1, spec §6) as [label, value, mark, note]:
## - the main objective: its believers and a tick, or a cross;
## - each wish granted (its believers, a tick), lost (struck through, the reason in `note`), failed (a cross, unanswered) or
##   never answered ("open").
static func descend_rows(result: Dictionary) -> Array:
	var d: Dictionary = result.get("descend", {})
	var goal: Dictionary = result.get("goal", {})
	var main := bool(d.get("main", false))
	var rows := [[String(goal.get("label", "")), ("+%d" % int(d.get("main_reward", 0))) if main else "", "ok" if main else "x", ""]]
	for w: Dictionary in d.get("wishes", []):
		var text := String(w.get("text", ""))
		var state := String(w.get("state", "open"))
		if state == "granted" and bool(w.get("lost", false)):
			rows.append([text, "", "lost", String(d.get("lost_text", ""))])
		elif state == "granted":
			rows.append([text, "+%d" % int(w.get("reward", 0)), "ok", ""])
		elif state == "failed":
			rows.append([text, "", "x", Wish.UNANSWERED])
		else:
			rows.append([text, "", "open", ""])
	return rows


## A board night's lines under its rows (v0.11 M1, spec §6): the believers banked and the new total, the night, the tier's
## progress, and each best beaten.
static func summary_lines(result: Dictionary) -> PackedStringArray:
	var d: Dictionary = result.get("descend", {})
	var bank: Dictionary = d.get("bank", {})
	var out := PackedStringArray()
	out.append("Believers +%d, %d now" % [int(bank.get("believers", d.get("earned", 0))), int(bank.get("total", 0))])
	out.append("Night %d" % int(bank.get("night", 0)))
	if String(bank.get("progress", "")) != "":
		out.append(String(bank.get("progress", "")))
	for b in bank.get("bests", PackedStringArray()):
		out.append("New best: " + String(b))
	return out


## A board night (v0.11 M1, spec §6): the mission and its tier under the title, its rows, a rule, then its lines.
func _draw_descend() -> void:
	var d: Dictionary = _result.get("descend", {})
	var def := TierBook.board(String(_result.get("mission", "")))
	var called := "%s  -  %s" % [def.name if def != null else String(_result.get("mission", "")),
		TierBook.tier_name(int(d.get("tier", 1)))]
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(called, UiTheme.SIZE_BODY) * 0.5), 84.0), called, UiTheme.SIZE_BODY,
		UiTheme.COL_DIM)
	var y := DESCEND_TOP
	for row: Array in descend_rows(_result):
		_descend_row(y, row)
		y += DESCEND_ROW
	_ui.draw_line(Vector2(DESCEND_L, y - 10.0), Vector2(DESCEND_R, y - 10.0), UiTheme.COL_GOLD_DARK, -1.0)
	y += 4.0
	var lines := summary_lines(_result)
	for i in lines.size():
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(lines[i], UiTheme.SIZE_BODY) * 0.5), y), lines[i], UiTheme.SIZE_BODY,
			UiTheme.COL_GOLD if i == 0 or lines[i].begins_with("New best") else UiTheme.COL_TEXT)
		y += UiTheme.LINE_BODY


## One board row, `y` its baseline: the label (struck through when lost, dim when unanswered), its note in red before the
## right edge, then its value or its mark at the right edge.
func _descend_row(y: float, row: Array) -> void:
	var label := String(row[0])
	var value := String(row[1])
	var mark := String(row[2])
	var note := String(row[3])
	var dim := mark == "lost" or mark == "open"
	UiTheme.text(_ui, Vector2(DESCEND_L, y), label, UiTheme.SIZE_BODY, UiTheme.COL_DIM if dim else UiTheme.COL_TEXT)
	if mark == "lost":
		_ui.draw_line(Vector2(DESCEND_L, y - 5.0), Vector2(DESCEND_L + UiTheme.width(label, UiTheme.SIZE_BODY), y - 5.0),
			UiTheme.COL_DIM, -1.0)
	if note != "":
		UiTheme.text(_ui, Vector2(DESCEND_R - 12.0 - UiTheme.width(note, UiTheme.SIZE_SMALL), y), note, UiTheme.SIZE_SMALL,
			UiTheme.COL_BAD)
	if value != "":
		UiTheme.text(_ui, Vector2(DESCEND_R - UiTheme.width(value, UiTheme.SIZE_BODY) - (12.0 if mark == "ok" else 0.0), y),
			value, UiTheme.SIZE_BODY, UiTheme.COL_GOLD)
	if mark == "ok" or mark == "x":
		UiTheme.mark(_ui, Vector2(DESCEND_R - 7.0, y - 8.0), mark == "ok")
```

- [ ] **Step 5: Game banks the night and opens the Upgrades.** In `src/game/game.gd`:
  - In `enum Screen`, add `UPGRADES` at the end: `enum Screen {TITLE, BOARD, PREPARE, MISSION, RESULTS, INTERLUDE, CAMPAIGN, ENDING, UPGRADES}`.
  - In `FLOW`, add after `"title:ending": Screen.ENDING,`:

```gdscript
	# The tier board (v0.11 M1): the Upgrades, from the board's header and from a board night's results; back to the board.
	"board:upgrades": Screen.UPGRADES,
	"results:upgrades": Screen.UPGRADES,
	"upgrades:back": Screen.BOARD,
```

  - In `go_to()`'s `match to:`, add before `_:`:

```gdscript
		Screen.UPGRADES:
			var up := UpgradesScreen.new()
			up.name = "Upgrades"
			add_child(up)
			up.setup(save.descend)
			up.action.connect(_on_upgrades_action)
			_screen_node = up
```

    and add `Screen.UPGRADES` to the music `match`'s `Screen.TITLE, Screen.BOARD, ...` line.
  - In `_on_mission_finished()`, replace the `else:` branch with:

```gdscript
	elif result.has("descend"):
		# A board night (v0.11 M1, spec §3.3, §6): banked on the tier board -- the night counted, its believers added, its
		# mission cleared and its bests kept. v0.10's per-mission bests are left as they were.
		(result.descend as Dictionary)["bank"] = save.descend.bank(mission_id, result.descend)
		result["best"] = false
		save.remember_loadout(mission_id, loadout)
	else:
		result["best"] = save.record(mission_id, result)
		save.remember_loadout(mission_id, loadout)
```

  - Add after `_on_ending_action()`:

```gdscript
## The Upgrades screen (v0.11 M1): each purchase is saved at once; Back is the tier board.
func _on_upgrades_action(what: String) -> void:
	if what == "bought":
		save.save_to(save_path)
	elif what == "back":
		on_action("upgrades:back")
```

- [ ] **Step 6: FLOW: banking, the Upgrades, a restart, a night caught.** In `src/game/game.gd`:
  - In `_flow_test()`, replace the two lines after `await _flow_ascend(step)` (`on_action("results:missions")` and its `await get_tree().process_frame`) with `await _flow_results(step)`.
  - Add after `_flow_ascend()`:

```gdscript
## v0.11 M1 (spec §3.3-§3.4, §6; review focus 3).
## - The ascended Warning's results bank it: Night 1, its believers, The Warning cleared, Omen open; the save holds them.
## - Upgrades from the results buys the first +1 DP, saved at once; Back is the board, and The Warning's Prepare has 7 DP.
## - A restart banks nothing and hears the same wishes.
## - A night caught by dawn after its main objective banks the main win, its granted wish lost.
## Ends on the board.
func _flow_results(step: Callable) -> void:
	var res := _screen_node as ResultsScreen
	var d: Dictionary = result.get("descend", {})
	var bank: Dictionary = d.get("bank", {})
	var earned := int(d.get("earned", 0))
	step.call(res != null and res.descend and save.descend.night == 1 and earned >= 10 and save.descend.believers == earned
		and save.descend.cleared.has(MissionBook.WARNING) and save.descend.open_tier == 2 and int(bank.get("opened", 0)) == 2,
		"the results bank the night: Night 1, %d believers, The Warning cleared, Omen open" % earned)
	var reread := SaveFile.new().load_from(save_path)
	step.call(reread.descend.night == 1 and reread.descend.believers == earned and reread.descend.open_tier == 2
		and reread.descend.cleared.has(MissionBook.WARNING), "and the save holds them")
	res.action.emit("upgrades")
	var up := _screen_node as UpgradesScreen
	step.call(screen == Screen.UPGRADES and up != null, "Upgrades from the results opens the Upgrades")
	save.descend.believers += DescendState.DP_STEP  # (a fixture: one night need not pay for the first +1 DP)
	var purse := save.descend.believers
	up.click(up.button_rect("dp").get_center())
	step.call(save.descend.dp_bought == 1 and save.descend.believers == purse - DescendState.DP_STEP
		and SaveFile.new().load_from(save_path).descend.dp_bought == 1, "a click buys the first +1 DP for 25, saved at once")
	up.action.emit("back")
	var board := _screen_node as MissionBoard
	step.call(screen == Screen.BOARD and board != null and save.descend.is_open(2), "Back is the tier board, Omen open")
	board.choose(MissionBook.WARNING)
	var prep := _screen_node as PrepareScreen
	step.call(prep != null and prep.draft.capacity == TierBook.dp(1) + 1,
		"The Warning's Prepare now has %d DP" % (prep.draft.capacity if prep != null else 0))
	prep.draft.preselect(MissionBook.warning().default_loadout)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _past_intro()
	var heard := _wish_ids()
	var old := _mission
	_open_pause()
	on_action("pause:restart")
	await _until(func() -> bool: return _mission_up(old), 10.0)
	await _past_intro()
	step.call(save.descend.night == 1 and _wish_ids() == heard,
		"a restart banks nothing and hears the same wishes (%s)" % ", ".join(heard))
	for w: WarningDirector in (_mission.rules().director as StarfallDirector).stars:
		w.warning_dead = true
	await _until(func() -> bool: return _mission.rules().main_done, 3.0)
	var wishes := _mission.descent().wishes
	if not wishes.is_empty():
		wishes[0].status = Objective.Status.DONE
	var total := save.descend.believers
	_mission.rules().time_left = 0.01
	await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	var caught: Dictionary = result.get("descend", {})
	var rows: Array = caught.get("wishes", [])
	step.call(String(caught.get("caught", "")) == "dawn" and bool(result.get("won", false)) and int(caught.get("earned", 0)) == 10
		and save.descend.believers == total + 10 and save.descend.night == 2
		and (rows.is_empty() or bool((rows[0] as Dictionary).get("lost", false))),
		"caught by dawn after the main objective: its 10 believers banked, the granted wish lost")
	(_screen_node as ResultsScreen).action.emit("missions")
	step.call(screen == Screen.BOARD and _screen_node is MissionBoard, "Board from the results returns to the tier board")


## The night's wishes by id, in the order heard (FLOW, v0.11 M1).
func _wish_ids() -> PackedStringArray:
	var out := PackedStringArray()
	if is_instance_valid(_mission) and _mission.descent() != null:
		for w in _mission.descent().wishes:
			out.append(w.def.id)
	return out
```

- [ ] **Step 7: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`, the count up by about 16.

- [ ] **Step 8: FLOW.** Run FLOW. Expected: `checks=108 failures=0` (99 + 9). Paste every `FLOW FAIL` line if there are any.

- [ ] **Step 9: Commit.**

```bash
git add src/game/ui/upgrades_screen.gd src/game/ui/results_screen.gd src/game/game.gd tests/test_descend_screens.gd tests/test_flow.gd tests/run_all.gd
git commit -m "feat: a board night's results bank its believers and night; the Upgrades screen (v0.11 M1)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 12: The photos and the notes

**Files:**
- Modify: `src/game/game.gd` (`--show=tiers`, `upgrades`, `results-descend`, `ascend`; `SAMPLE_DESCEND_RESULT`)
- Modify (only if a photo shows a problem): the drawing constants `MissionBoard.CARD_TOP` / `PAD`, `Hud.ASCEND_TOP` / `PRAYERS_TOP`, `ResultsScreen.DESCEND_TOP` / `DESCEND_ROW`, `UpgradesScreen.CELL`
- Create: `docs/KAK_Version_0.11_Summary.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: everything above.
- Produces: four photographs and the notes. No new behaviour.

- [ ] **Step 1: The samples.** In `src/game/game.gd`:
  - Add after `SAMPLE_FEAST_RESULT`:

```gdscript
## What --show=results-descend displays (v0.11 M1): the board's Warning caught by dawn after its main objective -- its 10
## believers banked, a granted wish lost, one failed -- and Omen opened by the clear.
const SAMPLE_DESCEND_RESULT := {
	"mission": "warning", "won": true, "reason": "warning", "time": 214.0, "goal": {"label": "The warnings die", "done": true},
	"bonuses": [],
	"descend": {"tier": 1, "main": true, "main_time": 201.0, "main_reward": 10, "ascended": false, "caught": "dawn",
		"lost_text": "lost: dawn came", "earned": 10, "kept": 0,
		"wishes": [{"text": "Burn the moneylender's house", "reward": 10, "state": "granted", "lost": true},
			{"text": "Show me a sign", "reward": 5, "state": "failed", "lost": false}],
		"bank": {"believers": 10, "total": 10, "night": 1, "cleared": true, "first_clear": true, "opened": 2,
			"progress": "Whisper 1 / 1 cleared: Omen is open", "bests": ["Fastest clear 3:21"]}},
}
```

  - In `_ready()`'s `match show:`, add before `_:`:

```gdscript
		"tiers":
			# The tier board part-way up (v0.11 M1): Whisper and Omen cleared, Wrath open, for the photograph (SHOW_SAVE).
			save.descend = DescendState.new()
			save.descend.cleared = PackedStringArray(["warning", "miras_house", "broken_lanterns"])
			save.descend.fastest = {"warning": 192.0}
			save.descend.most_wishes = {"warning": 2}
			save.descend.believers = 64
			save.descend.night = 5
			save.descend.refresh_open()
			mission_id = MissionBook.VIGIL_FLAME
			go_to(Screen.BOARD)
		"upgrades":
			# The Upgrades with a purse (v0.11 M1), one +1 DP and one power bought, for the photograph (SHOW_SAVE).
			save.descend = DescendState.new()
			save.descend.believers = 120
			save.descend.dp_bought = 1
			save.descend.unlocked = PackedStringArray(["tornado"])
			go_to(Screen.UPGRADES)
		"results-descend":
			result = SAMPLE_DESCEND_RESULT.duplicate(true)
			go_to(Screen.RESULTS)
		"ascend":
			# The board's Warning with its main objective done (v0.11 M1), for the photograph of THE NIGHT IS YOURS, the ASCEND
			# plate, the wishes' rows and their tags.
			mission_id = MissionBook.WARNING
			loadout = MissionBook.warning().default_loadout
			go_to(Screen.MISSION)
```

  - In the `if "--capture" in args:` branch, after the `if show in ["miras", "cael", "lanterns", "flame", "flame-beams"] ...` skip block, add:

```gdscript
		if show == "ascend" and is_instance_valid(_mission):
			await _until(func() -> bool: return _mission.started(), 10.0)
			_mission.skip_intro()
			for w: WarningDirector in (_mission.rules().director as StarfallDirector).stars:
				w.warning_dead = true
			await _until(func() -> bool: return _mission.rules().main_done, 3.0)
```

- [ ] **Step 2: Take the photos.** Run `--show=tiers`, `--show=upgrades`, `--show=results-descend` and `--show=ascend`, and Read each `captures/screen_<name>.png`.

- [ ] **Step 3: Judge them against spec §3.1, §3.4, §5.2 and §6.** For each photo, answer in the report:
  - **tiers:**
    - three tabs open, two locked with padlocks;
    - Wrath's two cards with their types and briefs;
    - "Night 6   Believers 64";
    - no text running off a card or under the hint line.
  - **upgrades:**
    - the two buttons with price and count;
    - the grid of locked powers with prices (Tornado "Unlocked");
    - nothing overlapping.
  - **results-descend:**
    - the title, "The Warning  -  Whisper";
    - the main row ticked "+10";
    - the moneylender's struck through with "lost: dawn came" in red;
    - the sign crossed with "Their prayer goes unanswered";
    - the four lines;
    - Board / Again / Upgrades.
  - **ascend:**
    - THE NIGHT IS YOURS (or its banner already gone);
    - the ASCEND plate above the slots;
    - the hint "Grant the wishes still open...";
    - the wish rows under it, and the wish tags in soft blue.

- [ ] **Step 4: Fix only what a photo shows.**
  - Change only the drawing constants listed under **Files**.
  - After any change, run Tests and the photo again.
  - Report each change with its old and new value, and the photo that asked for it. If nothing needs changing, say so.

- [ ] **Step 5: The notes.**
  - Create `docs/KAK_Version_0.11_Summary.md`: a title, then a section `## M1: The Tiers framework`, in the voice of `docs/KAK_Version_0.10_Summary.md`. It says:
    - The board: the five tiers, the eight ★ missions on them, the unlocking rule (and the short-tier rule), the night counter, believers.
    - Each tier's numbers, and the board versions:
      - stretched timelines;
      - the three stars of The Warning;
      - the Festival's 80 of 120 and its 4:30 close;
      - the Gaze at Tier 5.
    - The wishes: the eight, how they are drawn and filtered, engaged and judged.
    - ASCEND, being caught after the main objective, and what is banked or lost.
    - The Upgrades and their prices; locked powers in the board's draft.
    - The no-waiting changes to The Warning and Mira's House, and that they reach the campaign. The moved references' old and new values, from Task 1's commit message.
    - Every ruling in this plan's "Plan decisions", one line each.
    - Gates: write `Gates: filled in at landing.`
  - In `README.md`'s KAK section, add one sentence: Missions now opens a five-tier board whose nights hear the town's wishes, end with an ascent, and bank believers for upgrades.

- [ ] **Step 6: Run Tests** (a docs commit still runs them). Expected: `failures=0`.

- [ ] **Step 7: FLOW.** Run FLOW. Expected: `checks=108 failures=0`.

- [ ] **Step 8: Commit.**

```bash
git add src/game/game.gd docs/KAK_Version_0.11_Summary.md README.md
git commit -m "docs: the v0.11 summary's M1 section, README, and the tier board's photographs (v0.11 M1)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

(If Step 4 changed drawing constants, add those files to the same commit and say so in its message.)

---

## Self-review

**Spec coverage:**

| Spec | Task |
|---|---|
| §2 M1 row | 1-12 |
| §3.1 the board (tabs, cards, header, locked tabs, Prepare) | 8 |
| §3.2 unlocking, short tiers, never closes, "cleared" incl. caught | 2 (rule), 11 (banked on a caught night) |
| §3.3 nights (counted at the end; restart and abandon not) | 2 (bank), 11 (FLOW: restart) |
| §3.4 believers, prices, limits, starting powers, locked greyed with price, board only | 2, 8, 11 |
| §3.5 `[descend]`, bests, fresh without section, v0.10 carry-over, `[campaign]` untouched | 2 |
| §4 the tier table, floor, no picker, budget + upgrades, clock, believers × multiplier, Tier 5 Gaze | 2, 3, 5, 9 |
| §5.1 the prayers plate, count, seeded, eligibility, clashes, wisher in soft blue, failing | 6, 10 |
| §5.2 HUD list, ticks and crosses, map tags, timed wishes on engagement, any time | 6, 7, 10 |
| §5.3 the eight wishes | 6, 7 |
| §6 no ASCEND before main, banner, plate + F, clock runs, hint switch, rise, banking, caught, results | 5, 9, 10, 11 |
| §7.2 board versions: clock, readiness, budget, stretched timelines, three stars, the Festival | 3, 4 |
| §7.3 Mira's House at the fourth Believer, The Warning by stopping it, references recorded | 1 |
| §9 framework tests | 2, 3, 4, 5, 6, 7, 8, 11 |
| §9 FLOW: board → locked tab → Prepare → ASCEND → results; caught-after-main → results | 8, 10, 11 |

**Placeholders:** Task 1's commit body is filled from Step 9's measured lines (the values cannot be known before the run). Task 12's summary text is written from the shipped code. No step says "add tests" without the tests.

**Type consistency:**

| Name | Defined in | Used in |
|---|---|---|
| `TierBook.board(id, state)` | Task 3 | Tasks 4, 8, 9, 11 |
| `Mission.def_for(id, on_board, state)` | Task 9 | Task 9's `Game.go_to` |
| `Descent.attach(rules, director)` | Task 5 | Task 9 `_build_act` |
| `Descent.wish_seed` | Task 5 | Task 6 `hear()` |
| `Descent.engage(i)` | Task 6 | Task 10 Mission click |
| `Descent.next_act(rules)` | Task 5 | Task 9 |
| `Descent.report(rules)["descend"]` keys `main`, `main_time`, `earned`, `kept` | Tasks 5 / 6 | `DescendState.bank()` (Task 2); `wishes` / `lost_text` / `main_reward` in `ResultsScreen.descend_rows()` (Task 11) |
| `Wish.waiting()` / `engage()` / `timed()` | Task 6 | `RescueWish` overrides (Task 7), `Hud.wish_at()` (Task 10) |
| `Rules.MAIN_BANNER`, `main_done`, `ascended`, `caught`, `last_cast` | Task 5 | Tasks 9-11 |
| `PrepareScreen.setup(def, preselect, tier, locked)` | Task 8 | Task 9 |
| `MissionBoard.choose()` / `lock_line()` / `missions()` / `open_tab()` | Task 8 | FLOW in Tasks 8, 10, 11 |
| `UpgradesScreen.button_rect()` / `click()` | Task 11 | Task 11's FLOW |

**Review Focus:** each of the five lines has its test in the owning task, named in its line.
