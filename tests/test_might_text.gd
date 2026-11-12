extends RefCounted
## The draft budget is called Might on every screen (god P1, spec §6, ruling C1): Prepare's header, refusal, panel, hint and
## cards, the campaign's status line and results line, and the Upgrades. "Divine Power" is the god's experience from Task 9
## on, so no budget screen may use the name; identifiers keep their old names (a ruling C1 cost saving for merges).

const UI_DIR := "res://src/game/ui"
## The screens whose budget text this task renamed: none may say "Divine Power" at all.
const NO_DIVINE_POWER := ["prepare_screen.gd", "campaign_screen.gd", "upgrades_screen.gd"]


static func run(t) -> void:
	_prepare(t)
	_campaign(t)
	_upgrades_scan(t)
	_scan(t)


static func _prepare(t) -> void:
	var prep := PrepareScreen.new().setup(TierBook.board("warning"), PackedStringArray(), ResponseProfile.DEFAULT,
		DescendState.new().locked())
	var text := prep.budget_text()
	t.check(text == "0 / 3 slots   0 / 6 Might", "Prepare's budget meter says Might ('%s')" % text)
	prep.free()
	t.check(String(PrepareScreen.REFUSALS["dp"]) == "Not enough Might",
		"and the refusal for an over-budget card says Might ('%s')" % PrepareScreen.REFUSALS["dp"])


static func _campaign(t) -> void:
	var status := CampaignScreen.status_text(CampaignState.new())
	t.check(status == "6 Might   3 slots   Bites 0 / 3   The Forgotten", "the campaign's status line says Might ('%s')" % status)
	var grows := ResultsScreen.campaign_line({"won": true, "dp_gain": 2, "dp": 8})
	t.check(grows == "The god grows: +2 Might, 8 Might now.", "a won night's line says Might ('%s')" % grows)
	var bites := ResultsScreen.campaign_line({"won": false, "dp": 5, "bites": 1})
	t.check(bites == "Halcyon bites: 5 Might now. Bites 1 / 3.", "a lost night's line says Might ('%s')" % bites)


## The Upgrades screen draws its strings from literals only; the scan below covers them, this pins the two the brief names.
static func _upgrades_scan(t) -> void:
	var src := _source("%s/upgrades_screen.gd" % UI_DIR)
	t.check(src.contains("\"+1 MIGHT\"") and src.contains("their tier's budget +%d Might, +%d slot"),
		"the Upgrades screen's button title and budget line say Might")


## Comments stripped, no string literal in src/game/ui/*.gd says DP, and the three budget screens never say Divine Power.
static func _scan(t) -> void:
	var found: Array[String] = []
	var dp := RegEx.create_from_string("\\bDP\\b")
	var bs := "\\\\"  # two characters, which the regex reads as one literal backslash
	var literal := RegEx.create_from_string("\"(?:[^\"" + bs + "]|" + bs + ".)*\"")
	var files := DirAccess.get_files_at(UI_DIR)
	t.check(files.size() > 10, "the scan sees the UI scripts (%d files)" % files.size())
	for f in files:
		if not f.ends_with(".gd"):
			continue
		var lines := _source("%s/%s" % [UI_DIR, f]).split("\n")
		for i in lines.size():
			var code := _strip_comment(lines[i])
			for m in literal.search_all(code):
				var s := m.get_string()
				if dp.search(s) != null:
					found.append("%s:%d DP in %s" % [f, i + 1, s])
				if f in NO_DIVINE_POWER and s.to_lower().contains("divine power"):
					found.append("%s:%d Divine Power in %s" % [f, i + 1, s])
	t.check(found.is_empty(), "no budget string says DP or (on the budget screens) Divine Power (%s)" % ["; ".join(found)])


static func _source(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	return f.get_as_text() if f != null else ""


## A line without its trailing comment: the first `#` outside a double-quoted string starts it.
static func _strip_comment(line: String) -> String:
	var in_str := false
	var i := 0
	while i < line.length():
		var c := line[i]
		if in_str:
			if c == "\\":
				i += 1
			elif c == "\"":
				in_str = false
		elif c == "\"":
			in_str = true
		elif c == "#":
			return line.substr(0, i)
		i += 1
	return line
