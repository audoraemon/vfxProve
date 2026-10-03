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

	# The mission sets the draft (v0.08): Last Judgement has four slots and allows every power.
	var lj := Draft.new().for_mission(MissionBook.last_judgement())
	t.check(lj.slots == 4 and lj.pool == PowerBook.keys(), "Last Judgement's draft has four slots and every power (%d)" % lj.slots)
	var narrow := Draft.new()
	narrow.slots = 2
	narrow.pool = PackedStringArray(["nova", "heaven"])
	narrow.preselect(PackedStringArray(["cinder", "heaven", "nova", "gravity"]))
	t.check(narrow.picks == PackedStringArray(["heaven", "nova"]) and narrow.is_full(),
		"a power outside the mission's pool is refused, and its slots make it full (%s)" % [narrow.picks])

	# The Prepare screen (v0.06): tabs by kind, the open tab's cards, the loadout bar with MANIFEST -- none
	# overlapping, all above the difficulty strip.
	var screen := Rect2(0, 0, 640, PrepareScreen.STRIP.position.y)
	var boxes: Array[Rect2] = []
	for i in PowerBook.KINDS.size():
		boxes.append(PrepareScreen.tab_rect(i))
	var most := 0
	for kind in PowerBook.KINDS:
		most = maxi(most, PowerBook.of_kind(kind).size())
	for i in most:
		boxes.append(PrepareScreen.cell_rect(i))
	for i in d.slots:
		boxes.append(PrepareScreen.slot_rect(i))
	boxes.append(PrepareScreen.MANIFEST_RECT)
	var bad := 0
	for i in boxes.size():
		if not screen.encloses(boxes[i]):
			bad += 100
		for j in range(i + 1, boxes.size()):
			if boxes[i].intersects(boxes[j]):
				bad += 1
	t.check(bad == 0, "tabs, the largest tab's %d cards and the loadout bar fit without touching (%d)" % [most, bad])
	var prep := PrepareScreen.new()
	prep.setup(MissionBook.last_judgement(), PackedStringArray(["doom", "heaven"]))
	t.check(prep.tab == PowerBook.KINDS.find("quiet") and Array(prep.shown()) == Array(PowerBook.of_kind("quiet")),
		"the screen opens on the first pick's tab (%d)" % prep.tab)
	t.check(prep.hit(PrepareScreen.tab_rect(0).get_center()) == "tab:0"
		and prep.hit(PrepareScreen.slot_rect(1).get_center()) == "slot:1"
		and prep.hit(PrepareScreen.cell_rect(0).get_center()) == String(PowerBook.of_kind("quiet")[0])
		and prep.hit(PrepareScreen.MANIFEST_RECT.get_center()) == "manifest",
		"tabs, slots, MANIFEST and the open tab's cards answer the mouse")
	prep.free()
	t.check(PrepareScreen.cooldown_text(PowerBook.get_power("doom")) == "2.5 s"
		and PrepareScreen.cooldown_text(PowerBook.get_power("nova")) == "120 s",
		"a card shows a fractional cooldown as 2.5 s and a whole one without a decimal")

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
