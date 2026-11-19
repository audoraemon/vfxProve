# God's Chamber (milestone 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> This project's `kak-milestone` skill applies: the plan gives interfaces, tests and numbers, not full code; the implementer
> writes the code test-first.

**Goal:** Replace the text hub between nights (`GodHub`) with the God's Chamber: a layered room with four clickable stations, a
top status bar, parallax and zoom transitions, in greybox art.

**Architecture:** The hub's words and rules move unchanged into a `HubStatus` object. A new `GodChamber` screen draws the room
from a `ChamberLayout` data table through `ChamberArt` (texture if present, else greybox) and emits the hub's own `action`
names, so `Game`'s routes, saves and nights do not change.

**Tech Stack:** Godot 4.7.2, GDScript, the project's UI layer (`UiScale`, `UiTheme`, `UiSound`), the project's test runner
(`tests/run_part.gd`).

**Spec:** `docs/superpowers/specs/2026-11-19-kak-god-chamber-design.md` (read it first; this plan argues from it).

## Global Constraints

- Worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-chamber`, branch `feat/god-chamber`. Never touch the `vfxProve` worktree.
- Godot: `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`. Always wrap runs in `timeout` (a parse error hangs).
- Fresh worktree or new `class_name`: copy `.godot` from `../vfxProve-gmerge` once, then
  `timeout 300 $G --headless --path . --import` before any headless run.
- One suite: `timeout 600 $G --headless --path . --script res://tests/run_part.gd -- --part=1 --of=1 --only=<name>`.
  It prints `part=1/1 suites=1 checks=N failures=F`. A suite that dies on a runtime error can still print `failures=0`: read
  the output for `SCRIPT ERROR`.
- New tests are added to the list in `tests/run_all.gd` (beside `test_faith_hub.gd`).
- The action names stay exactly: "descend", "awaken", "tree", "faith", "title", "awaken_dev".
- The refusal texts stay word for word (`BLOCKED`, `HUNT_DUE`, `SEALED`, `AWAKEN_HUNT`, `RITE_UNWRITTEN`, `GIFTS_LINE`).
- Coordinates: 640 x 360 design units in `UiScale.design_frame`. Room 840 x 360 (x from -100 to 740). Top bar 22 units high.
- Numbers: `PARALLAX_MAX` 6.0; layer factors wall 0.25, stations 0.5, table 0.75, desk 1.0; `ZOOM_TO` 2.2; `ZOOM_TIME` 0.35 s;
  fade over the last 40% of the zoom; dim stations at 45% brightness; hover outline 1 unit, `UiTheme.COL_GOLD`.
- Scripted windowed runs use `user://test_*` files only, never `kak_save.cfg` or `kak_settings.cfg`.
- Stage files by name; never `git commit -a`. Do not stage stray `*.uid` files of other work. Commits end with
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`.
- No PixelLab, no ChatGPT automation. Never kill a Godot process you did not start.
- No replay reference may move: the room changes no night. A moved row is a bug, not a re-record.

## Review Focus

1. A click during a transition: it must skip, never fire a second action or a different station's action.
2. The screen torn down mid-transition (Esc to title, pause, quit): nothing emitted afterwards, no freed-object error.
3. Parallax at the mouse extremes and with the mouse outside the window: what is drawn is what is clicked.
4. Window resized while the room is open (16:9 to 21:9 to 4:3): bar anchored, stations clickable, no station under the bar.
5. A god at the cap with nothing to draft, and a god with the Hunt due: the Rite door and the table refuse as the hub did.

Each line has its test in the task that owns the code (Tasks 3 and 4).

---

### Task 1: `HubStatus`, the hub's words moved out

**Files:**
- Create: `src/game/ui/hub_status.gd`
- Modify: `src/game/ui/god_hub.gd` (uses `HubStatus`; drawing and input unchanged)
- Create: `tests/test_hub_status.gd`; Modify: `tests/test_faith_hub.gd`, `tests/run_all.gd`

**Interfaces:**
- Produces: `class_name HubStatus extends RefCounted`
  - `func _init(slot: GodSlot) -> void`
  - constants `BLOCKED`, `HUNT_DUE`, `SEALED`, `AWAKEN_HUNT`, `RITE_UNWRITTEN`, `GIFTS_LINE` (same strings as `GodHub`)
  - `static func bar_text(slot: GodSlot) -> String`
  - `func lines() -> PackedStringArray` (7 lines, same order: title, level+tier, bar text, points, Faith, Notice, Night)
  - `func gifts_line() -> String`, `func notice_fill() -> float`, `func hunt_line() -> String`, `func seal_line() -> String`
  - `func can_descend() -> bool`, `func blocked_line() -> String`
  - `var awaken := ""` (from `GodNight.awaken_state(slot)`, fixed at `_init`), `func awaken_shown() -> bool`,
    `func awaken_dim() -> bool`
  - `func bar_fill() -> float` (1.0 when capped, else divine_power / need, clamped 0..1)
  - `func faith_affordable() -> bool` (true when any row of `GodSlot.FAITH` has `slot.faith_refusal(row.key) == ""`)
  - `func press(what: String, from_key := false, dev := false) -> Dictionary`: the hub's decision for one press, with no
    sound and no signal: `{"emit": String, "buzz": bool, "line": String}`. `what` is "descend", "awaken", "tree", "faith",
    "title". It holds the logic of `GodHub._emit` and `_awaken_pressed` exactly (including the dev hook returning
    "awaken_dev", `AWAKEN_HUNT` and `RITE_UNWRITTEN` as `line`).
- `GodHub` keeps its public functions as thin forwards (`GodHub.bar_text`, `lines()`, `menu_rect`, `click`, `line`, ...), so
  FLOW and the probe still pass after this task.

- [ ] **Step 1:** Write `tests/test_hub_status.gd`: for each `_hub_*` case in `test_faith_hub.gd` that checks words or a
  decision (lines, notice, hunt, seal, awaken refused/rite/unwritten/hidden/hunt/blocked, gifts, blocked), the same fixture
  against `HubStatus` and `press()`. Add `faith_affordable()` true/false cases (Faith 0; Faith enough for the cheapest row) and
  `bar_fill()` (0, half, capped). Add the suite to `tests/run_all.gd`.
- [ ] **Step 2:** Run it; expect a parse failure (`HubStatus` not declared).
- [ ] **Step 3:** Create `HubStatus` by moving the code; make `GodHub` forward to it. Run `--import`.
- [ ] **Step 4:** Run `--only=test_hub_status` and `--only=test_faith_hub`: both 0 failures, no `SCRIPT ERROR`.
- [ ] **Step 5:** Commit: `refactor: HubStatus holds the hub's words and decisions (no behaviour change)`.

### Task 2: `ChamberLayout` and `ChamberArt` (the room as data, greybox drawing)

**Files:**
- Create: `src/game/ui/chamber_layout.gd`, `src/game/ui/chamber_art.gd`
- Create: `tests/test_chamber_layout.gd`; Modify: `tests/run_all.gd`

**Interfaces:**
- Produces: `class_name ChamberLayout` (static)
  - `const ROOM := Rect2(-100.0, 0.0, 840.0, 360.0)`, `const FRAME := Rect2(0.0, 0.0, 640.0, 360.0)`, `const BAR_H := 22.0`
  - `const PARALLAX_MAX := 6.0`, `const LAYERS := {"wall": 0.25, "stations": 0.5, "table": 0.75, "desk": 1.0}`
  - `const ORDER: Array[String] = ["descend", "tree", "faith", "awaken"]`
  - `const STATIONS: Dictionary`, one row per key:
    `{name: String, rect: Rect2, focus: Vector2, layer: String, keys: Array[Key], action: String}`. First layout:

    | key | name | rect (x, y, w, h) | layer | keys |
    |---|---|---|---|---|
    | descend | World Table | 200, 150, 240, 110 | table | KEY_ENTER, KEY_KP_ENTER, KEY_1 |
    | tree | Ability Tree | 40, 70, 110, 130 | stations | KEY_T, KEY_2 |
    | faith | Faith Altar | 490, 80, 110, 120 | stations | KEY_F, KEY_3 |
    | awaken | Rite Door | 170, 50, 80, 90 | wall | KEY_A, KEY_4 |

    `focus` is each rect's centre. `action` equals the key.
  - `const SCENERY: Array`: non-clickable pieces `{name, rect, layer}`: `wall` = ROOM on "wall"; `table` = the table's body on
    "table"; `desk` = Rect2(-100, 300, 840, 60) on "desk".
  - `static func shift(layer: String, mouse01: Vector2) -> Vector2`: `mouse01` is the mouse as -1..1 from the screen centre
    (clamped); returns `-mouse01 * PARALLAX_MAX * LAYERS[layer]`, snapped to whole units.
  - `static func rect_of(key: String, mouse01 := Vector2.ZERO) -> Rect2`: the station's rect moved by its layer's shift.
  - `static func at(point: Vector2, mouse01 := Vector2.ZERO) -> String`: the station under a design-frame point, front layer
    first (table, stations, wall); "" for none or for a point inside the top bar.
  - `static func key_for(code: Key) -> String`: the station a key belongs to, or "".
- Produces: `class_name ChamberArt` (static)
  - `const DIR := "res://assets/chamber/"`
  - `static func texture(name: String) -> Texture2D` (cached; null when the file is missing; no per-frame load or log)
  - `static func draw(canvas: CanvasItem, name: String, rect: Rect2, state := "") -> void`: `state` is "", "hover", "dim" or
    "closed". Texture found: `draw_texture_rect` (the `closed` door uses `awaken_closed`). Not found: a flat greybox
    silhouette, one colour per name (table blue-grey, tree violet, altar amber, door stone; wall very dark; desk dark brown),
    with a darker base strip; "dim" multiplies by 0.45; "closed" draws the door dark with no glow. "hover" adds nothing here
    (the outline is `GodChamber`'s).
  - `static func greybox_color(name: String) -> Color` (so a test can tell the four stations apart).

- [ ] **Step 1:** Write `tests/test_chamber_layout.gd`:
  - every station rect is inside `FRAME`, below `BAR_H`, and no two stations intersect;
  - `ORDER` and `STATIONS` have the same four keys; each `focus` is inside its rect; each key code maps back with `key_for`;
    no key code belongs to two stations;
  - `shift("desk", Vector2(1, 0)) == Vector2(-6, 0)`, `shift("wall", Vector2(1, 0)) == Vector2(-2, 0)` (1.5 snapped), and a
    `mouse01` of (5, -5) is clamped to (1, -1);
  - `at(rect.get_center())` returns each key at rest; `at(rect_of(key, m).get_center(), m)` returns it at m = (1, 1) and
    (-1, -1); a point in the bar returns "";
  - `ChamberArt.texture("no_such")` is null, and the four stations' `greybox_color` differ pairwise.
- [ ] **Step 2:** Run; expect a parse failure.
- [ ] **Step 3:** Write both classes. Run `--import`.
- [ ] **Step 4:** Run `--only=test_chamber_layout`: 0 failures.
- [ ] **Step 5:** Commit: `feat: the God's Chamber layout table and greybox art hook`.

### Task 3: `GodChamber`, the screen (stations, bar, keys, badges), swapped into `Game`

**Files:**
- Create: `src/game/ui/god_chamber.gd`, `tests/test_god_chamber.gd`
- Delete: `src/game/ui/god_hub.gd` (and its `.uid`)
- Modify: `src/game/game.gd` (Screen.HUB builds `GodChamber`; FLOW's `as GodHub` casts; the `--show=hub*` fixtures),
  `tools/dev/real_path_probe.gd` (`_screen_is("GodHub")` and `hub.menu_rect`), `tests/test_faith_hub.gd` (hub cases move
  out; the Faith screen cases stay), `tests/run_all.gd`

**Interfaces:**
- Consumes: `HubStatus` (Task 1), `ChamberLayout`, `ChamberArt` (Task 2).
- Produces: `class_name GodChamber extends Node`
  - `signal action(name: String)`
  - `var line := ""`, `var dev := false`, `var status: HubStatus`, `var _ui: Control` (the 640 x 360 design frame, as the hub)
  - `func setup(slot: GodSlot, p_line := "", p_dev := false, p_from := "") -> GodChamber` (`p_from` is used in Task 4; accept
    and store it now)
  - `func lines() -> PackedStringArray` (forwards to `status`), `func can_descend() -> bool`
  - `func menu_rect(what: String) -> Rect2`: the station's current rect for "descend", "tree", "faith", "awaken"; the Title
    button's rect for "title". Kept under the hub's name so FLOW and the probe change by class name only.
  - `func click(point: Vector2) -> void`, `func station_state(key: String) -> String` ("", "hover", "dim", "closed"),
    `func badge(key: String) -> bool`, `func hint_text() -> String`
  - Title button: a small button at the bar's right end; `Esc` does the same.
- Behaviour:
  - A press (click or key) on a station asks `status.press(key, from_key, dev)`; `buzz` plays `ui_buzz`, `line` replaces
    `line` and redraws, `emit` plays `ui_click` and emits (immediately in this task; Task 4 adds the zoom).
  - `awaken` when `not status.awaken_shown()`: state "closed", `at()` skips it (no hover, no click); the A key still goes to
    `status.press("awaken", true, dev)`, the 4 key does nothing.
  - Hover: entering a station plays `ui_hover` once; outline and the name plate (name centred under the rect, on a dark strip).
  - Badges: `tree` when `slot.points > 0`; `faith` when `status.faith_affordable()`; `awaken` when shown and not dim.
  - Top bar per the spec §5, anchored to the real screen edges with `UiScale.anchor`; the Hunt and seal lines under it; the
    one-off line (wrapped to 600), blocked line, gifts line and hint at the bottom.
  - Hint: `"Enter: Descend   T: Tree   F: Faith   Esc: Title"`, plus `"   A: Awaken"` when shown, or `"   DEV  A: awaken"`.
  - Draw order: backdrop, wall, wall-layer stations, stations layer, table and its station, desk, outlines and plates,
    badges, top bar and text.

- [ ] **Step 1:** Write `tests/test_god_chamber.gd` (fixtures copied from `test_faith_hub.gd`: `_slot`, `_capped`, `_click`,
  `_key`):
  - the frame is 640 x 360 centred in a 960 x 495 test area (as `_frames` checks the hub today);
  - a click at each `menu_rect(key).get_center()` and each key in `ChamberLayout.STATIONS[key].keys` emits that action once;
  - nothing to draft: `descend` is "dim", a click buzzes, emits nothing, and `blocked_line()` is shown;
  - Rite door: not capped = "closed", a click on its rect and the 4 key emit nothing, hovering it shows no plate; capped with
    a rite = lit, click emits "awaken"; capped unwritten = "dim", click sets `line == HubStatus.RITE_UNWRITTEN`; dev A key
    when not capped emits "awaken_dev"; with the Hunt due it sets `AWAKEN_HUNT` and emits nothing;
  - capped with nothing to draft and the Hunt due (Review Focus 5): table and door both refuse;
  - badges: points 0/1, Faith below/at the cheapest price, rite ready or not;
  - Esc and a click on the Title button emit "title";
  - Review Focus 4: for test areas 1280x720, 1920x1080, 2560x1080, 1024x768: no station rect intersects the bar's rect, the
    bar's left and right ends are at the area's edges, and a click at each station centre still emits;
  - `lines()[6] == "Night 1"` on a fresh god (FLOW reads this).
  Move the hub cases out of `test_faith_hub.gd`; keep its Faith cases.
- [ ] **Step 2:** Run; expect a parse failure.
- [ ] **Step 3:** Write `GodChamber`. In `Game`: build `GodChamber` under the node name "Hub" with
  `setup(god, _hub_line, dev, "")`; change FLOW's `as GodHub` casts; check the `--show=hub*` fixtures still build. In the
  probe: `_screen_is("GodChamber")`. Delete `god_hub.gd`. Run `--import`.
- [ ] **Step 4:** Run `--only=test_god_chamber`, `--only=test_faith_hub`, `--only=test_hub_status`: 0 failures each.
- [ ] **Step 5:** Headless FLOW: `timeout 1500 $G --headless --path . --scene res://scenes/game.tscn -- --flow-test` ; expect
  `FLOW result checks=209 failures=0` (run it alone; another Godot running can abort it).
- [ ] **Step 6:** Capture the room for a look: `--show=hub`, `--show=hub-capped`, `--show=hub-awaken`, `--show=hub-unwritten`,
  `--show=hub-hunt`, `--show=hub-gifts` with `--capture --window=1280x720` (see `Game`'s `--show` handling near
  `"hub-awaken", "hub-unwritten", "hub-gifts"` for the output name). Read each PNG: four stations distinct, bar readable, no
  text overlapping.
- [ ] **Step 7:** `bash tools/dev/run_suite_parallel.sh 8`: 0 failures (`test_decree_cage`'s 2 ms check can fail under the
  8-way load: rerun it alone before calling it a failure).
- [ ] **Step 8:** Commit: `feat: the God's Chamber replaces the hub (four stations, top bar, badges; greybox)`.

### Task 4: Parallax and transitions

**Files:**
- Modify: `src/game/ui/god_chamber.gd`, `src/game/game.gd`, `tests/test_god_chamber.gd`

**Interfaces:**
- Consumes: `ChamberLayout.shift/rect_of/at` with `mouse01`.
- Produces, on `GodChamber`:
  - `static var transitions := true`
  - `const ZOOM_TO := 2.2`, `const ZOOM_TIME := 0.35`, `const FADE_FROM := 0.6` (the fade runs over the last 40%)
  - `func mouse01() -> Vector2` (from the last mouse position over the real area; (0, 0) before any motion; clamped to -1..1)
  - `func in_transition() -> bool`, `func zoom() -> float`, `func fade() -> float`
  - `func advance(delta: float) -> void`: one step of the transition (called from `_process`; public so tests step it)
  - `func skip() -> void`: finishes a transition at once (out: emits the pending action; back: at rest)
- Behaviour:
  - Out: an accepted press on a station starts the zoom about its `focus` (after the parallax shift); the action is emitted
    when it ends. "title" and "awaken_dev" never zoom. Refused presses (buzz) never zoom.
  - Back: `setup(..., p_from)` with "tree" or "faith" and `transitions` true starts at `ZOOM_TO` on that station, fade 1, and
    runs to rest. Any other `p_from` starts at rest.
  - While `in_transition()`: any click or key calls `skip()` and does nothing else; hover does not change.
  - `_exit_tree` clears the pending action, so a torn-down room emits nothing.
  - With `transitions` false: Task 3's behaviour exactly (emit in the same call).
- `Game`: remembers the last screen left for the hub; passes "tree" after "tree:back", "faith" after "faith:back", else "".
  Sets `GodChamber.transitions = false` when `--flow-test` or `--capture` is in the args or
  `DisplayServer.get_name() == "headless"`, else true.

- [ ] **Step 1:** Add to `tests/test_god_chamber.gd` (each test sets `GodChamber.transitions` itself and restores false):
  - with transitions on, a click on `tree` emits nothing at once; after `advance(0.2)` still nothing, `zoom()` is between 1
    and 2.2 and `fade() == 0.0`; after a further `advance(0.2)` the action has been emitted exactly once and `fade() == 1.0`;
  - Review Focus 1: during the zoom to `tree`, a click on `faith`'s rect emits "tree" once (the skip) and never "faith";
    a key press does the same;
  - Review Focus 2: start the zoom, free the node, step two frames: no emission, no error logged;
  - a dim station and the Title button start no transition;
  - `setup(slot, "", false, "tree")` starts with `zoom() == 2.2`, `fade() == 1.0`, `in_transition()`; after `advance(0.35)`
    it is at rest (`zoom() == 1.0`, `fade() == 0.0`); a click during it only skips;
  - with transitions off, `setup(..., "tree")` is at rest and a click emits in the same call;
  - Review Focus 3: with the mouse at the area's top-left and bottom-right corners, and with a motion event outside the area
    (clamped), a click at `menu_rect(key).get_center()` emits `key` for all four (capped fixture), and `menu_rect` moved by
    `ChamberLayout.shift(layer, mouse01())`.
- [ ] **Step 2:** Run; expect failures on the new cases only.
- [ ] **Step 3:** Implement parallax (draw and hit rects from `mouse01()`), the transition (a transform about the focus on the
  room's layers, a black rect over the room and under nothing: the bar fades with it), and `Game`'s `p_from` and off switch.
- [ ] **Step 4:** Run `--only=test_god_chamber`: 0 failures. Headless FLOW again: `checks=209 failures=0`.
- [ ] **Step 5:** A windowed look, on test saves only: `powershell -ExecutionPolicy Bypass -File tools/dev/real_path.ps1 -Out
  <scratch dir> -Size max -Mode route -Route god`; read `probe.log` (no `CHECK` line other than `CHECK ok`) and the hub screenshots.
- [ ] **Step 6:** Commit: `feat: the Chamber's parallax and zoom transitions`.

### Task 5: The user's play test

- [ ] **Step 1:** Tell the user how to open the room (`--dev`, title, ENDLESS, a slot) and what to try: each station, the
  hotkeys, the skip, a resize, a 21:9 window.
- [ ] **Step 2:** Apply the layout changes they ask for in `ChamberLayout` only; rerun `--only=test_chamber_layout` and
  `--only=test_god_chamber`; commit each round.

### Task 6: Landing

- [ ] **Step 1:** `git fetch`; trial-merge `origin/feat/Develop-Main` into a throwaway commit; resolve; re-run the three
  chamber suites.
- [ ] **Step 2:** On the merged tree: `bash tools/dev/run_suite_parallel.sh 8` (0 failures), `bash tools/dev/refs_check.sh`
  (`refs ok=508 bad=0`; a moved row is a bug), windowed FLOW alone (`real_path.ps1 -Mode flow`: `FLOW result checks=209
  failures=0`).
- [ ] **Step 3:** With the user's go: `git merge-base --is-ancestor origin/feat/Develop-Main HEAD`, then
  `git push origin HEAD:feat/Develop-Main`.
- [ ] **Step 4:** Ledger task, #board refresh, #visual-changelog post, the #ideas post "God's Chamber" stays OPEN (art, the
  World Map and Conquer Progress are still to come) with a reply saying what landed; memory updated.
