# KAK: The Warning rework (implementation plan)

Spec: `docs/superpowers/specs/2026-11-26-kak-warning-rework-design.md` (§ numbers below are the spec's).
Workspace: `.superpowers/sdd/warning/`. It holds implementer.md, rulings.md and the task briefs the controller writes.
Worktree: `C:/BURIN_NITRO/Godot/GIT/vfxProve-warning`, branch `feat/warning-rework`. `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`.

Each task is sized for one sonnet implementer following `implementer.md`. This plan gives interfaces, tests and numbers, not code. Tests are written first where marked RED.

## Global constraints (every task)

- **Flags.** Every new WarningDirector rule is a flag that defaults off, and only StarfallDirector sets them. The single-star Warning, The Omen act and The Bell-Ringers (RingerDirector) must behave exactly as before (spec G9, §9).
- **No RNG in why_not.** why_not, tags, phases and the policies' reads draw no RNG (G7).
- **Numbers.** Constants are named as the spec names them, with "(first guess)" in their doc comment.
- **New test files.** A new test file is added to `tests/run_all.gd` (alphabetical), followed by an import: `timeout 900 $G --headless --editor --path . --import`.
- **References guarded by every task:** `bash tools/dev/refs_check.sh --only='^(digest|crowd_check|calm|warning_|ringers_)'`. A move fails the task unless the task says otherwise.
- **The suite.** `bash tools/dev/run_suite_parallel.sh 8` runs before each commit.
- **FLOW.** It runs only where a task says so, alone: check `tasklist | grep -i godot` first.

Order:

- T1, then T2, then T3, then T4, then T5, then T7, then T8, then T9.
- T6 is independent: run it in parallel with any task, in its own commit, staging only its hunks.

---

## T1 WarningDirector: post hold, dreamt, K2 key, why_not reach (spec §3, §3.1, §7)

**Files:** `src/game/mission/warning_director.gd`, and a new `tests/test_warning_rework.gd`.

**Interfaces** (all off by default):

- `var holds_post := false`. While true, the watchman stays at his post: phase OMEN, then STARE. He looks up for STARE (look only), then observes his gate. STARE no longer starts the run.
- `func set_off() -> void` starts the run: phase RUN, the `msn_bolt` sound, `_run()`. It does nothing unless the warning holds its post and lives. A relay before it skips the hold, as today.
- `func at_post() -> bool`: holds_post, alive, not stopped, phase OMEN or STARE. Read-only.
- `var quiet_omen := false`. When true, `_omen()` plays no FallingStarFx and no banners: StarfallDirector plays the one star. The look-up still happens.
- `var dreams_stop := false`. In `step()`, while `at_post()` and `watchman.mind == CONFUSED`:
  - `_end("dreamt")`;
  - the banner THE WATCHMAN THINKS HE DREAMT IT (const DREAMT_BANNER);
  - `crowd.off_duty(watchman)` (off duty, his day resumes).
- `var lead_key := false` (K2). It extends `_use_key()` to a WHISPERED own-gate watchman whose `goal()` lies beyond the wall and who stands within KEY_WALK 4.0 of the postern's centre:
  - walk him to its inner face (re-goal once, read the walk with `has_goal()`);
  - then `fold` through, as today, with the banner and sound.
  - D29 and D30 stand: no evacuation, no other walk, no other person.
- `_carrier_reach()`:
  - confuse on a carrier who is `at_post()` with dreams_stop: MAYBE;
  - a seal verb on the carrier: NOT, unless the same key may kill;
  - a lead: judged by `_whispered_at(at)`. MAYBE if that man is the carrier and his goal is outside the walls (walls_stop), or the K2 case. NOT if it is the carrier and his goal is inside. NONE otherwise.
- `report()` adds nothing new. `stopped_how` can now be `"dreamt"`.

**Tests (RED first), tests/test_warning_rework.gd**, in a world like test_starfall's `_world()`, with one WarningDirector set by hand:

- **Post hold.** With holds_post the watchman never runs before `set_off()` (60 s); after it he runs.
- **Off by default.** Without holds_post he runs at OMEN_AT + STARE, as today.
- **Dreamt.**
  - A Discord cast through `Rules.cast()` at his post with dreams_stop gives `warning_dead`, `stopped_how == "dreamt"`, the banner, and the watchman off duty.
  - The same Discord after `set_off()` gives no stop (paused only).
  - Without dreams_stop, nothing.
- **K2.** A real Mind Whisper of the postern's watchman to ground beyond the postern takes him out through it, so W1 stops the warning. With lead_key off he goes round, as today. An evacuation flee never turns the key (D30).
- **why_not reach.**
  - Discord at the post: `""`.
  - Discord on a runner: STOPS_BANNER.
  - Seal on a runner: STOPS_BANNER.
  - Whisper out: `""`; whisper inside: STOPS_BANNER.
  - `ClarityKit.assert_read_only` around each.

**Checks:**

- `test_warning_rework`, `test_starfall`, `test_herald`, `test_herald_nights`, `test_bell_ringers`, `test_clarity_intercept`, then the suite.
- The guarded references (warning_* and ringers_* must stay).

---

## T2 The broken bell buys time (spec §5, §7 rot row)

**Files:** `warning_director.gd`, and `tests/test_warning_rework.gd` (append).

**Interfaces:**

- `var bell_breaks := false` turns the rule on.
- `const BROKEN_PACE := 0.25` (first guess) and `const BROKEN_GAIN := 10.0` (first guess; used by the test only).
- `func bell_broken() -> bool`: bell_breaks, and the bell tower blighted or destroyed, and the Lantern not yet tolled. Read-only.
- `heralding()` is also true when `bell_broken()` on a Herald night.
- `func carrier_pace() -> float`: BROKEN_PACE while `bell_broken()`, else LanternWatch.HERALD_SLOW. It replaces the bare HERALD_SLOW in `_herald_pace()`, the slow-status check in `_herald_run()`, `herald_eta()` and `herald_label()`. With bell_breaks off it returns HERALD_SLOW, so nothing changes.
- `const BROKEN_BANNER := "THE BELL IS BROKEN"`: once per night, emitted by the director that owns the flag (T3 wires it once for the three stars).
- `func bell_why(key: String, at: Vector2) -> String` (static-safe, read-only). For a key whose verbs include rot and `BlightFx.target(env, at) == crowd.bell.tower`:
  - BELL_TOLLED "THE BELL HAS TOLLED ALREADY", when tolled;
  - BELL_SOONER "BROKEN BELL: HE RUNS SOONER", when any live carrier's Temple ETA at BROKEN_PACE is less than his ETA through the intact bell;
  - BELL_TIME "BROKEN BELL: IT ONLY BUYS TIME" otherwise;
  - `""` for any other key or structure.
- **The ETAs** come from `TempleReport.walk_seconds()` and the bell's climb and HERALD_DESCEND: `_eta_intact()` and `_eta_broken()`, both read-only.

**Tests (RED first):**

- **The gain test, per Aldermere post** (StarfallDirector.STARS posts, snapped): `_eta_broken(post) >= _eta_intact(post) + BROKEN_GAIN`. Print both.
- **Blight on an idle bell.** A real Blight cast on the bell tower with bell_breaks:
  - a watchman who sets off later walks to the Temple at BROKEN_PACE (`statuses.slow`);
  - `herald_open()` is true;
  - `herald_eta()` uses BROKEN_PACE.
- **The keeper carrying it.** He walks at BROKEN_PACE with no climb.
- **Flag off.** Today's behaviour, pinned by the existing test_herald cases.
- **bell_why:** each of the three banners in its state; `""` for Blight on a well; read-only.

**Checks:** as T1, plus `test_lantern` and `test_threat_alert`.

---

## T3 StarfallDirector: three posts from 0:00, one star, tags, phases (spec §2, §3.2, §6)

**Files:**

- `src/game/mission/starfall_director.gd`;
- `src/game/descend/tier_book.gd` (`_warning`);
- `src/game/town/cities/capital_missions/warning.gd`;
- the tests named below.

**Interfaces:**

- **The schedule.**
  - `STARS` keeps its shape, and the field means "sets off at". The values are 20.0, 40.0 and 60.0 (first guess), with the posts unchanged.
  - `const OMEN_AT := 1.0`.
  - `STOP_WAIT`, `stop_wait`, `fall_at`, `next_star`, `next_fall_in` and `_stopped_at` are removed. `TOWN_VARS := ["star_falls"]`.
- **Setup.** `_begin()` creates the three WarningDirectors with walls_stop, lie_stops, gate_keeps, holds_post, quiet_omen, dreams_stop, lead_key and bell_breaks all true. All three are set up on the first `step()`, in STARS order, each with `_reserved_for()`.
- **`func sets_off_in(i: int) -> float`.** Mission seconds until star `i` sets off: never below 0, and INF once it has set off or stopped. Read-only. `step()` calls `set_off()` on each warning still `at_post()` when its time comes.
- **The one omen.** At OMEN_AT: one FallingStarFx over the Main Gate post, the banners A STAR FALLS OVER THE TOWN and STOP THE WARNINGS, and each watchman's look-up (his own `_omen()`).
- **The broken bell.** The first frame any warning's `bell_broken()` is true, BROKEN_BANNER is emitted once.
- **`tags()`** per spec §6.1: the countdown label `"WATCHMAN - SETS OFF IN %s" % UiTheme.clock(sets_off_in(i))`, and the TEMPLE tag hidden while `rules.lantern.herald_running()`. NEXT STAR is removed.
- **Phases.** `hint_phase()` and `hint_phases()` per §6.2. It never returns `""`.
- **`step_seconds()`.** The soonest `sets_off_in` still to come, else 0.
- **`tour()`** per §6.3.
- **`report()`** adds `"dreamt": n`.
- **`why_not()`.** The existing aggregation, plus the first warning's `bell_why()` when the key rots. The rot banner wins only if no warning could be stopped by the cast.
- **`TierBook._warning()`.**
  - The brief becomes ["One star falls over the town.", "Three watchmen will run to wake the bell."].
  - The goal, label and lose stay the same.
  - `make_bonuses` gets `[UnseenObjective.new()]` (W-R6).
- **The Capital overrides.** The same three posts, with the times 20.0, 40.0 and 60.0. The Capital's quiet posts are reported, not binding.

**Tests to update:**

- **test_starfall.gd.** Rewrite the schedule cases:
  - all three appointed at 0, each at his post;
  - the countdown tags read 0:20, 0:40 and 1:00 and count down;
  - each set-off falls at its time, in mission seconds (with a clock rate of 2.0, at half);
  - the one star and its banners;
  - phases posts, running, relay, bell, broken and herald;
  - `step_seconds`;
  - the tour;
  - a win at the instant the last stop lands;
  - dreamt counted in `report()`.
- **Kept or retired.** Keep the W1, W2 and W3 cases, adjusted to the new schedule. Retire the stop_wait and NEXT STAR cases. Update or retire `_gate_guards` (D29's pin was for the old policies; see W-R9).
- **The rest:** test_town_vars, test_town_overrides, test_capital_starfall, test_herald_nights (the schedule and STOP_WAIT cases), test_wishes (`STARS[0][0]` timing), test_threat_alert, test_descent, test_tier1_board, test_board_missions, test_descend_hud.
- **Reading the rest.** Run the suite, then fix each failure that pins the old schedule. A failure that is a real bug is fixed, not re-pinned.

**Checks:**

- The focused tests above, then the suite.
- The guarded references.
- **FLOW, alone:** `$G --path . --scene res://scenes/game.tscn -- --flow-test`. It must end `failures=0`: the board section sets `warning_dead` on all `stars`, and the ascend and results flows.

---

## T4 Quiet posts: `_quiet_posts()` and `_hush_step()` (spec §4; gates G2, G3, G4)

**Files:** `starfall_director.gd`, and a new `tests/test_warning_quiet.gd`.

**Interfaces:**

- `const QUIET_R := 3.0` and `const QUIET_MARGIN := 0.5` (first guesses).
- **`func _quiet_posts()`**, at setup after the appointments. Deterministic: sort by distance, then by instance id. No RNG.
  - It moves each soldier whose post anchor or position lies within QUIET_R of a post. His anchor (and `post`) goes to the nearest walkable ground at least QUIET_R + QUIET_MARGIN from every post, along the line out from that post, and he is placed there.
  - It holds those soldiers, and every GateCheck checker of the three gates, as the director's: `busy()` returns true for them, so `_holds_soldier` and `held_by_mission` see them, while their post is held.
  - It moves idle CALM citizens anchored in the ring, never a wisher or a wish target (spec §4).
- **`func _hush_step()`**, in `step()` while any post is held. It turns away the others within QUIET_R of a held post, per spec §4.
- **`func posts_held() -> Array[int]`**, read-only, for tests and policies.
- **The release.** When a post stops being held, its soldiers are released (`off_duty`), and their town posts are given back as they were.

**Tests (RED first), tests/test_warning_quiet.gd:**

- **G3, the quiet test.**
  - The world: the board def with the director set up, at seeds 1-3, for each of Town.Look.DAY and NIGHT (`NightRules.apply` with the director's reserved).
  - The sampling: every 0.25 s from 0 to each set-off.
  - The check: nobody but the watchman within `crowd.witness_reach(p, true)` of a held watchman.
  - On failure, print who, where and when.
- **G2.** Each of the 12 starters' reach, centred on each watchman: at most one watchman in reach. The reaches are KILL_R, RADIUS, REACH and PICK_R, taken from each fx's constants.
- **G4.**
  - Three real Smite casts through `Rules.cast()` kill the three watchmen at their posts. The result is three `stopped_how == "kill"`, the bell IDLE, `alarms.stage` below LOCAL_EMERGENCY, and the night won.
  - The same with three Breath-in-a-cell kills, where Might allows (a test may refill).
- **The release.** After a set-off, the moved soldiers are no longer held and walk back to their town posts.
- **Tuning.** If G3 fails after `_hush_step` covers the case, move a post's literal spot (spec §4 limits) and record the new literals in STARS. That is first-guess data.

**Checks:**

- test_warning_quiet, test_starfall, test_soldier duties tests (`grep -l "GateCheck\|guard_jobs" tests`), then the suite.
- The guarded references, plus `^(gates|soldiers)$`: they must not move, since the hush only runs on the board Warning.

---

## T5 Steps, hints and their proofs (spec §7, §8; gate G6)

**Files:**

- `src/game/mission/mission_hints.gd` and `src/game/mission/mission_steps.gd`;
- `tests/test_mission_hints.gd` (its SPEC table), `tests/test_mission_steps.gd` (`_advance_intercept` only, per R2) and `tests/test_clarity_intercept.gd` (`_starfall` only).

**Work:**

- **The lines.** LINES gets `warning.posts`, `warning.running` (new words) and `warning.broken`. `warning.stars` and `warning.waiting` are removed.
- **The steps.** STEPS["warning"] per §8.2.
- **The SPEC table** is updated word for word.
- **The proofs.** `_starfall` proves each verb per phase with real casts (§8.3). Its colour checks run per phase (`_colours`). `assert_read_only` runs per phase. The why_not rows of §7, one case each, including the three rot banners.
- **The plates.** If a line does not fit (G6), shorten it per §8's last paragraph and record the final words in the spec in the same commit.

**Checks:**

- test_mission_hints, test_mission_steps, test_clarity_intercept, test_hud, test_legend (if verbs touched), then the suite.
- The guarded references.

---

## T6 The rename (spec §10): independent

**Files:** `src/game/mission/mission_book.gd` (the two `_tier1()` names), and any test that pins the old `name` or `intro_banner` (grep `"The Tax Collector"`, `"Spoiled Harvest"`, `"THE TAX COLLECTOR"` as intro_banner, `"SPOILED HARVEST"`). Do not touch person labels, director banners or docs (W-R8).

**Test:** in test_mission_book or test_tier1_board, the board card names "The King's Tribute" and "The Broken Harvest", their intro banners, and the unchanged ids.

**Checks:**

- The apostrophe draws: `$G --path . --script tools/dev/glyph_ascii.gd -- "'"` prints its pixels, or a test of `UiTheme.base_font().has_char("'".unicode_at(0))`.
- The suite.
- `refs_check --only='^(tax|harvest)_'`: none may move.

---

## T7 The six bots and the gate (spec §12, §13; gate G8)

**Files:** `tools/dev/routes/god_t1/warning.gd` (rewrite the six `act_<type>`, plus `state()` adding dreamt), `tools/dev/routes/tier1_b.gd` (`act_warning` kept working: reported, not binding), and `tests/test_god_routes.gd` (its Warning cases).

**The policies** read the director through `StarfallDirector.stars`, `at_post()`, `sets_off_in()`, `posts_held()` and the tags. Each casts only its type's `GodT1.loadout(type)` and uses no filler.

| Type | Policy (first plan; tune per spec §11 step 1) |
|---|---|
| veil | Silent Doom on the at-post watchman with the soonest set-off when the cluster aim is clean, else wait until it is. A runner: the existing cluster and seen logic. |
| ruin | Smite on the soonest at-post watchman. A runner: Smite on him, with Ember as the fallback. |
| death | Death Mark on the soonest at-post watchman whose `sets_off_in` is at least MARK_TIME + 0.5. Otherwise, in order: a later one, Raise on a body near a runner, or Death Mark on a runner. |
| passage | Skylift on the soonest at-post watchman to `_beyond()`. A runner: lift him ahead on his road, with Windfall barring his road while the lift cools (today's). |
| decree | Seal, then Breath, on the soonest at-post watchman (`GodT1.cast_amber`/`amber_breath`), when Might is at least 3 and both are ready. Otherwise the breath fright out through the gate (today's), then seal and breath on a runner. |
| dominion | Discord at the post for the soonest watchman if he sets off before Discord cools again. Otherwise lead him out with a whisper (K2 for the postern; `_out_spot`). A runner: whisper out, with Discord as a pause only. |

**Tests:** test_god_routes keeps "all six filled", "no filler" and "outside() empty". Add one case per type: in the board world, the policy's first cast at 0:01 is aimed at an at-post watchman.

**The gate** (foreground, each call under 10 minutes; `--jobs=2` under load):

```
bash tools/dev/god_gate.sh --only=warning
bash tools/dev/gate.sh warning --route=b --board --with-none        (reported only)
bash tools/dev/god_gate.sh --only=warning --city=capital            (reported only)
```

**The pass.** Every pair is `wins=3/3` with `idle_max` at most 45, `none_lost=3/3`, and the last line `pass=6/6 none_lost=1/1 PASS`. If a pair misses, follow spec §11 (at most three rounds), then report DONE_WITH_CONCERNS with the table.

**The report table:** per type and seed, the outcome, time, idle, checksum and casts.

**Checks:**

- test_god_routes, test_warning_quiet, then the suite.
- The guarded references. The gate's new runs are recorded in T8, not here.

---

## T8 Record the board Warning's references (spec §14)

**File:** `tools/dev/refs/references.tsv`, with the 21 rows inserted after `warning_mix`, in this order:

```
warning_board_none_1        --scenario=warning --board --case=none --seed=1 --god=ruin:1
warning_board_none_2        --scenario=warning --board --case=none --seed=2 --god=ruin:1
warning_board_none_3        --scenario=warning --board --case=none --seed=3 --god=ruin:1
warning_board_ruin_play_1   --scenario=warning --board --case=play --seed=1 --god=ruin:1
... seeds 2 and 3, then the same for death, veil, passage, decree and dominion (18 play rows).
```

- **Recording.** Each checksum is recorded from the T7 gate's own run of that case, or a re-run. Run every row twice, because the checksum must repeat: a row that differs between two runs is not recorded, and is reported (hitstop is off under --god).
- **May move:** only the 21 new rows; they are new.
- **Must not move:** `warning_none`, `warning_doom`, `warning_whisper`, `warning_discord`, `warning_mix`, `ringers_*`, `tax_*`, `harvest_*`, digest, crowd_check, calm, gates and soldiers. Check with `bash tools/dev/refs_check.sh --only='^(digest|crowd_check|calm|gates|soldiers|warning_|ringers_|tax_|harvest_)'`.
- **The commit body** gives the reason: "new rows: the reworked board Warning (spec §14)".

---

## T9 Milestone check (controller, before landing)

- `bash tools/dev/run_suite_parallel.sh 8`;
- `bash tools/dev/refs_check.sh` (all rows; quiet machine);
- FLOW, alone;
- `god_gate.sh --only=warning` once more, after the merge with Develop-Main (`check-before-every-merge`: trial merge on a commit, gate the merged tree).

**The record.** Append the rulings made during the tasks to `.superpowers/sdd/warning/rulings.md` and copy them to `docs/KAK_Warning_Rework_Rulings.md`. Write the open questions for the user's play test. Landing, the Ledger and Discord follow the kak-milestone skill.
