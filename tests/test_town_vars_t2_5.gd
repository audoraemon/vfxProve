extends RefCounted
## Plan "The Capital at every tier", Tasks 1-: the shared lookups the tier 2-5 missions read instead of an Aldermere const are bit-equal
## to it in Aldermere (_lookups_exact). Each mission task adds its own `_seeded` row to its own test, not here.


static func run(t) -> void:
	City.use(&"aldermere")
	_lookups_exact(t)
	City.use(&"aldermere")


static func _lookups_exact(t) -> void:
	t.check(City.current() is AldermereCity, "Aldermere is the active town")
	t.check(Places.point(&"citadel_gate") == HarvestDirector.CITADEL_GATE, "the Citadel's gate is the Harvest's const (%s)" % [Places.point(&"citadel_gate")])
	# NOT bit-equal: the rect's float32 centre is (0.8, -8.700001), the spire const is (0.8, -8.7), one ulp apart. A mission that must stay
	# bit-exact in Aldermere (the Lantern Eye, whose searchlight sits here) keeps the const as its town var's default, not Places.at().
	t.check(Places.at(&"temple").is_equal_approx(LanternEyeDirector.SPIRE) and Places.at(&"temple").distance_to(LanternEyeDirector.SPIRE) < 0.0001,
		"the Temple's centre is the Lantern Eye's spire to within an ulp (%s vs %s)" % [Places.at(&"temple"), LanternEyeDirector.SPIRE])
	t.check(City.current().town().get_center() == City.current().map().get_center(), "the town's centre is the map's")
