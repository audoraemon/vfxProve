extends RefCounted
## The draft's rules: slots filled in pick order, a pick past the last slot or over the Divine Power refused (v0.08),
## unpicking closes the gap, and a saved loadout comes back cleaned up.


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
	var fifth := d.toggle("tornado")
	t.check(fifth == "slots" and d.picks.size() == 4 and d.slot_of("tornado") == 0, "a fifth pick is refused (%s, %s)" % [fifth, d.picks])

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

	# The mission sets the draft (v0.08): Last Judgement has six slots, 14 Divine Power and every power.
	var lj := Draft.new().for_mission(MissionBook.last_judgement())
	t.check(lj.slots == 6 and lj.capacity == 14 and lj.pool == PowerBook.keys(),
		"Last Judgement's draft has six slots, 14 DP and every power (%d, %d)" % [lj.slots, lj.capacity])
	t.check(not lj.can_manifest(), "an empty draft cannot manifest")
	var changed := ""
	for key in Mission.DEFAULT_LOADOUT:
		changed += lj.toggle(key)
	t.check(changed == "" and lj.spent() == 14 and lj.can_manifest(),
		"the default four (2+4+4+4) cost 14 and fit (%d DP, '%s')" % [lj.spent(), changed])
	t.check(lj.refusal("doom") == "dp" and lj.toggle("doom") == "dp" and lj.spent() == 14 and lj.slot_of("doom") == 0,
		"a fifth pick of 1 DP is refused for its Divine Power, with two slots free (%s, %d DP)" % [lj.picks, lj.spent()])
	t.check(lj.toggle("nova") == "" and lj.spent() == 10, "taking out the Nova leaves 10 DP spent (%d)" % lj.spent())
	t.check(lj.toggle("doom") == "" and lj.slot_of("doom") == 4 and lj.spent() == 11,
		"after which Silent Doom fits (%s, %d DP)" % [lj.picks, lj.spent()])
	var one := Draft.new().for_mission(MissionBook.last_judgement())
	one.toggle("heaven")
	t.check(one.can_manifest() and not one.is_full(), "one pick can manifest: empty slots are allowed")
	# Six cheap picks fill the slots well inside the Divine Power; the seventh is refused for want of a slot. With
	# six of the 1-2 DP powers taken, the Tornado's 3 makes 14 in all, still within the budget.
	var cheap := Draft.new().for_mission(MissionBook.last_judgement())
	for key in ["doom", "wisp", "discord", "heaven", "blight", "thorns"]:
		changed += cheap.toggle(key)
	t.check(changed == "" and cheap.is_full() and cheap.spent() == 11, "six cheap picks fill the six slots (%d DP)" % cheap.spent())
	t.check(cheap.toggle("tornado") == "slots" and cheap.picks.size() == 6,
		"and the seventh is refused for want of a slot, not of DP (%s)" % [cheap.picks])
	# A mission's pool: a power outside it is refused as such, and so is a key that is no power at all.
	var pooled := MissionDef.new()
	pooled.pool = PackedStringArray(["doom", "discord"])
	var small := Draft.new().for_mission(pooled)
	t.check(small.toggle("nova") == "pool" and small.toggle("kettle") == "pool" and small.toggle("doom") == ""
		and small.picks == PackedStringArray(["doom"]), "a key outside the pool is refused with \"pool\" (%s)" % [small.picks])
	# A saved loadout skips whatever no longer fits: here the Nova, which would take the spend past 14.
	var over := Draft.new().for_mission(MissionBook.last_judgement())
	over.preselect(PackedStringArray(["cinder", "judgement", "glacial", "nova", "doom", "kettle", "heaven"]))
	t.check(over.picks == PackedStringArray(["cinder", "judgement", "glacial", "doom"]) and over.spent() == 13,
		"a saved loadout keeps its order and skips what is refused (%s, %d DP)" % [over.picks, over.spent()])
	var narrow := Draft.new()
	narrow.slots = 2
	narrow.pool = PackedStringArray(["nova", "heaven"])
	narrow.preselect(PackedStringArray(["cinder", "heaven", "nova", "gravity"]))
	t.check(narrow.picks == PackedStringArray(["heaven", "nova"]) and narrow.is_full(),
		"a power outside the mission's pool is refused, and its slots make it full (%s)" % [narrow.picks])

	# The Prepare screen (v0.06): tabs by Authority (v0.08), the open tab's cards, the loadout bar with MANIFEST --
	# none overlapping, all above the difficulty strip.
	var screen := Rect2(0, 0, 640, PrepareScreen.STRIP.position.y)
	var boxes: Array[Rect2] = []
	for i in PowerBook.AUTHORITIES.size():
		boxes.append(PrepareScreen.tab_rect(i))
	var most := 0
	for authority in PowerBook.AUTHORITIES:
		most = maxi(most, PowerBook.of_authority(authority).size())
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
	# Last Judgement's six slots (v0.08) share the bar left of MANIFEST.
	var six_bad := 0
	for i in lj.slots:
		var r := PrepareScreen.slot_rect(i, lj.slots)
		if not PrepareScreen.LOADOUT_BAR.encloses(r) or r.end.x > PrepareScreen.MANIFEST_RECT.position.x:
			six_bad += 100
		if i > 0 and r.intersects(PrepareScreen.slot_rect(i - 1, lj.slots)):
			six_bad += 1
	t.check(six_bad == 0, "six loadout slots fit left of MANIFEST without touching (%d)" % six_bad)
	var prep := PrepareScreen.new()
	prep.setup(MissionBook.last_judgement(), PackedStringArray(["doom", "heaven"]))
	t.check(prep.tab == prep.tabs().find("veil") and Array(prep.shown()) == Array(PowerBook.of_authority("veil")),
		"the screen opens on the first pick's tab (%d)" % prep.tab)
	t.check(prep.hit(PrepareScreen.tab_rect(0).get_center()) == "tab:0"
		and prep.hit(PrepareScreen.slot_rect(1, prep.draft.slots).get_center()) == "slot:1"
		and prep.hit(PrepareScreen.cell_rect(0).get_center()) == String(PowerBook.of_authority("veil")[0])
		and prep.hit(PrepareScreen.MANIFEST_RECT.get_center()) == "manifest",
		"tabs, slots, MANIFEST and the open tab's cards answer the mouse")
	# Tabs (v0.08): one per Authority with a power in the mission's pool, in AUTHORITIES order.
	t.check(Array(prep.tabs()) == PowerBook.AUTHORITIES, "Last Judgement shows all six Authorities' tabs (%s)" % [prep.tabs()])
	prep.free()
	var pooled_prep := PrepareScreen.new()
	pooled_prep.setup(pooled, PackedStringArray())
	t.check(pooled_prep.tabs() == PackedStringArray(["veil", "disorder"]),
		"a pool of Silent Doom and Discord shows only Veil and Disorder (%s)" % [pooled_prep.tabs()])
	t.check(pooled_prep.hit(PrepareScreen.tab_rect(1, 2).get_center()) == "tab:1"
		and PrepareScreen.tab_rect(1, 2).end.x <= PrepareScreen.TAB_AT.x + PrepareScreen.TAB_ROW
		and PrepareScreen.tab_rect(1, 2).size.x == 214.0,
		"and its two tabs share the 432-px row (%s)" % PrepareScreen.tab_rect(1, 2))
	pooled_prep.set_tab(1)
	t.check(Array(pooled_prep.shown()) == ["discord"], "the second tab holds Discord (%s)" % [pooled_prep.shown()])
	# Difficulty: a mission that sets the town's readiness itself has no selector to hit.
	t.check(pooled_prep.mission.chooses_difficulty() and pooled_prep.hit(PrepareScreen.arrow_rect(-1).get_center()) == "diff_prev",
		"a mission that chooses its difficulty on Prepare has the arrows")
	pooled_prep.free()
	var fixed := MissionDef.new()
	fixed.profile = "unaware"
	var fixed_prep := PrepareScreen.new()
	fixed_prep.setup(fixed, PackedStringArray())
	var arrows := ""
	for side in [-1, 1]:
		var r := PrepareScreen.arrow_rect(side)
		for p in [r.get_center(), r.position + Vector2.ONE, r.end - Vector2.ONE]:
			arrows += fixed_prep.hit(p)
	t.check(not fixed_prep.mission.chooses_difficulty() and arrows == "",
		"a mission with a fixed profile never offers the difficulty arrows ('%s')" % arrows)
	fixed_prep.free()

	# Clicks (v0.08): a card that does not fit leaves the draft as it was and says why; MANIFEST needs one pick.
	var click := PrepareScreen.new()
	click.setup(MissionBook.last_judgement(), PackedStringArray(Mission.DEFAULT_LOADOUT))
	var emitted: Array[String] = []
	click.action.connect(func(what: String) -> void: emitted.append(what))
	click.set_tab(click.tabs().find("veil"))
	var before := click.draft.picks.duplicate()
	click.click(PrepareScreen.cell_rect(Array(click.shown()).find("doom")).get_center())
	t.check(click.draft.picks == before and click.refused_reason == "Not enough Divine Power",
		"a card over the Divine Power is refused with its reason ('%s', %s)" % [click.refused_reason, click.draft.picks])
	click.draft.preselect(PackedStringArray(["doom", "wisp", "discord", "heaven", "blight", "thorns"]))
	click.set_tab(click.tabs().find("ruin"))
	before = click.draft.picks.duplicate()
	click.click(PrepareScreen.cell_rect(Array(click.shown()).find("tornado")).get_center())
	t.check(click.draft.picks == before and click.refused_reason == "No free slot",
		"a card with no free slot is refused with its reason ('%s', %s)" % [click.refused_reason, click.draft.picks])
	click.draft.preselect(PackedStringArray(["heaven"]))
	t.check(click.can_manifest(), "one pick lights MANIFEST")
	click.draft.preselect(PackedStringArray())
	click.refused_reason = ""
	click.click(PrepareScreen.MANIFEST_RECT.get_center())
	t.check(not click.can_manifest() and emitted.is_empty() and click.refused_reason != "",
		"MANIFEST with nothing picked does not go, and says why (%s, '%s')" % [emitted, click.refused_reason])
	click.draft.preselect(PackedStringArray(["heaven"]))
	click.click(PrepareScreen.MANIFEST_RECT.get_center())
	t.check(emitted.size() == 1 and emitted[0] == "manifest", "and with one pick it does (%s)" % [emitted])
	click.free()
	t.check(PrepareScreen.cooldown_text(PowerBook.get_power("doom")) == "10 s"
		and PrepareScreen.cooldown_text(PowerBook.get_power("nova")) == "120 s",
		"a card shows Silent Doom's 10 s and Nova's 120 s without a decimal")
	t.check(PrepareScreen.cooldown_text({"cooldown": 2.5}) == "2.5 s", "and a fractional cooldown with one")

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
