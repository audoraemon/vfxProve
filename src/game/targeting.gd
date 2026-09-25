class_name Targeting
extends Node2D
## Aiming: which slot is picked, the area it would cover drawn on the ground, and the click or drag that turns
## into a cast. A child of Battlefield.ground_plane, so it draws in ground units and its circles come out as
## the right iso ellipses. It knows nothing about the mouse: Mission hands it ground positions, which is also
## what makes it testable headless.

## The player picked another slot.
signal picked(slot: int)

## A drag shorter than this keeps the default direction rather than spinning on a twitch.
const DRAG_MIN := 0.5
const COL_EDGE := Color(1.0, 0.86, 0.35, 0.7)
const COL_INNER := Color(1.0, 0.45, 0.2, 0.8)
const COL_FAINT := Color(1.0, 0.86, 0.35, 0.25)
const COL_BAD := Color(0.9, 0.2, 0.15, 0.7)
## Which way a drag power points when the player barely moved the mouse.
const DEFAULT_DIR := Vector2(1, 0)

## What each power covers, taken from the effect's own constants (the comment names them). Milestone 5 may
## repaint these; it must not invent numbers for them.
const AREAS := {
	# LINE_LENGTH, LINE_HALF_WIDTH, FISSURE_LENGTH
	"heaven": {"shape": "lane", "length": 10.0, "half": 0.7, "fissure": 5.6},
	# PULL_RADIUS, CORE_RADIUS, WANDER_RADIUS
	"tornado": {"shape": "circle", "r": 3.2, "inner": 0.6, "roam": 7.0},
	# CONE_RADIUS, SWEEP_ARC (the dragon is locked to screen down-right, so this cone does not follow the mouse)
	"dragon": {"shape": "cone", "r": 11.0, "arc": 1.0},
	# LENGTH, WIDTH * 0.5
	"tsunami": {"shape": "lane", "length": 6.5, "half": 4.0},
	# RADIUS, KILL_R
	"gravity": {"shape": "circle", "r": 4.5, "inner": 1.5},
	# LENGTH, KILL_HALF_WIDTH
	"laser": {"shape": "lane", "length": 10.0, "half": 2.6},
	# RADIUS
	"orbital": {"shape": "circle", "r": 4.5},
	# RADIUS, VOLCANO_RADIUS
	"cinder": {"shape": "circle", "r": 5.8, "inner": 2.4},
	# RADIUS
	"judgement": {"shape": "circle", "r": 5.2},
	# RADIUS, SPIKE_RADIUS
	"glacial": {"shape": "circle", "r": 5.0, "inner": 4.5},
	# RADIUS, KILL_CORE
	"nova": {"shape": "circle", "r": 5.0, "inner": 1.2},
}

## The focused slot, or -1 when nothing is: the area is only drawn while a power is focused.
var slot := -1
## A left press is in progress on a focused power; the release casts it unless something called it off.
var armed := false
## A drag power has the button down and is being aimed.
var aiming := false

var _rules: Rules
var _crowd: Crowd
## Where the button went down (a cast lands here, not where it came up).
var _press := Vector2.ZERO
## Where the cursor is now, for the preview and the drag's direction.
var _at := Vector2.ZERO


func setup(rules: Rules, crowd: Crowd) -> Targeting:
	_rules = rules
	_crowd = crowd
	_rules.cast_made.connect(_on_cast_made)
	z_index = 5
	z_as_relative = false  # absolute z 5: over the ground and the world, under the overhead layer at 8.
	queue_redraw()  # the first preview: hover() only redraws when the cursor moves, so nothing else would
	return self


## Focus a slot, or unfocus it when it is the one already focused (pressing its key again).
func pick(new_slot: int) -> void:
	if new_slot == slot:
		unfocus()
		return
	slot = new_slot
	armed = false
	aiming = false
	picked.emit(slot)
	queue_redraw()


func unfocus() -> void:
	slot = -1
	armed = false
	aiming = false
	picked.emit(slot)
	queue_redraw()


## The cursor moved. Keeps the preview where the player is looking.
func hover(ground: Vector2) -> void:
	# Mission calls this every frame. A preview that has not moved is not redrawn: this node sits on the ground
	# plane, and redrawing it re-batches the layer the whole town is drawn in.
	if ground.is_equal_approx(_at):
		return
	_at = ground
	if not aiming:
		_press = ground
	queue_redraw()


func press(ground: Vector2) -> void:
	if slot < 0:
		return
	_press = ground
	_at = ground
	armed = true
	aiming = _is_drag()
	queue_redraw()


## The button came up: cast, unless the press was called off. A click power fires from where the button went
## down; a drag power fires from there along the way it was dragged.
func release(ground: Vector2) -> void:
	if not armed:
		return
	_at = ground
	armed = false
	var extra := {}
	if _is_drag():
		extra["dir"] = aim_dir()
	aiming = false
	_rules.cast(slot, _press, extra)
	queue_redraw()


## Call off a press in progress (right-click or Esc while the button is held). True when there was one; the
## power stays focused either way.
func cancel() -> bool:
	var had := armed
	armed = false
	aiming = false
	queue_redraw()
	return had


## Which way a drag power points: the drag itself, or DEFAULT_DIR when the player hardly moved.
func aim_dir() -> Vector2:
	var drag := _at - _press
	return drag.normalized() if drag.length() >= DRAG_MIN else DEFAULT_DIR


func area() -> Dictionary:
	return AREAS.get(_rules.key(slot), {})


func _is_drag() -> bool:
	return String(_rules.power(slot).get("aim", "click")) == "drag"


func _on_cast_made(_slot: int, key: String, at: Vector2) -> void:
	var a: Dictionary = AREAS.get(key, {})
	if String(a.get("shape", "")) == "lane":
		_crowd.on_cast(at, aim_dir(), float(a.length))
	else:
		_crowd.on_cast(at)
	# A power that went out is on its cooldown: unfocus, so its area stops following the cursor.
	unfocus()


func _draw() -> void:
	var a := area()
	if a.is_empty():
		return
	# A power that cannot be cast still shows its area, in red, so the player can aim while it comes back.
	var edge := COL_EDGE if _rules.refusal(slot) == "" else COL_BAD
	match String(a.shape):
		"circle":
			_ring(_press, float(a.r), edge)
			if a.has("inner"):
				_ring(_press, float(a.inner), COL_INNER)
			if a.has("roam"):
				_ring(_press, float(a.roam), COL_FAINT)
		"lane":
			_lane(_press, aim_dir(), float(a.length), float(a.half), edge)
			if a.has("fissure"):
				for i in 8:
					var out := Vector2.RIGHT.rotated(TAU * float(i) / 8.0) * float(a.fissure) * 0.5
					draw_line(_press, _press + out, COL_FAINT, -1.0)
		"cone":
			_cone(_press, float(a.r), float(a.arc), edge)


## Every preview line is drawn twice: a dark stroke a hair outside, then the bright one. Hairlines are all
## this project draws (a pixel line cannot be made thicker), and one gold hairline vanishes over lit stone.
const SHADE := Color(0.05, 0.04, 0.02, 0.75)
## How far outside the bright line the dark one sits, in ground units (about two pixels).
const SHADE_GAP := 0.05


func _ring(at: Vector2, r: float, col: Color) -> void:
	draw_arc(at, r + SHADE_GAP, 0.0, TAU, 48, SHADE, -1.0)
	draw_arc(at, r, 0.0, TAU, 48, col, -1.0)


func _lane(from: Vector2, dir: Vector2, length: float, half: float, col: Color) -> void:
	var unit := Vector2(-dir.y, dir.x)
	for pass_i in 2:
		var grow: float = SHADE_GAP if pass_i == 0 else 0.0
		var side := unit * (half + grow)
		var tip := dir * (length + grow)
		var back := dir * -grow
		draw_polyline(PackedVector2Array([from + back + side, from + tip + side, from + tip - side,
			from + back - side, from + back + side]), SHADE if pass_i == 0 else col, -1.0)
	draw_line(from, from + dir * length, COL_FAINT, -1.0)


func _cone(from: Vector2, r: float, arc: float, col: Color) -> void:
	# The dragon's own start angle: its facing, biased 8 degrees to its right so the jet misses its body.
	var start := Vector2(1, 0).angle() - arc * 0.5 - deg_to_rad(8.0)
	for pass_i in 2:
		var grow: float = SHADE_GAP if pass_i == 0 else 0.0
		var points := PackedVector2Array([from])
		for i in 17:
			points.append(from + Vector2.RIGHT.rotated(start + arc * float(i) / 16.0) * (r + grow))
		points.append(from)
		draw_polyline(points, SHADE if pass_i == 0 else col, -1.0)
