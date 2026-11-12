extends RefCounted
## Doors of the Dead (Passage, Tier V): every door in a district opens onto the other side. The cold slows whoever is
## in it; the houses throw out whoever sheltered there and take nobody in; hellhounds, ghosts and demons come out of
## the doors in a fixed turn, hunt, and claw at buildings; at the span's end they are called back and the cold lifts.
## The Visitors' new traits (ghosts through walls, demons at buildings) are checked on their own first.

const DT := 0.05


static func _setup() -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)
	crowd.spawn()
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.world = world
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return [crowd, env, grid, field, world, ctx]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


static func _run(fx: FxTimeline, seconds: float) -> void:
	for i in roundi(seconds / DT):
		fx._process(DT)


## Everyone far off in a corner, out of every reach.
static func _clear_town(crowd: Crowd) -> void:
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		person.mind = Person.Mind.CALM
		i += 1


## A standing house (role house) with open ground on its front face, near `at`.
static func _house_near(env: EnvironmentField, grid: WalkGrid, at: Vector2) -> Structure:
	var best: Structure = null
	var best_d := INF
	for s in env.structures():
		if s.destroyed or s.role != &"house":
			continue
		var d := s.distance_to(at)
		if d < best_d and grid.walkable(EveryDoorFx.door_of(s, grid) + Vector2(0.0, 0.4)):
			best_d = d
			best = s
	return best


static func run(t) -> void:
	var b := PowerBook.get_power("deaddoors")
	var area: Dictionary = Targeting.AREAS.get("deaddoors", {})
	t.check(int(b.dp) == 6 and not PowerBook.is_quiet("deaddoors") and String(b.aim) == "click" and float(b.cooldown) == 999.0
		and PowerBook.authority_of("deaddoors") == "passage" and PowerBook.icon("deaddoors") != null
		and PowerBook.hud_icon("deaddoors") != null and PowerBook.clip("deaddoors") != null
		and area.get("shape", "") == "circle" and is_equal_approx(float(area.get("r", 0.0)), DoorsOfTheDeadFx.RADIUS)
		and Rules.POWER_KINDS.get("deaddoors", []) == [&"frenzy"]
		and is_equal_approx(PowerBook.impact("deaddoors"), DoorsOfTheDeadFx.first_out())
		and PowerBook.family("deaddoors") != "",
		"Doors of the Dead is Passage's 6 DP, loud, once a descent, a click on a district of RADIUS, its kills frenzy, its impact the first spirit out, with icons, clip and a family")
	t.check(Animal.sheet(Animal.Breed.DEMON).get("cell", 0) == 48 and Animal.sheet(Animal.Breed.GHOST).get("cell", 0) == 36
		and not (Animal.Breed.DEMON in Animal.DOGS) and not (Animal.Breed.GHOST in Animal.CATS)
		and Animal.OTHER_SIDE == [Animal.Breed.HELLHOUND, Animal.Breed.DEMON, Animal.Breed.GHOST],
		"the demon and the ghost have their own painted sheets, and like the hellhound are of the other side, never the town's")

	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var world: Node2D = made[4]
	var ctx: FxContext = made[5]
	_clear_town(crowd)
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())

	# --- The traits on their own. A ghost goes straight through a house to the one behind it.
	var house := _house_near(env, grid, at)
	t.check(house != null, "a house by the market for the traits")
	var visitors := Visitors.new().setup(field, crowd, grid, world)
	var prey: Person = crowd.citizens[0]
	var c := house.center()
	var half := house.footprint.size * 0.5
	prey.ground_pos = c + Vector2(0.0, -half.y - 1.2)
	var ghost := visitors.summon(c + Vector2(0.0, half.y + 1.2), Animal.Breed.GHOST, 3, 1.0, 9.0, 0.45, 1.6, true)
	visitors.give(ghost, {"phase": true})
	var crossed := false
	for k in roundi(8.0 / DT):
		visitors.step(DT)
		crossed = crossed or house.footprint.has_point(ghost.ground_pos)
		if not prey.is_alive():
			break
	t.check(crossed and not prey.is_alive() and prey._kind == &"frenzy",
		"a ghost (phase) walks straight through the house to the one behind it and its touch kills (frenzy)")
	visitors.clear()

	# A demon with nobody to hunt goes at the nearest building and claws it down; each blow is a "wrecked".
	visitors = Visitors.new().setup(field, crowd, grid, world)
	var door := EveryDoorFx.door_of(house, grid)
	var spawn := grid.nearest_walkable(door + (door - c).normalized() * 1.5)
	var before := {}
	for s in env.near(spawn, 9.0):
		before[s] = s.hp
	var blows := {}
	visitors.wrecked.connect(func(_a, s): blows[s] = int(blows.get(s, 0)) + 1)
	var demon := visitors.summon(spawn, Animal.Breed.DEMON, 8, 1.0, 8.0, 0.6, 1.2, false)
	visitors.give(demon, {"wreck": DoorsOfTheDeadFx.DEMON_WRECK, "wreck_every": DoorsOfTheDeadFx.DEMON_WRECK_EVERY,
		"wreck_reach": DoorsOfTheDeadFx.DEMON_WRECK_REACH})
	for k in roundi(6.0 / DT):
		visitors.step(DT)
	var n := 0
	var lost := 0.0
	var clawed: Structure = null
	for s in blows.keys():
		n += int(blows[s])
		lost += float(before.get(s, s.max_hp)) - (0.0 if s.destroyed else s.hp)
		clawed = s
	t.check(n >= 2 and lost >= 2.0 * DoorsOfTheDeadFx.DEMON_WRECK - 0.01 and clawed != null and Visitors._wreckable(clawed) == not clawed.destroyed,
		"a demon with nobody near goes to the nearest building and claws it, DEMON_WRECK every DEMON_WRECK_EVERY (%d blows, %.0f lost)" % [n, lost])
	visitors.clear()
	for s in before.keys():
		if not s.destroyed:
			s.hp = before[s]

	# --- The cast. People near and far, one sheltering in a house the doors will take.
	var near: Person = crowd.citizens[1]
	near.ground_pos = grid.nearest_walkable(at + Vector2(1.5, 0.5))
	var far: Person = crowd.citizens[2]
	far.ground_pos = grid.nearest_walkable(at + Vector2(DoorsOfTheDeadFx.RADIUS + 4.0, 0.0))
	var fx: DoorsOfTheDeadFx = FxTimeline.cast(load("res://src/fx/control/doors_of_the_dead.gd"), ctx, at)
	var ok_doors := fx.doors.size() > 0 and fx.doors.size() <= DoorsOfTheDeadFx.MAX_DOORS
	var last_d := -1.0
	var last_open := -1.0
	for d in fx.doors:
		var dd := d.building.distance_to(at)
		ok_doors = ok_doors and dd <= DoorsOfTheDeadFx.RADIUS and dd >= last_d - 0.001 and d.opens >= last_open \
			and d.building.role in EveryDoorFx.DOOR_ROLES
		last_d = dd
		last_open = d.opens
	t.check(ok_doors and is_equal_approx(fx.doors[0].opens, DoorsOfTheDeadFx.T_CHILL)
		and fx.doors[fx.doors.size() - 1].opens <= DoorsOfTheDeadFx.T_CHILL + DoorsOfTheDeadFx.WAVE + 0.001,
		"the doors are the %d nearest buildings with a door within RADIUS, opening nearest first over WAVE from T_CHILL" % fx.doors.size())
	var taken: Structure = fx.doors[0].building
	var dweller: Person = crowd.citizens[3]
	if crowd.shelters.shelters.has(taken):
		dweller.mind = Person.Mind.SHELTER
		dweller.shelter = taken
		dweller.shelter_door = crowd.shelters._door(taken, taken.center() + Vector2(0.0, 5.0))
		crowd.shelters._enter(dweller, taken)
		(crowd.shelters.shelters[taken].inside as Array).append(dweller)
	_run(fx, DoorsOfTheDeadFx.T_CHILL - 0.3)
	t.check(not fx.chilled(near) and fx.spirits == 0 and near.pace_hold() == 1.0,
		"before the cold has come in, nobody is slowed and nothing has come through")
	var taken_hp := taken.hp
	_run(fx, 0.6)
	t.check(fx.chilled(near) and is_equal_approx(near.pace_hold(), DoorsOfTheDeadFx.COLD_SLOW)
		and not fx.chilled(far) and far.pace_holds.is_empty(),
		"in the cold everyone walks at COLD_SLOW; one outside the district does not")
	t.check(taken.hp < taken_hp and crowd.structure_mark(taken) == &"cursed",
		"the first door opens: its building is struck and cursed (nobody shelters there) (%.0f of %.0f)" % [taken_hp - taken.hp, taken_hp])
	if crowd.shelters.shelters.has(taken):
		t.check(not dweller.inside and fx.thrown >= 1 and not (crowd.shelters.shelters[taken].inside as Array).has(dweller),
			"whoever sheltered in it is thrown out into the street")
	_run(fx, DoorsOfTheDeadFx.WAVE + DoorsOfTheDeadFx.OUT_FIRST + 0.2)
	var all_open := true
	for d in fx.doors:
		all_open = all_open and (d.open or d.building.destroyed)
	t.check(all_open and fx.spirits >= fx.doors.size(), "every door is open and each has let one through (%d)" % fx.spirits)
	_run(fx, DoorsOfTheDeadFx.OUT_EVERY * 3.0)
	var kinds := {}
	for a in fx.visitors.living():
		kinds[a.breed] = true
	t.check(kinds.has(Animal.Breed.HELLHOUND) and kinds.has(Animal.Breed.GHOST) and kinds.has(Animal.Breed.DEMON)
		and fx.visitors.living().size() <= DoorsOfTheDeadFx.LIVE_CAP,
		"the doors keep sending, in the fixed turn -- hounds, ghosts and demons -- never more than LIVE_CAP on their feet (%d out)" % fx.spirits)
	var phases := true
	for a in fx.visitors.living():
		var r: Visitors.Rule = fx.visitors._rules[a]
		phases = phases and r.phase == (a.breed == Animal.Breed.GHOST) and (r.wreck > 0.0) == (a.breed == Animal.Breed.DEMON)
	t.check(phases, "only the ghosts go through walls and only the demons claw at buildings")
	var mid := fx.spirits
	var peak := 0
	while fx.t < fx.t_end() - 0.1:
		fx._process(DT)
		peak = maxi(peak, fx.visitors.living().size())
	t.check(fx.spirits > mid and fx.spirits <= DoorsOfTheDeadFx.MAX_SPIRITS and peak <= DoorsOfTheDeadFx.LIVE_CAP,
		"they come for the whole span, filling back the fallen: %d through by the end (%d at the third turn), at most %d on their feet (MAX_SPIRITS %d, LIVE_CAP %d)" % [fx.spirits, mid, peak, DoorsOfTheDeadFx.MAX_SPIRITS, DoorsOfTheDeadFx.LIVE_CAP])
	var at_end := fx.spirits
	_run(fx, 1.0)
	t.check(fx.spirits == at_end, "none come once the span is over")
	_run(fx, DoorsOfTheDeadFx.RECALL + 0.3)
	t.check(fx.visitors.living().is_empty() and not fx.chilled(near) and near.pace_holds.is_empty(),
		"the span over, the other side is called back through the doors and the cold lifts: everyone has their pace back")
	t.check(fx.kills() >= 0 and fx.wrecks >= 0, "kills %d, demon blows %d" % [fx.kills(), fx.wrecks])
	fx.free()
	_freed(t, made, at)
	_exit(t, made, at)
	_done(made)


## The first citizen still alive from index `from` (the horde of the main cast killed some).
static func _alive(crowd: Crowd, from: int) -> Person:
	for k in range(from, crowd.citizens.size()):
		var p: Person = crowd.citizens[k]
		if p.is_alive() and not p.inside:
			return p
	return null


## One in the cold freed mid-span (they left the town: Crowd.escape, or another power took them "gone"), and a door's
## building torn out of the map: both dropped without an error, the doors left go on sending, and the end is clean.
static func _freed(t, made: Array, at: Vector2) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	_clear_town(crowd)
	var gone := _alive(crowd, 0)
	gone.ground_pos = grid.nearest_walkable(at + Vector2(1.0, 1.0))
	var fx: DoorsOfTheDeadFx = FxTimeline.cast(load("res://src/fx/control/doors_of_the_dead.gd"), ctx, at)
	_run(fx, DoorsOfTheDeadFx.T_CHILL + DoorsOfTheDeadFx.WAVE + DoorsOfTheDeadFx.OUT_FIRST + 0.2)
	var id := gone.get_instance_id()
	var torn: DoorsOfTheDeadFx.Door = null
	for d in fx.doors:
		if d.open and d != fx.doors[0]:
			torn = d
			break
	t.check(fx.chilled(gone) and torn != null, "(one in the cold, a door open)")
	crowd.citizens.erase(gone)
	field.remove(gone)
	gone.free()
	env.remove(torn.building)
	var sent := fx.spirits
	_run(fx, DoorsOfTheDeadFx.OUT_EVERY + 0.3)
	t.check(not fx._cold.has(id) and not torn.open and fx.spirits > sent,
		"one in the cold freed mid-span and a door's building torn down: both dropped without an error, the other doors still send")
	fx.end_now()
	t.check(fx.finished and fx.visitors.living().is_empty() and fx._cold.is_empty(), "and the effect ends cleanly")
	fx.free()


## Freed without _finish (Battlefield.clear_effects() on a restart queue_frees it): the spirits are gone and the pack leaves
## the town, everyone in the cold has their pace back, with no error; its end after that changes nothing.
static func _exit(t, made: Array, at: Vector2) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	_clear_town(crowd)
	var cold := _alive(crowd, 0)
	cold.ground_pos = grid.nearest_walkable(at + Vector2(-1.0, 1.0))
	var fx: DoorsOfTheDeadFx = FxTimeline.cast(load("res://src/fx/control/doors_of_the_dead.gd"), ctx, at, {"level": 5})
	_run(fx, DoorsOfTheDeadFx.T_CHILL + DoorsOfTheDeadFx.WAVE + DoorsOfTheDeadFx.OUT_FIRST + 0.2)
	var pack := fx.visitors
	var up := pack.living()
	t.check(not up.is_empty() and crowd.visitors.has(pack) and fx.chilled(cold) and cold.pace_hold() < 1.0,
		"(spirits up: %d, one slowed in the cold)" % up.size())
	var wind := AudioStreamPlayer2D.new()
	wind.set_meta(&"cue", &"glac_wind")
	fx._winds.append(wind)
	fx._exit_tree()
	var gone := true
	for a in up:
		gone = gone and (not is_instance_valid(a) or a.is_queued_for_deletion())
	t.check(gone and pack.living().is_empty() and not crowd.visitors.has(pack),
		"freed without its end, the spirits are gone and the pack leaves the town")
	t.check(not fx.chilled(cold) and cold.pace_holds.is_empty() and fx._winds.is_empty(),
		"and nobody is left slowed by the cold, and the wind is stopped")
	fx.end_now()
	t.check(fx.finished and cold.pace_holds.is_empty(), "and its end after that changes nothing")
	fx.free()
	wind.free()
