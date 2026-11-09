extends RefCounted
## The town's dogs and cats (Discord idea "Animals", AnimalPack): they are spawned round the citizens' haunts in six
## breeds, wander without touching anyone, run from a danger and die under a strike; the mind powers turn them --
## Madness Bloom sends them biting (a soldier cuts them down), Congregation gathers them, Clear Mind sits them -- and
## nothing they do lights a fire. With AnimalPack.enabled off there are none, so the references never see them.

const CM := preload("res://tests/test_clear_mind.gd")


static func run(t) -> void:
	_off(t)
	AnimalPack.enabled = true
	_spawn_and_wander(t)
	_danger(t)
	_madness(t)
	_gather_and_trance(t)
	_stuck(t)
	_night(t)
	AnimalPack.enabled = false


static func _off(t) -> void:
	AnimalPack.enabled = false
	var made := CM._setup()
	t.check((made[0] as Crowd).animals == null, "with AnimalPack.enabled off the town has no animals")
	CM._done(made)


static func _spawn_and_wander(t) -> void:
	var made := CM._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var pack := crowd.animals
	t.check(pack != null and pack.animals.size() >= AnimalPack.MIN and pack.animals.size() <= AnimalPack.MAX,
		"the town has its dogs and cats (%d)" % (pack.animals.size() if pack != null else -1))
	if pack == null:
		CM._done(made)
		return
	var breeds := {}
	var dogs := 0
	for a in pack.animals:
		breeds[a.breed] = true
		dogs += 1 if a.is_dog() else 0
		t.check(grid.walkable(a.ground_pos), "an animal starts on walkable ground")
	t.check(breeds.size() >= 4 and dogs > 0 and dogs < pack.animals.size(), "dogs and cats of several breeds (%d breeds, %d dogs)" % [breeds.size(), dogs])
	var before: Array = []
	for p in crowd.citizens:
		before.append([p.ground_pos, p.mind, p.health])
	var start: Array = []
	for a in pack.animals:
		start.append(a.ground_pos)
	for i in 300:
		pack.step(0.05)
	var moved := 0
	var off_grid := 0
	for i in pack.animals.size():
		var a: Animal = pack.animals[i]
		moved += 1 if a.ground_pos.distance_to(start[i]) > 0.2 else 0
		off_grid += 0 if grid.walkable(a.ground_pos) else 1
	t.check(moved > pack.animals.size() / 3, "they wander about (%d of %d moved)" % [moved, pack.animals.size()])
	t.check(off_grid == 0, "and never onto a building or water (%d off)" % off_grid)
	var same := true
	for i in crowd.citizens.size():
		var p: Person = crowd.citizens[i]
		same = same and p.ground_pos == before[i][0] and p.mind == before[i][1] and p.health == before[i][2]
	t.check(same, "wandering animals touch nobody")
	CM._done(made)


static func _danger(t) -> void:
	var made := CM._setup()
	var crowd: Crowd = made[0]
	var pack := crowd.animals
	var grid: WalkGrid = made[2]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var near: Animal = pack.animals[0]
	var close: Animal = pack.animals[1]
	near.ground_pos = at + Vector2(1.8, 0.0)
	close.ground_pos = at + Vector2(0.2, 0.0)
	crowd.threats.register(at, 1.0, 0.8, 5.0, 4.0, 6.0, &"meteor")
	pack.step(0.3)
	t.check(not close.is_alive(), "an animal under a strike dies")
	t.check(near.is_alive() and near.state == Animal.State.FLEE, "one beside it runs")
	CM._done(made)


static func _madness(t) -> void:
	var made := CM._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var pack := crowd.animals
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	for a in pack.animals:
		a.ground_pos = Vector2(27, 27)
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var dog: Animal = null
	for a in pack.animals:
		if a.is_dog():
			dog = a
			break
	dog.ground_pos = at
	var victim: Person = crowd.citizens[0]
	victim.ground_pos = at + Vector2(1.2, 0.0)
	victim.mind = Person.Mind.CALM
	var rng_before := ctx.rng.state
	var fx: MadnessBloomFx = FxTimeline.cast(load("res://src/fx/curse/madness_bloom.gd"), ctx, at + Vector2(0.3, 0.0))
	fx._process(MadnessBloomFx.ANIMAL_DELAY + 0.05)
	t.check(dog.state == Animal.State.ATTACK and dog.hypnotized(), "Madness Bloom turns a dog in its circle")
	var fires_before := crowd.fires.fires.size()
	var health := victim.health
	for k in 80:
		pack.step(0.05)
	t.check(victim.health < health, "it goes for the nearest and bites (%.2f -> %.2f)" % [health, victim.health])
	t.check(crowd.threats.active_count() > 0, "the town sees the danger")
	var fires_after := crowd.fires.fires.size()
	t.check(fires_after == fires_before, "nothing is set alight")
	var guard: Person = crowd.soldiers[0]
	guard.ground_pos = dog.ground_pos + Vector2(0.2, 0.0)
	for k in 40:
		pack.step(0.05)
	t.check(not dog.is_alive(), "a soldier beside it cuts it down")
	t.check(field.alive().size() > 0 and rng_before != null, "the people are still there")
	fx.queue_free()
	CM._done(made)


static func _gather_and_trance(t) -> void:
	var made := CM._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var pack := crowd.animals
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var cat: Animal = null
	for a in pack.animals:
		if not a.is_dog():
			cat = a
			break
	cat.ground_pos = at + Vector2(2.0, 0.0)
	t.check(AnimalPack.cast(ctx, at, 3.0, Animal.Spell.GATHER, 10.0, null, at) >= 1 and cat.state == Animal.State.GATHER,
		"a gathering power draws the cat")
	for k in 100:
		pack.step(0.05)
	t.check(cat.ground_pos.distance_to(at) < 0.6, "it walks to the place (%.2f away)" % cat.ground_pos.distance_to(at))
	for k in 200:
		pack.step(0.05)
	t.check(not cat.hypnotized(), "and is free again when the hold ends")
	var fx: ClearMindFx = FxTimeline.cast(load("res://src/fx/dominion/clear_mind.gd"), ctx, at)
	fx._process(ClearMindFx.T_CAST + 0.05)
	t.check(cat.state == Animal.State.TRANCE, "Clear Mind sits it in a trance")
	var p0 := cat.ground_pos
	for k in 40:
		pack.step(0.05)
	t.check(cat.ground_pos == p0, "and it stays put")
	fx.queue_free()
	CM._done(made)


## A goal behind a wall: it does not walk on the spot for ever (sliding to and fro along the wall) but gives up, and
## standing still never shows the walk.
static func _stuck(t) -> void:
	var made := CM._setup()
	var grid: WalkGrid = made[2]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var wall := Vector2.INF
	for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]:
		for k in range(1, 40):
			var q: Vector2 = at + dir * (k * 0.25)
			if not grid.walkable(q):
				wall = q + dir * 0.6
				at = q - dir * 1.2
				break
		if wall != Vector2.INF:
			break
	t.check(wall != Vector2.INF, "there is a wall near the square to walk into")
	var a := Animal.new()
	a.ground_pos = grid.nearest_walkable(at)
	var gave_up := false
	var moving_frames := 0
	for k in 80:
		if a.walk_to(wall + Vector2(0.3, 0.4), 0.05, grid):
			gave_up = true
			break
		a.tick_visual(0.05)
	t.check(gave_up and a.blocked, "walking into a wall it gives up rather than walk on the spot")
	for k in 5:
		a.tick_visual(0.05)
	for k in 10:
		a.tick_visual(0.05)
		moving_frames += 1 if a._pose_now() == &"walk" else 0
	t.check(moving_frames == 0, "and standing still it does not show the walk")
	a.free()
	CM._done(made)


## At night (the NIGHT look) dogs mostly lie down to sleep and keep near home; cats prowl, roaming farther than by day.
static func _night(t) -> void:
	var made := CM._setup()
	var pack: AnimalPack = (made[0] as Crowd).animals
	var dog: Animal = null
	var cat: Animal = null
	for a in pack.animals:
		if a.is_dog() and dog == null:
			dog = a
		elif not a.is_dog() and cat == null:
			cat = a
	var was = TownLook.active
	var lies := [0, 0]
	for night in [false, true]:
		TownLook.active = Town.Look.NIGHT if night else Town.Look.DAY
		for k in 200:
			lies[1 if night else 0] += 1 if pack._pick_idle(dog) == &"lie" else 0
	t.check(AnimalPack.is_night(), "the NIGHT look is night to the animals")
	t.check(lies[1] > 80 and lies[1] > lies[0] * 3, "at night a dog mostly lies down to sleep (%d of 200, by day %d)" % [lies[1], lies[0]])
	var cat_lies := 0
	for k in 200:
		cat_lies += 1 if pack._pick_idle(cat) == &"lie" else 0
	t.check(cat_lies < lies[1] / 2, "a cat sleeps far less at night (%d of 200)" % cat_lies)
	var reach := [0.0, 0.0]
	for night in [false, true]:
		TownLook.active = Town.Look.NIGHT if night else Town.Look.DAY
		for k in 100:
			cat.home = cat.ground_pos
			pack._next_errand(cat)
			reach[1 if night else 0] = maxf(reach[1 if night else 0], cat.goal.distance_to(cat.home))
	t.check(reach[1] > reach[0], "a cat roams farther at night (%.1f against %.1f)" % [reach[1], reach[0]])
	TownLook.active = was
	CM._done(made)
