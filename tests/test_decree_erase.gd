extends RefCounted
## Erasing Distance (Decree, Tier III; spec 5.5; review R4): a dragged line whose distance is erased, folded back into its
## start. A gilt seam runs down it; the fold drags whoever stands within CRUSH_W, the decor there and every building it
## crosses to the press; the caught are crushed there (kill kind crushed) and lie piled at it, the buildings are taken
## away whole, one whose health another owns is struck where it stands instead, those within CRACK_W crack; the line is
## left bare and open to walk, and a mound of law rubble (one heap, one per building with its own ruins, one per 3
## decor) is laid round the press; the spring back throws whoever stands within THROW_W outward and down. All by
## distance and order: the same cast twice does the same.

const PATH := "res://src/fx/decree/erasing_distance.gd"
const DT := 0.05
## Open ground west of the town (nothing stands within 5 of it): the line runs from FROM along +y, LEN long.
const FROM := Vector2(-24.0, -3.0)
const DIR := Vector2(0.0, 1.0)
const LEN := 6.0


static func _setup() -> Array:
	var env := EnvironmentField.new()
	env.rng.seed = 11  # the buildings' own seeds (and so a townhouse's art) the same in both runs
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
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return [crowd, env, grid, field, world, ctx, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


## `seconds` of the effect's frames, DT at a time.
static func _run(fx: FxTimeline, seconds: float) -> void:
	for i in int(roundf(seconds / DT)):
		fx._process(DT)


static func _barrel(env: EnvironmentField, at: Vector2) -> Decor:
	var d := Decor.new().setup(Decor.Kind.BARREL, at, Vector2.ZERO, 7)
	env.add_decor(d)
	return d


## Whether decor `d` is still in the town (a piece taken away is freed).
static func _has(env: EnvironmentField, d: Variant) -> bool:
	return is_instance_valid(d) and env.decor().has(d)


## A check only on the first of the two runs (the second is compared whole).
static func _ck(t, on: bool, cond: bool, msg: String) -> void:
	if on:
		t.check(cond, msg)


static func run(t) -> void:
	var b := PowerBook.get_power("erase")
	var area: Dictionary = Targeting.AREAS.get("erase", {})
	t.check(String(b.get("name", "")) == "Erasing Distance" and int(b.get("dp", 0)) == 4 and float(b.get("cooldown", 0.0)) == 60.0
		and String(b.get("aim", "")) == "drag" and not PowerBook.is_quiet("erase") and PowerBook.authority_of("erase") == "decree"
		and ResourceLoader.exists(String(b.get("path", ""))) and String(area.get("shape", "")) == "lane"
		and is_equal_approx(float(area.get("length", 0.0)), 10.0) and is_equal_approx(float(area.get("half", 0.0)), 1.0)
		and bool(area.get("stretch", false)) and Rules.POWER_KINDS.get("erase", []) == [&"crushed"]
		and PowerBook.family("erase") == "decree" and PowerBook.REACH.has("erase"),
		"Erasing Distance: Decree, 4 Might, 60 s, a drag up to 10, loud, a lane 1 each side, kills by crushing (%s)" % [b])
	var ef = load(PATH) if ResourceLoader.exists(PATH) else null
	if ef == null:
		t.check(false, "the effect script loads")
		return
	t.check(is_equal_approx(PowerBook.impact("erase"), float(ef.T_SEAM) + float(ef.T_FOLD)),
		"its danger lands when the fold closes (%.2f)" % PowerBook.impact("erase"))
	var first := _scenario(t, ef, true)
	var second := _scenario(t, ef, false)
	t.check(first != "" and first == second, "the same cast on the same ground does the same: nothing is rolled\n%s\n%s" % [first, second])


## One cast on the test's ground; returns a digest of what it did (where the dead lie, the heaps, the counts).
static func _scenario(t, ef, checking: bool) -> String:
	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var mid := FROM + DIR * LEN * 0.5
	var clear := true
	for s in env.near(mid, 4.0):
		clear = clear and (s.destroyed or s.walkable)
	_ck(t, checking, clear, "the test's ground is open")

	if checking:
		# --- The drag's length: clamped to MIN_LEN..MAX_LEN; no end given, DEFAULT_LEN.
		var long = FxTimeline.cast(ef, ctx, FROM, {"dir": DIR, "to": FROM + DIR * 14.0})
		var short = FxTimeline.cast(ef, ctx, FROM, {"dir": DIR, "to": FROM + DIR * 0.2})
		var none = FxTimeline.cast(ef, ctx, FROM, {})
		t.check(is_equal_approx(long.length, 10.0) and is_equal_approx(short.length, float(ef.MIN_LEN))
			and is_equal_approx(none.length, float(ef.DEFAULT_LEN)) and none.dir.is_equal_approx(Vector2.RIGHT),
			"a drag of 14 erases 10, one of 0.2 its least, a cast with no drag its default (%.2f, %.2f, %.2f)" % [long.length, short.length, none.length])
		long.free()
		short.free()
		none.free()

	# --- The ground the line runs through: a townhouse it crosses on its far half, a Citadel-owned part it crosses near
	# the press, a house 1.5 off it, one 2.6 off it; four barrels within 1 of it and one 1.6 off.
	var crossed := env.add_structure(Rect2(-24.4, 1.2, 0.8, 0.8), 30.0, Structure.Kind.HOUSE, &"house", &"townhouse")
	var owned := env.add_structure(Rect2(-24.3, -1.3, 0.6, 0.6), 30.0, Structure.Kind.HOUSE, &"house")
	var blows: Array = []
	owned.damage_filter = func(_s: Structure, amount: float, _source: Vector2, kind: StringName) -> void: blows.append([amount, kind])
	var near_house := env.add_structure(Rect2(-22.5, -2.0, 0.8, 0.8), 30.0, Structure.Kind.HOUSE, &"house")
	var far_house := env.add_structure(Rect2(-21.4, 0.5, 0.6, 0.6), 30.0, Structure.Kind.HOUSE, &"house")
	var art := LawRubble.art_tag_from(crossed)
	var barrels: Array = []
	for g: Vector2 in [Vector2(0.3, 1.0), Vector2(-0.5, 3.0), Vector2(0.6, 4.5), Vector2(0.0, 5.5)]:
		barrels.append(_barrel(env, FROM + g))
	var off_barrel := _barrel(env, FROM + Vector2(1.6, 2.0))
	# The town's own decor in the band (the plants on this open ground) goes with them.
	var in_band := 0
	for dc in env.decor():
		var rel := dc.at - FROM
		var along := clampf(rel.dot(DIR), 0.0, LEN)
		if not dc.sprite_only and not dc.kind in Decor.ON_WATER and dc.at.distance_to(FROM + DIR * along) <= 1.0:
			in_band += 1
	var want_heaps := mini(1 + 1 + in_band / 3, 8)
	var crossed_base := crossed.position
	var owned_base := owned.position
	var a: Person = crowd.citizens[0]
	var guard: Person = crowd.soldiers[0]
	var d: Person = crowd.citizens[1]
	var p15: Person = crowd.citizens[2]
	var p24: Person = crowd.citizens[3]
	var p35: Person = crowd.citizens[4]
	var behind: Person = crowd.citizens[5]
	a.ground_pos = FROM + Vector2(0.8, 0.5)  # 0.8 off the line
	guard.ground_pos = FROM + Vector2(-0.5, 5.0)  # 0.5 off it, at its far end
	d.ground_pos = FROM + Vector2(-0.2, 2.0)
	d.inside = true
	p15.ground_pos = FROM + Vector2(-1.5, 2.0)  # 1.5 off: not crushed, thrown
	p24.ground_pos = FROM + Vector2(2.4, 2.0)  # 2.4 off: thrown
	p35.ground_pos = FROM + Vector2(3.5, 3.0)  # 3.5 off: left standing
	behind.ground_pos = FROM - DIR * 1.6 + Vector2(0.1, 0.0)  # 1.6 behind the press: where the mound's second heap lands
	_ck(t, checking, not grid.walkable(crossed.center()), "the townhouse closes its walk cells")
	var killed := crowd.killed_citizens + crowd.killed_soldiers
	var a_from := a.ground_pos.distance_to(FROM)
	var barrel_from: float = (barrels[2] as Decor).at.distance_to(FROM)
	var fx = FxTimeline.cast(ef, ctx, FROM, {"dir": DIR, "to": FROM + DIR * LEN})
	_ck(t, checking, is_equal_approx(fx.length, LEN) and fx.to.is_equal_approx(FROM + DIR * LEN),
		"the line runs from the press to the release (%.2f)" % fx.length)

	# --- Stage 1: the seam runs; nobody and nothing is taken yet.
	_run(fx, float(ef.T_SEAM) - DT)
	_ck(t, checking, a.is_alive() and a.ground_pos.is_equal_approx(FROM + Vector2(0.8, 0.5)) and fx.caught.is_empty()
		and crossed.position == crossed_base and crossed.scale == Vector2.ONE, "while the seam runs, nothing is taken")

	# --- Stage 2: the fold drags whoever stands within CRUSH_W, the decor and the building the line crosses to the press.
	_run(fx, DT + float(ef.T_FOLD) * 0.5)
	var screen_from := Iso.ground_to_screen(FROM)
	_ck(t, checking, a.is_alive() and guard.is_alive() and fx.caught.has(a) and fx.caught.has(guard) and not fx.caught.has(d)
		and not fx.caught.has(p15) and a.ground_pos.distance_to(FROM) < a_from - 0.2,
		"half way through the fold the two within 1 are dragged toward the press (%.2f of %.2f), the one indoors and the one at 1.5 are not"
		% [a.ground_pos.distance_to(FROM), a_from])
	_ck(t, checking, crossed.scale.x < 0.9 and crossed.position.distance_to(screen_from) < crossed_base.distance_to(screen_from) - 20.0
		and env.structures().has(crossed) and not crossed.destroyed and owned.position == owned_base and owned.scale == Vector2.ONE,
		"the townhouse slides down the line toward the press, shrinking (%.2f), still standing; the Citadel's part stays put"
		% crossed.scale.x)
	_ck(t, checking, (barrels[2] as Decor).at.distance_to(FROM) < barrel_from - 1.0, "and the barrels slide with it")
	_run(fx, float(ef.T_FOLD) * 0.5)
	fx._process(0.01)  # past the close, whatever the frames' rounding
	_ck(t, checking, not a.is_alive() and a._kind == &"crushed" and not guard.is_alive() and guard._kind == &"crushed"
		and a.ground_pos.distance_to(FROM) < 0.3 and guard.ground_pos.distance_to(FROM) < 0.3
		and not a.ground_pos.is_equal_approx(guard.ground_pos)
		and crowd.killed_citizens + crowd.killed_soldiers == killed + 2 and fx.crushed == 2,
		"when the fold closes they are crushed at the press and lie piled there (kind %s, %.2f and %.2f from it)"
		% [a._kind, a.ground_pos.distance_to(FROM), guard.ground_pos.distance_to(FROM)])
	_ck(t, checking, d.is_alive() and p15.is_alive() and p24.is_alive() and p35.is_alive() and behind.is_alive(),
		"the one indoors and those beyond 1 live")
	_ck(t, checking, crossed.taken and crossed.destroyed and not env.structures().has(crossed) and not crossed.visible
		and crossed.scale == Vector2.ONE and fx.taken == 1,
		"the townhouse is taken away whole when it arrives (%d taken)" % fx.taken)
	_ck(t, checking, env.structures().has(owned) and blows.size() == 1 and float(blows[0][0]) >= 99999.0 and fx.struck == 1
		and not owned.taken, "the Citadel's part is dealt the blow where it stands, its owner deciding (%d blows)" % blows.size())
	_ck(t, checking, not near_house.destroyed and near_house.hp < near_house.max_hp * Structure.CRACK_AT
		and not far_house.destroyed and is_equal_approx(far_house.hp, far_house.max_hp),
		"the house 1.5 off cracks (%.0f of %.0f); the one 2.6 off is untouched" % [near_house.hp, near_house.max_hp])
	var gone := 0
	for bl: Variant in barrels:
		gone += 0 if _has(env, bl) else 1
	_ck(t, checking, gone == 4 and _has(env, off_barrel) and fx.removed == in_band,
		"the four barrels within 1 are taken away with the rest of the band's decor, the one 1.6 off stays (%d of %d taken)"
		% [fx.removed, in_band])

	# --- The mound: 1 + 1 building + 1 per 3 decor heaps (8 at most), round the press, the townhouse's wearing its ruins.
	var heaps: Array = fx.heaps
	var round_press := heaps.size() == want_heaps
	var far_half := 0
	var closed := true
	var worn := 0
	var under := false
	for h: Structure in heaps:
		var rel := h.center() - FROM
		round_press = round_press and h.role == LawRubble.ROLE and env.structures().has(h) and rel.length() <= 3.0
		far_half += 1 if rel.dot(DIR) >= LEN * 0.5 else 0
		closed = closed and not grid.walkable(h.center())
		worn += 1 if h.art_tag == art else 0
		under = under or h.footprint.grow(WalkGrid.BODY).has_point(behind.ground_pos)
	_ck(t, checking, round_press and far_half == 0 and closed,
		"a mound of %d heaps (of %d) lies round the press, none on the line's far half, closing its cells" % [heaps.size(), want_heaps])
	_ck(t, checking, art != &"" and worn == 1, "one heap wears the townhouse's own ruins (%s)" % art)
	_ck(t, checking, not under and behind.ground_pos.distance_to(FROM - DIR * 1.6) > 0.3,
		"the one standing where a heap landed was pushed out first")
	var open := 0
	for k in range(6, 13):
		open += 1 if grid.walkable(FROM + DIR * float(k) * 0.5) else 0
	_ck(t, checking, open == 7 and grid.walkable(crossed.center()),
		"the line is left bare, its cells open to walk where the townhouse stood (%d of 7)" % open)
	_ck(t, checking, not p15.is_down() and not p24.is_down(), "nobody is thrown until the spring back")

	# --- Stage 3: the spring back throws whoever stands within THROW_W outward and down.
	_run(fx, float(ef.T_SNAP) + DT)
	_ck(t, checking, p15.is_down() and p24.is_down() and not p35.is_down() and p15._velocity.x < 0.0 and p24._velocity.x > 0.0,
		"the spring back throws those within 3 outward and knocks them down; the one at 3.5 stands (%d thrown)" % fx.thrown)
	_ck(t, checking, d.is_alive(), "the one indoors is still alive")
	var digest := "%d %d %d %d %d %d|%s %s %s|" % [fx.crushed, fx.taken, fx.removed, fx.struck, fx.cracked, fx.thrown,
		a.ground_pos, guard.ground_pos, behind.ground_pos]
	for h: Structure in heaps:
		digest += "%s %s %.3f;" % [h.footprint, h.art_tag, h.max_height]
	_run(fx, fx.duration)
	_ck(t, checking, fx.finished and env.structures().has(heaps[0]), "the effect ends; the rubble stays until it is cleared")
	_done(made)
	return digest
