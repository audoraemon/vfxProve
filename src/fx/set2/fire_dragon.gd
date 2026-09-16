class_name FireDragon
extends Node2D
## Colossal dragon of living flame rising out of the ground: S-curved neck of glowing scale segments with
## dorsal spikes, flame-edged wings and a horned head whose jaw opens to breathe fire.
## Positioned on its ground point; `aim` is the local screen point the head looks at.

const DEEP := Color("6a1606")
const BODY := Color("c8401a")
const BRIGHT := Color("ff7a24")
const HOT := Color("ffbe4a")
const WHITE := Color("fff2c0")
const HEIGHT := 122.0
const HEAD_SCALE := 1.5

var rise := 0.0
var jaw := 0.0
var wings := 0.0
var fade := 1.0
var aim := Vector2(80, 0)
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func spine_point(s: float) -> Vector2:
	var sway := sin(_time * 1.6 + s * 2.0) * 4.0 * s
	var lean := (aim.x * 0.12) * s * s
	return Vector2(sin(s * PI * 1.25 + 0.6) * 30.0 * (1.0 - s * 0.35) + sway + lean, -s * HEIGHT * clampf(rise, 0.0, 1.0))


func head_pos() -> Vector2:
	return spine_point(clampf(rise, 0.02, 1.0)) + Vector2(0, -6)


func mouth_pos() -> Vector2:
	var h := head_pos()
	var u := (aim - h).normalized()
	return h + u * 24.0 * HEAD_SCALE


func _draw() -> void:
	if rise <= 0.01 or fade <= 0.0:
		return
	modulate.a = fade
	var top := clampf(rise, 0.0, 1.0)
	if wings > 0.01:
		_draw_wings(spine_point(top * 0.62), wings)
	var segs := 20
	var prev := spine_point(0.0)
	for i in range(0, segs + 1):
		var s := top * i / segs
		var p := spine_point(s)
		var r := lerpf(22.0, 10.0, s / maxf(top, 0.001) * top)
		var tangent := (p - prev).normalized() if i > 0 else Vector2(0, -1)
		_scale_segment(p, r, tangent, i)
		prev = p
	_draw_head()


func _scale_segment(p: Vector2, r: float, tangent: Vector2, i: int) -> void:
	var flick := 0.85 + 0.15 * sin(_time * 18.0 + i * 1.3)
	var n := tangent.orthogonal()
	if n.x > 0.0:
		n = -n
	# Flame tongues licking off the outline.
	for k in 3:
		var a := _time * 3.0 + i * 1.7 + k * 2.1
		var d := Vector2(cos(a), sin(a) * 0.8)
		var tip := p + d * (r + 5.0 + 4.0 * sin(_time * 12.0 + i + k))
		draw_primitive(PackedVector2Array([p + d.orthogonal() * r * 0.35 + d * r * 0.7, p - d.orthogonal() * r * 0.35 + d * r * 0.7, tip]),
			PackedColorArray([Color(BRIGHT, 0.8), Color(BRIGHT, 0.8), Color(HOT, 0.6)]), PackedVector2Array())
	var ring := PackedVector2Array()
	for k in 10:
		var a := TAU * k / 10.0
		ring.append(p + Vector2(cos(a), sin(a) * 0.92) * r)
	draw_colored_polygon(ring, DEEP)
	var body := PackedVector2Array()
	for pt in ring:
		body.append(p + (pt - p) * 0.86 + Vector2(-0.5, -0.5))
	draw_colored_polygon(body, BODY * flick)
	# Lit upper-left scales and a hot core.
	var lit := PackedVector2Array()
	for pt in ring:
		lit.append(p + (pt - p) * 0.55 + Vector2(-r * 0.22, -r * 0.25))
	draw_colored_polygon(lit, BRIGHT)
	draw_rect(Rect2((p + Vector2(-r * 0.35, -r * 0.4)).round(), Vector2(maxf(r * 0.3, 2.0), 2)), HOT)
	# Scale chevrons.
	for k in 2:
		var c := p + n * (r * 0.1 - k * r * 0.35) + tangent * r * 0.2
		draw_line((c - tangent * 3.0 + n * 3.0).round(), c.round(), DEEP, -1.0)
		draw_line(c.round(), (c - tangent * 3.0 - n * 3.0).round(), DEEP, -1.0)
	# Dorsal spike on the back side.
	if i % 2 == 0:
		var base := p + n * r * 0.8
		draw_primitive(PackedVector2Array([base + tangent * r * 0.35, base - tangent * r * 0.35, base + n * r * 0.9 + tangent * r * 0.2]),
			PackedColorArray([DEEP, DEEP, HOT]), PackedVector2Array())


func _draw_head() -> void:
	var h := head_pos()
	var u := (aim - h).normalized()
	if u == Vector2.ZERO:
		u = Vector2(1, 0)
	var n := u.orthogonal()
	if n.y > 0.0:
		n = -n
	var ld := (u - n * jaw * 0.9).normalized()
	# Draw the head scaled up about its own center.
	draw_set_transform(h * (1.0 - HEAD_SCALE), 0.0, Vector2(HEAD_SCALE, HEAD_SCALE))
	# Horns sweeping back.
	for k in 2:
		var root := h - u * (6.0 + k * 6.0) + n * 8.0
		var tip := root - u * 18.0 + n * (16.0 - k * 4.0)
		draw_primitive(PackedVector2Array([root + u * 3.0, root - u * 3.0, tip]), PackedColorArray([DEEP, DEEP, HOT]),
			PackedVector2Array())
	# Lower jaw.
	var lower := PackedVector2Array([h - u * 8.0 - n * 2.0, h + ld * 24.0 - n * 2.0, h + ld * 20.0 - n * 7.0, h - u * 6.0 - n * 9.0])
	draw_colored_polygon(lower, DEEP)
	draw_colored_polygon(PackedVector2Array([lower[0], lower[1], lower[3]]), BODY)
	# Mouth fire between the jaws.
	if jaw > 0.1:
		draw_primitive(PackedVector2Array([h - u * 4.0, h + u * 24.0 + n * 1.0, h + ld * 22.0 - n * 3.0]),
			PackedColorArray([HOT, WHITE, WHITE]), PackedVector2Array())
	# Upper skull and snout.
	var skull := PackedVector2Array([h - u * 14.0 + n * 6.0, h - u * 2.0 + n * 12.0, h + u * 18.0 + n * 6.0, h + u * 28.0 + n * 1.0,
		h + u * 24.0 - n * 2.0, h - u * 10.0 - n * 4.0])
	draw_colored_polygon(skull, BODY)
	draw_colored_polygon(PackedVector2Array([skull[0], skull[1], skull[2], h + u * 6.0 + n * 3.0]), BRIGHT)
	draw_line((h - u * 10.0 + n * 10.0).round(), (h + u * 22.0 + n * 4.0).round(), HOT, -1.0)
	# Teeth.
	for k in 3:
		var tp := h + u * (8.0 + k * 6.0) - n * 1.0
		draw_line(tp.round(), (tp - n * 3.0).round(), WHITE, -1.0)
	# Glowing eye with brow.
	var eye := h + u * 2.0 + n * 6.0
	draw_rect(Rect2((eye - Vector2(2, 1)).round(), Vector2(5, 3)), DEEP)
	draw_rect(Rect2((eye - Vector2(1, 1)).round(), Vector2(3, 2)), WHITE if int(_time * 6.0) % 5 else HOT)
	draw_line((eye + n * 3.0 - u * 3.0).round(), (eye + n * 2.0 + u * 5.0).round(), DEEP, -1.0)
	draw_set_transform(Vector2.ZERO)


func _draw_wings(shoulder: Vector2, spread: float) -> void:
	for side in [-1.0, 1.0]:
		var flap := sin(_time * 3.0) * 6.0
		var pts := [shoulder, shoulder + Vector2(side * 70.0, -70.0 + flap) * spread, shoulder + Vector2(side * 110.0, -30.0 + flap) * spread,
			shoulder + Vector2(side * 90.0, 10.0) * spread, shoulder + Vector2(side * 60.0, 0.0) * spread,
			shoulder + Vector2(side * 40.0, 22.0) * spread]
		var poly := PackedVector2Array(pts)
		draw_colored_polygon(poly, Color(DEEP, 0.85))
		var inner := PackedVector2Array()
		for p in pts:
			inner.append(shoulder + (p - shoulder) * 0.8)
		draw_colored_polygon(inner, Color(BODY, 0.55))
		# Bone ribs and burning trailing edge.
		for k in [1, 2, 3]:
			draw_line(shoulder.round(), (pts[k] as Vector2).round(), BRIGHT, -1.0)
		for k in range(1, pts.size() - 1):
			var a: Vector2 = pts[k]
			var b: Vector2 = pts[k + 1]
			draw_line(a.round(), b.round(), HOT, -1.0)
			var mid := (a + b) * 0.5
			var out := (mid - shoulder).normalized()
			draw_primitive(PackedVector2Array([mid - out.orthogonal() * 4.0, mid + out.orthogonal() * 4.0,
				mid + out * (8.0 + 4.0 * sin(_time * 14.0 + k))]), PackedColorArray([BRIGHT, BRIGHT, Color(HOT, 0.5)]),
				PackedVector2Array())
