class_name CameraShake
extends Camera2D
## Trauma-based screen shake with whole-pixel offsets.

const MAX_OFFSET := 8.0
const DECAY := 1.6

var trauma := 0.0

var _noise := FastNoiseLite.new()
var _time := 0.0


func _ready() -> void:
	_noise.seed = 1337
	_noise.frequency = 0.35


func add_trauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)


func _process(delta: float) -> void:
	_time += delta * 60.0
	trauma = maxf(trauma - DECAY * delta, 0.0)
	var power := trauma * trauma * MAX_OFFSET
	var n := Vector2(_noise.get_noise_2d(_time, 0.0), _noise.get_noise_2d(0.0, _time))
	offset = (n * power * 2.0).round()
