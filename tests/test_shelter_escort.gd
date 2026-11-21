extends RefCounted
## Soldier duties, slice f: the shelter escort. At City Emergency a household whose first member is home and waits (Mind.REGROUP) is
## led to a shelter with room by two free guards: they run to the house, every member walks to the shelter's door in REGROUP (the
## squad keeps beside the group), and each goes in. A near miss does not scatter a member who has a living, free squad man within
## 2.0; a direct hit does; a squad wiped out scatters them with a banner. Evacuation, a full or lost shelter, or a crew that never
## comes ends it and hands the family back to the normal flow.

const Corps := preload("res://tests/test_corps.gd")
const C := preload("res://tests/test_cordon.gd")
const SHELTER := GuardJobs.Kind.SHELTER
const STEP := 1.0 / 60.0


static func run(t) -> void:
	_trigger(t)
	_no_shelter_none(t)
	_before_after(t)
	_cap_three(t)
	_crew_two(t)
	_mission_man_never(t)
	_mission_member_never(t)
	_walk_in(t)
	_steady(t)
	_direct_hit(t)
	_held_unsteadies(t)
	_scatter(t)
	_evacuation_ends(t)
	_citadel_falls(t)
	_forced_lands(t)
	_cooldown(t)
	_end_to_end(t)
	_own_home(t)
	_capital_escort(t)
	_open_ends(t)
	_shelter_full_midwalk(t)
	_shelter_full_open(t)
	_badges_and_clear(t)
	_freed_crew(t)
	_never_pulled(t)
	_no_rng_without_escort(t)


static func _world() -> Array:
	City.use(&"aldermere")
	return Corps._crowd(ResponseProfile.Tier.PREPARED)


## The board's once-a-second tick, now.
static func _tick(crowd: Crowd) -> void:
	crowd.guard_jobs._tick_left = 0.0
	crowd.guard_jobs.step(0.0)


## Households with a shelter in reach and room: [{"fam", "members", "home", "shelter", "d"}], in family order.
static func _families(crowd: Crowd) -> Array:
	var by := {}
	for p in crowd.citizens:
		if is_instance_valid(p) and p.profile != null and not p.night_indoors:
			if not by.has(p.profile.family):
				by[p.profile.family] = []
			(by[p.profile.family] as Array).append(p)
	var keys := by.keys()
	keys.sort()
	var out: Array = []
	for fam in keys:
		var members: Array = by[fam]
		var home: Vector2 = (members[0] as Person).profile.home
		var s := crowd.shelters.nearest_with_room(home, ShelterEscort.SHELTER_REACH, members.size())
		if s != null:
			out.append({"fam": fam, "members": members, "home": home, "shelter": s, "d": s.distance_to(home)})
	return out


## The family's members wait at home in REGROUP, out of doors, with no goal.
static func _wait(f: Dictionary) -> void:
	for p: Person in f.members:
		p.inside = false
		p.visible = true
		p.mind = Person.Mind.REGROUP
		p.ground_pos = f.home
		p.anchor = f.home
		p._goal = Vector2.INF
		p._path = PackedVector2Array()
		p._target = f.home


## Runs a second at a time until the job is over (everyone is in, or it ended), at most `limit` seconds: the shelter lets its people
## out again 5 s after the last danger, so what is asked of it is asked at the moment the escort ends.
static func _until_over(crowd: Crowd, job: GuardJobs.Job, members: Array, limit: int) -> void:
	for i in limit:
		_run(crowd, 1.0, members)
		if bool(job.data.over):
			return


static func _stage(crowd: Crowd, stage: AlarmManager.Stage) -> void:
	crowd.alarms.stage = stage


## A waiting household with its shelter near (`far` to `near` from its door), at City Emergency: the household, empty when none.
static func _setup(made: Array, near := 8.0, skip := 0, far := 2.0) -> Dictionary:
	var crowd: Crowd = made[0]
	var list := _families(crowd).filter(func(f: Dictionary) -> bool: return f.d <= near and f.d >= far)
	if list.size() <= skip:
		return {}
	var f: Dictionary = list[skip]
	_stage(crowd, AlarmManager.Stage.CITY_EMERGENCY)
	_wait(f)
	return f


## The job of a household, started and its two men set down on the spots they were sent to (null when none).
static func _up(crowd: Crowd, f: Dictionary) -> GuardJobs.Job:
	_tick(crowd)
	var live := crowd.guard_jobs.live(SHELTER)
	if live.is_empty() or live[0].crew.size() < 2:
		return null
	return live[0]


static func _arrive(job: GuardJobs.Job) -> void:
	for m: Variant in job.crew:
		if not is_instance_valid(m):
			continue
		var p: Person = m
		p.ground_pos = p.anchor
		p._goal = Vector2.INF
		p._path = PackedVector2Array()
		p._target = p.anchor


## Every soldier and each of `extra` thinks one step, then the crowd's tick.
static func _run(crowd: Crowd, seconds: float, extra: Array, delta := 0.05) -> void:
	C._run_for(crowd, seconds, extra, delta)


static func _texts(crowd: Crowd) -> Array[String]:
	var out: Array[String] = []
	crowd.duty_event.connect(func(_k: int, text: String, _at: Vector2) -> void: out.append(text))
	return out


## A city emergency, a household 8.0 or less from a shelter with room: one job on the household and its shelter.
static func _trigger(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	t.check(not f.is_empty(), "(a household with a shelter within 8)")
	if f.is_empty():
		C._done(made)
		return
	_tick(crowd)
	var live := crowd.guard_jobs.live(SHELTER)
	t.check(live.size() == 1, "a waiting household with room in reach: one SHELTER job (%d)" % live.size())
	if not live.is_empty():
		t.check(live[0].data.family == f.fam and live[0].data.shelter == f.shelter and live[0].need == 2,
				"it names the family and the shelter and wants two men")
		t.check(crowd.shelter_escort.escorting(f.fam), "the family is escorted once the crew is on")
	C._done(made)


## No shelter in reach (nearest_with_room's reach), or one that is full: no job.
static func _no_shelter_none(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	var d: float = f.d
	t.check(crowd.shelters.nearest_with_room(f.home, d + 0.01, f.members.size()) == f.shelter, "a shelter within its reach is found")
	t.check(crowd.shelters.nearest_with_room(f.home, d - 0.01, f.members.size()) != f.shelter, "one just out of reach is not")
	# Every shelter in reach is full: nothing is posted.
	for s: Structure in crowd.shelters.shelters.keys():
		var e: Dictionary = crowd.shelters.shelters[s]
		(e.coming as Array).resize(ShelterManager.CAPACITY.y)
	t.check(crowd.shelters.room(f.shelter) == 0, "a full shelter has no room")
	_tick(crowd)
	t.check(crowd.guard_jobs.live(SHELTER).is_empty(), "every shelter full: no job")
	C._done(made)


## Only between City Emergency and the Evacuation.
static func _before_after(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	_stage(crowd, AlarmManager.Stage.LOCAL_EMERGENCY)
	_tick(crowd)
	t.check(crowd.guard_jobs.live(SHELTER).is_empty(), "Local Emergency: no job")
	_stage(crowd, AlarmManager.Stage.EVACUATION)
	_tick(crowd)
	t.check(crowd.guard_jobs.live(SHELTER).is_empty(), "Evacuation: no job")
	C._done(made)


## Five waiting households: three jobs in Aldermere; six in the Capital (cap 3 scaled).
static func _cap_three(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var list := _families(crowd)
	t.check(list.size() >= 5, "(five households with a shelter)")
	if list.size() < 5:
		C._done(made)
		return
	_stage(crowd, AlarmManager.Stage.CITY_EMERGENCY)
	for i in 5:
		_wait(list[i])
	_tick(crowd)
	t.check(crowd.guard_jobs.live(SHELTER).size() == 3 and crowd.guard_jobs.cap(ShelterEscort.ESCORT_SQUADS) == 3,
			"Aldermere: five households, three jobs (%d)" % crowd.guard_jobs.live(SHELTER).size())
	C._done(made)
	var cap := _capital()
	var clist := _families(cap[0])
	t.check(clist.size() >= 8, "(eight Capital households with a shelter: %d)" % clist.size())
	if clist.size() >= 8:
		var ccrowd: Crowd = cap[0]
		_stage(ccrowd, AlarmManager.Stage.CITY_EMERGENCY)
		for i in 8:
			_wait(clist[i])
		_tick(ccrowd)
		t.check(ccrowd.guard_jobs.cap(ShelterEscort.ESCORT_SQUADS) == 6 and ccrowd.guard_jobs.live(SHELTER).size() == 6,
				"the Capital: six jobs (%d)" % ccrowd.guard_jobs.live(SHELTER).size())
	_done_capital(cap)


## The crew is the two free guards nearest the house; one free guard: no job.
static func _crew_two(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	var trio := C._trio(crowd, f.home, 3.0)
	C._only_free(crowd, trio)
	_tick(crowd)
	var live := crowd.guard_jobs.live(SHELTER)
	t.check(live.size() == 1 and live[0].crew.size() == 2 and live[0].crew.has(trio[0]) and live[0].crew.has(trio[1])
			and not live[0].crew.has(trio[2]), "the two nearest free guards are the crew")
	C._done(made)
	var made2 := _world()
	var crowd2: Crowd = made2[0]
	var f2 := _setup(made2)
	var one := C._trio(crowd2, f2.home, 3.0)
	C._only_free(crowd2, [one[0]])
	_tick(crowd2)
	t.check(crowd2.guard_jobs.live(SHELTER).is_empty() and not crowd2.guard_jobs.on_job(one[0]), "one free guard: no job, he stays at his post")
	C._done(made2)


## Mission men are never taken.
static func _mission_man_never(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	crowd.mission_holds.append(func(p: Person) -> bool: return p.soldier)
	_tick(crowd)
	t.check(crowd.guard_jobs.live(SHELTER).is_empty(), "every guard named by a director: no job, nobody taken")
	var any := false
	for p in crowd.soldiers:
		any = any or crowd.guard_jobs.on_job(p)
	t.check(not any, "and no guard holds a record")
	C._done(made)


## A household with a member a director holds, or one that answers a lure, is never escorted.
static func _mission_member_never(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	var held: Person = f.members[0]
	crowd.mission_holds.append(func(p: Person) -> bool: return p == held)
	_tick(crowd)
	t.check(crowd.guard_jobs.live(SHELTER).is_empty(), "a household with a mission-held member: no escort")
	C._done(made)


## The squad runs to the house, the members walk in REGROUP to the door and go in.
static func _walk_in(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	var job := _up(crowd, f)
	t.check(job != null, "(a job with a crew)")
	if job == null:
		C._done(made)
		return
	for p: Person in job.crew:
		t.check(p.mind == Person.Mind.POST and p.hurrying and p.post.is_equal_approx(p.town_post), "a crew man runs to the house, his post unchanged")
	t.check(f.members[0].mind == Person.Mind.REGROUP and f.members[0].anchor.is_equal_approx(f.home), "members wait until the squad is there")
	_arrive(job)
	_tick(crowd)
	var m: Person = f.members[0]
	t.check(m.mind == Person.Mind.REGROUP and m.has_goal() and not m.anchor.is_equal_approx(f.home), "the squad there: the members set out for the door in REGROUP")
	t.near(m.walk_speed, m._mind_speed(), 0.001, "at the REGROUP walking pace")
	_until_over(crowd, job, f.members, 90)
	var inside := 0
	for p: Person in f.members:
		if p.inside and p.mind == Person.Mind.SHELTER:
			inside += 1
	t.check(inside == f.members.size(), "every member ends inside the shelter (%d of %d)" % [inside, f.members.size()])
	t.check(crowd.guard_jobs.live(SHELTER).is_empty() and not crowd.shelter_escort.escorting(f.fam), "the job is over and the squad is released")
	for p: Person in job.crew:
		t.check(p.anchor.is_equal_approx(p.post), "a crew man is sent back to his post")
	C._done(made)


## A started job with its two men beside the first member.
static func _beside(crowd: Crowd, f: Dictionary) -> GuardJobs.Job:
	var job := _up(crowd, f)
	if job == null:
		return null
	var m: Person = f.members[0]
	job.crew[0].ground_pos = m.ground_pos + Vector2(1.5, 0.0)
	job.crew[1].ground_pos = m.ground_pos + Vector2(-8.0, 0.0)
	return job


## A near miss on a member with a squad man within 2.0: he stays REGROUP and no rng is drawn.
static func _steady(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	var job := _beside(crowd, f)
	t.check(job != null, "(a job with a crew)")
	if job == null:
		C._done(made)
		return
	var m: Person = f.members[0]
	var state := m.rng.state
	var cstate := crowd._rng.state
	m.panic(m.ground_pos + Vector2(3.0, 0.0), 1.0)
	t.check(m.mind == Person.Mind.REGROUP, "a near miss beside the squad: he stays in REGROUP")
	t.check(m.rng.state == state and crowd._rng.state == cstate, "and no rng was drawn")
	var far: Person = f.members[f.members.size() - 1]
	if f.members.size() > 1:
		far.ground_pos = m.ground_pos + Vector2(-15.0, 0.0)
		far.panic(far.ground_pos + Vector2(3.0, 0.0), 1.0, &"", true, false)
		t.check(far.mind == Person.Mind.PANIC, "a member with no squad man within 2.0 panics as ever")
	C._done(made)


## A direct hit scatters him all the same.
static func _direct_hit(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	var job := _beside(crowd, f)
	if job == null:
		t.check(false, "(a job with a crew)")
		C._done(made)
		return
	var m: Person = f.members[0]
	m.panic(m.ground_pos + Vector2(0.3, 0.0), 1.0, &"", true, false)
	t.check(m.mind == Person.Mind.PANIC, "inside the danger's radius he panics")
	C._done(made)


## Both squad men in the god's hand: the group is unsteadied.
static func _held_unsteadies(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	var job := _beside(crowd, f)
	if job == null:
		t.check(false, "(a job with a crew)")
		C._done(made)
		return
	job.crew[0].mind = Person.Mind.CONFUSED
	job.crew[1].mind = Person.Mind.CONFUSED
	var m: Person = f.members[0]
	m.panic(m.ground_pos + Vector2(3.0, 0.0), 1.0, &"", true, false)
	t.check(m.mind == Person.Mind.PANIC, "both squad men confused: the near miss panics him")
	C._done(made)


## The last squad man dies: every member still outside panics and the banner shows.
static func _scatter(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	var job := _up(crowd, f)
	if job == null:
		t.check(false, "(a job with a crew)")
		C._done(made)
		return
	var texts := _texts(crowd)
	for p in job.crew.duplicate():
		(made[3] as EnemyField).kill(p, &"mob")
	crowd.guard_jobs.prune()
	var all_panic := true
	for p: Person in f.members:
		all_panic = all_panic and p.mind == Person.Mind.PANIC
	t.check(all_panic, "every member outside panics")
	t.check(texts.has(ShelterEscort.BANNER), "the banner shows: " + str(texts))
	t.check(not crowd.shelter_escort.escorting(f.fam), "and the family is no longer escorted")
	for p: Person in f.members:
		t.check(p.badge_left <= 0.0 or p.badge_glyph != GuardJobs.GLYPH_SHIELD, "no shield badge is left on a scattered member")
	C._done(made)


## At the Evacuation the escort hands its people on at once: a member by the door goes in, the rest flee directly (no household
## wait away from home), the squad goes back to its posts, no badge is left.
static func _evacuation_ends(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	var job := _up(crowd, f)
	if job == null:
		t.check(false, "(a job with a crew)")
		C._done(made)
		return
	_arrive(job)
	_tick(crowd)
	_tick(crowd)
	var near: Person = f.members[0]
	near.ground_pos = job.data.door
	near._goal = Vector2.INF
	var crew: Array = job.crew.duplicate()
	_stage(crowd, AlarmManager.Stage.EVACUATION)
	crowd._evacuate()
	_tick(crowd)
	t.check(crowd.guard_jobs.live(SHELTER).is_empty() and not crowd.shelter_escort.escorting(f.fam), "the job is over")
	t.check(near.mind == Person.Mind.SHELTER, "the member at the door goes in")
	for p: Person in f.members:
		if p != near:
			t.check(p.mind == Person.Mind.FLEE, "every other member outside flees at once")
		t.check(p.badge_left <= 0.0 or p.badge_glyph != GuardJobs.GLYPH_SHIELD, "no badge is left on a member")
	for p: Person in crew:
		t.check(p.anchor.is_equal_approx(p.post) and not crowd.guard_jobs.on_job(p), "the squad goes back to post")
	C._done(made)


## The Citadel falls mid-walk: the board closes, the members are handed back to wait at home, the squad goes to its posts.
static func _citadel_falls(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	var job := _up(crowd, f)
	if job == null:
		t.check(false, "(a job with a crew)")
		C._done(made)
		return
	_arrive(job)
	_tick(crowd)
	_tick(crowd)
	var crew: Array = job.crew.duplicate()
	var m: Person = f.members[0]
	t.check(m.badge_left > 0.0 and not m.anchor.is_equal_approx(f.home), "(the members are on their way to the door)")
	crowd.guard_jobs.close()
	t.check(crowd.guard_jobs.live(SHELTER).is_empty() and not crowd.shelter_escort.escorting(f.fam), "no job is left")
	for p: Person in f.members:
		t.check(p.mind == Person.Mind.REGROUP and p.anchor.is_equal_approx(f.home), "a member is handed back to wait at home")
		t.check(p.badge_left <= 0.0 or p.badge_glyph != GuardJobs.GLYPH_SHIELD, "no badge is left on him")
	for p: Person in crew:
		t.check(p.anchor.is_equal_approx(p.post), "a squad man is back at his post")
	t.check(not crowd.shelter_escort.steadied(m, m.ground_pos + Vector2(3.0, 0.0), 1.0), "and nobody is steadied")
	C._done(made)


## A power's own touch is never steadied away: Divine Schism's (and the law mark's) fright lands on an escorted member.
static func _forced_lands(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	var job := _beside(crowd, f)
	if job == null:
		t.check(false, "(a job with a crew)")
		C._done(made)
		return
	var m: Person = f.members[0]
	t.check(crowd.shelter_escort.steadied(m, m.ground_pos + Vector2(3.0, 0.0), 0.5), "(a near miss would be steadied)")
	m.mind = Person.Mind.CALM
	m.panic(m.ground_pos + Vector2(3.0, 0.0), 0.5, &"schism", true, false, true)
	t.check(m.mind == Person.Mind.PANIC, "a forced fright on an escorted member lands")
	C._done(made)


## A family whose open job timed out is not posted again for 10 s.
static func _cooldown(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	crowd.shelter_escort.post_jobs()
	crowd.mission_holds.append(func(p: Person) -> bool: return p.soldier)
	C._run_for(crowd, 11.0, [], 0.1)
	t.check(crowd.guard_jobs.live(SHELTER).is_empty(), "(the open job timed out)")
	crowd.mission_holds.clear()
	for i in 4:
		C._run_for(crowd, 1.0, [], 0.1)
	t.check(crowd.guard_jobs.live(SHELTER).is_empty(), "the family is not posted again within 10 s")
	C._run_for(crowd, 8.0, [], 0.1)
	t.check(not crowd.guard_jobs.live(SHELTER).is_empty(), "and is posted again after it")
	C._done(made)


## End to end: the real stage change makes some of the town regroup; with those families home a started SHELTER job appears.
static func _end_to_end(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	crowd.alarms.stage = AlarmManager.Stage.CITY_EMERGENCY
	crowd._on_stage(AlarmManager.Stage.CITY_EMERGENCY, "test")
	var home: Array[Person] = []
	for p in crowd.citizens:
		if is_instance_valid(p) and p.mind == Person.Mind.REGROUP and p.profile != null:
			p.ground_pos = p.profile.home
			p._goal = Vector2.INF
			p._path = PackedVector2Array()
			p._target = p.ground_pos
			home.append(p)
	t.check(not home.is_empty(), "(the stage change sent some citizens home to regroup: %d)" % home.size())
	C._run_for(crowd, 3.0, home, 0.1)
	var started := 0
	for job in crowd.guard_jobs.live(SHELTER):
		if job.started:
			started += 1
	t.check(started >= 1, "a real regrouping household gets a started SHELTER job (%d)" % started)
	C._done(made)


## A household whose own house is the shelter: led in at once.
static func _own_home(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	var s: Structure = f.shelter
	var door: Vector2 = crowd.shelter_escort._door(s, s.center() + Vector2.DOWN * 5.0)
	for p: Person in f.members:
		p.profile.home = door
	f.home = door
	_wait(f)
	var job := _up(crowd, f)
	t.check(job != null, "(a job with a crew)")
	if job != null:
		_arrive(job)
		_tick(crowd)
		_until_over(crowd, job, f.members, 30)
		var inside := 0
		for p: Person in f.members:
			if p.inside and p.mind == Person.Mind.SHELTER:
				inside += 1
		t.check(inside == f.members.size(), "a household at its own shelter's door is led in (%d of %d)" % [inside, f.members.size()])
	C._done(made)


static func _capital() -> Array:
	City.use(&"capital")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = City.current().map()
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)
	crowd.spawn()
	return [crowd, env, world, field, grid, town]


static func _done_capital(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[2] as Node).free()
	(made[5] as Node).free()
	City.use(&"aldermere")


## The Capital: one household is led into a shelter.
static func _capital_escort(t) -> void:
	var made := _capital()
	var crowd: Crowd = made[0]
	var list := _families(crowd).filter(func(f: Dictionary) -> bool: return f.d <= 8.0)
	t.check(not list.is_empty(), "(a Capital household with a shelter within 8)")
	if list.is_empty():
		_done_capital(made)
		return
	var f: Dictionary = list[0]
	_stage(crowd, AlarmManager.Stage.CITY_EMERGENCY)
	_wait(f)
	var job := _up(crowd, f)
	t.check(job != null, "(a Capital job with a crew)")
	if job != null:
		_arrive(job)
		_tick(crowd)
		_until_over(crowd, job, f.members, 120)
		var inside := 0
		for p: Person in f.members:
			if p.inside and p.mind == Person.Mind.SHELTER:
				inside += 1
		t.check(inside == f.members.size(), "the Capital: the household is led inside (%d of %d)" % [inside, f.members.size()])
	_done_capital(made)


## An open job: ends after 10 s without a full crew, and while open it holds nobody from the normal flow.
static func _open_ends(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	crowd.shelter_escort.post_jobs()
	t.check(crowd.guard_jobs.live(SHELTER).size() == 1 and not crowd.shelter_escort.escorting(f.fam), "an open job does not hold the family")
	crowd.mission_holds.append(func(p: Person) -> bool: return p.soldier)
	crowd._households[f.fam] = crowd._clock - 100.0
	crowd._tend_households()
	var fled := true
	for p: Person in f.members:
		fled = fled and p.mind == Person.Mind.FLEE
	t.check(fled, "an unstarted job: _tend_households() sends the family on as ever")
	C._done(made)
	var made2 := _world()
	var crowd2: Crowd = made2[0]
	var g := _setup(made2)
	crowd2.shelter_escort.post_jobs()
	crowd2.mission_holds.append(func(p: Person) -> bool: return p.soldier)
	C._run_for(crowd2, 9.0, [], 0.1)
	t.check(crowd2.guard_jobs.live(SHELTER).size() == 1, "9 s without a crew: still open")
	C._run_for(crowd2, 2.0, [], 0.1)
	t.check(crowd2.guard_jobs.live(SHELTER).is_empty(), "10 s without a full crew: it ends (%d)" % crowd2.guard_jobs.live(SHELTER).size())
	C._done(made2)


## The shelter fills during the walk: another with room is picked, or the family is handed back.
static func _shelter_full_midwalk(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	var job := _up(crowd, f)
	if job == null:
		t.check(false, "(a job with a crew)")
		C._done(made)
		return
	_arrive(job)
	_tick(crowd)
	var s: Structure = job.data.shelter
	(crowd.shelters.shelters[s].coming as Array).resize(ShelterManager.CAPACITY.y)
	_tick(crowd)
	var other: Structure = crowd.shelters.nearest_with_room(f.home, ShelterEscort.SHELTER_REACH, f.members.size())
	if other != null:
		t.check(not job.ended and job.data.shelter == other, "the shelter filled: the escort picks another with room")
	else:
		t.check(job.ended and crowd.guard_jobs.live(SHELTER).is_empty(), "the shelter filled and no other has room: the job ends")
		for p: Person in f.members:
			t.check(p.mind == Person.Mind.REGROUP and p.anchor.is_equal_approx(f.home), "a member is handed back to wait at home")
	C._done(made)


## A shelter that is full before the squad is on: the open job ends at the next tick.
static func _shelter_full_open(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	crowd.shelter_escort.post_jobs()
	for s: Structure in crowd.shelters.shelters.keys():
		(crowd.shelters.shelters[s].coming as Array).resize(ShelterManager.CAPACITY.y)
	crowd.mission_holds.append(func(p: Person) -> bool: return p.soldier)
	_tick(crowd)
	t.check(crowd.guard_jobs.live(SHELTER).is_empty(), "every shelter full: the open job ends at once")
	C._done(made)


## Members wear the shield badge while escorted; guard_jobs.clear() takes everything off.
static func _badges_and_clear(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	var job := _up(crowd, f)
	if job == null:
		t.check(false, "(a job with a crew)")
		C._done(made)
		return
	_arrive(job)
	_tick(crowd)
	_tick(crowd)
	var m: Person = f.members[0]
	t.check(m.badge_left > 0.0 and m.badge_glyph == GuardJobs.GLYPH_SHIELD, "a member wears the shield badge")
	var tagged := false
	for tag in crowd.guard_jobs.tags():
		tagged = tagged or tag.label == ShelterEscort.TAG
	t.check(tagged, "and the squad's tag shows")
	crowd.guard_jobs.clear()
	t.check(m.badge_left <= 0.0 or m.badge_glyph != GuardJobs.GLYPH_SHIELD, "clear() takes the badge off")
	t.check(not crowd.shelter_escort.steadied(m, m.ground_pos + Vector2(3.0, 0.0), 1.0), "and nobody is steadied")
	C._done(made)


## A crew man freed under the job: the board goes on.
static func _freed_crew(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	var job := _up(crowd, f)
	if job == null:
		t.check(false, "(a job with a crew)")
		C._done(made)
		return
	var gone: Person = job.crew[0]
	crowd.soldiers.erase(gone)
	gone.free()
	_arrive(job)
	_tick(crowd)
	_run(crowd, 3.0, f.members)
	t.check(true, "a freed crew man: the board went on")
	var m: Person = f.members[0]
	t.check(crowd.shelter_escort.steadied(m, m.ground_pos + Vector2(3.0, 0.0), 1.0) in [true, false], "and steadied() survives him")
	C._done(made)


## A shelter man is never pulled by a higher job.
static func _never_pulled(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var f := _setup(made)
	if f.is_empty():
		t.check(false, "(a household)")
		C._done(made)
		return
	var job := _up(crowd, f)
	if job == null:
		t.check(false, "(a job with a crew)")
		C._done(made)
		return
	t.check(not crowd.guard_jobs.pullable(job.crew[0]) and not crowd.guard_jobs.pullable(job.crew[1]), "a shelter man is never pullable")
	C._done(made)


## With no escort live a panic reads nothing of the escort.
static func _no_rng_without_escort(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var m: Person = crowd.citizens[0]
	t.check(not crowd.shelter_escort.steadied(m, m.ground_pos + Vector2(3.0, 0.0), 1.0), "no escort live: nobody is steadied")
	C._done(made)
