class_name CameraShake
extends Camera2D
## Trauma-based screen shake with whole-pixel offsets.

const MAX_OFFSET := 8.0
const DECAY := 1.6

var trauma := 0.0
## Directional punch (px), springs back to rest.
var _kick := Vector2.ZERO

var _noise := FastNoiseLite.new()
var _time := 0.0


func _ready() -> void:
	_noise.seed = 1337
	_noise.frequency = 0.35


func add_trauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)


## Snap the view in a direction (px), e.g. downward on a heavy impact.
func kick(offset_px: Vector2) -> void:
	_kick += offset_px


func _process(delta: float) -> void:
	_time += delta * 60.0
	trauma = maxf(trauma - DECAY * delta, 0.0)
	var power := trauma * trauma * MAX_OFFSET
	var n := Vector2(_noise.get_noise_2d(_time, 0.0), _noise.get_noise_2d(0.0, _time))
	_kick = _kick.lerp(Vector2.ZERO, minf(14.0 * delta, 1.0))
	offset = (n * power * 2.0 + _kick).round()
