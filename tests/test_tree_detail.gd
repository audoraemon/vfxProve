extends RefCounted
## Skill Tree wheel Task 2: what the detail panel says -- blurbs, the stats the next level changes, the tags and the buy button.


static func run(t) -> void:
	_rows(t)
	_same_text(t)
	_tags(t)
	_column(t)
	_button(t)
	_blurbs(t)


static func _slot(type := "dominion", tier := 1, points := 0) -> GodSlot:
	var slot := GodSlot.make(1, type, 7)
	slot.tier = tier
	slot.points = points
	return slot


static func _rows(t) -> void:
	var rows := PowerBook.level_rows("wisp", 3)
	var labels := PackedStringArray()
	var changes := PackedStringArray()
	for r: Dictionary in rows:
		labels.append(r.label)
		changes.append("%s -> %s" % [r.old, r.new])
	t.check(labels == PackedStringArray(["lure cap", "lure time", "enthrall", "cooldown"]),
		"wisp 3 changes four stats in table order (%s)" % [labels])
	t.check(changes == PackedStringArray(["27 -> 30", "13.0 -> 14.0", "32.0 -> 34.0", "28.0 -> 26.0"]),
		"and prints them as level_change() does (%s)" % [changes])
	t.check(PowerBook.level_rows("wisp", 1).is_empty() and PowerBook.level_rows("thorns", 3).is_empty(),
		"level 1 and a power with no table have no rows")
	t.check(not (PowerBook.level_rows("wisp", 5) as Array).any(func(r: Dictionary) -> bool: return r.label == "twist"),
		"the twist is not a row")


static func _same_text(t) -> void:
	t.check(PowerBook.level_change("wisp", 3) == "lure cap 27 -> 30, lure time 13.0 -> 14.0, enthrall 32.0 -> 34.0, cooldown 28.0 -> 26.0",
		"wisp 3 reads as before (%s)" % [PowerBook.level_change("wisp", 3)])
	t.check(PowerBook.level_change("smite", 5) == "kill radius 0.75 -> 0.8, damage 60.0 -> 65.0, cooldown 8.5 -> 8.0, Forked Bolt: leaps to one more nearby",
		"smite 5 reads as before (%s)" % [PowerBook.level_change("smite", 5)])
	t.check(PowerBook.level_change("schism", 5) == "region 17.0 -> 18.0, fighters 170 -> 180, length 32.0 -> 35.0, Turn the Tide: click a fighter to turn them",
		"schism 5 reads as before (%s)" % [PowerBook.level_change("schism", 5)])
	t.check(PowerBook.level_change("smite", 1) == "" and PowerBook.level_change("thorns", 2) == PowerBook.NO_LEVELS
		and PowerBook.NO_LEVELS == "Levels to come", "level 1 says nothing; no table says Levels to come")


static func _tags(t) -> void:
	t.check(TreeDetail.tags("wisp") == PackedStringArray(["DOMINION", "TIER II", "QUIET"]), "wisp tags (%s)" % [TreeDetail.tags("wisp")])
	t.check(TreeDetail.tags("smite") == PackedStringArray(["RUIN", "TIER I", "LOUD"]), "smite tags (%s)" % [TreeDetail.tags("smite")])


static func _column(t) -> void:
	var s := _slot()
	s.learned["wisp"] = 2
	var c := TreeDetail.level_column(s, "wisp")
	t.check(c.head == "LEVEL 2 -> 3" and (c.rows as Array).size() == 4 and c.might == "2 -> 3" and String(c.twist).begins_with("Level 5 . "),
		"wisp at 2: head, 4 rows, Might, twist (%s)" % [c])
	s.learned["wisp"] = 5
	c = TreeDetail.level_column(s, "wisp")
	t.check(c.head == "MAX" and (c.rows as Array).is_empty() and c.might == "4", "wisp at 5 is MAX (%s)" % [c])
	s.learned.erase("wisp")
	c = TreeDetail.level_column(s, "wisp")
	var same := true
	for r: Dictionary in c.rows:
		same = same and r.old == r.new
	t.check(c.head == "LEARN" and (c.rows as Array).size() == 4 and same, "unlearned: LEARN, level 1's numbers (%s)" % [c])
	c = TreeDetail.level_column(s, "thorns")
	t.check(c.head == "Levels to come" and (c.rows as Array).is_empty() and c.twist == "", "no table: Levels to come (%s)" % [c])


static func _button(t) -> void:
	var s := _slot("dominion", 3, 0)
	var b := TreeDetail.buy_button(s, "wisp", 2)
	t.check(b.label == "LEARN" and not b.enabled and b.reason == "Not enough ability points", "no points: refused (%s)" % [b])
	s.points = 10
	b = TreeDetail.buy_button(s, "wisp", 2)
	t.check(b.enabled and b.reason == "" and b.cost == 1, "points: LEARN is enabled for 1 (%s)" % [b])
	s.learned["wisp"] = 2
	t.check(TreeDetail.buy_button(s, "wisp", 2).label == "RAISE", "learned: RAISE")
	s.learned["wisp"] = 5
	b = TreeDetail.buy_button(s, "wisp", 2)
	t.check(b.label == "MAX" and not b.enabled, "level 5: MAX, disabled (%s)" % [b])
	var low := _slot("dominion", 1, 10)
	t.check(TreeDetail.buy_button(low, "clearmind", 3).reason == "Awaken to Tier 3", "a tier-3 key for a tier-1 god (%s)" % [TreeDetail.buy_button(low, "clearmind", 3)])
	var own: int = TreeDetail.buy_button(_slot("dominion", 3, 10), "wisp", 2).cost
	var far: int = TreeDetail.buy_button(_slot("ruin", 3, 10), "wisp", 2).cost
	t.check(own == 1 and far == 2 * own, "a neighbour's cost is twice the own type's (%d, %d)" % [own, far])


static func _blurbs(t) -> void:
	var bad := PackedStringArray()
	var n := 0
	for type: String in GodTree.TABLE:
		for tier: Array in GodTree.TABLE[type]:
			for key: String in tier:
				if key == "":
					continue
				n += 1
				var d := TreeDetail.description(key, TreeDetail.DESCRIPTION_W)
				if PowerBook.blurb(key) == "" or d.size() > 3 or (d.size() > 0 and d[d.size() - 1].ends_with("...")):
					bad.append(key)
	t.check(n == 52 and bad.is_empty(), "all %d table keys have a blurb that fits three lines at %d px (%s)" % [n, int(TreeDetail.DESCRIPTION_W), bad])
	t.check(PowerBook.blurb("nova") == "Huge circle", "a row with no blurb falls back to its shape, capitalised (%s)" % [PowerBook.blurb("nova")])
