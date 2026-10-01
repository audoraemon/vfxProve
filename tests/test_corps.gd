extends RefCounted
## v0.07 soldiers' roles: each soldier takes a role from its post -- the barracks yard's first squads dig (Rescue), the
## walls' first take the ways out (Marshal), the patrols guard the responders (Escort) -- up to the profile's counts;
## only the rest rally at the Citadel; each role is drawn its own way.


static func _crowd(tier := ResponseProfile.Tier.ORGANIZED) -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(tier)
	crowd.spawn()
	return [crowd, env, world, field, grid, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[2] as Node).free()


static func _count(crowd: Crowd, corps: Person.Corps) -> int:
	var n := 0
	for p in crowd.soldiers:
		if p.corps == corps:
			n += 1
	return n


static func run(t) -> void:
	for tier in [ResponseProfile.Tier.ORGANIZED, ResponseProfile.Tier.GOD_RESISTANT]:
		var made := _crowd(tier)
		var crowd: Crowd = made[0]
		var pr := crowd.profile
		var exits := 2 + (2 if pr.boats else 0)
		var marshals := _count(crowd, Person.Corps.MARSHAL)
		var rescue := _count(crowd, Person.Corps.RESCUE)
		var escorts := _count(crowd, Person.Corps.ESCORT)
		t.check(marshals == pr.marshals_per_exit * exits and rescue == pr.rescue_squads * Crowd.RESCUE_SQUAD
			and escorts == Crowd.POST_PATROL,
			"%s: %d marshals, %d in rescue squads, %d escorts" % [pr.tier_name(), marshals, rescue, escorts])
		var posts_kept := true
		for p in crowd.soldiers:
			posts_kept = posts_kept and p.post == p.anchor
		t.check(posts_kept, "every soldier remembers its post")
		# Only soldiers without a role rally at the Citadel.
		crowd.rally()
		var wrong := 0
		for p in crowd.soldiers:
			var rallied := p.mind == Person.Mind.RALLY
			if rallied != (p.corps == Person.Corps.NONE):
				wrong += 1
		t.check(wrong == 0, "%s: only soldiers without a role rally (%d wrong)" % [pr.tier_name(), wrong])
		_done(made)

	# Soldiers can take a duty and be sent to a fire; off duty a soldier goes back to its post.
	var made := _crowd()
	var crowd: Crowd = made[0]
	var s: Person = crowd.soldiers[0]
	s.go_duty(s.ground_pos + Vector2(1, 0))
	t.check(s.mind == Person.Mind.DUTY, "a soldier can take a duty")
	crowd.off_duty(s)
	t.check(s.mind == Person.Mind.POST and s.anchor == s.post, "and goes back to its post after")
	var house: Structure = null
	for st in (made[1] as EnvironmentField).structures():
		if st.role == &"house" and house == null:
			house = st
	s.assist(house)
	t.check(s.mind != Person.Mind.ASSIST, "a soldier is not sent to a fire unasked")
	s.assist(house, true)
	t.check(s.mind == Person.Mind.ASSIST and s.assist_fire == house, "but can be, by its squad")
	s.stand_down()
	t.check(s.mind == Person.Mind.POST and s.anchor == s.post, "stood down, a soldier goes back to its post")
	_done(made)
