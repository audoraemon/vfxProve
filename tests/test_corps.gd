extends RefCounted
## v0.07 soldiers' roles: each soldier takes a role from its post -- the barracks yard's first squads dig (Rescue), the
## walls' first take the ways out (Marshal), the first patrols guard the responders (Escort, v0.09.1: only as many as
## the tier's duties use) -- up to the profile's counts; only the rest rally at the Citadel; each role is drawn its own
## way. Once rallied, the ring is the reserve (v0.09.1): a role soldier killed is replaced from it, and it garrisons the
## Citadel.


static func _crowd(tier := ResponseProfile.Tier.ORGANIZED, unaware := false) -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.unaware() if unaware else ResponseProfile.for_tier(tier)
	crowd.spawn()
	return [crowd, env, world, field, grid, town]


## Every soldier walking to the rally ring arrives at its slot (other suites use it too).
static func ring(crowd: Crowd) -> void:
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and p.mind == Person.Mind.RALLY and p.has_goal():
			p.ground_pos = p.goal()
			p._goal = Vector2.INF
			p._path = PackedVector2Array()


## The soldiers standing on the rally ring now.
static func on_ring(crowd: Crowd) -> Array[Person]:
	var out: Array[Person] = []
	for p in crowd.soldiers:
		if crowd.on_ring(p):
			out.append(p)
	return out


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
	# The escorts by need (v0.09.1): escorts_per_duty x the duties the tier has (the bell, the rite, each engineer
	# team), the first patrols in post order; the other patrols keep no role, and rally.
	var caps := {"Unaware": 0, "Unprepared": 0, "Organized": 1, "Prepared": 2 * (1 + 1 + 2),
		"God-Resistant": 2 * (1 + 1 + 3)}
	for tier in [-1, ResponseProfile.Tier.UNPREPARED, ResponseProfile.Tier.ORGANIZED, ResponseProfile.Tier.PREPARED,
			ResponseProfile.Tier.GOD_RESISTANT]:
		var made := _crowd(maxi(tier, ResponseProfile.Tier.UNPREPARED) as ResponseProfile.Tier, tier < 0)
		var crowd: Crowd = made[0]
		var pr := crowd.profile
		var cap: int = caps[pr.tier_name()]
		var first := Crowd.POST_YARD + Crowd.POST_WALLS + Crowd.POST_CITADEL
		var in_order := true
		for i in Crowd.POST_PATROL:
			var want := Person.Corps.ESCORT if i < cap else Person.Corps.NONE
			in_order = in_order and crowd.soldiers[first + i].corps == want
		t.check(Crowd.escort_cap(pr) == cap and _count(crowd, Person.Corps.ESCORT) == cap and in_order,
			"%s: %d escorts, the first patrols; the other %d patrols keep no role" % [pr.tier_name(),
			_count(crowd, Person.Corps.ESCORT), Crowd.POST_PATROL - cap])
		crowd.rally()
		var rallied := 0
		for i in Crowd.POST_PATROL:
			rallied += 1 if crowd.soldiers[first + i].mind == Person.Mind.RALLY else 0
		t.check(rallied == Crowd.POST_PATROL - cap, "%s: and they rally (%d)" % [pr.tier_name(), rallied])
		_done(made)

	for tier in [ResponseProfile.Tier.ORGANIZED, ResponseProfile.Tier.GOD_RESISTANT]:
		var made := _crowd(tier)
		var crowd: Crowd = made[0]
		var pr := crowd.profile
		var exits := 2 + (2 if pr.boats else 0)
		var marshals := _count(crowd, Person.Corps.MARSHAL)
		var rescue := _count(crowd, Person.Corps.RESCUE)
		var escorts := _count(crowd, Person.Corps.ESCORT)
		t.check(marshals == pr.marshals_per_exit * exits and rescue == pr.rescue_squads * Crowd.RESCUE_SQUAD
			and escorts == Crowd.escort_cap(pr),
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
	_no_refill(t)
	_garrison(t)
	_freed(t)


## The first living soldier of `corps`.
static func first_of(crowd: Crowd, corps: Person.Corps) -> Person:
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and p.corps == corps:
			return p
	return null


## No reserve before the rally, nor once the ring is empty, nor for a town that never rallies.
static func _no_refill(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var none := _count(crowd, Person.Corps.NONE)
	var marshals := _count(crowd, Person.Corps.MARSHAL)
	field.kill(first_of(crowd, Person.Corps.MARSHAL), &"test")
	t.check(_count(crowd, Person.Corps.NONE) == none and _count(crowd, Person.Corps.MARSHAL) == marshals,
		"before the rally a marshal killed is not replaced")
	crowd.rally()
	ring(crowd)
	var standing := on_ring(crowd)
	t.check(standing.size() > 0, "the rally rings the Citadel (%d)" % standing.size())
	for p in standing:
		field.kill(p, &"test")
	t.check(on_ring(crowd).is_empty(), "the ring killed to the last soldier")
	# (_count() counts the dead too: a soldier taking a role would move one from NONE to it.)
	none = _count(crowd, Person.Corps.NONE)
	var roles := [Person.Corps.MARSHAL, Person.Corps.RESCUE, Person.Corps.ESCORT]
	var before: Array = roles.map(func(c: Person.Corps) -> int: return _count(crowd, c))
	for c in roles:
		field.kill(first_of(crowd, c), &"test")
	var after: Array = roles.map(func(c: Person.Corps) -> int: return _count(crowd, c))
	t.check(_count(crowd, Person.Corps.NONE) == none and after == before,
		"with the ring empty, nobody takes a dead soldier's role (%s)" % [after])
	_done(made)

	# The leaderless town (forgo_rally()) has nobody on the ring to send.
	made = _crowd()
	crowd = made[0]
	crowd.forgo_rally()
	none = _count(crowd, Person.Corps.NONE)
	(made[3] as EnemyField).kill(first_of(crowd, Person.Corps.MARSHAL), &"test")
	t.check(_count(crowd, Person.Corps.NONE) == none, "a town that never rallied has no reserve")
	_done(made)


## The ring garrisons the Citadel: its count reaches the Citadel's damage filter; a Town built without a crowd has none.
static func _garrison(t) -> void:
	var env := EnvironmentField.new()
	var bare := Town.new()
	bare.build(env)
	t.check(bare.citadel.garrison_cut() == 0.0, "a Citadel with no crowd has no garrison")
	env.clear()
	env.free()

	var made := _crowd()
	var crowd: Crowd = made[0]
	var citadel: Citadel = (made[5] as Town).citadel
	t.check(crowd.ring_count() == 0 and citadel.garrison_cut() == 0.0, "before the rally nobody garrisons the Citadel")
	crowd.rally()
	var walking := crowd.ring_count()
	ring(crowd)
	var n := crowd.ring_count()
	t.check(n == on_ring(crowd).size() and n > walking and n >= Crowd.POST_CITADEL,
		"rallied, the soldiers who reach the ring garrison it (%d, %d before they arrived)" % [n, walking])
	t.near(citadel.garrison_cut(), minf(float(n) * Citadel.GARRISON_STEP, Citadel.GARRISON_CAP), 0.0001,
		"the Citadel reads the ring's count (cut %.2f)" % citadel.garrison_cut())
	_done(made)


## A soldier freed while still on the roster (its death fade ended before _prune_soldiers() ran): the Citadel's next
## look at its garrison and the next refill pass it by, with no typed-argument error (v0.09.1 Task 3 review).
static func _freed(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	crowd.rally()
	ring(crowd)
	var standing := on_ring(crowd)
	var gone: Person = standing[0]
	field.kill(gone, &"test")
	field.remove(gone)
	gone.free()
	var freed := 0
	for i in crowd.soldiers.size():
		freed += int(not is_instance_valid(crowd.soldiers[i]))
	t.check(freed == 1, "the freed soldier is still on the roster (%d)" % freed)
	t.check(crowd.ring_count() == standing.size() - 1,
		"the ring counts the rest (%d of %d)" % [crowd.ring_count(), standing.size() - 1])
	var marshal := first_of(crowd, Person.Corps.MARSHAL)
	var post := marshal.post
	field.kill(marshal, &"test")
	var took := 0
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and p.corps == Person.Corps.MARSHAL and p.post == post:
			took += 1
	t.check(took == 1 and crowd.ring_count() == standing.size() - 2,
		"a dead marshal is still replaced from the ring (%d, ring %d)" % [took, crowd.ring_count()])
	_done(made)
