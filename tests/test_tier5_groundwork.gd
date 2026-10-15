extends RefCounted
## v0.11 M6 the groundwork for Tier 5's new missions, each shared change shown to keep today's path when left alone (review focus 1):
## EscortDirector's Charge record and EscortObjective's need (Task 1); HuntDirector's _unguarded_blow() and shield_hits (Task 2); the
## HUD's keepout and the kit's real stack depth (Task 3); Tier 5's frame, StagesObjective, RazeDirector._spoil_for(), the
## Searchlight's hunt and hold, TierBook's one Gaze objective and a director's own Gaze (Task 4).

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")
## Where a pair of charges hides (v0.11 M6 tests): The Lost Lamb's fountain.
const PAIR_START := Vector2(11.4, -10.0)


## An escort of two charges (v0.11 M6 tests): The Lost Lamb's places, no watch and no patrols, the two lay citizens nearest its start;
## `changes` is the guard change's switch; with `exit_any` either escapes wherever he stands.
class Pair:
	extends EscortDirector
	var changes := true
	var exit_any := false

	func _plan() -> void:
		charge_start = PAIR_START
		gate_at = LostLambDirector.GATE_MOUTH
		exit_at = LostLambDirector.EXIT
		return_to = LostLambDirector.TEMPLE_DOOR
		guardhouse = LostLambDirector.GUARDHOUSE
		watch_changes = changes

	func _appoint_charges() -> Array[Person]:
		return _lay_near(charge_start, 2)

	func _exit_reached(c: Charge) -> bool:
		return exit_any or super(c)


static func run(t) -> void:
	_charge_record(t)
	_charge_defaults(t)
	_two_charges(t)
	_marching(t)
	_exit_hook(t)
	_need(t)
	_watch_switch(t)


## The Lost Lamb keeps one Charge record, and every old field reads and writes it (v0.11 M6, Task 1).
static func _charge_record(t) -> void:
	var s := Kit.world(MissionBook.lost_lamb())
	var d: LostLambDirector = s.d
	var c: EscortDirector.Charge = d.charges[0]
	t.check(d.charges.size() == 1 and c.man == d.charge and c.hold_at == d._hold_at and not c.held and not d.held and not c.bound
		and is_equal_approx(c.freed_at, -1.0) and is_equal_approx(c.change_in, -1.0) and d.out_count() == 0 and d.left_count() == 1,
		"The Lost Lamb: one Charge record, read through the old names")
	var w: Person = d.watch[0]
	d.held = true
	d.seizer = w
	d._hold_at = Vector2(1.0, 2.0)
	d.change_in = 12.0
	d.freed_at = 3.0
	t.check(c.held and c.seizer == w and c.hold_at == Vector2(1.0, 2.0) and is_equal_approx(c.change_in, 12.0)
		and is_equal_approx(c.freed_at, 3.0), "the old names write charges[0]")
	Kit.done(s)
	var p := Kit.world(MissionBook.prisoner())
	var pd: PrisonerDirector = p.d
	t.check(pd.charges.size() == 1 and pd.charges[0].man == pd.charge and pd.bound and pd.charges[0].bound and not pd.gaolers.is_empty(),
		"The Prisoner: her record bound, her gaolers appointed as before")
	Kit.done(p)


## An escort with no charge gives today's defaults (v0.11 M6).
static func _charge_defaults(t) -> void:
	var e := EscortDirector.new()
	t.check(e.charges.is_empty() and e.charge == null and not e.held and e.seizer == null and e._hold_at == Vector2.INF and not e.bound
		and not e.bound_lost and is_equal_approx(e.freed_at, -1.0) and not e.escaped and not e.taken and is_equal_approx(e.change_in, -1.0)
		and e.watch_changes and e.out_count() == 0 and e.left_count() == 0 and e._all_resolved(),
		"no charge: null, false, Vector2.INF and -1, as the old fields began")


## Two charges are both stepped (v0.11 M6): the one at the way out escapes, the other stays.
static func _two_charges(t) -> void:
	var p := Pair.new()
	var s := Kit.world(MissionBook.lost_lamb(), p)
	var a: EscortDirector.Charge = p.charges[0]
	var b: EscortDirector.Charge = p.charges[1]
	t.check(p.charges.size() == 2 and a.man != b.man and (a.man as Person).mind == Person.Mind.DUTY and (b.man as Person).mind == Person.Mind.DUTY
		and p.left_count() == 2 and p.out_count() == 0, "two charges, each set down and held where the god finds them")
	Kit.arrive(b.man as Person, p.exit_at)
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(b.escaped and not a.escaped and p.out_count() == 1 and p.left_count() == 1 and not p._all_resolved() and p.charge == a.man,
		"each is stepped: the second at the way out escapes, the first stays (out 1, left 1)")
	Kit.done(s)


## A watcher marching one charge sees no other (v0.11 M6), though the other stands beside him.
static func _marching(t) -> void:
	var p := Pair.new()
	var s := Kit.world(MissionBook.lost_lamb(), p)
	var a: EscortDirector.Charge = p.charges[0]
	var b: EscortDirector.Charge = p.charges[1]
	var w: Person = p._free_soldiers(PAIR_START, 1)[0]
	p.watch.append(w)
	p.watch_posts.append(w.ground_pos)
	Kit.arrive(b.man as Person, w.ground_pos + Vector2(8.0, 0.0))
	Kit.arrive(a.man as Person, w.ground_pos + Vector2(EscortDirector.SIGHT - 0.5, 0.0))
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(a.held and a.seizer == w and not b.held, "(set-up) the watchman seizes the first")
	Kit.arrive(b.man as Person, w.ground_pos + Vector2(0.0, 1.0))
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(a.held and not b.held and p.seizures == 1, "a watcher marching one charge sees no other")
	Kit.done(s)


## _exit_reached() is the way out's test (v0.11 M6): a subclass may widen it.
static func _exit_hook(t) -> void:
	var p := Pair.new()
	p.exit_any = true
	var s := Kit.world(MissionBook.lost_lamb(), p)
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(p.out_count() == 2 and p._all_resolved(), "an _exit_reached() that says yes everywhere lets both out at once")
	Kit.done(s)


## EscortObjective's need (v0.11 M6): 1 by default, today's checks; above 1, done at that many out and failed only by the director.
static func _need(t) -> void:
	var lamb := Kit.world(MissionBook.lost_lamb())
	var o := (lamb.rules as Rules).objectives[0] as EscortObjective
	var d: LostLambDirector = lamb.d
	t.check(o.need == 1 and EscortObjective.new().need == 1 and o.check(lamb.rules) == Objective.Status.PENDING, "need 1 by default")
	d.escaped = true
	t.check(o.check(lamb.rules) == Objective.Status.DONE and o.reason == "lamb_out", "need 1: today's check, the charge out wins")
	Kit.done(lamb)
	var p := Pair.new()
	var s := Kit.world(MissionBook.lost_lamb(), p)
	var two := EscortObjective.new("Lead them out", "both_out", "one_taken", "one_dead", 2)
	p.charges[0].taken = true
	t.check(two.check(s.rules) == Objective.Status.PENDING, "need 2: one taken ends nothing by itself")
	p.charges[0].taken = false
	p.charges[1].escaped = true
	t.check(two.check(s.rules) == Objective.Status.PENDING, "one out of two needed: still open")
	p.charges[0].escaped = true
	t.check(two.check(s.rules) == Objective.Status.DONE and two.reason == "both_out", "two out: done, with its own reason")
	Kit.done(s)


## watch_changes (v0.11 M6): off, the guard change never starts; on (the default), it starts as The Lost Lamb's.
static func _watch_switch(t) -> void:
	var off := Pair.new()
	off.changes = false
	var s := Kit.world(MissionBook.lost_lamb(), off)
	Kit.arrive(off.charges[0].man as Person, off.gate_at + Vector2(0.0, -2.0))
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(off.change_in < 0.0 and not off.watch_away, "watch_changes false: near the gate, the guard change never starts")
	Kit.done(s)
	var on := Pair.new()
	var s2 := Kit.world(MissionBook.lost_lamb(), on)
	Kit.arrive(on.charges[0].man as Person, on.gate_at + Vector2(0.0, -2.0))
	Kit.run_for(s2, EscortDirector.TICK + DT)
	t.check(on.change_in > EscortDirector.WATCH_CHANGE - 1.0, "watch_changes true: it starts")
	Kit.done(s2)
