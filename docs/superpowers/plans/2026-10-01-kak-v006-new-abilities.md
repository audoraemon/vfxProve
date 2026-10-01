# KAK v0.06 New Abilities Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** four small-radius powers of new kinds:
- Will-o'-Wisp (control);
- Thornwall (route control);
- Discord (quiet);
- Pestilence (curse).

The Prepare screen gets tabs by kind.

**Architecture:** each power is an `FxTimeline` effect script that acts through objects the context already reaches: `ctx.field` for people, `ctx.env` for structures. The crowd's managers react through signals and person state. Lingering effects lock casting only briefly (`FxTimeline.busy`). Temporary structures (thorns) go through new environment signals, which the walk grid and the crowd follow.

**Tech Stack:** Godot 4.7.2 (GDScript, gl_compatibility); headless tests in `tests/run_all.gd`; scripted scenarios in `tools/dev/behaviour_check.gd`; Python/PIL for icons.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-10-01-kak-v006-new-abilities-design.md`. Baseline tag `kak-v0.05`.
- **Numbers (spec §1):**
  - Will-o'-Wisp: 10 DP, 25 s, click, `WISP_TIME` 12, `LURE_REACH` 6, `LURE_MAX` 25.
  - Thornwall: 14 DP, 30 s, drag, `THORN_LENGTH` 3, `THORN_SEGMENTS` 5, `THORN_TIME` 25, +1 alarm, Clear priority 70, `CLEAR_TIME` 5.
  - Discord: 10 DP, 20 s, click, `DISCORD_R` 1.2, `DISCORD_TIME` 15.
  - Pestilence: 16 DP, 40 s, click, `INFECT_MAX` 3, `INFECT_R` 0.8, `PLAGUE_LIFE` 30, `SPREAD_EVERY` 3, `SPREAD_R` 0.6, `SPREAD_CHANCE` 0.3, `PLAGUE_MAX` 60, sick pace 70%.
- **Kinds and tabs:** `cataclysm`, `control`, `quiet`, `curse` (tab titles CATACLYSM, CONTROL, QUIET, CURSE).
- **Cast lock:** Wisp and Thornwall 1.0 s, Discord 0.6 s, Pestilence 0.8 s. Every existing power keeps its whole-duration lock.
- **Repository rules:**
  - Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
  - `git add` explicit paths only.
  - Never commit `default_bus_layout.tres` (restore it with `git checkout -- default_bus_layout.tres`), anything under `captures/`, `.codex/`, `concepts/`, or `docs/HUM_Game_Design_Document_v1.docx`.
  - Push with `git -c credential.helper= -c 'credential.helper=!"/c/Program Files/GitHub CLI/gh.exe" auth git-credential' push origin feat/vfx-proof <tag>`.
- **Commands:**
  - `G=/f/Godot/Godot_v4.7.2-stable_win64_console.exe`.
  - **Re-import:** `timeout 180 $G --headless --editor --path . --import`, needed after adding a `class_name`.
  - **Tests:** `timeout 500 $G --headless --path . --script res://tests/run_all.gd 2>&1 | grep -v '^\s*at:' | grep -n "FAIL\|SCRIPT ERROR\|Parse Error\|checks="`. Expected: `checks=N failures=0`.
  - **Digest:** `$G --headless --path . -s tools/dev/state_digest.gd` must print `digest=61267b7e90524d800bf1c3473a71146b`.
  - **Crowd check:** `$G --headless --path . --fixed-fps 60 -s tools/dev/crowd_check.gd`. Baseline `-346732806`; any change must be explained.
  - **Mission test:** `SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test --difficulty=<tier>`.
  - **Bench:** `$G --path . --audio-driver Dummy --scene res://scenes/mission.tscn -- --bench`, alternating with `kak-v0.05` in a scratchpad worktree with `.godot` copied in. At most a 5-fps loss.
- **Icons and clips:** every power must have an icon (84 px, plus a 42 px HUD copy) and a preview clip, or `test_power_book` and `test_draft` fail. So **each power's milestone adds its own icon and clip** (the spec put them all in M6; moved forward so the gates hold at every milestone).

---

## File structure

| File | Responsibility |
|---|---|
| `src/fx/fx_timeline.gd` | Adds `busy`: seconds a cast locks the slots (−1 = the whole duration) |
| `src/game/rules.gd` | `busy_left()` honours `busy`; `POWER_KINDS` for plague |
| `src/game/power_book.gd` | 4 new entries; a `kind` on every entry; `KINDS`; `of_kind()` |
| `src/environment/environment_field.gd` | `structure_added` / `structure_removed` signals |
| `src/game/town/walk_grid.gd` | Stamps an added structure; reopens a removed one |
| `src/game/crowd/crowd.gd` | Clears the gate spot cache on either; the thorn alarm; plague manager wiring |
| `src/game/ui/prepare_screen.gd` | Tabs, grid by tab, loadout bar |
| `src/game/crowd/person.gd` | `lure()`, `confuse()` with Mind/Intent CONFUSED, `infect()`/`sick_left`, sick and confused looks |
| `src/fx/control/will_o_wisp.gd` | Will-o'-Wisp effect (class `WillOWisp`) |
| `src/fx/control/thornwall.gd` | Thornwall effect (class `ThornwallFx`) |
| `src/environment/art/prop_art.gd` | `_thorns()` art for tree-kind structures tagged `thorns` |
| `src/game/crowd/engineer_manager.gd` | `Job.CLEAR` |
| `src/fx/quiet/discord.gd` | Discord effect (class `DiscordFx`) |
| `src/game/crowd/plague_manager.gd` | Pestilence spread and deaths (class `PlagueManager`) |
| `src/fx/curse/pestilence.gd` | Pestilence effect (class `PestilenceFx`) |
| `src/game/targeting.gd` | `AREAS` for the four, plus aim previews (lure reach, thorn line, Discord ring, infect ring) |
| `tools/dev/make_power_icons.py` | Renamed from `make_quiet_icons.py`; paints all the procedural icons |
| `tools/dev/behaviour_check.gd` | `clip` scenario (records a power's clip in the mission); `powers` scenario |
| `tests/test_cast_lock.gd`, `test_town_signals.gd`, `test_wisp.gd`, `test_thornwall.gd`, `test_discord.gd`, `test_plague.gd` | New tests |

---

## Milestone 1 — Framework

### Task 1: The short cast lock

**Files:**
- Modify: `src/fx/fx_timeline.gd` (vars), `src/game/rules.gd` (`busy_left`)
- Test: `tests/test_cast_lock.gd` (new), registered in `tests/run_all.gd`

**Interfaces:**
- Produces:
  - `FxTimeline.busy: float` (default −1.0);
  - `Rules.busy_left() -> float` = `max(busy − t, 0)` when `busy >= 0`, else `max(duration − t, 0)`.

- [ ] **Step 1: Write the failing test** — `tests/test_cast_lock.gd`:

```gdscript
extends RefCounted
## v0.06: a lingering power locks the other slots only for its `busy` seconds, not its whole run; one without
## `busy` keeps the whole-duration lock.


static func run(t) -> void:
	var rules := Rules.new()
	var fx := FxTimeline.new()
	fx.duration = 25.0
	rules._playing = fx
	t.check(is_equal_approx(rules.busy_left(), 25.0), "without busy, the whole run locks (%.1f)" % rules.busy_left())
	fx.busy = 1.0
	t.check(is_equal_approx(rules.busy_left(), 1.0), "with busy, only that long (%.1f)" % rules.busy_left())
	fx.t = 1.5
	t.check(rules.busy_left() == 0.0, "and then the slots are free while it lingers")
	fx.free()
	rules.free()
```

Register `"res://tests/test_cast_lock.gd",` after `"res://tests/test_rules.gd",` in `tests/run_all.gd`.

- [ ] **Step 2: Run the tests.** Expected: a parse error, because `FxTimeline` has no `busy`.

- [ ] **Step 3: Implement.** In `src/fx/fx_timeline.gd`, after `var duration := 5.0`:

```gdscript
## Seconds a cast of this effect keeps the other slots locked ("one power at a time"); -1 = its whole duration. A
## power that lingers (a wisp, a thorn wall) locks only while it is cast (v0.06).
var busy := -1.0
```

In `src/game/rules.gd`, replace the body of `busy_left()`:

```gdscript
func busy_left() -> float:
	if not is_instance_valid(_playing) or _playing.finished:
		return 0.0
	var lock := _playing.busy if _playing.busy >= 0.0 else _playing.duration
	return maxf(lock - _playing.t, 0.0)
```

and add to its doc comment: `A lingering effect sets FxTimeline.busy to lock only while it is cast.`

- [ ] **Step 4: Run the tests.** Expected: `failures=0`; `test_rules`' busy checks still pass (no `busy` set).

- [ ] **Step 5:** Fold into the M1 commit (Task 5).

### Task 2: Power kinds

**Files:**
- Modify: `src/game/power_book.gd`
- Test: `tests/test_power_book.gd`

**Interfaces:**
- Produces:
  - every `POWERS` entry has `"kind"`;
  - `PowerBook.KINDS := ["cataclysm", "control", "quiet", "curse"]`;
  - `PowerBook.KIND_TITLES := ["CATACLYSM", "CONTROL", "QUIET", "CURSE"]`;
  - `static func of_kind(kind: String) -> PackedStringArray` (keys in POWERS order);
  - `static func kind_of(key: String) -> String`.

- [ ] **Step 1: Failing test.** Append to `tests/test_power_book.gd`'s `run`:

```gdscript
	var kinds_ok := true
	for p: Dictionary in PowerBook.POWERS:
		kinds_ok = kinds_ok and PowerBook.KINDS.has(String(p.get("kind", "")))
	t.check(kinds_ok, "every power has a kind")
	t.check(Array(PowerBook.of_kind("quiet")) == ["doom", "blight"] and PowerBook.kind_of("nova") == "cataclysm",
		"powers by kind (quiet: %s)" % [PowerBook.of_kind("quiet")])
```

- [ ] **Step 2: Run.** Expected: a parse error, because `KINDS` is undefined.

- [ ] **Step 3: Implement.**
  - Add `"kind": "cataclysm"` to the eleven destruction entries and `"kind": "quiet"` to doom and blight.
  - Then add:

```gdscript
## The draft's tabs (v0.06): what a power is for.
const KINDS := ["cataclysm", "control", "quiet", "curse"]
const KIND_TITLES := ["CATACLYSM", "CONTROL", "QUIET", "CURSE"]


static func of_kind(kind: String) -> PackedStringArray:
	var out := PackedStringArray()
	for p: Dictionary in POWERS:
		if String(p.get("kind", "")) == kind:
			out.append(p.key)
	return out


static func kind_of(key: String) -> String:
	return String(get_power(key).get("kind", ""))
```

- [ ] **Step 4: Run.** Expected: pass.

### Task 3: Structures added and removed

**Files:**
- Modify: `src/environment/environment_field.gd`, `src/game/town/walk_grid.gd`, `src/game/crowd/crowd.gd`
- Test: `tests/test_town_signals.gd` (new), registered after `test_quiet.gd`

**Interfaces:**
- Produces:
  - `EnvironmentField.structure_added(s)`, emitted at the end of `add_structure`;
  - `EnvironmentField.structure_removed(s)`, emitted in `remove(s)` before the node is freed (the structure is still valid during the signal);
  - `WalkGrid` stamps added structures (`refresh`) and reopens removed ones (`_reopen`);
  - `Crowd` clears `_spots` on both.

- [ ] **Step 1: Failing test** — `tests/test_town_signals.gd`:

```gdscript
extends RefCounted
## v0.06: a structure added after the town is built closes the walk grid under it, and removing it opens it again;
## the crowd forgets the gate queue spots it had worked out, so they are found again round the change.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()
	var at := Vector2(2.7, 11.0)  # the Main Gate's plaza
	t.check(grid.walkable(at), "open ground first")
	crowd.queue_spots(town.gates[0])
	var v := grid.version
	var s := env.add_structure(Rect2(at - Vector2(0.3, 0.3), Vector2(0.6, 0.6)), 14.0, Structure.Kind.TREE, &"thorns", &"thorns")
	t.check(not grid.walkable(at) and grid.version > v and crowd._spots.is_empty(),
		"an added structure closes its ground, and the gate spots are worked out again")
	env.remove(s)
	t.check(grid.walkable(at), "removed, the ground opens again")
	crowd.clear()
	world.free()
```

- [ ] **Step 2: Run.** Expected: FAIL, "an added structure closes its ground".

- [ ] **Step 3: Implement.**

`environment_field.gd`, next to `structure_restored`:

```gdscript
## A structure built after the town (v0.06's thorns), and one taken away again (remove()).
signal structure_added(s: Structure)
signal structure_removed(s: Structure)
```

At the end of `add_structure`, before `return s`, add `structure_added.emit(s)`. At the start of `remove(s)`, add `structure_removed.emit(s)` (before the free).

`walk_grid.gd`, in `setup` after the restored connection:

```gdscript
	env.structure_added.connect(refresh)
	env.structure_removed.connect(_reopen)
```

and add, next to `_on_destroyed` (factor the shared body):

```gdscript
## A structure taken away (a thorn wall withering): its ground opens as a fallen building's does.
func _reopen(s: Structure) -> void:
	_on_destroyed(s, &"")
```

`_on_destroyed` already guards on `s == _bridge`, so this reuse is safe.

`crowd.gd`, in `setup` next to `structure_blighted`:

```gdscript
	env.structure_added.connect(func(_s: Structure) -> void: _spots.clear())
	env.structure_removed.connect(func(_s: Structure) -> void: _spots.clear())
```

- [ ] **Step 4: Run.** Expected: pass; the digest is unchanged (no structure is added after the build in the sandbox script).

### Task 4: Prepare tabs and the loadout bar

**Files:**
- Modify: `src/game/ui/prepare_screen.gd`
- Test: `tests/test_draft.gd`

**Interfaces:**
- Consumes: `PowerBook.KINDS`, `KIND_TITLES`, `of_kind()`, `kind_of()`.
- Produces:
  - `PrepareScreen.tab: int`;
  - `static func tab_rect(i: int) -> Rect2`;
  - `static func cell_rect(i: int) -> Rect2` (now for the open tab's cards);
  - `static func slot_rect(i: int) -> Rect2` (loadout bar slots 0–3);
  - `const MANIFEST_RECT: Rect2`;
  - `func shown() -> PackedStringArray` (the open tab's keys);
  - `hit()` also returns `"tab:<i>"`, `"slot:<i>"`.

Layout (640×360):
- `TAB_AT = Vector2(196, 40)`, tabs 104×16 with a gap of 4;
- `GRID_AT = Vector2(196, 60)`, `CARD = Vector2(140, 50)`, `GAP = 6`, 3 columns, 4 rows (12 cells; Cataclysm has 11);
- the loadout bar `LOADOUT_BAR = Rect2(196, 280, 432, 32)`: four slots `Rect2(200 + i·88, 282, 84, 28)`, then `MANIFEST_RECT = Rect2(552, 282, 76, 28)`;
- `STRIP` is unchanged at y 318.

- [ ] **Step 1: Failing test.** Replace the grid block in `tests/test_draft.gd` (the "thirteen cards and the MANIFEST cell" check) with:

```gdscript
	# The Prepare screen (v0.06): tabs by kind, the open tab's cards, the loadout bar with MANIFEST -- none
	# overlapping, all above the difficulty strip.
	var screen := Rect2(0, 0, 640, PrepareScreen.STRIP.position.y)
	var boxes: Array[Rect2] = []
	for i in PowerBook.KINDS.size():
		boxes.append(PrepareScreen.tab_rect(i))
	var most := 0
	for kind in PowerBook.KINDS:
		most = maxi(most, PowerBook.of_kind(kind).size())
	for i in most:
		boxes.append(PrepareScreen.cell_rect(i))
	for i in Draft.SLOTS:
		boxes.append(PrepareScreen.slot_rect(i))
	boxes.append(PrepareScreen.MANIFEST_RECT)
	var bad := 0
	for i in boxes.size():
		if not screen.encloses(boxes[i]):
			bad += 100
		for j in range(i + 1, boxes.size()):
			if boxes[i].intersects(boxes[j]):
				bad += 1
	t.check(bad == 0, "tabs, the largest tab's %d cards and the loadout bar fit without touching (%d)" % [most, bad])
	var prep := PrepareScreen.new()
	prep.setup(PackedStringArray(["doom", "heaven"]), 0, "")
	t.check(prep.tab == PowerBook.KINDS.find("quiet") and Array(prep.shown()) == Array(PowerBook.of_kind("quiet")),
		"the screen opens on the first pick's tab (%d)" % prep.tab)
	t.check(prep.hit(PrepareScreen.tab_rect(0).get_center()) == "tab:0"
		and prep.hit(PrepareScreen.slot_rect(1).get_center()) == "slot:1"
		and prep.hit(PrepareScreen.cell_rect(0).get_center()) == String(PowerBook.of_kind("quiet")[0]),
		"tabs, slots and the open tab's cards answer the mouse")
	prep.free()
```

- [ ] **Step 2: Run.** Expected: a parse error (`tab_rect` undefined).

- [ ] **Step 3: Implement** in `prepare_screen.gd`:
  - **Constants** as in the layout above. `GRID_AT` moves to y 60.
  - **`var tab := 0`.** In `setup()`, after `draft.preselect`: `tab = maxi(PowerBook.KINDS.find(PowerBook.kind_of(draft.picks[0])), 0) if not draft.picks.is_empty() else 0`.
  - **`shown()`** returns `PowerBook.of_kind(PowerBook.KINDS[tab])`.
  - **`hit()`:**
    1. tabs → `"tab:%d"`;
    2. `shown()` cells → the key;
    3. loadout slots → `"slot:%d"`;
    4. `MANIFEST_RECT` → `"manifest"`;
    5. the difficulty arrows, as before.
  - **`_on_gui_input` clicks:**
    - `"tab:"` sets `tab` (with `UiSound.play(&"ui_click")`) and redraws;
    - `"slot:i"` with a pick in it unpicks it (`draft.toggle(draft.picks[i])`);
    - the rest is unchanged.
  - **`_unhandled_input`:** `KEY_TAB` steps the tab (with Shift backwards).
  - **`_draw_ui`:**
    - `_draw_tabs()`: each tab is a panel with its title and count, gold-framed when open, with a gold 3×3 dot at its right end when it holds a pick;
    - the cards of `shown()` via `_draw_card(i, key)` (it takes the key and the cell index);
    - `_draw_loadout()`: four slots, each with the HUD icon and short name (first word) or "—", its number badge, and a frame; then MANIFEST in `MANIFEST_RECT`, with the same colours as before;
    - `_draw_profile()`.
  - **Remove** the old `_draw_manifest()` cell drawing.
  - **The header comment** describes the tabs.

- [ ] **Step 4: Run** the tests and FLOW: `$G --path . --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep "FLOW"`. Expected: `failures=0` and FLOW all ok (24/24).

- [ ] **Step 5: Capture** the screen: `SCENE=res://scenes/game.tscn bash tools/capture.sh --show=prepare --capture`. Check `captures/screen_prepare.png`: tabs, cards and bar all readable.

### Task 5: M1 gates and commit

- [ ] Run the full tests, the digest, crowd_check (expected unchanged, −346732806) and the mission test (Organized).
- [ ] Commit:

```bash
git checkout -- default_bus_layout.tres
git add src/fx/fx_timeline.gd src/game/rules.gd src/game/power_book.gd src/environment/environment_field.gd src/game/town/walk_grid.gd src/game/crowd/crowd.gd src/game/ui/prepare_screen.gd tests/run_all.gd tests/test_cast_lock.gd tests/test_cast_lock.gd.uid tests/test_town_signals.gd tests/test_town_signals.gd.uid tests/test_power_book.gd tests/test_draft.gd docs/superpowers/plans/2026-10-01-kak-v006-new-abilities.md
git commit -m "feat: draft tabs by kind, short cast locks, structure signals (v0.06 M1)"
git tag kak-v006-m1
```

---

## Milestone 2 — Will-o'-Wisp

### Task 6: Person.lure

**Files:** `src/game/crowd/person.gd`; test `tests/test_wisp.gd` (new).

**Interfaces:**
- Produces:
  - `Person.lure(at: Vector2, seconds: float) -> bool`. True when the person came: a citizen not running, sheltering, inside, on duty or dead. Its mind becomes OBSERVE, it walks to `at`, and its watch timer is `seconds`.
  - `Person.LURABLE := [Mind.CALM, Mind.RECOVER, Mind.OBSERVE, Mind.REGROUP]`.

```gdscript
const LURABLE := [Mind.CALM, Mind.RECOVER, Mind.OBSERVE, Mind.REGROUP]


## Drawn by a Will-o'-Wisp (v0.06): walk to `at` and stand staring for `seconds`, then back to the day.
func lure(at: Vector2, seconds: float) -> bool:
	if soldier or inside or state == State.DEAD or not mind in LURABLE:
		return false
	mind = Mind.OBSERVE
	awareness = maxi(awareness, Awareness.CONCERNED) as Awareness
	_threat = at
	_observe_left = seconds
	walk_speed = _mind_speed()
	set_goal(at)
	return true
```

The OBSERVE timer runs while the person walks; on reaching the spot, `_pick_target` already stands an OBSERVE person still.

### Task 7: The effect, the entry and the aim preview

**Files:**
- Create: `src/fx/control/will_o_wisp.gd` (class `WillOWisp`)
- Modify: `power_book.gd`, `targeting.gd`

PowerBook entry, placed by DP among the others:

```gdscript
	{"key": "wisp", "name": "Will-o'-Wisp", "path": "res://src/fx/control/will_o_wisp.gd",
		"dp": 10, "cooldown": 25.0, "aim": "click", "shape": "lures up to 25 calm people, 12 s", "quiet": true,
		"kind": "control"},
```

`targeting.gd`: `AREAS["wisp"] = {"shape": "circle", "r": 1.6, "roam": 6.0}` (the ring and the reach). Draw rings at the people it would draw, using `WillOWisp.drawn(_crowd._field, _press)`.

`will_o_wisp.gd`:

```gdscript
class_name WillOWisp
extends FxTimeline
## Will-o'-Wisp (v0.06): a pale light hovers at the aim for WISP_TIME. Up to LURE_MAX calm citizens within
## LURE_REACH, nearest first, walk to it and stand staring in a loose ring (Person.lure()), then go back to their
## day. No danger and no alarm: curiosity. It locks the other slots only while it is cast.

const WISP_TIME := 12.0
const LURE_REACH := 6.0
const LURE_MAX := 25
const RING := Vector2(0.8, 1.6)
const GLOW := [Color("e8fff4"), Color("9fe8d0"), Color("5cb8a8"), Color("2a6a6a")]


## Who it would draw from `at`: calm citizens within reach, nearest first, LURE_MAX at most.
static func drawn(field: EnemyField, at: Vector2) -> Array[Person]:
	var out: Array[Person] = []
	for e in field.in_radius(at, LURE_REACH):
		var p := e as Person
		if p != null and not p.soldier and not p.inside and p.mind in Person.LURABLE:
			out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(at) < b.ground_pos.distance_squared_to(at))
	return out.slice(0, LURE_MAX)


func _build() -> void:
	duration = WISP_TIME
	busy = 1.0
	var rng := ctx.rng
	for p in drawn(ctx.field, origin):
		var a := rng.randf() * TAU
		p.lure(origin + Vector2(cos(a), sin(a)) * rng.randf_range(RING.x, RING.y), WISP_TIME - 0.5)
	ctx.play(&"grav_shimmer", origin, -12.0)
	var light := FxParts.ground_light(self, origin, 1.6, Color(0.6, 1.0, 0.85), 0.8)
	light.set_param("flicker", 1.0)
	var motes := FxParts.emitter(self, ctx.overhead, Iso.ground_to_screen(origin) + Vector2(0, -14),
		PixelParticles.Shape.SQUARE, GLOW, 6.0, WISP_TIME - 1.0,
		{"radius": 4.0, "speed": Vector2(2, 8), "alt": Vector2(0, 4), "alt_speed": Vector2(6, 14),
		"life": Vector2(0.8, 1.4), "size": Vector2(1, 1)})
	motes.gravity = -8.0


## The core: a soft orb that bobs and flickers, fading at the end.
func _fx_process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var fade := clampf(minf(t / 0.5, (duration - t) / 1.0), 0.0, 1.0)
	var at := Iso.ground_to_screen(origin) + Vector2(0, -14.0 + sin(t * 2.2) * 2.0) - global_position
	var flick := 0.85 + 0.15 * sin(t * 17.0) * sin(t * 5.3)
	for k in 3:
		var c: Color = GLOW[k]
		c.a = fade * flick * (0.35 + 0.3 * k)
		draw_circle(at, 6.0 - 2.0 * k, c)
```

(FxTimeline is a Node2D under `ctx.overhead`; `global_position` is the origin of its local drawing.)

### Task 8: Tests, icon, clip and gates

`tests/test_wisp.gd`:

```gdscript
extends RefCounted
## v0.06 Will-o'-Wisp: calm citizens within reach walk to the light and stand staring; the fleeing, the sheltering,
## soldiers and people on duty do not come; at most LURE_MAX; afterwards they go back to their day.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()
	var at := Vector2(0.8, 2.0)
	var i := 0
	for p in crowd.citizens + crowd.soldiers:
		p.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var calm: Array[Person] = []
	for k in 30:
		var p: Person = crowd.citizens[k]
		p.mind = Person.Mind.CALM
		p.ground_pos = at + Vector2(0.15 * float(k % 10) - 0.7, 0.3 * float(k / 10) + 1.0)
		calm.append(p)
	calm[0].mind = Person.Mind.FLEE
	calm[1].mind = Person.Mind.DUTY
	var soldier: Person = crowd.soldiers[0]
	soldier.ground_pos = at + Vector2(0.5, 0.5)
	var drawn := WillOWisp.drawn(field, at)
	t.check(drawn.size() == WillOWisp.LURE_MAX and calm[0] not in drawn and calm[1] not in drawn and soldier not in drawn,
		"it draws calm citizens only, %d at most (%d)" % [WillOWisp.LURE_MAX, drawn.size()])
	var p2: Person = drawn[0]
	t.check(p2.lure(at, 10.0) and p2.mind == Person.Mind.OBSERVE and p2.goal() != Vector2.INF,
		"a lured citizen walks to the light, watching it")
	p2.ground_pos = p2.goal()
	p2._goal = Vector2.INF
	p2.frame(9.0)
	t.check(p2.mind == Person.Mind.OBSERVE, "and stands there")
	p2.frame(2.0)
	t.check(p2.mind == Person.Mind.RECOVER, "then goes back to its day")
	crowd.clear()
	world.free()
```

(`Person.frame(delta)` is the crowd's per-person step; if a single frame skips thinking at half rate, call it twice.)

- **Icon:** add `wisp()` to `tools/dev/make_power_icons.py`: a pale orb with a soft halo and motes over a dark teal field.
- **Clip:** add the `clip` scenario to `behaviour_check.gd`:
  - `--power=<key>`: the mission at Prepared with the loadout `[key, "heaven", "cinder", "nova"]`;
  - after 20 s of calm, cast slot 0 at `--at=x,y` (default the market, 0.8,2), with the camera snapped there at zoom 1.5;
  - record 16 frames over `--seconds` (default the effect's duration) into `assets/clips/<key>.png`, using the sandbox's sheet layout (`PowerBook.CLIP_SIZE`, `CLIP_COLUMNS`, crop the screen middle at 2× clip size).
- **Gates and commit:** `feat: Will-o'-Wisp (v0.06 M2)`, tag `kak-v006-m2`.

---

## Milestone 3 — Thornwall

### Task 9: Thorn segments, art and the effect

- **Art:** in `prop_art.gd`, `draw()` for `Kind.TREE`: `if s.art_tag == &"thorns": _thorns(s); return` before the tree.

```gdscript
## A thorn wall's segment (v0.06): a tangle of dark stems with thorns and dark berries, as high as a person.
static func _thorns(s: Structure) -> void:
	ArtKit.begin()
	var r := s.footprint
	var stem := Color("2a2a1a")
	var leaf := Color("3d4a24")
	for k in 7:
		var a := r.position + r.size * Vector2(ArtKit.hash01(s.rng.seed, k * 3), ArtKit.hash01(s.rng.seed, k * 3 + 1))
		var b := a + Vector2(ArtKit.hash01(s.rng.seed, k * 3 + 2) - 0.5, 0.0) * 0.4
		var h := 8.0 + 6.0 * ArtKit.hash01(s.rng.seed, k + 40)
		ArtKit.line(s._gp(a, 0.0), s._gp(b, h), stem)
		ArtKit.line(s._gp(a, 0.0) + Vector2(1, 0), s._gp(b, h) + Vector2(1, 0), leaf)
		ArtKit.poly(PackedVector2Array([s._gp(b, h) + Vector2(-1, 0), s._gp(b, h) + Vector2(1, 0),
			s._gp(b, h) + Vector2(0, -2)]), Color("6a1830"), 0.0)
	ArtKit.flush(s)
```

- **Effect:** `src/fx/control/thornwall.gd` (class `ThornwallFx`).
  - `THORN_LENGTH` 3, `THORN_SEGMENTS` 5, `SEG` 0.6, `THORN_TIME` 25, `busy` 1.0, `duration` = `THORN_TIME`.
  - **The segments:** the centre of segment k is `origin + dir * (−L/2 + L·(k+0.5)/N)`, each a `Rect2(centre − (0.3,0.3), (0.6,0.6))`, added with `ctx.env.add_structure(rect, 14.0, Structure.Kind.TREE, &"thorns", &"thorns")`.
  - **Before adding each:** move every person within `rect.grow(0.15)` to `grid.nearest_walkable` of a point 0.5 beyond the rect. The effect has no grid, so use `rect.get_center() + (p.ground_pos − rect.get_center()).normalized() * 0.65` and keep it if `not ctx.env.blocked(it)`.
  - **Growth:** a green dust burst at each segment.
  - **Withering:** at `THORN_TIME`, `ctx.env.remove(s)` for each segment still valid and standing.
- `targeting.gd`: `AREAS["thorns"] = {"shape": "lane", "length": 3.0, "half": 0.3, "centred": true}`. The PowerBook entry uses aim "drag", kind control, 14 DP, 30 s, and `"quiet": true` (its alarm comes from Crowd).

### Task 10: The crowd and the engineers

**`crowd.gd`:** `const THORN_ALARM := 1.0`. In the `structure_added` handler, when `s.role == &"thorns"`:
- the first segment of a wall within 1 s adds `THORN_ALARM` (keep `_thorn_alarm_at`, so a 5-segment wall adds it once);
- calm citizens within 3 of the segment `observe(s.center())`.

In `_on_structure_destroyed`, add at the top `if s.role == &"thorns": return` (a burnt segment is no incident, threat or alarm). The walk grid still opens it.

**`engineer_manager.gd`:**
- `enum Job { NONE, CITADEL, ROUTE, LANDMARK, HOUSE, CLEAR }`, with `PRIORITY[Job.CLEAR] = 70.0` and `const CLEAR_TIME := 5.0`.
- `jobs()`: for each standing `s.role == &"thorns"`, `_add_job(out, Job.CLEAR, s, s.footprint, false)`.
- `_valid()`: `CLEAR` is valid while the segment is valid and not destroyed (and still in `env.structures()`; check `_env.structures().has(s)`).
- `_work()`: `CLEAR` advances `team.progress += delta / CLEAR_TIME`; at 1, `_env.remove(s)`, then `team.job = {}` and `_think_in = 0.0`.

### Task 11: Tests, icon, clip and gates

`tests/test_thornwall.gd`:
- after a cast through `FxTimeline.cast(load(path), ctx, at, {"dir": Vector2(1,0)})` there are 5 segments (a minimal `FxContext` with env, field, an rng and an `overhead` node);
- the grid is closed at each;
- a person standing on the line was moved off it;
- the alarm rose by 1 once (the crowd's `structure_added`);
- advancing the effect's clock past `THORN_TIME` (`fx._process(THORN_TIME)`) removes them and opens the grid;
- an engineer team at City Emergency (Prepared) takes a `CLEAR` job and removes a segment after `CLEAR_TIME` at the site;
- destroying a segment adds no alarm.

Icon: a thorn tangle (dark green stems, red thorns) on a dusk field. Clip: `--power=thorns --at=2.7,13.5` (the Main Gate's mouth). Commit `feat: Thornwall (v0.06 M3)`, tag `kak-v006-m3`.

---

## Milestone 4 — Discord

### Task 12: The confused mind

**`person.gd`:**
- Add `CONFUSED` to `enum Mind` (at the end), and `CONFUSED` to `enum Intent` (at the end). `intent()` maps `Mind.CONFUSED` to `Intent.CONFUSED`. `_mind_speed()` returns `WALK_SPEED * 0.7 * pace` for CONFUSED.
- Vars: `_confused_left := 0.0`, `_was_fleeing := false`.

```gdscript
## Discord (v0.06): forget everything for `seconds` -- wander near where it stands, then pick up again (flee if it was
## fleeing, else back to its day; a responder's manager takes it back once it is calm).
func confuse(seconds: float) -> void:
	if soldier or inside or state == State.DEAD:
		return
	_was_fleeing = mind == Mind.FLEE
	release_from_queue()
	passing_gate = null
	mind = Mind.CONFUSED
	_confused_left = seconds
	anchor = ground_pos
	_goal = Vector2.INF
	_path = PackedVector2Array()
	walk_speed = _mind_speed()
	_drift()
```

- In the per-person think (next to the OBSERVE timer):

```gdscript
	elif mind == Mind.CONFUSED:
		_confused_left -= delta
		if _confused_left <= 0.0:
			if _was_fleeing:
				mind = Mind.CALM
				flee()
			else:
				_recover(rng.randf_range(1.0, 2.0))
```

- `_drift()` treats CONFUSED like CALM (spread `CALM_SPREAD`), and `_pick_target` drifts it (no stand-still branch).
- `panic()` works on the confused (no change needed).
- `_draw_citizen`: while CONFUSED, a 5-px violet swirl over the head (`_px` dots in a ring at y −17, rotating with `_anim`).
- `behaviour_overlay.gd` `INTENT_COLS` gains violet `Color("b070ff")`.

### Task 13: The effect and the managers' check

- `src/fx/quiet/discord.gd` (class `DiscordFx`): `DISCORD_R` 1.2, `DISCORD_TIME` 15, `busy` 0.6, `duration` 1.2. A swirl of violet motes at the aim (inward PUFF); for each Person in `ctx.field.in_radius(origin, DISCORD_R)` that is not a soldier, `confuse(DISCORD_TIME)`.
  - Sheltered people are not in the field, so they are untouched.
  - The effect must also reach the clergy, bellkeeper and engineers: they are in the field. ✓
- PowerBook: 10 DP, 20 s, click, `quiet`, kind quiet.
- Targeting: `AREAS["discord"] = {"shape": "circle", "r": 1.2}`, and ring the people it would take.
- The managers need **no code change**. The rite (`_tend` drops non-DUTY), the bell (CLIMBING → `_wait`; it retries when the keeper is in a calm mind) and the engineers (`_work` re-sends members back in AVAILABLE minds) already handle a member leaving duty. FireManager drops responders whose mind is not ASSIST. The tests prove each.

### Task 14: Tests, icon, clip and gates

`tests/test_discord.gd`. With the Prepared crowd:
- **the rite:** chanting with 3 in the ring; confuse 2 → after a step it is in COOLDOWN, broken;
- **the bell:** CLIMBING; confuse the keeper → WAITING; after the confusion and RETRY the keeper is called again;
- **the engineers:** a working team; confuse a member → `working` false; after the confusion (RECOVER) the member is sent back;
- **evacuees:** a fleeing evacuee with a queue spot loses it while confused and flees again after;
- soldiers are untouched, and there is no threat and no alarm.

Icon: a broken violet spiral over a staring eye. Clip: `--power=discord --at=<the cathedral steps during the rite>`. The scenario starts the rite (Prepared, City Emergency at 20 s) and casts at 40 s on the ring's centre. Commit `feat: Discord (v0.06 M4)`, tag `kak-v006-m4`.

---

## Milestone 5 — Pestilence

### Task 15: The sick, and PlagueManager

**`person.gd`:**
- `var sick_left := 0.0` (seconds to live, 0 = healthy).
- `func infect(seconds: float) -> bool` refuses soldiers, the dead and the already sick, then sets `sick_left`.
- `_mind_speed()` multiplies by `SICK_PACE` (0.7) when `sick_left > 0`.
- `_draw_citizen` tints the skin and coat toward `Color("7a9a4a")` while sick, and a cough mote (a green pixel) rises every second.
- **The redraw signature:** `_art_signature` must include sickness (add `(1 if sick_left > 0.0 else 0) * SIG_SICK` with a fresh large constant) so the tint appears at once.

`src/game/crowd/plague_manager.gd`:

```gdscript
class_name PlagueManager
extends RefCounted
## Pestilence (v0.06): the sick (Person.sick_left) die PLAGUE_LIFE after they caught it, and every SPREAD_EVERY seconds
## each one gives it to each healthy citizen within SPREAD_R with SPREAD_CHANCE, up to PLAGUE_MAX sick at once.
## People sheltering together pass it on inside. Soldiers do not catch it.

const PLAGUE_LIFE := 30.0
const SPREAD_EVERY := 3.0
const SPREAD_R := 0.6
const SPREAD_CHANCE := 0.3
const PLAGUE_MAX := 60

var sick: Array[Person] = []
var deaths := 0
var _crowd: Crowd
var _field: EnemyField
var _rng := RandomNumberGenerator.new()
var _spread_in := SPREAD_EVERY


func setup(crowd: Crowd, field: EnemyField, seed_value: int) -> PlagueManager:
	_crowd = crowd
	_field = field
	_rng.seed = seed_value
	return self


func step(delta: float) -> void:
	_collect()
	if sick.is_empty():
		return
	for p in sick:
		p.sick_left -= delta
	var dead: Array[Person] = []
	for p in sick:
		if p.sick_left <= 0.0:
			dead.append(p)
	for p in dead:
		sick.erase(p)
		if p.inside and _crowd.shelters != null:
			_crowd.shelters.release(p)  # out of the shelter to die where it can be seen
		if _field.kill(p, &"plague"):
			deaths += 1
	_spread_in -= delta
	if _spread_in <= 0.0:
		_spread_in = SPREAD_EVERY
		_spread()


## Newly sick people (infected by the effect) join the list; the freed and the dead leave it.
func _collect() -> void:
	var kept: Array[Person] = []
	for p in sick:
		if is_instance_valid(p) and p.is_alive():
			kept.append(p)
	sick = kept
	for p in _crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and p.sick_left > 0.0 and not sick.has(p):
			sick.append(p)


func _spread() -> void:
	var fresh: Array[Person] = []
	for p in sick:
		if sick.size() + fresh.size() >= PLAGUE_MAX:
			break
		var near: Array = _crowd.shelters.occupants_with(p) if p.inside and _crowd.shelters != null \
			else _field.in_radius(p.ground_pos, SPREAD_R)
		for e in near:
			var q := e as Person
			if q != null and q != p and not q.soldier and q.sick_left <= 0.0 and not fresh.has(q) \
					and _rng.randf() < SPREAD_CHANCE:
				fresh.append(q)
	for q in fresh:
		q.infect(PLAGUE_LIFE)
		sick.append(q)


func clear() -> void:
	sick.clear()
	deaths = 0
```

**`ShelterManager`:**
- `func occupants_with(p: Person) -> Array` returns the others inside the same shelter as `p` (search `shelters` for `inside.has(p)`).
- `func release(p: Person)` takes `p` out of its shelter's `inside` and calls `_exit(p, s)` (factor from `_flush`).

**`Crowd`:**
- `var plague: PlagueManager`, made in `spawn()` with `_rng.randi()`.
  - **Note:** this draws one number from the crowd's rng, which changes `crowd_check`. To keep the crowd check stable, seed it from `seed_value + 41` stored in `setup()` instead (`_seed`), not from `_rng`.
- Step it in `advance()` after the ferry; clear it in `clear()`.

### Task 16: The effect, tests, icon, clip and gates

- `src/fx/curse/pestilence.gd` (class `PestilenceFx`): `INFECT_MAX` 3, `INFECT_R` 0.8, `busy` 0.8, `duration` 1.4. A green miasma puff at each of the nearest 3 citizens within reach, then `infect(PlagueManager.PLAGUE_LIFE)` on each.
- PowerBook: 16 DP, 40 s, click, `quiet`, kind curse. `Rules.POWER_KINDS["pestilence"] = [&"plague"]`. Targeting: `AREAS["pestilence"] = {"shape": "circle", "r": 0.8}`, ringing who it would infect.
- `tests/test_plague.gd`:
  - the cast infects 3 at most;
  - a sick person in a packed group of 10 infects about `SPREAD_CHANCE` of them per tick (the seeded rng gives an exact count; check `> 0` and `<= 10`);
  - deaths come at `PLAGUE_LIFE` with the kind `plague` (`crowd.killed_citizens` rises);
  - the cap of 60 holds;
  - soldiers never catch it;
  - a sick person sheltering infects others inside;
  - the sick move at 70% pace.
- Icon: a green plague skull with miasma. Clip: `--power=pestilence --at=<the Main Gate queue>` during an evacuation (the scenario calls the evacuation at 15 s and casts at 25 s, recording 30 s).
- Commit `feat: Pestilence (v0.06 M5)`, tag `kak-v006-m5`.

---

## Milestone 6 — Scenario, bench, summary

### Task 17: The `powers` scenario
In `behaviour_check.gd`, `powers` (Prepared, loadout `wisp, thorns, discord, pestilence`). Each power cast in turn, reporting:
- the wisp at 20 s: how many lured;
- Thornwall at 35 s across the Main Gate's mouth during an evacuation called at 30 s: the queue and the reroutes;
- Discord at 50 s at the cathedral steps (the rite running): rite state, the confused count;
- Pestilence at 70 s on the Main Gate queue: sick and dead every 10 s to 130 s.

Print a checksum. Captures with `--shots`.

### Task 18: Bench, summary, tag
- Bench against `kak-v0.05`, alternating (at most a 5-fps loss).
- `docs/KAK_Version_0.06_Summary.md` (v0.05's summary updated: 17 powers, the kinds and tabs, the four powers, the measurements).
- The spec gains "Changes made while executing" per milestone.
- Commit `feat: the powers scenario and v0.06 summary (v0.06 M6)`; tags `kak-v006-m6` and `kak-v0.06`; push.
