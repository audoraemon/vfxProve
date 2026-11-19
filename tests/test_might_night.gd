extends RefCounted
## Mission and the Might gauge: each act's Rules gets the pool and the seal from the def (or the bots' tier), never in a Remembrance,
## the night's cast keys are the union over its acts, and a board mission has no pool.
## A real Mission cannot be started in the headless suite, so the hooks are driven on a bare Mission with bare Rules.


static func run(t) -> void:
	_board(t)
	_gauge_def(t)
	_tier(t)
	_remembrance(t)
	_acts(t)


## A def that is a gauge night of `size` and `seconds`, sealed on `sealed`.
static func _def(size: int, seconds: float, sealed := "") -> MissionDef:
	var d := MissionDef.new()
	d.might_capacity = size
	d.might_refill = seconds
	d.sealed = sealed
	return d


## A Mission with bare Rules armed from `d`; the caller frees both.
static func _armed(d: MissionDef, tier := 0, memory := "") -> Mission:
	var m := Mission.new()
	m.might_tier = tier
	m.remembrance = memory
	m._rules = Rules.new()
	m._arm_might(d)
	return m


static func _drop(m: Mission) -> void:
	m._rules.free()
	m._rules = null
	m.free()


static func _board(t) -> void:
	var m := _armed(TierBook.board("warning", null))
	t.check(m._rules.might == null and m._rules.sealed == "", "a board mission has no pool and no seal")
	t.check(m.cast_keys().is_empty(), "and has cast nothing yet")
	_drop(m)


static func _gauge_def(t) -> void:
	var m := _armed(_def(8, 55.0, "heaven"))
	var p: MightPool = m._rules.might
	t.check(p != null and p.capacity == 8.0 and is_equal_approx(p.refill_seconds, 55.0) and is_equal_approx(p.value, 8.0),
		"a gauge def gives a full pool of 8, refill 55 s")
	t.check(m._rules.sealed == "heaven", "and the seal (%s)" % m._rules.sealed)
	_drop(m)


static func _tier(t) -> void:
	var m := _armed(TierBook.board("warning", null), 1)
	var p: MightPool = m._rules.might
	t.check(p != null and p.capacity == 6.0 and is_equal_approx(p.refill_seconds, 60.0), "might_tier 1 on a board def: a pool of 6 / 60")
	_drop(m)
	m = _armed(_def(8, 55.0), 1)
	t.check(m._rules.might.capacity == 6.0, "the bots' tier wins over the def's own gauge")
	_drop(m)


static func _remembrance(t) -> void:
	var m := _armed(_def(8, 55.0, "heaven"), 0, "wisp")
	t.check(m._rules.might == null and m._rules.sealed == "", "a Remembrance has no pool and no seal, whatever the def says")
	_drop(m)
	m = _armed(_def(8, 55.0), 1, "wisp")
	t.check(m._rules.might == null, "nor with the bots' tier")
	_drop(m)


static func _acts(t) -> void:
	var one := _def(8, 55.0, "heaven")
	var m := _armed(one)
	m._rules.might.pay(5.0)
	m._rules.cast_keys.append("tsunami")
	t.check(m.cast_keys() == PackedStringArray(["tsunami"]), "the act's own cast keys show at once")
	m._carry_cast()
	m._rules.free()
	m._rules = Rules.new()
	m._arm_might(_def(8, 55.0, "heaven"))
	t.check(is_equal_approx(m._rules.might.value, 8.0), "the next act's pool starts full")
	m._rules.cast_keys.append("cinder")
	m._rules.cast_keys.append("tsunami")
	t.check(m.cast_keys() == PackedStringArray(["tsunami", "cinder"]), "the night's cast keys hold both acts', once each (%s)" % [m.cast_keys()])
	_drop(m)
