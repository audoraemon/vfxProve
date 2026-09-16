class_name FxContext
extends RefCounted
## Handles an effect needs: gameplay, camera, audio and the draw layers.

var field: EnemyField
var env: EnvironmentField
var lights: LightField
var shake: CameraShake
var sfx: Node
## Node2D with transform Iso.BASIS: children are authored in ground units.
var impact: Impact
var ground: Node2D
## Screen-space, y-sorted with enemies.
var world: Node2D
## Screen-space, above the world but under overhead: smoke goes here so fireballs read in front.
var overhead_back: Node2D
## Screen-space, above the world.
var overhead: Node2D
## Screen-space, topmost; for screen-texture distortion.
var distort: Node2D
var rng: RandomNumberGenerator
## func(color: Color, seconds: float)
var flash: Callable


func play(cue: StringName, ground_pos: Vector2, db_offset := 0.0) -> Node:
	if sfx == null:
		return null
	return sfx.play(cue, ground_pos, db_offset)


func fade_out(player: Node, seconds: float) -> void:
	if sfx != null and player != null:
		sfx.fade_out(player, seconds)
