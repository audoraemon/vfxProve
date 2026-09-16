extends FxTimeline
## Walking Laser Grid: lane telegraph -> emitter drones arrive -> beams link -> wall sweeps -> scorched corridor.

const WIDTH := 5.0
const LENGTH := 10.0
const EMITTERS := 5
const KILL_HALF_WIDTH := 2.6
const KILL_BAND := 0.35
const T_ARRIVE := 1.0
const T_LINK := 1.6
const T_WALK := 2.0
const T_STOP := 5.5
const T_DEPART := 5.7
const HOVER_ALT := 82.0
const LINK_HEIGHTS := [16.0, 40.0, 64.0]

const COL_OUTER := Color(0.75, 0.04, 0.08, 0.55)
const COL_MID := Color("ff3a2a")
const COL_CORE := Color("ffd2c4")


## Lane projected on the ground. Local space: x along lane (0..LENGTH), y across (-WIDTH/2..WIDTH/2).
class LaneMarker:
	extends Node2D

	var reveal := 0.0
	var alpha := 1.0
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var hw := WIDTH * 0.5
		var span := LENGTH * reveal
		if span <= 0.01:
			return
		var pulse := 0.8 + 0.2 * sin(_time * 10.0)
		var edge := Color(1.0, 0.25, 0.18, alpha * pulse)
		var grid := Color(1.0, 0.2, 0.15, alpha * 0.35)
		draw_rect(Rect2(0, -hw, span, WIDTH), Color(1.0, 0.15, 0.1, alpha * 0.09))
		var x := 1.0
		while x < span:
			draw_line(Vector2(x, -hw), Vector2(x, hw), grid, -1.0)
			x += 1.0
		for y in range(-2, 3):
			draw_line(Vector2(0, y), Vector2(span, y), grid, -1.0)
		draw_line(Vector2(0, -hw), Vector2(span, -hw), edge, -1.0)
		draw_line(Vector2(0, hw), Vector2(span, hw), edge, -1.0)
		draw_line(Vector2(0, -hw), Vector2(0, hw), edge, -1.0)
		if reveal >= 1.0:
			draw_line(Vector2(LENGTH, -hw), Vector2(LENGTH, hw), edge, -1.0)
		# Direction chevrons down the center.
		var c := 1.5
		while c < span - 0.5:
			var off := fmod(_time * 2.0, 1.0)
			var cx := c + off
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 0.35, -0.3), Vector2(cx + 0.1, 0), Vector2(cx - 0.35, 0.3), Vector2(cx - 0.2, 0)]), edge)
			c += 2.0
		# Emitter anchor nodes along the start edge.
		for i in EMITTERS:
			var p := Vector2(0, i - 2)
			draw_arc(p, 0.22, 0.0, TAU, 12, edge, -1.0)
			draw_rect(Rect2(p - Vector2(0.05, 0.05), Vector2(0.1, 0.1)), Color(1, 0.85, 0.8, alpha))
		# Scan bar sweeping ahead.
		var sx := fmod(_time * 7.0, span)
		draw_line(Vector2(sx, -hw), Vector2(sx, hw), Color(1.0, 0.6, 0.5, alpha * 0.8), -1.0)


## Hovering emitter drone. Positioned on the ground point (y-sorted); draws at altitude.
## Beams are shader quads (bright core + additive halo) so they read as heavy energy beams.
class Drone:
	extends Node2D

	const COL_BODY := Color("3b4150")
	const COL_TOP := Color("7a8496")
	const COL_DARK := Color("222630")
	const COL_EYE := Color("ff4a3a")
	const COL_THRUST := Color("5ab8ff")
	const BEAM_W := 12.0
	const HALO_W := 38.0
	const HALO_COLOR := Color(1.0, 0.2, 0.08)

	var alt := 190.0
	var beam := 0.0
	var link := 0.0
	var next: Drone
	var _time := 0.0
	var _seed := 0.0
	var _halo: QuadFx
	var _core: QuadFx
	var _base_glow: QuadFx
	var _link_core: Array[QuadFx] = []
	var _link_halo: Array[QuadFx] = []
	var _body: Node2D

	func _ready() -> void:
		_halo = QuadFx.new().setup(FxParts.SH_BEAM_ADD, Vector2(HALO_W, 1), Vector2(0.5, 1.0))
		_halo.set_param("color", HALO_COLOR)
		add_child(_halo)
		_core = QuadFx.new().setup(FxParts.SH_BEAM, Vector2(BEAM_W, 1), Vector2(0.5, 1.0))
		FxParts.set_ramp(_core, FxParts.LASER)
		_core.set_param("taper", 0.0)
		# Solid core: no travelling bands, so it reads as one continuous beam.
		_core.set_param("bands", 0.0)
		add_child(_core)
		_base_glow = QuadFx.new().setup(FxParts.SH_LIGHT, Vector2(44, 22))
		_base_glow.set_param("color", HALO_COLOR)
		_base_glow.set_param("falloff", 1.3)
		add_child(_base_glow)
		_body = Node2D.new()
		_body.draw.connect(_draw_body)
		add_child(_body)

	## Called once neighbors are known: build link beams toward the next drone.
	func build_links() -> void:
		if next == null:
			return
		for h in LINK_HEIGHTS:
			var lc := QuadFx.new().setup(FxParts.SH_BEAM, Vector2(6, 1), Vector2(0.5, 0.0))
			FxParts.set_ramp(lc, FxParts.LASER)
			lc.set_param("taper", 0.0)
			lc.set_param("bands", 0.0)
			lc.set_param("intensity", 0.0)
			var lh := QuadFx.new().setup(FxParts.SH_BEAM_ADD, Vector2(20, 1), Vector2(0.5, 0.0))
			lh.set_param("color", HALO_COLOR)
			lh.set_param("intensity", 0.0)
			add_child(lh)
			add_child(lc)
			move_child(_body, -1)
			_link_core.append(lc)
			_link_halo.append(lh)

	func _process(delta: float) -> void:
		_time += delta
		var flick := 0.85 + 0.15 * sin(_time * 60.0 + _seed * 9.0)
		var length := maxf(alt - 3.0, 1.0)
		for q in [_halo, _core]:
			q.size.y = length
			q.queue_redraw()
		_core.set_param("intensity", beam)
		_halo.set_param("intensity", clampf(beam * 1.2 - 0.2, 0.0, 1.0) * flick)
		_base_glow.set_param("intensity", clampf(beam * 1.4 - 0.3, 0.0, 1.4) * flick)
		if next != null and not _link_core.is_empty():
			var d := next.position - position
			for i in _link_core.size():
				var h: float = LINK_HEIGHTS[i]
				var a := Vector2(0, -h)
				var b := d + Vector2(0, -h)
				for q in [_link_core[i], _link_halo[i]]:
					q.position = a
					q.rotation = (b - a).angle() - PI * 0.5
					q.size.y = maxf(a.distance_to(b) * link, 1.0)
					q.queue_redraw()
				_link_core[i].set_param("intensity", link * 0.85)
				_link_halo[i].set_param("intensity", link * 0.8 * flick)
		queue_redraw()
		_body.queue_redraw()

	func _draw() -> void:
		# Under the beams: shadow and glowing contact ring on the ground.
		var sh := clampf(1.0 - alt / 260.0, 0.1, 1.0)
		draw_rect(Rect2(-4, -1, 9, 2), Color(0, 0, 0, 0.35 * sh * modulate.a))
		if beam > 0.3:
			var ring := PackedVector2Array()
			var pulse := 1.0 + 0.15 * sin(_time * 12.0 + _seed)
			for i in 17:
				var a := TAU * i / 16.0
				ring.append((Vector2(cos(a) * 10.0, sin(a) * 5.0) * pulse).round())
			draw_polyline(ring, Color(1.0, 0.45, 0.3, beam), -1.0)
			draw_polyline(PackedVector2Array(Array(ring).map(func(v): return (v * 0.55).round())), Color(1.0, 0.85, 0.75, beam), -1.0)

	func _draw_body() -> void:
		var bob := roundf(sin(_time * 5.0 + _seed) * 1.0)
		var top := -alt + bob
		var flick := fmod(_time * 30.0 + _seed * 7.0, 3.0) < 1.0
		var b := _body
		b.draw_rect(Rect2(-10, top - 3, 3, 2), COL_DARK)
		b.draw_rect(Rect2(8, top - 3, 3, 2), COL_DARK)
		b.draw_rect(Rect2(-8, top - 2, 3, 1), COL_DARK)
		b.draw_rect(Rect2(6, top - 2, 3, 1), COL_DARK)
		b.draw_rect(Rect2(-6, top - 4, 13, 6), COL_BODY)
		b.draw_rect(Rect2(-6, top - 4, 13, 1), COL_TOP)
		b.draw_rect(Rect2(-2, top - 2, 5, 1), COL_EYE)
		b.draw_rect(Rect2(-2, top + 2, 5, 2), Color("ff3a2a") if beam > 0.0 else COL_DARK)
		if beam > 0.0:
			b.draw_rect(Rect2(-1, top + 3, 3, 1), Color("fff0e8"))
		var thrust := COL_THRUST if flick else COL_THRUST.lightened(0.4)
		b.draw_rect(Rect2(-10, top - 1, 3, 1), thrust)
		b.draw_rect(Rect2(8, top - 1, 3, 1), thrust)
		if flick:
			b.draw_rect(Rect2(-9, top, 1, 1), Color(COL_THRUST, 0.6))
			b.draw_rect(Rect2(9, top, 1, 1), Color(COL_THRUST, 0.6))


var _dir := Vector2(1, 0)
var _side := Vector2(0, 1)
var _lane: LaneMarker
var _lane_space: Node2D
var _trail: QuadFx
var _trail_glow: QuadFx
var _flames: PixelParticles
var _next_edge_fire := 0.0
var _fire_voice: Node
var _drones: Array[Drone] = []
var _front := 0.0
var _streaks: PixelParticles
var _hum: Node
var _wall_light: QuadFx
var _wall_haze: QuadFx


func _build() -> void:
	duration = 7.4
	_dir = (extra.get("dir", Vector2(1, 0)) as Vector2).normalized()
	_side = _dir.orthogonal()

	_lane = LaneMarker.new()
	_lane.position = origin
	_lane.rotation = _dir.angle()
	_lane.z_index = 3
	track(_lane, ctx.ground)
	create_tween().tween_property(_lane, "reveal", 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	ctx.play(&"laser_scan", origin)

	# Lane-space node on the ground plane: x along the lane, y across.
	_lane_space = Node2D.new()
	_lane_space.position = origin
	_lane_space.rotation = _dir.angle()
	_lane_space.z_index = 1
	track(_lane_space, ctx.ground)
	_trail = QuadFx.new().setup(FxParts.SH_MOLTEN, Vector2(LENGTH, WIDTH), Vector2(0.0, 0.5))
	FxParts.set_ramp(_trail, FxParts.LAVA)
	_trail.set_param("length_units", LENGTH)
	_trail.set_param("width_units", WIDTH)
	_trail.set_param("seed", ctx.rng.randf() * 50.0)
	_lane_space.add_child(_trail)

	_streaks = FxParts.particles(self, ctx.overhead, Vector2.ZERO, PixelParticles.Shape.STREAK, FxParts.LASER_LIFE)
	_streaks.auto_free = false
	_streaks.drag = 2.0
	_streaks.streak_len = 0.08

	at(T_ARRIVE, _arrive)
	at(T_LINK, _link)
	at(T_WALK, _walk)
	at(T_STOP, _stop)
	at(T_DEPART, _depart)


func _emitter_ground(i: int) -> Vector2:
	return origin + _side * (i - (EMITTERS - 1) * 0.5) + _dir * _front


func _arrive() -> void:
	ctx.play(&"laser_thrusters", origin)
	for i in EMITTERS:
		var d := Drone.new()
		d._seed = i * 1.7
		d.position = Iso.ground_to_screen(_emitter_ground(i))
		track(d, ctx.world)
		_drones.append(d)
		var tw := d.create_tween()
		tw.tween_property(d, "alt", HOVER_ALT, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(i * 0.04)
		tw.parallel().tween_property(d, "beam", 0.25, 0.3).set_delay(0.2)
	for i in EMITTERS - 1:
		_drones[i].next = _drones[i + 1]
		_drones[i].build_links()


func _link() -> void:
	ctx.play(&"laser_ignite", origin)
	ctx.shake.add_trauma(0.3)
	ctx.shake.kick(Vector2(0, 3))
	ctx.impact.aberration(2.5, 0.3)
	ctx.impact.dim(0.3, 1.5)
	for d in _drones:
		var tw := d.create_tween()
		tw.tween_property(d, "beam", 1.0, 0.1)
		tw.tween_property(d, "link", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		FxParts.sparks(self, ctx.overhead, d.position + Vector2(0, -HOVER_ALT + 4), 10, FxParts.LASER_LIFE, Vector2(30, 120), Vector2(-20, 60))
		FxParts.sparks(self, ctx.overhead, d.position, 12, FxParts.LASER_LIFE, Vector2(40, 140), Vector2(20, 90))
	create_tween().tween_property(_lane, "alpha", 0.35, 0.3)


func _walk() -> void:
	_hum = ctx.play(&"laser_hum", origin, -2.0)
	_fire_voice = ctx.play(&"laser_fire", origin)
	_trail_glow = QuadFx.new().setup(FxParts.SH_LIGHT, Vector2(4.0, WIDTH + 1.5))
	_trail_glow.set_param("color", Color(1.0, 0.45, 0.12))
	_trail_glow.set_param("falloff", 1.2)
	_trail_glow.set_param("intensity", 0.8)
	_trail_glow.set_param("flicker", 1.0)
	_trail_glow.z_index = 5
	_lane_space.add_child(_trail_glow)
	ctx.lights.register_quad(_trail_glow, origin, 2.8, Color(1.0, 0.45, 0.12),
		func(): return origin + _dir * maxf(_front - 1.6, 0.0))
	_flames = FxParts.particles(self, ctx.overhead, Vector2.ZERO, PixelParticles.Shape.PUFF, FxParts.FIRE_LIFE)
	_flames.auto_free = false
	_flames.drag = 1.5
	# Red light spilling onto the floor along the wall, and heat shimmer riding with it.
	var lane_space := Node2D.new()
	lane_space.position = origin
	lane_space.rotation = _dir.angle()
	lane_space.z_index = 6
	track(lane_space, ctx.ground)
	_wall_light = QuadFx.new().setup(FxParts.SH_LIGHT, Vector2(2.2, WIDTH + 2.0))
	_wall_light.set_param("color", Color(1.0, 0.22, 0.1))
	_wall_light.set_param("falloff", 1.1)
	_wall_light.set_param("intensity", 1.1)
	_wall_light.set_param("flicker", 1.0)
	lane_space.add_child(_wall_light)
	ctx.lights.register_quad(_wall_light, origin, 3.4, Color(1.0, 0.22, 0.1), func(): return origin + _dir * _front)
	_wall_haze = FxParts.heat_haze(self, Iso.ground_to_screen(origin), FxParts.PX_PER_UNIT_MAJOR * WIDTH * 0.45, 1.5)


func _fx_process(delta: float) -> void:
	if t < T_WALK or t > T_STOP:
		return
	_front = clampf((t - T_WALK) / (T_STOP - T_WALK), 0.0, 1.0) * LENGTH
	_trail.set_param("front", _front)
	if is_instance_valid(_trail_glow):
		_trail_glow.position = Vector2(maxf(_front - 1.6, 0.0), 0)
	_spawn_fire(delta)
	if is_instance_valid(_wall_light):
		_wall_light.position = Vector2(_front, 0)
	if is_instance_valid(_wall_haze):
		_wall_haze.position = Iso.ground_to_screen(origin + _dir * _front) + Vector2(0, -40)
	for i in _drones.size():
		_drones[i].position = Iso.ground_to_screen(_emitter_ground(i)).round()

	var screen_back := Iso.ground_to_screen(-_dir) * 60.0 / Iso.ground_to_screen(-_dir).length()
	for n in 3:
		var along := ctx.rng.randf_range(-0.5, 0.5) * WIDTH
		var ground := origin + _side * along + _dir * _front
		var h := LINK_HEIGHTS[ctx.rng.randi() % LINK_HEIGHTS.size()] as float
		_streaks.burst(1, {
			"offset": Iso.ground_to_screen(ground), "alt": Vector2(h, h), "speed": Vector2(0, 0),
			"life": Vector2(0.15, 0.3), "size": Vector2(2, 3), "velocity": screen_back,
		})
	if ctx.rng.randf() < 0.6:
		var d := _drones[ctx.rng.randi() % _drones.size()]
		FxParts.sparks(self, ctx.overhead, d.position, 3, FxParts.LASER_LIFE, Vector2(20, 90), Vector2(20, 80))

	ctx.env.damage_lane(origin, _dir, KILL_HALF_WIDTH, _front - KILL_BAND, _front + KILL_BAND, &"laser")
	for e in ctx.field.in_lane(origin, _dir, KILL_HALF_WIDTH, _front - KILL_BAND, _front + KILL_BAND):
		if ctx.field.kill(e, &"laser", e.ground_pos - _dir):
			var sp := Iso.ground_to_screen(e.ground_pos)
			FxParts.sparks(self, ctx.overhead, sp + Vector2(0, -8), 22, FxParts.LASER_LIFE, Vector2(50, 200), Vector2(20, 160))
			var burn := FxParts.bloom(self, sp + Vector2(0, -8), 20.0, Color(1.0, 0.4, 0.15), 1.3)
			burn.tween_param("intensity", 1.3, 0.0, 0.35, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
			burn.life = 0.37
			FxParts.smoke(self, sp + Vector2(0, -6), 3.0, 18.0, 0.25, Vector2(15, 35), Vector2(2, 3), Vector2(0.6, 1.0))
			ctx.play(&"laser_sizzle", e.ground_pos)


## Flames licking up along the burning wall base, and lingering fires along the corridor edges.
func _spawn_fire(delta: float) -> void:
	for i in int(ceil(70.0 * delta)):
		var g := origin + _dir * (_front - ctx.rng.randf_range(0.05, 0.5)) + _side * ctx.rng.randf_range(-2.2, 2.2)
		_flames.burst(1, {
			"offset": Iso.ground_to_screen(g), "alt": Vector2(0, 3), "alt_speed": Vector2(30, 75),
			"speed": Vector2(0, 8), "life": Vector2(0.25, 0.55), "size": Vector2(2, 4), "size_end_mul": 0.25,
		})
	if _front >= _next_edge_fire:
		_next_edge_fire = _front + 0.7
		for sgn in [-1.0, 1.0]:
			var g: Vector2 = origin + _dir * maxf(_front - 0.4, 0.0) + _side * sgn * ctx.rng.randf_range(1.6, 2.3)
			var sp := Iso.ground_to_screen(g)
			FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.PUFF, FxParts.FIRE_LIFE, 12.0,
				ctx.rng.randf_range(1.2, 2.4), {
					"radius": 5.0, "alt_speed": Vector2(20, 45), "speed": Vector2(0, 5), "life": Vector2(0.25, 0.5),
					"size": Vector2(1.5, 3.0), "size_end_mul": 0.25,
				})
			FxParts.smoke(self, sp, 4.0, 1.5, 2.0, Vector2(14, 30), Vector2(2, 4), Vector2(1.0, 1.8))
			FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 6.0, 2.0, {
				"radius": 8.0, "alt_speed": Vector2(15, 40), "speed": Vector2(0, 10), "life": Vector2(0.5, 1.1),
				"size": Vector2(1, 1),
			})


func _stop() -> void:
	ctx.play(&"laser_powerdown", origin)
	ctx.fade_out(_hum, 0.3)
	for d in _drones:
		var tw := d.create_tween()
		tw.tween_property(d, "link", 0.0, 0.2)
		tw.parallel().tween_property(d, "beam", 0.0, 0.3)
	create_tween().tween_property(_lane, "alpha", 0.0, 0.3)
	if is_instance_valid(_wall_light):
		_wall_light.tween_param("intensity", 1.1, 0.0, 0.3)
	if is_instance_valid(_wall_haze):
		_wall_haze.tween_param("strength", 1.5, 0.0, 0.6)
	# Smoke wisps rising from the corridor.
	for k in 5:
		var g := origin + _dir * (LENGTH * (k + 0.5) / 5.0) + _side * ctx.rng.randf_range(-1.8, 1.8)
		FxParts.smoke(self, Iso.ground_to_screen(g), 20.0, 5.0, 1.4, Vector2(12, 30), Vector2(3, 5), Vector2(1.0, 1.8))
	_trail.tween_param("heat_mul", 1.0, 0.25, 1.4, 0.0, Tween.TRANS_SINE, Tween.EASE_OUT)
	_trail.tween_param("fade", 1.0, 0.0, 0.8, 1.0)
	if is_instance_valid(_trail_glow):
		_trail_glow.tween_param("intensity", 0.8, 0.0, 1.4)
	ctx.fade_out(_fire_voice, 1.6)
	ctx.impact.dim(0.0, 1.0)
	if is_instance_valid(_flames):
		_flames.auto_free = true


func _depart() -> void:
	ctx.play(&"laser_depart", origin)
	for i in _drones.size():
		var d := _drones[i]
		var tw := d.create_tween()
		tw.tween_property(d, "alt", 280.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(i * 0.05)
		tw.parallel().tween_property(d, "modulate:a", 0.0, 0.5).set_delay(0.8 + i * 0.05)
