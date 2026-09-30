# KAK v0.04 — Citizen behaviour and a living town — design

**Source:** `E:\Document\PROJECT\KAK\KAK_v0_04_Citizen_Behavior_Design.docx` (the user's v0.04 direction). Baseline tag `kak-v0.03`.

**Goal:** citizens stop being one panic system that ends in a gate rush. They follow routines, react to what they know locally, escalate through staged alarms, and choose gates by distance, congestion and hazards. The gate kill becomes an earned late phase, not the default tactic.

## Decisions (with the user, 2026-09-30)

| Topic | Decision |
|---|---|
| Scope | All P0 items, in staged sub-milestones, each playable. P1 (fire response, families) comes after. P2 (shelter) is optional. |
| Approach | Extend the existing `Person`, `Crowd`, walk grid, queue fans and ticker; add a profile per citizen and central managers. |
| Escape limit | Keep 76 for now; propose a new value from scripted runs once routing works. |
| Readability | A debug overlay only; in play, the behaviour itself tells the story. |
| Water | Two fountains plus 4–6 destructible wells, one per quarter. Placed in the layout now; used in P1. |
| Outside workers | About 10% of citizens (Farmers, Laborers) work at the farms, mills and dock and commute through the gates. |
| Awareness reach | A sight and sound radius per power, by severity. |
| Alarm bell | Clergy ring the cathedral bell at City Emergency. A destroyed cathedral means no bell. |
| Exits | The two gates only. |
| Budget | At most a 5-fps loss against `kak-v0.03`, at the start view and after heavy destruction. |
| Soldiers | Existing behaviour, plus hazard-aware routing; a few investigate Local Emergencies. |

## 1. Profiles and routines

- **`CitizenProfile`** (data on each citizen):
  - `role`;
  - `home` (a house);
  - `work` (optional anchor);
  - `leisure` (1–3 anchors);
  - `family` (optional id; used in P1).
- **Roles and weights.** Roles follow the source doc; these are the spawn shares out of 220:

  | Role | Share | Works at |
  |---|---|---|
  | Resident | 30% | — |
  | Merchant | 15% | Market stalls, taverns |
  | Craft Worker | 15% | Smithy, workshop, carpenter |
  | Laborer | 8% | Market carts, yards, dock |
  | Clergy | 4% | Cathedral |
  | Caregiver | 18% | — |
  | Farmer | 10% | Fields, barns, mills |

  Outside workers (Farmers and some Laborers) come to about 10% of all citizens.
- **Anchors.** `TownLayout.anchors()` gives named points by kind: home doors, stall fronts, workshop yards, tavern patios, cathedral steps, fountain and well edges, plazas, field edges, the mills and the dock. Every anchor is walkable, and none lies in a queue fan.
- **`RoutineManager`** (central). Each calm citizen's next destination is chosen at 0.5–2 Hz by role weights (home, work, leisure, errand). The citizen dwells there 5–25 s, then moves on. Movement stays in `Person`.
- **What it replaces.** This replaces the v0.03 `PUBLIC_SHARE` anchoring. Routines must still fill the market and streets in the calm state; a density check shows people visibly in homes, work, market, plazas and farms.

## 2. Threats and awareness

- **`ThreatManager`.** A cast, a collapse (and later a fire) registers a threat: position, radius (its shape reduced to a circle or a capsule), severity 0–1, duration, a sight radius, and a sound radius.
  - Each power's entry in `PowerBook` gains `sight`, `sound` and `severity`. For example, Heaven Splitter is local (sight 6, sound 9), and Nuclear Nova covers the whole town.
  - After its effect ends, a threat leaves a *recent impact* mark for 8 s.
- **Awareness per citizen:** Unaware, Concerned, Threatened, Emergency, Collapse, plus a small memory of known threats (up to 4, oldest dropped).
  - **Checks.** A citizen checks threat proximity at 5–10 Hz on screen and 2 Hz off screen, through the manager's spatial buckets (no town-wide scans).
  - **Spreading.** A Threatened or fleeing citizen passes Concern and their known threat to calm citizens within 2.5 units, after a 0.5–1.5 s delay, at most once per pair.
  - **The bell.** At City Emergency, a living Clergy member reaching the cathedral rings the bell. Everyone becomes aware of every active threat, and the alarm can reach Evacuation. With the cathedral destroyed, there is no bell: awareness only spreads through neighbours.

## 3. Intents

- **Intents:** Routine, Observe, Local Flee, Regroup, Evacuate, Reroute, Recover. P1 adds Assist; P2 adds Shelter.
  - **Observe:** stop 1–3 s and face the event, then Recover or Local Flee.
  - **Local Flee:** move away from known threats to the nearest safe anchor beyond the threat's radius, not to a gate.
  - **Recover:** once the threat has lapsed, walk back towards the routine carefully (slower, avoiding marks).
  - **Evacuate / Reroute:** gate travel, driven by routing (section 5).
  - **Regroup:** go home, or to the family point, before evacuating. At stage 3, 30% of citizens do this.
- **What it replaces.** The v0.03 minds (CALM, PANIC, FLEE) become intents.
  - Soldiers keep POST, RALLY and HOLD.
  - Queue holding and escapes keep their current code paths.
- **Cost.** Intent is re-evaluated at 2–5 Hz in an emergency, and on events. The half-rate on-screen updates apply to Routine and Observe.

## 4. Six-stage alarm

- **`AlarmManager`.** It keeps the existing alarm value (kills, collapses, hits on the Citadel) and adds district counts. There are about 6 districts, taken from the layout's quarters.

  | Stage | Reached when | What it allows |
  |---|---|---|
  | 0 Normal | — | Routines |
  | 1 Concern | Any threat | Observe and Local Flee near it |
  | 2 Local Emergency | A district has 2+ collapses or deaths | Local Flee; soldiers investigate |
  | 3 City Emergency | Alarm ≥ 25, or 2+ districts at Local Emergency | Markets close; Regroup; soldiers rally; the bell is rung |
  | 4 Evacuation | Alarm ≥ 50 after the bell, or ≥ 70 with no bell | Evacuate with routing |
  | 5 Collapse | The Citadel falls, or stability ≤ 25% | Independent flight: routing noise rises, no regrouping |

  All thresholds are constants, tuned by playtest.
- **Local panic.** Threatened citizens always Local Flee, whatever the stage. The stage only gates the town-wide behaviours.

## 5. Gate routing

- **`EvacuationManager`.** It keeps each gate's state (open, blocked or destroyed), its queue length, and its throughput. It also keeps a coarse hazard grid of 1-unit cells covering known threats and recent impacts, updated on events.
- **Choosing a gate.** An evacuee takes the gate with the lowest `score = path_length + CONGESTION × queue + HAZARD × hazard_cells_on_route + BLOCKED(∞)`.
  - `hazard_cells_on_route` is sampled along the walk-grid path.
  - The citizen only counts hazards it knows of; after the bell, it counts all of them.
- **Re-checking.** A citizen re-evaluates at 1–2 Hz, and on a major hazard change near its route. It switches gates only if the new score is ≥ 25% better, and at most once per 4 s. When it switches, its intent is Reroute.
- **Unchanged:** queue fans, spots, gate throughput and escape counting. The queue-room test holds (Main 219, Side 213).

## 6. Soldiers

- Their rally and post behaviour stays as in v0.03.
- When pathing, they avoid known hazard cells.
- At stage 2, two of the nearest patrol soldiers walk to the district's incident and return to post after 20 s.

## 7. Layout additions

- **Wells:** 4–6, one in each district without a fountain. Each is a small destructible structure (`well` kind) on a blocker.
- **Anchor points:** stall fronts, workshop yards, cathedral steps, field edges, mill doors, the dock.
- **Checks.** Wells go through the queue-fan and walkability tests, and the density numbers are re-measured.

## 8. Debug and tools

- **Debug overlay (F4):**
  - each citizen tinted by intent;
  - a gate panel (queue, score, state);
  - the alarm stage with a timeline of the last events;
  - for the citizen nearest the mouse, its awareness rings and known threats.
- **Scripted scenarios** (`tools/dev/behaviour_check.gd`, headless, fixed fps, deterministic):
  - (a) a calm 60 s: counts of people at each kind of anchor;
  - (b) a Heaven Splitter strike at the market: the aware and threatened counts by distance over time;
  - (c) a hazard at the Main Gate approach: the share rerouting to the Side Gate;
  - (d) a jammed Main Gate: the share choosing the Side Gate;
  - (e) an escalation run: the stage timeline.
- **Checksums.** `crowd_check.gd` gets a new baseline; `behaviour_check.gd` prints its own checksum.

## 9. Milestones (each ends playable, benched and tagged)

1. **M1 — Routines:** profiles, anchors and wells in the layout, and the RoutineManager. The calm town is alive.
2. **M2 — Awareness and intents:** the ThreatManager, per-power reach, neighbour spread, Observe, Local Flee and Recover.
3. **M3 — Staged alarm:** the AlarmManager, the bell, stage gates for intents, Regroup, and soldiers investigating.
4. **M4 — Gate routing:** the EvacuationManager, the hazard grid, scoring and rerouting; soldiers avoiding hazards.
5. **M5 — Debug overlay and tuning:** the F4 overlay, scenario checks, the 76-escape proposal, and the acceptance tests from the source doc.
6. **P1 (next):** fire response at fountains and wells (Assist), and families.

## Success

- **Calm town.** Calm people are distributed by role and place (scenario a).
- **Local first.** The first cast produces a local reaction, not a town-wide gate rush (b).
- **Routing.** Crowds split between gates under congestion or hazard (c, d).
- **Staged.** Stages show in order (e).
- **Performance.** Within 5 fps of `kak-v0.03` at the start and after heavy destruction (`profile_wear.gd`).
- **Tests.** All tests pass, the queue room is unchanged, and the digest is unchanged.
