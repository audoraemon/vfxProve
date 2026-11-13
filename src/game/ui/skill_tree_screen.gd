class_name SkillTreeScreen
extends Node
## The Skill Tree as a wheel (spec 2026-11-10): one Authority centred as five oval tier rings with two powers on each, the other two
## Authorities (the god's ring neighbours; far types never shown) as dim side panels, and a detail panel along the bottom with the
## selected power's looping preview clip, what it is, what its next level changes and two buttons. A click on a power only selects it;
## points are spent by the gold button. A neighbour's powers cost double. The screen edits the GodSlot it is given and emits
## "learned" so Game writes the slot, "remember" to try the selected power free in a city, and "back" (Esc or Back).

## "learned" (a point was spent: Game writes the slot), "remember" (try the selected power) or "back".
signal action(name: String)

const BACK_RECT := Rect2(6.0, 4.0, 40.0, 18.0)
const REMEMBER_RECT := Rect2(528.0, 263.0, 96.0, 30.0)
const BUY_RECT := Rect2(528.0, 298.0, 96.0, 30.0)
## The detail panel (the wheel's DETAIL strip): the clip box, the info column, the level column and the buttons sit inside it.
const DETAIL := TreeWheel.DETAIL
const CLIP_BOX := Rect2(15.0, 258.0, 152.0, 86.0)
const INFO_X := 176.0
const INFO_W := TreeDetail.DESCRIPTION_W
const LEVEL_X := 387.0
const LEVEL_W := 132.0
## A side panel's small icons: a 2x5 grid of MINI_PX squares.
const MINI_PX := 18.0
## How long a refusal's reason stays up.
const REFUSE_SECONDS := 1.5
## What a refused click says, by GodSlot.refusal(); "tier" takes the spot's tier.
const REFUSALS := TreeDetail.REFUSALS

const COL_REMEMBER := Color("6fa8c8")
const COL_SELECT := Color("fff3c4")
const COL_NODE := Color("100c18")
const COL_GREEN := Color("9fe08a")
const COL_TWIST := Color("e9c96a")
const NODE_NAME_PX := 9
## A node's name label: centred under the node, this wide at most (every power name fits, none is chopped).
const NODE_NAME_W := 84.0
const SMALL_PX := 9

## Why the last buy learned nothing, shown for REFUSE_SECONDS; "" for none.
var refused_reason := ""
## Which of columns() is on the wheel (0-2), and the selected spot (column, tier 1-5, i) or (-1, -1, -1).
var centred := 1
var selected := Vector3i(-1, -1, -1)

var _refuse_left := 0.0
var _slot: GodSlot
var _ui: Control
var _hover := ""
## The spots' icons, loaded once each in setup(), not in the draw (a texture first loaded inside a draw showed white for a frame);
## null for a power with none yet. _big holds the large icons and _clips the preview sheets, loaded when a power is selected.
var _icons := {}
var _big := {}
var _clips := {}
var _clip_time := 0.0
var _clip_shown := -1
var _wide_style: StyleBoxFlat


func setup(slot: GodSlot, p_state := {}) -> SkillTreeScreen:
	_slot = slot
	for col in columns().size():
		for tier in range(1, GodTree.TIERS + 1):
			for i in GodTree.PER_TIER:
				var key := key_at(col, tier, i)
				if key != "" and not _icons.has(key):
					_icons[key] = spot_icon(key)
	centred = maxi(columns().find(slot.type), 0)
	selected = _first_pick()
	if p_state.has("centred") and int(p_state.centred) >= 0 and int(p_state.centred) < columns().size():
		centred = int(p_state.centred)
	var want: Variant = p_state.get("selected")
	if want is Vector3i and (want as Vector3i).x >= 0 and (want as Vector3i).x < columns().size():
		selected = want
	_load_selected()
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	return self


## The three types shown, left to right: the god's left ring neighbour, its own type, its right neighbour. Far types never appear.
func columns() -> PackedStringArray:
	var near := GodTree.neighbours(_slot.type)
	if near.size() < 2:
		return PackedStringArray([_slot.type])
	return PackedStringArray([near[0], _slot.type, near[1]])


## The ability key in a spot ("" when empty).
func key_at(col: int, tier: int, i: int) -> String:
	var cols := columns()
	return GodTree.spot(cols[col], tier, i) if col >= 0 and col < cols.size() else ""


## The picture of an ability's spot: the HUD copy of its icon, else the full one; null when the power has none yet.
static func spot_icon(key: String) -> Texture2D:
	var hud := PowerBook.hud_icon(key)
	return hud if hud != null else PowerBook.icon(key)


# ------------------------------------------------------------------------------------------------ state

## Puts column `col` on the wheel (the selection stays where it was).
func centre(col: int) -> void:
	if col < 0 or col >= columns().size():
		return
	centred = col
	_redraw()


## Selects a spot (nothing is spent); an empty spot may be selected, it shows "Not yet chosen".
func select(col: int, tier: int, i: int) -> void:
	selected = Vector3i(col, tier, i)
	_load_selected()
	_redraw()


## The key of the selected spot, "" for none or an empty spot.
func selected_key() -> String:
	return key_at(selected.x, selected.y, selected.z) if selected.x >= 0 else ""


## What the next open of the screen restores: the centred Authority and the selected spot.
func state() -> Dictionary:
	return {"centred": centred, "selected": selected}


## The level Remembrance starts at: the selected power's learned level, else 1.
func remember_level() -> int:
	return maxi(_slot.level_of(selected_key()), 1)


## The first open's selection: the first power learned below level 5 in the god's own column (tier order), else the first one it
## can learn now, else its Tier I first spot.
func _first_pick() -> Vector3i:
	var own := maxi(columns().find(_slot.type), 0)
	for want_open in [false, true]:
		for tier in range(1, GodTree.TIERS + 1):
			for i in GodTree.PER_TIER:
				var key := key_at(own, tier, i)
				if key == "":
					continue
				var have := _slot.level_of(key)
				if (not want_open and have > 0 and have < PowerBook.MAX_LEVEL) or (want_open and _slot.refusal(key) == ""):
					return Vector3i(own, tier, i)
	return Vector3i(own, 1, 0)


## Loads the selected power's clip and large icon (never inside a draw) and restarts its loop.
func _load_selected() -> void:
	_clip_time = 0.0
	_clip_shown = -1
	var key := selected_key()
	if key == "":
		return
	if not _clips.has(key):
		_clips[key] = PowerBook.clip(key)
	if not _big.has(key):
		var big := PowerBook.icon(key)
		_big[key] = big if big != null else spot_icon(key)


## The state of a spot on the wheel: "empty", "learned", "can" (buyable now), "poor" (open but not buyable now), "lock" (tier above
## the god's).
func node_state(col: int, tier: int, i: int) -> String:
	var key := key_at(col, tier, i)
	if key == "":
		return "empty"
	if _slot.level_of(key) > 0:
		return "learned"
	var why := _slot.refusal(key)
	if why == "":
		return "can"
	return "lock" if why == "tier" else "poor"


# ------------------------------------------------------------------------------------------------ layout

## The chip of column `col` in the top bar: the three chips are centred together, the centred one wider.
func chip_rect(col: int) -> Rect2:
	var cols := columns()
	var widths: Array[float] = []
	var total := 3.0 * (cols.size() - 1)
	for c in cols.size():
		var w := UiTheme.width(_chip_title(c), SIZE_CHIP if c == centred else SMALL_PX + 1) + (28.0 if c == centred else 18.0)
		if c != centred and cols[c] != _slot.type:
			w += UiTheme.width(" x2", SMALL_PX - 1)
		widths.append(w)
		total += w
	var x := 320.0 - total * 0.5
	for c in cols.size():
		if c == col:
			return Rect2(x, 4.0, widths[c], 18.0)
		x += widths[c] + 3.0
	return Rect2()


const SIZE_CHIP := 12


func _chip_title(col: int) -> String:
	return PowerBook.authority_title(columns()[col])


## The panel of the `side`-th (0-1) column that is not centred, in chip order.
func side_col(side: int) -> int:
	var seen := 0
	for c in columns().size():
		if c == centred:
			continue
		if seen == side:
			return c
		seen += 1
	return -1


## A node's name as its label shows it: whole, else cut at a letter with "..." so the cut is visible.
static func node_label(full: String) -> String:
	if UiTheme.width(full, NODE_NAME_PX) <= NODE_NAME_W:
		return full
	var out := full
	while out.length() > 1 and UiTheme.width(out + "...", NODE_NAME_PX) > NODE_NAME_W:
		out = out.substr(0, out.length() - 1)
	return out.strip_edges(false, true) + "..."


## Where a node's name sits: under the node; else beside it on its outer side (spot 0 right, spot 1 left), else above it -- the first
## place clear of every other node's circle.
static func node_label_rect(tier: int, i: int, text: String) -> Rect2:
	var p := TreeWheel.node_at(tier, i)
	var w := UiTheme.width(text, NODE_NAME_PX)
	var side := 1.0 if i == 0 else -1.0
	var spots := [Rect2(p.x - w * 0.5, p.y + TreeWheel.NODE_R + 2.0, w, 9.0),
		Rect2(p.x + side * (TreeWheel.NODE_R + 3.0) - (0.0 if side > 0.0 else w), p.y - 4.0, w, 9.0),
		Rect2(p.x - w * 0.5, p.y - TreeWheel.NODE_R - 11.0, w, 9.0)]
	for r: Rect2 in spots:
		var clear := true
		for t in range(1, GodTree.TIERS + 1):
			for k in GodTree.PER_TIER:
				if (t != tier or k != i) and r.intersects(Rect2(TreeWheel.node_at(t, k) - Vector2.ONE * TreeWheel.NODE_R, Vector2.ONE * TreeWheel.NODE_R * 2.0)):
					clear = false
		if clear:
			return r
	return spots[0]


static func side_rect(side: int) -> Rect2:
	return TreeWheel.SIDE_L if side == 0 else TreeWheel.SIDE_R


## The small icon of tier 1-5, spot i (0-1) inside a side panel.
static func mini_rect(panel: Rect2, tier: int, i: int) -> Rect2:
	return Rect2(Vector2(panel.get_center().x - 23.0 + float(i) * 28.0, panel.position.y + 64.0 + float(tier - 1) * 23.0),
		Vector2(MINI_PX, MINI_PX))


## The points box in the top bar.
func points_rect() -> Rect2:
	var w := 28.0 + UiTheme.width("Ability points", SMALL_PX) + UiTheme.width(str(_slot.points), UiTheme.SIZE_BODY)
	return Rect2(632.0 - w, 4.0, w, 18.0)


## What is under a point: "back", "chip:<col>", "remember", "buy", "node:<tier>:<i>", "mini:<col>:<tier>:<i>", "side:<col>" or "".
func hit(point: Vector2) -> String:
	if BACK_RECT.has_point(point):
		return "back"
	for c in columns().size():
		if chip_rect(c).has_point(point):
			return "chip:%d" % c
	if selected_key() != "":
		if REMEMBER_RECT.has_point(point):
			return "remember"
		if BUY_RECT.has_point(point):
			return "buy"
	var n := TreeWheel.node_hit(point)
	if n.x > 0:
		return "node:%d:%d" % [n.x, n.y]
	for side in 2:
		var col := side_col(side)
		if col < 0:
			continue
		var panel := side_rect(side)
		for tier in range(1, GodTree.TIERS + 1):
			for i in GodTree.PER_TIER:
				if mini_rect(panel, tier, i).has_point(point):
					return "mini:%d:%d:%d" % [col, tier, i]
		if panel.has_point(point):
			return "side:%d" % col
	return ""


# ------------------------------------------------------------------------------------------------ input

## A left click at a screen point: Back leaves, a chip or side panel centres, a node or small icon selects, the buttons act.
func click(point: Vector2) -> void:
	var h := hit(point)
	if h == "":
		return
	var p := h.split(":")
	match p[0]:
		"back":
			UiSound.play(&"ui_click")
			action.emit("back")
		"chip", "side":
			UiSound.play(&"ui_click")
			centre(int(p[1]))
		"node":
			UiSound.play(&"ui_click")
			select(centred, int(p[1]), int(p[2]))
		"mini":
			UiSound.play(&"ui_click")
			select(int(p[1]), int(p[2]), int(p[3]))
		"remember":
			UiSound.play(&"ui_click")
			action.emit("remember")
		"buy":
			_buy()


## Selects a spot and buys it (learns the power or raises it a level); returns GodSlot.refusal()'s code ("unknown", "far", "max",
## "tier", "points") when it cannot, or "" and emits "learned" when it did.
func learn_at(col: int, tier: int, i: int) -> String:
	select(col, tier, i)
	return _buy()


## Buys the selected spot. A refusal buzzes and says why for REFUSE_SECONDS.
func _buy() -> String:
	if selected.x < 0:
		return "unknown"
	var key := selected_key()
	var why := _slot.refusal(key)
	if why != "":
		UiSound.play(&"ui_buzz")
		refused_reason = String(REFUSALS.get(why, why))
		if why == "tier":
			refused_reason = refused_reason % selected.y
		_refuse_left = REFUSE_SECONDS
		_redraw()
		return why
	_slot.learn(key)
	UiSound.play(&"ui_manifest")
	refused_reason = ""
	_redraw()
	action.emit("learned")
	return ""


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var n := columns().size()
		match event.physical_keycode:
			KEY_ESCAPE:
				UiSound.play(&"ui_click")
				action.emit("back")
			KEY_Q:
				UiSound.play(&"ui_click")
				centre((centred + n - 1) % n)
			KEY_E:
				UiSound.play(&"ui_click")
				centre((centred + 1) % n)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := hit(event.position)
		if h != _hover:
			_hover = h
			if h != "":
				UiSound.play(&"ui_hover")
			_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click(event.position)


func _redraw() -> void:
	if _ui != null:
		_ui.queue_redraw()


func _process(delta: float) -> void:
	if _refuse_left > 0.0:
		_refuse_left -= delta
		if _refuse_left <= 0.0:
			refused_reason = ""
			_redraw()
	_clip_time += delta
	var frame := int(_clip_time * PowerBook.CLIP_FPS) % PowerBook.CLIP_FRAMES
	if frame != _clip_shown and _clips.get(selected_key()) != null:
		_clip_shown = frame
		_redraw()


# ------------------------------------------------------------------------------------------------ drawing

func _draw_ui() -> void:
	_draw_backdrop()
	_draw_top_bar()
	_draw_wheel()
	for side in 2:
		if side_col(side) >= 0:
			_draw_side(side)
	UiTheme.text(_ui, Vector2(10.0, 246.0), "Esc back    Q / E switch Authority", SMALL_PX, Color(UiTheme.COL_DIM, 0.7))
	_draw_detail()


func _draw_backdrop() -> void:
	var stops := [[0.0, Color("2a1d45")], [0.26, Color("160f26")], [0.55, Color("0b0912")], [1.0, Color("050408")]]
	_ui.draw_rect(Rect2(0, 0, 640, 360), stops[3][1])
	for k in range(45, 0, -1):
		var t := float(k) / 45.0
		var col: Color = stops[3][1]
		for s in 3:
			if t <= float(stops[s + 1][0]):
				col = (stops[s][1] as Color).lerp(stops[s + 1][1], (t - float(stops[s][0])) / (float(stops[s + 1][0]) - float(stops[s][0])))
				break
		_ui.draw_circle(Vector2(320.0, 133.0), 450.0 * t, col)
	for d: Array in [[77, 79, 0.35], [524, 50, 0.3], [435, 220, 0.3], [173, 209, 0.25], [288, 32, 0.2], [589, 187, 0.25], [38, 169, 0.3]]:
		_ui.draw_rect(Rect2(float(d[0]), float(d[1]), 1, 1), Color(0.8, 0.75, 1.0, float(d[2])))


func _draw_top_bar() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 26), Color(0, 0, 0, 0.45))
	_ui.draw_rect(BACK_RECT, Color(0.04, 0.04, 0.06, 0.85))
	UiTheme.frame(_ui, BACK_RECT, _hover == "back")
	_text_centred(BACK_RECT.get_center().x, BACK_RECT.position.y + 13.0, "< BACK", SMALL_PX,
		UiTheme.COL_GOLD if _hover == "back" else UiTheme.COL_TEXT)
	UiTheme.text(_ui, Vector2(54.0, 18.0), "SKILL TREE", UiTheme.SIZE_BODY, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(54.0 + UiTheme.width("SKILL TREE") + 6.0, 18.0), "Tier %d . level %d" % [_slot.tier, _slot.level], SMALL_PX,
		UiTheme.COL_DIM)
	var cols := columns()
	for c in cols.size():
		var r := chip_rect(c)
		var on := c == centred
		var hue := TreeWheel.color(cols[c])
		var hot := _hover == "chip:%d" % c
		_ui.draw_rect(r, hue.darkened(0.7) if on else Color(0.05, 0.04, 0.08, 0.8))
		_ui.draw_rect(r, hue if on else (hue.lightened(0.2) if hot else Color("2e2838")), false, 1.0)
		if on:
			_ui.draw_rect(r.grow(2.0), Color(hue, 0.18), false, 2.0)
		var title := _chip_title(c)
		var title_col := Color("efe3ff") if on else (UiTheme.COL_TEXT if hot else Color("7d7668"))
		var tw := UiTheme.width(title, SIZE_CHIP if on else SMALL_PX + 1)
		var x2 := 0.0 if (on or cols[c] == _slot.type) else UiTheme.width(" x2", SMALL_PX - 1)
		var x := r.position.x + (r.size.x - tw - x2) * 0.5
		UiTheme.text(_ui, Vector2(roundf(x), r.position.y + (13.5 if on else 12.5)), title, SIZE_CHIP if on else SMALL_PX + 1, title_col)
		if x2 > 0.0:
			UiTheme.text(_ui, Vector2(roundf(x + tw), r.position.y + 12.5), " x2", SMALL_PX - 1, Color("c07a4a"))
	var pr := points_rect()
	_ui.draw_rect(pr, Color(0.07, 0.055, 0.02, 0.8))
	_ui.draw_rect(pr, Color("4a3c1c"), false, 1.0)
	var d := Vector2(pr.position.x + 9.0, pr.get_center().y)
	_ui.draw_colored_polygon(PackedVector2Array([d + Vector2(0, -4), d + Vector2(4, 0), d + Vector2(0, 4), d + Vector2(-4, 0)]), UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(pr.position.x + 17.0, pr.position.y + 12.5), "Ability points", SMALL_PX, UiTheme.COL_DIM)
	UiTheme.text(_ui, Vector2(pr.end.x - 5.0 - UiTheme.width(str(_slot.points), UiTheme.SIZE_BODY), pr.position.y + 14.0), str(_slot.points),
		UiTheme.SIZE_BODY, Color("f3d36a"))


func _ellipse(rx: float, ry: float, from_deg := 0.0, steps := 72) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in steps + 1:
		var a := deg_to_rad(from_deg + 360.0 * float(k) / float(steps))
		out.append(TreeWheel.CENTER + Vector2(sin(a) * rx, -cos(a) * ry))
	return out


func _draw_wheel() -> void:
	var hue := TreeWheel.color(columns()[centred])
	var c := TreeWheel.CENTER
	for r in range(40, 18, -2):
		_ui.draw_circle(c, float(r), Color(hue, 0.045))
	_ui.draw_circle(c, 18.0, hue.darkened(0.7))
	_ui.draw_circle(c, 13.0, hue.darkened(0.3))
	_ui.draw_circle(c, 8.0, hue.lightened(0.15))
	_ui.draw_circle(c, 4.0, hue.lightened(0.6))
	for tier in range(1, GodTree.TIERS + 1):
		var ring := TreeWheel.ring(tier)
		var locked := tier > _slot.tier
		var pts := _ellipse(ring.x, ring.y)
		if locked:
			var dash := Color("3a3348")
			for k in range(0, pts.size() - 1, 2):
				_ui.draw_line(pts[k], pts[k + 1], Color(dash, 0.7), 1.0)
		elif tier == _slot.tier:
			_ui.draw_polyline(_ellipse(ring.x + 1.0, ring.y + 1.0), Color(hue, 0.18), 3.0)
			_ui.draw_polyline(pts, Color(hue.lightened(0.3), 0.75), 1.0)
		else:
			_ui.draw_polyline(pts, Color(hue, 0.35), 1.0)
		var numeral := String(TreeDetail.ROMAN[tier - 1])
		var top := Vector2(c.x, c.y - ring.y)
		_ui.draw_rect(Rect2(top.x - 7.0, top.y - 5.0, 14.0, 10.0), Color(0.07, 0.05, 0.12, 0.95))
		_text_centred(top.x, top.y + 3.5, numeral, SMALL_PX - 1, Color("4a4356") if locked else Color("a794c8"))
	for tier in range(1, GodTree.TIERS + 1):
		for i in GodTree.PER_TIER:
			_draw_node(tier, i, hue)


func _draw_node(tier: int, i: int, hue: Color) -> void:
	var p := TreeWheel.node_at(tier, i)
	var r := TreeWheel.NODE_R
	var key := key_at(centred, tier, i)
	var state := node_state(centred, tier, i)
	var sel := selected == Vector3i(centred, tier, i)
	var hot := _hover == "node:%d:%d" % [tier, i]
	if sel:
		_ui.draw_arc(p, r + 4.0, 0.0, TAU, 40, Color(COL_SELECT, 0.25), 2.0)
		_ui.draw_arc(p, r + 2.0, 0.0, TAU, 40, COL_SELECT, 2.0)
	if state == "empty":
		_dashed_circle(p, r - 1.0, Color(hue, 0.45 if hot else 0.3))
		return
	var have := _slot.level_of(key)
	var edge := hue.darkened(0.25)
	var fade := 1.0
	match state:
		"learned":
			edge = UiTheme.COL_GOLD
		"can":
			edge = hue.lightened(0.2)
		"lock":
			edge = Color("3a3348")
			fade = 0.5
	if hot:
		edge = edge.lightened(0.3)
	if state == "learned":
		_ui.draw_arc(p, r + 0.5, 0.0, TAU, 40, Color(UiTheme.COL_GOLD, 0.25), 3.0)
	_ui.draw_circle(p, r, Color(COL_NODE, 0.95))
	_ui.draw_arc(p, r - 1.0, 0.0, TAU, 40, Color(edge, fade), 2.0)
	var icon: Texture2D = _icons.get(key)
	var tint := Color(1, 1, 1, 1) if state != "lock" else Color(0.5, 0.5, 0.55, 0.55)
	if state == "poor":
		tint = Color(1, 1, 1, 0.85)
	if icon != null:
		_ui.draw_texture_rect(icon, Rect2(p - Vector2(7.0, 7.0), Vector2(14.0, 14.0)), false, tint)
	if state == "lock":
		var lp := p + Vector2(7.0, 7.0)
		_ui.draw_rect(Rect2(lp.x - 3.0, lp.y - 1.0, 6.0, 5.0), Color("8a8090"))
		_ui.draw_arc(lp + Vector2(0.0, -1.0), 2.0, PI, TAU, 8, Color("8a8090"), 1.0)
	if have > 0:
		for k in PowerBook.MAX_LEVEL:
			_ui.draw_rect(Rect2(p.x - 9.5 + float(k) * 4.0, p.y + r + 1.0, 3.0, 2.0), Color("f3d36a") if k < have else Color("3a3326"))
	var name_col := COL_SELECT if sel else (Color("bfb49a") if state != "lock" else Color("6e6678"))
	var short := node_label(String(PowerBook.get_power(key).name))
	var label := node_label_rect(tier, i, short)
	_text_centred(label.get_center().x, label.end.y - 1.0, short, NODE_NAME_PX, name_col)


func _dashed_circle(p: Vector2, r: float, col: Color) -> void:
	for k in range(0, 16, 2):
		_ui.draw_arc(p, r, TAU * float(k) / 16.0, TAU * float(k + 1) / 16.0, 4, col, 1.0)


func _draw_side(side: int) -> void:
	var col := side_col(side)
	var panel := side_rect(side)
	var type := columns()[col]
	var hue := TreeWheel.color(type)
	var hot := _hover == "side:%d" % col or _hover.begins_with("mini:%d:" % col)
	var fade := 1.0 if hot else 0.78
	if _wide_style == null:
		_wide_style = StyleBoxFlat.new()
		_wide_style.set_corner_radius_all(4)
		_wide_style.corner_radius_top_left = 56
		_wide_style.corner_radius_top_right = 56
		_wide_style.set_border_width_all(1)
	_wide_style.bg_color = Color(1, 1, 1, 0.03 if not hot else 0.06)
	_wide_style.border_color = Color("2a2433") if not hot else Color("4a4058")
	_ui.draw_style_box(_wide_style, panel)
	var mid := panel.get_center().x
	_text_centred(mid, panel.position.y + 24.0, PowerBook.authority_title(type), UiTheme.SIZE_BODY, Color(hue, fade))
	_text_centred(mid, panel.position.y + 36.0, "your nature" if type == _slot.type else "neighbour", SMALL_PX, Color("7d7668", fade))
	if type != _slot.type:
		var pill := Rect2(mid - 22.0, panel.position.y + 41.0, 44.0, 12.0)
		_ui.draw_rect(pill, Color("5a3a22", 0.8), false, 1.0)
		_text_centred(mid, pill.position.y + 9.5, "x2 cost", SMALL_PX - 1, Color("c07a4a", fade))
	for tier in range(1, GodTree.TIERS + 1):
		for i in GodTree.PER_TIER:
			_draw_mini(side, col, tier, i, hue, fade)
	_text_centred(mid, panel.end.y - 7.0, "click to centre", SMALL_PX - 1, Color("9a9484", fade))


func _draw_mini(side: int, col: int, tier: int, i: int, hue: Color, fade: float) -> void:
	var r := mini_rect(side_rect(side), tier, i)
	var key := key_at(col, tier, i)
	var c := r.get_center()
	var sel := selected == Vector3i(col, tier, i)
	if sel:
		_ui.draw_arc(c, 11.5, 0.0, TAU, 28, COL_SELECT, 2.0)
	if key == "":
		_dashed_circle(c, 8.5, Color(hue, 0.4 * fade))
		return
	var state := node_state(col, tier, i)
	var edge := hue.darkened(0.35)
	if state == "learned":
		edge = UiTheme.COL_GOLD
	elif state == "can":
		edge = hue.lightened(0.2)
	elif state == "lock":
		edge = Color("3a3348")
	if _hover == "mini:%d:%d:%d" % [col, tier, i]:
		edge = edge.lightened(0.35)
	_ui.draw_circle(c, 9.0, Color(COL_NODE, 0.9))
	_ui.draw_arc(c, 8.5, 0.0, TAU, 24, Color(edge, fade), 1.0)
	var icon: Texture2D = _icons.get(key)
	if icon == null:
		icon = spot_icon(key)
	if icon != null:
		_ui.draw_texture_rect(icon, Rect2(c - Vector2(6.0, 6.0), Vector2(12.0, 12.0)), false,
			Color(0.5, 0.5, 0.55, 0.5 * fade) if state == "lock" else Color(1, 1, 1, fade))


## The detail panel: clip, name and tags and description, the level column and the two buttons.
func _draw_detail() -> void:
	_ui.draw_rect(DETAIL, Color(0.07, 0.055, 0.1, 0.94))
	_ui.draw_rect(DETAIL, Color("5a4a2a"), false, 1.0)
	_ui.draw_line(DETAIL.position + Vector2(40, 0), Vector2(DETAIL.end.x - 40.0, DETAIL.position.y), Color(UiTheme.COL_GOLD, 0.8), 1.0)
	var key := selected_key()
	_ui.draw_rect(CLIP_BOX, Color("0a0810"))
	_ui.draw_rect(CLIP_BOX, Color("3a3326"), false, 1.0)
	if key == "":
		_text_centred(CLIP_BOX.get_center().x, CLIP_BOX.get_center().y + 4.0, GodTree.NOT_CHOSEN, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		UiTheme.text(_ui, Vector2(INFO_X, 275.0), GodTree.NOT_CHOSEN, UiTheme.SIZE_BIG, UiTheme.COL_DIM)
		UiTheme.text(_ui, Vector2(INFO_X, 296.0), "Nothing here yet.", UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		return
	_draw_clip(key)
	var entry := PowerBook.get_power(key)
	UiTheme.text(_ui, Vector2(INFO_X, 274.0), UiTheme.fit(String(entry.name), INFO_W, UiTheme.SIZE_BIG), UiTheme.SIZE_BIG, Color("f3e7c0"))
	var tx := INFO_X
	var tags := TreeDetail.tags(key)
	var hue := TreeWheel.color(PowerBook.authority_of(key))
	for n in tags.size():
		var tag_col := hue if n == 0 else (Color("9fd1b8") if tags[n] == "QUIET" else (Color("d8906a") if tags[n] == "LOUD" else Color("c9b8ea")))
		var w := UiTheme.width(tags[n], SMALL_PX - 1) + 10.0
		_ui.draw_rect(Rect2(tx, 281.0, w, 12.0), Color(tag_col, 0.55), false, 1.0)
		UiTheme.text(_ui, Vector2(tx + 5.0, 290.0), tags[n], SMALL_PX - 1, tag_col)
		tx += w + 3.0
	var desc := TreeDetail.description(key, INFO_W)
	for n in desc.size():
		UiTheme.text(_ui, Vector2(INFO_X, 307.0 + UiTheme.LINE_SMALL * float(n)), desc[n], UiTheme.SIZE_SMALL, Color("c8c0ac"))
	var button := TreeDetail.buy_button(_slot, key, selected.y)
	var reason := refused_reason if refused_reason != "" else String(button.reason)
	if reason != "":
		UiTheme.text(_ui, Vector2(INFO_X, 347.0), UiTheme.fit(reason, INFO_W, UiTheme.SIZE_SMALL), UiTheme.SIZE_SMALL,
			UiTheme.COL_BAD if refused_reason != "" else Color(UiTheme.COL_BAD, 0.75))
	_draw_levels(key)
	_draw_buttons(button)


func _draw_clip(key: String) -> void:
	var sheet: Texture2D = _clips.get(key)
	if sheet != null:
		var frame := int(_clip_time * PowerBook.CLIP_FPS) % PowerBook.CLIP_FRAMES
		_ui.draw_texture_rect_region(sheet, CLIP_BOX, PowerBook.clip_frame(frame))
		return
	var big: Texture2D = _big.get(key)
	if big != null:
		_ui.draw_texture_rect(big, Rect2(CLIP_BOX.get_center() - Vector2(40.0, 40.0), Vector2(80.0, 80.0)), false)


func _num(s: String) -> String:
	return _dot_zero.sub(s, "", true)


var _dot_zero: RegEx = _make_dot_zero()


static func _make_dot_zero() -> RegEx:
	var re := RegEx.new()
	re.compile("(?<=\\d)\\.0(?!\\d)")
	return re


func _draw_levels(key: String) -> void:
	var col := TreeDetail.level_column(_slot, key)
	_ui.draw_line(Vector2(LEVEL_X, 260.0), Vector2(LEVEL_X, 342.0), Color("2a2433"), 1.0)
	var x := LEVEL_X + 8.0
	var room := LEVEL_W - 14.0
	var y := 268.0
	var line := 10.0
	var no_table: bool = col.head == PowerBook.NO_LEVELS
	UiTheme.text(_ui, Vector2(x, y), String(col.head), SMALL_PX - 1, UiTheme.COL_DIM)
	y += line
	var twist_lines := PackedStringArray()
	if String(col.twist) != "":
		twist_lines = UiTheme.wrap(String(col.twist), room, SMALL_PX - 1)
		if twist_lines.size() > 3:
			twist_lines = twist_lines.slice(0, 3)
	# Rows that do not fit above the Might row and the twist are dropped.
	var budget := int((342.0 - y - line * float(1 + twist_lines.size()) - 3.0) / line)
	var rows: Array = col.rows
	for n in mini(rows.size(), maxi(budget, 0)):
		var row: Dictionary = rows[n]
		var old_v := _num(String(row.old))
		var new_v := _num(String(row.new))
		var value_w := 0.0
		if old_v == new_v:
			value_w = UiTheme.width(new_v, SMALL_PX)
			UiTheme.text(_ui, Vector2(x + room - value_w, y), new_v, SMALL_PX, Color("c8c0ac"))
		else:
			var new_w := UiTheme.width(new_v, SMALL_PX)
			var old_part := old_v + " -> "
			value_w = UiTheme.width(old_part, SMALL_PX) + new_w
			UiTheme.text(_ui, Vector2(x + room - value_w, y), old_part, SMALL_PX, Color("bfb49a"))
			UiTheme.text(_ui, Vector2(x + room - new_w, y), new_v, SMALL_PX, COL_GREEN)
		UiTheme.text(_ui, Vector2(x, y), UiTheme.fit(String(row.label), room - value_w - 4.0, SMALL_PX), SMALL_PX, Color("bfb49a"))
		y += line
	var might := _num(String(col.might))
	UiTheme.text(_ui, Vector2(x, y), "Might", SMALL_PX, Color("bfb49a"))
	UiTheme.text(_ui, Vector2(x + room - UiTheme.width(might, SMALL_PX), y), might, SMALL_PX, Color("c8c0ac"))
	y += line
	if not no_table:
		_ui.draw_line(Vector2(x, y - line + 3.0), Vector2(x + room, y - line + 3.0), Color("3a3326"), 1.0)
	for n in twist_lines.size():
		UiTheme.text(_ui, Vector2(x, y + 1.0 + line * float(n)), twist_lines[n], SMALL_PX - 1, COL_TWIST)


func _draw_buttons(button: Dictionary) -> void:
	var rem_hot := _hover == "remember"
	_ui.draw_rect(REMEMBER_RECT, Color("1f3a4a") if rem_hot else Color("152a37"))
	_ui.draw_rect(REMEMBER_RECT, COL_REMEMBER, false, 1.0)
	_text_centred(REMEMBER_RECT.get_center().x, REMEMBER_RECT.position.y + 13.0, "REMEMBRANCE", SMALL_PX + 1, Color("dff2fa"))
	_text_centred(REMEMBER_RECT.get_center().x, REMEMBER_RECT.position.y + 24.0, "try it, free", SMALL_PX - 1, Color(COL_REMEMBER, 0.9))
	var on: bool = button.enabled
	var hot := _hover == "buy" and on
	var fill := Color("f0cf62") if hot else Color("d8b23a")
	_ui.draw_rect(BUY_RECT, fill if on else Color("2a2630"))
	_ui.draw_rect(BUY_RECT, Color("f3d36a") if on else Color("463f50"), false, 1.0)
	var ink := Color("2a1d04") if on else Color("7d7668")
	_text_centred(BUY_RECT.get_center().x, BUY_RECT.position.y + 13.0, String(button.label), UiTheme.SIZE_BODY - 1, ink)
	var cost: int = button.cost
	var sub := "Level %d" % PowerBook.MAX_LEVEL if button.label == "MAX" else "%d point%s" % [cost, "" if cost == 1 else "s"]
	_text_centred(BUY_RECT.get_center().x, BUY_RECT.position.y + 24.0, sub, SMALL_PX - 1, Color(ink, 0.85))


func _text_centred(x: float, baseline: float, s: String, size: int, col: Color) -> void:
	UiTheme.text(_ui, Vector2(roundf(x - UiTheme.width(s, size) * 0.5), baseline), s, size, col)
