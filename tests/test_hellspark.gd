extends RefCounted
## Hellmouth Spark: a small door to the furnace opens on the ground for OPEN seconds; whatever is within RADIUS of the
## mouth catches, tick after tick -- people die by fire, wooden walls are alight, decor chars -- and the town keeps clear
## of it. A Mirrorfold's way in carries the door to its way out.


## A passage stub: every point is carried, and comes out six units down the map.
class Shift extends RefCounted:
	func carries(_p: Vector2) -> bool:
		return true

	func across(p: Vector2) -> Vector2:
		return p + Vector2(0.0, 6.0)


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


## A calm citizen standing at `at`, with nothing of his own to do.
static func _stand(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p.mind = Person.Mind.CALM
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._target = at


static func run(t) -> void:
	var b := PowerBook.get_power("hellspark")
	t.check(int(b.dp) == 1 and not PowerBook.is_quiet("hellspark") and String(b.aim) == "click"
		and PowerBook.authority_of("hellspark") == "passage" and PowerBook.icon("hellspark") != null
		and PowerBook.hud_icon("hellspark") != null and PowerBook.clip("hellspark") != null
		and Targeting.AREAS.has("hellspark") and is_equal_approx(float(Targeting.AREAS["hellspark"].r), HellmouthSparkFx.RADIUS)
		and Rules.POWER_KINDS.get("hellspark", []) == [&"fire"] and is_equal_approx(PowerBook.impact("hellspark"), HellmouthSparkFx.T_OPEN)
		and PowerBook.family("hellspark") != "",
		"Hellmouth Spark is Passage's 1 DP, loud, a click, its area the mouth's RADIUS, its kills fire, its impact the opening, with icons, clip and a family")
	t.check(is_equal_approx(HellmouthSparkFx.OPEN, 6.0) and is_equal_approx(HellmouthSparkFx.BURN_EVERY, 0.5) and is_equal_approx(HellmouthSparkFx.HEAT, 6.0),
		"the door stands open 6 s and burns every half second, 6 heat a tick")

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
	var R := HellmouthSparkFx.RADIUS
	var within: Person = crowd.citizens[0]
	var beyond: Person = crowd.citizens[1]
	var later: Person = crowd.citizens[2]
	_stand(within, at + Vector2(-0.6, 0.2))
	_stand(beyond, at + Vector2(R + 0.5, 0.0))
	_stand(later, at + Vector2(-9.0, 0.0))
	# Two sheds: one half a unit from the mouth, one three units off.
	var near_shed := env.add_structure(Rect2(at + Vector2(0.5, -0.3), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	var far_shed := env.add_structure(Rect2(at + Vector2(3.0, -0.3), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	t.check(is_equal_approx(near_shed.distance_to(at), 0.5) and far_shed.distance_to(at) > R, "a shed half a unit from the mouth, another three units off")
	crowd.fires.clear()
	var threats_before := crowd.threats.active_count()

	var fx: HellmouthSparkFx = FxTimeline.cast(load("res://src/fx/control/hellmouth_spark.gd"), ctx, at)
	t.check(fx.mouth == at and is_equal_approx(fx.busy, HellmouthSparkFx.T_OPEN)
		and is_equal_approx(fx.duration, HellmouthSparkFx.T_OPEN + HellmouthSparkFx.OPEN + 1.5),
		"cast on plain ground the mouth is the click; the god is busy while it opens, and the fx lasts the open, the shut and the scorch")
	fx._process(HellmouthSparkFx.T_OPEN - 0.05)
	t.check(within.is_alive() and not fx.open() and fx.burned == 0 and not crowd.fires.is_burning(near_shed),
		"nothing happens while the paving tears: the one standing on it still lives")
	fx._process(0.1)
	t.check(fx.open() and not within.is_alive() and within._kind == &"fire" and fx.burned == 1,
		"at T_OPEN the door is open and whoever stands within RADIUS of the mouth burns (kind fire)")
	t.check(beyond.is_alive(), "one standing half a unit beyond RADIUS is not touched")
	t.check(crowd.fires.is_burning(near_shed) and fx.lit >= 1, "the shed half a unit from the mouth is alight after the first tick (%d alight about the mouth)" % fx.lit)
	var lit_first := fx.lit
	t.check(not crowd.fires.is_burning(far_shed) and not far_shed.destroyed and is_equal_approx(far_shed.hp, far_shed.max_hp),
		"the shed three units off is neither alight nor touched")
	var fire_threats := crowd.threats.nearby(at, 0.0).filter(func(th: Dictionary) -> bool: return th.kind == &"fire")
	t.check(crowd.threats.active_count() == threats_before + 1 and fire_threats.size() == 1
		and is_equal_approx(float(fire_threats[0].radius), R + 0.5) and crowd.threats.unsafe(at + Vector2(R + 0.3, 0.0)),
		"the open mouth is a fire danger the town keeps clear of, RADIUS + 0.5 about it")
	# Three seconds on, one walks into it: the next tick takes him.
	fx._process(3.0)
	t.check(fx.open() and later.is_alive(), "three seconds in the door is still open")
	_stand(later, at + Vector2(-0.4, 0.3))
	fx._process(HellmouthSparkFx.BURN_EVERY)
	t.check(not later.is_alive() and later._kind == &"fire" and fx.burned == 2, "one who walks onto the mouth dies on the next tick")
	t.check(crowd.fires.is_burning(near_shed) and fx.lit == lit_first, "a burning building is counted once, however many ticks it takes")
	# The door shuts: nobody within RADIUS burns any more.
	var walker: Person = crowd.citizens[3]
	fx._process(HellmouthSparkFx.T_OPEN + HellmouthSparkFx.OPEN + 0.1 - fx.t)
	t.check(not fx.open(), "at T_OPEN + OPEN the door has shut")
	_stand(walker, at + Vector2(0.2, 0.1))
	fx._process(HellmouthSparkFx.BURN_EVERY)
	t.check(walker.is_alive() and fx.burned == 2, "once shut, one standing on the scorch is not harmed")
	fx.free()
	crowd.fires.clear()
	env.remove(near_shed)
	env.remove(far_shed)

	# --- Through a passage: cast on the way in, the door opens at the way out.
	var shift := Shift.new()
	field.portals.append(shift)
	var carried: HellmouthSparkFx = FxTimeline.cast(load("res://src/fx/control/hellmouth_spark.gd"), ctx, at)
	t.check(carried.mouth == at + Vector2(0.0, 6.0), "cast on an open passage's way in, the mouth opens at its way out")
	var there: Person = crowd.citizens[4]
	var here: Person = crowd.citizens[5]
	_stand(there, at + Vector2(0.0, 6.0) + Vector2(0.3, 0.0))
	_stand(here, at + Vector2(0.3, 0.0))
	carried._process(HellmouthSparkFx.T_OPEN + 0.05)
	t.check(not there.is_alive() and here.is_alive(), "and it burns there, not where the god clicked")
	carried.free()
	field.portals.clear()
	crowd.fires.clear()
	_done(made)
