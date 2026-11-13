class_name ZoomReadout
extends CanvasLayer
## The camera's zoom as "x0.60" at the screen's right edge (the user's Discord idea "Zoom cap", 2026-11): shown for SHOW_SECONDS
## after each zoom change, then it fades. On a layer of its own above the HUD's, so it still shows while F1 hides the interface
## (zoomed out, the town is what one looks at). Reads only; draws nothing until the zoom first changes.

## How long the readout stays up after a change, and how long of that it spends fading out.
const SHOW_SECONDS := 3.0
const FADE_SECONDS := 0.6
## Its plate's distance from the area's right edge and its vertical centre as a fraction of the area's height (the right side, clear of the
## status line and the slots). The plate is anchored to that edge, so it hugs it at any area.
const RIGHT_MARGIN := 6.0
const MID_Y := 180.0
const PLATE_H := 18.0

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


## The plate for a text `w` wide on an area of `area` units: its right edge RIGHT_MARGIN in from the area's, centred at MID_Y's share of its height.
static func plate_rect(w: float, area: Vector2) -> Rect2:
	return Rect2(Vector2(area.x - RIGHT_MARGIN - w - 8.0, roundf(area.y * (MID_Y / 360.0)) - PLATE_H * 0.5), Vector2(w + 8.0, PLATE_H))


func _draw_view() -> void:
	if not shown():
		return
	var a := clampf(_left / FADE_SECONDS, 0.0, 1.0)
	var w := UiTheme.width(_text, UiTheme.TEXT_S)
	var plate := plate_rect(w, _view.size if _view.size.x > 1.0 else UiScale.area())
	var bg := UiTheme.COL_PANEL
	bg.a *= a
	_view.draw_rect(plate, bg)
	var col := UiTheme.COL_TEXT
	col.a = a
	UiTheme.text(_view, plate.position + Vector2(4.0, 13.0), _text, UiTheme.TEXT_S, col, a)
