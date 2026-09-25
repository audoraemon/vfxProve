class_name Fader
extends CanvasLayer
## Black over everything, faded in and out between screens. It covers the moment a new mission has a
## battlefield but no town yet, which showed as a second of bare green after MANIFEST.

var _rect: ColorRect


func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	add_child(_rect)


func fade_out(seconds: float) -> void:
	await _to(1.0, seconds)


func fade_in(seconds: float) -> void:
	await _to(0.0, seconds)


func is_clear() -> bool:
	return _rect.modulate.a <= 0.01


func _to(alpha: float, seconds: float) -> void:
	var tw := create_tween()
	tw.set_ignore_time_scale(true)  # hit-stop and the slow-motion ending must not stretch a fade
	tw.tween_property(_rect, "modulate:a", alpha, seconds)
	await tw.finished
