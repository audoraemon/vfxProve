extends RefCounted
## Death's aims (review R1, R4): Raise the Dead and Walking Corpse mark every body a click could take -- the one Remains.pick()
## takes is the lead, and in SPIRIT mode a body whose soul has gone is red and never lead; with the ledger off nothing is marked.
## Gravecall aims in two points: the first click where the spirits rise, the second where they haunt (the "route" preview).


static func run(t) -> void:
	_marks(t)
	var made := _crowd()
	_gravecall(t, made)
	await _draws(t, made)
	_done(made)


static func _crowd() -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.ORGANIZED)
	crowd.spawn()
	return [crowd, env, world, field, grid, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[2] as Node).free()


## A body on the ledger at `at`, written down now.
static func _lay(rem: Remains, at: Vector2) -> Remains.Remain:
	var r := Remains.Remain.new()
	r.pos = at
	r.born = rem._clock
	r.kind = &"mob"
	rem._list.append(r)
	return r


static func _marks(t) -> void:
	var c := Vector2(3.0, -2.0)
	var rem := Remains.new()
	rem.enabled = true
	_lay(rem, c)
	_lay(rem, c + Vector2(0.6, 0.0))
	_lay(rem, c + Vector2(1.4, 0.0))
	var marks := Targeting.bodies_marked(rem, c, false)
	var leads := marks.filter(func(m: Dictionary) -> bool: return bool(m.lead))
	t.check(marks.size() == 2 and leads.size() == 1 and leads[0].pos == rem.pick(c).pos
		and marks.all(func(m: Dictionary) -> bool: return bool(m.ok)),
		"raise marks every body within 1.0, the picked one lead (%s)" % [marks])
	rem.free()

	rem = Remains.new()
	rem.enabled = true
	_lay(rem, c)
	rem.step(16.0)
	marks = Targeting.bodies_marked(rem, c, true)
	t.check(marks.size() == 1 and not bool(marks[0].ok) and not bool(marks[0].lead),
		"spirit mode: a soul-less body is not ok and never lead (%s)" % [marks])
	t.check(Targeting.bodies_marked(rem, c, false).size() == 1 and bool(Targeting.bodies_marked(rem, c, false)[0].lead),
		"(in ZOMBIE mode the same body is lead)")

	# Walking Corpse reaches a hidden body too: it is the lead, marked where it lies.
	var hid := _lay(rem, c + Vector2(0.3, 0.0))
	hid.hidden = true
	marks = Targeting.bodies_marked(rem, c + Vector2(0.3, 0.0), false, true)
	leads = marks.filter(func(m: Dictionary) -> bool: return bool(m.lead))
	t.check(marks.size() == 2 and leads.size() == 1 and leads[0].pos == hid.pos,
		"with hidden_too the hidden body Walking Corpse would take is marked as lead (%s)" % [marks])
	t.check(Targeting.bodies_marked(rem, c + Vector2(0.3, 0.0), false).size() == 1, "and without it the hidden body is not marked")

	t.check(Targeting.bodies_marked(null, c, false).is_empty(), "no ledger, no marks")
	rem.enabled = false
	t.check(Targeting.bodies_marked(rem, c, false).is_empty(), "no ledger, no marks (the ledger off)")
	rem.free()

	t.check(Targeting.COL_BONE == Color(0.92, 0.9, 0.82, 0.9) and Targeting.COL_BONE_FILL == Color(0.92, 0.9, 0.82, 0.16)
		and Targeting.order_color("enter") == Targeting.COL_BONE, "bone is the death marks' colour, and ENTER's")


static func _gravecall(t, made: Array) -> void:
	var rules := Rules.new().setup(PackedStringArray(["gravecall"]), null, made[1], made[3], made[0], made[5])
	var casts: Array = []
	rules.caster = func(_s: GDScript, g: Vector2, e: Dictionary) -> FxTimeline:
		casts.append([g, e])
		return null
	var aim := Targeting.new().setup(rules, made[0])
	var a := Vector2(1.0, 1.0)
	var b := Vector2(5.0, 2.0)
	aim.pick(0)
	t.check(String(aim.area().get("shape", "")) == "route" and is_equal_approx(float(aim.area().get("r", 0.0)), GravecallFx.HAUNT_R),
		"gravecall's preview is a route, its circle HAUNT_R (%s)" % [aim.area()])
	aim.press(a)
	aim.release(a)
	t.check(aim.placed and aim.first == a and casts.is_empty(), "gravecall aims in two points: the first click is placed")
	t.check(aim.cancel() and not aim.placed, "gravecall aims in two points and Esc drops the first")
	aim.press(a)
	aim.release(a)
	aim.hover(b)
	aim.press(b)
	aim.release(b)
	t.check(casts.size() == 1 and casts[0][0] == a and casts[0][1].get("to") == b,
		"gravecall aims in two points: one cast at the first, sent to the second (%s)" % [casts])
	aim.free()
	rules.free()


## Each new preview draws (in the tree, over frames): Raise's and Walking Corpse's body marks, Corpse Guise's marks, and Gravecall's
## route before and after its first click.
static func _draws(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var rules := Rules.new().setup(PackedStringArray(["raise", "walker", "guise", "gravecall"]), null, made[1], made[3], made[0], made[5])
	t.check(crowd.remains.enabled, "(the ledger is on for Death's loadout)")
	var c := (made[4] as WalkGrid).nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	_lay(crowd.remains, c)
	_lay(crowd.remains, c + Vector2(0.5, 0.0))
	var aim := Targeting.new().setup(rules, made[0])
	t.root.add_child(aim)
	var draws := [0]
	aim.draw.connect(func() -> void: draws[0] += 1)
	for slot in 4:
		aim.pick(slot)
		aim.hover(c + Vector2(0.1 * float(slot + 1), 0.0))
		await t.process_frame
	aim.pick(0)
	aim.step_mode(1)  # SPIRIT
	aim.hover(c)
	await t.process_frame
	aim.pick(3)
	aim.press(c)
	aim.release(c)
	aim.hover(c + Vector2(4.0, 1.0))
	await t.process_frame
	t.check(draws[0] >= 6 and aim.placed, "raise, spirit, walker, guise and gravecall's route all draw (%d draws)" % draws[0])
	t.root.remove_child(aim)
	aim.free()
	rules.free()
