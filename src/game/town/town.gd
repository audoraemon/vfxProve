class_name Town
extends Node
## Builds Aldermere (TownLayout) into an EnvironmentField: every building with its role, the fortified Citadel, the
## market fountain, the decor (TownDecor), the chimney smoke, and the town floor on the battlefield's ground plane.


## The world's decor: y-sorted in with everyone else, and dimmed with the ambient light as a whole.
class DecorLayer extends Node2D:
	var lights: LightField

	func _ready() -> void:
		y_sort_enabled = true

	func _process(_delta: float) -> void:
		var a := lights.ambient if lights else 1.0
		var t := lights.tint if lights else Color.WHITE
		var m := Color(a * t.r, a * t.g, a * t.b)
		if not modulate.is_equal_approx(m):
			modulate = m

## The town's warm evening light, after the reference: everything lit takes this colour (LightField.tint); windows,
## torches and lamps do not, so they glow against it.
const EVENING := Color(1.03, 0.93, 0.8)
## The ground takes a deeper gold than the buildings: in the reference the low sun turns its dirt and cobbles
## orange while its stone stays grey and its slate blue (tools/dev/match_interior.py measures the whole).
const GROUND_EVENING := Color(1.06, 0.92, 0.74)

var citadel: Citadel
var bridge: Structure
var gates: Array[Structure] = []
var fountain: Structure
var smoke: ChimneySmoke
## Null when built without a ground plane (headless tests).
var floor_node: TownFloor
## Everything this town put into the field, so teardown() can take exactly that back out.
var _built: Array[Structure] = []
var _decor: Array[Decor] = []
var _decor_layer: DecorLayer
## Plays each collapse (collapse_cue()). Set by whoever builds the town on a battlefield; null in tests.
var sfx: Sfx

var _env: EnvironmentField


## ground: the battlefield's ground plane, or null for no floor. shake: camera the Citadel shakes when parts fall.
func build(env: EnvironmentField, ground: Node2D = null, shake: CameraShake = null) -> void:
	_env = env
	env.structure_destroyed.connect(_on_structure_destroyed)
	if env.lights != null:
		env.lights.tint = EVENING
	for d in TownLayout.structures():
		var s := env.add_structure(d.rect, d.height, d.kind, d.role, d.tag)
		_built.append(s)
		if s.kind == Structure.Kind.GATE:
			gates.append(s)
		elif s.kind == Structure.Kind.BRIDGE:
			bridge = s
	# One Citadel node for the life of this town: setup() resets its state, so a rebuild reuses it instead of
	# orphaning the old node — and anything connected to its signals stays connected.
	if not is_instance_valid(citadel):
		citadel = Citadel.new()
		citadel.name = "Citadel"
		add_child(citadel)
	citadel.setup(env, TownLayout.CITADEL_ORIGIN, shake)
	_built.append_array(citadel.parts)
	# Built last so every other building keeps the seed it had before the fountain existed.
	for f: Rect2 in TownLayout.FOUNTAINS:
		var built := env.add_structure(f, 24.0, Structure.Kind.FOUNTAIN, &"decor")
		_built.append(built)
		if fountain == null:
			fountain = built
	var baked: Array[Dictionary] = []
	if env.world_parent != null:
		_decor_layer = DecorLayer.new()
		_decor_layer.name = "Decor"
		_decor_layer.lights = env.lights
		env.world_parent.add_child(_decor_layer)
	for d in TownDecor.spots():
		if d.bake and ground != null:
			baked.append(d)
			continue
		var dec := Decor.new().setup(d.kind, d.at, d.size, d.seed)
		env.add_decor(dec)
		_decor.append(dec)
		if _decor_layer != null:
			_decor_layer.add_child(dec)
	var houses: Array[Structure] = []
	for s in _built:
		if s.kind == Structure.Kind.HOUSE and s.role == &"house":
			houses.append(s)
	smoke = ChimneySmoke.new().setup(houses)
	smoke.name = "ChimneySmoke"
	smoke.lights = env.lights
	if env.fx_back != null:
		env.fx_back.add_child(smoke)
	if ground != null:
		baked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return (a.at as Vector2).x + (a.at as Vector2).y < (b.at as Vector2).x + (b.at as Vector2).y)
		floor_node = TownFloor.new()
		floor_node.name = "TownFloor"
		floor_node.baked_decor = baked
		floor_node.tint = GROUND_EVENING
		ground.add_child(floor_node)
		ground.move_child(floor_node, 0)


## Take this town out of the world: its buildings (the Citadel's parts included) leave the field, the floor is
## freed, and the town forgets them so build() can run again.
func teardown() -> void:
	if _env.structure_destroyed.is_connected(_on_structure_destroyed):
		_env.structure_destroyed.disconnect(_on_structure_destroyed)
	for s in _built:
		if is_instance_valid(s):
			_env.remove(s)
	_built.clear()
	gates.clear()
	bridge = null
	fountain = null
	if _env.lights != null:
		_env.lights.tint = Color.WHITE
	_env.clear_decor()
	for d in _decor:
		_free(d)
	_decor.clear()
	_free(_decor_layer)
	_decor_layer = null
	_free(smoke)
	smoke = null
	_free_floor()


## The sound a structure makes coming down, by what it is built of: stone for fortifications and the big civic
## buildings, timber for houses, stalls and farm buildings, a tree's own; none for torch and lamp posts or fields.
static func collapse_cue(s: Structure) -> StringName:
	match s.kind:
		Structure.Kind.TREE:
			return &"collapse_tree"
		Structure.Kind.HOUSE, Structure.Kind.MARKET_STALL, Structure.Kind.CRATES:
			return &"collapse_timber"
		Structure.Kind.TORCH, Structure.Kind.FARM_FIELD:
			return &""
	return &"collapse_stone"


## A structure came down: its material's crash where it stood, louder the bigger it was.
func _on_structure_destroyed(s: Structure, _kind: StringName) -> void:
	if sfx == null:
		return
	var cue := collapse_cue(s)
	if cue == &"":
		return
	sfx.play(cue, s.center(), lerpf(-3.0, 1.0, clampf(s.footprint.get_area() / 6.0, 0.0, 1.0)))


## Free a node now if it never entered the tree, else at the end of the frame.
func _free(n: Node) -> void:
	if not is_instance_valid(n):
		return
	if n.is_inside_tree():
		n.queue_free()
	else:
		n.free()


func _exit_tree() -> void:
	_free_floor()


func _notification(what: int) -> void:
	# The floor hangs under the battlefield's ground plane, not under this node, so it has to be freed by
	# hand whichever way the town goes away — including a town that never entered the scene tree.
	if what == NOTIFICATION_PREDELETE:
		_free_floor()
		# Decor that never entered a tree (headless) would leak otherwise.
		for d in _decor:
			if is_instance_valid(d) and not d.is_inside_tree():
				d.free()
		if is_instance_valid(smoke) and not smoke.is_inside_tree():
			smoke.free()


func _free_floor() -> void:
	if is_instance_valid(floor_node):
		# queue_free() only marks the node for deferred deletion — it stays a child of the ground plane until
		# the engine next flushes that queue. A rebuild that never yields a frame (this happens synchronously
		# in headless tests) would then add a second floor beside the still-attached old one, so a floor
		# outside the tree (headless: the ground plane is never added anywhere) is freed immediately instead.
		if floor_node.is_inside_tree():
			floor_node.queue_free()
		else:
			floor_node.free()
	floor_node = null
