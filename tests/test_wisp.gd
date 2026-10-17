extends RefCounted
## v0.06 Will-o'-Wisp: calm citizens within reach walk to the light and stand staring; the fleeing, people on duty and
## soldiers do not come; at most LURE_MAX; afterwards they go back to their day. Nothing is registered as a danger.


static func run(t) -> void:
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
	var at := Vector2(0.8, 2.0)
	var i := 0
	for p in crowd.citizens + crowd.soldiers:
		p.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var near: Array[Person] = []
	for k in 30:
		var p: Person = crowd.citizens[k]
		p.mind = Person.Mind.CALM
		p.ground_pos = at + Vector2(0.15 * float(k % 10) - 0.7, 0.3 * float(k / 10) + 1.0)
		near.append(p)
	near[0].mind = Person.Mind.FLEE
	near[1].mind = Person.Mind.DUTY
	var soldier: Person = crowd.soldiers[0]
	soldier.ground_pos = at + Vector2(0.5, 0.5)
	var drawn := WillOWisp.drawn(field, at)
	t.check(drawn.size() == WillOWisp.LURE_MAX and near[0] not in drawn and near[1] not in drawn and soldier in drawn,
		"it draws the calm and (v0.11.1: soldiers hear the god) a soldier at his post, %d at most (%d)" % [WillOWisp.LURE_MAX, drawn.size()])
	var p: Person = near[2]
	t.check(p.lure(at, 10.0) and p.mind == Person.Mind.OBSERVE and p.goal() != Vector2.INF,
		"a lured citizen walks to the light, watching it")
	p._idle = 0.0
	p._think(0.1)
	t.check(p._idle == 0.0, "and is not held in place on the way, as a plain watcher is")
	p.ground_pos = p.goal()
	p._goal = Vector2.INF
	p._think(9.0)
	t.check(p.mind == Person.Mind.OBSERVE, "it stands there staring")
	p._think(1.5)
	t.check(p.mind == Person.Mind.RECOVER, "then goes back to its day")
	soldier.mind = Person.Mind.RALLY
	t.check(not near[0].lure(at, 10.0) and not soldier.lure(at, 10.0), "the fleeing and a soldier on the rally will not come")
	crowd.on_cast(at, Vector2.ZERO, 0.0, "wisp")
	t.check(crowd.threats.active_count() == 0, "a wisp is no danger the town can see")

	# v0.11.1: a director's charge (answers_lure) on duty answers a Wisp within CHARGE_LURE_R of him and no farther; any other
	# person on duty never does.
	var charge: Person = near[3]
	charge.ground_pos = at + Vector2(1.0, 0.0)
	charge.mind = Person.Mind.DUTY
	near[4].mind = Person.Mind.DUTY
	near[4].ground_pos = at + Vector2(1.0, 0.5)
	t.check(not charge.lure(at, 10.0) and charge not in WillOWisp.drawn(field, at), "a person on duty is deaf to a lure")
	charge.answers_lure = true
	t.check(charge in WillOWisp.drawn(field, at) and near[4] not in WillOWisp.drawn(field, at),
		"one who answers a lure is drawn from duty within %.0f of the light, and only he" % WillOWisp.CHARGE_LURE_R)
	charge.ground_pos = at + Vector2(WillOWisp.CHARGE_LURE_R + 0.5, 0.0)
	t.check(charge not in WillOWisp.drawn(field, at), "and not beyond it: a Wisp cast elsewhere does not pull him off his road")
	charge.ground_pos = at + Vector2(WillOWisp.CHARGE_LURE_R - 0.5, 0.0)
	t.check(charge.lure(at, 10.0) and charge.mind == Person.Mind.OBSERVE and charge.goal() != Vector2.INF,
		"lured, he walks to the light and stares as anyone does")
	charge.mind = Person.Mind.CALM
	charge.ground_pos = at + Vector2(WillOWisp.CHARGE_LURE_R + 0.5, 0.0)
	t.check(charge not in WillOWisp.drawn(field, at), "a charge going about calmly keeps to the same reach")

	# Any lure obeys it (a Death Mark's gawkers too), measured from the source; and he goes back to his duty after it.
	charge.mind = Person.Mind.DUTY
	charge.anchor = at + Vector2(2.0, 0.0)
	charge.ground_pos = charge.anchor
	var body := charge.ground_pos + Vector2(5.0, 0.0)
	t.check(not charge.lure(body + Vector2(1.0, 0.0), 10.0) and charge.mind == Person.Mind.DUTY,
		"a Death Mark's body five away does not draw a charge off his duty")
	t.check(charge.lure(charge.ground_pos + Vector2(3.0, 0.0), 10.0, charge.ground_pos + Vector2(2.0, 0.0)) and charge.mind == Person.Mind.OBSERVE,
		"the Wisp's light within reach draws him though the ring spot it names is farther (the source is the light)")
	charge.ground_pos = charge.goal()
	charge._goal = Vector2.INF
	charge._think(9.0)
	t.check(charge.mind == Person.Mind.OBSERVE, "he stares at it")
	charge._think(1.5)
	t.check(charge.mind == Person.Mind.DUTY and charge.anchor == at + Vector2(2.0, 0.0), "and goes back to his duty, not to a day he does not have")
	var plain: Person = near[5]
	plain.mind = Person.Mind.CALM
	plain.ground_pos = at + Vector2(8.0, 0.0)
	t.check(plain.lure(at, 10.0), "everyone else is lured from any distance as before")
	crowd.clear()
	world.free()
