# World Map and Conquer Progress (God's Chamber step 8) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> This project's `kak-milestone` skill applies: the plan gives files, interfaces, tests and numbers, not full code; the
> implementer writes the code test-first.

**Goal:** The god keeps the believers it wins, per town. Each town has a conquer percent; the World Table opens a kingdom map
where the player picks a town and descends; 60% of Aldermere opens the Capital; a 100% town pays Faith every banked night.

**Architecture:** `GodSlot` stores a believer count per town, the opened towns and the last town. `Conquest` (static, no nodes)
holds the arithmetic. `BelieverRoll`, owned by `Mission` on ordinary god nights only, marks the carried believers after the
night's rules are applied (own RNG), records power landings and believer deaths, and picks the fill at the decision; its report
rides in the result under `"conquest"` and `GodNight.bank()` hands it to `Conquest.bank()`. A new `WorldMap` screen
(`Game.Screen.WORLD`) sits between the Chamber's table and Prepare; `GodNight.draw/def_for` take the town.

**Tech Stack:** Godot 4.7.2, GDScript, the project's UI layer (`UiScale`, `UiTheme`, `UiSound`, `ChamberArt`), the project's
test runner (`tests/run_part.gd`).

**Spec:** `docs/superpowers/specs/2026-11-20-kak-world-map-conquer-design.md` (binding; read it first). It builds on
`docs/superpowers/specs/2026-11-19-kak-god-chamber-design.md` (built). Where this plan departs from the spec's wording, the
"Plan notes" section says why.

## Global Constraints

- Worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-chamber`, branch `feat/god-chamber`. Never touch another worktree. Nothing on this
  branch lands until every Chamber step is done: this plan has no landing task.
- Godot: `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`. Always wrap runs in `timeout` (a parse error hangs).
- New `class_name` (Tasks 1, 2, 5): `timeout 600 $G --headless --path . --import` before any headless run.
- One suite: `timeout 900 $G --headless --path . --script res://tests/run_part.gd -- --part=1 --of=1 --only=<test_name>`;
  prints `part=1/1 suites=1 checks=N failures=F`. A suite that dies on a runtime error can still print `failures=0`: read the
  output for `SCRIPT ERROR`. New suites are added to `SUITES` in `tests/run_all.gd`.
- Headless FLOW: `timeout 1500 $G --headless --path . --scene res://scenes/game.tscn -- --flow-test`; expect
  `FLOW result checks=<N> failures=3` where the 3 are the music checks ("plays the theme" / "plays the battle") that already
  fail headless on this machine on the base commit (not ours). Any other FAIL is ours. Run FLOW alone (no other Godot).
- The whole suite (`bash tools/dev/run_suite_parallel.sh 8`) is run by the controller, not per task.
- **A night with a believer count of 0 is bit-for-bit today's night.** Carried believers are chosen with a
  `RandomNumberGenerator` of their own, seeded from the night (`GodNight.believer_seed()`); never `Crowd._rng`, a person's
  `rng`, the global RNG or `NightRules`' stream. With a count of 0 no generator is even made.
- **Replay references must not move:** `bash tools/dev/refs_check.sh` must print `refs ok=508 bad=0` (Tasks 2, 3, 4, 6). A
  moved row is a bug, never a re-record.
- Old saves load: every new `GodSlot` key has a default and a missing key reads as it; `GodSlot.VERSION` stays 1.
- Campaign nights, tier-board nights and DEV-tab nights (`<mission>@<city>` included) are unaffected: no believers marked,
  nothing banked, no wishes switched on that were off. Only Game's Endless nights set `Mission.conquest` / `Mission.god_night`.
- Rites, the Hunt and the dev Awaken change no town count and make no converts.
- `GodChamber.transitions` stays false for `--flow-test`, `--capture` and headless runs (Game's `_ready()` already does this;
  `WorldMap` has no transitions of its own).
- Scripted windowed runs use `user://test_*` files only, never `kak_save.cfg`, `kak_settings.cfg` or `kak_god_<n>.cfg`.
- Stage files by name; never `git commit -a`. Never stage `*.uid` files under `src/core`, `tools/dev/real_path_probe.gd.uid`
  or anything under `captures/`. (New `.uid` files of this plan's own new scripts and tests ARE staged with them.)
- Every commit ends with the line `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`.
- No PixelLab, no ChatGPT automation. Never kill a Godot process you did not start.
- Town ids are plain `String` everywhere in the god's data (`"aldermere"`, `"capital"`): a `Dictionary` keyed by `String` does
  not find a `StringName` key in Godot 4. Convert with `StringName(town)` only when calling `City`.

## Review Focus

1. **Earned counted twice.** `descend.earned` (main reward + granted wishes' rewards) and its Faith stay exactly as today;
   carried believers never enter it, named converts are not paid a second time, only the fill adds Faith on top. Test: Task 3
   `_faith_not_doubled`.
2. **RNG stream leak.** Marking carried believers must not draw from any shared stream; with count 0 nothing is drawn at all.
   Tests: Task 2 `_zero_draws_nothing`, `_marking_leaves_streams`; `refs_check.sh` ok=508.
3. **Reserved people marked or filled.** Director-reserved people and every wish's people (wisher and targets) are never carried
   or filled; children (`Role.CHILD`) and soldiers never either. Tests: Task 2 `_skips_reserved`, Task 3 `_fill_never_picks`.
4. **Old save keys.** A file without `believers`/`opened`/`last_town` loads with defaults; an unknown town is dropped; an
   over-count is clamped; a `last_town` that is unknown or not opened reads `aldermere`. Tests: Task 1 `test_god_slot` additions.
5. **Fill picks dead or escaped people; map Enter with a locked `last_town`.** The fill takes only living citizens still in
   `Crowd.citizens`; an escaped believer counts as alive once; a dead believer is counted lost once. Enter on the map with a
   `last_town` that is locked selects and descends Aldermere. Tests: Task 3 `_fill_never_picks`, Task 2 `_deaths_once`,
   `_escaped_alive`, Task 5 `_locked_last_town`.

Each line has its test in the task that owns the code.

## Plan notes (spec wording vs the code)

1. **`Person.Faith` does not exist.** Faith is `CitizenProfile.Faith { NONE, FAITHFUL, GRIEVING, BELIEVER }` on
   `Person.profile.faith`. A carried believer gets `profile.faith = CitizenProfile.Faith.BELIEVER`. The "carried flag" is kept
   by `BelieverRoll` (`is_carried(p)`), not added to `Person` (3500 lines, many tests build people), so no Person field moves.
2. **"At spawn" is after the night's rules.** `MissionDirector.reserved` and the wishes' people exist only after `_build_act()`
   (the director's setup) and `NightRules.apply()` picks from `faith == NONE` people. Marking right after
   `_apply_night_rules()` in `Mission.start()` is the earliest point where "skip the reserved" is possible and keeps NightRules'
   indoor pick identical. Directors that pick NONE-faith people later in the night skip carried believers: that changes only
   nights with a count above 0.
3. **"Reserved" = director's `reserved` + every wish's `people()`** (the same `kept` list `_apply_night_rules()` builds today),
   plus the rule that only `faith == NONE`, non-child citizens are carried. Children are not in `CityDef.citizens()`, so they
   never count toward a town and are never carried or filled.
4. **`descend.earned` is not a head count.** It is `Descent.main_reward()` plus granted wishes' `reward` (tier-scaled
   numbers), so carried believers could never be "earned again". It and its Faith stay as today. "Named converts pay" is
   already that Faith (a granted wish's reward); the fill pays `FILL x FAITH_PER_BELIEVER` on top. Named converts are counted
   as heads (living citizens whose faith is BELIEVER and who were not carried, plus such believers who escaped), which covers
   `NeighboursWish`'s several believers too.
5. **Power landings** are taken from `Crowd.danger_landed(key, points, radius)` (loud powers) and also from
   `Rules.cast_made(slot, key, at)` (quiet powers emit no danger), so "no power cast" means truly none.
6. **The night's seed** is `GodNight.believer_seed(slot, id) = hash([slot.seed, slot.night, id, "believers"])`, beside
   `look_for()` and `wish_seed()`. `Game` passes `Time.get_ticks_usec()` as the crowd seed, so "seeded from the night" cannot be
   the crowd seed.
7. **Abandon and crash.** `GodNight.forfeit()` gains `alive := -1`. Pause's Abandon and the interlude's Missions pass the
   roll's `carried_alive()` (deaths still cost); a forfeit found at load (`Game.load_god`) has no roll and passes -1: the count
   is kept. The town of an open night is `slot.last_town`, so `Game` sets `last_town` when the map descends (not at bank).
8. **More carried than fit:** the saved count is not reduced: `carried_alive = alive marked + escaped marked + unplaced`.
9. **Hunts play only in Aldermere in this step.** `HuntBook` defs are not in `MissionNeeds`, and `Places.can_host()` errors on
   them; `GodNight.draw(slot, town)` returns `""` while the Hunt is due and `town != "aldermere"` (the Capital buzzes
   `NO_NIGHT`, the Chamber's Hunt line already says what waits).
10. **The conquered bonus** is paid by `GodNight.bank()` (ordinary nights and Hunts, after this night's count is banked), not
    by rites (`_bank_rite`) or forfeits. It is counted after the bank, so the night that reaches 100% pays.
11. **DEV-tab Capital nights stay wishless.** `Mission.has_descent(def, on_board, any_town := false)`: Aldermere as today; another
    town only when `any_town` (Game's god nights) and `CityDef.wishes()` is true. The DEV tab never passes `any_town`.
12. **The keys hint.** A night has no keys row; the closest is `LegendPanel.FOOTER` (H). B is named there:
    `"H next   B believers   Esc close   the night waits"`.
13. **Town names** live once, in `Conquest.TOWN_NAMES`; `WorldLayout` reads real towns' names from it (its sealed spots carry
    their own).
14. **The Chamber's table no longer refuses.** Spec 4.5: with nothing to draft the map still opens and the map's Descend buzzes
    `HubStatus.BLOCKED`. So `HubStatus.press("descend")` always emits, the table is not dim, and the blocked line still shows in
    the Chamber; `test_hub_status._blocked` and `test_god_chamber._blocked` change accordingly.
15. **Bests.** A Capital god night keeps the base mission id (`tax_collector`, not `tax_collector@capital`), so `GodSlot.bests`
    and `last_mission` are shared across towns, and `MissionBook.is_dev()` stays false for it: it banks fully (spec 4.6).

---

### Task 1: `GodSlot` fields and `Conquest`

**Files:**
- Create: `src/game/god/conquest.gd`, `tests/test_conquest.gd`
- Modify: `src/game/god/god_slot.gd`, `tests/test_god_slot.gd`, `tests/run_all.gd`

**Interfaces:**
- Produces: `class_name Conquest extends RefCounted` (all static)
  - `const HOME := "aldermere"`
  - `const UNLOCK_PERCENT := 60`, `const CONQUER_FAITH := 5`, `const FILL_CAUGHT := 3`, `const FILL_CLEAN := 6`
  - `const OPENS := {"aldermere": "capital"}` (the town whose percent opens the next)
  - `const TOWN_NAMES := {"aldermere": "Aldermere", "capital": "The Capital"}`
  - `static func towns() -> PackedStringArray` (`["aldermere", "capital"]`, from `City.IDS` as Strings, test cities excluded)
  - `static func is_town(town: String) -> bool`
  - `static func town_name(town: String) -> String`
  - `static func population(town: String) -> int` (`City.by_id(StringName(town)).citizens()`; 0 for an unknown town)
  - `static func percent(believers: int, pop: int) -> int` (`floor(100 * clamp(believers, 0, pop) / pop)`; 0 when pop <= 0)
  - `static func count_of(slot: GodSlot, town: String) -> int` (clamped 0..population)
  - `static func percent_of(slot: GodSlot, town: String) -> int`
  - `static func is_open(slot: GodSlot, town: String) -> bool` (HOME always; else `slot.opened.has(town)`)
  - `static func opener_of(town: String) -> String` (the key of `OPENS` whose value is `town`, or "")
  - `static func conquered(slot: GodSlot, town: String) -> bool` (percent == 100)
  - `static func conquered_towns(slot: GodSlot) -> PackedStringArray`
  - `static func bonus(slot: GodSlot) -> int` (`CONQUER_FAITH * conquered_towns(slot).size()`)
  - `static func fill_target(main: bool, ascended: bool) -> int` (0 / `FILL_CAUGHT` / `FILL_CLEAN`)
  - `static func bank(slot: GodSlot, roll: Dictionary, main: bool) -> Dictionary`: `roll` is `BelieverRoll.report()`'s
    `{"town", "carried_alive", "named", "fill", "lost"}`. Sets `slot.believers[town] = clamp(carried_alive + (named + fill if
    main else 0), 0, population)`; then opens every `OPENS` target whose opener is at or above `UNLOCK_PERCENT` (never closes
    one). Returns `{"town", "before", "count", "percent", "named", "fill", "converts", "lost", "opened": PackedStringArray (newly
    opened), "conquered": bool}`. An unknown town returns `{}` and changes nothing.
- Produces on `GodSlot`:
  - `var believers := {}` (town String -> int; a missing town is 0)
  - `var opened := PackedStringArray(["aldermere"])`
  - `var last_town := "aldermere"`
  - `read()`: `believers` keeps only `Conquest.is_town()` keys with int/float values, each clamped 0..population; `opened`
    keeps only known towns and always holds `"aldermere"`; `last_town` falls back to `"aldermere"` when unknown or not opened.
  - `write()`: the three keys, under their own names.

- [ ] **Step 1:** Write `tests/test_conquest.gd` (fixtures: `GodSlot.make(1, "ruin", 7)`):
  - `_percent`: `percent(0, 220) == 0`, `percent(1, 220) == 0`, `percent(132, 220) == 60`, `percent(219, 220) == 99`,
    `percent(220, 220) == 100`, `percent(500, 220) == 100`, `percent(-3, 220) == 0`, `percent(5, 0) == 0`.
  - `_population`: `population("aldermere") == Crowd.CITIZENS` (220: `AldermereCity` keeps `CityDef.citizens()`); `population("capital") == CapitalCity.new().citizens()`;
    `population("nowhere") == 0`.
  - `_unlock`: aldermere at 131 -> capital not open; bank to 132 (60%) -> `opened` gains "capital" and the result's
    `opened == ["capital"]`; bank down to 10 -> capital still open, result `opened` empty.
  - `_conquered`: 220 in aldermere -> `conquered(...)`, `bonus == 5`; both towns full -> `bonus == 10`; 219 -> not conquered.
  - `_bank_clean`: carried_alive 10, named 2, fill 6, main true -> count 18, `converts == 8`, `before == 10`.
  - `_bank_caught`: carried_alive 10, named 1, fill 3 -> 14.
  - `_bank_failed`: carried_alive 7 (of 10 carried), named 2, fill 6, main false -> count 7, `converts == 0`.
  - `_bank_abandoned` (same arithmetic as failed, from `carried_alive` alone): 10 carried, 4 died -> 6.
  - `_bank_clamps`: carried_alive 219 + fill 6 -> 220; unknown town -> `{}`, slot unchanged.
  - `_fill_target`: (false, false) 0, (true, false) 3, (true, true) 6.
- [ ] **Step 2:** Add to `tests/test_god_slot.gd`:
  - `_conquest_round_trip`: believers `{"aldermere": 40, "capital": 3}`, opened `["aldermere", "capital"]`, last_town
    "capital" survive `write()` + `read()` (to `user://test_god_conquest.cfg`, removed after).
  - `_conquest_old_save`: a cfg written by `ConfigFile` with only `type` and `level` reads `believers == {}`,
    `opened == ["aldermere"]`, `last_town == "aldermere"`.
  - `_conquest_unknown_town`: `{"atlantis": 5, "aldermere": 2}` reads `{"aldermere": 2}`; opened `["atlantis"]` reads
    `["aldermere"]`; last_town "atlantis" reads "aldermere".
  - `_conquest_over_count`: aldermere 9999 reads 220; -4 reads 0.
  - `_conquest_locked_last`: last_town "capital" with opened `["aldermere"]` reads "aldermere".
  Add `test_conquest.gd` to `tests/run_all.gd`.
- [ ] **Step 3:** Run both; expect a parse failure (`Conquest` not declared) and failing new `test_god_slot` checks.
- [ ] **Step 4:** Write `Conquest` and the `GodSlot` fields. `--import`.
- [ ] **Step 5:** `--only=test_conquest`, `--only=test_god_slot`: 0 failures, no `SCRIPT ERROR`.
- [ ] **Step 6:** Commit: `feat: GodSlot keeps believers per town; Conquest holds the conquer arithmetic`.

### Task 2: `BelieverRoll` (carried believers, deaths, banking in Aldermere; the percent in the bar and the results)

**Files:**
- Create: `src/game/god/believer_roll.gd`, `tests/test_believer_roll.gd`
- Modify: `src/game/mission.gd`, `src/game/god/god_night.gd`, `src/game/game.gd`, `src/game/ui/hub_status.gd`,
  `src/game/ui/god_chamber.gd`, `src/game/ui/results_screen.gd`, `tests/test_god_night.gd`, `tests/test_hub_status.gd`,
  `tests/test_god_chamber.gd`, `tests/run_all.gd`

**Interfaces:**
- Consumes: `Conquest` (Task 1).
- Produces: `class_name BelieverRoll extends RefCounted`
  - `const SEED_TAG := "believers"`
  - `var town := ""`, `var asked := 0` (the saved count), `var marked: Array[Person] = []`, `var unplaced := 0`,
    `var lost := 0`, `var landings := PackedVector2Array()` (Task 3 fills it)
  - `func setup(crowd: Crowd, p_town: String, p_seed: int) -> BelieverRoll` (connects `crowd._field.enemy_killed` and
    `crowd.escaped`; stores the seed, makes no generator)
  - `static func eligible(p: Variant, reserved: Array) -> bool`: valid, alive, not a soldier, `profile != null`,
    `profile.role != Role.CHILD`, `profile.faith == Faith.NONE`, not in `reserved`
  - `func mark_carried(count: int, reserved: Array) -> int`: returns the number marked. `count <= 0`: returns 0 and makes no
    `RandomNumberGenerator`. Else: pool = eligible `crowd.citizens` in crowd order; Fisher-Yates with a generator seeded
    `hash([seed, SEED_TAG])` (as `NightRules.pick_indoors`); the first `min(count, pool.size())` get `faith = BELIEVER` and go
    into `marked`; `unplaced = count - marked.size()`.
  - `func is_carried(p: Variant) -> bool`
  - `func attach(rules: Rules) -> void` (per act; Task 3 connects `cast_made`; safe to call twice)
  - `func carried_alive() -> int`: living marked still in `crowd.citizens` + marked that escaped + `unplaced`
  - `func report(main: bool, ascended: bool, reserved: Array) -> Dictionary`:
    `{"town", "carried": asked, "marked": marked.size(), "carried_alive", "named": 0, "fill": 0, "lost"}` (named and fill are
    Task 3's; the keys exist now)
  - `func release() -> void` (disconnects what `setup`/`attach` connected)
  - Deaths: `_on_killed(e, kind)`: a `Person` whose `profile.faith == BELIEVER` adds 1 to `lost`, once per person (kept in a
    `Dictionary` by instance id). Escapes: `_on_escaped(p)`: a marked person is remembered as escaped-alive (its node is freed
    right after the signal: keep the count, not the reference).
- Produces on `Mission`:
  - `var god_night := false` (Game: any Endless night; used by Task 6), `var conquest := false` (Game: an ordinary god night,
    not a rite, not a Hunt), `var carried := 0`, `var believer_seed := 0`
  - `func _reserved() -> Array` (director's `reserved` + every wish's `people()`; `_apply_night_rules()` now uses it, same
    order, same list)
  - In `start()`: release an old roll with the Descent's; after `_apply_night_rules(seed_value)`:
    `if conquest and _descent != null:` make the roll, `mark_carried(carried, _reserved())`, `attach(_rules)`.
    In `next_act()`: `attach(_rules)` after `_build_act()`.
  - `func believers() -> BelieverRoll` (null off god nights), `func carried_alive() -> int` (-1 with no roll)
  - `_with_descent(res)`: also `res["conquest"] = _believers.report(_rules.main_done, _rules.ascended, _reserved())` when a
    roll exists.
- Produces on `GodNight`:
  - `static func believer_seed(slot: GodSlot, id: String) -> int` (`hash([slot.seed, slot.night, id, "believers"])`)
  - `bank()`: when `outcome.conquest` is not empty and the night is not the Hunt, `Conquest.bank(slot, c, d.main)`; result
    gains `"conquest"` (Conquest.bank's dictionary, `{}` otherwise). Faith unchanged in this task.
  - `forfeit(slot: GodSlot, alive := -1)`: an ordinary night (not rite, not Hunt) with `alive >= 0` sets
    `slot.believers[slot.last_town] = clamp(alive, 0, population)`; -1 keeps the count. Result gains `"conquest"`
    (`{"town", "count", "percent"}` or `{}`).
- Produces on `Game`: in `_build_mission()` Endless branch: `mission.god_night = true`, `mission.conquest = not
  GodNight.is_rite(mission_id) and not GodNight.is_hunt(mission_id)`, `mission.carried = Conquest.count_of(god, "aldermere")`
  (Task 5 makes it the night's town), `mission.believer_seed = GodNight.believer_seed(god, mission_id)`.
  `_abandon_night()`: `GodNight.forfeit(god, _mission.carried_alive() if is_instance_valid(_mission) else -1)`.
- Produces on `HubStatus`: `func town_line() -> String` (`"%s %d%%" % [Conquest.town_name(last_town), percent]`, e.g.
  `"Aldermere 0%"`). `GodChamber._draw_bar` draws it left of "Night n"; `GodChamber.bar_parts() -> Dictionary` returns the
  rects it drew (`"town"`, `"night"`, `"notice"`, `"faith"`, `"points"`, `"power"`) so a test can check they do not overlap.
- Produces on `ResultsScreen`: `const CONQUEST_LINE := "%s %d%%   converts +%d   believers lost %d"`; `god_lines()` inserts it
  just before the "Night n" line when `result.god.conquest` is not empty (no line otherwise: old results unchanged).

- [ ] **Step 1:** Write `tests/test_believer_roll.gd`. World fixture as `tests/test_descent.gd`'s `_world()` (Aldermere, crowd
  seed 5, a Tier 1 def from `TierBook.board("tax_collector")`, a Descent attached so wishes reserve their people):
  - `_marks_n`: count 12 -> 12 citizens have `faith == BELIEVER` and `is_carried`; `marked.size() == 12`; `unplaced == 0`.
  - `_skips_reserved`: no marked person is in the director's `reserved` or any wish's `people()`; none is a soldier or a child
    (turn `Children.enabled` on for this case, restore it).
  - `_same_seed`: two fresh worlds, same crowd seed and roll seed -> the same citizen indices marked; another roll seed ->
    a different set.
  - `_zero_draws_nothing`: snapshot `crowd._rng.state`, every citizen's `rng.state` and `faith`; `mark_carried(0, ...)` returns
    0 and every snapshot is equal after.
  - `_marking_leaves_streams`: the same snapshots with count 30: `crowd._rng.state` and every person's `rng.state` unchanged.
  - `_too_many`: count 10000 -> every eligible citizen marked, `unplaced == 10000 - marked.size()`,
    `carried_alive() == 10000` before any death.
  - `_deaths_once`: kill two marked people (`crowd._field.kill(p, &"test")`, which emits `enemy_killed`); `lost == 2`; emit the killed signal a
    second time for one of them -> still 2; `carried_alive() == count - 2`; killing a non-believer leaves `lost` unchanged.
  - `_escaped_alive`: `crowd.escape(marked[0])` -> `carried_alive()` unchanged (still counted).
  - `_report_keys`: `report(true, false, [])` has exactly the keys town, carried, marked, carried_alive, named, fill, lost.
- [ ] **Step 2:** Add to `tests/test_god_night.gd`:
  - `_bank_conquest`: a slot with aldermere 50, an outcome with `descend.main == true` and
    `conquest = {"town": "aldermere", "carried_alive": 48, "named": 0, "fill": 0, "lost": 2}` -> `slot.believers.aldermere ==
    48`, result `conquest.count == 48`; Faith equals `earned` exactly (unchanged rule).
  - `_bank_no_conquest`: an outcome without "conquest" leaves `believers` untouched and result `conquest == {}`.
  - `_hunt_no_conquest`: a Hunt bank with a conquest entry changes no count.
  - `_forfeit_alive`: in_night set, last_town aldermere, count 50: `forfeit(slot, 41)` -> 41; `forfeit(slot)` -> unchanged.
  - `_believer_seed`: stable for the same slot/night/id; differs by night.
  Add to `tests/test_hub_status.gd` `_town_line`: fresh god `"Aldermere 0%"`; aldermere 132 -> `"Aldermere 60%"`.
  Add to `tests/test_god_chamber.gd` `_bar_town`: at the four test areas (as `_resolutions`), the `bar_parts()` rects lie in
  `bar_rect()` and no two intersect. Add a `ResultsScreen.god_lines()` case (in `tests/test_god_night.gd` or the results suite
  that already tests `god_lines`): with `god.conquest = {"town": "aldermere", "percent": 12, "converts": 4, "lost": 1, ...}`
  the line before "Night n" is `"Aldermere 12%   converts +4   believers lost 1"`; without it, the lines are as before.
  Add `test_believer_roll.gd` to `tests/run_all.gd`.
- [ ] **Step 3:** Run the four suites; expect the parse failure and the new checks failing.
- [ ] **Step 4:** Implement. `--import`.
- [ ] **Step 5:** `--only=test_believer_roll`, `test_god_night`, `test_hub_status`, `test_god_chamber`, `test_descent`,
  `test_mission_book`: 0 failures. `bash tools/dev/refs_check.sh`: `refs ok=508 bad=0`.
- [ ] **Step 6:** Headless FLOW: only the 3 known music failures.
- [ ] **Step 7:** Commit: `feat: BelieverRoll carries a town's believers into its nights; deaths cost; the percent on the bar and results`.

### Task 3: Converts (power landings recorded; named plus fill)

**Files:**
- Modify: `src/game/god/believer_roll.gd`, `src/game/god/god_night.gd`, `src/game/game.gd` (FLOW's Faith check),
  `tests/test_believer_roll.gd`, `tests/test_god_night.gd`

**Interfaces:**
- Consumes: `Crowd.danger_landed(key: String, points: Array[Vector2], radius: float)`,
  `Rules.cast_made(slot: int, key: String, at: Vector2)`, `Conquest.fill_target()`.
- Produces on `BelieverRoll`:
  - `func record(points: Array[Vector2]) -> void` (appends to `landings`; connected to `danger_landed` in `setup`, and
    `cast_made`'s `at` in `attach`, connected once per Rules)
  - `func named() -> int`: living citizens with `faith == BELIEVER` that are not carried, plus such believers that escaped
  - `func pick_fill(count: int, reserved: Array) -> Array[Person]`: candidates = `crowd.citizens` that are valid, alive, not a
    soldier, not a child, `faith != BELIEVER`, not in `reserved`. Order: by the least distance from `ground_pos` to any point in
    `landings`; with no landings, to any named convert's `ground_pos`; with neither, crowd order. Ties keep crowd order (a
    stable sort: sort `[distance, index]` pairs). Returns the first `min(count, candidates.size())`. Marks nobody.
  - `report()` now fills `"named"` and `"fill"` (`pick_fill(Conquest.fill_target(main, ascended), reserved).size()`);
    both 0 when `main` is false.
- Produces on `GodNight.bank()`: Faith = `earned * FAITH_PER_BELIEVER + conquest.fill * FAITH_PER_BELIEVER`; result gains
  `"converts"` (named + fill) and `"faith"` includes the fill's Faith.
- `Game._flow_endless`: the banked check (`god.faith == int(d.get("earned", -1))`) becomes
  `god.faith == earned + int(banked.conquest.fill)`, and its line names the fill.

- [ ] **Step 1:** Add to `tests/test_believer_roll.gd`:
  - `_landings`: `crowd.danger_landed.emit("ember", [Vector2(1, 1)], 1.0)` and a `cast_made` emit -> `landings.size() == 2`.
  - `_fill_nearest`: one landing at a chosen citizen's `ground_pos` -> `pick_fill(3, [])[0]` is that citizen (or one at
    distance 0), and the three are in ascending distance.
  - `_fill_two_landings`: two landings far apart -> each pick's distance is the min over both.
  - `_fill_falls_back_named`: no landings, one named convert (a citizen set BELIEVER by hand) -> picks nearest to it.
  - `_fill_falls_back_order`: no landings, no named -> the first eligible citizens in crowd order.
  - `_fill_never_picks`: a carried believer, a reserved person, a dead person (killed), a soldier, a child and an escaped
    person all stand on the landing point -> none is picked.
  - `_fill_fewer`: a pool of 2 eligible (others made believers) -> `pick_fill(6, [])` returns 2.
  - `_named`: a wish's `grant()` on a living wisher -> `named() == 1`; the wisher killed -> `named() == 0`, `lost` +1.
  - `_report_counts`: clean (`main` true, `ascended` true) -> fill 6; caught -> 3; failed -> named 0, fill 0.
- [ ] **Step 2:** Add to `tests/test_god_night.gd` `_faith_not_doubled`: carried_alive 30, named 2, fill 6, earned 40 ->
  Faith `+46` (40 + 6), count 38; the same with no conquest entry -> Faith `+40`.
- [ ] **Step 3:** Run; expect the new checks to fail.
- [ ] **Step 4:** Implement; update the FLOW check.
- [ ] **Step 5:** `--only=test_believer_roll`, `--only=test_god_night`: 0 failures. `refs_check.sh`: `refs ok=508 bad=0`.
  Headless FLOW: only the 3 known music failures.
- [ ] **Step 6:** Commit: `feat: converts at a night's end: the wishes' believers plus a fill nearest the god's landings`.

### Task 4: Believer view (the B toggle, head marks, the aim count)

**Files:**
- Modify: `src/game/mission.gd`, `src/game/ui/hud.gd`, `src/game/targeting.gd`, `src/game/ui/legend_panel.gd`,
  `tests/test_legend.gd`
- Create: `tests/test_believer_view.gd`; Modify: `tests/run_all.gd`

**Interfaces:**
- Produces on `Mission`:
  - `const BELIEVER_KEY := KEY_B`, `static func toggles_believers(event: InputEvent) -> bool` (pressed, not echo, B, no
    Alt/Ctrl/Meta; shaped like `toggles_legend`)
  - `var believer_view := false` (set false in `start()`; carried across acts by `_build_act()`)
  - `func set_believer_view(on: bool) -> void` (sets `_hud.believer_view` and `_aim.believer_view`, redraws)
  - `_unhandled_input`: B toggles it (handled beside H; not while the legend is open), any night.
- Produces on `Hud`:
  - `const BELIEVER_COL := Color("ffd75a")`, `const BELIEVER_LIFT := 14.0` (below `MapTag.PERSON_LIFT` 22, so a mission's
    diamond sits above the gold mark)
  - `var believer_view := false`
  - `func believer_tags() -> Array[MapTag]`: off -> empty; on -> one `MapTag.pip(p, BELIEVER_COL)` with `lift = BELIEVER_LIFT`,
    no label, for every living citizen whose `profile.faith == BELIEVER`
  - `all_tags()`: `believer_tags()` first (drawn under), then the director's, the Lantern's and the wishes', through
    `MapTag.shown()` as today
  - `_draw()`: when `_aim.believers_text() != ""`, the text in `BELIEVER_COL`, `UiTheme.TEXT_S`, at the aim point's screen
    position + (10, -10)
- Produces on `Targeting`:
  - `var believer_view := false`, `func aim_at() -> Vector2` (the `_press` ground point)
  - `static func in_shape(a: Dictionary, at: Vector2, dir: Vector2, run: float, point: Vector2) -> bool`: `circle`, `pick`,
    `regions`, `gather`: within `a.r` of `at`; `square`: inside `square(at, a.half)`; `lane`: `at` is the lane's start, within
    `a.half` of the segment `at .. at + dir * run`; `cone`: within `a.r` and within `a.arc / 2` of `dir`; any other shape false
  - `func believers_in() -> int`: 0 when the view is off or no slot is focused; else living believer citizens for which
    `in_shape(area(), start, aim_dir(), lane_length(), p.ground_pos)` (start = `lane_start(...)` for a lane, else `_press`)
  - `func believers_text() -> String`: "" when `believers_in() == 0`; `"1 believer"`; `"%d believers"`
- `LegendPanel.FOOTER := "H next   B believers   Esc close   the night waits"`.

- [ ] **Step 1:** Write `tests/test_believer_view.gd` (world as Task 2's fixture, a Hud and a Targeting set up on its Rules):
  - `_off_by_default`: a fresh Hud's `believer_tags()` is empty with 5 believers set; `Targeting.believers_text() == ""`.
  - `_marks_on`: view on -> `believer_tags().size() == 5`, each `who` a believer, `label == ""`, colour `BELIEVER_COL`,
    `lift == BELIEVER_LIFT`; a dead believer has none; `all_tags()` begins with them.
  - `_marks_off_again`: on then off -> empty.
  - `_in_shape`: circle r 1 at (0,0): (0.9, 0) in, (1.1, 0) out; square half 1: (0.9, 0.9) in, (1.1, 0) out; lane half 0.5
    from (0,0) along (1,0) run 4: (3, 0.4) in, (3, 0.6) out, (5, 0) out; cone r 2 arc 90 deg dir (1,0): (1, 0.5) in, (0, 1) out;
    shape "wheel" -> false.
  - `_aim_count`: slot 0 focused on a circle power, `_press` on 3 believers within r and 1 outside -> `believers_in() == 3`,
    text `"3 believers"`; one inside -> `"1 believer"`; view off -> `""`.
  - `_toggle_key`: `Mission.toggles_believers()` true for B pressed, false for B echo, B released, Ctrl+B, and H.
- [ ] **Step 2:** Update `tests/test_legend.gd` if it checks `FOOTER` verbatim. Add the suite to `tests/run_all.gd`.
- [ ] **Step 3:** Run; expect failures.
- [ ] **Step 4:** Implement.
- [ ] **Step 5:** `--only=test_believer_view`, `test_legend`, `test_hud`, `test_targeting`: 0 failures. `refs_check.sh`:
  `refs ok=508 bad=0` (the view is off in every reference run).
- [ ] **Step 6:** Commit: `feat: the believer view (B): gold marks over believers and a believer count in the aim`.

### Task 5: The World Map page, routes, sealed spots, unlock and conquered bonus; FLOW and probe

**Files:**
- Create: `src/game/ui/world_layout.gd`, `src/game/ui/world_map.gd`, `tests/test_world_map.gd`
- Modify: `src/game/game.gd`, `src/game/god/god_night.gd`, `src/game/ui/hub_status.gd`, `src/game/ui/god_chamber.gd`,
  `tools/dev/real_path_probe.gd`, `tests/test_hub_status.gd`, `tests/test_god_chamber.gd`, `tests/test_god_night.gd`,
  `tests/run_all.gd`

**Interfaces:**
- Produces: `class_name WorldLayout extends RefCounted` (static data, 640 x 360 design units)
  - `const LAND := Rect2(40.0, 34.0, 560.0, 290.0)`, `const HIT_R := 16.0`
  - `const SPOTS: Array` of `{id: String, name: String, place: Vector2, source: String}` (`source` "town" or "sealed"; a
    town's `name` is "" and read from `Conquest.town_name()`):

    | id | name | place | source |
    |---|---|---|---|
    | aldermere | (Conquest) | 250, 220 | town |
    | capital | (Conquest) | 420, 140 | town |
    | thornwick | Thornwick | 110, 110 | sealed |
    | saltmere | Saltmere | 540, 260 | sealed |
    | greyhollow | Greyhollow | 130, 290 | sealed |
    | vael | Vael Crossing | 555, 85 | sealed |

  - `const ROADS := [["aldermere", "capital"]]`
  - `static func ids() -> PackedStringArray`, `static func spot(id: String) -> Dictionary`, `static func name_of(id: String)
    -> String`, `static func is_town(id: String) -> bool`, `static func spot_rect(id: String) -> Rect2` (a `2 * HIT_R` square
    about `place`), `static func at(point: Vector2) -> String` (nearest spot within `HIT_R`, else "")
- Produces: `class_name WorldMap extends Node`
  - `signal action(name: String)` ("descend", "back")
  - `const SEALED_LINE := "Beyond your reach"`, `const LOCK_LINE := "Conquer %d%% of %s"` (-> "Conquer 60% of Aldermere"),
    `const NO_NIGHT := "No night waits there yet"`, `const HINT := "Arrows: choose   Enter: Descend   Esc: Back"`
  - `var selected := ""`, `var line := ""`, `var status: HubStatus`, `var _ui: Control`
  - `func setup(slot: GodSlot, p_dev := false) -> WorldMap`: same layer and blocker pattern as `GodChamber.setup`
    (`UiScale.design_frame`, the blocker takes the mouse); `selected = slot.last_town` if open, else "aldermere"
  - `func spot_state(id: String) -> String`: "sealed", "locked", "conquered", "dim" (open, `GodNight.draw(slot, id) == ""`),
    "open"
  - `func selectable(id: String) -> bool` (open, dim or conquered)
  - `func select(id: String) -> bool`, `func move(dir: Vector2) -> void` (the selectable spot whose direction from the selected
    one has the largest positive dot with `dir`, ties to the nearer; nothing when none)
  - `func press_descend() -> void`: not `status.can_descend()` -> `ui_buzz`, `line = HubStatus.BLOCKED`; state "dim" ->
    `ui_buzz`, `line = NO_NIGHT`; else `ui_click`, emit "descend"
  - `func click(point: Vector2) -> void`: the Back button -> emit "back"; the Descend button or the selected spot ->
    `press_descend()`; another selectable spot -> select it (`ui_hover`); a sealed or locked spot -> `ui_buzz`, nothing else
  - `func back_rect() -> Rect2` (bottom-left, `Rect2(12, 330, 60, 18)` anchored to the backdrop's left edge), `func
    descend_rect() -> Rect2` (on the selected town's info plate)
  - `func info_lines(id: String) -> PackedStringArray`: open town: name, `"%d%%"`, `"%d / %d believers"`; conquered adds
    "Conquered"; locked: name, `LOCK_LINE % [Conquest.UNLOCK_PERCENT, Conquest.town_name(Conquest.opener_of(id))]`; sealed:
    name, `SEALED_LINE`
  - `_unhandled_input`: arrows -> `move()`; Enter / KP Enter -> `press_descend()`; Esc -> emit "back"
  - Drawing: `ChamberArt.texture("map")` (`res://assets/chamber/map.png`) over the backdrop when it exists, else a greybox:
    backdrop dark sea, `LAND` in `ChamberArt.greybox_color("table")`-family green-grey, the road as a 2-unit line; each spot a
    diamond (gold selected, white open, grey dim/locked, dark sealed), a percent bar under each town, a seal ring on a conquered
    one; the info plate, the line, the hint and the two buttons.
- Produces on `GodNight`: `static func draw(slot: GodSlot, town := "aldermere") -> String` returns `""` for any town but
  "aldermere" (Task 6 opens other towns); Aldermere's draw is exactly today's.
- Produces on `GodNight.bank()`: after `Conquest.bank`, `faith += Conquest.bonus(slot)`; result gains `"conquer_faith"`;
  `ResultsScreen.god_lines()` shows `"Conquered towns: Faith +%d"` after the conquest line when it is above 0.
- Produces on `HubStatus.press("descend")`: always `{"emit": "descend", ...}` (Plan note 14); `GodChamber.station_state
  ("descend")` is never "dim".
- Produces on `GodChamber.setup`: `p_from == "descend"` also plays the zoom back.
- Produces on `Game`:
  - `enum Screen { ..., FAITH, WORLD }` (appended last; no index moves)
  - `FLOW`: `"hub:descend": Screen.WORLD`, `"world:descend": Screen.PREPARE`, `"world:back": Screen.HUB`
  - `var night_town := "aldermere"`; `go_to(Screen.WORLD)` builds `WorldMap` under the node name "World", in the Endless
    list, `Music.play(&"theme")`
  - `_on_hub_action("descend")`: `on_action("hub:descend")` (no draw here any more); "awaken" sets `night_town = "aldermere"`
  - `func _on_world_action(what: String, map: WorldMap) -> void`: "descend" -> `god.last_town = map.selected`,
    `night_town = map.selected`, `mission_id = GodNight.draw(god, night_town)`, loadout as today,
    `on_action("world:descend")`; "back" -> `on_action("world:back")`
  - `on_action`: `_hub_from = "descend"` after "world:back"
  - `_build_mission`: `mission.carried = Conquest.count_of(god, night_town)`
  - FLOW: `func _flow_descend(hub: GodChamber) -> WorldMap` (clicks the table, then `press_descend()` on the map; returns the
    map or null) replaces each of the nine `hub.click(hub.menu_rect("descend").get_center())` sites; new
    `func _flow_world(step: Callable) -> void` run after `_flow_endless`: the table opens WORLD (`_screen_node is WorldMap`,
    `selected == "aldermere"`); the Capital is "locked" with `"Conquer 60% of Aldermere"`; Esc returns to HUB; with aldermere at
    132 believers and written, the map shows the Capital "dim" (until Task 6) and a click on it then Enter buzzes with
    `NO_NIGHT`, no screen change; Enter on Aldermere opens PREPARE; Prepare's back returns to the HUB.
  - `--show=world` (in `_show_endless`'s match, beside "hub"): the map on a fixture god with aldermere 132 (Capital open).
- Produces on the probe: `_route_god` after "hub Descend": `_screen_is("WorldMap")`, then `os_click_design(map._ui,
  map.descend_rect().get_center(), "map Descend")` and the existing `PrepareScreen` check.

- [ ] **Step 1:** Write `tests/test_world_map.gd` (fixtures from `tests/test_god_chamber.gd`: `_slot`, `_click`, `_key`,
  `_make` shaped for WorldMap; `GodTree.dev_fill = true`):
  - `_six_spots`: `WorldLayout.ids().size() == 6`, two towns, four sealed; every `spot_rect` inside `LAND` and below
    `ChamberLayout.BAR_H`; no two rects intersect; `at(place)` returns each id.
  - `_sealed_refuse`: a click on each sealed spot leaves `selected` and emits nothing; `info_lines` second line is
    `"Beyond your reach"`; `select("thornwick") == false`.
  - `_locked_refuse`: fresh god -> `spot_state("capital") == "locked"`, click selects nothing, `info_lines("capital")[1] ==
    "Conquer 60% of Aldermere"`.
  - `_starts_on_last`: aldermere 132, opened capital, last_town "capital" -> `selected == "capital"`.
  - `_locked_last_town`: `last_town = "capital"` set in memory with opened `["aldermere"]` -> `selected == "aldermere"`;
    Enter emits "descend" with `selected == "aldermere"`.
  - `_enter_descends`: Enter and KP Enter emit "descend" once each; a click on the selected spot and on `descend_rect()` too.
  - `_esc_backs`: Esc and a click on `back_rect()` emit "back".
  - `_arrows`: with both towns open, Right from Aldermere selects the Capital, Left returns; Up/Down never select a sealed spot.
  - `_blocked`: empty tree (`GodTree.use_table(GodTree.blank())`) -> the map opens, Enter emits nothing,
    `line == HubStatus.BLOCKED`.
  - `_dim_town`: Capital open -> "dim" (Task 5's draw), Enter on it emits nothing, `line == WorldMap.NO_NIGHT`.
  - `_conquered_seal`: aldermere 220 -> `spot_state == "conquered"`, `info_lines` contains "Conquered".
  - `_window_sizes`: at 1280x720, 1920x1080, 2560x1080, 1024x768 (`UiScale.set_test_area`): `back_rect()` inside the backdrop,
    a click at each town's spot centre selects it, `back_rect()` and `descend_rect()` do not intersect any spot rect.
- [ ] **Step 2:** Update `tests/test_hub_status.gd` `_blocked` (descend now emits "descend"; the blocked line stays) and
  `tests/test_god_chamber.gd` `_blocked` (the table click and Enter emit "descend"; not dim) and add `_table_opens_map`
  (the table's action is "descend"; with transitions on, `setup(..., "descend")` starts at `ZOOM_TO`). Add to
  `tests/test_god_night.gd` `_conquer_bonus`: aldermere at 220 -> a banked ordinary night pays `earned + fill + 5`;
  `_draw_town`: `draw(slot) == draw(slot, "aldermere")` for nights 0..30 and seeds 1..20; `draw(slot, "capital") == ""`.
  Add `test_world_map.gd` to `tests/run_all.gd`.
- [ ] **Step 3:** Run; expect the parse failure and the changed checks failing.
- [ ] **Step 4:** Implement the two classes, the routes and `Game` changes, the bonus, FLOW and the probe. `--import`.
- [ ] **Step 5:** `--only=test_world_map`, `test_god_chamber`, `test_hub_status`, `test_god_night`: 0 failures.
- [ ] **Step 6:** Headless FLOW alone: only the 3 known music failures; the new count printed (note it in the commit body).
- [ ] **Step 7:** A look: `timeout 300 $G --path . --scene res://scenes/game.tscn -- --show=world --capture --window=1280x720`
  (the photograph path as the `--show=hub` ones); read the PNG: six spots, names readable, no text overlapping. Windowed
  probe on test saves only: `powershell -ExecutionPolicy Bypass -File tools/dev/real_path.ps1 -Out <scratch dir> -Size max
  -Mode route -Route god`; `probe.log` has no `CHECK` line other than `CHECK ok`.
- [ ] **Step 8:** Commit: `feat: the World Map between the Chamber and Prepare: six spots, the Capital opens at 60%, conquered towns pay Faith`.

### Task 6: Capital nights (town-aware draw and banking, wishes switched on)

**Files:**
- Modify: `src/game/god/god_night.gd`, `src/game/mission.gd`, `src/game/town/city_def.gd`,
  `src/game/town/cities/aldermere_city.gd`, `src/game/town/cities/capital_city.gd`, `src/game/game.gd`,
  `tests/test_god_night.gd`, `tests/test_mission_book.gd` (or `tests/test_city.gd`), `tests/test_world_map.gd`
- Create: `tests/test_capital_god_night.gd`; Modify: `tests/run_all.gd`

**Interfaces:**
- Produces on `CityDef`: `func wishes() -> bool: return false`; `AldermereCity.wishes()` and `CapitalCity.wishes()` return true.
- Produces on `Mission`: `static func has_descent(def: MissionDef, on_board: bool, any_town := false) -> bool`: today's rule,
  or `on_board and (TierBook.has(def.id) or HuntBook.has(def.id)) and any_town and City.has(def.city) and
  City.by_id(def.city).wishes()`. `start()` passes `god_night`.
- Produces on `GodNight`:
  - `static func can_host(town: String, id: String) -> bool`: "aldermere" hosts every tier mission (no `Places` call, so its
    draw is untouched); another town: `MissionBook.hostable(id, City.by_id(StringName(town)))`; a Hunt only in "aldermere"
    (Plan note 9)
  - `draw(slot, town := "aldermere")`: the Hunt when due and `can_host(town, hunt.id)`, else `""` while due; otherwise
    today's pool filtered by `can_host(town, id)` (no filter for Aldermere: same list, same order, same RNG), the no-repeat
    fallback over the hostable ones; `""` when none is hostable
  - `def_for(slot, id, town := "aldermere")`: as today, then `MissionBook.in_city(def, StringName(town))` when `town` is not the
    def's own city (rites ignore `town`)
- Produces on `Game`: PREPARE and `_build_mission` call `GodNight.def_for(god, mission_id, night_town)`; `bank_god_night`
  unchanged (the town rides in `outcome.conquest.town`).
- Produces on `WorldMap`: "dim" now comes from the real `GodNight.draw(slot, id) == ""`.

- [ ] **Step 1:** Write `tests/test_capital_god_night.gd`:
  - `_draw_hostable`: for tiers 1-5 and nights 0..20, `draw(slot, "capital")` is "" or an id with
    `MissionBook.hostable(id, CapitalCity.new())` true; `draw(slot, "aldermere")` equals today's (keep a copy of the old pool
    logic in the test as the oracle).
  - `_draw_none`: a tier whose missions the Capital hosts none of (pick by `MissionBook.town_missions(&"capital")`; if every
    tier hosts one, a registered fixture city with no overrides) -> "".
  - `_hunt_aldermere_only`: notice 100 -> `draw(slot, "aldermere")` is the Hunt id, `draw(slot, "capital") == ""`.
  - `_def_in_capital`: `def_for(slot, id, "capital").city == &"capital"`, slots/Might/pool are the god's; the same id with
    "aldermere" is today's def (`city == &"aldermere"`).
  - `_has_descent`: Capital def: `has_descent(def, true)` false (DEV tab unchanged), `has_descent(def, true, true)` true,
    `has_descent(def, false, true)` false; Aldermere unchanged in all three.
  - `_capital_wishes`: a Capital world (fixture as `tests/test_capital_lamb.gd`) with a Descent for tiers 1-5, wish seeds 1..5:
    every heard wish's `people()` are living citizens of the crowd and its `places()` are structures of that town; no error is
    logged.
  - `_capital_bank`: a Capital outcome with `conquest.town == "capital"` banks into `believers.capital`, not aldermere; the
    night counts, Faith and DP are paid, `last_mission` is the base id; `MissionBook.is_dev(id)` false.
- [ ] **Step 2:** Update `tests/test_world_map.gd` `_dim_town`: with the Capital open at a tier it hosts, `spot_state ==
  "open"` and Enter emits "descend"; at a tier it hosts none of, "dim" and `NO_NIGHT`. Add the suite to `tests/run_all.gd`.
- [ ] **Step 3:** Run; expect failures.
- [ ] **Step 4:** Implement. If a wish's `choose()` reads Aldermere-only data in the Capital, make it return false there
  (the wish is then not offered: spec 4.6), never special-case the Capital in `WishBook`.
- [ ] **Step 5:** `--only=test_capital_god_night`, `test_god_night`, `test_world_map`, `test_mission_book`, `test_city`,
  `test_descent`: 0 failures. `refs_check.sh`: `refs ok=508 bad=0`. Headless FLOW: only the 3 known music failures; FLOW's
  `_flow_world` Capital step now expects PREPARE when the tier is hosted (update it in this task).
- [ ] **Step 6:** Commit: `feat: god nights in the Capital: town-aware draw and banking, wishes switched on`.

### Task 7: The user's play test

- [ ] **Step 1:** Tell the user how to reach it (`--dev`, title, ENDLESS, a slot, the World Table) and what to try: several
  Aldermere nights (the percent grows), B during a night (marks and the aim count), killing believers (lost on the results),
  the Capital at 60% (a `--dev` fixture or a hand-edited test slot), a Capital night, Esc and Enter on the map, the four window
  shapes.
- [ ] **Step 2:** Tune only the numbers they ask for: `Conquest.FILL_CAUGHT` (3), `FILL_CLEAN` (6), `UNLOCK_PERCENT` (60),
  `CONQUER_FAITH` (5); Capital mission tuning lives in the Capital's overrides files. After each round rerun
  `--only=test_conquest`, `test_believer_roll`, `test_god_night`, `test_world_map`, `test_capital_god_night` and commit with
  `tune: <what changed and why>`.
