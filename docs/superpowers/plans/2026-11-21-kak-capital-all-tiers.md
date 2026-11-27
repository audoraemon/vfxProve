# The Capital at Every Tier Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> This project's `kak-milestone` skill applies: the plan gives files, interfaces, tests and numbers, not full code; the
> implementer writes the code test-first.

**Goal:** The Capital hosts all twenty missions of Tiers 2 to 5, so a god night in the Capital works at any tier. Each tier is
usable when its five missions are hostable there and pass their gates. Tier 2 first.

**Architecture:** As Tier 1 in v0.12. Each director gets `const TOWN_VARS` and town vars seeded from its Aldermere consts; each
mission gets an overrides file `src/game/town/cities/capital_missions/<id>.gd` (`"def"`, `"director"`; the Long Night also
`"acts"`). A few directors read Aldermere data the overrides cannot reach (a list index, a sibling class's const, the map centre):
those reads change to town vars or town lookups that are bit-equal in Aldermere. `CapitalCity.gate_towers()` names the two existing
towers of the old town's west river gate. The scripted policies read the director's vars.

**Tech Stack:** Godot 4.7.2, GDScript, the project's test runner (`tests/run_part.gd`), `tools/dev/behaviour_check.gd`,
`tools/dev/gate.sh`, `tools/dev/refs_check.sh`.

**Spec:** `docs/superpowers/specs/2026-11-21-kak-capital-all-tiers-design.md` (binding; read it first, sections 2 to 6). It builds on
`docs/superpowers/specs/2026-10-23-kak-v012-many-towns.md` (sections 1.5, 2.0) and
`docs/superpowers/plans/2026-10-23-kak-v012-many-towns.md` (Task 6, Tasks 9-13: the pattern every task here follows).

## Global Constraints

- Worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-chamber`, branch `feat/god-chamber`. Never touch another worktree. Nothing on this
  branch lands until every Chamber step is done: this plan has no landing task.
- Godot: `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`. Always wrap runs in `timeout` (a parse error hangs).
- New `class_name` or new script: `timeout 600 $G --headless --path . --import` before any headless run.
- One suite: `timeout 900 $G --headless --path . --audio-driver Dummy --script res://tests/run_part.gd -- --part=1 --of=1 --only=<name>`;
  prints `part=1/1 suites=1 checks=N failures=F`. Read the output for `SCRIPT ERROR` too. New suites go in `SUITES` of
  `tests/run_all.gd`.
- Gates: `bash tools/dev/gate.sh <scenario> --city=capital [--route=b] [--board] [--with-none] [--case=toll] --jobs=2`.
  Seeds 1-3. Pass: play wins at least 2 of 3; none loses 3 of 3; idle at most 45 s; route a median 180-240 s; route b median
  150-270 s; toll wins at least 2 of 3 (binding on a Herald night, reported on a Gaze stealth night, v0.11.2 C12).
- **Aldermere exact.** `bash tools/dev/refs_check.sh --jobs=2 --only='^(capital_<scenario>|<scenario>)_'` OK at each mission
  task (its Aldermere rows unmoved, its new Capital rows recorded); the full `refs_check.sh` at each tier close prints `bad=0`.
  A moved Aldermere row is a bug, never a re-record. `state_digest` unchanged.
- The machine is shared. Run FLOW alone (no other Godot), only in the tier close tasks:
  `timeout 1500 $G --headless --path . --scene res://scenes/game.tscn -- --flow-test`; the known headless music FAILs only.
- The whole suite (`bash tools/dev/run_suite_parallel.sh 8`) is run by the controller at each tier close, not per task.
- Town vars: `var <name>: <type> = <CONST>`; a base-class var that setup assigns is seeded in `_init()` and setup stops assigning
  it (v0.12 R31; patterns `lost_lamb_director.gd`, `tax_collector_director.gd`). A number in copy is never a town var (v0.12 D17).
- Overrides files: floats with a decimal point, tags as `&"..."`, literals only (Overrides is strict). Never edit another
  mission's overrides file.
- No PixelLab, no new art, no new sounds. Never move a Capital building.
- Scripted windowed runs use `user://test_*` files only, never `kak_save.cfg`.
- Stage files by name; never `git commit -a`. Never stage `*.uid` files under `src/core`, `tools/dev/real_path_probe.gd.uid` or
  anything under `captures/`. New `.uid` files of this plan's own new scripts and tests ARE staged with them.
- Every commit ends with the line `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`.
- Never kill a Godot process you did not start.

## Review Focus

1. **Aldermere bit-exact.** Every town var equals its const on a fresh director; every replaced read (citadel gate, Temple centre,
   town centre) is bit-equal in Aldermere; the mission's Aldermere reference rows are unmoved. Test: Task 1 `_lookups_exact`, each
   task's `refs_check.sh --only`.
2. **Overrides survive setup.** A town var a base class assigns in `_plan()`/`setup()` must be seeded in `_init()` instead, or
   the Capital's value is silently replaced. Test: each task's `_starts` reads every overridden value after `setup()`.
3. **The design rules in the bigger town.** Parity band, spread (more than 1.6), idle at most 45 s, no wait over 60 s. A gate miss
   is met by the spot first, the policy second, the numbers third, at most three rounds, then DONE_WITH_CONCERNS with numbers.
4. **Policies read the director.** No policy keeps an Aldermere const or `TownLayout` coordinate for a mission played in the
   Capital. Test: each task's source scan of its own policy functions.
5. **Last Judgement and Act III.** Measure before tuning; stop and ask if the whole Capital cannot be broken in time (spec 6.4.1).

## Task order and parallelism

- Task 1 first (groundwork).
- Tier 2: Tasks 2-6 in parallel (each its own director, overrides file, test, TSV and policy functions; `tests/run_all.gd` gets
  one line each: merge by hand), then Task 7 (close).
- Tier 3: Tasks 8-12, then Task 13. Task 8 (Vigil Flame) uses Task 3's Capital shrine spots as its route (literal copy, no
  import).
- Tier 4: Tasks 14-18, then Task 19. Task 18 (Relic Run) after Task 8 (VigilFlameDirector town vars).
- Tier 5: Tasks 20-23 in parallel, then Task 24 (Long Night: needs Tasks 9, 14, 20), then Task 25.

## The shape every mission task shares

Every mission task (2-6, 8-12, 14-18, 20-24) has these steps. The task text gives only what differs.

- [ ] **Step 1: Failing tests** `tests/test_capital_<scenario>.gd` (SUITES), on `tests/capital_kit.gd` (Task 1):
  `_overrides_valid`, `_hostable`, `_starts`, `_walk_parity` (the task's walks), `_spots_land`, `_camera_clear`, `_words_true`
  (spec section 8), plus `_seeded` (a fresh director: every new town var equals its const) and `_policy_reads_vars` (source scan of
  the task's policy functions: no listed const or `TownLayout.` coordinate).
- [ ] **Step 2: RED.** `timeout 900 $G --headless --path . --audio-driver Dummy --script res://tests/run_part.gd -- --part=1 --of=1 --only=test_capital_<scenario>`
  fails on the missing file and vars.
- [ ] **Step 3: Implement.** Town vars and `TOWN_VARS` in the director (and its base where the task says); the code change the
  task names; the overrides file; the policy reads.
- [ ] **Step 4: GREEN.** The same command: `failures=0`, no `SCRIPT ERROR`. Also `--only=test_<mission>` (the mission's own
  Aldermere suite, where one exists) and `--only=test_mission_needs`.
- [ ] **Step 5: Aldermere unmoved.** `bash tools/dev/refs_check.sh --jobs=2 --only='^<scenario>_'` OK (A, B, none and toll rows).
- [ ] **Step 6: Gates in the Capital.** The task's gate lines. Tune in the task's knob order, one knob at a time, gate re-run after
  each, at most three rounds.
- [ ] **Step 7: References.** `tools/dev/refs/capital_<scenario>.tsv` (header comment as `capital_lamb.tsv`: what it is,
  `--city=capital`; rows `capital_<scenario>_none_1..3`, `_play_1..3`, `_b_play_1..3`, `_toll_1..3` where the mission has a toll
  case), each gate run's checksum. Then `refs_check.sh --jobs=2 --only='^(capital_<scenario>|<scenario>)_'` OK.
- [ ] **Step 8: Commit.** Stage by name: the director(s), the overrides file and its `.uid`, the test and its `.uid`,
  `tests/run_all.gd`, the TSV, the policy file(s). Message `feat: <Mission> in the Capital: its spots, gates and references`; body:
  the gate lines (A, B, none, toll), the parity numbers, the knobs moved; last line
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`.

---

### Task 1: Groundwork: the gate towers, the Capital test kit, the shared lookups

**Goal:** spec sections 3 and 5 (items 1, 2's test, 4's test, 10's test). Nothing in Aldermere moves.

**Files:**
- Modify: `src/game/town/cities/capital_city.gd` (`gate_towers()`).
- Create: `tests/capital_kit.gd` (static helpers, no `run()`), factored from `tests/test_capital_lamb.gd` (`_town`, `_free`,
  `_walk`, `_snap`) and its checks.
- Create: `tests/test_capital_gate_towers.gd`, `tests/test_town_vars_t2_5.gd` (SUITES; this task fills `_lookups_exact` only; each
  mission task adds its `_seeded` row to its own test, not here).
- Modify: `tests/test_mission_needs.gd` (`_unknown_and_counts`: the Capital hosts the needs of `armoury` and `crowns_bread`).
- Modify: `tests/run_all.gd` (two suites).

**Interfaces (produces):**
- `CapitalCity.gate_towers() -> Array[Rect2]`: `_gatehouses(INNER, [INNER_GATES[1]]).towers`, west tower first. Cached as the
  other layout lists are.
- `CapitalKit` (`tests/capital_kit.gd`, `class_name` not needed; preload it):
  - `town(city: StringName) -> Dictionary` `{env, town, grid}` and `free(b)`;
  - `walk(grid, from, to) -> float` (both snapped as the director snaps: `nearest_walkable`);
  - `parity(t, label, cap_walk, ald_walk, lo := 0.75, hi := 1.35)` (prints both, checks the band);
  - `overrides_valid(t, id)`, `hostable(t, id)`, `spots_land(t, b, spots, max_snap := 0.6)`, `spread(t, points, min := 1.6)`,
    `camera_clear(t, def, tag_at)` (pattern `tests/test_exodus.gd`), `starts(t, id) -> MissionDirector` (a Kit world in the
    Capital, the def from `GodNight.def_for()`, the director set up; the caller reads its vars).

- [ ] **Step 1: Failing tests.**
  - `test_capital_gate_towers.gd::_two_towers`: `City.by_id(&"capital").gate_towers().size() == 2`; each rect is the footprint of a
    built structure with role `&"tower"` and `Structure.Kind.KEEP` in a built Capital; [0].x < [1].x; both within 3 of `(-14, 4)`.
  - `_needs`: `Places.can_host("crowns_bread", capital)` and `Places.can_host("armoury", capital)` true; `hostable()` still false
    for both (no overrides file yet).
  - `_capital_refs_untouched`: nothing to assert in code; Step 5 runs the references.
  - `test_town_vars_t2_5.gd::_lookups_exact` (Aldermere active): `Places.point(&"citadel_gate") == HarvestDirector.CITADEL_GATE`;
    `Places.at(&"temple") == LanternEyeDirector.SPIRE`; `City.current().town().get_center() == City.current().map().get_center()`.
  - `test_mission_needs.gd`: the two lines asserting the Capital cannot host `armoury`/`crowns_bread` become "the Capital has the
    places of `armoury`/`crowns_bread`".
- [ ] **Step 2: RED.** `--only=test_capital_gate_towers`, `--only=test_mission_needs`.
- [ ] **Step 3: Implement** `gate_towers()` and the kit (move the helpers out of `test_capital_lamb.gd` only if that test keeps
  passing unchanged; else copy them).
- [ ] **Step 4: GREEN.** `--only=test_capital_gate_towers`, `--only=test_town_vars_t2_5`, `--only=test_mission_needs`,
  `--only=test_capital_lamb`.
- [ ] **Step 5: Unmoved.** `bash tools/dev/refs_check.sh --jobs=2 --only='^capital_'` OK (the Capital's calm, evac and Tier 1 rows:
  gate towers are read by no running mission).
- [ ] **Step 6: Commit** `feat: the Capital names its west river gate's towers; a shared Capital test kit`.

**Numbers:** none. **References:** none move.

---

## Tier 2

### Task 2: Mira's House in the Capital (spec 6.1.1)

**Files:** `src/game/mission/miras_house_director.gd`, `src/game/town/cities/capital_missions/miras_house.gd` (new),
`tests/test_capital_miras.gd` (new), `tools/dev/refs/capital_miras.tsv` (new), `tests/run_all.gd`.

**Interfaces:** `MirasHouseDirector.TOWN_VARS := ["mira_spot"]`; `var mira_spot: Vector2 = MIRA_SPOT` (read at lines ~94, ~114).
`read_seconds` stays copy-free and not overridden. SermonDirector inherits the var and never reads it.

**Overrides:**
- def: `camera_at` `Vector2(-18.0, -15.5)`, `intro_from` `Vector2(-18.0, -9.5)`.
- director: `mira_spot` `Vector2(-18.0, -15.5)`.

**Tests beyond the shape:** `_walk_parity`: Mira's door to the Temple door (A about 14.6). `_spots_land`: the house is a dwelling
in the noble quarter (`Rect2(-24, -21, 15, 12)`). `_words_true`: no tour line says "west quarter".

**Gates:** `gate.sh miras --city=capital --with-none`; `gate.sh miras --route=b --city=capital`; toll
`gate.sh miras --city=capital --case=toll`. Knobs in order: `mira_spot` (parity), then none by this task (report).

**Aldermere rows to keep:** `miras_play`, `miras_b_play_*`, `miras_toll_*`.

---

### Task 3: Broken Lanterns in the Capital (spec 6.1.2)

**Files:** `broken_lanterns_director.gd`; `capital_missions/broken_lanterns.gd`; `tests/test_capital_lanterns.gd`;
`tools/dev/refs/capital_lanterns.tsv`; `tests/run_all.gd`.

**Interfaces:** `TOWN_VARS := ["shrine_spots"]`; `var shrine_spots: Array = SHRINE_SPOTS`. `SHRINE_SPOTS` stays a const (the Vigil
Flame reads it until Task 8).

**Overrides:**
- def: `camera_at` `Vector2(-1.0, -9.0)`, `intro_from` `Vector2(-1.0, -3.0)`.
- director: `shrine_spots` `[Vector2(1.5, -12.6), Vector2(7.0, -16.0), Vector2(14.0, -11.0), Vector2(12.0, -1.0), Vector2(-2.5, -1.0), Vector2(-14.5, -11.5)]`.

**Tests beyond the shape:** `_walk_parity`: the round's total (six legs, A about 79); each shrine to the Temple door. `_spots_land`:
no shrine footprint (`SHRINE_SIZE` about the snapped spot) overlaps an avenue or a building; the two Knights' posts of each shrine
more than 1.6 apart.

**Gates:** `gate.sh lanterns --city=capital --with-none`; `--route=b`; `--case=toll`; the bonus case reported. Knobs: spots
(parity, traffic), then `KNIGHTS_AT` 90 (60-90) only if idle exceeds 45 s.

**Aldermere rows to keep:** `lanterns_none`, `lanterns_b_play_*`, `lanterns_toll_*`.

---

### Task 4: The Bell-Ringers in the Capital (spec 6.1.3)

**Files:** `bell_ringers_director.gd`; `capital_missions/bell_ringers.gd`; `tests/test_capital_ringers.gd`;
`tools/dev/refs/capital_ringers.tsv`; `tests/run_all.gd`.

**Interfaces:** `TOWN_VARS := ["post_spots", "post_names", "set_out_at"]`; vars seeded from `POST_SPOTS`, `POST_NAMES`, `SET_OUT_AT`.
Code change: `_town_door()` reads `City.current().town().get_center()` (spec 5 item 2).

**Overrides:**
- def: `camera_at` `Vector2(-14.0, -20.0)`, `intro_from` `Vector2(-14.0, -14.0)`.
- director: `post_spots` `[Vector2(-19.0, -30.0), Vector2(-24.0, -5.0), Vector2(-24.0, -21.0)]`, `post_names`
  `["north-west", "south-west", "west"]`.

**Tests beyond the shape:** `_walk_parity`: each post's town door to the bell's foot (A about 17.0 / 20.6 / 12.4). `_spots_land`:
each post resolves to a distinct standing wall tower of `INNER` (not a gate tower, not the bell tower); its door is inside the ring
(`INNER.has_point(door)`). `_inward`: for a south-wall tower the chosen face points north.

**Gates:** `gate.sh ringers --city=capital --with-none`; `--route=b`; toll `--case=toll` (binding, Herald). Knobs: posts (a west
post moves to the north wall `(-11.0, -30.0)` if the loop patrol keeps idle over 45 s); `set_out_at` 40/110/180 (each within the
previous plus `CHAIN_WAIT` 45).

**Aldermere rows to keep:** `ringers_*`, `ringers_b_play_*`, `ringers_toll_*`.

---

### Task 5: Market Panic in the Capital (spec 6.1.4)

**Files:** `market_panic_director.gd`; `capital_missions/market_panic.gd`; `tests/test_capital_panic.gd`;
`tools/dev/refs/capital_panic.tsv`; `tools/dev/behaviour_check.gd` (`_panic_act` and its helpers only),
`tools/dev/routes/tier2_b.gd` (`act_panic`/`state_panic` only); `tests/run_all.gd`.

**Interfaces:** `TOWN_VARS := ["heart", "sources", "source_names", "wave_at"]`; `var heart: Vector2 = HEART`, `sources`,
`source_names`, `wave_at`. Every read of `HEART`/`SOURCES`/`SOURCE_NAMES`/`WAVE_AT` in code reads the var. Policies:
`MarketPanicDirector.HEART` and `.SOURCES` become `d.heart`, `d.sources` (`FAIR_R` stays a const).

**Overrides:**
- def: `camera_at` `Vector2(5.0, -14.0)`, `intro_from` `Vector2(5.0, -8.0)`.
- director: `heart` `Vector2(6.1, -16.4)`; `sources` `[Vector2(6.1, -16.4), Vector2(-3.0, -11.0), Vector2(8.0, -5.0), Vector2(0.2, -5.7)]`;
  `source_names` `["the guild quarter", "the cathedral's plaza", "the bathhouse street", "the market tavern"]`.

**Tests beyond the shape:** `_walk_parity`: each source to the heart (A 9.1 / 11.0 / 13.0). `_fair_ground`: at least `WAVE * 4`
walkable spots within `FAIR_R` of the heart on the built Capital. Wardens more than 1.6 apart.

**Gates:** `gate.sh panic --city=capital --with-none`; `--route=b`. Knobs: sources (parity); `wave_at` 0/75/150/220 (each within
the previous plus `CHAIN` 45 after a scatter).

**Aldermere rows to keep:** `panic_*`, `panic_b_play_*`.

---

### Task 6: The Informer in the Capital (spec 6.1.5)

**Files:** `informer_director.gd`; `capital_missions/informer.gd`; `tests/test_capital_informer.gd`;
`tools/dev/refs/capital_informer.tsv`; `tests/run_all.gd`.

**Interfaces:** `TOWN_VARS := ["contact_spots", "lodging_at", "temple_door_at", "visit_at", "safe_at"]`; `var contact_spots: Array =
CONTACT_SPOTS`, `var lodging_at: Vector2 = LODGING_AT`, `var temple_door_at: Vector2 = TEMPLE_DOOR` (spec 5 item 3; every read of
`TEMPLE_DOOR` in code reads it), `var visit_at: Array = VISIT_AT`; AssassinateDirector's `safe_at` seeded in `_init()` to
`TEMPLE_DOOR` and no longer assigned in `_plan()`. `TRADES` and `ORDINALS` stay consts (trades, not places).

**Overrides:**
- def: `camera_at` `Vector2(2.0, -10.0)`, `intro_from` `Vector2(2.0, -4.0)`.
- director: `contact_spots` `[Vector2(12.4, -12.5), Vector2(14.0, -3.0), Vector2(-20.0, -2.0), Vector2(6.0, 0.0)]`;
  `lodging_at` `Vector2(-11.0, -19.5)`; `temple_door_at` `Vector2(-3.9, -14.0)`; `safe_at` `Vector2(-3.9, -14.0)`.

**Tests beyond the shape:** `_walk_parity`: the carpenter's door to the Temple door (A about 19.5); the lodging to the door (A about
8.1). `_spots_land`: four distinct dwellings `RuinWish.fits(s, "house")` accepts, none the lodging.

**Gates:** `gate.sh informer --city=capital --with-none`; `--route=b`; toll `--case=toll` (Watch). Knobs: the potter's spot (to
`(-15.0, -11.0)` if idle over 45 s); `visit_at` 45/115/180/245 (each within the previous plus `CHAIN_WAIT` 45).

**Aldermere rows to keep:** `informer_*`, `informer_b_play_*`, `informer_toll_*`.

---

### Task 7: Tier 2 close

- [ ] **Step 1:** `tests/test_capital_god_night.gd`: a new check `_tier2_drawn`: `GodNight.draw(_slot(2), "capital")` is one of the
  five Tier 2 ids; `_draw_none` still finds a tier (3) the Capital hosts nothing of.
- [ ] **Step 2:** `--only=test_capital_god_night`, `--only=test_board_test_mode` (the DEV tab's Capital ids now include Tier 2's).
- [ ] **Step 3:** The controller runs `bash tools/dev/run_suite_parallel.sh 8`, then the full `bash tools/dev/refs_check.sh`
  (`bad=0`), then FLOW alone.
- [ ] **Step 4:** Every Tier 2 Capital gate once more, together, `--jobs=2` (they were tuned one by one).
- [ ] **Step 5: Commit** `test: Tier 2 is drawn for a god night in the Capital`. The Ledger's task row is updated by the controller.

---

## Tier 3

### Task 8: The Vigil Flame in the Capital (spec 6.2.1)

**Files:** `vigil_flame_director.gd`; `capital_missions/vigil_flame.gd`; `tests/test_capital_flame.gd`;
`tools/dev/refs/capital_flame.tsv`; `tests/run_all.gd`.

**Interfaces:** `TOWN_VARS := ["route_spots", "mira_shrine"]`; `var route_spots: Array = BrokenLanternsDirector.SHRINE_SPOTS`
(spec 5 item 5: line ~147 reads it), `var mira_shrine: Vector2 = MIRA_SHRINE`. RelicRunDirector inherits both.

**Overrides:**
- def: `camera_at` `Vector2(-3.0, -12.0)`, `intro_from` `Vector2(-3.0, -6.0)`.
- director: `route_spots` = Task 3's six Capital shrine spots (literal copy); `mira_shrine` `Vector2(-18.0, -14.0)`.

**Tests beyond the shape:** `_walk_parity`: the round (as Task 3); the nearest round point to `mira_shrine` (Wren's carry; A
measured; move to `(-21.0, -18.0)` if under 0.75x).

**Gates:** `gate.sh flame --city=capital --with-none`; `--route=b`; toll `--case=toll` (Light). Knobs: `mira_shrine`; then none.

**Aldermere rows to keep:** `flame_none`, `flame_play`, `flame_b_play_*`, `flame_toll_*`.

---

### Task 9: The Festival in the Capital (spec 6.2.2)

**Files:** `capital_missions/festival.gd`; `tests/test_capital_festival.gd`; `tools/dev/refs/capital_festival.tsv`;
`tools/dev/behaviour_check.gd` (`FESTIVAL_LOOK_AT` read only when `--shots`: make it `Places.at(&"market_square")`-relative per
city, Aldermere's literal kept); `tests/run_all.gd`.

**Interfaces:** none in the director (it reads `Places` only). The board builds this def through `TierBook._from_act()`;
`in_city()` applies the overrides to that root def.

**Overrides:**
- def: `camera_at` `Vector2(-7.5, -2.5)`, `intro_from` `Vector2(-7.5, 5.5)`.
- director: none (omit the section).

**Tests beyond the shape:** `_crowd_fits`: on the built Capital, `crowd._spot_near()` finds 80 walkable goer spots within
`Places.rect(&"market_square").size.x * 0.4` of the square's centre; the fountain (`Places.at(&"fountain")`) lies inside the square.

**Gates:** `gate.sh feast --city=capital --board --extra='--path=festival' --with-none`; the same with `--route=b`. Knobs: none by
this task; report.

**Aldermere rows to keep:** `feast_play`, `festival_b_play_*`.

---

### Task 10: The Crown's Bread in the Capital (spec 6.2.3)

**Files:** `crowns_bread_director.gd`; `capital_missions/crowns_bread.gd`; `tests/test_capital_bread.gd`;
`tools/dev/refs/capital_bread.tsv`; `behaviour_check.gd` (`_bread_act`: `CrownsBreadDirector.WORDS` -> `d.words`),
`routes/tier3_b.gd` (`act_bread`: the same); `tests/run_all.gd`.

**Interfaces:** `TOWN_VARS := ["granary_tag", "mill_tag", "bridge_at", "names", "words", "stage_labels", "stage_at"]`.
`var granary_tag: StringName = &""` (empty: `barns()[3]` by footprint); `var mill_tag: StringName = &""` (empty: art tag
`&"watermill"`); `var bridge_at := Vector2.INF` (INF: `town.bridge`; else the standing `Structure.Kind.BRIDGE` crossing nearest it);
`names`, `words`, `stage_labels`, `stage_at` seeded from their consts. `_find_targets()` (spec 5 item 6) matches a tag against
`s.art_tag` for a CapitalPlots set. `_gate_tower()` unchanged (Task 1 gives the Capital its towers).

**Overrides:**
- def: `camera_at` `Vector2(-13.0, -2.0)`, `intro_from` `Vector2(-13.0, 4.0)`.
- director: `granary_tag` `&"gpt_markethall"`; `mill_tag` `&"gpt_bakery"`; `bridge_at` `Vector2(-14.0, 8.0)`; `names`
  `["MARKET HALL", "BAKERY", "BRIDGE"]`; `words` `["market hall", "bakery", "bridge"]`; `stage_labels`
  `["The grain carts fill the market hall", "The bakers bake the Crown's bread", "The bread carts gather at the bridge"]`.

**Tests beyond the shape:** `_targets`: a set-up director in the Capital has three targets, the market hall, the bakery and the west
stone bridge, in that order; the bridge shift's tower is `gate_towers()[0]`. `_walk_parity` (printed, the player's travel): target
to target (A 27.5 / 8). Each target's night crew posts more than 1.6 apart.

**Gates:** `gate.sh bread --city=capital --with-none`; `--route=b`. Knobs: targets (if the user rules otherwise, spec 9 question
1); `stage_at` 45/115/185 (each within the previous plus `CHAIN` 45).

**Aldermere rows to keep:** `bread_*`, `bread_b_play_*`.

---

### Task 11: The Prisoner in the Capital (spec 6.2.4)

**Files:** `prisoner_director.gd`; `capital_missions/prisoner.gd`; `tests/test_capital_prisoner.gd`;
`tools/dev/refs/capital_prisoner.tsv`; `behaviour_check.gd` (`_prisoner_act`: `PrisonerDirector.ROAD` -> `d.road`),
`routes/tier3_b.gd` (`act_prisoner`: the same); `src/game/mission/mission_needs.gd` (row `prisoner` adds `citadel_gate`);
`tests/run_all.gd`.

**Interfaces:** `TOWN_VARS := ["stocks_at", "lane_foot", "road", "beat_spots", "gate_words", "charge_start", "gate_at", "exit_at",
"return_to", "guardhouse", "watch_posts"]`. Declared: `stocks_at`, `lane_foot`, `road: Array = ROAD`, `beat_spots: Array = BEATS`,
`gate_words: String` (the tour's postern line). EscortDirector's `gate_at` (GATE_MOUTH), `exit_at` (EXIT), `watch_posts` (POSTS),
`guardhouse` (GUARDHOUSE), `charge_start` (the stocks' spot) seeded in `_init()`; `return_to` and `citadel_door` read
`Places.point(&"citadel_gate")` (spec 5 item 4).

**Overrides:**
- def: `camera_at` `Vector2(8.0, -15.0)`, `intro_from` `Vector2(8.0, -9.0)`.
- director: `stocks_at` `Vector2(4.0, -19.0)`; `lane_foot` `Vector2(4.0, -21.0)`; `gate_at` `Vector2(16.4, -9.0)`; `exit_at`
  `Vector2(19.6, -9.0)`; `watch_posts` `[Vector2(16.4, -9.9), Vector2(16.4, -8.1)]`; `guardhouse` `Vector2(16.0, -4.0)`;
  `beat_spots` `[[Vector2(0.0, -16.5), Vector2(8.0, -16.5)], [Vector2(10.0, -13.0), Vector2(10.0, -4.0)]]`; `road`
  `[Vector2(4.0, -18.0), Vector2(4.0, -9.0), Vector2(16.4, -9.0), Vector2(19.6, -9.0)]`; `gate_words`
  `"The harbour gate, out to the quays. Its guard changes soon after she draws near."`; `charge_start` `Vector2(4.0, -18.0)`.

**Tests beyond the shape:** `_walk_parity`: her road (A about 22.4); the Citadel gate to the stocks (A about 4.25). The posts more
than 1.6 apart. Every beat point 6 or more from the Citadel gate. `_walls`: `Walls.outside(exit_at)` is true in the Capital.

**Gates:** `gate.sh prisoner --city=capital --with-none`; `--route=b`. Knobs: road (parity, traffic); `FREE_BY` stays (copy).

**Aldermere rows to keep:** `prisoner_*`, `prisoner_b_play_*`.

---

### Task 12: The Heretic Hunt in the Capital (spec 6.2.5)

**Files:** `heretic_hunt_director.gd`; `capital_missions/heretic_hunt.gd`; `tests/test_capital_hunt.gd`;
`tools/dev/refs/capital_hunt.tsv`; `tests/run_all.gd`.

**Interfaces:** `TOWN_VARS := ["sweep_spots", "sweep_words", "sweep_areas", "cellar_at", "cellar_area", "temple_door_at", "step_at"]`.
`var sweep_areas: Array = []` (empty: `districts()[SWEEP_DISTRICTS[i]]`); `var cellar_area := Rect2()` (no area:
`districts()[CELLAR_DISTRICT]`); `temple_door_at` (spec 5 item 3); the rest seeded from consts.

**Overrides:**
- def: `camera_at` `Vector2(-14.0, -8.0)`, `intro_from` `Vector2(-14.0, -2.0)`.
- director: `sweep_spots` `[Vector2(-6.0, -12.0), Vector2(-18.0, -15.0), Vector2(-20.0, -6.0)]`; `sweep_words`
  `["the cathedral quarter", "the noble quarter", "the west market"]`; `sweep_areas`
  `[Rect2(-9.0, -21.0, 17.0, 12.0), Rect2(-24.0, -21.0, 15.0, 12.0), Rect2(-24.0, -9.0, 22.0, 13.0)]`; `cellar_at`
  `Vector2(-21.0, 1.0)`; `cellar_area` `Rect2(-24.0, -9.0, 22.0, 13.0)`; `temple_door_at` `Vector2(-3.9, -14.0)`.

**Tests beyond the shape:** `_walk_parity`: the Temple door to the cellar (the captain, A about 20.5); each sweep spot to the cellar
printed. `_cellar_quiet`: the cellar's door is farther than `QUIET_R` from every soldier post of the Capital.

**Gates:** `gate.sh hunt --city=capital --with-none`; `--route=b`. Knobs: spots; `step_at` 60/115/185/240.

**Aldermere rows to keep:** `hunt_*`, `hunt_b_play_*`.

---

### Task 13: Tier 3 close

As Task 7, with `_tier3_drawn` (`GodNight.draw(_slot(3), "capital")` is one of the five), `_draw_none` finding tier 4. Commit
`test: Tier 3 is drawn for a god night in the Capital`.

---

## Tier 4

### Task 14: The Procession in the Capital (spec 6.3.1)

**Files:** `procession_director.gd`; `capital_missions/procession.gd`; `tests/test_capital_procession.gd`;
`tools/dev/refs/capital_procession.tsv`; `tests/run_all.gd`.

**Interfaces:** `TOWN_VARS := ["route_spots"]`; `var route_spots: Array = []`; `_route()` uses them when not empty (each still
snapped by `_ground()`), else today's landmark points (spec 5 item 8). `STEPS_LEG` 1 and `DOCK_LEG` 3 keep their meaning: the
Capital's list has five points as Aldermere's.

**Overrides:**
- def: `camera_at` `Vector2(9.3, -18.6)` (Citadel.lerp(dock, 0.3)), `intro_from` `Vector2(0.0, -25.5)`.
- director: `route_spots` `[Vector2(0.0, -22.4), Vector2(-3.9, -14.1), Vector2(16.4, -9.0), Vector2(31.0, -4.1), Vector2(31.0, -2.8)]`.

**Tests beyond the shape:** `_walk_parity`: the whole route (A about 37.6) and each leg. `_no_queue`: on a built Capital the route's
path crosses no bridge rect; the Prince's party at the harbour gate mouth is not a queued evacuee (the gate queue reads only
evacuees: assert by the crowd's own rule).

**Gates:** `gate.sh feast --city=capital --board --extra='--path=procession' --with-none`; the same with `--route=b`. Knobs:
route points; `emerge_after` (board tune) unchanged.

**Aldermere rows to keep:** `procession_*`, `procession_b_play_*`.

---

### Task 15: The Bishop in the Capital (spec 6.3.2)

**Files:** `bishop_director.gd`; `capital_missions/bishop.gd`; `tests/test_capital_bishop.gd`;
`tools/dev/refs/capital_bishop.tsv`; `mission_needs.gd` (row `bishop` adds `citadel_gate`); `tests/run_all.gd`.

**Interfaces:** `TOWN_VARS := ["refuge_spots", "arrive_at", "safe_at"]`; `var refuge_spots: Array = REFUGE_SPOTS`;
`CITADEL_GATE` reads become `Places.point(&"citadel_gate")` (spec 5 item 4); AssassinateDirector's `safe_at` seeded in `_init()`.
`REFUGE_WORDS` stay (his house, the chapter house, the Temple: true in the Capital).

**Overrides:**
- def: `camera_at` `Vector2(4.0, -14.0)`, `intro_from` `Vector2(4.0, -8.0)`.
- director: `refuge_spots` `[Vector2(12.4, -12.5), Vector2(6.5, -18.0)]`; `safe_at` `Vector2(0.0, -22.6)`.

**Tests beyond the shape:** `_walk_parity`: his house to the chapter house (A 6.9), the chapter house to the Temple door (A 10.1),
the Citadel gate to his house. Knights' posts more than 1.6 apart.

**Gates:** `gate.sh bishop --city=capital --with-none`; `--route=b`. Knobs: refuges; `arrive_at` 45.

**Aldermere rows to keep:** `bishop_*`, `bishop_b_play_*`.

---

### Task 16: The Armoury in the Capital (spec 6.3.3)

**Files:** `armoury_director.gd`; `capital_missions/armoury.gd`; `tests/test_capital_armoury.gd`;
`tools/dev/refs/capital_armoury.tsv`; `behaviour_check.gd` (`_armoury_act`: `ArmouryDirector.WORDS` -> `d.words`),
`routes/tier4_b.gd` (`act_armoury`: the same); `mission_needs.gd` (row `armoury` adds `citadel_gate`); `tests/run_all.gd`.

**Interfaces:** `TOWN_VARS := ["words", "horn_labels", "stage_at"]`; vars seeded from consts; `CITADEL_GATE` reads become
`Places.point(&"citadel_gate")`. `_find_targets()` unchanged (Task 1's towers; the Capital's `taverns()[0..1]`).

**Overrides:**
- def: `camera_at` `Vector2(-16.0, -6.0)`, `intro_from` `Vector2(-16.0, 0.0)`.
- director: `words` `["west barracks", "gate barracks", "armoury"]`; `horn_labels`
  `["The muster horn: the west barracks turns out", "The muster horn: the gate barracks turns out", <Aldermere's third label>]`.

**Tests beyond the shape:** `_targets`: three targets in a set-up director: the west market tavern, the west river gate's east tower,
the Keep's barracks. Distances between targets printed. Night watch posts more than 1.6 apart.

**Gates:** `gate.sh armoury --city=capital --with-none`; `--route=b`. Knobs: `stage_at` 40/110/180 (the third first: the barracks
is 32 from the gate tower; each within the previous plus `CHAIN` 40).

**Aldermere rows to keep:** `armoury_*`, `armoury_b_play_*`.

---

### Task 17: The Sermon in the Capital (spec 6.3.4)

**Files:** `sermon_director.gd`; `capital_missions/sermon.gd`; `tests/test_capital_sermon.gd`;
`tools/dev/refs/capital_sermon.tsv`; `behaviour_check.gd` (`_sermon_act`: `TownLayout.BELL_TOWER.get_center()` ->
`Places.at(&"bell_tower")`); `routes/tier4_b.gd` (any same read in `act_sermon`); `tests/run_all.gd`.

**Interfaces:** `TOWN_VARS := ["pulpit_well", "house_spot", "sources", "wave_at"]`; `var pulpit_well: int = 2` (spec 5 item 9:
`City.current().wells()[pulpit_well]`), `house_spot`, `sources`, `wave_at` seeded from consts.

**Overrides:**
- def: `camera_at` `Vector2(11.0, -1.0)`, `intro_from` `Vector2(11.0, 5.0)`.
- director: `pulpit_well` `3`; `house_spot` `Vector2(13.0, -2.5)`; `sources` `[Vector2(0.0, -5.0), Vector2(14.0, -5.5), Vector2(2.0, -1.0)]`.

**Tests beyond the shape:** `_walk_parity`: the pulpit to the god's house (A 6.1); each source to the pulpit (A 11.6 / 7.1 / 8.1);
the god's house to the Temple door (the report run). Sentries more than 1.6 apart. `_lookup_exact`: in Aldermere
`Places.at(&"bell_tower") == TownLayout.BELL_TOWER.get_center()`.

**Gates:** `gate.sh sermon --city=capital --with-none`; `--route=b`; toll `--case=toll`. Knobs: house and sources (keep east of
x = 8); `wave_at` 0/95/185/260.

**Aldermere rows to keep:** `sermon_*`, `sermon_b_play_*`, `sermon_toll_*`.

---

### Task 18: The Relic Run in the Capital (spec 6.3.5)

**Files:** `relic_run_director.gd`; `capital_missions/relic_run.gd`; `tests/test_capital_relic.gd`;
`tools/dev/refs/capital_relic.tsv`; `behaviour_check.gd` (`_relic_act`: bell tower read as Task 17); `tests/run_all.gd`.
Depends on Task 8.

**Interfaces:** `TOWN_VARS := ["route", "check_words", "drop_spot", "pip_spot", "mira_shrine"]`; `route`, `check_words`,
`drop_spot`, `pip_spot` seeded from consts; `mira_shrine` is VigilFlameDirector's (Task 8). `HALT_LEGS` stays a const (indices).
Policy reads of `HALT_LEGS`, `CART_REACH`, `WARDEN_GAP` stay consts.

**Overrides:**
- def: `camera_at` `Vector2(8.0, -6.0)`, `intro_from` `Vector2(8.0, 0.0)`.
- director: `route` `[Vector2(14.0, 1.5), Vector2(14.0, -9.0), Vector2(-2.0, -9.0), Vector2(-2.0, -13.0), Vector2(4.0, -13.0), Vector2(0.0, -22.6)]`;
  `check_words` `["the harbour watch-house", "the plaza watch-house"]`; `drop_spot` `Vector2(16.0, -14.0)`; `pip_spot`
  `Vector2(10.0, 0.0)`; `mira_shrine` `Vector2(-18.0, -14.0)`.

**Tests beyond the shape:** `_walk_parity`: the cart's route (A about 50.7); Pip's spot to the first halt. The route's last point is
the Capital's Citadel gate. Wardens `WARDEN_GAP` 2.6 apart.

**Gates:** `gate.sh relic --city=capital --with-none`; `--route=b`; toll `--case=toll`. Knobs: leg 2's end (to `(2.0, -9.0)` if idle
over 45 s); none else.

**Aldermere rows to keep:** `relic_*`, `relic_b_play_*`, `relic_toll_*`.

---

### Task 19: Tier 4 close

As Task 7, with `_tier4_drawn`, `_draw_none` finding tier 5. Commit `test: Tier 4 is drawn for a god night in the Capital`.

---

## Tier 5

### Task 20: Last Judgement in the Capital (spec 6.4.1)

**Files:** `capital_missions/last_judgement.gd`; `tests/test_capital_judgement.gd`; `tools/dev/refs/capital_judgement.tsv`;
`behaviour_check.gd` (`_judgement`, `_play_judgement`, `_richest`: `JUDGEMENT_TARGETS` becomes a per-city table
`{&"aldermere": <today's list>, &"capital": <eight Capital targets>}` read by `City.current().id()`; `TownLayout.CITADEL_ORIGIN` ->
`City.current().citadel_origin()`; the exits' report keys by `City.current().exits()`); `tests/run_all.gd`.

**Interfaces:** none in the director.

**Overrides:**
- def: `brief` `PackedStringArray(["The Capital and its Royal Keep.", "Bring the whole kingdom down."])`, `intro_from`
  `Vector2(16.4, -9.0)`. No `camera_at` (the Capital's Citadel by default).
- Capital fixed targets (policy table): `(0.0, -25.5)`, `(-8.0, -12.0)`, `(-7.5, -2.5)`, `(6.0, -4.0)`, `(-18.0, -15.0)`,
  `(10.0, -14.0)`, `(-3.9, -17.7)`, `(-20.0, -4.0)`.

- [ ] **Step 0 (before any number): measure.** `gate.sh judgement --city=capital --board --with-none` and `--route=b`. If play wins
  at least 2 of 3, continue the shape. If not, stop: report the numbers (stability left, escapes, time) and return
  DONE_WITH_CONCERNS for the user (spec 9 question 2). Do not tune `ESCAPE_LIMIT`, DP or the clock (copy, D17).

**Tests beyond the shape:** `_policy_city_table`: in Aldermere the table's list equals today's `JUDGEMENT_TARGETS` element for
element. `_lookups`: the director's tags point at `(0, -25.5)` and the Capital's three exits.

**Aldermere rows to keep:** `judgement_b_play_*`, references rows that run `judgement`.

---

### Task 21: The Lantern's Eye in the Capital (spec 6.4.3)

**Files:** `lantern_eye_director.gd`; `capital_missions/lantern_eye.gd`; `tests/test_capital_eye.gd`;
`tools/dev/refs/capital_eye.tsv`; `tests/run_all.gd`.

**Interfaces:** `TOWN_VARS := ["tower_points", "tower_words", "step_at"]`; seeded from consts. `SPIRE` reads become a `spire` var set
at setup from `Places.at(&"temple")` (spec 5 item 10; not a town var). Line ~204: `town().get_center()` (spec 5 item 2).

**Overrides:**
- def: `camera_at` `Vector2(-4.0, -14.0)`, `intro_from` `Vector2(-4.0, -8.0)`.
- director: `tower_points` `[Vector2(-11.0, -30.0), Vector2(18.0, -21.0), Vector2(-11.0, 4.0)]`; `tower_words`
  `["the north tower", "the east tower", "the south tower"]`.

**Tests beyond the shape:** `_towers`: three distinct standing wall towers of `INNER`, none the bell tower or a gate tower; each
within `Searchlight.FAR` of the spire; each party's posts on the town side of its tower (`INNER.has_point`) and `POST_GAP` apart.
`_walk_parity` (printed): the reliefs' walk from the nearest barracks door to each tower.

**Gates:** `gate.sh eye --city=capital --board --with-none`; `--route=b`. Knobs: tower order (near to far); `step_at` 40/115/180.

**Aldermere rows to keep:** `eye_*`, `eye_b_play_*`.

---

### Task 22: Exodus in the Capital (spec 6.4.4)

**Files:** `exodus_director.gd`; `capital_missions/exodus.gd`; `tests/test_capital_exodus.gd`;
`tools/dev/refs/capital_exodus.tsv`; `behaviour_check.gd` (`_exodus_act` and helpers: `ExodusDirector.HOUSE_*`/`GATE_*` -> `d.<var>`),
`routes/tier5_b.gd` (`act_exodus`/`state_exodus`: the same); `tests/run_all.gd`.

**Interfaces:** `TOWN_VARS := ["house_points", "gate_mouths", "gate_exits", "gate_labels", "gate_words", "gate_along", "beat_spots",
"temple_door_at", "gate_at", "exit_at"]`; seeded from consts; `temple_door_at` (spec 5 item 3); EscortDirector's `gate_at`/`exit_at`
seeded in `_init()` from `GATE_MOUTHS[2]`/`GATE_EXITS[2]` and no longer assigned at line ~166. `SHUT_AT` and `OUT_AT` stay (copy).

**Overrides:**
- def: `camera_at` `Vector2(-4.0, -8.0)`, `intro_from` `Vector2(-4.0, -2.0)`.
- director: `house_points` `[Vector2(-16.0, -18.0), Vector2(12.0, -4.0), Vector2(6.0, -1.5)]`; `gate_mouths`
  `[Vector2(-22.4, -13.0), Vector2(16.4, -9.0), Vector2(4.0, 2.4)]`; `gate_exits` `[Vector2(-25.6, -13.0), Vector2(19.6, -9.0), Vector2(4.0, 5.6)]`;
  `gate_labels` `["WEST GATE", "HARBOUR GATE", "BRIDGE GATE"]`; `gate_words` `["the west gate", "the harbour gate", "the bridge gate"]`;
  `gate_along` `[Vector2(0.0, 1.0), Vector2(0.0, 1.0), Vector2(1.0, 0.0)]`; `beat_spots`
  `[[Vector2(-12.0, -20.0), Vector2(-12.0, -10.0)], [Vector2(2.0, -6.0), Vector2(12.0, -6.0)]]`; `temple_door_at`
  `Vector2(-3.9, -14.0)`; `gate_at` `Vector2(4.0, 2.4)`; `exit_at` `Vector2(4.0, 5.6)`.

**Tests beyond the shape:** `_walk_parity`: each household's door to its gate mouth (A 9.0 / 8.2 / 5.0). `_walls`: every
`gate_exits` point is `Walls.outside()` in the Capital. `_no_queue`: a believer set at the bridge gate's mouth with a whisper to its
exit arrives within the walk time plus 2 s on a built Capital in a calm town (the gatehouse queue does not hold him); if it fails, the
third gate becomes the harbour side and the test says why. Gate watch posts `POST_GAP` 2.4 apart.

**Gates:** `gate.sh exodus --city=capital --board --with-none`; `--route=b`. Knobs: households (parity); the third gate.

**Aldermere rows to keep:** `exodus_*`, `exodus_b_play_*`.

---

### Task 23: The Heart of Faith in the Capital (spec 6.4.5)

**Files:** `heart_of_faith_director.gd`; `capital_missions/heart_of_faith.gd`; `tests/test_capital_heart.gd`;
`tools/dev/refs/capital_heart.tsv`; `mission_needs.gd` (row `heart_of_faith` adds `citadel_gate`); `tests/run_all.gd`.

**Interfaces:** `TOWN_VARS := ["oil_at", "steps_at_spot", "lane_foot", "quiet_at", "stage_at"]`; `var steps_at_spot: Vector2 =
STEPS_AT` (the director already has a `steps_at` var set at setup from it: setup reads the town var); the rest seeded from consts;
`CITADEL_GATE` reads become `Places.point(&"citadel_gate")`. `WORDS`, `NAMES` stay (oil-house, Temple: true in the Capital).

**Overrides:**
- def: `camera_at` `Vector2(-6.0, -16.0)`, `intro_from` `Vector2(-6.0, -10.0)`.
- director: `oil_at` `Vector2(-11.0, -20.0)`; `steps_at_spot` `Vector2(-3.9, -14.0)`; `lane_foot` `Vector2(2.0, -13.0)`; `quiet_at`
  `[Vector2(-7.0, -19.0), Vector2(-7.0, -16.4)]`.

**Tests beyond the shape:** `_walk_parity`: the oil-house to the steps (A 8.2); Odran's route, Citadel gate to lane foot to steps (A
about 13.8). Knight posts `POST_APART` 2.1 apart; litter bearers excluded (they move).

**Gates:** `gate.sh heart --city=capital --board --with-none`; `--route=b`. Knobs: `quiet_at` (inside the cathedral close, off the
pilgrim plaza); `stage_at` 45/110.

**Aldermere rows to keep:** `heart_*`, `heart_b_play_*`.

---

### Task 24: The Long Night in the Capital (spec 6.4.2)

Depends on Tasks 9, 14 and 20.

**Files:** `src/game/mission/overrides.gd` (`KEYS` gains `"acts"`), `src/game/mission/mission_book.gd` (`in_city()`),
`src/game/mission/warning_director.gd`; `capital_missions/long_night.gd`; `tests/test_capital_night.gd`;
`tools/dev/refs/capital_night.tsv`; `behaviour_check.gd` (`_night`, `_play_act`: `TownLayout.CITADEL_ORIGIN` ->
`City.current().citadel_origin()`; Act III's fixed targets through Task 20's table); `routes/tier5_b.gd` (`act_night`: the same);
`tests/run_all.gd`.

**Interfaces:**
- `MissionBook.in_city()`: for `ov["acts"]` (a Dictionary act id -> `{"def", "director"}`), `Overrides.apply(m.act(id), def)` and
  the act's `tune` chained as the root's is. An unknown act id: `push_error` and skipped. Root `def`/`director` as today.
- `WarningDirector.TOWN_VARS := ["gate_spot"]`; `var gate_spot: Vector2 = GATE_SPOT`; every code read of `GATE_SPOT` reads it.
  `RingerDirector`, `WitnessDirector` and `StarfallDirector` set their posts as today (their own setups), unchanged.

**Overrides:**
- def (root): `camera_at` `Vector2(-17.4, -15.5)`, `intro_from` `Vector2(-16.4, -13.0)`.
- acts:
  - `omen`: def `camera_at` `Vector2(-17.4, -15.5)`, `intro_from` `Vector2(-16.4, -13.0)`, `brief`
    `PackedStringArray(["A star falls over the west gate.", "A watchman runs to wake the bell."])`; director `gate_spot`
    `Vector2(-22.4, -13.0)`.
  - `festival`: def `camera_at` `Vector2(-7.5, -2.5)`, `intro_from` `Vector2(-7.5, 5.5)`.
  - `procession`: def `camera_at` `Vector2(9.3, -18.6)`, `intro_from` `Vector2(0.0, -25.5)`; director `route_spots` as Task 14.
  - `judgement`: def `intro_from` `Vector2(16.4, -9.0)`, `camera_at` `Vector2(0.0, -25.5)`.

**Tests beyond the shape:** `_acts_applied`: `MissionBook.in_city(MissionBook.long_night(), &"capital")` has each act's values; an
Aldermere long night is unchanged field for field (`tests/test_mission_needs.gd::_builders_keep_aldermere` still passes);
`_unknown_act`: an overrides dict with `"acts": {"nope": {}}` reports one error and changes nothing. `_walk_parity`: the Omen's
watchman to the bell's foot (A 13.7). `_words_true`: the Omen's brief names the west gate.

**Gates:** `gate.sh night --city=capital --board --extra='--path=festival --act1=play --act2=play --act3=play'` and
`--extra='--path=procession ...'`; `gate.sh night --city=capital --route=b --board`. Act III carries Task 20's verdict: if Task 20
stopped, this task stops at the same point and reports.

**Aldermere rows to keep:** `night_b_play_*`, every `warning_*`, `starfall_toll_*`, `warning_toll_*` (WarningDirector changed).

---

### Task 25: Tier 5 close; the god night test

- [ ] **Step 1:** `tests/test_capital_god_night.gd`: `_draw_none` is replaced by `_draw_every_tier` (for k in 1..5,
  `GodNight.draw(_slot(k), "capital")` is one of tier k's five ids); the empty-draw path stays tested by `_hunt_aldermere_only`
  (a full Notice draws "" in the Capital). `tests/test_capital_god_night.gd` header comment updated.
- [ ] **Step 2:** `--only=test_capital_god_night`, `--only=test_board_test_mode`, `--only=test_mission_needs`.
- [ ] **Step 3:** The controller runs the whole suite, the full `refs_check.sh` (`bad=0`), FLOW alone, and the five-board bench
  within about 1 fps of the plan's base (memory `kak-m1-perf-debt`: noisy pairs; rerun on a quiet machine).
- [ ] **Step 4: Commit** `test: every tier is drawn for a god night in the Capital`.

**Numbers:** none. **References:** none move.
