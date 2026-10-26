# KAK God Progression P1: every ruling

God progression P1 ("Framework") was built straight through, subagent-driven, on `feat/god-progression` on 2026-10-26 to 2026-10-27: 15 tasks, a milestone review and one fix wave. A ruling is a choice the spec or plan left open, or a place where the code said something else. Each entry has what was decided, why, and the cost if it is wrong (where the source gave one). The spec is `docs/superpowers/specs/2026-10-26-kak-god-progression-design.md` (cited as section numbers). The plan is `docs/superpowers/plans/2026-10-26-kak-god-progression-p1.md`. The summary is `docs/KAK_God_P1_Summary.md`.

Groups, in order: C1-C14 (controller rulings), pre-flight B1-B4, R1-R7, G1, plan rulings P1-P24, then the rulings each task reported (T1-T13), then the milestone review and fix wave. Where two disagree, the controller rulings (C) beat the plan text; the pre-flight rulings were adopted as written (C10). Task 14 (landing) and Task 15 (this note) reported no rulings of their own.

## Controller rulings C1-C14 (`.superpowers/sdd/godp1/rulings.md`)

- C1. Might rename. User-facing text (every screen, HUD, Prepare, Faith screen) says Might. New code and the new god save use `might`. Existing internal identifiers (`PowerBook` "dp" field, `TierBook.DP`, `Rules` and `Draft` budget names, campaign DP) stay, so merges with `feat/Develop-Main` stay cheap. Cost if wrong: a later mechanical rename.
- C2. The title is unchanged in P1 (Campaign stays; spec §3 "before the tree's Tier 1 is filled"). Endless Night is reached from the board's DEV tab only.
- C3. The board as test mode must not move any reference row in `tools/dev/refs/*.tsv`, nor `digest`. Mission simulation is unchanged; only the board's UI, unlocking and banking change. FLOW is updated for the new board and the Endless Night DEV entry.
- C4. No PixelLab. Text, drawn shapes and existing icons only.
- C5. Landing is on `feat/god-progression`, not `feat/Develop-Main`. Land.sh's checks (suite, all references, FLOW alone, bench vs `kak-v012-m2`) are the gate; `feat/Develop-Main` is not fast-forwarded or pushed. The tag `kak-god-p1` goes on the branch.
- C6. The per-type win check (spec §5.2) needs a filled tree. P1 builds only the plumbing a scripted policy needs to be restricted to one type's learned abilities, if cheap. The check itself runs with the Tier 1 fill.
- C7. The old save's `[descend]` and `[campaign]` sections are ignored by Endless Night, never erased.
- C8. Endless Night reuses the board's Descent (wishes, ASCEND, banking) with the god slot as the bank: banked believers become Faith 1:1; Divine Power per spec §8.
- C9. P1 includes the spec §9.1 "no escape by quitting" rule and the Notice field in the save (written, shown as 0%). The Notice's changes, the Hunt and seals are P2.
- C10. Every `Ruling:` in `preflight.md` (B1-B4, R1-R7, G1) is adopted as written.
- C11. Pre-flight B4, option (a): each task in groups A, B and C gets its own worktree from the group's base commit (branch `god/p1-t<N>`, folder `vfxProve-god-t<N>`). Serial tasks (1, 11, 12, 14, 15) run in the main worktree. The controller merges in task order, then runs suite 8 and FLOW alone on the merged tree.
- C12. In a parallel group, references run with `--jobs=2`; a MISMATCH is rerun alone before it counts (pre-flight R6).
- C13. (Task 1 review) Task 2 also changes the comments that call the draft budget "Divine Power" (`draft.gd` `capacity`, `power_book.gd` ~183, `Draft.for_mission`) to "Might"; identifiers unchanged.
- C14. (Task 1 report) Task 6: unpicking a power (`Draft.toggle()` off) clears its level, so a re-pick starts at level 1.

## Pre-flight rulings (2026-10-26, `preflight.md`; adopted by C10)

The scan read the spec, plan, rulings and briefs against the code at `9403f7df`. It found 4 blocking items, 7 risks and 1 gap.

- B1. Task 2 also updates `tests/test_draft.gd:170-171` to "Not enough Might" (the message too). Why: Task 2 changes `PrepareScreen.REFUSALS["dp"]`, which that test asserted as "Not enough Divine Power"; without it the suite cannot reach `failures=0`. Nothing else in that file changes.
- B2. Task 11 updates `tests/test_flow.gd:68-69` to 14 screens ("all fourteen screens are reachable, Endless Night's five too"). Why: Task 11 appends five `Game.Screen` entries to the nine. (Task 11 then ruled 14 screens, 13 reachable; see T11 below.)
- B3. Task 12's step 12 ends with `dev = was` and `go_to(Screen.BOARD)`, plus one check that the board is up without the DEV tab. The title-rows check (C2) and the C7 check stay inside step 12, before the return. Why: FLOW's next line casts the board; a walk that ends on the Title makes the cast give null and FLOW abort.
- B4. Parallel groups get one worktree per task (option (a); became C11). Why: shared `run_all.gd` SUITES lines cannot be split with `git add -p`, a sibling's RED test or half-built file fails the others' suites, and two `--import` runs in one `.godot/` can race. Option (b) (anchored SUITES lines, a focused-suite gate) was the fallback.
- R1. In Endless Night, the three Game handlers that wrote `kak_save.cfg` (`_on_prepare_action` MANIFEST and between-acts, `_on_act_over`) skip `remember_loadout`, `save.difficulty` and `save.save_to`. `god.loadout` is the only memory of the draft. FLOW compares the bytes of `FLOW_TEST_SAVE` at step 1 and step 12. Why: C7; Task 11's brief named only `_on_mission_finished`, and the leak would have passed FLOW.
- R2. Task 12's step 4 preselects `["smite", "ember"]` before MANIFEST; step 5 checks `rules().loadout` is non-empty and inside `god.draftable()`; an Endless Night MANIFEST with no picks is refused with `REFUSE_EMPTY`. Why: an empty draft falls back to the mission's default loadout, which is outside the god's pool.
- R3. `behaviour_check` prints `BEHAVIOUR refused scenario=<scenario> god=<type>:<tier> outside=<k1,k2>` and quits 1. Why: `gate.sh` reads only lines starting `BEHAVIOUR refused scenario=`; `gate.sh` does not change.
- R4. The controller times FLOW once after group B. If it takes over 7 minutes, Tasks 11 and 12 do not run FLOW themselves; if FLOW plus the Endless Night walk passes 840 s, the step-10 descent is dropped. Outcome: FLOW alone took 200 s after group B, so the implementers ran FLOW themselves.
- R5. If `land.sh` stops at a trial-merge conflict, Task 14 runs its steps by hand (import, suite 8, `refs_check.sh --jobs=8`, FLOW alone, `land.sh --bench-only --bench=kak-v012-m2`) and reports the conflicting files. Outcome: the references step is about 2 h, so Task 14 ran land.sh's steps by hand in its order.
- R6. A MISMATCH seen inside a parallel group is rerun alone (`tasklist | grep -i godot` first) before it counts as a mover. Why: rendered rows use wall-clock hit-stop (memory `mission-test-not-exact`).
- R7. `PrepareScreen.hit()` tests the level badge (`level_rect(i, slots)`, only with `level_picker` on) before the slot loop. A badge is drawn only on a filled slot. Why: a click on a badge inside the slot rect would otherwise remove the pick.
- G1. Levels are carried back into Prepare: `PrepareScreen.levels := {}` is set before `setup()`, which copies it into the new `Draft` before `preselect()`; Prepare's board branch and the between-acts branch pass `Game.levels`; the between-acts MANIFEST copies `prep.draft.levels` into `levels` and `_mission.levels`; FLOW checks the badge after Change powers. Why: Prepare builds a fresh Draft, so Change powers and the between-acts re-draft would show level 1 while `Mission.levels` kept playing the old levels.

## Plan rulings P1-P24 (`docs/superpowers/plans/2026-10-26-kak-god-progression-p1.md`, "Rulings")

- P1 (Task 3). `GodTree.RING` is the spec's ring order; `PowerBook.AUTHORITIES` (the draft's tab order on the board) is left as it is. Why: the two orders do different jobs, and changing the board's tabs would move FLOW and tests for nothing. Cost if wrong: one const swap.
- P2 (Tasks 3, 11). The dev fill is `GodTreeDev.TABLE`, merged over the real table's empty spots, never over a real key and never repeating a key the real table uses. It is on when Endless Night is entered from the DEV tab (and in tests that turn it on; both runners reset it). Why: spec §15 asks for a fill kept out of the real table, and the merge lets the user's Tier 1 fill take over spot by spot without touching the dev table. Cost if wrong: a slot made on the fill keeps keys the user's fill does not use (see P4).
- P3 (Task 1). `extra["level"]` is put on a copy of every cast's `extra` (default 1), not only for powers with a table. Why: the effect needs no special case, and no P1 effect reads it, so no reference moves (proved in Tasks 1 and 14). Cost if wrong: none expected; a mover would show at once.
- P4 (Task 4). Starting abilities are ensured whenever a slot is read (a fill landed after the slot was made gives them, free, at level 1); a learned key that sits in no spot is kept in the file but neither drafted nor shown. Why: spec §4 gives them "for free"; a fill must not strand a god. Cost if wrong: an old god keeps an invisible key; a later cleanup can drop them.
- P5 (Task 4). Points earned are derived, `(level - 1) + 2 x (tier - 1)` (57 at level 50 after four rites), and respec sets `points` to that with only the starting two at level 1. Respec is refused when no point is spent. Why: spec §5.3's totals; one formula cannot drift from the stored points. Cost if wrong: a later source of points (none planned) needs a stored total.
- P6 (Task 4). At the cap, Divine Power fills the bar to `need()` and stops; the excess is lost and reported (`lost`). Reaching level 10 keeps the leftover in the bar; the bar is only "full" once filled. Awaken keeps the bar and re-levels at the new need. Why: spec §8 "the bar stops at full", "earned while capped is lost". Cost if wrong: P3 sets the bar to 0 on a rite instead (one line).
- P7 (Task 5). The Faith clock bonus is added to the night's clock after `TierBook.board()` set its stretch, so the mission's events keep the tier's times and only dawn comes later; a night with acts adds it to each act. Why: "+15 s on the descent clock" is more time, not slower events. Cost if wrong: one line moves before the stretch.
- P8 (Tasks 5, 9). A god with nothing to draft gets the pool `["none"]` (no power allowed), and the hub's Descend is blocked with a line. Why: `MissionDef.powers()` treats an empty pool as every power, which would hand an empty god the whole book. Cost if wrong: none.
- P9 (Tasks 5, 10, 11). "No escape by quitting" is kept by `GodSlot.in_night`, written when the clock starts (`Mission.clock_started`). Abandon (after a confirm that says so) or finding `in_night` set when the slot is opened forfeits the night as a lost one. Endless Night's pause menu has no Restart and no Change powers, R does nothing, and the interlude's Missions forfeits (the fix wave added a confirm; see I2). Leaving from Prepare or during the intro is free. Why: spec §9.1; closing the game is the easiest escape. Cost if wrong: a crash mid-night costs a night (shown on the hub).
- P10 (Task 11). An Endless Night night writes only the god's file: no board best, no `last_mission`, no `kak_save.cfg` write. Why: C7 and spec §4 (per-mission bests live in the slot). Cost if wrong: none.
- P11 (Task 6). The board in test mode still counts `DescendState.night` (only to seed the wishes, never shown) and keeps its bests (cleared ticks, fastest, most wishes); believers are not banked and no tier opens. Results read "Test mode: nothing banked"; their buttons are Board, Again, Change powers. Why: spec §3 "nothing is saved but bests"; without the counter every board night of a mission would hear the same wishes forever. Cost if wrong: the counter is removed in one line.
- P12 (Task 9). The Faith screen is a new `FaithScreen` modelled on `UpgradesScreen`; `UpgradesScreen` and `DescendState`'s shop stay in the code, unreachable from the board, as the Lantern campaign does. Why: C1's merge-cheap rule; the user may remove the board later (spec §3). Cost if wrong: dead code to delete in one later commit.
- P13 (Task 6). The board's level picker is a badge on each loadout slot; a click steps 1 to 5 to 1, refused when the Might would go over; the levels are kept for Again and Restart but never saved. Why: the smallest UI that fits six slots in 640 px. Cost if wrong: layout only.
- P14 (Task 11). The DEV entry is an `ENDLESS` button in the board's header beside DEV (`--dev` only). Why: a card would need a fake `MissionDef`. Cost if wrong: layout only.
- P15 (Tasks 4, 7). P1 has no name entry; `name` is written empty and a slot shows its type's title. Why: the name is optional (spec §4) and text entry is new UI. Cost if wrong: a later small task.
- P16 (Task 5). Each night banked adds 1 to `carried[key]` for every drafted key, from P1 on. Why: P2's seal picks the most-carried ability (§10.3); recording now keeps P1 nights' history. Cost if wrong: an unused field.
- P17 (Task 5). The night's draw uses `hash([slot.seed, slot.night])`, the wishes `hash([slot.seed, slot.night, id])`; `seed` is made once when the slot is made. Why: spec §9.1 "the same night" after quitting from Prepare; two gods do not share draws. Cost if wrong: none.
- P18 (Task 9). The hub's DEV key A is the Awaken hook: tier + 1, +2 points, the cap lifted (P3's win without its gift or plate). Why: spec §14 P1 needs only a dev hook. Cost if wrong: none (dev only).
- P19 (Task 3). The six flavour lines are first guesses for the user to rewrite. Cost if wrong: copy only.
- P20 (Task 2). C1's "every screen" covers the Lantern campaign's screens too ("6 Might   3 slots ..."); dev tools' prints (`behaviour_check`, `town_debug`) keep DP. Why: the player reads the campaign's screens; the tools' readers are us. Cost if wrong: two strings back.
- P21 (Task 11). An abandoned night has no results screen; the hub shows the lost night once. Why: §9.2's results are for a night played to its end; the hub line keeps the loss visible. Cost if wrong: a small results variant.
- P22 (Task 5). Divine Power uses `Descent.report()`'s `kept` (wishes granted and banked), so a night caught after its main objective earns the main's only, and Faith is its `earned` (believers banked) 1:1. Why: spec §8 "caught after the main objective" and C8. Cost if wrong: none.
- P23 (Task 4). A slot file whose type is not one of the six reads as an empty slot, and is replaced only through New's confirm. Why: a damaged god must not crash or be silently rebuilt as another type. Cost if wrong: a damaged god is lost (it already is).
- P24 (Task 9). The hub also shows the unspent ability points (not in spec §9.1's list). Why: the player needs to know when the tree has something to buy. Cost if wrong: one line.

## Rulings the tasks reported

Tasks 3, 7 and 9 reported no new rulings (they applied P1, P2, P8, P12, P15, P18, P19, P23, P24 and C1, C9 as written). Task 14 listed the others for filing and made none.

### Task 1: levels plumbing
- Ruling: `levels_problems` treats int and float as one kind ("number"), so a table may mix `40` and `46.5`. Why: the brief says "one type" and a strict `typeof` check would reject harmless tables. Cost if wrong: a table mixing int and float passes validation.
- Ruling: `level_change` returns `""` at level 1 (nothing is reached) and `NO_LEVELS` for a power without a table at any level. Cost if wrong: a caller wanting level 1 text changes one line.
- Ruling: `Draft.set_level` stores level 1 by erasing the key (so `levels` stays `{}` when nothing is raised), and going down is always allowed even when picks are over capacity. Cost if wrong: none expected.

### Task 2: Might rename
- Ruling: the "quiet" mark on Prepare's card lifts one line when the card's "N Might" cost line would reach it. Why: "Might" made the cost 17 px wider and it met the mark. Cost if wrong: remove the 2-line change in `_draw_card`.

### Task 4: the god's save slot
- Ruling: `awaken()` at tier 5 does nothing (no tier, no points). Why: "tier + 1 (5 at most)" with a points gift would pay points past the 57 total that `points_earned()` gives. Cost if wrong: one line.
- Ruling: respec's "something is spent" is `learned` differing from the free starting set at level 1, or points held below `points_earned()`. Why: it works for a god built by learning and for one with the points edited down. Cost if wrong: one function (`points_spent`).
- Ruling: `bought` stays sparse (a key exists once bought or read from a file); all lookups use `.get(key, 0)`. Why: the brief's `_bad_file` expects `{"slot": 3, "might": 0}` exactly. Cost if wrong: none.

### Task 5: an Endless Night night
- Ruling: `Mission._mission_def()` checks `night_def` before the `--mission` argument and before `def_for()`'s board logic. Why: the brief says it ignores `--mission`. Cost if wrong: none.
- Ruling: `clock_started` is emitted once at the end of `_land()` (after `_rules.set_process(true)`), so a listener that reads the Rules sees a running clock. Why: "once per start or act" and P9 (written when the clock starts). Cost if wrong: one line.
- Ruling (ledger): bests are keyed by mission id and that is fine as is, because each mission id sits on one tier only (`TierBook.MISSIONS`), so a god never plays one mission at two tiers. Cost if wrong: a stale best line.

### Task 6: the board as a test mode
- Ruling: `LEVEL_BADGE` is 14 x 10, not 12 x 10. Why: "L5" measures 13 px in the 11 px pixel font (a test pins it), so a 12 px badge would clip. Cost if wrong: layout only (one const).
- Ruling: `Game.levels` resets on every board pick (`_on_board_action("pick")`) and `_build_mission()` hands the mission `{}` in the campaign. Why: a new mission starts at level 1 (P13: kept for Again and Restart, not beyond), and a stale level for a key in another mission's saved loadout must not leak in. Cost if wrong: one line.
- Ruling: the level picker is also on in the between-acts re-draft of a board night (`level_picker = not _in_campaign`), as G1 says the BEGIN MANIFEST copies the levels. Cost if wrong: one line.
- Ruling: `mission.descend = null` for every night (the campaign never read it). Why: the brief says null on the board and nothing else reads `Mission.descend`; the wishes' seed still counts `save.descend.night`. Cost if wrong: not given.
- Ruling: the results' rows keep their "+N" believer values on a test night (the brief changes only the menu and `summary_lines()`). Cost if wrong: `descend_rows()` hides the numbers when `bank.test`.
- Ruling: the panel hint gains ". Click the L on a slot to set its level" while the picker is on (not in the brief; the badges would be unexplained). Cost if wrong: one string.

### Task 8: the skill tree screen
- Ruling: the spot shows level pips as squares, not the "n / 5" text; `spot_lines()` still returns the text (tests and a11y). Why: 94 px does not hold pips, "2 / 5" and the Might. Cost if wrong: one draw function.
- Ruling: in a locked tier, an unlearned spot's change line is replaced by "Awaken to Tier N" (drawn only; `spot_lines()` stays as the brief gives). Why: the spec wants the dimmed tier to say it, and the row has no free space. Cost if wrong: one draw line.
- Ruling: `spot_lines()` at level 5 puts the twist as line 5, and `NO_LEVELS` for a power with no table (so a P1 tree never shows an empty line). An unlearned spot's change is `level_change(key, 1)` (empty for a table, `NO_LEVELS` otherwise). Cost if wrong: not given.

### Task 10: Endless Night's results, pause menu and Prepare
- Ruling: in a god's Prepare, `draft.slots` and `draft.capacity` come from the god (`god.slots()`, `god.max_might()`), overriding the def's. Why: spec §6 makes the god the authority on its slots and Might. Cost if wrong: two lines, if `def_for` already sets the same; if it set different numbers, Prepare and the night's Rules would disagree (Task 11 checked: they match, 3 slots and 6 Might).
- Ruling: a god's powers keep their learned level when picked, given back and picked again (`_keep_god_levels()` after each click toggle; `setup()` does not drop non-picked levels). Why: C14's "unpick clears the level" is for the board's picker; here the level is the god's. Cost if wrong: one line.
- Ruling: `PauseMenu` ignores `"abandon"`'s confirm unless `endless`. Why: the action only exists in the endless rows. Cost if wrong: none.

### Task 11: Endless Night in Game
- Ruling: `board:upgrades` and `results:upgrades` are dropped from FLOW, so the Upgrades screen is reachable from no FLOW entry; `test_flow.gd` asserts 14 screens, 13 reachable, with UPGRADES the named exception, instead of pre-flight B2's "all fourteen reachable". Why: B2 and the carry file disagree; the carry says to drop the dead entries, and keeping them would make a button that no longer exists "reachable". Cost if wrong: re-add two FLOW lines and revert one assert.
- Ruling: `MissionBoard.click(point)` is new and public, and the mouse handler calls it. Why: the brief's test says "a click emits endless" and the board had no `click()`. Cost: none.
- Ruling: `--show` runs set `dev = true` for Endless Night photographs and write the fixture to `SHOW_GOD` files, removed at the start and after the capture. Why: Endless Night is only ever reached with `--dev`, so the hub's "A: awaken" hint belongs in the photograph. Cost: none.

### Task 12: FLOW walks Endless Night
- Ruling: `_flow_endless` ends with `GodTree.dev_fill = false`, which Task 11 left on "for the session" (P2). Why: the walk is the only FLOW code that turns it on, and later FLOW steps should not run with a filled tree even though nothing outside Endless Night reads it. Cost if wrong: delete one assignment.
- Ruling: the fixture seed is found by a loop over `god.seed = 1..` against `GodNight.draw()` and written to the god's file, so the draw is deterministic whatever the clock-seeded god got. Cost: none.

### Task 13: scripted-player plumbing
- Ruling: an unknown `--god` type/tier or `--level` is an error (quit 1), not silently empty. Why: an unknown type would otherwise read as "everything outside" and mislead. Cost if wrong: none (dev tool).
- Ruling: for scenarios with no scenario loadout (`calm`, ``) the check and `--level` use the default four drafted by the `_ready` start, as that is what `mission.start([])` plays. Cost if wrong: not given.

## Milestone review and fix wave

The controller's opus milestone review (`final-review.md`, `38751472..c2df7f85`) found 0 critical, 2 important and 9 minor issues. It made no `Ruling:` lines of its own; it accepted P11 and P3 and agreed with the Task 5 bests ruling. The fix wave (`fix-wave-report.md`, branch `god/p1-fix`, tip `f222b2d0`) reported "Ruling: none made".

- Controller ruling (progress ledger). The fix wave takes I1, I2, M1, M4, M5, M6 and M9. It leaves M2 (the slot screen reads files on mouse move: performance only), M3 (a failed `in_night` write: disk error only), M7 (a fresh board opens on the last mission's tier: test mode, FLOW pinned) and M8 (`behaviour_check` looks at the first act only: dev tool). Cost if wrong: small follow-ups.
- I1 fix. `ResultsScreen.god_lines()` adds "N Divine Power lost at the cap" after the level lines when `lost > 0` (in the bad colour). Why: a hidden loss; spec §8 says the loss is "simple and visible".
- I2 fix. `InterludeScreen.endless`: in Endless Night the second button reads "Abandon night", Esc does nothing, and the click opens a confirm with `PauseMenu.CONFIRM_LOST`'s text (Abandon or Stay). A board night's interlude is unchanged. Why: the pause menu confirms a lost night; the interlude did not.
- M1. `Game.between_acts_levels(campaign, chosen)` returns `{}` in the campaign. M4. `PrepareScreen._refuse` is public `refuse`. M5. A picked board card shows its level's Might (`card_cost_text`). M6. Skill tree spots draw their power's icon (`ICON_PX` 14, `NAME_X` 20), cached in `setup()` (a texture first loaded inside the draw showed white).
- M9. `GodSlot.fresh_seed()` uses one static `RandomNumberGenerator`, randomized once, two draws combined. A fresh generator per call collided (62 of 64 seeds distinct in a first try), so it stays static; the global RNG is not reseeded. Why: `Time.get_ticks_usec()` could repeat for two gods made at the same moment after launch, against P17.
- Fix-wave concern, no ruling: "Manufacture" (a Dominion Tier 4 name) clips to "Manufactur" in the tree because the icon takes 16 px of the name's room and `fit()` cuts without an ellipsis. Deferred to the tree fill (see the summary's Known small issues).
