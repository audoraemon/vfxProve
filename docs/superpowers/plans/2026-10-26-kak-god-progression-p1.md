# KAK God Progression P1 "Framework" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Run it the KAK way: `.claude/skills/kak-milestone/SKILL.md` (sonnet implementers, no per-task review for mechanical tasks, dispatches from `.superpowers/sdd/godp1/implementer.md`).

**Goal:** the god-progression framework of spec §14 row P1: three god save slots, god select, an empty 60-spot `GodTree` with a dev fill, ability points and levels (plumbed to effects as `extra["level"]`, Might rising), Divine Power and god levels with the cap, Faith and the Faith screen, the Might rename, the Endless Night hub and night loop reached from the board's DEV tab, and the board turned into a test mode with a level picker.

**Architecture:** a new folder `src/game/god/` holds the data and rules: `GodTree` (the real table, empty) and `GodTreeDev` (the dev fill), `GodSlot` (one god, one file `user://kak_god_<n>.cfg`: level, Divine Power, points, learned levels, Faith, upgrades) and `GodNight` (the draw, the night's `MissionDef`, banking and forfeits). An Endless Night night is a board night (TierBook's version, its `Descent` with wishes and ASCEND) whose def comes from `GodNight.def_for()` through a new `Mission.night_def` callable, and whose banked believers become Faith 1:1 (C8). Levels travel `GodSlot.learned` / the board's picker -> `Game.levels` -> `Mission.levels` -> `Rules.levels` -> `extra["level"]` on every cast; no effect reads it in P1, so no reference moves. Five new screens (slots, god select, hub, skill tree, Faith) are plain `Node` + `Control` screens in `UiTheme`, like the board.

**Tech Stack:** Godot 4.7.2 GDScript; headless suite `tests/run_all.gd` / `tools/dev/run_suite_parallel.sh`; references `tools/dev/refs_check.sh`; scripted play `tools/dev/behaviour_check.gd`; FLOW (`Game._flow_test()`, `--flow-test`); landing `tools/dev/land.sh`.

**Spec:** `docs/superpowers/specs/2026-10-26-kak-god-progression-design.md` (cited §N). Rulings: `.superpowers/sdd/godp1/rulings.md` (C1-C9; binding over this text where they differ). This plan's own rulings: section "Rulings" at the end (P1-P24); the controller copies the ones it accepts into the rulings file.

## Global Constraints

- G = `/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`; worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-god`, branch `feat/god-progression`; every command from the worktree root; foreground only, each under 10 minutes. Import once and again after a new `class_name` or test file: `timeout 900 $G --headless --editor --path . --import >/dev/null 2>&1`.
- Per task: focused tests, then `bash tools/dev/run_suite_parallel.sh 8` (`3` in a parallel group; expect `failures=0`), then the task's `refs_check.sh --only=...` (`--jobs=2` in a parallel group); FLOW only where the task says, alone (`tasklist | grep -i godot` first; memory `flow-needs-quiet-machine`), never inside a parallel group (the controller runs it after merging the group).
- **References that must not move (C3):** `digest` `61267b7e90524d800bf1c3473a71146b`, `crowd_check` `-935602679`, and every one of the 286 rows in `tools/dev/refs/*.tsv` at `38751472`. **No row may move in P1.** A mover is a bug in the task that moved it; nothing is re-recorded. Mission simulation does not change: only the board's UI, unlocking and banking, and the new Endless Night screens.
- **No-levels exactness:** a power without a `levels` table plays exactly as today at every level (spec §5.4); `extra["level"]` is added to a copy of the cast's `extra`, never read by any P1 effect.
- **C1 naming:** every user-facing string says **Might** for the draft budget; new code and the god save say `might`; existing identifiers (`PowerBook` `"dp"`, `TierBook.DP`, `MissionDef.dp_capacity`, `Draft.capacity`, `Draft.refusal()`'s `"dp"`, `CampaignState.dp`, `DescendState.dp_bought`) keep their names. "Divine Power" now means the god's experience only.
- **C2:** the title is unchanged (`Campaign`, `Missions`, `Options`, `VFX Sandbox`, `Quit`). Endless Night is reached only from the board's DEV tab (`--dev`).
- **C4:** no PixelLab. Text, drawn shapes and existing icons (`PowerBook.hud_icon()`, `PowerBook.icon()`) only. Screens fit 640x360, `UiTheme` colours and sizes.
- **C7:** Endless Night never reads or writes `user://kak_save.cfg`'s `[descend]` or `[campaign]`, nor the board's bests; it writes only `user://kak_god_<n>.cfg`.
- Numbers from the spec are exact; those marked *tunable* are first guesses (spec §15: tuned with the scripted players later). Copy quoted in this plan is exact unless marked *(my call)*.
- Freed bodies: never touch a freed node; `is_instance_valid()` for anything held across frames (screens, missions).
- Tests: `t.check(cond, "message")`, one `static func run(t) -> void` per file, sub-tests `static func _name(t) -> void`, each new file one line in `tests/run_all.gd` SUITES (`run_part.gd` reads that list). A test that writes a file uses its own `user://test_<suite>_*.cfg` name and removes it. A test that turns `GodTree.dev_fill` on turns it off before it returns.
- Shared files: in a parallel group, stage only your own hunks (`git add -p`, `git diff --cached`). Owners are in the table below.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Every `Ruling:` a report makes goes to `.superpowers/sdd/godp1/rulings.md` (the controller) and the rulings doc (Task 15).
- Never cd elsewhere, never edit another worktree, never stop a process you did not start.

## Review Focus

1. **No escape by quitting (C9, spec §9.1):** once the clock starts, Abandon from the pause menu or closing the game counts as a lost night (counted, nothing earned); leaving from Prepare or during the intro is free. Tests: Task 5 `_forfeit`, Task 11 `_load_god_forfeits`, Task 12 FLOW (abandon after the intro, abandon during the intro, a quit mid-night).
2. **The level cap:** Divine Power never lifts a god past `tier x 10` (or 50); the excess is lost and reported; one large gain crosses several levels, one point each; Awaken (the dev hook) lifts the cap and keeps the bar. Tests: Task 4 `_xp`, `_cap_stops`, `_max_level`, `_points_total`.
3. **A damaged or hand-edited slot file** (unknown type, level 99, negative Faith, unknown power, bought counts past their limit, a missing file) reads safely; an unknown type reads as an empty slot. Test: Task 4 `_bad_file`.
4. **A god with nothing to draft** (the real tree empty, the dev fill off) cannot Descend, and its night's def allows no power (a sentinel pool, never `MissionDef.powers()`'s "every power" fallback). Tests: Task 5 `_def_empty`, Task 9 `_hub_blocked`.
5. **Endless Night never touches the board's save (C7):** after a night is banked, `SaveFile`'s `descend` (night, believers, cleared) and `campaign` are unchanged and `kak_save.cfg` is not written. Tests: Task 11 `_bank_leaves_save`, Task 12 FLOW `_flow_endless`'s last check.
6. **Board levels move Might, nothing else:** the board's level picker raises a drafted power's Might cost (+1 at 3, +1 at 5) and the cast's `extra["level"]`; the scripted runs (no levels) and every reference are unchanged. Tests: Task 1 `_cast_level`, Task 6 `_level_picker`; references in Tasks 1, 6, 14.

---

## Task order and parallelism

| # | Task | Model | Review | Parallel group |
|---|---|---|---|---|
| 1 | Ability levels and Might: `PowerBook` levels API, `Draft.levels`, `Rules`/`Mission` `extra["level"]` | sonnet | sonnet | serial |
| 2 | The Might rename in the UI | sonnet | none | **A** (A1) |
| 3 | `GodTree`, `GodTreeDev`, the validation test | sonnet | none | **A** (A2) |
| 4 | `GodSlot`: the save slot, points, levels, Divine Power and the cap, Faith | sonnet | sonnet | **B** (B1) |
| 5 | `GodNight`: the draw, the night's def, banking, forfeits; Mission's hooks | sonnet | sonnet | **C** (C1) |
| 6 | The board as test mode, with the Prepare level picker | sonnet | sonnet | **B** (B2) |
| 7 | Slot select and god select screens | sonnet | none | **C** (C2) |
| 8 | The Skill Tree screen | sonnet | none | **C** (C3) |
| 9 | The Faith screen and the Endless Night hub | sonnet | none | **C** (C4) |
| 10 | Endless Night's Results, Pause and Prepare | sonnet | none | **C** (C5) |
| 11 | Wiring: Game's Endless Night screens, the DEV entry, banking, forfeits, photographs | sonnet | sonnet | serial |
| 12 | FLOW: the Endless Night walk | sonnet | none | serial |
| 13 | Scripted-player plumbing: `--god=<type>:<tier>`, `--dev-tree`, `--level=` (C6) | sonnet | none | **B** (B3) |
| 14 | P1 landing on `feat/god-progression` (C5) | sonnet | none (controller's opus milestone review) | serial |
| 15 | Notes: P1 summary, rulings doc, Dev Ledger lines | sonnet | none | serial |

Order: 1 → A (2, 3 at once) → B (4, 6, 13 at once) → C (5, 7, 8, 9, 10 at once) → 11 → 12 → 14 → 15 → the controller's milestone review, one fix wave, then the tag `kak-god-p1` on `feat/god-progression`. Every group runs in the one worktree; inside a group the controller commits in number order and runs FLOW alone after B (Task 6 changes FLOW). No task needs opus (no redesign: the spec fixes the rules; the layouts are the builder's, spec §12, §15).

**Shared files and their owners** (one hunk each; keep all on merge):

| File | Serial / A | Group B | Group C | Serial (11-12) |
|---|---|---|---|---|
| `src/game/power_book.gd` | 1: new consts and funcs after `get_power()` | -- | -- | -- |
| `src/game/draft.gd`, `src/game/rules.gd` | 1 only | -- | -- | -- |
| `src/game/mission.gd` | 1: `var levels`, the line in `_build_act()` | -- | 5: `night_def`, `restart_locked`, `clock_started`, `_mission_def()`, `_land()`, the R key | -- |
| `src/game/ui/prepare_screen.gd` | 2: strings only | 6: `level_picker`, `level_rect()`, the badge, `click()` | 10: `god`, `tabs()`, `authority_keys()`, the card's level | -- |
| `src/game/ui/results_screen.gd` | 2: `campaign_line()` strings | 6: the board's menu, `summary_lines()` test branch | 10: `endless`, `god_lines()`, its menu and draw | -- |
| `src/game/ui/campaign_screen.gd`, `upgrades_screen.gd` | 2: strings only | -- | -- | -- |
| `src/game/ui/mission_board.gd` | -- | 6: test mode (tabs, header, no Upgrades) | -- | 11: `ENDLESS_RECT`, `"endless"` |
| `src/game/ui/pause_menu.gd` | -- | -- | 10 only | -- |
| `src/game/descend/descend_state.gd` | -- | 6: `bank_test()` | -- | -- |
| `src/game/game.gd` | -- | 6: `locked_for()`, `board_locked_for()`, `board_def()`, Prepare's board branch, `_build_mission()` board lines, `_on_prepare_action()` levels, `bank_night()` board branch, FLOW's board steps | -- | 11: `Screen`, `FLOW` entries, the Endless Night vars, branches and handlers, `--show` entries; 12: `_flow_endless()` and its call |
| `tools/dev/behaviour_check.gd` | -- | 13 only | -- | -- |
| `tests/run_all.gd`, `tests/run_part.gd` | 3: `GodTree.dev_fill = false` in both `_reset_world()`; each task: one SUITES line in run_all | one line each | one line each | one line each |
| `tests/test_tier_board.gd` | 2: the budget string | 6: `_tabs`, `_draft` | -- | -- |

---

### Task 1: Ability levels and Might

**Goal:** spec §5.4 (levels 1-5, a `levels` table per power, `extra["level"]`), §6 (Might cost by level). No reference moves.

**Files:**
- Modify: `src/game/power_book.gd`, `src/game/draft.gd`, `src/game/rules.gd`, `src/game/mission.gd` (`var levels`, one line in `_build_act()`).
- Test: `tests/test_power_levels.gd` (new; SUITES).

**Interfaces (produces):**
- `PowerBook.MAX_LEVEL := 5`; `PowerBook.MIGHT_STEPS := [3, 5]` (each level reached adds +1 Might, spec §6); `PowerBook.NO_LEVELS := "Level effects not set"`.
- `PowerBook.might(key: String, level := 1) -> int`: the power's `dp` plus one for each `MIGHT_STEPS` entry `<= level` (level clamped 1..5); 0 for an unknown key.
- The optional `"levels"` entry of a `POWERS` row: an Array of exactly 5 Dictionaries, index 0 = level 1; each maps stat name -> value (the numbers its effect reads); index 4 also holds `"twist": true` and `"twist_text": "<one line>"`. No row has one in P1.
- `PowerBook.has_levels(key) -> bool`; `PowerBook.stat_in(entry: Dictionary, level: int, stat: String, base: Variant) -> Variant` (the table's value at `level` when the entry has a table naming the stat, else `base`); `PowerBook.level_stat(key, level, stat, base) -> Variant` (`stat_in(get_power(key), ...)`); `PowerBook.stat(extra: Dictionary, key: String, stat: String, base: Variant) -> Variant` (what an effect calls: `level_stat(key, int(extra.get("level", 1)), stat, base)`); `PowerBook.twist(key) -> String` (`""` none); `PowerBook.level_change(key, level) -> String` (what reaching `level` changes, `"radius 1.5 -> 1.7, damage 40 -> 46"` from the tables; `NO_LEVELS` without a table; the twist text at 5); `PowerBook.levels_problems(entry: Dictionary) -> PackedStringArray` (empty when valid: 5 tables; every stat named in all five with one type; `twist` true and `twist_text` not empty at level 5 only).
- `Draft.levels := {}` (key -> level 1-5; absent = 1); `Draft.level_of(key) -> int`; `Draft.spent()` sums `PowerBook.might(key, level_of(key))`; `refusal()`'s `"dp"` test uses that Might; `Draft.set_level(key: String, level: int) -> String` ("" when set; `"dp"` when the new Might would exceed `capacity`, level unchanged; `"pool"` for a key not picked).
- `Rules.levels := {}`; `Rules.level_of(slot: int) -> int` (the slot's key's level, 1 by default, clamped 1..5); `Rules.cast()` hands the caster a **copy** of `extra` with `"level"` set (unless the caller set it), so the caller's dictionary is never changed.
- `Mission.levels := {}`; `_build_act()` sets `_rules.levels = levels` right after `_rules.setup(...)`. An R restart and `next_act()` keep it.
- An effect script reads its numbers as `PowerBook.stat(extra, "<key>", "<stat>", CONST)`; no effect is changed in P1.

- [ ] **Step 1: Failing tests** `tests/test_power_levels.gd`:

```gdscript
# _might
t.check(PowerBook.might("doom") == 1 and PowerBook.might("doom", 2) == 1 and PowerBook.might("doom", 3) == 2
	and PowerBook.might("doom", 4) == 2 and PowerBook.might("doom", 5) == 3, "Might rises +1 at levels 3 and 5")
t.check(PowerBook.might("schism", 5) == 8 and PowerBook.might("nosuch", 5) == 0 and PowerBook.might("doom", 9) == 3, "clamped; unknown 0")
# _no_tables: no POWERS row has "levels" in P1 -> has_levels false for every key; level_stat("ember", 5, "radius", 1.5) == 1.5;
#   level_change("ember", 2) == PowerBook.NO_LEVELS; twist("ember") == ""
# _fixture_table: FIXTURE := {"key": "fx", "levels": [{"radius": 1.0}, {"radius": 1.1}, {"radius": 1.2}, {"radius": 1.3},
#   {"radius": 1.5, "twist": true, "twist_text": "Jumps to the next house"}]}
#   stat_in(FIXTURE, 3, "radius", 9.0) == 1.2; stat_in(FIXTURE, 3, "damage", 9.0) == 9.0; levels_problems(FIXTURE).is_empty();
#   a 4-table copy -> not empty; level 5 without twist_text -> not empty; a twist at level 2 -> not empty; "radius" missing at level 4 -> not empty
# _draft_levels: Draft capacity 6, picks ["smite", "tornado"], levels {"tornado": 5} -> spent() == 1 + 5;
#   set_level("smite", 3) == "dp" and level_of("smite") == 1; set_level("smite", 2) == "" ; set_level("heaven", 2) == "pool";
#   with levels empty, Last Judgement's default four spent() == 14 (as tests/test_draft.gd)
# _cast_level (a Rules built as tests/test_board_nights.gd builds one; its caster records the extra it is given):
#   no levels -> recorded["level"] == 1; rules.levels = {"smite": 4} -> 4; the caller's extra {"mode": "x"} still has no "level" afterwards
# _mission_keeps: Mission.new().levels is {} and a value set on it is what _build_act hands Rules (read the property after a start in
#   a headless Mission only if cheap; else a source check that _build_act assigns _rules.levels = levels)
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN** (suite 8 `failures=0`; `tests/test_draft.gd` unchanged and passing).
- [ ] **Step 5: Unmoved** (every cast goes through `Rules.cast()`): `bash tools/dev/refs_check.sh --only='^(digest|crowd_check|calm|gates|fire|rite|soldiers|warning_(none|doom|whisper|discord|mix)|miras_play|feast_play|flame_play|tax_play_1|ringers_play_1|bread_play_1|hunt_play_1|armoury_play_1|eye_play_1|heart_play_1|judgement_b_play_1|night_b_play_1)$'` → all OK (the full 286 run at landing).
- [ ] **Step 6: Commit** `feat: ability levels plumbed -- PowerBook levels tables, Might by level, extra["level"] on every cast (god P1)`.

**Numbers:** `MAX_LEVEL` 5; Might +1 at 3 and at 5 (spec §6). **References:** none may move. **Model:** sonnet; **review:** sonnet (the path every later task and every effect builds on; Review Focus 6).

---

### Task 2: The Might rename in the UI

**Goal:** spec §6 last line, ruling C1: every user-facing string that says DP for the draft budget says Might. Mechanical.

**Files:**
- Modify (strings only): `src/game/ui/prepare_screen.gd` (`REFUSALS["dp"]`, `budget_text()`, the panel's LOADOUT line, the hint, both card cost lines), `src/game/ui/campaign_screen.gd` (`status_text()`), `src/game/ui/results_screen.gd` (`campaign_line()`), `src/game/ui/upgrades_screen.gd` (its button title and budget line). Comments may follow; identifiers do not change.
- Modify: `tests/test_campaign_screens.gd`, `tests/test_tier_board.gd` (the budget string only).
- Test: `tests/test_might_text.gd` (new; SUITES).

**Interfaces:** none new. Exact copy:
- `REFUSALS["dp"] = "Not enough Might"`; `budget_text()` `"%d / %d slots   %d / %d Might"`; panel `"%d slots, %d Might to spend on them"`; hint `"Pick up to %d powers within %d Might"`; cards `"%d Might   %s   %s"` and `"%d Might  %s"` (the price is `PowerBook.might(key, draft.level_of(key))`, so Task 1's levels show).
- `CampaignScreen.status_text()` `"%d Might   %d slots   Bites %d / %d   %s"`; `campaign_line()` `"The god grows: +%d Might, %d Might now."` and `"Halcyon bites: %d Might now. Bites %d / %d."`.
- `UpgradesScreen`: `"+1 MIGHT"`, `"Board missions: their tier's budget +%d Might, +%d slot"`.

- [ ] **Step 1: Failing tests** `tests/test_might_text.gd`:

```gdscript
# _prepare: a PrepareScreen set up on TierBook.board("warning") -> budget_text() == "0 / 3 slots   0 / 6 Might";
#   PrepareScreen.REFUSALS["dp"] == "Not enough Might"
# _campaign: CampaignScreen.status_text(CampaignState.new()) == "6 Might   3 slots   Bites 0 / 3   The Forgotten";
#   ResultsScreen.campaign_line({"won": true, "dp_gain": 2, "dp": 8}) == "The god grows: +2 Might, 8 Might now.";
#   ResultsScreen.campaign_line({"won": false, "dp": 5, "bites": 1}) == "Halcyon bites: 5 Might now. Bites 1 / 3."
# _scan: in src/game/ui/*.gd, comments stripped, no string literal matches \bDP\b, and none in prepare_screen.gd, campaign_screen.gd or
#   upgrades_screen.gd says "Divine Power" (from Task 9 on, "Divine Power" is the god's experience on the hub and the results) -> the found
#   list is empty (the message names file:line)
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN** (suite 3).
- [ ] **Step 5: Commit** `refactor: the draft budget is Might on every screen (god P1, C1)`.

**References:** none (UI only). **Model:** sonnet; **review:** none.

---

### Task 3: `GodTree`, `GodTreeDev`, the validation test

**Goal:** spec §5.1-§5.2, §15 (dev fill). The ring, 60 spots in one table, all empty; the dev fill kept apart; the test that checks keys exist and appear once.

**Files:**
- Create: `src/game/god/god_tree.gd` (`class_name GodTree`), `src/game/god/god_tree_dev.gd` (`class_name GodTreeDev`).
- Modify: `tests/run_all.gd`, `tests/run_part.gd` (`_reset_world()` gains `GodTree.dev_fill = false`).
- Test: `tests/test_god_tree.gd` (new; SUITES).

**Interfaces (produces):**
- `GodTree.RING := ["ruin", "death", "veil", "passage", "decree", "dominion"]` (spec §5.1's ring; `PowerBook.AUTHORITIES`, the draft's tab order, is untouched: Ruling P1). `TIERS := 5`, `PER_TIER := 2`, `SPOTS := 60`, `NOT_CHOSEN := "Not yet chosen"`, `OWN_COST := 1`, `NEIGHBOUR_COST := 2`.
- `GodTree.TABLE := {"ruin": [["", ""], ["", ""], ["", ""], ["", ""], ["", ""]], ...}` -- every type, five tiers (index 0 = Tier 1), two keys each, all `""`. Filling the tree is editing this table only (spec §5.2).
- `GodTree.FLAVOUR := {type: "<one line>"}` *(my call; the user may rewrite)*: ruin "What stands, falls.", death "Every life is a loan.", veil "Unseen, unheard, unanswered.", passage "Every way is yours to open or to close.", decree "Your word is law, and the law is yours.", dominion "Every mind bends."
- `static var dev_fill := false`. With it on, an empty real spot takes `GodTreeDev.TABLE`'s key for that spot, unless the real table already holds that key somewhere (Ruling P2).
- `static func spot(type: String, tier: int, i: int) -> String` (`""` empty or out of range); `static func spots() -> Array` (60 `{"type", "tier", "i", "key"}` in RING, tier, index order); `static func spot_of(key: String) -> Dictionary` (`{}` when in no spot); `static func neighbours(type) -> PackedStringArray` (`[ring left, ring right]`: ruin -> `["dominion", "death"]`); `static func factor(god_type: String, spot_type: String) -> int` (`OWN_COST` own, `NEIGHBOUR_COST` a neighbour, 0 a far type); `static func starting(type) -> PackedStringArray` (the type's non-empty Tier 1 keys); `static func keys_for(type: String, max_tier: int) -> PackedStringArray` (the type's non-empty keys, tiers 1..`max_tier`, spot order); `static func outside(type, max_tier, keys: PackedStringArray) -> PackedStringArray` (the keys not in `keys_for`); `static func problems(table: Dictionary) -> PackedStringArray` (empty when valid: the six RING types, five tiers of two, each key `""` or a `PowerBook` key, no key twice; a key's Authority is **not** checked against its spot, spec §5.2); `static func merged(real: Dictionary, dev: Dictionary) -> Dictionary` (Ruling P2's merge, pure); `static func table() -> Dictionary` (`merged(TABLE, GodTreeDev.TABLE)` when `dev_fill`, else `TABLE`; every lookup above reads it).
- `GodTreeDev.TABLE` (the same shape; test and scripted play only; *tunable*, not the user's fill):
  - ruin: T1 `smite, ember`; T2 `heaven, tornado`; T3 `dragon, gravity`; T4 `laser, orbital`; T5 `cinder, judgement`
  - death: T1 `deathmark, pestilence`; T2 `glacial, solaris`; T3-T5 empty
  - veil: T1 `doom, blight`; T2 `tsunami, nova`; T3-T5 empty
  - passage: T1 `thorns, mirror`; T2-T5 empty
  - decree: T1 `noleave, belllies`; T2 `magnify, abolition`; T3-T5 empty
  - dominion: T1 `whisper, wisp`; T2 `discord, madness`; T3 `oath, echo`; T4 `turncoat, hatred`; T5 `priority, verdict`

- [ ] **Step 1: Failing tests** `tests/test_god_tree.gd`:

```gdscript
# _shape: GodTree.TABLE.keys() sorted == GodTree.RING sorted; GodTree.spots().size() == 60; every type 5 tiers x 2
# _valid: GodTree.problems(GodTree.TABLE).is_empty(); GodTree.problems(GodTreeDev.TABLE).is_empty();
#   GodTree.dev_fill = true -> GodTree.problems(GodTree.table()).is_empty(); off again
# _problems_found: a copy with "nosuch" in a spot, one with "smite" twice, one with four tiers -> each non-empty (the message says why)
# _ring
t.check(GodTree.neighbours("ruin") == PackedStringArray(["dominion", "death"]) and GodTree.neighbours("veil") == PackedStringArray(["death", "passage"]), "the ring")
t.check(GodTree.factor("ruin", "ruin") == 1 and GodTree.factor("ruin", "death") == 2 and GodTree.factor("ruin", "dominion") == 2
	and GodTree.factor("ruin", "veil") == 0 and GodTree.factor("ruin", "passage") == 0 and GodTree.factor("ruin", "decree") == 0, "1x own, 2x neighbours, far locked")
# _dev_fill: on -> spot("ruin", 1, 0) == "smite", spot_of("smite") == {"type": "ruin", "tier": 1, "i": 0}, starting("ruin") == ["smite", "ember"],
#   keys_for("ruin", 2) == ["smite", "ember", "heaven", "tornado"], outside("ruin", 1, ["smite", "doom"]) == ["doom"]; off ->
#   starting("ruin") == the real TABLE's non-empty Tier 1 keys for ruin (empty in P1)
# _real_wins: GodTree.merged(real, GodTreeDev.TABLE) with a test-local real table holding "smite" at veil T3 and "doom" at veil T1:
#   "smite" appears once (at veil T3; ruin T1 spot 0 is left empty), veil T1 spot 0 is "doom", and problems() of the result is empty
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN** (suite 3).
- [ ] **Step 5: Commit** `feat: the god tree -- six types on a ring, 60 empty spots, a dev fill kept apart, the validation test (god P1)`.

**Numbers:** 60 spots; 1x / 2x / locked (spec §5.1). **References:** none. **Model:** sonnet; **review:** none (small; the milestone review covers it; Task 4's review reads its interfaces).

---

### Task 4: `GodSlot`

**Goal:** spec §4 (slots, what a slot holds, storage, starting abilities), §5.3 (points, costs, respec), §5.2 tier gate, §6 (max Might, slots), §7 (Faith upgrades), §8 (Divine Power, levels, cap). C9: the Notice field is written and read (always 0 in P1).

**Files:**
- Create: `src/game/god/god_slot.gd` (`class_name GodSlot`).
- Test: `tests/test_god_slot.gd` (new; SUITES).

**Interfaces (consumes):** Task 3 (`GodTree.spot_of`, `factor`, `starting`, `spots`, `RING`, `dev_fill`), Task 1 (`PowerBook.might`, `MAX_LEVEL`), `TierBook.dp()`, `TierBook.MAX_SLOTS`, `TierBook.has()`.

**Interfaces (produces):**
- Consts: `COUNT := 3`; `PATH_BASE := "user://kak_god_"` (file = base + n + ".cfg", n 1-3); `SECTION := "god"`; `VERSION := 1`; `MAX_LEVEL := 50`; `LEVELS_PER_TIER := 10`; `XP_PER_LEVEL := 50` (*tunable*: a level costs `50 x god tier`); `AWAKEN_POINTS := 2`; `BASE_SLOTS := 3`; `NOTICE_MAX := 100`; `FAITH_PER_BELIEVER := 1`; `CLOCK_STEP := 15.0`.
- `const FAITH := [{"key": "slot", "name": "+1 SLOT", "prices": [150, 300, 450], "limit": 3}, {"key": "might", "name": "+1 MIGHT", "step": 25, "limit": 6}, {"key": "clock", "name": "+15 S DESCENT", "step": 40, "limit": 4}, {"key": "respec", "name": "RESET ABILITY POINTS", "step": 100, "limit": 0}]` (prices *tunable*, spec §7; `limit` 0 = none; new rows are data).
- Vars (each one save key of `[god]`, same name): `index: int`, `name := ""`, `type := ""`, `level := 1`, `divine_power := 0` (toward the next level), `tier := 1`, `points := 0`, `learned := {}` (key -> level 1-5), `faith := 0`, `bought := {}` (FAITH key -> count), `notice := 0` (percent), `sealed := ""`, `seal_nights := 0`, `night := 0` (nights played), `last_mission := ""`, `in_night := ""` (the mission whose clock has started and not yet ended: Task 5, Ruling P9), `gifts := PackedStringArray()`, `bests := {}` (mission id -> `{"cleared": bool, "fastest": float, "most_wishes": int}`), `carried := {}` (key -> nights drafted, for P2's most-carried, Ruling P16), `loadout := PackedStringArray()` (last drafted), `seed := 0` (made once at creation; Task 5's draw). Plus `version`.
- `static func path(n: int, base := PATH_BASE) -> String`; `static func make(n: int, god_type: String, p_seed: int) -> GodSlot` (level 1, tier 1, starting abilities learned at 1 for free); `static func read(file: String) -> GodSlot` (null when missing, unreadable, or its `type` is not in `GodTree.RING`: Ruling P23; every value clamped as `_bad_file` lists; unknown power keys and mission ids dropped; then `ensure_starting()`); `func write(file: String) -> Error`.
- `func need() -> int` (`XP_PER_LEVEL * tier`); `func cap() -> int` (`mini(tier * LEVELS_PER_TIER, MAX_LEVEL)`); `func capped() -> bool` (`level >= cap()`); `func gain_dp(amount: int) -> Dictionary` (`{"levels": PackedInt32Array, "points": int, "lost": int, "capped": bool}`: levels while the bar fills and `level < cap()`, +1 point each; at the cap the bar fills to `need()` and stops, the rest is `lost`: Ruling P6); `func awaken() -> void` (the dev/test hook for P3's win: `tier + 1` (5 at most), `points + AWAKEN_POINTS`, the bar kept and re-levelled at the new need); `func points_earned() -> int` (`(level - 1) + AWAKEN_POINTS * (tier - 1)`: Ruling P5).
- `func spot_type(key) -> String`; `func cost(key) -> int` (`GodTree.factor(type, spot_type(key))`; 0 for a key in no spot or a far type); `func level_of(key) -> int` (0 not learned); `func refusal(key) -> String` (`"unknown"` in no spot, `"far"`, `"tier"` (learning a spot above the god's tier; raising is never tier-gated, spec §5.2), `"max"` (level 5), `"points"`, or `""`); `func learn(key) -> bool` (learns at 1 or raises by 1, spending `cost(key)`).
- `func might_of(key) -> int` (`PowerBook.might(key, level_of(key))`); `func max_might() -> int` (`TierBook.dp(tier) + bought.might`); `func slots() -> int` (`mini(BASE_SLOTS + bought.slot, TierBook.MAX_SLOTS)`); `func extra_clock() -> float` (`CLOCK_STEP * bought.clock`).
- `func draftable() -> PackedStringArray` (learned keys that sit in a spot and are not `sealed`, in `GodTree.spots()` order; a learned key no longer in any spot is kept but not draftable: Ruling P4); `func starting() -> PackedStringArray`; `func ensure_starting() -> void`.
- `func faith_price(what) -> int` (`prices[n]` or `step * (n + 1)` for the (n+1)-th); `func faith_refusal(what) -> String` (`"unknown"`, `"limit"`, `"nothing"` (respec with no point spent), `"faith"`, `""`); `func buy(what) -> bool` (spends; `"respec"` resets `learned` to `starting()` at level 1 and `points = points_earned()`).

- [ ] **Step 1: Failing tests** `tests/test_god_slot.gd` (dev fill on for the suite, off at its end; files `user://test_god_slot_*.cfg`, removed):

```gdscript
# _make: GodSlot.make(1, "ruin", 7): level 1, tier 1, points 0, learned == {"smite": 1, "ember": 1}, faith 0, notice 0, night 0,
#   slots() == 3, max_might() == 6, need() == 50, cap() == 10
# _round_trip: every var set to a non-default value, write(), read() -> each var equal (list them all in the message)
# _bad_file: type "nosuch" -> read() == null; a missing file -> null; level 99 -> cap() (10); tier 9 -> 5; faith -5 -> 0;
#   divine_power 999 at tier 1 -> 50; learned {"nosuch": 3, "smite": 9} -> {"smite": 5, "ember": 1}; bought {"slot": 9, "might": -2} ->
#   {"slot": 3, "might": 0}; notice 250 -> 100; last_mission "nosuch" -> ""; loadout ["nosuch", "smite"] -> ["smite"]
# _costs (ruin): cost("smite") == 1, cost("deathmark") == 2, cost("whisper") == 2, cost("doom") == 0 -> refusal("doom") == "far";
#   refusal("congregation") == "unknown" (in no dev spot)
# _tier_gate: points 5: refusal("heaven") == "tier"; awaken(); learn("heaven") and level_of("heaven") == 1 and points == 6
# _levels: points 4: smite 1 -> 5 costs 4 (points 0); refusal("smite") == "max"; might_of("smite") == 3; at level 3 it was 2
# _neighbour: points 10: deathmark 0 -> 5 costs 2 x 5 == 10; points 1 -> refusal("pestilence") == "points"
# _xp: gain_dp(80) -> level 2, points 1, divine_power 30, levels [2]; a fresh slot gain_dp(500) -> levels [2..10], points 9,
#   divine_power 50 (full), lost 0, capped; then gain_dp(30) -> lost 30, level 10, divine_power 50
# _cap_stops: at level 10 any gain leaves level 10; awaken() -> tier 2, cap 20, need 100, points + 2, divine_power still 50
# _max_level: tier 5, level 49, gain_dp(100000) -> level 50, never 51; capped; lost > 0
# _points_total: a fresh slot driven to level 50 with four awaken() -> points_earned() == 57 (49 + 8)
# _faith_prices: faith 2000: slot 150, 300, 450 then refusal "limit", slots() == 6; might 25 x n six times then "limit",
#   max_might() == 12; clock 40 x n four times then "limit", extra_clock() == 60.0; faith_price("respec") == 100, and after one respec
#   (a point earned and spent first) 200
# _faith_short: faith 10 -> faith_refusal("might") == "faith"; buy("might") false; faith still 10
# _respec: tier 2, smite 3, ember 1, heaven 2, points 0 -> faith_refusal("respec") == ""; buy -> learned == {"smite": 1, "ember": 1},
#   points == points_earned(); a fresh slot -> faith_refusal("respec") == "nothing"
# _draftable: smite, ember, deathmark learned -> draftable() == ["smite", "ember", "deathmark"] (spot order); sealed "smite" -> without it;
#   dev fill off (real table empty) -> draftable().is_empty()
# _ensure_starting: a file with learned {} read with the dev fill on -> {"smite": 1, "ember": 1}, points unchanged
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN** (suite 3).
- [ ] **Step 5: Commit** `feat: the god's save slot -- level, Divine Power and the cap, ability points and costs, Faith upgrades and respec (god P1)`.

**Numbers:** spec §5.3, §6, §7, §8 as above; `XP_PER_LEVEL` and the Faith prices *tunable*. **References:** none. **Model:** sonnet; **review:** sonnet (the rules every screen shows; Review Focus 2, 3).

---

### Task 5: `GodNight` and Mission's hooks

**Goal:** spec §9.1 (the draw, what the night sets, Prepare's pool, every night counts, no escape by quitting), §8 (Divine Power per night), §7 (Faith from believers), C8, C9.

**Files:**
- Create: `src/game/god/god_night.gd` (`class_name GodNight`).
- Modify: `src/game/mission.gd` (`night_def`, `restart_locked`, `clock_started`; `_mission_def()`, `_land()`, the R key).
- Test: `tests/test_god_night.gd` (new; SUITES).

**Interfaces (consumes):** Task 4 (`GodSlot` vars and `draftable()`, `slots()`, `max_might()`, `extra_clock()`, `gain_dp()`), Task 3 (`GodTree.dev_fill`), `TierBook.board(id, null)`, `TierBook.missions(tier)`, `Descent.report()`'s `"descend"` keys (`tier`, `main`, `main_time`, `kept`, `earned`).

**Interfaces (produces):**
- `GodNight.MAIN_DP := 80`, `WISH_DP := 20` (*tunable*: x the night's mission tier, spec §8); `NO_POWERS := "none"` (the pool of a god with nothing to draft: Ruling P8); `ABANDONED := "Night %d was abandoned: a lost night."` *(my call)*.
- `static func night_seed(slot: GodSlot) -> int` (`hash([slot.seed, slot.night])`); `static func draw(slot: GodSlot) -> String` (a mission of `TierBook.missions(slot.tier)` but never `slot.last_mission`, picked with a `RandomNumberGenerator` seeded `night_seed(slot)`; no state changes, so the same slot gives the same night until a night counts); `static func wish_seed(slot, id: String) -> int` (`hash([slot.seed, slot.night, id])`).
- `static func def_for(slot: GodSlot, id: String) -> MissionDef`: `TierBook.board(id, null)`, then on it and every act: `slots = slot.slots()`, `dp_capacity = slot.max_might()`, `pool = slot.draftable()` (or `[NO_POWERS]` when empty), and the clock `+ slot.extra_clock()` added **after** the board set its stretch (event times keep the tier's; only dawn moves: Ruling P7; for a night with acts, each act's clock).
- `static func divine_power(d: Dictionary) -> int` (`d` = a report's `"descend"`: `main ? MAIN_DP * tier + WISH_DP * tier * kept : 0`; caught after the main objective, `kept` is 0, so only the main's counts: Ruling P22).
- `static func bank(slot: GodSlot, id: String, drafted: PackedStringArray, outcome: Dictionary) -> Dictionary`: `night + 1`, `last_mission = id`, `in_night = ""`, `faith += earned * FAITH_PER_BELIEVER`, `gain_dp(divine_power(...))`, the mission's bests, `carried[key] + 1` for each drafted key, `loadout = drafted`. Returns `{"divine_power": int, "levels": PackedInt32Array, "points": int, "lost": int, "capped": bool, "level": int, "bar": [divine_power, need], "believers": int, "faith": int, "faith_total": int, "notice": int, "notice_change": 0, "night": int, "bests": PackedStringArray}` (bests' text as `DescendState.bank()` writes them).
- `static func forfeit(slot: GodSlot) -> Dictionary` (a lost night: `night + 1`, `last_mission = in_night`, `in_night = ""`, nothing earned; P2 adds the Notice; returns `{"night": slot.night, "line": ABANDONED % slot.night}`).
- `Mission.night_def: Callable` (when valid, `_mission_def()` returns `night_def.call()` and ignores `--mission`); `Mission.restart_locked := false` (true: the R key does nothing); `signal clock_started` (emitted from `_land()`, once per start or act).

- [ ] **Step 1: Failing tests** `tests/test_god_night.gd` (dev fill on, off at the end):

```gdscript
# _draw_no_repeat: GodSlot.make(1, "ruin", 3); 40 times: id := draw(s); s.in_night = id; forfeit(s) -> no two in a row equal, and every
#   one of TierBook.missions(1) drawn at least once
# _draw_seeded: draw(s) twice == the same; a copy with the same seed and night == the same; seeds 3 and 4 give different 10-night runs
# _draw_tier: s.tier = 2 -> draw(s) in TierBook.missions(2)
# _def: bought {"might": 2, "slot": 1, "clock": 2}: def_for(s, "warning") -> slots 4, dp_capacity 8, pool == s.draftable(),
#   clock == TierBook.clock(1) + 30.0, stretch == TierBook.board("warning").stretch, director == StarfallDirector, tier 1
# _def_empty: dev fill off -> def_for(s, "warning").pool == [GodNight.NO_POWERS] and not .allows("smite")
# _def_acts: s.tier = 5 -> def_for(s, "long_night"): every act's slots, dp_capacity and pool are the god's; each act's clock is its board
#   clock + extra_clock()
# _dp: bank(s, "warning", ["smite"], {"won": true, "descend": {"tier": 1, "main": true, "kept": 2, "earned": 30, "main_time": 150.0}})
#   -> divine_power 120, level 3, points 2, faith 30, faith_total 30, night 1, s.last_mission "warning", carried {"smite": 1}
# _dp_caught: main true, kept 0, earned 10 -> divine_power 80, faith 10
# _dp_lost: main false, earned 0 -> divine_power 0, faith 0, night 1 (counted), last_mission set
# _tier_scale: tier 3, main, kept 1 -> 300
# _forfeit: s.in_night = "tax_collector": forfeit(s) -> night + 1, last_mission "tax_collector", in_night "", faith and level unchanged,
#   line == "Night 1 was abandoned: a lost night."
# _wish_seed: stable for the same slot, night and id; differs after night + 1
# _bests: two banks of "warning" (main_time 200 then 150; kept 1 then 2) -> bests.warning == {"cleared": true, "fastest": 150.0, "most_wishes": 2}
# _mission_hooks: var m := Mission.new(); m.night_def = func() -> MissionDef: return def_for(s, "warning");
#   m._mission_def(PackedStringArray()).pool == s.draftable(); m.restart_locked == false; m.has_signal("clock_started"); m.free()
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN** (suite 3).
- [ ] **Step 5: Unmoved** (`_mission_def`, `_land`, the R key): `bash tools/dev/refs_check.sh --jobs=2 --only='^(digest|calm|warning_none|tax_play_1|night_b_play_1|feast_play)$'` → OK.
- [ ] **Step 6: Commit** `feat: an Endless Night night -- the seeded draw with no repeat, the god's def, Divine Power and Faith banked, forfeits (god P1)`.

**Numbers:** `80 x tier`, `20 x tier` *tunable* (spec §8). **References:** none may move. **Model:** sonnet; **review:** sonnet (the loop's rules; Review Focus 1, 4).

---

### Task 6: The board as test mode, with the Prepare level picker

**Goal:** spec §3 "Board as test mode", C3: all five tiers open, no padlocks, every power open, no Upgrades button, no believers banked, TierBook's slots and Might; Prepare's level picker (1-5, default 1). Simulation unchanged.

**Files:**
- Modify: `src/game/ui/mission_board.gd`, `src/game/ui/prepare_screen.gd` (the picker), `src/game/ui/results_screen.gd` (the board's menu and `summary_lines()`), `src/game/descend/descend_state.gd` (`bank_test()`), `src/game/game.gd` (owner hunks in the table; FLOW's board steps).
- Modify (tests that assert the old board): `tests/test_tier_board.gd` (`_tabs`, `_draft`), `tests/test_board_nights.gd` (locks), `tests/test_descend_screens.gd` (results buttons), `tests/test_tier5_board.gd` (header). Each changed assertion says the new rule; none is deleted without a replacement.
- Test: `tests/test_board_test_mode.gd` (new; SUITES).

**Interfaces (consumes):** Task 1 (`Draft.levels`, `set_level()`, `PowerBook.might()`, `Mission.levels`).

**Interfaces (produces):**
- `MissionBoard`: `_is_open(t)` true for 1-5 (DEV as before); `lock_line()` always `""`; no padlock drawn; `TEST_HEADER := "TEST MODE: every tier, mission and power open"`, `header_text()` returns it; no Upgrades button drawn, `hit()` never returns `"upgrades"`, U does nothing; the hint reads `"Left and Right: missions   Tab or number keys: tiers   Enter: prepare   Esc: title"`. Cards keep their ticks and bests (`DescendState.cleared`, `fastest`, `most_wishes`).
- `Game.locked_for()` and `Game.board_locked_for()` return an empty list always (signatures kept); `static func Game.board_def(id: String) -> MissionDef` (`Mission.def_for(id, true, null)`: TierBook's slots and Might, no upgrades); Prepare's board branch and `_build_mission()` use it (`mission.descend = null` on the board); `Game.levels := {}` (the picker's choice, kept for Replay and Restart, never saved: Ruling P13), set from `prep.draft.levels` at MANIFEST and handed to `mission.levels`.
- `DescendState.bank_test(id: String, outcome: Dictionary) -> Dictionary`: `night + 1` (it seeds the board's wishes only: Ruling P11), the mission's `cleared`, `fastest`, `most_wishes` as `bank()` keeps them; **no believers**, `open_tier` untouched. Returns `{"test": true, "night": int, "cleared": bool, "first_clear": bool, "bests": PackedStringArray}`. `Game.bank_night()`'s board branch calls it instead of `bank()`.
- `ResultsScreen`: a board night's menu `["missions", "replay", "change"]` / `["Board", "Again", "Change powers"]`; `summary_lines()` for a `bank.test` result: `["Test mode: nothing banked"]` then each `"New best: ..."`.
- `PrepareScreen.level_picker := false` (set before `setup()`; Game sets it for a board night); `static func level_rect(i: int, count: int) -> Rect2` (a 12x10 badge at the top right of loadout slot `i`); `hit()` returns `"level:<i>"` there when the picker is on; a click steps that slot's power to the next level, 5 wrapping to 1, through `draft.set_level()` (a refusal shows `REFUSALS[reason]` as a pick's does); the badge reads `"L%d"`.

- [ ] **Step 1: Failing tests** `tests/test_board_test_mode.gd`:

```gdscript
# _all_open: a fresh SaveFile's board: for t in 1..5, open_tab(t) -> lock_line() == ""; choose("heart_of_faith") emits "pick"
# _no_upgrades: hit(MissionBoard.UPGRADES_RECT.get_center()) != "upgrades"; a U key press emits nothing; header_text() == MissionBoard.TEST_HEADER
# _no_locks: Game.locked_for(SaveFile.new(), false).is_empty() and Game.board_locked_for(SaveFile.new(), "warning").is_empty()
# _tier_budget: Game.board_def("warning") -> slots 3, dp_capacity 6; Game.board_def("last_judgement") -> 6, 16 (a save with
#   dp_bought 3 changes nothing: board_def takes no state)
# _bank_test: Game.bank_night(save, "warning", kit, {"won": true, "descend": {"main": true, "main_time": 190.0, "earned": 25, "kept": 2}}, false)
#   -> save.descend.believers == 0, night == 1, cleared has "warning", most_wishes.warning == 2, outcome.descend.bank.test == true
# _results: a ResultsScreen on that outcome -> its menu's actions == ["missions", "replay", "change"];
#   ResultsScreen.summary_lines(outcome)[0] == "Test mode: nothing banked"
# _level_picker: level_picker = true; setup(TierBook.board("warning"), ["smite", "tornado"]) (capacity 6): click(level_rect(1, 3).get_center())
#   four times -> draft.levels.tornado == 5 and draft.spent() == 6; click(level_rect(0, 3).get_center()) twice -> refused at 3
#   ("Not enough Might"), smite stays 2; one more click on tornado -> wraps to 1
# _picker_off: level_picker false -> hit(level_rect(0, 3).get_center()) does not begin with "level:" and draft.levels stays {}
```

- [ ] **Step 2: RED**, **Step 3: implement**; update the four old suites' assertions to the new rules.
- [ ] **Step 4: FLOW's board steps** (`game.gd`): `_flow_board` (every tab open, no rule line, the test header); `_flow_ascend` (no locked powers, `locked.size() == 0`, Tier 1's 3 slots and 6 Might); `_flow_results` (the bank is a test bank: night 1, believers 0, no Upgrades button; the Upgrades purchase steps go; The Warning's Prepare capacity is `TierBook.dp(1)`; a restart still hears the same wishes; caught by dawn: night 2, believers unchanged); `_flow_tier1`..`_flow_tier5` (Prepare capacity `TierBook.dp(t)`, no `open_tier` fixture, the results' bests instead of the progress line); `_veteran()` keeps only what the later steps still need. Add one check: a board Prepare with the picker on, a click on the first badge makes it `L2` and the budget counts it.
- [ ] **Step 5: GREEN** (suite 3).
- [ ] **Step 6: Unmoved:** `bash tools/dev/refs_check.sh --jobs=2 --only='^(digest|calm|warning_none|warning_b_play_1|tax_play_1|eye_play_1|night_b_play_1)$'` → OK (the board's UI only; the CLI's `--board` reads `TierBook.board(id, null)` as before).
- [ ] **Step 7: FLOW** -- the controller runs it alone after group B: `FLOW result ... failures=0`.
- [ ] **Step 8: Commit** `feat: the board is a test mode -- every tier and power open, nothing banked, Prepare's level picker (god P1, C3)`.

**Numbers:** none new. **References:** none may move. **Model:** sonnet; **review:** sonnet (many old assertions change; the reviewer checks each one still says something true).

---

### Task 7: Slot select and god select

**Goal:** spec §4 (3 slots, New / Continue / Delete with a confirm, overwrite after a confirm, type chosen once), §12 rows 1-2.

**Files:**
- Create: `src/game/ui/slot_screen.gd` (`class_name SlotScreen`), `src/game/ui/god_select_screen.gd` (`class_name GodSelectScreen`).
- Test: `tests/test_slot_screens.gd` (new; SUITES; files `user://test_slot_screens_<n>.cfg`).

**Interfaces (consumes):** Task 4 (`GodSlot.read`, `path`, `COUNT`), Task 3 (`GodTree.RING`, `FLAVOUR`, `neighbours`, `spot`, `NOT_CHOSEN`), `PowerBook.authority_title()`, `TierBook.tier_name()`.

**Interfaces (produces):**
- `SlotScreen`: `signal action(name: String)` (`"continue"`, `"new"`, `"back"`); `var chosen := 0` (1-3); `func setup(base := GodSlot.PATH_BASE) -> SlotScreen`; `static func slot_rect(i: int) -> Rect2` (i 0-2); `func slot_line(i: int) -> String` (`"Empty"`, or `"%s   Level %d   %s   Night %d" % [title, level, tier name, night + 1]`); per slot buttons: an empty slot `New`; a filled one `Continue`, `New`, `Delete`; `func button_rect(i: int, what: String) -> Rect2`; `func hit(point) -> String` (`"<what>:<i>"`); `func click(point)`; `New` on a filled slot and `Delete` ask `"Overwrite this god? It cannot be undone."` / `"Delete this god? It cannot be undone."` with `Confirm` / `Cancel` *(my call)*; `func confirm()`, `func cancel()`; Delete removes the file only on confirm; Esc: a pending confirm cancels, else `"back"`.
- `GodSelectScreen`: `signal action(name: String)` (`"chosen"`, `"back"`); `var chosen_type := ""`; `func setup() -> GodSelectScreen`; `static func ring_rect(i: int) -> Rect2` (six rects on an ellipse around `(320, 172)`, `RING[0]` at the top, clockwise); `func type_lines(type) -> PackedStringArray` (`[authority title, FLAVOUR line, "Tier 1: %s, %s" (the spots' power names or NOT_CHOSEN), "Neighbours: %s, %s"]`); `func select(i: int)`; `func confirm()` (emits `"chosen"`); a `Choose` button under the ring; Left/Right step the ring, Enter chooses, Esc `"back"`.

- [ ] **Step 1: Failing tests** `tests/test_slot_screens.gd`:

```gdscript
# _layout: the three slot rects and every button rect inside Rect2(0, 0, 640, 360), none overlapping; the six ring rects inside, none overlapping
# _empty: no files -> slot_line(i) == "Empty" for 0-2; click New on slot 1 -> emits "new", chosen == 1
# _filled: write GodSlot (ruin, level 3, night 3) at slot 2 -> slot_line(1) == "RUIN   Level 3   Whisper   Night 4"; Continue -> "continue", chosen 2
# _delete_confirm: Delete on 2 -> nothing emitted, the file still there; cancel() -> still there; Delete + confirm() -> the file gone, "Empty"
# _overwrite_confirm: New on 2 -> no "new" until confirm(); then "new", chosen 2
# _ring: type_lines("ruin") == ["RUIN", GodTree.FLAVOUR.ruin, "Tier 1: Not yet chosen, Not yet chosen", "Neighbours: DOMINION, DEATH"] (dev fill off);
#   with the dev fill on the third line is "Tier 1: Smite, Ember"
# _choose: select(2); confirm() -> chosen_type == "veil", "chosen" emitted; Esc -> "back"
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN** (suite 3).
- [ ] **Step 5: Commit** `feat: god save slots and the god select ring (god P1)`.

**Model:** sonnet; **review:** none. **References:** none.

---

### Task 8: The Skill Tree screen

**Goal:** spec §12 "Skill Tree" row, §5.2-§5.4.

**Files:**
- Create: `src/game/ui/skill_tree_screen.gd` (`class_name SkillTreeScreen`).
- Test: `tests/test_skill_tree.gd` (new; SUITES).

**Interfaces (consumes):** Task 4 (`refusal`, `learn`, `level_of`, `cost`, `might_of`, `points`, `tier`, `type`), Task 3 (`GodTree.spot`, `neighbours`, `NOT_CHOSEN`), Task 1 (`PowerBook.might`, `level_change`, `twist`, `has_levels`, `NO_LEVELS`).

**Interfaces (produces):**
- `signal action(name: String)` (`"learned"`: Game writes the slot; `"back"`); `func setup(slot: GodSlot) -> SkillTreeScreen`; `func columns() -> PackedStringArray` (`[left neighbour, own, right neighbour]`; far types never shown); `static func spot_rect(col: int, tier: int, i: int) -> Rect2` (three columns, five tier rows, two spots each); `const DETAIL := Rect2(...)`, `const BACK_RECT := Rect2(...)` (the builder's numbers inside 640x360); `func hit(point) -> String` (`"spot:<col>:<tier>:<i>"`, `"back"`, `""`); `func click(point)`; `func learn_at(col, tier, i) -> String` (the refusal, or `""` and `"learned"` emitted).
- `func spot_lines(col, tier, i) -> PackedStringArray` (what the spot draws, for tests): an empty spot `[NOT_CHOSEN]`; else `[power name, "%d / 5" pips text, "%d Might", next]` where next is `"Learn: %d point%s"`, `"Level %d: %d point%s"`, or `"Level 5"`; under it `PowerBook.level_change()` for the next level, or the twist at 5.
- Headers: own column the type's title; a neighbour column the title and `"x2"`; a tier row above the god's tier dim with `"Awaken to Tier %d"`; the header `"SKILL TREE   %s   Ability points %d"`.
- `const REFUSALS := {"unknown": "Not yet chosen", "far": "Too far from your nature", "tier": "Awaken to Tier %d", "max": "Already at level 5", "points": "Not enough ability points"}` *(my call)*, shown in the detail panel for 1.5 s.

- [ ] **Step 1: Failing tests** `tests/test_skill_tree.gd` (dev fill on, off at the end):

```gdscript
# _columns: a ruin god -> columns() == ["dominion", "ruin", "death"]
# _layout: the 30 spot rects inside the screen, none overlapping, none over DETAIL or BACK_RECT
# _lines: smite learned at 2 -> spot_lines(1, 1, 0) == ["Smite", "2 / 5", "1 Might", "Level 3: 1 point", PowerBook.NO_LEVELS];
#   a death spot (deathmark, not learned) -> its next line "Learn: 2 points"; with the dev fill off every line is [GodTree.NOT_CHOSEN]
# _locked_tier: a Tier 1 god: learn_at(1, 2, 0) == "tier" and level_of("heaven") == 0
# _learn: points 1: learn_at(1, 1, 0) == "" and level_of("smite") == 2 and "learned" emitted; again -> "points"
# _far_hidden: no point of the screen hits a spot of veil, passage or decree
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN** (suite 3).
- [ ] **Step 5: Commit** `feat: the skill tree -- own type between its neighbours, tiers gated, levels and costs (god P1)`.

**Model:** sonnet; **review:** none. **References:** none.

---

### Task 9: The Faith screen and the Endless Night hub

**Goal:** spec §7 (the Faith screen: a list, new rows are data), §9.1 hub, C9 (Notice shown as 0%).

**Files:**
- Create: `src/game/ui/faith_screen.gd` (`class_name FaithScreen`), `src/game/ui/god_hub.gd` (`class_name GodHub`).
- Test: `tests/test_faith_hub.gd` (new; SUITES).

**Interfaces (consumes):** Task 4 (`GodSlot.FAITH`, `faith_price`, `faith_refusal`, `buy`, `need`, `cap`, `capped`, `draftable`, every var shown), `TierBook.tier_name()`, `PowerBook.authority_title()`.

**Interfaces (produces):**
- `FaithScreen` (built from `UpgradesScreen`'s layout; `UpgradesScreen` itself stays: Ruling P12): `signal action(name: String)` (`"bought"`, `"back"`); `func setup(slot: GodSlot) -> FaithScreen`; `func rows() -> PackedStringArray` (the `FAITH` keys in order); `static func row_rect(i: int) -> Rect2`; `const BACK_RECT`; `func row_line(what) -> String` (`"%s   %d Faith   %d / %d"`, or `"%s   %d Faith   bought %d"` with no limit, or `"%s   All bought"`); `func hit(point)`, `func click(point)`, `func buy(what) -> bool`; header `"FAITH   %d"`; `const REFUSALS := {"faith": "Not enough Faith", "limit": "None left to buy", "nothing": "No ability point spent yet", "unknown": "Not an upgrade"}`; Esc `"back"`.
- `GodHub`: `signal action(name: String)` (`"descend"`, `"tree"`, `"faith"`, `"title"`, `"awaken_dev"`); `func setup(slot: GodSlot, line := "", dev := false) -> GodHub` (`line`: a one-off message, e.g. `GodNight.ABANDONED`); `static func bar_text(slot) -> String` (`"%d / %d Divine Power"`; at the cap below 50 `"AWAKEN TO GROW"`; at 50 `"MAX LEVEL"`); `func lines() -> PackedStringArray` (`[type title, "Level %d   %s" (tier name), bar_text, "Ability points %d", "Faith %d", "Lantern Notice %d%%", "Night %d" (night + 1)]`); `func can_descend() -> bool` (`not slot.draftable().is_empty()`); `const BLOCKED := "Nothing to draft: the tree's Tier 1 is not filled yet"`; `func blocked_line() -> String` (`BLOCKED` when it cannot descend, else `""`; drawn under the buttons); the buttons `Descend`, `Skill Tree`, `Faith`, `Title` (a Menu row); Enter descends, T tree, F Faith, Esc title; with `dev`, A emits `"awaken_dev"` and the hint shows `"DEV  A: awaken"` (Ruling P18). The Divine Power bar is drawn filled `divine_power / need()`.

- [ ] **Step 1: Failing tests** `tests/test_faith_hub.gd` (dev fill on, off at the end):

```gdscript
# _faith_rows: rows() == ["slot", "might", "clock", "respec"], each row_rect inside the screen, none overlapping BACK_RECT or each other;
#   row_line("slot") == "+1 SLOT   150 Faith   0 / 3"
# _faith_buy: faith 150: click(row_rect(0).get_center()) -> "bought", faith 0, row_line("slot") == "+1 SLOT   300 Faith   1 / 3";
#   faith 10: click on might -> refused_reason == "Not enough Faith", nothing emitted; Esc -> "back"
# _hub_lines: a fresh ruin god -> lines() == ["RUIN", "Level 1   Whisper", "0 / 50 Divine Power", "Ability points 0", "Faith 0",
#   "Lantern Notice 0%", "Night 1"]; level 10 -> bar_text "AWAKEN TO GROW"; tier 5 level 50 -> "MAX LEVEL"
# _hub_buttons: each button's rect clicked emits descend / tree / faith / title; A emits "awaken_dev" only when set up with dev true
# _hub_blocked: dev fill off -> can_descend() false, the Descend click emits nothing, and BLOCKED is drawn (a draw-free check: blocked_line() == BLOCKED)
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN** (suite 3).
- [ ] **Step 5: Commit** `feat: the Faith screen and the Endless Night hub (god P1)`.

**Model:** sonnet; **review:** none. **References:** none.

---

### Task 10: Endless Night's Results, Pause and Prepare

**Goal:** spec §9.2 (the results screen), §9.1 Prepare (learned abilities only, at their levels), §9.1 "no escape by quitting" (the pause menu says so before it confirms).

**Files:**
- Modify: `src/game/ui/results_screen.gd`, `src/game/ui/pause_menu.gd`, `src/game/ui/prepare_screen.gd` (owner hunks in the table).
- Test: `tests/test_endless_screens.gd` (new; SUITES).

**Interfaces (consumes):** Task 5's `GodNight.bank()` dictionary shape as `result.god` (from the plan; Task 5 runs beside this one, so this task reads the dictionary and never calls `GodNight`), Task 4, Task 3 (`GodTree.RING`, `spot_of`).

**Interfaces (produces):**
- `ResultsScreen.endless` (true when `result.has("god")`): the title and the descend rows as a board night's, then `static func god_lines(result) -> PackedStringArray` in spec §9.2's order: `"Divine Power +%d"` (with `"   AWAKEN TO GROW"` appended when `capped`), one `"Level %d   +1 ability point"` per level gained, `"Believers %d   Faith +%d, %d now"`, `"Lantern Notice %d%%"`, `"Night %d"` *(copy my call)*; the Divine Power bar under the first line fills over ~1 s and each level line flashes gold as the bar passes it (drawing only); the menu `["continue", "tree", "faith"]` / `["Continue", "Skill Tree", "Faith"]`; Enter and Esc continue.
- `PauseMenu.setup(campaign := false, settings = null, path := Settings.PATH, endless := false, forfeits := false)`: with `endless`, the rows are `["resume", "options", "abandon"]` / `["Resume", "Options", "Abandon night"]`; Abandon opens a confirm with `CONFIRM_LOST := "Abandon now and the night is lost: no Divine Power, no Faith."` when `forfeits`, else `CONFIRM_FREE := "The clock has not started: leaving is free."`, and the buttons `Abandon` / `Stay`; only the confirm emits `"abandon"`; Esc in the confirm is Stay. The board's and the campaign's menus are unchanged.
- `PrepareScreen.god: GodSlot` (set before `setup()`; Game sets it for an Endless Night def): `tabs()` are the `GodTree.RING` types holding a draftable key, in ring order; `authority_keys(i)` that type's draftable keys in spot order (the spot decides the tab, spec §5.2); `draft.levels` = the god's learned levels; each card shows `"L%d"` and its Might at that level; no level picker; the briefing panel's LOADOUT line counts the god's slots and Might.

- [ ] **Step 1: Failing tests** `tests/test_endless_screens.gd` (dev fill on, off at the end):

```gdscript
# _results_menu: a result with "god" and "descend" -> endless, the menu's actions == ["continue", "tree", "faith"]; Enter emits "continue"
# _god_lines: god {divine_power 120, levels [2, 3], capped false, believers 30, faith 30, faith_total 45, notice 0, night 1} ->
#   ["Divine Power +120", "Level 2   +1 ability point", "Level 3   +1 ability point", "Believers 30   Faith +30, 45 now", "Lantern Notice 0%", "Night 1"];
#   capped true, divine_power 80, levels [] -> first line "Divine Power +80   AWAKEN TO GROW"
# _pause_endless: setup(false, null, path, true, true) -> rows == ["resume", "options", "abandon"]; clicking Abandon emits nothing and the
#   confirm line == PauseMenu.CONFIRM_LOST; Stay -> rows again, nothing emitted; Abandon then the confirm's Abandon -> "abandon";
#   forfeits false -> CONFIRM_FREE; setup() with the defaults -> the five rows as before
# _prepare_god: a ruin god with smite 3, ember 1, deathmark 1 learned: prep.god = god; a def made here as GodNight.def_for() will make it
#   (TierBook.board("warning") with pool = god.draftable(); Task 5 runs beside this one, so do not call it) -> setup(def, []) ->
#   tabs() == ["ruin", "death"], authority_keys(0) == ["smite", "ember"], authority_keys(1) == ["deathmark"], draft.levels.smite == 3;
#   toggle("smite") -> spent() == 2; draft.refusal("heaven") == "pool"; hit() never returns "level:<i>"
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN** (suite 3).
- [ ] **Step 5: Commit** `feat: Endless Night's results, its pause menu's abandon confirm, and Prepare from the learned abilities (god P1)`.

**Model:** sonnet; **review:** none. **References:** none.

---

### Task 11: Wiring Endless Night into Game

**Goal:** spec §14 P1 "Endless Night loop from the DEV tab", C2, C7, C8, C9: every screen reachable, every night banked or forfeited, the photographs.

**Files:**
- Modify: `src/game/game.gd` (owner hunks), `src/game/ui/mission_board.gd` (`ENDLESS_RECT`).
- Test: `tests/test_endless_flow.gd` (new; SUITES; files `user://test_endless_flow_*.cfg`).

**Interfaces (consumes):** Tasks 3-10.

**Interfaces (produces):**
- `MissionBoard.ENDLESS_RECT := Rect2(158.0, 8.0, 72.0, 20.0)` (drawn `"ENDLESS"` beside DEV, `--dev` only); a click emits `"endless"`; `hit()` returns `"endless"` there with `dev` (Ruling P14).
- `Game.Screen` gains, appended (old values unchanged): `SLOTS, GOD_SELECT, HUB, TREE, FAITH`.
- `Game.FLOW` gains: `"board:endless": SLOTS`, `"slots:continue": HUB`, `"slots:new": GOD_SELECT`, `"slots:back": BOARD`, `"god:chosen": HUB`, `"god:back": SLOTS`, `"hub:descend": PREPARE`, `"hub:tree": TREE`, `"hub:faith": FAITH`, `"hub:title": TITLE`, `"tree:back": HUB`, `"faith:back": HUB`, `"prepare:hub": HUB`, `"results:continue": HUB`, `"results:tree": TREE`, `"results:faith": FAITH`, `"pause:abandon": HUB`, `"interlude:hub": HUB`.
- Vars: `god: GodSlot` (null outside Endless Night), `god_slot := 0`, `god_base := GodSlot.PATH_BASE` (`"user://test_flow_god_"` under `--flow-test`, its three files removed at the start and end; `"user://test_show_god_"` under `--show`), `_in_endless := false` (true from SLOTS to the hub and its nights; false at TITLE and BOARD, as `_in_campaign` is), `_hub_line := ""` (shown once by the next hub).
- `board:endless` turns `GodTree.dev_fill` on for the session (Ruling P2) and opens SLOTS.
- `static func load_god(file: String) -> Array` (`[GodSlot or null, line]`: a slot found with `in_night` set is forfeited at once, written, and the line is `GodNight.forfeit()`'s: Ruling P9).
- SLOTS `continue` -> `load_god()` -> HUB with the line; `new` -> GOD_SELECT; `chosen` -> `GodSlot.make(god_slot, type, seed from Time.get_ticks_usec())`, written (an overwrite replaces the file) -> HUB.
- HUB: `descend` -> `mission_id = GodNight.draw(god)`, `loadout = god.loadout` -> PREPARE (EN branch: `prep.god = god`, `prep.setup(GodNight.def_for(god, mission_id), loadout, save.difficulty)`); Prepare's back -> `"prepare:hub"` (free); `awaken_dev` -> `god.awaken()`, written, the hub rebuilt; `tree`, `faith`, `title` as FLOW says. TREE `learned` and FAITH `bought` write the slot.
- `_build_mission()` for Endless Night: `board = true`, `descend = null`, `night_def` (a Callable returning `GodNight.def_for(god, mission_id)`), `levels = god.learned.duplicate()`, `wish_seed = GodNight.wish_seed(god, mission_id)`, `restart_locked = true`, `clock_started` connected: `god.in_night = mission_id`, written (once).
- `_on_mission_finished()` in Endless Night: `static func bank_god_night(slot: GodSlot, id: String, kept: PackedStringArray, outcome: Dictionary) -> void` (`outcome["god"] = GodNight.bank(...)`, `outcome["best"] = false`), the slot written; **`save.save_to()` is not called** and `bank_night()` is not reached (C7: Ruling P10). Results -> `continue` / `tree` / `faith`.
- Pause in Endless Night: `_pause.setup(false, settings, settings_path, true, god.in_night != "")`; `"abandon"` -> forfeit when `in_night` is set (`_hub_line` = its line), written -> HUB; abandoned before the clock starts, nothing counts. The interlude's Missions in Endless Night -> forfeit -> `"interlude:hub"`; the between-acts Prepare in Endless Night is the god's (`prep.god = god`) on the act.
- `--show` photographs (`SHOW_SAVE`, `god_base` the show's, the dev fill on, a fixture god: ruin, level 7, tier 1, 3 points, smite 3, ember 1, deathmark 1 learned, faith 180, night 6): `"slots"`, `"god-select"`, `"hub"`, `"hub-capped"` (level 10), `"tree"`, `"faith"`, `"results-endless"` (`SAMPLE_ENDLESS_RESULT`: a won Warning, two wishes granted, +120 Divine Power, levels 7 and 8 gained), `"prepare-endless"` (The Warning), `"pause-endless"` (the abandon confirm open).

- [ ] **Step 1: Failing tests** `tests/test_endless_flow.gd`:

```gdscript
# _flow_table: every new FLOW entry above maps to its screen (Game.next_screen()); the old entries are unchanged ("title:play" BOARD ...)
# _bank_leaves_save (C7): a SaveFile with descend night 3, believers 40, cleared ["warning"] and a CampaignState; Game.bank_god_night(god,
#   "warning", kit, outcome) -> outcome.god.divine_power == 120 (the Task 5 _dp numbers), save.descend and save.campaign unchanged
#   (night, believers, cleared, campaign.night), no file written at SaveFile.PATH's test twin (bank_god_night takes no SaveFile at all)
# _load_god_forfeits: a slot written with in_night "tax_collector", night 2 -> Game.load_god(file) == [slot with night 3, in_night "",
#   last_mission "tax_collector"], line "Night 3 was abandoned: a lost night."; the file re-read says the same; a slot with in_night "" ->
#   line "" and night unchanged; a missing file -> [null, ""]
# _endless_button: a board with dev -> hit(ENDLESS_RECT.get_center()) == "endless" and a click emits "endless"; without dev -> ""
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN** (suite 8).
- [ ] **Step 5: Photographs:** for each show: `SCENE=res://scenes/game.tscn bash tools/capture.sh --show=<name> --capture`; look at each (text inside the frame, no overlap, the confirm readable). Memory `capture-diffs-unreliable`: photos are for eyes, not diffs.
- [ ] **Step 6: FLOW** alone (`tasklist | grep -i godot` first): `failures=0` (the board steps of Task 6 and the old steps still pass; Task 12 adds the walk).
- [ ] **Step 7: Unmoved:** `bash tools/dev/refs_check.sh --only='^(digest|calm|warning_none|tax_play_1)$'` → OK.
- [ ] **Step 8: Commit** `feat: Endless Night from the DEV tab -- slots, god select, the hub, nights banked to the god, forfeits; photographs (god P1)`.

**Model:** sonnet; **review:** sonnet (Game's state across screens; Review Focus 1, 5).

---

### Task 12: FLOW: the Endless Night walk

**Goal:** the loop proven through the real screens (spec §14 P1's "playable at its end").

**Files:** `src/game/game.gd` (`_flow_endless(step)`, called after `_flow_dev_town()`).

**Interfaces:** `Game._flow_endless(step: Callable) -> void`; ends on the board with `dev` restored, as `_flow_dev_town()` does.

- [ ] **Step 1: The walk** (each line one `step.call(...)`):
  1. With `dev` on, the board's ENDLESS opens SLOTS; three slots read `"Empty"` (the test god files were removed at start).
  2. New on slot 1 -> GOD_SELECT; choose Ruin -> HUB; the slot file exists; `god.level == 1`, `tier == 1`, `learned == {"smite": 1, "ember": 1}` (dev fill), hub `"Night 1"`.
  3. Skill Tree: learning anything is refused for points (`"points"`); Back -> HUB.
  4. A fixture seed (the first `s` in 1.. for which `GodNight.draw()` gives `"warning"`); Descend -> PREPARE: `prep.god == god`, `tabs() == ["ruin"]`, `draft.slots == 3`, `draft.capacity == 6`, `draft.locked.is_empty()`.
  5. MANIFEST -> the mission: `rules().mission.pool == god.draftable()`; past the intro `god.in_night == "warning"` and the file says so; an R press leaves the same `Rules` (restart locked).
  6. The three warnings stopped, F ascends -> RESULTS with `result.god`: `divine_power == 80 + 20 * kept`, `god.level >= 2`, `god.points >= 1`, `god.faith == result.descend.earned`, `god.night == 1`, `god.in_night == ""`; the slot file re-read agrees; the menu is Continue / Skill Tree / Faith.
  7. Skill Tree from the results: raise Smite to 2 -> `points` one less; Back -> HUB.
  8. Faith: `god.faith += 25` (a fixture), buy +1 Might -> `god.max_might() == 7`, the file agrees; Back -> HUB.
  9. Descend: the draw is not The Warning (no repeat); Prepare's capacity is 7; MANIFEST; past the intro; Pause shows Abandon (no Restart, no Change powers), its confirm says `CONFIRM_LOST`; confirm -> HUB; `god.night == 2`, `god.level` and `divine_power` unchanged, the hub's line `"Night 2 was abandoned: a lost night."`.
  10. Descend, MANIFEST, Pause **during the intro**: the confirm says `CONFIRM_FREE`; confirm -> HUB; `god.night` still 2.
  11. Descend, MANIFEST, past the intro (`in_night` set), then leave as a quit would (`go_to(Screen.BOARD)` with no forfeit); ENDLESS -> SLOTS -> Continue slot 1 -> HUB with `"Night 3 was abandoned: a lost night."`, `god.night == 3`.
  12. Hub Title -> TITLE; the title's rows are unchanged (`campaign`, `play`, `options`, `sandbox`, `quit`: C2); `save.descend.night`, `believers`, `cleared` and `save.campaign` are what they were before step 1 (C7).
- [ ] **Step 2: FLOW** alone: `FLOW result checks=<n> failures=0` (record n).
- [ ] **Step 3: Commit** `test: FLOW walks Endless Night -- a god made, a night won and banked, the tree, Faith, an abandon, a quit (god P1)`.

**Model:** sonnet; **review:** none. **References:** none (FLOW only).

---

### Task 13: Scripted-player plumbing (C6)

**Goal:** ruling C6: the per-type win check (spec §5.2) needs a scripted run restricted to one type's abilities of tiers 1..T, and played at a level. P1 builds the flags only; the check runs with the Tier 1 fill.

**Files:** `tools/dev/behaviour_check.gd` (the argument handling before `mission.start()`, and its header comment).

**Interfaces (consumes):** Task 3 (`GodTree.keys_for`, `outside`, `dev_fill`), Task 1 (`Mission.levels`).

**Interfaces (produces):**
- `--dev-tree`: `GodTree.dev_fill = true` for the run.
- `--god=<type>:<tier>` (tier defaults to 1): the drafted loadout must lie in `GodTree.keys_for(type, tier)`; otherwise the run prints `BEHAVIOUR refused god=<type>:<tier> outside=<k1,k2>` and quits 1 (gate.sh reads it as a FAIL); otherwise it prints `BEHAVIOUR god=<type>:<tier>` (in no checksum).
- `--level=<n>` (1-5): `mission.levels` = every drafted key at n.
- No flag given: the run is exactly as before.

- [ ] **Step 1:** `$G --headless --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=tax --case=play --seed=1 --god=veil:1 --dev-tree` prints `BEHAVIOUR refused god=veil:1 outside=whisper,discord` and exits 1.
- [ ] **Step 2:** `... --scenario=tax --case=play --seed=1 --level=3` runs to its result line (no refusal; no effect reads the level yet).
- [ ] **Step 3: Unmoved:** `bash tools/dev/refs_check.sh --jobs=2 --only='^(calm|tax_play_1|harvest_play_1|warning_b_play_1)$'` → OK.
- [ ] **Step 4: Commit** `dev: behaviour_check --god=<type>:<tier>, --dev-tree and --level= for the per-type win check (god P1, C6)`.

**Model:** sonnet; **review:** none.

---

### Task 14: P1 landing on `feat/god-progression` (C5)

**Goal:** everything checked together on the branch; nothing reaches `feat/Develop-Main`.

- [ ] `bash tools/dev/land.sh --bench=kak-v012-m2` (alone on the machine; it waits for other sessions' Godot): its trial merge against `origin/feat/Develop-Main` is reported only (a conflict is noted for the later merge, not fixed here); import exit 0; suite `failures=0`; references: all 286 rows OK, `bad=0`; FLOW `failures=0`; the five board benches within ~1 fps of `kak-v012-m2` (rerun a noisy pair on a quiet machine; memory `kak-m1-perf-debt`).
- [ ] A mover or a FLOW failure: find the task that caused it, fix it in a commit naming that task, rerun the failing step and then land.sh.
- [ ] Report: the table for the summary (suite count, refs 286/286, FLOW checks, the five bench pairs), every `Ruling:` from Tasks 1-13, and one Dev Ledger line per task.
- [ ] Commit only if something changed: `fix: god P1 landing -- <what>`. The controller then runs the opus milestone review (one fix wave, sonnet re-review) and tags `kak-god-p1` on `feat/god-progression`. Never ff, merge or push `feat/Develop-Main`.

**Model:** sonnet; **review:** none here.

---

### Task 15: Notes

**Files:**
- Create: `docs/KAK_God_P1_Summary.md` (what P1 built, by spec section; how to reach Endless Night: `--dev`, the board's DEV tab, ENDLESS; the numbers in play with *tunable* marks; the dev fill and how the user fills the tree (edit `GodTree.TABLE` only; the validation test); what is not yet there: the Notice's changes, Hunts and seals (P2), Awaken rites and gifts (P3-P4), the per-type win check with the Tier 1 fill, the title switch (spec §3); the landing table from Task 14).
- Create: `docs/KAK_God_P1_Rulings.md` (C1-C9 from `.superpowers/sdd/godp1/rulings.md`, this plan's P1-P24 as the controller settled them, and every task report's `Ruling:`).
- [ ] Commit `docs: god progression P1 summary and rulings`.
- [ ] Report the Dev Ledger lines for the controller (memory `kak-dev-ledger`; the controller writes them and refreshes the Discord board): one release row (`kak-god-p1`, branch `feat/god-progression`, the landing numbers); one `done` task per task 1-13 with `branch: feat/god-progression`; `todo` tasks for P2 Lantern, P3 First Rite, the Tier 1 fill (needs_you: true), the level tables batch 1 (needs_you: true); and the ideas left open (god names, the flavour lines' wording, deleting the board later).

**Model:** sonnet; **review:** none.

---

## Rulings

Each is a decision on a point where the spec and the code disagree or the spec is silent: what was decided, why, and what it costs if wrong.

- **Ruling P1** (Task 3): `GodTree.RING` is the spec's ring order; `PowerBook.AUTHORITIES` (the draft's tab order on the board) is left as it is. Why: the two orders do different jobs, and changing the board's tabs would move FLOW and tests for nothing. Cost if wrong: one const swap.
- **Ruling P2** (Tasks 3, 11): the dev fill is `GodTreeDev.TABLE`, merged over the real table's **empty** spots, never over a real key and never repeating a key the real table uses. It is on when Endless Night is entered from the DEV tab (and in tests that turn it on; both runners reset it). Why: spec §15 asks for a fill kept out of the real table, and the merge lets the user's Tier 1 fill take over spot by spot without touching the dev table. Cost if wrong: a slot made on the fill keeps keys the user's fill does not use (see P4).
- **Ruling P3** (Task 1): `extra["level"]` is put on a copy of every cast's `extra` (default 1), not only for powers with a table. Why: the effect needs no special case, and no P1 effect reads it, so no reference moves (proved in Tasks 1 and 14). Cost if wrong: none expected; a mover would show at once.
- **Ruling P4** (Task 4): starting abilities are ensured whenever a slot is read (a fill landed after the slot was made gives them, free, at level 1); a learned key that sits in no spot is kept in the file but neither drafted nor shown. Why: spec §4 gives them "for free"; a fill must not strand a god. Cost if wrong: an old god keeps an invisible key; a later cleanup can drop them.
- **Ruling P5** (Task 4): points earned are derived, `(level - 1) + 2 x (tier - 1)` (57 at level 50 after four rites), and respec sets `points` to that with only the starting two at level 1. Respec is refused when no point is spent. Why: spec §5.3's totals; one formula cannot drift from the stored points. Cost if wrong: a later source of points (none planned) needs a stored total.
- **Ruling P6** (Task 4): at the cap, Divine Power fills the bar to `need()` and stops; the excess is lost and reported (`lost`). Reaching level 10 keeps the leftover in the bar; the bar is only "full" once filled. Awaken keeps the bar and re-levels at the new need. Why: spec §8 "the bar stops at full", "earned while capped is lost". Cost if wrong: P3 sets the bar to 0 on a rite instead (one line).
- **Ruling P7** (Task 5): the Faith clock bonus is added to the night's clock after `TierBook.board()` set its stretch, so the mission's events keep the tier's times and only dawn comes later; a night with acts adds it to each act. Why: "+15 s on the descent clock" is more time, not slower events. Cost if wrong: one line moves before the stretch.
- **Ruling P8** (Tasks 5, 9): a god with nothing to draft gets the pool `["none"]` (no power allowed), and the hub's Descend is blocked with a line. Why: `MissionDef.powers()` treats an empty pool as every power, which would hand an empty god the whole book. Cost if wrong: none.
- **Ruling P9** (Tasks 5, 10, 11): "no escape by quitting" is kept by `GodSlot.in_night`, written when the clock starts (`Mission.clock_started`); Abandon (after a confirm that says so) or finding `in_night` set when the slot is opened forfeits the night as a lost one. Endless Night's pause menu has no Restart and no Change powers, R does nothing, and the interlude's Missions forfeits. Leaving from Prepare or during the intro is free. Why: spec §9.1; closing the game is the easiest escape. Cost if wrong: a crash mid-night costs a night (shown on the hub).
- **Ruling P10** (Task 11): an Endless Night night writes only the god's file: no board best, no `last_mission`, no `kak_save.cfg` write. Why: C7 and spec §4 (per-mission bests live in the slot). Cost if wrong: none.
- **Ruling P11** (Task 6): the board in test mode still counts `DescendState.night` (only to seed the wishes, never shown) and keeps its bests (cleared ticks, fastest, most wishes); believers are not banked and no tier opens. Results read "Test mode: nothing banked"; their buttons are Board, Again, Change powers. Why: spec §3 "nothing is saved but bests"; without the counter every board night of a mission would hear the same wishes forever. Cost if wrong: the counter is removed in one line.
- **Ruling P12** (Task 9): the Faith screen is a new `FaithScreen` modelled on `UpgradesScreen`; `UpgradesScreen` and `DescendState`'s shop stay in the code, unreachable from the board, as the Lantern campaign does. Why: C1's merge-cheap rule; the user may remove the board later (spec §3). Cost if wrong: dead code to delete in one later commit.
- **Ruling P13** (Task 6): the board's level picker is a badge on each loadout slot, a click steps 1→5→1, refused when the Might would go over; the levels are kept for Again and Restart but never saved. Why: the smallest UI that fits six slots in 640 px. Cost if wrong: layout only.
- **Ruling P14** (Task 11): the DEV entry is an `ENDLESS` button in the board's header beside DEV (`--dev` only). Why: a card would need a fake `MissionDef`. Cost if wrong: layout only.
- **Ruling P15** (Tasks 4, 7): P1 has no name entry; `name` is written empty and a slot shows its type's title. Why: the name is optional (spec §4) and text entry is new UI. Cost if wrong: a later small task.
- **Ruling P16** (Task 5): each night banked adds 1 to `carried[key]` for every drafted key, from P1 on. Why: P2's seal picks the most-carried ability (§10.3); recording now keeps P1 nights' history. Cost if wrong: an unused field.
- **Ruling P17** (Task 5): the night's draw uses `hash([slot.seed, slot.night])`, the wishes `hash([slot.seed, slot.night, id])`; `seed` is made once when the slot is made. Why: spec §9.1 "the same night" after quitting from Prepare; two gods do not share draws. Cost if wrong: none.
- **Ruling P18** (Task 9): the hub's DEV key A is the Awaken hook: tier + 1, +2 points, the cap lifted (P3's win without its gift or plate). Why: spec §14 P1 needs only a dev hook. Cost if wrong: none (dev only).
- **Ruling P19** (Task 3): the six flavour lines are first guesses for the user to rewrite. Cost if wrong: copy only.
- **Ruling P20** (Task 2): C1's "every screen" covers the Lantern campaign's screens too ("6 Might   3 slots ..."); dev tools' prints (`behaviour_check`, `town_debug`) keep DP. Why: the player reads the campaign's screens; the tools' readers are us. Cost if wrong: two strings back.
- **Ruling P21** (Task 11): an abandoned night has no results screen; the hub shows the lost night once. Why: §9.2's results are for a night played to its end; the hub line keeps the loss visible. Cost if wrong: a small results variant.
- **Ruling P22** (Task 5): Divine Power uses `Descent.report()`'s `kept` (wishes granted and banked), so a night caught after its main objective earns the main's only, and Faith is its `earned` (believers banked) 1:1. Why: spec §8 "caught after the main objective" and C8. Cost if wrong: none.
- **Ruling P23** (Task 4): a slot file whose type is not one of the six reads as an empty slot, and is replaced only through New's confirm. Why: a damaged god must not crash or be silently rebuilt as another type. Cost if wrong: a damaged god is lost (it already is).
- **Ruling P24** (Task 9): the hub also shows the unspent ability points (not in spec §9.1's list). Why: the player needs to know when the tree has something to buy. Cost if wrong: one line.

## Needs the user (not blocking P1)

- The Tier 1 fill of `GodTree.TABLE` (12 spots) before Endless Night reaches the title (spec §3); its per-type win check (C6) runs then, with Task 13's flags.
- The flavour lines (Ruling P19) and the Endless Night copy marked *(my call)*.
