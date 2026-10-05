extends RefCounted
## v0.10 the Lantern campaign as data and state: four nights and their missions, Divine Power that grows with each won
## night and is bitten by each lost one, the path tally and its ties, Night 1's bell carried to Night 3, and every way a
## campaign ends.


static func run(t) -> void:
	_def(t)
	_growth(t)
	_paths(t)
	_branches(t)


static func _won(bonus := false) -> Dictionary:
	return {"won": true, "reason": "held", "bonuses": [{"label": "Bonus", "earned": bonus}]}


static func _lost(reason := "timeout") -> Dictionary:
	return {"won": false, "reason": reason, "bonuses": []}


static func _def(t) -> void:
	t.check(CampaignDef.NIGHTS.size() == 4, "the prototype campaign has four nights")
	var slots := []
	var tiers := []
	for i in 4:
		var n := CampaignDef.night(i)
		slots.append(int(n.slots))
		tiers.append(int(n.tier))
		t.check(CampaignText.FRAGMENTS.has(String(n.fragment)), "night %d's fragment has its words (%s)" % [i + 1, n.fragment])
		for o: Dictionary in n.options:
			t.check(MissionBook.get_mission(String(o.mission)).id == String(o.mission),
				"night %d offers a real mission (%s)" % [i + 1, o.mission])
	t.check(slots == [3, 3, 4, 6] and tiers == [1, 2, 3, 5], "slots %s and Tiers %s are the spec's" % [slots, tiers])
	var paths := []
	for o: Dictionary in CampaignDef.night(1).options:
		paths.append(String(o.path))
	t.check(paths == ["faith", "theft", "ruin"], "Night 2 offers one mission per path (%s)" % [paths])
	t.check(CampaignDef.path_of(1, "vigil_flame") == "theft" and CampaignDef.path_of(0, "warning") == ""
		and CampaignDef.path_of(1, "warning") == "", "path_of() names a night's path, and nothing it does not offer")
	t.check(CampaignDef.ending_for("faith") == "new_faith" and CampaignDef.ending_for("theft") == "false_lantern"
		and CampaignDef.ending_for("ruin") == "kataclysm", "each path has its ending")
	for e in CampaignDef.ENDINGS:
		t.check(CampaignText.ENDINGS.has(e), "the %s ending has its words" % e)
	for p in CampaignDef.PATHS:
		t.check(CampaignText.TITLES.has(p) and CampaignText.PATH_NAMES.has(p), "the %s path has a title and a name" % p)
	for id in ["miras_house", "vigil_flame", "broken_lanterns"]:
		t.check(CampaignText.CARD_LINES.has(id), "Cael has a line for the %s card" % id)


static func _growth(t) -> void:
	var s := CampaignState.new()
	t.check(s.night == 0 and s.dp == 6 and s.bites == 0 and s.slots() == 3 and s.ending == "" and s.title() == "The Forgotten",
		"a fresh campaign: Night 1, 6 DP, 3 slots, no bites, the Forgotten")
	var c := s.record("warning", {"won": true, "reason": "omen", "bonuses": [{"label": "Unseen", "earned": false}]})
	t.check(s.dp == 8 and s.night == 1 and int(c.dp_gain) == 2 and not bool(c.bite) and not s.bell_rang and s.nights_won == 1,
		"a won night: +2 DP and on to Night 2 (dp %d)" % s.dp)
	var m := s.mission("broken_lanterns")
	t.check(m.slots == 3 and m.dp_capacity == 8, "a mission from the campaign has the night's slots and the god's DP")
	s = CampaignState.new()
	s.record("warning", {"won": true, "reason": "warning", "bonuses": [{"label": "Unseen", "earned": true}]})
	t.check(s.dp == 9, "a won night with its bonus: +3 (dp %d)" % s.dp)
	s = CampaignState.new()
	c = s.record("warning", _lost("bell"))
	t.check(s.dp == 5 and s.bites == 1 and s.night == 1 and s.bell_rang and bool(c.bite) and int(c.dp_gain) == 0,
		"a lost night is a bite: -1 DP, and the story goes on; the bell is remembered")
	var f := s.mission("feast_festival")
	t.check(f.first_act().night != null and f.first_act().night.bell_rang
		and f.response_profile(ResponseProfile.DEFAULT).tier == ResponseProfile.Tier.ORGANIZED,
		"Night 1's bell reaches the Feast's act and its Prepare")
	s = CampaignState.new()
	s.dp = 4
	s.record("warning", _lost())
	t.check(s.dp == 4, "a bite never takes the budget under 4 (dp %d)" % s.dp)
	s = CampaignState.new()
	s.record("warning", _lost())
	s.record("vigil_flame", _lost())
	c = s.record("feast_festival", _lost())
	t.check(s.bites == 3 and s.ending == "eaten" and String(c.ending) == "eaten", "the third bite: Halcyon has eaten the god")


static func _paths(t) -> void:
	var s := CampaignState.new()
	t.check(s.path() == "", "no path before a path night")
	s.tally = {"faith": 1, "theft": 1, "ruin": 0}
	s.last_path = "theft"
	t.check(s.path() == "theft", "a tie goes to the most recent path night (%s)" % s.path())
	s.last_path = "faith"
	t.check(s.path() == "faith", "whichever it was (%s)" % s.path())
	s.tally = {"faith": 0, "theft": 0, "ruin": 2}
	t.check(s.path() == "ruin" and s.title() == "The Kataclysm", "the strongest path gives the title (%s)" % s.title())
	s = CampaignState.new()
	s.record("warning", _won())
	s.record("miras_house", _lost())
	t.check(int(s.tally["faith"]) == 1 and s.last_path == "faith" and s.title() == "The Prophet's God",
		"a path night counts for its path won or lost")
	t.check(CampaignState.new().ending_fragment() == "", "no fragment before an ending")
	s.ending = "new_faith"
	t.check(s.ending_fragment() == "vision", "The Vision comes before the Faith ending")
	s.ending = "kataclysm"
	t.check(s.ending_fragment() == "", "but not before the Kataclysm (seen before Night 4)")


## Every way through the prototype campaign (spec §7's forced outcomes): Night 1 won or lost, each Night 2 path won or
## lost, Night 3 won or lost, and on the Ruin path the finale lost once, then won.
static func _branches(t) -> void:
	var bad := PackedStringArray()
	for n1 in [true, false]:
		for n2 in ["miras_house", "vigil_flame", "broken_lanterns"]:
			for n2won in [true, false]:
				for n3won in [true, false]:
					var label := "n1 %s, %s %s, n3 %s" % [n1, n2, n2won, n3won]
					var s := CampaignState.new()
					s.record("warning", _won() if n1 else _lost("bell"))
					s.record(n2, _won() if n2won else _lost())
					s.record("feast_procession", _won() if n3won else _lost())
					var bites := int(not n1) + int(not n2won) + int(not n3won)
					var want := ""
					if bites >= 3:
						want = "eaten"
					elif n2 == "miras_house":
						want = "new_faith"
					elif n2 == "vigil_flame":
						want = "false_lantern"
					if s.ending != want:
						bad.append("%s: ending '%s'" % [label, s.ending])
						continue
					if want != "":
						continue
					if s.night != CampaignDef.FINALE:
						bad.append("%s: not at the finale" % label)
						continue
					s.record("last_judgement", _lost())
					if s.bites >= 3:
						if s.ending != "eaten":
							bad.append("%s: the finale's third bite is not Eaten" % label)
						continue
					if s.night != CampaignDef.FINALE or s.ending != "":
						bad.append("%s: a lost finale is not played again" % label)
					s.record("last_judgement", _won())
					if s.ending != "kataclysm":
						bad.append("%s: a won finale is not the Kataclysm" % label)
	t.check(bad.is_empty(), "every branch ends where the spec says (%s)" % ", ".join(bad))
	var r := CampaignState.new()
	var dps := [r.dp]
	for id in ["warning", "broken_lanterns", "feast_festival"]:
		r.record(id, _won())
		dps.append(r.dp)
	t.check(dps == [6, 8, 10, 12] and r.night == CampaignDef.FINALE and r.slots() == 6,
		"a Ruin run that wins every night: %s DP, then the finale with 6 slots" % [dps])
