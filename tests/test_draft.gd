extends RefCounted
## The draft's rules: four slots filled in pick order, a fifth pick refused, unpicking closes the gap, and a
## saved loadout comes back cleaned up.


static func run(t) -> void:
	var d := Draft.new()
	t.check(d.picks.is_empty() and not d.is_full(), "a new draft is empty")

	d.toggle("nova")
	d.toggle("heaven")
	d.toggle("cinder")
	t.check(d.slot_of("nova") == 1 and d.slot_of("heaven") == 2 and d.slot_of("cinder") == 3,
		"picks fill the slots in the order they were made (%s)" % [d.picks])
	t.check(not d.is_full(), "three picks is not a loadout")
	d.toggle("gravity")
	t.check(d.is_full() and d.slot_of("gravity") == 4, "the fourth pick fills it")
	d.toggle("tornado")
	t.check(d.picks.size() == 4 and d.slot_of("tornado") == 0, "a fifth pick is refused (%s)" % [d.picks])

	# Taking a pick back closes the gap: the later picks move up a slot.
	d.toggle("heaven")
	t.check(d.picks == PackedStringArray(["nova", "cinder", "gravity"]), "unpicking closes the gap (%s)" % [d.picks])
	t.check(d.slot_of("cinder") == 2 and d.slot_of("heaven") == 0, "so the slots renumber (%d, %d)" % [d.slot_of("cinder"), d.slot_of("heaven")])

	d.toggle("kettle")
	t.check(d.picks.size() == 3, "a key that is not a power cannot be picked (%s)" % [d.picks])

	# A saved loadout comes back in its own order, without strangers, doubles or a fifth power.
	var saved := Draft.new().preselect(PackedStringArray(["judgement", "kettle", "nova", "nova", "laser", "dragon", "heaven"]))
	t.check(saved.picks == PackedStringArray(["judgement", "nova", "laser", "dragon"]),
		"a saved loadout is cleaned up on the way in (%s)" % [saved.picks])
	t.check(Draft.new().preselect(PackedStringArray()).picks.is_empty(), "and an empty one gives an empty draft")

	# The Prepare screen's grid: eleven cards and the MANIFEST cell, none overlapping, all on screen.
	var screen := Rect2(0, 0, 640, 360)
	var overlaps := 0
	for i in 12:
		var a := PrepareScreen.cell_rect(i)
		if not screen.encloses(a):
			overlaps += 100
		for j in range(i + 1, 12):
			if a.intersects(PrepareScreen.cell_rect(j)):
				overlaps += 1
	t.check(overlaps == 0, "the twelve cells fit the screen without touching (%d)" % overlaps)

	# Wrapping keeps every line inside its width.
	var lines := UiTheme.wrap("Judgement of the Ancients", 60.0, UiTheme.SIZE_SMALL)
	var widest := 0.0
	for line in lines:
		widest = maxf(widest, UiTheme.width(line, UiTheme.SIZE_SMALL))
	t.check(lines.size() >= 2 and widest <= 60.0, "a long name wraps inside its width (%s, %.0f px)" % [lines, widest])

	# Every power has a recorded preview, laid out the way the draft reads it.
	var unrecorded := ""
	for key in PowerBook.keys():
		if PowerBook.clip(key) == null:
			unrecorded += " " + key
	t.check(unrecorded == "", "every power has a preview clip (missing:%s)" % unrecorded)
	var sheet := PowerBook.clip("nova")
	var rows := ceili(float(PowerBook.CLIP_FRAMES) / PowerBook.CLIP_COLUMNS)
	t.check(sheet != null and sheet.get_size() == Vector2(PowerBook.CLIP_SIZE.x * PowerBook.CLIP_COLUMNS, PowerBook.CLIP_SIZE.y * rows),
		"a sheet holds its frames in a %d-column grid (%s)" % [PowerBook.CLIP_COLUMNS, sheet.get_size() if sheet != null else "none"])
