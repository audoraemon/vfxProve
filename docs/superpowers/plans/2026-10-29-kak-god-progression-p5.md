# KAK God Progression P5 "The Lantern Hunts" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Run it the KAK way: `.claude/skills/kak-milestone/SKILL.md` (sonnet implementers, a sonnet task review only for mission and shared-code tasks, dispatches from `.superpowers/sdd/godp5/implementer.md`, briefs `.superpowers/sdd/godp5/task-N-brief.md`).

**Goal:** parent spec §14 row P5 (the Hunt nights only; Eclipse is its own spec later), as the approved mission spec builds it: the five real Lantern Hunts replace P2's stand-ins, one per god tier, each a subclass of its type's director with new places and one Hunt-only rule (MS §1-§6); the draw, the def, the save and the screens carry the real Hunts (MS §1); every type wins every Hunt with the dev tree at that tier, or the gap is reported (MS §7, §9). No existing reference moves.

**Architecture:** four layers, in the order they are built.
1. **Rules and data (pure statics, P2/P3's shape).** `HuntBook` (`src/game/god/hunt_book.gd`) holds the five rows; `MissionBook` holds the five frames on their tiers' frames. `GodNight` draws and builds the real Hunt; `GodSlot.read()` keeps a Hunt id; `Mission.has_descent()` admits Hunt ids. Bank and forfeit are P2's untouched.
2. **Hooks and tools.** Three base directors read the numbers a Hunt changes from same-valued `tune_` vars (MS H11). `behaviour_check` plays each Hunt through per-type policies in `tools/dev/routes/god_hunts.gd`; `tools/dev/hunt_gate.sh` gates one Hunt a type at a time and judges the six from saved lines.
3. **The nights.** Five directors, each in its own file and worktree: `HideFaithfulDirector`, `SilenceWitnessDirector` (+ `WitnessDirector`, `WitnessObjective`), `ExpelInquisitorDirector`, `BreakHuntDirector`, `FaceHalcyonDirector`; then each Hunt's six per-type policies, tuning and 21 reference rows.
4. **Screens and Game.** The DEV tab's second row, the results' Hunt titles, photographs, FLOW's Lantern walk on the real Tier 1 Hunt.

The save's format is unchanged (`VERSION` 1; no new key).

**Tech Stack:** Godot 4.7.2 GDScript; headless suite `tests/run_all.gd` / `tools/dev/run_suite_parallel.sh`; references `tools/dev/refs_check.sh`; gates `tools/dev/gate.sh`, `tools/dev/hunt_gate.sh` (new); scripted players `tools/dev/behaviour_check.gd`; FLOW (`Game._flow_test()`, `--flow-test`); photographs `tools/capture.sh --show=`; landing `tools/dev/land.sh`.

**Specs:** mission spec `docs/superpowers/specs/2026-10-29-kak-god-p5-hunts.md` (cited **MS §n**; R1-R43, rulings H1-H15, open issues 1-9 as the user answers them); parent spec `docs/superpowers/specs/2026-10-26-kak-god-progression-design.md` (cited **§n**). Controller rulings C1-C8 below and in `.superpowers/sdd/godp5/rulings.md` (binding over this text). Pre-flight `.superpowers/sdd/godp5/preflight.md` (B1-B8 settled by C1-C8; its minors folded in below). As built: `docs/KAK_God_P2_*`, `docs/KAK_God_P3_*`, `docs/KAK_God_T1_Routes_Summary.md`, `docs/KAK_God_T1R_Rulings.md` (their rulings hold unless one below changes them). This plan's rulings: "Rulings" at the end (P5-1 to P5-22).

## Controller rulings (binding; the pre-flight's BLOCKING items)

- **C1 (B1).** No new var reuses a name in a base or its subclasses (`reliefs`, `beats`, `patrol_size`, `mates`, `post_names` exist). Convention: **`tune_<const in lower case>`**, grep-checked unused in `src`, `tools`, `tests`. Only the consts a Hunt changes that are read outside the `_plan()` / `_begin()` the Hunts replace get one (Task 2's list). `patrol_size` is already a var: set it, add nothing.
- **C2 (B2).** A Hunt subclass never redeclares a parent const name. Each Hunt's numbers are consts with its prefix (`HF_` Hunt 1, `SW_` 2, `EI_` 3, `BH_` 4, `FH_` 5; grep-checked unused), copied in `setup()` (before `super()` reads them) into the base's `tune_` vars and existing vars. Every const per task is listed in Tasks 4-8.
- **C3 (B3).** Hunt 2's witness: `_rings_himself()` stays true (RingerDirector's), `_take_rope()` a no-op, `_give_back()` a no-op, and the loss is his own distance check to the Temple's door each step; `_deliver()` is never reached, so a living bellkeeper can neither lose nor ring for him. The whole Ringer/Warning path is checked in MS §3 "The bell, never the witness's".
- **C4 (B4).** Hunt 4 overrides `_raise(i)` (never `_break()` on a null Structure) and every other Structure path (MS §5 Overrides list).
- **C5 (B5).** Hunt 3 overrides `_hide_goal()` and `_arrive()` (and `_begin()`, `_set_out()`, `fleeing_to_safe()`): no target ever runs to the Citadel but the captain at his round's end, warned; with the Temple down or burning a target hides in his own houses.
- **C6 (B6).** The five Hunts are a second row of the DEV tab; row 1 (the rite last) and its pins are unchanged; labels fit by `UiTheme.width`, shortened to the title if `"<title> (Hunt)"` does not. `test_board_test_mode.gd` and `test_tier_board.gd` are Task 14's, with the exact asserts below.
- **C7 (B7).** `_loadouts_real` asserts each type's exact missing-key list (Passage's empty).
- **C8 (B8).** `hunt_gate.sh` gets `--type=<type>` (one type's 3 seeds; plus the 3 none runs only with `--with-none`), `--save=<dir>` and `--judge=<dir>`; Tasks 9-13 run it per type and split their reference checks per type. Every foreground command is under 10 minutes (estimates in Task 3).

## Global Constraints

The full text is `.superpowers/sdd/godp5/global-constraints.md`; in short:

- Worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-god-p5`, branch `god/p5-hunts` (from `feat/god-progression` `f130d4f5` = tag `kak-god-t1r`); every command from its root; foreground only, each under 10 minutes; `G = /c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`; import after a new `class_name` or test file. The controller commits the spec, this plan and `.superpowers/sdd/godp5/` before cutting any group worktree (memory `trial-merge-needs-commit`).
- Per task: focused tests (RED first), `bash tools/dev/run_suite_parallel.sh 8` (`3` in a parallel group) -> `failures=0`, the brief's `refs_check.sh --only=...` (`--jobs=2` in a parallel group), the task's gate; FLOW only in Tasks 14 and 15, alone.
- **No existing reference moves:** `digest` `61267b7e90524d800bf1c3473a71146b`, `crowd_check` `-935602679`, every one of the 403 rows of `tools/dev/refs/*.tsv`. The 105 Hunt rows (Tasks 9-13) are added, never old ones re-recorded.
- **Never edit `GodTree.TABLE` or `GodTreeDev.TABLE`.** Tests and scripted play take keys from the tree at run time.
- Base directors: Task 2 alone edits `exodus_director.gd`, `ringer_director.gd`, `bell_ringers_director.gd` (the `tune_` vars). `escort_director.gd`, `warning_director.gd`, `assassinate_director.gd`, `hunt_director.gd` and every other existing director are not edited. A Hunt task that finds it needs another hook stops and reports NEEDS_CONTEXT; the controller rules.
- No PixelLab: text, drawn shapes and existing icons. 640x360; `UiTheme`. Endless Night writes only the god's file. Copy says **Might**.
- Copy quoted here is exact and *(my call)* unless the spec gives it. Numbers marked *fg* are the spec's first guesses, tuned only in Tasks 9-13.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; every `Ruling:` goes in the task's report.

## The open issues and the tasks they change

**Answered 2026-10-29: the user approved all nine recommended answers (C9)**, so none of the changes below applies; kept for the record. An answer other than the recommendation would have changed:
- **1 (Decree on Hunts 2-4):** Tasks 10-12 (the Decree policy, and a rule if the user gives one: a new small task before them) and Task 15 (`--except=decree` in the judged lines only if accepted).
- **2 (out of the walls on all five):** Tasks 4-8 (`_exit_reached` / `walls_stop` / the procession's fold) and the Passage policies in 9-13.
- **3 (Hunt 1 walks itself):** Task 4 (`_step_free()`), Task 9.
- **4 (the Descent):** Task 1 (`Mission.has_descent`, `_descent`, `_hunt_wishes`).
- **5 (the pooled median):** Task 3 (`hunt_gate.sh`'s verdict), Tasks 9-13.
- **6 (the loadout floor):** Task 3 (`problems()`), Tasks 9-13 (`LOADOUT`).
- **7 (Death on Face Halcyon):** Task 13's tuning order.
- **8 (the third fright wins at once):** Task 6.
- **9 (the plates):** Task 1 (`HuntBook.HUNTS`).

## Review Focus

The milestone review checks, with the tests that prove each:

1. **The stand-ins are gone and the Lantern's rules are P2's (MS §1, R1-R5):** at Notice 100 each tier draws its own Hunt, whatever the seed; the Hunt's def has the god's numbers; a closed game mid-Hunt is a lost Hunt; won/lost bank as P2. Tests: Task 1 `_hunt_for_real`, `_hunt_def`, `_read_keeps_hunt`, `_bank_hunt_real`; FLOW.
2. **Nothing else moved (R10):** every `tune_` var equals its const and is read in its place. Tests: Task 2 `_defaults_*` and its per-base reference runs; landing.
3. **No luck, no hidden loss (MS §0):** only the director's people seize, carry word, escort, guard; every instant loss is countdown-tagged and bannered first; win-first objective order; the search never finds a household inside (`HF_SLIP`); no witness near a living bellkeeper loses or rings; no warden runs to the Citadel. Tests: Tasks 4-8 `_no_luck`, `_slip`, `_keeper_inert`, `_no_citadel_flight`, `_win_beats_*`.
4. **Each Hunt's own rule (MS §2-§6):** the search and its trail; the mates' relay; the three frights; the standard taken up; the escort's break. Tests: Tasks 4-8 (named per Hunt).
5. **Every type can win (MS §7):** per Hunt six types x three seeds, each >= 2/3, idle <= 45 s, none 3/3 lost, pooled median 180-240 s, Decree's gaps on Hunts 2-4 reported. Tasks 9-13's judged lines.
6. **The screens hold (R7, R8, R41-R43):** WIN/LOSE fit at tiers 1-5; the DEV tab's second row fits and row 1's pins hold; each Hunt's results title; photographs; FLOW. Task 1 `_prepare_hunt_fits`; Task 14.

---

## Task order and parallelism

| # | Task | Model | Review | Parallel group |
|---|---|---|---|---|
| 1 | Hunt rules and data: `HuntBook`, `GodNight`/`GodSlot`/`Mission.has_descent`, the five frames, stubs and seeded anchors, P2 tests re-pointed | sonnet | **sonnet** | serial |
| 2 | Base hooks: `tune_` vars in Exodus, Ringer, BellRingers (MS H11, C1) | sonnet | **sonnet** | **A** (A1) |
| 3 | Hunt tools: `behaviour_check` arms, `god_hunts.gd` and five policy stubs, `hunt_gate.sh` | sonnet | **sonnet** | **A** (A2) |
| 4 | Hunt 1 `HideFaithfulDirector` (MS §2) | sonnet | **sonnet** | **B** (B1) |
| 5 | Hunt 2 `SilenceWitnessDirector`, `WitnessDirector`, `WitnessObjective` (MS §3) | sonnet | **sonnet** | **B** (B2) |
| 6 | Hunt 3 `ExpelInquisitorDirector` (MS §4) | sonnet | **sonnet** | **B** (B3) |
| 7 | Hunt 4 `BreakHuntDirector` (MS §5) | sonnet | **sonnet** | **B** (B4) |
| 8 | Hunt 5 `FaceHalcyonDirector` (MS §6) | sonnet | **sonnet** | **B** (B5) |
| 9 | Hunt 1 per-type policies, tuning, 21 rows | sonnet | **sonnet** | **C** (C1) |
| 10 | Hunt 2 per-type policies, tuning, 21 rows | sonnet | **sonnet** | **C** (C2) |
| 11 | Hunt 3 per-type policies, tuning, 21 rows | sonnet | **sonnet** | **C** (C3) |
| 12 | Hunt 4 per-type policies, tuning, 21 rows | sonnet | **sonnet** | **C** (C4) |
| 13 | Hunt 5 per-type policies, tuning, 21 rows | sonnet | **sonnet** | **C** (C5) |
| 14 | Screens and Game: the DEV tab's second row, results titles, `--show` photographs, FLOW's Lantern walk | sonnet | **sonnet** | serial |
| 15 | Landing on `feat/god-progression` (controller) | controller | opus milestone review | serial |
| 16 | Notes: `docs/KAK_God_P5_Summary.md`, `docs/KAK_God_P5_Rulings.md` | sonnet | none | serial |

Order: 1 -> A (2, 3) -> B (4-8) -> C (9-13) -> 14 -> 15 -> the opus milestone review, one fix wave, sonnet re-review -> 16 -> tag `kak-god-p5` (local; nothing pushed without the user's yes).

A group runs in parallel only in separate worktrees: branch `god/p5-t<N>` from the group's base commit, worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-god-p5-t<N>`, merged back into `god/p5-hunts` **in task order**, then suite 8 on the merged tree. **At most three worktrees at once** (machine load): B as 4-6 then 7-8, C as 9-11 then 12-13. Why B before C: a director must be reviewed and merged before six policies are written against it; why C per Hunt (not one shared task): the five Hunts share no code after Task 3, each tuning loop reruns 18 runs per round, and one shared task would be 30 policies and five tuning loops for one implementer, serially (P5-14). FLOW never runs in a group.

Merge notes: Task 1 seeds one anchor per Hunt in `mission_hints.gd` (a `# <id> (god P5 Task N)` comment line, a blank line between them, after `first_taste.cleanse`) and in `references.tsv` (five `# god P5 <Title> (Task N) -- rows below` comment lines at the end, a blank line between them); each Hunt task writes only under its own anchor, so merges do not touch the same lines. `mission_book.gd`: one function per Hunt.

**Shared files and their owners** (one hunk each):

| File | 1 | 2 | 3 | 4-8 (each its own) | 9-13 (each its own) | 14 |
|---|---|---|---|---|---|---|
| `src/game/god/hunt_book.gd` | creates | -- | -- | -- | -- | -- |
| `src/game/god/god_night.gd`, `god_slot.gd` | all P5 changes | -- | -- | -- | -- | -- |
| `src/game/mission.gd` | `has_descent` line | -- | -- | -- | -- | -- |
| `src/game/mission/mission_book.gd` | ids, `hunt_missions()`, `get_mission()`, `is_dev()`, five frame functions | -- | -- | its frame's director, objectives, camera, tour | -- | -- |
| `src/game/mission/mission_hints.gd` | five anchors | -- | -- | its rows under its anchor | -- | -- |
| `exodus_director.gd`, `ringer_director.gd`, `bell_ringers_director.gd` | -- | all | -- | -- | -- | -- |
| `src/game/mission/<id>_director.gd` (+ `witness_director.gd`, `witness_objective.gd`) | -- | -- | -- | creates | tuning consts only | -- |
| `tools/dev/behaviour_check.gd` | -- | -- | all | -- | -- | -- |
| `tools/dev/routes/god_hunts.gd`, `tools/dev/hunt_gate.sh` | -- | -- | creates | -- | -- | -- |
| `tools/dev/routes/god_hunts/<id>.gd` | -- | -- | creates stubs | `state()`, `act_shared()` | `LOADOUT`, `act_<type>`, `FILLED` | -- |
| `tools/dev/refs/references.tsv` | five anchors | -- | -- | -- | its rows under its anchor | -- |
| `tests/run_all.gd` | eight SUITES lines | -- | -- | -- | -- | -- |
| `tests/test_hunt_book.gd` | creates | -- | -- | -- | -- | -- |
| `tests/test_hunt_hooks.gd`, `test_hunt_tools.gd`, `test_hide_faithful.gd`, `test_silence_witness.gd`, `test_expel_inquisitor.gd`, `test_break_hunt.gd`, `test_face_halcyon.gd` | creates as stubs | fills hooks | fills tools | fills its own | -- | -- |
| `tests/test_god_lantern.gd`, `test_god_night.gd`, `test_endless_screens.gd`, `test_endless_flow.gd`, `test_faith_hub.gd` | re-points stand-in ids | -- | -- | -- | -- | `test_endless_flow.gd` adds |
| `src/game/ui/mission_board.gd`, `src/game/ui/results_screen.gd`, `src/game/game.gd`, `tests/test_board_test_mode.gd`, `tests/test_tier_board.gd`, `tests/test_results.gd` | -- | -- | -- | -- | -- | all |

---

### Task 1: Hunt rules and data

**Goal:** MS §1 and R1-R9: the real Hunts drawn and built, the save keeping a Hunt id, the Descent on a Hunt, the five frames (no director yet). P2's bank and forfeit untouched.

**Files:**
- Create `src/game/god/hunt_book.gd`, `tests/test_hunt_book.gd`; stubs (each `static func run(t) -> void: pass` with a `##` header naming its task) `tests/test_hunt_hooks.gd`, `test_hunt_tools.gd`, `test_hide_faithful.gd`, `test_silence_witness.gd`, `test_expel_inquisitor.gd`, `test_break_hunt.gd`, `test_face_halcyon.gd`.
- Modify `src/game/god/god_night.gd`, `src/game/god/god_slot.gd` (`read()` only), `src/game/mission.gd` (`has_descent()` only), `src/game/mission/mission_book.gd`, `src/game/mission/mission_hints.gd` (the five anchors only), `tools/dev/refs/references.tsv` (the five anchors only), `tests/run_all.gd` (eight SUITES lines after `test_god_routes.gd`), and the P2/P3 tests that pinned stand-ins.

**Interfaces (produces):**
- `MissionBook`: `HIDE_FAITHFUL := "hide_faithful"`, `SILENCE_WITNESS := "silence_witness"`, `EXPEL_INQUISITOR := "expel_inquisitor"`, `BREAK_HUNT := "break_hunt"`, `FACE_HALCYON := "face_halcyon"`; five functions `hide_faithful()` .. `face_halcyon()` on `_tier1()` .. `_tier5()` with `name` = the title, `brief`, `goal`, `goal_label`, `lose` exactly MS §2-§6, `lantern` (`KIND_WATCH` x4, `KIND_GAZE` for Tier 5), `default_loadout` (Hunt 1 `["whisper", "doom", "discord"]`, 2 `["doom", "whisper", "discord"]`, 3 `["doom", "smite", "whisper"]`, 4 `["doom", "smite", "heaven"]`, 5 `["whisper", "discord", "doom"]`), `director = MissionDirector` and `make_objectives` = `[ClockObjective.new(false, "Dawn", "dawn")]` until the Hunt's task (a night then runs to dawn), `camera_at` a placeholder near the first item; `static hunt_missions() -> Array[MissionDef]`; `get_mission()` searches it after `rite_missions()`; `is_dev(id)` true for a Hunt id. Not in `tier_missions()`, `all()`, `TierBook.MISSIONS`.
- `class_name HuntBook extends RefCounted` (MS H1): `const HUNTS := [{"tier": 1, "id": MissionBook.HIDE_FAITHFUL, "title": "Hide the faithful", "plate": "Lead your believers out before the inquisitors reach them"}, ...]` (titles and plates exactly P2's `GodNight.HUNTS`); `static has(id) -> bool`, `row(id) -> Dictionary` (copy, `{}`), `at_tier(tier: int) -> Dictionary` (clamped 1-5, copy), `ids() -> PackedStringArray`, `def(id) -> MissionDef` (null for a non-Hunt; `TierBook.checked(MissionBook.get_mission(id), id)`; appends `TierBook.UNAWARE_TAG` to `mission_tags` when the town's readiness <= `TierBook.UNAWARE_LEVEL`, as `TierBook.board()`).
- `GodNight`: `const HUNTS := HuntBook.HUNTS`; `hunt_for()` = `HuntBook.at_tier(slot.tier)` + `"tier"`; `static is_hunt(id) -> bool`; `def_for()`: a Hunt id (any Notice: a stale `in_night`, a test) -> `HuntBook.def(id)`, then `_apply_god()`, `def.clock = TierBook.clock(def.tier) + slot.extra_clock()`, `_dress_hunt()`, `_carry_gifts()`; else as today. `bank()`, `forfeit()` unchanged.
- `GodSlot.read()`: `in_night` and `last_mission` accept `HuntBook.has(id)` too (R4).
- `Mission.has_descent(def, on_board)`: `on_board and (TierBook.has(def.id) or HuntBook.has(def.id)) and def.city == &"aldermere"` (open issue 4).

- [ ] **Step 1: Failing tests** `tests/test_hunt_book.gd` (dev fill on for the file, off at the end; fixtures pick their type by search as P2's R3):
  - `_rows`: five rows, tiers 1-5 in order, titles and plates equal P2's strings; `has()`, `row("x") == {}`, `at_tier(0).tier == 1`, `at_tier(9).tier == 5`; no id is `TierBook.has()`.
  - `_frames`: each `HuntBook.def(id)`: `tier`; `clock`, `slots`, `dp_capacity` = `TierBook.clock/slots/dp(tier)`; `lantern` watch x4, gaze at 5; `unaware_town` at Tier 1 only; `goal.length() <= 91`, `lose.length() <= 96`; `is_dev(id)`; absent from `tier_missions()`, `TierBook.all()`, `dev_missions()`.
  - `_hunt_for_real`: tiers 1-5 at Notice 100: `hunt_for(slot).id == HuntBook.at_tier(tier).id`; `draw()` returns it for seeds 1-5 and with `last_mission` = that id; Notice 99 -> `{}`.
  - `_hunt_def`: `def_for(slot, id)` at tiers 1-5: `tier`, `slots == slot.slots()`, `dp_capacity == slot.max_might()`, `pool == slot.draftable()`, `clock == TierBook.clock(tier) + extra_clock()` with one clock bought, `gifts` the slot's, `name` the title.
  - `_read_keeps_hunt`: a slot file with `in_night` and `last_mission` = a Hunt id reads both back; `forfeit()` then gives the lost Hunt (seal, Notice 50, `HUNT_ABANDONED` line).
  - `_bank_hunt_real`: P2's won and lost banks with the real id (Notice 0 and `50 x tier` Faith; seal target and 50); `last_mission` = the Hunt id; `before_hunt` the night before; no best kept.
  - `_descent`: `has_descent(HuntBook.def(id), true)` true for all five; false off the board; a board id as before; a rite false.
  - `_hunt_wishes` (open issue 4's promise; P2's `_informer_t3_wishes` in `test_god_lantern.gd` is the model): for each Hunt at its tier, nights 0-3, the Descent hears the tier's wishes and none lands on the director's own people once the frame's director has set up (a NOTE, not a failure, while the frame's director is the empty one; Tasks 4-8 rerun it with their directors).
- [ ] **Re-point P2's tests (their shape changes, not only ids):** `test_god_lantern.gd`: `:130`'s "the stand-in is on the board" becomes "every Hunt id is `HuntBook.has()` and not `TierBook.has()`"; `_hunt_def` compares with `HuntBook.def(h.id)` plus the god's numbers (not `TierBook.board(h.id)`, null for a Hunt id); `_hunt_def_not_due` asserts a Hunt id builds the Hunt at any Notice (P5-2); `_board_at_informer` and the other `TierBook.board(at_tier)` checks stay (the parameter stays). `test_god_night.gd`, `test_endless_screens.gd` (`_prepare_hunt_fits` with the real defs: unchanged but for ids), `test_endless_flow.gd`, `test_faith_hub.gd`: every stand-in id read through `GodNight.HUNTS` / `HuntBook`. List each changed assert in the report.
- [ ] **Steps 2-4:** RED, implement, GREEN (suite 8 `failures=0`).
- [ ] **Step 5: References** `bash tools/dev/refs_check.sh --only='^(digest|crowd_check|calm|lamb_(none|play)_[123]|exodus_(none|play)_[123]|procession_(none|play)_[123]|first_taste_none_[123])$'` -> all OK (`procession_*` run `--board`: the Descent line).
- [ ] **Step 6: Commit** `feat: the real Lantern Hunts drawn and built -- HuntBook, five frames, a Hunt id kept in the save (god P5)`.

**Model:** sonnet; **review:** sonnet (every later task reads these; Review Focus 1).

---

### Task 2: Base hooks (MS H11, C1)

**Goal:** each Hunt subclass can set the numbers its base reads outside the `_plan()` / `_begin()` it replaces. Each constant below gets a same-valued instance var with a `##` comment `(god P5, MS H11)`, read in place of the constant **inside the base's methods** listed; the constant stays (outside readers, tests). Byte-identical by default.

**Files:** `src/game/mission/exodus_director.gd`, `ringer_director.gd`, `bell_ringers_director.gd`; fill `tests/test_hunt_hooks.gd`. No other base.

**The vars (names grep-checked unused in `src`, `tools`, `tests`; read sites from the pre-flight):**
- `ExodusDirector`: `tune_out_at` (`OUT_AT`: `_begin`, `out_due`, `tour`), `tune_shut_at` (`SHUT_AT`: `_begin`'s shut events and `tags`, each loop guarded by the array's size, so `[]` means no gate shuts; `_plan` and `tour` are replaced by both Hunts), `tune_hounds` (`HOUNDS`: `_begin`), `tune_per_house` (`PER_HOUSE`), `tune_believer_pace` (`BELIEVER_PACE`), `tune_need` (`NEED`: `lost_reason`, `hud_line`, `tags`, `hint_phase`), `tune_chain` (`CHAIN`: `out_due`), `tune_gate_watch` (`GATE_WATCH`: `gate_watched`), `tune_quiet` and `tune_beats` (`QUIET`, `BEATS` in `_quiet()`).
- `RingerDirector`: `tune_mates` (`MATES`: `_appoint_watchman`), `tune_mate_gap`, `tune_mate_side` (`_heel`, `_door_spots`), `tune_out_pause` (`set_out`).
- `BellRingersDirector`: `tune_set_out_at`, `tune_chain_wait` (`out_at`).
- Not given vars (the Hunts replace their readers): Exodus `HOUSE_POINTS`, `GATE_*`, `PATROL_SIZE` (`patrol_size` is already a var), `HUNT_AFTER` (`_come_out`, replaced), `RELIEF_AFTER`/`RELIEFS` (`_relieve_watch`, replaced by a no-op); BellRingers `POST_SPOTS`, `POST_NAMES` (`_begin`, replaced). `AssassinateDirector` and `HuntDirector`: nothing (Hunt 3 overrides `_alarm()`; Hunt 4's numbers are vars already).

- [ ] **Step 1: Failing tests** (`test_hunt_hooks.gd`): `_defaults_exodus`, `_defaults_ringer`, `_defaults_bell_ringers` (a fresh director's every `tune_` var deep-equals its const); `_exodus_small` (a test subclass setting `tune_per_house = 3`, `tune_need = 5`, `tune_shut_at = []`, `tune_hounds = 0` and its own `_plan()` with two house points, in the `test_lost_lamb.gd`-style world, appoints 6 believers in 2 households, adds no shut event and no searcher, and `lost_reason()` judges against 5); `_ringer_side` (`tune_mate_side = 0.85`: two door spots and two heels 1.7 apart); `_names_free` (a source scan: no `tune_` name is declared twice across the base and its subclasses).
- [ ] **Steps 2-4:** RED, implement, GREEN (suite 3 in group A).
- [ ] **Step 5: References** (`--jobs=2`; each call under 10 minutes, about 3-6 min): `'^(digest|crowd_check|calm)$'`; `'^exodus_(none|play|b_play)_[123]$'`; `'^ringers_(none|play|b_play|toll)_[123]$'` -> every row OK.
- [ ] **Step 6: Commit** `refactor: the numbers a Lantern Hunt changes, as same-valued tune_ vars in three base directors (god P5, MS H11)`.

**Model:** sonnet; **review:** sonnet (simulation files; Review Focus 2).

---

### Task 3: Hunt tools (`behaviour_check`, `god_hunts.gd`, `hunt_gate.sh`)

**Goal:** MS §7 R37-R38: each Hunt is a scenario; `--god=<type>:<tier> --dev-tree` plays that type's policy for the Hunt with a checked loadout; a type at a time is gated in one short command and the six are judged from saved lines.

**Files:** Modify `tools/dev/behaviour_check.gd`; create `tools/dev/routes/god_hunts.gd`, `tools/dev/routes/god_hunts/{hide_faithful,silence_witness,expel_inquisitor,break_hunt,face_halcyon}.gd`, `tools/dev/hunt_gate.sh`; fill `tests/test_hunt_tools.gd`.

**Interfaces:**
- `god_hunts.gd` (no `class_name`, preloaded as `GOD_HUNTS`; preloads `god_t1.gd` for `FILL`, `note_cast()`, `outside_spot()`, `road_ahead()`, `cast_mirror()`, `cast_bell()`, `plague_aim()`: no copies): `SCENARIOS` = `HuntBook.ids()` order; `FILES`; `static tier_of(scenario) -> int`; `static loadout(scenario, type, tier) -> PackedStringArray` (the file's `LOADOUT[type]`); `static problems(scenario, type, tier) -> PackedStringArray` (each key not in `GodTree.keys_for(type, tier)`, named; more than `GodSlot.BASE_SLOTS` keys; `PowerBook.might(key, 1)` summed over `TierBook.dp(tier)`); `has_policy`, `filled`, `act(scenario, type, bc, ctx)` (`type == ""` -> `act_shared`), `state(scenario, bc, ctx)`.
- Each `god_hunts/<id>.gd`: `const FILLED := []`; `const LOADOUT := {}` from MS "Plays" (Tier 1: the type's two real keys); `static state(bc, ctx) -> String` (stub `""`); `static act_shared(bc, ctx) -> String` and six `act_<type>(bc, ctx) -> String` stubs returning `""`.
- `behaviour_check.gd` (new hunks only, at their places, functions at the file's end): `const GOD_HUNTS := preload(...)`; in the loadout chain `elif scenario in GOD_HUNTS.SCENARIOS:` `mission.mission_id = scenario`, `powers` = the def's `default_loadout`, or with `--god` `GOD_HUNTS.loadout(scenario, type, tier)`; `var hunt_route := god_type != "" and route == "" and scenario in GOD_HUNTS.SCENARIOS`: a tier other than the Hunt's prints `BEHAVIOUR refused scenario=<id> god=<type>:<n> hunt_tier=<m>` and quits 1; `problems()` non-empty prints `BEHAVIOUR refused scenario=<id> god=<type>:<n> missing=<...>` and quits 1; the existing `outside()` refusal stays; the five ids join the hit-stop-off list; `match` arm `_ when scenario in GOD_HUNTS.SCENARIOS: await _god_hunt(scenario, god_type if hunt_route else "", case)`; `_god_hunt()` = `_scripted(scenario, case or "play", act, state)` with `_route_ctx(memo)` (as `_god_route()`). Header doc lines describe the arm.
- `hunt_gate.sh` (header as `god_gate.sh`'s): `--only=<id>` (required), `--type=<type>` (one type: `gate.sh <id> --god=<type>:<tier> --extra='--dev-tree' --jobs=N`, its 3 play seeds; with `--with-none` also the 3 none runs), `--save=<dir>` (writes that type's gate lines and per-run lines to `<dir>/<id>.<type>.txt`), `--judge=<dir>` (runs nothing: reads the six saved files and prints the 6-row table `wins/median/idle` and `hunt_gate <id> tier=N pass=K/6 none_lost=K/3 median=S [excepted=...] PASS|FAIL`; median: all winning play runs pooled; PASS iff every counted type's gate PASSed, none_lost 3/3, median 180-240; a missing type file is FAIL), `--except=<type,...>` (with `--judge`: those types print `excepted` and do not count), `--jobs=N`. Without `--type` or `--judge` it refuses (no 21-run call). Exit 1 on FAIL.
- **Time per foreground command** (the pre-flight's ~2-2.5 min a night run under load): `--type=<t> --jobs=3` = 3 runs in one wave, about 3-4 min; with `--with-none --jobs=3` = 6 runs in two waves, about 6-8 min; `--judge` seconds. A Hunt's full check is 6 such calls (35-40 min in all, each under 10).

- [ ] **Step 1: Failing tests** (`test_hunt_tools.gd`, preloading `god_hunts.gd`): `_scenarios` (== `HuntBook.ids()`; `GOD_T1.SCENARIOS` unchanged); `_files` (each has `act_shared`, six `act_<type>`, `state`, `FILLED`, `LOADOUT`); `_loadouts_dev` (dev fill on: `problems()` empty for every Hunt x type at its tier); `_loadouts_real` (C7; dev fill off, the real tree: `problems()` equals exactly, per Hunt at tiers 2-5: Ruin the Tier 2+ keys of its `LOADOUT` (Heaven Splitter, Tornado, Orbital ...), Death `glacial` (and any other Tier 2 key it plays), Veil `tsunami`/`nova`, Decree `magnify`, Dominion `madness`/`turncoat`/`priority` as its `LOADOUT` lists, **Passage empty** (its two real Tier 1 keys); at Tier 1 every type empty; the expected lists are computed from each `LOADOUT` minus `GodTree.keys_for(type, tier)` with `dev_fill` off and also written out literally in the test, so a changed `LOADOUT` fails it); `_problems_might` (a fake 3-key list over the tier's Might is named); `_gate_flags` (a source scan of `hunt_gate.sh`: `--type`, `--with-none`, `--save`, `--judge`, `--except` are parsed; no code path runs more than one type).
- [ ] **Steps 2-4:** RED, implement, GREEN (suite 3 in group A).
- [ ] **Step 5: Smoke (no bar):** `$G --headless --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=hide_faithful --case=none --seed=1` prints a result line and a checksum (the frame runs to dawn); `--scenario=silence_witness --god=ruin:1` is refused (`hunt_tier=2`); `--scenario=expel_inquisitor --case=play --god=passage:3 --dev-tree` prints `BEHAVIOUR god=passage:3` and drafts `thorns,mirror`; `bash tools/dev/hunt_gate.sh --only=hide_faithful --type=ruin --save=<scratch> --jobs=3` then `--judge=<scratch>` prints FAIL with five types missing.
- [ ] **Step 6: References** (`--jobs=2`): `'^(digest|crowd_check|calm|first_taste_(none|ruin_play|passage_play)_[123]|god_(ruin|passage)_lamb_play_[123]|lamb_(none|play)_[123]|exodus_play_[123])$'` -> OK (two calls if near 10 minutes).
- [ ] **Step 7: Commit** `dev: the Lantern Hunts in behaviour_check -- per-type policies at the Hunt's tier, hunt_gate.sh a type at a time (god P5)`.

**Model:** sonnet; **review:** sonnet (the gate's honesty: refusals, the pooled median; Review Focus 5).

---

### Tasks 4-8: the five Hunt nights (group B)

Shared shape for each (one task per Hunt, in its own worktree):
- **Files:** create `src/game/mission/<id>_director.gd` (class names below); modify `mission_book.gd` (its own frame function only: `director`, `make_objectives`, `camera_at`, `intro_from`), `mission_hints.gd` (its rows, under its anchor), `tools/dev/routes/god_hunts/<id>.gd` (`state()`, `act_shared()`: the shared plan with the default loadout); fill `tests/test_<id>.gd`.
- **Director contract:** the base's virtuals as MS lists them under "Overrides" (that list is the task's checklist: every item done or reported); **numbers are consts with the Hunt's prefix, never a parent's const name (C2)**, each with `##` (MS section, *fg*); `setup()` copies them into the base's `tune_` vars and existing vars before calling `super()`; `_walkable()` every spot; `_hold_all()` over its people every look; people looped as `for v: Variant in` with `is_instance_valid()` / alive before an order or a cast; banners and tags exactly MS; objectives win first; the base's `report()` keys kept and the Hunt's added.
- **Tests (each Hunt, RED first)** in the `test_lost_lamb.gd`-style world; a test may drive the director through public `test_*` hooks. Each also reruns Task 1's `_hunt_wishes` for its Hunt (no wish on its people).
- **Gate (no bar yet):** `bash tools/dev/gate.sh <id> --jobs=3` (6 runs in two waves, about 6-8 min) -> `none_lost=3/3`; the default-loadout play reported. References `--only='^(digest|crowd_check|calm)$'` (`--jobs=2`). Suite 3.
- **Model:** sonnet; **review:** sonnet (the mission's rules; Review Focus 3-4).

#### Task 4: Hunt 1 `HideFaithfulDirector extends ExodusDirector` (MS §2)

- **Consts (C2):** `HF_BELIEVERS` 6, `HF_PER_HOUSE` 3, `HF_NEED` 5, `HF_HOUSE_POINTS` [(-11.0, -1.5), (5.5, -12.0)] *fg*, `HF_HOUSE_WORDS`/`HF_HOUSE_NAMES` (north-west, north), `HF_GATES` (Main, Side: mouths, exits, labels), `HF_OUT_AT` [15, 110] *fg*, `HF_CHAIN` 45, `HF_SLIP` 30 *fg*, `HF_BELIEVER_PACE` 0.45 *fg*, `HF_POSTS` [(2.7, 14.6), (2.7, 16.8), (14.6, 9.0), (16.8, 9.0)], `HF_BEATS` = `LostLambDirector.BEATS`, `HF_PATROL_GAP` 1.8, `HF_SEARCHERS` 2, `HF_SEARCH_LIST` 6, `HF_SEARCH_STOP` 6 *fg*, `HF_SEARCH_GAP` 1.8, `HF_SEARCH_RELIEF_AFTER` 30, `HF_SEARCH_RELIEFS` 2, `HF_SIGHT` 2.5 (copied into the Escort type's sight where it reads one; if `SIGHT` is a const read in `_watching()`, the subclass overrides `_watching()` with `HF_SIGHT`), `HF_QUIET` 3.5. Set: `tune_out_at`, `tune_shut_at = []`, `tune_hounds = 0`, `tune_per_house`, `tune_believer_pace`, `tune_need`, `tune_chain`, `tune_beats = HF_BEATS`, `tune_quiet`, `patrol_size = 2`.
- **Interfaces:** `search_list() -> Array` (houses in order, by walk order from the Temple's door: four empty quiet dwellings, household 1's house second, household 2's last), `search_eta(i: int) -> float`, `trail_of() -> int` (-1 for none), `out_due(i)` (the soonest of time, chain, `search_eta - HF_SLIP`), `lost() -> int`, `lost_reason()` (`"faithful_lost"` at 2); the MS §2 overrides list (soldier `_post_to()`/`_takes_post()` in EscortDirector's `send_to_post` way, `_step_patrols()` and the first placement 1.8 apart, `_relieve_watch()` no-op, `_come_out()` without the searchers' row, `_exit_reached()` after the sight check).
- **Tests:** `_setup` (6 believers in 2 quiet houses, soldiers at the four posts pairwise > 1.6, patrol pairs 1.8 apart, the list's 6 tags counting down, banner `HIDE THE FAITHFUL`); `_walk_out` (out, a household walks its file to its gate at pace; a whispered lamp walks on after the linger); `_out_of_walls` (a believer set past the wall is out and sent off; `A BELIEVER IS OUT  1/5`); `_sight_first` (a believer set down 1.5 from the outer Main Gate post is seized, not out); `_slip` (the search slowed: household 2 comes out `HF_SLIP` s before it reaches the house; never found inside); `_chain`; `_trail` (`THE INQUISITION FINDS THE TRAIL`, they follow its lamp and seize on sight; done, they go on down the list); `_relief` (an inquisitor killed is replaced 30 s later, at most 2; a gate watchman killed is never replaced); `_strip_rows` (no "The Temple sends searchers" row; the search's and the households' rows); `_seize_free`; `_lose_two` (one lost: banner and DO NOT KILL tags; two lost: `lost_reason() == "faithful_lost"`, the objective FAILS); `_win_beats_loss`; `_no_luck` (a town soldier not in the watch never seizes); `_evacuation`.
- **Commit:** `feat: Hide the faithful -- the Inquisition searches house by house; the faithful walk out (god P5 Hunt 1)`.

#### Task 5: Hunt 2 `SilenceWitnessDirector extends BellRingersDirector`, `WitnessDirector extends RingerDirector`, `WitnessObjective extends StarsObjective` (MS §3, C3)

- **Consts (C2):** `SW_HOUSE_POINTS` [(-11.5, 2.0), (-11.0, 12.5), (12.5, 12.0), (12.5, -11.0)] *fg*, `SW_HOUSE_NAMES` (west, south-west, south-east, north-east), `SW_OUT_AT` [20, 75, 130, 185] *fg*, `SW_CHAIN` 45, `SW_POST_SIGHT` 6 (the base's `POST_SIGHT` equals it; read through the base), `SW_OUT_PAUSE` 3, `SW_MATES` 2, `SW_MATE_GAP` 1.2, `SW_MATE_SIDE` 0.85 *fg*, `SW_WITNESS_PACE` 0.65 *fg*, `SW_NEAR_WARN` 15. Set: coordinator `tune_set_out_at`, `tune_chain_wait`; each witness `tune_mates`, `tune_mate_gap`, `tune_mate_side`, `tune_out_pause`, `walls_stop = true`.
- **Interfaces:** coordinator `_begin()` replaced (MS §3 Overrides: the houses stone tonight, `WitnessDirector.new()` each with `tower`, `own_keeper`, `claimed`), `houses`, `out_at(i)`, `stopped()`, `word_in() -> bool`, `lost_reason()` (`"word"`); witness `_goal()` = `lantern_door()`, `_take_rope()` and `_give_back()` no-ops, `step()` (super, then: messenger alive, out of doors, within `TempleReport.REACH` of `lantern_door()` -> word in), `_relay_witness(at)` (the nearest of his own able mates within `Crowd.DOOM_WITNESS`; null -> the word dies), `_judge()` (the base's with `THE MATE RUNS ON`), `witnesses()`, `tags()`, `eta() -> float`, the walk at `SW_WITNESS_PACE`; `WitnessObjective.check()` FAILS `word` on `lost_reason() == "word"`, else `StarsObjective`'s.
- **Tests:** `_setup`; `_chain`; `_mates_apart` (1.7 apart, within 2.0 of him); `_relay_mate`; `_no_luck` (only townsfolk saw: the word dies); `_held_mate`; `_out_of_walls`; `_keeper_inert` (C3: a witness walked past the living bellkeeper within 0.8 neither loses nor calls the bell; with the keeper dead, a witness at the bell's foot never takes the rope; `bell.state` unchanged by him); `_word_in` (within 1.0 of the Temple's door: `lost_reason() == "word"`, FAILS; 15 s out the banner); `_win`; `_lantern` (a toll turns the Lantern, never a loss); `_no_keeper_tags` (no BELLKEEPER or bell-tower tag); `_evacuation`.
- **Commit:** `feat: Silence the witness -- four witnesses for the Temple; only their own mates carry the word (god P5 Hunt 2)`.

#### Task 6: Hunt 3 `ExpelInquisitorDirector extends AssassinateDirector` (MS §4, C5)

- **Consts (C2; no clash with Assassinate's):** `EI_ROUNDS` (three 4-stop rounds, MS §4) *fg*, `EI_VISIT` 6 *fg*, `EI_WARDEN_AT` [20, 70, 120] *fg*, `EI_CHAIN` 45, `EI_CAPTAIN_AT` 190 *fg*, `EI_CAPTAIN_STOPS` *fg*, `EI_GUARD_OFF` 0.9, `EI_ALARM_REACH` 4, `EI_HIDE` 12 *fg*, `EI_FRIGHTS` 3, `EI_FRIGHT_GAP` 8 *fg*, `EI_NEAR_WARN` 20. Set: `visit_seconds`, `hide_seconds`, `alarm_reach`, `guard_r`, `chain_wait`, `walls_stop = true`, `safe_at` (the Citadel's gate). Guards: the base's soldiers (`_appoint_guards()` / `_tends()` unchanged).
- **Interfaces:** `frights() -> int`, `fled() -> bool`, `captain_eta() -> float`; the MS §4 overrides: `_begin()` (super, then each warden into his own waiting house), `_set_out()`, `_alarm()` (super; on the captain, the count and on the third the flight: `THE CAPTAIN FLEES ALDERMERE`, stopped, `send_off()`), `_hide_goal()`, `_arrive()`, `fleeing_to_safe()`.
- **Tests:** `_setup`; `_chain`; `_round_loops` (a warden visits his 4 stops and loops; never walks to `safe_at`); `_fright_count` (a loud cast within 4 while he walks: 1; two in 8 s: 1; a guard felled: +1; while hiding: none); `_third_fright`; `_out_of_walls`; `_no_citadel_flight` (C5: with the Temple burning, then destroyed, an alarmed warden and the captain each hide in a house of their own round, never at the Citadel; `fleeing_to_safe()` false; the objective stays PENDING); `_captain_safe` (only after his last stop: FAILS `captain_safe`; tag countdown and the 20 s banner first); `_win_beats_loss`; `_evacuation`.
- **Commit:** `feat: Expel the inquisitor -- three lantern-wardens, then the captain: kill him or frighten him out (god P5 Hunt 3)`.

#### Task 7: Hunt 4 `BreakHuntDirector extends HuntDirector` (MS §5, C4)

- **Consts (C2; no clash with HuntDirector's):** `BH_HOUSE_POINTS` [(-4.0, 4.0), (7.0, 6.0), (-2.0, 12.5)] *fg*, `BH_MUSTERS` [(6.0, -13.5), (-14.0, 0.0), (14.0, -2.0), (-11.0, 14.0)] *fg*, `BH_ESCORTS` 2, `BH_ESCORT_OFF` 0.9, `BH_BEARER_AT` [20, 70, 120, 170] *fg*, `BH_CHAIN` 45, `BH_BEARER_PACE` 0.5 *fg*, `BH_GUARD_REACH` 1.5, `BH_TAKE_REACH` 1.0, `BH_LOSE_TAKEN` 2, `BH_NEAR_WARN` 15. Set: `has_head = false`, `chain`, `guard_reach`, `lost_word = "houses"`.
- **Interfaces:** `bearer(i) -> Person`, `guarded(i) -> bool`, `taken() -> int`, `house_eta(h) -> float`; the MS §5 overrides list in full (`_raise(i)`, `_raise_standard()`, `_guarding()`, `_guarded()`, `_keep_party()`, `_relieve()`, `_in_use()`/`_keep_held()`, `standard(i)`, `tags()`, the march, the take-up, the break through the base's `_break(i)`, `_found()`, `_quarry_point()`, `hint_phase()`, `strip_rows()`, `tour()`).
- **Tests:** `_setup`; `_chain`; `_raise_not_broken` (C4: at its time a step is raised and **not** broken; `standards` stays empty; no `damage_filter` set); `_march`; `_escorts_follow` (each look the escorts' posts are beside the bearer; a fallen escort is not replaced after 60 s); `_break_unguarded`; `_take_up`; `_out_of_walls`; `_taken`; `_lose_two`; `_win_beats_loss`; `_teardown_clean` (teardown with no Structure raises no error); `_evacuation`.
- **Commit:** `feat: Break the hunt -- four standards march on the believers' houses; an escort takes one up (god P5 Hunt 4)`.

#### Task 8: Hunt 5 `FaceHalcyonDirector extends ExodusDirector` (MS §6)

- **Consts (C2):** `FH_HOUSE_POINTS` [(-11.5, 2.0), (12.5, -11.0), (12.0, 12.0), (-11.0, 12.5)] *fg*, `FH_PYRE_OFF` (0, 2.5), `FH_ESCORT` 3, `FH_ESCORT_RING` 1.0, `FH_ESCORT_HOLD` 2, `FH_ESCORT_REACH` 1.6, `FH_PROC_AT` [30, 95, 160, 225] *fg*, `FH_CHAIN` 45, `FH_FORM` 8 *fg*, `FH_PROC_PACE` 0.5 *fg*, `FH_PYRE_REACH` 1.2, `FH_BURN` 12 *fg*, `FH_NEED` 3, `FH_LOSE_BURNED` 2. Set: `tune_out_at`, `tune_chain`, `tune_need`, `tune_shut_at = []`, `tune_hounds = 0`, `tune_per_house = 1`.
- **Interfaces:** `pyre_at`, `able_escort(i) -> int`, `freed() -> int`, `burned() -> int`, `burn_left(i) -> float`; the MS §6 overrides (`_step_held()` replacing the single-seizer march, the free, the burning, `_relieve_watch()` no-op, `_come_out()` without the searchers' row).
- **Tests:** `_setup`; `_chain`; `_form_and_walk`; `_one_seizer_not_free` (one escort off DUTY or dead: still marched; the Escort type's single-seizer release does not fire); `_free_break` (two escorts frightened, compelled by CALL THE GUARD, confused, whispered, frail, dead or inside: freed at once, `A BELIEVER IS FREED  1/3`); `_call_on_procession` (CALL THE GUARD clicked on the procession compels its escort); `_out_of_walls`; `_burn`; `_god_kill`; `_lose_two`; `_gaze`; `_win_beats_gaze`; `_strip_rows` (no searchers' row); `_evacuation`.
- **Commit:** `feat: Face Halcyon -- four processions to the pyre; free each by breaking his escort, unseen (god P5 Hunt 5)`.

---

### Tasks 9-13: per-type policies, tuning and references (group C, one per Hunt)

Shared shape (task N = Hunt N - 8):
- **Files:** `tools/dev/routes/god_hunts/<id>.gd` (`LOADOUT` per MS "Plays", `act_<type>` for all six, `FILLED`), `tools/dev/refs/references.tsv` (rows under its anchor), and only if tuning: its director's prefixed consts (each moved `##` says the round and the numbers that moved it).
- **Policy:** the type's route from MS (§2-§6 tables), in priority order, keys found at run time; the shared policy pieces from `god_t1.gd`; no filler casts (D38). Decree on Hunts 2-4: the best honest policy (delay), losses expected, no invented rule (open issue 1).
- [ ] **Step 1 (C8; six calls, each under 10 minutes):** `bash tools/dev/hunt_gate.sh --only=<id> --type=ruin --with-none --save=<scratch>/<id> --jobs=3` (6 runs, about 6-8 min); then `--type=death`, `veil`, `passage`, `decree`, `dominion` each without `--with-none` (3 runs, about 3-4 min); then `bash tools/dev/hunt_gate.sh --only=<id> --judge=<scratch>/<id>` -> the table and the `hunt_gate` line.
- [ ] **Step 2 (if a type misses):** first the policy (MS §7); then tune in MS §7's order for that Hunt, **at most three rounds**; a round that moves a director const reruns all six types (Step 1's six calls); a policy-only change reruns that type. Still missing: `DONE_WITH_CONCERNS` with the numbers. Decree on Hunts 2-4 is reported, not tuned around.
- [ ] **Step 3: Record** under its anchor: `<id>_none_1..3` (`--scenario=<id> --case=none --seed=N`) and `<id>_<type>_play_1..3` (`--scenario=<id> --case=play --seed=N --god=<type>:<tier> --dev-tree`), 21 rows. **Check per type (C8), each about 3-4 min:** `bash tools/dev/refs_check.sh --only='^<id>_none_' --jobs=3`, then `--only='^<id>_<type>_play_'` for each of the six types -> 21 OK in seven calls.
- [ ] **Step 4:** suite 3; references `--only='^(digest|crowd_check|calm)$'`; if a director const moved, the Hunt's own focused tests too.
- [ ] **Step 5: Commit** `test: every type plays <Title> -- per-type policies, 21 Hunt references (god P5 Hunt N)` (body: the `hunt_gate` line, the six gate lines, the tuning rounds).
- **Model:** sonnet; **review:** sonnet (the milestone's bar; Review Focus 5).

| Task | Hunt | `--god` tier | Rows (403 ->) |
|---|---|---|---|
| 9 | `hide_faithful` | 1 | +21 |
| 10 | `silence_witness` | 2 | +21 |
| 11 | `expel_inquisitor` | 3 | +21 |
| 12 | `break_hunt` | 4 | +21 |
| 13 | `face_halcyon` | 5 | +21 (508) |

---

### Task 14: Screens and Game (DEV tab, results titles, photographs, FLOW)

**Goal:** R7, R41-R43, C6.

**Files:** `src/game/ui/mission_board.gd`, `src/game/ui/results_screen.gd`, `src/game/game.gd` (`--show` names, `_flow_lantern()`), `tests/test_board_test_mode.gd`, `tests/test_tier_board.gd`, `tests/test_results.gd`, `tests/test_endless_flow.gd`.

**Interfaces:**
- **MissionBoard (C6):** `missions()` and `_missions_of(DEV_TIER)` are **unchanged** (row 1: the sandbox, the towns' missions, the rite last). New `dev_hunts() -> PackedStringArray` (`HuntBook.ids()` with `dev`, else empty); `static hunt_rect(i: int, count: int) -> Rect2` (row 2: five equal cards across 640 less `BOARD_MARGIN` with `CARD_GAP`, top `DEV_ROW2_TOP` = `CARD_TOP + CARD.y + 6` (298), height `DEV_ROW2_H` 40 *(my call)*); `hunt_label(id) -> String` = `"%s (Hunt)" % title` when every line of `UiTheme.wrap(it, room, UiTheme.SIZE_SMALL)` fits `room` (card width less `2 x HUNT_PAD` 4) in at most 2 lines, else the title; on the DEV tab the board's hint is drawn at y 344 (not 322) so it clears row 2; `hit()` and `click()` find row-2 cards (a click picks: `choose(id)`, emits `pick`); Down/Up move the selection between the rows on the DEV tab (Left/Right within a row) *(my call)*; `tab_of(id)` is `DEV_TIER` for a Hunt id. `card_title()` / `kind_lines()` of a Hunt id return `hunt_label(id)` / `["HUNT"]`.
- **ResultsScreen:** `ACT_TITLES` gains the ten reasons of MS §1 ("The results' title line") exactly.
- **Game `--show`** (fixture god and dev fill as P2/P3's): `prepare-hunt-1` .. `prepare-hunt-5`; `board-dev-hunts`; mission shots through `GodNight.def_for()`: `hide_faithful-start`, `hide_faithful-trail`, `silence_witness-start`, `silence_witness-relay`, `expel_inquisitor-start`, `expel_inquisitor-captain`, `break_hunt-start`, `break_hunt-taken`, `face_halcyon-start`, `face_halcyon-pyre` (each `-<rule>` set up through the director's public `test_*` hooks).
- **FLOW `_flow_lantern()`:** its doc comment and steps re-pointed to the real Tier 1 Hunt: step 2's seed rule keeps "neither the last night nor the Hunt" (the stand-in clauses go); step 4 checks `mission_id == "hide_faithful"`, `def.name == "Hide the faithful"`, tier 1, `lantern` watch, the night's director a `HideFaithfulDirector`; step 5 loses it through the real ending (`force_end(false, "dawn")`) and checks `last_mission == "hide_faithful"` in memory and in the file (R4); the results' title line is the Dawn's; the rest as P2. `_flow_rite()`'s Hunt-first step follows `HUNTS[0]` unchanged.

- [ ] **Step 1: Failing tests:**
  - `test_board_test_mode.gd`: **keep** `_dev_tab_rite` exactly (first_taste last in `missions()`, the Capital ids first, its title, kind line, fit with `card_rect(0, ids.size())`: row 1's count is unchanged at 7); **add** `_dev_tab_hunts`: with `dev`, `dev_hunts() == HuntBook.ids()`; none of the five in `missions()`; each `hunt_rect(i, 5)` is inside 640x360, below `card_rect(0, n).end.y`, above y 344, and clear of the others; each label's wrapped lines fit their card in at most 2 lines at `SIZE_SMALL` (`UiTheme.width`, printing the px), and a label that drops "(Hunt)" is exactly the title; a click on `hunt_rect(2, 5)`'s centre emits `pick` with `chosen == "expel_inquisitor"` and `tier == DEV_TIER`; without `dev`, `dev_hunts()` is empty and no Hunt is on any tab.
  - `test_tier_board.gd`: **keep** `_dev_town`'s exact list assert for `_missions_of(DEV_TIER)` (row 1 unchanged); **add** one check that `board.dev_hunts()` is `HuntBook.ids()` and that no `_missions_of(t)` for tiers 1-5 holds a Hunt id.
  - `test_results.gd` `_hunt_titles`: `ResultsScreen.title_for(true, r)` / `(false, r)` for the ten reasons gives MS §1's strings; never "THE CITY HAS FALLEN" nor "MANIFESTATION ENDED".
  - `test_endless_flow.gd` `_load_god_hunt_real` (a file with `in_night = "hide_faithful"`: `load_god()` gives the lost Hunt, the seal and 50, the file agrees).
- [ ] **Steps 2-4:** RED, implement, GREEN (suite 8).
- [ ] **Step 5: Photographs:** each name with `SCENE=res://scenes/game.tscn bash tools/capture.sh --show=<name> --capture`; look at each (WIN and LOSE fit; row 2 and the moved hint; tags, edge arrows and countdowns read; nothing over the slots, stack or strip); paths in the report.
- [ ] **Step 6: FLOW alone** (`tasklist | grep -i godot` first): `failures=0`; checks and time (T1R: 209 checks).
- [ ] **Step 7:** references `--only='^(digest|crowd_check|calm)$'`.
- [ ] **Step 8: Commit** `feat: the Lantern Hunts on screen -- the DEV tab's Hunt row, results titles, photographs, FLOW loses the real Hunt (god P5)`.

**Model:** sonnet; **review:** sonnet (Game wiring and FLOW; Review Focus 1, 6).

---

### Task 15: Landing on `feat/god-progression` (controller)

- [ ] Commit everything (memory `trial-merge-needs-commit`). `git log --oneline HEAD..feat/god-progression` (anything landed meanwhile); `git merge-tree --write-tree --name-only HEAD feat/god-progression`; clean -> merge; a conflict -> keep both blocks or stop and report.
- [ ] `bash tools/dev/land.sh --bench=kak-god-t1r` (this branch's base: import, suite, every reference, FLOW alone, the bench). **Its own trial merge targets `origin/feat/Develop-Main`** (P5 never merges there): if it stops on that step, run its steps by hand: import; `bash tools/dev/run_suite_parallel.sh 8` -> `failures=0`; `bash tools/dev/refs_check.sh --jobs=8 > <scratch>/refs.txt 2>&1` (background; ~2.5 h) -> `refs ok=508 bad=0`, `digest` and `crowd_check` OK; FLOW alone -> `failures=0`; `bash tools/dev/land.sh --bench-only --bench=kak-god-t1r` (background; waits for a quiet machine) -> the five pairs within ~1 fps (P5 adds per-frame work only on Hunt nights, none benched; a steady gap is a bug).
- [ ] The five Hunts judged on the merged tree: per Hunt, the six `hunt_gate.sh --only=<id> --type=<t> --save=<dir>` calls (background is the controller's choice) and `--judge=<dir>` (with `--except=decree` for Hunts 2-4 only if the user accepted open issue 1).
- [ ] A mover or a failure: find the task, fix in `fix: god P5 landing -- <what>`, rerun the step.
- [ ] The opus milestone review (one fix wave, sonnet re-review), Task 16, tag `kak-god-p5` (local), ff `feat/god-progression`. Nothing pushed without the user's yes; `feat/Develop-Main` never touched.

**Model:** controller; **review:** the opus milestone review.

---

### Task 16: Notes

- [ ] `docs/KAK_God_P5_Summary.md` in P3's summary's shape: what you asked (the five sketches, eight answers); what P5 built (MS §1-§7); how to see each Hunt (the DEV tab's Hunt row; a god at Notice 100 of each tier); the numbers in play (exact / *fg* / tuned with the rounds); the five per-type tables; the photographs; landing (gates, bench pairs vs `kak-god-t1r`); known issues (Decree's gaps, short pairs); not yet there (Eclipse; re-gates as tiers fill); needs you.
- [ ] `docs/KAK_God_P5_Rulings.md` in P3's rulings' shape: C1-C8 and any later C-rulings, MS H1-H15 and the open issues as answered, P5-1 to P5-22, the pre-flight's items, every task's `Ruling:` lines, the milestone review and fix wave. Each: what, why, cost if wrong.
- [ ] One Dev Ledger line per task in the report (the controller writes the Ledger and refreshes the board).
- [ ] Commit `docs: god P5 summary and rulings`.

**Model:** sonnet; **review:** none.

---

## Tuning (MS §7)

Only Tasks 9-13 tune, each its own Hunt, and only after its policies work the opposition as a player would. Order per Hunt as MS §7 (labels there; the prefixed consts here); **at most three rounds**; a round that moves a director const reruns all six types; each moved constant's `##` says the round and the numbers that moved it. A miss after three rounds is `DONE_WITH_CONCERNS` and goes to the user. Rules, not knobs: the 45 s chain, every wait under 60 s, the Gaze's weights, `HF_SLIP`, the 1.6 spread between opposition members.

## Rulings

Settled against the code at `f130d4f5` and the pre-flight. Each has why and the cost if wrong.

- **P5-1 (Task 1): `HuntBook` beside `RiteBook`; `GodNight.HUNTS` aliases it.** P2's screens and FLOW read `GodNight.HUNTS[0]`; the alias keeps them. Cost if wrong: a rename.
- **P5-2 (Task 1): a Hunt id builds the Hunt at any Notice.** `def_for()` keys on `HuntBook.has(id)`, not `hunt_for()`; bank and forfeit still key on the Notice (P2-3). P2's `_hunt_def_not_due` is re-pointed to say so. Cost if wrong: a forfeit of a stale Hunt id banks as an ordinary night (unreachable: the Notice only leaves 100 by the Hunt's bank).
- **P5-3 (Task 1): the frames carry a do-nothing `MissionDirector` until their task.** Cost if wrong: none (replaced in Tasks 4-8).
- **P5-4 (Task 1): `last_mission` keeps a Hunt id.** Cost if wrong: a line.
- **P5-5 (Task 1): the Descent on a Hunt** (open issue 4's recommendation), with `_hunt_wishes`. Cost if wrong: drop one term and flip `_descent`.
- **P5-6 (Task 2): one hooks task, only three bases, only the consts read outside the replaced `_plan()` / `_begin()`.** Cost if wrong: a later Hunt finds a missing hook (NEEDS_CONTEXT; a small serial fix).
- **P5-7 (Task 3): the policies live in `god_hunts/<id>.gd`.** Groups B and C never touch `behaviour_check.gd`. Cost if wrong: none.
- **P5-8 (Task 3): the loadout is checked, not chosen at run time.** Cost if wrong: a refusal names it.
- **P5-9 (Task 7): Hunt 4's standard is drawn over its bearer, not a Structure; `_raise(i)` is replaced (C4).** Cost if wrong: a blow at the pole, not the man, does nothing.
- **P5-10 (Tasks 4, 8): Hunts 1 and 5 subclass `ExodusDirector`** (MS H3), with the `tune_` vars and the overrides MS lists. Cost if wrong: more overrides.
- **P5-11 (Task 4): the search list is chosen by walk order** from the Temple's door, household 1's house second, household 2's last. Cost if wrong: a different order; `HF_SLIP` still holds.
- **P5-12 (Task 5): `WitnessObjective` subclasses `StarsObjective`** (it does not read `lost_reason()`). Cost if wrong: one file.
- **P5-13 (Task 6): Hunt 3 counts frights in its own `_alarm()` override; no base hook.** The base calls `_alarm()` through self. Cost if wrong: none.
- **P5-14 (Tasks 9-13): one per-type task per Hunt.** Cost if wrong: five more reviews than one shared task.
- **P5-15 (Tasks 9-13): Decree on Hunts 2-4 is recorded as it falls.** Cost if wrong: re-recorded at the planned re-gate.
- **P5-16 (groups B, C): at most three worktrees at once.** Cost if wrong: wall time.
- **P5-17 (Task 14): FLOW loses the real Hunt** (P2-14's shape); wins are the references'. Cost if wrong: a win walk later.
- **P5-18 (Task 14): photographs include Prepare at all five tiers.** Cost if wrong: none.
- **P5-19 (Task 15): `land.sh --bench=kak-god-t1r`, by hand where its Develop-Main trial merge stops it** (P2-16, P3-24). Cost if wrong: none.
- **P5-20 (all): the user's later tier fills re-gate their Hunt** (answer 2). Cost if wrong: none.
- **P5-21 (Tasks 1, 4-13): anchors seeded in `mission_hints.gd` and `references.tsv`** so parallel merges never touch the same lines (pre-flight minor 17). Cost if wrong: a textual merge conflict the controller resolves as a union.
- **P5-22 (Task 14): the DEV tab's Hunt row is compact (title only) and the hint moves below it on the DEV tab only.** Row 1 and the tier tabs are untouched. Cost if wrong: layout only.

## Needs the user (not blocking the build)

- MS §9's open issues 1-9 (Decree's gaps first); the section "The open issues and the tasks they change" says what each answer reaches.
- The copy: the spec's quoted strings are exact; banners, tags, hints and the results titles are my call.
- If a Hunt still misses after three rounds for a type other than Decree: the user chooses (a rule, a number, or a reported gap).
- Eclipse (its own spec), and the re-gates as the tree's tiers fill.
