class_name NoLeaveFx
extends FxTimeline
## Leaving Is Prohibited (Decree, Tier I; spec 5.1): a cell of golden amber closes over a patch of ground. T_SEAL after
## the cast, and for HOLD_TIME, nobody and nothing within RADIUS of the click can leave it -- any role, hounds and other
## visitors too. Walking in is free, and whoever walks in afterwards is held as well. They are not held still and their
## minds are their own: they walk, flee, fight as they would, and at the edge they simply cannot go on (set back onto
## it; they hesitate and turn). One inside a building is left alone until it comes out; a rite's chained captive walks
## out (the chain is stronger than the law). One carried more than CARRIED beyond the edge by something greater (a
## Mirrorfold, a blast) is free of it. The law itself is a LawZone (NO LEAVING) laid on the crowd, which holds them and
## answers the town's choices (Crowd.in_law()); this effect steps it on its own clock and keeps the books the missions
## read: `bound` (the people held, who wear the bars), `sealed` and `turned_back`. At the end the amber cracks and
## falls away in shards, which hurt no one. Quiet, but for the book entry's "alarm".

const RADIUS := 3.0
const HOLD_TIME := 15.0
const T_SEAL := 0.6
const CARRIED := LawZone.CARRIED
## At most this long after walking in one is bound (the cell takes in whoever stands inside every frame).
const JOIN_EVERY := 0.2
const TURN_EVERY := LawZone.TURN_EVERY
## How high the amber stands over the middle of the circle, in screen pixels.
const DOME_UP := 54.0
## The amber cracks for this long, then its shards fall and fade for FALL_TIME.
const CRACK_TIME := 0.15
const FALL_TIME := 0.65
const SHARDS := 22

## The bound: Person -> seconds until it may be turned back again.
var bound := {}
## Whether the law holds now, and how many times someone has been turned back at the edge.
var sealed := false
var turned_back := 0
## The law on the place (LawZone, NO LEAVING): laid at the seal, lifted at the end. null before the seal.
var law: LawZone
## The amber's shards once it has cracked (empty until then), each [from, velocity, spin, landing time, size, shape]:
## screen pixels from the circle's middle, pixels a second, radians a second, seconds after the crack.
var shards: Array = []

var _cell: Cell


func _build() -> void:
	duration = T_SEAL + HOLD_TIME + CRACK_TIME + FALL_TIME
	busy = T_SEAL
	at(T_SEAL, _seal)
	at(T_SEAL + HOLD_TIME, _lift)
	ctx.play(&"q_noleave", origin)
	if DominionParts.staged(self):
		DecreeParts.proclaim(self, origin, 60.0, 70.0, T_SEAL, 1.2)
		var mark := FxParts.rings(self, origin, RADIUS, DecreeParts.GILT, 2, 24.0)
		mark.set_param("scan", 0.0)
		mark.tween_param("reveal", 0.0, 1.0, T_SEAL, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		mark.life = T_SEAL + 0.1


func _seal() -> void:
	sealed = true
	law = LawZone.circle(origin, RADIUS, [LawZone.NO_LEAVING], HOLD_TIME)
	law.stepped_by_holder = true
	if ctx.crowd != null:
		ctx.crowd.add_law(law, self)
	else:
		law.hold_by(self)
	_step_law(0.0)
	if not DominionParts.staged(self):
		return
	_cell = Cell.new()
	_cell.fx = self
	_cell.position = Iso.ground_to_screen(origin).round()
	_cell.z_index = 4
	track(_cell, ctx.overhead_back)
	DecreeParts.seal(self, origin, DecreeParts.BARS, 2.6, 64.0)
	DominionParts.pulse(self, origin, RADIUS, DecreeParts.GILT, 0.5, 1.0)
	# The amber closes in from outside.
	var close := FxParts.shockwave(self, origin, RADIUS * 1.6, DecreeParts.GILT_RAMP)
	close.set_param("thickness", 0.05)
	close.tween_param("progress", 1.0, 0.62, 0.35, 0.0, Tween.TRANS_CUBIC, Tween.EASE_IN)
	close.tween_param("fade", 1.0, 0.0, 0.12, 0.25)
	close.life = 0.4


func _lift() -> void:
	sealed = false
	if law != null:
		if ctx.crowd != null:
			ctx.crowd.remove_law(law)
		else:
			law.lift()
	for p: Variant in bound:
		if is_instance_valid(p):
			p.clear_badge()
	bound.clear()
	_crack()
	if DominionParts.staged(self):
		DecreeParts.wave(self, origin, RADIUS * 1.3, 0.5, 0.05)


func _fx_process(delta: float) -> void:
	if not sealed or law == null:
		return
	# The law's clock starts at the seal, so it holds to the last frame before the lift.
	_step_law(minf(delta, t - T_SEAL))


## One frame of the law, then the books: whoever it holds now is bound and wears the bars; whoever it has let go (or
## who has died or gone) is bound no more.
func _step_law(delta: float) -> void:
	if ctx.crowd != null:
		ctx.crowd.step_law(law, delta)
	else:
		law.step(delta, ctx.field.in_rect(law.bounds()), [])
	turned_back = law.turned_back
	if _cell != null and is_instance_valid(_cell):
		for e: Array in law.turned:
			var edge: Vector2 = e[1]
			_cell.strike((edge - origin).angle())
	var left := maxf(T_SEAL + HOLD_TIME - t, 0.1)
	var held := 0
	for body: Variant in law.members:
		if not is_instance_valid(body):
			continue
		var p := body as Person
		if p == null:
			continue
		held += 1
		if not bound.has(p):
			p.set_badge(DecreeParts.BARS, DecreeParts.GILT, left)
		bound[p] = law.members[p]
	if bound.size() > held:
		for p: Variant in bound.keys():
			if not law.members.has(p):
				bound.erase(p)
				if is_instance_valid(p):
					p.clear_badge()


## The amber cracks: its shards, laid out over the dome by order (a golden-angle spread), never by a roll.
func _crack() -> void:
	shards.clear()
	var half := Cell.half_axes()
	for i in SHARDS:
		var round_at := TAU * fposmod(float(i) * 0.618034, 1.0)
		var up := lerpf(0.12, 1.2, fposmod(float(i) * 0.381966 + 0.17, 1.0))
		var from := Vector2(half.x * cos(up) * cos(round_at), half.y * cos(up) * sin(round_at) - DOME_UP * sin(up))
		var vel := Vector2(cos(round_at) * 34.0 * cos(up), -18.0 - 30.0 * sin(up))
		# It falls to the ground beneath it: from.y + vel.y * s + G * s^2 / 2 = floor.
		var drop := DOME_UP * sin(up)
		var land := (-vel.y + sqrt(vel.y * vel.y + 2.0 * Cell.FALL_G * drop)) / Cell.FALL_G
		var spin := (2.0 + float(i % 3)) * (1.0 if i % 2 == 0 else -1.0)
		shards.append([from, vel, spin, land, 4.0 + float(i % 3) * 2.0, i % 3])


## How much of the amber shows: up as the law lands, whole while it holds and as it cracks, gone once it has fallen.
func shown() -> float:
	if t >= T_SEAL + HOLD_TIME + CRACK_TIME:
		return 0.0
	return clampf((t - T_SEAL) / 0.3, 0.0, 1.0)


## The cell: a translucent dome of amber over the circle, drawn in screen space (the people it holds show through it,
## tinted). A gilt rim on the ground and a light rim over the top, the deep amber of its ribs, a sheen that climbs it,
## and a bright flare at the edge where someone is turned back. At the end it cracks and falls in shards. Its shapes are
## laid out once; each frame only draws them.
class Cell extends Node2D:
	const STRIKE_LIFE := 0.5
	const STRIKES := 8
	const FALL_G := 420.0
	## Points round each curve, and round half of one.
	const STEPS := 32
	const HALF := 16
	var fx: NoLeaveFx
	var _body := PackedVector2Array()
	var _top := PackedVector2Array()
	var _front := PackedVector2Array()
	var _back := PackedVector2Array()
	var _ribs := PackedVector2Array()
	var _cracks := PackedVector2Array()
	var _disc := PackedVector2Array()
	var _half_disc := PackedVector2Array()
	var _shapes: Array[PackedVector2Array] = []
	var _rims: Array[PackedVector2Array] = []
	var _strike_at := PackedFloat32Array()
	var _strike_age := PackedFloat32Array()

	## The ground circle's half width and half height on screen.
	static func half_axes() -> Vector2:
		return Vector2(RADIUS * 32.0 * sqrt(2.0), RADIUS * 16.0 * sqrt(2.0))

	func _init() -> void:
		var h := half_axes()
		var s := sqrt(h.y * h.y + DOME_UP * DOME_UP)
		# The dome's outline: the top of its silhouette, then the ground in front of it.
		for i in STEPS + 1:
			var a := PI + PI * float(i) / float(STEPS)
			_top.append(Vector2(h.x * cos(a), s * sin(a)))
			_back.append(Vector2(h.x * cos(a), h.y * sin(a)))
			_front.append(Vector2(h.x * cos(a - PI), h.y * sin(a - PI)))
		_body.append_array(_top)
		_body.append_array(_front.slice(1, STEPS))
		# Ribs: two rings of latitude and five meridians over its front.
		for lat: float in [0.5, 1.0]:
			var r := cos(lat)
			for i in HALF:
				for j in 2:
					var a := PI * float(i + j) / float(HALF)
					_ribs.append(Vector2(h.x * r * cos(a), h.y * r * sin(a) - DOME_UP * sin(lat)))
		for m in 5:
			var a := PI * (float(m) + 1.0) / 6.0
			for i in 8:
				for j in 2:
					var lat := (PI * 0.5) * float(i + j) / 8.0
					_ribs.append(Vector2(h.x * cos(lat) * cos(a), h.y * cos(lat) * sin(a) - DOME_UP * sin(lat)))
		# Cracks: from the crown out and down, zigzagging, laid by order.
		for c in 6:
			var a := TAU * float(c) / 6.0 + 0.3
			var prev := Vector2(0.0, -DOME_UP)
			for k in 4:
				var lat := (PI * 0.5) * (1.0 - float(k + 1) / 4.0)
				var jog := (0.22 if k % 2 == 0 else -0.22)
				var next := Vector2(h.x * cos(lat) * cos(a + jog), h.y * cos(lat) * sin(a + jog) - DOME_UP * sin(lat))
				_cracks.append(prev)
				_cracks.append(next)
				prev = next
		for i in 24:
			_disc.append(Vector2.from_angle(TAU * float(i) / 24.0))
		for i in 13:
			_half_disc.append(Vector2.from_angle(PI * float(i) / 12.0))
		# The shards' shapes, a unit across: a sliver, a wedge, a chip.
		for pts: Array in [[Vector2(0, -1), Vector2(0.45, 0.6), Vector2(-0.3, 0.8)],
				[Vector2(-0.8, -0.5), Vector2(0.9, -0.3), Vector2(0.1, 0.9)],
				[Vector2(-0.6, -0.6), Vector2(0.7, -0.4), Vector2(0.5, 0.6), Vector2(-0.4, 0.5)]]:
			var shape := PackedVector2Array(pts)
			_shapes.append(shape)
			var rim := shape.duplicate()
			rim.append(shape[0])
			_rims.append(rim)
		_strike_at.resize(STRIKES)
		_strike_age.resize(STRIKES)
		_strike_age.fill(-1.0)

	## Someone is turned back at the edge, at `angle` (on the ground) from the middle.
	func strike(angle: float) -> void:
		var slot := 0
		for i in STRIKES:
			if _strike_age[i] < 0.0:
				slot = i
				break
			if _strike_age[i] > _strike_age[slot]:
				slot = i
		# On screen the ground circle is turned an eighth of a turn.
		_strike_at[slot] = angle + PI * 0.25
		_strike_age[slot] = 0.0

	func _process(delta: float) -> void:
		if fx.t > T_SEAL + HOLD_TIME + CRACK_TIME + FALL_TIME:
			queue_free()
			return
		for i in STRIKES:
			if _strike_age[i] >= 0.0:
				_strike_age[i] = _strike_age[i] + delta if _strike_age[i] + delta < STRIKE_LIFE else -1.0
		queue_redraw()

	func _draw() -> void:
		var broke := fx.t - (T_SEAL + HOLD_TIME)
		if broke >= CRACK_TIME:
			_draw_shards(broke - CRACK_TIME)
			return
		var a := fx.shown()
		if a <= 0.0:
			return
		# It closes in from a little wider than the circle.
		var k := clampf((fx.t - T_SEAL) / 0.3, 0.0, 1.0)
		var s := lerpf(1.3, 1.0, 1.0 - (1.0 - k) * (1.0 - k))
		var h := half_axes()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
		draw_colored_polygon(_body, Color(DecreeParts.AMBER, DecreeParts.AMBER.a * a))
		# Lighter towards the crown, and a glint.
		var crown := sqrt(h.y * h.y + DOME_UP * DOME_UP)
		draw_set_transform(Vector2(0.0, -crown * 0.42) * s, 0.0, Vector2(h.x * 0.72, crown * 0.42) * s)
		draw_colored_polygon(_disc, Color(DecreeParts.AMBER_LIGHT, 0.1 * a))
		draw_set_transform(Vector2(-h.x * 0.3, -crown * 0.66) * s, -0.25, Vector2(h.x * 0.16, crown * 0.08) * s)
		draw_colored_polygon(_disc, Color(1.0, 0.97, 0.85, 0.35 * a))
		# A sheen that climbs it, over and over.
		var lat := fposmod(fx.t * 0.35, 1.0) * 1.35
		var r := cos(lat)
		draw_set_transform(Vector2(0.0, -DOME_UP * sin(lat)) * s, 0.0, Vector2(h.x * r, h.y * r) * s)
		draw_polyline(_half_disc, Color(DecreeParts.AMBER_LIGHT, 0.45 * a * (1.0 - lat / 1.35)), -1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
		draw_multiline(_ribs, Color(DecreeParts.AMBER_DEEP, 0.45 * a), -1.0)
		draw_polyline(_back, Color(DecreeParts.GILT, 0.3 * a), -1.0)
		# The rims: ink under each, so they read on any ground.
		draw_polyline(_top, Color(DecreeParts.INK, 0.5 * a), 3.0)
		draw_polyline(_top, Color(DecreeParts.AMBER_LIGHT, 0.9 * a), 1.0)
		draw_polyline(_front, Color(DecreeParts.INK, 0.7 * a), 3.0)
		draw_polyline(_front, Color(DecreeParts.GILT, 0.95 * a), 1.0)
		for i in STRIKES:
			if _strike_age[i] < 0.0:
				continue
			var f := 1.0 - _strike_age[i] / STRIKE_LIFE
			var at := Vector2(h.x * cos(_strike_at[i]), h.y * sin(_strike_at[i])) * s
			var span := 0.2 + 0.25 * (1.0 - f)
			draw_set_transform(Vector2.ZERO, 0.0, h * s)
			draw_arc(Vector2.ZERO, 1.0, _strike_at[i] - span, _strike_at[i] + span, 10, Color(1.0, 0.97, 0.82, f * a), -1.0)
			draw_set_transform(Vector2.ZERO)
			draw_line(at, at + Vector2(0.0, -10.0 - 8.0 * f), Color(DecreeParts.AMBER_LIGHT, f * a), 2.0)
			draw_rect(Rect2(at + Vector2(-2.0, -2.0), Vector2(4.0, 4.0)), Color(1.0, 0.97, 0.82, f * a))
		if broke >= 0.0:
			# It cracks, crown first.
			var c := clampf(broke / CRACK_TIME, 0.0, 1.0)
			draw_set_transform(Vector2.ZERO)
			draw_multiline(_cracks, Color(DecreeParts.INK, 0.8 * c), 2.0)
			draw_multiline(_cracks, Color(1.0, 0.97, 0.85, c), 1.0)
		draw_set_transform(Vector2.ZERO)

	## The shards, `age` seconds into their fall: each falls to the ground beneath where it was, turning, and fades.
	func _draw_shards(age: float) -> void:
		var fade := clampf(1.0 - (age - FALL_TIME * 0.45) / (FALL_TIME * 0.55), 0.0, 1.0)
		if fade <= 0.0:
			return
		for i in fx.shards.size():
			var sh: Array = fx.shards[i]
			var go := minf(age, float(sh[3]))
			var from: Vector2 = sh[0]
			var vel: Vector2 = sh[1]
			var at := from + Vector2(vel.x * go, vel.y * go + 0.5 * FALL_G * go * go)
			var size: float = sh[4]
			draw_set_transform(at, float(sh[2]) * go, Vector2(size, size))
			var body := DecreeParts.AMBER_LIGHT if i % 3 == 0 else Color(1.0, 0.7, 0.2)
			draw_colored_polygon(_shapes[int(sh[5])], Color(body, 0.75 * fade))
			draw_polyline(_rims[int(sh[5])], Color(DecreeParts.AMBER_DEEP, fade), -1.0)
		draw_set_transform(Vector2.ZERO)
