extends RefCounted
## Gravecall (Death, Tier II): no body needed. The first click calls three pale spirits up out of the ground, the second
## sends them; they drift through walls to the second click and haunt a circle of 3 there for 20 s (everyone within 3
## flees each second); a soldier a spirit passes through is frozen for 3 s, once per soldier per spirit.

const RD := preload("res://tests/test_raise_dead.gd")
const DT := 0.05


static func _cast(made: Array, from: Vector2, to: Vector2) -> GravecallFx:
	return FxTimeline.cast(GravecallFx, made[5], from, {"to": to}) as GravecallFx


static func run(t) -> void:
	var made := RD._setup()
	_rise(t, made)
	_wall(t, made)
	_flee(t, made)
	_freeze(t, made)
	_gone(t, made)
	_exit(t, made)
	RD._done(made)


## A walkable spot with nobody near, and one `dx` east of it that is walkable too.
static func _spot(made: Array) -> Vector2:
	return RD._empty(made)


## "three wraiths rise with no body needed"
static func _rise(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := _spot(made)
	t.check(crowd.remains.all().is_empty(), "no body anywhere")
	var fx := _cast(made, at, at + Vector2(6.0, 0.0))
	RD._run(fx, GravecallFx.T_RISE + 0.1)
	var up := fx.visitors.living()
	t.check(up.size() == GravecallFx.SPIRITS and up.all(func(a: Animal) -> bool: return a.breed == Animal.Breed.WRAITH),
		"three wraiths rise with no body needed (%d)" % up.size())
	t.check(GravecallFx.HAUNT_R == DeathParts.SPIRIT_FRIGHT_R, "the haunt reaches as far as a spirit's fright")
	fx.end_now()


## "they cross a wall to the second click"
static func _wall(t, made: Array) -> void:
	RD._clear_all(made)
	var env: EnvironmentField = made[1]
	var house: Structure = null
	for s in env.structures():
		if not s.destroyed and not s.walkable and s.kind == Structure.Kind.HOUSE:
			house = s
			break
	t.check(house != null, "a house to cross")
	if house == null:
		return
	var from := Vector2(house.footprint.position.x - 2.5, house.center().y)
	var to := Vector2(house.footprint.end.x + 2.5, house.center().y)
	t.check(Geometry2D.segment_intersects_segment(from, to, house.footprint.position, Vector2(house.footprint.position.x, house.footprint.end.y)) != null,
		"the straight line from the first click to the second crosses the house footprint")
	var fx := _cast(made, from, to)
	RD._run(fx, GravecallFx.T_RISE + 0.1 + from.distance_to(to) / 1.0 + 1.0)
	var ok := fx.spirits.size() == GravecallFx.SPIRITS
	for a in fx.spirits:
		ok = ok and is_instance_valid(a) and a.ground_pos.distance_to(to) < 1.5
	t.check(ok and fx.haunting, "they cross a wall to the second click (%s)" % [fx.spirits.map(func(a: Animal) -> float: return snappedf(a.ground_pos.distance_to(to), 0.1))])
	fx.end_now()


## "people within 3 of the haunt flee"
static func _flee(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := _spot(made)
	var to := at + Vector2(0.0, 2.0)
	var near: Person = crowd.citizens[2]
	var far: Person = crowd.citizens[3]
	near.ground_pos = to + Vector2(2.5, 0.0)
	far.ground_pos = to + Vector2(0.0, 7.0)
	var fx := _cast(made, at, to)
	RD._run(fx, GravecallFx.T_RISE + 6.0)
	t.check(near.mind == Person.Mind.PANIC or near.mind == Person.Mind.FLEE,
		"people within 3 of the haunt flee (%s)" % Person.Mind.keys()[near.mind])
	t.check(far.mind == Person.Mind.CALM, "one at 7 does not (%s)" % Person.Mind.keys()[far.mind])
	fx.end_now()


## "a soldier passed through is stunned 3 s once"
static func _freeze(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := _spot(made)
	var to := at + Vector2(8.0, 0.0)
	var s: Person = crowd.soldiers[0]
	s.ground_pos = at + Vector2(3.0, 0.0)
	var fx := _cast(made, at, to)
	RD._run(fx, GravecallFx.T_RISE + 0.05)
	var stunned := 0.0
	var calls := 0
	for i in roundi(8.0 / DT):
		fx._process(DT)
		if s.wait > 0.0:
			calls += 1  # every stun() raises the cleared wait to FREEZE, so this counts the calls
			stunned = maxf(stunned, s.wait)
			s.wait = 0.0
	var passed := 0
	for a in fx.spirits:
		if (fx._passed[a] as Dictionary).has(s):
			passed += 1
	t.check(passed >= 1 and calls == passed and is_equal_approx(stunned, GravecallFx.FREEZE),
		"a soldier passed through is stunned 3 s once per spirit (%d stuns, %d spirits passed, up to %.2f)" % [calls, passed, stunned])
	fx.end_now()


## "gone after 20 s at the spot"
static func _gone(t, made: Array) -> void:
	RD._clear_all(made)
	var at := _spot(made)
	var to := at + Vector2(0.0, 3.0)
	var fx := _cast(made, at, to)
	RD._run(fx, GravecallFx.T_RISE + 4.0)
	t.check(fx.haunting and fx.visitors.living().size() == 3, "they haunt the spot")
	var arrived: float = fx._started
	RD._run(fx, arrived + GravecallFx.HAUNT - 1.0 - fx.t)
	t.check(fx.haunting and not fx.finished, "still there before the 20 s are up")
	RD._run(fx, 1.0 + GravecallFx.FADE + 0.3)
	t.check(fx.finished and fx.visitors.living().is_empty(), "gone after 20 s at the spot (%.1f s in)" % (fx.t - arrived))


## Freed without _finish (Battlefield.clear_effects() on a restart queue_frees it): the spirits are gone and the pack leaves the
## town, with no error; its end after that changes nothing.
static func _exit(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := _spot(made)
	var fx := _cast(made, at, at + Vector2(0.0, 3.0))
	RD._run(fx, GravecallFx.T_RISE + 1.0)
	var pack := fx.visitors
	var up := pack.living()
	t.check(up.size() == GravecallFx.SPIRITS, "(three up)")
	fx._exit_tree()
	t.check(RD._all_gone(up) and pack.living().is_empty() and not crowd.visitors.has(pack),
		"freed without its end, the spirits are gone and the pack leaves the town")
	fx.end_now()
	t.check(fx.finished, "and its end after that changes nothing")
