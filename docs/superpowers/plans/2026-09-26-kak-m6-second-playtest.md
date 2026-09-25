# KAK Milestone 6 — The Second Playtest — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Act on the user's second playtest: crowds that visibly pile up at the gates, the sound of a panicking town, a three-second ending before the results, a Heaven Splitter preview centred where the line really falls, the powers' names on the HUD, and background music.

**Architecture:** No new systems except music. The gate queue in `Crowd` gives each waiting person a spot in a crowd fanned out in front of the gate, instead of freezing them where they stand; `Targeting` learns that one lane power is centred on the cast; the HUD's slots become small cards; `Crowd` drives a looping crowd-panic bed; and a `Music` player — built like `UiSound`, non-positional and alive across every screen — plays a synthesized theme on the title and draft and a layered battle loop in the mission that thickens as the city falls.

**Tech Stack:** Godot 4.7.2, GDScript, `gl_compatibility`, 640×360; Python 3 with numpy/scipy (`tools/audio/synth.py`) and PIL.

## The playtest notes this plan answers

The user's words, their numbering:

1. "Regeneration alone can be enough if you pick and use ability suitable." → no change.
2. "Not pile up at gate" → **Task 2.** Units never collide, so everyone waiting at a gate stood on the same few pixels; a crowd of thirty looked like three.
3. "That's still Ok" (the 38 escape limit) → no change.
4. "Can we add crowded sound effect while citizens are panic and escape?" → **Task 4.**
5. "Can we add delay before display result for 3 seconds?" → **Task 1.**
6. "Can you correct preview radius of Heaven Splitter on ability focus? Make it center at the cursor" → **Task 1.** The effect's line runs `LINE_LENGTH / 2` each way from the cast point (`heaven_splitter.gd` line 57, and its strike spreads both ways); the preview drew it from the cursor forward. The Tsunami and the Laser Grid really do start at the cursor — theirs are right.
7. "Can we add Ability name label along with ability icon?" → **Task 3.** The user chose wider slots: icon on the left, name and cost on the right, always visible.
8. "Help me adding BGM" → **Tasks 5 and 6.** The user chose music synthesized in the project like every other sound: a brooding theme for the title and draft, a driving battle loop for the mission that gains layers as the city's stability falls.

## Global Constraints

- Engine: `F:\Godot\Godot_v4.7.2-stable_win64_console.exe` (Git Bash: `/f/Godot/Godot_v4.7.2-stable_win64_console.exe`), renderer `gl_compatibility`.
- Viewport 640×360, nearest filtering, `2d/snap/snap_2d_vertices_to_pixel=true`: pixel lines are hairlines (`width = -1.0`).
- **No text smaller than `UiTheme.SIZE_SMALL` (11 px)**; stack lines with `UiTheme.LINE_SMALL` / `LINE_BODY`. Measure widths with `UiTheme.width()` rather than guessing (a guessed column ran "TARGET" into its value). Dark text on a gold fill picks up every label's one-pixel shadow and blurs; use gold on dark.
- **A texture is loaded before it is drawn, never inside `_draw()`.**
- The 11 effects and the effect toolkit (`src/fx/`) do not change — including Tornado Tempest's wander (the user's deferred note from the last playtest).
- Behaviour gate: `/f/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tools/dev/state_digest.gd` must keep printing `rows=19`, `digest=61267b7e90524d800bf1c3473a71146b`, `blocked=000000111000000000000011000000000000000000001110000000000000`, `emitters=45`. Never edit that tool or those values.
- Tests: `bash tools/test.sh` must end `checks=<N> failures=0`; the **628 checks** standing today keep passing. A suite that builds nodes frees them — no leaked-object lines. The sound-catalog suite grows by one check per new catalog entry on its own; count that in.
- Audio: every sound and every bar of music is made by `tools/audio/synth.py` — never recorded or downloaded. `python tools/audio/synth.py --verify` must end `0 problems`; loops must pass its seam check. If a cue fails, fix the builder, never `verify()`.
- Anything that plays audio returns at once in a headless run (as `UiSound.play` does): a player made during the headless suite outlives it and leaks.
- The screen flow still works: `/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/game.tscn --audio-driver Dummy -- --flow-test` ends `FLOW result checks=<N> failures=0`, with no errors or leak lines at quit.
- The scripted runs keep their names and output shape. `--mission-test` now runs at a fixed 60 fps and prints the same line every run (`MISSION test dp=21.5 buildings=58 citizens=47 escaped=20 ...` today) — use it to compare before and after.
- GDScript style: tabs, typed vars; explicit types for values from untyped Arrays/Dictionaries; `##` doc comments like the surrounding code. Local names must not shadow built-ins or Node members.
- Commit after each task; every message ends with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Commit new scripts with their `.gd.uid` files and new assets with their `.import` files.
- Leave the untracked `.codex/` folder and `docs/HUM_Game_Design_Document_v1.docx` alone. Do not commit anything under `captures/`.
- **User checkpoints:** after Task 2 (the gate crowds, on close-up captures) and after Task 6 (the music and the crowd bed — the user listens), the controller shows the result and waits for approval.

---

## File Structure

| File | Change |
|---|---|
| `src/game/targeting.gd` | a centred lane for Heaven Splitter, in the preview and the crowd's fright (Task 1) |
| `src/game/mission.gd` | the ending lasts 3 s (Task 1); feeds the music its intensity (Task 6) |
| `src/game/crowd/crowd.gd` | gate queues as spread-out crowds (Task 2); the crowd-panic bed (Task 4) |
| `src/game/crowd/person.gd` | `queue_spot`, released by the gate (Task 2) |
| `src/game/town_debug.gd` | the crowd test logs queues by spot and photographs each gate close up (Task 2) |
| `src/game/ui/hud.gd` | slot cards with names (Task 3) |
| `tools/audio/synth.py`, `src/audio/sfx.gd` | `crowd_panic` loop (Task 4); music loops (Task 5) |
| `src/audio/music.gd` (new) | the music player (Task 6) |
| `src/game/game.gd` | which music plays on which screen (Task 6) |
| tests | as each task says |

Task order: 1, 2, 3, 4, 5, 6. Each ends with a green suite and a commit. Counts are given as "+N"; report the actual total.

---

### Task 1: Heaven Splitter centred, and a three-second ending

**Files:**
- Modify: `src/game/targeting.gd`
- Modify: `src/game/mission.gd`
- Modify: `tests/test_targeting.gd`

**Why:** notes 6 and 5. The Heaven Splitter's line is centred on the cast — `Set2Parts.lane(self, origin - _dir * LINE_LENGTH * 0.5, ...)` and a strike that spreads both ways — so its preview has to be centred too, and so does the crowd's fright along it. And the ending before the results grows from 1.6 s to the 3 s the user asked for.

**Interfaces:**
- Produces: `Targeting.AREAS["heaven"].centred == true`; `Targeting.lane_start(key: String, press: Vector2, dir: Vector2) -> Vector2`; `Mission.ENDING_SECONDS == 3.0`.

- [ ] **Step 1: Write the failing test**

In `tests/test_targeting.gd`, after the `missing` check (`t.check(missing == "", "every power has an area to show ...`), add:

```gdscript
	# The Heaven Splitter's line is centred on the cast (heaven_splitter.gd lays its lane from
	# origin - dir * LINE_LENGTH / 2); the Tsunami and the Laser Grid start at it.
	t.check(bool(Targeting.AREAS["heaven"].get("centred", false)), "the Heaven Splitter's lane is centred on the cast")
	t.check(not bool(Targeting.AREAS["tsunami"].get("centred", false)) and not bool(Targeting.AREAS["laser"].get("centred", false)),
		"the Tsunami's and the Laser Grid's start at it")
	var mid := Targeting.lane_start("heaven", Vector2(2.0, 2.0), Vector2(1.0, 0.0))
	t.check(mid.is_equal_approx(Vector2(-3.0, 2.0)), "so a Heaven Splitter at (2, 2) pointing east starts 5 units west (%s)" % mid)
	t.check(Targeting.lane_start("tsunami", Vector2(2.0, 2.0), Vector2(1.0, 0.0)) == Vector2(2.0, 2.0), "and a Tsunami starts where it is cast")
```

Run `bash tools/test.sh` — expected: `test_targeting.gd` fails to load (`lane_start` does not exist).

- [ ] **Step 2: Centre it**

In `src/game/targeting.gd`, change the `"heaven"` entry of `AREAS` and its comment:

```gdscript
	# LINE_LENGTH, LINE_HALF_WIDTH, FISSURE_LENGTH; centred: the line runs half its length each way from the cast
	"heaven": {"shape": "lane", "length": 10.0, "half": 0.7, "fissure": 5.6, "centred": true},
```

add:

```gdscript
## Where a lane power's lane begins: at the cast for a power that sweeps forward from it, half a length back for
## one centred on it.
static func lane_start(key: String, press: Vector2, dir: Vector2) -> Vector2:
	var a: Dictionary = AREAS.get(key, {})
	if bool(a.get("centred", false)):
		return press - dir * float(a.get("length", 0.0)) * 0.5
	return press
```

In `_draw()`'s `"lane"` branch, draw the lane from its start:

```gdscript
		"lane":
			var dir := aim_dir()
			_lane(lane_start(_rules.key(slot), _press, dir), dir, float(a.length), float(a.half), edge)
```

(the fissure spokes stay centred on `_press`, which is right — they radiate from the strike point).

In `_on_cast_made()`, frighten along the real lane:

```gdscript
	if String(a.get("shape", "")) == "lane":
		var dir := aim_dir()
		_crowd.on_cast(lane_start(key, at, dir), dir, float(a.length))
```

- [ ] **Step 3: Three seconds before the results**

In `src/game/mission.gd`, change `const ENDING_SECONDS := 1.6` to:

```gdscript
const ENDING_SECONDS := 3.0
```

and update its comment: the user asked for three seconds between the mission's end and the results. The slow motion runs for the whole of it.

- [ ] **Step 4: Run and look**

```bash
bash tools/test.sh
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/game.tscn --audio-driver Dummy -- --flow-test 2>&1 | grep -E "FLOW result|FLOW FAIL|ERROR"
SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test 2>&1 | grep -E "MISSION test|ERROR|SCRIPT"
```

Expected: `checks=632 failures=0` (+4); `FLOW result checks=22 failures=0` (its ending step waits up to 5 s, enough for 3); one `MISSION test` line — the scripted run casts a Heaven Splitter at t=1, so its numbers may move slightly now that the fright is centred; report it.

Then photograph the preview: the scripted mission's first cast is the Heaven Splitter, aimed with `_aim.pick(0)` and `_aim.hover(...)` before it goes out, so `captures/mission_0050.png` shows the Nova's ring (the opening aim) — add nothing to the run; instead crop `captures/mission_0200.png` around the first cast point and check the heaven strike itself sits in the middle of where the lane was. If you cannot tell from a capture, say so.

- [ ] **Step 5: Commit**

```bash
git add src/game/targeting.gd src/game/mission.gd tests/test_targeting.gd
git commit -m "fix: the Heaven Splitter's preview is centred, and the ending lasts three seconds" -m "The Heaven Splitter's line runs half its length each way from the cast, but its preview and the crowd's fright along it started at the cursor and ran forward, so both sat half a line off. They are centred now; the Tsunami and the Laser Grid, which do start at the cursor, are unchanged. The slow-motion ending before the results lasts three seconds, as the user asked." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Crowds that pile up at the gates

**Files:**
- Modify: `src/game/crowd/person.gd` (`queue_spot`, `release_from_queue()`)
- Modify: `src/game/crowd/crowd.gd` (queue spots and the new `_gates()`)
- Modify: `src/game/town_debug.gd` (the crowd test's queue log and gate close-ups)
- Modify: `tests/test_crowd.gd`

**Why:** note 2 — "Not pile up at gate." The gate *was* holding people, but a held person froze wherever it stood, and units never collide: everyone arriving along the same street froze on the same few pixels. Now each gate has a set of **queue spots** — rows fanned out in front of its doorway on the town side, nearest first — and every waiting person walks to its own spot and stands. As the gate lets the front person through, everyone shuffles one spot closer. The gate's rate (one every 2 s) and the escape limit do not change.

**Interfaces:**
- Produces: `Person.queue_spot: Vector2` (`Vector2.INF` when not waiting), `Person.release_from_queue() -> void`; `Crowd.QUEUE_REACH`, `Crowd.QUEUE_SPACING`, `Crowd.queue_spots(gate: Structure) -> Array[Vector2]`, `Crowd.waiting_at(gate: Structure) -> int`. `Person.wait` is no longer set by the gates.

- [ ] **Step 1: Write the failing test**

In `tests/test_crowd.gd`, replace the whole first gate block — from `# A gate passes one person at a time and holds the rest;` down to and including the four lines that send `queue` far away and erase the gate's pass (`crowd._gate_next.erase(gate)` and `crowd._gate_passing.erase(gate)`) — with:

```gdscript
	# A gate's waiting crowd: everyone waiting gets a spot of their own in front of the doorway, spread out
	# rather than stacked, and one person at a time is let through.
	var gate: Structure = town.gates[0]
	var spots := crowd.queue_spots(gate)
	t.check(spots.size() >= 20, "a gate has room for a crowd in front of it (%d spots)" % spots.size())
	var tightest := INF
	for i in spots.size():
		for j in range(i + 1, spots.size()):
			tightest = minf(tightest, spots[i].distance_to(spots[j]))
	t.check(tightest >= Crowd.QUEUE_SPACING * 0.8, "and the spots are spread out (closest pair %.2f)" % tightest)
	var off_grid := 0
	for s in spots:
		if not grid.walkable(s):
			off_grid += 1
	t.check(off_grid == 0, "every spot is somewhere a person can stand (%d are not)" % off_grid)

	var queue: Array[Person] = []
	for i in 12:
		var p: Person = crowd.citizens[10 + i]
		p.ground_pos = gate.center() - gate.center().normalized() * 1.0 + Vector2(0.02 * i, 0.0)
		queue.append(p)
	# Everyone else waits at the market -- far enough that nobody else reaches this gate during the test, so the
	# crowd at it is exactly these twelve.
	for p in crowd.citizens:
		if is_instance_valid(p) and not queue.has(p):
			p.ground_pos = TownLayout.MARKET_SQUARE.get_center()
	crowd.advance(0.0)
	var released := 0
	var placed: Array[Vector2] = []
	for p in queue:
		if p.queue_spot == Vector2.INF:
			released += 1
		else:
			placed.append(p.queue_spot)
	t.check(released == 1, "one person is let through at a time (%d were)" % released)
	var doubled := 0
	for i in placed.size():
		for j in range(i + 1, placed.size()):
			if placed[i].is_equal_approx(placed[j]):
				doubled += 1
	t.check(placed.size() == 11 and doubled == 0, "the other eleven wait on eleven different spots (%d shared)" % doubled)
	t.check(crowd.waiting_at(gate) == 11, "and the gate counts them (%d)" % crowd.waiting_at(gate))

	# Walk them: after two intervals they have spread onto their spots and the queue has moved on by one.
	for i in int(Crowd.GATE_INTERVAL * 2.0 * 60.0) + 30:
		crowd.advance(1.0 / 60.0)
		for p in queue:
			if is_instance_valid(p):
				p.tick(1.0 / 60.0)
	var stacked := 0
	for i in queue.size():
		for j in range(i + 1, queue.size()):
			if is_instance_valid(queue[i]) and is_instance_valid(queue[j]) \
					and queue[i].queue_spot != Vector2.INF and queue[j].queue_spot != Vector2.INF \
					and queue[i].ground_pos.distance_to(queue[j].ground_pos) < Crowd.QUEUE_SPACING * 0.5:
				stacked += 1
	t.check(stacked == 0, "waiting people stand apart instead of on top of each other (%d pairs stacked)" % stacked)
	t.check(crowd.waiting_at(gate) <= 10, "and the gate has let more through (%d still waiting)" % crowd.waiting_at(gate))

	# This synthetic crowd is done with the gate: send it away and forget the gate's pass, so the throughput test
	# below starts with an idle gate.
	for p in queue:
		if is_instance_valid(p):
			p.release_from_queue()
			p.ground_pos = gate.center() - gate.center().normalized() * (Crowd.QUEUE_REACH + 3.0)
	crowd._gate_next.erase(gate)
	crowd._gate_passing.erase(gate)
	crowd.advance(0.0)
```

In the throughput test further down, the walkers move only while released: replace `if w.wait <= 0.0:` with `if w.queue_spot == Vector2.INF:`.

Run `bash tools/test.sh` — expected: `test_crowd.gd` fails to load (`queue_spots` does not exist).

- [ ] **Step 2: A person can wait on a spot**

In `src/game/crowd/person.gd`, add the state:

```gdscript
## This person's spot in a gate's waiting crowd, or Vector2.INF. While set, it walks there and stands; the gate
## clears it (release_from_queue) when it lets the person through or the person leaves the crowd.
var queue_spot := Vector2.INF
```

and:

```gdscript
## Let a waiting person go: leave its spot and pick its route up again from where it stands (the waypoint it
## was heading for when it joined the crowd may now be behind it).
func release_from_queue() -> void:
	if queue_spot == Vector2.INF:
		return
	queue_spot = Vector2.INF
	if _goal != Vector2.INF:
		set_goal(_goal)
```

In `_think()`, directly after the stumble block (before `walk_speed = _mind_speed()`):

```gdscript
	if queue_spot != Vector2.INF:
		# Waiting at a gate: shuffle to this spot in the crowd and stand. The fright keeps ticking.
		_panic_left = maxf(_panic_left - delta, 0.0)
		walk_speed = WALK_SPEED * pace
		if ground_pos.distance_to(queue_spot) > 0.06:
			_target = queue_spot
			_idle = 0.0
		else:
			_idle = maxf(_idle, 0.1)
		return
```

and at the very top of `_pick_target()`:

```gdscript
	if queue_spot != Vector2.INF:
		_target = queue_spot
		return
```

- [ ] **Step 3: Gates with room for a crowd**

In `src/game/crowd/crowd.gd`, add the constants:

```gdscript
## A gate's waiting crowd: how far in front of the doorway it may reach, and how far apart two waiting people
## stand. People never collide, so without spots of their own a crowd of thirty stood on three pixels.
const QUEUE_REACH := 3.2
const QUEUE_SPACING := 0.34
```

the state:

```gdscript
## Gate -> its queue spots, nearest the doorway first. Built when the town is first asked about, per gate.
var _spots := {}
```

the spots:

```gdscript
## Rows fanned out in front of a gate's doorway on the town side, nearest the doorway first, walkable only. The
## crowd widens as it backs into the town, the way a real one does.
func queue_spots(gate: Structure) -> Array[Vector2]:
	if _spots.has(gate):
		return _spots[gate]
	var out_dir := gate.center().normalized()
	var side := Vector2(-out_dir.y, out_dir.x)
	var face := gate.center() - out_dir * (absf(gate.footprint.size.dot(out_dir)) * 0.5 + GATE_DOOR)
	var spots: Array[Vector2] = []
	var row := 0
	var depth := 0.0
	while depth <= QUEUE_REACH:
		var half := 1.2 + depth * 0.6
		var count := int(half * 2.0 / QUEUE_SPACING) + 1
		var stagger := QUEUE_SPACING * 0.5 if row % 2 == 1 else 0.0
		for i in count:
			var spot := face - out_dir * depth + side * (-half + stagger + QUEUE_SPACING * float(i))
			if _grid == null or _grid.walkable(spot):
				spots.append(spot)
		row += 1
		depth += QUEUE_SPACING * 0.87
	spots.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.distance_squared_to(face) < b.distance_squared_to(face))
	_spots[gate] = spots
	return spots


## How many people are waiting at a gate right now.
func waiting_at(gate: Structure) -> int:
	var n := 0
	var spots := queue_spots(gate)
	for p in citizens:
		if is_instance_valid(p) and p.queue_spot != Vector2.INF and spots.has(p.queue_spot):
			n += 1
	return n
```

Replace `_gates()` with the version below. What it keeps: rubble is no bottleneck; the pass holds while the passer is still in the doorway and its turn lasts; anyone already further out than the gate is through it. What changes: the waiting crowd is everyone fleeing within `QUEUE_REACH` in front of the doorway, and instead of `wait` each one gets `queue_spot`, nearest person to nearest spot.

```gdscript
func _gates() -> void:
	for gate in _town.gates:
		if not is_instance_valid(gate) or gate.destroyed:
			_gate_passing.erase(gate)
			_release_all(gate)
			continue  # rubble is no bottleneck
		var centre := gate.center()
		var outward := centre.normalized()
		var spots := queue_spots(gate)
		var face := centre - outward * (absf(gate.footprint.size.dot(outward)) * 0.5 + GATE_DOOR)
		# The passer keeps its pass while it is still in the doorway and its turn lasts.
		var passing: Person = _gate_passing.get(gate)
		if not (is_instance_valid(passing) and passing.is_alive() and passing.mind == Person.Mind.FLEE \
				and gate.footprint.grow(GATE_CLEAR).has_point(passing.ground_pos) \
				and _clock < float(_gate_next.get(gate, -1.0))):
			passing = null
			_gate_passing.erase(gate)
		# The waiting crowd: fleeing, in front of the doorway, not yet through it.
		var crowd_here: Array[Person] = []
		for p in citizens:
			if p == passing or not is_instance_valid(p) or not p.is_alive() or p.mind != Person.Mind.FLEE:
				continue
			var rel := p.ground_pos - centre
			var in_front := rel.dot(outward) <= 0.0 and p.ground_pos.distance_to(face) <= QUEUE_REACH + 0.5
			if in_front:
				crowd_here.append(p)
			elif spots.has(p.queue_spot):
				p.release_from_queue()  # it left this gate's crowd (thrown clear, or through)
		if crowd_here.is_empty():
			continue
		crowd_here.sort_custom(func(a: Person, b: Person) -> bool:
			return a.ground_pos.distance_squared_to(face) < b.ground_pos.distance_squared_to(face))
		var first := 0
		if passing == null and _clock >= float(_gate_next.get(gate, -1.0)):
			_gate_next[gate] = _clock + GATE_INTERVAL
			_gate_passing[gate] = crowd_here[0]
			crowd_here[0].release_from_queue()
			first = 1
		for i in range(first, crowd_here.size()):
			var slot := i - first
			crowd_here[i].queue_spot = spots[mini(slot, spots.size() - 1)]


## A gate that fell lets its whole crowd go.
func _release_all(gate: Structure) -> void:
	var spots: Array[Vector2] = _spots.get(gate, [])
	for p in citizens:
		if is_instance_valid(p) and spots.has(p.queue_spot):
			p.release_from_queue()
```

`clear()` must forget the spots: add `_spots.clear()` there (a rebuilt town has new gate nodes).

- [ ] **Step 4: The crowd test counts and photographs the crowds**

In `src/game/town_debug.gd`'s `_crowd_test()`, the per-second log counts the waiting by spot: replace `if p.wait > 0.0:` with `if p.queue_spot != Vector2.INF:`. And before the final `print("CROWD result ...")`, photograph each gate close up:

```gdscript
	# Close on each gate for its waiting crowd (milestone 6): these are the frames the user judges the queue by.
	for i in _town.gates.size():
		var g: Structure = _town.gates[i]
		_bf.camera.zoom = Vector2.ONE * 1.4
		_bf.camera.position = Iso.ground_to_screen(g.center() - g.center().normalized() * 1.5).round()
		await _bf.wait_frames(3)
		await _bf.save_capture("crowd_gate_%d.png" % i)
```

- [ ] **Step 5: Run and look**

```bash
bash tools/test.sh
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --crowd-test 2>&1 | grep -E "CROWD t=(10|20|30)|CROWD result|captured .*gate|ERROR"
SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test 2>&1 | grep -E "MISSION test|ERROR|SCRIPT"
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tools/dev/state_digest.gd
```

Expected: `checks=637 failures=0` (+5: eight new checks in place of the old block's three — report the actual number); the `CROWD t=` lines show `queued=` in the tens once people flee; one `CROWD result`; two `captured .../crowd_gate_0.png` / `crowd_gate_1.png`; one `MISSION test` line (report `escaped=` next to today's 20 — the gate's rate is unchanged, so it should be close); the digest unchanged.

**Look.** Read `captures/crowd_gate_0.png` and `crowd_gate_1.png` and describe them: a crowd of people spread out in front of each gate, fanning back into the street, rather than a few figures on top of each other. This is the user's checkpoint image — if there is no visible crowd, say so plainly and report the `queued=` numbers.

- [ ] **Step 6: Commit**

```bash
git add src/game/crowd/person.gd src/game/crowd/crowd.gd src/game/town_debug.gd tests/test_crowd.gd
git commit -m "feat: crowds that pile up at the gates" -m "A gate held its waiting people by freezing them where they stood, and people never collide, so a crowd of thirty stood on three pixels. Each gate now has spots fanned out in front of its doorway, widening back into the street; every waiting person walks to its own and stands, and the crowd shuffles forward as the gate lets its front person through. The gate's rate and the escape limit are unchanged. The crowd test photographs each gate close up." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

**User checkpoint:** the controller sends `captures/crowd_gate_0.png` and `crowd_gate_1.png` and waits for approval before Task 3.

---
### Task 3: The powers' names on the HUD

**Files:**
- Modify: `src/game/ui/hud.gd`
- Modify: `tests/test_hud.gd`

**Why:** note 7. The user chose wider slots: each becomes a small card, the 42-pixel icon on the left, the power's name (up to two lines) and its DP cost on the right, always visible. The row grows from 186 to 466 pixels, still centred under the DP bar. The hotkey keeps its plate on the icon's corner; the cooldown shade falls across the whole card, its seconds centred on the icon.

**Interfaces:**
- Produces: `Hud.SLOT_W := 112.0` (the card), `Hud.slot_name(i: int) -> String`. `slot_rect(i)` now returns the card, so `slot_at()` and the mouse follow it unchanged.

- [ ] **Step 1: Write the failing test**

In `tests/test_hud.gd`, after the two `slot_at` checks, add:

```gdscript
	# Each slot is a card with the power's name beside its icon (the user's second playtest).
	t.check(hud.slot_rect(0).size.x == Hud.SLOT_W and hud.slot_rect(0).size.y == Hud.SLOT_SIZE,
		"a slot is a %d x %d card (%s)" % [int(Hud.SLOT_W), int(Hud.SLOT_SIZE), hud.slot_rect(0).size])
	t.check(hud.slot_name(0) == "Heaven Splitter" and hud.slot_name(3) == "Nuclear Nova",
		"and carries its power's name (%s, %s)" % [hud.slot_name(0), hud.slot_name(3)])
```

Run `bash tools/test.sh` — expected: `test_hud.gd` fails to load (`SLOT_W` does not exist).

- [ ] **Step 2: Cards**

In `src/game/ui/hud.gd`, add next to `SLOT_SIZE`:

```gdscript
## A slot is a card: the SLOT_SIZE icon on the left, the power's name and cost on the right.
const SLOT_W := 112.0
```

In `slot_rect()`, lay the row out with `SLOT_W` instead of `SLOT_SIZE` for the width (both in `total` and in each card's position) and return `Rect2(..., Vector2(SLOT_W, SLOT_SIZE))`.

Add state and fill it in `setup()` next to `_slot_icons`:

```gdscript
## The powers' names, taken once with their icons.
var _slot_names: Array[String] = []
```

```gdscript
	_slot_names.clear()
	for i in _rules.loadout.size():
		_slot_names.append(String(_rules.power(i).get("name", "")))
```

```gdscript
func slot_name(i: int) -> String:
	return _slot_names[i] if i >= 0 and i < _slot_names.size() else ""
```

Replace the body of `_draw_slots()`'s loop with:

```gdscript
	for i in _rules.loadout.size():
		var box := slot_rect(i)
		var icon_box := Rect2(box.position, Vector2(SLOT_SIZE, SLOT_SIZE))
		var state := slot_state(i)
		var usable := state == "ready"
		draw_rect(box, UiTheme.COL_PANEL)
		if flashing(i):
			var red := UiTheme.COL_BAD
			red.a = _flash[i] / FLASH_SECONDS
			draw_rect(box, red)
		var icon: Texture2D = _slot_icons[i] if i < _slot_icons.size() else null
		if icon != null:
			draw_texture_rect(icon, icon_box, false, Color.WHITE if usable else Color(0.45, 0.45, 0.5))
		UiTheme.frame(self, box, is_picked(i))
		_plate(icon_box.position + Vector2(1.0, 1.0), "%d" % (i + 1), UiTheme.COL_TEXT)
		# The name beside the icon, up to two lines; gold when focused, dim when it cannot be cast.
		var tx := box.position.x + SLOT_SIZE + 4.0
		var name_col := UiTheme.COL_GOLD if is_picked(i) else (UiTheme.COL_TEXT if usable else UiTheme.COL_DIM)
		var lines := UiTheme.wrap(slot_name(i), SLOT_W - SLOT_SIZE - 8.0, UiTheme.SIZE_SMALL)
		for k in mini(lines.size(), 2):
			UiTheme.text(self, Vector2(tx, box.position.y + 12.0 + UiTheme.LINE_SMALL * float(k)), lines[k], UiTheme.SIZE_SMALL, name_col)
		var cost := "%d DP" % _rules.cost(i)
		UiTheme.text(self, Vector2(box.end.x - UiTheme.width(cost, UiTheme.SIZE_SMALL) - 4.0, box.end.y - 4.0), cost,
			UiTheme.SIZE_SMALL, UiTheme.COL_BAD if state == "dp" else UiTheme.COL_DIM)
		if state == "cooldown":
			# The cooldown as a shade falling away from the top of the card, its seconds over the icon.
			var left := _rules.cooldown_left(i)
			var frac := clampf(left / maxf(float(_rules.power(i).cooldown), 0.001), 0.0, 1.0)
			draw_rect(Rect2(box.position, Vector2(SLOT_W, SLOT_SIZE * frac)), Color(0, 0, 0, 0.6))
			var secs := "%d" % ceili(left)
			UiTheme.text(self, icon_box.get_center() + Vector2(-UiTheme.width(secs) * 0.5, 4.0), secs, UiTheme.SIZE_BODY)
```

(the cost plate on the icon's corner goes — the cost now sits in the card's bottom-right as text).

- [ ] **Step 3: Run and look**

```bash
bash tools/test.sh
SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test 2>&1 | grep -E "MISSION test|ERROR|SCRIPT"
```

Expected: `checks=639 failures=0` (+2). Crop and enlarge the bottom of `captures/mission_0050.png` and `mission_1600.png` (PIL): four cards in a row under the DP bar, each with its icon, the hotkey on the icon's corner, a name that fits in two lines (check "Cinderfall Barrage" and, if you can, the longest — "Judgement of the Ancients" — by running once with `-- --loadout=judgement,laser,orbital,glacial` on the mission scene), the cost bottom-right, the cooldown shade over the card with its seconds on the icon. Describe what you see; name anything that runs out of its card.

- [ ] **Step 4: Commit**

```bash
git add src/game/ui/hud.gd tests/test_hud.gd
git commit -m "feat: the powers' names on the HUD" -m "Each slot is now a small card -- the icon, and beside it the power's name on up to two lines and its DP cost -- always visible, as the user asked. The hotkey stays on the icon's corner and the cooldown shade falls across the whole card." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: The sound of a town running

**Files:**
- Modify: `tools/audio/synth.py` (`crowd_panic`, a loop)
- Modify: `src/audio/sfx.gd`
- Modify: `src/game/crowd/crowd.gd` (the bed)
- Modify: `src/game/mission.gd` (pause silences it)
- Modify: `tests/test_voices.gd`

**Why:** note 4 — "crowded sound effect while citizens are panic and escape." Under the capped individual yelps, a looping bed of a panicking crowd — a murmur shaped by vowel formants with dozens of voices crying out across the loop — whose level follows how many citizens are running: silent when nobody is, full at forty, easing up and down rather than jumping, and quiet when the mission is paused.

**Interfaces:**
- Produces: cue `crowd_panic` (loop); `Crowd.BED_FULL`, `static Crowd.bed_level_for(running: int) -> float`, `Crowd.pause_bed(paused: bool) -> void`.

- [ ] **Step 1: Write the failing test**

At the end of `tests/test_voices.gd`'s `run()` (before its cleanup lines):

```gdscript
	# The bed: silent with nobody running, full at BED_FULL, never louder.
	t.check(Crowd.bed_level_for(0) == 0.0, "nobody running, no crowd noise")
	t.near(Crowd.bed_level_for(int(Crowd.BED_FULL / 2.0)), 0.5, 0.001, "half the full crowd, half the level")
	t.check(Crowd.bed_level_for(500) == 1.0, "and a stampede is no louder than full")
	t.check(Sfx.CATALOG.has(&"crowd_panic") and bool(Sfx.CATALOG[&"crowd_panic"].get("loop", false))
		and ResourceLoader.exists("res://assets/audio/crowd/crowd_panic.wav"), "the crowd bed is a loop in the catalog and on disk")
```

Run `bash tools/test.sh` — expected: `test_voices.gd` fails to load.

- [ ] **Step 2: Synthesize it**

In `tools/audio/synth.py`, after `sol_rally` (it uses that section's `VOWELS` and `_voice`):

```python
def crowd_panic(rng, dur):
    """A town running for its life: a formant-shaped murmur and dozens of voices crying out across the loop."""
    n = int(round(dur * SR))
    total = n + int(0.06 * SR)                   # loopify's crossfade takes the overflow
    out = np.zeros(total)
    murmur = brown(total, rng)
    for fc, gain in VOWELS[0]:
        out += bandpass(murmur, fc * 0.8, fc * 1.2) * gain * 0.35
    for _ in range(38):
        m = int(rng.uniform(0.25, 0.55) * SR)
        k = np.linspace(0.0, 1.0, m)
        f0 = rng.uniform(260.0, 560.0) * (1.0 + 0.4 * np.sin(np.pi * np.minimum(k * 1.3, 1.0)))
        voice = _voice(rng, m, f0, VOWELS[int(rng.integers(0, 4))], breath=0.2) * adsr(m, 0.02, 0.08, 0.6, 0.12)
        place(out, voice * rng.uniform(0.15, 0.45), rng.uniform(0.0, dur))
    return loopify(reverb(out, size=1.6, mix=0.35), n)
```

and register it next to the other crowd cues:

```python
CUES["crowd_panic"] = ("crowd", crowd_panic, 6.0, True)
```

```bash
python tools/audio/synth.py --only crowd_panic
python tools/audio/synth.py --verify
```

Expected: one `wrote` line, then `0 problems` (the loop's seam check included). In `src/audio/sfx.gd`'s `CATALOG`:

```gdscript
	&"crowd_panic": {"path": "res://assets/audio/crowd/crowd_panic.wav", "db": -8.0, "loop": true},
```

- [ ] **Step 3: Play it under the running crowd**

In `src/game/crowd/crowd.gd`, add:

```gdscript
## The sound of a town running: a looping bed whose level follows how many citizens are running -- silent with
## none, full at BED_FULL -- easing at BED_EASE a second so it swells and fades instead of jumping.
const BED_FULL := 40.0
const BED_EASE := 1.5
const BED_DB := -8.0

var _bed: AudioStreamPlayer
var _bed_level := 0.0


## How loud the panic bed should be, 0 to 1, for this many running citizens.
static func bed_level_for(running: int) -> float:
	return clampf(float(running) / BED_FULL, 0.0, 1.0)


## The mission paused (or the results are up over it): hold the bed where it is.
func pause_bed(paused: bool) -> void:
	if _bed != null:
		_bed.stream_paused = paused


func _update_bed(delta: float) -> void:
	var running := 0
	for p in citizens:
		if is_instance_valid(p) and p.is_alive() and (p.mind == Person.Mind.PANIC or p.mind == Person.Mind.FLEE):
			running += 1
	_bed_level = move_toward(_bed_level, bed_level_for(running), BED_EASE * delta)
	if sfx == null or DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	if _bed == null:
		_bed = AudioStreamPlayer.new()
		_bed.bus = Sfx.BUS
		_bed.stream = Sfx.load_stream(&"crowd_panic")
		add_child(_bed)
	if _bed_level <= 0.001:
		if _bed.playing:
			_bed.stop()
		return
	if not _bed.playing:
		_bed.play()
	_bed.volume_db = BED_DB + linear_to_db(_bed_level)
```

and call `_update_bed(delta)` at the end of `advance(delta)`.

In `src/game/mission.gd`'s `set_frozen(frozen)`, add after setting `process_mode`:

```gdscript
	if is_instance_valid(_crowd):
		_crowd.pause_bed(frozen)
```

- [ ] **Step 4: Run everything**

```bash
bash tools/test.sh
python tools/audio/synth.py --verify
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/game.tscn --audio-driver Dummy -- --flow-test 2>&1 | grep -E "FLOW result|FLOW FAIL|ERROR|leaked"
```

Expected: `checks=644 failures=0` (+5: four here and one more in the catalog suite, which counts every catalog path); `0 problems`; `FLOW result checks=22 failures=0` with nothing leaked at quit (the bed is a new player that must be freed with its crowd). Render the cue's spectrogram and say what it shows: a continuous low murmur band with scattered rising voice arcs across the whole loop.

- [ ] **Step 5: Commit**

```bash
git add tools/audio/synth.py src/audio/sfx.gd assets/audio/crowd/crowd_panic.wav assets/audio/crowd/crowd_panic.wav.import src/game/crowd/crowd.gd src/game/mission.gd tests/test_voices.gd
git commit -m "feat: the sound of a town running" -m "A synthesized crowd-panic loop -- a formant-shaped murmur with dozens of voices crying out across it -- plays under the capped individual yelps, its level following how many citizens are running: silent with none, full at forty, easing rather than jumping, and held while the mission is paused." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---
### Task 5: The music, synthesized

**Files:**
- Modify: `tools/audio/synth.py` (four music loops)
- Modify: `src/audio/sfx.gd` (their catalog entries)
- Create: `assets/audio/music/*.wav` (generated, with `.import` files)
- Modify: `tests/test_voices.gd`

**Why:** note 8. The user chose music made the way every other sound in the game is. Two pieces:
- **the theme** (title and draft): 24 s, D minor, a slow pad of detuned saws under a sine melody with vibrato, a sub-bass root, long reverb — brooding, not busy;
- **the battle** (mission): 16 s at 120 bpm, eight bars of D minor – B♭ – C – A, in **three stems of identical length** — a base (drone and a bass ostinato in eighths), drums (taiko-like thumps with a snare on 2 and 4 and a roll every fourth bar), and a lead (brass-like stabs on the chords). The player (Task 6) layers them in as the city's stability falls.

All four are loops and must pass `verify()`'s seam check. Synthesized music will sound synthetic — the user knows and will judge it at the checkpoint after Task 6.

**Interfaces:**
- Produces: cues `music_theme`, `music_battle_base`, `music_battle_drums`, `music_battle_lead` (all loops) in `Sfx.CATALOG` and `assets/audio/music/`.

- [ ] **Step 1: Write the failing test**

At the end of `tests/test_voices.gd`'s `run()` (before its cleanup):

```gdscript
	# The music: four loops, the three battle stems exactly the same length so they stay in step.
	var lengths: Array[float] = []
	for cue: StringName in [&"music_theme", &"music_battle_base", &"music_battle_drums", &"music_battle_lead"]:
		var stream := Sfx.load_stream(cue) if Sfx.CATALOG.has(cue) else null
		lengths.append(stream.get_length() if stream != null else -1.0)
	t.check(lengths[0] > 20.0, "the theme is a long loop (%.1f s)" % lengths[0])
	t.check(lengths[1] > 0.0 and is_equal_approx(lengths[1], lengths[2]) and is_equal_approx(lengths[1], lengths[3]),
		"the battle's three stems are the same length (%s)" % [lengths])
```

Run `bash tools/test.sh` — expected: these checks fail (no music in the catalog yet).

- [ ] **Step 2: Compose it**

In `tools/audio/synth.py`, after the crowd section:

```python
# --------------------------------------------------------------------------
# Music (KAK milestone 6), synthesized like everything else. A brooding theme for the title and the draft; a battle
# loop in three stems -- base, drums, lead -- that the game layers in as the city falls. All loops, all built with
# loopify, so they pass verify()'s seam check.
# --------------------------------------------------------------------------

def hz(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


BEAT = 0.5                                   # 120 bpm
BAR = BEAT * 4.0
BATTLE_BARS = 8
# Two bars each: D minor, B flat, C, and A -- the dominant that pulls the loop back to its start.
BATTLE_CHORDS = ((38, 41, 45), (34, 38, 41), (36, 40, 43), (33, 37, 40))
THEME_CHORDS = ((50, 53, 57), (46, 50, 53), (41, 45, 48), (48, 52, 55))
# (midi, beats) at 60 bpm: 24 beats, the whole 24 s loop.
THEME_MELODY = ((74, 2), (72, 1), (69, 3), (70, 2), (69, 1), (65, 3),
                (69, 2), (67, 1), (65, 3), (64, 2), (65, 1), (62, 3))


def _note(freq, m, cutoff, a, d, s, r):
    return lowpass(saw(freq, m), cutoff) * adsr(m, a, d, s, r)


def music_theme(rng, dur):
    n = int(round(dur * SR))
    out = np.zeros(n + int(0.06 * SR))
    seg = dur / len(THEME_CHORDS)
    for i in range(len(THEME_CHORDS) + 1):   # one extra chord feeds the loop's crossfade
        chord = THEME_CHORDS[i % len(THEME_CHORDS)]
        m = int(seg * 1.15 * SR)
        pad = sum(lowpass(saw(hz(p), m) + saw(hz(p) * 1.004, m), 900.0) for p in chord)
        place(out, pad * adsr(m, 1.2, 0.5, 0.7, 1.5) * 0.12, i * seg)
        place(out, sine(hz(chord[0] - 12), m) * adsr(m, 0.6, 0.4, 0.8, 1.2) * 0.35, i * seg)
    at = 0.0
    for midi, beats in THEME_MELODY:
        m = int(beats * SR)
        vib = hz(midi) * (1.0 + 0.006 * np.sin(2.0 * np.pi * 5.0 * np.arange(m) / SR))
        place(out, (sine(vib, m) + 0.3 * sine(vib * 2.0, m)) * adsr(m, 0.08, 0.3, 0.6, 0.4) * 0.28, at)
        at += beats
    return loopify(reverb(out, size=1.8, mix=0.4), n)


def music_battle_base(rng, dur):
    n = int(round(dur * SR))
    out = np.zeros(n + int(0.06 * SR))
    step = BEAT / 2.0                        # eighth notes
    pattern = (0, 0, 0, 2, 0, 0, 1, 0)       # root, root, root, fifth, root, root, third, root
    for bar in range(BATTLE_BARS + 1):
        chord = BATTLE_CHORDS[(bar // 2) % len(BATTLE_CHORDS)]
        for i, idx in enumerate(pattern):
            m = int(step * 0.9 * SR)
            place(out, _note(hz(chord[idx] - 12), m, 700.0, 0.005, 0.05, 0.5, 0.05) * 0.5, bar * BAR + i * step)
        if bar % 2 == 0:
            m = int(BAR * 2.0 * SR)
            root = hz(chord[0] - 12)
            drone = lowpass(saw(root, m) + saw(root * 1.005, m), 300.0) * adsr(m, 0.2, 0.3, 0.8, 0.3)
            place(out, drone * 0.3, bar * BAR)
    return loopify(out, n)


def _taiko(rng, m, pitch):
    body = sine(ramp(pitch * 1.8, pitch, m, "exp"), m) * decay(m, 0.18)
    skin = lowpass(noise(m, rng), 900.0) * decay(m, 0.03)
    return saturate(body + skin * 0.5, 1.5)


def _snare(rng, m):
    return bandpass(noise(m, rng), 1500.0, 6000.0) * decay(m, 0.07) + sine(190.0, m) * decay(m, 0.04) * 0.4


def music_battle_drums(rng, dur):
    n = int(round(dur * SR))
    out = np.zeros(n + int(0.06 * SR))
    for bar in range(BATTLE_BARS + 1):
        start = bar * BAR
        for beat in (0.0, 1.5, 2.0):         # taiko on 1, the and of 2, and 3
            place(out, _taiko(rng, int(0.5 * SR), 62.0) * 0.9, start + beat * BEAT)
        for beat in (1.0, 3.0):              # snare on 2 and 4
            place(out, _snare(rng, int(0.25 * SR)) * 0.5, start + beat * BEAT)
        if bar % 4 == 3:                     # a roll into the end of every fourth bar
            for i in range(4):
                place(out, _taiko(rng, int(0.3 * SR), 90.0) * 0.5, start + (3.0 + i * 0.25) * BEAT)
    return loopify(reverb(out, size=1.1, mix=0.18), n)


def music_battle_lead(rng, dur):
    n = int(round(dur * SR))
    out = np.zeros(n + int(0.06 * SR))
    for bar in range(BATTLE_BARS + 1):
        chord = BATTLE_CHORDS[(bar // 2) % len(BATTLE_CHORDS)]
        for beat, length in ((0.0, 1.2), (1.5, 0.4), (2.0, 1.8)):
            m = int(length * BEAT * SR)
            stab = sum(_note(hz(p + 12), m, 1800.0, 0.02, 0.15, 0.5, 0.15) for p in chord)
            place(out, stab * 0.25, bar * BAR + beat * BEAT)
    return loopify(reverb(out, size=1.3, mix=0.25), n)
```

and register them:

```python
for _name, _fn, _dur in (
    ("music_theme", music_theme, 24.0),
    ("music_battle_base", music_battle_base, BAR * BATTLE_BARS),
    ("music_battle_drums", music_battle_drums, BAR * BATTLE_BARS),
    ("music_battle_lead", music_battle_lead, BAR * BATTLE_BARS),
):
    CUES[_name] = ("music", _fn, _dur, True)
```

```bash
for c in music_theme music_battle_base music_battle_drums music_battle_lead; do python tools/audio/synth.py --only $c; done
python tools/audio/synth.py --verify
```

Expected: four `wrote assets/audio/music/...` lines and `0 problems`. If a stem fails the seam check, look at what reaches past the loop's end (a note or reverb tail placed after `n`) rather than touching `verify()`.

Then a mixdown for the user to hear the battle with every layer in (not committed):

```bash
python -c "
import numpy as np; from scipy.io import wavfile
xs = [wavfile.read(f'assets/audio/music/music_battle_{s}.wav')[1].astype(np.float64) for s in ('base', 'drums', 'lead')]
mix = sum(xs); mix /= np.max(np.abs(mix)) * 1.12
wavfile.write('captures/music_battle_mix.wav', 44100, np.round(mix * 32767).astype(np.int16))
print('mix', len(mix) / 44100, 's')"
```

In `src/audio/sfx.gd`'s `CATALOG`:

```gdscript
	&"music_theme": {"path": "res://assets/audio/music/music_theme.wav", "db": 0.0, "loop": true},
	&"music_battle_base": {"path": "res://assets/audio/music/music_battle_base.wav", "db": 0.0, "loop": true},
	&"music_battle_drums": {"path": "res://assets/audio/music/music_battle_drums.wav", "db": 0.0, "loop": true},
	&"music_battle_lead": {"path": "res://assets/audio/music/music_battle_lead.wav", "db": 0.0, "loop": true},
```

- [ ] **Step 3: Run and commit**

```bash
bash tools/test.sh
```

Expected: `checks=650 failures=0` (+6: two here, four in the catalog suite). Render the four spectrograms and describe them: the theme's slow pad bands and melody line; the base's repeating low ostinato; the drums' regular broadband hits with rolls; the lead's stacked stab harmonics on the beat.

```bash
git add tools/audio/synth.py src/audio/sfx.gd assets/audio/music tests/test_voices.gd
git commit -m "feat: the music, synthesized" -m "A 24 s theme for the title and the draft -- a D minor pad under a sine melody -- and a 16 s battle loop at 120 bpm in three stems of the same length, base, drums and lead, for the game to layer as the city falls. Made by synth.py like every other sound; all four pass the loop seam check." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Music that follows the game

**Files:**
- Create: `src/audio/music.gd`
- Modify: `src/game/game.gd` (which track on which screen; ducking under pause; the flow test)
- Modify: `src/game/mission.gd` (feeds the battle its intensity)
- Modify: `tests/test_voices.gd`

**Why:** note 8's other half. `Music` is built like `UiSound`: one node under the scene tree's root, made the first time music is asked for, alive across every screen, and silent in headless runs. It plays the theme on the title and the draft, fades to the battle behind MANIFEST's fade, layers the battle's stems by how far the city has fallen (base always; drums from a third; lead from two thirds), ducks under the pause menu, and falls silent on the results so the win or lose sting stands alone. The three battle stems start together and keep playing — even at zero volume — for the whole mission, so they never drift out of step.

**Interfaces:**
- Produces: `Music.play(track: StringName)` (`&"theme"`, `&"battle"` or `&""`), `Music.set_intensity(x: float)`, `Music.set_ducked(on: bool)`, `Music.current() -> StringName`, `static Music.stem_gains(intensity: float) -> Array[float]`, `const Music.THEME`, `Music.BATTLE`, `Music.DB`, `Music.FADE`, `Music.DUCK_DB`.

- [ ] **Step 1: Write the failing test**

At the end of `tests/test_voices.gd`'s `run()` (before its cleanup):

```gdscript
	# The battle's layers: the base always, the drums from a third of the way down, the lead from two thirds.
	var calm := Music.stem_gains(0.0)
	var half := Music.stem_gains(0.5)
	var falling := Music.stem_gains(1.0)
	t.check(calm[0] == 1.0 and calm[1] == 0.0 and calm[2] == 0.0, "a standing city hears only the battle's base (%s)" % [calm])
	t.check(half[1] == 1.0 and half[2] == 0.0, "half fallen adds the drums (%s)" % [half])
	t.check(falling[0] == 1.0 and falling[1] == 1.0 and falling[2] == 1.0, "and a city falling hears all three (%s)" % [falling])
```

Run `bash tools/test.sh` — expected: `test_voices.gd` fails to load (`Music` does not exist).

- [ ] **Step 2: The player**

Create `src/audio/music.gd`:

```gdscript
class_name Music
extends Node
## Background music, synthesized like every other sound: a brooding theme on the title and the draft, and in the
## mission a battle loop in three stems -- base, drums, lead -- layered in as the city falls. Not positional, not
## tied to a battlefield, and alive across every screen change so one track can fade into the next. Built the way
## UiSound is: one node under the scene tree's root, made the first time music is asked for, silent headless.

const THEME := &"music_theme"
const BATTLE := [&"music_battle_base", &"music_battle_drums", &"music_battle_lead"]
## The music's level under everything else.
const DB := -10.0
## Seconds for a track or a layer to fade fully in or out.
const FADE := 1.2
## How far the music drops while the pause menu is up.
const DUCK_DB := -12.0

static var _node: Music

var _theme: AudioStreamPlayer
var _stems: Array[AudioStreamPlayer] = []
## Current gain (0..1) of the theme and of each stem, eased toward their targets.
var _theme_gain := 0.0
var _stem_gain: Array[float] = [0.0, 0.0, 0.0]
var _want := &""
var _intensity := 0.0
var _ducked := false


## What should be playing: &"theme", &"battle", or &"" for silence. Fades from whatever is playing now.
static func play(track: StringName) -> void:
	var m := _get()
	if m != null:
		m._switch(track)


## How far the city has fallen, 0 (standing) to 1 (falling): how many battle layers are in.
static func set_intensity(x: float) -> void:
	var m := _get()
	if m != null:
		m._intensity = clampf(x, 0.0, 1.0)


static func set_ducked(on: bool) -> void:
	var m := _get()
	if m != null:
		m._ducked = on


static func current() -> StringName:
	return _node._want if is_instance_valid(_node) else &""


## Each battle stem's volume at an intensity: the base always; the drums from a third of the way, the lead from
## two thirds, each fading in over a sixth so the music thickens rather than switches.
static func stem_gains(intensity: float) -> Array[float]:
	return [1.0, clampf((intensity - 0.33) / 0.17, 0.0, 1.0), clampf((intensity - 0.66) / 0.17, 0.0, 1.0)]


static func _get() -> Music:
	if DisplayServer.get_name() == "headless":
		return null  # no audio, and a node made during the headless suite would outlive it
	if not is_instance_valid(_node):
		var tree := Engine.get_main_loop() as SceneTree
		if tree == null or tree.root == null:
			return null
		_node = Music.new()
		_node.name = "Music"
		tree.root.add_child.call_deferred(_node)
	return _node


func _ready() -> void:
	_theme = _player(THEME)
	for cue: StringName in BATTLE:
		_stems.append(_player(cue))


func _player(cue: StringName) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = Sfx.load_stream(cue)
	p.volume_db = -80.0
	add_child(p)
	return p


func _switch(track: StringName) -> void:
	if track == _want:
		return
	_want = track
	if not is_inside_tree():
		return  # _process picks the wish up once the node is in
	if track == &"battle":
		# Start all three stems together, so identical lengths keep them in step for the whole mission.
		for p in _stems:
			p.play(0.0)
	elif track == &"theme" and not _theme.playing:
		_theme.play(0.0)


func _process(delta: float) -> void:
	if _theme == null:
		return
	if _want == &"battle" and not _stems[0].playing:
		for p in _stems:
			p.play(0.0)
	elif _want == &"theme" and not _theme.playing:
		_theme.play(0.0)
	var step := delta / FADE
	_theme_gain = move_toward(_theme_gain, 1.0 if _want == &"theme" else 0.0, step)
	var targets: Array[float] = [0.0, 0.0, 0.0]
	if _want == &"battle":
		targets = stem_gains(_intensity)
	for i in _stems.size():
		_stem_gain[i] = move_toward(_stem_gain[i], float(targets[i]), step)
	var duck := DUCK_DB if _ducked else 0.0
	_apply(_theme, _theme_gain, duck)
	for i in _stems.size():
		_apply(_stems[i], _stem_gain[i], duck)
	# A track faded right out stops, so nothing plays silently forever -- except a battle stem while the battle
	# is on, which must keep running to stay in step.
	if _theme_gain <= 0.0 and _theme.playing:
		_theme.stop()
	if _want != &"battle" and _stem_gain.max() <= 0.0 and _stems[0].playing:
		for p in _stems:
			p.stop()


func _apply(p: AudioStreamPlayer, gain: float, duck: float) -> void:
	p.volume_db = DB + duck + (linear_to_db(gain) if gain > 0.0005 else -80.0)
```

- [ ] **Step 3: Follow the game**

In `src/game/game.gd`:
- in `go_to()`, after its `match`: play the theme on `Screen.TITLE` and `Screen.PREPARE`, and silence on `Screen.RESULTS` (`Music.play(&"")`) so the win or lose sting stands alone;
- in `_faded_into_mission()`, right after `await _fader.fade_out(FADE_OUT)`: `Music.play(&"battle")` — the battle rises behind the fade;
- in `_open_pause()`: `Music.set_ducked(true)`; in `_close_pause()`: `Music.set_ducked(false)`.

In `src/game/mission.gd`'s `_process()`, once started and not in the ending, feed the battle how far the city has fallen, twice a second:

```gdscript
	_music_in -= delta
	if _music_in <= 0.0:
		_music_in = 0.5
		Music.set_intensity(1.0 - _rules.stability.total())
```

with `var _music_in := 0.0` next to the other state.

In `_flow_test()`, add two steps: right after the first check that the game opens on the title, `step.call(Music.current() == &"theme", "the title plays the theme")`; and after the mission is up (after the fade has cleared), `step.call(Music.current() == &"battle", "the mission plays the battle")`.

- [ ] **Step 4: Run everything**

```bash
bash tools/test.sh
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/game.tscn --audio-driver Dummy -- --flow-test 2>&1 | grep -E "FLOW|ERROR|leaked"
SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test 2>&1 | grep -E "MISSION test|ERROR|SCRIPT|WARNING"
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tools/dev/state_digest.gd
python tools/audio/synth.py --verify
```

Expected: `checks=653 failures=0` (+3); `FLOW result checks=24 failures=0` with no leak lines at quit (the music node lives under root; `6619f26`'s audio-thread wait before quitting covers it — if a leak appears, say so with the lines); one `MISSION test` line; the digest unchanged; `0 problems`.

- [ ] **Step 5: Commit**

```bash
git add src/audio/music.gd src/audio/music.gd.uid src/game/game.gd src/game/mission.gd tests/test_voices.gd
git commit -m "feat: music that follows the game" -m "The theme plays on the title and the draft; MANIFEST's fade brings in the battle, whose drums and lead join as the city's stability falls; the pause menu ducks it and the results silence it so the sting stands alone. The three battle stems start together and keep running for the whole mission, so they never drift apart." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

**User checkpoint:** the controller sends `assets/audio/music/music_theme.wav`, `captures/music_battle_mix.wav` and `assets/audio/crowd/crowd_panic.wav` and waits for approval.

---

## Milestone check

1. `bash tools/test.sh` — `checks=653 failures=0`, pristine.
2. The digest exactly as in the Global Constraints; `python tools/audio/synth.py --verify` — `0 problems`.
3. `--flow-test` — `FLOW result checks=24 failures=0`, nothing leaked; one `MISSION test`; one `CROWD result`; the two gate close-ups.
4. A bench line next to milestone 5's (99–106 fps).
5. Hand `play.bat` to the user with this round's notes as the checklist. Still open, by the user's choice: Tornado Tempest's wander and its preview clip.
