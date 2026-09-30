extends RefCounted
## The F3 frame-rate meter: its line, its colours, and the key that shows and hides it.


static func run(t) -> void:
	t.check(FpsMeter.describe(83.4, 12.04, 25.63, 1201) == "83 FPS  12.0 ms  max 25.6  1201 draws",
		"the meter's line (%s)" % FpsMeter.describe(83.4, 12.04, 25.63, 1201))
	t.check(FpsMeter.color_for(60.0) == FpsMeter.COL_GOOD and FpsMeter.color_for(40.0) == UiTheme.COL_GOLD
		and FpsMeter.color_for(20.0) == UiTheme.COL_BAD, "green from 55 fps, gold from 30, red below")

	FpsMeter.shown = false
	var m := FpsMeter.new()
	m._ready()
	t.check(not m.visible, "hidden until asked for")
	var f3 := InputEventKey.new()
	f3.pressed = true
	f3.physical_keycode = KEY_F3
	m._input(f3)
	t.check(m.visible and FpsMeter.shown, "F3 shows it")
	var again := FpsMeter.new()
	again._ready()
	t.check(again.visible, "a new battlefield's meter keeps it shown")
	m._input(f3)
	t.check(not m.visible and not FpsMeter.shown, "F3 again hides it")
	FpsMeter.shown = false
	m.free()
	again.free()

	# F4's behaviour overlay (v0.04 debug): a colour for every intent, hidden until asked for.
	t.check(BehaviourOverlay.INTENT_COLS.size() == Person.Intent.size() and not BehaviourOverlay.shown,
		"the behaviour overlay has a colour per intent and starts hidden")
