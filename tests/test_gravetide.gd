extends RefCounted
## Grave Tide (Death, Tier V; spec 5.8): a click, once a descent. Every unused body in town -- the oldest first, MOST at
## most -- gets up at once as a zombie for LIFE and walks toward the click, then hunts. Where the most bodies lie close
## (CLUSTER_MIN within CLUSTER_R of a point; a deterministic sweep, no luck) a giant of bones bursts up at their middle: it
## takes GIANT_BLOWS blows, claws down the walls in its way, kills a soldier with a blow, and Death's undead within
## GIANT_AURA of it move AURA_SPEED times as fast. No body anywhere in town: the cast is refused "no_dead", nothing spent.
## Ruling R12: its BONES bones fly in one by one over ASSEMBLE; it lands with a slam and slams the ground every SLAM_EVERY
## while it stands (soldiers within SLAM_R die, the rest are knocked back and frightened); it stands GIANT_LIFE, the zombies
## LIFE. The frame-rate check: thirty zombies, the giant and its slams cost under 5 ms a frame.

const RD := preload("res://tests/test_raise_dead.gd")
const FxStage := preload("res://tests/fx_stage.gd")
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
	_aura_others(t, made)
	_soldier(t, made)
	_wall(t, made)
	_holds(t, made)
	_freed_clear(t, made)
	_assemble(t, made)
	_landing(t, made)
	_slam_every(t, made)
	_no_slam_fallen(t, made)
	_cut_short(t, made)
	_life(t, made)
	_exit(t, made)
	await _staged(t, made)
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
	t.check(GraveTideFx.GIANT_LIFE == 60.0 and GraveTideFx.ASSEMBLE == 1.2 and GraveTideFx.BONES == 18 and GraveTideFx.SLAM_EVERY == 4.0
		and GraveTideFx.SLAM_R == 3.0 and GraveTideFx.SLAM_KNOCK == 5.5, "the slam's numbers (ruling R12)")
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
	RD._run(fx, GraveTideFx.ASSEMBLE + 0.15)
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
	RD._run(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + 0.2)
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


## Review IMPORTANT 1 (spec 5.8, "Death's undead within 6 of the giant move 20% faster"): another power's zombie -- Raise the
## Dead's -- standing by the giant is quickened too, and has its pace back as it leaves or as the giant goes (carried off by
## another power: its node freed with no cut_down); a hellhound of another pack beside it never is.
static func _aura_others(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	_bodies(made, _ring(made, at, 5, 1.5))
	var fx := _cast(made, at)
	var beside := at + Vector2(0.0, 3.0)
	_bodies(made, [beside])  # after the tide's pick: Raise's body, not the tide's
	var raise := FxTimeline.cast(RaiseTheDeadFx, made[5], beside, {"mode": "zombie"}) as RaiseTheDeadFx
	var hounds := Visitors.new().setup(made[3], crowd, made[2], made[4])
	var hound := hounds.summon(at + Vector2(-2.0, 0.0), Animal.Breed.HELLHOUND, 4, 1.0, 0.0, 0.5, 1.0, false)
	var both := func(seconds: float) -> void:
		for i in roundi(seconds / DT):
			if not fx.finished:
				fx._process(DT)
			if not raise.finished:
				raise._process(DT)
	both.call(GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + 0.2)
	var z: Animal = raise.visitors.living()[0] if raise.visitors.living().size() == 1 else null
	t.check(z != null and fx.giant != null and z.ground_pos.distance_to(fx.giant.ground_pos) <= GraveTideFx.GIANT_AURA,
		"(a Raise the Dead zombie stands by the giant)")
	if z == null or fx.giant == null:
		fx.end_now()
		raise.end_now()
		hounds.clear()
		return
	var own := DeathParts.ZOMBIE_PACE * DummyEnemy.WALK_SPEED / (Animal.DOG_SPEED * Animal.RUN)
	t.check(is_equal_approx(z.speed_mul, own * GraveTideFx.AURA_SPEED) and is_equal_approx(hound.speed_mul, 1.0),
		"another power's zombie by the giant is quickened x%.1f (%.3f); a hellhound beside it is not (%.2f)" % [GraveTideFx.AURA_SPEED, z.speed_mul, hound.speed_mul])
	z.ground_pos = fx.giant.ground_pos + Vector2(GraveTideFx.GIANT_AURA + 3.0, 0.0)
	both.call(0.3)
	t.check(is_equal_approx(z.speed_mul, own), "it has its own pace back as it leaves the aura (%.3f)" % z.speed_mul)
	z.ground_pos = fx.giant.ground_pos + Vector2(1.0, 0.0)
	both.call(0.3)
	var again := is_equal_approx(z.speed_mul, own * GraveTideFx.AURA_SPEED)
	var mine: Animal = _zombies(fx)[0]
	fx.visitors.take(fx.giant)  # another power carries the giant off: freed, no cut_down
	both.call(0.3)
	t.check(again and is_equal_approx(z.speed_mul, own) and is_equal_approx(mine.speed_mul, own) and fx.giant == null,
		"quickened again as it comes back; the giant gone, every one has its own pace back (%.3f, %.3f)" % [z.speed_mul, mine.speed_mul])
	fx.end_now()
	raise.end_now()
	hounds.clear()


## Review IMPORTANT 2 ("it walks the streets ... smashes walls in its way"): with no soldier out in the open anywhere, the
## giant holds at the click, between houses within its reach (one 2 off, a small one beside it), and claws none of them:
## it never leaves the street for a building, nor strikes one it stands idle by.
static func _holds(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var house := RD._house(env, grid)
	var at := Vector2(house.footprint.end.x + 2.0, house.center().y)
	var was := {}
	for s in crowd.soldiers:
		if is_instance_valid(s):
			was[s] = s.inside
			s.inside = true  # every soldier indoors: none to go after
	var hp := house.hp
	_bodies(made, _ring(made, at, 5, 1.5))
	var fx := _cast(made, at)
	RD._run(fx, GraveTideFx.T_RISE + 8.0)
	var g := fx.giant
	t.check(g != null and house.distance_to(at) <= GraveTideFx.GIANT_SEEK and house.hp == hp and fx.wrecks == 0
		and g.ground_pos.distance_to(at) <= Visitors.MARCH_NEAR + 0.5,
		"no soldier near: the giant holds at the click and does not leave the street for the house %.1f off (%d blows, %.1f from the click)"
		% [house.distance_to(at), fx.wrecks, g.ground_pos.distance_to(at) if g != null else -1.0])
	var demon := Visitors.new().setup(made[3], crowd, grid, made[4])
	var d := demon.summon(at, Animal.Breed.DEMON, 8, 1.0, 8.0, 0.6, 1.2, false)
	demon.give(d, {"wreck": DoorsOfTheDeadFx.DEMON_WRECK})
	t.check((demon._rules[d] as Visitors.Rule).wreck_idle and not (fx.visitors._rules[g] as Visitors.Rule).wreck_idle,
		"a demon still goes at buildings with nobody near (wreck_idle by default); the giant does not")
	demon.clear()
	fx.end_now()
	house.hp = hp
	for s in was:
		if is_instance_valid(s):
			s.inside = was[s]


## Review minor (a): a visitor whose node another power freed is still in its pack; clear() frees the rest without an error.
static func _freed_clear(t, made: Array) -> void:
	var v := Visitors.new().setup(made[3], made[0], made[2], made[4])
	var at := RD._empty(made)
	var gone := v.summon(at, Animal.Breed.ZOMBIE, 3, 1.0, 0.0, 0.5, 1.0, true)
	var kept := v.summon(at + Vector2(1.0, 0.0), Animal.Breed.ZOMBIE, 3, 1.0, 0.0, 0.5, 1.0, true)
	gone.free()
	v.clear()
	t.check(v._rules.is_empty() and not is_instance_valid(kept) and not (made[0] as Crowd).visitors.has(v),
		"a freed visitor's pack clears without an error, the rest freed")


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
	RD._run(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + 0.05)
	t.check(fx.giant != null, "(five within 2 of the middle: a giant)")
	if fx.giant == null:
		fx.end_now()
		return
	var soldier: Person = null
	for s in crowd.soldiers:
		if is_instance_valid(s) and s.is_alive() and s.corps != Person.Corps.KNIGHT:
			soldier = s
			break
	t.check(soldier != null, "(a soldier left to stand by the giant)")
	if soldier == null:
		fx.end_now()
		return
	for z in _zombies(fx):
		fx.visitors.take(z)  # the giant's own blow, not a zombie's bite first: only the giant stands by him
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
	RD._run(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + 0.05)
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


## Every soldier indoors (none for the giant to go after, none for a guard to strike it); the old `inside` of each.
static func _soldiers_in(made: Array) -> Dictionary:
	var was := {}
	for s in (made[0] as Crowd).soldiers:
		if is_instance_valid(s):
			was[s] = s.inside
			s.inside = true
	return was


static func _soldiers_back(was: Dictionary) -> void:
	for s in was:
		if is_instance_valid(s):
			s.inside = was[s]


## Ruling R12: "bones fly in one by one, then the giant stands" -- halfway through ASSEMBLE no giant yet and some, not all,
## of the BONES in; at T_RISE + ASSEMBLE the giant stands with every bone in. Counted on the effect clock, staged or not.
static func _assemble(t, made: Array) -> void:
	RD._clear_all(made)
	var at := RD._empty(made)
	_bodies(made, _ring(made, at, 5, 1.5))
	var fx := _cast(made, at)
	RD._run(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE * 0.5)
	t.check(fx.giant == null and fx.bones_in > 0 and fx.bones_in < GraveTideFx.BONES and fx.landed_at < 0.0,
		"bones fly in one by one: halfway through, no giant and %d of %d bones in" % [fx.bones_in, GraveTideFx.BONES])
	RD._run(fx, GraveTideFx.ASSEMBLE * 0.5 + 0.05)
	t.check(fx.giant != null and fx.bones_in == GraveTideFx.BONES and fx.landed_at >= GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE - 0.001,
		"then the giant stands, every bone in (%d), landed at %.2f" % [fx.bones_in, fx.landed_at])
	fx.end_now()


## "the landing slams": the landing is the first slam. A soldier 2 off dies (frenzy: a body lies there); a citizen 2 off
## lives, is frightened and is thrown back.
static func _landing(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	_bodies(made, _ring(made, at, 5, 1.0))
	var fx := _cast(made, at)
	RD._run(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE - 0.1)
	var spot := fx.giant_at
	var soldier: Person = null
	for s in crowd.soldiers:
		if is_instance_valid(s) and s.is_alive():
			soldier = s
			break
	var citizen := _put(made, 0, spot + Vector2(0.0, -2.0))
	t.check(soldier != null and fx.giant == null and fx.slams == 0, "(a soldier to stand by the giant's spot; nothing has landed yet)")
	if soldier == null:
		fx.end_now()
		return
	soldier.inside = false
	soldier.ground_pos = spot + Vector2(0.0, 2.0)
	soldier.health = Person.HEALTH_SOLDIER
	soldier.mind = Person.Mind.CALM
	var from := citizen.ground_pos.distance_to(spot)
	var dead_at := soldier.ground_pos
	var kinds := []
	var on_kill := func(e: DummyEnemy, kind: StringName) -> void:
		if e == soldier:
			kinds.append(kind)
	field.enemy_killed.connect(on_kill)
	RD._run(fx, 0.15)
	field.enemy_killed.disconnect(on_kill)
	t.check(fx.giant != null and fx.slams == 1, "the landing is the first slam (%d)" % fx.slams)
	crowd.remains.step(0.01)
	t.check(not soldier.is_alive() and kinds == [&"frenzy"] and crowd.remains.pick(dead_at) != null,
		"a soldier 2 off dies (%s), and his body lies there" % [kinds])
	var knocked := citizen.state == DummyEnemy.State.KNOCKBACK
	RD._run(fx, 0.5, [citizen])
	var away := citizen.ground_pos.distance_to(spot) - from
	t.check(citizen.is_alive() and knocked and (citizen.mind == Person.Mind.PANIC or citizen.mind == Person.Mind.FLEE) and away >= 0.3,
		"a citizen 2 off lives, knocked back (%s) and frightened (mind %d), thrown %.2f farther off" % [knocked, citizen.mind, away])
	fx.end_now()


## "a slam every 4 s": the landing's, then one at landed_at + 4 and + 8.
static func _slam_every(t, made: Array) -> void:
	RD._clear_all(made)
	var was := _soldiers_in(made)
	var at := RD._empty(made)
	_bodies(made, _ring(made, at, 5, 1.5))
	var fx := _cast(made, at)
	RD._run(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + 0.05)
	var first := fx.slams
	RD._run(fx, fx.landed_at + GraveTideFx.SLAM_EVERY - 0.1 - fx.t)
	var before := fx.slams
	RD._run(fx, fx.landed_at + 2.0 * GraveTideFx.SLAM_EVERY + 0.05 - fx.t)
	t.check(first == 1 and before == 1 and fx.slams == 3,
		"a slam every %.0f s: %d at the landing, %d just before the next, %d at landed_at + 8" % [GraveTideFx.SLAM_EVERY, first, before, fx.slams])
	fx.end_now()
	_soldiers_back(was)


## Review Focus 4: "no slam once the giant falls" -- cut down, it slams no more.
static func _no_slam_fallen(t, made: Array) -> void:
	RD._clear_all(made)
	var was := _soldiers_in(made)
	var at := RD._empty(made)
	_bodies(made, _ring(made, at, 5, 1.5))
	var fx := _cast(made, at)
	RD._run(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + 0.05)
	var g := fx.giant
	t.check(g != null, "(the giant stands)")
	if g == null:
		fx.end_now()
		_soldiers_back(was)
		return
	# Cut down as a guard's last blow does it: its health gone, the pack forgets it, cut_down heard.
	var where := g.ground_pos
	g.hurt(float(GraveTideFx.GIANT_BLOWS))
	fx.visitors._rules.erase(g)
	fx.visitors.cut_down.emit(g, where)
	var n := fx.slams
	RD._run(fx, GraveTideFx.SLAM_EVERY * 2.0 + 0.5)
	t.check(fx.giant == null and n == 1 and fx.slams == n, "no slam once the giant falls (%d -> %d)" % [n, fx.slams])
	fx.end_now()
	if is_instance_valid(g):
		g.free()
	_soldiers_back(was)


## "cut short mid-assembly: no giant ever".
static func _cut_short(t, made: Array) -> void:
	RD._clear_all(made)
	var at := RD._empty(made)
	_bodies(made, _ring(made, at, 5, 1.5))
	var fx := _cast(made, at)
	RD._run(fx, GraveTideFx.T_RISE + 0.5)
	fx._finish()
	for i in roundi(3.0 / DT):
		fx._process(DT)
	t.check(fx.giant == null and fx.slams == 0 and fx.finished, "cut short mid-assembly: no giant ever, no slam")


## "the giant outlives the horde": at LIFE the zombies fall to ash and the giant stands on; GIANT_LIFE after its landing
## it is gone too, and the tide is over.
static func _life(t, made: Array) -> void:
	RD._clear_all(made)
	var was := _soldiers_in(made)
	var at := RD._empty(made)
	_bodies(made, _ring(made, at, 5, 1.5))
	var fx := _cast(made, at)
	RD._run(fx, GraveTideFx.LIFE - 0.2)
	t.check(fx.visitors.living().size() == 6, "up to LIFE, all six stand (%d)" % fx.visitors.living().size())
	RD._run(fx, GraveTideFx.T_RISE + GraveTideFx.LIFE + 1.0 - fx.t)
	var g := fx.giant
	t.check(_zombies(fx).is_empty() and g != null and is_instance_valid(g) and g.is_alive() and fx.visitors.living() == [g]
		and not fx.finished,
		"the giant outlives the horde: at LIFE the zombies fall to ash (%d left), the giant stands" % _zombies(fx).size())
	RD._run(fx, fx.landed_at + GraveTideFx.GIANT_LIFE - 0.3 - fx.t)
	t.check(fx.giant != null and not fx.finished, "it stands to the end of its GIANT_LIFE")
	RD._run(fx, fx.landed_at + GraveTideFx.GIANT_LIFE + GraveTideFx.FADE + 0.2 - fx.t)
	t.check(fx.giant == null and fx.visitors.living().is_empty() and fx.finished,
		"GIANT_LIFE after its landing it is gone, and the tide is over")
	_soldiers_back(was)


## Freed without its end (a mission torn down): the pack is cleared, nothing errors.
static func _exit(t, made: Array) -> void:
	RD._clear_all(made)
	var at := RD._empty(made)
	_bodies(made, _ring(made, at, 5, 1.5))
	var fx := _cast(made, at)
	RD._run(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + 0.3)
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


## One cast for the staged check: a soldier 2 off the giant's spot as it lands, run to past the second slam. Counts the
## bones in mid-assembly, the slams, whether the soldier died, and (staged) the flying bones and slam marks drawn. Each
## `await` lets the tree draw a frame with the effect itself held still, so staged and headless run the same clock.
static func _slam_run(t, made: Array, staged: bool) -> Dictionary:
	RD._clear_all(made)
	var was := _soldiers_in(made)
	var ctx: FxContext = made[5]
	var at := RD._empty(made)
	_bodies(made, _ring(made, at, 5, 1.5))
	var fx := _cast(made, at)
	var out := {"bones": 0, "slams": 0, "dead": false, "drawn_bones": 0, "marks": 0}
	RD._run(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE * 0.5)
	out.bones = fx.bones_in
	if staged:
		fx.set_process(false)
		await t.process_frame
		fx.set_process(true)
		for n in fx.stand_layer().get_children():
			out.drawn_bones += 1 if n is GraveTideFx.Bones else 0
	RD._run(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE - 0.1 - fx.t)
	var soldier: Person = was.keys()[0] if not was.is_empty() else null
	if soldier != null:
		soldier.inside = false
		soldier.ground_pos = fx.giant_at + Vector2(2.0, 0.0)
		soldier.health = Person.HEALTH_SOLDIER
	RD._run(fx, GraveTideFx.SLAM_EVERY + 0.3)
	out.slams = fx.slams
	out.dead = soldier != null and not soldier.is_alive()
	if staged:
		fx.set_process(false)
		await t.process_frame
		fx.set_process(true)
		for n in ctx.ground.get_children():
			out.marks += 1 if n is GraveTideFx.SlamMark else 0
	fx.end_now()
	_soldiers_back(was)
	return out


## Staged (the effect in the tree with an Impact, as in the game): the bones are drawn flying in, each slam leaves its mark
## (ring and cracks) on the ground layer, and none of it changes the logic -- staged or headless, the same bones, slams and
## dead.
static func _staged(t, made: Array) -> void:
	var plain: Dictionary = await _slam_run(t, made, false)
	var ctx: FxContext = made[5]
	var keep := [ctx.overhead, ctx.ground, ctx.overhead_back]
	var stage := Node2D.new()
	t.root.add_child(stage)
	await t.process_frame  # (the tree is only live after the first frame)
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	ctx.overhead_back = Node2D.new()
	for n in [ctx.ground, ctx.overhead_back, ctx.overhead]:
		stage.add_child(n)
	var stub := FxStage.StageImpact.new()
	ctx.impact = stub
	var lit: Dictionary = await _slam_run(t, made, true)
	ctx.impact = null
	stub.free()
	ctx.overhead = keep[0]
	ctx.ground = keep[1]
	ctx.overhead_back = keep[2]
	t.root.remove_child(stage)
	stage.free()
	t.check(int(lit.drawn_bones) == 1 and int(lit.marks) == 2,
		"staged: the bones are drawn flying in, and each slam leaves its mark on the ground (%d, %d marks)" % [lit.drawn_bones, lit.marks])
	t.check(lit.bones == plain.bones and lit.slams == plain.slams and lit.dead == plain.dead and int(plain.slams) == 2 and plain.dead,
		"staged or not, the same bones (%d/%d), slams (%d/%d) and dead (%s/%s)" % [lit.bones, plain.bones, lit.slams, plain.slams, lit.dead, plain.dead])


## "30 zombies + giant: _fx_process + visitors.step under 5 ms a frame", in the full town (220 people where the day put
## them), the thirty bodies lying round the market; ruling R13 with the slams: measured from just before the landing to past
## landed_at + 2 SLAM_EVERY (the landing's slam and two more), at 60 frames a second.
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
	RD._run(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE - 0.1)
	var frame := 1.0 / 60.0
	var frames := ceili((0.1 + 2.0 * GraveTideFx.SLAM_EVERY + 0.2) / frame)
	var worst := 0.0
	var slam_worst := 0.0
	var t0 := Time.get_ticks_usec()
	for i in frames:
		var before := fx.slams
		var f0 := Time.get_ticks_usec()
		fx._process(frame)
		var f_ms := float(Time.get_ticks_usec() - f0) / 1000.0
		worst = maxf(worst, f_ms)
		if fx.slams > before:
			slam_worst = maxf(slam_worst, f_ms)
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0 / float(frames)
	print("GRAVETIDE perf: %.3f ms a frame over %d frames, worst %.3f ms, worst slam frame %.3f ms (%d slams, %d up, %d alive in town)"
		% [ms, frames, worst, slam_worst, fx.slams, fx.visitors.living().size(),
		(crowd.citizens + crowd.soldiers).filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive()).size()])
	t.check(fx.giant != null and _zombies(fx).size() >= 25 and fx.slams >= 3 and frames >= PERF_FRAMES and ms < PERF_MS,
		"30 zombies + giant + %d slams: _fx_process + visitors.step under 5 ms a frame averaged over %d frames (%.3f ms)" % [fx.slams, frames, ms])
	fx.end_now()
	RD._done(made)
