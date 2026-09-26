extends RefCounted
## ArtTuning: the per-component size and colour knobs the tuning tool sets.


static func run(t) -> void:
	ArtTuning.set_data({})
	t.check(ArtTuning.scale("barrel") == 1.0 and ArtTuning.tint("barrel") == Color.WHITE, "no entry changes nothing")
	ArtTuning.set_data({"barrel": {"scale": 1.3, "tint": [0.9, 1.0, 1.1]}, "house_tavern": {"tint": [1.1, 1.0, 0.9]}})
	t.check(is_equal_approx(ArtTuning.scale("barrel"), 1.3), "a decor's scale is read")
	t.check(ArtTuning.tint("barrel").is_equal_approx(Color(0.9, 1.0, 1.1)), "and its tint")
	t.check(ArtTuning.scale("house_tavern") == 1.0, "a missing field keeps its default")

	var d := Decor.new().setup(Decor.Kind.BARREL, Vector2.ZERO, Vector2.ZERO, 1)
	t.check(d.tuning_key() == "barrel", "decor keys are their kind in lower case")
	d.free()
	var tav := Structure.new().setup(Rect2(0, 0, 2.1, 1.4), 30.0, Structure.Kind.HOUSE, 1, &"house", &"tavern")
	var barn := Structure.new().setup(Rect2(0, 0, 1.2, 1.4), 20.0, Structure.Kind.HOUSE, 2, &"farm")
	var keep := Structure.new().setup(Rect2(0, 0, 2, 2), 80.0, Structure.Kind.KEEP, 3, &"citadel", &"keep")
	t.check(tav.tuning_key() == "house_tavern" and barn.tuning_key() == "house_barn" and keep.tuning_key() == "keep_keep",
		"structure keys carry their art tag, and a farm's house is a barn")
	tav.free()
	barn.free()
	keep.free()
	# The tuning tool rewrites the file between renders; everything else reads the committed one.
	ArtTuning.reload()
