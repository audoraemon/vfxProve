extends RefCounted
## The shared hooks the Veil powers stand on (Veil authority powers, Task 2): a deep sleep, the watch's one question (guise or cloak),
## the shadow and the dreaded (who see, shout, ring, fight and seize nothing), the sick sent home and the quarry made ill, the dread on
## dark ground, the town-wide veil, the silent takes, the spared, the Veil's cooldown haste, the muted lamps, Blight's lost alarm, the two
## refusal stubs, the footholds, Remembrance's ledger and the aim ring that redraws when the dusk under it changes.


## A director whose quarry and keeps_alive are one named person each.
class HookDirector extends MissionDirector:
	var mine: Person
	var keep: Person

	func quarry(p: Person) -> bool:
		return p != null and p == mine

	func keeps_alive(p: Person) -> bool:
		return p != null and p == keep


static func _setup() -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)
	crowd.spawn()
	return [crowd, env, grid, field, world, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[4] as Node).free()


## Everyone far off in a corner, out of sight and earshot of the market.
static func _clear_round(crowd: Crowd) -> void:
	var i := 0
	for p in crowd.citizens + crowd.soldiers:
		p.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1


static func run(t) -> void:
	var made := _setup()
	_sleep(t, made)
	_watch(t, made)
	_shadow_and_dread_people(t, made)
	_sick(t, made)
	_quarry(t, made)
	_dread(t, made)
	_veil_all(t, made)
	_take(t, made)
	_spared(t, made)
	_haste(t, made)
	_blight_alarm(t, made)
	_refusals(t, made)
	_remembrance(t, made)
	_ring(t, made)
	_directors(t, made)
	var crowd: Crowd = made[0]
	crowd.footholds.append(made[5].gates[0])
	t.check(crowd.footholds.size() == 1, "Crowd.footholds holds the blighted buildings")
	_done(made)
	t.check(crowd.footholds.is_empty(), "and is emptied with the crowd")
	_mute(t)


static func _sleep(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	_clear_round(crowd)
	var p: Person = crowd.citizens[10]
	var q: Person = crowd.citizens[11]
	p.ground_pos = grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	q.ground_pos = grid.nearest_walkable(p.ground_pos + Vector2(20.0, 0.0))
	t.check(p.sleep(20.0, true) and p.is_deep_asleep(), "a deep sleep")
	crowd._react([p.ground_pos], 3.0, 5.0, p.ground_pos, &"lightning", true, false)
	t.check(p.is_asleep() and p.mind == Person.Mind.ASLEEP, "noise does not wake a deep sleeper")
	t.check(q.sleep(20.0) and not q.is_deep_asleep(), "a light sleep (the default: Curfew's)")
	crowd._react([q.ground_pos], 3.0, 5.0, q.ground_pos, &"lightning", true, false)
	t.check(not q.is_asleep(), "noise wakes a light sleeper (control)")
	# A soldier in a deep sleep sleeps through the blow too; a light one wakes.
	var s: Person = crowd.soldiers[3]
	var s2: Person = crowd.soldiers[4]
	s.ground_pos = p.ground_pos + Vector2(1.0, 0.0)
	s2.ground_pos = q.ground_pos + Vector2(1.0, 0.0)
	s.sleep(20.0, true)
	s2.sleep(20.0)
	crowd._react([p.ground_pos, q.ground_pos], 0.5, 5.0, p.ground_pos, &"lightning")
	t.check(s.is_asleep() and not s2.is_asleep(), "a deep-sleeping soldier is not woken by noise; a light one is")
	p.hurt(0.1, null)
	t.check(not p.is_asleep() and not p.is_deep_asleep(), "a hurt still wakes a deep sleeper")
	s.hurt_from(0.1, s.ground_pos + Vector2(0.5, 0.0))
	t.check(not s.is_asleep(), "a bite too")
	# A light sleep laid on a deep one keeps it deep.
	p.sleep(20.0, true)
	p.sleep(5.0)
	t.check(p.is_deep_asleep(), "a light sleep on a deep sleeper keeps it deep")
	p.wake()
	t.check(not p.is_deep_asleep() and not p.is_asleep(), "awake, no deep sleep is left")


static func _watch(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	_clear_round(crowd)
	var death := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var grown: Array[Person] = []
	for q in crowd.citizens:
		if not q.is_child():
			grown.append(q)
	var p: Person = grown[20]  # grown-ups: a relay's witness is never a child (TempleReport._witness())
	var c: Person = grown[21]
	p.ground_pos = death + Vector2(1.0, 0.0)
	c.ground_pos = death + Vector2(-1.0, 0.0)
	p.statuses[&"cloak"] = 25.0
	t.check(p.hidden_from_watch() and not p.guised(), "cloak hides, is not a guise")
	t.check(crowd.nearest_witness(death) == c, "a cloaked person is never the witness; the uncloaked control at the same distance is (C5)")
	c.ground_pos = death + Vector2(20.0, 0.0)
	t.check(crowd.nearest_witness(death) == null, "and alone he is no witness at all")
	p.statuses.erase(&"cloak")
	t.check(crowd.nearest_witness(death) == p and not p.hidden_from_watch(), "uncloaked he is the witness again (positive control)")
	p.statuses[&"guise"] = 10.0
	t.check(p.hidden_from_watch() and crowd.nearest_witness(death) == null, "the guise answers the same question")
	p.statuses.erase(&"guise")
	for key: StringName in [&"shadow", &"dread"]:
		c.ground_pos = death + Vector2(-1.0, 0.0)
		p.statuses[key] = 10.0
		t.check(crowd.nearest_witness(death) == c, "one under %s is never the nearest witness; a control at the same distance is" % key)
		p.statuses.erase(key)
	t.check(crowd.nearest_witness(death) == c or crowd.nearest_witness(death) == p, "(both seen again)")
	# A soldier on the watch looks past the cloaked when he picks whom to fight.
	var s: Person = crowd.soldiers[5]
	s.ground_pos = death
	s._fight_rule = Person.FightRule.HOSTILES
	p.mind = Person.Mind.FIGHT
	t.check(s._fightable(p), "a fighting citizen is the watch's to fight (control)")
	p.statuses[&"cloak"] = 25.0
	t.check(not s._fightable(p), "the cloaked is not")
	p.statuses.erase(&"cloak")
	p.mind = Person.Mind.CALM
	s.ground_pos = death + Vector2(25.0, 0.0)
	# The Faithful's sight and the escort's watch read the same question.
	var d := MissionDirector.new()
	p.statuses[&"cloak"] = 25.0
	t.check(MissionDirector._unseen(p), "a Faithful does not see the cloaked (MissionDirector._unseen)")
	p.statuses.erase(&"cloak")
	t.check(not MissionDirector._unseen(p) and d.quarry(p) == false and d.keeps_alive(p) == false,
		"the uncloaked is seen; the base director has no quarry and keeps no one")
	# TempleReport's copy of the witness search follows.
	var rep := TempleReport.new(c, death)
	rep.skip = func(_q: Person) -> bool: return false
	p.ground_pos = death + Vector2(0.5, 0.0)
	c.ground_pos = death + Vector2(20.0, 0.0)
	t.check(rep._witness(crowd, death) == p, "a relay's witness (control)")
	for key: StringName in [&"cloak", &"shadow", &"dread"]:
		p.statuses[key] = 10.0
		t.check(rep._witness(crowd, death) != p, "a relay's witness is never one under %s" % key)
		p.statuses.erase(key)


static func _shadow_and_dread_people(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	_clear_round(crowd)
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var s: Person = crowd.soldiers[6]
	var foe: Person = crowd.citizens[30]
	s.ground_pos = at
	foe.ground_pos = at + Vector2(1.0, 0.0)
	# A shadow soldier fights nobody; a dreaded one neither.
	for key: StringName in [&"shadow", &"dread"]:
		s.send_to_post(at)
		s.statuses[key] = 10.0
		s.fight(foe, 10.0, 0.5)
		t.check(s.mind != Person.Mind.FIGHT, "a soldier under %s takes no fight" % key)
		s.statuses.erase(key)
		s.fight(foe, 10.0, 0.5)
		t.check(s.mind == Person.Mind.FIGHT, "without it he does (control, %s)" % key)
		s.statuses[key] = 10.0
		s._fight_step(0.1)
		t.check(s.mind != Person.Mind.FIGHT, "and one already fighting stops when %s lands" % key)
		s.statuses.erase(key)
	# Neither frightens, flees nor looks.
	var p: Person = crowd.citizens[31]
	p.ground_pos = at + Vector2(0.0, 2.0)
	for key: StringName in [&"shadow", &"dread"]:
		p.mind = Person.Mind.CALM
		p.statuses[key] = 10.0
		p.panic(at, 1.0, &"lightning")
		p.observe(at)
		p.flee()
		t.check(p.mind == Person.Mind.CALM, "one under %s does not panic, look or flee" % key)
		p.statuses.erase(key)
	p.panic(at, 1.0, &"lightning")
	t.check(p.mind == Person.Mind.PANIC, "without, he panics (control)")
	p.mind = Person.Mind.CALM
	p._panic_left = 0.0
	p._startle_left = 0.0
	# Neither shouts.
	crowd._voice_tokens = Crowd.VOICE_BUDGET
	var voiced := crowd.voices_played
	for key: StringName in [&"shadow", &"dread"]:
		p.statuses[key] = 10.0
		crowd._voice(p, &"cit_yelp")
		p.statuses.erase(key)
	t.check(crowd.voices_played == voiced, "the shadow and the dreaded do not cry out")
	crowd._voice(p, &"cit_yelp")
	t.check(crowd.voices_played == voiced + 1, "one free does (control)")
	# The dreaded do not walk; a shadow does, and so does the free control.
	var far := grid.nearest_walkable(at + Vector2(6.0, 0.0))
	var walked := {}
	for key: StringName in [&"dread", &"shadow", &""]:
		p.ground_pos = at + Vector2(0.0, 2.0)
		p.mind = Person.Mind.CALM
		p.walk_speed = 1.0
		if key != &"":
			p.statuses[key] = 10.0
		p.set_goal(far)
		var from := p.ground_pos
		for i in 30:
			p.tick(0.05)
		walked[key] = p.ground_pos.distance_to(from)
		p.statuses.erase(key)
	t.check(float(walked[&"dread"]) < 0.001 and float(walked[&"shadow"]) > 0.2 and float(walked[&""]) > 0.2,
		"the dreaded stand frozen; a shadow and a free man walk (%s)" % [walked])
	# The dreaded keeper does not climb on: the bell's climb holds while the dread is on him.
	t.check(crowd.bell != null and is_instance_valid(crowd.bell.keeper), "(the town has a bell and its keeper)")
	if crowd.bell != null and is_instance_valid(crowd.bell.keeper):
		var bell := crowd.bell
		var k := bell.keeper
		bell.state = BellNetwork.State.CLIMBING
		bell.progress = 0.0
		k.mind = Person.Mind.DUTY
		k.statuses[&"dread"] = 10.0
		bell.step(1.0)
		var held := bell.progress
		k.statuses.erase(&"dread")
		k.statuses[&"shadow"] = 10.0
		bell.step(1.0)
		var shadowed := bell.progress
		k.statuses.erase(&"shadow")
		bell.step(0.01)
		t.check(held == 0.0 and shadowed == 0.0 and bell.progress > 0.0, "a dreaded or shadow keeper does not ring; a free one climbs on")
		bell.state = BellNetwork.State.IDLE
		bell.progress = 0.0
		k.mind = Person.Mind.CALM


static func _sick(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	_clear_round(crowd)
	var p: Person = null
	for c in crowd.citizens:
		if c.profile != null and c.profile.home != Vector2.INF and grid.nearest_walkable(c.profile.home) != Vector2.INF:
			p = c
			break
	t.check(p != null, "a citizen with a home")
	if p == null:
		return
	var alive := crowd.alive_citizens()
	var home := grid.nearest_walkable(p.profile.home)
	p.ground_pos = grid.nearest_walkable(home + Vector2(2.5, 0.0))
	p.mind = Person.Mind.CALM
	p.go_duty(home + Vector2(4.0, 0.0))
	t.check(p.mind == Person.Mind.DUTY, "(on a duty)")
	p.send_home_sick()
	t.check(p.home_sick and p.mind != Person.Mind.DUTY and not p.can_take_duty() and not p.inside, "sick: off his duty, takes none, walks")
	p.go_duty(home + Vector2(4.0, 0.0))
	t.check(p.mind != Person.Mind.DUTY, "a duty does not take the sick")
	p.panic(home, 1.0, &"lightning")
	t.check(p.mind != Person.Mind.PANIC, "nor does a fright")
	for i in 600:
		p.tick(0.05)
		if p.inside:
			break
	t.check(p.inside and p.home_sick and p.is_alive() and p.night_indoors and not p.visible and not field.alive().has(p),
		"after walking home he is indoors, hidden, out of the field, alive (%s, %.2f from home)" % [p.inside, p.ground_pos.distance_to(home)])
	t.check(crowd.alive_citizens() == alive, "and still counted among the living")
	p.send_home_sick()
	t.check(p.inside, "sending one already indoors does nothing")
	# A soldier walks to the barracks yard.
	var s: Person = crowd.soldiers[7]
	var yard := grid.nearest_walkable(City.current().landmark(&"barracks_yard").get_center())
	s.ground_pos = grid.nearest_walkable(yard + Vector2(2.0, 0.0))
	s.send_to_post(s.ground_pos)
	s.send_home_sick()
	for i in 600:
		s.tick(0.05)
		if s.inside:
			break
	t.check(s.inside and s.home_sick and s.is_alive() and crowd.alive_soldiers() > 0, "a sick soldier is taken in at the barracks yard")
	var at := s.ground_pos
	s.frame(0.5)
	t.check(s.ground_pos == at, "and is not stepped indoors")
	# The dead are not sent.
	var dead: Person = crowd.citizens[40]
	field.kill(dead, &"smite")
	dead.send_home_sick()
	t.check(not dead.home_sick, "the dead are not sent home")


static func _quarry(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var p: Person = crowd.citizens[50]
	var d := HookDirector.new()
	d.mine = p
	t.check(d.quarry(p) and not d.quarry(crowd.citizens[51]) and not MissionDirector.new().quarry(p), "quarry: the director's own answer")
	p.mind = Person.Mind.CALM
	var full := p._mind_speed()
	p.make_ill(20.0)
	t.check(is_equal_approx(p.pace_hold(), 0.5) and is_equal_approx(p._mind_speed(), full * 0.5) and not p.home_sick
		and p.mind == Person.Mind.CALM, "ill: half pace, nothing else changed")
	for i in 199:
		p.tick(0.1)
	t.check(is_equal_approx(p.pace_hold(), 0.5) and p.ill_left() > 0.0, "still ill at 19.9 s")
	p.tick(0.2)
	t.check(is_equal_approx(p.pace_hold(), 1.0) and p.ill_left() == 0.0, "well again after 20 s")
	# Another hold on his pace is his own: the illness lifts only its own.
	p.hold_pace(77, 0.3)
	p.make_ill(1.0)
	p.tick(1.1)
	t.check(is_equal_approx(p.pace_hold(), 0.3), "the illness lifts only its own hold")
	p.free_pace(77)


static func _dread(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	_clear_round(crowd)
	crowd.dusk.enabled = true
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var dpt := at + Vector2(4.0, 0.0)
	var lit := at + Vector2(-4.0, 0.0)
	var patch := crowd.lay_dusk(dpt, 1.5, 60.0)
	t.check(not crowd.dreaded(dpt) and crowd.dreads.is_empty(), "no dread, nothing dreaded")
	var a := crowd.dread(at, 6.0, 25.0)
	t.check(a > 0 and crowd.dreaded(dpt) and not crowd.dreaded(lit) and not crowd.dreaded(dpt + Vector2(10.0, 0.0)),
		"dark ground in reach is dreaded; lit ground in reach is not; nothing out of reach")
	var b := crowd.dread(at, 6.0, 25.0)
	crowd.end_dread(a)
	t.check(b != a and crowd.dreaded(dpt), "two dreads: ending one keeps the other")
	crowd.end_dread(b)
	t.check(not crowd.dreaded(dpt), "end_dread clears")
	crowd.dread(at, 6.0, 25.0)
	crowd._clock += 25.1
	t.check(not crowd.dreaded(dpt), "a dread ends at its time")
	# Nobody outside steps into it; a shadow does, and so does anyone once it ends.
	var c := crowd.dread(at, 6.0, 25.0)
	var p: Person = crowd.citizens[60]
	p.ground_pos = dpt + Vector2(1.6, 0.0)
	var into := Vector2(-0.2, 0.0)
	t.check(p._step_blocked(into) and not p._step_blocked(-into), "a step into dreaded ground is refused; a step away is not")
	p.statuses[&"shadow"] = 10.0
	t.check(not p._step_blocked(into), "a shadow is not afraid of the dark")
	p.statuses.erase(&"shadow")
	p.ground_pos = dpt
	t.check(not p._step_blocked(Vector2(0.2, 0.0)), "one already inside is not held by the edge (the dread on him holds him)")
	crowd.end_dread(c)
	p.ground_pos = dpt + Vector2(1.6, 0.0)
	t.check(not p._step_blocked(into), "ended: he walks on")
	# Under Evernight (or a NIGHT mission) the whole circle is dark.
	crowd.dusk.everywhere = true
	var e := crowd.dread(at, 6.0, 25.0)
	t.check(crowd.dreaded(lit), "everywhere dark: the whole circle is dreaded")
	crowd.end_dread(e)
	crowd.dusk.everywhere = false
	crowd.dusk.end(patch)


static func _veil_all(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var far := Vector2(-20.0, 15.0)
	var q := Vector2(5.0, 5.0)
	t.check(not crowd.is_veiled(far) and not crowd.is_veiled(q), "nothing veiled")
	var id := crowd.veil_all(10.0)
	t.check(id > 0 and crowd.is_veiled(far) and crowd.is_veiled(q) and crowd.in_dark(far), "the whole town is veiled (and dark)")
	crowd.veil(q, 2.0, 30.0)
	crowd.end_veil_all(id)
	t.check(not crowd.is_veiled(far) and crowd.is_veiled(q), "ended: the rest is seen again; a veil laid meanwhile stays")
	var id2 := crowd.veil_all(5.0)
	crowd._clock += 5.1
	t.check(not crowd.is_veiled(far), "it ends at its time")
	crowd.end_veil_all(id2)
	crowd._clock += 30.0
	t.check(not crowd.is_veiled(q), "(the plain veil ended)")


static func _take(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var grid: WalkGrid = made[2]
	_clear_round(crowd)
	crowd.remains.enabled = true
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var watcher: Person = crowd.citizens[70]
	watcher.ground_pos = at + Vector2(0.5, 0.0)  # in plain sight of every take
	var i := 71
	for kind: StringName in [&"void", &"night", &"dreamt", &"shade"]:
		var p: Person = crowd.citizens[i]
		i += 1
		p.ground_pos = at
		var alarm := crowd.alarm
		var bodies := crowd.remains.all().size()
		var voiced := crowd.deaths.voiced
		var killed := crowd.killed_citizens
		t.check(crowd.take(p, kind), "take %s" % kind)
		t.check(not p.is_alive() and crowd.alarm == alarm and crowd.remains.all().size() == bodies and crowd.deaths.voiced == voiced
			and crowd.killed_citizens == killed + 1 and not p.visible and DeathVoices.QUIET_KINDS.has(kind) and not Remains.BODY_KINDS.has(kind)
			and crowd._doomed.is_empty(), "%s: dead and counted, no alarm, no remain, no voice, nothing to find" % kind)
		t.check(not crowd.take(p, kind), "a second take of %s returns false" % kind)
	t.check(not crowd.take(null, &"void"), "nobody to take")
	# Dreamless's found body: a remain, judged as Silent Doom's dead are (a witness sees it).
	var v: Person = crowd.citizens[80]
	v.ground_pos = at
	var bodies := crowd.remains.all().size()
	var alarm := crowd.alarm
	field.kill(v, &"dreamless")
	t.check(crowd.remains.all().size() == bodies + 1 and Remains.BODY_KINDS.has(&"dreamless") and crowd._doomed.has(v)
		and crowd.alarm == alarm, "a dreamless body is left, and waits to be judged as Silent Doom's dead")
	crowd._settle_doom()
	t.check(crowd.alarm > alarm, "seen, it raises the alarm as a doom death does")
	crowd.remains.enabled = false


static func _spared(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var town: Town = made[5]
	var b: Person = crowd.citizens[90]
	var f: Person = crowd.citizens[91]
	var k: Person = crowd.citizens[92]
	b.profile.faith = CitizenProfile.Faith.BELIEVER
	f.profile.faith = CitizenProfile.Faith.FAITHFUL
	k.profile.faith = CitizenProfile.Faith.NONE
	t.check(crowd.spared(b) and not crowd.spared(f) and not crowd.spared(k), "a BELIEVER is spared; a FAITHFUL is not")
	var d := HookDirector.new()
	d.keep = k
	d.setup(null, crowd, town, null)
	t.check(crowd.spared(k) and not crowd.spared(f), "one the director keeps alive is spared")
	crowd.clear_mission_hooks()
	t.check(not crowd.spared(k) and not crowd.spared(null), "its hook goes with the mission's")
	b.profile.faith = CitizenProfile.Faith.NONE
	f.profile.faith = CitizenProfile.Faith.NONE


static func _haste(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var rules := Rules.new().setup(PackedStringArray(["doom", "smite", "swallow"]), null, made[1], made[3], crowd, made[5])
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	t.check(rules.haste.is_empty(), "no haste by default")
	for slot in 3:
		rules.cast(slot, Vector2(float(slot) * 3.0, 0.0))
	var before := [rules.cooldown_left(0), rules.cooldown_left(1), rules.cooldown_left(2)]
	rules.advance(1.0)
	t.check(is_equal_approx(before[0] - rules.cooldown_left(0), 1.0) and is_equal_approx(before[1] - rules.cooldown_left(1), 1.0),
		"no haste: one second a second")
	rules.haste = {"veil": 2.0}
	before = [rules.cooldown_left(0), rules.cooldown_left(1), rules.cooldown_left(2)]
	rules.advance(1.0)
	t.check(is_equal_approx(before[0] - rules.cooldown_left(0), 2.0) and is_equal_approx(before[1] - rules.cooldown_left(1), 1.0)
		and is_equal_approx(before[2] - rules.cooldown_left(2), 1.0) and rules.cooldown_of(2) >= 999.0,
		"haste: doom's drops by 2, smite's by 1, a once-a-descent cooldown by 1 (%s -> %s)"
		% [before, [rules.cooldown_left(0), rules.cooldown_left(1), rules.cooldown_left(2)]])
	rules.free()


static func _blight_alarm(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var well := BlightFx.target(env, TownLayout.WELLS[0].get_center())
	var alarm := crowd.alarm
	env.blight(well)
	t.check(well.blighted and crowd.alarm == alarm, "a blighted building raises no alarm (C1)")
	env.unblight(well)
	var d := MissionDirector.new()
	d.crowd = crowd
	t.check(d.blighted(Vector2.ZERO) and crowd.alarm == alarm, "nor does a director's own thing")
	var gate: Structure = (made[5] as Town).gates[0]
	env.blight(gate)
	t.check(crowd._jams.has(gate), "the gate still jams")
	env.unblight(gate)
	crowd._jams.clear()


static func _refusals(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var rules := Rules.new().setup(PackedStringArray(["blight", "dread"]), null, made[1], made[3], crowd, made[5])
	var casts: Array = []
	rules.caster = func(_s: GDScript, _g: Vector2, e: Dictionary) -> FxTimeline:
		casts.append(e)
		return null
	var refused: Array = []
	rules.cast_refused.connect(func(_s: int, why: String) -> void: refused.append(why))
	t.check(BlightFx.refusal(rules, Vector2.ZERO) == "" and DreadOfTheDarkFx.refusal(crowd, Vector2.ZERO, false) == ""
		and DreadOfTheDarkFx.refusal(null, Vector2.ZERO, false) == "", "the two refusal stubs allow every cast")
	rules.cast(0, Vector2.ZERO)
	rules.cast(1, Vector2.ZERO)
	t.check(casts.size() == 2 and refused.is_empty() and rules.cooldown_left(0) > 0.0, "so Blight and Dread go out (%s)" % [refused])
	t.check(Hud.VEIL_REFUSALS.get("no_blight", "") == "NOTHING HERE TO BLIGHT" and Hud.VEIL_REFUSALS.get("no_dark", "") == "NO DARK HERE TO DREAD",
		"the HUD's words for the two refusals")
	var src := (load("res://src/game/rules.gd") as GDScript).source_code
	t.check(src.find("BlightFx.refusal(") > 0 and src.find("DreadOfTheDarkFx.refusal(") > 0, "Rules.cast asks both")
	rules.free()


## C10: Remembrance builds its Rules as a mission does (Mission._build_act(): setup with the loadout, then free_play), so a remembered
## Veil key turns the ledger on and its cast is stamped.
static func _remembrance(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var p := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	crowd.dusk.enabled = false
	var rules := Rules.new().setup(PackedStringArray(["slumber"]), null, made[1], made[3], crowd, made[5])
	rules.free_play = true
	var casts: Array = []
	rules.caster = func(_s: GDScript, _g: Vector2, e: Dictionary) -> FxTimeline:
		casts.append(e)
		return null
	t.check(crowd.dusk.enabled, "a remembered Veil key turns the dusk ledger on")
	var id := crowd.lay_dusk(p, 3.0, 20.0)
	rules.cast(0, p)
	rules.cast(0, p + Vector2(10.0, 0.0))
	t.check(casts.size() == 2 and casts[0].get("dark") == true and casts[1].get("dark") == false and rules.cooldown_left(0) == 0.0,
		"and its casts are stamped dark or light, free of cooldown (%s)" % [casts])
	crowd.dusk.end(id)
	rules.free()
	var src := (load("res://src/game/mission.gd") as GDScript).source_code
	var at_setup := src.find("_rules.setup(loadout")
	var at_free := src.find("_rules.free_play = remembrance")
	t.check(at_setup > 0 and at_free > at_setup, "Remembrance's Rules are set up from the loadout before free play is turned on")


## C11: the aim ring is redrawn when the dusk under a still cursor changes.
static func _ring(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var p := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	crowd.dusk.enabled = true
	var rules := Rules.new().setup(PackedStringArray(["slumber", "smite"]), null, made[1], made[3], crowd, made[5])
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var aim := Targeting.new().setup(rules, crowd)
	aim.pick(0)
	aim.hover(p)
	aim._drawn_tag = aim.ring_tag()
	t.check(aim._drawn_tag == "LIGHT" and not aim.ring_stale(), "drawn LIGHT, nothing to redraw")
	var id := crowd.lay_dusk(p, 3.0, 20.0)
	t.check(aim.ring_stale(), "dusk laid under the still cursor: the ring is stale")
	aim._drawn_tag = aim.ring_tag()
	crowd.dusk.end(id)
	t.check(aim.ring_stale(), "and again when it fades")
	aim.pick(1)
	t.check(not aim.ring_stale() or aim.ring_tag() == "", "a power with one size never goes stale")
	aim.free()
	rules.free()


static func _mute(t) -> void:
	var lights := LightField.new()
	var lamp := Vector2(2.0, 2.0)
	lights.add_static(lamp, 3.0, Color(1.0, 0.8, 0.5), 1.0)
	var first := lights.sample(lamp + Vector2(0.5, 0.0))
	lights.mute(0.0)
	t.check(lights.sample(lamp + Vector2(0.5, 0.0)).r == 0.0, "muted: the lamp gives nothing")
	var late := Vector2(20.0, 20.0)
	lights.add_static(late, 3.0, Color.WHITE, 1.0)
	var late_lit := lights.sample(late)
	t.check(late_lit.r > 0.0, "a lamp lit after the mute is not muted")
	lights.mute(0.5)
	t.check(is_equal_approx(lights.sample(lamp + Vector2(0.5, 0.0)).r, first.r * 0.5) and lights.sample(late) == late_lit,
		"half; the lamp lit after the muting began is still untouched (Evernight's torches)")
	lights.mute(1.0)
	t.check(lights.sample(lamp + Vector2(0.5, 0.0)) == first and lights.sample(late) == late_lit, "mute(1.0) restores every lamp as made")
	lights._process(0.1)
	t.check(lights.sample(lamp + Vector2(0.5, 0.0)) == first, "and the frame's own update keeps it")
	lights.free()


## Step 5: the directors' quarry and keeps_alive, read from their own people.
static func _directors(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var p: Person = crowd.citizens[100]
	var o: Person = crowd.citizens[101]
	var bad: Array[String] = []
	var w := WarningDirector.new()
	w.messenger = p
	if not (w.quarry(p) and not w.quarry(o) and not w.quarry(null)):
		bad.append("warning")
	var a := AssassinateDirector.new()
	var aq := AssassinateDirector.Quarry.new()
	aq.target = p
	a.quarries.append(aq)
	if not (a.quarry(p) and not a.quarry(o)):
		bad.append("assassinate")
	var h := HuntDirector.new()
	h.head = p
	if not (h.quarry(p) and not h.quarry(o)):
		bad.append("hunt")
	var f := FestivalDirector.new()
	f.mayor = p
	if not (f.quarry(p) and not f.quarry(o)):
		bad.append("festival")
	var pr := ProcessionDirector.new()
	pr.prince = p
	if not (pr.quarry(p) and not pr.quarry(o)):
		bad.append("procession")
	var rr := RelicRunDirector.new()
	rr.carter = p
	if not (rr.quarry(p) and not rr.quarry(o)):
		bad.append("relic_run")
	var vf := VigilFlameDirector.new()
	vf.wren = p
	if not (vf.keeps_alive(p) and not vf.keeps_alive(o) and not vf.quarry(p)):
		bad.append("vigil_flame")
	var rd := RiteDirector.new()
	rd.captive = p
	if not (rd.keeps_alive(p) and not rd.keeps_alive(o)):
		bad.append("rite")
	var mh := MirasHouseDirector.new()
	mh.shouter = o
	mh.believers.append(p)
	if not (mh.keeps_alive(p) and mh.quarry(o) and not mh.quarry(p)):
		bad.append("miras_house")
	var sd := SermonDirector.new()
	sd.preacher = p
	if not (sd.quarry(p) and not sd.quarry(o)):
		bad.append("sermon")
	var hf := HideFaithfulDirector.new()
	hf.inquisitors.append(p)
	if not (hf.quarry(p) and not hf.quarry(o)):
		bad.append("hide_faithful")
	var ed := EscortDirector.new()
	ed.charge = p
	if not (ed.keeps_alive(p) and not ed.keeps_alive(o)):
		bad.append("escort")
	var rg := RingerDirector.new()
	rg.own_keeper = p
	if not (rg.quarry(p) and not rg.quarry(o)):
		bad.append("ringer")
	var br := BellRingersDirector.new()
	br.ringers.append(rg)
	if not (br.quarry(p) and not br.quarry(o)):
		bad.append("bell_ringers")
	t.check(bad.is_empty(), "each director answers quarry / keeps_alive from its own people (%s)" % [bad])
