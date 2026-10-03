# Kingdoms Amid Kataclysm (KAK) — Version 0.08.2 Summary

*Engine: Godot 4.7.2. Branch `feat/Develop-Main`, after `kak-v0.08.1`. A fix batch of four items: a lost MANIFEST, engineers at fires, a harder God-Resistant, and a profile of the worst frame. The profile's details: "v0.08.2: the worst-frame profile" in the Execution notes of `docs/superpowers/plans/2026-10-03-kak-v008-awakening-slice.md`.*

## 1. MANIFEST during a fade-in is kept

Before, `Game._faded_into_mission()` dropped any MANIFEST, Replay or Restart that came while a fade was running. A player who paused at once after a Replay, changed powers and pressed MANIFEST lost the press.

**Now:**
- A request that comes once the new mission is up is **kept** and runs when the fade ends. "Up" covers the moment behind the black and the fade back in. Such a request is a Restart, or a MANIFEST from the Prepare screen reached through the pause menu.
- Any other screen change in between drops it (Back, Missions).
- A second click during the fade *out* is still ignored, so one button cannot start two missions.

**FLOW:** a new step checks that a MANIFEST pressed during the Replay's fade-in is kept, then runs. The two waits added in v0.08 M1 to work round the bug are gone. FLOW now has **35 checks** (34 before).

## 2. Idle engineers fight fires

At Prepared and God-Resistant, an engineer team with nothing to mend now fights the nearest fire it can within 30 (`FIRE_REACH`):
- it joins through `FireManager.enlist()` and fetches water like the brigade;
- it is forced, like a rescue squad, so a soldier standing in for an engineer can go too;
- it **stays on through the evacuation**, when the fire brigade stands down; the evacuation does not send it running.

A job to mend calls the team back at the next rethink (2 s). When the fire is out, the team goes back to the workshop, on call.

**Tests:** 10 new checks in `test_engineers.gd`. Five of them fail on the old code.

**Measured** (`siege --difficulty=prepared`, three before/after pairs, side by side):

| | Before | After |
|---|---|---|
| Siege: ends (50 escaped) | 61 / 61 / 61 s | 59 / 61 / 61 s |
| Siege: escaped at 60 s | 49 / 48 / 49 | 50 / 48 / 49 |
| Siege: fires burned / doused | 0 / 0 | 0 / 0 |
| `siege --burn`: ends | 60 / 60 / 60 s | 59 / 61 / 61 s |
| `siege --burn`: burned down / doused | 16-17 / 3 | 16-17 / 3 |
| `siege --burn`: buildings down at the end | 67 / 67 / 68 | 67 / 69 / 70 |

**Effectively no change, for two reasons found while measuring:**
- **The plain siege never burns anything.** Every fire-kind hit kills a house outright (houses have 50 hp; the hits deal 60-70), and a fire only starts on a building still standing. `siege --burn` (new) sets 6 houses burning at 30 s and 6 more at 60 s to make it fire-heavy.
- **The engineers are rarely idle, and they run.** In `--burn` both teams are usually mending houses: fires leave damaged houses behind, and burning ones are not jobs. Only one team was at a fire, once per run. A debug run showed that **all four engineers were fleeing by 45 s**: an engineer frightened during the evacuation recovers into flight, and FLEE never gives a member back to its team. A team whose two members fled keeps its job forever.
- **Proposed follow-ups (your call):**
  - an engineer who is frightened during the evacuation goes back to its team, as the bell and rite duties do;
  - a fire outranks mending a house (`Job.HOUSE`, priority 20).

**Siege report:** it now prints the fires burning, burned down and doused, the buildings down, and "fire" for a team at a fire. It also prints when the mission ends, and when the rite breaks or completes.

## 3. God-Resistant clearly harder than Prepared

Four new `ResponseProfile` numbers. Only God-Resistant changes them; every other tier keeps today's value:

| Number | Prepared (and others) | God-Resistant |
|---|---|---|
| `regroup_seconds`: City Emergency to the evacuation | 15 s (was `AlarmManager.REGROUP_SECONDS`) | **8 s** |
| `boat_load`: people per sailing (loading still takes 4 s) | 6 | **10** |
| `postern_interval`: seconds per person through the postern | 3.0 | **1.5** |
| `rite_clergy`: clergy called, places on the steps | 4 | **6** |

- The town already has 9 clergy, so the rite calls more of them; nobody new is made a cleric.
- The evacuees' choice of exit weighs the bigger boat and the quicker postern.
- **Defense Profile:**
  - "River Evacuation" now reads **"River Boats x6"** (x10 at God-Resistant);
  - the rite line reads **"Banishing Rite x4, 45 s"** (x6, 35 s);
  - God-Resistant's blurb: **"Everything faster: evacuates sooner, big boats."**

  A new test checks that every blurb fits beside its label.

**Measured** (`siege`, three runs per tier, Prepared and God-Resistant side by side; times are the scenario's, from its first cast 20 s in):

| Median | Prepared | God-Resistant before | **God-Resistant after** |
|---|---|---|---|
| Evacuation called | 18.8 s | 18.8 s | **12.0 s** |
| Ends (50 escaped) | 61 s | 56 s | **50 s** |
| Escaped at 60 s | 48 | 53 | **73** |
| Carried by boat at 60 s | 6 | 9 | **20** |
| Rite | broken at 45 s, completed at ~123 s (after the end) | completed by 45 s | **completed at 42 s** |

- The boats, the postern and the clergy alone (without `regroup_seconds`) changed little: the end was 56-57 s and 52 escaped at 60 s.
  - The first boat sails later when it must fill with 10.
  - The siege's escapes are set by when the evacuation starts and by the walk to the gates.
- The quicker regroup is what makes the difference.

## 4. The worst frame, profiled (no change)

Timers were put round every per-frame hook in a scratch copy of the tree (not in the repository): the people, the crowd and each of its managers, structures, drawing, the HUD, path-finding, and the measured render CPU/GPU time.
- **The average bench frame (~9.5 ms):** scripts 4.0 ms (the people 1.9), render CPU 4.4 ms, GPU 0.8 ms, and 1.1 ms outside any timer.
- **The worst frames (18-24 ms):** 6.5-10 ms of their time was outside every script and the render. In the same frames every script ran 1.5-2.5× slower at once. That is the whole process held up on a busy laptop (Chrome, Edge and three other Godot processes were running), not a cost in the game.
- **The one periodic cost in the code:** the citizens' routine sometimes plans a long route. `WalkGrid.path()` then takes 1.4-2 ms in that frame, about twice a second. It raises the 99th percentile, not the worst frame.
- **Ruled out:**
  - shader compiles;
  - garbage collection;
  - the enemy field's purge;
  - the crowd's managers (each under 0.05 ms a frame);
  - vsync (`--disable-vsync` frames are no better).
- **Not fixed:** spreading the route planning over frames would change every exact checksum.
- **Bench at the end:** 111.4 / 110.8 / 114.6 fps, worst 17.2 / 18.2 / 17.9 ms, 1050 draw calls (the machine was busy).

## 5. Gates

| Gate | v0.08.1 | v0.08.2 |
|---|---|---|
| Tests | 1278 / 0 | **1299 / 0** |
| State digest | `61267b7e…146b` | = |
| crowd_check | −346732806 | = |
| FLOW | 34 / 0 | **35 / 0** |
| `calm --seconds=60`, `gates`, `fire`, `rite --interrupt`, `soldiers --case=escort` | −695580348, 619520995, −16560442, −129298221, −935015846 | all = |
| Mission test (Last Judgement) | — | buildings 51, citizens 190, escaped 1, stability 71%, Citadel 50% |
| The Warning, unhindered | the bell at 24.2 s | the bell at 24.1 s |

**No exact checksum changed.**
- The two Prepared checksums (`rite --interrupt`, `soldiers --case=escort`) have no fire, so the engineers never fight one.
- The ring's four places are built in the same order as before.
- Organized has no engineers, and its numbers are unchanged.
