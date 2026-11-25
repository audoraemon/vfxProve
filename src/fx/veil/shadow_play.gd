class_name ShadowPlayFx
extends FxTimeline
## Shadow Play (Veil, Tier 4): T_RISE after the click everyone out in the open within RADIUS (VeilRules: 3.0 light / 6.0 dark) becomes
## their own shadow for SPAN seconds: statuses[KEY] on them (Person.is_shadow()), the value this effect's instance id, so two casts
## never undo each other (a later cast takes a shadow over; the earlier one's end leaves it). The person node is the shadow (VB3): it
## goes on with its task -- its goal, its post, its queue -- so the post looks manned and every director counts it as held; the hooks
## Task 2 laid make it see nothing and do nothing (no witness, no report, no shout, no fright, no fight, no chase, no seizure, not afraid
## of the dark), and Dreamless takes its owner at once.
## The end (VB4): in the light every shadow lies down for LIE seconds where it stopped (Person.knock_down(.., true): the mind is not
## touched) and is the person again. In the dark the soldiers' shadows fade where they stand -- those soldiers are taken (Crowd.take(),
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
## The lying outline: over the ground's own pieces, and how strong (VRB1: drawn where he stood at last, so a little stronger).
const MARK_Z := 3
const MARK_A := 0.34
## Level 5, The Shadows Keep Watch: at most this many join a cast, each within JOIN_R of a shadow of it, polled every TICK.
const JOIN_MOST := 12
const JOIN_R := 1.0
const TICK := 0.25
const EYE_KEY := "shadowplay"
const FADE := [Color("cfd3e6"), Color("3b1470"), Color("07050c"), Color(0.03, 0.02, 0.05, 0.4)]

## How many became shadows, how many lay down and woke at the end, and how many were taken (dark).
var shadows := 0
var lain := 0
var taken := 0
## How many fades were drawn (staged, dark soldiers; tests).
var fades := 0

var _dark := false
var _r := 0.0
## This cast's span, at its level (SPAN at level 1).
var lv_span := SPAN
var _me := 0
var _held: Array[Person] = []
## Person -> its Edge (only when staged).
var _edges := {}
var _marks: Array[Node] = []
var _undone := false
## Level 5 twist: whether it is on, how many joined, whether the shadows have risen, the poll's accumulator and the peel they stand up in.
var _twist := false
var joined := 0
var _rose := false
var _acc := 0.0
var _peel: VeilCastLooks.Peel
## The cast's look while it plays (tests): the ripple across the ground, the shadows peeling up.
var ripple: Node2D
var peel: Node2D


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
	_twist = PowerBook.twist_at(extra, "shadowplay")
	lv_span = PowerBook.stat(extra, "shadowplay", "SPAN", SPAN)
	_dark = VeilParts.dark(self)
	_r = VeilParts.size(self, "shadowplay", "RADIUS")
	duration = T_RISE + lv_span
	busy = T_RISE
	VeilParts.land(self, origin, _r)
	ctx.play(&"v_shadowplay", origin)
	at(T_RISE, _rise)
	at(T_RISE + lv_span, _end)
	if not DominionParts.staged(self):
		return
	var mark := FxParts.rings(self, origin, _r, VeilParts.VEIL, 2, 30.0)
	mark.set_param("scan", 0.0)
	mark.tween_param("reveal", 0.0, 1.0, T_RISE, 0.0, Tween.TRANS_SINE, Tween.EASE_OUT)
	mark.life = T_RISE + 0.1
	# The cast's look (Veil review, spec 5): a dark ripple crosses the ground out to the reach before the shadows rise.
	var wave := VeilCastLooks.Wave.new()
	wave.kind = VeilCastLooks.Wave.Kind.RIPPLE
	wave.r = _r
	wave.rim = Color(VeilParts.VEIL, 0.7)
	wave.fill = Color(VeilParts.BLACK, 0.45)
	wave.grow = T_RISE * 0.8
	wave.hold = 0.2
	wave.fade = 0.5
	wave.position = origin
	wave.z_index = 2
	ripple = track(wave, ctx.ground) as Node2D


## Whether `p` is a shadow of this cast now.
func _owns(p: Person) -> bool:
	return is_instance_valid(p) and p.statuses.has(KEY) and typeof(p.statuses[KEY]) == TYPE_INT and int(p.statuses[KEY]) == _me


func _rise() -> void:
	if ctx.field == null:
		return
	_rose = true
	var staged := DominionParts.staged(self)
	var up: VeilCastLooks.Peel = null
	if staged:
		up = VeilCastLooks.Peel.new()
		peel = track(up, ctx.overhead) as Node2D
		_peel = up
	for p in shadows_at(ctx.field, origin, _r):
		p.statuses[KEY] = _me  # (a shadow of another cast is taken over: its end is this one's now)
		p.self_modulate = VeilParts.BLACK
		_held.append(p)
		shadows += 1
		if staged:
			_dress(p)
			up.ids.append(p.get_instance_id())  # his shadow peels up from his feet and stands
			DominionParts.motes(self, p.ground_pos, RISE, 4)


## The silver edge behind the silhouette, and the faint lying outline where he stood.
func _dress(p: Person) -> void:
	var e := Edge.new()
	e.person = p
	e.show_behind_parent = true
	p.add_child(e)
	_edges[p] = e
	var m := Mark.new()
	# (VRB1) The ground layer carries the iso basis: undo it, so the outline is drawn in screen pixels at his feet, under the people.
	m.transform = Iso.BASIS.affine_inverse() * Transform2D(0.0, Iso.ground_to_screen(p.ground_pos))
	m.z_index = MARK_Z
	m.take(p)
	track(m, ctx.ground)
	_marks.append(m)


## While the shadows walk: one who died meanwhile (or was taken) is let go at once, his look given back.
func _fx_process(delta: float) -> void:
	if _held.is_empty():
		return
	for i in range(_held.size() - 1, -1, -1):
		var p: Variant = _held[i]
		if not is_instance_valid(p) or not (p as Person).is_alive() or not _owns(p):
			_let_go(p)
			_held.remove_at(i)
	if _twist and _rose and not _undone:
		_join_poll(delta)


## Level 5, every TICK from the rise to the end: whoever is alive, out of doors and not held by another Veil power (VeilParts.held())
## and within JOIN_R of a shadow this cast owns becomes a shadow as _rise() makes one, eyed; nearest the shadow first, JOIN_MOST a cast.
func _join_poll(delta: float) -> void:
	if ctx.field == null or joined >= JOIN_MOST:
		return
	_acc += delta
	if _acc < TICK - 0.001:
		return
	_acc = 0.0
	var near := {}
	for v: Variant in _held:
		var sh := v as Person
		if sh == null or not is_instance_valid(sh) or not sh.is_alive() or not _owns(sh):
			continue
		for e in ctx.field.in_radius(sh.ground_pos, JOIN_R):
			var p := e as Person
			if p == null or not p.is_alive() or p.inside or VeilParts.held(p):
				continue
			var d := p.ground_pos.distance_to(sh.ground_pos)
			if d > JOIN_R:
				continue
			var id := p.get_instance_id()
			if not near.has(id) or d < float(near[id][0]):
				near[id] = [d, p]
	var found: Array = near.values()
	found.sort_custom(func(a: Array, b: Array) -> bool:
		if is_equal_approx(float(a[0]), float(b[0])):
			return (a[1] as Person).get_instance_id() < (b[1] as Person).get_instance_id()
		return float(a[0]) < float(b[0]))
	var staged := DominionParts.staged(self)
	for f: Array in found:
		if joined >= JOIN_MOST:
			break
		var p := f[1] as Person
		p.statuses[KEY] = _me
		p.self_modulate = VeilParts.BLACK
		_held.append(p)
		joined += 1
		if staged:
			_dress(p)
			if _peel != null and is_instance_valid(_peel):
				_peel.ids.append(p.get_instance_id())
			DominionParts.motes(self, p.ground_pos, RISE, 4)
		if ctx.crowd != null:
			PaleEye.mark(self, p, EYE_KEY, INF)


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
				DominionParts.motes(self, p.ground_pos, FADE, 6)  # the shadow fades where it stands
				_fade_look(p)
			_let_go(p)
			if ctx.crowd != null and ctx.crowd.take(p, &"shade"):
				taken += 1
			continue
		_let_go(p)
		p.knock_down(LIE, true)  # lies down where the shadow stopped; the mind is as it was
		lain += 1
	_held.clear()
	_undo()


## A soldier's shadow fading in the dark, made an event (Veil review): his silhouette stretches up and thins with a silver edge, a
## ring goes out at his feet. It outlives the cast, which ends this frame (VeilCastLooks.ShadeFade: SolarisPit.GROUP, frees itself).
func _fade_look(p: Person) -> void:
	if ctx.overhead == null:
		return
	var f := VeilCastLooks.ShadeFade.new()
	f.take(p, VeilCastLooks.seed_of(p.ground_pos, 47))
	ctx.overhead.add_child(f)
	fades += 1


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
	if _twist and ctx != null and is_instance_valid(ctx.crowd):
		PaleEye.release(self)
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


## Freed off the tree without finishing (level 5 only): the joined and the eyes are let go all the same.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _twist:
		_undo()


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
		draw_texture_rect_region(PeopleArt.atlas(), _dst, _sil, Color(VeilParts.VEIL, ShadowPlayFx.MARK_A))


## The white silhouette frame of what `p` drew last (PeopleArt's silhouette block sits beside the frame's), or an empty rect.
static func sil_of(p: Person) -> Rect2:
	if not is_instance_valid(p) or p.drawn_src.size == Vector2.ZERO:
		return Rect2()
	var info: Array = p.silhouette_src()
	if info.size() < 2:
		return Rect2()
	var block: Vector2 = info[0]
	var sil: Vector2 = info[1]
	return Rect2(p.drawn_src.position - block + sil, p.drawn_src.size)
