# KAK Milestone 5 — Polish and the Playtest — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Act on the user's hour-long playtest of milestone 4 and finish the spec's last milestone: people drawn in front of what they stand in front of, a crowd that visibly panics and cries out, aiming that only shows when a power is focused and can be called off at the last moment, Divine Power from regeneration alone, video previews on the draft, a fade instead of a green flash, a slow-motion ending, a labelled stability bar, and the interface sounds the spec asked for.

**Architecture:** No new systems. Each task changes the unit that owns the behaviour: `Rules` (DP), `Targeting` / `Mission` / `Hud` (aiming), `DummyEnemy` / `Person` / `EnvironmentField` / `Structure` (draw order), `Person` / `Crowd` (panic and voices), `tools/audio/synth.py` / `Sfx` / a small `UiSound` (sounds), the sandbox and `PrepareScreen` (preview clips), `Game` / `Mission` / `Hud` (fade, ending, legend).

**Tech Stack:** Godot 4.7.2, GDScript, `gl_compatibility`, 640×360; Python 3 with numpy/scipy for the synthesized audio (`tools/audio/synth.py`) and PIL for checking captures.

## The playtest notes this plan answers

The user's own words, numbered as they gave them, with where each lands:

1. "sometimes citizen and soldiers get obscure by structures … walking in front of it but still get covered. Also the bridge completely obscure citizen." → **Task 3**
2. "Tornado Tempest walking too spread. I want it to have target driven for more. We don't have to adjust it now." → **not in this plan, deliberately** (see *Out of scope*)
3. "remove restore DP on killed … Just try with only DP regeneration first." → **Task 1**
4. "more panic direction … walking like stuck for a while and then just continue walking normally … more lively … sound effects" → **Tasks 4 and 6** (the user chose synthesized yelps, capped so the crowd never drowns the powers)
5. "When hover on an ability can we use video preview example instead of just larger icon?" → **Task 7** (the user chose pre-rendered loops)
6. "fading screen after finish loading game scene … Currently I see blank green screen after click Manifest" → **Task 8**
7. "I don't want to always show preview skill radius on cursor … just show when focus on ability … right click to cancel" → **Task 2** (the user chose: unfocus after a cast)
8. "add color as label related to … gauge color So I can know which gauge explain what." → **Task 8** (the user chose: a legend on the five-colour bar *and* the top-right figures tinted with their part's colour)
9. "Not cut to the summary page suddenly … slow motion for a second and see the last ability to finish" → **Task 8**
10. "holding left click while ability focus … I want to have right click to cancel it" → **Task 2**

## Global Constraints

- Engine: `F:\Godot\Godot_v4.7.2-stable_win64_console.exe` (Git Bash: `/f/Godot/Godot_v4.7.2-stable_win64_console.exe`), renderer `gl_compatibility`.
- Viewport 640×360, nearest filtering, `2d/snap/snap_2d_vertices_to_pixel=true`: pixel lines are hairlines (`width = -1.0`); never `draw_line` with width ≥ 1.
- **No text smaller than `UiTheme.SIZE_SMALL` (11 px)**; stack lines with `UiTheme.LINE_SMALL` / `LINE_BODY`. Pixelify Sans drops strokes below 11 px with smoothing off. It draws its 5 as an S-shape at every size — that is the font's design.
- **A texture is loaded before it is drawn, never inside `_draw()`.** Loading during drawing paints a solid white block that stays.
- The 11 effects and the effect toolkit (`src/fx/`) do not change. That includes Tornado Tempest (note 2 is deferred).
- Behaviour gate: `/f/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tools/dev/state_digest.gd` must keep printing `rows=19`, `digest=61267b7e90524d800bf1c3473a71146b`, `blocked=000000111000000000000011000000000000000000001110000000000000`, `emitters=45`. Never edit that tool or those values. Tasks 3 and 4 touch code the digest covers (`DummyEnemy`, `EnvironmentField`, `Structure`); their changes are inert in the sandbox and the digest proves it.
- Tests: `bash tools/test.sh` must end `checks=<N> failures=0`; the **562 checks** standing today keep passing. A suite that builds nodes frees them — no leaked-object lines.
- Audio: `python tools/audio/synth.py --verify` must end `audio verify: <N> cues, 0 problems`. New cues are made by `synth.py`, never recorded or downloaded.
- The screen flow still works end to end: `/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/game.tscn --audio-driver Dummy -- --flow-test` ends `FLOW result checks=<N> failures=0`. Tasks 2 and 8 change what it walks through and update it.
- The scripted runs keep working and keep their names and output shape: `SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test` prints one `MISSION test ...` line; `SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --crowd-test` prints one `CROWD result ...` line. Their numbers may move where a task changes the crowd or the economy — report them.
- Never write test data to `user://kak_save.cfg`.
- GDScript style: tabs, typed vars; explicit types for values from untyped Arrays/Dictionaries; `##` doc comments like the surrounding code. Local names must not shadow built-ins or Node members (`ready`, `ease`, `name`, `show`, `size`, `position`, `visible` …) — they warn, and the output must be pristine.
- Commit after each task; every message ends with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Commit new scripts with their `.gd.uid` files and new assets with their `.import` files.
- Leave the untracked `.codex/` folder and `docs/HUM_Game_Design_Document_v1.docx` alone. Do not commit anything under `captures/` that git does not already track.
- **User checkpoints:** after Task 3 (the draw order, shown on captures), Task 6 (the voices and interface sounds — the user listens; nobody else in this process can), and Task 7 (the preview clips), the controller shows the result to the user and waits for approval before going on.

## Out of scope

- **Tornado Tempest's wander** (note 2). The user asked for it to be marked, not changed. It stays exactly as it is; it is recorded in the project's memory for a later session.
- Numbers other than the DP recovery switch. The spec's milestone 5 includes "numbers tuned from playtests"; this playtest named only DP. Everything else waits for the next one.

---

## File Structure

| File | Change |
|---|---|
| `src/game/rules.gd` | `dp_recovery` switch, off by default (Task 1) |
| `src/game/targeting.gd` | nothing focused by default, `armed` presses, cancel and unfocus (Task 2) |
| `src/game/mission.gd` | right-click / Esc cancel-then-unfocus, HUD slot clicks (Task 2); slow-motion ending (Task 8) |
| `src/game/ui/hud.gd` | slot rects and `slot_at()` (Task 2); legend and tinted status (Task 8) |
| `src/enemies/dummy_enemy.gd` | `sort_bias`, drawn back out by a draw origin (Task 3) |
| `src/environment/environment_field.gd` | `near(g, r)` from the spatial index (Task 3) |
| `src/environment/structure.gd` | flat walkable kinds drawn under people (Task 3) |
| `src/game/crowd/person.gd` | the sort rule (Task 3); panic, flight and the running pose (Task 4) |
| `src/game/crowd/crowd.gd` | hands people the environment (Task 3); voices with a budget (Task 6) |
| `tools/audio/synth.py` | interface cues (Task 5), crowd cues (Task 6) |
| `src/audio/sfx.gd` | catalog entries (Tasks 5, 6) |
| `src/audio/ui_sound.gd` (new) | non-positional interface sounds for screens with no battlefield (Task 5) |
| `src/game/ui/*.gd`, `src/game/game.gd` | play the interface sounds (Task 5); the fade (Task 8) |
| `src/game/ui/fader.gd` (new) | fade to and from black (Task 8) |
| `src/sandbox/sandbox.gd` | `--capture-clip` writes each power's preview sheet (Task 7) |
| `src/game/power_book.gd` | clip constants and `clip(key)` (Task 7) |
| `src/game/ui/prepare_screen.gd` | plays the clip on hover (Task 7) |
| `assets/clips/<key>.png` (new, 11) | the preview sheets (Task 7) |
| `tests/test_sort.gd`, `tests/test_voices.gd` (new) and existing suites | as each task says |

Task order: 1, 2, 3, 4, 5, 6, 7, 8. Every task ends with a green suite and a commit. Check counts are given per task as "+N"; report the actual total.

---

### Task 1: Divine Power from regeneration alone

**Files:**
- Modify: `src/game/rules.gd`
- Modify: `tests/test_rules.gd`

**Why:** playtest note 3 — "DP is far far more than enough." Every destroyed tower, gate, soldier and chain was paying Divine Power back on top of the 0.5/s regeneration. The recovery becomes a switch, off; the table and its tests stay, so turning it back on after the next playtest is one line.

**Interfaces:**
- Produces: `Rules.dp_recovery: bool` (default `false`). With it off, `_gain()` pays nothing and emits nothing (no `+DP` popups); chains are still counted, still bannered and still scored.

- [ ] **Step 1: Write the failing test**

In `tests/test_rules.gd`, find the line that starts the recovery block:

```gdscript
	var r2 := Rules.new().setup(loadout, null, env, field, crowd, town)
```

Insert this block immediately **before** it:

```gdscript
	# Since the milestone 4 playtest the mission runs on regeneration alone: destroying things pays nothing.
	var r0 := Rules.new().setup(loadout, null, env, field, crowd, town)
	t.check(not r0.dp_recovery, "Divine Power comes back only by regeneration by default")
	r0.dp = 50.0
	var first_tower: Structure = null
	for s in env.structures():
		if s.role == &"tower" and not s.destroyed:
			first_tower = s
			break
	first_tower.destroy(first_tower.center(), &"nova")
	t.check(r0.dp == 50.0 and r0.buildings_down == 1,
		"a destroyed tower pays nothing but still counts as a building (%.1f DP, %d)" % [r0.dp, r0.buildings_down])
	r0.free()
```

and, directly after the `var r2 := ...` line, turn the recovery on for the block that tests it:

```gdscript
	r2.dp_recovery = true  # the table is kept, switched off; this block proves it still pays when switched on
```

- [ ] **Step 2: Run it to see it fail**

Run: `bash tools/test.sh`
Expected: a parse error for `dp_recovery` (`Invalid assignment of property or key 'dp_recovery'` or `Cannot find member`), reported as `FAIL: suite failed to load: res://tests/test_rules.gd`.

- [ ] **Step 3: Write the switch**

In `src/game/rules.gd`, add next to `var chains := 0`:

```gdscript
## Whether destroying things pays Divine Power back (spec §4.1's table). Off since the milestone 4 playtest --
## the player had far more DP than they could spend -- so a mission runs on regeneration alone. The table stays,
## so bringing it back is this one line.
var dp_recovery := false
```

and make `_gain()` start with:

```gdscript
func _gain(amount: float, at: Vector2) -> void:
	if not dp_recovery:
		return
```

(keep the rest of `_gain()` exactly as it is).

- [ ] **Step 4: Run the tests**

```bash
bash tools/test.sh
SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test 2>&1 | grep -E "MISSION test|ERROR|SCRIPT"
```

Expected: `checks=564 failures=0` (+2). The `MISSION test` line's `dp=` falls — it was ~86 with recovery — which is the point; report the new value.

- [ ] **Step 5: Commit**

```bash
git add src/game/rules.gd tests/test_rules.gd
git commit -m "balance: Divine Power from regeneration alone" -m "The milestone 4 playtest found far more DP than a player could spend. Destroying towers, gates, soldiers and chains no longer pays DP back; the mission runs on the 0.5/s regeneration. Chains still count for the score and still get their banner. The recovery table is kept behind Rules.dp_recovery, off, so the next playtest can turn it back on in one line." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Aim only when a power is focused

**Files:**
- Modify: `src/game/targeting.gd`
- Modify: `src/game/mission.gd`
- Modify: `src/game/ui/hud.gd`
- Modify: `src/game/game.gd` (the flow test)
- Modify: `tests/test_targeting.gd`, `tests/test_hud.gd`

**Why:** notes 7 and 10, and one spec gap. Today a power is always picked, so its area follows the cursor for the whole mission; right-click during a drag stops the drag, but releasing the left button **still casts** (`release()` never checks whether the press was called off); and the spec's "pick a power: keys 1–4 or click its slot" only has the keys. After this task: nothing is focused until the player presses 1–4 or clicks a slot; only then does the area show; right-click (or Esc) first calls off a press in progress, and otherwise unfocuses; a cast that goes out unfocuses (the user's choice — the slot is on cooldown anyway).

**Interfaces:**
- Produces (Targeting): `slot` is `-1` when nothing is focused; `pick(i)` focuses `i`, or unfocuses when `i` is already focused; `unfocus() -> void`; `armed: bool` — a left press is in progress; `cancel() -> bool` — calls off a press in progress and returns whether there was one; `release()` casts only when armed.
- Produces (Hud): `slot_rect(i: int) -> Rect2`, `slot_at(point: Vector2) -> int` (`-1` when the point is on no slot).

- [ ] **Step 1: Write the failing tests**

In `tests/test_targeting.gd`, replace everything from `var aim := Targeting.new().setup(rules, crowd)` down to (not including) the lane-fright comment `# A lane power frightens the people along it, not only at its start.` with:

```gdscript
	var aim := Targeting.new().setup(rules, crowd)
	t.check(aim.slot == -1 and aim.area().is_empty(), "nothing is focused when a mission starts, so nothing is drawn")
	aim.press(Vector2(1.0, 1.0))
	aim.release(Vector2(1.0, 1.0))
	t.check(casts.is_empty() and not aim.armed, "a click with nothing focused casts nothing")

	aim.pick(0)
	t.check(aim.slot == 0 and not aim.area().is_empty(), "pressing a slot's key focuses it and shows its area")
	aim.pick(0)
	t.check(aim.slot == -1, "pressing it again unfocuses it")

	# A click power: cast where the button went down, then unfocused.
	aim.pick(0)
	aim.press(Vector2(2.0, 2.0))
	t.check(aim.armed and not aim.aiming, "a click power arms on press without starting a drag")
	aim.release(Vector2(2.4, 2.1))
	t.check(casts.size() == 1 and casts[0][0] == Vector2(2.0, 2.0) and not casts[0][1].has("dir"),
		"a click power is cast where the button went down, with no direction (%s)" % [casts])
	t.check(aim.slot == -1 and not aim.armed, "and a cast that goes out unfocuses (%d)" % aim.slot)

	# A drag power: cast from where the drag started, along the drag.
	aim.pick(1)
	aim.press(Vector2(-3.0, 0.0))
	t.check(aim.aiming, "a drag power starts aiming")
	aim.release(Vector2(0.0, 0.0))
	t.check(casts.size() == 2 and casts[1][0] == Vector2(-3.0, 0.0), "and is cast from where the drag started")
	t.check((casts[1][1].dir as Vector2).is_equal_approx(Vector2(1, 0)),
		"pointed the way it was dragged (%s)" % [casts[1][1].dir])
	t.check(not aim.aiming and aim.slot == -1, "and the drag is done")

	# Right-click while the button is held calls the cast off; the power stays focused.
	aim.pick(3)
	aim.press(Vector2(0.0, 5.0))
	t.check(aim.cancel(), "calling off a held press reports that it did")
	aim.release(Vector2(1.0, 5.0))
	t.check(casts.size() == 2 and aim.slot == 3, "the release after it casts nothing, and the power stays focused (%d)" % casts.size())
	t.check(not aim.cancel(), "with nothing held there is nothing to call off")
	aim.unfocus()
	t.check(aim.slot == -1 and aim.area().is_empty(), "and unfocusing takes the area away")
```

In `tests/test_hud.gd`, replace:

```gdscript
	t.check(hud.is_picked(0) and hud.slot_state(0) == "ready",
```

with:

```gdscript
	aim.pick(0)
	t.check(hud.is_picked(0) and hud.slot_state(0) == "ready",
```

and add, just before the banner block (`# Banners queue up, show for their time and go.`):

```gdscript
	# The slots answer to the mouse (spec §1: "keys 1-4 or click its slot").
	t.check(hud.slot_at(hud.slot_rect(2).get_center()) == 2, "a point on the third slot is the third slot")
	t.check(hud.slot_at(Vector2(4.0, 200.0)) == -1, "and a point on the town is no slot")
```

- [ ] **Step 2: Run them to see them fail**

Run: `bash tools/test.sh`
Expected: both suites fail to load (`armed`, `unfocus`, `slot_rect` do not exist yet).

- [ ] **Step 3: Rework the targeting**

In `src/game/targeting.gd`:

Change `var slot := 0` to:

```gdscript
## The focused slot, or -1 when nothing is: the area is only drawn while a power is focused.
var slot := -1
## A left press is in progress on a focused power; the release casts it unless something called it off.
var armed := false
```

Replace `pick()` with:

```gdscript
## Focus a slot, or unfocus it when it is the one already focused (pressing its key again).
func pick(new_slot: int) -> void:
	if new_slot == slot:
		unfocus()
		return
	slot = new_slot
	armed = false
	aiming = false
	picked.emit(slot)
	queue_redraw()


func unfocus() -> void:
	slot = -1
	armed = false
	aiming = false
	picked.emit(slot)
	queue_redraw()
```

Replace `press()`, `release()` and `cancel()` with:

```gdscript
func press(ground: Vector2) -> void:
	if slot < 0:
		return
	_press = ground
	_at = ground
	armed = true
	aiming = _is_drag()
	queue_redraw()


## The button came up: cast, unless the press was called off. A click power fires from where the button went
## down; a drag power fires from there along the way it was dragged.
func release(ground: Vector2) -> void:
	if not armed:
		return
	_at = ground
	armed = false
	var extra := {}
	if _is_drag():
		extra["dir"] = aim_dir()
	aiming = false
	_rules.cast(slot, _press, extra)
	queue_redraw()


## Call off a press in progress (right-click or Esc while the button is held). True when there was one; the
## power stays focused either way.
func cancel() -> bool:
	var had := armed
	armed = false
	aiming = false
	queue_redraw()
	return had
```

and at the end of `_on_cast_made()` add:

```gdscript
	# A power that went out is on its cooldown: unfocus, so its area stops following the cursor.
	unfocus()
```

In `_draw()`, the existing `if a.is_empty(): return` already covers `slot == -1` (`area()` of slot -1 is empty) — leave it.

- [ ] **Step 4: Rework the mission's input**

In `src/game/mission.gd`'s `_unhandled_input()`:

Replace the Esc branch's first test:

```gdscript
			if _aim.aiming:
				_aim.cancel()
			elif autostart:
```

with:

```gdscript
			if _aim.cancel():
				pass  # a held press was called off
			elif _aim.slot >= 0:
				_aim.unfocus()
			elif autostart:
```

(and update its comment: Esc calls off a held press, then unfocuses, and only with nothing focused is it the pause menu's).

Replace the right-click branch:

```gdscript
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_aim.cancel()
```

with:

```gdscript
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# Right-click first calls off a held press (note 10), and otherwise lets go of the focused power (note 7).
		if not _aim.cancel():
			_aim.unfocus()
```

Replace the left-button branch:

```gdscript
		if event.pressed:
			_pressing = true
			_aim.press(_bf.mouse_ground())
```

with:

```gdscript
		if event.pressed:
			# A click on a HUD slot focuses that power instead of casting into the town under it.
			var on_slot := _hud.slot_at(event.position)
			if on_slot >= 0 and on_slot < _rules.loadout.size():
				_aim.pick(on_slot)
				return
			_pressing = true
			_aim.press(_bf.mouse_ground())
```

- [ ] **Step 5: Give the HUD's slots a shape the mouse can find**

In `src/game/ui/hud.gd`, add next to the other constants:

```gdscript
## The screen width to lay out against before the Control has been sized (headless tests).
const SCREEN_W := 640.0
## Where the slot row sits.
const SLOT_TOP := 312.0
```

add:

```gdscript
## Where slot `i` is drawn -- the one geometry both the drawing and the mouse use.
func slot_rect(i: int) -> Rect2:
	var w := size.x if size.x > 1.0 else SCREEN_W
	var count := _rules.loadout.size()
	var total := float(count) * SLOT_SIZE + float(maxi(count - 1, 0)) * SLOT_GAP
	var left := roundf((w - total) * 0.5)
	return Rect2(Vector2(left + float(i) * (SLOT_SIZE + SLOT_GAP), SLOT_TOP), Vector2(SLOT_SIZE, SLOT_SIZE))


## The slot under a screen point, or -1.
func slot_at(point: Vector2) -> int:
	for i in _rules.loadout.size():
		if slot_rect(i).has_point(point):
			return i
	return -1
```

and in `_draw_slots()`, replace the lines that compute `count`, `total`, `at` and `box` so the box comes from `slot_rect(i)`:

```gdscript
func _draw_slots(_w: float) -> void:
	for i in _rules.loadout.size():
		var box := slot_rect(i)
```

(keep the rest of the loop body as it is).

- [ ] **Step 6: Keep the flow test walking**

In `src/game/game.gd`'s `_flow_test()`, the mission part focuses nothing, so nothing changes there. Run it to confirm:

```bash
bash tools/test.sh
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/game.tscn --audio-driver Dummy -- --flow-test 2>&1 | grep -E "FLOW result|FLOW FAIL|ERROR|SCRIPT"
SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test 2>&1 | grep -E "MISSION test|ERROR|SCRIPT"
```

Expected: `checks=574 failures=0` (+10); `FLOW result checks=20 failures=0`; one `MISSION test` line — the scripted run focuses each power itself (`_aim.pick(slot)` before each cast) so it is unaffected, and its first frame still shows the Nova's ring.

- [ ] **Step 7: Commit**

```bash
git add src/game/targeting.gd src/game/mission.gd src/game/ui/hud.gd tests/test_targeting.gd tests/test_hud.gd
git commit -m "feat: aim only when a power is focused" -m "Nothing is focused when a mission starts, so no area follows the cursor until the player presses 1-4 or clicks a slot (the slot click is the spec's, and was missing). Right-click or Esc first calls off a press in progress -- before, releasing the button after a right-click still cast -- and otherwise lets go of the focused power. A cast that goes out unfocuses, since its slot is on cooldown anyway." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---
### Task 3: People drawn in front of what they stand in front of

**Files:**
- Modify: `src/environment/environment_field.gd` (`near()`)
- Modify: `src/environment/structure.gd` (flat walkable kinds under people)
- Modify: `src/enemies/dummy_enemy.gd` (`sort_bias`, the draw origin, the pose hook)
- Modify: `src/game/crowd/person.gd` (the sort rule)
- Modify: `src/game/crowd/crowd.gd` (hands each person the environment)
- Create: `tests/test_sort.gd`
- Modify: `tests/run_all.gd`

**Why:** playtest note 1. The world is y-sorted: every building sorts by the screen point of its footprint's south-east corner — the corner nearest the camera — and every person by their feet. For a long building that is wrong: someone standing just in front of its south face, near its **west** end, has feet whose sort key is smaller than the building's far-east corner, so the building is drawn over them. The Barracks yard, the Citadel's curtain walls and the gates are exactly where people stand. The bridge is worse: it is long and people walk *on* it, so it covered everyone crossing.

Two fixes, one each:
- **Flat things people walk on** — the bridge and the farm fields — are drawn under every person (`z_index = -1`), whatever their key says.
- **Everything solid** keeps its key, and each **person** nudges their own sort key. The exact rule for a point and a box, in ground units: a person at `p` is in front of a building whose footprint is `B` when `p.x >= B.end.x` or `p.y >= B.end.y`, and behind it otherwise. Among the buildings that overlap the person on screen, the person's key has to be above every one they are in front of and below every one they are behind. When their own feet already satisfy that, nothing changes; when it cannot be satisfied (in front of one and behind another with a lower key), nothing changes either. The shift moves only the **sort key** — the body is drawn back to the feet through a draw origin, so nobody moves on screen.

The sandbox has no bridges or fields and never sets a bias, which is why the behaviour digest cannot move. No effect reads a unit's screen `position` (they all use `ground_pos`), which is why the shift is safe for them too.

**Interfaces:**
- Produces: `EnvironmentField.near(g: Vector2, r: float) -> Array[Structure]`; `Structure.FLAT` (kinds drawn under people); `DummyEnemy.sort_bias: float` (screen px added to the sort key), `DummyEnemy._pose_signature() -> int` and `DummyEnemy._walk_rate() -> float` (virtual hooks for Task 4); `Person.env: EnvironmentField`, `static Person.sort_bias_for(feet: Vector2, near: Array[Structure]) -> float`, `const Person.SORT_REACH`.

- [ ] **Step 1: Write the failing test**

Create `tests/test_sort.gd`:

```gdscript
extends RefCounted
## Draw order between people and buildings: a person in front of a long building sorts after it, one behind
## sorts before it, a person whose own feet already do stays put, a contradiction is left alone, and flat
## things people walk on are drawn under them.


static func run(t) -> void:
	# A long, low building running east-west: its south-east corner sorts at (4 + 1) * 16 = 80.
	var long := Structure.new().setup(Rect2(0.0, 0.0, 4.0, 1.0), 40.0, Structure.Kind.BLOCK, 1)
	var near: Array[Structure] = [long]

	# In front of its south face, near the WEST end: the case the playtest saw.
	var front := Vector2(0.5, 1.6)
	var own := (front.x + front.y) * 16.0
	var bias := Person.sort_bias_for(front, near)
	t.check(own < long.position.y, "the person's own feet sort before the building (%.1f < %.1f)" % [own, long.position.y])
	t.check(bias > 0.0 and own + bias > long.position.y, "so the person is lifted past it (+%.1f)" % bias)

	# Behind it: the feet already sort before it, nothing to do.
	t.check(Person.sort_bias_for(Vector2(2.0, -0.6), near) == 0.0, "a person behind the building is left behind it")
	# In front of the east end, far enough that the feet already sort after it: nothing to do either.
	t.check(Person.sort_bias_for(Vector2(4.5, 1.2), near) == 0.0, "a person whose own feet already sort in front is left alone")

	# A contradiction: in front of the long building and behind a small one whose key is lower. No single key
	# can be both, so nothing changes rather than guessing.
	var small := Structure.new().setup(Rect2(0.8, 1.9, 0.6, 0.5), 30.0, Structure.Kind.BLOCK, 2)
	var both: Array[Structure] = [long, small]
	t.check(Person.sort_bias_for(front, both) == 0.0, "a person who would have to be both in front and behind is left alone")

	# Things people walk on and rubble do not constrain anyone.
	var bridge := Structure.new().setup(Rect2(0.0, 0.0, 4.0, 1.0), 20.0, Structure.Kind.BRIDGE, 3)
	var only_bridge: Array[Structure] = [bridge]
	t.check(Person.sort_bias_for(front, only_bridge) == 0.0, "a bridge does not lift anyone: it is drawn under them instead")
	t.check(bridge.z_index < 0, "and a bridge is drawn under the people on it (z %d)" % bridge.z_index)
	var field := Structure.new().setup(Rect2(0.0, 0.0, 2.0, 2.0), 4.0, Structure.Kind.FARM_FIELD, 4)
	var house := Structure.new().setup(Rect2(0.0, 0.0, 1.0, 1.0), 30.0, Structure.Kind.HOUSE, 5)
	t.check(field.z_index < 0 and house.z_index == 0, "so is a field, and a house is not")
	long.destroyed = true
	t.check(Person.sort_bias_for(front, near) == 0.0, "rubble does not lift anyone")

	# The shift moves the sort key, not the body.
	var p := Person.new()
	p.ground_pos = front
	p.sort_bias = 20.0
	p._sync_position()
	var feet := Iso.ground_to_screen(front).round()
	t.check(p.position.y == feet.y + 20.0 and p._draw_origin.y == -20.0,
		"a biased person sorts 20 px later and is still drawn at its feet (%.0f, %.0f)" % [p.position.y, p._draw_origin.y])

	for n: Node in [long, small, bridge, field, house, p]:
		n.free()
```

- [ ] **Step 2: Register it and run it to see it fail**

In `tests/run_all.gd`, add `"res://tests/test_sort.gd",` to `SUITES` after `"res://tests/test_crowd.gd",`.

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_sort.gd` (no `sort_bias_for`).

- [ ] **Step 3: Draw flat walkable things under people**

In `src/environment/structure.gd`, next to `const WALKABLE := ...`:

```gdscript
## Flat things people walk on. They are drawn under every person whatever their sort key says: a bridge sorts
## by its far corner, and drew over everyone crossing it.
const FLAT := [Kind.BRIDGE, Kind.FARM_FIELD]
```

and in `setup()`, right after `walkable = k in WALKABLE`:

```gdscript
	z_index = -1 if k in FLAT else 0
```

- [ ] **Step 4: Let a unit sort somewhere other than its feet**

In `src/enemies/dummy_enemy.gd`, add next to the other state:

```gdscript
## Screen pixels added to this unit's y-sort key without moving where it is drawn. Zero except for the town's
## people, who use it to sort in front of a long building they stand in front of (Person.sort_bias_for).
var sort_bias := 0.0
## Where drawing starts relative to the node: the sort bias drawn back out, so the body stays on its feet.
var _draw_origin := Vector2.ZERO
```

Replace `_sync_position()`:

```gdscript
func _sync_position() -> void:
	var bias := roundf(sort_bias)
	position = Iso.ground_to_screen(ground_pos).round() + Vector2(0.0, bias)
	_draw_origin = Vector2(0.0, -bias)
```

Then make **every** drawing call start from `_draw_origin`:
- the first line of `_draw()` becomes `draw_set_transform(_draw_origin)`;
- every `draw_set_transform(X, ...)` in this file becomes `draw_set_transform(_draw_origin + X, ...)`;
- every `draw_set_transform(Vector2.ZERO)` becomes `draw_set_transform(_draw_origin)`.

Find them all with `grep -n "draw_set_transform" src/enemies/dummy_enemy.gd` and change each — a missed one draws that part of a body `sort_bias` pixels away from the rest (typically a dead body flying off in the wrong place). `src/game/crowd/person.gd` has none today; check with the same grep.

A unit only redraws when its art signature changes, so the draw origin and the new poses (Task 4) must be part of it, and the leg cycle it samples must be the one actually drawn. In `_art_signature()`, replace
`var walk := int(_anim * (5.0 if look == Look.ORC else 6.0)) % 2` with `var walk := int(_anim * _walk_rate()) % 2`, and at its end replace `return sig * 97 + int(state)` with:

```gdscript
	sig = sig * 97 + int(state)
	# Where the body is drawn from moves with the sort bias; a stale draw would sit that far off its feet.
	sig = sig * 131 + int(_draw_origin.y) + 64
	return sig * 7 + _pose_signature()


## What a subclass draws differently that the signature above cannot see (a person running or stumbling).
func _pose_signature() -> int:
	return 0


## Leg steps per unit of _anim. A person running steps faster (Task 4); the signature samples the same rate,
## or a redraw would only happen on the slower cycle and the legs would stutter.
func _walk_rate() -> float:
	return 5.0 if look == Look.ORC else 6.0
```

In `_draw_body()`, use it too: `var step := int(_anim * 6.0) % 2 ...` becomes `var step := int(_anim * _walk_rate()) % 2 ...` (the orc drawing has its own step line; leave `_draw_orc()` as it is).

- [ ] **Step 5: The sort rule**

In `src/environment/environment_field.gd`, add after `structures()`:

```gdscript
## Structures whose footprint comes within `r` of `g`, from the spatial index -- for a person deciding what it
## stands in front of. A radius beyond the index's margin still works; it just walks more cells.
func near(g: Vector2, r: float) -> Array[Structure]:
	var out: Array[Structure] = []
	var c0 := _cell(g - Vector2(r, r))
	var c1 := _cell(g + Vector2(r, r))
	for cx in range(c0.x, c1.x + 1):
		for cy in range(c0.y, c1.y + 1):
			for s in _grid.get(Vector2i(cx, cy), []):
				if is_instance_valid(s) and not out.has(s) and (s as Structure).footprint.grow(r).has_point(g):
					out.append(s)
	return out
```

In `src/game/crowd/person.gd`, add the constants:

```gdscript
## How far around its feet (ground units) a person looks for buildings it might be drawn against. A building
## further away cannot overlap it on screen.
const SORT_REACH := 3.0
## How often a person re-reads its draw order. 160 people against the buildings around each of them is real
## work; ten times a second is plenty for someone walking under two units a second.
const SORT_HZ := 10.0
## A person's sprite on screen, relative to its feet: wide enough for a spear, tall enough for a helmet.
const SPRITE_BOX := Rect2(-6.0, -18.0, 12.0, 19.0)
## Drawn above a building's footprint: its height plus a roof or battlements.
const ROOF_MARGIN := 14.0
```

the state:

```gdscript
## The field of buildings, for sorting against them. Null in tests that build a person without a town.
var env: EnvironmentField
## Seconds until the next draw-order reading, staggered by instance so a crowd does not all re-sort together.
var _sort_in := 0.0
```

the rule itself:

```gdscript
## The sort-key shift (screen px) that draws a person at `feet` after every building in `near` it stands in
## front of and before every one it stands behind, counting only buildings that overlap it on screen. 0 when
## its own feet already do that, or when nothing can (it would have to be before and after the same key).
static func sort_bias_for(feet: Vector2, near: Array[Structure]) -> float:
	var own := (feet.x + feet.y) * 16.0
	var me := Rect2(Iso.ground_to_screen(feet) + SPRITE_BOX.position, SPRITE_BOX.size)
	var lo := -INF
	var hi := INF
	for s in near:
		if not is_instance_valid(s) or s.destroyed or s.walkable:
			continue
		var fp := s.footprint
		if fp.has_point(feet) or not _screen_box(fp, s.height).intersects(me):
			continue
		var key := s.position.y
		if feet.x >= fp.end.x or feet.y >= fp.end.y:
			lo = maxf(lo, key + 1.0)
		else:
			hi = minf(hi, key - 1.0)
	if (own >= lo and own <= hi) or lo > hi:
		return 0.0
	return (lo if own < lo else hi) - own


## A footprint's box on screen, raised by its height and a roof.
static func _screen_box(fp: Rect2, h: float) -> Rect2:
	var box := Rect2(Iso.ground_to_screen(fp.position), Vector2.ZERO)
	for corner in [Vector2(fp.end.x, fp.position.y), fp.end, Vector2(fp.position.x, fp.end.y)]:
		box = box.expand(Iso.ground_to_screen(corner))
	box.position.y -= h + ROOF_MARGIN
	box.size.y += h + ROOF_MARGIN
	return box
```

and at the end of `_think()` (after the `match mind:` block), keep the key current:

```gdscript
	_sort_in -= delta
	if env != null and _sort_in <= 0.0:
		_sort_in = 1.0 / SORT_HZ + float(get_instance_id() % 7) * 0.001
		sort_bias = sort_bias_for(ground_pos, env.near(ground_pos, SORT_REACH))
```

`_think()` returns early while a person waits in a gate queue — someone standing still keeps the key they had, which is right.

In `src/game/crowd/crowd.gd`'s `_add_person()`, after `p.setup_person(...)`:

```gdscript
	p.env = _env
```

- [ ] **Step 6: Run the tests and the gates**

```bash
bash tools/test.sh
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tools/dev/state_digest.gd
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --crowd-test 2>&1 | grep -E "CROWD result|ERROR"
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --capture-town 2>&1 | grep -E "captured|ERROR"
```

Expected: `checks=584 failures=0` (+10); the digest exactly as in the Global Constraints; one `CROWD result`; seven `captured` lines.

**Look before you commit.** Open `captures/town_crowd.png`, `town_main_gate.png` and `town_river_farms.png` and crop-and-enlarge (PIL) around: soldiers in the Barracks yard (in front of its long south face), people at the Main Gate, anyone on the bridge. Describe whether each person you can see is drawn over the building behind them and under the one in front. The bridge must never cover a person. If you find someone still covered, report the crop and the person's ground position rather than tuning the rule.

Also bench once and report it next to the milestone 4 figure (`bench[mission]`, 72–100 fps depending on machine load): the rule runs at think rate for each of 160 people.

```bash
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/mission.tscn --audio-driver Dummy --disable-vsync --max-fps 0 -- --bench
```

- [ ] **Step 7: Commit**

```bash
git add src/environment/environment_field.gd src/environment/structure.gd src/enemies/dummy_enemy.gd src/game/crowd/person.gd src/game/crowd/crowd.gd tests/test_sort.gd tests/test_sort.gd.uid tests/run_all.gd
git commit -m "fix: people are drawn in front of what they stand in front of" -m "A building sorts by its footprint's nearest corner, so anyone standing in front of a long building's far end sorted behind it and was covered -- the Barracks yard, the Citadel's curtain walls, the gates. Each person now shifts its own sort key by the exact point-and-box rule (in front when past either near face) against the buildings that overlap it on screen; the body is drawn back to its feet, so nothing moves. The bridge and the farm fields, which people walk on, are drawn under everyone. Inert in the sandbox: the digest is unchanged." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: A crowd that panics like one

**Files:**
- Modify: `src/game/crowd/person.gd`
- Modify: `tests/test_person.gd`

**Why:** playtest note 4 — "walking like stuck for a while and then just continue walking normally." That is exactly what the code does. A panicked citizen makes **one** 3-unit dash away from the blow, then mills in place until the fright wears off; then, turning to flight, it **stands still** for up to 2.4 seconds while its route to an exit is staggered (so a hundred people do not all path-find in one frame); then it walks out at a pace that barely differs from a stroll. After this task: a panic is a string of dashes that veer, a person waiting for its route keeps scurrying away from the danger without path-finding, everyone moves at their own pace, runners hold their arms up and move their legs faster, and now and then one stumbles.

**Interfaces:**
- Produces: `Person.pace: float` (in `PACE_RANGE`), `is_running() -> bool`, `is_stumbling() -> bool`; `DummyEnemy._pose_signature()` overridden. `FLEE_SPEED` is unchanged — the gates and the escape limit were tuned against it.

- [ ] **Step 1: Write the failing tests**

In `tests/test_person.gd`, before the suite's final cleanup (the last lines that free what it built), add:

```gdscript
	# --- A lively panic ------------------------------------------------------------------------------
	var paces: Array[float] = []
	for i in 20:
		var q := Person.new()
		q.rng.seed = 100 + i
		q.setup_person(false, Vector2(0.0, 2.0), grid)
		paces.append(q.pace)
		q.free()
	var slowest: float = paces.min()
	var fastest: float = paces.max()
	t.check(slowest >= Person.PACE_RANGE.x and fastest <= Person.PACE_RANGE.y and fastest - slowest > 0.1,
		"people move at their own pace (%.2f to %.2f)" % [slowest, fastest])

	var r := Person.new()
	r.rng.seed = 7
	r.bounds = TownLayout.MAP
	r.setup_person(false, Vector2(0.0, 2.0), grid)
	var threat := r.ground_pos + Vector2(0.0, -1.0)
	r.panic(threat)
	t.check(r.is_running(), "a panicked citizen runs")
	var first_goal := r._goal
	t.check(first_goal.distance_to(threat) > r.ground_pos.distance_to(threat), "away from the blow")
	# Walk it to the end of its dash: still panicking, it dashes again instead of milling about.
	var guard := 0
	while guard < 600 and r.ground_pos.distance_to(first_goal) > Person.GOAL_REACH:
		r.tick(1.0 / 60.0)
		guard += 1
	r.tick(1.0 / 60.0)
	t.check(r.mind == Person.Mind.PANIC and r._goal != Vector2.INF and r._goal != first_goal,
		"at the end of a dash it dashes again (%s)" % [r._goal])

	# Turning to flight, it does not stand still while its route out is worked out.
	r.flee()
	var still := 0
	var last := r.ground_pos
	for i in 60:
		r.tick(1.0 / 60.0)
		if r.ground_pos.distance_to(last) < 0.001 and not r.is_stumbling():
			still += 1
		last = r.ground_pos
	t.check(still < 15, "waiting for its route, a fleeing citizen keeps moving (%d still frames of 60)" % still)
	r.free()

	var calm := Person.new()
	calm.setup_person(false, Vector2(0.0, 2.0), grid)
	t.check(not calm.is_running(), "a calm citizen does not run")
	calm.free()
```

- [ ] **Step 2: Run them to see them fail**

Run: `bash tools/test.sh`
Expected: `test_person.gd` fails to load (`pace`, `is_running` do not exist).

- [ ] **Step 3: Pace, dashes, scurrying, stumbles**

In `src/game/crowd/person.gd`, change `const PANIC_SPEED := 0.9` to `const PANIC_SPEED := 1.6` — a dash, not a brisk walk — and `const PANIC_SECONDS := 1.6` to `const PANIC_SECONDS := 3.0`: a single dash takes up to about 2.3 s, so a 1.6 s fright ended before the second dash could ever start. (If the existing panic-then-flight check in `test_person.gd` now needs more ticks to see the flight, lengthen its loop — that is this change's direct consequence, not a regression.) Then add:

```gdscript
## Each person's speed is scaled by a pace drawn from this range, so a crowd is not a marching column.
const PACE_RANGE := Vector2(0.85, 1.2)
## One panicked dash: how far (ground units), and how far it may veer from straight away (radians).
const DASH := Vector2(1.6, 3.2)
const DASH_VEER := 0.6
## While its route out is being planned a fleeing person scurries in hops this long, without path-finding.
const SCURRY := 0.9
## Chance per think that a running person stumbles, and how long they are down for.
const STUMBLE_CHANCE := 0.006
const STUMBLE_SECONDS := 0.45
```

state:

```gdscript
var pace := 1.0
## Where the fright came from, so a dash and a scurry run away from it.
var _threat := Vector2.INF
var _stumble := 0.0
```

In `setup_person()`, after the existing randomized looks, draw the pace:

```gdscript
	pace = rng.randf_range(PACE_RANGE.x, PACE_RANGE.y)
```

`_mind_speed()` returns its current value times `pace` (keep its `match`, multiply each result).

Replace the end of `panic()` (everything from `var away := ground_pos - from`) with:

```gdscript
	_threat = from
	_dash()
```

and add:

```gdscript
## A panicked dash: away from the danger, veering, to the nearest walkable point.
func _dash() -> void:
	var away := ground_pos - _threat if _threat != Vector2.INF else Vector2.RIGHT.rotated(rng.randf() * TAU)
	var dir := (away.normalized() if away.length() > 0.01 else Vector2.RIGHT).rotated(rng.randf_range(-DASH_VEER, DASH_VEER))
	var to := ground_pos + dir * rng.randf_range(DASH.x, DASH.y)
	if grid != null:
		var free := grid.nearest_walkable(to, 6)
		to = free if free != Vector2.INF else ground_pos
	if to.distance_to(ground_pos) <= GOAL_REACH:
		# Nowhere to dash (hemmed in by walls): scurry instead. set_goal() on a point already reached would
		# arrive at once, dash again, and recurse forever.
		_scurry()
		return
	set_goal(to)


## Keep running while the route out is still being planned: a short straight hop away from the danger. No
## path-finding -- the stagger exists so a whole town does not path-find in one frame.
func _scurry() -> void:
	var away := ground_pos - _threat if _threat != Vector2.INF else Vector2.RIGHT.rotated(rng.randf() * TAU)
	var dir := (away.normalized() if away.length() > 0.01 else Vector2.RIGHT).rotated(rng.randf_range(-0.8, 0.8))
	for turn in [0.0, PI * 0.5, -PI * 0.5]:
		var to := ground_pos + dir.rotated(turn) * SCURRY
		if grid == null or grid.walkable(to):
			_target = to
			return


func is_running() -> bool:
	return state != State.DEAD and (mind == Mind.PANIC or mind == Mind.FLEE or mind == Mind.RALLY)


func is_stumbling() -> bool:
	return _stumble > 0.0
```

In `_pick_target()`, where it runs out of path at its goal (`_goal = Vector2.INF` then `_drift()`), a panicking person dashes again:

```gdscript
	_goal = Vector2.INF
	if mind == Mind.PANIC:
		_dash()
		return
	_drift()
```

In `_think()`, directly after the `if wait > 0.0:` block:

```gdscript
	if _stumble > 0.0:
		_stumble = maxf(_stumble - delta, 0.0)
		_idle = maxf(_idle, 0.05)
		return
	if is_running() and not soldier and rng.randf() < STUMBLE_CHANCE:
		_stumble = STUMBLE_SECONDS
		return
```

and in the `Mind.FLEE` branch replace the standing wait:

```gdscript
				else:
					_idle = maxf(_idle, 0.05)
```

with:

```gdscript
				elif ground_pos.distance_to(_target) < 0.1:
					_scurry()
```

- [ ] **Step 4: The running pose**

In `_draw_citizen()`, make the legs quicker and the arms go up while running, and crouch while stumbling. Replace its first lines and its arm lines:

```gdscript
func _draw_citizen(lift: int, top_only: int) -> void:
	var running := is_running()
	var step := int(_anim * _walk_rate()) % 2 if state != State.DEAD and not is_frozen() and not is_stumbling() else 0
	if is_stumbling():
		lift += 2  # down on one knee
```

and replace the two arm pixels (`_px(-4, -9 + lift, 1, 3, _skin)` and `_px(3, -9 + lift, 1, 3, _skin)`) with:

```gdscript
	var arm_y := -12 if running else -9
	_px(-4, arm_y + lift, 1, 3, _skin)
	_px(3, arm_y + lift, 1, 3, _skin)
```

In `_draw_soldier()`, its step line becomes `var step := int(_anim * _walk_rate()) % 2 ...` the same way.

The pose and the leg rate are part of the redraw signature through Task 3's hooks:

```gdscript
func _pose_signature() -> int:
	return (1 if is_running() else 0) + (2 if is_stumbling() else 0)


func _walk_rate() -> float:
	if is_running():
		return 8.0 if soldier else 10.0
	return 5.0 if soldier else 6.0
```

- [ ] **Step 5: Run the tests and look**

```bash
bash tools/test.sh
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --crowd-test 2>&1 | grep -E "CROWD result|ERROR"
SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test 2>&1 | grep -E "MISSION test|ERROR|SCRIPT"
```

Expected: `checks=590 failures=0` (+6); one `CROWD result` and one `MISSION test` line — their numbers will move (people run faster and never stand still), so report both next to milestone 4's (`citizens=42 escaped=6` and `escaped=4..8`). **If `escaped` more than doubles**, say so: the escape limit (38) was set against the old pace, and the user decides whether that is a balance change they want.

Look at `captures/crowd_*.png` (crop-and-enlarge): runners with raised arms, people spread out rather than frozen in clumps.

- [ ] **Step 6: Commit**

```bash
git add src/game/crowd/person.gd tests/test_person.gd
git commit -m "feat: a crowd that panics like one" -m "A fright was one dash, then milling in place, then standing still for up to 2.4 s while the route out was staggered, then a walk. Now a panic is a string of veering dashes at a sprint, a person waiting for its route keeps scurrying away from the danger without path-finding, everyone moves at their own pace, runners hold their arms up and move their legs faster, and now and then one stumbles. The fleeing speed the gates were tuned against is unchanged." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---
### Task 5: Interface sounds

**Files:**
- Modify: `tools/audio/synth.py` (eight `ui_*` cues)
- Modify: `src/audio/sfx.gd` (their catalog entries)
- Create: `src/audio/ui_sound.gd`
- Modify: `src/game/ui/title_screen.gd`, `prepare_screen.gd`, `results_screen.gd`, `pause_menu.gd`, `hud.gd`, `src/game/mission.gd`, `src/game/game.gd`
- Modify: `tests/test_results.gd`

**Why:** the spec's milestone 5 asks for UI sounds "synthesized like the effect audio", and §1 asks for "a buzz" when a slot refuses a cast. Interface sounds are not in the world, so they are not positional — and the title, the draft and the results have no battlefield to hang an `Sfx` off — so they get their own small player: `UiSound`, a pool of plain `AudioStreamPlayer`s under the scene tree's root, made the first time a sound plays and alive across every screen change (the MANIFEST sting has to outlive the draft screen that started it).

**Interfaces:**
- Produces: cues `ui_hover`, `ui_click`, `ui_focus`, `ui_buzz`, `ui_pause`, `ui_manifest`, `ui_win`, `ui_lose` in `Sfx.CATALOG` and `assets/audio/ui/`; `UiSound.play(cue: StringName, db_offset := 0.0) -> void` (static); `UiSound.CUES`.

- [ ] **Step 1: Write the failing test**

At the end of `tests/test_results.gd`'s `run()`, add:

```gdscript
	# Every interface sound is in the catalog and on disk (synthesized by tools/audio/synth.py).
	var missing := ""
	for cue: StringName in UiSound.CUES:
		if not Sfx.CATALOG.has(cue):
			missing += " %s(catalog)" % cue
		elif not ResourceLoader.exists(String(Sfx.CATALOG[cue].path)):
			missing += " %s(file)" % cue
	t.check(missing == "", "every interface sound exists (missing:%s)" % missing)
	t.check(UiSound.CUES.size() == 8, "eight of them (%d)" % UiSound.CUES.size())
```

Run: `bash tools/test.sh` — expected: `test_results.gd` fails to load (`UiSound` does not exist).

- [ ] **Step 2: Synthesize the cues**

In `tools/audio/synth.py`, add these builders after the last effect's builders and before `# id: (effect folder, builder, length seconds, loop)`:

```python
# --------------------------------------------------------------------------
# Interface (KAK milestone 5): short, dry, and plainly not part of the world.
# --------------------------------------------------------------------------

def ui_hover(rng, dur):
    n = int(round(dur * SR))
    return sine(1800.0, n) * decay(n, 0.012) * attack(n, 0.002) * 0.5


def ui_click(rng, dur):
    n = int(round(dur * SR))
    body = sine(ramp(900.0, 520.0, n, "exp"), n) * decay(n, 0.03)
    tick = highpass(noise(n, rng), 3000.0) * decay(n, 0.004)
    return (body + tick * 0.4) * attack(n, 0.001)


def ui_focus(rng, dur):
    n = int(round(dur * SR))
    tone = sine(ramp(700.0, 1400.0, n, "exp"), n) + 0.3 * sine(ramp(1400.0, 2800.0, n, "exp"), n)
    return tone * adsr(n, 0.004, 0.03, 0.4, 0.04)


def ui_buzz(rng, dur):
    n = int(round(dur * SR))
    tone = lowpass(square(110.0, n, 0.3) + 0.5 * square(116.0, n, 0.3), 1800.0)
    return saturate(tone * 0.6, 2.0) * adsr(n, 0.005, 0.05, 0.7, 0.06)


def ui_pause(rng, dur):
    n = int(round(dur * SR))
    out = sine(660.0, n) * decay(n, 0.05)
    place(out, sine(440.0, n) * decay(n, 0.06), 0.07)
    return out * attack(n, 0.002)


def ui_manifest(rng, dur):
    n = int(round(dur * SR))
    rise = ramp(0.0, 1.0, n) ** 2
    drift = ramp(0.98, 1.0, n)
    chord = sum(saw(f * drift, n) for f in (110.0, 164.8, 220.0, 329.6))
    chord = sweep_filter(chord, "lowpass", ramp(300.0, 4000.0, n, "exp"))
    hit = int(dur * 0.55 * SR)
    boom = np.zeros(n)
    boom[hit:] = sine(ramp(90.0, 40.0, n - hit, "exp"), n - hit) * decay(n - hit, 0.35)
    return reverb(chord * rise * 0.25 + boom * 0.8, size=1.2, mix=0.3)


def ui_win(rng, dur):
    n = int(round(dur * SR))
    out = np.zeros(n)
    for i, f in enumerate((261.6, 329.6, 392.0, 523.3)):
        m = int(0.9 * SR)
        note = lowpass(saw(f, m) * 0.5 + sine(f * 2.0, m) * 0.3, 2600.0) * adsr(m, 0.01, 0.1, 0.6, 0.3)
        place(out, note, 0.13 * i)
    m = n - int(0.55 * SR)
    chord = lowpass(sum(saw(f, m) for f in (261.6, 329.6, 392.0, 523.3)) * 0.18, 3000.0)
    place(out, chord * adsr(m, 0.02, 0.3, 0.5, 0.8), 0.55)
    return reverb(out, size=1.3, mix=0.28)


def ui_lose(rng, dur):
    n = int(round(dur * SR))
    out = np.zeros(n)
    for i, f in enumerate((392.0, 349.2, 311.1, 261.6)):
        m = int(0.7 * SR)
        note = lowpass(saw(f, m) * 0.5 + sine(f * 0.5, m) * 0.4, 1600.0) * adsr(m, 0.01, 0.12, 0.5, 0.35)
        place(out, note, 0.3 * i)
    return reverb(out, size=1.4, mix=0.32)
```

and register them after the `CUES` dict's closing brace (next to the other `CUES[...] = ...` lines):

```python
for _name, _fn, _dur in (
    ("ui_hover", ui_hover, 0.06), ("ui_click", ui_click, 0.12), ("ui_focus", ui_focus, 0.1),
    ("ui_buzz", ui_buzz, 0.25), ("ui_pause", ui_pause, 0.25), ("ui_manifest", ui_manifest, 1.6),
    ("ui_win", ui_win, 2.4), ("ui_lose", ui_lose, 2.2),
):
    CUES[_name] = ("ui", _fn, _dur, False)
```

Then:

```bash
for c in ui_hover ui_click ui_focus ui_buzz ui_pause ui_manifest ui_win ui_lose; do python tools/audio/synth.py --only $c; done
python tools/audio/synth.py --verify
```

Expected: eight `wrote assets/audio/ui/...` lines, then `audio verify: <N> cues, 0 problems` with N eight higher than before. If a cue reports a problem (a click at the start, a DC offset, a length off by more than 5%), fix the builder — do not loosen `verify()`.

Open Godot once headless so it imports the new WAVs (`bash tools/test.sh` does), and commit their `.import` files with them.

- [ ] **Step 3: The catalog and the player**

In `src/audio/sfx.gd`'s `CATALOG`, add:

```gdscript
	&"ui_hover": {"path": "res://assets/audio/ui/ui_hover.wav", "db": -16.0},
	&"ui_click": {"path": "res://assets/audio/ui/ui_click.wav", "db": -10.0},
	&"ui_focus": {"path": "res://assets/audio/ui/ui_focus.wav", "db": -12.0},
	&"ui_buzz": {"path": "res://assets/audio/ui/ui_buzz.wav", "db": -10.0},
	&"ui_pause": {"path": "res://assets/audio/ui/ui_pause.wav", "db": -10.0},
	&"ui_manifest": {"path": "res://assets/audio/ui/ui_manifest.wav", "db": -6.0},
	&"ui_win": {"path": "res://assets/audio/ui/ui_win.wav", "db": -6.0},
	&"ui_lose": {"path": "res://assets/audio/ui/ui_lose.wav", "db": -6.0},
```

Create `src/audio/ui_sound.gd`:

```gdscript
class_name UiSound
extends Node
## Interface sounds (spec §8: synthesized like the effect audio). They are not in the world, so they are not
## positional, and they cannot hang off a battlefield -- the title, the draft and the results have none. One
## small pool of players under the scene tree's root, made the first time a sound plays and kept across every
## screen change, so a sting started on one screen finishes on the next.

## Every interface cue, so a test can prove each one exists.
const CUES := [&"ui_hover", &"ui_click", &"ui_focus", &"ui_buzz", &"ui_pause", &"ui_manifest", &"ui_win", &"ui_lose"]
const POOL := 6

static var _node: UiSound

var _players: Array[AudioStreamPlayer] = []
var _next := 0
## Sounds asked for before the pool reached the tree.
var _pending: Array = []


## Play an interface cue. Safe from anywhere, including before the pool exists.
static func play(cue: StringName, db_offset := 0.0) -> void:
	if DisplayServer.get_name() == "headless":
		return  # no audio to play, and a pool made during the headless test suite would outlive it and leak
	if not Sfx.CATALOG.has(cue):
		push_warning("Unknown ui sound: %s" % cue)
		return
	if not is_instance_valid(_node):
		var tree := Engine.get_main_loop() as SceneTree
		if tree == null or tree.root == null:
			return
		_node = UiSound.new()
		_node.name = "UiSound"
		# Deferred: a sound can be asked for while the root is still adding the main scene's children.
		tree.root.add_child.call_deferred(_node)
	if _node.is_inside_tree():
		_node._play(cue, db_offset)
	else:
		_node._pending.append([cue, db_offset])


func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = Sfx.BUS
		add_child(p)
		_players.append(p)
	for s: Array in _pending:
		_play(s[0], s[1])
	_pending.clear()


func _play(cue: StringName, db_offset: float) -> void:
	var entry: Dictionary = Sfx.CATALOG[cue]
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = Sfx.load_stream(cue)
	p.volume_db = float(entry.get("db", 0.0)) + db_offset
	p.play()
```

- [ ] **Step 4: Play them**

- **Title, Results, Pause** (`_on_gui_input` in each): when the hovered action changes to a non-empty one, `UiSound.play(&"ui_hover")`; when a click lands on an action, `UiSound.play(&"ui_click")` before emitting it.
- **Prepare** (`_on_gui_input`): a hover change onto a card or MANIFEST plays `ui_hover`; toggling a card plays `ui_click`; MANIFEST (click or Enter) with four picked plays `ui_manifest` instead of `ui_click`. A click on MANIFEST with fewer than four plays `ui_buzz`.
- **HUD** (`_on_cast_refused`): `UiSound.play(&"ui_buzz")` next to the red flash — spec §1's buzz.
- **Mission** (`start()`, right after `_aim.setup(...)`):

```gdscript
	_aim.picked.connect(func(s: int) -> void:
		if s >= 0:
			UiSound.play(&"ui_focus"))
```

- **Game**: `_open_pause()` plays `ui_pause`; in `go_to()`'s `Screen.RESULTS` branch, after `res.setup(result)`, play `ui_win` if `result.won` else `ui_lose`.

- [ ] **Step 5: Run everything**

```bash
bash tools/test.sh
python tools/audio/synth.py --verify
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/game.tscn --audio-driver Dummy -- --flow-test 2>&1 | grep -E "FLOW result|FLOW FAIL|ERROR|SCRIPT|WARNING"
```

Expected: `checks=592 failures=0` (+2); `audio verify: ... 0 problems`; `FLOW result checks=20 failures=0` with no warnings (the flow test walks every screen, so an unknown cue would warn here).

Render spectrograms of the eight cues (`python tools/audio/synth.py --spectrograms captures/ui_spectra` — it writes one PNG per cue; if it writes all cues, look at the `ui_*` ones) and look at them: the buzz low and harsh, the hover a short high blip, the win rising, the lose falling. You cannot listen; the user will, at the checkpoint after Task 6.

- [ ] **Step 6: Commit**

```bash
git add tools/audio/synth.py src/audio/sfx.gd src/audio/ui_sound.gd src/audio/ui_sound.gd.uid assets/audio/ui src/game/ui/title_screen.gd src/game/ui/prepare_screen.gd src/game/ui/results_screen.gd src/game/ui/pause_menu.gd src/game/ui/hud.gd src/game/mission.gd src/game/game.gd tests/test_results.gd
git commit -m "feat: interface sounds" -m "Eight synthesized interface cues -- hover, click, focus, the refused-cast buzz spec 1 asked for, pause, the MANIFEST sting, and a win and a lose sting on the results -- played by UiSound, a small non-positional pool under the scene tree's root, because the title, the draft and the results have no battlefield and a sting has to outlive the screen that started it." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Voices in the crowd

**Files:**
- Modify: `tools/audio/synth.py` (`cit_yelp_1..4`, `cit_shout_1..3`, `sol_rally`)
- Modify: `src/audio/sfx.gd`
- Modify: `src/game/crowd/crowd.gd`
- Modify: `src/game/mission.gd` (hands the crowd the battlefield's `Sfx`)
- Create: `tests/test_voices.gd`
- Modify: `tests/run_all.gd`

**Why:** playtest note 4 asks for the citizens' sound. The user chose synthesized yelps, capped so 160 people never drown the powers. A cast that panics thirty people plays at most a few yelps — from the people nearest the blow — and a town-wide budget refills at a few voices a second; the soldiers' rally gets one horn.

**Interfaces:**
- Produces: `Crowd.sfx: Node` (the battlefield's `Sfx`, or null — tests count voices without playing them), `Crowd.voices_played: int`, `const Crowd.VOICE_BUDGET`, `const Crowd.VOICES_PER_CAST`; cues `cit_yelp` (4 variants), `cit_shout` (3), `sol_rally`.

- [ ] **Step 1: Write the failing test**

Create `tests/test_voices.gd`:

```gdscript
extends RefCounted
## The crowd's voices: a panic is heard from the few people nearest the blow, a town-wide budget stops a
## crowd drowning the powers, the budget refills, and every crowd cue exists.


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

	# Gather a crowd around one spot and frighten it: only the nearest few cry out.
	for i in 30:
		crowd.citizens[i].ground_pos = Vector2(float(i % 6) * 0.3, float(i / 6) * 0.3)
	crowd.on_cast(Vector2(0.8, 0.6))
	var heard := crowd.voices_played
	t.check(heard >= 1 and heard <= Crowd.VOICES_PER_CAST, "thirty frightened people are heard as a few voices (%d)" % heard)

	# The budget itself: however many voices ask at once, no more than it holds. (Casting again at the same
	# spot would not test this -- everyone there is already panicking, so nobody new cries out.)
	for i in 10:
		crowd._voice(crowd.citizens[40], &"cit_shout")
	t.check(crowd.voices_played <= int(Crowd.VOICE_BUDGET),
		"ten more voices at once stop at the budget (%d of %d)" % [crowd.voices_played, int(Crowd.VOICE_BUDGET)])
	var spent := crowd.voices_played
	crowd.advance(1.0)
	crowd._voice(crowd.citizens[40], &"cit_shout")
	t.check(crowd.voices_played == spent + 1, "a second later the budget has refilled (%d -> %d)" % [spent, crowd.voices_played])

	var missing := ""
	for cue: StringName in [&"cit_yelp", &"cit_shout", &"sol_rally"]:
		if not Sfx.CATALOG.has(cue):
			missing += " %s" % cue
	t.check(missing == "", "every crowd cue is in the catalog (missing:%s)" % missing)
	t.check(ResourceLoader.exists("res://assets/audio/crowd/cit_yelp_4.wav") and ResourceLoader.exists("res://assets/audio/crowd/sol_rally.wav"),
		"and on disk")

	crowd.clear()
	field.clear()
	field.free()
	env.clear()
	env.free()
	town.free()
	crowd.free()
	world.free()
```

Register it in `tests/run_all.gd` after `"res://tests/test_sort.gd",`. Run `bash tools/test.sh` — expected: it fails to load (`voices_played` does not exist).

- [ ] **Step 2: Synthesize the voices**

In `tools/audio/synth.py`, after the interface builders:

```python
# --------------------------------------------------------------------------
# The crowd (KAK milestone 5): crude voices -- a buzzy source through a few vowel formants. Stylized on
# purpose: heard in a crowd under a volcano, they need to read as people, not to fool anyone.
# --------------------------------------------------------------------------

VOWELS = (
    ((800.0, 1.0), (1150.0, 0.7), (2800.0, 0.3)),   # ah
    ((400.0, 1.0), (2000.0, 0.6), (2800.0, 0.3)),   # eh
    ((700.0, 1.0), (1800.0, 0.6), (2600.0, 0.3)),   # ae
    ((500.0, 1.0), (900.0, 0.7), (2500.0, 0.25)),   # oh
)


def _voice(rng, n, f0, vowel, breath=0.15):
    src = saw(f0, n) + 0.3 * square(f0, n, 0.2)
    out = np.zeros(n)
    for fc, gain in vowel:
        out += bandpass(src, fc * 0.85, fc * 1.15) * gain
    return out + bandpass(noise(n, rng), 1500.0, 5000.0) * breath


def cit_yelp(rng, dur, v):
    n = int(round(dur * SR))
    k = np.linspace(0.0, 1.0, n)
    base = (380.0, 460.0, 330.0, 520.0)[v - 1]
    f0 = base * (1.0 + 0.55 * np.sin(np.pi * np.minimum(k * 1.4, 1.0)))
    f0 = f0 * (1.0 + 0.03 * np.sin(2.0 * np.pi * 7.0 * k * dur))
    return saturate(_voice(rng, n, f0, VOWELS[v - 1]) * adsr(n, 0.02, 0.1, 0.7, 0.18), 1.5)


def cit_shout(rng, dur, v):
    n = int(round(dur * SR))
    k = np.linspace(0.0, 1.0, n)
    f0 = (210.0, 260.0, 180.0)[v - 1] * (1.15 - 0.25 * k)
    return saturate(_voice(rng, n, f0, VOWELS[v % 4], breath=0.25) * adsr(n, 0.01, 0.08, 0.8, 0.2), 2.0)


def sol_rally(rng, dur):
    n = int(round(dur * SR))
    k = np.linspace(0.0, 1.0, n)
    f0 = 146.8 * (1.0 + 0.06 * np.minimum(k * 6.0, 1.0)) * (1.0 + 0.008 * np.sin(2.0 * np.pi * 5.0 * k * dur))
    horn = saw(f0, n) + 0.5 * saw(f0 * 2.0, n) + 0.25 * saw(f0 * 3.0, n)
    horn = lowpass(horn, 1400.0) * adsr(n, 0.12, 0.2, 0.8, 0.45)
    return reverb(saturate(horn * 0.5, 1.5), size=1.4, mix=0.3)
```

and register them next to the interface cues:

```python
CUES["sol_rally"] = ("crowd", sol_rally, 1.4, False)
for _v in range(1, 5):
    CUES[f"cit_yelp_{_v}"] = ("crowd", lambda rng, dur, v=_v: cit_yelp(rng, dur, v), 0.45, False)
for _v in range(1, 4):
    CUES[f"cit_shout_{_v}"] = ("crowd", lambda rng, dur, v=_v: cit_shout(rng, dur, v), 0.55, False)
```

Generate them (`--only` each of the eight names) and run `--verify` — `0 problems`, eight more cues.

In `src/audio/sfx.gd`'s `CATALOG`:

```gdscript
	&"cit_yelp": {"path": "res://assets/audio/crowd/cit_yelp_%d.wav", "variants": 4, "db": -10.0, "voices": 4, "jitter": 0.12},
	&"cit_shout": {"path": "res://assets/audio/crowd/cit_shout_%d.wav", "variants": 3, "db": -12.0, "voices": 3, "jitter": 0.1},
	&"sol_rally": {"path": "res://assets/audio/crowd/sol_rally.wav", "db": -6.0},
```

- [ ] **Step 3: Give the crowd a voice, and a budget**

In `src/game/crowd/crowd.gd`, add:

```gdscript
## Voices: at most this many a second across the whole town, refilling steadily, so 160 people can never drown
## the powers. A cast is heard from at most VOICES_PER_CAST of the people it frightened, the nearest first.
const VOICE_BUDGET := 4.0
const VOICES_PER_CAST := 3

## The battlefield's Sfx; null in tests, which still count what would have played.
var sfx: Node
var voices_played := 0
var _voice_tokens := VOICE_BUDGET
```

```gdscript
## One voice from `p`, if the budget allows it.
func _voice(p: Person, cue: StringName) -> void:
	if _voice_tokens < 1.0:
		return
	_voice_tokens -= 1.0
	voices_played += 1
	if sfx != null:
		sfx.play(cue, p.ground_pos)


## A few of the people just frightened near `at` cry out, nearest first.
func _yelp(frightened: Array[Person], at: Vector2) -> void:
	frightened.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(at) < b.ground_pos.distance_squared_to(at))
	for i in mini(frightened.size(), VOICES_PER_CAST):
		_voice(frightened[i], &"cit_yelp")
```

In `advance(delta)`, refill:

```gdscript
	_voice_tokens = minf(VOICE_BUDGET, _voice_tokens + VOICE_BUDGET * delta)
```

In `on_cast()`, collect the people it panicked and let them be heard — change the inner loop so it records who changed:

```gdscript
	var frightened: Array[Person] = []
	for p in citizens:
		if not is_instance_valid(p) or not p.is_alive():
			continue
		for point in points:
			if p.ground_pos.distance_to(point) <= PANIC_CAST:
				var was := p.mind
				p.panic(point)
				if p.mind == Person.Mind.PANIC and was != Person.Mind.PANIC:
					frightened.append(p)
				break
	_yelp(frightened, ground)
```

In `_on_structure_destroyed()`, do the same for the people it panics (collect, then `_yelp(frightened, s.center())`). In `add_alarm()`, inside the once-only town-wide flight block, after the loop that sends everyone running: two shouts from the first two living citizens (`_voice(p, &"cit_shout")`). In `rally()`, the first time it runs (guarded by `_rallied` as it already is), play the horn once at the Citadel, outside the budget:

```gdscript
	if sfx != null:
		sfx.play(&"sol_rally", TownLayout.CITADEL_ORIGIN)
```

Reset `_voice_tokens = VOICE_BUDGET` and `voices_played = 0` in `clear()`.

In `src/game/mission.gd`'s `start()`, right after `_crowd.setup(...)`:

```gdscript
	_crowd.sfx = _bf.ctx.sfx
```

- [ ] **Step 4: Run everything**

```bash
bash tools/test.sh
python tools/audio/synth.py --verify
SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test 2>&1 | grep -E "MISSION test|ERROR|SCRIPT|WARNING"
```

Expected: `checks=597 failures=0` (+5); `0 problems`; one `MISSION test` line and no warnings (an unknown cue would warn).

- [ ] **Step 5: Commit**

```bash
git add tools/audio/synth.py src/audio/sfx.gd assets/audio/crowd src/game/crowd/crowd.gd src/game/mission.gd tests/test_voices.gd tests/test_voices.gd.uid tests/run_all.gd
git commit -m "feat: voices in the crowd" -m "Synthesized yelps and shouts -- a buzzy source through vowel formants, stylized on purpose -- and a war horn for the soldiers' rally. A cast is heard from at most three of the people it frightened, nearest first, and a town-wide budget of four voices a second, refilling steadily, keeps 160 people from drowning the powers." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

**User checkpoint:** the controller sends the user `assets/audio/crowd/cit_yelp_1.wav`, `cit_shout_1.wav`, `sol_rally.wav`, `assets/audio/ui/ui_buzz.wav`, `ui_manifest.wav` and `ui_win.wav` to listen to, and waits for approval before Task 7.

---
### Task 7: A moving preview on the draft

**Files:**
- Modify: `src/game/power_book.gd` (clip constants, `clip()`)
- Modify: `src/sandbox/sandbox.gd` (`--capture-clip`)
- Create: `assets/clips/<key>.png` × 11 (generated, with their `.import` files)
- Modify: `src/game/ui/prepare_screen.gd` (plays the clip on hover; `preview(key)` for captures)
- Modify: `src/game/game.gd` (`--hover=<key>` for the Prepare photograph)
- Modify: `tests/test_draft.gd`

**Why:** playtest note 5 — a moving example instead of a larger icon. The user chose pre-rendered loops: each power is recorded once, from the sandbox that frames every power the way it was approved, as a sprite sheet of 16 frames spread evenly over the whole effect. The draft plays it at 8 frames a second — a two-second time-lapse of the power, start to finish — and costs nothing at runtime beyond one texture per power.

**Interfaces:**
- Produces: `PowerBook.CLIP_DIR`, `CLIP_FRAMES := 16`, `CLIP_COLUMNS := 4`, `CLIP_SIZE := Vector2i(152, 86)`, `CLIP_FPS := 8.0`, `clip_path(key) -> String`, `clip(key) -> Texture2D` (null when not recorded), `clip_frame(i) -> Rect2`; `PrepareScreen.preview(key: String) -> void`; Game `--hover=<key>` with `--show=prepare`.

- [ ] **Step 1: Write the failing test**

At the end of `tests/test_draft.gd`'s `run()`:

```gdscript
	# Every power has a recorded preview, laid out the way the draft reads it.
	var unrecorded := ""
	for key in PowerBook.keys():
		if PowerBook.clip(key) == null:
			unrecorded += " " + key
	t.check(unrecorded == "", "every power has a preview clip (missing:%s)" % unrecorded)
	var sheet := PowerBook.clip("nova")
	var rows := ceili(float(PowerBook.CLIP_FRAMES) / PowerBook.CLIP_COLUMNS)
	t.check(sheet != null and sheet.get_size() == Vector2(PowerBook.CLIP_SIZE.x * PowerBook.CLIP_COLUMNS, PowerBook.CLIP_SIZE.y * rows),
		"a sheet holds its frames in a %d-column grid (%s)" % [PowerBook.CLIP_COLUMNS, sheet.get_size() if sheet != null else "none"])
```

Run `bash tools/test.sh` — expected: `test_draft.gd` fails to load (`PowerBook.clip` does not exist).

- [ ] **Step 2: Where clips live**

In `src/game/power_book.gd`, add after `ICON_DIR`:

```gdscript
## Preview clips for the draft: each power recorded once from the sandbox (bash tools/capture.sh --capture-clip)
## into one sprite sheet -- CLIP_FRAMES frames spread over the whole effect, CLIP_COLUMNS to a row.
const CLIP_DIR := "res://assets/clips/"
const CLIP_FRAMES := 16
const CLIP_COLUMNS := 4
const CLIP_SIZE := Vector2i(152, 86)
## How fast the draft plays a clip: 16 frames at 8 a second is a two-second time-lapse of the whole power.
const CLIP_FPS := 8.0
```

and after `hud_icon()`:

```gdscript
static func clip_path(key: String) -> String:
	return CLIP_DIR + key + ".png"


## The power's preview sheet, or null when it has not been recorded.
static func clip(key: String) -> Texture2D:
	var path := clip_path(key)
	return load(path) if ResourceLoader.exists(path) else null


## Where frame `i` sits in a sheet.
static func clip_frame(i: int) -> Rect2:
	return Rect2(Vector2(float(i % CLIP_COLUMNS) * CLIP_SIZE.x, float(i / CLIP_COLUMNS) * CLIP_SIZE.y), Vector2(CLIP_SIZE))
```

- [ ] **Step 3: Record them**

In `src/sandbox/sandbox.gd`, add a branch to the flag dispatch in `_ready()`, next to `--capture-all`:

```gdscript
	elif "--capture-clip" in args:
		_capture_clips(Battlefield.arg_value(args, "--only"))
```

and the recorder, after `_capture_all()`:

```gdscript
## One preview sheet per power for the draft: PowerBook.CLIP_FRAMES frames spread evenly over the effect's
## whole run, each the middle of the screen at half size. bash tools/capture.sh --capture-clip [--only=nova]
func _capture_clips(only: String) -> void:
	var crop := PowerBook.CLIP_SIZE * 2
	var rows := ceili(float(PowerBook.CLIP_FRAMES) / PowerBook.CLIP_COLUMNS)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PowerBook.CLIP_DIR))
	for entry in EFFECTS:
		var key: String = entry.key
		if only != "" and only != key:
			continue
		if not ResourceLoader.exists(entry.path) or not CAPTURES.has(key):
			continue
		var plan: Dictionary = CAPTURES[key]
		set_index = entry.set
		_reset_world(7)
		_hud.text = ""
		await _bf.wait_frames(10)
		var extra := {}
		if plan.has("dir"):
			extra["dir"] = plan.dir
		var fx := _cast_entry(entry, plan.target, extra)
		var run := fx.duration
		var sheet := Image.create(PowerBook.CLIP_SIZE.x * PowerBook.CLIP_COLUMNS, PowerBook.CLIP_SIZE.y * rows, false, Image.FORMAT_RGBA8)
		for i in PowerBook.CLIP_FRAMES:
			var at := run * (float(i) + 0.5) / float(PowerBook.CLIP_FRAMES)
			while is_instance_valid(fx) and fx.t < at:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			var from := Vector2i((img.get_width() - crop.x) / 2, (img.get_height() - crop.y) / 2)
			var frame := img.get_region(Rect2i(from, crop))
			frame.convert(Image.FORMAT_RGBA8)
			frame.resize(PowerBook.CLIP_SIZE.x, PowerBook.CLIP_SIZE.y, Image.INTERPOLATE_BILINEAR)
			sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, PowerBook.CLIP_SIZE), Vector2i(PowerBook.clip_frame(i).position))
		var out := ProjectSettings.globalize_path(PowerBook.clip_path(key))
		sheet.save_png(out)
		print("clip ", out)
		while is_instance_valid(fx):
			await get_tree().process_frame
	await _bf.quit()
```

(`capture.sh` gives `--capture-clip` the same fixed 60 fps and seed 7 as every other capture, and defaults to the sandbox scene.) Then:

```bash
bash tools/capture.sh --capture-clip 2>&1 | grep -E "^clip|ERROR|SCRIPT"
bash tools/test.sh
```

Expected: eleven `clip .../assets/clips/<key>.png` lines. The test run imports them; commit each `.png` with its `.import`.

**Look at them.** Build one contact image of every sheet's middle frame (frame 8) with PIL and Read it: each should show its power clearly — the nova's dome, the tornado's funnel, the tsunami's wall — not an empty field or the sandbox's labels. A clip that misses its power (framed on nothing, or cut off) is reported with its key, not re-framed by hand.

- [ ] **Step 4: Play the clip on hover**

In `src/game/ui/prepare_screen.gd`, add state:

```gdscript
## Each power's preview sheet, loaded once in setup() like the icons.
var _clips := {}
var _clip_t := 0.0
var _clip_frame := 0
```

In `setup()`, in the loop that loads the icons:

```gdscript
		_clips[key] = PowerBook.clip(key)
```

Wherever `_hover` changes (in `_on_gui_input`), restart the clip:

```gdscript
			_clip_t = 0.0
			_clip_frame = 0
```

Add:

```gdscript
func _process(delta: float) -> void:
	if _clips.get(_hover) == null:
		return
	_clip_t += delta
	var f := int(_clip_t * PowerBook.CLIP_FPS) % PowerBook.CLIP_FRAMES
	if f != _clip_frame:
		_clip_frame = f
		_ui.queue_redraw()


## Show a power's preview as if the mouse were on its card -- for photographs of this screen.
func preview(key: String) -> void:
	_hover = key
	_clip_t = 0.0
	_clip_frame = 0
	_ui.queue_redraw()
```

In `_draw_panel()`, replace the hovered-card section (from `var art_at := ...` to the end of the function) with the clip and two lines under it:

```gdscript
	var clip_rect := Rect2(Vector2(PANEL.position.x + (PANEL.size.x - PowerBook.CLIP_SIZE.x) * 0.5, PANEL.end.y - 116.0),
		Vector2(PowerBook.CLIP_SIZE))
	var sheet: Texture2D = _clips.get(_hover)
	if sheet != null:
		_ui.draw_texture_rect_region(sheet, clip_rect, PowerBook.clip_frame(_clip_frame))
	else:
		# No recording for this power: its card art, centred where the clip would be.
		var art: Texture2D = _art.get(_hover)
		if art != null:
			_ui.draw_texture_rect(art, Rect2(clip_rect.get_center() - Vector2(42, 42), Vector2(84, 84)), false)
	UiTheme.frame(_ui, clip_rect, true)
	var tx := PANEL.position.x + 4.0
	UiTheme.text(_ui, Vector2(tx, clip_rect.end.y + 12.0), String(p.name), UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(tx, clip_rect.end.y + 12.0 + UiTheme.LINE_SMALL),
		"%d DP  %d s  %s" % [int(p.dp), int(p.cooldown), String(p.aim)], UiTheme.SIZE_SMALL)
```

In `src/game/game.gd`'s `_ready()`, in the `"prepare"` branch of `match show:`, after `go_to(Screen.PREPARE)`:

```gdscript
			var hover := Battlefield.arg_value(args, "--hover")
			if hover != "" and _screen_node is PrepareScreen:
				(_screen_node as PrepareScreen).preview(hover)
```

- [ ] **Step 5: Run the tests and look**

```bash
bash tools/test.sh
SCENE=res://scenes/game.tscn bash tools/capture.sh --show=prepare --hover=tsunami --capture 2>&1 | grep -E "captured|ERROR|SCRIPT"
```

Expected: `checks=599 failures=0` (+2). Look at `captures/screen_prepare.png`: the clip in its gold frame at the bottom of the left panel, the name and numbers under it, **the briefing above it not overlapping it** — if the briefing's last lines reach the clip, shorten the briefing's POWER line (it is the longest) rather than moving the clip, and say what you changed.

- [ ] **Step 6: Commit**

```bash
git add src/game/power_book.gd src/sandbox/sandbox.gd assets/clips src/game/ui/prepare_screen.gd src/game/game.gd tests/test_draft.gd
git commit -m "feat: a moving preview on the draft" -m "Hovering a power on the draft plays a two-second time-lapse of it instead of a larger icon: sixteen frames spread over the whole effect, recorded once from the sandbox (which frames every power the way it was approved) by the new --capture-clip mode into one sprite sheet per power. Nothing runs at draft time but a texture and a frame counter." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

**User checkpoint:** the controller sends the user the contact image of the eleven clips and the `--hover` photograph of the draft, and waits for approval before Task 8.

---

### Task 8: A fade, a slow ending, and a labelled bar

**Files:**
- Create: `src/game/ui/fader.gd`
- Modify: `src/game/game.gd` (fade into a mission; the flow test)
- Modify: `src/game/mission.gd` (the slow-motion ending)
- Modify: `src/game/ui/hud.gd` (legend and tinted status)
- Modify: `tests/test_hud.gd`

**Why:** three small notes.
- **Note 6** — "blank green screen after click Manifest for a second." That is the mission's battlefield standing empty while its shaders prewarm, before `start()` builds the town. The screen fades to black, the mission loads behind it, and it fades back in once the town is there.
- **Note 9** — "Not cut to the summary page suddenly … slow motion for a second and see the last ability to finish." The ending plays at 0.3× for 1.6 real seconds before Results.
- **Note 8** — the user chose both: a legend under the five-colour stability bar, and the top-right figures tinted with the colour of the part they drive (citizens → Population, soldiers → Military, destroyed → Infrastructure).

**Interfaces:**
- Produces: `Fader` (a `CanvasLayer`): `fade_out(seconds)`, `fade_in(seconds)` (awaitable), `is_clear() -> bool`; `Game.FADE_OUT`, `Game.FADE_IN`; `Mission.ENDING_SECONDS`, `Mission.ENDING_TIME_SCALE`; `Hud.LEGEND`, `Hud.status_segments() -> Array`.

- [ ] **Step 1: Write the failing tests**

In `tests/test_hud.gd`, after the status-line check (`t.check(hud.status_text().contains("110") ...`):

```gdscript
	# The five-colour bar has a legend, and the figures top right wear the colour of the part they drive.
	t.check(Hud.LEGEND.size() == 5 and Hud.LEGEND[3][1] == 3, "the stability bar has a five-entry legend in part order")
	var segs := hud.status_segments()
	t.check(segs[0][1] == UiTheme.STABILITY_COLS[0] and segs[1][1] == UiTheme.STABILITY_COLS[3] and segs[2][1] == UiTheme.STABILITY_COLS[1],
		"citizens are Population's colour, soldiers Military's, destroyed Infrastructure's")
```

Run `bash tools/test.sh` — expected: `test_hud.gd` fails to load.

- [ ] **Step 2: The legend and the tinted figures**

In `src/game/ui/hud.gd`, add:

```gdscript
## The stability bar's legend: a short name for each part and its colour's index, in the bar's own order.
const LEGEND := [["Pop", 0], ["Infra", 1], ["Lead", 2], ["Mil", 3], ["Res", 4]]
```

change `OBJECTIVE_PANEL` to `Rect2(2.0, 2.0, 236.0, 60.0)` (one more row), and replace `status_text()` with:

```gdscript
## The city's state, top right, as [text, colour] pieces: each figure wears the colour of the stability part it
## drives, so the player can tell which number moves which part of the bar.
func status_segments() -> Array:
	return [
		["Citizens %d" % _crowd.alive_citizens(), UiTheme.STABILITY_COLS[0]],
		["Soldiers %d" % _crowd.alive_soldiers(), UiTheme.STABILITY_COLS[3]],
		["Destroyed %d" % _rules.buildings_down, UiTheme.STABILITY_COLS[1]],
		["Alarm %d%%" % roundi(_crowd.alarm), UiTheme.COL_TEXT],
	]


func status_text() -> String:
	var parts := PackedStringArray()
	for seg: Array in status_segments():
		parts.append(String(seg[0]))
	return "   ".join(parts)
```

Replace `_draw_status()`:

```gdscript
func _draw_status(w: float) -> void:
	var gap := UiTheme.width("   ", UiTheme.SIZE_SMALL)
	var segs := status_segments()
	var total := gap * float(segs.size() - 1)
	for seg: Array in segs:
		total += UiTheme.width(String(seg[0]), UiTheme.SIZE_SMALL)
	var x := w - total - 6.0
	for seg: Array in segs:
		UiTheme.text(self, Vector2(x, 14.0), String(seg[0]), UiTheme.SIZE_SMALL, seg[1])
		x += UiTheme.width(String(seg[0]), UiTheme.SIZE_SMALL) + gap
```

In `_draw_objectives()`, draw the legend on its own row under the bar, and move the escaped line down one row:

```gdscript
	# The legend: a swatch and a short name for each part, in the bar's order.
	var lx := 6.0
	for entry: Array in LEGEND:
		draw_rect(Rect2(lx, 31.0, 5.0, 5.0), UiTheme.STABILITY_COLS[int(entry[1])])
		UiTheme.text(self, Vector2(lx + 7.0, 38.0), String(entry[0]), UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		lx += 7.0 + UiTheme.width(String(entry[0]), UiTheme.SIZE_SMALL) + 8.0
```

and the escaped line's `Vector2(6.0, 45.0)` becomes `Vector2(6.0, 54.0)`.

- [ ] **Step 3: The fade**

Create `src/game/ui/fader.gd`:

```gdscript
class_name Fader
extends CanvasLayer
## Black over everything, faded in and out between screens. It covers the moment a new mission has a
## battlefield but no town yet, which showed as a second of bare green after MANIFEST.

var _rect: ColorRect


func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	add_child(_rect)


func fade_out(seconds: float) -> void:
	await _to(1.0, seconds)


func fade_in(seconds: float) -> void:
	await _to(0.0, seconds)


func is_clear() -> bool:
	return _rect.modulate.a <= 0.01


func _to(alpha: float, seconds: float) -> void:
	var tw := create_tween()
	tw.set_ignore_time_scale(true)  # hit-stop and the slow-motion ending must not stretch a fade
	tw.tween_property(_rect, "modulate:a", alpha, seconds)
	await tw.finished
```

In `src/game/game.gd`, add the constants and state:

```gdscript
## The fade into a mission: out to black, the mission loads behind it, back in once its town is there.
const FADE_OUT := 0.25
const FADE_IN := 0.35

var _fader: Fader
var _fading := false
```

In `_ready()`, before the first `go_to()`:

```gdscript
	_fader = Fader.new()
	_fader.name = "Fader"
	add_child(_fader)
```

In `on_action()`, after the unknown-action check, send every route into a mission (MANIFEST, Replay, Restart) through the fade — Resume is handled above it and stays instant:

```gdscript
	if to == Screen.MISSION:
		_faded_into_mission()
		return
	go_to(to)
```

and add:

```gdscript
## Into a mission behind the fade. Not awaited by the caller: the button that asked for it has done its part.
func _faded_into_mission() -> void:
	if _fading:
		return  # a second MANIFEST click during the fade
	_fading = true
	await _fader.fade_out(FADE_OUT)
	go_to(Screen.MISSION)
	if is_instance_valid(_mission) and not _mission.started():
		await _mission.prewarmed
	# Two frames for the town to be drawn once before it is shown.
	await get_tree().process_frame
	await get_tree().process_frame
	await _fader.fade_in(FADE_IN)
	_fading = false
```

- [ ] **Step 4: The slow ending**

In `src/game/mission.gd`, add:

```gdscript
## The ending plays out in slow motion before the results: the last blow lands, the dust settles, then the
## numbers (playtest note 9). Real seconds, and the time scale the world runs at meanwhile.
const ENDING_SECONDS := 1.6
const ENDING_TIME_SCALE := 0.3

var _ending := false
```

In `_on_over()`, replace its last line (`finished.emit(...)`) with `_play_ending(won, reason)`, and add:

```gdscript
func _play_ending(won: bool, reason: String) -> void:
	_ending = true
	_aim.unfocus()
	if not _scripted:
		# The scripted runs keep milestone 3's timing: no slow motion for them.
		_bf.ctx.impact.set_base_time_scale(ENDING_TIME_SCALE)
		await get_tree().create_timer(ENDING_SECONDS, true, false, true).timeout
		_bf.ctx.impact.set_base_time_scale(1.0)
	finished.emit(won, reason, _rules.score(), _rules.rank(), _rules.stat_lines())
```

In `_unhandled_input()`, directly after the `started()` guard:

```gdscript
	if _ending:
		return  # the mission is over; nothing to aim or pause
```

(`Game.go_to()` already resets `Engine.time_scale` to 1, so a slow ending cut short by anything still leaves the game at normal speed.)

- [ ] **Step 5: Keep the flow test walking**

In `src/game/game.gd`, add a helper:

```gdscript
## Wait until `cond` holds or `seconds` of real time pass; true when it held.
func _until(cond: Callable, seconds: float) -> bool:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not cond.call():
		if Time.get_ticks_msec() > end:
			return false
		await get_tree().process_frame
	return true
```

In `_flow_test()`:
- after `_on_prepare_action("manifest", prep)`, wait for the fade to bring the mission up before checking it:

```gdscript
	await _until(func() -> bool: return screen == Screen.MISSION and is_instance_valid(_mission) and _mission.started(), 5.0)
```

- after the intro checks, add: `step.call(_fader.is_clear(), "the fade has cleared once the mission is up")`;
- replace `await get_tree().create_timer(0.3).timeout` after `time_left = 0.01` with:

```gdscript
	var reached := await _until(func() -> bool: return screen == Screen.RESULTS, 5.0)
	step.call(reached, "the ending plays out before the results (slow motion, %.1f s)" % Mission.ENDING_SECONDS)
```

- after `on_action("results:replay")`, the same `_until(... MISSION ... started ..., 5.0)` wait before its checks.

- [ ] **Step 6: Run everything and look**

```bash
bash tools/test.sh
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/game.tscn --audio-driver Dummy -- --flow-test 2>&1 | grep -E "FLOW|ERROR|SCRIPT"
SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test 2>&1 | grep -E "MISSION test|ERROR|SCRIPT"
```

Expected: `checks=601 failures=0` (+2); `FLOW result checks=22 failures=0` (two new steps); one `MISSION test` line.

Look at `captures/mission_0050.png` (crop-and-enlarge the top-left and top-right): the legend's five swatches and names on their own row under the bar, inside the panel; the top-right figures in green, red and tan, still clear of the clock.

- [ ] **Step 7: Commit**

```bash
git add src/game/ui/fader.gd src/game/ui/fader.gd.uid src/game/game.gd src/game/mission.gd src/game/ui/hud.gd tests/test_hud.gd
git commit -m "feat: a fade, a slow ending and a labelled bar" -m "MANIFEST, Replay and Restart fade to black while the mission loads and fade back in once its town is drawn, instead of showing a second of bare green. A mission's end plays out at 0.3x for 1.6 s before the results, so the last blow is seen landing. The stability bar has a legend, and the figures top right wear the colour of the part they drive." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Milestone check

1. `bash tools/test.sh` — `checks=601 failures=0`, output pristine.
2. The digest exactly as in the Global Constraints; `python tools/audio/synth.py --verify` — `0 problems`.
3. `--flow-test` — `FLOW result checks=22 failures=0`; one `MISSION test`, one `CROWD result`, the four screen photographs plus the hovered draft.
4. A bench line next to milestone 4's.
5. Hand `play.bat` to the user with the ten playtest notes as a checklist, the same numbering, and ask for the next round of notes — including whether the escape limit still feels right with the faster crowd, and whether regeneration alone is now too little.
6. Tornado Tempest's wander is still open (note 2), by the user's choice.
