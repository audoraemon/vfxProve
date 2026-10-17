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


## A director whose stages, loss and HUD line are set by hand (v0.11 M6 tests).
class Staged:
	extends MissionDirector
	var done := false
	var why := ""
	var line := ""

	func stages_done() -> bool:
		return done

	func lost_reason() -> String:
		return why

	func hud_line() -> String:
		return line


## A Raze of one house whose burning spoils it in 2 s, whatever spoil_seconds says (v0.11 M6 tests).
class QuickRaze:
	extends RazeDirector

	func _begin() -> void:
		targets.append(_house_near(Vector2(0.0, 8.0)))
		spoil_seconds = 50.0

	func _spoil_for(_s: Structure) -> float:
		return 2.0


## A director that keeps a Gaze of its own (v0.11 M6 tests, Decision 208).
class OwnGaze:
	extends MissionDirector

	func _begin() -> void:
		gaze = GazeMeter.new()


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
	_keepout_aside(t)
	_taken_rects(t)
	_keepout_fallback(t)
	_advance_cache(t)
	_frame5(t)
	_stages(t)
	_spoil_default(t)
	_searchlight_hooks(t)
	_one_gaze(t)
	_own_gaze(t)


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
const FULL_STACK := Rect2(0.0, 0.0, 250.0, 175.0)


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
	Hud.details = true  # v0.11.1: these measure the expanded HUD
	var r := hud.stack_rect()
	var hint := hud.hint_rect()
	var wishes := hud.wishes_rect()
	var rows := hud.objective_rect()
	var wide := maxf(rows.end.x, maxf(hint.end.x, wishes.end.x))
	t.check(r.position == Vector2.ZERO and is_equal_approx(r.end.x, wide + Hud.STACK_PAD) and is_equal_approx(r.end.y, wishes.end.y + Hud.STACK_PAD)
		and descent.wishes.size() == 3 and r.end.y > Kit.DEAD.end.y,
		"the stack: the objectives, the hint and three wishes' rows, padded (%s)" % r)
	t.check(absf(Kit.STACK.size.y - wishes.end.y) <= 2.0 and Kit.STACK.size.y > Kit.DEAD.size.y,
		"the kit's STACK is the real depth (%s of the plates' %s), deeper than DEAD" % [Kit.STACK.size.y, wishes.end.y])
	hud.set_caption("The tour")
	t.check(hud.stack_rect() == r, "the tour's caption leaves it: the stack is still drawn")
	Hud.reset_session()
	hud.free()
	descent.release()
	Kit.done(s)


## The tag layer redraws when the stack's size changes, not only when a tag or the camera does (v0.11 M6, the controller's ruling): the
## night's main objective done swaps the hint for the wishes' line and changes the stack, the tags the same. The signature without its
## stack term does not move, so the stack term is what moves the full one.
static func _keepout_redraw(t) -> void:
	var def := TierBook.board("crowns_bread")
	var s := Kit.world(def)
	var descent := Descent.new().setup(def, 7)
	descent.attach(s.rules, s.d)
	var hud := Hud.new().setup(s.rules, s.crowd, s.town, null)
	Hud.details = true  # v0.11.1: these measure the expanded HUD
	var before := hud._tag_signature()
	var blank := hud._tag_signature(false)
	var stack := hud.stack_rect()
	s.rules.main_done = true
	t.check(before != "" and hud.stack_rect() != stack and hud._tag_signature() != before,
		"the stack changed with the tags as they were: the tag layer's signature changes (%s -> %s)" % [stack, hud.stack_rect()])
	t.check(hud._tag_signature(false) == blank, "and without the stack term it did not: the stack alone moved it")
	Hud.reset_session()
	hud.free()
	descent.release()
	Kit.done(s)


## A map tag whose diamond is clear of the stack but whose plate over the diamond would lie under it takes its plate beside the diamond,
## shown, never under the stack (v0.11 M6): one just below the stack, one just right of it.
static func _keepout_aside(t) -> void:
	var xf := Transform2D(0.0, MID)
	var spots := {"JUST BELOW": Vector2(100.0, FULL_STACK.end.y + 4.0), "JUST RIGHT": Vector2(FULL_STACK.end.x + 4.0, 100.0)}
	for label: String in spots:
		var tag := _tag_at(spots[label], label, true)
		var c := Hud.tag_point(tag, xf)
		var over := Hud.label_rect(label, c - Vector2(0.0, tag.size + Hud.LABEL_GAP + Hud.PLATE_H * 0.5), Kit.VIEW)
		var lay := Hud.tag_layout(_tags([tag]), xf, Kit.VIEW, FULL_STACK)
		t.check(over.intersects(FULL_STACK) and String(lay[0].mode) == "map" and bool(lay[0].show)
			and not (lay[0].label as Rect2).intersects(FULL_STACK) and not FULL_STACK.has_point(c),
			"%s: the plate over its diamond is under the stack, so it sits beside it, shown, outside the stack" % label)


## The timeline strip and the slot bar as the HUD draws them at 640 x 360 (v0.11 M6's final review tests): a strip under the clock, six
## slots along the bottom.
const STRIP := Rect2(240.0, 40.0, 160.0, 31.0)
const SLOTS := Rect2(10.0, Hud.SLOT_TOP, 620.0, Hud.SLOT_SIZE)


## The strip and the slot bar count as placed for labels (v0.11 M6's final review): a plate that would cover the strip sits beside its
## diamond instead; one that cannot clear the slot bar is not drawn; no shown plate covers either; the arrows and diamonds are where they
## were; with none taken, the layout of old.
static func _taken_rects(t) -> void:
	var xf := Transform2D(0.0, MID)
	var taken: Array[Rect2] = [STRIP, SLOTS]
	var high := _tag_at(Vector2(320.0, 86.0), "GUARD", false)
	var c := Hud.tag_point(high, xf)
	var over := Hud.label_rect("GUARD", c - Vector2(0.0, high.size + Hud.LABEL_GAP + Hud.PLATE_H * 0.5), Kit.VIEW)
	var lay := Hud.tag_layout(_tags([high]), xf, Kit.VIEW, Rect2(), taken)
	t.check(over.intersects(STRIP) and String(lay[0].mode) == "map" and bool(lay[0].show) and not (lay[0].label as Rect2).intersects(STRIP),
		"a plate over its diamond would cover the strip: it sits beside the diamond, shown, clear of it (%s)" % lay[0].label)
	var low := Hud.tag_layout(_tags([_tag_at(Vector2(320.0, 336.0), "GUARD", false)]), xf, Kit.VIEW, Rect2(), taken)
	t.check(String(low[0].mode) == "map" and not bool(low[0].show), "a diamond on the slot bar keeps no plate over the slots")
	var tags := _spread_tags()
	var before := Hud.tag_layout(tags, xf, Kit.VIEW, FULL_STACK)
	var now := Hud.tag_layout(tags, xf, Kit.VIEW, FULL_STACK, taken)
	var same := before.size() == now.size()
	var clear := true
	for i in mini(before.size(), now.size()):
		same = same and String(before[i].mode) == String(now[i].mode) and before[i].arrow == now[i].arrow and before[i].c == now[i].c
		if bool(now[i].show):
			clear = clear and not (now[i].label as Rect2).intersects(STRIP) and not (now[i].label as Rect2).intersects(SLOTS)
	var none := Hud.tag_layout(tags, xf, Kit.VIEW, FULL_STACK, [] as Array[Rect2])
	var old := none.size() == before.size()
	for i in mini(before.size(), none.size()):
		old = old and before[i].label == none[i].label and bool(before[i].show) == bool(none[i].show)
	t.check(same and clear and old, "every arrow and diamond where it was, no shown plate on the strip or the slots; none taken, as of old")


## _keepout_point()'s guard (v0.11 M6's final review): a line that never meets the keepout's right edge or bottom gets the frame's own
## edge point, never the screen's centre.
static func _keepout_fallback(t) -> void:
	var frame := Hud.tag_frame(Kit.VIEW)
	var far := Vector2(-400.0, -100.0)
	var whole := Rect2(Vector2.ZERO, Kit.VIEW)
	t.check(Hud.frame_point(far, frame, whole) == Hud.frame_point(far, frame) and Hud.frame_point(far, frame, whole) != frame.get_center()
		and Hud._keepout_point(frame.get_center(), Vector2.ZERO, FULL_STACK, Vector2(7.0, 9.0)) == Vector2(7.0, 9.0),
		"a keepout over the whole frame, or no heading: the frame's own edge point, not the centre")


## advance() takes the objective rows and the how-to-win line once and lets them go at its end (v0.11 M6's final review): outside it
## every reader takes them live, so a change between two advances is read at once; the slot bar is the slots' rectangles in one.
static func _advance_cache(t) -> void:
	var def := TierBook.board("crowns_bread")
	var s := Kit.world(def)
	var descent := Descent.new().setup(def, 7)
	descent.attach(s.rules, s.d)
	var hud := Hud.new().setup(s.rules, s.crowd, s.town, null)
	Hud.details = true  # v0.11.1: these measure the expanded HUD
	var stack := hud.stack_rect()
	var sig := hud._signature()
	hud.advance(0.016)
	t.check(hud._frame_rows == null and hud._frame_hint == null and hud._frame_lines == null and hud.stack_rect() == stack
		and hud._signature() == sig, "after an advance nothing is held, and the stack and the signature read as before")
	s.rules.main_done = true
	t.check(hud.stack_rect() != stack and hud._signature() != sig, "a change after the advance is read at once")
	var n: int = (s.rules as Rules).loadout.size()
	var bar := hud.slots_rect()
	t.check(n > 0 and bar.position == hud.slot_rect(0).position and bar.end == hud.slot_rect(n - 1).end, "the slot bar: every slot in one (%s)" % bar)
	Hud.reset_session()
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


## Tier 5's frame (v0.11 M6, Decision 207).
static func _frame5(t) -> void:
	var m := MissionBook._tier5("x", "X", PackedStringArray(["a", "b"]))
	t.check(m.tier == 5 and m.slots == 6 and m.dp_capacity == 16 and is_equal_approx(m.clock, 420.0) and m.profile == ""
		and m.tier_floor == 4 and not m.chooses_difficulty()
		and m.response_profile(ResponseProfile.Tier.UNPREPARED).tier_name() == "God-Resistant" and m.intro_banner == "X"
		and m.bonuses().is_empty() and m.pool.is_empty() and is_equal_approx(m.stretch, 1.0),
		"a Tier 5 mission's numbers: 7:00, 6 / 16, a God-Resistant town whatever is chosen, no bonuses")
	t.check(MissionBook.LANTERN_EYE == "lantern_eye" and MissionBook.EXODUS == "exodus" and MissionBook.HEART_OF_FAITH == "heart_of_faith",
		"Ascendance's three new ids")


## StagesObjective (v0.11 M6, Decision 255): its label and win reason given; the director's stages, loss and line.
static func _stages(t) -> void:
	var s := Kit.world(MissionBook.warning(), Staged.new())
	var d: Staged = s.d
	var o := StagesObjective.new("Put out the flame", "heart")
	t.check(o.label == "Put out the flame" and o.reason == "heart" and o.check(s.rules) == Objective.Status.PENDING
		and o.hud_text(s.rules) == "Put out the flame" and StagesObjective.new().reason == "stages",
		"StagesObjective: its words given; pending; its label on the HUD while the director has no line")
	d.line = "Kill Odran"
	d.why = "kindled"
	t.check(o.hud_text(s.rules) == "Kill Odran" and o.check(s.rules) == Objective.Status.FAILED and o.reason == "kindled",
		"the director's line in its place; its loss fails it with its reason")
	d.why = ""
	d.done = true
	var won := StagesObjective.new("Put out the flame", "heart")
	t.check(won.check(s.rules) == Objective.Status.DONE and won.reason == "heart", "the stages done: won, with the win's reason")
	var base := MissionDirector.new()
	t.check(not base.stages_done() and base.lost_reason() == "" and base.hud_line() == "", "the base director: no stages, no loss, no line")
	Kit.done(s)


## RazeDirector._spoil_for() (v0.11 M6, Decision 256): spoil_seconds by default; a subclass's own seconds raze its target.
static func _spoil_default(t) -> void:
	var s := Kit.world(MissionBook.spoiled_harvest())
	var d: HarvestDirector = s.d
	t.check(is_equal_approx(d._spoil_for(d.targets[0]), d.spoil_seconds), "_spoil_for() is spoil_seconds by default (Spoiled Harvest)")
	Kit.done(s)
	var q := QuickRaze.new()
	var w := Kit.world(MissionBook.spoiled_harvest(), q)
	var house := q.targets[0]
	(w.crowd as Crowd).fires.ignite(house, 1.0)
	Kit.run_for(w, 2.5)
	t.check(q.razed(house) and q.burned(house) >= 2.0, "a subclass's _spoil_for() of 2 s razes its target after 2 s alight, not 50")
	Kit.done(w)


## The Searchlight's hunt and hold (v0.11 M6, Decision 244): by default a noise is searched only in the clock's last seconds and held
## for good; hunting, a noise draws the nearest beam at once, held `hold` seconds, and a newer noise draws one again.
static func _searchlight_hooks(t) -> void:
	var l := Searchlight.new().setup(Vector2.ZERO)
	t.check(not l.hunt and l.hold == INF, "the defaults: no hunt, held for good")
	l.light(Searchlight.SECOND_AFTER)
	l.hear(Vector2(10.0, 0.0))
	l.step(0.1, 300.0)
	var early := l.searching
	l.step(0.1, Searchlight.SEARCH_LAST - 1.0)
	var late := l.searching
	for i in 100:
		l.step(0.1, Searchlight.SEARCH_LAST - 2.0)
	t.check(not early and late and l.searching, "by default: searched only in the last seconds, and still held 10 s on")
	var h := Searchlight.new().setup(Vector2.ZERO)
	h.hunt = true
	h.hold = 8.0
	h.light(Searchlight.SECOND_AFTER)
	h.hear(Vector2(10.0, 0.0))
	h.step(0.1, 300.0)
	var beam := h.search_beam
	t.check(h.searching and beam >= 0, "hunting: a noise draws the nearest lit beam at once")
	for i in 30:
		h.step(0.1, 300.0)
	t.check(h.aim(beam).distance_to(Vector2(10.0, 0.0)) < 1.0, "the beam reaches the noise")
	for i in 60:
		h.step(0.1, 300.0)
	t.check(not h.searching and h.search_beam == -1, "after `hold` seconds the beam goes back to its sweep")
	h.hear(Vector2(10.0, 0.0))
	h.step(0.1, 300.0)
	t.check(h.searching, "a newer noise draws a beam again")


## TierBook adds the Gaze objective only to a list that has none (v0.11 M6, Decision 211): the ★ missions as before.
static func _one_gaze(t) -> void:
	var made := func() -> Array[Objective]:
		var out: Array[Objective] = [StagesObjective.new(), GazeObjective.new()]
		return out
	var list: Array[Objective] = []
	list.assign(TierBook._with_gaze(made).call())
	var gazes := 0
	for o in list:
		gazes += 1 if o is GazeObjective else 0
	var lj := TierBook.board("last_judgement").objectives()
	var lj_gazes := 0
	for o in lj:
		lj_gazes += 1 if o is GazeObjective else 0
	t.check(list.size() == 2 and gazes == 1 and lj_gazes == 1 and lj.back() is GazeObjective,
		"a list with its own Gaze gets none added; Last Judgement's board version still ends with its one")
	# The final review: the same for an act's objectives made for the night -- one added to a list with none, none to a list with its own.
	var bare := func(_n: NightState) -> Array[Objective]:
		var out: Array[Objective] = [StagesObjective.new()]
		return out
	var own := func(_n: NightState) -> Array[Objective]:
		var out: Array[Objective] = [StagesObjective.new(), GazeObjective.new()]
		return out
	var added: Array[Objective] = []
	added.assign(TierBook._with_gaze_for_night(bare).call(NightState.new()))
	var kept: Array[Objective] = []
	kept.assign(TierBook._with_gaze_for_night(own).call(NightState.new()))
	t.check(added.size() == 2 and added[0] is StagesObjective and added[1] is GazeObjective and kept.size() == 2 and kept[1] is GazeObjective
		and not kept[0] is GazeObjective, "an act's night objectives: a Gaze after a list with none, none added to a list with its own")


## A Tier 5 director that keeps its own Gaze keeps it (v0.11 M6, Decision 208): the night's goes only to one with none.
static func _own_gaze(t) -> void:
	var def := TierBook.board("last_judgement")
	var s := Kit.world(def, OwnGaze.new())
	var mine: GazeMeter = (s.d as MissionDirector).gaze
	var descent := Descent.new().setup(def, 7)
	descent.attach(s.rules, s.d)
	t.check(mine != null and (s.d as MissionDirector).gaze == mine and descent.gaze == null and not (mine is Descent.TierGaze),
		"Descent.attach() leaves a director's own Gaze")
	descent.release()
	Kit.done(s)
