class_name Hud
extends Control
## The in-mission HUD (spec §5): the clock above, the objectives to the left, the city's state to the right,
## banners across the middle, and the slots below (v0.08: no Divine Power bar -- none is spent in a mission). A mission
## without a score (v0.08: The Warning) lists its objectives top left, and its director's marked person -- the
## messenger -- wears a gold marker, or an arrow at the screen's edge points to him. It reads Rules, Crowd and
## the Citadel and changes nothing; it redraws only when what it shows has changed.

## How long one banner stays up.
const BANNER_SECONDS := 2.2
## A slot that refused a cast stays red for this long (spec §1; the buzz that goes with it is milestone 5's).
const FLASH_SECONDS := 0.35
## The clock turns red and pulses under this many seconds (spec §5).
const HURRY_AT := 30.0

const SLOT_SIZE := 42.0
const SLOT_GAP := 4.0
## A slot is a compact card (v0.08: six fit across the screen): the SLOT_SIZE icon on the left, and beside it the
## power's name on one line, cut to NAME_ROOM, over its cooldown. Six make a 620-px row inside 640.
const SLOT_W := 100.0
## How wide the name may run beside the icon, short of the card's right edge.
const NAME_ROOM := SLOT_W - SLOT_SIZE - 6.0
## The screen width to lay out against before the Control has been sized (headless tests).
const SCREEN_W := 640.0
## Where the slot row sits: low, where the Divine Power bar was before v0.08.
const SLOT_TOP := 316.0
const STABILITY_BAR := Vector2(96.0, 5.0)
## The objectives, top left: sized for four lines of SIZE_SMALL text.
const OBJECTIVE_PANEL := Rect2(2.0, 2.0, 236.0, 60.0)
## The stability bar's legend: a short name for each part and its colour's index, in the bar's own order.
const LEGEND := [["Pop", 0], ["Infra", 1], ["Lead", 2], ["Mil", 3], ["Res", 4]]
## The dark plate under a slot's hotkey.
const PLATE_H := 12.0
## The Banishing Rite's bar under the clock (v0.05).
const RITE_BAR := Vector2(120.0, 4.0)
const RITE_TOP := 30.0
## The act's next timed events (v0.09), centred under the clock and the rite's bar: one line each.
const EVENTS_TOP := 44.0
## The screen height to lay out against before the Control has been sized (headless tests).
const SCREEN_H := 360.0
## A mission without a score (v0.08: The Warning) lists its objectives top left instead, one row this tall each.
const ROW_H := 13.0
## The messenger's marker (v0.08): a gold chevron this far above his feet while he is on screen, else an arrow at the
## screen's edge, this far in, pointing at him.
const MARKER_LIFT := 26.0
const EDGE_MARGIN := 10.0

var _rules: Rules
var _crowd: Crowd
var _town: Town
var _aim: Targeting
## Banners waiting their turn: [text, seconds shown].
var _banners: Array = []
## Seconds of red left per slot, for the refused-cast flash.
var _flash := PackedFloat32Array()
## What the last frame drew, so an unchanged HUD costs nothing.
var _drawn := ""
## The slot icons, taken once. PowerBook.hud_icon() goes through load(), and a texture asked for during
## _draw() can reach the draw list before the GPU has it -- which paints a solid white block, and because the
## HUD only redraws when something changes, the block stays white for the rest of the mission.
var _slot_icons: Array[Texture2D] = []
## The powers' names, cut to one line of NAME_ROOM, taken once with their icons.
var _slot_names: Array[String] = []


func setup(rules: Rules, crowd: Crowd, town: Town, aim: Targeting) -> Hud:
	_rules = rules
	_crowd = crowd
	_town = town
	_aim = aim
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # the player is aiming at the town, not clicking the HUD
	_flash.resize(_rules.loadout.size())
	_flash.fill(0.0)
	_slot_icons.clear()
	for i in _rules.loadout.size():
		_slot_icons.append(PowerBook.hud_icon(_rules.key(i)))
	_slot_names.clear()
	for i in _rules.loadout.size():
		_slot_names.append(UiTheme.fit(String(_rules.power(i).get("name", "")), NAME_ROOM))
	_rules.banner.connect(push_banner)
	_rules.cast_refused.connect(_on_cast_refused)
	return self


func _process(delta: float) -> void:
	advance(delta)


## Age the banners, and redraw when anything on screen has changed.
func advance(delta: float) -> void:
	# Only the one on screen (index 0, the only one _draw_banners() ever reads) ages: a banner waiting behind
	# it must not lose part of its own showing to the time it spent queued.
	if not _banners.is_empty():
		_banners[0][1] += delta
	while not _banners.is_empty() and float(_banners[0][1]) >= BANNER_SECONDS:
		_banners.pop_front()
	var flashing := false
	for i in _flash.size():
		_flash[i] = maxf(0.0, _flash[i] - delta)
		flashing = flashing or _flash[i] > 0.0
	# Banners fade, a refused slot burns red, the last half minute pulses and a marker follows its messenger (v0.08):
	# while any of those is on screen the HUD is an animation and redraws every frame. The rest of the time it is a
	# still picture.
	if flashing or not _banners.is_empty() or _rules.time_left <= HURRY_AT or marker_shown():
		_drawn = ""
		queue_redraw()
		return
	var now := _signature()
	if now != _drawn:
		_drawn = now
		queue_redraw()


## "Destroy the Royal Citadel - 60% left", the spec's objective line.
func objective_text() -> String:
	var left := 0.0
	if is_instance_valid(_town) and is_instance_valid(_town.citadel):
		left = _town.citadel.fraction()
	return "Destroy the Royal Citadel - %d%% left" % roundi(left * 100.0)


## The objective panel of a mission without a score (v0.08), as [text, mark] rows: each primary objective with a line
## to show (mark ""), then each bonus -- "ok" while it holds, "x" once it has failed.
func objective_rows() -> Array:
	var rows := []
	for o in _rules.objectives:
		var s := o.hud_text(_rules)
		if s != "":
			rows.append([s, ""])
	for b in _rules.bonuses:
		rows.append([b.hud_text(_rules), "x" if b.check(_rules) == Objective.Status.FAILED else "ok"])
	return rows


## The act's next two timed events (v0.09) as [clock, label] rows, e.g. ["0:23", "The bonfire lights"]; empty for a
## mission whose director keeps no timeline.
func event_rows() -> Array:
	var rows := []
	if _rules.director == null or _rules.director.timeline == null:
		return rows
	for e: Dictionary in _rules.director.timeline.upcoming(2):
		rows.append([UiTheme.clock(float(e["in"])), String(e["label"])])
	return rows


## The escapes that lose this act (v0.09): its EscapeLimitObjective's limit (Act III's is 40 when the Prince escaped),
## else the single missions' 50.
func escape_limit() -> int:
	for o in _rules.objectives:
		if o is EscapeLimitObjective:
			return (o as EscapeLimitObjective).limit
	return Rules.ESCAPE_LIMIT


## The mission's director marks someone (v0.08: The Warning's messenger).
func marker_shown() -> bool:
	return _rules.director != null and _rules.director.marker() != Vector2.INF


## Where the marked person's feet are on the screen, or Vector2.INF with nobody marked. The world point goes through
## the camera's canvas transform (none before the HUD is in a tree: headless tests).
func marker_screen() -> Vector2:
	if not marker_shown():
		return Vector2.INF
	var world := Iso.ground_to_screen(_rules.director.marker())
	return (get_viewport().get_canvas_transform() if is_inside_tree() else Transform2D.IDENTITY) * world


## Where the edge arrow for an off-screen `point` sits: on the line from the screen's centre to it, EDGE_MARGIN inside
## the frame.
func edge_arrow(point: Vector2) -> Vector2:
	var view := _view()
	var mid := view * 0.5
	var d := point - mid
	var half := mid - Vector2.ONE * EDGE_MARGIN
	var k := 1.0
	if absf(d.x) > half.x:
		k = half.x / absf(d.x)
	if absf(d.y) * k > half.y:
		k = half.y / absf(d.y)
	return mid + d * k


## The screen's size: the Control's once laid out, else 640 x 360.
func _view() -> Vector2:
	return Vector2(size.x if size.x > 1.0 else SCREEN_W, size.y if size.y > 1.0 else SCREEN_H)


## The city's state, top right, as [text, colour] pieces: each figure wears the colour of the stability part it
## drives, so the player can tell which number moves which part of the bar.
## The alarm stage's colour on the status line (v0.04), calm to red.
const STAGE_COLS := [Color("9a9484"), Color("e8e2d0"), Color("d8b23a"), Color("ff8a3a"), Color("c8342a"), Color("ff4a4a")]


func status_segments() -> Array:
	return [
		["Citizens %d" % _crowd.alive_citizens(), UiTheme.STABILITY_COLS[0]],
		["Soldiers %d" % _crowd.alive_soldiers(), UiTheme.STABILITY_COLS[3]],
		["Destroyed %d" % _rules.buildings_down, UiTheme.STABILITY_COLS[1]],
		[_crowd.alarms.stage_name(), STAGE_COLS[_crowd.alarms.stage]],
	]


func status_text() -> String:
	var parts := PackedStringArray()
	for seg: Array in status_segments():
		parts.append(String(seg[0]))
	return "   ".join(parts)


## What a slot is: ready to cast, waiting out a cooldown, or waiting for the power now playing. Being the picked one is a separate
## question -- a picked slot still has to show its own cooldown, which it did not when this answered "picked".
func slot_state(slot: int) -> String:
	var reason := _rules.refusal(slot)
	return "ready" if reason == "" else reason


## Is this the slot the player has picked?
func is_picked(slot: int) -> bool:
	return _aim != null and _aim.slot == slot


## Where slot `i` is drawn -- the one geometry both the drawing and the mouse use.
func slot_rect(i: int) -> Rect2:
	var w := size.x if size.x > 1.0 else SCREEN_W
	var count := _rules.loadout.size()
	var total := float(count) * SLOT_W + float(maxi(count - 1, 0)) * SLOT_GAP
	var left := roundf((w - total) * 0.5)
	return Rect2(Vector2(left + float(i) * (SLOT_W + SLOT_GAP), SLOT_TOP), Vector2(SLOT_W, SLOT_SIZE))


## The power's name in slot `i` as its card shows it, cut to one line (taken once in setup()).
func slot_name(i: int) -> String:
	return _slot_names[i] if i >= 0 and i < _slot_names.size() else ""


## The slot under a screen point, or -1.
func slot_at(point: Vector2) -> int:
	for i in _rules.loadout.size():
		if slot_rect(i).has_point(point):
			return i
	return -1


func push_banner(text: String) -> void:
	_banners.append([text, 0.0])


func banners() -> PackedStringArray:
	var out := PackedStringArray()
	for b in _banners:
		out.append(String(b[0]))
	return out


## Is this slot still red from a cast it could not take?
func flashing(slot: int) -> bool:
	return slot >= 0 and slot < _flash.size() and _flash[slot] > 0.0


func _on_cast_refused(slot: int, reason: String) -> void:
	if slot >= 0 and slot < _flash.size():
		_flash[slot] = FLASH_SECONDS
	if reason == "nobody":
		push_banner("NO ONE TO WHISPER TO")
	elif reason == "shaken":
		push_banner("THEY SHAKE OFF THE WHISPER")
	UiSound.play(&"ui_buzz")


## Everything the HUD shows, as one string. Cheap to build, and it means a still frame is not redrawn sixty
## times a second while a four-minute mission's effects are already busy.
func _signature() -> String:
	var out := "%s|%s|%s|%d|%s" % [UiTheme.clock(_rules.time_left),
		objective_text() if _rules.mission.scored else str(objective_rows()), status_text(),
		roundi(_rules.stability.total() * 200.0), rite_text()]
	var events := event_rows()
	if not events.is_empty():
		out += "|" + str(events)
	for i in _rules.loadout.size():
		out += "%s%d%s," % [slot_state(i), roundi(_rules.cooldown_left(i) * 4.0), "p" if is_picked(i) else ""]
	return out


func _draw() -> void:
	# Before the first layout pass a Control can still be 0 wide, and this one is centred on the screen.
	var w := size.x if size.x > 1.0 else get_viewport_rect().size.x
	_draw_clock(w)
	_draw_rite(w)
	_draw_events(w)
	if _rules.mission.scored:
		_draw_objectives()
	else:
		_draw_rows()
	_draw_status(w)
	_draw_banners(w)
	_draw_slots(w)
	# Last, over the slots and banners: an arrow for someone below the screen lands on the slot row.
	_draw_marker()


func _draw_clock(w: float) -> void:
	var s := UiTheme.clock(_rules.time_left)
	var col := UiTheme.COL_TEXT
	if _rules.time_left <= HURRY_AT:
		# One pulse a second, so the last half minute is felt without a tween.
		col = UiTheme.COL_BAD if fmod(_rules.time_left, 1.0) > 0.5 else Color("ff8a72")
	UiTheme.text(self, Vector2(roundf((w - UiTheme.width(s, UiTheme.SIZE_BIG)) * 0.5), 18.0), s, UiTheme.SIZE_BIG, col)


## The Banishing Rite under the clock: the clergy gathering, then the rite's progress in RITE_BAR's steps; "" when
## there is nothing to show.
func rite_text() -> String:
	var rite := _crowd.rite if _crowd != null else null
	if rite == null:
		return ""
	match rite.state:
		BanishingRite.State.GATHERING:
			return "CLERGY GATHER %d/%d" % [mini(rite.in_ring(), BanishingRite.NEED), BanishingRite.NEED]
		BanishingRite.State.CHANTING:
			return "BANISHING RITE %d" % floori(rite.fraction() * RITE_BAR.x)
	return ""


func _draw_rite(w: float) -> void:
	var rite := _crowd.rite if _crowd != null else null
	if rite_text() == "":
		return
	var chanting := rite.state == BanishingRite.State.CHANTING
	var label := "BANISHING RITE" if chanting else rite_text()
	var plate_w := maxf(RITE_BAR.x, UiTheme.width(label, UiTheme.SIZE_SMALL)) + 8.0
	draw_rect(Rect2(roundf((w - plate_w) * 0.5), RITE_TOP - 8.0, plate_w, 17.0 if chanting else 11.0), UiTheme.COL_PANEL)
	UiTheme.text(self, Vector2(roundf((w - UiTheme.width(label, UiTheme.SIZE_SMALL)) * 0.5), RITE_TOP),
		label, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD if chanting else UiTheme.COL_DIM)
	if chanting:
		var at := Vector2(roundf((w - RITE_BAR.x) * 0.5), RITE_TOP + 3.0)
		draw_rect(Rect2(at - Vector2.ONE, RITE_BAR + Vector2(2.0, 2.0)), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(at, Vector2(roundf(RITE_BAR.x * rite.fraction()), RITE_BAR.y)), UiTheme.COL_GOLD)


## The next timed events (v0.09), centred on a plate under the clock: the time dim, the label light.
func _draw_events(w: float) -> void:
	var rows := event_rows()
	if rows.is_empty():
		return
	var wide := 0.0
	for row: Array in rows:
		wide = maxf(wide, UiTheme.width(String(row[0]) + "  " + String(row[1]), UiTheme.SIZE_SMALL))
	# The plate starts 4 px above EVENTS_TOP, just under the rite's plate (which ends at 39 while it chants).
	var top := EVENTS_TOP - 4.0
	draw_rect(Rect2(roundf((w - wide) * 0.5) - 4.0, top, wide + 8.0, 5.0 + ROW_H * float(rows.size())), UiTheme.COL_PANEL)
	var y := top + 12.0
	for row: Array in rows:
		var clock := String(row[0])
		var x := roundf((w - wide) * 0.5)
		UiTheme.text(self, Vector2(x, y), clock, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		UiTheme.text(self, Vector2(x + UiTheme.width(clock + "  ", UiTheme.SIZE_SMALL), y), String(row[1]), UiTheme.SIZE_SMALL)
		y += ROW_H


func _draw_objectives() -> void:
	draw_rect(OBJECTIVE_PANEL, UiTheme.COL_PANEL)
	UiTheme.text(self, Vector2(6.0, 14.0), objective_text(), UiTheme.SIZE_SMALL)
	# The five-colour stability bar: one segment per part, each as wide as its weight.
	var at := Vector2(6.0, 21.0)
	var parts := [[_rules.stability.population, Stability.W_POPULATION],
		[_rules.stability.infrastructure, Stability.W_INFRASTRUCTURE],
		[_rules.stability.leadership, Stability.W_LEADERSHIP],
		[_rules.stability.military, Stability.W_MILITARY],
		[_rules.stability.resources, Stability.W_RESOURCES]]
	draw_rect(Rect2(at, STABILITY_BAR), Color(0, 0, 0, 0.6))
	var x := at.x
	for i in parts.size():
		var part: Array = parts[i]
		var full := STABILITY_BAR.x * float(part[1])
		draw_rect(Rect2(Vector2(x, at.y), Vector2(full * float(part[0]), STABILITY_BAR.y)), UiTheme.STABILITY_COLS[i])
		x += full
	UiTheme.text(self, Vector2(at.x + STABILITY_BAR.x + 5.0, at.y + 6.0),
		"Stability %d%%" % roundi(_rules.stability.total() * 100.0), UiTheme.SIZE_SMALL)
	# The legend: a swatch and a short name for each part, in the bar's order.
	var lx := 6.0
	for entry: Array in LEGEND:
		draw_rect(Rect2(lx, 31.0, 5.0, 5.0), UiTheme.STABILITY_COLS[int(entry[1])])
		UiTheme.text(self, Vector2(lx + 7.0, 38.0), String(entry[0]), UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		lx += 7.0 + UiTheme.width(String(entry[0]), UiTheme.SIZE_SMALL) + 8.0
	var count := _rules.escaped_this_act()
	var limit := escape_limit()
	var escaped := "Escaped %d / %d" % [count, limit]
	var col := UiTheme.COL_BAD if count >= limit - 8 else UiTheme.COL_DIM
	UiTheme.text(self, Vector2(6.0, 54.0), escaped, UiTheme.SIZE_SMALL, col)


## The objective panel of a mission without a score (v0.08): objective_rows(), each with its tick or cross after it.
func _draw_rows() -> void:
	var rows := objective_rows()
	if rows.is_empty():
		return
	var wide := 0.0
	for row: Array in rows:
		wide = maxf(wide, UiTheme.width(String(row[0]), UiTheme.SIZE_SMALL) + (12.0 if String(row[1]) != "" else 0.0))
	draw_rect(Rect2(2.0, 2.0, wide + 10.0, 5.0 + ROW_H * float(rows.size())), UiTheme.COL_PANEL)
	var y := 14.0
	for row: Array in rows:
		var text := String(row[0])
		UiTheme.text(self, Vector2(6.0, y), text, UiTheme.SIZE_SMALL)
		if String(row[1]) != "":
			UiTheme.mark(self, Vector2(6.0 + UiTheme.width(text, UiTheme.SIZE_SMALL) + 5.0, y - 7.0), String(row[1]) == "ok")
		y += ROW_H


## The messenger's marker (v0.08): a gold chevron over him while he is on screen, else an arrow at the screen's edge
## pointing his way.
func _draw_marker() -> void:
	var feet := marker_screen()
	if feet == Vector2.INF:
		return
	var view := _view()
	var tip := feet - Vector2(0.0, MARKER_LIFT)
	var dark := Color(0.04, 0.04, 0.06, 0.9)
	if Rect2(Vector2.ZERO, view).grow(-EDGE_MARGIN).has_point(tip):
		var down := PackedVector2Array([tip + Vector2(-5.0, -7.0), tip + Vector2(5.0, -7.0), tip])
		draw_colored_polygon(down, UiTheme.COL_GOLD)
		down.append(down[0])
		draw_polyline(down, dark, -1.0)
		return
	var at := edge_arrow(tip)
	var dir := (tip - view * 0.5).normalized()
	var side := Vector2(-dir.y, dir.x)
	# On a dark disc, so it stands out from the town's warm roofs and stalls.
	draw_circle(at - dir * 5.0, 10.0, dark)
	draw_arc(at - dir * 5.0, 10.0, 0.0, TAU, 24, UiTheme.COL_GOLD_DARK, -1.0)
	var arrow := PackedVector2Array([at, at - dir * 10.0 + side * 6.0, at - dir * 10.0 - side * 6.0])
	draw_colored_polygon(arrow, UiTheme.COL_GOLD)
	arrow.append(arrow[0])
	draw_polyline(arrow, dark, -1.0)


func _draw_status(w: float) -> void:
	var gap := UiTheme.width("   ", UiTheme.SIZE_SMALL)
	var segs := status_segments()
	var total := gap * float(segs.size() - 1)
	for seg: Array in segs:
		total += UiTheme.width(String(seg[0]), UiTheme.SIZE_SMALL)
	var x := w - total - 6.0
	for seg: Array in segs:
		UiTheme.text(self, Vector2(x, 14.0), String(seg[0]), UiTheme.SIZE_SMALL, seg[1])
		x += UiTheme.width(String(seg[0]), UiTheme.SIZE_SMALL) + gap


func _draw_banners(w: float) -> void:
	if _banners.is_empty():
		return
	var text := String(_banners[0][0])
	var age := float(_banners[0][1])
	var fade := clampf((BANNER_SECONDS - age) / 0.4, 0.0, 1.0)
	var col := UiTheme.COL_GOLD
	col.a = fade
	var text_w := UiTheme.width(text, UiTheme.SIZE_BIG)
	var x := roundf((w - text_w) * 0.5)
	# A banner announces something that is happening right now, which means it lands on top of the effect that
	# caused it. On its own bar with a gold edge it stays readable over lightning or a wave.
	var bar := Rect2(x - 8.0, 116.0, text_w + 16.0, 20.0)
	draw_rect(bar, Color(0.03, 0.03, 0.05, 0.78 * fade))
	var edge := UiTheme.COL_GOLD_DARK
	edge.a = fade
	draw_rect(bar, edge, false, -1.0)
	UiTheme.text(self, Vector2(x, 131.0), text, UiTheme.SIZE_BIG, col)


func _draw_slots(_w: float) -> void:
	for i in _rules.loadout.size():
		var box := slot_rect(i)
		var icon_box := Rect2(box.position, Vector2(SLOT_SIZE, SLOT_SIZE))
		var state := slot_state(i)
		var usable := state == "ready"
		draw_rect(box, UiTheme.COL_PANEL)
		if flashing(i):
			var red := UiTheme.COL_BAD
			red.a = _flash[i] / FLASH_SECONDS
			draw_rect(box, red)
		var icon: Texture2D = _slot_icons[i] if i < _slot_icons.size() else null
		if icon != null:
			draw_texture_rect(icon, icon_box, false, Color.WHITE if usable else Color(0.45, 0.45, 0.5))
		UiTheme.frame(self, box, is_picked(i))
		_plate(icon_box.position + Vector2(1.0, 1.0), "%d" % (i + 1), UiTheme.COL_TEXT)
		# The name beside the icon on one line, gold when focused, dim when it cannot be cast; its cooldown under it.
		var tx := box.position.x + SLOT_SIZE + 4.0
		var name_col := UiTheme.COL_GOLD if is_picked(i) else (UiTheme.COL_TEXT if usable else UiTheme.COL_DIM)
		UiTheme.text(self, Vector2(tx, box.position.y + 14.0), slot_name(i), UiTheme.SIZE_SMALL, name_col)
		UiTheme.text(self, Vector2(tx, box.position.y + 14.0 + UiTheme.LINE_SMALL),
			PrepareScreen.cooldown_text(_rules.power(i)), UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		if state == "busy":
			# Another power is still playing: a light shade and its seconds left, in gold.
			draw_rect(Rect2(box.position, Vector2(SLOT_W, SLOT_SIZE)), Color(0, 0, 0, 0.35))
			var wait := "%d" % ceili(_rules.busy_left())
			UiTheme.text(self, icon_box.get_center() + Vector2(-UiTheme.width(wait) * 0.5, 4.0), wait, UiTheme.SIZE_BODY,
				UiTheme.COL_GOLD)
		if state == "cooldown":
			# The cooldown as a shade falling away from the top of the card, its seconds over the icon.
			var left := _rules.cooldown_left(i)
			var frac := clampf(left / maxf(float(_rules.power(i).cooldown), 0.001), 0.0, 1.0)
			draw_rect(Rect2(box.position, Vector2(SLOT_W, SLOT_SIZE * frac)), Color(0, 0, 0, 0.6))
			var secs := "%d" % ceili(left)
			UiTheme.text(self, icon_box.get_center() + Vector2(-UiTheme.width(secs) * 0.5, 4.0), secs, UiTheme.SIZE_BODY)


## A short label on a dark plate, `at` being the plate's top-left corner.
func _plate(at: Vector2, label: String, col: Color) -> void:
	var w := UiTheme.width(label, UiTheme.SIZE_SMALL)
	draw_rect(Rect2(at, Vector2(w + 2.0, PLATE_H)), Color(0, 0, 0, 0.62))
	UiTheme.text(self, at + Vector2(1.0, PLATE_H - 3.0), label, UiTheme.SIZE_SMALL, col)
