extends RefCounted
## v0.11 M4 Wrath's two wishes (mission spec §5): the pool grows to fourteen, the two new ones heard from Wrath up (min_tier 3), so
## Tier 1 and Tier 2 nights shuffle exactly what they did. Burn the tithe barn: a farm barn outside the walls (never a mill), granted
## when it falls, its tag pointed at; it clashes with razes_bread. Strike down the cruel sergeant: a soldier of no corps out of doors,
## granted at his death, failed if he leaves the town or the wisher dies, his tag pointed at, reserved like every wish target.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_pool(t)
	_draws(t)
	_barn(t)
	_sergeant(t)
	_sergeant_ends(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.crowns_bread(), MissionDirector.new())


static func _def(id: String) -> WishDef:
	for d in WishBook.pool():
		if d.id == id:
			return d
	return null


static func _wish(s: Dictionary, id: String, seed_n := 3) -> Wish:
	var r := RandomNumberGenerator.new()
	r.seed = seed_n
	var w := _def(id).instance()
	return w if w.choose(s.crowd, s.town, r, []) else null


static func _ids(list: Array) -> Array:
	var out := []
	for x in list:
		out.append(x.id if x is WishDef else (x as Wish).def.id)
	return out


static func _pool(t) -> void:
	var all := _ids(WishBook.pool())
	t.check(all.size() == 16 and all.slice(12, 14) == ["barn", "sergeant"], "the pool: M3's twelve, then Wrath's two (%s)" % [all])
	var barn := _def("barn")
	var sergeant := _def("sergeant")
	t.check(barn.text == "Burn the tithe barn" and barn.kind == "ruin" and barn.reward == 10 and barn.min_tier == 3
		and Array(barn.clashes) == ["razes_bread"] and barn.runner == RuinWish and String(barn.params.role) == "barn"
		and sergeant.text == "Strike down the cruel sergeant" and sergeant.kind == "punish"
		and sergeant.reward == 15 and sergeant.min_tier == 3 and sergeant.clashes.is_empty() and sergeant.runner == PunishWish
		and bool(sergeant.params.soldier) and bool(sergeant.params.edge) and not bool(sergeant.params.unseen),
		"their words, kinds, rewards, parameters; heard from Wrath up; the barn keeps off razes_bread")
	t.check(_ids(WishBook.pool_for(1)) == all.slice(0, 10) and _ids(WishBook.pool_for(2)) == all.slice(0, 12) and _ids(WishBook.pool_for(3)) == all.slice(0, 14),
		"Tier 1 draws from M2's ten, Tier 2 from M3's twelve; Wrath from fourteen")


static func _draws(t) -> void:
	var s := Kit.world(TierBook.board("miras_house"), MissionDirector.new())
	var twelve: Array[WishDef] = []
	twelve.assign(WishBook.pool().slice(0, 12))
	var same := true
	for n in 20:
		var a := Descent.new().setup(TierBook.board("miras_house"), Descent.seed_for(n, "miras_house"))
		a.hear(s.crowd, s.town)
		var r := RandomNumberGenerator.new()
		r.seed = Descent.seed_for(n, "miras_house")
		var b := WishBook.draw(twelve, TierBook.wishes(2), TierBook.board("miras_house").mission_tags, s.crowd, s.town, r)
		same = same and _ids(a.wishes) == _ids(b)
		for w in a.wishes:
			w.release()
		for w in b:
			w.release()
	t.check(same, "twenty Tier 2 nights hear exactly what M3's twelve gave them")
	Kit.done(s)
	var o := Kit.world(TierBook.board("vigil_flame"), MissionDirector.new())
	var heard := {}
	for n in 60:
		var d := Descent.new().setup(TierBook.board("vigil_flame"), Descent.seed_for(n, "vigil_flame"))
		d.hear(o.crowd, o.town)
		for w in d.wishes:
			heard[w.def.id] = true
			w.release()
	t.check(heard.has("barn") and heard.has("sergeant"), "Wrath's nights can hear both new wishes (%s)" % [heard.keys()])
	Kit.done(o)


static func _barn(t) -> void:
	var s := _world()
	var town: Town = s.town
	var barns := 0
	var mills := 0
	for st: Structure in town._built:
		if RuinWish.fits(st, "barn"):
			barns += 1
			mills += 1 if st.art_tag in [&"windmill", &"watermill"] else 0
	t.check(barns == TownLayout.BARNS.size() and mills == 0, "a barn is a farm house with no art tag: the four farmhouses, never a mill")
	var w := _wish(s, "barn") as RuinWish
	t.check(w != null and RuinWish.fits(w.target, "barn") and w.places().size() == 1 and w.places()[0] == w.target and w.tags()[0].label == "TITHE BARN"
		and w.tags()[0].edge, "its target a barn, set aside; TITHE BARN pointed at from the edge")
	w.target.destroy(w.target.center(), &"fire")
	t.check(w.check(s.rules) == Objective.Status.DONE, "granted when it falls, by any means")
	var barn_def := _def("barn")
	var moneylender := _wish(s, "moneylender") as RuinWish
	t.check(moneylender != null and moneylender.tags()[0].edge and moneylender.tags()[0].label == "MONEYLENDER",
		"the older Ruin wishes keep their tags as they were")
	t.check(WishBook.clashes(barn_def, PackedStringArray(["razes_bread"])) and not WishBook.clashes(barn_def, PackedStringArray(["unaware_town"])),
		"the barn keeps off the mission tag razes_bread (The Crown's Bread's night) and no other")
	Kit.done(s)


static func _sergeant(t) -> void:
	var s := _world()
	var w := _wish(s, "sergeant") as PunishWish
	var sol := w.target if w != null else null
	t.check(w != null and sol.soldier and sol.corps == Person.Corps.NONE and not sol.inside and w.wisher != null and not w.wisher.soldier
		and w.people().has(sol) and w.people().has(w.wisher), "the sergeant: a soldier of no corps out of doors; a lay wisher; both set aside")
	var tag := w.tags()[0]
	t.check(tag.label == "SERGEANT" and tag.edge, "SERGEANT, pointed at from the edge")
	var director: MissionDirector = s.d
	director.reserved.append(sol)
	t.check(not director._free_soldiers(sol.ground_pos, 3).has(sol), "reserved, no director appoints him")
	(s.crowd as Crowd)._field.kill(sol, &"smite")
	w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.DONE, "granted the moment he dies, any way")
	w.release()
	var tc := _wish(s, "tax_collector") as PunishWish
	t.check(tc != null and not tc.target.soldier and not tc.tags()[0].edge, "the older Punish wishes pick a lay target and keep their tags")
	tc.release()
	Kit.done(s)


static func _sergeant_ends(t) -> void:
	var s := _world()
	var w := _wish(s, "sergeant") as PunishWish
	var sol := w.target
	var crowd: Crowd = s.crowd
	crowd._field.remove(sol)
	crowd.soldiers.erase(sol)
	sol.free()
	t.check(w.check(s.rules) == Objective.Status.FAILED, "he leaves the town alive: failed")
	w.release()
	var v := _wish(s, "sergeant", 5) as PunishWish
	Kit.free_body(s, v.wisher)
	t.check(v.check(s.rules) == Objective.Status.FAILED, "the wisher dies first: failed")
	v.release()
	Kit.done(s)
