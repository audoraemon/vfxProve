extends RefCounted
## erase level 5 twist (Death and Decree ability levels, Task 16): Shortcut. After the spring back the two ends of the line stay
## joined as a door for 15 s: whoever (person, soldier, hound) stands within 0.6 of one end is set down at the other end's
## nearest walkable point, then cannot be taken again for 1.0 s. Level 4 has no seams. Nothing is laid in the world, so a cast
## cut short or freed leaves nothing behind; two casts keep their own seams and rests.

const PATH := "res://src/fx/decree/erasing_distance.gd"
const E := preload("res://tests/test_decree_erase.gd")
const T_OPEN := 2.25  # the spring back has happened (0.6 + 1.5 + 0.15)


## A cast at `level` on open ground from `from` along +y (6 long), run to just after the spring back: [made, fx].
static func _world(level: int, made: Array = [], from := E.FROM) -> Array:
	if made.is_empty():
		made = E._setup()
	var fx := FxTimeline.cast(load(PATH), made[5], from, {"dir": E.DIR, "to": from + E.DIR * E.LEN, "level": level})
	E._run(fx, T_OPEN + 0.05)
	return [made, fx]


static func _land(made: Array, g: Vector2) -> Vector2:
	return (made[2] as WalkGrid).nearest_walkable(g, 8)


static func run(t) -> void:
	_level4(t)
	_through(t)
	_hound(t)
	_rest(t)
	_sound(t)
	_unwalkable(t)
	_expiry(t)
	await _teardown(t)
	_overlap(t)


static func _level4(t) -> void:
	var w := _world(4)
	var made: Array = w[0]
	var fx: EraseFx = w[1]
	var p: Person = (made[0] as Crowd).citizens[0]
	p.ground_pos = fx.origin
	E._run(fx, 0.2)
	t.check(not fx.seams_open() and p.ground_pos.is_equal_approx(fx.origin) and fx.shortcuts == 0
		and is_equal_approx(fx.duration, EraseFx.T_SEAM + EraseFx.T_FOLD + EraseFx.T_SNAP + EraseFx.SCAR),
		"erase level 4: no seams, nobody is moved, the old duration")
	fx.end_now()
	E._done(made)
	# Control: the same stand at level 5 is taken through.
	var w5 := _world(5)
	var fx5: EraseFx = w5[1]
	var p5: Person = (w5[0][0] as Crowd).citizens[0]
	p5.ground_pos = fx5.origin
	E._run(fx5, 0.1)
	t.check(fx5.seams_open() and fx5.shortcuts == 1 and p5.ground_pos.distance_to(_land(w5[0], fx5.to)) < 0.01
		and is_equal_approx(fx5.duration, EraseFx.T_SEAM + EraseFx.T_FOLD + EraseFx.T_SNAP + 15.0),
		"control: at level 5 the seams are open and the same stand sets him at the far end (15 s on)")
	fx5.end_now()
	E._done(w5[0])


static func _through(t) -> void:
	var w := _world(5)
	var made: Array = w[0]
	var fx: EraseFx = w[1]
	var crowd: Crowd = made[0]
	var p: Person = crowd.citizens[0]
	var s: Person = crowd.soldiers[0]
	p.ground_pos = fx.origin + Vector2(0.3, 0.0)
	s.ground_pos = fx.to + Vector2(0.0, 0.4)
	var p_end: Vector2 = _land(made, fx.to)
	var s_end: Vector2 = _land(made, fx.origin)
	E._run(fx, 0.1)
	t.check(p.ground_pos.distance_to(p_end) < 0.01, "a person stepping on end A appears at B (%s)" % str(p.ground_pos))
	t.check(s.ground_pos.distance_to(s_end) < 0.01, "a soldier on end B appears at A (%s)" % str(s.ground_pos))
	# Someone who is not near an end is left alone.
	var far: Person = crowd.citizens[1]
	far.ground_pos = fx.middle()
	E._run(fx, 0.1)
	t.check(far.ground_pos.is_equal_approx(fx.middle()), "one standing mid-line is left alone")
	fx.end_now()
	E._done(made)


static func _hound(t) -> void:
	var w := _world(5)
	var made: Array = w[0]
	var fx: EraseFx = w[1]
	var v := Visitors.new().setup(made[3], made[0], made[2], made[4])
	var hound := v.summon(fx.origin + Vector2(0.2, 0.0), Animal.Breed.HELLHOUND, 3, 1.0, 8.0, 0.5, 1.0)
	E._run(fx, 0.1)
	t.check(hound.ground_pos.distance_to(_land(made, fx.to)) < 0.01 and fx.shortcuts == 1,
		"a hound stepping on end A appears at B too (%s)" % str(hound.ground_pos))
	var dead := v.summon(fx.to + Vector2(0.0, 0.3), Animal.Breed.HELLHOUND, 3, 1.0, 8.0, 0.5, 1.0)
	dead.die()
	var at := dead.ground_pos
	E._run(fx, 0.1)
	t.check(dead.ground_pos.is_equal_approx(at), "a dead hound is not taken")
	fx.end_now()
	v.clear()
	E._done(made)


static func _rest(t) -> void:
	var w := _world(5)
	var made: Array = w[0]
	var fx: EraseFx = w[1]
	var p: Person = (made[0] as Crowd).citizens[0]
	var b := _land(made, fx.to)
	p.ground_pos = fx.origin
	E._run(fx, 0.1)
	t.check(p.ground_pos.distance_to(b) < 0.01, "ping-pong: he is set at B")
	E._run(fx, 4.0)
	t.check(p.ground_pos.distance_to(b) < 0.01 and fx.shortcuts == 1,
		"no ping-pong: someone standing still at the landing end is never moved back (4 s)")
	# Control: he walks out of the end's ring, and back in: taken again (to A).
	p.ground_pos = b + Vector2(0.0, -1.5)
	E._run(fx, 0.1)
	t.check(fx.shortcuts == 1, "control: stepping out of the ring alone moves nobody")
	p.ground_pos = fx.to
	E._run(fx, 0.1)
	t.check(p.ground_pos.distance_to(_land(made, fx.origin)) < 0.01 and fx.shortcuts == 2,
		"control: walking out and back into an end takes him again (to A)")
	# The 1.0 s minimum: out and straight back in within a second is not enough.
	var q: Person = (made[0] as Crowd).citizens[1]
	q.ground_pos = fx.to
	E._run(fx, 0.05)
	var at_a := q.ground_pos
	q.ground_pos = fx.origin + Vector2(0.0, -1.5)
	E._run(fx, 0.05)
	q.ground_pos = fx.origin
	E._run(fx, 0.05)
	t.check(q.ground_pos.is_equal_approx(fx.origin) and at_a.distance_to(_land(made, fx.origin)) < 0.01,
		"the 1.0 s minimum holds even after stepping out")
	E._run(fx, 1.0)
	t.check(q.ground_pos.distance_to(_land(made, fx.to)) < 0.01, "control: after the 1.0 s he is taken")
	fx.end_now()
	E._done(made)


class Rec extends Node:
	var cues: Array = []

	func play(cue: StringName, _g: Vector2, _db := 0.0) -> Node:
		cues.append(cue)
		return null


static func _sound(t) -> void:
	var w := _world(5)
	var made: Array = w[0]
	var fx: EraseFx = w[1]
	var rec := Rec.new()
	(made[5] as FxContext).sfx = rec
	var p: Person = (made[0] as Crowd).citizens[0]
	var q: Person = (made[0] as Crowd).citizens[1]
	E._run(fx, 0.5)
	t.check(rec.cues.is_empty(), "sound: nobody at an end, no sound")
	p.ground_pos = fx.origin
	q.ground_pos = fx.origin + Vector2(0.1, 0.0)
	E._run(fx, 0.05)
	t.check(rec.cues.size() == 1 and fx.shortcuts == 2, "sound: two crossing in one step make one sound (%d)" % rec.cues.size())
	E._run(fx, 3.0)
	t.check(rec.cues.size() == 1, "sound: two resting at the landing end make no more (%d)" % rec.cues.size())
	p.ground_pos = fx.to + Vector2(0.0, 1.5)
	E._run(fx, 0.05)
	p.ground_pos = fx.to
	E._run(fx, 0.05)
	t.check(rec.cues.size() == 2, "control: a fresh crossing sounds again")
	(made[5] as FxContext).sfx = null
	rec.free()
	fx.end_now()
	E._done(made)


static func _unwalkable(t) -> void:
	var made: Array = E._setup()
	var fx := FxTimeline.cast(load(PATH), made[5], E.FROM, {"dir": E.DIR, "to": E.FROM + E.DIR * E.LEN, "level": 5})
	E._run(fx, T_OPEN + 0.05)
	# The far end is made to lie inside a standing building.
	var house: Structure = null
	for s in (made[1] as EnvironmentField).structures():
		if not s.walkable and not s.destroyed:
			house = s
			break
	fx.to = house.center()
	var grid: WalkGrid = made[2]
	var snap := grid.nearest_walkable(fx.to, 8)
	t.check(not grid.walkable(fx.to) and snap != Vector2.INF and grid.walkable(snap),
		"setup: the far end is solid, a walkable point lies near")
	var p: Person = (made[0] as Crowd).citizens[0]
	p.ground_pos = fx.origin
	E._run(fx, 0.1)
	t.check(p.ground_pos.distance_to(snap) < 0.01 and grid.walkable(p.ground_pos),
		"an end on unwalkable ground sets him at its nearest walkable point (%s)" % str(p.ground_pos))
	fx.end_now()
	E._done(made)


static func _expiry(t) -> void:
	var w := _world(5)
	var made: Array = w[0]
	var fx: EraseFx = w[1]
	var p: Person = (made[0] as Crowd).citizens[0]
	E._run(fx, 14.0)
	t.check(fx.seams_open() and not fx.finished, "the seams still stand at 14 s after the spring back")
	p.ground_pos = fx.origin
	E._run(fx, 0.1)
	t.check(fx.shortcuts == 1, "control: still taken at 14 s")
	E._run(fx, 1.0)
	t.check(fx.finished and not fx.seams_open(), "the seams are gone at 15.0 s and the effect ends")
	var q: Person = (made[0] as Crowd).citizens[1]
	q.ground_pos = fx.origin
	fx._process(0.05)
	t.check(q.ground_pos.is_equal_approx(fx.origin) and fx.shortcuts == 1, "nobody is taken after it")
	E._done(made)


static func _teardown(t) -> void:
	var w := _world(5)
	var made: Array = w[0]
	var fx: EraseFx = w[1]
	var ctx: FxContext = made[5]
	(t.root as Node).add_child(ctx.ground)
	await t.process_frame
	var p: Person = (made[0] as Crowd).citizens[0]
	p.ground_pos = fx.origin
	E._run(fx, 0.1)
	t.check(fx.shortcuts == 1, "teardown control: a cast mid-seams moves people")
	fx.end_now()
	var q: Person = (made[0] as Crowd).citizens[1]
	q.ground_pos = fx.origin
	fx._process(0.1)
	t.check(fx.finished and not fx.seams_open() and q.ground_pos.is_equal_approx(fx.origin),
		"end_now: the seams are gone, nobody is moved")
	fx.free()
	# A freed node (in the tree) leaves nothing either.
	var w2 := _world(5)
	var fx2: EraseFx = w2[1]
	var ctx2: FxContext = w2[0][5]
	(t.root as Node).add_child(ctx2.ground)
	await t.process_frame
	var r: Person = (w2[0][0] as Crowd).citizens[0]
	r.ground_pos = fx2.origin
	E._run(fx2, 0.1)
	t.check(fx2.shortcuts == 1, "teardown control: a second cast takes him through")
	fx2.free()
	await t.process_frame
	r.ground_pos = Vector2(-24.0, -3.0)
	t.check(not is_instance_valid(fx2), "a freed cast is gone")
	(t.root as Node).remove_child(ctx2.ground)
	(t.root as Node).remove_child(ctx.ground)
	E._done(w2[0])
	E._done(made)


static func _overlap(t) -> void:
	var w := _world(5)
	var made: Array = w[0]
	var fx1: EraseFx = w[1]
	var w2 := _world(5, made, E.FROM + Vector2(-5.0, 0.0))
	var fx2: EraseFx = w2[1]
	var crowd: Crowd = made[0]
	var a: Person = crowd.citizens[0]
	var b: Person = crowd.citizens[1]
	a.ground_pos = fx1.origin
	b.ground_pos = fx2.origin
	E._run(fx1, 0.05)
	fx2._process(0.05)
	t.check(fx1.shortcuts == 1 and fx2.shortcuts == 1, "two casts: each takes its own through")
	fx1.end_now()
	b.ground_pos = fx2.to
	var rested_a := a.ground_pos
	fx2._process(1.1)
	t.check(fx2.seams_open() and fx2.shortcuts == 2 and a.ground_pos.is_equal_approx(rested_a),
		"one cast ending leaves the other's seams open (and its rests its own)")
	fx2.end_now()
	E._done(made)
