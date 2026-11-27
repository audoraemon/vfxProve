class_name ChamberPageFade
extends CanvasLayer
## God's Chamber step 8: the page side of a station's transition, over any page (Game puts it up; the pages know nothing of it). After the
## room's zoom ends in the station's end colour (GodChamber.end_color), the page appears under a cover of that colour, which lifts over
## IN_TIME; on the page's Back the cover rises again over OUT_TIME, then what follows runs (Game goes on to the room, which starts covered
## in the same colour and pulls back). One continuous motion. Any click or key while it plays finishes that part at once; nothing under it
## is clicked meanwhile.
##
## Only where GodChamber.transitions is on: arrival() and departure() say "" otherwise, and Game then cuts as it always has.

## Over the pages (layer 10) and the pause menu (20), under the fader (100).
const LAYER := 50
const IN_TIME := 0.2
const OUT_TIME := 0.15
## The actions that bring a page up from the room's zoom, and the station each came from.
const ARRIVALS := {"hub:tree": "tree", "hub:faith": "faith", "hub:descend": "descend", "hub:awaken": "awaken"}
## A page's Back and the station the room pulls back from. Prepare's back is the Rite Door's only when the door opened it (departure()).
const DEPARTURES := {"tree:back": "tree", "faith:back": "faith", "world:back": "descend", "prepare:hub": "awaken"}

enum Phase {NONE, IN, OUT}

var phase := Phase.NONE
## The station whose colour this is.
var key := ""
## Photographs only: the cover is held where pose() put it.
var held := false
var _t := 0.0
var _then := Callable()
var _rect: ColorRect
var _color := Color.BLACK


func _init() -> void:
	layer = LAYER
	_rect = ColorRect.new()
	_rect.name = "Cover"
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.color = Color(0, 0, 0, 0)
	add_child(_rect)


## The station a page brought up by `action` fades in from; "" for none, and always "" with transitions off.
static func arrival(action: String) -> String:
	if not GodChamber.transitions:
		return ""
	return ARRIVALS.get(action, "")


## The station a page left by `action` fades out to (and the room pulls back from); "" for none, and always "" with transitions off.
## `page_station` is the station whose zoom brought the page up ("" for none): Prepare's back is the Rite Door's only after the door.
static func departure(action: String, page_station: String) -> String:
	if not GodChamber.transitions:
		return ""
	if action == "prepare:hub" and page_station != "awaken":
		return ""
	return DEPARTURES.get(action, "")


## The cover's alpha fading in, at u (0..1) of IN_TIME: quick, then soft.
static func alpha_in(u: float) -> float:
	var v := 1.0 - clampf(u, 0.0, 1.0)
	return v * v


## The cover's alpha fading out, at u of OUT_TIME: soft, then quick into the room's own cover.
static func alpha_out(u: float) -> float:
	var v := clampf(u, 0.0, 1.0)
	return v * v


## The page appears under `p_key`'s end colour, which lifts over IN_TIME.
func fade_in(p_key: String) -> ChamberPageFade:
	key = p_key
	_color = GodChamber.end_color(p_key)
	phase = Phase.IN
	_t = 0.0
	_then = Callable()
	_apply()
	return self


## The page goes under `p_key`'s end colour over OUT_TIME, with the reverse whoosh; then `then` runs, once.
func fade_out(p_key: String, then: Callable) -> ChamberPageFade:
	key = p_key
	_color = GodChamber.end_color(p_key)
	phase = Phase.OUT
	_t = 0.0
	_then = then
	UiSound.play(GodChamber.WHOOSH_BACK)
	_apply()
	return self


## Photographs only: hold the cover `t` seconds into its fade in (or out); nothing runs after it.
func pose(p_key: String, out: bool, t: float) -> void:
	key = p_key
	_color = GodChamber.end_color(p_key)
	phase = Phase.OUT if out else Phase.IN
	_t = t
	_then = Callable()
	held = true
	_apply()


func busy() -> bool:
	return phase != Phase.NONE


## The cover's alpha now.
func alpha() -> float:
	return _rect.color.a


## The cover's colour now (the end colour, at alpha()).
func color() -> Color:
	return _rect.color


## The cover (tests).
func cover() -> ColorRect:
	return _rect


## One step of the fade (public so tests drive it without the clock).
func advance(delta: float) -> void:
	if phase == Phase.NONE or held:
		return
	_t += delta
	if _t >= (IN_TIME if phase == Phase.IN else OUT_TIME):
		_end()
	else:
		_apply()


## Finishes the part that plays at once: a fade in shows the page, a fade out goes on to what follows.
func skip() -> void:
	if phase != Phase.NONE:
		_end()


func _end() -> void:
	var was := phase
	phase = Phase.NONE
	held = false
	_rect.color = Color(_color.r, _color.g, _color.b, 1.0 if was == Phase.OUT else 0.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP if was == Phase.OUT else Control.MOUSE_FILTER_IGNORE
	var then := _then
	_then = Callable()
	if was == Phase.OUT and then.is_valid():
		then.call()


func _apply() -> void:
	var a := 0.0
	match phase:
		Phase.IN: a = alpha_in(_t / IN_TIME)
		Phase.OUT: a = alpha_out(_t / OUT_TIME)
	_rect.color = Color(_color.r, _color.g, _color.b, a)
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP if phase != Phase.NONE else Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	advance(delta)


## Any key or click while it plays finishes that part, and goes no further (the page under it never sees it).
func _input(event: InputEvent) -> void:
	if phase == Phase.NONE or held:
		return
	var press: bool = (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed)
	if not press:
		return
	skip()
	if is_inside_tree():
		get_viewport().set_input_as_handled()
