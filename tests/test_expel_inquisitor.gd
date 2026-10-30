extends RefCounted
## God P5 Task 6 (plan Task 6, MS §4, Rulings C5, C9): Hunt 3, Expel the inquisitor (ExpelInquisitorDirector, an AssassinateDirector): three
## lantern-wardens on looping rounds each with a guard, then the captain with two, who three frights drive out of Aldermere. Tested in the
## Tax Collector's world (bodies do not walk: a test puts a walker down at his goal with arrive()): the setup, the chain, a warden's looping
## round, the fright count, the third fright, the walls, the Temple down (no one flees to the Citadel), the captain's countdown, the win before the
## loss, a freed body, the tags and the town's evacuation. Every test builds and frees its own world (Kit.world(), Kit.done()).

const Kit := preload("res://tests/test_tier2_groundwork.gd")
const DT := 0.05
## Seconds after the captain changes state (leaves a door, goes in) before the guards' places are read: they walk from the door ring to his heels.
const SETTLE := 8.0
const STOP_SETTLE := 2.0
const State := AssassinateDirector.State
const HUNT := preload("res://tools/dev/routes/god_hunts/expel_inquisitor.gd")
const GodHunts := preload("res://tools/dev/routes/god_hunts.gd")


static func run(t) -> void:
	_frame(t)
	_setup(t)
	_chain(t)
	_round_loops(t)
	_fright_count(t)
	_third_fright(t)
	_out_of_walls(t)
	_no_citadel_flight(t)
	_captain_safe(t)
	_eta_true(t)
	_eta_once(t)
	_policies(t)
	_door_policies(t)
	_guards_walk(t)
	_win_beats_loss(t)
	_lost_body(t)
	_tags(t)
	_camera(t)
	_hold(t)
	_evacuation(t)
	_wishes(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.expel_inquisitor())


static func _ei(s: Dictionary) -> ExpelInquisitorDirector:
	return s.d as ExpelInquisitorDirector


## Everyone but `who` within 3 units moved well away, so a death there has no witness.
static func _clear_round(crowd: Crowd, who: Person) -> void:
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and p != who and p.ground_pos.distance_to(who.ground_pos) <= 3.0:
				p.ground_pos = who.ground_pos + Vector2(12.0, 0.0)


## `q` is sent out on his round now and set down in the street at his first leg's door, as his walk would have brought him.
static func _out(d: ExpelInquisitorDirector, q: AssassinateDirector.Quarry) -> void:
	d._set_out(q)
	Kit.arrive(q.target, d.hide_door if d._is_captain(q) else q.stop_doors[0])


## `q` killed where he stands (a Silent Doom's death in the field).
static func _kill(s: Dictionary, q: AssassinateDirector.Quarry) -> void:
	_clear_round(s.crowd, q.target)
	(s.crowd as Crowd)._field.kill(q.target, &"doom")
	Kit.run_for(s, DT)


## `q` is walking and then arrives at the door of his stop `leg`.
static func _walk_to(s: Dictionary, q: AssassinateDirector.Quarry, door: Vector2) -> void:
	Kit.arrive(q.target, door)
	Kit.run_for(s, AssassinateDirector.TICK + DT)


static func _frame(t) -> void:
	var m := MissionBook.expel_inquisitor()
	t.check(m.director == ExpelInquisitorDirector and m.lantern == LanternWatch.KIND_WATCH and m.tier == 3 and m.make_director() is ExpelInquisitorDirector,
		"the frame builds the Hunt's director, a Tier 3 night with the watch Lantern")
	var objectives: Array = m.make_objectives.call()
	t.check(objectives.size() == 2 and objectives[0] is AssassinateObjective and objectives[0].label == "Expel the inquisitor"
		and objectives[1] is ClockObjective, "the Assassinate objective runs ahead of the dawn: the winning strike never also loses")
	t.check(m.goal == "Stop his three wardens, then kill the captain or drive him out of the town" and m.goal_label == "The inquisitor is gone"
		and m.lose == "The captain reaches the Citadel, or dawn comes", "the goal, label and lose are the spec's")
	t.check(MissionHints.line("expel_inquisitor") == "Stop each lantern-warden (gold): kill him, or put him out of the walls."
		and MissionHints.line("expel_inquisitor", "captain") == "The captain walks his rounds: kill him, or frighten him three times."
		and MissionHints.line("expel_inquisitor", "near") == "The captain nears the Citadel: stop him now.", "the three hints")
	t.check(m.camera_at == ExpelInquisitorDirector.EI_CAMERA_AT and m.intro_from == m.camera_at + Vector2(0.0, 6.0), "the camera is the director's")
	# C2: no parent const name is redeclared (a parse error otherwise); the Hunt's numbers carry its prefix.
	var own := (ExpelInquisitorDirector as GDScript).get_script_constant_map()
	var prefixed := true
	for k: String in own.keys():
		prefixed = prefixed and k.begins_with("EI_")
	t.check(prefixed, "every const of the Hunt carries the EI_ prefix (C2)")


static func _setup(t) -> void:
	var s := _world()
	var d := _ei(s)
	var rules: Rules = s.rules
	t.check(d.quarries.size() == 4 and d.hideout != null and d.hideout.role == &"temple" and d.safe_at.distance_to(Places.point(&"citadel_gate")) < 0.01
		and d.walls_stop and not d.smoke_out, "three wardens and the captain; the Temple the hideout, the Citadel's gate the safe place; walls stop, no smoke-out")
	t.check((s.banners as Array).has("EXPEL THE INQUISITOR"), "the opening banner (%s)" % [s.banners])
	var guards := [1, 1, 1, 2]
	var ok := true
	var everyone: Array = []
	for q in d.quarries:
		ok = ok and q.target != null and q.target.inside and q.guards.size() == guards[q.index] and q.stops.size() == 4
		everyone.append(q.target)
		everyone.append_array(q.guards)
		for g in q.guards:
			ok = ok and g.soldier and g.is_alive()
	t.check(ok, "each target is indoors, with 1, 1, 1 and 2 guards (soldiers) and four stops")
	var distinct := true
	for i in everyone.size():
		for j in range(i + 1, everyone.size()):
			distinct = distinct and everyone[i] != everyone[j]
	t.check(distinct, "all eleven people are different")
	for i in 3:
		var q := d.quarries[i]
		t.check(q.target.profile.role == CitizenProfile.Role.WATCHMAN and q.inside_of == q.stops[0] and q.state == State.WAITING
			and q.target.ground_pos.distance_to(q.stops[0].center()) < 0.01, "warden %d waits inside the first house of his round, a watchman for the night" % i)
	var cap := d.captain()
	t.check(cap != null and cap.inside_of == d.hideout and cap.target.profile.role == CitizenProfile.Role.CLERGY, "the captain waits in the Temple, a cleric")
	var houses: Array = []
	var apart := true
	for q in d.quarries:
		for st in q.stops:
			apart = apart and not houses.has(st) and st != d.hideout
			houses.append(st)
	t.check(apart, "no house is in two rounds, none is the Temple")
	# Opposition stands more than 1.6 apart (MS §0): every guard's post from every other's.
	var guard_posts: Array = []
	for q in d.quarries:
		for g in q.guards:
			guard_posts.append(g.anchor)
	var far := true
	var min_gap := INF
	for i in guard_posts.size():
		for j in range(i + 1, guard_posts.size()):
			var gap: float = guard_posts[i].distance_to(guard_posts[j])
			min_gap = minf(min_gap, gap)
			far = far and gap > 2.0 * SilentDoom.RADIUS
	t.check(far, "no two guards post within two Silent Doom radii of each other (closest %.2f)" % min_gap)
	t.check(d.out_at(0) == 44.0 and d.out_at(1) == 94.0 and d.out_at(2) == 144.0 and d.out_at(3) == 190.0, "set-out times 0:44, 1:34, 2:24 and 3:10 (%s)"
		% [[d.out_at(0), d.out_at(1), d.out_at(2), d.out_at(3)]])
	var labels := Kit.labels(d)
	t.check(labels.has("WARDEN OUT IN 0:44") and labels.has("WARDEN OUT IN 1:34") and labels.has("WARDEN OUT IN 2:24") and labels.has("CAPTAIN OUT IN 3:10")
		and labels.has("CITADEL"), "the grey countdowns and the Citadel are tagged at the start (%s)" % [labels])
	t.check(d.hint_phase() == "" and d.frights() == 0 and not d.fled() and d.captain_eta() == INF and d.strip_rows().is_empty(), "the hint is the mission's; no fright, no row")
	t.check(rules.objectives[0].hud_text(rules) == "Expel the inquisitor: 0 / 4", "the HUD counts the four (%s)" % rules.objectives[0].hud_text(rules))
	var tour := d.tour()
	t.check(tour.size() == 3 and d.hide_door != Vector2.INF, "a tour of three stops")
	Kit.done(s)


static func _chain(t) -> void:
	var s := _world()
	var d := _ei(s)
	var wait := ExpelInquisitorDirector.EI_CHAIN
	Kit.run_for(s, 45.0)
	t.check(d.quarries[0].state == State.WALKING and (s.banners as Array).has("A WARDEN SETS OUT") and d.quarries[1].state == State.WAITING,
		"0:44: the first warden sets out, the others wait")
	t.check(d.quarries[0].leg == 1, "he is bound for the second stop of his round (he has stood in the first)")
	Kit.arrive(d.quarries[0].target, d.quarries[0].stop_doors[0])
	_kill(s, d.quarries[0])
	var died := d.quarries[0].died_at
	t.check(is_equal_approx(d.out_at(1), minf(94.0, died + wait)) and d.out_at(1) <= 94.0 and d.out_at(1) - died <= wait + 0.01,
		"the first warden stopped: the next is due by the chain (%.1f; stopped %.1f)" % [d.out_at(1), died])
	t.check(d.out_at(2) == 144.0, "the third keeps his time while the second lives")
	_out(d, d.quarries[1])
	_kill(s, d.quarries[1])
	t.check(d.out_at(2) <= d.quarries[1].died_at + wait + 0.01, "and after the second, the third is due within 45 s")
	_out(d, d.quarries[2])
	_kill(s, d.quarries[2])
	var d3 := d.quarries[2].died_at
	t.check(d.out_at(3) <= d3 + wait + 0.01 and d.out_at(3) <= 190.0, "the third warden stopped: the captain follows within 45 s or at 3:10 (%.1f)" % d.out_at(3))
	Kit.run_for(s, wait + 1.0)
	t.check(d.captain().state == State.WALKING and (s.banners as Array).has("THE CAPTAIN SETS OUT"), "and sets out then")
	Kit.done(s)

	# With no one stopped the captain comes at 3:10 and not before.
	var n := _world()
	var dn := _ei(n)
	Kit.run_for(n, 189.0)
	t.check(dn.captain().state == State.WAITING and dn.captain_out_in() > 0.0, "3:09: the captain still waits")
	Kit.run_for(n, 2.0)
	t.check(dn.captain().state == State.WALKING and dn.captain_out_in() == 0.0, "3:11: he is out")
	Kit.done(n)


static func _round_loops(t) -> void:
	var s := _world()
	var d := _ei(s)
	var q := d.quarries[0]
	var visit := ExpelInquisitorDirector.EI_VISIT
	d._set_out(q)
	t.check(not q.target.inside and q.target.mind == Person.Mind.DUTY and q.target.goal().distance_to(q.stop_doors[1]) < 0.5,
		"he comes out of his own door and walks to the second stop")
	var visits := 0
	# Walk the round twice over: stops 2, 3, 0, 1, 2, 3, 0, 1, ...
	var order := [1, 2, 3, 0, 1, 2, 3, 0]
	var good := true
	for k in order.size():
		var i: int = order[k]
		good = good and q.state == State.WALKING and q.target.goal().distance_to(q.stop_doors[i]) < 0.5
		_walk_to(s, q, q.stop_doors[i])
		good = good and q.state == State.VISITING and q.target.inside and q.leg == i
		Kit.run_for(s, visit + AssassinateDirector.TICK + DT)
		visits += 1
		good = good and q.state == State.WALKING and not q.target.inside
	t.check(good and visits == 8, "he visits his four stops and goes round again, twice (a visit is %d s indoors)" % roundi(visit))
	t.check(q.target.goal().distance_to(d.safe_at) > 3.0 and not d.any_safe() and q.state != State.SAFE, "his goal is never the Citadel's gate: a warden has no safe place")
	Kit.done(s)

	# A stop's house brought down is skipped, and the round goes on.
	var f := _world()
	var df := _ei(f)
	var qf := df.quarries[1]
	df._set_out(qf)
	qf.stops[1].destroy(qf.stops[1].center(), &"fire")
	_walk_to(f, qf, qf.stop_doors[1])
	Kit.run_for(f, AssassinateDirector.TICK + DT)
	t.check(qf.state == State.WALKING and qf.leg == 2 and qf.target.goal().distance_to(qf.stop_doors[2]) < 0.5, "a fallen stop is skipped")
	Kit.done(f)


static func _fright_count(t) -> void:
	var s := _world()
	var d := _ei(s)
	var cap := d.captain()
	var gap := ExpelInquisitorDirector.EI_FRIGHT_GAP
	_out(d, cap)
	t.check(cap.state == State.WALKING, "(set-up) the captain walks")
	# A loud cast within 4 of him while he walks: one fright; he makes for the Temple.
	d._on_danger("smite", [cap.target.ground_pos + Vector2(1.0, 0.0)] as Array[Vector2])
	t.check(d.frights() == 1 and cap.state == State.FLEEING and cap.target.goal().distance_to(d.hide_door) < 0.5 and (s.banners as Array).has("THE CAPTAIN HIDES"),
		"a loud cast near him: shaken 1/3, and he makes for the Temple (%d, %s)" % [d.frights(), State.keys()[cap.state]])
	# While he flees, a second alarm does not count (the base acts only while he walks).
	d._on_danger("smite", [cap.target.ground_pos] as Array[Vector2])
	t.check(d.frights() == 1, "while he flees, a loud cast counts nothing")
	_walk_to(s, cap, d.hide_door)
	t.check(cap.state == State.HIDING and cap.target.inside and cap.inside_of == d.hideout, "he hides in the Temple")
	d._alarm(cap)
	d._on_danger("smite", [cap.target.ground_pos] as Array[Vector2])
	t.check(d.frights() == 1, "while he hides, nothing counts")
	# Out of hiding, an alarm inside the gap: he hides again, but it is not counted.
	Kit.run_for(s, ExpelInquisitorDirector.EI_HIDE + AssassinateDirector.TICK + DT)
	t.check(cap.state == State.WALKING and not cap.target.inside, "(set-up) out of hiding he walks on")
	d._fright_wait = gap - 1.0
	d._alarm(cap)
	t.check(d.frights() == 1 and cap.state == State.FLEEING, "a second alarm within %d s sends him to hide but is not counted (%d)" % [roundi(gap), d.frights()])
	_walk_to(s, cap, d.hide_door)
	Kit.run_for(s, ExpelInquisitorDirector.EI_HIDE + AssassinateDirector.TICK + DT)
	# A guard felled counts once the gap is over.
	d._fright_wait = 0.0
	cap.guard_fell = true
	d._tick(cap)
	t.check(d.frights() == 2 and cap.state == State.FLEEING and (s.banners as Array).has("THE CAPTAIN HIDES"), "a guard of his felled, a gap later: shaken 2/3")
	t.check(d.report().frights == 2, "the report counts two")
	Kit.done(s)

	# The tag reads the count.
	var u := _world()
	var du := _ei(u)
	_out(du, du.captain())
	du._on_danger("nova", [du.captain().target.ground_pos] as Array[Vector2])
	du.captain().state = State.WALKING
	t.check(Kit.labels(du).has("CAPTAIN - SHAKEN 1/3") and Kit.edged(du, "CAPTAIN - SHAKEN 1/3"), "out in the street he reads shaken 1/3, pointed at (%s)" % [Kit.labels(du)])
	Kit.done(u)

	# A warden alarmed hides without any count.
	var w := _world()
	var dw := _ei(w)
	var qw := dw.quarries[0]
	_out(dw, qw)
	dw._on_danger("smite", [qw.target.ground_pos] as Array[Vector2])
	t.check(dw.frights() == 0 and qw.state == State.FLEEING and (w.banners as Array).has("A WARDEN HIDES"), "a warden alarmed hides; only the captain's alarms are counted")
	Kit.done(w)


static func _third_fright(t) -> void:
	var s := _world()
	var d := _ei(s)
	var rules: Rules = s.rules
	var cap := d.captain()
	_out(d, cap)
	for k in 2:
		d._fright_wait = 0.0
		d._alarm(cap)
		_walk_to(s, cap, d.hide_door)
		Kit.run_for(s, ExpelInquisitorDirector.EI_HIDE + AssassinateDirector.TICK + DT)
		t.check(cap.state == State.WALKING, "(set-up) fright %d, hidden, out again" % (k + 1))
	t.check(d.frights() == 2 and not d.fled(), "(set-up) shaken 2/3")
	d._fright_wait = 0.0
	d._alarm(cap)
	t.check(d.frights() == 3 and d.fled() and cap.state == State.OUT and cap.died_at >= 0.0 and d.stopped() == 1 and d.killed() == 0 and d.out_count() == 1,
		"the third: he is stopped at once, counted with the dead, not killed")
	t.check((s.banners as Array).has("THE CAPTAIN FLEES ALDERMERE") and not (s.banners as Array).has("THE CAPTAIN REACHES THE CITADEL"),
		"THE CAPTAIN FLEES ALDERMERE (%s)" % [s.banners])
	t.check(d.is_leaving(cap.target) and not d.any_safe(), "and he is sent off the map, never safe")
	t.check(String(d.report().target) == "alive" and d.report().fled == true and d.report().frights == 3, "the report: fled after three frights")
	# The wardens still count: stop them for the win.
	t.check(rules.objectives[0].check(rules) == Objective.Status.PENDING, "the captain gone, the wardens still stand: the night goes on")
	for i in 3:
		_out(d, d.quarries[i])
		_kill(s, d.quarries[i])
	Kit.run_for(s, DT)
	t.check(d.all_fallen() and rules.finished and rules.won and rules.over_reason == "expelled", "the three wardens stopped as well: the night is won (%s)" % rules.over_reason)
	Kit.done(s)

	# The same with the wardens stopped first: the third fright wins at once (C9).
	var w := _world()
	var dw := _ei(w)
	for i in 3:
		_out(dw, dw.quarries[i])
		_kill(w, dw.quarries[i])
	var cw := dw.captain()
	_out(dw, cw)
	for k in 2:
		dw._fright_wait = 0.0
		dw._alarm(cw)
		_walk_to(w, cw, dw.hide_door)
		Kit.run_for(w, ExpelInquisitorDirector.EI_HIDE + AssassinateDirector.TICK + DT)
	dw._fright_wait = 0.0
	dw._alarm(cw)
	Kit.run_for(w, DT * 2.0)
	t.check((w.rules as Rules).finished and (w.rules as Rules).won and (w.rules as Rules).over_reason == "expelled",
		"the wardens stopped, the third fright wins at once, reason expelled (%s)" % (w.rules as Rules).over_reason)
	Kit.done(w)


static func _out_of_walls(t) -> void:
	var s := _world()
	var d := _ei(s)
	var q := d.quarries[0]
	_out(d, q)
	var way := Walls.way_off(q.target.ground_pos)
	t.check(way != Vector2.INF, "(set-up) the town has a way off the map")
	# A warden set down past the wall is stopped, not safe.
	q.target.ground_pos = Vector2(-17.5, 0.0)
	Kit.run_for(s, DT * 2.0)
	t.check(q.state == State.OUT and d.stopped() == 1 and d.killed() == 0 and (s.banners as Array).has("A WARDEN LEAVES TOWN") and d.is_leaving(q.target) and not d.any_safe(),
		"a warden out of the walls is stopped, sent off the map, never safe (%s)" % [s.banners])
	var cap := d.captain()
	_out(d, cap)
	cap.target.ground_pos = Vector2(0.5, 17.5)
	Kit.run_for(s, DT * 2.0)
	t.check(cap.state == State.OUT and (s.banners as Array).has("THE CAPTAIN LEAVES ALDERMERE") and d.frights() == 0 and not d.fled() and not d.any_safe(),
		"the captain out of the walls is stopped too, without a fright")
	Kit.done(s)

	# One indoors is not out.
	var f := _world()
	var df := _ei(f)
	Kit.run_for(f, DT * 2.0)
	t.check(df.stopped() == 0, "no one is stopped by waiting")
	Kit.done(f)


static func _no_citadel_flight(t) -> void:
	# The Temple burning, then fallen: the alarmed captain hides in a house of his round, never at the Citadel (Ruling C5).
	var s := _world()
	var d := _ei(s)
	var cap := d.captain()
	_out(d, cap)
	(s.crowd as Crowd).fires.ignite(d.hideout, 0.6)
	Kit.run_for(s, DT * 2.0)
	t.check(not d._hideout_stands(), "(set-up) the Temple burns")
	d._fright_wait = 0.0
	d._alarm(cap)
	var goal: Vector2 = cap.target.goal()
	t.check(cap.state == State.FLEEING and not d.fleeing_to_safe(cap) and goal.distance_to(d.safe_at) > 3.0 and goal.distance_to(d.hide_door) > 1.0,
		"the Temple burning: the alarmed captain makes for a house of his round, not the Citadel (%s)" % [goal])
	var home := d._hide_house(cap)
	t.check(home != null and cap.stops.has(home) and home != d.hideout, "and that house is a standing house of his round")
	_walk_to(s, cap, d._hide_goal(cap))
	t.check(cap.state == State.HIDING and cap.inside_of == home and cap.target.inside and not d.any_safe(), "he hides there")
	t.check(not d.any_safe() and (s.rules as Rules).objectives[0].check(s.rules) == Objective.Status.PENDING, "the objective stays pending")
	Kit.done(s)

	# The Temple fallen too.
	var f := _world()
	var df := _ei(f)
	var cf := df.captain()
	_out(df, cf)
	df.hideout.destroy(df.hideout.center(), &"fire")
	Kit.run_for(f, DT * 2.0)
	df._fright_wait = 0.0
	df._alarm(cf)
	t.check(cf.state == State.FLEEING and not df.fleeing_to_safe(cf) and cf.target.goal().distance_to(df.safe_at) > 3.0 and df._hide_house(cf) != null
		and df._hide_house(cf) != df.hideout, "the Temple down: he still hides in a house of his round")
	# Every house of his round down or burning: he takes his round up again, still not the Citadel.
	for st in cf.stops:
		st.destroy(st.center(), &"fire")
	cf.state = State.WALKING
	df._fright_wait = 0.0
	df._alarm(cf)
	t.check(df._hide_house(cf) == null and cf.state == State.FLEEING and cf.target.goal().distance_to(df.safe_at) > 3.0,
		"with no house left he has no place to hide, and still does not run for the Citadel")
	_walk_to(f, cf, df._hide_goal(cf))
	t.check(not df.any_safe() and cf.state != State.SAFE and cf.state == State.WALKING, "and goes on with his round: not safe (%s)" % State.keys()[cf.state])
	Kit.done(f)

	# A warden hides in his own waiting house; with that house down, in the nearest standing house of his round; never the Temple, never the Citadel.
	var w := _world()
	var dw := _ei(w)
	var qw := dw.quarries[1]
	_out(dw, qw)
	dw._alarm(qw)
	t.check(qw.state == State.FLEEING and dw._hide_house(qw) == qw.stops[0] and dw._hide_goal(qw).distance_to(qw.stop_doors[0]) < 0.5,
		"a warden alarmed makes for his own waiting house (%s %s)" % [State.keys()[qw.state], dw._hide_goal(qw)])
	_walk_to(w, qw, qw.stop_doors[0])
	t.check(qw.state == State.HIDING and qw.inside_of == qw.stops[0] and qw.target.inside, "and hides there")
	Kit.run_for(w, ExpelInquisitorDirector.EI_HIDE + AssassinateDirector.TICK + DT)
	t.check(qw.state == State.WALKING and not qw.target.inside and qw.target.goal().distance_to(qw.stop_doors[qw.leg]) < 0.5, "then takes his round up where he left it")
	qw.stops[0].destroy(qw.stops[0].center(), &"fire")
	Kit.arrive(qw.target, qw.stop_doors[2])
	dw._alarm(qw)
	var spare := dw._hide_house(qw)
	t.check(spare != null and spare != qw.stops[0] and qw.stops.has(spare) and not dw.fleeing_to_safe(qw), "his house down: the nearest standing house of his round")
	t.check(dw.hideout.role == &"temple" and spare != dw.hideout, "never the Temple")
	Kit.done(w)

	# Even a warden past his last stop turns round, never to the Citadel, however long the night runs.
	var l := _world()
	var dl := _ei(l)
	var ql := dl.quarries[2]
	_out(dl, ql)
	ql.leg = ql.stops.size()
	t.check(dl._leg_goal(ql).distance_to(dl.safe_at) > 3.0 and ql.leg == 0, "a warden past his last stop is bound for the first again")
	Kit.done(l)


static func _captain_safe(t) -> void:
	var s := _world()
	var d := _ei(s)
	var rules: Rules = s.rules
	var cap := d.captain()
	_out(d, cap)
	var visit := ExpelInquisitorDirector.EI_VISIT
	var banners: Array = s.banners
	var last := cap.stops.size() - 1
	for i in last:
		t.check(d.captain_eta() == INF and d.strip_rows().is_empty() and d.hint_phase() == "captain", "stop %d: still on his round, no countdown" % (i + 1))
		_walk_to(s, cap, cap.stop_doors[i])
		Kit.run_for(s, visit + AssassinateDirector.TICK + DT)
	t.check(d.captain_eta() == INF and not banners.has("THE CAPTAIN NEARS THE CITADEL"), "on his way to the last stop: no countdown yet")
	# His last visit begins: the countdown, the strip row and the tag show (Ruling P5-T6-R1), with the whole walk ahead of him.
	_walk_to(s, cap, cap.stop_doors[last])
	t.check(cap.state == State.VISITING and cap.leg == last, "(set-up) he is indoors at his last stop")
	var eta := d.captain_eta()
	var rows := d.strip_rows()
	var citadel_tag := ""
	for m in d.tags():
		if m.label.begins_with("CAPTAIN - CITADEL IN"):
			citadel_tag = m.label
	t.check(eta >= 45.0 and eta < INF, "the countdown first shows with at least 45 s to run (%.1f s)" % eta)
	t.check(rows.size() == 1 and rows[0].label == "The captain reaches the Citadel" and absf(float(rows[0]["in"]) - eta) < 0.1 and citadel_tag != "",
		"the strip has its row and the tag counts down from his last visit (%s; %s)" % [rows, citadel_tag])
	t.check(not banners.has("THE CAPTAIN NEARS THE CITADEL") and d.hint_phase() == "captain",
		"and the 20 s banner and hint have not fired in the same look (%s)" % [banners])
	t.check(Kit.edged(d, citadel_tag) and Kit.edged(d, "CITADEL"), "the captain and the Citadel are pointed at from the edge")
	# The window at the two ends of PACE_RANGE (visit left included, then the walk through the waypoint).
	var slow := 0.0
	var fast := 0.0
	var original := cap.target.pace
	cap.target.pace = Person.PACE_RANGE.x
	slow = d.captain_eta()
	cap.target.pace = Person.PACE_RANGE.y
	fast = d.captain_eta()
	cap.target.pace = original
	t.check(fast >= 45.0 and slow >= fast, "from the start of the last visit: %.1f s at the fast end, %.1f s at the slow end, both at least 45 s" % [fast, slow])
	print("NOTE: expel_inquisitor countdown window: %.1f s (fast pace) to %.1f s (slow pace), the walk alone %.1f / %.1f s" % [fast, slow, fast - visit, slow - visit])
	Kit.run_for(s, visit + AssassinateDirector.TICK + DT)
	t.check(cap.state == State.WALKING and cap.leg == cap.stops.size() and cap.target.goal().distance_to(d._walkable(ExpelInquisitorDirector.EI_FINAL_WAYPOINT)) < 0.5
		and cap.target.goal().distance_to(d.safe_at) > 10.0, "his round done, he walks through the final waypoint first, not straight to the gate")
	t.check(d.captain_eta() < eta and d.captain_eta() >= 30.0, "the countdown went on (%.1f s)" % d.captain_eta())
	_walk_to(s, cap, d._walkable(ExpelInquisitorDirector.EI_FINAL_WAYPOINT))
	t.check(not d.any_safe() and cap.target.goal().distance_to(d.safe_at) < 0.5, "through the waypoint he makes for the Citadel")
	# 20 s out: the banner and the hint.
	var near_pos := d.safe_at + Vector2(1.0, 0.0)
	Kit.arrive(cap.target, near_pos)
	cap.target.go_duty(d.safe_at)
	Kit.run_for(s, AssassinateDirector.TICK + DT)
	t.check(banners.has("THE CAPTAIN NEARS THE CITADEL") and d.hint_phase() == "near" and MissionHints.line("expel_inquisitor", d.hint_phase()) == "The captain nears the Citadel: stop him now.",
		"within 20 s: THE CAPTAIN NEARS THE CITADEL and the hint says stop him now (%s)" % [banners])
	t.check(!rules.finished, "(set-up) the night is not lost yet")
	Kit.arrive(cap.target, d.safe_at)
	Kit.run_for(s, AssassinateDirector.TICK + DT)
	t.check(d.any_safe() and rules.finished and not rules.won and rules.over_reason == "captain_safe" and banners.has("THE CAPTAIN REACHES THE CITADEL"),
		"at the gate: the night is lost, reason captain_safe")
	t.check(String(d.report().target) == "escaped", "the report: escaped")
	Kit.done(s)

	# Nobody else is ever safe: a warden has no safe place.
	var f := _world()
	var df := _ei(f)
	_out(df, df.quarries[0])
	Kit.arrive(df.quarries[0].target, df.safe_at)
	Kit.run_for(f, AssassinateDirector.TICK + DT)
	t.check(not df.any_safe() and df.quarries[0].state != State.SAFE and not (f.rules as Rules).finished, "a warden standing at the Citadel's gate is not safe there")
	Kit.done(f)


## The countdown is true (god P5 Task 11, review of Task 6): walked by the person himself, from his last stop's door through the waypoint to the gate,
## the captain arrives no sooner than his tag reads 0:00 and not long after it, at the two ends of PACE_RANGE and between (the walk term is scaled to
## the measured pace, EI_WALK_SCALE; the ETA was about 15 % short, so the tag showed 0:00 about 6 s before he came).
static func _eta_true(t) -> void:
	for pace: float in [Person.PACE_RANGE.x, 1.0, Person.PACE_RANGE.y]:
		var s := _world()
		var d := _ei(s)
		var cap := d.captain()
		var p: Person = cap.target
		d._set_out(cap)
		p.pace = pace
		p.walk_speed = Person.PANIC_SPEED * pace
		Kit.arrive(p, cap.stop_doors[cap.stops.size() - 1])
		cap.state = State.WALKING
		cap.leg = cap.stops.size()
		var eta := d.captain_eta()
		var wp := d._walkable(ExpelInquisitorDirector.EI_FINAL_WAYPOINT)
		p.go_duty(wp)
		var secs := 0.0
		var through := false
		while secs < 200.0:
			p.tick(0.05)
			secs += 0.05
			if not through and p.ground_pos.distance_to(wp) < 0.6:
				through = true
				p.go_duty(d.safe_at)
			elif through and p.ground_pos.distance_to(d.safe_at) < 0.6:
				break
		t.check(through and secs < 200.0, "(set-up) the walk reached the gate at pace %.2f (%.1f s)" % [pace, secs])
		t.check(eta >= secs - 0.5 and eta - secs <= 4.0, "pace %.2f: the tag reads %.1f s and he walks it in %.1f s (never early, at most 4 s over)" % [pace, eta, secs])
		Kit.done(s)


## The ETA is computed once for a look (god P5 Task 11, review of Task 6): the strip row, the hint, the banner check and the tag together ask for it
## four times a frame in the warned window, and each ask is two path searches. Asking again where nothing moved costs no search.
static func _eta_once(t) -> void:
	var s := _world()
	var d := _ei(s)
	var cap := d.captain()
	d._set_out(cap)
	Kit.arrive(cap.target, cap.stop_doors[cap.stops.size() - 1])
	cap.state = State.VISITING
	cap.leg = cap.stops.size() - 1
	cap.indoors_left = 4.0
	var before := d.eta_runs()
	var first := d.captain_eta()
	d.strip_rows()
	d.hint_phase()
	d.tags()
	var again := d.captain_eta()
	t.check(d.eta_runs() == before + 1 and again == first, "four asks in one look run the search once (%d runs) and agree (%.1f, %.1f)" % [d.eta_runs() - before, first, again])
	cap.target.pace = 1.0
	cap.indoors_left = 3.0
	d.captain_eta()
	t.check(d.eta_runs() == before + 2, "a changed pace or visit clock asks again (%d runs)" % [d.eta_runs() - before])
	Kit.run_for(s, AssassinateDirector.TICK + DT)
	var stepped := d.eta_runs()
	d.captain_eta()
	d.captain_eta()
	t.check(d.eta_runs() <= stepped + 1, "and after a step the next asks share one search (%d more)" % [d.eta_runs() - stepped])
	cap.state = State.WAITING
	var idle_runs := d.eta_runs()
	t.check(d.captain_eta() == INF and d.eta_runs() == idle_runs, "a captain not warned costs no search")
	Kit.done(s)


## The Hunt's six per-type policies (god P5 Task 11): all six written, their loadouts within the tree and the floor, none a filler (D38: no cast whose
## only purpose is to end an idle stretch -- the policy file holds no FILL word), the Silent Doom aimed where the man stands now (it takes whoever is
## within its radius at the cast), a Death Mark held back while the fuse would find him indoors, and Decree a delay only.
static func _policies(t) -> void:
	var filled := GodHunts.filled("expel_inquisitor")
	for type: String in ["ruin", "death", "veil", "passage", "decree", "dominion"]:
		t.check(filled.has(type) and GodHunts.has_policy("expel_inquisitor", type), "the %s policy is written (FILLED %s)" % [type, Array(filled)])
	GodTree.dev_fill = true
	for type: String in ["ruin", "death", "veil", "passage", "decree", "dominion"]:
		t.check(GodHunts.problems("expel_inquisitor", type, 3).is_empty(), "%s: the loadout is in the tree at Tier 3 and within the floor (%s)" % [type, Array(GodHunts.problems("expel_inquisitor", type, 3))])
	GodTree.dev_fill = false
	var src := FileAccess.get_file_as_string("res://tools/dev/routes/god_hunts/expel_inquisitor.gd")
	t.check(not src.contains("GOD.FILL") and not src.contains("FILL +") and not src.contains('"fill:') and not src.contains("is_fill"), "no policy of the Hunt casts a filler (D38)")
	# The Doom: on him where he stands; the midpoint when his guard stands within a Doom's reach of it.
	var s := _world()
	var d := _ei(s)
	var q := d.quarries[0]
	_out(d, q)
	var guard: Person = q.guards[0]
	guard.ground_pos = q.target.ground_pos + Vector2(6.0, 0.0)
	t.check(HUNT._doom_aim(q).distance_to(q.target.ground_pos) < 0.01, "the Doom is aimed at the man where he stands now, a guard far off (%s)" % [HUNT._doom_aim(q)])
	guard.ground_pos = q.target.ground_pos + Vector2(0.9, 0.0)
	t.check(HUNT._doom_aim(q).distance_to(q.target.ground_pos + Vector2(0.45, 0.0)) < 0.01, "and at the midpoint when his guard is 0.9 off, so both fall (%s)" % [HUNT._doom_aim(q)])
	# The mark: a man inside for longer than the fuse is not marked; the door guards are a waiting target's only.
	var ctx := {"d": d, "crowd": s.crowd, "rules": s.rules}
	var w := d.quarries[1]
	_out(d, w)
	w.state = State.VISITING
	w.indoors_left = 20.0
	t.check(not HUNT._mark_holds(ctx, w), "a Death Mark is not laid on a man who is indoors for 20 s more")
	t.check(HUNT._door_guards(d).is_empty(), "with somebody out, nobody's guards at a door are struck")
	Kit.done(s)
	var n := _world()
	var dn := _ei(n)
	Kit.arrive(dn.quarries[0].guards[0], dn.quarries[0].stop_doors[0] + Vector2(1.0, 0.0))
	t.check(HUNT._door_guards(dn).size() == 1 and HUNT._door_guards(dn)[0] == dn.quarries[0].guards[0], "before anyone is out, the first warden's guard at his door is the one struck")
	# Decree: no route (MS §9 open issue 1); its one act is the law laid over the captain, to delay him.
	var from := src.find("static func act_decree")
	var body := src.substr(from, src.find("# --- Dominion") - from)
	t.check(body.contains("slots.noleave") and body.count("rules.cast(") == 1, "the Decree policy casts the one law (Leaving Is Prohibited), over the captain, and nothing else")
	Kit.done(n)


## The door preps of the policies (review of Task 11, I1, M1, M2; Rulings P5-T11-R6, R7): a guard is struck at his door only in the last RUIN_PREP_LEAD seconds
## of the wait (Ruin), only while he stands at it, and the Madness Bloom lands once for each target and never on a guard who has wandered off. The tour line.
static func _door_policies(t) -> void:
	var s := _world()
	var d := _ei(s)
	var first := d.quarries[0]
	var guard: Person = first.guards[0]
	var door: Vector2 = first.stop_doors[0]
	Kit.arrive(guard, door + Vector2(1.0, 0.0))  # (the Kit world does not walk bodies: he stands where his post would put him)
	# The lead: the wait is 44 s; at 0 s the last-24-s window has not come, at 21 s it has.
	t.check(HUNT._door_guards(d, HUNT.RUIN_PREP_LEAD).is_empty() and HUNT._door_guards(d).size() == 1,
		"before the last %.0f s of the wait the Ruin prep strikes nobody; with no lead the guard is there" % HUNT.RUIN_PREP_LEAD)
	Kit.run_for(s, 21.0)
	t.check(HUNT._door_guards(d, HUNT.RUIN_PREP_LEAD).size() == 1, "in the last %.0f s of the wait it strikes the guard at the door (clock %.1f)" % [HUNT.RUIN_PREP_LEAD, d._clock])
	# The Bloom: once for each target, and only on a guard at his door.
	var memo := {}
	var aim := HUNT._bloom_aim(d, memo)
	t.check(aim != Vector2.INF and aim.distance_to(guard.ground_pos) < 0.01, "the Bloom is aimed at the guard at the first warden's door (%s)" % [aim])
	HUNT._bloom_done(d, memo)
	t.check(HUNT._bloom_aim(d, memo) == Vector2.INF, "and not again for the same target (a repeat cast is a filler)")
	var memo2 := {}
	var home := guard.ground_pos
	guard.ground_pos = door + Vector2(HUNT.DOOR_REACH + 4.0, 0.0)
	t.check(HUNT._bloom_aim(d, memo2) == Vector2.INF and HUNT._door_guards(d, INF, HUNT.DOOR_REACH).is_empty(), "a guard who has wandered off from the door is not bloomed")
	guard.ground_pos = home
	t.check(HUNT._bloom_aim(d, memo2) != Vector2.INF, "back at the door he is (the aim is not lost for good)")
	# The next target: after the first is out, the Bloom is for the second warden's guard, once.
	var memo3 := {"bloom_0": true}
	d._set_out(first)
	Kit.done(s)
	var n := _world()
	var dn := _ei(n)
	var memo4 := {"bloom_0": true}
	dn.quarries[0].state = State.DEAD
	dn.quarries[0].dead = true
	var second: Person = dn.quarries[1].guards[0]
	Kit.arrive(second, dn.quarries[1].stop_doors[0] + Vector2(0.0, 1.0))
	t.check(HUNT._bloom_aim(dn, memo4) != Vector2.INF and HUNT._bloom_aim(dn, memo4).distance_to(second.ground_pos) < 0.01,
		"with the first done, the Bloom is for the second warden's guard")
	HUNT._bloom_done(dn, memo4)
	t.check(memo4.has("bloom_1") and HUNT._bloom_aim(dn, memo4) == Vector2.INF, "once for him too")
	Kit.done(n)
	# The tour line reads the first warden's time.
	var w := _world()
	var tour := _ei(w).tour()
	t.check(tour.size() == 3 and String(tour[0][1]) == "A lantern-warden waits in his house. He sets out at 0:44; two more follow.", "the tour line: He sets out at 0:44 (%s)" % [tour[0][1]])
	Kit.done(w)


## The captain's two guards stay apart on his walk (review of Task 11, M3; Ruling P5-T11-R8, MS §0: one Doom or strike must not take both). The bodies
## are moved: the captain walks his whole round to the Citadel with his two guards ticked beside him (Person.tick; the Kit world does not step bodies),
## and the gap between the guards is read every step. At a stop (he indoors, the two at his door) it stays over 1.6 always; on the walk it does but for
## the turns of the road (a corner, the doubling-back at the waypoint) where a pair walking in file must pass the same ground -- at most 5 % of the steps.
## They also keep up with him (the farthest a guard strays from him is under 6), or "apart" would only mean "left behind".
static func _guards_walk(t) -> void:
	var s := _world()
	var d := _ei(s)
	var cap := d.captain()
	var rules: Rules = s.rules
	var pair := d._door_pair(d.hide_door)
	for k in 2:
		Kit.arrive(cap.guards[k], pair[k])  # (the guards at the Temple's door, where their posts put them)
	d._set_out(cap)
	var settle := 0.0
	var last_state := -1
	var steps := 0
	var stop_steps := 0
	var stop_under := 0
	var walk_steps := 0
	var walk_under := 0
	var worst_stop := INF
	var farthest := 0.0
	var secs := 0.0
	while secs < 220.0 and not rules.finished:
		(s.crowd as Crowd).advance(DT)
		rules.advance(DT)
		secs += DT
		for p: Variant in [cap.target] + cap.guards:
			if MissionDirector._alive(p):
				(p as Person).tick(DT)
		if int(cap.state) != last_state:
			last_state = int(cap.state)
			settle = 0.0
		settle += DT
		var a: Person = cap.guards[0]
		var b: Person = cap.guards[1]
		if settle < (STOP_SETTLE if cap.state == State.VISITING else SETTLE) or not MissionDirector._alive(a) or not MissionDirector._alive(b) or a.inside or b.inside:
			continue
		var gap := a.ground_pos.distance_to(b.ground_pos)
		steps += 1
		if cap.state == State.VISITING:
			stop_steps += 1
			worst_stop = minf(worst_stop, gap)
			stop_under += 1 if gap <= 1.6 else 0
		elif cap.state == State.WALKING:
			walk_steps += 1
			walk_under += 1 if gap <= 1.6 else 0
			var far_now := maxf(a.ground_pos.distance_to(cap.target.ground_pos), b.ground_pos.distance_to(cap.target.ground_pos))
			if far_now > 5.0 and far_now > farthest:
				print('DBG far %.1f t=%.1f leg=%d cap=%s a=%s b=%s' % [far_now, secs, cap.leg, cap.target.ground_pos, a.ground_pos, b.ground_pos])
			farthest = maxf(farthest, far_now)
	t.check(rules.finished and walk_steps > 800, "(set-up) the captain walked his round (%d steps walking, %d at stops, %.0f s)" % [walk_steps, stop_steps, secs])
	t.check(stop_steps > 100 and stop_under == 0, "at his stops the two guards stand over 1.6 apart always (%d steps, closest %.2f)" % [stop_steps, worst_stop])
	t.check(float(walk_under) <= 0.05 * float(walk_steps), "on his walk they are over 1.6 apart but at the turns of the road: %d of %d steps under (%.1f %%)" % [walk_under, walk_steps, 100.0 * float(walk_under) / float(maxi(walk_steps, 1))])
	t.check(farthest < 6.0, "and they keep up with him (the farthest a guard strays from him: %.1f)" % farthest)
	Kit.done(s)


static func _win_beats_loss(t) -> void:
	# The last warden falls the moment the captain is on the Citadel's step: the win is checked first.
	var s := _world()
	var d := _ei(s)
	var rules: Rules = s.rules
	for i in 3:
		_out(d, d.quarries[i])
		_kill(s, d.quarries[i])
	var cap := d.captain()
	_out(d, cap)
	Kit.arrive(cap.target, d.safe_at)
	(s.crowd as Crowd)._field.kill(cap.target, &"doom")
	Kit.run_for(s, DT * 2.0)
	t.check(d.all_fallen() and rules.finished and rules.won and rules.over_reason == "expelled" and not d.any_safe(),
		"the captain killed at the gate with the wardens down: won, never lost (%s)" % rules.over_reason)
	Kit.done(s)

	# The bell tolls on a seen death: the Lantern turns, nothing is lost.
	var b := _world()
	var db := _ei(b)
	_out(db, db.quarries[0])
	(b.crowd as Crowd)._field.kill(db.quarries[0].target, &"doom")
	Kit.run_for(b, 0.5)
	t.check(not (b.rules as Rules).finished and db.quarries[0].dead, "a seen death loses nothing (%s %s)" % [(b.rules as Rules).finished, db.quarries[0].dead])
	Kit.done(b)


static func _lost_body(t) -> void:
	# A target whose body is freed without a death (he left the map) is stopped, never safe.
	var s := _world()
	var d := _ei(s)
	var q := d.quarries[1]
	_out(d, q)
	var body: Person = q.target
	(s.crowd as Crowd)._field.remove(body)
	(s.crowd as Crowd).citizens.erase(body)
	body.free()
	Kit.run_for(s, DT * 2.0)
	t.check(q.state == State.OUT and not d.any_safe() and d.stopped() == 1 and not (s.rules as Rules).finished, "a warden's body gone without a death: stopped, not safe, and the night goes on")
	var c := d.captain()
	_out(d, c)
	var cb: Person = c.target
	(s.crowd as Crowd)._field.remove(cb)
	(s.crowd as Crowd).citizens.erase(cb)
	cb.free()
	Kit.run_for(s, DT * 2.0)
	t.check(c.state == State.OUT and not d.any_safe(), "the captain's the same: expelled, not escaped")
	Kit.run_for(s, 2.0)
	t.check(true, "and the director steps on over freed bodies")
	Kit.done(s)

	# Guards freed.
	var g := _world()
	var dg := _ei(g)
	var qg := dg.quarries[0]
	_out(dg, qg)
	var guard: Person = qg.guards[0]
	Kit.free_body(g, guard)
	Kit.run_for(g, 1.0)
	t.check(qg.state == State.HIDING and dg.tags().size() > 0, "a freed guard is borne: it alarms his warden, who hides, and the tags go on (%s %d)" % [State.keys()[qg.state], dg.tags().size()])
	Kit.done(g)


static func _tags(t) -> void:
	var s := _world()
	var d := _ei(s)
	var q := d.quarries[0]
	_out(d, q)
	var cap := d.captain()
	var labels := Kit.labels(d)
	t.check(labels.has("WARDEN") and Kit.edged(d, "WARDEN") and labels.has("STOP") and labels.has("GUARD") and Kit.edged(d, "GUARD"),
		"a warden in the street: WARDEN (pointed at), his STOP, his GUARD (pointed at) (%s)" % [labels])
	t.check(labels.any(func(l: String) -> bool: return l.begins_with("WARDEN OUT IN")), "the waiting wardens count down (%s)" % [labels])
	# Waiting tags count down with the clock, like the strip.
	Kit.run_for(s, 10.0)
	var after := Kit.labels(d)
	var tick := ""
	for l: String in after:
		if l.begins_with("CAPTAIN OUT IN"):
			tick = l
	t.check(tick == "CAPTAIN OUT IN 3:00" or tick == "CAPTAIN OUT IN 3:01", "the captain's countdown ran down ten seconds (%s)" % tick)
	# Inside a visit.
	_walk_to(s, q, q.stop_doors[1])
	var inside := ""
	for l: String in Kit.labels(d):
		if l.begins_with("WARDEN - INSIDE"):
			inside = l
	t.check(inside != "", "visiting, a warden is tagged INSIDE with his seconds (%s)" % inside)
	# The captain inside shows his shaken count.
	_out(d, cap)
	d._on_danger("smite", [cap.target.ground_pos] as Array[Vector2])
	_walk_to(s, cap, d.hide_door)
	var cin := ""
	for l: String in Kit.labels(d):
		if l.begins_with("CAPTAIN - INSIDE"):
			cin = l
	t.check(cin.ends_with("SHAKEN 1/3"), "hiding, the captain reads inside with the count (%s)" % cin)
	t.check(Kit.labels(d).has("CITADEL"), "the Citadel's gate stays tagged")
	# The Temple tag is not the HIDEOUT's: no stray words.
	t.check(not Kit.labels(d).has("HIDEOUT") and not Kit.labels(d).has("NEXT TARGET"), "no base words are left on the map")
	Kit.done(s)

	# Everything stopped: no tags.
	var e := _world()
	var de := _ei(e)
	for i in 4:
		_out(de, de.quarries[i])
		_kill(e, de.quarries[i])
	t.check(de.tags().is_empty(), "once all four are stopped nothing is tagged")
	Kit.done(e)


## The camera spot and the tags the night opens on are clear of the HUD stack (MS §0, Kit.STACK).
static func _camera(t) -> void:
	var s := _world()
	var d := _ei(s)
	var cam := ExpelInquisitorDirector.EI_CAMERA_AT
	var clear := true
	var failed := ""
	for m in d.tags():
		if not m.label.begins_with("WARDEN OUT IN 0:44"):
			continue
		if not Kit.clear_of_stack(m.at, cam, Kit.STACK):
			clear = false
			failed = m.label
	t.check(clear, "the first warden's countdown is clear of the HUD stack from the camera (%s)" % failed)
	var door_ok := Kit.clear_of_stack(d.quarries[0].stop_doors[0], cam, Kit.STACK)
	t.check(door_ok, "and so is his door (%s)" % [d.quarries[0].stop_doors[0]])
	Kit.done(s)


## The director's people are kept out of the town's flight every look (_hold_all): a target whose mind the evacuation made FLEE is back on his
## feet and walking, a guard back at his post.
static func _hold(t) -> void:
	var s := _world()
	var d := _ei(s)
	var q := d.quarries[0]
	_out(d, q)
	var guard: Person = q.guards[0]
	q.target._reassured_fled = true
	guard._reassured_fled = true
	Kit.run_for(s, AssassinateDirector.TICK + DT)
	t.check(not q.target._reassured_fled and not guard._reassured_fled, "each look lets go of the flight a false calm owes the warden and his guard")
	Kit.done(s)


static func _evacuation(t) -> void:
	var s := _world()
	var d := _ei(s)
	var q := d.quarries[0]
	_out(d, q)
	var cap := d.captain()
	_out(d, cap)
	var warden_guard: Person = q.guards[0]
	q.target._recover(1.0)
	warden_guard._recover(1.0)
	Kit.evacuate(s)
	t.check(q.target.mind == Person.Mind.FLEE, "(set-up) the evacuation sends the recovering warden running (%s)" % Person.Mind.keys()[q.target.mind])
	Kit.run_for(s, 2.0 * AssassinateDirector.TICK + DT)
	t.check(q.target.mind == Person.Mind.DUTY and q.target.goal().distance_to(q.stop_doors[q.leg]) < 0.5 and q.state == State.WALKING,
		"at the next looks the warden is back on duty, bound for his stop (%s)" % [Person.Mind.keys()[q.target.mind]])
	t.check(warden_guard.mind != Person.Mind.FLEE and (s.crowd as Crowd).soldiers.has(warden_guard), "his guard is held out of the flight too")
	t.check(d.frights() == 0 and cap.state == State.WALKING, "and the evacuation was no fright on the captain (%d)" % d.frights())
	Kit.run_for(s, 5.0)
	t.check(not d.any_safe() and d.stopped() == 0 and not (s.rules as Rules).finished, "the town's flight loses nothing and stops no one")
	Kit.done(s)


## Open issue 4's promise for this Hunt (Task 1's _hunt_wishes, which skips a director's people held in a Quarry): on nights 0-3 the Descent
## hears the tier's wishes and none lands on a target, a guard, or a house of any round, nor the Temple.
static func _wishes(t) -> void:
	var id := MissionBook.EXPEL_INQUISITOR
	var heard := 0
	var hit := 0
	for night in 4:
		var def := HuntBook.def(id)
		var descent := Descent.new().setup(def, Descent.seed_for(night, id))
		var n := Kit.world(HuntBook.def(id), null, func(dir: MissionDirector, rules: Rules) -> void: descent.reserve(rules, dir))
		var d := _ei(n)
		var mine: Array = []
		var places: Array = [d.hideout]
		for q in d.quarries:
			mine.append(q.target)
			mine.append_array(q.guards)
			places.append_array(q.stops)
		for w in descent.wishes:
			heard += 1
			for p in w.people():
				hit += 1 if mine.has(p) else 0
			for st in w.places():
				hit += 1 if places.has(st) else 0
		descent.release()
		Kit.done(n)
	t.check(heard > 0 and hit == 0, "wishes heard (%d), none on the director's own people or buildings (%d)" % [heard, hit])
