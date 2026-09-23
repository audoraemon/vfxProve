class_name Town
extends Node
## Builds Aldermere (TownLayout) into an EnvironmentField: every building with its role, the fortified Citadel, and
## the town floor on the battlefield's ground plane.

var citadel: Citadel
var bridge: Structure
var gates: Array[Structure] = []
## Null when built without a ground plane (headless tests).
var floor_node: TownFloor


## ground: the battlefield's ground plane, or null for no floor. shake: camera the Citadel shakes when parts fall.
func build(env: EnvironmentField, ground: Node2D = null, shake: CameraShake = null) -> void:
	for d in TownLayout.structures():
		var s := env.add_structure(d.rect, d.height, d.kind, d.role)
		if s.kind == Structure.Kind.GATE:
			gates.append(s)
		elif s.kind == Structure.Kind.BRIDGE:
			bridge = s
	citadel = Citadel.new()
	citadel.name = "Citadel"
	add_child(citadel)
	citadel.setup(env, TownLayout.CITADEL_ORIGIN, shake)
	if ground != null:
		floor_node = TownFloor.new()
		floor_node.name = "TownFloor"
		ground.add_child(floor_node)
		ground.move_child(floor_node, 0)


func _exit_tree() -> void:
	_free_floor()


func _notification(what: int) -> void:
	# The floor hangs under the battlefield's ground plane, not under this node, so it has to be freed by
	# hand whichever way the town goes away — including a town that never entered the scene tree.
	if what == NOTIFICATION_PREDELETE:
		_free_floor()


func _free_floor() -> void:
	if is_instance_valid(floor_node):
		floor_node.queue_free()
	floor_node = null
