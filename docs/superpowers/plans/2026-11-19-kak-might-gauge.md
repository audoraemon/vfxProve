# KAK Might Gauge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** In Endless Night a god brings every learned ability into the night, limited by a Might gauge that drops on cast and refills, with a new hideable ability bar.

**Architecture:** `Rules` gets an optional `MightPool` (null = today's behaviour). `GodNight` marks a god's def as a gauge night; `Mission` builds the pool into each act's `Rules`. A new `AbilityBar` replaces the HUD's slot row only when the pool is on. Board, campaign and Remembrance never get a pool.

**Tech Stack:** Godot 4.7.2, GDScript. Tests are `extends RefCounted` suites with `static func run(t)` listed in `tests/run_all.gd`.

**Spec:** `docs/superpowers/specs/2026-11-19-kak-might-gauge-design.md` (mockup: `docs/superpowers/specs/assets/2026-11-19-might-gauge-bar-mockup.html`). Read both before any task.

## Global Constraints

- Work only in the worktree `C:\BURIN_NITRO\Godot\GIT\vfxProve\.claude\worktrees\might-gauge` (branch `feat/might-gauge`). Never push; never touch another worktree.
- Godot: `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`. After adding a `class_name`, run `$G --headless --path . --import` once before any headless run.
- One suite: `$G --headless --path . -s res://tests/run_part.gd -- --only=test_x`. Expected last line: `... failures=0`.
- Never stop, kill or close a process you did not launch. Scripted windowed runs use `user://test_*` files only.
- With `Rules.might == null` and `Rules.sealed == ""`, every code path in `rules.gd`, `hud.gd` and `mission.gd` must behave exactly as before this branch. The 304 reference rows without `--god` must stay byte-identical.
- Shared files (`rules.gd`, `hud.gd`, `mission.gd`, `game.gd`, `prepare_screen.gd`) get hooks only; new behaviour lives in the new files.
- Project style: a `##` doc comment on every new member; statics where a suite can prove them; no new `class_name` without a test.
- Exact numbers: base refill `60.0` s, Faith step `5.0` s, floor `30.0` s; gauge size = `GodSlot.max_might()`; cost = `PowerBook.might(key, level)`.
- Exact copy: banners `NOT ENOUGH MIGHT` and `SEALED BY THE LANTERN`; Faith row name `FASTER MIGHT`; strip hint `Ctrl: abilities`; button `DESCEND`.
- New keys in a gauge night: both Ctrl keys toggle the bar, `Z` / `X` turn the page, `1`..`9`,`0` arm tiles 1..10 of the current page.
- Commits end with `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`.

## Review Focus

1. A god whose night has no castable ability (`GodNight.NO_POWERS`, or one page with only the sealed key): the bar has zero or one page, nothing crashes, the strip shows the gauge only.
2. Window resized or UI scale changed while the bar is shown: every tile, tab and the strip stay inside the view at 640x360 logical units with ten tiles, and `slots_rect()` follows.
3. Ctrl, Z, X or 7-0 pressed while the legend is open, during the intro, or with the interface hidden (`ui_hidden`): no toggle under the legend or intro; with the interface hidden the key first brings it back, as slot keys do today.
4. An ability armed on one page, then the page turned: the armed ability stays armed and castable, the strip still shows it, and a number key arms from the new page.
5. An old god file (`bought.slot = 3`, a six-key `loadout`, a sealed key): reads without error, `refill_seconds()` is 45, the sealed key is on the bar locked, the old `loadout` is ignored.

---

## File Structure

| File | Responsibility |
|---|---|
| Create `src/game/might_pool.gd` | The gauge's numbers and arithmetic. |
| Create `src/game/ui/ability_bar.gd` | The strip and the bar: pages, key mapping, rectangles, hit-testing, drawing. |
| Create `tests/test_might_pool.gd`, `tests/test_rules_might.gd`, `tests/test_ability_bar.gd`, `tests/test_might_night.gd` | New suites (new files, so shared test files conflict less). |
| Modify `src/game/rules.gd` | Pool, seal, cast-keys hooks. |
| Modify `src/game/mission/mission_def.gd`, `src/game/god/god_night.gd`, `src/game/god/god_slot.gd`, `src/game/ui/faith_screen.gd` | Gauge fields on the def, the god's numbers, the Faith row. |
| Modify `src/game/mission.gd`, `src/game/ui/hud.gd` | Wire the pool and the bar. |
| Modify `src/game/ui/prepare_screen.gd`, `src/game/game.gd` | The read-only briefing and the no-draft flow. |
| Modify `tools/dev/behaviour_check.gd` | Bots pay Might. |
| Modify `tests/run_all.gd` and the god suites named per task | Register and update. |

---

### Task 0: Baseline gates on the untouched tree

**Files:** none changed. Output: `C:\BURIN_NITRO\Godot\GIT\vfxProve\.claude\worktrees\might-gauge\.gate-baseline\` (untracked; add `.gate-baseline/` and `.gate-after/` to `.git/info/exclude`, not to `.gitignore`).

- [ ] **Step 1:** `$G --headless --path . --import` (fresh worktree).
- [ ] **Step 2:** Run `bash tools/dev/god_gate.sh --only=<s> --jobs=3 > .gate-baseline/god_<s>.txt 2>&1` for each of `warning tax harvest lamb prayers`, one after another.
- [ ] **Step 3:** For each Hunt of `hide_faithful silence_witness expel_inquisitor break_hunt face_halcyon` and each type of `ruin death veil passage decree dominion`: `bash tools/dev/hunt_gate.sh --only=<hunt> --type=<type> --save=.gate-baseline --jobs=3` (`--with-none` on `ruin` only). Then `bash tools/dev/hunt_gate.sh --only=<hunt> --judge=.gate-baseline` (`--except=decree` on Hunts 2-4) `> .gate-baseline/hunt_<hunt>.txt`.
- [ ] **Step 4:** Write `.gate-baseline/SUMMARY.txt`: the last line of each file. A pair or Hunt that FAILs here is recorded as "failed before the gauge".

This task runs in the background while Tasks 1-7 are built; it needs no code.

---

### Task 1: MightPool

**Files:** Create `src/game/might_pool.gd`, `tests/test_might_pool.gd`; modify `tests/run_all.gd` (append the suite after `test_god_slot.gd`).

**Interfaces — Produces:**
```gdscript
class_name MightPool
extends RefCounted
const REFILL_SECONDS := 60.0
const REFILL_STEP := 5.0
const REFILL_FLOOR := 30.0
const EPSILON := 0.0001            # can_pay tolerance
var capacity := 0.0
var refill_seconds := REFILL_SECONDS
var value := 0.0
static func make(size: int, seconds := REFILL_SECONDS) -> MightPool   # full; seconds clamped to >= REFILL_FLOOR
static func for_tier(tier: int) -> MightPool                          # TierBook.dp(tier), REFILL_SECONDS
static func for_god(slot: GodSlot) -> MightPool                       # slot.max_might(), slot.refill_seconds()  (Task 3 adds refill_seconds)
static func refill_for(bought: int) -> float                          # maxf(REFILL_SECONDS - REFILL_STEP * bought, REFILL_FLOOR)
func rate() -> float                                                  # capacity / refill_seconds
func advance(delta: float) -> void                                    # value toward capacity
func can_pay(cost: float) -> bool                                     # value + EPSILON >= cost
func pay(cost: float) -> bool                                         # false and unchanged when it cannot
func refill() -> void
func whole() -> int                                                   # floori(value + EPSILON)
```
`for_god` is written in Task 3 (it needs `GodSlot.refill_seconds()`); Task 1 leaves it out.

- [ ] **Step 1: failing tests** in `tests/test_might_pool.gd`:
  - `make(6)`: `value == 6.0`, `rate()` near `0.1`.
  - `make(16).rate()` near `16.0 / 60.0`.
  - `pay(4)` on 6 leaves 2; `pay(3)` then returns false and leaves 2.
  - after `pay(6)`, `advance(30.0)` gives 3.0; `advance(1000.0)` clamps at 6.0.
  - 600 calls of `advance(0.1)` from empty reach `can_pay(6.0) == true` (float drift).
  - `refill_for(0) == 60`, `refill_for(3) == 45`, `refill_for(99) == 30`; `make(6, 10.0).refill_seconds == 30.0`.
  - `for_tier(1).capacity == 6`, `for_tier(5).capacity == 16`.
  - `whole()` is 2 at value 2.99, 3 at 2.99995.
- [ ] **Step 2:** import, run `--only=test_might_pool`, expect failures (class missing).
- [ ] **Step 3:** implement the file to the interface above.
- [ ] **Step 4:** run, expect `failures=0`.
- [ ] **Step 5:** commit `feat: MightPool, the Might gauge's numbers`.

---

### Task 2: Rules pays Might

**Files:** Modify `src/game/rules.gd`; create `tests/test_rules_might.gd`; register in `tests/run_all.gd`.

**Interfaces — Consumes:** `MightPool` (Task 1).
**Produces (on `Rules`):**
```gdscript
var might: MightPool = null          # null: no gauge (board, campaign, Remembrance)
var sealed := ""                     # a PowerBook key that refuses "sealed"; "" for none
var cast_keys := PackedStringArray() # keys cast at least once this act, first-cast order, no repeats
func might_cost(slot: int) -> int    # PowerBook.might(key(slot), level_of(slot)); 0 for an empty slot
```
- `refusal(slot)` order: `"over"`, `"empty"`, `"sealed"`, `"cooldown"`, `"might"`, `"busy"`. `"might"` only when `might != null and not free_play and not might.can_pay(might_cost(slot))`.
- `cast()`: pays at the line that sets `_cooldowns[slot]` (after every refusal return); appends to `cast_keys`; pays nothing under `free_play`.
- `advance(delta)`: `might.advance(delta)` beside the cooldown loop.
- The Divine Surge branch (`_cooldowns.fill(0.0)` in `_on_structure_destroyed`): `might.refill()`.
- `result()` gains `"cast": cast_keys.duplicate()`.
- `recast()` is untouched (free).

- [ ] **Step 1: failing tests** (build `Rules` the way `tests/test_rules.gd` does; use its fixture helpers):
  - no pool: `refusal()` and `cast()` results equal a control `Rules` for the same script of casts; `result().cast` lists the keys cast.
  - pool `make(6)`, loadout of a 2-Might key: three casts (cooldowns zeroed between them) leave 0; the fourth `refusal()` is `"might"`, emits `cast_refused(slot, "might")`, starts no cooldown and leaves the pool unchanged.
  - on cooldown and unaffordable: `refusal()` is `"cooldown"`.
  - a refused whisper (`"nobody"`) pays nothing.
  - `sealed = key`: `refusal()` is `"sealed"` before cooldown; pool unchanged; not in `cast_keys`.
  - `free_play = true` with a pool: cast pays nothing.
  - `advance(30.0)` after emptying a size-6 pool gives 3.0.
  - the surge: pool emptied, the Temple destroyed through the same call `test_rules.gd` uses for the surge, pool full.
  - a live power's `recast()` at 0 Might succeeds and the pool stays 0.
  - `cast_keys` holds a key once after two casts of it.
- [ ] **Step 2:** run `--only=test_rules_might`, expect failures.
- [ ] **Step 3:** implement the hooks.
- [ ] **Step 4:** run `--only=test_rules_might` and `--only=test_rules`, both `failures=0`.
- [ ] **Step 5:** commit `feat: Rules pays Might from an optional pool; sealed refusal; cast keys`.

---

### Task 3: GodSlot and Faith — FASTER MIGHT

**Files:** Modify `src/game/god/god_slot.gd`, `src/game/ui/faith_screen.gd`, `src/game/might_pool.gd` (`for_god`), `tests/test_god_slot.gd`, and the Faith screen's suite (find with `grep -ln "FaithScreen" tests/`).

**Interfaces — Produces:**
```gdscript
# GodSlot.FAITH row 0 becomes (key unchanged on purpose: an older build sharing the file must keep reading it)
{"key": "slot", "name": "FASTER MIGHT", "prices": [150, 300, 450], "limit": 3}
func refill_seconds() -> float       # MightPool.refill_for(int(bought.get("slot", 0)))
```
- `GodSlot.VERSION` stays 1. `slots()` and `BASE_SLOTS` stay (the Hunt bots' loadout check uses them); their doc comments say a night no longer drafts by them.
- `seal_target()` body unchanged; its doc comment and `carried`'s now say "nights the ability was cast".
- Faith screen detail lines: row `slot` → `"Full refill: %d s" % refill_seconds()`; row `might` → `"Might gauge: %d" % max_might()`.

- [ ] **Step 1: failing tests:** `refill_seconds()` is 60 fresh, 55/50/45 after 1/2/3 buys of `"slot"`; a file written with `bought = {"slot": 3}` reads back 45 s and `slots()` unchanged; the Faith row line reads `FASTER MIGHT   150 Faith   0 / 3`; detail lines as above; `MightPool.for_god(slot)` has `capacity == slot.max_might()` and `refill_seconds == slot.refill_seconds()`; an old file with a six-key `loadout` and a sealed key reads without error (Review Focus 5).
- [ ] **Step 2:** run the two suites, expect failures.
- [ ] **Step 3:** implement. Update existing assertions that expect `+1 SLOT` / `Slots in a draft`.
- [ ] **Step 4:** run `--only=test_god_slot`, the Faith suite and `--only=test_might_pool`, all `failures=0`.
- [ ] **Step 5:** commit `feat: Faith's slot row becomes FASTER MIGHT (5 s off the refill)`.

---

### Task 4: The god's night carries the gauge

**Files:** Modify `src/game/mission/mission_def.gd`, `src/game/god/god_night.gd`, `tests/test_god_night.gd` (and `tests/test_god_rite.gd`, `tests/test_god_lantern.gd` where they assert the pool or `carried`). `ActDef`: check whether it extends `MissionDef`; if not, add the same fields there.

**Interfaces — Produces:**
```gdscript
# MissionDef (and ActDef)
var might_capacity := 0      # > 0: a gauge night of this size
var might_refill := 60.0     # seconds for a full refill
var sealed := ""             # the god's sealed key, "" for none
var god_type := ""           # the god's own type (the bar's middle page), "" outside a god's night
func gauge() -> bool         # might_capacity > 0
```
- `GodNight._apply_god(def, slot, pool)`: `def.pool = slot.in_tree()` (or `[NO_POWERS]` when empty), `def.might_capacity = slot.max_might()`, `def.might_refill = slot.refill_seconds()`, `def.sealed = slot.sealed`, `def.god_type = slot.type`. `def.slots` and `def.dp_capacity` keep their values (Prepare's read-only mode ignores them). Callers pass `slot.in_tree()` where they pass `slot.draftable()` today.
- `GodNight.bank(slot, id, cast, outcome)` and `_bank_rite(...)`: the third parameter is the keys cast that night. `carried[key] += 1` for each. `slot.loadout` is no longer assigned.
- `GodNight.night_loadout(slot) -> PackedStringArray`: `slot.in_tree()` (empty when nothing is learned); what Game starts the mission with.

- [ ] **Step 1: failing tests:** a god with a sealed key: `def_for().pool` contains it, `def.sealed` equals it, `might_capacity == max_might()`, `might_refill == refill_seconds()`, `god_type == slot.type`, and the same on every act of a night with acts and on a rite def and a Hunt def; `bank(slot, id, ["smite"], outcome)` raises `carried.smite` by 1 and leaves a key not cast unchanged; `slot.loadout` unchanged by `bank`; `TierBook.board(id, null).gauge() == false`.
- [ ] **Step 2:** run `--only=test_god_night`, expect failures.
- [ ] **Step 3:** implement; update assertions that expected the sealed key out of the pool or `loadout` remembered.
- [ ] **Step 4:** run `--only=test_god_night`, `test_god_rite`, `test_god_lantern`, `test_hunt_book`, all `failures=0`.
- [ ] **Step 5:** commit `feat: a god's night def carries the gauge, the seal and every learned ability`.

---

### Task 5: Mission builds the pool; bots pay

**Files:** Modify `src/game/mission.gd`, `tools/dev/behaviour_check.gd`; create `tests/test_might_night.gd`; register it.

**Interfaces — Consumes:** Tasks 1, 2, 4.
**Produces (on `Mission`):**
```gdscript
var might_tier := 0                       # > 0: every act's Rules gets MightPool.for_tier(might_tier) (the bots' switch)
func cast_keys() -> PackedStringArray     # keys cast this night, the union over the acts played so far
```
- `_build_act`: after `_rules.setup(...)`, with `play` the def being played: `if might_tier > 0: _rules.might = MightPool.for_tier(might_tier)` else `if play.gauge(): _rules.might = MightPool.make(play.might_capacity, play.might_refill)`; `_rules.sealed = play.sealed`. Never when `remembrance != ""`.
- The outcome dictionaries `Mission` emits (`finished`, `decided`, the act result) carry `"cast": cast_keys()`; a new act merges the finished act's `Rules.cast_keys` first.
- `behaviour_check.gd`: every run with `--god` sets `mission.might_tier = god_tier` before `mission.start(...)` and prints `BEHAVIOUR might=<capacity>/<refill>` (in no checksum). Runs without `--god` set nothing.

- [ ] **Step 1: failing tests** (headless `Mission`, built as `tests/test_god_night.gd` or `tests/test_night.gd` build one):
  - a board mission: `_rules.might == null`.
  - a mission whose `night_def` returns a gauge def of size 8 / 55 s: `_rules.might.capacity == 8`, `refill_seconds == 55`, `_rules.sealed` set.
  - `might_tier = 1` on a board def: pool of 6 / 60.
  - Remembrance (`remembrance = key`) with a gauge def: `_rules.might == null`.
  - a night with acts: the second act's pool starts full; `cast_keys()` after a cast in each act holds both keys.
- [ ] **Step 2:** run `--only=test_might_night`, expect failures.
- [ ] **Step 3:** implement.
- [ ] **Step 4:** run `--only=test_might_night`, `test_night`, `test_god_routes`, `failures=0`. Run one bot by hand: `$G --headless --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=tax --case=play --seed=1 --god=ruin:1`; expect a `BEHAVIOUR might=6/60` line and a result line.
- [ ] **Step 5:** commit `feat: Mission builds the Might pool per act; god bots pay Might`.

---

### Task 6: AbilityBar

**Files:** Create `src/game/ui/ability_bar.gd`, `tests/test_ability_bar.gd`; register it.

**Interfaces — Consumes:** `Rules` (Task 2), `GodTree.neighbours()`, `GodTree.spot_of(key)`, `UiTheme`, `UiIcon`, `PowerBook.icon()` / `hud_icon()`.
**Produces:**
```gdscript
class_name AbilityBar
extends RefCounted
const TILE := 36.0          # a tile's side, HUD units (640x360)
const TILE_GAP := 4.0
const STRIP_TILE := 28.0
const BOTTOM := 2.0         # gap under the row, as the slot cards have
const LINE := 13.0          # height of the name line, the tabs line and the gauge line
const SEG := Vector2(8.0, 6.0)   # one gauge segment
const PAGE_FLASH := 1.5     # seconds the hidden strip names a page after a turn
const HINT := "Ctrl: abilities"
var open := false
var page := 0
static func pages_for(own_type: String, keys: PackedStringArray) -> Array
    # [{"type": String, "slots": PackedInt32Array}], slots = indices into `keys`, tree order, only types with a key.
    # Order: GodTree.neighbours(own)[0], own, GodTree.neighbours(own)[1], then any other type in GodTree.RING order.
    # own_type "" or absent from the keys: RING order.
func setup(rules: Rules, own_type: String) -> AbilityBar     # builds pages, loads icons once, page = the own type's page (0 if none)
func pages() -> Array
func toggle() -> void
func turn(by: int) -> void                 # wraps; no-op with fewer than 2 pages; starts the page flash
func slot_for_digit(digit: int) -> int     # digit 0..9 (key 1..0) -> loadout slot on the current page, -1 for none
func digit_of(slot: int) -> int            # the slot's place on its own page, -1 when not found
func page_of(slot: int) -> int
func advance(delta: float) -> void
func rect(view: Vector2) -> Rect2          # everything drawn now: the strip when hidden, the whole bar when open
func tile_rect(i: int, view: Vector2) -> Rect2      # tile i of the current page (open only)
func tab_rect(i: int, view: Vector2) -> Rect2
func armed_rect(armed: int, view: Vector2) -> Rect2 # where the armed ability's tile is (bar tile if on this page and open, else the strip's tile)
func hit(point: Vector2, view: Vector2) -> String   # "tile:<slot>", "tab:<i>", "strip", ""
func tile_state(slot: int) -> String       # "ready" | "sealed" | "cooldown" | "might" | "busy" | "empty" | "over" (Rules.refusal, "" -> "ready")
func signature(armed: int) -> String       # everything the drawing depends on, for the HUD's redraw check
func draw(on: CanvasItem, view: Vector2, armed: int, hover: int, flash: PackedFloat32Array) -> void
```
Layout (logical units, centred on `view.x`, measured up from `view.y - BOTTOM`): open = tiles row (36), name line above, tabs line above that, gauge line on top; hidden = one strip 28 high holding `[armed tile] name  N Might   MIGHT [segments] v / cap   Ctrl: abilities`. Tile drawing: key plate top-left (`1`..`9`,`0`), Might price bottom-right in `Color("9cc4de")`, red `UiTheme.COL_BAD` when `tile_state == "might"` with the icon grey (`Color(0.45, 0.45, 0.5)`); cooldown shade and seconds as `Hud._draw_slots` does; `"sealed"`: icon dark and a lock glyph (draw a small padlock from rects: no new art); armed: gold frame. Gauge: `capacity` segments, full ones `Color("6fa8c8")`, the fractional one filled in proportion, text `"%d / %d" % [pool.whole(), capacity]`. Use the crisp icon choice `Hud._slot_icon` uses (`UiIcon.texture_for`).

- [ ] **Step 1: failing tests:**
  - `pages_for("ruin", [dominion key, 3 ruin keys, 2 passage keys])` → types `["dominion", "ruin", "passage"]`, each `slots` in tree order.
  - `pages_for("ruin", [ruin keys only])` → one page. `pages_for("", [])` → `[]`.
  - `setup` opens on the own type's page; `turn(1)` from the last page wraps to 0; `turn(1)` with one page changes nothing.
  - `slot_for_digit(0)` is the page's first slot; a digit past the page's count is -1; with zero pages every digit is -1 and `rect()` is the strip (Review Focus 1).
  - packed order: a page of 4 keys answers digits 0..3 only.
  - with ten tiles open at `view = Vector2(640, 360)`: every `tile_rect`, every `tab_rect` and `rect()` lie inside `Rect2(0, 0, 640, 360)`; tiles do not overlap; at `view = Vector2(1280, 720)` they are centred (Review Focus 2).
  - `rect()` when hidden is shorter than `Hud.SLOT_SIZE` (42) and when open no taller than `TILE + 3 * LINE + 8`.
  - `hit()` on a tile's centre gives `"tile:<slot>"` with the loadout slot, on a tab `"tab:<i>"`, on the hidden strip `"strip"`, elsewhere `""`.
  - arm slot S on page 0, `turn(1)`: `page_of(S) == 0`, `armed_rect(S)` is the strip's tile, `slot_for_digit(0)` is page 1's first slot (Review Focus 4).
  - `tile_state` for a sealed key is `"sealed"`, for an unaffordable one `"might"`.
  - `signature()` changes when `open`, `page`, the pool's `whole()`, a tile's state or the armed slot changes, and not otherwise between two calls.
- [ ] **Step 2:** import, run `--only=test_ability_bar`, expect failures.
- [ ] **Step 3:** implement.
- [ ] **Step 4:** run, `failures=0`.
- [ ] **Step 5:** commit `feat: AbilityBar, the god's paged ability bar and Might strip`.

---

### Task 7: HUD and input use the bar

**Files:** Modify `src/game/ui/hud.gd`, `src/game/mission.gd`, `tests/test_might_night.gd` (extend), and `tests/test_hud.gd` only if an existing assertion needs the no-pool path named.

**Interfaces — Consumes:** `AbilityBar` (Task 6), `Rules.might` / `sealed` (Task 2), `MissionDef.god_type` (Task 4).
**Produces (on `Hud`):**
```gdscript
var bar: AbilityBar = null       # made in setup() when _rules.might != null; null otherwise
var bar_type := ""               # set by Mission before setup(): the def's god_type
func bar_hit(point: Vector2) -> String    # bar.hit(...) or "" without a bar
```
- With `bar != null`: `_draw()` calls `bar.draw(...)` in place of `_draw_slots`; `slot_top()` returns `bar.rect(_view()).position.y`; `slots_rect()` returns `bar.rect(_view())`; `slot_at()` returns the slot of a `"tile:<slot>"` hit, else -1; `_signature()` appends `bar.signature(...)`; `advance()` calls `bar.advance(delta)`; the modes row (`_draw_modes`) is drawn above `bar.armed_rect(...)`. `chain_rect()` keeps its formula (it reads `slots_rect()` / `slot_top()`).
- `_on_cast_refused`: `"might"` → `push_banner("NOT ENOUGH MIGHT", true)`; `"sealed"` → `push_banner("SEALED BY THE LANTERN", true)`.
- With `bar == null` nothing in the HUD changes.
- `Mission`:
```gdscript
const BAR_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]
func toggles_bar(event: InputEvent) -> bool   # a Ctrl key (physical_keycode KEY_CTRL), pressed, not echo, no alt/meta/shift
```
  In `_unhandled_input`, only when `_hud.bar != null`: a `BAR_KEYS` press picks `_hud.bar.slot_for_digit(i)` when it is >= 0 (in place of the `SLOT_KEYS` branch); `toggles_bar` toggles with `ui_click`; `KEY_Z` / `KEY_X` call `turn(-1)` / `turn(1)` with `ui_mode`; a left click: `"strip"` opens the bar, `"tab:<i>"` sets the page, `"tile:<slot>"` picks (the existing `slot_at` branch already does). The `ui_hidden` wake-up list gains `BAR_KEYS`, Ctrl, Z and X when a bar exists. These branches sit after the legend and intro returns, so neither reacts under them. The game binds no Ctrl+key combination in a night, so toggle on press.
  `_build_act` sets `_hud.bar_type = play.god_type` before `_hud.setup(...)`.

- [ ] **Step 1: failing tests** (extend `tests/test_might_night.gd`; build key events as `tests/test_descend_hud.gd` or `tests/test_rite_hud.gd` do):
  - gauge night: `_hud.bar != null`; board night: `_hud.bar == null` and `Hud.slot_rect(0)` equals its value on Develop-Main's formula.
  - Ctrl press toggles `bar.open`; a Ctrl echo does not; Shift+Ctrl does not.
  - `KEY_0` with ten abilities on the page arms the tenth; `KEY_7` on a four-tile page arms nothing.
  - `KEY_X` turns the page and keeps `_aim.slot` (Review Focus 4); a number key then arms from the new page.
  - with the legend open, and during the intro, Ctrl / Z / X / `KEY_7` change nothing; with `ui_hidden`, a Ctrl press sets `ui_hidden` false (Review Focus 3).
  - a click on the hidden strip opens the bar and casts nothing; a click on a tile arms it.
  - a cast refused `"might"` raises the banner `NOT ENOUGH MIGHT`.
  - `_hud.slot_top()` with the bar hidden is greater (lower on screen) than with it open; `_hud.slots_rect() == _hud.bar.rect(view)`.
  - a gauge night whose loadout is empty builds a HUD and takes every key above without error (Review Focus 1).
- [ ] **Step 2:** run, expect failures.
- [ ] **Step 3:** implement.
- [ ] **Step 4:** run `--only=test_might_night`, `test_hud`, `test_descend_hud`, `test_rite_hud`, `test_ability_bar`, all `failures=0`.
- [ ] **Step 5:** commit `feat: a gauge night's HUD shows the ability bar; Ctrl, Z, X and keys 1-0`.

---

### Task 8: The briefing and the no-draft flow

**Files:** Modify `src/game/ui/prepare_screen.gd`, `src/game/game.gd`, `tests/test_endless_screens.gd`, `tests/test_endless_flow.gd`; the FLOW steps in `game.gd` (around lines 2128, 2506, 2599, 2697 on `acb82b96`).

**Interfaces — Consumes:** `MissionDef.gauge()`, `GodNight.night_loadout()`, `Mission.cast_keys()` / outcome `"cast"`.
**Produces (on `PrepareScreen`):**
```gdscript
var read_only := false                  # set in setup(): god != null and def.gauge()
func gauge_text() -> String             # "Might %d  ·  full refill in %d s"
```
- `read_only`: tabs and cards draw as today (sealed card with its note, hover preview kept); a click on a card does nothing (no buzz, no pick); `hit()` returns no `"slot:<i>"` / `"level:<i>"`; `_draw_loadout` draws only `gauge_text()` at the bar's left and the confirm button; `confirm_label` is `"DESCEND"` (and stays `"BEGIN"` between acts); `can_manifest()` is true; `budget_text()` is `""` and `_draw_budget` draws nothing; `_god_tabs` are filled from `god.in_tree()` without the `mission.allows` filter changing (the pool already is `in_tree()`).
- `Game`:
  - hub `"descend"` / `"awaken"`: the empty check uses `god.in_tree()`; `loadout = GodNight.night_loadout(god)`. Every other `loadout = god.loadout.duplicate()` for an Endless night or photograph does the same.
  - `_on_prepare_action` for a god's night starts the mission with `GodNight.night_loadout(god)` whatever the draft holds.
  - `_on_mission_finished` and `_on_night_decided`: `bank_god_night(god, mission_id, PackedStringArray(outcome.get("cast", PackedStringArray())), outcome)`.
  - Between acts in Endless Night the same read-only briefing shows.
  - FLOW: the Endless steps assert the briefing (`prep.read_only`, `prep.gauge_text() == "Might 6  ·  full refill in 60 s"`, the 7-Might step → `"Might 7  ·  ..."`), descend without picking, and a banked night whose `carried` grew only for keys cast.

- [ ] **Step 1: failing tests** in `tests/test_endless_screens.gd` / `test_endless_flow.gd`: a god's Prepare is `read_only`; a card click leaves `draft.picks` unchanged and `refused_reason == ""`; `hit(MANIFEST_RECT centre) == "manifest"` and it emits `action("manifest")` with nothing picked; `gauge_text()` for a Tier 1 god with one FASTER MIGHT is `"Might 6  ·  full refill in 55 s"`; the sealed card's cost text still starts `Sealed:`; the board's Prepare has `read_only == false` and its `budget_text()` is unchanged; `Game.bank_god_night(slot, id, ["smite"], outcome)` raises `carried.smite` only.
- [ ] **Step 2:** run both suites, expect failures.
- [ ] **Step 3:** implement; update existing assertions about the god's slots/Might budget line.
- [ ] **Step 4:** run `--only=test_endless_screens`, `test_endless_flow`, `test_board_test_mode`, `test_campaign_screens`, `failures=0`. On a quiet machine: `$G --path . --scene res://scenes/game.tscn -- --flow-test`; expect every check to pass.
- [ ] **Step 5:** commit `feat: Endless Night's Prepare is a briefing; the god descends with every ability`.

---

### Task 9: Photographs, gates and tuning

**Files:** Modify `src/game/game.gd` (`--show=` cases), `src/game/might_pool.gd` / `src/game/descend/tier_book.gd` only if tuning is needed; `tools/dev/refs/*.tsv` (the `--god` rows only).

- [ ] **Step 1:** Add `--show=bar-hidden` and `--show=bar-open` (a Tier 5 fixture god on the dev fill with ten abilities of its own type and some of each neighbour, mid-night, one ability on cooldown, gauge part spent) beside the existing Endless photographs; point any photograph that showed six slot cards in a god's night (`six`, `modes` of the rite set) at the bar. Capture both at 1280x720 and 1920x1080 with the show's own slot files and compare by eye with the mockup: tiles one row, strip smaller than today's cards, nothing clipped.
- [ ] **Step 2:** Rerun Task 0's commands into `.gate-after/` and write `.gate-after/SUMMARY.txt` beside the baseline's.
- [ ] **Step 3:** For every pair or Hunt that PASSed in the baseline and FAILs now, apply the tuning order, one change at a time, rerunning only the failing gates then all of them once green:
  1. `MightPool.REFILL_SECONDS` 60 → 55 → 50 → 45 (never lower).
  2. A flat bonus `MightPool.TIER_BONUS` (start 1, at most 3) added in `for_tier()` and in `GodSlot.max_might()`.
  A bot policy may be changed only to wait out a `"might"` refusal the way it waits out a cooldown. If the gates are still red at 45 s and +3, stop: write the two SUMMARY files and the failing pairs into the report for the user. Do not edit missions, idle limits or bands.
- [ ] **Step 4:** `bash tools/dev/refs_check.sh --jobs=4` on a quiet machine. Expected: every row without `--god` matches; `--god` rows differ. Any non-`--god` row that differs is a bug: fix it before going on. Then re-record the `--god` rows the way `tools/dev/refs_check.sh` documents, and rerun: all 508 match.
- [ ] **Step 5:** `bash tools/dev/run_suite_parallel.sh 6`; a part with `NO RESULT` is rerun alone with a 5400 s timeout. Expected `failures=0` in every part. FLOW once more on a quiet machine.
- [ ] **Step 6:** commit `test: Might gauge photographs; god refs re-recorded with bots paying Might` (and a separate `tune:` commit for any number changed, naming old and new values).

---

### Task 10: Land

- [ ] **Step 1:** Final whole-branch review against the spec (fresh reviewer), fix findings, rerun the suites they touch.
- [ ] **Step 2:** Follow the project's merge procedure: `git fetch`; trial-merge `origin/feat/Develop-Main` into a throwaway commit; check semantic clashes in `rules.gd`, `hud.gd`, `mission.gd`, `game.gd`, `prepare_screen.gd`; gate the merged tree (suite, refs, FLOW, both god gates); fast-forward `feat/Develop-Main`; push.
- [ ] **Step 3:** Ledger: idea "Ability restricted by Might" done, a task entry, board refresh. Discord: the #ideas post OPEN → DONE and closed; a #god-changelog post.
- [ ] **Step 4:** Report to the user: what landed, every number that differs from the agreed 60 s / tier budget, the before/after gate tables, and the calls made during the build.
