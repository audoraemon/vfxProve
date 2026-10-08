# Kingdoms Amid Kataclysm (KAK) — Version 0.11 Summary

*Engine: Godot 4.7.2 (gl_compatibility, 640×360 pixel art, iso view). Branch `claude/lantern-campaign-spec` (from the v0.10 line plus the v0.09.1 board-tag work at `92e0dcc`). v0.11 is **The Tiers**: the board of single missions becomes the god's five Awakening Tiers, each night hears the town's wishes, ends in an ascent and pays believers that buy the god's upgrades. It is built in milestones: M1 the framework, then M2-M6 one tier at a time (25 missions in all). Design: `docs/superpowers/specs/2026-10-08-kak-v011-tiers-design.md`. Plan: `docs/superpowers/plans/2026-10-08-kak-v011-m1-framework.md`.*

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
