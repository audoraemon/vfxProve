# KAK God Progression P3 "First Rite" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Run it the KAK way: `.claude/skills/kak-milestone/SKILL.md` (sonnet implementers, a sonnet task review only for the logic tasks, dispatches from `.superpowers/sdd/godp3/implementer.md`, briefs `.superpowers/sdd/godp3/task-N-brief.md`).

**Goal:** parent spec §14 row P3 ("Tier 1 to Tier 2"), as the approved mission spec builds it: the hub's **Awaken** button at the cap (§9.3), the **Rite** mission type and its director (mission spec §1), **Chain of the Forgotten** (§2), the first rite **The First Taste** (§3), winning (plate, tier + 1, +2 points, cap lifts, gift) and losing (Notice +25, retry next night) (§1, §5), and the first stolen gift **The Watchful Bell**, applied to later Endless nights only (§4). Every type wins the rite with its own Tier 1 (scripted check, §3.9). No existing reference moves.

**Architecture:** three layers, in the order they are built.
1. **Rules and data (pure statics, P1/P2's shape).** A new `RiteBook` (`src/game/god/rite_book.gd`) holds the rite rows (level, id, name, shards, victims, gift, plate copy) and the gift rows (name, effect, climb scale). `GodNight` learns rites beside Hunts: `awaken_state()`, `rite_for()`, `is_rite()`, a rite branch in `def_for()` (the rite's def at the god's slots, Might and Faith clock), in `bank()` (no Divine Power, no Faith, no best, `last_mission` untouched; won -> `GodSlot.awaken()` + the gift; lost -> Notice +25) and in `forfeit()` (a lost rite). Every `def_for()` copies the god's gifts onto a new `MissionDef.gifts`; the board, the campaign and the references never set it.
2. **The night.** `RiteDirector` (`src/game/mission/rite_director.gd`, base of all four rites) owns the shrine and its flame, shards, marked victims, the chain (aim, bite, drag, grip, Yank, free, sacrifice), breakers as an abstract list, the replacement rule and the report. `FirstTasteDirector` subclasses it with the lamplighters' rounds, the Watch's posts and Halcyon's clergy marches and cleanse. `MissionBook.first_taste()` is a Tier 1 frame with `lantern = "watch"`, no Descent (so no wishes, believers, Faith, ASCEND). Mission routes key **C** and the chain's click to the director; the HUD draws the chain plate above the slot row's right end, grip and cleanse rings on tags, a director strip row, and the win plate. The Watchful Bell is a `Crowd.climb_scale` (1.0 unless the def carries the gift) read at the three places `BellNetwork.climb` is set.
3. **Screens and Game.** Hub (Awaken button and key A, "Rite not yet written", gifts line), Prepare (`THE AWAKENING RITE`, its rows, the chain row; a GIFTS row on ordinary nights), Results (rite lines), Pause (the lost-rite confirm), the board's DEV tab (`The First Taste (rite)`), Game routing (`hub:awaken` -> the Hunt first, else the rite's Prepare), photographs and FLOW's rite walk.

The save's format is unchanged (`GodSlot.gifts` is already written and read; `VERSION` stays 1).

**Tech Stack:** Godot 4.7.2 GDScript; headless suite `tests/run_all.gd` / `tools/dev/run_suite_parallel.sh`; references `tools/dev/refs_check.sh`; the mission gate `tools/dev/gate.sh`; scripted players `tools/dev/behaviour_check.gd`; FLOW (`Game._flow_test()`, `--flow-test`); photographs `tools/capture.sh --show=`; landing by hand in `tools/dev/land.sh`'s order.

**Specs:** mission spec `docs/superpowers/specs/2026-10-28-kak-god-p3-first-taste.md` (cited **MS §n**; approved with all six recommended answers, its R1-R14 binding); parent spec `docs/superpowers/specs/2026-10-26-kak-god-progression-design.md` (cited **§n**). Controller rulings `.superpowers/sdd/godp3/rulings.md` (C1-C7; binding over this text). P1/P2 as built: `docs/KAK_God_P1_Summary.md`, `docs/KAK_God_P1_Rulings.md`, `docs/KAK_God_P2_Summary.md`, `docs/KAK_God_P2_Rulings.md` (their rulings hold unless one below changes them). This plan's rulings: "Rulings" at the end (P3-1 to P3-24).

## Global Constraints

The full text is `.superpowers/sdd/godp3/global-constraints.md`; in short:

- Worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-god-p3`, branch `god/p3-rite` (from `feat/god-progression` `a0185497`, P2 + its fix wave; tag `kak-god-p2`); every command from its root; foreground only, each under 10 minutes; `G = /c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`; import after a new `class_name` or test file.
- Per task: focused tests (RED first), `bash tools/dev/run_suite_parallel.sh 8` (`3` in a parallel group) -> `failures=0`, the brief's `refs_check.sh --only=...` (`--jobs=2` in a parallel group), the task's gate where it has one; FLOW only in Tasks 8 and 9, alone.
- **No existing reference moves (C3):** `digest` `61267b7e90524d800bf1c3473a71146b`, `crowd_check` `-935602679`, every one of the 286 rows of `tools/dev/refs/*.tsv`. The rite's new rows (Task 7) are added, never re-recorded old ones.
- **Never edit `GodTree.TABLE` or `GodTreeDev.TABLE` (C2).** Tests take keys from the tree at test time.
- No PixelLab (C4): text, drawn shapes and existing icons. 640x360; `UiTheme`. Endless Night writes only the god's file.
- C6: `god/t1routes` lands on `feat/god-progression` in parallel. Never edit the Tier 1 mission directors (`tax_collector`, `harvest`, `lost_lamb`, `first_prayers`, `warning`) or `tools/dev/routes/tier1_b.gd`; in `behaviour_check.gd` and `references.tsv` keep P3's hunks in their own blocks (a new match arm, new functions at the file's end, new rows in their own commented block at the end).
- Copy quoted here is exact and *(my call)* unless the spec gives it. Numbers marked *fg* are the spec's first guesses, tuned only in Task 7.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; every `Ruling:` goes in the task's report.

## Review Focus

The milestone review checks, with the tests that prove each:

1. **A rite is reached only at the cap, and the Hunt still comes first (MS §1, §9.3, P2-4):** Awaken shows only when capped below 50; dim with "Rite not yet written" when no rite exists; while `hunt_due()` both Awaken and A lead to the Hunt. Tests: Task 1 `_awaken_state`; Task 6 `_hub_awaken_*`; Task 8 `_awaken_routes`; FLOW.
2. **A rite's bookkeeping is exact (MS §1 R2-R4):** won -> tier + 1, +2 points, cap lifts, the gift once, Notice unchanged, no Divine Power or Faith, no best, `last_mission`/`before_hunt` untouched, the night and a seal tick; lost or abandoned -> Notice +25 (clamped, may bring the Hunt), still capped, Awaken offered again. Tests: Task 1 `_bank_rite_won`, `_bank_rite_lost`, `_forfeit_rite`, `_rite_draw_untouched`; Task 8 `_load_god_rite`; FLOW.
3. **The gift moves nothing it should not (MS §4 R12, C3):** `climb_scale` is exactly 1.0 without the gift, the board and campaign defs carry no gifts, `digest`, `crowd_check` and every row unchanged; with the gift every climb (setup, `raise_profile`, the reset) is x1.2 and a stand-in's x1.5 stacks. Tests: Task 2 `_climb_*`; Task 1 `_gifts_copied`, `_board_no_gifts`; references in Tasks 2 and 9.
4. **The chain cannot be lost to luck and never silently loses (MS §0, §2, §3.5):** only the director's breakers grip; every grip reset listed in MS §2 works; the drag takes at most 55 s; the cleanse is warned 10 s + ~90 s + 12 s ahead; the last shard wins even when a cleanse ends in the same frame. Tests: Task 3 `_grip_*`, `_drag_pace`, `_yank_once`; Task 4 `_cleanse_*`, `_win_beats_cleanse`, `_march_breaks`.
5. **Every type can win (MS §3.8-3.9, §5.2):** six types x three seeds, each type >= 2/3, idle <= 45 s, median 180-240 s, none loses 3/3; recorded as new reference rows. Task 7's gate table.
6. **The plate fits (MS §6 GAP):** the chain plate clear of the slots, stack, strip and tags at 3 and 6 slots. Task 5 `_chain_rect_*`; Task 8's photographs.

---

## Task order and parallelism

| # | Task | Model | Review | Parallel group |
|---|---|---|---|---|
| 1 | Rite rules and data: `RiteBook`, `GodNight` rites and gifts, `MissionDef.gifts`, `MissionBook.first_taste()` frame, test stubs | sonnet | **sonnet** | serial |
| 2 | The Watchful Bell: `Crowd.climb_scale` at the bell's three climb sites | sonnet | **sonnet** | **A** (A1) |
| 3 | `RiteDirector` and Chain of the Forgotten (bite, drag, grip, Yank, free, sacrifice, replacement) | sonnet | **sonnet** | **A** (A2) |
| 4 | `FirstTasteDirector`: lamplighters, the Watch, clergy marches and cleanse; hints; a basic `first_taste` scenario | sonnet | **sonnet** | **B** (B1) |
| 5 | Mission and HUD: key C, the chain's aim and click, the chain plate, rings, the director's strip row, the win plate | sonnet | none | **B** (B2) |
| 6 | Screens: hub Awaken and gifts, Prepare's rite and GIFTS rows, results' rite lines, pause confirm, the board's DEV tab | sonnet | none | **B** (B3) |
| 7 | The per-type scripted check: six types x three seeds, tuning (at most three rounds), new reference rows | sonnet | **sonnet** | serial |
| 8 | Game wiring, photographs and FLOW's rite walk | sonnet | **sonnet** | serial |
| 9 | Landing on `feat/god-progression` (controller; trial merge incl. t1routes, gates, bench vs `kak-god-p2`) | controller | opus milestone review | serial |
| 10 | Notes: `docs/KAK_God_P3_Summary.md`, `docs/KAK_God_P3_Rulings.md` | sonnet | none | serial |

Order: 1 -> A (2 and 3) -> B (4, 5 and 6) -> 7 -> 8 -> 9 -> the controller's opus milestone review, one fix wave, sonnet re-review -> 10 -> tag `kak-god-p3` (local; nothing pushed without the user's yes, C1). A group runs in parallel only in separate worktrees (P1's C11: branch `god/p3-t<N>` from the group's base commit, merged in task order, then suite 8 on the merged tree); otherwise its tasks run in order here. Task 7 comes before Task 8 because tuning may change the rite's numbers (Yank, break seconds, Watch count) that the photographs and FLOW show. FLOW runs only in Tasks 8 and 9, alone; never in a group.

**Shared files and their owners** (one hunk each; keep all on merge):

| File | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| `src/game/god/rite_book.gd` | creates | -- | -- | -- | -- | -- | -- | -- |
| `src/game/god/god_night.gd`, `god_slot.gd` | all P3 changes | -- | -- | -- | -- | -- | -- | -- |
| `src/game/mission/mission_def.gd` | `gifts` | -- | -- | -- | -- | -- | -- | -- |
| `src/game/mission/mission_book.gd` | `FIRST_TASTE`, `first_taste()` frame, `rite_missions()`, `get_mission()`, `is_dev()` | -- | -- | `first_taste()`'s director, objectives, camera, tour | -- | -- | -- | -- |
| `src/game/crowd/crowd.gd`, `bell_network.gd` | -- | all | -- | -- | -- | -- | -- | -- |
| `src/game/crowd/person.gd`, `src/fx/decree/leaving_is_prohibited.gd` | -- | -- | `chained` and its skip | -- | -- | -- | -- | -- |
| `src/game/mission/mission_director.gd`, `map_tag.gd` | -- | -- | `strip_rows()` virtual; `MapTag.ring` | -- | -- | -- | -- | -- |
| `src/game/mission/rite_director.gd` | -- | -- | creates | -- | -- | -- | tuning consts only | -- |
| `src/game/mission/first_taste_director.gd`, `mission_hints.gd` | -- | -- | -- | creates / its rows | -- | -- | tuning consts only | -- |
| `src/game/mission.gd` | -- | the `climb_scale` line | -- | -- | key C, chain aim, the win ending | -- | -- | -- |
| `src/game/ui/hud.gd` | -- | -- | -- | -- | all | -- | -- | -- |
| `src/game/ui/god_hub.gd`, `prepare_screen.gd`, `results_screen.gd`, `pause_menu.gd`, `mission_board.gd` | -- | -- | -- | -- | -- | all | -- | -- |
| `src/game/game.gd` | -- | -- | -- | -- | -- | -- | -- | all (routing, pause, `--show`, `_flow_rite()`) |
| `tools/dev/behaviour_check.gd` | -- | -- | -- | the `first_taste` arm, `_first_taste()` (shared plan, default loadout) | -- | -- | per-type answers | -- |
| `tools/dev/refs/references.tsv` | -- | -- | -- | -- | -- | -- | the new block | -- |
| `tests/run_all.gd` | five SUITES lines | -- | -- | -- | -- | -- | -- | -- |
| `tests/test_god_rite.gd` | creates | -- | -- | -- | -- | -- | -- | -- |
| `tests/test_watchful_bell.gd`, `test_rite_director.gd`, `test_first_taste.gd`, `test_rite_hud.gd` | creates as stubs | 2 fills its own | 3 fills its own | 4 fills its own | 5 fills its own | -- | -- | -- |
| `tests/test_faith_hub.gd`, `test_endless_screens.gd`, `test_board_test_mode.gd` | -- | -- | -- | -- | -- | adds | -- | -- |
| `tests/test_endless_flow.gd` | -- | -- | -- | -- | -- | -- | -- | adds |

---

### Task 1: Rite rules and data (`RiteBook`, `GodNight`, `MissionDef.gifts`, the rite's frame)

**Goal:** MS §1 (Hunt first, the rite's frame, won/lost/abandoned bookkeeping R2-R4), §4 (gifts stored and copied onto every later Endless def), §9.3 (when Awaken is offered). Pure rules and data; no screen, no director.

**Files:**
- Create: `src/game/god/rite_book.gd`, `tests/test_god_rite.gd`; stubs (each `static func run(t) -> void: pass` with a `##` header naming its task) `tests/test_watchful_bell.gd`, `tests/test_rite_director.gd`, `tests/test_first_taste.gd`, `tests/test_rite_hud.gd`.
- Modify: `src/game/god/god_night.gd`, `src/game/god/god_slot.gd` (`steal()` only), `src/game/mission/mission_def.gd` (`gifts`), `src/game/mission/mission_book.gd`, `tests/run_all.gd` (five SUITES lines, after `test_god_lantern.gd`).

**Interfaces (produces):**
- `class_name RiteBook extends RefCounted` (MS §1 "data rows in a new RiteBook"):
  - `const FIRST_TASTE := MissionBook.FIRST_TASTE`; `const WATCHFUL_BELL := "watchful_bell"`; `const WATCHFUL_CLIMB := 1.2` (MS §4).
  - `const RITES := [{"level": 10, "id": FIRST_TASTE, "name": "The First Taste", "shards": 3, "victims": 5, "answer": "clergy", "gift": WATCHFUL_BELL, "plate": "Halcyon's lamplighters keep his light in the streets. Drag three to Mira's shrine.", "lose_line": "The clergy cleanse the shrine, or dawn comes first."}]` (P4 appends 20/30/40).
  - `const GIFTS := {WATCHFUL_BELL: {"name": "The Watchful Bell", "effect": "The bell takes 20% longer to ring", "stolen": "a bell ringer takes 20% longer to start the toll", "climb": WATCHFUL_CLIMB}}`.
  - `static has(id: String) -> bool`; `static row(id: String) -> Dictionary` (a copy, `{}` if none); `static at_level(level: int) -> Dictionary` (the row whose `level` equals it, else `{}`); `static def(id: String) -> MissionDef` (`MissionBook.get_mission(id)` checked like `TierBook.checked()`; null for a non-rite); `static gift_name(id) -> String`, `static gift_effect(id) -> String` (`""` for an unknown id); `static plate_lines(id: String) -> PackedStringArray` = `["AWAKENED - %s" % TierBook.tier_name(level / 10 + 1).to_upper(), "+%d ability points" % GodSlot.AWAKEN_POINTS, "Stolen: %s - %s" % [gift name, gift "stolen"]]` (MS §5); `static climb_scale(gifts: PackedStringArray) -> float` = the product of known gifts' `climb` (1.0 for none or unknown ids).
- `MissionDef.gifts := PackedStringArray()` (MS §4): set only by `GodNight.def_for()`.
- `MissionBook.FIRST_TASTE := "first_taste"`; `static first_taste() -> MissionDef`: `_tier1(FIRST_TASTE, "The First Taste", [plate])`; `goal = "Drag three of Halcyon's lamplighters to Mira's shrine"`, `goal_label = "Three Lantern shards"`, `lose = lose_line`; `lantern = LanternWatch.KIND_WATCH` (MS §1 "the bell"); `default_loadout = ["doom", "whisper", "smite"]`; in Task 1 `make_objectives` = `[StagesObjective.new("Lantern shards", "shards"), ClockObjective.new(false, "Dawn", "dawn")]` and `director` stays null (Task 4 adds the flame's objective and the director). `static rite_missions() -> Array[MissionDef]` (`[first_taste()]`); `get_mission()` searches it after `dev_missions()`; `is_dev(id)` is also true for a rite id (P3-6).
- `GodSlot.steal(gift: String) -> bool`: appends once; false when already held or `gift == ""`.
- `GodNight` (MS §1, §9.3):
  - `const RITE_ABANDONED := "Night %d was abandoned: the rite is lost."`
  - `static awaken_state(slot) -> String`: `""` when not `capped()` or `level >= MAX_LEVEL`; `"rite"` when `RiteBook.at_level(slot.level)` exists; else `"unwritten"`.
  - `static rite_for(slot) -> Dictionary`: the row when `awaken_state() == "rite"`, else `{}`.
  - `static is_rite(id: String) -> bool` = `RiteBook.has(id)`.
  - `def_for(slot, id)`: a rite id -> `RiteBook.def(id)`, then `def.tier = slot.tier`, `_apply_god()`, `def.clock = TierBook.clock(slot.tier) + slot.extra_clock()` (P3-3); every def (night, Hunt, rite; the mission and each act) gets `gifts = slot.gifts.duplicate()` (MS §4).
  - `bank(slot, id, drafted, outcome)`: when `is_rite(id)` (checked first; P3-4), `_bank_rite()`: (1) `unsealed := slot.tick_seal()`; (2) `night += 1`, `in_night = ""`, `last_mission`, `before_hunt`, bests, Faith and Divine Power untouched (R4, R1); (3) `carried` counted, `loadout = drafted` (P3-5); (4) won (`outcome.won`) -> `slot.awaken()`, `slot.steal(row.gift)`, Notice unchanged (R3); lost -> `slot.add_notice(NOTICE_LOST_RITE)`. Returns P1/P2's keys (`divine_power` 0, `levels` [], `points` (2 or 0), `lost` 0, `capped`, `level`, `bar`, `believers` 0, `faith` 0, `faith_total`, `notice`, `notice_change`, `night`, `bests` [], `hunt` {}, `unsealed`, `hunt_next` = `slot.hunt_due()`) plus `"rite": {"id", "name", "won", "tier" (after), "points", "gift" (id or ""), "shards" (`outcome.rite.shards`, 0 absent), "need"}`.
  - `forfeit(slot)`: when `is_rite(slot.in_night)` (before the Hunt check): `tick_seal()`, `night += 1`, `in_night = ""`, `last_mission` untouched, `add_notice(NOTICE_LOST_RITE)`; line `RITE_ABANDONED % night` + `" " + NOTICE_UP % change` when it rose + `" " + UNSEALED % name` when a seal ended. Returns P2's keys plus `"rite"` as above (`won: false`).

- [ ] **Step 1: Failing tests** `tests/test_god_rite.gd` (dev fill on for the file, off at the end; a capped slot fixture: tier 1, level 10, `divine_power = need()`):
  - `_rite_book`: `has("first_taste")`, `at_level(10).id`, `at_level(20) == {}`, `row("x") == {}`, `plate_lines()` exact (`"AWAKENED - OMEN"`, `"+2 ability points"`, `"Stolen: The Watchful Bell - a bell ringer takes 20% longer to start the toll"`), `climb_scale([]) == 1.0`, `([WATCHFUL_BELL]) == 1.2`, `(["nosuch"]) == 1.0`.
  - `_awaken_state`: level 9 -> `""`; level 10 capped -> `"rite"`; a tier 2 slot at level 20 -> `"unwritten"`; level 50 -> `""`.
  - `_rite_def`: `def_for(slot, "first_taste")`: id, `tier == 1`, the god's slots, Might and pool (`draftable()`), clock `300 + extra_clock()` with one Faith clock bought, `lantern == "watch"`, `profile == "unaware"`; `gifts` equals the slot's.
  - `_gifts_copied`: a slot holding `watchful_bell`: an ordinary night's def, a Hunt's def (at 100%) and each act of a multi-act night carry it; a slot without: empty.
  - `_board_no_gifts`: for every `TierBook.all()` id, `TierBook.board(id).gifts` is empty; `MissionBook.first_taste().gifts` is empty; `board_def`-style `Mission.def_for(id, true, null)` likewise.
  - `_bank_rite_won`: won outcome (`{"won": true, "rite": {"shards": 3}}`): tier 2, points +2, `capped()` false, `cap() == 20`, `gifts == [watchful_bell]`, Notice and Faith unchanged, `divine_power` as before the bank re-levelled by `awaken()`, night +1, `last_mission` and `before_hunt` as before, no new `bests` key, `carried` counted, `loadout == drafted`; the dict's `rite.won`, `rite.tier == 2`, `rite.points == 2`, `rite.gift`, `notice_change == 0`, `hunt` empty.
  - `_bank_rite_twice`: a second won rite with the gift held does not add it twice (`steal()` false).
  - `_bank_rite_lost`: tier 1, still capped, Notice +25, `rite.won == false`, `rite.shards` from the outcome; from 80 -> 100, `notice_change == 20`, `hunt_next == true`.
  - `_forfeit_rite`: `in_night = "first_taste"`, Notice 25 -> 50; line exactly `"Night N was abandoned: the rite is lost. Lantern Notice +25%."`; `last_mission` untouched; a seal on its last night adds `UNSEALED`.
  - `_rite_draw_untouched`: after a banked rite, `draw(slot)` equals `draw()` of a copy that never played it with the same night count (R4: the draw is as if the rite had not been played).
  - `_rite_beats_hunt_flag`: a rite banked lost from Notice 100 (dev fixture) is still a rite (`hunt` empty, Notice stays 100 clamped).
  - `_mission_book_rite`: `get_mission("first_taste").id`, `is_dev("first_taste")`, `dev_missions()` unchanged, `tier_missions()` and `TierBook.all()` hold no rite.
- [ ] **Steps 2-4:** RED, implement, GREEN (suite 8 `failures=0`; P1/P2 suites unchanged).
- [ ] **Step 5: References** `bash tools/dev/refs_check.sh --only='^(digest|crowd_check|calm)$'` -> OK.
- [ ] **Step 6: Commit** `feat: the Awaken rite's rules -- RiteBook, rites banked and forfeited, stolen gifts on every later night (god P3)`.

**Model:** sonnet; **review:** sonnet (every later task reads these rules; Review Focus 1-3).

---

### Task 2: The Watchful Bell (`Crowd.climb_scale`)

**Goal:** MS §4: every bell climb x1.2 with the gift, the stand-in's x1.5 stacking, the Herald's descent untouched (R12, user answer 6); without it byte-identical.

**Files:** Modify `src/game/crowd/crowd.gd` (one var, one line in `raise_profile()`), `src/game/crowd/bell_network.gd` (`setup()`, `restore()`), `src/game/mission.gd` (one line before `_crowd.spawn()`); fill `tests/test_watchful_bell.gd`.

**Interfaces:**
- `Crowd.climb_scale := 1.0` (`##` MS §4, R12): multiplies `profile.bell_climb` wherever the climb is set.
- `BellNetwork.setup()` and `restore()`: `climb = crowd.profile.bell_climb * crowd.climb_scale`; `Crowd.raise_profile()`: `bell.climb = p.bell_climb * climb_scale`. The stand-in's `ESCORT_CLIMB` stays applied on top as today.
- `Mission` (the act's build, before `spawn()`): `_crowd.climb_scale = RiteBook.climb_scale(_def.gifts)`.

- [ ] **Step 1: Failing tests** (`test_watchful_bell.gd`, a `_world()` like `test_lost_lamb.gd`'s):
  - `_climb_default`: `climb_scale == 1.0`; `bell.climb == profile.bell_climb` exactly (8.0 Unaware/Organized; 5.0 God-Resistant).
  - `_climb_gift`: scale 1.2 set before `spawn()`: 9.6; God-Resistant 6.0; after `restore()` 9.6 again; after `raise_profile()` to a higher profile `p.bell_climb * 1.2`.
  - `_climb_stand_in`: with the gift, a stand-in's climb is `9.6 * BellNetwork.ESCORT_CLIMB` (14.4).
  - `_herald_untouched`: `LanternWatch.HERALD_DESCEND` path unchanged with the scale (the Herald's timing equal at 1.0 and 1.2).
  - `_mission_reads_def`: a `MissionDef` with `gifts = [watchful_bell]` started headless gives `crowd.climb_scale == 1.2`; with none 1.0.
- [ ] **Steps 2-4:** RED, implement, GREEN (suite `3` in group A, else 8).
- [ ] **Step 5: References** `bash tools/dev/refs_check.sh --jobs=2 --only='^(digest|crowd_check|calm|gates|rite|soldiers|warning_(none|doom|whisper|discord|mix)|(ringers|tax|informer|warning)_toll_[123]|ringers_(none|play)_[123])$'` -> all OK (none may move: R12).
- [ ] **Step 6: Commit** `feat: The Watchful Bell -- a bell climb x1.2 on nights after the rite, 1.0 everywhere else (god P3)`.

**Model:** sonnet; **review:** sonnet (simulation files; Review Focus 3).

---

### Task 3: `RiteDirector` and Chain of the Forgotten

**Goal:** MS §1 (Director row), §2 (the chain, entire), §3.6 (the replacement rule, generic): the base every rite subclasses. Numbers from MS §2.

**Files:**
- Create `src/game/mission/rite_director.gd`.
- Modify `src/game/crowd/person.gd` (`var chained := false`), `src/fx/decree/leaving_is_prohibited.gd` (a chained person is never set back, as one inside a building is not: R10), `src/game/mission/mission_director.gd` (`func strip_rows() -> Array[Dictionary]` virtual, default `[]`), `src/game/mission/map_tag.gd` (`var ring := -1.0`: a 0-1 fill drawn by the HUD, -1 none); fill `tests/test_rite_director.gd`.

**Interfaces (`class_name RiteDirector extends MissionDirector`):**
- Consts: `SHRINE := VigilFlameDirector.MIRA_SHRINE` (-17.6, 5.0); `SHRINE_REACH := VigilFlameDirector.SHRINE_REACH` (1.0); `COOLDOWN := 8.0` *fg*; `BITE := 1.0`; `DRAG_MAX := 55.0`; `PACE_MIN := 0.6`; `SIGHT := EscortDirector.SIGHT` (2.5); `GRIP_REACH := EscortDirector.TAKE_REACH` (0.9); `BREAK_SECONDS := 3.0` *fg*; `YANK_STEP := 1.5`; `YANK_STUN := 1.0`; `YANKS := 1` (R9; Task 7 may set 0); `PICK_R := 1.0` *(my call)*; `TICK := 0.25` (sight checks; bite, drag, grip and cooldown advance every frame).
- Copy: `NOT_VICTIM := "NOT A %s"` (the victim's word), `ONE_CHAIN := "ONE CHAIN AT A TIME"`, `NOT_READY := "THE CHAIN IS NOT READY"` *(my call)*, `YANK_USED := "THE CHAIN HAS PULLED ONCE"` *(my call)*, `SHARD_BANNER := "%s  %d/%d"` (rite name upper), `FREED_BANNER := "THE CHAIN BREAKS"` *(my call)*, `SHRINE_TAG := "MIRA'S SHRINE  %d/%d"`, `CAPTIVE_TAG := "CAPTIVE - SHRINE IN %s"`.
- `enum Chain { READY, BITE, DRAG, COOLDOWN }`; `var chain_state`, `var captive: Person`, `var shards := 0`, `var marked: Array[Person]`, `var safe: Array[Person]`, `var grip_by: Person`, `var grip := 0.0` (seconds), `var yanks_left`, `var cooldown_left`, `var flame_out := false`.
- Public API (Mission, HUD, the scripted player and FLOW call these; none reads input):
  - `need() -> int` (the RiteBook row's `shards`); `stages_done() -> bool` (`shards >= need()`); `hud_line() -> String` (`"Lantern shards %d/%d"`); `lost_reason() -> String` returns `""` (the flame's loss is its own objective: P3-10).
  - `chain_key() -> String`: `"aim"` when READY; `"yank"` after a Yank in DRAG; else the refusal (`ONE_CHAIN` in BITE/DRAG with no Yank left -> `YANK_USED`; `NOT_READY` in COOLDOWN).
  - `chain_at(ground: Vector2) -> String`: the marked victim nearest within `PICK_R` -> `chain(p)`; none marked there -> `NOT_VICTIM % victim_word()`.
  - `chain(p: Person) -> String`: refusals as above; else `captive = p`, `p.chained = true`, BITE for `BITE` s (he kneels), then DRAG along `crowd._grid` path to `_walkable(SHRINE)` at `drag_pace(path_length)`; "" on success. Quiet: no alarm, no danger.
  - `static drag_pace(path_len: float) -> float` = `maxf(PACE_MIN, path_len / DRAG_MAX)`.
  - `yank() -> bool`: in DRAG with `yanks_left > 0`: the captive moves `YANK_STEP` on along his path, the grip resets, its breaker stunned `YANK_STUN` s (held still, not gripping).
  - `drag_eta() -> float` (seconds left on the path at pace), `cooldown_left`, `chain_plate() -> String` (`"READY"`, `"DRAG %s"` eta, `"%s"` cooldown clock; `UiTheme.clock`).
  - `offer(p: Person) -> bool`: the sacrifice (a captive within `SHRINE_REACH`, or a test/FLOW hook on any marked victim): he dies on the stone, `shards += 1`, banner `SHARD_BANNER`, the flame grows a step (the shrine tag's `rise` + one step), `_answer(shards)` called (virtual), the chain to COOLDOWN.
  - `held(p: Person) -> bool` (static-ish helper for breakers): `p.held_by_god()` (Whisper, Discord, The Bell Lies' call: COMPELLED), Death Mark's frailty (`statuses.has(&"frail")`), bound by a Leaving Is Prohibited law, frightened (`PANIC`, `FLEE`, `SHELTER`), stunned by a Yank, inside, or dead.
  - `strip_rows()`: none in the base (subclasses add).
- The grip: each frame in DRAG, for the nearest `_breakers()` member not `held()` within `GRIP_REACH`: the captive stops, `grip += delta`, the captive's tag `ring = grip / BREAK_SECONDS`; the breaker `held()`, dead, or shoved further than `GRIP_REACH` (Thornwall) resets `grip` to 0 and the drag walks on; `grip >= BREAK_SECONDS` frees him. Breakers within `SIGHT` of the captive walk to him (`go_duty`); out of sight they go back to `_post_of(b)` (virtual). Only `_breakers()` ever grip (no luck).
- Freed: `p.chained = false`; he panics and runs for `lantern_door()`; still marked; within 1.0 of the door he is `safe` (unmarked). The chain goes to COOLDOWN.
- The captive dead away from the shrine (any cause): wasted; COOLDOWN; never a loss.
- A captive is held to his drag like `EscortDirector`'s bound charge (whisper shaken off, fearless) (P3-13); a Mirrorfold fold carries him through and the path is recomputed from where he lands.
- The replacement rule (MS §3.6): each TICK, `left()` = marked, alive, not safe (the captive counts); while `left() < need() - shards + 1`, `_replace()` (virtual) adds one.
- Evacuation: `_hold_all(_held_people(), evacuating)` each TICK over marked victims and breakers (MS §0).
- Virtuals for subclasses: `victim_word() -> String`, `_appoint_victims() -> Array[Person]`, `_breakers() -> Array[Person]`, `_post_of(b) -> Vector2`, `_answer(shard: int)`, `_replace()`, `rite_id() -> String`.
- Tags (`tags()`): each marked victim (gold, `victim_word()`, edge-arrowed, with a gold pip for his lantern: P3-14), the captive (`CAPTIVE_TAG % clock(drag_eta())`, edge, `ring` while gripped), the shrine (`SHRINE_TAG`, orange `MARK_SHRINE`, place).
- `report()`: `{"rite": {"id": rite_id(), "shards": shards, "need": need(), "flame_out": flame_out}}`.

- [ ] **Step 1: Failing tests** (`test_rite_director.gd`: an inner `class TestRite extends RiteDirector` with two victims at fixed walkable spots and one breaker; world as `test_lost_lamb.gd`'s):
  - `_refusals`: `chain_at` on nobody -> `"NOT A <word>"`; a second `chain()` while dragging -> `ONE_CHAIN`; `chain_key()` in cooldown -> `NOT_READY`; READY -> `"aim"`.
  - `_bite_then_drag`: the captive stands still `BITE` s, then walks; `drag_pace(30) == 0.6`, `drag_pace(45) == 45/55`; a drag from 40 units out reaches the shrine in <= 55 s (+ BITE) with no breaker.
  - `_sacrifice`: at the shrine he dies, `shards == 1`, banner `"<NAME>  1/N"`, `_answer(1)` called once, cooldown 8 s then READY.
  - `_grip_breaks`: a breaker reaching him grips; after 3 s the chain breaks (`FREED_BANNER`), the captive panics toward `lantern_door()`, is still marked; reaching the door he is `safe`.
  - `_grip_resets`: for each of: breaker killed, whispered, confused, compelled, frail (Death Mark), frightened, inside a Leaving Is Prohibited circle, shoved beyond reach: the grip returns to 0 and the drag resumes.
  - `_yank_once`: C in DRAG: he moves 1.5 on, a 2 s grip resets, the breaker stunned 1 s; a second `chain_key()` -> `YANK_USED`; next drag has its Yank again.
  - `_town_never_grips`: a soldier not in `_breakers()` standing on the path never stops him.
  - `_noleave_skips_chained`: a chained captive walks out of a `NoLeaveFx` circle; an unchained person is held (R10).
  - `_dies_on_the_way`: killing the captive away from the shrine: no shard, no loss, cooldown.
  - `_replacement`: with need 3, 0 shards and 4 marked alive, killing one calls `_replace()` once; making one safe does too.
  - `_hold_all`: an evacuation keeps victims and breakers on their errands.
  - `_report`: `report().rite` keys and values.
  - `_default_strip_rows`: `MissionDirector.new().strip_rows()` is empty; `MapTag.new().ring == -1.0`.
- [ ] **Steps 2-4:** RED, implement, GREEN (suite `3` in group A, else 8).
- [ ] **Step 5: References** `--only='^(digest|crowd_check|calm|warning_(none|mix)|tax_play_[123]|lamb_play_[123])$'` (`--jobs=2` in group A): `person.gd` and `leaving_is_prohibited.gd` changed, nothing may move.
- [ ] **Step 6: Commit** `feat: the Rite director and Chain of the Forgotten -- bite, drag, grip, Yank, the shrine's shards (god P3)`.

**Model:** sonnet; **review:** sonnet (the shared base of four rites; Review Focus 4).

---

### Task 4: `FirstTasteDirector` (The First Taste)

**Goal:** MS §3.1-3.7: the five lamplighters on their rounds, the Watch's four posts, Halcyon's two clergy marches and the cleanse, the banners, tags, strip row and hints; `MissionBook.first_taste()` complete; a basic `first_taste` scenario for the gate.

**Files:**
- Create `src/game/mission/first_taste_director.gd`, `src/game/mission/rite_flame_objective.gd`.
- Modify `src/game/mission/mission_book.gd` (`first_taste()`: `director`, objectives, `camera_at`, `intro_from`), `src/game/mission/mission_hints.gd` (its rows), `tools/dev/behaviour_check.gd` (a `first_taste` arm; `_first_taste(which)` and its helpers at the file's end; `first_taste` in the hit-stop-off list); fill `tests/test_first_taste.gd`.

**Interfaces (`class_name FirstTasteDirector extends RiteDirector`):**
- Numbers (MS §3.1-3.4): `ROUNDS` = the five 4-point loops of MS §3.2 (snapped with `_walkable()`); `LAMP_SECONDS := 4.0`; `POSTS := [Vector2(1.6, 13.6), Vector2(3.8, 13.6), Vector2(-8.0, 17.6), Vector2(-17.2, 10.0)]` *fg* (4 posts); `MARCH_AFTER := 10.0` *fg* (muster); `MARCHERS := [2, 3]` *fg*; `MARCH_GAP := 1.8`; `MARCH_PACE := 0.6` (times each marcher's own 0.85-1.2); `CLEANSE_SECONDS := 12.0`; `CLEANSE_NEED := 2`; `KNEEL_RING := 0.8` *(my call: kneel spots on a ring round the shrine)*.
- Copy: `OPENING := "THE FIRST TASTE"`, `ANSWER := "HALCYON ANSWERS - CLERGY MARCH ON THE SHRINE"`, `CLEANSE := "THE CLERGY CLEANSE THE SHRINE"`, `BREAKS := "THE MARCH BREAKS"`, `NEW_LAMPLIGHTER := "A NEW LAMPLIGHTER SETS OUT"`, `NO_CLERGY := "HALCYON'S CLERGY ARE GONE"` *(my call)*; tags `LAMPLIGHTER` (gold), `WATCH` (red), `CLERGY MARCH IN %s` (muster), `CLERGY - SHRINE IN %s` (the leader), `CLERGY` (the rest), `CLEANSING %s` (the shrine); strip row `"The clergy reach the shrine"`.
- Lamplighters (R13): for each round, the eligible `RESIDENT` or `LABORER` nearest its first lamp, `profile.faith = FAITHFUL` for the night, walking the loop and standing `LAMP_SECONDS` at each point, round and round; held through an evacuation.
- The Watch: `_free_soldiers(post, 1)` per post, at their posts; breakers; not replaced.
- `_answer(shard)`: shard 1 and 2 only: muster `MARCHERS[shard - 1]` `CLERGY` citizens nearest `lantern_door()` (then `FAITHFUL` residents if short: P3-15) at the door for `MARCH_AFTER` s, then walk in file `MARCH_GAP` apart along the grid's path to their kneel spots. A marcher frightened (PANIC/FLEE/SHELTER) or dead leaves the march for good; under `CLEANSE_NEED` able marchers the march breaks (`BREAKS`; survivors go home). A held marcher stays on it and walks on after (delay). Marchers are breakers while marching.
- The cleanse: `CLEANSE_NEED` marchers kneeling (within 0.5 of their spots, not `held()`) fill the ring for `CLEANSE_SECONDS`; fewer than 2 kneeling resets it to 0; full -> `flame_out = true` (`RiteFlameObjective` fails with `cleansed`).
- `_replace()`: the eligible `RESIDENT`/`LABORER` nearest `lantern_door()` sets out on the round whose lamplighter is gone (dead or safe), banner `NEW_LAMPLIGHTER` (P3-16).
- `strip_rows()`: for each walking march, `{"in": eta, "label": "The clergy reach the shrine"}`; for a muster, `{"in": muster_left, ...}`.
- `hint_phase()`: `"chain"` (READY or cooldown, no march near), `"drag"`, `"march"` (a march walking), `"cleanse"`.
- `tour()`: the shrine, the gate pair, back to `camera_at` = `Vector2(3.0, 10.0)` *(my call: the gate plaza, where lamplighters #3 and #4 are)*.
- `class_name RiteFlameObjective extends Objective` (new file `src/game/mission/rite_flame_objective.gd`): label "The shrine's flame", FAILED reason `cleansed` when `(rules.director as RiteDirector).flame_out`.
- `MissionBook.first_taste()`: `director = FirstTasteDirector`, objectives `[StagesObjective.new("Lantern shards", "shards"), RiteFlameObjective.new(), ClockObjective.new(false, "Dawn", "dawn")]` (in this order: the win is checked first, MS §6 "the winning strike never also loses").
- `MissionHints` rows `first_taste`, `.drag`, `.march`, `.cleanse` *(my call)*: "Press C, then click a lamplighter (gold): he walks to Mira's shrine (orange). Three win the rite.", "Keep the Watch (red) off him. C again to Yank him on once.", "The clergy (red) march on the shrine: stop two of them, or win first.", "The clergy cleanse the shrine: strike a kneeler now."
- `behaviour_check --scenario=first_taste --case=none|play --seed=N [--god=<type>:1 --dev-tree]`: loadout = `GodTree.starting(type)` with `--god`, else the def's default; `_first_taste(which)` through `_scripted()` with the **shared plan** (MS §3.9): chain the marked lamplighter with the shortest path to the shrine; strike any breaker within 4 units of the drag before he grips with whatever the loadout holds ready; Yank when a grip passes 1.5 s; after each shard, answer the march first only when it is within 45 s of the shrine. State line: `shards=%d/%d chain=%s march=%s cleanse=%.0f phase=%s`. Per-type answers are Task 7's.

- [ ] **Step 1: Failing tests** (`test_first_taste.gd`):
  - `_setup`: five lamplighters, FAITHFUL, each on a distinct round, tags gold `LAMPLIGHTER`; four Watch at the posts, pairwise > 1.6 apart (`2 x SilentDoom.RADIUS`); `OPENING` banner; chain READY.
  - `_rounds`: a lamplighter visits his four lamps in order, 4 s each, and loops.
  - `_drag_path`: for each round's first lamp, the grid path to the shrine passes within 2.0 of the Main Gate and is <= 45 units *(MS §2 "about 30-45"; a longer one is reported, not failed)*; `drag_pace()` keeps each <= 55 s.
  - `_watch_breaks`: a captive brought within 2.5 of a post is walked to and gripped; out of sight the watchman returns to his post.
  - `_march_one`: `offer()` one lamplighter: muster tag `CLERGY MARCH IN 0:10` with 2 clergy at the door; after 10 s they walk, kept >= 1.8 apart; the leader's tag counts down; `strip_rows()` has the row; `ANSWER` banner.
  - `_march_two`: the second `offer()` sends 3; the third sends none and the night is won.
  - `_march_breaks`: kill one of two marchers -> `BREAKS`, the other goes home; frighten one of three -> still marching (2 left); a whispered marcher stays on it.
  - `_cleanse_*`: two kneeling 12 s -> `flame_out`, the rules lose with `cleansed`; one killed at 6 s resets the ring; a held kneeler stops it.
  - `_win_beats_cleanse`: the third shard and a full cleanse in the same `_check_end()` -> won, reason `shards`.
  - `_replacement`: kill two lamplighters before any shard -> one new lamplighter from the Temple door on a freed round, `NEW_LAMPLIGHTER`.
  - `_evacuation`: an evacuation keeps lamplighters, the Watch and marchers on their errands.
  - `_mission`: `MissionBook.first_taste()` objectives in order, `lantern == "watch"`, director class, hints present for the four phases; the night has no Descent (`Mission.has_descent(def, true)` false).
- [ ] **Steps 2-4:** RED, implement, GREEN (suite `3` in group B, else 8).
- [ ] **Step 5: Gate (not recorded yet):** `bash tools/dev/gate.sh first_taste --jobs=2` -> none_lost 3/3 (dawn); play with the default loadout reported (no bar here: Task 7 owns it). References `--only='^(digest|crowd_check|calm)$'` (`--jobs=2`).
- [ ] **Step 6: Commit** `feat: The First Taste -- lamplighters on their rounds, the Watch, Halcyon's clergy march on Mira's shrine (god P3)`.

**Model:** sonnet; **review:** sonnet (the mission's rules; Review Focus 4).

---

### Task 5: Mission and HUD (key C, the chain plate, rings, the win plate)

**Goal:** MS §2 (key C, aim, refusals, the plate R7), §3.4-3.5 (rings, the strip row), §5 (the win plate and rise).

**Files:** Modify `src/game/mission.gd`, `src/game/ui/hud.gd`; fill `tests/test_rite_hud.gd`.

**Interfaces:**
- `Mission.CHAIN_KEY := KEY_C`; `static chains(event) -> bool` (C pressed, not echo, no modifiers); `var chain_aim := false`.
- Input (only when `_rules.director is RiteDirector`, after the intro and the legend checks, as the slot keys): C -> `chain_key()`: `"aim"` -> `chain_aim = true`, the slot unfocused; `"yank"` -> `UiSound ui_click`; a refusal -> `_hud.chain_refused(text)` (buzz, plate flash, a quiet banner). A left click with `chain_aim` (and not on a slot, the ASCEND plate or a wish) -> `chain_at(ground)`: `""` ends the aim; a refusal keeps it and shows the words. A slot key or slot click, Esc or right-click ends the aim. A click on the chain plate is C.
- The ending: a won rite (`_rules.won` and the director a `RiteDirector`): `_hud.rise(SHRINE, RITE_RISE)` and `_hud.show_rite_plate(RiteBook.plate_lines(rite_id))`, waiting `RITE_SECONDS := 4.0` *(my call)* in slow motion; `report_on_decision` already banks first.
- `Hud.CHAIN_SIZE := Vector2(100, 20)`, `Hud.CHAIN_GAP := 4.0`; `chain_shown() -> bool`; `chain_rect() -> Rect2` = `Rect2(slots_rect().end.x - 100, SLOT_TOP - CHAIN_GAP - 20, 100, 20)` (with no slots, centred on `SCREEN_W`); `chain_label() == "C CHAIN"`; `chain_state() -> String` (the director's `chain_plate()`); `var chain_aiming` (Mission sets it; the plate's frame gold while aiming); `chain_refused(text)`; drawn with an existing icon (the Death Mark or Leaving Is Prohibited icon, P3-17).
- `tag_layout()` keeps labels off `chain_rect()` as it keeps them off `slots_rect()`.
- `_draw_tags()`: a tag with `ring >= 0` gets a ring that fills clockwise (red), radius `MapTag.SIZE + 3`.
- `event_rows()` merges `_rules.director.strip_rows()` with the timeline's and the Lantern's, soonest first.
- `rise(at, scale := 1.0)` (MS §5 "larger": `RITE_RISE := 2.0`); `show_rite_plate(lines)`: a centred plate (y 120-200), drawn in place of the stack, strip and slots while it shows.

- [ ] **Step 1: Failing tests** (`test_rite_hud.gd`):
  - `_chain_rect_3` / `_chain_rect_6`: with 3 and 6 slots the plate is 100 x 20, ends at `slots_rect().end.x`, sits 4 px above `SLOT_TOP`, does not intersect any `slot_rect(i)`, `stack_rect()`, `events_rect()`, `ascend_rect()`, and is inside 640 x 360.
  - `_chain_states`: the plate's state reads `READY`, `DRAG 0:41`, `0:06` from a stub director.
  - `_chains_key`: `Mission.chains()` true for C, false for C+ctrl and for echo.
  - `_refused_shows`: `chain_refused("NOT A LAMPLIGHTER")` flashes the plate and queues the words.
  - `_tags_clear_chain`: a tag placed under the plate is moved off it by `tag_layout()`.
  - `_strip_merges`: a stub director's `strip_rows()` row sorts with the timeline's.
  - `_ring_default`: tags with `ring == -1` draw as before (the tag signature unchanged).
  - `_rite_plate`: `show_rite_plate()` hides the stack and slots while it shows.
- [ ] **Steps 2-4:** RED, implement, GREEN (suite `3` in group B, else 8). P1/P2 HUD tests unchanged.
- [ ] **Step 5: References** `--only='^(digest|crowd_check|calm)$'` (`--jobs=2`).
- [ ] **Step 6: Commit** `feat: Chain of the Forgotten in play -- key C, its plate above the slots, grip and cleanse rings, the rite's win plate (god P3)`.

**Model:** sonnet; **review:** none (input and drawing; Task 8's photographs and the milestone review cover them).

---

### Task 6: Screens (hub, Prepare, results, pause, the board's DEV tab)

**Goal:** MS §1 (Awaken, Prepare's rows, Leaving), §4 "Shown", §5 (results), R6 (the DEV tab).

**Files:** Modify `src/game/ui/god_hub.gd`, `prepare_screen.gd`, `results_screen.gd`, `pause_menu.gd`, `mission_board.gd`; tests `tests/test_faith_hub.gd`, `tests/test_endless_screens.gd`, `tests/test_board_test_mode.gd`.

**Interfaces and copy:**
- **GodHub:** buttons `Descend, Awaken, Skill Tree, Faith, Title` when `GodNight.awaken_state() != ""` (width `BUTTON_W_FIVE := 108.0`), else P1's four. Action `"awaken"` (click or **A**, any build) when `"rite"`; when `"unwritten"` the Awaken button is dim, a click or A buzzes and sets `line = RITE_UNWRITTEN` (`"Rite not yet written"`), and under `--dev` A still emits `awaken_dev` (P2's Hunt refusal kept); not capped: A under `--dev` as P2, else nothing. `awaken_shown() -> bool`, `awaken_dim() -> bool`. `gifts_line() -> String`: `""` or `"Stolen gifts: %s"` (names joined `", "`), drawn after `lines()` (P1's indices unchanged). Hint row adds `A: Awaken` when shown.
- **PrepareScreen:** `header_text()`: `"THE AWAKENING RITE"` (gold) when `GodNight.is_rite(mission.id)` and a god; Hunt and night as P2. `brief_rows()` for a rite: `RITE` (`"%s: %s" % [name, plate]`), `WIN`, `LOSE`, `IF WON` (`"Tier %d %s, +%d ability points, %s" % [tier + 1, TierBook.tier_name(tier + 1), AWAKEN_POINTS, gift name]`), `IF LOST` (`"Lantern Notice +%d%%; the god stays capped" % NOTICE_LOST_RITE`), `CHAIN` (`"Chain of the Forgotten (C): free"`). An ordinary night with gifts: `GIFTS` (each gift's effect, `"; "`-joined) in place of `CITY` (P3-8); a Hunt: unchanged (no room, P2's T3).
- **ResultsScreen:** `rite_called(result) -> String`: `"Awakening Rite: %s  -  %s"` (name, the tier played), drawn in place of the mission line (as `hunt_called`). `god_lines()` for a rite: `"Divine Power: none - the rite feeds no bar"`; won: `"AWAKENED: Tier %d %s"`, `"+%d ability points"`, `"Stolen: %s - %s"` (name, stolen line); lost: `"Lantern shards %d/%d"`, `"The god is still capped. Awaken again when ready."`; then P2's Notice line (with its change), unsealed, next-Hunt, `Night N`. No believers line on a rite (R1). Colours: the AWAKENED and Stolen lines gold; the capped line red. The bar under the first line shows the slot's re-levelled bar.
- **PauseMenu:** `var rite := false` (set by Game); `CONFIRM_RITE := "Abandon the rite and it is lost: Lantern Notice +%d%%. The god stays capped."` (the real rise after the clamp, from `notice`), with `" The Lantern Hunts next."` appended when it reaches 100; fits `CONFIRM_WIDTH` in two lines.
- **MissionBoard:** the DEV tab lists `MissionBook.rite_missions()` ids **after** the towns' (P3-7: `_flow_dev_town`'s slice stays); the card's title `"%s (rite)" % name`, kind line `"RITE"`.

- [ ] **Step 1: Failing tests:**
  - `test_faith_hub.gd`: `_hub_awaken_rite` (capped level 10: five buttons, `awaken_shown()`, A and a click emit `awaken`; the row fits 640), `_hub_awaken_unwritten` (tier 2 level 20: dim, A without dev sets `RITE_UNWRITTEN` and emits nothing; with dev emits `awaken_dev`), `_hub_awaken_hidden` (level 9: four buttons, A without dev does nothing), `_hub_awaken_hunt` (capped at 100%: A emits `awaken` and Game routes it, Task 8), `_hub_gifts` (none: `""`; one: exact), `_hub_lines_unchanged`.
  - `test_endless_screens.gd`: `_prepare_rite` (header, the six labels, IF WON and IF LOST exact, every row fits: measured like P2's `_prepare_hunt_fits`), `_prepare_gifts_row` (a gifted night: GIFTS replaces CITY; no gifts: P2's rows; a Hunt: P2's rows), `_god_lines_rite_won`, `_god_lines_rite_lost`, `_rite_called`, `_pause_rite` (25% -> `+25%`; 80% -> `+20%` and the Hunt line; before the clock: `CONFIRM_FREE`).
  - `test_board_test_mode.gd`: `_dev_tab_rite` (dev: `first_taste` last in `missions()` on the DEV tab, title `"The First Taste (rite)"`; not dev: absent; the capital ids still first).
- [ ] **Steps 2-4:** RED, implement, GREEN (suite `3` in group B, else 8).
- [ ] **Step 5: References** `--only='^(digest|crowd_check|calm)$'` (`--jobs=2`).
- [ ] **Step 6: Commit** `feat: the rite on screen -- Awaken at the cap, THE AWAKENING RITE on Prepare, the rite's results, the lost-rite confirm, the DEV tab (god P3)`.

**Model:** sonnet; **review:** none (screens; FLOW and the milestone review).

---

### Task 7: The per-type scripted check (MS §3.8-3.9, §5.2) and new references

**Goal:** prove every one of the six `GodTree.RING` types wins The First Taste with its own Tier 1 at level 1; record the rite's references.

**Files:** `tools/dev/behaviour_check.gd` (per-type answers in `_first_taste_answer(type, ...)`), `tools/dev/refs/references.tsv` (a new commented block at the end), and only if tuning: `rite_director.gd` / `first_taste_director.gd` consts (with their `##` updated to say the round and why).

**The policy (MS §3.8's "answers" columns, in priority order; keys from `GodTree.starting(type)` at run time, C2):**
- Ruin (smite, ember): Smite each watchman as the drag nears him; Smite one marcher (the seen kill frightens the other). Ember a house by the gate plaza only when two watchmen stand together.
- Death (deathmark, pestilence): Death Mark the gate pair at 0:00 and 0:20; mark ahead of each drag; Pestilence on a muster.
- Veil (doom, blight): Blight the Bell Tower at 0:00; Doom one watchman per cast, unseen; Doom two marchers.
- Passage (thorns, mirror): Mirrorfold in on the gate-plaza path, out on the shrine road past the outside post; Thornwall under a gripping breaker; delay marches (Thornwall across the gate mouth, Mirrorfold the march back inside); win by speed.
- Decree (noleave, belllies): Leaving Is Prohibited on the gate pair as the drag passes (the captive walks out: R10); CALL THE GUARD pulls the shrine-road post away (R11); circle the march every 20 s; ALL IS WELL if the bell is being climbed.
- Dominion (whisper, discord): Whisper each watchman away ahead of the drag; Discord the gate pair; Whisper marchers back toward the Temple; Discord the file.
- **Bar (MS §3.9):** per type, `play` wins >= 2/3 seeds, idle <= 45 s, median of wins 180-240 s; `none` loses 3/3.

**Command per type:** `bash tools/dev/gate.sh first_taste --extra='--god=<type>:1 --dev-tree' --jobs=3` (six runs each).

- [ ] **Step 1:** Run the six gates; table per type and seed (won, reason, time, idle, shards, checksum).
- [ ] **Step 2 (if a type misses):** first make that type's policy work the opposition as a player would (aim ahead of the drag, answer breakers before they reach 0.9). Then tune **in MS §3.9's order, at most three rounds**, rerunning all six types after each round (one constant moves every type): to make the rite **easier** when a type misses on wins: `BREAK_SECONDS` 3 -> 4, then the Watch 4 -> 3 posts (drop the shrine approach), then march 2's count 3 -> 2, then `MARCH_AFTER` 10 -> 15; when Ruin or Veil clear **under 180 s** median: `YANKS` 1 -> 0 first (P3-19). Still missing after three rounds: stop, report `DONE_WITH_CONCERNS` with the numbers (the controller asks the user).
- [ ] **Step 3: Record** (in a block headed `# god P3 (2026-10-28): The First Taste, the per-type rite check (Task 7)`): `first_taste_none_1..3` (`--scenario=first_taste --case=none --seed=N`) and `first_taste_<type>_play_1..3` (`--scenario=first_taste --case=play --seed=N --god=<type>:1 --dev-tree`), 21 rows (286 -> 307). Check them: `bash tools/dev/refs_check.sh --only='^first_taste_' --jobs=6` -> 21 OK.
- [ ] **Step 4:** suite 8; references `--only='^(digest|crowd_check|calm)$'`; if a director const was tuned, Tasks 3-4's focused tests too.
- [ ] **Step 5: Commit** `test: every type wins The First Taste -- the per-type scripted check, 21 rite references (god P3)` (body: the six gate lines, the tuning rounds).

**Model:** sonnet; **review:** sonnet (the milestone's riskiest bar; Review Focus 5).

---

### Task 8: Game wiring, photographs and FLOW's rite walk

**Goal:** MS §1 (Awaken routed, Hunt first, Leaving, the pause), §5 (results, after), §9.1 forfeit through `load_god`; photographs (MS §6 GAP at 3 and 6 slots); FLOW walks Awaken -> a rite won -> Tier 2 and a rite lost.

**Files:** `src/game/game.gd` (`next_screen` map `"hub:awaken": Screen.PREPARE`; `_on_hub_action("awaken")`; `_open_pause()`'s `rite`; `--show` entries; `_flow_rite(step)` called after `await _flow_lantern(step)`), `tests/test_endless_flow.gd`.

**Interfaces:**
- `_on_hub_action("awaken")`: `god.draftable()` empty -> nothing (as Descend); `god.hunt_due()` -> exactly Descend's path (`mission_id = GodNight.draw(god)`, the Hunt; P2-4); else `mission_id = GodNight.rite_for(god).id`, `loadout = god.loadout`, `on_action("hub:awaken")`. A `static Game.awaken_target(slot) -> String` (the id Awaken opens) so a suite can prove it.
- `_open_pause()`: `_pause.rite = _in_endless and god != null and GodNight.is_rite(mission_id)`.
- Nothing else: `_build_mission()`, `_on_clock_started()`, the bank and `load_god()` already go through `GodNight` (Task 1).
- `--show` names (with `_show_endless()`'s fixture god and the dev fill): `hub-awaken` (capped level 10), `hub-unwritten` (tier 2, level 20), `hub-gifts` (tier 2, the gift), `prepare-rite`, `prepare-gifts`, `results-rite-won`, `results-rite-lost` (from `GodNight.bank()` on a fixture slot, not hand-written: P2's Task 4 M5), `pause-rite`; mission shots through the first_taste def built by `GodNight.def_for()`: `first_taste-start` (the intro's end: tags, the Watch, the chain plate READY, 3 slots), `first_taste-six` (6 slots: the plate clear of the row), `first_taste-drag` (a captive gripped: the ring), `first_taste-march` (after `offer()`: muster, leader tag, strip row), `first_taste-cleanse`, `first_taste-win` (the plate).

- [ ] **Step 1: Failing tests** (`test_endless_flow.gd`): `_awaken_routes` (`awaken_target()`: capped -> `first_taste`; capped at 100% -> the Hunt's id; uncapped -> `""`), `_load_god_rite` (a slot file with `in_night = "first_taste"`: `load_god()` gives Notice +25, the exact `RITE_ABANDONED` line, tier unchanged, `last_mission` unchanged, the file agrees; opened again nothing more), `_rite_bank_writes` (`bank_god_night()` of a won rite then `write_god()`: the file reads tier 2, the gift, points).
- [ ] **Steps 2-4:** RED, implement, GREEN (suite 8).
- [ ] **Step 5: Photographs:** each `--show` name with `SCENE=res://scenes/game.tscn bash tools/capture.sh --show=<name> --capture`; look at each (text fits, nothing overlaps the buttons, the slots, the stack or the strip; the chain plate clear at 3 and 6 slots); paths in the report.
- [ ] **Step 6: FLOW's rite walk** (`_flow_rite(step)`, its steps in a doc comment; `dev = true`, dev fill on; restored at the end as `_flow_lantern()`'s `out`):
  1. Fixture written to slot 1's file, hub reopened: tier 1, level 10, bar full (capped), Notice 50, no seal, `last_mission` noted. The hub shows `Awaken` (`awaken_shown()`), no gifts line.
  2. Hunt first: Notice set to 100 (fixture), A -> Prepare's `header_text() == "THE LANTERN HUNT"`; Back to the hub (free). Notice back to 50.
  3. A -> Prepare: `"THE AWAKENING RITE"`, `brief_rows()` labels and IF LOST exact. MANIFEST, past the intro: `god.in_night == "first_taste"`, the night's def tier 1, `lantern == "watch"`, the director a `FirstTasteDirector`, `_hud.chain_shown()`; pause: `confirm_line()` is `CONFIRM_RITE`'s 50 -> `+25%`; resume.
  4. Win the real way: `offer()` three marked lamplighters (the director's own sacrifice path: banners, marches). Results: `result.god.rite.won`, `god_lines()` hold the AWAKENED and Stolen lines, `rite_called()`; the god and its file: tier 2, points +2, `cap() == 20`, gifts `[watchful_bell]`, Notice 50, Night +1, `last_mission` as noted, Faith and Divine Power unchanged.
  5. Continue: the hub has no Awaken, `gifts_line()` exact. Descend: a Tier 2 mission; Prepare's GIFTS row; the def's `gifts`. Back (free).
  6. Fixture: the god back to tier 1 capped (written), Notice 50. Awaken, MANIFEST, past the intro; lose the real way: `_mission.rules().force_end(false, "dawn")`. Results: `rite.won == false`, the capped line; the god: tier 1, Notice 75, Night +1, still capped. Continue: Awaken still shown.
  7. Title; the board's save bytes unchanged since the walk's start (C7); out.
  Run **FLOW alone** (`tasklist | grep -i godot` first): `failures=0`; report the checks and time (P2: 175 checks, ~235 s; this adds three night loads, about +1.5 min). Over 10 minutes: report it, do not cut steps without the controller.
- [ ] **Step 7:** suite 8; references `--only='^(digest|crowd_check|calm)$'`.
- [ ] **Step 8: Commit** `feat: Awaken in Game -- the Hunt first, then the rite; photographs; FLOW wins and loses a rite (god P3)`.

**Model:** sonnet; **review:** sonnet (Game wiring; Review Focus 1-2).

---

### Task 9: Landing on `feat/god-progression` (C1, C6, C7)

Run by the controller, `land.sh`'s steps by hand (its trial merge targets `feat/Develop-Main`, which P3 never touches):

- [ ] `git fetch origin`; local `feat/god-progression` vs this branch: `git log --oneline HEAD..feat/god-progression` (t1routes may have landed, C6). Commit nothing uncommitted first (memory `trial-merge-needs-commit`); `git merge-tree --write-tree --name-only HEAD feat/god-progression`; clean -> `git merge --no-ff feat/god-progression`; a conflict (likely `behaviour_check.gd`, `references.tsv`, `routes_t1.tsv`) -> keep both blocks, or stop and report. Check API clashes by hand: t1routes' Tier 1 policies against Task 4's shared helpers; any Tier 1 reference it re-recorded is its own.
- [ ] Import (exit 0); `bash tools/dev/run_suite_parallel.sh 8` -> `failures=0`.
- [ ] References, every row: `bash tools/dev/refs_check.sh --jobs=8 > <scratch>/refs.txt 2>&1` (background; ~2 h): 307 + t1routes' rows, `grep -v ' OK$'` only headers; `digest`, `crowd_check` OK; the 21 rite rows OK.
- [ ] FLOW alone -> `failures=0` (checks, time).
- [ ] Bench vs `kak-god-p2` (C7): `bash tools/dev/land.sh --bench-only --bench=kak-god-p2` (background; waits for a quiet machine) -> the five pairs within ~1 fps (rerun a noisy pair; memory `kak-m1-perf-debt`). P3 adds per-frame work only on a rite night (not benched), so a steady gap elsewhere is a bug.
- [ ] A mover or a failure: find the task, fix in `fix: god P3 landing -- <what>`, rerun the step.
- [ ] The opus milestone review (one fix wave, sonnet re-review), Task 10, tag `kak-god-p3` (local), ff `feat/god-progression`. Nothing pushed without the user's yes; `feat/Develop-Main` never touched.

**Model:** controller; **review:** the opus milestone review.

---

### Task 10: Notes

- [ ] `docs/KAK_God_P3_Summary.md` in P2's summary's shape: what you asked; what P3 built by section (MS §1-§5, §9.3, §11.2-§11.5); how to see it (the DEV path to a capped god: a fixture or ten levels; the DEV tab's `The First Taste (rite)`); the numbers in play (exact / *fg* / tuned, with Task 7's rounds); the per-type gate table; the photographs; landing (gates table, bench pairs); known small issues; not yet there (rites 2-4 and their gifts P4, Hunts and Eclipse P5, the title switch); needs you.
- [ ] `docs/KAK_God_P3_Rulings.md` in P2's rulings' shape: C1-C7, any controller rulings added, MS R1-R14 (as approved), P3-1 to P3-24, every task's `Ruling:` lines, the milestone review and fix wave. Each: what, why, cost if wrong.
- [ ] One Dev Ledger line per task in the report (the controller writes the Ledger and refreshes the board, memory `kak-dev-ledger`, `kak-discord-changelog`).
- [ ] Commit `docs: god P3 summary and rulings`.

**Model:** sonnet; **review:** none.

---

## Tuning (MS §3.9)

Only Task 7 tunes, and only after the scripted policy works the opposition as a player would. Order: Yank on/off (when too fast), `BREAK_SECONDS` 3 -> 4, the Watch 4 -> 3, march 2 count 3 -> 2, muster 10 -> 15 s. **At most three rounds**; each round reruns all six types' gates; each moved constant's `##` comment says the round and the numbers that moved it. A miss after three rounds is `DONE_WITH_CONCERNS` and goes to the user. The cooldown (8 s) and the 55 s drag cap are rules (MS §6 pacing), not tuning knobs.

## Rulings

Settled against the code at `6946db2d` (P2 + fix wave + the approved spec). Each has why and the cost if wrong.

- **P3-1 (Task 1): `RiteBook` lives in `src/game/god/`.** Rites are god progression data (the level that opens them, the gift they steal); the mission def stays in `MissionBook`. Cost if wrong: a file move.
- **P3-2 (Tasks 1, 6): Awaken's three states.** `awaken_state()`: hidden below the cap and at 50; `"rite"` with a row at the god's level; `"unwritten"` otherwise (20/30/40 in P3), dim with "Rite not yet written". The `--dev` A hook (`awaken_dev`) stays for unwritten levels and below the cap, with P2's Hunt refusal. Why: MS §1 "Reached from". Cost if wrong: one condition.
- **P3-3 (Task 1): the rite's frame at the god tier.** `def_for()` builds the rite from `MissionBook.first_taste()` (a Tier 1 frame) and sets `tier = slot.tier` and `clock = TierBook.clock(slot.tier) + extra_clock()`; the Unaware profile comes from the frame. P3's only rite is at Tier 1, so this is the frame exactly; P4's rites build their own frames. Cost if wrong: a rite at the wrong tier's clock in P4 (one line).
- **P3-4 (Task 1): a rite is known by its id, checked before the Hunt.** `bank()` and `forfeit()` test `is_rite(id)` / `is_rite(in_night)` first. A rite can never be played while the Hunt is due (Game routes Awaken to the Hunt), so the order matters only for damaged files. No save field (the rite is `in_night`'s id). Cost if wrong: a stored flag.
- **P3-5 (Task 1): a rite's draft is remembered.** `carried` counts it (MS §1) and `loadout = drafted`, so the next Prepare preselects it. The chain is never in the loadout. Cost if wrong: one line.
- **P3-6 (Task 1): the rite is a dev mission for the board.** `MissionBook.rite_missions()` is searched by `get_mission()`, and `is_dev()` is true for a rite id: on the board every power is open, no Descent, only its own best is recorded (as a `@city` night). `dev_missions()` is unchanged so FLOW's DEV-tab check and the sandbox stay. Cost if wrong: a board line.
- **P3-7 (Task 6): the rite is last on the DEV tab.** After the towns' missions, so `_flow_dev_town`'s `slice(0, capital_ids.size())` stays true. Title `"The First Taste (rite)"`, kind `RITE`. Cost if wrong: one FLOW check.
- **P3-8 (Task 6): where the gifts show on Prepare.** On an ordinary night GIFTS replaces CITY (CITY is the same every night; six rows stay six, no layout risk). Not on a Hunt (P2's T3: its rows have 1 px of room) nor on the rite (P3's only rite comes before any gift); the hub always shows them. Why: MS §4 "Prepare (Endless only): a GIFTS row" within the panel. Cost if wrong: layout, one row.
- **P3-9 (Task 6): the rite's results.** "Divine Power: none - the rite feeds no bar" replaces the Divine Power line; no believers line (R1); won: the tier, the points, the gift; lost: the shards and the capped line; then P2's Notice and Hunt lines and `Night N`. Copy *(my call)* except the spec's quoted strings. Cost if wrong: copy.
- **P3-10 (Tasks 3, 4): the flame's loss is its own objective.** Objectives in order: shards (main, a `StagesObjective` on `stages_done()`), `RiteFlameObjective` (fails `cleansed`), Dawn. `RiteDirector.lost_reason()` stays `""` so the main row never fails on its own. Rules check objectives in order, so a last shard and a full cleanse in one frame is a win (MS §6). Cost if wrong: a reason string.
- **P3-11 (Task 3): breakers are the subclass's list.** Only `_breakers()` grip; the town's soldiers (the rally, a fight, the marshals) never do (MS §0 no luck). A breaker grips only when not `held()`; `held()` is the union MS §2 names: `held_by_god()` (Whisper, Discord, The Bell Lies' call), Death Mark's `frail`, a Leaving Is Prohibited law, fright, a Yank's stun, inside, dead. Cost if wrong: one set.
- **P3-12 (Task 3): Leaving Is Prohibited skips a chained person.** A `Person.chained` flag (false by default) that `NoLeaveFx` checks as it checks "inside". The only change to a power's file; its references are rerun in Task 3. Why: R10. Cost if wrong: Decree blocks its own drags.
- **P3-13 (Task 3): the captive is the chain's, not the god's other powers'.** As `EscortDirector`'s bound charge: a whisper and fear are shaken off while chained; Discord does not divert him; a Mirrorfold fold carries him through (the path is recomputed); anything that kills him wastes him. Why: MS §2 "the god's own powers". Cost if wrong: a type could steer its own captive (a feature request, not a loss).
- **P3-14 (Task 3): no new art for victims (R13, C4).** A gold `LAMPLIGHTER` tag with a gold pip for his lantern; the shrine's flame is its tag's `rise` growing one step per shard (if `VigilFlameDirector` has a reusable flame drawing, it may be used). Cost if wrong: art later.
- **P3-15 (Task 4): who marches.** The `CLERGY` citizens nearest the Temple door, then `FAITHFUL` residents if short; fewer than 2 able -> no march and `HALCYON'S CLERGY ARE GONE` (shown, so not a hidden change). The Temple door is `MissionDirector.lantern_door()` (about (0.8, -5.0)). A marcher frightened once leaves the march for good ("fled in panic", MS §3.4). Cost if wrong: one fallback.
- **P3-16 (Task 4): the replacement's lamplighter.** The eligible `RESIDENT`/`LABORER` nearest the Temple door sets out from there on the round whose lamplighter is gone (dead or safe), the lowest such round first. Cost if wrong: who walks.
- **P3-17 (Task 5): the chain plate's input.** C enters an aim (like a focused slot: a slot key, Esc or right-click leaves it); a refused click keeps the aim; a click on the plate is C. The plate's icon is an existing one (Death Mark's or Leaving Is Prohibited's), no PixelLab (C4). Cost if wrong: input feel, a few lines.
- **P3-18 (Task 5): the win's ending.** A won rite rises from the shrine at twice the ascend effect's scale and shows `RiteBook.plate_lines()` for 4 s in slow motion; the bank happened at the decision (P2's M1). Cost if wrong: a timing constant.
- **P3-19 (Task 7): tuning directions.** MS §3.9's order read as: a type that misses on **wins** gets the easier steps (break 3 -> 4, Watch 4 -> 3, march 3 -> 2, muster 10 -> 15); a clear **under 180 s** median gets Yank off first. Each step moves every type, so all six rerun. Cost if wrong: one more round.
- **P3-20 (Tasks 4, 7): the scenario and its references.** `--scenario=first_taste`, loadout `GodTree.starting(type)` under `--god` (both Tier 1 keys at level 1), else the def's default; hit-stop off (Smite). Rows `first_taste_none_<seed>` and `first_taste_<type>_play_<seed>` (parallel-run names). Recorded once, in Task 7, after tuning. Cost if wrong: rows re-recorded within P3 (new rows; C3 unaffected).
- **P3-21 (Task 8): Awaken while the Hunt is due opens the Hunt.** Exactly Descend's path (P2-4); the rite waits for the next night. `Game.awaken_target()` is the testable decision. Cost if wrong: one branch.
- **P3-22 (Task 8): FLOW wins through `offer()`.** The director's own sacrifice path (banners, marches, the real objective and ending) three times; a drag needs scripted play and wall time. Loses through `force_end(false, "dawn")` (the results path); the abandon path is `_forfeit_rite` and `_load_god_rite`. Cost if wrong: a scripted drag later.
- **P3-23 (Task 1): five test files made at once.** Task 1 adds every SUITES line with stub files so groups A and B never edit `run_all.gd`. Cost if wrong: none.
- **P3-24 (Task 9): landing.** Trial merge against local `feat/god-progression` (t1routes may be there, C6), the merged tree gated (suite, every reference, FLOW alone), bench vs `kak-god-p2`; the long steps in the background by the controller. Cost if wrong: none.

## Needs the user (not blocking P3)

- The copy: the spec's strings are exact; every other line (refusals beyond the two, banners `THE CHAIN BREAKS` and `HALCYON'S CLERGY ARE GONE`, hints, results lines) is my call.
- If Task 7 still misses after three tuning rounds for Passage, Decree or Dominion: the user chooses (a second Yank, a longer break, or a type-specific tool).
- Rites 2-4 (P4), each its own mission spec, and their gifts.
- Still open from P2: the title switch to Endless Night, the five real Hunts (P5), the clean-win seen-death question.
