class_name DummyEnemy
extends Node2D
## Placeholder sci-fi trooper. Simulates in ground units, draws itself as pixel art.

enum State { WANDER, KNOCKBACK, PULLED, DEAD }

const WALK_SPEED := 0.6
const KNOCK_DECAY := 8.0
const MIN_PULL_DIST := 0.15
const DEATH_FADE := 1.4

const COL_SHADOW := Color(0, 0, 0, 0.4)
const COL_DARK := Color("1c1f2a")
const COL_ARMOR := Color("4b5566")
const COL_ARMOR_HI := Color("75839a")
const COL_HELMET := Color("333a48")
const COL_VISOR := Color("ff4a2a")
const COL_CHAR := Color("16100e")
const COL_EMBER := Color("ff8a2a")

var ground_pos := Vector2.ZERO
var state := State.WANDER
var bounds := Rect2(-50, -50, 100, 100)
var rng := RandomNumberGenerator.new()

var _velocity := Vector2.ZERO
var _target := Vector2.ZERO
var _idle := 0.0
var _flash := 0.0
var _anim := 0.0
var _dead_time := 0.0
var _lift := 0.0
var _facing := 1


func _ready() -> void:
	_pick_target()
	_sync_position()


func _process(delta: float) -> void:
	tick(delta)
	queue_redraw()


func tick(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	match state:
		State.WANDER:
			_anim += delta
			if _idle > 0.0:
				_idle -= delta
			else:
				var to := _target - ground_pos
				if to.length() < 0.05:
					_idle = rng.randf_range(0.3, 1.6)
					_pick_target()
				else:
					_move(to.normalized() * WALK_SPEED * delta)
		State.KNOCKBACK:
			_move(_velocity * delta)
			_velocity = _velocity.move_toward(Vector2.ZERO, KNOCK_DECAY * delta)
			if _velocity == Vector2.ZERO:
				state = State.WANDER
				_pick_target()
		State.PULLED:
			_anim += delta * 3.0
			_lift = move_toward(_lift, 3.0, 12.0 * delta)
		State.DEAD:
			_dead_time += delta
			modulate.a = clampf(1.0 - (_dead_time - 0.5) / (DEATH_FADE - 0.5), 0.0, 1.0)
			if _dead_time >= DEATH_FADE and is_inside_tree():
				queue_free()
	if state != State.PULLED:
		_lift = move_toward(_lift, 0.0, 20.0 * delta)
	_sync_position()


func knock(v: Vector2) -> void:
	if state == State.DEAD:
		return
	state = State.KNOCKBACK
	_velocity = v


func pull_step(center: Vector2, strength: float, swirl: float, delta: float) -> void:
	if state == State.DEAD:
		return
	state = State.PULLED
	var to := center - ground_pos
	var d := to.length()
	if d <= MIN_PULL_DIST:
		return
	var dir := to / d
	var speed := strength * (0.5 + 0.5 * clampf(1.0 - d / 5.0, 0.0, 1.0))
	var tangential := dir.orthogonal() * swirl * strength * 0.5 * clampf(d / 2.0, 0.0, 1.0)
	var step := (dir * speed + tangential) * delta
	ground_pos += step.limit_length(d - MIN_PULL_DIST)


func release() -> void:
	if state == State.PULLED:
		state = State.WANDER
		_pick_target()


func die(_kind: StringName) -> void:
	state = State.DEAD
	_flash = 0.12
	_dead_time = 0.0
	z_index = -1


func is_alive() -> bool:
	return state != State.DEAD


func flash(seconds: float) -> void:
	_flash = maxf(_flash, seconds)


func _move(step: Vector2) -> void:
	if absf(step.x - step.y) > 0.0001:
		_facing = 1 if step.x - step.y > 0.0 else -1
	ground_pos += step
	ground_pos = ground_pos.clamp(bounds.position, bounds.end)


func _pick_target() -> void:
	var offset := Vector2(rng.randf_range(-2.5, 2.5), rng.randf_range(-2.5, 2.5))
	_target = (ground_pos + offset).clamp(bounds.position, bounds.end)


func _sync_position() -> void:
	position = Iso.ground_to_screen(ground_pos).round()


func _px(x: int, y: int, w: int, h: int, c: Color) -> void:
	if w < 0:
		x += w
		w = -w
	draw_rect(Rect2(x, y, w, h), Color.WHITE if _flash > 0.0 else c)


func _draw() -> void:
	if state == State.DEAD:
		_draw_corpse()
		return
	draw_rect(Rect2(-4, -1, 9, 2), COL_SHADOW)
	var lift := -int(round(_lift))
	var step := int(_anim * 6.0) % 2
	var f := _facing
	# legs
	_px(-3, -5 + lift, 2, 5 - step, COL_DARK)
	_px(1, -5 + lift, 2, 4 + step, COL_DARK)
	# torso
	_px(-4, -11 + lift, 8, 6, COL_ARMOR)
	_px(-4, -11 + lift, 8, 1, COL_ARMOR_HI)
	_px(-5, -11 + lift, 1, 3, COL_HELMET)
	_px(4, -11 + lift, 1, 3, COL_HELMET)
	# helmet + visor
	_px(-3, -15 + lift, 6, 4, COL_HELMET)
	_px(-3, -15 + lift, 6, 1, COL_ARMOR_HI)
	_px(-1 if f > 0 else -2, -13 + lift, 3, 1, COL_VISOR)
	# rifle
	_px(2 * f, -8 + lift, 5 * f, 1, COL_DARK)


func _draw_corpse() -> void:
	var c := Color.WHITE if _flash > 0.0 else COL_CHAR
	draw_rect(Rect2(-5, -2, 10, 2), c)
	draw_rect(Rect2(-3, -3, 5, 1), c)
	if _dead_time < 0.9 and _flash <= 0.0:
		var ember := COL_EMBER
		ember.a = 1.0 - _dead_time / 0.9
		draw_rect(Rect2(-2, -3, 1, 1), ember)
		draw_rect(Rect2(2, -2, 1, 1), ember)
		draw_rect(Rect2(-4, -2, 1, 1), ember)
