extends RefCounted
## Mission buildings are spared (Death second review, R45 as amended): MissionKeeps.spared() is the one rule a power's side
## effects (Grave Tide's claws and slams) ask before they wreck a building. A building the night wants down is never spared;
## otherwise the Citadel, the Temple, a hallowed building, one with a damage filter, one set aside, and one its director needs
## standing are.


## A bare building with `role` (a Node2D: freed by _drop()).
static func _building(role: StringName) -> Structure:
	var s := Structure.new()
	s.role = role
	return s


static func _drop(made: Array) -> void:
	for n: Variant in made:
		if is_instance_valid(n):
			(n as Node).free()


static func run(t) -> void:
	_generic(t)
	_hallowed(t)
	_kept_aside(t)
	_wanted_down(t)
	_no_director(t)
	_directors(t)


static func _generic(t) -> void:
	var crowd := Crowd.new()
	var d := MissionDirector.new()
	var citadel := _building(&"citadel")
	var temple := _building(&"temple")
	var house := _building(&"house")
	t.check(MissionKeeps.spared(citadel, crowd, d) and MissionKeeps.spared(temple, crowd, d)
		and not MissionKeeps.spared(house, crowd, d), "the Citadel and the temple are spared, a house is not")
	_drop([citadel, temple, house, crowd])


static func _hallowed(t) -> void:
	var crowd := Crowd.new()
	var d := MissionDirector.new()
	var house := _building(&"house")
	var other := _building(&"house")
	crowd.mark_structure(house, AnathemaFx.HALLOWED, 2.0)
	crowd.mark_structure(other, AnathemaFx.CURSED, 2.0)
	crowd._clock = 1.0
	var held := MissionKeeps.spared(house, crowd, d)
	var cursed := MissionKeeps.spared(other, crowd, d)
	crowd._clock = 2.5
	var lapsed := MissionKeeps.spared(house, crowd, d)
	t.check(held and not lapsed and not cursed,
		"a hallowed building is spared while the mark holds (at 1.0 s %s, at 2.5 s %s; cursed %s)" % [held, lapsed, cursed])
	_drop([house, other, crowd])


static func _kept_aside(t) -> void:
	var crowd := Crowd.new()
	var d := MissionDirector.new()
	var stone := _building(&"house")
	stone.damage_filter = func(st: Structure, _amount: float, _source: Vector2, _kind: StringName) -> void: st.shake(1.0)
	var aside := _building(&"house")
	d.reserved_places.append(aside)
	t.check(MissionKeeps.spared(stone, crowd, d) and MissionKeeps.spared(aside, crowd, d),
		"a building with a damage filter, or set aside, is spared")
	_drop([stone, aside, crowd])


static func _wanted_down(t) -> void:
	var crowd := Crowd.new()
	var raze := RazeDirector.new()
	var target := _building(&"house")
	var sealed := _building(&"house")
	raze.targets.append(target)
	raze.targets.append(sealed)
	raze.seal(sealed)
	var harvest := HarvestDirector.new()
	var granary := _building(&"granary")
	var holy := _building(&"granary")
	harvest.targets.append(granary)
	harvest.targets.append(holy)
	crowd.mark_structure(holy, AnathemaFx.HALLOWED, 30.0)
	t.check(not MissionKeeps.spared(target, crowd, raze) and not MissionKeeps.spared(sealed, crowd, raze)
		and not MissionKeeps.spared(granary, crowd, harvest) and not MissionKeeps.spared(holy, crowd, harvest),
		"a building the night wants down is never spared (Raze's target, a sealed one, a granary, a hallowed granary)")
	raze.teardown()
	_drop([target, sealed, granary, holy, crowd])


static func _no_director(t) -> void:
	var crowd := Crowd.new()
	var house := _building(&"house")
	var temple := _building(&"temple")
	t.check(not MissionKeeps.spared(house, crowd, null) and MissionKeeps.spared(temple, crowd, null)
		and MissionKeeps.spared(temple, null, null) and not MissionKeeps.spared(null, crowd, null),
		"no director: the generic rules only")
	_drop([house, temple, crowd])


## Each director names its own: [director, the member's name, a building put there, true for wants_down / false for
## needs_standing]. A stranger is neither.
static func _directors(t) -> void:
	var stub := _building(&"house")
	var stranger := _building(&"house")
	var keep: Array = []  # [director, member, wants_down?]
	keep.append([RazeDirector.new(), "targets", true])
	keep.append([HarvestDirector.new(), "targets", true])
	keep.append([CrownsBreadDirector.new(), "targets", true])
	keep.append([ArmouryDirector.new(), "targets", true])
	keep.append([HeartOfFaithDirector.new(), "targets", true])
	keep.append([BishopDirector.new(), "refuges", true])
	keep.append([BrokenLanternsDirector.new(), "shrines", true])
	keep.append([EscortDirector.new(), "bound_by", true])
	keep.append([PrisonerDirector.new(), "stocks", true])
	keep.append([HereticHuntDirector.new(), "standards", true])
	keep.append([LastJudgementDirector.new(), "", true])
	keep.append([JudgementDirector.new(), "", true])
	keep.append([BellRingersDirector.new(), "posts", false])
	keep.append([BellRingersDirector.new(), "_stone", false])
	keep.append([AssassinateDirector.new(), "hideout", false])
	keep.append([TaxCollectorDirector.new(), "hideout", false])
	keep.append([HereticHuntDirector.new(), "cellar", false])
	keep.append([HereticHuntDirector.new(), "temple", false])
	keep.append([LanternEyeDirector.new(), "standards", true])
	keep.append([LanternEyeDirector.new(), "temple", false])
	keep.append([LostLambDirector.new(), "fountain", false])
	keep.append([MirasHouseDirector.new(), "house", false])
	keep.append([SermonDirector.new(), "house", false])
	keep.append([FirstPrayersDirector.new(), "house", false])
	keep.append([WarningDirector.new(), "_key_gate", false])
	for row: Array in keep:
		var d: MissionDirector = row[0]
		var member: String = row[1]
		var down: bool = row[2]
		var name := "%s.%s" % [(d.get_script() as Script).get_global_name(), member]
		if member == "":
			stub.role = &"citadel"  # Last Judgement's goal: the Citadel's parts, by role
		else:
			stub.role = &"house"
			var now: Variant = d.get(member)
			if now is Array:
				(now as Array).append(stub)
			else:
				d.set(member, stub)
		var named := d.wants_down(stub) if down else d.needs_standing(stub)
		var other_side := d.needs_standing(stub) if down else d.wants_down(stub)
		t.check(named and not other_side and not d.needs_standing(stranger) and not d.wants_down(stranger),
			"each director names its goal buildings: %s %s (%s, the other side %s)" % [name, "wants_down" if down else "needs_standing", named, other_side])
		t.check(MissionKeeps.spared(stub, null, d) != down, "%s: spared() follows its side" % name)
	# The Lantern's Eye's standards are its towers: a blow on a raised one takes the mirror's glass (the goal), and the stone
	# filter keeps its health, so it never falls. Before it is raised its stone spares it.
	var eye := LanternEyeDirector.new()
	var tower := _building(&"")
	tower.damage_filter = func(st: Structure, _amount: float, _source: Vector2, _kind: StringName) -> void: st.shake(1.0)
	eye.towers.append(tower)
	var before := MissionKeeps.spared(tower, null, eye) and not eye.needs_standing(tower) and not eye.wants_down(tower)
	eye.standards.append(tower)
	var raised := not MissionKeeps.spared(tower, null, eye) and eye.wants_down(tower) and not eye.needs_standing(tower)
	t.check(before and raised, "the Lantern's Eye's tower is spared by its stone until raised, then may be struck (%s, %s)" % [before, raised])
	_kneel_shrine(t)
	_drop([stub, stranger, tower])


## Broken Lanterns (the controller's ruling): the last shrine, once the kneelers ring it, is kept -- a claw or slam breaking it
## early would cost the Faithful star -- while every other shrine stays the night's to break.
static func _kneel_shrine(t) -> void:
	var d := BrokenLanternsDirector.new()
	var last := _building(&"shrine")
	var other := _building(&"shrine")
	d.shrines.append(last)
	d.shrines.append(other)
	var before := d.wants_down(last) and not d.needs_standing(last) and not MissionKeeps.spared(last, null, d)
	d.kneel_shrine = last
	var kept := d.needs_standing(last) and not d.wants_down(last) and MissionKeeps.spared(last, null, d)
	var rest := d.wants_down(other) and not d.needs_standing(other) and not MissionKeeps.spared(other, null, d)
	t.check(before and kept and rest,
		"the kneeling shrine is kept once set, the other shrines may be broken (before %s, kept %s, the rest %s)" % [before, kept, rest])
	_drop([last, other])
