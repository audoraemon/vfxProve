# KAK v0.11 M3 Omen: the three new Tier 2 missions (mission spec)

Date: 2026-10-09. Status: for the user's approval. Builds on the v0.11 spec
(`docs/superpowers/specs/2026-10-08-kak-v011-tiers-design.md` §2, §4, §5, §7.1, §8 rows 6-10), M1 (rulings 1-30) and M2 as
shipped (`docs/superpowers/specs/2026-10-08-kak-v011-m2-whisper-missions.md`, rulings 31-63 in
`docs/KAK_Version_0.11_Summary.md`). M3 makes Tier 2 complete: Mira's House and Broken Lanterns, plus three new missions
(Intercept and Break generalised, Assassinate reused), two new wishes, and one item carried over from M2's reviews.

## 0. What every Tier 2 mission shares

- **Tier 2's numbers:** clock 5:30 (dawn), town Organized, 3 slots and 8 DP (plus upgrades), 2 wishes heard, believers ×1.5
  (the main objective pays 15).
- **Built at their tier:** each new mission is made in `MissionBook.tier_missions()` by a new `_tier2()` frame: 330 s,
  `tier_floor` 2 (Organized; no `profile`, so its scripted runs meet the same town), 3 / 8, no bonuses. Its board version has
  stretch 1.
- **The Organized town** (`ResponseProfile` Organized, as Mira's House and Broken Lanterns meet on the board):
  - the bell has an escort: a soldier guards whoever is on the rope (`escorts_per_duty` 1);
  - four seen deaths or collapses in one district make a Local Emergency, and the town calls its bellkeeper;
  - a fire brigade of four; no rite, no engineers, no boats.
- **Mission tags:** an Organized town carries no `unaware_town`, so Save my child and both new wishes (§5) can be heard.
- **No waiting:** everything finishes by acting. Every timed wait is 60 s at most. Each mission lists its longest wait.
- **The chain rule** (M2 lesson): each item comes at its scheduled time or a short chain wait after the one before is done,
  whichever is sooner. One still open never holds the next back. Chain waits are 45 s (tunable 30-45).
- **Length:** each main objective is designed to take 3-4 minutes of acting. The gate, per mission (M2 ruling 55):
  - doing nothing loses, seeds 1-3;
  - the scripted player wins at least 2 of 3;
  - the median of its wins is 180-240 s;
  - its longest stretch between two casts is 45 s or less.
- **Own people:** each director's people are lay citizens it appoints (watchmen, wardens, contacts), never borrowed town
  soldiers, so the rally cannot take them (M2 lesson 4). Every choice goes through M2's helpers (`_eligible()`,
  `_lay_near()`, `_house_near()`, `_house_reached()`), so no wisher, wish target or wish building is ever taken. Each
  mission lists what it claims.
- **Camera:** each `camera_at` keeps every key target out of the dead zone under the left HUD stack (about 230×70 px at
  the top-left; at play zoom, ground points 8-18 units west of the camera). Every off-screen target's tag has an edge arrow.
- **Art:** text and drawn shapes only. Ringers, mates and wardens are made `CitizenProfile.Role.WATCHMAN`, so they wear the
  existing watch cloak and lantern. Every other stand-in is an existing building, person or drawn shape named by a map tag.
- **Colours** (as M2): target gold `d8b23a`, places orange `ff9a3a`, watchers and danger red `c8342a`, the god's charges
  steel blue `8fb8e8`, a waiting place grey, clear green `7fc46a`, wishes soft blue `8fb8ff`.
- **The ★ missions** keep their directors, rules and stretches (Mira's House ×2.2, Broken Lanterns ×1.8333).

## 1. The Bell-Ringers (Intercept, generalised)

- **Brief:** "Three watch posts guard the walls." / "Stop their ringers before the bell."
- **Card type:** Intercept. **Id:** `bell_ringers`.
- **Map** (centres from `TownLayout.wall_towers()`; each post is the wall tower nearest its point that is not reserved, and
  its door is the first face with a route from the bell's foot, M2's `_open_door()`):
  - **The north-east post:** the north-wall tower at (6.6, -15.65), at the head of the east street. About 20 units of
    street to the bell.
  - **The south-west post:** the south-wall tower at (-8.0, 15.65), west of the postern. About 28 units.
  - **The east post:** the east-wall tower at (15.65, -8.0), north of the workshops. About 16 units: the shortest run.
  - **The bell tower:** `TownLayout.BELL_TOWER`, east of the market. Its foot is `BellNetwork.foot`.
  - **Stone tonight:** the three posts and the bell tower only shake when struck (`Structure.damage_filter`, as the old well
    shrine). No one can bring a post or the bell down to skip a ringer.
  - **The camera** rests at (6.0, -5.0). The north-east post shows at the top right, the bell tower below the centre and
    the east post at the right. The south-west post is off screen at the bottom left; its edge arrow sits on the left edge,
    below the HUD stack.
- **Claims:** three wall towers; nine lay citizens (a ringer and two mates per post, the three nearest the post's door).
  No soldiers.
- **Main objective:** stop all three warnings.
  - **Won** the moment the third is stopped.
  - **Lost** when the bell tolls (rung by a ringer, a relay or the town's own bellkeeper), or at dawn.
- **People and behaviour** (The Warning's rules unless said):
  - **Inside:** each post's ringer and his two mates are watchmen (cloak and lantern), inside their tower from the start.
    Indoors they are hidden and cannot be touched.
  - **Setting out:** at its time the post's three come out at its door. They stand OUT_PAUSE (3 s) to light their lanterns.
    Then the ringer runs (on duty) for the bell's foot.
  - **The mates** run MATE_GAP (1.2) behind him, one on either side: beyond one Silent Doom's reach of him, within sight.
    They stand about 1.4 apart, so a Doom between them can take both.
    - A mate follows while on his own feet. Frightened, whispered or confused, he falls behind. Back on his feet, he runs to
      catch up.
  - **The relay:** a seen death passes the warning to the nearest witness, who runs on with it. That is usually a mate. So
    one strike never stops a warning while his mates are by him.
  - **The god's hand:** a frightened, confused or whispered carrier drops the errand and takes it up again once back on his
    feet (`WarningDirector.RESUMABLE`).
  - **Ringing it himself:** a carrier who reaches the bell's foot takes the rope (`BellNetwork.replace_keeper()`), whether
    or not the bellkeeper lives. He climbs 12 s (the town's 8 s × 1.5), with the climb bar over the tower. The bellkeeper is
    never his goal.
    - **Pulled off:** frightened, whispered or confused, the climber drops off (BellNetwork's own rule) and tries again
      10 s after he is calm.
    - **The bell's guard:** the Organized town sends an escort to whoever is on the rope. The escort sees a Doom on the
      climber, and steadies a confused climber within 3 s (`EscortManager`).
    - **One rope:** a second carrier at the foot waits there. He takes the rope if the climber falls or drops off.
    - **Stopped on the rope:** the bell goes back to its own keeper, idle.
  - **Stopped:** a warning dies when its carrier is killed with no one living within 2 units (`Crowd.nearest_witness()`).
  - **The posts see you:** a loud power cast within POST_SIGHT (6) of a waiting post sends its ringer out at once ("THE EAST
    POST SEES YOU"). Quiet powers never do.
  - **The next post** sends its ringer at its own time (1:50, 3:00), or 45 s after the warning before is stopped, whichever
    is sooner. A warning still running never holds the next back.
  - **The town's bellkeeper** is the town's. A Local Emergency calls him, and his ring loses the night too.
- **Timeline** (left alone):

  | Time | Event |
  |---|---|
  | 0:00 | "THE WATCH POSTS ARE MANNED" |
  | 0:40 | "The north-east post sends its ringer" (sooner if a post sees you) |
  | ~0:43 | He runs for the bell tower, his mates at his heels |
  | ~0:55 | He climbs the bell tower (12 s) |
  | ~1:07-1:12 | The bell tolls: lost |
  | 1:50 | "The south-west post sends its ringer" (sooner: 45 s after the first warning is stopped) |
  | 3:00 | "The east post sends its ringer" (sooner: 45 s after the second is stopped) |
  | 5:30 | Dawn |

- **Longest waits:** 40 s at the start (a loud cast by the north-east post cuts it short), and 45 s between one warning
  stopped and the next post (a loud cast by that post cuts it short).
- **Tags:**
  - RINGER on each warning's carrier, gold, with an edge arrow. RINGER - CLIMBING while he is on the rope.
  - MATE on each mate still with him, red. A red diamond on everyone else who would see the carrier die
    (`WarningDirector.witnesses()`).
  - NEXT POST over the next post's door until its ringer sets out, gold, with an edge arrow. WATCH POST on each other post
    still waiting, orange.
  - BELL TOWER, red.
  - BELLKEEPER, steel blue, with an edge arrow, while the town has called him.
- **Hint phases:**

  | Phase | Line |
  |---|---|
  | (none) | Kill each ringer (gold) where no one (red) sees, before he climbs the bell tower. His mates run with him. |
  | `mates` | His mates (red) would see him die and run on. Draw them off or strike them first. |
  | `relay` | Someone saw: a witness (gold) carries the warning on. Strike again where no one (red) is near. |
  | `climbing` | He climbs the bell (gold). Pull him off with a whisper or a fright, or kill him unseen before the bar fills. |
  | `bell` | The town calls its bellkeeper (blue). Stop him before the bell tolls. |
  | `waiting` | That warning is dead. The next post (gold) sends its ringer soon. A loud power near a post sends him at once. |

- **HUD:** "Ringers stopped 1 / 3".
- **Tour:**
  1. "The north-east post. Its ringer runs for the bell at 0:40."
  2. "The south-west post. Its ringer comes by 1:50."
  3. "The east post. Its ringer comes by 3:00, by the shortest way."
  4. "The bell tower. A ringer who reaches it climbs and rings it himself."
- **Mission tags:** none.
- **Pool:** every power but Blight and The Bell Lies. Both silence the bell outright, which would stop every ringer at once.
- **Results:** "THE RINGERS ARE STOPPED" (`ringers`). "THE BELL TOLLS" (`bell`) and "DAWN COMES" (`dawn`) exist.
- **Numbers** (first guesses): SET_OUT_AT 40 / 110 / 180, CHAIN_WAIT 45, OUT_PAUSE 3, MATES 2, MATE_GAP 1.2, POST_SIGHT 6.
  The climb stays the town's. Tune in this order if the scripted clear misses 180-240 s: SET_OUT_AT (the first at most 40),
  CHAIN_WAIT (30-45), MATES (1-2), MATE_GAP, POST_SIGHT.
- **Scripted policy** (`--scenario=ringers`, loadout Silent Doom, Mind Whisper, Discord: 4 DP). Every LOOK_FRAMES, the first
  that applies:
  1. The town's bellkeeper is called and Doom is ready: Doom him.
  2. A carrier out of doors would die unseen (`_tax_unseen()`): Doom him.
  3. Two mates stand within 1.6 of each other, and a Doom at their midpoint would take both and no one else: Doom there.
  4. One or two witnesses, none a soldier, and Whisper is ready: whisper the nearest six units away from the carrier.
  5. The carrier is within 8 of the bell's foot, or on the rope, and Discord is ready: Discord on him.

  It never casts a loud power, so it never pulls a ringer early. Expected clear: about 3:00-3:20.
- **How it differs from the board's Warning** (M2 lesson 10):
  - **Other places:** three wall towers in the north-east, south-west and east. The Warning uses three gates in the south
    and east.
  - **No pre-kill:** each warning starts inside a tower, not with a watchman standing at a gate.
  - **A pair at least:** every warning is three people. One strike never ends it.
  - **No keeper to chase:** the ringers ring the bell themselves. The guarded climb is the last chance.
  - **The posts watch the god:** a loud power near a post sends its ringer early. That rushes the night, or overloads it.

## 2. Market Panic (Break, generalised)

- **Brief:** "A night fair fills the north-east square." / "Scatter it before the market closes."
- **Card type:** Break. **Id:** `market_panic`.
- **Map:**
  - **The fair:** the north-east fountain (`TownLayout.FOUNTAINS[1]`, centre (11.4, -10.0)), its plaza
    (`TownLayout.FOUNTAIN_PLAZA`) and the east street beside it. Tagged THE FAIR. It is not the market square: the Festival
    keeps that.
  - **Spread out:** goers stand within FAIR_R (5.5) of the fountain on walkable ground, among the plaza, the street and the
    gaps between houses. One Heaven Splitter (a strip 10 long and 6.4 wide) cannot take a whole crowd.
  - **A bonfire** beside the fountain (the existing `BonfireFx`).
  - **The wardens' posts:** three, evenly round the fountain, 1.5 from its centre on walkable ground. They stand 2.6 apart,
    more than one Silent Doom takes.
  - **Where the crowds come from:**
    - the north-east quarter round the fair (11.4, -10.0);
    - the cathedral's street by the market's north-east corner (4.5, -4.0);
    - the workshops and the smithy (12.0, 1.0);
    - the east tavern (8.75, 2.75).
  - **The camera** rests at (10.0, -8.0). The fountain is at the centre. The three later sources are on screen, none in the
    HUD stack's corner: the cathedral's street at the left, the east tavern at the lower left, the workshops at the bottom.
- **Claims:** 44 lay citizens as goers (four crowds of 11, calm), appointed as the night begins. Three wardens, the lay
  citizens nearest their posts, and their reliefs. No soldiers, no buildings.
- **Main objective:** break 36 of the 44 goers.
  - Broken is the Festival's rule: dead, frightened by the god (panic, or a dash for shelter), or standing in a loud
    cast's danger. A goer who leaves the town unbroken never counts.
  - **Won** the moment the 36th breaks.
  - **Lost** when the guard closes the market at 5:00.
- **People and behaviour** (the Festival's rules unless said):
  - **Four crowds:**
    - the first, the 11 nearest the fountain, walks in at 0:00 and is there in about 10 s;
    - the second comes at 1:15, the third at 2:30 and the fourth at 3:40, or 45 s after the crowd before is wholly gone
      (every one of it broken, dead or out of the town), whichever is sooner;
    - each walks in at a stroll, about 20 s, then takes its place at the fair.
  - **The wardens:** three watchmen (cloak and lantern) keep the fair.
    - **On guard:** alive, out of doors, within 2.5 of his post, and calm (Spoiled Harvest's `GUARD_MINDS`).
    - **Fearless on guard:** a fright does not move him. The god's holds still take him: a kill, a whisper, Discord.
    - **Steadying:** while a warden is on guard, a fright breaks no goer within WARD_R (5.5) of him. Deaths still count.
    - **Return and relief** (Spoiled Harvest's rules): a warden off his post and calm again goes back 20 s after he left.
      A fallen one is replaced by the nearest free lay citizen with a way to the post, 30 s after he fell. Clearing the
      wardens too early is undone.
  - **Catch them on the way:** a walker not yet within WARD_R of a warden on guard breaks as any goer does.
  - **Goers hold to the fair:** once a goer reaches the fair, the town's regroup and evacuation do not take him. He stays
    until he breaks or the market closes. The Organized town's bell may ring; it loses nothing here.
  - **Crowds to come wait on duty:** each crowd's people are appointed as the night begins and stand on duty round their
    source until their crowd sets out. They are held fearless, so a loud cast or a seen death near a source does not turn them
    into the town's flight, and the regroup and the evacuation pass them by; for the same reason no fright or cast's danger
    breaks one while he waits.
  - **The waiting are goers too:** they count as the Festival counts any of its crowd. One struck down where he waits counts
    toward the need (nine stray kills at a source cost the night nothing) and is not sent. A crowd wholly gone before its
    time (every one dead) is scattered at once: it never sets out, and the next comes at its own time or 45 s after.
  - **No Mayor, no address:** the Festival's own events and square guards stay off.
- **Timeline** (left alone):

  | Time | Event |
  |---|---|
  | 0:00 | "THE NIGHT FAIR". The first crowd walks in. |
  | 1:15 | "More come to the fair", from the cathedral's street (sooner: 45 s after the first crowd is gone) |
  | 2:30 | "More come to the fair", from the workshops (sooner: 45 s after the second is gone) |
  | 3:40 | "More come to the fair", from the east tavern (sooner: 45 s after the third is gone) |
  | 5:00 | "The guard closes the market": lost unless 36 have broken |
  | 5:30 | Dawn |

- **Longest wait:** 45 s between one crowd gone and the next setting out. Its walk-in is about 20 s more, and those
  walkers can be struck on the way. There is no wait at the start.
- **Tags:**
  - THE FAIR - 12 / 36 at the fountain, gold, with an edge arrow.
  - WARDEN on each warden on guard, red. A small red mark on one away from his post.
  - A gold diamond on each goer not yet broken, walkers too, and the waiting ones at their stands: gold means it counts.
  - NEXT CROWD and the seconds to it (the sooner of its own time and the chained one) at the next crowd's source until it sets
    out, orange, with an edge arrow.
- **Hint phases:**

  | Phase | Line |
  |---|---|
  | (none) | Strike down the wardens (red), then scatter the crowd (gold). Thirty-six must break; the waiting count if struck down. |
  | `steadied` | A warden (red) steadies the crowd near him: frights break no one there. Remove them all first. |
  | `open` | No warden stands. Strike the crowd (gold) now, before a new warden comes. |
  | `coming` | More come to the fair (gold). Strike them on the way, away from the wardens, or when they arrive. |

- **HUD:** "Scatter the fair 12/36", and the deadline row "Market closes 3:12".
- **Tour:**
  1. "The night fair at the north-east fountain. Its wardens (red) keep the crowd calm."
  2. "More come from the cathedral's street by 1:15."
  3. "More come from the workshops by 2:30."
  4. "More come from the east tavern by 3:40. The guard closes the market at 5:00."
- **Mission tags:** none.
- **Results:** "THE FAIR IS SCATTERED" (`fair`), "THE MARKET IS CLOSED" (`market_closed`).
- **Numbers** (tuned by Task 3's gate; the first guesses were three crowds of 14, WAVE_NEED 10, NEED 30, WAVE_AT 0 / 90 / 165,
  WARDENS 2, WARD_R 4, PACK_R 4.5, CLOSE_AT 270): WAVE 11, WAVE_NEED 11 (a crowd is gone when all of it is), NEED 36,
  WAVE_AT 0 / 75 / 150 / 220, CHAIN 45, WARDENS 3, WARD_R 5.5, FAIR_R 5.5, RETURN 20, RELIEF 30, MARKET_CLOSE 300. RETURN and
  RELIEF stay at Spoiled Harvest's. Its gate: none loses 3 of 3, play wins 3 of 3 at 3:13-3:25 (median 3:16), the longest
  idle 21 s.
- **Scripted policy** (`--scenario=panic`, loadout Heaven Splitter, Silent Doom, Smite: 4 DP; hit-stop off, so a seed
  replays exactly). Every LOOK_FRAMES, after the first crowd has had 10 s to take its places, the first that applies:
  1. A warden on guard within WARD_R of four or more unbroken goers, and Doom is ready: Doom him (the one nearest the
     fountain first).
  2. No crowd still to come (a loud splitter early brings the town's evacuation, which sends the goers not on duty out
     unbroken), no warden on guard, six or more unbroken goers within FAIR_R, and Heaven is ready: Heaven Splitter through
     the fountain, along whichever of the two axes covers more of them.
  3. No crowd still to come, five or more unbroken walkers inside one Heaven strip, none within WARD_R of a warden on
     guard, and Heaven is ready: Heaven along them.
  4. Smite is ready: Smite the densest knot of three or more unbroken goers with no warden on guard within WARD_R; else the
     goer nearest the fountain (a bolt kills whoever it strikes).
  5. Doom is ready and a warden stands on guard: Doom him, to clear the cover before the next crowd.
- **How it differs from the Festival** (M2 lesson 10):
  - **Another place:** the north-east fountain, not the market square.
  - **Smaller:** 44 goers in four crowds of 11, against 120 at once.
  - **Its own opposition:** wardens who steady the crowd, with returns and reliefs.
  - **Crowds come in:** the player can catch them on the way.
  - **No Mayor:** no address, no fountain push.
  - **Its own close:** the market guard at 5:00, inside a 5:30 night.

## 3. The Informer (Assassinate, reused)

M2 lesson 1: one target in the open dies at about 1:00. So the informer cannot be reached until the player has worked
through his four contacts. They are the night's paced items, on the chain rule. The final kill is a short chase.

- **Brief:** "An informer carries your believers' names." / "Find him through his contacts. Kill him."
- **Card type:** Kill. **Id:** `informer`.
- **Map:**
  - **The Temple's door** at (0.8, -5.0) (The Lost Lamb's `TEMPLE_DOOR`): where he takes the names. Tagged TEMPLE.
  - **Four contacts.** Each is the lay citizen nearest his house's door, set down there and kept there. His house is the
    dwelling nearest his point whose door the street reaches (`_house_reached()`) and no soldier's post watches (none within
    2 units of the door: a soldier hears no whisper and feels no Discord). Every door stands in a quiet lane (Task 4's fix
    ruling):
    1. **the chandler**, at (6.0, -12.4): behind the Temple to the north-east;
    2. **the weaver**, at (-13.7, 12.6): the south-west quarter by the west wall;
    3. **the potter**, at (-1.4, 13.8): the south quarter, west of the Main Gate's road;
    4. **the carpenter**, at (6.2, 13.8): east of the Main Gate's road, toward the carpenter's yard, about 20 units of street
       from the Temple's door.
  - **Each contact's company:** the COMPANY (3) lay citizens nearest him, set down 1.2 from his door on a half ring facing the
    street (inside 2 units' sight), and kept there.
  - **The informer:** the resident nearest (-3.5, -12.0), behind the Temple. He is taken inside the dwelling nearest that
    point at the start, and is never tagged until he is found. He waits there on duty, so an evacuation never sends him
    running.
  - **The camera** rests at (4.0, -2.0). The Temple's door is above the centre and the chandler at the top right. The
    weaver's and the potter's tags point from the left edge, below the HUD stack. The carpenter's door shows at the bottom
    left.
- **Claims:** 17 lay citizens (4 contacts, 12 company, the informer) and five dwellings (the contacts' houses and his
  lodging). No soldiers.
- **Main objective:** kill the informer before he reaches the Temple.
  - **Won** the moment he dies, any way.
  - **Lost** when:
    - the names reach the Temple (he reaches its door, or 60 s pass after his fourth visit without him found);
    - a contact dies before he is turned, or leaves the town ("THE TRAIL GOES COLD");
    - the bell tolls;
    - dawn comes.
- **People and behaviour:**
  - **Hidden:** the informer keeps to cellars and back lanes. He is indoors, untouchable and untagged, and moves from house
    to house unseen. No power reaches him until he is found. Fire or the fall of a house he is in does not bring him out.
  - **His visits:** word reaches a contact when the informer comes to his house:
    - the chandler at 0:45;
    - the second contact at 1:55, or 45 s after the chandler is turned, whichever is sooner;
    - the third at 3:00, or 45 s after the second is turned, whichever is sooner;
    - the fourth at 4:05, or 45 s after the third is turned, whichever is sooner.

    Before his visit, a contact knows nothing.
  - **Turning a contact:** cast Mind Whisper on him after the visit, while no one else out of doors within 2 units sees it.
    People held by Discord or a whisper see nothing. A turned contact names the next contact ("THE CHANDLER NAMES THE
    WEAVER"). The last names the informer's hiding place.
    - **A whisper someone sees** is no use. Mind Whisper's own rule lets the same contact be whispered again 20 s later.
    - **Discord:** a contact held by Discord can still be whispered, and turned.
    - **Only his own whisper counts:** one cast beside him (on a companion at his elbow) while an older whisper still holds
      him neither turns him nor reads as seen.
  - **The company** stand by their contact. Whispered away, each walks back once the whisper's linger ends, so clearing
    them too early is undone.
  - **A contact dead before he is turned** takes the trail with him: the night is lost. So does one gone from the town.
  - **Found:** the informer bursts out of the last contact's house ("THE INFORMER IS FOUND") and runs on duty for the
    Temple's door, about 20 units of street (some 13 s). AssassinateDirector's rules then hold, with no guards:
    - a loud power within 4 of him, or a fright, sends him back into that house to hide 20 s;
    - fire on that house flushes him out; with it burning or fallen, an alarm sends him on toward the Temple;
    - any death wins. A seen death makes the guards cry murder and calls the bellkeeper. On the board the bell after the
      kill catches the night and loses the wishes, unless the god ascends or stops the bellkeeper first.
  - **Not found in time:** 60 s after his fourth visit, the names reach the Temple by the back lanes.
  - **The Organized town:** a seen death by a contact counts toward a Local Emergency. Four, and the bellkeeper climbs.
- **Timeline** (left alone):

  | Time | Event |
  |---|---|
  | 0:00 | "FIND THE INFORMER". All four contacts are marked DO NOT KILL; the chandler is the one to work on. |
  | 0:45 | "Word reaches the chandler" |
  | 1:55 | "Word reaches his second contact" (sooner: 45 s after the chandler is turned) |
  | 3:00 | "Word reaches his third contact" (sooner: 45 s after the second is turned) |
  | 4:05 | "Word reaches his fourth contact" (sooner: 45 s after the third is turned) |
  | 5:05 | "THE NAMES REACH THE TEMPLE": lost (60 s after the fourth visit) |
  | 5:30 | Dawn |

- **Longest waits:** 45 s to the first visit, and 45 s between a contact turned and the next visit. In both, the next
  contact's company can be dealt with. The 60 s after the fourth visit is time to act in, not a wait.
- **Tags** (Task 4's rulings: every contact whose death loses the night is warned from the start):
  - The contact to turn now has a tag with an edge arrow. Before his visit it is grey, "NO WORD YET - DO NOT KILL". Once word
    reaches him it is orange, "CONTACT - DO NOT KILL".
  - Each later contact has a pale tag with no arrow: "NO WORD YET - DO NOT KILL", or "CONTACT - DO NOT KILL" if word reaches
    him first. Turned contacts lose their tag.
  - A red diamond on everyone who would see a whisper on him (within 2, not held).
  - Once found: INFORMER, gold, with an edge arrow; INFORMER - INSIDE over the house's door while he hides; TEMPLE at the
    door, red; a red diamond on whoever would see a Doom on him.
- **Hint phases:**

  | Phase | Line |
  |---|---|
  | `waiting` | Word has not reached the contact (grey) yet. Get his company (red) away before it does. Do not kill a contact. |
  | (none) | Whisper the contact (orange) while no one (red) sees. He names the next. Do not kill a contact. |
  | `found` | He is found and runs for the Temple (red). Kill him before he gets in. Unseen, no cry is raised. |
  | `hiding` | Alarmed, he hides. Set the house alight to smoke him out, or wait for him. |
  | `running` | No hiding place: he runs for the Temple (red). Kill him before he gets in. |

  `running` is AssassinateDirector's phase from M2's final review (alarmed, with the hideout alight or fallen).
- **HUD:** "Find the informer: contacts turned 1 / 4". Once found: "Kill the informer", with ", he hides" while he hides and
  ", he runs for the Temple" while he flees with no hiding place.
- **Tour:**
  1. "The chandler, first of the informer's four contacts. Word reaches him at 0:45. Turn him with a whisper: do not kill
     him."
  2. "The Temple. The informer takes your believers' names here."
- **Mission tags:** `hunts_informer`. It keeps the wish "Kill the informer, unseen" away.
- **Results:** "THE INFORMER IS DEAD" (`informer`), "THE NAMES REACH THE TEMPLE" (`names`), "THE TRAIL GOES COLD" (`cold`).
- **Numbers** (tuned by Task 4's gate, its fix round): VISIT_AT 45 / 115 / 180 / 245, CHAIN 45, COMPANY 3, SPEAK_SEEN 2,
  FOUND_LIMIT 60, HIDE 20, ALARM_REACH 4. Tune in this order: COMPANY (2-3), CHAIN (30-45), VISIT_AT, the carpenter's point
  (the chase), HIDE.
- **Scripted policy** (`--scenario=informer`, loadout Mind Whisper, Discord, Silent Doom: 4 DP). Every LOOK_FRAMES, the first
  that applies:
  1. The bellkeeper is called and Doom is ready: Doom him.
  2. The informer is found and out of doors: Doom him when the kill would go unseen, or whatever the witnesses once he is
     within 8 of the Temple's door. Never while a contact stands close enough to fall with him.
  3. The current contact has word:
     - no onlooker: whisper him three units off;
     - Mind Whisper and Discord both ready: Discord where it holds every onlooker, or all but one a whisper can send off;
       the whisper follows;
     - else: whisper one onlooker eight units away (his company and those standing still first; not a soldier, not one
       shaking off a whisper).
  4. The current contact's visit is within 18 s: whisper his company away, one per whisper, only while the whisper will be
     ready again when word comes.

  It never Dooms a contact. Clear (Task 4's gate): 3:11-3:28, median 3:11.
- **How it differs from The Tax Collector:** one hidden target found by work, not three walking in the open. The paced items
  are the contacts. The quarry shows only for a short chase at the end.

## 4. Tier 2 on the board

- **The tab:** `TierBook.MISSIONS[1]` becomes `["miras_house", "broken_lanterns", "bell_ringers", "market_panic",
  "informer"]`: the ★ missions first, as on Whisper's tab.
- **Types:** Intercept, Break and Kill in `TierBook.TYPES`.
- **Mission tags:** `informer` gains `["hunts_informer"]` in `TierBook.MISSION_TAGS`.
- **Unlocking:** Omen has five missions, so Wrath opens at three cleared (spec §3.2's full rule). A save that opened Wrath
  with Mira's House and Broken Lanterns alone keeps it open: a tier never closes.
- **Cards:** five on Omen's tab, 115 px wide, with Whisper's wrapping rules (M2 ruling 58).
- **The results' tier line** reads, e.g., "Omen 2 / 3 cleared: one more opens Wrath".

## 5. New wishes for Tier 2

The pool grows from 10 to 12. Both new wishes clash with `unaware_town`, so they are heard from Omen up.

| Wish | Kind | Act | Reward | Needs / clashes |
|---|---|---|---|---|
| Scare off the bully, unharmed | Fright (new) | Frighten the marked citizen: he panics or runs for shelter (the Festival's broken minds) while he lives. | 10 | a lay citizen; `unaware_town` |
| Free the pressed man | Rescue | Once engaged (his tag or a soldier's clicked, or a cast within 2 of any of them), two soldiers walk to the wisher's son and march him to the barracks' door. Kill or turn both within 45 s, the son alive. | 15 | a lay citizen of the wisher's household living at least 15 units from the barracks' door, with at most 40 units of street to it, and two free soldiers; `unaware_town` |

- **Scare off the bully:**
  - Tag BULLY, pointed at from the edge (he walks the town).
  - Granted the moment he is frightened. The town's own flight (`FLEE`) does not count.
  - Failed if he dies first, or leaves the town.
- **Free the pressed man:**
  - Tags PRESSED MAN (always pointed at from the edge) and PRESS-GANG (on each soldier; pointed at once engaged).
  - "Turned" is `RescueWish.TURNED`, as Save my child.
  - Failed when the son dies, reaches the barracks' door, or the 45 s run out.
  - The barracks' door is the front of `TownLayout.BARRACKS`, in its yard.
  - The HUD shows the clock once engaged, as Save my child does.
- Both fail when the wisher dies, as every wish does.

## 6. The item carried from M2's reviews

- **The strip shows the chained time.** M2 deferred it twice (the Tax Collector, Spoiled Harvest): when the chain brings an
  item forward, the event strip still counts down to its scheduled time, overstating by up to 13 s. Every M3 mission chains.
  - The fix is display only. A director tells its timeline the chain's time (`EventTimeline.expect(id, at)`). The strip and
    `seconds_to()` show the sooner time. Firing is unchanged.
  - The Tax Collector and Spoiled Harvest adopt it too. Firing is unchanged, so their 24 references hold.
- The left HUD stack's dead zone stays M6's polish task (M2's Task 8 ruling). M3 works round it with its camera spots.

## 7. Testing, photos and notes

- **Per mission:**
  - unit tests of its director;
  - a behaviour scenario, `--scenario=ringers|panic|informer --case=none|play [--seed=N] [--board]`, running the
    `MissionBook` version (the same director, clock and town, no wishes), so its checksums are exact references;
  - the gate of §0;
  - M2's `_waits` test extended to every new timed wait.
- **Exact references that must not move:** the digest, `crowd_check`, every behaviour checksum and outcome in M2's global
  constraints (the five Warning cases, Mira's House, Broken Lanterns, the Feast's win), and M2's 24 new ones.
- **FLOW:** the board and results steps change for Omen's five missions. One step is added: The Bell-Ringers from the
  board, its three warnings stopped, ascended, then the results. FLOW goes from 110 to 111.
- **Photos:** `--show=bell_ringers|market_panic|informer` (the tour skipped, the opening banners waited out) and
  `--show=tiers --mission=miras_house` (Omen's tab). Each photo is checked for the HUD stack's dead zone and the edge arrows.
- **Bench:** The Bell-Ringers' board version (`--mission=bell_ringers --board --bench`) against Mira's House's, on a quiet
  machine.
- **Release notes:** an M3 section at the top of `docs/KAK_Version_0.11_Summary.md`, with M3's rulings numbered from 64.

## 8. Decisions

These are the details the v0.11 spec left open. The controller records them as rulings. Each gives its cost if it proves
wrong.

1. **Ids and building:** the ids are `bell_ringers`, `market_panic` and `informer`. They are built in
   `MissionBook.tier_missions()` by a new `_tier2()` frame (330 s, `tier_floor` 2, no `profile`, 3 / 8, no bonuses), so
   `TierBook.board()` needs no per-mission branch and their stretch is 1. They are not in `all()` nor the campaign. Cost if
   wrong: a scripted run meets a different town from the board's; one frame to change.
2. **Unlocking:** Omen has five missions, so Wrath opens at three cleared. A save that opened Wrath with Omen's two ★
   missions keeps it open, and a test pins that. Cost: none.
3. **Bell-Ringers, the code:** a new container, `BellRingersDirector`, follows StarfallDirector's pattern; StarfallDirector
   is untouched. Each warning is a `RingerDirector`, a subclass of `WarningDirector`. `WarningDirector` gains only virtual
   hooks whose defaults keep today's path (a `_rings_himself()` that answers false; the goal and the appointment are
   already methods). The five Warning references and the board Warning stay exact. Cost if wrong: a copy of the relay code
   instead of a subclass.
4. **The posts:** the wall towers nearest (6.6, -15.65), (-8.0, 15.65) and (15.65, -8.0), never a reserved tower (the
   watchtower wish's), each door the first face with a route from the bell's foot. `_open_door()` moves up from
   `AssassinateDirector` to `MissionDirector` unchanged. Cost if wrong: a post with no route; the next nearest tower.
5. **Stone tonight:** the posts and the bell tower only shake when struck. Their `damage_filter` is cleared at teardown, as
   M2's final review made RazeDirector do for its seals. The pool leaves out Blight and The Bell Lies. Cost if wrong: a
   narrower draft for this one mission.
6. **Ringers and mates:** each post's three are the lay citizens nearest its door, made watchmen and taken inside the tower
   at the start. MATES 2, MATE_GAP 1.2 (beyond one Doom of the ringer, within sight; the mates about 1.4 apart). Cost if
   wrong: the mates are the first tuning knob (1-2).
7. **Ringing himself:** a carrier's goal is the bell's foot, and arriving he takes the rope (12 s climb) whether or not the
   keeper lives. One rope: a second carrier waits at the foot. A carrier stopped on the rope gives the bell back to its own
   keeper, idle (a small `BellNetwork.restore()`). Cost if wrong: a stuck bell state the town's alarm cannot use.
8. **Pacing:** SET_OUT_AT 40 / 110 / 180, CHAIN_WAIT 45, OUT_PAUSE 3. Cost if wrong: one tuning round.
9. **The posts see you:** a loud cast within 6 of a waiting post sends its ringer out at once. Quiet casts never do. It lets
   a player cut any wait. An expert who pulls every ringer early can clear in about two minutes; the scripted gate does not
   use it. Cost if wrong: set POST_SIGHT to 0.
10. **Relays and the escort:** the Warning's relay is kept. The Organized town's bell escort guards whoever is on the rope.
    Cost: none.
11. **Bell-Ringers' objectives:** all three warnings stopped (`StarsObjective` learns to read any director with `stopped()`
    and a warning count), the bell silent (`BellSilentObjective`), dawn. Cost if wrong: a small `RingersObjective` instead.
12. **Market Panic, the code:** `FestivalDirector` gains overridable vars whose defaults are today's constants: the square,
    the heart (fountain), the pack radius, the event times, the Mayor on or off, the fire spots and the tags' words. It also
    gains two virtual hooks: `_gather()` and `_may_break(goer)`, which answers true. `FestivalObjective` takes its label and
    reason. The subclass is `MarketPanicDirector`. The Festival, the Feast and The Long Night's act play exactly as before.
    Cost if wrong: a few more knobs on a shared director.
13. **The place:** the north-east fountain and its plaza, a night fair. Goers spread within 5.5 of the fountain. Cost if
    wrong: a crowd too packed or too thin; FAIR_R is a tuning knob.
14. **Four crowds:** 11 each, from (11.4, -10.0), (4.5, -4.0), (12.0, 1.0) and (8.75, 2.75). The first walks in at 0:00. The
    next come at 1:15, 2:30 and 3:40, or 45 s after the crowd before is wholly gone. All are appointed as the night begins
    and wait on duty round their source (Task 3's fix rounds); they count as goers from the start, struck down or not yet
    come. Cost if wrong: one tuning round.
15. **The need:** 36 of 44, by the Festival's rule of broken. Cost if wrong: one tuning round.
16. **The wardens:** three watchmen at posts evenly round the fountain. On guard and fearless, each steadies the goers
    within 5.5: frights break no one there, deaths still count. Return 20 s, relief 30 s. Spoiled Harvest's `Watch` record
    and its tick move to a shared helper only if Spoiled Harvest's six references stay exact; otherwise Market Panic copies
    the rule. Cost if wrong: a second copy of a small rule.
17. **The close:** "The guard closes the market" at 5:00 is a deadline (`EventObjective`), as the board Festival's square.
    Doing nothing loses then. Cost: none.
18. **No Mayor:** no address, no fountain push. One bonfire burns by the fountain. Cost: none.
19. **Goers hold to the fair:** once at the fair, the town's regroup and evacuation do not take a goer. Market Panic has no
    bell loss. Cost if wrong: without the hold, one bloody strike can bring City Emergency and empty the fair, leaving the
    night unwinnable. The crowds still to come are held the same way (Task 3's fix round): a loud cast must not empty one.
20. **The Informer, the code:** `InformerDirector` extends `AssassinateDirector`, with one quarry and no guards. The base
    gains three switches whose defaults keep The Tax Collector exact:
    - a per-quarry `scheduled` flag (false: no set-out on the strip);
    - a `smoke_out` switch (false: a cast at the hideout's door does nothing);
    - an optional HUD line from the director (`AssassinateObjective` shows it when given).

    Cost if wrong: a fork of the Assassinate code.
21. **Hidden until found:** the informer is indoors, untouchable and untagged until his last contact is turned. He moves
    between houses unseen, on duty, so an evacuation never sends him running. This is what keeps the kill from coming at
    about 1:00 (M2 lesson 1). Cost if wrong: a player never sees the quarry until the end; the tour and hints must say so
    plainly.
22. **The contacts:** four (Task 4's fix ruling: a fourth item, as Market Panic's fourth crowd): the chandler (6.0, -12.4),
    the weaver (-13.7, 12.6), the potter (-1.4, 13.8) and the carpenter (6.2, 13.8). Each is set down at his house's door,
    a quiet one that no soldier's post watches. The spec's first chandler (5.5, -3.0) and weaver (-9.0, 12.0) stood among
    four to six passers-by within 2 units at almost every moment, so an unseen whisper meant waiting on the traffic. Its
    first carpenter (12.0, 12.0) had a south-east tower's post within sight on two towns of ten. All four are tagged DO NOT
    KILL from the start; each names the next. Cost if wrong: a contact in a quiet spot is too easy; move his point.
23. **Visits and the chain:** word reaches them at 0:45, 1:55, 3:00 and 4:05, or 45 s after the contact before is turned,
    whichever is sooner. A contact can be turned only after his visit. With quiet doors the clear is held by the chain
    (four items, 45 s apart), about 3:10. Cost if wrong: one tuning round.
24. **Turning:** a Mind Whisper on the contact while no one else out of doors within 2 sees it (held minds see nothing). A
    contact held by Discord can still be whispered and turned. Cost if wrong: if the engine will not whisper a confused
    person, the scripted policy drops its Discord step.
25. **The company:** three per contact, set down 1.2 from his door on a half ring facing the street (a full ring put some
    inside the house, snapped out of his sight). They walk back after a whisper. There is no relief. Cost if wrong: COMPANY
    is the first tuning knob (2-3).
26. **A dead contact** before he is turned loses the night ("THE TRAIL GOES COLD"), and so does one gone from the town (no
    silent lock until the names' deadline). Every contact's tag, the hint and the tour warn of it from the start. Cost if
    wrong: harsh for a stray strike; the hint says "Do not kill a contact".
27. **The chase:** found, he runs from the carpenter's house to the Temple's door, about 20 units of street (some 13 s),
    with no guards. He hides 20 s when alarmed. Any kill wins; a seen kill calls the bellkeeper. Cost if wrong: a chase
    too short; move the last contact or give him one guard.
28. **Not found in time:** 60 s after the fourth visit, the names reach the Temple by the back lanes, so doing nothing loses
    at 5:05, before dawn. Cost: none.
29. **Informer's tag:** `hunts_informer`; the wish "Kill the informer, unseen" clashes with it. Cost: none.
30. **Camera spots:** The Bell-Ringers (6.0, -5.0), Market Panic (10.0, -8.0), The Informer (4.0, -2.0), each checked
    against the left HUD stack. Cost if wrong: a photo-round move, which moves that scenario's own references once (as
    Spoiled Harvest's did in M2).
31. **The new wishes:** "Scare off the bully, unharmed" (a new Fright kind, 10) and "Free the pressed man" (Rescue, 15).
    Both clash with `unaware_town`. The pool grows from 10 to 12, but Tier 1's seeded draws do not change (controller ruling 3):
    `WishDef.min_tier` and `WishBook.pool_for(tier)` leave the two out of a Tier 1 night's draw before it shuffles. Only the
    tests that pin the pool's contents change. Cost: none.
32. **Free the pressed man:** the son lives at least 15 units from the barracks' door, with at most 40 units of street;
    the two free soldiers nearest him march him; 45 s; turning is `RescueWish.TURNED`. It shares `RescueWish`'s code (a
    soldier list and a goal), so Save my child plays as before. Cost if wrong: a subclass instead of a generalisation.
33. **The carried item:** the strip shows a chained item's real time (`EventTimeline.expect()`, display only). The Tax
    Collector and Spoiled Harvest adopt it with their references exact. Cost: none.
34. **Behaviour scenarios** `ringers`, `panic` and `informer` run the `MissionBook` versions, so their checksums are exact
    references. `--board` stops at the main objective. Cost: none.
35. **The scripted gate** is M2's: wins at least 2 of seeds 1-3, the median clear 180-240 s, `none` loses 3 of 3, no idle
    stretch over 45 s. Each mission names its knobs. Cost: none.
36. **Results titles:** THE RINGERS ARE STOPPED, THE FAIR IS SCATTERED, THE MARKET IS CLOSED, THE INFORMER IS DEAD, THE
    NAMES REACH THE TEMPLE and THE TRAIL GOES COLD, each a reason in `ResultsScreen.ACT_TITLES` under the mission's own key
    (`ringers`, `fair`, `market_closed`, `informer`, `names`, `cold`), never a type's default (M2's final review gave The
    Lost Lamb its own keys for this reason). Cost: none.
37. **FLOW:** Omen's five missions on the board and results steps, and one added step (The Bell-Ringers ascended). FLOW goes
    from 110 to 111. Cost: none.
38. **Board order:** the ★ missions first, then #8, #9 and #10. Cost: none.
39. **The bench:** The Bell-Ringers' board version against Mira's House's. Cost: none.
40. **Market Panic's objective:** `FestivalObjective("Scatter the fair", "fair")`, the close as an `EventObjective`, dawn
    the tier's. Cost: none.
