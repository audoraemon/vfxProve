extends RefCounted
## v0.11 M5 Reckoning's two wishes (mission spec §6): the pool grows to sixteen, the two new ones heard from Reckoning up (min_tier 4), so
## Tier 1-3 nights shuffle exactly what they did. Save the heretic from the pyre: Free the pressed man's march to the Temple's door (found
## by its role), its son tagged HERETIC and its men TEMPLE GUARD; it keeps off burns_temple. Lead my family out: Lead my brother out for
## three of the household, each escaping by a gate -- or leaving the town alive any way, never read as dead (the final review). Free the
## pressed man gains the clash razes_barracks; it and Lead my brother out are as before.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_pool(t)
	_draws(t)
	_heretic(t)
	_pressed_kept(t)
	_family(t)
	_family_ends(t)
	_family_slips_out(t)
	_brother_kept(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.sermon(), MissionDirector.new())


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
	t.check(all.size() == 18 and all.slice(14, 16) == ["heretic", "family_out"], "the pool: M4's fourteen, then Reckoning's two, M6 grown to eighteen (%s)" % [all])
	var h := _def("heretic")
	var f := _def("family_out")
	t.check(h.text == "Save the heretic from the pyre" and h.kind == "rescue" and h.reward == 15 and h.min_tier == 4 and h.runner == PressedWish
		and Array(h.clashes) == ["burns_temple", "unaware_town"] and String(h.params.goal) == "temple" and String(h.params.son_label) == "HERETIC"
		and String(h.params.guard_label) == "TEMPLE GUARD" and f.text == "Lead my family out" and f.kind == "mercy" and f.reward == 15
		and f.min_tier == 4 and f.runner == MercyWish and int(f.params.count) == 3 and Array(f.clashes) == ["shuts_gates"],
		"their words, kinds, rewards and parameters; heard from Reckoning up; the pyre keeps off burns_temple")
	t.check(Array(_def("pressed").clashes) == ["unaware_town", "razes_barracks"], "Free the pressed man keeps off The Armoury's night")
	t.check(_ids(WishBook.pool_for(1)) == all.slice(0, 10) and _ids(WishBook.pool_for(2)) == all.slice(0, 12)
		and _ids(WishBook.pool_for(3)) == all.slice(0, 14) and _ids(WishBook.pool_for(4)) == all.slice(0, 16),
		"Tier 1 draws from M2's ten, Tier 2 from twelve, Tier 3 from fourteen, each in its order; Reckoning from all sixteen")


static func _draws(t) -> void:
	var s := Kit.world(TierBook.board("vigil_flame"), MissionDirector.new())
	var same := true
	var tiers := {"warning": 10, "miras_house": 12, "vigil_flame": 14}
	for id: String in tiers:
		var older: Array[WishDef] = []
		older.assign(WishBook.pool().slice(0, int(tiers[id])))
		var def := TierBook.board(id)
		for n in 20:
			var a := Descent.new().setup(def, Descent.seed_for(n, id))
			a.hear(s.crowd, s.town)
			var r := RandomNumberGenerator.new()
			r.seed = Descent.seed_for(n, id)
			var b := WishBook.draw(older, TierBook.wishes(def.tier), def.mission_tags, s.crowd, s.town, r)
			same = same and _ids(a.wishes) == _ids(b)
			for w in a.wishes:
				w.release()
			for w in b:
				w.release()
	t.check(same, "twenty Tier 1, 2 and 3 nights each hear exactly what the pool before Reckoning's gave them (the filter runs before the shuffle)")
	# Bites: drawn from all sixteen, the same seeds do shuffle differently, so the check above is not vacuous.
	var all := WishBook.pool()
	var differs := false
	for n in 20:
		var def := TierBook.board("vigil_flame")
		var r1 := RandomNumberGenerator.new()
		r1.seed = Descent.seed_for(n, "vigil_flame")
		var r2 := RandomNumberGenerator.new()
		r2.seed = r1.seed
		var older: Array[WishDef] = []
		older.assign(all.slice(0, 14))
		var x := WishBook.draw(older, 3, def.mission_tags, s.crowd, s.town, r1)
		var y := WishBook.draw(all, 3, def.mission_tags, s.crowd, s.town, r2)
		differs = differs or _ids(x) != _ids(y)
		for w in x:
			w.release()
		for w in y:
			w.release()
	t.check(differs, "unfiltered, the sixteen would have changed some Tier 3 night's draw")
	Kit.done(s)
	var o := Kit.world(TierBook.board("procession"), MissionDirector.new())
	var heard := {}
	for n in 60:
		var d := Descent.new().setup(TierBook.board("procession"), Descent.seed_for(n, "procession"))
		d.hear(o.crowd, o.town)
		for w in d.wishes:
			heard[w.def.id] = true
			w.release()
	t.check(heard.has("heretic") and heard.has("family_out"), "Reckoning's nights can hear both new wishes (%s)" % [heard.keys()])
	Kit.done(o)
	var barracks := PackedStringArray(["razes_barracks"])
	var temple := PackedStringArray(["burns_temple"])
	t.check(WishBook.clashes(_def("pressed"), barracks) and WishBook.clashes(_def("heretic"), temple)
		and not WishBook.clashes(_def("heretic"), barracks) and not WishBook.clashes(_def("family_out"), temple + barracks),
		"The Armoury's night keeps off Free the pressed man; The Bishop's keeps off the pyre; Lead my family out clashes with neither")


static func _heretic(t) -> void:
	var s := _world()
	var w := _wish(s, "heretic") as PressedWish
	var door := PressedWish.temple_door(s.crowd, s.town)
	t.check(w != null and w._gate.is_equal_approx(door) and door.distance_to(Vector2(0.8, -5.0)) < 1.0
		and w.child.ground_pos.distance_to(door) >= PressedWish.MIN_FROM and w.soldier.soldier and w.mate.soldier and w.people().size() == 4,
		"the heretic: a son of the household at least MIN_FROM from the Temple's door (found by its role); two free soldiers")
	var tags := w.tags()
	t.check(tags[0].label == "HERETIC" and tags[0].edge and tags[1].label == "TEMPLE GUARD" and not tags[1].edge,
		"HERETIC pointed at from the edge; TEMPLE GUARD on each man")
	w.engage()
	t.check(w.tags()[1].edge, "engaged: the Temple's guard pointed at")
	w.release()
	for st: Structure in (s.town as Town)._built:
		if is_instance_valid(st) and st.role == &"temple":
			st.destroy(st.center(), &"smite")
	t.check(PressedWish.temple_door(s.crowd, s.town) == Vector2.INF, "a fallen Temple is passed over: no door (the final review)")
	Kit.done(s)


static func _pressed_kept(t) -> void:
	var s := _world()
	var w := _wish(s, "pressed") as PressedWish
	t.check(w != null and w._gate.is_equal_approx(PressedWish.barracks_door(s.crowd)) and w.tags()[0].label == "PRESSED MAN"
		and w.tags()[1].label == "PRESS-GANG", "Free the pressed man marches to the barracks' door as before, its tags as they were")
	w.release()
	Kit.done(s)


static func _family(t) -> void:
	var s := _world()
	var w := _wish(s, "family_out") as MercyWish
	var near := w != null and w.count() == 3 and w.family.size() == 3 and w.people().size() == 4 and w.target == null
	for v: Variant in w.family:
		near = near and (v as Person).profile.home.distance_to(w.wisher.profile.home) <= FamilyWish.REACH
	t.check(near, "three of the wisher's household, living near his home, set aside with him")
	var labels := []
	for m in w.tags():
		if m.label == "FAMILY" and m.edge:
			labels.append(m.label)
	t.check(labels.size() == 3, "FAMILY on each, pointed at from the edge")
	var exit: Vector2 = MercyWish.exits()[0]
	for k in 2:
		var p := w.family[k] as Person
		p.whisper(exit, MindWhisperFx.LINGER)
		Kit.arrive(p, exit)
		w.step(s.rules, DT)
		p.free()
	t.check(w.check(s.rules) == Objective.Status.PENDING and w.hud_text(s.rules).ends_with("2 / 3") and w.tags().size() == 2,
		"two escaped and their bodies freed: still open, their tags gone (%s)" % w.hud_text(s.rules))
	var last := w.family[2] as Person
	last.whisper(exit, MindWhisperFx.LINGER)
	Kit.arrive(last, exit)
	w.step(s.rules, DT)
	last.free()
	t.check(w.check(s.rules) == Objective.Status.DONE, "the third escapes: granted")
	Kit.done(s)


static func _family_ends(t) -> void:
	var s := _world()
	var w := _wish(s, "family_out", 5) as MercyWish
	Kit.free_body(s, w.family[1])
	t.check(w.check(s.rules) == Objective.Status.FAILED, "one dies before escaping: failed")
	var v := _wish(s, "family_out", 7) as MercyWish
	Kit.free_body(s, v.wisher)
	t.check(v.check(s.rules) == Objective.Status.FAILED, "the wisher dies first: failed")
	Kit.done(s)


## The final review: a member who leaves the town alive on his own -- not whispered, walking out an exit (Crowd.escape(), his body freed
## at once) -- is out, never read as dead; a death still fails. The brother the same.
static func _family_slips_out(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	var w := _wish(s, "family_out", 5) as MercyWish
	var p := w.family[0] as Person
	crowd._field.remove(p)
	crowd.escape(p)
	p.free()
	t.check(w.check(s.rules) == Objective.Status.PENDING and w.hud_text(s.rules).ends_with("1 / 3"),
		"one walks out of town on his own: counted as escaped, the wish still open (%s)" % w.hud_text(s.rules))
	Kit.free_body(s, w.family[1])
	t.check(w.check(s.rules) == Objective.Status.FAILED, "another dies before escaping: failed, as before")
	var b := _wish(s, "brother", 7) as MercyWish
	var brother := b.target
	crowd._field.remove(brother)
	crowd.escape(brother)
	brother.free()
	t.check(b.check(s.rules) == Objective.Status.DONE, "the brother walks out of town alive on his own: granted, not failed")
	w.release()
	b.release()
	t.check(not crowd.escaped.is_connected(w._on_escaped) and not crowd.escaped.is_connected(b._on_escaped),
		"release() lets go of the crowd's escapes")
	Kit.done(s)


static func _brother_kept(t) -> void:
	var s := _world()
	var w := _wish(s, "brother") as MercyWish
	t.check(w != null and w.count() == 1 and w.family.is_empty() and w.target != null and w.tags()[0].label == "BROTHER"
		and not w.tags()[0].edge and w.people().size() == 2, "Lead my brother out: one brother, his tag as it was")
	var exit: Vector2 = MercyWish.exits()[1]
	w.target.whisper(exit, MindWhisperFx.LINGER)
	Kit.arrive(w.target, exit)
	w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.DONE, "whispered to a gate he escapes: granted, as before")
	Kit.done(s)
