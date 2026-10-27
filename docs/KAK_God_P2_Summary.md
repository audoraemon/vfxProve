# Kingdoms Amid Kataclysm (KAK) - God Progression P2 Summary

*Engine: Godot 4.7.2. Branch `claude/god-p2-lantern-04cddc`, landed on `feat/god-progression` (base `a45a7c17`, tag `kak-god-p1`). P2 is the "Lantern" row of spec §14: the Lantern Notice moves, a full Notice brings a Hunt, and a lost Hunt seals one of your abilities. Built 2026-10-27, straight through and subagent-driven: 5 build tasks, a landing task, this note, a milestone review and one fix wave (tip `ebce344e`, on `god/p2-fix`). Spec: `docs/superpowers/specs/2026-10-26-kak-god-progression-design.md` (cited as section numbers). Plan: `docs/superpowers/plans/2026-10-27-kak-god-progression-p2.md`. Every ruling is in `docs/KAK_God_P2_Rulings.md`. P1 is in `docs/KAK_God_P1_Summary.md`.*

## What you asked

The Lantern watches the god. In P1 the Notice was a saved number shown as 0%. P2 makes it move: it rises when you lose a night, quit a night, or get caught, and falls when you ascend cleanly. At 100% the Lantern Hunts: the next night is a Hunt that you cannot skip, played by a stand-in mission. Win it and the Notice resets and you are paid Faith. Lose it and the Lantern seals your most-carried ability for 3 nights. P2 changes no mission rule. No reference moved.

## What P2 built, by spec section

### §10.1 The Notice
Every night that counts moves the Notice by an amount that depends on how it ended. The meter is held between 0% and 100%. The result shows the real change after that limit, never the nominal one.

| How the night ended | Notice |
|---|---|
| Lost: the main objective not done, or the night abandoned | +25% |
| Won, but caught afterwards (dawn, the bell, the Gaze) | +10% |
| Won and ascended | -5% |
| A lost rite (P3's hook, `NOTICE_LOST_RITE`) | +25%, not used yet |

Where it shows: the results line `Lantern Notice N%  (+25%)` (the change only when the number moved); the hub's `Lantern Notice N%` line with a drawn red meter beside it; and, after a night you left, a hub line such as `Night 2 was abandoned: a lost night. Lantern Notice +25%.` A change is never made without one of these.

### §10.2 The Hunt
At 100% the next draw is the Hunt. It cannot be skipped: the draw ignores the seed and even the "not the same night twice" rule, and leaving Prepare or the intro and coming back gives the same Hunt (leaving there is still free, as in P1). The dev Awaken key (A on the hub, `--dev`) is refused while the Hunt is due, with a line. The Hunt is played by a stand-in: an existing board mission, with the Hunt's own title and plate, at the god tier's settings. The Hunt's name shows in the night's intro banner, on Prepare and on the results. Its goal and lose condition stay the stand-in's own, so what you read is what you play.

| God tier | Hunt title | Stand-in | Played at |
|---|---|---|---|
| 1 Whisper | Hide the faithful | Lost Lamb | Tier 1 |
| 2 Omen | Silence the witness | Bell Ringers | Tier 2 |
| 3 Wrath | Expel the inquisitor | The Informer | Tier 3 (it is a Tier 2 mission; it plays with Tier 3's readiness, clock, wishes and multiplier) |
| 4 Reckoning | Break the hunt | Armoury | Tier 4 |
| 5 Ascendance | Face Halcyon | Heart of Faith | Tier 5 (the Gaze is on) |

The plates are the spec's: "Lead your believers out before the inquisitors reach them", "Stop the runner carrying word of you to the Lantern", "Drive out or kill the Lantern's captain in the town", "Smash their standards before they reach your believers", "His Gaze is on the whole town, and a seen death fills it". The stand-ins are placeholders: P5 writes five real Hunt nights.

### §10.3 The result
- **Won** (the main objective done; being caught afterwards still counts as won): the Notice goes to 0%, you earn the believers' Faith plus a bonus of `50 x god tier` Faith (50 / 100 / 150 / 200 / 250), and Divine Power as any night at the god's tier.
- **Lost** (main objective not done, or the Hunt abandoned): the Notice goes to 50% (a set, not +25 on top), no Divine Power, and the Lantern seals the most-carried ability for 3 nights.
- **The most-carried ability**, exactly: among the learned abilities that sit in a tree spot, the one carried on the most banked nights; ties go to the higher Might at its learned level, then to the earlier tree spot (ring order from Ruin, then tier, then index). The Hunt's own draft is not counted, so what Prepare and the pause menu showed before the Hunt is what is sealed. If fewer than 2 abilities are in the tree nothing is sealed ("The Lantern found nothing to seal") so a god is never left with nothing to draft.
- **The 3 nights** are the next three nights that count, banked or abandoned, Hunts included. Each tick shows on the results or the hub line; the third says `<ability> is no longer sealed.` A lost Hunt on a seal's last night replaces it with a fresh 3 (one seal at a time). A sealed ability is dropped from the remembered loadout and not given back when the seal ends.
- A Hunt keeps no per-mission best. The stand-in becomes the "last mission", so the next ordinary draw avoids it.

### §9.1 No escape by quitting, now with a cost
Abandoning from the pause menu, abandoning from the interlude between acts, and closing the game after the clock started (then pressing Continue) all go through the same forfeit. On an ordinary night that is a lost night: the night counts, nothing is earned, and the Notice rises (+25%). On the Hunt it is a lost Hunt: the seal and 50%. The pause menu says so before you confirm:
- An ordinary night: `Abandon now and the night is lost: no Divine Power, no Faith, Lantern Notice +25%.` From a Notice of 75% up the rise is the real one after the limit, and the line says when this brings the Hunt (`..., Lantern Notice +5%, and the Lantern Hunts next.`; at 100%, `... Lantern Notice is already 100%, and the Lantern Hunts next.`).
- The Hunt: `Abandon the Hunt and it is lost. The Lantern will seal <ability> for 3 nights, and the Notice goes to 50%.` (or `The Lantern has nothing to seal`).
- Before the clock starts: `The clock has not started: leaving is free.`

If the god's file cannot be written (a full or read-only disk), the hub says so once: `The god could not be saved (error N): progress since the last save may be lost.` It never shows twice for the same failure. This covers the clock-start write, the bank, the forfeit and a slot opened mid-night.

### §9.2 and §12 The screens
- **Hub:** P1's lines unchanged; a Notice meter beside the Notice line; `THE LANTERN HUNTS: the next night is the Hunt, <title>` when it is due; `Sealed by the Lantern: <ability>, <n> nights left` while a seal is on; the one-off line (the lost night, the failed write) wraps at 600 px above the buttons.
- **Results:** the objective and Divine Power as before; `Lantern Notice N%` with its change; for a Hunt: `Lantern Hunt: <title>  -  <tier>` in place of the mission line, then won (bonus Faith, in gold) or `The Lantern seals <ability> for 3 nights.`; `<ability> is no longer sealed.` when a seal ended; a next-Hunt warning when this night brought the Notice to 100%; then `Night N`.
- **Prepare:** a Hunt's header is `THE LANTERN HUNT` (red). Its briefing shows HUNT (title and plate), WIN, LOSE, IF WON (`Notice 0%, +N Faith`) and IF LOST (the stake, `Notice 50%`). The LOADOUT row is dropped on a Hunt to make the room (Ruling T3). A sealed ability stays on its tab, dimmed with a red cross and the cost line `Sealed: N nights`; clicking it is refused with `Sealed by the Lantern: N nights left`, and it is never preselected.
- **Pause:** the confirms above, in a 420 px box; the Abandon/Stay row moves down to clear a third line.

### Tools and tests
- Photographs: `--show=hub-hunt`, `hub-sealed`, `prepare-hunt`, `prepare-sealed`, `results-hunt-won`, `results-hunt-lost` and `pause-hunt`.
- `TierBook.board(id, state, at_tier := 0)`: the one change outside the god code. With no tier it builds what it always built (the references prove it); a Hunt passes the god tier.
- New suite `test_god_lantern`; additions to `test_god_night`, `test_god_slot`, `test_faith_hub`, `test_endless_screens`, `test_endless_flow`. FLOW gained a Lantern walk (15 checks, 175 in all): the Notice from 50% to 100% by an abandon, the Hunt on Prepare and in the pause menu, the Hunt lost, the seal on the results, the hub and Prepare, and the board's save bytes unchanged.

## How to see it

1. The DEV path from P1: run with `--dev` (`& $godot --path . --scene res://scenes/game.tscn -- --dev`), open the Missions board, `ENDLESS`, New, choose a type, Choose. (Since the Tier 1 fill landed, the dev fill adds abilities only where the real Tier 1 leaves a spot empty.)
2. A quick way to a Hunt: a god at 75% and one abandoned night. There is no Notice editor; the fastest way is to lose four ordinary nights (4 x 25%) by Descend, wait for the clock (the pause menu stops saying "leaving is free"), Esc, Abandon. The hub then reads `Lantern Notice 100%` and `THE LANTERN HUNTS`. Or, for the shortest path, edit `notice = 75` in the slot's `user://kak_god_<n>.cfg` and abandon once.
3. Descend plays the Hunt. To lose it quickly, Abandon from the pause menu after the clock starts (the confirm names the ability). The hub shows the seal; Descend again shows the sealed card.
4. Photographs: `tools/capture.sh --show=hub-hunt` and the others above.

## The numbers in play

| Number | Value | |
|---|---|---|
| Notice range, Hunt due | 0 to 100%, due at 100% | exact |
| Lost / caught / ascended | +25 / +10 / -5 | exact (spec §10.1) |
| Hunt won | Notice 0%, Faith bonus `50 x god tier` | Notice exact, bonus *tunable* |
| Hunt lost | Notice 50%, seal for 3 nights | exact |
| Seal length | 3 counted nights | exact (spec §10.3) |
| Hunt stand-ins | Lost Lamb / Bell Ringers / Informer / Armoury / Heart of Faith | placeholders until P5 |
| Lost rite | +25 | P3 |
| Save format | unchanged (`VERSION` 1); the Hunt is derived from the Notice | exact |

## Landing

Merged tree `6ee2b044` is the P2 branch with the user's Tier 1 fill `420a4e37` from local `feat/god-progression` (unpushed; origin still at `a45a7c17`). The trial merge was clean. The fix wave `ebce344e` was made on `god/p2-fix` from the merged tree.

| Gate | Merged tree `6ee2b044` | Fix wave `ebce344e` |
|---|---|---|
| Trial merge vs `feat/god-progression` | clean; 1 incoming commit (the Tier 1 fill) | - |
| Import | exit 0 | - |
| Suite | `checks=10881 failures=0` (jobs 8) | `checks=10908 failures=0` (jobs 3) |
| References, every row | `refs ok=286 bad=0` (jobs 8) | digest, `crowd_check` and `calm` OK |
| `digest` | `61267b7e90524d800bf1c3473a71146b` OK | `61267b7e90524d800bf1c3473a71146b` OK |
| `crowd_check` | `-935602679` OK | `-935602679` OK |
| FLOW alone | `checks=175 failures=0` (230 s) | `checks=175 failures=0` (235 s, final tree `71551be8`) |
| Bench vs `kak-god-p1` | - | run on final tree `71551be8`: no steady change (below) |

Bench pairs (median of 3, fps; A = `kak-god-p1`, B = the final tree `71551be8`). Run 1 had another session's Godot runs starting mid-bench; run 2 began with no other Godot running. Both runs are slow on every board (remote-desktop load), so read the pairs, not the absolute fps.

| Board | Run 1 A / B | Run 2 A / B |
|---|---|---|
| warning | 32.4 / 34.0 | 43.6 / 44.3 |
| miras_house | 37.7 / 33.9 | 34.5 / 32.4 |
| vigil_flame | 46.6 / 38.3 | 31.5 / 30.0 |
| procession | 31.7 / 30.4 | 25.8 / 25.1 |
| last_judgement | 29.0 / 29.2 | 30.3 / 28.4 |

The runs overlap on every board and the direction flips between runs (warning and last_judgement). P2 adds no per-frame work to a mission: the Notice, the Hunt and the seal are read on the hub, Prepare, results and pause screens, and a Hunt night plays a normal board with a different TierBook tier. Rerun on a quiet machine before the next release if a 1-2 fps gap matters.

The milestone review (opus) approved the merged tree: 0 critical, 0 important, 6 minor. The fix wave took M2 and M6; a sonnet re-review approved it. Earlier per-task runs: Task 1 suite 10761, Task 2 10807, Task 3 10861, Task 4 10873 then 10877, Task 5 10873; FLOW alone 160/0 after Task 4 and 175/0 after Task 5 (and again after Task 4's fix round).

## Known small issues

Left on purpose; each has a short fix or waits for a later task.

**From the milestone review (left in the fix wave, C13):**
- M1. A night that is already decided but closed during the 2-3 s ending is forfeited. A won Hunt becomes a lost Hunt with a seal (and any won night becomes +25 instead of its own change). The file still says `in_night` from the end of the objective until the ending finishes. P1 accepted "a crash mid-night costs a night"; P2 makes the window cost more. Fix: have Game bank on the mission's `over` signal and leave only the screen change to `finished`.
- M3. The night after a Hunt may be the night before it. The Hunt's stand-in becomes the "last mission", so the draw may pick the mission played before the Hunt (the FLOW log shows first_prayers, the Hunt, first_prayers). As ruled (P2-10). Avoiding it needs a second remembered id.
- M4. A failed clock-start write is invisible if the player then quits. The failure line lives in memory for the next hub; with the file missing `in_night` the reload forfeits nothing and nothing was shown. A disk error only (a failing disk usually failed earlier writes too, which were shown).

**From the tasks' deferred minors (`progress.md`):**
- Task 1 M1. A lost Hunt with nothing to seal keeps `unsealed` when a seal just ran out, and no test reaches it; the Hunt's forfeit line never mentions the freed ability. Practically unreachable (it needs a seal whose key was respecced out).
- Task 1 M2. `_hunt_draw`'s 99% check is trivially true for Tier 3 (the Informer is not in Tier 3's missions).
- Task 1 M3. `_seal_replaced` drafts the sealed key, which the real Prepare cannot do.
- Task 1 M4. The stake may name an ability that is already sealed (a Hunt always lands on a seal's last night); the copy could say "keeps X sealed".
- Task 2 M1. `_hunt_def` never checks `extra_clock() > 0`, so the Faith clock it compares against could be 0 and the check would still pass.
- Task 2 M2. Only Tier 3 proves `def_for()` uses the god tier; stretch and readiness are not checked for the Hunt's def; tiers 1, 2, 4, 5 would pass with the old build.
- Task 2 M3. `_board_at_informer`'s first message formats a null result and would crash instead of failing.
- Task 2 M4. `def_for()` passes the raw `slot.tier` while `hunt_for()` clamps it to 1-5 (only a corrupt file).
- Task 4 M3. A stale write-failure line can outlive a later good write (honest, shown once).
- Task 4 M4. The `hub-sealed` photograph says "3 nights" in its one-off line and shows 2 left on the seal.
- Task 4 M5. `SAMPLE_HUNT_WON` and `SAMPLE_HUNT_LOST` are hand-written, not built by `GodNight.bank()`; if `bank()`'s keys change the photographs drift silently. `SAMPLE_HUNT_LOST` names "smite", a literal.
- Task 4 re-review. `_write_god`'s `join_lines` call is not pinned by a test (only the helper is); and two different error codes still show two sentences.
- Fix wave re-review. An ordinary night that runs at Notice 100 (the draw never produces one; only dev fixtures) says "already 100%", though its abandon would really be a Hunt loss.
- The fix wave did not add an IF LOST row to a normal night's Prepare (the review's optional part): a normal night's loss is shown only in the pause menu and the hub, not on Prepare.
- Tier 3's Hunt rows have 1 px of room on Prepare. Any longer Informer text breaks `_prepare_hunt_fits`, which is the alarm.
- Tests that cannot fail: Task 2 M2 (`_hunt_def` tiers 1/2/4/5), `_board_at_default`'s first comparison (same code path; the references are the real proof), Task 1 M2. `_seal_target`'s "key in no spot" leg is skipped silently if every power has a spot (today 56 powers against about 41 keys, so it runs).
- The merged FLOW log prints "Lambda capture" errors in P1's board steps (before the Lantern walk). They did not fail a check.
- The Informer at Tier 3 (the Tier 3 Hunt) is not checked winnable by the scripted players.

## What is not yet there

- **The five real Hunt nights (P5).** The stand-ins stand in; each real Hunt will be its own short mission.
- **Rites and the Awaken button routing to the Hunt (P3).** The hub's Awaken is still the dev key. When P3 builds the Awaken button it must route to the Hunt when `hunt_due()` holds, as the dev key does by refusing.
- **A per-night seen-death count (Ruling P2-2).** "Clean" is "ascended"; a seen death is not counted per night, so a win that ascended after a seen death still reads -5%.
- Gifts (P4), the level tables, god names, and the title switch (see Needs you).

## Needs you

- **The title switch (M5).** Spec §3 says the title's first button switches to Endless Night once the Tier 1 fill lands. The fill has landed, and the title still says `Campaign` and still offers Endless Night only on the board's DEV tab, which turns the dev fill on. Switch the title to Endless Night with the dev fill off, as its own small task. Say yes and it is next.
- **The five real Hunt nights (P5):** the title, plate and rules of each, to replace the stand-ins. Check the Informer at Tier 3 is winnable.
- **The Hunt's copy and Faith bonus.** The titles and plates are the spec's; every other line (the confirm texts, the hub lines, the results lines) is my call. The bonus `50 x god tier` Faith is *tunable*.
- **A clean win and a seen death (Ruling C9 / P2-2).** Should a clean win (-5%) also need no seen death? It needs a per-night seen-death count in the Descent, which touches simulation files and would move references.
- **Pushing.** Local `feat/god-progression` holds your Tier 1 fill `420a4e37` (unpushed; origin is `a45a7c17`) and, after landing, P2 and its tag `kak-god-p2`. Nothing is pushed without your yes; `feat/Develop-Main` is untouched.
- Still open from P1: the level tables for the first powers, the god names and flavour lines, and whether to delete the Missions board.
