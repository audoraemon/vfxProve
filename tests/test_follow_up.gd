extends RefCounted
## The one way a live power takes a follow-up order (Called Bolts, Procession, Sleepwalk, Second Word, Turn the Tide): an FxTimeline with
## can_follow_up() / follow_up(at, extra) [/ follow_up_area()] is reached by Rules.recast() / can_recast() / follow_up_area(), and by a
## real Targeting's click (which aims as a plain click while the slot can take one, whatever its own aim kind). No cooldown, no cast_made.

const P := Vector2(4.0, 5.0)


## A stand-in for an effect that takes orders.
class Stub extends FxTimeline:
	var open := true
	var got: Array = []

	func can_follow_up() -> bool:
		return open

	func follow_up(at_pos: Vector2, extra_data: Dictionary) -> bool:
		if not open:
			return false
		got.append([at_pos, extra_data])
		return true

	func follow_up_area() -> Dictionary:
		return {"shape": "circle", "r": 1.0}


static func run(t) -> void:
	_rules(t)
	_targeting(t)


static func _world() -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, WalkGrid.new().setup(env, town), world, 5)
	return [env, town, field, world, crowd]


static func _free(made: Array) -> void:
	(made[4] as Crowd).clear()
	(made[3] as Node).free()
	(made[1] as Node).free()


static func _rules(t) -> void:
	var made := _world()
	var rules := Rules.new().setup(PackedStringArray(["wisp", "doom"]), null, made[0], made[2], made[4], made[1])
	var stub := Stub.new()
	stub.duration = 30.0
	stub.busy = 1.0
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline:
		return stub
	var casts: Array = []
	var called: Array = []
	rules.cast_made.connect(func(slot: int, key: String, _at: Vector2): casts.append([slot, key]))
	rules.recast_made.connect(func(slot: int, key: String, at: Vector2): called.append([slot, key, at]))
	t.check(not rules.recast(0, P) and not rules.can_recast(0) and rules.follow_up_area(0).is_empty(), "with nothing running, recast is false and there is no area")
	rules.cast(0, P)
	t.check(casts == [[0, "wisp"]] and rules.live_fx("wisp") == stub, "a cast puts the stub in play")
	var left := rules.cooldown_left(0)
	t.check(not rules.recast(0, P, {"mode": "halt"}) and not rules.can_recast(0) and called.is_empty() and stub.got.is_empty(),
		"while the cast's busy lock holds, recast is false")
	stub.t = 1.5
	t.check(rules.can_recast(0) and rules.follow_up_area(0) == {"shape": "circle", "r": 1.0}, "after the busy lock the slot can take an order, and the area is the stub's")
	t.check(rules.recast(0, P, {"mode": "halt"}), "recast(slot, p, {mode}) is true")
	t.check(stub.got == [[P, {"mode": "halt"}]], "the extra is handed through to follow_up (%s)" % [stub.got])
	t.check(called == [[0, "wisp", P]] and casts.size() == 1 and is_equal_approx(rules.cooldown_left(0), left),
		"recast_made is sent; no cast_made, the cooldown is untouched")
	t.check(not rules.recast(1, P) and not rules.recast(7, P) and not rules.can_recast(-1) and rules.follow_up_area(-1).is_empty(),
		"another slot, an empty one or none is never recast")
	stub.open = false
	t.check(not rules.recast(0, P) and not rules.can_recast(0) and rules.follow_up_area(0).is_empty() and called.size() == 1,
		"when the effect cannot take one, recast is false and the area is empty")
	stub.open = true
	stub.finished = true
	t.check(not rules.recast(0, P) and not rules.can_recast(0), "after the effect has finished, recast is false")
	stub.finished = false
	rules.free()
	stub.free()
	_free(made)


## The stub's slot is "Sacred Sanctuary", whose own aim is "two clicks" with a mode (circle / rect): while it can take an order, a click is
## one, handed the mode; the HUD's slot_state is what it was.
static func _targeting(t) -> void:
	var made := _world()
	var crowd: Crowd = made[4]
	var rules := Rules.new().setup(PackedStringArray(["sanctuary", "doom"]), null, made[0], made[2], crowd, made[1])
	var stub := Stub.new()
	stub.duration = 30.0
	stub.busy = 1.0
	stub.t = 2.0
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline:
		return stub
	var casts: Array = []
	var called: Array = []
	rules.cast_made.connect(func(slot: int, key: String, _at: Vector2): casts.append([slot, key]))
	rules.recast_made.connect(func(slot: int, _key: String, at: Vector2): called.append([slot, at]))
	var aim := Targeting.new().setup(rules, crowd)
	var hud := Hud.new().setup(rules, crowd, made[1], aim)
	aim.pick(0)
	t.check(aim._aim_kind() == "two clicks", "with nothing running the slot aims as its own kind (two clicks)")
	aim.press(P)
	aim.release(P)
	t.check(aim.placed and casts.is_empty() and called.is_empty(), "so the first click only places the first spot")
	aim.cancel()
	rules.cast(0, P, {"to": P + Vector2(2.0, 0.0)})
	t.check(casts == [[0, "sanctuary"]] and rules.live_fx("sanctuary") == stub, "the cast is in play")
	var left := rules.cooldown_left(0)
	var state := hud.slot_state(0)
	aim.pick(0)
	t.check(rules.can_recast(0) and aim._aim_kind() == "click" and not aim._is_twice() and aim.area() == {"shape": "circle", "r": 1.0},
		"while the stub takes orders the slot aims as a click, and the preview is the stub's area (%s)" % aim._aim_kind())
	aim.press(P)
	aim.release(P)
	t.check(called == [[0, P]] and casts.size() == 1 and not aim.placed and aim.slot == 0 and is_equal_approx(rules.cooldown_left(0), left),
		"a press and release reaches recast, not cast: recast_made, no cast_made, still focused, cooldown untouched")
	t.check(stub.got.size() == 1 and stub.got[0][1] == {"mode": "circle"}, "and the mode is handed to follow_up (%s)" % [stub.got])
	t.check(hud.slot_state(0) == state and state == "cooldown", "the HUD's slot_state is what it was (%s)" % hud.slot_state(0))
	stub.open = false
	t.check(aim._aim_kind() == "two clicks" and aim.area() != {"shape": "circle", "r": 1.0}, "when the stub stops taking orders the slot is its own kind again")
	aim.free()
	hud.free()
	rules.free()
	stub.free()
	_free(made)
