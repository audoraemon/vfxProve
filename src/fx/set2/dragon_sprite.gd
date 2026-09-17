class_name DragonSprite
extends Node2D
## Fire dragon from PixelLab PixMiniMax clips (assets/pixellab/dragon_video), always facing the camera like
## the concept: a 16-frame idle loop and a 24-frame breath clip (rear back, head down, fire sweeping across
## the ground, recover). No direction switching; the whole sprite mirrors when the sweep runs right to left.
## Rising and sinking clip the sprite at the ground line so it climbs out of its lava hole.
## Positioned on its ground point; the lava hole in the art sits on that point.

const IDLE := preload("res://assets/pixellab/dragon_video/dragon_idle.png")
const BREATH := preload("res://assets/pixellab/dragon_video/dragon_breath.png")
const FRAME := 256.0
const IDLE_FRAMES := 16
const SCALE := 1.5
## Art pixel under the ground point (center of the lava hole).
const FOOT := Vector2(128, 236)
const IDLE_FPS := 12.0
## Breath clip phases (last frame of each): rear back and lower the head, breathe fire, recover.
const INHALE_END := 7
const FIRE_END := 21
const BREATH_LAST := 24
## Mouth in art pixels keyed by breath frame; idle uses frame 0.
const MOUTH_KEYS := [[0, Vector2(169, 131)], [4, Vector2(149, 90)], [7, Vector2(177, 154)], [9, Vector2(184, 149)],
	[12, Vector2(179, 143)], [15, Vector2(179, 149)], [18, Vector2(192, 154)], [21, Vector2(192, 149)],
	[24, Vector2(169, 131)]]

## 0 buried .. 1 fully out of the ground.
var rise := 0.0
var fade := 1.0
## Mirror the art so the head and fire sweep toward screen left.
var mirrored := false

var _time := 0.0
## Seconds into the breath clip, or -1 while idle.
var _breath_t := -1.0
var _inhale := 0.5
var _fire := 2.4
var _recover := 0.4


## Play the breath clip: `inhale` seconds to rear back and lower the head, `fire` seconds of breathing,
## `recover` seconds to settle back into the idle pose.
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
		return [BREATH, mini(int(t / _inhale * (INHALE_END + 1)), INHALE_END)]
	t -= _inhale
	var fire_frames := FIRE_END - INHALE_END
	if t < _fire:
		return [BREATH, INHALE_END + 1 + mini(int(t / _fire * fire_frames), fire_frames - 1)]
	t -= _fire
	return [BREATH, mini(FIRE_END + 1 + int(t / _recover * (BREATH_LAST - FIRE_END)), BREATH_LAST)]


func _art_to_local(p: Vector2) -> Vector2:
	var v := (p - FOOT) * SCALE
	if mirrored:
		v.x = -v.x
	return v + Vector2(0, (1.0 - clampf(rise, 0.0, 1.0)) * FRAME * SCALE)


func mouth_pos() -> Vector2:
	var fr := _frame()
	return mouth_at(fr[1] if fr[0] == BREATH else 0)


## Local mouth position for a breath clip frame.
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
	var top_left := _art_to_local(Vector2.ZERO)
	var size := src.size * SCALE
	if mirrored:
		# Flip around the art's left edge so the mirrored art stays centered on the lava hole.
		draw_set_transform(Vector2(top_left.x, 0), 0.0, Vector2(-1, 1))
		draw_texture_rect_region(tex, Rect2(Vector2(0, top_left.y), size), src)
		draw_set_transform(Vector2.ZERO)
	else:
		draw_texture_rect_region(tex, Rect2(top_left, size), src)
