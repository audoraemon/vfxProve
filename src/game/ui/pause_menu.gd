class_name PauseMenu
extends Node
## Pause (spec §1): the mission frozen underneath, and Resume, Options (v0.11.2), Restart, Change powers, Missions (Endless Night, god P1:
## Resume, Options, Abandon night, which asks first). Esc resumes, the
## way it paused -- unless the Options panel is open, when it closes that first. This node lives beside the mission, not inside it, so it keeps running while the mission is
## switched off.

## "resume", "restart" (a new mission with the same four powers), "change" (back to the draft), "missions" (the
## mission board, v0.08) or, in a campaign, "campaign" (its night screen, v0.10). In Endless Night (god P1, spec §9.1): "resume"
## or "abandon", the latter only after its confirm.
signal action(name: String)

## Endless Night's Abandon confirm once the clock has started (god P1, spec §9.1, Ruling P9): leaving counts as a lost night.
## God P2 (spec §10.1, §2: a penalty is shown before it happens) adds that a lost night raises the Lantern Notice by 25%.
const CONFIRM_LOST := "Abandon now and the night is lost: no Divine Power, no Faith, Lantern Notice +25%."
## The Hunt's Abandon confirm (god P2, spec §10.3, Ruling P2-5; *my call*): `%s` is GodNight.hunt_stake() -- what the Lantern would seal.
const CONFIRM_HUNT := "Abandon the Hunt and it is lost. %s, and the Notice goes to 50%%."
## The same when the abandon fills the meter (god P2 fix wave, final review M2, Ruling F1): `%d` is the rise that really happens after the
## clamp (min(25, 100 - Notice)), and the Hunt is named because the next night will be it. *My call* (copy).
const CONFIRM_LOST_HUNT := "Abandon now and the night is lost: no Divine Power, no Faith, Lantern Notice +%d%%, and the Lantern Hunts next."
## And when the Notice is full already (rise 0): no rise is promised; the Hunt is still the next night. *My call* (copy).
const CONFIRM_LOST_FULL := "Abandon now and the night is lost: no Divine Power, no Faith. Lantern Notice is already 100%, and the Lantern Hunts next."
## An Awaken rite's Abandon confirm (god P3, MS §1, spec §2: a penalty is shown before it happens; *my call*): `%d` is the Notice rise that really
## happens after the clamp (min(25, 100 - Notice)).
const CONFIRM_RITE := "Abandon the rite and it is lost: Lantern Notice +%d%%. The god stays capped."
## The same when the abandon fills the meter: the Hunt is named because the next night will be it.
const CONFIRM_RITE_HUNT := "Abandon the rite and it is lost: Lantern Notice +%d%%. The god stays capped. The Lantern Hunts next."
## And when the Notice is full already (rise 0): no rise is promised.
const CONFIRM_RITE_FULL := "Abandon the rite and it is lost. Lantern Notice is already 100%. The god stays capped. The Lantern Hunts next."
## And before the clock starts (the intro, Prepare's side of it): leaving costs nothing.
const CONFIRM_FREE := "The clock has not started: leaving is free."
## The confirm's text block: its width, its first baseline, and the row of buttons under it.
## (God P2: wide enough that a Hunt's three-line stake stays above the buttons; preflight R5.)
const CONFIRM_WIDTH := 420.0
const CONFIRM_Y := 160.0
const CONFIRM_BUTTONS_Y := 196.0

var _ui: Control
var _menu: Menu
var _hover := ""
var _panel: OptionsPanel
var _settings: Settings
var _settings_path := Settings.PATH
## Endless Night's menu (god P1): the rows are Resume, Options and Abandon night, and Abandon asks first.
var _endless := false
## True once the clock has started, so the confirm says the night is lost (Ruling P9).
var _forfeits := false
## What a lost Hunt would seal (GodNight.hunt_stake()), set by Game before setup() when the night is the Hunt; "" for any other night.
var hunt_stake := ""
## True while the night is an Awaken rite, set by Game before setup() (god P3, MS §1): Abandon then says the rite is lost and what it costs.
var rite := false
## The god's Lantern Notice now, set by Game before setup() (god P2 fix wave, M2): the lost-night confirm states the rise it will really cause.
var notice := 0
## The rows the menu goes back to when Stay is pressed, and whether the confirm is up.
var _rows: Menu
var _confirm := false


## `campaign` (v0.10): the last button leads back to the campaign's night screen instead of the board. `settings` and `path`
## (v0.11.2) are what the Options row edits and where it saves; "options" opens the panel here and is never emitted. `endless`
## (god P1, spec §9.1): Endless Night's rows -- no Restart, no Change powers -- and Abandon night, which asks before it emits
## "abandon"; `forfeits` says the clock has started, so the confirm warns that the night is lost (Ruling P9) rather than that
## leaving is free.
func setup(campaign := false, settings: Settings = null, path := Settings.PATH, endless := false, forfeits := false) -> PauseMenu:
	_settings = settings if settings != null else Settings.new().load_from(path)
	_settings_path = path
	_endless = endless
	_forfeits = forfeits
	var layer := CanvasLayer.new()
	layer.layer = 20  # over the HUD
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	if endless:
		_menu = Menu.column(["resume", "options", "abandon"], ["Resume", "Options", "Abandon night"], 320.0, 148.0, 140.0)
	else:
		_menu = Menu.column(["resume", "options", "restart", "change", "campaign" if campaign else "missions"],
			["Resume", "Options", "Restart", "Change powers", "Campaign" if campaign else "Missions"],
			320.0, 148.0, 140.0)
	_rows = _menu
	return self


## Abandon's confirm is up (Endless Night only).
func confirming() -> bool:
	return _confirm


## The lost-night confirm for a god at `notice` (god P2 fix wave, final review M2, Ruling F1; spec §2 "every penalty is shown before it
## happens"): the Notice rise after the clamp -- GodNight.NOTICE_LOST, but never past 100 -- and "the Lantern Hunts next" when the abandon
## fills the meter. At 0..74 this is CONFIRM_LOST word for word. Static so the interlude says exactly the same.
static func lost_line(at_notice: int) -> String:
	var rise := clampi(mini(GodNight.NOTICE_LOST, GodSlot.NOTICE_MAX - at_notice), 0, GodNight.NOTICE_LOST)
	if rise == 0:
		return CONFIRM_LOST_FULL
	if at_notice + rise >= GodSlot.NOTICE_MAX:
		return CONFIRM_LOST_HUNT % rise
	return CONFIRM_LOST


## The Notice a lost rite adds for a god at `at_notice`: GodNight.NOTICE_LOST_RITE, never past 100 (the pause confirm's and Prepare's IF LOST read it).
static func rite_rise(at_notice: int) -> int:
	return clampi(mini(GodNight.NOTICE_LOST_RITE, GodSlot.NOTICE_MAX - at_notice), 0, GodNight.NOTICE_LOST_RITE)


## The lost-rite confirm for a god at `at_notice` (god P3, MS §1; Ruling P3-4): the Notice rise after the clamp -- GodNight.NOTICE_LOST_RITE, but
## never past 100 -- and "the Lantern Hunts next" when the abandon fills the meter. Static so a test can read it without a screen.
static func rite_line(at_notice: int) -> String:
	var rise := rite_rise(at_notice)
	if rise == 0:
		return CONFIRM_RITE_FULL
	if at_notice + rise >= GodSlot.NOTICE_MAX:
		return CONFIRM_RITE_HUNT % rise
	return CONFIRM_RITE % rise


## What the confirm says: once the clock has started CONFIRM_RITE for a rite, CONFIRM_HUNT for the Hunt (it names the stake) or else lost_line(notice); before it,
## CONFIRM_FREE; "" while it is not up.
func confirm_line() -> String:
	if not _confirm:
		return ""
	if not _forfeits:
		return CONFIRM_FREE
	if rite:
		return rite_line(notice)
	return CONFIRM_HUNT % hunt_stake if hunt_stake != "" else lost_line(notice)


## Opens (or closes) the confirm: the buttons become Abandon and Stay, and the rows return on Stay.
func _set_confirm(on: bool) -> void:
	_confirm = on
	_hover = ""
	if on:
		# The buttons sit under the last line of the confirm, however many lines it takes (god P2, preflight R5).
		var lines := UiTheme.wrap(confirm_line(), CONFIRM_WIDTH, UiTheme.SIZE_BODY).size()
		_menu = Menu.row(["abandon", "stay"], ["Abandon", "Stay"], 320.0,
			maxf(CONFIRM_BUTTONS_Y, CONFIRM_Y + UiTheme.LINE_BODY * float(lines - 1) + 10.0), 100.0)
	else:
		_menu = _rows
	_ui.queue_redraw()


func options_open() -> bool:
	return is_instance_valid(_panel) and _panel.is_open()


func _open_options() -> void:
	if options_open():
		return
	_panel = OptionsPanel.new().setup(_settings, _settings_path)
	_panel.closed.connect(_on_options_closed)
	_ui.add_child(_panel)


func _on_options_closed() -> void:
	if is_instance_valid(_panel):
		_panel.queue_free()
	_panel = null
	_ui.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if options_open():
		return  # the panel has it (Esc closes the panel, it does not resume)
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		if _confirm:
			UiSound.play(&"ui_click")
			_set_confirm(false)  # Esc in the confirm is Stay
			return
		UiSound.play(&"ui_resume")
		action.emit("resume")


func _on_gui_input(event: InputEvent) -> void:
	if options_open():
		return
	if event is InputEventMouseMotion:
		var h := _menu.at(event.position)
		if h != _hover:
			_hover = h
			if h != "":
				UiSound.play(&"ui_hover")
			_ui.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var a := _menu.at(event.position)
		if a == "options":
			UiSound.play(&"ui_click")
			_open_options()
		elif a == "abandon" and _endless and not _confirm:
			UiSound.play(&"ui_click")
			_set_confirm(true)  # asks first; only the confirm's Abandon emits (god P1, Ruling P9)
		elif a == "stay":
			UiSound.play(&"ui_click")
			_set_confirm(false)
		elif a != "":
			# Resume is ui_pause turned upward; every other button leaves the mission, and clicks.
			UiSound.play(&"ui_resume" if a == "resume" else &"ui_click")
			action.emit(a)


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.0, 0.0, 0.0, 0.55))
	var title := "PAUSED"
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(title, UiTheme.SIZE_TITLE) * 0.5), 126.0), title,
		UiTheme.SIZE_TITLE, UiTheme.COL_GOLD)
	if _confirm:
		var lines := UiTheme.wrap(confirm_line(), CONFIRM_WIDTH, UiTheme.SIZE_BODY)
		for i in lines.size():
			UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(lines[i], UiTheme.SIZE_BODY) * 0.5),
				CONFIRM_Y + UiTheme.LINE_BODY * float(i)), lines[i], UiTheme.SIZE_BODY, UiTheme.COL_BAD if _forfeits else UiTheme.COL_TEXT)
	_menu.draw_on(_ui, _hover)
