extends RefCounted
## Lighting round 9 (DAY and NIGHT only; CURRENT untouched): the small things that stand (barrels, crates, benches,
## carts, goods piles, lamps, animals...) cast shadows baked from their sprites, so they no longer float, and the look's
## own street lamps and house lanterns cast their posts'.


const R2 := preload("res://tests/test_town_round2.gd")


static func run(t) -> void:
	_decor_casts(t)


static func _shadows(town: Town) -> TownShadows:
	for n in town.look_nodes():
		if n is TownShadows:
			return n
	return null


static func _decor_casts(t) -> void:
	var parts: Array = R2._build(Town.Look.DAY)
	var town: Town = parts[0]
	var sh := _shadows(town)
	t.check(sh != null, "DAY has a shadow layer")
	if sh == null:
		R2._free(parts)
		return
	var want := 0
	var kinds := {}
	for dec in town._env.decor():
		if dec.down or dec.sprite_only:
			continue
		var pieces: Array = dec.parts if dec.kind == Decor.Kind.PILE else [{"kind": dec.kind, "at": dec.at, "size": dec.size, "seed": dec.seed_value}]
		for p: Dictionary in pieces:
			if p.kind in TownShadows.DECOR_CASTS and DecorSprites.name_for(p.kind, p.seed, p.size, p.at) != "":
				want += 1
				kinds[p.kind] = true
	var props := 0
	for p: Dictionary in town.look_decor.props:
		if TownLookDecor.SPRITES.has(p.prop) and float(p.lift) <= 0.0:
			props += 1
	print("ROUND9 decor pieces=%d kinds=%s look props=%d decor_count=%d" % [want, kinds.keys(), props, sh.decor_count])
	t.check(want > 20 and kinds.has(Decor.Kind.BARREL) and kinds.has(Decor.Kind.CRATES),
		"the town has barrels, crates and other standing decor (%d pieces)" % want)
	t.check(props > 0, "DAY has street lamps or lanterns on the ground (%d)" % props)
	t.check(sh.decor_count >= want + props, "every standing decor piece and look lamp casts (%d of %d)" % [sh.decor_count, want + props])
	# A fallen barrel drops its shadow on the next rebuild.
	var before := sh.decor_count
	for dec in town._env.decor():
		if dec.kind == Decor.Kind.BARREL and not dec.down and not dec.sprite_only:
			dec.down = true
			break
	sh.rebuild()
	t.check(sh.decor_count < before, "a fallen barrel casts no shadow (%d -> %d)" % [before, sh.decor_count])
	R2._free(parts)
