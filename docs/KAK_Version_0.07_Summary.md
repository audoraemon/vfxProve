# Kingdoms Amid Kataclysm (KAK) — Version 0.07 Summary

*Engine: Godot 4.7.2 (gl_compatibility, 640×360 pixel art, iso view). Branch `feat/vfx-proof`, tag `kak-v0.07`. v0.07 is the soldiers release. The town's 100 soldiers used to rally round the Citadel and wait to be hit; now most of them have a role:
- **marshals** speed and steady the evacuation;
- **escorts** guard the responders and take over their duties;
- **rescue squads** dig survivors out of collapsed shelters and fight fires.

It builds on v0.06's 17 powers in four kinds and v0.05's civilization responses: a bell network, a banishing rite, engineers and river boats, with a difficulty that decides how much of that the town has.*

## 1. Concept

You are an ancient god who **manifests over one walled medieval town, Aldermere**. You draft 4 of 17 powers and, before the manifestation ends, must **destroy the Royal Citadel and collapse City Stability** while keeping too many citizens from escaping.

**Design goals:**
- players replay the same town because they believe a better sequence of powers would level it faster or with less Divine Power;
- v0.05: a harder game through **organization, not hit points**. Every response the town mounts is readable and can be countered.
- v0.06: **more kinds of play than destruction.** Gather a crowd, wall off a gate, unsettle the responders, sow a plague.
- v0.07: **soldiers who matter.** They never fight the god, but they get the town out faster, keep its responders working and save the buried. Each role can be countered.

## 2. Game flow

**Title → Prepare (draft and difficulty) → Mission → Results**, with **Pause** over the mission.

| Screen | What it does |
|---|---|
| Title | Game name over a slowly panning town; Play, VFX Sandbox, Quit |
| Prepare | Briefing, the draft and the **difficulty selector** with the town's **Defense Profile** along the bottom. The draft (v0.06) sorts the 17 powers into **tabs by kind** (Cataclysm, Control, Quiet, Curse); a **loadout bar** holds the four picks in slot order, whichever tab they came from, with MANIFEST. Hovering a power shows its card on the left: preview clip, cost, kind, what it does |
| Mission | 2 s intro (camera sweeps to the Citadel, "MANIFEST" banner), then the 6:00 clock runs |
| Pause (Esc) | Resume, Restart, Change powers, Title |
| Results | Victory/defeat, stat lines with points, score, rank S–D, "NEW BEST!" (saved) |

## 3. Controls

| Action | Input |
|---|---|
| Pan | WASD / arrows, or middle-mouse drag |
| Zoom | Mouse wheel (0.5–1.6) |
| Pick power | Keys 1–4 or click the slot |
| Cast | Click (point powers) or press-drag-release (line/lane powers) |
| Cancel / unfocus / pause | Esc |
| Restart | R |
| Difficulty (Prepare) | Left/Right, or the arrows |
| Draft tab (Prepare) | Click a tab, or Tab / Shift-Tab; click a loadout slot to give its pick back |
| FPS meter | F3 |
| Behaviour overlay | F4 (intents, alarm stage and timeline, gate queues, the citizen under the mouse; v0.05 adds the tier, the bell, the rite, each engineer team's job with lines to its site, and the boats; v0.07 adds the marshals' speed at each way out, the escorts on each duty, and the rescue squads with the trapped, saved and lost) |

## 4. Rules and resources

- **Divine Power (DP):** a 100-point bar regenerating 0.5 a second. Each power costs DP and has a cooldown.
- **One power at a time:** while a power is still playing, no other can be cast (the slots show its seconds left in gold). A power that lingers (v0.06: the wisp, the thorns) locks only while it is cast.
- **The Temple (cathedral):** destroying it restores 70% of the DP bar, once.
- **City Stability:** five parts (Population, Infrastructure, Leadership, Military, Resources).
- **Citadel:** fortified, losing at most 25% of its health a second; every 10% lost collapses one of its towers or walls.
- **Losing:** 50 citizens escaping, or the manifestation clock running out — and in v0.05 the clergy can shorten that clock (§7.3).
- **Score and ranks** as in v0.04 (win 5000; 25 a second left; 40 a building; 10 a citizen; 25 a soldier; 300 a chain; 10 a DP left; S ≥ 19,200 … D).

## 5. The 17 powers, by kind

**Cataclysm** (destruction):

| Power | DP | Cooldown | Aim | Effect |
|---|---|---|---|---|
| Heaven Splitter | 10 | 20 s | drag | Line strike with 8 fissures |
| Tornado Tempest | 15 | 30 s | click | 10 s vortex that softly locks onto buildings |
| Dragonfire Parade | 18 | 35 s | click | Cone of dragonfire |
| Tsunami Breaker | 20 | 40 s | drag | Moving wall of water |
| Gravity Distortion | 20 | 45 s | click | Pull field |
| Walking Laser Grid | 22 | 45 s | drag | Moving laser lane |
| Orbital Strike | 22 | 45 s | click | Random bombardment |
| Cinderfall Barrage | 25 | 50 s | click | Volcano and stone rain |
| Judgement of the Ancients | 30 | 60 s | click | 8 punches and a slam |
| Glacial Cataclysm | 30 | 60 s | click | Burst, freeze, ice |
| Nuclear Nova | 40 | 120 s | click | Huge blast circle |

**Control** (v0.06):

| Power | DP | Cooldown | Aim | Effect |
|---|---|---|---|---|
| **Will-o'-Wisp** | 10 | 25 s | click | A pale light hovers for 12 s. Up to 25 citizens within 6 who are going about their day, watching, recovering or regrouping walk to it and stand staring, then go back to their day. No alarm. Soldiers and people on duty ignore it |
| **Thornwall** | 14 | 30 s | drag | Five bramble segments, 3 units long, grow along the drag and block the street for 25 s, then wither. Anyone standing there is shoved clear. +1 alarm, and onlookers stop to stare. Engineers can cut it down (5 s a segment); it burns |

**Quiet** (no danger the town can see):

| Power | DP | Cooldown | Aim | Effect |
|---|---|---|---|---|
| Silent Doom | 8 | 15 s | click | Up to 3 people within 0.8 die under a dark wisp. Unseen, the town never knows; a witness within 2 panics and the deaths raise the alarm |
| **Discord** (v0.06) | 10 | 20 s | click | Every citizen within 1.2 forgets what they were doing for 15 s and ambles under a violet swirl. Clergy leave the rite, the bellkeeper drops the climb, engineers down tools, fire crews leave, evacuees step out of the queue. Then they pick up again. Soldiers are unaffected |
| Blight | 12 | 25 s | click | Rots the nearest useful structure within 1.0: a well or fountain gives no water, the bell cracks, a gate jams for 30 s, the dock stops the boats, the cathedral holds no rite. +1 alarm |

**Curse** (v0.06):

| Power | DP | Cooldown | Aim | Effect |
|---|---|---|---|---|
| **Pestilence** | 16 | 40 s | click | Up to 3 citizens within 1.2 catch the plague. The sick slow to 70%, green and coughing, and die 30 s later. Every 3 s each passes it to each healthy citizen within 1.0 with a 30% chance, up to 60 sick. It spreads in shelters too. Soldiers are immune. The cast is quiet; the deaths are not |

**Aim previews:** every power shows what it would hit — rings on the people the Wisp would draw, Discord would take or Pestilence would infect; the thorn line; Blight's target outline; Silent Doom's victims. The default loadout is Heaven Splitter, Tsunami Breaker, Cinderfall Barrage and Nuclear Nova.

## 6. Difficulty and the Defense Profile

Chosen on the Prepare screen and saved. Harder tiers add no hit points: the town organizes better.

| Tier | The town's responses |
|---|---|
| Unprepared | Fire brigade (2 per fire, from City Emergency). No bellkeeper: the Bell Tower is scenery. The postern is barred |
| **Organized** (default) | Bell Network (8 s climb), fire brigade (4 per fire, from Local Emergency) |
| Prepared | Organized + engineers (2 teams) + river boats and the postern + the Banishing Rite (45 s) |
| God-Resistant | Prepared, faster: bell 5 s, fire brigade 5, engineers 3 teams, rite 35 s |

**Soldiers' roles (v0.07)**, in every tier, scaled. The Defense Profile shows them as "Marshals xN, Escorts xN, Rescue xN"; its three columns are now sized to their text.

| Tier | Marshals per way out | Escorts per duty | Rescue squads (of 3) |
|---|---|---|---|
| Unprepared | 2 | 1 | 2 |
| Organized | 3 | 1 | 3 |
| Prepared | 4 | 2 | 4 |
| God-Resistant | 5 | 2 | 5 |

## 7. The town's responses

### 7.1 Bell Tower (Bell Network)
- A stone tower with an open belfry east of the market. Its **bellkeeper** (in a navy coat with a brass badge) works at its foot.
- At the first Local Emergency the bellkeeper runs to the tower and climbs it for 8 s (a gold bar over the roof). The ring adds 20 alarm, tells every citizen, and brings City Emergency at alarm 25 (not 35) and the evacuation at 60 (not 90).
- **Until the bell has rung, alarm from events counts half** (collapses, deaths, Citadel hits): a town kept from its bell mobilizes slower.
- **Counters:** kill the bellkeeper before it is called (it is not replaced), Blight the tower (the bell cracks), or destroy it. A frightened bellkeeper drops the climb and retries 10 s later. **v0.07:** a silenced bell sends its living keeper off duty: home to wait with the family, or to the gates once the town evacuates.
- **v0.07:** once the keeper is called, its escort guards it. Kill the keeper then and an escort takes the rope ("A SOLDIER TAKES THE BELL ROPE") and climbs it again, half as slow again (12 s at Prepared). The bell gets the tier's escorts per duty and no more (1, or 2 at Prepared and up): kill each one who takes the rope and the bell is silenced.

### 7.2 Fire brigade
- Up to 4 calm citizens per fire (5 at God-Resistant; 2 when Unprepared), from Local Emergency (City Emergency when Unprepared), fetch water from the nearest fountain or well and douse it. Blighted or destroyed water points give none.

### 7.3 Banishing Rite (Prepared and up)
- At City Emergency up to 4 clergy (in cream robes with gold stoles) gather on the cathedral's steps. Once 3 stand in the ring they chant for 45 s (35 s at God-Resistant): a gold ring fills on the ground, halos over the clergy, and a bar under the clock.
- **Completed, the rite takes 40 s off the manifestation**, once per mission.
- **Broken** — progress lost — when fewer than 2 remain in the ring (killed or frightened away) or the cathedral drops under half health; the clergy regather after 30 s. **Ended for good** by a fallen or blighted cathedral, or fewer than 3 clergy alive (the town starts with about 9).

### 7.4 Engineers (Prepared and up)
- Two teams of two (three at God-Resistant) from the workshop, in leather caps and aprons with hammers, turn out at City Emergency.
- Each team takes the job scoring highest on **priority less 2 for every unit of travel** — Citadel 100, routes (gates, bridge, dock) 80, Bell Tower and cathedral 60, houses 20 — never one another team holds, rethinking every 2 s.
- With both at the site they heal 5% of a building's health a second (sparks and a green bar), or rebuild a fallen gate, the bridge or the dock in 20 s (a steel bar), exactly as it stood.
- **The Citadel mends only back to its last collapse:** fallen towers and walls stay down.
- During the evacuation the gates are left alone (a fallen gate lets the crowd out faster).
- **v0.06:** they also cut down a Thornwall (a Clear job, priority 70, 5 s a segment).
- A team that loses a member is lost; the workshop sends another 60 s later while it stands. **v0.07:** unless one of its escorts can take the fallen engineer's place.

### 7.5 River boats and the postern (Prepared and up)
- The dock is a pier on the north bank below the **postern**, a narrow door in the south wall at the end of the west street (one person every 3 s; barred in towns without boats).
- From the Evacuation stage the ship moored there ferries people away: they wait behind the pier, step aboard one by one, and escape when it sails full (6) — or 4 s after the first with nobody left waiting. It is back 12 s later.
- Evacuees score the dock as a third way out, counting the postern's queue and the crowd at the dock.
- **Counters:** destroy the dock (the boats stop until the engineers rebuild it) or Blight it (they stop for good). Destroying the bridge no longer seals the south.

### 7.6 Soldiers (v0.07)
Soldiers never hurt the god. Each takes a role from where it is posted at the start: marshals and rescue squads up to the tier's counts, and every patroller an escort. The rest keep v0.06's ways: drill, guard, and rally at the Citadel at City Emergency. Escorts with nothing to guard keep patrolling (all of them at Unprepared, which has no bellkeeper, rite or engineers).

| Posted | Role | Look |
|---|---|---|
| Walls and gates (30) | **Marshals** | Red tabard |
| Street patrols (20) | **Escorts** | White tabard |
| Barracks yard (30) | **Rescue squads** | A shovel instead of the spear |
| The Citadel (20) | — (they rally there) | Blue tabard |

Soldiers sent to a role **run** there.

- **Marshals.**
  - At the Evacuation stage they leave the walls for the ways out ("THE SOLDIERS TAKE THE GATES"). Each way out takes the nearest marshals: the Main Gate, the Side Gate and, with boats, the postern and the dock. They stand either side of the crowd's head.
  - Each living marshal within 2 of a way out makes it 15% faster. Four at the Main Gate let one through every 1.25 s instead of 2. The boats board faster too.
  - A Discord-confused evacuee near a marshal comes to within 3 s.
  - **Counter:** kill or scatter them, and the way out slows again.
- **Escorts.**
  - They join each responder on duty and keep close: the bellkeeper while the bell is called, climbed or waited for; the clergy's ring while it gathers, chants or cools down (by its centre); and each engineer team while the engineers are out.
  - Silent Doom near them is seen (soldiers count as witnesses).
  - A guarded bellkeeper or engineer confused by Discord near its escort comes to within 3 s. A confused cleric leaves the ring at once, as in v0.06, so Discord still breaks the rite.
  - **The bell:** a keeper killed before the bell has rung is replaced by an escort (the climb takes 1.5 times as long, once).
  - **Each duty gets the tier's escorts per duty, once**, for the duty's whole life (a rite that regathers keeps what it has). A guard who dies or takes over is not replaced, so the takeovers run out.
  - After a takeover the banners read "A SOLDIER TAKES THE BELL ROPE" and "A SOLDIER CLIMBS THE TOWER".
  - **Engineers:** a fallen engineer is replaced by one of the team's escorts, so the team is not lost.
  - **The rite:** it cannot be taken over, because soldiers do not chant.
  - When the duty ends they go back to their patrols. The patrols' investigations leave a guarding escort alone.
  - **Counter:** kill the escorts first, which is loud.
- **Rescue squads.**
  - **The trapped:** a shelter that collapses on its people now traps 60% of them under the rubble instead of killing them all. The trapped are hidden with 45 s to live, marked by a dust plume and a count.
  - **Digging:** the nearest free squad of three runs to the rubble and digs one out every 3 s. The first rescue shows "SURVIVORS DUG FROM THE RUBBLE".
  - **The freed** come out frightened, or head for the gates if the town is evacuating.
  - **The untended** die there.
  - A plague caught before the collapse waits under the rubble.
  - **Fires:** a squad with nothing to dig turns out to the nearest fire within 10, from any alarm stage until the evacuation. The squad counts towards the fire's crew, so fewer citizens turn out near the barracks. At Unprepared the squads reach fires before the brigade is called.
  - **In the counts:** the trapped are alive. They count as citizens in the HUD and the results until they die.
  - **Counter:** kill or scatter the squad, or bring down several shelters at once. One squad digs at each site, and they are few.

## 8. The town of Aldermere

- **Layout:** walls with towers; the Main Gate (south, over the river bridge), the Side Gate (east road) and the postern (south, to the dock).
- **Landmarks:** the Royal Citadel (9 parts), the cathedral (the Temple), the Bell Tower, the barracks and its yard, a workshop, a smithy, 3 taverns, a carpenter's yard, the market square with a fountain, a second fountain plaza, 3 wells.
- **Density:** 81 houses, 30 market stalls, street props, trees, gardens, paved plazas.
- **Countryside:** the river and its west branch, the bridge, the dock and ship, farms and fields, a windmill and a watermill, pastures, a forest ring.
- **Look and sound:** warm evening light, procedural pixel art, moving water, mills, trees, awnings, banners, torches; synthesized effects, crowd voices and music that follows the city's fall.

## 9. People

- **220 citizens with roles** (Resident, Caregiver, Merchant, Craft Worker, Farmer, Laborer, Clergy; v0.05 adds the Bellkeeper and the Engineers), each with a home, a workplace and leisure spots, living a daily routine.
- **Local awareness** of every danger by its radius, sight and sound; fright that spreads; shelter in sturdy buildings; households that leave together.
- **Staged alarm** (rises only):

  | Stage | Reached when | What happens |
  |---|---|---|
  | Normal | — | Routines as usual |
  | Concern | Any danger | People nearby look or flee locally |
  | Local Emergency | 4 incidents in one district | Two patrol soldiers investigate (not escorts on a duty); the bellkeeper is called, with its escorts |
  | City Emergency | Alarm 35 (25 after the bell), or 2 districts in emergency | Soldiers without a role rally at the Citadel; the market closes; 30% of citizens regroup at home; the clergy gather; the engineers turn out (each with escorts) |
  | Evacuation | 15 s after City Emergency, then alarm 60 with the bell or 90 without | Citizens make for the gates, the postern and the boats; marshals take the ways out |
  | Collapse | The Citadel falls, or stability drops to 25% | Route choices grow erratic |

- **People on duty** — the bellkeeper, the clergy at the rite, the engineers — stand at their posts, keep to them through the evacuation, and go on (home, or to the gates) when their duty ends.
- **New states (v0.06):** drawn by a wisp (watching, with a walk first), confused by Discord (wandering, then resuming), and sick with the plague (slowed, then dying).
- **Gate routing:** evacuees score each way out by route length, the queue at its gate (only while they are inside the walls) and the danger they know of. **100 soldiers** drill, guard, patrol and investigate; in v0.07 most take a role (§7.6), and only the rest rally.

## 10. Tools and dev features

- **Scripted runs:** `--mission-test` (now with `--difficulty=`), `--crowd-test`, `--flow-test`, `--bench`; `crowd_check.gd`; `state_digest.gd`.
- **Behaviour scenarios** (`tools/dev/behaviour_check.gd`, seeded, deterministic checksums):
  - calm, strike, escalate, gates, fire;
  - v0.05: bell (`--kill-keeper`), rite (`--interrupt`), engineers, boats (`--cut-bridge`), quiet, opening (`--quiet`), siege (with `--difficulty=`);
  - v0.06: **powers** (`--case=` plague/combo, wall/nowall, discord/rite: each new power against doing without) and **clip** (records a power's draft preview in the real town);
  - v0.07: **soldiers** (`--case=` marshals/nomarshals, escort/noescort, rescue/norescue: each role against doing without).
- **Profilers:** `profile_view.gd`, `profile_wear.gd`.
- **Art:** `tools/dev/make_power_icons.py` paints the procedural icons (Silent Doom, Blight, Will-o'-Wisp, Thornwall, Discord, Pestilence). The sandbox records the cataclysm powers' preview clips (`--capture-clip`); the town records the others (`behaviour_check --scenario=clip`).
- **Tests:** 1035 automated checks (`tools/test.sh`).

## 11. The soldiers, measured (v0.07)

With the `soldiers` scenario: Prepared, seed 7, each role against the same soldiers without it.

| Case | Without the role | With it |
|---|---|---|
| **Marshals:** an evacuation called at 20 s, escapes at 60 s | 33 escaped (south 15, east 12, boat 6); queues at the Main and Side Gates 30 / 20 | **44 escaped** (south 20, east 18, boat 6); queues 20 / 10 |
| **Escorts:** the bellkeeper killed 3 s into its climb | Silenced; the bell never rings | An escort 0.5 away takes the rope; **the bell rings at ~36 s** after a 12 s climb |
| **Rescue squads:** 20 sheltering in the cathedral when it falls | 11 crushed, 9 trapped, **all 9 lost** at 65 s | 11 crushed, 9 trapped, **all 9 dug out** (the first at ~40 s, the last at ~65 s) |

**The tiers under one siege** (`siege`, seed 7: eight loud casts from 20 s, with no answer to the escapes; the game is lost at 50 escaped). Times are from the first cast; deaths are people neither alive in town nor escaped at 120 s. Casts use a wall-clock hitstop, so repeated runs differ by a few people:

| Tier | v0.06: 50 escaped | v0.07: 50 escaped | v0.06: escaped / dead at 120 s | v0.07: escaped / dead at 120 s |
|---|---|---|---|---|
| Unprepared | ~90 s | ~88 s | 86 / 74 | 99 / 59 |
| Organized | ~76 s | ~75 s | 100 / 60 | 118 / 24 |
| Prepared | ~69 s | ~61 s | 114 / 25 | 144 / 22 |
| God-Resistant | ~70 s | ~59 s | 120 / 29 | 152 / 27 |

**What the runs show:**
- **The soldiers are a game changer for the town.**
  - **Escapes:** in the siege, Prepared and God-Resistant lose the player the game to escapes 8–11 s sooner. Unprepared and Organized barely change.
  - **Deaths:** fewer people die at every tier, and less than half as many at Organized (24 against 60), because squads dig out the buried and the crowd leaves before the next strike.
- **Marshals work at the road gates, not at the dock.** The boats carried 6 with or without them: the ferry's trips, not the boarding, limit the dock, and the postern's queue stays at 60–70 either way.
- **Rescue is tight against the 45 s.** One squad digs at a site at one person every 3 s, and the run from the yard takes most of the first 20 s. The cathedral's last survivor came out at about 65 s, the very end of the 45 s.
  - Larger collapses, or several at once, will lose people. That is the counter.
  - If the playtest wants rescue stronger: let a second squad join a big site, or shorten the dig.
- **Killing the bellkeeper early still silences the bell.** No escort is assigned until the keeper is called, so the v0.05 opening counter is kept.
- **Unprepared changes least** (2 marshals a way out, 2 squads, and escorts with nothing to guard). That is in keeping with a town that is not ready.
- **The soldiers are harder to break, and so is the win.** A win needs City Stability broken, and its Military part needs 80 soldiers dead. Only soldiers without a role rally at the Citadel: 70 at Unprepared, 65 at Organized, 52 at Prepared and 45 at God-Resistant (all 100 in v0.06). The rest are spread through the town.
  - Same siege, Prepared: the first Nova on the Citadel killed 42 soldiers (58 in v0.06), and by 120 s 74 were dead (89), leaving the Military part at 5% instead of broken.
  - **For the playtest:** this makes the win harder, as the soldiers were meant to. If it is too hard, make only the escorts a tier can use (1 at Organized, 8 at Prepared, 10 at God-Resistant) and let the other patrollers rally.

### From v0.06: the new powers

With the `powers` scenario: Prepared, seed 7, each power against doing without.

| Case | Without | With |
|---|---|---|
| **Pestilence** on the market crowd at 26 s | — | 16 sick at 56 s; 22 dead at 96 s |
| **Will-o'-Wisp at 20 s, then Pestilence** on the gathered crowd | (Pestilence alone, above) | 20 sick at 36 s, 58 at 56 s; **76 dead at 96 s** |
| **Thornwall** across the Main Gate's mouth, 5 s into an evacuation | 40 escaped at 65 s (17 by the south road) | **28 escaped** (5 by the south road); the Main Gate's crowd drains to the Side Gate and the postern |
| **Discord** on the rite's ring 10 s into the chant | The rite completes at ~70 s; the clock reads 3:51 at 90 s | Broken at once; regathered at ~66 s; the clock reads 4:31 at 90 s (**40 s saved**) |
| **Will-o'-Wisp** in the market | — | 20 citizens gathered within 2.5 by 6.4 s; alarm 0 |

**What the runs show:**
- **Placement matters for Thornwall.** Dropped in the middle of a wide plaza, people simply walk round its ends and nothing changes. Across the gate's mouth, between the towers, it seals the gate.
- **The Wisp-then-Pestilence combo is very strong:** 76 deaths for 26 DP, quietly until the first deaths at about 56 s. It is a candidate for the playtest.
  - Options: lower the cap (now 60 sick) or the spread chance (now 0.3), or lengthen the life before death (now 30 s).
- **Pestilence's reach was widened while building it** (catch 1.2, spread 1.0, from 0.8 and 0.6). The real evacuation queue is sparse, and at the narrower reach it barely spread.

### From v0.05: tuning the responses

Measured with the seeded behaviour scenarios. **No numbers were retuned:** as in v0.04, the tiers wait for a playtest. These runs show what each response does and where it is weak.

**Stealth against loud** (`opening`, Organized). The same four loud casts from 30 s; the quiet run first kills the bellkeeper with Silent Doom and blights the Bell Tower and the Main Gate:

| Opening | Bell | Evacuation called | Escaped by 100 s |
|---|---|---|---|
| Loud | Rang | 48.8 s | 65 |
| Quiet first | Silenced | 63.6 s | 47 |

The quiet opening bought 15 s before the evacuation and 18 fewer escapes.

**The tiers under one siege** (`siege`). Eight loud casts from 20 s (Heaven Splitter in the west, Cinderfall, two Novas on the Citadel, Tsunami, more Heaven Splitters), with no answer to the escapes. Every tier ends lost to escapes:

| Tier | Evacuation | Escaped at 60 s | 50 escaped | Rite | Boats carried |
|---|---|---|---|---|---|
| Unprepared | ~38 s (alarm 90) | 22 | ~92 s | — | — |
| Organized | ~28 s (the bell rang) | 35 | ~75 s | — | — |
| Prepared | ~28 s | 43 | ~71 s | broken once (clergy scattered), done too late | 27 |
| God-Resistant | ~28 s | 40 | ~72 s | **done at ~40 s: the clock lost 40 s** | 30 |

**What the runs show (for the playtest):**
- **Each tier is harder:** Organized's bell brings the evacuation 10 s sooner than Unprepared; the postern and boats lose the game to escapes about 4 s sooner again.
- **God-Resistant is mostly Prepared plus a faster rite.** If it should feel clearly harder, candidates are a bigger boat load, a quicker postern, or more clergy.
- **The bellkeeper works at the tower's foot by the market.** A first strike on the market kills them, and then Organized plays like Unprepared. That is counterplay working, but it is easy to do by accident.
- **Engineers matter most against chip damage.** In a fire-heavy siege they stood idle:
  - the damaged houses were burning (left to the fire brigade, which stops at the evacuation);
  - the Nova's 25%-a-second bursts left the Citadel on its collapse marks, with nothing to mend.
  - Options: let engineers douse fires, mend burning buildings, or (at God-Resistant) rebuild a fallen Citadel part.
- **The rite completes only when undisturbed.** At 35 s it finished before the siege reached the steps; at 45 s a cast scattered the clergy first.

## 12. Performance

- **Market view, mission bench, alternating** (`--bench`, two sets of three):

  | Build | fps | Draw calls |
  |---|---|---|
  | `kak-v0.06` | 116.1 / 117.2 / 118.4 / 117.4 / 117.8 / 117.8 (mean 117.5) | 1052 |
  | v0.07 | 115.7 / 116.5 / 116.2 / 115.1 / 116.3 / 116.3 (mean 116.0) | 1052 |

  **−1.5 fps** (about 0.1 ms a frame), within the 5-fps budget.
  - The worst single frame of a run was higher in most v0.07 runs: about 15–16 ms against 12–13 ms.
  - The time it went to was not found. The managers and the squads' re-posting do no work while the town is calm. The crowd's own spikes appear in both builds, and the machine was busy with other programs.
  - Worth a profile in the next performance pass.
- The soldiers' managers think twice a second (escorts, rescue) or only from the evacuation (marshals).
- **From v0.06:** the new powers cost nothing while they are not cast. **The plague manager** looks for the newly sick twice a second rather than every frame. Its spread uses the field's radius query every 3 s.
- From v0.05: ~111 fps at Organized against 115.6 at v0.04-final, the Bell Tower's ~0.6 fps, and walkers no longer pinned on corners (~2.5 fps, a fix).

## 13. Not yet in (later)

World map, progression and upgrades, more maps, civilization ages, building materials, elemental combos, enemy heroes and defenses that fight back.

- **For the responses:** commanders, ward protection, a targetable ferry, barricades, a Citadel garrison, battle-priests, and per-tier tuning after playtests (for example the soldiers' counts, rescue speed, and marshals at the dock).
- **More abilities:** the rest of the v0.06 shortlist, after a playtest of the first four: Dread (herd a crowd), Mire (quicksand), Veil of Silence (a dome where nothing is seen), False Omen (a decoy incident), Gorgon's Gaze (statues that block paths) and Soul Harvest (deaths return DP).
