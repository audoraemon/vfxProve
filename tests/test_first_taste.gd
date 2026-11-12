extends RefCounted
## God P3 Task 4 (plan P3-10, P3-15, P3-16; pre-flight B3 R5 R8 R9 G3): The First Taste (MS §3). The lamplighters on their rounds, the Watch at its posts,
## Halcyon's clergy marches and the cleanse, the replacement rule, the evacuation hold, the mission's frame and its hint lines. The chain itself is
## Task 3's (test_rite_director.gd); here it is used to bring a captive into the Watch's sight.

const DT := 0.05
## Where a lamplighter is chained from to be about 1.8 from the shrine-road post (outside the south wall, on the shrine road).
const BY_POST := Vector2(-8.0, 19.4)


static func run(t) -> void:
	_setup(t)
	_rounds(t)
	_drag_path(t)
	_watch_breaks(t)
	_watch_not_reposted(t)
	_march_one(t)
	_march_two(t)
	_march_breaks(t)
	_march_timeline(t)
	_kneel_spots(t)
	_file_gap(t)
	_marchers_grip(t)
	_hint_order(t)
	_freed_people(t)
	_final_frame(t)
	_stranded_replaced(t)
	_cleanse_runs(t)
	_cleanse_resets(t)
	_win_beats_cleanse(t)
	_replacement(t)
	_evacuation(t)
	_busy(t)
	_mission(t)


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
	var director := def.make_director().setup(rules, crowd, town, null) as FirstTasteDirector
	rules.director = director
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director,
		"banners": banners, "def": def}


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


## One step: the crowd, then every person the director keeps at an errand (headless, a crowd's people are not stepped by their own _process), then
## the rules and so the director.
static func _step(s: Dictionary) -> void:
	(s.crowd as Crowd).advance(DT)
	var d: FirstTasteDirector = s.d
	var seen := {}
	for p: Variant in d._held_people():
		if is_instance_valid(p) and not seen.has(p):
			seen[p] = true
			(p as Person).tick(DT)
	(s.rules as Rules).advance(DT)


static func _run(s: Dictionary, seconds: float) -> void:
	for i in roundi(seconds / DT):
		_step(s)


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


## A marker for victim `i` set down at `at`, still.
static func _victim(d: FirstTasteDirector, i: int, at: Vector2) -> Person:
	var v: Person = d.marked[i]
	_arrive(v, d._walkable(at))
	v.go_duty(v.ground_pos)
	return v


## The tag with this label's start.
static func _tag(d: FirstTasteDirector, start: String) -> MapTag:
	for tag in d.tags():
		if tag.label.begins_with(start):
			return tag
	return null


## The tags whose label starts with `start`.
static func _tags(d: FirstTasteDirector, start: String) -> Array[MapTag]:
	var out: Array[MapTag] = []
	for tag in d.tags():
		if tag.label.begins_with(start):
			out.append(tag)
	return out


## The seconds a tag's clock reads ("... IN 0:10" -> 10).
static func _clock_of(label: String) -> float:
	var words := label.split(" ")
	var parts := String(words[words.size() - 1]).split(":")
	return float(parts[0]) * 60.0 + float(parts[1])


# --- The tests -----------------------------------------------------------------------------------

static func _setup(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	t.check(d.lamps.size() == 5 and d.marked.size() == 5, "five lamplighters, all marked (%d lamps, %d marked)" % [d.lamps.size(), d.marked.size()])
	var rounds_ok := true
	var faith_ok := true
	for i in 5:
		var p: Person = d.lamps[i]
		if p == null or not d.marked.has(p) or p.ground_pos.distance_to(d._lamp_spot(i, 0)) > 0.3:
			rounds_ok = false
		if p == null or p.profile.faith != CitizenProfile.Faith.FAITHFUL:
			faith_ok = false
	t.check(rounds_ok, "each lamplighter stands at his own round's first lamp")
	t.check(faith_ok, "each is Faithful for the night")
	var distinct := {}
	for p in d.lamps:
		distinct[p] = true
	t.check(distinct.size() == 5, "five different people")
	var gold := _tags(d, FirstTasteDirector.TAG_LAMPLIGHTER)
	var all_gold := not gold.is_empty()
	for tag in gold:
		if tag.color != RiteDirector.MARK_VICTIM or not tag.edge:
			all_gold = false
	t.check(gold.size() == 5 and all_gold, "five gold, edge-arrowed LAMPLIGHTER tags (%d)" % gold.size())
	t.check(d.watch.size() == 4, "four soldiers of the Watch (%d)" % d.watch.size())
	var spread := INF
	var at_post := true
	for i in d.watch.size():
		var w: Person = d.watch[i]
		if w.ground_pos.distance_to(d._post_of(w)) > 0.3:
			at_post = false
		for j in range(i + 1, d.watch.size()):
			spread = minf(spread, w.ground_pos.distance_to(d.watch[j].ground_pos))
	t.check(at_post, "each stands at his post")
	t.check(spread > 2.0 * SilentDoom.RADIUS, "the Watch is spread over two Silent Doom radii (nearest pair %.2f > %.2f)" % [spread, 2.0 * SilentDoom.RADIUS])
	var red := _tags(d, FirstTasteDirector.TAG_WATCH)
	t.check(red.size() == 4 and red[0].color == EscortDirector.MARK_WATCHED, "four red WATCH tags (%d)" % red.size())
	# R9: the def's own intro banner is the opening; the director pushes none.
	t.check((s.def as MissionDef).intro_banner == "THE FIRST TASTE" and (s.banners as Array).is_empty(),
		"the opening banner is the def's own, and the director pushes none (%s)" % [s.banners])
	t.check(d.chain_state == RiteDirector.Chain.READY and d.chain_plate() == "READY", "the chain is ready")
	t.check(d.shards == 0 and d.need() == 3 and not d.flame_out and d.marches.is_empty(), "no shard, no march, the flame burning")
	_done(s)


## Each lamplighter's lamp order and the four seconds at each.
static func _rounds(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	var p: Person = d.lamps[2]
	var stages: Array[int] = [d._stage[2]]
	var reached_at := -1.0
	var dwell: Array[float] = []
	var clock := 0.0
	var end := 70.0
	while clock < end:
		_step(s)
		clock += DT
		if reached_at < 0.0 and d._reached[2] >= 0.0:
			reached_at = clock
		if d._stage[2] != stages[stages.size() - 1]:
			stages.append(d._stage[2])
			dwell.append(clock - reached_at)
			reached_at = -1.0
	t.check(stages.size() >= 5 and stages.slice(0, 5) == [0, 1, 2, 3, 0], "a lamplighter visits his four lamps in order, then loops (%s)" % [stages])
	var dwell_ok := not dwell.is_empty()
	for x in dwell:
		if x < FirstTasteDirector.LAMP_SECONDS - 0.1 or x > FirstTasteDirector.LAMP_SECONDS + 0.7:
			dwell_ok = false
	t.check(dwell_ok, "he stands LAMP_SECONDS (4 s) at each lamp (%s)" % [dwell])
	t.check(p.mind == Person.Mind.DUTY and d.marked.has(p), "and stays on duty, still marked")
	_done(s)


## MS §2: every round's first lamp has a way to the shrine through the Main Gate; the pace keeps each drag to 55 s or less. A path over 45 units is
## reported in the message, not failed (MS §2 "about 30-45").
static func _drag_path(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	var gate := City.current().landmark(&"main_gate").get_center()
	var ok_gate := true
	var ok_time := true
	var report := PackedStringArray()
	for i in 5:
		var first := d._lamp_spot(i, 0)
		var way := d._path_length(first)
		var near := INF
		for pt in (s.crowd as Crowd)._grid.path(first, d.shrine()):
			near = minf(near, pt.distance_to(gate))
		if way < 0.0 or near > 2.0:
			ok_gate = false
		if way / RiteDirector.drag_pace(way) > RiteDirector.DRAG_MAX + 0.001:
			ok_time = false
		report.append("%d: %.1f" % [i + 1, way])
	var shortest := INF
	var longest := 0.0
	for i in 5:
		var w := d._path_length(d._lamp_spot(i, 0))
		shortest = minf(shortest, w)
		longest = maxf(longest, w)
	t.check(shortest >= 30.0 and longest <= 60.0, "the ways are between 30 and 60 units (%.1f to %.1f)" % [shortest, longest])
	t.check(ok_gate, "every round's first lamp has a path to the shrine through the Main Gate (within 2.0)")
	t.check(ok_time, "and at drag_pace() no drag takes over 55 s (path lengths by round: %s; over 45 is reported, not failed)" % ", ".join(report))
	_done(s)


## A captive within sight of a post is walked to and gripped; out of sight the watchman goes back to his post.
static func _watch_breaks(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	var post := Vector2(-8.0, 17.6)
	var near_post: Person = null
	for w in d.watch:
		if w.ground_pos.distance_to(post) < 0.5:
			near_post = w
	t.check(near_post != null, "a watchman stands at the shrine-road post")
	var v := _victim(d, 0, BY_POST)
	t.check(v.ground_pos.distance_to(post) < FirstTasteDirector.SIGHT, "the lamplighter is within the post's sight (%.2f)" % v.ground_pos.distance_to(post))
	t.check(d.chain(v) == "", "he is chained")
	var took := _until(s, 6.0, func() -> bool: return d.grip_by != null)
	t.check(d.grip_by != null and d.watch.has(d.grip_by) and d.grip > 0.0 and d.grip_by.ground_pos.distance_to(v.ground_pos) <= RiteDirector.GRIP_REACH + 0.2,
		"the Watch walked to him and gripped within %.1f s (grip %.2f, by a watchman: %s)" % [took, d.grip, d.grip_by != null and d.watch.has(d.grip_by)])
	var tag := _tag(d, "CAPTIVE")
	t.check(tag != null and tag.ring >= 0.0, "the captive's tag shows the grip's ring (%s)" % [tag.ring if tag != null else "none"])
	_until(s, 6.0, func() -> bool: return (s.banners as Array).has(RiteDirector.FREED_BANNER))
	t.check((s.banners as Array).has(RiteDirector.FREED_BANNER) and d.chain_state == RiteDirector.Chain.COOLDOWN,
		"a full ring breaks the chain: THE CHAIN BREAKS (%s)" % [s.banners])
	# Out of sight, the watchman goes back to his post.
	_run(s, 12.0)
	t.check(near_post.ground_pos.distance_to(post) < 0.8, "out of sight the watchman returns to his post (%.2f away)" % near_post.ground_pos.distance_to(post))
	_done(s)


## R5: a compelled (held) watchman is not re-posted until the hold ends.
static func _watch_not_reposted(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	var w: Person = d.watch[2]
	var post := d._post_of(w)
	w.compel(post + Vector2(0.0, 0.0), 3.0, 0.5, Color.WHITE)
	t.check(w.held_by_god() and d.held(w), "a compelled watchman is held")
	var anchor: Vector2 = w.anchor
	_run(s, 1.0)
	t.check(w.mind == Person.Mind.COMPELLED, "and the director leaves him to the hold (mind %s)" % [w.mind])
	_run(s, 3.5)
	t.check(not d.held(w), "his hold ends by itself")
	_done(s)


## The second marcher etc. are tested with the first: offer() one lamplighter -> a muster of two.
static func _march_one(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	_usual_pace(s)
	t.check(d.offer(d.marked[0]) and d.shards == 1, "a lamplighter offered on the stone: shard 1")
	t.check(d.marches.size() == 1, "one march is formed (%d)" % d.marches.size())
	if d.marches.is_empty():
		_done(s)
		return
	var m: FirstTasteDirector.March = d.marches[0]
	t.check(m.people.size() == 2 and not m.walking and is_equal_approx(m.muster_left, FirstTasteDirector.MARCH_AFTER),
		"two marchers muster %d s (%d people)" % [int(FirstTasteDirector.MARCH_AFTER), m.people.size()])
	var clergy := true
	for p in m.people:
		if not CitizenProfile.is_clergy(p.profile.role):
			clergy = false
	t.check(clergy, "both are clergy")
	t.check((s.banners as Array).has(FirstTasteDirector.ANSWER), "the banner: HALCYON ANSWERS - CLERGY MARCH ON THE SHRINE (%s)" % [s.banners])
	_run(s, 0.3)
	var muster := _tag(d, "CLERGY MARCH IN")
	t.check(muster != null and muster.label == "CLERGY MARCH IN 0:10" and muster.color == EscortDirector.MARK_WATCHED and muster.edge,
		"the leader's tag counts the muster: %s" % [muster.label if muster != null else "none"])
	t.check(_tags(d, FirstTasteDirector.TAG_CLERGY).size() >= 2, "red CLERGY tags")
	var rows := d.strip_rows()
	var total0 := float(rows[0]["in"]) if not rows.is_empty() else -1.0
	t.check(rows.size() == 1 and String(rows[0]["label"]) == FirstTasteDirector.STRIP_ROW and total0 > 95.0 and total0 < 115.0,
		"the strip counts the muster and the walk once: about 10 + 92 s (%s)" % [rows])
	t.check(d.hint_phase() != "march", "no march walks yet: phase %s" % d.hint_phase())
	var before_out := 0.0
	while not m.walking:
		before_out = float(d.strip_rows()[0]["in"])
		_step(s)
	var after_out := float(d.strip_rows()[0]["in"])
	t.check(m.walking and before_out - after_out >= 0.0 and before_out - after_out < 2.0,
		"the strip's row counts down smoothly through the set-out (%.1f -> %.1f)" % [before_out, after_out])
	t.check(absf(m.eta - 92.0) < 8.0, "a marcher of the usual pace walks the way in about 90 s (%.1f s)" % m.eta)
	t.check(d.hint_phase() == "march", "phase march while a file walks (%s)" % d.hint_phase())
	var gap := INF
	var started: Vector2 = m.people[0].ground_pos
	var eta0 := m.eta
	for i in roundi(12.0 / DT):
		_step(s)
		gap = minf(gap, m.people[0].ground_pos.distance_to(m.people[1].ground_pos))
	t.check(gap >= FirstTasteDirector.MARCH_GAP - 0.25 and gap > 2.0 * SilentDoom.RADIUS,
		"in file they keep MARCH_GAP (1.8) apart, over 1.6 (nearest %.2f)" % gap)
	t.check(m.people[0].ground_pos.distance_to(started) > 3.0, "the leader walks (%.1f units)" % m.people[0].ground_pos.distance_to(started))
	var leader := _tag(d, "CLERGY - SHRINE IN")
	t.check(leader != null and _clock_of(leader.label) < eta0 - 5.0 and _clock_of(leader.label) > 60.0,
		"the leader's tag counts down: %s (started at about %.0f s)" % [leader.label if leader != null else "none", eta0])
	var speed_ok := true
	for p in m.people:
		if absf(p.pace * Person.PANIC_SPEED - FirstTasteDirector.MARCH_PACE * float(m.pace0[p])) > 0.001:
			speed_ok = false
	t.check(speed_ok, "each walks at MARCH_PACE times his own pace (the usual pace is under the 88 s cap)")
	rows = d.strip_rows()
	t.check(rows.size() == 1 and float(rows[0]["in"]) < eta0, "the strip's row counts down (%s)" % [rows])
	_done(s)


## The second offer sends 3; the third sends none and wins.
static func _march_two(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	d.offer(d.marked[0])
	t.check(d.marches.size() == 1 and d.marches[0].people.size() == 2, "shard 1: a march of 2")
	d.offer(d.marked[0])
	t.check(d.marches.size() == 2 and d.marches[1].people.size() == 3, "shard 2: a march of 3 (%d marches)" % d.marches.size())
	var fresh := true
	for p in d.marches[1].people:
		if d.marches[0].people.has(p):
			fresh = false
	t.check(fresh, "the second march are other clergy")
	# The musterers stand over two Silent Doom radii apart after the walk grid's snap (milestone review Minor 3).
	var nearest := INF
	var mus: Array = d.marches[1].people
	for i in mus.size():
		for j in range(i + 1, mus.size()):
			nearest = minf(nearest, (mus[i] as Person).anchor.distance_to((mus[j] as Person).anchor))
	t.check(nearest > 2.0 * SilentDoom.RADIUS, "the three musterers' spots are over 1.6 apart (nearest %.2f)" % nearest)
	d.offer(d.marked[0])
	t.check(d.shards == 3 and d.marches.size() == 2 and d.stages_done(), "shard 3 sends no march, and the shards are done (%d marches)" % d.marches.size())
	_done(s)


## MS §3.4: a march with fewer than 2 able breaks; a frightened marcher leaves for good; a held one stays on it.
static func _march_breaks(t) -> void:
	# One of two killed -> breaks, the other goes home.
	var s := _world()
	var d: FirstTasteDirector = s.d
	d.offer(d.marked[0])
	var m: FirstTasteDirector.March = d.marches[0]
	var a: Person = m.people[0]
	var b: Person = m.people[1]
	var pace_a := float(m.pace0[a])
	_run(s, FirstTasteDirector.MARCH_AFTER + 1.0)
	(s.crowd as Crowd)._field.kill(b, &"fire")
	_run(s, 0.6)
	t.check(m.done and (s.banners as Array).has(FirstTasteDirector.BREAKS), "one of two killed: THE MARCH BREAKS (%s)" % [s.banners])
	t.check(m.people.is_empty() and not d._marching(a), "the survivor is off the march")
	t.check(absf(a.pace - pace_a) < 0.0001, "and has his own pace back (%.3f, was %.3f)" % [a.pace, pace_a])
	t.check(d.hint_phase() != "march", "a broken march is not a phase (%s)" % d.hint_phase())
	_done(s)

	# One of three frightened -> still marching with two.
	s = _world()
	d = s.d
	d.offer(d.marked[0])
	d.offer(d.marked[0])
	var m2: FirstTasteDirector.March = d.marches[1]
	_run(s, 0.3)
	var first: Person = m2.people[0]
	var scared: Person = m2.people[1]
	scared.panic(scared.ground_pos + Vector2(0.5, 0.0), 1.0)
	_run(s, 0.6)
	t.check(not m2.done and m2.people.size() == 2 and not m2.people.has(scared) and m2.fled.has(scared),
		"one of three frightened: he leaves the march for good, two march on (%d left)" % m2.people.size())
	_run(s, 6.0)
	t.check(not m2.people.has(scared), "and does not rejoin once calm")
	# Another frightened -> breaks.
	var other: Person = m2.people[1]
	other.panic(other.ground_pos + Vector2(0.5, 0.0), 1.0)
	_run(s, 0.6)
	t.check(m2.done and first != null, "a second frightened of three: fewer than 2 left, the march breaks")
	_done(s)

	# A whispered marcher stays on the march and walks on afterwards.
	s = _world()
	d = s.d
	d.offer(d.marked[0])
	m = d.marches[0]
	_run(s, FirstTasteDirector.MARCH_AFTER + 2.0)
	var held_one: Person = m.people[0]
	var before := held_one.ground_pos
	held_one.whisper(held_one.ground_pos + Vector2(0.0, 4.0), 2.0)
	_run(s, 1.0)
	t.check(m.people.has(held_one) and not m.done, "a whispered marcher stays on the march")
	_until(s, 40.0, func() -> bool: return held_one.mind == Person.Mind.DUTY)
	t.check(m.people.has(held_one) and held_one.mind == Person.Mind.DUTY and held_one.anchor.distance_to(m.spots[held_one]) < 0.4,
		"and is on duty for his spot again once the whisper ends (mind %s)" % [held_one.mind])
	t.check(before.distance_to(held_one.ground_pos) > 0.0, "(he has moved)")
	_done(s)


## Puts both marchers of `m` on their spots (kneeling) at once.
static func _kneel_all(m: FirstTasteDirector.March, d: FirstTasteDirector) -> void:
	m.walking = true
	m.muster_left = 0.0
	for p in m.people:
		m.spots[p] = d._kneel_spot(m, m.people.find(p))
		m.paused[p] = false
		_arrive(p, m.spots[p])
		p.go_duty(p.ground_pos)


## Two kneeling for 12 s put the flame out and the rules lose with `cleansed`.
static func _cleanse_runs(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	d.offer(d.marked[0])
	var m: FirstTasteDirector.March = d.marches[0]
	_kneel_all(m, d)
	_run(s, 1.0)
	t.check(d.cleansing() and d.hint_phase() == "cleanse" and (s.banners as Array).has(FirstTasteDirector.CLEANSE),
		"two kneeling: the cleanse begins (banner, phase %s)" % d.hint_phase())
	var shrine := _tag(d, "CLEANSING")
	t.check(shrine != null and shrine.ring > 0.0 and shrine.ring < 1.0 and _clock_of(shrine.label) <= 11.0,
		"the shrine's tag counts down CLEANSING with a ring (%s, ring %.2f)" % [shrine.label if shrine != null else "none", shrine.ring if shrine != null else -1.0])
	t.check(not (s.rules as Rules).finished, "11 s in, the rite is not lost")
	_run(s, FirstTasteDirector.CLEANSE_SECONDS - 0.5)
	t.check(d.flame_out, "after 12 s the flame is out")
	_run(s, 0.2)
	var rules: Rules = s.rules
	t.check(rules.finished and not rules.result().won and rules.result().reason == "cleansed", "the rules lose: cleansed (%s %s)" % [rules.finished, rules.result().reason])
	_done(s)


## One killed mid-cleanse resets the ring; a held kneeler stops it.
static func _cleanse_resets(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	d.offer(d.marked[0])
	d.offer(d.marked[0])
	var m: FirstTasteDirector.March = d.marches[1]
	_kneel_all(m, d)
	_run(s, 6.0)
	t.check(d.cleansing() and d.cleanse > 4.0 and d.cleanse < 8.0, "three kneeling: the ring fills (%.1f)" % d.cleanse)
	(s.crowd as Crowd)._field.kill(m.people[0], &"fire")
	_run(s, 0.5)
	t.check(d.cleansing() and d.cleanse > 0.0 and not m.done, "one of three killed: two still kneel, the ring runs on")
	# A held kneeler (whispered) leaves one kneeling: reset.
	var held_one: Person = m.people[0]
	held_one.whisper(held_one.ground_pos + Vector2(0.0, 3.0), 3.0)
	_run(s, 0.6)
	t.check(d.cleanse == 0.0 and not d.cleansing(), "a held kneeler: fewer than 2 kneel, the ring resets to 0 (%.2f)" % d.cleanse)
	t.check(not d.flame_out, "and the flame is not out")
	_done(s)


## The third shard and a full cleanse in the same check: the shards come first in the objectives, so it is a win.
static func _win_beats_cleanse(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	var rules: Rules = s.rules
	t.check(rules.objectives.size() == 3 and rules.objectives[0] is StagesObjective and rules.objectives[1] is RiteFlameObjective,
		"the rules hold shards, the flame, Dawn in that order")
	d.shards = 3
	d.flame_out = true
	rules._check_end()
	t.check(rules.finished and rules.result().won and rules.result().reason == "shards",
		"the third shard and a full cleanse in one check: won, reason shards (%s %s)" % [rules.finished, rules.result().reason])
	_done(s)
	s = _world()
	d = s.d
	rules = s.rules
	d.flame_out = true
	rules._check_end()
	t.check(rules.finished and not rules.result().won and rules.result().reason == "cleansed", "a cleanse alone loses: cleansed")
	_done(s)


## MS §3.6: kill two lamplighters before any shard -> one new lamplighter on a freed round.
static func _replacement(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	var first_a: Person = d.lamps[1]
	var first_b: Person = d.lamps[3]
	(s.crowd as Crowd)._field.kill(first_a, &"fire")
	_run(s, 0.6)
	t.check(d.left() == 4 and d.marked.size() == 4 and not (s.banners as Array).has(FirstTasteDirector.NEW_LAMPLIGHTER),
		"one gone leaves 4 (shards needed + 1): no replacement yet (%d left)" % d.left())
	(s.crowd as Crowd)._field.kill(first_b, &"fire")
	_run(s, 0.6)
	t.check(d.left() == 4 and (s.banners as Array).has(FirstTasteDirector.NEW_LAMPLIGHTER) and d.marked.size() == 4,
		"two gone: a new lamplighter sets out, banner A NEW LAMPLIGHTER SETS OUT (%d left)" % d.left())
	t.check(MissionDirector._alive(d.lamps[1]) and d.lamps[1] != first_a and d.marked.has(d.lamps[1]),
		"he takes the lowest freed round (round 2) and is marked")
	t.check(d.lamps[1].profile.faith == CitizenProfile.Faith.FAITHFUL, "and is Faithful for the night")
	_run(s, 0.6)
	t.check(not MissionDirector._alive(d.lamps[3]) and d.left() >= 4, "(round 4 stays empty: only enough are replaced, %d left)" % d.left())
	# A safe lamplighter (reached the Temple) is also gone.
	var victim: Person = d.lamps[0]
	d.safe.append(victim)
	d.marked.erase(victim)
	_run(s, 0.6)
	t.check(d.left() >= 4, "a victim safe at the Temple counts as gone: the rule refills (%d left)" % d.left())
	_done(s)


## An evacuation keeps the lamplighters, the Watch and the marchers on their errands.
static func _evacuation(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	d.offer(d.marked[0])
	var held: Array = d._held_people()
	var all_in := true
	for v in d.marked:
		if not held.has(v):
			all_in = false
	for w in d.watch:
		if not held.has(w):
			all_in = false
	for p in d.marches[0].people:
		if not held.has(p):
			all_in = false
	t.check(all_in, "the held list has every lamplighter, the whole Watch and the march (%d people)" % held.size())
	(s.crowd as Crowd)._evacuate()
	_run(s, 1.0)
	var on_duty := 0
	for v in d.marked:
		if v.mind == Person.Mind.DUTY:
			on_duty += 1
	t.check(on_duty == d.marked.size(), "the lamplighters are on duty (%d of %d)" % [on_duty, d.marked.size()])
	var post_ok := 0
	for w: Variant in d.watch:
		if (w as Person).mind in EscortDirector.POST_MINDS:
			post_ok += 1
	t.check(post_ok == d.watch.size(), "the Watch stays at its posts through the evacuation (%d of %d)" % [post_ok, d.watch.size()])
	var m: FirstTasteDirector.March = d.marches[0]
	_run(s, FirstTasteDirector.MARCH_AFTER + 1.0)
	var marching := 0
	for p: Variant in m.people:
		if (p as Person).mind == Person.Mind.DUTY:
			marching += 1
	t.check(m.walking and marching == m.people.size() and not m.done, "and the march sets out and walks on (%d of %d on duty)" % [marching, m.people.size()])
	_done(s)


## G3: busy() is true for a lamplighter, a watchman and a marcher.
static func _busy(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	t.check(d.busy(d.marked[0]) and d.busy(d.watch[0]), "busy: a lamplighter and a watchman")
	d.offer(d.marked[0])
	t.check(d.busy(d.marches[0].people[0]), "busy: a mustering clergyman")
	var other: Person = null
	for p in (s.crowd as Crowd).citizens:
		if not d.busy(p) and MissionDirector._alive(p):
			other = p
			break
	t.check(other != null and not d.busy(other), "and an ordinary citizen is not")
	_done(s)


## The mission's frame: objectives in order, the Watch's bell, the director, the hints, and no Descent.
static func _mission(t) -> void:
	var def := MissionBook.first_taste()
	var objs := def.make_objectives.call() as Array
	t.check(objs.size() == 3 and objs[0] is StagesObjective and objs[1] is RiteFlameObjective and objs[2] is ClockObjective,
		"objectives: shards, the flame, Dawn (%d)" % objs.size())
	t.check(String((objs[1] as Objective).label) == "The shrine's flame" and (objs[1] as Objective).reason == "cleansed",
		"the flame's objective: label and reason")
	t.check(def.lantern == LanternWatch.KIND_WATCH and def.director == FirstTasteDirector, "the Watch's bell, and FirstTasteDirector")
	t.check(def.camera_at == FirstTasteDirector.CAMERA_AT and def.intro_from.distance_to(def.camera_at) > 1.0, "a camera spot and an intro start")
	for phase in ["", "drag", "march", "cleanse"]:
		t.check(MissionHints.line("first_taste", phase) != "", "a hint for phase '%s'" % phase)
	t.check(MissionHints.line("first_taste", "drag") != MissionHints.line("first_taste", "march")
		and MissionHints.line("first_taste", "chain") == MissionHints.line("first_taste"), "the four lines differ; phase chain falls back to the mission's own")
	t.check(not Mission.has_descent(def, true), "the night has no Descent (no wishes, believers, Faith or ASCEND)")
	# The tour: the shrine, the gate pair, back to the camera's spot.
	var s := _world()
	var d: FirstTasteDirector = s.d
	var tour := d.tour()
	t.check(tour.size() == 3 and (tour[0][0] as Vector2).distance_to(d.shrine()) < 0.1 and (tour[2][0] as Vector2) == FirstTasteDirector.CAMERA_AT,
		"the tour: the shrine, the gate pair, the camera's spot (%d stops)" % tour.size())
	_done(s)


# --- Review round (review-t4) --------------------------------------------------------------------

## Every citizen at the usual pace 1.0, so a march walks the typical way.
static func _usual_pace(s: Dictionary) -> void:
	for p: Person in (s.crowd as Crowd).citizens:
		p.pace = 1.0


## Review I5 (controller ruling), MS §3.5: the flame is never out sooner than ~110 s after the shard, even for the quickest clergy (pace 1.2); a march
## of the usual pace walks about 90 s.
static func _march_timeline(t) -> void:
	for pace in [1.2, 1.0]:
		var s := _world()
		var d: FirstTasteDirector = s.d
		for p: Person in (s.crowd as Crowd).citizens:
			p.pace = pace
		d.offer(d.marked[0])
		var m: FirstTasteDirector.March = d.marches[0]
		var took := _until(s, 200.0, func() -> bool: return d.flame_out)
		if pace == 1.2:
			t.check(d.flame_out and took >= 110.0 - 0.3, "the quickest clergy (1.2): the flame is out %.1f s after the shard, not under 110 s" % took)
		else:
			t.check(d.flame_out and took >= 110.0 and took < 135.0, "the usual clergy (1.0): the flame is out %.1f s after the shard (about 10 + 92 + 12 + the file's stagger)" % took)
		var rules: Rules = s.rules
		_run(s, 0.2)
		t.check(rules.finished and rules.result().reason == "cleansed" and m.walking, "and the rules lose: cleansed")
		_done(s)


## Review I3: the kneeling spots, after the walk grid's snap, at the real shrine -- one march of 2, one of 3, and both together -- stay over two Silent Doom
## radii apart and each has a way.
static func _kneel_spots(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	d.offer(d.marked[0])
	d.offer(d.marked[0])
	var spots: Array[Vector2] = []
	var all_walk := true
	var per_march := PackedStringArray()
	for m: FirstTasteDirector.March in d.marches:
		var mine: Array[Vector2] = []
		for k in m.people.size():
			var at := d._kneel_spot(m, k)
			mine.append(at)
			spots.append(at)
			if d._walk_way(d.lantern_door(), at) < 0.0:
				all_walk = false
		per_march.append("%d spots" % mine.size())
	var nearest := INF
	for i in spots.size():
		for j in range(i + 1, spots.size()):
			nearest = minf(nearest, spots[i].distance_to(spots[j]))
	t.check(spots.size() == 5 and nearest > 2.0 * SilentDoom.RADIUS,
		"the five kneeling spots of both marches stay over 1.6 apart after the snap (nearest %.2f; %s)" % [nearest, ", ".join(per_march)])
	t.check(all_walk, "and each has a way from the Temple door")
	var near_shrine := true
	for at in spots:
		if at.distance_to(d.shrine()) > 3.5:
			near_shrine = false
	t.check(near_shrine, "and each kneels near the shrine")
	_done(s)


## Review minor: behind a held (stationary) leader a follower keeps over 1.6 (the margin).
static func _file_gap(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	_usual_pace(s)
	d.offer(d.marked[0])
	var m: FirstTasteDirector.March = d.marches[0]
	_until(s, 20.0, func() -> bool: return m.walking)
	_run(s, 6.0)
	var leader: Person = m.people[0]
	var follower: Person = m.people[1]
	# Hold the leader still (a compulsion on the spot) for 15 s.
	var low := INF
	var held_frames := 0
	for i in roundi(15.0 / DT):
		if i == 0:
			leader.compel(leader.ground_pos, 15.0, 0.5, Color.WHITE)
		_step(s)
		low = minf(low, leader.ground_pos.distance_to(follower.ground_pos))
		held_frames += 1 if d.held(leader) else 0
	t.check(held_frames > 100 and low > 2.0 * SilentDoom.RADIUS,
		"behind a held leader (held %d of 300 frames) the follower stays over 1.6 (nearest %.2f)" % [held_frames, low])
	_done(s)


## MS §3.4: a walking marcher grips a captive (marchers are breakers); a mustering one does not.
static func _marchers_grip(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	d.offer(d.marked[0])
	var m: FirstTasteDirector.March = d.marches[0]
	var marcher: Person = m.people[0]
	var v := _victim(d, 0, Vector2(-8.0, 19.4))
	d.chain(v)
	_arrive(marcher, v.ground_pos + Vector2(0.4, 0.0))
	marcher.go_duty(marcher.ground_pos)
	# Out of the watchmen's way: set the Watch's soldiers far off.
	for w: Variant in d.watch:
		(w as Person).ground_pos = Vector2(14.0, -12.0)
		(w as Person).send_to_post((w as Person).ground_pos)
	_run(s, 2.0)
	t.check(d.chain_state == RiteDirector.Chain.DRAG and d.grip_by != marcher and d.grip == 0.0,
		"a mustering marcher beside the captive does not grip (grip %.2f)" % d.grip)
	m.walking = true
	m.muster_left = 0.0
	for p: Variant in m.people:
		m.spots[p] = d._kneel_spot(m, m.people.find(p))
		m.paused[p] = false
	if d.chain_state == RiteDirector.Chain.DRAG:
		_arrive(marcher, v.ground_pos + Vector2(0.4, 0.0))
		marcher.go_duty(d.shrine())
		_until(s, 1.0, func() -> bool: return d.grip_by == marcher)
		t.check(d.grip_by == marcher and d.grip > 0.0, "a walking marcher beside the captive grips (grip %.2f)" % d.grip)
	else:
		t.check(false, "the chain was still dragging (state %s)" % [d.chain_state])
	_done(s)


## Review minor: the drag line shows first while a breaker has his grip, even with a march walking.
static func _hint_order(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	t.check(d.hint_phase() == "chain", "ready, nothing marching: phase chain (%s)" % d.hint_phase())
	d.offer(d.marked[0])
	var m: FirstTasteDirector.March = d.marches[0]
	m.walking = true
	t.check(d.hint_phase() == "march", "a file walking: phase march (%s)" % d.hint_phase())
	d.chain_state = RiteDirector.Chain.DRAG
	d.grip_by = d.watch[0]
	t.check(d.hint_phase() == "drag", "a grip on the captive: phase drag first (%s)" % d.hint_phase())
	d.grip_by = null
	d.chain_state = RiteDirector.Chain.READY
	_done(s)


## Review I1, I2: a body is freed after its death fade. The Watch, the rounds, the marches and the replacement rule go on past it.
static func _freed_people(t) -> void:
	# (a) the Watch: one killed (and freed after its fade), one freed at once.
	var s := _world()
	var d: FirstTasteDirector = s.d
	var killed: Person = d.watch[0]
	var freed: Person = d.watch[1]
	(s.crowd as Crowd)._field.kill(killed, &"fire")
	freed.free()
	_run(s, 3.0)
	d._look()
	t.check(d.watch.size() == 2 and d._breakers().size() == 2, "the Watch is pruned to the living (%d, %d breakers)" % [d.watch.size(), d._breakers().size()])
	t.check(d.busy(d.marked[0]) and not d.tags().is_empty() and d._held_people().size() >= 7, "busy(), tags() and _held_people() pass over the freed Watch")
	# a gripping breaker among the survivors still grips
	var v := _victim(d, 0, Vector2(-8.0, 19.4))
	var post_man: Person = d.watch[0] if d.watch[0].ground_pos.distance_to(Vector2(-8.0, 17.6)) < 1.0 else d.watch[1]
	d.chain(v)
	_run(s, 6.0)
	t.check(post_man.ground_pos.distance_to(Vector2(-8.0, 17.6)) < 1.0 and (d.grip_by == post_man or (s.banners as Array).has(RiteDirector.FREED_BANNER)),
		"the surviving watchman at the shrine road still grips (grip by him: %s)" % [d.grip_by == post_man])
	_done(s)
	# (b) the rounds and the replacement rule: one sacrificed, two freed.
	s = _world()
	d = s.d
	var keep: Person = d.lamps[2]
	var gone1: Person = d.lamps[0]
	var gone2: Person = d.lamps[1]
	d.offer(d.lamps[3])
	gone1.free()
	gone2.free()
	_run(s, 3.0)
	t.check((s.banners as Array).has(FirstTasteDirector.NEW_LAMPLIGHTER) and d.left() >= 3,
		"past the fade the replacement rule still fires and a new lamplighter sets out (%d left)" % d.left())
	_run(s, 12.0)
	t.check(MissionDirector._alive(keep) and d._stage[2] >= 1, "and another round goes on: the lamplighter of round 3 reached his second lamp (stage %d)" % d._stage[2])
	_done(s)
	# (c) a marcher of three freed: the march goes on with two.
	s = _world()
	d = s.d
	d.offer(d.marked[0])
	d.offer(d.marked[0])
	var m: FirstTasteDirector.March = d.marches[1]
	var lost: Person = m.people[2]
	lost.free()
	_run(s, 3.0)
	t.check(not m.done and m.people.size() == 2 and m.fled.size() == 0, "a marcher freed: the march goes on with two (%d)" % m.people.size())
	_run(s, FirstTasteDirector.MARCH_AFTER)
	t.check(m.walking and d._breakers().size() >= 2 and d.tags().size() > 0, "and sets out, its people breakers, tags() working")
	_done(s)


## The third shard and a cleanse that fills in the same step: the win comes first.
static func _final_frame(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	var rules: Rules = s.rules
	d.offer(d.marked[0])
	var m: FirstTasteDirector.March = d.marches[0]
	_kneel_all(m, d)
	_run(s, 1.0)
	d.cleanse = FirstTasteDirector.CLEANSE_SECONDS - 0.04
	d.offer(d.marked[0])
	d.offer(d.marked[0])
	_step(s)
	t.check(d.flame_out and d.shards == 3, "the cleanse filled in the step of the third shard (flame_out %s, shards %d)" % [d.flame_out, d.shards])
	t.check(rules.finished and rules.result().won and rules.result().reason == "shards", "and the night is won, reason shards (%s)" % [rules.result().reason])
	_done(s)


## Milestone review I1, on the REAL director (the stub's _replace() always adds someone): lamplighters the chain let go of because they could not move (a
## closed pocket after a Mirrorfold) stay alive and out of safety, so no round is free unless the stranded one's round counts as gone. Shard 2 is set by
## hand (no one dies, so no round is free for another reason), four of the five are stranded and kept in their pockets, and a new lamplighter must set out on
## a stranded man's round.
static func _stranded_replaced(t) -> void:
	var s := _world()
	var d: FirstTasteDirector = s.d
	d.shards = 2
	var pins := {}
	var rounds: Array[int] = []
	var originals: Array = d.lamps.duplicate()
	for n in 4:
		_until(s, 20.0, func() -> bool: return d.chain_state == RiteDirector.Chain.READY)
		var v: Person = null
		for m: Person in d.marked:
			if not d._stranded.has(m) and MissionDirector._alive(m):
				v = m
				break
		pins[v] = v.ground_pos
		d.chain(v)
		var held_for := 0.0
		while held_for < RiteDirector.STUCK_SECONDS + 3.0 and d.chain_state != RiteDirector.Chain.COOLDOWN:
			for k: Person in pins:
				k.ground_pos = pins[k]
			_step(s)
			held_for += DT
		rounds.append(d.lamps.find(v))
	t.check(d._stranded.size() == 4, "four are stranded (%d)" % d._stranded.size())
	for i in roundi(1.0 / DT):
		for k: Person in pins:
			k.ground_pos = pins[k]
		_step(s)
	t.check((s.banners as Array).has(FirstTasteDirector.NEW_LAMPLIGHTER), "a new lamplighter sets out (%s)" % [s.banners])
	t.check(d.left() >= d.need() - d.shards + 1, "enough are in play again (%d left, need %d)" % [d.left(), d.need() - d.shards + 1])
	var fresh_round := -1
	for i in d.lamps.size():
		var man: Variant = d.lamps[i]
		if MissionDirector._alive(man) and not originals.has(man) and d.marked.has(man):
			fresh_round = i
	t.check(fresh_round >= 0 and rounds.has(fresh_round), "the new man took a stranded man's round (round %d; stranded rounds %s)" % [fresh_round, rounds])
	_done(s)
