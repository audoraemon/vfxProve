# KAK v0.09.1 Decisions Batch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** build the nine decisions the user made on 2026-10-06 from the Dev Ledger's open cards:
- the soldiers (escorts, the rally);
- Pestilence;
- the engineers;
- The Long Night's balance.

**Architecture:** small rule changes in the town (`Crowd`, the response managers, `Citadel`) and in The Long Night's data and directors. No new systems.

**Tech Stack:** Godot 4.7.2, GDScript; headless tests in `tests/run_all.gd`; scripted scenarios in `tools/dev/behaviour_check.gd`; the screen-flow test `--flow-test`.

**Spec:** this plan is the spec. The decisions were made with the user on 2026-10-06; they are listed verbatim under each task. The Long Night's design is `docs/superpowers/specs/2026-10-04-kak-long-night-acts-design.md`. The soldiers' roles are `docs/superpowers/specs/2026-10-02-kak-v007-soldiers-design.md`.

## Global Constraints

- **Workspace:**
  - Worktree: `C:\BURIN_NITRO\Godot\GIT\vfxProve-v0091` (Git Bash `/c/BURIN_NITRO/Godot/GIT/vfxProve-v0091`).
  - Branch: `feat/v0091-fixes`, started from `origin/feat/Develop-Main` at `ec247e4`.
  - Work only in this worktree. Never touch the main checkout `C:\BURIN_NITRO\Godot\GIT\vfxProve` (another session commits v0.10 campaign work there) or any other worktree.
- **Godot:** `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`. Every command runs with `--path .` from the worktree.
  - **Import**, after a new `class_name` or a new test file: `timeout 300 $G --headless --editor --path . --import >/dev/null 2>&1`.
  - **Tests:** `timeout 900 $G --headless --path . --script res://tests/run_all.gd 2>&1 | grep -v '^\s*at:' | grep -n "FAIL\|SCRIPT ERROR\|Parse Error\|checks="`. Expected: `failures=0`, with no errors.
  - **Digest:** `$G --headless --path . -s tools/dev/state_digest.gd`.
  - **crowd_check:** `$G --headless --path . --fixed-fps 60 -s tools/dev/crowd_check.gd`.
  - **FLOW:** `$G --path . --audio-driver Dummy --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep "FLOW result"`.
  - **Behaviour:** `$G --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=<name>`.
  - Baselines at `ec247e4` are recorded in the Execution notes (Task 0).
- **These are deliberate rule changes, so some exact checksums will move.** Every task must:
  1. run every exact gate;
  2. name each value that changed;
  3. explain why the change is caused by this task's rule and nothing else.

  A checksum that changes without an explanation is a defect. The state digest must never change: no task touches `Structure` or `EnvironmentField`.
- **The v0.10 campaign is not this batch's to change.** The campaign's code lives in `src/game/campaign/` and its mission entries in `MissionBook`, such as `feast_festival` and `vigil_flame`. Its directors are the Vigil and feast ones. Changes to shared code (`Crowd`, the Festival director, `NightState`) must leave the campaign's tests passing. If a decision would change a campaign mission's behaviour, keep the campaign's behaviour as it is and report it.
- **Code style:** tabs; `##` doc comments in full sentences; constants `UPPER_CASE` with a `##` comment; new enum values at the end.
- **Git:**
  - `git add` explicit paths only;
  - never add `default_bus_layout.tres`, `captures/`, `.codex/` or `concepts/`;
  - commit messages are tagged `(v0.09.1)` and end with a blank line, then a `Co-Authored-By:` line naming your model;
  - do not push, merge or tag.

## Review Focus

1. **A soldier in a refilled role is one the role's manager actually uses.** A rallied soldier that takes a dead marshal's, escort's or rescuer's role must be picked up by that manager. *Test:* Task 1.
2. **The garrison's damage cut never makes the Citadel unkillable.** It is capped, and the cap is tested. *Test:* Task 1.
3. **A warned town's feast still breaks when the god strikes it.** "Calm the feast" stops the feast breaking by itself, not under a real blow. *Test:* Task 3.
4. **Per-act DP shows correctly** on the board card, the first Prepare and each interlude re-draft, and the campaign keeps its own budget. *Test:* Task 3.
5. **A rank cap that depends on lost acts must not break a scored single mission** (Last Judgement's ranks are unchanged). *Test:* Task 3.

---

## Task 0 (controller): baselines

- [ ] Run every gate at `ec247e4` in the worktree and record the values in `## Execution notes` → `### Task 0 baselines`.

## Task 1: The soldiers — escorts by need, the rally as reserve and garrison

**Decisions, verbatim:**
- *Escorts:* "Only what the tier uses — each tier keeps just the escorts it can assign (escorts per duty × duties); the rest patrol and rally as before v0.07."
- *Rally:* "Reserve + garrison — rallied soldiers refill dead marshals, escorts and rescuers, and each one on the ring cuts Citadel damage a little (capped). The ring becomes a target worth hitting first."

**Files:**
- `src/game/crowd/crowd.gd`: `_assign_corps`, the rally, a refill on a role soldier's death.
- The managers that must accept a refilled soldier: `escort_manager.gd`, `marshal_manager.gd`, `rescue_manager.gd`.
- `src/game/town/citadel.gd`: the damage filter `_on_part_hit`.
- Tests: `tests/test_corps.gd`, `tests/test_escorts.gd`, `tests/test_marshals.gd`, `tests/test_rescue.gd`, `tests/test_citadel.gd`, plus new tests where needed.
- The F4 overlay (`behaviour_overlay.gd`), if a garrison line fits.

**Rules:**
- **The escort cap.** It is `escorts_per_duty × duties`, where duties = (1 if `profile.bell`) + (1 if `profile.rite`) + `profile.engineer_teams`. These are the duties `EscortManager._duties()` knows: `bell`, `rite`, `team:N`.
  - Only the first *cap* patrollers, in post order, get `Corps.ESCORT`. The rest keep `Corps.NONE`, so they patrol, investigate and rally.
  - Unaware (`escorts_per_duty` 0) has no escorts.
  - Write the numbers per tier into the test.
- **Reserve.** Once the rally has happened, when a living soldier with a role (marshal, escort or rescuer) dies, the nearest living rallied soldier (corps NONE, on the ring) takes that role.
  - It takes the corps, inherits the dead soldier's `post`, and runs to its job. Each manager must then use it:
    - **MarshalManager:** add it to its gate's marshals, or the nearest gate short of marshals.
    - **EscortManager:** it becomes available to a duty short of escorts. Today a duty is given its escorts once over its whole life; a reserve escort may replace a fallen one.
    - **RescueManager:** it joins the squad that lost a member.
  - At most one replacement per death. When the ring is empty, nobody refills.
- **The garrison.** Each living soldier on the ring (a rallied soldier within `RING_RADIUS + 1.0` of `CITADEL_ORIGIN`) cuts damage to the Citadel's parts by `GARRISON_STEP := 0.02`, up to `GARRISON_CAP := 0.30` (starting values).
  - It is applied in Citadel's damage filter. Read the count from the crowd once per hit; it must not cost every frame.
  - Show the cut somewhere a player can read it, for example the F4 overlay line "Garrison −NN%". A HUD change is optional; do not crowd the HUD.

**Tests:**
- **The escort cap,** for each tier: Unaware 0, Unprepared 0 (no bell), Organized 1, Prepared 2 × (1 + 1 + 2) = 8, God-Resistant 2 × (1 + 1 + 3) = 10. Check these against the profile values in the code, and correct the arithmetic if a profile differs. The rest are NONE and rally.
- **Refills, one per role,** after `rally()`:
  - kill a marshal: a rallied soldier becomes MARSHAL and its manager posts it;
  - kill an escort on duty: a replacement guards the duty;
  - kill a rescuer: its squad is whole again.
  - Review Focus 1: assert the manager uses the replacement, not just that the corps changed.
- **No refill** before the rally, or with the ring empty.
- **The garrison:**
  - with N soldiers on the ring, a part takes `damage × (1 − min(N × 0.02, 0.30))`;
  - with 20 on the ring the cut is exactly 0.30, and the Citadel still falls to enough damage (Review Focus 2).

**Gates:**
- The digest must not change.
- Report every other changed value with its reason. Expected:
  - the scenarios that rally or kill role soldiers (`soldiers …`, `siege`) change;
  - the Warning cases may change (Unaware patrollers become NONE);
  - crowd_check may stay the same. It never rallies, but corps change at spawn.

**Commit:** `feat: escorts by need; rallied soldiers refill roles and garrison the Citadel (v0.09.1)`.

## Task 2: Pestilence's reach; the engineers' fire duty

**Decisions, verbatim:**
- *Pestilence:* "Reach 1.5 — the sick infect anyone within 1.5 units (today less), so it jumps through crowds but still dies out in thin streets."
- *Engineers:* "Return after a fright — an engineer frightened during the evacuation goes back to its team, as the bellkeeper and clergy do (today it flees for good)." And: "Fire before mending — a burning building outranks mending a damaged house, so idle-ish teams actually fight fires."

**Files:**
- `src/game/crowd/plague_manager.gd` (`SPREAD_R` 1.0 → 1.5);
- `src/game/crowd/engineer_manager.gd`, `crowd.gd` (`_evacuate` / `off_duty` paths), `fire_manager.gd` if needed;
- tests: `tests/test_plague.gd`, `tests/test_engineers.gd`.

**Rules:**
- **Pestilence:** `SPREAD_R := 1.5`. `SPREAD_CHANCE` and the life are unchanged. Update the doc comment.
- **Return after a fright:**
  - An engineer frightened during the evacuation (or after `_fled_all`) goes back to its team when it calms down: RECOVER or CALM, as `EngineerManager.AVAILABLE` already allows. It must not be sent fleeing by `_evacuate`, `off_duty` or the recover path.
  - Find exactly where it is lost today and fix it there: a team member is an engineer on duty, like the clergy in the rite.
  - When the team itself stands down (the job is done, or the town has fallen), engineers may flee as before.
- **Fire before mending:** when a team chooses its next job, a burning building within `FIRE_REACH` is chosen before mending a damaged house. Rebuilding a gate, the bridge or the dock keeps its current priority over both; say what that priority is in the report.

**Tests:**
- **Plague:** a sick person infects someone at 1.4 (the chance forced to 1.0 in the test) and not someone at 1.6.
- **Return after a fright:** with the evacuation called, frighten an engineer member, let it recover, and it is back on its team's job, not FLEE.
- **Fire before mending:** with a damaged house and a burning house both in reach, the idle team goes to the fire.

**Gates:** the digest is unchanged. Report every changed checksum with its reason. Expected: Pestilence scenarios and `engineers` change; Organized ones without engineers or plague should not.

**Commit:** `feat: Pestilence reaches 1.5; engineers return after a fright and fight fires before mending (v0.09.1)`.

## Task 3: The Long Night's balance

**Decisions, verbatim:**
- *Festival:* "Calm the feast — a warned town still holds its feast: goers only count as broken by a fright from the god (a power, a seen kill, the Mayor's death), not by the town's own alarm or evacuation."
- *Rite:* "Rite costs 20 s at night — in The Long Night the rite's penalty is 20 s instead of 40; Last Judgement keeps 40."
- *DP:* "Per-act DP — Act I 6 DP / 3 slots (as The Warning), Act II 10 DP / 4 slots, Act III 14 DP / 4 slots: the god grows through the night."
- *Score:* "Losing an act caps rank at B — a night with any act lost can't rank above B; S/A need all three acts." And: "Mayor's death breaks less — killing the Mayor frightens goers within 8 units of the fountain, not all 80 — a big push, not an instant win."

**Files:**
- `src/game/mission/mission_book.gd` (`long_night()` and its acts);
- `src/game/mission/festival_director.gd`, `night_state.gd`;
- `src/game/mission.gd` (the rite's penalty on completion);
- `mission_def.gd` (a `rite_penalty` field), if that is the cleanest way;
- the UI that shows DP: the board card, Prepare, the interlude;
- tests: `tests/test_night.gd`, `test_festival.gd`, `test_flow.gd`, `test_mission_book.gd`.

**Rules:**
- **Calm the feast:**
  - First find why a warned town's feast breaks by itself today (the alarm stage? `_regroup`? `_evacuate`? soldiers in the square?). Then make goers count as broken only through a fright from the god.
  - A god fright is any of: `Person.panic` from a cast's danger (`Crowd.on_cast` / `_react`); a seen kill (doom witnesses, collapses caused by a power); the Mayor's death.
  - Goers sent away by the town's own regroup or evacuation must not count, or must not be sent away while the feast holds. Choose the smaller change and explain it.
  - Review Focus 3: a warned town under a Heaven Splitter in the square still breaks.
- **The rite at night:** a completed Banishing Rite during any of The Long Night's acts takes `20.0` s off the clock. Everywhere else it takes `BanishingRite.PENALTY` (40), so Last Judgement is unchanged. Update the banner's text, which prints the seconds.
- **Per-act DP and slots:**
  - Act I (`omen`) 6 DP / 3 slots; `festival` and `procession` 10 DP / 4 slots; `judgement` 14 DP / 4 slots.
  - The night's own `MissionDef` (board card, first Prepare) shows Act I's 3 slots / 6 DP. The board card says the budget grows, for example "3–4 slots · 6→14 DP".
  - Each interlude re-draft uses the next act's numbers. The `night` behaviour scenario's per-act loadouts must fit them; Act I's whisper, doom and discord (4 DP) already fit.
  - Review Focus 4: the campaign builds its feast nights with its own `dp_capacity` (`campaign_state.gd:61`). Confirm it is unaffected.
- **The rank cap:** `NightState.result()`: when any act in the night was lost, the rank is at most `B`. A scored single mission (Last Judgement, `Rules.rank()`) is unchanged (Review Focus 5).
- **The Mayor's death:** frighten only goers within `MAYOR_PANIC_R := 8.0` of the fountain (`TownLayout.FOUNTAIN` centre), not all of them. Update the banner if its text says the whole feast breaks.

**Tests:**
- **The calm feast:** a Festival act with `night.bell_rang = true` and no casts holds for 150 s: lost to the clock "closed", with `count() < need`. The same warned town under a power in the square breaks.
- **The rite at night:** a completed rite in a night act takes 20 s; in Last Judgement it takes 40.
- **Per-act DP:** each act's `dp_capacity` and `slots`; the interlude's Prepare draft capacity for Act II is 10; the board card's text.
- **The rank cap:** with an act lost and a night score of 30000, the rank is B; with all acts won it is S.
- **The Mayor's death:** goers 5 units from the fountain are frightened, goers 12 units away are not.

**Measure:** run the `night` scenario, both paths, `--act1=play --act2=play --act3=play`, twice each. Report each end line. Report whether a played night still wins and its rank. Changing other numbers is not part of this task: report anything off as an option.

**Gates:** the digest is unchanged. The Warning and Last Judgement single-mission checksums must stay the same as after Task 2. Report every night-scenario change.

**Commit:** `tune: The Long Night -- a calm feast, the rite at 20 s, per-act DP, rank cap, the Mayor's reach (v0.09.1)`.

## Task 4 (controller): gates, summary, merge

- [ ] Run the full gates on the branch and record them in the Execution notes.
- [ ] Run the final whole-branch review.
- [ ] Write a short `docs/KAK_Version_0.09.1_Summary.md`.
- [ ] Merge, following the memory note *check-before-every-merge*:
  1. fetch origin and trial-merge into the work branch;
  2. check for semantic clashes with the campaign work;
  3. gate the merged tree;
  4. fast-forward `feat/Develop-Main`, tag `kak-v0.09.1`, push.
- [ ] Update the ledger cards `c01`, `c02`, `c03`, `eng-followups` and `v09-decisions`.

## Execution notes

### Task 0 baselines (at ec247e4, two identical runs)

- Tests `checks=3567 failures=0`; digest `61267b7e90524d800bf1c3473a71146b`; crowd_check `-346732806 alive=220 escaped=0`; FLOW `checks=82 failures=0`.
- Exact behaviour checksums (two runs, identical):
  - `calm --seconds=60`: -355092532
  - `gates`: 589794389
  - `fire`: 250399241
  - `rite --interrupt`: -948525703
  - `soldiers --case=escort`: -778609674
  - `soldiers --case=marshals`: 692583005
  - `soldiers --case=rescue`: 230709969
  - `warning --case=none`: -489775734
  - `warning --case=doom`: -905773030
  - `warning --case=whisper`: -588314462
  - `warning --case=discord`: -997640091
  - `warning --case=mix`: -206935500
- Mission test: buildings 53, citizens 190, escaped 1, stability 70%, citadel 50%.
