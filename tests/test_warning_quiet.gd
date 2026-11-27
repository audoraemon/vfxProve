extends RefCounted
## The Warning rework, T4 (spec 4; gates G2, G3, G4): the three posts are quiet while their watchmen hold them. StarfallDirector._quiet_posts() moves the
## soldiers and the idle citizens out of each ring and holds them (and the gate checkers), _hush_step() turns away the rest, and a post let go gives its
## men back. G3: nobody but the watchman within witness reach of a held watchman, at seeds 1-3, DAY and NIGHT, every 0.25 s up to each set-off, and
## through the kill sequences. G2: no starter's reach takes two watchmen. G4: three kills at the posts (Smite, Death Mark, Breath) stop all three,
## unseen: the town never reaches Local Emergency, and the night is won.

const DT := 0.05
const SAMPLE_EVERY := 5
const STARTERS := ["smite", "ember", "deathmark", "raise", "doom", "blight", "skylift", "windfall", "noleave", "breath", "whisper", "discord"]
const ClarityKit := preload("res://tests/clarity_kit.gd")

static var _frame := 0


static func run(t) -> void:
	_g2(t)
	_g3(t)
	_g4(t)
	_release(t)
	_teardown_loss(t)
	_loop_men(t)
	_wish_keepout(t)
	_off_the_board(t)
	Person.frame_no = -1


## The board's Warning as the game builds it: the wishes heard first (their people and places reserved), the director set up, NightRules applied --
## all before the first step.
static func _world(seed_value: int, look: int, city := &"aldermere") -> Dictionary:
	City.use(city)
	var def := TierBook.board("warning")
	if city != &"aldermere":
		def = MissionBook.in_city(def, city)  # the Capital's own posts, times and overrides (as test_capital_starfall builds it)
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	town.look = look
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = City.current().map()
	var node := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, node, seed_value)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	var director := def.make_director()
	var descent := Descent.new().setup(def, Descent.seed_for(seed_value, "warning"))
	descent.reserve(rules, director)
	director.setup(rules, crowd, town, null)
	rules.director = director
	var kept: Array = director.reserved.duplicate()
	NightRules.apply(crowd, look, kept, seed_value, director)
	return {"env": env, "town": town, "field": field, "world": node, "crowd": crowd, "rules": rules, "d": director, "banners": banners, "descent": descent}


## One step of the night as the game takes it: the crowd, its people, the rules.
static func _step(s: Dictionary) -> void:
	_frame += 1
	Person.frame_no = _frame  # the frames advance as in play: the people's LOD staggers by them, never by this process's instance ids
	(s.crowd as Crowd).advance(DT)
	(s.crowd as Crowd).step_people(DT)
	(s.rules as Rules).advance(DT)


## Who stands within witness reach of a held watchman now: "who (role) at (x, y) d from post i at mission second". Empty when the posts are quiet.
static func _breaches(s: Dictionary, secs: float) -> Array[String]:
	var out: Array[String] = []
	var d: StarfallDirector = s.d
	var crowd: Crowd = s.crowd
	for i in d.posts_held():
		var w: Person = d.stars[i].watchman
		for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
			for p in group:
				if not is_instance_valid(p) or p == w or not p.is_alive() or p.inside:
					continue
				var gap := p.ground_pos.distance_to(w.ground_pos)
				if gap <= crowd.witness_reach(p, true):
					out.append("%s %s%s at %s, %.2f from watchman %d, mind %s, at %.2f s" % ["soldier" if p.soldier else "citizen", "(reserved) " if (s.d as MissionDirector).reserved.has(p) else "",
						str(p.get_instance_id()), p.ground_pos, gap, i, Person.Mind.keys()[p.mind], secs])
	return out


static func _done(s: Dictionary) -> void:
	ClarityKit.done(s)


## G2: no starter's take radius reaches two watchmen, taking each post's centre (the gap between the Postern and the Main Gate is the least).
static func _g2(t) -> void:
	var gap := INF
	var spots: Array[Vector2] = []
	for st: Array in StarfallDirector.STARS:
		spots.append(st[1])
	for i in spots.size():
		for j in range(i + 1, spots.size()):
			gap = minf(gap, spots[i].distance_to(spots[j]))
	var worst := 0.0
	var wide := ""
	for key in STARTERS:
		var r := 3.0 if key == "raise" else Crowd._cast_radius(key)  # Raise takes bodies within 3; its zombies hunt further, a kill, not a cast radius
		if r > worst:
			worst = r
			wide = key
	t.check(gap > 8.0, "the posts stand more than 8 apart (%.2f)" % gap)
	t.check(worst + DirectorWhy.MARGIN < gap, "no starter's reach (the widest: %s, %.2f, plus the why-not margin) takes two watchmen (gap %.2f)" % [wide, worst, gap])
	var two := 0
	for key in STARTERS:
		var r := 3.0 if key == "raise" else Crowd._cast_radius(key)
		for c in spots:
			var inside := 0
			for sp in spots:
				inside += 1 if sp.distance_to(c) <= r else 0
			two += 1 if inside > 1 else 0
	t.check(two == 0, "centred on each watchman, every starter's reach holds only him (%d breaches)" % two)


## A stand-in for MissionDirector.WHY_MARGIN, so a test reads the same number the why-not banners add.
class DirectorWhy:
	const MARGIN := MissionDirector.WHY_MARGIN


## G3: at seeds 1-3, DAY and NIGHT, nobody but a watchman is within witness reach of any held watchman, sampled every 0.25 s until the last set-off.
static func _g3(t) -> void:
	for look in [Town.Look.DAY, Town.Look.NIGHT]:
		for seed_value in [1, 2, 3]:
			_g3_world(t, _world(seed_value, look), "seed %d, %s" % [seed_value, "DAY" if look == Town.Look.DAY else "NIGHT"])
	# The Capital's posts too (its own ground and walls): one seed, as the board plays it there.
	_g3_world(t, _world(1, Town.Look.DAY, &"capital"), "Capital, seed 1, DAY")
	City.use(&"aldermere")


## One G3 world: the three posts held from the first frames, sampled every 0.25 s up to the last set-off, and no one within witness reach of a held watchman.
static func _g3_world(t, s: Dictionary, label: String) -> void:
	var d: StarfallDirector = s.d
	var steps := roundi((float(StarfallDirector.STARS[2][0]) + 0.5) / DT)
	var seen: Array[String] = []
	var held_all := true
	var samples := 0
	for k in steps:
		_step(s)
		if k % SAMPLE_EVERY == 0 and not d.posts_held().is_empty():
			samples += 1
			seen.append_array(_breaches(s, float(k) * DT))
		if k == 2:
			held_all = held_all and d.posts_held().size() == 3
	t.check(held_all and samples > 100, "%s: the three posts were held from the first frames and sampled (%d samples)" % [label, samples])
	t.check(seen.is_empty(), "%s: no one but the watchman within witness reach of a held post: %s" % [label, "; ".join(seen.slice(0, 6))])
	_done(s)


## G4: three kills at the posts stop all three unseen, at seeds 1-3 and through each kill's aftermath the later posts stay quiet. Smite, Death Mark and
## Breath (a kill by the key, as the test world has no cell) in turn.
static func _g4(t) -> void:
	for key in ["smite", "deathmark", "breath"]:
		for seed_value in [1, 2, 3]:
			var s := _world(seed_value, Town.Look.NIGHT if seed_value % 2 == 0 else Town.Look.DAY)
			var d: StarfallDirector = s.d
			var rules: Rules = s.rules
			var crowd: Crowd = s.crowd
			for k in roundi(2.0 / DT):
				_step(s)
			var seen: Array[String] = []
			var t_now := 2.0
			var killed := 0
			for i in 3:
				seen.append_array(_breaches(s, t_now))
				var w: Person = d.stars[i].watchman
				if is_instance_valid(w) and w.is_alive():
					ClarityKit.apply(s, "kill", w, key)
				for k in roundi(2.0 / DT):
					_step(s)
					t_now += DT
					if k % SAMPLE_EVERY == 0:
						seen.append_array(_breaches(s, t_now))
				killed += 1 if d.stars[i].warning_dead and d.stars[i].stopped_how == "kill" else 0
			var label := "%s, seed %d" % [key, seed_value]
			t.check(killed == 3 and d.stopped() == 3, "%s: three kills at their posts, three warnings stopped by a kill (%d, %d)" % [label, killed, d.stopped()])
			t.check(rules.finished and rules.won, "%s: the night is won" % label)
			t.check(crowd.alarms.stage < AlarmManager.Stage.LOCAL_EMERGENCY, "%s: the town never reaches Local Emergency (stage %d)" % [label, crowd.alarms.stage])
			t.check(crowd.bell.state == BellNetwork.State.IDLE, "%s: the bell never rang" % label)
			t.check(seen.is_empty(), "%s: no witness at any later kill: %s" % [label, "; ".join(seen.slice(0, 6))])
			_done(s)


## The release (B2): after a set-off the moved soldiers are no longer held, their `post` is their town post again, no town job takes them for a mission
## man; the two other posts stay held until their own set-offs.
## Every soldier the director holds now, added to `seen` (each quarter second).
static func _note(d: StarfallDirector, seen: Dictionary, k: int) -> void:
	if k % SAMPLE_EVERY != 0:
		return
	for p: Variant in d._men.keys():
		seen[p] = true


static func _release(t) -> void:
	var s := _world(1, Town.Look.DAY)
	var d: StarfallDirector = s.d
	var crowd: Crowd = s.crowd
	_step(s)
	var moved: Array[Person] = []
	var held_for := {}
	for p: Variant in d._men.keys():
		var rec: Dictionary = d._men[p]
		held_for[p] = int(rec.post)
		if bool(rec.moved):
			moved.append(p as Person)
	t.check(moved.size() >= 2, "post 0's ring had soldiers to move (%d moved of %d held)" % [moved.size(), d._men.size()])
	var first: Array[Person] = []
	for p in moved:
		if int(held_for[p]) <= 1:
			first.append(p)
	var all_men := {}  # every soldier ever held: at setup, moved or not, and those the hush takes in play after each set-off
	for p: Variant in held_for.keys():
		all_men[p] = true
	var all_held := true
	var off_town := true
	for p in moved:
		all_held = all_held and d.busy(p) and crowd.held_by_mission(p)
		off_town = off_town and not p.post.is_equal_approx(p.town_post) and p.town_post != Vector2.INF or p.town_post == Vector2.INF
	t.check(all_held, "every moved soldier is held by the director (busy, held_by_mission)")
	t.check(off_town, "a moved soldier's `post` is his new spot, never his `town_post`")
	var first_men: Array = []
	for p: Variant in held_for.keys():
		if int(held_for[p]) == 0:
			(d._men[p] as Dictionary)["far"] = true  # a far-seeing checker's sight, stored as the hold took it
			first_men.append(p)
	for k in roundi((float(StarfallDirector.STARS[0][0]) + 0.5) / DT):
		_step(s)
		_note(d, all_men, k)
	var sight_back := true
	var freed := 0
	for p: Variant in first_men:
		if is_instance_valid(p) and (p as Person).is_alive() and not d._men.has(p):
			freed += 1
			sight_back = sight_back and (p as Person).watch_far and not (p as Person).post_held
	t.check(freed > 0 and sight_back, "a post freed mid-night gives its men their sight back and the loop's hand (%d freed)" % freed)
	t.check(not d.stars[0].at_post() and not d.posts_held().has(0) and d.posts_held().has(1) and d.posts_held().has(2),
		"after the first set-off post 0 is let go and the other two stay held (%s)" % [d.posts_held()])
	var later := d._men.size()
	for k in roundi((float(StarfallDirector.STARS[2][0]) - float(StarfallDirector.STARS[0][0]) + 1.0) / DT):
		_step(s)  # past the last set-off: every post is let go
		_note(d, all_men, k)
	t.check(d.posts_held().is_empty() and d._men.is_empty(), "after the last set-off no post is held and the director holds no soldier (%d held)" % d._men.size())
	t.check(later > 0, "the other posts' men were still held after the first set-off")
	# The release is about FIELDS (GateCheck and GuardJobs read `post == town_post`), never about where a man stands.
	var bad: Array[String] = []
	var bad_patrol: Array[String] = []
	var counted := 0
	for p: Variant in all_men.keys():
		if not is_instance_valid(p) or not (p as Person).is_alive():
			continue
		var m := p as Person
		counted += 1
		var why := ""
		if m.town_post != Vector2.INF and not m.post.is_equal_approx(m.town_post):
			why += " post %s != town_post %s;" % [m.post, m.town_post]
		if d.busy(m) or crowd.held_by_mission(m):
			why += " still held;"
		if m.post_group >= 0 and m.corps == Person.Corps.NONE and crowd.guard_jobs.mission_man(m):
			why += " a mission man to GuardJobs;"
		if why != "":
			(bad_patrol if m.post_group == 3 else bad).append("%s (group %d, corps %d)%s" % [str(m.get_instance_id()), m.post_group, m.corps, why])
	t.check(counted >= 6 and bad.is_empty(), "every held or moved soldier (%d) has `post == town_post` again and is no town job's mission man: %s" % [counted, "; ".join(bad)])
	t.check(bad_patrol.is_empty(), "a patrol man has his loop back too (post == town_post, not held): %s" % "; ".join(bad_patrol))
	var patrol: Person = null
	for p: Variant in all_men.keys():
		if is_instance_valid(p) and (p as Person).is_alive() and (p as Person).post_group == 3 and (p as Person).corps == Person.Corps.NONE:
			patrol = p as Person
			break
	t.check(patrol != null, "a patrol man was held at some post")
	if patrol != null:
		var seen_at: Array[Vector2] = []
		for k in roundi(40.0 / DT):
			_step(s)
			if k % 20 == 0:
				seen_at.append(patrol.ground_pos)
		var reach := 0.0
		for v in seen_at:
			reach = maxf(reach, v.distance_to(seen_at[0]))
		t.check(reach > 1.0, "a released patrol man walks his beat again (he went %.1f from where he stood over 40 s)" % reach)
	_done(s)


## A night lost while the posts are still held (the Lantern, say), then the director's teardown: every held man is let go -- each soldier has `post == town_post`
## and his sight back, each re-anchored citizen his own anchor, no watchman still has a 999 s stay -- and the wishes' keep-out is cleared.
static func _teardown_loss(t) -> void:
	var s := _world(1, Town.Look.DAY)
	var d: StarfallDirector = s.d
	var crowd: Crowd = s.crowd
	var rules: Rules = s.rules
	for k in roundi(2.0 / DT):
		_step(s)
	var held := d.posts_held().size()
	var men: Array = d._men.keys()
	var folk := {}
	for p: Variant in d._folk.keys():
		folk[p] = (d._folk[p] as Dictionary).was
	var far := {}
	for p: Variant in men:
		far[p] = bool((d._men[p] as Dictionary).get("far", false))
	t.check(held == 3 and men.size() > 6 and not folk.is_empty(), "before the loss three posts are held with men (%d) and folk (%d) moved" % [men.size(), folk.size()])
	var stays := 0
	for w in d.stars:
		stays += 1 if w.watchman.stay_left >= NightRules.HOLD_STAY else 0
	t.check(stays == 3, "each watchman holds his post with a stay of %.0f s (%d)" % [NightRules.HOLD_STAY, stays])
	var seeded: Person = men[0] as Person
	(d._men[seeded] as Dictionary)["far"] = true  # a far-seeing checker's sight, stored as the hold took it
	far[seeded] = true
	t.check(crowd.wish_keepout.size() == 3, "before the teardown three rings are kept out of the wishes")
	rules.finished = true  # the night is lost with every post still held
	rules.won = false
	_step(s)
	d.teardown()
	var bad: Array[String] = []
	for p: Variant in men:
		if not is_instance_valid(p) or not (p as Person).is_alive():
			continue
		var m := p as Person
		if m.town_post != Vector2.INF and not m.post.is_equal_approx(m.town_post):
			bad.append("post %s != town_post %s" % [m.post, m.town_post])
		if d.busy(m) or crowd.held_by_mission(m):
			bad.append("still held")
		if m.post_held:
			bad.append("still flagged held")
		if m.watch_far != bool(far[p]):
			bad.append("sight %s, was %s" % [m.watch_far, far[p]])
	for p: Variant in folk.keys():
		if is_instance_valid(p) and (p as Person).is_alive() and not (p as Person).anchor.is_equal_approx(folk[p]):
			bad.append("anchor %s, was %s" % [(p as Person).anchor, folk[p]])
	for w in d.stars:
		if w.watchman.stay_left >= NightRules.HOLD_STAY:
			bad.append("a watchman's stay_left is %.0f" % w.watchman.stay_left)
	t.check(bad.is_empty(), "after the teardown every held man is released (%d men, %d folk): %s" % [men.size(), folk.size(), "; ".join(bad.slice(0, 5))])
	t.check(d._men.is_empty() and d._folk.is_empty() and d._turned.is_empty() and crowd.wish_keepout.is_empty(), "and the director keeps no man, no anchor, no turn and no keep-out")
	_done(s)


## A wall-loop man another director (or a wish) holds still walks the loop; one the board Warning holds at a post does not.
static func _loop_men(t) -> void:
	var s := _world(1, Town.Look.DAY, &"capital")
	var crowd: Crowd = s.crowd
	crowd.mission_holds.append(func(_p: Person) -> bool: return true)  # every man held by some other director
	var rows: Array = []
	for e in crowd._loops:
		if is_instance_valid(e[0]) and rows.size() < 40:
			rows.append(e)
	t.check(not rows.is_empty(), "the town has wall-loop men")
	var before: Array = rows.map(func(e: Array) -> int: return int(e[2]))
	var kept := rows.duplicate()
	for e in rows:
		(e[0] as Person).post_held = false
	for k in roundi(120.0 / DT):
		_step(s)
	var moved := 0
	for i in rows.size():
		moved += 1 if int(rows[i][2]) != int(before[i]) else 0
	t.check(moved > 0, "loop men held by another director still walk their loop (%d of %d moved on)" % [moved, rows.size()])
	_done(s)
	s = _world(1, Town.Look.DAY, &"capital")
	crowd = s.crowd
	rows.clear()
	for e in crowd._loops:
		if is_instance_valid(e[0]):
			rows.append(e)
			(e[0] as Person).post_held = true
	before = rows.map(func(e: Array) -> int: return int(e[2]))
	for k in roundi(15.0 / DT):
		_step(s)
	moved = 0
	for i in rows.size():
		moved += 1 if int(rows[i][2]) != int(before[i]) else 0
	t.check(not rows.is_empty() and moved == 0, "loop men the board Warning holds stay put (%d moved)" % moved)
	_done(s)
	City.use(&"aldermere")


## I9: no wisher or wish target is picked from within a post's ring (Crowd.wish_keepout), and no other mission sets one.
static func _wish_keepout(t) -> void:
	var bad := 0
	for seed_value in [1, 2, 3, 4, 5, 6]:
		var s := _world(seed_value, Town.Look.DAY)
		var crowd: Crowd = s.crowd
		for w: Wish in (s.descent as Descent).wishes:
			for p in w.people():
				for k in crowd.wish_keepout:
					bad += 1 if p.ground_pos.distance_to(Vector2(k.x, k.y)) <= k.z else 0
		_done(s)
	t.check(bad == 0, "no wisher or wish target stood in a ring when the wishes were heard (%d)" % bad)
	var s := _world(1, Town.Look.DAY)
	t.check((s.crowd as Crowd).wish_keepout.size() == 3, "three rings are kept out of the wishes")
	_done(s)
	var plain := Crowd.new()
	t.check(plain.wish_keepout.is_empty(), "a crowd has no kept-out places unless the Warning names them")
	plain.free()
	t.check(MissionBook.warning().make_director().wish_keepout().is_empty(), "the single-star Warning names none")


## The single-star Warning and every town but the board's hush nobody: no director holds a soldier and nothing is moved.
static func _off_the_board(t) -> void:
	var s := ClarityKit.world(MissionBook.warning(), null)
	var crowd: Crowd = s.crowd
	var before := {}
	for p in crowd.soldiers:
		before[p] = p.post.is_equal_approx(p.town_post)
	for k in roundi(5.0 / DT):
		crowd.advance(DT)
		(s.rules as Rules).advance(DT)
	var same := true
	for p in crowd.soldiers:
		same = same and (not before[p] or p.post.is_equal_approx(p.town_post))
	t.check(same, "the single-star Warning moves no soldier's post")
	t.check(not (s.d as MissionDirector).busy(crowd.soldiers[0]), "and holds none")
	_done(s)
