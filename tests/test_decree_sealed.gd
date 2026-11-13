extends RefCounted
## The Sealed Verdict (Decree, Tier V; spec 5.10): a district of 10 is written into the brass ledger. Only the player sees
## its circle and countdown (the god's overlay); the town sees nothing -- no alarm, no fright, nobody's mind changes, no
## law for its choices to ask -- and goes on, walking in and out. At 30 s the bell strikes once, and everyone inside at
## that moment dies in the same frame, where he stands, without a cry (kill kind verdict): out of doors, sheltering in a
## house inside the circle (brought out at its door), or kept at home for the night. Then the bodies are found like any
## other dead. Who dies is where each stands at the stroke, never a roll.

const PATH := "res://src/fx/decree/the_sealed_verdict.gd"
const DT := 0.1
## Ground east of the market: the verdict is written round C.
const C := Vector2(17.0, -4.0)


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
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return [crowd, env, grid, field, world, ctx, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


## The effect's frames, DT at a time, until its clock reads `until`.
static func _run_to(fx: FxTimeline, until: float) -> void:
	while fx.t < until - 0.001 and not fx.finished:
		fx._process(DT)


## Everyone in the town set down far from C, in a block of their own.
static func _away(crowd: Crowd) -> void:
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1


## `p` taken indoors where he stands, out of the field, as NightRules keeps one at home (night) or a director holds one.
static func _indoors(field: EnemyField, p: Person, at: Vector2, night: bool) -> void:
	p.ground_pos = at
	p.inside = true
	p.night_indoors = night
	p.visible = false
	field.remove(p)


static func run(t) -> void:
	var b := PowerBook.get_power("sealed")
	var area: Dictionary = Targeting.AREAS.get("sealed", {})
	t.check(String(b.get("name", "")) == "The Sealed Verdict" and int(b.get("dp", 0)) == 6 and float(b.get("cooldown", 0.0)) == 999.0
		and String(b.get("aim", "")) == "click" and PowerBook.is_quiet("sealed") and PowerBook.authority_of("sealed") == "decree"
		and ResourceLoader.exists(String(b.get("path", ""))) and String(area.get("shape", "")) == "circle"
		and is_equal_approx(float(area.get("r", 0.0)), 10.0) and Rules.POWER_KINDS.get("sealed", null) == [&"verdict"]
		and PowerBook.family("sealed") == "decree" and not PowerBook.REACH.has("sealed") and not PowerBook.IMPACT.has("sealed")
		and String(b.get("shape", "")).contains("once a descent"),
		"The Sealed Verdict: Decree, 6 Might, once a descent, a click, quiet, a circle of 10, kills by verdict (%s)" % [b])
	t.check(DeathVoices.QUIET_KINDS.has(&"verdict"), "a verdict's dead fall without a cry")
	t.check(Sfx.CATALOG.has(&"q_sealed") and Sfx.CATALOG.has(&"q_sealed_hit"), "its cues: the writing and the bell's stroke")
	var sf = load(PATH) if ResourceLoader.exists(PATH) else null
	if sf == null:
		t.check(false, "the effect script loads")
		return
	t.check(is_equal_approx(sf.RADIUS, 10.0) and is_equal_approx(sf.COUNTDOWN, 30.0) and sf.KIND == &"verdict",
		"a district of 10, struck at 30 s")
	_quiet(t, sf)
	_stroke(t, sf)
	_cut_short(t, sf)


## The cast: the town sees nothing over 29 s.
static func _quiet(t, sf) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	_away(crowd)
	var near: Array[Person] = []
	for k in 6:
		var p: Person = crowd.citizens[k]
		p.ground_pos = C + Vector2.from_angle(float(k)) * (1.0 + float(k))
		near.append(p)
	var guard: Person = crowd.soldiers[0]
	guard.ground_pos = C + Vector2(0.0, 3.0)
	near.append(guard)
	var minds := {}
	for p in crowd.citizens + crowd.soldiers:
		minds[p] = p.mind
	var alarm := crowd.alarm
	var stage := crowd.alarms.stage
	var killed := crowd.killed_citizens + crowd.killed_soldiers
	crowd.on_cast(C, Vector2.ZERO, 0.0, "sealed")  # what Rules.cast tells the town of every cast
	var fx = FxTimeline.cast(sf, ctx, C)
	_run_to(fx, 29.0)
	var changed := 0
	for p in minds:
		if p.mind != minds[p]:
			changed += 1
	t.check(is_equal_approx(crowd.alarm, alarm) and crowd.alarms.stage == stage and crowd.threats.nearby(C, 30.0).is_empty(),
		"the writing adds no alarm and no danger over 29 s (alarm %.2f -> %.2f)" % [alarm, crowd.alarm])
	t.check(changed == 0 and crowd.laws.is_empty() and crowd.killed_citizens + crowd.killed_soldiers == killed,
		"and nobody's mind changes, no law is laid for the town to ask, nobody dies (%d changed)" % changed)
	var alive := true
	for p in near:
		alive = alive and p.is_alive()
	t.check(alive and not fx.struck and absf(fx.left() - 1.0) < 0.01, "the ledger counts down: 1 s left at 29 s (%.2f)" % fx.left())
	fx.end_now()
	_done(made)


## The stroke: whoever is inside at 30 s dies in that one frame; whoever left lives; then the town finds them.
static func _stroke(t, sf) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	_away(crowd)
	var stayer: Person = crowd.citizens[0]  # inside all along
	var walker: Person = crowd.citizens[1]  # outside at the cast, walks in at 15 s
	var leaver: Person = crowd.citizens[2]  # inside at the cast, walks out at 25 s
	var far: Person = crowd.citizens[3]  # outside all along, just past the edge
	var edge: Person = crowd.citizens[4]  # on the edge itself
	var sheltered: Person = crowd.citizens[5]  # in a house inside the circle
	var home: Person = crowd.citizens[6]  # kept at home for the night, inside the circle
	var held: Person = crowd.citizens[7]  # held indoors by a director: untouchable until brought out
	var guard: Person = crowd.soldiers[0]  # a soldier inside
	stayer.ground_pos = C + Vector2(0.4, 0.2)
	walker.ground_pos = C + Vector2(0.0, 12.0)
	leaver.ground_pos = C + Vector2(-6.0, 0.0)
	far.ground_pos = C + Vector2(10.3, 0.0)
	edge.ground_pos = C + Vector2(0.0, -10.0 + 0.001)
	guard.ground_pos = C + Vector2(3.0, -4.0)
	var house := env.add_structure(Rect2(C + Vector2(4.5, 2.5), Vector2(1.0, 1.0)), 30.0, Structure.Kind.HOUSE, &"house")
	crowd.shelters.shelters[house] = {"inside": [], "coming": [], "clear": 0.0}
	sheltered.ground_pos = house.center()
	crowd.shelters._enter(sheltered, house)
	(crowd.shelters.shelters[house].inside as Array).append(sheltered)
	_indoors(field, home, C + Vector2(-2.0, 5.0), true)
	_indoors(field, held, C + Vector2(2.0, 5.0), false)
	var visitors := Visitors.new().setup(field, crowd, grid, made[4])
	var hound := visitors.summon(C + Vector2(1.0, -1.0), Animal.Breed.HELLHOUND, 3, 1.0, 8.0, 0.5, 1.0)
	var deaths: Array = []
	field.enemy_killed.connect(func(e: DummyEnemy, kind: StringName) -> void: deaths.append([e, kind, fx_t(ctx)]))
	var alarm := crowd.alarm

	var fx = FxTimeline.cast(sf, ctx, C)
	_run_to(fx, 15.0)
	walker.ground_pos = C + Vector2(0.0, 4.0)  # walks in
	_run_to(fx, 25.0)
	leaver.ground_pos = C + Vector2(-11.0, 0.0)  # walks out
	_run_to(fx, sf.COUNTDOWN - DT)
	t.check(deaths.is_empty() and not fx.struck and stayer.is_alive() and walker.is_alive() and sheltered.inside
		and fx.t < sf.COUNTDOWN, "nobody dies before the stroke (%d dead at %.2f s)" % [deaths.size(), fx.t])
	fx._process(DT * 1.5)  # the frame the clock passes 30 s
	var frame_t: float = fx.t
	t.check(fx.struck, "the bell strikes once at 30 s")
	t.check(not stayer.is_alive() and not walker.is_alive() and not guard.is_alive() and not edge.is_alive(),
		"whoever stands inside at 30 s dies: one inside all along, one who walked in at 15 s, a soldier, one on the edge")
	t.check(leaver.is_alive() and far.is_alive() and held.is_alive() and hound.is_alive(),
		"one who walked out at 25 s lives; so does one just past the edge, one a director holds indoors, and a hound")
	t.check(not sheltered.is_alive() and not sheltered.inside and sheltered.visible and sheltered.ground_pos.distance_to(house.center()) > 0.4
		and not (crowd.shelters.shelters[house].inside as Array).has(sheltered),
		"one sheltering in a house inside the circle is brought out at its door and dies there, for the town to find")
	t.check(not home.is_alive(), "one kept at home for the night inside the circle dies at home")
	var same := true
	var kinds_ok := true
	for d in deaths:
		same = same and is_equal_approx(float(d[2]), frame_t)
		kinds_ok = kinds_ok and d[1] == &"verdict"
	t.check(deaths.size() == 6 and fx.dead == 6 and same and kinds_ok,
		"all six die in the same frame, by verdict (%d deaths, %d counted)" % [deaths.size(), fx.dead])
	t.check(crowd.alarm > alarm, "then the bodies are found like any other dead: the town's alarm rises (%.2f -> %.2f)" % [alarm, crowd.alarm])
	var before := deaths.size()
	_run_to(fx, sf.COUNTDOWN + 0.5)
	far.ground_pos = C
	_run_to(fx, fx.duration + 0.2)
	t.check(deaths.size() == before and far.is_alive() and fx.finished, "the verdict is carried out once: one who walks in after lives")
	visitors.clear()
	_done(made)


## Cut short (an act of the night ends) before the stroke: nobody dies.
static func _cut_short(t, sf) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	_away(crowd)
	var p: Person = crowd.citizens[0]
	p.ground_pos = C
	var fx = FxTimeline.cast(sf, ctx, C)
	_run_to(fx, 15.0)
	fx.end_now()
	for i in 400:
		fx._process(DT)
	t.check(p.is_alive() and not fx.struck, "cut short before the stroke, the verdict is never carried out")
	_done(made)


## The clock of the one verdict the test runs (read by the deaths recorder).
static func fx_t(ctx: FxContext) -> float:
	for c in ctx.overhead.get_children():
		if c is FxTimeline:
			return (c as FxTimeline).t
	return -1.0
