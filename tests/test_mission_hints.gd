extends RefCounted
## v0.10 M6 how to win (spec §3): the lines are the spec's, word for word; a phase's line, the fallbacks; a line for every
## mission and act the game plays; and each fits the HUD's plate (HINT_LINES lines of HINT_W).

## The spec's table: [key, line].
const SPEC := [
	# The board missions' (board tags, spec §3).
	["warning", "Kill the messenger (gold) with no one near (red) before he warns the bellkeeper (blue)."],
	["warning.relay", "Someone saw: a witness (gold) carries the warning on. Strike again where no one (red) is near."],
	["warning.bell", "The bell is called. Kill its ringer (gold) unseen before the bell tolls."],
	["warning.waiting", "That warning is dead. Watch the next star's gate (gold): its watchman runs when it falls."],
	["omen", "Kill the messenger (gold) with no one near (red) before he warns the bellkeeper (blue)."],
	["omen.relay", "Someone saw: a witness (gold) carries the warning on. Strike again where no one (red) is near."],
	["omen.bell", "The bell is called. Kill its ringer (gold) unseen before the bell tolls."],
	["festival", "Break the festival: kill or scatter enough of its crowd (gold) before the guard closes the square."],
	["festival.packed", "The bonfire packs the crowd (gold) round the fountain: one strike there breaks many."],
	["festival.address", "The Mayor (orange) speaks from the fountain. Kill him and the crowd round it panics."],
	["procession", "Kill the Prince (gold) before he boards. If no one near (red) sees it, the town is left leaderless."],
	["procession.blessing", "The Prince holds at the cathedral steps for the blessing. Strike while he stands still."],
	["procession.dock", "The Prince waits at the dock. He boards as soon as his ship is in: kill him first."],
	["judgement", "Bring the Citadel (gold) down before dawn, before too many of its people escape by the gates (red)."],
	["judgement.rite", "The clergy gather for the Banishing Rite (red). Break it, or it cuts your time short."],
	["judgement.fallen", "The Citadel is down. Break the city's stability before dawn, and keep its people in."],
	["last_judgement", "Destroy the Citadel (gold) and break the city in time. Fifty escaping by the gates (red) loses it."],
	["last_judgement.rite", "The clergy gather for the Banishing Rite (red). Break it, or it cuts your time short."],
	["last_judgement.fallen", "The Citadel is down. Break the city's stability before time runs out. Fifty escaping loses it."],
	["miras_house", "Whisper a grieving (gold) to Mira's door while no Faithful (red) watches. Four must believe by dawn."],
	["miras_house.four", "Four believe. The night is won: ascend, or keep the Gaze from filling until dawn."],
	["miras_house.burning", "Her house burns: no one can go in now. Keep your Believers (orange) alive until dawn."],
	["broken_lanterns", "Break a lantern (gold), then keep the flame-bearer off it for 20 s while it drains. Drain all six."],
	["broken_lanterns.knights", "A Knight (blue) shields the lantern he guards. Draw him off or kill him, then strike."],
	["vigil_flame", "Soon the boy Wren comes for the flame (gold). Its acolytes would see him: draw them off first."],
	["vigil_flame.wren", "Whisper Wren (blue) to the flame (gold) while no Faithful but its bearer is near him (red)."],
	["vigil_flame.homeward", "The Vigil turns for home: have the flame swapped before its bearer reaches the Temple."],
	["vigil_flame.carry", "Walk Wren to Mira's shrine (orange), west past the wall. Keep him out of the searchlight."],
	# The Tax Collector (v0.11 M2; three collectors, the controller's Task 2 ruling).
	["tax_collector", "Kill each collector (gold) in the street. If no one near (red) sees it, the guards raise no cry."],
	["tax_collector.inside", "He is indoors (gold). He comes out to walk to his next debtor (orange): be ready."],
	["tax_collector.hiding", "Alarmed, he hides in the counting-house. Set it alight to smoke him out, or wait for him."],
	["tax_collector.safe", "His rounds are done. He takes the taxes to the Citadel (red): kill him before he gets in."],
	["tax_collector.next", "One down. The next collector (gold) leaves the counting-house soon: be ready for him."],
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
	for m in MissionBook.tier_missions():
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
