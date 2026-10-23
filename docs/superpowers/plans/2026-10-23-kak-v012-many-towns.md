# KAK v0.12 "Many Towns" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Run it the KAK way: `.claude/skills/kak-milestone/SKILL.md` (sonnet implementers, no per-task review for mechanical tasks, `implementer.md` dispatches from `.superpowers/sdd/v012/`).

**Goal:** M1 -- merge `feat/capital-city`, make every mission read its places from the active town, list what each needs, let a town override a mission's spots and numbers, and run any mission in a chosen town (`--city=`, the board's DEV tab), with Aldermere exact. M2 -- the five Tier 1 missions hostable and gated in the Capital, dev-only.

**Architecture:** `CityDef` names places (`landmark()`, new `place()`, lists); missions read them through a static `Places` helper. `MissionNeeds` is one table of each mission's needs, checked against what its director reads. A town's spots and numbers for a mission live in `src/game/town/cities/<city>_missions/<mission_id>.gd` (`overrides() -> {"def": {}, "director": {}}`), applied by `MissionBook.in_city()` and `Overrides.apply()` onto **town vars** that each hosted director seeds from its own consts. A night in another town is the composite id `<mission>@<city>` (or `--city=` on the CLI); it has no Descent in v0.12.

**Tech Stack:** Godot 4.7.2 GDScript; headless suite `tests/run_all.gd` / `tools/dev/run_suite_parallel.sh`; references `tools/dev/refs_check.sh`; scripted play `tools/dev/behaviour_check.gd` (+ `tools/dev/routes/tier1_b.gd`); gates `tools/dev/gate.sh`; landing `tools/dev/land.sh`.

**Spec:** `docs/superpowers/specs/2026-10-23-kak-v012-many-towns.md` (Decisions 1-29; cited D1-D29). Rulings: `.superpowers/sdd/v012/rulings.md` (R1-R31; binding over this text where they differ).

## Global Constraints

- G = `/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`; every command from the worktree root; foreground only, each under 10 minutes. A fresh worktree imports once: `timeout 900 $G --headless --editor --path . --import >/dev/null 2>&1` (again after a new class_name or test file).
- Per task: focused tests, then `bash tools/dev/run_suite_parallel.sh 8` (`3` in a parallel phase; expect `failures=0`), then `bash tools/dev/refs_check.sh --only='<touched>'` (`--jobs=2` in a parallel phase); FLOW only where the task says, alone (memory `flow-needs-quiet-machine`), never in a parallel phase (the controller runs it after merging the group).
- **Aldermere exact** (spec §0.2): `digest` `61267b7e90524d800bf1c3473a71146b`, every one of the 233 rows in `tools/dev/refs/*.tsv` at `1c28dc0`, FLOW `failures=0`, bench within ~1 fps. **No Aldermere row may move in this release.** A mover is a bug in the task that moved it. Only `capital_calm` / `capital_evac` and the new `capital_*` rows may be (re-)recorded, each with its reason in the commit body (`name old -> new: why`).
- Exactness rule (D9): a `TownLayout.X` read becomes the same expression on the city's value; an Aldermere literal spot stays a literal (never replaced by a computed equal).
- Gates (M2, seeds 1-3): none loses 3/3; play wins ≥2/3; route a median 180-240 s; route b median 150-270 s (★ Starfall: reported); idle ≤45 s; no designed wait >60 s; toll case wins ≥2/3 (Starfall, Tax binding; Prayers per C12). Misses: the spot first (walk parity, D26), then the scripted policy, then the mission's numbers in spec §2's order, at most three rounds, else DONE_WITH_CONCERNS with the numbers. Never tune the opposition down before the policy; never touch Aldermere's numbers.
- Colours: target `d8b23a`, place `ff9a3a`, danger `c8342a`, charge `8fb8e8`, not-yet `9a948a`, clear `7fc46a`. Keys: no new key in a mission (`D` on the board under `--dev` comes from the merge). Text and drawn shapes only; no PixelLab.
- Freed bodies: never touch a freed Person; `is_instance_valid()` where a reference is held across frames.
- Copy in the spec is exact. Tests: `t.check(cond, "message")`, one static `run(t)` per file, new files in `tests/run_all.gd` SUITES.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Each `Ruling:` of a report goes to the rulings file and the summary (Task 15).
- Never edit another worktree (`vfxProve-capital` is read-only); never stop a process you did not start.

## Review Focus

1. **Aldermere exact across the merge:** the full reference run after Task 1 is 233/233 OK; a capital crowd rule that moves an Aldermere row is switched off for Aldermere (D5), never re-recorded. Task 1 (`refs_check.sh` full).
2. **City state never leaks:** a Capital night then an Aldermere night builds Aldermere exactly (the capital's `_leak` test, kept), and `City.current()` is the def's city before `Town.new()` on every path (Game, CLI `--city`, `behaviour_check`, Restart). Task 4 (`_restart_keeps_city`), Task 7 (FLOW step).
3. **Overrides cannot be silent:** an unknown key or a type mismatch in any `<city>_missions/*.gd` fails the suite; town overrides apply after the board's `tune`; Aldermere never applies any; a director's `_plan()`/`_begin()` never overwrites a town var. Task 4 (`_unknown_key`, `_order`), Task 6 (`_override_survives_setup`), Tasks 9-13 (`_overrides_valid`).
4. **Town vars seeded exactly:** every Tier 1 director's town var equals its const on a fresh director, and the policies read the vars; the 51 Tier 1 rows (A, B, toll) do not move. Task 6.
5. **No Descent off Aldermere:** a composite-id night banks nothing (`save.descend` unchanged after a Capital night's result), greys no power, and its best is kept under the composite id. Task 4 (`_no_descent`), Task 7 (`_dev_night_banks_nothing`).
6. **Needs match reads:** every `Places.*(&"name")` in a director (and its bases) is in its needs; Aldermere hosts all; the Capital hosts only what has an overrides file. Task 3 (`_reads_are_needs`), Task 4 (`_hostable`).

---

## Task order and parallelism

| # | Task | Milestone | Model | Review | Parallel group |
|---|---|---|---|---|---|
| 1 | Merge `feat/capital-city` (and record the Capital's references) | M1 | sonnet | sonnet | serial |
| 2 | The place API: `CityDef.place()`, new landmarks and lists, `Places`, `citadel_gate` | M1 | sonnet | sonnet | serial |
| 3 | Missions and descend off TownLayout; the guard extended; `MissionNeeds` | M1 | sonnet | none | **A** (A1) |
| 4 | Town overrides, hostable, composite ids, `--city`, no Descent off Aldermere | M1 | sonnet | sonnet | **A** (A2) |
| 5 | Tooling: `gate.sh --city --with-none`, `land.sh --bench-only` | M1 | sonnet | none | **A** (A3) |
| 6 | Tier 1 directors take town vars; the policies read them | M1 | sonnet | none | **B** (B1) |
| 7 | The DEV tab lists town missions; FLOW's town step | M1 | sonnet | none | **B** (B2) |
| 8 | M1 landing (`kak-v012-m1`) | M1 | sonnet | none (controller's opus milestone review) | serial |
| 9 | Starfall in the Capital | M2 | sonnet | sonnet | **C** (C1) |
| 10 | The Tax Collector in the Capital | M2 | sonnet | sonnet | **C** (C2) |
| 11 | Spoiled Harvest in the Capital | M2 | sonnet | sonnet | **C** (C3) |
| 12 | The Lost Lamb in the Capital | M2 | sonnet | sonnet | **C** (C4) |
| 13 | First Prayers in the Capital | M2 | sonnet | sonnet | **C** (C5) |
| 14 | M2 landing: sweep, FLOW step, bench (`kak-v012-m2`) | M2 | sonnet | none (controller's opus milestone review) | serial |
| 15 | Notes: summary, rulings, README/DEV notes, Dev Ledger lines | M2 | sonnet | none | serial |

Order: 1 → 2 → A (3, 4, 5 at once) → B (6, 7 at once) → 8 (land M1) → C (9-13 at once, each in its own worktree off `kak-v012-m1`) → 14 → 15 → the controller tags `kak-v012-m2`. Inside a group the controller merges in number order, then runs FLOW alone once. Task 1 is serial and long (full references, FLOW); keep the laptop awake (`mcp__ccd_host__request_keep_awake`). No task needs opus: none is a redesign (the merge follows spec §1.1's table).

**Shared files and their owners** (one hunk each; keep all on merge):

| File | Group A | Group B | Group C |
|---|---|---|---|
| `src/game/mission/mission_book.gd` | 3: the TownLayout camera/intro lines only; 4: new functions `city_id`, `split_city`, `in_city`, `hostable`, `town_missions`, the composite branch of `is_dev` and `get_mission` | -- | none |
| `src/game/mission/mission_def.gd` | 3: `camera_at` default, `camera()`, `needs()` | -- | none |
| `src/game/mission.gd` | 3: the five `camera_at` reads -> `camera()`; 4: `--city`, the Descent condition, `def_for` composite | -- | none |
| `src/game/town/city_def.gd` | 4: body of `mission_overrides()`, `missions_dir()` (Task 2 adds the stub) | -- | none |
| `tools/dev/behaviour_check.gd` | 4: `city=` in `_board_line()` only | 6: Tier 1 policy functions | each task its own scenario's functions only |
| `tools/dev/routes/tier1_b.gd` | -- | 6: const reads -> vars | each task its own `act_`/`state_` pair only |
| `tests/run_all.gd` | 3, 4: one line each | 6: one line | one line each |
| `tests/test_city.gd` | 3: the guard | -- | none |
| `tests/test_tier_board.gd` | -- | 7: `_dev` | none (Task 14 extends `_dev`) |
| `src/game/town/cities/capital_city.gd` | -- | -- | **none** (spots are literals in the task's overrides file; a missing name is NEEDS_CONTEXT) |

---

### Task 1: Merge `feat/capital-city`

**Goal:** spec §1.1. The capital's city format, its sandbox, its DEV tab and its tests on this branch; Aldermere exact; the Capital's references measured and recorded.

**Files:**
- Merge: `origin/feat/capital-city` (`f7d74922`) into `feat/v012`; resolve the five conflicts per spec §1.1's table.
- Modify: `src/game/descend/pressed_wish.gd` (`TownLayout.BARRACKS` -> `City.current().landmark(&"barracks")`).
- Modify (D4): `src/game/mission/first_prayers_director.gd` l. 145, `src/game/mission/lantern_bearer.gd` l. 235 and 248, `src/game/descend/neighbours_wish.gd`, `src/game/descend/punish_wish.gd`, `src/game/crowd/banishing_rite.gd` (two) -> `CitizenProfile.is_clergy(...)`.
- Modify: `tools/dev/refs/references.tsv` (two seq rows `capital_calm`, `capital_evac`).
- Test: `tests/test_v012_merge.gd` (new; SUITES).

**Interfaces:** none new beyond the merge's (`CityDef`, `City`, `AldermereCity`, `CapitalCity`, `MissionDef.city`, `MissionBook.dev_missions()/is_dev()/capital_sandbox()`, `Game.dev`, `Game.board_locked_for()`, `MissionBoard.DEV_TIER/DEV_RECT/dev`).

- [ ] **Step 1: The Capital's references at its tip.** `git worktree add --detach <scratchpad>/wt-capital f7d74922`; import there; run `--scenario=capital_calm --seconds=60` and `--scenario=capital_evac` (rendered, `--fixed-fps 60 --audio-driver Dummy`, as `refs_check.sh` runs seq rows); note both checksums; `git worktree remove --force` it. (Memory says -370675099 / -870513036, the capital summary -713901328 / 731230687: R2 -- trust only this run.)
- [ ] **Step 2: Failing test** `tests/test_v012_merge.gd`:

```gdscript
# _clergy (D4): a monk is clergy; no "is clergy" test compares Role.CLERGY by == or != in mission/descend/the rite
t.check(CitizenProfile.is_clergy(CitizenProfile.Role.MONK) and CitizenProfile.is_clergy(CitizenProfile.Role.CLERGY), "monks and clergy")
# scan src/game/mission, src/game/descend, src/game/crowd/banishing_rite.gd (comments stripped): no "role == CitizenProfile.Role.CLERGY"
#   nor "role != CitizenProfile.Role.CLERGY" -> found list empty (the message names the files)
# _pressed_door: City.use(&"aldermere"); PressedWish's door == the value the v0.11.2 expression gave on TownLayout.BARRACKS
# _sandbox: MissionBook.get_mission(MissionBook.CAPITAL_SANDBOX).city == &"capital"; MissionBook.is_dev("capital_sandbox")
# _aldermere_people: City.use(&"aldermere"); City.current().citizens() + City.current().soldiers() == Mission.PEOPLE (220 + 100)
```

- [ ] **Step 3: RED** (the clergy scan names the five files), then **merge and resolve**; then the semantic work above. The guard (`tests/test_city.gd::_no_hardcoded`) must pass (it catches `pressed_wish.gd`).
- [ ] **Step 4: GREEN:** import; suite 8 `failures=0` (the twelve capital suites included).
- [ ] **Step 5: Aldermere exact, everything:** `bash tools/dev/refs_check.sh --jobs=6` → all 233 rows OK. A mover: find the capital rule that moved it (river step, wade ashore, waypoint landing), put it behind a `CityDef` switch off for Aldermere (D5, R8), rerun. Never re-record an Aldermere row.
- [ ] **Step 6: The Capital's rows on the merged tree:** add `capital_calm	--scenario=capital_calm --seconds=60	<sum>` and `capital_evac	--scenario=capital_evac	<sum>` to `references.tsv`; if either differs from Step 1, name the cause (a v0.11.x shared change, e.g. the startle) in the commit body: `capital_evac <tip> -> <merged>: why`.
- [ ] **Step 7: FLOW alone** (`tasklist | grep -i godot` first): `FLOW result ... failures=0` (127 checks expected).
- [ ] **Step 8: Commit** the merge: `merge: feat/capital-city into v0.12 -- the city format, the Capital and its sandbox; Aldermere exact`; body: the five conflicts and how each was resolved, the semantic edits, both Capital checksums (tip and merged), `refs 235/235`, FLOW count.

**Numbers:** none. **References:** no Aldermere row moves; `capital_calm`, `capital_evac` added. **Gate:** full refs, suite, FLOW. **Model:** sonnet; **review:** sonnet (the five resolutions against both parents).

---

### Task 2: The place API

**Goal:** spec §1.2. Names for every place a mission reads, on both cities; the `Places` helper; the Citadel's gate as a place.

**Files:**
- Modify: `src/game/town/city_def.gd` (`place()`, `gate_towers()`, `barns()`, stub `mission_overrides()`), `src/game/town/cities/aldermere_city.gd`, `src/game/town/cities/capital_city.gd`, `src/game/town/city.gd` (`IDS`).
- Create: `src/game/mission/places.gd` (`class_name Places`).
- Modify (D3): `src/game/descend/rescue_wish.gd` (`GATE` -> `Places.point(&"citadel_gate")`), `src/game/mission/harvest_director.gd` and `src/game/mission/tax_collector_director.gd` (their `CITADEL_GATE` consts removed; the code reads the place).
- Test: `tests/test_places.gd` (new; SUITES).

**Interfaces (produces):**
- `CityDef.place(name: StringName) -> Vector2` (`Vector2.INF` unknown); `CityDef.gate_towers() -> Array[Rect2]` (`[]`); `CityDef.barns() -> Array[Rect2]` (`[]`); `CityDef.mission_overrides(mission_id: String) -> Dictionary` (returns `{}`; Task 4 fills it).
- `AldermereCity`: `LANDMARKS` gains `&"fountain": TownLayout.FOUNTAIN`, `&"side_gate": TownLayout.SIDE_GATE`; `const PLACES := {&"citadel_gate": Vector2(-10.5, -7.6), &"postern": TownLayout.POSTERN_AT, &"citadel": TownLayout.CITADEL_ORIGIN}`; `gate_towers()` -> `TownLayout.GATE_TOWERS`; `barns()` -> `TownLayout.BARNS` (typed fresh copies).
- `CapitalCity`: `landmark()` gains `&"fountain"` (`FOUNTAINS[0]`), `&"side_gate"` (the harbour gate, `inner[4]`); `place()`: `&"citadel_gate"` `CITADEL_ORIGIN + Vector2(0.0, 2.9)`, `&"citadel"` `CITADEL_ORIGIN`; `barns()` -> `BARNS`.
- `City.IDS := [&"aldermere", &"capital"]`.
- `Places` (static): `rect(name) -> Rect2`, `point(name) -> Vector2`, `at(name) -> Vector2`, `has(city: CityDef, need: StringName) -> bool` (list needs `gate_towers`, `barns`, `taverns`, `wells`, `fountains`, `districts`, and `<list>:<n>` for "at least n"; `citadel`; else landmark area or place), `const LIST_NEEDS`.

- [ ] **Step 1: Failing tests** `tests/test_places.gd`:

```gdscript
# _aldermere_exact
var al := City.by_id(&"aldermere")
t.check(al.landmark(&"fountain") == TownLayout.FOUNTAIN and al.landmark(&"side_gate") == TownLayout.SIDE_GATE, "new landmarks are TownLayout's")
t.check(al.place(&"citadel_gate") == Vector2(-10.5, -7.6) and al.place(&"postern") == TownLayout.POSTERN_AT, "places are the literals")
t.check(al.gate_towers() == _rects(TownLayout.GATE_TOWERS) and al.barns() == _rects(TownLayout.BARNS), "lists")
t.check(al.place(&"nowhere") == Vector2.INF, "an unknown place is INF")
# _capital
var c := City.by_id(&"capital")
t.check(c.place(&"citadel_gate") == CapitalCity.CITADEL_ORIGIN + Vector2(0.0, 2.9) and c.gate_towers().is_empty(), "the Capital's gate, no towers")
t.check(c.landmark(&"fountain") == CapitalCity.FOUNTAINS[0], "the Great Market's fountain")
t.check(c.landmark(&"side_gate").has_area() and c.landmark(&"side_gate") == c.landmark(&"harbour_gate"), "the harbour gate")
# _has
t.check(Places.has(c, &"citadel") and not Places.has(c, &"gate_towers") and Places.has(c, &"taverns:2"), "needs in the Capital")
for n in [&"temple", &"bell_tower", &"citadel", &"citadel_gate", &"market_square", &"gate_towers", &"barns:4", &"fountain"]:
	t.check(Places.has(al, n), "Aldermere has %s" % n)
# _helper: City.use(&"aldermere"); Places.rect(&"temple") == TownLayout.TEMPLE; Places.at(&"citadel_gate") == Vector2(-10.5, -7.6);
#   Places.rect(&"nope") == Rect2() (an error is printed)
# _rescue_gate: City.use(&"aldermere"); the RescueWish's goal point == Vector2(-10.5, -7.6) (snapped as before)
# _citadel_gate_walkable: a built Capital (as tests/test_capital_evac.gd builds one): WalkGrid.nearest_walkable(citadel_gate) within
#   0.6 of it, and WalkGrid.path(the Great Market's centre, it) not empty
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN** (suite 8 `failures=0`).
- [ ] **Step 5: Unmoved:** `refs_check.sh --only='^(digest|crowd_check|calm|tax_|harvest_|capital_)'` → OK (the Citadel's gate read through the place; `tax_*`, `harvest_*` with their B and toll rows are the ones it could reach).
- [ ] **Step 6: Commit** `feat: places by name -- CityDef.place(), the Citadel's gate, fountain and side gate; Places for missions (v0.12 M1)`.

**Numbers:** none. **References:** none may move. **Gate:** none. **Model:** sonnet; **review:** sonnet (the API every later task builds on).

---

### Task 3: Missions and descend off TownLayout; the guard; `MissionNeeds`

**Goal:** spec §1.3 and §1.4's table and scan. No file under `src/game/mission`, `src/game/descend` or `tools/dev/routes` reads `TownLayout`; every mission lists its needs.

**Files:**
- Modify (each code read, spec §1.3's list, D9): `armoury_director.gd`, `bell_ringers_director.gd`, `broken_lanterns_director.gd`, `crowns_bread_director.gd`, `festival_director.gd`, `heretic_hunt_director.gd`, `lantern_eye_director.gd`, `lantern_watch.gd`, `miras_house_director.gd`, `mission_director.gd`, `procession_director.gd`, `relic_run_director.gd`, `sermon_director.gd`, `tax_collector_director.gd`, `vigil_flame_director.gd`, `mission_book.gd` (camera/intro lines only), `tools/dev/routes/tier3_b.gd`, `tools/dev/routes/tier4_b.gd`. A comment naming `TownLayout.X` may stay (the guard ignores comments) but should say "the city's X".
- Modify: `src/game/mission/mission_def.gd` (`var camera_at := Vector2.INF`; `func camera() -> Vector2`; `func needs() -> PackedStringArray`), `src/game/mission.gd` (its five `play.camera_at` reads -> `play.camera()`).
- Create: `src/game/mission/mission_needs.gd` (`class_name MissionNeeds`).
- Modify: `tests/test_city.gd` (`_no_hardcoded`: DIRS += `res://src/game/mission`, `res://tools/dev/routes`; a function-scoped scan of `behaviour_check.gd`).
- Test: `tests/test_mission_needs.gd` (new; SUITES).

**Interfaces (produces):**
- `MissionDef.camera() -> Vector2`: `camera_at` unless `Vector2.INF`, then `City.current().citadel_origin()` (an `ActDef` inherits it).
- `MissionDef.needs() -> PackedStringArray`: `MissionNeeds.of(id)`.
- `MissionNeeds.TABLE := {id: PackedStringArray}` for every id of `MissionBook.all()`, `campaign_missions()`, `tier_missions()`, `dev_missions()` and `TierBook.all()` (Tier 1 rows exactly as spec §1.4; the others from the scan, e.g. `armoury` with `barracks`, `taverns:2`, `gate_towers`; `crowns_bread` with `barns:4`, `gate_towers`; `heretic_hunt` with `districts`; `capital_sandbox` `[]`); `static func of(id: String) -> PackedStringArray` (unknown id: `push_error`, empty).
- Guard: `const POLICY_FUNCS := ["_tax", "_harvest", "_lamb", "_faith_", "_prayers", "_warning", "_watch_bearer_act", "_toll_", "_scripted"]` -- every `func` in `behaviour_check.gd` whose name starts with one of them has no `TownLayout.` in its body.
- `MissionDef.intro_from`'s default `Vector2(2.7, 12.0)` stays (every Tier 1 mission sets its own; a town sets it by override).

- [ ] **Step 1: Failing tests:**

```gdscript
# test_city._no_hardcoded (extended): with the new DIRS the found list names the 17 mission files and the two route files -> RED
# test_mission_needs._every_mission
for id in _all_ids():   # MissionBook.all/campaign/tier/dev + TierBook.all
	t.check(MissionNeeds.TABLE.has(id), "%s lists its needs" % id)
	t.check(Places.can_host(id, City.by_id(&"aldermere")), "Aldermere hosts %s" % id)
# _reads_are_needs: for each mission with a director, the names in Places.rect/at/point(&"...") calls in its script and every base
#   script (get_base_script() up to MissionDirector) are all in MissionNeeds.of(id); the message lists the missing names
# _tier1: MissionNeeds.of("spoiled_harvest") == PackedStringArray(["citadel", "citadel_gate"]) ... (spec §1.4's five rows exactly)
# _camera: MissionDef.new().camera_at == Vector2.INF; City.use(&"aldermere") -> MissionDef.new().camera() == TownLayout.CITADEL_ORIGIN;
#   a def with camera_at set returns it
```

- [ ] **Step 2: RED**, **Step 3: implement** (spec §1.3; same expressions, D9); `Places` everywhere a mission reads a place.
- [ ] **Step 4: GREEN** (suite 3 `failures=0`).
- [ ] **Step 5: Unmoved -- every board row:** `bash tools/dev/refs_check.sh --jobs=2` (all 235 rows; this task touches 17 directors) → OK.
- [ ] **Step 6: Commit** `refactor: missions read their places from the town -- no TownLayout in mission, descend or routes; each mission lists its needs (v0.12 M1)`.

**Numbers:** none. **References:** none may move. **Gate:** none (no rule changes). **Model:** sonnet; **review:** none (mechanical; the full references prove it). FLOW: the controller after group A (`camera()` is read by the intro).

---

### Task 4: Town overrides, hostable, composite ids, `--city`, no Descent off Aldermere

**Goal:** spec §1.5 and §1.6. A town can override a mission's def and director values; a mission can run in a chosen town by id or by flag.

**Files:**
- Create: `src/game/mission/overrides.gd` (`class_name Overrides`); the test fixture `tests/fixtures/town_missions/tax_collector.gd` (a test-only overrides file) and a fixture city in the test (a `CityDef` stub whose `missions_dir()` is `res://tests/fixtures/town_missions`, every other answer the Capital's).
- Modify: `src/game/town/city_def.gd` (`mission_overrides()` body, `missions_dir()`), `src/game/mission/mission_book.gd`, `src/game/mission.gd` (`def_for()`, `start()`'s city, the Descent condition, `wanted_city()`), `tools/dev/behaviour_check.gd` (`_board_line()` prints `city=`).
- Test: `tests/test_town_overrides.gd` (new; SUITES).

**Interfaces (produces):**
- `CityDef.missions_dir() -> String` (`"res://src/game/town/cities/%s_missions" % id()`); `CityDef.mission_overrides(mission_id) -> Dictionary`: `<missions_dir>/<mission_id>.gd` loaded if `ResourceLoader.exists()`, its `overrides()`; else `{}`. `AldermereCity.mission_overrides()` returns `{}` always. The folder `src/game/town/cities/capital_missions/` is created by M2's first file.
- `Overrides.apply(target: Object, values: Dictionary) -> PackedStringArray`: sets each key with `set()`; returns (and `push_error`s) every key the target has no property for, and every value whose `typeof` differs from the property's current value (not set). `const KEYS := ["def", "director"]`.
- `MissionBook`: `const CITY_SEP := "@"`; `static func city_id(id: String, city: StringName) -> String`; `static func split_city(id: String) -> Array` (`[base, city]`, `city` `&""` when none); `static func in_city(m: MissionDef, city: StringName, from: CityDef = null) -> MissionDef` (sets `m.city`; `Overrides.apply(m, ov.def)`; wraps `m.tune` so the board's tune runs, then `Overrides.apply(d, ov.director)`; `from` defaults to `City.by_id(city)` and lets a test pass a fixture); `static func hostable(id: String, city: CityDef) -> bool` (D13); `static func town_missions(city: StringName) -> PackedStringArray` (composite ids of `TierBook.all()` hostable there, tier order; `[]` for Aldermere); `is_dev(id)` also true for a composite id; `get_mission(composite)` -> `in_city(get_mission(base), city)`.
- `Mission.def_for(id, on_board, state)`: a composite id -> `MissionBook.in_city(def_for(base, on_board, state), city)`.
- `static func Mission.wanted_city(args: PackedStringArray, autostart: bool) -> StringName` (`--city=` when autostart, else `&""`). `Mission.start()`: after `_def = _mission_def(args)`, the wanted city is the `city` var if set, else `wanted_city()`; if set and not `_def.city`, `_def = MissionBook.in_city(_def, wanted)`; then `City.use(_def.city)` (the merge's line, before `Town.new()`). `_descent` only when `_def.city == &"aldermere"` (D20).

- [ ] **Step 1: Failing tests** `tests/test_town_overrides.gd`:

```gdscript
# _ids
t.check(MissionBook.city_id("tax_collector", &"capital") == "tax_collector@capital", "composite id")
t.check(MissionBook.split_city("tax_collector@capital") == ["tax_collector", &"capital"] and MissionBook.split_city("warning")[1] == &"", "split")
t.check(MissionBook.is_dev("tax_collector@capital") and not MissionBook.is_dev("tax_collector"), "a town night is a dev night")
# _apply (the fixture overrides {"def": {"camera_at": Vector2(1, 2)}, "director": {"hide_seconds": 31.0}})
var m := MissionBook.in_city(MissionBook.tax_collector(), &"capital", _fixture())
t.check(m.city == &"capital" and m.camera_at == Vector2(1, 2), "def overrides applied")
t.check(is_equal_approx((m.make_director() as TaxCollectorDirector).hide_seconds, 31.0), "director overrides on the made director, before setup")
# _unknown_key: Overrides.apply(MissionDef.new(), {"no_such": 1, "camera_at": "x"}) == PackedStringArray(["no_such", "camera_at"])
# _order: a def whose board tune sets d.hide_seconds = 10.0, in the fixture town (31.0) -> the made director has 31.0
# _aldermere_none: for every mission id, City.by_id(&"aldermere").mission_overrides(id).is_empty()
# _hostable: hostable("tax_collector", aldermere) true; hostable("tax_collector", capital) false (no overrides yet);
#   hostable("tax_collector", the fixture city) true; town_missions(&"aldermere").is_empty()
# _def_for: Mission.def_for("warning@capital", true, null).director == StarfallDirector and .city == &"capital"
# _no_descent: a Mission started with mission_id "tax_collector@capital", board true -> _descent == null; "tax_collector" -> not null
# _restart_keeps_city: the same Mission started twice with "tax_collector@capital" -> City.current().id() == &"capital" both times;
#   then with "tax_collector" -> &"aldermere" and City.current().structures() == AldermereCity.new().structures()
# _cli_city: Mission.wanted_city(["--city=capital"], true) == &"capital"; Mission.wanted_city(["--city=capital"], false) == &""
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN** (suite 3).
- [ ] **Step 5: Unmoved:** `refs_check.sh --jobs=2 --only='^(digest|crowd_check|calm|capital_|warning_|starfall_|tax_|ringers_toll)'` → OK (the Descent condition and `def_for` reach the `--board` rows).
- [ ] **Step 6: A Capital smoke run** (not a gate): `$G --headless --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=calm --seconds=10 --city=capital` prints a `city=capital` line, no SCRIPT ERROR.
- [ ] **Step 7: Commit** `feat: a mission in a chosen town -- per-town overrides, <mission>@<city> ids and --city; no Descent off Aldermere (v0.12 M1)`.

**Numbers:** none. **References:** none may move. **Gate:** none. **Model:** sonnet; **review:** sonnet (the mechanism M2 rests on; Review Focus 2, 3, 5).

---

### Task 5: Tooling

**Goal:** spec §1.8.

**Files:** `tools/dev/gate.sh`, `tools/dev/land.sh` (usage comments updated).

**Interfaces:**
- `gate.sh ... --city=<id>`: appends `--city=<id>` to every run; the verdict line reads `gate <scenario> city=<id> route=...`. `--with-none`: with `--route=b`, CASES `none play`; `none_lost` judged 3/3 (FAIL otherwise).
- `land.sh --bench-only`: skips the trial merge, suite, references and FLOW; imports, waits for a quiet machine (`busy()`), runs the bench pairs; the summary says `bench only`.

- [ ] **Step 1:** `bash tools/dev/gate.sh warning --route=b --board --with-none --jobs=3` prints six run lines and a verdict with `none_lost=3/3` (Aldermere's board Warning: doing nothing loses). After group A merges, the controller reruns it with `--city=aldermere` (the flag is then a no-op).
- [ ] **Step 2:** `bash tools/dev/land.sh --bench-only --bench=kak-v0.11.2 --pairs="warning:warning"` prints one bench pair and nothing else.
- [ ] **Step 3: Commit** `dev: gate.sh --city and --with-none; land.sh --bench-only (v0.12 M1)`.

**Model:** sonnet; **review:** none. **References:** none.

---

### Task 6: Tier 1 directors take town vars; the policies read them

**Goal:** spec §1.5 "Town vars" for the five Tier 1 directors; the scripted policies read the director's values, not its consts. Aldermere exact.

**Files:**
- Modify: `starfall_director.gd`, `tax_collector_director.gd`, `harvest_director.gd`, `lost_lamb_director.gd`, `first_prayers_director.gd` (every read of a listed const uses its town var; `tour()`, labels and timelines read the vars).
- Modify: `tools/dev/behaviour_check.gd` (Tier 1 functions only: `LAMB_WAIT` inward; `FirstPrayersDirector.MARKET_AT/MARKET_SECONDS/PRIESTS_AT/PRIESTS_SECONDS/FETCH_R/FETCH_STARE` -> `d.<var>`; `HarvestDirector.STORE_NAMES` -> `d.store_names`), `tools/dev/routes/tier1_b.gd` (the same reads).
- Test: `tests/test_town_vars.gd` (new; SUITES).

**Interfaces (produces) -- town vars.** Two kinds (R31): a var the director's **base already has** is seeded from the const in a new `func _init() -> void` (so it is set at `.new()`, before any override), and `_plan()`/`_begin()` stop assigning it; a var the base lacks is declared `var <name>: <type> = <CONST>`. Either way an override set by `make_director()` survives setup.

| Director | Seeded in `_init()` (base's vars) | Declared town vars |
|---|---|---|
| `StarfallDirector` | -- | `star_falls: Array = STARS` (time, post, banner name), `stop_wait: float = STOP_WAIT` |
| `TaxCollectorDirector` | `visit_seconds`, `hide_seconds`, `alarm_reach`, `guard_r`, `chain_wait`, `flush_gap` (AssassinateDirector's) | `counting_tag: StringName = COUNTING_TAG`, `counting_spot := Vector2.INF` (INF: `Places.rect(&"workshop").get_center()` at `_plan()`), `rounds: Array = ROUNDS`, `set_out_at: Array = SET_OUT_AT`, `guards: Array = GUARDS` |
| `HarvestDirector` | -- | `store_spots: Array = STORE_SPOTS`, `store_names: Array = STORE_NAMES`, `grain_at: Array = GRAIN_AT`, `chain_after: float = CHAIN_AFTER`, `load_count: int = LOADS` |
| `LostLambDirector` | `charge_start` (START), `gate_at` (GATE_MOUTH), `exit_at` (EXIT), `return_to` (TEMPLE_DOOR), `guardhouse`, `watch_posts` (POSTS), `patrol_size`, `hunt_at`, `hunt_size` (HUNTERS), `charge_pace` (EscortDirector's) | `beat_spots: Array = BEATS` (`_plan()` builds `beats` from it with `_walkable()`) |
| `FirstPrayersDirector` | `read_seconds` (PRAY_SECONDS; MirasHouseDirector's) | `shrine_at: Vector2 = SHRINE_AT`, `poor_spot: Vector2 = POOR_SPOT`, `market_at`, `market_seconds`, `priests_at`, `priests_seconds`, `faithful_lay: int = FAITHFUL_LAY`, `fetch_r: float = FETCH_R` |

Spec §2's knob names map to these (`pray_seconds` -> `read_seconds`, Lamb's `start` -> `charge_start`, `gate_mouth` -> `gate_at`, `exit` -> `exit_at`, `posts` -> `watch_posts`, `temple_door` -> `return_to`, `beats` -> `beat_spots`). Not town vars (D17, copy; or shared reflexes): `SPOIL_SECONDS`, `SMOTHER_AFTER`, `WATCHMEN`, `WATCH_OFFS`, `NEED`, `WarningDirector.OMEN_AT/STARE`, `EscortDirector.WATCH_*`.
- Policy (`behaviour_check.gd` `_lamb`): `wait_at := d._walkable(d.gate_at + (d.gate_at - d.exit_at).normalized() * LAMB_WAIT_DIST)`, `const LAMB_WAIT_DIST := 4.0` (Aldermere: `(0, -4)` exactly); `LAMB_WAIT` removed.

- [ ] **Step 1: Failing tests** `tests/test_town_vars.gd`:

```gdscript
# _seeded: a fresh director of each of the five has every town var equal to its const (counting_spot INF before _plan)
var h := HarvestDirector.new()
t.check(h.store_spots == HarvestDirector.STORE_SPOTS and h.grain_at == HarvestDirector.GRAIN_AT and h.load_count == HarvestDirector.LOADS, "harvest seeded")
var l := LostLambDirector.new()
t.check(l.charge_start == LostLambDirector.START and l.gate_at == LostLambDirector.GATE_MOUTH and l.hunt_at == LostLambDirector.HUNT_AT, "lamb seeded in _init")
# ... every row of the table, the same way
# _read_not_const: source scan of each of the five scripts -- outside const/var/_init lines no listed CONST is read
#   (e.g. no "GRAIN_AT[" in harvest_director.gd's code)
# _policies_read_vars: source scan of behaviour_check.gd's Tier 1 functions and routes/tier1_b.gd: no "FirstPrayersDirector.MARKET_AT",
#   "HarvestDirector.STORE_NAMES", "LAMB_WAIT" (the vector)
# _lamb_wait_exact: (Vector2(2.7, 14.4) - Vector2(2.7, 17.6)).normalized() * 4.0 == Vector2(0.0, -4.0)
# _override_survives_setup: a Kit world (as tests/test_tier1_board.gd builds one); a HarvestDirector with grain_at = [30.0, 90.0, 150.0]
#   set before setup() has its first grain event at 30; a LostLambDirector with hunt_at = 120.0 set before setup() keeps 120 after
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN** (suite 3).
- [ ] **Step 5: Unmoved -- every Tier 1 row:** `refs_check.sh --jobs=2 --only='^(tax|harvest|lamb|prayers|warning|starfall)_'` → OK (A, B and toll rows: 51).
- [ ] **Step 6: Commit** `refactor: Tier 1 directors read their places and numbers from town vars; the policies read the director (v0.12 M1)`.

**Numbers:** none change. **References:** none may move. **Gate:** none. **Model:** sonnet; **review:** none (mechanical; the 51 rows prove it).

---

### Task 7: The DEV tab lists town missions; FLOW's town step

**Goal:** spec §1.7.

**Files:** `src/game/ui/mission_board.gd` (`_missions_of(DEV_TIER)`, `_defs` for composite ids via `Mission.def_for(id, true, save.descend)`, `_draw_card()` for a DEV card), `src/game/game.gd` (FLOW step `_flow_dev_town()`), `tests/test_tier_board.gd` (`_dev` extended).

**Interfaces:**
- `MissionBoard._missions_of(DEV_TIER)`: `MissionBook.dev_missions()` ids, then for each `City.IDS` but `&"aldermere"`, `MissionBook.town_missions(city)`.
- A DEV card for a composite id: the mission's name; the town's id upper-cased (`CAPITAL`) in gold; the type line `TierBook.type_of(base)`; no brief (D21). The sandbox's card stays as merged ("Dev sandbox").
- `Game._flow_dev_town(step)`: `dev = true`; board -> `open_tab(DEV_TIER)` -> `choose("capital_sandbox")` -> Prepare -> the mission (`City.current().id() == &"capital"`) -> pause -> Missions -> `choose("tax_collector")` on Tier 1 -> the mission (`City.current().id() == &"aldermere"` and `City.current().structures() == AldermereCity.new().structures()`); `dev` restored.

- [ ] **Step 1: Failing tests** (`tests/test_tier_board.gd::_dev`, extended):

```gdscript
# M1's real cities, board.dev = true: the DEV tab lists exactly ["capital_sandbox"]
# with Task 4's fixture city appended to City.IDS (restored after): ["capital_sandbox", "tax_collector@<fixture id>"]
# _dev_card_fits: for six cards, every text line of a composite card fits card_rect(i, 6).size.x - 2 * PAD (UiTheme.width)
# _dev_night_banks_nothing: Game._on_mission_finished with mission_id "tax_collector@capital" and a won result -> save.descend's
#   night, believers and cleared unchanged; the save's entry for "tax_collector@capital" won
# _reopen: setup(save, "tax_collector@<fixture>") opens on DEV_TIER
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN** (suite 3).
- [ ] **Step 5: FLOW** -- the controller runs it alone after group B: `failures=0`, checks 127 + this step's.
- [ ] **Step 6: Commit** `feat: the DEV tab lists each town's hostable missions; FLOW walks a Capital night and back (v0.12 M1)`.

**Model:** sonnet; **review:** none (board work; the milestone review covers it). **References:** none.

---

### Task 8: M1 landing

**Goal:** land M1 on feat/Develop-Main as the brief asks.

- [ ] `bash tools/dev/refs_check.sh` → `bad=0` (235 rows: Aldermere's 233 + `capital_calm`, `capital_evac`).
- [ ] FLOW alone → `failures=0` (checks recorded).
- [ ] `bash tools/dev/land.sh --bench=kak-v0.11.2` → trial merge clean, suite 0, references 0, FLOW 0, Aldermere's five boards within ~1 fps (rerun noisy pairs on a quiet machine; a drop traced to the capital's border band is reported, D29).
- [ ] `bash tools/dev/land.sh --bench-only --bench=f7d74922 --pairs="capital_sandbox:capital_sandbox"` → recorded.
- [ ] Report: the table for the summary (rows, FLOW, both benches), every `Ruling:` of Tasks 1-7, and the Dev Ledger lines for the controller (one per task: what landed).
- [ ] Commit only if a table or row changed: `refs: v0.12 M1 landing`. The controller runs the opus milestone review (one fix wave, sonnet re-review), then memory `check-before-every-merge`, ff feat/Develop-Main, tag `kak-v012-m1`, push, Dev Ledger.

**Model:** sonnet; **review:** none here.

---

### Tasks 9-13: Tier 1 in the Capital (one per mission; parallel worktrees C1-C5 off `kak-v012-m1`)

Each M2 task has the same shape:

- [ ] **Overrides file** `src/game/town/cities/capital_missions/<mission_id>.gd`: `static func overrides() -> Dictionary` with `"def"` (`camera_at`, `intro_from`) and `"director"` (Task 6's town vars). Spots are literals here (the director snaps them with `_walkable()` at setup, as in Aldermere). Never edit `capital_city.gd` or any base-class director.
- [ ] **Failing test first** `tests/test_capital_<scenario>.gd` (SUITES):
  - `_overrides_valid`: `Overrides.apply()` on a fresh def and director returns `[]`; every value's type matches the seeded var's.
  - `_hostable`: `MissionBook.hostable("<id>", City.by_id(&"capital"))`; `MissionBook.town_missions(&"capital").has("<id>@capital")`.
  - `_walk_parity` (D26): on a built Capital and a built Aldermere (as `tests/test_capital_evac.gd` builds a town and its `WalkGrid`), each key walk the task names -- `WalkGrid.path()` length -- printed for both towns and within the band (0.75-1.35x; Starfall 0.75-1.6x; Prayers' report run printed only).
  - `_spots_land`: every overridden spot snaps (`nearest_walkable`) within 0.6 of itself; house spots resolve to distinct dwellings `RuinWish.fits(s, "house")` accepts; posts, beats and guards of the mission's own people are more than 1.6 apart (spread).
  - `_camera_clear`: at the intro's final camera (`camera()`, zoom 1, the game's viewport) the first target's tag point lies outside `Rect2(Kit.STACK.position, Kit.STACK.size + Vector2(Hud.STACK_PAD, Hud.STACK_PAD))` (pattern: `tests/test_exodus.gd`).
  - `_tour_true`: the set-up director's `tour()` lines name the overridden values (e.g. `UiTheme.clock(set_out_at[0])`).
- [ ] **Policy:** only if the gate misses for the town's shape: edit the scenario's own functions in `behaviour_check.gd` / its `act_`/`state_` pair in `tools/dev/routes/tier1_b.gd`; Aldermere's rows of that scenario must stay OK (rerun them).
- [ ] **Gates** (the task's lines), seeds 1-3, `--jobs=2`. Tune in the task's order, one knob at a time, gate re-run after each, at most three rounds.
- [ ] **References:** `tools/dev/refs/capital_<scenario>.tsv` (header comment: what it is, `--city=capital`), every gate run's checksum. Then `refs_check.sh --jobs=2 --only='^(capital_<scenario>|<scenario>)_'` → OK (the new rows and Aldermere's own of this mission).
- [ ] **Commit** `feat: <Mission> in the Capital -- its spots, gates and references (v0.12 M2)`; body: the gate lines (A, B, none, toll), parity numbers, knobs moved, `Ruling:` lines.

Shared knobs: none (each task changes only its own overrides file). A task that needs a base-class change (`AssassinateDirector`, `EscortDirector`, `MirasHouseDirector`, `WarningDirector`, `MissionDirector`, `RazeDirector`) or a new Capital place name reports NEEDS_CONTEXT: those are other missions' too.

#### Task 9: Starfall (`warning`) -- spec §2.1

- Overrides: `star_falls` = `[[10.0, <harbour gate inside ≈ (16.4, -9.0)>, "THE HARBOUR GATE"], [90.0, <west river gate inside ≈ (-14.0, 2.4)>, "THE RIVER GATE"], [180.0, <west gate inside ≈ (-22.4, -13.0)>, "THE WEST GATE"]]`; `camera_at` = the first post `.lerp(<bell tower centre>, 0.35)`, `intro_from` = `camera_at + (0, 6)`.
- Parity walks: each post -> the bellkeeper's foot (`crowd.bell`'s foot point; Aldermere 18.3 / 13.7 / 11.0 straight-line, measure paths), band 0.75-1.6x; the Herald's bell tower -> cathedral door (Aldermere ~8.5).
- Knobs in order: posts; fall times 10/90/180 (±30; every wait ≤60 s); `stop_wait` 30 (20-40).
- Gates: `gate.sh warning --route=b --board --city=capital --with-none`; toll `gate.sh warning --route=b --board --city=capital --case=toll` (binding ≥2/3).
- TSV `capital_starfall.tsv`: `capital_starfall_none_1..3` (`--scenario=warning --case=none --route=b --board --seed=N --city=capital`), `capital_starfall_b_play_1..3`, `capital_starfall_toll_1..3`.
- Aldermere rows to keep: `warning_*`, `warning_b_play_*`, `starfall_toll_*`.

#### Task 10: The Tax Collector -- spec §2.2

- Overrides: `counting_tag` `&"gpt_weighhouse"`, `counting_spot` ≈ `(-6.2, -7.7)`; `rounds` ≈ `[[(8, 0), (-18, 1), (-20, -12)], [(10, -14), (-14, -15)], [(14, -3), (2, 1), (-16, -5)]]`; `camera_at` ≈ the counting-house's door + `(-2, 3)` (Aldermere's offset), `intro_from` + `(0, 6)`.
- Parity walks: the counting-house door -> each round's first debtor; each round's last debtor -> the Citadel's gate `(0, -22.6)`; the door -> the Citadel's gate (Aldermere ~23 straight-line).
- Knobs: spots; `set_out_at` 35/95/155; `chain_wait` 45 (30-50); `visit_seconds` 20 (15-25); `flush_gap` 1.5 (≤3.0). Never `guards` or `alarm_reach` down.
- Gates: `gate.sh tax --city=capital`; `gate.sh tax --route=b --city=capital`; toll `gate.sh tax --city=capital --case=toll` (binding).
- TSV `capital_tax.tsv`: `capital_tax_none_*`, `capital_tax_play_*`, `capital_tax_b_play_*`, `capital_tax_toll_*`.
- Aldermere rows to keep: `tax_*`, `tax_b_play_*`, `tax_toll_*`.

#### Task 11: Spoiled Harvest -- spec §2.3

- Overrides: `store_spots` ≈ `[(15, -14), (14, 0), (-16, -4)]`, `store_names` `["north-east", "south-east", "west"]`; `camera_at` ≈ the first granary's door (checked clear of the HUD), `intro_from` + `(0, 6)`.
- Parity walks: the Citadel's gate -> each granary's door (the carter's trip; Aldermere 19.7 / 29.8 / 22.9 straight-line, measure paths).
- Knobs: spots; `grain_at` 60/120/180; `chain_after` 45 (30-45); `load_count` 5 (4-6). Never `SPOIL_SECONDS`, `SMOTHER_AFTER`, `WATCHMEN` (copy, D17).
- Gates: `gate.sh harvest --city=capital`; `gate.sh harvest --route=b --city=capital`. No toll case (no Lantern).
- TSV `capital_harvest.tsv`: `capital_harvest_none_*`, `_play_*`, `_b_play_*`. Aldermere rows to keep: `harvest_*`, `harvest_b_play_*`.

#### Task 12: The Lost Lamb -- spec §2.4

- Overrides (Task 6's names): `charge_start` ≈ `(6.1, -16.0)`; `gate_at` ≈ `(-22.4, -13.0)`; `exit_at` ≈ `(-25.6, -13.0)`; `watch_posts` ≈ `[(-22.2, -13.9), (-22.2, -12.1)]`; `guardhouse` ≈ `(-22.6, -7.0)`; `return_to` ≈ `(-3.9, -14.0)` (the cathedral's door); `beat_spots` ≈ `[[(-14, -19), (-14, -7)], [(-8, -11), (4, -11)]]`; `camera_at` `charge_start.lerp(gate_at, 0.3)`, `intro_from` + `(0, 6)`.
- Parity walks: start -> gate mouth (Aldermere ~26-28); gate mouth -> guardhouse (~6); each beat's length. Every beat point ≥6 from `return_to`.
- Knobs: spots; `charge_pace` 0.385 (0.33-0.45); `hunt_at` 150 (120-180).
- Gates: `gate.sh lamb --city=capital`; `gate.sh lamb --route=b --city=capital`. No toll case.
- TSV `capital_lamb.tsv`. Aldermere rows to keep: `lamb_*`, `lamb_b_play_*`.

#### Task 13: First Prayers -- spec §2.5

- Overrides: `shrine_at` ≈ `(-11.2, -2.5)` (free ground at the Great Market's west edge); `poor_spot` ≈ `(-21, -5)`; `camera_at` `shrine_at`, `intro_from` + `(0, 6)`.
- Parity walks: the poor's (poor spot -> shrine, Aldermere ~11.3, asserted); the Faithful's report run (shrine -> Temple door, Aldermere ~9.4, printed only, D28); the Bearer's (cathedral door -> bell tower foot).
- Knobs: spots; `read_seconds` 32 (25-40); `market_at` 75 / `priests_at` 150; `faithful_lay` 3 (2-4). Never `NEED`.
- Gates: `gate.sh prayers --city=capital`; `gate.sh prayers --route=b --city=capital`; toll `gate.sh prayers --city=capital --case=toll` (C12: reported if under 2/3; the toll never loses outright).
- TSV `capital_prayers.tsv`. Aldermere rows to keep: `prayers_*`, `prayers_b_play_*`, `prayers_toll_*`.

**Model (9-13):** sonnet; **review:** sonnet (spots, policy edits, the gate table). **References:** each task's own new TSV; no Aldermere row moves.

---

### Task 14: M2 landing

**Goal:** all five together, as landing sees them.

- [ ] FLOW step (spec §2.7) in `_flow_dev_town()`: the DEV tab lists `capital_sandbox` and the five `@capital` ids in tier order; picking `tax_collector@capital` starts it in the Capital with the director's `counting_tag == &"gpt_weighhouse"`; Esc -> Missions returns to the DEV tab. Test first in `tests/test_tier_board.gd::_dev` (the five ids listed, real cities, no fixture).
- [ ] Every Capital gate and toll gate again on the merged tree (spec §2.1-§2.5) → PASS (Prayers' toll per C12); the table for the summary.
- [ ] `bash tools/dev/refs_check.sh` → `bad=0` (235 + 51 new rows).
- [ ] `bash tools/dev/land.sh --bench=kak-v012-m1` → clean, suite 0, references 0, FLOW 0, Aldermere's five boards within ~1 fps.
- [ ] The Capital's Starfall bench, recorded (HEAD only; the base has no Capital spots for it): three runs of `$G --path . --audio-driver Dummy --disable-vsync --scene res://scenes/mission.tscn -- --mission=warning@capital --bench --board`, the median.
- [ ] Commit `feat: the DEV tab's Capital Tier 1 in FLOW; v0.12 M2 sweep`.

**Model:** sonnet; **review:** none here (the controller's opus milestone review, one fix wave, then ff and tag `kak-v012-m2`).

---

### Task 15: Notes

**Files:**
- Create: `docs/KAK_Version_0.12_Summary.md` (the user's question and the answer; M1: the merge, the place API, needs, overrides, `--city` and the DEV tab; M2: the five Capital nights with their spots, gate tables beside Aldermere's v0.11.2 numbers, toll results, knobs moved; references added; benches; open notes: thin rows, DONE_WITH_CONCERNS, the border-band bench (D29), wishes off Aldermere, Tiers 2-5 and the Citadel missions next).
- Create: `docs/KAK_v012_Rulings.md` (every R-line of `.superpowers/sdd/v012/rulings.md` and every task's `Ruling:`).
- Modify: `docs/KAK_Capital_City_Summary.md` (its "Not merged" line: merged in v0.12 M1, `kak-v012-m1`; the Capital's references as recorded).
- Modify: `README.md` (versions paragraph; a DEV line: "`--dev`: the board's DEV tab (D) holds the Capital Sandbox and the missions each town hosts (`<mission>@<city>`); `--city=<id>` plays a scripted or standalone run in that town").
- [ ] Commit `docs: v0.12 summary, rulings, README DEV notes; the capital summary marked merged`.
- [ ] Report the Dev Ledger lines for the controller (memory `kak-dev-ledger`): one release row (v0.12, tags `kak-v012-m1`, `kak-v012-m2`), one task line per task 1-14, the ideas it leaves (Tier 2 in the Capital; the player-facing town pick; wishes in other towns; Citadel missions in the Capital).

**Model:** sonnet; **review:** none.
