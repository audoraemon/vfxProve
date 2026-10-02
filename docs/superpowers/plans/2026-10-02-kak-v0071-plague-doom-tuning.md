# KAK v0.07.1 Pestilence and Silent Doom Tuning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** make Pestilence fast and readable (soldiers catch it too), and make Silent Doom a quick, sure kill of everyone in its radius.
- Pestilence: 5 s to die, spreads every second, a strong green-to-red tint, a pulsing ring, a green puff on each spread.
- Silent Doom: 2.5 s cooldown, takes everyone within its radius.

**Architecture:**
- Rule changes are constant and guard edits in `PlagueManager`, `Person.infect()`, `PestilenceFx.victims_at()`, `SilentDoom.victims_at()` and `PowerBook`.
- Looks are split by cost:
  - **In each person's sprite:** a 5-step tint, so it redraws 5 times over the sickness.
  - **Drawn by `PlagueManager`:**
    - one batched ring draw on the crowd's ground drawer;
    - `PixelParticles` puffs on the crowd's overlay drawer, capped.

**Tech Stack:** Godot 4.7.2, GDScript; headless tests in `tests/run_all.gd`; scripted scenarios in `tools/dev/behaviour_check.gd`.

## Global Constraints

- **Spec:** `docs/superpowers/specs/2026-10-02-kak-v0071-plague-doom-tuning-design.md`. Baseline tag `kak-v0.07`.
- **Repo and branch:** `F:\Godot\Git\vfxProve` (Git Bash `/f/Godot/Git/vfxProve`), branch `feat/vfx-proof`. Work in it directly.
- **Godot:** `G=/f/Godot/Godot_v4.7.2-stable_win64_console.exe`.
  - **Import:** after adding a script with a new `class_name` or a new test file, run `timeout 180 $G --headless --editor --path . --import >/dev/null 2>&1`. It writes the `.gd.uid` files.
  - **Tests:** `timeout 600 $G --headless --path . --script res://tests/run_all.gd 2>&1 | grep -v '^\s*at:' | grep -n "FAIL\|SCRIPT ERROR\|Parse Error\|checks="`. Expected: `checks=N failures=0`, with no SCRIPT ERROR or Parse Error lines.
  - **Digest:** `$G --headless --path . -s tools/dev/state_digest.gd` must print `digest=61267b7e90524d800bf1c3473a71146b`.
  - **crowd_check:** `$G --headless --path . --fixed-fps 60 -s tools/dev/crowd_check.gd`. Report its checksum; it was −346732806 at `kak-v0.07`.
  - **FLOW:** `$G --path . --audio-driver Dummy --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep "FLOW result"` must show `failures=0`.
- **Test style:**
  - A test file is `extends RefCounted` with `static func run(t) -> void:`, using `t.check(cond, "msg")` and `t.near(a, b, eps, "msg")`.
  - Register new files in `tests/run_all.gd` after `"res://tests/test_rescue.gd",`.
- **Code style:**
  - Tabs. `##` doc comments in full sentences.
  - Constants in UPPER_CASE, each with a `##` comment.
  - Match the surrounding density.
- **Git:**
  - `git add` explicit paths only, including new `.gd.uid` files.
  - Never add:
    - `default_bus_layout.tres`; run `git checkout -- default_bus_layout.tres` if it changed;
    - `captures/`, `.codex/`, `concepts/`, `docs/HUM_Game_Design_Document_v1.docx`.
  - Every commit message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
  - Do not push or tag; the controller does.
- **Numbers:**
  - `PLAGUE_LIFE` 5.0, `SPREAD_EVERY` 1.0. `SPREAD_R` 1.0, `SPREAD_CHANCE` 0.3, `PLAGUE_MAX` 60 unchanged.
  - Silent Doom: cooldown 2.5, `RADIUS` 0.8, 8 DP.
  - Looks: `SICK_STAGES` 5, `SICK_RED` `#b03a2e`, `SICK_SKIN` 0.6, `SICK_CLOTH` 0.55.
  - Ring: radius 0.32, 10 segments, pulsing at 3 Hz.
  - Puffs: `PUFF_MAX` 40, 6 particles each.

---

## Task 1: Plague rules — 5 s, spread each second, soldiers catch it

**Files:**
- Modify: `src/game/crowd/plague_manager.gd`, `src/game/crowd/person.gd`, `src/fx/curse/pestilence.gd`, `src/game/power_book.gd`, `tools/dev/behaviour_check.gd` (a comment), `tests/test_plague.gd`

**Interfaces:** produces `PlagueManager.PLAGUE_LIFE == 5.0`, `SPREAD_EVERY == 1.0`; soldiers accepted by `Person.infect()`, `PestilenceFx.victims_at()`, `PlagueManager._spread()` and `_collect()`.

- [ ] **Step 1: Update tests/test_plague.gd (failing first).**

Replace the header comment with:

```gdscript
## v0.06 Pestilence, retuned in v0.07.1: up to three caught at the cast, soldiers too; the sick slow down, pass it each
## second to those packed near them, and die PLAGUE_LIFE (5 s) later as ordinary deaths -- a soldier's counted as a
## soldier killed; never more than PLAGUE_MAX sick; it spreads inside a shelter, and one who dies in there is carried
## out first. The cast is no danger the town can see.
```

Replace the cast block:

```gdscript
	var victims := PestilenceFx.victims_at(field, at)
	t.check(victims.size() == PestilenceFx.INFECT_MAX and soldier not in victims and group[4] not in victims,
		"it catches the three nearest citizens")
	t.check(not soldier.infect(30.0), "soldiers do not catch it")
```

with:

```gdscript
	var victims := PestilenceFx.victims_at(field, at)
	t.check(victims.size() == PestilenceFx.INFECT_MAX and soldier in victims and group[3] not in victims
		and group[4] not in victims, "it catches the three nearest people, soldiers too")
	t.check(soldier.infect(PlagueManager.PLAGUE_LIFE) and soldier.sick_left > 0.0, "soldiers catch it (v0.07.1)")
```

After the spread check (`"a sick person passes it to some of those packed round it ..."`), add:

```gdscript
	# It passes to a soldier packed beside the sick, too.
	var s2: Person = crowd.soldiers[1]
	s2.ground_pos = sick.ground_pos + Vector2(0.05, -0.05)
	for k in 20:
		if s2.sick_left > 0.0:
			break
		plague._spread()
	t.check(s2.sick_left > 0.0, "it spreads to soldiers")
```

Replace the deaths block:

```gdscript
	# Deaths, as ordinary deaths.
	var killed := crowd.killed_citizens
	plague.step(PlagueManager.PLAGUE_LIFE)
	t.check(not sick.is_alive() and crowd.killed_citizens - killed >= 1 + caught and plague.deaths >= 1 + caught,
		"the sick die %d s after catching it (%d dead)" % [roundi(PlagueManager.PLAGUE_LIFE), crowd.killed_citizens - killed])
```

with:

```gdscript
	# Deaths, 5 s after catching it, as ordinary deaths -- a soldier's too.
	var killed := crowd.killed_citizens
	var killed_soldiers := crowd.killed_soldiers
	plague.step(PlagueManager.PLAGUE_LIFE - PlagueManager.SPREAD_EVERY - 0.5)
	t.check(sick.is_alive(), "still alive half a second before its time")
	plague.step(1.0)
	t.check(not sick.is_alive(), "the sick die %.0f s after catching it" % PlagueManager.PLAGUE_LIFE)
	plague.step(PlagueManager.PLAGUE_LIFE)
	t.check(crowd.killed_citizens - killed >= 1 + caught and plague.deaths >= 1 + caught,
		"as ordinary deaths (%d dead)" % (crowd.killed_citizens - killed))
	t.check(crowd.killed_soldiers - killed_soldiers >= 1, "a soldier dies of it too, counted as a soldier killed")
```

In the shelter block, change `for k in 5:` to `for k in 3:`.

- [ ] **Step 2: Run the tests.** Expected: FAIL on "it catches the three nearest people, soldiers too" and "soldiers catch it".

- [ ] **Step 3: Implement.**

`src/game/crowd/plague_manager.gd`:
- Set `const PLAGUE_LIFE := 5.0` and `const SPREAD_EVERY := 1.0`.
- In the class doc comment:
  - replace "Soldiers do not catch it." with "Soldiers catch it too (v0.07.1).";
  - add "v0.07.1: death 5 s after catching it, spreading each second." at the end.
- In `_spread()`, remove `not q.soldier and ` from the condition.
- In `_collect()`, change `for p in _crowd.citizens:` to `for p in _crowd.citizens + _crowd.soldiers:`.

`src/game/crowd/person.gd`, in `infect()`:
- change `if soldier or state == State.DEAD or sick_left > 0.0:` to `if state == State.DEAD or sick_left > 0.0:`;
- change its doc comment to "Pestilence (v0.06): catch the plague, with `seconds` to live. Soldiers too (v0.07.1); the dead and the already sick do not."

`src/fx/curse/pestilence.gd`:
- In `victims_at()`, remove `not p.soldier and ` from the condition. Its doc comment becomes "the nearest healthy people within reach, soldiers too, INFECT_MAX at most."
- In the class doc comment, replace "Soldiers do not catch it." with "Soldiers catch it too (v0.07.1)."

`src/game/power_book.gd`: the pestilence entry's `"shape"` becomes `"a fast plague spreading through crowds"`.

`tools/dev/behaviour_check.gd`, header comment near line 33: the clip note says soldiers cannot be "infected". Drop "or infected" (they can be now); leave the rest.

- [ ] **Step 4: Run the full suite.** Expected: `failures=0`.
  - `tests/test_rescue.gd` uses `PlagueManager.PLAGUE_LIFE` and must still pass.
  - If any other test relied on 30 s or on soldier immunity, update it, keeping its intent, and report it.

- [ ] **Step 5: Gates.** Digest unchanged; FLOW `failures=0`; report crowd_check.

- [ ] **Step 6: Commit.**

```bash
git add src/game/crowd/plague_manager.gd src/game/crowd/person.gd src/fx/curse/pestilence.gd src/game/power_book.gd tools/dev/behaviour_check.gd tests/test_plague.gd
git commit -m "feat: Pestilence kills in 5 s, spreads each second, and soldiers catch it (v0.07.1)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Task 2: Plague looks — tint stages, ground ring, spread puffs

**Files:**
- Modify: `src/game/crowd/person.gd`, `src/game/crowd/plague_manager.gd`, `src/game/crowd/crowd.gd`, `tests/run_all.gd`
- Create: `tests/test_plague_look.gd`

**Interfaces:**
- Consumes: Task 1 (soldiers can be sick).
- Produces:
  - `Person.sick_total: float`, `Person.sick_stage() -> int` (0, or 1..`SICK_STAGES`), `Person.sick_color() -> Color`;
  - `Person.SICK_RED`, `SICK_SKIN`, `SICK_CLOTH`, `SICK_STAGES`;
  - `PlagueManager.draw_ground(ci: CanvasItem)`, `PlagueManager.PUFF_MAX`, `PlagueManager._puffs`;
  - `Crowd.overlay() -> Node2D`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_plague_look.gd`:

```gdscript
extends RefCounted
## v0.07.1 Pestilence looks: the sick go through SICK_STAGES steps from green to red as death nears, and their sprite
## redraws at each; while anyone is sick the crowd's drawers show (the rings under them); each infection passed on
## raises a green puff, never more than PUFF_MAX at once.


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
	var plague := crowd.plague
	var i := 0
	for p in crowd.citizens + crowd.soldiers:
		p.ground_pos = Vector2(-27.0 + float(i % 20) * 0.9, -27.0 + float(i / 20) * 0.9)
		i += 1

	# Stages, green to red.
	var p: Person = crowd.citizens[0]
	t.check(p.sick_stage() == 0, "the healthy are at stage 0")
	p.infect(PlagueManager.PLAGUE_LIFE)
	var sig_first := p._art_signature()
	t.check(p.sick_stage() == 1 and p.sick_color() == Person.SICK_TINT, "just caught: stage 1, green")
	p.sick_left = PlagueManager.PLAGUE_LIFE * 0.5
	t.check(p.sick_stage() == 3 and p._art_signature() != sig_first, "half way: stage 3, and the sprite redraws")
	p.sick_left = 0.1
	t.check(p.sick_stage() == Person.SICK_STAGES and p.sick_color() == Person.SICK_RED, "about to die: the last stage, red")
	var s: Person = crowd.soldiers[0]
	s.infect(PlagueManager.PLAGUE_LIFE)
	t.check(s.sick_stage() == 1, "a sick soldier shows it too")

	# While anyone is sick, the drawers show (the rings).
	var drawer := crowd._ground_drawer as Crowd.ResponseDrawer
	plague.step(0.01)
	t.check(drawer.showing(), "the rings show while anyone is sick")
	for q in crowd.citizens + crowd.soldiers:
		q.sick_left = 0.0
	plague.step(0.01)
	t.check(not drawer.showing(), "and stop when nobody is")

	# Each infection passed on raises a puff, PUFF_MAX at most.
	var at := Vector2(0.8, 2.0)
	var packed: Array[Person] = []
	for k in 60:
		var q: Person = crowd.citizens[20 + k]
		q.ground_pos = at + Vector2(0.08 * float(k % 8), 0.08 * float(k / 8))
		packed.append(q)
	for k in 10:
		packed[k].infect(PlagueManager.PLAGUE_LIFE)
	plague._collect(true)
	var before := plague._puffs.size()
	plague._spread()
	var caught := 0
	for q in packed.slice(10):
		if q.sick_left > 0.0:
			caught += 1
	t.check(caught > 0 and plague._puffs.size() - before == mini(caught, PlagueManager.PUFF_MAX - before),
		"a puff for each one who caught it (%d caught, %d puffs)" % [caught, plague._puffs.size() - before])
	for k in 5:
		plague._spread()
	t.check(plague._puffs.size() <= PlagueManager.PUFF_MAX, "never more than %d puffs" % PlagueManager.PUFF_MAX)
	crowd.clear()
	world.free()
```

Register `"res://tests/test_plague_look.gd",` after `"res://tests/test_rescue.gd",` in `tests/run_all.gd`, then run the import.

- [ ] **Step 2: Run the tests.** Expected: parse errors, because `sick_stage`, `PUFF_MAX` and the others are not defined yet.

- [ ] **Step 3: Implement.**

**`src/game/crowd/person.gd`**

(a) After `const SICK_MOTE`, add:

```gdscript
## Pestilence (v0.07.1): the sick turn from SICK_TINT to this red as death nears, in SICK_STAGES steps, and the
## sickness colours the skin and the clothes this strongly.
const SICK_RED := Color("b03a2e")
const SICK_STAGES := 5
const SICK_SKIN := 0.6
const SICK_CLOTH := 0.55
```

(b) After `var sick_left := 0.0`, add:

```gdscript
## Pestilence (v0.07.1): the seconds the sickness ran in all, from infect(), to tell how far along it is.
var sick_total := 0.0
```

(c) In `infect()`, set `sick_total = seconds` next to `sick_left = seconds`.

(d) Add after `infect()`:

```gdscript
## Pestilence (v0.07.1): 0 when healthy, else 1..SICK_STAGES by how much of the sickness has run.
func sick_stage() -> int:
	if sick_left <= 0.0 or state == State.DEAD:
		return 0
	var run := 1.0 - sick_left / maxf(sick_total, 0.001)
	return clampi(1 + int(run * float(SICK_STAGES)), 1, SICK_STAGES)


## Pestilence (v0.07.1): the sickness's colour now, green when caught to red near death.
func sick_color() -> Color:
	return SICK_TINT.lerp(SICK_RED, float(maxi(sick_stage() - 1, 0)) / float(SICK_STAGES - 1))
```

(e) **`_draw_citizen`.**
- Replace

```gdscript
	var sick := sick_left > 0.0 and state != State.DEAD
	var skin := _skin.lerp(SICK_TINT, 0.5) if sick else _skin
```

with

```gdscript
	var sick := sick_left > 0.0 and state != State.DEAD
	var tint := sick_color() if sick else Color.WHITE
	var skin := _skin.lerp(tint, SICK_SKIN) if sick else _skin
	var legs := CIT_LEGS.lerp(tint, SICK_CLOTH) if sick else CIT_LEGS
```

- The robe line becomes `var robe := CLERGY_ROBE.lerp(tint, SICK_CLOTH) if sick else CLERGY_ROBE`.
- `coat = coat.lerp(SICK_TINT, 0.3)` becomes `coat = coat.lerp(tint, SICK_CLOTH)`.
- The two leg `_px` calls use `legs` instead of `CIT_LEGS`.
- The cough mote's colour becomes `tint.lightened(0.35)`.

(f) **`_draw_soldier`.** After `var f := _facing`, add:

```gdscript
	# The plague (v0.07.1) colours a soldier too.
	var sick := sick_left > 0.0 and state != State.DEAD
	var tint := sick_color() if sick else Color.WHITE
	var mail := SOL_MAIL.lerp(tint, SICK_CLOTH) if sick else SOL_MAIL
	var skin := _skin.lerp(tint, SICK_SKIN) if sick else _skin
```

- Use `mail` for the `_px(-4, -11 + lift, 8, 6, SOL_MAIL)` body.
- Use `skin` for the two arm pixels that use `_skin`.
- Blend the tabard: right after the `var tabard := ...` line, add `if sick: tabard = tabard.lerp(tint, SICK_CLOTH)`.
- At the end of `_draw_soldier`, add:

```gdscript
	if sick:
		# A cough from under the helm.
		_px(2 if f > 0 else -3, -16 - int(_anim * 2.0) % 4 + lift, 1, 1, tint.lightened(0.35))
```

(g) **`_art_signature()`.** Replace `(walk + (4 if sick_left > 0.0 else 0)) * SIG_WALK` with `(walk + 4 * sick_stage()) * SIG_WALK`. Change the comment above it to: "Sickness (v0.06) above the walk frames, by stage (v0.07.1), so the sprite redraws as it turns from green to red."

**`src/game/crowd/plague_manager.gd`**

(h) Add constants:

```gdscript
## The sick's rings (v0.07.1): an ellipse this many ground units round under each, of so many segments, pulsing so
## many times a second.
const RING_R := 0.32
const RING_SEGMENTS := 10
const RING_PULSE_HZ := 3.0
## Spread puffs (v0.07.1): this many particles each, and at most PUFF_MAX alive at once.
const PUFF_PARTICLES := 6
const PUFF_MAX := 40
```

and vars:

```gdscript
var _puffs: Array = []
## The puffs' own randomness, so drawing them never changes who catches it.
var _fx_rng := RandomNumberGenerator.new()
```

(i) In `setup()`, add `_fx_rng.seed = seed_value + 1`.

(j) In `_spread()`, change the final loop to:

```gdscript
	for q in fresh:
		q.infect(PLAGUE_LIFE)
		sick.append(q)
		_puff(q)
```

(k) Add:

```gdscript
## A green smoke puff where the plague was just passed on (v0.07.1), in the cast's colours, on the crowd's overlay.
func _puff(p: Person) -> void:
	_puffs = _puffs.filter(func(x) -> bool: return is_instance_valid(x))
	var layer := _crowd.overlay()
	if _puffs.size() >= PUFF_MAX or layer == null or p.inside:
		return
	var puff := PixelParticles.new()
	puff.rng.seed = _fx_rng.randi()
	puff.shape = PixelParticles.Shape.PUFF
	puff.ramp = PackedColorArray(PestilenceFx.MIASMA)
	puff.position = Iso.ground_to_screen(p.ground_pos)
	puff.drag = 1.4
	puff.gravity = -14.0
	layer.add_child(puff)
	puff.burst(PUFF_PARTICLES, {"radius": 4.0, "speed": Vector2(4, 12), "alt": Vector2(2, 10),
		"alt_speed": Vector2(2, 8), "life": Vector2(0.5, 0.9), "size": Vector2(2, 3), "size_end_mul": 1.8})
	_puffs.append(puff)


## The sick's rings (v0.07.1): a pulsing ellipse under each sick person out in the open, in its sickness's colour, all
## in one draw call. Into `ci` (the crowd's ground drawer, under the people), world space.
func draw_ground(ci: CanvasItem) -> void:
	if sick.is_empty():
		return
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var pulse := 0.55 + 0.45 * sin(float(Time.get_ticks_msec()) * 0.001 * TAU * RING_PULSE_HZ)
	for p in sick:
		if not is_instance_valid(p) or p.inside or not p.visible:
			continue
		var c := p.sick_color()
		c.a = pulse
		var prev := Iso.ground_to_screen(p.ground_pos + Vector2(RING_R, 0.0))
		for k in range(1, RING_SEGMENTS + 1):
			var a := TAU * float(k) / float(RING_SEGMENTS)
			var nxt := Iso.ground_to_screen(p.ground_pos + Vector2(cos(a), sin(a)) * RING_R)
			pts.append(prev)
			pts.append(nxt)
			cols.append(c)
			prev = nxt
	if not pts.is_empty():
		ci.draw_multiline_colors(pts, cols, -1.0)
```

(l) In `clear()`, add `_puffs.clear()`.

(m) Add to the class doc comment: "Looks (v0.07.1): the sick are tinted by stage (Person.sick_color()), a ring pulses under each (draw_ground()), and each infection passed on raises a green puff."

**`src/game/crowd/crowd.gd`**

(n) Next to `_response_drawer()`, add:

```gdscript
## The drawer over the people (z 60), where short-lived effects such as the plague's puffs go; null before spawn().
func overlay() -> Node2D:
	return _drawer if is_instance_valid(_drawer) else null
```

(o) In `ResponseDrawer._draw()`, after the rescue line, add:

```gdscript
		if crowd.plague != null and ground:
			crowd.plague.draw_ground(self)
```

(p) In `ResponseDrawer.showing()`, add `or (crowd.plague != null and not crowd.plague.sick.is_empty())` to the condition.

- [ ] **Step 4: Run the full suite.** Expected: `failures=0`.

- [ ] **Step 5: Look at it.** Record a still of sick people in a crowd.
  - Use the clip tool: `$G --path . --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=clip --power=pestilence --snap` (read the `clip` scenario in `tools/dev/behaviour_check.gd` for its flags and where it writes).
  - Or use any existing capture path that shows the market with sick people.
  - Report the PNG path. PNGs go under `captures/` and are never committed.
  - Describe whether the tint, the ring and the puffs read clearly.

- [ ] **Step 6: Gates.** Digest unchanged; FLOW `failures=0`; report crowd_check.

- [ ] **Step 7: Commit.**

```bash
git add src/game/crowd/person.gd src/game/crowd/plague_manager.gd src/game/crowd/crowd.gd tests/test_plague_look.gd tests/test_plague_look.gd.uid tests/run_all.gd
git commit -m "feat: the sick turn green to red, with a ring and a puff as it spreads (v0.07.1)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Task 3: Silent Doom — 2.5 s cooldown, everyone within reach

**Files:**
- Modify: `src/fx/quiet/silent_doom.gd`, `src/game/power_book.gd`, `tests/test_quiet.gd`

**Interfaces:**
- Produces: `SilentDoom.victims_at(field, at) -> Array[DummyEnemy]` returns every living person within `RADIUS`, nearest first. `SilentDoom.VICTIMS` is removed.

- [ ] **Step 1: Update tests/test_quiet.gd (failing first).** Replace the block from `# Who Silent Doom takes: the nearest, three at most, within reach.` through its `t.check(...)` with:

```gdscript
	# Who Silent Doom takes: everyone within reach, soldiers too (v0.07.1), and nobody beyond.
	var at := Vector2(-4.0, 10.0)
	var four: Array[Person] = []
	for k in 4:
		var p: Person = crowd.citizens[k]
		p.ground_pos = at + Vector2(0.15 * k, 0.0)
		four.append(p)
	var far: Person = crowd.citizens[4]
	far.ground_pos = at + Vector2(1.5, 0.0)
	var soldier: Person = crowd.soldiers[0]
	soldier.ground_pos = at + Vector2(0.0, 0.6)
	var taken := SilentDoom.victims_at(field, at)
	t.check(taken.size() == 5 and four.all(func(p: Person) -> bool: return p in taken) and soldier in taken
		and far not in taken, "Silent Doom takes everyone within reach, soldiers too, and nobody beyond")
	t.check(is_equal_approx(float(PowerBook.get_power("doom").cooldown), 2.5), "Silent Doom is ready again 2.5 s after a cast")
	taken.erase(soldier)
	soldier.ground_pos = Vector2(-27.0, 22.0)
```

In the "Unseen" block, delete the line `four[3].ground_pos = Vector2(-27.0, 20.0)`. Change:
- the comment to `# Unseen: four fall together (none witnesses another) and the town never knows.`;
- `crowd.killed_citizens == killed + 3` to `crowd.killed_citizens == killed + taken.size()`;
- the message to `"unseen, all four die and the town never knows"`.

Read the surrounding lines first. `_clear_round` puts everyone far off; keep the soldier and `far` out of sight of `at`.

- [ ] **Step 2: Run the tests.** Expected: FAIL. `SilentDoom.VICTIMS` still caps at 3, and the cooldown is 15.

- [ ] **Step 3: Implement.**

`src/fx/quiet/silent_doom.gd`:
- Remove `const VICTIMS := 3`.
- `victims_at()` returns all of `near`, sorted, without `.slice(0, VICTIMS)`. Its doc comment becomes "Who the doom would take at `at`: every living person within RADIUS (v0.07.1: no cap), nearest first."
- Class doc comment: "A dark wisp gathers over up to VICTIMS people within RADIUS of the aim, nearest first," becomes "A dark wisp gathers over everyone within RADIUS of the aim (v0.07.1; before, the nearest three),".

`src/game/power_book.gd` doom entry:
- `"cooldown": 15.0` becomes `"cooldown": 2.5`;
- `"shape": "up to 3 struck down, unseen"` becomes `"shape": "everyone within reach struck down, unseen"`.

Search for other uses of `SilentDoom.VICTIMS` (`grep -rn "VICTIMS" src tests tools`) and update them. Known: `src/game/targeting.gd` uses only `victims_at()`.

- [ ] **Step 4: Run the full suite.** Expected: `failures=0`. If `test_power_book.gd`, `test_rules.gd` or `test_hud.gd` relied on Doom's 15 s cooldown, update them, keeping their intent, and report it.

- [ ] **Step 5: Gates.** Digest unchanged; FLOW `failures=0`; report crowd_check.

- [ ] **Step 6: Commit.**

```bash
git add src/fx/quiet/silent_doom.gd src/game/power_book.gd tests/test_quiet.gd
git commit -m "feat: Silent Doom takes everyone within reach, every 2.5 s (v0.07.1)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Task 4: Measurements, summary, tag (controller)

- Run the `powers` scenario's `plague` and `combo` cases: `--scenario=powers --case=plague` and `--case=combo`. Record the sick and dead counts over time.
- Run a mission bench, alternating with `kak-v0.07`, plus one look at the frame time with the plague running in view.
- Update `docs/KAK_Version_0.07_Summary.md`:
  - the §5 rows for Silent Doom and Pestilence;
  - a short "v0.07.1" note in §11 with the new numbers.
- Add "Changes made while executing" to the spec.
- Tag `kak-v0.07.1` and push.
