class_name LightOfSolaris
extends FxTimeline
## Light of Solaris: the sun's own light let down in one pillar. The sky darkens and a needle of light finds the spot
## (T_CHARGE); then the pillar opens to RADIUS and stands for BEAM_TIME, and nothing under it is left -- people are
## burned to ash, buildings come down and their rubble goes with them. When it lifts, the ground it stood on is a pit
## (SolarisPit) that stays for the rest of the mission and takes whoever walks into it.

const RADIUS := 2.2
const T_CHARGE := 1.2
const BEAM_TIME := 5.0
const T_END := T_CHARGE + BEAM_TIME
## Seconds of smoke and cooling after the beam lifts.
const AFTER := 2.4
## How often the standing beam burns away what is under it.
const SCOUR_EVERY := 0.1
## Level 5, Wandering Sun: how far from the pillar it looks for a knot of people, how close neighbours must stand to make one,
## how often it looks again, and how fast the pillar drifts toward it (ground units per second).
const WANDER_R := 4.0
const KNOT_R := 1.0
const KNOT_EVERY := 0.5
const DRIFT := 0.8

const SH_COLUMN := preload("res://shaders/solar_beam.gdshader")
const COLUMN_H := 620.0
const SOLAR := [Color(0.92, 0.36, 0.06, 0.55), Color("ec7a1c"), Color("ffb62e"), Color("ffe27c"), Color("fffbe8")]
const SOLAR_LIFE := [Color("fffbe8"), Color("ffe27c"), Color("ffb62e"), Color("ec7a1c"), Color(0.6, 0.18, 0.04, 0.6)]
## What the pillar lifts off the ground: dark flecks that catch and burn out as they rise.
const ASH_LIFE := [Color("2c1c12"), Color("6a3410"), Color("e8741a"), Color("ffd27a"), Color(1.0, 0.95, 0.8, 0.5)]
const SUN := Color(1.0, 0.82, 0.42)
const SUN_HOT := Color(1.0, 0.94, 0.72)
const GOLD := Color("ffd76a")

var pit: SolarisPit
## How many the beam itself has burned away.
var burned := 0
## This cast's pillar radius and burn time, and where the beam lifts: the ability level's (PowerBook.stat()), the consts at level 1.
var lv_radius := RADIUS
var lv_beam_time := BEAM_TIME
var lv_t_end := T_END
## Where the pillar stands: the cast point, and at level 5 wherever the Wandering Sun has drifted to.
var beam_at := Vector2.ZERO

var _column: QuadFx
var _halo: QuadFx
var _glow: QuadFx
var _light: QuadFx
var _rays: QuadFx
var _updraft: PixelParticles
var _sparks: PixelParticles
var _voices: Array[Node] = []
## Wandering Sun: where the pillar is heading (Vector2.INF = nowhere, it stands) and when it looks for a knot again.
var _knot_to := Vector2.INF
var _knot_next := T_CHARGE


func _build() -> void:
	beam_at = origin
	lv_radius = float(PowerBook.stat(extra, "solaris", "RADIUS", RADIUS))
	lv_beam_time = float(PowerBook.stat(extra, "solaris", "BEAM_TIME", BEAM_TIME))
	lv_t_end = T_CHARGE + lv_beam_time
	duration = lv_t_end + AFTER
	at(T_CHARGE, _ignite)
	var ts := T_CHARGE
	while ts < lv_t_end:
		at(ts, scour)
		ts += SCOUR_EVERY
	at(lv_t_end, _lift)
	if _staged():
		_telegraph()


## Whether there is a stage to play on: a headless test hands an effect only the field and the ground.
func _staged() -> bool:
	return ctx.impact != null and ctx.shake != null and is_inside_tree()


## Everything under the pillar: the living die and the standing fall. Returns how many people it took.
func scour() -> int:
	var took := 0
	for e in ctx.field.in_radius(beam_at, lv_radius):
		var p := e as Person
		if p != null and p.inside:
			continue  # the building round them comes down first, and puts them out
		if ctx.field.kill(e, &"solaris", beam_at):
			took += 1
	burned += took
	ctx.env.damage_radius(beam_at, lv_radius, 99999.0, &"solaris")
	if _staged():
		ctx.shake.add_trauma(0.075)
	return took


## The pillar lands, and the ground under it opens.
func _ignite() -> void:
	pit = SolarisPit.new().setup(ctx.field, beam_at, lv_radius, ctx.rng.randf() * 40.0)
	ctx.world.add_child(pit)
	if _staged():
		_strike()


## The pillar lifts: the pit is left open, and the rubble over it is gone (SolarisPit.hide_rubble()).
func _lift() -> void:
	if is_instance_valid(pit):
		pit.armed = true
		pit.hide_rubble(ctx.env)
	if _staged():
		_fade()


# --- The show ----------------------------------------------------------------

func _telegraph() -> void:
	var sp := Iso.ground_to_screen(origin)
	ctx.impact.dim(1.0, 1.6)
	ctx.play(&"hs_charge", origin)
	ctx.play(&"nova_lock", origin, -4.0)
	var rings := FxParts.rings(self, origin, lv_radius, GOLD, 3, 22.0)
	rings.tween_param("reveal", 0.0, 1.0, 0.5, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	rings.tween_param("alpha", 1.0, 0.0, 0.3, T_CHARGE)
	rings.life = T_CHARGE + 0.32
	# The needle: a thread of light down from the sky, thickening.
	var needle := FxParts.beam(self, ctx.overhead, sp, 6.0, COLUMN_H, SOLAR)
	needle.set_param("band_speed", 18.0)
	needle.tween_param("intensity", 0.12, 0.8, T_CHARGE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	needle.life = T_CHARGE
	var warm := FxParts.ground_light(self, origin, lv_radius * 1.8, SUN, 0.0)
	warm.tween_param("intensity", 0.0, 0.9, T_CHARGE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	warm.life = T_CHARGE + 0.05
	# Motes drawn in off the ground toward the spot.
	var motes := FxParts.particles(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, SOLAR_LIFE)
	motes.gravity = -50.0
	motes.drag = 0.4
	motes.burst(46, {"radius": FxParts.particle_radius(lv_radius * 1.5), "speed": Vector2(40, 90),
		"dir": PixelParticles.Dir.INWARD, "alt": Vector2(0, 8), "alt_speed": Vector2(6, 30), "life": Vector2(0.6, 1.1),
		"size": Vector2(1, 2)})


func _strike() -> void:
	var sp := Iso.ground_to_screen(origin)
	var semi := Iso.radius_to_screen(lv_radius)
	ctx.flash.call(Color(1.0, 0.96, 0.82, 0.85), 0.5)
	ctx.impact.impact_frame(0.06, ctx.impact.focus_of(sp), Color(1.0, 0.98, 0.9), Color(0.25, 0.08, 0.0))
	ctx.impact.hitstop(0.09)
	ctx.impact.aberration(3.0, 0.4)
	ctx.shake.add_trauma(0.9)
	ctx.shake.kick(Vector2(0, 5))
	ctx.play(&"nova_crack", origin)
	ctx.play(&"laser_ignite", origin, 3.0)
	_voices = [ctx.play(&"laser_fire", origin, 4.0), ctx.play(&"dr_breath", origin, -2.0)]

	# Behind the pillar: a tall glow round it and a hot bloom where it stands.
	_halo = FxParts.bloom(self, sp + Vector2(0, -COLUMN_H * 0.3), semi.x * 1.7, SUN, 0.0, 2.4)
	_glow = FxParts.bloom(self, sp, semi.x * 1.9, SUN_HOT, 0.0, 0.5)
	_column = FxParts.quad(self, SH_COLUMN, Vector2(semi.x * 2.0, COLUMN_H + semi.y), ctx.overhead,
		Vector2(0.5, COLUMN_H / (COLUMN_H + semi.y)))
	_column.position = sp
	_column.z_index = 6
	_column.set_param("size_px", _column.size)
	_column.set_param("foot", semi.y / (COLUMN_H + semi.y))
	_column.set_param("seed", ctx.rng.randf() * 40.0)
	FxParts.set_ramp(_column, SOLAR)
	_column.tween_param("intensity", 0.06, 1.0, 0.22, 0.0, Tween.TRANS_BACK, Tween.EASE_OUT)

	_light = FxParts.ground_light(self, origin, lv_radius * 3.4, SUN, 1.9)
	_light.set_param("flicker", 1.0)
	_rays = FxParts.ground_rays(self, origin, lv_radius * 3.2, SUN_HOT, 72.0)
	_rays.tween_param("reach", 0.2, 1.0, 0.3, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	_rays.tween_param("intensity", 1.4, 0.55, 0.7)

	var ring := FxParts.shockwave(self, origin, lv_radius * 2.6, SOLAR)
	ring.set_param("thickness", 0.14)
	ring.tween_param("progress", 0.05, 1.0, 0.45, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.25, 0.25)
	ring.life = 0.55
	var refract := FxParts.refract_ring(self, origin, lv_radius * 2.8, SUN)
	refract.set_param("strength", 8.0)
	refract.tween_param("progress", 0.1, 1.0, 0.5, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	refract.life = 0.52
	var haze := FxParts.heat_haze(self, sp, FxParts.particle_radius(lv_radius * 1.7), 2.6)
	haze.tween_param("strength", 2.6, 0.0, 1.6, lv_beam_time)
	haze.life = lv_beam_time + 1.65

	# What the light lifts off the ground and burns: flecks streaming up the pillar, sparks thrown from its foot.
	_updraft = FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.STREAK, ASH_LIFE, 110.0, lv_beam_time, {
		"radius": FxParts.particle_radius(lv_radius * 0.9), "speed": Vector2(0, 10), "alt": Vector2(0, 30),
		"alt_speed": Vector2(150, 380), "life": Vector2(0.35, 0.8), "size": Vector2(1, 3)})
	_updraft.gravity = -260.0
	_updraft.streak_len = 0.05
	_updraft.z_index = 7
	_sparks = FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.STREAK, SOLAR_LIFE, 80.0, lv_beam_time, {
		"radius": FxParts.particle_radius(lv_radius), "speed": Vector2(90, 280), "dir": PixelParticles.Dir.OUTWARD,
		"alt": Vector2(0, 8), "alt_speed": Vector2(40, 220), "life": Vector2(0.3, 0.7), "size": Vector2(1, 2)})
	_sparks.gravity = 320.0
	_sparks.drag = 1.2
	_sparks.z_index = 7
	FxParts.debris(self, sp, 34, FxParts.particle_radius(lv_radius * 0.8), Vector2(80, 260), FxParts.HOT_ROCK,
		Vector2(1.5, 4.5), true)


func _fade() -> void:
	var sp := Iso.ground_to_screen(origin)
	_column.tween_param("intensity", 1.0, 0.0, 0.42, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	_column.life = _column.age + 0.44
	_rays.tween_param("intensity", 0.55, 0.0, 0.4)
	for v in _voices:
		ctx.fade_out(v, 0.5)
	ctx.play(&"laser_powerdown", origin)
	ctx.play(&"nova_rumble", origin, -3.0)
	ctx.impact.dim(0.0, 0.7)
	ctx.impact.aberration(1.6, 0.3)
	ctx.shake.add_trauma(0.5)
	var ring := FxParts.shockwave(self, origin, lv_radius * 1.8, FxParts.DUST_RING)
	ring.set_param("thickness", 0.2)
	ring.tween_param("progress", 0.3, 1.0, 0.6, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.4, 0.25)
	ring.life = 0.7
	# The pit breathes out: smoke lit from below, and embers rising off the molten rim.
	FxParts.smoke(self, sp, FxParts.particle_radius(lv_radius * 0.8), 30.0, AFTER - 0.6, Vector2(30, 80), Vector2(3, 7),
		Vector2(1.2, 2.2), Color("ff7a2a"))
	var embers := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 40.0,
		AFTER - 0.4, {"radius": FxParts.particle_radius(lv_radius), "speed": Vector2(0, 12), "alt": Vector2(0, 6),
		"alt_speed": Vector2(14, 50), "life": Vector2(0.6, 1.4), "size": Vector2(1, 1)})
	embers.gravity = -20.0


## Wandering Sun (level 5) drifts the pillar toward a knot of people; the pillar's light breathes while it stands, and dies with it.
func _fx_process(delta: float) -> void:
	if PowerBook.twist_at(extra, "solaris"):
		_wander(delta)
	if not is_instance_valid(_light):
		return
	var k := curve([[T_CHARGE, 0.0], [T_CHARGE + 0.15, 1.0], [lv_t_end, 1.0], [lv_t_end + 0.5, 0.35], [duration, 0.0]])
	var breath := 0.92 + 0.08 * sin(t * 23.0) * sin(t * 7.1)
	_light.set_param("intensity", 1.9 * k * breath)
	var standing := curve([[T_CHARGE, 0.0], [T_CHARGE + 0.2, 1.0], [lv_t_end, 1.0], [lv_t_end + 0.45, 0.0]])
	if is_instance_valid(_halo):
		_halo.set_param("intensity", 0.55 * standing * breath)
	if is_instance_valid(_glow):
		_glow.set_param("intensity", 1.2 * standing * breath)


# --- Level 5: the Wandering Sun ----------------------------------------------

## The person within WANDER_R of the pillar with the most neighbours within KNOT_R (a knot, not a straggler); ties go to
## the nearer one, then to the field's own order. Null when no one is in reach: the pillar stands.
func _knot() -> Person:
	var best: Person = null
	var best_n := -1
	var best_d := 0.0
	for e in ctx.field.in_radius(beam_at, WANDER_R):
		var p := e as Person
		if p == null or p.inside:
			continue
		var n := ctx.field.in_radius(p.ground_pos, KNOT_R).size() - 1
		var d := p.ground_pos.distance_to(beam_at)
		if n > best_n or (n == best_n and d < best_d):
			best = p
			best_n = n
			best_d = d
	return best


## While the beam stands the pillar looks for a knot every KNOT_EVERY seconds and drifts toward it at DRIFT, never past it.
func _wander(delta: float) -> void:
	var span := minf(t, lv_t_end) - maxf(t - delta, T_CHARGE)
	if span <= 0.0:
		return
	if t >= _knot_next:
		_knot_next = t + KNOT_EVERY
		var knot := _knot()
		_knot_to = knot.ground_pos if knot != null else Vector2.INF
	if _knot_to == Vector2.INF:
		return
	var moved := beam_at.move_toward(_knot_to, DRIFT * span)
	if moved == beam_at:
		return
	beam_at = moved
	if is_instance_valid(pit):
		pit.move_to(beam_at)
	_follow()


## The staged pieces stand where the pillar does.
func _follow() -> void:
	var sp := Iso.ground_to_screen(beam_at)
	if is_instance_valid(_column):
		_column.position = sp
	if is_instance_valid(_halo):
		_halo.position = sp + Vector2(0, -COLUMN_H * 0.3)
	if is_instance_valid(_glow):
		_glow.position = sp
	if is_instance_valid(_light):
		_light.position = beam_at
	if is_instance_valid(_rays):
		_rays.position = beam_at
	if is_instance_valid(_updraft):
		_updraft.position = sp
	if is_instance_valid(_sparks):
		_sparks.position = sp
