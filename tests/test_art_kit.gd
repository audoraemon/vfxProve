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
