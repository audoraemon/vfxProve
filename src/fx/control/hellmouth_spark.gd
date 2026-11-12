class_name HellmouthSparkFx
extends FxTimeline
## Hellmouth Spark (Passage, Tier I): a small door to the furnace opens on the ground. Aimed by a click: the paving
## at the point rumbles and tears over T_OPEN, then the door is open for OPEN seconds -- a jagged mouth of white-orange
## light with the furnace's roar behind it. Every BURN_EVERY while it is open, whoever stands within RADIUS of the
## mouth -- any role; those inside a building are not reached -- catches and dies (damage kind fire), every building
## whose wall comes within RADIUS takes HEAT of fire (a wooden one is alight from the first tick, FireManager's; a
## stone one only cracks), and the decor within it chars. The mouth is a danger the town keeps clear of (a fire
## threat, RADIUS + 0.5, as long as it is open). Where it opens follows the open passages: cast on a Mirrorfold's way
## in, the door opens at its way out (EnemyField.through()). At T_OPEN + OPEN the door shuts -- a last burst of sparks,
## smoke -- and a scorch stays on the paving. Loud: the opening is seen and heard (PowerBook.REACH), from T_OPEN.

const T_OPEN := 0.6
const OPEN := 6.0
const RADIUS := 1.5
const BURN_EVERY := 0.5
const HEAT := 6.0
## The shut and the scorch cooling, after the door closes.
const AFTER := 1.5
const T_SHUT := 0.4
const HOT := Color(1.0, 0.85, 0.55)
const FLAME := Color(1.0, 0.55, 0.18)
const DEEP_RED := Color(0.55, 0.06, 0.02)
const WHITE_HOT := Color(1.0, 0.96, 0.85)

## Where the door opened (the cast point, carried through an open passage), how many it burned, how many
## buildings it set alight.
var mouth := Vector2.ZERO
var burned := 0
var lit := 0

var _open := false
var _crack: Crack
var _column: QuadFx
var _core: QuadFx
var _light: QuadFx
var _rays: QuadFx
var _haze: QuadFx
var _breath: Node
var _breath2: Node


## Whether the door is open now: the ticks only burn while it is.
func open() -> bool:
	return _open


func _build() -> void:
	mouth = ctx.field.through(origin)
	duration = T_OPEN + OPEN + AFTER
	busy = T_OPEN
	at(T_OPEN, _open_door)
	var ticks := int(floor(OPEN / BURN_EVERY))
	for i in ticks:
		at(T_OPEN + BURN_EVERY * float(i), _burn)
	at(T_OPEN + 3.0, _roar_again)
	at(T_OPEN + OPEN, _shut)
	ctx.play(&"hm_tear", mouth, -2.0)
	if not DominionParts.staged(self):
		return
	# The paving rumbles and the crack tears open over T_OPEN: a dull red seam first, the ground under it warming.
	_crack = Crack.new()
	_crack.rng.seed = ctx.rng.randi()
	_crack.radius = RADIUS * 0.8
	_crack.position = mouth
	_crack.z_index = 4
	_crack.build()
	track(_crack, ctx.ground)
	var tear := create_tween()
	tear.tween_property(_crack, "open", 1.0, T_OPEN).from(0.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_light = FxParts.ground_light(self, mouth, RADIUS * 2.0, FLAME, 0.0)
	_light.tween_param("intensity", 0.0, 0.8, T_OPEN, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	var mark := FxParts.rings(self, mouth, RADIUS, Color("ff7a3a"), 2, 20.0)
	mark.set_param("scan", 0.0)
	mark.tween_param("reveal", 0.0, 1.0, T_OPEN * 0.8, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	mark.tween_param("fade", 1.0, 0.0, 0.3, T_OPEN)
	mark.life = T_OPEN + 0.35
	ctx.shake.add_trauma(0.12)
	var sp := Iso.ground_to_screen(mouth)
	var dust := FxParts.particles(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, FxParts.DUST_LIFE)
	dust.gravity = 60.0
	dust.burst(14, {"radius": FxParts.particle_radius(RADIUS * 0.8), "speed": Vector2(5, 20), "alt": Vector2(0, 4),
		"alt_speed": Vector2(20, 60), "life": Vector2(0.3, T_OPEN), "size": Vector2(1, 2)})


## The door opens: the town is warned off it, and the furnace light pours up out of the ground.
func _open_door() -> void:
	_open = true
	if ctx.crowd != null:
		ctx.crowd.threats.register(mouth, RADIUS + 0.5, 0.7, OPEN, 5.0, 8.0, &"fire")
	ctx.play(&"hm_open", mouth, 0.0)
	_breath = ctx.play(&"hm_roar", mouth, -6.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(mouth)
	ctx.flash.call(Color(1.0, 0.6, 0.25, 0.2), 0.2)
	ctx.shake.add_trauma(0.5)
	ctx.impact.hitstop(0.05)
	ctx.impact.aberration(2.0, 0.25)
	# Light pouring up: a wide column and a white-hot core, flickering (see _fx_process), rays off the ground, the
	# ground lit, the air over it shimmering.
	_column = FxParts.quad(self, FxParts.SH_BEAM_ADD, Vector2(84.0, 380.0), ctx.overhead, Vector2(0.5, 1.0))
	_column.position = sp
	_column.set_param("color", FLAME)
	_column.set_param("intensity", 1.5)
	_core = FxParts.quad(self, FxParts.SH_BEAM_ADD, Vector2(26.0, 340.0), ctx.overhead, Vector2(0.5, 1.0))
	_core.position = sp
	_core.set_param("color", WHITE_HOT)
	_core.set_param("intensity", 1.6)
	_rays = FxParts.ground_rays(self, mouth, RADIUS * 2.4, HOT, 48.0)
	_rays.set_param("reach", 0.9)
	_rays.set_param("intensity", 0.5)
	_haze = FxParts.heat_haze(self, sp, FxParts.particle_radius(RADIUS * 1.6), 2.4)
	var halo := FxParts.bloom(self, sp + Vector2(0, -16), 48.0, FLAME, 1.0, 0.7)
	halo.tween_param("intensity", 1.0, 0.0, 0.5, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	halo.life = 0.52
	var ring := FxParts.shockwave(self, mouth, RADIUS + 1.2, FxParts.FIRE)
	ring.set_param("thickness", 0.14)
	ring.tween_param("progress", 0.05, 1.0, 0.4, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.2, 0.2)
	ring.life = 0.42
	var air := FxParts.refract_ring(self, mouth, RADIUS + 1.8, HOT)
	air.tween_param("progress", 0.05, 1.0, 0.5, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	air.life = 0.52
	# Embers spiralling out and up for as long as it is open, and a few flames licking out of the mouth.
	var embers := FxParts.emitter(self, ctx.overhead, sp + Vector2(0, -4), PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 60.0, OPEN,
		{"radius": FxParts.particle_radius(RADIUS * 0.7), "speed": Vector2(8, 40), "dir": PixelParticles.Dir.OUTWARD,
		"alt": Vector2(0, 10), "alt_speed": Vector2(40, 120), "life": Vector2(0.9, 1.8), "size": Vector2(1, 2)})
	embers.gravity = -45.0
	embers.drag = 0.6
	var flames := FxParts.emitter(self, ctx.overhead, sp + Vector2(0, -2), PixelParticles.Shape.PUFF, FxParts.FIRE_LIFE, 40.0, OPEN,
		{"radius": FxParts.particle_radius(RADIUS * 0.6), "speed": Vector2(2, 10), "alt": Vector2(0, 6),
		"alt_speed": Vector2(30, 90), "life": Vector2(0.3, 0.7), "size": Vector2(2, 5), "size_end_mul": 0.3})
	flames.gravity = -20.0
	FxParts.sparks(self, ctx.overhead, sp, 30, FxParts.FIRE_LIFE, Vector2(60, 220), Vector2(120, 320))
	FxParts.debris(self, sp, 10, FxParts.particle_radius(RADIUS * 0.7), Vector2(40, 160), FxParts.HOT_ROCK, Vector2(1.5, 3.0), true)


## One tick of the furnace: whoever stands at the mouth catches, the walls about it take heat, the decor chars.
func _burn() -> void:
	if not _open:
		return
	for e in ctx.field.in_radius(mouth, RADIUS):
		var person := e as Person
		if person != null and person.inside:
			continue
		if ctx.field.kill(e, &"fire", mouth):
			burned += 1
	var fires: FireManager = ctx.crowd.fires if ctx.crowd != null else null
	for s in ctx.env.structures():
		if s.destroyed or s.distance_to(mouth) > RADIUS:
			continue
		var was := fires != null and fires.is_burning(s)
		s.damage(HEAT, mouth, &"fire")
		if fires != null and not was and fires.is_burning(s):
			lit += 1
	for d in ctx.env.decor():
		if is_instance_valid(d) and d.at.distance_to(mouth) <= RADIUS:
			d.hit(HEAT, &"fire")
	var crackle := ctx.play(&"hm_pulse", mouth, 0.0)
	ctx.fade_out(crackle, BURN_EVERY * 0.9)
	if not DominionParts.staged(self):
		return
	ctx.shake.add_trauma(0.07)
	var sp := Iso.ground_to_screen(mouth)
	FxParts.sparks(self, ctx.overhead, sp, 8, FxParts.FIRE_LIFE, Vector2(40, 140), Vector2(80, 220))
	if is_instance_valid(_crack):
		_crack.kick = 1.0


## The roar is a loop that outlasts the door: the first voice gives way to a second halfway through.
func _roar_again() -> void:
	_breath2 = ctx.play(&"hm_roar", mouth, -6.0)
	if _breath != null:
		ctx.fade_out(_breath, 0.6)


## The door shuts: the crack closes, a last burst of sparks, smoke, and the scorch left on the paving.
func _shut() -> void:
	_open = false
	ctx.play(&"hm_shut", mouth, -3.0)
	for v in [_breath, _breath2]:
		if v != null:
			ctx.fade_out(v, 0.5)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(mouth)
	ctx.shake.add_trauma(0.25)
	ctx.flash.call(Color(1.0, 0.7, 0.4, 0.1), 0.12)
	if is_instance_valid(_crack):
		var close := create_tween()
		close.tween_property(_crack, "open", 0.0, T_SHUT).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		close.tween_callback(_crack.queue_free)
	for q: QuadFx in [_column, _core]:
		if is_instance_valid(q):
			q.tween_param("intensity", 1.5, 0.0, T_SHUT, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
			q.life = q.age + T_SHUT + 0.02
	if is_instance_valid(_rays):
		_rays.tween_param("intensity", 0.5, 0.0, T_SHUT)
		_rays.life = _rays.age + T_SHUT + 0.02
	if is_instance_valid(_haze):
		_haze.tween_param("strength", 2.4, 0.0, 1.0)
		_haze.life = _haze.age + 1.02
	if is_instance_valid(_light):
		_light.tween_param("intensity", 0.8, 0.0, 1.2)
		_light.life = _light.age + 1.22
	var scorch := FxParts.decal(self, mouth, RADIUS * 0.9, Color("ff6a1a"), Color("ffd27a"), Color(0.07, 0.05, 0.04, 0.9))
	scorch.tween_param("heat", 1.0, 0.1, AFTER)
	var ring := FxParts.shockwave(self, mouth, RADIUS + 0.6, FxParts.FIRE)
	ring.set_param("thickness", 0.1)
	ring.tween_param("progress", 0.05, 1.0, 0.3, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.15, 0.15)
	ring.life = 0.32
	FxParts.sparks(self, ctx.overhead, sp, 40, FxParts.FIRE_LIFE, Vector2(80, 260), Vector2(140, 340))
	FxParts.smoke(self, sp, FxParts.particle_radius(RADIUS * 0.6), 18.0, 1.0, Vector2(25, 60), Vector2(3, 6), Vector2(1.0, 1.8), Color("ff7a2a"))


## The furnace light flickers while the door is open.
func _fx_process(_delta: float) -> void:
	if not _open or not DominionParts.staged(self):
		return
	var flicker := 0.78 + 0.22 * sin(t * 23.0) * sin(t * 7.3) + 0.08 * sin(t * 41.0)
	if is_instance_valid(_column):
		_column.set_param("intensity", 1.0 + 0.7 * flicker)
	if is_instance_valid(_core):
		_core.set_param("intensity", 1.1 + 0.7 * flicker)
	if is_instance_valid(_light):
		_light.set_param("intensity", 0.7 + 0.5 * flicker)
	if is_instance_valid(_rays):
		_rays.set_param("intensity", 0.3 + 0.3 * flicker)
	if is_instance_valid(_crack):
		_crack.pulse = flicker
		_crack.kick = maxf(_crack.kick - _delta * 4.0, 0.0)
		_crack.queue_redraw()


## The mouth itself: a jagged crack in the paving, drawn on the ground layer in ground units, deep red at its lips,
## white-orange at the middle. `open` 0..1 is how far it has torn, `pulse` the furnace's brightness.
class Crack extends Node2D:
	var rng := RandomNumberGenerator.new()
	var radius := 1.2
	var open := 0.0
	var pulse := 1.0
	var kick := 0.0
	var _points: PackedVector2Array

	## POINTS jagged points about the middle: a mouth longer across the screen than down it.
	func build() -> void:
		const POINTS := 11
		_points = PackedVector2Array()
		for i in POINTS:
			var a := TAU * float(i) / float(POINTS)
			var r := radius * rng.randf_range(0.55, 1.0)
			# Longer along screen-x (ground (1, -1)), narrower along screen-y (ground (1, 1)).
			var along := Vector2(1, -1).normalized() * cos(a) * r
			var across := Vector2(1, 1).normalized() * sin(a) * r * 0.55
			_points.append(along + across)

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if open <= 0.01 or _points.is_empty():
			return
		var lips := PackedVector2Array()
		var fire := PackedVector2Array()
		var core := PackedVector2Array()
		var k := open * (1.0 + 0.06 * kick)
		for p in _points:
			lips.append(p * k)
			fire.append(p * k * 0.62)
			core.append(p * k * 0.3)
		var hot := clampf(pulse, 0.0, 1.0)
		draw_colored_polygon(lips, Color(0.3, 0.03, 0.01, 0.95))
		draw_colored_polygon(fire, Color(0.55 + 0.4 * hot, 0.08 + 0.3 * hot, 0.02, 1.0))
		draw_colored_polygon(core, Color(1.0, 0.75 + 0.2 * hot, 0.45 + 0.4 * hot, 1.0))
		for i in lips.size():
			draw_line(lips[i], lips[(i + 1) % lips.size()], Color(0.12, 0.02, 0.01, 0.9), 0.04)
