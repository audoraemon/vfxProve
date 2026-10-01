# KAK v0.07 — Soldiers — design and plan

**Baseline:** `kak-v0.06`.

**Goal:** make the town's 100 soldiers matter. Today they drill, guard, patrol, look into a district's first emergency, then all rally round the Citadel at City Emergency and wait to be hit. In v0.07 most of them take a role that helps the town survive:
- **Marshals** speed and steady the evacuation;
- **Escorts** guard the town's responders and take over their duties;
- **Rescue squads** dig survivors out of collapsed shelters and fight fires.

Following v0.05's rule, soldiers never hurt the god. Each role can be countered.

## Decisions (with the user, 2026-10-02)

| Topic | Decision |
|---|---|
| Roles | Marshals, Escorts, Rescue squads. A Citadel garrison, barricades and battle-priests are not in this version |
| Tiers | **Always on, scaled:** every tier has all three roles; the squad sizes grow with the tier |
| Allocation | **From the posts:** the walls and gates' 30 become Marshals, the 20 patrollers (10 pairs) Escorts, the barracks yard's 30 Rescue squads. Only the Citadel's 20 rally at the Citadel |

## 1. Roles

### 1.1 Marshals (the evacuation)
- **Before the Evacuation:** they guard the walls and gates as now.
- **Posting:** at the Evacuation stage, `MARSHALS_PER_EXIT[tier]` of them go to each open way out: the Main Gate, the Side Gate, and in towns with boats the postern and the dock. They stand at the exit's mouth, either side of the queue's head.
- **Faster exits:** each living marshal within `MARSHAL_REACH` (2.0) of an exit makes it `MARSHAL_SPEED` (15%) faster. A gate's release interval, the postern's, and the boat's boarding interval are divided by `1 + 0.15 × marshals`. For example, 4 at the Main Gate: 2.0 s → 1.25 s.
- **Order:** every 0.5 s, a confused evacuee within `MARSHAL_STEADY_R` (3.0) of a marshal has its confusion cut to `STEADY_TIME` (3 s). Fleeing evacuees ignore fright already.
- **Counter:** kill or knock marshals away; the exit returns to its normal pace. Marshals wear a red tabard.

### 1.2 Escorts (the responders)
- **Assignment:** when a responder's duty starts, `ESCORTS_PER_DUTY[tier]` patrol soldiers join it and keep within `ESCORT_REACH` (1.5).
  - **The bellkeeper:** while the bell is called, climbing or waiting.
  - **The clergy's ring:** while the rite is gathering, chanting or cooling down. The escorts stand by the ring's centre.
  - **Each engineer team:** while the engineers are turned out. The escorts stay with the team's first member.
- **When the duty ends:** the escorts go back to their patrol posts.
- **Witnesses:** Silent Doom near a guarded responder is seen. No new code: `Crowd._settle_doom()` already counts any living person within 2, soldiers included.
- **Steadying:** a guarded responder confused within 2 of its escort comes to after `STEADY_TIME` (3 s).
- **Taking over:**
  - **The bell:** if the bellkeeper dies before the bell has rung, a living escort becomes the keeper (`BellNetwork.replace_keeper`). Its climb takes `ESCORT_CLIMB` (1.5×) as long. The banner reads "A SOLDIER TAKES THE BELL ROPE".
  - **Engineers:** if an engineer dies, a living escort of that team takes its place, so the team is not lost.
  - The rite cannot be taken over: soldiers do not chant.
- **Immunities:** soldiers ignore Discord and Pestilence and do not panic.
- **Counter:** kill the escorts first, which is loud. Escorts wear a white tabard.

### 1.3 Rescue squads (the rubble)
- **Trapped survivors:** when an occupied shelter collapses, `TRAPPED_SHARE` (60%) of those inside are trapped under its rubble instead of killed. The rest die as now.
  - The trapped stay hidden and out of the field, with `TRAPPED_LIFE` (45 s) to live.
  - A dust plume and a small count over the rubble mark them.
- **Squads:** `RESCUE_SQUADS[tier]` squads of 3 from the barracks yard. The nearest free squad runs to a walkable spot by the rubble. With at least one member within 1.2, it frees one person every `DIG_TIME` (3 s). The freed person comes out at the rubble's edge, frightened.
- **The untended:** if `TRAPPED_LIFE` runs out, the trapped die there, as a collapse death.
- **Fires:** an idle squad joins the nearest fire within `FireManager.RECRUIT_REACH` as a crew (`FireManager.enlist`). Soldiers carry water like citizens.
- **The banner** "SURVIVORS DUG FROM THE RUBBLE" shows the first time.
- **Counter:** kill or scatter the squad, or bring down several shelters at once. The squads are few, and the trapped die when their time runs out. Rescue squads carry shovels instead of spears.

### 1.4 Scaled by tier

| Tier | `MARSHALS_PER_EXIT` | `ESCORTS_PER_DUTY` | `RESCUE_SQUADS` (×3) |
|---|---|---|---|
| Unprepared | 2 | 1 (it has only fire crews, which are not escorted) | 2 |
| Organized | 3 | 1 | 3 |
| Prepared | 4 | 2 | 4 |
| God-Resistant | 5 | 2 | 5 |

The Defense Profile gains a line "Marshals xN, Escorts xN, Rescue xN". Soldiers beyond a role's count keep today's behaviour.

## 2. How it is built

- **Soldier roles:** `Person.corps` takes one of NONE, MARSHAL, ESCORT, RESCUE.
  - `Crowd.spawn()` hands them out from the posts (`_soldier_posts` order: yard, walls, Citadel, patrol), up to the tier's counts:
    - marshals: `MARSHALS_PER_EXIT` × the number of exits;
    - escorts: the patrollers;
    - rescue: `RESCUE_SQUADS` × 3.
  - **The rally** (`Crowd.rally`) moves only soldiers without a role.
- **Duties for soldiers:** `Person.go_duty()` no longer refuses soldiers (only the bell and the engineers give one), and `EngineerManager._send` accepts a soldier at its post.
- **MarshalManager** (`src/game/crowd/marshal_manager.gd`):
  - `begin()` at Evacuation posts the marshals;
  - `speed_at(exit_point) -> float` returns the multiplier for an exit;
  - `step()` steadies the confused.
  - `Crowd._gates` and `RiverFerry` divide their intervals by it.
- **EscortManager** (`src/game/crowd/escort_manager.gd`):
  - `step()` follows the duties and assigns, moves and releases escorts;
  - it steadies the guarded;
  - `replacement(team) -> Person` serves the engineers;
  - it calls the bell's takeover.
- **RescueManager** (`src/game/crowd/rescue_manager.gd`):
  - `trap(people, s)` takes the trapped from `ShelterManager`'s collapse branch;
  - `step()` sends squads, digs, lets the trapped die, and enlists idle squads at fires;
  - `draw()` shows the plume and the count.
- **FireManager.enlist(p, s):** puts a soldier on a fire's crew. `Person.assist` gains `force` so a soldier can be sent.
- **ResponseProfile:** `marshals_per_exit`, `escorts_per_duty`, `rescue_squads`, plus the profile line.
- **Looks** (`Person._draw_soldier`): a red tabard (marshal), a white tabard (escort), a shovel in place of the spear (rescue).
- **On screen:** the banners above; F4 shows a line per role (marshals at each exit, escorts and whom they guard, squads with their jobs and the number trapped).

## 3. Measures
- **Tests:** `test_corps.gd` (allocation by tier, the rally, the looks' signature), `test_marshals.gd`, `test_escorts.gd`, `test_rescue.gd`.
- **Behaviour scenario `soldiers`** (`--case=`):
  - `marshals` / `nomarshals`: escapes per exit over 40 s of evacuation, with marshals or with their count forced to 0;
  - `escort` / `noescort`: the bellkeeper killed during the climb; does the bell still ring?
  - `rescue` / `norescue`: an occupied shelter flattened; survivors.
- **Gates:** tests, digest, FLOW, crowd_check (it changes on purpose in M1: the rally moves fewer soldiers; record the new baseline), the mission test, and a bench against `kak-v0.06` (at most a 5-fps loss).

## Milestones (each tagged)
1. **M1 — Corps:** soldier roles and their allocation, profile counts and line, the rally change, the looks.
2. **M2 — Marshals.**
3. **M3 — Escorts.**
4. **M4 — Rescue squads.**
5. **M5 — Scenario and wrap-up:** the `soldiers` scenario, the bench, the v0.07 summary, tag `kak-v0.07`.

## Changes made while executing

### M1 — Corps
- **Defense Profile line** uses this spec's wording, "Marshals xN, Escorts xN, Rescue xN". The plan's longer "Soldiers: marshals xN, …" ran ~80 px past the Prepare strip in every tier.
- **Prepare strip columns** are now sized to their content (`PrepareScreen.profile_columns()`), and a test keeps every tier's lines inside the strip.
- **`Person.stand_down()`** sends a soldier back to its post instead of recovering into a citizen's day.
- **Hold ground:** after the Citadel falls only soldiers without a role hold its rubble (`test_crowd` updated).
- **Checks:** 977; digest and crowd_check unchanged (−346732806); FLOW 24/24.

### M2 — Marshals
- **`speed_at()` is 1.0 until the Evacuation stage.** A wall post sits 1.4 from the Main Gate's mouth, so the Main Gate and the postern were ×1.15 from the start.
- **Posting:** each way out takes the nearest marshals not yet posted (greedy, in gate order), instead of the soldier list's order.
- **Banner:** "THE SOLDIERS TAKE THE GATES" only shows if at least one marshal was sent.
- **Checks:** 985.

### M3 — Escorts
- **Plan bug fixed:** the plan stored a duty's guard list after the loop that filled it, so the same escort filled every slot.
- **The bell duty is kept while the bell is called, climbing or waiting**, even with its keeper dead. A keeper killed between the bell's step and the escorts' step would otherwise have released the escorts and silenced the bell.
- **`Person.hurrying`:** soldiers sent with `send_to_post(at, rally, hurried=true)` run (`PANIC_SPEED`) until they arrive. Before this, escorts walked at about 0.6 u/s and trailed their charge.
  - Escorts and marshals are sent hurried, and so are rescue squads (M4).
- **Investigations:** a guarding escort is left out of the patrols' investigations.
- **A bellkeeper killed before the bell is called is not replaced:** no escort is assigned yet. This keeps the v0.05 counter of killing the keeper early.
- **Checks:** 999.

### M4 — Rescue squads
- **Plan bug fixed:** a squad wiped out while digging kept its site, so no other squad would take that rubble.
- **Survivors dug out once the town is evacuating head for the gates.** They used to recover into their day, because the evacuation sweep skips sheltering people.
- **The plague waits under the rubble:** a sick person who is trapped neither recovers nor dies until dug out (`RescueManager.holds()`).
- **`FireManager.enlist`** does not add a soldier twice.
- **Checks:** 1013. Mission test (Prepared): 186 citizens alive at the end, against 172 before M4.

### M5 — Scenario and wrap-up
- **`soldiers` scenario:**
  - Every case prints its role's soldier count first (0 in the "no" cases).
  - The marshals pair reports escapes by way out and the gate queues.
  - The rescue case fills the cathedral to its capacity (20).
- **Measurements and bench:** see `docs/KAK_Version_0.07_Summary.md`.
