extends RefCounted
## Dragonfire ground fire, Task 2 (the beaters): calm citizens gather round a burning patch's edge, wait a step back while it
## is at full strength, then beat it out (no water): three take it from 0.9 in 5 s, two in 7.5 s, one in 15 s. A house comes
## first; the evacuation, a fright or the patch going out ends the work; no goal is ever inside a patch.

const G := Vector2(2.75, 11.25)  # the Main Gate's plaza: open ground, no building within a few units
const FAR := Vector2(-60.0, -60.0)


static func _make(seed_value := 5) -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, seed_value)
	crowd.spawn()
	# The brigade turns out from the profile's stage.
	crowd.alarms.stage = crowd.profile.fire_from
	return [crowd, env, field, world]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[3] as Node).free()


static func _arrive(p: Person) -> void:
	p.ground_pos = p.goal()
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


## Everyone calm and well away from the stage (20 off), so only the people a test places are near.
static func _clear_away(crowd: Crowd) -> void:
	for p in crowd.citizens:
		p.mind = Person.Mind.CALM
		p._goal = Vector2.INF
		p.ground_pos = FAR + Vector2(20.0, 20.0)


## `n` calm citizens at the given distances east of `at`.
static func _place(crowd: Crowd, at: Vector2, dists: Array) -> Array[Person]:
	var out: Array[Person] = []
	for i in dists.size():
		var c: Person = crowd.citizens[i]
		c.ground_pos = at + Vector2(float(dists[i]), 0.0)
		out.append(c)
	return out


static func run(t) -> void:
	_turn_out(t)
	_wait_then_beat(t)
	_rates(t)
	_stand_down(t)
	_house_first(t)
	_real_walk(t)


static func _count_assist(crowd: Crowd, p: GroundFire) -> int:
	var n := 0
	for c in crowd.citizens:
		if c.mind == Person.Mind.ASSIST and c.assist_patch == p:
			n += 1
	return n


static func _turn_out(t) -> void:
	var made := _make()
	var crowd: Crowd = made[0]
	var fm := crowd.fires
	_clear_away(crowd)
	var five := _place(crowd, G, [3.0, 4.0, 5.0, 6.0, 12.0])
	var soldier: Person = crowd.soldiers[0]
	soldier.ground_pos = G + Vector2(0.0, 2.0)
	var p := fm.lay(G)
	crowd.alarms.stage = crowd.profile.fire_from - 1 as AlarmManager.Stage
	fm._recruit()
	t.check(_count_assist(crowd, p) == 0 and p.crew.is_empty(), "beaters: below the profile's stage nobody turns out")
	crowd.alarms.stage = crowd.profile.fire_from
	fm._recruit()
	var ok := true
	for i in 3:
		ok = ok and five[i].mind == Person.Mind.ASSIST and five[i].assist_patch == p and five[i].assist_fire == null \
			and five[i].intent() == Person.Intent.ASSIST
	t.check(ok and p.crew.size() == 3, "beaters: the three nearest calm citizens turn out (%d)" % p.crew.size())
	t.check(five[3].mind == Person.Mind.CALM and five[4].mind == Person.Mind.CALM, "beaters: the others stay calm")
	t.check(soldier.mind != Person.Mind.ASSIST and not soldier in p.crew, "beaters: a soldier 2 away is never taken")
	soldier.beat(p)
	t.check(soldier.mind != Person.Mind.ASSIST and soldier.assist_patch == null, "beaters: a soldier refuses beat()")
	var slots := {}
	for b in p.crew:
		slots[b.assist_slot] = true
	t.check(slots.size() == 3, "beaters: each takes a ring slot of its own")
	fm._recruit()
	t.check(p.crew.size() == 3 and _count_assist(crowd, p) == 3, "beaters: a full crew takes no more")
	_done(made)

	# A profile of fire_crew 2: two.
	made = _make()
	crowd = made[0]
	fm = crowd.fires
	_clear_away(crowd)
	crowd.profile.fire_crew = 2
	var four := _place(crowd, G, [3.0, 4.0, 5.0, 6.0])
	p = fm.lay(G)
	fm._recruit()
	t.check(p.crew.size() == 2 and _count_assist(crowd, p) == 2 and four[2].mind == Person.Mind.CALM,
		"beaters: a profile fire_crew of 2 gives two (%d)" % p.crew.size())
	_done(made)

	# A citizen standing in the fire is not taken; nor one inside a building.
	made = _make()
	crowd = made[0]
	fm = crowd.fires
	_clear_away(crowd)
	var two := _place(crowd, G, [0.2, 3.0])
	p = fm.lay(G)
	fm._recruit()
	t.check(two[0].mind == Person.Mind.CALM and two[1].mind == Person.Mind.ASSIST,
		"beaters: a citizen standing in the patch is not taken")
	_done(made)


static func _wait_then_beat(t) -> void:
	var made := _make()
	var crowd: Crowd = made[0]
	var fm := crowd.fires
	_clear_away(crowd)
	var three := _place(crowd, G, [3.0, 4.0, 5.0])
	var p := fm.lay(G)
	fm._recruit()
	var waits_ok := true
	var never_inside := true
	for b in three:
		var d := b.goal().distance_to(G)
		waits_ok = waits_ok and b.has_goal() and absf(d - (p.radius + GroundFire.WAIT_GAP)) <= 0.15
		never_inside = never_inside and d > p.radius
	t.check(waits_ok, "beaters: at full strength each goal is on the wait ring")
	for b in three:
		_arrive(b)
	for i in 4:
		fm._tend_beaters(0.25)
		fm._burn_patches(0.25)
		for b in three:
			never_inside = never_inside and (not b.has_goal() or b.goal().distance_to(G) > p.radius)
	t.check(fm._beaters(p) == 0 and not three[0].assist_beating and not three[0].has_goal(),
		"beaters: they wait a step back and do not beat at full strength")
	t.check(is_equal_approx(p.strength, 1.0 - 4.0 * 0.25 * GroundFire.BURN_DOWN),
		"beaters: waiting, the patch burns down at BURN_DOWN (%.4f)" % p.strength)
	p.strength = GroundFire.BEAT_FROM
	fm._tend_beaters(0.1)
	var beats_ok := true
	for b in three:
		var d := b.goal().distance_to(G)
		beats_ok = beats_ok and b.has_goal() and absf(d - (p.radius + GroundFire.BEAT_GAP)) <= 0.15
		never_inside = never_inside and d > p.radius
	t.check(beats_ok, "beaters: at 0.9 the next goal is the beat ring")
	for b in three:
		_arrive(b)
	var swung := false
	for i in 8:
		fm._tend_beaters(0.1)
		for b in three:
			swung = swung or b._swing_left > 0.0
			never_inside = never_inside and (not b.has_goal() or b.goal().distance_to(G) > p.radius)
	t.check(fm._beaters(p) == 3 and three[0].assist_beating, "beaters: at the beat ring all three beat")
	t.check(swung, "beaters: a beater shows a swing")
	t.check(never_inside, "beaters: no goal in the run was ever inside the patch")
	_done(made)


## A fresh town with `n` beaters at the ring of a patch of strength 0.9; the seconds until it is out, stepped by 0.25.
static func _beat_time(n: int) -> Array:
	var made := _make()
	var crowd: Crowd = made[0]
	var fm := crowd.fires
	_clear_away(crowd)
	var dists: Array = []
	for i in n:
		dists.append(3.0 + float(i))
	var crew := _place(crowd, G, dists)
	var p := fm.lay(G)
	p.strength = GroundFire.BEAT_FROM
	fm._recruit()
	for b in crew:
		_arrive(b)
	fm._tend_beaters(0.0)  # at the beat ring: beating
	var seconds := 0.0
	while not p.out and seconds < 40.0:
		fm._burn_patches(0.25)
		fm._tend_beaters(0.25)
		seconds += 0.25
	var all_recover := true
	for b in crew:
		all_recover = all_recover and b.mind == Person.Mind.RECOVER and b.assist_patch == null and not b.assist_beating
	var res := [seconds, p.out and p.beaten and fm.patches_beaten == 1 and fm.patches_burned_out == 0 and fm.patches.is_empty(),
		all_recover, not crowd.threats.is_active(p.threat_id) and not crowd.threats.is_active(p.prev_threat_id)]
	_done(made)
	return res


static func _rates(t) -> void:
	var want := {3: 5.0, 2: 7.5, 1: 15.0}
	for n in [3, 2, 1]:
		var r := _beat_time(n)
		t.check(absf(float(r[0]) - float(want[n])) <= 0.25,
			"beaters: %d beating put it out from 0.9 in %.2f s (want %.1f)" % [n, float(r[0]), float(want[n])])
		if n == 3:
			t.check(r[1], "beaters: beaten, counted, and gone from the list")
			t.check(r[2], "beaters: put out, each beater stands down to RECOVER")
			t.check(r[3], "beaters: the patch's danger ended with it")


static func _stand_down(t) -> void:
	# The evacuation: the crew stands down.
	var made := _make()
	var crowd: Crowd = made[0]
	var fm := crowd.fires
	_clear_away(crowd)
	var crew := _place(crowd, G, [3.0, 4.0, 5.0])
	var p := fm.lay(G)
	fm._recruit()
	crowd.alarms.stage = AlarmManager.Stage.EVACUATION
	fm._tend_beaters(0.1)
	var gone := true
	for b in crew:
		gone = gone and b.mind != Person.Mind.ASSIST and b.assist_patch == null
	t.check(gone and p.crew.is_empty(), "beaters: at the evacuation the crew stands down")
	_done(made)

	# A beater frightened off leaves, and the next recruitment takes a new one.
	made = _make()
	crowd = made[0]
	fm = crowd.fires
	_clear_away(crowd)
	var four := _place(crowd, G, [3.0, 4.0, 5.0, 6.0])
	p = fm.lay(G)
	fm._recruit()
	t.check(four[3].mind == Person.Mind.CALM and p.crew.size() == 3, "beaters: three turned out of four")
	four[0].panic(G, 1.0, &"fire")
	t.check(four[0].mind != Person.Mind.ASSIST, "beaters: a fright takes a beater off the work")
	fm._tend_beaters(0.1)
	t.check(p.crew.size() == 2 and not four[0] in p.crew, "beaters: the frightened one leaves the crew")
	fm._recruit()
	t.check(p.crew.size() == 3 and four[3] in p.crew and four[3].mind == Person.Mind.ASSIST
		and four[3].assist_patch == p, "beaters: the next recruitment takes a new one")
	var slots := {}
	for b in p.crew:
		slots[b.assist_slot] = true
	t.check(slots.size() == 3, "beaters: the newcomer takes the free slot")
	# A patch out stands the crew down at once.
	for b in p.crew:
		_arrive(b)
	p.strength = 0.0001
	fm._tend_beaters(0.1)
	fm._burn_patches(0.25)
	var down := true
	for b in four:
		down = down and b.assist_patch == null
	t.check(p.out and down and p.crew.is_empty(), "beaters: a patch out stands its crew down")
	_done(made)


static func _house_first(t) -> void:
	var made := _make()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var fm := crowd.fires
	var house: Structure = null
	for s in env.structures():
		if house == null and s.kind == Structure.Kind.HOUSE and s.role == &"house" and s.center().distance_to(Vector2(-8, 2)) < 4.0:
			house = s
	_clear_away(crowd)
	crowd.profile.fire_crew = 4
	fm.ignite(house, 0.5)
	var patch := fm.lay(house.center() + Vector2(3.0, 3.0))
	var four := _place(crowd, house.center() + Vector2(0.0, 2.5), [0.0, 0.5, 1.0, 1.5])
	fm._recruit()
	var all_house := true
	for b in four:
		all_house = all_house and b.mind == Person.Mind.ASSIST and b.assist_fire == house and b.assist_patch == null
	t.check(all_house and patch.crew.is_empty(), "beaters: a burning house and a patch, all four go to the house")
	_done(made)


## Real walking: three citizens a few units off walk to the wait ring, stand while the patch is full, then walk in and beat.
static func _real_walk(t) -> void:
	var made := _make()
	var crowd: Crowd = made[0]
	var fm := crowd.fires
	_clear_away(crowd)
	var crew := _place(crowd, G, [3.0, 4.0, 5.0])
	var p := fm.lay(G)
	var dt := 1.0 / 60.0
	var beat_seen := false
	var inside := false
	var waited := false
	var elapsed := 0.0
	while elapsed < 60.0 and not p.out:
		crowd.alarms.stage = crowd.profile.fire_from  # (the test holds the stage; the alarm is not under test)
		crowd.advance(dt)
		for b in crew:
			b.tick(dt)
		elapsed += dt
		beat_seen = beat_seen or fm._beaters(p) > 0
		if p.full() and p.crew.size() == 3 and not crew[0].has_goal():
			waited = true
		for b in crew:
			if b.is_alive() and b.mind == Person.Mind.ASSIST and G.distance_to(b.ground_pos) < p.radius:
				inside = true
	t.check(waited and beat_seen, "beaters: walking for real, they wait at full strength then beat (%.1f s)" % elapsed)
	t.check(p.out and p.beaten and not inside, "beaters: walking for real, the patch is beaten out and nobody stood in it")
	_done(made)
