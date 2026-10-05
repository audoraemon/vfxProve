class_name SolarisPit
extends Node2D
## The hole the Light of Solaris leaves: a pit of the beam's radius, burned straight down, that stays for the rest of
## the mission. The ground round it stays walkable and nobody knows to avoid it: whoever steps in falls and is gone
## (damage kind `pit`). It glows molten at first and cools to bare rock. It is drawn in the world layer, sorted at its
## far rim (under the iso basis, so its circle projects to the ground's ellipse): whatever stands behind it is under
## it, and whoever stands in front of it -- or is falling into it -- is drawn over it. The rubble of what stood over
## it is hidden (LightOfSolaris._lift()). Battlefield.clear_effects() frees it by its group.

## What an effect leaves behind for good.
const GROUP := &"fx_lasting"
## Rubble that stays even over the hole: a gate or the bridge may yet be rebuilt.
const KEEP_RUBBLE := [&"gate", &"bridge"]
const SHADER := preload("res://shaders/solaris_pit.gdshader")
## The hole's share of the drawn quad; the rest is the scorched apron (the shader's `hole`).
const HOLE_SHARE := 0.74
## Someone falls once this far inside the rim: a step past the lip, not a toe on it.
const FALL_SHARE := 0.9
## How often it looks for someone to take.
const CHECK_EVERY := 0.1
## Seconds the opening takes; and, once the beam has lifted (armed), the rock stays molten and then takes to cool.
const OPEN := 0.4
const HOT := 0.8
const COOL := 7.0

var center := Vector2.ZERO
var radius := 1.0
## Off while the beam still stands on it: the beam takes them first.
var armed := false
## How many have fallen in.
var fallen := 0

var _field: EnemyField
var _quad: QuadFx
var _age := 0.0
## Seconds since the beam lifted.
var _open_air := 0.0
var _check_in := 0.0
var _rng := RandomNumberGenerator.new()


func setup(field: EnemyField, at: Vector2, r: float, seed_value: float) -> SolarisPit:
	_field = field
	center = at
	radius = r
	add_to_group(GROUP)
	_rng.seed = int(seed_value * 1000.0)
	# Sorted by its far rim: the node sits there, and the quad hangs the hole's radius below it (screen-down is the
	# ground's (1, 1) way).
	var far_rim := r * FxParts.PX_PER_UNIT_MINOR
	transform = Transform2D(Iso.BASIS.x, Iso.BASIS.y, Iso.ground_to_screen(at) - Vector2(0, far_rim))
	# The shader keeps its own time; this node drives the opening and the cooling.
	_quad = QuadFx.new().setup(SHADER, Vector2.ONE * r * 2.0 / HOLE_SHARE).run_on_shader_clock()
	_quad.set_param("hole", HOLE_SHARE)
	_quad.set_param("seed", seed_value)
	_quad.set_param("open", 0.0)
	_quad.set_param("heat", 1.0)
	_quad.position = Vector2.ONE * (far_rim / 32.0)
	add_child(_quad)
	return self


func _process(delta: float) -> void:
	advance(delta)


## Drive it by hand (tests) or from _process.
func advance(delta: float) -> void:
	_age += delta
	if armed:
		_open_air += delta
	if _open_air <= HOT + COOL + CHECK_EVERY:
		_quad.set_param("open", clampf(_age / OPEN, 0.0, 1.0))
		_quad.set_param("heat", clampf(1.0 - (_open_air - HOT) / COOL, 0.0, 1.0))
	_check_in -= delta
	if armed and _check_in <= 0.0:
		_check_in = CHECK_EVERY
		swallow()


## The rubble of whatever stood over the hole -- the Citadel's parts too -- is hidden, now and whenever something
## else comes down over it later.
func hide_rubble(env: EnvironmentField) -> void:
	for s in env.structures():
		if is_instance_valid(s) and s.destroyed:
			_on_structure_destroyed(s, &"")
	if not env.structure_destroyed.is_connected(_on_structure_destroyed):
		env.structure_destroyed.connect(_on_structure_destroyed)


func _on_structure_destroyed(s: Structure, _kind: StringName) -> void:
	if is_instance_valid(s) and not KEEP_RUBBLE.has(s.role) and s.distance_to(center) <= radius:
		s.visible = false


## Whether `g` is over the hole.
func over(g: Vector2) -> bool:
	return g.distance_to(center) <= radius * FALL_SHARE


## Everyone standing over the hole falls; returns how many did.
func swallow() -> int:
	if not is_instance_valid(_field):
		return 0
	var took := 0
	for e in _field.in_radius(center, radius * FALL_SHARE):
		var p := e as Person
		if p != null and p.inside:
			continue
		var at := e.ground_pos
		if _field.kill(e, &"pit", center):
			took += 1
			_crumble(at)
	fallen += took
	return took


## The lip gives way under someone: a puff of dust where they stood and a few chips of rock tumbling in after them.
## Put beside the pit in the world layer, so it sorts over the hole like the one falling.
func _crumble(at: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var dust := PixelParticles.new()
	dust.rng.seed = _rng.randi()
	dust.shape = PixelParticles.Shape.PUFF
	dust.ramp = PackedColorArray(FxParts.DUST_LIFE)
	dust.position = Iso.ground_to_screen(at) + Vector2(0, -1)  # a pixel up: it sorts behind the one falling
	dust.drag = 1.6
	dust.gravity = -6.0
	parent.add_child(dust)
	dust.burst(6, {"radius": 7.0, "speed": Vector2(8, 24), "dir": PixelParticles.Dir.OUTWARD, "alt": Vector2(0, 3),
		"alt_speed": Vector2(3, 12), "life": Vector2(0.3, 0.6), "size": Vector2(1, 3), "size_end_mul": 1.5})
	var chips := PixelParticles.new()
	chips.rng.seed = _rng.randi()
	chips.shape = PixelParticles.Shape.CHUNK
	chips.ramp = PackedColorArray(FxParts.ROCK)
	chips.position = Iso.ground_to_screen(at) + Vector2(0, -1)
	chips.gravity = -520.0  # into the hole: the chips drop and keep dropping, with no ground to land on
	parent.add_child(chips)
	chips.burst(6, {"radius": 6.0, "speed": Vector2(4, 14), "dir": PixelParticles.Dir.INWARD, "alt": Vector2(0, 3),
		"alt_speed": Vector2(-10, 20), "life": Vector2(0.4, 0.7), "size": Vector2(1, 2)})
