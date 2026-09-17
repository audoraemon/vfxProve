class_name GolemSprite
extends Node2D
## Stone titan from PixelLab PixMiniMax clips (assets/pixellab/golem), locked facing the camera like the
## concept: an idle loop, a left and a right knuckle punch and a two-handed slam. Rising and crumbling clip
## the sprite at the ground line so it climbs out of (and sinks back into) its glowing crater.
## Positioned on its ground point; the crater in the art sits on that point.

const FRAME := 256.0
const SCALE := 1.6
## Art pixel under the ground point (center of the crater).
const FOOT := Vector2(128, 244)
const IDLE_FPS := 10.0
## Clip: texture, frames to play, index (into frames) where the fist lands, fist landing spot in art px.
const CLIPS := {
	"idle": [preload("res://assets/pixellab/golem/golem_idle.png"), 16, -1, Vector2.ZERO],
	"punch_l": [preload("res://assets/pixellab/golem/golem_punch_l.png"), 11, 6, Vector2(80, 231)],
	"punch_r": [preload("res://assets/pixellab/golem/golem_punch_r.png"), 13, 8, Vector2(180, 231)],
	"slam": [preload("res://assets/pixellab/golem/golem_slam.png"), 21, 8, Vector2(128, 236)],
}

## 0 buried .. 1 fully out of the ground.
var emerge := 0.0
var fade := 1.0
## 0..1 while crumbling: the titan shudders as it sinks.
var crumble := 0.0

var _time := 0.0
var _clip := "idle"
var _clip_t := 0.0
var _before := 0.0
var _after := 0.0


## Play an attack clip: frames up to the impact take `before` seconds, the rest `after` seconds.
## Returns the local screen position where the fist lands.
func play(clip: String, before: float, after: float) -> Vector2:
	_clip = clip
	_clip_t = 0.0
	_before = maxf(before, 0.01)
	_after = maxf(after, 0.01)
	return impact_pos(clip)


func impact_pos(clip: String) -> Vector2:
	return _art_to_local(CLIPS[clip][3])


## Local point above the head where energy gathers for the final slam.
func crown() -> Vector2:
	return _art_to_local(Vector2(128, 40))


func _process(delta: float) -> void:
	_time += delta
	if _clip != "idle":
		_clip_t += delta
		if _clip_t >= _before + _after:
			_clip = "idle"
	queue_redraw()


func _frame() -> int:
	var c: Array = CLIPS[_clip]
	var count: int = c[1]
	var hit: int = c[2]
	if hit < 0:
		return int(_time * IDLE_FPS) % count
	if _clip_t < _before:
		return mini(int(_clip_t / _before * hit), hit)
	return mini(hit + int((_clip_t - _before) / _after * (count - hit)), count - 1)


func _art_to_local(p: Vector2) -> Vector2:
	return (p - FOOT) * SCALE + Vector2(0, (1.0 - clampf(emerge, 0.0, 1.0)) * FRAME * SCALE)


func _draw() -> void:
	if emerge <= 0.01 or fade <= 0.01:
		return
	modulate.a = fade
	var tex: Texture2D = CLIPS[_clip][0]
	# Clip at the ground line: only the part above the ground has emerged.
	var sink_px := (1.0 - clampf(emerge, 0.0, 1.0)) * FRAME
	var visible_h := minf(FOOT.y - sink_px + 10.0, FRAME)
	if visible_h <= 0.0:
		return
	var src := Rect2(Vector2(_frame() * FRAME, 0), Vector2(FRAME, visible_h))
	var shudder := Vector2.ZERO
	if crumble > 0.0:
		shudder = Vector2(sin(_time * 53.0), cos(_time * 41.0)) * 3.0 * crumble
	draw_texture_rect_region(tex, Rect2((_art_to_local(Vector2.ZERO) + shudder).round(), src.size * SCALE), src)
