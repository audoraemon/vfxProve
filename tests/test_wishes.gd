extends RefCounted
## v0.11 M1 wishes (spec §5): the pool's words and rewards; the draw -- seeded (a restart hears the same, review focus 3),
## filtered by clashes and by what the town can give, never two sharing a person; five wishes' acts; a wisher dying fails a
## wish, a granted one makes them a Believer (review focus 2); and the Descent hearing, stepping, banking and losing them.

const DT := 0.05


static func run(t) -> void:
	_pool(t)
	_draw(t)
	_ruin(t)
	_punish(t)
	_sign(t)
	_wisher(t)
	_descent(t)
	_reserved(t)


static func _world() -> Dictionary:
	var def := TierBook.board("warning")
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
	var director := def.make_director().setup(rules, crowd, town, null)
	rules.director = director
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	return {"def": def, "env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules,
		"d": director, "banners": banners}


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


static func _rng(n: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = n
	return r


static func _def(id: String) -> WishDef:
	for d in WishBook.pool():
		if d.id == id:
			return d
	return null


## A wish of the pool's `id`, given its people from the world (with `seed`); null when the town cannot give them.
static func _wish(s: Dictionary, id: String, seed_n := 3) -> Wish:
	var w := _def(id).instance()
	return w if w.choose(s.crowd, s.town, _rng(seed_n), []) else null


static func _ids(wishes: Array[Wish]) -> Array:
	var out := []
	for w in wishes:
		out.append(w.def.id)
	return out


static func _release(wishes: Array[Wish]) -> void:
	for w in wishes:
		w.release()


## Everyone but `keep` within `reach` of `at` moved well away, so nobody but `keep` can witness there.
static func _clear_round(s: Dictionary, at: Vector2, reach: float, keep: Array) -> void:
	var crowd: Crowd = s.crowd
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and not keep.has(p) and p.ground_pos.distance_to(at) <= reach:
				p.ground_pos = at + Vector2(reach + 6.0, reach + 6.0)


static func _pool(t) -> void:
	var rows := {}
	for d in WishBook.pool():
		rows[d.id] = [d.text, d.kind, d.reward]
	t.check(rows.get("moneylender") == ["Burn the moneylender's house", "ruin", 10]
		and rows.get("watchtower") == ["Bring down the watchtower", "ruin", 15]
		and rows.get("tax_collector") == ["Strike down the cruel tax collector", "punish", 10]
		and rows.get("informer") == ["Kill the informer, unseen", "punish", 15]
		and rows.get("sign") == ["Show me a sign", "sign", 5], "the spec's wishes, word for word (%s)" % [rows])
	t.check(Array(_def("moneylender").clashes) == ["spares_houses"] and _def("watchtower").clashes.is_empty(),
		"the moneylender's house clashes with spares_houses")
	var w := _def("sign").instance()
	t.check(w is SignWish and w.def.id == "sign" and w.status == Objective.Status.PENDING and not w.timed() and not w.engage(),
		"a fresh wish of its kind, open, not timed")
	t.check(Wish.state_name(Objective.Status.PENDING) == "open" and Wish.state_name(Objective.Status.DONE) == "granted"
		and Wish.state_name(Objective.Status.FAILED) == "failed", "its states' names")


static func _draw(t) -> void:
	var s := _world()
	var a := WishBook.draw(WishBook.pool(), 2, PackedStringArray(), s.crowd, s.town, _rng(11))
	var b := WishBook.draw(WishBook.pool(), 2, PackedStringArray(), s.crowd, s.town, _rng(11))
	t.check(a.size() == 2 and _ids(a) == _ids(b) and a[0].wisher == b[0].wisher and a[1].wisher == b[1].wisher,
		"the same seed hears the same wishes, from the same wishers (%s)" % [_ids(a)])
	_release(a)
	_release(b)
	var lists := {}
	for n in range(1, 11):
		var drawn := WishBook.draw(WishBook.pool(), 2, PackedStringArray(), s.crowd, s.town, _rng(n))
		lists[str(_ids(drawn))] = true
		_release(drawn)
	t.check(lists.size() > 1, "other seeds draw otherwise (%d different draws in 10)" % lists.size())
	var clashed := false
	for n in range(1, 21):
		var drawn := WishBook.draw(WishBook.pool(), 5, PackedStringArray(["spares_houses"]), s.crowd, s.town, _rng(n))
		clashed = clashed or _ids(drawn).has("moneylender")
		_release(drawn)
	t.check(not clashed, "a wish that clashes with the mission's tags is never drawn")
	var all := WishBook.draw(WishBook.pool(), 10, PackedStringArray(), s.crowd, s.town, _rng(4))
	var people := []
	var shared := false
	for w in all:
		for p: Variant in [w.wisher, w.get("target")]:
			if p != null:
				shared = shared or people.has(p)
				people.append(p)
	t.check(all.size() == WishBook.pool().size() and not shared, "asked for more than there are, it offers what it can; none share")
	_release(all)
	for st: Structure in (s.town as Town)._built:
		if RuinWish.fits(st, "house"):
			st.destroyed = true
	var no_house := WishBook.draw(WishBook.pool(), 10, PackedStringArray(), s.crowd, s.town, _rng(4))
	t.check(not _ids(no_house).has("moneylender") and _ids(no_house).has("watchtower"), "no house standing: no moneylender")
	_release(no_house)
	for p in (s.crowd as Crowd).citizens:
		if is_instance_valid(p) and p.profile != null:
			p.profile.faith = CitizenProfile.Faith.FAITHFUL
	t.check(WishBook.draw(WishBook.pool(), 3, PackedStringArray(), s.crowd, s.town, _rng(4)).is_empty(),
		"nobody to wish: no wishes, and no error")
	_done(s)


static func _ruin(t) -> void:
	var s := _world()
	var w := _wish(s, "moneylender") as RuinWish
	t.check(w != null and RuinWish.fits(w.target, "house") and w.target.art_tag in [&"", &"townhouse"], "the moneylender's is a dwelling")
	var tags := w.tags()
	t.check(tags.size() == 2 and tags[0].label == "MONEYLENDER" and tags[0].color == Wish.COLOR and tags[0].at == w.target.center()
		and tags[1].label == Wish.WISHER_LABEL and tags[1].at == w.wisher.ground_pos, "its house and its wisher are tagged in blue")
	t.check(w.check(s.rules) == Objective.Status.PENDING and w.hud_text(s.rules) == "Burn the moneylender's house (+0)", "open")
	w.target.destroyed = true
	t.check(w.check(s.rules) == Objective.Status.DONE and w.tags().is_empty(), "destroyed: granted, its tags gone")
	w.target.destroyed = false
	t.check(w.check(s.rules) == Objective.Status.DONE, "and it stays granted")
	var tower := _wish(s, "watchtower") as RuinWish
	t.check(tower != null and tower.target.role == &"tower" and tower.target.art_tag != &"bell_tower", "the watchtower is no bell tower")
	_done(s)


## The crowd judges its own doomed (a frame), then the wish steps -- as Rules.advance() does for a night.
static func _settle(s: Dictionary, w: Wish) -> void:
	(s.crowd as Crowd).advance(DT)
	w.step(s.rules, DT)


static func _punish(t) -> void:
	var s := _world()
	var w := _wish(s, "tax_collector") as PunishWish
	t.check(w != null and w.target != w.wisher and w.tags()[0].label == "TAX COLLECTOR", "the tax collector, tagged")
	(s.field as EnemyField).kill(w.target, &"doom", w.target.ground_pos)
	_settle(s, w)
	t.check(w.check(s.rules) == Objective.Status.DONE, "struck down: granted, seen or not")
	w.release()
	var seen := _wish(s, "informer", 5) as PunishWish
	var witness: Person = null
	for p in (s.crowd as Crowd).citizens:
		if MissionDirector._alive(p) and p != seen.target and p != seen.wisher:
			witness = p
			break
	witness.ground_pos = seen.target.ground_pos + Vector2(1.0, 0.0)
	(s.field as EnemyField).kill(seen.target, &"doom", seen.target.ground_pos)
	_settle(s, seen)
	t.check(seen.check(s.rules) == Objective.Status.FAILED, "the informer killed with a witness near: failed")
	seen.release()
	var unseen := _wish(s, "informer", 6) as PunishWish
	_clear_round(s, unseen.target.ground_pos, Crowd.DOOM_WITNESS + 0.5, [unseen.target])
	(s.field as EnemyField).kill(unseen.target, &"doom", unseen.target.ground_pos)
	_settle(s, unseen)
	t.check(unseen.check(s.rules) == Objective.Status.DONE, "killed with nobody near: granted")
	unseen.release()
	_done(s)


static func _sign(t) -> void:
	var s := _world()
	var w := _wish(s, "sign") as SignWish
	w.on_cast("doom", w.wisher.ground_pos + Vector2(SignWish.REACH + 0.5, 0.0))
	t.check(w.check(s.rules) == Objective.Status.PENDING, "a cast too far is not seen")
	w.wisher.inside = true
	w.on_cast("doom", w.wisher.ground_pos)
	t.check(w.check(s.rules) == Objective.Status.PENDING, "nor one cast while they are indoors")
	w.wisher.inside = false
	w.on_cast("doom", w.wisher.ground_pos + Vector2(SignWish.REACH - 0.1, 0.0))
	t.check(w.check(s.rules) == Objective.Status.DONE, "one within 4 is a sign: granted")
	_done(s)


static func _wisher(t) -> void:
	var s := _world()
	var w := _wish(s, "watchtower")
	(s.field as EnemyField).kill(w.wisher, &"doom")
	t.check(w.check(s.rules) == Objective.Status.FAILED and w.tags().is_empty(), "the wisher dead first: the prayer goes unanswered")
	var g := _wish(s, "sign", 9)
	g.on_cast("doom", g.wisher.ground_pos)
	g.check(s.rules)
	g.grant()
	t.check(g.wisher.profile.faith == CitizenProfile.Faith.BELIEVER, "a granted wish makes its wisher a Believer")
	_done(s)


static func _descent(t) -> void:
	var s := _world()
	var rules: Rules = s.rules
	var d := Descent.new().setup(s.def, 7)
	d.attach(rules, s.d)
	t.check(d.wishes.size() == TierBook.wishes(1) and not _ids(d.wishes).has("child"), "Tier 1 hears two (%s)" % [_ids(d.wishes)])
	var again := Descent.new().setup(s.def, 7)
	again.attach(rules, MissionDirector.new())
	t.check(_ids(again.wishes) == _ids(d.wishes), "a restart of the night hears the same wishes (review focus 3)")
	again.release()
	d.attach(rules, s.d)
	t.check(d.wishes.size() == TierBook.wishes(1), "a later act hears none again (review focus 5)")
	d.release()
	var sign := _wish(s, "sign", 9)
	sign.reward = d.reward(sign.def.reward)
	d.wishes.assign([sign])
	rules.cast_made.emit(0, "doom", sign.wisher.ground_pos)
	_run_rules(rules)
	t.check(sign.status == Objective.Status.DONE and (s.banners as Array).has(Descent.GRANTED_BANNER)
		and sign.wisher.profile.faith == CitizenProfile.Faith.BELIEVER, "a cast by the wisher grants it: its banner, a Believer")
	t.check(d.tags().is_empty(), "a granted wish is no longer tagged")
	for w in (s.d as StarfallDirector).stars:
		w.warning_dead = true
	_run_rules(rules)
	var rep: Dictionary = d.report(rules).descend
	t.check(int(rep.earned) == 10 and bool((rep.wishes as Array)[0].lost) and String(rep.lost_text) == Descent.LOST_ANY
		and int(rep.kept) == 0, "held open, the granted wish is not yet banked (%s)" % [rep])
	rules.ascend()
	rep = d.report(rules).descend
	var row: Dictionary = (rep.wishes as Array)[0]
	t.check(int(rep.earned) == 15 and int(rep.kept) == 1 and String(row.state) == "granted" and not bool(row.lost)
		and String(row.text) == "Show me a sign" and int(row.reward) == 5, "ascended: the main 10 and the sign's 5 (%s)" % [rep])
	_done(s)


static func _run_rules(rules: Rules) -> void:
	rules.advance(DT)


## Every wisher and wish target is reserved on the director (preflight ruling): the Descent hears at attach, and a later
## star's watchman is never one of them.
static func _reserved(t) -> void:
	var s := _world()
	var d := Descent.new().setup(s.def, 7)
	d.attach(s.rules, s.d)
	var folk: Array[Person] = []
	for w in d.wishes:
		folk.append_array(w.people())
	var all_in := not folk.is_empty()
	for p in folk:
		all_in = all_in and (s.d as MissionDirector).reserved.has(p)
	t.check(all_in, "every wisher and wish target is reserved on the director (%d people)" % folk.size())
	# The nearest citizen to a star's gate is a wisher: the watchman must be someone else.
	var starfall: StarfallDirector = s.d
	var wisher: Person = d.wishes[0].wisher
	wisher.ground_pos = StarfallDirector.STARS[0][1]
	starfall._clock = StarfallDirector.STARS[0][0] - WarningDirector.OMEN_AT - 0.05
	_run_rules(s.rules)
	var watchman: Person = starfall.stars[0].watchman
	t.check(starfall.stars[0].rules != null and watchman != null and not folk.has(watchman) and watchman != wisher,
		"a star's watchman is never a wisher or a wish target")
	d.release()
	_done(s)
