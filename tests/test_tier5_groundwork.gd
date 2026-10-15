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


## The Heretic Hunt whose standards are heard when struck (v0.11 M6 tests): shield_hits on.
class Loud:
	extends HereticHuntDirector

	func _plan() -> void:
		super()
		shield_hits = true


## The Heretic Hunt whose first standard comes with an owner of its own (v0.11 M6 tests): the owner counts each blow handed to it and
## lowers nothing, as a borrowed tower's would.
class Borrowed:
	extends HereticHuntDirector
	var owned: Array = []
	var post: Structure

	func _raise_standard(i: int) -> Structure:
		var s := super(i)
		if i == 0:
			post = s
			s.damage_filter = func(_st: Structure, amount: float, _source: Vector2, _kind: StringName) -> void: owned.append(amount)
		return s


static func run(t) -> void:
	_charge_record(t)
	_charge_defaults(t)
	_two_charges(t)
	_marching(t)
	_exit_hook(t)
	_need(t)
	_watch_switch(t)
	_hunt_hooks(t)
	_keepout_empty(t)
	_keepout_under(t)
	_keepout_slide(t)
	_keepout_labels(t)
	_keepout_stack(t)
	_keepout_redraw(t)


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


## The screen's middle, and the stack as a full night draws it, for the keepout's unit checks (v0.11 M6 tests).
const MID := Vector2(320.0, 180.0)
const FULL_STACK := Rect2(0.0, 0.0, 244.0, 169.0)


## Tags as the layout takes them (v0.11 M6 tests).
static func _tags(list: Array) -> Array[MapTag]:
	var out: Array[MapTag] = []
	out.assign(list)
	return out


## A person's tag whose diamond lands on `screen` with the camera at MID (v0.11 M6 tests).
static func _tag_at(screen: Vector2, label: String, edge: bool) -> MapTag:
	var g := Iso.screen_to_ground(screen + Vector2(0.0, MapTag.PERSON_LIFT) - MID)
	return MapTag.person(g, Color.RED, label, edge)


## A spread of tags over the screen and off it, half with edge arrows (v0.11 M6 tests).
static func _spread_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for k in 16:
		out.append(MapTag.person(Vector2(-16.0 + 2.2 * float(k), -12.0 + 1.6 * float(k)), Color.RED, "TAG %d" % k, k % 2 == 0))
	return out


## An empty keepout lays every tag out exactly as before (v0.11 M6, Task 3).
static func _keepout_empty(t) -> void:
	var xf := Transform2D(0.0, MID)
	var tags := _spread_tags()
	var before := Hud.tag_layout(tags, xf, Kit.VIEW)
	var now := Hud.tag_layout(tags, xf, Kit.VIEW, Rect2())
	var same := before.size() == now.size()
	for i in mini(before.size(), now.size()):
		same = same and String(before[i].mode) == String(now[i].mode) and before[i].arrow == now[i].arrow \
			and before[i].label == now[i].label and bool(before[i].show) == bool(now[i].show)
	var frame := Hud.tag_frame(Kit.VIEW)
	var far := Vector2(-400.0, -100.0)
	t.check(same and Hud.frame_point(far, frame) == Hud.frame_point(far, frame, Rect2()),
		"an empty keepout: every tag and arrow where it was")


## An edge tag whose diamond the stack would hide becomes an arrow on the stack's border, its label beside it outside (v0.11 M6); a tag
## without an edge keeps its diamond under the stack but loses its label.
static func _keepout_under(t) -> void:
	var xf := Transform2D(0.0, MID)
	var lay := Hud.tag_layout(_tags([_tag_at(Vector2(100.0, 130.0), "UNDER", true)]), xf, Kit.VIEW, FULL_STACK)
	var tip: Vector2 = lay[0].arrow
	var on_border := is_equal_approx(tip.x, FULL_STACK.end.x) or is_equal_approx(tip.y, FULL_STACK.end.y)
	t.check(String(lay[0].mode) == "arrow" and on_border and not FULL_STACK.has_point(tip) and bool(lay[0].show)
		and not (lay[0].label as Rect2).intersects(FULL_STACK), "an edge tag under the stack: an arrow on its border (%s), its label outside" % tip)
	var plain := Hud.tag_layout(_tags([_tag_at(Vector2(100.0, 130.0), "PLAIN", false)]), xf, Kit.VIEW, FULL_STACK)
	t.check(String(plain[0].mode) == "map" and not bool(plain[0].show), "a tag without an edge keeps its diamond under the stack, not its label")
	# One high up in the stack's span, bound mostly up: its plate, centred away from the tip along the heading, would straddle the border;
	# it is moved out and still shown.
	var high := Hud.tag_layout(_tags([_tag_at(Vector2(196.0, 52.0), "PRESSED MAN AND HIS PRESS-GANG", true)]), xf, Kit.VIEW, FULL_STACK)
	t.check(String(high[0].mode) == "arrow" and bool(high[0].show) and not (high[0].label as Rect2).intersects(FULL_STACK)
		and not FULL_STACK.has_point(high[0].arrow), "an arrow bound mostly up on the stack's border keeps its label, outside it")


## An arrow bound for the frame's left or top edge inside the stack's span slides to where the same line meets the stack's border
## (v0.11 M6).
static func _keepout_slide(t) -> void:
	var frame := Hud.tag_frame(Kit.VIEW)
	var far := Vector2(-400.0, -100.0)
	var old := Hud.frame_point(far, frame)
	var tip := Hud.frame_point(far, frame, FULL_STACK)
	var mid := frame.get_center()
	var cross := (tip - mid).cross(far - mid)
	t.check(FULL_STACK.grow(0.5).has_point(old) and not FULL_STACK.has_point(tip) and absf(cross) < 1.0
		and (is_equal_approx(tip.x, FULL_STACK.end.x) or is_equal_approx(tip.y, FULL_STACK.end.y)),
		"an arrow that fell inside the stack's span (%s) now sits on its border on the same line (%s)" % [old, tip])
	var east := Vector2(900.0, 200.0)
	t.check(Hud.frame_point(east, frame, FULL_STACK) == Hud.frame_point(east, frame), "an arrow nowhere near the stack is where it was")


## No label plate is drawn over the stack: it counts as a label already placed (v0.11 M6).
static func _keepout_labels(t) -> void:
	var xf := Transform2D(0.0, MID)
	var clear := true
	var shown := 0
	for e: Dictionary in Hud.tag_layout(_spread_tags(), xf, Kit.VIEW, FULL_STACK):
		if bool(e.show):
			shown += 1
			clear = clear and not (e.label as Rect2).intersects(FULL_STACK)
	t.check(clear and shown > 0, "no shown label plate overlaps the stack (%d shown)" % shown)


## Hud.stack_rect() is the live stack as drawn (v0.11 M6): from the corner to the widest plate's right edge and the lowest's bottom,
## STACK_PAD beyond; the tour's caption leaves it (the stack is still drawn). A Tier 3 board night: three wishes' rows. The kit's STACK is
## the real depth.
static func _keepout_stack(t) -> void:
	var def := TierBook.board("crowns_bread")
	var s := Kit.world(def)
	var descent := Descent.new().setup(def, 7)
	descent.attach(s.rules, s.d)
	var hud := Hud.new().setup(s.rules, s.crowd, s.town, null)
	var r := hud.stack_rect()
	var hint := hud.hint_rect()
	var wishes := hud.wishes_rect()
	var rows := hud.objective_rect()
	var wide := maxf(rows.end.x, maxf(hint.end.x, wishes.end.x))
	t.check(r.position == Vector2.ZERO and is_equal_approx(r.end.x, wide + Hud.STACK_PAD) and is_equal_approx(r.end.y, wishes.end.y + Hud.STACK_PAD)
		and descent.wishes.size() == 3 and r.end.y > Kit.DEAD.end.y,
		"the stack: the objectives, the hint and three wishes' rows, padded (%s)" % r)
	t.check(Kit.STACK.size.y >= r.size.y - 12.0 and Kit.STACK.size.y > Kit.DEAD.size.y, "the kit's STACK is the real depth, deeper than DEAD")
	hud.set_caption("The tour")
	t.check(hud.stack_rect() == r, "the tour's caption leaves it: the stack is still drawn")
	hud.free()
	descent.release()
	Kit.done(s)


## The tag layer redraws when the stack's size changes -- a wish row coming or going -- not only when a tag or the camera does
## (v0.11 M6, the controller's ruling).
static func _keepout_redraw(t) -> void:
	var def := TierBook.board("crowns_bread")
	var s := Kit.world(def)
	var descent := Descent.new().setup(def, 7)
	descent.attach(s.rules, s.d)
	var hud := Hud.new().setup(s.rules, s.crowd, s.town, null)
	var before := hud._tag_signature()
	var rows := descent.wishes.size()
	descent.wishes.pop_back()
	var after := hud._tag_signature()
	t.check(before != "" and rows == 3 and before != after and hud.stack_rect().size.y < Kit.STACK.size.y,
		"a wish row gone: the stack shrinks and the tag layer's signature changes")
	hud.free()
	descent.release()
	Kit.done(s)


## Step `i`'s guards moved well off their ring (v0.11 M6 tests): off guard, still alive.
static func _clear_party(d: HuntDirector, i: int) -> void:
	for g: HuntDirector.Guard in d.steps[i].party:
		if MissionDirector._alive(g.man):
			Kit.arrive(g.man as Person, g.post + Vector2(5.0, 5.0))


## HuntDirector._unguarded_blow() and shield_hits (v0.11 M6, Task 2): by default today's path, silent; heard when asked; a standard's
## own owner keeps its health, and gets it back at teardown.
static func _hunt_hooks(t) -> void:
	var s := Kit.world(MissionBook.heretic_hunt())
	var d: HereticHuntDirector = s.d
	d._raise(0)
	_clear_party(d, 0)
	var std := d.standard(0)
	var hits := [0]
	std.hit.connect(func(_s: Structure, _a: float, _k: StringName) -> void: hits[0] += 1)
	std.damage(10.0, std.center(), &"smite")
	t.check(not d.shield_hits and not d.guarded(0) and is_equal_approx(std.hp, std.max_hp - 10.0) and hits[0] == 0,
		"by default an unguarded blow lowers the standard's own health and is not heard (The Heretic Hunt's path)")
	Kit.done(s)
	var l := Loud.new()
	var s2 := Kit.world(MissionBook.heretic_hunt(), l)
	l._raise(0)
	_clear_party(l, 0)
	var loud := l.standard(0)
	var heard := [0]
	loud.hit.connect(func(_s: Structure, _a: float, _k: StringName) -> void: heard[0] += 1)
	loud.damage(10.0, loud.center(), &"smite")
	t.check(l.shield_hits and heard[0] == 1 and is_equal_approx(loud.hp, loud.max_hp - 10.0), "shield_hits on: the same blow, heard once")
	Kit.done(s2)
	var b := Borrowed.new()
	var s3 := Kit.world(MissionBook.heretic_hunt(), b)
	b._raise(0)
	_clear_party(b, 0)
	b.post.damage(10.0, b.post.center(), &"smite")
	t.check(b.owned == [10.0] and is_equal_approx(b.post.hp, b.post.max_hp), "a standard that came with an owner hands the blow to it")
	var post := b.post
	b.teardown()
	post.damage(5.0, post.center(), &"smite")
	t.check(b.owned == [10.0, 5.0] and is_equal_approx(post.hp, post.max_hp), "teardown gives the owner its building back")
	Kit.done(s3)
