# KAK v0.11 M2 Whisper: the four new Tier 1 missions (mission spec)

Date: 2026-10-08. Status: for the user's approval. Builds on the v0.11 spec
(`docs/superpowers/specs/2026-10-08-kak-v011-tiers-design.md` §2, §5.3, §7.1, §8 rows 2-5) and M1 as shipped
(`docs/KAK_Version_0.11_Summary.md`, rulings 1-30). M2 makes Tier 1 complete: The Warning plus four new missions, two new
director types (Assassinate, Escort), two generalised ones (Raze, Convert), two new wishes, and two items carried over from
M1's final review.

## 0. What every Tier 1 mission shares

- **Tier 1's numbers:** clock 5:00 (dawn), town Unaware, 3 slots and 6 DP (plus upgrades), 2 wishes heard, believers ×1.
- **Built at their tier:** each new mission is made in `MissionBook` at Tier 1's numbers, so its own clock is 5:00 and its
  board version has stretch 1 (no stretched timeline). No bonuses (ruling 6).
- **No waiting:** everything finishes by acting. Every timed wait is 60 s at most, and where it can, a wait starts only when
  the player engages. Each mission's longest wait is listed under it.
- **Length:** each main objective is designed to take 3-4 minutes. The scripted clear (§9 of the v0.11 spec) must land in
  that window. Each mission names the numbers to tune if it does not.
- **Art:** text and drawn shapes only. Every stand-in is an existing building, person or drawn shape, named by a map tag.
- **Colours** (as M6 and M1): the mission's target gold `d8b23a`, places orange `ff9a3a`, watchers and danger red `c8342a`,
  the god's charges steel blue `8fb8e8`, clear green `7fc46a`, wishes soft blue `8fb8ff`.
- **Mission tags:** every Tier 1 board mission carries `unaware_town` (Decision 17).

## 1. The Tax Collector (Assassinate, new type)

Reshaped by the controller's Task 2 ruling (Decision 4): three collectors in sequence, not one.

- **Brief:** "The tax collector and his deputies make their rounds." / "Strike all three down before the taxes reach the
  Citadel."
- **Card type:** Kill. **Id:** `tax_collector`.
- **Map:**
  - **The counting-house:** the workshop hall in the east quarter (art tag `workshop`), tagged COUNTING-HOUSE.
  - **The collectors:** the tax collector and his two deputies, the three residents nearest its door, each made a noble.
    They wear the noble's cape and crown, so they stand out.
  - **Their guards:** the free soldiers nearest the counting-house: two for the collector, one for each deputy.
  - **Their debtors:** each collector's own round, the dwellings nearest these spots whose doors the street reaches (a house
    walled in by its neighbours is passed over):
    - the collector: (6.5, 11.5), (-8.0, 11.5), (-10.0, 2.5), the south-east quarter by the gate plaza, the south-west and
      the west;
    - the first deputy: (6.0, -10.4), (-3.4, -10.4), the north-east and north-west blocks;
    - the second deputy: (6.2, 5.4), (-3.5, 12.5), (-7.6, 5.4), the east block by the barracks, the south quarter and the
      west.
  - **Their safe place:** the Citadel's gate at (-10.5, -7.6) (`RescueWish.GATE`).
- **Main objective:** kill all three collectors (any way). **Won** the moment the third dies. **Lost** when any reaches the
  Citadel's gate with the taxes ("THE TAXES ARE IN"), when the bell tolls, or at dawn.
- **People and behaviour:**
  - **Inside:** all three start in the counting-house, counting the take. Indoors they are hidden and cannot be touched.
  - **Their rounds:** the collector sets out at 0:45. Each deputy sets out at his own time (1:45, 2:45) or 45 s after the
    collector before him dies, whichever is sooner (the board Warning's stars' rule: no idle wait over 60 s). One still
    alive never holds the next back: at his own time the next sets out all the same. Each walks to each of his debtors'
    doors in turn, goes in to collect for 15 s, then walks on. After his last he walks to the Citadel's gate.
  - **Smoked out:** a power cast within 4 units of the counting-house's door while no collector is out sends the next one
    out at once.
  - **Their guards** walk 0.6 units from their collector, inside Silent Doom's reach. A Doom that takes him takes them too.
  - **Alarmed:** a loud power cast within 4 units of a collector in the street, one of his guards falling (unless with him,
    in the same blow), or a fright sends him to hide in the counting-house for 30 s. Then he takes his rounds up at the
    next debtor.
  - **Flushed:** the house a collector is in set alight or destroyed sends him out of it in a fright. For the
    counting-house that means those out on their rounds who hide there; those still waiting to set out stay in, and set
    out at their own time or by the chain, so one fire never sets the whole night out at once.
  - **No hiding place:** once the counting-house is gone, an alarm sends him running for the Citadel.
  - **Unseen:** each death is judged as the Prince's is. If anyone living stands within 2 units of where he falls (once a
    Doom's other victims have fallen), the guards cry murder and the bellkeeper is called. On the board the night is then
    caught by the bell (wishes lost) unless the god ascends first or stops the bellkeeper (Decision 3).
- **Timeline** (left alone, seeds 1-3):

  | Time | Event |
  |---|---|
  | 0:00 | Counting in the counting-house |
  | 0:45 | "The tax collector sets out", or earlier if smoked out |
  | ~0:55-1:10 | His first debtor: 15 s indoors |
  | 1:45 | "A deputy sets out" (sooner: 45 s after the collector dies) |
  | ~2:22-2:34 | The collector reaches the Citadel's gate: lost |
  | 2:45 | "A deputy sets out" (sooner: 45 s after the first deputy dies) |
  | 5:00 | Dawn |

  A round stretches by 30 s for each alarm. The longest waits are 45 s, at the start (smoking him out cuts it short), and
  45 s between one collector's death and the next one's setting out.
- **Tags:**
  - TAX COLLECTOR or DEPUTY on each collector out, gold, with an edge arrow. While one is indoors it reads TAX COLLECTOR -
    INSIDE (DEPUTY - INSIDE) over that door. With none out, the next one is tagged so over the counting-house's door.
  - COUNTING-HOUSE, orange.
  - DEBTOR on the house each collector out is heading to or inside, orange (with none out, the next one's first).
  - CITADEL, red, once one heads there.
  - NEXT COLLECTOR, orange, at the counting-house's door while one is out and another still waits (as the Warning's NEXT
    STAR).
  - A red diamond on everyone who would see a Silent Doom on a collector in the street (within 2 units, beyond the Doom's
    0.8). A blue diamond on each guard, who would fall with him.
- **Hint phases** (for the first collector out, else the next one waiting):

  | Phase | Line |
  |---|---|
  | (none) | Kill each collector (gold) in the street. If no one near (red) sees it, the guards raise no cry. |
  | `inside` | He is indoors (gold). He comes out to walk to his next debtor (orange): be ready. |
  | `hiding` | Alarmed, he hides in the counting-house. Set it alight to smoke him out, or wait for him. |
  | `safe` | His rounds are done. He takes the taxes to the Citadel (red): kill him before he gets in. |
  | `next` | One down. The next collector (gold) leaves the counting-house soon: be ready for him. |
- **HUD:** "Kill the collectors: 1 / 3", with ", he hides" or ", rounds done" for the first collector out.
- **Tour:**
  1. "The counting-house. The tax collector sets out at 0:45, his deputies by 1:45 and 2:45."
  2. "His first debtor. He goes in to collect, then walks on."
  3. "The Citadel. A collector whose rounds are done takes the taxes in."
- **Mission tags:** `unaware_town` (derived), `hunts_tax_collector`. The second keeps the wish "Strike down the cruel tax
  collector" away.
- **Results:** "THE COLLECTORS ARE DEAD" (`collector`), "THE TAXES ARE IN" (`taxes`).
- **Numbers:** first guesses SET_OUT_AT 45 / 105 / 165, CHAIN_WAIT 40, VISIT 25, HIDE 30, ALARM_REACH 4.0, GUARDS 2 / 1 / 1,
  GUARD_R 0.6, the second deputy with two debtors. Task 2 tuned CHAIN_WAIT to 45, VISIT to 15 and gave the second deputy a
  third debtor (its report has the runs). Tune in this order if the scripted clear misses 3-4 minutes: SET_OUT_AT (the
  first at most 60), CHAIN_WAIT (30-50), VISIT, HIDE, ALARM_REACH, GUARDS / GUARD_R, the debtor spots.

## 2. Spoiled Harvest (Raze, generalised)

Reshaped by the controller's Task 3 fix-round ruling (work, not waiting): no seal; each granary has a watchman.

- **Brief:** "Carts empty the granaries to the Citadel." / "Spoil the harvest before they do."
- **Card type:** Destroy. **Id:** `spoiled_harvest`.
- **Map:**
  - **Three granary stores:** the dwellings nearest (-9.0, 12.0), (12.0, 12.0) and (12.0, -12.0), named the south-west,
    south-east and north-east granaries. All three are far from the Citadel, and all three are open to the god from the start.
  - **The watchmen:** at each granary's door stands a watchman, the lay citizen nearest it.
  - **The carters:** for each granary, the lay citizen nearest the Citadel's gate not already at work.
- **Main objective:** spoil all three granaries. A granary is spoiled once it has burned 10 s in all, or is destroyed
  (the controller's Task 3 ruling: a 50-hp house burns down in about 13 s, so the first guess of 15 s could never be reached).
  - **Won** the moment the third is spoiled.
  - **Lost** the moment any granary is emptied ("A GRANARY IS EMPTIED": a store emptied cannot be spoiled), or at dawn.
- **People and behaviour:**
  - **The watchman:** while he is alive, out of doors, at his post and calm (not frightened, fleeing, confused, whispered,
    compelled or fighting), he holds his post while his granary burns and beats the fire out after 3 s. What it had burned is
    forgotten. The god must first remove him (strike him down, scare him off, whisper him away, Discord him), then keep the
    fire burning 10 s in all, or bring the granary down.
  - **His return:** a watchman off his post who is calm again is sent back to it 20 s after he left; a fallen one is replaced
    by the nearest lay citizen 30 s after he fell.
  - **The carts:** at 0:30, 1:30 and 2:30 a granary's carter sets out from the Citadel's gate for its door. He takes a load at
    the granary and carries it to the Citadel's gate, again and again. Each granary holds 6 loads, and taking the last empties it.
  - **The god's hand:** a frightened, whispered or confused carter is left be, and takes his errand up again after.
  - **Felled carters** are not replaced. A spoiled granary's carters and watchman go home.
  - **Fire:** the town answers a fire as it always does. Its fire crews douse it, and that is the Raze type's "repair crews".
- **Timeline:**

  | Time | Event |
  |---|---|
  | 0:30 | "The south-west granary's carts set out" |
  | 1:30 | "The south-east granary's carts set out" |
  | 2:30 | "The north-east granary's carts set out" |
  | ~3:30 | Left alone, the south-west granary is emptied: lost |
  | 5:00 | Dawn |

  There is no idle wait: every granary can be worked on from the first second. The timed waits are 30 s (the first carts),
  60 s (between carts), 20 s (a watchman's return) and 30 s (a relief). Measured (Task 3 fix round): the scripted player,
  cooldown-limited (Silent Doom 10 s, Ember 15 s), clears all three in about 0:42, below the 3-4 minute target; see the
  Task 3 report for the numbers and the options.
- **Tags:** each granary, gold:
  - carts still to come: GRANARY - CARTS IN 0:12 (the time left to them), with an edge arrow;
  - carts out: GRANARY - 3 LEFT;
  - burning: GRANARY - BURNING 9, orange;
  - spoiled: untagged.

  A red diamond labelled WATCHMAN on each watchman on guard (a small red mark while he is away), and a steel-blue diamond on
  each carter.
- **Hint phases:**

  | Phase | Line |
  |---|---|
  | (none) | Remove a granary's watchman (red), then keep it burning 10 s before its carters (blue) empty it. |
  | `watchman` | The watchman (red) puts the fire out within 3 s. Strike him down, scare him off or whisper him away first. |
  | `burning` | It burns, with no one to put it out. Keep it burning 10 s, or bring it down, before a new watchman comes. |
- **Tour:**
  1. "The south-west granary. Its watchman puts out fires. Its carts set out at 0:30."
  2. "The south-east granary. Its watchman puts out fires. Its carts set out at 1:30."
  3. "The north-east granary. Its watchman puts out fires. Its carts set out at 2:30."
  4. "The Citadel. Carts carry the grain here. An emptied granary cannot be spoiled."
- **Mission tags:** `unaware_town` (derived).
- **Results:** "THE HARVEST IS SPOILED" (`spoiled`), "A GRANARY IS EMPTIED" (`emptied`).
- **Numbers:** first guesses CART_AT 30 / 90 / 150, SPOIL 10 (the ruling), LOADS 5, CARTERS 1, SMOTHER_AFTER 3, RETURN_AFTER 20,
  RELIEF_AFTER 30. Task 3's fix round set LOADS to 6 so that doing nothing loses at about 3:30. Tune in this order if the
  scripted clear misses 3-4 minutes: CART_AT, RELIEF_AFTER, RETURN_AFTER, the watchmen per granary (SPOIL stays 10).

## 3. The Lost Lamb (Escort, new type)

- **Brief:** "A runaway acolyte hides from the Temple." / "Lead him out through the west gate."
- **Card type:** Protect. **Id:** `lost_lamb`.
- **Map:**
  - **The acolyte:** the cleric nearest the north-east fountain, set down there at (11.4, -10.0). He moves at 0.6 of his pace.
  - **The west gate:** the Main Gate, on screen the lower-left wall (Decision 10). Its way out is (2.7, 17.6) on the south
    road.
  - **The gate's watch:** the two free soldiers nearest the gate's mouth, posted at (2.0, 14.6) and (3.4, 14.6).
  - **Two patrols** of two soldiers each:
    - one walks the south street from (-6.0, 9.0) to (10.0, 9.0) and back;
    - one walks the market's street from (2.7, -4.0) to (2.7, 8.0) and back.
  - **The Temple's door** at (0.8, -5.0).
- **Main objective:** lead him out. **Won** the moment he reaches the way out. **Lost** if he is taken back to the
  Temple's door ("THE LAMB IS TAKEN BACK"), if he dies ("THE ACOLYTE IS DEAD"), or at dawn.
- **People and behaviour:**
  - **The god's hand:** he moves only by the god's hand, a Mind Whisper or a Will-o'-Wisp's lure. Otherwise he holds where
    he was left.
  - **Seized:** any of the watch, the patrols or the searchers within 2.5 units seizes him on sight. A seizer held by
    Discord or a whisper, or turned, sees nothing. The seizer marches him back toward the Temple's door.
  - **Freed:** felling the seizer frees the acolyte where he stands. So does turning him, or a town order taking him off
    the errand. A whisper on the acolyte alone does not free him.
  - **The watch change:** 30 s after the acolyte first comes within 6 units of the gate's mouth, the watch walks to the
    guardhouse (6 units east along the wall) for 15 s. While they are gone the gate is clear. From then on the change repeats
    every 45 s. The god can also clear the gate by acting on the watch.
  - **Searchers:** at 1:30 the Temple sends two soldiers (the free soldiers nearest its door) after him. They walk to wherever
    he is and seize him on sight. Left alone, he is taken back long before dawn.
- **Timeline:**

  | Time | Event |
  |---|---|
  | 0:00 | He hides by the north-east fountain. The patrols walk their beats. |
  | 1:30 | "The Temple sends searchers" |
  | +30 s after he first nears the gate | "The watch changes": the gate is clear for 15 s, every 45 s |
  | ~2:30 | Left alone, he is seized and marched back (lost by about 2:50) |
  | 5:00 | Dawn |

  The longest wait is 30 s, at the gate. It starts when the player brings him there.
- **Tags:**
  - ACOLYTE, blue, with an edge arrow. While seized it reads ACOLYTE - CAUGHT, red.
  - WEST GATE - WATCHED (red) or WEST GATE - CLEAR (green) at the way out.
  - TAKING HIM BACK, red with an edge arrow, on the seizer. TEMPLE, red, while he is held.
  - SEARCHER, red with an edge arrow, on each searcher.
  - PATROL, red, on each patrol's first soldier. A red diamond on every other patrol soldier and on the watch.
- **Hint phases:**

  | Phase | Line |
  |---|---|
  | (none) | Whisper the acolyte (blue) to the west gate. Soldiers (red) seize him on sight: keep him clear. |
  | `caught` | He is caught. Kill or turn the soldier taking him back (red) before they reach the Temple. |
  | `gate` | The watch (red) holds the gate. It changes soon: bring him close, or draw the watch off. |
  | `clear` | The watch is changing. Send him through the gate now. |
- **Tour:**
  1. "The runaway acolyte hides by the north-east fountain."
  2. "The west gate. Its watch changes soon after he draws near."
  3. "The Temple. At 1:30 it sends searchers after him."
- **Mission tags:** `unaware_town` (derived).
- **Results:** "THE LAMB IS FREE" (`out`), "THE LAMB IS TAKEN BACK" (`taken`), "THE ACOLYTE IS DEAD" (`lamb`).
- **First guesses** (tune order): CHARGE_PACE 0.6, the start spot, SIGHT 2.5, HUNT_AT 90, WATCH_CHANGE 30 / WATCH_GAP 15 /
  WATCH_CYCLE 45, the beats.

## 4. First Prayers (Convert, generalised from Mira's House)

- **Brief:** "The poor have no shrine of their own." / "Lead three to the old well, unseen."
- **Card type:** Cult. **Id:** `first_prayers`.
- **Map:**
  - **The old well shrine:** a stone shrine post (Broken Lanterns' drawn shape) at (-4.4, 2.8), moved to free ground. It
    stands on the market's west edge by the west tavern. It cannot be destroyed: a blow only shakes it.
  - **The poor:** the 8 lay citizens nearest (-11.0, 12.0), in the south-west quarter.
  - **Halcyon's Faithful:** few of them. The 3 clergy nearest the Temple's door, plus 3 lay citizens spread through the town.
    There is no Inquisitor.
- **Main objective:** three of the poor believe and are out of doors.
  - **Won** the moment the third walks out of the shrine.
  - **Lost** if the Lantern looks (a full Gaze), or if fewer than three believe at dawn.
- **People and behaviour** (Mira's rules unless said):
  - **Praying:** a poor citizen whispered to the shrine's door (or lured to a light by it) goes down the old well's steps
    and prays, hidden, for 25 s. He comes out a Believer. Only one prays at a time: the next waits at the door.
  - **Turned away:** a Faithful within 3 units of the door who sees someone go in turns them away and runs to the Temple to
    report it. One who sees a Believer come out lets them go, and runs to report. A report that reaches the Temple fills
    the Gaze.
  - **The Gaze:** a seen death adds to it, and the bell fills it.
  - **The market:** the shrine sits by the market. The market fills at 1:15 and the priests come at 2:30, and each time
    Faithful stand at its door.
- **Timeline:**

  | Time | Event |
  |---|---|
  | 0:00 | "LEAD THE POOR TO THE OLD WELL" |
  | 1:15 | "The market fills": up to four free Faithful stand by the shrine's door for 40 s |
  | 2:30 | "The priests come to the well": up to two more stand there for 40 s |
  | 5:00 | Dawn: too few believe, lost |

  The longest waits are 40 s (the Faithful at the door, which Discord or a lure can cut short) and 25 s (one praying
  before the next).
- **Tags** (Mira's, renamed):
  - OLD WELL SHRINE, gold, outlined, with an edge arrow.
  - DOOR - CLEAR (green) or DOOR - WATCHED (red).
  - TO THE TEMPLE, red with an edge arrow, on each runner. TEMPLE, red, while a report runs.
  - A red diamond on each Faithful watching the door.
  - A gold diamond on each of the poor. An orange one on each Believer.
- **Hint phases:**

  | Phase | Line |
  |---|---|
  | (none) | Whisper the poor (gold) to the old well shrine while no Faithful (red) watches. Three must pray. |
  | `watched` | Faithful (red) crowd the shrine's door. Draw them off, or let them go before you send anyone in. |
- **Tour:**
  1. "The old well shrine, by the market. Lead the poor here."
  2. "The poor of the south-west quarter. Three must pray at the well."
  3. "The Temple. A Faithful who sees you runs here."
- **Mission tags:** `unaware_town` (derived).
- **Results:** "THEY BELIEVE" (`believers`), "TOO FEW BELIEVE" (`few`), "THE LANTERN LOOKS" (`gaze`). All three titles exist
  already.
- **First guesses** (tune order): PRAY 25, the poor's spot, MARKET_AT 75 / PRIESTS_AT 150 (each 40 s), FAITHFUL 3 + 3.

## 5. New wishes for Tier 1

The pool grows from 8 to 10. Both new wishes may be heard in an Unaware town.

| Wish | Kind | Act | Reward | Needs / clashes |
|---|---|---|---|---|
| Stop the bailiff | Rescue | Once engaged (his tag or the home's clicked, or a cast within 2 of either), the bailiff walks from his post to the wisher's home. Kill him, turn him, or keep him from the door for 50 s. | 15 | a lay citizen with a home, and a free soldier at least 10 units from it; — |
| Let my neighbours believe | Faith | Whisper three of the wisher's neighbours (marked) to within 2 units of the wisher. Each one believes. | 10 | three lay citizens living within 8 of the wisher's home, not of the household; — |

- **"Strike down the cruel tax collector"** now also clashes with `hunts_tax_collector`, so it is never heard on The Tax
  Collector's night.
- **Tags:** BAILIFF and HOME, NEIGHBOUR.
- **Failing:**
  - Stop the bailiff fails when he reaches the door.
  - Let my neighbours believe fails when a neighbour dies before believing.
  - Both fail when the wisher dies (as every wish does).

## 6. The two items carried from M1's final review

1. **`RescueWish.TURNED` gains `Person.Mind.FIGHT`.** A soldier turned by a fight power (Turncoat, Manufactured Hatred) is
   the god's doing, so Save my child is granted. Stop the bailiff uses the same list.
2. **The Warning's tour says "by".** Its later stars can fall sooner (30 s after the previous warning dies), so the tour reads
   "The Main Gate. A star falls here by 1:30." and "The Side Gate. A star falls here by 3:00." The first star still reads
   "at 0:10". `test_starfall` pins both.

## 7. Decisions

These are the details the v0.11 spec left open. The controller records them as rulings.

1. **Ids and building:** the ids are `tax_collector`, `spoiled_harvest`, `lost_lamb` and `first_prayers`. They are built in a
   new `MissionBook.tier_missions()` at Tier 1's numbers (5:00, Unaware, 3 / 6, no bonuses), so `TierBook.board()` needs no
   per-mission branch for them and their stretch is 1. They are not in `MissionBook.all()` (the interlude's list) nor the
   campaign.
2. **Unlocking:** Tier 1 now has five missions, so Omen opens at 3 of them cleared (spec §3.2's full rule). A save that
   opened Omen with The Warning alone keeps it open: a tier never closes.
3. **Unseen, for the Tax Collector:** it is not a bonus (ruling 6). A seen kill makes the guards cry murder and calls the
   bellkeeper. The kill still wins (the main objective is "kill him"). On the board the bell tolling after it catches the
   night and loses the wishes, unless the god ascends or stops the bellkeeper first. So "unseen" protects the night's wishes.
4. **The Tax Collector's length** (rewritten by the controller's Task 2 ruling, which overrides the first text): one
   target could be killed at about 1:00, against the user's rule of at least five minutes of play with a 3-4 minute main
   objective. So the night has three targets in sequence -- the tax collector and his two deputies, each on his own round
   with his own guards -- and the main objective is all three dead. Each deputy sets out at his own time (1:45, 2:45) or a
   chain wait after the one before him dies, whichever is sooner; the chain wait is tunable 30-50 s (45 s as tuned), so no
   idle wait passes 60 s. Any one reaching the Citadel's gate still loses the night, and a seen kill still calls the
   bellkeeper. The type is generic (`AssassinateDirector`: N targets with schedules), so The Informer and The Bishop can
   reuse it. Nothing makes a target untouchable in the street: that would add a new kind of protection the code does not
   have.
5. **Stand-ins:** the counting-house is the workshop hall. Each collector's debtors are the dwellings nearest his fixed
   spots whose doors the street reaches. The tax collector and his two deputies are residents made nobles, so their capes
   and crowns pick them out.
6. **Alarm:** a loud (not quiet) power cast within 4 units of a collector in the street, one of his guards falling, or a
   fright sends that collector to hide 30 s. A fire on, or the fall of, the house a collector is in flushes him out (but
   never the collectors still waiting in the counting-house). With the counting-house gone, an alarm sends a collector to
   the Citadel. Quiet powers never alarm the collectors.
7. **Raze:** Raze is generalised as a new `RazeDirector` base (targets, a spoil time, sealing). Last Judgement's and
   Judgement's directors are left as they are (the Citadel judges itself), so their references hold.
8. **Watchmen, not seals:** the granaries are dwellings, all open to the god from the start. Each has a watchman who beats
   out its fire after 3 s while he is alive, out of doors, at his post and calm (a fire at his granary does not frighten him);
   the god removes him first. A watchman returns 20 s after a fright and a relief comes 30 s after one falls. "Spoiled" means
   burned 10 s in all, or destroyed. The first granary emptied loses at once. The Raze base keeps an optional seal that no
   mission uses.
9. **Carters:** one lay citizen per granary, from near the Citadel, setting out at 0:30, 1:30 and 2:30. A load is counted when it
   is taken at the granary, which is what empties it. Felled carters are not replaced.
10. **The west gate:** "the west gate" is the Main Gate, which stands on the lower-left wall on screen. The postern is barred
    in an Unaware town (no boats), and the Side Gate is on the right.
11. **Seizing:** the acolyte moves only by the god's hand and holds where left. He is seized on sight (2.5 units) by the
    patrols, the gate's watch and the searchers. A seizer in a blind mind (`MissionDirector.BLIND`) or a turned one
    (`RescueWish.TURNED`) never seizes. He is freed when the seizer is felled, turned, or taken off the errand by a town
    order. A whisper on him alone does not free him.
12. **The watch change** starts 30 s after he first comes within 6 units of the gate, so the wait starts when the player
    engages. The watch is away 15 s and the change repeats every 45 s.
13. **The searchers** set out at 1:30, so doing nothing loses well before dawn.
14. **Convert:** Convert is generalised by subclassing `MirasHouseDirector`. It gains `need`, `read_seconds` and
    `one_at_a_time` (defaults: 4, 8, false) and an `_opening_banner()` hook. `BelieversObjective` reads `need` from the
    director. Mira's House plays exactly as before.
15. **The old well shrine:** a drawn stone shrine post (`Structure.Kind.SHRINE`, Broken Lanterns' shape) at the market's west
    edge. It cannot be destroyed. People led there pray hidden ("down the well's steps") for 25 s, one at a time.
16. **Few Faithful:** three clergy and three lay citizens, and no Inquisitor. The two events (the market at 1:15, the
    priests at 2:30) reuse the Vigil's line of Faithful at the door, 40 s each.
17. **`unaware_town`** is derived in `TierBook.board()` from the board mission's readiness (Unaware or lower), not declared
    per mission. The Warning's `MISSION_TAGS` entry goes.
18. **Wish buildings reserved:** `Wish.places()` (RuinWish's target) is reserved on the director as `reserved_places`, so no
    director makes a wish's building its granary or a debtor's house.
19. **Eligibility helpers:** `MissionDirector._eligible()`, `_free_soldiers()`, `_lay_near()`, `_citizen_near()` and
    `_house_near()` all skip reserved people and places, so a new director cannot forget.
20. **Town-wide orders:** the new directors leave alone a soldier the rally or the marshals have taken (his mind is not on
    post or calm, or his corps is not none). They tolerate the loss and do not fight the order.
21. **Stop the bailiff:** 50 s is how long he has. The wish is granted when he is killed, turned, or still short of the door
    at 50 s, and failed when he reaches it. It is engaged as Save my child is.
22. **Let my neighbours believe:** the neighbours live within 8 of the home and are not of the household. Each counts once
    whispered to within 2 of the wisher.
23. **Tax collector clash:** the tax collector wish clashes with The Tax Collector (mission tag `hunts_tax_collector`).
24. **Behaviour scenarios** run the `MissionBook` versions (the same director, clock and town, no wishes), so their checksums
    are exact references. `--board` is accepted too, and stops at the main objective.
25. **The scripted gate:** the scripted player wins at least 2 of seeds 1-3, and the median time to the main objective of its
    wins is 180-240 s. Each mission names the knobs to tune if not.
26. **Results titles** for the new reasons are as listed in §1-§4 (The Tax Collector's win reads "THE COLLECTORS ARE
    DEAD").
27. **The Warning's tour:** the first star "at 0:10", the later two "by".
28. **Five cards on the Whisper tab** are 115 px wide. A card's best line wraps above its rule when it does not fit.
29. **FLOW:** the board and results steps change for Tier 1's five missions, and one step is added (The Tax Collector from
    the board, then abandoned through Pause). FLOW goes from 109 to 110.
