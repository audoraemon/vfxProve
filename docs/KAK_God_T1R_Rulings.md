# KAK Tier 1 Routes: every ruling

The Tier 1 routes milestone ("Option C": every god type wins all five Tier 1 missions with only its own two Tier 1 powers) was built straight through, subagent-driven, on `god/t1routes` from 2026-10-27 to 2026-10-29, landing on `feat/god-progression`: 8 build tasks, a landing task, an opus final review with one fix wave and two re-reviews, and this note. A ruling is a choice the spec or plan left open, or a place where the code said something else. Each entry below has what was decided, why, and the cost if it is wrong, in the controller's own words (where an entry gives no cost, the cost is in its reasoning). The spec is `docs/superpowers/specs/2026-10-27-kak-tier1-routes-design.md`, the plan `docs/superpowers/plans/2026-10-27-kak-tier1-routes.md`, the summary `docs/KAK_God_T1_Routes_Summary.md`.

Groups, in order: the controller rulings D1-D40 (as kept in `.superpowers/sdd/t1routes/rulings.md`), the answers to the spec's section 13, the pre-flight rulings PF1-PF19 (adopted as written by D14), the rulings each task reported (T1-T9), and the final review and its fix wave. Where two disagree, the controller rulings (D) beat the plan text; D25 supersedes D21; D26 is corrected by D28. Task 10 (this note) reported no rulings of its own.

The user's own rulings are D3 (the routes table and the three shared rules), D2 (the real tree), D7 (the title switch), D25 (the Lamb's dead end is fair), D34 (Death x Prayers, option c) and D40 (Passage x Prayers may idle to 60 s). D12 was reported to the user as the one idle exception; D34 and D40 are the same kind of exception, granted by the user.

## Controller rulings D1-D40

Milestone: "Option C" of the Tier 1 fill. The user (2026-10-27) chose to give each Tier 1 mission more ways to win so every god type
wins all five with only its own two Tier 1 powers (spec 2026-10-26-kak-god-progression-design.md §5.2, the per-type win rule), and
approved the routes table below. Worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-god-t1r`, branch `god/t1routes` off
`feat/god-progression` 420a4e37 (Tier 1 fill commit).

- D1. Landing: on `feat/god-progression` only (fetch, trial merge, gate the merged tree, ff). Never `feat/Develop-Main`. Tag
  `kak-god-t1r` locally; the controller asks the user before any push.
- D2. The real tree (`GodTree.TABLE` Tier 1) is the user's and fixed for this milestone:
  ruin smite+ember, death deathmark+pestilence, veil doom+blight, passage thorns+mirror, decree noleave+belllies, dominion whisper+discord.
- D3. The routes table (user-approved, first guesses for numbers; the spec turns each into exact rules):

  | | The Warning | Tax Collector | Spoiled Harvest | Lost Lamb | First Prayers |
  |---|---|---|---|---|---|
  | Ruin | Smite him unseen | Smite (proven) | Ember (proven) | Smite/Ember near him starts his run; Smite a patrol | Ember a building pulls the Faithful away |
  | Death | Death Mark (proven) | Death Mark | NEW plague reaching a carter spoils his granary | a death near him starts his run; plague on patrols | Death Mark a Faithful on the watch |
  | Veil | Doom (proven) | Doom (proven) | NEW Blight rots a full granary | Blight his fountain starts his run; Doom patrols | Doom the Faithful at the door |
  | Passage | mirror him out of the Main Gate | mirror a collector out of town | mirror a carter out (his granary counts spoiled) | Thornwall blocks patrols; mirror him near the gate | mirror the poor to the shrine door; Thornwall blocks sight |
  | Decree | NEW a keeper who heard ALL IS WELL ignores him | NEW Leaving Is Prohibited in a crowd: the debtors mob the collector | NEW The Bell Lies CALL THE GUARD: the guard seize the cart | Bell Lies calls the gate watch away; Leaving Is Prohibited pins a patrol | Leaving Is Prohibited pins the Faithful; Bell Lies ALL IS WELL |
  | Dominion | whisper him out of the gate | whisper a collector out | whisper a carter out | Whisper (proven) | Whisper (proven) |

  Three shared rules: (1) **Out of the walls**: a messenger, collector or carter who leaves through a town gate is gone for the night
  and counts as stopped (for a carter: his granary counts spoiled). (2) **He bolts**: the Lost Lamb's acolyte runs for the west gate
  himself when frightened near him, or at 1:00 at the latest. (3) **They come to pray**: First Prayers' poor set out for the shrine
  themselves, one at a time; the Faithful at the door still see them, so doing nothing loses.
  The user was told the two Decree routes marked "debtors mob" and "guard seize the cart" are the weakest; build them, tuned honestly.
- D4. The user's binding mission rules apply to every route (memory kak-mission-design-lessons): no timed wait over 60 s, doing nothing
  loses 3/3, no luck, no hidden losses, the bell never loses outright (Lantern rules stay), every moving target tagged and arrowed.
- D5. The per-type gate: `behaviour_check --god=<type>:1` (Task 13 of P1) with a scripted policy per type per mission, playing only that
  type's two Tier 1 powers at level 1 within Tier 1's 3 slots / 6 Might: wins >= 2/3 seeds on each of the 30 pairs. The existing route A
  and route B gates and their `none` cases keep their results (win/loss); their checksums may move (D6).
- D6. References: rows of the five Tier 1 missions (Aldermere, `@capital`, the board Warning's starfall and toll rows) may move where a
  new rule reaches them, and are re-recorded in the commit that moves them with the reason. Every other row, `digest` and `crowd_check`
  must not move. Blight's new granary target must not move any non-Tier 1 row.
- D7. The title switch (spec §3, user's builder-check answer 2(a)): once the 30-pair gate passes, the title's Campaign entry becomes
  Endless Night (the board stays as the test mode). In scope as the last build task.
- D8. P2 (Lantern Notice, Hunt, seals) is being built at the same time by another session on `claude/god-p2-lantern-04cddc`, also landing
  on `feat/god-progression`; the Lost Lamb is one of its Hunt stand-ins. This milestone does not touch P2 code; whichever lands second
  trial-merges onto the first and re-gates.
- D9. No PixelLab. Models: opus spec/plan/pre-flight/final review; sonnet implementers and reviews; per-mission tasks in their own
  worktrees (`god/t1r-t<N>`, `C:/BURIN_NITRO/Godot/GIT/vfxProve-god-t1r-t<N>`), merged in task order onto `god/t1routes`.

### Spec/plan problems (2026-10-27, after 976784ed)

- D10. Per-type bar: wins >= 2/3 seeds and idle <= 45 s are binding on every Aldermere pair (D12 names the one exception); the median
  is judged against 150-270 s and reported, not binding (a two-power kit is narrower than the A/B loadouts, whose own v0.11 bars stay).
  Capital per-type results are reported, not binding (Tier 1 in the Capital is dev-only). Cost if wrong: a later tuning round.
- D11. Accept the spec's fixes for Problems 1 (Prayers: first walker timed to arrive as the market fills, the rest chained), 2 (Harvest
  carters set out 30 s early and can be met on the road), 3 (plague and Blight spoil only a granary with no watchman on guard), 8 (a dead
  carter is replaced after 30 s; killing a carter never spoils), 4 (Warning/Passage fallback: an out-of-walls stop starts the next
  star's clock when he leaves the map, if the policy alone cannot make it), 7 (Tax/Decree: the mob is the visited house's debtors at its
  door, only with his guards drawn off), 9 (Capital river gates count as gates), 10 (Lamb: one gate watchman just outside the gate),
  13 (left as is). A stopped person walks off the map. Why: each keeps the user's no-waiting / no-luck rules with the least new rule.
  Cost if wrong: a rule to take back in one director.
- D12. Problem 6 accepted: Decree at Spoiled Harvest may idle up to 60 s (The Bell Lies' cooldown); reported to the user as the one
  exception. Cost if wrong: Decree's Harvest route needs a second hook.
- D13. Problems 5, 11, 12 are policy work (no rule change): the Decree Warning policy times Leaving Is Prohibited holds into a lie; the
  Death Lamb policy keeps plague 8 away from the acolyte; the Death Tax policy marks 10 s before the next door.

### Pre-flight (2026-10-27)

- D14. Every `Ruling:` in preflight.md (items 1-19) is adopted as written; they bind over the plan text. Read the items naming your task.

### Task 1 review (2026-10-27)

- D15. `MissionDirector.left_the_map(person)` is emitted by `_step_leaving()` just before a leaver is freed (controller commit after
  59b54cc9). Tasks 2-6 connect to it for "he left the map" moments (Task 2's Problem 4 fallback, Task 4's carter's load) and never
  edit `send_off()`, `_step_leaving()`, `Walls.MARGIN` or `LEAVE_REACH`; a task that needs one of those changed reports it, and the
  controller changes it once for all.
- D16. Parallel group (Tasks 2-6): suite `bash tools/dev/run_suite_parallel.sh 3`, references and gate.sh with `--jobs=2`; a run that
  dies without a result line is rerun alone before it counts (pre-flight item 11). FLOW is never run inside the group.

### Task 3 review (2026-10-27)

- D17. Tax mob test (I1): the mob reads the binding law's centre, not the collector's spot. It starts when a sealed Leaving Is
  Prohibited binds the collector and the law's origin is within MOB_DOOR_R (3.0) of a door he entered tonight; the guard and
  out-of-doors conditions stay. Why: a click on the door must always work (no luck, D4); with the old rule about half the clicks on
  the door failed. Cost if wrong: one comparison in one director to put back.
- D18. A mob kill stays as loud as an unseen Smite (M5): Crowd only quiets doom kills. The bell stays IDLE and nothing is seen, as
  ruled; the kill still counts toward local events, the same as Smite today. Not a regression. Cost if wrong: one line in Crowd.

### Task 4 report (2026-10-27)

- D19. Harvest SEIZE_R 3.0 (+0.05 slack), up from the spec's 2.5: Leaving Is Prohibited holds a carter on its 3.0 circle, so a held
  carter must always be in reach. Why: a smaller reach made the seizure depend on where the law was clicked (no luck, D4). Cost if
  wrong: one constant.
- D20. HarvestDirector._cart() re-sends a carter left with no walk (a Thornwall on his road dropped his goal and he stood all night).
  Accepted as a stall fix inside the mission's own director. Cost if wrong: none seen; a carter could re-path more often.

### Task 5 review (2026-10-27)

- D21. Passage at the Lost Lamb must not win by flinging a patrol into Aldermere's north-west dead end. Why: the pocket is an
  accident of the map, so the win depends on an accident a later art round can remove without anyone noticing; the Capital's 2/3 shows
  how much the pocket carries. The policy plays the designed line instead: Thornwall blocks patrols, Mirrorfold him near the gate.
  The fling target must be a spot with a path back to the gate. The gate bar is unchanged (>= 2/3 on each seed, idle <= 45 s).
  Cost if wrong: a re-tune for nothing, if the user would have accepted the pocket.
- D22. Add a startle-only negative for the Lamb: a 0:00 Ember (Ruin) or Blight (Veil), then nothing, must lose 3/3. Why: it proves the
  50 s nights are won by play, not by the bolt alone. Cost if wrong: one extra gate case.

### Task 4 review (2026-10-27)

- D23. Harvest seizure (I1) reads the law's centre, the same as D17. A carter is in reach if he is within SEIZE_R + SEIZE_SLACK of
  the bell's place, or if a held NoLeaveFx binds him and that law's origin is within SEIZE_R of the bell's place. Why: the law and
  the bell are two clicks, so the old check failed about half of human seizures (no luck, D4). Cost if wrong: one condition.
- D24. Passage's 86 s Harvest night stays: it is a real route (all carters use the Citadel road, so one mirror catches two), and
  pacing is reported only (D10). Recorded as a known short route for the user. Cost if wrong: a later CARTER_LEAD or policy tune.

### User ruling (2026-10-28)

- D25. Supersedes D21. The user rules Aldermere's north-west dead end fair for Passage at the Lost Lamb: Passage may fling a patrol
  there. A test pins it: a soldier set down at the fling target has no path to the gate mouth, and the failure message names Passage's
  Lamb policy, so an art round that opens the pocket shows up as that test, not as a gate mystery. Capital Passage stays 2/3, reported
  only (D10). Cost if wrong: the user can ask for the hard-Thornwall rule later.

### Task 2 report (2026-10-28)

- D26. Ruin and Death at The Warning (board starfall) win 1/3 in Aldermere after 5 and 4 policy rounds: the Postern star's road is
  never quiet enough for an unseen kill. The binding bar (D5, D10) stays. A fresh opus round finds the smallest rule that gives
  both a fair, readable route on the Postern star, inside the mission rules (D4). It must not tune the opposition down, and must
  not use luck or a hidden loss. Only Warning rows may move (D6). Why: five rounds of policy work show the trouble is in the map or
  the rules, not the play. Cost if wrong: one Warning rule to take back.
- D27. W1 (a keeper who heard ALL IS WELL ignores the messenger) applies in every phase, as spec 4.1 says. A keeper whose bell is
  already called (DELIVERED) and who then hears the lie calls the ringer back before the toll. A bell already tolling stays.
  Why: otherwise the player "stops" the warning and still loses, which is a hidden loss (D4). Cost if wrong: one phase branch.

### Task 2 opus round (2026-10-28)

- D28. Accept W3, "the watchman keeps his gate" (opt-in `WarningDirector.gate_keeps`, set only by the Starfall director). During his
  4 s stare, a death just outside the gate (within GATE_SIGHT 4.0 of the post) draws the star's watchman out to the body, and the
  walls stop the warning (W1). The barred postern's watchman holds its key, so a fright or a body takes him out through it. Why: no
  Postern-only rule could fix Death, which lost at the Main and Side Gates. W3 changes no number, power or opposition, and it also
  ends the 40 s stall at the barred postern. Correction to D26: Death's trouble was at the two open gates, not the Postern. Cost if
  wrong: one flag plus the Ruin and Death Warning policies. Spec 4.1/4.3 to name W3 in Task 10's notes.

### Task 2 review (2026-10-28)

- D29. W3 must be playable by a person, not only by the bot (review I1-I3):
  (1) The NEXT STAR tag counts down to the fall (m:ss), per the countdown-tags lesson, so a 10 s Death Mark can be timed.
  (2) `warning.stars` names W3's conditions in its 3 lines: a death just outside his gate, as he stares at his star.
  (3) A test pins the real board-Warning town: each star's gate in Aldermere has a posted guard outside the walls within
      GATE_SIGHT of the post (the D25 precedent); its message names W3 and the Ruin and Death policies.
  Plus the key fires only on a goal W3 or a fright gave him (M2), and tests for D27 WAITING, GATE_SIGHT and the running
  hint_phase (M4). M1 (a delayed death from an earlier player cast) is fair: it is still the player's cast. M3, M5, M6 stay.
  Why: the user's rules want no hidden timing and countdown tags on moving targets. Cost if wrong: a tag string and a hint line.
- D30. Task 2 re-review: I2 is closed as D29(2) words it. The hint names the stare and "just outside his gate", and "keep the strike
  clear of him" does not fit 3 lines. M2: a flight from the town's evacuation (Crowd._evacuate, EVACUATION/COLLAPSE stages) must
  not turn the postern key; only a W3 body goal or a fright from a strike near him does. The running phase's hint must not offer W3,
  which draws only in the stare. The countdown stays in mission seconds, like every other strip tag. Cost if wrong: a guard and a
  hint line.

### Task 6 report (2026-10-28)

- D31. Task 6's proposed numbers are accepted: POOR_OUT_AT[0] 80 (Capital 150), POOR_CHAIN 50 (above the spec's 30-45 range, so
  Decree's 60 s Bell Lies fits, as in D12), FIRE_PULL 7. While the bell lies ALL IS WELL, no Faithful sees the door. A walker who
  stands still 20 s gives the walk up; he is not a loss, since the chain sends the next one, but he must get a banner (no hidden
  losses). Cost if wrong: numbers to re-tune.
- D32. Three Prayers gaps need a fresh opus rule round, the way D26/D28 fixed The Warning:
  (1) Death idles 126-161 s, waiting on the chain once every Faithful is dead. That breaks the no-waiting rule. Find the smallest rule
      so a door with nobody watching does not make the player wait, for example "with no Faithful at the door, the next walker sets
      out at once".
  (2) Passage wins 0/3 and needs a fair, readable route (the routes table: mirror the poor to the shrine door; Thornwall blocks
      sight).
  (3) Route A seed 1 (prayers_play_1) now loses. Existing gates keep their win/loss (D5), so A must be 3/3 again.
  Never tune the opposition down. Only Prayers rows may move (D6). The bar stays at >= 2/3 and idle <= 45. Cost if wrong: one
  Prayers rule to take back.

### Task 6 review (2026-10-28)

- D33. Accept F3b ("brambles by the well": a Thornwall segment within THORN_HIDE 1.5 of the shrine door hides the door from every
  side, and a poor who went down hidden comes up hidden) and "a Believer never goes down a second time". Without "comes up hidden",
  Passage has no route: the wall lasts 25 s and a prayer 32 s. Also accept POOR_OUT_AT [80,170,240], since the chain decides walkers
  2-3. Conditions (the D29 precedent):
  - `first_prayers.watched` must name F3b, with fire and ALL IS WELL, within HINT_LINES.
  - The mission_book copy and opening banner must say the poor come themselves, not "Lead".
  - A Thornwall's look-lure never counts a poor as brought in (review d): no unadvertised believer.
  - A wall clicked on the door itself must work, or be clearly refused.
  - Prove with real pathing in both towns that a walker waiting at a busy shrine never trips WALK_STALL.
  Cost if wrong: a hint line and one lure exclusion.

### User ruling (2026-10-28)

- D34. User chose option (c) for Death x First Prayers.
  - Once no Faithful is left alive, the next walker sets out at once (the chain is skipped), and the poor may pray together:
    several at the shrine at the same time, each counted.
  - Route B's 150 s median floor is relaxed at First Prayers only. Its win/loss must still hold (D5).
  - Death x Prayers may idle up to 60 s, the user's no-wait limit, as D12 allows for Decree x Harvest. The user was told it lands
    near 50 s.
  - The new moment needs a banner, for example THE DOOR STANDS EMPTY - THE POOR HURRY IN.
  - Only Prayers rows may move.
  - Cost if wrong: one rule in the Prayers director to take back.

D35. Ruling: Task 6 round 3 re-review: fix I1 and M1-M6 in a round 4 by resuming the same opus implementer (no tier above opus; its context saves a cold start). I1 per D31 (no hidden loss): each hurrying poor gets the walker's WALK_STALL give-up with the same banner and is replaced. M1 copy/hint name the together rule; M4 no "sets out" banner when nobody walks. — Why: a stuck hurrier silently holds a need slot until the night times out. — Cost if wrong: one more opus round; only Prayers rows may move.

D36. Ruling: Task 7 accepted as is: god_gate.sh reads each mission's none check off the ruin pair's --with-none run; a none failure then fails ruin's cell as well, which is louder, not hidden. Capital pass=24/30 (Warning: death 0/3, passage 0/3, veil 1/3; Prayers: ruin 0/3, death 1/3, passage median 297, dominion idle 72) is reported only (D10) and goes to the user as a follow-up. — Why: D10 binds Aldermere only. — Cost if wrong: a Capital tuning round later.

D37. Ruling: Task 9 with P2 landed first (D8): merge feat/god-progression (a0185497) INTO god/t1routes (a merge commit, no rebase), so the final ff of feat/god-progression is a fast-forward. Conflicts in game.gd (T8's _flow_title_endless vs P2's _flow_lantern doc+func at the same spot) and tests/test_endless_screens.gd are unions: keep both sides whole. FLOW order: _flow_title_endless before the board walk, P2's _flow_lantern after _flow_endless, as each side has it. Bench against kak-god-p2 (the tip's tag), not kak-god-p1. All references (land.sh) stand in for re-running Tasks 2-6's route gates (each gate row is an exact checksum); god_gate.sh reruns the 30 pairs. — Why: P2 is pushed; t1r must sit on top of it. — Cost if wrong: one more merge round.

D38. Ruling: final review fix wave (one opus dispatch on god/t1routes). I1: the gate must print the real idle: filler casts mark themselves and idle stretches ignore them (every pair re-measured; Decree x Harvest's real ~60 s still fits D12). Passage x First Prayers (real wait 66-69 s before the first walker at 80 s) gets a real early play first (a cast with a lasting effect the night uses, e.g. brambles laid by the door or a fold that moves a Faithful off it); no tuning the opposition down, no moving POOR_OUT_AT. If no honest play brings it to <= 60, the pair is reported to the user as an exception request (the user's no-wait rule is theirs to bend, as in D12/D34) and the milestone waits on that one answer. Minors M1-M7 all fixed in the same wave. — Why: a PASS that rests on casts that do nothing is a hidden lie in the gate. — Cost if wrong: the user is asked once more.

### D39 (final re-review residuals)
Ruling: a cast that moves or blocks a real opponent counts as play, even when the policy times it to fill a quiet stretch. A filler is a cast with no target and no effect (D38). So Dominion x Prayers' "whisper a Faithful a way off from the shrine", Lamb x Dominion's patrol whisper and pre-bolt Discord, and Tax x Passage's Thornwall along the road all stay as play. -- Each changes where an opponent stands or walks, which is what a human player would do in that gap. -- If wrong: Dominion x Prayers' real wait is 59 s at seed 2, the same case as Passage x Prayers, and falls under whatever the user rules for that pair.
Ruling: N1 fixed in the branch (the no-filler test also catches `FILL +`). Re-review I1 otherwise closed; Passage x Prayers goes to the user per D38.

### D40 (user, 2026-10-29)
Ruling (the user's): Passage x First Prayers may idle up to 60 s, like Harvest x Decree (D12) and Prayers x Death (D34). Real idle 59/53/53 s after three honest tries (D38); walkers come ~55 s apart and the walls need one cast each. god_gate.sh passes --idle-max=60 for that pair. This also covers Dominion x Prayers should D39's whisper ever be ruled a filler.

## Answers to the spec's section 13 ("Rulings needed before Task 1")

- R-a. The per-type bar (idle binding; median judged for tier missions; Capital reported). Answered by D10, then made exact for gate.sh by PF1: wins at least 2 of 3 and idle at most `--idle-max` (default 45) are binding on every Aldermere pair, the `none` case loses 3 of 3 once per mission, the median is printed and never judged, and the Capital's 30 pairs are reported only.
- R-b. Problems 2, 3 and 8 (the carter's early lead, the guarded condition, the replaced carter). Accepted by D11 as the spec wrote them (`CARTER_LEAD` 30; plague and Blight spoil only a granary with no watchman on guard; a dead carter is replaced after 30 s and killing a carter never spoils). PF15 added that a sick carter spoils at the first look with no watchman on guard.
- R-c. Problem 6 (Decree x Harvest idle) and Problem 10 (the Lamb's outer post). Problem 6: D12, an idle of up to 60 s for that pair, reported to the user as the one exception (the user later granted the same kind of exception at D34 and D40). Problem 10: D11 accepted a gate watchman just outside the gate, and PF2 dropped the spec's L2 so the watch is judged before the exit, which is what makes the outer post work.
- R-d. Problem 7's debtors and the "walks off and leaves the map" call. Both accepted by D11 (the mob is the visited house's debtors at its door, only with his guards drawn off; a stopped person walks off the map). D15 added the `left_the_map` signal; D17 and D23 fixed the reach of the mob and the seizure to the law's centre.
- Problems 1, 4, 5, 9, 11, 12 and 13 of the spec: D11 and D13; problem 13 (the Lamb watch geometry) is left as it is, as D11 ruled.

## Pre-flight rulings PF1-PF19 (2026-10-27, `preflight.md`; adopted as written by D14)

An opus pre-flight reviewer read the plan against the spec and the tree at `976784ed` before Task 1 and found 5 blocking and 14 advisory items. Each `Ruling:` was adopted as written (D14) and binds over the plan text. The title of each item is the problem; the ruling is the answer.

- PF1 (blocking): gate.sh's per-type verdict contradicts D10 and D12. Ruling: gate.sh with `--god` judges wins ≥ 2/3 and idle ≤ `--idle-max=N` (new flag, default 45), plus `none_lost` 3/3 with `--with-none`; the median is printed, never part of the verdict, in either town. god_gate.sh passes `--idle-max=60` for harvest × decree only and marks that cell `D12`. Wherever the plan says a per-type median is judged (GC, Task 3 Step 8), read "reported".
- PF2 (blocking): The Lost Lamb: L2 plus `_step_free()`'s order cancels the ruled fix for Problem 10. Ruling: L2 is dropped: the acolyte is out only within ESCAPE_REACH of `exit_at`, as today. `LostLambDirector._step_free()` judges `_seen_by()` before `_exit_reached()` (the outer post at (2.7, 16.8) has every point within 1.2 of (2.7, 17.6) inside its SIGHT 2.5; in the Capital the outer post is the same distance from its `exit_at`). Task 5's tests become `_fold_to_exit_seen` (folded onto the exit with the outer watchman on post: seized) and `_fold_to_exit_clear` (watch away or drawn off: escaped). Spec §7.3 Veil reads "two Dooms for the watch". Passage's Lamb median is reported (D10).
- PF3 (blocking): The lie's seconds left: needed by Tasks 2 and 6, owned by nobody. Ruling: Task 1 adds `Crowd.lie_left() -> float` (seconds the bell still lies on the crowd's clock, 0 when it does not; read-only) with one test in `tests/test_walls.gd` or `test_god_routes.gd`; `crowd.gd` joins the owners table as Task 1 only. Tasks 2 and 6 read it and never edit `crowd.gd`.
- PF4 (blocking): Task 1's `_dispatch` test can't pass after Task 2, and would be edited by all five parallel tasks. Ruling: `_dispatch` asserts `has_policy()` for all 30 pairs and false for an unknown scenario, and calls `act()` on an empty ctx only for types *not* in that file's `FILLED` (stubs). Tasks 2-6 never edit `tests/test_god_routes.gd`; Task 7's `_all_filled` is its only later change.
- PF5 (blocking): D6: a route A fix in a shared helper reaches non-Tier-1 rows, and Task 6's protected regex would not see it. Ruling: a task may change a behaviour_check or tier file function only if every caller is its own scenario (shown by grep in the report); a shared helper is changed only behind a parameter that only its scenario passes (e.g. `_faith_look`'s `fetch`), or copied into a scenario-only helper. `_warning` is off-limits to Task 2. Task 6 Step 5 becomes `--only='^(digest|crowd_check|miras_play|miras_(toll|b_play)_[123]|sermon_(none|play|toll|b_play)_[123]|lanterns_none|lanterns_(toll|b_play)_[123]|relic_(none|play|toll|b_play)_[123]|flame_(none|play)|flame_(toll|b_play)_[123])$'`; any task that touched a shared helper adds that helper's other scenarios' rows to its protected run.
- PF6 (advisory): Who steps a Warning's leaver off the map. Ruling: the warning calls `send_off()` on itself and `WarningDirector.step()` calls `_step_leaving()` before its OVER return (a no-op with `walls_stop` off); StarfallDirector does not call it. Task 2's `_out_stops` checks `w.is_leaving(p)` and that he is taken off at the exit after the warning is OVER.
- PF7 (advisory): The board Warning's new hint would show in the campaign Warning and the Long Night's Omen. Ruling: `warning`, `warning.relay` and `WARNING_LINE` stay as they are; the board copy goes on a new key `warning.stars`, which `StarfallDirector.hint_phase()` returns where it returns "" today (no running phase, nothing stopped). `test_mission_hints.gd` adds that one line.
- PF8 (advisory): Tests that assert nothing new, or nothing at all. Ruling: `_last_fx` gives its Rules a caster returning a real `FxTimeline.new()` and checks identity, null before any cast, null once that fx is freed. Task 1 puts the draft in `god_t1.gd` (`static func loadout(type) -> PackedStringArray`, used by behaviour_check) and `_god_draft` asserts it for all six types against D2's pairs. Drop `_tier1_real` (Task 7 keeps `_all_filled`) and the `_none_loses` line.
- PF9 (advisory): `Walls.way_off()` by straight line walks a Capital leaver back through the old town. Ruling: `way_off(at)` is the nearest exit whose straight segment from `at` does not cross `town()` (the nearest exit if none qualifies). `_capital` adds `way_off(Vector2(4.0, 4.6)) == Vector2(7, 39.6)`. `outside()` takes `city` with an explicit null check.
- PF10 (advisory): Merge hunks in the parallel group. Ruling: the controller resolves TSV conflicts by row name (each task's own rows as that task recorded them, the file's order kept), then runs `refs_check.sh --only` on the merged task's rows before the suite. Task 5 inserts `lost_lamb.running` directly after `lost_lamb` (58) in both `mission_hints.gd` and `test_mission_hints.gd`.
- PF11 (advisory): Five tasks' gates at once. Ruling: during the parallel group every gate.sh call takes `--jobs=2`; a FAIL whose log says "printed no result line" is rerun alone before any tuning round is counted.
- PF12 (advisory): A stopped person counts as an escaped citizen. Ruling: `_step_leaving()` takes him off without an escape: `crowd._field.remove(p)`, erase from `crowd.citizens` or `crowd.soldiers`, `p.queue_free()`; `_send_off` test checks `escaped_count` unchanged. (If the controller prefers the escape count, say so in the summary's "what you see".)
- PF13 (advisory): The Tax Collector: OUT and the mob, against `AssassinateDirector`'s other paths. Ruling: `step()`, `_send_guards()` and `_on_killed()` skip an OUT quarry as they skip DEAD/SAFE; the mob kill sets `q.unseen = true`, `q.judged = true`, `killed_by = "noleave"` without going through `fell_at`/`_judge()`. Tests: `_out_killed_after` (an OUT collector struck on his way off: still OUT, chain unchanged, bell IDLE).
- PF14 (advisory): D11's Problem 4 fallback is not in Task 2. Ruling: for Passage (and Dominion if it misses), Task 2's second tuning round turns on `StarfallDirector.out_chain_at_exit` (board only, default off): an out stop's `_stopped_at` is the second the leaver is taken off the map, not the second he passed the wall; a test `_out_chain_at_exit`; the report says whether it was needed.
- PF15 (advisory): H2 judged only at the second of infection reads as a hidden loss. Ruling: a sick carter (`sick_left > 0`) spoils his granary at the first look with no watchman of it on guard while he is still sick; the TURNS THE SICK CART AWAY banner shows once per carter. `_plague_guarded` adds: the watchmen then cleared while he is still sick -> razed "plague".
- PF16 (advisory): P2 (D8) overlaps. Ruling: Task 8 owns `tests/test_endless_screens.gd`; Task 1 appends its two SUITES lines away from `test_god_night.gd`; whichever of P2/T1R lands second reruns `test_god_lantern.gd`, `test_endless_screens.gd`, `test_endless_flow.gd` and FLOW alone, and Task 8 adds `_flow_title_endless` after P2's Lantern walk if P2 is in.
- PF17 (advisory): god_gate.sh: the none runs and the 10-minute cap. Ruling: god_gate.sh puts all of a scenario's runs (6 types × 3 play + 3 none, the none with the first type's `--god`) in one `xargs -P <jobs>` pool calling behaviour_check directly, and judges each cell with gate.sh's rules (item 1), so one `--only` call is ~4 rounds at `--jobs=6`; if a call still nears 10 minutes, Step 3 runs `--only` per type.
- PF18 (advisory): The same policy pieces would be written five times. Ruling: Task 1 adds read-only helpers to `god_t1.gd`: `outside_spot(bc, ctx, from, reach) -> Vector2`, `road_ahead(p, seconds) -> Vector2`, `cast_mirror(bc, ctx, way_in, way_out) -> bool`, `cast_bell(bc, ctx, mode, at) -> bool`, `plague_aim(crowd, at, avoid := [])`, each with one `test_god_routes` check. Tasks 2-6 use them and never edit `god_t1.gd`; a helper a task still needs is written in its own file and named in its report so Task 7 can move it up.
- PF19 (advisory): Task 1's unmoved sample is narrow for an edit every scenario runs through. Ruling: add `warning_none|ringers_play_1|miras_play|prisoner_play_1|bread_play_1|festival_b_play_1|night_b_play_1|starfall_toll_1` to it.

## Rulings the tasks reported

Each task report ended with proposals ("Ruling:" lines or notes for the controller). Where the controller took one into a D number, the entry says so. Where a report proposed one and nobody objected, it stood by being built, and it is listed here so it is not lost.

### Task 1: groundwork (`59b54cc9`, `69dc290b`; review approved)

- T1-1. `Walls`, `MARGIN` 0.5, `outside(at, city)` with an explicit null check, `way_off(at)` per PF9. `MissionDirector.send_off(p: Variant)`, `_step_leaving()`, `is_leaving(p)`. The director that calls `send_off()` steps it (PF6: the warning does it on itself, before its OVER return). A leaver is taken off the map without an escape count (PF12). Why: one place for the rule; a stopped person is not an escaped citizen. Cost if wrong: one director.
- T1-2. `Crowd.lie_left()` and `Rules.last_fx()` are read-only getters (PF3). The controller added `MissionDirector.left_the_map(person)` after the review (D15).
- T1-3. `behaviour_check --god=<type>:1` on a Tier 1 scenario with no `--route` plays that type's policy as route `god` (the drafted loadout is `GodT1.loadout(type)`, PF8) and turns hit-stop off for every `--god` run. `gate.sh --god` and `--idle-max` per PF1. Why: scripted runs are exact only with hit-stop off. Cost if wrong: none seen.
- T1-4. PF6 (the Warning steps its own leavers) was left to Task 2 because `WarningDirector` is Task 2's file.

### Task 2: The Warning (`2add7aa4`, `0f6dfdcb`, `5cc44b6f`, `0cfe8814`)

- T2-1. Ruling: none needed from the rulings doc beyond D14 item 14. `StarfallDirector.out_chain_at_exit` was built, tested and removed again: Passage passes without it.
- T2-2. Route B's board Warning whisper goes in 8-unit hops, so its idle stays 35 to 38 (`tier1_b.gd`, only the board's route-B act). B now wins sooner (108 s against 124 s) because a whisper to a quiet spot is outside the walls. The 12 board Warning route B and toll rows were re-recorded with that reason, inside D6's 99.
- T2-3. The five-round Ruin and Death misses were ruled D26 and D28; W3, the watchman keeps his gate (`gate_keeps`, `GATE_SIGHT` 4.0, `KEY_STEP` 1.2), was built by the opus round. D27: a called bell is called off by ALL IS WELL (RUNG or SILENCED stays; a Herald is never fooled).
- T2-4. Fix round 2 (D29): the NEXT STAR tag counts down; `warning.stars` names W3 in three lines; `_gate_guards` pins each star's outside guard on the real board town; the key fires only on a W3 body goal (M2). Fix round 3 (D30): the key ignores an evacuation's flee, and the running phase gets its own hint `warning.running` without the stare clause. The countdown stays in mission seconds.
- T2-5. Capital Warning per-type results (Death 0/3, Passage 0/3, Veil 1/3) are reported only (D10, D36): the West River and West Gates have no guard posted outside.

### Task 3: The Tax Collector (`0a5bac58`, `3241123f`, `ca3b2014`)

- T3-1. Ruling: (a) the mob needs him out of doors (Leaving Is Prohibited binds only people in the field); (b) up to three nearest lay citizens walk to him as the mob's sight, released after; (c) `report()` has an `out` key and `killed` stays deaths only; (d) the HUD label "Kill the collectors" is now "Stop the collectors" (the Informer and Bishop keep theirs). Why: the mob must not be a luck of traffic, and the objective must say what stops a collector. Cost if wrong: copy and one comparison.
- T3-2. The mob reads the binding law's centre (D17) and a mob kill is as loud as an unseen Smite (D18). The mob constants (`MOB_DOOR_R` 3.0, `MOB_GUARD_R` 1.5, `MOB_AFTER` 3.0) were never tuned.
- T3-3. Tax medians of 128 to 135 s (Ruin, Veil, Death) sit under the 150-270 band by construction: the floor of a Tax night is 35 + 2 x 45 = 125 s. Reported only (D10). Veil leans on Blight cracking the Bell Tower; a reviewer may rule it differently.
- T3-4. The `MOB_DOOR_R` comparison has no tolerance; a click exactly on the edge is borderline (reported, not added because the spec's numbers are exact). D17's inclusive comparison and the policy's centring cover it.

### Task 4: Spoiled Harvest (`e84fdc5e`, `153809fd`)

- T4-1. Ruling: `SEIZE_R` 3.0 (= `NoLeaveFx.RADIUS`) with 0.05 slack (D19). HarvestDirector re-sends a carter left with no walk (a Thornwall on his road dropped his goal), D20. Decree x Harvest needed no idle exception in the policy's own measure (30 s in Task 4); the later honest measure (final wave, D38) is the full 60 s, which D12 allows.
- T4-2. Fix round 1: the seizure reads the law's centre (D23); `_needs_orders` splits a long condition (M3); `_road_closed` pins the still-blocked state (M5). D24: Passage's 86 s night stays; all carters leave by the Citadel road, so one mirror catches two.
- T4-3. `PlagueManager.PLAGUE_LIFE` is 5 s, so a carter's sick window is 5 s; H2 spoils at the first look with no watchman on guard (PF15). Route B's median at Harvest is 150.1 s against the 150 s floor and is chain-bound.

### Task 5: The Lost Lamb (`398ea67c`, `09192e8d`, `583b3892`, `a89f02f0`)

- T5-1. Ruling: the strip's bolt event is `bolt_at / stretch` (a mission minute on any board clock, D4's 60 s wait) and is absent for a bound charge.
- T5-2. Ruling: only a whisper or a Wisp's light leads him; a Death Mark body's lure does not (the death near him is what starts the run).
- T5-3. Ruling: the card brief's line 1 is "A runaway acolyte hides, then bolts." (the Tier 1 card allows 7 lines).
- T5-4. L2 dropped (PF2); `POSTS` = (2.7, 14.6) and (2.7, 16.8) in Aldermere, the Capital's `watch_posts` (-22.2, -13.0) and (-24.8, -13.0).
- T5-5. Review: D21 (no dead-end fling) was superseded by the user's D25 (the dead end is fair, pinned by `_passage_dead_end`); D22 (the startle-only negative: a 0:00 Ember or Blight then nothing loses 3/3, six pinned rows `god_{ruin,veil}_lamb_startle_play_1-3` with `outcome:won=false`, which `gate.sh` prints as FAIL on purpose). Fix round 3 pinned the unified `bound_by != null` guard.
- T5-6. Medians under the band (Ruin and Veil 50 s, Death 79 s, Dominion and Decree 109 s) are the rules, not the play: once he runs, clearing the soldiers on his road is the whole night. Reported only.

### Task 6: First Prayers (`ab78ce6f`, `9eb2034c`, `430617ac`, `ef24273a`, `92921515`)

- T6-1. Ruling (proposed, accepted by D31): `POOR_OUT_AT[0]` is 80 (Capital 150) because the first walker is what moves route A's median (at 60 s it fell to 137-146; at 80 s it is 182), `POOR_CHAIN` is 50 (above the spec's 30-45 so Decree's 60 s Bell Lies fits). The chain decides walkers 2 and 3, so D33 set `POOR_OUT_AT` to [80, 170, 240].
- T6-2. Ruling (proposed, accepted by D31): while the bell lies ALL IS WELL, no Faithful sees the door (`_sees` false); a stray Faithful otherwise turns the walker away through the lie.
- T6-3. Ruling (proposed, accepted by D31): a walker standing still 20 s (`WALK_STALL`) gives the walk up; D31 adds that he must get a banner (no hidden losses): ONE OF THE POOR GIVES UP THE WALK.
- T6-4. F3b brambles by the well (D33): a Thornwall segment within `THORN_HIDE` 1.5 of the door hides it from every side, and a poor who went down hidden comes up hidden; a Believer never goes down a second time; a look at brambles never brings a poor in; a wall on the door works along either axis; the hint `first_prayers.watched` names F3b, fire and ALL IS WELL.
- T6-5. D34 (the user): no Faithful alive, the next walker sets out at once, the poor pray together, route B's 150 s floor is relaxed at Prayers only, Death x Prayers may idle to 60 s. D35: each hurrying poor gets the give-up and a replacement; the hint and the book copy name the together rule; no "sets out" banner when the door is empty.
- T6-6. Route A at Prayers: a walker who would go in under a window's line, or with a Faithful by the door, is whispered back down his road (a policy change behind `fetch` in `_faith_look`, not a rule). Prayers route A's seed 1 lost at 169.9 s in the first build and wins again after fix round 1.
- T6-7. Veil now wins Prayers in about 90 s (every route that kills all six Faithful reaches D34's rule). Reported only.

### Task 7: the 30-pair gate (`b1b79928`; D36)

- T7-1. `god_gate.sh` runs `gate.sh <s> --god=<type>:1` per pair (`--board` for the Warning, `--city` passed on), `--with-none` on the first type (Ruin) of each mission, `--idle-max=60` for Harvest x Decree (D12) and Prayers x Death (D34), the default 45 elsewhere (and, since D40, Prayers x Passage). D36: its none check is read off the Ruin pair's `--with-none` run, so a failed none fails Ruin's cell as well (louder, not hidden). Capital 24/30, none_lost 5/5, reported only.
- T7-2. Tests: `test_god_tree._tier1_real`, `test_god_routes._all_filled`. No game code, no references moved.

### Task 8: the title switch (`e9f00510`; review approved)

- T8-1. Deviation: suites run inside `_initialize()` where the root is not in the tree, so a `Game` cannot be built there. `_title_entry` proves the routing (`next_screen`, `Game.slots_back_action(from)`) and the two doors' wiring by source text, and FLOW walks the real screens (the dev fill off from the title, on from the board, both Backs). The source-text check was made robust in the final wave (M1: `_lines_after()`).
- T8-2. `hub:title` leaves `dev_fill` as it was; the title door resets it on entry. The "campaign" handler stays in `Game` (D7).

### Task 9: landing checks (`16803dd7`, `6b179077`; D37)

- T9-1. Merge `feat/god-progression` (P2, `a0185497`) into `god/t1routes` as a merge commit, no rebase. Conflicts in `game.gd` and `tests/test_endless_screens.gd` are unions; FLOW order `_flow_title_endless` before the board walk, P2's `_flow_lantern` after `_flow_endless`. API clash review: none. The `%` in P2's "interlude at 95" check message was escaped (`%%`, `6b179077`), a real engine format error in P2's test text.
- T9-2. FLOW launched from a background shell fails or gives no result (the window is throttled when detached); it passes in the foreground and alone (187/0). `land.sh`'s own FLOW stage was therefore replaced by a hand run, and the bench by hand-run alternating pairs. All sessions share `user://`, so another session's Godot test can disturb FLOW.
- T9-3. All references (`land.sh`) stand in for re-running Tasks 2-6's route gates (each gate row is an exact checksum); `god_gate.sh` reruns the 30 pairs. The brief said 376 references; there were 382 rows, all OK.
- T9-4. P3 (First Taste) was merged in at landing as `d95cf423`, no conflicts, no duplicate reference rows.

## The final review and its fix wave

- F-1. Final review (opus, `a0185497..6b179077`): 0 critical, 1 important (I1), 7 minor (M1-M7). I1: the 30-pair gate passed Passage x Prayers only on filler casts; the real wait was 66 to 69 s. D38 ruled one opus fix wave.
- F-2. The gate measure (`GodT1.FILL`, `is_fill()`, `note_cast()`): a filler cast names itself and an idle stretch ignores it, so `gate.sh` and `god_gate.sh` print the real wait. Fillers were marked, measured and then deleted or replaced: Passage x Prayers' mirror over the Temple's door and the well wall; Veil x Prayers' blight a fountain; Dominion x Prayers' Discord at the Temple door; route B Prayers' Discord at the Temple door; Harvest x Decree's law at the next granary. Why: a PASS that rests on casts that do nothing is a hidden lie in the gate. Cost if wrong: the printed idle goes up by the filler's gap.
- F-3. Passage x Prayers' real early play, `_passage_fold`: a Faithful within 10 of the door is folded far off (16 from the mirror's way in, to the spot with the longest walk back), only within 40 s of the door next mattering, never on the walkers' or the poor's way. Three honest tries gave 59 / 53 / 53 s of real idle, so the pair went to the user (D38), who ruled D40.
- F-4. Minors: M1 a by-name anchor check in the title tests; M2 FLOW null guards after Back; M3 the long title comment wrapped; M4 the redundant `await` dropped; M5 `_hurry()` guards a freed poor (`is_instance_valid` first) with a Logger-based test; M6 the `spoiled_harvest` hint shortened to "Spoil each granary (gold) before its carter (blue) empties it: burn or blight it, or stop him. Its watchmen (red) guard it."; M7 a CALL THE GUARD that finds no cart shows THE GUARD FIND NO CART.
- F-5. Re-review (read only): I1's gate half addressed, the Passage play real, the fillers deleted; open on Dominion x Prayers' whisper-away (a filler in substance by one reading) and a judgement on idle-triggered casts in Tax, the Lamb and Harvest. D39 ruled both as play; N1 (the filler test did not see `GodT1.FILL + words`) was fixed in `53764524`.
- F-6. D40: the user's. `god_gate.sh` passes `--idle-max=60` for Passage x Prayers (`b1c91b82`). Final table: Aldermere 30/30, none_lost 5/5; Passage x Prayers 3/3, median 225 s, real idle 59 s.

## Report-only results and open items (not rulings; for the user)

Not binding (D10, D36); listed here so nobody has to dig for them:

- Capital per-type: `pass=24/30`. The Warning: Death 0/3, Passage 0/3, Veil 1/3. First Prayers: Ruin 0/3, Death 1/3, Passage median 297 s, Dominion idle 72 s.
  After D42: `pass=22/30`; First Prayers also loses Veil (idle 52 s) and Passage (3/3, idle 81 s).
- Short medians: The Warning Ruin and Death about 75 s, Lamb Ruin and Veil 50 s, Harvest Passage 86 s, Prayers Veil about 90 s, route B at Prayers 129 s (floor relaxed, D34).
- ~~A Capital Tax Passage deputy stalls near a Thornwall~~ (fixed after landing, D42).
- Dominion x Prayers sits at exactly 45 s at seed 2 on a whisper D39 counts as play.

## After landing (2026-10-29)

- **D41.** Ruling: Passage's fold window at First Prayers widens from 40 s to 50 s before the door next matters -- the board version's
  62 s wait (over the user's 60 s limit) came from the policy holding its mirror; 50 s gives 47/47/55 (gate) and 59/47/55 (board), every
  run a win; 60 s was no better -- If wrong: the three `god_passage_prayers_play` rows move back and the board version waits 62 s again.
- **D42.** Ruling: a Capital walker whose step overshoots a free waypoint into a building margin stops on the waypoint instead of sliding
  -- the slide rocked across the waypoint for ever on steps under 0.1 (the Capital Tax deputy, seed 2); only the Capital passes `to`, so
  Aldermere is untouched; the Capital per-type report goes 24/30 -> 22/30 (reported only) -- If wrong: Capital reference rows that
  moved go back, and the deputy stalls again.
