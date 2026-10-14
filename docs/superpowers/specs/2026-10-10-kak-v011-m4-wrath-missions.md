# KAK v0.11 M4 Wrath: the three new Tier 3 missions (mission spec)

Date: 2026-10-10. Status: for the user's approval. Builds on the v0.11 spec
(`docs/superpowers/specs/2026-10-08-kak-v011-tiers-design.md` §2, §4, §5, §7.1, §8 rows 11-15), M1 (rulings 1-30), M2 as
shipped (rulings 31-63 in `docs/KAK_Version_0.11_Summary.md`) and M3 as tuned
(`docs/superpowers/specs/2026-10-09-kak-v011-m3-omen-missions.md`, Decisions 1-40, plan decisions 41-56, the ledger's rulings).
M4 makes Tier 3 complete: The Vigil Flame and The Festival, plus three new missions (Raze and Escort reused, Hunt new), two new
wishes, and the board, photos and notes.

## 0. What every Tier 3 mission shares

- **Tier 3's numbers:** clock 6:00 (dawn), town Prepared, 4 slots and 10 DP (plus upgrades), 3 wishes heard, believers ×2 (the
  main objective pays 20).
- **Built at their tier:** each new mission is made in `MissionBook.tier_missions()` by a new `_tier3()` frame, as M3's
  `_tier2()`:
  - `tier` 3, `clock` 360 s, `slots` 4, `dp_capacity` 10;
  - `tier_floor` 3 (Prepared) and no `profile`, so a scripted run meets the board's town;
  - no bonuses, `intro_banner` the name in capitals;
  - every power allowed unless the mission narrows its pool. Its board version has stretch 1.
- **The Prepared town** (`ResponseProfile.for_tier(PREPARED)`, as The Vigil Flame and The Festival meet on the board):
  - the bell climbs in 8 s, and two soldiers guard whoever is on the rope (`escorts_per_duty` 2);
  - four seen deaths or collapses in one district make a Local Emergency;
  - a fire brigade of four turns out from Local Emergency;
  - two engineer teams turn out from City Emergency and mend what the god breaks;
  - the Banishing Rite at City Emergency (45 s, four clergy) takes 40 s off the clock;
  - river boats: the postern is open, the way down to the dock;
  - four marshals at each way out at the evacuation, four rescue squads.
- **No bell loss:** none of M4's missions loses on the bell. A seen kill raises the town as it always does; it never ends the
  night by itself.
- **Mission tags:** a Prepared town carries no `unaware_town`, so every Tier 2 wish and both new wishes (§5) can be heard.
- **No waiting:** everything finishes by acting. Every timed wait is 60 s at most. Each mission lists its longest wait.
- **The chain rule** (M2, M3): each item comes at its scheduled time or 45 s after the one before is done, whichever is sooner.
  One still open never holds the next back. The strip shows the chained time (`EventTimeline.expect()`, M3 §6).
- **The clear arithmetic** (M3 lesson): with N chained items, a skilled clear is about
  `first wait + (N - 1) × 45 s + the work after each item comes`. Work the player can do ahead (the next item's guards, cleared
  in the last 25 s before it comes) does not count. Each mission shows its sum. Two missions are chain-bound; The Prisoner is an
  escort, bound by her walk.
- **Length and the gate** (M2 ruling 55), per mission, seeds 1-3:
  - doing nothing loses 3 of 3;
  - the scripted player wins at least 2 of 3;
  - the median of its wins is 180-240 s;
  - its longest stretch between two casts (`idle=`) is 45 s or less.
- **Own people** (M2 lesson 4, M3 lesson 6): every person a director uses is a lay citizen it appoints and dresses, never a town
  soldier, so the rally, the marshals and the rite never take one. Every choice goes through `MissionDirector._eligible()`,
  `_lay_near()`, `_house_near()`, so no wisher, wish target or wish building is ever taken. Each mission lists its claims.
- **Held on duty** (M3 lesson 4): every person whose loss would change the night is put on duty at his place from setup
  (`Person.go_duty()`), so the town's regroup and evacuation pass him by. Only the god's hand moves him; back on his feet he
  walks back. People waiting for their time wait indoors, untouchable.
- **No hidden losses:** a stray kill never makes a night unwinnable without a plain warning on the person's tag
  ("DO NOT KILL"). A person leaving the town resolves at once. Each mission says how.
- **No relays:** no M4 mission passes an errand from a dead man to a witness. M3's open cross-task note (a relay may pick a wish's
  person) does not reach M4.
- **Camera:** each `camera_at` keeps every key target, or its edge arrow, out of the dead zone under the left HUD stack (about
  230×70 px at the top-left; ground points 8-18 units west of the camera). Every moving target's tag has an edge arrow. Each
  mission's tests check its spots with the kit's `clear_of_stack()`.
- **Art:** text and drawn shapes only.
  - Gaolers, Inquisitors and the captain's escort are made `CitizenProfile.Role.WATCHMAN` (the watch cloak and lantern).
  - The Crown's engineers are made `Role.ENGINEER` (the leather apron, cap and hammer the town's engineers wear).
  - The hunt's captain is made `Role.NOBLE` (the purple cape and crown, as the tax collectors).
  - The stocks are a drawn market stall; the lantern-standards are Broken Lanterns' drawn shrine post. Every other stand-in is
    an existing building or person named by a map tag.
- **Colours** (as M2, M3): target gold `d8b23a`, places orange `ff9a3a`, watchers and danger red `c8342a`, the god's charges
  steel blue `8fb8e8`, not yet grey `9a948a`, clear green `7fc46a`, wishes soft blue `8fb8ff`.
- **The ★ missions** keep their directors, rules and stretches on the board (The Vigil Flame ×2.0; The Festival 80 of 120,
  closing at 4:30). M4 does not touch them.

## 1. The Crown's Bread (Raze, reused)

M3 lesson 1 and M2's Spoiled Harvest: three open targets fall in about 1:30 to a skilled player. So each target comes into use on
the chain, and each brings fresh work when it does. Nothing is sealed: every target takes every blow from 0:00.

- **Brief:** "The Crown's bread is made tonight." / "Destroy the granary, the mill and the bridge."
- **Card type:** Destroy. **Id:** `crowns_bread`.
- **Map** (the bread's road along the river, south and east of the walls):
  - **The granary:** the farmhouse by the east road, `TownLayout.BARNS[3]` (centre (20.15, 17.95)), tagged GRANARY. 50 hp; it
    burns.
  - **The mill:** the watermill on the south bank, `TownLayout.WATERMILL` (centre (-5.7, 25.95)), tagged MILL. 50 hp; it
    burns.
  - **The bridge:** the stone bridge on the south road, `TownLayout.BRIDGE` (`Town.bridge`, centre (2.7, 22.2)), tagged BRIDGE.
    140 hp; it does not burn. Only blows bring it down.
  - The three stand 9-18 units apart: one Heaven Splitter (10 long) cannot reach two.
  - **The shifts' waiting places:** the granary's and the mill's shifts wait inside their own building. The bridge's waits in
    the Main Gate's west tower (`GATE_TOWERS[0]`), or the east one if a wish has set the west one aside.
  - **The camera** rests at (6.0, 20.0), above the Main Gate's road. The bridge is just left of the centre, the granary at the
    right, the mill toward the left edge at mid height. None sits in the HUD stack's corner.
- **Claims:** 15 lay citizens made engineers: a night crew of two and a shift of three at each target, the nearest free ones to
  each post. Reliefs as they are needed. No soldiers. The targets are fixed buildings; no wish can take one (the barn wish
  clashes, §5).
- **Main objective:** raze all three.
  - **Razed:** a target that falls while it is in use (below), or one that is down when its time comes. It stays razed.
  - **Won** the moment the third is razed.
  - **Lost** when the Crown's carts roll at 5:00 ("THE CROWN IS FED"), or at dawn.
- **People and behaviour:**
  - **In use** (the stages; Spoiled Harvest's grain rule, `RazeDirector._spoilable()`):
    - the granary at 0:45 ("THE GRAIN CARTS FILL THE GRANARY");
    - the mill at 1:55, or 45 s after the granary is razed ("THE MILL GRINDS THE CROWN'S FLOUR");
    - the bridge at 3:05, or 45 s after the mill is razed ("THE BREAD CARTS GATHER AT THE BRIDGE").
  - **Before its time:** blows land and a target can fall. A fire on it is put out at once (the Raze base's rule for a target
    not yet spoilable). Its crew mends it and rebuilds a fall. A target still down when its time comes is razed at once, so
    holding one down is never wasted, only hard.
  - **The night crew:** two engineers at each target from the start, on posts along its open face (`_open_door()` from the
    nearest town gate), 1.8 apart, so one Silent Doom takes one.
  - **The shift:** at its time, three more engineers come out at each target, each at his own post: 1.8 beyond the night crew's
    (the third 1.8 out from the face), every post of the crew more than two Silent Doom radii from the others, so one strike never
    clears a stage. Before that they are indoors and untouchable. A fire or the fall of the building they wait in does not
    bring them out early. This is the work that cannot be done ahead.
  - **On guard:** alive, out of doors, within 2.5 of the target, and calm (Spoiled Harvest's `GUARD_MINDS`). A crewman on guard
    holds his post while his target burns (Spoiled Harvest's `HOLD_POST`).
  - **The engineers' work**, while on guard:
    - **mend:** each gives back 2.5% of the target's health a second (two make the town's engineers' 5%);
    - **put out fire:** a fire is beaten out once it has burned 3 s with one on guard;
    - **rebuild:** a fallen target not in use stands again (`Structure.restore()`) after 20 s with two on guard, or 40 s with
      one.
  - **Return and relief** (Spoiled Harvest's rules): a crewman off his post and calm again walks back 20 s after he left. A
    fallen one is replaced 30 s after he fell by the nearest free lay citizen with a route to the post, made an engineer. So
    clearing a crew long before its time is undone.
  - **Razed:** its crew and shift go home (Spoiled Harvest's `_release()`).
  - **The town keeps off:** the town's own engineer teams leave the three targets alone (`EngineerManager.hands_off`, §6), so
    the only crews are the ones the player sees tagged. The town's fire brigade answers a fire as it always does.
  - **The bridge** cuts the south bank when it falls. It is the last target, so this only ends the night.
- **Timeline** (left alone):

  | Time | Event |
  |---|---|
  | 0:00 | "THE CROWN'S BREAD". The night crews stand at all three targets. |
  | 0:45 | "The grain carts fill the granary": its shift comes out |
  | 1:55 | "The mill grinds the Crown's flour" (sooner: 45 s after the granary is razed) |
  | 3:05 | "The bread carts gather at the bridge" (sooner: 45 s after the mill is razed) |
  | 5:00 | "The Crown's carts roll": lost unless all three are razed |
  | 6:00 | Dawn |

- **The clear:** first wait 45 + granary 15 (the shift: a Doom, a Smite that also strikes the granary, an Ember) + 45 +
  mill 15 + 45 + bridge 35 (the shift, then 140 hp of blows: four Smites at 10 s) ≈ **200 s**. With nothing done ahead, the
  work rises to about 25 / 25 / 45 s, ≈ 230 s. Measured (Task 2's gate, seeds 1-3): 195.3 / 216.3 / 203.0 s, median 203.0;
  the median run's sum is 45 + granary about 10 + 45 + mill about 15 + 45 + bridge about 43 ≈ 203 s.
- **Longest waits:** 45 s to the first stage, and 45 s between a target razed and the next one's time. In both, the next night
  crew can be cleared in the last 25 s.
- **Tags:**
  - Each target not razed, with an edge arrow:
    - not in use: "MILL - IN USE BY 1:55" (the sooner time), grey;
    - not in use and down: "MILL - DOWN, REBUILT IN 14" while a crew rebuilds it, else "MILL - DOWN", grey;
    - in use: "MILL", gold; burning: "MILL - BURNING", orange.
  - ENGINEER on each crewman on guard, red. A small red mark on one away from his post. A red diamond on a relief walking in.
- **Hint phases:**

  | Phase | Line |
  |---|---|
  | (none) | Remove a target's engineers (red), then bring it down (gold) while it is in use: the granary, the mill, the bridge. |
  | `not_yet` | Not in use yet (grey). A fall counts only if it is still down when its time comes. Clear its engineers (red) shortly before. |
  | `engineers` | Engineers (red) mend it, put out its fires and rebuild it. Remove every one first. |
  | `open` | No engineer stands. Bring it down now, before a relief comes. The bridge takes blows, not fire. |

- **HUD:** "Raze the Crown's bread 1 / 3", and the deadline row "Carts roll 2:10".
- **Tour:**
  1. "The granary by the east road. In use at 0:45. Its engineers mend and rebuild."
  2. "The mill across the river. In use by 1:55."
  3. "The bridge. The bread carts gather here by 3:05. It takes blows, not fire."
- **Mission tags:** `razes_bread`. It keeps the wish "Burn the tithe barn" away.
- **Pool:** every power.
- **Results:** "THE CROWN'S BREAD IS RUINED" (`bread`), "THE CROWN IS FED" (`fed`).
- **Numbers** (tuned by Task 2's gate): STAGE_AT 45 / 115 / 185, CHAIN 45, NIGHT_CREW 2, SHIFT 3, POST_GAP 1.8, GUARD_REACH 2.5,
  MEND 0.025, SMOTHER_AFTER 3, REBUILD 20 (40 with one), RETURN_AFTER 20, RELIEF_AFTER 30, CARTS_AT 300. Tuned in this order
  while the scripted clear missed 180-240 s: SHIFT (1-3), STAGE_AT[0] (30-60), CHAIN (30-45), RELIEF_AFTER (20-30), MEND. Round 1:
  SHIFT 2 -> 3 (median 177.5 -> 177.8 s, the shift bunched at its door); round 2: STAGE_AT[0] 45 -> 55 (median 188.6 s). The
  controller's fix round 1 then brought each shift man out at his own post, spread, and STAGE_AT[0] back to 45 (median 203.0 s).
- **Scripted policy** (`--scenario=bread`, loadout Silent Doom, Smite, Ember, Mind Whisper: 4 DP; hit-stop off,
  `Impact.hitstop_enabled`). Every LOOK_FRAMES, the first that applies:
  1. The target in use has a crewman on guard:
     - Smite is ready and one stands within 0.7 of the target: Smite him (he falls and the target takes 45);
     - Doom is ready: Doom the one with no one else within 0.8;
     - Whisper is ready: whisper one eight units away.
  2. The target in use has none on guard: a granary or mill not burning, Ember it (Smite it if Ember is cooling); the bridge,
     Smite it.
  3. The next target's time is within 25 s: clear its night crew as in step 1.
  4. A relief walks toward the target in use and Doom is ready: Doom him.

  It never holds a target down ahead of its time. Expected clear: about 3:20; measured median 3:23.
- **How it differs from Spoiled Harvest** (M2 lesson 10):
  - **Three kinds of target:** a barn, a mill and a stone bridge, each with its own answer (fire, fire, blows).
  - **Engineers, not watchmen:** they mend damage and rebuild falls, so a target can be undone, not only saved.
  - **Work arrives with the time:** each stage brings a shift out, so the work cannot all be done ahead.
  - **No carts to stop:** the loss is one deadline. The pressure is the crews.

## 2. The Prisoner (Escort, reused)

- **Brief:** "A woman who spoke your name stands in the stocks." / "Break her free and lead her out."
- **Card type:** Protect. **Id:** `prisoner`.
- **Map:**
  - **The stocks:** a drawn market stall (`Structure.Kind.MARKET_STALL`, footprint 0.6 × 0.4, 25 hp, burns), the director's
    own, in the yard at the head of the long west street, the nearest spot to (-6.25, -7.4) that stands 4 units or more from
    the Citadel's gate (-10.5, -7.6), leaves the Citadel's lane walkable and leaves a way from the gate to her. (Task 3, the
    controller's ruling: beside the gate, a seizure was a loss within a second; here a seizer's march back is some 6.5 units,
    about ten seconds at her pace, time to answer it.) Its role is `stocks`, not a building role: it never counts in a tally.
    The town takes it away with its own buildings (`Town._built`, Broken Lanterns' way). Tagged STOCKS.
  - **The prisoner:** the lay citizen nearest the stocks, set down 1.0 in front of them. Tagged PRISONER - DO NOT KILL.
  - **The way out:** the postern in the south wall (`TownLayout.POSTERN_AT`, (-5.75, 15.65)), open in a Prepared town. Its
    mouth is (-5.75, 14.6); the way out is on the dock bank past it at (-5.75, 17.4). Tagged POSTERN.
  - **Her road:** from the stocks straight down the long west street to the postern: about 21 units (The Lost Lamb's was about
    37; 29 before the stocks moved).
  - **The camera** rests at (-9.0, -2.0). The stocks and the Citadel's gate are just above and right of the centre. The
    postern's tag points from the bottom-left edge, below the HUD stack.
- **Claims:** 11 lay citizens: the prisoner, two gaolers, two patrols of two, the postern's watch of two, and two searchers.
  All but her are made watchmen. No soldiers, no buildings.
- **Main objective:** lead her out.
  - **Won** the moment she reaches the way out, or leaves the town any way (a gate she fled to, a river boat): The Lost
    Lamb's rule.
  - **Lost** when:
    - the stocks still stand at 2:00 ("THE PRISONER IS TAKEN INSIDE");
    - a seizer marches her back to the Citadel's gate ("THE PRISONER IS TAKEN BACK");
    - she dies ("THE PRISONER IS DEAD");
    - dawn comes.
- **People and behaviour** (The Lost Lamb's rules unless said):
  - **Bound:** she stands in the stocks, held there. A whisper or a lure on her does nothing while she is bound.
  - **The gaolers:** two watchmen posted either side of her, GAOLER_OFF 1.7 off and set on the yard's walkable ground: about
    1.6 from her (within sight, beyond one Silent Doom of her) and 3.0 apart. Each would seize her the moment she is free, and
    their tag says so (GAOLER - SEIZES HER, the controller's ruling).
  - The gaolers are held past fear while she is bound (decision 119).
  - **Held from the flight:** at each of its looks the director keeps everyone it holds out of the town's flight (the gaolers,
    the patrols, the postern's watch, the searchers indoors or out, and she while she is bound), by M3's final-review rule
    (`_keep_from_flight`, the first look after the evacuation calling back one it sent running), and lets go a flight owed to a
    false calm (its own hold past fear). It does so in its own step, never in `EscortDirector`, so The Lost Lamb plays as before.
  - **Breaking the stocks:** any blow or fire that brings the stall down frees her ("SHE IS FREE"). Ember is the quiet way.
    A Smite aimed at the stocks' far side strikes them (`HIT_R` 0.7) and passes her by (`KILL_R` 0.6 from the aim, she stands
    1.2 or more away). The stocks' tag sits on their far side, so the obvious aim is the safe one.
  - **Free:** she moves by the god's hand alone, Mind Whisper or a Will-o'-Wisp's lure, and holds where she is left. She walks
    at 0.33 of a citizen's pace (tuned from The Lost Lamb's 0.385), weak from the stocks.
  - **Seized:** a watcher within 2.5 seizes her on sight and marches her back to the Citadel's gate. The watchers are the
    gaolers, the patrols, the postern's watch and the searchers. A watcher held by Discord or a whisper sees nothing. So does
    one frightened, or one indoors. Felling or holding the seizer frees her where she stands. A whisper on her alone does not.
  - **Watchmen, not soldiers:** every watcher is a lay citizen, so Mind Whisper and Discord work on all of them. That is the
    main difference from The Lost Lamb, where only killing or Discord answered a soldier.
  - **The patrols:**
    - one walks the street by the cathedral from (-14.0, -5.1) to (-7.0, -5.1) and back, across the foot of the lane to the
      mouth of the stocks' yard;
    - one walks the south street from (-14.0, 9.0) to (-2.0, 9.0) and back, across the long west street.
  - **The hue and cry:** 30 s after the stocks break, two searchers come out of the Citadel's gate and walk to wherever she is,
    seizing her on sight ("THE CITADEL SENDS ITS HOUNDS"). Before that they wait inside the Citadel. The hunt starts from the
    player's own act, not a clock.
  - **The guards change at the postern** (The Lost Lamb's model): 30 s after she first comes within 6 of the postern's mouth,
    its watch walks to the guardhouse (6 units west along the wall, (-11.75, 14.4)) for 25 s. The change repeats every 45 s.
    The god can also clear the postern by acting on the watch.
  - **The Prepared town:** if the god brings the town to evacuate, the crowd and the marshals use the postern too. She is on
    duty where she holds, so the flight does not take her. If the crowd carries her out, it counts as her escape.
- **Timeline** (left alone):

  | Time | Event |
  |---|---|
  | 0:00 | "BREAK HER FREE". The gaolers stand by the stocks; the patrols walk their beats. |
  | 2:00 | "The gaolers take her inside": lost |
  | +30 s after the stocks break | "The Citadel sends its hounds": two searchers |
  | +30 s after she first nears the postern | "The guard changes": the postern clear for 25 s, every 45 s |
  | 6:00 | Dawn |

- **The clear** (an escort is bound by her walk, not a chain): freeing her about 10-18 s (a Doom on one gaoler, a whisper on
  the other, Ember; the stall burns some 8 s) + her road, 21 units at about 4.3 s a unit with the patrols and the hounds in the
  way (≈ 90 s) + the guard change, 30 s from her first nearing the postern + the twenty seconds she shakes off the whisper that
  left her waiting + the watch coming back, the hounds and a second change, 30-50 s ≈ **180-205 s**. Measured (Task 3's gate,
  seed 1): freed 10, at the postern 101, the watch away 131, sent through 151 (shaking off the last whisper till then), seized
  by the returning watch and the hounds three times, out 203.0.
- **Longest waits:** 30 s at the postern, starting when she first nears it. The change's gap plus its away time is 55 s. There
  is no wait at the start: the gaolers are there to work on. The scripted player's longest stretch between two casts is 30-36 s.
- **Tags:**
  - PRISONER - DO NOT KILL, steel blue, with an edge arrow, while bound. Once free: PRISONER, steel blue, with an edge arrow;
    PRISONER - CAUGHT, red, while seized.
  - STOCKS - TAKEN IN AT 2:00, orange, on the stocks' far side, while they stand.
  - POSTERN - WATCHED (red) or POSTERN - CLEAR (green) at the way out, with an edge arrow. WATCHED while the watch walks back
    (The Lost Lamb's final-review rule).
  - GAOLER - SEIZES HER on each gaoler, red. TAKING HER BACK, red, with an edge arrow, on a seizer; CITADEL, red, while she
    is held.
  - SEARCHER on each searcher, red, with an edge arrow. PATROL on each patrol's first watchman, red. A red diamond on every
    other patrol watchman and on the postern's watch.
- **Hint phases:**

  | Phase | Line |
  |---|---|
  | `bound` | Remove both gaolers (red): one left seizes her for the Citadel. Then burn the stocks (orange) or strike their far side. |
  | (none) | Whisper her (blue) toward the postern, and again before she stops. Watchmen (red) seize her on sight. |
  | `caught` | She is caught. Whisper or Discord the man taking her back (red), or strike once she is clear of him. |
  | `hounds` | The Citadel's hounds (red) follow her. Strike them or turn them before they see her. |
  | `gate` | The watch (red) holds the postern. It changes soon: bring her close, or draw the watch off. |
  | `clear` | The guard is changing. Send her through the postern now. |

- **HUD:** "Free the prisoner", with the deadline row "Taken inside 1:23" while she is bound. Then "Lead her out", or
  "Lead her out: caught".
- **Tour:**
  1. "The prisoner in the stocks by the Citadel. Break her free by 2:00: do not kill her."
  2. "The postern, down to the dock. Its guard changes soon after she draws near."
  3. "The Citadel. Once she is free it sends its hounds after her."
- **Mission tags:** none.
- **Pool:** every power.
- **Results:** "THE PRISONER IS FREE" (`prisoner_out`), "THE PRISONER IS TAKEN BACK" (`prisoner_taken`), "THE PRISONER IS TAKEN
  INSIDE" (`prisoner_inside`), "THE PRISONER IS DEAD" (`prisoner`). Its own keys, never the Escort defaults (M2 decision 63).
- **Numbers** (tuned by Task 3's gate): FREE_BY 120, GAOLERS 2, GAOLER_OFF 1.7, PACE **0.33** (round 1, from 0.385: the clears
  were 173.6 / 169.9 / 134.7 s, median 169.9, with the shorter road), SIGHT 2.5, PATROL_SIZE 2, HUE_AFTER 30, HOUNDS 2,
  WATCH_CHANGE 30, WATCH_GAP 25, WATCH_CYCLE 45, LANE_DOWN 4. Tune in this order if the scripted clear misses 180-240 s: PACE
  (0.33-0.45), the beats, HUE_AFTER (20-45), WATCH_GAP. The wait for the watch stays 30 s or less. Gate (seeds 1-3): `none`
  lost `prisoner_inside` at 120.0 three times; `play` won 203.0 / 199.2 / 181.9 s, median **199.2 s**, idle 31 / 36 / 30 s.
- **Scripted policy** (`--scenario=prisoner`, loadout Mind Whisper, Silent Doom, Ember, Discord: 5 DP). Every LOOK_FRAMES, the
  first that applies:
  1. Bound, a gaoler on his post: Doom him (they stand 3.4 apart: one at a time), else whisper him eight units away.
  2. Bound, no gaoler within sight of her: Ember the stocks.
  3. Seized: Discord on the seizer, or Doom him if she stands beyond 0.8 of him.
  4. Free, a watcher within 4 of her or of the next stretch of her road: whisper him eight units away from it, else Doom him,
     else Discord where it holds two.
  5. Free, Whisper ready and she is not shaking a whisper off: whisper her up to 10 units along her road, stopping short of
     the postern while it is watched.
  6. At the postern, watched, with the change more than 10 s off: whisper one of the watch away.

  It casts no loud power. Expected clear: about 3:15; measured 3:19 (median of seeds 1-3).
- **Single charge:** The Prisoner stays single-charge. Every new hook in `EscortDirector` takes the charge it acts on as an
  argument (§6), so M6's Exodus can lift `charge` to a list without rewriting them.
- **How it differs from The Lost Lamb** (M2 lesson 10):
  - **She starts bound:** the first minute is a break-out under the gaolers' eyes, with its own deadline.
  - **Another gate:** the postern down to the dock, on the far side of the town from the Lamb's start.
  - **Watchmen, not soldiers:** every watcher can be whispered or held, so the god's quiet powers do more.
  - **The hunt follows the player:** the hounds come 30 s after she is freed, not at a fixed time.

## 3. The Heretic Hunt (Hunt, new type)

M3 lesson 1: with chained items the clear is about the first wait plus 45 s between items. So the hunt has four: three
lantern-standards and its captain, each coming on the chain. Each standard is guarded by its party, the work to do.

- **Brief:** "The Inquisition hunts your believers." / "Break the hunt before it finds their cellar."
- **Card type:** Protect. **Id:** `heretic_hunt`.
- **Map** (the hunt closes on the south-west quarter, district by district; `TownLayout.DISTRICTS` names each):
  - **The cellar:** the dwelling nearest (-11.0, 12.5) in the south-west quarter (district 6) whose door the street reaches
    and no soldier's post watches (none within 2 units). Your believers hide in it. Tagged CELLAR, steel blue. **Stone
    tonight:** it only shakes when struck (`Structure.damage_filter`, cleared at teardown, as M3's posts), so no stray power can
    end the night through it.
  - **The three sweeps**, each a district and its standard's spot (snapped to walkable ground):
    1. **the north quarter** west of the Temple (district 1): the spot (-6.0, -10.0), on the long west street;
    2. **the west quarter** (district 4): the spot (-10.5, 1.5);
    3. **the south quarter** (district 7): the spot (-1.5, 12.0), at the Main Gate plaza's west edge.
  - **The last sweep:** the cellar's own quarter (district 6), led by the captain.
  - **The Temple's door** at (0.8, -5.0): the captain comes out here. Tagged TEMPLE while he is inside.
  - **The camera** rests at (-6.0, 3.0). The first spot is up and to the right, the second just up and left of the centre,
    the third below the centre, the cellar at the left at mid height, the Temple's door at the right. None sits in the HUD
    stack's corner.
- **Claims:** 12 lay citizens: three parties of three (a standard-bearer and two Inquisitors), the captain and his two
  escorts. Reliefs as they are needed. One dwelling (the cellar). No soldiers.
- **Main objective:** break the hunt.
  - **Won** the moment all three standards are broken and the captain is dead, in any order the chain allows.
  - **Lost** when the captain reaches the cellar's door ("THE CELLAR IS FOUND"), or at dawn.
- **People and behaviour:**
  - **The parties:** each sweep's three stand on a ring of 1.2 round its spot from the start, 2.1 apart (one Silent Doom takes
    one). They are watchmen in cloak and lantern, held on duty. Fright, a whisper and Discord move them; back on their feet they
    walk back.
  - **Raised:** at its time the party's bearer plants the lantern-standard at the spot, "THE HUNT SWEEPS THE WEST QUARTER":
    - the first at 0:45;
    - the second at 1:55, or 45 s after the first is broken, whichever is sooner;
    - the third at 3:05, or 45 s after the second is broken.

    If the bearer is down, any living member plants it. With none, it is planted all the same, unguarded.
  - **The standard:** Broken Lanterns' drawn shrine post (`Structure.Kind.SHRINE`, 40 hp), the director's own, its role
    `standard` (never a building in a tally). Before its time it does not exist.
  - **Guarded:** while a member of its party stands within 1.5, alive, out of doors and not held by the god (`BLIND`), a blow
    only shakes the standard (Broken Lanterns' guarded shrine, `_shield`).
  - **Broken:** an unguarded standard brought down is broken for good ("A STANDARD FALLS"). One Smite (45) does it. Its party
    goes home.
  - **Return and relief:** a member off the ring and calm again walks back 20 s after he left. A fallen one is replaced 30 s
    after he fell by the nearest free lay citizen with a route, made a watchman. So clearing a party long before its time is
    undone. A broken standard's party gets no relief.
  - **The captain:** the resident nearest the Temple's door, made a noble, taken inside the Temple at the start. Indoors he is
    untouchable; a fire or the Temple's fall does not bring him out.
    - At 4:00, or 45 s after the third standard is broken, he comes out with two escorts ("THE CAPTAIN LEADS THE LAST SWEEP"):
      the escorts are watchmen who waited inside with him, 1.4 behind him, beyond one Doom of him.
    - He walks on duty to the cellar's quarter. Then he searches the five houses nearest the cellar, farthest first, 4 s at
      each door (Mira's Inquisitor's search), and last the cellar's door.
    - A fright, a whisper or Discord drops his search. Back on his feet he takes it up at the house he had reached.
    - Any death kills him for the objective. His escorts go home. Nobody takes up the search.
    - He is the last item: he never comes before the third standard is raised.
  - **The Prepared town:** a seen death counts toward a Local Emergency as always. It loses nothing here.
- **Timeline** (left alone):

  | Time | Event |
  |---|---|
  | 0:00 | "THE HERETIC HUNT". The three parties wait at their districts. |
  | 0:45 | "The hunt sweeps the north quarter": the first standard |
  | 1:55 | "The hunt sweeps the west quarter" (sooner: 45 s after the first is broken) |
  | 3:05 | "The hunt sweeps the south quarter" (sooner: 45 s after the second is broken) |
  | 4:00 | "The captain leads the last sweep" (sooner: 45 s after the third is broken) |
  | ~5:25 | He reaches the cellar's door: lost |
  | 6:00 | Dawn |

- **The clear:** first wait 45 + standard 3 (party cleared ahead, one Smite) + 45 + 3 + 45 + 3 + 45 + captain 8 (a Doom once he
  is out) ≈ **197 s**. With nothing done ahead, each standard takes about 15 s: ≈ 233 s. The Informer's four items measured 191
  s on the same sum.
- **Longest waits:** 45 s to the first standard, and 45 s between a standard broken and the next. In both, the next party can be
  cleared in the last 25 s. The captain's walk (about 50 s) is time to act in, not a wait.
- **Tags:**
  - The current standard, gold, with an edge arrow: "STANDARD - GUARDED" while guarded, "STANDARD" when open.
  - Each other standing standard, gold, no arrow.
  - The next sweep's spot until its standard is raised: "NEXT SWEEP 0:24" (the sooner time), grey, with an edge arrow.
  - GUARD on each party member on his ring, red. A small red mark on one away. A red diamond on a relief walking in.
  - The swept district's outline, red, thin (`MapTag.outline`, as Mira's house), while its standard stands.
  - CAPTAIN - IN THE TEMPLE, grey, over the Temple's door until he comes out. Then CAPTAIN, gold, with an edge arrow; CAPTAIN -
    SEARCHING once he searches. ESCORT, red, on each escort.
  - CELLAR, steel blue, with an edge arrow.
- **Hint phases:**

  | Phase | Line |
  |---|---|
  | (none) | Clear a standard's guards (red), then break the standard (gold). Three standards, then the captain. |
  | `guarded` | Its guards (red) hold the standard: blows only shake it. Remove every one first. |
  | `open` | The standard (gold) stands unguarded. Break it now, before a new guard comes. |
  | `waiting` | The hunt moves on soon. Clear the next sweep's guards (red) shortly before it comes. |
  | `captain` | The captain (gold) leads the last sweep to your cellar (blue). Kill him before he finds it. |
  | `searching` | The captain searches the houses by your cellar. Kill him before he reaches its door. |

- **HUD:** "Break the hunt: standards 1 / 3". Once the captain is out: "Break the hunt: standards 3 / 3, kill the captain".
- **Tour:**
  1. "Your believers' cellar. If the hunt finds it, the night is lost."
  2. "The north quarter. The hunt raises its first standard here at 0:45."
  3. "The Temple. Its captain leads the last sweep by 4:00."
- **Mission tags:** none.
- **Pool:** every power.
- **Results:** "THE HUNT IS BROKEN" (`hunt`), "THE CELLAR IS FOUND" (`cellar`).
- **Numbers** (first guesses): STEP_AT 45 / 115 / 185 / 240, CHAIN 45, PARTY 3, PARTY_R 1.2, GUARD_REACH 1.5, RETURN_AFTER 20,
  RELIEF_AFTER 30, ESCORTS 2, ESCORT_GAP 1.4, CAPTAIN_HOUSES 5, CAPTAIN_STOP 4. Tune in this order if the scripted clear misses
  180-240 s: CHAIN (30-45), STEP_AT[0] (30-60), PARTY (2-3), RELIEF_AFTER (20-30). If doing nothing does not lose before dawn:
  CAPTAIN_HOUSES, then STEP_AT[3].
- **Scripted policy** (`--scenario=hunt`, loadout Silent Doom, Smite, Mind Whisper, Discord: 5 DP; hit-stop off). Every
  LOOK_FRAMES, the first that applies:
  1. The captain is out of doors and Doom is ready: Doom him.
  2. A raised standard stands unguarded and Smite is ready: Smite its far side from any guard.
  3. A raised standard is guarded, or the next sweep's time is within 25 s:
     - two or more guards within 1.2 of one point and Discord is ready: Discord there, then Smite the standard while they are
       held;
     - Doom is ready: Doom the guard with no one else within 0.8;
     - Whisper is ready: whisper one eight units away.
  4. A relief walks toward a standing standard and Doom is ready: Doom him.

  Expected clear: about 3:20.
- **How it differs:**
  - **From Broken Lanterns** (Anchors): the standards are raised one at a time on the chain, each with its own party, and the
    night ends on a chase to a place you protect, not on a drain timer.
  - **From The Informer** (four chained items too): the items are things to break and a man in the open, not men to turn
    unseen; and the loss is a place found, not a man arriving.

### 3.1 The Hunt type (`HuntDirector`)

A new base in `src/game/mission/`, written for M6's The Lantern's Eye (Anchors + Hunt: three tower mirrors aim Halcyon's
Searchlight, and the beam hunts the god's casts) as well as for this mission.

- **The plan** (`_plan()`, virtual): the steps, each a record (`HuntStep`: its words, its spot, its district `Rect2` or none, its
  scheduled time, its party size); the chain wait; the quarry.
- **The standards:**
  - `_raise_standard(i) -> Structure` (virtual): plants a drawn lantern post at the step's spot by default. The Lantern's Eye
    returns an existing tower instead.
  - `_guarded(i) -> bool` (virtual): a party member within GUARD_REACH by default.
  - `_appoint_party(i) -> Array[Person]` (virtual): lay citizens made watchmen by default.
- **The head:** `has_head` (true by default), `_appoint_head()` (virtual; a lay citizen made a noble), `_head_route()` (virtual;
  the search route ending at the quarry), `_found() -> bool` (virtual; the head at the quarry's door).
- **The quarry:** `_quarry_point() -> Vector2` (virtual; the cellar's door by default). The Lantern's Eye returns the god's last
  cast, and its seeker is the Searchlight (`searchlight.gd`) rather than a man.
- **Reads:** `standards`, `broken(i)`, `broken_count()`, `broken_all()`, `head_down()`, `found`, `lost_reason()`, and the
  usual `tags()`, `hint_phase()`, `tour()`, `report()`.
- **`HuntObjective`** (new): DONE (its win reason) the moment `broken_all()` and `head_down()`; FAILED with `lost_reason()`
  (`cellar`). It takes its label and reasons in `_init()`, as every M2/M3 generic objective (M2 ruling 61).

## 4. Tier 3 on the board

- **The tab:** `TierBook.MISSIONS[2]` becomes `["vigil_flame", "festival", "crowns_bread", "prisoner", "heretic_hunt"]`: the ★
  missions first, as on the other tabs.
- **Types:** `"crowns_bread": "Destroy"`, `"prisoner": "Protect"`, `"heretic_hunt": "Protect"` in `TierBook.TYPES` (spec §8:
  Hunt is a Protect card).
- **Mission tags:** `"crowns_bread": ["razes_bread"]` in `TierBook.MISSION_TAGS`.
- **Unlocking:** Wrath has five missions, so Reckoning opens at three cleared (spec §3.2's full rule). A save that opened
  Reckoning on Wrath's two ★ missions keeps it open: a tier never closes. A test pins it.
- **Cards:** five on Wrath's tab, 115 px wide, with Whisper's wrapping rules (M2 ruling 58).
- **The results' tier line** reads, e.g., "Wrath 2 / 3 cleared: one more opens Reckoning".

## 5. New wishes for Tier 3

The pool grows from 12 to 14. Both new wishes have `min_tier` 3, so Tier 1 and Tier 2 nights shuffle exactly what they did
(M3 ruling 3, `WishBook.pool_for()`).

| Wish | Kind | Act | Reward | Needs / clashes |
|---|---|---|---|---|
| Burn the tithe barn | Ruin | Destroy the marked barn, by any means. | 10 | a farm barn outside the walls; `razes_bread` |
| Strike down the cruel sergeant | Punish | Kill the marked soldier, any way. | 15 | a soldier of no corps, out of doors; — |

- **Burn the tithe barn:**
  - `RuinWish` with role `barn`: `RuinWish.fits()` gains "barn", a `Kind.HOUSE` of role `farm` with no art tag (one of
    `TownLayout.BARNS`; never a windmill or watermill).
  - Tag TITHE BARN, pointed at from the edge (it stands outside the walls, often off screen).
  - It clashes with `razes_bread`, so The Crown's Bread never hears it: its granary is a barn.
- **Strike down the cruel sergeant:**
  - `PunishWish` with `"soldier": true`: the target is a living soldier of no corps (`Person.Corps.NONE`), out of doors and not
    taken, chosen as `_free_soldiers()` chooses. The wisher is lay, as every wish's.
  - Tag SERGEANT, pointed at from the edge (soldiers walk).
  - Granted the moment he dies. Failed if he leaves the town, or when the wisher dies.
  - Reserved like every wish target, so no director appoints him.
- **Why these two:** both reuse a kind's code with one parameter. The barn sends the god outside the walls; the sergeant is the
  first wish to name a soldier (twice a citizen's health, and watched by other soldiers).

## 6. What the shared code gains

M3 lesson 8: every shared change is a hook or a var whose default is today's path, proven by the exact references.

- **`RazeDirector`:** unchanged. `CrownsBreadDirector` (new, its subclass) uses `_spoilable()` for the stages and
  `Structure.restore()` for the rebuilds. `HarvestDirector` is untouched.
- **`EngineerManager`** (`src/game/crowd/`): `hands_off: Array[Structure]`, empty by default. `jobs()` skips every structure in
  it. The Crown's Bread fills it with its three targets at setup and clears it at teardown. No TownLayout read.
- **`EscortDirector`:** hooks whose defaults keep The Lost Lamb exact:
  - `_appoint_watch(charge, n)`, `_appoint_patrol(charge, beat, n)`, `_appoint_hunters(charge, n)`: free soldiers by default;
    The Prisoner appoints lay watchmen.
  - `_post_to(p, at, hurry)`: `send_to_post()` by default; `go_duty()` for a lay watchman. `_watching()` already accepts a
    watcher on duty.
  - **Bound:** `bound_by: Structure` (null by default) and `free_by: float` (-1 by default). While bound the charge is held at
    his spot; the structure's fall frees him. Still bound at `free_by`: lost.
  - `hunt_after_free: float` (-1 by default: `hunt_at` on the clock, The Lost Lamb's). The Prisoner's searchers come that long
    after the charge is freed.
  - `lost_reason() -> String` (virtual, "" by default), as `RazeDirector`'s and `AssassinateDirector`'s. `EscortObjective`
    fails with it when it is not empty.
  - `hud_line()` (virtual, "" by default) for the HUD's row while bound.
- **`MissionDirector`:** `_recall_to(p, at)`, the duty-recall idiom (M3's minor: "abstract at a fifth"). M4's three new
  directors use it. Spoiled Harvest, Market Panic and The Informer keep their own copies, so their references cannot move.
- **New:** `CrownsBreadDirector`, `PrisonerDirector`, `HuntDirector`, `HereticHuntDirector`, `HuntObjective`, the two wishes'
  parameters (`RuinWish` "barn", `PunishWish` "soldier"), `MissionBook._tier3()` and its three missions.
- **TownLayout in shared code** (the capital-city branch, M3 ruling): no new read outside `src/game/mission/`. The new wishes
  read a building's role and kind, and a soldier's corps.

## 7. Testing, photos and notes

- **Per mission:**
  - unit tests of its director, on M3's kit (`Kit.world()`, `Kit.run_for()`, `Kit.arrive()`, `Kit.free_body()`,
    `Kit.labels()`, `Kit.clear_of_stack()`);
  - a behaviour scenario, `--scenario=bread|prisoner|hunt --case=none|play [--seed=N] [--board]`, running the `MissionBook`
    version (the same director, clock and town, no wishes), so its checksums are exact references; `bread` and `hunt` turn
    hit-stop off (they cast Smite);
  - the gate of §0;
  - M3's `_waits` test extended to every new timed wait (the stages, the steps, the chains, the guard change).
- **What each mission's tests pin** (M2 and M3 lessons):
  - **a body freed mid-night** (a crewman, a gaoler, a watcher, a party member, the captain, an escort): `tags()`,
    `hint_phase()`, `report()` and the objectives never touch it;
  - **the town takes the crowd** (City Emergency's regroup, the evacuation): crews, gaolers, patrols, parties and the prisoner
    hold their places on duty;
  - **a wish's people and buildings:** no wisher or wish target becomes a crewman, a gaoler, a watcher, a party member, the
    captain or his escort; no wish's building becomes the cellar or the bridge shift's tower;
  - **Crown's Bread:** a target down when its time comes is razed; a fall before its time is rebuilt; the town's engineers keep
    off; fire before its time is put out;
  - **The Prisoner:** a whisper on her while bound does nothing; a Smite on the stocks' far side frees her unhurt; a whispered
    gaoler seizes no one; the crowd carrying her out wins;
  - **The Heretic Hunt:** a guarded standard only shakes; the captain never comes before the third standard; the cellar only
    shakes, and takes blows again after teardown.
- **Exact references that must not move:** the digest, `crowd_check`, every behaviour checksum and outcome in M3's global
  constraints (the five Warning cases, Mira's House, Broken Lanterns, the Vigil Flame's and the Feast's outcomes), M2's 24
  (refs24) and M3's 18 (`ringers`, `panic`, `informer`, `none` and `play`, seeds 1-3).
- **FLOW:** the board and results steps change for Wrath's five missions. One step is added: The Heretic Hunt from the board,
  its hunt broken, ascended, then the results reading "Wrath 1 / 3 cleared: 2 more open Reckoning". FLOW goes from 111 to 112.
- **Photos:** `--show=crowns_bread|prisoner|heretic_hunt` (the tour skipped, the opening banners waited out) and
  `--show=tiers --mission=vigil_flame` (Wrath's tab, its save clearing three Wrath missions so Reckoning opens). Each photo is
  checked for the HUD stack's dead zone and the edge arrows. The Heretic Hunt's district outline is checked for clutter; if it
  hides tags, it goes (Decision 79).
- **Bench:** The Crown's Bread's board version (`--mission=crowns_bread --board --bench`: fires, rebuilds, the most structure
  work) against The Vigil Flame's, on a quiet machine.
- **Release notes:** an M4 section at the top of `docs/KAK_Version_0.11_Summary.md`, its rulings numbered on from M3's last.
- **Spec sync:** each mission task syncs its section here to its tuned numbers (M3 ruling), as Market Panic's and The
  Informer's did.

## 8. Decisions

These are the details the v0.11 spec left open, numbered on from M3's plan (56). The controller records them as rulings. Each
gives its cost if it proves wrong.

57. **Ids and building:** the ids are `crowns_bread`, `prisoner` and `heretic_hunt`, built in `MissionBook.tier_missions()` by
    a new `_tier3()` frame (360 s, tier 3, `tier_floor` 3, no `profile`, 4 / 10, no bonuses), so their stretch is 1 and
    `TierBook.board()` needs no branch. Not in `all()` nor the campaign. Cost if wrong: a scripted run meets another town; one
    frame to change.
58. **Unlocking:** Wrath has five missions, so Reckoning opens at three cleared; a save that opened Reckoning on Wrath's two ★
    missions keeps it, pinned by a test. Cost: none.
59. **No bell loss in M4:** none of the three carries `BellSilentObjective`; the Prepared town's bell only raises the town.
    Cost if wrong: a careless night is too forgiving; add the objective to one mission.
60. **Crown's Bread, the code:** `CrownsBreadDirector extends RazeDirector`; the base is unchanged; the stages are
    `_spoilable()`, the rebuilds `Structure.restore()`. Cost if wrong: if `restore()` misbehaves on a house, the granary and mill
    are only mended, and only the bridge is rebuilt.
61. **The three targets:** the east-road barn (`BARNS[3]`) as the granary, the watermill, the stone bridge; in use in that
    order. They stand 9-18 units apart. Cost if wrong: a target in a camera's dead zone; move the camera, not the target.
62. **Stages, not seals:** in use at 0:45 / 1:55 / 3:05, or 45 s after the one before is razed. Every blow lands from 0:00. A fall
    counts while in use; one down when its time comes is razed; fire on one not in use is put out (the base's rule). Cost if
    wrong: without the stages a skilled clear falls to about 1:30 (three open targets, as M2 found).
63. **Crews:** a night crew of two at each target from the start, and a shift of two that comes out at its time (the granary's
    and mill's from inside, the bridge's from the Main Gate's west tower, else the east one). Lay citizens made engineers, posts
    1.8 apart. Cost if wrong: SHIFT is the first tuning knob (1-3).
64. **The engineers' work:** each on guard mends 2.5% a second, beats out a fire after 3 s, and rebuilds a fall not in use in
    20 s (two) or 40 s (one); return 20 s, relief 30 s. Cost if wrong: one tuning round on MEND and RELIEF_AFTER.
65. **The town's engineers keep off:** `EngineerManager.hands_off` (empty by default) holds the three targets, so the only crews
    are the tagged ones. Cost if wrong: an untagged team rebuilds the bridge, a hidden opposition.
66. **The Crown's deadline:** "The Crown's carts roll" at 5:00 (`EventObjective("carts", "Carts roll", "fed")`); dawn is the
    tier's. Doing nothing loses then. Cost: none.
67. **The Prisoner, the code:** `PrisonerDirector extends EscortDirector`; the base gains the hooks of §6, each defaulting to
    The Lost Lamb's path, so its six references hold. Single charge; every new hook takes the charge as an argument for M6's
    Exodus. Cost if wrong: Exodus rewrites the hooks.
68. **The stocks:** a drawn market stall (0.6 × 0.4, 25 hp, burns) beside the Citadel's gate, leaving the lane walkable; any blow
    or fire frees her; still standing at 2:00 loses ("taken inside"). Its tag sits on the far side, where a Smite is safe. Cost
    if wrong: a stall does not read as stocks; the tag carries it, as M3's stand-ins.
69. **Watchmen, not soldiers:** gaolers, patrols, the postern's watch and the searchers are lay citizens made watchmen, so the
    rally never takes them and the god's whispers work on them. Cost if wrong: too easy; add a third gaoler.
70. **The postern:** the way out is the dock bank past the postern (open in a Prepared town); the guard change is The Lost
    Lamb's (30 s after she first nears, away 25 s, every 45 s); a crowd or a boat carrying her out wins. Cost if wrong: an
    evacuation jams the postern; the scripted policy stays quiet and a player has the crowd's escape rule.
71. **The hue and cry:** two searchers come out of the Citadel 30 s after the stocks break. Cost if wrong: HUE_AFTER is a knob
    (20-45).
72. **Her pace and sight:** 0.385 of a citizen's (The Lost Lamb's), seized within 2.5. Cost if wrong: PACE is the first knob.
73. **The Hunt type:** `HuntDirector` (steps, standards, parties, an optional head, a quarry) with the virtuals of §3.1, so The
    Lantern's Eye can swap the planted posts for tower mirrors and the captain for the Searchlight. `HereticHuntDirector` is
    its first subclass. Cost if wrong: M6 forks it.
74. **Four chained items:** three standards raised at 0:45 / 1:55 / 3:05 and the captain at 4:00, each sooner by 45 s after
    the one before is done. A standard does not exist before its time. Cost if wrong: with three items the clear is about
    2:30, as M3's three-item missions measured.
75. **The standards:** Broken Lanterns' drawn post, 40 hp (one Smite), only shaking while a party member stands within 1.5
    and is not held by the god. Cost if wrong: a standard too easy; GUARD_REACH or a second blow (raise its health).
76. **The parties:** three watchmen per standard on a ring of 1.2 from the start (2.1 apart), held on duty; return 20 s,
    relief 30 s; none for a broken standard's party. Cost if wrong: PARTY is a knob (2-3).
77. **The captain:** a resident made a noble, inside the Temple until his step; two escorts 1.4 behind; he searches the five
    houses nearest the cellar (4 s each) and then its door; any death ends him; no relay. Left alone he finds the cellar
    at about 5:25. Cost if wrong: if doing nothing reaches dawn, CAPTAIN_HOUSES then STEP_AT[3] come down.
78. **The cellar:** the dwelling nearest (-11.0, 12.5) with a quiet door; stone tonight, cleared at teardown. Cost if wrong:
    none; it is a place, not a target.
79. **Tags for the hunt:** the swept district's thin red outline while its standard stands. Cost if wrong: clutter on a busy
    map; the photo round drops it and the HUD line carries the district's name.
80. **Camera spots:** The Crown's Bread (6.0, 20.0), The Prisoner (-9.0, -2.0), The Heretic Hunt (-6.0, 3.0), each checked
    with `clear_of_stack()`. Cost if wrong: a photo-round move, which moves that scenario's own references once.
81. **The new wishes:** "Burn the tithe barn" (Ruin, 10, `min_tier` 3, clashes with `razes_bread`) and "Strike down the cruel
    sergeant" (Punish, 15, `min_tier` 3). The pool grows from 12 to 14; Tier 1 and Tier 2 draws do not change. Cost: none.
82. **Mission tags:** only `crowns_bread` declares one (`razes_bread`); a test pins that its night never hears the barn wish
    (M3's Task 6 ruling: a declared clash is tested). Cost: none.
83. **Behaviour scenarios** `bread`, `prisoner` and `hunt` run the `MissionBook` versions; `bread` and `hunt` turn hit-stop off
    (`Impact.hitstop_enabled`), so their play checksums are exact. Cost: none.
84. **The scripted gate** is M2's and M3's; each mission names its knobs and its policy works the opposition as a player would.
    Cost: none.
85. **Results titles:** THE CROWN'S BREAD IS RUINED, THE CROWN IS FED, THE PRISONER IS FREE, THE PRISONER IS TAKEN BACK, THE
    PRISONER IS TAKEN INSIDE, THE PRISONER IS DEAD, THE HUNT IS BROKEN and THE CELLAR IS FOUND, under the mission's own keys
    (`bread`, `fed`, `prisoner_out`, `prisoner_taken`, `prisoner_inside`, `prisoner`, `hunt`, `cellar`). Cost: none.
86. **FLOW:** Wrath's five on the board and results steps, and one added step (The Heretic Hunt ascended). 111 to 112. Cost:
    none.
87. **Board order:** the ★ missions first, then #13, #14 and #15. Cost: none.
88. **The bench:** The Crown's Bread's board version against The Vigil Flame's, on a quiet machine. Cost: none.
89. **The duty-recall helper:** `MissionDirector._recall_to()` for M4's new directors only; the four M2/M3 copies stay. Cost if
    wrong: five copies become one in a later clean-up, with its references checked.
90. **No new TownLayout reads in shared code:** the wishes and `EngineerManager` read roles, kinds and corps; the new directors
    in `src/game/mission/` may read TownLayout. Cost: none.
