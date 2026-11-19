extends RefCounted
## God's Chamber Task 1: HubStatus, the hub's words and decisions without the drawing -- the lines, Notice, Hunt, seal, gifts, what Awaken
## offers, what a press decides (emit, buzz, line), the bar's fill and whether any Faith row can be bought. The same fixtures as
## test_faith_hub.gd, asked of HubStatus directly.


static func run(t) -> void:
	GodTree.dev_fill = true
	_lines(t)
	_notice_hunt_seal(t)
	_gifts(t)
	_bar_fill(t)
	_faith_affordable(t)
	_press_plain(t)
	_awaken_rite(t)
	_awaken_unwritten(t)
	_awaken_hidden(t)
	_awaken_hunt(t)
	_awaken_refused_dev(t)
	_blocked(t)
	_awaken_blocked(t)
	GodTree.dev_fill = false


static func _slot(type := "ruin") -> GodSlot:
	return GodSlot.make(1, type, 7)


static func _capped(level: int, tier := 1) -> GodSlot:
	var god := _slot()
	god.tier = tier
	god.level = level
	god.divine_power = god.need()
	return god


static func _lines(t) -> void:
	var god := _slot()
	var st := HubStatus.new(god)
	t.check(Array(st.lines()) == ["RUIN", "Level 1   Whisper", "0 / 50 Divine Power", "Ability points 0", "Faith 0", "Lantern Notice 0%",
		"Night 1"], "a fresh ruin god's lines (%s)" % [st.lines()])
	god.level = 10
	god.divine_power = 50
	t.check(HubStatus.bar_text(god) == "AWAKEN TO GROW", "capped below 50: the bar says to Awaken (%s)" % HubStatus.bar_text(god))
	god.tier = 5
	god.level = 50
	god.divine_power = 250
	t.check(HubStatus.bar_text(god) == "MAX LEVEL", "level 50 is max level (%s)" % HubStatus.bar_text(god))
	god.points = 4
	god.faith = 77
	god.night = 6
	t.check(Array(st.lines()) == ["RUIN", "Level 50   Ascendance", "MAX LEVEL", "Ability points 4", "Faith 77", "Lantern Notice 0%",
		"Night 7"], "the lines follow the god (%s)" % [st.lines()])


static func _notice_hunt_seal(t) -> void:
	var god := _slot()
	var st := HubStatus.new(god)
	t.check(is_zero_approx(st.notice_fill()), "Notice 0: an empty meter")
	god.notice = 75
	t.check(st.lines()[5] == "Lantern Notice 75%" and is_equal_approx(st.notice_fill(), 0.75), "Notice 75: line and meter")
	god.notice = 100
	t.check(is_equal_approx(st.notice_fill(), 1.0) and st.hunt_line() == HubStatus.HUNT_DUE % GodNight.HUNTS[0].title,
		"Notice 100: a full meter and the Hunt named (%s)" % st.hunt_line())
	god.notice = 99
	t.check(st.hunt_line() == "", "at 99 the Hunt says nothing")
	t.check(st.seal_line() == "", "no seal: no line")
	var key: String = GodTree.starting("ruin")[0]
	var name: String = PowerBook.get_power(key).name
	god.sealed = key
	god.seal_nights = 3
	t.check(st.seal_line() == "Sealed by the Lantern: %s, 3 nights left" % name, "a seal of 3 nights (%s)" % st.seal_line())
	god.seal_nights = 1
	t.check(st.seal_line() == "Sealed by the Lantern: %s, 1 night left" % name, "a seal of 1 night (%s)" % st.seal_line())


static func _gifts(t) -> void:
	var god := _slot()
	var st := HubStatus.new(god)
	t.check(st.gifts_line() == "", "no gifts: no line")
	god.gifts = PackedStringArray([RiteBook.WATCHFUL_BELL])
	t.check(st.gifts_line() == "Stolen gifts: The Watchful Bell", "one gift (%s)" % st.gifts_line())
	god.gifts = PackedStringArray([RiteBook.WATCHFUL_BELL, "nobody_knows"])
	t.check(st.gifts_line() == "Stolen gifts: The Watchful Bell", "an unknown id is not named (%s)" % st.gifts_line())
	t.check(st.lines().size() == 7, "the lines stay seven with gifts present")


static func _bar_fill(t) -> void:
	var god := _slot()
	var st := HubStatus.new(god)
	t.check(is_zero_approx(st.bar_fill()), "no Divine Power: an empty bar (%s)" % st.bar_fill())
	god.divine_power = god.need() / 2
	t.check(is_equal_approx(st.bar_fill(), float(god.divine_power) / float(god.need())) and st.bar_fill() > 0.4 and st.bar_fill() < 0.6,
		"half the need: about half a bar (%s)" % st.bar_fill())
	t.check(is_equal_approx(HubStatus.new(_capped(10)).bar_fill(), 1.0), "capped: a full bar")


static func _faith_affordable(t) -> void:
	var god := _slot()
	var st := HubStatus.new(god)
	god.faith = 0
	t.check(not st.faith_affordable(), "Faith 0: nothing to buy")
	# +1 MIGHT at 25 is the cheapest row a fresh god can buy (RESET needs a point spent).
	god.faith = 24
	t.check(not st.faith_affordable(), "Faith one short of the cheapest row: nothing to buy")
	god.faith = 25
	t.check(st.faith_affordable(), "Faith enough for the cheapest row: something to buy")


static func _press_plain(t) -> void:
	var st := HubStatus.new(_slot())
	for what in ["descend", "tree", "faith", "title"]:
		t.check(st.press(what) == {"emit": what, "buzz": false, "line": ""}, "%s decides to emit itself (%s)" % [what, st.press(what)])
	t.check(st.press("tree", true, true).emit == "tree", "the key and dev flags change nothing for the plain buttons")


static func _awaken_rite(t) -> void:
	var st := HubStatus.new(_capped(10))
	t.check(st.awaken == "rite" and st.awaken_shown() and not st.awaken_dim(), "capped level 10: a rite, Awaken shown and lit")
	t.check(st.press("awaken") == {"emit": "awaken", "buzz": false, "line": ""}, "a click emits awaken (%s)" % [st.press("awaken")])
	t.check(st.press("awaken", true).emit == "awaken" and st.press("awaken", true, true).emit == "awaken", "A emits awaken with or without dev")


static func _awaken_unwritten(t) -> void:
	var st := HubStatus.new(_capped(20, 2))
	t.check(st.awaken == "unwritten" and st.awaken_shown() and st.awaken_dim(), "tier 2 level 20: Awaken shown and dim")
	var r := st.press("awaken")
	t.check(r.emit == "" and r.buzz and r.line == HubStatus.RITE_UNWRITTEN and HubStatus.RITE_UNWRITTEN == "Rite not yet written",
		"a click buzzes and says the rite is not written (%s)" % [r])
	r = st.press("awaken", true)
	t.check(r.emit == "" and r.buzz and r.line == HubStatus.RITE_UNWRITTEN, "A without dev does the same (%s)" % [r])
	t.check(st.press("awaken", true, true) == {"emit": "awaken_dev", "buzz": false, "line": ""}, "A under dev is the awaken_dev hook")
	t.check(st.press("awaken", false, true).emit == "", "a click under dev is not the hook")
	var top := HubStatus.new(_capped(50, 5))
	t.check(not top.awaken_shown() and not top.awaken_dim(), "level 50: no Awaken")


static func _awaken_hidden(t) -> void:
	var god := _capped(10)
	god.level = 9
	god.divine_power = 0
	var st := HubStatus.new(god)
	t.check(not st.awaken_shown() and not st.awaken_dim() and st.awaken == "", "level 9: no Awaken")
	t.check(st.press("awaken") == {"emit": "", "buzz": false, "line": ""}, "a click does nothing, silently")
	t.check(st.press("awaken", true) == {"emit": "", "buzz": false, "line": ""}, "A without dev does nothing, silently")
	t.check(st.press("awaken", true, true) == {"emit": "awaken_dev", "buzz": false, "line": ""}, "A under dev is the awaken_dev hook")


static func _awaken_hunt(t) -> void:
	for level_tier in [[10, 1], [20, 2]]:
		var god := _capped(int(level_tier[0]), int(level_tier[1]))
		god.notice = 100
		var st := HubStatus.new(god)
		t.check(st.awaken_shown() and not st.awaken_dim(), "level %d at Notice 100: Awaken lit, the Hunt leads" % int(level_tier[0]))
		t.check(st.press("awaken").emit == "awaken" and st.press("awaken", true).emit == "awaken" and st.press("awaken").line == "",
			"click and A emit awaken for the Hunt (level %d)" % int(level_tier[0]))


static func _awaken_refused_dev(t) -> void:
	var god := _slot()
	god.notice = 100
	var st := HubStatus.new(god)
	var r := st.press("awaken", true, true)
	t.check(r.emit == "" and r.buzz and r.line == HubStatus.AWAKEN_HUNT and HubStatus.AWAKEN_HUNT == "The Lantern hunts: face the Hunt first",
		"dev A, not capped, Hunt due: refused with its words (%s)" % [r])
	god.notice = 99
	t.check(st.press("awaken", true, true) == {"emit": "awaken_dev", "buzz": false, "line": ""}, "at 99 it is the dev hook")


static func _blocked(t) -> void:
	GodTree.dev_fill = false
	GodTree.use_table(GodTree.blank())
	var st := HubStatus.new(_slot())
	t.check(not st.can_descend() and st.blocked_line() == HubStatus.BLOCKED, "with the tree empty the god cannot Descend (%s)" % st.blocked_line())
	t.check(st.press("descend") == {"emit": "", "buzz": true, "line": ""}, "Descend buzzes and emits nothing (%s)" % [st.press("descend")])
	t.check(st.press("tree").emit == "tree", "the other buttons still work")
	GodTree.use_table({})
	GodTree.dev_fill = true
	var full := HubStatus.new(_slot())
	t.check(full.can_descend() and full.blocked_line() == "", "with a filled tree it can Descend and has no blocked line")


static func _awaken_blocked(t) -> void:
	GodTree.dev_fill = false
	GodTree.use_table(GodTree.blank())
	var st := HubStatus.new(_capped(10))
	t.check(st.awaken_shown() and not st.can_descend() and st.awaken_dim(), "nothing to draft: Awaken shown and dim")
	t.check(st.press("awaken") == {"emit": "", "buzz": true, "line": ""} and st.press("awaken", true) == {"emit": "", "buzz": true, "line": ""},
		"the click and A buzz and emit nothing")
	GodTree.use_table({})
	GodTree.dev_fill = true
	t.check(not HubStatus.new(_capped(10)).awaken_dim(), "with a filled tree Awaken is lit again")
