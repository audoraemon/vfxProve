# Kingdoms Amid Kataclysm (KAK) — Version 0.11 Summary

*Engine: Godot 4.7.2 (gl_compatibility, 640×360 pixel art, iso view). Branch `claude/lantern-campaign-spec` (from the v0.10 line plus the v0.09.1 board-tag work at `92e0dcc`). v0.11 is **The Tiers**: the board of single missions becomes the god's five Awakening Tiers, each night hears the town's wishes, ends in an ascent and pays believers that buy the god's upgrades. It is built in milestones: M1 the framework, then M2-M6 one tier at a time (25 missions in all). Design: `docs/superpowers/specs/2026-10-08-kak-v011-tiers-design.md`. Plan: `docs/superpowers/plans/2026-10-08-kak-v011-m1-framework.md`. M2 (Whisper): Tier 1's four new missions; mission spec `docs/superpowers/specs/2026-10-08-kak-v011-m2-whisper-missions.md`, plan `docs/superpowers/plans/2026-10-08-kak-v011-m2-whisper.md`. M3 (Omen): Tier 2's three new missions; mission spec `docs/superpowers/specs/2026-10-09-kak-v011-m3-omen-missions.md`, plan `docs/superpowers/plans/2026-10-09-kak-v011-m3-omen.md`.*

## M3: Omen

M3 completes Tier 2. Omen has five missions: Mira's House and Broken Lanterns from v0.10, and three new ones, each a night of 5:30 in an Organized town, 3 slots and 8 DP (plus the upgrades), two wishes and ×1.5 believers (the main objective pays 15). It generalises two mission types (Intercept and Break), reuses a third (Assassinate), adds two wishes, and carries one item over from M2's reviews. It adds no art: the ringers, their mates and the wardens are watchmen in the watch cloak and lantern, the watch posts are the wall towers, and every other stand-in is an existing building or person named by a map tag. Mission spec: `docs/superpowers/specs/2026-10-09-kak-v011-m3-omen-missions.md`.

### Omen's five

| Mission | Card type | Main objective | The twist |
|---|---|---|---|
| Mira's House | Cult | Lead four of the grieving to Mira's journal, unseen; won the moment the fourth walks out a Believer | Halcyon's Gaze fills as the town sees; on the board its events stretch ×2.2 |
| Broken Lanterns | Anchors | Break Halcyon's six wayside shrines and let them drain before the Vigil relights them | The bell and the Gaze can both lose the night; on the board its events stretch ×1.8333 |
| The Bell-Ringers | Intercept | Stop all three warnings | Three watch posts each send a ringer with two mates; a seen death passes the warning to a mate; a ringer who reaches the bell tower climbs and rings it himself; a loud power near a post sends its ringer out at once |
| Market Panic | Break | Scatter the fair: break 36 of the 44 goers | Four crowds of 11 walk in at a night fair; three wardens steady the crowd round them; the guard closes the market at 5:00 |
| The Informer | Kill | Kill the informer before the names reach the Temple | He is indoors, untouchable and untagged until his fourth contact is turned, and each contact is turned by a Mind Whisper no one sees; a contact killed or gone loses the night |

**Wrath now opens at three cleared.** Omen has five missions, so Wrath takes the full rule of three; M1's "both Omen missions open Wrath" no longer applies. A tier never closes: a save that opened Wrath on the two ★ missions keeps it open, and a test pins that. The results' tier line reads, e.g., "Omen 1 / 3 cleared: 2 more open Wrath". The board lists the ★ missions first, then the three new ones; five cards a tab are 115 px wide as on Whisper's, and The Informer's second brief line reads "Find him by his contacts. Kill him." so its brief fits the card's seven lines.

### The types

- **Intercept, generalised** (`BellRingersDirector`, with a `RingerDirector` per post, a subclass of `WarningDirector`). Three watch posts, the wall towers nearest (6.6, -15.65), (-8.0, 15.65) and (15.65, -8.0), each hold a ringer and two mates, all lay citizens made watchmen and taken inside the tower. At its time a post's three come out at its town-side door (a ringer running outside the wall read wrong), stand 3 s to light their lanterns, and the ringer runs for the bell tower's foot with his mates 1.2 behind him, on either side, beyond one Silent Doom's reach of him but within sight. A seen death passes the warning to the nearest witness, usually a mate, so one strike never stops a warning while his mates are by him: the god draws them off (a whisper, Discord, a fright) or strikes them first. A carrier who reaches the bell's foot takes the rope himself, whether or not the bellkeeper lives, and climbs for 12 s with the climb bar over the tower; one rope, so a second carrier waits at the foot; the town's escort guards the climber and steadies a confused one; a climber pulled off by a whisper, a fright or Discord tries again 10 s after he is calm; one stopped on the rope gives the bell back to its keeper, idle. A loud power within 6 of a waiting post sends its ringer out at once ("THE EAST POST SEES YOU"); quiet powers never do. A warning dies when its carrier is killed with no one living within 2 units. The posts and the bell tower are stone tonight (a blow only shakes them), and the pool leaves out Blight and The Bell Lies, which would silence the bell outright. `WarningDirector` gains only virtual hooks (`_rings_himself()`, `_relay_witness()`) whose defaults keep The Warning exact; `StarsObjective` reads either director.
- **Break, generalised** (`MarketPanicDirector`, a subclass of `FestivalDirector`). The Festival gains only what Market Panic uses: whether it has a Mayor, its fire spots, `_add_events()` and `_may_break()`. The fair is the north-east fountain, its plaza and the east street beside it, a bonfire by the fountain, goers spread within 5.5 of it so one Heaven Splitter cannot take a crowd. There are four crowds of 11, from the north-east quarter, the cathedral's street, the workshops and the east tavern; each walks in on duty (about 15 s), so an evacuation passes the walkers by, and can be struck on the way. Three wardens (watchmen, one at each post round the fountain, 2.6 apart) steady the goers within 5.5 of them while they stand on guard: they are fearless on guard (a kill, a whisper or Discord still takes them), and a fright breaks no goer near one, though deaths still count. A warden who left his post calm goes back after 20 s; a fallen one is replaced after 30 s (Spoiled Harvest's numbers, in Market Panic's own copy of the rule). The crowds to come are appointed as the night begins and stand on duty round their source, held fearless, so a loud cast or a seen death cannot empty one, and they count as goers from the start: one struck down where he waits counts toward the 36, and a crowd wholly dead before its time is scattered at once. Goers who reach the fair are held there against the town's regroup and evacuation. The guard closes the market at 5:00, a deadline. No Mayor, no address.
- **Assassinate, reused** (`InformerDirector`, a subclass of `AssassinateDirector` with one quarry and no guards). The base gains four hooks whose defaults keep The Tax Collector exact: a per-quarry `scheduled` flag, a `smoke_out` switch, a HUD line from the director, and `lost_reason()`. The informer waits indoors in his lodging, untouchable and untagged, and the night's paced items are his four contacts, the chandler, the weaver, the potter and the carpenter, each a lay citizen kept on duty at his house's door with three of his company on a half ring round it, in a quiet lane (no soldier's post within 2 of a door). Word reaches a contact at his visit; he is then turned by a Mind Whisper cast on him while no one else out of doors within 2 units sees it (people held by Discord or a whisper see nothing; a contact confused by Discord can still be whispered; only a fresh whisper counts). A turned contact names the next; the last names the hiding place, the informer bursts out of the carpenter's house and runs for the Temple's door, hiding 20 s in that house when a loud power comes within 4 or a fright takes him. A contact killed before he is turned, or gone from the town, loses the night ("THE TRAIL GOES COLD"): every contact is tagged DO NOT KILL from the start, bright and pointed at for the one to work on, pale for the ones after, and the hint and the tour say so. The company are held on duty and walk back after a whisper. Any kill of the informer wins; a seen one calls the bellkeeper, and on the board the bell tolling after it loses the wishes unless the god ascends or stops the bellkeeper first.

### Each mission's timeline

- **The Bell-Ringers:** 0:40 the north-east post sends its ringer (sooner if a post sees the god), who climbs at about 0:55 for 12 s and rings at about 1:10; the south-west post at 1:50 and the east post at 3:00, each or 45 s after the warning before is stopped, whichever is sooner; left alone the bell tolls between 68 and 73 s. Longest wait: 45 s, at the start (40 s) and between a warning stopped and the next post.
- **Market Panic:** the first crowd walks in at 0:00 and is at the fair in about 10 s; the next at 1:15, 2:30 and 3:40, each or 45 s after the crowd before is wholly gone; the guard closes the market at 5:00, so doing nothing loses at 300 s. Longest wait: 45 s, between a crowd gone and the next walking in.
- **The Informer:** word reaches the chandler at 0:45, his second contact at 1:55, the third at 3:00 and the fourth at 4:05, each or 45 s after the contact before is turned, whichever is sooner; the names reach the Temple 60 s after the fourth visit, so doing nothing loses at 5:05. Longest wait: 45 s, to the first visit and between a turn and the next visit.

No timed wait passes 60 s and no chain wait 45 s, and `test_tier2_board` pins every one. The later gaps in the schedules (70-75 s between crowds, 65-70 s between visits) are at-the-latest bounds that hold only while the item before is still open, so the player is never waiting. The tuning numbers, as shipped:

| Mission | Numbers |
|---|---|
| The Bell-Ringers | set out 0:40 / 1:50 / 3:00, chain wait 45 s, 3 s to light lanterns, 2 mates 1.2 behind, climb 12 s, post sight 6 |
| Market Panic | 4 crowds of 11 at 0:00 / 1:15 / 2:30 / 3:40, chain 45 s, 36 of 44 must break, 3 wardens, warden reach 5.5, fair radius 5.5, return 20 s, relief 30 s, market closes 5:00 |
| The Informer | 4 contacts, visits 0:45 / 1:55 / 3:00 / 4:05, chain 45 s, company 3, seen within 2, names 60 s after the last visit, hide 20 s, alarm reach 4 |

### The wishes

The pool grows from 10 to 12. Both new wishes are heard from Omen up (they clash with `unaware_town`), and Tier 1's seeded draws do not change: `WishDef.min_tier` and `WishBook.pool_for(tier)` leave the two out of a Tier 1 night's draw before it shuffles, so a Tier 1 night shuffles exactly M2's ten in M2's order and no test pinning a draw was re-pinned.

| Wish | Kind | Act | Reward | Needs / clashes |
|---|---|---|---|---|
| Scare off the bully, unharmed | Fright (new) | Frighten the marked citizen so he panics or runs for shelter (the Festival's broken minds) while he lives | 10 | a lay citizen; `unaware_town` |
| Free the pressed man | Rescue | Once engaged (a click on a tag, or a cast within 2 units of the son or either soldier), two soldiers walk to the wisher's son and march him to the barracks' door; kill or turn both within 45 s, the son alive | 15 | a lay citizen of the wisher's household living at least 15 units from the barracks' door with at most 40 units of street to it, and two free soldiers; `unaware_town` |

- **The bully** is tagged BULLY with an edge arrow (he walks the town). The wish is granted the moment he is frightened; the town's own flight does not count. It fails if he dies, leaves the town, or is hurt at all: "unharmed" means unhurt, since the frenzy powers panic as they hit (a controller ruling after Task 5's review).
- **The pressed man** is tagged PRESSED MAN with an edge arrow from the start, and PRESS-GANG on each soldier, pointed at once engaged. Turning is `RescueWish.TURNED`, as Save my child. The wish leads with the man who reached the son. `PressedWish` subclasses `RescueWish`, which is untouched, so Save my child plays as before.
- **Kill the informer, unseen** now clashes with `hunts_informer`, which The Informer declares in `TierBook.MISSION_TAGS`, so it is never heard on that night; a test draws sixty nights on The Informer and Market Panic.

### The carried item

- **The strip shows the chained time.** M2 deferred it twice: when a chain brings an item forward the event strip kept counting down to its scheduled time, overstating by up to 13 s. A director now tells its timeline the chain's time (`EventTimeline.expect(id, at)`); the strip and `seconds_to()` show the sooner time, display only, and firing is unchanged. All three new missions use it, and so do The Tax Collector and Spoiled Harvest, whose 24 references are exact.

### References

Each mission's scenario is `--scenario=ringers|panic|informer --case=none|play [--seed=N] [--board]`; it runs the `MissionBook` version (the same director, clock and town, no wishes), so its checksums are exact references, and `--board` stops at the main objective. The panic scenario turns hit-stop off (below). **Every M1 and M2 reference is unchanged.** The 18 new ones, seeds 1-3 (a rendered run equals a headless one):

| Scenario | `none` (idle) | `play` (the scripted player) |
|---|---|---|
| ringers | lost, the bell tolls, 72.6 / 68.5 / 70.5 s: -275717420 / -138070945 / -370827666 | won 2 of 3 (lost seed 3 at 173.3 s to the bell), 232.9 / 176.3 s, median 204.6 s, idle 26 s: 153399206 / -667456881 / -195878434 |
| panic | lost, the market closes, 300.0 s all three: -42444191 / -831702796 / 49852883 | won 3 of 3, 220.0 / 212.6 / 195.6 s, median 212.6 s, idle 25 s: -102624718 / -214853765 / -575287130 |
| informer | lost, the names reach the Temple, 305.0 s all three: -466238773 / -645533123 / -807294926 | won 3 of 3, 200.2 / 191.3 / 191.1 s, median 191.3 s, idle 27 s: -597754669 / -239928876 / -328944037 |

The scripted gate for each mission is M2's: `play` wins at least 2 of seeds 1-3, the median time to the main objective of its wins is 180-240 s, `none` loses 3 of 3, and an acting player's longest idle stretch is 45 s or less (measured: The Informer 27 s, The Bell-Ringers 26 s, Market Panic 25 s). The Bell-Ringers' two wins straddle 180 (176.3 and 232.9, median 204.6), so the landing gate also runs its seeds 4 and 5, as evidence only. The informer's checksums moved once, when its camera moved in the photograph round (below): `none` still loses 3 of 3 (it was -240463889 / -734019761 / -973115462) and `play` still wins 3 of 3 (it was 208.2 / 191.3 / 191.1 s, median 191.3 s, -628642426 / -974457838 / -172155681). Market Panic's moved once, in the final review's fixes (below), when its walkers were sent on duty: `none` still loses 3 of 3 (it was -664887067 / -375660839 / 827215944) and `play` still wins 3 of 3 (it was 205.3 / 193.2 / 195.9 s, median 195.9 s, idle 21 s, -161148673 / -608785440 / -605487252). The board versions at seed 1 (`--case=play --seed=1 --board`): ringers won 193.3 s with the moneylender and sign wishes (-797522800); panic won 220.0 s with the pressed and neighbours wishes (-102624718, the same as off the board: neither wish touches the checksum there); the informer won 200.2 s with the brother and pressed wishes (-855491052; it was 208.2 s and -951894780 before the camera moved). Two wishes each, and never the informer wish on The Informer's night.

### The rulings that changed the design

The controller's rulings, made when a task's gate or review showed what the mission spec's first guesses could not.

- **The post doors are each tower's town-side door; the mates are back to 2 and the chain to 45** (Task 2). The first doors opened outside the wall (the east route ran 37 units, so the tour's "shortest way" was false). A first tuning round had cut the mates to 1 and the chain wait to 40 to fit a weak scripted policy, which cheapened the mission; the policy now works the mates (a Doom from clear of others, or a fright or whisper to send one off), and acts elsewhere when a soldier watches a door, as a player would. The ringers' six references were recorded once, after this.
- **Market Panic has four crowds of 11, held on duty and counted when struck down** (Task 3). The first guess was three crowds of 14 needing 30; its scripted run cleared in 143 s, and the spec's Heaven-first policy made the Organized town evacuate, emptying the second crowd. A fourth crowd and the 45 s chain make the clear crowd-bound, so only another crowd reaches 180 s without idle; with 12 to a crowd the fourth was never needed, so it is 11. Every crowd's goers are appointed at the start and kept on duty at their source until they walk in, so an evacuation cannot silently empty a later crowd: a natural Heaven Splitter must not be a hidden loss. A goer of any crowd killed before he walks in counts toward the need (the Festival counts any of its crowd), and the waiting crowds' gold pips and the hint say so; before he sets out only a waiting goer's death counts, not a fright, or one Smite would clear a stand.
- **Quiet doors and a fourth contact** (Task 4). With the spec's first doors, about five passers-by stood within 2 of the chandler's and weaver's doors at almost every moment, so an unseen whisper meant waiting on street traffic, which is waiting. The contacts' doors are now quiet ones, and a fourth contact (a fourth visit, chain 45 s, the first at 45 s) lets the chain-bound clear reach 180 s, as Market Panic's fourth crowd does. Four additions the director found it needed were accepted: the found informer is held on duty, a contact leaving town loses at once, only a fresh whisper counts, and the cold-trail banner shows once. The short, seen chase (he dies 8-10 s after he is found, near the Temple, so the bell is called) stands: the main objective is done by then, ASCEND banks the wishes, and an unseen kill is the skilled player's reward.
- **"Unharmed" means unhurt** (Task 5's review). The bully wish fails if his health drops below a citizen's full health, since the frenzy powers hurt 0.25-0.5 and panic him as they do.
- **Hit-stop has a switch** (Task 3). Smite's and Heaven Splitter's hit-stop runs on the wall clock, so a scripted run's checksum varied. `Impact.hitstop_enabled` (default on) skips it, and `behaviour_check` turns it off for the panic scenario (and any later scenario that casts them), so those play checksums are exact; no old scenario changes.

### Rulings made in M3

The mission spec's Decisions 1-40 and the plan's 41-56, numbered 64-119 after M2's. The controller's rulings are folded in where they changed a decision (16, 24, 26, 31, 32).

64. The ids are `bell_ringers`, `market_panic` and `informer`, built in `MissionBook.tier_missions()` by a new `_tier2()` frame (330 s, `tier_floor` 2, no `profile`, 3 / 8, no bonuses), so the board needs no per-mission branch and they have no stretch; they are not in `all()` or the campaign.
65. Omen has five missions, so Wrath opens at three cleared; a save that opened Wrath on Mira's House and Broken Lanterns keeps it open.
66. The Bell-Ringers is a new container, `BellRingersDirector`, after StarfallDirector's pattern (which is untouched); each warning is a `RingerDirector`, and `WarningDirector` gains only virtual hooks, so the five Warning references and the board Warning stay exact.
67. The posts are the wall towers nearest (6.6, -15.65), (-8.0, 15.65) and (15.65, -8.0), never a reserved tower; each door is the first face with a route from the bell's foot, the tower's town-side door (north-east 23.5 units of street, south-west 23.3, east 18.9, by the controller's ruling); `_open_door()` moves up from `AssassinateDirector` to `MissionDirector` unchanged.
68. Stone tonight: the posts and the bell tower only shake when struck, their damage filter cleared at teardown; the pool leaves out Blight and The Bell Lies.
69. Each post's three are the lay citizens nearest its door, made watchmen and taken inside; MATES 2, MATE_GAP 1.2, the mates beyond one Doom of the ringer at the door (the controller put MATES back to 2 and made the policy work them).
70. A carrier who reaches the bell's foot takes the rope (a 12 s climb) whether or not the keeper lives; one rope; a carrier stopped on it gives the bell back to its keeper, idle (`BellNetwork.restore()`).
71. SET_OUT_AT 40 / 110 / 180, CHAIN_WAIT 45, OUT_PAUSE 3.
72. A loud cast within 6 of a waiting post sends its ringer out at once; quiet casts never do. It lets a player cut any wait.
73. The Warning's relay is kept (a relay never picks another warning's ringer or mate: a controller ruling), and the Organized town's escort guards whoever is on the rope; if the town calls its bellkeeper while a ringer holds the rope, the hand-back re-calls him at Local Emergency.
74. The Bell-Ringers' objectives are all three warnings stopped, the bell silent, dawn.
75. Market Panic is `MarketPanicDirector`, a subclass of `FestivalDirector`, which gains only what it uses (decision 110).
76. The place is the north-east fountain and its plaza; goers spread within 5.5 of it.
77. Four crowds of 11, from (11.4, -10.0), (4.5, -4.0), (12.0, 1.0) and (8.75, 2.75), at 0:00 / 1:15 / 2:30 / 3:40 or 45 s after the crowd before is wholly gone; all appointed as the night begins and held on duty at their source until they walk in (the controller's ruling; the spec's three crowds of 14 did not make the night).
78. 36 of the 44 goers must break, by the Festival's rule of broken, a waiting goer struck down counting too (the controller's ruling).
79. Three wardens at posts evenly round the fountain steady the goers within 5.5; return 20 s, relief 30 s. The spec shared Spoiled Harvest's watchman record only if its references stayed exact; the controller ruled the safe way, so Market Panic copies the rule (decision 106).
80. The guard closes the market at 5:00 (`MARKET_CLOSE` 300 s), a deadline: doing nothing loses then.
81. No Mayor, no address, no fountain push; one bonfire burns by the fountain.
82. Goers who reach the fair are held there against the town's regroup and evacuation, and the crowds still to come are held on duty the same way; the Organized town's bell may ring and loses nothing here.
83. `InformerDirector` extends `AssassinateDirector`, with one quarry and no guards; the base gains the `scheduled` flag, the `smoke_out` switch and a HUD line, and a fourth hook, `lost_reason()`.
84. The informer is indoors, untouchable and untagged until his last contact is turned, on duty so an evacuation never sends him running; this keeps the kill from coming at about 1:00.
85. Four contacts, the chandler (6.0, -12.4), the weaver (-13.7, 12.6), the potter (-1.4, 13.8) and the carpenter (6.2, 13.8), each set down at a quiet door (the controller's ruling: quiet doors, and a fourth contact), all tagged DO NOT KILL from the start.
86. Word reaches them at 0:45 / 1:55 / 3:00 / 4:05, or 45 s after the contact before is turned; a contact can be turned only after his visit; the clear is chain-bound, about 3:10.
87. Turning is a Mind Whisper on the contact while no one else out of doors within 2 units sees it; held minds see nothing. A contact held by Discord can be whispered (the controller's condition on Decision 24: kept only if the code lets a Whisper reach a confused person; `Person.whisper()` refuses only soldiers, people inside, the dead and the shaken, so it does).
88. Three company a contact, 1.2 from his door on a half ring facing the street; they walk back after a whisper; no relief.
89. A contact killed before he is turned, or gone from the town, loses the night ("THE TRAIL GOES COLD"), with a plain warning on his tag, in the hint and in the tour (the controller's condition on Decision 26).
90. The chase: found, he runs from the carpenter's house to the Temple's door (about 20 units, some 13 s), no guards, hiding 20 s when alarmed; any kill wins and a seen one calls the bellkeeper; the short, seen chase stands.
91. Not found in time: 60 s after the fourth visit the names reach the Temple, so doing nothing loses at 5:05, before dawn.
92. The Informer declares `hunts_informer`; the wish "Kill the informer, unseen" clashes with it.
93. Camera spots: The Bell-Ringers (6.0, -5.0), Market Panic (10.0, -8.0), The Informer (3.0, -3.0, moved from (4.0, -2.0) by the photograph round).
94. The new wishes are "Scare off the bully, unharmed" (a new Fright kind, 10) and "Free the pressed man" (Rescue, 15), both clashing with `unaware_town`; the pool grows from 10 to 12 and Tier 1's seeded draws do not change (the controller replaced the spec's re-pin with `min_tier` and `pool_for`).
95. Free the pressed man is `PressedWish`, a subclass of `RescueWish` (the fallback): the son lives at least 15 units from the barracks' door with at most 40 of street, the two free soldiers nearest him march him, 45 s, turning is `RescueWish.TURNED`.
96. The strip shows a chained item's real time (`EventTimeline.expect()`, display only); The Tax Collector and Spoiled Harvest adopt it with their references exact.
97. The scenarios `ringers`, `panic` and `informer` run the `MissionBook` versions, so their checksums are exact references; `--board` stops at the main objective; the panic scenario turns hit-stop off.
98. The scripted gate is M2's: wins at least 2 of seeds 1-3, median clear 180-240 s, `none` loses 3 of 3, no idle stretch over 45 s.
99. The new results titles are THE RINGERS ARE STOPPED, THE FAIR IS SCATTERED, THE MARKET IS CLOSED, THE INFORMER IS DEAD, THE NAMES REACH THE TEMPLE and THE TRAIL GOES COLD, each a reason in `ResultsScreen.ACT_TITLES` under the mission's own key (`ringers`, `fair`, `market_closed`, `informer`, `names`, `cold`).
100. FLOW's board step also checks Omen's five missions and one step is added (The Bell-Ringers from the board, ascended): 110 to 111.
101. The board lists the ★ missions first, then The Bell-Ringers, Market Panic and The Informer.
102. The bench is The Bell-Ringers' board version against Mira's House's, on a quiet machine.
103. Market Panic's objectives are `FestivalObjective("Scatter the fair", "fair")`, the close as an `EventObjective`, and the tier's dawn.
104. The directors are `BellRingersDirector` / `RingerDirector`, `MarketPanicDirector` and `InformerDirector`; the wishes are `FrightWish` and `PressedWish`.
105. Tier 1's wish draws do not change (see 94): `WishDef.min_tier` (1 by default) and `WishBook.pool_for(tier)`, which `Descent.hear()` draws from.
106. Market Panic copies the warden rule as its own `Ward` record and tick, reading Spoiled Harvest's numbers, so `HarvestDirector` is not touched and its references cannot move.
107. Decision 87 holds in the code: a Whisper reaches a confused person, and the informer's policy keeps its Discord step.
108. The contact's tag reads "CONTACT - DO NOT KILL" once he has word and "NO WORD YET - DO NOT KILL" before; the main hint ends "Do not kill a contact." and the tour's first stop ends "Turn him with a whisper: do not kill him."
109. `PressedWish extends RescueWish`, overriding the two-soldier parts; `RescueWish` stays untouched, so Save my child plays exactly as before.
110. `FestivalDirector` gains only `has_mayor`, `fire_spots`, `_add_events()` and `_may_break()`; Market Panic keeps its place, radius and words itself and overrides `_gather()`, `tags()`, `hint_phase()` and `tour()`.
111. `StarsObjective` takes its words in `_init()` and counts through a static `tally()` that reads a `StarfallDirector` or a `BellRingersDirector`.
112. `AssassinateDirector.lost_reason()` carries "the trail goes cold"; not being found in time marks the quarry safe, so the objective's own loss reason (`names`) covers both ways the names reach the Temple.
113. The informer's hideout is the third contact's house from the start (the Assassinate rule); he waits in his lodging and is moved into the hideout the moment he is found.
114. A ringer's set-out reuses `WarningDirector`'s stare (`set_out()` brings the three out and enters it with `OUT_PAUSE` left; no star falls); a carrier finds the rope taken while the bell is called or climbing with a living keeper on duty who is not him, and waits at the foot.
115. `EventTimeline.expect(id, at)` stores a shown time per event (in the night's real seconds, as the chains count); `upcoming()` orders by it, which is the old order for a timeline that never calls it.
116. The schedules leave gaps of 65-90 s between items only while the item before is still open; the waits an acting player can meet are the first wait and the chain wait, and `_waits` pins those (60 s at most; chains 45 s at most), with the gate's `idle` proving the player's side.
117. Goers at the fair, the contacts and their company are put on duty at their spots (`Person.go_duty()`): the town's regroup takes only the calm and the evacuation passes those on duty by; a whisper, a fright or Discord still moves them, and back on their feet they walk back.
118. FLOW 111: a new `_flow_tier2` (Omen opened as a fixture) plays The Bell-Ringers from the board, stops its three warnings, ascends and reads "Omen 1 / 3 cleared: 2 more open Wrath"; the `tiers` photograph's save also clears The Bell-Ringers, so Wrath opens by the three-clear rule.
119. Small additions for clarity: NEXT CROWD and TEMPLE are pointed at from the edge, a whisper someone sees gives the banner "SEEN - HE SAYS NOTHING", and Free the pressed man measures his distance and his street from where the son stands at the draw (as Save my child and Stop the bailiff measure).

### Photographs and drawing fixes

`--show=bell_ringers|market_panic|informer` photograph each new mission's board night, with the tour skipped and the opening banners waited out, and `--show=tiers --mission=miras_house` opens Omen's tab (the `tiers` photograph's save has Whisper's three and Omen's three cleared, so Wrath is open).

- **The Bell-Ringers** needed nothing. NEXT POST shows over the north-east post at the top right, WATCH POST at the east post, and the south-west post's arrow on the left edge below the HUD stack; BELL TOWER shows below the centre; the strip ("The north-east post sends its ringer", "The south-west post sends its ringer"), "Ringers stopped 0 / 3", "Dawn 5:28", the hint and the two wishes' rows read clear, and nothing key is under the stack.
- **Market Panic** needed nothing. THE FAIR - 0 / 36 and the WARDEN tags show at the fountain, the gold pips of the waiting crowds (33 of them) read on the streets, NEXT CROWD and its seconds show at the cathedral's street below the stack, and the strip, "Scatter the fair 0/36", "Market closes" and the hint read clear.
- **The Informer's camera moves** from (4.0, -2.0) to (3.0, -3.0). At the old spot the chandler's tag sat 9 px above the HUD's tag frame, so the first contact, the one to work on, showed as an arrow at the top edge with "NO WORD YET - DO NOT KILL" drifting away from his company's red diamonds. Now his grey diamond sits over his door in the middle of his company's red ones, with its label above, and the Temple is clear of the stack (so are the weaver's and the potter's arrows once each is the one to work on, and the carpenter's pale tag at the bottom left). The camera feeds the scenario (a person orders itself against its neighbours only on screen), so The Informer's six references were re-recorded and its gate re-run: none loses 3 of 3, play wins 3 of 3, median 191.3 s, idle 27 s. A test pins that the first contact's tag is drawn over his door, not as an arrow.
- **Omen's tab** reads clear: five cards with each name, type and brief inside it; Mira's House, Broken Lanterns and The Bell-Ringers ticked; Wrath open and Reckoning and Ascendance padlocked.
- As in every mission, a world tag can still pass under the HUD's panels and timeline strip (a WISH tag under the strip, PRESSED MAN under the hint).

### The final review's fixes

One Important finding and the minor ones, fixed in one commit before the milestone lands.

- **Market Panic's goers stay in the town when it evacuates.** The walkers strolled in calm, and the town's evacuation flees everyone calm, recovering or looking on once, and a fleeing man refuses a duty, so a crowd walking in when the town evacuated left it for good, and with it any chance of 36 of 44. Now each walks in on duty (as the waiting and the arrived stand on duty), so the evacuation passes him by; each walks to a spot he has a way to (a duty walker bound for a yard shut behind the houses would stand short of it for good, where a calm stroller drifted on); a goer his crowd could not send as it set out (whispered, confused, indoors) is sent once back on his feet, so the hint never waits on "coming" for him; and none is let flee: a whisper the evacuation found him under ends with him on his feet, and at the director's first look after the evacuation began, any it sent running is called back (`MissionDirector._keep_from_flight()`, `_evacuation_began()`). The walk-in is about 15 s now.
- **The Informer's contacts stay too.** A contact or one of his company whispered when the town evacuated woke into its flight and left the town, and the trail went cold; the same rule keeps them at their places.
- **The Bell-Ringers' relay passes over the fleeing and the reserved.** A warning handed to a citizen already running for the gates left the town with him and could never be stopped; a wish's people could carry one too. Neither is picked or marked as a witness now, and a carrier gone out of the town alive (no fall to judge) takes his warning with him: it is dead, and counted.
- **`StarsObjective` reads the director's own count** (`stars_stopped()` / `stars_total()`, none by default) instead of a list of types; the board Warning's reads as before.
- **Minor:** The Informer's seen death cries "THE TOWN CRIES MURDER" (he has no guards); a later contact past his visit, not yet workable, reads NO WORD YET; its loss names a contact leaving the town; the vestigial `Contact.known` is gone. Market Panic's hint reads "crowds still waiting count if struck down" (and "Strike the wardens" to fit the plate), tied to `FAIR_NEED` by a test; a shut-in citizen is passed over for a relief, end to end. The wish buildings (MONEYLENDER, WATCHTOWER) are pointed at from the edge. The mates' door formation is tested at all three doors; FLOW asserts The Bell-Ringers' ascent and guards its results casts; `_waits` pins the first waits (0:40, 0:00, 0:45). Market Panic's third WARDEN label is dropped where its plate overlaps THE FAIR's, and no reorder keeps both, so it stays a red diamond.

Gates: filled in at landing.

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
36. A loud power within 4 units of a collector in the street, a guard falling or a fright sends him to hide 30 s; a fire on, or the fall of, the house he is in flushes him out (never those waiting in the counting-house); with no hiding place (the counting-house burning or gone) an alarm sends him to the Citadel, and the hint, the HUD and the Citadel tag say so; quiet powers never alarm.
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
63. Each new results title is a reason in `ResultsScreen.ACT_TITLES`, added in the mission's own task. The Lost Lamb's reasons are its own (`lamb_out`, `lamb_taken`, `lamb`), not the Escort objective's defaults (`out`, `taken`), so a later Escort mission using the defaults is not given the lamb's titles.

### Photographs and drawing fixes

`--show=board`, `--show=tiers` (Whisper's tab, three of its five cleared; `--mission=vigil_flame` opens Wrath's instead) and `--show=tax_collector|spoiled_harvest|lost_lamb|first_prayers` photograph the board and each new mission's board night, with the tour skipped and the opening banners waited out.

- **Best lines:** a card's best, "Cleared  best 3:12  wishes 2", wraps between its parts and never inside one, so "best 3:12" stays whole and the double spaces survive; and the five cards' rules sit at one height, lifted by the row's most best lines, so a two-line best on The Warning does not leave its rule a line above its neighbours'.
- **The Lost Lamb's WEST GATE tag** has an edge arrow. The gate is some 28 units from the acolyte, so it is off screen at the opening camera, and the first photograph showed no sign of it; now "WEST GATE - WATCHED" and its arrow show at the screen's left edge.
- **Spoiled Harvest's camera** moves from (1, 8) to (-9, 13.5). At the old spot the first granary, the one whose grain comes at 1:00 (its tag read 0:55 by the time of the photograph), sat under the left HUD stack (objectives, hint, wishes), tag and watchmen both; now its tag and its two watchmen are clear of the stack and the other two granaries' tags show at the right.
- The Tax Collector and First Prayers photographs needed nothing: their tags, hints and wishes read clear. As in every mission, a world tag can still pass under the HUD's panels and timeline strip (the INFORMER wish tag under the strip in the tax photograph).

### The final review's fixes

One Important and five minor findings, fixed in one commit before the milestone lands.

- **A collector running for the Citadel is shown as running.** With the counting-house burning or gone, an alarmed collector walks to the Citadel and his arrival loses the night, yet the hint read "he hides in the counting-house", the HUD ", he hides" and the place tag stayed on his next debtor. `AssassinateDirector.fleeing_to_safe()` now drives a `running` hint phase ("No hiding place: he runs for the Citadel (red). Kill him before he gets in."), the HUD's ", he runs for the Citadel" and a red CITADEL tag with an edge arrow. All read-only: no checksum moved.
- **The Lost Lamb's results keys** are its own (decision 63).
- **A spoiled granary's watchmen go home**, those calm at their posts as well as those on duty (the first watchmen are set down with a stay of 1000 s, so they would have stood there all night). The scripted player kills every watchman before a granary is spoiled, so Spoiled Harvest's six references did not move.
- **The lamb's gate reads WATCHED while the watch walks back** from the guardhouse, in the tag and the hint; seizing is by sight alone and the scripted player's own choice is unchanged, so the lamb references did not move.
- **`RazeDirector.teardown()` unseals** every sealed target, so no building keeps a damage filter bound to a dead director.
- **Stale text:** the Tax Collector's header comments (15 s indoors, the second deputy's three debtors) and the photograph note above (the first grain comes at 1:00).

Gates (at 9c27bfd, M2 merged with Develop-Main's GPT buildings): tests 5596 checks, 0 failures (4525 on M2 alone; the rest came with the merge); FLOW 110 checks, 0 failures; the state digest and crowd_check unchanged; every exact behaviour checksum unchanged (calm, gates, fire, rite, soldiers, the five Warning cases, Mira's House, Broken Lanterns), the Vigil Flame and the Feast with the same results; all 24 new references above exact; the four `--board` runs as Task 7 recorded them (prayers differs from its off-board run on purpose: the family wish reserves some of the poor). Bench, board versions against `kak-v011-m1` (medians of three, noisy machine): The Tax Collector 96 fps against The Warning's 89 there (+22 draw calls), The Warning 111 vs 111, Mira's House 102 vs 101, the Vigil Flame 103 vs 102, Last Judgement 91 vs 85: no cost.

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
