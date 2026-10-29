# Kingdoms Amid Kataclysm (KAK) - Tier 1 Routes Summary

*Engine: Godot 4.7.2. Branch `god/t1routes`, landing on `feat/god-progression` (cut from the Tier 1 fill `420a4e37`; P2 and P3 were merged into it before landing, `16803dd7` and `d95cf423`). "Option C" of the Tier 1 fill: every god type now wins all five Tier 1 missions with only its own two Tier 1 powers. Built 2026-10-27 to 2026-10-29, straight through and subagent-driven: 8 build tasks (every mission task with a review and one to four fix rounds), a landing task, an opus final review with one fix wave, two re-reviews, this note. Spec: `docs/superpowers/specs/2026-10-27-kak-tier1-routes-design.md` (amended in place for W3 and F3b). Plan: `docs/superpowers/plans/2026-10-27-kak-tier1-routes.md`. Every ruling is in `docs/KAK_God_T1R_Rulings.md`. P1, P2 and P3 are in `docs/KAK_God_P1_Summary.md`, `docs/KAK_God_P2_Summary.md` and `docs/KAK_God_P3_Summary.md`.*

## What you asked

The Tier 1 fill gave each god type two Tier 1 powers (Ruin Smite and Ember, Death Death Mark and Pestilence, Veil Silent Doom and Blight, Passage Thornwall and Mirrorfold, Decree Leaving Is Prohibited and The Bell Lies, Dominion Mind Whisper and Discord). The god-progression design says every type must be able to win every Tier 1 mission with only those two. Before this milestone that was not true: most missions had one or two ways to win, and a Decree god had no way to stop a tax collector. On 2026-10-27 you chose "Option C": give each mission more ways to win, so all 30 pairs (six types times five missions) can be won, and you approved the routes table. You also set three shared rules and the mission rules every route must keep (below). Last, once the 30 pairs passed, the title's first button becomes Endless Night.

## The mission rules every route keeps

These are your rules (D4) and they were the gate on every route:

- Every timed wait is 60 s or less.
- Doing nothing loses 3 of 3.
- The scripted player wins at least 2 of 3 seeds, and idles no more than 45 s (three pairs may idle up to 60 s by your word, see Problems).
- No luck: nothing a route needs depends on who happens to walk by. No hidden losses: every new stop or give-up has a banner.
- Every moving target has an edge-arrowed tag and its tag counts down. The bell never loses outright.
- New rules are opt-in: a flag the shared director leaves off, set only by the Tier 1 director, so no other mission changes.

## The three shared rules (you)

1. **Out of the walls.** A warning's messenger, a tax collector or a harvest carter who gets outside the town's walls (the wall plus half a unit) is gone for the night and counts as stopped. However he got there: through a gate, whispered, frightened, or set down by a Mirrorfold. He is sent on to the nearest map exit and taken off the map; he never walks back in. A warning dies, a collector counts with the dead, a carter's granary counts spoiled. This does not count as a citizen escaping. In the Capital the river gates count as ways out.
2. **He bolts.** The Lost Lamb's acolyte runs for the west gate himself, when something frightens him near him (a Smite landing, a building afire, any death, his fountain blighted) or at 1:00 at the latest. If you lead him first (Mind Whisper, a Wisp) he never bolts. Doing nothing: he bolts at 1:00 into the patrols and the gate watch and is seized.
3. **They come to pray.** At First Prayers the poor walk to the old well themselves, one at a time, the first at 1:20. The Faithful at the door still see them, so doing nothing loses.

## What each mission got (new rules, in plain words)

**The Warning (the board's Starfall).**
- Out of the walls stops any carrier at any step. A relay witness standing outside is out at once.
- A keeper who heard ALL IS WELL (The Bell Lies) does not believe the messenger: the warning dies, the carrier is sent home. If the bell is already called, climbing or waiting, the lie calls the ringer back (so stopping the warning never still loses). A tolling or silenced bell stays; the Herald is never fooled.
- **W3, the watchman keeps his gate** (added mid-build, D28). During his 4 s stare at his star, a death just outside his gate (within 4 units of the post, past the wall) draws the watchman out to the body, and out of the walls stops the warning. The barred postern's watchman holds its key: a body or a fright sets him down just beyond it. Ruin and Death could not find an unseen kill on a street that is never empty; this is the smallest rule that gives them one.
- You can play it: the NEXT STAR tag counts down to the fall, and the board hint names the death outside his gate.

**The Tax Collector.**
- Out of the walls stops a collector (state OUT, banner A COLLECTOR LEAVES TOWN). The objective now reads "Stop the collectors".
- **The debtors mob the collector** (Decree). Leaving Is Prohibited centred within 3 units of a door he went in at, with his guards drawn off (none within 1.5 for 3 s), and he is mobbed by that house's debtors: he dies unseen, the bell is not called. The Bell Lies' CALL THE GUARD draws the guards off first. His tag reads TAX COLLECTOR - GUARDED while a guard still stands by.

**Spoiled Harvest.**
- Carters set out 30 s before their grain, and wait at the granary door, so there is something to do before 1:00. Tag: CARTER - GRAIN IN m:ss, then CARTER - n LEFT.
- Out of the walls spoils the carter's granary. A dead carter is replaced after 30 s (killing one is never a spoil).
- **Plague**: a sick carter spoils his granary if no watchman of it stands on guard (else THE WATCH TURNS THE SICK CART AWAY).
- **Blight** rots a full granary with no watchman on guard (BLIGHT - THE GRAIN ROTS; NO GRAIN TO ROT YET; THEIR WATCH KEEPS IT).
- **The guard seize the cart** (Decree): CALL THE GUARD, once its first soldier stands at his ring spot, seizes every carter within 3 units of the law's centre or the bell's place; his granary counts spoiled.

**The Lost Lamb.**
- The bolt (above), tags ACOLYTE - BOLTS IN m:ss and ACOLYTE - RUNNING, banner HE BOLTS FOR THE WEST GATE. One gate watchman stands just outside the gate, so a Mirrorfold past the gate still lands in his sight unless the watch is drawn off.
- Passage may fling a patrol into Aldermere's north-west dead end (your ruling, D25; a test pins it).

**First Prayers.**
- The poor walk to the shrine themselves (tag POOR - TO THE SHRINE), first at 1:20, then 50 s after the one before went in or was turned away.
- **Fire pulls the Faithful** (Ruin): a building burning within 7 units of the door pulls the Faithful lining it to the fire for as long as it burns.
- **Brambles by the well** (Passage, F3b): a Thornwall segment within 1.5 units of the door hides it from every Faithful on every side, and a poor who went down hidden comes up hidden. A Believer never goes down twice, and a wall's look-lure never counts as bringing a poor in.
- **ALL IS WELL stands the Faithful down** (Decree): while the bell lies, no Faithful sees the door, a window due during the lie forms when it ends, and running reports are dropped.
- **The door stands empty** (your ruling, D34): with no Faithful left alive, the chain is skipped, the poor the night still needs set out at once and pray together. Banner THE DOOR STANDS EMPTY - THE POOR HURRY IN. A stuck walker gives up after 20 s (ONE OF THE POOR GIVES UP THE WALK) and is replaced.

## The routes as built

Aldermere, the binding town. Cells are wins, median clear, longest real idle, for the final tree (`god_gate.sh`; `none` loses 3/3 on all five missions). Medians are reported only; the bar is 2 of 3 and idle 45 s, except the three marked pairs (60 s).

| | The Warning | Tax Collector | Spoiled Harvest | Lost Lamb | First Prayers |
|---|---|---|---|---|---|
| **Ruin** | 3/3, 75 s, 32 s | 3/3, 128 s, 40 s | 3/3, 193 s, 40 s | 3/3, 50 s, 33 s | 3/3, 201 s, 32 s |
| **Death** | 3/3, 78 s, 34 s | 3/3, 135 s, 34 s | 3/3, 154 s, 30 s | 3/3, 79 s, 39 s | 3/3, 121 s, 53 s (60) |
| **Veil** | 3/3, 162 s, 42 s | 3/3, 132 s, 30 s | 3/3, 152 s, 40 s | 3/3, 50 s, 32 s | 3/3, 91 s, 39 s |
| **Passage** | 3/3, 148 s, 38 s | 3/3, 164 s, 35 s | 3/3, 86 s, 37 s | 3/3, 148 s, 42 s | 3/3, 225 s, 59 s (60) |
| **Decree** | 3/3, 152 s, 42 s | 3/3, 198 s, 43 s | 3/3, 157 s, 60 s (60) | 3/3, 109 s, 20 s | 3/3, 226 s, 22 s |
| **Dominion** | 3/3, 102 s, 32 s | 3/3, 179 s, 39 s | 3/3, 202 s, 30 s | 3/3, 109 s, 28 s | 3/3, 207 s, 45 s |

`god_gate tier=1 pass=30/30 none_lost=5/5 PASS`. The idle column is the real wait: filler casts that do nothing no longer count (D38, below).

How each pair wins:

| | The Warning | Tax Collector | Spoiled Harvest | Lost Lamb | First Prayers |
|---|---|---|---|---|---|
| **Ruin** | Smite the guard posted outside his gate during the stare (W3) | Smite along his road at his door; Ember the counting-house for the last | Smite the watchmen, Ember the granary | Ember a house or Smite starts the run; Smite each patrol, the watch | Ember a house pulls the Faithful to the fire; Smite a lone one |
| **Death** | Death Mark that guard 8.5 s before the star falls (W3) | Death Mark with 11 s of street left; Pestilence on him with his guards | Death Mark both watchmen, then Pestilence on the carter | Death Mark a citizen by him starts the run; mark patrols; Pestilence 8+ away from him | Death Mark and Pestilence take every Faithful, then the door stands empty |
| **Veil** | Silent Doom the messenger and each relay; quiet Dooms at the tower | Blight the Bell Tower, then Doom in the street | Doom both watchmen, Blight the granary | Blight his fountain starts the run; Doom pairs (two Dooms for the watch) | Doom the Faithful, then the door stands empty |
| **Passage** | Thornwall across his first steps; Mirrorfold him out beyond the walls | Mirrorfold him out beyond the wall; Thornwall along his road | Mirrorfold the carter out (one mirror takes two) | First mirror flings a patrol to the north-west dead end; the lap at the gate | Brambles by the well, a Faithful folded away, a far walker mirrored to the door |
| **Decree** | ALL IS WELL as he nears the keeper; Leaving Is Prohibited holds a runner until the lie | CALL THE GUARD, then the law on the door: the debtors mob him | Law on the carter, then CALL THE GUARD: the guard seize the cart | Law pins a patrol; CALL THE GUARD on the watch | ALL IS WELL at each window; the law pins the Faithful |
| **Dominion** | Whisper him out in hops; Discord holds him | Whisper him out in 9-unit hops | Whisper the carter out in hops; Discord | Discord patrols, whisper the watchmen off their posts (he bolts at 1:00) | Whisper a Faithful away from the shrine |

The existing routes keep their verdicts, in both towns, with their `none` cases. The board Warning's route B won at 108 s (was 124 s) because its whisper now takes the carrier outside the walls. Route A at Spoiled Harvest runs 182 s, at First Prayers 186 s (seed 1 is a win again). Route B at First Prayers runs a 129 s median because its 150 s floor is relaxed there (D34).

### In the Capital (reported only)

Tier 1 in the Capital is dev-only, so these are not binding (D10, D36): `pass=24/30 none_lost=5/5`.

- The Warning 3/6 of its pairs: Death 0/3, Passage 0/3, Veil 1/3.
- First Prayers 3/6: Ruin 0/3, Death 1/3, Passage 2/3 with a 297 s median, Dominion 3/3 with a 72 s idle.
- Tax 6/6 (Passage 2/3), Harvest 6/6, Lamb 6/6 (Passage and Dominion 2/3).

The policies were tuned in Aldermere. The Capital's West River and West Gates have no guard posted outside (so W3 has no body to draw him out), and its first walker goes at 150 s to keep route A's median.

## The numbers in play

| Number | Value | |
|---|---|---|
| `Walls.MARGIN`, past the wall's band | 0.5 | *tunable* 0.3 to 1.0 |
| Leaver taken off the map within | 1.2 of the exit (`LEAVE_REACH`) | exact |
| Warning: stare, `stop_wait`, W3 `GATE_SIGHT`, `KEY_STEP` | 4 s, 30 s, 4.0, 1.2 | stare and `stop_wait` exact; the others *tunable* |
| Tax mob: door radius, guard radius, hold | 3.0, 1.5, 3 s | *tunable* (the spec's, never moved) |
| Harvest: `CARTER_LEAD`, `RELIEF_AFTER`, `SEIZE_R` (+0.05 slack) | 30 s, 30 s, 3.0 | *tunable*; `SEIZE_R` was 2.5 in the spec (D19) |
| Lamb: `BOLT_AT`, `BOLT_REACH`, bolt pace | 60 s, 6.0, 0.385 | *tunable*; `BOLT_AT` goes down, never up |
| Lamb gate watch | posts at (2.7, 14.6) and (2.7, 16.8) | exact |
| Prayers: first walker, later walkers | 80 s (Capital 150 s), then 170 s and 240 s or 50 s after the one before | *tunable* (spec had 60/135/200 and 35) |
| Prayers: `FIRE_PULL`, `THORN_HIDE`, `WALK_STALL` | 7.0, 1.5, 20 s | *tunable* |
| Idle allowed | 45 s; 60 s for Harvest x Decree, Prayers x Death, Prayers x Passage | your rule |
| Per-type bar | wins 2 of 3, idle, `none` loses 3 of 3 | your rule |
| Save format | unchanged | exact |

## The title switch

The title's rows are now Endless Night, Missions, Options, VFX Sandbox, Quit. Endless Night from the title opens the slot select with the **real** tree (the dev fill off); its Back returns to the title. From the Missions board's ENDLESS button the dev fill is on, as before, and Back returns to the board. The Lantern campaign left the title; its handler stays in `Game` for FLOW and for a later change of mind. The board stays as the test mode. The campaign's "ending not yet seen" branch is no longer reachable from the title (a known side effect, D7).

## Landing

Landing follows D1 and D37: P2 landed first, so `feat/god-progression` was merged into this branch (a merge commit, conflicts in `game.gd` and `tests/test_endless_screens.gd` resolved as unions), then P3 (`d95cf423`, no conflicts). The final ff of `feat/god-progression` is a fast-forward. Tag `kak-god-t1r` locally; nothing is pushed without your yes; `feat/Develop-Main` is untouched.

| Gate | Result |
|---|---|
| Import | exit 0 |
| Suite | `checks=11924 failures=0` (land.sh on d95cf423, P3 merged in; P3 alone ended at 11488) |
| References, every row | `refs ok=403 bad=0` (P3 ended at 307; Tier 1 routes add 90 `god_<type>_<scenario>_play_<n>` rows, 6 startle rows and re-recorded rows) |
| `digest` | `61267b7e90524d800bf1c3473a71146b` (unchanged) |
| `crowd_check` | `-935602679` (unchanged) |
| FLOW alone | `checks=209 failures=0`, alone in the foreground (land.sh's own FLOW gave no result, and one earlier rerun failed at the first results screen's banked believers under load; the rerun alone passed) |
| Bench vs `kak-god-p3` | median of 3 fps, A = kak-god-p3, B = this branch: warning 34.1 / 33.9, miras_house 30.1 / 29.3, vigil_flame 31.6 / 32.2, procession 28.2 / 28.7, last_judgement 29.0 / 28.7 -- all within 1 fps (a busy machine; both sides equally low) |
| 30-pair gate (Aldermere) | `pass=30/30 none_lost=5/5 PASS` |
| Landed commit | the `feat/god-progression` tip tagged `kak-god-t1r` |

**References.** The 99 Tier 1 rows were allowed to move and were re-recorded in the commit that moved each, with the reason: the Warning's route B and toll rows (the whisper now reaches outside the walls), the Harvest rows (carters wait at the door), the Lamb rows (the bolt and the outer post), the Prayers rows (walkers, and the door stands empty). The other rows, the digest and `crowd_check` did not move. At the final review the 382 rows were all OK, and the final fix wave re-recorded 9 more (Passage x Prayers 1 to 3, Dominion x Prayers seeds 2 and 3, Decree x Harvest 1 to 3, and `capital_prayers_b_play_2`) because fillers were deleted.

## The reviews

- **Per task.** Every mission task was reviewed. Tax found one important defect (the mob read where the collector stood, not the law's centre, so about half of the clicks on a door failed: D17). Harvest the same defect in the seizure (D23). The Lamb found that Passage won by flinging a patrol into a dead end (ruled by you: fair, D25). The Warning found three things a human could not play (a hidden countdown, a hint that did not name W3, no pin on the gate guards: D29). Prayers found that the poor's walk needed a hint, that a stuck hurrier could hold a slot silently, and that Passage had no route without brambles (D33, D35). All were fixed and re-reviewed, most by a haiku re-review.
- **Final review (opus)** of the whole range: 0 critical, 1 important, 7 minor. The important one: Passage x First Prayers passed its idle bar only on casts that do nothing (a mirror over the Temple's door with no one to fold); the real wait was 66 to 69 s. D38 ruled a fix wave: the gate now prints the real idle (a filler is marked, and an idle stretch ignores it), the fillers were deleted or replaced by real plays, and the minors M1 to M7 were fixed.
- **Final re-review.** It found the Dominion x Prayers whisper and a few idle-triggered casts in Tax, the Lamb and Harvest to be judgement calls; D39 ruled a cast that moves or blocks a real opponent counts as play. The test that bans fillers now also catches a filler built as `FILL + words`. Passage x Prayers real wait was 59 / 53 / 53 s after three honest tries; you ruled it may idle to 60 s (D40).

## Problems found and how each was ruled

The spec listed 13 problems; the build found more. Each is in `docs/KAK_God_T1R_Rulings.md`.

1. **Doing nothing must lose at Prayers** (spec problem 1): the first walker is timed to arrive as the market fills. D11.
2. **No early work at Harvest** (2): carters set out 30 s early. D11.
3. **Plague and Blight spoil only an unguarded granary** (3). D11.
4. **Warning x Passage is tight** (4): a policy answer was found (a Thornwall at the Postern holds him about 20 s, which fits the mirror's 54 s cooldown); the chain-at-exit fallback of D11 was built, tested and removed again.
5. **Debtors in a crowd is luck** (7): the mob is the visited house's debtors at its door, with the guards drawn off. D11, D17.
6. **A dead carter blocks a granary** (8): replaced after 30 s. D11.
7. **Capital river gates** (9): they count as ways out. D11.
8. **Lamb x Passage is a one-mirror win** (10): one gate watchman stands outside the gate; L2 (anywhere outside the walls) was dropped so the watch is judged before the exit.
9. **Harvest x Decree idles to 60 s** (6): the Bell Lies' cooldown. You were told as the one exception. D12. (In the end the policy's real wait at Harvest x Decree is the full 60 s.)
10. **Warning x Ruin and Death won 1/3** after five and four policy rounds: the Postern star's street is never quiet. A fresh opus round found W3, the watchman keeps his gate (D26, D28).
11. **Prayers x Death idled 126 to 161 s** waiting on the chain: you chose the door-stands-empty rule and 60 s (D34).
12. **Prayers x Passage won 0/3**: brambles by the well (F3b, D33).
13. **Prayers x Passage real wait was 59 s** after three honest tries: you ruled up to 60 s (D40).
14. **The gate's idle was a lie** (final review I1): filler casts reset the idle count. The gate now prints the real wait. D38, D39.
15. **Lamb x Passage rests on Aldermere's north-west dead end**: you ruled it fair; a test pins it (D25). The Capital's Passage is 2/3.

## Known small issues

Left on purpose; each is reported, not hidden.

- **Short medians.** Reported only (D10): The Warning Ruin and Death about 75 s, Lamb Ruin and Veil 50 s, Harvest Passage 86 s (one mirror takes the first two carters, D24), Prayers Veil about 90 s (every Faithful dies, then the door stands empty), route B at Prayers 129 s (the floor is relaxed at Prayers, D34), Tax Ruin, Death and Veil 128 to 135 s (the night's floor is 125 s).
- **Dominion x Prayers sits exactly at 45 s at seed 2** and rests on the whisper that moves a Faithful away from the shrine. D39 counts it as play; if you rule it a filler, its real wait is 59 s, the same case as Passage x Prayers (D40 already covers it).
- **Veil x Tax leans on Blight cracking the Bell Tower** (a seen death then rings nothing). A legitimate move; a reviewer may rule otherwise.
- **Passage x Lamb has no slack:** its idle is 42 s of 45, and the dead-end pocket carries it.
- **Policies read some director state** (the late window, the fire, the walker's road); each is something the player is shown as a tag, banner or strip entry.
- **A Capital Tax Passage deputy stalls near a Thornwall** (Capital seed 2: he stands still from 100 s to the end; the same run without the smoke Thornwall wins). Cause not found; not a Task 3 rule.
- **The campaign's "ending not yet seen" branch** is unreachable from the title (D7).
- **Parked minor test gaps:** Harvest's `bound.has(p)` term is not pinned by a test; a law-in-two-slots loadout would miss the earlier law; a hurrier wedged 0.7 to 1.3 from a door that is not overgrown holds a slot (the walker has the same gap, a follow-up if you want no slot held); the hurrier give-up test checks banner text the walker also emits.
- **Landing noise:** FLOW fails or gives no result when launched from a background shell (it passes in the foreground and alone); machines were rarely quiet, and bench fps flipped between two regimes for both sides together.

## What is not yet there

- **The level tables, batch 1, and god names and flavour lines** (from P1), still to be written.
- **Per-type hints.** Hints are per mission; they do not say how a Decree or a Passage god wins. A hint per type would help a first-time player.
- **The Capital per-type rows** (24 of 30 pass). Tuning them is a follow-up if Tier 1 ever opens in the Capital.
- **A `--board` sweep of the 24 other pairs.** The gate plays the board version only for the Warning; Endless Night serves every Tier 1 mission as `TierBook.board(id)`. A one-off sweep would close that gap before the next tier.
- **The five real Hunt nights (P5)** still use P2's stand-ins; the Lamb stand-in now bolts, and its Hunt plate does not mention it.
- **Gifts beyond the first, rites at levels 20, 30 and 40** (P4).

## What to play by hand first

The scripted player is not a human. These are the ones most worth a minute of your hands, in Endless Night with a god of that type (choose the type, play the mission with only its two Tier 1 powers), or from the Missions board and its ENDLESS button for the dev fill:

1. **Decree x Tax Collector.** CALL THE GUARD near a door he is in, then Leaving Is Prohibited on the door as he comes out: do the debtors mob him? Is the TAX COLLECTOR - GUARDED tag enough to tell what is missing?
2. **Decree x Harvest.** The law on the carter, then CALL THE GUARD on the same spot: is the 60 s gap between seizures bearable?
3. **Ruin or Death x The Warning.** Kill a man just outside the star's gate while the watchman stares: is the NEXT STAR countdown and the hint enough to time it?
4. **Passage x First Prayers.** Lay a Thornwall by the well as each walker sets out: do the BRAMBLES HIDE THE WELL tag and the DOOR - HIDDEN tag make sense?
5. **Death x First Prayers.** Kill the six Faithful: does THE DOOR STANDS EMPTY - THE POOR HURRY IN read well, and is a 90 to 120 s night too short?
6. **Passage x Lost Lamb.** The north-west dead end: is flinging a patrol there a play you accept?
7. **Veil x Spoiled Harvest.** Blight a full granary with no watchman on guard: are the refusal words (NO GRAIN TO ROT YET, THEIR WATCH KEEPS IT) clear?
8. **The title.** Endless Night from the title (real tree) and from the board (dev fill): both Backs.

## Needs you

- **Pairs reported, not binding.** The Capital's 24 of 30, and the short medians above. Say so if any should be tuned.
- **Passage x Lost Lamb's dead end** (D25) and **Passage x Harvest's 86 s night** (D24): both are final unless you reopen them. For the Lamb the lever is a hard Thornwall rule (a Thornwall also stops a patrol's walk) or a second mirror charge.
- **Passage x Prayers** at 59 s of your 60, with a 1 s margin on seed 1.
- **The copy.** The spec's hint lines are a first draft; every line is tested to fit three lines of `Hud.HINT_W`. The banners are my call.
- **The tunable numbers** (the table above), none moved from the spec except the ones in the Rulings note (Harvest `SEIZE_R`, Prayers first walker and chain).
- **Pushing.** After landing, local `feat/god-progression` holds P2, P3 and this milestone; the local tag is `kak-god-t1r`. Nothing is pushed without your yes; `feat/Develop-Main` is untouched.
- Still open from P1 and P2: the level tables for the first powers, the god names and flavour lines, whether to delete the Missions board, the five real Hunt nights, and whether a clean win should also need no seen death.
