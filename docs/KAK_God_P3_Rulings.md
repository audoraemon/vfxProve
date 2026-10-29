# KAK God Progression P3: every ruling

God progression P3 ("First Rite") was built straight through, subagent-driven, on `god/p3-rite` on 2026-10-28 and 2026-10-29, landing on `feat/god-progression`: 8 build tasks, a landing task, this note, an opus milestone review, one fix wave and one Passage policy round. A ruling is a choice the spec or plan left open, or a place where the code said something else. Each entry has what was decided, why, and the cost if it is wrong (where the source gave one; where it did not, the cost is stated from the entry's own reasoning). The mission spec is `docs/superpowers/specs/2026-10-28-kak-god-p3-first-taste.md` (cited MS §n), the parent spec `docs/superpowers/specs/2026-10-26-kak-god-progression-design.md` (§n), the plan `docs/superpowers/plans/2026-10-28-kak-god-progression-p3.md`. P1 and P2's rulings (`docs/KAK_God_P1_Rulings.md`, `docs/KAK_God_P2_Rulings.md`) hold unless one below changes them.

Groups, in order: C1-C11 (controller rulings), MS R1-R14 (the mission spec's, as you approved them), pre-flight B1-B5, R1-R13, G1-G8, plan rulings P3-1 to P3-24, the rulings each task reported (T1-T8), then the reviews, the fix wave and the Passage round. Where two disagree, the controller rulings (C) beat the plan text; the pre-flight rulings were adopted as written (C8). Task 9 (landing) and Task 10 (this note) reported no rulings of their own.

## Controller rulings C1-C11 (`.superpowers/sdd/godp3/rulings.md`)

- C1. Base and landing. Worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-god-p3`, branch `god/p3-rite`, cut from `feat/god-progression` at `a0185497` (P2 and its fix wave). Landing: trial-merge the then-current `feat/god-progression`, gate the merged tree, fast-forward `feat/god-progression`. Never merge into or push `feat/Develop-Main`. Tag `kak-god-p3` locally; the controller asks you before any push. Why: the god work lives on its own line until you decide. Cost if wrong: a branch to move.
- C2. Never edit `GodTree.TABLE` or `GodTreeDev.TABLE`. Tests use the dev fill and take keys from the tree at test time. Why: you fill Tier 1 in parallel, and a test that assumes a table breaks at the merge. Cost if wrong: a merge conflict or a test fixed at landing.
- C3. No existing reference row and no digest may move (digest `61267b7e90524d800bf1c3473a71146b`, `crowd_check` `-935602679`, 286 rows). New rite references are added rows, not re-recorded old ones. Why: a rite is a new night; the code it shares must stay byte-identical on every other night. Cost if wrong: a re-record and a review of the mover.
- C4. No PixelLab. Text, drawn shapes and existing icons only. Cost if wrong: art later.
- C5. The First Taste spec is approved with all six recommended answers (the Yank yes; the Main Gate; no wishes or Faith; a lost rite retried the next night; a won rite leaves the Notice; the Watchful Bell slows only the bell's climb). Its design is not re-asked.
- C6. Tier 1 routes (`god/t1routes`) is in flight in another session and will land on `feat/god-progression`; the controller trial-merges it before landing P3. Tasks avoid gratuitous edits to the Tier 1 mission files. Why: fewer conflicts. Cost if wrong: hand-merged hunks.
- C7. Bench at landing vs `kak-god-p2`; FLOW and the bench need no other Godot running.
- C8. The pre-flight (`preflight.md`: B1-B5, R1-R13, G1-G8) is adopted: every recommended fix is binding on the task(s) it names, over the plan text. Where it offers options, take its first recommendation.
- C9. Tasks run serially in this one worktree (1, 2, 3, 4, 5, 6, 7, 8), not in parallel groups: one worktree, no inner merges, suite at jobs 8. Task 9 (landing) is the controller's; Task 10 (docs) comes after the milestone review. Why: the tasks share files; worktree overhead costs more than it saves. Cost if wrong: wall time.
- C10. The controller runs the long gates at landing (all references, FLOW alone, bench). A task runs FLOW only where its brief says, alone, after `tasklist | grep -i godot` shows none. Why: FLOW aborts under parallel Godot load.
- C11 (you, 2026-10-29). **Passage's First Taste clear under the 180-240 s band is accepted as is.** Passage wins by speed (the deep Mirrorfold past the approach post, `FT_FOLD_ALL`); the band guards pacing and a fast clear hides no loss. Passage's references rows are final; no rule change. Why: the spec's own §3.8 line ("halves a drag, skips two posts") lands under 180 s, so the band and Passage's speed identity cannot both hold as written; a fast clear that loses nothing breaks no mission-design rule. Cost if wrong: a distance limit on the fold's exit, a stiffer approach post, or barring the fold of a chained captive, with Passage's three rows re-recorded.

Controller rulings made during the build (`progress.md`):
- **The march walk is at least 88 s** (review of Task 4, I5). MS §3.5 says the flame is never out sooner than about 110 s after the shard that sent the march; the tuned numbers (muster 10 s, walk, kneel 12 s) made the quickest clergy beat it. Each marcher's speed is `min(0.6 x pace, way / 88)` so muster 10 + walk 88 + kneel 12 = 110 at the earliest. A test asserts the fastest case. Why: the warning is the only protection against an instant loss. Cost if wrong: a slower march in a night that was already near its floor.
- **The Task 3 sacrifice is quiet** (review of Task 3, I3; see T3 below): a note for the review that Lantern death judging and the gaze no longer see it.
- **Fix wave order** (Passage): fix Passage's scripted policy first (10 seeds), not a knob, and not a revert of the muster spacing fix.

## The mission spec's rulings MS R1-R14 (as approved)

- R1. No wishes, believers or Faith on a rite. Cost: wishes later need reserved people.
- R2. A lost rite is retried the next night; Awaken is offered again. Cost: one hub check.
- R3. A won rite leaves the Notice unchanged. Cost: one constant.
- R4. A rite keeps no best and leaves `last_mission` and `before_hunt` untouched. Cost: a draw may repeat the night before the rite.
- R5. Rite timers are real seconds; the Lantern speeds only dawn. Cost: if the timers should speed up, a toll shortens the warnings.
- R6. Rites only on the board's DEV tab. Cost: a board row later.
- R7. The chain plate sits above the slot row's right end (six slots leave 20 px). Cost: layout only.
- R8. The drag goes out the Main Gate at a pace scaled to 55 s. Cost: a fast-looking haul; opening the postern would change the evacuation.
- R9. One Yank per drag. Cost: Ruin and Veil may be too easy; tune the grip seconds.
- R10. Leaving Is Prohibited never holds a chained captive. Cost: Decree would block its own drags.
- R11. The Watch answers The Bell Lies' CALL THE GUARD. Cost: without it Decree has no answer on the shrine road.
- R12. The Watchful Bell is a `climb_scale` (1.0 by default) on the bell's climb. Cost: references must stay byte-identical (they do).
- R13. Lamplighters are residents made lamplighters for the night; no new art. Cost: art later.
- R14. Freed captives run for the Temple and can be chained again; one who gets in is safe. Cost: the replacement rule covers it.

## Pre-flight rulings (2026-10-29, `preflight.md`; adopted by C8)

The scan read the plan, C1-C7, the briefs, the mission spec and the parent's §8, §9.3, §11 and §13 against the code at `568da1d5`. It found 5 blocking items, 13 risks and 8 gaps.

- B1. A rite left by closing the game must be charged. `GodSlot.read()` keeps `in_night = "first_taste"` (`TierBook.has(open) or RiteBook.has(open)`), tested by `_read_rite_in_night` (a rite id kept, an unknown id still dropped). Why: otherwise the rite is not in `TierBook`, the clock-start write reads back as empty, the forfeit never runs, and a quit mid-rite is a free retry. Cost if wrong: a hidden escape from MS §1.
- B2. The four stub suites each make one check (`t.check(true, "stub: Task N fills this suite")`). Why: a suite that ran no checks fails the run. Cost: red suites until filled.
- B3. Task 4 also edits `tests/test_mission_hints.gd`: the four `first_taste*` rows appended at the END of `SPEC`. Why: `LINES.size() == SPEC.size()` and every line is compared word for word. Cost: a red test.
- B4. Task 6 appends `MissionBook.FIRST_TASTE` last to `test_tier_board._dev_town`'s expectation. Why: it asserts the DEV tab's missions exactly. Cost: a red test.
- B5. "Held by a Leaving Is Prohibited law" is `p.badge_glyph == DecreeParts.BARS and p.badge_left > 0.0`; no power-file hook. Why: `NoLeaveFx` keeps its bound set private. Cost if wrong: a bound watchman can still grip.
- R1. Prepare's rite rows are cut in this order if they overflow: RITE shows the name only; then CHAIN moves into the hint line. The first cut was needed (T6). Cost: layout.
- R2. The chain plate is hidden in the intro and steps up `PLATE_H + 4` while the focused power's modes plate lies under it (`_chain_rect_modes`, Decree's The Bell Lies in the last of six slots); Task 8 owes a `first_taste-modes` photograph (done). Cost: overlapping plates.
- R3. Merge placement for `god/t1routes`: Task 4 never edits `behaviour_check.gd` line 623 or the `--god` parse block; `_first_taste()` switches hit-stop off as its first line; the match arm goes after `"heart"`. Cost: a certain conflict.
- R4. Other shared files stay clear of t1routes' hunks (`mission_director.gd` appends, `run_all.gd` line position, `mission_book.gd` constants and file end, `crowd.gd` vars, the references block at the end). Never call `test_lost_lamb._world()` (its signature changes). Cost: conflicts.
- R5. A held breaker is never re-posted (`_post_of` returns only when not `held`); the Watch is re-posted each tick otherwise, and is in `_hold_all`. Why: a director that re-posts a whispered or compelled watchman each tick undoes Whisper, Discord and CALL THE GUARD. The second half (the town's rally pulling the Watch off its posts) is settled by the fix-wave ruling below.
- R6. The drag's pace is set once at the bite; a Mirrorfold recomputes the path only. Why: recomputing the pace makes any remaining path over 33 units take 55 s again, so a fold gains nothing. Cost if wrong: Passage has no speed.
- R7. The scripted policy returns `chain <name>` when it chains and `drag on, shrine in m:ss` at most every 20 s of a drag. Why: the idle measure would otherwise count a drag as idle (a drag is MS §3.7's "0 s (acting)"). Cost: a false FAIL and the wrong knob tuned.
- R8. Clergy are picked with `CitizenProfile.is_clergy(...)`, never `role == CLERGY`. Why: `test_v012_merge` scans for it.
- R9. The director pushes no opening banner; `_tier1()` already emits `THE FIRST TASTE` at the intro's end. The test checks `def.intro_banner`.
- R10. `NoLeaveFx` skips `inside or chained`; the proof is the default short-circuit plus `_noleave_skips_chained` asserting an unchained person is still set back. After the t1routes merge its `god_t1_*` Decree rows are the real-play proof (landing note).
- R11. Task 4's gate is expected to print FAIL on the median (default loadout, no bar there); it judges only `none_lost=3/3` and that play prints results. (It passed: median 184.)
- R12. Tests that cannot fail are not counted as proof: `_herald_untouched` runs the real Warning world at scale 1.0 and 1.2; `_chain_rect_3/6` first assert the stack and strip have area; `_ring_redraw` and `_strip_merges` are non-vacuous.
- R13. The drag is re-asserted every frame (position along the path, duty, fearless); `_town_never_grips` covers a panicking crowd, a whisper and Discord on the captive. Why: a captive stopped by the crowd's steering is luck.
- G1. A won rite's goal row is ticked from `result.won`. Why: a rite has no Descent, so `descend.main` is false and the row would show a cross on a win.
- G2. The rite's end reasons have titles: `shards` is `THE RITE IS DONE`, `cleansed` is `THE SHRINE IS CLEANSED` (*my call*). Why: they would read THE CITY HAS FALLEN and MANIFESTATION ENDED.
- G3. `RiteDirector.busy(p)` is true for a marked man, the captive and the breakers (the first-taste subclass adds the musterers). Why: on a toll the Lantern's Bearer and escorts would take the director's people (a hidden change).
- G4. `behaviour_check` has a `first_taste` branch that picks the loadout from `GodTree.starting(<type>)` under `--god` (both Tier 1 keys at level 1), else the def's default.
- G5. Key C, the aim click and Esc are driven through a real `Mission._unhandled_input` in `test_rite_hud`, and FLOW sends a real C and a real click. Cost: input that only the model has seen.
- G6. Copy is `Tier %d: %s` in both IF WON and the results line, the spec's `Tier 2: Omen`.
- G7. `RiteDirector.MARK_SHRINE := Color("ff9a3a")`, the orange of `AssassinateDirector.MARK_PLACE`.
- G8. The cost of the per-type gates is accepted (18 headless runs a round; none runs are cheap). If a gate nears 10 minutes raise `--jobs` rather than split it.

## Plan rulings P3-1 to P3-24 (`docs/superpowers/plans/2026-10-28-kak-god-progression-p3.md`)

- P3-1 (Task 1). `RiteBook` lives in `src/game/god/`. Rites are god progression data (the level that opens them, the gift they steal); the mission def stays in `MissionBook`. Cost if wrong: a file move.
- P3-2 (Tasks 1, 6). Awaken's three states: hidden below the cap and at level 50; `rite` with a row at the god's level; `unwritten` otherwise (20, 30, 40 in P3), dim with `Rite not yet written`. The `--dev` A hook stays for unwritten levels and below the cap, with P2's Hunt refusal. Cost if wrong: one condition.
- P3-3 (Task 1). The rite's frame is `MissionBook.first_taste()` (a Tier 1 frame) with `tier = slot.tier` and `clock = TierBook.clock(slot.tier) + extra_clock()`. P3's only rite is at Tier 1, so this is the frame exactly; P4's rites build their own. Cost if wrong: one line.
- P3-4 (Task 1). A rite is known by its id, checked before the Hunt: `bank()` and `forfeit()` test `is_rite` first. A rite can never be played while the Hunt is due (Game routes Awaken to the Hunt), so the order matters only for damaged files. No save field. Cost if wrong: a stored flag.
- P3-5 (Task 1). A rite's draft is remembered: `carried` counts it and `loadout = drafted`. The chain is never in the loadout. Cost if wrong: one line.
- P3-6 (Task 1). The rite is a dev mission for the board: `rite_missions()` is searched by `get_mission()` and `is_dev()` is true for it (every power open, no Descent, only its own best). `dev_missions()` is unchanged so FLOW's DEV-tab check stays. Cost if wrong: a board line.
- P3-7 (Task 6). The rite is last on the DEV tab, after the towns, so FLOW's `slice(0, capital_ids.size())` stays true. Title `The First Taste (rite)`, kind `RITE`. Cost if wrong: one FLOW check.
- P3-8 (Task 6). GIFTS replaces CITY on an ordinary night's Prepare (six rows stay six). Not on a Hunt (P2's T3: 1 px of room) nor on the rite (it comes before any gift); the hub always shows them. Cost if wrong: layout, one row.
- P3-9 (Task 6). The rite's results: `Divine Power: none - the rite feeds no bar` replaces the Divine Power line; no believers line; won: the tier, the points, the gift; lost: the shards and the capped line; then P2's Notice and Hunt lines and `Night N`. Copy is my call except the spec's strings. Cost if wrong: copy.
- P3-10 (Tasks 3, 4). The flame's loss is its own objective. Order: shards (main, a `StagesObjective`), `RiteFlameObjective` (fails `cleansed`), Dawn. `RiteDirector.lost_reason()` stays `""`. Rules check objectives in order, so a last shard and a full cleanse in one frame is a win (MS §6). Cost if wrong: a reason string.
- P3-11 (Task 3). Breakers are the subclass's list. Only `_breakers()` grip; the town's soldiers never do (MS §0, no luck). A breaker grips only when not `held()`; `held()` is `held_by_god()` (Whisper, Discord, The Bell Lies' call), Death Mark's `frail`, a Leaving Is Prohibited law (B5), fright, a Yank's stun, inside, dead. Cost if wrong: one set.
- P3-12 (Task 3). Leaving Is Prohibited skips a chained person: a `Person.chained` flag (false by default) that `NoLeaveFx` checks as it checks "inside". The only change to a power's file. Why: R10. Cost if wrong: Decree blocks its own drags.
- P3-13 (Task 3). The captive is the chain's, not the god's other powers': as `EscortDirector`'s bound charge, fear and Whisper are shaken off while chained, Discord does not divert him, a fold carries him through (path recomputed, pace kept: pre-flight R6), anything that kills him wastes him. Cost if wrong: a type could steer its own captive.
- P3-14 (Task 3). No new art for victims: a gold `LAMPLIGHTER` tag with a gold pip for his lantern; the flame is the tag's `rise` growing one step per shard. Cost if wrong: art later.
- P3-15 (Task 4). Who marches: the `CLERGY` citizens nearest the Temple door, then `FAITHFUL` residents if short; fewer than 2 able gives no march and `HALCYON'S CLERGY ARE GONE` (shown). A marcher frightened once leaves the march for good. Cost if wrong: one fallback.
- P3-16 (Task 4). The replacement lamplighter is the eligible `RESIDENT` or `LABORER` nearest the Temple door, on the round whose lamplighter is gone, the lowest such round first. (Task 4 ruled that he walks from where he stands, near the door, not from the door: see T4.) Cost if wrong: who walks.
- P3-17 (Task 5). The chain plate's input: C enters an aim (like a focused slot: a slot key, Esc or right-click leaves it); a refused click keeps the aim; a click on the plate is C. The icon is an existing one (no PixelLab). Cost if wrong: input feel.
- P3-18 (Task 5). A won rite rises from the shrine at twice the ascend effect's scale and shows the plate for 4 s in slow motion; the bank happened at the decision (P2 F4). Cost if wrong: a timing constant.
- P3-19 (Task 7). Tuning directions: a type that misses on wins gets the easier steps in MS §3.9's order (grip 3 to 4 s, Watch 4 to 3 posts, march 2's count 3 to 2, muster 10 to 15 s); a clear under 180 s gets the Yank off first. Each step moves every type, so all six rerun. No step was needed.
- P3-20 (Tasks 4, 7). The scenario and its references: `--scenario=first_taste`, loadout `GodTree.starting(type)` under `--god`, hit-stop off. Rows `first_taste_none_<seed>` and `first_taste_<type>_play_<seed>`, recorded once in Task 7 (and re-recorded within P3 as the rounds below say; they are new rows, so C3 is unaffected).
- P3-21 (Task 8). Awaken while the Hunt is due opens the Hunt, exactly Descend's path (P2-4); the rite waits. `Game.awaken_target()` is the testable decision.
- P3-22 (Task 8). FLOW wins through `offer()` (the director's own sacrifice path: banners, marches, the real objective and ending) three times, and loses through `force_end(false, "dawn")`. A drag needs scripted play and wall time. Cost if wrong: a scripted drag later. (Milestone review accepted it: the grip and Yank are unit-tested and played by the references.)
- P3-23 (Task 1). Task 1 adds every new `SUITES` line with stub files so no later task edits `run_all.gd`. Cost: none.
- P3-24 (Task 9). Landing: trial merge against local `feat/god-progression` (t1routes may be there, C6), the merged tree gated (suite, every reference, FLOW alone), bench vs `kak-god-p2`. Cost: none.

## Rulings the tasks reported

Task 2 applied R4 and R12; Task 9 and Task 10 reported none.

### Task 1: the rite's rules and data (`6fcbcdb0`; review CHANGES, fixed in `0efcadbb`)
- Ruling: `MissionNeeds` gets a `first_taste` row (`["temple"]`) in Task 1, and `test_mission_needs` now includes `rite_missions()` and expects 29 missions (was 28). Why: a mission with no row pushes an error in hosting checks. Cost if wrong: Task 4 extends it (it did not need to).
- Ruling: a lost rite's `bank()` keeps `before_hunt` and `last_mission`; `hunt_next` is `slot.hunt_due()`. Why: a rite is never the Hunt. Cost: one guard.
- Ruling: `bank()` reads `won` from `outcome.won` and the shards from `outcome.rite.shards` (0 when absent).
- Review I1 (fixed): the rite def's slot and Might checks could not fail; they can now. Review M3: the 28-to-29 count was on the landing checklist.

### Task 2: the Watchful Bell (`7e539a65`; controller-approved from the 4-line source diff)
- Ruling: `Mission` reads `_def.gifts`; each act of a god's night carries the same gifts (Task 1 `_carry_gifts`), so the def and the act agree.
- `Crowd.climb_scale` stacks with `replace_keeper()`'s x1.5 (9.6 becomes 14.4); `_herald_untouched` runs the real world at 1.0 and 1.2 (R12). `_mission_reads_def` reads `mission.gd`'s source for the line and its order before `spawn()` (no scene tree in a suite); the live proof is FLOW's rite walk.

### Task 3: RiteDirector and the Chain (`866b0a07`; review CHANGES, fixed in `0073854a`, haiku re-review APPROVED)
- Ruling: `chain_key()` performs the Yank itself and returns `yank` (Task 5 only plays the click); in a drag with no Yank left it returns `YANK_USED` (`ONE_CHAIN` when `YANKS` is 0). Cost if wrong: where the Yank lives.
- Ruling: added copy (*my call*): `CANT_REACH = "THE CHAIN CANNOT REACH HIM"` (victim indoors or no walk path) and `LOST_BANNER = "THE CAPTIVE IS LOST"` (the captive died away from the shrine).
- Ruling: breakers act only while `mind == DUTY` or in `EscortDirector.POST_MINDS` and not `held()`; held also covers FIGHT, down and frozen. Subclasses with their own errands (marchers) override `_go_grip` and `_go_back`. Why: R5.
- Ruling: `_replace()` is tried at most 3 times per look and stops if it adds nobody. Why: no infinite loop on an empty town.
- Ruling: Task 4's rounds must skip `claimed(p)` (the captive and freed runners). Why: the lamplighters' own round logic must not re-send them.
- Ruling (review I3): the sacrifice is quiet. `offer()` kills with `Person.die(&"rite", shrine)`, `EnemyField.kill` minus the `enemy_killed` emit, so the crowd counts no kill, raises no incident and hears no alarm. Why: MS §2 says the chain is quiet and the old code raised an alarm of 0.25 and counted a kill. Cost if wrong: nothing listening to `enemy_killed` (the gaze, Lantern death judging) sees the sacrifice; the milestone review confirmed that is what MS §2 asks, and that the stability figure is only stale until the next kill (its optional minor 8, not done).
- Review I1 (fixed): the director iterated typed arrays of people who can be freed mid-loop (a typed `filter` on a freed member returned an empty array and wiped `marked`, letting the replacement rule fill four new victims); every loop now runs as `for w: Variant in` with `_alive()` and a cast. I2 (fixed): a `_freed_people` test. Minors left: see the summary.

### Task 4: FirstTasteDirector (`586581d1`; review CHANGES, fixed in `45fc286e`, haiku re-review APPROVED)
- Ruling: `KNEEL_RING` is 1.1 (plan 0.8): three kneelers stand 1.9 apart, over the 1.6 of two Silent Doom radii; 0.8 gave 1.4. Why: the spread rule. (Superseded for the real shrine by the review's `_plan_spots`, below.)
- Ruling: the replacement lamplighter is the eligible resident or labourer nearest the Temple door and walks from where he stands (not teleported to the door). Why: a visible jump would be a hidden change. P3-16 now reads "from near it".
- Ruling: lamplighters are set down at their round's first lamp at setup (the nearest resident or labourer to it), like the stand-in in Task 3's tests.
- Ruling: R9: no `OPENING` const and no banner pushed.
- Ruling: a mustering march is not yet a breaker; its people are `busy()` and held through an evacuation; it becomes breakers when it walks. Why: they have not left the door.
- Ruling: one global cleanse ring (kneelers counted across marches), banner `THE CLERGY CLEANSE THE SHRINE` on each (re)start of the ring. Cost if wrong: two marches kneeling together count as one ring.
- Ruling: `hint_phase()` order is cleanse, march (a file walking), drag, then `chain` (which has no row, so the mission's own line shows). The review later put "drag" first while a breaker grips the captive.
- Ruling: the marchers' kneel spots do not use the compel kneel pose (`COMPELLED` counts as held and would stop their own ring); they stand on duty at the spot.
- Review I3 ruling: each march's kneel spots are planned after the walk-grid snap (24 angles, more than 1.7 from every spot already planned, off the stone, within 3.6, with a way from the door); a later march on a ring 0.9 further out. Why: the old formula left spots 0.93 apart at the real shrine.
- Review I4 ruling: `m.eta` is the walk only; `march_eta()` is the muster left plus the walk, so the strip row counts down smoothly through the set-out. Each marcher's speed is fixed at set-out.
- Review I5 ruling: the 88 s walk floor (controller ruling above). Measured flame-out after the shard: 120.2 s quickest, 124.5 s usual, 140.3 s slowest.
- Review I1 and I2 (fixed): the same freed-person defects as Task 3, and a `_freed_people` test (the Watch, rounds, the replacement rule with two freed lamplighters, a marcher of three freed) and `_final_frame`.

### Task 5: Mission and HUD (`356dba78`; review CHANGES, fixed in `93074a2c`, haiku re-review APPROVED)
- Ruling: the plate's icon is Leaving Is Prohibited's (`noleave`), chosen over Death Mark's: a chain binds, it does not curse.
- Ruling: a second C (or a click on the plate) during the aim lets it go (`ui_back`), as a slot key's second press does.
- Ruling: `Mission.chains()` excludes Shift as well as Ctrl, Alt and Meta ("no modifiers").
- Ruling: a won rite pushes no ending banner (`title_for(true, "shards")` would have read THE CITY HAS FALLEN); the shard banner `THE FIRST TASTE  3/3` and the plate speak. While the win plate shows, the ASCEND and chain plates and the slots are not drawn (the clock, banners and Cael's lines still are).
- Ruling (review I2, it overrides the plan's "y 120-200"): **the win plate sits at y 164-244** (`RITE_PLATE_TOP` 164), below the banner bar (116-136) and Cael's plate (140-157). The plan text was corrected to match. Why: at 120 it drew over the banner bar. Cost if wrong: layout only.
- Review I1 (fixed): `Hud.tag_layout()` has an `avoid` rect (the chain plate); an edge tag whose diamond lies under it becomes an arrow `ARROW_PAD` above it, and an arrow whose tip would sit within the pad moves up. I3 (fixed): a repeated refusal queues one banner.

### Task 6: the screens (`b05efa07`; no per-task review)
- Ruling: while the Hunt is due, Awaken (button or A) emits `awaken` for a capped god whether the rite is written or not, and the button is then not dim (MS §1 "Hunt first"). Under `--dev` an unwritten level in that state does the same instead of the old refusal, which still applies to a god that is not capped.
- Ruling: a click on the dim Awaken button buzzes and shows `RITE_UNWRITTEN`; under `--dev` only the A key is the `awaken_dev` hook.
- Ruling: Prepare's RITE row shows the name only (pre-flight R1's first cut: six rows with the plate ran 2 px past the hint); the plate stays on the briefing through WIN. Cost if wrong: the plate is not seen on Prepare.
- Ruling: the results line for a won rite is `Tier 2: Omen` (G6) with no `AWAKENED` prefix; the `Tier N:` and `Stolen:` lines are gold, `The god is still capped...` red.
- Ruling: `rite_called` names the tier played (a won rite's `tier` is the one crossed into, minus 1).
- Ruling: the lost-rite pause confirm at Notice 100 reads `CONFIRM_RITE_FULL` (no rise promised, the Hunt named), as P2's lost-night confirm does (P2 F3).
- Ruling: a rite's board card has no brief, like a town card: seven cards on the DEV tab leave 58 px of room.

### Task 7: the per-type scripted check and the 21 references (`ffcfdbd5`; review CHANGES, fixed in `ca61c534`)
- Ruling: `RiteDirector._step_drag` re-sends a captive without a goal to the shrine every tick, and `_check_stuck()` frees a captive who stands still 8 s (`STUCK_SECONDS`, `STUCK_STEP` 0.3) with no one gripping him: the chain breaks like a gripped one (banner `THE CHAIN BREAKS`, he runs for the Temple if he can). Why: MS §3.6 "never a dead end"; both were found by scripted Passage (a Thornwall across the lane; a Mirrorfold exit in a closed pocket) and left the captive standing in his drag with the chain locked until dawn. Cost if wrong: a captive stopped 8 s by something legitimate is freed; nothing in P3 stops one.
- Ruling: Passage's fold skips the approach post too (`FT_FOLD_ALL`). Settled by C11.
- Ruling: `first_taste_none_*` rows carry no `--god`: nothing is cast, so the loadout is not in the checksum (all six gates printed the same three).
- Ruling: the per-type policy lives in `behaviour_check.gd` as `_first_taste_*` functions (`_first_taste_hit` for a breaker near the drag, `_first_taste_stop` for a march, `_first_taste_prep` between them) with the `FT_*` consts documented in place.
- Ruling: the state line's doc is extended with `captive=` (and, later, `flame_in=`).
- Review I1: resolved by C11 (above). I2 (Passage's analysis restated): **no plan with one Mirrorfold, one Thornwall and one Yank per drag gets a captive past the approach post unless the fold lands beyond it** (the post is 5 units from the stone, a grip takes 3 s, a captive needs about 6.5 free units and those tools give about 3.8). The nine variants tried are in `task-7-report.md`. The breaker-side fold was not run (by count it is slower).
- Ruling (review I3, Decree): the policy, not a knob, wins Decree on every seed. The circle goes to the gate pair; CALL THE GUARD to the posts beyond it (one 20 s call covers the shrine road and the approach, 11 units apart), each giving way to the other when not ready. 8 of 10 seeds became 10 of 10 at the structural floor (183.9-184.3 s), flame margin 19-34 s (was 12). No Yank, grip, Watch, march or muster number moved. Why: user rule "if the gate misses, first make the scripted policy work the opposition as a player would". Cost if wrong: a deviation from the spec's guard allocation; it now follows MS §3.8.
- Ruling (review I4): a stranded captive is not counted. `_check_stuck()` adds the freed man to `_stranded`; `left()` skips stranded victims, so the replacement rule fires; `chain()` takes a man off `_stranded` (a lane that opens lets him be chained). The one residual case, a man held in a jammed gate's queue, is in the `STUCK_SECONDS` doc. (The real rite did not get it until the fix wave, below.)

### Task 8: Game wiring, photographs and FLOW (`391bc75f`; covered by the milestone review)
- Ruling: `awaken_target()` also returns `""` for a god with nothing to draft (as Descend), and the Hunt's id when the Notice is full even where no rite is written yet (the hub emits `awaken` then, T6).
- Ruling: result plumbing needs no Game code: the mission's result already carries `goal`, `reason` and the director's `rite` (Rules merges `director.report()`), `bank_god_night()` adds `god.rite`, and FLOW proves it.
- Ruling: `first_taste-win` waits 0.6 s (scaled by the ending's 0.3) so the capture lands inside the 4 s plate.
- Findings carried to the summary: the marchers' edge arrows clump at the top edge; the cleanse ring is off screen from the camera spot; FLOW's wins go through `offer()`.

## The milestone review and the fix wave

The opus review of `568da1d5..ca61c534` (`review-milestone.md`) found 0 critical, 1 important and 8 minor, and called a small fix wave. It checked save and load, that nothing leaks into other missions, the freed-person lifecycle, the UI wiring, every spec number and string, the design lessons, and the t1routes merge (no semantic clash).

- **Important 1 (fixed, `c98d14fe`).** `FirstTasteDirector._gone(i)` is also true for a stranded man, so `_replace()` sends a new lamplighter onto his round. Before, Task 7's I4 fix never fired in the real rite: the replacement rule only filled the round of a dead or safe man, and the I4 test passed only because its stub always added someone. The new test `_stranded_replaced` runs on the REAL director (RED without the one-line fix: 3 failures). Why: MS §3.6 "never a dead end" was unproven for the night that ships. Cost if wrong: a night with fewer victims than shards needed.
- **Minors 1 and 2 (fixed).** `_set_out` reads `m.people[k]` as a Variant and skips the dead; the `_marchers_grip` check is `A and B and C`.
- **Minor 3 (fixed).** The three musterers stood on a 1.0 ring, 1.73 apart before the snap (the Temple door opens on a street 1-2 units wide). `_plan_muster()` now picks each musterer's spot after the snap, over 1.7 from the others, trying rings of 1.0, 2.0 and 3.0. Cost: 17 `_play_` references moved because the musterers stand elsewhere; all 17 were re-recorded in the same commit with the reason in the block's comment.
- **Minor 5 (fixed).** Prepare's IF LOST shows the real clamped rise and names the coming Hunt, from the pause confirm's clamp (`PauseMenu.rite_rise()` extracted from `rite_line()`); at Notice 0 it is still the spec's exact `Lantern Notice +25%; the god stays capped`. Tested at Notice 80, 90 and 100.
- **Minor 6 (fixed).** Awaken is dim and buzzes when the god has nothing to draft (`awaken_dim()`).
- **Minor 4: ruling. A watchman the town's rally (or any mind outside DUTY and POST) takes off his post on a toll is not sent back.** The Watch is the town's and answers its alarm as `EscortDirector`'s posts do; he is a breaker again when his mind returns to a post mind. No code. Why: this makes the rite easier and is caused by the player (a loud night), so it is not a hidden loss. Cost if wrong: on a loud night (Ruin's toll) the Watch can thin out; re-posting on the rally too would be one line.
- **Minor 7 (deferred).** The marchers' edge arrows clump at the top edge: cosmetic, left for the art and animation round.
- **Minor 8 (not done).** The quiet sacrifice leaves `_stability_dirty` unset. Optional; nothing on a rite reads stability.
- **Fix-wave minors skipped as told:** 7 (a distinct banner for the stuck case is a copy decision; P3 keeps `THE CHAIN BREAKS`) and 8, and the stray `%` at `test_endless_screens.gd:568` (the t1routes merge brings its fix).
- **Known items not taken:** `hud.gd:750`'s call is untested (it only calls `_lay_out_tags()`, which `test_rite_hud` exercises); a replaced stranded man keeps his victim tag (cosmetic); `Person.fold()` has no path test (a Mirrorfold check, P4 or later); FLOW wins through `offer()` (P3-22).
- **Re-review (sonnet): APPROVED.** It asked for the Minor 4 ruling to be copied here (done above) and for FLOW alone on the merged tree.

### The Passage policy round (`183c8781`)
The wave moved who leads the marches, and Passage seed 3, which had been a 177.0 s win, became a loss (the clergy cleansed the shrine at 256.7 s). The march was never late; the captive was lost to the Thornwall the policy itself laid across the Main Gate (cast one second after the second fold was laid, before the captive had stepped on the mirror, and later a look before the third chain). A sealed gate sent the next walker round by the side gate into the marchers. This is the same luck class as Decree's earlier seed 3.

- Ruling: fix Passage's scripted policy, not a knob, not C11's Passage speed, not a revert of the muster spacing. Three changes, all in `behaviour_check.gd`: (1) the gate seal waits until no captive is about to use the gate (none chained, or a folded one set down more than `FT_SEAL_FAR` = 14 units from it, and never while the chain is READY); (2) the seal is laid when the march leader is within 4.5 units of the gate (was 8), so a 25 s wall stands when the file arrives; (3) Passage chooses, of the lamplighters clear of the Watch, the one with the most room before the first free breaker on his way (`by_room`), so he sets out earliest and the wait for the mirror is shortest. Why: the user rule to work the opposition as a player would. Cost if wrong: another policy round.
- Result: Passage on 10 seeds wins 10 of 10, 111.3-115.6 s, flame margin 87-123 s, idle at most 43 s. Only `first_taste_passage_play_1..3` were re-recorded; the other 18 `first_taste_` rows still match the wave's recordings (24 OK with `digest`, `crowd_check` and `calm`).
- Passage still clears about 112 s, under the 180 s band; accepted under C11. The gate script prints FAIL on its median by design.
