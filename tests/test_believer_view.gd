extends RefCounted
## World Map + Conquer Progress Task 4: the believer view (B): gold head marks over living believers, and "N believers" in the aim.


static func run(t) -> void:
	_off_by_default(t)
	_marks_on(t)
	_marks_off_again(t)
	_in_shape(t)
	_aim_count(t)
	_toggle_key(t)
	_all_tags_lead(t)
	_outline_input(t)
	_signature_quiet(t)
	_legend_excludes(t)
	_signature_follows(t)


static func _world() -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()
	var rules := Rules.new().setup(PackedStringArray(["doom", "tsunami", "cinder", "nova"]), null, env, field, crowd, town)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var aim := Targeting.new().setup(rules, crowd)
	var hud := Hud.new().setup(rules, crowd, town, aim)
	var folk: Array[Person] = []
	for p in crowd.citizens:
		if not p.soldier and p.profile != null and folk.size() < 6:
			folk.append(p)
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "aim": aim, "hud": hud, "folk": folk}


static func _done(s: Dictionary) -> void:
	(s.hud as Hud).free()
	(s.aim as Targeting).free()
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


static func _believe(s: Dictionary, n: int) -> void:
	for i in n:
		(s.folk[i] as Person).profile.faith = CitizenProfile.Faith.BELIEVER


static func _off_by_default(t) -> void:
	var s := _world()
	_believe(s, 5)
	var hud: Hud = s.hud
	t.check(not hud.believer_view and hud.believer_tags().is_empty(), "the believer view is off by default: no marks")
	t.check((s.aim as Targeting).believers_text() == "", "and the aim says nothing about believers")
	_done(s)


static func _marks_on(t) -> void:
	var s := _world()
	_believe(s, 5)
	var hud: Hud = s.hud
	hud.believer_view = true
	var tags := hud.believer_tags()
	t.check(tags.size() == 5, "view on: one mark for each of 5 believers (%d)" % tags.size())
	var ok := true
	for m in tags:
		ok = ok and m.who is Person and (m.who as Person).profile.faith == CitizenProfile.Faith.BELIEVER and m.label == "" \
			and m.color == Hud.BELIEVER_COL and is_equal_approx(m.lift, Hud.BELIEVER_LIFT)
	t.check(ok, "each mark is on a believer, unlabelled, gold, lifted BELIEVER_LIFT")
	t.check(Hud.BELIEVER_LIFT < MapTag.PERSON_LIFT, "the gold mark sits under a mission's diamond")
	var dead: Person = s.folk[0]
	(s.field as EnemyField).kill(dead, &"test")
	tags = hud.believer_tags()
	var has_dead := false
	for m in tags:
		has_dead = has_dead or m.who == dead
	t.check(tags.size() == 4 and not has_dead, "a dead believer has no mark (%d)" % tags.size())
	_done(s)


static func _marks_off_again(t) -> void:
	var s := _world()
	_believe(s, 5)
	var hud: Hud = s.hud
	hud.believer_view = true
	hud.believer_view = false
	t.check(hud.believer_tags().is_empty(), "on then off: no marks")
	_done(s)


static func _in_shape(t) -> void:
	var o := Vector2.ZERO
	var x := Vector2(1, 0)
	var circle := {"shape": "circle", "r": 1.0}
	t.check(Targeting.in_shape(circle, o, x, 0.0, Vector2(0.9, 0)) and not Targeting.in_shape(circle, o, x, 0.0, Vector2(1.1, 0)),
		"circle: 0.9 in, 1.1 out")
	var sq := {"shape": "square", "half": 1.0}
	t.check(Targeting.in_shape(sq, o, x, 0.0, Vector2(0.9, 0.9)) and not Targeting.in_shape(sq, o, x, 0.0, Vector2(1.1, 0)),
		"square: (0.9, 0.9) in, (1.1, 0) out")
	var lane := {"shape": "lane", "half": 0.5}
	t.check(Targeting.in_shape(lane, o, x, 4.0, Vector2(3, 0.4)) and not Targeting.in_shape(lane, o, x, 4.0, Vector2(3, 0.6))
		and not Targeting.in_shape(lane, o, x, 4.0, Vector2(5, 0)), "lane: along it in, beside it out, past its end out")
	var cone := {"shape": "cone", "r": 2.0, "arc": 90.0}
	t.check(Targeting.in_shape(cone, o, x, 0.0, Vector2(1, 0.5)) and not Targeting.in_shape(cone, o, x, 0.0, Vector2(0, 1)),
		"cone: ahead in, to the side out")
	t.check(not Targeting.in_shape({"shape": "wheel", "r": 5.0}, o, x, 0.0, Vector2(0.1, 0)), "any other shape is false")
	for shape in ["pick", "regions", "gather"]:
		t.check(Targeting.in_shape({"shape": shape, "r": 1.0}, o, x, 0.0, Vector2(0.5, 0)), "%s counts as a circle" % shape)


static func _aim_count(t) -> void:
	var s := _world()
	_believe(s, 4)
	var aim: Targeting = s.aim
	aim.pick(0)
	var r := float(aim.area().r)
	aim._press = Vector2(10, 10)
	for i in 3:
		(s.folk[i] as Person).ground_pos = Vector2(10, 10) + Vector2(r * 0.5, 0)
	(s.folk[3] as Person).ground_pos = Vector2(10, 10) + Vector2(r * 3.0, 0)
	t.check(aim.believers_text() == "", "view off: no text")
	aim.believer_view = true
	t.check(aim.aim_at() == Vector2(10, 10), "aim_at is the press point")
	t.check(aim.believers_in() == 3 and aim.believers_text() == "3 believers", "3 inside, 1 outside: '3 believers' (%s)" % aim.believers_text())
	(s.folk[1] as Person).ground_pos = Vector2(10, 10) + Vector2(r * 3.0, 0)
	(s.folk[2] as Person).ground_pos = Vector2(10, 10) + Vector2(r * 3.0, 0)
	t.check(aim.believers_text() == "1 believer", "one inside: '1 believer' (%s)" % aim.believers_text())
	(s.folk[0] as Person).ground_pos = Vector2(10, 10) + Vector2(r * 3.0, 0)
	t.check(aim.believers_text() == "", "none inside: no text")
	aim.unfocus()
	(s.folk[0] as Person).ground_pos = Vector2(10, 10)
	t.check(aim.believers_in() == 0, "no slot focused: 0")
	_done(s)


static func _key(code: Key, pressed := true, echo := false, ctrl := false) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = pressed
	e.echo = echo
	e.ctrl_pressed = ctrl
	return e


static func _toggle_key(t) -> void:
	t.check(Mission.toggles_believers(_key(KEY_B)), "B pressed toggles")
	t.check(not Mission.toggles_believers(_key(KEY_B, true, true)), "B echo does not")
	t.check(not Mission.toggles_believers(_key(KEY_B, false)), "B released does not")
	t.check(not Mission.toggles_believers(_key(KEY_B, true, false, true)), "Ctrl+B does not")
	t.check(not Mission.toggles_believers(_key(KEY_H)), "H does not")


static func _all_tags_lead(t) -> void:
	var s := _world()
	_believe(s, 3)
	var hud: Hud = s.hud
	hud.believer_view = true
	var all := hud.all_tags()
	var mine := hud.believer_tags()
	var ok := all.size() >= mine.size() and not mine.is_empty()
	for i in mine.size():
		ok = ok and all[i].who == mine[i].who and all[i].color == Hud.BELIEVER_COL
	t.check(ok, "all_tags() draws the believer marks first (under the mission's) when the view is on")
	_done(s)


## Final review 1: the covered-outline layer reads outline_tags(): the mission's own tags, never the believer pips (20+ of them would
## take the 12 slots in tag order and colour a granted wisher gold). A mission's person keeps its place and colour with them present.
static func _outline_input(t) -> void:
	var s := _world()
	var hud: Hud = s.hud
	var folk: Array[Person] = []
	for p in (s.crowd as Crowd).citizens:
		if not p.soldier and p.profile != null:
			folk.append(p)
	for i in 24:
		folk[i].profile.faith = CitizenProfile.Faith.BELIEVER
	hud.believer_view = true
	var all := hud.all_tags()
	t.check(all.size() >= 24, "setup: 24 believer pips are on the map (%d)" % all.size())
	var out: Array[MapTag] = hud.outline_tags()
	var gold := 0
	for m in out:
		if m.color == Hud.BELIEVER_COL:
			gold += 1
	t.check(gold == 0 and out.size() == hud.legend_tags().size(), "outline_tags(): no believer pip, the mission's tags as they are (%d gold, %d)" % [gold, out.size()])
	# a mission-tagged person ahead of the believers in the layer's input keeps its colour
	var wisher := folk[30]
	wisher.inside = false
	wisher.drawn_upright = true
	wisher.visible = true
	var mine: Array[MapTag] = [MapTag.person(wisher, Color.RED, "WISH")]
	mine.append_array(out)
	var want := TagOutlines.wanted(mine)
	t.check(not want.is_empty() and want[0][0] == wisher and want[0][1] == Color.RED, "its person is first, in its own colour")
	_done(s)


## Final review 7: with the view on and nothing to show, the aim's position is not in the signature (no redraw on every mouse move).
static func _signature_quiet(t) -> void:
	var s := _world()
	var hud: Hud = s.hud
	var aim: Targeting = s.aim
	aim.pick(0)
	aim._press = Vector2(10, 10)
	hud.believer_view = true
	aim.believer_view = true
	t.check(aim.believers_text() == "", "setup: no believer inside the aim")
	var a := hud._signature()
	aim._press = Vector2(30, 30)
	t.check(aim.believers_text() == "" and hud._signature() == a, "the aim moves over nothing: the signature stands")
	_done(s)


static func _legend_excludes(t) -> void:
	var s := _world()
	_believe(s, 3)
	var hud: Hud = s.hud
	hud.believer_view = true
	var gold := false
	for m in hud.legend_tags():
		gold = gold or m.color == Hud.BELIEVER_COL
	t.check(not gold and hud.all_tags().size() >= hud.legend_tags().size() + 3, "the legend's tags leave the believer marks out")
	_done(s)


static func _signature_follows(t) -> void:
	var s := _world()
	_believe(s, 4)
	var hud: Hud = s.hud
	var aim: Targeting = s.aim
	aim.pick(0)
	var r := float(aim.area().r)
	aim._press = Vector2(10, 10)
	for i in 4:
		(s.folk[i] as Person).ground_pos = Vector2(10, 10) + Vector2(r * 0.5, 0)
	var off := hud._signature()
	hud.believer_view = true
	aim.believer_view = true
	var a := hud._signature()
	(s.folk[0] as Person).ground_pos = Vector2(10, 10) + Vector2(r * 3.0, 0)
	var b := hud._signature()
	t.check(a != b, "view on: a changed believer count changes the signature")
	aim._press = Vector2(10.0 + r * 3.0, 10.0)
	t.check(hud._signature() != b, "view on: a moved aim point changes the signature")
	hud.believer_view = false
	aim.believer_view = false
	t.check(hud._signature() == off, "view off again: the signature is exactly what it was")
	_done(s)
