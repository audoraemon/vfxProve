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
