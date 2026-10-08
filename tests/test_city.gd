extends RefCounted
## The shared city format: Aldermere through CityDef is exactly TownLayout.

static func run(t) -> void:
	var c := AldermereCity.new()
	t.check(c.id() == &"aldermere", "Aldermere's city id")
	t.check(c.map() == TownLayout.MAP, "map")
	t.check(c.structures() == TownLayout.structures(), "same structures, same order")
	t.check(c.houses() == TownLayout.houses(), "same houses")
	t.check(c.anchors() == TownLayout.anchors(), "same anchors")
	t.check(c.blockers() == TownLayout.blockers(), "same blockers")
	t.check(c.landmark(&"market_square") == TownLayout.MARKET_SQUARE, "market landmark")
	t.check(c.landmark(&"nowhere") == Rect2(), "unknown landmark is empty")
	City.active = null
	t.check(City.current() is AldermereCity, "Aldermere is the default city")
