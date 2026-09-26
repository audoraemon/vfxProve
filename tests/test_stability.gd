extends RefCounted
## City Stability: each part falls linearly to its broken point, and the total is the spec's weighted sum.


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
	var stab := Stability.new().setup(env)

	stab.measure(env, crowd, town.citadel)
	t.near(stab.total(), 1.0, 0.0001, "an untouched city is at full stability (%.3f)" % stab.total())

	# Population: broken when 75% of the citizens are dead or gone, and linear on the way there.
	var half := int(Crowd.CITIZENS * Stability.POPULATION_BROKEN * 0.5)
	var broken := ceili(Crowd.CITIZENS * Stability.POPULATION_BROKEN)
	for i in half:
		field.kill(crowd.citizens[i], &"nova")
	crowd.advance(0.0)
	stab.measure(env, crowd, town.citadel)
	t.near(stab.population, 0.503, 0.01, "half the way to 75%% dead is half the population part (%.3f)" % stab.population)
	for i in range(half, broken):
		field.kill(crowd.citizens[i], &"nova")
	crowd.advance(0.0)
	stab.measure(env, crowd, town.citadel)
	t.check(stab.population == 0.0, "75%% dead or escaped breaks the population part (%.3f)" % stab.population)
	t.check(crowd.killed_citizens == broken, "the kills were counted (%d)" % crowd.killed_citizens)

	# Infrastructure is measured by footprint, so the wall weighs more than a house.
	var infra_area := 0.0
	for s in env.structures():
		if Stability.INFRA_ROLES.has(s.role):
			infra_area += s.footprint.get_area()
	t.check(infra_area > 0.0, "the town has an infrastructure footprint (%.1f)" % infra_area)
	var razed := 0.0
	for s in env.structures():
		if razed >= infra_area * Stability.INFRASTRUCTURE_BROKEN:
			break
		if Stability.INFRA_ROLES.has(s.role) and not s.destroyed:
			s.destroy(s.center(), &"nova")
			razed += s.footprint.get_area()
	stab.measure(env, crowd, town.citadel)
	t.check(stab.infrastructure == 0.0, "70%% of the footprint in rubble breaks infrastructure (%.3f)" % stab.infrastructure)

	# Leadership is the Citadel's health, straight through.
	t.near(stab.leadership, town.citadel.fraction(), 0.0001, "leadership is the Citadel's health (%.3f)" % stab.leadership)
	# Two rolling seconds of 200 damage: the Citadel's shared budget caps each rolling second at 250 of its
	# 1000, and it is the budget that lands, not the 200 a single part asked for -- so each round takes the
	# full 250, taking it to 50% and leaving it standing. Six rounds would flatten it, and the "has not
	# fallen" check below -- which is about a city whose Leadership is the only part left -- would then be
	# wrong.
	for i in 2:
		town.citadel.advance(1.01)
		env.damage_radius(TownLayout.CITADEL_ORIGIN, 4.0, 200.0, &"nova")
	stab.measure(env, crowd, town.citadel)
	t.near(stab.leadership, town.citadel.fraction(), 0.0001, "and follows it down (%.3f)" % stab.leadership)
	t.check(stab.leadership < 1.0, "the Citadel took damage (%.3f)" % stab.leadership)

	# Military: two thirds the soldiers (broken at 80% dead), one third the Barracks.
	var military_before := stab.military
	var barracks: Structure = null
	for s in env.structures():
		if s.role == &"barracks":
			barracks = s
			break
	barracks.destroy(barracks.center(), &"nova")
	stab.measure(env, crowd, town.citadel)
	t.near(military_before - stab.military, 1.0 - Stability.MILITARY_SOLDIER_SHARE, 0.0001,
		"the Barracks is a third of the military part (%.3f -> %.3f)" % [military_before, stab.military])
	for i in ceili(Crowd.SOLDIERS * Stability.SOLDIERS_BROKEN):
		field.kill(crowd.soldiers[i], &"nova")
	crowd.advance(0.0)
	stab.measure(env, crowd, town.citadel)
	t.check(stab.military == 0.0, "80%% of the soldiers dead with the Barracks gone breaks it (%.3f)" % stab.military)

	# Resources: the market stalls and the farm fields, counted per building.
	var res_total := 0
	for s in env.structures():
		if Stability.RESOURCE_ROLES.has(s.role):
			res_total += 1
	var res_down := 0
	for s in env.structures():
		if Stability.RESOURCE_ROLES.has(s.role) and not s.destroyed \
				and float(res_down) < float(res_total) * Stability.RESOURCES_BROKEN:
			s.destroy(s.center(), &"nova")
			res_down += 1
	stab.measure(env, crowd, town.citadel)
	t.check(res_total >= 5 and stab.resources == 0.0,
		"80%% of the market and the farms breaks resources (%d of %d, %.3f)" % [res_down, res_total, stab.resources])

	# The total is the weighted sum, and everything broken is a fallen city.
	t.near(stab.total(), Stability.W_LEADERSHIP * stab.leadership, 0.0001,
		"with only leadership left the total is its weight (%.3f)" % stab.total())
	t.check(not stab.is_broken(), "a city with a standing Citadel has not fallen")
	while not town.citadel.is_fallen():
		town.citadel.advance(1.01)
		env.damage_radius(TownLayout.CITADEL_ORIGIN, 4.0, 400.0, &"nova")
	stab.measure(env, crowd, town.citadel)
	t.check(stab.is_broken() and stab.total() == 0.0, "with the Citadel down as well, the city has fallen (%.3f)" % stab.total())

	# The weights are the spec's, and they add up.
	t.near(Stability.W_POPULATION + Stability.W_INFRASTRUCTURE + Stability.W_LEADERSHIP + Stability.W_MILITARY
		+ Stability.W_RESOURCES, 1.0, 0.0001, "the five weights add up to one")

	crowd.clear()
	field.clear()
	field.free()
	env.clear()
	env.free()
	town.free()
	crowd.free()
	world.free()
