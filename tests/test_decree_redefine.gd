extends RefCounted
## Redefine (Decree, Tier II; spec 5.3): say what a person is and, for 25 s, the law agrees. The MAX_NAMED people nearest
## the click within PICK_R are named (by distance, ties by instance order, never a roll), each with LawMark under the
## effect's own owner id, and a gilt word floats over each. CRIMINAL: every guard who sees him goes for him (a soldier is
## hunted by his own). OFFICER: no guard takes him for a suspect (an inquisitor at 1.0 does not seize a believer, who still
## counts). NOBODY: no one sees him. After SPAN every mark it set is lifted; ending early, or leaving the tree, lifts them too,
## and only its own. Quiet.

const PATH := "res://src/fx/decree/redefine.gd"
const DT := 0.1
const Kit := preload("res://tests/test_tier2_groundwork.gd")
const Hide := preload("res://tests/test_hide_faithful.gd")
const Breath := preload("res://tests/test_decree_breath.gd")


static func run(t) -> void:
	_book(t)
	_named(t)
	_criminal(t)
	_officer(t)
	_lifted(t)


static func _book(t) -> void:
	var b := PowerBook.get_power("redefine")
	var area: Dictionary = Targeting.AREAS.get("redefine", {})
	var modes: Array = b.get("modes", [])
	var keys := []
	for m: Dictionary in modes:
		if String(m.get("name", "")) != "":
			keys.append(String(m.get("key", "")))
	t.check(String(b.get("name", "")) == "Redefine" and int(b.get("dp", 0)) == 3 and float(b.get("cooldown", 0.0)) == 45.0
		and String(b.get("aim", "")) == "click" and PowerBook.is_quiet("redefine") and PowerBook.authority_of("redefine") == "decree"
		and ResourceLoader.exists(String(b.get("path", ""))) and String(area.get("shape", "")) == "circle"
		and Rules.POWER_KINDS.get("redefine", null) == [&"frenzy"] and PowerBook.family("redefine") == "decree"
		and not PowerBook.REACH.has("redefine") and not PowerBook.IMPACT.has("redefine"),
		"Redefine: Decree, 3 Might, 45 s, a click, quiet (%s)" % [b])
	t.check(keys == ["criminal", "officer", "nobody"], "its modes are CRIMINAL, OFFICER and NOBODY, each with a name (%s)" % [keys])
	var script: GDScript = load(PATH)
	if script == null:
		return
	var c: Dictionary = script.get_script_constant_map()
	t.check(is_equal_approx(float(c.get("PICK_R", 0.0)), 1.5) and int(c.get("MAX_NAMED", 0)) == 3 and is_equal_approx(float(c.get("SPAN", 0.0)), 25.0)
		and is_equal_approx(float(area.get("r", 0.0)), float(c.get("PICK_R", 0.0))),
		"PICK_R 1.5, MAX_NAMED 3, SPAN 25 s, and the aim's circle is PICK_R")


## Everyone moved off into a corner of the map, out of the way.
static func _scatter(crowd: Crowd) -> void:
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1


## NOBODY on four people within PICK_R: the three nearest are named, the fourth (at 1.4) is skipped; one at 1.6 is out of
## reach. Two at the same distance: the earlier instance first.
static func _named(t) -> void:
	var made: Array = Breath._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	_scatter(crowd)
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var a: Person = crowd.citizens[0]
	var b: Person = crowd.citizens[1]
	var c: Person = crowd.citizens[2]
	var d: Person = crowd.citizens[3]
	var e: Person = crowd.citizens[4]
	a.ground_pos = at + Vector2(0.3, 0.0)
	b.ground_pos = at + Vector2(0.0, -0.6)
	c.ground_pos = at + Vector2(-0.9, 0.0)
	d.ground_pos = at + Vector2(0.0, 1.4)
	e.ground_pos = at + Vector2(1.6, 0.0)
	var fx: FxTimeline = FxTimeline.cast(load(PATH), ctx, at, {"mode": "nobody"})
	var named: Array = fx.get("named")
	t.check(named == [a, b, c], "NOBODY names exactly the three nearest, nearest first (%d named)" % named.size())
	t.check(LawMark.kind_of(a) == &"nobody" and LawMark.kind_of(b) == &"nobody" and LawMark.kind_of(c) == &"nobody"
		and LawMark.unseen_by_all(a), "each of them is NOBODY by law")
	t.check(LawMark.kind_of(d) == &"" and LawMark.kind_of(e) == &"", "the fourth at 1.4 is skipped (MAX_NAMED), one at 1.6 is out of reach")
	fx.end_now()
	# A tie: two at 1.0, one place left -- the earlier instance takes it, whichever order they stand in the field.
	var f: Person = crowd.citizens[5]
	var g: Person = crowd.citizens[6]
	_scatter(crowd)
	a.ground_pos = at + Vector2(0.2, 0.0)
	b.ground_pos = at + Vector2(-0.4, 0.0)
	f.ground_pos = at + Vector2(1.0, 0.0)
	g.ground_pos = at + Vector2(-1.0, 0.0)
	var first := f if f.get_instance_id() < g.get_instance_id() else g
	var fx2: FxTimeline = FxTimeline.cast(load(PATH), ctx, at, {"mode": "officer"})
	named = fx2.get("named")
	t.check(named.size() == 3 and named[2] == first and LawMark.kind_of(first) == &"officer"
		and LawMark.kind_of(g if first == f else f) == &"", "a tie at 1.0 goes to the earlier instance")
	fx2.end_now()
	# A bad mode is the first.
	var fx3: FxTimeline = FxTimeline.cast(load(PATH), ctx, at, {"mode": "king"})
	t.check(String(fx3.get("mode")) == "criminal", "an unknown mode is read as CRIMINAL")
	fx3.end_now()
	Breath._done(made)


## CRIMINAL on a soldier: the other soldiers about him fight him (a TARGET_ONLY fight, the law's own), and are called off
## when the law is lifted.
static func _criminal(t) -> void:
	var made: Array = Breath._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	_scatter(crowd)
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var named: Person = crowd.soldiers[0]
	var s1: Person = crowd.soldiers[1]
	var s2: Person = crowd.soldiers[2]
	named.ground_pos = at
	s1.ground_pos = at + Vector2(2.0, 0.0)
	s2.ground_pos = at + Vector2(0.0, -2.4)
	for s: Person in [named, s1, s2]:
		s.mind = Person.Mind.POST
	var fx: FxTimeline = FxTimeline.cast(load(PATH), ctx, at, {"mode": "criminal"})
	t.check(fx.get("named") == [named] and LawMark.wanted(named), "CRIMINAL names the soldier alone")
	named.tick(DT)
	t.check(s1.mind == Person.Mind.FIGHT and s1.fight_target == named and s1._fight_rule == Person.FightRule.TARGET_ONLY
		and s2.mind == Person.Mind.FIGHT and s2.fight_target == named, "the other soldiers go for him, a TARGET_ONLY fight")
	t.check(named.mind != Person.Mind.FIGHT or named.fight_target != named, "he is not set on himself")
	fx.end_now()
	t.check(LawMark.kind_of(named) == &"" and s1.mind != Person.Mind.FIGHT and s2.mind != Person.Mind.FIGHT,
		"ended, the law is lifted and his hunters are called off")
	Breath._done(made)


## OFFICER on a believer in Hide the faithful: an inquisitor at 1.0 does not seize him; the believer still counts; lifted,
## he is seen again.
static func _officer(t) -> void:
	var s := Hide._world()
	var d: HideFaithfulDirector = s.d
	Hide._clear_watch(d)
	d._come_out(0)
	Kit.run_for(s, EscortDirector.TICK + DT)
	var lead := d.lamp(0)
	var lp := lead.man as Person
	var inq := d.inquisitors[0] as Person
	var at := lp.ground_pos
	# Nobody else within reach of the click: the believer alone is named.
	for group: Array[Person] in [s.crowd.citizens, s.crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and p != lp and p.ground_pos.distance_to(at) <= 3.0:
				Kit.arrive(p, at + Vector2(6.0, 6.0))
	Kit.arrive(inq, at + Vector2(1.0, 0.0))
	var left := d.left_count()
	t.check(d._watching(inq) and d._seen_by(lead) == inq, "no law: an inquisitor at 1.0 sees the believer")
	var ctx := FxContext.new()
	ctx.env = s.env
	ctx.field = s.field
	ctx.crowd = s.crowd
	ctx.rules = s.rules
	ctx.rng = RandomNumberGenerator.new()
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	Kit.arrive(inq, at + Vector2(6.0, 0.0))
	var fx: FxTimeline = FxTimeline.cast(load(PATH), ctx, at, {"mode": "officer"})
	t.check(fx.get("named") == [lp] and LawMark.kind_of(lp) == &"officer", "OFFICER names the believer")
	var seized := false
	for k in 8:
		Kit.arrive(inq, lp.ground_pos + Vector2(1.0, 0.0))
		Kit.run_for(s, EscortDirector.TICK)
		seized = seized or lead.held or lead.taken
	t.check(not seized and d._seen_by(lead) == null, "an inquisitor at 1.0 does not seize him")
	t.check(d.left_count() == left and d.charges.has(lead), "the believer still counts (%d of %d)" % [d.left_count(), left])
	fx.end_now()
	Kit.arrive(inq, lp.ground_pos + Vector2(1.0, 0.0))
	t.check(LawMark.kind_of(lp) == &"" and d._seen_by(lead) == inq, "lifted, he is seen again")
	ctx.overhead.free()
	ctx.ground.free()
	Kit.done(s)


## After SPAN every mark it set is lifted; ending early lifts them; leaving the tree lifts them; another owner's law stays.
static func _lifted(t) -> void:
	var made: Array = Breath._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	_scatter(crowd)
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var a: Person = crowd.citizens[0]
	var b: Person = crowd.citizens[1]
	var c: Person = crowd.citizens[2]
	a.ground_pos = at + Vector2(0.3, 0.0)
	b.ground_pos = at + Vector2(-0.3, 0.0)
	c.ground_pos = at + Vector2(0.0, 0.5)
	LawMark.set_law(c, &"criminal", 120.0, 99)
	var fx: FxTimeline = FxTimeline.cast(load(PATH), ctx, at, {"mode": "nobody"})
	var span := float((load(PATH) as GDScript).get_script_constant_map().get("SPAN", 0.0))
	t.check(LawMark.kind_of(a) == &"nobody" and LawMark.kind_of(c) == &"nobody", "named: NOBODY, over another owner's CRIMINAL")
	Breath._run([fx], span - 0.5)
	t.check(LawMark.kind_of(a) == &"nobody" and LawMark.kind_of(b) == &"nobody", "at 24.5 s the law still holds")
	Breath._run([fx], 0.6)
	t.check(LawMark.kind_of(a) == &"" and LawMark.kind_of(b) == &"" and LawMark.kind_of(c) == &"criminal",
		"after 25 s every mark it set is lifted; another owner's law stays")
	Breath._run([fx], 2.0)
	t.check(fx.finished, "and the effect is done")
	LawMark.lift(c, 99)

	# Ended early.
	var fx2: FxTimeline = FxTimeline.cast(load(PATH), ctx, at, {"mode": "officer"})
	Breath._run([fx2], 5.0)
	var held := LawMark.kind_of(a) == &"officer" and LawMark.kind_of(b) == &"officer" and LawMark.kind_of(c) == &"officer"
	fx2.end_now()
	t.check(held and LawMark.kind_of(a) == &"" and LawMark.kind_of(b) == &"" and LawMark.kind_of(c) == &"",
		"ending the effect early lifts every mark it set")

	# Leaving the tree (a scene torn down round it): the suite runs before the tree does, so its _exit_tree() is called as
	# the tree would.
	var fx3: FxTimeline = FxTimeline.cast(load(PATH), ctx, at, {"mode": "criminal"})
	var wanted := LawMark.wanted(a)
	fx3._exit_tree()
	t.check(wanted and LawMark.kind_of(a) == &"" and LawMark.kind_of(b) == &"" and LawMark.kind_of(c) == &"",
		"taken out of the tree, it lifts them too (wanted %s, now %s %s %s)" % [wanted, LawMark.kind_of(a), LawMark.kind_of(b), LawMark.kind_of(c)])
	fx3.free()
	Breath._done(made)
