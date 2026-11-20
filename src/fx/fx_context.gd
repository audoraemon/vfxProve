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
## The town's crowd, for an effect that changes how the town itself behaves (Voice of God's Silence); null in the
## sandbox and in tests that have none.
var crowd: Crowd
## The mission's rules, for an effect that changes the mission itself (Abolition); null in the sandbox and in tests
## that have none.
var rules: Rules
## func(color: Color, seconds: float)
var flash: Callable


## The level (1-5) of the power whose code is running now, and its main cue and school weight (LevelSound): FxTimeline
## sets them around a power's build, events and frame, so what it plays is heard heavier at a higher level. 1 and none
## outside a power's own code (a signal it answers, an effect that is not a power).
var level := 1
var main_cue: StringName = &""
var weight_cue: StringName = &""


func play(cue: StringName, ground_pos: Vector2, db_offset := 0.0) -> Node:
	if sfx == null:
		return null
	if level <= 1:
		return sfx.play(cue, ground_pos, db_offset)
	var p: Node = sfx.play(cue, ground_pos, db_offset + LevelSound.db_for(level))
	if p != null and sfx.has_method(&"set_voice_pitch"):
		sfx.set_voice_pitch(p, LevelSound.pitch_for(level))
	if level >= LevelSound.WEIGHT_FROM and cue == main_cue and weight_cue != &"":
		sfx.play(weight_cue, ground_pos, db_offset + LevelSound.weight_db(level))
	return p


## What FxTimeline saves before a power's code runs and puts back after: [level, main cue, weight cue].
func hearing() -> Array:
	return [level, main_cue, weight_cue]


func hear(was: Array) -> void:
	level = was[0]
	main_cue = was[1]
	weight_cue = was[2]


func fade_out(player: Node, seconds: float) -> void:
	if sfx != null and player != null:
		sfx.fade_out(player, seconds)
