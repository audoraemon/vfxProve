class_name EarthshatterFx
extends FxTimeline
## Earthshatter (Ruin, Tier V): the ground is torn open from one point to another. Two clicks: where it starts and
## where it ends (extra "to"; the run clamped to MIN_LENGTH..MAX_LENGTH). The ground groans and cracks for T_CRACK, then
## the fissure opens at the start and crawls toward the end at SPEED, the earth shaking the whole way, dust and rock
## thrown up at the front, a glow of the deep in the crack that cools over time. Everything in its way goes: whoever
## stands within HALF of the crack's line falls in (damage kind pit), anyone within HALF + SHOVE is thrown off their
## feet, and what stands within HALF + WALL_REACH is broken (damage kind shatter; no fire). The fissure stays for the
## rest of the mission (Fissure, group fx_lasting, as the Light of Solaris's pit does): nobody knows to avoid it, and
## whoever steps in later is gone too. Loud: seen and heard the length of its run (PowerBook.REACH), and each stretch
## of the crawl frightens those beside it (Crowd.fright()). Once in a descent.

const MIN_LENGTH := 4.0
const MAX_LENGTH := 18.0
const T_CRACK := 1.2
const SPEED := 2.0
const HALF := 1.1
const SHOVE := 1.2
const WALL_REACH := 0.6
const WALL_DAMAGE := 400.0
const FRIGHT_EVERY := 2.0
const T_SETTLE := 2.5
## Every STRETCH of crawl the ground jumps and heat is laid into the crack behind the front.
const STRETCH := 1.5
const DEEP := Color(1.0, 0.45, 0.15)
const CRACK_LIGHT := Color(1.0, 0.55, 0.2)

## Where it ends, how far it has opened (ground units along the run), and what it took.
var to := Vector2.ZERO
var length := 0.0
var reach := 0.0
var fell := 0
var broke := 0
## The crack left in the ground.
var fissure: Fissure

var _fright_at := 0.0
var _rumble_in := 0.0
var _dust_in := 0.0
var _stretch_at := 0.0
var _walls_done := {}


func _build() -> void:
	to = extra.get("to", origin + Vector2(MIN_LENGTH, 0.0))
	var run := to - origin
	if run.length() < 0.01:
		run = Vector2(1.0, 0.0)
	length = clampf(run.length(), MIN_LENGTH, MAX_LENGTH)
	to = origin + run.normalized() * length
	var crawl := length / SPEED
	duration = T_CRACK + crawl + T_SETTLE
	busy = T_CRACK + crawl
	at(T_CRACK, _open)
	at(T_CRACK + crawl, _settle)
	ctx.play(&"quake_groan", origin)
	if not DominionParts.staged(self):
		return
	# The ground groans: the run is marked faintly, and the start cracks and glows.
	var mark := FxParts.rings(self, origin, HALF, CRACK_LIGHT, 2, 8.0)
	mark.set_param("scan", 0.0)
	mark.tween_param("reveal", 0.0, 1.0, T_CRACK * 0.8, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	mark.life = T_CRACK + 0.05
	var light := FxParts.ground_light(self, origin, 2.0, CRACK_LIGHT, 0.0)
	light.tween_param("intensity", 0.0, 1.0, T_CRACK, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	light.life = T_CRACK + 0.05
	var sp := Iso.ground_to_screen(origin)
	var dust := FxParts.emitter(self, ctx.overhead_back, sp, PixelParticles.Shape.PUFF, FxParts.DUST_LIFE, 30.0, T_CRACK,
		{"radius": 14.0, "speed": Vector2(4, 14), "alt": Vector2(0, 4), "alt_speed": Vector2(8, 26), "life": Vector2(0.5, 1.0), "size": Vector2(2, 4), "size_end_mul": 1.6})
	dust.drag = 1.2


## The ground breaks at the start.
func _open() -> void:
	fissure = Fissure.new().setup(ctx.field, origin, to, HALF, ctx.rng.randi())
	ctx.ground.add_child(fissure)
	fissure.hide_rubble(ctx.env)
	ctx.play(&"quake_open", origin, -1.0)
	if not DominionParts.staged(self):
		return
	ctx.flash.call(Color(1.0, 0.8, 0.6, 0.2), 0.3)
	ctx.impact.hitstop(0.06)
	ctx.impact.aberration(2.0, 0.3)
	ctx.shake.add_trauma(0.6)
	ctx.shake.kick(Vector2(0, 5))
	var sp := Iso.ground_to_screen(origin)
	FxParts.debris(self, sp, 22, 10.0, Vector2(40, 200), FxParts.ROCK, Vector2(2, 5), true)
	var ring := FxParts.shockwave(self, origin, HALF + 1.5, FxParts.FIRE)
	ring.set_param("thickness", 0.14)
	ring.tween_param("progress", 0.05, 1.0, 0.4, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.2, 0.2)
	ring.life = 0.42


## The crawl is done: the shaking eases, the crack stays.
func _settle() -> void:
	reach = length
	if fissure != null and is_instance_valid(fissure):
		fissure.reach = length
		fissure.armed = true
	ctx.play(&"quake_settle", to, 2.0)
	if DominionParts.staged(self):
		ctx.shake.add_trauma(0.4)
		FxParts.debris(self, Iso.ground_to_screen(to), 16, 8.0, Vector2(30, 160), FxParts.ROCK, Vector2(2, 4), true)


## Where the front is now.
func front() -> Vector2:
	return origin + (to - origin).normalized() * reach


func _fx_process(delta: float) -> void:
	if t < T_CRACK or reach >= length:
		return
	var was := reach
	reach = minf(reach + SPEED * delta, length)
	if fissure != null and is_instance_valid(fissure):
		fissure.reach = reach
	var dir := (to - origin).normalized()
	# Everything the front has passed since the last frame: the fall, the shove, the walls.
	var mid := origin + dir * ((was + reach) * 0.5)
	var step := maxf(reach - was, 0.05)
	for e in ctx.field.in_radius(mid, HALF + SHOVE + step):
		var p := e as Person
		if p != null and p.inside:
			continue
		var along := (e.ground_pos - origin).dot(dir)
		if along < was - HALF or along > reach + HALF:
			continue
		var off := absf((e.ground_pos - origin).cross(dir))
		if off <= HALF:
			if ctx.field.kill(e, &"pit", e.ground_pos):
				fell += 1
				if fissure != null and is_instance_valid(fissure):
					fissure.crumble(e.ground_pos)
		elif off <= HALF + SHOVE:
			var lateral := (e.ground_pos - origin) - dir * along  # away from the crack's line
			e.knock((lateral.normalized() if lateral.length() > 0.01 else Vector2(-dir.y, dir.x)) * 2.0)
	for s in ctx.env.near(front(), HALF + WALL_REACH + 1.0):
		if not is_instance_valid(s) or s.destroyed or _walls_done.has(s) or s.role == &"thorns":
			continue
		var c := s.center()
		var along := (c - origin).dot(dir)
		if along < -HALF or along > reach + HALF:
			continue
		if absf((c - origin).cross(dir)) <= HALF + WALL_REACH + s.footprint.size.length() * 0.5:
			_walls_done[s] = true
			s.damage(WALL_DAMAGE, c, &"shatter")
			broke += 1
	# Barrels, carts, lamps and trees on the line go into it.
	for d in ctx.env.decor():
		if not is_instance_valid(d) or not d.visible:
			continue
		var along := (d.at - origin).dot(dir)
		if along < was - HALF or along > reach + HALF:
			continue
		if absf((d.at - origin).cross(dir)) <= HALF + 0.5:
			d.visible = false
	# The town is told, stretch by stretch.
	if ctx.crowd != null and reach - _fright_at >= FRIGHT_EVERY:
		_fright_at = reach
		ctx.crowd.fright(front(), HALF + 1.0, 0.8, 6.0, 7.0, 12.0, &"shatter")
	if not DominionParts.staged(self):
		return
	# The earth shakes the whole way; the front throws dust and rock; the rumble goes on.
	ctx.shake.add_trauma(minf(delta * 1.6, 0.12))
	_rumble_in -= delta
	if _rumble_in <= 0.0:
		_rumble_in = 1.4
		ctx.play(&"quake_run", front(), 2.0)
	_dust_in -= delta
	if _dust_in <= 0.0:
		_dust_in = 0.1
		var sp := Iso.ground_to_screen(front())
		FxParts.debris(self, sp, 8, 8.0, Vector2(40, 260), FxParts.ROCK, Vector2(1.5, 4.5), true)
		FxParts.debris(self, sp, 4, 6.0, Vector2(60, 220), FxParts.HOT_ROCK, Vector2(1.5, 3.0), true)
		FxParts.sparks(self, ctx.overhead, sp, 8, FxParts.EMBER_LIFE, Vector2(40, 180), Vector2(60, 220))
		var puff := FxParts.particles(self, ctx.overhead_back, sp, PixelParticles.Shape.PUFF, FxParts.DUST_LIFE)
		puff.drag = 1.0
		puff.burst(9, {"radius": 16.0, "speed": Vector2(10, 40), "dir": PixelParticles.Dir.OUTWARD, "alt": Vector2(0, 6), "alt_speed": Vector2(14, 44),
			"life": Vector2(0.7, 1.4), "size": Vector2(2, 5), "size_end_mul": 1.8})
		var light := FxParts.ground_light(self, front(), 2.2, CRACK_LIGHT, 1.1)
		light.tween_param("intensity", 1.1, 0.0, 0.5)
		light.life = 0.52
	# Every stretch: the ground round the front jumps, and the heat of the deep is laid into the crack behind it.
	if reach - _stretch_at >= STRETCH:
		_stretch_at = reach
		var here := front()
		var ring := FxParts.shockwave(self, here, HALF + 1.6, FxParts.FIRE)
		ring.set_param("thickness", 0.1)
		ring.tween_param("progress", 0.05, 1.0, 0.35, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
		ring.tween_param("fade", 0.8, 0.0, 0.2, 0.15)
		ring.life = 0.37
		ctx.shake.kick(Vector2(ctx.rng.randf_range(-2.0, 2.0), 2.0))
		FxParts.debris(self, Iso.ground_to_screen(here), 14, 12.0, Vector2(60, 300), FxParts.ROCK, Vector2(2, 5), true)
		if fissure != null and is_instance_valid(fissure):
			fissure.add_heat(here - dir * STRETCH * 0.5)


## The crack in the ground, left for good: a jagged dark gash from `a` toward `b` as far as `reach`, lit from the deep
## while it is new, with side cracks off it. Drawn in the ground layer in ground units. Once armed, whoever stands over
## it falls (swallow(), every CHECK_EVERY); the rubble of what stood over it is hidden.
class Fissure extends Node2D:
	const GROUP := &"fx_lasting"
	const CHECK_EVERY := 0.1
	const COOL := 10.0
	const KEEP_RUBBLE := [&"gate", &"bridge"]

	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var half := 1.0
	var reach := 0.0
	var armed := false
	var fallen := 0
	var _field: EnemyField
	var _rng := RandomNumberGenerator.new()
	var _age := 0.0
	var _check_in := 0.0
	## The crack's spine: [along, offset, half-width] every SEG along the run; and the side cracks: [along, side, length].
	var _spine: Array = []
	var _sides: Array = []
	## Rubble lying on the lips: [along, side offset, size].
	var _rubble: Array = []
	## The heat along it: [emitter, stop_at].
	var _heat: Array = []
	const SEG := 0.45

	func setup(field: EnemyField, from: Vector2, to_point: Vector2, half_width: float, seed_value: int) -> Fissure:
		_field = field
		a = from
		b = to_point
		half = half_width
		_rng.seed = seed_value
		add_to_group(GROUP)
		z_index = 4
		var length := a.distance_to(b)
		var along := 0.0
		while along <= length + 0.01:
			var k := clampf(along / length, 0.0, 1.0)
			var taper := minf(1.0, minf(along, length - along) / 1.5 + 0.25)
			_spine.append([along, _rng.randf_range(-0.35, 0.35) * (1.0 - absf(k - 0.5) * 0.6), half * taper * _rng.randf_range(0.7, 1.0)])
			along += SEG
		along = 1.0
		while along < length - 0.5:
			_sides.append([along, 1.0 if _rng.randf() < 0.5 else -1.0, _rng.randf_range(0.8, 2.6)])
			along += _rng.randf_range(0.8, 1.8)
		for i in int(length * 6.0):
			var side := 1.0 if _rng.randf() < 0.5 else -1.0
			_rubble.append([_rng.randf_range(0.0, length), side * (half + _rng.randf_range(0.05, 1.1)), _rng.randf_range(0.06, 0.16)])
		return self

	func _process(delta: float) -> void:
		advance(delta)
		queue_redraw()

	func advance(delta: float) -> void:
		_age += delta
		for h in _heat:
			if is_instance_valid(h[0]) and _age >= float(h[1]):
				(h[0] as PixelParticles).emitting = false
		_check_in -= delta
		if armed and _check_in <= 0.0:
			_check_in = CHECK_EVERY
			swallow()

	## Whether `g` is over the crack (as far as it has opened).
	func over(g: Vector2) -> bool:
		var dir := (b - a).normalized()
		var along := (g - a).dot(dir)
		return along >= 0.0 and along <= reach and absf((g - a).cross(dir)) <= half * 0.9

	## Everyone standing over the crack falls; how many did.
	func swallow() -> int:
		if not is_instance_valid(_field):
			return 0
		var took := 0
		var dir := (b - a).normalized()
		var mid := a + dir * reach * 0.5
		for e in _field.in_radius(mid, reach * 0.5 + half):
			var p := e as Person
			if p != null and p.inside:
				continue
			if not over(e.ground_pos):
				continue
			var at := e.ground_pos
			if _field.kill(e, &"pit", at):
				took += 1
				crumble(at)
		fallen += took
		return took

	## The rubble of what stood over the crack is hidden, now and later.
	func hide_rubble(env: EnvironmentField) -> void:
		for s in env.structures():
			if is_instance_valid(s) and s.destroyed:
				_on_structure_destroyed(s, &"")
		if not env.structure_destroyed.is_connected(_on_structure_destroyed):
			env.structure_destroyed.connect(_on_structure_destroyed)

	func _on_structure_destroyed(s: Structure, _kind: StringName) -> void:
		if not is_instance_valid(s) or KEEP_RUBBLE.has(s.role):
			return
		var dir := (b - a).normalized()
		var c := s.center()
		var along := (c - a).dot(dir)
		# Anything fallen on the lip or over the crack is gone into it.
		if along >= -half and along <= a.distance_to(b) + half and absf((c - a).cross(dir)) <= half + 1.0:
			s.visible = false

	## The heat of the deep at `at`, for as long as the crack is new: the air shimmers over it, embers rise out of it,
	## and the ground about it is lit from below.
	func add_heat(at: Vector2) -> void:
		var sp := Iso.ground_to_screen(at)
		var flat := Iso.BASIS.affine_inverse()
		var haze := QuadFx.new().setup(FxParts.SH_HAZE, Vector2(70.0, 44.0))
		haze.transform = flat * Transform2D(0.0, sp + Vector2(0, -8))
		haze.set_param("strength", 1.4)
		haze.tween_param("strength", 1.4, 0.0, COOL, 1.0)
		haze.life = COOL + 1.1
		add_child(haze)
		var embers := PixelParticles.new()
		embers.rng.seed = _rng.randi()
		embers.shape = PixelParticles.Shape.SQUARE
		embers.ramp = PackedColorArray(FxParts.EMBER_LIFE)
		embers.transform = flat * Transform2D(0.0, sp)
		embers.gravity = -40.0
		embers.drag = 0.6
		embers.rate = 14.0
		embers.spec = {"radius": 14.0, "speed": Vector2(2, 10), "alt": Vector2(0, 4), "alt_speed": Vector2(20, 60),
			"life": Vector2(0.8, 1.6), "size": Vector2(1, 2)}
		embers.emitting = true
		add_child(embers)
		_heat.append([embers, _age + COOL * 0.7])
		var glow := QuadFx.new().setup(FxParts.SH_LIGHT, Vector2(1.0, 1.0) * (half + 1.2) * 2.0)
		glow.position = at
		glow.set_param("color", Color(1.0, 0.5, 0.2))
		glow.set_param("intensity", 0.9)
		glow.tween_param("intensity", 0.9, 0.0, COOL, 0.5)
		glow.life = COOL + 0.6
		add_child(glow)

	## The lip gives way under someone: dust where they stood.
	func crumble(at: Vector2) -> void:
		var parent := get_parent()
		if parent == null:
			return
		var dust := PixelParticles.new()
		dust.rng.seed = _rng.randi()
		dust.shape = PixelParticles.Shape.PUFF
		dust.ramp = PackedColorArray(FxParts.DUST_LIFE)
		dust.position = Iso.ground_to_screen(at)
		dust.drag = 1.6
		dust.gravity = -6.0
		# Screen-space node in a ground-space layer: undo the layer's basis.
		dust.transform = Iso.BASIS.affine_inverse() * Transform2D(0.0, Iso.ground_to_screen(at))
		parent.add_child(dust)
		dust.burst(6, {"radius": 7.0, "speed": Vector2(8, 24), "dir": PixelParticles.Dir.OUTWARD, "alt": Vector2(0, 3),
			"alt_speed": Vector2(3, 12), "life": Vector2(0.3, 0.6), "size": Vector2(1, 3), "size_end_mul": 1.5})

	func _draw() -> void:
		if reach <= 0.05 or _spine.size() < 2:
			return
		var dir := (b - a).normalized()
		var side := Vector2(-dir.y, dir.x)
		var heat := clampf(1.0 - (_age - 1.0) / COOL, 0.0, 1.0)
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		var core := PackedVector2Array()
		for s in _spine:
			var along: float = s[0]
			if along > reach:
				break
			var c := a + dir * along + side * float(s[1])
			var w: float = s[2]
			left.append(c + side * w)
			right.append(c - side * w)
			core.append(c)
		# The front, as far as it has opened, tapers to a point.
		var tip := a + dir * reach
		left.append(tip)
		var poly := PackedVector2Array(left)
		for i in range(right.size() - 1, -1, -1):
			poly.append(right[i])
		if poly.size() >= 3:
			draw_colored_polygon(poly, Color(0.1, 0.08, 0.1, 0.97))
		# The depth: the middle of the gash darker still, with a lit sill along the near wall.
		var inner := PackedVector2Array()
		for i in core.size():
			inner.append(core[i] + (left[i] - core[i]) * 0.55)
		for i in range(core.size() - 1, -1, -1):
			inner.append(core[i] + (right[i] - core[i]) * 0.75)
		if inner.size() >= 3:
			draw_colored_polygon(inner, Color(0.03, 0.02, 0.04, 1.0))
		if left.size() >= 3:
			var sill := PackedVector2Array()
			for i in core.size():
				sill.append(left[i])
			for i in range(core.size() - 1, -1, -1):
				sill.append(core[i] + (left[i] - core[i]) * 0.7)
			draw_colored_polygon(sill, Color(0.32, 0.27, 0.24, 1.0))
		# The deep glows while it is new, pulsing, brightest where the crack is widest.
		if heat > 0.0 and core.size() >= 2:
			var pulse := 0.8 + 0.2 * sin(_age * 6.0)
			draw_polyline(core, Color(0.6, 0.12, 0.02, 0.7 * heat), 0.6)
			draw_polyline(core, Color(DEEP, 0.75 * heat * pulse), 0.36)
			draw_polyline(core, Color(1.0, 0.85, 0.5, 0.75 * heat * pulse), 0.14)
			for i in range(0, core.size(), 2):
				var w: float = _spine[i][2]
				draw_circle(core[i], w * 0.35 * pulse, Color(1.0, 0.7, 0.3, 0.45 * heat))
		# The lips, lit on one side, dark on the other.
		if left.size() >= 2:
			draw_polyline(left, Color(0.62, 0.56, 0.5, 1.0), 0.1)
		if right.size() >= 2:
			draw_polyline(right, Color(0.14, 0.11, 0.1, 1.0), 0.1)
		# Rubble on the lips where the crack has reached.
		for r in _rubble:
			var along: float = r[0]
			if along > reach:
				continue
			var at := a + dir * along + side * float(r[1])
			var sz: float = r[2]
			draw_rect(Rect2(at - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), Color(0.33, 0.3, 0.3, 1.0))
			draw_rect(Rect2(at - Vector2(sz, sz) * 0.5, Vector2(sz, sz * 0.4)), Color(0.5, 0.46, 0.42, 1.0))
		# Side cracks, thin, where the crack has reached.
		for sc in _sides:
			var along: float = sc[0]
			if along > reach:
				break
			var from := a + dir * along
			var out := side * float(sc[1])
			var p1 := from + out * float(sc[2]) * 0.5 + dir * 0.3
			var p2 := p1 + out * float(sc[2]) * 0.5 - dir * 0.2
			draw_polyline(PackedVector2Array([from, p1, p2]), Color(0.05, 0.04, 0.06, 0.9), 0.1)
			if heat > 0.0:
				draw_line(from, p1, Color(DEEP, 0.35 * heat), 0.05)
