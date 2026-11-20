class_name ThreatAlert
extends CanvasLayer
## The loss warning (Discord idea "More Effect on Losing situation"): one big hit, then a reminder. When a thing that ends the night comes within
## WARN_AT seconds (Rules.threats(): a Herald nearing the Temple, the bell's climb that would fill the Gaze, a standard nearing its second house),
## a red card slams in at the screen's centre -- what happens, and what to do with the seconds counting down -- with an alarm and a small
## kick of the picture, holds CARD_SECONDS and fades; then only a red pulse round the screen's edges stays until the threat is gone (stopped, back
## beyond CLEAR_AT, or the night over). A new threat (another id) gets its own hit; the same one never hits twice unless it went away first.
##
## Pure presentation: it reads Rules and changes nothing in the night. Its clocks are real time (the hit-stop's dips and the ending's 0.3 slow
## motion do not stretch it), so the state machine is driven by tick() with real seconds; the drawing is computed from the ages, no tween.
## Over the HUD (HudLayer 6), under the results and the pause menu (10, 20) and the Fader (100).

enum State { IDLE, CARD, EDGE }

const LAYER := 7
## A threat this many seconds out (or nearer) is warned.
const WARN_AT := 15.0
## Hysteresis: a warned threat stays warned until it is this far out again (an estimate that jitters past WARN_AT does not drop it).
const CLEAR_AT := WARN_AT + 3.0
## Real seconds the big card stays up (its fade included).
const CARD_SECONDS := 2.5
## A warned threat missing from the list this long (real seconds) is gone: back, it is a new warning. Shorter, a one-frame gap is not a loss.
const FORGET := 0.5
## The card's slam: from this scale to 1 over PUNCH_SECONDS, eased out; it comes in over IN_SECONDS and fades over its last FADE_SECONDS.
const PUNCH_FROM := 1.6
const PUNCH_SECONDS := 0.22
const IN_SECONDS := 0.12
const FADE_SECONDS := 0.4
## A red flash over the whole screen at the slam, gone in FLASH_SECONDS.
const FLASH_SECONDS := 0.3
const FLASH_A := 0.2
## The edge pulse: a band EDGE_W units deep, red at the screen's edge fading to nothing inward, pulsing PULSE_HZ times a second between
## EDGE_LOW and EDGE_HIGH alpha (EDGE_CARD while the card is up). Subtle enough to play under.
const EDGE_W := 34.0
const EDGE_LOW := 0.16
const EDGE_HIGH := 0.34
const EDGE_CARD := 0.42
const PULSE_HZ := 0.9
const COL_EDGE := Color(0.85, 0.06, 0.04)
## The card: a dark red plate with a bright red rim; the title in light text, the order and the seconds in gold-white.
const COL_CARD := Color(0.28, 0.02, 0.02, 0.9)
const COL_RIM := Color("e8473a")
const COL_TITLE := Color("f4ece0")
const COL_ACT := Color("ffd27a")
const CARD_PAD := Vector2(18.0, 10.0)
const LINE_GAP := 4.0
## The card's centre sits this far below the screen's: under the banner bar (Hud.BANNER_TOP + BANNER_H at 640x360), clear of the slots.
const CARD_DROP := 10.0
## The alarm: the town's horn as an interface sound (Sfx catalogue; not in the world, so not positional), a little under its own level.
const CUE := &"town_horn"
const CUE_DB := -3.0
## The kick at the slam: the world's picture (WorldView.display) punched KICK_PX units down, back in KICK_SECONDS. The picture, not the camera:
## the camera's place decides who is stepped off screen (Person.view), and a warning must not change the night (the references stay exact).
const KICK_PX := 4.0
const KICK_SECONDS := 0.18

var state := State.IDLE
## The threat on screen (a NightThreat dictionary), {} when idle.
var current := {}
## How many times the alarm has sounded (one per hit), and the ids of the threats warned and still live, with the real seconds each has
## been missing (FORGET).
var stings := 0
var _warned := {}
var _card_age := 0.0
var _pulse := 0.0
## The night is over: nothing more is shown (Rules.over).
var _over := false

var _rules: Rules
## The world's picture the kick moves (null headless, where the world is not hosted), and its rest position.
var _display: Control
var _display_rest := Vector2.ZERO
var _kick_age := INF
## func() -> bool: may the alert be seen now (the HUD shown, no intro, no ending). Unset: always.
var _allowed := Callable()
var _view: Control
## Capture only (--hud-threat): a made-up threat shown in place of the night's, its seconds counting down in real time.
var dev_threat := {}


func _init() -> void:
	layer = LAYER
	_view = Control.new()
	_view.name = "View"
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_view.draw.connect(_draw_view)
	add_child(_view)
	visible = false


## Reads `rules`' threats; kicks `display`, the world's picture (may be null); shown only while `allowed` says so (unset: always). Stops for good
## when the act is over.
func setup(rules: Rules, display: Control = null, allowed := Callable()) -> ThreatAlert:
	_rules = rules
	_display = display
	_allowed = allowed
	if rules != null and not rules.over.is_connected(finish):
		rules.over.connect(finish)
	return self


func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.001)  # real seconds, through the hit-stop and the ending's slow motion
	tick(real, _read(real), _shown())
	_step_kick(real)


## The night's threats now (or the capture's made-up one).
func _read(real: float) -> Array:
	if not dev_threat.is_empty():
		dev_threat["eta"] = maxf(float(dev_threat.get("eta", 0.0)) - real, 0.0)
		return [dev_threat]
	if _over or not is_instance_valid(_rules):
		return []
	return _rules.threats()


func _shown() -> bool:
	return not _over and (not _allowed.is_valid() or bool(_allowed.call()))


## One step of `dt` real seconds with the night's threats `list` (NightThreat dictionaries), drawn only when `show`. A hidden alert still
## follows its threats, so one that was warned while hidden does not hit when the interface comes back -- but a hit while hidden is silent.
func tick(dt: float, list: Array, show := true) -> void:
	_pulse += dt
	if _over:
		list = []
	var live := {}
	for t: Dictionary in list:
		if float(t.get("eta", INF)) <= CLEAR_AT:
			live[t.get("id", &"")] = true
	for id: Variant in _warned.keys():
		if live.has(id):
			_warned[id] = 0.0
		else:
			_warned[id] = float(_warned[id]) + dt
			if float(_warned[id]) > FORGET:
				_warned.erase(id)
	var t := NightThreat.soonest(list)
	var id: Variant = t.get("id", &"")
	var eta := float(t.get("eta", INF))
	if t.is_empty() or not (eta <= WARN_AT or (_warned.has(id) and eta <= CLEAR_AT)):
		state = State.IDLE
		current = {}
	else:
		if current.is_empty() or current.get("id", &"") != id:
			if _warned.has(id):
				state = State.EDGE  # warned already (another was soonest a moment): the reminder, not a second hit
			else:
				_warned[id] = 0.0
				state = State.CARD
				_card_age = 0.0
				_slam(show)
		current = t
	if state == State.CARD:
		_card_age += dt
		if _card_age >= CARD_SECONDS:
			state = State.EDGE
	visible = show and state != State.IDLE
	if visible:
		_view.queue_redraw()


## The night is over (Rules.over): the alert goes, for good.
func finish(_won := false, _reason := "") -> void:
	_over = true
	if _kick_age < KICK_SECONDS and is_instance_valid(_display):
		_display.position = _display_rest
	_kick_age = INF
	state = State.IDLE
	current = {}
	visible = false


## The card is up.
func card_shown() -> bool:
	return visible and state == State.CARD


## Only the edge pulse is up.
func edge_shown() -> bool:
	return visible and state == State.EDGE


## The card's second line: "STOP HIM - 12 SECONDS".
static func act_line(t: Dictionary) -> String:
	var n := ceili(float(t.get("eta", 0.0)))
	return "%s - %d %s" % [String(t.get("act", "")), n, "SECOND" if n == 1 else "SECONDS"]


## The hit: the alarm and the picture's kick, once per new threat. Silent while hidden.
func _slam(show: bool) -> void:
	if not show:
		return
	stings += 1
	UiSound.play(CUE, CUE_DB)
	if is_instance_valid(_display):
		if _kick_age >= KICK_SECONDS:
			_display_rest = _display.position
		_kick_age = 0.0


## The kick's frame: the picture down KICK_PX, easing back to rest over KICK_SECONDS, then left at rest.
func _step_kick(dt: float) -> void:
	if _kick_age >= KICK_SECONDS or not is_instance_valid(_display):
		return
	_kick_age += dt
	var k := clampf(1.0 - _kick_age / KICK_SECONDS, 0.0, 1.0)
	_display.position = _display_rest + Vector2(0.0, roundf(KICK_PX * k * k))


func _exit_tree() -> void:
	if _kick_age < KICK_SECONDS and is_instance_valid(_display):
		_display.position = _display_rest  # never leave the picture kicked
	_kick_age = INF


func _area() -> Vector2:
	var s := _view.size
	return s if s.x > 1.0 and s.y > 1.0 else UiScale.area()


func _draw_view() -> void:
	if state == State.IDLE:
		return
	var a := _area()
	if state == State.CARD and _card_age < FLASH_SECONDS:
		var f := COL_EDGE
		f.a = FLASH_A * (1.0 - _card_age / FLASH_SECONDS)
		_view.draw_rect(Rect2(Vector2.ZERO, a), f)
	var edge := EDGE_CARD if state == State.CARD else lerpf(EDGE_LOW, EDGE_HIGH, 0.5 + 0.5 * sin(TAU * PULSE_HZ * _pulse))
	_draw_edges(a, edge)
	if state == State.CARD:
		_draw_card(a)


## The red band round the screen: four strips, each red at the edge and clear inward (vertex colours, no shader).
func _draw_edges(a: Vector2, alpha: float) -> void:
	var on := COL_EDGE
	on.a = alpha
	var off := COL_EDGE
	off.a = 0.0
	var w := EDGE_W
	var cols := PackedColorArray([on, on, off, off])
	_view.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(a.x, 0), Vector2(a.x - w, w), Vector2(w, w)]), cols)
	_view.draw_polygon(PackedVector2Array([Vector2(0, a.y), Vector2(a.x, a.y), Vector2(a.x - w, a.y - w), Vector2(w, a.y - w)]), cols)
	_view.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(0, a.y), Vector2(w, a.y - w), Vector2(w, w)]), cols)
	_view.draw_polygon(PackedVector2Array([Vector2(a.x, 0), Vector2(a.x, a.y), Vector2(a.x - w, a.y - w), Vector2(a.x - w, w)]), cols)


## The card at its slam's scale and fade: the title, then the order and the seconds.
func _draw_card(a: Vector2) -> void:
	var title := String(current.get("title", ""))
	var act := act_line(current)
	var size := UiTheme.TEXT_L
	var tw := UiTheme.width(title, size)
	var aw := UiTheme.width(act, size)
	var inner := maxf(tw, aw)
	var box := Vector2(inner + CARD_PAD.x * 2.0, UiTheme.LINE_L * 2.0 + LINE_GAP + CARD_PAD.y * 2.0)
	var punch := clampf(_card_age / PUNCH_SECONDS, 0.0, 1.0)
	var s := lerpf(PUNCH_FROM, 1.0, 1.0 - pow(1.0 - punch, 3.0))
	var fade := clampf(_card_age / IN_SECONDS, 0.0, 1.0) * clampf((CARD_SECONDS - _card_age) / FADE_SECONDS, 0.0, 1.0)
	var centre := (a * 0.5 + Vector2(0.0, CARD_DROP)).round()
	_view.draw_set_transform(centre, 0.0, Vector2(s, s))
	var rect := Rect2(-box * 0.5, box)
	var plate := COL_CARD
	plate.a *= fade
	_view.draw_rect(rect, plate)
	var rim := COL_RIM
	rim.a = fade
	_view.draw_rect(rect, rim, false, 2.0)
	_view.draw_rect(rect.grow(-4.0), Color(rim, 0.45 * fade), false, 1.0)
	var top := rect.position.y + CARD_PAD.y
	var t_col := COL_TITLE
	t_col.a = fade
	var a_col := COL_ACT
	a_col.a = fade
	UiTheme.text(_view, Vector2(roundf(-tw * 0.5), top + 19.0), title, size, t_col, fade)
	UiTheme.text(_view, Vector2(roundf(-aw * 0.5), top + UiTheme.LINE_L + LINE_GAP + 19.0), act, size, a_col, fade)
	_view.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
