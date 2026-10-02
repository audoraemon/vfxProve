extends RefCounted
## v0.05 quiet powers. Silent Doom takes everyone within reach of the aim (v0.07.1); unseen, the town never knows (no
## danger, no alarm), but a witness panics and the death raises the alarm. Blight ruins what a structure is for --
## a well's water, a gate (jammed for a while), the bell, the dock, the rite -- and adds a single alarm.


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


## Everyone far off in a corner, out of sight of `at`.
static func _clear_round(crowd: Crowd) -> void:
	var i := 0
	for p in crowd.citizens + crowd.soldiers:
		p.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1


static func run(t) -> void:
	# The power book: icons and preview clips for both.
	for key in ["doom", "blight"]:
		var p := PowerBook.get_power(key)
		t.check(PowerBook.is_quiet(key) and PowerBook.icon(key) != null and PowerBook.hud_icon(key) != null
			and PowerBook.clip(key) != null and ResourceLoader.exists(String(p.path)),
			"%s is a quiet power with its icons, clip and effect" % p.name)

	var made := _crowd()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var field: EnemyField = made[3]
	var town: Town = made[5]
	_clear_round(crowd)

	# Who Silent Doom takes: everyone within reach, soldiers too (v0.07.1), and nobody beyond.
	var at := Vector2(-4.0, 10.0)
	var four: Array[Person] = []
	for k in 4:
		var p: Person = crowd.citizens[k]
		p.ground_pos = at + Vector2(0.15 * k, 0.0)
		four.append(p)
	var far: Person = crowd.citizens[4]
	far.ground_pos = at + Vector2(1.5, 0.0)
	var soldier: Person = crowd.soldiers[0]
	soldier.ground_pos = at + Vector2(0.0, 0.6)
	var taken := SilentDoom.victims_at(field, at)
	t.check(taken.size() == 5 and four.all(func(p: Person) -> bool: return p in taken) and soldier in taken
		and far not in taken, "Silent Doom takes everyone within reach, soldiers too, and nobody beyond")
	t.check(taken[0] == four[0], "and the nearest comes first")
	t.check(is_equal_approx(float(PowerBook.get_power("doom").cooldown), 2.5), "Silent Doom's cooldown is 2.5 s")
	taken.erase(soldier)
	soldier.ground_pos = Vector2(-27.0, 22.0)

	# A quiet cast registers no danger.
	crowd.on_cast(at, Vector2.ZERO, 0.0, "doom")
	crowd.on_cast(at, Vector2.ZERO, 0.0, "blight")
	t.check(crowd.threats.active_count() == 0, "a quiet cast is no danger the town can see")

	# Unseen: four fall together (none witnesses another) and the town never knows.
	far.ground_pos = Vector2(-27.0, 21.0)
	var alarm := crowd.alarm
	var killed := crowd.killed_citizens
	for p in taken:
		field.kill(p, &"doom", at)
	crowd.advance(0.1)
	t.check(crowd.killed_citizens == killed + taken.size() and crowd.alarm == alarm and crowd.threats.active_count() == 0
		and crowd.alarms.stage == AlarmManager.Stage.NORMAL, "unseen, all four die and the town never knows")

	# Seen: a witness close by panics, and the death raises the alarm.
	var victim: Person = crowd.citizens[10]
	var witness: Person = crowd.citizens[11]
	victim.ground_pos = at
	witness.ground_pos = at + Vector2(1.2, 0.0)
	witness.shelters = null
	witness.mind = Person.Mind.CALM
	field.kill(victim, &"doom", at)
	crowd.advance(0.1)
	t.check(crowd.alarm > alarm and witness.mind == Person.Mind.PANIC and crowd.threats.active_count() == 1,
		"seen, the witness panics and the alarm rises (%.1f)" % crowd.alarm)

	# Seen, several at once (v0.07.1): the victims are reacted to together, but each death still raises the alarm as if
	# it fell alone, a witness among them flees from the nearest, and a soldier taken is counted as a soldier killed.
	var site := Vector2(6.0, 10.0)
	var fallen: Array[Person] = []
	for k in 4:
		var p: Person = crowd.citizens[20 + k]
		p.ground_pos = site + Vector2(0.5 * float(k), 0.0)
		fallen.append(p)
	var guard: Person = crowd.soldiers[2]
	guard.ground_pos = site + Vector2(0.75, -0.5)
	fallen.append(guard)
	var between: Person = crowd.citizens[30]
	between.ground_pos = site + Vector2(0.7, 0.3)
	between.shelters = null
	between.mind = Person.Mind.CALM
	alarm = crowd.alarm
	killed = crowd.killed_citizens
	var killed_soldiers := crowd.killed_soldiers
	for p in fallen:
		field.kill(p, &"doom", site)
	crowd.advance(0.1)
	var per_death := Crowd.ALARM_KILL * (1.0 if crowd.alarms.bell_rung else Crowd.UNWARNED_ALARM)
	t.near(crowd.alarm - alarm, per_death * float(fallen.size()), 0.001,
		"each of the %d seen deaths raises the alarm by %.3f (+%.3f)" % [fallen.size(), per_death, crowd.alarm - alarm])
	t.check(between.mind == Person.Mind.PANIC, "a witness between the victims flees")
	t.check(between._threat.is_equal_approx(fallen[1].ground_pos),
		"from the nearest of them (%s)" % [between._threat])
	t.check(crowd.killed_soldiers == killed_soldiers + 1 and crowd.killed_citizens == killed + 4,
		"a soldier taken counts as a soldier killed (%d), the rest as citizens (%d)" % [crowd.killed_soldiers - killed_soldiers,
		crowd.killed_citizens - killed])

	# A boarding in the T_STRIKE between the cast and the fall is out of reach (v0.07.1): only the one in the open dies.
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.rng = RandomNumberGenerator.new()
	ctx.overhead = Node2D.new()
	var spot := Vector2(-4.0, 20.0)
	var open_air: Person = crowd.citizens[40]
	var boarding: Person = crowd.citizens[41]
	open_air.ground_pos = spot
	boarding.ground_pos = spot + Vector2(0.2, 0.0)
	var doom := FxTimeline.cast(load("res://src/fx/quiet/silent_doom.gd"), ctx, spot, {}) as SilentDoom
	boarding.inside = true
	doom._process(SilentDoom.T_STRIKE + 0.01)
	t.check(not open_air.is_alive() and boarding.is_alive(), "someone who boards a boat before the strike is not taken")
	boarding.inside = false
	ctx.overhead.free()
	_done(made)

	# Blight: its target, its alarm, and what each loses.
	made = _crowd(ResponseProfile.Tier.PREPARED)
	crowd = made[0]
	env = made[1]
	town = made[5]
	var well_rect: Rect2 = TownLayout.WELLS[0]
	var well := BlightFx.target(env, well_rect.get_center() + Vector2(0.4, 0.4))
	t.check(well != null and well.art_tag == &"well", "Blight finds the well beside the aim")
	t.check(BlightFx.target(env, Vector2(-10.0, 4.0)) == null or BlightFx.blightable(BlightFx.target(env, Vector2(-10.0, 4.0))),
		"and only ever a structure it can ruin")
	var before := crowd.alarm
	var waters := crowd.fires.water_points().size()
	env.blight(well)
	t.check(well.blighted and crowd.fires.water_points().size() == waters - 1
		and is_equal_approx(crowd.alarm - before, Crowd.BLIGHT_ALARM), "a blighted well gives no water, and adds one alarm")
	t.check(Mission.blight_banner(well) == "BLIGHT - THE WELL IS POISONED", "and the player is told")

	# A blighted gate jams: its crowd waits, nobody passes, until it frees itself.
	var gate: Structure = town.gates[0]
	env.blight(gate)
	crowd.alarms.stage = AlarmManager.Stage.CITY_EMERGENCY
	crowd._on_stage(AlarmManager.Stage.EVACUATION, "test")
	var spots := crowd.queue_spots(gate)
	for k in 6:
		var p: Person = crowd.citizens[40 + k]
		p.mind = Person.Mind.FLEE
		p.ground_pos = spots[k]
	crowd._gate_next.erase(gate)
	crowd.advance(0.1)
	var passing := 0
	for p in crowd.citizens:
		if is_instance_valid(p) and p.passing_gate == gate:
			passing += 1
	t.check(passing == 0 and crowd.waiting_at(gate) >= 6, "a blighted gate is jammed: they wait (%d)" % crowd.waiting_at(gate))
	crowd._clock += Crowd.GATE_JAM
	crowd.advance(0.1)
	crowd.advance(0.1)
	passing = 0
	for p in crowd.citizens:
		if is_instance_valid(p) and p.passing_gate == gate:
			passing += 1
	t.check(not gate.blighted and passing >= 1, "after %d s it frees itself" % roundi(Crowd.GATE_JAM))
	_done(made)

	# The bell cannot ring, the cathedral holds no rite.
	made = _crowd(ResponseProfile.Tier.PREPARED)
	crowd = made[0]
	env = made[1]
	var silenced := []
	crowd.bell.silenced.connect(func(why: String) -> void: silenced.append(why))
	env.blight(crowd.bell.tower)
	crowd.bell.call_keeper()
	crowd.bell.step(0.1)
	t.check(crowd.bell.state == BellNetwork.State.SILENCED and silenced == ["the bell is cracked"], "a blighted bell is silenced")
	var ended := []
	crowd.rite.ended.connect(func(why: String) -> void: ended.append(why))
	env.blight(crowd.rite.cathedral)
	crowd.rite.begin()
	t.check(crowd.rite.state == BanishingRite.State.ENDED and ended == ["the cathedral is defiled"],
		"a blighted cathedral holds no rite")
	_done(made)
