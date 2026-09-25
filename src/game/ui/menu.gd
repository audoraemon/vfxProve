class_name Menu
extends RefCounted
## A handful of pixel buttons: where each one is, which one a point is over, and how they draw. Title, Results
## and Pause all use it, so every button in the game looks and answers the same way.

const HEIGHT := 20.0

## One entry per button: {"action": String, "label": String, "rect": Rect2}.
var items: Array[Dictionary] = []


func add(action: String, label: String, rect: Rect2) -> Menu:
	items.append({"action": action, "label": label, "rect": rect})
	return self


## Buttons stacked downward from `top`, each `width` wide, centred on `centre_x`.
static func column(actions: Array, labels: Array, centre_x: float, top: float, width: float, gap := 6.0) -> Menu:
	var m := Menu.new()
	for i in actions.size():
		m.add(String(actions[i]), String(labels[i]),
			Rect2(roundf(centre_x - width * 0.5), top + float(i) * (HEIGHT + gap), width, HEIGHT))
	return m


## Buttons side by side at `top`, each `width` wide, the whole row centred on `centre_x`.
static func row(actions: Array, labels: Array, centre_x: float, top: float, width: float, gap := 8.0) -> Menu:
	var m := Menu.new()
	var total := float(actions.size()) * width + float(maxi(actions.size() - 1, 0)) * gap
	var left := roundf(centre_x - total * 0.5)
	for i in actions.size():
		m.add(String(actions[i]), String(labels[i]), Rect2(left + float(i) * (width + gap), top, width, HEIGHT))
	return m


## The action under a point, or "" between and around the buttons.
func at(point: Vector2) -> String:
	for item: Dictionary in items:
		if (item.rect as Rect2).has_point(point):
			return String(item.action)
	return ""


func rect_of(action: String) -> Rect2:
	for item: Dictionary in items:
		if String(item.action) == action:
			return item.rect
	return Rect2()


## Every button: a dark panel, the gold frame bright under the mouse, the label centred. `dim` names buttons
## that are shown but cannot be pressed yet.
func draw_on(on: CanvasItem, hover: String, dim := PackedStringArray()) -> void:
	for item: Dictionary in items:
		var r: Rect2 = item.rect
		var action := String(item.action)
		var off := dim.has(action)
		on.draw_rect(r, Color(0.04, 0.04, 0.06, 0.85))
		UiTheme.frame(on, r, action == hover and not off)
		var label := String(item.label)
		var col := UiTheme.COL_DIM if off else (UiTheme.COL_GOLD if action == hover else UiTheme.COL_TEXT)
		UiTheme.text(on, Vector2(roundf(r.get_center().x - UiTheme.width(label) * 0.5), r.position.y + 14.0),
			label, UiTheme.SIZE_BODY, col)
