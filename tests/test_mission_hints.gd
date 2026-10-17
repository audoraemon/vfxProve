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
	["vigil_flame.wren", "Whisper or lure Wren (blue) to the flame (gold) while no Faithful but its bearer is near him (red)."],
	["vigil_flame.homeward", "The Vigil turns for home: have the flame swapped before its bearer reaches the Temple."],
	["vigil_flame.carry", "Walk Wren to Mira's shrine (orange), west past the wall. Keep him out of the searchlight."],
	# The Tax Collector (v0.11 M2; three collectors, the controller's Task 2 ruling).
	["tax_collector", "Kill each collector (gold) in the street. If no one near (red) sees it, the guards raise no cry."],
	["tax_collector.inside", "He is indoors (gold). He comes out to walk to his next debtor (orange): be ready."],
	["tax_collector.hiding", "Alarmed, he hides in the counting-house. Set it alight: every collector inside runs for the Citadel."],
	["tax_collector.running", "No hiding place: he runs for the Citadel (red). Kill him before he gets in."],
	["tax_collector.safe", "His rounds are done. He takes the taxes to the Citadel (red): kill him before he gets in."],
	["tax_collector.next", "One down. The next collector (gold) leaves the counting-house soon: be ready for him."],
	# Spoiled Harvest (v0.11 M2).
	["spoiled_harvest", "Strike down a granary's two watchmen (red), then keep it burning 10 s before its carter (blue) empties it."],
	["spoiled_harvest.empty", "No grain yet: fire on an empty granary does nothing. Clear its watchmen (red) shortly before the grain comes."],
	["spoiled_harvest.watchman", "A watchman (red) puts the fire out within 3 s. Strike down, scare off or whisper away every one first."],
	["spoiled_harvest.burning", "It burns, with no one to put it out. Keep it burning 10 s, or bring it down, before a new watchman comes."],
	# The Lost Lamb (v0.11 M2).
	["lost_lamb", "Whisper the acolyte (blue) toward the west gate, and again before he stops. Soldiers (red) seize him on sight."],
	["lost_lamb.caught", "He is caught. Discord the soldier taking him back (red), or strike once the acolyte is clear of him, before the Temple."],
	["lost_lamb.gate", "The watch (red) holds the gate. It changes soon: bring him close, or draw the watch off."],
	["lost_lamb.clear", "The watch is changing. Send him through the gate now."],
	# First Prayers (v0.11 M2).
	["first_prayers", "Whisper the poor (gold) to the old well shrine while no Faithful (red) watches. Three must pray."],
	["first_prayers.watched", "Faithful (red) crowd the shrine's door. Draw them off, or let them go before you send anyone in."],
	# The Bell-Ringers (v0.11 M3).
	["bell_ringers", "Kill each ringer (gold) where no one (red) sees, before he climbs the bell tower. His mates run with him."],
	["bell_ringers.mates", "His mates (red) would see him die and run on. Draw them off or strike them first."],
	["bell_ringers.relay", "Someone saw: a witness (gold) carries the warning on. Strike again where no one (red) is near."],
	["bell_ringers.climbing", "He climbs the bell (gold). Pull him off with a whisper or a fright, or kill him unseen before the bar fills."],
	["bell_ringers.bell", "The town calls its bellkeeper (blue). Stop him before the bell tolls."],
	["bell_ringers.waiting", "That warning is dead. The next post (gold) sends its ringer soon. A loud power near a post sends him at once."],
	# Market Panic (v0.11 M3).
	["market_panic", "Strike the wardens (red), then scatter the crowd (gold). Thirty-six must break; crowds still waiting count if struck down."],
	["market_panic.steadied", "A warden (red) steadies the crowd near him: frights break no one there. Remove them all first."],
	["market_panic.open", "No warden stands. Strike the crowd (gold) now, before a new warden comes."],
	["market_panic.coming", "More come to the fair (gold). Strike them on the way, away from the wardens, or when they arrive."],
	# The Informer (v0.11 M3).
	["informer", "Whisper the contact (orange) while no one (red) sees. He names the next. Do not kill a contact."],
	["informer.waiting", "Word has not reached the contact (grey) yet. Get his company (red) away before it does. Do not kill a contact."],
	["informer.found", "He is found and runs for the Temple (red). Kill him before he gets in. Unseen, no cry is raised."],
	["informer.hiding", "Alarmed, he hides. Set the house alight to smoke him out, or wait for him."],
	["informer.running", "No hiding place: he runs for the Temple (red). Kill him before he gets in."],
	# The Crown's Bread (v0.11 M4).
	["crowns_bread", "Remove a target's engineers (red), then bring it down (gold) while it is in use: the granary, the mill, the bridge."],
	["crowns_bread.not_yet", "Not in use yet (grey). A fall counts only if it is still down when its time comes. Clear its engineers (red) shortly before."],
	["crowns_bread.engineers", "Engineers (red) mend it, put out its fires and rebuild it. Remove every one first."],
	["crowns_bread.open", "No engineer stands. Bring it down now, before a relief comes. The bridge takes blows, not fire."],
	# The Prisoner (v0.11 M4).
	["prisoner", "Whisper or lure her (blue) toward the postern, and again before she stops. Watchmen (red) seize her on sight."],
	["prisoner.bound", "Remove both gaolers (red): one left seizes her for the Citadel. Then burn the stocks (orange) or strike their far side."],
	["prisoner.caught", "She is caught. Whisper or Discord the man taking her back (red), or strike once she is clear of him."],
	["prisoner.hounds", "The Citadel's hounds (red) follow her. Strike them or turn them before they see her."],
	["prisoner.gate", "The watch (red) holds the postern. It changes soon: bring her close, or draw the watch off."],
	["prisoner.clear", "The guard is changing. Send her through the postern now."],
	# The Heretic Hunt (v0.11 M4).
	["heretic_hunt", "Clear a standard's guards (red), then break the standard (gold). Three standards, then the captain."],
	["heretic_hunt.guarded", "Its guards (red) hold the standard: blows only shake it. Remove every one first."],
	["heretic_hunt.open", "The standard (gold) stands unguarded. Break it now with a blow or Blight, before a new guard comes."],
	["heretic_hunt.waiting", "The hunt moves on soon. Clear the next sweep's guards (red) shortly before it comes."],
	["heretic_hunt.coming", "The captain comes out of the Temple (grey) in {n} s. Be ready on his road to your cellar (blue)."],
	["heretic_hunt.captain", "The captain (gold) leads the last sweep to your cellar (blue). Kill him before he finds it."],
	["heretic_hunt.searching", "The captain searches the houses by your cellar. Kill him before he reaches its door."],
	# The Bishop (v0.11 M5).
	["bishop", "Burn each refuge the bishop hides in (gold), once its Knights (red) are dead. The Temple last: then kill him in the square."],
	["bishop.waiting", "He reaches his next refuge in {n} s. Kill its Knights (red) shortly before he comes."],
	["bishop.guarded", "His Knights (red) beat out fire. Kill them, or whisper, Discord or lure them off: each walks back."],
	["bishop.open", "No Knight stands. Set the refuge (gold) alight before a new Knight comes."],
	["bishop.burning", "It burns. Keep it burning: his Knights (red) put out a fire they stand by."],
	["bishop.square", "He is in the square and makes for the Citadel (red). Kill him before he gets in."],
	["bishop.running", "Alarmed, he runs for the Citadel (red). Kill him now."],
	# The Armoury (v0.11 M5).
	["armoury", "Kill a target's armed men (red), then destroy it once it musters (gold): two barracks, then the armoury."],
	["armoury.not_yet", "Not mustering yet (grey): fire goes out, and a fall counts when its horn sounds. Kill its night watch (red) shortly before."],
	["armoury.guarded", "Armed men (red) guard it: it takes no harm. Kill them, or whisper one off: he walks back."],
	["armoury.open", "No guard stands. Destroy it now: more armed men march from the Citadel, faster each minute."],
	["armoury.stone", "The gate barracks is stone: blows, not fire."],
	# The Sermon (v0.11 M5).
	["sermon", "Silence the preacher (red), then whisper his crowd (gold) to the god's house unseen. Eight must believe: kill none."],
	["sermon.rapt", "He preaches: his crowd hears only him. Whisper or Discord him aside; kill him unseen by his acolytes. Never kill his crowd."],
	["sermon.watched", "Sentries (red) watch the door: anyone seen going in is turned away and reported. Remove them first."],
	["sermon.report", "A Faithful runs to the Temple. Stop him before he gets there, unseen."],
	["sermon.coming", "More come to hear him (gold). Whisper them on the way, before they come within his voice. Do not kill them."],
	["sermon.seen", "A death was seen: the Gaze rises. Four seen deaths in a district call the bell, and the bell fills the Gaze."],
	["sermon.bell", "The bellkeeper (red) runs to ring the bell, and the bell fills the Gaze. Stop him, unseen."],
	# The Relic Run (v0.11 M5).
	["relic_run", "Bring Pip (blue) to the cart's first halt. He slips aboard there, and swaps the relic at the next."],
	["relic_run.moving", "The cart (gold) moves. Its reliquary opens only at a checkpoint. Clear the next one's wardens (red) shortly before."],
	["relic_run.watched", "The cart halts, watched (red). Hold or remove the watch: Pip only works unseen."],
	["relic_run.aboard", "Pip is aboard and picks the lock. At the next halt, clear the watch so he can swap the relic."],
	["relic_run.carry", "Pip has the relic. Keep him out of the light (a touch costs half the Gaze) on his way to your believers' house (orange)."],
	["relic_run.last_halt", "The cart rolls to its last halt before the Citadel. Bring Pip (blue) there: he can board and swap in that one halt."],
	["relic_run.citadel", "The cart makes for the Citadel (red) and halts no more: the relic is lost when it gets there."],
	["relic_run.report", "A Faithful runs to the Temple. Stop him before he gets there, unseen."],
	["relic_run.seen", "A death was seen: the Gaze rises. Four seen deaths in a district call the bell, and the bell fills the Gaze."],
	["relic_run.bell", "The bellkeeper (red) runs to ring the bell, and the bell fills the Gaze. Stop him, unseen."],
	# The Lantern's Eye (v0.11 M6).
	["lantern_eye", "Clear a mirror's guards (red), shatter it (gold), keep it shattered 20 s. Never cast in the light."],
	["lantern_eye.guarded", "Its guards (red) hold the mirror: blows only shake the tower. Remove every one."],
	["lantern_eye.open", "The mirror (gold) stands unguarded. Two blows or one Blight shatter it: strike where no beam shines."],
	["lantern_eye.shattered", "Its wrights (red) hang a new glass. Stop them for {n} s and it is gone for good."],
	["lantern_eye.waiting", "The next mirror goes up soon; till then the beams sweep but do not hunt. Clear its guards (red) shortly before."],
	["lantern_eye.eye", "All three mirrors stand: the Eye opens in {n} s. Shatter one now."],
	# Exodus (v0.11 M6).
	["exodus", "Whisper each lamp (blue) to an open gate: the rest follow. Inquisitors (red) seize on sight. Ten must get out alive."],
	["exodus.caught", "A believer is taken to the Temple. Whisper, Discord or strike the man taking him (red)."],
	["exodus.hounds", "The Temple's searchers (red) follow the household. Strike them or turn them before they see it."],
	["exodus.gate", "Inquisitors (red) watch the gate. Whisper them off or strike them, then send the household through."],
	["exodus.shut", "That gate is shut. Lead the household to another open gate."],
	["exodus.waiting", "The next household comes out in {n} s. Clear its road and its gate of Inquisitors (red)."],
	# The Heart of Faith (v0.11 M6; shortened to the three-line plate, the controller's ruling: the Gaze's sentence once, in "coming").
	["heart_of_faith", "Kill the Knights (red), then burn the oil-house and the Temple (gold): the Great Flame goes out. Then kill High Priest Odran."],
	["heart_of_faith.not_yet", "Not in use yet (grey): fire there goes out, but a fall counts when its time comes. Kill its Knights (red) shortly before."],
	["heart_of_faith.guarded", "Lantern Knights (red) guard it: it takes no harm, its fire goes out. Kill them, or whisper, Discord or lure them off."],
	["heart_of_faith.open", "No Knight stands. Set it alight (gold) and keep it burning."],
	["heart_of_faith.burning", "It burns. Keep it burning: a new Knight comes from the Citadel."],
	["heart_of_faith.coming", "The flame is out: each seen death now adds 20 to the Gaze. Odran comes out in {n} s: kill his bearers (red) first."],
	["heart_of_faith.litter", "Odran rides in his litter, untouchable. Kill his bearers (red): with fewer than two, it falls."],
	["heart_of_faith.on_foot", "Odran walks to the Temple's steps (orange). Kill him before he rekindles the flame."],
	["heart_of_faith.rite", "Odran rekindles the flame. Kill him now, or whisper him off the steps to start it again."],
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
	# v0.11 M4: a line that counts down (the controller's ruling for The Heretic Hunt's captain), filled by the HUD.
	var coming := MissionHints.line("heretic_hunt", "coming")
	t.check(MissionHints.filled(coming, 29.2) == coming.replace(MissionHints.SECONDS, "30") and MissionHints.filled(coming, -1.0).contains(" in 0 s")
		and MissionHints.filled(spec["heretic_hunt"], 12.0) == spec["heretic_hunt"] and MissionDirector.new().hint_seconds() == 0.0,
		"the seconds rounded up, never below 0; a line without the mark as it was; a director counts nothing by default")
	t.check(Hud.hint_lines(MissionHints.filled(coming, 30.0)).size() <= Hud.HINT_LINES
		and UiTheme.wrap(MissionHints.filled(coming, 30.0), Hud.HINT_W, UiTheme.SIZE_SMALL).size() <= Hud.HINT_LINES,
		"filled at its longest (30 s), the captain's line still fits the plate")
