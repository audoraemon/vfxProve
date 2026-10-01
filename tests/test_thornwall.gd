extends RefCounted
## v0.06 Thornwall: five bramble segments grow across the street and close the walk grid; anyone standing there is
## shoved clear; the town notices (one alarm for the wall); after THORN_TIME they wither and the ground opens; engineers
## can cut a segment down; burning one away is no incident.


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
	ctx.rng = RandomNumberGenerator.new()
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return [crowd, env, grid, field, world, ctx]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[4] as Node).free()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()


static func run(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := Vector2(2.75, 11.25)  # across the Main Gate's plaza
	var rects := ThornwallFx.rects(at, Vector2(1, 0))
	var bystander: Person = crowd.citizens[0]
	bystander.ground_pos = rects[2].get_center()
	var alarm := crowd.alarm
	var fx: ThornwallFx = FxTimeline.cast(load("res://src/fx/control/thornwall.gd"), ctx, at, {"dir": Vector2(1, 0)})
	var closed := true
	for r in rects:
		closed = closed and not grid.walkable(r.get_center())
	t.check(fx.segments.size() == ThornwallFx.THORN_SEGMENTS and closed, "five segments grow and close the street")
	t.check(not rects[2].grow(0.15).has_point(bystander.ground_pos) and bystander.is_alive(),
		"someone standing there is shoved clear, unhurt")
	t.check(is_equal_approx(crowd.alarm - alarm, Crowd.THORN_ALARM), "the town notices the wall once (+%.1f)" % (crowd.alarm - alarm))
	t.check(fx.busy == 1.0, "its cast locks the slots for 1 s, not its whole run")

	# Burning one away is no incident.
	alarm = crowd.alarm
	fx.segments[0].destroy(fx.segments[0].center(), &"fire")
	t.check(crowd.alarm == alarm and crowd.threats.active_count() == 0, "a bramble burnt away raises nothing")

	# Withering: the ground opens again.
	fx._process(ThornwallFx.THORN_TIME + 0.1)
	var gone := true
	for s in env.structures():
		gone = gone and s.role != &"thorns"
	t.check(gone and grid.walkable(rects[2].get_center()), "after %d s it withers and the street opens" % roundi(ThornwallFx.THORN_TIME))

	# The engineers cut a wall down.
	fx = FxTimeline.cast(load("res://src/fx/control/thornwall.gd"), ctx, at, {"dir": Vector2(1, 0)})
	crowd._on_stage(AlarmManager.Stage.CITY_EMERGENCY, "test")
	var e := crowd.engineers
	e.step(0.1)
	var clearing: Dictionary = {}
	for team in e.teams:
		if team.job.get("type", -1) == EngineerManager.Job.CLEAR:
			clearing = team
	t.check(not clearing.is_empty(), "an engineer team goes to cut it down")
	var target: Structure = clearing.job.target
	for i in clearing.members.size():
		var m: Person = clearing.members[i]
		m.ground_pos = clearing.spots[i]
		m._goal = Vector2.INF
		m._path = PackedVector2Array()
	e.step(EngineerManager.CLEAR_TIME + 0.1)
	t.check(not is_instance_valid(target) or not env.structures().has(target), "and clears a segment in %d s" % roundi(EngineerManager.CLEAR_TIME))
	fx._process(ThornwallFx.THORN_TIME + 0.1)
	fx.free()
	_done(made)
