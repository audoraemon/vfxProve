class_name GolemSprite
extends Node2D
## Stone titan from PixelLab PixMiniMax clips (assets/pixellab/golem), locked facing the camera like the
## concept: an idle loop, knuckle punches landing at eight different spots around its front and a two-handed
## slam. Rising and crumbling clip
## the sprite at the ground line so it climbs out of (and sinks back into) its glowing crater.
## Positioned on its ground point; the crater in the art sits on that point.

const FRAME := 256.0
const SCALE := 1.6
const IDLE_FPS := 10.0
## Art pixel under the ground point (center of the crater) for clips made from the original start frame, and
## for the "reach" clips made from a start frame placed higher on the canvas so the arm can reach forward.
const FOOT := Vector2(128, 244)
const FOOT_REACH := Vector2(128, 170)
## Clip: texture, strip frames to play, position in that list where the fist lands, fist landing spot (art px),
## crater anchor (art px). The reach clips hold the fist down for many frames; most of the hold is skipped.
const CLIPS := {
	"idle": [preload("res://assets/pixellab/golem/golem_idle.png"), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], -1, Vector2.ZERO, FOOT],
	"punch_l": [preload("res://assets/pixellab/golem/golem_punch_l.png"), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 6, Vector2(80, 231), FOOT],
	"punch_r": [preload("res://assets/pixellab/golem/golem_punch_r.png"), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], 8, Vector2(180, 231), FOOT],
	"reach_lf": [preload("res://assets/pixellab/golem/golem_reach_lf.png"), [0, 2, 4, 5, 6, 13, 14, 15, 16], 3, Vector2(76, 215), FOOT_REACH],
	"reach_rf": [preload("res://assets/pixellab/golem/golem_reach_rf.png"), [0, 2, 4, 5, 6, 13, 14, 15, 16], 3, Vector2(177, 218), FOOT_REACH],
	"reach_lw": [preload("res://assets/pixellab/golem/golem_reach_lw.png"), [0, 2, 3, 4, 5, 14, 15, 16], 3, Vector2(59, 212), FOOT_REACH],
	"reach_rw": [preload("res://assets/pixellab/golem/golem_reach_rw.png"), [0, 2, 3, 4, 5, 6, 14, 15, 16], 4, Vector2(195, 211), FOOT_REACH],
	"reach_lc": [preload("res://assets/pixellab/golem/golem_reach_lc.png"), [0, 2, 4, 5, 6, 13, 14, 15, 16], 3, Vector2(121, 205), FOOT_REACH],
	"reach_rc": [preload("res://assets/pixellab/golem/golem_reach_rc.png"), [0, 2, 4, 5, 6, 13, 14, 15, 16], 3, Vector2(126, 213), FOOT_REACH],
	"slam": [preload("res://assets/pixellab/golem/golem_slam.png"), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20], 8, Vector2(128, 236), FOOT],
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
	return _art_to_local(CLIPS[clip][3], CLIPS[clip][4])


## Local point above the head where energy gathers for the final slam.
func crown() -> Vector2:
	return _art_to_local(Vector2(128, 40), FOOT)


func _process(delta: float) -> void:
	_time += delta
	if _clip != "idle":
		_clip_t += delta
		if _clip_t >= _before + _after:
			_clip = "idle"
	queue_redraw()


## Strip frame index for the current time.
func _frame() -> int:
	var c: Array = CLIPS[_clip]
	var frames: Array = c[1]
	var count := frames.size()
	var hit: int = c[2]
	if hit < 0:
		return frames[int(_time * IDLE_FPS) % count]
	if _clip_t < _before:
		return frames[mini(int(_clip_t / _before * hit), hit)]
	return frames[mini(hit + int((_clip_t - _before) / _after * (count - hit)), count - 1)]


func _art_to_local(p: Vector2, foot: Vector2) -> Vector2:
	return (p - foot) * SCALE + Vector2(0, (1.0 - clampf(emerge, 0.0, 1.0)) * FRAME * SCALE)


func _draw() -> void:
	if emerge <= 0.01 or fade <= 0.01:
		return
	modulate.a = fade
	var tex: Texture2D = CLIPS[_clip][0]
	var foot: Vector2 = CLIPS[_clip][4]
	# Clip at the ground line: only the part above the ground has emerged. Reach clips show their full
	# height once risen so fists planted in front of the crater stay visible.
	var sink_px := (1.0 - clampf(emerge, 0.0, 1.0)) * FRAME
	var visible_h := minf(foot.y - sink_px + 10.0, FRAME)
	if emerge >= 0.999:
		visible_h = FRAME
	if visible_h <= 0.0:
		return
	var src := Rect2(Vector2(_frame() * FRAME, 0), Vector2(FRAME, visible_h))
	var shudder := Vector2.ZERO
	if crumble > 0.0:
		shudder = Vector2(sin(_time * 53.0), cos(_time * 41.0)) * 3.0 * crumble
	draw_texture_rect_region(tex, Rect2((_art_to_local(Vector2.ZERO, foot) + shudder).round(), src.size * SCALE), src)
