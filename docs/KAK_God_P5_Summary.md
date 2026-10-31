# Kingdoms Amid Kataclysm (KAK) - God Progression P5 Summary

*Engine: Godot 4.7.2. Branch `god/p5-hunts`, landing on `feat/god-progression` (base `f130d4f5`, tag `kak-god-t1r`). P5 is "The Lantern Hunts": the five real Hunts that replace P2's stand-ins, one for each tier (spec §10.2 of the parent spec). Built straight through from 2026-10-29, subagent-driven, in worktrees: 14 build tasks (every one reviewed, most with one or two fix rounds), a landing task (the controller's), this note, an opus milestone review and one fix wave (branch `god/p5-fix`, `54bb9581` plus two small follow-ups from its re-review, `559fb61c` and `e85cafb9`). Mission spec: `docs/superpowers/specs/2026-10-29-kak-god-p5-hunts.md` (cited MS §n). Parent spec: `docs/superpowers/specs/2026-10-26-kak-god-progression-design.md` (cited as section numbers). Plan: `docs/superpowers/plans/2026-10-29-kak-god-progression-p5.md`. Every ruling is in `docs/KAK_God_P5_Rulings.md`. Earlier phases: `docs/KAK_God_P1_Summary.md`, `docs/KAK_God_P2_Summary.md`, `docs/KAK_God_P3_Summary.md` and `docs/KAK_God_T1_Routes_Summary.md`.*

## What you asked

When the Lantern Notice reaches 100%, the Lantern sends a Hunt after your god. In P2 that Hunt was a stand-in: an ordinary board mission wearing a Hunt's name. You approved five sketches, eight answers and then, on 2026-10-29, all nine recommended answers to the spec's open issues, and said to run P5 straight through.

P5 builds the five real Hunts. Each is its own mission with its own people and its own places in Aldermere. Each has one rule that only a Hunt has: **the Lantern comes for your own people.** Win a Hunt and the Notice drops to 0%, you get Faith and the night counts as normal. Lose or abandon one and your most-used ability is sealed for 3 nights and the Notice is set to 50%. Those results are P2's, unchanged. Eclipse is not part of P5 (your answer 8).

## What P5 adds

### The five Hunts (MS §1-§6)

| Tier | Hunt | Built on | Its own rule | Clock | Bell |
|---|---|---|---|---|---|
| 1 Whisper | **Hide the faithful** | the Escort type (many people to lead) | The Inquisition searches house by house | 5:00 | the toll turns the Lantern |
| 2 Omen | **Silence the witness** | Bell Ringers and the Intercept type | Only the witness's own mates carry the word on | 5:30 | the toll turns the Lantern |
| 3 Wrath | **Expel the inquisitor** | the Assassinate type | Three frights drive the captain out | 6:00 | the toll turns the Lantern |
| 4 Reckoning | **Break the hunt** | the Hunt type | The standards march, and an escort takes one up | 6:30 | the toll turns the Lantern |
| 5 Ascendance | **Face Halcyon** | the Escort type, run backwards, with its own Gaze | A believer is freed the moment his escort breaks | 7:00 | the toll adds 40 to the Gaze |

"The toll turns the Lantern" is the rule from P3: the bell never loses a night outright. It speeds the clock and the Lantern's flame. A Hunt is played only at its own tier, so a Tier 2 god meets Hunt 2 and nobody else.

### What all five share
- **The draw.** `GodNight.hunt_for()` returns your tier's own Hunt. The stand-ins are gone from the god's nights. They stay on the Missions board as ordinary missions, with all their references, untouched (your answer 5).
- **The data.** A new `HuntBook` (`src/game/god/hunt_book.gd`) holds the five rows: tier, id, title and the plate P2 already wrote. Each Hunt's frame is a `MissionBook` function built on its tier's frame. The Hunt is dressed with your slots, Might, draft pool and gifts, and the clock is the tier's clock plus the Faith clock.
- **The save.** A game closed in the middle of a Hunt reads back as a lost Hunt. No new save key. `VERSION` stays 1.
- **Results and stakes.** Unchanged from P2. Won: Notice 0%, `50 x tier` Faith. Lost: the seal and Notice 50%.
- **The Descent stays** (your issue 4). A Hunt hears the tier's wishes, banks believers and has the ASCEND phase. A test proves no wish ever lands on one of the Hunt's own people.
- **Screens.** Prepare's Hunt rows, the hub's Hunt line and the pause stake are P2's. WIN and LOSE now read the real Hunt's text, and each fits (proved at tiers 1-5).
- **Results titles.** A won Hunt no longer says THE CITY HAS FALLEN, and a lost one no longer says MANIFESTATION ENDED. The ten new titles are in the table under Hunt 1-5 below. Dawn and the Gaze keep theirs.
- **The DEV tab.** The five Hunts are a second row of small cards under the first row. The first row is unchanged: the sandbox, the towns' missions and the rite last. Each card is the title, or `<title> (Hunt)` where that fits in two lines. Up and Down cross between the rows, and the hint says so. Every power is open on the board.
- **The rules every Hunt passes** (MS §0, the lessons you set after P3): nothing waits more than 60 s; doing nothing loses; no success or loss depends on street traffic; the Hunt's own people are held through an evacuation; anyone whose death loses is tagged DO NOT KILL; every sudden loss is warned with a countdown; the winning strike can never also lose; the guards of one target stand more than 1.6 apart, so one Silent Doom never takes two. The last rule took the most work (see Rulings).

### Hunt 1: Hide the faithful (Tier 1)
*"Lead your believers out before the inquisitors reach them."* Two households of three believers each. Five of the six must get out of the walls.

| Part | Rule |
|---|---|
| Households | North-west household out at 0:15. The north household comes out at the soonest of 2:20, 45 s after the first household is done, or 30 s before the search would reach its house. |
| The walk | Out, a household walks itself in file behind its lamp-bearer, at pace 0.40 (tuned from 0.45), past fear. A Mind Whisper sends a man where you choose. A believer anywhere outside the walls is out, even set down there by a Mirrorfold. |
| The watch | 4 soldiers at the two gates and two patrols of two, walking 2.0 apart. They seize on sight (2.5 units). They are not replaced. The Bell Lies' CALL THE GUARD answers them. |
| The search | 2 inquisitors visit 6 houses in a fixed order, 6 s at each door, walking in file. Each listed house has a countdown. At an emptied household's house they take up its trail. A felled inquisitor is replaced 30 s later, at most twice. |
| Seized | Marched to the Temple. If he gets there he is lost. The seizer felled, frightened or held lets him go. Two lost believers lose the Hunt. After the first loss every believer's tag adds DO NOT KILL. |
| Titles | Won: THE FAITHFUL ARE HIDDEN. Lost: THE INQUISITION TAKES THEM. |

### Hunt 2: Silence the witness (Tier 2)
*"Stop the runner carrying word of you to the Lantern."* Four witnesses, one from each district, each with two mates.

| Part | Rule |
|---|---|
| Setting out | West, north-east, south-west, south-east, at 0:20, 1:15, 2:10 and 3:05, or 45 s after the witness before is stopped, or at once when a loud power lands near a waiting house. |
| The walk | The witness walks for the Temple's door. His mates walk in file, 1.6 behind and 1.0 ahead of him, at twice his pace. Walks measure 21-34 s. |
| The rule | If one of his own mates sees him die, that mate runs on as the witness (`THE MATE RUNS ON`). Seen by anyone else, the word dies with him. The town never carries it. |
| Stopped | Dead with no mate to carry on, or out of the walls. Four stopped wins. |
| Lose | A witness reaches the Temple's door. Warned by his tag, a strip row and a banner. He never rings the bell, and a living bellkeeper can neither lose nor ring for him. |
| Titles | Won: THE WITNESSES ARE SILENT. Lost: WORD REACHES THE TEMPLE. |

### Hunt 3: Expel the inquisitor (Tier 3)
*"Drive out or kill the Lantern's captain in the town."* Three lantern-wardens, then the captain.

| Part | Rule |
|---|---|
| Wardens | Three, each with one soldier guard, each walking a looping round of four stops. They set out at 0:44, 1:34 and 2:24 (tuned from 0:20, 1:10, 2:00), or 45 s after the warden before is stopped. A warden has no safe place. |
| The captain | At 3:10, or 45 s after the third warden. Two guards walk behind him in file. He visits four stops (the bell tower, the market's south end, the Main Gate's plaza, the far south-east house), then a street point north of the Temple, then the Citadel's gate. |
| The rule | Each alarm on the captain counts as one fright, at most one per 8 s. The first two send him to hide for 12 s. The third makes him flee Aldermere and he is stopped at once. A route for gods without a killing power. |
| Lose | The captain reaches the Citadel's gate. The countdown first shows 46-63 s out. |
| Titles | Won: THE INQUISITOR IS GONE. Lost: THE CAPTAIN REACHES THE CITADEL. |

### Hunt 4: Break the hunt (Tier 4)
*"Smash their standards before they reach your believers."* Four standards march on three believers' houses.

| Part | Rule |
|---|---|
| Bearers | Four, one at each of four musters, each with two escorts walking in file 1.3 ahead of and behind him. Raised at 0:20, 1:10, 2:00 and 2:50, or 45 s after the standard before is broken. A fallen escort is not replaced. |
| The march | To the nearest house nobody else is marching on, at 0.5 units a second, never faster than a 50 s walk. |
| The rule | Unguarded, a bearer's death or fright breaks the standard. While an escort stands by him, a bearer who dies is replaced: the escort takes the standard up and marches on (`THE STANDARD IS TAKEN UP`). A frightened bearer who is still guarded keeps the standard and only shakes (P5-L-R2). A bearer out of the walls breaks it. |
| Taken | A bearer at a house's door plants the standard. The house is taken, and the bearer stays planted and breakable. Two houses taken lose. |
| Titles | Won: THE STANDARDS ARE BROKEN. Lost: THE HUNT TAKES THEIR HOUSES. |

### Hunt 5: Face Halcyon (Tier 5)
*"His Gaze is on the whole town, and a seen death fills it."* Four believers are led to the pyre before the Temple. Free three.

| Part | Rule |
|---|---|
| Processions | One from each district, forming up at 0:44, 1:49, 2:54 and 3:59 (tuned from 0:30, 1:35, 2:40, 3:45), or 45 s after the one before is freed or burned. Each forms for 8 s in its doorway, then walks to the pyre (walks of 28-33 s). A believer is bound and cannot be frightened. His three soldier escorts walk in file. |
| The rule | The believer is freed the moment fewer than 2 of his escort are able: alive, outdoors, close to him, not held, not frightened, not weakened by you. He runs off and is counted. A believer outside the walls is freed too. |
| The pyre | At the stake he burns for 12 s unless freed. A believer you kill counts as burned. Two burned lose. |
| The Gaze | The Hunt keeps its own Gaze: a seen death adds 10 of 100, a bell toll adds 40. Full loses. Believers read DO NOT KILL from the start. |
| Titles | Won: THE PYRE STAYS COLD. Lost: THE PYRE BURNS. |

### Tools and tests
- **`tools/dev/hunt_gate.sh`** runs one Hunt's gate for one type: `bash tools/dev/hunt_gate.sh --only=<id> --type=<type> [--with-none] --save=<dir> --jobs=2`. Then `--judge=<dir>` reads the six saved types and prints the table and a line such as `hunt_gate <id> tier=N pass=K/6 none_lost=K/3 median=S PASS|FAIL`. `--except=decree` is allowed on Hunts 2-4 only. After the fix wave `--judge` only trusts a gate line with `route=god:<that type>`.
- **`behaviour_check`** plays each Hunt: `--scenario=<id> --case=none|play --seed=N --god=<type>:<tier> --dev-tree`. It refuses a loadout the god could not hold at that tier, a `--route` on a Hunt, and a `--level` other than 1. The per-type scripted players live in `tools/dev/routes/god_hunts/<id>.gd`.
- **New suites:** `test_hunt_book` (662 checks), `test_hunt_hooks` (15), `test_hunt_tools` (329), `test_hide_faithful` (334), `test_silence_witness` (452), `test_expel_inquisitor` (766), `test_break_hunt` (513), `test_face_halcyon` (318). Counts are from the fix wave's single runs. Changes to P2's `test_god_lantern`, and to `test_results`, `test_board_test_mode`, `test_tier_board`, `test_endless_flow` and `test_mission_hints`, were needed.
- **References:** 403 rows became 508. The 105 new rows are 21 for each Hunt: `<id>_none_1..3` and `<id>_<type>_play_1..3` for the six types, in five commented blocks at the end of `tools/dev/refs/references.tsv`. A losing run is recorded as it falls. No older row, no `digest` and no `crowd_check` moved at any task.
- **The three base directors** (Exodus, Ringer, Bell Ringers) gained same-valued `tune_` variables, so a Hunt can change a number without touching the base. By default they are byte-identical. Their references were rerun and did not move. The Escort, Warning, Assassinate and Hunt directors were not touched.
- **FLOW's Lantern walk** now plays the real Hunt 1 and loses it through the real ending.

## How to see it

1. **The DEV path.** Run with `--dev` (`& $godot --path . --scene res://scenes/game.tscn -- --dev`), open the Missions board and the DEV tab. Press Down from the first row to reach the five Hunt cards. Enter plays one with every power open.
2. **As a god.** A god of the tier, with the Lantern Notice at 100%, meets its tier's Hunt when it presses Descend (or Awaken). Prepare shows HUNT, WIN, LOSE, IF WON and IF LOST.
3. **The scripted player:** `bash tools/dev/hunt_gate.sh --only=hide_faithful --type=ruin --with-none --save=<dir> --jobs=2`, then the other five types, then `--judge=<dir>`. The five ids are `hide_faithful`, `silence_witness`, `expel_inquisitor`, `break_hunt` and `face_halcyon`.
4. **Photographs:** `tools/capture.sh --show=<name>` with the names in the table below.

## The numbers in play

| Number | Value | |
|---|---|---|
| Hunts, tiers, believers' counts | 5, one per tier; Hunt 1 six believers (five needed), Hunt 2 four witnesses, Hunt 3 three wardens and a captain, Hunt 4 four standards and three houses, Hunt 5 four processions (three needed) | exact |
| The chain | 45 s: the next item comes at its time, or 45 s after the one before is done | exact (a rule) |
| Opposition spacing | more than 1.6 between guards of one target, always at a stop; on a walk, at most 5% of all steps under 1.6 | exact (a rule) |
| Hunt 1 | out at 0:15 and 2:20; believer pace 0.40; search stop 6 s; patrol gap 2.0 | 0:15 spec; 2:20 and 0.40 *tuned* |
| Hunt 2 | out at 0:20, 1:15, 2:10, 3:05; pace 0.65; pause 3 s | spec |
| Hunt 3 | wardens at 0:44, 1:34, 2:24; captain at 3:10; visit 6 s; hide 12 s; fright gap 8 s | 0:44 set *tuned*; rest spec |
| Hunt 4 | bearers at 0:20, 1:10, 2:00, 2:50; pace 0.5; march at least 50 s; guard reach 1.5 | spec |
| Hunt 5 | forming at 0:44, 1:49, 2:54, 3:59; form 8 s; burn 12 s; 3 escorts, free below 2 | set *tuned*; rest spec |
| Gaze | +10 a seen death, +40 a toll | exact (not a knob) |
| Save format | unchanged (`VERSION` 1) | exact |

Four numbers were moved from the spec. Each carries a comment with the round and the figures that moved it: Hunt 1's second household 1:50 to 2:20 and believer pace 0.45 to 0.40; Hunt 3's warden times; Hunt 5's procession times. The first two Hunt 1 moves and the Hunt 3 and 5 schedules are the "harder" levers you allowed (P5-C10). The pooled medians were under 180 s without them.

## Every type against every Hunt

The bar (MS §7): each type wins at least 2 of 3 seeds with its longest stretch without a cast ("idle") at most 45 s; none (casting nothing) loses on all 3 seeds; the Hunt's pooled median of every winning run is 180-240 s. A type's own median is reported but not judged. No type casts only to end an idle stretch (D38), and every Hunt has a test that proves it by mutation. Each Hunt below lists the loadout as the spec's "Plays": at most 3 keys, level 1, within the tier's Might.

### Hunt 1: Hide the faithful

`hunt_gate hide_faithful tier=1 pass=0/6 none_lost=3/3 median=186 FAIL`. Doing nothing loses at 50-52 s. This is the fix round's gate (task 9), after the inquisitors were made to walk in file.

| Type | Plays | Wins | Median | Idle max | Verdict |
|---|---|---|---|---|---|
| Ruin | Smite, Ember | 3/3 (204, 188, 172 s) | 188 s | **133 s** | misses on idle |
| Death | Death Mark, Pestilence | **0/3** (lost at 176, 107, 60 s) | - | 94 s | misses |
| Veil | Silent Doom, Blight | 3/3 (197, 193, 167 s) | 193 s | **91 s** | misses on idle |
| Passage | Thornwall, Mirrorfold | 3/3 (75, 74, 73 s) | 74 s | 54 s | passes only under P5-T11-R2 (Mirrorfold cooldown) |
| Decree | Leaving Is Prohibited, The Bell Lies | **0/3** (lost at 137, 142, 102 s) | - | 26 s | misses |
| Dominion | Mind Whisper, Discord | 3/3 (185, 197, 190 s) | 190 s | **60 s** (43, 52, 60) | misses on idle |

The pooled median of 186 includes Passage's three wins at 73-75 s. This Hunt is delivered **with concerns**. The cause is the shape of the night: a type that kills clears the whole watch by 80-90 s, and the second household still sets out at a fixed 2:20 with nothing left to answer. Death and Decree also lose outright. The fix is on paper (needs you, 2 and 4).

### Hunt 2: Silence the witness

`hunt_gate silence_witness tier=2 pass=5/5 none_lost=3/3 median=193 excepted=decree PASS`. Doing nothing loses on all three seeds.

| Type | Plays | Wins | Median | Idle max | Verdict |
|---|---|---|---|---|---|
| Ruin | Smite, Heaven Splitter, Tornado | 3/3 | 88 s | 23 s | pass |
| Death | Death Mark, Pestilence, Glacial | 3/3 | 145 s | 34 s | pass |
| Veil | Silent Doom, Blight, Tsunami | 3/3 | 193 s | 44 s | pass |
| Passage | Thornwall, Mirrorfold | 3/3 | 202 s | 40 s | pass |
| Decree | Leaving Is Prohibited, The Bell Lies, Magnify | 0/3 (lost at 99, 95, 97 s) | - | 20 s | known gap, left out of the judged line (C9) |
| Dominion | Mind Whisper, Discord, Madness Bloom | 3/3 | 216 s | 40 s | pass |

Most types open with a cast on a mate and finish at least 9.5 s later, which is what keeps idle under 45 s without filler casts. One house order change moved this Hunt easier (P5-T10-R1, needs you, 7).

### Hunt 3: Expel the inquisitor

`hunt_gate expel_inquisitor tier=3 pass=4/5 none_lost=3/3 median=181 excepted=decree FAIL`. The FAIL is Passage's idle of 54 s only. Doing nothing: the captain reaches the Citadel at 306-319 s of 360.

| Type | Plays | Wins | Median | Idle max | Verdict |
|---|---|---|---|---|---|
| Ruin | Smite, Heaven Splitter, Tornado | 3/3 | 160 s | 33 s | pass |
| Death | Death Mark, Pestilence, Glacial | 3/3 | 140 s | 44 s | pass |
| Veil | Silent Doom, Blight, Nuclear Nova | 3/3 | 181 s | 39 s | pass |
| Passage | Thornwall, Mirrorfold | 3/3 | 209 s | 54 s | idle is the Mirrorfold's cooldown (P5-T11-R2) |
| Decree | Leaving Is Prohibited, The Bell Lies, Magnify | 0/3 (dawn) | - | 190 s | known gap, left out of the judged line (C9) |
| Dominion | Mind Whisper, Discord, Madness Bloom | 3/3 | 222 s | 39 s | pass |

The pooled median of 181 sits only just inside the band. A first warden at 0:43 would drop it under 180.

### Hunt 4: Break the hunt

`hunt_gate break_hunt tier=4 pass=3/5 none_lost=3/3 median=184 excepted=decree FAIL`. Doing nothing: two houses are taken at 118 s. No number was tuned in this Hunt.

| Type | Plays | Wins | Median | Idle max | Verdict |
|---|---|---|---|---|---|
| Ruin | Smite, Heaven Splitter, Orbital Strike | 3/3 | 123 s | 22 s | pass |
| Death | Death Mark, Pestilence, Glacial | 3/3 | 211 s | 20 s | pass |
| Veil | Silent Doom, Blight, Nuclear Nova | 3/3 | 177 s | 24 s | pass |
| Passage | Thornwall, Mirrorfold | 3/3 | 184 s | 54 s | idle is the Mirrorfold's cooldown (P5-T11-R2) |
| Decree | Leaving Is Prohibited, The Bell Lies, Magnify | 0/3 (houses at 118 s) | - | 20 s | known gap, left out of the judged line (C9) |
| Dominion | Mind Whisper, Discord, Turncoat | 3/3 | 297 s | **113 s** | misses on idle (needs you, 5) |

### Hunt 5: Face Halcyon

`hunt_gate face_halcyon tier=5 pass=5/6 none_lost=3/3 median=165 FAIL`. Doing nothing: two believers burn at 163 s. Decree is judged here, because CALL THE GUARD works on soldier escorts.

| Type | Plays | Wins | Median | Idle max | Verdict |
|---|---|---|---|---|---|
| Ruin | Smite, Ember, Heaven Splitter | 3/3 | 186 s | 45 s | pass (wins hang on the Gaze budget) |
| Death | Death Mark, Pestilence, Glacial | 3/3 | 194 s | 45 s | pass |
| Veil | Silent Doom, Blight, Tsunami | 3/3 | 196 s | 45 s | pass |
| Passage | Thornwall, Mirrorfold | 3/3 | 165 s | 54 s | idle is the Mirrorfold's cooldown (P5-T11-R2) |
| Decree | Leaving Is Prohibited, The Bell Lies, Magnify | 3/3 | 134 s | 45 s | pass |
| Dominion | Mind Whisper, Discord, Rewrite Priority | 3/3 | 136 s | 45 s | pass |

The pooled median of 165 is **under** the 180 s floor. Decree, Dominion and Passage free a procession with one cast the moment it forms, so the 45 s chain sets their time at 134-136 s. Three tuning rounds could not lift it (needs you, 6).

### Tuning, in short
- **Hunt 1:** round 1 moved the second household to 2:20 and the believer pace to 0.40 (the median went from about 160 to 189). Round 2 was policy only. A third round (a relief pair when the watch empties) dropped the gate from 4/6 to 2/6 and the controller reverted it. A later director fix (the inquisitors walk in file) then moved the gate to 0/6.
- **Hunt 2:** one round: the house order (west, north-east, south-west, south-east). It made Dominion's idle go from 72-90 to 40, and Death win 3/3.
- **Hunt 3:** round 2 moved the wardens' times to 0:44, 1:34, 2:24. The median went 157 to 181. The other levers (fright gap, hide, visit, guards) were not needed.
- **Hunt 4:** none.
- **Hunt 5:** round 1 pace 0.4 (reverted, no lift and Passage idle 61), round 2 four escorts (reverted, Ruin failed), round 3 the schedule 44/109/174/239 (median 164 to 178). Then the fix round moved Passage's mirror and the median fell to 165.

## Photographs

All were looked at. They are 1280 x 720 and sit in `.superpowers/sdd/godp5/photos-t14/` (the working folder, not the repo). Take them again with `tools/capture.sh --show=<name>`.

| `--show=` name | Shows |
|---|---|
| `board-dev-hunts` | the DEV tab: row 1 unchanged, row 2 the five Hunt cards, one lit, the hint below |
| `prepare-hunt-1` to `prepare-hunt-5` | each Hunt's Prepare at its tier; every row fits |
| `results-hunt-won`, `results-hunt-lost` | THE FAITHFUL ARE HIDDEN and THE INQUISITION TAKES THEM |
| `hide_faithful-start`, `-trail` | the first countdowns and the watch; the search on a household's trail |
| `silence_witness-start`, `-relay` | the first witness tags; THE MATE RUNS ON |
| `expel_inquisitor-start`, `-captain` | the wardens' tags; the captain out, SHAKEN 0/3 |
| `break_hunt-start`, `-taken` | the raise tags; a house taken |
| `face_halcyon-start`, `-pyre` | the pyre and the first procession; a believer burning with its ring |

## Landing

Landing gate, by hand on the milestone tree (`bfecf5ce`: the five Hunts, Task 14 and `feat/god-progression` 1b6ab0b2 merged in). `land.sh`'s trial merge is against Develop-Main and does not apply here.

- **Suite:** 13955 checks, 0 failures.
- **References:** all 508 checked, 508 OK, 0 bad. The 105 new Hunt rows reproduce on the merged tree. `digest` (`61267b7e90524d800bf1c3473a71146b`), `crowd_check` (`-935602679`) and `calm` (`-355092532`) did not move.
- **FLOW:** the gate's two runs gave no result: the known flake under load, since the reference run had just finished. Rerun alone with no other Godot running: `FLOW result checks=209 failures=0`, 250 s. FLOW logs about 620 `Lambda capture at index 0 was freed` errors from `_until` (`game.gd`). They are older than P5: FLOW on `feat/god-progression` 1b6ab0b2 logs 623.
- **Bench vs `kak-god-t1r`** (board versions, median of 3, fps): warning 34.5 / 34.5, miras_house 29.4 / 30.4, vigil_flame 31.3 / 31.2, procession 27.7 / 28.0, last_judgement 28.4 / 28.7. Every pair is within 1 fps. The absolute numbers are low because the machine was busy, so only the pairs count.
- **After the milestone fix wave** (merge `7345b833`): suite 13962 checks, 0 failures. `digest`, `crowd_check` and `calm` OK, and `face_halcyon_none_*` 3/3 OK. The fix wave changed tests, tools, comments and docs only, so no game code changed and FLOW and the bench were not rerun.

## The reviews

- **Per task.** Every task had a review. Tasks 2, 3, 5 and 14 were approved as built (Task 14 with four small notes, taken). The rest came back CHANGES NEEDED, were fixed, and were re-reviewed: Task 1 (a gifts check that could not fail), Task 4 (the two inquisitors stood on top of each other), Task 6 (the captain's last walk warned only 17 s out), Task 7 (escorts bunched on the walk, and a planted company stood on another standard's street), Task 8 (escorts bunched), Task 9 (three rounds, ending in tests only), Task 10 (the house order, Dominion's Discord used as a timer, mates bunched), Task 11 (a Dominion filler, the guards bunched), Task 12 (the whispered file bunched 27% of the time, escorts stood too close at stops, an unproved Dominion claim) and Task 13 (survivors of a fallen escort 1.40 apart, and Passage's idle was not what the report said).
- **Wave 1 taught one lesson.** Every Hunt built in wave 1 first failed the 1.6 spacing on the walk, even though it passed at the stops. After that the rule was written down as a binding test: bodies moving, every step counted, and a mutation that must fail on the old code. Hunts 3 to 5 were checked against it from the start.
- **Milestone review (opus)** of the whole branch: FIX WAVE NEEDED, no critical issue. Four important findings: (1) `for-user.md` was missing rulings and design changes you had approved differently (taken: items 7 to 10 below); (2) Hunts 1 and 2 never got the 45 s warning window that Hunts 3 to 5 were held to (ruled: P5-L-R1); (3) stale comments still described side-by-side formations that the reviews had removed; (4) Hunt 4's guarded fright did not match the spec's text (ruled: P5-L-R2). Nine minors followed.
- **Fix wave (sonnet, no behaviour change, no reference moved):** the stale comments were reworded; `FH_ESCORT_RING` was deleted; `hunt_gate.sh --judge` now checks the route and `--except` only accepts `decree` on Hunts 2-4; `behaviour_check` refuses `--route` and a `--level` other than 1 on a Hunt; Hunt 5's `tune_gate_watch` is 1, not 0; three joined lines got their line breaks back; two P2 test nits were fixed. Its sonnet re-review asked for two tiny follow-ups (a test that anchors on the printed line, and a doc line), both done.

## Known small issues

Left on purpose; each has a short fix or waits for a later pass.

**From the reviews and the rounds:**
- **Hunt 1: two countdowns share a point.** At a waiting household's door `OUT IN` and `SEARCH IN` sit in the same place, and the HUD keeps the first and hides the second. No information is lost (a household always comes out before the search reaches it), but the second tag is not shown. The fix is in `Hud.tag_layout()`: stack a later label above an earlier one.
- **Edge-arrow labels can sit under their own arrow** at the screen's edge (`INQUIS` and an arrow, `PROCESSION IN 3:34` at the left). It is the HUD's general layout. The numbers stay legible.
- **The pyre is a tag, not a picture.** MS §6 said "a stacked pile and a stake"; no plan interface draws one, and there was no PixelLab. Orange tag, the pile outlined, a ring that fills as he burns.
- **Hunt 1's lamp countdown ignores the man's own pace** (it uses the Hunt's pace; real pace varies 10-15%). It is a progress tag and not a loss countdown.
- **Hunts 1 to 3 print no walking-spacing counters** in the scripted state line. Hunts 4 and 5 do. Their 5% figure exists in the stepped-body tests only.
- **Magnify can stretch an escort's steadiness past his TAKEN UP tag** (Hunt 4; needs you, 11).
- **Hunt 5's south-west house keeps only 1.5 from the south-east road.** No gate run forms the fourth procession, so no run walked it (needs you, 8).
- **Several walks are shorter than the spec said.** Hunt 2's witnesses walk 21-34 s (the spec said 35-50 s), Hunt 5's processions 28-33 s (50-64 s). The town's streets do not offer more.
- **Hunt 3's two warden rounds walk the interior,** not along the walls, and the captain's last leg takes the long way round the north wall.
- **The parked minors** of Tasks 3 to 6 and 8 that are not above: a sheltering witness shows its tag late (fixed in Task 10), the captain's countdown ran about 15% short (fixed in Task 11), and the rest are in the task reports.

## What is not yet there

- **Eclipse** (your answer 8). It is its own spec.
- **Re-gates as the tiers fill.** The Hunts were gated with the dev tree at level 1 (your answer 2 and 6). When you fill a tier of the real tree, its Hunt is gated again with the real keys.
- **Decree on Hunts 2 to 4.** No route, by design (needs you, 3).
- **The Hunt 1 pacing redesign** and a decision on Hunt 5's median (needs you, 4 and 6).
- **Rites at levels 20, 30 and 40, more gifts,** and the older P3 and P2 items that are still open.

## Needs you

These are the eleven decisions from the controller's final list. They are exactly what the reports left open. Nothing is blocked on them.

1. **Passage may idle up to 60 s when it is exactly the Mirrorfold's cooldown** (P5-T11-R2, the same kind of allowance as D40). It is the cooldown of 54 s with nothing else in its two keys that has a real use. It applies on Hunts 1, 3, 4 and 5. Accept or reverse.
2. **Decree on Hunt 1** (spec R40). It scored 0/3 after five plays were tried: cages on the pair, the call of the guard, the seizer with his prisoner, and the bell on the gate watch. The inquisitors meet the first household at the crossing 7 units from the Temple, and a seizure there lands in about 10 s. The law confines, it does not hold still, and The Bell Lies takes soldiers only. Accept the gap, or give Decree a rule change (for example, the law holds lay inquisitors still).
3. **Decree on Hunts 2 to 4** (C9, open issue 1). It has no route and is left out of the judged lines on those three Hunts. Confirm.
4. **Hunt 1's pacing** (a proposal on paper, not built). The empty stretch is the shape of the night. A killing type clears the whole watch by about 80-90 s, and the second household still sets out at its fixed 2:20 and walks about 59 s with nothing left to answer (Ruin idle 133, Veil 91, Death 120 before the pair fix). Proposal: the second household sets out when the first is safe or lost plus the 45 s chain, or at once when no inquisitor stands (`THE WATCH IS BROKEN - THE SECOND HOUSEHOLD SETS OUT`), whichever comes first. The fixed 2:20 stays as the latest time. Expected: killing types finish about 40-60 s sooner, so the pooled median would fall under 180 and the change would be paired with a slower believer pace or a later first household. The alternative that was tried (a relief pair when the watch empties, P5-T9-R5) failed: the gate went from 4/6 to 2/6 because the pair came too late. Death 0/3 and Dominion's idle need a fresh look after the pacing.
5. **Hunt 4's Dominion idle of 113 s** (P5-T12-R4). It is structural for the spec's loadout (Mind Whisper, Discord, Turncoat): whispered bearers walk out slowly. The evidence for another loadout (Whisper, Madness Bloom and Discord) is that it wins at 131, 131 and 175 s with idle 49-57, which is still over 45, and the pooled median would fall to 176.7. Keep the miss, or change the loadout or the bearers' whispered pace.
6. **Hunt 5's median of 165.** Decree, Dominion and Passage free a procession with one cast at forming, and the 45 s chain sets them at 134-136 s (Passage 165 with its mirror at the nearest clear spot). Three rounds were spent: pace 0.4, four escorts, and the schedule shift to 44/109/174/239. Accept, or make a design change (for example, a freed procession's next one forms on the clock and not on the chain, or one cast cannot free a procession of three).
7. **Accepted by the controller and disclosed. Reverse any you disagree with.**
   - P5-T7-R8: a bearer's take-up is judged from the look before the blow.
   - P5-T10-R1: Hunt 2's house order was changed, in the easier direction.
   - `EI_WARDEN_AT` 44/94/144 (P5-T11-R1) and `FH_PROC_AT` 44/109/174/239 (P5-T13-R9) as "harder" schedule levers.
   - Held real casts: the `FH_GAP` 20 s hold on Hunt 5, and Dominion's Discord on Hunt 2.
   - Early real casts made to meet the idle bar: Hunt 3's `RUIN_PREP_LEAD` 24, Hunt 4's `BH_PREP` 24, Hunt 2's `SW_PREP` 25. These are real kills or moves, cast early so that the next cast is not 50 s away.
   - Hunt 1's idle-triggered kills (P5-T9-R9): Ruin, Death and Veil strike a gate watchman up to 70 s early once 30 s (38 s for the last) pass without a cast, and Veil accepts a seen kill after 38 s. The trigger is the idle clock itself.
   - Pair dips at turns up to 5% of walk steps (P5-T11-R9).
   - Dips caused by the player's own powers are exempt (P5-T12-R5).
8. **Changed from the approved sketches. Reverse any.**
   - **Formations: every company now walks in file** (P5-T7-R10, P5-T8 fix, P5-T10-R3/R4/R5, P5-T11-R8), because side-by-side and ring formations broke the 1.6 rule on the walk. Hunt 2: mates 1.6 behind and 1.0 ahead of the witness (the `MATE_SIDE` lever is retired, P5-T10-R5). Hunt 3: the captain's guards behind him at 0.9 and 3.3. Hunt 4: escorts 1.3 ahead and behind (planted posts 2.6 apart). Hunt 5: lead 1.4 ahead, two behind at 1.8 and 4.4. The spec's §3, R21 and §7 were edited to match after your approval.
   - **Geometry the town could not give.** Hunt 3: two of three warden rounds walk the interior, not the walls, and the captain's last leg goes the long way round the north wall (P5-T6-R1). Hunt 4: house 2 was replaced (P5-T7-R9), and the south-west muster was moved out of a walled yard. Hunt 5: three of four house points moved (P5-T8-R2/R5), and its walks are 28-33 s, about half the spec's 50-64 s.
   - **P5-T8-R7, an exception to the opposition rule.** Face Halcyon's south-west house keeps only 1.5 (not 2.7) from the south-east road, so one power may reach two companies there. No gate run forms that procession, so the overlap log says nothing about it.
   - **Tuning moves.** Hunt 1: `HF_OUT_AT[1]` 110 to 140 and `HF_BELIEVER_PACE` 0.45 to 0.40 (P5-C10). Hunt 4: the 50 s march floor (P5-T7-R3) makes the pace lever inert on short routes (the south-west standard crawls at about 0.22 units a second), and the `guard_reach` 1.5 to 1.2 lever is unusable with the 1.3 file.
9. **The warning window on Hunts 1 and 2** (P5-L-R1). Hunts 3 to 5 are held to "every sudden loss is warned at least 45 s out"; Hunts 1 and 2 were built before that rule. Hunt 1's second seizure can lose with about 10 s of warning (the seized man's tag and a banner, no strip row; the spec said 20-30 s). It is folded into the Hunt 1 pacing redesign (item 4): march a seized believer at least 20 s, or add a strip row "A believer reaches the Temple". Hunt 2's `WITNESS - TEMPLE IN` first shows 19-31 s out, but the house's `WITNESS OUT IN` tag (up to 55 s) comes first, so the window starts there; accepted by the controller. No code change now, because it would move Hunt 1's 21 rows.
10. **Hunt 4's guarded fright** (P5-L-R2). The spec says a guarded bearer's death or fright passes the standard to an escort. The code passes it only on a death. A frightened, guarded bearer keeps the standard and runs off with it ("a guarded fright only shakes"). Ruled to stand, and the doc was reworded. Reversing it moves Hunt 4's 21 rows.
11. **A small hidden state (a follow-up).** Decree's Magnify on a steadied escort can stretch his steadiness past his `TAKEN UP` tag (Hunt 4). One line to fix here, or a clamp later.

Also still yours, as in P3:
- **The copy.** The spec's quoted strings are exact. Every banner, tag, hint and results title beyond them is my call.
- **Pushing.** After landing, local `feat/god-progression` holds P5 and its tag `kak-god-p5`. Nothing is pushed without your yes, and `feat/Develop-Main` is untouched.
- Still open from P3 and P2: Passage's fast clear on The First Taste (C11, accepted), the title switch to Endless Night, the level tables for the first powers, the god names and flavour lines.
