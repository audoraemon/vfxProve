extends RefCounted
## The zoom readout (Discord idea "Zoom cap", 2026-11): "x" and two decimals, shown after a zoom change and gone after SHOW_SECONDS;
## its own layer above the HUD's, so F1 (which hides the HUD layer) leaves it.


static func run(t) -> void:
	t.check(ZoomReadout.label(0.5) == "x0.50" and ZoomReadout.label(1.0) == "x1.00" and ZoomReadout.label(0.6 * 1.1) == "x0.66",
		"the label is x and two decimals (%s)" % ZoomReadout.label(0.66))
	var r := ZoomReadout.new()
	t.check(not r.shown() and r.text() == "" and r.layer > 5, "nothing until the zoom changes; above the HUD's layer 5")
	r.show_zoom(0.6)
	t.check(r.shown() and r.text() == "x0.60", "a change shows it (%s)" % r.text())
	r._process(ZoomReadout.SHOW_SECONDS - 0.1)
	t.check(r.shown(), "still up just before SHOW_SECONDS")
	r.show_zoom(0.55)
	r._process(ZoomReadout.SHOW_SECONDS - 0.1)
	t.check(r.shown() and r.text() == "x0.55", "a new change starts the time again")
	r._process(0.2)
	t.check(not r.shown() and r.text() == "", "gone after SHOW_SECONDS")
	r.free()
