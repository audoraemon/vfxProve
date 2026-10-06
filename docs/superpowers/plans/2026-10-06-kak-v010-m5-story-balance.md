# KAK v0.10 M5 — Story and Balance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** the Lantern campaign gets the last of its words and its balance check. Cael speaks during the three Night 2 missions, the night screen and the endings carry the text the spec gives them, the campaign's rough edges the earlier milestones deferred are fixed, and Night 3 and Night 4 are measured at the campaign's own budgets.

**Architecture:**
- **Cael's lines** are a second HUD queue beside the banners: a **subtitle** under the banner's bar, his name small in gold, then the line, up 4 s.
  - `Rules` gains `signal subtitle(text: String)`.
  - `MissionDirector._say(event)` looks the line up in `CampaignText.CAEL_LINES` by the mission's id and emits it.
  - The three Night 2 directors call `_say()` from the hooks they already have: Venn's search, the fire, Wren's coming, the light waking, the first shrine drained, the Knights.
  - The words live in `CampaignText`, so writing changes never touch logic.
- **Story text:**
  - The night screen's cards show the mission's **goal** (spec §5.3) instead of its brief. A pure `card_layout()` lays out each card, and a test checks that nothing overlaps.
  - The endings get a drawn frame in place of the panel art, Cael's name under his words, and a closing line on the campaign.
- **Campaign fixes:**
  - The board's own mission comes back whenever the campaign is left.
  - An ending the player never saw is shown from Campaign.
  - The night screen remembers the chosen card.
  - The DP read from a save is clamped above.
  - The Feast's results are those of an unscored night: its goal, its bonus, its time, no three-act rank.
- **HUD marks** are bigger, outlined, and drawn under the banners and the slots.
- **Loose ends in Mira's House and the Vigil Flame:**
  - Venn is not turned to her search while she carries a report.
  - The Vigil's banner does not fire when nobody can walk it.
  - No route or acolyte banners come after the swap.
  - The Faithful who saw the swap runs at his own pace.
  - The Mira's House test's stale wording is fixed.
- **Balance:**
  - A `feast` behaviour scenario plays Night 3's acts alone at the campaign's 4 slots and 10 DP.
  - The `judgement` scenario reports a loadout's cost and can aim like Act III's caster, so Last Judgement can be measured at 12 DP.
  - Only campaign-side numbers may move. The board's Long Night and Last Judgement stay exact.

**Tech Stack:** Godot 4.7.2, GDScript; headless tests in `tests/run_all.gd`; scripted scenarios in `tools/dev/behaviour_check.gd`; FLOW in `src/game/game.gd`.

**Spec:** `docs/superpowers/specs/2026-10-05-kak-v010-lantern-campaign-design.md`. Read §3.1, §4.2, §4.3, §5 (how the story is told), §7 (measures and balance) and §8.5 before any task. This plan covers **M5**. The M1–M4 plans (`docs/superpowers/plans/2026-10-05-kak-v010-m1-campaign-spine.md`, `…-m2-gaze-miras-house.md`, `2026-10-06-kak-v010-m3-broken-lanterns.md`, `2026-10-06-kak-v010-m4-vigil-flame.md`) built everything reused here.

## Global Constraints

- **Baseline:** branch `claude/lantern-campaign-spec` at `ec247e4`: M4 complete (its tag `kak-v010-m4` is the controller's to set). The milestone tag is `kak-v010-m5`.
- **Text only (the user's decision):** no PixelLab art, no new image assets, no new fonts. Ending panels and portraits wait for a later art pass. The ending screens stay text, with a drawn frame.
- **No playtest notes yet:** the user has not playtested M2–M4. Balance numbers move only in Task 8.
- **Machine:** the BURIN_NITRO laptop.
  - **Repository:** the main checkout is `C:\BURIN_NITRO\Godot\GIT\vfxProve` (Git Bash `/c/BURIN_NITRO/Godot/GIT/vfxProve`). Work in the checkout the controller names: this plan was written in the worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve/.claude/worktrees/game-concept-story-review-636208` on `claude/lantern-campaign-spec`. Never touch other sessions' worktrees.
  - **In a fresh worktree,** run the import first.
  - **Godot:** `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`.
- **Commands:**
  - **Import** (after a new `class_name` or a new test file): `timeout 900 $G --headless --editor --path . --import >/dev/null 2>&1`.
  - **Tests:** `timeout 1200 $G --headless --path . --script res://tests/run_all.gd 2>&1 | grep -v '^\s*at:' | grep -n "FAIL\|SCRIPT ERROR\|Parse Error\|checks="`.
    - Expected: `checks=N failures=0`. The baseline at `ec247e4` is **3567**. Each task adds to it; report the count.
    - The `leaked` / `still in use` lines at exit are there at baseline too.
  - **Digest:** `$G --headless --path . -s tools/dev/state_digest.gd`. Expected: `digest=61267b7e90524d800bf1c3473a71146b`.
  - **crowd_check:** `$G --headless --path . --fixed-fps 60 -s tools/dev/crowd_check.gd`. Expected: `checksum=-346732806`.
  - **Behaviour (exact):** `$G --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=<name>`.
    - Give each run `timeout 600`. Run the ten in the background with a long limit: they take about 15 min.
    - A gate run on `ec247e4` is confirming them now. If it moves them, the controller updates this list.
    - `calm --seconds=60`: -355092532
    - `gates`: 589794389
    - `fire`: 250399241
    - `rite --interrupt`: -948525703
    - `soldiers --case=escort`: -778609674
    - `warning --case=none|doom|whisper|discord|mix`: -489775734, -905773030, -588314462, -997640091, -206935500
  - **Mira's House reference (exact):** `--scenario=miras --case=play` prints `BEHAVIOUR miras result won=false reason=gaze time=94.9 believers=3 gaze=100 reports=3` and `BEHAVIOUR checksum=-200101558`.
    - Tasks 1–6 must leave it identical.
    - Task 7's Venn fix may move it. It then records the new lines with the reason, and they are the reference from there on.
  - **Broken Lanterns:**
    - `--scenario=lanterns --case=none --seed=1` loses (`reason=relit`), with `BEHAVIOUR checksum=424350965` (exact).
    - `--case=play --seed=1|2|3` vary run to run (the hit-stop's wall clock). Judge only the outcome: won, `drained=6`.
  - **The Vigil Flame:** `--scenario=flame --case=none` loses on seeds 1–3, and `--case=play` wins at least 2 of 3. Outcome only.
  - **FLOW:** `$G --path . --audio-driver Dummy --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep "FLOW"`. Expected: `failures=0`.
    - The baseline is **82** steps.
    - Task 4 adds four campaign steps, so the count is **86** from Task 4 on.
  - **Mission tests:** `--mission-test` gives, within a few: buildings about 53, citizens 184–193, escaped 0–1, stability 67–71%, citadel 50%. `--mission=warning --mission-test` gives `won=false reason=bell time≈24`. These are not exact (memory: hit-stop wall clock).
  - **Captures:** `GODOT=$G SCENE=res://scenes/game.tscn bash tools/capture.sh --show=<name> --capture`.
- **Powers:** 38 powers; the Authorities are Ruin, Veil, Dominion, Passage, Death, Decree. Pools and default loadouts do not change.
- **Test style:** as in M2–M4.
  - `extends RefCounted`, `static func run(t)`, `t.check` / `t.near`.
  - Register each new file at the end of `SUITES` in `tests/run_all.gd`.
  - Build the town and crowd like `tests/test_vigil_flame.gd`'s `_setup()`, and step `crowd.advance(DT)` then `rules.advance(DT)`.
  - **Headless tests never move or think people:** `Crowd.advance()` does not call `Person.frame()`. Put people where a test needs them with `_arrive()`, and set a mind by hand to stand for what thinking would do.
  - **Tests run with ctx null:** no FX.
  - Compare captured lists as untyped arrays (`var lines := []`), so `==` against an array literal is plain.
- **Code style:**
  - tabs; `##` docs in full sentences; `UPPER_CASE` constants with a `##` comment.
  - **No enum gains a value.**
  - **Every word the player reads in the story lives in `CampaignText`:** Cael's lines, fragments, card lines, titles and endings.
- **Nothing outside the campaign's missions and screens may change in play.**
  - The Warning, The Long Night and Last Judgement, played from the board, play exactly as before. Every exact gate stays identical.
  - The Feast's changes are made in `MissionBook.feast()`'s own copy of the act, never in `_festival()` / `_procession()`.
  - Last Judgement's campaign numbers live in `CampaignDef` / `CampaignState`, never in `MissionBook.last_judgement()`.
- **Git:**
  - stage explicit paths, with each new script's `.gd.uid` file;
  - never stage `default_bus_layout.tres`, `captures/`, `.codex/` or `concepts/`;
  - commit subjects are tagged `(v0.10)` and end with a `Co-Authored-By:` line naming the model that commits. The blocks below show `Claude Opus 5.5`; write your own model's name if it is different;
  - **do not push or tag:** the controller does that at the gate.
- **Tuning latitude:** the code was written against `ec247e4` and has not been run.
  - Fix real bugs and keep each test's intent.
  - **Layout constants may move** if a photograph shows a clash: `Hud.SUBTITLE_TOP`, `Hud.MARK_R` (4 or more), `CampaignScreen.CARD_H` (up to 134, so a card still ends 8 px above `HINT_Y`), and `EndingScreen.INNER` / `CORNER_R`.
  - Report every deviation.

## Review Focus

These are inputs the spec implies but no feature test exercises. Each line has its test in the owning task.

1. **Two lines close together, and a banner with them:** Venn's line while an earlier one is still up, under a queue of banners. Each line shows its full 4 s in turn, none is lost, and the banners keep their own pace. *Test:* Task 1 (`test_hud.gd`).
2. **A line whose moment never comes is never spoken:**
   - Venn dead before 0:40, or already running to the Temple with a report;
   - nobody left to be Wren at 0:50.

   Cael says nothing about them. *Test:* Task 2 (`_lines` in `test_miras_house.gd` and `test_vigil_flame.gd`), Task 7 (`_loose_ends`).
3. **The first-drained line is said once a night.** It is not said again when a second shrine drains (it keys on the drained count reaching one, which a relit shrine never adds to). *Test:* Task 2 (`_lines` in `test_broken_lanterns.gd`).
4. **A save from before M5:**
   - A campaign that had reached its ending has no `ending_seen` key. It reads as not seen, so Campaign shows that ending once more, then starts fresh.
   - A hand-edited `dp` above anything a campaign can reach is pulled back to `MAX_DP`.

   *Test:* Task 4 (`test_campaign.gd` `_save`).
5. **Text longer than its place:**
   - a Cael line wider than the 640-px screen with his name before it;
   - a card's goal running into Cael's line at the card's foot, in a sleeping or a warned town.

   *Test:* Task 1 (`test_cael_lines.gd` widths), Task 3 (`card_layout` in `test_campaign_screens.gd`).

## Where this plan departs from the spec

The controller reports these to the user at the gate.

1. **Cael's lines are a subtitle, not a banner.** They sit on a plate under the banner's bar, his name ("CAEL") small in gold before the line, and stay up 4 s. A banner stays up 2.2 s. The event's own banner still shows above it.
2. **No panel art (the user's decision).**
   - The ending's "one panel" (§5.4) is a drawn frame for now: a second gold rule and corner diamonds.
   - Cael's name stands under his words.
   - The last page closes with the god's title, the nights won and the bites.
   - Fragments stay text on the night screen. There is no darkened town panel and no portraits.
3. **A card shows the mission's goal** (§5.3: "the mission's goal and a line from Cael") in place of its two-line brief. The brief stays on Prepare.
4. **The Feast is an unscored night.** Its results show its own goal, its bonus and its time, with no rank: a one-act night cannot reach The Long Night's three-act thresholds. The campaign never used the score.
5. **An ending the player has not seen** (the game quit on the last Results) is shown from Campaign, then the next Campaign starts fresh.
6. **"First shrine drained"** is said at the first drain only, once a night.
7. **Balance:** whatever Task 8 measures and changes, with before and after lines.

## Decisions for the user

The plan does not decide these. The controller puts them to the user at the gate, with Task 8's measurements.

- **(a) Free retries dodge bites.** Pause → Restart, or Pause → Campaign, leaves a night unplayed at no cost, so a player can retry until a night is won and never take a bite. The options:
  - keep it;
  - count leaving a started night as a loss after its first minute;
  - allow one free retry a night.
- **(b) Broken Lanterns' "Through the faithful" bonus is unreachable in live play.** Most Faithful are evacuating by the fifth drain, and the town-wide flight lies outside Broken Lanterns. The options:
  - the Faithful turn back to kneel (a director rule over their flight);
  - lower `KNEELERS` / `ThroughFaithfulObjective.NEED` / `BONUS_REACH`;
  - replace the bonus.
- **(c) Balance scales far from the spec:**
  - Broken Lanterns: prayer at `PRAYER_SCALE` 0.05 (1/20 of the spec's rate), and a seen death at 0.5 Gaze instead of 10 (`SEEN_DEATH_SCALE` 0.05);
  - the Vigil Flame: prayer at 0.5.

  Accept these as the design, or ask for a rethink of the sources (fewer Faithful, slower beams) so the spec's rates can stand.
- **(d) Last Judgement lost about 5.7 fps and gained 64 draw calls since `kak-v0.09`,** through the merged art and VFX work (M4 Task 8: 132.6 fps on this tree against 138.3 at `kak-v0.09`; 1072 draw calls against 1008). It is outside the campaign. Should a perf pass come before v0.10's release, or after it?
- **(e) Venn's search loops all night.** After Mira's door she starts the round again (`_venn_i` wraps). The M2 doc says the search ends at Mira's. Confirm the loop is intended, or end it at the door.
- **(f) The 2:00 fire might ring the bell.** The priests' fire in Mira's House can draw the town's alarm. A rung bell fills the Gaze and loses the night with no act of the player's. It was not seen in 6 runs. Should the fire be hushed (`crowd.hush()` for its duration), or stay a risk?
- **(g) Noted, not in M5's brief:** Mira's House's scripted policy loses (`reason=gaze`, 3 Believers) since the VFX merge. Its balance was measured with whisper/doom/discord, not the default whisper/wisp/discord. Rebalancing it would move the exact Mira's House reference.

## Deferred items: in this plan, and out of it

**In this plan:**

| Item (milestone) | Task |
|---|---|
| After an ending, Missions opens the board on the campaign's last night, not the last board pick (M1) | 4 |
| `CampaignState.read()` has no upper clamp on `dp` (M1) | 4 |
| Feast results say "Act II: The Festival" and rank on three-act thresholds (M1) | 5 |
| Quitting on the final Results skips the ending screen (M1) | 4 |
| The night screen forgets the chosen card after Back or Pause → Campaign (M1) | 3, 4 |
| Venn redirected at 0:40 while carrying a report (M2) | 7 |
| "THE VIGIL PASSES" shows when no Faithful is free (M2) | 7 |
| Marks draw over the slot row and banners; marks tiny and low contrast, `MARK_R` 2 (M2, M3 T7, M4 T6) | 6 |
| `test_miras_house` wording says ten grieving, 10 s, five Believers (M2) | 7 |
| The route and acolyte banners fire after the swap (M4 final N4) | 7 |
| The seen swap's report crawls at the Vigil's half pace (M4 final N2) | 7 |

**Out of scope** (one line each):
- M1: "Campaign (Continue / New)" became one Campaign button plus New campaign on the night screen. This is the accepted M1 design.
- M1: free retries dodge bites. This is decision (a).
- M2: Venn's search loops all night. This is decision (e).
- M2: the 2:00 fire might ring the bell. This is decision (f).
- M2: a one-frame entry or conversion in the frame the house is destroyed. It lasts one frame and is never seen.
- M2: readers leave with `leave_shelter(false)`, ignoring an evacuation without a bell. An Unaware town calls none without the bell, and the bell fills the Gaze.
- M2: balance measured with whisper/doom/discord, and the miras play run losing to the Gaze. This is decision (g).
- M2: stray literal tabs in a `behaviour_check` line continuation. The tool only; nothing a player sees.
- M3 T1: a vacuous `judge_deaths(null)` check, `_doomed`'s private reach, old constants and test helpers without `##`, a hard-coded `Vector2(60,60)`. Test and style hygiene.
- M3 T2: the `SHRINE_HP` "one blow" doc claim, the test lacking a `40.0` literal, the niche render check, thin restore asserts. Test hygiene.
- M3 T3: `procession_director.gd:147`'s roster index range. It is safe (`corps == NONE`).
- M3 T4: a mutated caller array, `goal()` out of range after `finish()`, `start()` ignoring a detour. No caller reaches them today.
- M3 T5: leftover `_alive` copies in `WarningDirector`, `vigil_route.gd` and `temple_report.gd`. `WarningDirector` sits under exact gates, so this needs a refactor round of its own.
- M3 T6 and T7: the reviewers' remaining minors. Hygiene; T7's marks are Task 6.
- M3 T8: balance scales. This is decision (c).
- M3 T8: the "Through the faithful" bonus. This is decision (b).
- M3 T8: a kneeler who later flees keeps a place; `_call_prayers` may put non-kneelers at the kneel shrine. Both are tied to decision (b).
- M3 final: the dawn-loss wording and `faithful_near` (no dead code found). No change asked.
- M4 T1–T7: the reviewers' minors (5, 6, 4, 10, 7, 6, 8). Hygiene; T6's dust and diamond contrast are Task 6.
- M4 T4: `vigil_flame_director.gd:154` calls `_sort_citizens` directly. Style.
- M4 T5: the search event's strip time is fixed at 160 s. Cosmetic: the strip shows it from the start.
- M4 T6: a Discord at the door could park a beam on Wren; the result lines never reach Phase 2; a freed bearer var; the `--bench-beams` label on other missions. Tool and policy only.
- M4 T7: the Vigil Flame's balance (seed 2's policy loses at the swap). This is a policy limit.
- M4 T8: Last Judgement's frame-rate regression. This is decision (d).
- M4 final N3: the beams sweep about 6.7 units past the map's north edge. It is off screen at the mission's camera.
- M4 final: about 34 optional minors the final reviewer did not list one by one.

---

## File structure

| File | Responsibility |
|---|---|
| `src/game/campaign/campaign_text.gd` | `CAEL_LINES`, `SPEAKER`, `cael_line()` |
| `src/game/rules.gd` | `signal subtitle(text)` |
| `src/game/mission/mission_director.gd` | `_say(event)` |
| `src/game/ui/hud.gd` | The subtitle queue and plate; bigger, outlined marks drawn under the banners and slots |
| `src/game/mission/miras_house_director.gd` | Says "venn" and "fire"; Venn's search guard; the Vigil's guard (`_free_faithful()`) |
| `src/game/mission/vigil_flame_director.gd` | Says "wren" and "light"; no route or acolyte banners after the swap; the seen swap's runner at his own pace |
| `src/game/mission/broken_lanterns_director.gd` | Says "drained" (first only) and "knights" |
| `src/game/ui/campaign_screen.gd` | Cards show the goal (`card_layout()`); `setup(state, pick)` |
| `src/game/ui/ending_screen.gd` | The drawn frame, Cael's name, `summary_text()` |
| `src/game/campaign/campaign_def.gd` | `MAX_DP` |
| `src/game/campaign/campaign_state.gd` | `ending_seen`; the `dp` clamp |
| `src/game/game.gd` | The board's mission back on leaving the campaign; `title:ending`; the night screen's pick; `--show=cael`, `--show=results-feast`; four FLOW steps |
| `src/game/mission/mission_book.gd` | The Feast is unscored |
| `src/game/mission/night_state.gd`, `src/game/mission.gd` | An unscored night's result |
| `src/game/ui/results_screen.gd` | `plain_rows()`; "Solved by" only when the result says |
| `tools/dev/behaviour_check.gd` | The `feast` scenario; `judgement` prints its budget, with `--aim=rich`; the Festival policy casts a drafted Heaven Splitter |
| `tests/test_cael_lines.gd` | **New** |
| `tests/test_hud.gd`, `test_miras_house.gd`, `test_vigil_flame.gd`, `test_broken_lanterns.gd`, `test_campaign_screens.gd`, `test_campaign.gd`, `test_flow.gd`, `test_night.gd`, `test_mission_book.gd` | New checks |
| `docs/KAK_Version_0.10_Summary.md`, `README.md` | Task 9 (controller) |

---

## Milestone 5 — Story and balance

### Task 1: Cael's voice on the HUD

**Files:**
- Modify: `src/game/campaign/campaign_text.gd`, `src/game/rules.gd`, `src/game/mission/mission_director.gd`, `src/game/ui/hud.gd`, `src/game/game.gd` (`--show=cael`), `tests/test_hud.gd`, `tests/run_all.gd`
- Create: `tests/test_cael_lines.gd`

**Interfaces:**
- Consumes: `Rules.mission: MissionDef` (`.id`), `Hud.SCREEN_W`, `UiTheme.width()`.
- Produces:
  - `CampaignText.CAEL_LINES: Dictionary` (mission id → {event → line}), `CampaignText.SPEAKER := "Cael"`, `static func CampaignText.cael_line(mission_id: String, event: String) -> String`;
  - `Rules`: `signal subtitle(text: String)`;
  - `MissionDirector`: `func _say(event: String) -> void`;
  - `Hud`: `SUBTITLE_SECONDS := 4.0`, `SUBTITLE_TOP := 140.0`, `SUBTITLE_GAP := 6.0`, `func push_subtitle(text: String) -> void`, `func subtitles() -> PackedStringArray`, `static func subtitle_width(text: String) -> float`, `static func speaker() -> String`.
  - Event ids, used by Task 2: `"venn"`, `"fire"` (miras_house), `"wren"`, `"light"` (vigil_flame), `"drained"`, `"knights"` (broken_lanterns).

- [ ] **Step 1: Record the references.** Run Import and Tests (expect 3567; report the count), then:
  - `--scenario=miras --case=play`;
  - `--scenario=lanterns --case=none --seed=1`;
  - `--scenario=flame --case=none --seed=1`;
  - `--scenario=night --path=festival --act1=win --act2=win --act3=win`;
  - `--scenario=night --path=procession --act1=win --act2=win --act3=win`;
  - `--scenario=judgement`.

  Keep every `BEHAVIOUR … result …`, `BEHAVIOUR night end …`, `BEHAVIOUR judgement end …` and `BEHAVIOUR checksum=…` line in the task report. Compare the miras and lanterns lines with Global Constraints and report any difference before going on. The night and judgement lines are the "before" for Task 8.

- [ ] **Step 2: Write the failing tests.** Create `tests/test_cael_lines.gd`:

```gdscript
extends RefCounted
## v0.10 M5 Cael's lines during missions (spec §5.2): the words, kept in CampaignText as the spec gives them; each fits
## the screen as the HUD shows it, his name before it; a director speaks only the lines its own mission has.

## The spec's table, word for word: [mission, event, line].
const SPEC := [["miras_house", "venn", "Venn. She lit Mira's pyre."],
	["miras_house", "fire", "They're burning her again. Get them out."],
	["vigil_flame", "wren", "The boy wants that lantern. Let him have it."],
	["vigil_flame", "light", "He's looking. Don't let him see the boy."],
	["broken_lanterns", "drained", "Feel that? That was his."],
	["broken_lanterns", "knights", "Odran's knights. He's frightened."]]


static func run(t) -> void:
	var wrong := PackedStringArray()
	var wide := PackedStringArray()
	for row: Array in SPEC:
		var said := CampaignText.cael_line(String(row[0]), String(row[1]))
		if said != String(row[2]):
			wrong.append("%s/%s" % [row[0], row[1]])
		# Review focus 5: each fits the screen with his name before it, 16 px in from either side.
		if Hud.subtitle_width(said) > Hud.SCREEN_W - 32.0:
			wide.append("%s/%s %.0f px" % [row[0], row[1], Hud.subtitle_width(said)])
	t.check(wrong.is_empty(), "Cael's six lines are the spec's (wrong: %s)" % ", ".join(wrong))
	t.check(wide.is_empty(), "each fits the screen with his name before it (too wide: %s)" % ", ".join(wide))
	t.check(CampaignText.cael_line("miras_house", "nonsense") == "" and CampaignText.cael_line("warning", "venn") == "",
		"an event or a mission he has no line for gives none")
	t.check(Hud.speaker() == "CAEL", "the HUD names him (%s)" % Hud.speaker())

	var rules := Rules.new()
	rules.mission = MissionBook.miras_house()
	var d := MissionDirector.new()
	d.rules = rules
	var heard := []
	rules.subtitle.connect(func(text: String) -> void: heard.append(text))
	d._say("venn")
	d._say("nonsense")
	t.check(heard == [CampaignText.cael_line("miras_house", "venn")],
		"a director speaks its mission's line, and only that (%s)" % [heard])
	rules.mission = MissionBook.warning()
	d._say("venn")
	t.check(heard.size() == 1, "The Warning has no lines of his")
	rules.mission = null
	d._say("venn")
	t.check(heard.size() == 1, "nor does a director with no mission")
	rules.free()
```

  Register `"res://tests/test_cael_lines.gd",` at the end of `SUITES` in `tests/run_all.gd`.

  In `tests/test_hud.gd`, insert just after the `hud.advance(Hud.BANNER_SECONDS + 0.1)` that follows the "THEY SHAKE OFF THE WHISPER" check, before the six-slot block:

```gdscript
	# Cael's lines (v0.10 M5): a queue of their own beside the banners, each up SUBTITLE_SECONDS in turn (review focus 1:
	# two close together and a banner with them -- none lost, none cut short, the banners at their own pace).
	rules.banner.emit("THE INQUISITOR SEARCHES")
	rules.subtitle.emit("Venn. She lit Mira's pyre.")
	rules.subtitle.emit("They're burning her again. Get them out.")
	t.check(hud.banners().size() == 1 and hud.subtitles() == PackedStringArray(["Venn. She lit Mira's pyre.",
		"They're burning her again. Get them out."]), "a line shows beside its banner, the next waits (%s)" % [hud.subtitles()])
	hud.advance(Hud.BANNER_SECONDS + 0.1)
	t.check(hud.banners().is_empty() and hud.subtitles().size() == 2, "a line outlasts its banner")
	hud.advance(Hud.SUBTITLE_SECONDS - Hud.BANNER_SECONDS)
	t.check(hud.subtitles() == PackedStringArray(["They're burning her again. Get them out."]),
		"then gives way to the next (%s)" % [hud.subtitles()])
	hud.advance(Hud.SUBTITLE_SECONDS - 0.1)
	t.check(hud.subtitles().size() == 1, "which lost none of its own time waiting")
	hud.advance(0.2)
	t.check(hud.subtitles().is_empty(), "and goes when its time is up")
	t.check(Hud.SUBTITLE_SECONDS > Hud.BANNER_SECONDS, "a line, a sentence to read, stays longer than a banner")
```

- [ ] **Step 3: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `cael_line` or `subtitle`.

- [ ] **Step 4: The words.** In `src/game/campaign/campaign_text.gd`:
  - Change the header's first sentence to: `## The Lantern campaign's words (v0.10, spec §5), kept apart from its logic so a writing change never touches it: Cael's`, then `## memory fragments, his lines during the Night 2 missions, the choice cards' lines, the titles a path gives the god, and`, then `## the endings. Every name is a placeholder the user may change.`
  - After `CARD_LINES`, add:

```gdscript
## Cael's lines during the Night 2 missions (spec §5.2), by mission and by the event that brings them: each is shown as a
## subtitle under the banners when its event happens (MissionDirector._say()). A mission or event with no line has none.
const CAEL_LINES := {
	"miras_house": {"venn": "Venn. She lit Mira's pyre.", "fire": "They're burning her again. Get them out."},
	"vigil_flame": {"wren": "The boy wants that lantern. Let him have it.",
		"light": "He's looking. Don't let him see the boy."},
	"broken_lanterns": {"drained": "Feel that? That was his.", "knights": "Odran's knights. He's frightened."},
}
## Who speaks in a mission: the HUD names him before each line.
const SPEAKER := "Cael"
```

  - At the end of the file, add:

```gdscript


## Cael's line for `event` in the mission `mission_id`, or "" when he has none.
static func cael_line(mission_id: String, event: String) -> String:
	var lines: Dictionary = CAEL_LINES.get(mission_id, {})
	return String(lines.get(event, ""))
```

- [ ] **Step 5: The signal and `_say()`.**
  - In `src/game/rules.gd`, after `signal banner(text: String)` and its comment, add:

```gdscript
## Cael speaks (v0.10 M5, spec §5.2): a line of his, shown under the banners (the HUD's subtitle).
signal subtitle(text: String)
```

  - In `src/game/mission/mission_director.gd`, after `teardown()`, add:

```gdscript


## Cael speaks (v0.10 M5, spec §5.2): his line for `event` in this mission (CampaignText.CAEL_LINES), shown under the
## banners; nothing when he has none for it.
func _say(event: String) -> void:
	if rules == null or rules.mission == null:
		return
	var text := CampaignText.cael_line(rules.mission.id, event)
	if text != "":
		rules.subtitle.emit(text)
```

- [ ] **Step 6: The HUD's subtitle.** In `src/game/ui/hud.gd`:
  - After `const BANNER_SECONDS := 2.2`, add:

```gdscript
## Cael's lines (v0.10 M5, spec §5.2): how long one stays up (longer than a banner: it is a sentence to read), the top of
## its plate (just under the banner's bar, 116 to 136), and the gap between his name and the line.
const SUBTITLE_SECONDS := 4.0
const SUBTITLE_TOP := 140.0
const SUBTITLE_GAP := 6.0
```

  - After `var _banners: Array = []`, add:

```gdscript
## Cael's lines waiting their turn (v0.10 M5): [text, seconds shown].
var _subtitles: Array = []
```

  - In `setup()`, after `_rules.banner.connect(push_banner)`, add `_rules.subtitle.connect(push_subtitle)`.
  - In `advance()`, replace these lines:

```gdscript
	# Only the one on screen (index 0, the only one _draw_banners() ever reads) ages: a banner waiting behind
	# it must not lose part of its own showing to the time it spent queued.
	if not _banners.is_empty():
		_banners[0][1] += delta
	while not _banners.is_empty() and float(_banners[0][1]) >= BANNER_SECONDS:
		_banners.pop_front()
```

  with:

```gdscript
	_age(_banners, delta, BANNER_SECONDS)
	_age(_subtitles, delta, SUBTITLE_SECONDS)
```

  - In the same function, change the animation condition's `or not _banners.is_empty()` to `or not _banners.is_empty() or not _subtitles.is_empty()`.
  - After `advance()`, add:

```gdscript


## Ages the one on screen of a queue of [text, seconds shown] and lets go of those whose time is up. Only the one on screen
## (index 0, the only one drawn) ages: one waiting behind it must not lose part of its own showing to the time it spent
## queued.
static func _age(queue: Array, delta: float, seconds: float) -> void:
	if not queue.is_empty():
		queue[0][1] += delta
	while not queue.is_empty() and float(queue[0][1]) >= seconds:
		queue.pop_front()
```

  - After `banners()`, add:

```gdscript


## Cael's line (v0.10 M5): queued behind any still showing, as banners are.
func push_subtitle(text: String) -> void:
	_subtitles.append([text, 0.0])


func subtitles() -> PackedStringArray:
	var out := PackedStringArray()
	for s in _subtitles:
		out.append(String(s[0]))
	return out


## Who speaks, as the HUD names him.
static func speaker() -> String:
	return CampaignText.SPEAKER.to_upper()


## How wide a line is on screen: his name, the gap, then the line.
static func subtitle_width(text: String) -> float:
	return UiTheme.width(speaker(), UiTheme.SIZE_SMALL) + SUBTITLE_GAP + UiTheme.width(text, UiTheme.SIZE_BODY)
```

  - In `_draw()`, after `_draw_banners(w)`, add `_draw_subtitle(w)`.
  - After `_draw_banners()`, add:

```gdscript


## Cael's line under the banner's bar (v0.10 M5): on a dark plate, his name small in gold, then the line in the body's
## light text; it comes up over 0.2 s and fades over its last 0.4 s.
func _draw_subtitle(w: float) -> void:
	if _subtitles.is_empty():
		return
	var text := String(_subtitles[0][0])
	var age := float(_subtitles[0][1])
	var fade := clampf((SUBTITLE_SECONDS - age) / 0.4, 0.0, 1.0) * clampf(age / 0.2, 0.0, 1.0)
	var who := speaker()
	var who_w := UiTheme.width(who, UiTheme.SIZE_SMALL)
	var x := roundf((w - subtitle_width(text)) * 0.5)
	draw_rect(Rect2(x - 6.0, SUBTITLE_TOP, subtitle_width(text) + 12.0, 17.0), Color(0.03, 0.03, 0.05, 0.72 * fade))
	var gold := UiTheme.COL_GOLD
	gold.a = fade
	var body := UiTheme.COL_TEXT
	body.a = fade
	UiTheme.text(self, Vector2(x, SUBTITLE_TOP + 12.0), who, UiTheme.SIZE_SMALL, gold)
	UiTheme.text(self, Vector2(x + who_w + SUBTITLE_GAP, SUBTITLE_TOP + 13.0), text, UiTheme.SIZE_BODY, body)
```

- [ ] **Step 7: A photograph of a line.** In `src/game/game.gd`'s `_ready()`:
  - Change the match arm `"miras":` to `"miras", "cael":`. Add to its comment: `## cael (v0.10 M5) is the same, with Venn's banner and Cael's line under it.`
  - In the `--capture` branch, after the `flame-beams` block, add:

```gdscript
		if show == "cael" and is_instance_valid(_mission) and is_instance_valid(_mission._hud):
			# Cael's line under its event's banner (v0.10 M5), for the photograph of the subtitle.
			_mission._hud.push_banner("THE INQUISITOR SEARCHES")
			_mission._hud.push_subtitle(CampaignText.cael_line(MissionBook.MIRAS_HOUSE, "venn"))
```

- [ ] **Step 8: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`, the count up by the new checks.
- [ ] **Step 9: Photograph and check by eye.** `--show=cael`:
  - the line sits under the banner's bar, centred, readable over the town;
  - "CAEL" is in gold, and nothing overlaps the Gaze bar or the event strip.

  Then `--show=miras`: unchanged from M4.
- [ ] **Step 10: The references.** Run `--scenario=miras --case=play` and `--scenario=lanterns --case=none --seed=1`. Expected: identical to Step 1. No director speaks yet.
- [ ] **Step 11: Commit.**

```bash
git add src/game/campaign/campaign_text.gd src/game/rules.gd src/game/mission/mission_director.gd src/game/ui/hud.gd src/game/game.gd tests/test_cael_lines.gd tests/test_cael_lines.gd.uid tests/test_hud.gd tests/run_all.gd
git commit -m "feat: Cael's lines on the HUD: a subtitle under the banners, the words in CampaignText (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 2: Cael speaks in the three Night 2 missions

**Files:**
- Modify: `src/game/mission/miras_house_director.gd`, `src/game/mission/vigil_flame_director.gd`, `src/game/mission/broken_lanterns_director.gd`, `tests/test_miras_house.gd`, `tests/test_vigil_flame.gd`, `tests/test_broken_lanterns.gd`

**Interfaces:**
- Consumes: `MissionDirector._say(event)`, `Rules.subtitle`, `CampaignText.cael_line()` (Task 1). The tests' `_setup()`, `_run()`, `_arrive()`, `_done()`, `_wren_now()`, `_do_swap()`, `_away()`, `_break()` as they are.
- Produces: each of the three test files' `_setup()` dictionary gains `"lines"`, an untyped array of every subtitle emitted (Task 7 reads it).

- [ ] **Step 1: Capture the lines in each test's setup.** In `tests/test_miras_house.gd`, `tests/test_vigil_flame.gd` and `tests/test_broken_lanterns.gd`, `_setup()`:
  - after `rules.banner.connect(...)`, add:

```gdscript
	var lines := []
	rules.subtitle.connect(func(text: String) -> void: lines.append(text))
```

  - in the returned dictionary, after `"banners": banners`, add `, "lines": lines`.

- [ ] **Step 2: Write the failing tests.**
  - In `tests/test_miras_house.gd`, add `_lines(t)` to `run()` after `_focus(t)`, and at the end of the file:

```gdscript


## Cael's lines (v0.10 M5, spec §5.2): as the Inquisitor sets out, and as the house burns. Review focus 2: a dead
## Inquisitor never searches, and he does not name her.
static func _lines(t) -> void:
	var s := _setup()
	var lines: Array = s.lines
	_run(s, MirasHouseDirector.VENN_AT + DT)
	t.check(lines == [CampaignText.cael_line(MissionBook.MIRAS_HOUSE, "venn")],
		"as the Inquisitor sets out, Cael names her (%s)" % [lines])
	_run(s, MirasHouseDirector.FIRE_AT - MirasHouseDirector.VENN_AT)
	t.check(lines.size() == 2 and lines[1] == CampaignText.cael_line(MissionBook.MIRAS_HOUSE, "fire"),
		"as the house burns, he speaks again (%s)" % [lines])
	_done(s)

	var s2 := _setup()
	var d2: MirasHouseDirector = s2.d
	(s2.crowd as Crowd)._field.kill(d2.venn, &"doom")
	_run(s2, MirasHouseDirector.VENN_AT + DT)
	t.check((s2.lines as Array).is_empty(), "with the Inquisitor dead, nothing is said of her (%s)" % [s2.lines])
	_done(s2)
```

  - In `tests/test_vigil_flame.gd`, add `_lines(t)` to `run()` after `_teardown(t)`, and at the end of the file:

```gdscript


## Cael's lines (v0.10 M5, spec §5.2): as Wren comes, and as the light wakes at the swap. Review focus 2: with nobody
## left to be Wren, nothing is said of the boy.
static func _lines(t) -> void:
	var s := _setup()
	var lines: Array = s.lines
	_wren_now(s.d)
	t.check(lines == [CampaignText.cael_line(MissionBook.VIGIL_FLAME, "wren")], "as Wren comes, Cael speaks (%s)" % [lines])
	_done(s)

	var s2 := _setup()
	_do_swap(s2)
	var lines2: Array = s2.lines
	t.check(lines2.size() == 2 and lines2[1] == CampaignText.cael_line(MissionBook.VIGIL_FLAME, "light"),
		"as the swap wakes the light, he speaks again (%s)" % [lines2])
	_done(s2)

	var s3 := _setup()
	var d3: VigilFlameDirector = s3.d
	for p in (s3.crowd as Crowd).citizens:
		if not d3.faithful.has(p):
			p.inside = true
	_wren_now(d3)
	t.check(d3.no_wren and (s3.lines as Array).is_empty(), "with nobody to be Wren, nothing is said of him (%s)" % [s3.lines])
	_done(s3)
```

  - In `tests/test_broken_lanterns.gd`, add `_lines(t)` to `run()` after `_focus(t)`, and at the end of the file:

```gdscript


## Cael's lines (v0.10 M5, spec §5.2): at the first shrine drained (review focus 3: once a night, never at a later one),
## and as the Knights come.
static func _lines(t) -> void:
	var s := _setup()
	var d: BrokenLanternsDirector = s.d
	var lines: Array = s.lines
	_away(d)
	_break(d.shrines[0])
	_run(s, BrokenLanternsDirector.DRAIN_SECONDS - 1.0)
	t.check(lines.is_empty(), "nothing while the first shrine drains (%s)" % [lines])
	_run(s, 1.5)
	t.check(lines == [CampaignText.cael_line(MissionBook.BROKEN_LANTERNS, "drained")],
		"the first shrine drained, Cael speaks (%s)" % [lines])
	_away(d)
	_break(d.shrines[1])
	_run(s, BrokenLanternsDirector.DRAIN_SECONDS + 0.5)
	t.check(d.drained_count() == 2 and lines.size() == 1, "the second says nothing more (%d drained, %s)" % [d.drained_count(), lines])
	d.timeline.step(BrokenLanternsDirector.KNIGHTS_AT)
	t.check(lines.size() == 2 and lines[1] == CampaignText.cael_line(MissionBook.BROKEN_LANTERNS, "knights"),
		"as the Knights come, he speaks again (%s)" % [lines])
	_done(s)
```

- [ ] **Step 3: Run the tests to verify they fail.** Expected: three FAILs, one per `_lines` ("as the Inquisitor sets out…", "as Wren comes…", "the first shrine drained…"), and no SCRIPT ERROR.

- [ ] **Step 4: The hooks.**
  - `src/game/mission/miras_house_director.gd`:
    - at the end of `_venn_starts()`, after `venn.go_duty(_venn_houses[0])`, add `_say("venn")`;
    - at the end of `_burn()`, after `_flush()`, add `_say("fire")`.
  - `src/game/mission/vigil_flame_director.gd`:
    - in `_wren_comes()`, after `_tick = 0.0` (the last line), add `_say("wren")`;
    - in `_phase2_begin()`, after `rules.banner.emit("THE SPIRE FLARES")`, add `_say("light")`.

    `bench_beams()` lights the beams without `_phase2_begin()`, so the bench and the photograph stay silent.
  - `src/game/mission/broken_lanterns_director.gd`:
    - in `_drain()`, after the `rules.banner.emit("A LANTERN IS DRAINED (%d / %d)" …)` line, add:

```gdscript
		if drained.size() == 1:
			_say("drained")  # Cael, at the first only (spec §5.2)
```

    - at the end of `_knights_come()`, after `_tend_knights()`, add `_say("knights")`.

- [ ] **Step 5: Run the tests to verify they pass.** Expected: `failures=0`.
- [ ] **Step 6: The references.**
  - `--scenario=miras --case=play`: identical to Task 1 Step 1. A subtitle changes nothing in the world.
  - `--scenario=lanterns --case=none --seed=1`: identical, checksum 424350965.
  - `--scenario=flame --case=none --seed=1`: same outcome.
- [ ] **Step 7: Commit.**

```bash
git add src/game/mission/miras_house_director.gd src/game/mission/vigil_flame_director.gd src/game/mission/broken_lanterns_director.gd tests/test_miras_house.gd tests/test_vigil_flame.gd tests/test_broken_lanterns.gd
git commit -m "feat: Cael speaks in Mira's House, the Vigil Flame and Broken Lanterns (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 3: The night screen's cards and the endings

**Files:**
- Modify: `src/game/ui/campaign_screen.gd`, `src/game/ui/ending_screen.gd`, `tests/test_campaign_screens.gd`

**Interfaces:**
- Consumes: `CampaignText.SPEAKER` (Task 1), `CampaignState.title()`, `.nights_won`, `.bites`, `.options()`, `.mission()`; `MissionDef.goal`.
- Produces:
  - `CampaignScreen.setup(state: CampaignState, pick := "") -> CampaignScreen`: a `pick` among tonight's cards is chosen at once;
  - `static func CampaignScreen.card_layout(def: MissionDef, s: CampaignState, r: Rect2) -> Dictionary` with keys `goal: PackedStringArray`, `line: PackedStringArray`, `goal_top: float`, `goal_end: float`, `line_top: float`;
  - `EndingScreen.setup(ending: String, fragment: String, summary_line := "") -> EndingScreen`, `var summary: String`;
  - `static func EndingScreen.summary_text(s: CampaignState) -> String`.

  Task 4 wires `pick` and `summary` from `game.gd`.

- [ ] **Step 1: Write the failing tests.** In `tests/test_campaign_screens.gd`, insert just before `night.free()` (the first one, after the double-click checks):

```gdscript
	# v0.10 M5: a card chosen before (Back from the draft, Pause > Campaign) is chosen again; a pick tonight does not offer
	# chooses nothing.
	var back := CampaignScreen.new()
	back.setup(s, MissionBook.VIGIL_FLAME)
	t.check(back.chosen == MissionBook.VIGIL_FLAME and back.selected == 1, "a card chosen before is chosen again (%s)" % back.chosen)
	back.free()
	var stray := CampaignScreen.new()
	stray.setup(s, MissionBook.LAST_JUDGEMENT)
	t.check(stray.chosen == "" and stray.selected == 0, "a mission tonight does not offer chooses nothing")
	stray.free()

	# Spec §5.3 (v0.10 M5): every card shows its mission's goal, clear of Cael's line at its foot -- Night 2's three and
	# Night 3's two, in a sleeping and a warned town (review focus 5).
	var cramped := PackedStringArray()
	for n in [1, 2]:
		for rang in [false, true]:
			var cs := CampaignState.new()
			cs.night = n
			cs.bell_rang = rang
			var count := cs.options().size()
			for i in count:
				var def := cs.mission(String((cs.options()[i] as Dictionary).mission))
				var lay := CampaignScreen.card_layout(def, cs, CampaignScreen.card_rect(i, count))
				if (lay.goal as PackedStringArray).is_empty() or (lay.goal as PackedStringArray)[0] == "" \
						or float(lay.goal_end) > float(lay.line_top) - UiTheme.LINE_SMALL:
					cramped.append("%s %.0f/%.0f" % [def.id, float(lay.goal_end), float(lay.line_top)])
	t.check(cramped.is_empty(), "every card shows its goal, clear of Cael's line (cramped: %s)" % ", ".join(cramped))
```

  After the `eaten.free()` line, add:

```gdscript
	# The ending's last page closes on the campaign (v0.10 M5): the god's title, the nights won, the bites.
	var ts := CampaignState.new()
	ts.tally["theft"] = 1
	ts.last_path = "theft"
	ts.nights_won = 2
	ts.bites = 1
	t.check(EndingScreen.summary_text(ts) == "The Deceiver   Nights won 2   Bites 1 / 3",
		"the closing line: %s" % EndingScreen.summary_text(ts))
	var told := EndingScreen.new()
	told.setup(CampaignDef.FALSE_LANTERN, "vision", EndingScreen.summary_text(ts))
	t.check(told.summary == EndingScreen.summary_text(ts) and told.pages.size() == 2, "the ending keeps it for its last page")
	told.free()
```

- [ ] **Step 2: Run the tests to verify they fail.** Expected: a Parse Error naming `card_layout` or `summary_text` (or `setup` with too many arguments).

- [ ] **Step 3: The night screen.** In `src/game/ui/campaign_screen.gd`:
  - In the header, change "or a choice card per mission" to "or a choice card per mission, with its goal and Cael's line".
  - Replace `func setup(state: CampaignState) -> CampaignScreen:` and its first lines, up to and including `chosen = (options[0] as MissionDef).id`, with:

```gdscript
## `pick` (v0.10 M5) is the mission chosen before, back from the draft or Pause > Campaign: chosen again if tonight
## offers it.
func setup(state: CampaignState, pick := "") -> CampaignScreen:
	_state = state
	options = []
	for o: Dictionary in state.options():
		options.append(state.mission(String(o.mission)))
	if options.size() == 1:
		chosen = (options[0] as MissionDef).id
	elif pick != "":
		for i in options.size():
			if (options[i] as MissionDef).id == pick:
				selected = i
				chosen = pick
```

  - Before `_draw_card()`, add:

```gdscript
## A card's words laid out in `r` (v0.10 M5, spec §5.3): the goal's lines under the name and the path, and Cael's line at
## the foot. `goal_end` is the last goal line's baseline and `line_top` the first of Cael's, so a test can see they never
## meet.
static func card_layout(def: MissionDef, s: CampaignState, r: Rect2) -> Dictionary:
	var room := r.size.x - PAD * 2.0
	var goal := UiTheme.wrap(def.goal, room, UiTheme.SIZE_SMALL)
	var line := UiTheme.wrap(card_line(def, s), room, UiTheme.SIZE_SMALL)
	var goal_top := r.position.y + PAD + 12.0 + UiTheme.LINE_BODY + UiTheme.LINE_SMALL + 4.0
	var line_top := r.end.y - PAD - UiTheme.LINE_SMALL * float(maxi(line.size() - 1, 0))
	return {"goal": goal, "line": line, "goal_top": goal_top,
		"goal_end": goal_top + UiTheme.LINE_SMALL * float(maxi(goal.size() - 1, 0)), "line_top": line_top}
```

  - Replace `_draw_card()` whole with:

```gdscript
## One card, top to bottom: the mission's name, its path, its goal, then Cael's line in gold at the foot (spec §5.3). The
## chosen card wears the bright frame; the one the keyboard is on is lit.
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
	var lay := card_layout(def, _state, r)
	var text_col := UiTheme.COL_TEXT if on or i == selected else UiTheme.COL_DIM
	y = float(lay.goal_top)
	for line: String in lay.goal:
		UiTheme.text(_ui, Vector2(x, y), line, UiTheme.SIZE_SMALL, text_col)
		y += UiTheme.LINE_SMALL
	var foot := float(lay.line_top)
	for line: String in lay.line:
		UiTheme.text(_ui, Vector2(x, foot), line, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
		foot += UiTheme.LINE_SMALL
```

- [ ] **Step 4: The ending.** In `src/game/ui/ending_screen.gd`:
  - Add to the header: `## v0.10 M5: a drawn frame stands in for the panel art until the art pass; Cael's name stands under his words, and the last`, then `## page closes with a line on the campaign (summary_text()).`
  - After `const BUTTON_Y := 288.0`, add:

```gdscript
## The drawn frame (v0.10 M5): a second rule this far inside the panel's, a small gold diamond of this half size at each
## of its corners, and a short rule under the title.
const INNER := 6.0
const CORNER_R := 3.0
const RULE_W := 120.0
```

  - After `var page := 0`, add:

```gdscript
## The closing line on the campaign, under the last page ("" for none).
var summary := ""
```

  - Change `func setup(ending: String, fragment: String) -> EndingScreen:` to `func setup(ending: String, fragment: String, summary_line := "") -> EndingScreen:`, and add `summary = summary_line` as its first line.
  - Before `func turn()`, add:

```gdscript
## "The Deceiver   Nights won 2   Bites 1 / 3" (v0.10 M5): the god's title, the nights won and the bites.
static func summary_text(s: CampaignState) -> String:
	return "%s   Nights won %d   Bites %d / %d" % [s.title(), s.nights_won, s.bites, CampaignDef.MAX_BITES]
```

  - In `_draw_ui()`:
    - after `UiTheme.frame(_ui, PANEL, true)`, add `_draw_frame()`;
    - after the title's `UiTheme.text(...)` call, add:

```gdscript
	_ui.draw_line(Vector2(320.0 - RULE_W * 0.5, TITLE_Y + 12.0), Vector2(320.0 + RULE_W * 0.5, TITLE_Y + 12.0),
		UiTheme.COL_GOLD_DARK, 1.0)
```

    - after the text loop (`y += UiTheme.LINE_BODY`), before the note, add:

```gdscript
	var by := "- " + CampaignText.SPEAKER
	UiTheme.text(_ui, Vector2(roundf(320.0 + TEXT_W * 0.5 - UiTheme.width(by, UiTheme.SIZE_SMALL)), y + 2.0), by,
		UiTheme.SIZE_SMALL, UiTheme.COL_GOLD_DARK)
	y += UiTheme.LINE_SMALL
```

    - before `_menu.draw_on(_ui, _hover)`, add:

```gdscript
	if summary != "" and page == pages.size() - 1:
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(summary, UiTheme.SIZE_SMALL) * 0.5), BUTTON_Y - 22.0),
			summary, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
```

  - At the end of the file, add:

```gdscript


## The frame that stands in for the ending's panel (v0.10 M5): a second gold rule inside the panel's, a diamond at each
## of its corners.
func _draw_frame() -> void:
	var inner := PANEL.grow(-INNER)
	_ui.draw_rect(inner, UiTheme.COL_GOLD_DARK, false, 1.0)
	for c: Vector2 in [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]:
		_ui.draw_colored_polygon(PackedVector2Array([c + Vector2(0.0, -CORNER_R), c + Vector2(CORNER_R, 0.0),
			c + Vector2(0.0, CORNER_R), c + Vector2(-CORNER_R, 0.0)]), UiTheme.COL_GOLD)
```

- [ ] **Step 5: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`.
  - If a card is cramped, first check `UiTheme.wrap()` against the card's room. Then you may raise `CARD_H` up to 134 (tuning latitude).
  - Report the cramped line if raising `CARD_H` does not clear it. Do not shorten a goal: Prepare shows the same words.
- [ ] **Step 6: Photographs.** `--show=campaign-choice` (three cards with goals, Cael's lines at the foot) and `--show=ending` (the frame, "- Cael" under each page's words, the Vision then the False Lantern page). The `--show=ending` state has no summary until Task 4 wires it; that is expected here.
- [ ] **Step 7: Commit.**

```bash
git add src/game/ui/campaign_screen.gd src/game/ui/ending_screen.gd tests/test_campaign_screens.gd
git commit -m "feat: the night's cards show their goal; the endings get a drawn frame and a closing line (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 4: The campaign's flow, mended

**Files:**
- Modify: `src/game/campaign/campaign_def.gd`, `src/game/campaign/campaign_state.gd`, `src/game/game.gd`, `tests/test_campaign.gd`, `tests/test_flow.gd`

**Interfaces:**
- Consumes: `CampaignScreen.setup(state, pick)`, `EndingScreen.setup(ending, fragment, summary_line)`, `EndingScreen.summary_text()` (Task 3).
- Produces:
  - `CampaignDef.MAX_DP` (15);
  - `CampaignState.ending_seen: bool`, written and read as `ending_seen`;
  - `Game.FLOW["title:ending"] = Screen.ENDING`;
  - `Game._on_ending_action(what: String) -> void`;
  - FLOW grows by four steps, to 86.

- [ ] **Step 1: Write the failing tests.**
  - In `tests/test_campaign.gd` `_save()`, insert just before `DirAccess.remove_absolute(...)`:

```gdscript
	# v0.10 M5: a hand-edited budget above anything a campaign can reach is pulled back (review focus 4).
	var hi := ConfigFile.new()
	hi.set_value(CampaignState.SECTION, "dp", 99)
	t.check(CampaignDef.MAX_DP == 15 and CampaignState.read(hi).dp == CampaignDef.MAX_DP,
		"a budget past every bonus reads as %d (%d)" % [CampaignDef.MAX_DP, CampaignState.read(hi).dp])
	# The ending, once seen, stays seen through the save.
	var e := CampaignState.new()
	e.ending = CampaignDef.FALSE_LANTERN
	e.ending_seen = true
	var ecfg := ConfigFile.new()
	e.write(ecfg)
	t.check(CampaignState.read(ecfg).ending_seen, "an ending seen is remembered")
	# Review focus 4: a save from before M5 that reached its ending has no ending_seen: owed, so shown once more.
	var old := ConfigFile.new()
	old.set_value(CampaignState.SECTION, "ending", CampaignDef.NEW_FAITH)
	t.check(CampaignState.read(old).ending == CampaignDef.NEW_FAITH and not CampaignState.read(old).ending_seen,
		"an older save's ending reads as not yet seen")
	var none := ConfigFile.new()
	none.set_value(CampaignState.SECTION, "ending_seen", true)
	t.check(not CampaignState.read(none).ending_seen, "and a campaign with no ending has nothing seen")
```

  - In `tests/test_flow.gd`, after the `ending:title` check, add:

```gdscript
	t.check(Game.next_screen("title:ending") == Game.Screen.ENDING, "an ending not yet seen opens from the title (v0.10 M5)")
```

- [ ] **Step 2: Run the tests to verify they fail.** Expected: a Parse Error naming `MAX_DP` or `ending_seen`.

- [ ] **Step 3: The clamp and `ending_seen`.**
  - In `src/game/campaign/campaign_def.gd`, after `const MAX_BITES := 3`, add:

```gdscript
## The most Divine Power a campaign can hold (v0.10 M5): every night before the finale won with its bonus. A save that
## says more was edited by hand, and is pulled back to it.
const MAX_DP := START_DP + FINALE * (WIN_DP + BONUS_DP)
```

    `FINALE` is declared further down. A GDScript constant may refer to one declared later in the same class. If the parser objects, move `MAX_DP` below `FINALE`.
  - In `src/game/campaign/campaign_state.gd`:
    - after `var ending := ""`, add:

```gdscript
## The ending has been shown (v0.10 M5): until it has -- the game quit on the last night's Results -- Campaign shows it
## before it starts afresh.
var ending_seen := false
```

    - in `write()`, after the `ending` line, add `cfg.set_value(SECTION, "ending_seen", ending_seen)`;
    - in `read()`, change the `dp` line to `s.dp = clampi(int(cfg.get_value(SECTION, "dp", CampaignDef.START_DP)), CampaignDef.MIN_DP, CampaignDef.MAX_DP)`;
    - in `read()`, after the "three bites" block, add `s.ending_seen = s.ending != "" and bool(cfg.get_value(SECTION, "ending_seen", false))`;
    - in `read()`'s comment, add: `A budget is held between the floor and MAX_DP.`

- [ ] **Step 4: The game's flow.** In `src/game/game.gd`:
  - In `FLOW`, after `"ending:title": Screen.TITLE,`, add `"title:ending": Screen.ENDING,` with the comment `# An ending not yet seen (v0.10 M5: the game quit on the last night's Results) opens from the title's Campaign.`
  - In `go_to()`, before `if to == Screen.TITLE or to == Screen.BOARD:`, add:

```gdscript
	# Leaving the campaign (v0.10 M5), whichever way -- its Title, or its ending: the board's own mission and loadout come
	# back, so Missions opens on the last board pick rather than the campaign's last night.
	if (to == Screen.TITLE or to == Screen.BOARD) and _in_campaign:
		mission_id = save.last_mission
		loadout = starting_loadout(save, mission_id)
```

  - In `go_to()`'s `Screen.CAMPAIGN` arm, change `night.setup(save.campaign)` to `night.setup(save.campaign, mission_id)`. After Back or Pause → Campaign, `mission_id` is tonight's pick; from the title it is a board mission, which no choice card offers.
  - In `go_to()`'s `Screen.ENDING` arm, replace the `end.setup(...)` and `end.action.connect(...)` lines with:

```gdscript
			end.setup(save.campaign.ending, save.campaign.ending_fragment(), EndingScreen.summary_text(save.campaign))
			end.action.connect(_on_ending_action)
```

  - In `_on_campaign_action()`'s `"title"` arm, delete the two lines `mission_id = save.last_mission` and `loadout = starting_loadout(save, mission_id)`. `go_to()` does it now. Change the function's comment's "where the board's mission is the one last picked there" to "(go_to() puts the board's mission back)".
  - After `_results_action()`, add:

```gdscript


## The ending's last page turned, or Esc (v0.10 M5): the ending has been seen, so Campaign next begins afresh.
func _on_ending_action(what: String) -> void:
	if save.campaign != null and not save.campaign.ending_seen:
		save.campaign.ending_seen = true
		save.save_to(save_path)
	on_action("ending:" + what)
```

  - In `_on_title_action()`'s `"campaign"` arm, before the existing "A campaign that has reached its ending is over" comment, add:

```gdscript
			# An ending not yet seen (v0.10 M5: the game quit on the last night's Results) is shown first.
			if save.campaign != null and save.campaign.ending != "" and not save.campaign.ending_seen:
				on_action("title:ending")
				return
```

- [ ] **Step 5: FLOW's four steps.** In `_flow_campaign()`:
  - Replace:

```gdscript
	night.choose(MissionBook.VIGIL_FLAME)
	night.click(night.button_rect("draft").get_center())
	prep = _screen_node as PrepareScreen
```

  with:

```gdscript
	night.choose(MissionBook.VIGIL_FLAME)
	night.click(night.button_rect("draft").get_center())
	# v0.10 M5: Back from the draft keeps tonight's card chosen.
	_on_prepare_action("back", _screen_node as PrepareScreen)
	night = _screen_node as CampaignScreen
	step.call(screen == Screen.CAMPAIGN and night != null and night.chosen == MissionBook.VIGIL_FLAME,
		"Back from the draft keeps the Vigil Flame chosen (%s)" % (night.chosen if night != null else "-"))
	night.click(night.button_rect("draft").get_center())
	prep = _screen_node as PrepareScreen
```

  - After the step "turning its last page returns to the title, the campaign left", add:

```gdscript
	step.call(mission_id == save.last_mission and loadout == starting_loadout(save, mission_id) and save.campaign.ending_seen,
		"leaving by the ending puts the board's own mission back (%s), the ending seen" % mission_id)

	# v0.10 M5: an ending never seen (the game quit on the last Results) opens from Campaign before a fresh one.
	save.campaign.ending_seen = false
	(_screen_node as TitleScreen).action.emit("campaign")
	var owed := _screen_node as EndingScreen
	step.call(screen == Screen.ENDING and owed != null and owed.pages.size() == 2 and owed.summary != "",
		"an ending left unseen opens from Campaign, with its closing line")
	owed.action.emit("title")
	step.call(screen == Screen.TITLE and save.campaign.ending_seen and save.campaign.ending == CampaignDef.FALSE_LANTERN,
		"and once seen it is done")
```

  - The existing "after an ending, Campaign begins a fresh one" step follows unchanged.

- [ ] **Step 6: Run the tests to verify they pass.** Run Tests. Expected: `failures=0`.
- [ ] **Step 7: Run FLOW.** Expected: `failures=0`, **86** steps. Every step that passed before passes again; name any that changed.
- [ ] **Step 8: Photograph** `--show=ending`: the last page now carries the closing line ("The Forgotten   Nights won 0   Bites 0 / 3" for that sample state).
- [ ] **Step 9: Commit.**

```bash
git add src/game/campaign/campaign_def.gd src/game/campaign/campaign_state.gd src/game/game.gd tests/test_campaign.gd tests/test_flow.gd
git commit -m "fix: the campaign's flow: the board's mission back after it, an unseen ending shown, the night's pick kept, DP clamped (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 5: The Feast's results

**Files:**
- Modify: `src/game/mission/mission_book.gd`, `src/game/mission/night_state.gd`, `src/game/mission.gd`, `src/game/ui/results_screen.gd`, `src/game/game.gd` (`--show=results-feast`), `tests/test_night.gd`, `tests/test_mission_book.gd`, `tests/test_campaign_screens.gd`

**Interfaces:**
- Consumes: `Rules.result()`'s `goal` and `bonuses`; `ResultsScreen.solved_text()`.
- Produces:
  - `NightState.result(final: Dictionary, mission_id: String, scored := true) -> Dictionary`. Unscored, it carries no `score`, `rank` or `lines`, and its `goal` is the act's own;
  - `static func ResultsScreen.plain_rows(result: Dictionary) -> Array` of `[label: String, value: String, ok: bool]`;
  - `Game.SAMPLE_FEAST_RESULT`.

- [ ] **Step 1: Write the failing tests.**
  - In `tests/test_night.gd`, after the check "and ends on the last act's reason", add:

```gdscript
	# v0.10 M5: a night of one unscored act (the campaign's Feast) has the act's own goal, bonuses and time, and no rank.
	var one := NightState.new()
	var act := {"won": true, "reason": "festival", "time": 96.0, "bonuses": [{"label": "Before the bell", "earned": true}],
		"goal": {"label": "The festival is broken", "done": true}}
	one.record("festival", act, null)
	var fr := one.result(act, "feast_festival", false)
	t.check(not fr.has("score") and not fr.has("rank") and fr.won and String(fr.reason) == "festival"
		and String(fr.goal.label) == "The festival is broken" and (fr.bonuses as Array).size() == 1
		and is_equal_approx(float(fr.time), 96.0) and (fr.acts as Array).size() == 1,
		"an unscored night of one act: its own goal, bonus and time, no rank (%s)" % [fr.keys()])
	t.check(n.result(final, "long_night").has("rank"), "The Long Night keeps its rank")
```

  - In `tests/test_mission_book.gd`, after the Feast's first check, add:

```gdscript
	t.check(not fe.scored and not MissionBook.feast("procession").scored and MissionBook.long_night().scored,
		"the Feast is an unscored night (v0.10 M5); The Long Night is still scored")
```

  - In `tests/test_campaign_screens.gd`, before the `PauseMenu` block at the end, add:

```gdscript
	# v0.10 M5: the Feast's results -- its own goal and bonus, the time, no rank and no "Solved by" (it has none); The
	# Warning still says what solved it.
	var feast := {"mission": "feast_festival", "won": true, "reason": "festival", "time": 96.0,
		"goal": {"label": "The festival is broken", "done": true}, "bonuses": [{"label": "Before the bell", "earned": true}]}
	t.check(ResultsScreen.plain_rows(feast) == [["The festival is broken", "", true], ["Before the bell", "", true],
		["Time", "1:36", false]], "the Feast's rows (%s)" % [ResultsScreen.plain_rows(feast)])
	t.check(ResultsScreen.title_for(true, "festival") == "THE FEAST IS BROKEN"
		and MissionBook.get_mission("feast_festival").name == "The Festival", "named the Festival, not Act II")
	t.check((ResultsScreen.plain_rows(Game.SAMPLE_WARNING_RESULT).back() as Array) == ["Solved by", "VEIL", false],
		"The Warning still says what solved it")
```

- [ ] **Step 2: Run the tests to verify they fail.** Expected: a Parse Error naming `plain_rows`, or `result()` called with too many arguments.

- [ ] **Step 3: An unscored night.**
  - `src/game/mission/mission_book.gd`, in `feast()`:
    - replace `m.scored = true` with `m.scored = false  # one act, unscored (v0.10 M5): the campaign never used the score`;
    - add to `feast()`'s comment: `## Its results are its act's own (an unscored night): a one-act night cannot reach the three-act ranks.`
  - `src/game/mission/night_state.gd`:
    - change `func result(final: Dictionary, mission_id: String) -> Dictionary:` to `func result(final: Dictionary, mission_id: String, scored := true) -> Dictionary:`;
    - add to its comment: `## An unscored night (v0.10 M5: the campaign's Feast, one act) has no score, rank or table: its goal is the act's own.`
    - after the `for r in results:` loop, insert:

```gdscript
	if not scored:
		return {"mission": mission_id, "won": bool(final.get("won", false)), "reason": String(final.get("reason", "")),
			"time": time, "acts": acts, "path": path, "bonuses": final.get("bonuses", []),
			"goal": final.get("goal", {"label": "The night is yours", "done": bool(final.get("won", false))})}
```

  - `src/game/mission.gd`, in `_play_ending()`: change `finished.emit(_night.result(res, _def.id))` to `finished.emit(_night.result(res, _def.id, _def.scored))`.

- [ ] **Step 4: The results' rows.** In `src/game/ui/results_screen.gd`:
  - Before `_draw_unscored()`, add:

```gdscript
## An unscored result's rows (v0.08; v0.10 M5 the Feast's too), as [label, value, ok]: the goal and each bonus with a tick
## or a cross (value ""), the time, and "Solved by" only when the result says what solved it (The Warning's).
static func plain_rows(result: Dictionary) -> Array:
	var goal: Dictionary = result.get("goal", {})
	var rows := [[String(goal.get("label", "")), "", bool(goal.get("done", false))]]
	for b: Dictionary in result.get("bonuses", []):
		rows.append([String(b.get("label", "")), "", bool(b.get("earned", false))])
	rows.append(["Time", UiTheme.clock(float(result.get("time", 0.0))), false])
	if result.has("solved_by"):
		rows.append(["Solved by", solved_text(result), false])
	return rows
```

  - In `_draw_unscored()`, replace everything from `var y := PLAIN_TOP` up to (not including) `if bool(_result.get("best", false)):` with:

```gdscript
	var y := PLAIN_TOP
	var rows := plain_rows(_result)
	var ticks := 1 + (_result.get("bonuses", []) as Array).size()
	for i in rows.size():
		if i == ticks:
			# The rule between the ticked rows and the figures.
			_ui.draw_line(Vector2(PLAIN_L, y - 13.0), Vector2(PLAIN_R, y - 13.0), UiTheme.COL_GOLD_DARK, -1.0)
			y += 4.0
		var row: Array = rows[i]
		_plain_row(y, String(row[0]), String(row[1]), bool(row[2]))
		y += PLAIN_ROW
```

  - Update `_draw_unscored()`'s comment: "…the time it took, "Solved by" when the result has it (v0.10 M5), and NEW BEST! when it is one."

- [ ] **Step 5: A photograph of the Feast's results.** In `src/game/game.gd`:
  - After `SAMPLE_NIGHT_RESULT`, add:

```gdscript
## What --show=results-feast displays (v0.10 M5): the campaign's Feast won by breaking the festival, its bonus earned.
const SAMPLE_FEAST_RESULT := {
	"mission": "feast_festival", "won": true, "reason": "festival", "time": 96.0, "path": "",
	"acts": [{"act": "festival", "won": true, "reason": "festival", "bonuses": [{"label": "Before the bell", "earned": true}],
		"time": 96.0}],
	"goal": {"label": "The festival is broken", "done": true}, "bonuses": [{"label": "Before the bell", "earned": true}],
	"campaign": {"won": true, "dp_gain": 3, "dp": 13, "bites": 0, "ending": ""},
}
```

  - In `_ready()`'s match, after the `"results-night":` arm, add:

```gdscript
		"results-feast":
			result = SAMPLE_FEAST_RESULT.duplicate(true)
			go_to(Screen.RESULTS)
```

- [ ] **Step 6: Run the tests to verify they pass.** Expected: `failures=0`.
- [ ] **Step 7: FLOW and the night.**
  - FLOW: `failures=0`, 86. The Long Night's step still finds `rank`, and the campaign's Feast step still records the bite.
  - `--scenario=night --path=festival --act1=win --act2=win --act3=win`: identical to Task 1 Step 1.
- [ ] **Step 8: Photographs.**
  - `--show=results-feast`: "THE FEAST IS BROKEN", "The Festival", the goal and the bonus ticked, the time, no rank, Continue with its campaign line.
  - `--show=results-warning`: unchanged, "Solved by VEIL".
  - `--show=results-night`: unchanged.
- [ ] **Step 9: Commit.**

```bash
git add src/game/mission/mission_book.gd src/game/mission/night_state.gd src/game/mission.gd src/game/ui/results_screen.gd src/game/game.gd tests/test_night.gd tests/test_mission_book.gd tests/test_campaign_screens.gd
git commit -m "fix: the Feast's results are an unscored night's: its own goal, bonus and time, no three-act rank (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 6: The marks, bigger and under the banners

**Files:**
- Modify: `src/game/ui/hud.gd`, `tests/test_hud.gd`

**Interfaces:**
- Consumes: `MissionDirector.marks()` (`[Vector2, Color]` pairs).
- Produces: `Hud.MARK_R := 4.0`, `Hud.MARK_EDGE: Color`, `static func Hud.mark_shape(c: Vector2) -> PackedVector2Array`.

- [ ] **Step 1: Write the failing test.** In `tests/test_hud.gd`, after the six-slot block (`six_rules.free()`), add:

```gdscript
	# The marks over people (v0.10; M5 made them bigger and outlined, so they read on the cobbles): a diamond MARK_R each
	# way from its centre.
	var shape := Hud.mark_shape(Vector2(100.0, 100.0))
	t.check(Hud.MARK_R >= 4.0 and shape.size() == 4 and shape[0] == Vector2(100.0, 100.0 - Hud.MARK_R)
		and shape[2] == Vector2(100.0, 100.0 + Hud.MARK_R) and Hud.MARK_EDGE.a > 0.5,
		"a mark is a diamond %d px each way, with a dark edge (%s)" % [int(Hud.MARK_R), shape])
```

- [ ] **Step 2: Run the test to verify it fails.** Expected: a Parse Error naming `mark_shape`.
- [ ] **Step 3: The marks.** In `src/game/ui/hud.gd`:
  - Replace:

```gdscript
## How far above a marked person's feet their mark sits, and its half size (v0.10).
const MARK_LIFT := 22.0
const MARK_R := 2.0
```

  with:

```gdscript
## How far above a marked person's feet their mark sits, its half size, and its dark edge (v0.10; M5 doubled it and gave
## it an edge, so it reads on the cobbles, and draws it under the banners and the slots).
const MARK_LIFT := 22.0
const MARK_R := 4.0
const MARK_EDGE := Color(0.04, 0.04, 0.06, 0.9)
```

  - Replace `_draw_marks()` whole with:

```gdscript
## A small diamond over each person the director marks (v0.10), edged dark.
func _draw_marks() -> void:
	if _rules.director == null:
		return
	var xf := get_viewport().get_canvas_transform() if is_inside_tree() else Transform2D.IDENTITY
	for m: Array in _rules.director.marks():
		var c: Vector2 = (xf * Iso.ground_to_screen(m[0] as Vector2) - Vector2(0.0, MARK_LIFT)).round()
		var shape := mark_shape(c)
		draw_colored_polygon(shape, m[1] as Color)
		shape.append(shape[0])
		draw_polyline(shape, MARK_EDGE, 1.0)


## The diamond a mark is drawn as, centred on `c` (screen pixels).
static func mark_shape(c: Vector2) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(0.0, -MARK_R), c + Vector2(MARK_R, 0.0), c + Vector2(0.0, MARK_R),
		c + Vector2(-MARK_R, 0.0)])
```

  - In `_draw()`, move `_draw_marks()` from the end to just before `_draw_banners(w)`, with this comment above it: `# The marks over people (v0.10) go under the banners and the slots (M5): they never hide one.` Keep `_draw_marker()` last, with its comment.
- [ ] **Step 4: Run the tests to verify they pass.** Expected: `failures=0`.
- [ ] **Step 5: Photographs.** `--show=miras`, `--show=lanterns`, `--show=flame`, each with the default art and with `--art=procedural`. Check:
  - the marks read clearly on the cobbles and on roofs;
  - a mark near the bottom of the screen goes under the slot cards;
  - Wren's blue diamond stands apart from the lantern's gold.

  If the edge looks heavy at 640×360, you may lower `MARK_EDGE`'s alpha (latitude).
- [ ] **Step 6: Commit.**

```bash
git add src/game/ui/hud.gd tests/test_hud.gd
git commit -m "fix: the HUD's marks are bigger, edged, and drawn under the banners and the slots (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 7: Mira's House and the Vigil Flame, loose ends

**Files:**
- Modify: `src/game/mission/miras_house_director.gd`, `src/game/mission/vigil_flame_director.gd`, `tests/test_miras_house.gd`, `tests/test_vigil_flame.gd`

**Interfaces:**
- Consumes: `MissionDirector._carrying()`, `_report()`, `reports`; the tests' `"lines"` (Task 2), `_setup()`, `_run()`, `_arrive()`, `_wren_now()`, `_bearer_out()`, `_clear_watchers()`, `_bring_wren()`, `_do_swap()`, `OUT`.
- Produces: `MirasHouseDirector._free_faithful() -> Array[Person]`; `VigilFlameDirector._walk_pace: Dictionary` (Person → pace before the Vigil's).

- [ ] **Step 1: Write the failing tests.**
  - In `tests/test_miras_house.gd`, add `_loose_ends(t)` to `run()` after `_lines(t)`, and at the end of the file:

```gdscript


## v0.10 M5: the Inquisitor already running to the Temple at 0:40 is not turned to her search, and Cael does not name her
## (review focus 2); with no Faithful free, the Vigil does not pass.
static func _loose_ends(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	# Far from the Temple, so the report is still on its way at 0:40 (nobody walks in a headless test).
	_arrive(d.venn, d.door + Vector2(2.0, 0.0))
	d._report(d.venn, d.temple_door)
	_run(s, MirasHouseDirector.VENN_AT + DT)
	t.check(not d.venn_searching and d.reports.size() == 1 and d.reports[0].carrier == d.venn
		and d.venn.anchor.distance_to(d.temple_door) < 0.5 and not d.timeline.fired_ids().has("venn")
		and (s.lines as Array).is_empty(), "an Inquisitor carrying a report runs on to the Temple, unsearching, unnamed")
	_done(s)

	var s2 := _setup()
	var d2: MirasHouseDirector = s2.d
	for f in d2.faithful:
		if f != d2.venn:  # the Inquisitor never walks the Vigil; she stays out for her own search
			f.inside = true
	_run(s2, MirasHouseDirector.VIGIL_AT + DT)
	t.check(d2.vigil == null and not (s2.banners as Array).has("THE VIGIL PASSES"),
		"with no Faithful free, the Vigil does not pass and no banner says it does")
	_done(s2)
```

  - In `tests/test_vigil_flame.gd`, add `_loose_ends(t)` to `run()` after `_lines(t)`, and at the end of the file:

```gdscript


## v0.10 M5: the Faithful who sees the swap runs to the Temple at his own pace, not the Vigil's; after the swap there is
## no route home and no acolyte "taking up the flame" -- the flame is gone.
static func _loose_ends(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	_wren_now(d)
	_bearer_out(s)
	_clear_watchers(d)
	var aco := d.vigil.acolytes[0]
	var own := float(d._walk_pace[aco])
	_arrive(aco, OUT + Vector2(0.0, 1.0))
	_bring_wren(d)
	_run(s, VigilFlameDirector.SWAP_SECONDS + 0.2)
	t.check(d.swap_seen and not d.reports.is_empty() and d.reports[0].carrier == aco and is_equal_approx(aco.pace, own),
		"the acolyte who saw the swap runs at his own pace (%.2f, own %.2f)" % [aco.pace, own])
	_done(s)

	var s2 := _setup()
	var d2: VigilFlameDirector = s2.d
	var banners: Array = s2.banners
	_do_swap(s2)
	d2.timeline.step(VigilFlameDirector.ROUTE_AT)
	_run(s2, DT)
	t.check(not d2.homeward and not banners.has("THE ROUTE SHORTENS"), "after the swap the route never shortens")
	(s2.crowd as Crowd)._field.kill(d2.vigil.bearer, &"doom")
	_run(s2, VigilRoute.TICK + DT)
	t.check(not banners.has("AN ACOLYTE TAKES UP THE FLAME"), "nor does an acolyte take up a flame that is false")
	_done(s2)
```

- [ ] **Step 2: Run the tests to verify they fail.** Expected: a Parse Error naming `_walk_pace` (the Vigil Flame test). Mira's House FAILs on "an Inquisitor carrying a report…" and "with no Faithful free…".

- [ ] **Step 3: Mira's House.** In `src/game/mission/miras_house_director.gd`, `_add_events()`:
  - change Venn's guard to `func() -> bool: return _alive(venn) and not _carrying(venn)`;
  - change the Vigil's line to `timeline.add(VIGIL_AT, "vigil", "The Vigil passes", _vigil_passes, func() -> bool: return not _free_faithful().is_empty())`.

  Then add `_free_faithful()` above `_vigil_passes()`, and make `_vigil_passes()` use it:

```gdscript
## The Faithful free to walk the Vigil or line the street (v0.10 M5): alive, out, not the Inquisitor, not carrying a
## report.
func _free_faithful() -> Array[Person]:
	var free: Array[Person] = []
	for f in faithful:
		if _alive(f) and not f.inside and f != venn and not _carrying(f):
			free.append(f)
	return free
```

  In `_vigil_passes()`, replace its first four lines (`var free: Array[Person] = []` and the `for f in faithful:` loop that fills it) with `var free := _free_faithful()`. With someone free it does exactly what it did.

- [ ] **Step 4: The Vigil Flame.** In `src/game/mission/vigil_flame_director.gd`:
  - After `var _fx: SearchlightFx`, add:

```gdscript
## The Vigil's walkers' own paces, before VIGIL_PACE (v0.10 M5): one who saw the swap runs to the Temple at his own.
var _walk_pace := {}
```

  - In `_start_vigil()`, replace:

```gdscript
	for p in vigil.walkers():
		p.pace *= VIGIL_PACE
```

  with:

```gdscript
	for p in vigil.walkers():
		_walk_pace[p] = p.pace
		p.pace *= VIGIL_PACE
```

  - In `_swap()`, replace:

```gdscript
	if seer != null:
		swap_seen = true
		_report(seer, temple_door)
```

  with:

```gdscript
	if seer != null:
		swap_seen = true
		if _walk_pace.has(seer):
			seer.pace = float(_walk_pace[seer])  # off the Vigil, he runs at his own pace (v0.10 M5)
		_report(seer, temple_door)
```

  - In `_begin()`, change the route's guard to `func() -> bool: return vigil != null and vigil.active and not swapped`. Add above the line: `# Once the flame is gone, the suspicious priest has nothing to bring home (v0.10 M5).`
  - In `_on_flame_passed()`, change `rules.banner.emit("AN ACOLYTE TAKES UP THE FLAME")` to:

```gdscript
	if not swapped:
		rules.banner.emit("AN ACOLYTE TAKES UP THE FLAME")  # after the swap it is a false flame (v0.10 M5)
```

- [ ] **Step 5: The Mira's House test's wording.** In `tests/test_miras_house.gd`:
  - Replace the header's first four lines with:

```gdscript
## v0.10 Mira's House (MirasHouseDirector): GRIEVING (12) grieving near her door, Halcyon's Faithful about the town; a
## grieving citizen whispered or lured to the door goes in, reads for READ_SECONDS (8 s) and comes out a Believer; a
## Faithful who sees someone go in turns them away and reports, one who sees a Believer come out reports; a report
## delivered, a seen death or the bell fills the Gaze; BelieversObjective.NEED (4) Believers out at dawn win.
```

  - Change the message `"still reading after 9 s"` to `"still reading a second short of READ_SECONDS"`.
  - Change `"after 10 s they come out a Believer, carrying the journal"` to `"after READ_SECONDS they come out a Believer, carrying the journal"`.

- [ ] **Step 6: Run the tests to verify they pass.** Expected: `failures=0`.
- [ ] **Step 7: The references.**
  - `--scenario=miras --case=play`, run twice.
    - Expected: the same lines as Task 1 Step 1, if Venn carried no report at 0:40 in that run.
    - If they moved, both runs must agree. Find the cause in the run's lines: Venn's search not started, or the Vigil skipped. Report it, and record the new `result` and `checksum` lines as the reference from here on.
  - `--scenario=flame --case=none --seed=1|2|3`: each loses.
  - `--scenario=flame --case=play --seed=1|2|3`: at least 2 of 3 win, as after M4. A seen swap now reaches the Temple sooner. If wins fall below 2 of 3, report the result lines; do not tune here (Task 8 owns numbers).
  - `--scenario=lanterns --case=none --seed=1`: identical (checksum 424350965).
- [ ] **Step 8: Commit.**

```bash
git add src/game/mission/miras_house_director.gd src/game/mission/vigil_flame_director.gd tests/test_miras_house.gd tests/test_vigil_flame.gd
git commit -m "fix: Mira's House and the Vigil Flame loose ends: Venn's report, the Vigil with nobody free, banners after the swap, the seen swap's runner (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 8: Balance — Night 3 at 10 DP, Last Judgement at 12 DP

**Files:**
- `tools/dev/behaviour_check.gd`: the `feast` scenario, `_budget()`, `_earned()`, `judgement`'s budget line and `--aim=rich`, and the Festival policy casting a drafted Heaven Splitter.
- Only if Step 7 needs it: `src/game/campaign/campaign_def.gd`, `src/game/campaign/campaign_state.gd`, `src/game/ui/campaign_screen.gd`, `tests/test_campaign.gd`.

**Interfaces:**
- Consumes: `NIGHT_LOADOUTS`, `_play_act()`, `_play_festival()`, `_densest()`, `_richest()`, `JUDGEMENT_TARGETS`, `Mission.bell_rang`, `Mission.finished`, `Rules.power(i)`, `Rules.key(i)`, `CampaignDef.START_DP`, `WIN_DP`.
- Produces:
  - `--scenario=feast --path=festival|procession --case=none|play [--bell=rang] [--loadout=a,b,…] [--seed=N]`, printing `BEHAVIOUR feast start …` and `BEHAVIOUR feast result won=… reason=… time=… bonuses=…`;
  - `--scenario=judgement [--aim=rich] [--loadout=…]`, printing `BEHAVIOUR judgement start aim=… loadout=… dp=…/12 slots=…/6 fits=…`.

Spec §4.2 and §4.3 ask that Night 3's acts can be won at the campaign's 10 DP, and Last Judgement at 12. Both were tuned at 14. The Long Night's Act II policies already fit 10 DP (the Festival's doom and discord cost 3; the Procession's whisper, doom and discord cost 4). What is untested is each act played **alone**, as a night of one act, in a fresh town. Last Judgement's default loadout costs 14, so at 12 it must lose 2 DP.

- [ ] **Step 1: The `feast` scenario.** In `tools/dev/behaviour_check.gd`:
  - Add to the usage comment, after the `flame` entry:

```gdscript
##   feast  (v0.10 M5) the campaign's Night 3 alone, at its 4 slots and 10 DP: `--path=festival|procession` (the
##          Festival unless it says the Procession), `--bell=rang` for a town Night 1 warned, `--case=none` (nothing cast)
##          or `play` (the night's act policy, as `night --act2=play`). It drafts NIGHT_LOADOUTS[path], or `--loadout=`.
##          Prints the loadout's cost against the budget, then the result. --seed= picks the town.
```

  - In the `judgement` usage entry, append: `` `--aim=rich` (v0.10 M5) aims each cast as Act III's caster does (_richest()); the start line prints the loadout's cost against the campaign's Night 4 budget (12 DP, 6 slots).``
  - After `const FLAME_DISCORD_MARGIN := 0.2`, add:

```gdscript
## The campaign's Night 3 (v0.10 M5, spec §4.2): its slots, and the budget of a run that won Nights 1 and 2 with no bonus.
const FEAST_SLOTS := 4
const FEAST_DP := CampaignDef.START_DP + 2 * CampaignDef.WIN_DP
## Night 4, Last Judgement in the campaign (spec §4.3): its slots, and the budget of a run that won Nights 1-3, no bonus.
const FINALE_SLOTS := 6
const FINALE_DP := CampaignDef.START_DP + 3 * CampaignDef.WIN_DP
```

  - In `_run()`'s powers chain, before `elif scenario == "night":`, add:

```gdscript
	elif scenario == "feast":
		var wanted := Battlefield.arg_value(args, "--loadout")
		powers = PackedStringArray(wanted.split(",")) if wanted != "" else PackedStringArray(NIGHT_LOADOUTS[_feast_path()])
		mission.mission_id = "feast_" + _feast_path()
		mission.bell_rang = Battlefield.arg_value(args, "--bell") == "rang"
```

  - In the `match scenario:` block, before `"night":`, add:

```gdscript
		"feast":
			await _feast(Battlefield.arg_value(args, "--case"))
```

  - Before `## The Long Night (v0.09) forced through its acts`, add:

```gdscript
## The Feast's act (`--path=`): the Festival unless it says the Procession.
func _feast_path() -> String:
	return "procession" if Battlefield.arg_value(OS.get_cmdline_user_args(), "--path") == "procession" else "festival"


## The campaign's Night 3 alone (v0.10 M5): nothing cast, or the act played by the night's policy; then its result.
func _feast(which: String) -> void:
	var path := _feast_path()
	print("BEHAVIOUR feast start path=%s bell=%s town=%s %s" % [path, mission.bell_rang, mission._crowd.profile.tier_name(),
		_budget(mission._rules, FEAST_SLOTS, FEAST_DP)])
	var done := [false]
	mission.finished.connect(func(r: Dictionary) -> void:
		print("BEHAVIOUR feast result won=%s reason=%s time=%.1f bonuses=%s" % [r.won, r.reason, float(r.time), _earned(r)])
		done[0] = true)
	if which == "play":
		_play_act(path)  # a coroutine left running beside the loop, until the act is over
	while not done[0]:
		await _frames(1)


## The drafted loadout against a budget: "loadout=a,b dp=3/10 slots=2/4 fits=true".
func _budget(rules: Rules, slots: int, dp: int) -> String:
	var keys := PackedStringArray()
	var cost := 0
	for i in rules.loadout.size():
		keys.append(rules.key(i))
		cost += int(rules.power(i).get("dp", 0))
	return "loadout=%s dp=%d/%d slots=%d/%d fits=%s" % [",".join(keys), cost, dp, keys.size(), slots,
		cost <= dp and keys.size() <= slots]


## Each bonus of a result and whether it was earned: "Before the bell:yes".
func _earned(r: Dictionary) -> String:
	var out := PackedStringArray()
	for b: Dictionary in r.get("bonuses", []):
		out.append("%s:%s" % [b.get("label", ""), "yes" if bool(b.get("earned", false)) else "no"])
	return ",".join(out)
```

  - In `_judgement()`:
    - after `var report_at := 30.0`, add:

```gdscript
	var rich := Battlefield.arg_value(OS.get_cmdline_user_args(), "--aim") == "rich"
	print("BEHAVIOUR judgement start aim=%s %s" % ["rich" if rich else "ring", _budget(rules, FINALE_SLOTS, FINALE_DP)])
```

    - replace `var at: Vector2 = JUDGEMENT_TARGETS[next % JUDGEMENT_TARGETS.size()]` with:

```gdscript
				var at: Vector2 = _richest(rules, mission._bf.ctx.env, mission._crowd) if rich \
					else JUDGEMENT_TARGETS[next % JUDGEMENT_TARGETS.size()]
```

  - In `_play_festival()`, after the Discord cast block (just before the loop's end), add:

```gdscript
		# A Heaven Splitter, when the draft has one (v0.10 M5: the Feast's richer policy within 10 DP), at the densest knot
		# of goers. The night's own Festival loadout has none, so `night` plays as before.
		if slots.has("heaven") and rules.refusal(slots.heaven) == "":
			var hat := _densest(d.goers)
			if hat != Vector2.INF and rules.cast(slots.heaven, hat, {"dir": Vector2(1, 0)}) != null:
				casts["heaven"] = int(casts.get("heaven", 0)) + 1
				print("BEHAVIOUR night play festival t=%.1f cast heaven at %s" % [t, hat.snapped(Vector2(0.1, 0.1))])
```

  - Smoke-check: `--scenario=feast --case=none --seed=1` prints a start line, then a result with `reason=closed`, and no SCRIPT ERROR.
  - Commit the tool now:

```bash
git add tools/dev/behaviour_check.gd
git commit -m "test: the feast scenario, and Last Judgement measured against the campaign's budget (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 2: Measure Night 3, unwarned.** Run each of these and record the start and result lines:
  - `--scenario=feast --path=festival --case=play --seed=1|2|3`
  - `--scenario=feast --path=procession --case=play --seed=1|2|3`
  - `--scenario=feast --path=festival --case=none --seed=1`
  - `--scenario=feast --path=procession --case=none --seed=1`

  **Pass:** each act wins at least 2 of 3 with `fits=true`, and doing nothing loses. The Festival left alone loses `closed`; v0.09's decision (a) lets an unhindered Festival close. The Procession left alone loses `sailed`.
- [ ] **Step 3: Measure Night 3, warned.** Run `--bell=rang`, played, seeds 1–3, both paths. Report only: a warned town is the price of losing Night 1, and the budget is then lower too.
- [ ] **Step 4: If an act fails Step 2,** try richer policy loadouts within 10 DP and 4 slots before any game number:
  - Festival: `--loadout=doom,discord,heaven`, then `--loadout=doom,discord,heaven,wisp`.
  - Procession: `--loadout=whisper,doom,discord,heaven`. Its policy never casts Heaven; this only shows whether the act is bound by the policy, not the budget.

  If it still fails, the only game lever allowed is **Night 3's slots** (`CampaignDef.NIGHTS[2].slots`, 4 → 5), and only if the lines show a policy wanting a fifth power. Otherwise stop and report it as a decision for the user. Do not touch the Festival or the Procession: they are The Long Night's.
- [ ] **Step 5: Measure Last Judgement at 14 DP (the "before").** Run `--scenario=judgement --seed=1|2|3` and `--scenario=judgement --aim=rich --seed=1|2|3` with the default loadout (`heaven,tsunami,cinder,nova`, 14 DP, `fits=false` against 12). Record each `start` and `end` line.
- [ ] **Step 6: Measure Last Judgement at 12 DP.** For each loadout below, run `--aim=ring` and `--aim=rich` at seeds 1–3, and record the lines. Each costs 12 or less, in 6 slots or fewer:
  - `heaven,nova,cinder,smite,ember`
  - `heaven,nova,judgement,blight`
  - `heaven,tsunami,nova,doom,smite`
  - `heaven,tornado,dragon,nova`

  **Pass:** at least one loadout wins at least 2 of 3 with one aim, with `fits=true`. Name the best in the report: it is the loadout the user can expect to work.
- [ ] **Step 7: Only if Step 6 fails: the finale's own grant.** It is campaign-side and leaves Last Judgement on the board untouched. Add it with its test, then measure again at the granted budget with the 14-DP default.
  - `src/game/campaign/campaign_def.gd`:
    - in the `NIGHTS` comment, add: `A night may grant the god Divine Power for itself alone ("dp_bonus", v0.10 M5 balance).`;
    - set Night 4's entry to `{"tier": 5, "slots": 6, "fragment": "vision", "dp_bonus": 2, "options": [{"mission": "last_judgement", "path": ""}]}`.
  - `src/game/campaign/campaign_state.gd`: add the function below, and in `mission()` use `def.dp_capacity = budget()`.

```gdscript
## Tonight's loadout budget: the god's Divine Power, and any grant the night makes for itself (v0.10 M5: the finale).
func budget() -> int:
	return dp + int(CampaignDef.night(night).get("dp_bonus", 0))
```

  - `src/game/ui/campaign_screen.gd` `status_text()`: use `s.budget()` for the DP figure.
  - `tests/test_campaign.gd` `_growth()`, at its end:

```gdscript
	var fin := CampaignState.new()
	fin.night = CampaignDef.FINALE
	fin.dp = 12
	t.check(fin.budget() == 14 and fin.mission("last_judgement").dp_capacity == 14 and CampaignState.new().budget() == 6,
		"the finale grants its own 2 DP; other nights grant none (v0.10 M5)")
```

  - Run Tests. The existing status-line test (Night 1, 6 DP) still holds. This departs from spec §3.1's 12 at Night 4: add it to the report as a departure.
- [ ] **Step 8: The gates are untouched.** Run the forced night runs of Task 1 Step 1 (identical), `--scenario=miras --case=play` (identical to the reference), and FLOW (86 / 0).
- [ ] **Step 9: Commit,** only if Step 4 or Step 7 changed a game number. Put the measurements in the message body.

```bash
git add src/game/campaign/campaign_def.gd src/game/campaign/campaign_state.gd src/game/ui/campaign_screen.gd tests/test_campaign.gd
git commit -m "tune: the campaign's Night 3 and finale budgets from measured runs (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

  Whether or not anything was committed, report the full table of Steps 2–6 to the controller: path or loadout, aim, seed, won, reason, time.

### Task 9 (controller): M5 gate, the v0.10 summary, landing

- [ ] **Step 1: Gates:**
  - Tests: `failures=0`, with the count reported;
  - Digest and crowd_check unchanged;
  - the ten exact behaviour checksums identical to Global Constraints (or to the controller's updated list after the `ec247e4` gate run);
  - `--scenario=miras --case=play` identical to the reference (Task 1's, or Task 7's if it moved);
  - `--scenario=lanterns --case=none --seed=1`: checksum 424350965;
  - lanterns and flame play: outcomes as in Global Constraints;
  - the forced night runs identical to Task 1 Step 1;
  - FLOW: `failures=0`, **86** steps;
  - Mission tests in range.
- [ ] **Step 2: Photographs:**
  - `--show=cael`;
  - `--show=campaign-choice` and `--show=campaign`;
  - `--show=ending`;
  - `--show=results-feast`, `--show=results-warning` and `--show=results-night`;
  - `--show=miras`, `--show=lanterns` and `--show=flame`, with the default art and with `--art=procedural`.

  Show them to the user.
- [ ] **Step 3: Playtest by hand:** Campaign from a fresh save.
  - Night 2: play each card once (three campaigns, or New campaign between) to hear Cael's six lines.
  - Night 3: the Feast's results.
  - The ending: quit the game on the last Results, relaunch, press Campaign, and the ending shows.
  - Title → Missions opens on the last board pick.
- [ ] **Step 4: Land:** fast-forward `feat/Develop-Main`. If origin moved, merge it first and rerun the gates on the merged code. With the user's go-ahead, tag `kak-v010-m5` and push. The release tag `kak-v0.10` is set only on the user's word. Report:
  - the plan's departures from the spec (above);
  - Task 8's measurement table, and any lever it pulled;
  - Task 7's Mira's House reference, if it moved;
  - the Decisions for the user (a)–(g).
- [ ] **Step 5: Write `docs/KAK_Version_0.10_Summary.md`** in the style of `docs/KAK_Version_0.09_Summary.md`. You may delegate it to one subagent, giving it these sources:
  - the spec;
  - the five v0.10 plans;
  - the scratchpad ledgers `deferred_m1_m2.txt`, `rulings_m3.txt` and `ledger_m4.txt`, in `C:/Users/dorae/AppData/Local/Temp/claude/C--BURIN-NITRO-Godot-GIT-vfxProve--claude-worktrees-game-concept-story-review-636208/ee5d1a0f-c279-4b75-b42b-362859dd24e0/scratchpad/`;
  - `git log --oneline kak-v0.09..HEAD`;
  - each milestone's gate reports.

  Sections, in 0.09's order:
  1. A header: engine, branch, tags `kak-v010-m1` … `kak-v010-m5` and `kak-v0.10`, the version in one paragraph with its bullet list, and the design and plan paths.
  2. Concept: the lore spine in brief, and the question the player carries.
  3. The campaign: the four nights as a table, the night screen, fragments and choice cards.
  4. Strength, bites and paths: DP growth, bites, the floor, titles, endings.
  5. Halcyon's Gaze.
  6. Night 2: Mira's House, the Vigil Flame and Broken Lanterns, each as built and as tuned.
  7. Night 3 (the Feast) and Night 4 (Last Judgement).
  8. How the story is told: fragments, Cael's lines, cards, endings, with the M5 text-only note.
  9. The gates by milestone: a table M1 to M5, with tests, digest, crowd_check, FLOW and the exact checksums.
  10. Balance beyond the spec's starting numbers: each mission's tuned numbers against the spec's, with M5's Night 3 and Night 4 measurements.
  11. Decisions for you: (a)–(g), and any Task 8 added.
  12. Performance: M4's searchlight bench, and Last Judgement's drift since v0.09.
  13. Tools and tests: the `miras`, `lanterns`, `flame` and `feast` scenarios, the `--show=` photographs, `--bench-beams`.
  14. Rulings made during the build.
  15. Known issues: the out-of-scope list above.
  16. What moves to v0.11: art for panels and portraits, playable Faith and Theft finales, Resonance and Awakening Trials, ruins and the dead between nights.
  17. Pushed.
- [ ] **Step 6: Update `README.md`'s KAK section briefly.**
  - Put v0.10 first in the "Versions:" paragraph: "v0.10 (tag `kak-v0.10`) adds **the Lantern campaign**: four nights in Aldermere from the title's Campaign button — The Warning, a Night 2 chosen by path (Mira's House, The Vigil Flame or Broken Lanterns, under Halcyon's Gaze), a Night 3 Feast act and, on the Ruin path, Last Judgement — with Divine Power that grows and bites, Cael's memory fragments and lines, and four endings."
  - Point "latest" at `docs/KAK_Version_0.10_Summary.md`.
  - Add `results-feast`, `cael`, `campaign`, `campaign-choice`, `ending`, `miras`, `lanterns`, `flame` to the `--show=` list.
  - Commit both docs:

```bash
git add docs/KAK_Version_0.10_Summary.md README.md
git commit -m "docs: KAK v0.10 summary, and the README's campaign (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 7: Update the Dev Ledger** (`ArtifactData`):
  - M5 to done, and the release to v0.10 if the user tagged it;
  - the decisions (a)–(g) as ideas or open decisions;
  - `meta/project` with the new counts (tests, FLOW 86, the measurements).
