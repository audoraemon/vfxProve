# Kingdoms Amid Kataclysm (KAK) - God Progression P1 Summary

*Engine: Godot 4.7.2. Branch `feat/god-progression` (from `feat/v012`, base `38751472`). P1 is the "Framework" row of spec §14: the god-progression machinery with an empty skill tree and a dev fill, playable end to end from the board's DEV tab. Built 2026-10-26 to 2026-10-27, straight through and subagent-driven: 15 tasks, a milestone review, and one fix wave (tip `f222b2d0`). Spec: `docs/superpowers/specs/2026-10-26-kak-god-progression-design.md` (cited as section numbers). Plan: `docs/superpowers/plans/2026-10-26-kak-god-progression-p1.md`. Every ruling is in `docs/KAK_God_P1_Rulings.md`.*

## What you asked

You asked for a game where a god grows over many nights: pick a god type, descend again and again, gain Divine Power and levels, spend ability points on a skill tree and Faith on upgrades, and have each ability get five levels. The old Missions board becomes a test bench. P1 builds the framework for all of that and changes no mission rule. No reference moved.

## What P1 built, by spec section

### §3 The modes
- **The board is a test mode.** All five tier tabs are open, no padlocks, all powers open in the draft, no Upgrades button, no believers banked. Slots and Might per tier are as `TierBook` sets them. Wishes still play and pay nothing. The header reads "TEST MODE: every tier, mission and power open". Results read "Test mode: nothing banked" and offer Board, Again and Change powers. Only bests (cleared, fastest, most wishes) are saved.
- **Prepare has an ability level picker (1-5).** On a board night, each drafted power shows an `L<n>` badge on its slot; a click steps 1 to 5 and back to 1, and is refused when the Might would not fit. The levels are kept for Again and Restart and never saved.
- **Endless Night is reached from the DEV tab only.** The title is unchanged (it keeps `Campaign`); the switch lands with the Tier 1 fill. The Lantern campaign, its code, its Upgrades screen and the old save's `[descend]` and `[campaign]` sections all stay, ignored by Endless Night and never erased.

### §4 Save slots and the god
- **Three slots**, one file each: `user://kak_god_<n>.cfg`. A slot holds the type, level, Divine Power, tier, points, learned abilities and levels, Faith, bought upgrades, the Notice, the night counter, the last mission, the loadout, the night seed, the `in_night` mark, per-mission bests and the carried count. A damaged file is clamped on read; a file with a type outside the six reads as an empty slot and is replaced only through New's confirm.
- **The slot screen** shows the three gods or `Empty`. New (with a confirm when it would replace a god), Continue, Delete (confirm). The god select screen is the six types on a ring.
- **The god is made once** with its type's two Tier 1 abilities at level 1, free. A name is not asked in P1; a slot shows its type's title.

### §5 The tree, points and levels
- **`GodTree`** (`src/game/god/god_tree.gd`): six types on a ring (ruin, death, veil, passage, decree, dominion), five tiers of two spots each, 60 spots, all empty. Neighbours cost 2 points per learn or level, the own type 1, a far type is locked.
- **Ability points:** 1 per god level gained (levels 2-50), plus 2 per Awaken (4 rites). Total 57. Respec is bought with Faith.
- **Levels:** `PowerBook` rows may carry a `levels` table (5 entries, a twist at level 5). `extra["level"]` is put on every cast. No effect reads it in P1 and no power has a table, so every power plays exactly as before. A power without a table shows "Level effects not set" in the tree.
- **The skill tree screen** shows the god's own type between its two neighbours, tiers gated by god tier, level pips, Might and costs, and each power's icon.

### §6 Might
- The draft budget is **Might** on every screen. Internal names (`dp`, `TierBook.DP`, `Draft` budget names) are unchanged (C1).
- A power costs its base Might, +1 at level 3 and +1 at level 5 (`PowerBook.MIGHT_STEPS`).
- The god's maximum Might is by god tier `6 / 8 / 10 / 13 / 16`, plus Faith. Slots are 3, plus Faith, never above 6.

### §7 Faith
- Every believer banked in Endless Night is 1 Faith. The Faith screen (`FaithScreen`, modelled on the Upgrades screen) sells: +1 slot, +1 maximum Might, +15 s on the descent clock, and a respec of all ability points. The rows are data (`GodSlot.FAITH`).

### §8 Divine Power and god level
- Divine Power is experience. A night earns `80 x tier` for the main objective and `20 x tier` per granted wish; a lost night earns none; caught after the main objective, only the main's counts.
- A level costs `50 x god tier`. God levels 10, 20, 30 and 40 end a tier: the bar stops at full and the hub reads "AWAKEN TO GROW". Divine Power earned at the cap is lost, and the results screen says how much ("N Divine Power lost at the cap"). Maximum level 50.

### §9 Endless Night
- **The hub:** type, level and tier name, the Divine Power bar, ability points, Faith, Lantern Notice (0% in P1), `Night N`. Buttons Descend, Skill Tree, Faith, Title. Keys: Enter, T, F, Esc. With `--dev`, A is the Awaken hook (tier + 1, +2 points).
- **Descend** draws a mission from the god tier's five, never the one played last, from the slot's seed and night: quitting and coming back gives the same night. Descend is blocked with a line when the god has nothing to draft (an empty tree).
- **Prepare** drafts from learned abilities only, at their learned levels, with the god's slots and Might.
- **A night** is a board night: wishes, ASCEND, the bell and the Gaze as the mission sets them. Banking writes only the god's file (never `kak_save.cfg`).
- **No escape by quitting (§9.1).** The `in_night` mark is written when the clock starts. Abandoning from the pause menu (after a confirm that says so) or from the interlude between acts (also after a confirm), or closing the game and pressing Continue, is a lost night: the night counts, nothing is earned. Leaving from Prepare or during the intro is free and the next draw is the same night. Restart, Change powers and R are locked in Endless Night.
- **Results (§9.2):** the objective and wishes, Divine Power and the bar, "+1 ability point" for each level, believers and Faith, `Night N`. Buttons Continue, Skill Tree, Faith. An abandoned night has no results; the hub shows the lost night once.

### §12 Screens
Five new screens: slots, god select, hub, skill tree, Faith. The board gains an `ENDLESS` button beside DEV (`--dev` only).

### §14 P1, tools and tests
- `behaviour_check.gd` takes `--god=<type>:<tier>`, `--dev-tree` and `--level=<1-5>`: the plumbing for the per-type win check (C6). A loadout outside the type's abilities prints `BEHAVIOUR refused scenario=... god=<type>:<tier> outside=...` and quits 1, so `gate.sh` reads it as a failure.
- Tests: `test_power_levels`, `test_god_tree`, `test_god_slot`, `test_god_night`, `test_skill_tree`, `test_faith_hub`, `test_endless_screens`, `test_endless_flow`, `test_board_test_mode` and updates to the older suites. FLOW walks Endless Night end to end (23 new lines): a god made, a night won and banked, the tree, Faith, an abandon, a quit, and the bytes of the board's save unchanged.

## How to reach Endless Night

1. Run the game with `--dev`: `& $godot --path . --scene res://scenes/game.tscn -- --dev`. (`play.bat` passes no arguments.)
2. Open the Missions board from the title. The header shows the test mode text, the DEV tab (press `D`) and an `ENDLESS` button beside it.
3. Click `ENDLESS`. This opens the slots and turns the dev fill on for the session.
4. New, choose a type, Choose. The hub opens on Night 1.
5. Descend. With the real tree empty, the dev fill gives each type its dev abilities, so the god has something to draft.

Leaving Endless Night (Title, or Esc at the hub) puts the god down; Continue on the slot picks it up again. The board's `kak_save.cfg` is never written by Endless Night.

## The numbers in play

Exact numbers come from the spec. Those marked *tunable* are first guesses, to be tuned with the scripted players once the tree is filled.

| Number | Value | |
|---|---|---|
| Save slots | 3 | exact |
| God levels / tiers | 50 levels, 5 tiers, a cap every 10 levels | exact |
| Divine Power per level | `50 x god tier` | *tunable* |
| Divine Power per night | main `80 x mission tier`, each wish `20 x mission tier` | *tunable* |
| Ability point costs | 1 own type, 2 neighbour, far type locked | exact |
| Points earned | 1 per level gained (49) + 2 per Awaken (8) = 57 | exact |
| Maximum Might by tier | 6 / 8 / 10 / 13 / 16 | exact |
| Might rise with level | +1 at level 3, +1 at level 5 | exact (spec's call) |
| Base slots | 3, only Faith adds, at most 6 | exact |
| Faith per believer | 1 | exact (spec's call) |
| Faith: +1 slot | 150, 300, 450 (limit 3) | *tunable* |
| Faith: +1 maximum Might | 25 x n (limit 6) | *tunable* |
| Faith: +15 s descent clock | 40 x n (limit 4, +60 s) | *tunable* |
| Faith: respec all points | 100 x n (no limit) | *tunable* |
| Lantern Notice | written, shown as 0% | P2 |

## The dev fill and how you fill the tree

The real tree, `GodTree.TABLE` in `src/game/god/god_tree.gd`, is empty: 60 `""` spots. The **dev fill**, `GodTreeDev.TABLE` in `src/game/god/god_tree_dev.gd`, is a stand-in for test and scripted play. It fills only empty real spots and never repeats a key the real table uses. It is on when you enter Endless Night from the DEV tab, in tests that turn it on, and with `behaviour_check --dev-tree`. It is reset after FLOW's Endless Night walk and by both test runners.

**To fill the tree, edit `GodTree.TABLE` only.** Put a `PowerBook` key in each spot (two per tier per type, index 0 first). Do not touch `GodTreeDev.TABLE`. As each real spot is filled, it takes over from the dev fill. Then run `tests/test_god_tree.gd` (it runs in the full suite: `bash tools/dev/run_suite_parallel.sh 8`). Its validation (`GodTree.problems()`) checks the six ring types, five tiers of two, every key either `""` or a real `PowerBook` key, and no key twice. A key's Authority is not checked against its spot (spec §5.2). A god made on the dev fill keeps its keys; they stay in its file but are neither drafted nor shown once they sit in no spot (Ruling P4).

Before the first real `levels` table lands, add a `levels_problems()` sweep over `PowerBook.POWERS` to `test_power_levels.gd` so a bad table cannot reach `level_change_in()` (milestone review).

## What is not yet there

- **The Notice's changes, Hunts and seals (P2).** The Notice is saved and shown as 0%; nothing moves it.
- **Awaken rites and gifts (P3, P4).** The hub has only the dev Awaken hook (A with `--dev`); a god cannot yet get past a tier cap in play.
- **The per-type win check (spec §5.2).** The plumbing is built (`--god`, `--dev-tree`, `--level`); the check itself runs with the Tier 1 fill.
- **The Tier 1 fill** of `GodTree.TABLE` (12 spots) and the **title switch** to `Endless Night` (spec §3, C2). Until then the title keeps `Campaign`.
- **The level tables** (`PowerBook` `levels`): no power has one, so all play at their current stats.
- **A god name entry**, and the final god names and flavour lines (the six lines are first guesses, Ruling P19).
- **Eclipse** (spec §11.6) and any Faith rows beyond the four.

## Landing

Landing checks were run by Task 14 on `c2df7f85` (Tasks 1-13), by hand in `land.sh`'s order because its references step takes about 2 hours. The fix wave `f222b2d0` came after, and its merged tree has its own row.

| Gate | `c2df7f85` (Tasks 1-13) | Merged tree (with fix wave `f222b2d0`) |
|---|---|---|
| Trial merge vs `origin/feat/Develop-Main` | clean, 0 incoming commits | - |
| Import | exit 0 | exit 0 |
| Suite (`run_suite_parallel.sh 8`) | `checks=10565 failures=0` | `checks=10637 failures=0` |
| References | 286 / 286 OK, none moved, nothing re-recorded | not rerun (no simulation file changed) |
| `digest` | `61267b7e90524d800bf1c3473a71146b` | `61267b7e90524d800bf1c3473a71146b` (rerun, OK) |
| `crowd_check` | `-935602679` | `-935602679` (rerun, OK) |
| FLOW alone | `checks=160 failures=0` (3 m 44 s) | `checks=160 failures=0` |
| Bench vs `kak-v012-m2` | all five pairs within about 1 fps (below) | not rerun |

Bench (median of 3, fps; A = `kak-v012-m2`, B = `c2df7f85`; the machine was shared with other sessions, so the absolute fps are low):

| Pair | A | B | Delta |
|---|---|---|---|
| warning | 30.1 | 29.6 | -0.5 |
| miras_house | 25.3 | 25.8 | +0.5 |
| vigil_flame | 26.9 | 26.6 | -0.3 |
| procession | 23.3 | 23.4 | +0.1 |
| last_judgement | 25.2 | 24.2 | -1.0 |

`last_judgement` is at the edge of the tolerance (B's runs are tightly 24.0 to 24.3, A's 25.0 to 25.8). It is the one pair worth a rerun on a quiet machine (memory: `kak-m1-perf-debt`).

The fix wave (I1 the cap loss shown, I2 the interlude abandon confirm, M1, M4, M5, M6 icons on tree spots, M9 god seeds) changed no simulation file. Its own suite run (suite 3) was `checks=10637 failures=0`, and its re-review found all seven items addressed with no new critical or important issue.

## Known small issues

Deferred on purpose; each has a one-line fix or waits for a later task.

**From the milestone review (left in the fix wave):**
- M2. The slot screen reads all three god files on every mouse move and draw (up to 9 file loads per event). Fix: read the three slots in `setup()` and again only after a delete.
- M3. A failed write of `in_night` at the clock's start would let a quit escape the forfeit (a disk error only; `_write_god()` only warns). When P2's Notice makes a forfeit costly, show a hub line when the write failed.
- M7. A fresh save's board opens on Ascendance (`save.last_mission` defaults to Last Judgement). Either open on Whisper when `save.descend.night == 0`, or keep it and fix the self-contradicting `_flow_board` doc comment (`game.gd` ~1489). FLOW pins the current behaviour.
- M8. `behaviour_check --god` and `--level` look only at the first act's loadout. A multi-act scenario whose later act drafts other keys plays them at level 1 and is not refused. Note it for the Tier 1 fill's win check, which has no act missions.

**From the tasks' deferred lines:**
- `Draft.set_level` refuses a same-Might raise on an already over-capacity draft (external callers only; Prepare never builds one).
- `PowerBook.level_change_in` has typed `Dictionary` locals that error on a malformed table; `levels_problems()` is the guard (see the sweep above).
- `_mission_keeps` (test_power_levels) is a source-text check; FLOW proves `rules().level_of(0) == 2` through a real night.
- Comments and FLOW messages still say "Divine Power" or "6 DP" for the old budget (`rules.gd:4`, check messages in `game.gd`); not player-visible. Fold the comment into the next touch of `rules.gd`.
- `god_slot.gd:136`: points are not clamped to `points_earned()` on read (a hand-edit cheat in a single-player save).
- `test_god_slot.gd:567`: the version check is trivially true; a local `seed` shadows `seed()`.
- Results screens still show "+N" believer rows on a test night (the summary line says nothing is banked). The Upgrades screen is unreachable by design (`UPGRADES_RECT` stays as a "nothing here" probe).
- Hovering a level badge does not light its slot.
- `forfeit()` with an empty `in_night` counts the night but keeps `last_mission` (both callers check `in_night` first). The `_mission_hooks` test is shallow (FLOW walks them).
- `_bank_leaves_save`'s save checks cannot fail (only the file-bytes check is real); Endless Night's `_on_mission_finished` branch is proved by FLOW.
- Game ignores the result of god writes in `load_god`, forfeit and clock start (see M3). Continue on an unreadable slot is silent (Continue is not offered on one, so this needs the file to vanish between draw and click).
- `GodTree.dev_fill` stays on after leaving Endless Night for the board in the same session; nothing on the board reads it.
- Tree spot names clip without an ellipsis because the icon takes 16 px ("Manufacture" shows as "Manufactur"). When the tree fills, widen the name room or add an ellipsis, and assert fitted names are unique per tier.
- Task 14's concern: a foreground references slice over about 20 rows runs past 10 minutes on this machine; the harness moved those runs to the background on its own.

## Needs you

- Fill the 12 Tier 1 spots of `GodTree.TABLE` (needed before the title switch), then the per-type win check runs.
- The level tables for the first batch of powers.
- The god names and the six flavour lines (`GodTree.FLAVOUR`), and the Endless Night copy marked "my call" in the plan.
- Whether to delete the Missions board later (spec §3 allows it; the code that would go is in Ruling P12).
