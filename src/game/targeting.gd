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
	# MirrorfoldFx.HALF_WIDE, HALF_DEEP: the way in at the first click, the way out at the second (MirrorfoldFx.exit_for())
	"mirror": {"shape": "pair", "wide": 2.4, "deep": 1.0},
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
## A two-click power (Mirrorfold Passage) has its first place set and waits for the second click.
var placed := false
## That first place.
var first := Vector2.ZERO

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
	placed = false
	armed = false
	aiming = false
	queue_redraw()


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
			_rules.refuse(slot, why if why != "" else ("nobody" if who == null else "shaken"))
			queue_redraw()
			return
		_whisper_target = who
		ground = who.ground_pos
	_press = ground
	armed = true
	aiming = _is_drag() or _is_whisper()
	queue_redraw()


## The button came up: cast, unless the press was called off. A click power fires from where the button went
## down; a drag power fires from there along the way it was dragged, and is told where the drag ended ("to"); a
## whisper from the citizen it picked. A two-click power keeps its first click as its place (`first`) and fires from
## there on the second, told where that one landed ("to").
func release(ground: Vector2) -> void:
	if not armed:
		return
	_at = ground
	armed = false
	var extra := {}
	if not modes().is_empty():
		extra["mode"] = String(mode().key)
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
	if _is_drag():
		extra["dir"] = aim_dir()
		extra["to"] = ground
	elif _is_whisper():
		# A whisper goes out where the citizen is now, sending them to the release clamped to REACH and walkable
		# ground. Someone who died or went in meanwhile can no longer hear it.
		var hears := is_instance_valid(_whisper_target) and _whisper_target.is_alive() \
			and not _whisper_target.inside and not _whisper_target.soldier
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


func area() -> Dictionary:
	var a: Dictionary = AREAS.get(_rules.key(slot), {})
	var own: Dictionary = mode().get("area", {})
	if own.is_empty():
		return a
	# A mode may cover its own ground (Divine Schism's regions).
	var out := a.duplicate()
	out.merge(own, true)
	return out


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
		"pair":
			# The way in under the cursor until the first click sets it; then the way out follows the cursor.
			if placed:
				_oval(first, float(a.wide), float(a.deep), edge)
				var out := MirrorfoldFx.exit_for(first, _press)
				_oval(out, float(a.wide), float(a.deep), COL_INNER)
				draw_line(first, out, COL_FAINT, -1.0)
			else:
				_oval(_press, float(a.wide), float(a.deep), edge)
	match _rules.key(slot):
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
			_ring(TownLayout.BELL_TOWER.get_center(), 0.9, COL_DIVINE)
			if String(mode().get("key", "")) == "guard":
				# Where the guard would be sent.
				_place_mark(_press, edge)
		"deathmark":
			var marked := DeathMarkFx.target_at(_crowd._field, _press)
			if marked != null:
				_ring(marked.ground_pos, 0.25, COL_MAD)
		"blight":
			# What it would ruin, or a red ring for nothing in reach.
			var s := BlightFx.target(_crowd._env, _press)
			if s != null:
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
## How far outside the bright line the dark one sits, in ground units (about two pixels).
const SHADE_GAP := 0.05
## Mind Whisper's dotted line, in dashes.
const WHISPER_DASHES := 8


func _ring(at: Vector2, r: float, col: Color) -> void:
	draw_arc(at, r + SHADE_GAP, 0.0, TAU, 48, SHADE, -1.0)
	draw_arc(at, r, 0.0, TAU, 48, col, -1.0)


## A translucent disc with an edge (Divine Congregation's circle), in ground units.
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


## An oval lying across the screen: `wide` along the screen's horizontal, `deep` along its vertical (ground units).
func _oval(at: Vector2, wide: float, deep: float, col: Color) -> void:
	for pass_i in 2:
		var grow: float = SHADE_GAP if pass_i == 0 else 0.0
		var points := PackedVector2Array()
		for i in 49:
			var a := TAU * float(i) / 48.0
			points.append(at + MirrorfoldFx.ACROSS * cos(a) * (wide + grow) + MirrorfoldFx.DOWN * sin(a) * (deep + grow))
		draw_polyline(points, SHADE if pass_i == 0 else col, -1.0)
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
