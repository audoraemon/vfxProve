extends RefCounted
## v0.10 M6 how to win (spec §3): the lines are the spec's, word for word; a phase's line, the fallbacks; a line for every
## mission and act the game plays; and each fits the HUD's plate (HINT_LINES lines of HINT_W).

## The spec's table: [key, line].
const SPEC := [
	# --- clarity block: intercept ---
	# The board missions' (board tags, spec §3).
	["warning", "Kill the messenger (gold) with no one near (red) before he warns the bellkeeper (blue)."],
	["warning.relay", "Someone saw: a witness (gold) carries the warning on. Kill again where no one (red) is near."],
	["warning.stars", "Kill the messenger (gold) unseen (red), banish him, or calm the town. Or kill a man just outside his gate as he stares."],
	["warning.running", "The messenger (gold) runs for the bellkeeper (blue). Kill him unseen (red), banish him, or calm the town."],
	["warning.bell", "The bell is called. Kill its ringer (gold) unseen, or the bell tolls and he runs for the Temple."],
	["warning.waiting", "That warning is dead. Watch the next star's gate (gold). A death just outside it as he stares draws its watchman out."],
	["omen", "Kill the messenger (gold) with no one near (red) before he warns the bellkeeper (blue)."],
	["omen.relay", "Someone saw: a witness (gold) carries the warning on. Kill again where no one (red) is near."],
	["omen.bell", "The bell is called. Kill its ringer (gold) unseen, or the bell tolls and he runs for the Temple."],
	# The Bell-Ringers (v0.11 M3).
	["bell_ringers", "Kill each ringer (gold) where no one (red) sees, before he climbs the bell tower. His mates run with him."],
	["bell_ringers.mates", "His mates (red) see him die and run on. Lead or lure them off, or kill them first."],
	["bell_ringers.relay", "Someone saw: a witness (gold) carries the warning on. Kill again where no one (red) is near."],
	["bell_ringers.climbing", "He climbs the bell (gold). Lead or scare him off the rope, or kill him unseen (red), before the bar fills."],
	["bell_ringers.bell", "The town calls its bellkeeper (blue). Kill or hold him, or the bell tolls and the Lantern turns."],
	["bell_ringers.waiting", "That warning is dead. The next post (gold) sends its ringer soon. A loud power near a post sends him at once."],
	# Silence the witness (god P5, plan Task 5; MS §3): inserted here, clear of the other Hunts' rows at the end.
	["silence_witness", "A witness (gold) walks to the Temple with two mates (red). Kill him unseen by them, or hold them first."],
	["silence_witness.relay", "His mate saw it and runs on with the word (gold). Kill him too."],
	["silence_witness.near", "The witness (gold) nears the Temple. Kill or banish him now."],
	["festival", "Kill or scare enough of the crowd (gold) before the guard closes the square in {n} s."],
	["festival.packed", "The bonfire packs the crowd (gold) round the fountain: scare them there and one cast breaks many."],
	["festival.address", "The Mayor (orange) speaks from the fountain. Kill him and the crowd round it panics."],
	# Market Panic (v0.11 M3).
	["market_panic", "Wardens (red) stand fast and steady the crowd (gold). Kill, lead or confuse them, then scare the crowd. 36 must break."],
	["market_panic.steadied", "A warden (red) still steadies the crowd near him. Kill, lead or confuse him; no fright breaks them there."],
	["market_panic.open", "No warden stands. Scare the crowd (gold) now, before a new warden comes."],
	["market_panic.coming", "More come to the fair (gold). Scare them on the way, away from the wardens (red), or when they arrive."],
	["procession", "Kill the Prince (gold) before he boards. If no one near (red) sees it, the town is left leaderless."],
	["procession.blessing", "The Prince (gold) holds at the cathedral steps for {n} s. Kill him while he stands still."],
	["procession.dock", "The Prince (gold) boards in {n} s, as soon as his ship is in. Kill him first."],

	# --- clarity block: assassinate ---
	["informer", "Confuse the contact (orange) and his company (red) together, or lead him with none of them near. Do not kill a contact."],
	["informer.waiting", "Word reaches the contact (grey) in {n} s. Nothing turns him before then. A companion you scare off walks back."],
	["informer.found", "He is found and runs for the Temple (red). Kill him before he gets in. Unseen, no cry is raised."],
	["informer.hiding", "Alarmed, he hides (gold). Burn the house: the fire drives him out. Or wait for him."],
	["informer.running", "No hiding place: he runs for the Temple (red). Kill him before he gets in."],
	["tax_collector", "Kill each collector (gold) on his round, unseen (red) if you can: a seen kill rings the bell. Or banish him."],
	["tax_collector.ready", "The first collector (gold) leaves the counting-house (orange) in {n} s. Be ready to kill him on his round."],
	["tax_collector.inside", "He is in a debtor's house (gold) for {n} s. Be at the door and seal it as he comes out, his guards away."],
	["tax_collector.hiding", "Alarmed, he hides in the counting-house (orange). Burn it: everyone inside runs for the Citadel."],
	["tax_collector.running", "No hiding place: he runs for the Citadel (red). Kill him before he gets in."],
	["tax_collector.safe", "His rounds are done. He takes the taxes to the Citadel (red): kill him before he gets in."],
	["tax_collector.next", "One down. The next collector (gold) leaves the counting-house (orange) in {n} s."],
	["bishop", "Burn each refuge the bishop hides in (gold), once its Knights (red) are dead. The Temple last: then kill him in the square."],
	["bishop.waiting", "He reaches his next refuge in {n} s. Kill or hold its Knights (red) shortly before he comes."],
	["bishop.guarded", "His Knights (red) beat out fire and turn blows aside. Kill or hold them: a held Knight walks back after."],
	["bishop.open", "No Knight stands. Set the refuge (gold) alight before a new Knight comes."],
	["bishop.burning", "It burns. Keep it burning: his Knights (red) put out a fire they stand by."],
	["bishop.square", "He is in the square and makes for the Citadel (red). Kill him before he gets in."],
	["bishop.running", "Alarmed, he runs for the Citadel (red). Kill him now."],
	# expel_inquisitor (god P5 Task 6; MS §4, *my call*)
	["expel_inquisitor", "Kill or banish each lantern-warden (gold). A fright only sends a warden to hide."],
	["expel_inquisitor.captain", "The captain (gold) walks his rounds. Kill him, or scare him three times, each 8 s or more apart, while he walks."],
	["expel_inquisitor.near", "The captain (gold) nears the Citadel (red). Kill or banish him now."],

	# --- clarity block: escort ---
	# The Lost Lamb (v0.11 M2).
	["lost_lamb", "Lead or lure the acolyte (blue) to the west gate, or scare him: he bolts for it. At {n} s he bolts alone."],
	["lost_lamb.running", "He runs for the west gate. Hold or kill the patrols and the watch (red) ahead of him."],
	["lost_lamb.led", "He holds where you left him. Lead or lure him on toward the west gate; soldiers (red) seize him on sight."],
	["lost_lamb.caught", "He is caught. Hold or kill the soldier taking him (red) before the Temple."],
	["lost_lamb.gate", "The watch (red) holds the gate. It changes in {n} s: bring him close, or hold the watch."],
	["lost_lamb.clear", "The watch is changing. Lead him through the gate now."],
	# The Prisoner (v0.11 M4).
	["prisoner", "Lead or lure her (blue) toward the postern, and again before she stops. Watchmen (red) seize her on sight."],
	["prisoner.bound", "Kill, lead or confuse both gaolers (red): one left seizes her for the Citadel. Then burn the stocks (orange) or strike them."],
	["prisoner.caught", "She is caught. Lead, scare or kill the man taking her back (red) before the Citadel."],
	["prisoner.hounds", "The Citadel's hounds (red) follow her. Lead, scare or kill them before they see her."],
	["prisoner.gate", "The watch (red) holds the postern. It changes in {n} s: bring her close, or lead the watch off."],
	["prisoner.clear", "The guard is changing. Lead her through the postern now."],
	# Exodus (v0.11 M6).
	["exodus", "Lead each lamp (blue) to an open gate: the rest follow. Scare or kill Inquisitors (red) in the way. Ten must get out."],
	["exodus.caught", "A believer is taken to the Temple. Lead, scare or kill the man taking him (red)."],
	["exodus.hounds", "The Temple's searchers (red) follow the household. Lead, scare or kill them before they see it."],
	["exodus.gate", "Inquisitors (red) watch the gate. Scare or kill them, then lead the household through."],
	["exodus.shut", "That gate is shut. Lead the household to another open gate."],
	["exodus.waiting", "The next household comes out in {n} s. Scare or kill the Inquisitors (red) on its road and at its gate."],
	# hide_faithful (god P5 Task 4).
	["hide_faithful", "Your believers (blue) walk out by themselves. Hold or kill the watch (red) on their road to the gate."],
	["hide_faithful.trail", "The Inquisition found the trail. Scare or kill its searchers (red) before they see the household."],
	["hide_faithful.seized", "A believer is seized. Hold or kill his seizer (red) before he reaches the Temple."],
	# face_halcyon (god P5 Task 8, MS §6): appended after the expel_inquisitor rows.
	["face_halcyon", "Hold two of a believer's three escorts (red) and he runs free. A death anyone sees feeds the Gaze."],
	["face_halcyon.pyre", "A believer burns at the pyre in {n} s. Hold two of his three escorts (red) now."],
	["face_halcyon.gaze", "Halcyon's Gaze is filling. Hold the escorts (red); every death anyone sees fills it more."],

	# --- clarity block: raze ---
	# Spoiled Harvest (v0.11 M2).
	["spoiled_harvest", "Scare, lead, confuse or kill a granary's watchmen (red), then burn or rot it (gold). Or banish its carter (blue)."],
	["spoiled_harvest.empty", "No grain yet: fire there is put out. The grain comes in {n} s: scare, lead or kill its watchmen (red) just before."],
	["spoiled_harvest.watchman", "A watchman (red) holds his post and beats the fire out in 3 s. Lead, confuse or kill every one first."],
	["spoiled_harvest.burning", "It burns, with no one to put it out. Keep it burning 10 s, or bring it down, before a new watchman comes."],
	# The Crown's Bread (v0.11 M4).
	["crowns_bread", "Kill or lead its engineers (red), then burn or strike it down while it is in use: granary, mill, bridge (strike only)."],
	["crowns_bread.not_yet", "Not in use yet (grey). Kill, lead, confuse or scare its engineers (red) just before; a fall counts if it stays down."],
	["crowns_bread.engineers", "Engineers (red) mend it and put out its fires. Kill, lead, confuse or scare every one first."],
	["crowns_bread.open", "No engineer stands. Burn or strike it (gold) down now. The bridge takes blows, not fire."],
	# The Armoury (v0.11 M5).
	["armoury", "Kill a target's armed men (red), then destroy it once it musters: two barracks, then the armoury."],
	["armoury.not_yet", "Not mustering yet (grey): it takes no harm. Kill or hold its night watch (red) just before its horn, in {n} s."],
	["armoury.guarded", "Armed men (red) guard it: it takes no harm. Kill or hold them: a held man walks back after."],
	["armoury.open", "No guard stands. Destroy it now: more armed men march from the Citadel, faster each minute."],
	["armoury.stone", "The gate barracks (gold) is stone: strike it, fire does nothing."],
	# The Heart of Faith (v0.11 M6; shortened to the three-line plate, the controller's ruling: the Gaze's sentence once, in "coming").
	["heart_of_faith", "Kill the Knights (red), then burn the oil-house and the Temple: the Great Flame goes out. Then kill High Priest Odran."],
	["heart_of_faith.not_yet", "Not in use yet (grey): fire there goes out, but a fall counts when its time comes. Kill its Knights (red) shortly before."],
	["heart_of_faith.guarded", "Lantern Knights (red) guard it: it takes no harm. Kill or hold them."],
	["heart_of_faith.open", "No Knight stands. Set it alight (gold) and keep it burning."],
	["heart_of_faith.burning", "It burns. Keep it burning: a new Knight comes from the Citadel."],
	["heart_of_faith.coming", "The flame is out: each seen death now adds 20 to the Gaze. Odran comes out in {n} s: kill his bearers (red) first."],
	["heart_of_faith.litter", "Odran rides in his litter, untouchable. Kill his bearers (red): with fewer than two, it falls."],
	["heart_of_faith.on_foot", "Odran walks to the Temple's steps (orange). Kill him before he rekindles the flame."],
	["heart_of_faith.rite", "Odran (gold) rekindles the flame in {n} s. Kill him, or scare, lead or confuse him to start it again."],
	["judgement", "Bring the Citadel (gold) down before dawn, before too many of its people escape by the gates (red)."],
	["judgement.rite", "The clergy (red) chant the Banishing Rite. Kill or scare them off the steps, or strike the cathedral, or it cuts your time."],
	["judgement.fallen", "The Citadel is down. Break the city's stability before dawn, and keep its people in."],
	["last_judgement", "Destroy the Citadel (gold) and break the city in time. Fifty escaping by the gates (red) loses it."],
	["last_judgement.rite", "The clergy (red) chant the Banishing Rite. Kill or scare them off the steps, or strike the cathedral, or it cuts your time."],
	["last_judgement.fallen", "The Citadel is down. Break the city's stability before time runs out. Fifty escaping loses it."],

	# --- clarity block: hunt ---
	# The Heretic Hunt (v0.11 M4).
	["heretic_hunt", "Kill or lead a standard's guards (red), then strike or rot the standard (gold). Three standards, then the captain."],
	["heretic_hunt.guarded", "Its guards (red) stand over the standard: blows only shake it. Kill, lead or confuse every one."],
	["heretic_hunt.open", "The standard (gold) stands unguarded. Strike or rot it now, before a new guard comes."],
	["heretic_hunt.waiting", "The hunt moves on soon. Kill, lead or confuse the next sweep's guards (red) shortly before it comes."],
	["heretic_hunt.coming", "The captain comes out of the Temple (grey) in {n} s. Be ready on his road to your cellar (blue)."],
	["heretic_hunt.captain", "The captain (gold) leads the last sweep to your cellar (blue). Kill him before he finds it."],
	["heretic_hunt.searching", "The captain searches the houses by your cellar. Kill him before he reaches its door."],
	["lantern_eye", "Kill or lead a mirror's guards (red), strike or rot the mirror (gold), keep it shattered 20 s. Never cast in the light."],
	["lantern_eye.guarded", "Its guards (red) stand over the mirror: blows only shake the tower. Kill, lead or confuse every one."],
	["lantern_eye.open", "The mirror (gold) stands unguarded. Strike it twice or rot it once, where no beam shines."],
	["lantern_eye.shattered", "Its wrights (red) hang a new glass. Kill, lead or confuse them for {n} s and it is gone for good."],
	["lantern_eye.waiting", "The next mirror goes up soon; till then the beams sweep but do not hunt. Kill or lead its guards (red) shortly before."],
	["lantern_eye.eye", "All three mirrors stand: the Eye opens in {n} s. Shatter one now."],
	# break_hunt (god P5 Task 7; MS §5, *my call*)
	["break_hunt", "Standards (gold) march on your houses (blue). Kill or scare a bearer when no escort (red) guards him: hold them first."],
	["break_hunt.carried", "An escort took up the standard (gold). Kill or scare him too, with no escort by him."],
	["break_hunt.taken", "A house is taken: one more and the hunt has won. Kill or scare a lone bearer (gold)."],

	# --- clarity block: convert ---
	["first_prayers", "Lead or lure the poor (gold) to the well (gold), or let them walk: the next sets out in {n} s. Three must pray unseen."],
	["first_prayers.watched", "Faithful (red) watch the well. Burn a house by it, calm the town, or lead, confuse or kill them."],
	["miras_house", "Lead or lure a grieving (gold) to Mira's house (gold) while no Faithful (red) sees. Four must believe by dawn."],
	["miras_house.four", "Four believe. The night is won: ascend, or keep the Gaze from filling until dawn."],
	["miras_house.burning", "Her house burns: no one can go in now. Keep your Believers (orange) alive until dawn."],
	["sermon", "Silence the preacher (red), then lead his crowd (gold) to the god's house (gold) unseen. Eight must believe: kill none."],
	["sermon.rapt", "He preaches: his crowd hears only him. Lead, confuse or scare him; kill him only unseen by his acolytes (red)."],
	["sermon.watched", "Sentries (red) watch the door: anyone seen going in is turned away. Lead, confuse or kill them first."],
	["sermon.report", "A Faithful (red) runs to the Temple. Kill him before he gets there, unseen."],
	["sermon.coming", "More come to hear him (gold). Lead them on the way, before they come within his voice. Do not kill them."],
	["sermon.seen", "A death was seen: the Gaze rises. Four seen deaths in a district call the bell: +40 Gaze, and the Lantern turns."],
	["sermon.bell", "The bellkeeper (red) runs to ring the bell: it raises the Gaze by 40 and turns the Lantern. Kill him, unseen."],
	["vigil_flame", "Wren comes for the flame (gold) in {n} s. Its acolytes would see him: lead or confuse them off first."],
	["vigil_flame.wren", "Lead Wren (blue) to the flame (gold) while no Faithful but its bearer is near him (red)."],
	["vigil_flame.homeward", "The Vigil turns for home: have the flame swapped before its bearer reaches the Temple."],
	["vigil_flame.carry", "Lead Wren to Mira's shrine (orange), west past the wall. Keep him out of the searchlight."],
	["relic_run", "Lead Pip (blue) to the cart's first halt (orange). He slips aboard there and swaps the relic at the next."],
	["relic_run.moving", "The cart (gold) moves. Its reliquary opens only at a checkpoint. Lead, confuse or kill the next one's wardens (red) first."],
	["relic_run.watched", "The watch (red) sees the cart. Lead, confuse or kill them: Pip works unseen. A lure draws them only once Pip follows you."],
	["relic_run.aboard", "Pip is aboard and picks the lock. At the next halt, lead, confuse or kill the watch (red) so he can swap the relic."],
	["relic_run.carry", "Pip has the relic. Keep him out of the light (a touch costs half the Gaze) on his way to your believers' house (orange)."],
	["relic_run.last_halt", "The cart rolls to its last halt before the Citadel. Lead Pip (blue) there: he can board and swap in that one halt."],
	["relic_run.citadel", "The cart makes for the Citadel (red) and halts no more: the relic is lost when it gets there."],
	["relic_run.report", "A Faithful (red) runs to the Temple. Kill him before he gets there, unseen."],
	["relic_run.seen", "A death was seen: the Gaze rises. Four seen deaths in a district call the bell: +40 Gaze, and the Lantern turns."],
	["relic_run.bell", "The bellkeeper (red) runs to ring the bell: it raises the Gaze by 40 and turns the Lantern. Kill him, unseen."],
	["broken_lanterns", "Strike a lantern (gold) down, then lead the flame-bearer (gold) away from it for 20 s while it drains. Drain all six."],
	["broken_lanterns.knights", "A Knight (blue) shields the lantern he stands by, held or not. Kill him, or lead him away, then strike."],
	["first_taste", "Press C, then click a lamplighter (gold): he walks to Mira's shrine (orange). Three win the rite."],
	["first_taste.drag", "Hold or kill the Watch (red) off him. Press C again to yank him on once."],
	["first_taste.march", "The clergy (red) march on the shrine: kill or scare all but one, or win first."],
	["first_taste.cleanse", "The clergy cleanse the shrine: kill or scare a kneeler (red) now."],

	# --- the rest (free play, the Lantern campaign) ---
]


static func run(t) -> void:
	_run(t)


static func _run(t) -> void:
	_lantern(t)
	_words(t)
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
		if UiTheme.wrap(String(MissionHints.LINES[key]), Hud.HINT_W, UiTheme.TEXT_S).size() > Hud.HINT_LINES:
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
		and UiTheme.wrap(MissionHints.filled(coming, 30.0), Hud.HINT_W, UiTheme.TEXT_S).size() <= Hud.HINT_LINES,
		"filled at its longest (30 s), the captain's line still fits the plate")


## v0.11.2 Task 12 (spec 5.3): the Lantern's lines, word for word, by their phase (final review: herald_silent and seeking added, the herald line names the wait).
const LANTERN_SPEC := {
	"stirring": "The bell tolled: the Lantern turns and dawn comes 1.5 times as fast. Its Bearer sets out soon: kill him to blind it.",
	"bearer": "The Bearer (gold) carries the flame to the bell tower. Kill him and dawn slows again. His escorts (red) take it up if they see.",
	"burning": "The Lantern burns: dawn comes twice as fast. A loud power or a seen death in its beam did it. Kill the Bearer (gold).",
	"herald": "The Herald (gold) runs for the Temple. Kill him before he gets in, unseen, or the warning passes on. No new Bearer starts.",
	"herald_silent": "The bell is silent: the warning (gold) runs for the Temple instead. Kill its carrier before he gets in, unseen.",
	"seeking": "The bell tolled: dawn comes 1.5 times as fast. The Lantern seeks a Bearer: nobody is free to carry its flame yet.",
}


static func _lantern(t) -> void:
	_lantern_lines(t)


static func _lantern_lines(t) -> void:
	t.check(MissionHints.LANTERN == LANTERN_SPEC, "the Lantern's lines are the spec's (and the seeking and silent-bell ones)")
	var odd := PackedStringArray()
	for phase: String in LANTERN_SPEC:
		if MissionHints.lantern_line(phase) != String(LANTERN_SPEC[phase]):
			odd.append(phase)
		if UiTheme.wrap(String(LANTERN_SPEC[phase]), Hud.HINT_W, UiTheme.TEXT_S).size() > Hud.HINT_LINES:
			odd.append(phase + " (too long)")
	t.check(odd.is_empty(), "lantern_line(phase) gives each line and each fits %d lines (%s)" % [Hud.HINT_LINES, ", ".join(odd)])
	t.check(MissionHints.lantern_line("") == "" and MissionHints.lantern_line("nowhere") == "", "no phase, or an unknown one, has no Lantern line")
	t.check(not MissionHints.LINES.has("stirring") and not MissionHints.LINES.has("lantern.stirring"), "the Lantern's lines stay out of the missions' table")


## v0.11.2 Task 12 (spec 5.4): the goal and lose words the Lantern made untrue.
static func _words(t) -> void:
	var w := MissionBook.warning()
	t.check(w.goal == "Stop the warning before it reaches the Temple" and w.lose == "The warning reaches the Temple, or dawn comes with it alive",
		"The Warning's goal and lose (%s / %s)" % [w.goal, w.lose])
	var star := TierBook.board("warning")
	t.check(star.goal == "Stop all three warnings before one reaches the Temple"
		and star.lose == "A warning reaches the Temple, or dawn comes with a warning alive", "Starfall's goal and lose (%s / %s)" % [star.goal, star.lose])
	var ringers := MissionBook.bell_ringers()
	t.check(ringers.goal == "Stop the ringers of all three watch posts" and ringers.lose == "A Herald reaches the Temple, or dawn comes",
		"The Bell-Ringers' goal and lose (%s / %s)" % [ringers.goal, ringers.lose])
	t.check(MissionBook.tax_collector().lose == "A collector reaches the Citadel, or dawn comes", "The Tax Collector's lose")
	t.check(MissionBook.informer().lose == "The names reach the Temple, a contact dies or leaves the town before he is turned, or dawn comes",
		"The Informer's lose")
	t.check(MissionBook.broken_lanterns().lose == "The Lantern looks, or dawn finds a shrine still lit", "Broken Lanterns' lose")
	t.check(MissionBook.long_night().acts[0].goal == w.goal and MissionBook.long_night().acts[0].lose == w.lose, "The Omen shares The Warning's words")
