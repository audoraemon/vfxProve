extends RefCounted
## Tier I of Passage: the book entries, and Windfall -- a load dropped from the sky crushes what is under it and blocks the
## way until the town clears it. Skylift's own checks are tests/test_skylift.gd.


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

	# --- The cargoes (Q/E modes)
	var modes := []
	for m in fall.get("modes", []):
		modes.append(String(m.key))
	t.check(modes == ["stone", "oil", "goods", "plague"], "the book offers STONE, OIL, GOODS and PLAGUE, in that order (%s)" % [modes])
	t.check(field.portals.is_empty() and field.through(spot) == spot, "with no passage open, a load comes down where it is dropped")
	env.remove(shed)
	var used: Array = [under, beside, crowd.citizens[4], crowd.citizens[5], crowd.citizens[6]]
	var seg0 := spot + Vector2(-WindfallFx.LENGTH * 0.5 + WindfallFx.LENGTH * 0.5 / float(WindfallFx.SEGMENTS), 0.0)

	# OIL: the barrels burst; whoever is under them burns, nothing is set down, and the line burns for a while.
	_clear_about(crowd, spot)
	var oil_under: Person = _fresh(crowd, used, 1)[0]
	var oil_beside: Person = _fresh(crowd, used, 1)[0]
	oil_under.ground_pos = spot + Vector2(0.2, 0.0)
	oil_beside.ground_pos = spot + Vector2(0.0, -WindfallFx.KILL_R - 0.6)
	# A shed just out of the burst's reach (HIT_R) but within the fire's (LIGHT_R) of the first segment.
	var oil_shed := env.add_structure(Rect2(seg0 + Vector2(-0.3, 0.8), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	var oil: WindfallFx = FxTimeline.cast(load("res://src/fx/control/windfall.gd"), ctx, spot, {"dir": Vector2(1, 0), "mode": "oil"})
	oil._process(WindfallFx.T_DROP - 0.1)
	t.check(oil.cargo == "oil" and oil_under.is_alive() and not oil.burning(), "OIL: nothing burns while the barrels fall")
	oil._process(0.2)
	t.check(not oil_under.is_alive() and oil_under._kind == &"fire" and oil_beside.is_alive() and oil.burned == 1,
		"the barrels burst on whoever stands under them: dead by fire, and nobody a step away")
	t.check(oil.piles.is_empty() and grid.walkable(far_end) and oil.burning(), "nothing is set down -- the way stays open -- but the line burns")
	t.check(not crowd.fires.is_burning(oil_shed), "a shed just beyond the burst is not yet alight")
	oil._process(WindfallFx.LIGHT_EVERY)
	t.check(crowd.fires.is_burning(oil_shed), "within %.0f s the burning line has set it alight" % (WindfallFx.LIGHT_EVERY + 0.1))
	oil._process(WindfallFx.T_DROP + 5.0 - oil.t)
	var walker: Person = _fresh(crowd, used, 1)[0]
	walker.ground_pos = spot
	oil._process(0.3)
	t.check(not walker.is_alive() and walker._kind == &"fire" and oil.burned == 2, "one who walks onto the line five seconds later burns")
	oil._process(WindfallFx.OIL_BURN)
	var late: Person = _fresh(crowd, used, 1)[0]
	late.ground_pos = spot
	oil._process(0.5)
	t.check(not oil.burning() and late.is_alive(), "after %.0f s the fire is out and the line is safe to cross" % WindfallFx.OIL_BURN)
	oil.free()
	env.remove(oil_shed)

	# GOODS: silk and wine nobody can resist. The calm nearby come to it, and carry nothing away.
	_clear_about(crowd, spot)
	var drawn := _fresh(crowd, used, 4)
	for k in drawn.size():
		drawn[k].mind = Person.Mind.CALM
		drawn[k].ground_pos = spot + Vector2(-1.5 + float(k), -3.0)  # within LOOT_R, well off the line
	var looters := _fresh(crowd, used, 3)
	for k in looters.size():
		looters[k].mind = Person.Mind.CALM
		looters[k].ground_pos = spot + Vector2(-1.0 + float(k), -0.9)  # at the line, as the three hands were
	var goods: WindfallFx = FxTimeline.cast(load("res://src/fx/control/windfall.gd"), ctx, spot, {"dir": Vector2(1, 0), "mode": "goods"})
	goods._process(WindfallFx.T_DROP + 0.1)
	t.check(goods.standing() and goods.piles.size() == WindfallFx.SEGMENTS and not grid.walkable(far_end), "GOODS: the wares land and bar the way as stone does")
	var came := 0
	for p in drawn:
		var near_line := false
		for c in goods.centres():
			near_line = near_line or p.goal().distance_to(c) <= WindfallFx.WORK_R
		if p.mind == Person.Mind.OBSERVE and near_line:
			came += 1
	t.check(came == drawn.size() and goods.looters >= drawn.size(), "the calm within %.0f are drawn to stand at the line (%d of %d)" % [WindfallFx.LOOT_R, came, drawn.size()])
	var untouched := goods.work_left
	for k in 4:
		goods._process(1.0)
	t.check(goods.standing() and is_equal_approx(goods.work_left, untouched), "three at the wares carry nothing away: the work left does not fall")
	goods.end_now()
	goods.free()

	# PLAGUE: a grain cart from a dead village. Whoever works at clearing it catches it.
	_clear_about(crowd, spot)
	var hands3 := _fresh(crowd, used, 3)
	for k in hands3.size():
		hands3[k].mind = Person.Mind.CALM
		hands3[k].ground_pos = spot + Vector2(-1.0 + float(k), -0.9)
	var plague: WindfallFx = FxTimeline.cast(load("res://src/fx/control/windfall.gd"), ctx, spot, {"dir": Vector2(1, 0), "mode": "plague"})
	plague._process(WindfallFx.T_DROP + 0.1)
	plague._process(2.0)
	var sick := 0
	for p in hands3:
		if p.sick_left > 0.0:
			sick += 1
	t.check(sick == 3 and plague.infected == 3 and plague.work_left < WindfallFx.CLEAR_WORK,
		"PLAGUE: within two seconds of work the three at the line are sick, and still at work (%d sick)" % sick)
	plague.end_now()
	plague.free()

	# A mode the book does not know lands as STONE.
	_clear_about(crowd, spot)
	var odd: WindfallFx = FxTimeline.cast(load("res://src/fx/control/windfall.gd"), ctx, spot, {"dir": Vector2(1, 0), "mode": "gravel"})
	odd._process(WindfallFx.T_DROP + 0.1)
	t.check(odd.cargo == "stone" and odd.piles.size() == WindfallFx.SEGMENTS and not grid.walkable(far_end), "an unknown cargo is STONE")
	odd.end_now()
	odd.free()

	# A passage open under the line carries the whole load through to its other side.
	var shift := Vector2(0, 6)
	field.portals.append(Shift.new())
	var carried: WindfallFx = FxTimeline.cast(load("res://src/fx/control/windfall.gd"), ctx, spot, {"dir": Vector2(1, 0)})
	carried._process(WindfallFx.T_DROP + 0.1)
	var along := true
	for c in carried.centres():
		along = along and c.distance_to(spot + shift) <= WindfallFx.LENGTH * 0.5 + 0.01 and is_equal_approx(c.y, spot.y + shift.y)
	t.check(carried.landing_origin == spot + shift and along and grid.walkable(far_end),
		"dropped onto a passage, the line lands at its far side, the same way round (%d segments there, none here)" % carried.piles.size())
	field.portals.clear()
	carried.end_now()
	carried.free()
	_done(made)


## The next `n` living, healthy citizens not yet used by a check.
static func _fresh(crowd: Crowd, used: Array, n: int) -> Array[Person]:
	var out: Array[Person] = []
	for p in crowd.citizens:
		if out.size() >= n:
			break
		if p.is_alive() and p.sick_left <= 0.0 and not used.has(p):
			out.append(p)
			used.append(p)
	return out


## Everyone alive near `at` is sent off to the corner, so a check starts with nobody about.
static func _clear_about(crowd: Crowd, at: Vector2) -> void:
	for person in crowd.citizens + crowd.soldiers:
		if person.is_alive() and person.ground_pos.distance_to(at) < WindfallFx.LOOT_R + 2.0:
			person.ground_pos = Vector2(-27.0, -27.0)


## A stand-in passage: carries everything, six units down the map.
class Shift extends RefCounted:
	func carries(_p: Vector2) -> bool:
		return true

	func across(p: Vector2) -> Vector2:
		return p + Vector2(0, 6)
