extends RefCounted
## Shadow Play (Veil, Tier 4): everyone in the open within 3.0 (light) / 6.0 (dark) at T_RISE becomes their own shadow for 30 s
## (statuses[&"shadow"]). A shadow keeps its task and its post, witnesses nothing, fights, chases and seizes nobody; Dreamless takes its
## owner at once. At the end (light) each lies down a moment where the shadow stopped and is himself again, mind as before; (dark) the
## soldiers among them are taken (&"shade", no remain) and the citizens wake. The dead are skipped; teardown lifts every status and takes
## nobody; two casts never undo each other; quiet; the dusk; through Rules the other slots unlock at T_RISE; no crowd.

const FxStage := preload("res://tests/fx_stage.gd")


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
	crowd.dusk.enabled = true
	crowd.remains.enabled = true
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	_away(crowd, [])
	for person in crowd.citizens + crowd.soldiers:
		person.mind = Person.Mind.CALM
	return [crowd, env, grid, field, world, ctx, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


static func _cast(ctx: FxContext, at: Vector2, dark: bool) -> ShadowPlayFx:
	return FxTimeline.cast(load("res://src/fx/veil/shadow_play.gd"), ctx, at, {"dark": dark}) as ShadowPlayFx


## Everyone but `keep` goes far from the test ground (a corner of the map), awake, calm, no status.
static func _away(crowd: Crowd, keep: Array) -> void:
	var i := 0
	for p: Person in crowd.citizens + crowd.soldiers:
		if not keep.has(p) and is_instance_valid(p) and p.is_alive():
			p.ground_pos = Vector2(-28.0 + float(i % 20) * 0.3, 27.0 + float(i / 20) * 0.3)
			p.statuses.erase(&"shadow")
		i += 1


## A living, ordinary guard (corps NONE, a town post), not one of `not_these`.
static func _guard(crowd: Crowd, not_these: Array) -> Person:
	for s: Person in crowd.soldiers:
		if is_instance_valid(s) and s.is_alive() and s.corps == Person.Corps.NONE and s.town_post != Vector2.INF and s.post_group >= 0 and s.post_group < 3 \
				and not not_these.has(s):
			return s
	return null


## Puts `s` at his own post, at rest there (Mind.POST, no goal left).
static func _posted(s: Person) -> void:
	s.ground_pos = s.town_post
	s.send_to_post(s.town_post)
	for i in 20:
		s.tick(0.05)


static func _held_posts(crowd: Crowd) -> int:
	var n := 0
	for s: Person in crowd.soldiers:
		if crowd.guard_jobs.at_post(s):
			n += 1
	return n


static func run(t) -> void:
	var b := PowerBook.get_power("shadowplay")
	t.check(not b.is_empty() and PowerBook.authority_of("shadowplay") == "veil" and ResourceLoader.exists(String(b.path))
		and ShadowPlayFx.SPAN == 30.0 and ShadowPlayFx.T_RISE == 1.0 and ShadowPlayFx.KEY == &"shadow"
		and VeilRules.size("shadowplay", "RADIUS", false) == 3.0 and VeilRules.size("shadowplay", "RADIUS", true) == 6.0,
		"Shadow Play is a Veil power with its effect and its constants (30 s, rise 1.0, key shadow, r 3 / 6)")

	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var kinds: Array[StringName] = []
	field.enemy_killed.connect(func(_e: DummyEnemy, kind: StringName) -> void: kinds.append(kind))
	var c: Array = crowd.citizens

	_who(t, made, at, c)
	_post(t, made, kinds)
	_witness(t, made, at, c)
	_no_fight(t, made, at, c)
	_dreamless(t, made, at, c, kinds)
	_end_light(t, made, at, c, kinds)
	_end_dark(t, made, at, c, kinds)
	_teardown(t, made, at, c, kinds)
	_two_casts(t, made, at, c)
	_quiet(t, made, at, c)
	_rules(t, made, at)
	await _staged(t, made, at, c)
	_done(made)
	_bare(t)


# --- who: everyone within 3.0 (light) / 6.0 (dark) at T_RISE, nobody before; for 30 s
static func _who(t, made: Array, at: Vector2, c: Array) -> void:
	var crowd: Crowd = made[0]
	var a: Person = c[0]
	var out: Person = c[1]
	var late: Person = c[2]
	var inn: Person = c[3]
	var s: Person = crowd.soldiers[0]
	_away(crowd, [a, out, late, inn, s])
	a.ground_pos = at + Vector2(2.9, 0.0)
	out.ground_pos = at + Vector2(3.1, 0.0)
	late.ground_pos = at + Vector2(8.0, 0.0)
	inn.ground_pos = at + Vector2(0.5, 0.0)
	inn.inside = true
	s.ground_pos = at + Vector2(0.0, 1.0)
	var fx := _cast(ctx_of(made), at, false)
	t.check(not a.is_shadow() and not s.is_shadow(), "at the cast: nobody is a shadow yet")
	late.ground_pos = at + Vector2(0.0, -2.0)  # walked in before the shadows rise: decided at T_RISE
	fx._process(ShadowPlayFx.T_RISE + 0.05)
	t.check(a.is_shadow() and s.is_shadow() and late.is_shadow() and not out.is_shadow() and not inn.is_shadow() and fx.shadows == 3,
		"light: everyone in the open within 3.0 at T_RISE is a shadow, soldier too; 3.1 and the indoors not (%d)" % fx.shadows)
	t.check(a.is_alive() and a.visible, "a shadow's owner is alive and drawn (as his shadow)")
	fx._process(ShadowPlayFx.SPAN - 0.2)
	t.check(a.is_shadow() and s.is_shadow(), "still shadows just before 30 s")
	fx._process(0.4)
	t.check(not a.is_shadow() and not s.is_shadow() and not late.is_shadow() and fx.finished, "after 30 s they are shadows no more")
	fx.free()
	inn.inside = false
	crowd.dusk.clear()
	# Dark: within 6.0.
	_away(crowd, [a, out])
	a.ground_pos = at + Vector2(5.9, 0.0)
	out.ground_pos = at + Vector2(6.1, 0.0)
	var dk := _cast(ctx_of(made), at, true)
	dk._process(ShadowPlayFx.T_RISE + 0.05)
	t.check(a.is_shadow() and not out.is_shadow(), "dark: within 6.0 a shadow, 6.1 not")
	dk.end_now()
	dk.free()
	crowd.dusk.clear()


static func ctx_of(made: Array) -> FxContext:
	return made[5]


# --- a shadow keeps its goal and its post: the guard is at it after 10 s; the post count and a director's busy() unchanged
static func _post(t, made: Array, kinds: Array[StringName]) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var s := _guard(crowd, [])
	t.check(s != null, "(a town guard with a post)")
	if s == null:
		return
	_away(crowd, [s])
	_posted(s)
	var walker: Person = crowd.citizens[4]
	walker.ground_pos = grid.nearest_walkable(s.ground_pos + Vector2(1.0, 1.0))
	walker.mind = Person.Mind.CALM
	walker.walk_speed = 1.0
	var far := grid.nearest_walkable(walker.ground_pos + Vector2(6.0, 0.0))
	walker.set_goal(far)
	var dir := AssassinateDirector.new()
	var q := AssassinateDirector.Quarry.new()
	q.guards.append(s)
	dir.quarries.append(q)
	var held := _held_posts(crowd)
	var busy := dir.busy(s)
	t.check(s.at_own_post() and crowd.guard_jobs.at_post(s) and held >= 1 and busy, "(the guard stands at his post; the director counts him)")
	var fx := _cast(ctx_of(made), s.ground_pos, false)
	fx._process(ShadowPlayFx.T_RISE + 0.05)
	t.check(s.is_shadow() and walker.is_shadow() and walker.has_goal() and walker.mind == Person.Mind.CALM,
		"the shadow keeps its goal and its mind")
	var from := walker.ground_pos
	for i in 100:
		s.tick(0.1)
		walker.tick(0.1)
		fx._process(0.1)
	t.check(s.is_shadow() and s.at_own_post() and s.mind == Person.Mind.POST and crowd.guard_jobs.at_post(s),
		"after 10 s the shadow guard is still at his post")
	t.check(_held_posts(crowd) == held and dir.busy(s) == busy, "the posts held and the director's busy() are unchanged (%d)" % held)
	t.check(walker.ground_pos.distance_to(from) > 0.5, "the walker's shadow went on along his way (%.2f)" % walker.ground_pos.distance_to(from))
	t.check(kinds.is_empty(), "nobody died")
	fx.end_now()
	fx.free()
	crowd.dusk.clear()


# --- a shadow witnesses nothing: a Silent Doom death 1.0 from a shadow guard is unseen; an ordinary guard there sees it
static func _witness(t, made: Array, at: Vector2, c: Array) -> void:
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var g := _guard(crowd, [])
	var v: Person = c[5]
	var v2: Person = c[6]
	_away(crowd, [g, v])
	g.ground_pos = at
	g.send_to_post(at)
	var fx := _cast(ctx_of(made), at, false)
	fx._process(ShadowPlayFx.T_RISE + 0.05)
	v.ground_pos = at + Vector2(1.0, 0.0)  # the victim stepped in after the rise: not a shadow
	t.check(g.is_shadow() and not v.is_shadow(), "(the guard is a shadow; the victim is not)")
	var alarm := crowd.alarm
	var dangers := crowd.threats.active_count()
	t.check(crowd.nearest_witness(v.ground_pos, v) == null, "the shadow guard is nobody's witness")
	field.kill(v, &"doom")
	crowd._settle_doom()
	t.check(not v.is_alive() and crowd.alarm == alarm and crowd.threats.active_count() == dangers,
		"a Silent Doom death 1.0 from a shadow guard settles unseen: no alarm, no danger")
	fx.end_now()
	fx.free()
	# Control: the same guard, himself, at the same distance, sees it.
	_away(crowd, [g, v2])
	g.ground_pos = at
	v2.ground_pos = at + Vector2(1.0, 0.0)
	t.check(not g.is_shadow() and crowd.nearest_witness(v2.ground_pos, v2) == g, "(control: the ordinary guard is the witness)")
	alarm = crowd.alarm
	field.kill(v2, &"doom")
	crowd._settle_doom()
	t.check(crowd.alarm > alarm, "control: an ordinary guard there sees it, and the alarm rises")
	crowd.threats.clear()
	crowd.dusk.clear()


# --- a shadow soldier does not fight, chase or seize
static func _no_fight(t, made: Array, at: Vector2, c: Array) -> void:
	var crowd: Crowd = made[0]
	var s := _guard(crowd, [])
	var foe: Person = c[7]
	_away(crowd, [s, foe])
	s.ground_pos = at
	s.send_to_post(at)
	var fx := _cast(ctx_of(made), at, false)
	fx._process(ShadowPlayFx.T_RISE + 0.05)
	foe.ground_pos = at + Vector2(1.0, 0.0)
	t.check(s.is_shadow() and not foe.is_shadow(), "(the soldier is a shadow; the foe stepped in after)")
	s.fight(foe, 10.0, 0.5)
	t.check(s.mind != Person.Mind.FIGHT, "a shadow soldier takes no fight")
	s.observe(foe.ground_pos)
	s.panic(foe.ground_pos, 1.0, &"lightning")
	t.check(s.mind == Person.Mind.POST and s.fight_target == null, "nor goes to look or runs after anything")
	t.check(MissionDirector._blind_veil(s), "and seizes no one (a mission's watch reads him as blind)")
	fx.end_now()
	fx.free()
	t.check(not s.is_shadow() and not MissionDirector._blind_veil(s), "control: himself again, he would seize")
	s.fight(foe, 10.0, 0.5)
	t.check(s.mind == Person.Mind.FIGHT, "control: himself again, he fights")
	s.stop_fighting()
	crowd.dusk.clear()


# --- Dreamless on a shadow takes its owner at once; someone who dies while a shadow is skipped at the end
static func _dreamless(t, made: Array, at: Vector2, c: Array, kinds: Array[StringName]) -> void:
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var a: Person = c[8]
	var d: Person = c[9]
	var keep: Person = c[10]
	_away(crowd, [a, d, keep])
	a.ground_pos = at + Vector2(0.3, 0.0)
	d.ground_pos = at + Vector2(2.0, 0.0)
	keep.ground_pos = at + Vector2(0.0, 2.0)
	var fx := _cast(ctx_of(made), at, false)
	fx._process(ShadowPlayFx.T_RISE + 0.05)
	t.check(a.is_shadow() and d.is_shadow() and keep.is_shadow(), "(three shadows)")
	kinds.clear()
	var rem := crowd.remains.all().size()
	var dl := FxTimeline.cast(load("res://src/fx/veil/dreamless.gd"), ctx_of(made), a.ground_pos, {"dark": false}) as DreamlessFx
	dl._process(DreamlessFx.T_SIT + 0.05)
	t.check(not a.is_alive() and kinds == [&"dreamt"] and crowd.remains.all().size() == rem,
		"Dreamless on a shadow takes its owner at once (dreamt, no remain; %s)" % str(kinds))
	dl.end_now()
	dl.free()
	field.kill(d, &"smite")
	fx._process(ShadowPlayFx.SPAN)
	t.check(fx.finished and not keep.is_shadow() and keep.is_alive() and not d.is_alive() and not a.is_alive() and fx.lain == 1,
		"at the end the dead are skipped without an error; the living one is himself again (%d)" % fx.lain)
	fx.free()
	crowd.dusk.clear()


# --- the end in the light: every shadow a person again, alive, lying a moment where the shadow stopped, mind as before
static func _end_light(t, made: Array, at: Vector2, c: Array, kinds: Array[StringName]) -> void:
	var crowd: Crowd = made[0]
	var cit: Person = c[11]
	var s := _guard(crowd, [])
	_away(crowd, [cit, s])
	cit.ground_pos = at + Vector2(0.5, 0.0)
	cit.mind = Person.Mind.CALM
	s.ground_pos = at + Vector2(0.0, 0.5)
	s.send_to_post(s.ground_pos)
	for i in 10:
		s.tick(0.05)
	var minds := [cit.mind, s.mind]
	kinds.clear()
	var fx := _cast(ctx_of(made), at, false)
	fx._process(ShadowPlayFx.T_RISE + 0.05)
	t.check(cit.is_shadow() and s.is_shadow() and cit.self_modulate != Color.WHITE, "(two shadows, drawn dark)")
	fx._process(ShadowPlayFx.SPAN - 0.5)
	cit.ground_pos = at + Vector2(1.2, 0.3)  # where the shadow stopped
	var stopped := [cit.ground_pos, s.ground_pos]
	fx._process(1.0)
	t.check(fx.finished and not cit.is_shadow() and not s.is_shadow() and cit.is_alive() and s.is_alive() and kinds.is_empty(),
		"light end: both are persons again, alive")
	t.check(cit.is_down() and s.is_down() and cit.ground_pos == stopped[0] and s.ground_pos == stopped[1],
		"lying for a moment where the shadow stopped")
	t.check(cit.mind == minds[0] and s.mind == minds[1] and cit.self_modulate == Color.WHITE and s.self_modulate == Color.WHITE,
		"mind as before; drawn as himself")
	for i in 60:
		cit.tick(0.1)
		s.tick(0.1)
	t.check(not cit.is_down() and not s.is_down() and cit.is_alive(), "and up again a moment later")
	fx.free()
	crowd.dusk.clear()


# --- the end in the dark: the soldiers among them are taken (shade, no remain); the citizens wake
static func _end_dark(t, made: Array, at: Vector2, c: Array, kinds: Array[StringName]) -> void:
	var crowd: Crowd = made[0]
	var cit: Person = c[12]
	var s := _guard(crowd, [])
	_away(crowd, [cit, s])
	cit.ground_pos = at + Vector2(4.0, 0.0)
	s.ground_pos = at + Vector2(0.0, 4.0)
	s.send_to_post(s.ground_pos)
	var fx := _cast(ctx_of(made), at, true)
	fx._process(ShadowPlayFx.T_RISE + 0.05)
	t.check(cit.is_shadow() and s.is_shadow(), "(dark: two shadows)")
	kinds.clear()
	var rem := crowd.remains.all().size()
	var alarm := crowd.alarm
	var killed := crowd.killed_soldiers
	fx._process(ShadowPlayFx.SPAN)
	t.check(not s.is_alive() and not s.visible and kinds == [&"shade"] and crowd.remains.all().size() == rem
		and crowd.killed_soldiers == killed + 1 and fx.taken == 1, "dark end: the soldier is taken (shade, no remain; %s)" % str(kinds))
	t.check(cit.is_alive() and not cit.is_shadow() and is_equal_approx(crowd.alarm, alarm), "the citizen wakes; no alarm")
	t.check(Rules.POWER_KINDS["shadowplay"] == [&"shade"], "the take is the god's (credited to Shadow Play)")
	fx.free()
	crowd.dusk.clear()


# --- teardown mid-span: every status lifted, nobody taken; leaving the tree the same; control: left to run, the soldier is taken
static func _teardown(t, made: Array, at: Vector2, c: Array, kinds: Array[StringName]) -> void:
	var crowd: Crowd = made[0]
	var cit: Person = c[13]
	var s := _guard(crowd, [])
	_away(crowd, [cit, s])
	cit.ground_pos = at + Vector2(1.0, 0.0)
	s.ground_pos = at + Vector2(0.0, 1.0)
	kinds.clear()
	var cut := _cast(ctx_of(made), at, true)
	cut._process(ShadowPlayFx.T_RISE + 0.05)
	cut._process(5.0)
	t.check(cit.is_shadow() and s.is_shadow(), "(teardown setup: two shadows)")
	cut.end_now()
	t.check(cut.finished and not cit.is_shadow() and not s.is_shadow() and s.is_alive() and cit.is_alive() and kinds.is_empty()
		and s.self_modulate == Color.WHITE and cit.self_modulate == Color.WHITE, "end_now mid-span: every status lifted, nobody taken")
	cut.free()
	var gone := _cast(ctx_of(made), at, true)
	gone._process(ShadowPlayFx.T_RISE + 0.05)
	var was := s.is_shadow() and cit.is_shadow()
	gone._exit_tree()
	gone.free()
	t.check(was and not is_instance_valid(gone) and not s.is_shadow() and not cit.is_shadow() and s.is_alive() and kinds.is_empty(),
		"leaving the tree and freed mid-span: the same")
	crowd.dusk.clear()
	var ctl := _cast(ctx_of(made), at, true)
	ctl._process(ShadowPlayFx.T_RISE + 0.05)
	ctl._process(ShadowPlayFx.SPAN)
	t.check(not s.is_alive() and kinds == [&"shade"] and cit.is_alive(), "control: left to run, the soldier is taken (%s)" % str(kinds))
	ctl.free()
	crowd.dusk.clear()


# --- two casts on one person: the first one's end does not undo the second
static func _two_casts(t, made: Array, at: Vector2, c: Array) -> void:
	var crowd: Crowd = made[0]
	var p: Person = c[14]
	_away(crowd, [p])
	p.ground_pos = at
	var one := _cast(ctx_of(made), at, false)
	one._process(ShadowPlayFx.T_RISE + 0.05)
	var two := _cast(ctx_of(made), at, false)
	two._process(ShadowPlayFx.T_RISE + 0.05)
	one._process(ShadowPlayFx.SPAN)
	t.check(one.finished and p.is_shadow() and p.self_modulate != Color.WHITE, "the first cast's end leaves the second's shadow")
	one.free()
	two.end_now()
	t.check(not p.is_shadow() and p.self_modulate == Color.WHITE, "the second's end lifts it")
	two.free()
	crowd.dusk.clear()


# --- quiet, and the dusk at the cast: r 3.0 (light), 6.0 (dark)
static func _quiet(t, made: Array, at: Vector2, c: Array) -> void:
	var crowd: Crowd = made[0]
	var p: Person = c[15]
	var w: Person = c[16]
	_away(crowd, [p, w])
	p.ground_pos = at
	w.ground_pos = at + Vector2(4.0, 0.0)
	crowd.dusk.clear()
	crowd.threats.clear()
	var alarm := crowd.alarm
	var voiced := crowd.voices_played
	var fx := _cast(ctx_of(made), at, false)
	t.check(crowd.dusk.count() == 1 and is_equal_approx(crowd.dusk.r_at(at), 3.0), "light: dusk laid at the cast with r 3.0 (%.2f)" % crowd.dusk.r_at(at))
	fx._process(ShadowPlayFx.T_RISE + 0.05)
	fx._process(ShadowPlayFx.SPAN)
	t.check(crowd.threats.active_count() == 0 and crowd.held_count() == 0 and is_equal_approx(crowd.alarm, alarm)
		and crowd.voices_played == voiced and w.mind == Person.Mind.CALM, "quiet: no danger, no alarm, no voice, nobody frightened")
	fx.free()
	crowd.dusk.clear()
	var dk := _cast(ctx_of(made), at, true)
	t.check(crowd.dusk.count() == 1 and is_equal_approx(crowd.dusk.r_at(at), 6.0) and crowd.dusk.covers(at + Vector2(5.9, 0.0)),
		"dark: dusk laid at the cast with r 6.0 (%.2f)" % crowd.dusk.r_at(at))
	dk.end_now()
	dk.free()
	crowd.dusk.clear()


# --- through Rules: Shadow Play is busy only until T_RISE; another power is cast after it while it still runs (C16)
static func _rules(t, made: Array, at: Vector2) -> void:
	var crowd: Crowd = made[0]
	_away(crowd, [])
	var rules := Rules.new().setup(PackedStringArray(["shadowplay", "slumber"]), ctx_of(made), made[1], made[3], crowd, made[6])
	var fx := rules.cast(0, at)
	t.check(fx is ShadowPlayFx and rules.busy_left() > 0.0, "(cast through Rules; busy at first)")
	fx._process(ShadowPlayFx.T_RISE + 0.05)
	t.check(rules.busy_left() == 0.0, "busy only until T_RISE (%.2f)" % rules.busy_left())
	var second := rules.cast(1, at + Vector2(5.0, 0.0))
	t.check(second is SlumberFx and not fx.finished, "another power is cast after it while Shadow Play still runs")
	if second != null:
		second.end_now()
		second.free()
	fx.end_now()
	fx.free()
	rules.free()
	crowd.dusk.clear()


# --- staged: the silhouette and its edge are drawn, the lying outline laid; all gone at the end
static func _staged(t, made: Array, at: Vector2, c: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx := ctx_of(made)
	var p: Person = c[17]
	_away(crowd, [p])
	p.ground_pos = at
	var keep := [ctx.overhead, ctx.ground]
	var stage := Node2D.new()
	t.root.add_child(stage)
	await t.process_frame
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	stage.add_child(ctx.ground)
	stage.add_child(ctx.overhead)
	var world: Node2D = made[4]
	stage.add_child(world)
	var stub := FxStage.StageImpact.new()
	ctx.impact = stub
	var fx := _cast(ctx, at, true)
	var ripple := fx.ripple
	t.check(ripple != null and ripple.get_parent() == ctx.ground and is_equal_approx((ripple as VeilCastLooks.Wave).r, 6.0)
		and (ripple as VeilCastLooks.Wave).kind == VeilCastLooks.Wave.Kind.RIPPLE,
		"staged: a dark ripple crosses the ground out to the dark reach (6)")
	fx._process(ShadowPlayFx.T_RISE + 0.05)
	var peel := fx.peel
	t.check(peel != null and peel.get_parent() == ctx.overhead and (peel as VeilCastLooks.Peel).ids.size() == 1 and (peel as VeilCastLooks.Peel).ids[0] == p.get_instance_id(),
		"staged: his shadow peels up from his feet (the peel holds him, overhead)")
	var lying: Node2D = fx._marks[0] if not fx._marks.is_empty() else null
	t.check(lying != null and lying.get_parent() == ctx.ground
		and (Iso.BASIS * lying.transform).origin.is_equal_approx(Iso.ground_to_screen(p.ground_pos)),
		"VRB1: the lying outline sits at his feet in screen pixels (the ground layer's basis undone)")
	await t.process_frame
	var edges := fx.edges()
	var marks := fx.marks()
	var dark_look := p.self_modulate == VeilParts.BLACK and p.is_shadow()
	await t.process_frame
	fx._process(ShadowPlayFx.SPAN)
	var after := fx.edges() + fx.marks()
	await t.process_frame
	t.check(edges == 1 and marks == 1 and dark_look,
		"staged: the shadow is a BLACK silhouette with its edge, and a lying outline where he stood (%d, %d)" % [edges, marks])
	t.check(after == 0 and p.self_modulate == Color.WHITE and p.get_children().filter(func(n: Node) -> bool: return n is ShadowPlayFx.Edge).is_empty(),
		"staged: at the end no edge or outline is left")
	t.check(not is_instance_valid(ripple) and not is_instance_valid(peel), "staged: the ripple and the peel are gone with the cast")
	if is_instance_valid(fx):
		fx.free()
	# The dark's end: a soldier's shadow fades as an event that outlives the cast, then frees itself.
	var s := _guard(crowd, [p])
	_away(crowd, [s])
	s.ground_pos = at
	s.mind = Person.Mind.POST
	var dfx := _cast(ctx, at, true)
	dfx._process(ShadowPlayFx.T_RISE + 0.05)
	dfx._process(ShadowPlayFx.SPAN)
	var fades: Array = ctx.overhead.get_children().filter(func(n: Node) -> bool: return n is VeilCastLooks.ShadeFade)
	t.check(dfx.taken == 1 and dfx.fades == 1 and fades.size() == 1 and (fades[0] as Node).is_in_group(SolarisPit.GROUP),
		"staged dark end: the soldier's shadow fades as an event (a ShadeFade, a lasting piece) (%d, %d)" % [dfx.fades, fades.size()])
	if fades.size() == 1:
		(fades[0] as Node)._process(VeilCastLooks.ShadeFade.LIFE + 0.05)
		await t.process_frame
		t.check(not is_instance_valid(fades[0]), "and frees itself when it has faded")
	if is_instance_valid(dfx):
		dfx.free()
	# A freed cast mid-rise leaves no piece of its look.
	_away(crowd, [p])
	p.ground_pos = at
	var ffx := _cast(ctx, at, false)
	var r2 := ffx.ripple
	ffx.free()
	await t.process_frame
	t.check(not is_instance_valid(r2), "staged: a freed cast leaves no ripple")
	ctx.impact = null
	stub.free()
	stage.remove_child(world)
	ctx.overhead.free()
	ctx.ground.free()
	ctx.overhead = keep[0]
	ctx.ground = keep[1]
	t.root.remove_child(stage)
	stage.free()
	crowd.dusk.clear()


# --- no crowd: builds and finishes, light and dark
static func _bare(t) -> void:
	var bare_env := EnvironmentField.new()
	var bare := FxContext.new()
	bare.env = bare_env
	bare.field = EnemyField.new()
	bare.field.env = bare_env
	bare.rng = RandomNumberGenerator.new()
	bare.overhead = Node2D.new()
	bare.ground = Node2D.new()
	var nb := _cast(bare, Vector2.ZERO, false)
	nb._process(ShadowPlayFx.T_RISE + 0.05)
	nb._process(ShadowPlayFx.SPAN + 1.0)
	t.check(nb.finished and nb.shadows == 0, "no crowd: builds and finishes")
	nb.free()
	var nd := _cast(bare, Vector2.ZERO, true)
	nd._process(ShadowPlayFx.T_RISE + 0.05)
	nd.end_now()
	nd.free()
	t.check(true, "no crowd, dark: ends clean")
	bare.overhead.free()
	bare.ground.free()
