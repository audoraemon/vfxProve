# KAK v0.07 Soldiers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** give the town's 100 soldiers roles that help it survive:
- **Marshals** speed and steady the evacuation;
- **Escorts** guard the responders and take over their duties;
- **Rescue squads** dig survivors out of collapsed shelters and fight fires.

**Architecture:**
- Each soldier gets a `Person.corps` role at spawn, from its post. Role counts come from the difficulty profile (`ResponseProfile`).
- Three small managers on the crowd (`MarshalManager`, `EscortManager`, `RescueManager`) run the roles, like the existing `BellNetwork`, `BanishingRite`, `EngineerManager` and `RiverFerry`.
- Hooks into the existing systems: gate and boat intervals, the bell's keeper, engineer losses, shelter collapses, fires.

**Tech Stack:** Godot 4.7.2, GDScript; headless tests in `tests/run_all.gd`; scripted scenarios in `tools/dev/behaviour_check.gd`.

## Global Constraints

- **Spec:** `docs/superpowers/specs/2026-10-02-kak-v007-soldiers-design.md`. Baseline tag `kak-v0.06`.
- **Repository:** `F:\Godot\Git\vfxProve` (Git Bash path `/f/Godot/Git/vfxProve`), branch `feat/vfx-proof`. Work there directly, with no worktree.
- **Godot:** `G=/f/Godot/Godot_v4.7.2-stable_win64_console.exe`.
- **After adding a script with a new `class_name`:** run `timeout 180 $G --headless --editor --path . --import >/dev/null 2>&1` (it registers the class and writes the `.gd.uid` file).
- **Tests:** `timeout 600 $G --headless --path . --script res://tests/run_all.gd 2>&1 | grep -v '^\s*at:' | grep -n "FAIL\|SCRIPT ERROR\|Parse Error\|checks="`. Expected: `checks=N failures=0`; there must be no "SCRIPT ERROR" or "Parse Error" lines.
- **Test style:** a test file is `extends RefCounted` with `static func run(t) -> void:`, using `t.check(cond: bool, "message")` and `t.near(a, b, eps, "message")`. Register it in `tests/run_all.gd` by adding `"res://tests/<file>.gd",` to the list (after `"res://tests/test_plague.gd",`). Tests build a town and crowd like this:

```gdscript
static func _crowd(tier := ResponseProfile.Tier.ORGANIZED) -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(tier)
	crowd.spawn()
	return [crowd, env, world, field, grid, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[2] as Node).free()
```

  Tests drive time by calling managers' `step(delta)` directly. A person walks only when the engine steps it, so tests "arrive" a person by setting `p.ground_pos = p.goal(); p._goal = Vector2.INF; p._path = PackedVector2Array()`.
- **Code style:**
  - tabs; doc comments are `##` above declarations, written in full sentences;
  - constants in `UPPER_CASE` with a `##` comment;
  - match the surrounding code's density of comments.
- **Git:**
  - `git add` explicit paths only, including any new `.gd.uid` files;
  - never add `default_bus_layout.tres` (restore it with `git checkout -- default_bus_layout.tres` if it changed), anything under `captures/`, `.codex/`, `concepts/`, or `docs/HUM_Game_Design_Document_v1.docx`;
  - every commit message ends with a blank line, then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`;
  - **do not push or tag:** the controller does that per milestone.
- **Numbers (spec §1):**
  - Marshals: `REACH` 2.0, `SPEED` 0.15, `STEADY_R` 3.0, `STEADY_TIME` 3.0.
  - Escorts: `REACH` 1.5, `STEADY_R` 2.0, `STEADY_TIME` 3.0, bell climb ×1.5.
  - Rescue: `TRAPPED_SHARE` 0.6, `TRAPPED_LIFE` 45, `DIG_TIME` 3, `DIG_REACH` 1.2, squads of 3.
  - Tiers (`marshals_per_exit` / `escorts_per_duty` / `rescue_squads`): Unprepared 2/1/2, Organized 3/1/3, Prepared 4/2/4, God-Resistant 5/2/5.
- **Tuning latitude:** the plan's code was written against the code at `kak-v0.06` but has not been run. Where a test fails only because of the town's geometry (a standing spot that is not walkable, or ends up farther than a REACH), you may tune the *placement* constants (`FLANK`, `FLANK_STEP`, `BACK`, `OFFSETS`, `_spot_near` spreads). Do not change the spec's numbers listed below or weaken a test's intent. Report every deviation from the plan in your final message.
- **Soldiers never hurt the god.** They ignore Discord and Pestilence (both already skip soldiers) and do not panic (`Person.panic` already returns for soldiers).

---

## File structure

| File | Responsibility |
|---|---|
| `src/game/response_profile.gd` | `marshals_per_exit`, `escorts_per_duty`, `rescue_squads` per tier; one Defense Profile line |
| `src/game/crowd/person.gd` | `enum Corps`, `var corps`, `var post`; soldier looks by corps; `go_duty` and `assist` usable by soldiers |
| `src/game/crowd/crowd.gd` | `_assign_corps()`; the rally and hold-ground only for soldiers without a role; `off_duty` for soldiers; creating, stepping and clearing the three managers; hooks |
| `src/game/crowd/marshal_manager.gd` | **New.** Marshals |
| `src/game/crowd/escort_manager.gd` | **New.** Escorts |
| `src/game/crowd/rescue_manager.gd` | **New.** Rescue squads, the trapped |
| `src/game/crowd/river_ferry.gd` | Boarding interval divided by the dock's marshal speed |
| `src/game/crowd/bell_network.gd` | `replace_keeper()`, the `keeper_replaced` signal, and the takeover in `step()` |
| `src/game/crowd/engineer_manager.gd` | Team ids; an escort stand-in before a team is lost; soldiers accepted |
| `src/game/crowd/shelter_manager.gd` | The collapse branch hands the trapped to `RescueManager` |
| `src/game/crowd/fire_manager.gd` | `enlist(p, s)` |
| `src/game/mission.gd` | Banners |
| `src/game/ui/behaviour_overlay.gd` | F4 lines per role |
| `tools/dev/behaviour_check.gd` | The `soldiers` scenario |
| `tests/test_corps.gd`, `test_marshals.gd`, `test_escorts.gd`, `test_rescue.gd` | **New** tests |

---

## Milestone 1 — Corps

### Task 1: Roles in the profile, the allocation, the rally, the looks

**Files:**
- Modify: `src/game/response_profile.gd`, `src/game/crowd/person.gd`, `src/game/crowd/crowd.gd`, `tests/test_profile.gd`, `tests/test_crowd.gd`, `tests/run_all.gd`
- Create: `tests/test_corps.gd`

**Interfaces:**
- Produces:
  - `ResponseProfile.marshals_per_exit: int`, `escorts_per_duty: int`, `rescue_squads: int`;
  - `Person.Corps { NONE, MARSHAL, ESCORT, RESCUE }`, `Person.corps: Person.Corps`, `Person.post: Vector2` (the soldier's spawn post);
  - `Crowd.RESCUE_SQUAD := 3`;
  - `Crowd._assign_corps()`;
  - `Person.go_duty(at)` accepts soldiers; `Person.assist(s, force := false)` accepts soldiers when `force`;
  - `Crowd.off_duty(p)` sends a soldier back to its post.

- [ ] **Step 1: Write the failing tests.** Create `tests/test_corps.gd`:

```gdscript
extends RefCounted
## v0.07 soldiers' roles: each soldier takes a role from its post -- the barracks yard's first squads dig (Rescue), the
## walls' first take the ways out (Marshal), the patrols guard the responders (Escort) -- up to the profile's counts;
## only the rest rally at the Citadel; each role is drawn its own way.


static func _crowd(tier := ResponseProfile.Tier.ORGANIZED) -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(tier)
	crowd.spawn()
	return [crowd, env, world, field, grid, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[2] as Node).free()


static func _count(crowd: Crowd, corps: Person.Corps) -> int:
	var n := 0
	for p in crowd.soldiers:
		if p.corps == corps:
			n += 1
	return n


static func run(t) -> void:
	for tier in [ResponseProfile.Tier.ORGANIZED, ResponseProfile.Tier.GOD_RESISTANT]:
		var made := _crowd(tier)
		var crowd: Crowd = made[0]
		var pr := crowd.profile
		var exits := 2 + (2 if pr.boats else 0)
		var marshals := _count(crowd, Person.Corps.MARSHAL)
		var rescue := _count(crowd, Person.Corps.RESCUE)
		var escorts := _count(crowd, Person.Corps.ESCORT)
		t.check(marshals == pr.marshals_per_exit * exits and rescue == pr.rescue_squads * Crowd.RESCUE_SQUAD
			and escorts == Crowd.POST_PATROL,
			"%s: %d marshals, %d in rescue squads, %d escorts" % [pr.tier_name(), marshals, rescue, escorts])
		var posts_kept := true
		for p in crowd.soldiers:
			posts_kept = posts_kept and p.post == p.anchor
		t.check(posts_kept, "every soldier remembers its post")
		# Only soldiers without a role rally at the Citadel.
		crowd.rally()
		var wrong := 0
		for p in crowd.soldiers:
			var rallied := p.mind == Person.Mind.RALLY
			if rallied != (p.corps == Person.Corps.NONE):
				wrong += 1
		t.check(wrong == 0, "%s: only soldiers without a role rally (%d wrong)" % [pr.tier_name(), wrong])
		_done(made)

	# Soldiers can take a duty and be sent to a fire; off duty a soldier goes back to its post.
	var made := _crowd()
	var crowd: Crowd = made[0]
	var s: Person = crowd.soldiers[0]
	s.go_duty(s.ground_pos + Vector2(1, 0))
	t.check(s.mind == Person.Mind.DUTY, "a soldier can take a duty")
	crowd.off_duty(s)
	t.check(s.mind == Person.Mind.POST and s.anchor == s.post, "and goes back to its post after")
	var house: Structure = null
	for st in (made[1] as EnvironmentField).structures():
		if st.role == &"house" and house == null:
			house = st
	s.assist(house)
	t.check(s.mind != Person.Mind.ASSIST, "a soldier is not sent to a fire unasked")
	s.assist(house, true)
	t.check(s.mind == Person.Mind.ASSIST and s.assist_fire == house, "but can be, by its squad")
	s.stand_down()
	t.check(s.mind == Person.Mind.POST and s.anchor == s.post, "stood down, a soldier goes back to its post")
	_done(made)
```

In `tests/run_all.gd`, add `"res://tests/test_corps.gd",` after `"res://tests/test_plague.gd",`.

In `tests/test_profile.gd`, after the line `t.check(g.bell_climb < p.bell_climb and g.rite_time < p.rite_time ...` block (the "God-Resistant: all of it, faster" check), add:

```gdscript
	t.check([u.marshals_per_exit, o.marshals_per_exit, p.marshals_per_exit, g.marshals_per_exit] == [2, 3, 4, 5]
		and [u.escorts_per_duty, o.escorts_per_duty, p.escorts_per_duty, g.escorts_per_duty] == [1, 1, 2, 2]
		and [u.rescue_squads, o.rescue_squads, p.rescue_squads, g.rescue_squads] == [2, 3, 4, 5],
		"the soldiers' roles grow with the tier (v0.07)")
```

and change `u.lines().size() == 2 and p.lines().size() == 5` to `u.lines().size() == 3 and p.lines().size() == 6`.

In `tests/test_crowd.gd` (around line 115), replace

```gdscript
	var rallying := 0
	for p in crowd.soldiers:
		if p.mind == Person.Mind.RALLY:
			rallying += 1
	t.check(rallying == crowd.soldiers.size(), "every soldier rallies to the Citadel (%d)" % rallying)
```

with

```gdscript
	var rallying := 0
	var free := 0
	for p in crowd.soldiers:
		if p.mind == Person.Mind.RALLY:
			rallying += 1
		if p.corps == Person.Corps.NONE:
			free += 1
	t.check(rallying == free and free > 0, "every soldier without a role rallies to the Citadel (%d of %d)" % [rallying, free])
```

- [ ] **Step 2: Run the tests.** Expected: parse errors (`Person.Corps` and `marshals_per_exit` are not defined).

- [ ] **Step 3: Implement.**

`src/game/response_profile.gd`, after `var rite_time := 45.0`:

```gdscript
## The soldiers' roles (v0.07): marshals at each way out at the evacuation, escorts for each responder on duty, and
## rescue squads of Crowd.RESCUE_SQUAD. Every tier has them; harder towns have more.
var marshals_per_exit := 3
var escorts_per_duty := 1
var rescue_squads := 3
```

In `for_tier()`:
- Unprepared: add `p.marshals_per_exit = 2`, `p.rescue_squads = 2`.
- Organized: keep the defaults (3/1/3).
- Prepared: add `p.marshals_per_exit = 4`, `p.escorts_per_duty = 2`, `p.rescue_squads = 4`.
- God-Resistant: add `p.marshals_per_exit = 5`, `p.escorts_per_duty = 2`, `p.rescue_squads = 5`.

At the end of `lines()`, before `return out`:

```gdscript
	out.append("Soldiers: marshals x%d, escorts x%d, rescue x%d" % [marshals_per_exit, escorts_per_duty, rescue_squads])
```

`src/game/crowd/person.gd`:

1. After `enum Awareness { ... }` add:

```gdscript
## A soldier's role (v0.07): none (the Citadel's guard and anyone over the profile's counts), marshal at a way out,
## escort for a responder, or rescue squad.
enum Corps { NONE, MARSHAL, ESCORT, RESCUE }
```

2. After `var soldier := false` add:

```gdscript
## A soldier's role (v0.07; Crowd._assign_corps()) and the post it was given at spawn, which it goes back to.
var corps := Corps.NONE
var post := Vector2.INF
```

3. Next to the other `SOL_*` constants add:

```gdscript
## The roles' looks (v0.07): a red tabard for a marshal, a white one for an escort, and a shovel for a rescue squad.
const SOL_MARSHAL := Color("a02424")
const SOL_ESCORT := Color("e4e0d6")
const SOL_SHOVEL := Color("8a8e96")
```

4. In `_draw_soldier`, replace `_px(-2, -9 + lift, 4, 4, SOL_TABARD)` with:

```gdscript
	var tabard := SOL_MARSHAL if corps == Corps.MARSHAL else (SOL_ESCORT if corps == Corps.ESCORT else SOL_TABARD)
	_px(-2, -9 + lift, 4, 4, tabard)
```

and replace the spear lines

```gdscript
	_px(5 * f, -17 + lift, 1, 12, SOL_HAFT)
	_px(5 * f, -18 + lift, 1, 2, SOL_TIP)
```

with

```gdscript
	if corps == Corps.RESCUE:
		# A shovel, blade up over the shoulder.
		_px(5 * f, -14 + lift, 1, 9, SOL_HAFT)
		_px(5 * f - 1, -17 + lift, 3, 3, SOL_SHOVEL)
	else:
		_px(5 * f, -17 + lift, 1, 12, SOL_HAFT)
		_px(5 * f, -18 + lift, 1, 2, SOL_TIP)
```

5. In `assist(s: Structure)`: change the signature to `func assist(s: Structure, force := false) -> void:` and its first condition from `if soldier or state == State.DEAD or mind == Mind.FLEE:` to `if (soldier and not force) or state == State.DEAD or mind == Mind.FLEE:`. Add to its doc comment: `A soldier only when sent by its rescue squad (force).`

6. In `go_duty(at)`: change `if soldier or state == State.DEAD or mind == Mind.FLEE:` to `if state == State.DEAD or mind == Mind.FLEE:` and add to its doc comment: `Soldiers take duties too (v0.07): an escort taking over the bell or an engineer's place.`

7. In `stand_down()`, a soldier goes back to its post instead of recovering (a soldier in RECOVER or CALM would drift into a citizen's day). Replace

```gdscript
	if mind == Mind.ASSIST:
		_recover(rng.randf_range(2.0, 4.0))
```

with

```gdscript
	if mind == Mind.ASSIST:
		if soldier:
			send_to_post(post if post != Vector2.INF else ground_pos)  # a rescue squad back to its post (v0.07)
		else:
			_recover(rng.randf_range(2.0, 4.0))
```

`src/game/crowd/crowd.gd`:

1. Next to `const POST_PATROL := 20` add:

```gdscript
## A rescue squad's size (v0.07).
const RESCUE_SQUAD := 3
```

2. In `spawn()`, right after the loop `for spot in _soldier_posts(soldier_count): soldiers.append(_add_person(true, spot))`, add `_assign_corps()`.

3. Add the function (next to `_soldier_posts`):

```gdscript
## The soldiers' roles (v0.07), from their posts (_soldier_posts() lays them out yard, walls, Citadel, patrols): the
## barracks yard's first profile.rescue_squads x RESCUE_SQUAD form the rescue squads, the walls' first
## profile.marshals_per_exit x ways out become marshals, and the patrols escort the responders. The Citadel's guard and
## anyone over the counts keep v0.06's ways (posts, the rally). Each remembers its post.
func _assign_corps() -> void:
	var exits := 2 + (2 if profile.boats else 0)
	for i in soldiers.size():
		var p := soldiers[i]
		p.post = p.anchor
		if i < POST_YARD:
			if i < profile.rescue_squads * RESCUE_SQUAD:
				p.corps = Person.Corps.RESCUE
		elif i < POST_YARD + POST_WALLS:
			if i - POST_YARD < profile.marshals_per_exit * exits:
				p.corps = Person.Corps.MARSHAL
		elif i >= POST_YARD + POST_WALLS + POST_CITADEL:
			p.corps = Person.Corps.ESCORT
```

4. In `rally()`, the loop collecting `living`: add `and p.corps == Person.Corps.NONE` to its condition (`if is_instance_valid(p) and p.is_alive() and p.corps == Person.Corps.NONE:`). Add to its doc comment: `Only soldiers without a role (v0.07): the others have their own work.`

5. In `_on_citadel_fallen()`: `p.hold_ground()` only for `p.corps == Person.Corps.NONE`.

6. In `off_duty(p)`, right after its first guard (`if not is_instance_valid(p) or not p.is_alive() or p.mind != Person.Mind.DUTY: return`), add:

```gdscript
	if p.soldier:
		p.send_to_post(p.post if p.post != Vector2.INF else p.ground_pos)  # back to its post (v0.07)
		return
```

- [ ] **Step 4: Run the tests.** Expected: `failures=0`.

- [ ] **Step 5: Run the gates.**
  - **Digest:** `$G --headless --path . -s tools/dev/state_digest.gd` must print `digest=61267b7e90524d800bf1c3473a71146b`.
  - **Crowd check:** `$G --headless --path . --fixed-fps 60 -s tools/dev/crowd_check.gd`. Report its checksum; −346732806 was the v0.06 baseline, and it may change only because of the rally.
  - **FLOW:** `$G --path . --audio-driver Dummy --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep "FLOW result"` must show `failures=0`.

- [ ] **Step 6: Commit.**

```bash
git add src/game/response_profile.gd src/game/crowd/person.gd src/game/crowd/crowd.gd tests/test_corps.gd tests/test_corps.gd.uid tests/test_profile.gd tests/test_crowd.gd tests/run_all.gd
git commit -m "feat: soldiers' roles from their posts (v0.07 M1)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

(Run the editor import first if `tests/test_corps.gd.uid` does not exist.)

---

## Milestone 2 — Marshals

### Task 2: MarshalManager and its hooks

**Files:**
- Create: `src/game/crowd/marshal_manager.gd`, `tests/test_marshals.gd`
- Modify: `src/game/crowd/crowd.gd`, `src/game/crowd/river_ferry.gd`, `src/game/mission.gd`, `src/game/ui/behaviour_overlay.gd`, `tests/run_all.gd`

**Interfaces:**
- Consumes: `Person.corps`, `Person.post`, `ResponseProfile.marshals_per_exit`, `Crowd.outward_of(gate)`, `Crowd.GATE_DOOR`, `RiverFerry.board_at`, `RiverFerry.State`.
- Produces:
  - `MarshalManager` with `signal posted`, `var active: bool`, `var posts: Dictionary` (mouth `Vector2` → `Array` of Person);
  - `func setup(crowd: Crowd, town: Town, grid: WalkGrid) -> MarshalManager`, `func exits() -> Array` (each `[mouth: Vector2, outward: Vector2]`), `func begin() -> void`, `func speed_at(mouth: Vector2) -> float`, `func step(delta: float) -> void`, `func clear() -> void`;
  - `Crowd.marshals: MarshalManager`.

- [ ] **Step 1: Write the failing test** — `tests/test_marshals.gd`:

```gdscript
extends RefCounted
## v0.07 Marshals: at the evacuation the soldiers from the walls take the ways out, profile.marshals_per_exit each;
## each one standing near a way out makes it SPEED faster; a confused evacuee near one comes to within STEADY_TIME;
## killed, a way out slows again.


static func _crowd(tier := ResponseProfile.Tier.PREPARED) -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(tier)
	crowd.spawn()
	return [crowd, env, world, field, grid, town]


static func run(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var m := crowd.marshals
	t.check(m != null and not m.active, "the marshals wait on the walls until the evacuation")
	var fired := []
	m.posted.connect(func() -> void: fired.append(true))
	crowd.alarms.stage = AlarmManager.Stage.CITY_EMERGENCY
	crowd._on_stage(AlarmManager.Stage.EVACUATION, "test")
	var per := crowd.profile.marshals_per_exit
	var placed := true
	for mouth: Vector2 in m.posts:
		var mine: Array = m.posts[mouth]
		placed = placed and mine.size() == per
		for p: Person in mine:
			placed = placed and p.corps == Person.Corps.MARSHAL and p.goal().distance_to(mouth) <= MarshalManager.REACH
	t.check(m.active and fired.size() == 1 and m.posts.size() == m.exits().size() and m.posts.size() == 4 and placed,
		"at the evacuation %d marshals take each of the %d ways out" % [per, m.posts.size()])

	# Arrived, they make the way out faster; killed, it slows again.
	var gate: Structure = (made[5] as Town).gates[0]
	var mouth: Vector2 = m.exits()[0][0]
	for p: Person in m.posts[mouth]:
		p.ground_pos = p.goal()
		p._goal = Vector2.INF
		p._path = PackedVector2Array()
	t.near(m.speed_at(mouth), 1.0 + MarshalManager.SPEED * per, 0.001, "each marshal speeds the way out (x%.2f)" % m.speed_at(mouth))
	var spots := crowd.queue_spots(gate)
	for k in 4:
		var c: Person = crowd.citizens[k]
		c.mind = Person.Mind.FLEE
		c.ground_pos = spots[k]
	crowd._gate_next.erase(gate)
	crowd._gates()
	t.near(float(crowd._gate_next[gate]) - crowd._clock, Crowd.GATE_INTERVAL / m.speed_at(mouth), 0.001,
		"so the gate lets the next one through sooner (%.2f s)" % (float(crowd._gate_next[gate]) - crowd._clock))

	# A confused evacuee near a marshal comes to sooner.
	var ev: Person = crowd.citizens[10]
	ev.mind = Person.Mind.FLEE
	ev.ground_pos = mouth + Vector2(0.0, -1.0)
	ev.confuse(15.0)
	m.step(1.0)
	t.check(ev._confused_left <= MarshalManager.STEADY_TIME, "a confused evacuee near a marshal comes to sooner")

	for p: Person in m.posts[mouth]:
		field.kill(p, &"test")
	t.near(m.speed_at(mouth), 1.0, 0.001, "killed, the way out slows again")
	crowd.clear()
	(made[2] as Node).free()
```

Register `"res://tests/test_marshals.gd",` after `"res://tests/test_corps.gd",` in `tests/run_all.gd`.

- [ ] **Step 2: Run the tests.** Expected: a parse error (`MarshalManager` and `crowd.marshals` are unknown).

- [ ] **Step 3: Implement** `src/game/crowd/marshal_manager.gd`:

```gdscript
class_name MarshalManager
extends RefCounted
## Marshals (v0.07): at the Evacuation stage the soldiers from the walls take the ways out -- the profile's
## marshals_per_exit at the Main Gate, the Side Gate and, in a town with boats, the postern and the dock -- standing
## either side of the crowd's head. Each living marshal within REACH of a way out makes it SPEED faster (speed_at(): a
## gate lets the next one through sooner, the boat takes them aboard sooner), and a confused evacuee near one is
## brought round within STEADY_TIME. Kill them or knock them away and the way out slows again.

signal posted

const REACH := 2.0
const SPEED := 0.15
const STEADY_R := 3.0
const STEADY_TIME := 3.0
## How often the confused near a marshal are checked.
const STEADY_EVERY := 0.5
## How far either side of a way out's mouth the first marshals stand, how much farther each next pair, and how far
## back from the mouth.
const FLANK := 0.9
const FLANK_STEP := 0.45
const BACK := 0.4

var active := false
## A way out's mouth -> the marshals posted there.
var posts := {}
var _crowd: Crowd
var _town: Town
var _grid: WalkGrid
var _steady_in := 0.0


func setup(crowd: Crowd, town: Town, grid: WalkGrid) -> MarshalManager:
	_crowd = crowd
	_town = town
	_grid = grid
	return self


## The ways out, each [mouth, outward]: every open gate's mouth (where Crowd queues its crowd), and the dock's
## boarding point while the boats can run.
func exits() -> Array:
	var out := []
	for g in _town.gates:
		if is_instance_valid(g) and not g.destroyed and g.walkable:
			var o := Crowd.outward_of(g)
			out.append([g.center() - o * (absf(g.footprint.size.dot(o)) * 0.5 + Crowd.GATE_DOOR), o])
	if _crowd.ferry != null and _crowd.ferry.state != RiverFerry.State.ENDED and _crowd.ferry.board_at != Vector2.INF:
		out.append([_crowd.ferry.board_at, Vector2(0, 1)])
	return out


## The Evacuation stage: the marshals leave the walls for the ways out.
func begin() -> void:
	if active:
		return
	active = true
	var pool: Array[Person] = []
	for p in _crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and p.corps == Person.Corps.MARSHAL:
			pool.append(p)
	var per := _crowd.profile.marshals_per_exit
	var k := 0
	for e in exits():
		var mouth: Vector2 = e[0]
		var out_dir: Vector2 = e[1]
		var side := Vector2(-out_dir.y, out_dir.x)
		var mine: Array = []
		for j in per:
			if k >= pool.size():
				break
			var p := pool[k]
			k += 1
			var sgn := -1.0 if j % 2 == 0 else 1.0
			var spot := mouth - out_dir * BACK + side * sgn * (FLANK + FLANK_STEP * float(j / 2))
			if not _grid.walkable(spot):
				var near := _grid.nearest_walkable(spot, 3)
				spot = near if near != Vector2.INF else mouth
			p.send_to_post(spot)
			mine.append(p)
		posts[mouth] = mine
	posted.emit()


## How much faster the way out at `mouth` runs: 1 + SPEED for each living marshal within REACH of it.
func speed_at(mouth: Vector2) -> float:
	var n := 0
	for p in _crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and p.corps == Person.Corps.MARSHAL \
				and p.ground_pos.distance_to(mouth) <= REACH:
			n += 1
	return 1.0 + SPEED * float(n)


## Confused evacuees near a marshal come to within STEADY_TIME.
func step(delta: float) -> void:
	if not active:
		return
	_steady_in -= delta
	if _steady_in > 0.0:
		return
	_steady_in = STEADY_EVERY
	var marshals: Array[Person] = []
	for p in _crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and p.corps == Person.Corps.MARSHAL:
			marshals.append(p)
	if marshals.is_empty():
		return
	for c in _crowd.citizens:
		if not is_instance_valid(c) or c.mind != Person.Mind.CONFUSED or not c._was_fleeing:
			continue
		for m in marshals:
			if m.ground_pos.distance_to(c.ground_pos) <= STEADY_R:
				c._confused_left = minf(c._confused_left, STEADY_TIME)
				break


func clear() -> void:
	posts.clear()
	active = false
```

`src/game/crowd/crowd.gd`:

1. Next to `var ferry: RiverFerry` add:

```gdscript
## The soldiers' roles (v0.07); made by spawn().
var marshals: MarshalManager
```

2. In `spawn()`, after `plague = PlagueManager.new().setup(self, _field, _seed + 41)`, add `marshals = MarshalManager.new().setup(self, _town, _grid)`.
3. In `advance()`, after the `if plague != null: plague.step(delta)` block, add `if marshals != null: marshals.step(delta)`.
4. In `_on_stage()`, the `AlarmManager.Stage.EVACUATION, AlarmManager.Stage.COLLAPSE:` branch: after `ferry.begin()` and before `_evacuate()`, add `if marshals != null: marshals.begin()`.
5. In `_gates()`, replace

```gdscript
			_gate_next[gate] = _clock + (POSTERN_INTERVAL if gate.art_tag == &"postern" else GATE_INTERVAL)
```

with

```gdscript
			var interval := POSTERN_INTERVAL if gate.art_tag == &"postern" else GATE_INTERVAL
			# Marshals at the mouth (v0.07) let them through faster.
			_gate_next[gate] = _clock + interval / (marshals.speed_at(face) if marshals != null else 1.0)
```

(`face` is the variable already computed earlier in the same loop as the gate's mouth.)

6. In `clear()`, after the plague's cleanup, add `if marshals != null: marshals.clear()`, then `marshals = null`.

`src/game/crowd/river_ferry.gd`, in `step()`: replace `_board_in = LOAD_TIME / float(LOAD)` with:

```gdscript
			# Marshals at the dock (v0.07) see them aboard faster.
			var speed := _crowd.marshals.speed_at(board_at) if _crowd.marshals != null else 1.0
			_board_in = LOAD_TIME / float(LOAD) / speed
```

`src/game/mission.gd`: find the block connecting the ferry's banners (`_crowd.ferry.opened.connect(...)`). After it, add:

```gdscript
	if _crowd.marshals != null:
		_crowd.marshals.posted.connect(func(): _rules.banner.emit("THE SOLDIERS TAKE THE GATES"))
```

`src/game/ui/behaviour_overlay.gd`: in `_draw_panel`, after the boats line (`if crowd.ferry != null and crowd.profile.boats:` block), add:

```gdscript
	if crowd.marshals != null and crowd.marshals.active:
		var parts := []
		for e in crowd.marshals.exits():
			parts.append("x%.2f" % crowd.marshals.speed_at(e[0]))
		lines.append(["Marshals at the ways out: %s" % ", ".join(parts), Color("e06060")])
```

- [ ] **Step 4:** Run the editor import, then the tests. Expected: `failures=0`.
- [ ] **Step 5: Gates:** digest unchanged; FLOW `failures=0`. Report the crowd_check checksum.
- [ ] **Step 6: Commit:**

```bash
git add src/game/crowd/marshal_manager.gd src/game/crowd/marshal_manager.gd.uid tests/test_marshals.gd tests/test_marshals.gd.uid src/game/crowd/crowd.gd src/game/crowd/river_ferry.gd src/game/mission.gd src/game/ui/behaviour_overlay.gd tests/run_all.gd
git commit -m "feat: marshals at the ways out (v0.07 M2)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Milestone 3 — Escorts

### Task 3: EscortManager, the bell takeover, engineer stand-ins

**Files:**
- Create: `src/game/crowd/escort_manager.gd`, `tests/test_escorts.gd`
- Modify: `src/game/crowd/crowd.gd`, `src/game/crowd/bell_network.gd`, `src/game/crowd/engineer_manager.gd`, `src/game/mission.gd`, `src/game/ui/behaviour_overlay.gd`, `tests/run_all.gd`

**Interfaces:**
- Consumes: `Person.corps`, `Person.post`, `Person.go_duty` (accepts soldiers since M1), `Crowd.off_duty` (soldier-aware since M1), `ResponseProfile.escorts_per_duty`, `BellNetwork.State`, `BanishingRite.State`, `EngineerManager.teams`.
- Produces:
  - `EscortManager` with `var guards: Dictionary` (duty key `String` → `Array` of Person);
  - `func setup(crowd: Crowd) -> EscortManager`, `func step(delta: float) -> void`, `func bell_stand_in() -> Person`, `func engineer_stand_in(team: Dictionary) -> Person`, `func clear() -> void`;
  - `Crowd.escorts: EscortManager`;
  - `BellNetwork.keeper_replaced` signal and `BellNetwork.replace_keeper(p: Person) -> void`; `BellNetwork.ESCORT_CLIMB := 1.5`;
  - every engineer team dictionary gets `"id": int`.

Duty keys: `"bell"`, `"rite"`, and `"team:%d" % team.id`.

- [ ] **Step 1: Write the failing test** — `tests/test_escorts.gd`:

```gdscript
extends RefCounted
## v0.07 Escorts: the patrol soldiers guard the responders on duty -- the bellkeeper, the clergy's rite, each engineer
## team -- profile.escorts_per_duty each; a bellkeeper killed before the bell rang is replaced by an escort (a slower
## climb), an engineer by one of its team's; a guarded responder confused near its escort comes to sooner; when the
## duty ends they go back to their posts.


static func _crowd(tier := ResponseProfile.Tier.PREPARED) -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(tier)
	crowd.spawn()
	return [crowd, env, world, field, grid, town]


static func _arrive(p: Person) -> void:
	if p.goal() != Vector2.INF:
		p.ground_pos = p.goal()
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


static func run(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var esc := crowd.escorts
	var per := crowd.profile.escorts_per_duty

	# The bell: escorts join the bellkeeper when it is called.
	var bell := crowd.bell
	bell.call_keeper()
	esc.step(1.0)
	var guards: Array = esc.guards.get("bell", [])
	var near := true
	for g: Person in guards:
		near = near and g.corps == Person.Corps.ESCORT and g.goal().distance_to(bell.keeper.ground_pos) <= EscortManager.REACH + 0.5
	t.check(guards.size() == per and near, "%d escorts join the bellkeeper" % guards.size())

	# The bellkeeper killed before the bell rang: an escort takes over, its climb slower.
	var replaced := []
	bell.keeper_replaced.connect(func() -> void: replaced.append(true))
	var climb := bell.climb
	field.kill(bell.keeper, &"test")
	bell.step(0.1)
	t.check(bell.keeper != null and bell.keeper.soldier and bell.state == BellNetwork.State.CALLED and replaced.size() == 1
		and is_equal_approx(bell.climb, climb * BellNetwork.ESCORT_CLIMB),
		"an escort takes the bell rope (climb %.1f s)" % bell.climb)
	var new_keeper := bell.keeper
	_arrive(new_keeper)
	bell.step(0.1)
	bell.step(bell.climb + 0.1)
	t.check(bell.state == BellNetwork.State.RUNG and crowd.alarms.bell_rung, "and the bell still rings")
	esc.step(1.0)
	t.check(not esc.guards.has("bell") and new_keeper.mind == Person.Mind.POST and new_keeper.anchor == new_keeper.post,
		"the bell rung, the escorts go back to their posts")

	# Engineers: escorts join a team; an engineer killed is replaced by one of them.
	var e := crowd.engineers
	e.begin()
	e.step(0.1)
	esc.step(1.0)
	var team: Dictionary = e.teams[0]
	var key := "team:%d" % int(team.id)
	t.check((esc.guards.get(key, []) as Array).size() == per, "escorts join each engineer team")
	var lost := []
	e.team_lost.connect(func() -> void: lost.append(true))
	var teams := e.teams.size()
	var dead: Person = team.members[0]
	field.kill(dead, &"test")
	e.step(0.1)
	var stand_in: Person = team.members[0]
	t.check(e.teams.size() == teams and lost.is_empty() and stand_in.soldier and stand_in.mind == Person.Mind.DUTY,
		"an engineer killed is replaced by an escort; the team goes on")

	# A guarded responder confused near its escort comes to sooner.
	var guarded: Person = team.members[1]
	for g: Person in esc.guards.get(key, []):
		g.ground_pos = guarded.ground_pos + Vector2(0.5, 0.0)
	guarded.confuse(15.0)
	esc.step(1.0)
	t.check(guarded._confused_left <= EscortManager.STEADY_TIME, "a guarded engineer confused near its escort comes to sooner")
	crowd.clear()
	(made[2] as Node).free()
```

Register it after `"res://tests/test_marshals.gd",`.

- [ ] **Step 2: Run the tests.** Expected: a parse error (`EscortManager` is unknown).

- [ ] **Step 3: Implement** `src/game/crowd/escort_manager.gd`:

```gdscript
class_name EscortManager
extends RefCounted
## Escorts (v0.07): the patrol soldiers guard the town's responders while they are on duty -- the bellkeeper while the
## bell is called, climbed or waited for, the clergy while their rite gathers, chants or cools down, each engineer
## team while the engineers are out -- the profile's escorts_per_duty each, keeping within REACH. Near a guarded
## responder Silent Doom is seen (Crowd counts any living witness, soldiers too); a guarded responder confused near its
## escort comes to within STEADY_TIME; a bellkeeper killed before the bell rang is replaced by an escort
## (bell_stand_in(); BellNetwork climbs it slower), an engineer by one of its team's (engineer_stand_in()). When a duty
## ends its escorts go back to their posts.

const REACH := 1.5
const STEADY_R := 2.0
const STEADY_TIME := 3.0
## How often the duties are looked at.
const EVERY := 0.5
## Where the escorts stand round what they guard.
const OFFSETS := [Vector2(0.8, 0.5), Vector2(-0.8, 0.5), Vector2(0.5, -0.8), Vector2(-0.5, -0.8)]

## A duty's key ("bell", "rite", "team:<id>") -> its escorts.
var guards := {}
var _crowd: Crowd
var _in := 0.0


func setup(crowd: Crowd) -> EscortManager:
	_crowd = crowd
	return self


## The duties now: key -> {"point": where to stand round, "guarded": the responders}.
func _duties() -> Dictionary:
	var out := {}
	var bell := _crowd.bell
	if bell != null and bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING, BellNetwork.State.WAITING] \
			and is_instance_valid(bell.keeper) and bell.keeper.is_alive():
		out["bell"] = {"point": bell.keeper.ground_pos, "guarded": [bell.keeper]}
	var rite := _crowd.rite
	if rite != null and rite.state in [BanishingRite.State.GATHERING, BanishingRite.State.CHANTING,
			BanishingRite.State.COOLDOWN]:
		var clergy: Array = []
		for e in rite.circle:
			if is_instance_valid(e[0]):
				clergy.append(e[0])
		out["rite"] = {"point": rite.centre, "guarded": clergy}
	var eng := _crowd.engineers
	if eng != null and eng.active:
		for team: Dictionary in eng.teams:
			var lead: Person = null
			for p in team.members:
				if is_instance_valid(p) and (p as Person).is_alive():
					lead = p
					break
			if lead != null:
				out["team:%d" % int(team.id)] = {"point": lead.ground_pos, "guarded": team.members}
	return out


func step(delta: float) -> void:
	_in -= delta
	if _in > 0.0:
		return
	_in = EVERY
	var duties := _duties()
	for key in guards.keys():
		if not duties.has(key):
			_release(guards[key])
			guards.erase(key)
	var per := _crowd.profile.escorts_per_duty
	for key in duties:
		var d: Dictionary = duties[key]
		var mine: Array = []
		for p in guards.get(key, []):
			if is_instance_valid(p) and (p as Person).is_alive():
				mine.append(p)
		while mine.size() < per:
			var free := _free_nearest(d.point)
			if free == null:
				break
			mine.append(free)
		guards[key] = mine
		var point: Vector2 = d.point
		for i in mine.size():
			var p: Person = mine[i]
			if p.mind == Person.Mind.DUTY:
				continue  # it took over a duty (the bell, an engineer's place)
			if p.anchor.distance_to(point) > REACH or p.mind != Person.Mind.POST:
				p.send_to_post(_crowd._spot_near(point + OFFSETS[i % OFFSETS.size()], 0.2))
		_steady(d.guarded, mine)


## Guarded responders confused near one of their escorts come to sooner.
func _steady(guarded: Array, mine: Array) -> void:
	for g in guarded:
		if not is_instance_valid(g) or (g as Person).mind != Person.Mind.CONFUSED:
			continue
		var gp: Person = g
		for p in mine:
			if (p as Person).ground_pos.distance_to(gp.ground_pos) <= STEADY_R:
				gp._confused_left = minf(gp._confused_left, STEADY_TIME)
				break


## Whether `p` is guarding a duty now (Crowd leaves it out of the patrols' investigations).
func guarding(p: Person) -> bool:
	for key in guards:
		if (guards[key] as Array).has(p):
			return true
	return false


## The nearest escort guarding nothing and on no duty of its own (a stand-in bellkeeper or engineer).
func _free_nearest(point: Vector2) -> Person:
	var taken := []
	for key in guards:
		taken.append_array(guards[key])
	var best: Person = null
	for p in _crowd.soldiers:
		if not is_instance_valid(p) or not p.is_alive() or p.corps != Person.Corps.ESCORT or taken.has(p) \
				or p.mind == Person.Mind.DUTY:
			continue
		if best == null or p.ground_pos.distance_squared_to(point) < best.ground_pos.distance_squared_to(point):
			best = p
	return best


func _release(mine: Array) -> void:
	for p in mine:
		if is_instance_valid(p) and (p as Person).is_alive():
			var s: Person = p
			s.send_to_post(s.post if s.post != Vector2.INF else s.ground_pos)


## A living escort of the bellkeeper to climb in its place, taken off the guard; null when there is none.
func bell_stand_in() -> Person:
	return _take("bell")


## A living escort of `team` to take a fallen engineer's place, taken off the guard; null when there is none.
func engineer_stand_in(team: Dictionary) -> Person:
	return _take("team:%d" % int(team.get("id", -1)))


func _take(key: String) -> Person:
	var mine: Array = guards.get(key, [])
	for i in mine.size():
		var p = mine[i]
		if is_instance_valid(p) and (p as Person).is_alive():
			mine.remove_at(i)
			return p
	return null


func clear() -> void:
	guards.clear()
```

`src/game/crowd/bell_network.gd`:

1. After `signal silenced(reason: String)` add:

```gdscript
## An escort took over from a fallen bellkeeper (v0.07).
signal keeper_replaced
```

2. After `const FOOT_REACH := 0.8` add:

```gdscript
## An escort climbing in a fallen bellkeeper's place takes this much longer (v0.07).
const ESCORT_CLIMB := 1.5
```

and next to `var keeper: Person` add:

```gdscript
## Whether an escort has taken the rope (v0.07; replace_keeper()).
var keeper_is_soldier := false
```

3. In `step()`, replace

```gdscript
	if not _keeper_ok():
		_silence("the bellkeeper is dead")
		return
```

(the one inside `step`, after the tower checks) with

```gdscript
	if not _keeper_ok():
		# An escort takes the rope (v0.07), else the bell is silenced.
		var sub: Person = _crowd.escorts.bell_stand_in() if _crowd.escorts != null else null
		if sub != null:
			replace_keeper(sub)
			return
		_silence("the bellkeeper is dead")
		return
```

4. Add:

```gdscript
## An escort climbs in the fallen bellkeeper's place, ESCORT_CLIMB times slower (once, however many fall); the climb
## starts over.
func replace_keeper(p: Person) -> void:
	keeper = p
	if not keeper_is_soldier:
		climb *= ESCORT_CLIMB
	keeper_is_soldier = true
	progress = 0.0
	state = State.CALLED
	keeper.go_ring(foot)
	keeper_replaced.emit()
```

`src/game/crowd/engineer_manager.gd`:

1. Add `var _next_id := 0` next to the other vars. In `_team(members)`, return `{"id": _next_id, ...}` and increment `_next_id` first:

```gdscript
func _team(members: Array) -> Dictionary:
	_next_id += 1
	return {"id": _next_id, "members": members, "job": {}, "spots": [], "progress": 0.0, "working": false}
```

2. In `_check_losses()`: before deciding a team is lost, try stand-ins. Replace the beginning of the loop body:

```gdscript
	for team in teams:
		var whole := true
		for p in team.members:
			whole = whole and is_instance_valid(p) and (p as Person).is_alive()
```

with

```gdscript
	for team in teams:
		# A fallen engineer's place is taken by one of the team's escorts (v0.07) before the team is written off.
		for i in team.members.size():
			var p = team.members[i]
			if not is_instance_valid(p) or not (p as Person).is_alive():
				var sub: Person = _crowd.escorts.engineer_stand_in(team) if _crowd.escorts != null else null
				if sub != null:
					team.members[i] = sub
					var spot: Vector2 = team.spots[i] if i < team.spots.size() else base
					if spot != Vector2.INF:
						sub.go_duty(spot)
		var whole := true
		for p in team.members:
			whole = whole and is_instance_valid(p) and (p as Person).is_alive()
```

3. In `_send(p, at)`, accept soldiers:

```gdscript
	if is_instance_valid(p) and p.is_alive() and (p.mind == Person.Mind.DUTY or p.mind in AVAILABLE or p.soldier):
		p.go_duty(at)
```

4. In `_work()`, change `if p.mind in AVAILABLE and spot != Vector2.INF:` to `if (p.mind in AVAILABLE or p.soldier) and spot != Vector2.INF:`.

`src/game/crowd/crowd.gd`:
- Add `var escorts: EscortManager` next to `var marshals`.
- In `spawn()`, after the marshals line: `escorts = EscortManager.new().setup(self)`.
- In `advance()`, after `marshals.step(delta)`: `if escorts != null: escorts.step(delta)`.
- In `clear()`: `if escorts != null: escorts.clear()`, then `escorts = null`.
- Escorts are patrol soldiers, which `_investigate()` sends to look at a district's first emergency: a guarding one is
  left out of that. In `_investigate()`, change the pool's condition to
  `if is_instance_valid(p) and p.is_alive() and p.mind == Person.Mind.POST and not (escorts != null and escorts.guarding(p)):`
  and in `_return_investigators()` change `elif p.is_alive() and p.mind == Person.Mind.POST:` to
  `elif p.is_alive() and p.mind == Person.Mind.POST and not (escorts != null and escorts.guarding(p)):` (an
  investigator since taken as an escort stays with its duty).

`src/game/mission.gd`: where the bell's banners are connected (`if _crowd.bell != null:` block), add:

```gdscript
		_crowd.bell.keeper_replaced.connect(func(): _rules.banner.emit("A SOLDIER TAKES THE BELL ROPE"))
```

`src/game/ui/behaviour_overlay.gd`: after the marshals line, add:

```gdscript
	if crowd.escorts != null and not crowd.escorts.guards.is_empty():
		var parts := []
		for key in crowd.escorts.guards:
			parts.append("%s %d" % [key, (crowd.escorts.guards[key] as Array).size()])
		lines.append(["Escorts: %s" % ", ".join(parts), Color("e8e4dc")])
```

- [ ] **Step 4:** Run the editor import, then the tests: `failures=0`. The existing `test_bell.gd` checks "a dead bellkeeper silences the bell" with escorts possibly assigned. That test never steps `crowd.escorts`, so no escort is assigned and it must still pass.
- [ ] **Step 5: Gates:** digest unchanged; FLOW `failures=0`. Report crowd_check.
- [ ] **Step 6: Commit:**

```bash
git add src/game/crowd/escort_manager.gd src/game/crowd/escort_manager.gd.uid tests/test_escorts.gd tests/test_escorts.gd.uid src/game/crowd/crowd.gd src/game/crowd/bell_network.gd src/game/crowd/engineer_manager.gd src/game/mission.gd src/game/ui/behaviour_overlay.gd tests/run_all.gd
git commit -m "feat: escorts guard the responders (v0.07 M3)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Milestone 4 — Rescue squads

### Task 4: RescueManager, the trapped, fires

**Files:**
- Create: `src/game/crowd/rescue_manager.gd`, `tests/test_rescue.gd`
- Modify: `src/game/crowd/crowd.gd`, `src/game/crowd/shelter_manager.gd`, `src/game/crowd/fire_manager.gd`, `src/game/mission.gd`, `src/game/ui/behaviour_overlay.gd`, `tests/run_all.gd`

**Interfaces:**
- Consumes: `Person.corps`, `Person.post`, `Person.assist(s, force)`, `Crowd.RESCUE_SQUAD`, `Crowd._spot_near(about, spread)`, `FireManager.fires`, `FireManager.RECRUIT_REACH`, `FireManager.ABANDON`, `FireManager.nearest_water()`.
- Produces:
  - `RescueManager` with `signal first_rescue`;
  - `const TRAPPED_SHARE := 0.6`, `TRAPPED_LIFE := 45.0`, `DIG_TIME := 3.0`, `DIG_REACH := 1.2`;
  - `var trapped: Array` (`{"p": Person, "left": float, "site": Structure}`), `var squads: Array` (`{"members": Array, "site": Structure, "spot": Vector2, "dig": float}`), `var rescued: int`, `var died: int`;
  - `func setup(crowd: Crowd, field: EnemyField) -> RescueManager`, `func trap(people: Array, s: Structure) -> void`, `func trapped_at(s: Structure) -> int`, `func step(delta: float) -> void`, `func draw(ci: CanvasItem) -> void`, `func clear() -> void`;
  - `Crowd.rescue: RescueManager`;
  - `FireManager.enlist(p: Person, s: Structure) -> void`.

- [ ] **Step 1: Write the failing test** — `tests/test_rescue.gd`:

```gdscript
extends RefCounted
## v0.07 Rescue squads: a collapsing shelter traps some of those inside instead of killing them all; a squad from the
## barracks goes to the rubble and digs one out every DIG_TIME; the untended die after TRAPPED_LIFE; an idle squad
## turns out to a fire.


static func _crowd(tier := ResponseProfile.Tier.ORGANIZED) -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(tier)
	crowd.spawn()
	return [crowd, env, world, field, grid, town]


## `n` citizens put inside `s` as ShelterManager would.
static func _shelter(crowd: Crowd, s: Structure, n: int) -> Array[Person]:
	var inside: Array[Person] = []
	for p in crowd.citizens:
		if p.is_alive() and not p.inside and inside.size() < n:
			inside.append(p)
	for p in inside:
		crowd.shelters._enter(p, s)
		(crowd.shelters.shelters[s].inside as Array).append(p)
	return inside


static func run(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var r := crowd.rescue
	t.check(r.squads.size() == crowd.profile.rescue_squads, "%d rescue squads from the barracks" % r.squads.size())

	# A shelter collapses on ten people: some are trapped, the rest die.
	var s: Structure = crowd.shelters.shelters.keys()[0]
	var inside := _shelter(crowd, s, 10)
	var killed := crowd.killed_citizens
	s.destroy(s.center(), &"nova")
	crowd.shelters._step_in = 0.0
	crowd.shelters.step(0.3)
	var trapped := r.trapped_at(s)
	t.check(trapped > 0 and trapped < 10 and crowd.killed_citizens - killed == 10 - trapped,
		"a collapse traps %d of the 10 inside; the rest die" % trapped)

	# A squad goes to the rubble and digs them out, one every DIG_TIME.
	var firsts := []
	r.first_rescue.connect(func() -> void: firsts.append(true))
	r.step(0.6)
	var squad: Dictionary = {}
	for sq in r.squads:
		if sq.site == s:
			squad = sq
	t.check(not squad.is_empty(), "a squad goes to the rubble")
	for m in squad.members:
		var p: Person = m
		p.ground_pos = squad.spot
		p._goal = Vector2.INF
		p._path = PackedVector2Array()
	r.step(RescueManager.DIG_TIME + 0.1)
	var freed: Person = null
	for p in inside:
		if p.is_alive() and not p.inside:
			freed = p
	t.check(r.rescued == 1 and freed != null and freed.visible and firsts.size() == 1,
		"one dug out after %d s, frightened and alive" % roundi(RescueManager.DIG_TIME))

	# Untended, the trapped die.
	for m in squad.members:
		(made[3] as EnemyField).kill(m, &"test")
	var left := r.trapped_at(s)
	r.step(RescueManager.TRAPPED_LIFE + 0.1)
	t.check(left > 0 and r.trapped_at(s) == 0 and r.died == left, "left untended, the trapped die (%d died)" % r.died)
	crowd.clear()
	(made[2] as Node).free()

	# An idle squad turns out to a fire.
	made = _crowd()
	crowd = made[0]
	r = crowd.rescue
	var house: Structure = null
	var yard := TownLayout.BARRACKS_YARD.get_center()
	for st in (made[1] as EnvironmentField).structures():
		if st.role == &"house" and st.kind == Structure.Kind.HOUSE and (house == null
				or st.center().distance_to(yard) < house.center().distance_to(yard)):
			house = st
	crowd.alarms.stage = AlarmManager.Stage.CONCERN
	crowd.fires.ignite(house, 0.4)
	r.step(0.6)
	var at_fire := 0
	for sq in r.squads:
		for m in sq.members:
			if (m as Person).mind == Person.Mind.ASSIST and (m as Person).assist_fire == house:
				at_fire += 1
	t.check(at_fire >= Crowd.RESCUE_SQUAD and (crowd.fires.fires[house].responders as Array).size() >= Crowd.RESCUE_SQUAD,
		"an idle squad turns out to a fire (%d soldiers)" % at_fire)
	crowd.clear()
	(made[2] as Node).free()
```

Register it after `"res://tests/test_escorts.gd",`.

- [ ] **Step 2: Run the tests.** Expected: a parse error (`RescueManager` is unknown).

- [ ] **Step 3: Implement** `src/game/crowd/rescue_manager.gd`:

```gdscript
class_name RescueManager
extends RefCounted
## Rescue squads (v0.07): the barracks yard's soldiers, in squads of Crowd.RESCUE_SQUAD. A shelter that collapses
## traps TRAPPED_SHARE of those inside under its rubble instead of killing them (ShelterManager hands them over:
## trap()); they live TRAPPED_LIFE. The nearest free squad goes to the rubble and, with one of them within DIG_REACH,
## digs one out every DIG_TIME; the freed come out at the rubble's edge, frightened. Untended, the trapped die there. A
## squad with nothing to dig turns out to the nearest fire (FireManager.enlist()) until the town evacuates.

signal first_rescue

const TRAPPED_SHARE := 0.6
const TRAPPED_LIFE := 45.0
const DIG_TIME := 3.0
const DIG_REACH := 1.2
## How often squads are given work.
const EVERY := 0.5
const DUST := Color(0.62, 0.56, 0.48)

## Each trapped person: {"p": Person, "left": seconds to live, "site": the rubble}.
var trapped: Array = []
## Each squad: {"members": Array of Person, "site": Structure being dug (null when free), "spot": where it digs,
## "dig": progress on the next one, 0..1}.
var squads: Array = []
var rescued := 0
var died := 0
var _crowd: Crowd
var _field: EnemyField
var _in := 0.0
var _announced := false


func setup(crowd: Crowd, field: EnemyField) -> RescueManager:
	_crowd = crowd
	_field = field
	var squad: Array = []
	for p in crowd.soldiers:
		if p.corps == Person.Corps.RESCUE:
			squad.append(p)
			if squad.size() == Crowd.RESCUE_SQUAD:
				squads.append({"members": squad, "site": null, "spot": Vector2.INF, "dig": 0.0})
				squad = []
	if not squad.is_empty():
		squads.append({"members": squad, "site": null, "spot": Vector2.INF, "dig": 0.0})
	return self


## The trapped from a shelter's collapse: hidden under the rubble with TRAPPED_LIFE to live.
func trap(people: Array, s: Structure) -> void:
	for p in people:
		if not is_instance_valid(p):
			continue
		var q: Person = p
		q.inside = true
		q.visible = false
		q.shelter = null
		q.ground_pos = s.center()
		trapped.append({"p": q, "left": TRAPPED_LIFE, "site": s})


func trapped_at(s: Structure) -> int:
	var n := 0
	for t in trapped:
		if t.site == s:
			n += 1
	return n


func step(delta: float) -> void:
	for t in trapped.duplicate():
		t.left = float(t.left) - delta
		if float(t.left) <= 0.0:
			_die(t)
	for sq in squads:
		if sq.site != null:
			_dig(sq, delta)
	_in -= delta
	if _in <= 0.0:
		_in = EVERY
		_assign()


func _living(sq: Dictionary) -> Array:
	var out: Array = []
	for m in sq.members:
		if is_instance_valid(m) and (m as Person).is_alive():
			out.append(m)
	return out


## Free squads to the rubble with nobody digging (nearest first); the rest to fires, or back to their posts.
func _assign() -> void:
	var sites: Array = []
	for t in trapped:
		if not sites.has(t.site):
			sites.append(t.site)
	for s in sites:
		var dug := false
		for sq in squads:
			dug = dug or sq.site == s
		if dug:
			continue
		var best: Dictionary = {}
		var best_d := INF
		for sq in squads:
			var crew := _living(sq)
			if sq.site != null or crew.is_empty():
				continue
			var d := (crew[0] as Person).ground_pos.distance_to((s as Structure).center())
			if d < best_d:
				best_d = d
				best = sq
		if best.is_empty():
			continue
		var site: Structure = s
		var crew := _living(best)
		var away := (crew[0] as Person).ground_pos - site.center()
		var dir := away.normalized() if away.length() > 0.01 else Vector2.DOWN
		best.site = site
		best.dig = 0.0
		best.spot = _crowd._spot_near(site.center() + dir * (site.footprint.size.length() * 0.5 + 0.3), 0.2)
		for i in crew.size():
			var m: Person = crew[i]
			if m.mind == Person.Mind.ASSIST:
				m.stand_down()
			m.send_to_post(_crowd._spot_near(best.spot + Vector2(0.4 * float(i), 0.0), 0.15))
	var evacuating := _crowd.alarms.stage >= AlarmManager.Stage.EVACUATION
	for sq in squads:
		if sq.site != null:
			continue
		var crew := _living(sq)
		if crew.is_empty():
			continue
		var at_fire := false
		for m in crew:
			at_fire = at_fire or (m as Person).mind == Person.Mind.ASSIST
		if at_fire:
			continue
		var fire := _nearest_fire((crew[0] as Person).ground_pos) if not evacuating else null
		for m in crew:
			var p: Person = m
			if fire != null:
				_crowd.fires.enlist(p, fire)
			elif p.mind != Person.Mind.POST or p.anchor != p.post:
				p.send_to_post(p.post if p.post != Vector2.INF else p.ground_pos)


func _nearest_fire(from: Vector2) -> Structure:
	var fm := _crowd.fires
	if fm == null:
		return null
	var best: Structure = null
	for s: Structure in fm.fires.keys():
		if not is_instance_valid(s) or float(fm.fires[s].intensity) >= FireManager.ABANDON or fm.nearest_water(s.center()) == null:
			continue
		var d := s.center().distance_to(from)
		if d <= FireManager.RECRUIT_REACH and (best == null or d < best.center().distance_to(from)):
			best = s
	return best


func _dig(sq: Dictionary, delta: float) -> void:
	var site: Structure = sq.site
	if trapped_at(site) == 0:
		sq.site = null
		return
	var close := false
	for m in _living(sq):
		var p: Person = m
		close = close or (not p.has_goal() and p.ground_pos.distance_to(sq.spot) <= DIG_REACH)
	if not close:
		return
	sq.dig = float(sq.dig) + delta / DIG_TIME
	if float(sq.dig) < 1.0:
		return
	sq.dig = 0.0
	for t in trapped:
		if t.site == site:
			_free(t, sq.spot)
			break


func _free(t: Dictionary, at: Vector2) -> void:
	trapped.erase(t)
	var p: Person = t.p
	if not is_instance_valid(p):
		return
	var site: Structure = t.site
	p.inside = false
	p.visible = true
	p.ground_pos = _crowd._spot_near(at, 0.3)
	_field.add(p)
	# As ShelterManager throws people out of a building hit hard: out of the shelter's ways, and running.
	p.leave_shelter(false)
	p.panic(site.center(), site.footprint.size.length() * 0.5)
	rescued += 1
	if not _announced:
		_announced = true
		first_rescue.emit()


func _die(t: Dictionary) -> void:
	trapped.erase(t)
	var p: Person = t.p
	if not is_instance_valid(p):
		return
	var site: Structure = t.site
	p.inside = false
	p.visible = true
	p.ground_pos = site.center()
	_field.add(p)
	_field.kill(p, &"collapse", site.center())
	died += 1


## A dust plume and the count over each rubble with people under it. Into `ci`, world space.
func draw(ci: CanvasItem) -> void:
	var counts := {}
	for t in trapped:
		counts[t.site] = int(counts.get(t.site, 0)) + 1
	var now := float(Time.get_ticks_msec()) * 0.001
	for s in counts:
		var site: Structure = s
		var at := Iso.ground_to_screen(site.center())
		for k in 6:
			var rise := fmod(now * 0.4 + float(k) * 0.17, 1.0)
			var c := DUST
			c.a = 0.6 * (1.0 - rise)
			ci.draw_rect(Rect2((at + Vector2(sin(float(k) * 2.3) * 6.0, -4.0 - rise * 22.0)).round(), Vector2(2, 2)), c)
		var label := "%d" % int(counts[s])
		ci.draw_rect(Rect2(at + Vector2(-4, -36), Vector2(9, 10)), Color(0, 0, 0, 0.6))
		UiTheme.text(ci, at + Vector2(-2, -28), label, UiTheme.SIZE_SMALL, Color.WHITE)


func clear() -> void:
	trapped.clear()
	squads.clear()
	rescued = 0
	died = 0
```

`src/game/crowd/shelter_manager.gd`: in `step()`, replace the collapse branch

```gdscript
		if not is_instance_valid(s) or s.destroyed:
			for p in e.inside:
				if is_instance_valid(p):
					_exit(p, s)
					_field.kill(p, &"collapse", s.center())
			e.inside = []
			continue
```

with

```gdscript
		if not is_instance_valid(s) or s.destroyed:
			# Some of those inside are trapped under the rubble for the rescue squads (v0.07); the rest die.
			var trapped: Array = []
			for p in e.inside:
				if not is_instance_valid(p):
					continue
				if _crowd.rescue != null and is_instance_valid(s) and (p as Person).rng.randf() < RescueManager.TRAPPED_SHARE:
					trapped.append(p)
					continue
				_exit(p, s)
				_field.kill(p, &"collapse", s.center())
			if not trapped.is_empty():
				_crowd.rescue.trap(trapped, s)
			e.inside = []
			continue
```

`src/game/crowd/fire_manager.gd`, add after `_recruit()`:

```gdscript
## A rescue squad's soldier turns out to the fire on `s` (RescueManager, v0.07): on its crew whatever the brigade's
## numbers.
func enlist(p: Person, s: Structure) -> void:
	if not fires.has(s) or not is_instance_valid(p) or not p.is_alive():
		return
	p.assist(s, true)
	if p.mind != Person.Mind.ASSIST:
		return
	(fires[s].responders as Array).append(p)
	_go_to_water(p, s)
```

`src/game/crowd/crowd.gd`:
- `var rescue: RescueManager` next to `var escorts`.
- In `spawn()`, after the escorts line: `rescue = RescueManager.new().setup(self, _field)`.
- In `advance()`, after `escorts.step(delta)`: `if rescue != null: rescue.step(delta)`.
- In the `ResponseDrawer` inner class:
  - `_draw()`: in the over (not ground) branch, `if crowd.rescue != null and not ground: crowd.rescue.draw(self)`;
  - `showing()`: add `or (crowd.rescue != null and not crowd.rescue.trapped.is_empty())`.
- In `clear()`: `if rescue != null: rescue.clear()`, then `rescue = null`.

`src/game/mission.gd`, after the marshals banner:

```gdscript
	if _crowd.rescue != null:
		_crowd.rescue.first_rescue.connect(func(): _rules.banner.emit("SURVIVORS DUG FROM THE RUBBLE"))
```

`src/game/ui/behaviour_overlay.gd`, after the escorts line:

```gdscript
	if crowd.rescue != null:
		var digging := 0
		for sq in crowd.rescue.squads:
			if sq.site != null:
				digging += 1
		lines.append(["Rescue: %d squads, %d digging; trapped %d, saved %d, lost %d" % [crowd.rescue.squads.size(), digging,
			crowd.rescue.trapped.size(), crowd.rescue.rescued, crowd.rescue.died], Color("c0a070")])
```

- [ ] **Step 4:** Run the editor import, then the tests: `failures=0`.
  - `tests/test_shelter.gd` (around line 70) checks "a collapse kills those inside" with one person `r` in the tavern; now that one may be trapped instead. Replace
    ```gdscript
    	t.check(r != null and not r.is_alive() and crowd.killed_citizens == killed + 1, "a collapse kills those inside")
    ```
    with
    ```gdscript
    	var trapped := crowd.rescue.trapped_at(tavern) if crowd.rescue != null else 0
    	t.check(r != null and ((not r.is_alive() and crowd.killed_citizens == killed + 1) or (r.is_alive() and trapped == 1)),
    		"a collapse kills those inside, or traps them for the rescue squads (v0.07)")
    ```
  - `tests/test_plague.gd` releases people from shelters through `ShelterManager.release`, which is unaffected.
- [ ] **Step 5: Gates:** digest unchanged; FLOW `failures=0`. Report crowd_check (rescue squads now go to fires, so it may change).
- [ ] **Step 6: Commit:**

```bash
git add src/game/crowd/rescue_manager.gd src/game/crowd/rescue_manager.gd.uid tests/test_rescue.gd tests/test_rescue.gd.uid src/game/crowd/crowd.gd src/game/crowd/shelter_manager.gd src/game/crowd/fire_manager.gd src/game/mission.gd src/game/ui/behaviour_overlay.gd tests/test_shelter.gd tests/run_all.gd
git commit -m "feat: rescue squads dig out the trapped (v0.07 M4)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Milestone 5 — Scenario and wrap-up

### Task 5: The `soldiers` scenario

**Files:** Modify `tools/dev/behaviour_check.gd`.

**Interfaces:** Consumes `Crowd.marshals`, `Crowd.escorts`, `Crowd.rescue`, `RescueManager.trapped_at/rescued/died`, `BellNetwork.State`, `Person.corps`. The file already has `_force_cast(slot, at, dir)`, `_frames(n)` and `mission._crowd`; the `match scenario:` dispatch and the header comment list scenarios.

- [ ] **Step 1: Add the scenario.**
  - **Header comment:** under the scenario list, add:

```gdscript
##   soldiers (v0.07) each soldier role against doing without, --case= one of (Prepared):
##            marshals / nomarshals  an evacuation called at 20 s: escapes every 10 s to 60 s
##            escort / noescort      the bellkeeper killed 2 s into its climb: the bell's state every 2 s to 30 s
##            rescue / norescue      ten people in the cathedral, then it falls: trapped, saved, lost every 5 s to 60 s
```

  - **Difficulty:** in `_run()`, add `"soldiers"` to the list that defaults the tier to Prepared (the line `if tier == "" and scenario in [...]`).
  - **Dispatch:** add to the `match scenario:` block:

```gdscript
		"soldiers":
			await _soldiers(Battlefield.arg_value(args, "--case"))
```

  - **The function:** add next to `_powers`:

```gdscript
func _soldiers(which: String) -> void:
	var crowd: Crowd = mission._crowd
	# The "no" cases take the role away from its soldiers: they keep v0.06's ways.
	var off := {"nomarshals": Person.Corps.MARSHAL, "noescort": Person.Corps.ESCORT, "norescue": Person.Corps.RESCUE}
	if off.has(which):
		for p in crowd.soldiers:
			if p.corps == off[which]:
				p.corps = Person.Corps.NONE
		if which == "norescue":
			crowd.rescue.squads.clear()
	await _frames(20 * 60)
	match which:
		"marshals", "nomarshals":
			crowd.alarms.bell_rung = true
			crowd.alarms.update(AlarmManager.CITY_ALARM, 0, crowd._clock)
			crowd.alarms._city_at = crowd._clock - AlarmManager.REGROUP_SECONDS
			crowd.add_alarm(100.0)
			for k in 4:
				await _frames(10 * 60)
				print("BEHAVIOUR soldiers %s t=%d escaped=%d" % [which, 20 + 10 * (k + 1), crowd.escaped_count])
		"escort", "noescort":
			crowd.alarms.stage = AlarmManager.Stage.CONCERN
			crowd._on_stage(AlarmManager.Stage.LOCAL_EMERGENCY, "test")
			var killed := false
			for k in 15:
				await _frames(2 * 60)
				if not killed and crowd.bell.state == BellNetwork.State.CLIMBING:
					killed = true
					await _frames(2 * 60)
					crowd._field.kill(crowd.bell.keeper, &"test")
				print("BEHAVIOUR soldiers %s t=%d bell=%s keeper=%s rung=%s" % [which, 20 + 2 * (k + 1),
					BellNetwork.State.keys()[crowd.bell.state],
					"soldier" if is_instance_valid(crowd.bell.keeper) and crowd.bell.keeper.soldier else "citizen",
					crowd.alarms.bell_rung])
		"rescue", "norescue":
			var cathedral: Structure = null
			for s in crowd.shelters.shelters.keys():
				if s.role == &"temple":
					cathedral = s
			var n := 0
			for p in crowd.citizens:
				if n < 10 and p.is_alive() and not p.inside:
					crowd.shelters._enter(p, cathedral)
					(crowd.shelters.shelters[cathedral].inside as Array).append(p)
					n += 1
			cathedral.destroy(cathedral.center(), &"nova")
			for k in 12:
				await _frames(5 * 60)
				print("BEHAVIOUR soldiers %s t=%d trapped=%d saved=%d lost=%d" % [which, 20 + 5 * (k + 1),
					crowd.rescue.trapped.size(), crowd.rescue.rescued, crowd.rescue.died])
```

- [ ] **Step 2: Run each case** and record the output: `$G --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=soldiers --case=<case> 2>&1 | grep -E "BEHAVIOUR|SCRIPT ERROR"`, for marshals, nomarshals, escort, noescort, rescue and norescue. Expect, in order:
  - more escapes with marshals;
  - with an escort the keeper becomes a soldier and the bell rings, and without one it is SILENCED;
  - with rescue squads `saved` > 0, and without them all the trapped are `lost` by 45 s.

  Report all six outputs.
- [ ] **Step 3: Commit** `tools/dev/behaviour_check.gd`: "feat: the soldiers scenario (v0.07 M5)".

### Task 6: Bench, summary, notes (controller)

Done by the controller (it needs the machine idle and the results of every task):
- the mission bench against `kak-v0.06`, alternating;
- `docs/KAK_Version_0.07_Summary.md` (from the v0.06 summary, with the soldiers' roles and the measurements);
- the spec's "Changes made while executing";
- tags `kak-v007-m1` … `kak-v007-m5` and `kak-v0.07`; push.
