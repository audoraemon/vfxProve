extends RefCounted
## Ability levels for the Tier 5 pair, Doors of the Dead and Heaven's Door (spec 2026-11-11 passage ability levels).
## Level 1 plays as it always did; level 5 widens the district, opens more doors and holds them longer (Doors of the
## Dead), and reaches farther, pulls harder at the rim and lands harder (Heaven's Door). The twists: Rise Again -- the
## horde's dead rise as ghosts 2 s on where they fell, hunt with it (in the shared LIVE_CAP) and are called back with
## it -- and Twin Doors -- two doors back to back, the pull over the whole circle, the landing struck once.

const DD := preload("res://tests/test_deaddoors.gd")
const HD := preload("res://tests/test_heavendoor.gd")
const DEAD := "res://src/fx/control/doors_of_the_dead.gd"
const HEAVEN := "res://src/fx/control/heavens_door.gd"
const DT := 0.05


static func run(t) -> void:
	_dead_levels(t)
	_rise_again(t)
	_rise_cap_and_lv4(t)
	_heaven_levels(t)
	_twin_doors(t)


# --- Doors of the Dead ------------------------------------------------------------------

## Stand `p` at `at`, calm, out in the open.
static func _place(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p.mind = Person.Mind.CALM
	p.inside = false
	p._sync_position()


## A hellhound of the cast's own horde summoned beside `victim`; the cast runs until its bite kills them (at most 2 s).
## Returns the spot they died at (INF if they did not), and takes the hound out again.
static func _kill_beside(fx: DoorsOfTheDeadFx, victim: Person) -> Vector2:
	var spec: Array = DoorsOfTheDeadFx.KINDS[Animal.Breed.HELLHOUND]
	var hound := fx.visitors.summon(victim.ground_pos + Vector2(0.2, 0.0), Animal.Breed.HELLHOUND, int(spec[0]), 1.0,
		float(spec[2]), float(spec[3]), float(spec[4]), bool(spec[5]))
	for k in roundi(2.0 / DT):
		fx._process(DT)
		if not victim.is_alive():
			break
	if is_instance_valid(hound):
		fx.visitors.take(hound)
	return Vector2.INF if victim.is_alive() else victim.ground_pos


static func _dead_levels(t) -> void:
	var made := DD._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	DD._clear_town(crowd)
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var one: DoorsOfTheDeadFx = FxTimeline.cast(load(DEAD), ctx, at)
	var one_b: DoorsOfTheDeadFx = FxTimeline.cast(load(DEAD), ctx, at, {"level": 1})
	t.check(one.lv_radius == DoorsOfTheDeadFx.RADIUS and one.lv_max_doors == DoorsOfTheDeadFx.MAX_DOORS
			and one.lv_span == DoorsOfTheDeadFx.SPAN and one.lv_max_spirits == DoorsOfTheDeadFx.MAX_SPIRITS
			and is_equal_approx(one.t_end(), DoorsOfTheDeadFx.T_CHILL + DoorsOfTheDeadFx.WAVE + DoorsOfTheDeadFx.SPAN)
			and not one.rise_again and one.doors.size() == one_b.doors.size() and one_b.lv_span == DoorsOfTheDeadFx.SPAN
			and is_equal_approx(one.duration, one_b.duration),
		"Doors of the Dead at level 1 is today's: district 12, 18 doors, 45 s, 160 spirits, no rising")
	var n1 := one.doors.size()
	one.end_now()
	one_b.end_now()
	var five: DoorsOfTheDeadFx = FxTimeline.cast(load(DEAD), ctx, at, {"level": 5})
	var within := true
	for d in five.doors:
		within = within and d.building.distance_to(at) <= 14.0
	t.check(is_equal_approx(five.lv_radius, 14.0) and five.lv_max_doors == 24 and is_equal_approx(five.lv_span, 60.0)
			and five.lv_max_spirits == 220 and five.rise_again
			and is_equal_approx(five.t_end(), DoorsOfTheDeadFx.T_CHILL + DoorsOfTheDeadFx.WAVE + 60.0)
			and is_equal_approx(five.closed_at(), five.t_end() + DoorsOfTheDeadFx.RECALL)
			and within and five.doors.size() <= 24 and five.doors.size() >= n1,
		"at level 5 the district is 14, up to 24 doors open (%d against level 1's %d) for 60 s, 220 spirits in all, and the dead rise" % [five.doors.size(), n1])
	var four: DoorsOfTheDeadFx = FxTimeline.cast(load(DEAD), ctx, at, {"level": 4})
	t.check(is_equal_approx(four.lv_radius, 13.5) and four.lv_max_doors == 22 and not four.rise_again,
		"level 4 grows the numbers but has no twist")
	five.end_now()
	four.end_now()
	DD._done(made)


## Rise Again: one the horde kills rises as a ghost 2 s on where they fell and hunts; whoever it kills rises too; at the
## span's end the risen are called back to a door with the rest, and the doors close on them.
static func _rise_again(t) -> void:
	var made := DD._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	DD._clear_town(crowd)
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var victim: Person = crowd.citizens[1]
	var prey: Person = crowd.citizens[2]
	var spot := grid.nearest_walkable(at + Vector2(1.5, 1.5))
	_place(victim, spot)
	_place(prey, grid.nearest_walkable(spot + Vector2(2.5, 0.0)))
	var fx: DoorsOfTheDeadFx = FxTimeline.cast(load(DEAD), ctx, at, {"level": 5})
	var fell := _kill_beside(fx, victim)
	var killed_at := fx.t
	t.check(fell != Vector2.INF and fx.risen == 0, "a hellhound of the horde bites one dead (at %.2f s)" % killed_at)
	DD._run(fx, DoorsOfTheDeadFx.RISE_AFTER - 0.2)
	t.check(fx.risen == 0, "the body lies a while: nothing has risen %.1f s on" % (DoorsOfTheDeadFx.RISE_AFTER - 0.2))
	DD._run(fx, 0.3)
	var ghost: Animal = fx.raised[0] if fx.risen > 0 else null
	var rule: Visitors.Rule = fx.visitors._rules.get(ghost) if ghost != null else null
	t.check(fx.risen == 1 and ghost != null and ghost.breed == Animal.Breed.GHOST and ghost.ground_pos.distance_to(fell) < 0.6
			and rule != null and rule.phase and fx.visitors.living().has(ghost) and fx._fright_in.has(ghost)
			and int(ghost.health) == int(DoorsOfTheDeadFx.KINDS[Animal.Breed.GHOST][0]),
		"%.1f s after the kill they rise where they fell as a ghost of the other side (through walls, frightening, a ghost's blows)" % DoorsOfTheDeadFx.RISE_AFTER)
	t.check(fx.spirits == 0, "the risen are not spirits through a door: the doors' count stays theirs (%d)" % fx.spirits)
	var gap := ghost.ground_pos.distance_to(prey.ground_pos) if ghost != null else 0.0
	DD._run(fx, 0.6)
	t.check(ghost != null and is_instance_valid(ghost) and ghost.target == prey and ghost.ground_pos.distance_to(prey.ground_pos) < gap,
		"and joins the hunt: it goes for the nearest of the living")
	# Whoever it (or the horde) kills rises too.
	var prey_fell := Vector2.INF
	for k in roundi(10.0 / DT):
		fx._process(DT)
		if not prey.is_alive():
			prey_fell = prey.ground_pos
			break
	DD._run(fx, DoorsOfTheDeadFx.RISE_AFTER + 0.2)
	var rose_there := false
	for a in fx.raised:
		rose_there = rose_there or (is_instance_valid(a) and a != ghost and a.ground_pos.distance_to(prey_fell) < 1.0)
	t.check(prey_fell != Vector2.INF and fx.risen >= 2 and rose_there, "the one it hunted falls and rises in turn (%d risen)" % fx.risen)
	# The span: the risen stand in the shared LIVE_CAP.
	var peak := 0
	while fx.t < fx.t_end() - 0.1:
		fx._process(DT)
		peak = maxi(peak, fx.visitors.living().size())
	t.check(peak <= DoorsOfTheDeadFx.LIVE_CAP and fx.spirits <= fx.lv_max_spirits,
		"never more than LIVE_CAP on their feet, the risen with them (at most %d; %d through the doors, %d risen)" % [peak, fx.spirits, fx.risen])
	var risen_at_end := fx.risen
	DD._run(fx, 0.3)
	var called := 0
	var homeward := true
	for a in fx.raised:
		if not is_instance_valid(a) or not a.is_alive():
			continue
		var r: Visitors.Rule = fx.visitors._rules.get(a)
		var gate_door := INF
		for d in fx.doors:
			gate_door = minf(gate_door, r.gate.distance_to(d.at + d.out * 0.45) if r != null else INF)
		homeward = homeward and r != null and r.recalling and gate_door < 0.01
		called += 1
	t.check(homeward, "the span over, every risen ghost on its feet is called back to an open door with the rest (%d)" % called)
	DD._run(fx, DoorsOfTheDeadFx.RECALL + 0.3)
	var gone := true
	for a in fx.raised:
		gone = gone and not (is_instance_valid(a) and a.is_alive())
	t.check(gone and fx.visitors.living().is_empty() and fx.risen == risen_at_end,
		"and the doors close on them: none left, none risen after the span")
	fx.free()
	DD._done(made)


## None rise while LIVE_CAP is full; at level 4 none rise at all.
static func _rise_cap_and_lv4(t) -> void:
	var made := DD._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	DD._clear_town(crowd)
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var victim: Person = crowd.citizens[1]
	var spot := grid.nearest_walkable(at + Vector2(1.5, 1.5))
	_place(victim, spot)
	var fx: DoorsOfTheDeadFx = FxTimeline.cast(load(DEAD), ctx, at, {"level": 5})
	# The horde at its cap but one: hounds that hunt nobody (no reach), far from everyone.
	var idle := grid.nearest_walkable(at + Vector2(-6.0, -6.0))
	for i in DoorsOfTheDeadFx.LIVE_CAP - 1:
		fx.visitors.summon(idle, Animal.Breed.HELLHOUND, 4, 1.0, 0.01, 0.01, 1.0, false)
	var spec: Array = DoorsOfTheDeadFx.KINDS[Animal.Breed.HELLHOUND]
	fx.visitors.summon(spot + Vector2(0.2, 0.0), Animal.Breed.HELLHOUND, int(spec[0]), 1.0, float(spec[2]), float(spec[3]),
		float(spec[4]), bool(spec[5]))
	for k in roundi(2.0 / DT):
		fx._process(DT)
		if not victim.is_alive():
			break
	var full := fx.visitors.living().size()
	DD._run(fx, DoorsOfTheDeadFx.RISE_AFTER + 0.3)
	t.check(not victim.is_alive() and full == DoorsOfTheDeadFx.LIVE_CAP and fx.risen == 0 and fx.visitors.living().size() == full,
		"with LIVE_CAP on their feet, one the horde kills does not rise (%d on their feet, %d risen)" % [full, fx.risen])
	fx.end_now()
	var four: DoorsOfTheDeadFx = FxTimeline.cast(load(DEAD), ctx, at, {"level": 4})
	var other: Person = crowd.citizens[2]
	_place(other, grid.nearest_walkable(spot + Vector2(-2.0, 0.5)))
	var fell := _kill_beside(four, other)
	DD._run(four, DoorsOfTheDeadFx.RISE_AFTER + 0.3)
	var ghost_there := false
	for a in four.visitors.living():
		ghost_there = ghost_there or (a.breed == Animal.Breed.GHOST and a.ground_pos.distance_to(fell) < 1.0)
	t.check(fell != Vector2.INF and four.risen == 0 and not ghost_there, "at level 4 the horde's dead stay down")
	four.end_now()
	DD._done(made)


# --- Heaven's Door -------------------------------------------------------------------

static func _heaven_levels(t) -> void:
	var s := HD._bare()
	var one: HeavensDoorFx = FxTimeline.cast(load(HEAVEN), s.ctx, Vector2.ZERO)
	var same := true
	for d: float in [0.0, 1.5, 4.0, 8.0, 12.0, 16.0, 18.0]:
		same = same and is_equal_approx(one.pull_at(d), HeavensDoorFx.pull_speed(d))
		same = same and is_equal_approx(one.storm_at(d), HeavensDoorFx.storm_rate(d))
	t.check(one.lv_pull_r == HeavensDoorFx.PULL_R and one.lv_span == HeavensDoorFx.SPAN and one.lv_pull_far == HeavensDoorFx.PULL_FAR
			and one.lv_land_damage == HeavensDoorFx.LAND_DAMAGE and not one.twin and one.half_angle == HeavensDoorFx.HALF_ANGLE
			and is_equal_approx(one.shut_at(), HeavensDoorFx.T_FALL + HeavensDoorFx.T_OPEN + HeavensDoorFx.SPAN) and same,
		"Heaven's Door at level 1 is today's: reach 16, 12 s, 0.6 at the rim, a 40 blow, one door over the half circle")
	one.end_now()
	var five: HeavensDoorFx = FxTimeline.cast(load(HEAVEN), s.ctx, Vector2.ZERO, {"level": 5})
	t.check(is_equal_approx(five.lv_pull_r, 20.0) and is_equal_approx(five.lv_span, 16.0) and is_equal_approx(five.lv_pull_far, 0.9)
			and is_equal_approx(five.lv_land_damage, 60.0) and five.twin
			and is_equal_approx(five.shut_at(), HeavensDoorFx.T_FALL + HeavensDoorFx.T_OPEN + 16.0)
			and is_equal_approx(five.pull_at(20.0), 0.9) and five.pull_at(12.0) > HeavensDoorFx.pull_speed(12.0),
		"at level 5 it reaches 20, pulls 16 s, 0.9 at the rim (harder everywhere out from the door) and lands for 60")
	five.end_now()
	HD._done(s)
	# Reach and the blow, played: one 18 out in front, and a wall within SHOCK_R.
	var hit := {}
	var moved := {}
	for lv in [1, 5]:
		var b := HD._bare()
		var far := HD._unit(b, Vector2(18.0, 0.0))
		var wall: Structure = (b.env as EnvironmentField).add_structure(Rect2(-4.5, 2.0, 1.0, 1.0), 2.0, Structure.Kind.WALL)
		wall.max_hp = 500.0
		wall.hp = 500.0
		var fx: HeavensDoorFx = FxTimeline.cast(load(HEAVEN), b.ctx, Vector2.ZERO, {"level": lv})
		HD._run_fx(fx, HeavensDoorFx.T_FALL + DT)
		hit[lv] = 500.0 - wall.hp
		HD._run_fx(fx, fx.open_at() + 1.0 - fx.t)
		moved[lv] = 18.0 - far.ground_pos.x
		fx.end_now()
		HD._done(b)
	t.check(is_equal_approx(float(hit[1]), HeavensDoorFx.LAND_DAMAGE) and is_equal_approx(float(hit[5]), 60.0),
		"the landing strikes a wall within SHOCK_R for %.0f at level 1 and %.0f at level 5 -- once, though two doors land" % [hit[1], hit[5]])
	t.check(is_equal_approx(float(moved[1]), 0.0) and float(moved[5]) > 0.5,
		"one 18 out in front is beyond level 1's reach (moved %.2f) and drawn at level 5 (%.2f)" % [moved[1], moved[5]])


## Twin Doors: one standing straight behind the door (opposite the drag) is drawn in and gone at level 5, and never
## touched at level 4.
static func _twin_doors(t) -> void:
	var result := {}
	for lv in [4, 5]:
		var s := HD._bare()
		var kinds := {}
		(s.field as EnemyField).enemy_killed.connect(func(e: DummyEnemy, kind: StringName) -> void: kinds[e] = kind)
		var behind := HD._unit(s, Vector2(-8.0, 0.0))
		var ahead := HD._unit(s, Vector2(10.0, 0.0))
		var fx: HeavensDoorFx = FxTimeline.cast(load(HEAVEN), s.ctx, Vector2.ZERO, {"level": lv, "dir": Vector2(3, 0)})
		HD._run_fx(fx, fx.open_at() + 6.0)
		result[lv] = [behind.is_alive(), behind.ground_pos, kinds.get(behind, &""), ahead.is_alive(), kinds.get(ahead, &""),
			fx.facing]
		fx.end_now()
		HD._done(s)
	var four: Array = result[4]
	var five: Array = result[5]
	t.check(four[5] == Vector2(1, 0) and bool(four[0]) and four[1] == Vector2(-8.0, 0.0) and not bool(four[3]) and four[4] == &"gone",
		"level 4, one door: the one in front is drawn in and gone, the one straight behind it is never touched (%s)" % four[1])
	t.check(not bool(five[0]) and five[2] == &"gone" and not bool(five[3]) and five[4] == &"gone",
		"level 5, Twin Doors: the second door faces the other way, so the one straight behind is drawn in and gone too")
	t.check(HeavensDoorFx.row_of(Vector2(-1, 0)) != HeavensDoorFx.row_of(Vector2(1, 0))
			and HeavensDoorFx.ROWS[HeavensDoorFx.row_of(Vector2(-1, 0))] == "north-west",
		"the second door is drawn from the same sheet, the row for the other way (seen from behind: north-west)")
