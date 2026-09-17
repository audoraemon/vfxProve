class_name DragonSprite
extends Node2D
## Fire dragon from PixelLab sprite animations (assets/pixellab/dragon): an idle loop (wings beating,
## flames flickering) and a breath clip (rears back, lunges down with jaws open). Rising and sinking are
## done here by clipping the sprite at the ground line so it climbs out of its lava hole.
## Same control surface the effect drives: rise, jaw, fade, aim, mouth_pos().
## Positioned on its ground point; the lava hole in the art sits on that point.

const IDLE := preload("res://assets/pixellab/dragon/dragon_idle.png")
const BREATH := preload("res://assets/pixellab/dragon/dragon_breath.png")
const FRAME := Vector2(168, 168)
const FRAMES := 17
const SCALE := 1.5
## Art pixel under the ground point (center of the lava hole).
const FOOT := Vector2(84, 146)
const IDLE_FPS := 10.0
## Breath frames: 0..OPEN_FRAME is the rear-back and lunge, OPEN_FRAME..16 loops while jaws are open.
const OPEN_FRAME := 12
const HOLD_FPS := 8.0
## Mouth position in art pixels per breath frame (idle uses frame 0).
const MOUTH_KEYS := {0: Vector2(126, 44), 10: Vector2(130, 50), 11: Vector2(138, 64), 12: Vector2(145, 79), 16: Vector2(145, 80)}

## 0 buried .. 1 fully out of the ground.
var rise := 0.0
## 0 closed (idle) .. 1 jaws open and breathing.
var jaw := 0.0
var fade := 1.0
## Wing spread is part of the art; kept so the effect's tweens still apply.
var wings := 0.0
var aim := Vector2(80, 0)
## +1 faces screen right, -1 left. 0 = pick from `aim` on first draw.
var facing := 0.0

var _time := 0.0
var _hold := 0.0


func _process(delta: float) -> void:
	_time += delta
	if jaw >= 0.999:
		_hold += delta
	else:
		_hold = 0.0
	queue_redraw()


func _f() -> float:
	if facing == 0.0:
		facing = 1.0 if aim.x >= 0.0 else -1.0
	return facing


## Current strip and frame index.
func _frame() -> Array:
	if jaw <= 0.001:
		return [IDLE, int(_time * IDLE_FPS) % FRAMES]
	if jaw < 0.999:
		return [BREATH, int(round(jaw * OPEN_FRAME))]
	# Ping-pong over the open-jaw frames while breathing.
	var span := FRAMES - 1 - OPEN_FRAME
	var k := int(_hold * HOLD_FPS) % (span * 2)
	return [BREATH, OPEN_FRAME + (k if k <= span else span * 2 - k)]


func _art_to_local(p: Vector2) -> Vector2:
	var v := (p - FOOT) * SCALE
	v.x *= _f()
	return v + Vector2(0, (1.0 - clampf(rise, 0.0, 1.0)) * FRAME.y * SCALE)


func mouth_pos() -> Vector2:
	var fr: Array = _frame()
	var idx: int = fr[1] if fr[0] == BREATH else 0
	var keys := MOUTH_KEYS.keys()
	keys.sort()
	var art: Vector2 = MOUTH_KEYS[keys[0]]
	for i in keys.size() - 1:
		var a: int = keys[i]
		var b: int = keys[i + 1]
		if idx >= a and idx <= b:
			art = (MOUTH_KEYS[a] as Vector2).lerp(MOUTH_KEYS[b], float(idx - a) / float(b - a))
			break
		if idx > b:
			art = MOUTH_KEYS[b]
	return _art_to_local(art)


func head_pos() -> Vector2:
	return mouth_pos()


func _draw() -> void:
	if rise <= 0.01 or fade <= 0.01:
		return
	modulate.a = fade
	var fr: Array = _frame()
	var tex: Texture2D = fr[0]
	var idx: int = fr[1]
	# Clip at the ground line: only the part above the ground has emerged.
	var sink_px := (1.0 - clampf(rise, 0.0, 1.0)) * FRAME.y
	var visible_h := FOOT.y - sink_px + 6.0
	if visible_h <= 0.0:
		return
	var src := Rect2(Vector2(idx * FRAME.x, 0), Vector2(FRAME.x, minf(visible_h, FRAME.y)))
	var top_left := _art_to_local(Vector2.ZERO)
	var size := src.size * SCALE
	if _f() < 0.0:
		draw_set_transform(Vector2(top_left.x, 0), 0.0, Vector2(-1, 1))
		draw_texture_rect_region(tex, Rect2(Vector2(0, top_left.y), size), src)
		draw_set_transform(Vector2.ZERO)
	else:
		draw_texture_rect_region(tex, Rect2(top_left, size), src)
