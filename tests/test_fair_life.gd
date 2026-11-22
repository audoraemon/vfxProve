extends RefCounted
## Talking groups at Market Panic's fair (fair life, 2026-11-20, FairLife): each crowd that sets out stands in knots of 2..4
## round a centre (the director's spots are the ring slots), the arrived talk (anim 13) facing the middle, every knot strolls to a
## new centre now and then -- inside the fair's radius, with a way for every member, APART from the other knots -- a knot that
## loses people mends itself, the fair's rules (steadied, _may_break) are untouched, and nothing is drawn from the town's stream.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_groups_form(t)
	_talk(t)
	_stroll_inside(t)
	_group_losses(t)
	_rules_kept(t)
	_no_town_draw(t)
	_late_goer(t)
	_after_close(t)
	_no_resend(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.market_panic())


static func _groups_form(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var seen := {}
	var sized := true
	var spots := true
	for grp: Array in d.life.groups():
		sized = sized and grp.size() >= FairLife.GROUP_MIN and grp.size() <= FairLife.GROUP_MAX
		for v: Variant in grp:
			var p := v as Person
			seen[p.get_instance_id()] = int(seen.get(p.get_instance_id(), 0)) + 1
			spots = spots and d._spots[p.get_instance_id()] == d.life.spot_of(p)
	var covers := seen.size() == (d.waves[0] as Array).size()
	for v: Variant in d.waves[0]:
		covers = covers and int(seen.get((v as Person).get_instance_id(), 0)) == 1
	t.check(sized and covers and spots, "the first crowd stands in groups of 2..4, each goer in exactly one, spots from the groups (%d groups)" % d.life.groups().size())
	Kit.done(s)


static func _talk(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var g := (d.waves[0] as Array)[0] as Person
	var spot: Vector2 = d._spots[g.get_instance_id()]
	Kit.arrive(g, spot)
	Kit.run_for(s, MarketPanicDirector.TICK + DT)
	for i in 6:
		g.frame(DT)
	var centre := d.life.centre_of(g)
	var to := centre - g.ground_pos
	var art := not g._own_art(13) or g._interact_anim() == 13
	t.check(g.mind == Person.Mind.DUTY and g.chat_at == centre and centre != Vector2.INF and art,
		"a goer arrived at his spot talks: on duty, chat_at his group's centre, the talk art")
	# Faced from where he stands: put him two tiles off the middle (the director has not looked yet) and let him think.
	Kit.arrive(g, centre + Vector2(2.0, 0.5))
	for i in 6:
		g.frame(DT)
	to = centre - g.ground_pos
	t.check(g._facing == (1 if to.x - to.y > 0.0 else -1) and g._back == (to.x + to.y < 0.0), "he faces the middle of his group")
	g.flinch(g.ground_pos + Vector2(2.0, 0.0))
	t.check(g.flinching() and g._interact_anim() != 13, "while he flinches the talk art is off")
	var walker := (d.waves[0] as Array)[1] as Person
	Kit.arrive(walker, d._spots[walker.get_instance_id()] + Vector2(3.0, 0.0))
	Kit.run_for(s, MarketPanicDirector.TICK + DT)
	t.check(walker.chat_at == Vector2.INF, "a goer still walking to his spot does not talk")
	Kit.done(s)


static func _stroll_inside(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var keys := []
	for grp: Array in d.life.groups():
		keys.append((grp[0] as Person).get_instance_id())
	var last := {}
	var moved := {}
	var inside := true
	var reach := true
	var ring := true
	var apart_bad := 0
	for step in roundi(120.0 / DT):
		Kit.run_for(s, DT)
		var centres: Array[Vector2] = []
		var changed := false
		for grp: Array in d.life.groups():
			var c := d.life.centre_of(grp[0])
			centres.append(c)
			var id := (grp[0] as Person).get_instance_id()
			if last.has(id) and last[id] != c:
				changed = true
				if keys.has(id):
					moved[id] = true
				inside = inside and c.distance_to(MarketPanicDirector.HEART) <= MarketPanicDirector.FAIR_R + 0.01
				for v: Variant in grp:
					reach = reach and d._reaches(v, c)
					ring = ring and d.life.spot_of(v).distance_to(MarketPanicDirector.HEART) <= MarketPanicDirector.FAIR_R + 0.01
			last[id] = c
		if changed:
			var bad := false
			for i in centres.size():
				for j in range(i + 1, centres.size()):
					bad = bad or centres[i].distance_to(centres[j]) < FairLife.APART - 0.01
			apart_bad += 1 if bad else 0
	var all_moved := true
	for k in keys:
		all_moved = all_moved and moved.has(k)
	t.check(all_moved and inside and reach, "in 120 s every first-crowd group strolled; each centre within FAIR_R and reachable by its people (moved %d/%d)" % [moved.size(), keys.size()])
	t.check(ring, "every ring spot of a stroll stays within FAIR_R + 0.01 of the fountain")
	t.check(apart_bad <= 1, "centres stay APART at each stroll (%d strolls under)" % apart_bad)
	Kit.done(s)


static func _group_losses(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var crowd: Crowd = s.crowd
	var groups := d.life.groups()
	groups.sort_custom(func(a: Array, b: Array) -> bool: return a.size() < b.size())
	var mine: Array = groups[0]
	# One killed, the rest but one broken: a lone survivor.
	var dead := mine[0] as Person
	var survivor := mine[mine.size() - 1] as Person
	crowd._field.kill(dead, &"doom")
	var broke: Array[Person] = []
	for k in range(1, mine.size() - 1):
		d._broke[mine[k]] = true
		broke.append(mine[k] as Person)
	# The survivor joins a group with room below GROUP_MAX. When every other group stands full, one of its people breaks too, which
	# leaves that group the room: the check states the invariant (a survivor joins a group with room), not a group size.
	var room_at_start := false
	for grp: Array in groups:
		room_at_start = room_at_start or (grp != mine and grp.size() < FairLife.GROUP_MAX)
	if not room_at_start:
		d._broke[(groups[groups.size() - 1] as Array)[0]] = true
	Kit.run_for(s, MarketPanicDirector.TICK * 2.0 + DT)
	var spare := false
	for grp: Array in d.life.groups():
		spare = spare or (not grp.has(survivor) and grp.size() >= FairLife.GROUP_MIN and grp.size() < FairLife.GROUP_MAX)
	var out := dead.chat_at == Vector2.INF and d.life.spot_of(dead) == Vector2.INF
	for p in broke:
		out = out and p.chat_at == Vector2.INF and d.life.spot_of(p) == Vector2.INF and p._interact_anim() != 13
	t.check(out, "the dead and the broken are out of their group: no spot, no chat_at, no talk anim")
	Kit.run_for(s, FairLife.STROLL.y + 1.0)
	var size := 0
	for grp: Array in d.life.groups():
		if grp.has(survivor):
			size = grp.size()
	t.check(spare and size >= FairLife.GROUP_MIN, "the lone survivor is in a group of 2+ after the next stroll (spare room %s, size %d)" % [spare, size])
	Kit.done(s)


static func _rules_kept(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var crowd: Crowd = s.crowd
	var env: EnvironmentField = s.env
	var house: Structure = null
	for st in env.structures():
		if is_instance_valid(st) and not st.destroyed and st.kind in FireManager.BURNABLE and st.kind != Structure.Kind.TREE \
				and (house == null or st.center().distance_to(MarketPanicDirector.HEART) < house.center().distance_to(MarketPanicDirector.HEART)):
			house = st
	var g := (d.waves[0] as Array)[0] as Person
	Kit.arrive(g, house.center() + Vector2(0.0, house.footprint.size.y * 0.5 + 0.6))
	var warden := d.wards[0].man as Person
	Kit.arrive(warden, g.ground_pos + Vector2(1.5, 0.0))
	Kit.run_for(s, MarketPanicDirector.TICK + DT)
	crowd.fires.ignite(house, EmberFx.START_LEVEL)
	Kit.run_for(s, 8.0)
	t.check(d.steadied(g) and not d._may_break(g) and not d.broke_list().has(g) and g.mind != Person.Mind.PANIC and d.life.spot_of(g) != Vector2.INF,
		"steadied by a warden at his group's spot beside a burning house: not broken, still in his group")
	var other := (d.waves[0] as Array)[5] as Person
	t.check(not d.is_waiting(other) and d._may_break(other) == (not d.steadied(other)), "_may_break() is the fair's old rule for the rest")
	Kit.done(s)


static func _no_town_draw(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var crowd: Crowd = s.crowd
	var before := crowd._rng.state
	var life := FairLife.new(1234, MarketPanicDirector.HEART, MarketPanicDirector.FAIR_R, d._reaches, d._walkable)
	life.form(d.waves[1])
	for i in roundi(60.0 / DT):
		life.step(DT)
	t.check(crowd._rng.state == before and life.groups().size() > 0, "forming groups and 60 s of strolling draw nothing from the town's stream")
	Kit.done(s)


## A goer with no spot when his crowd set out is given one he can walk to (fair life review, 2026-11-21).
static func _late_goer(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var late: Person = null
	for v: Variant in d.waves[1]:  # a crowd still waiting: in no group yet
		late = v as Person
		break
	Kit.arrive(late, MarketPanicDirector.HEART + Vector2(1.0, 1.0))
	var changed := d.life.join(late)
	var spot := d.life.spot_of(late)
	var ok := not changed.is_empty() and spot != Vector2.INF and d._reaches(late, spot) and d._reaches(late, d.life.centre_of(late))
	for v: Variant in changed:
		ok = ok and d._reaches(v, d.life.centre_of(v))
	t.check(ok, "a late goer joins a group at a centre he can walk to, with a spot of his own")
	# One no group's centre can be walked to stands alone, as form() would place him.
	var shut := Person.new()
	var life := FairLife.new(5, MarketPanicDirector.HEART, MarketPanicDirector.FAIR_R,
		func(p: Person, at: Vector2) -> bool: return p != shut or at.distance_to(MarketPanicDirector.HEART) < 0.0, d._walkable)
	life.form(d.waves[0])
	life.join(shut)
	var alone := false
	for grp: Array in life.groups():
		alone = alone or (grp.size() == 1 and grp[0] == shut)
	t.check(alone, "a goer who can reach no group's centre stands alone, not merged into one he cannot walk to")
	shut.free()
	Kit.done(s)


static func _after_close(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	d._close()
	var late := (d.waves[2] as Array)[0] as Person
	var changed := d.life.join(late)
	t.check(changed.is_empty() and d.life.spot_of(late) == Vector2.INF and d.life.groups().is_empty(),
		"after the close nobody joins a group")
	d._to_fair(late)
	t.check(not d._spots.has(late.get_instance_id()), "a late goer sent after the close is given no spot")
	Kit.done(s)


static func _no_resend(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var grp: Array = d.life.groups()[0]
	var mate := grp[0] as Person
	var control := grp[1] as Person
	d._broke[mate] = true
	for p in [mate, control]:
		p.go_duty(p.ground_pos)  # his anchor is off his spot
	var held := mate.anchor
	d._apply([mate, control])
	t.check(mate.anchor == held and control.anchor.distance_to(d._spots[control.get_instance_id()]) < 0.01,
		"_apply sends a goer on duty to his new spot but leaves a broken one where he is")
	Kit.done(s)
