extends RefCounted
## God P3 Task 3 (plan P3-10..P3-14, pre-flight B5 R5 R6 R10 R13 G3 G7): RiteDirector and Chain of the Forgotten (MS §2, §3.6) on a stand-in rite
## (TestRite: four victims, one breaker, a log of the subclass's calls). Bite, drag at the pace that keeps every drag to 55 s, the sacrifice, the
## grip and every reset MS §2 names, the Yank, the replacement rule, the evacuation hold, and the two defaults Task 3 adds to shared classes.

const DT := 0.05
## A start with a long way to the shrine (about 39 units by the walk grid) and one 0.5 from it; the Temple's door is near (0.8, -5.0).
const FAR := Vector2(5.5, 12.5)
const NEAR := Vector2(-17.4, 5.5)
const ELSEWHERE := Vector2(14.0, -12.0)


## A rite of four victims (so the replacement rule has room) and one breaker, with a log of what the base asked of it.
class TestRite extends RiteDirector:
	var answers: Array[int] = []
	var replaced := 0
	var breaker: Person
	## The raw list, as a real subclass keeps it (the Watch): a body freed after its death fade stays in it.
	var raw: Array[Person] = []
	var spots := [Vector2(5.5, 12.5), Vector2(-10.0, 9.0), Vector2(0.0, 7.5), Vector2(9.5, 8.8)]

	func rite_id() -> String:
		return RiteBook.FIRST_TASTE

	func victim_word() -> String:
		return "LAMPLIGHTER"

	func _appoint_victims() -> Array[Person]:
		var out: Array[Person] = []
		for at: Vector2 in spots:
			var v := _citizen_near(at, CitizenProfile.Role.RESIDENT, out)
			if v != null:
				_set_down(v, _walkable(at))
				v.go_duty(v.ground_pos)
				out.append(v)
		var soldiers := _free_soldiers(ELSEWHERE, 1)
		if not soldiers.is_empty():
			breaker = soldiers[0]
			breaker.ground_pos = ELSEWHERE
			breaker.send_to_post(ELSEWHERE)
			raw.append(breaker)
		return out

	func _breakers() -> Array[Person]:
		return raw

	func _post_of(_b: Person) -> Vector2:
		return ELSEWHERE

	func _answer(shard: int) -> void:
		answers.append(shard)

	func _replace() -> void:
		replaced += 1
		var v := _citizen_near(lantern_door(), CitizenProfile.Role.RESIDENT, marked + safe)
		if v != null:
			_set_down(v, v.ground_pos)
			v.go_duty(v.ground_pos)
			_mark(v)


static func run(t) -> void:
	_defaults(t)
	_refusals(t)
	_bite_then_drag(t)
	_sacrifice(t)
	_grip_breaks(t)
	_grip_resets(t)
	_yank_once(t)
	_town_never_grips(t)
	_noleave_skips_chained(t)
	_dies_on_the_way(t)
	_replacement(t)
	_hold_all(t)
	_fold_keeps_pace(t)
	_held_not_reposted(t)
	_busy(t)
	_tags(t)
	_report(t)
	_freed_people(t)
	_quiet_sacrifice(t)
	_blocked_walk_retries(t)
	_stuck_captive_freed(t)
	_stranded_replaced(t)


# --- The world -----------------------------------------------------------------------------------

static func _world() -> Dictionary:
	var def := MissionBook.first_taste()
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	var director := TestRite.new().setup(rules, crowd, town, null) as TestRite
	rules.director = director
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director,
		"banners": banners}


static func _done(s: Dictionary) -> void:
	var rules: Rules = s.rules
	rules.teardown()
	rules.free()
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


## One step: the crowd, then the people the test watches (headless, a crowd's people are not stepped by their own _process: the rite's victims, its
## breaker and whoever a test lists in s.also are), then the rules and so the director.
static func _step(s: Dictionary) -> void:
	(s.crowd as Crowd).advance(DT)
	var d: TestRite = s.d
	var walkers: Array = []
	walkers.append_array(d.marked)
	walkers.append(d.breaker)
	walkers.append(d.captive)
	walkers.append_array(s.get("also", []))
	for p: Variant in walkers:
		if is_instance_valid(p):
			(p as Person).tick(DT)
	(s.rules as Rules).advance(DT)


static func _run(s: Dictionary, seconds: float) -> void:
	for i in roundi(seconds / DT):
		_step(s)


## Runs until `cond` holds or `limit` seconds pass; returns the seconds it took.
static func _until(s: Dictionary, limit: float, cond: Callable) -> float:
	var spent := 0.0
	while spent < limit and not cond.call():
		_step(s)
		spent += DT
	return spent


static func _arrive(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


## Victim `i` set down at `at`, still, ready to be chained.
static func _victim(d: TestRite, i: int, at: Vector2) -> Person:
	var v: Person = d.marked[i]
	_arrive(v, d._walkable(at))
	v.go_duty(v.ground_pos)
	return v


## Chains victim `i`, standing at `at`, with the breaker `near` the new captive (Vector2.INF: left far away), and runs to the drag's first frames.
static func _dragging(s: Dictionary, i: int, at: Vector2, near := Vector2.INF) -> Person:
	var d: TestRite = s.d
	var v := _victim(d, i, at)
	if near != Vector2.INF:
		_arrive(d.breaker, v.ground_pos + near)
	_run(s, DT)
	var refused := d.chain(v)
	if refused != "":
		return null
	_run(s, RiteDirector.BITE + 0.2)
	return v


# --- The tests -----------------------------------------------------------------------------------

## The two defaults Task 3 adds to shared classes (R12 of the pre-flight: not proofs on their own, the references are).
static func _defaults(t) -> void:
	t.check(MissionDirector.new().strip_rows().is_empty(), "a mission director's strip rows are empty by default")
	t.check(MapTag.new().ring == -1.0, "a map tag has no ring by default")
	var p := Person.new()
	t.check(not p.chained, "a person is not chained by default")
	p.free()


static func _refusals(t) -> void:
	var s := _world()
	var d: TestRite = s.d
	t.check(d.chain_key() == "aim", "READY: C starts an aim (%s)" % [d.chain_key()])
	t.check(d.chain_at(Vector2(-25.0, -25.0)) == "NOT A LAMPLIGHTER", "a click on nobody: NOT A LAMPLIGHTER (%s)" % [d.chain_at(Vector2(-25.0, -25.0))])
	var other: Person = s.crowd.citizens[0]
	if d.marked.has(other):
		other = s.crowd.citizens[1]
	_arrive(other, Vector2(-25.0, -25.0))
	t.check(d.chain(other) == "NOT A LAMPLIGHTER" and d.chain_state == RiteDirector.Chain.READY, "an unmarked person is refused, the chain still ready")
	var v := _victim(d, 0, TestRite.new().spots[0])
	t.check(d.chain_at(v.ground_pos + Vector2(0.5, 0.0)) == "" and d.captive == v and d.chain_state == RiteDirector.Chain.BITE,
		"a click within PICK_R of a marked victim chains him (%s)" % [d.chain_state])
	t.check(d.chain(d.marked[1]) == RiteDirector.ONE_CHAIN and d.chain_key() == RiteDirector.ONE_CHAIN, "a second chain while one bites: ONE CHAIN AT A TIME")
	_run(s, RiteDirector.BITE + 0.2)
	t.check(d.chain_state == RiteDirector.Chain.DRAG and d.chain(d.marked[1]) == RiteDirector.ONE_CHAIN, "and while dragging: ONE CHAIN AT A TIME")
	d.offer(d.captive)
	t.check(d.chain_state == RiteDirector.Chain.COOLDOWN and d.chain_key() == RiteDirector.NOT_READY and d.chain(d.marked[0]) == RiteDirector.NOT_READY,
		"in the cooldown C and a chain are refused: THE CHAIN IS NOT READY")
	_done(s)


static func _bite_then_drag(t) -> void:
	t.check(RiteDirector.drag_pace(30.0) == 0.6 and is_equal_approx(RiteDirector.drag_pace(45.0), 45.0 / 55.0),
		"a short path is dragged at 0.6, a long one at path / 55 (%s, %s)" % [RiteDirector.drag_pace(30.0), RiteDirector.drag_pace(45.0)])
	t.check(RiteDirector.drag_pace(58.0) * RiteDirector.DRAG_MAX >= 58.0 - 0.001 and RiteDirector.drag_pace(20.0) == RiteDirector.PACE_MIN,
		"no path takes more than 55 s at the pace it is dragged")
	var s := _world()
	var d: TestRite = s.d
	var v := _victim(d, 0, FAR)
	var start := v.ground_pos
	t.check(d.chain(v) == "" and v.chained and d.chain_state == RiteDirector.Chain.BITE, "the chain takes him: chained, the bite begins")
	_run(s, RiteDirector.BITE * 0.5)
	t.check(v.ground_pos.distance_to(start) < 0.05 and v.mind == Person.Mind.COMPELLED and v.compel_pose == &"kneel",
		"he kneels still while the chain bites (%.2f from his spot)" % v.ground_pos.distance_to(start))
	var eta0 := d.drag_eta()
	var way := d._way
	t.check(way > 30.0 and way < 55.0 and absf(eta0 - way / d._speed) < 0.01 and absf(d._speed - RiteDirector.drag_pace(way)) < 0.001,
		"the drag is %.1f units at %.2f a second: %.1f s <= 55 s" % [way, d._speed, eta0])
	var took := _until(s, 58.0, func() -> bool: return d.shards == 1)
	t.check(d.shards == 1 and took <= RiteDirector.DRAG_MAX + RiteDirector.BITE + 1.0,
		"with no breaker he reaches the shrine within 55 s of the bite (%.1f s, shards %d)" % [took, d.shards])
	_done(s)


static func _sacrifice(t) -> void:
	var s := _world()
	var d: TestRite = s.d
	var v := _dragging(s, 0, NEAR)
	t.check(v != null and d.chain_state != RiteDirector.Chain.READY, "a victim 0.5 from the shrine is chained")
	_run(s, 0.3)
	t.check(d.shards == 1 and not MissionDirector._alive(v) and d.captive == null and d.chain_state == RiteDirector.Chain.COOLDOWN,
		"at the shrine he dies on its stone: one shard, the chain cooling down (shards %d)" % d.shards)
	t.check((s.banners as Array).has("THE FIRST TASTE  1/3"), "the banner: THE FIRST TASTE  1/3 (%s)" % [s.banners])
	t.check(d.answers == [1], "_answer(1) was called once (%s)" % [d.answers])
	t.check(not d.marked.has(v) and d.left() == 3, "the sacrificed is no longer marked; three are left (%d)" % d.left())
	var shrine_tag: MapTag = null
	for tag in d.tags():
		if tag.label.begins_with("MIRA'S SHRINE"):
			shrine_tag = tag
	t.check(shrine_tag != null and shrine_tag.label == "MIRA'S SHRINE  1/3" and shrine_tag.color == RiteDirector.MARK_SHRINE
		and is_equal_approx(shrine_tag.rise, RiteDirector.FLAME_RISE + RiteDirector.FLAME_STEP), "the shrine's tag is orange, 1/3, its flame one step higher")
	_run(s, RiteDirector.COOLDOWN - 1.0)
	t.check(d.chain_state == RiteDirector.Chain.COOLDOWN and d.chain_plate() != "READY", "the cooldown is 8 s: not ready at ~7 s (%s)" % [d.cooldown_left])
	_run(s, 1.3)
	t.check(d.chain_state == RiteDirector.Chain.READY and d.chain_plate() == "READY", "and ready again after it")
	_done(s)


static func _grip_breaks(t) -> void:
	var s := _world()
	var d: TestRite = s.d
	var pace_before: float = (d.marked[0] as Person).pace
	var v := _dragging(s, 0, FAR, Vector2(0.4, 0.0))
	_run(s, 0.4)
	t.check(d.grip_by == d.breaker and d.grip > 0.0 and d._stopped, "a breaker reaching him grips: the captive stops (grip %.2f)" % d.grip)
	var ringed := false
	for tag in d.tags():
		ringed = ringed or (tag.ring > 0.0 and tag.ring <= 1.0 and tag.label.begins_with("CAPTIVE - SHRINE IN"))
	t.check(ringed, "his tag carries the grip's ring and the countdown")
	var at := v.ground_pos
	_run(s, RiteDirector.BREAK_SECONDS - 0.9)
	t.check(d.captive == v and d.chain_state == RiteDirector.Chain.DRAG and v.ground_pos.distance_to(at) < 0.1, "still held before three seconds are up")
	_run(s, 0.9)
	t.check((s.banners as Array).has(RiteDirector.FREED_BANNER) and d.captive == null and not v.chained and d.chain_state == RiteDirector.Chain.COOLDOWN,
		"a full ring breaks the chain: THE CHAIN BREAKS, the cooldown begins")
	t.check(d.marked.has(v) and not d.safe.has(v) and absf(v.pace - pace_before) < 0.0001, "he is still marked, at the pace he had")
	t.check(v.mind == Person.Mind.DUTY and v.anchor.distance_to(d.lantern_door()) < 0.5, "and runs for the Temple's door")
	_arrive(v, d.lantern_door() + Vector2(0.5, 0.0))
	_run(s, RiteDirector.TICK * 2.0 + DT)
	t.check(d.safe.has(v) and not d.marked.has(v) and not d.claimed(v), "reaching the door he is safe, and unmarked")
	_done(s)


## The ways a grip resets (MS §2, P3-11, B5): the breaker killed, whispered, confused, compelled, frail, frightened, bound by a Leaving Is
## Prohibited law, or shoved beyond reach.
static func _grip_resets(t) -> void:
	for reason: String in ["killed", "whispered", "confused", "compelled", "frail", "frightened", "bound", "shoved"]:
		var s := _world()
		var d: TestRite = s.d
		var v := _dragging(s, 0, FAR, Vector2(0.4, 0.0))
		_run(s, 1.0)
		var gripping: bool = d.grip_by == d.breaker and d.grip > 0.5
		var b := d.breaker
		match reason:
			"killed":
				(s.crowd as Crowd)._field.kill(b, &"fire")
			"whispered":
				b.whisper(b.ground_pos + Vector2(3.0, 0.0), 5.0)
			"confused":
				b.confuse(5.0)
			"compelled":
				b.compel(b.ground_pos, 5.0, 0.5, Color.WHITE)
			"frail":
				b.statuses[&"frail"] = 1.0
			"frightened":
				b.panic(b.ground_pos + Vector2(1.0, 0.0), 1.0)
			"bound":
				b.set_badge(DecreeParts.BARS, DecreeParts.GILT, 5.0)
			"shoved":
				b.ground_pos += Vector2(4.0, 0.0)
		var before := v.ground_pos
		_run(s, 0.3)
		t.check(gripping and d.grip < 0.4 and (reason != "shoved" or d.grip_by == null), "%s: the grip was on, and resets (grip %.2f)" % [reason, d.grip])
		_run(s, 1.5)
		t.check(v.ground_pos.distance_to(before) > 0.5 and d.chain_state == RiteDirector.Chain.DRAG,
			"%s: and the drag walks on (%.2f units)" % [reason, v.ground_pos.distance_to(before)])
		_done(s)


static func _yank_once(t) -> void:
	var s := _world()
	var d: TestRite = s.d
	var v := _dragging(s, 0, FAR, Vector2(0.4, 0.0))
	_run(s, 2.0)
	t.check(d.grip >= 1.5 and d.yanks_left == RiteDirector.YANKS, "a 2 s grip, the Yank still unused (grip %.2f)" % d.grip)
	var before := v.ground_pos
	t.check(d.chain_key() == "yank", "C in a drag with a grip: the Yank (%s)" % [d.chain_key()])
	var moved := v.ground_pos.distance_to(before)
	t.check(moved > 1.0 and moved <= RiteDirector.YANK_STEP + 0.3, "he lurches on 1.5 units (%.2f)" % moved)
	t.check(d.grip == 0.0 and d.held(d.breaker) and d.breaker.wait > 0.0, "the grip resets and its breaker stands stunned")
	t.check(d.chain_key() == RiteDirector.YANK_USED and d.yanks_left == 0, "a second C: THE CHAIN HAS PULLED ONCE (%s)" % [d.chain_key()])
	_run(s, RiteDirector.YANK_STUN + 0.4)
	t.check(not d.held(d.breaker), "the stun lasts a second")
	d.offer(d.captive)
	_run(s, RiteDirector.COOLDOWN + 0.2)
	var v2 := _dragging(s, 1, NEAR)
	t.check(v2 != null and d.yanks_left == RiteDirector.YANKS, "the next drag has its Yank again (%d)" % d.yanks_left)
	_done(s)


## Only the director's breakers grip: a soldier who is not in _breakers() standing on the captive never stops him (MS §0), and the chain shakes off
## whisper, fright and Discord (P3-13, R13) with a panicking crowd round it.
static func _town_never_grips(t) -> void:
	var s := _world()
	var d: TestRite = s.d
	var v := _dragging(s, 0, FAR)
	var guard: Person = null
	for sol in (s.crowd as Crowd).soldiers:
		if sol != d.breaker:
			guard = sol
			break
	_arrive(guard, v.ground_pos)
	guard.send_to_post(v.ground_pos)
	var crowd_n := 0
	var also: Array = [guard]
	s["also"] = also
	for p in (s.crowd as Crowd).citizens:
		if p != v and not d.marked.has(p) and crowd_n < 8:
			_arrive(p, v.ground_pos + Vector2(0.3 * float(crowd_n), 0.5))
			p.panic(v.ground_pos, 2.0)
			also.append(p)
			crowd_n += 1
	v.panic(v.ground_pos, 2.0)
	var whispered := v.whisper(v.ground_pos + Vector2(2.0, 0.0), 5.0)
	var before := v.ground_pos
	_run(s, 0.2)
	v.confuse(3.0)
	_run(s, 0.3)
	t.check(not whispered and v.mind == Person.Mind.DUTY, "a whisper does not take him; Discord is put right at once (mind %s)" % [v.mind])
	_arrive(guard, v.ground_pos)
	_run(s, 6.0)
	t.check(d.grip == 0.0 and d.grip_by == null and d.chain_state == RiteDirector.Chain.DRAG and v.ground_pos.distance_to(before) > 2.0,
		"a soldier of the town on him grips nothing, and a frightened crowd does not stop the drag (%.1f units, grip %.2f)"
		% [v.ground_pos.distance_to(before), d.grip])
	_done(s)


## Leaving Is Prohibited never sets back a chained person (R10): an unchained one outside the radius is put back on the edge.
static func _noleave_skips_chained(t) -> void:
	var s := _world()
	var d: TestRite = s.d
	var a := _victim(d, 0, Vector2(0.0, 7.5))
	var b := _victim(d, 1, Vector2(2.0, 7.5))
	var fx := NoLeaveFx.new()
	fx.origin = Vector2(0.0, 7.5)
	fx.sealed = true
	fx._join_in = 99.0
	fx.bound[a] = 0.0
	fx.bound[b] = 0.0
	a.chained = true
	a.ground_pos = fx.origin + Vector2(NoLeaveFx.RADIUS + 0.5, 0.0)
	b.ground_pos = fx.origin + Vector2(NoLeaveFx.RADIUS + 0.5, 1.0)
	fx._fx_process(0.016)
	t.check(a.ground_pos.is_equal_approx(fx.origin + Vector2(NoLeaveFx.RADIUS + 0.5, 0.0)), "a chained captive walks out of the circle untouched")
	t.check(b.ground_pos.distance_to(fx.origin) <= NoLeaveFx.RADIUS + 0.001 and fx.turned_back == 1, "an unchained person past the edge is set back onto it (%.2f)"
		% b.ground_pos.distance_to(fx.origin))
	a.chained = false
	fx.free()
	_done(s)


static func _dies_on_the_way(t) -> void:
	var s := _world()
	var d: TestRite = s.d
	var v := _dragging(s, 0, FAR)
	_run(s, 3.0)
	(s.crowd as Crowd)._field.kill(v, &"fire")
	_run(s, 0.3)
	t.check(d.shards == 0 and d.captive == null and d.chain_state == RiteDirector.Chain.COOLDOWN and (s.banners as Array).has(RiteDirector.LOST_BANNER)
		and d.answers.is_empty(), "a captive killed away from the shrine is wasted: no shard, no answer, the chain cools down")
	t.check(not (s.rules as Rules).finished, "and it never ends the night")
	_done(s)


static func _replacement(t) -> void:
	var s := _world()
	var d: TestRite = s.d
	t.check(d.marked.size() == 4 and d.left() == 4, "four victims are marked")
	_run(s, 0.6)
	t.check(d.replaced == 0, "with four left and three shards needed none is added")
	(s.crowd as Crowd)._field.kill(d.marked[0], &"fire")
	_run(s, 0.6)
	t.check(d.replaced == 1 and d.left() == 4, "one killed: _replace() is called once and a new victim is marked (%d calls, %d left)" % [d.replaced, d.left()])
	# One made safe (reached the Temple) counts as gone too.
	var v: Person = d.marked[0]
	d.safe.append(v)
	_run(s, 0.6)
	t.check(d.replaced == 2, "one made safe is replaced too (%d calls)" % d.replaced)
	_done(s)


static func _hold_all(t) -> void:
	var s := _world()
	var d: TestRite = s.d
	var v: Person = d.marked[0]
	v.mind = Person.Mind.FLEE
	d.breaker.mind = Person.Mind.FLEE
	(s.crowd as Crowd)._fled_all = true
	_run(s, 0.6)
	t.check(v.mind != Person.Mind.FLEE and d.breaker.mind != Person.Mind.FLEE, "an evacuation does not send a victim or a breaker running for the gates (%s, %s)"
		% [v.mind, d.breaker.mind])
	_done(s)


## R6: the pace is set once at the bite; a Mirrorfold fold recomputes the path from where he lands and does not slow him to the 55 s pace again.
static func _fold_keeps_pace(t) -> void:
	var s := _world()
	var d: TestRite = s.d
	var v := _dragging(s, 0, FAR)
	var speed := d._speed
	var pace := v.pace
	var eta_before := d.drag_eta()
	t.check(v.fold(Vector2(-8.0, 17.6)), "a fold carries the captive down the road")
	_run(s, DT * 2.0)
	t.check(is_equal_approx(d._speed, speed) and is_equal_approx(v.pace, pace), "the drag pace is not recomputed by the fold (%.3f, was %.3f)" % [d._speed, speed])
	t.check(d.drag_eta() < eta_before - 10.0, "and the time left drops by the shortcut (%.1f s from %.1f s)" % [d.drag_eta(), eta_before])
	_done(s)


## R5: a held breaker is left to his hold: not sent back to his post while whispered or compelled, and sent back once the hold ends.
static func _held_not_reposted(t) -> void:
	var s := _world()
	var d: TestRite = s.d
	var b := d.breaker
	_arrive(b, Vector2(0.0, 0.0))
	b.send_to_post(Vector2(0.0, 0.0))
	b.compel(Vector2(1.0, 0.0), 3.0, 0.5, Color.WHITE)
	_run(s, 1.0)
	t.check(b.mind == Person.Mind.COMPELLED and b.anchor.distance_to(Vector2(1.0, 0.0)) < 0.5, "a compelled watchman is not re-posted while the compulsion lasts (mind %s)" % [b.mind])
	_run(s, 4.0)
	t.check(b.mind != Person.Mind.COMPELLED and b.anchor.distance_to(TestRite.new()._post_of(b)) < 1.0, "and is sent back to his post once it ends (anchor %s)" % [b.anchor])
	_done(s)


## G3: the Lantern's Bearer and escorts skip a director's busy() people.
static func _busy(t) -> void:
	var s := _world()
	var d: TestRite = s.d
	t.check(d.busy(d.marked[0]) and d.busy(d.breaker), "a marked victim and a breaker are busy")
	var v := _victim(d, 1, FAR)
	d.chain(v)
	d.marked.erase(v)
	t.check(d.busy(v), "so is the captive")
	var plain: Person = null
	for p in (s.crowd as Crowd).citizens:
		if not d.marked.has(p) and p != v:
			plain = p
			break
	t.check(not d.busy(plain), "an ordinary citizen is not")
	_done(s)


static func _tags(t) -> void:
	var s := _world()
	var d: TestRite = s.d
	var gold := 0
	var edged := true
	for tag in d.tags():
		if tag.label == "LAMPLIGHTER":
			gold += 1
			edged = edged and tag.edge and tag.color == RiteDirector.MARK_VICTIM
	t.check(gold == 4 and edged, "four LAMPLIGHTER tags, gold and edge-arrowed (%d)" % gold)
	var v := _dragging(s, 0, FAR)
	var captive_tag: MapTag = null
	var plain_lamps := 0
	for tag in d.tags():
		if tag.label.begins_with("CAPTIVE"):
			captive_tag = tag
		elif tag.label == "LAMPLIGHTER":
			plain_lamps += 1
	t.check(captive_tag != null and captive_tag.edge and captive_tag.label == "CAPTIVE - SHRINE IN %s" % UiTheme.clock(d.drag_eta()) and captive_tag.ring == -1.0
		and plain_lamps == 3, "the captive's tag counts down his drag, edge-arrowed, no ring; the other three keep theirs (%s)" % [captive_tag.label])
	t.check(d.chain_plate() == "DRAG %s" % UiTheme.clock(d.drag_eta()), "the plate reads DRAG with the time left (%s)" % d.chain_plate())
	t.check(v != null and RiteDirector.MARK_SHRINE == AssassinateDirector.MARK_PLACE, "the shrine's orange is the Assassinate mark's")
	_done(s)


static func _report(t) -> void:
	var s := _world()
	var d: TestRite = s.d
	var r: Dictionary = d.report()
	t.check(r.has("rite") and r.rite.id == RiteBook.FIRST_TASTE and r.rite.shards == 0 and r.rite.need == 3 and r.rite.flame_out == false,
		"report().rite carries the id, the shards, the need and the flame (%s)" % [r])
	t.check(d.hud_line() == "Lantern shards 0/3" and not d.stages_done() and d.lost_reason() == "", "the HUD line, the stages and no loss of its own")
	d.shards = 3
	t.check(d.stages_done() and d.report().rite.shards == 3, "three shards are the win")
	_done(s)


## A freed body in the director's lists never aborts a function (review I1/I2): a captive that escaped, a breaker freed mid-grip, a marked victim and
## a runner freed, with the stand-in keeping its raw breaker list as a real subclass does.
static func _freed_people(t) -> void:
	# (a) the captive is freed mid-drag.
	var s := _world()
	var d: TestRite = s.d
	var v := _dragging(s, 0, FAR)
	var keep: Person = d.marked[1]
	_run(s, 2.0)
	v.free()
	_run(s, 0.6)
	t.check(d.shards == 0 and d.captive == null and d.chain_state == RiteDirector.Chain.COOLDOWN and (s.banners as Array).has(RiteDirector.LOST_BANNER),
		"a captive freed mid-drag is wasted: no shard, the chain cools down")
	t.check(d.marked.has(keep) and d.tags().size() >= 4 and d.left() >= 3, "and tags() and left() still work (%d tags, %d left)" % [d.tags().size(), d.left()])
	_done(s)
	# (b) the breaker is freed while gripping.
	s = _world()
	d = s.d
	v = _dragging(s, 0, FAR, Vector2(0.4, 0.0))
	_run(s, 1.0)
	var gripping: bool = d.grip_by == d.breaker and d.grip > 0.5
	var before := v.ground_pos
	d.breaker.free()
	_run(s, 0.3)
	t.check(gripping and d.grip == 0.0 and d.grip_by == null, "a breaker freed mid-grip: the grip resets (grip %.2f)" % d.grip)
	_run(s, 1.5)
	t.check(v.ground_pos.distance_to(before) > 0.5 and d.chain_state == RiteDirector.Chain.DRAG, "and the drag walks on (%.2f units)" % v.ground_pos.distance_to(before))
	t.check(d.busy(d.marked[1]) and d.held(d.raw[0]), "busy() and held() pass over the freed breaker")
	_done(s)
	# (c) a marked victim and a runner are freed: the looks go on, and the rule replaces them.
	s = _world()
	d = s.d
	var gone: Person = d.marked[1]
	var runner: Person = d.marked[2]
	var keep0: Person = d.marked[0]
	var keep3: Person = d.marked[3]
	d._runners.append(runner)
	gone.free()
	runner.free()
	var replaced_before := d.replaced
	_run(s, 0.8)
	t.check(d.replaced == replaced_before + 2 and d.marked.has(keep0) and d.marked.has(keep3) and d.left() == 4,
		"freed victims and runners: the living stay marked and _look() reaches the replacement rule, which adds two (%d calls, %d left)" % [d.replaced, d.left()])
	t.check(d.chain_at(Vector2(-25.0, -25.0)) == "NOT A LAMPLIGHTER" and d.left() >= 3 and not d.tags().is_empty(),
		"and chain_at(), left() and tags() work (%d left)" % d.left())
	_done(s)


## The sacrifice is quiet (review I3, MS §2 "Noise: Quiet"): the crowd counts no kill and the town's alarm does not move.
static func _quiet_sacrifice(t) -> void:
	var s := _world()
	var d: TestRite = s.d
	var crowd: Crowd = s.crowd
	var v := _victim(d, 0, NEAR)
	var alarm := crowd.alarm
	var kills := crowd.killed_citizens
	d.chain(v)
	_run(s, 2.0)
	t.check(d.shards == 1 and not MissionDirector._alive(v), "the captive was sacrificed")
	t.check(crowd.alarm == alarm and crowd.killed_citizens == kills,
		"and the town heard nothing: alarm %.2f (was %.2f), kills %d (was %d)" % [crowd.alarm, alarm, crowd.killed_citizens, kills])
	_done(s)


## A walk that found no way (a Thornwall across his lane, a jam) leaves the captive with no goal; the drag tries again, so the chain is never stuck
## in its drag for good (found by Task 7's scripted Passage: a wall between the captive and a breaker stalled him until dawn).
static func _blocked_walk_retries(t) -> void:
	var s := _world()
	var d: TestRite = s.d
	var v := _dragging(s, 0, FAR)
	_run(s, 2.0)
	t.check(v.has_goal() and d.chain_state == RiteDirector.Chain.DRAG, "the captive is walking")
	var at := v.ground_pos
	d._clear_walk(v)
	t.check(not v.has_goal(), "(his walk is lost)")
	_run(s, 1.0)
	t.check(v.has_goal(), "a captive who lost his walk is sent on again within a second")
	var before := v.ground_pos
	_run(s, 3.0)
	t.check(v.ground_pos.distance_to(before) > 0.5 and v.ground_pos.distance_to(d.shrine()) < at.distance_to(d.shrine()),
		"and walks on toward the shrine (%.1f units nearer)" % [at.distance_to(d.shrine()) - v.ground_pos.distance_to(d.shrine())])
	_done(s)


## A captive who cannot move for STUCK_SECONDS and is not gripped (set down in a closed pocket by a Mirrorfold, say) is let go of like a broken chain, so
## the chain is free for another victim; one who keeps walking, or who is gripped, is not.
static func _stuck_captive_freed(t) -> void:
	var s := _world()
	var d: TestRite = s.d
	var v := _dragging(s, 0, FAR)
	_run(s, 2.0)
	t.check(d.chain_state == RiteDirector.Chain.DRAG, "the captive is in his drag")
	_run(s, RiteDirector.STUCK_SECONDS * 1.5)
	t.check(d.chain_state == RiteDirector.Chain.DRAG, "a captive who keeps walking is never let go of (%s)" % [RiteDirector.Chain.keys()[d.chain_state]])
	var at := v.ground_pos
	var held_for := 0.0
	while held_for < RiteDirector.STUCK_SECONDS - 1.0:
		v.ground_pos = at
		_step(s)
		held_for += DT
	t.check(d.chain_state == RiteDirector.Chain.DRAG, "stood still for %.0f s: not yet let go of" % held_for)
	while held_for < RiteDirector.STUCK_SECONDS + 2.0 and d.chain_state == RiteDirector.Chain.DRAG:
		v.ground_pos = at
		_step(s)
		held_for += DT
	t.check(d.chain_state == RiteDirector.Chain.COOLDOWN and d.captive == null and (s.banners as Array).has(RiteDirector.FREED_BANNER),
		"stood still %.1f s: the chain lets go of him (cooldown, THE CHAIN BREAKS)" % held_for)
	t.check(not v.chained, "and he is no longer chained")
	_done(s)


## Task 7 review I4: a man the chain let go of because he could not move (a closed pocket) is no victim the night can use, so the replacement rule sends
## another when the count falls short; a man freed by a grip is not stranded and counts as before.
static func _stranded_replaced(t) -> void:
	var s := _world()
	var d: TestRite = s.d
	var v := _dragging(s, 0, FAR)
	_run(s, 2.0)
	t.check(d.left() == 4 and d.replaced == 0, "four victims in play, none added (%d left, %d added)" % [d.left(), d.replaced])
	var at := v.ground_pos
	var held_for := 0.0
	while held_for < RiteDirector.STUCK_SECONDS + 2.0 and d.chain_state == RiteDirector.Chain.DRAG:
		v.ground_pos = at
		_step(s)
		held_for += DT
	t.check(d.chain_state == RiteDirector.Chain.COOLDOWN and d._stranded.has(v), "the stuck captive is freed and marked stranded")
	t.check(d.left() == 4 - 1 + d.replaced, "he is no longer counted as in play (%d left, %d replacements)" % [d.left(), d.replaced])
	_run(s, 0.6)
	t.check(d.replaced == 1 and d.left() == 4, "and a replacement sets out (%d calls, %d left)" % [d.replaced, d.left()])
	_done(s)
	# A grip frees a man who can still be chained: he stays counted and nothing is stranded.
	s = _world()
	d = s.d
	var w := _dragging(s, 0, FAR, Vector2(0.5, 0.0))
	_until(s, 8.0, func() -> bool: return d.chain_state == RiteDirector.Chain.COOLDOWN)
	t.check(w != null and d._stranded.is_empty() and d.left() == 4, "a grip strands nobody (%d stranded, %d left)" % [d._stranded.size(), d.left()])
	_done(s)
