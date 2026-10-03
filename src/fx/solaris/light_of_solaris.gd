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

var _column: QuadFx
var _halo: QuadFx
var _glow: QuadFx
var _light: QuadFx
var _rays: QuadFx
var _voices: Array[Node] = []


func _build() -> void:
	duration = T_END + AFTER
	at(T_CHARGE, _ignite)
	var ts := T_CHARGE
	while ts < T_END:
		at(ts, scour)
		ts += SCOUR_EVERY
	at(T_END, _lift)
	if _staged():
		_telegraph()


## Whether there is a stage to play on: a headless test hands an effect only the field and the ground.
func _staged() -> bool:
	return ctx.impact != null and ctx.shake != null and is_inside_tree()


## Everything under the pillar: the living die and the standing fall. Returns how many people it took.
func scour() -> int:
	var took := 0
	for e in ctx.field.in_radius(origin, RADIUS):
		var p := e as Person
		if p != null and p.inside:
			continue  # the building round them comes down first, and puts them out
		if ctx.field.kill(e, &"solaris", origin):
			took += 1
	burned += took
	ctx.env.damage_radius(origin, RADIUS, 99999.0, &"solaris")
	if _staged():
		ctx.shake.add_trauma(0.075)
	return took


## The pillar lands, and the ground under it opens.
func _ignite() -> void:
	pit = SolarisPit.new().setup(ctx.field, origin, RADIUS, ctx.rng.randf() * 40.0)
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
	var rings := FxParts.rings(self, origin, RADIUS, GOLD, 3, 22.0)
	rings.tween_param("reveal", 0.0, 1.0, 0.5, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	rings.tween_param("alpha", 1.0, 0.0, 0.3, T_CHARGE)
	rings.life = T_CHARGE + 0.32
	# The needle: a thread of light down from the sky, thickening.
	var needle := FxParts.beam(self, ctx.overhead, sp, 6.0, COLUMN_H, SOLAR)
	needle.set_param("band_speed", 18.0)
	needle.tween_param("intensity", 0.12, 0.8, T_CHARGE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	needle.life = T_CHARGE
	var warm := FxParts.ground_light(self, origin, RADIUS * 1.8, SUN, 0.0)
	warm.tween_param("intensity", 0.0, 0.9, T_CHARGE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	warm.life = T_CHARGE + 0.05
	# Motes drawn in off the ground toward the spot.
	var motes := FxParts.particles(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, SOLAR_LIFE)
	motes.gravity = -50.0
	motes.drag = 0.4
	motes.burst(46, {"radius": FxParts.particle_radius(RADIUS * 1.5), "speed": Vector2(40, 90),
		"dir": PixelParticles.Dir.INWARD, "alt": Vector2(0, 8), "alt_speed": Vector2(6, 30), "life": Vector2(0.6, 1.1),
		"size": Vector2(1, 2)})


func _strike() -> void:
	var sp := Iso.ground_to_screen(origin)
	var semi := Iso.radius_to_screen(RADIUS)
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

	_light = FxParts.ground_light(self, origin, RADIUS * 3.4, SUN, 1.9)
	_light.set_param("flicker", 1.0)
	_rays = FxParts.ground_rays(self, origin, RADIUS * 3.2, SUN_HOT, 72.0)
	_rays.tween_param("reach", 0.2, 1.0, 0.3, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	_rays.tween_param("intensity", 1.4, 0.55, 0.7)

	var ring := FxParts.shockwave(self, origin, RADIUS * 2.6, SOLAR)
	ring.set_param("thickness", 0.14)
	ring.tween_param("progress", 0.05, 1.0, 0.45, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.25, 0.25)
	ring.life = 0.55
	var refract := FxParts.refract_ring(self, origin, RADIUS * 2.8, SUN)
	refract.set_param("strength", 8.0)
	refract.tween_param("progress", 0.1, 1.0, 0.5, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	refract.life = 0.52
	var haze := FxParts.heat_haze(self, sp, FxParts.particle_radius(RADIUS * 1.7), 2.6)
	haze.tween_param("strength", 2.6, 0.0, 1.6, BEAM_TIME)
	haze.life = BEAM_TIME + 1.65

	# What the light lifts off the ground and burns: flecks streaming up the pillar, sparks thrown from its foot.
	var updraft := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.STREAK, ASH_LIFE, 110.0, BEAM_TIME, {
		"radius": FxParts.particle_radius(RADIUS * 0.9), "speed": Vector2(0, 10), "alt": Vector2(0, 30),
		"alt_speed": Vector2(150, 380), "life": Vector2(0.35, 0.8), "size": Vector2(1, 3)})
	updraft.gravity = -260.0
	updraft.streak_len = 0.05
	updraft.z_index = 7
	var sparks := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.STREAK, SOLAR_LIFE, 80.0, BEAM_TIME, {
		"radius": FxParts.particle_radius(RADIUS), "speed": Vector2(90, 280), "dir": PixelParticles.Dir.OUTWARD,
		"alt": Vector2(0, 8), "alt_speed": Vector2(40, 220), "life": Vector2(0.3, 0.7), "size": Vector2(1, 2)})
	sparks.gravity = 320.0
	sparks.drag = 1.2
	sparks.z_index = 7
	FxParts.debris(self, sp, 34, FxParts.particle_radius(RADIUS * 0.8), Vector2(80, 260), FxParts.HOT_ROCK,
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
	var ring := FxParts.shockwave(self, origin, RADIUS * 1.8, FxParts.DUST_RING)
	ring.set_param("thickness", 0.2)
	ring.tween_param("progress", 0.3, 1.0, 0.6, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.4, 0.25)
	ring.life = 0.7
	# The pit breathes out: smoke lit from below, and embers rising off the molten rim.
	FxParts.smoke(self, sp, FxParts.particle_radius(RADIUS * 0.8), 30.0, AFTER - 0.6, Vector2(30, 80), Vector2(3, 7),
		Vector2(1.2, 2.2), Color("ff7a2a"))
	var embers := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 40.0,
		AFTER - 0.4, {"radius": FxParts.particle_radius(RADIUS), "speed": Vector2(0, 12), "alt": Vector2(0, 6),
		"alt_speed": Vector2(14, 50), "life": Vector2(0.6, 1.4), "size": Vector2(1, 1)})
	embers.gravity = -20.0


## The pillar's light breathes while it stands, and dies with it.
func _fx_process(_delta: float) -> void:
	if not is_instance_valid(_light):
		return
	var k := curve([[T_CHARGE, 0.0], [T_CHARGE + 0.15, 1.0], [T_END, 1.0], [T_END + 0.5, 0.35], [duration, 0.0]])
	var breath := 0.92 + 0.08 * sin(t * 23.0) * sin(t * 7.1)
	_light.set_param("intensity", 1.9 * k * breath)
	var standing := curve([[T_CHARGE, 0.0], [T_CHARGE + 0.2, 1.0], [T_END, 1.0], [T_END + 0.45, 0.0]])
	if is_instance_valid(_halo):
		_halo.set_param("intensity", 0.55 * standing * breath)
	if is_instance_valid(_glow):
		_glow.set_param("intensity", 1.2 * standing * breath)
