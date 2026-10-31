# KAK God Progression P5: every ruling

God progression P5 ("The Lantern Hunts") was built straight through, subagent-driven, on `god/p5-hunts` from 2026-10-29, landing on `feat/god-progression`: 14 build tasks, a landing task, this note, an opus milestone review and one fix wave. A ruling is a choice the spec or plan left open, or a place where the code said something else. Each entry says what was decided, why, and the cost if it is wrong. Where a source gave no cost, the cost is worked out from the entry's own reasoning. The mission spec is `docs/superpowers/specs/2026-10-29-kak-god-p5-hunts.md` (cited MS §n), the parent spec `docs/superpowers/specs/2026-10-26-kak-god-progression-design.md` (§n), the plan `docs/superpowers/plans/2026-10-29-kak-god-progression-p5.md`. The rulings of P1, P2, P3 and the Tier 1 routes (`docs/KAK_God_P1_Rulings.md`, `_P2_`, `_P3_`, `docs/KAK_God_T1R_Rulings.md`) hold unless one below changes them.

Groups, in order: C1-C10 (controller rulings), the mission spec's H1-H15 and your answers to its nine open issues, the plan's P5-1 to P5-22, the pre-flight (B1-B8 and 24 minors), then the rulings of each task (1 to 14) with the controller's rulings named P5-Tn-Rn in the order they were made, then the landing, the milestone review (P5-L-R1 and R2) and the fix wave. Task 15 (landing) and Task 16 (these notes) report no rulings of their own beyond those.

**Where two disagree.** The order of authority, strongest first: your own answers (C9), then the controller's rulings (C1-C10, the P5-Tn-Rn, P5-L-R1 and R2), then the plan text, then the spec text. The pre-flight rulings were adopted as written (C1-C8). Where a later ruling changes an earlier one, the entry says which stands. Five places matter:
1. P5-T9-R5 (a relief pair for Hunt 1) was **withdrawn**. The tree is back to what it was before it. See Task 9.
2. P5-T9-4 (the task's request for an idle allowance for Death on Hunt 1) was **not granted**. Only Passage has an allowance (P5-T11-R2). Death's idle goes to you.
3. P5-T13-R7 (the report's first reading of Passage's idle on Hunt 5) is **superseded by P5-T13-R12**: the idle was not the cooldown, the fix made it the cooldown. R12 stands.
4. The ruling names R1 to R5 were used twice in Tasks 11 and 12: once by the task for its own first-round choices, and again by the controller for the review rounds. Both sets stand. This note marks the task's own as "(task, round 1)" and the controller's as "(controller)".
5. The spec's text was edited by the controller after you approved it, to match what was built (formations, house order, the retired `MATE_SIDE` lever). The spec as edited stands. Summary item 8 lists every change.

## Controller rulings C1-C10 (`.superpowers/sdd/godp5/rulings.md`)

- C1 (pre-flight B1, Task 2). No new variable reuses a name that already exists in a base or in its subclasses (`reliefs`, `beats`, `patrol_size`, `mates`, `post_names` are taken). Each new one is called `tune_<the const in lower case>`, checked unused in `src`, `tools` and `tests`. Only constants that a Hunt changes and that are read outside the `_plan()` or `_begin()` the Hunts replace get one. Three bases only: Exodus, Ringer, Bell Ringers. `patrol_size` is already a variable, so it is set, not added. Why: GDScript refuses a second member of the same name. Cost if wrong: a parse error in a base, which every mission would feel.
- C2 (B2, Tasks 4-8). A Hunt never redeclares a parent's constant name. Its numbers are constants with its own prefix (`HF_`, `SW_`, `EI_`, `BH_`, `FH_`). `setup()` copies them into the base's `tune_` variables before the base reads them. Why: a subclass cannot shadow a parent's `const`. Cost if wrong: a parse error.
- C3 (B3, Task 5). The witness keeps `_rings_himself()` true, makes `_take_rope()` and `_give_back()` do nothing, and checks his own distance to the Temple's door each step. `_deliver()` is never reached. Why: otherwise a witness who walks past the living bellkeeper would lose the night, and one at the Temple would lose nothing. Cost if wrong: a hidden instant loss at the bellkeeper.
- C4 (B4, Task 7). Hunt 4 replaces `_raise(i)` and every other path that assumes a Structure. Why: the base breaks a step the moment its standard is a null. Cost if wrong: every standard breaks as it is raised.
- C5 (B5, Task 6). Hunt 3 replaces `_hide_goal()`, `_arrive()`, `_begin()`, `_set_out()` and `fleeing_to_safe()`. Only the captain, at the end of his round and warned, ever goes to the Citadel. With the Temple down or burning, a target hides in a house of his own round. Why: the base would send a frightened warden to the Citadel's gate, which loses the night with no warning. Cost if wrong: a hidden loss.
- C6 (B6, Task 14). The five Hunts are a second row of the DEV tab. Row 1 and its pins are unchanged. Labels fit by measured width and are shortened to the title if `<title> (Hunt)` does not fit. Why: twelve cards on one row left 41 px each. Cost if wrong: layout only.
- C7 (B7, Task 3). `_loadouts_real` asserts each type's exact list of missing keys. Passage's list is empty. Why: Passage's two real Tier 1 keys are its keys at every tier. Cost if wrong: a test that says something false.
- C8 (B8, Tasks 3, 9-13, 15). `hunt_gate.sh` gets `--type=<type>` (that type's three seeds; the three none runs only with `--with-none`), `--save=<dir>` and `--judge=<dir>`. Tasks 9-13 run it per type and check references per type. Every foreground command stays under 10 minutes. Why: one call for a whole Hunt took 20-25 minutes. Cost if wrong: timeouts.
- C9 (you, 2026-10-29). "Approved: all nine recommended answers in the P5 spec's open issues. Run P5 straight through." Decree on Hunts 2-4 is a reported gap (Task 15 judges with `--except=decree` on those three Hunts only). Out of the walls on all five. Hunt 1 walks itself. Hunts keep the Descent. The pooled median. The loadout floor. Face Halcyon's Gaze weights kept (tune the escort first). The third fright wins at once. P2's plates kept. Cost if wrong: see the nine answers below.
- C10 = P5-C10 (controller, during Group C). For "harder", the reverse direction of any lever that MS §7 lists for the Hunt is allowed, plus the extra levers the task brief names. The chain (45 s), every wait of 60 s or less, the countdown window (first shown at least 45 s out) and the Gaze's weights are rules, not knobs. Each moved constant gets a comment with the round and the numbers that moved it. At most three rounds. Why: every Hunt's default play came in at 120-160 s, under the 180 s floor, and the spec's own levers only make a Hunt easier. Cost if wrong: a Hunt tuned further than you meant. All the moves are in summary item 7 and 8.
- Also (the coordinator, 2026-10-29). Every pre-flight minor that is a doc fix was folded into the spec and plan. The bench is against `kak-god-t1r` (this branch's base), not the plan's first guess. The spec's open issues stayed open until you answered (C9).

## The mission spec's rulings H1-H15 (MS §10)

- H1. `HuntBook` lives in `src/game/god/`, as `RiteBook` does; the frames live in `MissionBook`. Cost: a file move.
- H2. A Hunt is played only at its own tier (`hunt_for` indexes by tier). Cost: none, there is one tier per Hunt.
- H3. Hunts 1 and 5 subclass `ExodusDirector` (households, file, seizure march, its own Gaze). Cost: medium, overriding much of a 947-line base. (It was.)
- H4. Hunt 1's watch, Hunt 3's guards and Hunt 5's escorts are soldiers, so CALL THE GUARD answers, and Whisper and Discord hold them. Hunt 2's mates, Hunt 1's inquisitors and Hunt 4's escorts are lay people, the bases' own kinds. Cost: small, Decree's one route.
- H5. Hunt 2 uses the watch Lantern, not the herald's: the toll only turns the Lantern, so the Hunt has one way to lose. Cost: small, a Herald could be added.
- H6. Hunt 3's frights are the Assassinate type's `_alarm()` calls, only while he walks, one per 8 s, overridden in the subclass. No base hook. Cost: small, a constant.
- H7. Hunt 4's taken house keeps its planted bearer breakable, and he counts for the win. Cost: small, one condition.
- H8. Hunt 5's freed believer counts at once and is sent off (no second seizure). Cost: small, no chase to play.
- H9. Scenario names are the mission ids. Reference rows are `<id>_none_<n>` and `<id>_<type>_play_<n>`. Cost: none.
- H10. `TierBook.board(at_tier)` stays, unused by the god code. Cost: none.
- H11. The bases read their numbers as constants, so one groundwork task gives the constants a Hunt changes a same-valued variable named `tune_<const>`, read in the const's place. Exodus: `tune_out_at`, `tune_shut_at`, `tune_hounds`, `tune_per_house`, `tune_believer_pace`, `tune_need`, `tune_chain`, `tune_gate_watch`, `tune_quiet`, `tune_beats`. Ringer: `tune_mates`, `tune_mate_gap`, `tune_mate_side`, `tune_out_pause`. Bell Ringers: `tune_set_out_at`, `tune_chain_wait`. Byte-identical by default; those bases' references rerun. Cost: medium, a base's references move if a read is missed. (They did not.)
- H12. A Hunt's own numbers are prefixed constants, never a parent's name; `setup()` copies them into the `tune_` variables and into the bases' existing variables. Cost: none.
- H13. The DEV tab's Hunts are a second row; row 1 and its pins are unchanged. Cost: small, layout only.
- H14. A fright counts whoever set it going: the town's own panic follows the god's work. Cost: small, a god-only filter later.
- H15. Each Hunt's win and loss reasons get results titles. Cost: copy only.

### Your answers to the nine open issues (all nine recommended answers, C9)

1. **Decree has no route on Hunts 2, 3 and 4.** Accepted as a reported gap. The rows are recorded as they fall, and the Hunts are re-gated when you fill Decree's Tiers 2-4. No Decree-only rule was added. Why: Decree's kit there (Leaving Is Prohibited, The Bell Lies, Magnify) cannot kill, frighten or move a man, and those Hunts are won only by stopping people. Cost if wrong: a small task for a rule, plus re-recorded rows.
2. **Passage plays only Thornwall and Mirrorfold, so its routes rest on "out of the walls" on all five Hunts.** Applied as written. Cost: if it were refused, Passage would have no route on any Hunt.
3. **Hunt 1's households walk out on their own.** Yes. Why: at Tier 1 only Dominion can move a man. Cost: if refused, a rewrite of Hunt 1's walk.
4. **Hunts keep the Descent** (wishes, believers, ASCEND). Yes. Cost: one line in `Mission.has_descent` and a test that no wish lands on the Hunt's people. The alternative pays only the main Divine Power and the Faith bonus.
5. **"Board median" is the pooled median** of the winning runs (180-240 s), each type's own median reported. Yes. Cost: short pairs are reported, not failed.
6. **The scripted loadout is the floor** (3 slots, the tier's Might, level 1). Yes. Why: a Hunt any god of that tier can win is the bar. Cost: a Hunt may be easy for a well-fed god.
7. **Death on Face Halcyon.** Keep the Gaze's weights and tune the escort first. Cost: if Death misses, it is reported.
8. **The captain's third fright wins at once.** Yes. Why: no waiting, and the winning strike can never also lose. Cost: no chase to the gate.
9. **The plates stay P2's.** Tier 2's plate says "the runner" though four witnesses walk. A one-word change is yours to ask for. Cost: copy only.

## Plan rulings P5-1 to P5-22 (plan, "Rulings")

- P5-1 (Task 1). `HuntBook` sits beside `RiteBook`; `GodNight.HUNTS` aliases it, because P2's screens and FLOW read `GodNight.HUNTS[0]`. Cost: a rename.
- P5-2 (Task 1). A Hunt id builds the Hunt at any Notice. `def_for()` asks `HuntBook.has(id)`, not `hunt_for()`. Bank and forfeit still key on the Notice. Cost: a stale Hunt id would bank as an ordinary night (it cannot happen: the Notice leaves 100 only through the Hunt's bank).
- P5-3 (Task 1). The frames carry a do-nothing director until their task. Cost: none (replaced in Tasks 4-8).
- P5-4 (Task 1). `last_mission` keeps a Hunt id. Cost: a line.
- P5-5 (Task 1). The Descent on a Hunt, with `_hunt_wishes`. Cost: drop one term and flip `_descent`.
- P5-6 (Task 2). One hooks task, only three bases, only the constants read outside the replaced `_plan()` and `_begin()`. Cost: a later Hunt finds a missing hook and a small serial fix follows.
- P5-7 (Task 3). The policies live in `tools/dev/routes/god_hunts/<id>.gd`, so the later groups never touch `behaviour_check.gd`. Cost: none.
- P5-8 (Task 3). The loadout is checked, not chosen at run time. Cost: a refusal names the missing key.
- P5-9 (Task 7). Hunt 4's standard is drawn over its bearer, not a Structure, and `_raise(i)` is replaced (C4). Cost: a blow at the pole, not the man, would do nothing.
- P5-10 (Tasks 4, 8). Hunts 1 and 5 subclass `ExodusDirector` (MS H3), with the `tune_` variables and the overrides the spec lists. Cost: more overrides.
- P5-11 (Task 4). The search list is chosen by walk order from the Temple's door, household 1's house second, household 2's last. Cost: a different order; the 30 s slip still holds.
- P5-12 (Task 5). `WitnessObjective` subclasses `StarsObjective`, which does not read `lost_reason()`. Cost: one file.
- P5-13 (Task 6). Hunt 3 counts frights in its own `_alarm()`; no base hook. Cost: none.
- P5-14 (Tasks 9-13). One per-type task per Hunt. Why: the five Hunts share no code after Task 3, and each tuning loop reruns 18 runs. Cost: five more reviews than one shared task.
- P5-15 (Tasks 9-13). Decree on Hunts 2-4 is recorded as it falls. Cost: re-recorded at the planned re-gate.
- P5-16 (groups B and C). At most three worktrees at once. Cost: wall time.
- P5-17 (Task 14). FLOW loses the real Hunt (P2-14's shape); wins are the references'. Cost: a win walk later.
- P5-18 (Task 14). Photographs include Prepare at all five tiers. Cost: none.
- P5-19 (Task 15). `land.sh --bench=kak-god-t1r`, by hand where its trial merge with `feat/Develop-Main` stops it. Cost: none.
- P5-20 (all). Your later tier fills re-gate their Hunt (answer 2). Cost: none.
- P5-21 (Tasks 1, 4-13). Anchor lines are seeded in `mission_hints.gd` and `references.tsv`, so parallel merges never touch the same line. Cost: a text conflict the controller resolves as a union.
- P5-22 (Task 14). The DEV tab's Hunt row is compact (title only) and the hint moves below it on the DEV tab only. Cost: layout only.

## The pre-flight (`preflight.md`, against `f130d4f5`; adopted by C1-C8)

The scan read the spec, the plan and the briefs against the code. It found 8 blocking items, 24 minor ones, and a long list of things that checked out. The blocking items became C1-C8. Each is listed here with what it was.

- B1. New variable names in Task 2 clashed with members that already exist (`reliefs`, `beats`, `patrol_size`, `mates`, `post_names`). Fixed by C1. Cost if missed: a parse error.
- B2. Constants named as the plan said shadowed the parent's. Fixed by C2. Cost: a parse error.
- B3. Hunt 2's witness as specced would never deliver word at the Temple, and could lose the night at the bellkeeper. Fixed by C3.
- B4. Hunt 4's standard with no Structure breaks the moment it is raised. Fixed by C4.
- B5. A Hunt 3 warden could lose the night, unwarned, by fleeing to the Citadel. Fixed by C5.
- B6. Five more DEV cards did not fit, and two tests pin the tab. Fixed by C6.
- B7. A Task 3 test asserted something false for Passage. Fixed by C7.
- B8. A whole Hunt's gate cannot run in one call under 10 minutes. Fixed by C8.

The 24 minors, each with how it was settled:
1. Hunt 1's patrols were ringed at 0.5, not 1.8 apart: `_step_patrols()` and the first placement are overrides. (Task 4.)
2. Exodus always runs `_relieve_watch()`: Hunt 1 makes it do nothing, and the relief numbers are the inquisitors'. (Task 4.)
3. Exodus puts "The Temple sends searchers" on the strip even with no hounds: overridden in Hunts 1 and 5.
4. An empty `shut_at` is more than a variable swap: the loops were guarded in Task 2.
5. Exodus's quiet check read its own beats: it reads `tune_beats` now.
6. Hunt 1's soldier watch needs its own `_post_to` and `_takes_post`. (Task 4.)
7. The Tier 1 shared rules are not reusable code for an Exodus subclass: Hunt 1 builds both, in PF2's order (sight before out).
8. Hunt 3's guards: the plan keeps soldiers (the pre-flight's lay-watchmen note was not applied).
9. Hunt 3 uses `_alarm()`, not a new hook (P5-13).
10. A fright from the town's own panic counts (H14).
11. Results titles: added (H15), the reason strings named.
12. Hunt 5 overrides `_step_held()`: the base frees on one seizer leaving.
13. CALL THE GUARD takes the 12 soldiers nearest the click: a policy note.
14. The 1.6 rule binds between opposition members only (MS §0 now says so).
15. Dominion's Hunt 3 route: the spec's Plays column names the loadout.
16. Task 2 reference reruns: extended if `escort_director.gd` or `warning_director.gd` is touched (they were not).
17. Parallel merges conflict at the shared lists: anchors seeded (P5-21).
18. The spec and plan were untracked: committed before the worktrees were cut.
19. The bench base is `kak-god-t1r`, not `kak-god-p3`.
20. Open issues were still open: answered by C9.
21. MS cited "answer 6" for two things: noted.
22. MS §2 "2 of 3 believers" means two households of three: reworded.
23. A test that no wish lands on the Hunt's people: added to Task 1's list and to each Hunt's suite.
24. P2 tests whose shape changes, not only ids: re-pointed in Task 1 (each changed assert is listed in `task-1-report.md`).

## Rulings by task

Each entry is tagged: **(task)** the implementer's choice, **(controller)** the controller's ruling, or **(you)**.

### Task 1: Hunt rules and data (`a5807046`; review CHANGES, fixed in `ebad25cb`, haiku re-review APPROVED)
- A Hunt's clock is the Hunt's own tier clock plus the Faith clock. Why: a Hunt is played only at its tier, so it equals the god's. Cost if wrong: one line. (task)
- The seven stub suites each run one check. Why: the runner counts a suite with no checks as a failure. Cost: red suites until filled. (task)
- Placeholder cameras per Hunt until the Hunt's own task sets them. Cost: none. (task)
- The new scripts' `.uid` files are committed, as the repo tracks them. (task)
- Review I1 (fixed): the gifts check could not fail. The fixture god now carries a gift and the assert compares it. The nits (a `COPY` table, each frame's text compared word for word) were taken. The rest were parked and are in the fix wave (M2).

### Task 2: base hooks (`900f9339`; review APPROVED)
- No new ruling. C1 (names), C2 and C9 applied. An empty `shut_at` leaves no gate shutting and no "SHUT IN" tag. The door-spots test checks spots at `tune_mate_gap`, since `_door_spots` reads only the gap. The three changed bases were proved byte-identical: digest, `crowd_check` and calm, and the Exodus and Ringer references.

### Task 3: Hunt tools (`e0f9ae6e`; review APPROVED, six minors parked for the wave)
- `problems()` returns each missing key alone, so C7's expected lists compare exactly; other failures read `slots n>3`, `might n>m`, `no keys`. Cost if wrong: a looser test. (task)
- The real-tree literal lists in `test_hunt_tools` are pinned to a Tier 1 table, so your filling a higher tier moves nothing. Why: otherwise a test breaks when you fill a tier. (task)
- `hunt_gate.sh --judge` counts `pass=K/N` with N = 6 minus excepted types. A type file with no gate line is FAIL. Why: a missing file must not pass. (task)
- A refusal of tier or loadout is printed before the older outside-the-tree refusal. (task)
- Dominion's loadout follows the spec's Plays column, not the plan's mention of Oathbound. (task)

### Task 4: Hunt 1 director (`e140bdd0`, fix `427c2527`; review CHANGES, re-review core rule holds)
- P5-T4-1. The Gaze: Tier 1 shows none. The base steps a Gaze meter, so the Hunt gives the base a private one and takes it away again. The HUD draws no bar. Cost: a stray bar at Tier 1. (task)
- P5-T4-2. Banners and the strip: the base's timeline banner is replaced by the Hunt's own (`THE <NAME> HOUSEHOLD SLIPS OUT`); a household's time moves to its real time every look. (task)
- P5-T4-3. Patrol gap: the pair is placed in file along the street, not on a ring across it; on the narrow market street a ring snapped to 1.45 apart. (task)
- P5-T4-4. The search's pace: inquisitors walk the list at 0.6 of duty pace and a trail at 1.0, a seizer at 1.0; the first stop is at least 8 from the Temple's door; listed doors at least 4 apart. Tuned later by Task 9. (task)
- P5-T4-5. The 30 s slip is every household's, the first included, with a net: an inquisitor within 5 of a door whose household is still inside brings it out. Why: the search must never find a household still inside. (task)
- P5-T4-6. The search's ETA counts a household that is out and not done, so a house listed after it counts down honestly. (task)
- P5-T4-7. The sight (2.5) equals `EscortDirector.SIGHT`, which the base reads as a const; a test holds them equal. (task)
- P5-T4-8. The pair is sent to places 2.3 apart and the place must be reachable from the door. Why: the review found the two inquisitors 0.0-1.1 apart at stops. (task, review I1)
- `_watchman()` is not overridden: it only dresses a lay citizen as a watchman, and its one user here is the inquisitors.

### Task 5: Hunt 2 director (`d916d6b7`; review APPROVED, minors parked)
- The north-east house is the quiet dwelling whose street is closest to the 22-32 range (19.9), because Aldermere has none in range there. Cost if wrong: a shorter first walk. (task)
- The mates who could carry the word are taken at the witness's death, before the crowd's fright, so a held mate cannot carry it. (task)
- The opening banner is `SILENCE THE WITNESS` (the spec names none). (task)
- `SW_BEATS` is the Lamb's patrol lines for "quiet"; the camera spot is found by search to clear the padded HUD stack. (task)
- `test_mission_hints.gd`'s list is edited, because it pins the count of hint rows. (task)
- The spec's 35-50 s walk is unreachable (21-34 s, measured). The measured walks stand; no ruling was needed, and summary item 8 lists the geometry the town could not give.

### Task 6: Hunt 3 director (`30add747`, fix `1e926e3d`; review CHANGES, re-review APPROVED)
- Wardens are lantern-and-cloak people; the captain is the cleric nearest the Temple's door. (task)
- Aldermere has no east well: the captain's east stop is the one east house. (task)
- A body freed without a death (left the map) is stopped, for the captain as for a warden: expelled, not escaped. Why: the base would call it a loss. (task)
- The door ring is three slots wide, so the captain's two waiting guards stand 1.73 apart. (task)
- Frights are counted in real seconds, the town's panic included; an uncounted alarm still sends him to hide. (task)
- `test_mission_hints.gd` gets the three rows (it pins the hint table). (task)
- **P5-T6-R1 (controller).** The captain's last walk is long and warned: at least 45 s out at the first look of the countdown. Why: the review found the Citadel warning at 17 s. The town's geometry cannot give that by stop order alone, so the order puts the farthest house last and a street point is added before the gate. Cost if wrong: a walk that feels long, or a sudden loss. Measured: 46.4 s at the fast end, 63.1 s at the slow end. Renamed the two const names to the Hunt's prefix.

### Task 7: Hunt 4 director (`7ff69f93`, fixes `36d79f64`, `aef1846f`; reviews CHANGES twice, then accepted on mutation evidence)
- P5-T7-R1 (task). The bearer's pace is in ground units a second (0.5), not a share of a citizen's pace. Escorts walk at 1.3 times his pace so they keep up. Why: the spec's 50-70 s walks only hold at 0.5 u/s.
- P5-T7-R2 (task). A bearer marches on the nearest house no other marching standard is bound for. Why: "nearest" would send two companies to one door and bunch them.
- P5-T7-R3 (task). A march lasts at least 50 s: shorter streets make the company walk slower. Why: this makes "every instant loss warned at least 45 s out" true by construction. Cost: the spec's pace lever is inert on short routes (summary item 8).
- P5-T7-R4 (task). Musters are the spec's points moved up to 0.5 to the nearest street ground with room for three. The spec's south-west muster is in a walled yard and is at (-10.5, 14.0). Cost: a slightly different start.
- P5-T7-R5 (task). `_found()` is false once all four standards are broken, so the director never finds its quarry on a won night.
- P5-T7-R6 (task). The camera spot is (3.0, -6.0): no spot keeps all seven opening tags clear, so the test checks the first muster, its house and the bearer.
- P5-T7-R7 (task). The standard is Person's own pennant badge: no art, no new drawing code.
- **P5-T7-R8 (controller; you may reverse it).** A guarded bearer who is struck is judged by the look before the blow: fear from witnessing this very death does not count against the escorts. The escort who takes the standard up and his fellow are steadied for 5 s, shown by `THE STANDARD IS TAKEN UP` and the tag `STANDARD - TAKEN UP`. Why: otherwise any loud kill scatters the company and a take-up never happens. Cost if wrong: loud powers are easier or harder against a standard. (Summary item 7.)
- P5-T7-R9 (task, accepted). No muster's street to a house passes within 2.7 of another house's door. The spec's second house had no such door, so the next nearest dwelling (6.17, 5.39) replaced it. Cost: a different house.
- P5-T7-R10 (task, accepted). The escorts march in file, 1.3 ahead of and behind the bearer, not "0.9 to either side". Why: a one-wide street has no side, and a file never crosses at a corner. Standing, they stand opposite each other along his last heading first. (As corrected in fix round 2.)
- P5-T7-R11 (task, accepted). A bearer who has taken a standard up stands until his fellow is within reach, for at most 5 s. Why: otherwise the new bearer walks off unguarded. (Review RI-1; accepted on a per-frame test with a mutation that shows 12 bad frames.)
- Parked (Hunt 4 follow-ups): M2, M4 (Magnify extends steadiness: summary item 11), M5 (a re-aimed bearer keeps the raise's pace; fixed in Task 12).

### Task 8: Hunt 5 director (`489df1c3`, fixes `9cb4c0f7`, `9da63435`; reviews CHANGES twice)
- P5-T8-R1 (task, accepted with a change). Aldermere's lanes are one or two cells wide, so three escorts 1.7 apart cannot all be within 1.6 of the believer. Each escort has his own place. "With the procession" means within 1.6 of the believer or of his place, with a 2 s grace for geometry only. The ESCORT tag uses the same test. Cost if wrong: an escort who is not able shown as able.
- P5-T8-R2 (controller). A house is accepted only if its door has room at the door and along the road, and a walk of at least 25 s (so forming 8 + walk + burn 12 is at least 45 s). Two house points moved: north-east (12.5, -11.0) to (6.0, -12.4) and west (-11.5, 2.0) to (-11.5, 4.0). The spec's "25-32 units, 50-64 s walk" is unreachable: duty speed is 1.6 times pace. The moved points stand; the walk length was left to Task 13. Cost: shorter walks (28-33 s).
- P5-T8-R3 (task). Leaving Is Prohibited bars count an escort as held. A believer the god kills reads `A BELIEVER IS KILLED - ONE MORE AND THE HUNT IS LOST`. Escorts wait hidden in the house until forming. A second procession reaching the pyre while one burns waits 5 units short. The march waits up to 3 s for a straggling escort, so a corner never frees a believer by luck. The pyre is a tag (no world art).
- P5-T8-R4 (task). The first camera spot, (-6.0, -5.5). (Replaced by R5's.)
- P5-T8-R5 (task, accepted by the controller). The file needs a lane behind the door, which only some doors have. Houses are west (-12.75, 6.75), north (2.75, -12.25), south-east (14.25, 13.25) and south-west (-8.25, 10.75). The north house replaces the north-east. `FH_WALK_MIN` is 27.5 s. Camera (-7.0, -4.5). Cost: a different set of doors from the spec's.
- P5-T8-R6 (task, disclosed). The place-spacing test is "more than 1.5" (the planned places reach 1.60 at a right-angled lane corner), with a cap of 2% of road points under 1.65 (measured 0.7%). Bodies are pinned by a stepped test (at most 3% under 1.6, nothing under 1.0). It was loosened without a ruling in fix round 1 and disclosed in round 2.
- **P5-T8-R7 (controller).** Accept the south-west exception. No fourth dwelling keeps 2.7 from the other three roads (Aldermere has three approaches to the Temple's plaza; the south-east and south-west roads share one lane). The south-west house keeps 2.0 from the west road and 1.5 from the south-east road. `FH_MERGE` 7.0 (not 5.0) starts the road-to-road rule. Why: it is geometry, only player-favourable (one power may reach two companies), and nothing is hidden. Cost if wrong: you may not want a rule exception. Task 13 must log any look where two companies' escorts are within 1.6. (Summary item 8.)

### Task 9: Hunt 1 policies, tuning and references (`59784f8f`; final `bc60e1bd` and the tests-only round `a66862dc`; DONE_WITH_CONCERNS)
- **P5-T9-R1 (controller).** The pair gap with a relief is fixed in the director, not the policy: pair slack 0.6, one shared base pace for every inquisitor, both of a pair re-ordered together, and the gap sampled only when both stand at their places. Test `_relief_pair`. Why: the printed gap was 1.47, and a relief closed on his fellow. Cost if wrong: the pair bunches again. (task choices: P5-T9-2 below.)
- P5-T9-1 (task). Patrols walk at their slowest man's pace and their lead arrives at his own place of the pair. Found while testing the 2.0 gap in motion. `HF_PATROL_GAP` moved 1.8 to 2.0.
- P5-T9-2 (task). Inquisitors share one base pace (1.0). A director change beyond the brief, needed for R1.
- P5-T9-3 (task). Ember (Ruin) and Thornwall are not used as fillers. Thornwall is cast only across the street the search takes next.
- P5-T9-4 (task, **not granted**). The task asked for an idle allowance for Death on Hunt 1. None was given. Death's idle (94-120 s) goes to you (summary item 4).
- **P5-T9-R5 (controller, WITHDRAWN).** Round 3 added a relief pair for the Inquisition when the watch empties, to stop the empty stretch. It dropped the gate from 4/6 to 2/6: the pair came too late. The controller reverted it (`28b1ae4e`) and the tree went back to `59784f8f`. Why withdrawn: three tuning rounds were spent and the idea made it worse. The idea lives on as the pacing redesign on paper (summary item 4). Cost: Hunt 1's empty stretch stays.
- **P5-T9-R6 (controller).** One try at a Decree policy (the inquisitors caged first); if it fails, report the concern to you under R40. It failed. Decree 0/3 is reported (summary item 2).
- P5-T9-5 (task). The pair of 0:00 is set in file facing the first stop. A director change beyond the brief, needed so the pair rules hold on the walk.
- **P5-T9-R8 (controller).** The inquisitor pair walks in file, to the same standard as Hunt 2 and Hunt 3: the nearer man goes to the farther place, and the rear man holds until the gap opens to 2.3. Measured: 0.0% of steps under 1.6 plain, 1.9% with a relief. Why: the review measured 5-8% under 1.6 on the walk. Cost: the fix changed when the search meets each household, and the gate fell from 4/6 to 0/6. Accepted: the pair rule is a hard rule, so the tree stays (summary item 4).
- **P5-T9-R9 (controller).** Thornwall is dropped from Passage (so its idle becomes the Mirrorfold cooldown of 54 s, under P5-T11-R2). Dominion's Whisper and Discord are cast only when a believer is about to come in sight. Ruin, Death and Veil keep their idle-triggered early kills and disclose them (summary item 7). Why: the review found two filler casts. Cost: Dominion's idle went over the bar on two seeds (43/52/60).
- P5-T9-6 (task). Two director changes beyond the brief, found by the walk test: an unreachable place sends the man to the door (a stall), and the relief and the inquisitors are kept from the Lantern Bearer.
- Tuning rounds: round 1 moved `HF_BELIEVER_PACE` 0.45 to 0.40 and `HF_OUT_AT[1]` 110 to 140; round 2 was policy only; round 3 was reverted. Final: `hunt_gate hide_faithful tier=1 pass=0/6 none_lost=3/3 median=186 FAIL`. The 21 rows were re-recorded from this gate, losses as they fall.
- Fix round 2 (tests and one comment): four tests that fail by mutation for the four director fixes, a behavioural no-filler test that names its target, and corrected figures.

### Task 10: Hunt 2 policies, tuning and references (`10f2d099`, fix `3be0cbe9`, round 2 `9c1b0d90`; reviews CHANGES then approved)
- Hunt 2's houses send in the order west, north-east, south-west, south-east (tuning round 1). The levers the brief names (witness pace, pause) were not needed. (task, then ruled below)
- A policy's two-cast pacing (an opener, then a finisher at least 9.5 s later) keeps the real idle at 45 s or less without filler. The shared plan's bystander prep is not copied. (task)
- Veil opens with Blight on the Bell Tower at 0:00, as the spec says. No toll means the clock stays at normal speed, which also keeps its median at 193. (task)
- `WitnessDirector.eta()` uses the walk's time only while his goal is the Temple's door, otherwise the street. A sheltering witness shows `WITNESS INSIDE - TEMPLE IN m:ss`. Found by the Veil gate. (task)
- Decree's policy is Leaving Is Prohibited on the leading witness whenever ready. Its three losses are recorded as they fall (C9). (task)
- **P5-T10-R1 (controller; you may reverse it).** The house order west, north-east, south-west, south-east is accepted as an easier-direction change outside MS §7's levers. Evidence: Death seed 1 lost with the old order and won in 153 s with the new; Dominion seed 1's idle fell 90 to 40; Veil seed 3's idle fell 54 to 44. Spec §3's Houses row was updated. Why: the last witness is then the one 7 units from a gate, and the short north-east street comes before the Lantern burns the clock. Cost if wrong: Hunt 2 is easier than the spec says. (Summary item 7.)
- **P5-T10-R2 (controller).** One rule for openers: a cast must have a real effect on that night's opposition when it lands. Holding a real cast to a later moment is allowed and disclosed. A cast with no real effect is a filler. Dominion's Discord and Death's opener are real and held. Behaviour is checked by an aim test.
- **P5-T10-R3 (controller).** A witness's two mates stay more than 1.6 apart on every walk: in file, 2.6 apart, over 1.6 but at the turns of the road (at most 5% of the steps), measured with bodies moving on all four streets. Implementation: the first mate 1.6 behind on his trail, the second 1.0 ahead, mates at twice his pace, sent anew at 0.3. A door place the street does not reach is not a place (the south-west pocket). Why: the review measured the mates under 1.6 for 19.8 s of one 31 s walk. Cost: the spec's `MATE_SIDE` lever is gone (R5).
- **P5-T10-R4 (controller).** The mate pace, retarget and trail numbers are accepted as the implementation of R3 (`SW_MATE_QUICK` 2.0, `SW_HEEL_RETARGET` 0.3, `SW_HEEL_STEP` 0.4, `SW_HEEL_KEEP` 24, `SW_HEEL_LOOK` 1.5).
- **P5-T10-R5 (controller).** `SW_MATE_SIDE` is retired by R3. Spec §7 marks the lever. Cost: one fewer "easier" lever for Hunt 2.
- Final: `hunt_gate silence_witness tier=2 pass=5/5 none_lost=3/3 median=193 excepted=decree PASS`. All 21 rows were re-recorded after R3.

### Task 11: Hunt 3 policies, tuning and references (`211a1b6e`, `06670737`, `05d981d9`, tests `7a8f1747`; reviews CHANGES, re-review CHANGES, then accepted)
Task-reported round-1 rulings, named by the task before the controller reused R1 and R2:
- (task, round 1) R1: the captain's ETA walk term is multiplied by 1.15 (`EI_WALK_SCALE`), not by 1 / 0.85. The error is nearly additive per leg, so 1.15 is never early at any pace and keeps the 45 s window.
- (task, round 1) R2: the captain's ETA is cached on a key of clock, place, state, leg, pace, slow, visit and clock rate.
- (task, round 1) R3: Silent Doom aims at the man where he stands, not ahead, because its victims are fixed at the cast. Why: a lead of 0.86 missed every time.
- (task, round 1) R4: a policy may strike the next target's guard at his door in the chain wait. It is a real cast.
- (task, round 1) R5: the pooled median missed at 157 s with the allowed levers; round 1 was flat and was reverted; the task recommended moving the first warden from 20 to 44.
Controller rulings (these names stand as the controller filed them):
- **P5-T11-R1 (controller).** `EI_WARDEN_AT` becomes [44, 94, 144]. The median went from 157 to 181. Why: the "harder" lever (C10). Cost: only 1 s of headroom; a first warden at 0:43 puts it under 180. (Summary item 7.)
- **P5-T11-R2 (controller).** Passage's idle of up to 60 s is accepted when it is exactly the Mirrorfold's cooldown and nothing else in its two keys has a real use. Observed 54. No filler. Why: the cooldown is 54 s and Passage has no other power. Cost if wrong: Passage's rows fail the bar. It applies on Hunts 1, 3, 4 and 5 (summary item 1).
- P5-T11-R6 (task). Ruin strikes the next target's guard only in the last 24 s of the wait (`RUIN_PREP_LEAD`), so the 44 s first wait does not print an idle of 50. The controller accepts it as an early real cast (summary item 7).
- **P5-T11-R7 (controller).** Dominion's Madness Bloom is cast once for each target, and only on a guard standing within 3.0 of his door, and only with a real effect. A behavioural test drives the policy for 80 looks and counts the casts. Why: the review found a Bloom cast over and over as a pacing filler. Cost: Dominion's idle (37-39) comes from real casts only.
- **P5-T11-R8 (controller).** The captain's two guards stay more than 1.6 apart at stops (always) and on the walk (at most 5% of steps). Fix: the first guard 0.9 back on his trail, the second 2.4 further back, both at 1.6 times his pace; indoors, on the two farthest-apart points round the door.
- **P5-T11-R9 (controller).** Corner transients up to 5% of all walk steps are accepted, tested and disclosed (measured 3.9%). The dips are the turns of the road and the first seconds out of a door.
- Final: `hunt_gate expel_inquisitor tier=3 pass=4/5 none_lost=3/3 median=181 excepted=decree FAIL` (Passage's idle only). 19 of 21 rows moved and were re-recorded.

### Task 12: Hunt 4 policies and references (`e4646b0d`, fix `257de1db`; review CHANGES, re-review APPROVED)
Task-reported, first report:
- (task, round 1) R1 = **P5-T12-R1**: a bearer on duty with no way to walk (his street was shut by a Thornwall that has withered) is sent again each look. Found by the Passage gate. Why: MS §5 says a held bearer takes the march up again.
- (task, round 1) R2: a Mirrorfold laid before a raise is a real cast when the company's street runs through it within 30 s; its way out must be walkable over the whole oval.
- (task, round 1) R3: Death plays on Death Mark with Pestilence kept for a standard within 14 s of a house. Loud powers are not cast, because they turn the Lantern's clock.
- (task, round 1) R4: Dominion's Discord opener and a whisper finisher 15 s later, as a held real cast.
Controller rulings of the review round (these names stand for the review fixes):
- **P5-T12-R2 (controller).** A bearer whom a power walks (a whisper) has his file stand ahead along the road he is walking and behind along his trail. A bearer held in place gets the lane pair. Fixes a 27% bunching of the whispered file.
- **P5-T12-R3 (controller).** A planted or held company's posts are 2.6 apart (`BH_LANE_GAP`), so the stopped bodies stand more than 1.6 apart.
- **P5-T12-R4 (controller).** Dominion keeps the spec's loadout. Its idle of 113 s goes to you as structural, with the Madness Bloom evidence (131/131/175 s, idle 49-57, median 176.7 if adopted). Why: no key of the spec's loadout speeds a whispered walk. Cost if wrong: Dominion misses on this Hunt. (Summary item 5.)
- **P5-T12-R5 (controller).** Pair dips caused by the player's own powers (Mirrorfold, Death Mark, Leaving Is Prohibited) are exempt and disclosed with their measured shares (11.7%, 48%, and the cage). The director's own placement is not exempt and is tested (the none run: 0 of 1932 walking samples). Cost if wrong: a power that bunches a company could be called a bug.
- Final: `hunt_gate break_hunt tier=4 pass=3/5 none_lost=3/3 median=184 excepted=decree FAIL`. No tuning round was needed.

### Task 13: Hunt 5 policies, tuning and references (`1c47e447`, `e7ee928c`, `60a012b3`; reviews CHANGES, then APPROVED)
- P5-T13-R1 (task). `PYRE IN` holds the minimum of the per-look estimates and is never interpolated. A stalled march holds the figure. Found by test: 342 rises before.
- P5-T13-R2 (task). A give-way cell must be within reach of the escort's own place or of the believer, so geometry alone cannot make an escort unable.
- P5-T13-R3 (task). "Stops" for the spacing rule are forming, the stake and the wait short of it. A stall for a straggler is part of the walk.
- P5-T13-R4 (task). The lead's place at the stake and the file's bend spacing (2.2 apart, more than the witness range of 2.0) are director changes forced by the pair rule, not tuning.
- P5-T13-R5 (task). Ruin, Veil and Death finish a procession no sooner than `FH_GAP` 20 s after the opener (the same kind as Hunt 2's). It is a held real cast, disclosed (summary item 7).
- P5-T13-R6 (task). Ember, Smite-beside, Thornwall-ahead, Pestilence, Glacial, Heaven Splitter and Tsunami are not cast on this Hunt (measured or argued); each unused key is stated.
- P5-T13-R7 (task, **superseded by R12**). Passage's idle of 60 was reported as the mirror cooldown, and a pace of 0.4 would push it to 61.
- P5-T13-R8 (task). A pooled median of 164 was reported and not tuned around.
- **P5-T13-R9 (controller).** `FH_PROC_AT` becomes [44, 109, 174, 239] as a "harder" lever (the same kind as R1 of Task 11). The median went from 164 to 178. `FH_GAP` stays, as a held real cast. Cost: 2 s short of the band. (Summary item 7.)
- P5-T13-R10 (task). The hold's idle numbers are disclosed (with the hold: Ruin 186/196/158 and idle 44-45; without it Veil prints idle 46).
- **P5-T13-R11 (controller).** The survivors of a fallen escort are re-dealt to the two farthest-apart places of the file (`_redeal`), tested with bodies, red on the old code. Why: veil seed 1 left two survivors 1.40 apart.
- **P5-T13-R12 (controller).** Passage's mirror is laid 1.5 ahead of the lead (the shortest clear lead). The idle becomes 54, which is the cooldown itself, so P5-T11-R2 covers it. The median fell from 178 to 165 because of it. Supersedes R7. Why: the report had said the 59.4 s idle was the cooldown; the review showed it was the chain, the forming and a 4.5-unit walk. Cost: the median is further under the band. (Summary items 1 and 6.)
- P5-T13-R13 (task). A per-power reach table for the no-filler test; text fixes; the overlap log's blind spot (the south-west company) is noted, not fixed.
- Three tuning rounds: pace 0.4 (reverted), four escorts (reverted), the schedule shift (kept). Final: `hunt_gate face_halcyon tier=5 pass=5/6 none_lost=3/3 median=165 FAIL`.

### Task 14: screens and Game (`a7b9a881`, minors `909a509a`; review APPROVED, merged `baa63eb2`)
- P5-T14-1 (task). The second DEV row is 36 px high, not the plan's 40. At 40 the hint touched the cards. Cost: layout only.
- P5-T14-2 (task). The results photographs use the real `hide_faithful` ids and reasons.
- P5-T14-3 (task). In FLOW's Lantern part the "were there no Hunt" seed probe is dropped. A drawn night can never be a Hunt id now.
- P5-T14-4 (task). A staged photograph looks at what it stages.
- Review minors (taken in `909a509a`): the board photograph re-taken with the pointer off the window; the DEV hint names Up and Down (with a keyboard test); the report's "second house" corrected to "the fourth procession"; `hunt_label()` takes its room from the real count. Not taken: edge-label clipping (a general HUD pass).
- The two known FLOW flakes ("a restart during the ending" and the Festival draft) failed once under load; the second run alone passed (209 checks).

## The landing

Task 15 is the controller's. Hunt gates were not rerun on the merged tree: the 105 rows reproduce their checksums there, so the runs are the tasks' runs. `feat/god-progression` was brought in at `1b6ab0b2` (the Capital walker and the Passage fold) and merged cleanly (`bfecf5ce`). The figures are in the Summary's Landing section.

## The milestone review (opus) and the fix wave

The review of the whole branch against `feat/god-progression` found no critical issue. It checked the base directors (identical by default), C1 and C2, the constraints, the wiring, every Hunt's rules and the order of the rulings (no two contradict each other). It called a small fix wave.

- **I1. Missing disclosures** (the controller's, taken). `for-user.md` lacked the formation changes, the geometry the town could not give, the P5-T8-R7 exception, Hunt 1's idle-triggered kills, the wording of the early casts, and the unlisted tuning moves. All are now in the summary's items 7 and 8. Why: you had approved the sketches and not these changes. Cost if missed: you would learn of them from the code.
- **I2. P5-L-R1 (controller): the warning window on Hunts 1 and 2.** Hunts 3-5 were built to "every sudden loss is warned at least 45 s out"; Hunts 1 and 2 were built earlier. Hunt 1's second seizure can lose with about 10 s of warning (the spec said 20-30 s). That is **below** the window, and is folded into the Hunt 1 pacing redesign (march a seized believer at least 20 s, or add a strip row). Hunt 2's `WITNESS - TEMPLE IN` first shows 19-31 s out, but the house's `WITNESS OUT IN` tag (up to 55 s) starts the window earlier, and a loud cast that sends a house at once is bannered and the player's doing. Accepted. No code change, because it would move Hunt 1's 21 rows. Cost if wrong: a sudden loss with 10 s of warning on Hunt 1. (Summary item 9.)
- **I3. Stale comments** (fix wave). Comments still described side-by-side formations that the reviews removed, in Hunts 2, 3, 4 and 5. All reworded to the code as built. `FH_ESCORT_RING` (unused) was deleted. Why: someone "restoring the documented behaviour" would bring the bunching back.
- **I4. P5-L-R2 (controller): Hunt 4's guarded fright.** The spec says a guarded bearer's death or fright passes the standard to an escort. The code passes it only on a death. A frightened, guarded bearer keeps the standard and runs off with it; a guarded fright "only shakes". Ruled to stand. The class doc was reworded to say so. A test (`test_break_hunt.gd:904`) already pins it. Why: this reads the spec's "a guarded standard only shakes" for the fright. Cost if wrong: reversing it moves Hunt 4's 21 rows. (Summary item 10.)
- **Minors.** M1 (Task 3's parked tool issues), taken: `--route` is refused on a Hunt id; `--level` other than 1 is refused on a Hunt; `hunt_gate.sh --judge` requires `route=god:<type>` in the gate line; `--except` accepts only `decree`, and only on Hunts 2-4; the `exit 2` check that could not fail is replaced by a real run of the script on a two-file fixture (mutation-checked). M2 (test nits), taken. M3, taken: `tune_gate_watch` is 1 in Hunt 5, so a later change cannot divide by zero. M4 and M5 (stale docs, joined lines), taken. M6 (Hunt 1's lamp ETA ignores the man's pace), M7 (counters in Hunts 1 to 3), M8 (Magnify and steadiness) and M9 (small tidy-ups): not done, noted in the summary.
- **Re-review (sonnet): APPROVED**, with two tiny follow-ups, both done (`559fb61c` anchors a tool-refusal test on the printed line, `e85cafb9` adds a doc line). Single suites after the wave: `test_hunt_tools` 329, `test_hunt_book` 662, `test_god_lantern` 194, `test_face_halcyon` 318, `test_break_hunt` 513, `test_hide_faithful` 334, `test_silence_witness` 452, `test_expel_inquisitor` 766, all with 0 failures. The three none rows of Hunt 5 were unchanged. The full suite and all references are the controller's, at the landing.
