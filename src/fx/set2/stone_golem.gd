class_name StoneGolem
extends Node2D
## Ancient stone titan's upper body rising out of the ground, built from chamfered lit stone blocks.
## Positioned on its ground point (screen). Arms reach toward fist targets (local screen px) set by the effect.

const STONE_TOP := Color("9c8c72")
const STONE := Color("6e6252")
const STONE_SIDE := Color("4a4036")
const STONE_DARK := Color("2e2822")
const EDGE := Color("1a1512")
const RIM := Color("ffcf70")
const GOLD := Color("ffd060")
const GOLD_HOT := Color("fff6d0")

## 0 buried .. 1 fully risen.
var emerge := 0.0
## Eye and rune glow 0..1.
var glow := 0.0
## Crumble 0..1 (blocks sag and fall apart).
var crumble := 0.0
var fist_l := Vector2(-70, -40)
var fist_r := Vector2(70, -40)
var lights: LightField
var ground_pos := Vector2.ZERO
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if emerge <= 0.01:
		return
	var amb := maxf(lights.ambient, 0.62) if lights else 1.0
	var lit := lights.sample(ground_pos) if lights else Color.BLACK
	var tint := Color(amb + lit.r * 0.22, amb + lit.g * 0.22, amb + lit.b * 0.22)
	# Below-ground offset while emerging; slight breathing bob when risen.
	var rise := (1.0 - emerge) * 55.0 + sin(_time * 1.5) * 1.5 * emerge + crumble * 40.0
	modulate.a = clampf(emerge * 1.6, 0.0, 1.0)
	var shoulder_l := Vector2(-52, -96 + rise)
	var shoulder_r := Vector2(52, -96 + rise)
	# Back arm first (by screen depth), then torso, then front arm.
	var arms := [[shoulder_l, fist_l, -1.0], [shoulder_r, fist_r, 1.0]]
	arms.sort_custom(func(a, b): return (a[1] as Vector2).y < (b[1] as Vector2).y)
	_arm(arms[0][0], arms[0][1], arms[0][2], tint)
	_torso(rise, tint)
	_arm(arms[1][0], arms[1][1], arms[1][2], tint)


func _torso(rise: float, tint: Color) -> void:
	var c := func(v: Vector2) -> Vector2: return v + Vector2(0, rise)
	var sag := crumble * 18.0
	# Abdomen and hips, sinking into rubble.
	_block(c.call(Vector2(-20, -20 + sag)), Vector2(34, 30), tint, 0.9)
	_block(c.call(Vector2(20, -22 + sag)), Vector2(32, 32), tint, 1.0)
	_block(c.call(Vector2(0, -44 + sag * 0.8)), Vector2(46, 26), tint, 1.05)
	# Chest plates.
	_block(c.call(Vector2(-22, -76 + sag * 0.6)), Vector2(42, 38), tint, 1.0)
	_block(c.call(Vector2(22, -78 + sag * 0.6)), Vector2(42, 40), tint, 1.08)
	# Gold rune cracks glowing across the chest.
	if glow > 0.02:
		var g := Color(GOLD, glow)
		var ch: Vector2 = c.call(Vector2(0, -76 + sag * 0.6))
		for seg in [[Vector2(-4, -14), Vector2(2, -2)], [Vector2(2, -2), Vector2(-3, 10)], [Vector2(2, -2), Vector2(14, 2)],
				[Vector2(-3, 10), Vector2(6, 18)], [Vector2(-22, -6), Vector2(-10, 0)]]:
			draw_line((ch + seg[0]).round(), (ch + seg[1]).round(), g, -1.0)
			draw_line((ch + seg[0] + Vector2(1, 0)).round(), (ch + seg[1] + Vector2(1, 0)).round(), Color(GOLD_HOT, glow * 0.7), -1.0)
	# Shoulder boulders.
	_block(c.call(Vector2(-54, -98 + sag * 0.5)), Vector2(34, 32), tint, 0.95)
	_block(c.call(Vector2(54, -100 + sag * 0.5)), Vector2(36, 34), tint, 1.1)
	# Head: brow ridge, face block, glowing eyes.
	var head: Vector2 = c.call(Vector2(0, -118 + sag * 0.4))
	_block(head, Vector2(30, 28), tint, 1.0)
	_block(head + Vector2(0, -12), Vector2(34, 10), tint, 1.15)
	var eye := Color(GOLD_HOT.lerp(GOLD, 0.3), 0.35 + 0.65 * glow)
	for sx in [-8.0, 5.0]:
		draw_rect(Rect2((head + Vector2(sx, -4)).round(), Vector2(5, 3)), EDGE)
		draw_rect(Rect2((head + Vector2(sx + 1, -4)).round(), Vector2(3, 2)), eye)
	if glow > 0.5:
		for sx in [-6.0, 7.0]:
			draw_rect(Rect2((head + Vector2(sx - 2, -5)).round(), Vector2(6, 1)), Color(GOLD, (glow - 0.5) * 1.4))
	draw_line((head + Vector2(-6, 7)).round(), (head + Vector2(6, 7)).round(), EDGE, -1.0)


func _arm(shoulder: Vector2, fist: Vector2, side: float, tint: Color) -> void:
	# Elbow bends outward and up so arms read as heavy and bent.
	var mid := (shoulder + fist) * 0.5
	var reach := shoulder.distance_to(fist)
	var bend := maxf(0.0, 110.0 - reach) * 0.45 + 12.0
	var elbow := mid + Vector2(side * bend, -bend * 0.4)
	var crumble_drop := crumble * 30.0
	for k in 3:
		var p := shoulder.lerp(elbow, (k + 0.5) / 3.0)
		_block(p + Vector2(0, crumble_drop * k * 0.3), Vector2(26 - k * 1.5, 24 - k), tint, 0.95 + k * 0.03)
	for k in 3:
		var p := elbow.lerp(fist, (k + 0.3) / 3.0)
		_block(p + Vector2(0, crumble_drop * 0.8), Vector2(24, 22), tint, 1.0)
	# Knuckle fist: palm block with four knuckle blocks on top.
	var f := fist + Vector2(0, crumble_drop)
	_block(f + Vector2(0, 4), Vector2(34, 26), tint, 1.02)
	for k in 4:
		_block(f + Vector2(-12 + k * 8, -10), Vector2(9, 10), tint, 1.12 - k * 0.03)
	_block(f + Vector2(side * 16, 2), Vector2(10, 16), tint, 0.9)
	if glow > 0.3:
		draw_line((f + Vector2(-14, 0)).round(), (f + Vector2(14, 0)).round(), Color(GOLD, glow * 0.6), -1.0)


## Chamfered stone block: lit top band, front face, shaded right side, dark outline.
func _block(center: Vector2, size: Vector2, tint: Color, tone: float) -> void:
	var w := size.x * 0.5
	var h := size.y * 0.5
	var ch := minf(w, h) * 0.35
	var poly := PackedVector2Array([
		center + Vector2(-w + ch, -h), center + Vector2(w - ch, -h), center + Vector2(w, -h + ch),
		center + Vector2(w, h - ch), center + Vector2(w - ch, h), center + Vector2(-w + ch, h),
		center + Vector2(-w, h - ch), center + Vector2(-w, -h + ch),
	])
	var outline := PackedVector2Array()
	for p in poly:
		outline.append(center + (p - center) * 1.0 + (p - center).normalized())
	draw_colored_polygon(outline, EDGE * tint)
	draw_colored_polygon(poly, STONE * tint * tone)
	draw_colored_polygon(PackedVector2Array([poly[0], poly[1], poly[2], center + Vector2(w - 2, -h + ch + 3),
		center + Vector2(-w + 2, -h + ch + 3), poly[7]]), STONE_TOP * tint * tone)
	draw_colored_polygon(PackedVector2Array([poly[2], poly[3], poly[4], center + Vector2(w - 5, h - 2),
		center + Vector2(w - 5, -h + ch + 2)]), STONE_SIDE * tint * tone)
	# Weathered speckles and a mossy/dark lower band.
	var hk := absi(int(center.x * 13.0) ^ int(center.y * 7.0))
	for i in 3:
		var sp := center + Vector2(float((hk >> (i * 3)) % 9) - 4.0, float((hk >> (i * 5)) % 7) - 1.0) * Vector2(w, h) / 5.0
		draw_rect(Rect2(sp.round(), Vector2(2, 1)), STONE_DARK * tint)
	draw_line((poly[6] + Vector2(1, 0)).round(), (poly[4] - Vector2(1, 0)).round(), STONE_DARK * tint * tone, -1.0)
	# Golden rim light from the runes along the left edge.
	if glow > 0.05:
		draw_line(poly[7].round(), poly[6].round(), Color(RIM, 0.55 * glow), -1.0)
		draw_line(poly[0].round(), poly[7].round(), Color(RIM, 0.4 * glow), -1.0)
	# A crack for texture.
	if size.x > 20.0:
		var k := fposmod(center.x * 0.37 + center.y * 0.11, 1.0)
		draw_line((center + Vector2(-w * 0.4 + k * 6.0, -h * 0.1)).round(), (center + Vector2(-w * 0.1, h * 0.5)).round(),
			STONE_DARK * tint, -1.0)
