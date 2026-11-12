class_name GroundFireSprite
extends Node2D
## The look of one patch of burning ground (Dragonfire Parade): two flames, embers and a thin smoke in the y-sorted world, a
## scorch decal and a flickering light pool on the ground. It is made by the effect for each patch and is NOT tracked by it, so
## it outlives the cast (group `fx_lasting`, as SolarisPit and Earthshatter's Fissure; Battlefield.clear_effects() frees it).
## It follows the patch's strength; when the patch is out the flames shrink, the scorch fades and the sprite frees itself.
## With no town to keep the patch (the sandbox, staged tests) the sprite steps it too: it burns down and burns who stays in it.
## Everything it draws is seeded from the patch's id: it never draws the god's random numbers.

## What an effect leaves behind for good.
const GROUP := &"fx_lasting"
const FIRE_LIGHT := Color(1.0, 0.5, 0.18)
## Seconds the flames take to rise at laying, to shrink once the patch is out, and the scorch takes to fade after that.
const RISE := 0.25
const FLAMES_OUT := 0.6
const SCORCH_FADE := 6.0
## The light pool's radius and top intensity, the scorch's radius (ground units).
const LIGHT_RADIUS := 1.2
const LIGHT_INTENSITY := 0.7
const DECAL_RADIUS := 1.0
## Screen pixels (at zoom 1) round the patch's point within which it counts as on screen: more than its flames, embers and
## smoke ever reach (about 60 across and 100 up).
const CULL_MARGIN := 128.0
## Embers a second at full strength.
const EMBER_RATE := 5.0
const SMOKE_RATE := 1.0
## Particles in the grey puff of a patch that was beaten out.
const PUFF := 8

var patch: GroundFire
var ctx: FxContext
var flames: Array[FlameSprite] = []
var embers: PixelParticles
var smoke: PixelParticles
## In ctx.ground: the scorch decal and the light.
var ground: Node2D

var _decal: QuadFx
var _light: QuadFx
var _rng := RandomNumberGenerator.new()
var _age := 0.0
var _harm_in := 0.0
## The no-town path's heat entries ({DummyEnemy: {"heat", "in"}}).
var _heat := {}
## Seconds since the patch went out; negative while it burns.
var _out_age := -1.0
var _out_flame := 0.0
var _out_light := 0.0
var _voice: Node
var _strip: Array = []


func setup(p: GroundFire, c: FxContext) -> GroundFireSprite:
	patch = p
	ctx = c
	_rng.seed = p.id * 7919 + 13
	add_to_group(GROUP)
	position = Iso.ground_to_screen(p.at).round()
	ctx.world.add_child(self)
	for i in 2:
		var flame := FlameSprite.new()
		flame.size = _rng.randf_range(0.8, 1.2)
		flame.setup(_rng, _rng.randi_range(3, 5))
		flame.position = Vector2(-5.0 + 10.0 * i, 1.0 - 2.0 * i)
		add_child(flame)
		flames.append(flame)
	embers = PixelParticles.new()
	embers.rng.seed = p.id * 7919 + 13
	embers.shape = PixelParticles.Shape.SQUARE
	embers.ramp = PackedColorArray(FxParts.EMBER_LIFE)
	embers.position = Vector2(0, -14)
	embers.auto_free = false
	embers.rate = EMBER_RATE
	embers.spec = {"radius": 8.0, "alt_speed": Vector2(20, 50), "life": Vector2(0.4, 0.9), "size": Vector2(1, 1)}
	embers.emitting = true
	add_child(embers)
	smoke = PixelParticles.new()
	smoke.rng.seed = p.id * 7919 + 14
	smoke.shape = PixelParticles.Shape.PUFF
	smoke.ramp = PackedColorArray(FxParts.SMOKE_LIFE)
	smoke.position = Vector2(0, -4)
	smoke.auto_free = false
	smoke.drag = 0.4
	smoke.rate = SMOKE_RATE
	smoke.spec = {"radius": 6.0, "speed": Vector2(4, 18), "alt": Vector2(0, 8), "alt_speed": Vector2(14, 34),
		"life": Vector2(1.2, 2.2), "size": Vector2(3, 5), "size_end_mul": 1.8}
	smoke.emitting = true
	add_child(smoke)
	# The ground node: the decal under the light, in the ground layer (children authored in ground units).
	ground = Node2D.new()
	ctx.ground.add_child(ground)
	_decal = QuadFx.new().setup(FxParts.SH_DECAL, Vector2.ONE * DECAL_RADIUS * 2.0)
	_decal.position = p.at
	_decal.z_index = 1
	_decal.set_param("edge_color", Color("ff6a1a"))
	_decal.set_param("edge_hot", Color("ffd27a"))
	_decal.set_param("char_color", Color(0.12, 0.05, 0.03, 0.9))
	_decal.set_param("seed", float(p.id % 97) * 1.37)
	_decal.set_param("heat", p.strength)
	ground.add_child(_decal)
	_light = QuadFx.new().setup(FxParts.SH_LIGHT, Vector2.ONE * LIGHT_RADIUS * 2.0)
	_light.position = p.at
	_light.z_index = 6
	_light.set_param("color", FIRE_LIGHT)
	_light.set_param("intensity", 0.0)
	_light.set_param("flicker", 1.0)
	ground.add_child(_light)
	if ctx.lights != null:
		ctx.lights.register_quad_at(_light, p.at, LIGHT_RADIUS * 1.15, FIRE_LIGHT)
	return self


## The strip's burning loop: kept here, and faded (1.0 s) once every patch of `strip` is out. This sprite lets it go if it
## leaves first.
func hold_voice(voice: Node, strip: Array) -> void:
	_voice = voice
	_strip = strip


func _process(delta: float) -> void:
	advance(delta)
	_cull()


## Off screen, its flames, embers and smoke are hidden, so nobody draws what nobody sees (they still run, so they are
## where they would be the moment it comes back into view, and showing a node redraws it).
func _cull() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var xf := get_global_transform_with_canvas()
	var m := CULL_MARGIN * absf(xf.get_scale().x)
	var size := vp.get_visible_rect().size
	var o := xf.origin
	visible = o.x > -m and o.y > -m and o.x < size.x + m and o.y < size.y + m


## Drive it by hand (tests) or from _process.
func advance(delta: float) -> void:
	if is_queued_for_deletion():
		return
	_age += delta
	if not patch.owned and not patch.out:
		patch.burn_down(delta, 0)
		_harm_in += delta
		while _harm_in >= GroundFire.HARM_TICK - 1e-6 and ctx.field != null:
			_harm_in -= GroundFire.HARM_TICK
			GroundFire.scorch(ctx.field, [patch], _heat, GroundFire.HARM_TICK)
	if patch.out and _out_age < 0.0:
		_go_out()
	if _out_age >= 0.0:
		_out_age += delta
		_fade(_out_age)
	else:
		_burn()
	_check_voice()


## Alive: the flames, the light and the scorch's heat follow the patch's strength.
func _burn() -> void:
	var rise := smoothstep(0.0, 1.0, clampf(_age / RISE, 0.0, 1.0))
	var s := patch.strength
	for f in flames:
		f.strength = sqrt(s) * rise
	_light.set_param("intensity", LIGHT_INTENSITY * s * rise)
	_decal.set_param("heat", s)
	embers.rate = EMBER_RATE * s


## The patch is out: the emitters stop, a beaten fire gives one grey puff, and the flames' last size is kept to shrink from.
func _go_out() -> void:
	_out_age = 0.0
	_out_flame = flames[0].strength if not flames.is_empty() else 0.0
	_out_light = LIGHT_INTENSITY * clampf(patch.strength, 0.0, 1.0)
	embers.emitting = false
	smoke.emitting = false
	_decal.set_param("heat", 0.0)
	if patch.beaten:
		var puff := PixelParticles.new()
		puff.rng.seed = patch.id * 7919 + 15
		puff.shape = PixelParticles.Shape.PUFF
		puff.ramp = PackedColorArray(FxParts.SMOKE_LIFE)
		puff.position = Vector2(0, -6)
		puff.drag = 0.5
		add_child(puff)
		puff.burst(PUFF, {"radius": 7.0, "speed": Vector2(4, 16), "alt": Vector2(0, 8), "alt_speed": Vector2(20, 50),
			"life": Vector2(0.8, 1.6), "size": Vector2(3, 6), "size_end_mul": 1.8})


## Out: the flames shrink over FLAMES_OUT, then the scorch fades over SCORCH_FADE, then the sprite and its ground node go.
func _fade(age: float) -> void:
	var k := clampf(age / FLAMES_OUT, 0.0, 1.0)
	for f in flames:
		f.strength = _out_flame * (1.0 - k)
	_light.set_param("intensity", _out_light * (1.0 - k))
	var scorch_age := age - FLAMES_OUT
	_decal.set_param("fade", 1.0 - clampf(scorch_age / SCORCH_FADE, 0.0, 1.0))
	if scorch_age >= SCORCH_FADE:
		_release_voice()
		if is_instance_valid(ground):
			ground.queue_free()
		queue_free()


func _check_voice() -> void:
	if _voice == null:
		return
	for q: GroundFire in _strip:
		if not q.out:
			return
	_release_voice()


func _release_voice() -> void:
	var v := _voice
	_voice = null
	if v != null and is_instance_valid(v) and ctx != null and is_instance_valid(ctx.sfx):
		ctx.fade_out(v, 1.0)


func _exit_tree() -> void:
	_release_voice()
	if is_instance_valid(ground) and not ground.is_queued_for_deletion():
		ground.queue_free()
