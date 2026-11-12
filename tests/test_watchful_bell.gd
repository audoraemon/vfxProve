extends RefCounted
## God P3 Task 2 (MS §4, R12): the Watchful Bell, the first stolen gift. `Crowd.climb_scale` multiplies the profile's bell climb wherever the
## climb is set (BellNetwork.setup(), restore(), Crowd.raise_profile()); a stand-in's ESCORT_CLIMB stacks; the Herald's descent is not a
## climb. Without the gift the scale is exactly 1.0 and every climb is the profile's own, bit for bit (C3). Mission.start() cannot run in a
## suite (no scene tree): the line that hands the def's gifts to the crowd is checked in its source, and FLOW's rite walk is the live proof.

const Kit := preload("res://tests/test_tier2_groundwork.gd")
const H := preload("res://tests/test_herald.gd")
const DT := 0.05


static func run(t) -> void:
	_climb_default(t)
	_climb_gift(t)
	_climb_stand_in(t)
	_raise_profile(t)
	_gift_scale(t)
	_herald_untouched(t)
	_mission_reads_def(t)


## A crowd for `profile` with `scale` set before spawn(), as Mission does; the pieces to free in _drop().
static func _world(profile: ResponseProfile, scale: float) -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var node := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, node, 5)
	crowd.profile = profile
	crowd.climb_scale = scale
	crowd.spawn()
	return {"env": env, "town": town, "field": field, "world": node, "crowd": crowd}


static func _drop(s: Dictionary) -> void:
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


## Without the gift: the scale is 1.0 and the bell's climb is the profile's number exactly (8.0 Unaware and Organized, 5.0 God-Resistant).
static func _climb_default(t) -> void:
	t.check(Crowd.new().climb_scale == 1.0, "a new Crowd's climb_scale is exactly 1.0 (%s)" % [Crowd.new().climb_scale])
	for p: ResponseProfile in [ResponseProfile.unaware(), ResponseProfile.for_tier(ResponseProfile.Tier.ORGANIZED),
			ResponseProfile.for_tier(ResponseProfile.Tier.GOD_RESISTANT)]:
		var s := _world(p, 1.0)
		var bell: BellNetwork = (s.crowd as Crowd).bell
		t.check(bell.climb == p.bell_climb, "scale 1.0: the bell climbs the profile's %.1f s exactly (%s)" % [p.bell_climb, bell.climb])
		_drop(s)
	t.check(is_equal_approx(ResponseProfile.unaware().bell_climb, 8.0) and is_equal_approx(ResponseProfile.for_tier(ResponseProfile.Tier.GOD_RESISTANT).bell_climb, 5.0),
		"(the profiles' climbs are the 8 and the 5 the gift scales)")


## With the gift: setup() reads the scale (9.6 Unaware, 6.0 God-Resistant), and restore() reads it again.
static func _climb_gift(t) -> void:
	var s := _world(ResponseProfile.unaware(), 1.2)
	var crowd: Crowd = s.crowd
	var bell := crowd.bell
	t.check(is_equal_approx(bell.climb, 9.6), "scale 1.2: Unaware's bell takes 9.6 s (%s)" % [bell.climb])
	var keeper := bell.keeper
	var sub: Person = crowd.citizens[3]
	bell.replace_keeper(sub)
	bell.restore(keeper)
	t.check(is_equal_approx(bell.climb, 9.6) and bell.state == BellNetwork.State.IDLE,
		"restore() puts the climb back to 9.6 (%s)" % [bell.climb])
	_drop(s)
	var g := _world(ResponseProfile.for_tier(ResponseProfile.Tier.GOD_RESISTANT), 1.2)
	t.check(is_equal_approx((g.crowd as Crowd).bell.climb, 6.0), "scale 1.2: God-Resistant's bell takes 6.0 s (%s)" % [(g.crowd as Crowd).bell.climb])
	_drop(g)


## A stand-in's slower climb stacks on the gift: 9.6 x 1.5 = 14.4, once however many fall.
static func _climb_stand_in(t) -> void:
	var s := _world(ResponseProfile.unaware(), 1.2)
	var crowd: Crowd = s.crowd
	var bell := crowd.bell
	bell.replace_keeper(crowd.citizens[3])
	t.check(is_equal_approx(bell.climb, 9.6 * BellNetwork.ESCORT_CLIMB) and is_equal_approx(bell.climb, 14.4),
		"with the gift a stand-in's climb is 9.6 x ESCORT_CLIMB = 14.4 (%s)" % [bell.climb])
	bell.replace_keeper(crowd.citizens[4])
	t.check(is_equal_approx(bell.climb, 14.4), "a second stand-in does not stack again (%s)" % [bell.climb])
	_drop(s)
	var p := _world(ResponseProfile.unaware(), 1.0)
	(p.crowd as Crowd).bell.replace_keeper((p.crowd as Crowd).citizens[3])
	t.check((p.crowd as Crowd).bell.climb == 8.0 * BellNetwork.ESCORT_CLIMB, "without it, the stand-in's is 12.0 as ever (%s)" % [(p.crowd as Crowd).bell.climb])
	_drop(p)


## raise_profile() between acts: an idle bell takes the higher profile's climb times the scale; one already climbing is left alone.
static func _raise_profile(t) -> void:
	var s := _world(ResponseProfile.unaware(), 1.2)
	var crowd: Crowd = s.crowd
	var high := ResponseProfile.for_tier(ResponseProfile.Tier.GOD_RESISTANT)
	crowd.raise_profile(high)
	t.check(is_equal_approx(crowd.bell.climb, high.bell_climb * 1.2) and is_equal_approx(crowd.bell.climb, 6.0),
		"raise_profile() to a higher profile sets p.bell_climb x 1.2 (%s)" % [crowd.bell.climb])
	_drop(s)
	var n := _world(ResponseProfile.unaware(), 1.0)
	(n.crowd as Crowd).raise_profile(high)
	t.check((n.crowd as Crowd).bell.climb == high.bell_climb, "without the gift, raise_profile() sets the profile's climb exactly (%s)" % [(n.crowd as Crowd).bell.climb])
	_drop(n)
	var c := _world(ResponseProfile.unaware(), 1.2)
	(c.crowd as Crowd).bell.state = BellNetwork.State.CLIMBING
	(c.crowd as Crowd).raise_profile(high)
	t.check(is_equal_approx((c.crowd as Crowd).bell.climb, 9.6), "a bell already climbing keeps its climb (%s)" % [(c.crowd as Crowd).bell.climb])
	_drop(c)


## The scale a night gets from the gifts it carries: the Watchful Bell's 1.2, nothing's 1.0 exactly.
static func _gift_scale(t) -> void:
	var none := RiteBook.climb_scale(PackedStringArray())
	var bell := RiteBook.climb_scale(PackedStringArray([RiteBook.WATCHFUL_BELL]))
	var unknown := RiteBook.climb_scale(PackedStringArray(["no_such_gift"]))
	t.check(none == 1.0 and unknown == 1.0, "no gifts, or an unknown one: the scale is exactly 1.0 (%s, %s)" % [none, unknown])
	t.check(is_equal_approx(bell, 1.2), "the Watchful Bell: 1.2 (%s)" % [bell])


## The Herald's descent and walk are the same at 1.0 and 1.2: from the toll to the Temple's door takes as long (the toll itself moves
## with the climb, so the timing starts at the toll). This runs the whole errand, so it fails if the scale ever reached the descent.
static func _herald_untouched(t) -> void:
	var took := []
	for scale in [1.0, 1.2]:
		var s := H._world("warning")
		(s.crowd as Crowd).climb_scale = scale
		var bell: BellNetwork = (s.crowd as Crowd).bell
		bell.climb = 8.0 * scale
		var ok := H._deliver(s)
		H._ring(s)
		var d: WarningDirector = s.d
		var lw: LanternWatch = s.lw
		var r: Rules = s.rules
		var at := d._descend
		var n := H._until(s, 90.0, func() -> bool: return r.finished)
		took.append([ok, at, n, lw.heard])
		Kit.done(s)
	t.check(took[0][0] and took[1][0] and took[0][3] and took[1][3], "(both Heralds were delivered and got in: %s)" % [took])
	t.check(is_equal_approx(float(took[0][1]), float(took[1][1])) and is_equal_approx(float(took[0][2]), float(took[1][2])),
		"the Herald's descent and trip are the same at 1.0 and 1.2 (descent %s / %s, trip %s / %s s)" % [took[0][1], took[1][1], took[0][2], took[1][2]])


## Mission hands the def's gifts to the crowd before spawn(); Mission.start() cannot run here, so its source and the book are checked.
static func _mission_reads_def(t) -> void:
	var src := FileAccess.get_file_as_string("res://src/game/mission.gd")
	var set_at := src.find("_crowd.climb_scale = RiteBook.climb_scale(_def.gifts)")
	var spawn_at := src.find("_crowd.spawn(citizens, people - citizens)")
	t.check(set_at >= 0 and spawn_at > set_at, "Mission.start() sets climb_scale from the def's gifts before spawn() (%d < %d)" % [set_at, spawn_at])
	var def := MissionBook.warning()
	t.check(RiteBook.climb_scale(def.gifts) == 1.0, "a def with no gifts gives exactly 1.0 (%s)" % [RiteBook.climb_scale(def.gifts)])
	def.gifts = PackedStringArray([RiteBook.WATCHFUL_BELL])
	t.check(is_equal_approx(RiteBook.climb_scale(def.gifts), 1.2), "a def carrying the Watchful Bell gives 1.2 (%s)" % [RiteBook.climb_scale(def.gifts)])
