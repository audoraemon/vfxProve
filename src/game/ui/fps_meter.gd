class_name FpsMeter
extends CanvasLayer
## F3 shows or hides the frame rate over the battlefield, top right under the status line: frames a second and the
## average frame time over the last half second, the slowest frame in it, and the draw calls (the town's main
## cost: about 3.5 us each on the CPU). Hidden until asked for, so captures and benches never show it; once shown it
## stays shown for the rest of the run, through restarts and new missions. `-- --fps` starts with it shown.

const TOGGLE_KEY := KEY_F3
## How long each reading averages over.
const WINDOW := 0.5
## Green at or above GOOD_FPS, gold down to OK_FPS, red below.
const GOOD_FPS := 55.0
const OK_FPS := 30.0
const COL_GOOD := Color("7fc46a")
## Top right, under the HUD's status line (Hud._draw_status at y 14).
const TOP := 20.0
const MARGIN := 6.0
const PLATE_H := 12.0

## Shown or hidden, shared by every meter, so a new mission's battlefield keeps the player's choice.
static var shown := false

var text := ""
var color := UiTheme.COL_TEXT
var _readout: Readout
var _frames := 0
var _time := 0.0
var _worst := 0.0
var _calls := 0.0
## The wall clock at the last frame (us): delta is scaled by hitstop and the ending's slow motion.
var _last := 0


## The meter's line: "83 FPS  12.0 ms  max 25.6  1201 draws".
static func describe(fps: float, ms: float, worst_ms: float, draws: int) -> String:
	return "%d FPS  %.1f ms  max %.1f  %d draws" % [roundi(fps), ms, worst_ms, draws]


static func color_for(fps: float) -> Color:
	if fps >= GOOD_FPS:
		return COL_GOOD
	return UiTheme.COL_GOLD if fps >= OK_FPS else UiTheme.COL_BAD


class Readout extends Control:
	var meter: FpsMeter

	func _draw() -> void:
		if meter.text == "":
			return
		var w := get_viewport_rect().size.x
		var tw := UiTheme.width(meter.text, UiTheme.SIZE_SMALL)
		var at := Vector2(roundf(w - tw - FpsMeter.MARGIN), FpsMeter.TOP)
		draw_rect(Rect2(at - Vector2(2.0, 0.0), Vector2(tw + 4.0, FpsMeter.PLATE_H)), Color(0, 0, 0, 0.62))
		UiTheme.text(self, at + Vector2(0.0, FpsMeter.PLATE_H - 3.0), meter.text, UiTheme.SIZE_SMALL, meter.color)


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_readout = Readout.new()
	_readout.meter = self
	_readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_readout.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_readout)
	if "--fps" in OS.get_cmdline_user_args():
		shown = true
	visible = shown


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == TOGGLE_KEY:
		toggle()


func toggle() -> void:
	shown = not shown
	visible = shown
	_frames = 0
	_time = 0.0
	_worst = 0.0
	_calls = 0.0
	_last = 0
	text = ""
	_readout.queue_redraw()


func _process(_delta: float) -> void:
	if not visible:
		return
	var now := Time.get_ticks_usec()
	if _last == 0:
		_last = now
		return
	var dt := float(now - _last) / 1_000_000.0
	_last = now
	_frames += 1
	_time += dt
	_worst = maxf(_worst, dt)
	_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	if _time < WINDOW:
		return
	var fps := float(_frames) / _time
	text = describe(fps, _time / _frames * 1000.0, _worst * 1000.0, roundi(_calls / _frames))
	color = color_for(fps)
	_frames = 0
	_time = 0.0
	_worst = 0.0
	_calls = 0.0
	_readout.queue_redraw()
