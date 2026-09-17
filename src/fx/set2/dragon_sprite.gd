class_name DragonSprite
extends Node2D
## Fire dragon from PixelLab sprite animations (assets/pixellab/dragon8): an 8-frame idle loop and an
## 8-frame breath clip (rear back, lunge down, jaws open) for 8 facing directions. Five directions were
## generated; the other three are mirrors (SW = mirrored SE, W = mirrored E, NE = mirrored NW).
## Rising and sinking clip the sprite at the ground line so it climbs out of its lava hole.
## Control surface driven by the effect: rise, jaw, fade, look_ground(dir), mouth_pos().
## Positioned on its ground point; the lava hole in the art sits on that point.

## Clips are square frames laid out in a 9-frame strip; frame size varies per clip (224 or 236).
const FRAMES := 9
const SCALE := 1.5
const IDLE_FPS := 8.0
## Breath frames 0..OPEN_FRAME play while the jaw opens; OPEN_FRAME..8 ping-pong while breathing.
const OPEN_FRAME := 6
const HOLD_FPS := 7.0
const DIRS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
## True facing -> source clip (PixelLab direction), mirrored, lava-hole foot px, mouth px idle, mouth px
## with jaws open, and whether the breath clip is usable (the north clip turns its head to the camera).
const VIEWS := {
	"south": ["south-west", false, Vector2(109, 200), Vector2(106, 71), Vector2(70, 60), true],
	"south-east": ["south", false, Vector2(113, 201), Vector2(162, 74), Vector2(180, 100), true],
	"south-west": ["south", true, Vector2(113, 201), Vector2(162, 74), Vector2(180, 100), true],
	"east": ["south-east", false, Vector2(111, 197), Vector2(177, 74), Vector2(183, 103), true],
	"west": ["south-east", true, Vector2(111, 197), Vector2(177, 74), Vector2(183, 103), true],
	"north": ["north-east", false, Vector2(104, 191), Vector2(118, 47), Vector2(118, 47), false],
	"north-west": ["north-west", false, Vector2(125, 200), Vector2(83, 47), Vector2(53, 59), true],
	"north-east": ["north-west", true, Vector2(125, 200), Vector2(83, 47), Vector2(53, 59), true],
}

## Idle frames to loop per source clip (the south-west clip flashes white in frames 3-5).
const IDLE_LOOP := {"south-west": [0, 1, 2, 6, 7, 8, 7, 6, 2, 1]}

static var _textures := {}

## 0 buried .. 1 fully out of the ground.
var rise := 0.0
## 0 closed (idle) .. 1 jaws open and breathing.
var jaw := 0.0
var fade := 1.0
## Wing spread is part of the art; kept so the effect's tweens still apply.
var wings := 0.0
## Current facing, one of DIRS.
var facing := "south-east"

var _time := 0.0
var _hold := 0.0


static func _tex(anim: String, src: String) -> Texture2D:
	var key := anim + "_" + src
	if not _textures.has(key):
		_textures[key] = load("res://assets/pixellab/dragon8/%s.png" % key)
	return _textures[key]


## Face the compass direction closest to a ground-space direction (as it looks on screen).
func look_ground(ground_dir: Vector2) -> void:
	var screen := Iso.ground_to_screen(ground_dir)
	if screen.length() < 0.001:
		return
	var idx := posmod(int(round(screen.angle() / (TAU / 8.0))), 8)
	facing = DIRS[idx]


func _process(delta: float) -> void:
	_time += delta
	if jaw >= 0.999:
		_hold += delta
	else:
		_hold = 0.0
	queue_redraw()


## [anim, frame index, open 0..1 for mouth interpolation]
func _frame() -> Array:
	var view: Array = VIEWS[facing]
	var can_breathe: bool = view[5]
	if jaw <= 0.001 or not can_breathe:
		var loop: Array = IDLE_LOOP.get(view[0], [])
		if loop.is_empty():
			return ["idle", int(_time * IDLE_FPS) % FRAMES, 0.0]
		return ["idle", loop[int(_time * IDLE_FPS) % loop.size()], 0.0]
	if jaw < 0.999:
		var i := int(round(jaw * OPEN_FRAME))
		return ["breath", i, float(i) / OPEN_FRAME]
	var span := FRAMES - 1 - OPEN_FRAME
	var k := int(_hold * HOLD_FPS) % (span * 2)
	return ["breath", OPEN_FRAME + (k if k <= span else span * 2 - k), 1.0]


func _art_to_local(p: Vector2) -> Vector2:
	var view: Array = VIEWS[facing]
	var v: Vector2 = (p - (view[2] as Vector2)) * SCALE
	if view[1]:
		v.x = -v.x
	return v + Vector2(0, (1.0 - clampf(rise, 0.0, 1.0)) * _frame_size() * SCALE)


func _frame_size() -> float:
	var view: Array = VIEWS[facing]
	return float(_tex("idle", view[0]).get_height())


func mouth_pos() -> Vector2:
	var view: Array = VIEWS[facing]
	var fr := _frame()
	return _art_to_local((view[3] as Vector2).lerp(view[4], fr[2]))


func head_pos() -> Vector2:
	return mouth_pos()


func _draw() -> void:
	if rise <= 0.01 or fade <= 0.01:
		return
	modulate.a = fade
	var view: Array = VIEWS[facing]
	var fr := _frame()
	var tex := _tex(fr[0], view[0])
	var foot: Vector2 = view[2]
	# Clip at the ground line: only the part above the ground has emerged.
	var frame := float(tex.get_height())
	var sink_px := (1.0 - clampf(rise, 0.0, 1.0)) * frame
	var visible_h := minf(foot.y - sink_px + 6.0, frame)
	if visible_h <= 0.0:
		return
	var src := Rect2(Vector2(int(fr[1]) * frame, 0), Vector2(frame, visible_h))
	var top_left := _art_to_local(Vector2.ZERO)
	var size := src.size * SCALE
	if view[1]:
		# Mirrored: flip around the local x of the art's left edge.
		draw_set_transform(Vector2(top_left.x, 0), 0.0, Vector2(-1, 1))
		draw_texture_rect_region(tex, Rect2(Vector2(0, top_left.y), size), src)
		draw_set_transform(Vector2.ZERO)
	else:
		draw_texture_rect_region(tex, Rect2(top_left, size), src)
