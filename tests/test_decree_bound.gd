extends RefCounted
## Bound in Law (Decree, Tier II; spec 5.4): click one person, then another within REACH of him, and for SPAN a thin brass
## chain of light joins them and they share one fate. Polled both every frame, the onset of each state on one is laid on the
## other once: a hurt (the same amount), knocked down, stunned (the same seconds), asleep (the same seconds), held by a
## seizure (the other is held where he stands while the first is held), dead (the other dies too, kind bound). A mirrored
## onset never mirrors back. A second click farther than REACH from the first is refused before the cast (no cooldown). After
## SPAN harm no longer passes; a partner freed mid-link drops the link without a word. Quiet.

const PATH := "res://src/fx/decree/bound_in_law.gd"
const DT := 0.1
const Breath := preload("res://tests/test_decree_breath.gd")
const Redefine := preload("res://tests/test_decree_redefine.gd")


static func run(t) -> void:
	_book(t)
	_hurt(t)
	_sleep_and_death(t)
	_states(t)
	_refused(t)
	_span_and_freed(t)


static func _book(t) -> void:
	var b := PowerBook.get_power("bound")
	var area: Dictionary = Targeting.AREAS.get("bound", {})
	t.check(String(b.get("name", "")) == "Bound in Law" and int(b.get("dp", 0)) == 3 and float(b.get("cooldown", 0.0)) == 45.0
		and String(b.get("aim", "")) == "two clicks" and PowerBook.is_quiet("bound") and PowerBook.authority_of("bound") == "decree"
		and ResourceLoader.exists(String(b.get("path", ""))) and String(area.get("shape", "")) == "pick"
		and Rules.POWER_KINDS.get("bound", null) == [&"bound"] and PowerBook.family("bound") == "decree"
		and not PowerBook.REACH.has("bound") and not PowerBook.IMPACT.has("bound"),
		"Bound in Law: Decree, 3 Might, 45 s, two clicks, quiet (%s)" % [b])
	var script: GDScript = load(PATH)
	if script == null:
		return
	var c: Dictionary = script.get_script_constant_map()
	t.check(is_equal_approx(float(c.get("REACH", 0.0)), 10.0) and is_equal_approx(float(c.get("SPAN", 0.0)), 20.0)
		and is_equal_approx(float(area.get("r", 0.0)), float(c.get("PICK_R", -1.0))),
		"REACH 10, SPAN 20 s, and the aim's mark is PICK_R")


## Two citizens `apart` from each other on the open market square, everyone else out of the way, each with `hp` health.
static func _pair(made: Array, apart := 3.0, hp := 100.0) -> Array:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	Redefine._scatter(crowd)
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var a: Person = crowd.citizens[0]
	var b: Person = crowd.citizens[1]
	a.ground_pos = at
	b.ground_pos = at + Vector2(apart, 0.0)
	a.health = hp
	b.health = hp
	return [a, b]


static func _bind(made: Array, a: Person, b: Person) -> FxTimeline:
	return FxTimeline.cast(load(PATH), made[5], a.ground_pos, {"to": b.ground_pos})


## a.hurt(30): b loses 30, once; a loses 30 in all (no ping-pong). The same the other way.
static func _hurt(t) -> void:
	var made: Array = Breath._setup()
	var ab := _pair(made)
	var a: Person = ab[0]
	var b: Person = ab[1]
	var fx := _bind(made, a, b)
	t.check(fx.get("a") == a and fx.get("b") == b and bool(fx.get("linked")), "the first click binds a, the second b")
	t.check(LawMark.kind_of(a) == &"bound" and LawMark.kind_of(b) == &"bound", "both are BOUND by law (the badge)")
	a.hurt(30.0, null)
	Breath._run([fx], 0.3)
	t.check(is_equal_approx(b.health, 70.0) and is_equal_approx(a.health, 70.0),
		"a struck for 30: b loses 30 too, and a 30 in all (a %.1f, b %.1f)" % [a.health, b.health])
	Breath._run([fx], 1.0)
	t.check(is_equal_approx(b.health, 70.0) and is_equal_approx(a.health, 70.0),
		"once only: nothing passes back and forth (a %.1f, b %.1f)" % [a.health, b.health])
	b.hurt(10.0, null)
	Breath._run([fx], 0.5)
	t.check(is_equal_approx(a.health, 60.0) and is_equal_approx(b.health, 60.0), "b struck for 10: a loses 10 (a %.1f, b %.1f)" % [a.health, b.health])
	fx.end_now()
	# A blow the other cannot take kills him -- by the bond -- and a dies with him.
	a.health = 100.0
	b.health = 5.0
	var fx2 := _bind(made, a, b)
	a.hurt(20.0, null)
	Breath._run([fx2], DT)
	t.check(not b.is_alive() and b._kind == &"bound", "a blow more than b has left kills b, kind bound")
	t.check(not a.is_alive() and a._kind == &"bound" and not bool(fx2.get("linked")), "and a dies with him: one fate")
	fx2.end_now()
	Breath._done(made)


## a.sleep(10): b sleeps 10 too; a dies: b dies.
static func _sleep_and_death(t) -> void:
	var made: Array = Breath._setup()
	var ab := _pair(made)
	var a: Person = ab[0]
	var b: Person = ab[1]
	var fx := _bind(made, a, b)
	a.sleep(10.0)
	Breath._run([fx], DT)
	t.check(b.is_asleep() and is_equal_approx(b.sleep_left(), 10.0) and is_equal_approx(a.sleep_left(), 10.0),
		"a falls asleep for 10 s: b sleeps, for 10 s (b %.2f)" % b.sleep_left())
	b.wake()
	a.wake()
	Breath._run([fx], DT)
	t.check(not a.is_asleep() and not b.is_asleep(), "waking is no onset: neither is put back to sleep")
	(made[3] as EnemyField).kill(a, &"frenzy")
	Breath._run([fx], DT)
	t.check(not b.is_alive() and b._kind == &"bound" and a._kind == &"frenzy", "a dies: b dies too, kind bound")
	t.check(not bool(fx.get("linked")) and LawMark.kind_of(b) == &"", "the bond is over: its law lifted")
	fx.end_now()
	Breath._done(made)


## Knocked down, stunned (the same seconds), held by a seizure (the other held where he stands while the first is held).
static func _states(t) -> void:
	var made: Array = Breath._setup()
	var ab := _pair(made)
	var a: Person = ab[0]
	var b: Person = ab[1]
	var fx := _bind(made, a, b)
	a.knock_down()
	Breath._run([fx], DT)
	t.check(b.is_down(), "a knocked down: b is too")
	b.stun(4.0)
	Breath._run([fx], DT)
	t.check(is_equal_approx(a.wait, 4.0) and is_equal_approx(b.wait, 4.0), "b stunned 4 s: a is stunned 4 s (a %.2f)" % a.wait)
	Breath._run([fx], 0.5)
	t.check(is_equal_approx(a.wait, 4.0) and is_equal_approx(b.wait, 4.0), "and nothing passes back (a %.2f, b %.2f)" % [a.wait, b.wait])
	# Held by a seizure: a rite's chain, or a mission's seizer (MissionDirector.is_seized).
	a.chained = true
	Breath._run([fx], DT)
	t.check(b.pace_hold() == 0.0 and a.pace_hold() == 1.0, "a seized: b is held where he stands; a's own pace is untouched")
	Breath._run([fx], 1.0)
	t.check(b.pace_hold() == 0.0, "for as long as a is held")
	a.chained = false
	Breath._run([fx], DT)
	t.check(b.pace_hold() == 1.0, "a let go: b walks again")
	a.chained = true
	Breath._run([fx], DT)
	fx.end_now()
	t.check(b.pace_hold() == 1.0 and LawMark.kind_of(a) == &"" and LawMark.kind_of(b) == &"",
		"ended early, the hold and the law are lifted")
	a.chained = false
	var esc := EscortDirector.new()
	var c := EscortDirector.Charge.new()
	c.man = a
	esc.charges.append(c)
	var seized_before: bool = esc.is_seized(a)
	c.held = true
	t.check(not MissionDirector.new().is_seized(a) and not seized_before and esc.is_seized(a) and not esc.is_seized(b),
		"a mission's seized charge is held (EscortDirector.is_seized); no other director seizes")
	Breath._done(made)


## Rules: a second click farther than REACH from the first, or on no one, is refused: no cast, no cooldown.
static func _refused(t) -> void:
	var made: Array = Breath._setup()
	var ab := _pair(made, 12.0)
	var a: Person = ab[0]
	var b: Person = ab[1]
	var crowd: Crowd = made[0]
	var rules := Rules.new().setup(PackedStringArray(["bound"]), null, made[1], made[3], crowd, made[6])
	var casts: Array = []
	rules.caster = func(_script: GDScript, ground: Vector2, extra: Dictionary) -> FxTimeline:
		casts.append([ground, extra])
		return null
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, reason: String): refused.append([slot, reason]))
	t.check(rules.cast(0, a.ground_pos, {"to": b.ground_pos}) == null and refused == [[0, "far"]] and casts.is_empty()
		and rules.cooldown_left(0) == 0.0, "the second 12 from the first is refused as too far: no cast, no cooldown (%s)" % [refused])
	refused.clear()
	t.check(rules.cast(0, a.ground_pos, {"to": a.ground_pos + Vector2(0.0, 5.0)}) == null and refused == [[0, "unbound"]]
		and casts.is_empty() and rules.cooldown_left(0) == 0.0, "a second click on no one is refused (%s)" % [refused])
	refused.clear()
	t.check(rules.cast(0, a.ground_pos, {"to": a.ground_pos}) == null and refused == [[0, "unbound"]] and casts.is_empty(),
		"the same man twice is refused")
	refused.clear()
	b.ground_pos = a.ground_pos + Vector2(9.5, 0.0)
	rules.cast(0, a.ground_pos, {"to": b.ground_pos})
	t.check(refused.is_empty() and casts.size() == 1 and rules.cooldown_left(0) == 45.0, "within 10: cast, and the 45 s cooldown starts")
	rules.teardown()
	rules.free()
	# Cast round Rules (a scripted route): the effect binds nobody and ends.
	var fx := FxTimeline.cast(load(PATH), made[5], a.ground_pos, {"to": a.ground_pos + Vector2(0.0, 5.0)})
	t.check(not bool(fx.get("linked")) and LawMark.kind_of(a) == &"", "cast on no second man, nothing is bound")
	fx.end_now()
	Breath._done(made)


## After SPAN harm no longer passes and the law is lifted; a partner freed mid-link drops the link without error.
static func _span_and_freed(t) -> void:
	var made: Array = Breath._setup()
	var ab := _pair(made)
	var a: Person = ab[0]
	var b: Person = ab[1]
	var fx := _bind(made, a, b)
	var span := float((load(PATH) as GDScript).get_script_constant_map().get("SPAN", 0.0))
	Breath._run([fx], span - 0.5)
	a.hurt(10.0, null)
	Breath._run([fx], DT)
	t.check(is_equal_approx(b.health, 90.0), "at 19.5 s harm still passes")
	Breath._run([fx], 0.6)
	a.hurt(10.0, null)
	Breath._run([fx], DT)
	t.check(is_equal_approx(b.health, 90.0) and is_equal_approx(a.health, 80.0) and not bool(fx.get("linked"))
		and LawMark.kind_of(a) == &"" and LawMark.kind_of(b) == &"", "after 20 s it no longer passes, and the law is lifted")
	fx.end_now()

	var crowd: Crowd = made[0]
	var c: Person = crowd.citizens[2]
	c.ground_pos = a.ground_pos + Vector2(0.0, 2.0)
	var fx2 := _bind(made, a, c)
	c.chained = true
	Breath._run([fx2], DT)
	var held := a.pace_hold() == 0.0
	(made[3] as EnemyField).remove(c)
	crowd.citizens.erase(c)
	c.free()
	Breath._run([fx2], DT)
	t.check(held and not bool(fx2.get("linked")) and LawMark.kind_of(a) == &"" and a.pace_hold() == 1.0 and a.is_alive(),
		"the partner freed mid-link: the link is dropped, a let go and alive")
	a.hurt(5.0, null)
	Breath._run([fx2], DT)
	fx2.end_now()
	Breath._done(made)
