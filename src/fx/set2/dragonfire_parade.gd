extends FxTimeline
## Dragonfire Parade: draconic sigil -> the earth ruptures in lava and obsidian -> a colossal fire dragon rises ->
## it sweeps its head left to right breathing a devastating cone of flame -> it sinks away, leaving scorched
## earth and fires that keep burning.

const CONE_RADIUS := 11.0
## Narrow sweep matching the small head turn in the roar animation.
const SWEEP_ARC := 1.0
const T_ERUPT := 1.2
const T_RISE := 2.2
const RISE_TIME := 1.2
const T_INHALE := 3.6
const T_BREATH := 4.1
const BREATH_TIME := 2.4
const T_SINK := T_BREATH + BREATH_TIME + 0.4
const BEAM_HALF_ANGLE := 0.14
const FIRE_LIGHT := Color(1.0, 0.5, 0.18)
const SH_CONE := preload("res://shaders/fire_cone.gdshader")
const SH_STREAM := preload("res://shaders/flame_stream.gdshader")
const JET_REACH := 0.55
## Level 5, Second Breath: seconds between the first breath ending and the second beginning.
const SECOND_GAP := 2.0
## The dragon sprite faces screen down-right (south-east); the breath is locked to that facing.
const FACING := Vector2(1, 0)
## Ground fire: patches laid a second of breath (8 over the 2.4 s breath), at what distance from the dragon they lie, and the
## golden-ratio step that spreads a strip's patches along it without an rng.
const PATCH_RATE := 8.0 / BREATH_TIME
const PATCH_NEAR := 2.0
const PATCH_FAR := 9.5
const GOLDEN := 0.618034


var _center_px := Vector2.ZERO
var _dir := Vector2(1, 0)
var _start_angle := 0.0
var _sigil: SigilRune
var _dragon: DragonSprite
var _cone: QuadFx
var _stream: PixelParticles
var _jet: QuadFx
var _breath_voice: Node
var _burn_voice: Node
var _sweep := 0.0
var _breathing := false
## Second Breath (level 5): the breath on its way back (right to left), when the current breath began, and how many there have been.
var _back := false
var _breath_start := T_BREATH
var breaths := 0
## Ground fire: one strip (the patches of one breath) each, how many patches the dragon has laid in all, how many this breath, and how many
## this cast's breath lays (set in _build()).
var strips: Array = []
var patches_laid := 0
var _laid := 0
var _lv_patches := 0
## This cast's breath time and sweep, and when the dragon sinks: the ability level's (PowerBook.stat()), the consts at level 1.
var lv_breath_time := BREATH_TIME
var lv_sweep_arc := SWEEP_ARC
var lv_t_sink := T_SINK


func _build() -> void:
	lv_breath_time = float(PowerBook.stat(extra, "dragon", "BREATH_TIME", BREATH_TIME))
	lv_sweep_arc = float(PowerBook.stat(extra, "dragon", "SWEEP_ARC", SWEEP_ARC))
	lv_t_sink = T_BREATH + lv_breath_time + 0.4
	_lv_patches = roundi(PATCH_RATE * lv_breath_time)
	var second := PowerBook.twist_at(extra, "dragon")
	if second:
		lv_t_sink = T_BREATH + 2.0 * lv_breath_time + SECOND_GAP + 0.4
	duration = 11.5 + (lv_t_sink - T_SINK)
	# Standing pieces sort above buildings, under the dragon.
	stand_layer()
	_center_px = Iso.ground_to_screen(origin)
	_dir = FACING
	# Arc centered on the dragon's facing, slightly biased to its right so the jet never crosses its body.
	_start_angle = _dir.angle() - lv_sweep_arc * 0.5 - deg_to_rad(8.0)
	_sigil = Set2Parts.sigil(self, origin, 2.4, Color("ff5a2a"), "dragon")
	# Sweep arc indicator showing the coming cone.
	var arc := FxParts.quad(self, SH_CONE, Vector2.ONE * CONE_RADIUS * 2.0, ctx.ground)
	arc.position = origin
	arc.z_index = 8
	arc.set_param("start", _start_angle)
	arc.set_param("sweep", lv_sweep_arc)
	arc.set_param("heat", 0.35)
	arc.set_param("fade", 0.0)
	arc.tween_param("fade", 0.0, 0.35, 0.8)
	arc.tween_param("fade", 0.35, 0.0, 0.4, T_BREATH - 0.4)
	arc.life = T_BREATH + 0.05
	var glow := FxParts.ground_light(self, origin, 3.0, FIRE_LIGHT, 0.0)
	glow.tween_param("intensity", 0.0, 0.8, T_ERUPT)
	ctx.impact.dim(0.5, 1.0)
	ctx.play(&"dr_rumble", origin)
	at(T_ERUPT, _erupt)
	at(T_RISE, _rise)
	at(T_INHALE, _inhale)
	at(T_BREATH, _breathe)
	if second:
		at(T_BREATH + lv_breath_time + SECOND_GAP - (T_BREATH - T_INHALE), _inhale)
		at(T_BREATH + lv_breath_time + SECOND_GAP, _breathe_back)
	at(lv_t_sink, _sink)


func _erupt() -> void:
	ctx.play(&"dr_erupt", origin)
	ctx.shake.add_trauma(0.7)
	create_tween().tween_property(_sigil, "alpha", 0.0, 0.6)
	var fissure := FxParts.decal(self, origin, 2.6, Color("ff6a1a"), Color("ffd27a"), Color(0.12, 0.05, 0.03, 0.9))
	fissure.z_index = 2
	fissure.tween_param("heat", 1.0, 0.5, 4.0)
	fissure.tween_param("fade", 1.0, 0.0, 1.2, duration - t - 1.3)
	# Obsidian shards and lava bursting out of the ground in a ring.
	for i in 16:
		var a := TAU * i / 16.0 + ctx.rng.randf_range(-0.15, 0.15)
		var g := origin + Vector2.RIGHT.rotated(a) * ctx.rng.randf_range(0.7, 1.9)
		var s := IceSpike.new()
		s.palette = 2
		s.ground_pos = g
		s.position = Iso.ground_to_screen(g).round()
		s.height = ctx.rng.randf_range(22.0, 44.0)
		s.width = ctx.rng.randf_range(6.0, 10.0)
		s.angle = clampf((Iso.ground_to_screen(g) - _center_px).x * 0.012, -0.6, 0.6)
		s.seed = ctx.rng.randf() * 100.0
		s.glow = 1.0
		s.lights = ctx.lights
		track(s, stand_layer())
		var tw := s.create_tween()
		tw.tween_interval(i * 0.02)
		tw.tween_property(s, "grow", 1.0, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(lv_t_sink - T_ERUPT + ctx.rng.randf_range(0.0, 0.6))
		tw.tween_property(s, "shatter", 1.0, 0.6)
		tw.tween_interval(duration - lv_t_sink - 2.0)
		tw.tween_property(s, "fade", 0.0, 0.8)
	var lava := FxParts.particles(self, ctx.overhead, _center_px, PixelParticles.Shape.SQUARE, FxParts.FIRE_LIFE)
	lava.gravity = 360.0
	lava.drag = 0.5
	lava.burst(120, {"radius": 30.0, "speed": Vector2(20, 120), "alt_speed": Vector2(100, 300), "life": Vector2(0.6, 1.2),
		"size": Vector2(1, 3)})
	FxParts.debris(self, _center_px, 40, 30.0, Vector2(50, 220), Set2Parts.OBSIDIAN, Vector2(2, 5), true)
	FxParts.smoke(self, _center_px, 40.0, 30.0, 0.8, Vector2(20, 60), Vector2(5, 8), Vector2(1.2, 2.0), Color("ff5a1a"))
	for e in ctx.field.in_radius(origin, 1.9):
		ctx.field.kill(e, &"cinder", origin)
	ctx.env.damage_radius(origin, 1.9, 99999.0, &"cinder")


func _rise() -> void:
	ctx.play(&"dr_roar", origin)
	ctx.impact.impact_frame(0.05, ctx.impact.focus_of(_center_px + Vector2(0, -80)), Color(1.0, 0.9, 0.6), Color(0.15, 0.02, 0.0))
	ctx.impact.hitstop(0.06)
	ctx.impact.aberration(3.0, 0.4)
	ctx.shake.add_trauma(0.9)
	_dragon = DragonSprite.new()
	_dragon.position = _center_px
	track(_dragon, ctx.overhead_back)
	create_tween().tween_property(_dragon, "rise", 1.0, RISE_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var light := FxParts.ground_light(self, origin, 4.8, FIRE_LIGHT)
	light.set_param("flicker", 1.0)
	light.tween_param("intensity", 0.0, 1.1, RISE_TIME)
	light.tween_param("intensity", 1.1, 0.0, 1.2, lv_t_sink - t)
	var bloom := FxParts.bloom(self, _center_px + Vector2(0, -90), 120.0, FIRE_LIGHT, 0.0, 1.2)
	bloom.tween_param("intensity", 0.0, 0.75, RISE_TIME)
	bloom.tween_param("intensity", 0.75, 0.0, 1.0, lv_t_sink - t)
	bloom.life = lv_t_sink - t + 1.1
	var haze := FxParts.heat_haze(self, _center_px + Vector2(0, -60), 120.0, 2.0)
	haze.tween_param("strength", 2.0, 0.0, 1.0, lv_t_sink - t)
	haze.life = lv_t_sink - t + 1.1
	FxParts.emitter(self, ctx.overhead, _center_px + Vector2(0, -60), PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 40.0,
		lv_t_sink - t, {
			"radius": 60.0, "alt": Vector2(0, 80), "alt_speed": Vector2(20, 60), "speed": Vector2(0, 14),
			"life": Vector2(0.6, 1.3), "size": Vector2(1, 2),
		})
	for e in ctx.field.in_radius(origin, 2.4):
		ctx.field.kill(e, &"fire", origin)


func _inhale() -> void:
	ctx.play(&"dr_inhale", origin)
	# Rears back and lowers its head (breath clip); a flash gathers where the fire will leave the mouth.
	_dragon.breathe(T_BREATH - T_INHALE, lv_breath_time, 0.4)
	var flash := FxParts.bloom(self, _center_px + _dragon.mouth_at(DragonSprite.FIRE_SEQ[0]), 20.0,
		Color(1.0, 0.85, 0.5), 0.0)
	flash.tween_param("intensity", 0.0, 1.4, T_BREATH - T_INHALE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	flash.life = T_BREATH - T_INHALE + 0.05


## The second breath: the same set-up, sweeping the arc back from the dragon's right to its left.
func _breathe_back() -> void:
	_back = true
	_laid = 0
	_breathe(T_BREATH + lv_breath_time + SECOND_GAP)


## A breath that begins at time `start` (the first at T_BREATH).
func _breathe(start := T_BREATH) -> void:
	_breath_start = start
	breaths += 1
	strips.append([])
	_laid = 0
	ctx.play(&"dr_ignite", origin)
	_breath_voice = ctx.play(&"dr_breath", origin, -1.0)
	ctx.impact.dim(0.3, 1.5)
	ctx.impact.aberration(2.5, 0.3)
	ctx.shake.add_trauma(0.5)
	_breathing = true
	_cone = QuadFx.new().setup(SH_CONE, Vector2.ONE * CONE_RADIUS * 2.0)
	_cone.position = origin
	_cone.z_index = 7
	_cone.set_param("start", _start_angle if _back else _start_angle + lv_sweep_arc)
	_cone.set_param("reverse", 0.0 if _back else 1.0)
	_cone.set_param("sweep", 0.0)
	_cone.set_param("seed", ctx.rng.randf() * 20.0)
	track(_cone, ctx.ground)
	_jet = QuadFx.new().setup(SH_STREAM, Vector2(100, 72), Vector2(0.0, 0.5))
	_jet.set_param("seed", ctx.rng.randf() * 100.0)
	_jet.set_param("width_px", 72.0)
	# Same layer as the dragon so the jet can pass behind it when breathing away from the camera.
	track(_jet, ctx.overhead_back)
	_jet.tween_param("fade", 0.0, 1.0, 0.12)
	_stream = FxParts.particles(self, ctx.overhead, Vector2.ZERO, PixelParticles.Shape.PUFF, FxParts.FIRE_LIFE)
	_stream.auto_free = false
	_stream.drag = 0.6
	ctx.lights.register_quad(_cone, origin, 3.2, FIRE_LIGHT,
		func(): return origin + Vector2.RIGHT.rotated(_beam_angle()) * CONE_RADIUS * 0.6)
	_cone.set_param("intensity", 0.7)


## Where the beam points: from the arc's far end down to its start, and on the way back up again.
func _beam_angle() -> float:
	if _back:
		return _start_angle + _sweep
	return _start_angle + lv_sweep_arc - _sweep


func _fx_process(delta: float) -> void:
	if not _breathing:
		return
	var k := clampf((t - _breath_start) / lv_breath_time, 0.0, 1.0)
	_sweep = lv_sweep_arc * (k * k * (3.0 - 2.0 * k) * 0.5 + k * 0.5)
	# Sweep from the dragon's left (screen lower-left) to its right (screen right), following the head.
	var beam_angle := _beam_angle()
	_cone.set_param("start", _start_angle if _back else beam_angle)
	_cone.set_param("sweep", _sweep)
	var beam_dir := Vector2.RIGHT.rotated(beam_angle)
	var mouth := _center_px + _dragon.mouth_pos()
	# Thick flame jet from the mouth to where it hits the ground, then puffs rolling on along the cone.
	var hit := Iso.ground_to_screen(origin + beam_dir * CONE_RADIUS * JET_REACH)
	_jet.position = mouth
	_jet.rotation = (hit - mouth).angle()
	# The locked sweep always aims in front of the dragon, so the jet always draws over the sprite.
	_jet.z_index = 1
	_jet.size = Vector2(mouth.distance_to(hit) + 12.0, 72.0)
	_jet.set_param("length_px", _jet.size.x)
	_jet.queue_redraw()
	for i in int(ceil(70.0 * delta)):
		var along := ctx.rng.randf_range(JET_REACH, 1.0)
		var target := Iso.ground_to_screen(origin + beam_dir.rotated(ctx.rng.randf_range(-BEAM_HALF_ANGLE, BEAM_HALF_ANGLE)) * CONE_RADIUS * along)
		var life := ctx.rng.randf_range(0.25, 0.45)
		_stream.burst(1, {"offset": hit, "velocity": (target - hit) / life, "life": Vector2(life, life),
			"size": Vector2(3, 5), "size_end_mul": 1.6})
	# Enemies and buildings inside the beam band burn.
	for e in ctx.field.in_radius(origin, CONE_RADIUS):
		var rel := e.ground_pos - origin
		if absf(angle_difference(rel.angle(), beam_angle)) < BEAM_HALF_ANGLE and rel.length() > 0.8:
			ctx.field.kill(e, &"fire", origin)
	for s in ctx.env.structures():
		if is_instance_valid(s) and not s.destroyed:
			var rel := s.center() - origin
			if rel.length() < CONE_RADIUS and absf(angle_difference(rel.angle(), beam_angle)) < BEAM_HALF_ANGLE:
				s.damage(260.0 * delta, origin, &"fire")
	ctx.shake.add_trauma(0.4 * delta)
	# Ground fire: the patches of this breath, laid as the beam passes their share of the sweep.
	while _laid < _lv_patches and k >= (_laid + 0.5) / _lv_patches:
		_lay(beam_angle, _laid)
		_laid += 1
	if k >= 1.0:
		_breathing = false
		ctx.fade_out(_breath_voice, 0.4)
		_stream.auto_free = true
		_jet.tween_param("fade", 1.0, 0.0, 0.25)
		_jet.life = _jet.age + 0.3
		_cone.tween_param("heat", 1.0, 0.45, 1.5)
		_cone.tween_param("intensity", 0.7, 0.0, 1.2)
		_cone.tween_param("fade", 1.0, 0.0, 2.0, duration - t - 2.1)


## Lays patch `i` of this breath's strip on the beam at `angle`: no rng, the distance steps by the golden ratio from the strip's phase
## (the way back starts elsewhere). Outside the field or in a river it is skipped (the index still counts).
func _lay(angle: float, i: int) -> void:
	var phase := 0.0 if _back else 0.5
	var d := PATCH_NEAR + (PATCH_FAR - PATCH_NEAR) * fposmod(phase + i * GOLDEN, 1.0)
	var g := origin + Vector2.RIGHT.rotated(angle) * d
	if not ctx.field.bounds.has_point(g):
		return
	if ctx.crowd != null:
		for r: Rect2 in City.current().rivers():
			if r.has_point(g):
				return
	var patch: GroundFire = ctx.crowd.fires.lay(g) if ctx.crowd != null else GroundFire.new(g, GroundFire.RADIUS, 1000 + patches_laid)
	var sprite := GroundFireSprite.new().setup(patch, ctx)
	var strip: Array = strips.back()
	if strip.is_empty():
		var voice := ctx.play(&"orb_embers", g, -6.0)
		if voice != null:
			sprite.hold_voice(voice, strip)
	strip.append(patch)
	patches_laid += 1


func _sink() -> void:
	ctx.play(&"dr_sink", origin)
	_burn_voice = ctx.play(&"laser_fire", origin, -6.0)
	var tw := create_tween()
	tw.tween_property(_dragon, "rise", 0.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_dragon, "fade", 0.0, 1.2).set_delay(0.4)
	FxParts.emitter(self, ctx.overhead, _center_px + Vector2(0, -70), PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 120.0, 1.2, {
		"radius": 50.0, "alt": Vector2(0, 90), "alt_speed": Vector2(30, 90), "speed": Vector2(10, 40),
		"life": Vector2(0.6, 1.4), "size": Vector2(1, 3),
	})
	FxParts.smoke(self, _center_px, 30.0, 20.0, 1.5, Vector2(30, 80), Vector2(5, 9), Vector2(1.6, 2.6), Color("ff5a1a"))
	at(duration - 1.3, func():
		ctx.fade_out(_burn_voice, 1.2)
		ctx.impact.dim(0.0, 0.6))
