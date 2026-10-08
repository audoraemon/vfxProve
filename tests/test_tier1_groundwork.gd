extends RefCounted
## v0.11 M2 the groundwork for Tier 1's new missions: the director's eligibility helpers skip reserved people and places and
## freed bodies (review focus 1, 2); a wish's building is reserved like its people; unaware_town comes from a board mission's
## readiness; the board's own missions are found by id. And M1's two carried items: a soldier turned to fight is the god's
## doing (RescueWish.TURNED), and The Warning's later stars fall "by" their time (test_starfall pins the words).

const DT := 0.05


static func run(t) -> void:
	_helpers(t)
	_places(t)
	_tags(t)
	_book(t)
	_carried(t)


static func _world() -> Dictionary:
	var def := MissionBook.warning()
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
	var director := MissionDirector.new().setup(rules, crowd, town, null)
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director}


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


static func _def(id: String) -> WishDef:
	for d in WishBook.pool():
		if d.id == id:
			return d
	return null


static func _helpers(t) -> void:
	var s := _world()
	var d: MissionDirector = s.d
	var crowd: Crowd = s.crowd
	var at := Vector2(0.0, 4.0)
	var two := d._free_soldiers(at, 2)
	t.check(two.size() == 2 and two[0].soldier and two[0].corps == Person.Corps.NONE
		and two[0].ground_pos.distance_to(at) <= two[1].ground_pos.distance_to(at), "the two free soldiers nearest, nearest first")
	d.reserved.append(two[0])
	var next := d._free_soldiers(at, 2)
	t.check(not next.has(two[0]) and next[0] == two[1], "a reserved soldier is skipped (review focus 1)")
	t.check(not d._free_soldiers(at, 1, [two[1]]).has(two[1]), "and an excluded one")
	var lay := d._lay_near(at, 3)
	var lay_ok := lay.size() == 3
	for p in lay:
		lay_ok = lay_ok and p.profile.faith == CitizenProfile.Faith.NONE and not p.profile.role in Wish.NOT_LAY and not p.inside
	t.check(lay_ok, "three lay citizens: of no faith, no responder's role, out of doors")
	d.reserved.append(lay[0])
	t.check(not d._lay_near(at, 3).has(lay[0]), "a reserved citizen is skipped")
	var cleric := d._citizen_near(at, CitizenProfile.Role.CLERGY)
	t.check(cleric != null and cleric.profile.role == CitizenProfile.Role.CLERGY, "the nearest cleric")
	d.reserved.append(cleric)
	t.check(d._citizen_near(at, CitizenProfile.Role.CLERGY) != cleric, "a reserved cleric is skipped")
	var house := d._house_near(at)
	t.check(house != null and RuinWish.fits(house, "house"), "the nearest dwelling")
	d.reserved_places.append(house)
	var other := d._house_near(at)
	var third := d._house_near(at, [other])
	t.check(other != null and other != house and third != house and third != other,
		"a reserved dwelling is skipped, and an excluded one")
	t.check(not d._eligible(null) and not d._eligible(lay[0]) and d._eligible(lay[1]), "eligible: standing, out of doors, not reserved")
	var who := lay[2]
	d._take_inside(who, house)
	t.check(who.inside and not who.visible and who.ground_pos == house.center() and not d._eligible(who),
		"taken indoors: hidden, at the house, not eligible")
	var front := d._front_of(house)
	d._bring_out(who, front)
	t.check(not who.inside and who.visible and who.ground_pos == front
		and front.distance_to(house.center()) <= house.footprint.size.length() + 1.5, "brought out at its front")
	d._set_down(who, at)
	t.check(who.ground_pos == at and who.anchor == at and not who.has_goal(), "set down, its walk dropped")
	t.check(d._ring_spot(at, 1.0, 0, 4).distance_to(at) <= 1.6, "a place on a ring round a point")
	# A body freed after its death fade is neither eligible nor gathered (review focus 2).
	var gone := lay[1]
	crowd._field.remove(gone)
	crowd.citizens.erase(gone)
	gone.free()
	t.check(not d._eligible(gone) and not d._lay_near(at, 5).has(gone), "a freed body is neither eligible nor gathered")
	_done(s)


static func _places(t) -> void:
	var s := _world()
	var d: MissionDirector = s.d
	var r := RandomNumberGenerator.new()
	r.seed = 3
	var w := _def("moneylender").instance()
	t.check(w.choose(s.crowd, s.town, r, []) and w.places().size() == 1 and w.places()[0] == (w as RuinWish).target,
		"a Ruin wish sets its building aside")
	t.check(_def("sign").instance().places().is_empty(), "the other wishes set no building aside")
	var night := Descent.new().setup(MissionBook.warning(), 1)
	night.wishes.assign([w])
	night._heard = true
	night.reserve(s.rules, d)
	t.check(d.reserved_places.has((w as RuinWish).target) and d.reserved.has(w.wisher),
		"the night reserves its wishes' buildings with their people")
	night.reserve(s.rules, d)
	t.check(d.reserved_places.size() == 1, "once only")
	_done(s)


static func _tags(t) -> void:
	t.check(Array(TierBook.board("warning").mission_tags) == [TierBook.UNAWARE_TAG],
		"The Warning carries unaware_town, from its town's readiness")
	var miras := TierBook.board("miras_house").mission_tags
	t.check(not miras.has(TierBook.UNAWARE_TAG) and miras.has("spares_houses") and TierBook.board("festival").mission_tags.is_empty()
		and TierBook.board("long_night").mission_tags.is_empty(),
		"a raised town is not unaware: Mira's House keeps only its own tag; the Festival and The Long Night have none")
	t.check(not TierBook.MISSION_TAGS.has("warning"), "and no mission declares unaware_town itself")


static func _book(t) -> void:
	var ok := true
	for m in MissionBook.tier_missions():
		ok = ok and MissionBook.get_mission(m.id).id == m.id and is_equal_approx(m.clock, TierBook.clock(m.tier))
		ok = ok and m.bonuses().is_empty() and m.tier >= 1
		for a in MissionBook.all():
			ok = ok and a.id != m.id
		for c in MissionBook.campaign_missions():
			ok = ok and c.id != m.id
	t.check(ok, "the board's own missions: found by id, at their tier's clock, no bonuses, in neither the v0.09 list nor the campaign")
	var m1 := MissionBook._tier1("x", "X", PackedStringArray(["a", "b"]))
	t.check(m1.tier == 1 and m1.slots == 3 and m1.dp_capacity == 6 and is_equal_approx(m1.clock, 300.0) and m1.profile == "unaware"
		and m1.intro_banner == "X" and m1.bonuses().is_empty(), "a Tier 1 mission's numbers")


static func _carried(t) -> void:
	t.check(RescueWish.TURNED.has(Person.Mind.FIGHT), "a soldier turned to fight is the god's doing (M1 final review)")
	var s := _world()
	var r := RandomNumberGenerator.new()
	r.seed = 3
	var w := _def("child").instance() as RescueWish
	var chosen := w.choose(s.crowd, s.town, r, [])
	if chosen:
		w.engage()
		w.soldier.mind = Person.Mind.FIGHT
	t.check(chosen and w.check(s.rules) == Objective.Status.DONE, "Save my child: its soldier turned to fight grants it")
	w.release()
	_done(s)
