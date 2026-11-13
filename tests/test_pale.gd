extends RefCounted
## Pale Reign (Death, Tier IV): a click drains the colour out of a district of 10 for 16 s; it turns grey and silent.
## Everyone inside crawls at 0.3 pace, the fires there gutter out and the district is hushed (a bell tower in it too) for
## the span; the rest of the town is not. Every 1.5 s the weakest one still inside -- the sick, then the hurt, then the
## frail, then the nearest the middle; a tie to the lower instance id; never a guised one or a decoy -- dies without a sound
## (killed as pale, a whole body). Every whole-body death inside during the span gets up at once as a grey-eyed zombie, the
## god's pale servant, for 20 s (16 at most). With the first death a horde of pale ghosts pours out (4); a ghost's touch
## kills as pale, and every death inside adds a ghost, up to 24 alive and 24 kills; at 16 s they sink.

const RD := preload("res://tests/test_raise_dead.gd")
const DT := 0.05
const PERF_FRAMES := 200
const PERF_MS := 5.0


static func _cast(made: Array, at: Vector2) -> PaleReignFx:
	return FxTimeline.cast(PaleReignFx, made[5], at) as PaleReignFx


## A cast whose horde never comes (its kill cap spent before it starts): the reign's own deaths, read alone.
static func _cast_drip(made: Array, at: Vector2) -> PaleReignFx:
	var fx := _cast(made, at)
	fx.horde_kills = PaleReignFx.HORDE_KILLS
	return fx


static func run(t) -> void:
	var made := RD._setup()
	_book(t)
	_horde_pours(t, made)
	_ghost_touch(t, made)
	_last_touch(t, made)
	_ghost_per_death(t, made)
	_horde_caps(t, made)
	_ghost_bounds(t, made)
	_horde_sinks(t, made)
	_crawl(t, made)
	_order(t, made)
	_tie(t, made)
	_spared(t, made)
	_knight(t, made)
	_every(t, made)
	_risen(t, made)
	_every_death(t, made)
	_ledger_off(t, made)
	_fires(t, made)
	_loud(t, made)
	_voices(t, made)
	_escaped(t, made)
	_exit(t, made)
	_bell(t, made)
	RD._done(made)
	_perf(t)


## Everyone back out in the open, well and whole, then off in the corner (RD._clear_all); the town's clock on past any
## earlier reign's hush.
static func _reset(made: Array) -> void:
	var crowd: Crowd = made[0]
	crowd._clock += PaleReignFx.SPAN + 1.0
	for p in crowd.citizens + crowd.soldiers:
		if is_instance_valid(p):
			p.inside = false
			p.sick_left = 0.0
			p.statuses.erase(&"frail")
			if p.is_alive():
				p.health = Person.HEALTH_SOLDIER if p.soldier else Person.HEALTH_CITIZEN
	RD._clear_all(made)


## The nth citizen still alive (the reign kills some in every test), calm, at `at`.
static func _put(made: Array, n: int, at: Vector2) -> Person:
	var alive := (made[0] as Crowd).citizens.filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive())
	var p: Person = alive[n]
	p.ground_pos = at
	p.mind = Person.Mind.CALM
	return p


static func _names(ps: Array) -> Array:
	return ps.map(func(p: Person) -> String: return String(p.name) if is_instance_valid(p) else "<freed>")


## The row, its tables, its icons, the brief's numbers, its cue; Remains.wants() keeps bodies on a Pale night.
static func _book(t) -> void:
	var b := PowerBook.get_power("pale")
	t.check(not b.is_empty() and int(b.dp) == 6 and float(b.cooldown) == 120.0 and String(b.aim) == "click"
		and PowerBook.authority_of("pale") == "death" and not PowerBook.is_quiet("pale")
		and String(b.get("path", "")) == "res://src/fx/death/pale_reign.gd",
		"Pale Reign: Death's 6 DP, 120 s, a click, loud (%s)" % [b])
	var area: Dictionary = Targeting.AREAS.get("pale", {})
	t.check(PowerBook.REACH.has("pale") and is_equal_approx(PowerBook.impact("pale"), PaleReignFx.EVERY)
		and PowerBook.family("pale") == "death" and Rules.POWER_KINDS.get("pale", []) == [&"pale"]
		and area.get("shape", "") == "circle" and is_equal_approx(float(area.get("r", 0.0)), PaleReignFx.RADIUS)
		and Targeting.AREA_STATS.get("pale", {}) == {"r": "RADIUS"},
		"its reach, impact (the first death), family, kills (pale) and area (the district)")
	t.check(PowerBook.icon("pale") != null and PowerBook.hud_icon("pale") != null, "it has its icons")
	t.check(PaleReignFx.RADIUS == 10.0 and PaleReignFx.SPAN == 16.0 and PaleReignFx.CRAWL == 0.3
		and PaleReignFx.EVERY == 1.5 and PaleReignFx.SERVANT_LIFE == 20.0 and PaleReignFx.MAX_RISEN == 16
		and PaleReignFx.HORDE_START == 4 and PaleReignFx.HORDE_CAP == 24 and PaleReignFx.HORDE_KILLS == 24,
		"the numbers of the ruling (R10)")
	var reach: Array = PowerBook.REACH.get("pale", [])
	t.check(reach.size() == 4 and float(reach[3]) == PaleReignFx.SPAN and is_equal_approx(PowerBook.impact("pale"), 1.5),
		"its danger lasts the 16 s span, from the first death at 1.5 s (%s)" % [reach])
	t.check(Sfx.CATALOG.has(&"pale_drone"), "its cue (a low choir and bell drone) is catalogued")
	t.check(Remains.wants(["smite", "pale"]), "a loadout with Pale Reign keeps the town's bodies (Remains.wants)")


## "inside walk at 0.3, freed outside and at the end"
static func _crawl(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	t.check(at != Vector2.INF, "a spot with nobody near")
	var p := _put(made, 0, at + Vector2(3.0, 0.0))
	var out := _put(made, 1, at + Vector2(0.0, PaleReignFx.RADIUS + 1.5))
	var indoor := _put(made, 2, at + Vector2(-2.0, 0.0))
	indoor.inside = true
	var fx := _cast(made, at)
	RD._run(fx, 0.2)
	t.check(is_equal_approx(p.pace_hold(), PaleReignFx.CRAWL) and out.pace_hold() == 1.0 and indoor.pace_hold() == 1.0,
		"one inside crawls at 0.3, one past 10 and one indoors do not (%.2f, %.2f, %.2f)" % [p.pace_hold(), out.pace_hold(), indoor.pace_hold()])
	p.ground_pos = at + Vector2(PaleReignFx.RADIUS + 1.0, 0.0)
	RD._run(fx, 0.1)
	t.check(p.pace_hold() == 1.0, "freed once they leave the district (%.2f)" % p.pace_hold())
	p.ground_pos = at + Vector2(3.0, 0.0)
	RD._run(fx, 0.1)
	t.check(is_equal_approx(p.pace_hold(), PaleReignFx.CRAWL), "held again as they come back in")
	fx.end_now()
	t.check(p.is_alive() and p.pace_hold() == 1.0, "cut short, they are freed (%.2f)" % p.pace_hold())
	indoor.inside = false


## "the sick die first, then the hurt, then the nearest": the sick before the hurt before the frail before the nearest; one
## every 1.5 s, each killed as pale.
static func _order(t, made: Array) -> void:
	_reset(made)
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	var near := _put(made, 0, at + Vector2(1.0, 0.0))
	var frail := _put(made, 1, at + Vector2(0.0, 4.0))
	frail.statuses[&"frail"] = 60.0
	var hurt := _put(made, 2, at + Vector2(-6.0, 0.0))
	hurt.health = Person.HEALTH_CITIZEN * 0.5
	var sick := _put(made, 3, at + Vector2(0.0, -8.0))
	sick.sick_left = 60.0
	var far := _put(made, 4, at + Vector2(6.0, 4.0))
	var kinds := []
	var on_kill := func(e: DummyEnemy, kind: StringName) -> void:
		if e in [near, frail, hurt, sick, far]:
			kinds.append(kind)
	field.enemy_killed.connect(on_kill)
	var fx := _cast_drip(made, at)
	RD._run(fx, PaleReignFx.EVERY - 0.1)
	t.check(fx.taken.is_empty(), "nobody dies before the first 1.5 s")
	RD._run(fx, 0.15)
	t.check(fx.taken == [sick], "the sick die first, the farthest of them all (%s)" % [_names(fx.taken)])
	RD._run(fx, PaleReignFx.EVERY)
	t.check(fx.taken == [sick, hurt], "then the hurt (%s)" % [_names(fx.taken)])
	RD._run(fx, PaleReignFx.EVERY)
	t.check(fx.taken == [sick, hurt, frail], "then the frail (%s)" % [_names(fx.taken)])
	RD._run(fx, PaleReignFx.EVERY * 2.0)
	t.check(fx.taken == [sick, hurt, frail, near, far], "then the nearest the middle (%s)" % [_names(fx.taken)])
	t.check(kinds == [&"pale", &"pale", &"pale", &"pale", &"pale"], "each dies as pale, a whole body (%s)" % [kinds])
	field.enemy_killed.disconnect(on_kill)
	fx.end_now()


## A tie (two as near the middle, as well as each other) goes to the lower instance id; never the dice.
static func _tie(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	var a := _put(made, 0, at + Vector2(3.0, 0.0))
	var b := _put(made, 1, at + Vector2(-3.0, 0.0))
	var low := a if a.get_instance_id() < b.get_instance_id() else b
	var fx := _cast_drip(made, at)
	RD._run(fx, PaleReignFx.EVERY + 0.05)
	t.check(fx.taken == [low], "a tie goes to the lower instance id")
	fx.end_now()


## Never a guised one (Corpse Guise hides the faithful) nor a decoy (a glass twin is no one): the tick takes the next.
static func _spared(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	var guised := _put(made, 0, at + Vector2(1.0, 0.0))
	guised.statuses[&"guise"] = 60.0
	var decoy := _put(made, 1, at + Vector2(0.0, 1.5))
	decoy.set_meta(&"decoy", true)
	var plain := _put(made, 2, at + Vector2(-5.0, 0.0))
	var fx := _cast_drip(made, at)
	RD._run(fx, PaleReignFx.EVERY + 0.05)
	t.check(fx.taken == [plain] and guised.is_alive() and decoy.is_alive(),
		"the guised and the decoy nearer are passed over (%s)" % [_names(fx.taken)])
	fx.end_now()
	guised.statuses.erase(&"guise")
	decoy.remove_meta(&"decoy")


## A knight is hurt below his own full health (HEALTH_KNIGHT), not a soldier's: at 4 of 6 he goes before a whole citizen nearer.
static func _knight(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var near := _put(made, 0, at + Vector2(1.0, 0.0))
	var k: Person = crowd.soldiers[0]
	var corps := k.corps
	k.corps = Person.Corps.KNIGHT
	k.health = Person.HEALTH_KNIGHT - 2.0
	k.ground_pos = at + Vector2(-6.0, 0.0)
	t.check(PaleReignFx.full_health(k) == Person.HEALTH_KNIGHT and k.health > Person.HEALTH_SOLDIER, "(a knight at 4 of 6)")
	var fx := _cast_drip(made, at)
	RD._run(fx, PaleReignFx.EVERY + 0.05)
	t.check(fx.taken == [k] and near.is_alive(), "the wounded knight goes first (%s)" % [_names(fx.taken)])
	fx.end_now()
	k.corps = corps


## "one death every 1.5 s, 10 in 16 s at most": twenty inside, the first at the power's impact; none after the span; the
## ones left have their pace back when it ends.
static func _every(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	var ring: Array[Person] = []
	for i in 20:
		ring.append(_put(made, i, at + Vector2.from_angle(TAU * float(i) / 10.0) * (6.0 if i < 10 else 8.0)))
	var fx := _cast_drip(made, at)
	# Read halfway between the ticks (0.75, 2.25, 3.75 ... 14.25 s, then 15.75 s), never on one.
	var counts := []
	RD._run(fx, PaleReignFx.EVERY * 0.5)
	for k in 11:
		counts.append(fx.taken.size())
		RD._run(fx, PaleReignFx.EVERY)
	t.check(counts == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], "one death every 1.5 s (%s)" % [counts])
	RD._run(fx, 3.0)
	t.check(fx.taken.size() == 10, "10 in 16 s at most, none after (%d)" % fx.taken.size())
	t.check(is_equal_approx(fx.first_kill_at, PowerBook.impact("pale")), "the first at the power's impact (%.2f)" % fx.first_kill_at)
	var held := 0
	for p in ring:
		if is_instance_valid(p) and p.is_alive() and p.pace_hold() < 1.0:
			held += 1
	t.check(held == 0, "the span over, the ones left walk at their own pace again (%d still held)" % held)
	fx.end_now()


## "each pale death rises grey-eyed": at once, a zombie wearing the dead one's own look with ash-grey eyes; the body is taken
## (its remain off the ledger, its corpse hidden). Each lasts 20 s from its rising, and the reign ends with the last.
static func _risen(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var a := _put(made, 0, at + Vector2(2.0, 0.0))
	var b := _put(made, 1, at + Vector2(0.0, -8.0))
	var design := a._design()
	var fx := _cast_drip(made, at)
	RD._run(fx, PaleReignFx.EVERY + 0.05)
	var up := fx.visitors.living()
	t.check(fx.taken == [a] and up.size() == 1, "the first dead is up at once (%d up)" % up.size())
	if up.size() == 1:
		var z := up[0]
		t.check(z.breed == Animal.Breed.ZOMBIE and z.eyes == DeathParts.ASH and z.worn == design
			and z.ground_pos.distance_to(a.ground_pos) < 0.1,
			"a zombie in their own look, grey-eyed, where they fell (%s, eyes %s)" % [z.worn, z.eyes])
	var pale_left := crowd.remains.all().filter(func(r: Remains.Remain) -> bool: return r.kind == &"pale")
	t.check(pale_left.is_empty() and not a.visible, "its body is taken: off the ledger, the corpse no longer lies there")
	RD._run(fx, PaleReignFx.EVERY)
	t.check(fx.taken == [a, b] and fx.visitors.living().size() == 2, "and the next (%d up)" % fx.visitors.living().size())
	RD._run(fx, PaleReignFx.SERVANT_LIFE - PaleReignFx.EVERY - 0.2)
	t.check(fx.visitors.living().size() == 2, "they serve their 20 s")
	RD._run(fx, 0.3)
	t.check(fx.visitors.living().size() == 1 and not fx.finished, "the first falls at its 20 s, the second still up")
	RD._run(fx, PaleReignFx.EVERY + 0.3)
	t.check(fx.visitors.living().is_empty() and fx.finished, "the last falls, and the reign is over")


## Ruling: every whole-body death in the district during the span rises, whatever killed them (a mob's, a servant's bite);
## not one outside it, not one after the span, and no more than MAX_RISEN in a reign.
static func _every_death(t, made: Array) -> void:
	_reset(made)
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	var inside := _put(made, 0, at + Vector2(4.0, 0.0))
	var outside := _put(made, 1, at + Vector2(0.0, PaleReignFx.RADIUS + 2.0))
	var fx := _cast(made, at)
	RD._run(fx, 0.5)
	field.kill(inside, &"mob")
	t.check(fx.visitors.living().size() == 1 and fx.risen == 1 and fx.taken.is_empty(),
		"a mob's death inside rises too (%d up)" % fx.visitors.living().size())
	field.kill(outside, &"mob")
	t.check(fx.visitors.living().size() == 1 and fx.risen == 1, "a death outside the district does not")
	var also := _put(made, 1, at + Vector2(-4.0, 0.0))
	fx.risen = PaleReignFx.MAX_RISEN
	field.kill(also, &"mob")
	t.check(fx.visitors.living().size() == 1, "no more than %d rise in one reign" % PaleReignFx.MAX_RISEN)
	fx.end_now()
	_reset(made)
	var fx2 := _cast(made, at)
	RD._run(fx2, PaleReignFx.SPAN + 0.1)
	var late := _put(made, 0, at + Vector2(3.0, 0.0))
	field.kill(late, &"mob")
	t.check(fx2.visitors.living().is_empty(), "nor one after the span")
	fx2.end_now()


## With the town's ledger off (no Death power that keeps bodies in a test's loadout), the reign keeps it on for itself: its
## dead still rise; it is off again after.
static func _ledger_off(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	crowd.remains.enabled = false
	var at := RD._empty(made)
	_put(made, 0, at + Vector2(2.0, 0.0))
	var fx := _cast(made, at)
	t.check(crowd.remains.enabled, "the ledger is on for the reign")
	RD._run(fx, PaleReignFx.EVERY + 0.05)
	t.check(fx.taken.size() == 1 and fx.visitors.living().size() == 1, "its dead still rise")
	fx.end_now()
	t.check(not crowd.remains.enabled, "and the ledger is off again after")
	crowd.remains.enabled = true


## "fires inside are doused": a burning house within the district gutters out; one past it burns on.
static func _fires(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var house := RD._house(env, made[2])
	t.check(house != null, "a house that burns")
	if house == null:
		return
	var at := Vector2(house.footprint.end.x + 2.0, house.center().y)
	var far: Structure = null
	for s in env.structures():
		if not s.destroyed and FireManager.burns(s) and s.distance_to(at) > PaleReignFx.RADIUS + 3.0:
			far = s
			break
	crowd.fires.ignite(house, 1.0)
	if far != null:
		crowd.fires.ignite(far, 1.0)
	var fx := _cast(made, at)
	RD._run(fx, 0.1)
	t.check(crowd.fires.intensity(house) < 1.0, "the fire inside gutters at once (%.2f)" % crowd.fires.intensity(house))
	RD._run(fx, PaleReignFx.SPAN)
	t.check(not crowd.fires.is_burning(house) and fx.doused >= 1, "the fire inside is doused (%d)" % fx.doused)
	t.check(far != null and crowd.fires.is_burning(far), "one past the district burns on")
	fx.end_now()
	if far != null:
		crowd.fires._put_out(far, true)


## Loud: the cast is held as a danger by the town until its impact.
static func _loud(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var held := crowd.held_count()
	crowd.on_cast(at, Vector2.ZERO, 0.0, "pale")
	t.check(crowd.held_count() == held + 1, "the cast is a danger the town sees (held for its impact)")
	crowd.drop_held()


## The district is hushed, not the town: a shout inside makes no sound, one outside does; a pale death slumps without a cry
## (a quiet kind); the town itself is not hushed (frights, the alarm and the look go on as for any loud power).
static func _voices(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var inside := _put(made, 0, at + Vector2(3.0, 0.0))
	var outside := _put(made, 1, at + Vector2(0.0, PaleReignFx.RADIUS + 2.0))
	var fx := _cast(made, at)
	t.check(not crowd.is_hushed() and crowd.is_hushed_at(inside.ground_pos) and not crowd.is_hushed_at(outside.ground_pos),
		"the district is hushed, the town is not")
	crowd._voice_tokens = Crowd.VOICE_BUDGET
	var played := crowd.voices_played
	crowd._voice(inside, &"cit_shout")
	t.check(crowd.voices_played == played, "a shout inside makes no sound")
	crowd._voice(outside, &"cit_shout")
	t.check(crowd.voices_played == played + 1, "a shout outside does")
	t.check(DeathVoices.QUIET_KINDS.has(&"pale"), "a pale death is a quiet kind: a slump, no cry")
	fx.end_now()


## IMPORTANT 1 of the review: a held one who leaves the town mid-span (Crowd.escape frees them) is let go without an error
## (assigning a freed one to a Person errors and would leave them held), and the reign ends cleanly.
static func _escaped(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	var gone := _put(made, 0, at + Vector2(3.0, 0.0))
	var stays := _put(made, 1, at + Vector2(0.0, 6.0))
	var fx := _cast(made, at)
	RD._run(fx, 0.2)
	var id := gone.get_instance_id()
	t.check(fx._held.has(id), "(held)")
	crowd.citizens.erase(gone)
	field.remove(gone)
	gone.free()
	RD._run(fx, 0.2)
	t.check(not fx._held.has(id) and fx._held.has(stays.get_instance_id()), "the one who left is let go, the other still held")
	RD._run(fx, PaleReignFx.SPAN)
	t.check(fx._held.is_empty(), "the span over, nobody held")
	fx.end_now()
	t.check(fx.finished, "and it ends cleanly")


## Freed without _finish (a mission torn down mid-reign): _exit_tree still lets every pace go and clears the pack.
static func _exit(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	_put(made, 0, at + Vector2(1.0, 0.0))
	var left := _put(made, 1, at + Vector2(0.0, 5.0))
	var fx := _cast(made, at)
	RD._run(fx, PaleReignFx.EVERY + 0.05)
	var pack := fx.visitors
	var horde := fx.horde
	t.check(pack.living().size() == 1 and horde.living().size() >= PaleReignFx.HORDE_START and left.pace_hold() < 1.0,
		"(a servant up, the horde out and one held)")
	fx._exit_tree()
	t.check(left.pace_hold() == 1.0 and pack.living().is_empty() and not crowd.visitors.has(pack)
		and horde.living().is_empty() and not crowd.visitors.has(horde),
		"freed without its end, it still lets go of every pace and clears both its packs (%.2f)" % left.pace_hold())
	fx.end_now()
	t.check(left.pace_hold() == 1.0, "and its end after that changes nothing")


## Review focus 5, "the bell is hushed 16 s, then can ring": over a burning bell tower whose keeper is on the rope, the bell
## makes no sound for the span -- its keeper waits to try again, it is never silenced -- and rings once the span is over. A
## reign elsewhere in town does not hush it.
static func _bell(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var bell := crowd.bell
	t.check(bell != null and bell.tower != null and bell.state != BellNetwork.State.SILENCED, "(the town has a bell)")
	if bell == null or bell.tower == null:
		return
	var tower := bell.tower
	var at: Vector2 = (made[2] as WalkGrid).nearest_walkable(tower.center() + Vector2(tower.footprint.size.x * 0.5 + 2.0, 0.0), 6)
	t.check(at != Vector2.INF and tower.distance_to(at) <= PaleReignFx.RADIUS, "a spot beside the bell tower")
	if FireManager.burns(tower):
		crowd.fires.ignite(tower, 1.0)
	# Elsewhere in town first: a reign far from the tower does not hush its bell.
	var far := RD._empty(made, tower.center())
	t.check(far != Vector2.INF and tower.distance_to(far) > PaleReignFx.RADIUS + 2.0, "(a spot far from the tower)")
	var fx0 := _cast(made, far)
	bell.state = BellNetwork.State.CLIMBING
	bell._ring()
	t.check(bell.state == BellNetwork.State.RUNG, "a reign elsewhere: the bell rings (%s)" % BellNetwork.State.keys()[bell.state])
	fx0.end_now()
	crowd.unring_bell()
	var fx := _cast(made, at)
	t.check(crowd.is_hushed_at(tower.center()) and not crowd.is_hushed(), "the tower's district is hushed at the cast, not the town")
	bell.state = BellNetwork.State.CLIMBING
	bell._ring()
	t.check(bell.state == BellNetwork.State.WAITING, "the bell makes no sound (%s)" % BellNetwork.State.keys()[bell.state])
	_tick(made, fx, PaleReignFx.SPAN - 0.2)
	t.check(crowd.is_hushed_at(tower.center()) and bell.state != BellNetwork.State.SILENCED,
		"still hushed near the end, the bell never silenced")
	bell.state = BellNetwork.State.CLIMBING
	bell._ring()
	t.check(bell.state == BellNetwork.State.WAITING, "nor a ring at 15.8 s")
	_tick(made, fx, 0.4)
	t.check(not crowd.is_hushed_at(tower.center()), "the hush lifts at 16 s")
	bell.state = BellNetwork.State.CLIMBING
	bell._ring()
	t.check(bell.state == BellNetwork.State.RUNG, "then the bell rings on (%s)" % BellNetwork.State.keys()[bell.state])
	fx.end_now()


## The reign and the town's clock together (the hush is counted on the town's clock).
static func _tick(made: Array, fx: FxTimeline, seconds: float) -> void:
	var crowd: Crowd = made[0]
	for i in roundi(seconds / DT):
		crowd._clock += DT
		if not fx.finished:
			fx._process(DT)


## "the horde pours out at the first death: 4 ghosts": none before the first death at 1.5 s; at it, 4 pale ghosts (wraiths in
## the ghost's pale tint) pour out of the middle, and one more for that death.
static func _horde_pours(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	_put(made, 0, at + Vector2(2.0, 0.0))
	_put(made, 1, at + Vector2(-7.0, 0.0))
	var fx := _cast(made, at)
	RD._run(fx, PaleReignFx.EVERY - 0.1)
	t.check(fx.horde != null and fx.horde.living().is_empty() and fx.ghosts_made == 0, "no ghost before the first death")
	RD._run(fx, 0.1)
	fx._process(0.01)
	var up := fx.horde.living()
	var pale := up.filter(func(a: Animal) -> bool: return a.breed == Animal.Breed.WRAITH and a.worn_tint == DeathParts.PALE_GHOST_TINT)
	t.check(up.size() >= PaleReignFx.HORDE_START and pale.size() == up.size() and fx.taken.size() == 1,
		"the horde pours out at the first death: 4 ghosts (%d up, %d pale wraiths)" % [up.size(), pale.size()])
	t.check(fx.ghosts_made == PaleReignFx.HORDE_START + 1, "4 pour out, and one more for the first death (%d)" % fx.ghosts_made)
	fx.end_now()


## "a ghost's touch kills as pale, the body rises a servant": the reign's own death takes the sick one far off; a ghost reaches
## the one by the middle before the next tick, and its touch kills as pale -- a whole body, which gets up as a servant.
static func _ghost_touch(t, made: Array) -> void:
	_reset(made)
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	var sick_a := _put(made, 0, at + Vector2(0.0, -9.0))
	sick_a.sick_left = 60.0
	var sick_b := _put(made, 1, at + Vector2(0.0, 9.5))
	sick_b.sick_left = 60.0
	var victim := _put(made, 2, at + Vector2(2.0, 0.0))
	var kinds := []
	var on_kill := func(e: DummyEnemy, kind: StringName) -> void:
		if e == victim:
			kinds.append(kind)
	field.enemy_killed.connect(on_kill)
	var fx := _cast(made, at)
	RD._run(fx, PaleReignFx.EVERY + 0.05)
	var risen0 := fx.risen
	t.check(fx.taken == [sick_a] and victim.is_alive(), "(the sick one far off is the reign's first death)")
	RD._run(fx, 1.2)
	t.check(not victim.is_alive() and fx.taken == [sick_a] and fx.horde_kills == 1 and kinds == [&"pale"],
		"a ghost's touch kills as pale (%s, %d horde kills)" % [kinds, fx.horde_kills])
	t.check(fx.risen == risen0 + 1 and fx.visitors.living().size() == fx.risen,
		"the body rises a servant (%d risen)" % fx.risen)
	field.enemy_killed.disconnect(on_kill)
	fx.end_now()
	sick_b.sick_left = 0.0


## Final review 8: the touch that is the horde's HORDE_KILLS-th kill adds no ghost (it would be recalled at once): the horde one
## kill short of its cap, a ghost's touch takes the one by the middle, no ghost is made and the horde sinks.
static func _last_touch(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	var sick_a := _put(made, 0, at + Vector2(0.0, -9.0))
	sick_a.sick_left = 60.0
	var victim := _put(made, 2, at + Vector2(2.0, 0.0))
	var fx := _cast(made, at)
	RD._run(fx, PaleReignFx.EVERY + 0.05)
	t.check(fx.taken == [sick_a] and victim.is_alive() and fx.horde != null, "(the sick one far off is the reign's first death)")
	fx.horde.kills = PaleReignFx.HORDE_KILLS - 1
	fx.horde_kills = PaleReignFx.HORDE_KILLS - 1
	var made_before := fx.ghosts_made
	RD._run(fx, 1.2)
	t.check(not victim.is_alive() and fx.horde_kills == PaleReignFx.HORDE_KILLS and fx.ghosts_made == made_before and fx._sunk,
		"the touch that is the 24th kill adds no ghost, and the horde sinks (%d -> %d ghosts, %d kills)"
		% [made_before, fx.ghosts_made, fx.horde_kills])
	fx.end_now()


## "every death adds a ghost": ten inside; over the whole span the ghosts made past the 4 that pour out are as many as the
## deaths inside (the reign's, the horde's, the servants'), while under both caps.
static func _ghost_per_death(t, made: Array) -> void:
	_reset(made)
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	for i in 10:
		_put(made, i, at + Vector2.from_angle(TAU * float(i) / 10.0) * (3.0 + float(i % 3) * 2.0))
	var fx := _cast(made, at)
	var deaths := [0]
	var on_kill := func(e: DummyEnemy, _kind: StringName) -> void:
		var p := e as Person
		if p != null and not fx.over and p.ground_pos.distance_to(at) <= PaleReignFx.RADIUS:
			deaths[0] += 1
	field.enemy_killed.connect(on_kill)
	RD._run(fx, PaleReignFx.SPAN + 0.5)
	t.check(deaths[0] >= 5 and fx.ghosts_made - PaleReignFx.HORDE_START == deaths[0] and fx.horde_kills < PaleReignFx.HORDE_KILLS,
		"every death adds a ghost (%d deaths inside, %d ghosts made)" % [deaths[0], fx.ghosts_made])
	field.enemy_killed.disconnect(on_kill)
	fx.end_now()


## Review focus 3, "the horde stops at 24 alive and 24 kills": sixty packed inside; the living ghosts, read every step, never
## pass 24, and the horde kills 24 at most (it sinks then).
static func _horde_caps(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	var packed := 0
	for i in 60:
		var p := _put(made, i, at + Vector2(-7.0 + float(i % 8) * 2.0, -7.0 + float(i / 8) * 2.0))
		if p.ground_pos.distance_to(at) <= PaleReignFx.RADIUS:
			packed += 1
	t.check(packed == 60, "(sixty packed inside: %d)" % packed)
	# Final review 8: every death inside adds a ghost while under both caps and the span runs -- read here before the reign hears
	# the death -- except the touch that is the horde's last kill (it sinks then): the ghosts made are exactly those.
	var field: EnemyField = made[3]
	var holder: Array = [null]
	var under := [0]
	var last := [false]
	var pre := func(e: DummyEnemy, _kind: StringName) -> void:
		var f: PaleReignFx = holder[0]
		var p := e as Person
		last[0] = false
		if f == null or f.over or f.horde == null or p == null or p.ground_pos.distance_to(at) > PaleReignFx.RADIUS:
			return
		if f.horde.living().size() < PaleReignFx.HORDE_CAP and f.horde.kills < PaleReignFx.HORDE_KILLS and f.t < PaleReignFx.SPAN:
			under[0] += 1
			last[0] = true
	field.enemy_killed.connect(pre)
	var fx := _cast(made, at)
	holder[0] = fx
	var capped := [false]
	fx.horde.bitten.connect(func(_a: Animal, _who: Person, _first: bool) -> void:
		if not capped[0] and fx.horde.kills >= PaleReignFx.HORDE_KILLS:
			capped[0] = true
			if last[0]:
				under[0] -= 1)  # the last kill itself adds none
	var most := 0
	for i in roundi((PaleReignFx.SPAN + PaleReignFx.FADE + 0.5) / DT):
		if fx.finished:
			break
		fx._process(DT)
		most = maxi(most, fx.horde.living().size())
	t.check(fx.horde_kills == PaleReignFx.HORDE_KILLS and most == PaleReignFx.HORDE_CAP,
		"(both caps are reached: %d kills, %d most alive)" % [fx.horde_kills, most])
	t.check(fx.horde_kills <= PaleReignFx.HORDE_KILLS and most <= PaleReignFx.HORDE_CAP,
		"the horde stops at 24 alive and 24 kills (%d most alive, %d kills)" % [most, fx.horde_kills])
	t.check(fx.horde.living().is_empty(), "and once it has its 24 it sinks")
	t.check(capped[0] and fx.ghosts_made == PaleReignFx.HORDE_START + under[0],
		"the ghosts made are the 4 poured and one per death under both caps, none for the last kill (%d made, %d + %d)"
		% [fx.ghosts_made, PaleReignFx.HORDE_START, under[0]])
	field.enemy_killed.disconnect(pre)
	fx.end_now()


## "a ghost never kills outside the district": one standing just past it (RADIUS + 0.5) all span is alive at the end, though
## the horde kills everyone inside (on the far side, past a servant's reach of the one outside).
static func _ghost_bounds(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	var edge := _put(made, 0, at + Vector2(PaleReignFx.RADIUS + 0.5, 0.0))
	for i in 6:
		_put(made, i + 1, at + Vector2(-4.0 - float(i % 3) * 2.0, -2.0 + float(i / 3) * 4.0))
	var fx := _cast(made, at)
	RD._run(fx, PaleReignFx.SPAN + PaleReignFx.FADE + 0.2)
	t.check(edge.is_alive() and fx.horde_kills >= 1, "a ghost never kills outside the district (%d horde kills)" % fx.horde_kills)
	fx.end_now()


## "at 16 s the ghosts sink; freed mid-reign leaves nothing": the horde runs to the end of the span, sinks at SPAN and is gone
## by SPAN + FADE (its servants still up). A second reign freed at 5 s leaves no ghost or servant in any of the town's packs,
## and nobody held by it.
static func _horde_sinks(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	for i in 3:
		_put(made, i, at + Vector2.from_angle(TAU * float(i) / 3.0) * 4.0)
	var fx := _cast(made, at)
	RD._run(fx, PaleReignFx.SPAN - 0.2)
	t.check(not fx.horde.living().is_empty(), "(the horde still runs near the end of the span)")
	RD._run(fx, PaleReignFx.FADE + 0.4)
	t.check(fx.horde.living().is_empty() and not fx.finished and not fx.visitors.living().is_empty(),
		"at 16 s the ghosts sink: none left by %.1f s, the servants still up" % fx.t)
	fx.end_now()
	_reset(made)
	for i in 6:
		_put(made, i, at + Vector2.from_angle(TAU * float(i) / 6.0) * 5.0)
	var hidden := _put(made, 6, at + Vector2(3.0, 0.0))
	hidden.statuses[&"guise"] = 60.0  # passed over by the reign, its ghosts and its servants: still held at 5 s
	var fx2 := _cast(made, at)
	RD._run(fx2, 5.0)
	t.check(not fx2.horde.living().is_empty() and not fx2.visitors.living().is_empty() and hidden.pace_hold() < 1.0,
		"(a second reign at 5 s: ghosts and servants up, one held)")
	fx2._exit_tree()
	var undead := 0
	for pack in crowd.visitors:
		for a in (pack as Visitors).living():
			if a.breed == Animal.Breed.WRAITH or a.breed == Animal.Breed.ZOMBIE:
				undead += 1
	var held := (crowd.citizens + crowd.soldiers).filter(func(q: Person) -> bool:
		return is_instance_valid(q) and q.is_alive() and q.pace_hold() < 1.0)
	t.check(undead == 0 and held.is_empty(),
		"freed mid-reign, it leaves no ghost or servant in the town's packs and nobody held (%d undead, %d held)" % [undead, held.size()])
	fx2.end_now()
	hidden.statuses.erase(&"guise")


## Perf (R13): the horde at its cap (24) and 16 servants in the full town (its 220 out where they spawned): the reign's
## _fx_process with both packs stepped, averaged over 200 frames, is under 5 ms a frame.
static func _perf(t) -> void:
	var made := RD._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var fx := _cast(made, at)
	RD._run(fx, PaleReignFx.EVERY + 0.05)
	# The dead inside rise (MAX_RISEN of them), each adding a ghost; then the horde is filled to its cap.
	var alive := crowd.citizens.filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive() and not q.inside)
	var k := 0
	while fx.risen < PaleReignFx.MAX_RISEN and k < alive.size():
		var p: Person = alive[alive.size() - 1 - k]
		k += 1
		p.ground_pos = grid.nearest_walkable(at + Vector2.from_angle(TAU * float(k) / 16.0) * 6.0, 4)
		field.kill(p, &"pale", p.ground_pos)
	for i in 40:
		if fx.horde.living().size() >= PaleReignFx.HORDE_CAP:
			break
		fx._ghost_at(at + Vector2.from_angle(TAU * float(i) / 24.0) * 3.0)
	var ghosts := fx.horde.living().size()
	var servants := fx.visitors.living().size()
	# The worst case: the horde's kill count held far back, so all 24 hunt and kill through every measured frame instead of
	# sinking at their 24th kill part way through.
	fx.horde.kills = -100000
	var frame := 1.0 / 60.0
	var t0 := Time.get_ticks_usec()
	for i in PERF_FRAMES:
		fx._process(frame)
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0 / float(PERF_FRAMES)
	var killed := fx.horde.kills + 100000
	print("PALE perf: %.3f ms a frame over %d frames (%d ghosts + %d servants at the start, %d ghosts at the end, %d killed by them, %d citizens)" % [
		ms, PERF_FRAMES, ghosts, servants, fx.horde.living().size(), killed, crowd.citizens.size()])
	t.check(ghosts == PaleReignFx.HORDE_CAP and servants == PaleReignFx.MAX_RISEN and fx.horde.living().size() == PaleReignFx.HORDE_CAP
		and crowd.citizens.size() >= 220 and ms < PERF_MS,
		"horde 24 + 16 servants: _fx_process + both packs under 5 ms a frame over 200 frames (%.3f ms)" % ms)
	fx.end_now()
	RD._done(made)
