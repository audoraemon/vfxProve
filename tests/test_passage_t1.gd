extends RefCounted
## Tier I of Passage. Skylift: a beam takes whoever stands in one place and sets them down in another, still about their
## day. Windfall: a load dropped from the sky crushes what is under it and blocks the way until the town clears it.


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


static func run(t) -> void:
	var lift := PowerBook.get_power("skylift")
	var fall := PowerBook.get_power("windfall")
	var problems := []
	for key: String in ["skylift", "windfall"]:
		if PowerBook.icon(key) == null or PowerBook.hud_icon(key) == null or PowerBook.clip(key) == null \
				or not Targeting.AREAS.has(key) or not Rules.POWER_KINDS.has(key) or PowerBook.family(key) == "" \
				or PowerBook.authority_of(key) != "passage" or int(PowerBook.get_power(key).dp) != 1:
			problems.append(key)
	t.check(problems.is_empty() and PowerBook.is_quiet("skylift") and String(lift.aim) == "two clicks"
		and not PowerBook.is_quiet("windfall") and is_equal_approx(PowerBook.impact("windfall"), WindfallFx.T_DROP) and String(fall.aim) == "drag",
		"Skylift (quiet, two clicks) and Windfall (loud, a drag, its impact the drop) are Passage's 1 DP, each with icons, clip, area, kinds and a family (%s)" % [problems])

	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())

	# --- Skylift
	var to := grid.nearest_walkable(at + Vector2(0.0, 8.0))
	var a: Person = crowd.citizens[0]
	var guard: Person = crowd.soldiers[0]
	var left: Person = crowd.citizens[1]
	a.mind = Person.Mind.CALM
	a.ground_pos = at + Vector2(0.6, 0.2)
	guard.ground_pos = at + Vector2(-0.5, -0.4)
	left.mind = Person.Mind.CALM
	left.ground_pos = at + Vector2(SkyliftFx.RADIUS + 1.0, 0.0)
	var bound := grid.nearest_walkable(at + Vector2(5.0, 0.0))
	a.set_goal(bound)
	var mind := a.mind
	t.check(SkyliftFx.lifted_at(field, at).has(a) and SkyliftFx.lifted_at(field, at).has(guard) and not SkyliftFx.lifted_at(field, at).has(left),
		"Skylift would take whoever stands in its circle, a soldier too, and nobody beside it")
	var beam: SkyliftFx = FxTimeline.cast(load("res://src/fx/control/skylift.gd"), ctx, at, {"to": to})
	beam._process(SkyliftFx.T_TAKE - 0.1)
	t.check(beam.taken == 0 and a.ground_pos.distance_to(at) < SkyliftFx.RADIUS, "the light stands on them; nobody is gone yet")
	beam._process(0.2)
	t.check(beam.taken == 2 and a.ground_pos.distance_to(to + Vector2(0.6, 0.2)) < 0.9 and guard.ground_pos.distance_to(to) < SkyliftFx.RADIUS + 0.9
		and left.ground_pos.distance_to(at) < SkyliftFx.RADIUS + 1.1, "then they stand at the other place, as they stood; the one beside it is where he was (%d)" % beam.taken)
	t.check(a.is_alive() and a.mind == mind and a.goal().distance_to(bound) < 0.6, "unhurt, of the same mind, still bound for where they were going")
	beam._process(2.0)
	beam.free()

	# --- Windfall
	# Open ground for a whole line: the first place about the market where all six segments can land.
	var spot := Vector2.INF
	for dy in range(-12, 13):
		for dx in range(-12, 13):
			if spot != Vector2.INF:
				break
			var cand := at + Vector2(float(dx), float(dy)) * 0.5
			var open := true
			for r in WindfallFx.rects(cand, Vector2(1, 0)):
				open = open and not env.blocked(r.get_center(), 0.0) and grid.walkable(r.get_center())
			if open and not env.blocked(cand + Vector2(0.0, 0.9), 0.0):
				spot = cand
	t.check(spot != Vector2.INF, "open ground for a line about the market")
	var under: Person = crowd.citizens[2]
	var beside: Person = crowd.citizens[3]
	under.ground_pos = spot + Vector2(0.2, 0.0)
	beside.ground_pos = spot + Vector2(0.0, -WindfallFx.KILL_R - 0.6)  # beside the line, not along it
	var shed := env.add_structure(Rect2(spot + Vector2(-0.3, 0.5), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	var hp := shed.hp
	var far_end := spot + Vector2(WindfallFx.LENGTH * 0.5 - 0.3, 0.0)
	t.check(grid.walkable(far_end), "the place is open ground before the fall")
	var fx: WindfallFx = FxTimeline.cast(load("res://src/fx/control/windfall.gd"), ctx, spot, {"dir": Vector2(1, 0)})
	fx._process(WindfallFx.T_DROP - 0.1)
	t.check(fx.piles.is_empty() and under.is_alive(), "Windfall: nothing has landed while it falls")
	fx._process(0.2)
	t.check(not under.is_alive() and under._kind == &"stone" and beside.is_alive() and fx.crushed == 1, "it crushes whoever stands under it, and nobody a step away")
	t.check(shed.hp < hp and not crowd.fires.is_burning(shed), "what it lands against is damaged, without a fire (%.0f of %.0f)" % [hp - shed.hp, hp])
	t.check(fx.standing() and fx.piles.size() == WindfallFx.SEGMENTS and fx.piles[0].role == &"windfall" and not grid.walkable(far_end),
		"and the line lies there, %d segments barring the way from end to end" % fx.piles.size())
	# The town clears it by hand: three at the pile take fifty seconds.
	var hands: Array[Person] = []
	for k in 3:
		var p: Person = crowd.citizens[4 + k]
		p.mind = Person.Mind.CALM
		p.ground_pos = spot + Vector2(-1.0 + float(k), -0.9)
		hands.append(p)
	beside.ground_pos = spot + Vector2(0.0, -WindfallFx.WORK_R - 3.0)  # only the three are at it
	var start := fx.work_left
	for k in 4:
		fx._process(1.0)
	t.check(fx.standing() and is_equal_approx(start - fx.work_left, 12.0), "three at the line work it down, a second each a second (%.0f left of %.0f)" % [fx.work_left, start])
	hands[0].mind = Person.Mind.PANIC
	var before := fx.work_left
	fx._process(1.0)
	t.check(is_equal_approx(before - fx.work_left, 2.0), "one who is frightened does not work")
	hands[0].mind = Person.Mind.CALM
	var was := fx.piles.size()
	for k in 20:
		if fx.standing():
			fx._process(1.0)
	t.check(fx.standing() and fx.piles.size() < was, "the line comes down from its ends as the work goes (%d of %d)" % [fx.piles.size(), was])
	for k in 60:
		if fx.standing():
			fx._process(1.0)
	t.check(fx.cleared and fx.piles.is_empty() and grid.walkable(far_end), "until it is cleared and the way is open again")
	fx.free()
	# The engineers cut one away as they do a thorn wall; one nobody tends stands its time and no longer.
	var second: WindfallFx = FxTimeline.cast(load("res://src/fx/control/windfall.gd"), ctx, spot + Vector2(0.0, 6.0), {"dir": Vector2(0, 1)})
	second._process(WindfallFx.T_DROP + 0.1)
	var is_job := false
	if crowd.engineers != null and second.standing():
		for job in crowd.engineers.jobs():
			is_job = is_job or second.piles.has(job.target)
	t.check(crowd.engineers == null or is_job, "a segment is a Clear job for the engineers")
	for person in crowd.citizens + crowd.soldiers:
		if person.is_alive() and person.ground_pos.distance_to(second.origin) < WindfallFx.CALL_R + 2.0:
			person.ground_pos = Vector2(-27.0, -27.0)
	second._process(WindfallFx.LIFE + 1.0)
	t.check(not second.standing(), "untended, it stands its time and is gone")
	second.free()
	_done(made)
