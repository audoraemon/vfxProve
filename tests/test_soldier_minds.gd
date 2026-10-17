extends RefCounted
## v0.11.1 Soldiers hear the god: every control power reaches a soldier as it reaches a citizen (Mind Whisper, Discord, lures, a power's
## fright, calm), and Person.resists_mind() is the one hook for the later "strong ones". A soldier the god lets go goes back to what
## he was doing -- the post a director gave him, the rally ring, his duty -- never into a citizen's day and never into flight
## (Person._soldier_back()). The town's own routines still reach citizens only. And every director that takes its soldiers back to
## their places at its looks leaves one the god holds be (Person.held_by_god()): one `_held_soldier` check per manager.

const Kit := preload("res://tests/test_tier2_groundwork.gd")
const DT := 0.05


## A person whose mind the god cannot reach (the hook's test double).
class Strong:
	extends Person

	func resists_mind() -> bool:
		return true


static func run(t) -> void:
	_hears(t)
	_comes_back(t)
	_back_to_what_he_did(t)
	_powers(t)
	_town_unchanged(t)
	_hook(t)
	_held_soldier(t)


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


## A soldier of no corps, at his post and unhurried, with nothing laid on him.
static func _soldier(crowd: Crowd, k: int) -> Person:
	var seen := 0
	for p in crowd.soldiers:
		if p.corps == Person.Corps.NONE and p.mind == Person.Mind.POST and not p.hurrying:
			if seen == k:
				p.stop_fighting()
				return p
			seen += 1
	return null


static func _arrive(p: Person) -> void:
	p.ground_pos = p.goal() if p.goal() != Vector2.INF else p.ground_pos
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


const HOLD_MINDS := [Person.Mind.WHISPERED, Person.Mind.CONFUSED, Person.Mind.OBSERVE, Person.Mind.PANIC, Person.Mind.COMPELLED]


## Runs `p`'s thinking, arriving where he walks to, until no hold is on him or `seconds` have gone; the minds he passed through.
static func _let_go(p: Person, seconds: float) -> Array:
	var passed := []
	var left := 0.0
	while left < seconds:
		p._think(0.5)
		if p.goal() != Vector2.INF and p.mind in HOLD_MINDS:
			_arrive(p)
		if not passed.has(p.mind):
			passed.append(p.mind)
		left += 0.5
		if not p.mind in HOLD_MINDS and p.mind != Person.Mind.RECOVER and p.mind != Person.Mind.CALM:
			break
	return passed


static func _hears(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	var s := _soldier(crowd, 0)
	var spot := grid.nearest_walkable(s.ground_pos + Vector2(3.0, 0.0))
	t.check(s.whisper(spot, 8.0) and s.mind == Person.Mind.WHISPERED, "v0.11.1: soldiers hear the god -- a soldier hears Mind Whisper")
	t.check(s.held_by_god() and s.intent() == Person.Intent.WHISPERED, "and a whispered soldier is held by the god")
	var c := _soldier(crowd, 1)
	c.confuse(15.0)
	t.check(c.mind == Person.Mind.CONFUSED and c.held_by_god(), "v0.11.1: soldiers hear the god -- a soldier loses his head to Discord")
	var l := _soldier(crowd, 2)
	t.check(l.lure(l.ground_pos + Vector2(2.0, 0.0), 5.0) and l.mind == Person.Mind.OBSERVE and l.held_by_god(),
		"v0.11.1: soldiers hear the god -- a soldier at his post is drawn by a lure, and held while he stares")
	var r := _soldier(crowd, 3)
	r.reassure(10.0)
	t.check(r.fearless_left > 0.0, "v0.11.1: soldiers hear the god -- a soldier is told there is nothing to fear")
	var pn := _soldier(crowd, 4)
	pn.panic(pn.ground_pos + Vector2(0.5, 0.0), 1.0)
	t.check(pn.mind == Person.Mind.PANIC and not pn.held_by_god(), "v0.11.1: soldiers hear the god -- a danger laid on a soldier frightens him (not a hold)")
	var o := _soldier(crowd, 5)
	o.observe(o.ground_pos + Vector2(3.0, 0.0))
	t.check(o.mind == Person.Mind.OBSERVE and not o.held_by_god(), "a soldier at his post looks at what he is shown (a look is not a hold)")
	# A soldier running somewhere is not idle: a lure and a look do not take him.
	var h := _soldier(crowd, 6)
	h.send_to_post(h.ground_pos + Vector2(4.0, 0.0), false, true)
	t.check(not h.lure(h.ground_pos, 5.0), "a soldier hurrying to a post is deaf to a lure")
	var ra := _soldier(crowd, 7)
	ra.send_to_post(ra.ground_pos + Vector2(4.0, 0.0), true)
	t.check(not ra.lure(ra.ground_pos, 5.0) and ra.mind == Person.Mind.RALLY, "and one on the rally ring is too")
	# A soldier never flees: not on his own, not as the town does.
	var f := _soldier(crowd, 8)
	f.flee()
	t.check(f.mind == Person.Mind.POST, "soldiers never flee")
	_done(made)


## A held soldier ends at what he was doing (mind and anchor as before the hold), within 40 s, never in a citizen's recovery or day.
static func _comes_back(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	for how in ["whisper", "confuse", "lure", "panic", "look", "compel"]:
		var s := _soldier(crowd, 0)
		var post := s.anchor
		match how:
			"whisper":
				s.whisper(grid.nearest_walkable(s.ground_pos + Vector2(3.0, 0.0)), 8.0)
			"confuse":
				s.confuse(6.0)
			"lure":
				s.lure(grid.nearest_walkable(s.ground_pos + Vector2(2.0, 0.0)), 5.0)
			"panic":
				s.panic(s.ground_pos + Vector2(0.4, 0.0), 1.0)
			"look":
				s.observe(s.ground_pos + Vector2(3.0, 0.0), 2.0)
			"compel":
				s.compel(grid.nearest_walkable(s.ground_pos + Vector2(3.0, 0.0)), 5.0, Person.WILL_FIRM, Color.WHITE)
		var passed := _let_go(s, 40.0)
		t.check(s.mind == Person.Mind.POST and s.anchor.is_equal_approx(post) and not passed.has(Person.Mind.RECOVER)
				and not passed.has(Person.Mind.CALM) and not passed.has(Person.Mind.FLEE),
			"v0.11.1: a soldier let go of a %s goes back to his post, never into a citizen's day (mind %d, passed %s)" % [how, s.mind, passed])
	_done(made)


## B2: where he goes back to is what he was doing -- a director's post, the rally ring, a duty -- not the post he was given at spawn.
static func _back_to_what_he_did(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	for how in ["director_post", "rally", "duty", "hurrying"]:
		var s := _soldier(crowd, 0)
		var spot := grid.nearest_walkable(s.ground_pos + Vector2(5.0, 1.0))
		var want := Person.Mind.POST
		match how:
			"director_post":
				s.send_to_post(spot)
			"rally":
				s.send_to_post(spot, true)
				want = Person.Mind.RALLY
			"duty":
				s.go_duty(spot)
				want = Person.Mind.DUTY
			"hurrying":
				s.send_to_post(spot, false, true)
		_arrive(s)
		s.hurrying = how == "hurrying"
		var before_hurry := s.hurrying
		s._shaken_left = 0.0
		var off := spot
		for dir in [Vector2(2.0, 0.0), Vector2(-2.0, 0.0), Vector2(0.0, 2.0), Vector2(0.0, -2.0)]:
			off = grid.nearest_walkable(spot + dir)
			if off.distance_to(spot) > 0.5:
				break
		var took := s.whisper(off, 6.0)
		t.check(took and s.anchor != spot, "(set-up) %s: whispered off (took %s, mind %d, shaken %s)" % [how, took, s.mind, s.shaken()])
		_let_go(s, 40.0)
		t.check(s.mind == want and s.anchor.is_equal_approx(spot) and s.hurrying == before_hurry and s.anchor != s.post,
			"v0.11.1: a soldier back from a whisper has the mind and anchor he had before it -- %s (mind %d, want %d)" % [how, s.mind, want])
		s.send_to_post(s.post)
	# Whispered as the town evacuates: never flees.
	var e := _soldier(crowd, 1)
	e.whisper(grid.nearest_walkable(e.ground_pos + Vector2(2.0, 0.0)), 6.0)
	crowd._evacuate()
	var passed := _let_go(e, 40.0)
	t.check(e.mind == Person.Mind.POST and not passed.has(Person.Mind.FLEE), "a soldier whispered as the town evacuates never flees")
	# A second hold keeps the first's memory: whispered, then confused, then back where he was.
	var d := _soldier(crowd, 2)
	var spot := grid.nearest_walkable(d.ground_pos + Vector2(4.0, 0.0))
	d.send_to_post(spot)
	d.whisper(grid.nearest_walkable(spot + Vector2(2.0, 0.0)), 6.0)
	d.confuse(4.0)
	_let_go(d, 40.0)
	t.check(d.mind == Person.Mind.POST and d.anchor.is_equal_approx(spot), "a hold laid on a hold goes back to what he did before the first")
	_done(made)


static func _powers(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var grid: WalkGrid = made[4]
	var s := _soldier(crowd, 0)
	var at := s.ground_pos
	for q: Person in crowd.citizens + crowd.soldiers:
		if q != s:
			q.ground_pos = Vector2(-27.0, -27.0) + Vector2(float(q.get_instance_id() % 40) * 0.3, float(q.get_instance_id() % 7) * 0.5)
	t.check(MindWhisperFx.pick(field, at) == s, "v0.11.1: soldiers hear the god -- Mind Whisper picks a soldier")
	t.check(DiscordFx.taken(field, at).has(s), "Discord takes a soldier")
	t.check(WillOWisp.drawn(field, at).has(s), "a Wisp draws a soldier at his post")
	t.check(not CongregationFx.RESISTANCE.has(&"soldier"), "Congregation: no soldier resistance")
	t.check(not CongregationFx.resists(s, RandomNumberGenerator.new()), "and a soldier never shrugs the gathering off")
	# Rules.cast() of a whisper on a soldier is not refused.
	var rules := Rules.new().setup(PackedStringArray(["whisper", "heaven"]), null, made[1], field, crowd, made[5])
	rules.caster = func(_script: GDScript, ground: Vector2, extra: Dictionary) -> FxTimeline:
		var who: Person = extra.get("target", MindWhisperFx.pick(field, ground))
		if who != null:
			who.whisper(extra.get("to", ground), MindWhisperFx.LINGER)
		return null
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, reason: String): refused.append([slot, reason]))
	var to := MindWhisperFx.clamp_to(grid, at, at + Vector2(3.0, 1.0))
	rules.cast(0, at, {"to": to, "target": s})
	t.check(refused.is_empty() and s.mind == Person.Mind.WHISPERED, "Rules: a whisper on a soldier is not refused (%s)" % [refused])
	rules.teardown()
	rules.free()
	# Collective Delusion's calm reaches a frightened soldier, who goes back to his post.
	var f := _soldier(crowd, 1)
	f.panic(f.ground_pos + Vector2(0.4, 0.0), 1.0)
	f.reassure(10.0)
	t.check(f.mind == Person.Mind.POST and f.fearless_left > 0.0, "calm takes a frightened soldier back to his post")
	# The power's fright reaches soldiers; the same fright from Madness's outbreak does not.
	var g := _soldier(crowd, 2)
	var h := _soldier(crowd, 3)
	g.ground_pos = Vector2(1.0, 2.0)
	h.ground_pos = Vector2(1.2, 2.0)
	crowd.fright(Vector2(1.0, 2.0), 1.5, 0.5, 4.0, 6.0, 6.0, &"delusion")
	t.check(g.mind == Person.Mind.PANIC and h.mind == Person.Mind.PANIC, "v0.11.1: a power's fright (Collective Delusion) panics the soldiers it reaches")
	for p in [g, h]:
		(p as Person).send_to_post((p as Person).post)
	g.fearless_left = 0.0
	crowd.fright(Vector2(1.0, 2.0), 1.5, 0.5, 4.0, 6.0, 6.0, &"frenzy", false)
	t.check(g.mind == Person.Mind.POST, "Madness's outbreak (soldiers_too false) leaves the soldier to engage it")
	# Rewrite Priority's Escape: a soldier is compelled toward the nearest way out and stays in the town.
	var ctx := FxContext.new()
	ctx.env = made[1]
	ctx.field = field
	ctx.crowd = crowd
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	var k := _soldier(crowd, 4)
	var fx: RewritePriorityFx = FxTimeline.cast(load("res://src/fx/dominion/rewrite_priority.gd"), ctx, k.ground_pos, {"mode": "escape"})
	fx._process(RewritePriorityFx.T_CAST + 0.1)
	t.check(k.mind == Person.Mind.COMPELLED and k.has_goal() and crowd.soldiers.has(k) and k.goal().distance_to(grid.nearest_exit(k.ground_pos)) < 3.0,
		"v0.11.1: Rewrite Priority's Escape sends a soldier to the nearest way out's mouth; he is still a soldier of the town")
	fx.free()
	ctx.overhead.free()
	ctx.ground.free()
	_done(made)


static func _town_unchanged(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var s := _soldier(crowd, 0)
	s.ground_pos = Vector2(1.0, 2.0)
	crowd.on_cast(s.ground_pos, Vector2.ZERO, 0.0, "smite")
	t.check(s.mind == Person.Mind.POST, "an ordinary cast's danger leaves a soldier at his post (the god must reach his mind on purpose)")
	var before := s.mind
	s.flee()
	s.regroup(Vector2.ZERO)
	t.check(s.mind == before, "flee() and regroup() still do nothing to a soldier")
	_done(made)


## Person.resists_mind(): one override, and the god's hold misses him whatever its door.
static func _hook(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var grid: WalkGrid = made[4]
	var strong := Strong.new()
	strong.setup_person(true, Vector2(2.0, 3.0), grid)
	field.add(strong)
	(made[2] as Node).add_child(strong)
	t.check(strong.resists_mind() and not _soldier(crowd, 0).resists_mind(), "(set-up) one person resists, nobody else")
	var before := strong.mind
	t.check(not strong.whisper(Vector2(3.0, 3.0), 5.0) and not strong.lure(Vector2(3.0, 3.0), 5.0)
			and not strong.compel(Vector2(3.0, 3.0), 5.0, Person.WILL_FIRM, Color.WHITE), "resists_mind(): whisper, lure and compel are refused")
	strong.confuse(5.0)
	strong.panic(strong.ground_pos + Vector2(0.3, 0.0), 1.0)
	strong.observe(strong.ground_pos + Vector2(2.0, 0.0))
	strong.reassure(5.0)
	t.check(strong.mind == before and strong.fearless_left == 0.0, "and so are Discord, a fright, a look and calm: his mind is unchanged")
	t.check(MindWhisperFx.pick(field, strong.ground_pos) == null or MindWhisperFx.pick(field, strong.ground_pos) != strong,
		"Mind Whisper's pick skips him")
	t.check(not DiscordFx.taken(field, strong.ground_pos).has(strong) and not WillOWisp.drawn(field, strong.ground_pos).has(strong),
		"Discord and the Wisp skip him")
	field.remove(strong)
	strong.free()
	_done(made)


## One check per manager that re-takes soldiers: the soldier the god holds is not taken back while the hold lasts.
static func _held_soldier(t) -> void:
	_held_escorts(t)
	_held_rescue(t)
	_held_engineers(t)
	_held_warning(t)
	_held_report(t)
	_held_tax(t)
	_held_escort_director(t)
	_held_recall(t)
	_held_heart(t)


static func _held_escorts(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	crowd.bell.call_keeper()
	crowd.escorts.step(1.0)
	var guards: Array = crowd.escorts.guards.get("bell", [])
	t.check(not guards.is_empty(), "(set-up) the bell has escorts")
	var g: Person = guards[0]
	_arrive(g)
	g.hurrying = false
	g.whisper(grid.nearest_walkable(g.ground_pos + Vector2(4.0, 0.0)), 8.0)
	crowd.escorts.step(1.0)
	t.check(g.mind == Person.Mind.WHISPERED, "_held_soldier: the escort manager leaves a whispered escort be")
	var g2: Person = guards[1] if guards.size() > 1 else guards[0]
	if g2 != g:
		_arrive(g2)
		g2.hurrying = false
		g2.confuse(8.0)
		crowd.escorts.step(1.0)
		t.check(g2.mind == Person.Mind.CONFUSED, "and a confused one")
	_done(made)


static func _held_rescue(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	var sq: Dictionary = crowd.rescue.squads[0]
	var m: Person = sq.members[0]
	_arrive(m)
	m.hurrying = false
	m.whisper(grid.nearest_walkable(m.ground_pos + Vector2(4.0, 0.0)), 8.0)
	crowd.rescue.step(1.0)
	t.check(m.mind == Person.Mind.WHISPERED, "_held_soldier: the rescue manager leaves a whispered rescuer be")
	_done(made)


static func _held_engineers(t) -> void:
	var made := _crowd(ResponseProfile.Tier.PREPARED)
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	var e := crowd.engineers
	var house: Structure = null
	for st in (made[1] as EnvironmentField).structures():
		if st.role == &"house" and st.art_tag == &"" and (house == null
				or st.center().distance_to(e.base) < house.center().distance_to(e.base)):
			house = st
	house.hp = house.max_hp * 0.4
	e.begin()
	e.step(0.1)
	var team: Dictionary = e.teams[0]
	var s := _soldier(crowd, 0)
	team.members[0] = s
	s.go_duty(team.spots[0])
	_arrive(s)
	s.whisper(grid.nearest_walkable(s.ground_pos + Vector2(4.0, 0.0)), 8.0)
	e.step(0.5)
	e.step(0.5)
	t.check(s.mind == Person.Mind.WHISPERED, "_held_soldier: the engineers' team leaves a whispered soldier member be")
	_done(made)


static func _held_warning(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	var w := WarningDirector.new()
	var s := _soldier(crowd, 0)
	s.lure(grid.nearest_walkable(s.ground_pos + Vector2(2.0, 0.0)), 5.0)
	t.check(not w._resumable(s), "_held_soldier: a warning's relay does not re-send a soldier staring at a lure")
	var calm := _soldier(crowd, 1)
	calm.mind = Person.Mind.RALLY
	t.check(w._resumable(calm), "but a soldier under any other order is re-sent as before")
	_done(made)


static func _held_report(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	var door := grid.nearest_walkable(Vector2(TownLayout.TEMPLE.get_center().x, TownLayout.TEMPLE.end.y + 0.6))
	var s := _soldier(crowd, 0)
	var r := TempleReport.new(s, door)
	t.check(s.mind == Person.Mind.DUTY, "(set-up) the soldier carries the report")
	s.whisper(grid.nearest_walkable(s.ground_pos + Vector2(3.0, 0.0)), 8.0)
	r._send(true)
	r._send(false)
	t.check(s.mind == Person.Mind.WHISPERED, "_held_soldier: a temple report does not re-send a whispered soldier carrier")
	_done(made)


static func _held_tax(t) -> void:
	var s := Kit.world(MissionBook.tax_collector())
	var d: TaxCollectorDirector = s.d
	var q: AssassinateDirector.Quarry = d.quarries[0]
	var guard: Person = q.guards[0]
	Kit.run_for(s, 0.5)
	var lured := guard.lure(guard.ground_pos + Vector2(2.0, 0.0), 6.0)
	guard.anchor = guard.ground_pos + Vector2(20.0, 0.0)  # his place has moved on: he would be sent to it
	var other: Person = q.guards[1] if q.guards.size() > 1 else null
	d._send_guards()
	t.check(lured and guard.mind == Person.Mind.OBSERVE, "_held_soldier: a tax collector's guard staring at a lure is not sent back to his ring")
	if other != null:
		other.anchor = other.ground_pos + Vector2(20.0, 0.0)
		d._send_guards()
		t.check(other.anchor.distance_to(other.ground_pos) < 19.0, "(control) a guard not held is sent to his place")
	Kit.done(s)


static func _held_escort_director(t) -> void:
	var s := Kit.world(MissionBook.lost_lamb())
	var d: EscortDirector = s.d
	var crowd: Crowd = s.crowd
	var sol := _soldier(crowd, 3)
	t.check(d._takes_post(sol) and d._watching(sol), "(set-up) a soldier at his post takes a post and watches")
	sol.lure(sol.ground_pos + Vector2(2.0, 0.0), 6.0)
	t.check(not d._takes_post(sol) and not d._watching(sol),
		"_held_soldier: a soldier staring at a lure is not taken back to a post by the escort director, and sees nothing")
	Kit.done(s)


static func _held_recall(t) -> void:
	var s := Kit.world(MissionBook.armoury())
	var d: ArmouryDirector = s.d
	var crowd: Crowd = s.crowd
	var a := _soldier(crowd, 5)
	a.observe(a.ground_pos + Vector2(2.0, 0.0), 6.0)
	var spot: Vector2 = d.faces[0]
	d._recall_to(a, spot)
	t.check(a.mind == Person.Mind.DUTY, "(control) a soldier merely looking is called back on duty")
	var b := _soldier(crowd, 6)
	b.lure(b.ground_pos + Vector2(2.0, 0.0), 6.0)
	d._recall_to(b, spot)
	t.check(b.mind == Person.Mind.OBSERVE, "_held_soldier: a director's recall leaves a soldier staring at a lure be")
	Kit.done(s)


static func _held_heart(t) -> void:
	var s := Kit.world(MissionBook.heart_of_faith())
	var d: HeartOfFaithDirector = s.d
	d._open(0)
	d._raze(d.targets[0])
	d._open(1)
	d._raze(d.targets[1])
	Kit.run_for(s, DT)
	d._odran_comes()
	Kit.run_for(s, 1.0)
	var bearer: Person = (d.bearers[0] as HeartOfFaithDirector.Post).man
	t.check(d.riding and bearer.mind == Person.Mind.DUTY, "(set-up) the litter is carried on duty")
	bearer.whisper(bearer.ground_pos + Vector2(2.0, 0.0), 8.0)
	Kit.run_for(s, HeartOfFaithDirector.TICK + DT)
	Kit.run_for(s, HeartOfFaithDirector.TICK + DT)
	t.check(bearer.mind == Person.Mind.WHISPERED, "_held_soldier: the Heart's litter does not put a whispered bearer back on duty")
	Kit.done(s)
