extends RefCounted
## Grave Tide (Death, Tier V; spec 5.8): a click, once a descent. Every unused body in town -- the oldest first, MOST at
## most -- gets up at once as a zombie for LIFE and walks toward the click, then hunts. Where the most bodies lie close
## (CLUSTER_MIN within CLUSTER_R of a point; a deterministic sweep, no luck) a giant of bones bursts up at their middle: it
## takes GIANT_BLOWS blows, claws down the walls in its way, kills a soldier with a blow, and Death's undead within
## GIANT_AURA of it move AURA_SPEED times as fast. No body anywhere in town: the cast is refused "no_dead", nothing spent.
## The frame-rate check: thirty zombies and the giant cost under 5 ms a frame.

const RD := preload("res://tests/test_raise_dead.gd")
const DT := 0.05
## The perf check's frames and its ceiling (ms a frame, averaged).
const PERF_FRAMES := 200
const PERF_MS := 5.0


static func _cast(made: Array, at: Vector2) -> GraveTideFx:
	return FxTimeline.cast(GraveTideFx, made[5], at) as GraveTideFx


static func run(t) -> void:
	var made := RD._setup()
	_book(t)
	_sweep(t)
	_refused(t, made)
	_few(t, made)
	_four(t, made)
	_giant(t, made)
	_cap(t, made)
	_march(t, made)
	_aura(t, made)
	_soldier(t, made)
	_wall(t, made)
	_life(t, made)
	_exit(t, made)
	RD._done(made)
	_perf(t)


## The citizens still alive and out in the open, in the crowd's order.
static func _alive(made: Array) -> Array:
	return (made[0] as Crowd).citizens.filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive() and not q.inside)


## One body at each of `spots`, in that order, each a moment after the last (so the oldest is the first): the remains.
static func _bodies(made: Array, spots: Array) -> Array:
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var alive := _alive(made)
	var out := []
	for i in spots.size():
		var p: Person = alive[alive.size() - 1 - i]  # from the back: the front of the list stays for the tests' living
		p.ground_pos = spots[i]
		field.kill(p, &"mob")
		crowd.remains.step(0.01)
		out.append(crowd.remains.pick(spots[i]))
	return out


## `n` walkable spots on a ring of `r` round `at` (the first at angle 0).
static func _ring(made: Array, at: Vector2, n: int, r: float) -> Array:
	var grid: WalkGrid = made[2]
	var out := []
	for i in n:
		var p := at + Vector2.from_angle(TAU * float(i) / float(n)) * r
		out.append(p if grid.walkable(p) else grid.nearest_walkable(p, 4))
	return out


static func _zombies(fx: GraveTideFx) -> Array:
	return fx.visitors.living().filter(func(a: Animal) -> bool: return a.breed == Animal.Breed.ZOMBIE)


## The row, its tables, its icons, clip and cues, the brief's numbers.
static func _book(t) -> void:
	var b := PowerBook.get_power("gravetide")
	t.check(not b.is_empty() and int(b.dp) == 6 and float(b.cooldown) == 999.0 and String(b.aim) == "click"
		and String(b.get("needs", "")) == "any_body" and PowerBook.authority_of("gravetide") == "death"
		and not PowerBook.is_quiet("gravetide") and String(b.get("path", "")) == "res://src/fx/death/grave_tide.gd",
		"Grave Tide: Death's 6 DP, once a descent, a click, needs a body anywhere in town, loud (%s)" % [b])
	var area: Dictionary = Targeting.AREAS.get("gravetide", {})
	t.check(PowerBook.REACH.has("gravetide") and is_equal_approx(PowerBook.impact("gravetide"), GraveTideFx.T_RISE)
		and PowerBook.family("gravetide") == "death" and Rules.POWER_KINDS.get("gravetide", []) == [&"frenzy"]
		and area.get("shape", "") == "circle" and is_equal_approx(float(area.get("r", 0.0)), GraveTideFx.GIANT_AURA)
		and Targeting.AREA_STATS.get("gravetide", {}) == {"r": "GIANT_AURA"},
		"its reach, impact (the dead stand), family, kills (frenzy) and area (the giant's aura)")
	t.check(PowerBook.icon("gravetide") != null and PowerBook.hud_icon("gravetide") != null and PowerBook.clip("gravetide") != null,
		"it has its icons and its clip")
	t.check(GraveTideFx.MOST == 30 and GraveTideFx.LIFE == 40.0 and GraveTideFx.CLUSTER_R == 4.0 and GraveTideFx.CLUSTER_MIN == 5
		and GraveTideFx.GIANT_BLOWS == 12 and GraveTideFx.GIANT_AURA == 6.0 and GraveTideFx.AURA_SPEED == 1.2,
		"the numbers of the brief")
	t.check(Sfx.CATALOG.has(&"gravetide_rise") and Sfx.CATALOG.has(&"giant_step"), "its cues (bone grinding) are catalogued")
	t.check(Remains.wants(["smite", "gravetide"]), "a loadout with Grave Tide keeps the town's bodies (Remains.wants)")
	t.check(Animal.sheet(Animal.Breed.BONE_GIANT).size() > 0 or not ResourceLoader.exists(Animal.SHEETS[Animal.Breed.BONE_GIANT]),
		"the bone giant wears its painted sheet")


## The cluster sweep: the biggest group within CLUSTER_R of one of the points, a tie to the earlier point; its members.
static func _sweep(t) -> void:
	var none: Array[Vector2] = []
	t.check(GraveTideFx.cluster(none).is_empty(), "no points: no group")
	var pts: Array[Vector2] = [Vector2(0, 0), Vector2(20, 0), Vector2(1, 0), Vector2(21, 0), Vector2(22, 0), Vector2(0, 1), Vector2(20, 1)]
	t.check(GraveTideFx.cluster(pts) == [1, 3, 4, 6], "the biggest group wins (%s)" % [GraveTideFx.cluster(pts)])
	var tie: Array[Vector2] = [Vector2(0, 0), Vector2(1, 0), Vector2(20, 0), Vector2(21, 0)]
	t.check(GraveTideFx.cluster(tie) == [0, 1], "a tie goes to the earlier (older) point (%s)" % [GraveTideFx.cluster(tie)])
	var far: Array[Vector2] = [Vector2(0, 0), Vector2(4.0, 0), Vector2(4.01 + 4.0, 0)]
	t.check(GraveTideFx.cluster(far).size() == 2, "within CLUSTER_R counts, past it does not (%s)" % [GraveTideFx.cluster(far)])


## "0 remains in town: refused no_dead" -- the cooldown untouched, nothing cast. A body anywhere in town (far from the click)
## lets it cast; then it waits out the longest night (once a descent), and a second cast is refused "cooldown".
static func _refused(t, made: Array) -> void:
	RD._clear_all(made)
	var rules := Rules.new().setup(PackedStringArray(["gravetide"]), null, made[1], made[3], made[0], made[6])
	var casts := []
	rules.caster = func(s: GDScript, g: Vector2, e: Dictionary) -> FxTimeline:
		var fx := FxTimeline.cast(s, made[5], g, e)
		casts.append(fx)
		return fx
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, why: String) -> void: refused.append([slot, why]))
	var at := RD._empty(made)
	var got := rules.cast(0, at)
	t.check(got == null and refused == [[0, "no_dead"]] and rules.cooldown_left(0) == 0.0 and casts.is_empty(),
		"0 remains in town: refused no_dead, the cooldown untouched (%s, %.1f)" % [refused, rules.cooldown_left(0)])
	refused.clear()
	var far := RD._empty(made, at)
	_bodies(made, [far])
	got = rules.cast(0, at)
	t.check(got != null and refused.is_empty() and rules.cooldown_left(0) > TierBook.clock(5),
		"one body anywhere in town (%.0f off the click): it casts, and waits out the longest night (%.0f s)" % [far.distance_to(at), rules.cooldown_left(0)])
	if got != null:
		got.end_now()
	rules.cast(0, at)
	t.check(casts.size() == 1 and refused == [[0, "cooldown"]], "a second cast is refused (%s)" % [refused])
	rules.free()


## No crash with 0 or 1 remains: none raises nothing, one raises one, never a giant.
static func _few(t, made: Array) -> void:
	RD._clear_all(made)
	var at := RD._empty(made)
	var fx := _cast(made, at)
	RD._run(fx, GraveTideFx.T_RISE + 0.2)
	t.check(fx.raised == 0 and fx.giant == null and fx.visitors.living().is_empty(), "0 remains (a scripted cast): nothing rises, no error")
	fx.end_now()
	_bodies(made, [at + Vector2(2.0, 0.0)])
	fx = _cast(made, at)
	RD._run(fx, GraveTideFx.T_RISE + 0.2)
	t.check(fx.raised == 1 and fx.giant == null and _zombies(fx).size() == 1, "1 remain: 1 zombie, no giant")
	fx.end_now()


## "4 remains: 4 zombies, no giant": four lying close together are not enough; each rises in its own look, and every
## body is used up.
static func _four(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var spots := _ring(made, at + Vector2(3.0, 0.0), 4, 1.0)
	var rems := _bodies(made, spots)
	var designs := {}
	for r in rems:
		designs[(r as Remains.Remain).design] = true
	var fx := _cast(made, at)
	t.check(crowd.remains.all().size() == 4, "before T_RISE the bodies still lie there")
	RD._run(fx, GraveTideFx.T_RISE + 0.1)
	var zs := _zombies(fx)
	var worn := true
	for a in zs:
		worn = worn and designs.has((a as Animal).worn)
	t.check(zs.size() == 4 and fx.raised == 4 and fx.giant == null and fx.visitors.living().size() == 4 and worn,
		"4 remains: 4 zombies, each in its own look, no giant (%d up)" % fx.visitors.living().size())
	t.check(crowd.remains.all().is_empty(), "every body is used up (taken off the ledger)")
	fx.end_now()


## "5 within 4: a giant at their centre" -- the biggest cluster wins (six here, five elsewhere); its middle is the mean of
## its bodies. Every body still rises as a zombie as well. The giant takes GIANT_BLOWS blows and claws at walls.
static func _giant(t, made: Array) -> void:
	RD._clear_all(made)
	var at := RD._empty(made)
	var big := _ring(made, at + Vector2(-3.0, 0.0), 6, 1.5)
	var small := _ring(made, at + Vector2(6.0, 0.0), 5, 1.5)
	_bodies(made, small + big)  # the smaller group is the older: the biggest still wins
	var mid := Vector2.ZERO
	for p in big:
		mid += p
	mid /= float(big.size())
	var fx := _cast(made, at)
	RD._run(fx, GraveTideFx.T_RISE - 0.1)
	t.check(fx.giant == null, "nothing stands before T_RISE")
	RD._run(fx, 0.15)
	var g := fx.giant
	t.check(g != null and is_instance_valid(g) and g.breed == Animal.Breed.BONE_GIANT and fx.giant_at.distance_to(mid) < 0.5
		and is_equal_approx(g.health, float(GraveTideFx.GIANT_BLOWS)),
		"5 within 4: a giant at their centre, the biggest group's (%s vs %s), %d blows" % [fx.giant_at, mid, int(g.health) if g != null else 0])
	var rule: Visitors.Rule = fx.visitors._rules.get(g) if g != null else null
	t.check(rule != null and rule.wreck > 0.0 and rule.bite >= Person.HEALTH_SOLDIER and not rule.flinch,
		"it claws at walls (wreck), its blow fells a soldier, and it does not flinch")
	t.check(_zombies(fx).size() == 11 and fx.raised == 11, "and all eleven bodies rise as zombies (%d)" % _zombies(fx).size())
	fx.end_now()
	# Four within 4 and one just past it: no giant.
	RD._clear_all(made)
	var spots := _ring(made, at, 4, 1.0)
	spots.append(at + Vector2(9.5, 0.0))
	_bodies(made, spots)
	fx = _cast(made, at)
	RD._run(fx, GraveTideFx.T_RISE + 0.1)
	t.check(fx.giant == null and fx.raised == 5, "four close and a fifth far off: five zombies, no giant")
	fx.end_now()


## "30 cap: 40 remains raise 30, oldest first": the ten youngest still lie there.
static func _cap(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var spots := []
	for i in 40:
		spots.append((made[2] as WalkGrid).nearest_walkable(at + Vector2(-4.0 + float(i % 8) * 1.0, -2.0 + float(i / 8) * 1.0), 4))
	var rems := _bodies(made, spots)
	t.check(crowd.remains.all().size() == 40, "40 bodies lie in town")
	var fx := _cast(made, at)
	RD._run(fx, GraveTideFx.T_RISE + 0.1)
	var left := crowd.remains.all()
	var youngest := rems.slice(30)
	var same := left.size() == 10
	for r in youngest:
		same = same and left.has(r)
	t.check(fx.raised == 30 and _zombies(fx).size() == 30 and same,
		"30 cap: 40 remains raise 30, oldest first; the ten youngest still lie there (%d raised, %d left)" % [fx.raised, left.size()])
	fx.end_now()


## The zombies walk toward the click first -- past someone behind them they would otherwise hunt -- then hunt.
static func _march(t, made: Array) -> void:
	RD._clear_all(made)
	var grid: WalkGrid = made[2]
	var at := RD._empty(made)
	var to := at + Vector2(2.5, 0.0)
	var from := at + Vector2(-2.5, 0.0)
	t.check(grid.clear_line(from, to), "an open street from the bodies to the click")
	_bodies(made, _ring(made, from, 3, 0.5))
	var behind := _put(made, 0, from + Vector2(-7.0, 0.0))
	var fx := _cast(made, to)
	RD._run(fx, GraveTideFx.T_RISE + 0.1)
	var start := 0.0
	for a in _zombies(fx):
		start += (a as Animal).ground_pos.distance_to(to)
	RD._run(fx, 2.0)
	var now := 0.0
	var hunting := 0
	for a in _zombies(fx):
		now += (a as Animal).ground_pos.distance_to(to)
		hunting += 1 if (a as Animal).target == behind else 0
	t.check(now < start - 1.0 and hunting == 0 and behind.is_alive(),
		"they walk toward the click (%.1f -> %.1f summed), not at one 7 behind them (within a zombie's 10)" % [start, now])
	RD._run(fx, 11.0)
	var there := true
	for a in _zombies(fx):
		there = there and (a as Animal).ground_pos.distance_to(to) <= Visitors.MARCH_NEAR + 0.3
	for a in _zombies(fx):
		there = there and (fx.visitors._rules[a] as Visitors.Rule).march == Vector2.INF
	var prey := _put(made, 1, to + Vector2(0.0, 4.0))
	RD._run(fx, Visitors.RETARGET + 0.1)
	var on_prey := 0
	for a in _zombies(fx):
		on_prey += 1 if (a as Animal).target == prey else 0
	t.check(there and on_prey == 3, "at the click they hunt: all three go for one 4 off (%d)" % on_prey)
	fx.end_now()


static func _put(made: Array, n: int, at: Vector2) -> Person:
	var p: Person = _alive(made)[n]
	p.ground_pos = at
	p.mind = Person.Mind.CALM
	return p


## "aura speeds undead near the giant": AURA_SPEED times their pace within GIANT_AURA, their own pace back outside it.
static func _aura(t, made: Array) -> void:
	RD._clear_all(made)
	var at := RD._empty(made)
	_bodies(made, _ring(made, at, 5, 1.5))
	var fx := _cast(made, at)
	RD._run(fx, GraveTideFx.T_RISE + 0.1)
	var zs := _zombies(fx)
	var base := DeathParts.ZOMBIE_PACE * DummyEnemy.WALK_SPEED / (Animal.DOG_SPEED * Animal.RUN)
	var fast := zs.size() == 5
	for a in zs:
		fast = fast and is_equal_approx((a as Animal).speed_mul, base * GraveTideFx.AURA_SPEED)
	var g_base := fx.giant.speed_mul if fx.giant != null else 0.0
	t.check(fast and fx.giant != null and is_equal_approx(g_base, GraveTideFx.GIANT_PACE / (Animal.DOG_SPEED * Animal.RUN)),
		"aura speeds undead near the giant: x%.1f within %.0f (the giant itself at its own pace)" % [GraveTideFx.AURA_SPEED, GraveTideFx.GIANT_AURA])
	var out: Animal = zs[0]
	out.ground_pos = fx.giant.ground_pos + Vector2(GraveTideFx.GIANT_AURA + 3.0, 0.0)
	RD._run(fx, 0.3)
	t.check(is_equal_approx(out.speed_mul, base) and is_equal_approx((zs[1] as Animal).speed_mul, base * GraveTideFx.AURA_SPEED),
		"one that leaves the aura has its own pace back; the rest keep the speed (%.3f, %.3f)" % [out.speed_mul, (zs[1] as Animal).speed_mul])
	out.ground_pos = fx.giant.ground_pos + Vector2(1.0, 0.0)
	RD._run(fx, 0.3)
	t.check(is_equal_approx(out.speed_mul, base * GraveTideFx.AURA_SPEED), "and it is sped again as it comes back")
	fx.end_now()


## The giant's blow kills a soldier outright (a zombie's only wounds one).
static func _soldier(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	_bodies(made, _ring(made, at, 5, 2.0))
	var fx := _cast(made, at)
	var bites := []
	fx.visitors.bitten.connect(func(a: Animal, v: Person, _first: bool) -> void:
		bites.append([a.breed, is_instance_valid(v) and v.is_alive()]))
	RD._run(fx, GraveTideFx.T_RISE + 0.05)
	t.check(fx.giant != null, "(five within 2 of the middle: a giant)")
	if fx.giant == null:
		fx.end_now()
		return
	var soldier: Person = null
	for s in crowd.soldiers:
		if is_instance_valid(s) and s.is_alive() and s.corps != Person.Corps.KNIGHT:
			soldier = s
			break
	soldier.inside = false
	soldier.ground_pos = fx.giant.ground_pos + Vector2(0.0, 0.5)
	soldier.health = Person.HEALTH_SOLDIER
	soldier.mind = Person.Mind.CALM
	RD._run(fx, Visitors.RETARGET + 0.3)
	t.check(not bites.is_empty() and bites[0][0] == Animal.Breed.BONE_GIANT and not bites[0][1] and not soldier.is_alive(),
		"the giant's blow kills a soldier outright (%s)" % [bites])
	fx.end_now()


## "the giant wrecks a wall in its way": walking round a house to a click on its far side, it claws down what it passes --
## on its march, not at a building it went looking for -- and walks on.
static func _wall(t, made: Array) -> void:
	RD._clear_all(made)
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var house := RD._house(env, grid)
	t.check(house != null, "a house with open ground east of it")
	var east := Vector2(house.footprint.end.x + 2.0, house.center().y)
	var west := grid.nearest_walkable(Vector2(house.footprint.position.x - 2.0, house.center().y), 4)
	var before := {}
	for s in env.near(house.center(), 10.0):
		before[s] = s.hp
	_bodies(made, _ring(made, east, 5, 0.8))
	var fx := _cast(made, west)
	var struck := {}
	var on_march := [0]  # (a lambda captures an int by value)
	fx.visitors.wrecked.connect(func(a: Animal, s: Structure) -> void:
		struck[s] = true
		if a == fx.giant and (fx.visitors._rules[a] as Visitors.Rule).march != Vector2.INF:
			on_march[0] += 1)
	RD._run(fx, GraveTideFx.T_RISE + 0.05)
	var start := fx.giant.ground_pos.distance_to(west) if fx.giant != null else 0.0
	RD._run(fx, 12.0)
	var lost := 0.0
	for s in struck:
		lost += float(before.get(s, (s as Structure).max_hp)) - (0.0 if (s as Structure).destroyed else (s as Structure).hp)
	print("GRAVETIDE wall: %d blows (%d on its march), %.0f hp off %d buildings" % [fx.wrecks, on_march[0], lost, struck.size()])
	t.check(fx.giant != null and fx.wrecks >= 1 and on_march[0] >= 1 and lost >= GraveTideFx.GIANT_WRECK - 0.01
		and fx.giant.ground_pos.distance_to(west) < start - 1.0,
		"the giant wrecks a wall in its way: %d blows on its march, %.0f hp off %d buildings, and it walks on (%.1f -> %.1f to the click)"
		% [on_march[0], lost, struck.size(), start, fx.giant.ground_pos.distance_to(west) if fx.giant != null else -1.0])
	fx.end_now()
	for s in before:
		if not (s as Structure).destroyed:
			(s as Structure).hp = before[s]


## At LIFE every one of them falls to ash, and the effect ends.
static func _life(t, made: Array) -> void:
	RD._clear_all(made)
	var at := RD._empty(made)
	_bodies(made, _ring(made, at, 5, 1.5))
	var fx := _cast(made, at)
	RD._run(fx, GraveTideFx.LIFE - 0.2)
	t.check(fx.visitors.living().size() == 6, "up to the end, all six stand (%d)" % fx.visitors.living().size())
	RD._run(fx, 0.4)
	t.check(fx.visitors.living().is_empty() and fx.giant == null, "at LIFE every one falls to ash")
	RD._run(fx, GraveTideFx.FADE + 0.2)
	t.check(fx.finished, "and the tide is over")


## Freed without its end (a mission torn down): the pack is cleared, nothing errors.
static func _exit(t, made: Array) -> void:
	RD._clear_all(made)
	var at := RD._empty(made)
	_bodies(made, _ring(made, at, 5, 1.5))
	var fx := _cast(made, at)
	RD._run(fx, GraveTideFx.T_RISE + 0.5)
	var pack := fx.visitors
	var up := pack.living()
	t.check(up.size() == 6, "six up")
	fx._exit_tree()
	var gone := true
	for a in up:
		gone = gone and (not is_instance_valid(a) or a.is_queued_for_deletion())
	t.check(gone and pack.living().is_empty() and not (made[0] as Crowd).visitors.has(pack) and fx.giant == null,
		"freed without its end, the pack is cleared and leaves the town")
	fx.end_now()
	t.check(fx.finished, "and its end after that changes nothing")


## "30 zombies + giant: _fx_process + visitors.step under 5 ms a frame averaged over 200 frames", in the full town (220
## people where the day put them), the thirty bodies lying round the market.
static func _perf(t) -> void:
	var made := RD._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var spots := []
	for i in 30:
		spots.append(grid.nearest_walkable(at + Vector2.from_angle(TAU * float(i) / 30.0) * (1.5 + float(i % 3) * 1.5), 4))
	_bodies(made, spots)
	var fx := _cast(made, at)
	RD._run(fx, GraveTideFx.T_RISE + 0.05)
	var frame := 1.0 / 60.0
	var t0 := Time.get_ticks_usec()
	for i in PERF_FRAMES:
		fx._process(frame)
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0 / float(PERF_FRAMES)
	print("GRAVETIDE perf: %.3f ms a frame over %d frames (%d up, %d alive in town)" % [ms, PERF_FRAMES, fx.visitors.living().size(),
		(crowd.citizens + crowd.soldiers).filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive()).size()])
	t.check(fx.giant != null and _zombies(fx).size() >= 25 and ms < PERF_MS,
		"30 zombies + giant: _fx_process + visitors.step under 5 ms a frame averaged over 200 frames (%.3f ms)" % ms)
	fx.end_now()
	RD._done(made)
