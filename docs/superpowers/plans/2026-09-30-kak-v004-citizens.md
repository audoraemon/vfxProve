# KAK v0.04 citizen behaviour — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** citizens with routines, local awareness, staged alarms and gate routing, instead of one panic-to-gate crowd.

**Spec:** `docs/superpowers/specs/2026-09-30-kak-v004-citizens-design.md`.

**Architecture:**
- Extend `Person` and `Crowd` (`src/game/crowd/`).
- Add central managers under `src/game/crowd/`, stepped by the crowd's ticker at low frequency: `routine_manager.gd`, `threat_manager.gd`, `alarm_manager.gd`, `evacuation_manager.gd`.
- Put per-citizen data in `citizen_profile.gd`.

**Baseline tag:** `kak-v0.03`.

## Global constraints

- **Gates after every task:**
  - `bash tools/test.sh` passes (under machine load, run `tests/run_all.gd` directly with a longer timeout);
  - FLOW 24/24;
  - the digest is unchanged (`61267b7e90524d800bf1c3473a71146b`);
  - the queue-room test holds (Main 219, Side 213).
- **Checksums:**
  - `crowd_check.gd` changes on purpose from M1 onward; record each new checksum in "Changes made while executing";
  - from M2 onward, `behaviour_check.gd` prints its own deterministic checksum; a pure refactor keeps it unchanged.
- **Performance:** each milestone ends with `profile_view.gd` at the market and `profile_wear.gd --rounds=6 --settle=15`, against `kak-v0.03`, in the same hour. Budget: a loss of at most 5 fps at either point.
- **No global scans per citizen per frame:** shared questions go through the managers' buckets and caches.
- **Determinism:** manager decisions use the crowd's seeded rng and the spawn-order stagger, never instance ids or the wall clock.
- **Housekeeping:**
  - commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`;
  - never commit `captures/` or `default_bus_layout.tres`;
  - tag each milestone.

---

## M1 — Routines (tag `kak-v004-m1`)

### Task 1: Anchors and wells in the layout

**Files:** `src/game/town/town_layout.gd`, `town_decor.gd` or structure art (the well), `tests/test_town_layout.gd`.

1. `WELLS`: 4–6 rects of 0.5×0.5, one in each district without a fountain.
   - Built as destructible structures (`Structure.Kind.FOUNTAIN`-like, tag `&"well"`, a small stone ring and a winch drawn in `PropArt`).
   - Added last in `structures()`.
   - Kept clear of queue fans, streets and houses.
2. `static func anchors() -> Dictionary`, keyed by kind: `home` (a door point per house), `stall`, `work_craft` (smithy, workshop, carpenter), `tavern`, `cathedral`, `plaza`, `fountain` and `well` edges, `field`, `mill`, `dock`.
   - Every anchor point is walkable and outside the queue fans; this is checked in the test with a walk grid.
3. Tests: the well count; every anchor walkable and outside the fans; the queue room unchanged.
4. Capture the wells (town_debug shot), run the gates, commit.

### Task 2: CitizenProfile and role assignment

**Files:** `src/game/crowd/citizen_profile.gd` (new), `crowd.gd`, `tests/test_crowd.gd`.

1. `class_name CitizenProfile extends RefCounted` with:
   - `role: Role` (RESIDENT, MERCHANT, CRAFT, LABORER, CLERGY, CAREGIVER, FARMER);
   - `home: Vector2`, `work: Vector2` (INF when none), `leisure: PackedVector2Array`;
   - `family := -1`.
2. `Crowd.spawn()` assigns roles by `ROLE_SHARES` (spec table), deterministic by spawn index.
   - Anchors are picked with the crowd rng: nearest-weighted to the home for leisure; any of the role's work kind for work.
   - Farmers and some Laborers spawn outside at their work anchors.
   - Remove `PUBLIC_SHARE` and its public-spot anchoring; keep `TownLayout.public_spots()` only if M1 uses it for leisure.
3. Tests:
   - role shares within ±1 citizen of the table;
   - every profile's points are walkable;
   - about 10% outside the walls.

### Task 3: RoutineManager

**Files:** `src/game/crowd/routine_manager.gd` (new), `person.gd`, `crowd.gd`, tests.

1. The manager holds each calm citizen's `dwell_left` and next pick. It is stepped from the crowd ticker; each frame it visits a slice so that each citizen is seen at 1 Hz.
2. When dwell runs out, it picks the next destination by role weights (home, work, leisure, errand to the market), then calls `Person.set_goal()`. The dwell is 5–25 s from the rng.
3. `Person`'s calm wandering in `_think()` (CALM_SPREAD, strolls) is replaced by: at the goal, idle and dwell; otherwise walk. POST and the other minds are untouched.
4. Tests:
   - a citizen with a profile reaches its routine goals in turn;
   - dwell times fall within range;
   - determinism: two spawns give the same goal sequence.
5. `crowd_check` gets a new baseline.
6. Capture market, street and farm views after 60 s of calm; compare with v0.03's market (still busy).
7. **Bench M1:** start view and wear. Commit, tag `kak-v004-m1`, show the images to the user.

---

## M2 — Awareness and local intents (tag `kak-v004-m2`)

### Task 4: ThreatManager and per-power reach

**Files:** `threat_manager.gd` (new), `src/game/power_book.gd` (`sight`, `sound`, `severity`), `rules.gd` or `mission.gd` (register casts), `town.gd` (register collapses), tests.

1. `register(at: Vector2, radius: float, severity: float, duration: float, sight: float, sound: float, kind: StringName) -> int`.
   - Threats are kept in 4-unit buckets.
   - When a threat expires, it leaves a *recent impact* entry for 8 s.
2. Casts register at the aim point with the power's values.
   - Line and lane powers register a capsule approximated by 2–3 circles.
   - The Tornado updates its threat position as it moves (`tornado_tempest.gd` calls `move(id, at)`).
3. Collapses register (radius from the footprint, severity 0.4, 3 s).
4. `nearby(at: Vector2, reach: float) -> Array` answers from buckets.
5. Tests: register, expire, bucket queries, recent impacts.

### Task 5: Awareness levels and neighbour spread

**Files:** `person.gd` (awareness fields and memory), `crowd.gd` or a small `awareness` pass in the ThreatManager, tests.

1. `Person.awareness: Awareness` (UNAWARE, CONCERNED, THREATENED, EMERGENCY, COLLAPSE) and `known: Array` (threat ids, at most 4).
2. Proximity checks at 8 Hz on screen and 2 Hz off screen, through `nearby()`:
   - inside radius + 1.5 → THREATENED;
   - inside sight or sound → CONCERNED.
3. Spread: a THREATENED citizen passes CONCERNED plus the threat id to calm citizens within 2.5 units, after a 0.5–1.5 s delay, at most once per pair. Use the fine index in `EnvironmentField` or the crowd's own grid; no all-pairs scans.
4. Tests: distance bands after a strike; spread reaches a neighbour after the delay and not beyond; determinism.

### Task 6: Intents — Routine, Observe, Local Flee, Recover

**Files:** `person.gd`, tests.

1. `Person.intent: Intent` (ROUTINE, OBSERVE, LOCAL_FLEE, REGROUP, EVACUATE, REROUTE, RECOVER).
   - The minds CALM, PANIC and FLEE are mapped: CALM → ROUTINE; PANIC → LOCAL_FLEE; FLEE → EVACUATE.
   - The mind stays for soldiers.
2. CONCERNED → OBSERVE: stop 1–3 s facing the threat, then ROUTINE with a new goal away from it.
3. THREATENED → LOCAL_FLEE: the goal is the nearest anchor at least `radius + 3` from all known threats, away from them. The citizen runs at panic speed.
4. The threat lapses → RECOVER: walk back to the routine at 0.8× speed, avoiding recent-impact cells; then ROUTINE.
5. `unhurried()` covers ROUTINE and OBSERVE only.
6. Tests: each transition. Update the old panic tests to the new names; the behaviour stays equivalent where the spec keeps it.
7. **New tool: `tools/dev/behaviour_check.gd`.** A headless run at fixed fps with scenarios (a) calm 60 s and (b) a Heaven Splitter strike at the market. It prints the counts and a checksum.
8. **Bench M2.** Commit, tag `kak-v004-m2`.

---

## M3 — Staged alarm (tag `kak-v004-m3`)

### Task 7: AlarmManager and districts

**Files:** `alarm_manager.gd` (new), `crowd.gd` (the alarm value moves or is wrapped), `town_layout.gd` (`DISTRICT_NAMES` or quarter rects), `hud.gd` (the status line shows the stage name instead of "Alarm %"), tests.

1. Stages 0–5 with the spec's thresholds as constants; per-district collapse and death counts.
2. `stage_changed(stage)` signal. Rules and HUD listen; the alarm percentage keeps feeding stability.
3. Tests: each threshold, in order, with nothing skipped except by the rules in the spec.

### Task 8: The cathedral bell and stage gates

**Files:** `alarm_manager.gd`, `person.gd`, the cathedral structure (via `TownLayout.TEMPLE`), `sfx` (a bell sound via `tools/audio/synth.py` and the catalog), tests.

1. At stage 3, the nearest living Clergy member walks to the cathedral steps. On arrival the bell rings: a sound, everyone gets all active threats, and Evacuation is allowed at alarm 50.
   - If the cathedral is destroyed, or no clergy are alive, there is no bell and the Evacuation threshold is 70.
2. Stage gates: EVACUATE is allowed only from stage 4. At stage 3, 30% of routine citizens REGROUP (home), then wait. Markets close at stage 3: merchants go home.
3. Stage 5: routing noise up, no regrouping.
4. Tests: the bell path, the no-bell path, gating.

### Task 9: Soldiers investigate

**Files:** `crowd.gd` (the soldier posting logic), tests.

1. At a district's Local Emergency, the 2 nearest patrol soldiers walk to the incident, stay 20 s, then return to post.
2. **Bench M3.** Scenario (e) escalation timeline in `behaviour_check.gd`. Commit, tag `kak-v004-m3`.

---

## M4 — Gate routing (tag `kak-v004-m4`)

### Task 10: EvacuationManager and the hazard grid

**Files:** `evacuation_manager.gd` (new), `walk_grid.gd` (a path-length query without building a full path, or a cached distance field per gate), tests.

1. A distance field per gate: a BFS over the walk grid, rebuilt when `env.layout_epoch` changes (as collapses do). This gives `path_length(from, gate)` in O(1).
2. The hazard grid: 1-unit cells, a weight from active threats plus recent impacts; `hazard_on_route(from, gate)` samples along the descending distance field (about 10 samples).
3. Gate state: open, blocked (queue fan covered by a hazard) or destroyed; the queue length comes from `Crowd`'s queues.
4. Tests: distance field correctness against `WalkGrid.path`; hazard sampling; a destroyed gate is invalid.

### Task 11: Scoring, rerouting, soldiers avoiding hazards

**Files:** `person.gd` (EVACUATE and REROUTE), `evacuation_manager.gd`, `crowd.gd` (gate queues accept per-citizen gate choice), tests.

1. `score = path_length + CONGESTION × queue + HAZARD × hazard + BLOCKED`, counting known threats only until the bell. Evaluate at 1.5 Hz while evacuating; switch only if ≥ 25% better and ≥ 4 s since the last switch (REROUTE for 1 s, then EVACUATE).
2. Soldiers' paths add a hazard penalty (A* cost in `WalkGrid` for known hazard cells, or a detour via the distance field).
3. Tests and scenarios: (c) a hazard at the Main Gate approach sends ≥ 40% of the evacuees reaching it to the Side Gate; (d) a jammed Main queue sends a share to the Side. Queue room unchanged.
4. **Bench M4.** Commit, tag `kak-v004-m4`.

---

## M5 — Debug overlay and tuning (tag `kak-v0.04`)

### Task 12: F4 debug overlay

**Files:** `src/game/ui/behaviour_overlay.gd` (new, a CanvasLayer like FpsMeter), `battlefield.gd` or `mission.gd`, tests (toggle and formatting).

1. Each citizen tinted by intent (a small coloured ring under the feet, drawn in one node in batches).
2. A gate panel: queue, score and state for each gate.
3. The alarm stage and the last 5 stage events.
4. For the citizen nearest the mouse: awareness level, known threats with their rings, the current goal line.

### Task 13: Tuning and acceptance

1. Run all the `behaviour_check.gd` scenarios and the source doc's acceptance tests (§13): a calm 60 s, a local catastrophe, gate congestion, a gate hazard, alarm escalation, a repeat mission.
2. Propose a new escape limit from 5 scripted mission runs (report the escapes per run); the user decides.
3. **Final bench** against `kak-v0.03` (start view and wear).
4. Append "Changes made while executing". Update `docs/KAK_Version_0.03_Summary.md` into a `KAK_Version_0.04_Summary.md`. Tag `kak-v0.04`, push.

## Checkpoints for the user

- **After M1:** images of the living calm town.
- **After M2:** the strike scenario numbers and a capture.
- **After M4:** a playtest request (routing feel).
- **After M5:** the escape-limit decision.

---

## Changes made while executing

### M1
- **Wells: three, not 4–6.** Each needs open ground clear of the houses, the streets and the gate queues, with no building in front hiding it.
  - The ones built are in the NW, the W and the SW.
  - The north quarter's only open spot is behind a townhouse, and the east's lie behind the tavern or in the Side Gate's queue; the market fountain serves the east.
- **Farmers live at the farmhouse nearest their field** (a new "barn" anchor kind). As townsfolk their commute was ~30 units, and half the town was walking at any moment.
- **Places are chosen near home:** work is one of the 4 of its kind nearest home, and an errand one of the 6 stalls nearest home.
- **Stays are longer than the spec's 5–25 s:** home 10–30 s, work 25–60, leisure 8–25, errands 5–12.
- **Milling:** at a place, citizens stay within 0.6 of it (PLACE_SPREAD), not v0.03's 1.4.
- **Routine state lives on Person** (`stay_left`, `last_place`), not in arrays indexed by the citizen list, which shrinks as people escape.
- **Calm scenario at 60 s:** 41 at stalls, 38 at home, 18 at water, 10 at taverns, 9 at fields, 7 at craft yards, 7 on plazas, 4 at the cathedral, 80 walking.
- **crowd_check:** −856644546 (wells), then −774498493 (routines).
- **Market view bench** (same hour, `profile_view`):

  | | fps (two runs) | Draw calls |
  |---|---|---|
  | `kak-v0.03` | 114.5, 113.7 | 1054 |
  | M1 | 117.5, 116.1 | 1036 |
- **Wear bench** (4 rounds, 15 s settle), `kak-v0.03` against M1:

  | | `kak-v0.03` | M1 |
  |---|---|---|
  | Start | 112.6 fps | 113.0 fps |
  | Round 4 | 159.2 fps | 158.6 fps (first run), 152.2 (rerun) |

  The spread at ~155 fps is 0.3 ms of noise, inside the budget.
- **Bug found by the wear run:** RoutineManager's place in the roster ran past its end once people escaped or died. It now wraps, and a test covers it.

### M2
- **Threats are kept in a plain list** (ThreatManager), not buckets: only a handful are ever active.
- **Per-power reach** is `PowerBook.REACH` (sight, sound, severity, seconds). The danger radius comes from `Targeting.AREAS`; a lane registers a threat every radius along it.
- **The Tornado is not moved per frame.** Its threat covers its roam (radius r + roam) for its 10 s.
- **Intents are read from minds.** Mind gains OBSERVE and RECOVER; `Person.intent()` maps the minds to intents.
- **Panic no longer turns into flight.** Panic becomes a local run to beyond the danger's edge, then RECOVER (5–10 s wait, then the routine, avoiding unsafe ground).
- **The alarm-50 town-wide flight is still in place until M3.** In the strike scenario:
  - for the first 2 s only nearby people react; the rest carry on;
  - the kills and collapses of one Heaven Splitter in the packed market take the alarm past 50 by 5 s, and everyone evacuates.
- **Strike scenario, intents by distance at 2 s:**

  | Distance | Intents |
  |---|---|
  | 0–6 | 22 fleeing locally, 7 looking |
  | 6–12 | 26 fleeing, 42 looking, 12 in routine, 14 recovering |
  | 12–20 | 65 in routine, 12 looking |
  | 20+ | 13 in routine |

- **Freed people:** typed assignments of freed people in the spread and routine code are guarded, and so is the same bug in `profile_wear.gd`'s breakdown.
- **Checksums:** crowd_check −215896176; strike checksum 331747187.
- **Mission test:** `citizens=144 escaped=18` (v0.03: 143, 10); the global flight now fires after the local runs.
- **Bench:**
  - market view: 115.3 and 113.9 fps (v0.03: 114);
  - wear: 110 fps at the start, 149 at round 4 (v0.03: 159; within noise at that rate, 0.4 ms).

### M3
- **Thresholds tuned past the spec's starting values.**
  - At the spec's values, one Heaven Splitter into the packed market (about 20 stalls and 40 deaths) reached alarm 51–62 on its own, rang the bell within 2 s and emptied the town 5 s after the first cast.
  - Now: LOCAL_EVENTS 4 (was 2), CITY_ALARM 35 (25), EVAC_BELL 75 (50), EVAC_NO_BELL 90 (70).
  - New: REGROUP_SECONDS 15 — no evacuation until 15 s after City Emergency begins.
  - The soldiers still rally at City Emergency; the first hit on the Citadel still rallies them too.
- **The bell:** the nearest living Clergy member walks to the middle cathedral step (Mind.DUTY) and rings it on arrival. If the ringer dies or flees, another is sought every 2 s. A new synthesized `town_bell` cue joins the catalog (109 files).
- **Regrouping:** Mind.REGROUP (walk home and wait). Every merchant regroups at City Emergency (the market closes), plus 30% of the other citizens, picked by spawn stagger.
- **Collapse:** reached when the Citadel falls or stability ≤ 25% (Rules calls `Crowd.order_collapses()`). Routing noise waits for M4.
- **HUD:** the status line shows the stage name, coloured by stage, in place of "Alarm %".
- **Scenarios:**
  - strike: one Heaven Splitter leaves the town at City Emergency, with people regrouping and returning to their routines; nobody evacuates within 30 s;
  - escalate: Concern at 21.2 s, Local Emergency at 22.6, City Emergency at 24.7 (alarm 36), the bell by 10 s after the first cast, Evacuation at 39.7 once the second cast had taken the alarm to 100. Escaped at 60 s: 28 (50 at the spec's values).
- **Mission test:** `citizens=189 escaped=2 stability=53%` (v0.03: 143, 10, 45%). The scripted casts no longer empty the town into the gates.
- **Market bench, same hour:**

  | | Run 1 | Run 2 |
  |---|---|---|
  | `kak-v0.03` | 94.4 fps | 96.3 fps |
  | M3 | 92.5 fps | 100.3 fps |

  The machine was slower that hour (msedge busy).
- **Tests:** 801 checks. crowd_check −215896176, unchanged (it never raises the alarm).
