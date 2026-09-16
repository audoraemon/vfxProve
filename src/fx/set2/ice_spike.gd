class_name IceSpike
extends Node2D
## Faceted ice crystal standing on a ground point (y-sorted in the world layer).
## Shading: shadowed left facet, bright right facet, lit ridge, translucent deep-blue base,
## inner crack lines and a glint near the tip. `grow` drives the rise (overshoot allowed),
## `shatter` sinks and breaks it apart.

const DEEP := Color("16305e")
const MID := Color("3a74c0")
const LIGHT := Color("8cc8f0")
const PALE := Color("d2eeff")
const HI := Color("ffffff")

## Full height in px, base half-width in px, tip lean in px (screen x).
var height := 60.0
var width := 10.0
var lean := 0.0
var grow := 0.0
var shatter := 0.0
var glow := 0.0
## Final fade of the leftover crystal residue.
var fade := 1.0
var seed := 0.0
var lights: LightField
var ground_pos := Vector2.ZERO
var _time := 0.0
var _drawn := PackedFloat32Array()


func _process(delta: float) -> void:
	_time += delta
	# Redraw only when the crystal's look actually changes (growth, shatter, light, glint).
	var l := lights.sample(ground_pos) if lights != null else Color.BLACK
	var amb := lights.ambient if lights != null else 1.0
	var glint := 1.0 if fmod(_time * 1.3 + seed, 2.2) < 0.18 else 0.0
	var state := PackedFloat32Array([snappedf(grow, 0.02), snappedf(shatter, 0.02), snappedf(fade, 0.02),
		snappedf(glow, 0.05), snappedf(amb, 0.05), snappedf(l.r, 0.08), snappedf(l.g, 0.08), snappedf(l.b, 0.08), glint])
	if state != _drawn:
		_drawn = state
		queue_redraw()


func _draw() -> void:
	if grow <= 0.01:
		return
	# Shattering leaves a short jagged stump of crystal residue.
	var h := height * grow * (1.0 - shatter * 0.8)
	var w := width * clampf(0.5 + grow * 0.5, 0.0, 1.2) * (1.0 - shatter * 0.25)
	var alpha := fade * (1.0 - shatter * 0.25)
	if alpha <= 0.0:
		return
	# Emissive ice stays readable in the dark; effect light still brightens it.
	var amb := 1.0
	var lit := Color.BLACK
	if lights != null:
		amb = maxf(lights.ambient, 0.7)
		lit = lights.sample(ground_pos)
	var boost := 1.0 + glow * 0.15

	var left := Vector2(-w, 0)
	var front := Vector2(w * 0.15, w * 0.38)
	var right := Vector2(w, -w * 0.05)
	var tip := Vector2(lean, -h)
	# A shoulder vertex splits each face so the crystal reads as cut, not a flat cone.
	var shoulder_l := left.lerp(tip, 0.55) + Vector2(-w * 0.12, 0)
	var shoulder_r := right.lerp(tip, 0.5) + Vector2(w * 0.1, 0)

	var c_left := _shade(MID, amb, lit, boost, alpha)
	var c_left_up := _shade(LIGHT.lerp(MID, 0.45), amb, lit, boost, alpha)
	var c_right := _shade(LIGHT, amb, lit, boost, alpha)
	var c_right_up := _shade(PALE, amb, lit, boost, alpha)
	var c_deep := _shade(DEEP, amb, lit, boost, alpha * 0.85)

	# Raw triangles: no polygon triangulation per redraw.
	_tri(left, front, shoulder_l, c_left)
	_tri(shoulder_l, front, tip, c_left_up)
	_tri(front, right, shoulder_r, c_right)
	_tri(front, shoulder_r, tip, c_right_up)
	# Translucent, darker base where the crystal meets the ground.
	var base_h := minf(h * 0.22, 12.0)
	var fb := front + Vector2(0, -base_h)
	draw_primitive(PackedVector2Array([left, front, fb, left + Vector2(0, -base_h * 0.7)]),
		PackedColorArray([c_deep, c_deep, c_deep, c_deep]), PackedVector2Array())
	draw_primitive(PackedVector2Array([front, right, right + Vector2(0, -base_h * 0.6), fb]),
		PackedColorArray([c_deep, c_deep, c_deep, c_deep]), PackedVector2Array())

	var hi := Color(HI, alpha * clampf(0.75 + glow * 0.25, 0.0, 1.0))
	draw_line(front.round(), tip.round(), hi, -1.0)
	draw_line(shoulder_r.round(), tip.round(), Color(PALE, alpha * 0.8), -1.0)
	draw_line(left.round(), shoulder_l.round(), Color(MID.lightened(0.2), alpha * 0.8), -1.0)
	# Inner cracks.
	var s := seed
	for i in 2:
		var u := fposmod(sin(s * 12.9 + i * 7.1) * 43758.5, 1.0)
		var a := front.lerp(tip, 0.2 + u * 0.5)
		var b := a + Vector2((u - 0.5) * w * 1.4, -h * 0.12)
		draw_line(a.round(), b.round(), Color(PALE, alpha * 0.55), -1.0)
	if shatter > 0.05:
		for i in 3:
			var u := fposmod(sin(s * 3.3 + i * 5.7) * 9171.3, 1.0)
			var a := left.lerp(right, u) + Vector2(0, -h * 0.3)
			draw_line(a.round(), (a + Vector2(u * 6.0 - 3.0, -h * 0.5)).round(), Color(HI, alpha), -1.0)
	# Glint.
	if fmod(_time * 1.3 + s, 2.2) < 0.18:
		var g := tip.lerp(front, 0.18).round()
		draw_rect(Rect2(g + Vector2(-1, 0), Vector2(3, 1)), HI)
		draw_rect(Rect2(g + Vector2(0, -1), Vector2(1, 3)), HI)


func _tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	draw_primitive(PackedVector2Array([a, b, c]), PackedColorArray([col, col, col]), PackedVector2Array())


func _shade(c: Color, amb: float, lit: Color, boost: float, a: float) -> Color:
	return Color(minf(c.r * amb * boost + lit.r * 0.18, 1.0), minf(c.g * amb * boost + lit.g * 0.18, 1.0),
		minf(c.b * amb * boost + lit.b * 0.18, 1.0), a)
