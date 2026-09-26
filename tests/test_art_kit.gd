extends RefCounted
## ArtKit and the art plans: hashed variety is deterministic, in range, and never touches a structure's rng stream.


static func run(t) -> void:
	var a := ArtKit.hash01(12345, 3)
	t.check(a == ArtKit.hash01(12345, 3), "hash01 is deterministic")
	var in_range := true
	var seen := {}
	for i in 200:
		var h := ArtKit.hash01(i * 7919, i % 5)
		in_range = in_range and h >= 0.0 and h < 1.0
		seen[ArtKit.pick(i * 31, 1, 4)] = true
	t.check(in_range, "hash01 stays in [0, 1)")
	t.check(seen.size() == 4, "pick reaches every option")

	var s := Structure.new().setup(Rect2(0, 0, 1.3, 0.95), 23.0, Structure.Kind.HOUSE, 99)
	var twin := Structure.new().setup(Rect2(0, 0, 1.3, 0.95), 23.0, Structure.Kind.HOUSE, 99)
	t.check(s.art == twin.art and not s.art.is_empty(), "same seed, same house plan")
	t.check(s.rng.state == twin.rng.state, "planning leaves the rng stream alone")
	var fresh := RandomNumberGenerator.new()
	fresh.seed = 99
	for w in s._windows:
		fresh.randf()
	t.check(s.rng.randi() == fresh.randi(), "the rng stream after setup is exactly the windows' draws")
	var barn := Structure.new().setup(Rect2(0, 0, 1.2, 1.4), 20.0, Structure.Kind.HOUSE, 5, &"farm")
	t.check(barn.art.barn and not s.art.barn, "farm houses plan as barns")
	t.check(s.art.door_face in [ArtKit.LEFT, ArtKit.RIGHT] and s.art.roof_shade in [-1, 0, 1],
		"door face and roof shade in range")
	var faces := {}
	for i in 30:
		var h := Structure.new().setup(Rect2(0, 0, 1.3, 0.95), 23.0, Structure.Kind.HOUSE, i * 104729)
		faces[h.art.door_face] = true
		h.free()
	t.check(faces.size() == 2, "doors turn up on both visible walls")
	s.free()
	twin.free()
	barn.free()

	var env := EnvironmentField.new()
	# A fixed seed: each piece's torch is a coin flip from its seed, and an unseeded town could land outside the band.
	env.rng.seed = 7
	var town := Town.new()
	town.build(env)
	var pieces := 0
	var torches := 0
	var others_plain := true
	for st in env.structures():
		if st.kind == Structure.Kind.CASTLE_WALL and st.role == &"wall":
			pieces += 1
			if st.art.torch:
				torches += 1
		elif st.art.get("torch", false):
			others_plain = false
	t.check(torches >= pieces / 5 and torches <= pieces / 2, "about a third of the town wall pieces carry a torch")
	t.check(others_plain, "only town wall pieces carry torches")
	t.check(town.citadel.keep.art_tag == &"keep" and town.citadel.parts[5].art_tag == &"gate",
		"the Citadel keep flies the flag and its south wall is the gateway")
	town.teardown()
	town.free()
	env.free()

	var species := {}
	var crops := {}
	for i in 40:
		var tr := Structure.new().setup(Rect2(0, 0, 0.7, 0.7), 26.0, Structure.Kind.TREE, i * 104729)
		species[tr.art.species] = true
		tr.free()
		var fd := Structure.new().setup(Rect2(0, 0, 2.6, 1.8), 3.0, Structure.Kind.FARM_FIELD, i * 7907)
		crops[fd.art.crop] = true
		fd.free()
	t.check(species.size() == 2, "trees come as oaks and pines")
	t.check(crops.size() == 2, "fields come as wheat and cabbages")
	var bar := Structure.new().setup(Rect2(0, 0, 4.2, 1.9), 36.0, Structure.Kind.BARRACKS, 3)
	var forge: Rect2 = bar.art.forge
	t.check(bar.footprint.encloses(forge) and forge.end == bar.footprint.end, "the barracks forge stands in its east corner")
	t.check(bar._flame_tips().size() == 1, "the forge's furnace flickers")
	bar.free()
	var br := Structure.new().setup(Rect2(0, 0, 2.0, 2.4), 6.0, Structure.Kind.BRIDGE, 4)
	t.check(br._flame_tips().size() == 4, "the bridge carries four torches")
	br.free()
	var cloths := {}
	for i in 12:
		var st := Structure.new().setup(Rect2(0, 0, 0.9, 0.7), 10.0, Structure.Kind.MARKET_STALL, i)
		cloths[st.art.cloth] = true
		st.free()
	t.check(cloths.size() == 3, "stalls come in all three cloths")
