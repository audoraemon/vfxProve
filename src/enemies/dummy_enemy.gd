class_name DummyEnemy
extends Node2D
## Placeholder sci-fi trooper. Simulates in ground units, draws itself as pixel art.
## Death reads differently per damage type: blasts throw and char, gravity stretches into the core,
## lasers cut the body apart into embers.

enum State { WANDER, KNOCKBACK, PULLED, DEAD }
enum Look { TROOPER, ORC }

const WALK_SPEED := 0.6
const KNOCK_DECAY := 8.0
const MIN_PULL_DIST := 0.15
const DEATH_FADE := 1.6

const COL_SHADOW := Color(0, 0, 0, 0.4)
const COL_DARK := Color("1c1f2a")
const COL_ARMOR := Color("4b5566")
const COL_ARMOR_HI := Color("75839a")
const COL_HELMET := Color("333a48")
const COL_VISOR := Color("ff4a2a")
const COL_CHAR := Color("16100e")
const COL_EMBER := Color("ff8a2a")
const COL_HOT := Color("ffd27a")
const COL_VOID := Color("b98cff")
const COL_ICE := Color("b8e6ff")
const COL_ICE_DEEP := Color("5aa0e8")
const COL_ICE_HI := Color("f4fcff")
## Orc horde skin: dark iron armor, red cloth, green skin.
const ORC_DARK := Color("1e1a1c")
const ORC_ARMOR := Color("4a3f3e")
const ORC_ARMOR_HI := Color("75625a")
const ORC_CLOTH := Color("9a2420")
const ORC_SKIN := Color("5f7a3a")
const ORC_EYE := Color("ffd23a")
const ORC_HORN := Color("c8b89a")
const ORC_BLADE := Color("8c929c")
const ORC_HAFT := Color("5a4a3a")

var ground_pos := Vector2.ZERO
var state := State.WANDER
var bounds := Rect2(-50, -50, 100, 100)
var rng := RandomNumberGenerator.new()
## Optional: effect lights tint the trooper; blocked(ground_pos) -> bool keeps walkers out of buildings.
var lights: LightField
var blocked: Callable
var look := Look.TROOPER
## Height in px a pulled enemy is hoisted to (a tornado carries them up its funnel).
var lift_target := 3.0

var _velocity := Vector2.ZERO
var _target := Vector2.ZERO
var _idle := 0.0
var _flash := 0.0
var _anim := 0.0
var _dead_time := 0.0
var _lift := 0.0
var _facing := 1
var _kind := &""
## Screen-space death motion.
var _fly := Vector2.ZERO
var _fly_vel := Vector2.ZERO
var _alt := 0.0
var _valt := 0.0
var _rot := 0.0
var _spin := 0.0
var _char := 0.0
var _toward := Vector2.ZERO
var _embers: Array[Vector3] = []
var _frozen := 0.0
## Called with this enemy when its ice runs out (e.g. to burst it).
var _on_thaw := Callable()
## Ice shards for the shatter death: x, y position; z, w velocity.
var _shards: Array[Vector4] = []


func _ready() -> void:
	_pick_target()
	_sync_position()


func _process(delta: float) -> void:
	tick(delta)
	if lights != null:
		var l := lights.sample(ground_pos)
		var amb := lights.ambient
		modulate = Color(amb + l.r * 2.5, amb + l.g * 2.5, amb + l.b * 2.5, modulate.a)
	queue_redraw()


func tick(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	if _frozen > 0.0 and state != State.DEAD:
		_frozen = maxf(_frozen - delta, 0.0)
		_sync_position()
		if _frozen <= 0.0 and _on_thaw.is_valid():
			var cb := _on_thaw
			_on_thaw = Callable()
			cb.call(self)
		return
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
			_lift = move_toward(_lift, lift_target, maxf(12.0, lift_target * 3.0) * delta)
		State.DEAD:
			_tick_death(delta)
	if state != State.PULLED:
		_lift = move_toward(_lift, 0.0, 20.0 * delta)
	_sync_position()


func _tick_death(delta: float) -> void:
	_dead_time += delta
	match _kind:
		&"nova", &"orbital", &"lightning", &"cinder", &"stone", &"water", &"wind":
			_fly += _fly_vel * delta
			_fly_vel *= maxf(1.0 - (0.6 if _alt > 0.0 else 6.0) * delta, 0.0)
			_valt -= 520.0 * delta
			_alt = maxf(_alt + _valt * delta, 0.0)
			if _alt > 0.0:
				_rot += _spin * delta
			else:
				_rot = lerp_angle(_rot, PI * 0.5 * signf(_spin), minf(12.0 * delta, 1.0))
			if _kind != &"stone" and _kind != &"water" and _kind != &"wind":
				_char = minf(_char + delta * 3.5, 1.0)
		&"fire":
			_char = minf(_char + delta * 2.2, 1.0)
			for i in _embers.size():
				var e := _embers[i]
				_embers[i] = Vector3(e.x + sin(_dead_time * 9.0 + i) * 6.0 * delta, e.y - 22.0 * delta, e.z - delta * 0.8)
		&"gravity":
			_char = minf(_char + delta * 6.0, 1.0)
		&"ice":
			for i in _shards.size():
				var s := _shards[i]
				_shards[i] = Vector4(s.x + s.z * delta, s.y + s.w * delta, s.z * 0.96, s.w + 260.0 * delta)
		&"laser":
			_fly += Vector2(_facing * 10.0, 6.0) * delta * clampf(0.4 - _dead_time, 0.0, 0.4) * 10.0
			for i in _embers.size():
				var e := _embers[i]
				_embers[i] = Vector3(e.x + sin(_dead_time * 9.0 + i) * 6.0 * delta, e.y - 18.0 * delta, e.z - delta)
		_:
			pass
	var fade_start := 0.25 if _kind == &"gravity" else (0.35 if _kind == &"ice" else 0.6)
	modulate.a = clampf(1.0 - (_dead_time - fade_start) / (DEATH_FADE - fade_start), 0.0, 1.0)
	if _kind == &"gravity" and _dead_time > 0.3:
		modulate.a = 0.0
	if _dead_time >= DEATH_FADE and is_inside_tree():
		queue_free()


## Encase in ice for `seconds`: no walking, pull or knockback until it thaws.
func freeze(seconds: float, on_thaw := Callable()) -> void:
	if state == State.DEAD:
		return
	if on_thaw.is_valid():
		_on_thaw = on_thaw
	if state == State.PULLED or state == State.KNOCKBACK:
		state = State.WANDER
	_velocity = Vector2.ZERO
	_frozen = maxf(_frozen, seconds)


func is_frozen() -> bool:
	return _frozen > 0.0 and state != State.DEAD


func knock(v: Vector2) -> void:
	if state == State.DEAD or is_frozen():
		return
	state = State.KNOCKBACK
	_velocity = v


func pull_step(center: Vector2, strength: float, swirl: float, delta: float) -> void:
	if state == State.DEAD or is_frozen():
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
		lift_target = 3.0
		_pick_target()


## source: ground position the damage came from (INF = none).
func die(kind: StringName, source := Vector2.INF) -> void:
	_frozen = 0.0
	state = State.DEAD
	_kind = kind
	_flash = 0.1
	_dead_time = 0.0
	var away := Vector2.RIGHT.rotated(rng.randf() * TAU)
	if source != Vector2.INF and ground_pos.distance_to(source) > 0.01:
		away = (Iso.ground_to_screen(ground_pos) - Iso.ground_to_screen(source)).normalized()
	match kind:
		&"nova", &"orbital":
			var power := 1.0 if kind == &"nova" else 0.7
			_fly_vel = away * rng.randf_range(60.0, 150.0) * power
			_valt = rng.randf_range(90.0, 190.0) * power
			_alt = 1.0
			_spin = rng.randf_range(8.0, 16.0) * (1.0 if away.x >= 0.0 else -1.0)
		&"lightning", &"cinder", &"stone", &"water", &"wind":
			# power, lift, spin per type: wind flings high and spins, water sweeps along the ground.
			var cfg: Array = {&"lightning": [0.6, 0.8, 1.0], &"cinder": [0.8, 1.0, 1.0], &"stone": [0.9, 0.9, 0.7],
				&"water": [1.3, 0.35, 0.6], &"wind": [0.7, 2.2, 2.2]}[kind]
			_fly_vel = away * rng.randf_range(60.0, 150.0) * cfg[0]
			_valt = rng.randf_range(90.0, 190.0) * cfg[1]
			# Enemies already hoisted (tornado) launch from where they are.
			_alt = maxf(1.0, _lift)
			_spin = rng.randf_range(8.0, 16.0) * cfg[2] * (1.0 if away.x >= 0.0 else -1.0)
			if kind == &"lightning":
				_flash = 0.18
		&"fire":
			_flash = 0.05
			for i in 14:
				_embers.append(Vector3(rng.randf_range(-5, 5), rng.randf_range(-15, -2), rng.randf_range(0.5, 1.3)))
		&"gravity":
			_toward = -away
		&"ice":
			_flash = 0.05
			for i in 14:
				var a := rng.randf() * TAU
				var sp := rng.randf_range(20.0, 75.0)
				_shards.append(Vector4(rng.randf_range(-4, 4), rng.randf_range(-14, -2), cos(a) * sp, sin(a) * sp * 0.6 - 60.0))
		&"laser":
			_flash = 0.06
			for i in 10:
				_embers.append(Vector3(rng.randf_range(-4, 4), rng.randf_range(-12, -2), rng.randf_range(0.4, 1.0)))
	z_index = 0 if kind in [&"nova", &"orbital", &"lightning", &"cinder", &"stone", &"water", &"wind"] else -1


func is_alive() -> bool:
	return state != State.DEAD


func flash(seconds: float) -> void:
	_flash = maxf(_flash, seconds)


func _move(step: Vector2) -> void:
	if absf(step.x - step.y) > 0.0001:
		_facing = 1 if step.x - step.y > 0.0 else -1
	if blocked.is_valid() and blocked.call(ground_pos + step):
		_velocity = Vector2.ZERO
		_idle = rng.randf_range(0.1, 0.5)
		_pick_target()
		return
	ground_pos += step
	ground_pos = ground_pos.clamp(bounds.position, bounds.end)


func _pick_target() -> void:
	var offset := Vector2(rng.randf_range(-2.5, 2.5), rng.randf_range(-2.5, 2.5))
	_target = (ground_pos + offset).clamp(bounds.position, bounds.end)


func _sync_position() -> void:
	position = Iso.ground_to_screen(ground_pos).round()


func _tint(c: Color) -> Color:
	if _flash > 0.0:
		if _kind == &"lightning" and int(_flash * 40.0) % 2 == 0:
			return Color("5aa8ff")
		return Color.WHITE
	if is_frozen():
		# Colors wash to pale ice; in the last second before thawing the original shows through.
		var k := clampf(_frozen, 0.0, 1.0)
		return c.lerp(COL_ICE_DEEP.lerp(COL_ICE, clampf(c.get_luminance() * 1.6, 0.0, 1.0)), 0.75 * k)
	if _kind == &"gravity" and state == State.DEAD:
		return c.lerp(COL_VOID, _char * 0.8)
	return c.lerp(COL_CHAR, _char * 0.85)


func _px(x: int, y: int, w: int, h: int, c: Color) -> void:
	if w < 0:
		x += w
		w = -w
	draw_rect(Rect2(x, y, w, h), _tint(c))


func _draw() -> void:
	if state == State.DEAD:
		match _kind:
			&"nova", &"orbital", &"lightning", &"cinder", &"stone", &"water", &"wind":
				_draw_thrown()
			&"fire":
				_draw_burn()
			&"gravity":
				_draw_stretched()
			&"laser":
				_draw_cut()
			&"ice":
				_draw_shatter()
			_:
				_draw_corpse()
		return
	if _lift > 8.0:
		# Hoisted and tumbling.
		draw_rect(Rect2(-4, -1, 9, 2), Color(0, 0, 0, 0.35 * clampf(1.0 - _lift / 80.0, 0.2, 1.0)))
		draw_set_transform(Vector2(0, -_lift - 7.0).round(), _anim * 1.4)
		_draw_body(7, 0)
		draw_set_transform(Vector2.ZERO)
		return
	draw_rect(Rect2(-4, -1, 9, 2), COL_SHADOW)
	_draw_body(-int(round(_lift)), 0)
	if is_frozen():
		_draw_ice_shell()


## bottom_clip: skip rows below this offset from feet (0 = whole body). Used for the laser cut.
func _draw_body(lift: int, top_only: int) -> void:
	if look == Look.ORC:
		_draw_orc(lift, top_only)
		return
	var step := int(_anim * 6.0) % 2 if state != State.DEAD and not is_frozen() else 0
	var f := _facing
	if top_only == 0:
		_px(-3, -5 + lift, 2, 5 - step, COL_DARK)
		_px(1, -5 + lift, 2, 4 + step, COL_DARK)
	_px(-4, -11 + lift, 8, 6, COL_ARMOR)
	_px(-4, -11 + lift, 8, 1, COL_ARMOR_HI)
	_px(-5, -11 + lift, 1, 3, COL_HELMET)
	_px(4, -11 + lift, 1, 3, COL_HELMET)
	_px(-3, -15 + lift, 6, 4, COL_HELMET)
	_px(-3, -15 + lift, 6, 1, COL_ARMOR_HI)
	if state != State.DEAD or _char < 0.5:
		_px(-1 if f > 0 else -2, -13 + lift, 3, 1, COL_VISOR)
	_px(2 * f, -8 + lift, 5 * f, 1, COL_DARK)


func _draw_thrown() -> void:
	var shadow_a := 0.35 * clampf(1.0 - _alt / 60.0, 0.2, 1.0)
	draw_rect(Rect2(_fly.round() + Vector2(-4, -1), Vector2(9, 2)), Color(0, 0, 0, shadow_a))
	var center := (_fly + Vector2(0, -_alt - 7.0)).round()
	draw_set_transform(center, _rot)
	_draw_body(7, 0)
	# Smouldering while charred.
	if _char > 0.4 and _dead_time < 1.1:
		var ember := COL_EMBER
		ember.a = 1.0 - _dead_time / 1.1
		draw_rect(Rect2(-2, -4, 1, 1), ember)
		draw_rect(Rect2(1, 0, 1, 1), COL_HOT if _dead_time < 0.4 else ember)
		draw_rect(Rect2(-3, 2, 1, 1), ember)
	draw_set_transform(Vector2.ZERO)


## Spaghettified: squeezed thin and dragged toward the singularity, then gone.
func _draw_stretched() -> void:
	var k := clampf(_dead_time / 0.3, 0.0, 1.0)
	var pull := _toward * 26.0 * k * k
	var squash := lerpf(1.0, 0.25, k)
	draw_set_transform(pull.round(), _toward.angle() + PI * 0.5, Vector2(squash, 1.0 + 1.8 * k))
	_draw_body(0, 0)
	draw_set_transform(Vector2.ZERO)


## Cut by the laser: legs drop, torso slides off along a glowing cut, then burns away into embers.
func _draw_cut() -> void:
	var burn := clampf(_dead_time / 0.8, 0.0, 1.0)
	if burn < 1.0:
		# Legs stay put.
		_px(-3, -5, 2, 5, COL_DARK)
		_px(1, -5, 2, 5, COL_DARK)
		draw_set_transform(_fly.round())
		_draw_body(0, 1)
		draw_set_transform(Vector2.ZERO)
		# Molten cut line.
		var cut := COL_HOT if _dead_time < 0.25 else COL_EMBER
		cut.a = 1.0 - burn
		draw_rect(Rect2(Vector2(-4, -6) + _fly.round() * 0.5, Vector2(9, 1)), cut)
	for e in _embers:
		if e.z > 0.0:
			var c := COL_HOT if e.z > 0.6 else COL_EMBER
			c.a = clampf(e.z, 0.0, 1.0)
			draw_rect(Rect2(Vector2(e.x, e.y).round(), Vector2.ONE), c)


## Bulky orc raider: horned iron helm, red cloth, green arms, cleaver.
func _draw_orc(lift: int, top_only: int) -> void:
	var step := int(_anim * 5.0) % 2 if state != State.DEAD and not is_frozen() else 0
	var f := _facing
	if top_only == 0:
		_px(-4, -5 + lift, 3, 5 - step, ORC_DARK)
		_px(1, -5 + lift, 3, 4 + step, ORC_DARK)
	_px(-5, -12 + lift, 10, 7, ORC_ARMOR)
	_px(-5, -12 + lift, 10, 1, ORC_ARMOR_HI)
	_px(-3, -7 + lift, 6, 2, ORC_CLOTH)
	_px(-6, -11 + lift, 1, 4, ORC_SKIN)
	_px(5, -11 + lift, 1, 4, ORC_SKIN)
	_px(-3, -16 + lift, 6, 4, ORC_ARMOR)
	_px(-3, -16 + lift, 6, 1, ORC_ARMOR_HI)
	_px(-4, -18 + lift, 1, 3, ORC_HORN)
	_px(3, -18 + lift, 1, 3, ORC_HORN)
	if state != State.DEAD or _char < 0.5:
		_px(-1 if f > 0 else -2, -14 + lift, 3, 1, ORC_EYE)
	_px(5 * f, -13 + lift, 1, 6, ORC_HAFT)
	_px(5 * f + (1 if f > 0 else -2), -14 + lift, 2, 3, ORC_BLADE)


## Translucent ice block around the frozen body, with facet highlights and frost at the feet.
func _draw_ice_shell() -> void:
	var a := 0.55 * clampf(_frozen / 0.6, 0.0, 1.0)
	var body := PackedVector2Array([Vector2(-7, 1), Vector2(-8, -9), Vector2(-5, -20), Vector2(1, -22),
		Vector2(7, -17), Vector2(8, -6), Vector2(6, 1)])
	draw_colored_polygon(body, Color(COL_ICE.r, COL_ICE.g, COL_ICE.b, a * 0.55))
	var outline := body.duplicate()
	outline.append(body[0])
	draw_polyline(outline, Color(COL_ICE_HI, minf(a * 1.4, 1.0)), -1.0)
	draw_line(Vector2(-5, -19), Vector2(-6, -8), Color(COL_ICE_HI, minf(a * 1.6, 1.0)), -1.0)
	draw_line(Vector2(2, -21), Vector2(6, -16), Color(COL_ICE_HI, minf(a * 1.2, 1.0)), -1.0)
	draw_rect(Rect2(-9, -1, 18, 2), Color(COL_ICE_DEEP, a))
	if fmod(_frozen * 2.3 + float(rng.seed % 7), 1.6) < 0.1:
		draw_rect(Rect2(-5, -19, 1, 1), COL_ICE_HI)


func _draw_shatter() -> void:
	if _dead_time < 0.06:
		_draw_body(0, 0)
		return
	for s in _shards:
		if s.y < 0.0:
			draw_rect(Rect2(Vector2(s.x, s.y).round(), Vector2(2, 1)), COL_ICE_HI if int(absf(s.x) * 3.0) % 2 == 0 else COL_ICE)
		else:
			draw_rect(Rect2(Vector2(s.x, 0).round(), Vector2(1, 1)), COL_ICE_DEEP)


## Burned by dragon fire: blackens where it stands, crumbles to ash with rising embers.
func _draw_burn() -> void:
	var k := clampf((_dead_time - 0.5) / 0.8, 0.0, 1.0)
	if k < 1.0:
		draw_set_transform(Vector2(0, roundf(k * 8.0)), 0.0, Vector2(1.0, 1.0 - k * 0.8))
		_draw_body(0, 0)
		draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(-5, -2, 10, 2), COL_CHAR)
	for e in _embers:
		if e.z > 0.0:
			var c := COL_HOT if e.z > 0.8 else COL_EMBER
			c.a = clampf(e.z, 0.0, 1.0)
			draw_rect(Rect2(Vector2(e.x, e.y).round(), Vector2.ONE), c)


func _draw_corpse() -> void:
	var c := Color.WHITE if _flash > 0.0 else COL_CHAR
	draw_rect(Rect2(-5, -2, 10, 2), c)
	draw_rect(Rect2(-3, -3, 5, 1), c)
