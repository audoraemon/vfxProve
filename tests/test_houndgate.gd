extends RefCounted
## Hound Gate (Passage, Tier II): a door opens in the ground and four hounds of the other side come through, hunting
## whoever is nearest; they fear nothing, the guard cuts them down, and after the hunt they are called back through
## the door. The Visitors (src/game/crowd/visitors.gd) are the reusable piece: hostile walkers the pack never steps.

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


## Steps the effect `seconds` in DT ticks (the hounds are stepped by it; people stand where they are put).
static func _run(fx: FxTimeline, seconds: float) -> void:
	for i in roundi(seconds / DT):
		fx._process(DT)


## A portal that carries everything 6 units down the ground (EnemyField.through).
class Shift extends RefCounted:
	func carries(_p: Vector2) -> bool:
		return true

	func across(p: Vector2) -> Vector2:
		return p + Vector2(0, 6)


static func run(t) -> void:
	var b := PowerBook.get_power("houndgate")
	var area: Dictionary = Targeting.AREAS.get("houndgate", {})
	t.check(int(b.dp) == 2 and not PowerBook.is_quiet("houndgate") and String(b.aim) == "click"
		and PowerBook.authority_of("houndgate") == "passage" and PowerBook.icon("houndgate") != null
		and PowerBook.hud_icon("houndgate") != null and PowerBook.clip("houndgate") != null
		and area.get("shape", "") == "circle" and is_equal_approx(float(area.get("r", 0.0)), 0.6)
		and Rules.POWER_KINDS.get("houndgate", []) == [&"frenzy"]
		and is_equal_approx(PowerBook.impact("houndgate"), HoundGateFx.T_OPEN + HoundGateFx.OUT_EVERY)
		and PowerBook.family("houndgate") != "",
		"Hound Gate is Passage's 2 DP, loud, a click on a circle of 0.6, its kills frenzy, its impact the first hound's bite, with icons, clip and a family")

	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var world: Node2D = made[4]
	var ctx: FxContext = made[5]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())

	# --- The Visitors on their own: one summoned runs at the one person near it at the speed it is given.
	var visitors := Visitors.new().setup(field, crowd, grid, world)
	var prey: Person = crowd.citizens[0]
	prey.mind = Person.Mind.CALM
	prey.ground_pos = grid.nearest_walkable(at + Vector2(3.0, 0.0))
	var mul := HoundGateFx.SPEED / (Animal.DOG_SPEED * Animal.RUN)
	var one := visitors.summon(at, Animal.Breed.HOUND, 3, mul, 8.0, 0.5, 1.0)
	var gap := one.ground_pos.distance_to(prey.ground_pos)
	t.check(visitors.living().size() == 1 and one.get_parent() == world and one.is_alive(), "Visitors: a summoned hound stands at its gate")
	for k in 10:
		visitors.step(DT)
	var closed := gap - one.ground_pos.distance_to(prey.ground_pos)
	t.check(closed > HoundGateFx.SPEED * 0.5 * 0.7 and closed < HoundGateFx.SPEED * 0.5 * 1.3,
		"it runs at the nearest person at SPEED (closed %.2f in half a second)" % closed)
	visitors.clear()
	t.check(visitors.living().is_empty() and not is_instance_valid(one), "clear() frees it")
	prey.ground_pos = Vector2(-27.0, -27.0)

	# --- The gate: nothing before the door opens, then a hound every OUT_EVERY.
	var victim: Person = crowd.citizens[1]
	victim.mind = Person.Mind.CALM
	victim.ground_pos = grid.nearest_walkable(at + Vector2(2.0, 0.0))
	var alarm := crowd.alarm
	var fx: HoundGateFx = FxTimeline.cast(load("res://src/fx/control/hound_gate.gd"), ctx, at)
	t.check(fx.mouth == at and is_equal_approx(fx.busy, HoundGateFx.T_OPEN)
		and is_equal_approx(fx.duration, fx.hunt_end() + HoundGateFx.BURN + 0.1) and HoundGateFx.T_OPEN >= HoundGateFx.T_RISE + HoundGateFx.DOORS
		and fx.shut_at() > fx.last_out() and fx.gone() < fx.last_out() + 3.0,
		"the gate rises where the click lands; the cast is busy while its doors open; it is gone soon after the last hound is out")
	_run(fx, HoundGateFx.T_OPEN - 0.1)
	t.check(fx.out == 0 and fx.visitors.living().is_empty() and victim.is_alive(), "no hound before the door opens")
	_run(fx, 0.1 + HoundGateFx.HOUNDS * HoundGateFx.OUT_EVERY)
	t.check(fx.out == HoundGateFx.HOUNDS and fx.visitors.living().size() == HoundGateFx.HOUNDS and fx.hunting(),
		"HOUNDS hounds are out and alive OUT_EVERY apart (%d)" % fx.visitors.living().size())
	var on_grid := true
	for a in fx.visitors.living():
		on_grid = on_grid and grid.walkable(a.ground_pos) and a.speed_mul > 1.0 and a.get_parent() == world
	t.check(on_grid, "each stands on walkable ground by the door, a hound of the other side at its own pace")
	_run(fx, 4.0)
	t.check(not victim.is_alive() and victim._kind == &"frenzy" and fx.kills() == 1,
		"a calm citizen two steps from the door is run down and bitten dead (frenzy) within 4 s, and the gate counts him")
	t.check(crowd.alarm > alarm, "the first bite's outcry raises the town's alarm (%.1f -> %.1f)" % [alarm, crowd.alarm])

	# --- The guard. A hound bites through blows (it does not flinch): a lone soldier falls to it before his BLOWS
	# blows are done; two bring one down and lose one of their own.
	var hounds := fx.visitors.living()
	var one_hound: Animal = hounds[0]
	var two_hound: Animal = hounds[1]
	for k in range(2, hounds.size()):
		var a: Animal = hounds[k]
		a.ground_pos = at + Vector2(-9.0 + float(k), 9.0)
		a.sync_position()
	two_hound.ground_pos = at + Vector2(9.0, -9.0)
	two_hound.sync_position()
	var guard: Person = crowd.soldiers[0]
	guard.ground_pos = one_hound.ground_pos + Vector2(0.3, 0.0)
	var took := 0.0
	while guard.is_alive() and took < HoundGateFx.BLOWS * Visitors.GUARD_SWING:
		fx._process(DT)
		took += DT
	t.check(not guard.is_alive() and is_instance_valid(one_hound) and one_hound.is_alive() and fx.slain() == 0,
		"a lone soldier beside a hound is bitten dead (%.2f s) before his %d blows are done; the hound lives" % [took, HoundGateFx.BLOWS])
	var pair: Array[Person] = [crowd.soldiers[1], crowd.soldiers[2]]
	for k in 2:
		pair[k].ground_pos = two_hound.ground_pos + Vector2(0.3, -0.15 + 0.3 * float(k))
	took = 0.0
	while is_instance_valid(two_hound) and two_hound.is_alive() and took < HoundGateFx.BLOWS * Visitors.GUARD_SWING + 1.0:
		fx._process(DT)
		took += DT
	var fell := 0
	for p in pair:
		if not p.is_alive():
			fell += 1
	t.check(not is_instance_valid(two_hound) and fx.slain() == 1 and fell == 1,
		"two soldiers cut a hound down (%.2f s) and one of them dies doing it (%d fell)" % [took, fell])

	# --- Fear nothing: a loud danger on top of a hound does not send it running.
	var far: Animal = fx.visitors.living()[0]
	crowd.threats.register(far.ground_pos, 2.0, 1.0, 5.0, 8.0, 10.0, &"fire")
	_run(fx, 1.0)
	t.check(far.is_alive() and far.state != Animal.State.FLEE, "a hound never flees a danger (%s)" % Animal.State.keys()[far.state])

	# --- The recall: after the hunt every hound goes back through the door and none remains.
	var left := fx.visitors.living()
	_run(fx, fx.duration - fx.t + 0.1)
	var gone := true
	for a in left:
		gone = gone and not is_instance_valid(a)
	t.check(fx.finished and fx.visitors.living().is_empty() and gone, "the hunt over, the hounds still on their feet burn away where they stand and none remains")
	fx.free()

	# --- Cut short mid-hunt: the hounds go with it.
	var second: HoundGateFx = FxTimeline.cast(load("res://src/fx/control/hound_gate.gd"), ctx, at)
	_run(second, HoundGateFx.T_OPEN + HoundGateFx.HOUNDS * HoundGateFx.OUT_EVERY + 1.0)
	var pack := second.visitors.living()
	second.end_now()
	gone = pack.size() == HoundGateFx.HOUNDS
	for a in pack:
		gone = gone and not is_instance_valid(a)
	t.check(gone and second.visitors.living().is_empty(), "ended early, every hound is freed")
	second.free()

	# --- A passage carries the door: it opens where the click comes out.
	var shift := Shift.new()
	field.portals.append(shift)
	var third: HoundGateFx = FxTimeline.cast(load("res://src/fx/control/hound_gate.gd"), ctx, at)
	t.check(third.mouth == at + Vector2(0, 6), "an open passage moves the door to where the click comes out")
	field.portals.erase(shift)
	third.end_now()
	third.free()
	_freed_quarry(t, made, at)
	_exit(t, made, at)
	_done(made)


## Stand `p` calm at `at`, with nothing to walk to.
static func _stand(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p.mind = Person.Mind.CALM
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._target = at


## Quarry's marked one freed mid-hunt (they left the town: Crowd.escape, or another power took them "gone"): the dead
## mark is dropped without an error, its ring goes, the hounds hunt on, and a new mark still takes. A hound freed by
## something else leaves its trail behind without an error.
static func _freed_quarry(t, made: Array, at: Vector2) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var fx: HoundGateFx = FxTimeline.cast(load("res://src/fx/control/hound_gate.gd"), ctx, at, {"level": 5})
	_run(fx, HoundGateFx.T_OPEN + float(fx.lv_hounds) * HoundGateFx.OUT_EVERY + 0.05)
	var gone: Person = crowd.citizens[4]
	var next: Person = crowd.citizens[5]
	_stand(gone, grid.nearest_walkable(at + Vector2(12.0, 0.0)))
	_stand(next, grid.nearest_walkable(at + Vector2(-12.0, 0.0)))
	t.check(fx.follow_up(gone.ground_pos, {}) and fx.quarry == gone and fx.visitors.marked() == gone, "(marked)")
	var ring := HoundGateFx.QuarryMark.new()
	ring.fx = fx
	ring.prey = gone
	crowd.citizens.erase(gone)
	field.remove(gone)
	gone.free()
	_run(fx, 0.5)
	ring._process(DT)
	t.check(fx.visitors.marked() == null and ring.is_queued_for_deletion()
		and fx.visitors.living().size() == fx.lv_hounds,
		"a marked one freed mid-hunt: the mark is dropped without an error, its ring goes, the hounds hunt on")
	t.check(fx.follow_up(next.ground_pos, {}) and fx.quarry == next and fx.visitors.marked() == next, "and a new mark still takes")
	var lost: Animal = fx.visitors.living()[0]
	fx._trails[lost] = null
	fx.visitors.take(lost)
	if is_instance_valid(lost):
		lost.free()
	fx._stop_trail(lost)
	t.check(not fx._trails.has(lost), "a hound freed by something else: its trail is let go without an error")
	fx.end_now()
	fx.free()
	ring.free()


## Freed without _finish (Battlefield.clear_effects() on a restart queue_frees it): the hounds are gone and the pack leaves
## the town, Quarry's mark with it, with no error; its end after that changes nothing.
static func _exit(t, made: Array, at: Vector2) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var fx: HoundGateFx = FxTimeline.cast(load("res://src/fx/control/hound_gate.gd"), ctx, at, {"level": 5})
	_run(fx, HoundGateFx.T_OPEN + float(fx.lv_hounds) * HoundGateFx.OUT_EVERY + 0.05)
	var prey: Person = crowd.citizens[6]
	_stand(prey, grid.nearest_walkable(at + Vector2(12.0, 0.0)))
	t.check(fx.follow_up(prey.ground_pos, {}), "(a quarry marked)")
	var pack := fx.visitors
	var up := pack.living()
	t.check(up.size() == fx.lv_hounds and crowd.visitors.has(pack), "(the hounds up: %d)" % up.size())
	fx._exit_tree()
	var gone := true
	for a in up:
		gone = gone and (not is_instance_valid(a) or a.is_queued_for_deletion())
	t.check(gone and pack.living().is_empty() and not crowd.visitors.has(pack) and pack.marked() == null and fx.quarry == null,
		"freed without its end, the hounds are gone, the pack leaves the town and the mark goes")
	fx.end_now()
	t.check(fx.finished and prey.is_alive(), "and its end after that changes nothing")
	fx.free()
