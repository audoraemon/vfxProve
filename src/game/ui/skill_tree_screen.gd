class_name SkillTreeScreen
extends Node
## The Skill Tree (god P1, spec §5.2-§5.4, §12): the god's own type in the middle with its two ring neighbours beside it (their spots
## cost double, marked x2), far types never shown. Rows are the five tiers; a tier above the god's dims and says "Awaken to Tier T".
## Every spot shows its ability, level pips, Might at that level, the next level's cost in points and what that level changes (the
## twist at level 5). A click learns the ability or raises it one level; a refused click says why in the detail panel for
## REFUSE_SECONDS. The screen edits the GodSlot it is given and emits "learned" so Game writes the slot; Esc or Back leaves.

## "learned" (a point was spent: Game writes the slot) or "back".
signal action(name: String)

## The grid: three type columns, five tier rows, two spots a tier (spec §5.2). Spot (col, tier, i) sits at GRID_AT plus its column and
## row steps; a tier number sits in the gutter left of the grid.
const GRID_AT := Vector2(32.0, 50.0)
const SPOT := Vector2(94.0, 50.0)
const SPOT_GAP := 4.0
const COLUMN_GAP := 12.0
const ROW_STEP := 52.0
const COLUMNS := 3
## A spot's icon (spec §12): ICON_PX square, drawn at its top left, with the name from NAME_X so the two sit side by side above the pips.
const ICON_PX := 14.0
const NAME_X := 20.0
## The detail panel under the grid (the hovered spot's change, or a refusal), and the Back button beside it.
const DETAIL := Rect2(86.0, 314.0, 546.0, 40.0)
const BACK_RECT := Rect2(8.0, 322.0, 70.0, 24.0)
## How long a refusal's reason stays up.
const REFUSE_SECONDS := 1.5
## What a refused click says, by GodSlot.refusal() (*my call*); "tier" takes the spot's tier.
const REFUSALS := {"unknown": "Not yet chosen", "far": "Too far from your nature", "tier": "Awaken to Tier %d",
	"max": "Already at level 5", "points": "Not enough ability points"}

## Why the last click learned nothing, shown for REFUSE_SECONDS; "" for none.
var refused_reason := ""
var _refuse_left := 0.0
var _slot: GodSlot
var _ui: Control
var _hover := ""
var _picked := ""
## The spots' icons, loaded once each in setup(), not in the draw (a texture first loaded inside a draw showed white for a frame); null for a power with none yet.
var _icons := {}


func setup(slot: GodSlot) -> SkillTreeScreen:
	_slot = slot
	for col in columns().size():
		for tier in range(1, GodTree.TIERS + 1):
			for i in GodTree.PER_TIER:
				var key := key_at(col, tier, i)
				if key != "" and not _icons.has(key):
					_icons[key] = spot_icon(key)
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


## The rectangle of the spot `i` (0-1) of tier `tier` (1-5) in column `col` (0-2).
static func spot_rect(col: int, tier: int, i: int) -> Rect2:
	var x := GRID_AT.x + float(col) * (2.0 * SPOT.x + SPOT_GAP + COLUMN_GAP) + float(i) * (SPOT.x + SPOT_GAP)
	var y := GRID_AT.y + float(tier - 1) * ROW_STEP
	return Rect2(Vector2(x, y), SPOT)


## The rectangle of the icon in the spot `i` of tier `tier` in column `col`.
static func icon_rect(col: int, tier: int, i: int) -> Rect2:
	return Rect2(spot_rect(col, tier, i).position + Vector2(3.0, 1.0), Vector2(ICON_PX, ICON_PX))


## The picture of an ability's spot: the HUD copy of its icon, else the full one; null when the power has none yet.
static func spot_icon(key: String) -> Texture2D:
	var hud := PowerBook.hud_icon(key)
	return hud if hud != null else PowerBook.icon(key)


## What is under a point: "spot:<col>:<tier>:<i>", "back" or "".
func hit(point: Vector2) -> String:
	if BACK_RECT.has_point(point):
		return "back"
	for col in columns().size():
		for tier in range(1, GodTree.TIERS + 1):
			for i in GodTree.PER_TIER:
				if spot_rect(col, tier, i).has_point(point):
					return "spot:%d:%d:%d" % [col, tier, i]
	return ""


## A left click at a screen point: Back leaves; a spot is learned or raised if it can be (and says why if not).
func click(point: Vector2) -> void:
	var h := hit(point)
	if h == "":
		return
	if h == "back":
		UiSound.play(&"ui_click")
		action.emit("back")
		return
	_picked = h
	var at := _parse(h)
	learn_at(at[0], at[1], at[2])


## The ability key in a spot ("" when empty).
func key_at(col: int, tier: int, i: int) -> String:
	var cols := columns()
	return GodTree.spot(cols[col], tier, i) if col >= 0 and col < cols.size() else ""


## Learns or raises the ability in a spot; returns GodSlot.refusal()'s code ("unknown", "far", "max", "tier", "points") when it
## cannot, or "" and emits "learned" when it did. A refusal buzzes and says why for REFUSE_SECONDS.
func learn_at(col: int, tier: int, i: int) -> String:
	var key := key_at(col, tier, i)
	var why := _slot.refusal(key)
	if why != "":
		UiSound.play(&"ui_buzz")
		refused_reason = String(REFUSALS.get(why, why))
		if why == "tier":
			refused_reason = refused_reason % tier
		_refuse_left = REFUSE_SECONDS
		_redraw()
		return why
	_slot.learn(key)
	UiSound.play(&"ui_manifest")
	refused_reason = ""
	_redraw()
	action.emit("learned")
	return ""


## What a spot draws, for tests: an empty spot [NOT_CHOSEN]; else [power name, "n / 5", "n Might", next, change]. `next` is
## "Learn: n point(s)", "Level L: n point(s)" or "Level 5"; `change` is what the next level changes (PowerBook.level_change()), or
## the twist at level 5 (NO_LEVELS when the power has no table). Might is the cost at the learned level (level 1's when unlearned).
func spot_lines(col: int, tier: int, i: int) -> PackedStringArray:
	var key := key_at(col, tier, i)
	if key == "":
		return PackedStringArray([GodTree.NOT_CHOSEN])
	var have := _slot.level_of(key)
	var cost := _slot.cost(key)
	var points := "%d point%s" % [cost, "" if cost == 1 else "s"]
	var next := "Level %d" % PowerBook.MAX_LEVEL
	var change := PowerBook.twist(key) if PowerBook.has_levels(key) else PowerBook.NO_LEVELS
	if have < PowerBook.MAX_LEVEL:
		next = ("Learn: %s" % points) if have == 0 else ("Level %d: %s" % [have + 1, points])
		change = PowerBook.level_change(key, have + 1)
	return PackedStringArray([String(PowerBook.get_power(key).name), "%d / %d" % [have, PowerBook.MAX_LEVEL],
		"%d Might" % _slot.might_of(key), next, change])


## The header: the god's type and its ability points.
func header_text() -> String:
	return "SKILL TREE   %s   Ability points %d" % [PowerBook.authority_title(_slot.type), _slot.points]


## A column's header: the type's title, "x2" after a neighbour's.
func column_title(col: int) -> String:
	var cols := columns()
	var title := PowerBook.authority_title(cols[col])
	return title if cols[col] == _slot.type else title + " x2"


## The detail panel's lines: a refusal while one is up, else the spot under the mouse (or last clicked): its title line and what
## its next level changes; a hint when there is none.
func detail_lines() -> PackedStringArray:
	if refused_reason != "":
		return PackedStringArray([refused_reason])
	var shown := _hover if _hover.begins_with("spot:") else _picked
	if not shown.begins_with("spot:"):
		return PackedStringArray(["Click an ability to learn it or raise it. Esc goes back."])
	var at := _parse(shown)
	var key := key_at(at[0], at[1], at[2])
	if key == "":
		return PackedStringArray([GodTree.NOT_CHOSEN])
	var lines := spot_lines(at[0], at[1], at[2])
	var out := PackedStringArray(["%s - %s - %s - %s" % [lines[0], PowerBook.authority_title(columns()[at[0]]), lines[1], lines[2]]])
	out.append_array(UiTheme.wrap("%s   %s" % [lines[3], lines[4]], DETAIL.size.x - 16.0, UiTheme.SIZE_SMALL))
	return out


static func _parse(h: String) -> Array:
	var parts := h.split(":")
	return [int(parts[1]), int(parts[2]), int(parts[3])] if parts.size() == 4 else [0, 0, 0]


func _redraw() -> void:
	if _ui != null:
		_ui.queue_redraw()


func _process(delta: float) -> void:
	if _refuse_left > 0.0:
		_refuse_left -= delta
		if _refuse_left <= 0.0:
			refused_reason = ""
			_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		UiSound.play(&"ui_click")
		action.emit("back")


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


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.03, 0.05, 1.0))
	UiTheme.text(_ui, Vector2(8, 22), header_text(), UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	for col in columns().size():
		var own := columns()[col] == _slot.type
		var x := spot_rect(col, 1, 0).position.x
		UiTheme.text(_ui, Vector2(x, 44.0), column_title(col), UiTheme.SIZE_BODY, UiTheme.COL_GOLD if own else UiTheme.COL_TEXT)
	for tier in range(1, GodTree.TIERS + 1):
		var locked := tier > _slot.tier
		UiTheme.text(_ui, Vector2(12.0, GRID_AT.y + float(tier - 1) * ROW_STEP + 28.0), str(tier), UiTheme.SIZE_BODY,
			UiTheme.COL_DIM if locked else UiTheme.COL_GOLD)
		for col in columns().size():
			for i in GodTree.PER_TIER:
				_draw_spot(col, tier, i, locked)
	_draw_detail()
	_ui.draw_rect(BACK_RECT, Color(0.04, 0.04, 0.06, 0.85))
	UiTheme.frame(_ui, BACK_RECT, _hover == "back")
	UiTheme.text(_ui, Vector2(roundf(BACK_RECT.get_center().x - UiTheme.width("Back") * 0.5), BACK_RECT.position.y + 16.0),
		"Back", UiTheme.SIZE_BODY, UiTheme.COL_GOLD if _hover == "back" else UiTheme.COL_TEXT)


## One spot: name, level pips and Might, the next level's cost, and what it changes; a locked tier dims and says what unlocks it.
func _draw_spot(col: int, tier: int, i: int, locked: bool) -> void:
	var r := spot_rect(col, tier, i)
	var id := "spot:%d:%d:%d" % [col, tier, i]
	var key := key_at(col, tier, i)
	var lines := spot_lines(col, tier, i)
	var have := _slot.level_of(key) if key != "" else 0
	var fade := 0.5 if locked and have == 0 else 1.0
	_ui.draw_rect(r, Color(0.1, 0.09, 0.07, 0.9) if _hover == id else UiTheme.COL_PANEL)
	if key == "":
		UiTheme.frame(_ui, r, false)
		UiTheme.text(_ui, Vector2(r.position.x + 4.0, r.position.y + 29.0), UiTheme.fit(lines[0], r.size.x - 8.0), UiTheme.SIZE_SMALL,
			UiTheme.COL_DIM)
		return
	var can := _slot.refusal(key) == ""
	UiTheme.frame(_ui, r, have > 0 or (can and _hover == id))
	var text_col := Color(UiTheme.COL_TEXT, fade)
	var dim_col := Color(UiTheme.COL_DIM, fade)
	var room := r.size.x - 8.0
	var icon: Texture2D = _icons.get(key)
	if icon != null:
		_ui.draw_texture_rect(icon, icon_rect(col, tier, i), false, Color(1, 1, 1, fade))
	UiTheme.text(_ui, r.position + Vector2(NAME_X, 11.0), UiTheme.fit(lines[0], room - (NAME_X - 4.0)), UiTheme.SIZE_SMALL,
		Color(UiTheme.COL_GOLD, fade) if have > 0 else text_col, fade)
	for p in PowerBook.MAX_LEVEL:
		var pip := Rect2(r.position + Vector2(4.0 + float(p) * 6.0, 15.0), Vector2(5.0, 5.0))
		_ui.draw_rect(pip, Color(UiTheme.COL_GOLD, fade) if p < have else Color(0.2, 0.18, 0.12, fade))
	var might := lines[2]
	UiTheme.text(_ui, Vector2(r.end.x - 4.0 - UiTheme.width(might, UiTheme.SIZE_SMALL), r.position.y + 23.0), might, UiTheme.SIZE_SMALL,
		dim_col, fade)
	UiTheme.text(_ui, r.position + Vector2(4.0, 35.0), _clip(lines[3], room), UiTheme.SIZE_SMALL, text_col if can else dim_col, fade)
	var change := "Awaken to Tier %d" % tier if locked and have == 0 else lines[4]
	UiTheme.text(_ui, r.position + Vector2(3.0, 47.0), _clip(change, room + 2.0), UiTheme.SIZE_SMALL,
		Color(UiTheme.COL_BAD, fade) if locked and have == 0 else dim_col, fade)


## The detail panel: the refusal in red, else the hovered spot's title line and its change.
func _draw_detail() -> void:
	_ui.draw_rect(DETAIL, UiTheme.COL_PANEL)
	UiTheme.frame(_ui, DETAIL, false)
	var lines := detail_lines()
	for n in mini(lines.size(), 3):
		var col := UiTheme.COL_DIM
		if n == 0:
			col = UiTheme.COL_BAD if refused_reason != "" else UiTheme.COL_GOLD
		elif n == 1:
			col = UiTheme.COL_TEXT
		UiTheme.text(_ui, DETAIL.position + Vector2(8.0, 12.0 + UiTheme.LINE_SMALL * float(n)), lines[n], UiTheme.SIZE_SMALL, col)


## `s` cut to `room` px with a trailing "..." (UiTheme.fit keeps only a name's first word, which would lose a line of numbers).
static func _clip(s: String, room: float) -> String:
	if UiTheme.width(s, UiTheme.SIZE_SMALL) <= room:
		return s
	var out := s
	while out.length() > 1 and UiTheme.width(out + "...", UiTheme.SIZE_SMALL) > room:
		out = out.substr(0, out.length() - 1)
	return out + "..."
