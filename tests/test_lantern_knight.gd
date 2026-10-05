extends RefCounted
## v0.10 M3 the Lantern Knight: a soldier come mid-mission (Crowd.add_soldier()), one of the town's soldiers from then
## on, given the KNIGHT corps. He has three times a soldier's health and a gold tabard, and wears the escort's sprite
## until his own is drawn. No other corps' work takes him: not the rally, the marshals or the escorts.


static func _crowd() -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.unaware()
	crowd.spawn()
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd}


static func _done(s: Dictionary) -> void:
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


static func run(t) -> void:
	var s := _crowd()
	var crowd: Crowd = s.crowd
	var before := crowd.soldiers.size()
	var at := crowd._grid.nearest_walkable(Vector2(1.0, 2.0))
	var k := crowd.add_soldier(at)
	t.check(crowd.soldiers.size() == before + 1 and crowd.soldiers.back() == k and k.soldier
		and k.mind == Person.Mind.POST and k.anchor == at and k.post == at and k.corps == Person.Corps.NONE
		and is_equal_approx(k.health, Person.HEALTH_SOLDIER), "a soldier come mid-mission joins the town's soldiers at its post")
	k.corps = Person.Corps.KNIGHT
	k.health = Person.HEALTH_KNIGHT
	t.check(Person.Corps.KNIGHT == Person.Corps.RESCUE + 1 and is_equal_approx(Person.HEALTH_KNIGHT, Person.HEALTH_SOLDIER * 3.0),
		"the Knight corps comes last, and a Knight has three times a soldier's health")
	var design := PeopleArt.design_for(true, 0, Person.Corps.KNIGHT, 0.5)
	t.check(PeopleArt.wanted(true, 0, Person.Corps.KNIGHT, 0.5) == "knight" and PeopleArt.has(design)
		and (PeopleArt.has("knight") or design == PeopleArt.STAND_INS["knight"]),
		"a Knight wants his own design and wears the escort's until it is drawn (%s)" % design)
	k.hurt(Person.HEALTH_SOLDIER, null)
	t.check(k.is_alive(), "he stands through blows that would fell a soldier")
	k.confuse(15.0)
	t.check(k.mind == Person.Mind.POST and not k.whisper(at + Vector2(3.0, 0.0), 8.0) and not k.lure(at, 6.0),
		"the quiet powers do not hold him")
	crowd.rally()
	t.check(k.mind == Person.Mind.POST and k.anchor == at, "the town's rally leaves a Knight at his post")
	_done(s)
