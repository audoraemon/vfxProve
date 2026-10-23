extends RefCounted
## v0.11.2: F1 hides the whole interface to watch the town (the user's ask). The HUD layer and the aim go; the camera still moves; no
## click casts while hidden; F1 again, a slot key, TAB or H brings it back; the ending never stays hidden.

const Legend := preload("res://tests/test_legend.gd")


static func run(t) -> void:
	var m: Mission = Legend._mission()
	t.check(Mission.toggles_ui(Legend._key(KEY_F1)) and not Mission.toggles_ui(Legend._key(KEY_H)), "F1 is the key, only F1")
	var echo := Legend._key(KEY_F1)
	echo.echo = true
	t.check(not Mission.toggles_ui(echo), "a held F1 does not toggle")
	t.check(not m.ui_hidden and m._bf.hud_layer.visible and m._aim.visible, "shown at first")

	m._unhandled_input(Legend._key(KEY_F1))
	t.check(m.ui_hidden and not m._bf.hud_layer.visible and not m._aim.visible
		and not m._aim.is_processing_unhandled_input(), "F1 hides the HUD layer and the aim")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	m._unhandled_input(click)
	t.check(not m._pressing, "a click while hidden presses nothing (no cast)")
	m._unhandled_input(Legend._key(KEY_F1))
	t.check(not m.ui_hidden and m._bf.hud_layer.visible and m._aim.visible and m._aim.is_processing_unhandled_input(),
		"F1 again shows it all")

	m.set_ui_hidden(true)
	m._unhandled_input(Legend._key(KEY_H))
	t.check(not m.ui_hidden and m._bf.hud_layer.visible and m.legend_open(), "H while hidden shows the interface and opens the legend")
	m._legend.close()
	m._on_legend_closed()

	m.set_ui_hidden(true)
	m._unhandled_input(Legend._key(KEY_1))
	t.check(not m.ui_hidden, "a slot key while hidden shows the interface (TAB and H do too)")
	Legend._drop(m)
