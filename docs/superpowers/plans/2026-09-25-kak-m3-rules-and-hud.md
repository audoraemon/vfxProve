# KAK Milestone 3 — Rules and HUD — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the inhabited town into a playable four-minute mission: Divine Power, cooldowns, the timer, City Stability, the alarm, win and lose, and the in-mission HUD with its icons.

**Architecture:** Three new units sit between what milestone 2 built and the player. `Rules` (a Node) owns the mission's numbers — DP, cooldowns, the clock, stability, chains, win/lose, score — and learns everything from the signals `EnvironmentField`, `EnemyField`, `Crowd` and `Citadel` already emit. `Targeting` (a Node2D on the ground plane) shows the picked power's area, turns clicks and drags into casts through `Rules`, and frightens the crowd where a cast lands. `Hud` (a Control on the battlefield's HUD layer) draws the pixel UI and only ever reads. `Mission` composes them with `Battlefield`, `Town`, `WalkGrid` and `Crowd`, and is the scene the user plays.

**Tech Stack:** Godot 4.7.2, GDScript, `gl_compatibility`, 640×360 viewport; the existing `src/fx/` effects, `src/game/` town and crowd, Pixelify Sans and the 11 painted icons already in `assets/`.

## Global Constraints

- Engine: `F:\Godot\Godot_v4.7.2-stable_win64_console.exe` (Git Bash: `/f/Godot/Godot_v4.7.2-stable_win64_console.exe`), renderer `gl_compatibility`.
- Viewport 640×360, nearest filtering, `2d/snap/snap_2d_vertices_to_pixel=true`: pixel lines are hairlines (`width = -1.0`); never `draw_line` with width ≥ 1.
- Iso: one ground unit = one 64×32 cell; `Iso.ground_to_screen(g) = ((g.x - g.y) * 32, (g.x + g.y) * 16)`. Town coordinates: origin at the town centre, plan north = −y. A node parented to `Battlefield.ground_plane` already carries `Iso.BASIS`, so it draws in ground units.
- The 11 approved effects and the effect toolkit (`src/fx/`) do not change. Nothing in `src/fx/` is edited by this milestone — the aim previews read the effects' constants, they do not move them.
- New game code lives in `src/game/` (rules and targeting directly in it, UI in `src/game/ui/`).
- Art is procedural, in the existing pixel style; the only external assets are the ones already committed: `assets/fonts/PixelifySans-Variable.ttf` and `assets/pixellab/icons/*.png` (84×84 cards) with `assets/pixellab/icons/hud/*.png` (42×42 HUD copies).
- Tests: `bash tools/test.sh` must end `checks=<N> failures=0`; the **376 checks** standing today keep passing. Suites are `extends RefCounted` scripts with `static func run(t) -> void`, registered in `tests/run_all.gd`; use `t.check(cond, msg)` and `t.near(a, b, eps, msg)`.
- Behaviour gate: `/f/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tools/dev/state_digest.gd` must keep printing `rows=19`, `digest=61267b7e90524d800bf1c3473a71146b`, `blocked=000000111000000000000011000000000000000000001110000000000000`, `emitters=45`. Never edit that tool or those values. Screenshots are the weaker check — the hit-stop is timed against real time, so effect frames drift between identical runs.
- Performance (spec §7): the full town with 160 people averages **42.6 fps during Cinderfall** today; the user accepted that. Do not spend this milestone's time on frame rate, but do not make it worse: the HUD redraws only when what it shows changes, and `Rules` recomputes stability at most once a frame.
- The game's name in any text is **Kingdoms Amid Kataclysm** / **KAK** (never KWAI or HUM).
- Every number in this plan comes from the spec (`docs/superpowers/specs/2026-09-19-kak-one-mission-game-design.md` §4) and is a starting value to tune in milestone 5. Do not "improve" one because it looks off in play; report it instead.
- GDScript style: tabs, typed vars; explicit types when a value comes from an untyped Array or Dictionary; `##` doc comments like the surrounding code.
- Commit after each task; every message ends with a blank line and `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`. Commit new scripts with their generated `.gd.uid` files.
- Leave the untracked `.codex/` folder and `docs/HUM_Game_Design_Document_v1.docx` alone.
- **Out of scope, on purpose:** the Title, Prepare, Pause and Results screens, the saved best score and loadout, the 2 s mission intro sweep, and UI sounds (including the buzz a refused cast plays -- the slot still flashes red here). They are milestones 4 and 5. This milestone ends a mission with a banner and a printed stat block, and takes the loadout from a constant or the command line.

---

## File Structure

| File | Responsibility |
|---|---|
| `src/game/stability.gd` (new) | City Stability: the five parts, their weights, the weighted total. Pure measurement — no signals, no scene. |
| `src/game/rules.gd` (new) | One mission's numbers: DP and its recovery, cooldowns, the clock, chains, stability, win/lose, score and rank. Casts through `FxTimeline.cast` on `Targeting`'s behalf. |
| `src/game/targeting.gd` (new) | The picked power, its area preview on the ground, click/drag/cancel input, and the crowd's fright where a cast lands. |
| `src/game/ui/ui_theme.gd` (new) | The pixel font, the palette, the shared gold icon frame, and the `0:00` clock format. Shared with milestone 4's screens. |
| `src/game/ui/hud.gd` (new) | The in-mission HUD: timer, objectives, city status, DP bar with popups, four slots, centre banners. Reads only. |
| `src/game/mission.gd` (new) | One run: builds the world, the town, the crowd, the rules, the targeting and the HUD; restart; the scripted `--mission-test`. |
| `scenes/mission.tscn` (new) | The mission scene. |
| `play.bat` (new) | Opens the mission windowed, the way `town.bat` opens the debug scene. |
| `src/game/crowd/crowd.gd` (modify) | `on_cast()` learns about lanes, so a drag power frightens people along it instead of at its start point. |
| `tests/test_stability.gd`, `tests/test_rules.gd`, `tests/test_score.gd`, `tests/test_targeting.gd`, `tests/test_hud.gd` (new) | One suite per unit, registered in `tests/run_all.gd`. |

Task order: 1, 2, 3, 4, 5, 6, 7. Each task ends with a green suite and a commit.

Expected `checks=` after each task: Task 1 → 392, Task 2 → 413, Task 3 → 429, Task 4 → 451, Task 5 → 474, Task 6 → 490, Task 7 → 490.

---

### Task 1: City Stability

**Files:**
- Create: `src/game/stability.gd`
- Create: `tests/test_stability.gd`
- Modify: `tests/run_all.gd`

**Why:** the mission is won when the Citadel is down **and** stability reaches 0, so this is the win condition's other half and the HUD's five-colour bar. It is pure measurement over the town, the crowd and the Citadel, which makes it the one piece of milestone 3 that can be written and proved without a scene.

**Interfaces:**
- Consumes: `EnvironmentField.structures()`, `Structure.role` / `.destroyed` / `.footprint`; `Crowd.spawned_citizens`, `spawned_soldiers`, `killed_citizens`, `killed_soldiers`, `escaped_count`; `Citadel.fraction()`.
- Produces: `Stability.new().setup(env) -> Stability`, `measure(env, crowd, citadel) -> void`, the five parts `population` / `infrastructure` / `leadership` / `military` / `resources`, `total() -> float`, `is_broken() -> bool`, and the weight and threshold constants Task 4 and the HUD read.

- [ ] **Step 1: Write the failing test**

Create `tests/test_stability.gd`:

```gdscript
extends RefCounted
## City Stability: each part falls linearly to its broken point, and the total is the spec's weighted sum.


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
	var stab := Stability.new().setup(env)

	stab.measure(env, crowd, town.citadel)
	t.near(stab.total(), 1.0, 0.0001, "an untouched city is at full stability (%.3f)" % stab.total())

	# Population: broken when 75% of the citizens are dead or gone, and linear on the way there.
	for i in 41:
		field.kill(crowd.citizens[i], &"nova")
	crowd.advance(0.0)
	stab.measure(env, crowd, town.citadel)
	t.near(stab.population, 0.503, 0.01, "half the way to 75%% dead is half the population part (%.3f)" % stab.population)
	for i in range(41, 83):
		field.kill(crowd.citizens[i], &"nova")
	crowd.advance(0.0)
	stab.measure(env, crowd, town.citadel)
	t.check(stab.population == 0.0, "75%% dead or escaped breaks the population part (%.3f)" % stab.population)
	t.check(crowd.killed_citizens == 83, "the kills were counted (%d)" % crowd.killed_citizens)

	# Infrastructure is measured by footprint, so the wall weighs more than a house.
	var infra_area := 0.0
	for s in env.structures():
		if Stability.INFRA_ROLES.has(s.role):
			infra_area += s.footprint.get_area()
	t.check(infra_area > 0.0, "the town has an infrastructure footprint (%.1f)" % infra_area)
	var razed := 0.0
	for s in env.structures():
		if razed >= infra_area * Stability.INFRASTRUCTURE_BROKEN:
			break
		if Stability.INFRA_ROLES.has(s.role) and not s.destroyed:
			s.destroy(s.center(), &"nova")
			razed += s.footprint.get_area()
	stab.measure(env, crowd, town.citadel)
	t.check(stab.infrastructure == 0.0, "70%% of the footprint in rubble breaks infrastructure (%.3f)" % stab.infrastructure)

	# Leadership is the Citadel's health, straight through.
	t.near(stab.leadership, town.citadel.fraction(), 0.0001, "leadership is the Citadel's health (%.3f)" % stab.leadership)
	# Two rolling seconds of 200 damage: the Citadel can only lose 250 of its 1000 in a second, so this takes
	# it to 60% and leaves it standing. Six rounds would flatten it, and the "has not fallen" check below --
	# which is about a city whose Leadership is the only part left -- would then be wrong.
	for i in 2:
		town.citadel.advance(1.01)
		env.damage_radius(TownLayout.CITADEL_ORIGIN, 4.0, 200.0, &"nova")
	stab.measure(env, crowd, town.citadel)
	t.near(stab.leadership, town.citadel.fraction(), 0.0001, "and follows it down (%.3f)" % stab.leadership)
	t.check(stab.leadership < 1.0, "the Citadel took damage (%.3f)" % stab.leadership)

	# Military: two thirds the soldiers (broken at 80% dead), one third the Barracks.
	var military_before := stab.military
	var barracks: Structure = null
	for s in env.structures():
		if s.role == &"barracks":
			barracks = s
			break
	barracks.destroy(barracks.center(), &"nova")
	stab.measure(env, crowd, town.citadel)
	t.near(military_before - stab.military, 1.0 - Stability.MILITARY_SOLDIER_SHARE, 0.0001,
		"the Barracks is a third of the military part (%.3f -> %.3f)" % [military_before, stab.military])
	for i in 40:
		field.kill(crowd.soldiers[i], &"nova")
	crowd.advance(0.0)
	stab.measure(env, crowd, town.citadel)
	t.check(stab.military == 0.0, "80%% of the soldiers dead with the Barracks gone breaks it (%.3f)" % stab.military)

	# Resources: the market stalls and the farm fields, counted per building.
	var res_total := 0
	for s in env.structures():
		if Stability.RESOURCE_ROLES.has(s.role):
			res_total += 1
	var res_down := 0
	for s in env.structures():
		if Stability.RESOURCE_ROLES.has(s.role) and not s.destroyed \
				and float(res_down) < float(res_total) * Stability.RESOURCES_BROKEN:
			s.destroy(s.center(), &"nova")
			res_down += 1
	stab.measure(env, crowd, town.citadel)
	t.check(res_total >= 5 and stab.resources == 0.0,
		"80%% of the market and the farms breaks resources (%d of %d, %.3f)" % [res_down, res_total, stab.resources])

	# The total is the weighted sum, and everything broken is a fallen city.
	t.near(stab.total(), Stability.W_LEADERSHIP * stab.leadership, 0.0001,
		"with only leadership left the total is its weight (%.3f)" % stab.total())
	t.check(not stab.is_broken(), "a city with a standing Citadel has not fallen")
	# Radius 3.0, not 4.0: every Citadel part is within 2.6 of the origin, but the Temple's near edge is 3.5
	# away, and a blast that took it down as well would pay its 8 DP into the 15 being measured here.
	while not town.citadel.is_fallen():
		town.citadel.advance(1.01)
		env.damage_radius(TownLayout.CITADEL_ORIGIN, 3.0, 400.0, &"nova")
	stab.measure(env, crowd, town.citadel)
	t.check(stab.is_broken() and stab.total() == 0.0, "with the Citadel down as well, the city has fallen (%.3f)" % stab.total())

	# The weights are the spec's, and they add up.
	t.near(Stability.W_POPULATION + Stability.W_INFRASTRUCTURE + Stability.W_LEADERSHIP + Stability.W_MILITARY
		+ Stability.W_RESOURCES, 1.0, 0.0001, "the five weights add up to one")

	crowd.clear()
	field.clear()
	field.free()
	env.clear()
	env.free()
	town.free()
	crowd.free()
	world.free()
```

- [ ] **Step 2: Register it and run it to see it fail**

In `tests/run_all.gd`, add `"res://tests/test_stability.gd",` to `SUITES` after `"res://tests/test_crowd.gd",`.

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_stability.gd` and `checks=377 failures=1` (the loader counts a failed load as one check).

- [ ] **Step 3: Write the implementation**

Create `src/game/stability.gd`:

```gdscript
class_name Stability
extends RefCounted
## City Stability (spec §4.3): five parts, each falling linearly from 1 (untouched) to 0 (broken), weighted
## 30 / 25 / 20 / 15 / 10. Every part breaks well before its last target is gone, so the player never has to
## hunt one surviving farmer. Pure measurement: it reads the town, the crowd and the Citadel and keeps no
## history of its own.

const W_POPULATION := 0.30
const W_INFRASTRUCTURE := 0.25
const W_LEADERSHIP := 0.20
const W_MILITARY := 0.15
const W_RESOURCES := 0.10

## Population breaks when this fraction of the citizens are dead or escaped.
const POPULATION_BROKEN := 0.75
## Infrastructure breaks when this fraction of the town's footprint is rubble.
const INFRASTRUCTURE_BROKEN := 0.70
## The soldier share of Military breaks at this fraction dead.
const SOLDIERS_BROKEN := 0.80
## Resources break when this fraction of the market stalls and farm fields are destroyed.
const RESOURCES_BROKEN := 0.80
## Military is two thirds soldiers, one third the Barracks.
const MILITARY_SOLDIER_SHARE := 2.0 / 3.0

## The roles Infrastructure measures, by footprint (spec §4.3: houses, walls, towers, gates, the Bridge, the
## Temple). The Citadel is Leadership's business, and decor (trees, torch posts) is nobody's.
const INFRA_ROLES := [&"house", &"wall", &"tower", &"gate", &"bridge", &"temple"]
## The roles Resources measures, counted per building: a stall and a field weigh the same.
const RESOURCE_ROLES := [&"market", &"farm"]

var population := 1.0
var infrastructure := 1.0
var leadership := 1.0
var military := 1.0
var resources := 1.0

## Footprint area and building counts of the town as it was built, so each part measures against the whole
## city and not against whatever is left of it.
var _infra_area := 0.0
var _resource_count := 0
var _barracks_count := 0


## Take the totals from the standing town. Call once, after Town.build().
func setup(env: EnvironmentField) -> Stability:
	_infra_area = 0.0
	_resource_count = 0
	_barracks_count = 0
	for s in env.structures():
		if INFRA_ROLES.has(s.role):
			_infra_area += s.footprint.get_area()
		elif RESOURCE_ROLES.has(s.role):
			_resource_count += 1
		elif s.role == &"barracks":
			_barracks_count += 1
	return self


## Recompute the five parts. Cheap enough for a few times a second, not for every frame of every effect:
## Rules calls it once a frame at most, and only when something it measures has changed.
func measure(env: EnvironmentField, crowd: Crowd, citadel: Citadel) -> void:
	var lost_citizens := crowd.killed_citizens + crowd.escaped_count
	population = _part(float(lost_citizens), float(crowd.spawned_citizens) * POPULATION_BROKEN)

	var razed := 0.0
	var resources_down := 0
	var barracks_down := 0
	for s in env.structures():
		if not s.destroyed:
			continue
		if INFRA_ROLES.has(s.role):
			razed += s.footprint.get_area()
		elif RESOURCE_ROLES.has(s.role):
			resources_down += 1
		elif s.role == &"barracks":
			barracks_down += 1
	infrastructure = _part(razed, _infra_area * INFRASTRUCTURE_BROKEN)
	resources = _part(float(resources_down), float(_resource_count) * RESOURCES_BROKEN)

	leadership = citadel.fraction() if is_instance_valid(citadel) else 0.0

	var soldiers := _part(float(crowd.killed_soldiers), float(crowd.spawned_soldiers) * SOLDIERS_BROKEN)
	var barracks := 1.0
	if _barracks_count > 0:
		barracks = _part(float(barracks_down), float(_barracks_count))
	military = soldiers * MILITARY_SOLDIER_SHARE + barracks * (1.0 - MILITARY_SOLDIER_SHARE)


## The weighted total, 1 (untouched) down to 0 (fallen).
func total() -> float:
	return population * W_POPULATION + infrastructure * W_INFRASTRUCTURE + leadership * W_LEADERSHIP \
		+ military * W_MILITARY + resources * W_RESOURCES


func is_broken() -> bool:
	return total() <= 0.0


## One part: `lost` of `broken_at` gone, as a health from 1 down to 0. A city with none of something (no farms
## at all) counts that part as whole rather than as already broken.
func _part(lost: float, broken_at: float) -> float:
	if broken_at <= 0.0:
		return 1.0
	return clampf(1.0 - lost / broken_at, 0.0, 1.0)
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash tools/test.sh`
Expected: `checks=392 failures=0`, and no `SCRIPT ERROR` or `ERROR` line anywhere in the output.

If the population check misses, print `crowd.killed_citizens`, `crowd.escaped_count` and `crowd.spawned_citizens` before asserting rather than widening the tolerance: 41 of 110 against a break point of 82.5 is 0.503, and a different number means the crowd counted something else.

- [ ] **Step 5: Commit**

```bash
git add src/game/stability.gd src/game/stability.gd.uid tests/test_stability.gd tests/test_stability.gd.uid tests/run_all.gd
git commit -m "feat: City Stability" -m "The five parts of the spec's stability sum (population, infrastructure by footprint, the Citadel's health, the soldiers and the Barracks, the market and the farms), each falling linearly to its broken point, weighted 30/25/20/15/10. Pure measurement over the town, the crowd and the Citadel." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---
### Task 2: Divine Power, cooldowns and the clock

**Files:**
- Create: `src/game/rules.gd`
- Create: `tests/test_rules.gd`
- Modify: `tests/run_all.gd`

**Why:** this is the mission's spine. Everything else in the milestone either spends DP, reads the clock, or watches what a cast did. It is also where the one testability seam lives: `Rules` does the casting, but through a `caster` callable, so headless tests can drive the whole economy without building a single effect (effects make shaders, particles and audio players; a test that instantiated eleven of them would be slow and would prove nothing about the rules).

**Interfaces:**
- Consumes: `PowerBook.get_power(key)` (`dp`, `cooldown`, `aim`, `path`, `name`), `FxTimeline.cast(script, ctx, ground, extra)`, `Battlefield.ctx`.
- Produces:
  - `Rules.new().setup(loadout: PackedStringArray, ctx: FxContext, env: EnvironmentField, field: EnemyField, crowd: Crowd, town: Town) -> Rules`
  - `advance(delta: float) -> void` (also called from `_process`), `dp: float`, `time_left: float`, `finished: bool`
  - `power(slot: int) -> Dictionary`, `key(slot: int) -> String`, `cost(slot: int) -> int`, `cooldown_left(slot: int) -> float`
  - `refusal(slot: int) -> String` — `""`, `"cooldown"`, `"dp"`, `"empty"` or `"over"`
  - `cast(slot: int, ground: Vector2, extra := {}) -> FxTimeline`
  - signals `dp_changed(value)`, `cast_made(slot, key, at)`, `cast_refused(slot, reason)`
  - `caster: Callable` — `func(script: GDScript, ground: Vector2, extra: Dictionary) -> FxTimeline`, replaceable in tests

- [ ] **Step 1: Write the failing test**

Create `tests/test_rules.gd`:

```gdscript
extends RefCounted
## The mission's economy: Divine Power and its regeneration, the four slots' costs and cooldowns, the clock,
## and what happens when a cast cannot be paid for.


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

	var loadout := PackedStringArray(["heaven", "tsunami", "cinder", "nova"])
	var rules := Rules.new().setup(loadout, null, env, field, crowd, town)
	# No effects in a headless test: remember what would have been cast and hand back nothing.
	var casts: Array = []
	rules.caster = func(script: GDScript, ground: Vector2, extra: Dictionary) -> FxTimeline:
		casts.append([script.resource_path, ground, extra])
		return null

	t.check(rules.dp == Rules.DP_MAX and rules.dp == 100.0, "the mission starts on a full 100 DP (%.1f)" % rules.dp)
	t.near(rules.time_left, 240.0, 0.0001, "the manifestation lasts four minutes (%.1f)" % rules.time_left)
	t.check(rules.key(0) == "heaven" and rules.key(3) == "nova", "the loadout fills slots 1 to 4 in order")
	t.check(rules.cost(0) == 10 and rules.cost(3) == 40, "each slot costs its power's DP (%d, %d)" % [rules.cost(0), rules.cost(3)])
	t.check(rules.refusal(0) == "" and rules.refusal(4) == "empty", "a paid-up slot is ready and a fifth slot is empty")

	# A cast spends its cost and starts its cooldown.
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, reason: String): refused.append([slot, reason]))
	var made: Array = []
	rules.cast_made.connect(func(slot: int, power_key: String, at: Vector2): made.append([slot, power_key, at]))
	rules.cast(0, Vector2(2.0, -3.0), {"dir": Vector2(1, 0)})
	t.check(rules.dp == 90.0, "casting Heaven Splitter spends its 10 DP (%.1f)" % rules.dp)
	t.check(casts.size() == 1 and String(casts[0][0]).ends_with("heaven_splitter.gd"),
		"and reaches the world as its own effect script (%s)" % [casts])
	t.check(made.size() == 1 and made[0][0] == 0 and made[0][1] == "heaven" and made[0][2] == Vector2(2.0, -3.0),
		"and is reported with its slot, power and place (%s)" % [made])
	t.near(rules.cooldown_left(0), 20.0, 0.0001, "the slot goes on its 20 s cooldown (%.1f)" % rules.cooldown_left(0))
	t.check(rules.refusal(0) == "cooldown", "so the slot refuses a second cast")
	rules.cast(0, Vector2(2.0, -3.0))
	t.check(rules.dp == 90.0 and casts.size() == 1 and refused == [[0, "cooldown"]],
		"a refused cast costs nothing and says why (%.1f DP, %s)" % [rules.dp, refused])

	# The cooldown runs off, DP creeps back at half a point a second, and the clock runs down.
	rules.advance(19.0)
	t.near(rules.cooldown_left(0), 1.0, 0.0001, "the cooldown counts down (%.1f)" % rules.cooldown_left(0))
	t.check(rules.refusal(0) == "cooldown", "and still refuses with a second to go")
	rules.advance(1.0)
	t.check(rules.cooldown_left(0) == 0.0 and rules.refusal(0) == "", "then the slot is ready again")
	t.near(rules.dp, 100.0, 0.0001, "20 s of regeneration at 0.5/s tops the bar back up (%.1f)" % rules.dp)
	rules.advance(10.0)
	t.check(rules.dp == 100.0, "and DP never passes 100 (%.1f)" % rules.dp)
	t.near(rules.time_left, 240.0 - 30.0, 0.0001, "the clock has run 30 s (%.1f)" % rules.time_left)

	# Too little DP is its own refusal, and the cost is not taken.
	rules.cast(3, Vector2.ZERO)
	rules.cast(2, Vector2.ZERO)
	t.near(rules.dp, 100.0 - 40.0 - 25.0, 0.0001, "two casts spend both costs (%.1f)" % rules.dp)
	rules.dp = 15.0   # the Tsunami (slot index 1) costs 20, and that slot has not been cast yet
	refused.clear()
	rules.cast(1, Vector2.ZERO, {"dir": Vector2(0, 1)})
	t.check(refused == [[1, "dp"]] and rules.dp == 15.0, "20 DP is out of reach on 15 and nothing is spent (%s)" % refused)

	# The clock stops the mission dead: no more casting once it is out.
	rules.advance(300.0)
	t.check(rules.time_left == 0.0, "the clock floors at zero (%.1f)" % rules.time_left)
	refused.clear()
	rules.cast(0, Vector2.ZERO, {"dir": Vector2(1, 0)})
	t.check(refused == [[0, "over"]], "and a finished mission takes no more casts (%s)" % refused)

	rules.free()
	crowd.clear()
	field.clear()
	field.free()
	env.clear()
	env.free()
	town.free()
	crowd.free()
	world.free()
```

- [ ] **Step 2: Register it and run it to see it fail**

In `tests/run_all.gd`, add `"res://tests/test_rules.gd",` to `SUITES` after `"res://tests/test_stability.gd",`.

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_rules.gd` and `checks=393 failures=1`.

- [ ] **Step 3: Write the implementation**

Create `src/game/rules.gd`. This is the whole file for this task; Tasks 3 and 4 add to it.

```gdscript
class_name Rules
extends Node
## One mission's numbers (spec §4): Divine Power and its recovery, the four slots' cooldowns, the four-minute
## clock, City Stability, chains, win and lose, score and rank. It learns what happened from the signals the
## world already emits and never reaches into the world itself, except to start a cast.

signal dp_changed(value: float)
## A cast went out: the slot, its power key and where it landed.
signal cast_made(slot: int, key: String, at: Vector2)
## A cast could not go out: "cooldown", "dp", "empty" or "over".
signal cast_refused(slot: int, reason: String)

const DP_MAX := 100.0
## Divine Power comes back this fast on its own (spec §4.1).
const DP_REGEN := 0.5
## The manifestation's length in seconds (spec §1: 4:00).
const MISSION_SECONDS := 240.0

var dp := DP_MAX
var time_left := MISSION_SECONDS
## The four drafted power keys, in slot order.
var loadout := PackedStringArray()
## The mission is over: the clock ran out, the people got away, or the city fell.
var finished := false

## How a cast reaches the world: func(script: GDScript, ground: Vector2, extra: Dictionary) -> FxTimeline.
## Set in setup() to go through FxTimeline.cast; tests replace it so they need no effects.
var caster := Callable()

var _ctx: FxContext
var _env: EnvironmentField
var _field: EnemyField
var _crowd: Crowd
var _town: Town
## Seconds of cooldown left per slot.
var _cooldowns := PackedFloat32Array()


func setup(powers: PackedStringArray, ctx: FxContext, env: EnvironmentField, field: EnemyField, crowd: Crowd,
		town: Town) -> Rules:
	loadout = powers
	_ctx = ctx
	_env = env
	_field = field
	_crowd = crowd
	_town = town
	_cooldowns.resize(loadout.size())
	_cooldowns.fill(0.0)
	caster = func(script: GDScript, ground: Vector2, extra: Dictionary) -> FxTimeline:
		return FxTimeline.cast(script, _ctx, ground, extra)
	return self


func _process(delta: float) -> void:
	advance(delta)


## Drive the mission by hand (tests and scripted runs) or from _process.
func advance(delta: float) -> void:
	if finished:
		return
	for i in _cooldowns.size():
		_cooldowns[i] = maxf(0.0, _cooldowns[i] - delta)
	if dp < DP_MAX:
		dp = minf(DP_MAX, dp + DP_REGEN * delta)
		dp_changed.emit(dp)
	time_left = maxf(0.0, time_left - delta)
	if time_left <= 0.0:
		finished = true


## The power in a slot, or an empty dictionary for a slot nothing was drafted into.
func power(slot: int) -> Dictionary:
	if slot < 0 or slot >= loadout.size():
		return {}
	return PowerBook.get_power(loadout[slot])


func key(slot: int) -> String:
	var p := power(slot)
	return String(p.get("key", ""))


func cost(slot: int) -> int:
	var p := power(slot)
	return int(p.get("dp", 0))


func cooldown_left(slot: int) -> float:
	if slot < 0 or slot >= _cooldowns.size():
		return 0.0
	return _cooldowns[slot]


## Why this slot cannot cast right now, or "" when it can. The cooldown is named first: it is the wait the
## player can do nothing about, and the HUD shows its seconds.
func refusal(slot: int) -> String:
	if finished:
		return "over"
	if power(slot).is_empty():
		return "empty"
	if cooldown_left(slot) > 0.0:
		return "cooldown"
	if dp < float(cost(slot)):
		return "dp"
	return ""


## Spend the slot's DP, start its cooldown and put its effect in the world. Returns the running effect, or
## null when the cast was refused (and when a test's caster hands nothing back).
func cast(slot: int, ground: Vector2, extra := {}) -> FxTimeline:
	var reason := refusal(slot)
	if reason != "":
		cast_refused.emit(slot, reason)
		return null
	var p := power(slot)
	dp -= float(cost(slot))
	dp_changed.emit(dp)
	_cooldowns[slot] = float(p.cooldown)
	var fx: FxTimeline = caster.call(load(String(p.path)) as GDScript, ground, extra)
	cast_made.emit(slot, String(p.key), ground)
	return fx
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash tools/test.sh`
Expected: `checks=413 failures=0`.

- [ ] **Step 5: Commit**

```bash
git add src/game/rules.gd src/game/rules.gd.uid tests/test_rules.gd tests/test_rules.gd.uid tests/run_all.gd
git commit -m "feat: Divine Power, cooldowns and the mission clock" -m "Rules owns the mission's economy: 100 DP regenerating at 0.5/s, the four slots' costs and cooldowns, the four-minute clock, and a cast path that spends before it summons and says why when it cannot. Casting goes through a replaceable caller, so the headless tests drive the whole economy without building effects." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 3: What a cast destroyed — DP recovery and chains

**Files:**
- Modify: `src/game/rules.gd`
- Modify: `tests/test_rules.gd`

**Why:** DP only comes back by destroying things that matter, and the chain bonus needs to know which cast did it. The world reports a destroyed building and a kill with the **damage kind** that caused it (`&"nova"`, `&"stone"`, …), so the credit is a lookup from that kind to the casts still running. Two kinds are shared — `&"cinder"` by Dragonfire Parade and the Cinderfall Barrage, `&"stone"` by the Barrage and Judgement of the Ancients — which is exactly why the spec says the latest running cast wins a tie.

**Interfaces:**
- Consumes: `EnvironmentField.structure_destroyed(s: Structure, kind: StringName)`, `EnemyField.enemy_killed(enemy: DummyEnemy, kind: StringName)`, `Citadel.fallen`, `Person.soldier`, `Structure.role`, `FxTimeline.finished`.
- Produces: `buildings_down: int`, `chains: int`, `killed_citizens`/`killed_soldiers`/`escaped` read through `Crowd`, signals `dp_gained(amount: float, at: Vector2)`, `chained(at: Vector2)`, `banner(text: String)`, and the constants `POWER_KINDS`, `BUILDING_ROLES`, `DP_FOR_ROLE`, `DP_SOLDIER`, `CITADEL_DP`, `CHAIN_BUILDINGS`, `CHAIN_KILLS`, `CHAIN_DP`.

- [ ] **Step 1: Write the failing test**

In `tests/test_rules.gd`, insert this block immediately **before** the closing `rules.free()`. It starts a fresh mission so the earlier block's spent DP and stopped clock do not muddy it.

```gdscript
	# --- What a cast destroyed -------------------------------------------------------------------------
	var r2 := Rules.new().setup(loadout, null, env, field, crowd, town)
	var gains: Array = []
	r2.dp_gained.connect(func(amount: float, at: Vector2): gains.append([amount, at]))
	var banners: Array = []
	r2.banner.connect(func(text: String): banners.append(text))
	var chains: Array = []
	r2.chained.connect(func(at: Vector2): chains.append(at))
	r2.caster = func(_script: GDScript, _ground: Vector2, _extra: Dictionary) -> FxTimeline:
		return null
	r2.dp = 50.0   # spend first: a gain cannot show on a bar that is already full

	# Nothing is credited to nobody: a destroyed building still pays its DP.
	var towers: Array[Structure] = []
	for s in env.structures():
		if s.role == &"tower" and not s.destroyed:
			towers.append(s)
	var houses: Array[Structure] = []
	for s in env.structures():
		if s.role == &"house" and not s.destroyed:
			houses.append(s)
	t.check(towers.size() >= 4 and houses.size() >= 11, "the town still has towers and houses to break (%d, %d)" % [towers.size(), houses.size()])
	var dp_before := r2.dp
	houses[0].destroy(houses[0].center(), &"nova")
	t.check(r2.dp == dp_before and r2.buildings_down == 1, "a house is worth no DP but counts as a building (%.1f, %d)" % [r2.dp, r2.buildings_down])
	towers[0].destroy(towers[0].center(), &"nova")
	t.near(r2.dp, dp_before + 3.0, 0.0001, "a wall tower pays 3 DP (%.1f)" % r2.dp)
	t.check(gains.size() == 1 and gains[0][0] == 3.0, "and the gain is reported for its popup (%s)" % [gains])

	# The Citadel's own parts are the Citadel's, not nine more buildings.
	var parts_before := r2.buildings_down
	town.citadel.parts[0].destroy(town.citadel.parts[0].center(), &"nova")
	t.check(r2.buildings_down == parts_before, "a fallen Citadel part is not counted as a building (%d)" % r2.buildings_down)

	# A soldier pays, a citizen does not.
	dp_before = r2.dp
	var soldier: Person = null
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.is_alive():
			soldier = p
			break
	field.kill(soldier, &"nova")
	t.near(r2.dp, dp_before + Rules.DP_SOLDIER, 0.0001, "a dead soldier pays 0.4 DP (%.1f)" % r2.dp)
	dp_before = r2.dp
	var citizen: Person = null
	for p in crowd.citizens:
		if is_instance_valid(p) and p.is_alive():
			citizen = p
			break
	field.kill(citizen, &"nova")
	t.check(r2.dp == dp_before, "a dead citizen pays nothing (%.1f)" % r2.dp)

	# Credit goes to the running cast whose power deals that kind, and the latest one wins a tie.
	r2.cast(2, Vector2(1.0, 1.0))   # cinder: deals &"cinder" and &"stone"
	t.check(r2.credited_key(&"stone") == "cinder", "the Barrage is credited for falling stone (%s)" % r2.credited_key(&"stone"))
	t.check(r2.credited_key(&"ice") == "", "and nothing running deals ice (%s)" % r2.credited_key(&"ice"))

	# Six buildings from one cast is a chain: +6 DP and the banner.
	var dp_chain := r2.dp
	for i in 6:
		houses[i + 1].destroy(houses[i + 1].center(), &"stone")
	t.check(chains.size() == 1, "six buildings from one cast is one chain (%d)" % chains.size())
	t.near(r2.dp - dp_chain, Rules.CHAIN_DP, 0.0001, "worth 6 DP (%.1f)" % (r2.dp - dp_chain))
	t.check(banners.has("CHAIN!"), "and says so (%s)" % [banners])
	t.check(r2.chains == 1, "the chain is kept for the score (%d)" % r2.chains)
	for i in range(7, 11):
		houses[i].destroy(houses[i].center(), &"stone")
	t.check(r2.chains == 1, "one cast only ever chains once (%d)" % r2.chains)

	# The Citadel falling is worth 15 DP and its own banner.
	dp_before = r2.dp
	# Radius 3.0, not 4.0: every Citadel part is within 2.6 of the origin, but the Temple's near edge is 3.5
	# away, and a blast that took it down as well would pay its 8 DP into the 15 being measured here.
	while not town.citadel.is_fallen():
		town.citadel.advance(1.01)
		env.damage_radius(TownLayout.CITADEL_ORIGIN, 3.0, 400.0, &"nova")
	t.near(r2.dp - dp_before, Rules.CITADEL_DP, 0.0001, "the Citadel's fall pays 15 DP (%.1f)" % (r2.dp - dp_before))
	t.check(banners.has("THE CITADEL FALLS"), "and is announced (%s)" % [banners])
	r2.free()
```

- [ ] **Step 2: Run it to see it fail**

Run: `bash tools/test.sh`
Expected: a parse error naming `credited_key` (`Cannot find member "credited_key" in base "Rules"`), reported as `FAIL: suite failed to load: res://tests/test_rules.gd`, and the run ends `checks=393 failures=1`.

- [ ] **Step 3: Write the implementation**

In `src/game/rules.gd`, add the signals next to the existing ones:

```gdscript
## Divine Power came back from something that was destroyed, at the place it happened (for the popup).
signal dp_gained(amount: float, at: Vector2)
## One cast destroyed six buildings or killed twenty-five people.
signal chained(at: Vector2)
## Something worth a line across the middle of the screen.
signal banner(text: String)
```

the constants after `MISSION_SECONDS`:

```gdscript
## What each destroyed thing pays back (spec §4.1). Citizens, houses, the market, the farms and the walls pay
## nothing: the player is not rewarded for shopping.
const DP_FOR_ROLE := {&"tower": 3.0, &"gate": 5.0, &"temple": 8.0, &"barracks": 10.0}
const DP_SOLDIER := 0.4
const CITADEL_DP := 15.0
## One cast that destroys this many buildings, or kills this many people, is a chain.
const CHAIN_BUILDINGS := 6
const CHAIN_KILLS := 25
const CHAIN_DP := 6.0

## The damage kinds each power deals, so a destroyed building or a kill can be credited to the cast that did
## it. Two kinds are shared (Dragonfire Parade and the Barrage both burn with &"cinder"; the Barrage and
## Judgement both drop &"stone"), which the tie rule in _credit() settles.
const POWER_KINDS := {
	"heaven": [&"lightning"],
	"tornado": [&"wind"],
	"dragon": [&"fire", &"cinder"],
	"tsunami": [&"water"],
	"gravity": [&"gravity"],
	"laser": [&"laser"],
	"orbital": [&"orbital"],
	"cinder": [&"cinder", &"stone"],
	"judgement": [&"stone"],
	"glacial": [&"ice"],
	"nova": [&"nova"],
}
## The roles that count as a building for the tally, the chain and the score. Decor (trees, torch posts) does
## not, and the Citadel's nine parts are not nine buildings -- the Citadel is worth its own CITADEL_DP.
const BUILDING_ROLES := [&"house", &"wall", &"tower", &"gate", &"temple", &"barracks", &"market", &"farm", &"bridge"]
## How long a cast with no effect behind it (a test's stub, an effect that has already finished) can still be
## credited for what it started.
const CAST_GRACE := 4.0
```

the state after `finished`:

```gdscript
## Buildings destroyed this mission, by BUILDING_ROLES.
var buildings_down := 0
## How many casts chained.
var chains := 0
```

and after `_cooldowns`:

```gdscript
## One entry per cast that may still be credited: {"key", "fx", "at", "buildings", "kills", "chained", "until"}.
var _casts: Array[Dictionary] = []
```

Connect the world in `setup()`, just before `return self`:

```gdscript
	_env.structure_destroyed.connect(_on_structure_destroyed)
	_field.enemy_killed.connect(_on_killed)
	if is_instance_valid(_town) and is_instance_valid(_town.citadel):
		_town.citadel.fallen.connect(_on_citadel_fallen)
```

Record the cast in `cast()`, replacing its last two lines (`var fx := ...` and `cast_made.emit(...)`) with:

```gdscript
	var fx: FxTimeline = caster.call(load(String(p.path)) as GDScript, ground, extra)
	_casts.append({"key": String(p.key), "fx": fx, "at": ground, "buildings": 0, "kills": 0, "chained": false,
		"until": _elapsed + CAST_GRACE})
	cast_made.emit(slot, String(p.key), ground)
	return fx
```

Add the elapsed clock next to `_cooldowns` and keep it in `advance()`:

```gdscript
## Seconds since the mission started, for the casts' grace window.
var _elapsed := 0.0
```

In `advance()`, after the cooldown loop, add:

```gdscript
	_elapsed += delta
	_forget_old_casts()
```

Then add the crediting itself at the end of the file:

```gdscript
## The power key credited with this damage kind: among the casts still running, the one whose power deals it,
## latest first (spec §4.1). "" when nothing running claims it -- a building that falls to a stray fire after
## its cast is gone still pays its DP, it just has nobody to chain for.
func credited_key(kind: StringName) -> String:
	var c := _credit(kind)
	return String(c.get("key", "")) if not c.is_empty() else ""


func _credit(kind: StringName) -> Dictionary:
	for i in range(_casts.size() - 1, -1, -1):
		var c: Dictionary = _casts[i]
		var kinds: Array = POWER_KINDS.get(c.key, [])
		if kinds.has(kind):
			return c
	return {}


## Drop casts whose effect has finished and whose grace has run out, so a four-minute mission does not credit
## a kill to a volcano that went cold three minutes ago.
func _forget_old_casts() -> void:
	var keep: Array[Dictionary] = []
	for c in _casts:
		var fx: FxTimeline = c.fx
		var running: bool = is_instance_valid(fx) and not fx.finished
		if running or _elapsed < float(c.until):
			keep.append(c)
	_casts = keep


func _on_structure_destroyed(s: Structure, kind: StringName) -> void:
	if not BUILDING_ROLES.has(s.role):
		return
	buildings_down += 1
	var pay: float = DP_FOR_ROLE.get(s.role, 0.0)
	if pay > 0.0:
		_gain(pay, s.center())
	var c := _credit(kind)
	if c.is_empty():
		return
	c.buildings = int(c.buildings) + 1
	_check_chain(c)


func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	var p := e as Person
	if p != null and p.soldier:
		_gain(DP_SOLDIER, p.ground_pos)
	var c := _credit(kind)
	if c.is_empty():
		return
	c.kills = int(c.kills) + 1
	_check_chain(c)


func _on_citadel_fallen() -> void:
	var at: Vector2 = _town.citadel.origin if is_instance_valid(_town.citadel) else Vector2.ZERO
	_gain(CITADEL_DP, at)
	banner.emit("THE CITADEL FALLS")


func _check_chain(c: Dictionary) -> void:
	if bool(c.chained) or (int(c.buildings) < CHAIN_BUILDINGS and int(c.kills) < CHAIN_KILLS):
		return
	c.chained = true
	chains += 1
	_gain(CHAIN_DP, c.at)
	chained.emit(c.at)
	banner.emit("CHAIN!")


func _gain(amount: float, at: Vector2) -> void:
	dp = minf(DP_MAX, dp + amount)
	dp_changed.emit(dp)
	dp_gained.emit(amount, at)
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash tools/test.sh`
Expected: `checks=429 failures=0`.

Two traps to watch for, both of which show up as a wrong DP number rather than an error:

- `Rules` connects to the same `EnvironmentField` and `EnemyField` the other suites use. The test above makes a **second** `Rules` on purpose; if you connect a third, every destroyed building pays twice. Free a `Rules` you are done with (the test does).
- `_gain()` clamps at `DP_MAX`, so a test that expects `+3` while already on 100 DP sees nothing. The test spends first for that reason.

- [ ] **Step 5: Commit**

```bash
git add src/game/rules.gd tests/test_rules.gd
git commit -m "feat: DP recovery, cast credit and chains" -m "A destroyed tower, gate, Temple, Barracks or soldier pays its Divine Power back, the Citadel's fall pays 15, and each kill or destruction is credited to the running cast whose power deals that damage kind (latest wins a tie, which is how the shared cinder and stone kinds are settled). Six buildings or twenty-five people from one cast is a chain: +6 DP and the banner." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---
### Task 4: Win, lose, score and rank

**Files:**
- Modify: `src/game/rules.gd`
- Create: `tests/test_score.gd`
- Modify: `tests/run_all.gd`

**Why:** the mission needs an end. This is also where `Stability` gets wired in, because the win condition is the Citadel **and** a stability of zero, and where the numbers the Results screen will show in milestone 4 are worked out — so milestone 4 has nothing left to invent.

**Interfaces:**
- Consumes: `Stability` (Task 1), `Crowd.escaped` and `escaped_count`, `Citadel.health_changed` and `is_fallen()`.
- Produces: `stability: Stability`, `won: bool`, `over_reason: String` (`"citadel"`, `"escapes"`, `"timeout"`), signal `over(won: bool, reason: String)`, `score() -> int`, `rank() -> String`, `stat_lines() -> Array[Dictionary]` (each `{"label": String, "value": String, "points": int}`), and the constants `ESCAPE_LIMIT`, `SCORE_*`, `RANKS`.

**Interpretation to keep (say so in the commit, not in a new number):** the spec lists "+25 per second left" and "+10 per DP left when winning" together. Both are paid **only on a win** here — a mission lost because 38 citizens got away would otherwise score the player for losing quickly.

- [ ] **Step 1: Write the failing test**

Create `tests/test_score.gd`:

```gdscript
extends RefCounted
## How a mission ends and what it is worth: the two ways to lose, the one way to win, the score's arithmetic
## and the rank thresholds.


static func run(t) -> void:
	# --- Losing on the clock ---------------------------------------------------------------------------
	var a := _mission()
	var rules: Rules = a.rules
	var ended: Array = []
	rules.over.connect(func(won: bool, reason: String): ended.append([won, reason]))
	rules.advance(Rules.MISSION_SECONDS + 1.0)
	t.check(ended == [[false, "timeout"]], "the clock running out loses the mission (%s)" % [ended])
	t.check(rules.finished and not rules.won, "and the mission is over")
	rules.advance(1.0)
	t.check(ended.size() == 1, "the end is announced once (%d)" % ended.size())
	t.check(rules.score() == 0, "a mission with nothing destroyed scores nothing (%d)" % rules.score())
	t.check(rules.rank() == "D", "which is a D (%s)" % rules.rank())
	_drop(a)

	# --- Losing to the escape ------------------------------------------------------------------------
	var b := _mission()
	rules = b.rules
	var crowd: Crowd = b.crowd
	ended = []
	rules.over.connect(func(won: bool, reason: String): ended.append([won, reason]))
	for i in Rules.ESCAPE_LIMIT:
		crowd.escaped_count += 1
	rules.advance(0.1)
	t.check(ended == [[false, "escapes"]], "38 citizens getting away loses it (%s)" % [ended])
	t.near(rules.time_left, Rules.MISSION_SECONDS - 0.1, 0.0001, "with time still on the clock (%.1f)" % rules.time_left)
	_drop(b)

	# --- Winning -------------------------------------------------------------------------------------
	var c := _mission()
	rules = c.rules
	crowd = c.crowd
	var env: EnvironmentField = c.env
	var town: Town = c.town
	ended = []
	rules.over.connect(func(won: bool, reason: String): ended.append([won, reason]))
	rules.advance(40.0)
	t.check(not rules.finished, "a mission with a standing city runs on")
	for s in env.structures():
		if not s.destroyed and s.role != &"citadel":
			s.destroy(s.center(), &"nova")
	for p in crowd.citizens.duplicate():
		if is_instance_valid(p) and p.is_alive():
			c.field.kill(p, &"nova")
	for p in crowd.soldiers.duplicate():
		if is_instance_valid(p) and p.is_alive():
			c.field.kill(p, &"nova")
	rules.advance(0.1)
	t.check(not rules.finished, "a razed town with the Citadel still up is not a win yet")
	# Radius 3.0, not 4.0: every Citadel part is within 2.6 of the origin, but the Temple's near edge is 3.5
	# away, and a blast that took it down as well would pay its 8 DP into the 15 being measured here.
	while not town.citadel.is_fallen():
		town.citadel.advance(1.01)
		env.damage_radius(TownLayout.CITADEL_ORIGIN, 3.0, 400.0, &"nova")
	rules.advance(0.1)
	t.check(ended.size() == 1 and ended[0][0] == true and ended[0][1] == "citadel",
		"the Citadel down with stability at zero wins it (%s)" % [ended])
	t.near(rules.stability.total(), 0.0, 0.0001, "the city has fallen (%.3f)" % rules.stability.total())

	# The score is the spec's arithmetic, line by line.
	var seconds := int(roundf(rules.time_left))
	var dp_left := int(floorf(rules.dp))
	var expected := Rules.SCORE_WIN + seconds * Rules.SCORE_PER_SECOND + dp_left * Rules.SCORE_PER_DP \
		+ rules.buildings_down * Rules.SCORE_PER_BUILDING + crowd.killed_citizens * Rules.SCORE_PER_CITIZEN \
		+ crowd.killed_soldiers * Rules.SCORE_PER_SOLDIER + rules.chains * Rules.SCORE_PER_CHAIN
	t.check(rules.score() == expected, "the score adds up (%d, expected %d)" % [rules.score(), expected])
	t.check(rules.buildings_down >= 50 and crowd.killed_citizens == 110,
		"this run flattened the town and everyone in it (%d buildings, %d citizens)" % [rules.buildings_down, crowd.killed_citizens])
	var points := 0
	for line: Dictionary in rules.stat_lines():
		points += int(line.points)
	t.check(points == rules.score(), "and the results table adds up to the same (%d)" % points)
	t.check(rules.rank() == "S", "a flattened city on the first minute is an S (%s, %d)" % [rules.rank(), rules.score()])
	_drop(c)

	# --- The rank thresholds -------------------------------------------------------------------------
	# Driven through the real score, one chain at a time: 300 points each, so the thresholds land exactly.
	var d := _mission()
	rules = d.rules
	rules.chains = 40
	t.check(rules.score() == 12000 and rules.rank() == "S", "40 chains is 12,000 points and an S (%d, %s)" % [rules.score(), rules.rank()])
	rules.chains = 39
	t.check(rules.rank() == "A", "11,700 is an A (%s)" % rules.rank())
	rules.chains = 30
	t.check(rules.score() == 9000 and rules.rank() == "A", "9,000 is still an A (%d)" % rules.score())
	rules.chains = 29
	t.check(rules.rank() == "B", "8,700 is a B (%s)" % rules.rank())
	rules.chains = 20
	t.check(rules.score() == 6000 and rules.rank() == "B", "6,000 is still a B (%d)" % rules.score())
	rules.chains = 10
	t.check(rules.rank() == "C" and rules.score() == 3000, "3,000 is a C (%s)" % rules.rank())
	rules.chains = 9
	t.check(rules.rank() == "D", "2,700 is a D (%s)" % rules.rank())
	_drop(d)


## A fresh mission's world, with its own field and crowd so one test's kills never leak into another's.
static func _mission() -> Dictionary:
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
	var rules := Rules.new().setup(PackedStringArray(["heaven", "tsunami", "cinder", "nova"]), null, env, field,
		crowd, town)
	rules.caster = func(_script: GDScript, _ground: Vector2, _extra: Dictionary) -> FxTimeline:
		return null
	return {"env": env, "town": town, "field": field, "crowd": crowd, "rules": rules, "world": world}


static func _drop(m: Dictionary) -> void:
	var rules: Rules = m.rules
	rules.free()
	var crowd: Crowd = m.crowd
	crowd.clear()
	var field: EnemyField = m.field
	field.clear()
	field.free()
	var env: EnvironmentField = m.env
	env.clear()
	env.free()
	var town: Town = m.town
	town.free()
	crowd.free()
	var world: Node2D = m.world
	world.free()
```

- [ ] **Step 2: Register it and run it to see it fail**

In `tests/run_all.gd`, add `"res://tests/test_score.gd",` to `SUITES` after `"res://tests/test_rules.gd",`.

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_score.gd` and `checks=430 failures=1`.

- [ ] **Step 3: Write the implementation**

In `src/game/rules.gd`, add the signal:

```gdscript
## The mission ended. reason: "citadel" (won), "escapes" or "timeout".
signal over(won: bool, reason: String)
```

the constants after `CAST_GRACE`:

```gdscript
## This many citizens reaching an exit loses the mission (spec §4.4).
const ESCAPE_LIMIT := 38

const SCORE_WIN := 5000
const SCORE_PER_SECOND := 25
const SCORE_PER_BUILDING := 40
const SCORE_PER_CITIZEN := 10
const SCORE_PER_SOLDIER := 25
const SCORE_PER_CHAIN := 300
const SCORE_PER_DP := 10
## Score floors for each rank, best first; anything under the last one is a D.
const RANKS := [[12000, "S"], [9000, "A"], [6000, "B"], [3000, "C"]]
```

and the state:

```gdscript
## The five-part city health. Measured at most once a frame, and only after something changed it.
var stability: Stability
var won := false
## Which ending: "citadel", "escapes", "timeout", or "" while the mission runs.
var over_reason := ""

var _stability_dirty := true
```

In `setup()`, **replace the connection block Task 3 added** with this one — three of its lines are the same, so a paste that keeps both would connect twice and count every destroyed building twice:

```gdscript
	stability = Stability.new().setup(_env)
	_env.structure_destroyed.connect(_on_structure_destroyed)
	_field.enemy_killed.connect(_on_killed)
	_crowd.escaped.connect(_on_escaped)
	if is_instance_valid(_town) and is_instance_valid(_town.citadel):
		_town.citadel.fallen.connect(_on_citadel_fallen)
		_town.citadel.health_changed.connect(_on_citadel_health)
	stability.measure(_env, _crowd, _town.citadel)
```

Replace the end of `advance()` — the `time_left` lines — with:

```gdscript
	time_left = maxf(0.0, time_left - delta)
	if _stability_dirty:
		_stability_dirty = false
		stability.measure(_env, _crowd, _town.citadel)
	_check_end()
```

Add the handlers and the scoring at the end of the file:

```gdscript
func _on_escaped(_p: Person) -> void:
	_stability_dirty = true


func _on_citadel_health(_fraction: float) -> void:
	_stability_dirty = true
```

and mark the same flag in `_on_structure_destroyed()` (first line of the function, before the role test — a destroyed farm is no building but it is still lost resources) and in `_on_killed()` (also first line):

```gdscript
	_stability_dirty = true
```

Then:

```gdscript
## Win: the Citadel is down and the city's stability has reached zero. Lose: the people got away, or the
## manifestation ran out. The win is tested first, so a city that falls on the last tick of the clock counts.
func _check_end() -> void:
	if finished:
		return
	if is_instance_valid(_town.citadel) and _town.citadel.is_fallen() and stability.is_broken():
		_finish(true, "citadel")
	elif _crowd.escaped_count >= ESCAPE_LIMIT:
		_finish(false, "escapes")
	elif time_left <= 0.0:
		_finish(false, "timeout")


func _finish(win: bool, reason: String) -> void:
	finished = true
	won = win
	over_reason = reason
	over.emit(won, reason)


## The mission's points (spec §4.4). The victory bonus, the seconds left and the DP left are a winner's only:
## a mission lost to the escape would otherwise pay the player for losing it quickly.
func score() -> int:
	var total := buildings_down * SCORE_PER_BUILDING + _crowd.killed_citizens * SCORE_PER_CITIZEN \
		+ _crowd.killed_soldiers * SCORE_PER_SOLDIER + chains * SCORE_PER_CHAIN
	if won:
		total += SCORE_WIN + int(roundf(time_left)) * SCORE_PER_SECOND + int(floorf(dp)) * SCORE_PER_DP
	return total


func rank() -> String:
	var s := score()
	for r: Array in RANKS:
		if s >= int(r[0]):
			return String(r[1])
	return "D"


## The results table: one line per scoring rule, with what it was worth. Milestone 4's Results screen draws
## these; Task 7 prints them at the end of a scripted run.
func stat_lines() -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	if won:
		lines.append({"label": "The city has fallen", "value": "", "points": SCORE_WIN})
		lines.append({"label": "Time left", "value": UiTheme.clock(time_left), "points": int(roundf(time_left)) * SCORE_PER_SECOND})
		lines.append({"label": "Divine Power left", "value": "%d" % int(floorf(dp)), "points": int(floorf(dp)) * SCORE_PER_DP})
	lines.append({"label": "Buildings destroyed", "value": "%d" % buildings_down, "points": buildings_down * SCORE_PER_BUILDING})
	lines.append({"label": "Citizens killed", "value": "%d" % _crowd.killed_citizens, "points": _crowd.killed_citizens * SCORE_PER_CITIZEN})
	lines.append({"label": "Soldiers killed", "value": "%d" % _crowd.killed_soldiers, "points": _crowd.killed_soldiers * SCORE_PER_SOLDIER})
	lines.append({"label": "Citizens escaped", "value": "%d" % _crowd.escaped_count, "points": 0})
	lines.append({"label": "Chains", "value": "%d" % chains, "points": chains * SCORE_PER_CHAIN})
	return lines
```

`stat_lines()` uses `UiTheme.clock()`, which Task 6 writes. Until then, format it here as `"%d:%02d" % [int(time_left) / 60, int(time_left) % 60]` and swap it for `UiTheme.clock(time_left)` in Task 6 — the swap is one line and Task 6's step list says so.

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash tools/test.sh`
Expected: `checks=451 failures=0`.

If the win never fires, print `rules.stability.population`, `.infrastructure`, `.military` and `.resources` after the razing loop: the likely cause is a part that cannot reach zero because the loop skipped a role (the Bridge and the farm fields are `walkable`, and a walkable structure still has to be destroyed to count).

- [ ] **Step 5: Commit**

```bash
git add src/game/rules.gd tests/test_score.gd tests/test_score.gd.uid tests/run_all.gd
git commit -m "feat: win, lose, score and rank" -m "A mission is won when the Royal Citadel is down and City Stability has reached zero, and lost when the manifestation runs out or thirty-eight citizens escape. The score follows the spec line by line, with the victory bonus, the seconds left and the DP left paid only to a winner, and stat_lines() hands the same table to the HUD now and the Results screen in milestone 4." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 5: Aiming and casting

**Files:**
- Create: `src/game/targeting.gd`
- Modify: `src/game/crowd/crowd.gd`
- Create: `tests/test_targeting.gd`
- Modify: `tests/run_all.gd`

**Why:** the player's whole input. It also fixes a milestone 2 loose end: a drag power frightens the crowd only where the player pressed, so a tsunami's far end walked through calm streets.

The areas drawn here are **the effects' own constants**, listed in one table with the constant each number comes from. The test loads the effect scripts and compares, so a preview cannot quietly drift away from what the effect does.

**Interfaces:**
- Consumes: `Rules.refusal/cast/power`, `Rules.cast_made`, `Crowd.on_cast`, `PowerBook.get_power(key).aim`, `Battlefield.ground_plane`.
- Produces:
  - `Targeting.new().setup(rules: Rules, crowd: Crowd) -> Targeting` (add it as a child of `Battlefield.ground_plane`)
  - `pick(slot: int) -> void`, `slot: int`, signal `picked(slot)`
  - `hover(ground: Vector2) -> void`, `press(ground: Vector2) -> void`, `release(ground: Vector2) -> void`, `cancel() -> void`, `aiming: bool`
  - `const AREAS: Dictionary` — per power key: `shape` (`"circle"`, `"lane"`, `"cone"`) plus `r`/`inner`/`roam`, `length`/`half`, `arc`
- Produces (Crowd): `on_cast(ground: Vector2, dir := Vector2.ZERO, length := 0.0)`

- [ ] **Step 1: Write the failing test**

Create `tests/test_targeting.gd`:

```gdscript
extends RefCounted
## Aiming: the preview areas are the effects' own numbers, a click casts, a drag aims, and a lane power
## frightens the whole street it crosses.


static func run(t) -> void:
	# The preview table is the effects' constants, not a copy that can drift.
	var heaven: GDScript = load("res://src/fx/set2/heaven_splitter.gd")
	var tsunami: GDScript = load("res://src/fx/set2/tsunami_breaker.gd")
	var laser: GDScript = load("res://src/fx/walking_laser_grid.gd")
	var nova: GDScript = load("res://src/fx/nuclear_nova.gd")
	var cinder: GDScript = load("res://src/fx/set2/cinderfall_barrage.gd")
	var dragon: GDScript = load("res://src/fx/set2/dragonfire_parade.gd")
	var tornado: GDScript = load("res://src/fx/set2/tornado_tempest.gd")
	var h: Dictionary = Targeting.AREAS["heaven"]
	t.near(float(h.length), _k(heaven, "LINE_LENGTH"), 0.0001, "Heaven Splitter's lane is its LINE_LENGTH (%.1f)" % h.length)
	t.near(float(h.half), _k(heaven, "LINE_HALF_WIDTH"), 0.0001, "and its own half width (%.2f)" % h.half)
	var ts: Dictionary = Targeting.AREAS["tsunami"]
	t.near(float(ts.length), _k(tsunami, "LENGTH"), 0.0001, "the Tsunami's lane is its LENGTH (%.1f)" % ts.length)
	t.near(float(ts.half), _k(tsunami, "WIDTH") * 0.5, 0.0001, "and half the wall's WIDTH (%.1f)" % ts.half)
	var ls: Dictionary = Targeting.AREAS["laser"]
	t.near(float(ls.length), _k(laser, "LENGTH"), 0.0001, "the Laser Grid walks its LENGTH (%.1f)" % ls.length)
	t.near(float(ls.half), _k(laser, "KILL_HALF_WIDTH"), 0.0001, "in a KILL_HALF_WIDTH band (%.1f)" % ls.half)
	t.near(float(Targeting.AREAS["nova"].r), _k(nova, "RADIUS"), 0.0001, "the Nova's circle is its RADIUS")
	t.near(float(Targeting.AREAS["nova"].inner), _k(nova, "KILL_CORE"), 0.0001, "with its KILL_CORE inside")
	t.near(float(Targeting.AREAS["cinder"].r), _k(cinder, "RADIUS"), 0.0001, "the Barrage's circle is its RADIUS")
	t.near(float(Targeting.AREAS["dragon"].r), _k(dragon, "CONE_RADIUS"), 0.0001, "the dragon's cone is its CONE_RADIUS")
	t.near(float(Targeting.AREAS["dragon"].arc), _k(dragon, "SWEEP_ARC"), 0.0001, "over its SWEEP_ARC")
	t.near(float(Targeting.AREAS["tornado"].roam), _k(tornado, "WANDER_RADIUS"), 0.0001, "the tornado roams its WANDER_RADIUS")
	var missing := ""
	for key in PowerBook.keys():
		if not Targeting.AREAS.has(key):
			missing += " " + key
	t.check(missing == "", "every power has an area to show (missing:%s)" % missing)

	# Aiming: a click casts a point power where it was clicked, a drag casts along its direction.
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
	var rules := Rules.new().setup(PackedStringArray(["nova", "tsunami", "cinder", "heaven"]), null, env, field,
		crowd, town)
	var casts: Array = []
	rules.caster = func(_script: GDScript, ground: Vector2, extra: Dictionary) -> FxTimeline:
		casts.append([ground, extra])
		return null
	var aim := Targeting.new().setup(rules, crowd)

	aim.pick(0)
	aim.press(Vector2(2.0, 2.0))
	t.check(not aim.aiming, "a click power does not start a drag")
	aim.release(Vector2(2.4, 2.1))
	t.check(casts.size() == 1 and casts[0][0] == Vector2(2.0, 2.0) and not casts[0][1].has("dir"),
		"a click power is cast where the button went down, with no direction (%s)" % [casts])

	aim.pick(1)
	aim.press(Vector2(-3.0, 0.0))
	t.check(aim.aiming, "a drag power starts aiming")
	aim.release(Vector2(0.0, 0.0))
	t.check(casts.size() == 2 and casts[1][0] == Vector2(-3.0, 0.0), "and is cast from where the drag started")
	t.check((casts[1][1].dir as Vector2).is_equal_approx(Vector2(1, 0)),
		"pointed the way it was dragged (%s)" % [casts[1][1].dir])
	t.check(not aim.aiming, "and the drag is done")

	aim.pick(3)
	aim.press(Vector2(0.0, 5.0))
	aim.cancel()
	t.check(not aim.aiming and casts.size() == 2, "cancelling a drag casts nothing (%d)" % casts.size())

	# A lane power frightens the people along it, not only at its start.
	var far: Person = crowd.citizens[0]
	var near: Person = crowd.citizens[1]
	var bystander: Person = crowd.citizens[2]
	far.ground_pos = Vector2(5.0, -8.0)
	near.ground_pos = Vector2(-1.0, -8.0)
	bystander.ground_pos = Vector2(-1.0, 3.0)
	for p in [far, near, bystander]:
		p.mind = Person.Mind.CALM
	crowd.on_cast(Vector2(-2.0, -8.0), Vector2(1, 0), 10.0)
	t.check(near.mind == Person.Mind.PANIC, "someone beside the lane's start panics")
	t.check(far.mind == Person.Mind.PANIC, "and so does someone seven units down it")
	t.check(bystander.mind == Person.Mind.CALM, "someone a street away does not")

	rules.free()
	aim.free()
	crowd.clear()
	field.clear()
	field.free()
	env.clear()
	env.free()
	town.free()
	crowd.free()
	world.free()


## One constant out of an effect's script, by name.
static func _k(script: GDScript, name: String) -> float:
	return float(script.get_script_constant_map()[name])
```

- [ ] **Step 2: Register it and run it to see it fail**

In `tests/run_all.gd`, add `"res://tests/test_targeting.gd",` to `SUITES` after `"res://tests/test_score.gd",`.

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_targeting.gd` and `checks=452 failures=1`.

- [ ] **Step 3: Teach the crowd about lanes**

In `src/game/crowd/crowd.gd`, replace `on_cast()`:

```gdscript
## A cast landed: everyone close enough panics. A lane power (`dir` set, `length` above zero) frightens people
## along its whole lane -- a tsunami's far end runs through streets the player never pressed on.
func on_cast(ground: Vector2, dir := Vector2.ZERO, length := 0.0) -> void:
	var points: Array[Vector2] = [ground]
	if dir != Vector2.ZERO and length > 0.0:
		var step := PANIC_CAST
		var along := step
		var unit := dir.normalized()
		while along < length:
			points.append(ground + unit * along)
			along += step
		points.append(ground + unit * length)
	for p in citizens:
		if not is_instance_valid(p) or not p.is_alive():
			continue
		for point in points:
			if p.ground_pos.distance_to(point) <= PANIC_CAST:
				p.panic(point)
				break
```

- [ ] **Step 4: Write the targeting**

Create `src/game/targeting.gd`:

```gdscript
class_name Targeting
extends Node2D
## Aiming: which slot is picked, the area it would cover drawn on the ground, and the click or drag that turns
## into a cast. A child of Battlefield.ground_plane, so it draws in ground units and its circles come out as
## the right iso ellipses. It knows nothing about the mouse: Mission hands it ground positions, which is also
## what makes it testable headless.

## The player picked another slot.
signal picked(slot: int)

## A drag shorter than this keeps the default direction rather than spinning on a twitch.
const DRAG_MIN := 0.5
const COL_EDGE := Color(1.0, 0.86, 0.35, 0.7)
const COL_INNER := Color(1.0, 0.45, 0.2, 0.8)
const COL_FAINT := Color(1.0, 0.86, 0.35, 0.25)
const COL_BAD := Color(0.9, 0.2, 0.15, 0.7)
## Which way a drag power points when the player barely moved the mouse.
const DEFAULT_DIR := Vector2(1, 0)

## What each power covers, taken from the effect's own constants (the comment names them). Milestone 5 may
## repaint these; it must not invent numbers for them.
const AREAS := {
	# LINE_LENGTH, LINE_HALF_WIDTH, FISSURE_LENGTH
	"heaven": {"shape": "lane", "length": 10.0, "half": 0.7, "fissure": 5.6},
	# PULL_RADIUS, CORE_RADIUS, WANDER_RADIUS
	"tornado": {"shape": "circle", "r": 3.2, "inner": 0.6, "roam": 7.0},
	# CONE_RADIUS, SWEEP_ARC (the dragon is locked to screen down-right, so this cone does not follow the mouse)
	"dragon": {"shape": "cone", "r": 11.0, "arc": 1.0},
	# LENGTH, WIDTH * 0.5
	"tsunami": {"shape": "lane", "length": 6.5, "half": 4.0},
	# RADIUS, KILL_R
	"gravity": {"shape": "circle", "r": 4.5, "inner": 1.5},
	# LENGTH, KILL_HALF_WIDTH
	"laser": {"shape": "lane", "length": 10.0, "half": 2.6},
	# RADIUS
	"orbital": {"shape": "circle", "r": 4.5},
	# RADIUS, VOLCANO_RADIUS
	"cinder": {"shape": "circle", "r": 5.8, "inner": 2.4},
	# RADIUS
	"judgement": {"shape": "circle", "r": 5.2},
	# RADIUS, SPIKE_RADIUS
	"glacial": {"shape": "circle", "r": 5.0, "inner": 4.5},
	# RADIUS, KILL_CORE
	"nova": {"shape": "circle", "r": 5.0, "inner": 1.2},
}

var slot := 0
## A drag power has the button down and is being aimed.
var aiming := false

var _rules: Rules
var _crowd: Crowd
## Where the button went down (a cast lands here, not where it came up).
var _press := Vector2.ZERO
## Where the cursor is now, for the preview and the drag's direction.
var _at := Vector2.ZERO


func setup(rules: Rules, crowd: Crowd) -> Targeting:
	_rules = rules
	_crowd = crowd
	_rules.cast_made.connect(_on_cast_made)
	z_index = 5
	z_as_relative = false  # absolute z 5: over the ground and the world, under the overhead layer at 8.
	return self


func pick(new_slot: int) -> void:
	if new_slot == slot:
		return
	slot = new_slot
	aiming = false
	picked.emit(slot)
	queue_redraw()


## The cursor moved. Keeps the preview where the player is looking.
func hover(ground: Vector2) -> void:
	_at = ground
	if not aiming:
		_press = ground
	queue_redraw()


func press(ground: Vector2) -> void:
	_press = ground
	_at = ground
	aiming = _is_drag()
	queue_redraw()


## The button came up: cast. A click power fires from where it went down; a drag power fires from there along
## the way it was dragged.
func release(ground: Vector2) -> void:
	_at = ground
	var extra := {}
	if _is_drag():
		extra["dir"] = aim_dir()
	aiming = false
	_rules.cast(slot, _press, extra)
	queue_redraw()


func cancel() -> void:
	aiming = false
	queue_redraw()


## Which way a drag power points: the drag itself, or DEFAULT_DIR when the player hardly moved.
func aim_dir() -> Vector2:
	var drag := _at - _press
	return drag.normalized() if drag.length() >= DRAG_MIN else DEFAULT_DIR


func area() -> Dictionary:
	return AREAS.get(_rules.key(slot), {})


func _is_drag() -> bool:
	return String(_rules.power(slot).get("aim", "click")) == "drag"


func _on_cast_made(_slot: int, key: String, at: Vector2) -> void:
	var a: Dictionary = AREAS.get(key, {})
	if String(a.get("shape", "")) == "lane":
		_crowd.on_cast(at, aim_dir(), float(a.length))
	else:
		_crowd.on_cast(at)


func _draw() -> void:
	var a := area()
	if a.is_empty():
		return
	# A power that cannot be cast still shows its area, in red, so the player can aim while it comes back.
	var edge := COL_EDGE if _rules.refusal(slot) == "" else COL_BAD
	match String(a.shape):
		"circle":
			_ring(_press, float(a.r), edge)
			if a.has("inner"):
				_ring(_press, float(a.inner), COL_INNER)
			if a.has("roam"):
				_ring(_press, float(a.roam), COL_FAINT)
		"lane":
			_lane(_press, aim_dir(), float(a.length), float(a.half), edge)
			if a.has("fissure"):
				for i in 8:
					var out := Vector2.RIGHT.rotated(TAU * float(i) / 8.0) * float(a.fissure) * 0.5
					draw_line(_press, _press + out, COL_FAINT, -1.0)
		"cone":
			_cone(_press, float(a.r), float(a.arc), edge)


func _ring(at: Vector2, r: float, col: Color) -> void:
	draw_arc(at, r, 0.0, TAU, 48, col, -1.0)


func _lane(from: Vector2, dir: Vector2, length: float, half: float, col: Color) -> void:
	var side := Vector2(-dir.y, dir.x) * half
	var a := from + side
	var b := from + dir * length + side
	var c := from + dir * length - side
	var d := from - side
	draw_polyline(PackedVector2Array([a, b, c, d, a]), col, -1.0)
	draw_line(from, from + dir * length, COL_FAINT, -1.0)


func _cone(from: Vector2, r: float, arc: float, col: Color) -> void:
	# The dragon's own start angle: its facing, biased 8 degrees to its right so the jet misses its body.
	var start := Vector2(1, 0).angle() - arc * 0.5 - deg_to_rad(8.0)
	var points := PackedVector2Array([from])
	for i in 17:
		points.append(from + Vector2.RIGHT.rotated(start + arc * float(i) / 16.0) * r)
	points.append(from)
	draw_polyline(points, col, -1.0)
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `bash tools/test.sh`
Expected: `checks=474 failures=0`.

Then check the behaviour gate, because `Crowd.on_cast()` changed:

```bash
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tools/dev/state_digest.gd
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --crowd-test 2>&1 | grep -E "CROWD result|ERROR"
```

Expected: the digest exactly as in the Global Constraints, one `CROWD result ...` line and no `ERROR` lines. The crowd test's numbers may move a little — it casts a tsunami, whose lane now frightens more people — so report the line rather than matching it.

- [ ] **Step 6: Commit**

```bash
git add src/game/targeting.gd src/game/targeting.gd.uid src/game/crowd/crowd.gd tests/test_targeting.gd tests/test_targeting.gd.uid tests/run_all.gd
git commit -m "feat: aiming, area previews and lane fright" -m "Targeting shows the picked power's area on the ground from the effect's own constants (a circle, a lane or the dragon's locked cone, red while the power cannot be paid for), turns a click or a drag into a cast through Rules, and frightens the crowd where the cast lands. A lane power now panics the people along its whole lane instead of only at the point the player pressed." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---
### Task 6: The HUD

**Files:**
- Create: `src/game/ui/ui_theme.gd`
- Create: `src/game/ui/hud.gd`
- Modify: `src/game/rules.gd` (one line: `stat_lines()` uses `UiTheme.clock()`)
- Create: `tests/test_hud.gd`
- Modify: `tests/run_all.gd`

**Why:** the player cannot play what they cannot read: how long is left, what the Citadel has left, how close the city is to falling, how many people got away, and which of the four powers they can afford. The theme is split out because milestone 4's Title, Prepare and Results screens use the same font, palette and gold frame.

The HUD **reads only**. It never casts, never spends, never changes a number — everything it draws comes from `Rules`, `Crowd` and `Citadel`. That is what keeps it safe to redraw whenever it likes, and what makes the text functions testable without a screen.

**Interfaces:**
- Consumes: `Rules` (`dp`, `time_left`, `stability`, `buildings_down`, `cooldown_left`, `refusal`, `cost`, `key`, `banner`, `dp_gained`, `over`), `Crowd` (`alive_citizens()`, `alive_soldiers()`, `escaped_count`, `alarm`), `Citadel.fraction()`, `PowerBook.hud_icon(key)`, `Targeting.slot`.
- Produces:
  - `UiTheme`: `font() -> FontFile`, `clock(seconds: float) -> String`, `frame(on: CanvasItem, rect: Rect2, bright := true) -> void`, and the colour constants.
  - `Hud.new().setup(rules: Rules, crowd: Crowd, town: Town, aim: Targeting) -> Hud` (add it to `Battlefield.hud_layer`), `objective_text() -> String`, `status_text() -> String`, `slot_state(slot: int) -> String` (`"picked"`, `"ready"`, `"cooldown"`, `"dp"`), `push_banner(text: String) -> void`, `banners() -> PackedStringArray`, `flashing(slot: int) -> bool`, `advance(delta: float) -> void`.

- [ ] **Step 1: Write the failing test**

Create `tests/test_hud.gd`:

```gdscript
extends RefCounted
## The HUD's words and states: the clock's format, the objective and status lines, what each slot says about
## itself, and the banner queue. The look itself is judged from captures, not from here.


static func run(t) -> void:
	t.check(UiTheme.clock(240.0) == "4:00", "four minutes reads 4:00 (%s)" % UiTheme.clock(240.0))
	t.check(UiTheme.clock(29.4) == "0:30", "a part-second rounds up, so the clock never sits on 0:00 early (%s)" % UiTheme.clock(29.4))
	t.check(UiTheme.clock(0.0) == "0:00" and UiTheme.clock(-3.0) == "0:00", "and it floors at 0:00")
	var f := UiTheme.font()
	t.check(f != null and f.antialiasing == TextServer.FONT_ANTIALIASING_NONE, "the pixel font has no smoothing")

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
	var rules := Rules.new().setup(PackedStringArray(["heaven", "tsunami", "cinder", "nova"]), null, env, field,
		crowd, town)
	rules.caster = func(_script: GDScript, _ground: Vector2, _extra: Dictionary) -> FxTimeline:
		return null
	var aim := Targeting.new().setup(rules, crowd)
	var hud := Hud.new().setup(rules, crowd, town, aim)

	t.check(hud.objective_text().contains("Royal Citadel") and hud.objective_text().contains("100%"),
		"the objective names the Citadel and what is left of it (%s)" % hud.objective_text())
	t.check(hud.status_text().contains("110") and hud.status_text().contains("50"),
		"the status line counts the living (%s)" % hud.status_text())

	# A slot says which of the four things it is.
	t.check(hud.slot_state(0) == "picked", "the picked slot says so (%s)" % hud.slot_state(0))
	t.check(hud.slot_state(3) == "ready", "a slot that can be paid for is ready (%s)" % hud.slot_state(3))
	rules.cast(3, Vector2.ZERO)
	t.check(hud.slot_state(3) == "cooldown", "one that just fired is on cooldown (%s)" % hud.slot_state(3))
	rules.dp = 15.0   # the Barrage (slot index 2) costs 25
	t.check(hud.slot_state(2) == "dp", "and one the player cannot afford says so (%s, %.1f DP)" % [hud.slot_state(2), rules.dp])

	# A refused cast flashes its own slot red (the buzz that goes with it is milestone 5's).
	rules.cast(2, Vector2.ZERO)
	t.check(hud.flashing(2) and not hud.flashing(1), "a refused cast flashes its slot (%s)" % hud.flashing(2))
	hud.advance(Hud.FLASH_SECONDS + 0.1)
	t.check(not hud.flashing(2), "and the flash fades")

	# Banners queue up, show for their time and go.
	rules.banner.emit("CHAIN!")
	t.check(hud.banners().size() == 1 and hud.banners()[0] == "CHAIN!", "a banner from the rules is shown (%s)" % [hud.banners()])
	rules.banner.emit("THE BRIDGE HAS FALLEN")
	t.check(hud.banners().size() == 2, "and they queue rather than replace (%d)" % hud.banners().size())
	hud.advance(Hud.BANNER_SECONDS + 0.1)
	t.check(hud.banners().size() == 1, "the first one goes when its time is up (%d)" % hud.banners().size())
	hud.advance(Hud.BANNER_SECONDS + 0.1)
	t.check(hud.banners().is_empty(), "and so does the last (%d)" % hud.banners().size())

	hud.free()
	aim.free()
	rules.free()
	crowd.clear()
	field.clear()
	field.free()
	env.clear()
	env.free()
	town.free()
	crowd.free()
	world.free()
```

- [ ] **Step 2: Register it and run it to see it fail**

In `tests/run_all.gd`, add `"res://tests/test_hud.gd",` to `SUITES` after `"res://tests/test_targeting.gd",`.

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_hud.gd` and `checks=475 failures=1`.

- [ ] **Step 3: Write the theme**

Create `src/game/ui/ui_theme.gd`:

```gdscript
class_name UiTheme
extends RefCounted
## The game's pixel UI look, in one place: the font, the palette, the shared gold icon frame and the clock's
## format. Milestone 4's Title, Prepare and Results screens use the same ones.

const FONT_PATH := "res://assets/fonts/PixelifySans-Variable.ttf"

const COL_TEXT := Color("e8e2d0")
const COL_DIM := Color("9a9484")
const COL_GOLD := Color("d8b23a")
const COL_GOLD_DARK := Color("7a5f18")
const COL_PANEL := Color(0.04, 0.04, 0.06, 0.66)
const COL_BAD := Color("c8342a")
const COL_DP := Color("6fd0ff")
const COL_DP_LOW := Color("ffb040")
const COL_SHADOW := Color(0, 0, 0, 0.75)
## The five stability colours in the spec's order: population, infrastructure, leadership, military, resources.
const STABILITY_COLS := [Color("7fc46a"), Color("c8a05a"), Color("d8b23a"), Color("c05a4a"), Color("6fa8c8")]

const SIZE_SMALL := 8
const SIZE_BODY := 10
const SIZE_BIG := 16

static var _font: FontFile


## The pixel font with every smoothing trick off: on a 640x360 screen a blurred glyph is a broken glyph.
static func font() -> FontFile:
	if _font == null:
		_font = load(FONT_PATH)
		_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		_font.hinting = TextServer.HINTING_NONE
		_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return _font


## m:ss, the way the mission clock reads. Rounded up, so it shows 0:01 until the last moment and 0:00 only
## when the manifestation is actually over.
static func clock(seconds: float) -> String:
	var whole := int(ceilf(maxf(0.0, seconds)))
	return "%d:%02d" % [whole / 60, whole % 60]


## Text with a hard black shadow one pixel down-right, which is how every label in this game is drawn.
static func text(on: CanvasItem, at: Vector2, s: String, size := SIZE_BODY, col := COL_TEXT) -> void:
	on.draw_string(font(), at + Vector2.ONE, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, COL_SHADOW)
	on.draw_string(font(), at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## How wide that text will be, for right-aligned and centred lines.
static func width(s: String, size := SIZE_BODY) -> float:
	return font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## The one gold frame every icon in the game wears: a bevel, four corner studs and a small diamond on top.
static func frame(on: CanvasItem, rect: Rect2, bright := true) -> void:
	var gold := COL_GOLD if bright else COL_GOLD_DARK
	var dark := COL_GOLD_DARK if bright else Color(0.2, 0.16, 0.08, 1.0)
	on.draw_rect(rect.grow(1.0), dark, false, -1.0)
	on.draw_rect(rect, gold, false, -1.0)
	for corner in [rect.position, Vector2(rect.end.x - 1.0, rect.position.y),
			Vector2(rect.position.x, rect.end.y - 1.0), rect.end - Vector2.ONE]:
		on.draw_rect(Rect2(corner, Vector2.ONE), gold)
	var top := Vector2(rect.get_center().x, rect.position.y - 2.0)
	on.draw_colored_polygon(PackedVector2Array([top + Vector2(0, -2), top + Vector2(2, 0), top + Vector2(0, 2),
		top + Vector2(-2, 0)]), gold)
```

- [ ] **Step 4: Write the HUD**

Create `src/game/ui/hud.gd`:

```gdscript
class_name Hud
extends Control
## The in-mission HUD (spec §5): the clock above, the objectives to the left, the city's state to the right,
## banners across the middle, and the Divine Power bar with the four slots below. It reads Rules, Crowd and
## the Citadel and changes nothing; it redraws only when what it shows has changed.

## How long one banner stays up.
const BANNER_SECONDS := 2.2
## A +DP popup drifts up for this long.
const POPUP_SECONDS := 1.2
## A slot that refused a cast stays red for this long (spec §1; the buzz that goes with it is milestone 5's).
const FLASH_SECONDS := 0.35
## The clock turns red and pulses under this many seconds (spec §5).
const HURRY_AT := 30.0

const SLOT_SIZE := 42.0
const SLOT_GAP := 6.0
const STABILITY_BAR := Vector2(96.0, 5.0)
const DP_BAR := Vector2(180.0, 7.0)

var _rules: Rules
var _crowd: Crowd
var _town: Town
var _aim: Targeting
## Banners waiting their turn: [text, seconds shown].
var _banners: Array = []
## Floating gains: [text, screen position, seconds shown].
var _popups: Array = []
## Seconds of red left per slot, for the refused-cast flash.
var _flash := PackedFloat32Array()
## What the last frame drew, so an unchanged HUD costs nothing.
var _drawn := ""


func setup(rules: Rules, crowd: Crowd, town: Town, aim: Targeting) -> Hud:
	_rules = rules
	_crowd = crowd
	_town = town
	_aim = aim
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # the player is aiming at the town, not clicking the HUD
	_flash.resize(_rules.loadout.size())
	_flash.fill(0.0)
	_rules.banner.connect(push_banner)
	_rules.dp_gained.connect(_on_dp_gained)
	_rules.cast_refused.connect(_on_cast_refused)
	return self


func _process(delta: float) -> void:
	advance(delta)


## Age the banners and popups, and redraw when anything on screen has changed.
func advance(delta: float) -> void:
	for b in _banners:
		b[1] += delta
	while not _banners.is_empty() and float(_banners[0][1]) >= BANNER_SECONDS:
		_banners.pop_front()
	for p in _popups:
		p[2] += delta
	var kept: Array = []
	for p in _popups:
		if float(p[2]) < POPUP_SECONDS:
			kept.append(p)
	_popups = kept
	var flashing := false
	for i in _flash.size():
		_flash[i] = maxf(0.0, _flash[i] - delta)
		flashing = flashing or _flash[i] > 0.0
	# Banners fade, popups drift, a refused slot burns red and the last half minute pulses: while any of those
	# is on screen the HUD is an animation and redraws every frame. The rest of the time it is a still picture.
	if flashing or not _banners.is_empty() or not _popups.is_empty() or _rules.time_left <= HURRY_AT:
		_drawn = ""
		queue_redraw()
		return
	var now := _signature()
	if now != _drawn:
		_drawn = now
		queue_redraw()


## "Destroy the Royal Citadel - 60% left", the spec's objective line.
func objective_text() -> String:
	var left := 0.0
	if is_instance_valid(_town) and is_instance_valid(_town.citadel):
		left = _town.citadel.fraction()
	return "Destroy the Royal Citadel - %d%% left" % roundi(left * 100.0)


## The city's state, top right.
func status_text() -> String:
	return "Citizens %d   Soldiers %d   Buildings down %d   Alarm %d%%" % [_crowd.alive_citizens(),
		_crowd.alive_soldiers(), _rules.buildings_down, roundi(_crowd.alarm)]


## What a slot is: the one the player has picked, ready to cast, waiting out a cooldown, or unaffordable.
func slot_state(slot: int) -> String:
	if _aim != null and _aim.slot == slot:
		return "picked"
	var reason := _rules.refusal(slot)
	return "ready" if reason == "" else reason


func push_banner(text: String) -> void:
	_banners.append([text, 0.0])


func banners() -> PackedStringArray:
	var out := PackedStringArray()
	for b in _banners:
		out.append(String(b[0]))
	return out


## Is this slot still red from a cast it could not take?
func flashing(slot: int) -> bool:
	return slot >= 0 and slot < _flash.size() and _flash[slot] > 0.0


func _on_cast_refused(slot: int, _reason: String) -> void:
	if slot >= 0 and slot < _flash.size():
		_flash[slot] = FLASH_SECONDS


func _on_dp_gained(amount: float, at: Vector2) -> void:
	_popups.append(["+%.1f" % amount, Iso.ground_to_screen(at), 0.0])


## Everything the HUD shows, as one string. Cheap to build, and it means a still frame is not redrawn sixty
## times a second while a four-minute mission's effects are already busy.
func _signature() -> String:
	var out := "%s|%s|%s|%d|%d" % [UiTheme.clock(_rules.time_left), objective_text(), status_text(),
		roundi(_rules.dp * 2.0), roundi(_rules.stability.total() * 200.0)]
	for i in _rules.loadout.size():
		out += "%s%d," % [slot_state(i), roundi(_rules.cooldown_left(i) * 4.0)]
	return out


func _draw() -> void:
	# Before the first layout pass a Control can still be 0 wide, and this one is centred on the screen.
	var w := size.x if size.x > 1.0 else get_viewport_rect().size.x
	_draw_clock(w)
	_draw_objectives()
	_draw_status(w)
	_draw_banners(w)
	_draw_dp(w)
	_draw_slots(w)
	_draw_popups()


func _draw_clock(w: float) -> void:
	var s := UiTheme.clock(_rules.time_left)
	var col := UiTheme.COL_TEXT
	if _rules.time_left <= HURRY_AT:
		# One pulse a second, so the last half minute is felt without a tween.
		col = UiTheme.COL_BAD if fmod(_rules.time_left, 1.0) > 0.5 else Color("ff8a72")
	UiTheme.text(self, Vector2(roundf((w - UiTheme.width(s, UiTheme.SIZE_BIG)) * 0.5), 18.0), s, UiTheme.SIZE_BIG, col)


func _draw_objectives() -> void:
	draw_rect(Rect2(2.0, 2.0, 172.0, 40.0), UiTheme.COL_PANEL)
	UiTheme.text(self, Vector2(6.0, 13.0), objective_text(), UiTheme.SIZE_SMALL)
	# The five-colour stability bar: one segment per part, each as wide as its weight.
	var at := Vector2(6.0, 18.0)
	var parts := [[_rules.stability.population, Stability.W_POPULATION],
		[_rules.stability.infrastructure, Stability.W_INFRASTRUCTURE],
		[_rules.stability.leadership, Stability.W_LEADERSHIP],
		[_rules.stability.military, Stability.W_MILITARY],
		[_rules.stability.resources, Stability.W_RESOURCES]]
	draw_rect(Rect2(at, STABILITY_BAR), Color(0, 0, 0, 0.6))
	var x := at.x
	for i in parts.size():
		var part: Array = parts[i]
		var full := STABILITY_BAR.x * float(part[1])
		draw_rect(Rect2(Vector2(x, at.y), Vector2(full * float(part[0]), STABILITY_BAR.y)), UiTheme.STABILITY_COLS[i])
		x += full
	UiTheme.text(self, Vector2(at.x + STABILITY_BAR.x + 5.0, at.y + 5.0),
		"Stability %d%%" % roundi(_rules.stability.total() * 100.0), UiTheme.SIZE_SMALL)
	var escaped := "Escaped %d / %d" % [_crowd.escaped_count, Rules.ESCAPE_LIMIT]
	var col := UiTheme.COL_BAD if _crowd.escaped_count >= Rules.ESCAPE_LIMIT - 8 else UiTheme.COL_DIM
	UiTheme.text(self, Vector2(6.0, 36.0), escaped, UiTheme.SIZE_SMALL, col)


func _draw_status(w: float) -> void:
	var s := status_text()
	UiTheme.text(self, Vector2(w - UiTheme.width(s, UiTheme.SIZE_SMALL) - 6.0, 13.0), s, UiTheme.SIZE_SMALL,
		UiTheme.COL_DIM)


func _draw_banners(w: float) -> void:
	if _banners.is_empty():
		return
	var text := String(_banners[0][0])
	var age := float(_banners[0][1])
	var fade := clampf((BANNER_SECONDS - age) / 0.4, 0.0, 1.0)
	var col := UiTheme.COL_GOLD
	col.a = fade
	var x := roundf((w - UiTheme.width(text, UiTheme.SIZE_BIG)) * 0.5)
	UiTheme.text(self, Vector2(x, 128.0), text, UiTheme.SIZE_BIG, col)


func _draw_dp(w: float) -> void:
	var at := Vector2(roundf((w - DP_BAR.x) * 0.5), 300.0)
	draw_rect(Rect2(at - Vector2.ONE, DP_BAR + Vector2(2.0, 2.0)), Color(0, 0, 0, 0.7))
	var frac := clampf(_rules.dp / Rules.DP_MAX, 0.0, 1.0)
	var col := UiTheme.COL_DP if _rules.dp >= 20.0 else UiTheme.COL_DP_LOW
	draw_rect(Rect2(at, Vector2(DP_BAR.x * frac, DP_BAR.y)), col)
	UiTheme.text(self, Vector2(at.x + DP_BAR.x + 5.0, at.y + DP_BAR.y), "%d DP" % roundi(_rules.dp),
		UiTheme.SIZE_SMALL)


func _draw_slots(w: float) -> void:
	var count := _rules.loadout.size()
	var total := float(count) * SLOT_SIZE + float(maxi(count - 1, 0)) * SLOT_GAP
	var at := Vector2(roundf((w - total) * 0.5), 312.0)
	for i in count:
		var box := Rect2(at + Vector2(float(i) * (SLOT_SIZE + SLOT_GAP), 0.0), Vector2(SLOT_SIZE, SLOT_SIZE))
		var state := slot_state(i)
		draw_rect(box, UiTheme.COL_PANEL)
		if flashing(i):
			var red := UiTheme.COL_BAD
			red.a = _flash[i] / FLASH_SECONDS
			draw_rect(box, red)
		var icon := PowerBook.hud_icon(_rules.key(i))
		if icon != null:
			# Greyed while it cannot be cast, so the player reads the row at a glance.
			draw_texture_rect(icon, box, false, Color(0.45, 0.45, 0.5) if state in ["cooldown", "dp"] else Color.WHITE)
		UiTheme.frame(self, box, state == "picked" or state == "ready")
		UiTheme.text(self, box.position + Vector2(2.0, 9.0), "%d" % (i + 1), UiTheme.SIZE_SMALL)
		var cost := "%d" % _rules.cost(i)
		UiTheme.text(self, box.position + Vector2(SLOT_SIZE - UiTheme.width(cost, UiTheme.SIZE_SMALL) - 2.0,
			SLOT_SIZE - 2.0), cost, UiTheme.SIZE_SMALL,
			UiTheme.COL_BAD if state == "dp" else UiTheme.COL_TEXT)
		if state == "cooldown":
			# The cooldown as a shade falling away from the top, with its seconds over it.
			var left := _rules.cooldown_left(i)
			var frac := clampf(left / maxf(float(_rules.power(i).cooldown), 0.001), 0.0, 1.0)
			draw_rect(Rect2(box.position, Vector2(SLOT_SIZE, SLOT_SIZE * frac)), Color(0, 0, 0, 0.6))
			var secs := "%d" % ceili(left)
			UiTheme.text(self, box.get_center() + Vector2(-UiTheme.width(secs) * 0.5, 4.0), secs, UiTheme.SIZE_BODY)


func _draw_popups() -> void:
	for p in _popups:
		var age := float(p[2])
		var col := UiTheme.COL_DP
		col.a = clampf((POPUP_SECONDS - age) / 0.5, 0.0, 1.0)
		# The popup belongs to the place the DP came from, so its stored world pixel is put through the
		# camera's transform: the HUD's own layer does not move with the camera.
		var at: Vector2 = get_viewport().get_canvas_transform() * Vector2(p[1])
		UiTheme.text(self, at - Vector2(0.0, age * 14.0), String(p[0]), UiTheme.SIZE_SMALL, col)
```

- [ ] **Step 5: Swap the placeholder clock in Rules**

In `src/game/rules.gd`'s `stat_lines()`, replace the hand-rolled `"%d:%02d"` time value with `UiTheme.clock(time_left)`.

- [ ] **Step 6: Run the test to verify it passes**

Run: `bash tools/test.sh`
Expected: `checks=490 failures=0`.

`Hud` is a `Control`, so the suite must `free()` it (the test does). If `UiTheme.font()` returns null in the headless run, the font's `.import` is missing from the working tree — check `assets/fonts/PixelifySans-Variable.ttf.import` is present rather than working around it in code.

- [ ] **Step 7: Commit**

```bash
git add src/game/ui/ui_theme.gd src/game/ui/ui_theme.gd.uid src/game/ui/hud.gd src/game/ui/hud.gd.uid src/game/rules.gd tests/test_hud.gd tests/test_hud.gd.uid tests/run_all.gd
git commit -m "feat: the in-mission HUD" -m "UiTheme holds the pixel font with its smoothing off, the palette, the gold icon frame and the m:ss clock, ready for milestone 4's screens. The HUD draws the clock (red and pulsing under thirty seconds), the objective with the Citadel's health, the five-colour stability bar, the escape count, the city's status, centre banners, and the Divine Power bar with the four slots: hotkey, icon, cost, a falling cooldown shade and its seconds, greyed when it cannot be cast. It reads the rules and never writes to them, and it only redraws when what it shows has changed." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 7: The mission

**Files:**
- Create: `src/game/mission.gd`
- Create: `scenes/mission.tscn`
- Create: `play.bat`
- Modify: `README.md`

**Why:** the pieces become a game. This is the scene the user plays and the one the milestone is judged in, and it is where the scripted run that proves the whole loop lives.

**Interfaces:**
- Consumes: everything above, plus `Battlefield` (`reset`, `ctx`, `camera`, `ground_plane`, `hud_layer`, `mouse_ground`, `arg_value`, `key_pan_dir`, `save_capture`, `bench`, `quit`), `Town`, `WalkGrid`, `Crowd`, `TownLayout.MAP`.
- Produces: the playable scene; `--mission-test` and `--bench` scripted runs; `--loadout=heaven,tsunami,cinder,nova`, `--people=N` and `--seed=N` command-line overrides.

- [ ] **Step 1: Write the mission**

Create `src/game/mission.gd`:

```gdscript
extends Node2D
## One mission of Kingdoms Amid Kataclysm: the battlefield, the town of Aldermere, its people, the rules, the
## aiming and the HUD. The player picks a power with 1-4, clicks or drags to cast it, pans with WASD or the
## middle button and zooms with the wheel. R starts a fresh mission. Milestone 4 puts the Title, Prepare,
## Pause and Results screens around this.

## The four powers a mission starts with until the Prepare screen exists (milestone 4). Override on the
## command line: -- --loadout=heaven,gravity,judgement,nova
const DEFAULT_LOADOUT := ["heaven", "tsunami", "cinder", "nova"]
const PEOPLE := Crowd.CITIZENS + Crowd.SOLDIERS
const PAN_SPEED := 320.0
const PAN_MIN := Vector2(-760, -380)
const PAN_MAX := Vector2(760, 520)
const ZOOM_MIN := 0.5
const ZOOM_MAX := 1.6
const SLOT_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4]
## Grass, the same clear colour the debug scene uses.
const CLEAR := Color("4a6a2a")

## The scripted run: [seconds, slot, ground, drag direction or Vector2.ZERO].
const TEST_CASTS := [
	[1.0, 0, Vector2(-1.0, -6.0), Vector2(0.2, 1.0)],
	[6.0, 2, Vector2(2.6, 2.2), Vector2.ZERO],
	[14.0, 1, Vector2(-7.0, 1.0), Vector2(1.0, 0.1)],
	[24.0, 3, TownLayout.CITADEL_ORIGIN, Vector2.ZERO],
]
const TEST_SHOTS := [0.5, 2.0, 8.0, 16.0, 26.0, 30.0]
const TEST_END := 34.0

var _bf: Battlefield
var _town: Town
var _grid: WalkGrid
var _crowd: Crowd
var _rules: Rules
var _aim: Targeting
var _hud: Hud
var _pressing := false


func _ready() -> void:
	RenderingServer.set_default_clear_color(CLEAR)
	_bf = Battlefield.new()
	_bf.name = "Battlefield"
	add_child(_bf)
	_bf.ctx.impact.dim_scale = 0.4
	_bf.ctx.field.bounds = TownLayout.MAP
	# Connected here and not in _start(): the field outlives a restart, so connecting per mission would stack
	# up a handler for every mission the player has played.
	_bf.ctx.env.structure_destroyed.connect(_on_structure_destroyed)
	var args := OS.get_cmdline_user_args()
	var scripted := "--mission-test" in args or "--bench" in args
	var seed_arg := Battlefield.arg_value(args, "--seed")
	var seed_value := int(seed_arg) if seed_arg != "" else (7 if scripted else Time.get_ticks_usec())
	_start(seed_value)
	_bf.camera.zoom = Vector2.ONE * 0.75
	_bf.camera.position = Iso.ground_to_screen(Vector2(0, -2)).round()
	await FxParts.prewarm(_bf.ctx.distort)
	if "--mission-test" in args:
		_mission_test()
	elif "--bench" in args:
		_bf.bench("mission")
		_bf.quit()


## A fresh mission: clear the world, build the town, spawn the people, hand out 100 DP and four minutes.
func _start(seed_value: int) -> void:
	_bf.reset(seed_value)
	for n: Node in [_town, _crowd, _rules, _aim, _hud]:
		if is_instance_valid(n):
			if n is Town:
				(n as Town).teardown()
			elif n is Crowd:
				(n as Crowd).clear()
			# Parents may be mid-teardown here, so never free a tree-resident node immediately.
			if n.is_inside_tree():
				n.queue_free()
			else:
				n.free()
	_town = Town.new()
	_town.name = "Town"
	add_child(_town)
	_town.build(_bf.ctx.env, _bf.ground_plane, _bf.camera)
	_grid = WalkGrid.new().setup(_bf.ctx.env, _town)
	_crowd = Crowd.new()
	_crowd.name = "Crowd"
	add_child(_crowd)
	_crowd.setup(_bf.ctx.field, _bf.ctx.env, _town, _grid, _bf.ctx.world, seed_value)
	var args := OS.get_cmdline_user_args()
	var wanted := Battlefield.arg_value(args, "--people")
	var people := int(wanted) if wanted != "" else PEOPLE
	var citizens := roundi(float(people) * float(Crowd.CITIZENS) / float(PEOPLE))
	_crowd.spawn(citizens, people - citizens)

	_rules = Rules.new()
	_rules.name = "Rules"
	add_child(_rules)
	_rules.setup(_loadout(args), _bf.ctx, _bf.ctx.env, _bf.ctx.field, _crowd, _town)
	_rules.over.connect(_on_over)
	_crowd.rallied.connect(func(): _rules.banner.emit("SOLDIERS RALLY"))

	_aim = Targeting.new()
	_aim.name = "Targeting"
	_bf.ground_plane.add_child(_aim)
	_aim.setup(_rules, _crowd)

	_hud = Hud.new()
	_hud.name = "Hud"
	_bf.hud_layer.add_child(_hud)
	_hud.setup(_rules, _crowd, _town, _aim)


## The drafted loadout: the command line's, or the default four.
func _loadout(args: PackedStringArray) -> PackedStringArray:
	var wanted := Battlefield.arg_value(args, "--loadout")
	var keys := PackedStringArray(DEFAULT_LOADOUT)
	if wanted != "":
		keys = PackedStringArray()
		for key in wanted.split(","):
			if PowerBook.get_power(key).is_empty():
				push_warning("Unknown power in --loadout: " + key)
			else:
				keys.append(key)
	return keys


func _on_structure_destroyed(s: Structure, _kind: StringName) -> void:
	if is_instance_valid(_town) and is_instance_valid(_rules) and s == _town.bridge:
		_rules.banner.emit("THE BRIDGE HAS FALLEN")


func _on_over(won: bool, reason: String) -> void:
	var title := "THE CITY HAS FALLEN"
	if not won:
		title = "THE PEOPLE ESCAPED" if reason == "escapes" else "MANIFESTATION ENDED"
	_rules.banner.emit(title)
	# Milestone 4 turns this into the Results screen; until then the numbers go to the console.
	print("MISSION result won=%s reason=%s score=%d rank=%s" % [won, reason, _rules.score(), _rules.rank()])
	for line: Dictionary in _rules.stat_lines():
		print("  %-22s %8s %6d" % [line.label, line.value, line.points])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var i := SLOT_KEYS.find(event.physical_keycode)
		if i >= 0 and i < _rules.loadout.size():
			_aim.pick(i)
		elif event.physical_keycode == KEY_R:
			_start(Time.get_ticks_usec())
		elif event.physical_keycode == KEY_ESCAPE:
			# Aiming first: Esc cancels a drag, and only quits when there is nothing to cancel (Pause is
			# milestone 4's).
			if _aim.aiming:
				_aim.cancel()
			else:
				_bf.quit()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		_pan(-event.relative / _bf.camera.zoom.x)
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var z := _bf.camera.zoom.x * (1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.1)
		_bf.camera.zoom = Vector2.ONE * clampf(z, ZOOM_MIN, ZOOM_MAX)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_aim.cancel()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressing = true
			_aim.press(_bf.mouse_ground())
		elif _pressing:
			_pressing = false
			_aim.release(_bf.mouse_ground())


func _process(delta: float) -> void:
	var pan := Battlefield.key_pan_dir()
	if pan != Vector2.ZERO:
		# Pan in real time regardless of hit-stop, faster when zoomed out.
		var real_delta := delta / maxf(Engine.time_scale, 0.001)
		_pan(pan.normalized() * PAN_SPEED * real_delta / _bf.camera.zoom.x)
	_aim.hover(_bf.mouse_ground())


func _pan(by: Vector2) -> void:
	_bf.camera.position = (_bf.camera.position + by).clamp(PAN_MIN, PAN_MAX)


## A fixed mission: four casts on a timetable, screenshots at the interesting moments, and one result line.
func _mission_test() -> void:
	var casts := TEST_CASTS.duplicate()
	var shots := TEST_SHOTS.duplicate()
	var t := 0.0
	while t < TEST_END:
		await get_tree().process_frame
		t += get_process_delta_time()
		while not casts.is_empty() and t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			var slot := int(c[1])
			var extra := {}
			if (c[3] as Vector2) != Vector2.ZERO:
				extra["dir"] = (c[3] as Vector2).normalized()
			_rules.cast(slot, c[2], extra)
		while not shots.is_empty() and t >= float(shots[0]):
			var at: float = shots.pop_front()
			await _bf.save_capture("mission_%04d.png" % roundi(at * 100.0))
	print("MISSION test dp=%.1f buildings=%d citizens=%d escaped=%d alarm=%d stability=%d%% citadel=%d%%" % [
		_rules.dp, _rules.buildings_down, _crowd.alive_citizens(), _crowd.escaped_count, roundi(_crowd.alarm),
		roundi(_rules.stability.total() * 100.0), roundi(_town.citadel.fraction() * 100.0)])
	_bf.quit()
```

- [ ] **Step 2: Write the scene and the launcher**

Create `scenes/mission.tscn` — one node with the script on it, the same shape as `scenes/town_debug.tscn`:

```
[gd_scene format=3]

[ext_resource type="Script" path="res://src/game/mission.gd" id="1_mission"]

[node name="Mission" type="Node2D"]
script = ExtResource("1_mission")
```

Create `play.bat`, the same shape as `town.bat`:

```bat
@echo off
rem Play a mission of Kingdoms Amid Kataclysm. Override the engine path with: set GODOT=C:\path\to\Godot.exe
setlocal
if "%GODOT%"=="" set "GODOT=F:\Godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" (
	echo Godot not found at "%GODOT%".
	echo Set the GODOT environment variable to your Godot 4.7.2 executable.
	pause
	exit /b 1
)
start "" "%GODOT%" --path "%~dp0." --scene res://scenes/mission.tscn
```

- [ ] **Step 3: Run the scripted mission**

```bash
SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test 2>&1 | grep -E "MISSION|captured|ERROR|SCRIPT"
```

Expected: six `captured ...` lines, one `MISSION test ...` line, and **no** `ERROR` or `SCRIPT ERROR` lines. The mission will not end inside 34 s, so no `MISSION result` line is expected here.

Read the numbers: `dp` should be under 100 (four casts were paid for) but above 0 (destroyed towers and gates paid some back), `buildings` at least 20, `escaped` small, `alarm` at 100 by the end (a nova on the Citadel is worth 10 alarm on its own), `stability` well under 100, `citadel` under 100.

Then look at the frames: `captures/mission_0050.png`, `1600.png` and `3000.png`. Check each of these and say in your report what you see:
- the clock at the top, the objective and the five-colour stability bar top left, the city status top right;
- the four slots at the bottom with their icons in gold frames, the picked one brighter, a cooldown shade over one that just fired, and the DP bar above them;
- the aim preview ring or lane under the cursor (the scripted run does not move the mouse, so it sits at the map's centre — that is expected);
- banners when they fire.

- [ ] **Step 4: Check the rest still holds**

```bash
bash tools/test.sh
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tools/dev/state_digest.gd
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --crowd-test 2>&1 | grep -E "CROWD result|ERROR"
bash tools/dev/sandbox_baseline.sh captures/m3_task7
python tools/dev/compare_captures.py captures/m1_base_a captures/m3_task7 'idle.png'
```

Expected: `checks=490 failures=0`; the digest exactly as in the Global Constraints; one `CROWD result ...` line with no `ERROR`; `idle.png` `worst_mean_diff=0.000`.

- [ ] **Step 5: Measure the frame rate**

```bash
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/mission.tscn --audio-driver Dummy --disable-vsync --max-fps 0 -- --bench
```

Twice, and report the median with the numbers from `.git/sdd/m2-task-5-report.md` beside it. The HUD and the aim preview are new work in the frame; the gate is **no worse than 3 fps below** milestone 2's idle figure with the same crowd. If it is worse than that, the first suspect is the HUD redrawing every frame — check `_signature()` actually stops it.

- [ ] **Step 6: Update the README**

In `README.md`'s KAK section, replace the milestone line with milestone 3's, list the mission's controls, and add the new commands:

```bash
SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test   # scripted mission; logs MISSION test ...
```

Keep the check count line current (`checks=490 failures=0`) and mention `play.bat` as the way in.

- [ ] **Step 7: Commit**

```bash
git add src/game/mission.gd src/game/mission.gd.uid scenes/mission.tscn play.bat README.md
git commit -m "feat: a playable mission" -m "Mission composes the battlefield, Aldermere, its people, the rules, the aiming and the HUD into one four-minute run: pick a power with 1-4, click or drag to cast it, pan and zoom, R for a fresh mission. The loadout, the seed and the population can be set on the command line, --mission-test runs a fixed mission with screenshots, and the ending prints its score, rank and stat table until milestone 4 draws the Results screen." -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Milestone check

After Task 7, before the milestone is called done:

1. `bash tools/test.sh` — `checks=490 failures=0`, output pristine.
2. The digest line, exactly as in the Global Constraints.
3. `SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test` — one `MISSION test` line, no errors.
4. A **user playtest** of `play.bat`. Show the user the three frames from Task 7 and the bench number first, then hand over. The questions that matter: can they read the HUD at 640×360, does the DP economy let them cast often enough to be interesting, and is four minutes the right length? Their answers are milestone 5's tuning list, not this milestone's bugs.
5. Write down anything the playtest turns up that is not a defect into the milestone 5 notes rather than fixing it here.
