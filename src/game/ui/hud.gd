class_name Hud
extends Control
## The in-mission HUD (spec §5): the clock above, the objectives to the left, the city's state to the right,
## banners across the middle, and the Divine Power bar with the four slots below. It reads Rules, Crowd and
## the Citadel and changes nothing; it redraws only when what it shows has changed.

## How long one banner stays up.
const BANNER_SECONDS := 2.2
## A +DP popup drifts up for this long.
const POPUP_SECONDS := 1.2
## A slot that refused a cast stays red for this long (spec §1; the buzz that goes with it is milestone 5's).
const FLASH_SECONDS := 0.35
## The clock turns red and pulses under this many seconds (spec §5).
const HURRY_AT := 30.0

const SLOT_SIZE := 42.0
const SLOT_GAP := 6.0
## The screen width to lay out against before the Control has been sized (headless tests).
const SCREEN_W := 640.0
## Where the slot row sits.
const SLOT_TOP := 312.0
const STABILITY_BAR := Vector2(96.0, 5.0)
## The objectives, top left: sized for four lines of SIZE_SMALL text.
const OBJECTIVE_PANEL := Rect2(2.0, 2.0, 236.0, 60.0)
## The stability bar's legend: a short name for each part and its colour's index, in the bar's own order.
const LEGEND := [["Pop", 0], ["Infra", 1], ["Lead", 2], ["Mil", 3], ["Res", 4]]
## The dark plate under a slot's hotkey and cost.
const PLATE_H := 12.0
const DP_BAR := Vector2(180.0, 7.0)

var _rules: Rules
var _crowd: Crowd
var _town: Town
var _aim: Targeting
## Banners waiting their turn: [text, seconds shown].
var _banners: Array = []
## Floating gains: [text, screen position, seconds shown].
var _popups: Array = []
## Seconds of red left per slot, for the refused-cast flash.
var _flash := PackedFloat32Array()
## What the last frame drew, so an unchanged HUD costs nothing.
var _drawn := ""
## The four slot icons, taken once. PowerBook.hud_icon() goes through load(), and a texture asked for during
## _draw() can reach the draw list before the GPU has it -- which paints a solid white block, and because the
## HUD only redraws when something changes, the block stays white for the rest of the mission.
var _slot_icons: Array[Texture2D] = []


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
	_rules.banner.connect(push_banner)
	_rules.dp_gained.connect(_on_dp_gained)
	_rules.cast_refused.connect(_on_cast_refused)
	return self


func _process(delta: float) -> void:
	advance(delta)


## Age the banners and popups, and redraw when anything on screen has changed.
func advance(delta: float) -> void:
	# Only the one on screen (index 0, the only one _draw_banners() ever reads) ages: a banner waiting behind
	# it must not lose part of its own showing to the time it spent queued.
	if not _banners.is_empty():
		_banners[0][1] += delta
	while not _banners.is_empty() and float(_banners[0][1]) >= BANNER_SECONDS:
		_banners.pop_front()
	for p in _popups:
		p[2] += delta
	var kept: Array = []
	for p in _popups:
		if float(p[2]) < POPUP_SECONDS:
			kept.append(p)
	_popups = kept
	var flashing := false
	for i in _flash.size():
		_flash[i] = maxf(0.0, _flash[i] - delta)
		flashing = flashing or _flash[i] > 0.0
	# Banners fade, popups drift, a refused slot burns red and the last half minute pulses: while any of those
	# is on screen the HUD is an animation and redraws every frame. The rest of the time it is a still picture.
	if flashing or not _banners.is_empty() or not _popups.is_empty() or _rules.time_left <= HURRY_AT:
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


## The city's state, top right, as [text, colour] pieces: each figure wears the colour of the stability part it
## drives, so the player can tell which number moves which part of the bar.
func status_segments() -> Array:
	return [
		["Citizens %d" % _crowd.alive_citizens(), UiTheme.STABILITY_COLS[0]],
		["Soldiers %d" % _crowd.alive_soldiers(), UiTheme.STABILITY_COLS[3]],
		["Destroyed %d" % _rules.buildings_down, UiTheme.STABILITY_COLS[1]],
		["Alarm %d%%" % roundi(_crowd.alarm), UiTheme.COL_TEXT],
	]


func status_text() -> String:
	var parts := PackedStringArray()
	for seg: Array in status_segments():
		parts.append(String(seg[0]))
	return "   ".join(parts)


## What a slot is: ready to cast, waiting out a cooldown, or unaffordable. Being the picked one is a separate
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
	var total := float(count) * SLOT_SIZE + float(maxi(count - 1, 0)) * SLOT_GAP
	var left := roundf((w - total) * 0.5)
	return Rect2(Vector2(left + float(i) * (SLOT_SIZE + SLOT_GAP), SLOT_TOP), Vector2(SLOT_SIZE, SLOT_SIZE))


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


func _on_cast_refused(slot: int, _reason: String) -> void:
	if slot >= 0 and slot < _flash.size():
		_flash[slot] = FLASH_SECONDS
	UiSound.play(&"ui_buzz")


func _on_dp_gained(amount: float, at: Vector2) -> void:
	_popups.append(["+%.1f" % amount, Iso.ground_to_screen(at), 0.0])


## Everything the HUD shows, as one string. Cheap to build, and it means a still frame is not redrawn sixty
## times a second while a four-minute mission's effects are already busy.
func _signature() -> String:
	var out := "%s|%s|%s|%d|%d" % [UiTheme.clock(_rules.time_left), objective_text(), status_text(),
		roundi(_rules.dp * 2.0), roundi(_rules.stability.total() * 200.0)]
	for i in _rules.loadout.size():
		out += "%s%d%s," % [slot_state(i), roundi(_rules.cooldown_left(i) * 4.0), "p" if is_picked(i) else ""]
	return out


func _draw() -> void:
	# Before the first layout pass a Control can still be 0 wide, and this one is centred on the screen.
	var w := size.x if size.x > 1.0 else get_viewport_rect().size.x
	_draw_clock(w)
	_draw_objectives()
	_draw_status(w)
	_draw_banners(w)
	_draw_dp(w)
	_draw_slots(w)
	_draw_popups()


func _draw_clock(w: float) -> void:
	var s := UiTheme.clock(_rules.time_left)
	var col := UiTheme.COL_TEXT
	if _rules.time_left <= HURRY_AT:
		# One pulse a second, so the last half minute is felt without a tween.
		col = UiTheme.COL_BAD if fmod(_rules.time_left, 1.0) > 0.5 else Color("ff8a72")
	UiTheme.text(self, Vector2(roundf((w - UiTheme.width(s, UiTheme.SIZE_BIG)) * 0.5), 18.0), s, UiTheme.SIZE_BIG, col)


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
	var escaped := "Escaped %d / %d" % [_crowd.escaped_count, Rules.ESCAPE_LIMIT]
	var col := UiTheme.COL_BAD if _crowd.escaped_count >= Rules.ESCAPE_LIMIT - 8 else UiTheme.COL_DIM
	UiTheme.text(self, Vector2(6.0, 54.0), escaped, UiTheme.SIZE_SMALL, col)


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


func _draw_dp(w: float) -> void:
	var at := Vector2(roundf((w - DP_BAR.x) * 0.5), 300.0)
	draw_rect(Rect2(at - Vector2.ONE, DP_BAR + Vector2(2.0, 2.0)), Color(0, 0, 0, 0.7))
	var frac := clampf(_rules.dp / Rules.DP_MAX, 0.0, 1.0)
	var col := UiTheme.COL_DP if _rules.dp >= 20.0 else UiTheme.COL_DP_LOW
	draw_rect(Rect2(at, Vector2(DP_BAR.x * frac, DP_BAR.y)), col)
	UiTheme.text(self, Vector2(at.x + DP_BAR.x + 5.0, at.y + DP_BAR.y), "%d DP" % roundi(_rules.dp),
		UiTheme.SIZE_SMALL)


func _draw_slots(_w: float) -> void:
	for i in _rules.loadout.size():
		var box := slot_rect(i)
		var state := slot_state(i)
		draw_rect(box, UiTheme.COL_PANEL)
		if flashing(i):
			var red := UiTheme.COL_BAD
			red.a = _flash[i] / FLASH_SECONDS
			draw_rect(box, red)
		var icon: Texture2D = _slot_icons[i] if i < _slot_icons.size() else null
		if icon != null:
			# Greyed while it cannot be cast, so the player reads the row at a glance.
			draw_texture_rect(icon, box, false, Color(0.45, 0.45, 0.5) if state in ["cooldown", "dp"] else Color.WHITE)
		# Gold only for the picked slot (spec §5): when every affordable slot wore it, the pick was invisible.
		UiTheme.frame(self, box, is_picked(i))
		# The hotkey and the cost sit on their own dark plates: painted icons are busy, and a bare glyph over one
		# of them is a smudge at this size.
		_plate(box.position + Vector2(1.0, 1.0), "%d" % (i + 1), UiTheme.COL_TEXT)
		var cost := "%d" % _rules.cost(i)
		var cost_w := UiTheme.width(cost, UiTheme.SIZE_SMALL)
		_plate(box.position + Vector2(SLOT_SIZE - cost_w - 3.0, SLOT_SIZE - PLATE_H - 1.0), cost,
			UiTheme.COL_BAD if state == "dp" else UiTheme.COL_TEXT)
		if state == "cooldown":
			# The cooldown as a shade falling away from the top, with its seconds over it.
			var left := _rules.cooldown_left(i)
			var frac := clampf(left / maxf(float(_rules.power(i).cooldown), 0.001), 0.0, 1.0)
			draw_rect(Rect2(box.position, Vector2(SLOT_SIZE, SLOT_SIZE * frac)), Color(0, 0, 0, 0.6))
			var secs := "%d" % ceili(left)
			UiTheme.text(self, box.get_center() + Vector2(-UiTheme.width(secs) * 0.5, 4.0), secs, UiTheme.SIZE_BODY)


## A short label on a dark plate, `at` being the plate's top-left corner.
func _plate(at: Vector2, label: String, col: Color) -> void:
	var w := UiTheme.width(label, UiTheme.SIZE_SMALL)
	draw_rect(Rect2(at, Vector2(w + 2.0, PLATE_H)), Color(0, 0, 0, 0.62))
	UiTheme.text(self, at + Vector2(1.0, PLATE_H - 3.0), label, UiTheme.SIZE_SMALL, col)


func _draw_popups() -> void:
	for p in _popups:
		var age := float(p[2])
		var col := UiTheme.COL_DP
		col.a = clampf((POPUP_SECONDS - age) / 0.5, 0.0, 1.0)
		# The popup belongs to the place the DP came from, so its stored world pixel is put through the
		# camera's transform: the HUD's own layer does not move with the camera.
		var at: Vector2 = get_viewport().get_canvas_transform() * Vector2(p[1])
		UiTheme.text(self, at - Vector2(0.0, age * 14.0), String(p[0]), UiTheme.SIZE_SMALL, col)
