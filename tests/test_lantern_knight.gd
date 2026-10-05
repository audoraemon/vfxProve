extends RefCounted
## v0.10 M3 the Lantern Knight: a soldier come mid-mission (Crowd.add_soldier()), one of the town's soldiers from then
## on, given the KNIGHT corps. He has three times a soldier's health and a gold tabard, and wears the escort's sprite
## until his own is drawn. No other corps' work takes him: not the patrols' investigations (even once pruning slides him
## into the patrols' index range), the rally, the marshals or the escorts.


static func _crowd(prepared := false) -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED) if prepared else ResponseProfile.unaware()
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

	# Soldiers freed before him slide him down the roster (_prune_soldiers() compacts it) into the patrols' index range,
	# [80, 100): the patrols' investigations must still leave him alone, and take him as any soldier without his corps.
	for i in 20:
		crowd.soldiers[i].free()
	crowd._prune_soldiers()
	t.check(crowd.soldiers.back() == k and crowd.soldiers.find(k) == Crowd.POST_YARD + Crowd.POST_WALLS + Crowd.POST_CITADEL,
		"pruning slides the Knight into the patrols' index range (%d)" % crowd.soldiers.find(k))
	var look := Vector2(-10.0, 3.0)
	k.corps = Person.Corps.NONE
	crowd._investigate(look)
	t.check(crowd._investigating.size() == 1 and crowd._investigating[0][0] == k,
		"control: a soldier without a corps in the patrols' range is sent to look")
	crowd._investigating.clear()
	k.send_to_post(at)
	k.corps = Person.Corps.KNIGHT
	crowd._investigate(look)
	t.check(crowd._investigating.is_empty() and k.mind == Person.Mind.POST and k.anchor == at,
		"a Knight in the patrols' range is not sent to look")

	var plain := crowd.add_soldier(at + Vector2(1.0, 0.0))
	crowd.rally()
	t.check(plain.mind == Person.Mind.RALLY, "control: the town's rally takes a soldier without a corps")
	t.check(k.mind == Person.Mind.POST and k.anchor == at, "the town's rally leaves a Knight at his post")
	_done(s)

	# The marshals: more are raised from the walls' soldiers without a corps, and a Knight among them stays a Knight.
	s = _crowd()
	crowd = s.crowd
	k = crowd.add_soldier(at)
	k.corps = Person.Corps.KNIGHT
	var first_wall: Person = crowd.soldiers[Crowd.POST_YARD]
	crowd.soldiers[Crowd.POST_YARD] = k  # (first in post order, where it would be taken)
	crowd.soldiers[crowd.soldiers.size() - 1] = first_wall
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)
	var added := crowd._raise_marshals()
	t.check(added > 0 and k.corps == Person.Corps.KNIGHT, "raising the marshals takes soldiers without a corps, not a Knight (%d)" % added)
	_done(s)

	# The escorts: a Knight at the bell is not taken as an escort, whoever stands nearest.
	s = _crowd(true)
	crowd = s.crowd
	crowd.bell.call_keeper()
	var near_bell := crowd._grid.nearest_walkable(crowd.bell.keeper.ground_pos)
	k = crowd.add_soldier(near_bell)
	k.corps = Person.Corps.KNIGHT
	crowd.escorts.step(1.0)
	var guards: Array = crowd.escorts.guards.get("bell", [])
	t.check(guards.size() == crowd.profile.escorts_per_duty and not guards.has(k) and not crowd.escorts.guarding(k)
		and k.mind == Person.Mind.POST and k.anchor == near_bell, "the escorts leave a Knight at his post (%d guard the bell)" % guards.size())
	_done(s)
