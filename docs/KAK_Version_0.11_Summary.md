# Kingdoms Amid Kataclysm (KAK) — Version 0.11 Summary

*Engine: Godot 4.7.2 (gl_compatibility, 640×360 pixel art, iso view). Branch `claude/lantern-campaign-spec` (from the v0.10 line plus the v0.09.1 board-tag work at `92e0dcc`). v0.11 is **The Tiers**: the board of single missions becomes the god's five Awakening Tiers, each night hears the town's wishes, ends in an ascent and pays believers that buy the god's upgrades. It is built in milestones: M1 the framework, then M2-M6 one tier at a time (25 missions in all). Design: `docs/superpowers/specs/2026-10-08-kak-v011-tiers-design.md`. Plan: `docs/superpowers/plans/2026-10-08-kak-v011-m1-framework.md`. M2 (Whisper): Tier 1's four new missions; mission spec `docs/superpowers/specs/2026-10-08-kak-v011-m2-whisper-missions.md`, plan `docs/superpowers/plans/2026-10-08-kak-v011-m2-whisper.md`.*

## M2: Whisper

M2 completes Tier 1. Whisper has five missions: The Warning and four new ones, each a night of 5:00 in an Unaware town, 3 slots and 6 DP (plus the upgrades), two wishes and ×1 believers. It adds two new mission types (Assassinate and Escort), generalises two (Raze and Convert), adds two wishes, and carries two items over from M1's final review. It adds no art: the old well shrine is Broken Lanterns' drawn shrine post, the collectors wear the noble's cape and crown, and every other stand-in is an existing building or person named by a map tag. Mission spec: `docs/superpowers/specs/2026-10-08-kak-v011-m2-whisper-missions.md`.

### Whisper's five

| Mission | Card type | Main objective | The twist |
|---|---|---|---|
| The Warning | Intercept | Stop all three warnings | Three stars, each sending a runner; a later star falls sooner once the one before is stopped |
| The Tax Collector | Kill | Kill the tax collector and his two deputies | They are indoors until their time and hide when alarmed; a kill anyone sees raises the cry of murder and calls the bellkeeper; one reaching the Citadel's gate loses the night |
| Spoiled Harvest | Destroy | Spoil three granaries (burned 10 s in all, or brought down) | A granary has nothing to spoil until its grain arrives; two watchmen beat out its fire while they stand; carts empty it one load at a time |
| The Lost Lamb | Protect | Lead a runaway acolyte out through the west gate | He moves only by Mind Whisper; any soldier who sees him seizes him and marches him back to the Temple; the gate's watch changes, and at 2:30 the Temple sends searchers |
| First Prayers | Cult | Three of the poor pray at the old well shrine and come out Believers, unseen | One prays at a time for 32 s; a Faithful who sees someone go in turns them away and runs to report it; the Gaze fills |

**Tier 2 now opens at three cleared.** Tier 1 has five missions, so Omen takes the full rule of three; M1's "all of them, until M6" no longer applies to Whisper. A tier never closes: a save that opened Omen on The Warning alone (an M1 save) keeps it open, and a test pins that. A **v0.10 carry-over** now reads Whisper 1 / 3 with Omen locked ("Clear 3 Whisper missions"): its won Warning counts as one of the three, and it no longer opens Omen by itself.

### The new types

- **Assassinate** (`AssassinateDirector`, for N targets). Each target starts indoors at a hideout, untouchable, and sets out at his own time or a short chain wait after the one before him dies, whichever is sooner. On his round he walks to each of his debtors' doors, goes in for a while, then walks on, and after the last he makes for his safe place, which loses the night. A few soldiers walk with him, inside Silent Doom's reach. A loud power near him, a guard falling or a fright sends him to hide in his hideout for 30 s; a fire there, or its fall, flushes him out (only those out or hiding, never those still waiting to set out); with the hideout gone an alarm sends him running for his safe place. A power cast at the hideout's door while none is out smokes the next one out at once. Each death is judged as the Prince's is: if anyone living stands within 2 units, the guards cry murder and the bellkeeper is called. On the board the bell tolling after that catches the night and loses the wishes, unless the god ascends or stops the bellkeeper first. The Tax Collector's three collectors (the tax collector and two deputies, the three residents nearest the counting-house, made nobles) walk their own debtors from the counting-house, the workshop hall; later tiers' The Informer and The Bishop can reuse the director.
- **Escort** (`EscortDirector`, one charge). The charge (the acolyte, the cleric nearest the north-east fountain) moves only by the god's hand, a Mind Whisper or a Will-o'-Wisp's lure, and holds where he is left. Soldiers set to watch for him seize him on sight within 2.5 units and march him back to the Temple's door: the gate's watch, two patrols, and from 2:30 two searchers. A seizer under Discord or a whisper, a turned one, and one the town has taken (the rally, a marshal's post, a fight) sees nothing. Felling the seizer, or turning him, or a town order taking him off the errand, frees the acolyte. The watch changes 30 s after he first comes within 6 units of the gate (away 25 s, then every 45 s), so the wait starts when the player engages. The way out is the Main Gate, on the lower-left wall on screen. However the crowd carries him off, a gate he fled to included, counts as his escape.
- **Raze, generalised** (`RazeDirector`, targets and a spoil time; Spoiled Harvest is `HarvestDirector`). The base keeps an optional seal, a target that only shakes and smothers its fire, which no mission uses: Spoiled Harvest's granaries are not sealed but empty until their grain arrives (fire on an empty one is put out at once and counts for nothing), and each has two watchmen who beat out its fire after 3 s while they stand out of doors, at their posts and calm. The god must remove every watchman, then keep the fire burning 10 s in all, or bring the granary down. A watchman who left his post calm is sent back after 20 s; a fallen one is replaced after 30 s, so clearing a granary long before its grain is undone. The carts: the moment a granary's grain is in, its carter sets out from the Citadel's gate and takes a load at the granary, again and again; five loads empty it, and the first granary emptied loses the night. Last Judgement's and Judgement's directors are left as they are, so their references hold.
- **Convert, generalised** (`MirasHouseDirector`, with `FirstPrayersDirector` its subclass). The Mira's House director gains three numbers, `need`, `read_seconds` and `one_at_a_time` (defaults 4, 8 and false), and two label hooks; Mira's House plays exactly as before. First Prayers needs 3, prayers last 32 s and only one prays at a time. The old well shrine is a drawn stone shrine post (`Structure.Kind.SHRINE`) at the market's west edge, which cannot be destroyed (a blow only shakes it); a poor citizen led to its door goes down the well's steps and prays hidden. With few Faithful (3 clergy and 3 lay citizens, no Inquisitor), the market fills at 1:15 and the priests come at 2:30, each putting a line of Faithful at the door for 40 s. At dawn the post stands and a prayer in progress ends a Believer; the shrine's tag counts the prayer down ("PRAYING 21").

### Each mission's timeline

- **The Tax Collector:** 0:45 the tax collector sets out (sooner if smoked out); the deputies at 1:45 and 2:45, or 45 s after the one before dies; each collects 15 s at each debtor, then makes for the Citadel; left alone the first is there at about 2:25 and the night is lost. Longest wait: 45 s, at the start and between a death and the next setting out.
- **Spoiled Harvest:** grain arrives at 1:00, 2:00 and 3:00, or 45 s after the granary before is spoiled; left alone the first granary is emptied between 3:10 and 3:45. Longest wait: 60 s to the first grain, with its watchmen to deal with meanwhile (the longest stretch with nothing to do is 40 s).
- **The Lost Lamb:** he hides by the north-east fountain with the patrols on their beats; the watch changes 30 s after he first nears the gate; the searchers set out at 2:30; left alone he is taken back at about 2:55. Longest wait: 30 s, at the gate.
- **First Prayers:** the market fills at 1:15 and the priests come at 2:30; doing nothing loses at dawn, 5:00, with too few believing. Longest waits: 40 s (the Faithful at the door, which Discord or a lure can cut short) and 32 s (one praying before the next).

No timed wait passes 60 s, and a test pins every one. The tuning numbers, as shipped:

| Mission | Numbers |
|---|---|
| The Tax Collector | set out 0:45 / 1:45 / 2:45, chain wait 45 s, 15 s indoors at a debtor, hide 30 s, alarm reach 4, guards 2 / 1 / 1 |
| Spoiled Harvest | grain 1:00 / 2:00 / 3:00, chain 45 s, spoil 10 s, 5 loads, 2 watchmen a granary, smother after 3 s, return 20 s, relief 30 s |
| The Lost Lamb | pace 0.385 of a walk, sight 2.5, searchers at 2:30, watch change 30 s, away 25 s, cycle 45 s |
| First Prayers | prayer 32 s, market 1:15, priests 2:30 (40 s each), 3 clergy and 3 lay Faithful, 3 must pray |

### The wishes

The pool grows from 8 to 10. Both new wishes may be heard in an Unaware town.

| Wish | Kind | Act | Reward | Needs / clashes |
|---|---|---|---|---|
| Stop the bailiff | Rescue | Once engaged (as Save my child is: a click on his or the home's tag, or a cast within 2 units of either), the bailiff walks from his post to the wisher's home. Kill him, turn him, or keep him from the door for 50 s | 15 | a lay citizen with a home, and a free soldier at least 20 units from its door with no more than 40 units of street to it; no clash |
| Let my neighbours believe | Faith | Whisper three of the wisher's neighbours (marked) to within 2 units of the wisher; each one believes | 10 | three lay citizens living within 8 of the wisher's home, not of the household, each with a route to the wisher; no clash |

- **The bailiff** fails when he reaches the door. The 50 s is only a cap: he starts at least 20 units away with at most 40 units of street to walk, which is about 16 s after a click (the median of sixteen seeded towns) and 24 s at the slowest of twenty-four, so the HUD shows the act ("Stop the bailiff before he reaches the door") and no countdown. His route is bounded as well as his distance, because with the distance alone one seeded town sent him 67 units round the streets, 50 s, and the cap would have granted the wish for doing nothing.
- **Let my neighbours believe** fails when a neighbour dies before believing.
- **Strike down the cruel tax collector** now clashes with `hunts_tax_collector`, which The Tax Collector declares, so it is never heard on that night.

### The carried items

- **FIGHT turns a soldier.** A soldier turned by a fight power (Turncoat, Manufactured Hatred) is the god's own doing, so `RescueWish.TURNED` gains `Person.Mind.FIGHT`: Save my child is granted, and Stop the bailiff uses the same list.
- **The Warning's tour says "by".** Its later stars can fall sooner, so the tour reads "The Main Gate. A star falls here by 1:30." and "The Side Gate. A star falls here by 3:00."; the first star still reads "at 0:10".

### References

Each mission's scenario is `--scenario=tax|harvest|lamb|prayers --case=none|play [--seed=N] [--board]`; it runs the `MissionBook` version (the same director, clock and town, no wishes), so its checksums are exact references. `--board` is accepted too and stops at the main objective. **Every M1 reference is unchanged.** The 24 new ones, seeds 1-3 (a rendered run equals a headless one):

| Scenario | `none` (idle) | `play` (the scripted player) |
|---|---|---|
| tax | lost, the taxes are in, 146.2 / 142.1 / 153.5 s: -382910780 / 144915864 / -495264161 | won 2 of 3 (lost seed 1 at 228.9 s with two killed), 162.8 / 214.5 s, median 188.7 s: -642476028 / 659379666 / 458371431 |
| harvest | lost, a granary is emptied, 194.3 / 208.8 / 229.9 s: -631739367 / -407285158 / -195261095 | won 3 of 3, 182.2 / 189.2 / 189.2 s, median 189.2 s: 829609058 / -598442619 / 421108438 |
| lamb | lost, taken back, 177.6 / 173.4 / 170.4 s: -774246491 / -260547435 / -995215745 | won 3 of 3, 216.0 / 200.0 / 214.4 s, median 214.4 s: -768056610 / -739644497 / -418653026 |
| prayers | lost, too few believe, 300.0 s all three: 388017594 / -661342052 / -200623714 | won 3 of 3, 222.1 / 218.9 / 147.8 s, median 218.9 s: -911582887 / -560981669 / -817014552 |

The scripted gate for each mission: `play` wins at least 2 of seeds 1-3, the median time to the main objective of its wins is 180-240 s (the user's 3-4 minutes), `none` loses, and an acting player's longest idle stretch is under 45 s (measured: Spoiled Harvest 40 s, First Prayers 35 s, The Lost Lamb 27 s). The idle player's First Prayers loses only at dawn: no win waits for dawn, and only doing nothing loses late. The prayers `none` checksums moved once, when dawn stopped dropping the roof on a prayer in progress; their outcome did not. The harvest checksums moved once too, when its camera moved (below): the simulation reads what is in view (a person orders itself against its neighbours only on screen), so another camera is another run. The outcomes held: `none` still loses 3 of 3 (it was 190.2 / 193.3 / 226.8 s, checksums -399014068 / 547259992 / -90944872) and `play` still wins 3 of 3 (it was 182.2 / 182.2 / 190.0 s, median 182.2 s, -410228006 / 426542593 / 887534191); the median is now 189.2 s, further inside the 180-240 s window.

### Rulings made in M2

The mission spec's Decisions 1-29 and the plan's 30-33, numbered after M1's thirty.

31. The ids are `tax_collector`, `spoiled_harvest`, `lost_lamb` and `first_prayers`, built in `MissionBook.tier_missions()` at Tier 1's numbers (5:00, Unaware, 3 / 6, no bonuses), so the board needs no per-mission branch and they have no stretch; they are not in `all()` or the campaign.
32. Whisper has five missions, so Omen opens at three cleared; a save that opened Omen on The Warning alone keeps it open.
33. "Unseen" is no bonus: a seen kill calls the bellkeeper and still wins; on the board the bell tolling after it catches the night and loses the wishes, unless the god ascends or stops the bellkeeper first.
34. The Tax Collector has three targets in sequence (the collector and two deputies), each deputy out at his own time (1:45, 2:45) or 45 s after the one before dies; any one at the Citadel's gate loses the night, and `AssassinateDirector` is generic for N targets.
35. The counting-house is the workshop hall; each collector's debtors are the dwellings nearest his fixed spots whose doors the street reaches; the collectors are residents made nobles.
36. A loud power within 4 units of a collector in the street, a guard falling or a fright sends him to hide 30 s; a fire on, or the fall of, the house he is in flushes him out (never those waiting in the counting-house); with no hiding place an alarm sends him to the Citadel; quiet powers never alarm.
37. Raze is a new `RazeDirector` base (targets, a spoil time, an optional seal); Last Judgement's and Judgement's directors are left as they are.
38. Granaries are dwellings, empty until their grain arrives (1:00, 2:00, 3:00, or 45 s after the one before is spoiled); each has two watchmen who beat out its fire after 3 s while calm and at their posts; "spoiled" is burned 10 s in all or destroyed once the grain is in; the first granary emptied loses at once.
39. One carter a granary from near the Citadel, setting out when its grain arrives; a load is counted when it is taken; felled carters are not replaced.
40. "The west gate" is the Main Gate, on the lower-left wall on screen; the postern is barred in an Unaware town and the Side Gate is on the right.
41. The acolyte moves only by the god's hand and is seized on sight (2.5 units) by the patrols, the gate's watch and the searchers; a blind, turned or town-ordered soldier never seizes; he is freed when the seizer is felled, turned or taken off the errand; the crowd carrying him off is his escape.
42. The watch change starts 30 s after he first comes within 6 units of the gate, so the wait starts when the player engages; the watch is away 25 s and the change repeats every 45 s.
43. The searchers set out at 2:30, so doing nothing loses well before dawn, at about 2:55.
44. Convert is generalised by subclassing `MirasHouseDirector`: `need`, `read_seconds` and `one_at_a_time` (defaults 4, 8, false) and two label hooks, and Mira's House plays exactly as before.
45. The old well shrine is a drawn stone shrine post that cannot be destroyed; people led to it pray hidden for 32 s, one at a time; at dawn the post stands and a prayer in progress ends.
46. First Prayers has few Faithful (3 clergy, 3 lay, no Inquisitor); the market (1:15) and the priests (2:30) each put a line at the door for 40 s.
47. `unaware_town` is derived in `TierBook.board()` from a board mission's readiness, declared per mission nowhere; The Warning's entry goes.
48. Every wish's target building is reserved on the director, so no director makes it a granary or a debtor's house.
49. `MissionDirector`'s eligibility helpers skip reserved people and places, so a new director cannot forget.
50. The new directors leave alone a soldier the rally or the marshals have taken, and tolerate the loss rather than fight the order.
51. Stop the bailiff: 50 s is a cap; granted when he is killed, turned or still short of the door at 50 s, failed at the door; he starts at least 20 units away with at most 40 units of street, and the HUD shows the act, not a countdown.
52. Let my neighbours believe: the neighbours live within 8 of the home and are not of the household; each counts once whispered to within 2 of the wisher.
53. The tax collector wish clashes with The Tax Collector (`hunts_tax_collector`).
54. The behaviour scenarios run the `MissionBook` versions, so their checksums are exact references; `--board` stops at the main objective.
55. The scripted gate: wins at least 2 of seeds 1-3, median clear 180-240 s, and no idle stretch over 45 s for an acting player.
56. The new results titles are THE COLLECTORS ARE DEAD, THE TAXES ARE IN, THE HARVEST IS SPOILED, A GRANARY IS EMPTIED, THE LAMB IS FREE, THE LAMB IS TAKEN BACK and THE ACOLYTE IS DEAD.
57. The Warning's tour reads "at 0:10" for the first star and "by" for the later two.
58. Five cards a tab are 115 px wide: a card's brief wraps to seven lines at most, its best line wraps between its parts, and the row's rules sit level.
59. FLOW's board and results steps change for Tier 1's five missions and one step is added (The Tax Collector from the board, then abandoned through Pause): 109 to 110.
60. The directors are `AssassinateDirector` / `TaxCollectorDirector`, `RazeDirector` / `HarvestDirector`, `EscortDirector` / `LostLambDirector` and `FirstPrayersDirector`; the objectives `AssassinateObjective`, `RazeObjective` and `EscortObjective`; the wishes `BailiffWish` and `NeighboursWish`.
61. A generic objective takes its label and its reasons in `_init()`, so later tiers' missions of its type reuse it.
62. The board's Tier 1 list changes once, after all four missions exist; until then each was tested and played through its `MissionBook` version.
63. Each new results title is a reason in `ResultsScreen.ACT_TITLES`, added in the mission's own task.

### Photographs and drawing fixes

`--show=board`, `--show=tiers` (Whisper's tab, three of its five cleared; `--mission=vigil_flame` opens Wrath's instead) and `--show=tax_collector|spoiled_harvest|lost_lamb|first_prayers` photograph the board and each new mission's board night, with the tour skipped and the opening banners waited out.

- **Best lines:** a card's best, "Cleared  best 3:12  wishes 2", wraps between its parts and never inside one, so "best 3:12" stays whole and the double spaces survive; and the five cards' rules sit at one height, lifted by the row's most best lines, so a two-line best on The Warning does not leave its rule a line above its neighbours'.
- **The Lost Lamb's WEST GATE tag** has an edge arrow. The gate is some 28 units from the acolyte, so it is off screen at the opening camera, and the first photograph showed no sign of it; now "WEST GATE - WATCHED" and its arrow show at the screen's left edge.
- **Spoiled Harvest's camera** moves from (1, 8) to (-9, 13.5). At the old spot the first granary, the one whose grain comes at 0:55, sat under the left HUD stack (objectives, hint, wishes), tag and watchmen both; now its tag and its two watchmen are clear of the stack and the other two granaries' tags show at the right.
- The Tax Collector and First Prayers photographs needed nothing: their tags, hints and wishes read clear. As in every mission, a world tag can still pass under the HUD's panels and timeline strip (the INFORMER wish tag under the strip in the tax photograph).

Gates: filled in at landing.

## M1: The Tiers framework

M1 builds everything a tier needs and puts the eight missions that already exist on it. All five tiers are playable, with eight ★ missions between them. It adds no new mission type and no new art: text and drawn shapes only. The Lantern campaign is untouched, except for the two no-waiting changes below.

### The board

The title's **Missions** button opens **The Tiers**: five tabs, a header (`Night N`, `Believers N`, an **Upgrades** button) and the open tab's missions as cards (name, type, a two-line brief, and a foot line: "Not yet cleared", or "Cleared" with its fastest clear and most wishes once played).

| Tier | Name | Missions (type) | Readiness | Slots / DP | Clock | Wishes | Believers |
|---|---|---|---|---|---|---|---|
| 1 | Whisper | The Warning (Intercept) | Unaware | 3 / 6 | 5:00 | 2 | ×1 |
| 2 | Omen | Mira's House (Cult), Broken Lanterns (Anchors) | Organized | 3 / 8 | 5:30 | 2 | ×1.5 |
| 3 | Wrath | The Vigil Flame (Cult), The Festival (Break) | Prepared | 4 / 10 | 6:00 | 3 | ×2 |
| 4 | Reckoning | The Procession (Kill) | God-Resistant | 5 / 13 | 6:30 | 3 | ×2.5 |
| 5 | Ascendance | Last Judgement (Destroy), The Long Night (three acts) | God-Resistant, plus Halcyon's Gaze | 6 / 16 | 7:00 | 3 | ×3 |

- **Unlocking.** Tier 1 is open from the start. Tier T+1 opens when 3 of Tier T's missions are cleared. While a tier has fewer than three missions (until M6), all of them must be cleared: today clearing The Warning opens Omen, both Omen missions open Wrath, both Wrath missions open Reckoning and The Procession opens Ascendance. A tier never closes again. A locked tab shows a padlock and the rule ("Clear 3 Omen missions").
- **Cleared** means the main objective was done in some night, whether the god ascended or was caught after it.
- **Nights.** Every board night played to its end, won or lost, adds 1. A restart (R or Pause, Restart, which replay the loadout the night was drafted with) and an abandoned night (Pause, Missions) do not. The header shows the night about to be played; the results show the night just played. The counter has no story effect yet.
- **Believers** carry over between nights and are added to only when banked. Each tier's multiplier applies to the main objective (10) and to each wish (5 to 15 by difficulty), rounded half away from zero.
- **Prepare** on the board drops the difficulty picker. The budget is the tier's base plus the upgrades, never over six slots. Locked powers show greyed, with "Locked: N" for their price.
- **The save** has a new `[descend]` section: the night counter, believers, the highest open tier, the cleared missions, the upgrades bought, the powers unlocked and each mission's bests. A save without it starts the board fresh. A v0.10 save's won Warning, Long Night and Last Judgement carry over as cleared (v0.10 saves hold no times, so no best time carries). `[campaign]` is as it was. A board night also still calls `record()`, so the title's best score and rank keep updating.

### Board versions of the ★ missions

The board builds each mission from `TierBook.board(id, state)` on a fresh copy, so the campaign's and the scripted runs' missions never change. On the board a mission takes its tier's clock, its readiness (as a floor, never lowering the mission's own), its budget, and no bonuses (the wishes take their place).

- **Stretched timelines.** A mission's events stretch in proportion to the longer clock, so their windows still fall inside the night: Mira's House ×2.2, Broken Lanterns ×1.8333, The Vigil Flame ×2.0, The Procession ×2.6 and The Festival ×1.8 (to its close). The stretch is `EventTimeline` story time, so a director's comparisons with the timeline's elapsed time stretch too. Real-time waits (Mira's shout) do not, and neither do Wren's arrival at 0:50 and his 30 s wait before he tries the lantern himself: both run in real seconds, so the player never waits over a minute with nothing to do. The Long Night keeps its acts' own clocks (2:00, 2:30, 5:00) and every act takes the tier's budget and readiness.
- **The three stars of The Warning.** Three stars fall through the night, each sending a runner from its gate: the postern at 0:10, the Main Gate at 1:30 and the Side Gate at 3:00, the farthest from the bell first. A later star falls at its scheduled time or 30 s after the previous warning was stopped, whichever is sooner (its omen still first), so no wait runs over a minute; a warning still running never brings the next star forward. All three warnings must be stopped. Each star's watchman is appointed 2 s before it falls, and never a person already reserved (a wisher, a wish target or an earlier star's runner), so one kill stops one warning.
- **The Festival, 80 of 120.** The need rises from 50 to 80 and the crowd from 80 to 120 (80 of 80 would need every goer). The square closes at 4:30 as a deadline, before dawn. Its tour and hints say "eighty".
- **The Gaze at Tier 5.** In every Tier 5 mission a seen death adds 0.5 to Halcyon's 0-100 Gaze (Broken Lanterns' share of a seen death, 0.05), and a full Gaze loses the night. The Long Night keeps one Gaze through all three acts, and the bell does not fill it. A mission that already keeps a Gaze (Mira's House, Broken Lanterns, The Vigil Flame) keeps its own at every tier. On the HUD, a scored panel shows "Gaze N%" beside the escapes; the Gaze bar gives way to the rite's plate while the rite shows.

### Wishes

Each descent, the tier's count of wishes (2 or 3) is heard from real citizens. Each is an optional secondary objective that pays believers. At the start of the night's first intro a plate, "THE TOWN PRAYS...", lists them; on the HUD they sit under the how-to-win line, an open box each, a tick once granted, a cross and the words struck through once failed; on the map the wisher and the target carry soft-blue tags (`WISH`, `MONEYLENDER`, `THE CHILD` and so on).

| Wish | Kind | Act | Reward | Needs / clashes |
|---|---|---|---|---|
| Burn the moneylender's house | Ruin | Destroy the marked house | 10 | a house; clashes with `spares_houses` |
| Bring down the watchtower | Ruin | Destroy the marked tower | 15 | a watchtower |
| Strike down the cruel tax collector | Punish | Kill the marked citizen | 10 | a lay citizen |
| Kill the informer, unseen | Punish | Kill the marked citizen with no living witness | 15 | a lay citizen |
| Save my child | Rescue | Once engaged, stop or turn the soldier dragging the child to the Citadel's gate within 45 s | 15 | a soldier and a lay citizen of the wisher's household; clashes with `unaware_town` |
| Lead my brother out | Mercy | Whisper the marked citizen to a gate; he escapes | 10 | a lay citizen |
| Show me a sign | Sign | Cast any power within 4 units of the living wisher | 5 | none |
| Show yourself to my family | Sign | Whisper three of the wisher's household | 10 | three citizens near the wisher's home |

- **Drawn, and filtered.** The draw is seeded from the night counter and the mission id, not the town's seed: a restart or an abandoned night hears the same wishes again, and a counted night redraws. A wish is drawn only if its tags do not clash with the mission's (The Warning declares `unaware_town`, Mira's House `spares_houses`) and its targets exist; a mission with too few eligible wishes hears what it can, possibly none. Lay citizens are alive, out of doors, without faith, and neither clergy, engineer, bellkeeper, watchman, mayor nor noble. No person or building is shared between two wishes.
- **Reserved people.** Every wisher and wish target is reserved. A director that appoints someone mid-night (a later star's watchman, the Procession's escorts and its blessing's onlookers) skips them, so the mission cannot spoil a wish. The town's own orders cannot grant one either: the rally that sends every free soldier to the Citadel's ring (at City Emergency, the first Citadel hit and Judgement's start) sends an engaged Rescue's soldier back on his errand, and only the god's own effects (frightened, fleeing, confused, whispered, compelled) count as turning him.
- **Engaged.** A Rescue wish waits until engaged: a click within 8 px of the child's or the soldier's tag, or a cast within 2 units of either. Then its timer runs. The soldier dying by the god's own cast before engagement both engages and grants it; dying any other way fails it.
- **Judged at once.** A wish is granted the moment its act is done, before or after the main objective, and a granted wish turns its wisher into a Believer. It fails at once if the wisher dies, a target dies by another hand or leaves the town alive, the child dies, or a family member dies unshown. A building destroyed by anything still grants.

### ASCEND, being caught, and what is banked

- **Before the main objective** there is no ASCEND. A loss (bell, Gaze, escape limit, dawn) banks nothing, and still counts as a night.
- **The main objective done:** the banner THE NIGHT IS YOURS, an **ASCEND** plate above the slots (click it, or press **F**, which nothing else in a mission uses). The clock keeps running and every way of losing still applies. The how-to-win line switches to the wishes still open ("Grant the wishes still open (blue), or ascend when you are ready: press F.") or, with none open, to "Ascend when you are ready: press F."
- **Ascending.** A pale gold column rises over the god's last cast spot for 2 s of real time, under the banner YOU ASCEND, then the results. Banked: the main objective's believers plus every granted wish's. F pressed twice, or before the main objective, or during an intro or the ending, does nothing.
- **Caught after the main objective** (the bell, the Gaze, the escape limit or dawn first): the main win stands and its believers are banked; every granted wish's believers are lost and shown struck through ("lost: Halcyon saw you", "lost: the bell tolled", "lost: the people escaped", "lost: dawn came", else "lost: the night was lost"), and the results say so under the title ("Caught: dawn came. The night's main win stands."). A granted wish is lost on any night not ascended. After the main objective, a night also ends when any other primary objective fails (except deadlines such as the Festival's close).
- **The Long Night:** no ASCEND until Act III's main objective; Acts I and II end as before, and the wishes are heard once, at Act I.
- **The results** show the title and "mission - tier", a row for the main objective (its believers and a tick, or a cross) and one per wish (granted with its reward, lost, or crossed with "Their prayer goes unanswered"), then four lines: believers banked and the new total, `Night N`, the tier's progress ("Whisper 1 / 1 cleared: Omen is open") and each best beaten. Buttons: **Board**, **Again**, **Upgrades**.

### Upgrades

The Upgrades screen spends believers, on board missions only (the campaign keeps its own Divine Power):

| Upgrade | Price | Limit |
|---|---|---|
| +1 Divine Power | 25 × n believers for the n-th | 6 |
| +1 slot | 150 believers | 1 |
| Unlock a power | 15 × its DP (3 DP = 45, 4 DP = 60, 5 DP = 75, 6 DP = 90) | each once |

The powers costing 1 or 2 DP start unlocked (15 of 38). A click buys what it can afford; one it cannot buzzes and says why. The prices are first guesses, to be tuned in M2 against a played Tier 1. In the board's Prepare, the locked powers stay in the draft's grid, greyed, with their price, and cannot be picked.

### The no-waiting changes (they reach the campaign)

The rule: everything finishes by acting, no objective waits for dawn, a timed wait is 60 s at most. Two existing missions broke it, and both are shared with the Lantern campaign, so its Night 1 and Night 2 change too:

- **The Warning** is won only by stopping the warning (its clock is now "Dawn"): dawn with a warning alive loses, titled DAWN COMES. Holding out no longer wins.
- **Mira's House** is won the moment the fourth Believer walks out of the house, not at dawn.

The references that were expected to move did not: no scripted run reaches the changed condition. The five Warning cases end by the bell or by killing the messenger well before the clock, and Mira's play run ends at 94.9 s with three Believers.

| Reference | Old | New |
|---|---|---|
| warning none | -489775734 | -489775734 (lost to the bell, 24.9 s) |
| warning doom | -905773030 | -905773030 (won by killing the messenger, 13.5 s) |
| warning whisper | -588314462 | -588314462 (lost to the bell, 87.8 s) |
| warning discord | -997640091 | -997640091 (lost to the bell, 59.4 s) |
| warning mix | -206935500 | -206935500 (won by killing the messenger, 13.6 s) |
| miras play | -200101558, won=false reason=gaze, 94.9 s, 3 believers | unchanged |

### Rulings made in M1

1. The ★ missions keep their ids; The Festival and The Procession are `festival` and `procession`, built from The Long Night's acts as single missions.
2. The tier board is the class `MissionBoard`, rewritten in place; its v0.08 helpers that no longer apply went with their checks.
3. Stretch is the tier clock divided by the mission's own clock; The Festival stretches to its close; The Long Night keeps its acts' clocks.
4. The Warning's stars fall at the postern, the Main Gate and the Side Gate, each a `WarningDirector` set up 2 s before it falls; the main objective is all three stopped.
5. The board's Festival needs 80 of a crowd raised to 120, and closes at 4:30 as a deadline.
6. Board missions have no bonuses; `scored` stays, so Last Judgement and The Long Night keep their panel and show no score on the board's results.
7. Readiness is a floor (`MissionDef.tier_floor`) that never lowers a mission's own town.
8. Slots are capped at six, the number of slot keys.
9. The Long Night's acts all take the tier's budget on the board.
10. The Tier 5 Gaze adds 0.5 per seen death, one Gaze for the night, and the bell does not fill it.
11. After the main objective a night ends on the clock (caught `dawn`) or on any primary objective failing, deadlines excepted.
12. The Warning's clock-out loses with reason `dawn`, and its HUD row reads "Dawn".
13. The wish seed is the night counter and the mission id, so a restart replays the draw.
14. Wish targets are lay citizens, houses, towers and gates by fixed rules; the town has no ages, so the child is a lay citizen of the wisher's household; "any exit" is a gate, reached within 1.5.
15. Save my child: engaged by a tag click or a nearby cast, a free soldier walks to the child and then both to the Citadel's gate; granted when the soldier is dead or off duty with the child alive; failed on the child's death, the gate or 45 s.
16. The sign, the informer and the family are judged by the rules above (a seen kill fails the informer; one family member dying unshown fails the family).
17. Only The Warning (`unaware_town`) and Mira's House (`spares_houses`) declare mission tags in M1.
18. Rewards are rounded with `roundi` after the multiplier (15 × 1.5 = 23).
19. Granted wishes are lost on any night not ascended, with the texts listed above.
20. The ascent is a column of light drawn by the HUD, over 2 s of the ending's slow motion.
21. The header shows the next night; the results show the night played.
22. "Fastest" is seconds to the main objective (The Long Night counts its earlier acts); "most wishes" counts wishes banked by an ascent.
23. A v0.10 save's won Warning, Long Night and Last Judgement carry over as cleared only.
24. Prices: starting powers are DP 2 or less; unlocking is 15 × DP; +1 DP is 25 × n; +1 slot is 150.
25. After the main objective the hint is the wishes' or the ascent's line, and the ASCEND plate sits centred at y 272.
26. Results buttons are Board, Again and Upgrades; Upgrades' Back always leads to the board.
27. The Warning's hints drop "or outlast the omen"; the Festival's drop "fifty"; a new phase line covers the time between stars.
28. The Tier 5 Gaze shows as "Gaze N%" in a scored panel and gives way to the rite's plate.
29. The prayers plate shows during the night's first intro only, and not at all when no wish was drawn.
30. Mira's House's "four" hint stays but is no longer reached on the campaign night, and on the board the hint switches to the wishes once the main objective is done.

### Drawing fixes from the photographs

- **Results rows:** the board night's table widened from 120-520 to 100-540. A long label ("Strike down the cruel tax collector") beside "Their prayer goes unanswered" touched its note at the old width and clears it by about 38 px now.
- **Prepare:** a locked quiet power's "quiet" tag rides one line above its "Locked: N" price on the 140 px card; they ran together as "Locked: 45quiet".

### Photographs

`--show=tiers` (the board part-way up), `--show=upgrades`, `--show=results-descend` and `--show=ascend` (the board's Warning with its main objective done) photograph the board, the Upgrades, a caught night's results and the ASCEND night.

Gates (at 8d31813, M1 merged with Develop-Main's ui sounds): tests 4218 checks, 0 failures; FLOW 109 checks, 0 failures; the state digest and crowd_check unchanged; every exact behaviour checksum unchanged, including the five Warning cases and Mira's House (the no-waiting changes moved none of them: no scripted run reaches dawn with the warning alive or a fourth Believer); Broken Lanterns 424350965, the Vigil Flame and the Feast with the same results; the board Warning's scripted run (--board --mission-test) plays its stars cleanly. Bench, one mission per tier, board version against 92e0dcc (medians of three, noisy machine): The Warning 121 vs 121 fps, Mira's House 103 vs 109, the Vigil Flame 106 vs 109, Last Judgement 105 vs 109 (+20 draw calls): the wish tags and the board HUD cost about 0.3-0.6 ms a frame.
