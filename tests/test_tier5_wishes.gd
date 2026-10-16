extends RefCounted
## v0.11 M6 Ascendance's two new wishes (mission spec §5): "Strike down the zealot, unseen" (PunishWish with clergy and unseen) and "Turn the
## doubting priest" (NeighboursWish with count 1 and clergy), both heard from Tier 5 only, so Tier 1-4 nights shuffle what they always did;
## the old wishes' defaults exact; the shuts_gates clash keeps both escape wishes off Exodus; the pyre keeps off burns_temple; a reserved
## cleric is never Odran.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_pool(t)
	_old_draws(t)
	_kept(t)
	_zealot(t)
	_priest(t)
	_clashes(t)
	_zealot_not_odran(t)


static func _ids(defs: Array) -> Array:
	var out := []
	for d in defs:
		out.append(d.id if d is WishDef else (d as Wish).def.id)
	return out


static func _def(id: String) -> WishDef:
	for d in WishBook.pool():
		if d.id == id:
			return d
	return null


## A wish chosen in `s`'s town with the given seed (v0.11 M6 tests); null when its town cannot give it.
static func _wish(s: Dictionary, id: String, seed_n := 3) -> Wish:
	var r := RandomNumberGenerator.new()
	r.seed = seed_n
	var w := _def(id).instance()
	return w if w.choose(s.crowd, s.town, r, []) else null


static func _pool(t) -> void:
	var all := _ids(WishBook.pool())
	t.check(all.size() == 18 and all.slice(16) == ["zealot", "priest"], "the pool: M5's sixteen, then Ascendance's two (%s)" % [all])
	var z := _def("zealot")
	var p := _def("priest")
	t.check(z.text == "Strike down the zealot, unseen" and z.kind == "punish" and z.reward == 15 and z.min_tier == 5 and z.runner == PunishWish
		and bool(z.params.clergy) and bool(z.params.unseen) and bool(z.params.edge) and String(z.params.label) == "ZEALOT" and z.clashes.is_empty()
		and p.text == "Turn the doubting priest" and p.kind == "faith" and p.reward == 15 and p.min_tier == 5 and p.runner == NeighboursWish
		and int(p.params.count) == 1 and bool(p.params.clergy) and String(p.params.label) == "DOUBTING PRIEST" and is_equal_approx(float(p.params.route), 30.0),
		"their words, kinds, rewards and parameters; heard from Ascendance up")
	t.check(_ids(WishBook.pool_for(1)) == all.slice(0, 10) and _ids(WishBook.pool_for(2)) == all.slice(0, 12)
		and _ids(WishBook.pool_for(3)) == all.slice(0, 14) and _ids(WishBook.pool_for(4)) == all.slice(0, 16) and _ids(WishBook.pool_for(5)) == all,
		"Tiers 1-4 draw from exactly the pools they did (pool_for() filters before the shuffle); Ascendance from all eighteen")


## The ruling: Tier 1-4 seeded draws do not move. A night of Tiers 1-4 draws from pool_for(tier), which leaves the two out before the shuffle, so
## each seed draws exactly what the sixteen alone drew; and the control: shuffled in with the two, the same seeds would have drawn otherwise.
static func _old_draws(t) -> void:
	var s := Kit.world(MissionBook.warning(), MissionDirector.new())
	var all := WishBook.pool()
	var same := true
	var moved := false
	for tier in range(1, 5):
		for n in 12:
			var r1 := RandomNumberGenerator.new()
			r1.seed = Descent.seed_for(n, "tier5_%d" % tier)
			var r2 := RandomNumberGenerator.new()
			r2.seed = r1.seed
			var r3 := RandomNumberGenerator.new()
			r3.seed = r1.seed
			var older: Array[WishDef] = []
			for d in all.slice(0, 16):
				if d.min_tier <= tier:
					older.append(d)
			var a := WishBook.draw(WishBook.pool_for(tier), 3, PackedStringArray(), s.crowd, s.town, r1)
			var b := WishBook.draw(older, 3, PackedStringArray(), s.crowd, s.town, r2)
			var c := WishBook.draw(all, 3, PackedStringArray(), s.crowd, s.town, r3)
			same = same and _ids(a) == _ids(b)
			moved = moved or _ids(a) != _ids(c)
			for w: Wish in a + b + c:
				w.release()
	t.check(same and moved, "Tiers 1-4: seeded draws from pool_for(tier) are the sixteen's draws, exactly (same=%s); unfiltered, the eighteen would move some (moved=%s)" % [same, moved])
	Kit.done(s)


static func _kept(t) -> void:
	var s := Kit.world(MissionBook.warning(), MissionDirector.new())
	var tax := _wish(s, "tax_collector") as PunishWish
	t.check(tax != null and tax.target.profile.role != CitizenProfile.Role.CLERGY and not tax.target.soldier, "the tax collector is still a lay citizen")
	var n := _wish(s, "neighbours") as NeighboursWish
	t.check(n != null and n.neighbours.size() == NeighboursWish.COUNT and n._count() == 3 and n._label() == NeighboursWish.LABEL
		and n.hud_text(s.rules).ends_with("0 / 3"), "Let my neighbours believe: still three neighbours, NEIGHBOUR, 0 / 3")
	tax.release()
	Kit.done(s)


static func _zealot(t) -> void:
	var s := Kit.world(MissionBook.warning(), MissionDirector.new())
	var w := _wish(s, "zealot") as PunishWish
	var z := w.target
	t.check(w != null and z.profile.role == CitizenProfile.Role.CLERGY and not z.inside and w.wisher.profile.role != CitizenProfile.Role.CLERGY
		and w.tags()[0].label == "ZEALOT" and w.tags()[0].edge, "a cleric out of doors, marked ZEALOT and pointed at; a lay wisher")
	var crowd: Crowd = s.crowd
	for p in crowd.citizens:
		if MissionDirector._alive(p) and p != z and p.ground_pos.distance_to(z.ground_pos) <= Crowd.DOOM_WITNESS + 0.2:
			Kit.arrive(p, p.ground_pos + Vector2(8.0, 8.0))
	crowd._field.kill(z, &"fire")
	w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.DONE, "killed with no living witness: granted")
	w.release()
	var seen := _wish(s, "zealot", 5) as PunishWish
	var witness := seen.wisher
	Kit.arrive(witness, seen.target.ground_pos + Vector2(1.0, 0.0))
	crowd._field.kill(seen.target, &"fire")
	seen.step(s.rules, DT)
	t.check(seen.check(s.rules) == Objective.Status.FAILED, "killed before a witness: failed")
	seen.release()
	Kit.done(s)


static func _priest(t) -> void:
	var s := Kit.world(MissionBook.warning(), MissionDirector.new())
	var w := _wish(s, "priest") as NeighboursWish
	var priest := w.neighbours[0] as Person
	var path := (s.crowd as Crowd)._grid.path(priest.ground_pos, w.wisher.ground_pos)
	var walk := 0.0
	for k in range(path.size() - 1):
		walk += path[k].distance_to(path[k + 1])
	t.check(w != null and w.neighbours.size() == 1 and priest.profile.role == CitizenProfile.Role.CLERGY and walk <= 30.0
		and w.tags()[0].label == "DOUBTING PRIEST" and w.tags()[0].edge and w.hud_text(s.rules).ends_with("0 / 1"),
		"one cleric within 30 units of street of the wisher, DOUBTING PRIEST, pointed at (%.1f units)" % walk)
	priest.whisper(w.wisher.ground_pos, MindWhisperFx.LINGER)
	Kit.arrive(priest, w.wisher.ground_pos + Vector2(1.0, 0.0))
	w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.DONE and priest.profile.faith == CitizenProfile.Faith.BELIEVER,
		"whispered to within 2 of the wisher he believes: granted")
	var dies := _wish(s, "priest", 9) as NeighboursWish
	Kit.free_body(s, dies.neighbours[0])
	t.check(dies.check(s.rules) == Objective.Status.FAILED, "the priest dead before believing: failed")
	Kit.done(s)


static func _clashes(t) -> void:
	var s := Kit.world(MissionBook.warning(), MissionDirector.new())
	var heard := {}
	var near_temple := {}
	for n in 60:
		var r := RandomNumberGenerator.new()
		r.seed = 1000 + n
		for w in WishBook.draw(WishBook.pool_for(5), 3, PackedStringArray(["shuts_gates"]), s.crowd, s.town, r):
			heard[w.def.id] = true
			w.release()
		var r2 := RandomNumberGenerator.new()
		r2.seed = 2000 + n
		for w in WishBook.draw(WishBook.pool_for(5), 3, PackedStringArray(["burns_temple"]), s.crowd, s.town, r2):
			near_temple[w.def.id] = true
			w.release()
	t.check(not heard.has("brother") and not heard.has("family_out") and WishBook.clashes(_def("brother"), PackedStringArray(["shuts_gates"]))
		and WishBook.clashes(_def("family_out"), PackedStringArray(["shuts_gates"])) and not near_temple.has("heretic")
		and (heard.has("zealot") or heard.has("priest")), "sixty draws: shuts_gates keeps both escape wishes away, burns_temple the pyre (%s)" % [heard.keys()])
	t.check(TierBook.board("exodus").mission_tags.has("shuts_gates"),
		"Exodus on the board declares shuts_gates, the tag both escape wishes clash with (the board takes its tags from TierBook.MISSION_TAGS)")
	Kit.done(s)


static func _zealot_not_odran(t) -> void:
	var a := Kit.world(MissionBook.heart_of_faith())
	var ix := (a.crowd as Crowd).citizens.find((a.d as HeartOfFaithDirector).odran)
	Kit.done(a)
	var b := Kit.world(MissionBook.heart_of_faith(), null, func(d: MissionDirector, rules: Rules) -> void:
		d.reserved.append(rules.crowd().citizens[ix]))
	var odran: Variant = (b.d as HeartOfFaithDirector).odran
	t.check(ix >= 0 and MissionDirector._alive(odran) and odran != (b.crowd as Crowd).citizens[ix] and (odran as Person).profile.role == CitizenProfile.Role.CLERGY,
		"a cleric a wish has taken (the zealot, drawn before Odran is chosen) is passed over: Odran is the next")
	Kit.done(b)
