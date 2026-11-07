class_name DoorToTheDeepFx
extends FxTimeline
## Door to the Deep (Passage, Tier II): a door opens in the ground and black water floods out of it. The click is the
## door (`mouth`; a Mirrorfold way in carries the water to its way out, EnemyField.through()). It takes T_OPEN to open;
## then the water runs out over a circle that grows from the mouth to RADIUS in SPREAD seconds, stands SPAN, and drains
## back into the door over DRAIN. Every TICK while there is water: everyone standing in it -- citizen or soldier, not
## those indoors -- walks at SLOW of their pace (Person.statuses "slow"; their pace is theirs again the moment they
## are out of it, or when it drains); every fire on a building in it is doused a bucket's worth (FireManager.douse:
## a fire goes out in a few ticks, and a puff of steam goes up); every building in it takes SOAK of water damage
## (damage kind water: nothing catches, nothing is scorched when it falls -- a flooded field is left bare, not
## charred). Nobody dies of it. A mild water threat is laid on the circle once the water has spread, so people take
## another street rather than wade; whoever is in it keeps their mind (a shelter whose cellar is flooded taking nobody
## in is a later rule, not built here). Loud: the door's crash is seen and heard (PowerBook.REACH), from the opening.

const T_OPEN := 0.8
const RADIUS := 4.0
const SPREAD := 2.0
const SPAN := 25.0
const DRAIN := 2.0
const TICK := 0.5
const SLOW := 0.33
const SOAK := 1.5
## The water as it first runs from the door, and the door's own size (ground units).
const FIRST_REACH := 0.8
const MOUTH_R := 0.8
## A ripple runs out from the door every RIPPLE_EVERY seconds; a drip is heard every DRIP_EVERY.
const RIPPLE_EVERY := 1.5
const DRIP_EVERY := 4.0
const SH_FLOOD := preload("res://shaders/flood_water.gdshader")
const DEEP := Color(0.02, 0.03, 0.08)
const PALE := Color(0.78, 0.9, 1.0)
const SKY := Color(0.45, 0.75, 1.0)
const WATER_DEEP := Color(0.02, 0.05, 0.12, 0.95)
const WATER_BODY := Color(0.05, 0.11, 0.24, 0.93)
const WATER_MID := Color(0.09, 0.2, 0.38, 0.9)
const WATER_FOAM := Color(0.72, 0.86, 0.96, 0.85)
const WATER_FOAM_SHADOW := Color(0.36, 0.56, 0.76, 0.8)
const WET := Color(0.05, 0.07, 0.11, 0.6)
const STEAM := [Color(0.96, 0.98, 1.0, 0.85), Color(0.86, 0.9, 0.95, 0.6), Color(0.75, 0.8, 0.88, 0.3), Color(0.7, 0.75, 0.82, 0.0)]
const GLINT := [Color("ffffff"), Color("eaf6ff"), Color(0.8, 0.9, 1.0, 0.6), Color(0.7, 0.85, 1.0, 0.0)]

## Where the door is: the click, or where a Mirrorfold carries it.
var mouth := Vector2.ZERO
## How many fires the water put out, and how much water damage it did to buildings.
var doused := 0
var soaked_damage := 0.0

## Whoever is standing in the water, by instance id -> [Person, the "slow" they had before the water, if any].
var _soaked := {}
## Ticks run: the next is at T_OPEN + TICK * _ticks (counted, not summed, so the last lands on the drain's end).
var _ticks := 0
var _flooded := false
var _ripple_in := 0.0
var _glints: PixelParticles


## How far the water reaches from the door at `now`: nothing before the door is open, out to RADIUS over SPREAD,
## RADIUS for the span, and back to nothing over DRAIN.
func reach(now: float) -> float:
	if now < T_OPEN:
		return 0.0
	if now < T_OPEN + SPREAD:
		return lerpf(FIRST_REACH, RADIUS, (now - T_OPEN) / SPREAD)
	if now <= T_OPEN + SPAN:
		return RADIUS
	return RADIUS * maxf(1.0 - (now - T_OPEN - SPAN) / DRAIN, 0.0)


## Whether `g` is under water now.
func wet(g: Vector2) -> bool:
	return g.distance_to(mouth) <= reach(t)


## How far the door is open, 0..1: it opens over T_OPEN and closes as the water drains.
func opening() -> float:
	var k := clampf(t / T_OPEN, 0.0, 1.0)
	var o := 1.0 - pow(1.0 - k, 3.0)
	if t > T_OPEN + SPAN:
		o *= 1.0 - clampf((t - T_OPEN - SPAN) / DRAIN, 0.0, 1.0)
	return o


func _build() -> void:
	mouth = ctx.field.through(origin)
	duration = T_OPEN + SPAN + DRAIN + 0.3
	busy = T_OPEN
	at(T_OPEN, _open)
	at(T_OPEN + 0.3, func(): ctx.play(&"ts_surge", mouth, -3.0))
	at(T_OPEN + SPREAD, _lay_threat)
	var drip := T_OPEN + DRIP_EVERY
	while drip < T_OPEN + SPAN:
		at(drip, func(): ctx.play(&"ts_drip", mouth, 0.0))
		drip += DRIP_EVERY
	at(T_OPEN + SPAN, _drain)
	ctx.play(&"hs_rumble", mouth, -2.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(mouth)
	# The street darkens and stays dark where the water will lie: the wet ground, under everything else.
	var wet_ground := FxParts.frost_ground(self, mouth, RADIUS + 0.2)
	wet_ground.z_index = 1
	wet_ground.set_param("plate", WET)
	wet_ground.set_param("crack", Color(0.2, 0.28, 0.4, 0.12))
	wet_ground.set_param("rim", Color(0.3, 0.4, 0.5, 0.3))
	wet_ground.set_param("progress", 0.0)
	wet_ground.tween_param("progress", 0.0, 1.0, SPREAD, T_OPEN, Tween.TRANS_QUAD, Tween.EASE_OUT)
	wet_ground.tween_param("fade", 1.0, 0.0, 0.3, duration - 0.3)
	var pool := Pool.new()
	pool.fx = self
	pool.position = mouth
	pool.z_index = 2
	track(pool, ctx.ground)
	var side := (RADIUS + 1.0) * 2.0
	var water := QuadFx.new().setup(SH_FLOOD, Vector2(side, side))
	water.set_param("length", side)
	water.set_param("width", side)
	water.set_param("settle", 0.55)
	water.set_param("seed", ctx.rng.randf() * 10.0)
	water.set_param("deep", WATER_DEEP)
	water.set_param("body", WATER_BODY)
	water.set_param("mid", WATER_MID)
	water.set_param("foam", WATER_FOAM)
	water.set_param("foam_shadow", WATER_FOAM_SHADOW)
	pool.add_child(water)
	var shore := Shore.new()
	shore.fx = self
	shore.position = mouth
	shore.z_index = 3
	track(shore, ctx.ground)
	var door := Mouth.new()
	door.fx = self
	door.position = mouth
	door.z_index = 3
	track(door, ctx.ground)
	# A cold sheen on the ground about the water, and pale sky glints on its surface.
	var light := FxParts.ground_light(self, mouth, RADIUS * 1.1, SKY, 0.0)
	light.tween_param("intensity", 0.0, 0.22, SPREAD, T_OPEN)
	light.tween_param("intensity", 0.22, 0.0, DRAIN, T_OPEN + SPAN)
	_glints = FxParts.emitter(self, ctx.overhead_back, sp, PixelParticles.Shape.SQUARE, GLINT, 16.0, SPAN + DRAIN, {
		"radius": 0.0, "speed": Vector2(0, 3), "alt": Vector2(0, 1), "alt_speed": Vector2(0, 2), "life": Vector2(0.25, 0.6),
		"size": Vector2(1, 1)})
	_glints.emitting = false
	_ripple_in = 0.3


## The door is open: the water bursts out of it.
func _open() -> void:
	ctx.play(&"ts_crash", mouth, 0.0)
	if not DominionParts.staged(self):
		return
	ctx.shake.add_trauma(0.3)
	ctx.flash.call(Color(0.1, 0.2, 0.4, 0.12), 0.2)
	if is_instance_valid(_glints):
		_glints.emitting = true
	var sp := Iso.ground_to_screen(mouth)
	var ring := FxParts.shockwave(self, mouth, FIRST_REACH + 1.2, FxParts.ICE_WAVE)
	ring.set_param("thickness", 0.14)
	ring.set_param("inner_heat", 0.0)
	ring.tween_param("progress", 0.05, 1.0, 0.5, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.3, 0.25)
	ring.life = 0.6
	var spray := FxParts.particles(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, Set2Parts.WATER_LIFE)
	spray.gravity = 320.0
	spray.drag = 0.6
	spray.burst(70, {"radius": FxParts.particle_radius(MOUTH_R), "speed": Vector2(20, 90), "dir": PixelParticles.Dir.OUTWARD,
		"alt": Vector2(0, 10), "alt_speed": Vector2(60, 200), "life": Vector2(0.5, 1.1), "size": Vector2(1, 3)})
	var foam := FxParts.particles(self, ctx.overhead, sp, PixelParticles.Shape.PUFF, Set2Parts.FOAM_LIFE)
	foam.gravity = 260.0
	foam.drag = 0.8
	foam.burst(24, {"radius": FxParts.particle_radius(MOUTH_R * 0.6), "speed": Vector2(10, 40), "dir": PixelParticles.Dir.OUTWARD,
		"alt": Vector2(0, 16), "alt_speed": Vector2(40, 140), "life": Vector2(0.5, 0.9), "size": Vector2(2, 4), "size_end_mul": 0.5})


## The water has spread: a mild threat lies on the circle, so people would rather go round than wade.
func _lay_threat() -> void:
	if ctx.crowd != null:
		ctx.crowd.threats.register(mouth, RADIUS, 0.3, SPAN, 5.0, 8.0, &"water")


## The span is over: the water runs back into the door.
func _drain() -> void:
	ctx.play(&"ts_roar", mouth, -4.0)
	if not DominionParts.staged(self):
		return
	ctx.shake.add_trauma(0.12)
	if is_instance_valid(_glints):
		_glints.emitting = false


func _fx_process(delta: float) -> void:
	# The rules run on their own clock, a tick at a time, so a long frame (or a test's long step) misses none.
	while t >= T_OPEN + TICK * float(_ticks):
		_tick(T_OPEN + TICK * float(_ticks))
		_ticks += 1
	if not DominionParts.staged(self):
		return
	var r := reach(t)
	if is_instance_valid(_glints):
		_glints.spec["radius"] = FxParts.particle_radius(maxf(r - 0.3, 0.0))
	_ripple_in -= delta
	if r > FIRST_REACH and t < T_OPEN + SPAN and _ripple_in <= 0.0:
		_ripple_in = RIPPLE_EVERY
		var ripple := FxParts.shockwave(self, mouth, r, FxParts.ICE)
		ripple.set_param("thickness", 0.05)
		ripple.set_param("inner_heat", 0.0)
		ripple.tween_param("progress", MOUTH_R / r * 0.9, 1.0, 1.4, 0.0, Tween.TRANS_SINE, Tween.EASE_OUT)
		ripple.tween_param("fade", 0.45, 0.0, 1.4)
		ripple.life = 1.45


## One tick of the water at `now`: who is in it is slowed, who has left it has their pace back, every fire in it is
## doused a bucket's worth, every building in it takes SOAK.
func _tick(now: float) -> void:
	var r := reach(now)
	if r <= 0.001:
		if _flooded:
			_dry_all()
			_flooded = false
		return
	_flooded = true
	var in_water := {}
	for e in ctx.field.in_radius(mouth, r):
		var p := e as Person
		if p == null or p.inside or not p.is_alive():
			continue
		var id := p.get_instance_id()
		in_water[id] = true
		if not _soaked.has(id):
			_soaked[id] = [p, p.statuses.get(&"slow", null)]
			p.statuses[&"slow"] = SLOW
			p.walk_speed = p._mind_speed()
	for id in _soaked.keys():
		if not in_water.has(id):
			_dry(id)
	var fires: FireManager = ctx.crowd.fires if ctx.crowd != null else null
	for s in ctx.env.near(mouth, r):
		if not is_instance_valid(s) or s.destroyed or s.distance_to(mouth) > r:
			continue
		if fires != null and fires.is_burning(s):
			fires.douse(s)
			if not fires.is_burning(s):
				doused += 1
				_steam(s)
		s.damage(SOAK, mouth, &"water")
		soaked_damage += SOAK


## The one remembered under `id` is out of the water: their pace is theirs again.
func _dry(id: int) -> void:
	var held: Array = _soaked[id]
	_soaked.erase(id)
	var p: Person = held[0]
	if not is_instance_valid(p):
		return
	if held[1] == null:
		p.statuses.erase(&"slow")
	else:
		p.statuses[&"slow"] = held[1]
	p.walk_speed = p._mind_speed()


func _dry_all() -> void:
	for id in _soaked.keys():
		_dry(id)


## A fire put out: steam off the building.
func _steam(s: Structure) -> void:
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(s.center()) + Vector2(0, -s.height * 0.4)
	FxParts.smoke(self, sp, 10.0, 22.0, 0.9, Vector2(25, 60), Vector2(3, 6), Vector2(0.8, 1.5), Color(0, 0, 0, 0), STEAM)


## Cut short (the act ends): nobody is left slowed.
func end_now() -> void:
	_dry_all()
	super.end_now()


## The water's shape at `r` from the door: a circle whose edge laps, in ground units.
static func shore(r: float, time: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 72:
		var a := float(i) / 72.0 * TAU
		var w := r * (1.0 + 0.025 * sin(a * 5.0 + time * 2.1) + 0.018 * sin(a * 9.0 - time * 1.3) + 0.012 * sin(a * 3.0 + time * 0.7))
		pts.append(Vector2(cos(a), sin(a)) * w)
	return pts


## The water's body on the ground: the circle of reach, lapping at its edge, with the flood drawn inside it (its
## children are clipped to the shape).
class Pool extends Node2D:
	var fx: DoorToTheDeepFx

	func _ready() -> void:
		clip_children = CanvasItem.CLIP_CHILDREN_ONLY

	func _process(_delta: float) -> void:
		if fx.t > T_OPEN + SPAN + DRAIN + 0.1:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var r := fx.reach(fx.t)
		if r <= 0.02:
			return
		draw_colored_polygon(DoorToTheDeepFx.shore(r, fx.t), Color.WHITE)


## The water's edge: a pale line lapping round the pool.
class Shore extends Node2D:
	var fx: DoorToTheDeepFx

	func _process(_delta: float) -> void:
		if fx.t > T_OPEN + SPAN + DRAIN + 0.1:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var r := fx.reach(fx.t)
		if r <= 0.05:
			return
		var pts := DoorToTheDeepFx.shore(r, fx.t)
		pts.append(pts[0])
		draw_polyline(pts, Color(PALE, 0.4), 0.05)
		draw_polyline(pts, Color(WATER_FOAM_SHADOW, 0.3), 0.1)


## The door in the street: a round black mouth, deepening to the middle, a pale rim, a glint turning slowly round it.
class Mouth extends Node2D:
	var fx: DoorToTheDeepFx

	func _process(_delta: float) -> void:
		if fx.t > T_OPEN + SPAN + DRAIN + 0.1:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var o := fx.opening()
		if o <= 0.01:
			return
		var r := MOUTH_R * o
		var spin := fx.t * 0.9
		draw_circle(Vector2.ZERO, r, Color(DEEP, 0.92))
		draw_circle(Vector2.ZERO, r * 0.55, Color(0.0, 0.0, 0.02, 0.98))
		# Faint light turning in the deep.
		for j in 3:
			var a0 := spin * (1.0 + 0.3 * float(j)) + float(j) * 2.1
			draw_arc(Vector2.ZERO, r * (0.35 + 0.18 * float(j)), a0, a0 + 1.3 + 0.4 * float(j % 2), 16, Color(SKY, 0.18 + 0.1 * float(j % 2)), 0.04)
		# The rim, and its glint.
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(PALE, 0.85), 0.06)
		draw_arc(Vector2.ZERO, r + 0.07, 0.0, TAU, 48, Color(SKY, 0.25), 0.04)
		var ga := -spin * 1.6
		draw_arc(Vector2.ZERO, r, ga, ga + 0.8, 10, Color(1, 1, 1, 0.9), 0.08)
