# KAK v0.11 M6 Ascendance: the three new Tier 5 missions, and v0.11's close (mission spec)

Date: 2026-10-15. Status: for the user's approval.

Builds on:
- the v0.11 spec (`docs/superpowers/specs/2026-10-08-kak-v011-tiers-design.md` §2, §4, §5, §7.1, §8 rows 21-25);
- M1-M4 as shipped (rulings 1-183 in `docs/KAK_Version_0.11_Summary.md`);
- M5 as specified and planned (`docs/superpowers/specs/2026-10-10-kak-v011-m5-reckoning-missions.md`, Decisions 121-168;
  plan decisions 169-206; the controller's M5 rulings);
- the three items M4's final review carried to M6 (§6.1, §6.2, §6.4).

M6 makes Tier 5 complete and closes v0.11. It adds:
- Last Judgement and The Long Night, unchanged;
- three new missions (Anchors + Hunt, Escort with many charges, Raze + Assassinate);
- two new wishes;
- the board's end state once all 25 missions are cleared;
- photos, notes and the release bench.

**M5 lands first.** Where this spec leans on an M5 helper, it means that helper as M5 lands it:
- the Lantern Knights as directors' own soldiers (`Crowd.add_soldier()`, corps `KNIGHT`);
- `RazeDirector.hud_line()`;
- `EngineerManager.hands_off` as The Bishop and The Armoury use it;
- Pip's hidden ride in the relic cart;
- `_tier4()`;
- the `bishop` / `armoury` / `sermon` / `relic` references.

## 0. What every Tier 5 mission shares

- **Tier 5's numbers:** clock 7:00 (dawn), town God-Resistant plus Halcyon's Gaze, 6 slots and 16 DP (plus upgrades; six slots is
  the most a loadout has), 3 wishes heard, believers ×3 (the main objective pays 30; a 15 wish pays 45).
- **Built at their tier:** each new mission is made in `MissionBook.tier_missions()` by a new `_tier5()` frame, as `_tier2()` to
  `_tier4()`:
  - `tier` 5, `clock` 420 s, `slots` 6, `dp_capacity` 16;
  - `tier_floor` 4 (God-Resistant) and no `profile`, so a scripted run meets the board's town;
  - no bonuses, `intro_banner` the name in capitals;
  - every power allowed unless the mission narrows its pool;
  - its board version has stretch 1.
- **The God-Resistant town** (`ResponseProfile.for_tier(GOD_RESISTANT)`), as M5 §0 reads it:
  - the bell climbs in 5 s, and two soldiers guard whoever is on the rope;
  - four seen deaths or collapses in one district make a Local Emergency;
  - a fire brigade of five turns out from Local Emergency;
  - three engineer teams turn out from City Emergency and mend houses, the Temple, the bell tower, the gates, the bridge and the dock;
  - the Banishing Rite at City Emergency (35 s, six clergy, on the cathedral's steps) takes 40 s off the clock;
  - the evacuation comes 8 s after City Emergency, with five marshals at each way out and five rescue squads;
  - river boats: the postern is open.
- **Halcyon's Gaze at Tier 5** (spec §4: a seen death adds to it, and a full Gaze loses):
  - **Its own Gaze.** Each new director keeps its own Gaze, a plain `GazeMeter`: a seen death adds 10 of 100, so ten seen deaths
    lose. `Descent.attach()` gives the night's Tier 5 Gaze only to a director without one, so it leaves these alone.
  - **The ★ missions keep theirs.** Last Judgement and The Long Night keep M1's Tier 5 Gaze (0.5 a seen death, for nights that
    kill hundreds).
  - **Why 10:** the new missions are precise nights where a seen death is a mistake, not a side effect.
  - **Seen** is the town's rule (`Crowd.nearest_witness()`): someone living and out of doors within 2.0 when the body falls. Someone
    held by Discord or a whisper still counts as a witness. A cast's own victims never witness each other.
  - **The bell does not fill it** (M1 ruling 10).
  - **Per-mission additions:** The Lantern's Eye's light sees casts made in it (§1). The Heart of Faith counts double once its
    flame is out (§3).
  - **The objective:** each mission lists `GazeObjective` in its own objectives, so a scripted run judges the Gaze exactly.
    `TierBook.board()` adds one only to a mission that has none (§6.5).
- **Unseen by design** (the user's ruling for M6):
  - **Spacing:** every post a director gives its guards stands more than 2.0 from every other post (POST_GAP 2.4, or a ring of
    2.5). So one Silent Doom takes one guard and goes unseen when no passer-by is near.
  - **A clean line:** each mission names a line a careful player can win on with no seen death.
  - **The scripted policy:** it Dooms only a man with no one else within 2.0. Each mission says what it expects of the Gaze.
- **No bell loss:** none of M6's missions loses on the bell. A seen kill raises the town and ends nothing by itself.
- **Mission tags:** a God-Resistant town carries no `unaware_town`, so every older wish and both new wishes (§5) can be heard,
  except where a mission's tags say otherwise.
- **No waiting:**
  - everything finishes by acting;
  - every timed wait is 60 s at most, and every chain wait 45 s at most;
  - each mission lists its longest wait;
  - no wait before the last item is a pure 45 s with nothing to work on (M4's ruling on the hunt's captain).
- **The chain rule** (M2-M5): each item comes at its scheduled time or a chain wait after the one before is done, whichever is
  sooner. One still open never holds the next back. The strip shows the chained time (`EventTimeline.expect()`).
- **The clear arithmetic** (M3 lesson): with N chained items, a skilled clear is about
  `first wait + (N - 1) × chain + the work after each item comes`. Work done ahead (the next item's guards, cleared in the last
  25 s before it comes) does not count. Each mission shows its sum, and the shortest a skilled player can make it.
- **Length and the gate** (M2 ruling 55), per mission, seeds 1-3:
  - doing nothing loses 3 of 3;
  - the scripted player wins at least 2 of 3;
  - the median of its wins is 180-240 s;
  - its longest stretch between two casts (`idle=`) is 45 s or less.
  - The scripted policy works the opposition as a player would before any knob is tuned (M3's Task 2 ruling).
- **Own people** (M2-M5):
  - Every person a director uses is its own. Lay citizens are appointed and dressed through `MissionDirector._eligible()`,
    `_lay_near()`, `_lay_reaching()`, `_house_near()`.
  - The Heart of Faith's Lantern Knights are soldiers the director adds (corps `KNIGHT`), as The Bishop's are. No town soldier is
    ever borrowed.
  - So the rally, the marshals, the escorts and the rite never take one, and no wisher, wish target or wish building is ever
    used. Each mission lists its claims.
- **Held on duty** (M3 lesson 4, M4 final review):
  - Every person whose loss would change the night is put on duty at his place from setup (`Person.go_duty()`).
  - At each look every M6 director runs one rule over everyone it holds, `MissionDirector._hold_all(people, evacuating)`:
    - each is kept from the town's flight;
    - a flight owed to a false calm is let go;
    - one away from his post when the evacuation begins is recalled at once.
  - People waiting for their time wait indoors (`_take_inside()`), untouchable. A fire on, or the fall of, the building they wait in
    does not bring them out early.
- **No hidden losses** (M4, M5):
  - A stray kill never makes a night silently unwinnable. Either it is counted with a plain loss reason, or the person's tag warns
    "DO NOT KILL" from the start.
  - A person leaving the town resolves at once.
  - Any loss that can come quickly has a plain tag, hint and countdown, and room to act. Each mission lists its own.
  - Each mission has an evacuate-mid-mission test (`Kit.evacuate()`): one held person recovering and one whispered when the
    evacuation begins, both still at their places afterwards.
- **Relays:** no M6 mission passes an errand from a dead man to a witness. There is no `TempleReport` in M6.
- **Hit-stop** (M3 ruling): the scenarios that cast Smite or Heaven Splitter turn it off (`Impact.hitstop_enabled`): `eye` and
  `heart`.
- **Camera and the HUD stack:**
  - M6 does the structural fix carried from M4 (§6.4): map tags and edge arrows keep out of the left HUD stack (the objectives,
    the hint and up to three wish rows, about 240×165 px of 640×360) in every mission, campaign nights included.
  - So no mission needs a camera nudge for the stack again. Each `camera_at` only keeps the opening's key targets on screen where
    it can.
  - Each mission's tests check its spots at the real stack depth (`Kit.clear_of_stack(g, cam, Kit.STACK)`, §7).
  - Every moving target's tag has an edge arrow.
- **Art:** text and drawn shapes only.
  - The mirrors' guards and Exodus's Inquisitors are made `CitizenProfile.Role.WATCHMAN` (the watch cloak and lantern).
  - The mirror-wrights are made `Role.ENGINEER` (the apron and cap).
  - The Lantern Knights wear Broken Lanterns' gold tabard (corps `KNIGHT`).
  - High Priest Odran is a cleric, as he is.
  - The mirrors are their wall towers, named by tags. The Searchlight is The Vigil Flame's (`SearchlightFx`).
  - Odran's litter is its bearers, tagged; no litter is drawn (M5's relic cart, which is its carter).
  - Every other stand-in is an existing building or person named by a map tag.
- **Colours** (as M2-M5): target gold `d8b23a`, places orange `ff9a3a`, watchers and danger red `c8342a`, the god's charges steel
  blue `8fb8e8`, not yet grey `9a948a`, clear green `7fc46a`, wishes soft blue `8fb8ff`. Lantern Knights are red, as The
  Bishop's (M5 Decision 168).
- **The ★ missions:** Last Judgement and The Long Night keep their directors, rules and board versions. M6 does not touch them.

## 1. The Lantern's Eye (Anchors + Hunt)

Halcyon's Searchlight sweeps the town from the Temple's spire all night. Tonight the Inquisition hangs three great mirrors on the
wall towers to aim it. While a mirror stands, the light hunts the god's casts. The mirrors go up on the chain (the Hunt). Each must
be shattered and kept shattered 20 s while its wrights try to hang a new glass (the Anchors). M3 lesson 1 says three items need
real work each. Here each mirror brings a party to clear, two blows to land where the light is not, and two wrights to stop.

- **Brief:** "Halcyon hangs mirrors to aim his light." / "Shatter all three before the Eye opens."
- **Card type:** Anchors. **Id:** `lantern_eye`.
- **Map:**
  - **The spire:** the Temple's centre (0.8, -8.7), the Searchlight's origin, as The Vigil Flame's.
  - **The three mirror towers**, in the order the mirrors go up. Each is the standing wall tower nearest its point
    (`RuinWish.fits(s, "tower")`, never the bell tower), never a reserved one (a watchtower wish's), never another mirror's:
    1. **the north tower** behind the Temple, nearest (0.0, -15.65), about 7 units from the spire;
    2. **the east tower**, nearest (15.65, 0.0), about 17 units from the spire;
    3. **the south-west tower**, nearest (-8.0, 15.65), about 25 units from the spire (inside the beams' reach, FAR + POOL_R 28).

    They stand 22-33 units apart, so no one power reaches two. Each is tagged MIRROR once its mirror is up.
  - **Each tower's foot:** the point 1.0 out from the middle of its town-side face, snapped to walkable ground. The guards' posts,
    the wrights' posts and the re-hanging all key on it.
  - **The camera** rests at (0.0, -6.0). The spire is just above the centre and the north tower at the upper right. The east
    tower's tag points from the bottom-right edge and the south-west tower's from the left edge below the HUD stack. The keepout
    (§6.4) keeps every arrow off the stack whatever the night's rows.
- **Claims:**
  - 15 lay citizens: three parties of three guards (made watchmen) and three pairs of wrights (made engineers, waiting inside their
    tower). Reliefs as they are needed.
  - Three wall towers, borrowed: their damage filters are saved and given back at teardown.
  - No soldiers, no dwellings.
- **Main objective:** shatter the three mirrors.
  - **Won** the moment the third mirror is gone for good (below).
  - **Lost** when:
    - all three mirrors stand up and unshattered at once for EYE_OPENS (30 s) ("THE EYE OPENS");
    - Halcyon's Gaze fills ("THE LANTERN LOOKS");
    - dawn comes.
- **People and behaviour:**
  - **The light:**
    - Both of the Searchlight's beams are lit at 0:00 and sweep as The Vigil Flame's do: round the spire, in and out, past the walls.
    - **Hunting:** while one or more mirrors stand up and unshattered, the light hunts. Every cast it hears draws the nearest lit
      beam to its aim (at BEAM_SPEED, 8 units a second), and the beam holds there HOLD (8 s) before it returns to its sweep. A newer
      cast draws a beam again.
    - **Heard:** every cast but Mind Whisper (The Vigil Flame's `UNHEARD`).
    - **The decoy:** a Will-o'-Wisp draws the nearest beam to it for 5 s (`Searchlight.lure()`).
    - **Quiet:** with no mirror standing, the light sweeps and hears nothing.
    - **Out:** with all three gone, the light goes out (the night is won then).
  - **Seen casts:** a cast whose aim lies inside a lit pool (`Searchlight.touches()`), heard or not, adds SEEN_CAST (20) to the
    Gaze ("THE EYE SEES YOUR HAND"). It is judged as the cast is made (`Rules.cast_made`), so only a beam already there sees it.
    Deaths are judged by the witness rule alone (§0).
  - **The mirrors go up** (the steps, `HuntDirector`'s chain):
    - the north tower's at 0:50 ("A MIRROR GOES UP ON THE NORTH TOWER");
    - the east tower's at 1:55, or 35 s after the first is gone for good, whichever is sooner;
    - the south-west tower's at 3:00, or 35 s after the second is gone for good.

    Before its time a mirror does not exist. Blows on its tower only shake it (it is stone tonight: the filter owns its health).
  - **The glass:** a mirror's glass has MIRROR_HP (90), held by the director:
    - **Guarded:** while a guard of its party stands guard, a blow only shakes the tower (`HuntDirector._shield`).
    - **Unguarded:** the blow strikes the glass (`_unguarded_blow()`, §6.2). The tower scorches, shakes and emits its `hit` as any
      struck building does, but its own health never moves tonight.
    - Two Smites shatter it, or one Heaven Splitter through the tower and a Smite.
  - **Shattered:** at 0 the mirror shatters ("THE MIRROR SHATTERS"), and its two wrights come out of the tower's door to hang a new
    glass. The mirror is **gone for good** once it has stayed shattered DRAIN (20 s) without being hung again ("THE MIRROR IS GONE"):
    Broken Lanterns' drain rule.
  - **The wrights:**
    - They wait inside their tower, untouchable, until its mirror shatters.
    - Then they come out on posts at its foot, 2.4 apart (one Doom takes one), each working where he stands.
    - A wright alive, out of doors, not held by the god (`BLIND`) and within 1.2 of his post is at work. REHANG (10 s) of one
      wright's work in all hangs a new glass at full health ("THE MIRROR IS HUNG AGAIN"). Two at work hang it in 5 s.
    - Hung again, the mirror is up and guarded by whoever of its party stands. Its wrights go back inside for the next time, and the
      drain starts again at its next shattering.
    - A wright frightened, whispered or confused walks back 20 s after he is calm. A fallen wright is not replaced: the pair is the
      work that cannot be done ahead.
  - **The parties:**
    - Each tower's guard is three watchmen on posts along its town-side face from the start: the foot, and 2.4 to either side of it,
      1.0 out from the face.
    - They are held on duty. Fright, a whisper and Discord move them. Back on their feet they walk back.
    - **On guard:** alive, out of doors, not held by the god, within GUARD_REACH (2.0) of the tower's footprint.
    - **Return and relief:** a guard away from his post and calm again walks back 20 s after he left. A fallen one is replaced 30 s
      after he fell by the nearest free lay citizen with a way to the post (`_lay_reaching()`), made a watchman.
    - With no one who can reach the post, the search backs off and tries again 30 s later.
    - A gone mirror's party goes home and gets no relief.
  - **The Eye opens:**
    - With all three mirrors up and unshattered, a countdown runs: "THE EYE OPENS IN 30". The strip shows it, the spire gets a red
      tag with an edge arrow, and the hint changes.
    - A mirror shattered stops it; hung again, the count starts afresh.
    - At 0 the night is lost (`_found()`, §6.2). Left alone, the third mirror goes up at 3:00, so doing nothing loses at 3:30.
  - **The God-Resistant town:** a seen death counts toward a Local Emergency as always, and adds to the Gaze. The policy's kills
    are unseen, so the town stays asleep.
- **Timeline** (left alone):

  | Time | Event |
  |---|---|
  | 0:00 | "THE LANTERN'S EYE". The light sweeps; the three parties stand at their towers. |
  | 0:50 | "A mirror goes up on the north tower": the light hunts your casts |
  | 1:55 | "A mirror goes up on the east tower" (sooner: 35 s after the first is gone for good) |
  | 3:00 | "A mirror goes up on the south-west tower" (sooner: 35 s after the second is gone) |
  | 3:30 | "The Eye opens": lost, 30 s after all three stand |
  | 7:00 | Dawn |

- **The clear:**
  - **The sum:** first wait 50 + mirror 1 (glass 12: two Smites 10 s apart; the wrights a Doom and a whisper inside the drain;
    drain 20) 32 + 35 + mirror 2 32 + 35 + mirror 3 32 ≈ **216 s**.
  - **The schedule:** the times 1:55 and 3:00 fall 2 s before the chain's, so the expected run is ≈ 212 s.
  - **The shortest:** no glass can be struck before its mirror goes up, and no drain can be cut. So a skilled player's clear is at
    least 50 + 3 × (3 + 20) + 2 × 35 ≈ 189 s.
- **Longest waits:**
  - 50 s to the first mirror, with its party to clear from 0:25 (idle about 25 s);
  - 35 s between a mirror gone for good and the next one going up, its party to clear in the last 25 s;
  - each 20 s drain, the wrights to stop inside it.

  No timed wait passes 35 s except the first.
- **Tags:**
  - The current mirror, gold, with an edge arrow:
    - "MIRROR - GUARDED" while guarded, "MIRROR" when open;
    - "MIRROR - SHATTERED 14" (seconds of the drain left), orange, while shattered.
  - Each other standing mirror, gold, no arrow.
  - The next mirror's tower until its mirror is up: "NEXT MIRROR 0:24" (the sooner time), grey, with an edge arrow.
  - GUARD on each guard on guard, red. A small red mark on one away. A red diamond on a relief walking in.
  - WRIGHT on each wright out of doors, red.
  - "THE EYE OPENS IN 21" on the spire, red, with an edge arrow, only while the countdown runs.
  - The beams themselves are drawn (`SearchlightFx`), and they are the light's only mark.
- **Hint phases:**

  | Phase | Line |
  |---|---|
  | (none) | Clear a mirror's guards (red), then shatter it (gold) and keep it shattered 20 s. While a mirror stands, the light hunts your casts: never cast where it shines. |
  | `guarded` | Its guards (red) hold the mirror: blows only shake the tower. Remove every one. |
  | `open` | The mirror (gold) stands unguarded. Two blows shatter it: strike where no beam shines. |
  | `shattered` | Its wrights (red) hang a new glass. Stop them for {n} s and it is gone for good. |
  | `waiting` | The next mirror goes up soon, and the light is quiet till then. Clear its guards (red) shortly before. |
  | `eye` | All three mirrors stand: the Eye opens in {n} s. Shatter one now. |

  The `eye` phase comes first, then `shattered`, then the current mirror's. The `{n}` mark is filled from `hint_seconds()`
  (M4's countdown mark).
- **HUD:**
  - "Shatter the mirrors 1 / 3" (`HuntObjective`, count word "mirrors", no head);
  - "Halcyon's Gaze 20%" (`GazeObjective`).

  The Eye's countdown shows on the strip, on the spire's tag and in the hint's `{n}`. `HuntObjective` stays as M4 made it.
- **Tour:**
  1. "The north tower. A mirror goes up here at 0:50: shatter it and keep it shattered 20 s."
  2. "Halcyon's Searchlight. While a mirror stands, its beams hunt your casts. A cast in the light is seen."
  3. "The east and south-west towers: the next mirrors. If all three stand at once, the Eye opens."
- **Mission tags:** none. A watchtower wish's tower is reserved before the director chooses, so the mirror takes the next nearest
  tower (a test pins it).
- **Pool:** every power.
- **Results:**
  - "THE LANTERN'S EYE IS BLIND" (`eye_blind`);
  - "THE EYE OPENS" (`eye_open`);
  - the Gaze's "THE LANTERN LOOKS" (`gaze`, the family's own).
- **Numbers** (first guesses):
  - **The steps:** STEP_AT 50 / 115 / 180, CHAIN 35, PARTY 3, POST_GAP 2.4, POST_OUT 1.0, GUARD_REACH 2.0, RETURN_AFTER 20,
    RELIEF_AFTER 30.
  - **The glass:** MIRROR_HP 90, DRAIN 20, WRIGHTS 2, WRIGHT_GAP 2.4, WRIGHT_REACH 1.2, REHANG 10, EYE_OPENS 30.
  - **The light:** two beams from 0:00, HOLD 8, SEEN_CAST 20; the rest is The Vigil Flame's Searchlight.
  - **Tuning order,** if the scripted clear misses 180-240 s: CHAIN (30-45), STEP_AT[0] (40-60), DRAIN (15-20), MIRROR_HP
    (90-135), PARTY (2-3).
  - If doing nothing does not lose 3 of 3: EYE_OPENS (20-30).
- **Scripted policy** (`--scenario=eye`; loadout Silent Doom, Smite, Mind Whisper, Will-o'-Wisp, Heaven Splitter, 7 DP; hit-stop off):
  - **The rule over every step:** never cast where a lit pool lies within POOL_R + 0.5 of the aim. A step that would is skipped
    this look.
  - Every LOOK_FRAMES, the first that applies:
    1. A mirror is shattered and a wright is at work: Doom him if no one else is within 2; else whisper him eight units away.
    2. The current mirror is open and Smite is ready: Smite the tower's outer face, with no person within 0.7 of the aim.
       Heaven Splitter along the face if Smite is cooling.
    3. A beam holds on the current mirror's tower and Wisp is ready: Wisp six units from the tower, away from its people.
    4. The current mirror is guarded, or the next goes up within 25 s: Doom a guard with no one else within 2 (the posts stand 2.4
       apart); else whisper one eight units away.
    5. A relief walks toward a standing mirror and Doom is ready: Doom him.
  - **Its Gaze:** no seen cast by its rule, and its Dooms are taken alone. A sweeping beam that swings onto an aim already cast is
    the only risk. Expected Gaze: 0-20%. Expected clear: about 3:35.
- **Evacuate-mid-mission test:**
  - The evacuation begins while the second mirror stands, one guard whispered and one recovering: both back on their posts, and the
    wrights inside stay inside.
  - Again during a drain, the wrights at work: they hold their posts and work on.
- **No hidden losses:**
  - The Eye's countdown is 30 s, with its tag, its hint and its HUD row.
  - Every Gaze addition has a banner.
  - None of the Eye's people is a loss if killed.
- **How it differs:**
  - **From Broken Lanterns** (Anchors): three anchors come one at a time on a chain, on towers, each with a party and its own pair
    of wrights. The pressure is a light that answers your own casts, not a Vigil walking its round.
  - **From The Heretic Hunt** (Hunt): the hunt's quarry is the god's hand, not a cellar. The last step is a drain under the light,
    not a captain's walk.
  - **From The Vigil Flame and The Relic Run** (the Searchlight): the light hunts casts, not a boy. Being seen costs a share of the
    Gaze, not half of it.

## 2. Exodus (Escort, many charges)

The Escort type with twelve charges. The god leads three households of believers out of Aldermere while the Inquisition shuts the
gates one by one. M3 lesson 1 says the households must come on the chain, so each comes out of hiding only when the one before is
through, or at its time. The work is their walk: watchmen to clear on the road and at the gate, searchers sent after each household,
and seizures to answer. The households follow their lamp-bearer, so one whisper moves a family, not a person.

- **Brief:** "The Inquisition comes for your believers tonight." / "Lead ten out before the gates are shut."
- **Card type:** Protect. **Id:** `exodus`.
- **Map** (each house is the dwelling nearest its point with a door the street reaches that is quiet: no patrol's beat and no
  gate's watch within 3.5 of it; never reserved):
  - **The households, in the order they come out:**
    1. **the west household:** the house nearest (-10.5, 7.0), bound for the postern; about 12 units of street;
    2. **the east household:** the house nearest (7.5, 4.5), its door on the east side, bound for the Side Gate; about 11 units of
       street;
    3. **the south household:** the house nearest (7.7, 13.8), in the south-east quarter by the wall, bound for the Main Gate; about
       14 units of street. (Tuned, Task 6: no dwelling near the first guess (-2.5, 10.5) has a door 3.5 from the west street's beat
       and the gates' posts; the houses are the tuning knob, Decision 229.)
  - **The ways out:**
    - the postern: mouth (-5.75, 14.6), way out on the dock bank (-5.75, 17.4);
    - the Side Gate: mouth (14.4, 9.0), way out (17.6, 9.0);
    - the Main Gate: mouth (2.7, 14.4), way out (2.7, 17.6).

    Each household is bound for its gate, but any open gate's way out counts.
  - **The Temple's door** (0.8, -5.0): where a seized believer is marched, where the searchers and reliefs come from.
  - **The camera** rests at (-7.0, 9.0). The west household's door and the postern are left of the centre, below the HUD stack.
    The Main Gate is at the bottom. The east household's and the Side Gate's tags point from the right edge, and the Temple's from
    the right edge near the top.
- **Claims:**
  - 28 lay citizens:
    - the 12 believers;
    - two patrols of two, two watchmen at each gate and two searchers for each household (made watchmen, Inquisitors);
    - reliefs as they are needed.
  - The three houses, stone tonight: a blow only shakes them and any fire on them is put out, their filters given back at teardown.
    So no stray power empties a household.
  - No soldiers.
- **Main objective:** lead ten believers out.
  - **Won** the moment the tenth is out: he reaches an open gate's way out, or leaves the town any way (a gate he fled to, a river
    boat; The Lost Lamb's rule).
  - **Lost** when:
    - too few are left: the believers out plus those still in town, alive and not taken, fall below ten ("TOO FEW ARE LEFT");
    - the Main Gate, the last open, shuts with fewer than ten out ("THE GATES ARE SHUT");
    - Halcyon's Gaze fills ("THE LANTERN LOOKS");
    - dawn comes.
- **People and behaviour** (The Lost Lamb's and The Prisoner's rules, per charge, unless said):
  - **The believers:** twelve lay citizens, four to a household. They are the lay citizens nearest each house, made a household and
    taken inside it at the start.
    - **Coming out:** each household comes out of its door at its time ("THE WEST HOUSEHOLD COMES OUT"):
      - the first at 0:15;
      - the second at 1:45, or 25 s after the first is done, whichever is sooner;
      - the third at 3:15, or 25 s after the second is done.

      A household is **done** when each of its four is out, taken or dead. Before its time it waits indoors, untouchable. Out, it
      stands at its door, holding.
    - **They move by the god's hand alone**, Mind Whisper or a Will-o'-Wisp's lure, at BELIEVER_PACE (0.45 of a citizen's: the old
      and the young walk with them), and hold where they are left.
  - **The lamp:**
    - Each household's first living member in town, not held, carries its lamp. Whisper the lamp-bearer and the others follow him in
      file (FOLLOW_GAP 0.9 apart, along the way he walked) while within FOLLOW_REACH (4) of him.
    - A follower whispered on his own leaves the file and holds where he is left. He rejoins once within 2 of his lamp.
    - The lamp passes to the next member when its bearer is seized, dies or gets out.
    - When the bearer gets out, his followers walk on to his way out and get out there.
  - **Seen and seized:** a watcher within SIGHT (2.5) who sees a believer seizes him and marches him to the Temple's door ("A
    BELIEVER IS TAKEN").
    - The watchers are the patrols, the gates' watch and the searchers.
    - A watcher held by Discord or a whisper sees nothing. So does one frightened, or one indoors.
    - A watcher marching one believer sees no other.
    - Felling or holding the seizer frees the believer where he stands; a whisper on the believer alone does not.
    - The rest of his household hold where they are.
    - Reaching the Temple's door, he is **taken** ("THE INQUISITION TAKES A BELIEVER"): he goes inside the Temple, lost to the count.
    - The march from any household's road is 12 units or more (about 20 s), time to answer it.
  - **Watchmen, not soldiers:** every watcher is a lay citizen made a watchman, so Mind Whisper and Discord work on all of them.
  - **The patrols:**
    - one walks the long west street from (-6.25, 0.0) to (-6.25, 12.0) and back, across the west household's road;
    - one walks the east-west street from (1.0, 9.0) to (12.0, 9.0) and back, across the east household's road and short of the
      south household's door.
  - **The gates' watch:**
    - two watchmen at each gate's mouth, 2.4 apart, held on duty;
    - no guard change: the gate is cleared by acting, never waited out (§6.1's `watch_changes`);
    - whispered or confused, one walks back 20 s after he is calm;
    - a fallen one is replaced 30 s later by a watchman from the Temple's door (at most six reliefs in a night), chosen out of the
      town's flight and backed off when none can reach the post.
  - **The searchers:** 30 s after each household comes out, two searchers come out of the Temple's door and walk to its lamp
    ("THE TEMPLE SENDS SEARCHERS"). Before that they wait inside the Temple. A searcher who has delivered a believer goes after his
    household again. A household done sends its searchers home.
  - **The gates shut** ("THE INQUISITION SHUTS THE POSTERN"):
    - the postern at 2:30, the Side Gate at 3:45, the Main Gate at 5:00;
    - each on the strip from the start, with the gate's tag counting down;
    - a shut gate is no way out: a believer at its mouth holds there, and its watch stays;
    - the town's own flight is the town's affair.
  - **Stray harm:** a believer killed is gone from the count, and his tag warns DO NOT KILL from the start. The HUD's row says how
    many are to spare.
  - **The God-Resistant town:** an evacuation (City Emergency) sends the crowd and the marshals to every way out. The believers are
    on duty where they hold, so the flight does not take them. If the crowd carries one out, he is out. The marshals are the town's,
    not the director's: they see nothing.
- **Timeline** (left alone):

  | Time | Event |
  |---|---|
  | 0:00 | "EXODUS". The households hide; the patrols walk; each gate is watched. |
  | 0:15 | "The west household comes out" |
  | 0:45 | "The Temple sends searchers" (30 s after each household comes out) |
  | 1:45 | "The east household comes out" (sooner: 25 s after the west household is done) |
  | 2:30 | "The Inquisition shuts the postern" |
  | 3:15 | "The south household comes out" (sooner: 25 s after the east household is done) |
  | 3:45 | "The Inquisition shuts the Side Gate" |
  | 5:00 | "The Inquisition shuts the Main Gate": lost unless ten are out |
  | 7:00 | Dawn |

  Left alone, the searchers take a believer from about 1:00, and the third leaves too few at about 2:12 (`exodus_few`, measured
  on seeds 1-3): doing nothing loses well before the last gate.
- **The clear:**
  - **The sum:** first wait 15 (the policy clears the west road and the postern's watch from 0:00) + the west household 53 (15 units
    at about 0.32 a second, two whispers, the postern's watch) + 25 + the east household 51 + 25 + the south household 40 + the
    searchers and a seizure answered, about 15 ≈ **225 s**.
  - **Measured** (Task 6's gate, seeds 1-2 won): first wait 15 + the west household 40-50 + 25 + the east household 35-42 + 25 +
    the south household's two 49-56 ≈ **196-206 s** (195.8 and 205.9; seed 3 lost at the last gate).
  - **The shortest:** the households' walk cannot be hurried and each chain is 25 s, so a skilled clear is about 195 s.
- **Longest waits:**
  - 15 s to the first household;
  - 25 s between a household done and the next coming out, its road and gate to clear in it;
  - every gate is cleared by acting.

  The searchers are pressure, not a wait.
- **Tags:**
  - Each lamp-bearer: "LAMP - DO NOT KILL", steel blue, with an edge arrow. Each follower, a steel-blue diamond.
  - A seized believer: "TAKEN TO THE TEMPLE", red, with an edge arrow. Then TAKING HIM IN on his seizer and TEMPLE on the Temple's
    door, both red, with edge arrows.
  - A household still inside: "HOUSEHOLD - OUT BY 1:30" (the sooner time), grey, over its door, with an edge arrow.
  - Each gate, with an edge arrow: "POSTERN - WATCHED" (red), "POSTERN - CLEAR" (green), "POSTERN - SHUT AT 2:30" while shutting
    is under a minute off (orange), "POSTERN - SHUT" (grey).
  - SEARCHER on each searcher, red, with an edge arrow. PATROL on each patrol's first watchman, red. A red diamond on every other
    patrol watchman and on each gate's watch.
- **Hint phases:**

  | Phase | Line |
  |---|---|
  | (none) | Whisper each lamp (blue) to an open gate: the rest follow. Inquisitors (red) seize on sight. Ten must get out alive. |
  | `caught` | A believer is taken to the Temple. Whisper, Discord or strike the man taking him (red). |
  | `hounds` | The Temple's searchers (red) follow the household. Strike them or turn them before they see it. |
  | `gate` | Inquisitors (red) watch the gate. Whisper them off or strike them, then send the household through. |
  | `shut` | That gate is shut. Lead the household to another open gate. |
  | `waiting` | The next household comes out in {n} s. Clear its road and its gate of Inquisitors (red). |

- **HUD:**
  - "Lead them out 3 / 10, 2 to spare" (`EscortObjective` with `need` 10, its line from `hud_line()`);
  - "Halcyon's Gaze 0%".

  The shuttings are on the strip. None is an `EventObjective`: only the last one loses, and only with fewer than ten out, so the
  director judges it (`lost_reason()`).
- **Tour:**
  1. "The west household hides here. It comes out at 0:15: whisper its lamp to the postern, and the rest follow."
  2. "The gates. The Inquisition shuts the postern at 2:30, the Side Gate at 3:45 and the Main Gate at 5:00."
  3. "The Temple. Inquisitors take any believer they catch here. Ten must get out."
- **Mission tags:** `shuts_gates`. It keeps "Lead my brother out" and "Lead my family out" away: on a night of leading out through
  gates that shut, a wish's escapee walking out through a shut gate would read as a contradiction.
- **Pool:** every power.
- **Results:**
  - "THE FAITHFUL ARE OUT" (`exodus`);
  - "TOO FEW ARE LEFT" (`exodus_few`);
  - "THE GATES ARE SHUT" (`gates_shut`);
  - the Gaze's "THE LANTERN LOOKS" (`gaze`).

  Its own keys, never the Escort defaults (M2 decision 63).
- **Numbers** (first guesses, kept by Task 6's gate; only the south household's point moved):
  - **The households:** BELIEVERS 12 (3 × 4), NEED 10, OUT_AT 15 / 105 / 195, CHAIN 25, BELIEVER_PACE 0.45, FOLLOW_GAP 0.9,
    FOLLOW_REACH 4.0.
  - **The watch:** SIGHT 2.5, PATROLS 2 × 2, GATE_WATCH 2 (2.4 apart), RETURN_AFTER 20, RELIEF_AFTER 30, RELIEFS 6, HUNT_AFTER 30,
    HOUNDS 2 a household, QUIET 3.5.
  - **The gates:** SHUT_AT 150 / 225 / 300.
  - **Tuning order,** if the scripted clear misses 180-240 s: CHAIN (20-30), BELIEVER_PACE (0.4-0.55), the houses (12-16 units of
    street from their gates), OUT_AT[0] (10-30), HUNT_AFTER (20-45). Every wait stays 45 s or less.
  - If doing nothing does not lose 3 of 3: HUNT_AFTER comes down.
- **Scripted policy** (`--scenario=exodus`; loadout Mind Whisper, Silent Doom, Discord, Will-o'-Wisp, 6 DP):
  - Every LOOK_FRAMES, the first that applies:
    1. A believer is seized: Discord on the seizer; else whisper the seizer eight units away; else Doom him unseen.
    2. Searchers within 6 of a believer: clear one (below); searchers farther off: Doom them unseen wherever they walk (they walk
       1.0 apart: one Doom takes both).
    3. A watcher within SIGHT + 1.5 of a believer: clear him.
    4. A believer left out of his household's file, more than FOLLOW_REACH from his lamp: whisper him to it.
    5. Each household out, in order: its lamp free, not walking and Whisper ready -- whisper it up to 10 units along its road to the
       nearest open gate, stopping 3 short of a watched gate and 4 short of the first watcher on the way; else clear that watcher (or
       one at its gate).
    6. The next household comes out within 25 s: clear the first watcher on its road -- by Doom or Discord, and by a whisper only in
       its last 8 s (sooner, he is back at his post before it comes).

    To clear a watcher: Doom him (and a watcher beside him) where it goes unseen with 0.5 to spare; else Discord where it holds two,
    or him when no whisper is ready, with no believer near; else whisper him eight units away. (Tuned, Task 6: the busy postern and
    the believers themselves witness most Dooms, so the whisper carries the night; the plan's one-step policy lost all three seeds.)
  - **Its Gaze:** it casts no loud power and Dooms only unseen. Expected Gaze: 0-10% (measured 0 / 0 / 10). Expected clear: about
    3:20 (measured 3:16 and 3:26).
- **Evacuate-mid-mission test:**
  - The evacuation begins with the east household walking (its lamp whispered) and a gate watchman recovering. The household walks
    on, its followers follow, and none flees. The watchman walks back. The south household stays inside.
  - The crowd carrying a believer out counts him out.
- **No hidden losses:**
  - Every believer is tagged DO NOT KILL, and the HUD says how many are to spare.
  - A seizure is a march of about 20 s under a red tag with an arrow.
  - Every shutting is on the strip from 0:00.
  - The houses are stone tonight.
  - A believer leaving the town by any way resolves at once as out.
- **How it differs from The Lost Lamb and The Prisoner** (M2 lesson 10):
  - **A crowd, not a person:** twelve charges in three households. A whisper on the lamp moves four.
  - **The gates close:** three ways out, shut one by one. A slow household must turn for another.
  - **No waiting at the gate:** no guard change. The gate is cleared by the god's hand.
  - **The count, not one life:** two may be lost; the third loses the night at once, with the count on the HUD.

## 3. The Heart of Faith (Raze + Assassinate)

The last mission. Two stages: put out Halcyon's Great Flame, then kill the High Priest who comes to rekindle it.

- **Stage one** is M4's and M5's staged Raze with Lantern Knights. The flame is fed from its oil-house and burns in the Great
  Temple: burn both, in turn, and the flame goes out.
- **Stage two** is an Assassinate that cannot end in one cast (M2 lesson 1). Odran rides to the Temple's steps in a closed litter
  carried by four Lantern Knights. Inside it he is untouchable, so his bearers must fall first. Then on foot he begins the
  rekindling, which an interruption starts again.

- **Brief:** "Halcyon's Great Flame burns in his Temple." / "Put it out. Then kill his High Priest."
- **Card type:** Kill. **Id:** `heart_of_faith`.
- **Map:**
  - **The oil-house:** the dwelling nearest (-2.5, -12.5), in the quiet row behind the Temple on its west side, whose door the
    street reaches. Tagged OIL-HOUSE. 50 hp; it burns. If a wish has set it aside, the next nearest. (Task 7's sync: the first
    guess, (-3.5, -9.5), stands in streets never clear of passers-by and the town's patrols -- a 120 s sample found no point within
    a Knight's reach clear of a witness 1% of the time -- so no Knight there could be Doomed unseen; the row behind the Temple is
    clear 80-99% of the time.)
  - **The Great Temple:** `TownLayout.TEMPLE` (centre (0.8, -8.7)), its front door and steps at (0.8, -5.0). Tagged TEMPLE. 200 hp;
    it burns.
  - **The Citadel's gate** (-10.5, -7.6): where Odran waits and the Knights' reliefs come from.
  - **Odran's road:** from the Citadel's gate down the lane to (-10.5, -5.1) and east along the cathedral's street to the Temple's
    steps, about 14 units.
  - **The camera** rests at (-6.0, -4.0). The oil-house is up and right of the centre, the Temple at the right, its steps just
    below it, and the Citadel's gate above the centre, clear of the stack.
- **Claims:**
  - One cleric: Odran.
  - The Lantern Knights, added soldiers, up to 17 in a night: four standing, four coming out at the stages, four bearers, one last
    guard and at most four reliefs.
  - The oil-house and the Temple, both in `EngineerManager.hands_off`, so the town's engineers never mend them.
  - No lay citizens.
- **Main objective:** put out the Great Flame, then kill Odran.
  - **Stage one:** the flame goes out the moment the Temple is razed ("THE GREAT FLAME GOES OUT").
  - **Won** the moment Odran dies, any way, once the flame is out. Before it he is inside the Citadel and cannot be reached.
  - **Lost** when:
    - the flame still burns at 5:00 ("THE GREAT FLAME IS BLESSED");
    - Odran finishes the rekindling ("THE FLAME IS KINDLED ANEW");
    - Halcyon's Gaze fills ("THE LANTERN LOOKS");
    - dawn comes.
- **People and behaviour, stage one** (M4's staged rule as The Armoury's ruling has it; `RazeDirector`):
  - **In use** (the stages, `_spoilable()`):
    - the oil-house at 0:45 ("THE KEEPERS DRAW THE FLAME'S OIL");
    - the Temple at 1:50, or 45 s after the oil-house is razed, whichever is sooner ("THE GREAT FLAME BLAZES"); a Temple already
      down when the oil-house is razed comes into use at once, and so is razed (M5's horn rule).
  - **Before its time:**
    - every blow lands, and a target can fall: one down when its time comes is razed at once;
    - any fire on it is put out at once (the Temple's keepers inside), and nothing it burns counts.
  - **Razed** (`_spoil_for()`, §6.5): while in use, the oil-house burned 12 s in all or fallen; the Temple burned 20 s in all or
    fallen. It stays razed. Seconds burned stay counted.
  - **The Knights:**
    - **Standing:** two Lantern Knights at each target from the start, on posts along its quiet face (of the doors the street
      reaches, the one nearest its quiet yard behind the Temple, `QUIET_AT`), 2.4 apart, beyond a witness's 2.0 of every other
      post, nearer their own target than the other, and kept 2.5 off the town's soldiers' posts where they can be (a Knight among
      the watch could never be Doomed unseen). Packed in by its neighbours, a target's four spread as far apart as its yard allows.
    - **Coming out:** at its time two more come out of the target's own door, on posts 2.4 beyond them, out from the face. Before
      that they wait inside, untouchable: the work that cannot be done ahead.
    - **Soldiers:** Mind Whisper and Discord refuse them (M5 plan decision 173) and fear does not move them. Only a kill removes one.
  - **On guard:** a Knight alive, out of doors, within GUARD_REACH (2.5) of the target's footprint, on his post. While one stands
    on guard, the target is sealed (`seal()`; `unseal()` once none is): blows shake it and its fire is put out. The Armoury's
    ruling, before or after its time.
  - **Relief:** a standing Knight who falls is replaced 30 s later by a Knight walking from the Citadel's gate, while his target is
    not razed. At most four reliefs in a night. With no road from the gate to his post, the relief backs off and is tried again 30 s
    later.
  - **Razed:** its Knights walk to the Citadel's gate and go in. Any still running in go back.
  - **The town:** the fire brigade answers a fire on a target as it always does. Its men can be seen beating at the flames: that is
    the town's answer, not a hidden crew.
- **People and behaviour, stage two:**
  - **Odran:** the cleric nearest the Citadel's gate, taken inside the Citadel at the start, on duty there, untouchable, untagged as
    a person.
  - **His litter:** the moment the flame goes out, four Lantern Knights come out of the Citadel's gate as its bearers ("THE HIGH
    PRIEST'S LITTER WAITS"). They stand on the corners of a square of side 2.1 just outside the gate, beyond a witness's 2.0 of each
    other.
  - **He comes out** 30 s later (ODRAN_CHAIN: his own chain, never a pure 45 s; M4's captain ruling): "THE HIGH PRIEST COMES TO
    REKINDLE THE FLAME".
    - **The litter:** with two or more bearers alive he climbs in. Inside it he is hidden, indoors and untouchable, carried with it,
      as Pip rides M5's relic cart. The bearers carry him on duty at ODRAN_PACE (half a citizen's) down his road, keeping their
      square.
    - **On foot:** with fewer than two alive he walks his road on foot, and one more Knight comes out with him as his last guard,
      walking 2.5 behind him (beyond a witness's 2.0).
  - **The litter at the steps** (plan decision 291): within ALTAR_REACH of the Temple's steps it sets him down on foot; its living
    bearers stand by him as his last guard did.
  - **The litter falls** when its bearers fall below two ("THE LITTER FALLS"):
    - Odran steps out where it stands and walks on, on foot, killable;
    - any living bearer guards him as his last guard did, 2.5 behind.
  - **His walk:**
    - on duty at half pace;
    - Mind Whisper works on him (a cleric): he holds where he is left, then takes up his road again;
    - a fright stops him a moment, then he walks on;
    - he never runs and never goes back.
  - **The rekindling:** at the Temple's steps (within ALTAR_REACH 1.5 of (0.8, -5.0)), on foot and not held, he kindles for RITE
    (20 s) ("ODRAN REKINDLES THE FLAME"). A whisper, Discord or a fright on him starts it again from 20.
  - **His death:** any death, seen or not, ends the night in the god's favour. His Knights go home.
  - **Leaving:** a whisper or the crowd cannot carry him out, because he is held on duty. Should he leave the town anyway, his going
    ends him as his death would (`head_down()`'s freed-body rule): it resolves at once.
  - **Halcyon looks harder:** once the flame is out, a seen death adds FURY (20) to the Gaze, not 10 ("HALCYON LOOKS HARDER").
    Five seen deaths in stage two lose. Every rise of the Gaze is bannered: "HALCYON SEES A DEATH", and once the flame is out
    "HALCYON SEES A DEATH: +20".
    - **The clean line:** kill each bearer with a Doom from clear (they stand 2.1 apart, and Odran inside sees nothing), or kill the
      last guard 2.5 behind Odran. Then kill Odran alone.
- **Timeline** (left alone):

  | Time | Event |
  |---|---|
  | 0:00 | "THE HEART OF FAITH". Two Knights stand at the oil-house and two at the Temple; Odran is in the Citadel. |
  | 0:45 | "The keepers draw the flame's oil": the oil-house in use, two more Knights come out |
  | 1:50 | "The Great Flame blazes" (sooner: 45 s after the oil-house is razed): the Temple in use, two more Knights |
  | the flame out | "The Great Flame goes out": the litter's four bearers come out at the Citadel's gate |
  | +30 s | "The High Priest comes to rekindle the flame" |
  | +about 15-20 s | The litter (or he, on foot) reaches the Temple's steps (measured); 20 s more and the flame is kindled anew: lost |
  | 5:00 | "The Great Flame is blessed": lost unless the flame is out |
  | 7:00 | Dawn |

  Left alone the flame is blessed at 5:00, so doing nothing loses at 300 s.
- **The clear:**
  - **The sum:** first wait 45 + the oil-house 22 (its two new Knights, a Doom and a Smite; an Ember; 12 s alight) + 45 + the Temple
    30 (two new Knights; an Ember; 20 s alight) + 30 (Odran's chain, his four bearers Doomed in it, one at a time) + Odran 25 (on
    foot with his last guard: a Doom on the guard, then Odran) ≈ **197 s**.
  - **Measured** (Task 7's gate, seeds 1-2 won): first wait 45 + the oil-house about 20 (razed by 1:05-1:10; it burns down inside
    its 12 s) + 45 + the Temple about 35 (razed by 2:20-2:30) + 30 (Odran's chain, a bearer or two struck in it) + about 15 (the
    litter to the steps, or falling) = about **190 s** (193.8 and 187.2).
  - **The shortest:** a skilled player can fell the oil-house ahead of its time (its standing pair dead, two Smites), and it is razed
    at 0:45; a Temple felled ahead too comes into use, and is razed, the moment the oil-house is (M5's horn rule), so only Odran's
    chain paces the rest.
- **Longest waits:**
  - 45 s to the oil-house's time, with its standing pair to clear;
  - 45 s between the oil-house razed and the Temple's time, with the Temple's standing pair to clear;
  - 30 s for Odran, with his bearers at the Citadel's gate to work on.
- **Tags:**
  - **Stage one:**
    - The target in use, gold, with an edge arrow: "OIL-HOUSE - GUARDED" while a Knight is on guard, "OIL-HOUSE - SET IT ALIGHT"
      when open, "OIL-HOUSE - BURNING 7" (seconds of its 12 left), orange.
    - The next target, grey, with an edge arrow: "TEMPLE - THE FLAME BLAZES BY 1:50" (the sooner time); once felled ahead of its
      time "OIL-HOUSE - DOWN 0:45" (M5's wording: "DOWN, COUNTS AT" dropped a plate).
    - KNIGHT on each Knight on guard, red. A small red mark on one away from his post. A red diamond on a relief walking in.
  - **Stage two:**
    - "ODRAN - IN THE CITADEL" over the Citadel's gate, grey, with an edge arrow, with "COMES OUT IN 21" while his chain runs.
    - BEARER on each bearer, red, with an edge arrow (a moving target).
    - "ODRAN - IN HIS LITTER", gold, with an edge arrow, on the litter's middle while he rides. Then ODRAN, gold, with an edge arrow,
      on foot, and "ODRAN - REKINDLING 14" during the rite.
    - KNIGHT on his last guard (and on bearers standing by him), red, with an edge arrow.
    - ALTAR at the Temple's steps, orange, with an edge arrow, once he is out.
- **Hint phases:**

  | Phase | Line |
  |---|---|
  | (none) | Kill the Knights (red), then burn the oil-house and the Temple (gold): the Great Flame goes out. Then kill High Priest Odran. |
  | `not_yet` | Not in use yet (grey): fire there goes out, but a fall counts when its time comes. Kill its Knights (red) shortly before. |
  | `guarded` | Lantern Knights (red) guard it: it takes no harm, its fire goes out. Kill every one: whispers and Discord do not touch them. |
  | `open` | No Knight stands. Set it alight (gold) and keep it burning. |
  | `burning` | It burns. Keep it burning: a new Knight comes from the Citadel. |
  | `coming` | The flame is out: each seen death now adds 20 to the Gaze. Odran comes out in {n} s: kill his bearers (red) first. |
  | `litter` | Odran rides in his litter, untouchable. Kill his bearers (red): with fewer than two, it falls. |
  | `on_foot` | Odran walks to the Temple's steps (orange). Kill him before he rekindles the flame. |
  | `rite` | Odran rekindles the flame. Kill him now, or whisper him off the steps to start it again. |

  Every line fits the three-line plate (the controller's ruling); the Gaze's sentence is said once, in `coming`, beside the
  "HALCYON LOOKS HARDER" banner.
- **HUD:**
  - "Put out the flame 1 / 2: blessed in 2:10", then "Kill Odran", then "Kill Odran: in his litter" while he rides
    (`StagesObjective`, §6.5, its line from `hud_line()`);
  - "Halcyon's Gaze 10%".

  The blessing is not a separate deadline row. M4's ruling 159 says a dropped event reads as come, and this one is dropped once the
  flame is out. So the blessing is a timeline event, guarded by the flame still burning, that sets the director's loss (`blessed`).
- **Tour:**
  1. "The oil-house. Its Knights guard it. It feeds the flame from 0:45: burn it."
  2. "The Great Temple. The flame blazes here by 1:50. Burn it down to put the flame out."
  3. "The Citadel. High Priest Odran waits here. Once the flame is out he comes to rekindle it: kill him."
- **Mission tags:** `burns_temple` (M5's). It keeps "Save the heretic from the pyre" away: its march ends at the Temple's door.
- **Pool:** every power.
- **Results:**
  - "THE HEART OF FAITH IS BROKEN" (`heart`);
  - "THE GREAT FLAME IS BLESSED" (`blessed`);
  - "THE FLAME IS KINDLED ANEW" (`kindled`);
  - the Gaze's "THE LANTERN LOOKS" (`gaze`).
- **Numbers** (first guesses; Task 7's gate kept every one):
  - **Stage one:** STAGE_AT 45 / 110, CHAIN 45, STANDING 2, ARRIVING 2, POST_GAP 2.4, GUARD_REACH 2.5, SPOIL 12 (oil-house) / 20
    (Temple), RELIEF_AFTER 30, RELIEFS 4, BLESSED_AT 300.
  - **Stage two:** BEARERS 4, LITTER_SIDE 2.1, LAST_GUARD 1, GUARD_GAP 2.5, ODRAN_CHAIN 30, ODRAN_PACE 0.5, RITE 20, ALTAR_REACH 1.5.
  - **The Gaze:** SEEN 10, FURY 20.
  - **Placing** (Task 7): OIL_AT (-2.5, -12.5), QUIET_AT (-3.5, -14.0) for the oil-house and (2.0, -14.0) for the Temple, POST_APART
    2.1, QUIET 2.5.
  - **Tuning order,** if the scripted clear misses 180-240 s: CHAIN (35-45), STAGE_AT[0] (40-60), SPOIL[1] (15-25), ODRAN_CHAIN
    (20-30), ARRIVING (1-3).
- **Scripted policy** (`--scenario=heart`; loadout Silent Doom, Smite, Ember, Mind Whisper, Heaven Splitter, 6 DP; hit-stop off):
  - Every LOOK_FRAMES, the first that applies:
    1. Odran is on foot out of doors: Doom him when no one else is within 2; else Smite him.
    2. Odran's rite runs and neither Doom nor Smite is ready, but Whisper is: whisper him four units off the steps.
    3. Odran rides, or his bearers wait at the Citadel's gate: strike a bearer.
    4. His last guard stands within 3 of him: strike the guard.
    5. The target in use has a Knight on guard: strike one.
    6. The target in use is unguarded and not burning: Ember it (Smite it if Ember is cooling).
    7. The next target's time is within 25 s: strike its standing Knights, one at a time.
    8. A relief walks toward a target not razed: strike him.
  - **A strike** (Task 7): Silent Doom where its death goes unseen; else Smite there; else Mind Whisper sends the lone citizen who
    would see it 8 units off; for 3-5 (work that cannot wait), at last a seen Doom, 3 s after any such whisper, while the Gaze stays
    within 60%. Odran himself is struck seen or not: his death is the win.
  - It never fells a target ahead of its time.
  - **Its Gaze:** Dooms from clear; a Smite only when no Doom is ready, and only on a man with no one else within 2 if it can choose.
    Expected Gaze: 0-30%. Expected clear: about 3:20. Measured (Task 7): the Gaze 50-70% before the last blow, which is seen and
    takes it to full as Odran dies (the Citadel's gate and the burning Temple draw crowds, and bearers there are seldom clear); one
    seed in three is lost to it; the clear about 3:10.
- **Evacuate-mid-mission test:**
  - The evacuation begins while the Temple is in use, a Knight's relief walking in: the relief reaches his post and the Knights hold.
  - Again while the litter walks: the bearers keep their square, Odran stays hidden in it, and on foot -- recovering, or whispered
    -- he keeps his road.
  - Odran never leaves the town.
- **No hidden losses:**
  - The 5:00 blessing is on the strip from 0:00.
  - The rekindling counts down on Odran's tag and in the hint, and starts again on any interruption.
  - Odran cannot be killed by a stray before the flame is out (he is in the Citadel). Afterwards his death is the win.
- **How it differs from The Bishop** (M2 lesson 10):
  - **The god puts a fire out by setting fires:** the stages are an oil-house and the Temple under Lantern Knights, a staged Raze.
    The Bishop's refuges are a chase.
  - **Odran comes toward the god's ruin, not away to safety:** his danger is a rite at the end of his road, which can be started
    again, not an escape.
  - **The litter:** his ward is four bearers whose fall spills him out, not a ring round a man in the open.
  - **The Gaze turns:** seen deaths cost double in the last stage.

## 4. Tier 5 on the board, and the board complete

- **The tab:** `TierBook.MISSIONS[4]` becomes `["last_judgement", "long_night", "lantern_eye", "exodus", "heart_of_faith"]`: the ★
  missions first, as on the other tabs.
- **Types:** `"lantern_eye": "Anchors"`, `"exodus": "Protect"`, `"heart_of_faith": "Kill"` in `TierBook.TYPES`.
- **Mission tags:** `"exodus": ["shuts_gates"]`, `"heart_of_faith": ["burns_temple"]` in `TierBook.MISSION_TAGS`.
- **Cards:** five on Ascendance's tab, 115 px wide, with Whisper's wrapping rules (M2 ruling 58). Every brief fits seven lines.
- **Unlocking:** unchanged. Ascendance opens at three Reckoning missions cleared (M5). It is the last tier, so it opens nothing.
- **The results' tier line** for Ascendance counts all five: "Ascendance 2 / 5 cleared". Below Tier 5, a tier line counts toward
  the three that open the next.
- **The board complete:** with all 25 board missions cleared:
  - the results' line reads "Ascendance 5 / 5 cleared: every tier is cleared";
  - the board's header reads "Night N   Believers N   All 25 cleared".

  Nothing else changes: every night can be played again for its bests, and believers and upgrades go on as before.
  `DescendState.all_cleared()` answers it.

## 5. New wishes for Tier 5

The pool grows from 16 to 18. Both new wishes have `min_tier` 5, so Tier 1-4 nights shuffle exactly what they did (M3 ruling 3,
`WishBook.pool_for()`). Each reuses a kind's code with new parameters whose defaults keep the old wishes exact, as M4's and M5's
did.

| Wish | Kind | Act | Reward | Needs / clashes |
|---|---|---|---|---|
| Strike down the zealot, unseen | Punish | Kill the marked cleric with no living witness | 15 | a cleric out of doors; none |
| Turn the doubting priest | Faith | Whisper the marked cleric to within 2 units of the wisher; he believes | 15 | a cleric out of doors with a route to the wisher of at most 30 units of street; none |

- **Strike down the zealot, unseen:**
  - `PunishWish` with `"clergy": true` (the default, false, keeps the tax collector, the informer and the sergeant exact) and the
    informer's `"unseen": true` (no living witness within 2, as The Warning judges).
  - Tag ZEALOT, pointed at from the edge (clergy walk).
  - Failed by a seen kill, or if he leaves the town, or when the wisher dies.
  - On The Heart of Faith's night the wish is drawn before Odran is chosen, so Odran is never the zealot: a reserved cleric is
    passed over.
- **Turn the doubting priest:**
  - `NeighboursWish` with `"count": 1` and `"clergy": true` (the defaults, 3 and false, keep Let my neighbours believe exact).
  - Tag DOUBTING PRIEST, pointed at from the edge.
  - Granted when he comes within 2 of the wisher (`NeighboursWish`'s rule). Failed when he dies before believing, or when the wisher
    dies.
- **Why these two:** both answer Tier 5's Gaze. The zealot is an unseen kill of Halcyon's own. The priest is a quiet turning of
  one, a whisper's work across the town.
- **Draws:** a Tier 5 night's draw changes, since the pool it shuffles grows. Last Judgement's and The Long Night's board nights
  hear from eighteen. Any test that pins a Tier 5 draw is re-pinned to what the new pool gives, and named in the plan.

## 6. What the shared code gains

M3 lesson 8: every shared change is a hook or a var whose default is today's path, proven by the exact references. The three items
M4's final review carried to M6 are §6.1, §6.2 and §6.4.

### 6.1 EscortDirector: the Charge record (carried item 1)

M4's final review found that `EscortDirector` keeps one charge's state for the whole director, so its `(c)` hooks suggest a
multi-charge support it lacks. M6 makes it real before Exodus builds on it. M4 Decision 67's "the base unchanged" is reworded in
M6's plan to read: "the base gains the Charge record, its accessors gated on the Lamb's and the Prisoner's twelve".

- **`class Charge`** (inner, RefCounted) holds the per-charge fields:
  - `man: Person`;
  - `held`, `seizer` (a Variant), `hold_at` (the old `_hold_at`);
  - `bound`, `bound_lost`, `freed_at`;
  - `escaped`, `taken`;
  - `change_in`.

  Its defaults are today's: false, null, `Vector2.INF`, -1.
- **`var charges: Array[Charge]`**, filled by `_appoint_charges() -> Array[Person]`. That is virtual, `[_appoint_charge()]` by
  default (none for null).
- **Accessors:** the old fields `charge`, `held`, `seizer`, `_hold_at`, `bound`, `bound_lost`, `freed_at`, `escaped`, `taken` and
  `change_in` become properties that read and write `charges[0]`. With no charge they give today's defaults (`charge` null). So
  `LostLambDirector`, `PrisonerDirector`, `EscortObjective`, their tests and their scenario policies read as before.
- **Per-charge steps** take the record:
  - `_step_free(c: Charge)`, `_step_held(c)`, `_step_bound(c)`, `_unbind(c)`;
  - `_seen_by(c)`, `_seize(c, by)`, `_release(c)`, `_escape(c)`, `_taken_inside(c)`.

  `_on_escaped(p)` finds the charge whose man is `p`. The appointment hooks keep their `Person` argument (`charges[0].man`), as
  The Prisoner overrides them.
- **`step()`:** each charge not resolved, in order: held, bound or free. Then the watch's posts, the patrols and the searchers,
  once. With one charge the calls run in today's order, so The Lost Lamb's and The Prisoner's six references each hold. The early
  return becomes `_all_resolved()`, which for one charge is today's test.
- **A watcher marching one charge sees no other** (`_seen_by(c)` skips another charge's seizer). This is vacuous with one charge.
- **`_exit_reached(c) -> bool`** (virtual): within ESCAPE_REACH of `exit_at` by default. Exodus: any open gate's way out.
- **`watch_changes := true`:** false stops the guard change ever starting (Exodus). Its default is today's.
- **Reads:** `out_count()` (charges escaped) and `left_count()` (charges alive in town and not taken).
- **`EscortObjective`** gains `need` (default 1):
  - with 1, its checks are today's (escaped, taken, dead, the director's `lost_reason()`);
  - with more, DONE at `out_count() >= need`, and FAILED only through `lost_reason()`, so a single seizure never ends a
    many-charge night.
- **The gate:** The Lost Lamb's six and The Prisoner's six references exact, FLOW 113/0, before any Exodus code lands (its own
  task).
- **`ExodusDirector`** (new, its subclass) adds:
  - the households and the lamp (the file);
  - the gates (each a mouth, a way out, two posts, a shut time); it fills `watch_posts` with all six posts so the base keeps them;
  - the gates' reliefs, its searchers per household, the count loss;
  - its tags, hints, tour and report.

### 6.2 HuntDirector (carried item 2)

- **`_unguarded_blow(s, amount, source, kind)`** (virtual):
  - `_shield()` calls it for a blow on a standard no one guards;
  - by default it is today's path (lower hp, mark the hit, crack, destroy at 0). When the standard came with a damage filter of
    its own, the blow is handed to that saved filter instead: a borrowed building's own owner keeps its health. That is the
    carried fix to "replaces a borrowed tower's filter while standing";
  - The Heretic Hunt's posts have no filter of their own, so its six hold.
  - The Lantern's Eye overrides it: the glass.
- **`shield_hits := false`:** when true, the default unguarded path also emits `Structure.hit` as `Structure.damage()` does (fire
  catching, windows). The Lantern's Eye sets it and its override emits the tower's hit. The default keeps The Heretic Hunt's
  standards out of the fire manager's hearing, so its references hold. That is the carried "skips hit.emit".
- **Reserved towers:** the base reads no tower. The Lantern's Eye's tower choice skips `reserved_places` and the bell tower, as
  The Bell-Ringers' `_tower_near()` does (copied into the Eye, not shared; `BellRingersDirector` is untouched).
- **The step's break is the drain's end:** the Eye calls the base's `_break(i)` when a mirror is gone for good. So the chain, the
  party's going home and `timeline.expect()` are the base's. `_on_broken()` never fires for a tower, because the filter owns its
  health.
- **`LanternEyeDirector`** (new, its subclass) overrides:
  - `_plan()`, `_raise_standard()` (the tower), `_party_post()` (the town-side face), `_unguarded_blow()`;
  - `_found()` (the Eye opened) and `_quarry_point()` (the god's last heard cast, which the light uses; never tagged);
  - `tags()`, `hint_phase()`, `hint_seconds()`, `tour()`, `report()`.

  It keeps `has_head` false. Its wrights, the glass, the drain and the light are its own.

### 6.3 Searchlight

- **`hunt := false`:** when true, every heard noise draws the nearest lit beam at once, not only in the clock's last SEARCH_LAST
  seconds.
- **`hold := INF`:** how long a drawn beam stays at its noise before going back to its sweep. INF is today's: it stays until a
  newer noise.
- The Eye lights both beams at 0:00 (`light(SECOND_AFTER)`, as the bench does) and sets `hunt` while a mirror stands.
- The Vigil Flame and The Relic Run never set either. So The Relic Run's six references, The Vigil Flame's outcome and its play
  line (M5's Task 1 recording) prove the defaults.

### 6.4 The tag frame's keepout (carried item 3: the structural dead-zone fix)

M2-M5 moved cameras one mission at a time to keep tags and arrows out from under the left HUD stack. M6 fixes it in the HUD, once,
for every mission.

- **`Hud.stack_rect() -> Rect2`:** the live left stack as drawn this frame. It runs from the screen's corner to the right edge of
  the widest of the objective panel, the hint plate and the wishes plate, and down to the bottom of the lowest, plus STACK_PAD
  (4 px). It is empty when none is drawn (an intro's caption, the results).
- **`Hud.tag_layout(tags, xf, view, keepout := Rect2())`** and **`frame_point(point, frame, keepout := Rect2())`:** with an empty
  keepout, today's layout exactly. With one:
  1. The frame becomes the frame less the keepout, an L-shaped region. A tag with `edge` whose diamond lies inside the keepout
     becomes an arrow on the keepout's outer border, where the line from the frame's centre to the diamond crosses it. Its label
     goes beside the arrow, toward the centre.
  2. An arrow that `frame_point()` would put on the frame's left or top edge inside the keepout's span is put where the same line
     crosses the keepout's border instead.
  3. The keepout counts as a label already placed. So no plate is drawn over the stack: a label that would overlap it is dropped,
     as one overlapping an earlier tag's label is.
  4. A tag without `edge` inside the keepout keeps its diamond (under the translucent plates, as today) but not its label.
- **`_draw_tags()`** passes `stack_rect()`. Every mission and every campaign night gets it, and no camera moves.
- **No reference moves:** tags are not in any checksum (The Prisoner's lifted plates moved none), and no camera changes.
- **Tests:**
  - unit checks of the keepout (an edge tag under the stack arrows to its border; an arrow bound for the stack's span slides off
    it; no label plate intersects the keepout; an empty keepout lays out as before);
  - every existing tag-layout check passes unchanged, as they pass no keepout;
  - any test that pins a tag's mode at a mission's camera is re-run, and one that changes is named.
- **Photos:** The Crown's Bread's, The Informer's and Spoiled Harvest's photographs are taken again with a full night's rows, to
  show their old trouble spots clear (§7).

### 6.5 Everything else

- **`RazeDirector._spoil_for(s) -> float`** (virtual): `spoil_seconds` by default; `_judge_targets()` reads it. The Heart of Faith
  gives 12 and 20. Spoiled Harvest's, The Crown's Bread's and The Armoury's six each prove the default.
- **`HeartOfFaithDirector`** (new) extends `RazeDirector`:
  - stage one is the base's targets, `_spoilable()` stages, `seal()` / `unseal()` and `_spoil_for()`, with M5's Knights;
  - stage two (the litter, Odran's road, the rite, the fury) is its own;
  - its objectives are `StagesObjective`, `GazeObjective` and the tier's dawn. The blessing and the rekindling are the director's
    `lost_reason()` (`blessed`, `kindled`);
  - `AssassinateDirector` is untouched: its quarry and round fit neither the litter nor the rite.
- **`StagesObjective`** (new, generic; M2 ruling 61):
  - it takes its label and win reason in `_init()`;
  - DONE when `director.stages_done()`; FAILED with the director's `lost_reason()` when not empty;
  - its HUD line is the director's `hud_line()`, else the label;
  - the Heart's reasons: `heart`, and `blessed` and `kindled` from its director. It is the one new objective class in M6.
- **The Tier 5 Gaze objective:**
  - each new mission lists `GazeObjective` among its own objectives;
  - `TierBook._with_gaze()` (and `_with_gaze_for_night()`) appends one only when the list has none. Last Judgement and The Long
    Night have none, so their board versions are as before.
- **`Descent.LOST`** gains nothing. The new losses all end a night before its main objective is done, so no granted wish is ever
  "lost" by them. After the main objective only the Gaze or dawn can catch a night, and those have their words.
- **`PunishWish`:** `"clergy"`. **`NeighboursWish`:** `"count"` and `"clergy"`. **`WishBook`:** the two new wishes, and the
  `shuts_gates` clash on "Lead my brother out" and "Lead my family out". No mission below Tier 5 declares that tag, so their draws
  do not change.
- **`MissionBook`:** `_tier5()` and the three missions; `tier_missions()` lists them.
- **`TierBook`:** Ascendance's tab, types and tags; `_with_gaze()` as above.
- **`DescendState`:** `progress_line()` counts the last tier's missions, and `all_cleared()`.
- **`MissionBoard`:** the header's "All 25 cleared".
- **`EngineerManager.hands_off`** (M4's): The Heart of Faith's oil-house and Temple.
- **New:** `LanternEyeDirector`, `ExodusDirector`, `HeartOfFaithDirector`, `StagesObjective`.
- **TownLayout in shared code** (the capital-city branch, M3 ruling): no new read outside `src/game/mission/`. The wishes read
  roles and kinds; the HUD reads only its own panels. The new directors read TownLayout (`TEMPLE`, `POSTERN_AT`, the gates' and
  towers' points) in a few named constants each.

## 7. Testing, photos, bench and notes (v0.11's close)

- **Per mission:**
  - unit tests of its director, on M3's kit (`Kit.world()`, `Kit.run_for()`, `Kit.arrive()`, `Kit.free_body()`, `Kit.labels()`,
    `Kit.edged()`, `Kit.evacuate()`, `Kit.clear_of_stack()`);
  - headless people never think: a test that moves a man off his post calls `_come_to()` or `_wake()` by hand and places walkers
    with `Kit.arrive()` (M4's pre-flight rulings);
  - a behaviour scenario, `--scenario=eye|exodus|heart --case=none|play [--seed=N] [--board]`, running the `MissionBook` version
    (the same director, clock and town, no wishes), so its checksums are exact references; `eye` and `heart` turn hit-stop off;
  - the gate of §0;
  - M3's `_waits` test extended to every new timed wait (the mirrors and their chain, the drain and the re-hanging, the Eye's
    countdown, the households and their chain, the searchers, the shuttings, the stages, the Knights' reliefs, Odran's chain, the
    rite).
- **The kit:** `Kit.STACK` (240×165, the real stack with the hint and three wish rows) beside the old `DEAD` (240×100), and
  `clear_of_stack(g, cam, zone := DEAD)`. M6's missions check against `STACK`; the old checks are unchanged.
- **What each mission's tests pin** (M2-M5 lessons):
  - **a body freed mid-night** (a guard, a wright, a relief, a believer, a watchman, a searcher, a Knight, a bearer, Odran):
    `tags()`, `hint_phase()`, `report()` and the objectives never touch it;
  - **the evacuation mid-mission** (each mission's own test, §1-§3): everyone held stays held;
  - **a wish's people and buildings:** no wisher or wish target becomes a guard, a wright, a believer, an Inquisitor, a searcher or
    Odran. No wish's building becomes a mirror tower, a household's house or the oil-house (the next nearest is used instead). A
    watchtower wish's tower is never a mirror;
  - **The Lantern's Eye:**
    - a mirror does not exist before its time;
    - a guarded mirror only shakes its tower, and the tower's health never moves;
    - two Smites shatter an open one;
    - a mirror hung again within the drain stands, and one left 20 s is gone for good;
    - a cast in a lit pool adds 20, and a whisper there too, though it draws no beam;
    - a heard cast draws the nearest beam only while a mirror stands, and the beam goes back after 8 s;
    - all three standing for 30 s loses, and a shattering stops the count;
    - every tower's filter is given back at teardown;
  - **Exodus:**
    - a household is untouchable inside, comes out at its time or its chain;
    - the file follows its lamp, and the lamp passes on;
    - a watcher marching one believer seizes no other;
    - a shut gate lets no one out, and another open gate does;
    - the count loss comes the moment out plus left falls below ten;
    - the crowd carrying a believer out counts;
    - the houses only shake;
  - **The Heart of Faith:**
    - a target not in use puts its fire out, and a fall counts when its time comes;
    - a Knight on guard seals it;
    - the Temple razed puts the flame out and brings the bearers;
    - Odran is untouchable in the Citadel and in his litter;
    - the litter falls below two bearers;
    - an interruption starts the rite again, and a finished rite loses;
    - a seen death adds 20 once the flame is out;
    - the Knights are never taken by the rally or the marshals;
  - **the groundwork** (its own test file):
    - the Charge accessors read and write `charges[0]`;
    - a two-charge escort steps both, and a marching seizer sees no other;
    - `need` 1 is today's objective;
    - `_unguarded_blow()`'s default and its borrowed-filter path;
    - `shield_hits` off is silent;
    - the Searchlight's `hunt` and `hold` (and their defaults);
    - `_spoil_for()`'s default;
    - `_with_gaze()` adds none to a list that has one;
    - the keepout (§6.4).
- **Exact references that must not move:**
  - the digest, `crowd_check`, every behaviour checksum and outcome in M5's global constraints (calm, gates, fire, rite, soldiers,
    the five Warning cases, Mira's House, Broken Lanterns 424350965, the Vigil Flame's and the Feast's outcomes, the Vigil Flame's
    play line);
  - M2's 24 (refs24; The Lost Lamb's six prove the Charge record);
  - M3's 18;
  - M4's 18 (The Prisoner's six prove the Charge record; The Heretic Hunt's six prove the Hunt hooks; The Crown's Bread's six prove
    `_spoil_for()`);
  - M5's 24 (`bishop`, `armoury`, `sermon`, `relic`, none and play, seeds 1-3, as recorded at M5's landing; The Relic Run's six
    prove the Searchlight's hooks; The Armoury's six prove `_spoil_for()`).
- **FLOW:**
  - the board and results steps change for Ascendance's five missions;
  - one step is added: The Lantern's Eye from the board, its three mirrors gone by its public state, ascended, then the results
    reading "Ascendance 1 / 5 cleared";
  - FLOW goes from 113 to 114;
  - the board's end state (all 25 cleared: the header and the results' line) is a unit test, not a FLOW step.
- **Photos:**
  - `--show=lantern_eye|exodus|heart_of_faith` (the tour skipped, the opening banners waited out);
  - `--show=lantern_eye-hunt` (the first mirror up at once, a beam drawn to a cast) and `--show=heart_of_faith-odran` (the flame
    out, the litter on its road);
  - `--show=tiers --mission=last_judgement` (Ascendance's tab, its save clearing three Ascendance missions) and `--show=tiers-all`
    (the board complete: every tab ticked, the header's "All 25 cleared");
  - the keepout's proof: `--show=crowns_bread|informer|spoiled_harvest` with three wishes, against their M4 / M3 / M2 photographs;
  - each photo is checked for the stack and the edge arrows. The Lantern's Eye's for the beams' glare over the tags (if the drawn
    light washes a tag out, the tag's plate darkens, not the light).
- **Bench:**
  - The Lantern's Eye's board version (`--mission=lantern_eye --board --bench`: the Searchlight lit and drawn all night, both beams)
    against Last Judgement's, on a quiet machine;
  - **v0.11's release bench:** one mission per tier (The Warning, Mira's House, The Vigil Flame, The Procession, Last Judgement),
    board versions, medians of three, against `kak-v011-m5` and against v0.10's release tag.
- **Release notes:**
  - an M6 section at the top of `docs/KAK_Version_0.11_Summary.md`, its rulings numbered on from M5's last;
  - a short v0.11 close above it: all 25 missions by tier with their types, the wish pool of eighteen, the shared types and hooks
    the milestones built, and the final gates;
  - the README's `--show` list gains the M6 names.
- **Spec sync:** each mission task syncs its section here to its tuned numbers (M3 ruling).

## 8. Decisions

These are the details the v0.11 spec left open, numbered on from M5's plan (206). The controller records them as rulings. Each
gives its cost if it proves wrong.

207. **Ids and building:** `lantern_eye`, `exodus` and `heart_of_faith`, built in `MissionBook.tier_missions()` by a new
     `_tier5()` frame (420 s, tier 5, `tier_floor` 4, no `profile`, 6 / 16, no bonuses). So their stretch is 1 and
     `TierBook.board()` needs no branch. Not in `all()` nor the campaign. Cost if wrong: a scripted run meets another town; one
     frame to change.
208. **Each new mission keeps its own Gaze,** a plain `GazeMeter` (a seen death adds 10). `Descent.attach()` leaves it. Last
     Judgement and The Long Night keep M1's 0.5. Cost if wrong: ten seen deaths may be too harsh or too soft; a per-mission
     scale is one constant.
209. **The bell does not fill the new Gaze** (M1 ruling 10). Cost if wrong: a loud night that keeps its kills few is forgiving;
     the seen deaths still fill it.
210. **No bell loss in M6.** Cost if wrong: too forgiving; add `BellSilentObjective` to one mission.
211. **The Gaze objective is the mission's own;** `TierBook._with_gaze()` appends one only when none is listed. Cost: none; the
     ★ missions are unchanged.
212. **Unseen by design:** every guard post more than 2.0 from every other (POST_GAP 2.4, or rings of 2.1-2.5), and each policy
     Dooms only a man with no one else within 2. Cost if wrong: posts that spread out read less as a guard; the tags carry it.
213. **The Lantern's Eye, the code:** `LanternEyeDirector extends HuntDirector`. Towers are its standards, it has no head, and
     `_found()` is the Eye opening. Cost if wrong: a fork of the Hunt code.
214. **The mirror towers:** the wall towers nearest (0.0, -15.65), (15.65, 0.0) and (-8.0, 15.65), never the bell tower, a
     reserved tower or another mirror's, 22-33 units apart. Cost if wrong: a tower in a beam's blind spot; move the point.
215. **The glass:** 90 hp held by the director. Guarded, a blow shakes the tower; unguarded, it strikes the glass and scorches the
     tower, whose own health never moves tonight. Cost if wrong: too quick; MIRROR_HP up to 135.
216. **The mirrors go up on the chain:** 0:50 / 1:55 / 3:00, or 35 s after the one before is gone for good. A mirror does not
     exist before its time. Cost if wrong: CHAIN and STEP_AT[0] are the first knobs.
217. **The Anchors half:** shattered, a mirror is gone for good after 20 s unless hung again. Two wrights come out at the
     shattering, and 10 s of one wright's work rehangs it. Broken Lanterns' rule, rebuilt here; `BrokenLanternsDirector` is
     untouched. Cost if wrong: the drain reads as a wait; DRAIN down to 15.
218. **The parties:** three watchmen per mirror along the tower's town-side face, 2.4 apart, guard reach 2.0 of the footprint;
     return 20, relief 30; none after a mirror is gone. Cost if wrong: PARTY is a knob (2-3).
219. **The light:** both beams lit from 0:00. While a mirror stands, every heard cast draws the nearest beam, which holds 8 s.
     Whisper is unheard; a Wisp is a decoy. Cost if wrong: with HOLD too long the god cannot work one tower; HOLD down to 5.
220. **Seen casts:** a cast aimed inside a lit pool adds 20, judged as it is made. Deaths are judged by witnesses only. Cost if
     wrong: casting feels punished by chance; the light is drawn, so the hint carries it.
221. **The Eye opens:** all three mirrors standing at once for 30 s loses ("THE EYE OPENS"). Doing nothing loses at 3:30. Cost
     if wrong: EYE_OPENS is a knob (20-30).
222. **Exodus, the code:** `ExodusDirector extends EscortDirector` on the Charge record (§6.1), twelve charges. Cost if wrong:
     Exodus forks the escort code.
223. **Twelve believers, ten to save:** three households of four. Lost at once when those out plus those left fall below ten
     ("TOO FEW ARE LEFT"). Cost if wrong: two to spare is too strict; a thirteenth believer.
224. **The households on the chain:** indoors in stone-tonight houses with quiet doors; out at 0:15 / 1:45 / 3:15, or 25 s after
     the one before is done. Cost if wrong: CHAIN (20-30) is the first knob.
225. **The lamp:** a household follows its lamp-bearer in file (0.9 apart, within 4); the lamp passes on when he is seized, dies
     or gets out. Cost if wrong: files snag on corners; FOLLOW_GAP and FOLLOW_REACH are knobs.
226. **The watchers:** lay watchmen, as The Prisoner's: two patrols of two, two at each gate 2.4 apart, and two searchers per
     household 30 s after it comes out. A seizure marches the believer to the Temple's door. Cost if wrong: too easy with whispers;
     a third patrol.
227. **No guard change in Exodus** (`watch_changes` false). The gates' watch is worked: return 20, relief 30 from the Temple,
     at most six. Cost if wrong: a gate too easily held open; RELIEF_AFTER down to 20.
228. **The gates shut one by one:** the postern at 2:30, the Side Gate at 3:45, the Main Gate at 5:00. A shut gate is no way out;
     the last shutting with fewer than ten out loses. Cost if wrong: a slow household strands; SHUT_AT is a knob.
229. **Their pace and roads:** 0.45 of a citizen's, on roads of about 15, 15 and 11 units. Cost if wrong: BELIEVER_PACE and the
     houses are knobs.
230. **Exodus declares `shuts_gates`;** "Lead my brother out" and "Lead my family out" clash with it. Cost if wrong: two fewer
     wishes on its night (sixteen still eligible).
231. **The Heart of Faith, the code:** `HeartOfFaithDirector extends RazeDirector` for stage one; stage two is its own;
     `AssassinateDirector` is untouched. Cost if wrong: Odran's walk duplicates a little of the Assassinate round.
232. **The flame's two targets:** the oil-house (the dwelling nearest (-3.5, -9.5); 50 hp; 12 s alight) then the Temple (200 hp;
     20 s alight), in use at 0:45 / 1:50 or 45 s after. Staged, not sealed: a fall ahead counts at its time. Both in `hands_off`.
     Cost if wrong: a skilled clear about 170 s; STAGE_AT[0] up to 60.
233. **Lantern Knights:** two standing per target from the start and two coming out of its door at its time, 2.4 apart. On guard
     they seal it; reliefs come from the Citadel's gate after 30 s, at most four. Cost if wrong: ARRIVING is a knob (1-3).
234. **The blessing:** the flame still burning at 5:00 loses. It is a timeline event guarded by the flame, setting the director's
     `lost_reason()`, not an `EventObjective` (M4 ruling 159: a dropped event reads as come). The HUD row carries its countdown.
     Cost: none.
235. **Odran:** the cleric nearest the Citadel's gate, inside the Citadel. His litter's four bearers come out when the flame goes
     out, and he comes out 30 s later. Cost if wrong: ODRAN_CHAIN is a knob (20-30).
236. **The litter:** Odran rides hidden and untouchable while two or more bearers live (Pip's ride in M5's cart). Below two it
     falls and he walks on, with one last guard 2.5 behind when he set out on foot. Cost if wrong: if a hidden rider cannot be
     carried, he walks inside his bearers' square from the start, warded by nothing but distance.
237. **The rekindling:** 20 s at the Temple's steps, started again by a whisper, Discord or a fright. Finished, it loses. Cost if
     wrong: RITE is a knob (15-30).
238. **Halcyon looks harder:** after the flame is out, a seen death adds 20. Cost if wrong: too harsh; FURY back to 10.
239. **Card types:** The Lantern's Eye is Anchors, Exodus Protect, The Heart of Faith Kill (its win is Odran's death). Cost if
     wrong: a card word.
240. **The Heart declares `burns_temple`** (M5's tag); the pyre wish clashes. Cost: none.
241. **The Charge record (carried item 1):** the per-charge fields in a record, today's fields as accessors over `charges[0]`,
     gated on The Lost Lamb's and The Prisoner's twelve before Exodus is built. M4 Decision 67 is reworded in the plan. Cost if
     wrong: a reference moves; the task stops and reports.
242. **`EscortObjective` gains `need`** (default 1, today's). A many-charge night fails only through `lost_reason()`. Cost:
     none.
243. **The Hunt hooks (carried item 2):** `_unguarded_blow()` (default today's, or the borrowed filter's) and `shield_hits`
     (false). The Eye skips reserved towers in its own choice. Cost if wrong: The Heretic Hunt's six move; the switch stays off.
244. **The Searchlight's hooks:** `hunt` (false) and `hold` (INF), proven by The Relic Run's six and The Vigil Flame's outcome and
     play line. Cost if wrong: a fork of `searchlight.gd` for the Eye.
245. **The keepout (carried item 3):** `Hud.stack_rect()` handed to `tag_layout()` and `frame_point()`, defaults empty. Edge tags
     under the stack arrow to its border; the stack counts as a placed label; no camera moves and no reference moves. Cost if
     wrong: a tag under the stack loses its label; its arrow and diamond still show.
246. **The kit's real depth:** `Kit.STACK` (240×165) for M6's checks; the old `DEAD` checks are unchanged. Cost: none.
247. **Camera spots:** The Lantern's Eye (0.0, -6.0), Exodus (-7.0, 9.0), The Heart of Faith (-6.0, -4.0), each checked against
     `Kit.STACK`. Cost if wrong: a photo-round move, which moves that scenario's six references once.
248. **The new wishes:** "Strike down the zealot, unseen" (Punish, 15, `PunishWish` with clergy and unseen) and "Turn the doubting
     priest" (Faith, 15, `NeighboursWish` with count 1 and clergy), both `min_tier` 5. The pool grows from 16 to 18; Tier 1-4 draws
     do not change. Cost: none.
249. **Tier 5 draws change:** any test pinning one is re-pinned and named in the plan. Cost: none.
250. **Board order:** the ★ missions first, then #23, #24 and #25. Cost: none.
251. **The last tier's line** counts its five ("Ascendance 2 / 5 cleared"). With all 25 cleared it reads "...: every tier is
     cleared". Cost if wrong: a FLOW string to change.
252. **The board complete:** the header gains "All 25 cleared" (`DescendState.all_cleared()`); nothing else changes. Cost if
     wrong: the user may want a closing screen; that is story, out of v0.11's scope (spec §10).
253. **Behaviour scenarios** `eye`, `exodus` and `heart` run the `MissionBook` versions; `eye` and `heart` turn hit-stop off.
     Cost: none.
254. **Results titles:** THE LANTERN'S EYE IS BLIND, THE EYE OPENS, THE FAITHFUL ARE OUT, TOO FEW ARE LEFT, THE GATES ARE SHUT, THE
     HEART OF FAITH IS BROKEN, THE GREAT FLAME IS BLESSED and THE FLAME IS KINDLED ANEW, under the mission's own keys (`eye_blind`,
     `eye_open`, `exodus`, `exodus_few`, `gates_shut`, `heart`, `blessed`, `kindled`). The Gaze's is the family's `gaze`. Cost:
     none.
255. **`StagesObjective`:** one new generic objective (label and win reason in `_init()`, the director's `stages_done()`,
     `lost_reason()` and `hud_line()`). Cost if wrong: none; it is a dozen lines.
256. **`RazeDirector._spoil_for()`** (default `spoil_seconds`), proven by Spoiled Harvest's, The Crown's Bread's and The Armoury's
     references. Cost: none.
257. **FLOW:** Ascendance's five on the board and results steps, and one added step (The Lantern's Eye ascended): 113 to 114. The
     end state is a unit test. Cost: none.
258. **The bench:** The Lantern's Eye's board version against Last Judgement's. The release bench is one mission per tier against
     `kak-v011-m5` and v0.10's tag, on a quiet machine. Cost: none.
259. **No relays in M6;** no `TempleReport`. Cost: none.
260. **No new TownLayout reads in shared code:** the wishes read roles and kinds; the new directors read the layout in
     `src/game/mission/` only. Cost: none.
261. **The scripted gate and policies:** M2-M5's gate. Each policy works its opposition as a player would, and each states its
     Gaze. The Eye's never casts within POOL_R + 0.5 of a lit pool. Cost: none.
262. **v0.11's close:** the M6 section and a short whole-version summary in the release notes, and the README's `--show` list.
     Cost: none.
