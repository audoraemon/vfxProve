extends RefCounted
## God T1R Task 1 (spec 9, preflight 4, 8, 18): the per-type policy dispatch (tools/dev/routes/god_t1.gd), the Tier 1 draft a god type plays,
## Rules.last_fx(), and the policy pieces the mission tasks share.

const GodT1 := preload("res://tools/dev/routes/god_t1.gd")

## The user's Tier 1 picks (D2).
const PAIRS := {"ruin": ["smite", "ember"], "death": ["deathmark", "pestilence"], "veil": ["doom", "blight"],
	"passage": ["thorns", "mirror"], "decree": ["noleave", "belllies"], "dominion": ["whisper", "discord"]}


## What behaviour_check hands a policy: only `_slot_ready` is used by the shared pieces.
class FakeBc:
	extends RefCounted

	func _slot_ready(rules: Rules, slots: Dictionary, key: String) -> bool:
		return slots.has(key) and rules.refusal(int(slots[key])) == ""


static func run(t) -> void:
	_dispatch(t)
	_all_filled(t)
	_god_draft(t)
	_last_fx(t)
	_outside_spot(t)
	_road_ahead(t)
	_plague_aim(t)
	_casts(t)


static func _world(loadout: PackedStringArray) -> Dictionary:
	var def := TierBook.board("warning")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.unaware()
	crowd.spawn()
	var rules := Rules.new().setup(loadout, null, env, field, crowd, town, def)
	var calls: Array = []
	rules.caster = func(_s: GDScript, g: Vector2, e: Dictionary) -> FxTimeline:
		calls.append({"at": g, "extra": e})
		return null
	var slots := {}
	for i in loadout.size():
		slots[loadout[i]] = i
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "calls": calls, "slots": slots}


static func _done(s: Dictionary) -> void:
	var rules: Rules = s.rules
	rules.teardown()
	rules.free()
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


## Every one of the 30 pairs has a policy. act() on an empty ctx is called only for a type its file has not filled yet (a stub); once a
## mission task fills a type, its policy reads the ctx and is not called empty (preflight 4).
static func _dispatch(t) -> void:
	t.check(GodT1.SCENARIOS == ["warning", "tax", "harvest", "lamb", "prayers"], "the five Tier 1 missions")
	var all_have := true
	var stubs_quiet := true
	for scenario: String in GodT1.SCENARIOS:
		var filled := GodT1.filled(scenario)
		for type: String in GodTree.RING:
			all_have = all_have and GodT1.has_policy(scenario, type)
			if not type in filled:
				stubs_quiet = stubs_quiet and GodT1.act(scenario, type, null, {}) == ""
	t.check(all_have, "all 30 pairs have a policy")
	t.check(stubs_quiet, "a stub casts nothing on an empty ctx")
	t.check(not GodT1.has_policy("miras", "ruin") and not GodT1.has_policy("tax", "nobody"), "an unknown scenario or type has none")
	t.check(GodT1.filled("nowhere").is_empty() and GodT1.state("nowhere", null, {}) == "", "an unknown scenario has nothing filled")


## Every mission's policy file has written all six types (god T1R Task 7): FILLED names them, so no pair is a stub at the 30-pair gate.
static func _all_filled(t) -> void:
	for scenario: String in GodT1.SCENARIOS:
		var filled := GodT1.filled(scenario)
		for type: String in GodTree.RING:
			t.check(type in filled, "%s: the %s policy is filled (FILLED holds %s)" % [scenario, type, Array(filled)])


## The draft behaviour_check plays under --god=<type>:1 with no --route: the real tree's Tier 1 pair (D2), dev fill off.
static func _god_draft(t) -> void:
	t.check(not GodTree.dev_fill, "the dev fill is off for the draft")
	var ok := true
	for type: String in GodTree.RING:
		ok = ok and Array(GodT1.loadout(type)) == PAIRS[type]
	t.check(ok, "every god type drafts its own two Tier 1 keys")
	t.check(GodT1.loadout("decree") == PackedStringArray(["noleave", "belllies"]), "decree: noleave, belllies")


## Rules.last_fx(): null before a cast, then the effect the cast returned; null again once that effect is freed.
static func _last_fx(t) -> void:
	var s := _world(PackedStringArray(["smite", "ember"]))
	var rules: Rules = s.rules
	var made: Array[FxTimeline] = []
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline:
		var fx := FxTimeline.new()
		made.append(fx)
		return fx
	t.check(rules.last_fx() == null, "before any cast there is no last effect")
	var fx := rules.cast(0, Vector2(1, 1))
	t.check(fx != null and rules.last_fx() == fx and made.size() == 1, "after a cast, the effect the cast returned")
	made[0].free()
	t.check(rules.last_fx() == null, "freed since, it is null")
	_done(s)


static func _outside_spot(t) -> void:
	var s := _world(PackedStringArray(["whisper", "discord"]))
	var ctx := {"crowd": s.crowd}
	var near_gate := GodT1.outside_spot(null, ctx, Vector2(2.7, 15.0), 3.0)
	t.check(near_gate != Vector2.INF and Walls.outside(near_gate) and near_gate.distance_to(Vector2(2.7, 15.0)) <= 3.0
		and (s.crowd as Crowd)._grid.walkable(near_gate), "from the Main Gate, walkable ground out of the walls within reach")
	t.check(GodT1.outside_spot(null, ctx, Vector2(0, 0), 3.0) == Vector2.INF, "from the market there is none within 3")
	_done(s)


static func _road_ahead(t) -> void:
	var s := _world(PackedStringArray(["whisper", "discord"]))
	var grid: WalkGrid = (s.crowd as Crowd)._grid
	var p: Person = (s.crowd as Crowd).citizens[0]
	p.inside = false
	p.ground_pos = grid.nearest_walkable(Vector2(0, 10))  # the open paving south of the market
	p.go_duty(p.ground_pos)
	t.check(GodT1.road_ahead(p, 3.0) == p.ground_pos, "with nowhere to go he is where he stands")
	var from := p.ground_pos
	p.set_goal(grid.nearest_walkable(Vector2(0, -2)))
	var ahead := GodT1.road_ahead(p, 2.0)
	var reach := p.walk_speed * 2.0
	t.check(ahead.distance_to(from) > 0.1 and ahead.distance_to(from) <= reach + 0.01,
		"on his road he is up to walk_speed x seconds on (%.2f of %.2f)" % [ahead.distance_to(from), reach])
	t.check(GodT1.road_ahead(p, 0.0) == from, "no seconds, no distance")
	_done(s)


static func _plague_aim(t) -> void:
	var s := _world(PackedStringArray(["pestilence", "deathmark"]))
	var crowd: Crowd = s.crowd
	var a: Person = crowd.citizens[0]
	var b: Person = crowd.citizens[1]
	var c: Person = crowd.citizens[2]
	for e in crowd._field.alive():
		if e != a and e != b and e != c:
			e.ground_pos = Vector2(-200, -200)
	a.ground_pos = Vector2(0, 0)
	b.ground_pos = Vector2(0.5, 0)
	c.ground_pos = Vector2(5, 0)
	var aim := GodT1.plague_aim(crowd, Vector2(0.2, 0))
	var taken := PestilenceFx.victims_at(crowd._field, aim)
	t.check(aim != Vector2.INF and a in taken and b in taken, "the aim takes the two together")
	t.check(GodT1.plague_aim(crowd, Vector2(0.2, 0), [a, b]) == Vector2.INF, "avoiding both, no aim by them takes anyone")
	var apart := GodT1.plague_aim(crowd, Vector2(4.5, 0), [a, b])
	t.check(apart != Vector2.INF and PestilenceFx.victims_at(crowd._field, apart) == [c], "and the one apart is taken alone")
	t.check(GodT1.plague_aim(crowd, Vector2(60, 60)) == Vector2.INF, "where nobody stands, no aim")
	_done(s)


static func _casts(t) -> void:
	var s := _world(PackedStringArray(["mirror", "belllies"]))
	var rules: Rules = s.rules
	var ctx := {"rules": rules, "slots": s.slots}
	var bc := FakeBc.new()
	var calls: Array = s.calls
	t.check(GodT1.cast_mirror(bc, ctx, Vector2(1, 17), Vector2(1, 22)), "the mirror is cast when ready")
	t.check(calls.size() == 1 and calls[0].at == Vector2(1, 17) and calls[0].extra.to == Vector2(1, 22), "in at the first spot, out at the second")
	t.check(not GodT1.cast_mirror(bc, ctx, Vector2(1, 17), Vector2(1, 22)) and calls.size() == 1, "and not again while it cools")
	# The bell: only its two modes.
	t.check(not GodT1.cast_bell(bc, ctx, "sing", Vector2.ZERO) and calls.size() == 1, "a mode the bell has not is refused")
	t.check(GodT1.cast_bell(bc, ctx, "guard", Vector2(3, 4)), "the bell calls the guard when ready")
	t.check(calls.size() == 2 and calls[1].at == Vector2(3, 4) and calls[1].extra.mode == "guard", "to the place given, in the mode given")
	_done(s)
