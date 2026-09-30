extends RefCounted
## v0.04 P2 shelter: frightened citizens duck into sturdy buildings nearby; inside they are hidden and out of reach;
## they come out when the danger clears, are thrown out running by heavy damage, and die if it collapses.


static func _shelter_one(crowd: Crowd, s: Structure, from: Vector2) -> Person:
	for p in crowd.citizens:
		if not p.is_alive() or p.inside or p.mind == Person.Mind.SHELTER:
			continue
		p.mind = Person.Mind.CALM
		p.ground_pos = crowd._spot_near(s.center() + Vector2(0.0, s.footprint.size.y * 0.5 + 1.2), 0.3)
		p.panic(from, 1.0, &"tornado")
		if p.mind == Person.Mind.SHELTER and p.shelter == s:
			p.ground_pos = p.shelter_door
			p._goal = Vector2.INF
			crowd.shelters.step(1.0)
			return p
		p.mind = Person.Mind.CALM
	return null


static func run(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()
	var sm := crowd.shelters
	var cathedral: Structure = null
	for s in sm.shelters:
		if s.role == &"temple":
			cathedral = s
	t.check(cathedral != null and sm.shelters.size() >= 5 and ShelterManager.capacity(cathedral) == ShelterManager.CAPACITY.y,
		"the cathedral, taverns, barracks, workshop and townhouses are shelters (%d); the cathedral holds 20" % sm.shelters.size())

	# Taking cover: frightened beside a sturdy building, in they go, out of every effect's reach.
	var from := cathedral.center() + Vector2(0.0, cathedral.footprint.size.y * 0.5 + 4.0)
	var p := _shelter_one(crowd, cathedral, from)
	t.check(p != null and p.inside and not p.visible and p.intent() == Person.Intent.SHELTER and not field._enemies.has(p),
		"a frightened citizen takes cover: inside, hidden, out of reach")
	# The danger clears: out after a while, back to its day.
	for k in 30:
		sm.step(0.25)
	t.check(not p.inside and p.visible and p.mind == Person.Mind.RECOVER and field._enemies.has(p),
		"once no danger is near for a while, it comes out")

	# Heavy damage throws them out running.
	var q := _shelter_one(crowd, cathedral, from)
	crowd.threats.register(cathedral.center(), 2.0, 0.5, 60.0, 5.0, 8.0, &"test")
	cathedral.damage(cathedral.max_hp * 0.6, cathedral.center(), &"stone")
	sm.step(1.0)
	t.check(q != null and not q.inside and (q.mind == Person.Mind.PANIC or q.mind == Person.Mind.SHELTER),
		"a building hit hard throws its sheltering people out")

	# A collapse kills everyone inside.
	var tavern: Structure = null
	for s in sm.shelters:
		if s.art_tag == &"tavern" and not s.destroyed:
			tavern = s
			break
	var r := _shelter_one(crowd, tavern, tavern.center() + Vector2(0.0, 5.0))
	var killed := crowd.killed_citizens
	tavern.destroy(tavern.center(), &"stone")
	sm.step(1.0)
	t.check(r != null and not r.is_alive() and crowd.killed_citizens == killed + 1, "a collapse kills those inside")
	crowd.clear()
	world.free()
