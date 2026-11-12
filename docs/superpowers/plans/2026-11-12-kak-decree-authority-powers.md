# Decree Authority Powers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the user's Decree tree: two shared law pieces, the amber-cell rework of Leaving Is Prohibited, nine new
Decree powers at level 1, the Decree bots rewritten onto the new tree, and land it all on `feat/god-progression`.

**Architecture:** Each power is an `FxTimeline` effect under `src/fx/decree/`, registered in `PowerBook`, `Rules`,
`Targeting` and the sound catalog. Laws on a person go through one shared `LawMark` status. Laws on a place go through
one shared `LawZone` registry on the `Crowd`. Every guard sight/seize/witness check and every choice point asks those
two, never a power directly.

**Tech Stack:** Godot 4.7.2, GDScript. Headless test suites (`tests/run_all.gd`, `tests/run_part.gd`) and the
behaviour-check gates in `tools/dev/`.

**Spec:** `docs/superpowers/specs/2026-11-12-kak-decree-authority-powers-design.md` (approved 2026-11-12). Read it
first; section numbers below (§) point into it.

## Global Constraints

- Worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-decree`, branch `god/decree-powers`. Never touch other worktrees.
- Godot: `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`. After adding a `class_name`, run
  `$G --headless --editor --path . --import` twice, then `git checkout -- default_bus_layout.tres`.
- One suite: `$G --headless --path . --script <scratchpad>/run_one.gd -- test_a test_b` prints `checks=N failures=M`.
  Wrap every Godot run in `timeout`; a parse error hangs `run_part` instead of failing it. Grep for `SCRIPT ERROR`.
- Powers are reusable effects, never hard-coded into `CitizenAgent`/`Person` (the user's standing rule).
- No luck: who dies, is pushed or cut follows distance and order, never a random roll.
- Every law shows where it holds while it holds.
- Quiet powers (`quiet: true`): `noleave` (stays quiet: `alarm` 0.5, cue `q_noleave`), `redefine`, `bound`, `sealed`.
  Each plays its own `q_<key>` cue. All others are loud.
- Decree look: `DecreeParts` (GILT, INK, STRUCK, `proclaim`, `seal`, `wave`); amber is a new warm translucent gold.
- Might / cooldown / aim, verbatim from spec §5: `noleave` 1/20/click; `breath` 2/25/click; `redefine` 3/45/click+Q/E;
  `bound` 3/45/two clicks; `erase` 4/60/drag; `disorder` 3/45/click; `eminent` 4/80/drag; `fenced` 5/80/click+Q/E;
  `cage` 6/999 once/click; `sealed` 6/999 once/click.
- Stop and tell the user at once on any merge conflict. Check before every merge (fetch, trial merge on a commit,
  API clashes, gate the merged tree).
- Two sessions share this machine: pass `--jobs=2` to gate scripts while another session runs Godot.

## Review Focus

1. A person freed or killed while a law holds them (zone member, LawMark holder, Bound partner): every per-frame loop
   must skip `not is_instance_valid(p) or not p.is_alive()` and drop the entry. Pinned in Tasks 1, 2 and 6.
2. A power ended early (`end_now()`, the scene leaving the tree) must lift what it set: badges, `hold_pace` holds,
   LawMarks, LawZones, Bound links. Pinned in Tasks 1 and 2 (`_exit_tree` cleanup test).
3. Two laws at once on the same ground (two cells, cell + Breathing, Fenced NO LEAVING inside a cell): rules stack and
   neither undoes the other on lift. Pinned in Task 2.
4. Visitors (hounds, demons, Death's zombies and wraiths) inside a zone: NO LEAVING, NO BREATH and the Cage act on them
   too, as the spec says "nothing leaves". Pinned in Tasks 3, 4 and 11.
5. People indoors (`inside`) and a rite's chained captive (`chained`): zones leave them alone as today's cell does.
   Pinned in Task 2.

---

### Task 1: LawMark, the law on a person

**Files:**
- Create: `src/game/crowd/law_mark.gd` (`class_name LawMark`)
- Modify: `src/game/crowd/person.gd` (a `law: LawMark` field, created lazily; `_fightable` asks it)
- Modify: `src/game/mission/mission_director.gd:517` (`_sees`), `first_prayers_director.gd:636`, `relic_run_director.gd:481`,
  `escort_director.gd:500-539` (`_seen_by`, `_watching`, `_seize`), `hide_faithful_director.gd:516-524`,
  `witnesses()` in `assassinate`, `procession`, `ringer`, `warning`, `witness` directors, `temple_report.gd:161`
- Test: `tests/test_law_mark.gd` (register in `tests/run_all.gd` `SUITES`)

**Interfaces:**
- Produces:
  - `LawMark.set_law(p: Person, kind: StringName, seconds: float, owner: int) -> void` — kinds `&"criminal"`, `&"officer"`, `&"nobody"`, `&"bound"`
  - `LawMark.lift(p: Person, owner: int) -> void`
  - `LawMark.kind_of(p: Person) -> StringName` (`&""` when none or expired)
  - `LawMark.unseen_by_guards(p: Person) -> bool` (true for `nobody` and `officer`)
  - `LawMark.unseen_by_all(p: Person) -> bool` (true for `nobody`)
  - `LawMark.wanted(p: Person) -> bool` (true for `criminal`)
  - `LawMark.step(p: Person, delta: float)` called from `Person` each frame to expire
- Consumes: nothing.

- [ ] **Step 1: Write the failing tests** in `tests/test_law_mark.gd`:
  - `nobody` set → `unseen_by_all` true, `MissionDirector._sees` of a guard at 1.0 is false, the person is not in any
    director's `witnesses()`, and the escort `_seen_by` returns null.
  - `officer` set → `unseen_by_guards` true, `unseen_by_all` false (a citizen witness still sees him).
  - `criminal` set → a soldier within sight starts a TARGET_ONLY fight on him (`soldier.fight_target == p`).
  - Expiry: after `seconds` of `step`, `kind_of` is `&""` and all checks return to normal.
  - Two owners: `lift(p, owner_a)` keeps `owner_b`'s law.
  - Perception only: a NOBODY believer is still counted by the mission's believer count.
  - A freed person passed to every helper returns the default without error.
- [ ] **Step 2: Run** `timeout 600 $G ... run_one.gd -- test_law_mark`. Expected: FAIL (class not found).
- [ ] **Step 3: Implement `LawMark`** (a `RefCounted` holding `{owner: [kind, seconds]}`; latest set wins for
  `kind_of`). Wire one call into each file listed above at the point where it decides sight, witness, seizure or
  fight; `criminal` uses the `FightRule` TARGET_ONLY path Saint or Sinner uses (`saint_or_sinner.gd:3-12`).
- [ ] **Step 4: Import, then run** `test_law_mark` plus the suites of the files touched (`test_escort`,
  `test_hide_faithful`, `test_witness`, `test_first_prayers`). Expected: all PASS, no `SCRIPT ERROR`.
- [ ] **Step 5: Run** `timeout 1200 $G --headless --path . --fixed-fps 60 -s tools/dev/crowd_check.gd`. Expected:
  checksum unchanged (`-535548941`): an unused LawMark changes nothing.
- [ ] **Step 6: Commit** `feat: LawMark -- one shared law status on a person, asked by every sight and witness check`.

### Task 2: LawZone, the law on a place, and law rubble

**Files:**
- Create: `src/game/crowd/law_zone.gd` (`class_name LawZone`)
- Modify: `src/game/crowd/crowd.gd` (registry: `add_law(zone)`, `remove_law(zone)`, `in_law(p, kind) -> bool`, steps
  zones each frame), `src/game/crowd/engineer_manager.gd:33` (`CLEARABLE` gains `&"decree"`)
- Test: `tests/test_law_zone.gd`

**Interfaces:**
- Produces:
  - `LawZone.circle(at: Vector2, r: float, kinds: Array[StringName], seconds: float) -> LawZone`
  - `LawZone.lane(a: Vector2, b: Vector2, half_width: float, kinds: Array[StringName], seconds: float) -> LawZone`
  - `zone.contains(g: Vector2) -> bool`, `zone.kinds`, `zone.alive() -> bool`, `zone.radius` (mutable: the Cage shrinks it)
  - `Crowd.add_law(z: LawZone)`, `Crowd.remove_law(z: LawZone)`, `Crowd.in_law(p, kind: StringName) -> bool`
  - Kind `&"no_leaving"` is enforced by the zone itself each frame for Persons **and Visitors**: clamp onto the edge,
    `hesitate(0.6)` at most every 1.2 s, release past `CARRIED` 1.5. Walking in is free (spec §5.1).
  - Other kinds (`no_breath`, `disorder`, `no_running`, `no_arms`, `no_doors`, `no_sight`) are only answered by
    `in_law`; the powers and choice points act on them.
  - `LawRubble.lay(env: EnvironmentField, rect: Rect2, h: float) -> Structure` (role `&"decree"`), in `law_zone.gd` or
    its own file `src/game/crowd/law_rubble.gd`.
- Consumes: nothing.

- [ ] **Step 1: Write the failing tests:** a `no_leaving` circle sets a walker at `r + 1` back to `r`; one walking in
  from outside is not pushed back; a hound (Visitor) is held too; `inside` and `chained` people are left alone; two
  overlapping `no_leaving` zones both hold and removing one keeps the other; `in_law` is false after `seconds`;
  freeing the effect that added a zone removes it (`remove_law` on exit); a freed person in the zone is dropped;
  `LawRubble.lay` closes walk cells and an engineer CLEAR job removes it and reopens them.
- [ ] **Step 2: Run** `test_law_zone`. Expected: FAIL.
- [ ] **Step 3: Implement** `LawZone` (RefCounted, like `FoldWard` in `src/game/crowd/fold_ward.gd`) and the `Crowd`
  registry; zones stepped once per crowd frame; members cached once per step (the Visitors perf lesson: never
  allocate `alive()` per call).
- [ ] **Step 4: Run** `test_law_zone`, `test_engineers`, `test_decree`. Expected: PASS.
- [ ] **Step 5: crowd_check** unchanged. **Commit** `feat: LawZone -- area laws the town's choices ask; law rubble engineers clear`.

### Task 3: Leaving Is Prohibited becomes the amber cell

**Files:**
- Modify: `src/fx/decree/leaving_is_prohibited.gd` (uses `LawZone.circle(..., [&"no_leaving"], HOLD_TIME)`; new
  amber look: a translucent gold dome over `RADIUS` 3, cracking into shards at the end), `tests/test_decree.gd`
- Keep: `RADIUS` 3.0, `HOLD_TIME` 15.0, `T_SEAL` 0.6, the BARS badge, `bound` dict and `turned_back` (Hunt code reads
  them), `law_held()` behaviour, `quiet`.

- [ ] **Step 1: Extend the Leaving test block in `tests/test_decree.gd`:** the existing checks still pass unchanged;
  add: a Visitor hound inside cannot leave; a guard outside can walk in and is then bound; at `HOLD_TIME` the shards
  appear and nothing is hurt (`crowd` deaths unchanged).
- [ ] **Step 2: Run** `test_decree`. Expected: the new checks FAIL.
- [ ] **Step 3: Implement** the zone use and the amber look. Keep the badge and `bound` bookkeeping as today.
- [ ] **Step 4: Run** `test_decree`, `test_hide_faithful`, `test_god_routes`. Expected: PASS.
- [ ] **Step 5: Commit** `feat: Leaving Is Prohibited is an amber cell -- anyone may walk in, nothing gets out, hounds too`.

### Tasks 4-12: the nine new powers

Every power task has the same registration step, written once here and referenced as **[REG]**:
- A `PowerBook` row (`src/game/power_book.gd`) with key, name, path, blurb, `dp`, `cooldown`, `aim`, `shape`, `quiet`,
  `authority: "decree"`, and `modes` where the spec has them; the key in `FAMILY` (`:741`), and for loud powers in
  `REACH`/`IMPACT` (`:445/470`).
- The key in `Rules.POWER_KINDS` (`rules.gd:43`); a `Targeting.AREAS` entry (`targeting.gd:43`) of the right shape.
- Sounds: cues from `C:\BURIN_NITRO\SoundLibrary` (spec §6 lists each power's), added to `Sfx.CATALOG`; a quiet power's
  `q_<key>`; `python tools/audio/loudness.py` to add the `tools/audio/loudness.tsv` rows. Never copy Sonniss files
  into the public repo.
- The key in `tests/test_power_book.gd`'s lists (`:12/42/51`); `test_power_sounds.gd`'s quiet count `+1` for each
  quiet power.
- The key in `try/try_decree.bat` and `try.bat`'s key comment.
- Each power's own suite `tests/test_decree_<key>.gd`, registered in `run_all.gd`.

Each task's steps: **(1)** write its failing test, **(2)** run it (FAIL), **(3)** implement the effect and [REG],
**(4)** run its suite + `test_power_book` + `test_power_sounds` (PASS, no `SCRIPT ERROR`), **(5)** commit
`feat: <Name> (Decree, Tier N) -- <one line>`. The tests to write are listed per task.

### Task 4: Breathing Is Prohibited `breath` (`src/fx/decree/breathing_is_prohibited.gd`, `BreathFx`)

Consumes: `LawZone.circle(at, 2.5, [&"no_breath"], 8.0)`.
Constants: `RADIUS` 2.5, `HOLD_TIME` 8.0, `CHOKE` 3.0. Kill kind `&"choke"` (map onto an existing quiet collapse anim).
Tests:
- A person who stays inside 3.0 s dies with kind `choke`; at 2.9 s he is alive and choking (fleeing to the nearest edge).
- One who steps out at 2.0 s lives; stepping back in restarts his clock at 0 (dies 3.0 s after re-entry, not 1.0 s).
- A soldier chokes like anyone; a hound flees the circle and does not die.
- With a Leaving cell over the same spot, everyone inside the cell and the breath circle dies (the combo, spec §5.2).
- After 8 s nobody new chokes.

### Task 5: Redefine `redefine` (`src/fx/decree/redefine.gd`, `RedefineFx`)

Consumes: `LawMark.set_law(p, kind, 25.0, get_instance_id())`. Modes `criminal`, `officer`, `nobody` (Q/E).
Constants: `PICK_R` 1.5, `MAX_NAMED` 3, `SPAN` 25.0. A gilt word floats over each named person.
Tests:
- Mode `nobody` on three people within 1.5 marks exactly the three nearest; a fourth at 1.4 is skipped (`MAX_NAMED`).
- `criminal` on a soldier: the other soldiers fight him.
- `officer` on a believer in Hide the faithful: an inquisitor at 1.0 does not seize him; the believer still counts.
- After 25 s every mark is lifted; ending the effect early lifts them too.

### Task 6: Bound in Law `bound` (`src/fx/decree/bound_in_law.gd`, `BoundFx`)

Consumes: `LawMark.set_law(p, &"bound", 20.0, id)` (for the badge and cleanup), the follow-up interface
(`can_follow_up`, `follow_up(at, extra)`, `follow_up_area`) for the second click.
Constants: `REACH` 10.0, `SPAN` 20.0. Polls both each frame and mirrors the onset of: hurt (amount), knocked down,
stunned (seconds), asleep (seconds), held by a seizure (held where he stands while the first is held), dead
(kill kind `&"bound"`). A mirrored onset is tagged so it never mirrors back.
Tests:
- `a.hurt(30)` → `b` loses 30, once; no ping-pong (`a` loses 30 total).
- `a.sleep(10)` → `b` sleeps; `a` dies → `b` dies.
- A second click farther than 10 from the first is refused (cast not made, cooldown untouched).
- After 20 s, harm no longer passes. `b` freed mid-link → the effect drops the link without error.

### Task 7: Erasing Distance `erase` (`src/fx/decree/erasing_distance.gd`, `EraseFx`)

Consumes: `LawRubble.lay`, `Structure.damage/destroy`, `EnvironmentField.damage_lane`.
Constants: `MAX_LEN` 10.0, `CRUSH_W` 1.0, `CRACK_W` 2.0, `THROW_W` 3.0, `T_FOLD` 1.5. Stages per spec §5.5.
Tests:
- People within 1.0 of the line are pulled to its middle and killed (`collapse`); one at 1.5 is not killed.
- A building the line crosses is destroyed; one whose nearest edge is 1.5 away is cracked.
- After the spring-back, people within 3.0 are knocked down; law rubble lies along the line and closes walk cells.

### Task 8: Disorder `disorder` (`src/fx/decree/disorder.gd`, `DisorderFx`)

Consumes: `LawZone.circle(at, 5.0, [&"disorder"], 15.0)`; modifies the four choice points to ask
`crowd.in_law(p, &"disorder")`: `Person._flee_local` (worst direction: toward the danger), the guard's target pick
(farthest one in sight), `ShelterManager.try_shelter` (fails), `EvacuationManager.choose` (farthest gate).
Tests:
- In the circle a panicked citizen's flee target is closer to the danger than his start; outside the circle it is farther.
- A soldier in the circle picks the farthest of two suspects; outside, the nearest.
- `try_shelter` fails inside, succeeds outside; `choose` returns the farthest gate inside.
- No randomness: two runs with different rng seeds pick the same targets.
- crowd_check unchanged with no Disorder cast.

### Task 9: Eminent Domain `eminent` (`src/fx/decree/eminent_domain.gd`, `EminentFx`)

Consumes: `LawRubble.lay`, `Structure.destroy`, decor removal as Heaven's Door does.
Constants: `LENGTH` 10.0, `HALF_W` 1.0. Spec §5.7.
Tests:
- Every structure and decor overlapping the 10 x 2 strip is destroyed or removed; one 0.5 outside is untouched.
- A person in the strip ends outside it on the nearer side, knocked down, at half health; nobody dies from it.
- The strip's cells are walkable afterwards; law rubble lies along both long sides.

### Task 10: Fenced Rule `fenced` (`src/fx/decree/fenced_rule.gd`, `FencedFx`)

Consumes: `LawZone.circle(at, 7.0, [two kinds], 30.0)`; the choice points answer the kinds:
`no_running` (`hold_pace` at walking share), `no_arms` (guards neither strike nor seize: the fight and seizure checks
ask `in_law`), `no_doors` (`try_shelter` and leaving a building refused), `no_sight` (guard sight and witness reach
capped at 2.0), `no_leaving` (the zone's own clamp).
Modes: the ten pairs of the five rules, keys `run_arms`, `run_doors`, …, cycled with Q/E.
Tests:
- Mode list has 10 entries, each a distinct pair.
- `run_arms`: a soldier inside does not strike a citizen next to him; a runner inside moves at walking pace.
- `sight_leave`: a guard at 3.0 does not see a believer; a person at the fence cannot leave.
- Your faithful are bound too (a believer inside cannot run under NO RUNNING).
- After 30 s every rule lifts and pace holds are freed.

### Task 11: The Closing Cage `cage` (`src/fx/decree/the_closing_cage.gd`, `CageFx`)

Consumes: `LawZone.circle(at, 12.0, [&"no_leaving"], 30.0)` with its `radius` shrunk each frame from 12.0 to
`END_R` 0.75 (ring 1.5 across) over `CLOSE_TIME` 30.0; `Structure.crack/destroy`.
Rules per spec §5.9: people at the bars are pushed inward; one whose inward step is blocked by a structure the bars
have not reached is cut down (kill kind `collapse`); a structure cracks when the ring touches it and is destroyed when
the ring passes its centre; at the end everyone still inside dies. Visitors are pushed and cut too.
Tests:
- At t = 15 s the ring radius is about 6.4 (linear close); a person who stood at 10 is now inside 6.4.
- A person pinned against a wall the ring has not reached dies when the ring reaches him.
- A house the ring passed is destroyed; a house outside 12 is untouched.
- At the end nobody inside is alive; a person who stood outside 12 is untouched.
- Perf: with 220 people the effect's own `_fx_process` stays under 2 ms (measure in the test with `Time.get_ticks_usec`).

### Task 12: The Sealed Verdict `sealed` (`src/fx/decree/the_sealed_verdict.gd`, `SealedFx`)

Constants: `RADIUS` 10.0, `COUNTDOWN` 60.0. Quiet: no alarm is added at the cast; only the player's overlay shows the
circle and countdown (drawn on the god's overlay layer, not the world). At 60 s one bell-stroke cue plays and every
Person inside dies (kill kind `&"verdict"`); after that, bodies are found as usual.
Tests:
- The cast adds no alarm and no panic (`crowd.alarm` unchanged, nobody's mind changes) over 59 s.
- A person who walks in at 30 s and is inside at 60 s dies; one who walked out at 50 s lives.
- Exactly at 60 s, all inside die in the same frame.

### Task 13: The tree, icons, clips and sandbox

**Files:** `src/game/god/god_tree.gd:45` (decree row = spec §2), `tools/dev/make_power_icons.py` (nine new icons),
power clips as the other powers have them (`PowerBook.clip_path`), `src/sandbox/sandbox.gd:16` (`EFFECTS` gains the
ten Decree powers), `tests/test_god_tree.gd` (decree expectations), `tests/test_decree.gd`'s price list.
- [ ] Update `test_god_tree` to expect `[["noleave","breath"],["redefine","bound"],["erase","disorder"],["eminent","fenced"],["cage","sealed"]]`
  and `test_decree` to expect the new prices and the quiet set; run (FAIL); fill the row, icons, clips, sandbox; run
  (PASS); commit `feat: Decree's whole tree -- the user's picks, icons, clips, sandbox`.

### Task 14: The Decree bots on the new tree

**Files:** `tools/dev/routes/god_t1.gd:122-124` and `god_t1/{warning,tax,harvest,lamb,prayers}.gd` (`act_decree`),
`tools/dev/behaviour_check.gd` (`FT_USES` `"decree"` at `:5444` and First Taste's `"decree"` branches, `:3663`,
`:3838`, `:5755-5769`), `tools/dev/routes/god_hunts/*.gd` (LOADOUT `"decree"` and `act_decree` in all five), tests
naming Decree keys (`test_hunt_tools` PLAYS/LACKS/TIER1_ONLY, the Hunt suites' `AIM_REACH`), refs
`tools/dev/refs/god_t1_*.tsv` and `references.tsv` (only `*_decree_*` rows).
- Tier 1 loadout is `noleave` + `breath`. Hunts 2-5 draft at most 3 keys from `GodTree.keys_for("decree", tier)`
  within `TierBook.dp(tier)`.
- Gates: `bash tools/dev/god_gate.sh --only=<mission> --jobs=2` and `bash tools/dev/hunt_gate.sh --only=<hunt> --type=decree --jobs=2`.
  Wins ≥ 2/3, idle ≤ 45 s (60 where a ruling allows). No filler casts; no luck.
- A night Decree cannot win honestly is reported to the user with evidence, not tuned around (the Passage precedent).
- Re-record only the Decree rows (`refs_check.sh`).
- [ ] Rewrite, gate each night, re-record, run `test_hunt_tools`, `test_god_routes`, each Hunt suite (PASS); commit
  `dev: the Decree bots play the real Decree tree`.

### Task 15: Gate, merge check, land

- [ ] Import twice; full gate: four `run_part.gd --part=N --of=4` in parallel with `timeout 7500`; then crowd_check
  (`-535548941`). Expected: every part `failures=0`.
- [ ] `git fetch origin`; if `origin/feat/god-progression` moved (Death may have landed), commit, trial-merge with
  `git merge-tree --write-tree --name-only HEAD origin/feat/god-progression`; on any conflict stop and tell the user;
  else merge, check API clashes in `power_book.gd`, `god_tree.gd`, `run_all.gd`, `test_power_book.gd`,
  `test_power_sounds.gd` (both sides change counts), and re-run the full gate on the merged tree.
- [ ] Push `HEAD:feat/god-progression`. Post to #god-changelog; Ledger task + #board refresh; tell the other god
  sessions; update memory `kak-god-progression`.
