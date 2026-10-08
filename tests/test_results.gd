extends RefCounted
## The Results screen's words: the right ending for each way a mission ends, and scores written the way the
## spec writes them.


static func run(t) -> void:
	t.check(ResultsScreen.title_for(true, "citadel") == "THE CITY HAS FALLEN", "a win reads THE CITY HAS FALLEN")
	t.check(ResultsScreen.title_for(false, "escapes") == "THE PEOPLE ESCAPED", "the escape reads THE PEOPLE ESCAPED")
	t.check(ResultsScreen.title_for(false, "timeout") == "MANIFESTATION ENDED", "the clock reads MANIFESTATION ENDED")
	# The Warning (v0.08): both of its wins read THE WARNING DIES, its loss THE BELL TOLLS.
	t.check(ResultsScreen.title_for(true, "warning") == "THE WARNING DIES"
		and ResultsScreen.title_for(true, "omen") == "THE WARNING DIES",
		"The Warning's wins read THE WARNING DIES (%s, %s)" % [ResultsScreen.title_for(true, "warning"),
		ResultsScreen.title_for(true, "omen")])
	t.check(ResultsScreen.title_for(false, "bell") == "THE BELL TOLLS", "and its loss THE BELL TOLLS")
	t.check(ResultsScreen.title_for(false, "dawn") == "DAWN COMES", "dawn with the warning alive reads DAWN COMES (v0.11 M1)")
	t.check(ResultsScreen.solved_text({"won": true, "solved_by": PackedStringArray(["VEIL", "DISORDER"])}) == "VEIL, DISORDER"
		and ResultsScreen.solved_text({"won": true, "solved_by": PackedStringArray()}) == ResultsScreen.NOBODY
		and ResultsScreen.solved_text({"won": false, "solved_by": PackedStringArray(["VEIL"])}) == ResultsScreen.NOBODY,
		"Solved by lists the Authorities of a win, and nobody for a loss or none")

	# The night (v0.09): its path is named for the table; the other endings read as before.
	t.check(ResultsScreen.path_name("festival") == "The Festival" and ResultsScreen.path_name("procession") == "The Procession"
		and ResultsScreen.path_name("") == "", "a night's path is named (%s)" % ResultsScreen.path_name("festival"))
	t.check(ResultsScreen.title_for(true, "citadel") == "THE CITY HAS FALLEN", "the night's win reads as Last Judgement's")
	# Act II's endings have their own words on the act-end banner (v0.09 final review): a won Festival or Procession no
	# longer reads THE CITY HAS FALLEN, nor a lost one MANIFESTATION ENDED.
	for k: Array in [[true, "festival", "THE FEAST IS BROKEN"], [false, "closed", "THE SQUARE IS CLOSED"],
			[true, "prince", "THE PRINCE IS DEAD"], [false, "sailed", "THE PRINCE HAS SAILED"],
			[false, "tide", "THE TIDE HAS TURNED"]]:
		var title := ResultsScreen.title_for(bool(k[0]), String(k[1]))
		t.check(title == String(k[2]), "Act II's %s reads %s (%s)" % [k[1], k[2], title])

	t.check(ResultsScreen.thousands(12450) == "12,450", "scores get a thousands comma (%s)" % ResultsScreen.thousands(12450))
	t.check(ResultsScreen.thousands(999) == "999" and ResultsScreen.thousands(0) == "0", "small ones do not")
	t.check(ResultsScreen.thousands(1234567) == "1,234,567", "and big ones get every comma (%s)" % ResultsScreen.thousands(1234567))
	t.check(ResultsScreen.thousands(-3000) == "-3,000", "a negative keeps its sign in front (%s)" % ResultsScreen.thousands(-3000))

	# Every interface sound is in the catalog and on disk (synthesized by tools/audio/synth.py, or made with GodotSfxr
	# and baked by tools/audio/sfxr_bake.gd).
	var missing := ""
	for cue: StringName in UiSound.CUES:
		if not Sfx.CATALOG.has(cue):
			missing += " %s(catalog)" % cue
		elif not ResourceLoader.exists(String(Sfx.CATALOG[cue].path)):
			missing += " %s(file)" % cue
	t.check(missing == "", "every interface sound exists (missing:%s)" % missing)
	t.check(UiSound.CUES.size() == 14, "fourteen of them (%d)" % UiSound.CUES.size())
	# Every GodotSfxr source has been baked into its interface cue.
	var unbaked := ""
	for file in DirAccess.get_files_at("res://tools/audio/sfxr/"):
		if file.get_extension() != "tres":
			continue
		var cue := StringName(file.get_basename())
		if not UiSound.CUES.has(cue) or not ResourceLoader.exists("res://assets/audio/ui/%s.wav" % cue):
			unbaked += " " + String(cue)
	t.check(unbaked == "", "every GodotSfxr source is a baked interface cue (not:%s)" % unbaked)
