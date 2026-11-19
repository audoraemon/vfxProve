class_name ShadowPlayFx
extends FxTimeline
## Shadow Play (Veil, Tier 4): T_RISE after the click everyone out in the open within RADIUS (VeilRules: 3.0 light / 6.0 dark) becomes
## their own shadow for SPAN seconds: statuses[KEY] on them (Person.is_shadow()), the value this effect's instance id, so two casts
## never undo each other (a later cast takes a shadow over; the earlier one's end leaves it). The person node is the shadow (VB3): it
## goes on with its task -- its goal, its post, its queue -- so the post looks manned and every director counts it as held; the hooks
## Task 2 laid make it see nothing and do nothing (no witness, no report, no shout, no fright, no fight, no chase, no seizure, not afraid
## of the dark), and Dreamless takes its owner at once.
## The end (VB4): in the light every shadow lies down for LIE seconds where it stopped (Person.knock_down(.., true): the mind is not
## touched) and is the person again. In the dark the soldiers' shadows walk off and fade -- those soldiers are taken (Crowd.take(),
## kind &"shade": no body, no remain, no sound; C12) -- and the citizens wake as in the light. The dead are skipped.
## Quiet: no danger, no fright, no alarm, no cue. Its dusk is laid at the cast, radius its own (VeilParts.land(); VB0).
## Drawn: the person's own sprite as a flat BLACK silhouette (self_modulate) with a thin SILVER edge (an Edge drawn behind it), and where
## they stood when the shadow rose, a faint lying outline that only the god sees.
## Teardown: every status this cast still holds is lifted and every look given back in _finish() AND in _exit_tree(); an early end
## takes nobody.

const SPAN := 30.0
const T_RISE := 1.0
const KEY := &"shadow"
## How long a shadow lies down at the end before the person gets up.
const LIE := 1.5
const RISE := [Color("b98cff"), Color("3b1470"), Color("07050c"), Color(0.03, 0.02, 0.05, 0.5)]
const FADE := [Color("cfd3e6"), Color("3b1470"), Color("07050c"), Color(0.03, 0.02, 0.05, 0.4)]

## How many became shadows, how many lay down and woke at the end, and how many were taken (dark).
var shadows := 0
var lain := 0
var taken := 0

var _dark := false
var _r := 0.0
var _me := 0
var _held: Array[Person] = []
## Person -> its Edge (only when staged).
var _edges := {}
var _marks: Array[Node] = []
var _undone := false


## The living out in the open within `r` of `at`, nearest first and then by instance id (no luck): who becomes a shadow.
static func shadows_at(field: EnemyField, at: Vector2, r: float) -> Array[Person]:
	var out := DominionParts.near(field, at, r)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		var da := a.ground_pos.distance_squared_to(at)
		var db := b.ground_pos.distance_squared_to(at)
		if is_equal_approx(da, db):
			return a.get_instance_id() < b.get_instance_id()
		return da < db)
	return out


func _build() -> void:
	_me = get_instance_id()
	_dark = VeilParts.dark(self)
	_r = VeilParts.size(self, "shadowplay", "RADIUS")
	duration = T_RISE + SPAN
	busy = T_RISE
	VeilParts.land(self, origin, _r)
	at(T_RISE, _rise)
	at(T_RISE + SPAN, _end)
	if not DominionParts.staged(self):
		return
	var mark := FxParts.rings(self, origin, _r, VeilParts.VEIL, 2, 30.0)
	mark.set_param("scan", 0.0)
	mark.tween_param("reveal", 0.0, 1.0, T_RISE, 0.0, Tween.TRANS_SINE, Tween.EASE_OUT)
	mark.life = T_RISE + 0.1


## Whether `p` is a shadow of this cast now.
func _owns(p: Person) -> bool:
	return is_instance_valid(p) and p.statuses.has(KEY) and typeof(p.statuses[KEY]) == TYPE_INT and int(p.statuses[KEY]) == _me


func _rise() -> void:
	if ctx.field == null:
		return
	var staged := DominionParts.staged(self)
	for p in shadows_at(ctx.field, origin, _r):
		p.statuses[KEY] = _me  # (a shadow of another cast is taken over: its end is this one's now)
		p.self_modulate = VeilParts.BLACK
		_held.append(p)
		shadows += 1
		if staged:
			_dress(p)
			DominionParts.motes(self, p.ground_pos, RISE, 4)


## The silver edge behind the silhouette, and the faint lying outline where he stood.
func _dress(p: Person) -> void:
	var e := Edge.new()
	e.person = p
	e.show_behind_parent = true
	p.add_child(e)
	_edges[p] = e
	var m := Mark.new()
	m.position = Iso.ground_to_screen(p.ground_pos)
	m.take(p)
	track(m, ctx.ground)
	_marks.append(m)


## While the shadows walk: one who died meanwhile (or was taken) is let go at once, his look given back.
func _fx_process(_delta: float) -> void:
	if _held.is_empty():
		return
	for i in range(_held.size() - 1, -1, -1):
		var p: Variant = _held[i]
		if not is_instance_valid(p) or not (p as Person).is_alive() or not _owns(p):
			_let_go(p)
			_held.remove_at(i)


func _end() -> void:
	var staged := DominionParts.staged(self)
	var held: Array = _held.duplicate()
	for v: Variant in held:
		if not is_instance_valid(v):
			continue
		var p := v as Person
		if not _owns(p) or not p.is_alive():
			continue  # died, was taken, or another cast holds him now
		if _dark and p.soldier:
			if staged:
				DominionParts.motes(self, p.ground_pos, FADE, 6)  # the shadow walks off and fades
			_let_go(p)
			if ctx.crowd != null and ctx.crowd.take(p, &"shade"):
				taken += 1
			continue
		_let_go(p)
		p.knock_down(LIE, true)  # lies down where the shadow stopped; the mind is as it was
		lain += 1
	_held.clear()
	_undo()


## Lifts this cast's status from `p` and gives his look back (only when it is still this cast's: never another's).
func _let_go(p: Variant) -> void:
	if not is_instance_valid(p):
		_edges.erase(p)
		return
	var person := p as Person
	var e: Variant = _edges.get(person)
	_edges.erase(person)
	if e != null and is_instance_valid(e):
		(e as Node).queue_free()
	if _owns(person):
		person.statuses.erase(KEY)
		person.self_modulate = Color.WHITE


## Every status this cast still holds lifted, every look given back; nobody taken.
func _undo() -> void:
	if _undone:
		return
	_undone = true
	for p: Variant in _held:
		_let_go(p)
	_held.clear()
	for p: Variant in _edges.keys():
		var e: Variant = _edges[p]
		if e != null and is_instance_valid(e):
			(e as Node).queue_free()
	_edges.clear()
	for m in _marks:
		if is_instance_valid(m):
			m.queue_free()
	_marks.clear()


## How many silver edges / lying outlines are up now (tests).
func edges() -> int:
	var n := 0
	for e: Variant in _edges.values():
		if is_instance_valid(e) and not (e as Node).is_queued_for_deletion():
			n += 1
	return n


func marks() -> int:
	var n := 0
	for m in _marks:
		if is_instance_valid(m) and not m.is_queued_for_deletion():
			n += 1
	return n


func _finish() -> void:
	_undo()
	super._finish()


func _exit_tree() -> void:
	_undo()
	super._exit_tree()


## A thin SILVER edge round the person's silhouette: his own white silhouette frame drawn one pixel out on each side, behind him.
class Edge extends Node2D:
	var person: Person

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if not is_instance_valid(person) or person.drawn_src.size == Vector2.ZERO:
			return
		var sil := ShadowPlayFx.sil_of(person)
		if sil.size == Vector2.ZERO:
			return
		var c := Color(VeilParts.SILVER, 0.85)
		for d: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			draw_texture_rect_region(PeopleArt.atlas(), Rect2(person.drawn_dst.position + d, person.drawn_dst.size), sil, c)


## Where the person stood when the shadow rose: his silhouette lying on its side, faint, for the god's eyes.
class Mark extends Node2D:
	var _sil := Rect2()
	var _dst := Rect2()

	func take(p: Person) -> void:
		_sil = ShadowPlayFx.sil_of(p)
		_dst = p.drawn_dst

	func _draw() -> void:
		if _sil.size == Vector2.ZERO or _dst.size == Vector2.ZERO:
			return
		draw_set_transform(Vector2.ZERO, -PI * 0.5, Vector2.ONE)
		draw_texture_rect_region(PeopleArt.atlas(), _dst, _sil, Color(VeilParts.VEIL, 0.22))


## The white silhouette frame of what `p` drew last (PeopleArt's silhouette block sits beside the frame's), or an empty rect.
static func sil_of(p: Person) -> Rect2:
	if not is_instance_valid(p) or p.drawn_src.size == Vector2.ZERO or p._design_info.size() < 2:
		return Rect2()
	var block: Vector2 = p._design_info[0]
	var sil: Vector2 = p._design_info[1]
	return Rect2(p.drawn_src.position - block + sil, p.drawn_src.size)
