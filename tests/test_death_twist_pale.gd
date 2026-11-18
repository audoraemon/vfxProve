extends RefCounted
## Pale Reign, level 5 twist -- The Pall Grows (Death and Decree ability levels, Task 9; DL9): each death in the district adds 0.25
## to its radius, up to the cast-time radius + 3.0 (12 deaths); the crawl, the douse, the ghosts' bounds and the veil read the grown one.

const RD := preload("res://tests/test_raise_dead.gd")
const PT := preload("res://tests/test_pale.gd")
const STEP := 0.25
const MOST := 3.0


static func _cast(made: Array, at: Vector2, level: int) -> PaleReignFx:
	return FxTimeline.cast(PaleReignFx, made[5], at, {"level": level}) as PaleReignFx


static func _alive(made: Array) -> Array:
	return (made[0] as Crowd).citizens.filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive())


## `n` deaths near the middle (a mob death each, no step of the clock between them).
static func _die(made: Array, pool: Array, from: int, n: int, at: Vector2) -> void:
	for i in n:
		var p: Person = pool[from + i]
		p.ground_pos = at + Vector2.from_angle(TAU * float(i) / 12.0) * 3.0
		(made[3] as EnemyField).kill(p, &"mob")


static func run(t) -> void:
	var made := RD._setup()
	_growth(t, made)
	_crawl_edge(t, made)
	_level_four(t, made)
	_teardown(t, made)
	RD._done(made)


## 12 deaths at level 5 -> radius 11.0 + 3.0 = 14.0; a 13th changes nothing; the ghosts' bounds and the drain follow it.
static func _growth(t, made: Array) -> void:
	PT._reset(made)
	var at := RD._empty(made)
	var pool := _alive(made)
	var fx := _cast(made, at, 5)
	var base := fx.lv_radius
	_die(made, pool, 0, 1, at)
	t.check(is_equal_approx(fx.lv_radius, base + STEP) and is_equal_approx(base, 11.0), "level 5: one death widens the grey by 0.25 (%.2f)" % fx.lv_radius)
	_die(made, pool, 1, 11, at)
	t.check(is_equal_approx(fx.lv_radius, 14.0), "12 deaths: radius 14.0 (%.2f)" % fx.lv_radius)
	_die(made, pool, 12, 1, at)
	t.check(is_equal_approx(fx.lv_radius, 14.0), "a 13th death changes nothing (%.2f)" % fx.lv_radius)
	var bound := not fx.horde.living().is_empty()
	for a in fx.horde.living():
		var rule: Visitors.Rule = fx.horde._rules[a]
		bound = bound and is_equal_approx(rule.bounds.z, 14.0)
	t.check(bound, "every ghost up hunts within the grown district (%d up)" % fx.horde.living().size())
	fx.end_now()


## A person 12.5 away crawls after the 6th death and not before.
static func _crawl_edge(t, made: Array) -> void:
	PT._reset(made)
	var at := RD._empty(made)
	var pool := _alive(made)
	var far: Person = pool[20]
	far.ground_pos = at + Vector2(12.5, 0.0)
	far.mind = Person.Mind.CALM
	var fx := _cast(made, at, 5)
	_die(made, pool, 0, 5, at)
	RD._run(fx, 0.1)
	t.check(is_equal_approx(far.pace_hold(), 1.0), "after 5 deaths (radius 12.25) a person at 12.5 walks free")
	_die(made, pool, 5, 1, at)
	RD._run(fx, 0.1)
	t.check(is_equal_approx(far.pace_hold(), PaleReignFx.CRAWL), "after the 6th death (radius 12.5) he crawls (%.2f)" % far.pace_hold())
	fx.end_now()


## Level 4 (no twist): twelve deaths widen nothing, and the person at 12.5 never crawls.
static func _level_four(t, made: Array) -> void:
	PT._reset(made)
	var at := RD._empty(made)
	var pool := _alive(made)
	var far: Person = pool[20]
	far.ground_pos = at + Vector2(12.5, 0.0)
	far.mind = Person.Mind.CALM
	var fx := _cast(made, at, 4)
	var base := fx.lv_radius
	_die(made, pool, 0, 12, at)
	RD._run(fx, 0.1)
	t.check(is_equal_approx(fx.lv_radius, base) and is_equal_approx(base, 10.75) and is_equal_approx(far.pace_hold(), 1.0),
		"level 4: twelve deaths widen nothing (%.2f), nobody beyond crawls" % fx.lv_radius)
	fx.end_now()


## Cut short (end_now, then a freed node) after the grey has grown: the far person walks free, and a death after that grows nothing.
static func _teardown(t, made: Array) -> void:
	for mode in 2:
		PT._reset(made)
		var at := RD._empty(made)
		var pool := _alive(made)
		var far: Person = pool[20]
		far.ground_pos = at + Vector2(13.0, 0.0)
		far.mind = Person.Mind.CALM
		var fx := _cast(made, at, 5)
		_die(made, pool, 0, 8, at)
		RD._run(fx, 0.1)
		var held := is_equal_approx(far.pace_hold(), PaleReignFx.CRAWL)
		var name := "end_now" if mode == 0 else "freed"
		if mode == 0:
			fx.end_now()
		else:
			fx._exit_tree()
			fx.free()
		var field: EnemyField = made[3]
		var grew := fx.lv_radius if mode == 0 else -1.0
		_die(made, pool, 8, 1, at)
		var free := held and is_equal_approx(far.pace_hold(), 1.0)
		if mode == 0:
			free = free and not field.enemy_killed.is_connected(fx._on_killed)
		t.check(free, "%s after the grey grew: the far person walks free, the reign hears no more deaths" % name)
		if mode == 0:
			t.check(is_equal_approx(fx.lv_radius, grew), "%s: a later death widens nothing (%.2f)" % [name, fx.lv_radius])
