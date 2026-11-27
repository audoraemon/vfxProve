extends RefCounted
## Evernight (Veil, Tier 5; spec 5.10): night over the whole town for 60 s (90 in a NIGHT mission). Everywhere dark, sight 0.6, the
## town veiled, the Veil's cooldowns at twice the pace; the lone taken every 2 s (1.5), 5 at a time rising to 10, each group claimed one
## take ahead (the dark eats them where they stand; each taken leaves his shadow on the ground); soldiers' torches keep the living and can
## be put out; at dawn who shelters in a blighted building or sleeps in dusk never wakes. Silent; all undone at dawn, by end_now() and
## by a freed node, owned by the cast (a second Evernight, a Dread, a Cloak, a veil and dusk patches are left alone).

const RD := preload("res://tests/test_raise_dead.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")
const DT := 0.05
const E := preload("res://src/fx/veil/evernight.gd")


static func _cast(ctx: FxContext, at: Vector2, extra := {}) -> EvernightFx:
	return FxTimeline.cast(EvernightFx, ctx, at, extra) as EvernightFx


static func _go(fx: FxTimeline, seconds: float, people: Array = []) -> void:
	for i in roundi(seconds / DT):
		for p in people:
			if is_instance_valid(p) and (p as Person).is_alive():
				(p as Person).tick(DT)
		if fx != null and is_instance_valid(fx) and not fx.finished:
			fx._process(DT)


## Runs the cast until its clock reaches `when`.
static func _until(fx: FxTimeline, when: float, people: Array = []) -> void:
	_go(fx, maxf(when - fx.t, 0.0), people)


## A calm town: everyone living stowed indoors in the corner, the ledger on and empty, no dread, veil, night, keeper or foothold; the
## light field as made. Returns open walkable ground at the market.
static func _fresh(made: Array) -> Vector2:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	for p in crowd.citizens + crowd.soldiers:
		if p.is_alive():
			p.inside = true
			if p.is_asleep():
				p.wake()
			p.statuses.clear()
			if p.profile != null and p.profile.faith == CitizenProfile.Faith.BELIEVER:
				p.profile.faith = CitizenProfile.Faith.NONE
	crowd.dusk.clear()
	crowd.dusk.enabled = true
	crowd.night_mission = false
	crowd.sight_scale = 1.0
	crowd.dreads.clear()
	crowd._veils.clear()
	crowd.footholds.clear()
	crowd.mission_keeps.clear()
	var ctx: FxContext = made[5]
	ctx.lights.clear()
	ctx.lights.ambient = 1.0
	ctx.lights.tint = Color.WHITE
	return (made[2] as WalkGrid).nearest_walkable(TownLayout.MARKET_SQUARE.get_center())


## The next stowed citizen (or soldier), set down out of doors at `at`, calm and awake.
static func _put(crowd: Crowd, at: Vector2, soldier := false) -> Person:
	for p in (crowd.soldiers if soldier else crowd.citizens):
		if p.is_alive() and p.inside and p.shelter == null:
			p.inside = false
			p.visible = true
			Kit.arrive(p, at)
			p.mind = Person.Mind.CALM
			p.walk_speed = 1.0
			if soldier:
				p.send_to_post(at)
			return p
	return null


## The static light with id `id` in the field, or {} when gone.
static func _light(lights: LightField, id: int) -> Dictionary:
	for l in lights._lights:
		if int(l.get("id", 0)) == id:
			return l
	return {}


static func run(t) -> void:
	_book(t)
	var made := RD._setup()
	var ctx: FxContext = made[5]
	ctx.lights = LightField.new()
	var kinds := {}
	var field: EnemyField = made[3]
	var on_kill := func(e: DummyEnemy, k: StringName) -> void: kinds[e.get_instance_id()] = k
	field.enemy_killed.connect(on_kill)
	_night(t, made)
	_night_mission(t, made, kinds)
	_lone(t, made, kinds)
	_counts(t, made)
	_claims(t, made, kinds)
	_few(t, made)
	_claims_end(t, made)
	_stains(t, made)
	_never(t, made)
	_bearers(t, made)
	_held(t, made)
	_huddle(t, made)
	_put_out(t, made, kinds)
	_bearer_killed(t, made, kinds)
	_dawn(t, made, kinds)
	_dawn_shelter(t, made, kinds)
	_dread(t, made)
	_dread_cut_short(t, made)
	_rules(t, made)
	_teardown(t, made)
	_two(t, made)
	_look(t, made)
	_sky(t, made)
	_one_sky(t, made)
	_dawn_glow(t, made)
	await _layers(t, made)
	field.enemy_killed.disconnect(on_kill)
	ctx.lights.free()
	ctx.lights = null
	RD._done(made)
	_quiet(t)
	_no_crowd(t)


static func _book(t) -> void:
	var p := PowerBook.get_power("evernight")
	t.check(not p.is_empty() and String(p.get("authority", "")) == "veil" and float(p.cooldown) >= Rules.ONCE_COOLDOWN and int(p.dp) == 6,
		"the row: Veil, Might 6, once a descent (%s)" % [p])
	t.check(E.WAVE == 3.0 and E.DAWN == 3.0 and E.TORCHES == 6 and E.TORCH_R == 2.5 and E.TORCH_COUNT_R == 6.0 and E.TORCH_CALL == 10.0,
		"the brief's numbers")
	t.check(VeilRules.size("evernight", "NIGHT_TIME", false) == 60.0 and VeilRules.size("evernight", "NIGHT_TIME", true) == 90.0
		and VeilRules.size("evernight", "TAKE_EVERY", false) == 2.0 and VeilRules.size("evernight", "TAKE_EVERY", true) == 1.5,
		"60 s and a take every 2 s; 90 s and 1.5 s in a NIGHT mission")
	t.check(Crowd.SILENT_KINDS.has(E.KIND) and E.KIND == &"night", "its takes are silent (&\"night\")")


## Part 1: after the wave everywhere is dark and veiled, the Veil's clocks run at 2x, sight is 0.6, the lamps are dead and the light is
## the night's; it lasts 60 s and after the dawn all is as it was, lights included.
static func _night(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var rules := Rules.new()
	ctx.rules = rules
	var lamp := ctx.lights.add_static(at + Vector2(5.0, 0.0), 3.0, Color.WHITE, 1.0)
	var spots := [at, Vector2(-28.0, -28.0), Vector2(28.0, 28.0), at + Vector2(9.0, -6.0)]
	var dark_any := func() -> bool: return spots.all(func(g: Vector2) -> bool: return crowd.in_dark(g))
	var veiled_any := func() -> bool: return spots.all(func(g: Vector2) -> bool: return crowd.is_veiled(g))
	t.check(not dark_any.call() and not veiled_any.call() and rules.haste.is_empty() and crowd.sight_scale == 1.0,
		"control: before the cast nothing is dark or veiled, no haste, full sight")
	var fx := _cast(ctx, at)
	t.check(fx.duration == E.WAVE + 60.0 + E.DAWN and fx.busy == E.WAVE, "it lasts the wave, 60 s and the dawn; busy only for the wave")
	_until(fx, E.WAVE - 0.5)
	t.check(not crowd.dusk.everywhere and not dark_any.call() and rules.haste.is_empty(), "during the wave the night has not yet fallen")
	t.check(ctx.lights.ambient < 1.0 and float(_light(ctx.lights, lamp).intensity) < 1.0, "but the light is already going")
	_until(fx, E.WAVE + DT)
	t.check(dark_any.call() and veiled_any.call(), "after the wave everywhere is dark and veiled")
	t.check(float(rules.haste.get("veil", 0.0)) == 2.0, "the Veil's cooldown clocks run at 2x")
	t.check(is_equal_approx(crowd.sight_scale, 0.6), "sight is 0.6 (%.2f)" % crowd.sight_scale)
	crowd.lay_dusk(at + Vector2(-6.0, 0.0), 1.0, 30.0)
	t.check(is_equal_approx(crowd.sight_scale_at(at + Vector2(-6.0, 0.0), at), 0.6), "and 0.6 inside dusk too, never 0.36")
	t.check(is_equal_approx(ctx.lights.ambient, TownLook.ambient(Town.Look.NIGHT)) and ctx.lights.tint.is_equal_approx(TownLook.light_tint(Town.Look.NIGHT)),
		"the light is the night's (ambient %.2f)" % ctx.lights.ambient)
	t.check(float(_light(ctx.lights, lamp).intensity) == 0.0, "every lamp has died")
	_until(fx, fx.t_dawn - DT)
	t.check(dark_any.call() and crowd.sight_scale < 1.0 and rules.haste.has("veil"), "60 s on it is still night")
	_until(fx, fx.t_dawn + E.DAWN + DT)
	t.check(fx.finished, "after the dawn the cast is over")
	t.check(not crowd.dusk.everywhere and not crowd.in_dark(Vector2(28.0, 28.0)) and not veiled_any.call(), "the dark and the veil are gone")
	t.check(rules.haste.is_empty() and crowd.sight_scale == 1.0, "no haste, full sight")
	t.check(ctx.lights.ambient == 1.0 and ctx.lights.tint == Color.WHITE and is_equal_approx(float(_light(ctx.lights, lamp).intensity), 1.0)
		and ctx.lights._mute_below == -1 and not ctx.lights.has_meta(E.LOOK_KEY) and not crowd.has_meta(E.NIGHT_KEY),
		"the light is as it was, the lamp lit again")
	ctx.rules = null
	rules.free()


## Three clusters of three and one alone: the alone is the first taken (at WAVE + every), with &"night"; then one every `every`.
static func _layout(crowd: Crowd, at: Vector2) -> Dictionary:
	var clusters: Array[Person] = []
	for c in [at + Vector2(-8.0, -4.0), at + Vector2(0.0, 6.0), at + Vector2(8.0, -4.0)]:
		for o in [Vector2.ZERO, Vector2(0.8, 0.0), Vector2(0.4, 0.7)]:
			clusters.append(_put(crowd, c + o))
	var lone := _put(crowd, at + Vector2(0.0, -16.0))
	return {"clusters": clusters, "lone": lone}


static func _night_mission(t, made: Array, kinds: Dictionary) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	crowd.night_mission = true
	crowd.sight_scale = NightRules.NIGHT_SIGHT
	var l := _layout(crowd, at)
	var fx := _cast(ctx, at, {"dark": true})
	t.check(fx.night_time == 90.0 and fx.take_every == 1.5 and fx.duration == E.WAVE + 90.0 + E.DAWN, "NIGHT: 90 s, a take every 1.5 s")
	_until(fx, E.WAVE + DT)
	t.check(is_equal_approx(crowd.sight_scale, 0.6), "NIGHT: sight 0.6, not 0.36 (%.2f)" % crowd.sight_scale)
	t.check(fx.claimed.size() == 5 and fx.claimed[0] == (l.lone as Person).get_instance_id(), "NIGHT: the night falls: 5 claimed, the lone first")
	_until(fx, E.WAVE + 1.5 - DT)
	t.check(fx.taken.is_empty(), "NIGHT: nobody taken before WAVE + 1.5")
	_until(fx, E.WAVE + 1.5 + DT)
	t.check(fx.taken.size() == 5 and fx.taken[0] == (l.lone as Person).get_instance_id() and kinds.get(fx.taken[0], &"") == &"night",
		"NIGHT: at WAVE + 1.5 five are taken, the lone first (%d)" % fx.taken.size())
	_until(fx, E.WAVE + 3.0 - DT)
	t.check(fx.taken.size() == 5, "NIGHT: no second take before WAVE + 3.0")
	_until(fx, E.WAVE + 3.0 + DT)
	t.check(fx.taken.size() == 10, "NIGHT: the second take at WAVE + 3.0, the last five (%d)" % fx.taken.size())
	fx.end_now()
	t.check(is_equal_approx(crowd.sight_scale, NightRules.NIGHT_SIGHT) and crowd.night_mission, "NIGHT: ended, the night's own sight stays")
	crowd.night_mission = false


## Part 2: the lone is taken first, silently, then one every 2 s; ties by the lower instance id.
static func _lone(t, made: Array, kinds: Dictionary) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var l := _layout(crowd, at)
	var lone: Person = l.lone
	t.check(E.loneliest(crowd, []) == lone, "loneliest(): the one alone")
	var alarm := crowd.alarm
	var voiced := crowd.voices_played
	var fx := _cast(ctx, at)
	_until(fx, E.WAVE + 2.0 - DT)
	t.check(lone.is_alive() and fx.taken.is_empty(), "nobody taken before WAVE + 2.0")
	_until(fx, E.WAVE + 2.0 + DT)
	t.check(not lone.is_alive() and fx.taken.size() == 5 and fx.taken[0] == lone.get_instance_id()
		and kinds.get(lone.get_instance_id(), &"") == &"night",
		"at WAVE + 2.0 five are taken, the lone first, &\"night\" (%s, %d)" % [kinds.get(lone.get_instance_id(), &""), fx.taken.size()])
	_until(fx, E.WAVE + 4.0 - DT)
	t.check(fx.taken.size() == 5, "no second take before WAVE + 4.0")
	_until(fx, E.WAVE + 4.0 + DT)
	var from_clusters := fx.taken.size() == 10
	for id in fx.taken.slice(1):
		from_clusters = from_clusters and (l.clusters as Array).any(func(p: Person) -> bool: return p.get_instance_id() == id)
	t.check(from_clusters,
		"the next take at WAVE + 4.0, from the clusters: everyone left (%d)" % fx.taken.size())
	_until(fx, E.WAVE + 6.0 + DT)
	t.check(fx.taken.size() == 10 and fx.claimed.is_empty(), "and nobody is left to take or claim")
	t.check(crowd.alarm == alarm and crowd.voices_played == voiced, "nobody heard: alarm and voices unchanged")
	fx.end_now()
	# A tie: two pairs, each 5 apart: all four tie; the lowest instance id goes.
	at = _fresh(made)
	var four: Array[Person] = [_put(crowd, at + Vector2(-10.0, 0.0)), _put(crowd, at + Vector2(-5.0, 0.0)),
		_put(crowd, at + Vector2(10.0, 0.0)), _put(crowd, at + Vector2(10.0, 5.0))]
	var low := four[0]
	for p in four:
		if p.get_instance_id() < low.get_instance_id():
			low = p
	t.check(E.loneliest(crowd, []) == low, "a tie goes to the lower instance id")
	t.check(E.loneliest_n(crowd, [], 1, {}).size() == 1 and E.loneliest_n(crowd, [], 1, {})[0] == low and E.loneliest_n(crowd, [], 4, {})[0] == low
		and E.loneliest_n(crowd, [], 4, {}).size() == 4, "loneliest_n(): the same first, ties by the lower instance id")
	t.check(E.loneliest(crowd, [low.ground_pos]) != low and E.loneliest(crowd, [low.ground_pos]) != null, "one in a torch's light is passed over")
	# One take() cannot take (Corpse Guise's Deathless: Person.deathless) is passed over, so the tick takes the next one.
	at = _fresh(made)
	l = _layout(crowd, at)
	lone = l.lone
	lone.deathless = func(_w: Person, _k: StringName) -> bool: return true
	t.check(E.loneliest(crowd, []) != lone and E.loneliest(crowd, []) != null, "a Deathless loner is passed over by loneliest()")
	fx = _cast(ctx, at)
	_until(fx, E.WAVE + 2.0 + DT)
	t.check(lone.is_alive() and fx.taken.size() == 5 and not fx.taken.has(lone.get_instance_id()),
		"with a Deathless person the loneliest, the take passes him over (%d taken)" % fx.taken.size())
	fx.end_now()
	lone.deathless = Callable()


## Review 2: take k of K collects 5 at the first rising evenly to 10 at the last (rounded), for both night lengths; the rhythm is unchanged.
static func _counts(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	for night in [false, true]:
		_fresh(made)
		crowd.night_mission = night
		var fx := _cast(ctx, Vector2.ZERO)
		var k_last := 59 if night else 29
		var mid := (k_last + 1) / 2
		t.check(fx.takes == k_last and fx.take_count(1) == E.TAKE_FIRST and fx.take_count(mid) == 8 and fx.take_count(k_last) == E.TAKE_LAST,
			"%s: %d takes, 5 at the first, 8 at the middle (%d), 10 at the last" % ["NIGHT" if night else "day", fx.takes, fx.take_count(mid)])
		var rising := true
		for k in range(2, k_last + 1):
			rising = rising and fx.take_count(k) >= fx.take_count(k - 1) and fx.take_count(k) - fx.take_count(k - 1) <= 1
		t.check(rising, "%s: the count rises evenly, never by more than one a take" % ("NIGHT" if night else "day"))
		fx.end_now()
		crowd.night_mission = false
	t.check(E.TAKE_FIRST == 5 and E.TAKE_LAST == 10, "the brief's numbers: 5 rising to 10")


## Every living out of doors as neighbours; the candidates (not lit, not spared, takeable, not in `skip`) loneliest first, ties by id.
static func _expected(crowd: Crowd, lit: Array, n: int) -> Array[int]:
	var all: Array[Person] = []
	for p in crowd.citizens + crowd.soldiers:
		if p.is_alive() and not p.inside:
			all.append(p)
	var rows: Array = []
	for p in all:
		if E._in_light(p.ground_pos, lit) or crowd.spared(p) or not E.takeable(p):
			continue
		var d := INF
		for q in all:
			if q != p:
				d = minf(d, p.ground_pos.distance_to(q.ground_pos))
		rows.append([d, p.get_instance_id()])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0] if a[0] != b[0] else a[1] < b[1])
	var out: Array[int] = []
	for r in rows.slice(0, n):
		out.append(int(r[1]))
	return out


## Review 2, the claim and the take: at the fall the 5 loneliest are claimed in order, none in a torch's light, none spared; take 1 takes
## exactly the claimed who still qualify, in order; one who walked into the light, one gone indoors and one spared meanwhile are let go
## and live; the next group is claimed at once, nobody twice. The claims' looks follow them (overhead_back), the let go fall away.
static func _claims(t, made: Array, kinds: Dictionary) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	ctx.overhead_back = Node2D.new()
	var torch := at + Vector2(0.0, -14.0)
	_put(crowd, torch, true)
	var by_torch := _put(crowd, torch + Vector2(1.5, 0.0))
	var believer := _put(crowd, at + Vector2(-24.0, 0.0))
	believer.profile.faith = CitizenProfile.Faith.BELIEVER
	var spots := [Vector2(-12.0, 10.0), Vector2(12.0, 10.0), Vector2(15.0, -4.0), Vector2(-14.0, -7.0), Vector2(0.0, 15.0), Vector2(6.0, 4.0),
		Vector2(-5.0, 5.0), Vector2(8.0, 5.5), Vector2(-3.0, 18.0), Vector2(20.0, 12.0), Vector2(-20.0, 14.0), Vector2(2.0, 4.5)]
	var folk: Array[Person] = [by_torch, believer]
	for o in spots:
		folk.append(_put(crowd, at + o))
	for p in folk:
		p.sleep(200.0, true)  # they stay where they are (a calm one near a torch would walk to it)
	var fx := _cast(ctx, at)
	_until(fx, E.WAVE - DT)
	t.check(fx.claimed.is_empty(), "nobody is claimed before the night falls")
	_until(fx, E.WAVE + DT)
	var want := _expected(crowd, fx.lit(), 5)
	t.check(fx.torches.size() == 1 and fx.claimed.size() == 5 and fx.claimed == want,
		"the night falls: the 5 loneliest are claimed, in order (%s / %s)" % [fx.claimed, want])
	var ps: Array[Person] = []
	for id in fx.claimed:
		ps.append(instance_from_id(id) as Person)
	t.check(ps.all(func(p: Person) -> bool: return not E._in_light(p.ground_pos, fx.lit()) and not crowd.spared(p))
		and not fx.claimed.has(believer.get_instance_id()) and not fx.claimed.has(by_torch.get_instance_id()),
		"none claimed is in a torch's light or spared")
	t.check(E.loneliest(crowd, fx.lit()) == E.loneliest_n(crowd, fx.lit(), 1, {})[0] and E.loneliest(crowd, fx.lit()).get_instance_id() == want[0],
		"loneliest() agrees with loneliest_n(.., 1, {})")
	t.check(E.loneliest_n(crowd, fx.lit(), 3, {want[0]: true}) == E.loneliest_n(crowd, fx.lit(), 4, {}).slice(1),
		"loneliest_n() skips the ones in `skip`")
	var looks := fx._claim_looks.values()
	var looks_ok := looks.size() == 5 and EvernightMarks.Z_CLAIM < 5 and EvernightMarks.Z_CLAIM > EvernightSky.Z_AIR
	for c in looks:
		looks_ok = looks_ok and c is EvernightMarks.Claim and (c as Node).get_parent() == ctx.overhead_back \
			and not (c as CanvasItem).z_as_relative and (c as CanvasItem).z_index == EvernightMarks.Z_CLAIM
	t.check(looks_ok,
		"a claim's look on each claimed (overhead_back, absolute z 4: over the night, under the aim)")
	# Meanwhile: one walks into the torch's light, one goes indoors, one is spared.
	Kit.arrive(ps[0], torch + Vector2(-1.0, 0.5))
	ps[1].inside = true
	ps[2].profile.faith = CitizenProfile.Faith.BELIEVER
	var alive_before := (crowd.citizens + crowd.soldiers).filter(func(p: Person) -> bool: return p.is_alive()).size()
	_until(fx, E.WAVE + 2.0 + DT)
	t.check(fx.taken == [ps[3].get_instance_id(), ps[4].get_instance_id()] and not ps[3].is_alive() and not ps[4].is_alive()
		and kinds.get(ps[3].get_instance_id(), &"") == &"night",
		"take 1 takes exactly the claimed who still qualify, in order (%d)" % fx.taken.size())
	t.check(ps[0].is_alive() and ps[1].is_alive() and ps[2].is_alive()
		and (crowd.citizens + crowd.soldiers).filter(func(p: Person) -> bool: return p.is_alive()).size() == alive_before - 2,
		"the one in the light, the one indoors and the spared one are let go and live")
	t.check(not is_instance_valid(looks[0]) or (looks[0] as EvernightMarks.Claim).gone >= 0.0 or (looks[0] as Node).is_queued_for_deletion(),
		"a let go claim's look falls away")
	t.check(_gone(looks[3]) and _gone(looks[4]), "a taken one's look goes with him")
	var uniq := {}
	for id in fx.claimed:
		uniq[id] = true
	var want2 := _expected(crowd, fx.lit(), fx.take_count(2))
	t.check(fx.claimed == want2 and uniq.size() == fx.claimed.size() and not fx.claimed.has(ps[1].get_instance_id()),
		"the next group is claimed at once, nobody twice (%s / %s)" % [fx.claimed, want2])
	t.check(fx.stains != null and fx.stains.get_parent() == ctx.ground and fx.stains.marks.size() == 2,
		"the two taken leave their shadows on the ground layer, one node")
	var stains := fx.stains
	fx.end_now()
	t.check(fx.claimed.is_empty() and _gone(stains), "ended: no claim left, the shadows gone with the cast")
	ps[1].inside = true
	ps[2].profile.faith = CitizenProfile.Faith.NONE
	believer.profile.faith = CitizenProfile.Faith.NONE
	ctx.overhead_back.free()
	ctx.overhead_back = null


## Review 2: with fewer candidates than the take's count, the claim holds them all.
static func _few(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var three: Array[Person] = [_put(crowd, at + Vector2(-8.0, 0.0)), _put(crowd, at + Vector2(8.0, 0.0)), _put(crowd, at + Vector2(0.0, 9.0))]
	var fx := _cast(ctx, at)
	_until(fx, E.WAVE + DT)
	t.check(fx.claimed.size() == 3 and three.all(func(p: Person) -> bool: return fx.claimed.has(p.get_instance_id())),
		"three out of doors, five to claim: all three claimed (%d)" % fx.claimed.size())
	_until(fx, E.WAVE + 2.0 + DT)
	t.check(fx.taken.size() == 3 and fx.claimed.is_empty(), "all three taken; nobody left to claim")
	fx.end_now()


## Review 2: the night's end drops every claim. Cut short with a group claimed: nobody is taken after. Run to its dawn: nothing is
## claimed past the last take, nobody taken after it. Two casts keep their own claims.
static func _claims_end(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var l := _layout(crowd, at)
	var fx := _cast(ctx, at)
	_until(fx, E.WAVE + DT)
	var held := fx.claimed.duplicate()
	t.check(held.size() == 5, "(five claimed)")
	fx.end_now()
	t.check(fx.claimed.is_empty(), "end_now(): the claims are dropped")
	t.check(held.all(func(id: int) -> bool: return (instance_from_id(id) as Person).is_alive()), "and the claimed live")
	# Two casts, each its own claims; the first take takes the one both claimed.
	var a := _cast(ctx, at)
	var b := _cast(ctx, at + Vector2(2.0, 0.0))
	for i in roundi((E.WAVE + DT) / DT):
		a._process(DT)
		b._process(DT)
	t.check(a.claimed.size() == 5 and b.claimed == a.claimed, "two casts: each claims its own group (the same loneliest)")
	var both := a.claimed.duplicate()
	for i in roundi(2.0 / DT):
		a._process(DT)
		b._process(DT)
	t.check(a.taken == both and b.taken.is_empty(), "the one both claimed is taken by the first take (%d / %d)" % [a.taken.size(), b.taken.size()])
	a.end_now()
	b.end_now()
	# Run to the dawn: one set down after the last take is never claimed or taken.
	at = _fresh(made)
	var fx2 := _cast(ctx, at)
	_until(fx2, E.WAVE + float(fx2.takes) * fx2.take_every + DT)
	var late := _put(crowd, at + Vector2(0.0, 12.0))
	_until(fx2, fx2.t_dawn + DT)
	t.check(fx2.claimed.is_empty() and late.is_alive(), "after the last take nothing is claimed; at dawn none is held")
	_until(fx2, fx2.duration - DT)
	t.check(late.is_alive() and fx2.taken.is_empty(), "nobody taken after the night is over")
	fx2.end_now()
	l.clear()


## Review 2, the shadows: one node on the ground layer for all of the night's shadows, a mark for each taken (a torch put out too); they
## fade over the dawn; gone with end_now() and with a freed cast.
static func _stains(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	for mode in ["end_now", "free", "dawn"]:
		var at := _fresh(made)
		_layout(crowd, at)
		var fx := _cast(ctx, at)
		_until(fx, E.WAVE + 2.0 - DT)
		t.check(fx.stains == null, "%s: no shadow before the first take" % mode)
		_until(fx, E.WAVE + 4.0 + DT)
		var st := fx.stains
		var on_ground := ctx.ground.get_children().filter(func(n: Node) -> bool: return n is EvernightMarks.Stains and not n.is_queued_for_deletion())
		t.check(st != null and st.get_parent() == ctx.ground and on_ground.size() == 1 and st.marks.size() == fx.taken.size() and fx.taken.size() == 10,
			"%s: ten taken, ten shadows, one node on the ground layer (%d)" % [mode, st.marks.size() if st else -1])
		if mode == "dawn":
			_until(fx, fx.t_dawn + E.DAWN * 0.5)
			t.check(st.fade > 0.3 and st.fade < 0.7, "the shadows fade over the dawn (%.2f)" % st.fade)
			_until(fx, fx.duration + DT)
			t.check(fx.finished and _gone(st), "and go with the cast")
			continue
		if mode == "end_now":
			fx.end_now()
		else:
			fx.free()
		t.check(_gone(st), "%s: the shadows go with the cast" % mode)


## Never taken: a BELIEVER standing alone, one the director keeps alive, one indoors, one in a torch's light. Control: an ordinary loner.
static func _never(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var believer := _put(crowd, at + Vector2(-16.0, 0.0))
	believer.profile.faith = CitizenProfile.Faith.BELIEVER
	var kept := _put(crowd, at + Vector2(16.0, 0.0))
	crowd.mission_keeps.append(func(p: Person) -> bool: return p == kept)
	var indoors := _put(crowd, at + Vector2(0.0, 16.0))
	indoors.inside = true
	var bearer := _put(crowd, at + Vector2(0.0, -14.0), true)
	var lit := _put(crowd, at + Vector2(1.5, -14.0))
	lit.sleep(200.0, true)  # stays where he is (a calm one would walk to the torch)
	var control := _put(crowd, at + Vector2(-14.0, 12.0))
	t.check(crowd.spared(believer) and crowd.spared(kept) and not crowd.spared(control), "(the believer and the kept are spared)")
	var fx := _cast(ctx, at)
	_until(fx, E.WAVE + 2.0 + DT)
	t.check(fx.torches.size() == 1 and E._in_light(lit.ground_pos, fx.lit()), "(the bearer's torch lights the one beside him)")
	t.check(fx.taken == [control.get_instance_id()], "control: the ordinary loner is taken first")
	_until(fx, E.WAVE + 12.0 + DT)
	t.check(fx.taken.size() == 1 and believer.is_alive() and kept.is_alive() and indoors.is_alive() and lit.is_alive() and bearer.is_alive(),
		"10 s on: the believer, the kept, the one indoors and the ones in the light are never taken (%d)" % fx.taken.size())
	fx.end_now()
	indoors.inside = true
	believer.profile.faith = CitizenProfile.Faith.NONE


## Part 3, the bearers: up to 6 living soldiers out of doors, the most citizens within 6 first, ties by instance id; each torch lights 2.5.
static func _bearers(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var spots := [Vector2(-24.0, -20.0), Vector2(-8.0, -20.0), Vector2(8.0, -20.0), Vector2(24.0, -20.0), Vector2(-24.0, 4.0),
		Vector2(-8.0, 4.0), Vector2(8.0, 4.0)]
	var counts := [3, 2, 2, 1, 0, 0, 0]
	var ss: Array[Person] = []
	for i in spots.size():
		ss.append(_put(crowd, spots[i], true))
		for k in counts[i]:
			_put(crowd, spots[i] + Vector2(1.0 + 0.6 * float(k), 1.0))
	var by_id := func(a: Person, b: Person) -> bool: return a.get_instance_id() < b.get_instance_id()
	var twos: Array[Person] = [ss[1], ss[2]]
	twos.sort_custom(by_id)
	var zeros: Array[Person] = [ss[4], ss[5], ss[6]]
	zeros.sort_custom(by_id)
	var want: Array[Person] = [ss[0], twos[0], twos[1], ss[3], zeros[0], zeros[1]]
	var got := E.bearers(crowd)
	t.check(got == want, "bearers(): most citizens within 6 first, ties by instance id, at most 6")
	var indoor := _put(crowd, at + Vector2(0.0, 20.0), true)
	indoor.inside = true
	var dead := _put(crowd, at + Vector2(3.0, 20.0), true)
	crowd.take(dead, &"night")
	t.check(not E.bearers(crowd).has(indoor) and not E.bearers(crowd).has(dead), "never one indoors or dead")
	var fx := _cast(ctx, at)
	_until(fx, E.WAVE + DT)
	t.check(fx.torches.size() == 6, "six torches when the night falls")
	var ok := true
	for i in fx.torches.size():
		var tc: Dictionary = fx.torches[i]
		var l := _light(ctx.lights, int(tc.light))
		ok = ok and int(tc.bearer) == want[i].get_instance_id() and (tc.at as Vector2) == want[i].ground_pos and not l.is_empty() \
			and float(l.radius) == E.TORCH_R
	t.check(ok, "each where his bearer stands, lighting 2.5")
	t.check(not fx.torches.any(func(tc: Dictionary) -> bool: return int(tc.bearer) == zeros[2].get_instance_id()), "the seventh lights none")
	fx.end_now()
	t.check(fx.torches.all(func(tc: Dictionary) -> bool: return _light(ctx.lights, int(tc.light)).is_empty()) and ctx.lights._lights.is_empty(),
		"ended: every torch light is gone")


## A soldier a mission holds (Crowd.mission_holds: a seizer with his charge) is never a bearer while a free one is; a citizen it holds is
## never called to a torch while a free one beside him is.
static func _held(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var grid: WalkGrid = made[2]
	var at := _fresh(made)
	var held_s := _put(crowd, grid.nearest_walkable(at + Vector2(-14.0, 0.0)), true)
	for k in 3:
		_put(crowd, held_s.ground_pos + Vector2(1.0 + 0.6 * float(k), 1.0))
	var free_s := _put(crowd, grid.nearest_walkable(at + Vector2(14.0, 0.0)), true)
	var held_c := _put(crowd, grid.nearest_walkable(free_s.ground_pos + Vector2(0.0, 5.0)))
	var free_c := _put(crowd, grid.nearest_walkable(free_s.ground_pos + Vector2(0.0, -5.0)))
	t.check(E.bearers(crowd)[0] == held_s, "(control: unheld, the soldier with the most citizens near is the first bearer)")
	var hold := func(p: Person) -> bool: return p == held_s or p == held_c
	crowd.mission_holds.append(hold)
	var got := E.bearers(crowd)
	t.check(not got.has(held_s) and got.has(free_s), "a soldier the mission holds is never a bearer; the free one is")
	var goal := held_c._goal
	var fx := _cast(ctx, at)
	_until(fx, E.WAVE + DT)
	t.check(fx.torches.size() == 1 and int(fx.torches[0].bearer) == free_s.get_instance_id(), "one torch, the free soldier's")
	t.check(free_c.anchor.distance_to(free_s.ground_pos) <= E.TORCH_R and free_c._goal != Vector2.INF, "(control) the free citizen is called to it")
	t.check(held_c._goal == goal and not fx._called.has(held_c.get_instance_id()), "the held citizen is not")
	fx.end_now()
	crowd.mission_holds.erase(hold)


## Citizens within 10 of a torch walk to it and huddle in its light; one at 11 does not.
static func _huddle(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var grid: WalkGrid = made[2]
	var at := _fresh(made)
	var x := grid.nearest_walkable(at + Vector2(0.0, -2.0))
	var bearer := _put(crowd, x, true)
	var near := _put(crowd, grid.nearest_walkable(x + Vector2(8.0, 0.0)))
	var far := _put(crowd, grid.nearest_walkable(x + Vector2(-11.0, 0.0)))
	t.check(near.ground_pos.distance_to(x) <= 10.0 and far.ground_pos.distance_to(x) > 10.0, "(one within 10, one past it)")
	crowd.mission_keeps.append(func(p: Person) -> bool: return p == near or p == far)  # spared: only the walk is looked at
	var far_goal := far._goal
	var fx := _cast(ctx, at)
	_until(fx, E.WAVE + DT)
	t.check(fx.torches.size() == 1 and near.anchor.distance_to(x) <= E.TORCH_R and near._goal != Vector2.INF, "the one within 10 is called to the torch")
	t.check(far._goal == far_goal and far.anchor.distance_to(x) > E.TORCH_R, "the one at 11 is not")
	_go(fx, 30.0, [near])  # round the houses: the walk's route, not a beeline
	t.check(near.is_alive() and near.ground_pos.distance_to(x) <= E.TORCH_R and E._in_light(near.ground_pos, fx.lit()),
		"he walks into its light (%.2f from it)" % near.ground_pos.distance_to(x))
	t.check(bearer.ground_pos.distance_to(x) < 0.01, "the bearer stands where he is")
	fx.end_now()


## A torch put out by dusk laid over it: everyone in its light (not the spared) is taken and the light is gone.
static func _put_out(t, made: Array, kinds: Dictionary) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var x := at + Vector2(0.0, -6.0)
	var s := _put(crowd, x, true)
	var a := _put(crowd, x + Vector2(1.5, 0.0))
	var b := _put(crowd, x + Vector2(0.0, 1.5))
	var c := _put(crowd, x + Vector2(-1.5, 0.0))
	c.profile.faith = CitizenProfile.Faith.BELIEVER
	var d := _put(crowd, x + Vector2(0.0, -4.0))
	for p in [a, b, c, d]:
		p.sleep(200.0, true)  # held where they stand
	var fx := _cast(ctx, at)
	_until(fx, E.WAVE + DT)
	var light := int(fx.torches[0].light)
	crowd.lay_dusk(x + Vector2(12.0, 0.0), 1.0, 20.0)
	t.check(not fx.torches[0].out and not _light(ctx.lights, light).is_empty() and a.is_alive(), "control: dusk laid far off leaves the torch")
	crowd.lay_dusk(x + Vector2(3.5, 0.0), 1.5, 20.0)
	t.check(fx.torches[0].out and _light(ctx.lights, light).is_empty(), "dusk laid over it puts it out: the light is gone")
	t.check(not s.is_alive() and not a.is_alive() and not b.is_alive() and kinds.get(a.get_instance_id(), &"") == &"night",
		"everyone in its light is taken, the bearer too")
	t.check(c.is_alive(), "not the spared")
	t.check(d.is_alive(), "one outside its light is not taken by it")
	t.check(fx.taken.size() == 3, "three taken (%d)" % fx.taken.size())
	fx.end_now()
	c.profile.faith = CitizenProfile.Faith.NONE


## A bearer killed: his torch goes out the same way.
static func _bearer_killed(t, made: Array, kinds: Dictionary) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var x := at + Vector2(0.0, -6.0)
	var s := _put(crowd, x, true)
	var a := _put(crowd, x + Vector2(1.5, 0.0))
	a.sleep(200.0, true)
	var fx := _cast(ctx, at)
	_until(fx, E.WAVE + DT)
	var light := int(fx.torches[0].light)
	_go(fx, 0.5)
	t.check(not fx.torches[0].out and a.is_alive(), "control: the torch burns while he lives")
	(made[3] as EnemyField).kill(s, &"mob")
	_go(fx, DT)
	t.check(fx.torches[0].out and _light(ctx.lights, light).is_empty() and not a.is_alive() and kinds.get(a.get_instance_id(), &"") == &"night",
		"the bearer killed: his torch goes out and the one in its light is taken")
	fx.end_now()


## Part 4: at dawn one sheltering in a blighted building and one asleep in a dusk patch are taken; a sleeper on plain ground, one
## sheltering elsewhere and one awake live on. Nothing is counted: the alarm at dawn is the alarm at the cast.
static func _dawn(t, made: Array, kinds: Dictionary) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var x := at + Vector2(0.0, -6.0)
	var s := _put(crowd, x, true)
	var dreamer := _put(crowd, x + Vector2(1.5, 0.0))
	var sleeper := _put(crowd, x + Vector2(-1.5, 0.0))
	var awake := _put(crowd, x + Vector2(0.0, 1.0))
	crowd.lay_dusk(dreamer.ground_pos, 0.6, 200.0)
	dreamer.sleep(200.0, true)
	sleeper.sleep(200.0, true)
	var houses := (made[1] as EnvironmentField).structures()
	var blighted: Structure = houses[0]
	var plain: Structure = houses[1]
	crowd.footholds.append(blighted)
	var in_blight := _put(crowd, blighted.center())
	in_blight.inside = true
	in_blight.shelter = blighted
	var in_plain := _put(crowd, plain.center())
	in_plain.inside = true
	in_plain.shelter = plain
	# Spec 5.8: a shadow's owner counts as asleep -- awake and walking as his shadow in a dusk patch at dawn, he is taken; one awake
	# beside him in the same patch, no shadow, lives (control). Both stand in the torch's light through the night.
	var patch := x + Vector2(-1.2, -0.8)
	crowd.lay_dusk(patch, 0.6, 200.0)
	var shade := _put(crowd, patch)
	shade.statuses[&"shadow"] = 1.0
	var beside := _put(crowd, patch + Vector2(0.0, 0.3))
	var alarm := crowd.alarm
	var fx := _cast(ctx, at)
	_until(fx, fx.t_dawn - 1.0)
	t.check(dreamer.is_alive() and sleeper.is_alive() and awake.is_alive() and in_blight.is_alive() and in_plain.is_alive() and fx.taken.is_empty(),
		"(through the night all of them live: in the light or indoors)")
	sleeper.wake()
	sleeper.sleep(1.5, true)
	_until(fx, fx.t_dawn + DT)
	t.check(not in_blight.is_alive() and kinds.get(in_blight.get_instance_id(), &"") == &"night", "at dawn the one sheltering in a blighted building is taken")
	t.check(not dreamer.is_alive() and kinds.get(dreamer.get_instance_id(), &"") == &"night", "the one asleep in a dusk patch is taken")
	t.check(sleeper.is_alive() and in_plain.is_alive() and awake.is_alive() and s.is_alive(),
		"the sleeper on plain ground, the one sheltering elsewhere and the awake live on")
	t.check(not shade.is_alive() and kinds.get(shade.get_instance_id(), &"") == &"night", "a shadow's owner in a dusk patch counts as asleep: taken")
	t.check(beside.is_alive(), "(control) one awake beside him in the same patch, no shadow, lives")
	shade.statuses.erase(&"shadow")
	_go(null, 2.0, [sleeper])
	t.check(sleeper.is_alive() and not sleeper.is_asleep(), "and the sleeper wakes")
	t.check(crowd.alarm == alarm, "nothing counted: the alarm at dawn is the alarm at the cast (%.2f / %.2f)" % [crowd.alarm, alarm])
	fx.end_now()
	for p in [in_blight, in_plain]:
		p.shelter = null
	crowd.footholds.clear()


## Final review, Important 2: a real shelterer (ShelterManager's own list) in a blighted building is taken at dawn and let out of the
## shelter first, so when that shelter is next flushed he stays taken: not visible, not back in the field. Control: one sheltering in
## the same way in a plain building lives and is flushed out as ever.
static func _dawn_shelter(t, made: Array, kinds: Dictionary) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var field: EnemyField = made[3]
	var at := _fresh(made)
	var sm := crowd.shelters
	var houses: Array[Structure] = []
	for s: Structure in sm.shelters:
		if is_instance_valid(s) and not s.destroyed and (sm.shelters[s].inside as Array).is_empty():
			houses.append(s)
	houses.sort_custom(func(a: Structure, b: Structure) -> bool: return a.get_instance_id() < b.get_instance_id())
	t.check(houses.size() >= 2, "(two empty shelters)")
	if houses.size() < 2:
		return
	var blighted := houses[0]
	var plain := houses[1]
	crowd.footholds.append(blighted)
	var into := func(s: Structure) -> Person:
		var p := _put(crowd, s.center() + Vector2(0.0, 3.0))
		p.seek_shelter(s, s.center() + Vector2(0.0, 2.0))
		sm._enter(p, s)
		(sm.shelters[s].inside as Array).append(p)
		return p
	var doomed: Person = into.call(blighted)
	var spared: Person = into.call(plain)
	t.check(doomed.inside and doomed.shelter == blighted and (sm.shelters[blighted].inside as Array).has(doomed) and not field._enemies.has(doomed),
		"(a real shelterer: inside, on the shelter's list, out of the field)")
	var fx := _cast(ctx, at)
	_until(fx, fx.t_dawn + DT)
	t.check(not doomed.is_alive() and kinds.get(doomed.get_instance_id(), &"") == &"night" and not doomed.visible,
		"at dawn the shelterer in the blighted building is taken")
	t.check(not (sm.shelters[blighted].inside as Array).has(doomed), "and he is off the shelter's list")
	sm._flush(blighted, sm.shelters[blighted], false)
	sm._flush(plain, sm.shelters[plain], false)
	# (The field keeps a dead entry until its purge(), as for any death in the open: "in the field" is its living.)
	t.check(not doomed.is_alive() and not doomed.visible and not field.alive().has(doomed),
		"the shelter flushed: he stays taken, not visible, not back in the field")
	t.check(spared.is_alive() and spared.visible and not spared.inside and field._enemies.has(spared),
		"(control) the one in the plain shelter lives and is flushed out as ever")
	fx.end_now()
	crowd.footholds.clear()


## Cast during a running Dread: the Dread's people stay held.
static func _dread(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var d := at + Vector2(4.0, 0.0)
	crowd.lay_dusk(d, 1.5, 120.0)
	var p := _put(crowd, d)
	var dread := FxTimeline.cast(DreadOfTheDarkFx, ctx, at) as DreadOfTheDarkFx
	_go(dread, DreadOfTheDarkFx.T_FALL + DT)
	t.check(p.is_dreaded(), "control: the Dread holds him")
	var fx := _cast(ctx, at + Vector2(-10.0, 0.0))
	for i in roundi((E.WAVE + DT) / DT):
		fx._process(DT)
		dread._process(DT)
	t.check(p.is_dreaded() and not crowd.dreads.is_empty() and not dread.finished, "Evernight falls: the Dread's people are still held")
	fx.end_now()
	t.check(p.is_dreaded() and not crowd.dreads.is_empty(), "Evernight ended: the Dread still holds him")
	dread.end_now()


## Final review, Important 3: a Dread cast before a running Evernight, both ended by the act change (Battlefield.end_powers(): every
## FxTimeline in the overhead layer ended in cast order -- the loop below is that method's), lays no dusk of its own: no torch goes out
## and nobody is taken in that frame. Control: a Dread that runs its course lays one patch at the click when it lifts (VC1).
static func _dread_cut_short(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var d := at + Vector2(4.0, 0.0)
	crowd.lay_dusk(d, 1.5, 120.0)
	var held := _put(crowd, d)
	var bearer := _put(crowd, at + Vector2(1.5, 0.0), true)
	var huddler := _put(crowd, at + Vector2(1.5, 1.0))
	huddler.sleep(200.0, true)  # stays in the torch's light
	var dread := FxTimeline.cast(DreadOfTheDarkFx, ctx, at) as DreadOfTheDarkFx
	_go(dread, DreadOfTheDarkFx.T_FALL + DT)
	t.check(held.is_dreaded(), "(the Dread holds him)")
	var fx := _cast(ctx, at + Vector2(-10.0, 0.0))
	for i in roundi((E.WAVE + DT) / DT):
		fx._process(DT)
		dread._process(DT)
	t.check(fx.torches.size() == 1 and not fx.torches[0].out and E._in_light(huddler.ground_pos, fx.lit())
		and (fx.torches[0].at as Vector2).distance_to(at) <= VeilRules.DUSK_R + E.TORCH_R, "(a torch burns within a Dread dusk's reach of the click)")
	var patches := crowd.dusk.count()
	var alive := (crowd.citizens + crowd.soldiers).filter(func(p: Person) -> bool: return p.is_alive()).size()
	for c in ctx.overhead.get_children():
		# (Off the tree an ended effect frees its tracked nodes at once -- the Dread's shade is a sibling here.)
		if is_instance_valid(c) and c is FxTimeline:
			(c as FxTimeline).end_now()
	t.check(dread.finished and fx.finished and crowd.dusk.count() == patches, "the act ends: the Dread cut short lays no dusk (%d / %d patches)"
		% [crowd.dusk.count(), patches])
	t.check(fx.taken.is_empty() and bearer.is_alive() and huddler.is_alive() and held.is_alive()
		and (crowd.citizens + crowd.soldiers).filter(func(p: Person) -> bool: return p.is_alive()).size() == alive,
		"no torch goes out on it: nobody is taken in that frame")
	t.check(not held.is_dreaded() and crowd.dreads.is_empty(), "and the Dread lets go of its own")
	# Control: left to run, the Dread lays one patch when it lifts.
	at = _fresh(made)
	crowd.lay_dusk(at + Vector2(4.0, 0.0), 1.5, 120.0)
	var run := FxTimeline.cast(DreadOfTheDarkFx, ctx, at) as DreadOfTheDarkFx
	patches = crowd.dusk.count()
	_go(run, DreadOfTheDarkFx.T_FALL + DreadOfTheDarkFx.HOLD + DT)
	t.check(crowd.dusk.count() == patches + 1 and crowd.dusk.covers(at), "(control) a Dread that runs its course lays one patch at the click")
	run.end_now()


## C16 and the haste, through Rules: Evernight locks the other slots only for its wave; then a Veil power casts while the night runs,
## and its dusk on a torch puts the torch out. The Veil's running cooldown runs at 2x, the once-a-descent one does not; at dawn 1x.
static func _rules(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var x := at + Vector2(0.0, -8.0)
	var s := _put(crowd, x, true)
	var a := _put(crowd, x + Vector2(1.0, 0.0))
	a.sleep(200.0, true)
	var rules := Rules.new().setup(PackedStringArray(["evernight", "cloak"]), null, made[1], made[3], crowd, made[6])
	ctx.rules = rules
	var casts: Array = []
	rules.caster = func(sc: GDScript, g: Vector2, e: Dictionary) -> FxTimeline:
		var f := FxTimeline.cast(sc, ctx, g, e)
		casts.append(f)
		return f
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, why: String) -> void: refused.append([slot, why]))
	var fx := rules.cast(0, at) as EvernightFx
	t.check(fx != null and refused.is_empty(), "Evernight goes out")
	if fx == null:
		ctx.rules = null
		rules.free()
		return
	_go(fx, 1.0)
	var early := rules.cast(1, x)
	t.check(early == null and refused == [[1, "busy"]] and rules.busy_left() > 0.0, "during the wave the other slots are locked")
	refused.clear()
	_until(fx, E.WAVE + DT)
	t.check(rules.busy_left() == 0.0 and fx.torches.size() == 1, "(the night has fallen; one torch)")
	var cloak := rules.cast(1, x)
	t.check(cloak != null and refused.is_empty() and not fx.finished, "after the wave a Veil power casts while the night runs (%s)" % [refused])
	t.check(fx.torches[0].out and not a.is_alive() and not s.is_alive(), "its dusk on the torch puts it out: its light's people are taken")
	var cl := rules.cooldown_left(1)
	var once := rules.cooldown_left(0)
	rules.advance(1.0)
	t.check(is_equal_approx(cl - rules.cooldown_left(1), 2.0), "the Veil's running cooldown runs at 2x (%.2f)" % (cl - rules.cooldown_left(1)))
	t.check(is_equal_approx(once - rules.cooldown_left(0), 1.0), "the once-a-descent one does not")
	if cloak != null and is_instance_valid(cloak):
		cloak.end_now()
	fx.end_now()
	cl = rules.cooldown_left(1)
	rules.advance(1.0)
	t.check(rules.haste.is_empty() and is_equal_approx(cl - rules.cooldown_left(1), 1.0), "ended: 1x again")
	ctx.rules = null
	rules.free()


## Teardown at 10 s by end_now() and by a freed node: the dark, the veil, the haste, the sight, the light and the lamps as they were, the
## torches gone, the bearer back at his post, nobody else taken. A Dread, a Cloak, a plain veil and a dusk patch going on meanwhile are
## left alone (positive control: each still works after).
static func _teardown(t, made: Array) -> void:
	for mode in ["end_now", "free"]:
		var crowd: Crowd = made[0]
		var ctx: FxContext = made[5]
		var at := _fresh(made)
		var rules := Rules.new()
		ctx.rules = rules
		var lamp := ctx.lights.add_static(at + Vector2(5.0, 5.0), 3.0, Color.WHITE, 1.0)
		var d := at + Vector2(4.0, 0.0)
		crowd.lay_dusk(d, 1.5, 120.0)
		var held := _put(crowd, d)
		var cloaked := _put(crowd, at + Vector2(-12.0, 8.0))
		crowd.mission_keeps.append(func(p: Person) -> bool: return p == held or p == cloaked)
		var y := at + Vector2(-12.0, -10.0)
		crowd.veil(y, 2.0, 120.0)
		var dread := FxTimeline.cast(DreadOfTheDarkFx, ctx, at) as DreadOfTheDarkFx
		var cloak := FxTimeline.cast(CloakOfNightFx, ctx, cloaked.ground_pos) as CloakOfNightFx
		var x := at + Vector2(0.0, -10.0)
		var s := _put(crowd, x, true)
		var post := Vector2(-20.0, 20.0)
		s.post = post
		var l := _layout(crowd, at + Vector2(0.0, 10.0))
		var fx := _cast(ctx, at + Vector2(-2.0, 0.0))
		for i in roundi(10.0 / DT):
			fx._process(DT)
			dread._process(DT)
			cloak._process(DT)
		var took := fx.taken.size()
		t.check(crowd.dusk.everywhere and rules.haste.has("veil") and crowd.sight_scale < 1.0 and ctx.lights.ambient < 1.0
			and fx.torches.size() == 1 and took >= 3, "%s: control: at 10 s the night holds, one torch, %d taken" % [mode, took])
		var torch := int(fx.torches[0].light)
		var alive := (crowd.citizens + crowd.soldiers).filter(func(p: Person) -> bool: return p.is_alive()).size()
		if mode == "end_now":
			fx.end_now()
		else:
			fx.free()
		t.check(not crowd.dusk.everywhere and not crowd.is_veiled(at + Vector2(20.0, 20.0)) and not crowd.in_dark(at + Vector2(20.0, 20.0)),
			"%s: the dark and the town-wide veil are gone" % mode)
		t.check(rules.haste.is_empty() and crowd.sight_scale == 1.0, "%s: no haste, full sight" % mode)
		t.check(ctx.lights.ambient == 1.0 and ctx.lights.tint == Color.WHITE and float(_light(ctx.lights, lamp).intensity) == 1.0
			and ctx.lights._mute_below == -1 and _light(ctx.lights, torch).is_empty(), "%s: the light as it was, the lamp lit, the torch gone" % mode)
		t.check(s.anchor == post, "%s: the bearer goes back to his post" % mode)
		t.check(crowd.is_veiled(y) and crowd.in_dark(d), "%s: the plain veil and the dusk patch are left alone" % mode)
		t.check(held.is_dreaded() and not crowd.dreads.is_empty() and not dread.finished, "%s: the Dread still holds" % mode)
		t.check(cloaked.statuses.has(CloakOfNightFx.KEY) and not cloak.finished, "%s: the Cloak still cloaks" % mode)
		for i in roundi(10.0 / DT):
			dread._process(DT)
			cloak._process(DT)
		var after := (crowd.citizens + crowd.soldiers).filter(func(p: Person) -> bool: return p.is_alive()).size()
		t.check(after == alive and (l.lone as Person).is_alive() == false, "%s: nobody else taken (%d / %d)" % [mode, after, alive])
		dread.end_now()
		cloak.end_now()
		t.check(not held.is_dreaded() and not cloaked.statuses.has(CloakOfNightFx.KEY), "%s: positive control: the Dread and the Cloak end their own" % mode)
		ctx.rules = null
		rules.free()


## Two Evernights: the first ended leaves the second's night; the second ended puts the town back (own instance ids, no statics).
static func _two(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var rules := Rules.new()
	ctx.rules = rules
	var a := _cast(ctx, at)
	var b := _cast(ctx, at + Vector2(5.0, 0.0))
	for i in roundi((E.WAVE + DT) / DT):
		a._process(DT)
		b._process(DT)
	t.check(crowd.dusk.everywhere and rules.haste.has("veil") and crowd.sight_scale < 1.0, "two nights fall")
	a.free()
	t.check(crowd.dusk.everywhere and float(rules.haste.get("veil", 0.0)) == 2.0 and crowd.sight_scale < 1.0 and crowd.is_veiled(at)
		and ctx.lights.ambient < 1.0, "the first freed: the second's night holds")
	b._process(DT)
	t.check(is_equal_approx(ctx.lights.ambient, TownLook.ambient(Town.Look.NIGHT)), "and its look goes on")
	b.end_now()
	t.check(not crowd.dusk.everywhere and rules.haste.is_empty() and crowd.sight_scale == 1.0 and not crowd.is_veiled(at)
		and ctx.lights.ambient == 1.0 and ctx.lights._mute_below == -1, "the second ended: the town as it was")
	ctx.rules = null
	rules.free()


## The god's look: a wash in the ground layer whose front runs out from the click, full at the wave's end, the torches' rings; gone
## with the cast.
static func _look(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	_put(crowd, at + Vector2(0.0, -6.0), true)
	var fx := _cast(ctx, at)
	var wash := fx.wash
	t.check(wash != null and wash.get_parent() == ctx.ground, "a night wash on the ground layer")
	_go(fx, 1.0)
	t.check(wash.strength > 0.0 and wash.strength < 1.0 and is_equal_approx(wash.front, wash.map.size.x / E.WAVE * fx.t),
		"the front runs at map-width / 3 s (%.1f)" % wash.front)
	_until(fx, E.WAVE + DT)
	t.check(wash.strength == 1.0 and wash.lit.size() == 1, "full at the wave's end; the torch's ring drawn")
	# Spec 6: stars and a pale moon in the sky wash (the moon drawn in code, a fixed place: no luck).
	var moon := wash.get_node_or_null(^"Moon")
	t.check(moon != null and moon.get_parent() == wash, "the wash holds its pale moon while the night runs")
	fx.end_now()
	t.check(not is_instance_valid(wash) or wash.is_queued_for_deletion() or wash.get_parent() == null, "the wash goes with the cast")
	t.check(moon == null or not is_instance_valid(moon) or moon.is_queued_for_deletion(), "and no moon is left after it ends")


## True when `n` is freed or on its way out (it, or a parent, queued for deletion).
static func _gone(n: Variant) -> bool:
	if n == null or not is_instance_valid(n):
		return true
	var at: Node = n
	while at != null:
		if at.is_queued_for_deletion():
			return true
		at = at.get_parent()
	return false


## Review round (VRD, spec 7): the night seen over the town. With the layers there: the shade (multiplied), the air over it and the wall
## over both on the overhead_back layer; the moon top-level in the sky; a warm glow per torch on the overhead layer, out with its torch;
## a dark wisp for each take; the wall stands on the running front and is down through the night. All go with end_now() and with a
## freed cast.
static func _sky(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	for mode in ["end_now", "free"]:
		var at := _fresh(made)
		ctx.overhead_back = Node2D.new()
		_put(crowd, at + Vector2(0.0, -6.0), true)
		_put(crowd, at + Vector2(12.0, 12.0))
		var fx := _cast(ctx, at)
		# Absolute z (VRF1): the shade at 2, the air, the wall and the moon at 3 (tree order: the moon, the air, the wall), all under the
		# aim's 5 and over the world's 0-1. Pinned on purpose; _layers() reads the order against a real Battlefield.
		t.check(fx._shade != null and fx._shade.get_parent() == ctx.overhead_back and not fx._shade.z_as_relative and fx._shade.z_index == 2
			and fx._shade.mat.shader == EvernightSky.SH_SHADE, "%s: the night's shade over the town (overhead_back, absolute 2)" % mode)
		t.check(fx._air != null and fx._air.get_parent() == ctx.overhead_back and not fx._air.z_as_relative and fx._air.z_index == 3
			and fx._wall != null and fx._wall.get_parent() == ctx.overhead_back and not fx._wall.z_as_relative and fx._wall.z_index == 3
			and fx._wall.get_index() > fx._air.get_index() and fx.wash.moon.z_index == 3,
			"%s: the air over it, the wall over both (absolute 3)" % mode)
		t.check(fx.wash.moon.top_level and not fx.wash.moon.z_as_relative, "%s: the moon hangs in the sky (top level)" % mode)
		_go(fx, 1.0)
		t.check(fx._wall.amount > 0.0 and is_equal_approx(fx._wall.front, fx.look_front()) and fx._wall.front > 0.0,
			"%s: the wall stands on the running front (%.1f)" % [mode, fx._wall.front])
		_until(fx, E.WAVE + 0.5)
		t.check(fx._wall.amount == 0.0, "%s: through the night the wall is down" % mode)
		t.check(fx._glows.size() == 1 and fx.torches.size() == 1 and (fx._glows[0] as Node).get_parent() == ctx.overhead
			and (fx._glows[0] as EvernightSky.TorchGlow).lit, "%s: a warm glow round the torch" % mode)
		var wisps := func() -> int:
			var n := 0
			for c in ctx.overhead.get_children():
				if c is PixelParticles and not c.is_queued_for_deletion() and (c as PixelParticles).ramp[0] == EvernightSky.WISP[0]:
					n += 1
			return n
		var before: int = wisps.call()
		var look: Variant = fx._claim_looks.values()[0] if fx._claim_looks.size() == 1 else null
		t.check(fx.claimed.size() == 1 and look != null and (look as Node).get_parent() == ctx.overhead_back,
			"%s: the claimed one's look on overhead_back" % mode)
		_until(fx, E.WAVE + fx.take_every + DT)
		t.check(_gone(look), "%s: taken, his claim's look goes with him" % mode)
		t.check(fx.taken.size() == 1 and wisps.call() == before + 1, "%s: the take leaves a dark wisp (%d taken)" % [mode, fx.taken.size()])
		fx.put_out(0)
		fx._process(DT)
		t.check(not (fx._glows[0] as EvernightSky.TorchGlow).lit, "%s: the glow goes out with its torch" % mode)
		var pieces: Array = [fx._shade, fx._air, fx._wall, fx._glows[0], fx.wash.moon, fx.stains]
		if mode == "end_now":
			fx.end_now()
		else:
			fx.free()
		var left := pieces.filter(func(n: Variant) -> bool: return not _gone(n))
		t.check(left.is_empty(), "%s: every piece of the look is gone (%d left)" % [mode, left.size()])
		ctx.overhead_back.free()
		ctx.overhead_back = null


## Final review, Important 2 (VRF2): two overlapping Evernights show one sky. The first cast (the light look's owner) shows its shade,
## air, wall and moon; the second adds none. Through the first's dawn the sky stays at the second's full night (no roll-back, no flash
## of day); the first ended, the second's pieces show at once; both ended, none is left.
static func _one_sky(t, made: Array) -> void:
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	ctx.overhead_back = Node2D.new()
	var a := _cast(ctx, at)
	var b: EvernightFx = null
	var shown := func(n: Variant) -> bool: return not _gone(n) and (n as CanvasItem).visible
	var worst := {"shade": 0, "air": 0, "wall": 0, "moon": 0, "none": 0}
	var rolled := [false, false]  # the front shown rolled back during the first's dawn; the ambient eased toward the day
	var i := 0
	while a.t < a.duration - 0.2:
		if i == roundi(30.0 / DT):  # well inside the first night: the second's dawn is half a minute after the first's
			b = _cast(ctx, at + Vector2(4.0, 0.0))
		i += 1
		a._process(DT)
		if b != null:
			b._process(DT)
		if b != null and a.t > a.t_dawn + 0.2:
			var sh: EvernightSky.View = a._shade if shown.call(a._shade) else b._shade
			if float(sh.mat.get_shader_parameter(&"front")) < b.look_front() - 0.01:
				rolled[0] = true
			if ctx.lights.ambient > TownLook.ambient(Town.Look.NIGHT) + 0.01:
				rolled[1] = true
		for k in ["shade", "air", "wall", "moon"]:
			var c := 0
			for fx: EvernightFx in ([a, b] if b != null else [a]):
				if shown.call(fx.wash.moon if k == "moon" else fx.get("_" + k)):
					c += 1
			worst[k] = maxi(int(worst[k]), c)
			if c == 0:
				worst.none = int(worst.none) + 1
	t.check(b != null and int(worst.shade) == 1 and int(worst.air) == 1 and int(worst.moon) == 1 and int(worst.wall) <= 1
		and int(worst.none) == 0, "two nights: one shade, one air, one moon at any time (%s)" % [worst])
	t.check(shown.call(a._shade) and not shown.call(b._shade) and not shown.call(b._air) and not shown.call(b.wash.moon),
		"the first cast's sky shows; the second adds none")
	t.check(not rolled[0] and not rolled[1], "through the first's dawn the sky holds the second's night (front %s, day %s)" % rolled)
	var pieces: Array = [a._shade, a._air, a._wall, a.wash.moon, b._shade, b._air, b._wall, b.wash.moon]
	a.end_now()
	t.check(shown.call(b._shade) and shown.call(b._air) and shown.call(b.wash.moon) and b.wash.moon.strength == 1.0
		and float(b._shade.mat.get_shader_parameter(&"front")) >= b.look_front() - 0.01,
		"the first ended: the second's sky shows at once, at its full night")
	b.end_now()
	var left := pieces.filter(func(n: Variant) -> bool: return not _gone(n))
	t.check(left.is_empty(), "both ended: no piece of either sky is left (%d)" % left.size())
	ctx.overhead_back.free()
	ctx.overhead_back = null


## VRF5c, VRF5d: the shade's torch array fits TORCHES (the pair named on both sides); at dawn the torches are out for the rules at
## once, but their glows and islands fade with the night over DAWN.
static func _dawn_glow(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var code := EvernightSky.SH_SHADE.code
	t.check(E.TORCHES <= EvernightSky.SHADE_TORCHES and code.contains("uniform vec2 torches[%d];" % EvernightSky.SHADE_TORCHES)
		and code.contains("SHADE_TORCHES"), "the shade's torches[] is EvernightSky.SHADE_TORCHES, and TORCHES fits")
	var at := _fresh(made)
	_put(crowd, at + Vector2(0.0, -6.0), true)
	var fx := _cast(ctx, at)
	_until(fx, E.WAVE + 0.5)
	var glow: EvernightSky.TorchGlow = fx._glows[0] if fx._glows.size() == 1 else null
	t.check(glow != null and glow.lit and glow.fade == 1.0, "a torch's glow burns through the night")
	_until(fx, fx.t_dawn + E.DAWN * 0.5)
	t.check(fx.lit().is_empty() and fx.look_lit().size() == 1 and glow.lit and glow.fade > 0.3 and glow.fade < 0.7,
		"half way through the dawn: out for the rules, its glow and island half faded (%.2f)" % glow.fade)
	_until(fx, fx.duration - 0.05)
	t.check(fx.look_lit().size() <= 1 and glow.fade < 0.05, "faded by the dawn's end (%.2f)" % glow.fade)
	fx.end_now()
	t.check(_gone(glow), "and gone with the cast")


## The absolute z of `n`: its own z and its parents' while they are relative.
static func _abs_z(n: CanvasItem) -> int:
	var z := 0
	var at: Node = n
	while at is CanvasItem:
		z += (at as CanvasItem).z_index
		if not (at as CanvasItem).z_as_relative:
			break
		at = at.get_parent()
	return z


## Final review, Important 1 (VRF1): on a real Battlefield the aim (Targeting, where the mission puts it) draws over Evernight's
## shade, air, wall and moon, Unseen Hour's blanket and Dread's far wall; the shade still lies over the world. Read from the nodes.
static func _layers(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	_fresh(made)
	var bf := Battlefield.new()
	t.root.add_child(bf)
	await t.process_frame
	var rules := Rules.new()
	var aim := Targeting.new()
	bf.ground_plane.add_child(aim)
	aim.setup(rules, crowd)
	var at := Vector2(10.0, 10.0)
	var night := _cast(bf.ctx, at)
	var veil := FxTimeline.cast(UnseenHourFx, bf.ctx, at) as UnseenHourFx
	bf.ctx.crowd = crowd
	var dread := FxTimeline.cast(DreadOfTheDarkFx, bf.ctx, at) as DreadOfTheDarkFx
	bf.ctx.crowd = null
	var aim_z := _abs_z(aim)
	var world_z := _abs_z(bf.ctx.world)
	t.check(night._shade != null and _abs_z(night._shade) < aim_z and _abs_z(night._shade) > world_z + 1,
		"the night's shade lies over the world and under the aim (%d < %d)" % [_abs_z(night._shade) if night._shade else 0, aim_z])
	t.check(_abs_z(night._air) < aim_z and _abs_z(night._wall) < aim_z and _abs_z(night.wash.moon) < aim_z
		and _abs_z(night.wash.moon) > _abs_z(night._shade) and _abs_z(night._air) >= _abs_z(night.wash.moon),
		"the air, the wall and the moon under the aim; the moon over the shade, the air over the moon")
	t.check(veil.blanket != null and _abs_z(veil.blanket) < aim_z and _abs_z(veil.blanket) > world_z + 1,
		"Unseen Hour's blanket hangs over the world and under the aim (%d)" % (_abs_z(veil.blanket) if veil.blanket else 0))
	var back: Node2D = dread.shade.back if dread.shade != null else null
	t.check(back != null and _abs_z(back) < aim_z and _abs_z(back) > world_z + 1,
		"Dread's far wall stands over the world and under the aim (%d)" % (_abs_z(back) if back else 0))
	for fx: FxTimeline in [night, veil, dread]:
		fx.end_now()
	await t.process_frame
	rules.free()
	t.root.remove_child(bf)
	bf.free()


static func _quiet(t) -> void:
	var src := FileAccess.get_file_as_string("res://src/fx/veil/evernight.gd")
	t.check(src != "" and not src.contains("add_alarm") and not src.contains("fright(") and not src.contains("panic(") and not src.contains("on_cast")
		and not src.contains("randf") and not src.contains("randi") and not src.contains("ctx.rng") and not src.contains("register(")
		and not src.contains("_voice"), "the code never alarms, frightens, panics, registers a danger, voices or rolls")
	t.check(not src.contains("lay_dusk") and not src.contains("VeilParts.land"), "it lays no dusk patch of its own (VC7)")


## No crowd, no rules (the VFX Sandbox): it builds at the light size and finishes, the light given back.
static func _no_crowd(t) -> void:
	for with_lights in [false, true]:
		var ctx := FxContext.new()
		ctx.rng = RandomNumberGenerator.new()
		ctx.overhead = Node2D.new()
		ctx.ground = Node2D.new()
		ctx.world = Node2D.new()
		if with_lights:
			ctx.lights = LightField.new()
		var fx := _cast(ctx, Vector2.ZERO)
		t.check(fx != null and fx.night_time == 60.0 and fx.torches.is_empty(), "no crowd (lights %s): builds at the light size" % with_lights)
		for i in roundi((fx.duration + 0.5) / DT):
			if not fx.finished:
				fx._process(DT)
		t.check(fx.finished, "no crowd (lights %s): finishes without an error" % with_lights)
		if with_lights:
			t.check(ctx.lights.ambient == 1.0 and ctx.lights.tint == Color.WHITE and not ctx.lights.has_meta(E.LOOK_KEY), "and the light is given back")
			ctx.lights.free()
		ctx.overhead.free()
		ctx.ground.free()
		ctx.world.free()
	# A bare context: no ground, no crowd.
	var bare := FxContext.new()
	bare.rng = RandomNumberGenerator.new()
	bare.overhead = Node2D.new()
	var fb := _cast(bare, Vector2.ZERO)
	for i in roundi((fb.duration + 0.5) / DT):
		if not fb.finished:
			fb._process(DT)
	t.check(fb.finished and fb.stains == null and fb.claimed.is_empty() and fb.takes == 29, "a bare context (no ground, no crowd): builds and finishes")
	bare.overhead.free()
