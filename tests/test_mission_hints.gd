extends RefCounted
## v0.10 M6 how to win (spec §3): the lines are the spec's, word for word; a phase's line, the fallbacks; a line for every
## mission and act the game plays; and each fits the HUD's plate (HINT_LINES lines of HINT_W).

## The spec's table: [key, line].
const SPEC := [
	["warning", "Stop the messenger (gold arrow) before the bell tolls, or hold out until the omen fades."],
	["omen", "Stop the messenger (gold arrow) before the bell tolls, or hold out until the omen fades."],
	["festival", "Break the festival: kill or scatter fifty of its crowd before the guard closes the square."],
	["procession", "Kill the Prince before he boards his ship. If no one sees him die, the town is left leaderless."],
	["judgement", "Bring the Citadel down before dawn, before too many of its people escape."],
	["last_judgement", "Destroy the Citadel and break the city before time runs out. Fifty escaping loses it."],
	["miras_house", "Whisper a grieving (gold) to Mira's door while no Faithful (red) watches. Four must believe by dawn."],
	["miras_house.four", "Four believe. Keep the Believers (orange) alive until dawn, and the Gaze from filling."],
	["miras_house.burning", "Her house burns: no one can go in now. Keep your Believers (orange) alive until dawn."],
	["broken_lanterns", "Break a lantern (gold), then keep the flame-bearer off it for 20 s while it drains. Drain all six."],
	["broken_lanterns.knights", "A Knight (blue) shields the lantern he guards. Draw him off or kill him, then strike."],
	["vigil_flame", "Soon the boy Wren comes for the flame (gold). Its acolytes would see him: draw them off first."],
	["vigil_flame.wren", "Whisper Wren (blue) to the flame (gold) while no Faithful but its bearer is near him (red)."],
	["vigil_flame.homeward", "The Vigil turns for home: have the flame swapped before its bearer reaches the Temple."],
	["vigil_flame.carry", "Walk Wren to Mira's shrine (orange), west past the wall. Keep him out of the searchlight."],
]


static func run(t) -> void:
	var spec := {}
	var wrong := PackedStringArray()
	for row: Array in SPEC:
		spec[row[0]] = row[1]
		if String(MissionHints.LINES.get(row[0], "")) != String(row[1]):
			wrong.append(String(row[0]))
	t.check(wrong.is_empty() and MissionHints.LINES.size() == SPEC.size(),
		"the lines are the spec's (wrong: %s; %d lines)" % [", ".join(wrong), MissionHints.LINES.size()])
	t.check(MissionHints.line("miras_house", "burning") == spec["miras_house.burning"], "a phase's own line")
	t.check(MissionHints.line("miras_house", "dawn") == spec["miras_house"] and MissionHints.line("miras_house") == spec["miras_house"],
		"a phase with no line of its own, or none, gives the mission's")
	t.check(MissionHints.line("nowhere") == "" and MissionHints.line("nowhere", "burning") == "", "an unknown mission has none")

	# Every mission and act the game plays: the board's, the campaign's, The Long Night's acts and the Feast's.
	var played: Array[MissionDef] = []
	for m: MissionDef in [MissionBook.warning(), MissionBook.long_night(), MissionBook.last_judgement(),
			MissionBook.miras_house(), MissionBook.vigil_flame(), MissionBook.broken_lanterns(), MissionBook.feast("festival"),
			MissionBook.feast("procession")]:
		if m.has_acts():
			for a in m.acts:
				played.append(a)
		else:
			played.append(m)
	var missing := PackedStringArray()
	for m in played:
		if MissionHints.line(m.id) == "":
			missing.append(m.id)
	t.check(missing.is_empty(), "every mission and act played has a line (missing: %s)" % ", ".join(missing))

	var long := PackedStringArray()
	for key: String in MissionHints.LINES:
		if UiTheme.wrap(String(MissionHints.LINES[key]), Hud.HINT_W, UiTheme.SIZE_SMALL).size() > Hud.HINT_LINES:
			long.append(key)
	t.check(long.is_empty(), "every line fits %d lines of %d px (too long: %s)" % [Hud.HINT_LINES, int(Hud.HINT_W),
		", ".join(long)])
	t.check(Hud.hint_lines("").is_empty() and Hud.hint_lines(spec["miras_house"]).size() == Hud.HINT_LINES,
		"no line, no plate; Mira's House's takes the plate's three lines")
	t.check(MissionDirector.new().hint_phase() == "", "a director has no phase of its own by default")
