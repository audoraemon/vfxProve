# KAK Town Suspicion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The town keeps a suspicion value; deaths a natural-looking power explains no longer send the bellkeeper until the town believes a god is at work.

**Architecture:** A pure `Suspicion` object owned by `Crowd` beside `alarms`. `Crowd` feeds it one sign per witnessed cast and marks each incident explained or not; `AlarmManager` keeps a second, unexplained tally per district; the keeper is sent by one function, `Crowd.keeper_due()`. The HUD reads the object; nothing after the bell changes.

**Tech Stack:** Godot 4.7.2, GDScript. Tests are `tests/test_*.gd` suites run by `tests/run_part.gd`.

**Spec:** `docs/superpowers/specs/2026-11-20-kak-town-suspicion-design.md` (approved 2026-11-20). Read it first; this plan does not repeat its reasons.

## Global Constraints

- **Delay only.** The new rule may send the bellkeeper later than today, never sooner. A run with no natural-looking power behaves exactly as today.
- **No randomness.** `Suspicion` and every new line in `crowd.gd` use no random stream (`_rng`, `randf`, `randi`). The same run gives the same checksum twice.
- **Which reference rows may move:** only a run that, on the base, called the keeper at a district emergency made of explained incidents, or at a witnessed target kill of an explained kind, before the town would know. Tasks 1-3 and 6-8 must move no row at all.
- Shared files (`crowd.gd`, `hud.gd`, `mission.gd`, `alarm_manager.gd`, `power_book.gd`): hooks only, smallest diff.
- Numbers (spec 5.2, 5.3, 9), all constants of `Suspicion` unless said: `UNEASY_AT` 40, `KNOWN_AT` 100, `MEMORY` 60 s, `CALM_DELAY` 15 s, `FADE` 0.4/s, `OTHER_LOOKS` 0.5, `TARGET_SIGN` 40, `QUIET_SIGN_SIGHT` 5.0; bases lightning 20, fire 20, storm 25, quake 30, flood 30, miasma 30; `ResponseProfile.wary` Unprepared 0.8, Unaware 1.0, Organized 1.0, Prepared 1.25, God-Resistant 1.5.
- Looks (spec 5.2): `smite` lightning; `ember` fire; `tornado`, `tempest` storm; `shatter` quake; `tsunami` flood; `breath` miasma; `disorder` none. Every other loud power unnatural, every other quiet power none.
- Excuse rule (Ruling R7): a natural-looking cast (smite, ember, tornado, tempest, shatter, tsunami, breath) excuses its kinds of death (`EXCUSES`: lightning, fire, storm = wind + lightning, quake = pit, flood = water, miasma = choke) and collapses for `EXCUSE_SECONDS` 90 s from the cast, witnessed or not; a death is explained only while its kind is excused and the town does not know. With no natural cast in the run nothing is explained and the keeper is sent as on the base.
- Project style: tests first; a `##` doc comment on every new member; no commented-out code; a new suite is registered in `tests/run_all.gd` SUITES; test files write only `user://test_*`; no new audio files; no PixelLab.
- Commits end with `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`.

Commands (from the worktree root; `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`):
- Import after a new `class_name` or test file: `timeout 900 $G --headless --editor --path . --import >/dev/null 2>&1`
- One suite: `$G --headless --path . -s res://tests/run_part.gd -- --only=test_x` (last line ends `failures=0`)
- References: `bash tools/dev/refs_check.sh --only='<regex>' --jobs=3` (last line `refs ok=K bad=0`)

## Review Focus

1. **A cast that lands on many points or renews its danger** (Tsunami's lane, a Tornado still spinning, Wrath of the Sky's bolts through `Crowd.fright()`): the town counts one sign per cast, not one per point, bolt or renewal. Test in Task 3.
2. **Follow-up clicks of one cast** (`Rules.recast`, Smite's Gathered Storm): one use of the ability is one sign. Test in Task 3.
3. **A restart or a new act**: R restart and `Crowd.clear()` put the value at 0, forget the signs, unlatch `known` and the keeper latch; `Mission.next_act()` keeps all four (the crowd outlives the act). Test in Tasks 3 and 4.
4. **The Bell Lies after the town knows** (`Crowd.unring_bell()`): the keeper tries again as today; the new latch must not hold him back, and `known` stays. Test in Task 4.
5. **A town with no bell** (Unprepared), a dead keeper, and a keeper held by the Herald (`keeper_held`): `keeper_due()` never crashes and never calls twice. Test in Task 4.
6. **The gauge on a crowded top line**: TAB expanded, a Lantern night's clock badge, 640x360. Nothing overlaps. Test in Task 6.

## File Structure

| File | Change |
|---|---|
| `src/game/crowd/suspicion.gd` | new: the value, the memory, the latch, the arithmetic |
| `src/game/power_book.gd` | `"look"` on eight rows; `PowerBook.look()` |
| `src/game/response_profile.gd` | `wary` |
| `src/game/crowd/alarm_manager.gd` | the unexplained tally |
| `src/game/crowd/crowd.gd` | owns `suspicion`; signs; ways to know; explained incidents; `keeper_due()`; thought tags |
| `src/game/mission/ringer_director.gd`, `assassinate_director.gd` | the keeper's condition; the target sign |
| `src/game/ui/hud.gd`, `legend_panel.gd`, `behaviour_overlay.gd`, `src/game/mission.gd` | gauge, tags, banners, legend, overlay |
| `src/game/mission/mission_hints.gd`, `relic_run_director.gd`, `sermon_director.gd` | corrected copy |
| `src/game/game.gd` | two photographs |
| `tests/test_suspicion.gd`, `tests/test_suspicion_town.gd` | new suites |
| `tools/dev/refs/*.tsv` | moved rows re-recorded (Task 9) |

---

### Task 1: `Suspicion`

**Files:** Create `src/game/crowd/suspicion.gd`, `tests/test_suspicion.gd`; modify `tests/run_all.gd`.

**Interfaces — Produces:**
```gdscript
class_name Suspicion
extends RefCounted
signal changed                      ## the value or the state moved
signal uneasy                       ## the value passed UNEASY_AT on its way up (once per rise)
signal became_known(reason: String) ## once
const UNNATURAL := &"unnatural"
const NONE := &""
const BASE := {&"lightning": 20.0, &"fire": 20.0, &"storm": 25.0, &"quake": 30.0, &"flood": 30.0, &"miasma": 30.0}
const EXCUSES := {&"lightning": [&"lightning"], &"fire": [&"fire"], &"storm": [&"wind", &"lightning"], &"quake": [&"pit"], &"flood": [&"water"], &"miasma": [&"choke"]}
const EXCUSE_SECONDS := 90.0
var value := 0.0
var known := false
var reason := ""        ## why the town knows; "" until it does
var wary := 1.0
func sign(look: StringName) -> float   ## one witnessed cast; returns what it added (0 for NONE; UNNATURAL knows at once)
func add(points: float) -> void        ## a flat rise (x wary), no memory entry; knows at KNOWN_AT
func know(why: String) -> void         ## latch; value = 100; first reason wins
func advance(delta: float) -> void     ## clock, memory, fade
func state() -> StringName             ## &"calm", &"uneasy" (value >= UNEASY_AT), &"known"
func recent() -> Array                 ## [[look, seconds ago]] newest last, for the overlay
func excuse(look: StringName) -> void  ## a cast of a natural look excuses its kinds (and collapse) for EXCUSE_SECONDS
func explains(kind: StringName) -> bool  ## not known and kind excused now
func reset() -> void
```
`added = BASE[look] * (1 + same) * (1 + OTHER_LOOKS * others) * wary`, `same` = signs of that look in memory, `others` = distinct other looks in memory. The fade starts `CALM_DELAY` after the last sign or `add`; a known town does not fade.

- [ ] **Step 1: failing tests** in `tests/test_suspicion.gd` (`t.near(a, b, 0.01, msg)`); each case advances with `advance()` in 0.1 s steps:
  - one `sign(&"lightning")` -> 20, `state()` calm.
  - lightning at 0 s and 30 s -> 54, uneasy, `uneasy` emitted once.
  - lightning at 0, 30, 59 s -> `known`, `value` 100, `became_known` once, reason non-empty; the third `sign()` returned 60.
  - lightning every 61 s, five times -> values just after each: 20, 21.6, 23.2, 24.8, 26.4; never uneasy.
  - lightning 0 s, storm 10 s, quake 20 s -> 20, 57.5, then known.
  - `wary` 1.5: one lightning -> 30. `wary` 0.8 -> 16.
  - `sign(Suspicion.NONE)` -> returns 0, value unchanged, `recent()` empty, the fade's delay not restarted.
  - `sign(Suspicion.UNNATURAL)` -> known at once, reason "an unnatural power".
  - `add(40)` after one lightning -> 60, `recent().size()` 1; `add(40)` twice more -> known.
  - fade: value 54 untouched for 15 s, then 0.4/s, never below 0; `uneasy` fires again after falling under 40 and rising past it.
  - known: 300 s of `advance` leave value 100 and `known` true; `know("x")` again keeps the first reason.
  - `explains(&"lightning")` true, `explains(&"plague")` false, `explains(&"doom")` false, any kind false once known.
  - `reset()` -> 0, not known, reason "", `recent()` empty.
- [ ] **Step 2:** import, run `--only=test_suspicion`: fails (class missing).
- [ ] **Step 3:** implement `Suspicion`.
- [ ] **Step 4:** run again: `failures=0`.
- [ ] **Step 5:** commit `feat: Suspicion, the town's doubt about what it sees`.

### Task 2: Looks and wariness

**Files:** Modify `src/game/power_book.gd`, `src/game/response_profile.gd`; tests in `tests/test_suspicion.gd` (looks) and `tests/test_profile.gd` (wary).

**Interfaces — Produces:** `static func look(key: String) -> StringName` in `PowerBook`: the row's `"look"` (the word `"none"` reads as `Suspicion.NONE`); with no field, `Suspicion.NONE` for a quiet power or an unknown key (`""`, the sandbox's and scripted tests' cast), `Suspicion.UNNATURAL` for a loud one. `var wary := 1.0` in `ResponseProfile`, set in `for_tier()` per Global Constraints (`unaware()` 1.0).

- [ ] **Step 1: failing tests:** `look()` of the eight keys of Global Constraints; over every key of the book: exactly 7 keys have a look in `Suspicion.BASE` (smite, ember, tornado, tempest, shatter, tsunami, breath), exactly 29 are unnatural and all 29 are loud, `PowerBook.look("")` is NONE; `wary` of the five profiles.
- [ ] **Step 2-4:** run red, implement, run green (`--only=test_suspicion`, `--only=test_profile`).
- [ ] **Step 5:** commit `feat: every power has a look; readier towns are warier`.

### Task 3: The crowd reads the signs

**Files:** Modify `src/game/crowd/crowd.gd`; create `tests/test_suspicion_town.gd` (build the crowd the way `tests/test_alarm.gd` does); modify `tests/run_all.gd`.

**Interfaces — Consumes:** Tasks 1, 2. **Produces (in `Crowd`):**
```gdscript
var suspicion := Suspicion.new()
## A cast of `key` was seen by `witness`: the town's state before and after it (Suspicion.state()).
signal sign_seen(witness: Person, look: StringName, before: StringName, after: StringName)
## The nearest living person, citizen or soldier, not inside and not asleep, within `sight` x sight_scale of any of `points`; null in a hushed town.
func sign_witness(points: Array[Vector2], sight: float) -> Person
```
Wiring:
- `suspicion.wary` follows the profile (where the profile is set and in `raise_profile()`); `suspicion.advance(delta)` runs with the crowd's clock; `clear()` and a restart call `suspicion.reset()`.
- `_land(key, points, radius, reach, ground)`: if `PowerBook.look(key)` is not NONE and `sign_witness(points, reach[0])` finds someone, `suspicion.sign(look)` then `sign_seen`. Once per cast.
- `on_cast()` quiet branch: the same with `[ground]` and `Suspicion.QUIET_SIGN_SIGHT` (only Ember has a look there).
- A follow-up click of the same cast (`Rules.recast`) is no new sign; find how a follow-up reaches `on_cast` and keep it out (say how in the report).
- The town knows (`suspicion.know(...)`): in `ring_bell()` "the bell rings"; on a hit on the Citadel (`_on_citadel_health`, where it rallies) "the Citadel is struck"; in `_on_stage(CITY_EMERGENCY)` "the town is in emergency".

- [ ] **Step 1: failing tests** (`tests/test_suspicion_town.gd`), each on a fresh crowd, casting through `crowd.on_cast(...)` and advancing past `PowerBook.impact(key)`:
  - Smite with a citizen 3 units away -> value 20, `sign_seen` once with that citizen, before and after `calm`.
  - Smite with nobody within 5 units -> 0. The only person in reach inside a building -> 0; asleep -> 0; a soldier at 3 units -> 20.
  - `sight_scale` 0.6, witness at 4 units -> 0; at 2.5 units -> 20.
  - Hushed town -> 0. Cast under the Unseen Hour -> 0.
  - Dragonfire witnessed -> known, reason "an unnatural power". Unwitnessed -> not known.
  - Ember with a witness at 4 units -> 20; at 6 units -> 0. Mind Whisper witnessed -> 0.
  - Tsunami along a lane past three witnesses -> one sign (30).
  - `crowd.fright(...)` of kind `lightning` near a witness (what Wrath of the Sky's bolts call) -> no sign.
  - Smite cast, then its follow-up click -> one sign.
  - `ring_bell()` -> known; a Citadel hit -> known; forcing the stage to City Emergency -> known.
  - `clear()` -> value 0, not known. (`next_act` keeps them: asserted in Task 4's route test.)
  - Determinism: the test's crowd `_rng` state is the same after a witnessed Smite with the suspicion wired as with `PowerBook.look` forced to NONE (no draw is made by the new code).
- [ ] **Step 2-4:** red, implement, green; also `--only=test_alarm`, `--only=test_awareness`, `--only=test_crowd`, `--only=test_quiet` green.
- [ ] **Step 5:** `bash tools/dev/refs_check.sh --only='^(warning|tax|escalate|bell|quiet|powers)' --jobs=3`: `bad=0` (no row may move yet).
- [ ] **Step 6:** commit `feat: the crowd counts the signs it sees`.

### Task 4: Explained deaths and the keeper's call

**Files:** Modify `src/game/crowd/alarm_manager.gd`, `src/game/crowd/crowd.gd`, `src/game/mission/ringer_director.gd`; tests in `tests/test_alarm.gd`, `tests/test_bell.gd`, `tests/test_suspicion_town.gd`.

**Interfaces — Produces:**
```gdscript
# AlarmManager
func incident(g: Vector2, explained := false) -> bool   ## return value unchanged: true when the district just reached LOCAL_EVENTS of all incidents
func unexplained_emergency() -> bool                     ## some district holds LOCAL_EVENTS unexplained incidents
# Crowd
func keeper_due() -> bool   ## bell != null and alarms.stage >= LOCAL_EMERGENCY and (suspicion.known or alarms.unexplained_emergency())
```
Wiring in `Crowd`: `_on_killed` passes `suspicion.explains(kind)`; `_on_structure_destroyed` passes `suspicion.explains(&"collapse")`; `_settle_doom` passes false. `_on_stage(LOCAL_EMERGENCY)` no longer calls the keeper. One private function sends him when `keeper_due()` and he has not been sent by it before (a latch, reset in `clear()`); it runs after every incident, at every stage change and on `suspicion.became_known`. `RingerDirector` (ringer_director.gd:224) tests `crowd.keeper_due()` where it tests the stage.

- [ ] **Step 1: failing tests:**
  - Four `lightning` deaths in one district: stage Local Emergency, the two investigators sent, `bell.state` IDLE, `keeper_due()` false.
  - Then `suspicion.know("x")`: the keeper is called (state leaves IDLE).
  - Four `plague` deaths in one district, no sign ever: the keeper is called at the fourth, as today.
  - Three `lightning` and one `plague` in a district: not called. Three more `plague` there (four unexplained): called.
  - Four collapses in a district, town not knowing: not called; knowing: called.
  - Four witnessed dooms in a district (`_settle_doom`): called, as today.
  - Alarm value pushed to `CITY_ALARM` with no district emergency: City Emergency -> known -> called.
  - Called once: a second district's emergency and a second `know()` do not call again (count `bell.climbing_started` or wrap the call).
  - After the town knows, `unring_bell()` (The Bell Lies): the bell's own retry still sends the keeper (assert as `tests/test_bell.gd` asserts it today); `known` stays true.
  - Unprepared town (`bell == null`): `keeper_due()` false, four plague deaths raise no error. A dead keeper and a held keeper (`keeper_held`): no error, `call_keeper()` behaves as today.
  - A real `Mission` on `long_night` (as `tests/test_descent.gd` hosts one): a sign and `know()` in Act I survive `next_act()`; an R restart resets them.
- [ ] **Step 2-4:** red, implement, green; plus `--only=test_warning`, `--only=test_bell_ringers`, `--only=test_starfall`, `--only=test_lantern` green (fix a test only where it asserts the old call with explained deaths; list each).
- [ ] **Step 5:** `bash tools/dev/refs_check.sh --only='^(warning|tax|escalate|bell|ringers|quiet)' --jobs=3`; list every MISMATCH row in the report with the scenario and why the keeper's call moved. Do not re-record.
- [ ] **Step 6:** commit `feat: deaths an accident explains do not send the bellkeeper`.

### Task 5: Watched targets

**Files:** Modify `src/game/mission/assassinate_director.gd`; tests in the suites of its four users (`tests/test_tax_collector.gd` and the informer's, bishop's and inquisitor's suites; find them by `AssassinateDirector` / the director names).

**Interfaces — Consumes:** `crowd.suspicion.explains(kind)`, `.add(Suspicion.TARGET_SIGN)`, `.known`. The quarry remembers the kind it died of (spec 8: the builder chooses how `_judge` learns it).

Rule in `_judge(q)`: unseen -> as today. Seen: the banner and the sound as today; then, if `explains(kind)`: `add(TARGET_SIGN)` and call the keeper only if the town knows after it; else call the keeper as today.

- [ ] **Step 1: failing tests** (tax collector's suite; one seen-kill case each in the other three):
  - Collector killed by Smite with a witness in `DOOM_WITNESS`: `q.unseen` false, the seen banner emitted, suspicion 60 (20 + 40), `bell.state` IDLE.
  - A second collector killed the same way 20 s later: the town knows, the keeper is called.
  - Collector killed by Silent Doom, seen: keeper called at once, suspicion unchanged.
  - Collector killed by Smite unseen: no banner, suspicion as the cast alone left it.
  - Town already knowing, a seen Smite kill: keeper called at once.
- [ ] **Step 2-4:** red, implement, green.
- [ ] **Step 5:** `refs_check --only='^(tax|informer|bishop|god_.*_tax|expel|silence)'`; list MISMATCH rows with reasons; do not re-record.
- [ ] **Step 6:** commit `feat: a target struck by lightning in plain sight is an accident, once`.

### Task 6: The gauge, the banners, the legend, the overlay

**Files:** Modify `src/game/ui/hud.gd`, `src/game/ui/legend_panel.gd`, `src/game/ui/behaviour_overlay.gd`, `src/game/mission.gd` (`_wire_responses()`), `src/game/game.gd`; tests in `tests/test_hud.gd`.

**Interfaces — Produces (in `Hud`):** `func suspicion_shown() -> bool` (value > 0 or known), `func suspicion_rect() -> Rect2` (the bar, HUD units), `func suspicion_word() -> String` (`Calm`, `Uneasy`, `A GOD!`).

- The bar: about 48 x 5 units, a tick at 40 %, fill `COL_DIM` when calm, `COL_GOLD` when uneasy, `COL_BAD` when known, the word beside it in `TEXT_S`, on a `COL_PANEL` plate, left of the status plate (`status_rect()`); when there is no room there (TAB expanded, 640x360), directly under the status plate. `_signature()` includes `int(value)` and `state()`.
- Banners (`Mission._wire_responses()`): `suspicion.uneasy` -> quiet banner `THE TOWN GROWS UNEASY`; `suspicion.became_known` -> `THE TOWN KNOWS: A GOD IS HERE`.
- Legend: one entry `["suspicion", ..., "How strange the town finds this night. Full: it calls a god's hand, and the bell"]` after the `topline` entry, with a small bar swatch.
- Overlay: one line `Suspicion: 57 (uneasy)  signs: lightning 12s, lightning 42s` or `... (known: the bell rings)`.
- Photographs in `game.gd` beside the existing `--show=` cases: `--show=suspicion-uneasy` (a board Warning, two Smites seen, value near 54) and `--show=suspicion-known`.

- [ ] **Step 1: failing tests:** hidden at value 0; shown at 20 with `Calm`; `Uneasy` at 54; `A GOD!` when known; `suspicion_rect()` intersects neither `status_rect()` nor the clock's plate at 640x360, 1280x720 and 1920x1080, TAB collapsed and expanded, with and without a Lantern; the signature differs between values 20 and 21 and between uneasy and known; each banner is pushed once per signal.
- [ ] **Step 2-4:** red, implement, green (`--only=test_hud`, `--only=test_legend`).
- [ ] **Step 5:** capture both photographs at 1280x720 and 1920x1080 with `tools/capture.sh --show=... --capture --window=WxH` into `.sdd/shots/`; look at each: bar and word readable, nothing overlapped.
- [ ] **Step 6:** commit `feat: the town's suspicion on the HUD`.

### Task 7: The town's thought

**Files:** Modify `src/game/crowd/crowd.gd`, `src/game/ui/hud.gd` (`all_tags()`); tests in `tests/test_suspicion_town.gd`, `tests/test_hud.gd`.

**Interfaces — Consumes:** `Crowd.sign_seen`. **Produces:** `func thought_tags() -> Array[MapTag]` in `Crowd` (at most one: the newest sign's witness, for `THOUGHT_SECONDS` 2.5, built with `MapTag.person(witness, color, text, false)`); `Hud.all_tags()` appends it after the Lantern's tags and before the descent's.

Text by the state after the sign: calm -> by look: lightning and storm `JUST A STORM`, fire `FIRE!`, quake `EARTHQUAKE!`, flood `THE RIVER!`, miasma `BAD AIR`; uneasy -> `AGAIN?`; known -> `THIS IS NO ACCIDENT`. When the state after is uneasy and the state before was calm, the witness also voices `cit_shout` through `Crowd._voice()`.

- [ ] **Step 1: failing tests:** each of the eight texts; the tag gone after 2.5 s; gone when the witness dies; a second sign replaces the first; `all_tags()` contains it; a known-by-unnatural sign shows `THIS IS NO ACCIDENT`; no tag for an unwitnessed cast.
- [ ] **Step 2-4:** red, implement, green; `--only=test_tag_on_person`, `--only=test_tag_outlines` green.
- [ ] **Step 5:** commit `feat: a witness says what the town thinks`.

### Task 8: Copy that teaches the old rule

**Files:** Modify `src/game/mission/mission_hints.gd`, `src/game/mission/relic_run_director.gd`, `src/game/mission/sermon_director.gd`; tests `tests/test_mission_hints.gd`.

Exact copy:
- `mission_hints.gd` `"tax_collector"`: last sentence becomes `A seen kill that is plainly no accident rings the bell.`
- `mission_hints.gd` `"relic_run.seen"`: `A death was seen: the Gaze rises. Four deaths in a district that no accident explains call the bell: +40 Gaze, and the Lantern turns.`
- `relic_run_director.gd:853` and `sermon_director.gd:815`: the sentence `Four seen deaths in a district call the bell.` becomes `Four deaths in a district that no accident explains call the bell.`

- [ ] **Step 1:** grep `src/game` for other player-facing strings that state when the bell is called (`bell`, `bellkeeper`); list each in the report as changed or still true.
- [ ] **Step 2:** edit; run `--only=test_mission_hints`, `--only=test_mission_steps`, and the suites that check text fit for tours (grep `tour` in `tests/`): green. A line that no longer fits its box is shortened and reported.
- [ ] **Step 3:** commit `docs: hints say when the bell is called now`.

### Task 9: References, gates and bots (controller)

- [ ] **Step 1:** `bash tools/dev/refs_check.sh --jobs=4` (all rows). For each MISMATCH: confirm it is a run of the kind Global Constraints allows (its log on the base shows the keeper called at a district emergency of explained deaths or at a seen target kill by an explained kind). Any other mover is a bug: fix before going on.
- [ ] **Step 2:** For every scenario with a moved row, run its gate here and on the base (a detached worktree at the branch's merge-base): `bash tools/dev/gate.sh <scenario> ...` / `tools/dev/god_gate.sh --only=<mission>` / `tools/dev/hunt_gate.sh --only=<hunt> --type=<type>`. Pass bar: no pair worse than its base row. A worse pair: fix the bot's policy first; then tune per spec 9 (`wary`, then the bases), one change at a time, and record each number changed.
- [ ] **Step 3:** re-record the moved rows; `refs_check` all rows: `bad=0`.
- [ ] **Step 4:** `bash tools/dev/run_suite_parallel.sh 6` (a part with NO RESULT is rerun alone with a 5400 s timeout): `failures=0`, bar the known load-flaky frame-time check.
- [ ] **Step 5:** commit `test: references re-recorded where the bellkeeper now waits` (and a separate `tune:` commit naming old and new values for any number changed).

### Task 10: Review and land (controller)

- [ ] Whole-branch review by a fresh reviewer (opus) against the spec and Global Constraints; one fix wave; re-review of the fixes.
- [ ] `git fetch`; merge `origin/feat/Develop-Main` (the Might gauge will have landed: `hud.gd`, `mission.gd` overlap) and resolve; import; `bash tools/dev/land.sh` (suite, all references, FLOW on a quiet machine).
- [ ] Fast-forward `feat/Develop-Main`, push. Dev Ledger: idea done, task entry, board refresh. Discord #ideas post 1573203747956588564: OPEN -> DONE, close.
- [ ] Report to the user: what landed, every number that differs from the spec, the rows that moved and why, every ruling.
