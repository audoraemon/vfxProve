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
const HOVER_ALT := 66.0
const LINK_HEIGHTS := [12.0, 30.0, 48.0]

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


## Burned corridor behind the wall, drawn as coarse cells in lane space.
class ScorchTrail:
	extends Node2D

	const CELL := 0.2
	const CHAR := [Color(0.05, 0.035, 0.03, 0.85), Color(0.08, 0.05, 0.04, 0.8), Color(0.03, 0.02, 0.02, 0.9)]
	const MOLTEN := [Color("fff0c0"), Color("ffb040"), Color("ff5a1a"), Color("a0200e")]

	var front := 0.0
	var fade := 1.0
	var seed := 0
	var _time := 0.0
	var _noise := FastNoiseLite.new()

	func _ready() -> void:
		_noise.seed = seed
		_noise.frequency = 0.9

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _hash(ix: int, iy: int) -> int:
		return absi((ix * 73856093) ^ (iy * 19349663) ^ seed) % 1009

	func _draw() -> void:
		if front <= 0.0 or fade <= 0.0:
			return
		var hw := WIDTH * 0.5
		var nx := int(front / CELL)
		var ny := int(WIDTH / CELL)
		for ix in nx:
			var x := ix * CELL
			var behind := front - x
			for iy in ny:
				var h := _hash(ix, iy)
				var y := -hw + iy * CELL
				# Clustered glow: noise field, strongest just behind the wall and along ragged edges.
				var n := _noise.get_noise_2d(x, y) * 0.5 + 0.5
				var edge_d := minf(float(iy), float(ny - 1 - iy))
				var ragged := edge_d < 1.0 + float(h % 3) * 0.5
				if edge_d < 0.5 and h % 4 == 0:
					continue
				var col: Color = CHAR[h % 3]
				col.a *= fade
				draw_rect(Rect2(x, y, CELL, CELL), col)
				var heat := clampf(1.0 - behind / 1.8, 0.0, 1.0) * (0.55 + 0.6 * n)
				if ragged:
					heat = maxf(heat, clampf(1.0 - behind / 7.5, 0.0, 1.0) * (0.3 + 0.7 * n))
				elif n > 0.72:
					heat = maxf(heat, clampf(1.0 - behind / 5.0, 0.0, 1.0) * n * 0.8)
				var threshold := 0.35 + float(h % 20) / 100.0
				if heat > threshold:
					var idx := clampi(int((1.0 - heat) * 4.0), 0, 3)
					var m: Color = MOLTEN[idx]
					m.a = fade
					draw_rect(Rect2(x, y, CELL, CELL), m)


## Hovering emitter drone. Positioned on the ground point (y-sorted); draws at altitude.
class Drone:
	extends Node2D

	const COL_BODY := Color("3b4150")
	const COL_TOP := Color("7a8496")
	const COL_DARK := Color("222630")
	const COL_EYE := Color("ff4a3a")
	const COL_THRUST := Color("5ab8ff")

	var alt := 190.0
	var beam := 0.0
	var link := 0.0
	var next: Drone
	var _time := 0.0
	var _seed := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var bob := roundf(sin(_time * 5.0 + _seed) * 1.0)
		var top := -alt + bob
		var flick := fmod(_time * 30.0 + _seed * 7.0, 3.0) < 1.0
		# Shadow.
		var sh := clampf(1.0 - alt / 260.0, 0.1, 1.0)
		draw_rect(Rect2(-4, -1, 9, 2), Color(0, 0, 0, 0.35 * sh * modulate.a))
		# Links to the neighbor drone (the wall), plus burning ground line.
		if link > 0.0 and next != null:
			var d := next.position - position
			# Hairlines only: thick draw_line quads collapse under 2D vertex snapping.
			var ground_to := Vector2.ZERO.lerp(d, link).round()
			# Faint energy curtain between emitters.
			var top_h: float = LINK_HEIGHTS[-1] + 4.0
			var curtain := Color(1.0, 0.15, 0.1, (0.1 if flick else 0.16) * link)
			draw_colored_polygon(PackedVector2Array([
				Vector2.ZERO, ground_to, ground_to + Vector2(0, -top_h), Vector2(0, -top_h)]), curtain)
			draw_line(Vector2.ZERO, ground_to, COL_MID, -1.0)
			draw_line(Vector2(0, -1), ground_to + Vector2(0, -1), COL_OUTER, -1.0)
			for h in LINK_HEIGHTS:
				var a := Vector2(0, -h)
				var b := a.lerp(d + Vector2(0, -h), link).round()
				if not flick:
					draw_line(a + Vector2(0, -2), b + Vector2(0, -2), COL_OUTER, -1.0)
					draw_line(a + Vector2(0, 2), b + Vector2(0, 2), COL_OUTER, -1.0)
				draw_line(a + Vector2(0, -1), b + Vector2(0, -1), COL_MID, -1.0)
				draw_line(a + Vector2(0, 1), b + Vector2(0, 1), COL_MID, -1.0)
				draw_line(a, b, COL_CORE if link >= 1.0 else COL_MID, -1.0)
				draw_rect(Rect2(a + Vector2(-1, -1), Vector2(3, 3)), COL_MID)
				draw_rect(Rect2(a, Vector2.ONE), Color.WHITE)
		# Vertical beam from emitter to ground.
		if beam > 0.0:
			var length := alt - 3.0
			if beam > 0.6 and not flick:
				draw_rect(Rect2(-2, top + 3, 5, length), COL_OUTER)
			if beam > 0.3:
				draw_rect(Rect2(-1, top + 3, 3, length), COL_MID)
			draw_rect(Rect2(0, top + 3, 1, length), COL_CORE if beam > 0.6 else COL_MID)
			draw_rect(Rect2(-3, -1, 7, 2), COL_MID)
			draw_rect(Rect2(-1, -1, 3, 1), COL_CORE)
		# Body.
		draw_rect(Rect2(-9, top - 3, 2, 2), COL_DARK)
		draw_rect(Rect2(8, top - 3, 2, 2), COL_DARK)
		draw_rect(Rect2(-7, top - 2, 2, 1), COL_DARK)
		draw_rect(Rect2(6, top - 2, 2, 1), COL_DARK)
		draw_rect(Rect2(-5, top - 3, 11, 5), COL_BODY)
		draw_rect(Rect2(-5, top - 3, 11, 1), COL_TOP)
		draw_rect(Rect2(-1, top - 1, 3, 1), COL_EYE)
		draw_rect(Rect2(-1, top + 2, 3, 1), COL_MID if beam > 0.0 else COL_DARK)
		var thrust := COL_THRUST if flick else COL_THRUST.lightened(0.4)
		draw_rect(Rect2(-9, top - 1, 2, 1), thrust)
		draw_rect(Rect2(8, top - 1, 2, 1), thrust)
		if flick:
			draw_rect(Rect2(-9, top, 1, 1), Color(COL_THRUST, 0.6))
			draw_rect(Rect2(9, top, 1, 1), Color(COL_THRUST, 0.6))


var _dir := Vector2(1, 0)
var _side := Vector2(0, 1)
var _lane: LaneMarker
var _trail: ScorchTrail
var _drones: Array[Drone] = []
var _front := 0.0
var _streaks: PixelParticles
var _hum: Node


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

	_trail = ScorchTrail.new()
	_trail.position = origin
	_trail.rotation = _dir.angle()
	_trail.z_index = 1
	_trail.seed = ctx.rng.randi() % 100000
	track(_trail, ctx.ground)

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


func _link() -> void:
	ctx.play(&"laser_ignite", origin)
	ctx.shake.add_trauma(0.2)
	for d in _drones:
		var tw := d.create_tween()
		tw.tween_property(d, "beam", 1.0, 0.1)
		tw.tween_property(d, "link", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		FxParts.sparks(self, ctx.overhead, d.position + Vector2(0, -HOVER_ALT + 4), 10, FxParts.LASER_LIFE, Vector2(30, 120), Vector2(-20, 60))
		FxParts.sparks(self, ctx.overhead, d.position, 12, FxParts.LASER_LIFE, Vector2(40, 140), Vector2(20, 90))
	create_tween().tween_property(_lane, "alpha", 0.35, 0.3)


func _walk() -> void:
	_hum = ctx.play(&"laser_hum", origin, -2.0)


func _fx_process(delta: float) -> void:
	if t < T_WALK or t > T_STOP:
		return
	_front = clampf((t - T_WALK) / (T_STOP - T_WALK), 0.0, 1.0) * LENGTH
	_trail.front = _front
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

	for e in ctx.field.in_lane(origin, _dir, KILL_HALF_WIDTH, _front - KILL_BAND, _front + KILL_BAND):
		if ctx.field.kill(e, &"laser"):
			var sp := Iso.ground_to_screen(e.ground_pos)
			FxParts.sparks(self, ctx.overhead, sp + Vector2(0, -8), 16, FxParts.LASER_LIFE, Vector2(40, 170), Vector2(20, 140))
			FxParts.smoke(self, sp + Vector2(0, -6), 3.0, 18.0, 0.25, Vector2(15, 35), Vector2(2, 3), Vector2(0.6, 1.0))
			ctx.play(&"laser_sizzle", e.ground_pos)


func _stop() -> void:
	ctx.play(&"laser_powerdown", origin)
	ctx.fade_out(_hum, 0.3)
	for d in _drones:
		var tw := d.create_tween()
		tw.tween_property(d, "link", 0.0, 0.2)
		tw.parallel().tween_property(d, "beam", 0.0, 0.3)
	create_tween().tween_property(_lane, "alpha", 0.0, 0.3)
	# Smoke wisps rising from the corridor.
	for k in 5:
		var g := origin + _dir * (LENGTH * (k + 0.5) / 5.0) + _side * ctx.rng.randf_range(-1.8, 1.8)
		FxParts.smoke(self, Iso.ground_to_screen(g), 20.0, 9.0, 1.4, Vector2(12, 30), Vector2(3, 5), Vector2(1.0, 1.8))
	var tw := create_tween()
	tw.tween_interval(0.7)
	tw.tween_property(_trail, "fade", 0.0, 1.1)


func _depart() -> void:
	ctx.play(&"laser_depart", origin)
	for i in _drones.size():
		var d := _drones[i]
		var tw := d.create_tween()
		tw.tween_property(d, "alt", 280.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(i * 0.05)
		tw.parallel().tween_property(d, "modulate:a", 0.0, 0.5).set_delay(0.8 + i * 0.05)
