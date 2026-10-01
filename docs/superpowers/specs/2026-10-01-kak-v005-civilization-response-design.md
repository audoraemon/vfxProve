# KAK v0.05 — Civilization response — design and plan

**Source:** `E:\Document\PROJECT\KAK\KAK_v0_05_Civilization_Response_Design.docx`. **Baseline:** `kak-v0.04-final` (= `5082e49`).

**Goal:** a harder game through organization, not HP. Aldermere mobilizes responses as its alarm rises: a bell network, a banishing rite, a fire brigade, engineers and river boats. Each response is readable and can be countered, and two new quiet powers make a stealth opening real.

## Decisions (with the user, 2026-10-01)

| Topic | Decision |
|---|---|
| Stealth | Two new quiet powers: **Silent Doom** (silently kills one target, or up to 3 in a tiny radius) and **Blight** (quietly ruins a structure's function). |
| Alternate exit | River boats at the dock. |
| Bell | A new Bell Tower in town, with a bellkeeper. It replaces v0.04's cathedral bell. |
| Profiles | A difficulty chosen on the Prepare screen picks the fixed set of active responses, shown as the Defense Profile. |
| Rite | Costs 40 s of manifestation time on completion. Interruption resets its progress; the clergy can regather after a cooldown. |
| Engineers | Heal damaged standing structures (Citadel parts, cathedral, Bell Tower, houses) and rebuild destroyed gates, the bridge and the dock. Jobs are chosen by priority minus travel distance; priority runs Citadel > routes > Bell/Cathedral > houses. Two teams of two, repairing about 5% of a structure's hp a second. |
| Bell timing | At the first Local Emergency the bellkeeper climbs the tower (about 8 s, with progress shown). Ringing it adds 20 alarm, tells the whole town, and brings City Emergency and Evacuation sooner. |

## 1. Difficulty and the Defense Profile

| Tier | Responses |
|---|---|
| Unprepared | Fire brigade (basic: 2 per fire, from City Emergency). No bell (the tower stands unmanned). |
| Organized | Bell Network, Fire Brigade (4 per fire, from Local Emergency) |
| Prepared | Organized + Engineers + River Boats + Banishing Rite |
| God-Resistant | Prepared, faster: bell 5 s, rite 35 s, engineers 3 teams, fires 5 per fire |

- **Choosing it:** the Prepare screen gains a difficulty selector and a Defense Profile panel (the active responses, one line each).
- **Saving it:** the save remembers the last choice.
- **Default:** Organized.

## 2. Bell Tower (Bell Network)

- **The tower:** a new stone structure (`Structure.Kind.TOWER`-like art, tag `bell_tower`) near the market and the cathedral, with a bellkeeper (a citizen with the role Bellkeeper) posted at its foot.
- **Climbing:** at the first Local Emergency the bellkeeper climbs. It takes BELL_CLIMB (8 s) and shows a progress bar over the tower.
- **The ring:** alarm +20, and every citizen's awareness rises to EMERGENCY. City Emergency then needs alarm 25 (not 35), and the evacuation alarm 60 (not 75).
- **Stopping it:**
  - kill the bellkeeper (Silent Doom);
  - Blight the tower (the bell is cracked: it cannot ring, but the tower still stands);
  - destroy the tower (a building collapse, so the usual alarm).
  - A killed bellkeeper is not replaced. A frightened one abandons the climb and retries after 10 s.
- **Unprepared:** no bellkeeper; the tower is scenery.

## 3. Banishing Rite

- **When it starts:** at City Emergency or above, if the Rite is active, the cathedral stands (hp ≥ 50%, not blighted) and at least 3 clergy are alive.
- **Gathering:** the clergy walk to the cathedral steps. Once 3 have gathered, the rite runs for RITE_TIME (45 s; 35 s at God-Resistant).
- **What you see:**
  - a golden glow ring on the steps;
  - a HUD progress bar: "BANISHING RITE";
  - a banner when it starts.
- **Completion:** `Rules.time_left -= 40`, with a banner "THE CLERGY BANISH YOU — 40 s LOST".
- **Interruption:**
  - fewer than 2 clergy left in the ring (killed or frightened away), or the cathedral below 50%, resets the progress;
  - the clergy can regather after RITE_COOLDOWN (30 s);
  - a destroyed cathedral ends the rite for good.

## 4. Fire Brigade

- **Driven by the profile:** FireManager's crew size and starting stage come from the profile.
- **Blight:** a blighted fountain or well is not a water point (`Structure.blighted`).

## 5. Engineers (EngineerManager)

- **Teams:** ENGINEER_TEAMS (2) teams of 2 citizens with the role Engineer, based at the workshop. They are active from City Emergency.
- **Jobs:**
  - damaged standing structures (hp < 90%): Citadel parts, the cathedral, the Bell Tower and houses;
  - destroyed gates, the bridge and the dock, which are rebuilt: the structure is restored as it was, and the walk grid updates.
- **Choosing a job:** a team takes the job with the highest `PRIORITY[kind] − DISTANCE_WEIGHT × travel`. The weights are Citadel 100, routes 80, Bell and Cathedral 60, houses 20; DISTANCE_WEIGHT is 2 per unit. Two teams never take the same job.
- **Repairing:** 5% of max hp a second while both team members are at the site. A rebuild takes REBUILD (20 s).
- **Losses:** a team with a dead member is lost. A replacement comes from the workshop after 60 s, if the workshop stands.

## 6. River boats

- **The boat:** at the Evacuation stage (if River Boats is active and the dock stands, unblighted), the ship at the dock becomes the ferry.
- **The run:** it loads up to BOAT_LOAD (6) citizens over 4 s, departs (they escape), and returns after BOAT_TRIP (12 s).
- **Routing:** the dock is a third exit in EvacuationManager's scoring, with its congestion being those waiting at the dock.
- **Stopping it:** destroy the dock, or Blight it; either ends the service. The boat itself is decor and is not targetable in the first pass.

## 7. Quiet powers

| Power | DP | Cooldown | Aim | Effect |
|---|---|---|---|---|
| Silent Doom | 8 | 15 s | click | Kills the nearest person within 0.8 of the aim point, or up to 3 within 0.8. No threat is registered and no alarm is raised, unless a witness is within 2 units of a victim: then the witness panics (a small local threat). |
| Blight | 12 | 25 s | click | The nearest structure within 1.0 becomes blighted; its function is off (see below). Adds 1 alarm. |

- **What Blight turns off:**
  - a well or fountain: no longer a water point;
  - the Bell Tower: cannot ring;
  - a gate: jammed, closed to escapes for 30 s;
  - the dock: no boats;
  - the cathedral: no rite.
- **Look:** both have subtle VFX (a dark wisp; a grey-green rot tint on the structure). Their icons are procedural or from PixelLab (minimal).
- **The draft:** 13 powers.

## 8. Debug overlay (F4)

The overlay gains:
- the active responses;
- the bell's state and progress;
- the rite's state and progress;
- the engineers' jobs, with lines to their sites;
- the boat's state and load.

## 9. Measures

- **Tests** per system.
- **`behaviour_check.gd` scenarios:**
  - bell: a quiet first minute, then a strike, with the bellkeeper killed and with it left alive;
  - rite: completed, and interrupted;
  - engineers: the Citadel damaged, then repaired;
  - boats: evacuation spread across the gates and the dock;
  - stealth versus loud: the alarm timeline for each opening.
- **Benchmark** against `kak-v0.04-final`: a loss of at most 5 fps.

## Milestones (each tagged)

1. **M1 — Profile:** ResponseManager, the difficulty tiers, the Prepare screen's selector and profile panel, and the save.
2. **M2 — Bell Tower:** the tower's layout and art, the bellkeeper, the climb, the ring, and interruption.
3. **M3 — Banishing Rite:** gathering, progress and its UI, the time penalty, and interruption.
4. **M4 — Engineers:** jobs, priority scoring, repair and rebuild.
5. **M5 — River boats:** the ferry cycle, and the dock as an exit in routing.
6. **M6 — Quiet powers:** Silent Doom and Blight, the blighted state, and their icons and VFX.
7. **M7 — Tuning:** the overlay, the scenarios, the benchmark, the v0.05 summary, and the tag `kak-v0.05`.

---

## Changes made while executing

### M1
- **No separate ResponseManager.** The difficulty is a `ResponseProfile` (`src/game/response_profile.gd`) that the crowd carries. Each manager reads what it needs (FireManager: `fire_crew` and `fire_from`; the bell: `bell`), which was lighter than a manager in between.
- **The Prepare screen's bottom strip:**
  - left: the difficulty selector `< ORGANIZED >` (arrows clickable; Left/Right keys too);
  - right: the Defense Profile label, the tier's blurb, and its responses in three columns.
  - The left panel and the card grid were already full at 640×360.
- **The difficulty is saved** (`SaveFile.difficulty`) and handed to the mission by Game. A standalone mission reads `-- --difficulty=<name>`.
- **Until M2** the bell is still v0.04's cathedral bell. Unprepared has none.
- **The fire brigade turns out from the profile's stage:** Local Emergency for Organized and up, City Emergency for Unprepared. v0.04 turned out at any stage, so a lone house fire at Concern now burns unfought.
- **F4 panel:** it shows the tier and its responses.
- **Mission test:** Unprepared 179 alive / 3 escaped; Organized 183 / 2; God-Resistant 181 / 3. The tiers' big responses arrive in M2–M5.
- **Tests:** 844 checks.

### M2
- **The tower:** `TownLayout.BELL_TOWER` at (7.0, 0.8), 1.1 units square and 60 px tall, east of the market. It is a KEEP tagged `bell_tower`, drawn with `StoneArt._draw_belfry()`: a dark inside, stone piers at three corners (a front pier would sit straight in front of the bell in this view), a bronze bell hung low enough to show under the roof's front eave, and a slate pyramid roof. Its role is `tower`: 3 DP, and it counts as a building.
- **The bellkeeper:** the resident living nearest the tower (Role.BELLKEEPER). They work at the tower's foot, on its west side facing the market; the north side was a pocket the path could not reach. A test checks the foot is reachable from the market. On duty they run.
- **The v0.04 clergy/cathedral bell is gone.** BellNetwork runs the bell: IDLE → CALLED at the first Local Emergency → CLIMBING (8 s, a gold bar over the roof) → RUNG. A frightened keeper goes to WAITING and retries in 10 s; a dead keeper or a fallen or blighted tower means SILENCED. There are banners for each.
- **New rule — the unwarned half-rate.** Until the bell has rung, alarm from events (collapses, deaths, Citadel hits) counts half (`Crowd.UNWARNED_ALARM` 0.5), following the source doc's "the global Alarm rises faster after the bell". Without it, one Heaven Splitter into the dense west quarter reached alarm ~90 on its own, and silencing the bell bought nothing.
- **Thresholds after the bell:** City Emergency at 25; evacuation at 60.
- **Bell scenario** (Heaven Splitter in the west, seed 7):
  - keeper alive: the bell rings at about 14 s (alarm 47 → 67), and the town evacuates by 20 s;
  - keeper killed first: the bell is silenced, the alarm holds at 49 (City Emergency), and there is no evacuation within 30 s.
- **Walking fixes found through the bell:**
  - A walker blocked by a building's margin now slides the full step along the axis it leans (`DummyEnemy._move`). A walker already inside a margin may step out.
  - Paths' diagonals clip corner margins (the walk grid checks cell centres), and one keeper stood pinned at a stall corner for good.
  - Seven seeds now all ring.
- **`behaviour_check.gd` was never seeded.** It now restarts the mission on `--seed` (default 7). Checksums recorded before this were from clock seeds and do not repeat.
- **Checksums:** crowd_check −549829194.
- **Mission test:** `citizens=164 escaped=1 stability=65% citadel=50%`.
- **Market bench, alternating:** M1 93.8 / 92.7 / 92.2 fps, M2 91.6 / 92.9 / 92.8 fps.
- **Tests:** 853 checks.

### M3
- **BanishingRite** (`src/game/crowd/banishing_rite.gd`): made by `Crowd.spawn()` and stepped in `advance()`. Its states are IDLE, GATHERING, CHANTING, COOLDOWN, DONE and ENDED. Only a profile with `rite` (Prepared and up) holds one.
- **Gathering:** at City Emergency (after the market closes) up to 4 clergy run to the steps, nearest first. They are drawn from those calm, recovering, watching or regrouping, and take a new Person mind duty (`Person.go_duty()`; the bellkeeper's `go_ring()` now goes through it). Their places are an arc of four, 1.0 in front of the doors. The chant starts once 3 stand at their places and the cathedral is at 50% or more.
- **Done once.** The source doc's stealth story is "finish the Citadel before the Banishing Rite completes", so a completed rite does not repeat. Completion calls `Rules.lose_time(40)`, and the clergy go off duty.
- **Breaking:**
  - fewer than 2 in the ring, or the cathedral under 50%: the progress is lost;
  - the clergy still on the steps stay there, and the rest are called again after 30 s;
  - it will not restart while the cathedral is under 50% (M4's engineers can mend it).
- **Ending:** the cathedral destroyed or blighted, or fewer than 3 clergy alive. The town starts with about 9.
- **What you see:**
  - a gold ring on the ground under the people, its bright arc growing with the progress;
  - halos over the chanting clergy, and motes rising from the ring;
  - under the clock, "CLERGY GATHER n/3", then "BANISHING RITE" with a bar, on a dark plate;
  - banners for the gathering, the start, a break, the end, and "THE CLERGY BANISH YOU - 40 s LOST".
  - The F4 panel gains a rite line.
- **Duty survives the evacuation.** `Crowd._evacuate()` skips anyone on duty; `Crowd.off_duty()` sends them on afterwards (to the gates if the town is evacuating, otherwise home). This applies to the bellkeeper too: a keeper who rang after the evacuation was called used to regroup at home and never leave.
- **People on duty stand still** at their post instead of drifting round it.
- **Rite scenario** (Prepared, City Emergency called at 20 s, seed 7):
  - the clergy gather and chant within 5 s; the rite completes at about 50 s, and the clock drops from 290 to 245;
  - `--interrupt` (three of the clergy killed quietly 10 s into the chant): the rite breaks; the clergy regather after the cooldown and are chanting again 31 s later.
- **Checksums:**
  - crowd_check unchanged at −549829194;
  - rite scenario −305545241; interrupted −930059581.
- **Mission test:**
  - Organized `citizens=167 escaped=1` (M2: 164 / 1; the bellkeeper now keeps to the tower);
  - Prepared `citizens=171 escaped=0`.
- **Mission bench, alternating:** M2 106.5 / 104.1 fps, M3 108.9 / 110.2 fps.
- **Tests:** 870 checks.

### M4
- **EngineerManager** (`src/game/crowd/engineer_manager.gd`): made by `Crowd.spawn()`, stepped in `advance()`, and turned out at City Emergency. Only a profile with `engineer_teams` has one (Prepared 2 teams, God-Resistant 3).
- **The engineers:** the craftsfolk living nearest the workshop take the role Engineer, two per team, and work at the workshop until called. On a job they run there on duty (`go_duty`). With nothing to mend they stand by at the workshop, on call.
- **Jobs and scoring:** as specified — `PRIORITY − 2 × distance` (Citadel 100, routes 80, Bell Tower and cathedral 60, houses 20).
  - Rethought every 2 s. A team changes job only for one at least 20 better.
  - Two teams never hold the same job.
  - A building on fire is left to the fire brigade.
  - The Citadel is a job once 2% of its health can be mended.
- **Mending:** 5% of the building's health a second, while both of the team stand at their places at the site; for the Citadel, 5% of the keep's health a second.
  - Scorch and frost fade with the damage (`Structure.repair()` and `ease_marks()`); cracks close once the building is over 65% (the Citadel's parts: over 90%).
  - **The Citadel mends only back to its last collapse** (`Citadel.repair_cap()`). Its fallen towers and walls stay down, so a repair never climbs back over a collapse mark.
- **Rebuilding:** `Structure.restore()` brings a fallen gate or the bridge back as it was, in 20 s. `EnvironmentField.structure_restored` relays it: the walk grid reopens the way (`WalkGrid._on_restored`), and Rules re-measures stability.
- **Gates are left alone once the town evacuates.** In this game a fallen gate is rubble with no queue, so it lets the crowd out faster; rebuilding one mid-evacuation would hold the town's own people back. Before the Evacuation stage the gates are routes like the bridge. The bridge is always a job, because its fall cuts the south road.
- **The dock waits for M5.** It is decor today; M5 makes it a structure the boats need, and then a route job.
- **Losses:** a team with a dead member is lost, and its survivor goes off duty. After 60 s the workshop sends a new pair, if it still stands: engineers off a team first, then craftsfolk, nearest first. If nobody is free it retries every 5 s.
- **What you see:**
  - sparks between a working pair;
  - a bar over what they mend (steel for a rebuild, green for health);
  - the banners "THE ENGINEERS TURN OUT" and "THE BRIDGE / MAIN GATE / SIDE GATE IS REBUILT";
  - the F4 panel lists each team's job, score and progress, and draws a line from each engineer to their site.
- **Engineers scenario** (Prepared, City Emergency at 20 s, a Heaven Splitter on the Citadel and the bridge brought down, seed 7):
  - one team rebuilds the bridge, working from about 17 s; the bridge stands again at about 37 s;
  - the other walks across town to the Citadel (about 24 units), works from about 27 s, and mends it from 44% to its cap of 50% by 35 s.
  - In the same run the rite completed: the clock reads 4:00 at 60 s.
- **Checksums:**
  - crowd_check unchanged at −549829194;
  - engineers scenario 415943000.
- **Mission test:**
  - Organized `citizens=167 escaped=1` (unchanged);
  - Prepared `citizens=169 escaped=1`.
- **Mission bench at Prepared, alternating:** M3 106.9 / 105.8 fps, M4 105.5 / 107.8 fps.
- **Tests:** 890 checks.

### M5
- **The dock moved to the north bank, below a new postern** (decided with the user).
  - The v0.04 dock stood on the far (south) bank, past the river, so nobody could reach it without the bridge.
  - On the north bank but outside the Main Gate, the boats' passengers still queued at that gate, so the boats only added capacity once the bridge fell.
  - Now `TownLayout.DOCK` is a pier on the north bank below **the postern**: a small door in the south wall where the long west street meets it.
- **The postern:** it is the wall piece standing on `POSTERN_AT`, built as a gate tagged `postern`. Building it in that piece's place keeps every other building's seed.
  - It is open only in towns with boats; `Crowd.spawn()` bars it otherwise (`Town.bar_postern()`, `WalkGrid.refresh()`).
  - It lets one person through every 3 s (`Crowd.POSTERN_INTERVAL`, about the boats' pace).
  - It is the third entry in `Town.gates`, after the Main and Side Gates.
- **The dock is a structure:** Kind.BRIDGE tagged `dock`, role `dock`, 80 hp, with its own pier art (`PropArt._dock`). It counts as a building and as infrastructure. The ship decor lies moored beside it (`SHIP_AT`), and the bank between the postern and the dock is kept clear of decor (`DOCK_WAIT`).
- **RiverFerry** (`src/game/crowd/river_ferry.gd`) opens at the Evacuation stage, before the crowd is sent out, so the first to plan their route see the dock.
  - Evacuees bound for the dock wait in a crowd that forms on the pier and the bank behind it, in arrival order. The one at its head steps aboard every 0.67 s.
  - The ship sails when full, or 4 s after its first passenger if nobody else is waiting. (Sailing 4 s after the first, whatever, left it carrying 2 a trip while a crowd waited.)
  - Those aboard escape when it sails (`Crowd.escape()`). It is back 12 s later.
  - On the trip, the ship slips 3 units downriver as it fades out, and fades back in as it returns.
- **Routing:** `EvacuationManager.add_boat_exit()` makes the dock a third exit, through the postern, while the ferry runs. Each person waiting at the dock costs 0.7, and each person in the postern's queue counts 1.5× a gate's, as it is slower. Reaching the boarding point is not escaping (`Person.has_escaped()`).
- **Gate queues count only inside the walls.** A gate's crowd and danger no longer count against someone already outside: people who had passed the postern were weighing its queue again and turning back for the south road.
- **A destroyed dock stops the boats until the engineers rebuild it** (the dock is a route job), because rebuilding implies the boats run again. A blighted dock ends them for good. Either way, those waiting go for the gates.
- **Banners:** "BOATS TAKE PEOPLE FROM THE DOCK", "THE BOATS ARE STOPPED", and "THE DOCK / POSTERN IS REBUILT". The F4 panel shows the boats' state, load, crowd and trips, and the postern's queue.
- **Fixed:** `Crowd._release_all()` assigned an untyped `[]` to a typed array. It showed when a gate (here the postern) fell before anyone had queued at it.
- **Boats scenario** (Prepared, evacuation called at 20 s, seed 7; at 40 s):

  | | Escaped | Boat trips | Carried by boat |
  |---|---|---|---|
  | Bridge standing | 34 | — | 6 by 30 s |
  | Bridge cut at 5 s | 29 | 2 | 12 |

  The Organized gates scenario has 29 escaped at 40 s; the Prepared one has 33.
- **Checksums:**
  - crowd_check −346732806 (it changed: the laborers' dock anchor moved, and so did decor);
  - boats 452876283; boats with `--cut-bridge` −510933028.
- **Mission test:**
  - Organized `citizens=173 escaped=1`;
  - Prepared `citizens=171 escaped=1`.
- **Mission bench, alternating:**
  - at Prepared, M4 110.9 / 110.9 fps and M5 107.7 / 109.3 fps;
  - at Organized, M5 109.6–110.0 fps.
  - Primitives in view rose from 224k to 237k with the decor reshuffled by the move. Restoring the old exclusion gave 220k at the same fps.
- **Tests:** 906 checks.
