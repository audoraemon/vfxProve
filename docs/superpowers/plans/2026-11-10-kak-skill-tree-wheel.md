# Skill Tree wheel and Remembrance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 30-box Skill Tree with a calm wheel (one Authority centred, tiers as rings, a bottom detail panel with the
preview clip) and add Remembrance: try any shown power, at any level, free, in the real Capital, without touching the save.

**Architecture:** Two small pure helpers (`TreeWheel` geometry and palette, `TreeDetail` panel content) feed a rewritten
`SkillTreeScreen` that keeps its public test/FLOW API. Remembrance is a normal `Mission` built from a new `MissionBook`
def with a `Rules.free` flag (no cooldown, no clock, never ends) and a small memory overlay; `Game` routes "tree:remember"
to it and its pause's Leave back to the tree, outside every Endless Night banking path.

**Tech Stack:** Godot 4.7.2, GDScript, the project's own test runner (`tests/run_all.gd`, `tests/run_part.gd`).

**Spec:** `docs/superpowers/specs/2026-11-10-kak-skill-tree-wheel-design.md` (approved 2026-11-10). Mockup:
`docs/superpowers/mockups/2026-11-10-skill-tree-wheel.html` (its `/files/` images were `assets/pixellab/icons/<key>.png`,
`assets/fonts/PixelifySans-Variable.ttf` and `assets/clips/wisp.png`; open it only for the look).

## Global Constraints

- Branch `god/skill-tree-ui` (worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve/.claude/worktrees/bold-goldstine-e7bb80`). Lands on
  feat/god-progression, never Develop-Main. Never push.
- Screen is 640x360; draw with `UiTheme` (font, `COL_TEXT`, `COL_DIM`, `COL_GOLD`, `COL_BAD`, `frame()`, `text()`, `wrap()`,
  `fit()`). No new art files.
- **Gold means "yours or buyable"** (learned rings, points, the Raise button). Remembrance is the only blue (`Color("6fa8c8")`).
- Remembrance never changes the god's file, never counts as a night, never reaches `_write_god()`, `GodNight` banking, Notice,
  seals or `god.in_night`.
- Level 1 behaviour of every power is unchanged: `Rules.free` defaults to false and every existing path must read identically.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never bare `git stash`.
- Godot: `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`. After adding a `class_name`, run
  `timeout 900 $G --headless --editor --path . --import` once before headless runs.
- One suite file:
  `L=$(grep -o 'res://tests/test_[a-z0-9_]*\.gd' tests/run_all.gd); N=$(echo "$L"|wc -l); I=$(echo "$L"|grep -n "/test_X.gd"|cut -d: -f1); timeout 900 $G --headless --path . --script res://tests/run_part.gd -- --part=$I --of=$N`
  then grep the output for `SCRIPT ERROR` (a parse error hangs rather than fails). New test files are registered in
  `tests/run_all.gd`.
- Before each commit: `bash tools/dev/run_suite_parallel.sh 8` (all `failures=0`).
- FLOW drives the tree through `columns()`, `key_at(col, tier, i)`, `learn_at(col, tier, i)` and `click(BACK_RECT.get_center())`
  (`src/game/game.gd` ~2420-2515): keep those four with today's meaning.

## Review Focus

1. **A click on a power spends points** (the old one-click learn leaking into the new page) -- expect: select only; only the
   gold button spends. Pinned in Task 3 (`_click_selects_only`).
2. **The god file changes after a Remembrance** (a banking path, `in_night`, a write on Leave) -- expect: byte-identical file.
   Pinned in Task 5 (`_remembrance_leaves_save_alone`).
3. **An empty spot or a locked/far power selected** -- expect: empty spot shows "Not chosen yet" and no buttons; a locked
   tier still offers Remembrance, the gold button greys with "Awaken to Tier N". Pinned in Task 3 (`_empty_and_locked`).
4. **Leaving Remembrance lands somewhere else** (own Authority, nothing selected) -- expect: same centred Authority and power.
   Pinned in Task 5 (`_leave_returns_to_selection`).
5. **A power without a clip or without level tables** (Death, Veil, Passage, Decree rows) -- expect: the big icon in the clip
   box, "Levels to come" in the level column, the level picker in Remembrance at 1 only. Pinned in Tasks 2 and 4.

---

### Task 1: Wheel geometry and Authority palette

**Files:**
- Create: `src/game/ui/tree_wheel.gd` (`class_name TreeWheel`, `extends RefCounted`, statics only)
- Test: `tests/test_tree_wheel.gd` (register in `tests/run_all.gd`)

**Interfaces:**
- Produces:
  - `const CENTER := Vector2(320, 132)`, `const NODE_R := 12.0`, `const RY0 := 22.0`, `const RY_STEP := 20.0`,
    `const RX_SCALE := 1.45`, `const ANGLES := [60.0, 120.0, 30.0, 150.0, 90.0]` (degrees, tier I-V; spot 1 is +180).
  - `const COLORS := {"dominion": Color("9b7fd0"), "ruin": Color("e08a5a"), "death": Color("9fcf9a"),
    "passage": Color("6fc4b8"), "veil": Color("8fa6d8"), "decree": Color("d8c27a")}`; `static func color(type: String) -> Color`
    (`UiTheme.COL_TEXT` for an unknown type).
  - `static func ring(tier: int) -> Vector2` -- (rx, ry) of tier 1-5's oval: ry = RY0 + (tier-1)*RY_STEP, rx = ry*RX_SCALE.
  - `static func node_at(tier: int, i: int) -> Vector2` -- screen centre of spot i (0-1) of tier; angle a = ANGLES[tier-1] + i*180,
    x = CENTER.x + sin(a)*rx, y = CENTER.y - cos(a)*ry.
  - `static func node_hit(point: Vector2) -> Vector2i` -- (tier, i) of the node whose NODE_R circle holds the point, else (-1, -1).
  - `const WHEEL_AREA := Rect2(128, 28, 384, 216)`, `const SIDE_L := Rect2(8, 34, 112, 198)`, `const SIDE_R := Rect2(520, 34, 112, 198)`,
    `const TOP_BAR := Rect2(0, 0, 640, 26)`, `const DETAIL := Rect2(8, 250, 624, 102)`.

- [ ] **Step 1: Write the failing tests** `tests/test_tree_wheel.gd` (`static func run(t)` like the other suites):
  - `_inside`: every `node_at(tier, i)` grown by NODE_R (plus 10 px below for its name) lies inside `WHEEL_AREA`, and
    `WHEEL_AREA` does not intersect `SIDE_L`, `SIDE_R`, `TOP_BAR` or `DETAIL`.
  - `_apart`: every pair of the 10 node centres is at least `2*NODE_R + 4` apart.
  - `_hit`: `node_hit(node_at(t, i)) == Vector2i(t, i)` for all 10; `node_hit(CENTER) == Vector2i(-1, -1)`.
  - `_rings`: `ring(1) == Vector2(31.9, 22)` (to 0.01) and `ring(5).y == 102.0`.
  - `_colors`: `color("dominion") == Color("9b7fd0")`; `color("nope") == UiTheme.COL_TEXT`; all six types present.
- [ ] **Step 2: Run** the one-suite command for `test_tree_wheel` -- expect a parse/identifier failure (no TreeWheel yet).
- [ ] **Step 3: Implement** `src/game/ui/tree_wheel.gd` as above; run the import once (new class_name).
- [ ] **Step 4: Run** the suite file -- expect `failures=0`, no `SCRIPT ERROR`.
- [ ] **Step 5: Commit** `feat: TreeWheel -- the skill tree wheel's rings, node places and Authority colours`.

### Task 2: Detail panel content

**Files:**
- Modify: `src/game/power_book.gd` (add `"blurb"` to every row that `GodTree.TABLE` uses; add the functions below; make
  `level_change_in()` build its text from `level_rows_in()` so the two never disagree)
- Create: `src/game/ui/tree_detail.gd` (`class_name TreeDetail`, statics only)
- Test: `tests/test_tree_detail.gd` (register); `tests/test_power_levels.gd` must still pass unchanged

**Interfaces:**
- Consumes: `GodSlot.level_of/cost/refusal/might_of`, `GodTree.spot/neighbours`, `PowerBook.twist/has_levels/NO_LEVELS/STAT_LABELS`,
  `SkillTreeScreen.REFUSALS` (move that const to `TreeDetail.REFUSALS`; `SkillTreeScreen.REFUSALS` stays as an alias).
- Produces:
  - `PowerBook.blurb(key: String) -> String` -- the row's `"blurb"`; else its `"shape"` with the first letter capitalised.
  - `PowerBook.level_rows(key: String, level: int) -> Array` -- for reaching `level`: `[{"label": String, "old": String,
    "new": String}]`, one per stat that changes (labels from STAT_LABELS, the `"twist"`/`"twist_text"` keys excluded); `[]` at
    level < 2 or with no table.
  - `TreeDetail.tags(key: String) -> PackedStringArray` -- `[AUTHORITY, "TIER " + roman, "QUIET" | "LOUD"]`
    (authority from `PowerBook.get_power(key).authority`, upper case; tier from where `GodTree` places the key; roman I-V).
  - `TreeDetail.description(key: String, width: float) -> PackedStringArray` -- `UiTheme.wrap(PowerBook.blurb(key), width,
    UiTheme.SIZE_SMALL)` cut to 2 lines (the 2nd ends "..." if cut).
  - `TreeDetail.level_column(slot: GodSlot, key: String) -> Dictionary` -- `{"head": String, "rows": Array, "might": String,
    "twist": String}`: head `"LEARN"` (unlearned, rows = level 1's numbers as `old == new`), `"LEVEL n -> n+1"`, or `"MAX"`;
    `might` `"2 -> 3"` (or `"2"` when it does not change); `twist` `"Level 5 . <first sentence of PowerBook.twist(key)>"`.
    No table: head `PowerBook.NO_LEVELS` ("Levels to come" -- set `NO_LEVELS` to that exact text; the checks in
    `tests/test_power_levels.gd:38` and `tests/test_ruin_levels.gd:351` compare against the const and keep passing, only their
    messages' wording may be updated), rows `[]`, twist `""`.
  - `TreeDetail.buy_button(slot: GodSlot, key: String, tier: int) -> Dictionary` -- `{"label": "LEARN" | "RAISE" | "MAX",
    "cost": int, "enabled": bool, "reason": String}`; reason from `REFUSALS` (tier filled in) when `slot.refusal(key) != ""`.
- Blurbs: two short lines at most (~80 characters), present tense, what the player sees happen. Ruin, Dominion and every
  Tier 1 key in `GodTree.TABLE` (28 keys). Example for wisp: "A pale light lures calm people to stand round it. ENTHRALL holds
  everyone near it."

- [ ] **Step 1: Failing tests** `tests/test_tree_detail.gd`:
  - `_rows`: `PowerBook.level_rows("wisp", 3)` has, in table order, the labels `["lure cap", "lure time", "enthrall",
    "cooldown"]` with old -> new 27 -> 30, 13 -> 14, 32 -> 34, 28 -> 26 (strings formatted exactly as `level_change()` prints
    them today); `level_rows("wisp", 1) == []`;
    `level_rows("thorns", 3) == []`.
  - `_same_text`: for every key with levels and every level 2-5, `level_change(key, lv)` still equals what it was (snapshot the
    strings before the refactor in the test's own constants for wisp 3, smite 5, schism 5).
  - `_tags`: `tags("wisp") == ["DOMINION", "TIER II", "QUIET"]`; `tags("smite") == ["RUIN", "TIER I", "LOUD"]`.
  - `_column`: a fresh dominion slot with wisp at level 2 -> head `"LEVEL 2 -> 3"`, 4 rows, might `"2 -> 3"`, twist begins
    `"Level 5 . "`; at 5 -> head `"MAX"`; unlearned -> head `"LEARN"`; `"thorns"` -> head `"Levels to come"`, rows `[]`.
  - `_button`: 0 points -> enabled false, reason `"Not enough ability points"`; tier-1 slot on a tier-3 key -> reason
    `"Awaken to Tier 3"`; a neighbour key's cost is twice the own type's at the same level.
  - `_blurbs`: every non-empty key in `GodTree.TABLE` has `blurb()` != "" and fits 2 lines at 230 px (`description()` size <= 2
    with no "...").
- [ ] **Step 2: Run** -- expect failures (functions missing).
- [ ] **Step 3: Implement** the PowerBook functions and blurbs, `NO_LEVELS` text, then `tree_detail.gd`.
- [ ] **Step 4: Run** `test_tree_detail`, `test_power_levels`, `test_skill_tree` -- all `failures=0`.
- [ ] **Step 5: Commit** `feat: TreeDetail -- what the skill tree's panel says (blurbs, changed stats, the buy button)`.

### Task 3: The new Skill Tree screen

**Files:**
- Rewrite: `src/game/ui/skill_tree_screen.gd` (same class, same `action` signal)
- Rewrite: `tests/test_skill_tree.gd` (keep the intents of today's checks: columns/ring wrap, far types never shown, x2 cost,
  locked tier refusal text, learning spends a point and emits "learned", icons loaded in setup)

**Interfaces:**
- Consumes: Task 1 `TreeWheel.*`, Task 2 `TreeDetail.*`, `PowerBook.clip(key)/clip_frame(i)/CLIP_FPS/CLIP_FRAMES/CLIP_SIZE`,
  `SkillTreeScreen.spot_icon(key)`.
- Produces (kept): `signal action(name: String)` with `"learned"`, `"back"` and new `"remember"`; `setup(slot: GodSlot,
  state := {}) -> SkillTreeScreen`; `columns() -> PackedStringArray` ([left, own, right], unchanged); `key_at(col, tier, i)`;
  `learn_at(col, tier, i) -> String` (selects that spot, then buys it: same return codes and emit as today); `click(point)`;
  `const BACK_RECT := Rect2(6, 4, 40, 18)`; `refused_reason`.
- Produces (new):
  - `var centred := 1` (index into `columns()`); `func centre(col: int) -> void`.
  - `var selected := Vector3i(-1, -1, -1)` (col, tier, i); `func select(col: int, tier: int, i: int) -> void`;
    `func selected_key() -> String`.
  - `func state() -> Dictionary` -- `{"centred": int, "selected": Vector3i}`; `setup(slot, state)` restores it when given.
  - `func remember_level() -> int` -- the level Remembrance starts at: the learned level, else 1.
  - Hit ids from `hit(point)`: `"back"`, `"chip:<col>"`, `"node:<tier>:<i>"` (centred column), `"mini:<col>:<tier>:<i>"`
    (a side panel's small icon), `"side:<col>"` (the rest of a side panel), `"remember"`, `"buy"`, or `""`.
  - Layout consts: chips centred in the top bar; points box right; side panels `TreeWheel.SIDE_L/SIDE_R` with a 2x5 grid of
    18 px icons; detail panel `TreeWheel.DETAIL` split as clip 152x86 at (+7, +8), info column, level column 132 wide, buttons
    `REMEMBER_RECT := Rect2(528, 263, 96, 30)` and `BUY_RECT := Rect2(528, 298, 96, 30)`.
- Behaviour (from the spec, do not re-decide): click a node/mini selects only; chip, side panel, Q/E centre; `buy` and
  `learn_at` spend; `remember` emits "remember" when a key is selected; Esc and Back emit "back"; first open selection
  = first learned power below 5 in tier order on the god's own column, else first learnable, else (own, 1, 0); hover sounds
  `ui_hover`, refusals `ui_buzz` + REFUSALS text for `REFUSE_SECONDS`; the clip loops at `CLIP_FPS`, a key without a clip
  draws its icon scaled into the clip box; locked rings dashed, current-tier ring lit, node states as the spec lists.

- [ ] **Step 1: Failing tests** (rewrite `tests/test_skill_tree.gd`; helpers `_screen(type, tier, points)` and `_click(at)` stay):
  - `_columns` (as today) and `_far_hidden` (as today).
  - `_click_selects_only`: a ruin god with 5 points; `click(TreeWheel.node_at(1, 0))` -> `selected == Vector3i(1, 1, 0)`,
    points still 5, `level_of("smite") == 0`, no "learned" emitted.
  - `_buy`: then `click(BUY_RECT.get_center())` -> smite level 1, points 4, "learned" emitted once.
  - `_centre`: `click` on chip 0 -> `centred == 0` and `key_at(0, 1, 0)` is what `node_hit(node_at(1,0))` now selects;
    a Q key event moves centred to the left, E to the right, wrapping within the three.
  - `_mini`: clicking a side panel's tier-1 first mini icon selects (that col, 1, 0) without centring.
  - `_empty_and_locked`: dominion god, tier 1: selecting a tier-3 key -> buy refused with "Awaken to Tier 3", REMEMBER still
    emits "remember"; a death god's empty tier-2 spot -> `selected_key() == ""`, clicking REMEMBER_RECT and BUY_RECT emit nothing.
  - `_first_open`: a dominion god with whisper 5, discord 2 -> selected is discord; a fresh god -> (1, 1, 0).
  - `_state_round_trip`: `setup(slot, other.state())` restores centred and selected.
  - `_learn_at_compat`: `learn_at(1, 1, 0)` with 0 points returns "points" and sets `refused_reason`; with points returns ""
    and emits "learned" (FLOW's path).
  - `_layout`: every hit rect (chips, BACK_RECT, REMEMBER_RECT, BUY_RECT, side panels) is inside 640x360 and none overlaps
    another or `TreeWheel.WHEEL_AREA`.
- [ ] **Step 2: Run** -- expect failures.
- [ ] **Step 3: Implement** the screen.
- [ ] **Step 4: Run** `test_skill_tree`, `test_tree_wheel`, `test_tree_detail`, `test_faith_hub` -- `failures=0`. Take the
  photograph `bash tools/capture.sh --show=tree` and look at it (Read the PNG it writes): names must not collide, nothing
  overflows its box.
- [ ] **Step 5: Commit** `feat: the Skill Tree as a wheel -- one Authority centred, a detail panel with the clip, select then buy`.

### Task 4: Remembrance mode (mission side)

**Files:**
- Modify: `src/game/rules.gd` (`var free := false`), `src/game/mission.gd` (`var remembrance := ""`), 
  `src/game/mission/mission_book.gd` (the def)
- Create: `src/game/ui/memory_overlay.gd` (`class_name MemoryOverlay`) -- the memory look and its controls
- Test: `tests/test_remembrance.gd` (register)

**Interfaces:**
- Produces:
  - `Rules.free: bool` -- when true: `cast()` leaves the slot's cooldown at 0 (mode cooldowns too); `time_left` never falls and
    the mission never finishes by clock, escape or fall (no `finished`, no `won`). `busy_left()` still applies.
  - `MissionBook.REMEMBRANCE := "remembrance"`; `MissionBook.remembrance() -> MissionDef` -- city `&"capital"`, `slots = 1`,
    no objectives (`make_objectives` returns `[]`), `camera_at = CapitalCity.MARKET_SQUARE.get_center()`, no intro sweep,
    name "Remembrance". Never listed by `dev_missions()`, `tier_missions()` or the board.
  - `Mission.remembrance: String` -- the power key; set before `add_child`. When non-empty: loadout `[key]`, `rules.free = true`,
    no score, no results, `finished` never emitted, a `MemoryOverlay` added.
  - `Mission.set_memory_level(level: int) -> void` -- 1-5 (1 only for a key without levels); sets `levels[key]` and the rules'.
  - `Mission.memory_night: bool` (set before start) -- the look: NIGHT with `NightRules` when true, DAY otherwise.
  - `MemoryOverlay`: a pale vignette and a faint desaturating tint over the world (not over the HUD), a top banner
    "REMEMBRANCE . <power name> . Level n", a 1-5 level picker (keys 1-5 and clickable boxes; boxes above the key's max dim),
    a DAY/NIGHT toggle (key N), and "Esc . leave" text. Emits `level_picked(level: int)` and `night_toggled(night: bool)`.
- [ ] **Step 1: Failing tests** `tests/test_remembrance.gd` (build the def and a Rules the way existing Rules tests do; read
  `tests/test_rules*.gd` for the pattern):
  - `_def`: `remembrance()` is capital, 1 slot, no objectives; its id is absent from `dev_missions()`, `tier_missions(t)` for
    t 1-5 and the board list.
  - `_free_cast`: with `free = true`, casting slot 0 twice in a row (after `busy_left()` reaches 0) succeeds both times and
    `cooldown_left(0) == 0.0`; with `free = false` the second is refused "cooldown" (today's behaviour).
  - `_no_clock`: `free = true`, advance 400 s -> `time_left` unchanged and `finished == false`.
  - `_level_pick`: `set_memory_level(5)` on wisp -> `rules.level_of(0) == 5`; on thorns -> stays 1.
  - `_overlay_keys`: key 3 emits `level_picked(3)`; N emits `night_toggled(true)` then `(false)`.
- [ ] **Step 2: Run** -- failures. **Step 3: Implement.** **Step 4: Run** this suite and `bash tools/dev/run_suite_parallel.sh 8`.
  Then `bash tools/dev/refs_check.sh --only='^(digest|crowd_check|god_|hunt_)'` -- all OK (free defaults to false).
- [ ] **Step 5: Commit** `feat: Remembrance -- a free, endless memory of the Capital for one power at a chosen level`.

### Task 5: Wiring Remembrance into the game

**Files:**
- Modify: `src/game/game.gd` (routes, `_build_mission`, `_on_tree_action`, `_open_pause`, `--show=remembrance`),
  `src/game/ui/pause_menu.gd` (a remembrance menu: RESUME, LEAVE)
- Test: `tests/test_remembrance_game.gd` (register) -- drive a `Game` the way the existing game/flow tests do
  (read `tests/test_*endless*.gd` / `tests/test_game*.gd` for the pattern)

**Interfaces:**
- Consumes: Task 3 `action "remember"`, `selected_key()`, `remember_level()`, `state()`; Task 4 `Mission.remembrance`,
  `set_memory_level`, `memory_night`, `MemoryOverlay` signals.
- Produces: routes `"tree:remember": Screen.MISSION` and `"pause:leave_memory": Screen.TREE`; `Game` vars
  `_remembering := ""` (the key), `_memory_level := 1`, `_memory_night := false`, `_tree_state := {}`.
  On "remember": store `tree.state()`, the key and level, go to MISSION. `_build_mission()` with `_remembering != ""` builds
  only the Remembrance mission: no `night_def`, no `clock_started`/`decided` connections, `levels = {key: level}`,
  `restart_locked = true`; it must return before any `_in_endless` branch. A level pick calls `set_memory_level`; a night
  toggle rebuilds the mission with the same key and level. The pause in Remembrance offers RESUME and LEAVE only; LEAVE frees
  the mission, clears `_remembering`, and opens TREE with `setup(god, _tree_state)`. The tree's own Back still goes to the hub.
- [ ] **Step 1: Failing tests:**
  - `_routes`: the two routes exist.
  - `_remembrance_leaves_save_alone`: an Endless god written to a test slot file; read its bytes; open the tree, select a
    Tier 3 key the god cannot buy, "remember", cast it 3 times, toggle night, pick level 5, pause, LEAVE; the file's bytes are
    identical, `god.in_night == ""`, `god.night` unchanged.
  - `_leave_returns_to_selection`: centre the right neighbour, select its (2, 1), remember, leave -> the tree's `state()` equals
    what it was.
  - `_pause_menu`: the Remembrance pause has exactly RESUME and LEAVE.
- [ ] **Step 2: Run** -- failures. **Step 3: Implement.** **Step 4: Run** this suite, `test_skill_tree`, and the full suite
  `bash tools/dev/run_suite_parallel.sh 8`. Photograph `--show=tree` and `--show=remembrance` and look at both.
- [ ] **Step 5: Commit** `feat: Remembrance from the Skill Tree -- try a power in the Capital, Leave returns to the same spot`.

## Landing (controller, after the final review)

`bash tools/dev/land.sh` steps by hand as in the Dominion levels landing: import; full suite; all references
(`bash tools/dev/refs_check.sh --jobs=4`, expect 507/508 with only bread_play_3 at -133947279); FLOW alone (expect 209/0);
fetch and check feat/god-progression's tip; ask the user before the ff and push.
