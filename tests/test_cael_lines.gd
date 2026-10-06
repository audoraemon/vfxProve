extends RefCounted
## v0.10 M5 Cael's lines during missions (spec §5.2): the words, kept in CampaignText as the spec gives them; each fits
## the screen as the HUD shows it, his name before it; a director speaks only the lines its own mission has.

## The spec's table, word for word: [mission, event, line].
const SPEC := [["miras_house", "venn", "Venn. She lit Mira's pyre."],
	["miras_house", "fire", "They're burning her again. Get them out."],
	["vigil_flame", "wren", "The boy wants that lantern. Let him have it."],
	["vigil_flame", "light", "He's looking. Don't let him see the boy."],
	["broken_lanterns", "drained", "Feel that? That was his."],
	["broken_lanterns", "knights", "Odran's knights. He's frightened."]]


static func run(t) -> void:
	var wrong := PackedStringArray()
	var wide := PackedStringArray()
	for row: Array in SPEC:
		var said := CampaignText.cael_line(String(row[0]), String(row[1]))
		if said != String(row[2]):
			wrong.append("%s/%s" % [row[0], row[1]])
		# Review focus 5: each fits the screen with his name before it, 16 px in from either side.
		if Hud.subtitle_width(said) > Hud.SCREEN_W - 32.0:
			wide.append("%s/%s %.0f px" % [row[0], row[1], Hud.subtitle_width(said)])
	t.check(wrong.is_empty(), "Cael's six lines are the spec's (wrong: %s)" % ", ".join(wrong))
	t.check(wide.is_empty(), "each fits the screen with his name before it (too wide: %s)" % ", ".join(wide))
	t.check(CampaignText.cael_line("miras_house", "nonsense") == "" and CampaignText.cael_line("warning", "venn") == "",
		"an event or a mission he has no line for gives none")
	t.check(Hud.speaker() == "CAEL", "the HUD names him (%s)" % Hud.speaker())

	var rules := Rules.new()
	rules.mission = MissionBook.miras_house()
	var d := MissionDirector.new()
	d.rules = rules
	var heard := []
	rules.subtitle.connect(func(text: String) -> void: heard.append(text))
	d._say("venn")
	d._say("nonsense")
	t.check(heard == [CampaignText.cael_line("miras_house", "venn")],
		"a director speaks its mission's line, and only that (%s)" % [heard])
	rules.mission = MissionBook.warning()
	d._say("venn")
	t.check(heard.size() == 1, "The Warning has no lines of his")
	rules.mission = null
	d._say("venn")
	t.check(heard.size() == 1, "nor does a director with no mission")
	rules.free()
