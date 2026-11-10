class_name Targeting
extends Node2D
## Aiming: which slot is picked, the area it would cover drawn on the ground, and the click or drag that turns
## into a cast. A child of Battlefield.ground_plane, so it draws in ground units and its circles come out as
## the right iso ellipses. It knows nothing about the mouse: Mission hands it ground positions, which is also
## what makes it testable headless. Mind Whisper (v0.08) aims its own way: the press picks a citizen, the release
## the spot they are sent to.

## The player picked another slot.
signal picked(slot: int)

## A drag shorter than this keeps the default direction rather than spinning on a twitch.
const DRAG_MIN := 0.5
const COL_EDGE := Color(1.0, 0.86, 0.35, 0.7)
const COL_INNER := Color(1.0, 0.45, 0.2, 0.8)
const COL_FAINT := Color(1.0, 0.86, 0.35, 0.25)
const COL_BAD := Color(0.9, 0.2, 0.15, 0.7)
## Blight's target outline.
const COL_ROT := Color(0.62, 0.78, 0.4, 0.9)
## Divine Congregation's circle (its fill and its edge) and Madness Bloom's ring.
const COL_DIVINE := Color(1.0, 0.9, 0.6, 0.8)
const COL_DIVINE_FILL := Color(1.0, 0.9, 0.6, 0.1)
const COL_MAD := Color(0.6, 0.15, 0.3, 0.8)
## Divine Schism's other side, and the condemned.
const COL_CRIMSON := Color(1.0, 0.3, 0.25, 0.85)
const COL_CRIMSON_FILL := Color(1.0, 0.3, 0.25, 0.1)
## Which way a drag power points when the player barely moved the mouse.
const DEFAULT_DIR := Vector2(1, 0)

## What each power covers, taken from the effect's own constants (the comment names them). Milestone 5 may
## repaint these; it must not invent numbers for them.
const AREAS := {
	# SilentDoom.RADIUS; the people it would take are ringed (_draw())
	"doom": {"shape": "circle", "r": 0.8},
	# MindWhisperFx.PICK_R: who the press would whisper to
	"whisper": {"shape": "circle", "r": 0.6},
	# SmiteFx.KILL_R
	"smite": {"shape": "circle", "r": 0.6},
	# EmberFx.REACH; the building it would light is outlined (_draw())
	"ember": {"shape": "circle", "r": 1.0},
	# DeathMarkFx.PICK_R; whom it would mark is ringed (_draw())
	"deathmark": {"shape": "circle", "r": 1.0},
	# NoLeaveFx.RADIUS: the ground nobody may leave
	"noleave": {"shape": "circle", "r": 3.0},
	# The Bell Lies works at the Bell Tower wherever the click lands: the tower is ringed (_draw()); its Call the
	# Guard mode marks where the soldiers are sent (the book's "area")
	"belllies": {"shape": "circle", "r": 0.6},
	# MagnifyFx.RADIUS
	"magnify": {"shape": "circle", "r": 4.0},
	# Abolition voids a law of the whole night: the mark is only where the click lands
	"abolition": {"shape": "circle", "r": 0.6},
	# SkyliftFx.RADIUS: what it would take is ringed at the first click; then where it is set down ("pick")
	"skylift": {"shape": "pick", "r": 2.5},
	# WindfallFx.LENGTH, SEG * 0.5; centred on the press, like Thornwall
	"windfall": {"shape": "lane", "length": 3.6, "half": 0.3, "centred": true},
	# HellmouthSparkFx.RADIUS
	"hellspark": {"shape": "circle", "r": 1.5},
	# PilgrimRoadFx.LENGTH, HALF: the lane runs from the press along the drag
	"pilgrim": {"shape": "lane", "length": 6.0, "half": 0.6},
	# DoorToTheDeepFx.RADIUS: how far the water reaches
	"deep": {"shape": "circle", "r": 4.0},
	# HoundGateFx: the door is where the click lands; SEEK_R is how far the hounds hunt
	"houndgate": {"shape": "circle", "r": 0.6, "roam": 8.0},
	# AllRoadsLeadHereFx.RADIUS: the district whose roads are bent to the click
	"allroads": {"shape": "circle", "r": 10.0},
	# YesterdaysDoorFx.RADIUS: the district that steps back
	"yesterday": {"shape": "circle", "r": 6.0},
	# FoldedWardFx.HALF: the square folded so its edges meet, centred on the click
	"foldward": {"shape": "square", "half": 3.0},
	# EveryDoorFx: the whole town; the click is only where the door of light stands
	"everydoor": {"shape": "circle", "r": 0.6},
	# TheFarGateFx.RADIUS: whom the door of stars draws
	"fargate": {"shape": "circle", "r": 10.0},
	# AnathemaFx.RADIUS: the buildings it would mark are outlined (_draw())
	"anathema": {"shape": "circle", "r": 6.0},
	# SacredSanctuaryFx.PICK_R: who would be hypnotized is ringed; then the wall's shape at the second click ("sanctuary")
	"sanctuary": {"shape": "sanctuary", "r": 5.0},
	# SaintFx.PICK_R: whom it would choose is ringed (_draw()); then the wheel
	"saint": {"shape": "circle", "r": 1.0},
	# ClearMindFx.RADIUS
	"clearmind": {"shape": "circle", "r": 5.0},
	# UnseenHourFx.RADIUS
	"unseen": {"shape": "circle", "r": 5.0},
	# CurfewFx.RADIUS
	"curfew": {"shape": "circle", "r": 4.0},
	# EarthshatterFx: the run from the first click toward the second, HALF wide, MAX_LENGTH at most ("path")
	"shatter": {"shape": "path", "half": 1.1, "length": 18.0, "min": 4.0},
	# ScatterStrikeFx.RADIUS: the circle its strikes are thrown into
	"scatter": {"shape": "circle", "r": 6.5},
	# Tempest covers the whole town: the mark is only where the click lands (where the thunder is loudest)
	"tempest": {"shape": "circle", "r": 0.6},
	# Blight.REACH; the structure it would ruin is outlined (_draw())
	"blight": {"shape": "circle", "r": 1.0},
	# WillOWisp.RING (where the drawn stand) and LURE_REACH; who it would draw is ringed (_draw())
	"wisp": {"shape": "circle", "r": 1.6, "roam": 6.0},
	# ThornwallFx.THORN_LENGTH, SEG * 0.5; centred on the press
	"thorns": {"shape": "lane", "length": 3.0, "half": 0.3, "centred": true},
	# PestilenceFx.INFECT_R; who it would infect is ringed (_draw())
	"pestilence": {"shape": "circle", "r": 1.2},
	# DiscordFx.DISCORD_R; who it would take is ringed (_draw())
	"discord": {"shape": "circle", "r": 1.2},
	# OathboundFx.PICK_R; who it would bind is ringed; its Hold mode picks them first, then the place ("pick")
	"oath": {"shape": "circle", "r": 1.2},
	# CommandEchoFx.SEED_R; who it would start with is ringed
	"echo": {"shape": "circle", "r": 1.2},
	# TurncoatFx.PICK_R; who it would turn is ringed
	"turncoat": {"shape": "circle", "r": 1.0},
	# ManufacturedHatredFx.GROUP_R
	"hatred": {"shape": "circle", "r": 3.0},
	# RewritePriorityFx.RADIUS
	"priority": {"shape": "circle", "r": 7.0},
	# MobVerdictFx.RADIUS: the judged at the first click, the mob's circle at the second
	"verdict": {"shape": "gather", "r": 7.0},
	# CollectiveDelusionFx.DANGER_R (its All Is Well mode covers RADIUS)
	"delusion": {"shape": "circle", "r": 3.0},
	# Voice of God speaks to the whole town: the mark is only where the click lands (Flee's origin, Gather's place,
	# Judge's target -- ringed in _draw())
	"voice": {"shape": "circle", "r": 0.6},
	# Divine Schism: the middle of the region it divides; its modes cover their own ground (the book's "area")
	"schism": {"shape": "circle", "r": 0.6},
	# MadnessBloomFx.RADIUS; who it would take is ringed (_draw())
	"madness": {"shape": "circle", "r": 1.5},
	# CongregationFx.RADIUS: the place at the first click, the circle at the second; who it would draw is ringed
	"congregation": {"shape": "gather", "r": 7.0},
	# MirrorfoldFx.HALF, MIN_LEN, MAX_LEN: the way in is a lane laid by the drag, the way out the same lane at the click
	# that follows (MirrorfoldFx.exit_for())
	"mirror": {"shape": "lanepick", "half": 0.6, "min": 2.0, "length": 6.0},
	# LINE_LENGTH, LINE_HALF_WIDTH, FISSURE_LENGTH; centred: the line runs half its length each way from the cast
	"heaven": {"shape": "lane", "length": 10.0, "half": 0.7, "fissure": 5.6, "centred": true},
	# PULL_RADIUS, CORE_RADIUS, WANDER_RADIUS
	"tornado": {"shape": "circle", "r": 3.2, "inner": 0.6, "roam": 7.0},
	# CONE_RADIUS, SWEEP_ARC (the dragon is locked to screen down-right, so this cone does not follow the mouse)
	"dragon": {"shape": "cone", "r": 11.0, "arc": 1.0},
	# LENGTH, WIDTH * 0.5
	"tsunami": {"shape": "lane", "length": 6.5, "half": 4.0},
	# RADIUS, KILL_R
	"gravity": {"shape": "circle", "r": 4.5, "inner": 1.5},
	# LENGTH, KILL_HALF_WIDTH
	"laser": {"shape": "lane", "length": 10.0, "half": 2.6},
	# RADIUS
	"orbital": {"shape": "circle", "r": 4.5},
	# RADIUS, VOLCANO_RADIUS
	"cinder": {"shape": "circle", "r": 5.8, "inner": 2.4},
	# RADIUS
	"judgement": {"shape": "circle", "r": 5.2},
	# RADIUS, SPIKE_RADIUS
	"glacial": {"shape": "circle", "r": 5.0, "inner": 4.5},
	# RADIUS: the pillar, and the pit it leaves
	"solaris": {"shape": "circle", "r": 2.2},
	# RADIUS, KILL_CORE
	"nova": {"shape": "circle", "r": 5.0, "inner": 1.2},
}

## The focused slot, or -1 when nothing is: the area is only drawn while a power is focused.
var slot := -1
## A left press is in progress on a focused power; the release casts it unless something called it off.
var armed := false
## A drag power has the button down and is being aimed.
var aiming := false
## A two-click power (Skylift), or a drag-then-click one (Mirrorfold Passage), has its first place set and waits for
## the second click.
var placed := false
## That first place.
var first := Vector2.ZERO
## The lane a drag-then-click power's drag laid at `first`: which way, and how long (clamped to its area's min..length).
var _lane_dir := DEFAULT_DIR
var _lane_len := 0.0

## The citizen a held Mind Whisper press picked (v0.08), or null.
var _whisper_target: Person

var _rules: Rules
var _crowd: Crowd
## The mode picked for each power that has modes (its book entry's "modes"), by power key: Q and E step through them.
var _mode := {}
## Where the button went down (a cast lands here, not where it came up).
var _press := Vector2.ZERO
## Where the cursor is now, for the preview and the drag's direction.
var _at := Vector2.ZERO


func setup(rules: Rules, crowd: Crowd) -> Targeting:
	_rules = rules
	_crowd = crowd
	_rules.cast_made.connect(_on_cast_made)
	z_index = 5
	z_as_relative = false  # absolute z 5: over the ground and the world, under the overhead layer at 8.
	queue_redraw()  # the first preview: hover() only redraws when the cursor moves, so nothing else would
	return self


## Focus a slot, or unfocus it when it is the one already focused (pressing its key again).
func pick(new_slot: int) -> void:
	if new_slot == slot:
		unfocus()
		return
	slot = new_slot
	armed = false
	aiming = false
	placed = false
	_whisper_target = null
	picked.emit(slot)
	queue_redraw()


func unfocus() -> void:
	slot = -1
	armed = false
	aiming = false
	placed = false
	_whisper_target = null
	picked.emit(slot)
	queue_redraw()


## The focused power's modes (Voice of God's commands, Divine Schism's ways to divide), or none.
func modes() -> Array:
	return _rules.power(slot).get("modes", []) if slot >= 0 else []


func mode_index() -> int:
	var m := modes()
	return int(_mode.get(_rules.key(slot), 0)) % m.size() if not m.is_empty() else 0


## The picked mode's entry ({"key", "name", ...}), or empty for a power with none.
func mode() -> Dictionary:
	var m := modes()
	return m[mode_index()] if not m.is_empty() else {}


## Step to the next mode (or the one before): a first place already set is dropped, the modes may aim differently.
func step_mode(by: int) -> void:
	var m := modes()
	if m.is_empty():
		return
	_mode[_rules.key(slot)] = posmod(mode_index() + by, m.size())
	if not bool(_rules.power(slot).get("alt_steps_mode", false)):
		# The modes may aim differently: a first place already set is dropped. (A power whose modes are only the
		# shape of its second place -- Sacred Sanctuary -- keeps its first.)
		placed = false
		armed = false
		aiming = false
	queue_redraw()


## The right button, for a power whose book entry says "alt_steps_mode": while its second place is being aimed it
## steps the mode (Sacred Sanctuary's shape) instead of calling the cast off. True when it took the click.
func alt_click() -> bool:
	if slot < 0 or not placed or modes().is_empty() or not bool(_rules.power(slot).get("alt_steps_mode", false)):
		return false
	step_mode(1)
	return true


## Q and E step through the focused power's modes.
func _unhandled_input(event: InputEvent) -> void:
	if slot < 0 or not (event is InputEventKey) or not event.pressed or event.echo or modes().is_empty():
		return
	if event.physical_keycode == KEY_Q or event.physical_keycode == KEY_E:
		step_mode(-1 if event.physical_keycode == KEY_Q else 1)
		UiSound.play(&"ui_mode")
		get_viewport().set_input_as_handled()


## How the focused power is aimed: its mode's own way when the mode has one.
func _aim_kind() -> String:
	return String(mode().get("aim", _rules.power(slot).get("aim", "click")))


## The cursor moved. Keeps the preview where the player is looking.
func hover(ground: Vector2) -> void:
	# Mission calls this every frame. A preview that has not moved is not redrawn: this node sits on the ground
	# plane, and redrawing it re-batches the layer the whole town is drawn in.
	# A held whisper is the exception: its line starts on someone walking, so it follows them every frame.
	var held := _whisper_held()
	if ground.is_equal_approx(_at) and not held:
		return
	_at = ground
	if held:
		_press = _whisper_target.ground_pos
	elif not aiming:
		_press = ground
	if _is_wheel() and placed:
		# The option under the cursor is the picked mode: the HUD's chips show it.
		var over := wheel_pick(ground)
		if over >= 0:
			_mode[_rules.key(slot)] = over
	queue_redraw()


func press(ground: Vector2) -> void:
	if slot < 0:
		return
	_at = ground
	if _is_whisper():
		# Mind Whisper: the press snaps to the citizen under it, and with nobody there -- or (v0.08.1) only someone
		# still shaking the last whisper off -- nothing is armed. A slot that could not cast anyway names its own
		# reason first, as a release would.
		var who := MindWhisperFx.pick(_crowd._field, ground)
		if who == null or who.shaken():
			var why := _rules.refusal(slot)
			_rules.refuse(slot, why if why != "" else ("nobody" if who == null else "shaken"), who)
			queue_redraw()
			return
		_whisper_target = who
		ground = who.ground_pos
	_press = ground
	armed = true
	# A drag-then-click power drags only its first place: once that is laid, the press is a click.
	aiming = _is_drag() or _is_whisper() or (_is_drag_then() and not placed)
	queue_redraw()


## The button came up: cast, unless the press was called off. A click power fires from where the button went
## down; a drag power fires from there along the way it was dragged, and is told where the drag ended ("to"); a
## whisper from the citizen it picked. A two-click power keeps its first click as its place (`first`) and fires from
## there on the second, told where that one landed ("to"). A drag-then-click power's first release lays a lane from
## the press along the drag (`first`, "dir", "length"); the click after casts it, told where it landed ("to").
func release(ground: Vector2) -> void:
	if not armed:
		return
	_at = ground
	armed = false
	var extra := {}
	if not modes().is_empty():
		extra["mode"] = String(mode().key)
	if _is_wheel():
		if not placed:
			# Someone to choose, or nothing is armed.
			var who := SaintFx.target_at(_crowd._field, ground)
			if who == null:
				var why := _rules.refusal(slot)
				_rules.refuse(slot, why if why != "" else "nobody")
				queue_redraw()
				return
			placed = true
			first = who.ground_pos
			queue_redraw()
			return
		placed = false
		var pick := wheel_pick(ground)
		if pick < 0:
			queue_redraw()
			return  # off the wheel: called off
		_mode[_rules.key(slot)] = pick
		extra["mode"] = String(mode().key)
		_rules.cast(slot, first, extra)
		queue_redraw()
		return
	if _is_twice():
		if not placed:
			placed = true
			first = ground
			queue_redraw()
			return
		placed = false
		extra["to"] = ground
		_rules.cast(slot, first, extra)
		queue_redraw()
		return
	if _is_drag_then():
		if not placed:
			placed = true
			first = _press
			_lane_dir = aim_dir()
			_lane_len = lane_length()
			aiming = false
			queue_redraw()
			return
		placed = false
		extra["dir"] = _lane_dir
		extra["length"] = _lane_len
		extra["to"] = ground
		_rules.cast(slot, first, extra)
		queue_redraw()
		return
	if _is_drag():
		extra["dir"] = aim_dir()
		extra["to"] = ground
	elif _is_whisper():
		# A whisper goes out where the citizen is now, sending them to the release clamped to REACH and walkable
		# ground. Someone who died or went in meanwhile can no longer hear it.
		var hears := is_instance_valid(_whisper_target) and _whisper_target.is_alive() \
			and not _whisper_target.inside and not _whisper_target.resists_mind()
		var who := _whisper_target if hears else null
		_whisper_target = null
		aiming = false
		if who == null:
			var why := _rules.refusal(slot)
			_rules.refuse(slot, why if why != "" else "nobody")
			queue_redraw()
			return
		_press = who.ground_pos
		extra = {"to": MindWhisperFx.clamp_to(_crowd._grid, _press, ground), "target": who}
	aiming = false
	_rules.cast(slot, _press, extra)
	queue_redraw()


## Call off a press in progress (right-click or Esc while the button is held), or a two-click power's first place.
## True when there was one; the power stays focused either way.
func cancel() -> bool:
	var had := armed or placed
	armed = false
	aiming = false
	placed = false
	_whisper_target = null
	queue_redraw()
	return had


## Which way a drag power points: the drag itself, or DEFAULT_DIR when the player hardly moved.
func aim_dir() -> Vector2:
	var drag := _at - _press
	return drag.normalized() if drag.length() >= DRAG_MIN else DEFAULT_DIR


## How long the lane a drag-then-click power is laying would be: the drag's length, clamped to its area's "min" and
## "length".
func lane_length() -> float:
	var a := area()
	return clampf((_at - _press).length(), float(a.get("min", 0.0)), float(a.get("length", 0.0)))


func area() -> Dictionary:
	var a: Dictionary = AREAS.get(_rules.key(slot), {})
	var own: Dictionary = mode().get("area", {})
	if own.is_empty():
		return a
	# A mode may cover its own ground (Divine Schism's regions).
	var out := a.duplicate()
	out.merge(own, true)
	return out


## A "square" area: the axis-aligned square of side 2 * `half` centred on `at`, in ground units.
static func square(at: Vector2, half: float) -> Rect2:
	return Rect2(at - Vector2(half, half), Vector2(half, half) * 2.0)


## Where a lane power's lane begins: at the cast for a power that sweeps forward from it, half a length back for
## one centred on it.
static func lane_start(key: String, press: Vector2, dir: Vector2) -> Vector2:
	var a: Dictionary = AREAS.get(key, {})
	if bool(a.get("centred", false)):
		return press - dir * float(a.get("length", 0.0)) * 0.5
	return press


func _is_drag() -> bool:
	return _aim_kind() == "drag"


func _is_twice() -> bool:
	return _aim_kind() == "two clicks"


## A drag-then-click power (Mirrorfold Passage): the drag lays a lane, the click after it places the second lane and casts.
func _is_drag_then() -> bool:
	return _aim_kind() == "drag then click"


## A wheel power (v0.13): the first click picks someone, then a wheel of the power's modes opens round them and the
## second click picks one and casts. A click away from the wheel calls the cast off.
func _is_wheel() -> bool:
	return _aim_kind() == "wheel"


## Where the wheel's options sit round `first`, in ground units: spread on a screen circle of WHEEL_PX, the first
## to the left.
func wheel_spots() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var m := modes()
	var centre := Iso.ground_to_screen(first)
	for i in m.size():
		var ang := PI + TAU * float(i) / float(m.size())
		out.append(Iso.screen_to_ground(centre + Vector2(cos(ang), sin(ang) * 0.6) * WHEEL_PX + Vector2(0, -WHEEL_UP)))
	return out


## The wheel option nearest `ground`, or -1 when the click is off the wheel.
func wheel_pick(ground: Vector2) -> int:
	var best := -1
	var best_d := WHEEL_REACH
	var spots := wheel_spots()
	for i in spots.size():
		var d := spots[i].distance_to(ground)
		if d < best_d:
			best_d = d
			best = i
	return best


func _is_whisper() -> bool:
	return _aim_kind() == "whisper"


## The ring over whoever a Mind Whisper press would pick: red while they shake the last whisper off (v0.08.1).
static func whisper_pick_color(who: Person) -> Color:
	return COL_BAD if who.shaken() else COL_INNER


## A Mind Whisper press is held on someone still there to hear it.
func _whisper_held() -> bool:
	return armed and is_instance_valid(_whisper_target)


func _on_cast_made(_slot: int, key: String, at: Vector2) -> void:
	var a: Dictionary = AREAS.get(key, {})
	if String(a.get("shape", "")) == "lane":
		var dir := aim_dir()
		_crowd.on_cast(lane_start(key, at, dir), dir, float(a.length), key)
	elif String(a.get("shape", "")) == "path":
		# Two clicks: from the first toward the second, as far as the power runs.
		var run := _at - at
		var dir := run.normalized() if run.length() > 0.01 else Vector2.RIGHT
		_crowd.on_cast(at, dir, clampf(run.length(), float(a.get("min", 0.0)), float(a.length)), key)
	elif String(a.get("shape", "")) == "lanepick":
		# The lane the drag laid.
		_crowd.on_cast(at, _lane_dir, _lane_len, key)
	else:
		_crowd.on_cast(at, Vector2.ZERO, 0.0, key)
	# A power that went out is on its cooldown: unfocus, so its area stops following the cursor.
	unfocus()


func _draw() -> void:
	var a := area()
	if a.is_empty():
		return
	# A power that cannot be cast still shows its area, in red, so the player can aim while it comes back.
	var edge := COL_EDGE if _rules.refusal(slot) == "" else COL_BAD
	match String(a.shape):
		"circle":
			_ring(_press, float(a.r), edge)
			if a.has("inner"):
				_ring(_press, float(a.inner), COL_INNER)
			if a.has("roam"):
				_ring(_press, float(a.roam), COL_FAINT)
		"lane":
			var dir := aim_dir()
			_lane(lane_start(_rules.key(slot), _press, dir), dir, float(a.length), float(a.half), edge)
			if a.has("fissure"):
				for i in 8:
					var out := Vector2.RIGHT.rotated(TAU * float(i) / 8.0) * float(a.fissure) * 0.5
					draw_line(_press, _press + out, COL_FAINT, -1.0)
		"cone":
			_cone(_press, float(a.r), float(a.arc), edge)
		"square":
			# An axis-aligned square of side 2 * half centred on the cursor (a diamond on screen).
			var box := square(_press, float(a.half))
			draw_rect(box, COL_DIVINE_FILL)
			draw_rect(box.grow(SHADE_GAP), SHADE, false, -1.0)
			draw_rect(box, edge, false, -1.0)
		"pick":
			# The people at the first click, then the place the cursor is on.
			if placed:
				_ring(first, float(a.r), edge)
				_place_mark(_press, COL_DIVINE)
				draw_line(first, _press, COL_FAINT, -1.0)
			else:
				_ring(_press, float(a.r), edge)
		"regions":
			# Divine Schism's Custom Division: one side's region at the first click, the other's following the cursor.
			if placed:
				_disc(first, float(a.r), COL_DIVINE_FILL, COL_DIVINE)
				_disc(_press, float(a.r), COL_CRIMSON_FILL, COL_CRIMSON)
			else:
				_disc(_press, float(a.r), COL_DIVINE_FILL, COL_DIVINE)
		"gather":
			# The place under the cursor until the first click sets it; then the circle follows the cursor.
			if placed:
				_place_mark(first, edge)
				_disc(_press, float(a.r), COL_DIVINE_FILL, COL_DIVINE)
				draw_line(first, _press, COL_FAINT, -1.0)
				for p in CongregationFx.drawn(_crowd._field, _press):
					_ring(p.ground_pos, 0.18, COL_DIVINE)
			else:
				_place_mark(_press, edge)
		"path":
			# The start under the cursor until the first click sets it; then the run follows the cursor, clamped.
			if placed:
				var run := _press - first
				var dir := run.normalized() if run.length() > 0.01 else Vector2.RIGHT
				var length := clampf(run.length(), float(a.get("min", 0.0)), float(a.length))
				_lane(first, dir, length, float(a.half), edge)
				_ring(first, float(a.half), COL_INNER)
			else:
				_ring(_press, float(a.half), edge)
		"sanctuary":
			# The people under the cursor until the first click takes them; then the wall's shape follows the cursor.
			if placed:
				_ring(first, float(a.r), COL_FAINT)
				draw_line(first, _press, COL_FAINT, -1.0)
				if String(mode().get("key", "circle")) == "rect":
					var box := Rect2(_press - SacredSanctuaryFx.RECT * 0.5, SacredSanctuaryFx.RECT)
					draw_rect(box, COL_DIVINE_FILL)
					draw_rect(box.grow(SHADE_GAP), SHADE, false, -1.0)
					draw_rect(box, COL_DIVINE, false, -1.0)
				else:
					_disc(_press, SacredSanctuaryFx.CIRCLE_R, COL_DIVINE_FILL, COL_DIVINE)
				for p in SacredSanctuaryFx.picked_at(_crowd._field, first):
					_ring(p.ground_pos, 0.18, COL_DIVINE)
			else:
				_ring(_press, float(a.r), edge)
				for p in SacredSanctuaryFx.picked_at(_crowd._field, _press):
					_ring(p.ground_pos, 0.18, COL_DIVINE)
		"lanepick":
			# The way in: a lane from the press along the drag until the release lays it; then the way out, the same lane,
			# follows the cursor, and the people standing on the way in are ringed.
			if placed:
				_lane(first, _lane_dir, _lane_len, float(a.half), edge)
				var out := MirrorfoldFx.exit_for(first, _lane_dir, _lane_len, _press)
				_lane(out, _lane_dir, _lane_len, float(a.half), COL_INNER)
				var mid := _lane_dir * _lane_len * 0.5
				draw_line(first + mid, out + mid, COL_FAINT, -1.0)
				for e in MirrorfoldFx.standing_on(_crowd._field, first, _lane_dir, _lane_len):
					_ring(e.ground_pos, 0.18, COL_DIVINE)
			else:
				var dir := aim_dir()
				_lane(_press, dir, lane_length(), float(a.half), edge)
	if _is_wheel() and placed:
		_draw_wheel()
	match _rules.key(slot):
		"anathema":
			for s in AnathemaFx.marked_at(_crowd._env, _press):
				var box := s.footprint.grow(0.08)
				draw_rect(box, COL_MAD if String(mode().get("key", "")) == "cursed" else COL_DIVINE, false, -1.0)
		"saint":
			if not placed:
				var who := SaintFx.target_at(_crowd._field, _press)
				if who != null:
					_ring(who.ground_pos, 0.3, COL_DIVINE)
		"doom":
			# Who it would take.
			for v in SilentDoom.victims_at(_crowd._field, _press):
				_ring(v.ground_pos, 0.22, COL_INNER)
		"oath", "echo":
			# Whom it would bind, or start with.
			for p in OathboundFx.bound_at(_crowd._field, first if placed else _press, 5 if _rules.key(slot) == "echo" else 4):
				_ring(p.ground_pos, 0.2, COL_DIVINE)
		"turncoat":
			var turned := TurncoatFx.target_at(_crowd._field, _press)
			if turned != null:
				_ring(turned.ground_pos, 0.25, COL_CRIMSON)
		"voice":
			match String(mode().get("key", "")):
				"gather":
					_place_mark(_press, edge)
				"judge":
					# Whom everyone would turn on.
					var judged := VoiceOfGodFx.judged_at(_crowd._field, _press)
					if judged != null:
						_ring(judged.ground_pos, 0.3, COL_CRIMSON)
		"schism":
			if String(mode().get("key", "")) == "purge":
				# The condemned.
				for p in DivineSchismFx.condemned_at(_crowd._field, _press):
					_ring(p.ground_pos, 0.25, COL_CRIMSON)
		"madness":
			# Who it would take.
			for p in MadnessBloomFx.victims_at(_crowd._field, _press):
				_ring(p.ground_pos, 0.2, COL_MAD)
		"pestilence":
			# Who it would infect.
			for p in PestilenceFx.victims_at(_crowd._field, _press):
				_ring(p.ground_pos, 0.2, Person.SICK_MOTE)
		"discord":
			# Who it would take.
			for p in DiscordFx.taken(_crowd._field, _press):
				_ring(p.ground_pos, 0.2, Person.COL_DISCORD)
		"wisp":
			# Who it would draw.
			for p in WillOWisp.drawn(_crowd._field, _press):
				_ring(p.ground_pos, 0.18, COL_FAINT)
		"whisper":
			if _whisper_held():
				_whisper_line(_press, _at)
			else:
				# Who a press here would whisper to; red while they shake the last whisper off (v0.08.1).
				var who := MindWhisperFx.pick(_crowd._field, _press)
				if who != null:
					_ring(who.ground_pos, 0.2, whisper_pick_color(who))
		"ember":
			# What it would light, or a red ring for nothing that burns in reach.
			var burns := EmberFx.target(_crowd._env, _press)
			if burns != null:
				var box := burns.footprint.grow(0.08)
				draw_polyline(PackedVector2Array([box.position, Vector2(box.end.x, box.position.y), box.end,
					Vector2(box.position.x, box.end.y), box.position]), COL_INNER, -1.0)
			else:
				_ring(_press, 0.3, COL_BAD)
		"belllies":
			_ring(City.current().landmark(&"bell_tower").get_center(), 0.9, COL_DIVINE)
			if String(mode().get("key", "")) == "guard":
				# Where the guard would be sent.
				_place_mark(_press, edge)
		"deathmark":
			var marked := DeathMarkFx.target_at(_crowd._field, _press)
			if marked != null:
				_ring(marked.ground_pos, 0.25, COL_MAD)
		"blight":
			# What it would ruin, or a red ring for nothing in reach.
			var mine := _rules.director.blight_target(_press) if _rules.director != null else Vector2.INF
			var s := BlightFx.target(_crowd._env, _press) if mine == Vector2.INF else null
			if mine != Vector2.INF:
				# A director's own thing (v0.11.1: an unguarded standard or mirror), ringed as a structure is outlined; a guarded one
				# only takes the banner, so its ring is red.
				_ring(mine, 0.45, COL_ROT if _rules.director.blight_takes(mine) else COL_BAD)
			elif s != null:
				var r := s.footprint.grow(0.08)
				for pass_i in 2:
					var g := SHADE_GAP if pass_i == 0 else 0.0
					var q := r.grow(g)
					draw_polyline(PackedVector2Array([q.position, Vector2(q.end.x, q.position.y), q.end,
						Vector2(q.position.x, q.end.y), q.position]), SHADE if pass_i == 0 else COL_ROT, -1.0)
			else:
				_ring(_press, 0.3, COL_BAD)


## Every preview line is drawn twice: a dark stroke a hair outside, then the bright one. Hairlines are all
## this project draws (a pixel line cannot be made thicker), and one gold hairline vanishes over lit stone.
const SHADE := Color(0.05, 0.04, 0.02, 0.75)
## The wheel: its options' screen radius round the chosen, how far up, and how near a click must land on one.
const WHEEL_PX := 44.0
const WHEEL_UP := 26.0
const WHEEL_REACH := 1.3
const WHEEL_FILL := Color(0.05, 0.04, 0.02, 0.8)
## How far outside the bright line the dark one sits, in ground units (about two pixels).
const SHADE_GAP := 0.05
## Mind Whisper's dotted line, in dashes.
const WHISPER_DASHES := 8


func _ring(at: Vector2, r: float, col: Color) -> void:
	draw_arc(at, r + SHADE_GAP, 0.0, TAU, 48, SHADE, -1.0)
	draw_arc(at, r, 0.0, TAU, 48, col, -1.0)


## A translucent disc with an edge (Divine Congregation's circle), in ground units.
## The wheel round the chosen: a disc per mode with its sign, the one under the cursor lit.
func _draw_wheel() -> void:
	_ring(first, 0.35, COL_DIVINE)
	var m := modes()
	var spots := wheel_spots()
	var over := mode_index()
	var flat := Iso.BASIS.affine_inverse()
	for i in spots.size():
		var sp := Iso.ground_to_screen(spots[i])
		var lit := i == over
		draw_set_transform_matrix(flat * Transform2D(0.0, sp))
		draw_circle(Vector2.ZERO, 13.0, WHEEL_FILL)
		draw_arc(Vector2.ZERO, 13.0, 0.0, TAU, 24, COL_DIVINE if lit else COL_FAINT, 1.5 if lit else 1.0)
		var glyph: Array = (m[i] as Dictionary).get("glyph", DominionParts.RINGS)
		var col: Color = (m[i] as Dictionary).get("color", COL_DIVINE)
		for r in 5:
			for c in 5:
				if int(glyph[r]) & (1 << (4 - c)):
					draw_rect(Rect2(Vector2(c - 2.5, r - 2.5) * 3.0, Vector2(3, 3)), col if lit else Color(col, 0.6))
		draw_set_transform_matrix(Transform2D())
		draw_line(first, spots[i], COL_FAINT, -1.0)


func _disc(at: Vector2, r: float, fill: Color, edge: Color) -> void:
	var pts := PackedVector2Array()
	for i in 48:
		var a := TAU * float(i) / 48.0
		pts.append(at + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, fill)
	_ring(at, r, edge)


## The gathering place: the building it would be, or a small ring on the ground, with a four-point star over it.
func _place_mark(at: Vector2, col: Color) -> void:
	var found := CongregationFx.place_for(_crowd._env, at)
	if found.structure != null:
		var q: Rect2 = (found.structure as Structure).footprint.grow(0.1)
		draw_polyline(PackedVector2Array([q.position, Vector2(q.end.x, q.position.y), q.end, Vector2(q.position.x, q.end.y),
			q.position]), col, -1.0)
	else:
		_ring(at, 0.5, col)
	var c: Vector2 = found.at
	draw_line(c + Vector2(-0.3, -0.3), c + Vector2(0.3, 0.3), col, -1.0)
	draw_line(c + Vector2(-0.3, 0.3), c + Vector2(0.3, -0.3), col, -1.0)


## Mind Whisper's held aim: a dotted line of WHISPER_DASHES dashes from the citizen to where they would be sent
## (the release clamped to REACH and walkable ground), a ring there, and the stretch past REACH in red up to the
## cursor.
func _whisper_line(from: Vector2, to: Vector2) -> void:
	var spot := MindWhisperFx.clamp_to(_crowd._grid, from, to)
	var steps := WHISPER_DASHES * 2 - 1
	for i in range(0, steps, 2):
		var a := from.lerp(spot, float(i) / float(steps))
		var b := from.lerp(spot, float(i + 1) / float(steps))
		draw_line(a + Vector2(0.0, SHADE_GAP), b + Vector2(0.0, SHADE_GAP), SHADE, -1.0)
		draw_line(a, b, COL_EDGE, -1.0)
	_ring(spot, 0.25, COL_EDGE)
	if from.distance_to(to) > MindWhisperFx.REACH:
		draw_line(from + (to - from).limit_length(MindWhisperFx.REACH), to, COL_BAD, -1.0)


func _lane(from: Vector2, dir: Vector2, length: float, half: float, col: Color) -> void:
	var unit := Vector2(-dir.y, dir.x)
	for pass_i in 2:
		var grow: float = SHADE_GAP if pass_i == 0 else 0.0
		var side := unit * (half + grow)
		var tip := dir * (length + grow)
		var back := dir * -grow
		draw_polyline(PackedVector2Array([from + back + side, from + tip + side, from + tip - side,
			from + back - side, from + back + side]), SHADE if pass_i == 0 else col, -1.0)
	draw_line(from, from + dir * length, COL_FAINT, -1.0)


func _cone(from: Vector2, r: float, arc: float, col: Color) -> void:
	# The dragon's own start angle: its facing, biased 8 degrees to its right so the jet misses its body.
	var start := Vector2(1, 0).angle() - arc * 0.5 - deg_to_rad(8.0)
	for pass_i in 2:
		var grow: float = SHADE_GAP if pass_i == 0 else 0.0
		var points := PackedVector2Array([from])
		for i in 17:
			points.append(from + Vector2.RIGHT.rotated(start + arc * float(i) / 16.0) * (r + grow))
		points.append(from)
		draw_polyline(points, SHADE if pass_i == 0 else col, -1.0)
