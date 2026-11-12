extends RefCounted
## Door to the Deep: a door opens in the ground and a whirlpool turns round it for a while. Everyone in the water wades
## at a third of their pace and is carried toward the door and round it; whoever comes to the door goes under. One who
## runs from it at the rim wades out; one deeper in does not. Every fire in the water goes out, every building in it
## takes slow water damage, and then it drains.

const FX := "res://src/fx/control/door_to_the_deep.gd"
## One frame of the tests' clock.
const STEP := 0.05


## A Mirrorfold stub: whatever is poured anywhere comes out six units down the map.
class Shift extends RefCounted:
	func carries(_p: Vector2) -> bool:
		return true

	func across(p: Vector2) -> Vector2:
		return p + Vector2(0, 6)


static func _setup() -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)
	crowd.spawn()
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return [crowd, env, grid, field, world, ctx]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


static func _about(value: float, expected: float, share: float) -> bool:
	return absf(value - expected) <= absf(expected) * share


## Stand `p` at `at` in `mind`, with nothing to walk to, an even pace and no water on him yet.
static func _stand(p: Person, at: Vector2, mind := Person.Mind.CALM) -> void:
	p.ground_pos = at
	p.mind = mind
	p.pace = 1.0
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._target = at
	p.statuses.erase(&"slow")
	p.walk_speed = p._mind_speed()


## Run the door's clock `seconds` on, a frame at a time.
static func _run(fx: DoorToTheDeepFx, seconds: float) -> void:
	for k in roundi(seconds / STEP):
		fx._process(STEP)


## Whether nothing stands within `r` of `c`.
static func _clear(env: EnvironmentField, c: Vector2, r: float) -> bool:
	for ring in range(0, 10):
		for spoke in 16:
			var q := c + Vector2.RIGHT.rotated(TAU * float(spoke) / 16.0) * r * float(ring) / 9.0
			if env.blocked(q, 0.3):
				return false
	return true


## Open ground for a whole whirlpool, nearest `from`: nothing standing within the water's reach and a step beyond.
static func _site(env: EnvironmentField, grid: WalkGrid, from: Vector2) -> Vector2:
	var room := DoorToTheDeepFx.RADIUS + 1.0
	var m := TownLayout.MAP.grow(-(room + 0.5))
	var best := Vector2.INF
	var x := m.position.x
	while x <= m.end.x:
		var y := m.position.y
		while y <= m.end.y:
			var c := Vector2(x, y)
			if (best == Vector2.INF or c.distance_to(from) < best.distance_to(from)) and grid.walkable(c) and _clear(env, c, room):
				best = c
			y += 1.0
		x += 1.0
	return best


## `seconds` of the door's clock in which each of `waders` still in the water wades straight away from the door at
## his own (slowed) pace, and the water does what it does. Returns whether `watch` was calm in the frame he got out.
static func _wade(fx: DoorToTheDeepFx, site: Vector2, waders: Array, seconds: float, watch: Person) -> bool:
	var calm_out := false
	var was_in := true
	for k in roundi(seconds / STEP):
		for p: Person in waders:
			var d := p.ground_pos.distance_to(site)
			if p.is_alive() and d <= DoorToTheDeepFx.RADIUS and d > 0.01:
				p.ground_pos += (p.ground_pos - site) / d * p.walk_speed * STEP
		fx._process(STEP)
		if watch != null and was_in and watch.ground_pos.distance_to(site) > DoorToTheDeepFx.RADIUS:
			was_in = false
			calm_out = watch.is_alive() and watch.mind == Person.Mind.CALM
	return calm_out


static func _water_threat(crowd: Crowd, at: Vector2) -> Dictionary:
	for z in crowd.threats.nearby(at, 0.5):
		if z.kind == &"water":
			return z
	return {}


static func run(t) -> void:
	var b := PowerBook.get_power("deep")
	var area: Dictionary = Targeting.AREAS.get("deep", {})
	t.check(int(b.dp) == 2 and not PowerBook.is_quiet("deep") and String(b.aim) == "click" and PowerBook.authority_of("deep") == "passage"
		and PowerBook.icon("deep") != null and PowerBook.hud_icon("deep") != null and PowerBook.clip("deep") != null
		and String(area.get("shape", "")) == "circle" and is_equal_approx(float(area.get("r", 0.0)), DoorToTheDeepFx.RADIUS)
		and (Rules.POWER_KINDS.get("deep", []) as Array).size() == 1 and Rules.POWER_KINDS["deep"][0] == &"pit"
		and is_equal_approx(PowerBook.impact("deep"), DoorToTheDeepFx.T_OPEN) and PowerBook.family("deep") != "",
		"Door to the Deep is Passage's 2 DP, loud, a click on a circle of RADIUS, its kills those the door takes (pit), its impact the door's opening, with icons, clip and a family")

	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var i := 0
	var park := Vector2(-27.0, -27.0)
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = park + Vector2(float(i % 20) * 0.3, float(i / 20) * 0.3)
		i += 1
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var T_OPEN := DoorToTheDeepFx.T_OPEN
	var SPREAD := DoorToTheDeepFx.SPREAD
	var SPAN := DoorToTheDeepFx.SPAN
	var DRAIN := DoorToTheDeepFx.DRAIN
	var TICK := DoorToTheDeepFx.TICK
	var RADIUS := DoorToTheDeepFx.RADIUS
	var MAW := DoorToTheDeepFx.MAW
	var SLOW := DoorToTheDeepFx.SLOW

	# --- The water's reach in time, and how hard it runs
	var fx: DoorToTheDeepFx = FxTimeline.cast(load(FX), ctx, at)
	t.check(fx.mouth == at and is_equal_approx(fx.busy, T_OPEN) and fx.reach(T_OPEN - 0.1) == 0.0
		and is_equal_approx(fx.reach(T_OPEN + SPREAD), RADIUS) and is_equal_approx(fx.reach(T_OPEN + SPAN), RADIUS)
		and fx.reach(T_OPEN + SPAN + DRAIN + 0.01) == 0.0 and fx.reach(T_OPEN + SPAN + DRAIN * 0.5) < RADIUS,
		"the door is the click; no water before it opens, a circle of RADIUS once it has spread and for the span, none after the drain")
	t.check(is_equal_approx(DoorToTheDeepFx.pull_speed(RADIUS), DoorToTheDeepFx.PULL_RIM)
		and is_equal_approx(DoorToTheDeepFx.pull_speed(0.0), DoorToTheDeepFx.PULL_CORE)
		and is_equal_approx(DoorToTheDeepFx.pull_speed(RADIUS * 0.5), (DoorToTheDeepFx.PULL_RIM + DoorToTheDeepFx.PULL_CORE) * 0.5)
		and DoorToTheDeepFx.PULL_CORE > DoorToTheDeepFx.PULL_RIM,
		"the torrent draws in at PULL_RIM at the rim, rising evenly to PULL_CORE at the door")
	t.check(fx.force(T_OPEN - 0.1) == 0.0 and is_equal_approx(fx.force(T_OPEN), DoorToTheDeepFx.FIRST_REACH / RADIUS)
		and is_equal_approx(fx.force(T_OPEN + SPREAD), 1.0) and is_equal_approx(fx.force(T_OPEN + SPAN + DRAIN * 0.5), 0.5)
		and fx.force(T_OPEN + SPAN + DRAIN + 0.01) == 0.0,
		"it runs weaker while the water spreads and drains: by the share of RADIUS the water reaches")
	t.check(MAW <= DoorToTheDeepFx.FIRST_REACH, "the water covers the maw the moment the door opens")

	# --- People in the water wade
	var wader: Person = crowd.citizens[0]
	_stand(wader, at + Vector2(2.6, 0.0))
	var normal := wader.walk_speed
	var dry: Person = crowd.citizens[1]
	_stand(dry, at + Vector2(RADIUS + 0.5, 0.0))
	var dry_normal := dry.walk_speed
	var guard: Person = crowd.soldiers[0]
	guard.ground_pos = at + Vector2(0.0, -2.6)
	guard.walk_speed = guard._mind_speed()
	var guard_normal := guard.walk_speed
	# --- Buildings in the water: a burning shed within reach, a burning one well beyond it, and a dry one by the door.
	var shed := env.add_structure(Rect2(at + Vector2(0.6, -1.6), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	var far_shed := env.add_structure(Rect2(at + Vector2(6.0, -0.3), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	var soaked := env.add_structure(Rect2(at + Vector2(-1.0, -0.3), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	crowd.fires.ignite(shed, 0.6)
	crowd.fires.ignite(far_shed, 0.6)
	var hp := soaked.hp

	fx._process(T_OPEN - 0.1)
	t.check(is_equal_approx(wader.walk_speed, normal) and wader.pace_holds.is_empty() and crowd.fires.is_burning(shed)
		and is_equal_approx(soaked.hp, hp) and wader.ground_pos == at + Vector2(2.6, 0.0) and fx.caught == 0,
		"before the door opens nobody wades, nobody is carried, no fire is touched, no wall is wet")
	t.check(_water_threat(crowd, at).is_empty(), "nor is the place a danger yet")
	fx._process(0.15)
	var threat := _water_threat(crowd, at)
	t.check(not threat.is_empty() and is_equal_approx(float(threat.get("severity", 0.0)), 0.6)
		and is_equal_approx(float(threat.get("radius", 0.0)), RADIUS) and threat.get("at", Vector2.INF) == at,
		"from the moment the door opens the whole circle is a real danger the town knows: a water threat of 0.6 on it")
	fx._process(SPREAD + TICK - 0.05)
	t.check(wader.is_alive() and not wader.pace_holds.is_empty() and _about(wader.walk_speed, SLOW * normal, 0.1),
		"once the water has spread, a citizen in it walks at a third of his pace (%.2f of %.2f)" % [wader.walk_speed, normal])
	t.check(guard.is_alive() and _about(guard.walk_speed, SLOW * guard_normal, 0.1), "a soldier in it wades as slowly")
	t.check(is_equal_approx(dry.walk_speed, dry_normal) and dry.pace_holds.is_empty(), "one standing half a step beyond the water keeps his pace")
	wader.ground_pos = at + Vector2(RADIUS + 1.0, 0.0)
	guard.ground_pos = at + Vector2(0.0, -RADIUS - 1.0)
	fx._process(TICK)
	t.check(is_equal_approx(wader.walk_speed, normal) and wader.pace_holds.is_empty() and is_equal_approx(guard.walk_speed, guard_normal)
		and guard.pace_holds.is_empty(), "whoever gets out of the water has his pace back at once")

	# --- Fires and walls, five seconds into the flood
	fx._process(5.0 - SPREAD - 2.0 * TICK)
	var ticks := 5.0 / TICK
	t.check(not crowd.fires.is_burning(shed) and fx.doused == 1, "a burning shed within reach is out after five seconds of water")
	t.check(crowd.fires.is_burning(far_shed), "one burning six units off still burns")
	t.check(_about(hp - soaked.hp, DoorToTheDeepFx.SOAK * ticks, 0.2) and not soaked.destroyed,
		"a shed by the door has taken SOAK a tick of water damage (%.1f for %.0f ticks)" % [hp - soaked.hp, ticks])
	t.check(not crowd.fires.is_burning(soaked), "water sets nothing alight")
	t.check(dry.ground_pos == at + Vector2(RADIUS + 0.5, 0.0) and dry.is_alive(), "the one half a step beyond the water was never moved")
	fx.free()
	crowd.fires.clear()
	for p: Person in [wader, dry, guard]:
		p.ground_pos = park

	# --- The torrent, on open ground
	var site := _site(env, grid, at)
	t.check(site != Vector2.INF, "open ground for a whole whirlpool")
	var on_door: Person = crowd.citizens[2]
	var close: Person = crowd.citizens[3]
	var two: Person = crowd.citizens[4]
	var beyond: Person = crowd.citizens[5]
	var indoors: Person = crowd.citizens[6]
	var probe: Person = crowd.citizens[7]
	var late: Person = crowd.citizens[8]
	var after: Person = crowd.citizens[9]
	var sentry: Person = crowd.soldiers[1]
	_stand(on_door, site)
	_stand(close, site + Vector2(1.0, 0.0))
	_stand(two, site + Vector2(0.0, 2.0))
	_stand(beyond, site + Vector2(-RADIUS - 0.5, 0.0))
	_stand(indoors, site + Vector2(0.0, -2.0))
	indoors.inside = true
	var indoors_pace := indoors.walk_speed
	sentry.ground_pos = site + Vector2(-2.1, -2.1)
	sentry.statuses.erase(&"slow")
	var sentry_mind := sentry.mind
	var sentry_from := sentry.ground_pos.distance_to(site)
	var alive := crowd.alive_citizens()
	var whirl: DoorToTheDeepFx = FxTimeline.cast(load(FX), ctx, site)
	whirl._process(T_OPEN - 0.1)
	t.check(on_door.is_alive() and on_door.ground_pos == site and close.ground_pos == site + Vector2(1.0, 0.0) and whirl.caught == 0
		and whirl.drowned == 0, "while the door is opening nobody is carried and nobody is taken, not even one standing on it")
	whirl._process(0.15)
	t.check(not on_door.is_alive() and on_door._kind == &"pit" and whirl.drowned == 1 and whirl.t <= T_OPEN + 0.051,
		"one standing on the door when it opens is under at once: dragged down through it (a pit death)")
	_run(whirl, 1.5 - 0.05)
	var rel := two.ground_pos - site
	var turned := Vector2(0.0, 2.0).angle_to(rel)
	t.check(two.is_alive() and rel.length() < 2.0 - 0.15 and turned > 0.05 and two.mind == Person.Mind.CALM,
		"a calm citizen standing still two steps from the door is nearer it a second and a half after it opens, and has been turned round it, clockwise on screen, his mind his own (%.2f from it, %.2f round)" % [rel.length(), turned])
	t.check(not two.pace_holds.is_empty(), "and he wades: the water slows him as it carries him")
	_run(whirl, 1.5)
	t.check(sentry.is_alive() and sentry.ground_pos.distance_to(site) < sentry_from - 0.15 and sentry.mind == sentry_mind,
		"a soldier standing in it is carried in as well, and keeps his post in mind (%.2f from it, was %.2f)"
			% [sentry.ground_pos.distance_to(site), sentry_from])
	sentry.ground_pos = park
	_run(whirl, 1.0)
	t.check(not close.is_alive() and close._kind == &"pit", "one standing still a step from the door is under within four seconds of its opening")
	t.check(not two.is_alive() and whirl.drowned == 3 and crowd.alive_citizens() == alive - 3,
		"so is the one who stood two steps off; the door counts each it takes (%d)" % whirl.drowned)
	# At full flood: the carry's pace, measured on one set down three steps out.
	_stand(probe, site + Vector2(3.0, 0.0))
	_run(whirl, 1.0)
	var probe_rel := probe.ground_pos - site
	var drawn := 3.0 - probe_rel.length()
	var swung := Vector2(3.0, 0.0).angle_to(probe_rel)
	t.check(drawn >= DoorToTheDeepFx.pull_speed(3.0) - 0.01 and drawn <= DoorToTheDeepFx.pull_speed(3.0 - drawn) + 0.01,
		"at full flood one three steps out is drawn in at the torrent's pace there, quickening as he nears (%.2f in a second)" % drawn)
	t.check(swung >= DoorToTheDeepFx.SWIRL / 3.0 - 0.01 and swung <= DoorToTheDeepFx.SWIRL / (3.0 - drawn) + 0.01,
		"and carried round the door at SWIRL a second (%.2f radians in that second)" % swung)
	# Time standing still: the torrent with it.
	var held := probe.ground_pos
	crowd.freeze(5.0)
	_run(whirl, 0.5)
	t.check(probe.ground_pos == held and probe.is_alive(), "while time stands still in the town the water carries nobody")
	crowd._freeze_left = 0.0
	_run(whirl, 0.5)
	t.check(probe.ground_pos.distance_to(site) < held.distance_to(site), "and carries them again when it runs on")
	probe.ground_pos = park
	t.check(whirl.caught == 5, "it had hold of five in all: the four in the water and the one set down in it (%d)" % whirl.caught)
	# The drain: one set down near the rim a second before the span ends.
	_run(whirl, T_OPEN + SPAN - 1.0 - whirl.t)
	_stand(late, site + Vector2(3.6, 0.0))
	var late_pace := late.walk_speed
	_run(whirl, 0.6)
	t.check(not late.pace_holds.is_empty() and _about(late.walk_speed, SLOW * late_pace, 0.1), "one in the water at the end of the span is wading still")
	_run(whirl, T_OPEN + SPAN + DRAIN + 0.1 - whirl.t)
	t.check(whirl.reach(whirl.t) == 0.0 and late.is_alive() and is_equal_approx(late.walk_speed, late_pace) and late.pace_holds.is_empty(),
		"when it drains, one the water ran back from has his pace back and no slow on him")
	var late_at := late.ground_pos
	_stand(after, site + Vector2(0.3, 0.0))
	_run(whirl, 0.1)
	t.check(after.is_alive() and after.ground_pos == site + Vector2(0.3, 0.0) and late.ground_pos == late_at and whirl.drowned == 3,
		"after the drain nobody is moved any more, and one standing where the door was is safe")
	t.check(beyond.is_alive() and beyond.ground_pos == site + Vector2(-RADIUS - 0.5, 0.0) and beyond.pace_holds.is_empty(),
		"one standing half a step beyond the rim was never moved, the whole while")
	t.check(indoors.is_alive() and indoors.ground_pos == site + Vector2(0.0, -2.0) and indoors.pace_holds.is_empty()
		and is_equal_approx(indoors.walk_speed, indoors_pace), "one inside a building two steps from the door is not carried, slowed or taken")
	indoors.inside = false
	whirl.free()
	for p: Person in [beyond, indoors, late, after]:
		p.ground_pos = park

	# --- Who gets out: each wades straight away from the door at his own slowed pace; the water does the rest.
	# The strollers first, on their own: a drowning frightens those who see it, and a frightened man runs.
	var stroller: Person = crowd.citizens[10]
	var deep_stroller: Person = crowd.citizens[11]
	var runner: Person = crowd.citizens[12]
	var deep_runner: Person = crowd.citizens[13]
	var frantic: Person = crowd.citizens[15]
	var deep_frantic: Person = crowd.citizens[16]
	var pull := func(d: float) -> float: return DoorToTheDeepFx.pull_speed(d)
	var out := func(p: Person) -> bool:
		return p.is_alive() and p.ground_pos.distance_to(site) > RADIUS and p.pace_holds.is_empty() and is_equal_approx(p.walk_speed, p._mind_speed())
	var under := func(p: Person) -> bool: return not p.is_alive() and p._kind == &"pit"
	var second: DoorToTheDeepFx = FxTimeline.cast(load(FX), ctx, site)
	_run(second, T_OPEN + SPREAD)
	_stand(stroller, site + Vector2(-3.9, 0.0))
	_stand(deep_stroller, site + Vector2(0.0, -3.2))
	var stroll_pace := stroller.walk_speed
	_run(second, 0.15)
	t.check(not stroller.pace_holds.is_empty() and not deep_stroller.pace_holds.is_empty(), "the two strollers are wading")
	t.check(pull.call(RADIUS) < SLOW * stroll_pace and pull.call(3.2) > SLOW * stroll_pace,
		"the pull is less than a stroller's wading pace at the rim, and more most of a step in (wading %.3f; pull %.2f at the rim, %.2f at 3.2)"
			% [SLOW * stroll_pace, pull.call(RADIUS), pull.call(3.2)])
	var calm_out := _wade(second, site, [stroller, deep_stroller], 18.0, stroller)
	t.check(out.call(stroller) and calm_out, "a calm stroller who walks away from just inside the rim wades out alive, strolling still, and has his pace back")
	t.check(under.call(deep_stroller), "one who only strolls away from most of a step inside the rim is not fast enough: the door has him")
	second.free()
	stroller.ground_pos = park
	# The runners: fleeing, and in a panic.
	var runs: DoorToTheDeepFx = FxTimeline.cast(load(FX), ctx, site)
	_run(runs, T_OPEN + SPREAD)
	_stand(runner, site + Vector2(3.8, 0.0), Person.Mind.FLEE)
	_stand(deep_runner, site + Vector2(0.0, 2.0), Person.Mind.FLEE)
	_stand(frantic, site + Vector2(2.0, 0.0).rotated(PI * 0.25), Person.Mind.PANIC)
	_stand(deep_frantic, site + Vector2(-1.2, 0.0).rotated(PI * 0.25), Person.Mind.PANIC)
	var runners: Array = [runner, deep_runner, frantic, deep_frantic]
	var run_pace := runner.walk_speed
	var panic_pace := frantic.walk_speed
	_run(runs, 0.15)
	var all_wading := true
	for p: Person in runners:
		all_wading = all_wading and p.is_alive() and not p.pace_holds.is_empty()
	t.check(all_wading, "the four runners are wading")
	t.check(pull.call(2.0) > SLOW * run_pace and pull.call(2.0) < SLOW * panic_pace and pull.call(1.2) > SLOW * panic_pace,
		"two steps from the door the pull is more than a fleeing pace in the water and less than a panicked one; near the door it is more than anyone's (wading %.2f, %.2f; pull %.2f at 2, %.2f at 1.2)"
			% [SLOW * run_pace, SLOW * panic_pace, pull.call(2.0), pull.call(1.2)])
	_wade(runs, site, runners, 18.0, null)
	t.check(out.call(runner) and is_equal_approx(runner.walk_speed, run_pace), "one who flees from just inside the rim wades out alive, and has his pace back")
	t.check(under.call(deep_runner), "one who flees from two steps off the door does not get out")
	t.check(out.call(frantic) and is_equal_approx(frantic.walk_speed, panic_pace), "one who runs in a panic from two steps off the door does get out, alive")
	t.check(under.call(deep_frantic), "one who runs in a panic from little more than a step off the door does not: that near it, nobody gets out")
	runs.free()
	for p: Person in runners:
		p.ground_pos = park

	# --- A wall in the way: a long shed across the way in, between the door and one standing three steps north of it
	# (long, because the water turns him as it draws him in: a short one he is simply carried past).
	var walled: Person = crowd.citizens[17]
	var wall := env.add_structure(Rect2(site + Vector2(-0.6, -2.3), Vector2(3.2, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	var third: DoorToTheDeepFx = FxTimeline.cast(load(FX), ctx, site)
	_run(third, T_OPEN + SPREAD)
	_stand(walled, site + Vector2(0.0, -3.0))
	t.check(not env.blocked(walled.ground_pos) and env.blocked(site + Vector2(0.0, -2.0)), "the shed stands across his way in, and he stands clear of it")
	var through_wall := false
	for k in roundi(9.0 / STEP):
		third._process(STEP)
		through_wall = through_wall or env.blocked(walled.ground_pos) or wall.footprint.has_point(walled.ground_pos)
	var walled_d := walled.ground_pos.distance_to(site)
	t.check(walled.is_alive() and not through_wall and not wall.destroyed and walled_d < 3.0 - 0.1 and (walled.ground_pos - site).y < -2.3,
		"one with a shed between him and the door is never dragged into it or through it: the water carries him up to it and holds him against its far side, alive, while it stands (%.2f from the door)" % walled_d)
	third.free()
	walled.ground_pos = park

	# --- Cut short
	var cut_one: Person = crowd.citizens[14]
	_stand(cut_one, site + Vector2(3.5, 0.0))
	var cut_pace := cut_one.walk_speed
	var cut: DoorToTheDeepFx = FxTimeline.cast(load(FX), ctx, site)
	_run(cut, T_OPEN + SPREAD + 0.1)
	var was_slow := not cut_one.pace_holds.is_empty()
	cut.end_now()
	var cut_at := cut_one.ground_pos
	cut._process(STEP)
	t.check(was_slow and cut_one.is_alive() and cut_one.pace_holds.is_empty() and is_equal_approx(cut_one.walk_speed, cut_pace)
		and cut_one.ground_pos == cut_at, "cut short, it leaves nobody slowed and carries nobody on")
	cut_one.ground_pos = park

	# --- One in the water freed mid-span (they left the town: Crowd.escape, or another power took them "gone"): dropped
	# at the next tick without an error, everyone else still held.
	var freed: Person = crowd.citizens[18]
	var stays: Person = crowd.citizens[19]
	_stand(freed, site + Vector2(3.5, 0.0))
	_stand(stays, site + Vector2(-3.5, 0.0))
	var drop: DoorToTheDeepFx = FxTimeline.cast(load(FX), ctx, site)
	_run(drop, T_OPEN + SPREAD + 0.1)
	var freed_id := freed.get_instance_id()
	t.check(drop.soaks(freed) and drop.soaks(stays), "(both in the water)")
	crowd.citizens.erase(freed)
	field.remove(freed)
	freed.free()
	_run(drop, TICK + STEP)
	t.check(not drop._soaked.has(freed_id) and drop.soaks(stays) and is_equal_approx(stays.pace_hold(), SLOW),
		"one freed in the water is dropped at the next tick without an error; the others are still held")
	drop.end_now()
	t.check(drop.finished and stays.pace_holds.is_empty(), "and its end lets the rest go")
	drop.free()
	stays.ground_pos = park

	# --- Freed without _finish (Battlefield.clear_effects() on a restart queue_frees it): nobody is left slowed and the
	# roar is stopped, with no error; its end after that changes nothing.
	var torn_one: Person = crowd.citizens[14]
	_stand(torn_one, site + Vector2(3.5, 0.0))
	var torn_pace := torn_one.walk_speed
	var torn: DoorToTheDeepFx = FxTimeline.cast(load(FX), ctx, site)
	_run(torn, T_OPEN + SPREAD + 0.1)
	var roar := AudioStreamPlayer2D.new()
	roar.set_meta(&"cue", &"tn_wind")
	torn._roar = roar
	t.check(not torn_one.pace_holds.is_empty(), "(one slowed in the water)")
	torn._exit_tree()
	t.check(torn_one.is_alive() and torn_one.pace_holds.is_empty() and is_equal_approx(torn_one.walk_speed, torn_pace)
		and torn._soaked.is_empty() and torn._roar == null,
		"freed without its end, nobody is left slowed and the roar is stopped")
	torn.end_now()
	t.check(torn.finished and torn_one.pace_holds.is_empty(), "and its end after that changes nothing")
	torn.free()
	roar.free()
	torn_one.ground_pos = park

	# --- Through a Mirrorfold
	field.portals.append(Shift.new())
	var carried: DoorToTheDeepFx = FxTimeline.cast(load(FX), ctx, at)
	t.check(carried.mouth == at + Vector2(0, 6), "poured onto a Mirrorfold's way in, the door opens at its way out")
	field.portals.clear()
	carried.free()
	_done(made)
