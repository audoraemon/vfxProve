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
## Levels (PowerBook "hellspark"): RADIUS and OPEN grow; level 1 is the numbers below. Level 5's twist, Wandering Mouth:
## while it is open, one click moves it -- it shuts with a burst where it was and tears open at the click (no farther
## than WANDER from it) for the rest of its open time. Once a cast. The danger, the burning ticks and the scorch go with
## it.

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
## Wandering Mouth: how far from where it stands the mouth may be moved, and how fast it tears open at the new place.
const WANDER := 4.0
const MOVE_TEAR := 0.2

## Where the door opened (the cast point, carried through an open passage; moved by Wandering Mouth), how many it
## burned, how many buildings it set alight.
var mouth := Vector2.ZERO
var burned := 0
var lit := 0
## This cast's mouth and open time at its ability level (RADIUS and OPEN at level 1).
var lv_radius := RADIUS
var lv_open := OPEN
## Wandering Mouth (level 5): whether this cast has it, and whether the mouth has been moved (once a cast).
var moved := false
var _wander := false

var _open := false
var _threat := -1
var _crack: Crack
var _column: QuadFx
var _core: QuadFx
var _light: QuadFx
var _rays: QuadFx
var _haze: QuadFx
var _embers: PixelParticles
var _flames: PixelParticles
var _breath: Node
var _breath2: Node


## Whether the door is open now: the ticks only burn while it is.
func open() -> bool:
	return _open


## When the door shuts.
func shut_at() -> float:
	return T_OPEN + lv_open


func _build() -> void:
	lv_radius = float(PowerBook.stat(extra, "hellspark", "RADIUS", RADIUS))
	lv_open = float(PowerBook.stat(extra, "hellspark", "OPEN", OPEN))
	_wander = PowerBook.twist_at(extra, "hellspark")
	mouth = ctx.field.through(origin)
	duration = T_OPEN + lv_open + AFTER
	busy = T_OPEN
	at(T_OPEN, _open_door)
	var ticks := int(floor(lv_open / BURN_EVERY))
	for i in ticks:
		at(T_OPEN + BURN_EVERY * float(i), _burn)
	at(T_OPEN + 3.0, _roar_again)
	at(shut_at(), _shut)
	ctx.play(&"hm_tear", mouth, -2.0)
	if not DominionParts.staged(self):
		return
	_tear(mouth, T_OPEN)


## The paving rumbles and the crack tears open at `at_pos` over `tear`: a dull red seam first, the ground under it warming.
func _tear(at_pos: Vector2, tear: float) -> void:
	_crack = Crack.new()
	_crack.rng.seed = ctx.rng.randi()
	_crack.radius = lv_radius * 0.8
	_crack.position = at_pos
	_crack.z_index = 4
	_crack.build()
	track(_crack, ctx.ground)
	var tearing := create_tween()
	tearing.tween_property(_crack, "open", 1.0, tear).from(0.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_light = FxParts.ground_light(self, at_pos, lv_radius * 2.0, FLAME, 0.0)
	_light.tween_param("intensity", 0.0, 0.8, tear, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	var mark := FxParts.rings(self, at_pos, lv_radius, Color("ff7a3a"), 2, 20.0)
	mark.set_param("scan", 0.0)
	mark.tween_param("reveal", 0.0, 1.0, tear * 0.8, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	mark.tween_param("fade", 1.0, 0.0, 0.3, tear)
	mark.life = tear + 0.35
	ctx.shake.add_trauma(0.12)
	var sp := Iso.ground_to_screen(at_pos)
	var dust := FxParts.particles(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, FxParts.DUST_LIFE)
	dust.gravity = 60.0
	dust.burst(14, {"radius": FxParts.particle_radius(lv_radius * 0.8), "speed": Vector2(5, 20), "alt": Vector2(0, 4),
		"alt_speed": Vector2(20, 60), "life": Vector2(0.3, tear), "size": Vector2(1, 2)})


## The door opens: the town is warned off it, and the furnace light pours up out of the ground.
func _open_door() -> void:
	_open = true
	if ctx.crowd != null:
		_threat = ctx.crowd.threats.register(mouth, lv_radius + 0.5, 0.7, lv_open, 5.0, 8.0, &"fire")
	ctx.play(&"hm_open", mouth, 0.0)
	_breath = ctx.play(&"hm_roar", mouth, -6.0)
	if not DominionParts.staged(self):
		return
	_pour(lv_open)


## The furnace's light and fire at the mouth, for `left` seconds (the rest of its open time).
func _pour(left: float) -> void:
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
	_rays = FxParts.ground_rays(self, mouth, lv_radius * 2.4, HOT, 48.0)
	_rays.set_param("reach", 0.9)
	_rays.set_param("intensity", 0.5)
	_haze = FxParts.heat_haze(self, sp, FxParts.particle_radius(lv_radius * 1.6), 2.4)
	var halo := FxParts.bloom(self, sp + Vector2(0, -16), 48.0, FLAME, 1.0, 0.7)
	halo.tween_param("intensity", 1.0, 0.0, 0.5, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	halo.life = 0.52
	var ring := FxParts.shockwave(self, mouth, lv_radius + 1.2, FxParts.FIRE)
	ring.set_param("thickness", 0.14)
	ring.tween_param("progress", 0.05, 1.0, 0.4, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.2, 0.2)
	ring.life = 0.42
	var air := FxParts.refract_ring(self, mouth, lv_radius + 1.8, HOT)
	air.tween_param("progress", 0.05, 1.0, 0.5, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	air.life = 0.52
	# Embers spiralling out and up for as long as it is open, and a few flames licking out of the mouth.
	_embers = FxParts.emitter(self, ctx.overhead, sp + Vector2(0, -4), PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 60.0, left,
		{"radius": FxParts.particle_radius(lv_radius * 0.7), "speed": Vector2(8, 40), "dir": PixelParticles.Dir.OUTWARD,
		"alt": Vector2(0, 10), "alt_speed": Vector2(40, 120), "life": Vector2(0.9, 1.8), "size": Vector2(1, 2)})
	_embers.gravity = -45.0
	_embers.drag = 0.6
	_flames = FxParts.emitter(self, ctx.overhead, sp + Vector2(0, -2), PixelParticles.Shape.PUFF, FxParts.FIRE_LIFE, 40.0, left,
		{"radius": FxParts.particle_radius(lv_radius * 0.6), "speed": Vector2(2, 10), "alt": Vector2(0, 6),
		"alt_speed": Vector2(30, 90), "life": Vector2(0.3, 0.7), "size": Vector2(2, 5), "size_end_mul": 0.3})
	_flames.gravity = -20.0
	FxParts.sparks(self, ctx.overhead, sp, 30, FxParts.FIRE_LIFE, Vector2(60, 220), Vector2(120, 320))
	FxParts.debris(self, sp, 10, FxParts.particle_radius(lv_radius * 0.7), Vector2(40, 160), FxParts.HOT_ROCK, Vector2(1.5, 3.0), true)


## Wandering Mouth: true at level 5 while the door is open and it has not yet been moved.
func can_follow_up() -> bool:
	return _wander and not moved and _open and not finished


## Wandering Mouth: the mouth shuts with a burst where it stands and tears open at the click (no farther than WANDER from
## it) for the rest of its open time; the danger moves with it, and the ticks burn there. Once a cast.
func follow_up(at_pos: Vector2, _extra: Dictionary) -> bool:
	if not can_follow_up():
		return false
	moved = true
	var was := mouth
	var left := maxf(shut_at() - t, 0.0)
	mouth = was + (at_pos - was).limit_length(WANDER)
	ctx.play(&"cf_erupt", was, -3.0)
	for v in [_breath, _breath2]:
		if v != null:
			ctx.fade_out(v, 0.5)
	_breath2 = null
	if ctx.crowd != null:
		ctx.crowd.threats.end(_threat)
		_threat = ctx.crowd.threats.register(mouth, lv_radius + 0.5, 0.7, left, 5.0, 8.0, &"fire")
	ctx.play(&"hs_rumble", mouth, -2.0)
	ctx.play(&"dr_ignite", mouth, 0.0)
	_breath = ctx.play(&"dr_breath", mouth, -6.0)
	if DominionParts.staged(self):
		for e in [_embers, _flames]:
			if is_instance_valid(e):
				(e as PixelParticles).emitting = false
		_close_visuals(was)
		_tear(mouth, MOVE_TEAR)
		_pour(left)
	return true


## Wandering Mouth's preview: the mouth's own circle where the click would move it.
func follow_up_area() -> Dictionary:
	return {"shape": "circle", "r": lv_radius}


## One tick of the furnace: whoever stands at the mouth catches, the walls about it take heat, the decor chars.
func _burn() -> void:
	if not _open:
		return
	for e in ctx.field.in_radius(mouth, lv_radius):
		var person := e as Person
		if person != null and person.inside:
			continue
		if ctx.field.kill(e, &"fire", mouth):
			burned += 1
	var fires: FireManager = ctx.crowd.fires if ctx.crowd != null else null
	for s in ctx.env.structures():
		if s.destroyed or s.distance_to(mouth) > lv_radius:
			continue
		var was := fires != null and fires.is_burning(s)
		s.damage(HEAT, mouth, &"fire")
		if fires != null and not was and fires.is_burning(s):
			lit += 1
	for d in ctx.env.decor():
		if is_instance_valid(d) and d.at.distance_to(mouth) <= lv_radius:
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
	_close_visuals(mouth)


## The mouth at `at_pos` closes: the crack shuts, the light dies, a burst of sparks and smoke, the scorch on the paving.
func _close_visuals(at_pos: Vector2) -> void:
	var sp := Iso.ground_to_screen(at_pos)
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
	var scorch := FxParts.decal(self, at_pos, lv_radius * 0.9, Color("ff6a1a"), Color("ffd27a"), Color(0.07, 0.05, 0.04, 0.9))
	scorch.tween_param("heat", 1.0, 0.1, AFTER)
	var ring := FxParts.shockwave(self, at_pos, lv_radius + 0.6, FxParts.FIRE)
	ring.set_param("thickness", 0.1)
	ring.tween_param("progress", 0.05, 1.0, 0.3, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.15, 0.15)
	ring.life = 0.32
	FxParts.sparks(self, ctx.overhead, sp, 40, FxParts.FIRE_LIFE, Vector2(80, 260), Vector2(140, 340))
	FxParts.smoke(self, sp, FxParts.particle_radius(lv_radius * 0.6), 18.0, 1.0, Vector2(25, 60), Vector2(3, 6), Vector2(1.0, 1.8), Color("ff7a2a"))


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
