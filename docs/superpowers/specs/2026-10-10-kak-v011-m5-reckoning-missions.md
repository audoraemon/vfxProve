# KAK v0.11 M5 Reckoning: the four new Tier 4 missions (mission spec)

Date: 2026-10-10. Status: for the user's approval. Builds on the v0.11 spec
(`docs/superpowers/specs/2026-10-08-kak-v011-tiers-design.md` §2, §4, §5, §7.1, §8 rows 16-20), M1-M3 as shipped (rulings 1-119
in `docs/KAK_Version_0.11_Summary.md`) and M4 as specified and planned
(`docs/superpowers/specs/2026-10-10-kak-v011-m4-wrath-missions.md`, Decisions 57-90; plan decisions 91-120; the M4 ledger's
rulings). M5 makes Tier 4 complete: The Procession, plus four new missions (Assassinate, Raze, Convert and Steal, all reused), two
new wishes, and the board, photos and notes.

M5 lands after M4. Where this spec leans on an M4 helper (`_recall_to()`, `_lay_reaching()`, `EngineerManager.hands_off`), it
means the helper as M4 lands it.

## 0. What every Tier 4 mission shares

- **Tier 4's numbers:** clock 6:30 (dawn), town God-Resistant, 5 slots and 13 DP (plus upgrades), 3 wishes heard, believers ×2.5
  (the main objective pays 25).
- **Built at their tier:** each new mission is made in `MissionBook.tier_missions()` by a new `_tier4()` frame, as M3's
  `_tier2()` and M4's `_tier3()`:
  - `tier` 4, `clock` 390 s, `slots` 5, `dp_capacity` 13;
  - `tier_floor` 4 (God-Resistant) and no `profile`, so a scripted run meets the board's town;
  - no bonuses, `intro_banner` the name in capitals;
  - every power allowed unless the mission narrows its pool. Its board version has stretch 1.
- **The God-Resistant town** (`ResponseProfile.for_tier(GOD_RESISTANT)`, read in the code):
  - the bell climbs in 5 s, and two soldiers guard whoever is on the rope (`escorts_per_duty` 2);
  - four seen deaths or collapses in one district make a Local Emergency, and the bellkeeper climbs;
  - a fire brigade of five turns out from Local Emergency;
  - three engineer teams turn out from City Emergency. They mend houses and the Temple (`EngineerManager.jobs()`: a damaged
    house, the Temple, the bell tower, the gates, the bridge, the dock);
  - the Banishing Rite at City Emergency (35 s, six clergy, on the cathedral's steps) takes 40 s off the clock;
  - the evacuation comes 8 s after City Emergency (`regroup_seconds`), five marshals at each way out, five rescue squads;
  - river boats of ten: the postern is open, one person through it every 1.5 s.
- **What the profile does not bring:** no Lantern Knights, no Inquisitors, no Searchlight. Those are missions' own (Broken
  Lanterns' Knights, Mira's Inquisitor, The Vigil Flame's light). M5 brings Knights into The Bishop and the Searchlight into The
  Relic Run, each as its director's own.
- **The bell:**
  - The Bishop and The Armoury have no bell loss (as M4). A seen death raises the town. It never ends the night by itself.
  - The Sermon and The Relic Run keep their family's Gaze (Mira's House, The Vigil Flame). There the bell fills the Gaze, so the
    bell loses the night. With a 5 s climb, four seen deaths in one district are close to a loss. Both missions' hints say so.
- **Mission tags:** a God-Resistant town carries no `unaware_town`, so every older wish and both new wishes (§6) can be heard.
- **No waiting:** everything finishes by acting. Every timed wait is 60 s at most, every chain wait 45 s at most. Each mission
  lists its longest wait.
- **The chain rule** (M2-M4): each item comes at its scheduled time or a chain wait after the one before is done, whichever is
  sooner. One still open never holds the next back. The strip shows the chained time (`EventTimeline.expect()`).
- **The clear arithmetic** (M3 lesson): with N chained items, a skilled clear is about
  `first wait + (N - 1) × chain + the work after each item comes`. Work done ahead (the next item's guards, cleared in the last
  25 s before it comes) does not count. Each mission shows its sum.
- **Length and the gate** (M2 ruling 55), per mission, seeds 1-3:
  - doing nothing loses 3 of 3;
  - the scripted player wins at least 2 of 3;
  - the median of its wins is 180-240 s;
  - its longest stretch between two casts (`idle=`) is 45 s or less.
  - The scripted policy works the opposition as a player would before any knob is tuned (M3's Task 2 ruling).
- **Own people** (M2-M4):
  - Every person a director uses is its own. Lay citizens are appointed and dressed through `MissionDirector._eligible()`,
    `_lay_near()`, `_house_near()`. The Bishop's Lantern Knights are soldiers the director adds (`Crowd.add_soldier()`, corps
    `KNIGHT`), as Broken Lanterns' are. No town soldier is ever borrowed.
  - So the rally (corps `NONE` only), the marshals, the escorts and the rite never take one, and no wisher, wish target or wish
    building is ever used. Each mission lists its claims.
- **Held on duty** (M3 lesson 4, M4 ruling):
  - Every person whose loss would change the night is put on duty at his place from setup (`Person.go_duty()`). The town's
    regroup and evacuation pass him by.
  - Each look, every M5 director runs `MissionDirector._keep_from_flight()` over its held people, with M4's
    `_recall_to(p, at, evacuating)` as the one recall rule. A whispered or recovering man the evacuation finds is kept in town.
  - People waiting for their time wait indoors (`_take_inside()`), untouchable.
  - The Knights are corps `KNIGHT`: the rally, the marshals and the investigations (`Crowd._investigate()`) never take them.
    The director sends each back to his post every look (Broken Lanterns' `_tend_knights()`).
- **No hidden losses** (M4 rules, kept):
  - A stray kill never makes a night silently unwinnable. Either it is counted with a plain loss reason, or the person's tag
    warns "DO NOT KILL" from the start.
  - A person leaving the town resolves at once.
  - A short loss (a man about to reach a gate) has a plain tag, hint and room to act.
  - Each mission has an evacuate-mid-mission test: one held person recovering and one whispered when the evacuation begins,
    both still at their places afterwards.
- **Relays** (M3 final review): The Sermon and The Relic Run keep their family's Temple reports, whose relay passes a report to a
  witness. A new `TempleReport.skip` (§7) makes their relays pass over anyone fleeing (`FLEE`) and anyone reserved. Mira's House
  and The Vigil Flame keep today's relay.
- **Hit-stop** (M3 ruling): scenarios that cast Smite or Heaven Splitter turn it off (`Impact.hitstop_enabled`): `bishop` and
  `armoury`.
- **Camera:** each `camera_at` keeps every key target, or its edge arrow, out of the dead zone under the left HUD stack (about
  230×70 px at the top-left; ground points 8-18 units west of the camera). Every moving target's tag has an edge arrow. Each
  mission's tests check its spots with the kit's `clear_of_stack()`.
- **Art:** text and drawn shapes only.
  - The Lantern Knights wear Broken Lanterns' gold tabard (corps `KNIGHT`).
  - The bishop, the preacher and the acolytes are clergy, as they are.
  - The garrison's armed men, the sermon's sentries, the relic's wardens are made `CitizenProfile.Role.WATCHMAN` (the watch
    cloak and lantern).
  - The relic cart is its carter, tagged; no cart is drawn. Every other stand-in is an existing building or person named by a
    map tag.
- **Colours** (as M2-M4): target gold `d8b23a`, places orange `ff9a3a`, watchers and danger red `c8342a`, the god's charges steel
  blue `8fb8e8`, not yet grey `9a948a`, clear green `7fc46a`, wishes soft blue `8fb8ff`. The Bishop's Knights are red (danger),
  not Broken Lanterns' steel blue, which means the god's charges everywhere else on the board.
- **The ★ mission:** The Procession keeps its director, rules and stretch on the board (×2.6). M5 does not touch it.

## 1. The Bishop (Assassinate, reused)

M2 lesson 1: one target in the open dies at about 1:00. So the bishop is never out of doors until the last step. He moves
unseen from refuge to refuge. Each refuge is an item on the chain, guarded by Knights who arrive with him. Burning it drives
him on. The Temple is his last refuge: set it alight to draw him into the square.

- **Brief:** "The bishop hides behind his Knights." / "Smoke him out. Kill him."
- **Card type:** Kill. **Id:** `bishop`.
- **Map** (east and north of the Temple; each dwelling is chosen by `_house_reached()`: the dwelling nearest the point whose
  door the street reaches, never reserved):
  - **His house:** the dwelling nearest (12.0, -6.8), at the north-east quarter's south edge. Tagged REFUGE.
  - **The chapter house:** the dwelling nearest (7.9, -12.3), behind the Temple's east side. Tagged REFUGE. (Task 2: the
    next nearest to the first guess (6.5, -13.0), by the quiet-places rule: that one's only door opens on a one-cell gap in a
    lane walled both sides, where its two Knights stood 1.0 apart, inside one Doom.)
  - **The Temple:** `TownLayout.TEMPLE`, its front door (0.8, -5.0) on the square. 200 hp; it burns.
  - **The Citadel's gate** (-10.5, -7.6): where he runs once drawn into the square. Reaching it is his escape.
  - **Stone tonight:** a refuge he is not yet in only shakes when struck and smothers any fire
    (`Structure.damage_filter`, cleared at teardown, as M3's posts). No refuge can be burned down ahead of him.
  - **Spacing:** his house to the chapter house about 8 units; the chapter house to the Temple's door about 10.
  - **The camera** rests at (2.0, -3.0) (the controller's ruling: checked against the real HUD stack, 240x165 px). His house
    is at the right, the chapter house at the top right, the Temple's door and the first half of his walk across the square
    clear of the stack. The Citadel's gate shows at the top-left corner (its arrow is left to M6's tag keep-out); its tag
    shows only once he runs for it.
- **Claims:** one cleric (the bishop), the two dwellings and the Temple. The Knights are added soldiers (below). No lay
  citizens. All three refuges are put in `EngineerManager.hands_off`, so the town's engineers never mend them.
- **Main objective:** kill the bishop.
  - **Won** the moment he dies, any way. A seen death makes the Knights cry murder and calls the bellkeeper (the Assassinate
    rule). It still wins. On the board the bell after the kill catches the night and loses the wishes, unless the god ascends
    or stops the bellkeeper first (M2 ruling 33).
  - **Lost** when:
    - he reaches the Citadel's gate after the Temple ("THE BISHOP REACHES THE CITADEL"), or leaves the town alive any way;
    - the Citadel sends for him at 5:00 ("THE KNIGHTS TAKE HIM AWAY");
    - dawn comes.
- **People and behaviour:**
  - **The bishop:** the cleric nearest the Citadel's gate, taken inside the Citadel at the start: untouchable, untagged as a
    person. At 1:00 he goes to ground in his house by the cellars ("THE BISHOP GOES TO GROUND"). Between refuges he moves
    indoors, unseen (The Informer's rule). He never walks a street until the Temple drives him out.
  - **The standing Knights:** two at each refuge's door from the start, on posts along its open face (`_open_door()`), 1.8
    apart, so one Silent Doom takes one. They are soldiers: Mind Whisper and Discord do not touch them (the engine's rule:
    soldiers keep their heads). They are held past fear. Only a kill removes them.
  - **His escort:** three Knights come with him to each refuge. They wait inside with him and come out at its door when he
    arrives, on posts 1.8 beyond the standing pair (the third 1.8 straight out from the door): the last refuge's survivors,
    topped up to three from the Citadel through the
    cellars. This is the work that cannot be done ahead.
  - **On guard:** a Knight alive, out of doors, within 2.5 of the refuge's door, at his post.
  - **The Knights' work:** while one stands on guard, a fire on his refuge is beaten out once it has burned 3 s (Spoiled
    Harvest's rule).
  - **Driven out:** the refuge he is in burns 12 s in all with no Knight on guard (the Temple: 14 s), or falls. Then he flees
    ("THE BISHOP FLEES HIS HOUSE"). His escort's survivors go back inside with him, unseen.
  - **The flight:** he reaches the next refuge 45 s after he was driven out, unseen, by the cellars. Until then that refuge is
    stone. The chain has no scheduled time: he moves only when driven.
  - **Relief:** a standing Knight who falls is replaced 30 s later by a new Knight walking from the Citadel's gate, while the
    bishop has not yet passed that refuge. At most six reliefs in a night. A refuge he has left sends its Knights home.
  - **Drawn into the square:** driven from the Temple, he comes out at its front door with every living Knight of the Temple;
    with fewer than two alive, two more come out with him (his last guard). They ring him at 1.4 (beyond one Doom of him, within sight). He walks on duty for the Citadel's
    gate at half pace (about 14 units, some 18 s). A loud power within 4 of him, or a fright, sends him running for it
    (`AssassinateDirector`'s alarm, with no hideout). His tag and the hint say so.
  - **The God-Resistant town:** Knights die in sight of each other, so the town soon reaches Local Emergency. The bell rings;
    it loses nothing here. At City Emergency the rite gathers clergy on the cathedral's steps; they are witnesses in the
    square and nothing more.
- **Timeline** (left alone):

  | Time | Event |
  |---|---|
  | 0:00 | "THE BISHOP". He is in the Citadel. Two Knights stand at each refuge's door. |
  | 1:00 | "The bishop goes to ground": in his house, his escort at its door |
  | +45 s after he is driven out | He reaches the chapter house, then the Temple |
  | 5:00 | "The Knights take him away": lost unless he is dead |
  | 6:30 | Dawn |

- **The clear:** first wait 45 + his house 20 (his escort's two: a Doom and a Smite; an Ember; 8 s alight) + 45 + the chapter
  house 20 + 45 + the Temple 22 (two Knights, an Ember, 10 s alight) + the square 8 (a Smite as he comes out) ≈ **205 s**. With
  nothing done ahead, each refuge's work rises by about 10 s (the standing pair): ≈ 235 s.
  - **Measured** (Task 2, scripted seeds 1-3: 196.7 / 186.5 / 177.2 s, median 186.5): first wait 60 + his house 5 (his escort
    comes out bunched at the door: one Smite takes them all and shakes the house, an Ember fells it) + 45 + the chapter house 5
    (the same) + 45 + the Temple 17-36 (one Smite on its Knights, an Ember, 14 s alight; the fire went out before he was driven
    in seeds 1 and 2 and was lit again) + the square 1 (a Doom as he comes out) ≈ 177-197 s. The clear is chain-bound: 150 s of
    it is the first wait and the two flights, at the 60 s and 45 s caps.
- **Longest waits:** 60 s to his first refuge, and 45 s of each flight. In both, the next refuge's standing Knights can be
  cleared in the last 25 s. The wait before the Temple is not a pure one (M4's hunt-captain lesson): its standing pair is there
  to work on.
- **Tags:**
  - BISHOP - IN THE CITADEL, grey, over the Citadel's gate, until 1:00.
  - The refuge he is in, gold, with an edge arrow: "REFUGE - GUARDED" while a Knight is on guard, "REFUGE - SET IT ALIGHT"
    when open, "REFUGE - BURNING 5" (seconds of the 12 left) while it burns unguarded.
  - The next refuge, grey, with an edge arrow: "NEXT REFUGE" while he is in the one before, "NEXT REFUGE - HE COMES IN 0:31"
    during his flight.
  - KNIGHT on each Knight on guard, red. A small red mark on one away from his post. A red diamond on a relief walking in.
  - In the square: BISHOP, gold, with an edge arrow; BISHOP - RUNNING once alarmed. CITADEL, red, with an edge arrow. A red
    diamond on each living person who would see a Doom on him (`witnesses()`).
- **Hint phases:**

  | Phase | Line |
  |---|---|
  | `waiting` | He reaches his next refuge in {n} s. Kill its Knights (red) shortly before he comes. ({n}: the seconds to his next refuge, in the Citadel or in a flight) |
  | `guarded` | His Knights (red) beat out fire. Kill every one. Whispers and Discord do not touch a Knight. |
  | `open` | No Knight stands. Set the refuge (gold) alight before a new Knight comes. |
  | `burning` | It burns. Keep it burning: his Knights (red) put out a fire they stand by. |
  | `square` | He is in the square and makes for the Citadel (red). Kill him before he gets in. |
  | `running` | Alarmed, he runs for the Citadel (red). Kill him now. |

  The main line, (none): "Burn each refuge the bishop hides in (gold), once its Knights (red) are dead. The Temple last: then
  kill him in the square."
- **HUD:** "Kill the bishop: refuges 1 / 3" (from `hud_line()`); in the square, "Kill the bishop, he makes for the Citadel";
  the deadline row "Knights come 2:10".
- **Tour:**
  1. "His house. The bishop goes to ground here at 1:00, his Knights at the door."
  2. "The chapter house, his next refuge. Burn each one to drive him on."
  3. "The Temple, his last refuge. Set it alight to draw him into the square."
- **Mission tags:** `burns_temple`. It keeps the wish "Save the heretic from the pyre" (§6) away: its march ends at the Temple's
  door.
- **Pool:** every power.
- **Results:** "THE BISHOP IS DEAD" (`bishop`), "THE BISHOP REACHES THE CITADEL" (`bishop_safe`), "THE KNIGHTS TAKE HIM AWAY"
  (`bishop_taken`).
- **Numbers** (tuned, Task 2): ARRIVE_AT 60, CHAIN 45, STANDING 2, ESCORT 3, POST_GAP 1.8, GUARD_REACH 2.5, SMOTHER_AFTER 3,
  DRIVE_OUT 12 (Temple 14), RELIEF_AFTER 30, RELIEFS 6, RING_R 1.4, BISHOP_PACE 0.5, TAKEN_AT 300. Tuned in this order as the
  scripted clear missed 180-240 s (first guesses 158.3 / 158.2 / 166.6 s): CHAIN (30-45; already at 45), ARRIVE_AT (30-60) 45 ->
  60 (173.2 / 173.2 / 173.1), ESCORT (1-3) 2 -> 3 (183.0 / 173.2 / 173.2), DRIVE_OUT (6-12) 8 -> 12, the Temple's 10 -> 14 with it
  (196.7 / 186.5 / 177.2: the gate holds). RELIEF_AFTER (20-30) untouched.
- **Scripted policy** (`--scenario=bishop`, loadout Silent Doom, Smite, Ember: 3 DP; hit-stop off). Every
  LOOK_FRAMES, the first that applies:
  1. The bishop is out of doors: Doom him, else Smite him (plan decision 175: a Smite is cast before it strikes, and its alarm
     sends him running out of its reach; Silent Doom is quiet).
  2. The refuge he is in has a Knight on guard: Doom the one with no one else within 0.8; else Smite one.
  3. That refuge is open and not burning: Ember it (Smite it if Ember is cooling).
  4. He is in flight, or his next arrival is within 25 s: Doom that refuge's standing Knights, one at a time.
  5. A relief walks toward a refuge he has not passed, and Doom is ready: Doom him.

  Expected clear: about 3:25 (measured: median 3:06).
- **Evacuate-mid-mission test:** the evacuation begins while he is in flight: the Knights stay at their posts, the bishop
  stays inside, and he still arrives on time.
- **How it differs from The Tax Collector and The Informer** (M2 lesson 10):
  - **One target, never in the open** until the end: the paced items are his refuges, not his walk.
  - **Knights, not soldiers or company:** they cannot be whispered or confused. Only a kill removes them.
  - **Fire is the tool:** each refuge must burn, and the Temple's fire draws him into the square.

## 2. The Armoury (Raze, reused)

M2 and M4 lesson: three open targets fall in about 1:30. So each target musters at its horn on M4's stages (the controller's
ruling, replacing Decision 137's seals): every blow lands from the start, but fire on a target not mustering goes out, and its fall
counts only when its horn sounds. Armed men guard each target from the start, and while one stands guard the target is sealed. The
horn's twist is that the garrison arms faster each minute.

- **Brief:** "The muster horn arms the garrison." / "Destroy the armoury and two barracks."
- **Card type:** Destroy. **Id:** `armoury`.
- **Map:**
  - **The north barracks:** the north tavern by the Citadel's lane, `TownLayout.TAVERNS[0]` (centre (-8.4, -6.85)), tagged
    BARRACKS: the Citadel guard's billet. 50 hp; it burns. If a wish has set it aside, the west tavern (`TAVERNS[1]`).
  - **The gate barracks:** the Main Gate's east tower, `GATE_TOWERS[1]` (centre (4.5, 15.7)), tagged BARRACKS: the gate
    guard's quarters. 180 hp; stone, it does not burn. Only blows bring it down. If a wish has set it aside, the west tower.
  - **The armoury:** the barracks shed, `TownLayout.BARRACKS` (centre (12.5, 4.85)), tagged ARMOURY. Its racks and barrels
    already read as an armoury. 150 hp; it burns.
  - The three stand 13-26 units apart: one Heaven Splitter cannot reach two.
  - **The camera** rests at (-5.5, -4.5). The north barracks sits just above the centre. The gate barracks' and the armoury's
    tags point from the bottom edge. None sits in the real HUD stack's corner (`Kit.STACK`, 240 x 165 px).
- **Claims:** 23 lay citizens made watchmen: a night watch of two and a squad of three at each target, and a reserve of eight
  inside the Citadel's gate. The three targets are fixed buildings; a reserved tavern or tower is skipped (above). All three go
  in `EngineerManager.hands_off`. No soldiers.
- **Main objective:** destroy all three.
  - **Razed:** a target that falls, or burns 12 s in all after its horn. A fall before its horn counts when the horn sounds: still
    down then, it is razed at once. It stays razed.
  - **Won** the moment the third is razed.
  - **Lost** when the garrison marches at 5:00 ("THE GARRISON MARCHES"), or at dawn.
- **People and behaviour:**
  - **Not mustering yet** (M4's stages, `RazeDirector._spoilable()`): before its horn a target takes every blow, but any fire on
    it is put out at once and its fall is judged only at its horn. Tagged grey with its horn's time.
  - **The muster horn** (the stages):
    - the north barracks at 0:40 ("THE MUSTER HORN: THE NORTH BARRACKS TURNS OUT");
    - the gate barracks at 1:50, or 40 s after the north barracks is razed;
    - the armoury at 3:00, or 40 s after the gate barracks is razed ("THE MUSTER HORN: THE GARRISON ARMS").

    At its horn a target **musters**.
  - **The night watch:** two armed men at each target from the start, on posts along its open face (`_open_door()` from the
    nearest town gate; a tower's town side), 1.8 apart. Every post is kept within 2.5 of the target, reached on foot from its
    face, and more than two Silent Doom radii from the others (The Crown's Bread's `_spread()`), so one Silent Doom takes one.
  - **The squad:** at its horn, three more armed men come out, each at his own post 1.8 beyond the night watch (M4's fix round 1
    ruling: never bunched at one door, where one strike would take them all). Before that they wait inside, untouchable. They
    are the work that cannot be done ahead.
  - **Armed:** an armed man on his post is held deaf to a whisper and past fear (renewed each look, as M4's bound prisoner: plan
    decision 94). Discord holds him for a moment at most before he is set back. Only a kill removes him.
  - **Guarded:** while an armed man stands on guard (alive, out of doors, within 2.5 of the target, not frightened, sheltering or
    whispered), the target is sealed, before or after its horn: blows shake it and its fire is put out. With none on guard it is
    open. Seconds it burned stay counted (`burned()`; nothing calls `forget_burn()`), so a guard only pauses the fire.
  - **Return and relief:** a man off his post and calm again walks back 20 s after he left. A fallen one is replaced 30 s after
    he fell from the reserve (the director's own men, not the nearest citizen): out of the Citadel's gate and running to the
    post. A target already down gets none; with the reserve spent, or no way from the gate to the post, the relief backs off and
    is tried again 30 s later.
  - **Arming faster each minute:** from each horn, while a target musters, one armed man marches out of the Citadel's gate every
    REINFORCE seconds to the first mustering target, on a second row of posts. REINFORCE falls with the clock: 40 s before 2:00,
    30 s in the third minute, 20 s in the fourth, 12 s from 4:00. They come from the Citadel, not the armoury, so the armoury
    felled early never stops them (the controller's ruling); the chain still paces them. With the reserve spent, none come.
  - **Razed:** its men go home (Spoiled Harvest's `_release()`). Reinforcements and reliefs still running in walk back into the
    Citadel's gate, to the reserve.
  - **Held:** every armed man, the reserve and those walking back are kept from the town's flight by the one rule
    (`MissionDirector._hold_all()`); one away when the evacuation begins is recalled at once.
  - **The God-Resistant town:** the fire brigade answers a fire on a target, as it always does. Taverns and the barracks shed
    are shelters (`ShelterManager`); anyone sheltering in one flees its fire, as in any house.
- **Timeline** (left alone):

  | Time | Event |
  |---|---|
  | 0:00 | "THE ARMOURY". All three take blows; none musters; the night watches stand. |
  | 0:40 | "The muster horn": the north barracks turns out |
  | 1:50 | "The muster horn": the gate barracks (sooner: 40 s after the north barracks is razed) |
  | 3:00 | "The muster horn": the garrison arms at the armoury (sooner: 40 s after the gate barracks is razed) |
  | 5:00 | "The garrison marches": lost unless all three are razed |
  | 6:30 | Dawn |

- **The clear** (measured, scripted seeds 1-3: 235.7 / 214.4 / 200.8 s, median 214.4): first wait 40 + the north barracks about
  30 (three squad men and two reliefs for the night watch cleared ahead: Dooms and Smites; an Ember; a Smite) + 40 + the gate
  barracks about 14 (three squad men; one Heaven Splitter through it) + 40 + the armoury about 50 (three squad men, the night
  watch's reliefs running in from the Citadel, a reinforcement at the 20 s rate, an Ember, 12 s alight) ≈ **214 s**. The first
  sum was 200 s.
- **Longest waits:** 40 s to the first horn, and 40 s between a target razed and the next horn. In both, the next night watch can
  be cleared in the last 25 s (the scripted player's longest stretch between casts: 16 s).
- **Tags:**
  - Each target not razed, with an edge arrow:
    - not mustering: "BARRACKS - MUSTERS BY 1:50" (the sooner time), grey; once fallen, "BARRACKS - DOWN, COUNTS AT 1:50";
    - mustering, guarded: "ARMOURY - GUARDED", gold;
    - mustering, open: "ARMOURY", gold; burning: "ARMOURY - BURNING 7" (seconds of the 12 left), orange.
  - ARMED on each armed man on guard, red. A small red mark on one away from his post. A red diamond on a reinforcement or relief
    running in.
- **Hint phases:**

  | Phase | Line |
  |---|---|
  | (none) | Kill a target's armed men (red), then destroy it (gold): the north barracks, the gate barracks, the armoury. |
  | `not_yet` | Not mustering yet (grey): fire goes out, and a fall counts when its horn sounds. Kill its night watch (red) shortly before. |
  | `guarded` | Armed men (red) guard it: it takes no harm. Kill every one. Whispers do not move an armed man. |
  | `open` | No guard stands. Destroy it now: more armed men march from the Citadel, faster each minute. |
  | `stone` | The gate barracks is stone: blows, not fire. |

- **HUD:** the main row "Raze the garrison 1 / 3", and while a target musters and the reserve lasts "Raze the garrison 1 / 3,
  armed men every 30 s" (`RazeDirector.hud_line()`, plan decision 182); the deadline row "Garrison marches 2:10".
- **Tour:**
  1. "The north barracks. The muster horn calls it at 0:40."
  2. "The gate barracks, by 1:50. It is stone: blows, not fire."
  3. "The armoury, last. It arms the garrison, faster each minute."
- **Mission tags:** `razes_barracks`. It keeps "Free the pressed man" away: that wish marches its man to the barracks shed's
  door, the armoury here.
- **Pool:** every power.
- **Results:** "THE GARRISON IS BROKEN" (`garrison`), "THE GARRISON MARCHES" (`marches`).
- **Numbers** (tuned): STAGE_AT 40 / 110 / 180, CHAIN 40, NIGHT_WATCH 2, SQUAD 3 (round 1: 2 -> 3), POST_GAP 1.8, GUARD_REACH
  2.5, SPOIL_SECONDS 12, RETURN_AFTER 20, RELIEF_AFTER 30, REINFORCE 40 / 40 / 30 / 20 / 12 (by the minute), RESERVE 8,
  MARCH_AT 300. Tune in this order if the scripted clear misses 180-240 s: SQUAD (1-3), STAGE_AT[0] (30-45), CHAIN (30-45),
  REINFORCE, SPOIL_SECONDS (10-15).
- **Scripted policy** (`--scenario=armoury`, loadout Silent Doom, Smite, Ember, Heaven Splitter: 5 DP; hit-stop off). Every
  LOOK_FRAMES, the first that applies:
  1. The mustering target has an armed man on guard:
     - Smite is ready and one stands within 0.7 of the target: Smite him (he falls and the target takes 45);
     - Doom is ready: Doom the one with no one else within 0.8 (else the first).
  2. The mustering target has none on guard:
     - a barracks or the armoury not burning: Ember it (Smite it if Ember is cooling);
     - the gate barracks: Heaven Splitter through it if ready, else Smite it.
  3. The next horn is within 25 s: clear that target's night watch as in step 1, Doom only.
  4. A reinforcement or relief runs toward the mustering target, and Doom is ready: Doom him.

  Measured clear: 3:34 (median).
- **Evacuate-mid-mission test:** the evacuation begins while the gate barracks musters: a recovering night watch man sent
  running is back on his post at the next look, a whispered reinforcement's owed flight is ended and he runs on to his post, the
  squad holds its posts, and the reserve stays inside the Citadel's gate.
- **How it differs from Spoiled Harvest and The Crown's Bread** (M2 lesson 10):
  - **Staged, with guards that seal:** M4's stages (a fall ahead counts at the horn; fire waits for it), and a target is sealed
    while an armed man guards it, before or after its horn.
  - **Armed men, not watchmen or engineers:** deaf and fearless on their posts, killed only. Nobody mends or rebuilds.
  - **The pressure grows with the clock:** reinforcements come faster each minute, from the Citadel. Stalling is punished, not
    working ahead.
  - **A stone target:** the gate barracks needs blows, the other two fire.

## 3. The Sermon (Convert, reused)

Mira's House's rules: a citizen whispered to the holy place's door goes in unseen, reads, and comes out a Believer; a Faithful
who sees turns him away and runs to the Temple; a report delivered fills the Gaze. M3 lesson 1: the believers must come on the
chain, so the preacher's crowd comes in waves. The twist: his words hold his crowd until the god silences him.

- **Brief:** "A preacher holds the poor quarter." / "Silence him. Turn eight of his crowd."
- **Card type:** Cult. **Id:** `sermon`.
- **Map** (the south-west quarter, district 6, far from the Temple):
  - **The pulpit:** the south-west well, `TownLayout.WELLS[2]` (centre (-8.85, 13.75)). Tagged PREACHER on him, not on the well.
  - **The god's house:** the dwelling nearest (-14.0, 10.4) by the west wall, more than HEAR (5) from the pulpit, whose door the
    street reaches. Tagged GOD'S HOUSE and outlined (Mira's house tag). Its door faces a quiet lane.
  - **The Temple's door** (0.8, -5.0): where reports run, about 21 units of street away.
  - **Where the waves come from:**
    1. round the pulpit itself (the first wave, there in about 10 s);
    2. the west quarter (-11.0, 3.0);
    3. the south quarter (-2.0, 12.0);
    4. the long west street (-12.0, 6.0).
  - **The camera** rests at (-9.0, 9.5). The pulpit is just below the centre, the god's house at the left below the HUD stack,
    the second and fourth sources above the centre, the third at the lower right. The Temple's tag points from the right edge.
- **Claims:** 12 listeners (four waves of three), the preacher and two acolytes (clergy), two sentries and their reliefs (lay,
  made Faithful and watchmen), the god's house. The clergy and eight lay citizens spread through the rest are Halcyon's
  Faithful (Mira's `_choose_faithful()`). No soldiers.
- **Main objective:** turn eight of his crowd.
  - **Won** the moment the eighth Believer walks out of the god's house.
  - **Lost** when:
    - the sermon ends at 5:00 ("THE SERMON ENDS");
    - too few are left to turn: Believers plus living unturned listeners fall below eight ("THE FLOCK IS SCATTERED");
    - Halcyon's Gaze fills ("THE LANTERN LOOKS");
    - dawn comes.
- **People and behaviour:**
  - **The preacher:** the cleric nearest the pulpit, on duty at the well, preaching. His two acolytes (the next nearest clergy)
    stand 1.0 either side of him: within one Discord of him (radius 1.2), beyond one Doom (radius 0.8). All three are Faithful.
  - **Rapt:** while he preaches (alive, out of doors, not whispered, confused or frightened), every listener within HEAR (5) of
    him is rapt. A rapt listener is held deaf to a whisper and past fear (renewed each look, as plan decision 94), and on duty, so
    no lure takes him. The HUD's banner on a refused whisper: "THEY HEAR ONLY HIM".
  - **Silenced:**
    - whispered away, confused or frightened: silent while held. Back on his feet he walks back and preaches again ("THE
      PREACHER TAKES UP HIS SERMON");
    - dead: silent for good ("THE PREACHER IS SILENT"). No one takes his place.
    - A kill his acolytes see sends them running to the Temple (a report). Discord holds all three; a Doom on him then adds a
      seen death's share to the Gaze (10, `Crowd.nearest_witness()` counts the held) but sends no report.
  - **The waves:** all 12 listeners are appointed as the night begins, the three nearest each source, and wait on duty at their
    source, held fearless (Market Panic's rule), until their wave walks in:
    - the first at 0:00;
    - the second at 1:35, or 45 s after the first is spent;
    - the third at 3:05, or 45 s after the second is spent;
    - the fourth at 4:20, or 45 s after the third is spent.

    A wave is **spent** when each of its listeners believes, is dead or is gone. Each walks in on duty (about 15 s) and takes a
    place on a ring 2.5-3.5 from the preacher (outside his witnesses' 2 units). On the way he is not yet within HEAR: he can be
    whispered.
  - **Turning:** a listener whispered to the god's house goes in unless a Faithful within 3 of its door sees (Mira's
    `_doors()`): then he is turned away, the seer runs to the Temple, and the listener walks back to the pulpit. Inside he reads
    8 s and comes out a Believer. Several may read at once.
  - **The Believers stay:** each walks on duty to a ring 2.0 from the god's door and stands there, held, until the night is
    won. So the evacuation cannot carry a Believer out of the count. Tagged green.
  - **The sentries:** two Faithful watch the god's house from the start, on duty 1.5 either side of its door (3.0 apart; each
    sees the door). Whispered, confused or frightened, one walks back 20 s after he is calm. A fallen one is replaced 30 s later
    by the nearest free lay citizen with a way to the post (M4's `_lay_reaching()`), made Faithful and a watchman. At most six
    reliefs.
  - **Reports:** Mira's `TempleReport`. A report delivered fills the Gaze. A carrier killed unseen ends it; a seen kill passes
    it to a witness (never one fleeing or reserved: `TempleReport.skip`).
  - **The Gaze:** Mira's `GazeMeter`. A seen death adds 10; a delivered report or the bell fills it.
- **Timeline** (left alone):

  | Time | Event |
  |---|---|
  | 0:00 | "THE SERMON". The first wave walks to the well; the sentries watch the god's house. |
  | 1:35 | "More come to hear him", from the west quarter (sooner: 45 s after the first wave is spent) |
  | 3:05 | "More come to hear him", from the south quarter (sooner: 45 s after the second is spent) |
  | 4:20 | "More come to hear him", from the long west street (sooner: 45 s after the third is spent) |
  | 5:00 | "The sermon ends": lost unless eight believe |
  | 6:30 | Dawn |

- **The clear:** the first wave walks in 10 + silence him and turn three 45 (Discord and a Doom on the preacher; the sentries;
  three whispers 8 s apart; the walk and the reading) + 45 + the second wave walks in 15, whispered on the way, + 30 + 45 + the
  third walks in 15 + two more 20 ≈ **225 s**. Silencing him for good saves about 10 s a wave: ≈ 210 s. The fourth wave is slack
  for mistakes, not a needed item.
- **Longest waits:** 45 s between a wave spent and the next walking in. Its walk-in (15 s) can be worked on. The sentries'
  reliefs and the reports are work in every wait. There is no wait at the start.
- **Tags:**
  - GOD'S HOUSE, gold, outlined, with an edge arrow; its door CLEAR (green) or WATCHED (red), as Mira's.
  - PREACHER, red, while he preaches; PREACHER - SILENT, grey, while held. The acolytes are red diamonds.
  - A gold diamond on each listener not yet turned: rapt ones with a small red mark; walkers and the waiting at their sources too.
  - SENTRY on each sentry on guard, red. A red diamond on a relief walking in.
  - NEXT WAVE and the seconds to it (the sooner time) at its source, orange, with an edge arrow.
  - Each report's runner, red, with an edge arrow; TEMPLE, red, with an edge arrow while one runs.
  - The Believers, green.
- **Hint phases:**

  | Phase | Line |
  |---|---|
  | (none) | Silence the preacher (red), then whisper his crowd (gold) to the god's house unseen. Eight must believe. Do not kill them. |
  | `rapt` | He preaches: his crowd hears only him. Discord, a whisper or a fright silences him for a while; death, for good. |
  | `watched` | Sentries (red) watch the door: anyone seen going in is turned away and reported. Remove them first. |
  | `report` | A Faithful runs to the Temple. Stop him before he gets there, unseen. |
  | `coming` | More come to hear him (gold). Whisper them on the way, before they come within his voice. |

  The sermon hint also warns: "Four seen deaths in a district ring the bell, and the bell fills the Gaze."
- **HUD:** "Turn the crowd 3 / 8" (`BelieversObjective`'s label), "Gaze 30%", the deadline row "Sermon ends 2:10".
- **Tour:**
  1. "The preacher at the south-west well. While he preaches, his crowd hears only him."
  2. "The god's house. Lead eight of his crowd here, unseen by the Faithful."
  3. "The Temple. A Faithful who sees you runs here."
- **Mission tags:** none.
- **Pool:** every power.
- **Results:** "THE CROWD BELIEVES" (`sermon`), "THE SERMON ENDS" (`sermon_over`), "THE FLOCK IS SCATTERED" (`flock`); the Gaze's
  "THE LANTERN LOOKS" (`gaze`, the family's own).
- **Numbers** (first guesses): NEED 8, WAVES 4 × 3, WAVE_AT 0 / 95 / 185 / 260, CHAIN 45, HEAR 5, RING 2.5-3.5, ACOLYTE_OFF 1.0,
  READ 8, SIGHT 3, SENTRIES 2, SENTRY_OFF 1.5, RETURN_AFTER 20, RELIEF_AFTER 30, RELIEFS 6, FAITHFUL 8 (lay), BELIEVER_RING
  2.0, SERMON_ENDS 300. Tune in this order if the scripted clear misses 180-240 s: CHAIN (30-45), WAVE size (3-4, NEED staying 8),
  WAVE_AT[1] (75-110), READ (6-10), HEAR (4-6).
- **Scripted policy** (`--scenario=sermon`, loadout Mind Whisper, Discord, Silent Doom, Will-o'-Wisp: 6 DP). Every LOOK_FRAMES,
  the first that applies:
  1. The preacher preaches and Discord is ready: Discord on him (it holds his acolytes too).
  2. The preacher and both acolytes are held, and Doom is ready: Doom him (silenced for good).
  3. A report runs and Doom is ready: Doom the carrier where the kill would go unseen.
  4. A sentry stands on guard: Doom him when no one else is within 2 (they stand 3.0 apart), else whisper him eight units away.
  5. No sentry on guard and Whisper is ready: whisper the unturned listener nearest the god's house, if he is not rapt (still
     walking in, or the preacher silent), to its door.
  6. A sentry's relief walks in and Doom is ready: Doom him.

  Will-o'-Wisp is a spare: a lure on the walkers of a wave. Expected clear: about 3:35.
- **Evacuate-mid-mission test:** the evacuation begins with a listener whispered toward the house and a sentry recovering: the
  listener reaches the door, the sentry walks back, the waiting waves and the Believers stay.
- **How it differs from Mira's House and First Prayers** (M2 lesson 10):
  - **A man holds the crowd:** the preacher must be silenced before anyone in earshot can be whispered.
  - **Waves on the chain:** eight Believers, from crowds that come in turn.
  - **The Faithful watch the door:** sentries, with returns and reliefs, not passers-by.
  - **A count of the living:** too few left to turn loses at once, with a plain reason.

## 4. The Relic Run (Steal, reused)

The Vigil Flame's rules: a mortal hand takes a sacred thing unseen and carries it to a drop-off under Halcyon's Searchlight.
Here the relic rides a cart across the town to the Citadel, and its reliquary opens only while the cart halts at a checkpoint for
the watch's count. The heist has two steps: the boy slips into the cart at the first halt and picks the reliquary's lock on the
way, then swaps the relic at the second.

- **Brief:** "The Temple's relic rides to the Citadel." / "Swap it while the cart halts."
- **Card type:** Cult. **Id:** `relic_run`.
- **Map:**
  - **The route** (about 59 units): the Temple's door (0.8, -5.0); east along the cathedral street to the long east street
    (9.5, -5.1); south to the east-west street (9.5, 9.0); west to the long west street (-6.0, 9.0); north to (-6.0, -5.1); west
    to the Citadel's lane (-10.5, -5.1); up to the Citadel's gate (-10.5, -7.6). It keeps off the market and the gate plazas.
  - **The checkpoints:** the east watch-house at (9.5, -5.1) and the west watch-house at (-6.0, 9.0). Tagged CHECKPOINT.
  - **The drop-off:** your believers' house, the dwelling nearest (12.5, -12.0) in the north-east quarter whose door the street
    reaches. About 30 units of street from the west watch-house. Tagged BELIEVERS' HOUSE.
  - **Pip:** the lay citizen nearest (6.0, 2.5), east of the market, set down there. About 8 units from the east watch-house.
  - **The camera** rests at (4.0, -3.0). The Temple's door is just above the centre, the east watch-house at the right, Pip below
    the centre. The drop-off's tag points from the right edge, the west watch-house's from the left edge below the HUD stack. The
    CITADEL tag shows from the second halt on.
- **Claims:** 8 lay citizens: Pip, the carter, the cart's two escorts and two wardens at each checkpoint; reliefs as they are
  needed. The escorts and wardens are made watchmen and Faithful. One dwelling (the drop-off). No soldiers. The clergy and twelve
  lay citizens spread through the rest are Halcyon's Faithful.
- **Main objective:** swap the relic and bring it to your believers' house.
  - **Won** the moment Pip reaches its door with the relic.
  - **Lost** when:
    - the cart reaches the Citadel's gate with the relic ("THE RELIC REACHES THE CITADEL"), or leaves the town with it;
    - Pip dies, or leaves the town ("THE BOY IS DEAD"; his tag reads PIP - DO NOT KILL from the start);
    - Halcyon's Gaze fills ("THE LANTERN LOOKS");
    - dawn comes.
- **People and behaviour:**
  - **The cart:** the carter (a resident) walks the route on duty at 0.42 of a citizen's duty pace, his two escorts beside him
    (`VigilRoute`, The Vigil Flame's walk with its bearer and acolytes, 1.4 apart: one Discord at their midpoint holds both). It
    sets out at 0:35. The relic is in its locked reliquary; no hand can reach it while the cart moves.
  - **A dead driver:** the first escort takes the reins (`VigilRoute.pass_flame`). With all three dead the cart stands where the
    last fell, its reliquary locked. A new carter and escorts come from the Temple 30 s later and take it on. Killing the cart's
    people stalls the run; it never opens the reliquary.
  - **The halt:** at each checkpoint the cart halts (`VigilRoute.busy`, no change to the walk itself) and the reliquary opens for
    the watch's count. The count takes 20 s in all with one of the watch (the checkpoint's two wardens or the cart's escort) at
    the cart and not held. The halt ends when the count is done, or after 50 s at most. Then the reliquary closes and the cart
    goes on.
  - **Watched:** someone of the watch, or any Faithful, within 2 of the cart and not held (Mira's `BLIND`).
  - **Step one, aboard:** Pip whispered to within 1.0 of the halted cart climbs into its straw once no one watches for 2 s. He
    is hidden: indoors, untouchable, carried with the cart. A whispered Pip by a watched cart waits beside it, "PIP - WAITING".
  - **The lock:** aboard, Pip picks the reliquary's lock while the cart rolls on ("RELIC CART - PIP AT THE LOCK"). The leg
    between the halts is long enough for it.
  - **Step two, the swap:** at the next halt, Pip swaps the relic once no one watches: 4 s unwatched in all. Then he slips out
    at the cart's side with the relic, and a false relic rides on ("THE RELIC IS TAKEN").
  - **One halt, both steps:** if Pip was not aboard when the first halt ended, at the second halt he can still climb in, pick the
    lock and swap in the same window: 14 s unwatched in all (2 to climb in, 8 at the lock, 4 at the swap), against four of the
    watch. It is the hard way; the tour and the hint name the first halt as the way in.
  - **Unseen by rule:** Pip only boards and only swaps while no one watches, so the theft is never seen. Watchers held,
    whispered off or dead clear the way.
  - **The carry** (The Vigil Flame's phase 2): Pip makes for your believers' house on duty at half pace. The Searchlight wakes
    at the swap (one beam, a second 30 s on, a Will-o'-Wisp a decoy, any cast but a whisper a noise in the last 20 s). A beam
    touching Pip adds 50 to the Gaze; a Faithful it touches stops and prays. Pip holds where a whisper leaves him and then takes
    his errand up again.
  - **The checkpoints' wardens:** two at each watch-house from the start, on duty 2.6 apart (one Doom takes one). At a halt they
    step up to the cart for the count. Whispered or confused, one walks back 20 s after he is calm; a fallen one is replaced 30 s
    later by the nearest free lay citizen with a way to the post (M4's `_lay_reaching()`). At most six reliefs.
  - **Reports and the Gaze:** The Vigil Flame's (`FlameGaze`, `TempleReport`). A seen death adds 10. A report runs only from a
    seen death near a Faithful's eyes; the theft itself sends none.
  - **The God-Resistant town:** the bell fills the Gaze. Four seen deaths in a district bring it within 5 s.
- **Timeline** (left alone):

  | Time | Event |
  |---|---|
  | 0:00 | "THE RELIC RUN". The cart waits at the Temple's door. |
  | 0:35 | "The relic sets out" |
  | ~0:50 | "The cart halts at the east watch-house": the reliquary open 20-50 s |
  | ~1:55 | "The cart halts at the west watch-house" (left alone; later by as long as the first halt was held) |
  | ~2:50 | The cart reaches the Citadel's gate: lost |
  | 6:30 | Dawn |

- **The clear:** the first halt at 0:50 + Pip aboard 15 + the count done and the cart on 10 + the leg to the second halt 44 + the
  swap 10 + the carry 60 (30 units at about 0.8 a second, and the light dodged) ≈ **190 s**. The one-halt way is about as quick
  (the cart passes the first halt in 20 s) but needs 14 s unwatched against the whole watch; the gate's policy takes the two
  steps.
- **Longest waits:** about 50 s to the first halt; Pip must be brought and the first wardens cleared in it. About 44 s of the
  cart's leg between the halts, with the second wardens to clear. Each halt is a window of 20-50 s. No wait reaches 60 s.
- **Tags:**
  - RELIC CART, gold, with an edge arrow, on the carter: "RELIC CART - HALTED 34" (seconds of the 50 left) while halted;
    "RELIC CART - PIP AT THE LOCK" while he picks it, "RELIC CART - PIP ABOARD" once it is open. Once swapped: no tag (a false
    relic).
  - PIP - DO NOT KILL, steel blue, with an edge arrow; PIP - WAITING while he waits by a watched cart; PIP - THE RELIC once he
    carries it.
  - CHECKPOINT at the next watch-house, orange, with an edge arrow.
  - WARDEN on each warden, red; ESCORT on each escort, red. A red diamond on any other Faithful who watches the cart.
  - BELIEVERS' HOUSE, orange, with an edge arrow. CITADEL, red, with an edge arrow, from the second halt on.
  - Report runners and the Temple, as The Vigil Flame's.
- **Hint phases:**

  | Phase | Line |
  |---|---|
  | (none) | Bring Pip (blue) to the cart's first halt. He slips aboard there, and swaps the relic at the next. |
  | `moving` | The cart (gold) moves. Its reliquary opens only at a checkpoint. Clear the next one's wardens (red) shortly before. |
  | `watched` | The cart halts, watched (red). Hold or remove the watch: Pip only works unseen. |
  | `aboard` | Pip is aboard and picks the lock. At the next halt, clear the watch so he can swap the relic. |
  | `carry` | Pip has the relic. Keep him out of the light on his way to your believers' house (orange). |
  | `citadel` | The cart makes for the Citadel (red). This is the last halt. |

  The relic hint also warns: "Four seen deaths in a district ring the bell, and the bell fills the Gaze."
- **HUD:** "The relic: in its cart", "The relic: Pip at the lock", "The relic: Pip aboard", "Swapping 2 / 4 s", "The relic to your believers: 18", "Gaze 50%"
  (from `FlameObjective`, its label and reasons given in `_init()`, its line from the director's `hud_line()`).
- **Tour:**
  1. "The relic cart at the Temple. It halts at two checkpoints, where its reliquary opens."
  2. "Pip. Bring him to the first halt: he slips aboard there and swaps the relic at the second."
  3. "Your believers' house. Pip must bring the relic here."
- **Mission tags:** none.
- **Pool:** every power.
- **Results:** "THE RELIC IS OURS" (`relic`), "THE RELIC REACHES THE CITADEL" (`relic_kept`), "THE BOY IS DEAD" (`pip`); the
  Gaze's "THE LANTERN LOOKS" (`gaze`); dawn's own.
- **Numbers** (first guesses): SET_OUT_AT 35, CART_PACE 0.42, COUNT 20, HALT_MAX 50, BOARD 2, LOCK 8, SWAP 4, CART_REACH 1.0,
  WATCH 2.0, PIP_PACE 0.5, ESCORTS 2, WARDENS 2, WARDEN_GAP 2.6, RETURN_AFTER 20, RELIEF_AFTER 30, RELIEFS 6, FAITHFUL 12 (lay); the
  Searchlight's as The Vigil Flame's. Tune in this order if the scripted clear misses 180-240 s: the drop-off's point (25-35
  units from the second halt), CART_PACE (0.35-0.5), COUNT (15-25), SET_OUT_AT (25-45). HALT_MAX stays under 60.
- **Scripted policy** (`--scenario=relic`, loadout Mind Whisper, Discord, Silent Doom, Will-o'-Wisp: 6 DP). Every LOOK_FRAMES,
  the first that applies:
  1. Before the first halt, Pip more than 1.5 from where the cart will halt: whisper him up to 10 units toward it.
  2. The next halt within 25 s: Doom each of that checkpoint's wardens standing alone.
  3. The cart halts, Pip within reach or aboard, and it is watched:
     - both escorts within 1.2 of one point and Discord is ready: Discord there;
     - a warden alone and Doom is ready: Doom him;
     - else whisper one watcher eight units away.
  4. The cart halts, unwatched, Pip beside it and not yet aboard (or not yet swapped): whisper him to the cart.
  5. Pip carries the relic:
     - a beam will cross his next stretch within 3 s and Wisp is ready: Wisp six units from him, away from his road;
     - a beam is on him or about to be, and Whisper is ready: whisper him three units out of it.

  Expected clear: about 3:10.
- **Evacuate-mid-mission test:** the evacuation begins while the cart walks its second leg with Pip aboard: the cart walks on, Pip
  stays hidden, the second checkpoint's wardens hold their posts; and again while Pip carries the relic (he walks on).
- **How it differs from The Vigil Flame** (M2 lesson 10):
  - **A journey, not a loop:** the relic crosses the town once, and its reliquary opens only at two halts.
  - **Two steps:** aboard at one halt, the lock on the way, the swap at the next.
  - **Unseen by rule, not by punishment:** the boy waits for his moment, so the work is clearing the watch, not hoping.
  - **He is there from the start:** no boy who comes at 0:50.

## 5. Tier 4 on the board

- **The tab:** `TierBook.MISSIONS[3]` becomes `["procession", "bishop", "armoury", "sermon", "relic_run"]`: the ★ mission first,
  as on the other tabs.
- **Types:** `"bishop": "Kill"`, `"armoury": "Destroy"`, `"sermon": "Cult"`, `"relic_run": "Cult"` in `TierBook.TYPES` (spec §8:
  Convert and Steal are Cult cards, as Mira's House and The Vigil Flame).
- **Mission tags:** `"bishop": ["burns_temple"]`, `"armoury": ["razes_barracks"]` in `TierBook.MISSION_TAGS`.
- **Unlocking:** Reckoning has five missions, so Ascendance opens at three cleared (spec §3.2's full rule). A save that opened
  Ascendance on The Procession alone keeps it open: a tier never closes. A test pins it.
- **Cards:** five on Reckoning's tab, 115 px wide, with Whisper's wrapping rules (M2 ruling 58).
- **The results' tier line** reads, e.g., "Reckoning 2 / 3 cleared: one more opens Ascendance".

## 6. New wishes for Tier 4

The pool grows from 14 to 16. Both new wishes have `min_tier` 4, so Tier 1-3 nights shuffle exactly what they did (M3 ruling 3,
`WishBook.pool_for()`). Each reuses a kind's code with one new parameter, as M4's two did.

| Wish | Kind | Act | Reward | Needs / clashes |
|---|---|---|---|---|
| Save the heretic from the pyre | Rescue | Once engaged, two soldiers march the wisher's son to the Temple's door. Kill or turn both within 45 s, the son alive. | 15 | a lay citizen of the wisher's household at least 15 units from the Temple's door with at most 40 units of street, and two free soldiers; `burns_temple`, `unaware_town` |
| Lead my family out | Mercy | Whisper the three marked members of the wisher's household to any gate; each escapes. | 15 | three lay citizens near the wisher's home; — |

- **Save the heretic from the pyre:**
  - `PressedWish` with `"goal": "temple"` (the default, "barracks", keeps Free the pressed man exact). The Temple's door is found
    from the town's structure of role `temple` (`_front_of()`), not from TownLayout.
  - A `"guard_label"` parameter names the soldiers' tag: TEMPLE GUARD (the default stays PRESS-GANG).
  - Tags HERETIC, pointed at from the edge; TEMPLE GUARD on each soldier, pointed at once engaged.
  - Clashes with `burns_temple`, so The Bishop never hears it: its march ends at the door his Knights hold.
- **Lead my family out:**
  - `MercyWish` with `"count": 3` (the default, 1, keeps Lead my brother out exact). The three are chosen as Show yourself to my
    family chooses (three citizens near the wisher's home).
  - Tags FAMILY on each, pointed at from the edge.
  - Granted when the third escapes (whispered within 1.5 of a gate: `MercyWish.exits()`). Failed when one dies before escaping,
    or the wisher dies.
- **Free the pressed man** gains the clash `razes_barracks`, so The Armoury never hears it. No Tier 2 or 3 mission declares that
  tag, so their draws do not change.
- **Why these two:** both are Tier 4 in weight. The pyre is a Rescue under the Temple's own guard; the family is three escapes,
  through a God-Resistant town's marshals.

## 7. What the shared code gains

M3 lesson 8: every shared change is a hook or a var whose default is today's path, proven by the exact references.

- **`AssassinateDirector`:** two hooks, whose defaults keep The Tax Collector and The Informer exact:
  - `_appoint_guards(q, taken) -> Array[Person]`: `_free_soldiers(hide_door, q.guard_count, taken)` by default. The Bishop adds
    Knights.
  - `_tends(p) -> bool`: a guard of no corps in `GUARD_MINDS` by default (today's test in `_send_guards()` and
    `_release_guards()`). The Bishop's Knights are corps `KNIGHT`.
  - `BishopDirector` (new, its subclass) overrides the round: the set-out (into his house, unseen), the indoors step (driven out
    by fire), the flight, and the square. It keeps the quarry record, the judge (seen or unseen, the cry of murder), the guards'
    ring, `witnesses()` and the tags' helpers.
- **`RazeDirector`:** unchanged. `ArmouryDirector` (new, its subclass) uses `seal()` / `unseal()` for the bars and the guards,
  `spoil_seconds` for the 12 s, and `lost_reason()` stays "" (the march is an `EventObjective`).
- **`MirasHouseDirector`:** one hook, `lost_reason() -> String` ("" by default). `SermonDirector` (new, its subclass) overrides
  `_find_house()`, `_choose_people()`, `_add_events()`, `_step_events()`, `_opening_banner()`, `_house_label()`, `_roof()` (as
  First Prayers), `tags()`, `hint_phase()`, `tour()`.
- **`BelieversObjective`:** takes its label and reasons in `_init()` (defaults "Believers", "believers", "few"), and fails with
  the director's `lost_reason()` when it is not empty. Mira's House and First Prayers read exactly as before.
- **`VigilFlameDirector`:** one hook, `hud_line() -> String` ("" by default). `RelicRunDirector` (new, its subclass) overrides `_begin()`, `_start_vigil()` (the cart),
  `_home_check()` (the Citadel), `_swap_step()` (the halts, boarding and the swap), `_wren_step()` / `_wren_goal()` (Pip holds where
  left until the swap), `wren_lost()`, `tags()`, `hint_phase()`, `tour()`, `report()`. It reuses `_swap()` (with `shrine` set to the
  drop-off and the carter as the robbed bearer), phase 2 and the Searchlight, `FlameGaze` and the reports.
- **`VigilRoute`:** unchanged. The halts ride on its `busy` callable ("the walk waits for him").
- **`FlameObjective`:** takes its label and reasons in `_init()` (defaults "The flame", "flame", "kept", "wren"), and shows the
  director's `hud_line()` when it is not empty, so The Vigil Flame reads as before.
- **`TempleReport`:** `skip: Callable` (empty by default). When set, a relay passes over anyone it names. The Sermon and The Relic
  Run name the fleeing and the reserved. Mira's House, The Vigil Flame and Broken Lanterns relay as before.
- **`PressedWish`:** the `"goal"` and `"guard_label"` parameters. **`MercyWish`:** the `"count"` parameter. **`WishBook`:** the two
  new wishes, and Free the pressed man's added clash.
- **`MissionBook`:** `_tier4()` and the four missions. **`TierBook`:** Reckoning's tab, types and tags.
- **`EngineerManager.hands_off`** (M4's): The Bishop's three refuges and The Armoury's three targets.
- **New:** `BishopDirector`, `ArmouryDirector`, `SermonDirector`, `RelicRunDirector`. No new objective class: the four use
  `AssassinateObjective`, `RazeObjective`, `BelieversObjective`, `FlameObjective`, `GazeObjective`, `EventObjective` and
  `ClockObjective`.
- **TownLayout in shared code** (the capital-city branch, M3 ruling): no new read outside `src/game/mission/`. The pyre wish finds
  the Temple by its role. The new directors in `src/game/mission/` read TownLayout (`TAVERNS`, `GATE_TOWERS`, `BARRACKS`,
  `WELLS`, `TEMPLE`) in a few named constants each.

## 8. Testing, photos and notes

- **Per mission:**
  - unit tests of its director, on M3's kit (`Kit.world()`, `Kit.run_for()`, `Kit.arrive()`, `Kit.free_body()`, `Kit.labels()`,
    `Kit.edged()`, `Kit.clear_of_stack()`);
  - a behaviour scenario, `--scenario=bishop|armoury|sermon|relic --case=none|play [--seed=N] [--board]`, running the
    `MissionBook` version (the same director, clock and town, no wishes), so its checksums are exact references; `bishop` and
    `armoury` turn hit-stop off;
  - the gate of §0;
  - M3's `_waits` test extended to every new timed wait (the arrivals, the flights, the horns, the reinforcements by the minute,
    the waves, the halts and the count, returns and reliefs, the chains).
- **What each mission's tests pin** (M2-M4 lessons):
  - **a body freed mid-night** (a Knight, a relief, an armed man, a listener, the preacher, a sentry, a warden, an escort, the
    carter, the bishop): `tags()`, `hint_phase()`, `report()` and the objectives never touch it;
  - **the evacuation mid-mission** (§0 and each mission's own test): everyone held stays held;
  - **a wish's people and buildings:** no wisher or wish target becomes a listener, a sentry, a warden, an escort, the carter,
    Pip, an armed man, the preacher or an acolyte; no wish's building becomes a refuge, the god's house, the drop-off or a
    barracks (the fallback tavern and tower are used instead);
  - **The Bishop:** a refuge he is not in only shakes; he is never out of doors before the Temple; a fire is beaten out while a
    Knight stands on guard; he reaches the next refuge 45 s after he is driven out; the Knights are never taken by the rally;
  - **The Armoury:** a barred target only shakes; a guarded one takes no harm and its fire goes out; seconds burned stay counted;
    REINFORCE follows the clock's minute; the reserve spent sends no more;
  - **The Sermon:** a rapt listener refuses a whisper; a silent preacher frees his crowd, and a preacher back on his feet holds
    them again; a seen entry is turned away and reported; too few left loses at once; a Believer stays in town through an
    evacuation;
  - **The Relic Run:** no hand reaches the relic while the cart moves; Pip never boards or swaps while watched; killing the cart's
    people stalls it and never opens the reliquary; a cart with Pip aboard leaves the first halt once its count is done.
- **Exact references that must not move:**
  - the digest, `crowd_check`, every behaviour checksum and outcome in M4's global constraints (calm, gates, fire, rite,
    soldiers, the five Warning cases, Mira's House, Broken Lanterns, the Vigil Flame's and the Feast's outcomes);
  - M2's 24 (refs24: The Tax Collector's prove the Assassinate hooks; First Prayers' prove `BelieversObjective` and Mira's hook);
  - M3's 18 (`ringers`, `panic`, `informer`; The Informer's prove the Assassinate hooks too);
  - M4's 18 (`bread`, `prisoner`, `hunt`, `none` and `play`, seeds 1-3, as recorded at M4's landing).
- **FLOW:** the board and results steps change for Reckoning's five missions. One step is added: The Armoury from the board,
  razed by its public state, ascended, then the results reading "Reckoning 1 / 3 cleared: 2 more open Ascendance". FLOW goes
  from 112 to 113.
- **Photos:** `--show=bishop|armoury|sermon|relic_run` (the tour skipped, the opening banners waited out) and
  `--show=tiers --mission=procession` (Reckoning's tab, its save clearing three Reckoning missions so Ascendance opens). Each
  photo is checked for the HUD stack's dead zone and the edge arrows. The Sermon's photo is checked for clutter (twelve gold
  diamonds, the sentries, the house outline); if the waiting waves' diamonds hide tags, they go and NEXT WAVE carries them.
- **Bench:** The Bishop's board version (`--mission=bishop --board --bench`: the Temple's fire, up to 18 added Knights) against
  The Procession's, on a quiet machine.
- **Release notes:** an M5 section at the top of `docs/KAK_Version_0.11_Summary.md`, its rulings numbered on from M4's last.
- **Spec sync:** each mission task syncs its section here to its tuned numbers (M3 ruling).

## 9. Decisions

These are the details the v0.11 spec left open, numbered on from M4's plan (120). The controller records them as rulings. Each
gives its cost if it proves wrong.

121. **Ids and building:** `bishop`, `armoury`, `sermon` and `relic_run`, built in `MissionBook.tier_missions()` by a new
     `_tier4()` frame (390 s, tier 4, `tier_floor` 4, no `profile`, 5 / 13, no bonuses), so their stretch is 1 and
     `TierBook.board()` needs no branch. Not in `all()` nor the campaign. Cost if wrong: a scripted run meets another town; one
     frame to change.
122. **Unlocking:** Reckoning has five missions, so Ascendance opens at three cleared; a save that opened it on The Procession
     alone keeps it, pinned by a test. Cost: none.
123. **The God-Resistant town as read:** no Knights, Inquisitors or Searchlight from the profile; M5 brings Knights (The Bishop)
     and the Searchlight (The Relic Run) as directors' own. Cost if wrong: none; the profile is unchanged.
124. **Bell:** no bell loss in The Bishop and The Armoury; in The Sermon and The Relic Run the bell fills the Gaze (their families'
     rule), and both hints warn of it. Cost if wrong: at a 5 s climb the two Gaze missions are harsh on seen kills; add The Bell
     Lies to their policies, or soften the bell's fill for these two.
125. **The Bishop, the code:** `BishopDirector extends AssassinateDirector`; the base gains `_appoint_guards()` and `_tends()`,
     defaults today's, so The Tax Collector's and The Informer's twelve references hold. Cost if wrong: a fork of the Assassinate
     code.
126. **Refuges, not a round:** his house, the chapter house, the Temple, in that order; he moves between them indoors, unseen,
     and is never out of doors before the Temple. Cost if wrong: a kill at about 1:00 if he were ever in the open (M2 lesson 1).
127. **The refuges' places:** the dwellings nearest (12.0, -6.8) and (6.5, -13.0), and the Temple. Cost if wrong: a refuge in a
     busy lane makes the Knights' kills seen more often; the next nearest dwelling.
128. **Stone until he is in:** a refuge he is not in only shakes and smothers fire, cleared at teardown. Cost if wrong: without
     it, a refuge burned down ahead skips an item.
129. **Lantern Knights:** added soldiers (`Crowd.add_soldier()`, corps `KNIGHT`, three times a soldier's health), two standing
     at each refuge from the start and an escort of two arriving with him (topped up at each refuge); whispers and Discord do not
     touch them; only a kill removes them.
     Cost if wrong: too hard with a quiet loadout; ESCORT is a knob (1-3).
130. **Driven out:** 8 s burning in all with no Knight on guard (the Temple 10 s), or the refuge's fall; Knights on guard beat
     out a fire after 3 s. Cost if wrong: DRIVE_OUT is a knob (6-12).
131. **The flight:** 45 s from one refuge to the next, the chain itself; the first arrival at 0:45. Cost if wrong: CHAIN and
     ARRIVE_AT are the first knobs.
132. **Knight reliefs:** 30 s after a standing Knight falls, from the Citadel's gate, at most six, only for refuges he has not
     passed. Cost if wrong: an endless stream of Knights; the cap holds it.
133. **The square:** driven from the Temple, he walks with every living Temple Knight (ring 1.4) for the Citadel's gate at half
     pace; a loud power or a fright sends him running; reaching the gate loses. Cost if wrong: the last step is too short to act
     in; slow him (BISHOP_PACE) before anything else.
134. **The Bishop's deadline:** "The Knights take him away" at 5:00 (`EventObjective`); doing nothing loses then. Cost: none.
135. **The Armoury, the code:** `ArmouryDirector extends RazeDirector`, base unchanged; the bars and the guards are the base's
     `seal()` / `unseal()`. Cost if wrong: a seal flickering on and off each look misbehaves with fires; then a guarded flag of
     its own.
136. **The three targets:** the north tavern (`TAVERNS[0]`) and the Main Gate's east tower (`GATE_TOWERS[1]`) as barracks, the
     barracks shed as the armoury; fallbacks for a reserved one. Cost if wrong: a stand-in that does not read as a barracks; the
     tag carries it, as M3's and M4's stand-ins.
137. **Seals, not stages:** replaced by the controller's ruling: M4's stages.
138. **Armed men:** lay watchmen, held deaf and fearless on their posts (plan decision 94's hold); a night watch of two from the
     start and a squad of two at the horn; return 20 s, relief 30 s from the armoury's reserve. Cost if wrong: SQUAD is the first
     knob (1-3).
139. **Arming faster each minute:** one armed man from the armoury every 40 / 30 / 20 / 12 s by the clock's minute, while a
     target musters; a reserve of eight. Cost if wrong: one tuning round on REINFORCE.
140. **Razed by fire or fall:** 12 s burning in all (`spoil_seconds`), or the fall; a guard pauses the fire but keeps its seconds.
     Cost if wrong: SPOIL_SECONDS is a knob (10-15).
141. **The garrison marches** at 5:00 (`EventObjective("march", "Garrison marches", "marches")`). Cost: none.
142. **The Sermon, the code:** `SermonDirector extends MirasHouseDirector`; the base gains `lost_reason()`, and
     `BelieversObjective` takes its label and reasons; Mira's House's and First Prayers' references hold. Cost if wrong: a copy of
     the reading code.
143. **The place:** the pulpit at the south-west well; the god's house the dwelling nearest (-14.0, 10.4), beyond HEAR of the
     pulpit, its door on a quiet lane. Cost if wrong: Faithful passers turn people away by luck; move the house, not the rule.
144. **Rapt and silenced:** within HEAR (5) of a preaching preacher a listener refuses a whisper and fear; silenced while held,
     for good when dead; no new preacher. Cost if wrong: killing him early makes the night easy; give him a relief preacher.
145. **Four waves of three, need eight:** at 0:00 / 1:35 / 3:05 / 4:20, or 45 s after the wave before is spent; the fourth is
     slack. Cost if wrong: one tuning round on CHAIN and the wave size.
146. **The sentries:** two Faithful at the door, return 20 s, relief 30 s, at most six reliefs. Cost if wrong: too easy; a third
     sentry.
147. **The Believers stay** on a ring by the door, held, so an evacuation never empties the count. Cost if wrong: a crowded door;
     move the ring out.
148. **Too few left loses at once** ("THE FLOCK IS SCATTERED"), with the hint "Do not kill them." Cost if wrong: harsh for a stray
     Heaven Splitter; the fourth wave already gives four to spare.
149. **The sermon ends** at 5:00 (`EventObjective`); `BelieversObjective`'s dawn reason is the same key. Cost: none.
150. **The Relic Run, the code:** `RelicRunDirector extends VigilFlameDirector`; the base gains only `hud_line()` ("" by default);
     `FlameObjective` takes its label and reasons and shows that line. The Vigil Flame's outcome and board version hold. Cost if wrong: a
     fork of the theft code.
151. **The route and its checkpoints:** the Temple to the Citadel by the east street, the east-west street and the west street,
     about 59 units, halting at the east and west watch-houses; off the market and the gate plazas. Cost if wrong: a jam in an
     evacuation; move a checkpoint.
152. **The halt:** the reliquary opens for the count (20 s with one of the watch at the cart and not held), 50 s at most; the halt
     rides on `VigilRoute.busy`, so `VigilRoute` is unchanged. Cost if wrong: a halt held at 50 s every time feels like waiting;
     shorten HALT_MAX.
153. **Two steps:** aboard at the first halt, the lock picked on the leg, the swap (4 s) at the second; if he missed the first, all
     three in one window at the second (14 s unwatched). Cost if wrong: players take the hard way and wait a minute for it; then
     the second halt refuses a new boarder and a missed first halt loses at once, with a plain warning.
154. **Unseen by rule:** Pip boards and swaps only while no one watches, so the theft sends no report. Cost if wrong: less tension
     than The Vigil Flame's report; the Searchlight and the bell carry it.
155. **A dead driver stalls the cart:** the escort takes the reins; with all dead the cart stands 30 s until new hands come; the
     reliquary stays locked. Cost if wrong: none; it closes a shortcut.
156. **Pip from the start:** a lay citizen east of the market, tagged DO NOT KILL; he holds where a whisper leaves him until the
     swap, then makes for the drop-off on his own. Cost: none.
157. **The drop-off:** your believers' house in the north-east, about 30 units from the second halt, under the Searchlight. Cost
     if wrong: it is the first tuning knob for the clear.
158. **Relays:** `TempleReport.skip` (empty by default) passes over the fleeing and the reserved in The Sermon and The Relic Run.
     Cost if wrong: a relay to a fleeing man leaves the town with it, as M3 found.
159. **Camera spots:** The Bishop (6.0, -6.5), The Armoury (-5.5, -4.5), The Sermon (-9.0, 9.5), The Relic Run (4.0, -3.0), each
     checked with `clear_of_stack()`; tags that would point into the dead zone (the Citadel) show only in their phase. Cost if
     wrong: a photo-round move, which moves that scenario's references once.
160. **The new wishes:** "Save the heretic from the pyre" (Rescue, 15, `PressedWish` goal "temple", clashes `burns_temple`) and
     "Lead my family out" (Mercy, 15, `MercyWish` count 3), both `min_tier` 4; the pool grows from 14 to 16; Free the pressed
     man gains the clash `razes_barracks`. Tier 1-3 draws do not change; a test that pins a Tier 4 or 5 draw is re-pinned and
     named. Cost: none.
161. **Mission tags:** The Bishop `burns_temple`, The Armoury `razes_barracks`; tests pin that neither night hears its clashing
     wish (M3's Task 6 ruling). Cost: none.
162. **Behaviour scenarios** `bishop`, `armoury`, `sermon` and `relic` run the `MissionBook` versions; `bishop` and `armoury`
     turn hit-stop off. Cost: none.
163. **Results titles:** THE BISHOP IS DEAD, THE BISHOP REACHES THE CITADEL, THE KNIGHTS TAKE HIM AWAY, THE GARRISON IS BROKEN,
     THE GARRISON MARCHES, THE CROWD BELIEVES, THE SERMON ENDS, THE FLOCK IS SCATTERED, THE RELIC IS OURS, THE RELIC REACHES THE
     CITADEL and THE BOY IS DEAD, under the mission's own keys (`bishop`, `bishop_safe`, `bishop_taken`, `garrison`, `marches`,
     `sermon`, `sermon_over`, `flock`, `relic`, `relic_kept`, `pip`); the two Gaze missions share the family's `gaze`. Cost: none.
164. **FLOW:** Reckoning's five on the board and results steps, and one added step (The Armoury ascended): 112 to 113. Cost: none.
165. **Board order:** the ★ mission first, then #17, #18, #19 and #20. Cost: none.
166. **The bench:** The Bishop's board version against The Procession's, on a quiet machine. Cost: none.
167. **No new TownLayout reads in shared code:** the pyre wish finds the Temple by its role; the four directors read TownLayout in
     `src/game/mission/` only. Cost: none.
168. **Knights in red:** The Bishop's Knights are tagged red (danger), not Broken Lanterns' steel blue, which means the god's
     charges on every other board mission. Cost if wrong: a player who knows Broken Lanterns reads red Knights as new; the tag's
     word carries it.
