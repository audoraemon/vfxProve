class_name ZoomReadout
extends CanvasLayer
## The camera's zoom as "x0.60" at the screen's right edge (the user's Discord idea "Zoom cap", 2026-11): shown for SHOW_SECONDS
## after each zoom change, then it fades. On a layer of its own above the HUD's, so it still shows while F1 hides the interface
## (zoomed out, the town is what one looks at). Reads only; draws nothing until the zoom first changes.

## How long the readout stays up after a change, and how long of that it spends fading out.
const SHOW_SECONDS := 3.0
const FADE_SECONDS := 0.6
## Its plate's right edge and vertical centre on a 640 x 360 screen (the screen's right side, clear of the status line and slots).
const RIGHT_MARGIN := 6.0
const MID_Y := 180.0

var _text := ""
var _left := 0.0
var _view: Control


func _init() -> void:
	layer = 6  # above the HUD's (Battlefield.hud_layer is 5)
	name = "ZoomReadout"
	_view = Control.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(_draw_view)
	add_child(_view)


## The text for a zoom `z`: "x" and two decimals (x0.50, x1.00, x1.61).
static func label(z: float) -> String:
	return "x%.2f" % z


## The zoom changed to `z`: show it for SHOW_SECONDS.
func show_zoom(z: float) -> void:
	_text = label(z)
	_left = SHOW_SECONDS
	_view.queue_redraw()


func shown() -> bool:
	return _left > 0.0


func text() -> String:
	return _text if shown() else ""


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left = maxf(0.0, _left - delta)
	_view.queue_redraw()


func _draw_view() -> void:
	if not shown():
		return
	var a := clampf(_left / FADE_SECONDS, 0.0, 1.0)
	var w := UiTheme.width(_text, UiTheme.SIZE_BODY)
	var size := _view.size if _view.size.x > 1.0 else Vector2(640.0, 360.0)
	var plate := Rect2(Vector2(size.x - RIGHT_MARGIN - w - 8.0, size.y * (MID_Y / 360.0) - 9.0), Vector2(w + 8.0, 18.0))
	var bg := UiTheme.COL_PANEL
	bg.a *= a
	_view.draw_rect(plate, bg)
	var col := UiTheme.COL_TEXT
	col.a = a
	UiTheme.text(_view, plate.position + Vector2(4.0, 13.0), _text, UiTheme.SIZE_BODY, col, a)
