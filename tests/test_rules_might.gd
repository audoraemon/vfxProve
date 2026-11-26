extends RefCounted
## Rules and the Might gauge: an optional pool pays for casts, a sealed key is refused, the Temple's fall refills, and with no pool
## nothing changes.


## A stub power that takes a follow-up click, so recast() has a live effect to reach.
class Followable extends FxTimeline:
	func can_follow_up() -> bool:
		return true

	func follow_up(_at: Vector2, _extra: Dictionary) -> bool:
		return true


static func run(t) -> void:
	_no_pool(t)
	_pool(t)
	_sealed(t)
	_recast(t)


## A Rules over a bare town with a caster that casts nothing; `env` comes back through `out` for the surge test.
static func _rules(loadout: PackedStringArray, out := {}) -> Rules:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var field := EnemyField.new()
	field.env = env
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, WalkGrid.new().setup(env, town), world, 5)
	var rules := Rules.new().setup(loadout, null, env, field, crowd, town)
	rules.caster = func(_script: GDScript, _ground: Vector2, _extra: Dictionary) -> FxTimeline:
		return null
	out["env"] = env
	return rules


## With no pool the same script of casts gives the same refusals as a control, and the result lists what was cast.
static func _no_pool(t) -> void:
	var keys := PackedStringArray(["heaven", "tsunami", "cinder"])
	var a := _rules(keys)
	var b := _rules(keys)
	t.check(a.might == null and a.sealed == "" and a.cast_keys.is_empty(), "a fresh Rules has no pool, no seal and no cast keys")
	var seen_a: Array = []
	var seen_b: Array = []
	for slot in [0, 1, 0, 2, 3]:
		seen_a.append(a.refusal(slot))
		seen_b.append(b.refusal(slot))
		a.cast(slot, Vector2.ZERO)
		b.cast(slot, Vector2.ZERO)
	t.check(seen_a == seen_b and seen_a == ["", "", "cooldown", "", "empty"], "no pool: the refusals are today's (%s)" % [seen_a])
	t.check(a.might_cost(3) == 0 and a.might_cost(0) == 2, "might_cost: 0 for an empty slot, the power's cost otherwise (%d, %d)" % [a.might_cost(3), a.might_cost(0)])
	t.check(a.cast_keys == PackedStringArray(["heaven", "tsunami", "cinder"]), "cast_keys lists the keys in first-cast order (%s)" % [a.cast_keys])
	t.check(a.result().get("cast") == PackedStringArray(["heaven", "tsunami", "cinder"]), "result().cast carries them (%s)" % [a.result().get("cast")])


## A pool pays on cast and refuses what it cannot pay; advance() refills; the surge fills it.
static func _pool(t) -> void:
	var out := {}
	var rules := _rules(PackedStringArray(["heaven", "whisper"]), out)
	rules.might = MightPool.make(6)
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, reason: String): refused.append([slot, reason]))
	for i in 3:
		rules._cooldowns.fill(0.0)
		rules.cast(0, Vector2.ZERO)
	t.near(rules.might.value, 0.0, 0.0001, "three 2-Might casts empty a size-6 pool (%.2f)" % rules.might.value)
	rules._cooldowns.fill(0.0)
	t.check(rules.refusal(0) == "might", "the fourth is refused for Might (%s)" % rules.refusal(0))
	rules.cast(0, Vector2.ZERO)
	t.check(refused.back() == [0, "might"], "and cast_refused says so (%s)" % [refused])
	t.check(rules.cooldown_left(0) == 0.0 and rules.might.value == 0.0 and rules.cast_keys.size() == 1,
		"no cooldown starts and the pool is unchanged")
	t.check(rules.cast_keys == PackedStringArray(["heaven"]), "cast_keys holds a key once after three casts (%s)" % [rules.cast_keys])

	rules._cooldowns[0] = 5.0
	t.check(rules.refusal(0) == "cooldown", "on cooldown and unaffordable: the cooldown is named first (%s)" % rules.refusal(0))
	rules._cooldowns.fill(0.0)

	refused.clear()
	rules.might.refill()
	rules.cast(1, Vector2.ZERO)
	t.check(refused.back() == [1, "nobody"] and rules.might.value == 6.0 and not rules.cast_keys.has("whisper"),
		"a refused whisper pays nothing and is not a cast key (%s, %.1f)" % [refused, rules.might.value])

	rules.might.pay(6.0)
	rules.advance(30.0)
	t.near(rules.might.value, 3.0, 0.0001, "advance(30) refills half of a size-6 pool (%.2f)" % rules.might.value)

	var free := _rules(PackedStringArray(["heaven"]))
	free.might = MightPool.make(6)
	free.free_play = true
	free.cast(0, Vector2.ZERO)
	t.check(free.might.value == 6.0 and free.cast_keys == PackedStringArray(["heaven"]), "free play pays nothing (%.1f)" % free.might.value)

	var surge := _rules(PackedStringArray(["heaven"]), out)
	surge.might = MightPool.make(6)
	surge.might.pay(6.0)
	var temple: Structure = null
	for s in (out.env as EnvironmentField).structures():
		if s.role == &"temple":
			temple = s
	temple.destroy(temple.center(), &"nova")
	t.check(surge.surged_once and surge.might.value == 6.0, "the Divine Surge refills the pool (%.1f)" % surge.might.value)


## A sealed key is refused before the cooldown, pays nothing and is never a cast key.
static func _sealed(t) -> void:
	var rules := _rules(PackedStringArray(["heaven", "tsunami"]))
	rules.might = MightPool.make(6)
	rules.sealed = "heaven"
	rules._cooldowns[0] = 9.0
	t.check(rules.refusal(0) == "sealed", "a sealed key is refused before its cooldown (%s)" % rules.refusal(0))
	rules._cooldowns[0] = 0.0
	rules.cast(0, Vector2.ZERO)
	t.check(rules.might.value == 6.0 and rules.cast_keys.is_empty() and rules.cooldown_left(0) == 0.0,
		"it pays nothing and is not a cast key")
	t.check(rules.refusal(1) == "", "the other keys cast on")


## A live power's follow-up is free: recast() at 0 Might goes through.
static func _recast(t) -> void:
	var rules := _rules(PackedStringArray(["heaven"]))
	rules.might = MightPool.make(6)
	var fx := Followable.new()
	fx.duration = 1.0
	fx.busy = 0.0
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline:
		return fx
	rules.cast(0, Vector2.ZERO)
	rules.might.pay(rules.might.value)
	t.check(rules.recast(0, Vector2.ZERO) and rules.might.value == 0.0, "a follow-up recast costs no Might")
	fx.free()
