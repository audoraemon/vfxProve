class_name DragonSprite
extends Node2D
## Fire dragon from PixelLab PixMiniMax clips (assets/pixellab/dragon_video), locked facing south-east
## (screen down-right) like the concept: a 16-frame idle loop and a roar clip (head lowers, jaws open, head
## turns left to right, head rises) with no fire of its own, so the procedural flame jet is the only fire.
## Rising and sinking clip the sprite at the ground line so it climbs out of its lava hole.
## Positioned on its ground point; the lava hole in the art sits on that point.

const IDLE := preload("res://assets/pixellab/dragon_video/dragon_idle.png")
## Frames 8..24 of the generated clip, cleaned of stray embers (the first frames spat an unwanted plume).
const ROAR := preload("res://assets/pixellab/dragon_video/dragon_roar.png")
const FRAME := 256.0
const IDLE_FRAMES := 16
const SCALE := 1.5
## Art pixel under the ground point (center of the lava hole).
const FOOT := Vector2(128, 236)
const IDLE_FPS := 12.0
## Roar strip frames per phase: the head-raise frames played backward lower the head, the middle frames hold
## the open-jaw roar while the head turns, the head-raise frames settle back into the idle pose.
const INHALE_SEQ := [16, 15, 14, 13, 12]
const FIRE_SEQ := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
const RECOVER_SEQ := [12, 13, 14, 15, 16]
## Mouth in art pixels per roar strip frame (sparse keys, interpolated); idle uses the rest pose.
const MOUTH_REST := Vector2(169, 131)
const MOUTH_KEYS := [[0, Vector2(195, 156)], [3, Vector2(195, 164)], [6, Vector2(195, 156)], [9, Vector2(195, 159)],
	[11, Vector2(205, 154)], [13, Vector2(205, 156)], [14, Vector2(200, 148)], [15, Vector2(190, 133)],
	[16, Vector2(169, 131)]]

## 0 buried .. 1 fully out of the ground.
var rise := 0.0
var fade := 1.0

var _time := 0.0
## Seconds into the breath clip, or -1 while idle.
var _breath_t := -1.0
var _inhale := 0.5
var _fire := 2.4
var _recover := 0.4


## Play the roar: `inhale` seconds to lower the head, `fire` seconds holding the open jaws while the head turns,
## `recover` seconds to raise the head back into the idle pose.
func breathe(inhale: float, fire: float, recover: float) -> void:
	_inhale = maxf(inhale, 0.01)
	_fire = maxf(fire, 0.01)
	_recover = maxf(recover, 0.01)
	_breath_t = 0.0


func _process(delta: float) -> void:
	_time += delta
	if _breath_t >= 0.0:
		_breath_t += delta
		if _breath_t >= _inhale + _fire + _recover:
			_breath_t = -1.0
	queue_redraw()


## [texture, frame index]
func _frame() -> Array:
	if _breath_t < 0.0:
		return [IDLE, int(_time * IDLE_FPS) % IDLE_FRAMES]
	var t := _breath_t
	if t < _inhale:
		return [ROAR, _pick(INHALE_SEQ, t / _inhale)]
	t -= _inhale
	if t < _fire:
		return [ROAR, _pick(FIRE_SEQ, t / _fire)]
	return [ROAR, _pick(RECOVER_SEQ, (t - _fire) / _recover)]


func _pick(seq: Array, k: float) -> int:
	return seq[clampi(int(k * seq.size()), 0, seq.size() - 1)]


func _art_to_local(p: Vector2) -> Vector2:
	return (p - FOOT) * SCALE + Vector2(0, (1.0 - clampf(rise, 0.0, 1.0)) * FRAME * SCALE)


func mouth_pos() -> Vector2:
	var fr := _frame()
	if fr[0] == IDLE:
		return _art_to_local(MOUTH_REST)
	return mouth_at(fr[1])


## Local mouth position for a roar strip frame.
func mouth_at(idx: int) -> Vector2:
	var art: Vector2 = MOUTH_KEYS[0][1]
	for i in MOUTH_KEYS.size() - 1:
		var a: int = MOUTH_KEYS[i][0]
		var b: int = MOUTH_KEYS[i + 1][0]
		if idx >= a and idx <= b:
			art = (MOUTH_KEYS[i][1] as Vector2).lerp(MOUTH_KEYS[i + 1][1], float(idx - a) / float(b - a))
			break
	return _art_to_local(art)


func _draw() -> void:
	if rise <= 0.01 or fade <= 0.01:
		return
	modulate.a = fade
	var fr := _frame()
	var tex: Texture2D = fr[0]
	# Clip at the ground line: only the part above the ground has emerged.
	var sink_px := (1.0 - clampf(rise, 0.0, 1.0)) * FRAME
	var visible_h := minf(FOOT.y - sink_px + 16.0, FRAME)
	if visible_h <= 0.0:
		return
	var src := Rect2(Vector2(int(fr[1]) * FRAME, 0), Vector2(FRAME, visible_h))
	draw_texture_rect_region(tex, Rect2(_art_to_local(Vector2.ZERO), src.size * SCALE), src)
