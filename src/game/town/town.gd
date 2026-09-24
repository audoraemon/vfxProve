class_name Town
extends Node
## Builds Aldermere (TownLayout) into an EnvironmentField: every building with its role, the fortified Citadel, and
## the town floor on the battlefield's ground plane.

var citadel: Citadel
var bridge: Structure
var gates: Array[Structure] = []
## Null when built without a ground plane (headless tests).
var floor_node: TownFloor
## Everything this town put into the field, so teardown() can take exactly that back out.
var _built: Array[Structure] = []

var _env: EnvironmentField


## ground: the battlefield's ground plane, or null for no floor. shake: camera the Citadel shakes when parts fall.
func build(env: EnvironmentField, ground: Node2D = null, shake: CameraShake = null) -> void:
	_env = env
	for d in TownLayout.structures():
		var s := env.add_structure(d.rect, d.height, d.kind, d.role)
		_built.append(s)
		if s.kind == Structure.Kind.GATE:
			gates.append(s)
		elif s.kind == Structure.Kind.BRIDGE:
			bridge = s
	citadel = Citadel.new()
	citadel.name = "Citadel"
	add_child(citadel)
	citadel.setup(env, TownLayout.CITADEL_ORIGIN, shake)
	_built.append_array(citadel.parts)
	if ground != null:
		floor_node = TownFloor.new()
		floor_node.name = "TownFloor"
		ground.add_child(floor_node)
		ground.move_child(floor_node, 0)


## Take this town out of the world: its buildings (the Citadel's parts included) leave the field, the floor is
## freed, and the town forgets them so build() can run again.
func teardown() -> void:
	for s in _built:
		if is_instance_valid(s):
			_env.remove(s)
	_built.clear()
	gates.clear()
	bridge = null
	_free_floor()


func _exit_tree() -> void:
	_free_floor()


func _notification(what: int) -> void:
	# The floor hangs under the battlefield's ground plane, not under this node, so it has to be freed by
	# hand whichever way the town goes away — including a town that never entered the scene tree.
	if what == NOTIFICATION_PREDELETE:
		_free_floor()


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
