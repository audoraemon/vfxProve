class_name PaleEye
extends Node2D
## The Pale Eye (Veil ability levels, VS 6, VL5-VL7): the dark watches back. Whoever notices a level-5 Veil power is shown to the player
## with a pale almond eye over his head, and the power answers him. One node per crowd (Crowd.pale_eye), made by the first mark(): it
## holds the ledger (one entry per person and cast, VL5), draws every open eye in one _draw(), and asks for the cue once a CUE_GAP.
## An eyed man off the view gets an eye on the edge of the screen pointing to him. Quiet: nothing here alarms, frightens or changes a
## mind; the badge (Person.set_badge) is not touched. Headless the ledger works and nothing is drawn.

## How long an eye stays open by default; the cue; the least gap between two cue requests (eye clock); the layer's z (under Targeting's 5);
## the margin an edge eye keeps from the border.
const TIME := 4.0
const CUE := &"v_pale_eye"
const CUE_GAP := 1.0
const Z := 4
const EDGE_MARGIN := 12.0
const HEAD := Vector2(0.0, -34.0)
const FADE := 0.4
const WHITE := Color("e9e4ff")
const RIM := Color("5a2aa8")
const IRIS := Color("b98cff")
const PUPIL := Color("07050c")

## Every eye ever opened: {"id": person instance id, "key": the power's key, "fx": the cast's (owner's) instance id, "at": crowd clock}.
## Kept after an eye closes (the ledger of who the dark saw).
var record: Array[Dictionary] = []
## Cue requests made (tests).
var cues := 0

## Open eyes: {"p": Person, "id": int, "owner": int, "left": float (INF = until unmark/release)}.
var _open: Array[Dictionary] = []
## (owner, person) pairs closed for good ("owner:id" -> true): the person was taken, died or went inside.
var _gone := {}
var _crowd: Crowd
var _clock := 0.0
var _last_cue := -INF
var _edges := 0
var _headless := DisplayServer.get_name() == "headless"


func _init() -> void:
	name = "PaleEye"
	z_index = Z
	z_as_relative = false


## Opens (or keeps open) `fx`'s eye on `p` for `seconds` (INF: until unmark()/release()). True when `p` is eyed by this cast after the
## call; false with no crowd, no layer, nobody, a dead or indoor person or one this cast's eye closed for good (VL5).
static func mark(fx: FxTimeline, p: Person, key: String, seconds := TIME) -> bool:
	if fx == null or fx.ctx == null:
		return false
	var layer: Node = fx.ctx.overhead_back if fx.ctx.overhead_back != null else fx.ctx.overhead
	return mark_by(fx.ctx.crowd, fx.get_instance_id(), p, key, seconds, layer)


## mark() for an owner that is no cast (Blight's rot watch outlives its cast, VL12): `owner_id` stands for the cast's instance id.
static func mark_by(crowd: Crowd, owner_id: int, p: Person, key: String, seconds := TIME, layer: Node = null) -> bool:
	if crowd == null or p == null or not is_instance_valid(p) or not p.is_alive() or p.inside:
		return false
	var eye := of(crowd)
	if eye == null:
		if layer == null or not is_instance_valid(layer):
			return false
		eye = PaleEye.new()
		eye._crowd = crowd
		crowd.pale_eye = eye
		layer.add_child(eye)
		eye._keep_last()
	var opened := eye._open_eye(owner_id, p, key, seconds)
	eye._keep_last()
	return opened


## Closes `fx`'s eye on `p` (not for good: the cast may mark him again).
static func unmark(fx: FxTimeline, p: Person) -> void:
	if fx != null and fx.ctx != null:
		unmark_by(fx.ctx.crowd, fx.get_instance_id(), p)


static func unmark_by(crowd: Crowd, owner_id: int, p: Person) -> void:
	var eye := of(crowd)
	if eye != null and p != null and is_instance_valid(p):
		eye._close(owner_id, p.get_instance_id())


## Closes `fx`'s open-ended (INF) eyes; its timed ones run out.
static func release(fx: FxTimeline) -> void:
	if fx != null and fx.ctx != null:
		release_by(fx.ctx.crowd, fx.get_instance_id())


static func release_by(crowd: Crowd, owner_id: int) -> void:
	var eye := of(crowd)
	if eye == null:
		return
	var keep: Array[Dictionary] = []
	for e in eye._open:
		if int(e["owner"]) == owner_id and is_inf(float(e["left"])):
			continue
		keep.append(e)
	eye._open = keep


## The crowd's ledger, or null; never makes one.
static func of(crowd: Crowd) -> PaleEye:
	if crowd == null or not is_instance_valid(crowd):
		return null
	var e := crowd.pale_eye
	if e == null or not is_instance_valid(e) or e.is_queued_for_deletion():
		return null
	return e


## Where an eye for the screen point `screen` sits when the view is `view`: where it is when on the view, else on the ray from the view's
## centre to it, `margin` inside the border.
static func edge_point(view: Rect2, screen: Vector2, margin := EDGE_MARGIN) -> Vector2:
	if view.has_point(screen):
		return screen
	var c := view.get_center()
	var d := screen - c
	var inner := view.grow(-margin)
	var hx := inner.size.x * 0.5
	var hy := inner.size.y * 0.5
	var t := 1.0
	if absf(d.x) > 0.0001:
		t = minf(t, hx / absf(d.x))
	if absf(d.y) > 0.0001:
		t = minf(t, hy / absf(d.y))
	return c + d * t


func is_eyed(p: Person) -> bool:
	if p == null or not is_instance_valid(p):
		return false
	var id := p.get_instance_id()
	for e in _open:
		if int(e["id"]) == id:
			return true
	return false


## Every open eye's person, once each, by instance id.
func eyed() -> Array[Person]:
	var seen := {}
	var ids: Array[int] = []
	for e in _open:
		if not seen.has(e["id"]):
			seen[e["id"]] = e["p"]
			ids.append(int(e["id"]))
	ids.sort()
	var out: Array[Person] = []
	for id in ids:
		out.append(seen[id])
	return out


## Open eyes the cast with instance id `fx_id` holds.
func held_by(fx_id: int) -> int:
	var n := 0
	for e in _open:
		if int(e["owner"]) == fx_id:
			n += 1
	return n


## Off-screen markers drawn last frame (0 headless).
func edge_marks() -> int:
	return _edges


func _process(delta: float) -> void:
	step(delta)


## Runs the eye clock: timed eyes run down; an eye on someone taken, dead or indoors closes for good for its cast.
func step(delta: float) -> void:
	_clock += delta
	if not _open.is_empty():
		var keep: Array[Dictionary] = []
		for e in _open:
			var p: Person = e["p"] if is_instance_valid(e["p"]) else null
			if p == null or not p.is_alive() or p.inside:
				_gone["%d:%d" % [e["owner"], e["id"]]] = true
				continue
			if not is_inf(float(e["left"])):
				e["left"] = float(e["left"]) - delta
				if float(e["left"]) <= 0.0:
					continue
			keep.append(e)
		_open = keep
	_keep_last()
	if not _headless:
		queue_redraw()


func _open_eye(owner_id: int, p: Person, key: String, seconds: float) -> bool:
	var id := p.get_instance_id()
	if _gone.has("%d:%d" % [owner_id, id]):
		return false
	for e in _open:
		if int(e["owner"]) == owner_id and int(e["id"]) == id:
			e["left"] = maxf(float(e["left"]), seconds)
			return true
	_open.append({"p": p, "id": id, "owner": owner_id, "left": seconds})
	record.append({"id": id, "key": key, "fx": owner_id, "at": _crowd.clock() if _crowd != null else 0.0})
	_cue(p)
	return true


func _close(owner_id: int, id: int) -> void:
	for i in _open.size():
		if int(_open[i]["owner"]) == owner_id and int(_open[i]["id"]) == id:
			_open.remove_at(i)
			return


## The cue for an eye that just opened: at most once a CUE_GAP of the eye clock, at the man when he is on the view, else at the
## ground point of the view's centre.
func _cue(p: Person) -> void:
	if _clock - _last_cue < CUE_GAP:
		return
	_last_cue = _clock
	cues += 1
	if _crowd == null or _crowd.sfx == null:
		return
	var at := p.ground_pos
	if is_inside_tree() and not _headless:
		var xf := get_global_transform_with_canvas()
		var view := get_viewport_rect()
		if not view.has_point(xf * (Iso.ground_to_screen(p.ground_pos) + HEAD)):
			at = Iso.screen_to_ground(xf.affine_inverse() * view.get_center())
	_crowd.sfx.play(&"v_pale_eye", at)  # (the literal cue: test_power_sounds reads it; CUE is the same name)


## The layer's last child, so a blanket or wall at the same z never covers the eyes (VL6).
func _keep_last() -> void:
	var par := get_parent()
	if par != null and par.get_child_count() > 0 and par.get_child(par.get_child_count() - 1) != self:
		par.move_child(self, par.get_child_count() - 1)


func _draw() -> void:
	_edges = 0
	if _headless or _open.is_empty() or not is_inside_tree():
		return
	var xf := get_global_transform_with_canvas()
	var inv := xf.affine_inverse()
	var view := get_viewport_rect()
	var seen := {}
	for e in _open:
		if seen.has(e["id"]) or not is_instance_valid(e["p"]):
			continue
		seen[e["id"]] = true
		var p: Person = e["p"]
		var local := Iso.ground_to_screen(p.ground_pos) + HEAD
		var on := xf * local
		var life := float(e["left"])
		var a := clampf(life / FADE, 0.0, 1.0) if not is_inf(life) else 1.0
		if view.has_point(on):
			_eye(local, a, 1.0)
		else:
			var at := edge_point(view, on)
			var dir := (on - view.get_center()).normalized()
			var l := inv * at
			_eye(l, a, 1.0)
			var tip := l + (inv.basis_xform(dir)).normalized() * 11.0
			var side := inv.basis_xform(dir).orthogonal().normalized() * 3.5
			draw_colored_polygon(PackedVector2Array([tip, l + side + inv.basis_xform(dir).normalized() * 5.0, l - side + inv.basis_xform(dir).normalized() * 5.0]), Color(WHITE, 0.8 * a))
			_edges += 1


## One almond eye centred at `c`, `k` times its size, at alpha `a`.
func _eye(c: Vector2, a: float, k: float) -> void:
	var pulse := 0.85 + 0.15 * sin(_clock * 4.0)
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	for i in 9:
		var x := lerpf(-6.0, 6.0, float(i) / 8.0)
		var h := 3.0 * (1.0 - pow(x / 6.0, 2.0))
		top.append(c + Vector2(x, -h) * k)
		bottom.append(c + Vector2(x, h) * k)
	bottom.reverse()
	var outline := PackedVector2Array(top)
	outline.append_array(bottom)
	draw_colored_polygon(outline, Color(WHITE, 0.92 * a))
	draw_polyline(top, Color(RIM, a), 1.0)
	draw_polyline(bottom, Color(RIM, a), 1.0)
	draw_circle(c, 2.2 * k, Color(IRIS, a * pulse))
	draw_circle(c, 1.1 * k, Color(PUPIL, a))
