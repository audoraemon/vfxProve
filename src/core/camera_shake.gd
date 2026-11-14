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

## Render zoom = logical zoom x view_fit. The logical zoom is what the simulation and the player's zoom mean; the fit (UiScale.fit(),
## set by the hosting WorldView) widens or narrows the render so the visible world is never wider than 21:9. Always write the zoom
## through zoom_to(), never `zoom =`; a lint test enforces it.
var view_fit := 1.0


func zoom_to(z: float) -> void:
	zoom = Vector2.ONE * z * view_fit


## The zoom without the fit (derived, so a direct write to `zoom` stays consistent at fit 1).
func logical_zoom() -> float:
	return zoom.x / view_fit


## A new fit, keeping the logical zoom.
func set_view_fit(f: float) -> void:
	var logical := logical_zoom()
	view_fit = f
	zoom_to(logical)


func _ready() -> void:
	var wv := WorldView.of(self)
	if wv != null:
		set_view_fit(UiScale.fit())  # hosted: the fit of the current window
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
