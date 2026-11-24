extends RefCounted
## Mission clarity Task 1: the verb vocabulary (spec §3). The table, the families it follows, the source scan that ties each verb
## to the fx scripts that call Person.whisper/confuse/lure/compel and DummyEnemy.fold, the kill list, the word finder and the
## legend's rows.


static func run(t) -> void:
	_table(t)
	_families(t)
	_sources(t)
	_kill(t)
	_named(t)
	_legend_rows(t)


static func _text(key: String) -> String:
	return FileAccess.get_file_as_string(String(PowerBook.get_power(key).path))


static func _keys_with(call: String) -> PackedStringArray:
	var out := PackedStringArray()
	for k in PowerBook.keys():
		if _text(k).contains(call):
			out.append(k)
	return out


static func _table(t) -> void:
	t.check(MissionVerbs.verbs() == PackedStringArray(["kill", "scare", "lead", "lure", "confuse", "hold", "burn", "strike", "rot", "seal", "banish", "calm"]),
		"twelve verbs in the spec's order (%s)" % [MissionVerbs.verbs()])
	var book := PowerBook.keys()
	var bad := []
	for r: Dictionary in MissionVerbs.VERBS:
		for k in r.keys:
			if not book.has(k):
				bad.append(k)
	t.check(bad.is_empty(), "every key of every row is a real power (%s)" % [bad])
	t.check(MissionVerbs.word("burn") == "Burn" and MissionVerbs.does("seal") == "NO LEAVING on a door" and MissionVerbs.word("zzz") == "",
		"word() and does() read the table")


static func _families(t) -> void:
	var fire := PackedStringArray()
	var strike := PackedStringArray()
	for k in PowerBook.keys():
		if PowerBook.family(k) == "fire":
			fire.append(k)
		elif PowerBook.family(k) == "strike":
			strike.append(k)
	t.check(MissionVerbs.powers("burn") == fire, "Burn is the fire family (%s)" % [MissionVerbs.powers("burn")])
	t.check(MissionVerbs.powers("strike") == strike, "Strike is the strike family (%s)" % [MissionVerbs.powers("strike")])
	var loud := PackedStringArray()
	for k in PowerBook.keys():
		if not PowerBook.is_quiet(k):
			loud.append(k)
	t.check(MissionVerbs.powers("scare") == loud and not loud.is_empty(), "Scare is every power that is not quiet (%d)" % loud.size())
	t.check(not MissionVerbs.powers("scare").has("whisper") and MissionVerbs.verbs_of("smite").has("scare")
		and MissionVerbs.verbs_of("smite").has("kill") and MissionVerbs.verbs_of("smite").has("strike"), "Smite is Kill, Scare and Strike")
	t.check(MissionVerbs.verbs_of("belllies").has("calm") and MissionVerbs.verbs_of("belllies").has("hold")
		and MissionVerbs.verbs_of("noleave").has("seal") and MissionVerbs.verbs_of("blight").has("rot"), "verbs_of reads the rows")


static func _sources(t) -> void:
	var whisper := _keys_with(".whisper(")
	var confuse := _keys_with(".confuse(")
	var lure := _keys_with(".lure(")
	var compel := _keys_with(".compel(")
	var fold := _keys_with(".fold(")
	var hold := {}
	for list in [whisper, confuse, compel, lure]:
		for k in list:
			hold[k] = true
	var want_hold := PackedStringArray()
	for k in PowerBook.keys():  # book order
		if hold.has(k):
			want_hold.append(k)
	t.check(MissionVerbs.powers("lead") == whisper, "Lead is what calls .whisper( (%s)" % [whisper])
	t.check(MissionVerbs.powers("confuse") == confuse, "Confuse is what calls .confuse( (%s)" % [confuse])
	t.check(MissionVerbs.powers("lure") == lure, "Lure is what calls .lure( (%s)" % [lure])
	t.check(MissionVerbs.powers("hold") == want_hold, "Hold is the union of whisper, confuse, compel and lure (%s vs %s)" % [MissionVerbs.powers("hold"), want_hold])
	t.check(MissionVerbs.powers("banish") == fold, "Banish is what calls .fold( (%s)" % [fold])


## Kill: the strike, fire and death families but guise (and ember, whose spark lights a building and kills nobody itself), plus doom,
## hellspark, houndgate, breath and cage; each file kills or says someone dies.
static func _kill(t) -> void:
	var kill := MissionVerbs.powers("kill")
	var missing := []
	for k in kill:
		var text := _text(k).to_lower()
		if not (text.contains("kill") or text.contains("die") or text.contains("dead")):
			missing.append(k)
	t.check(missing.is_empty(), "every Kill power's effect speaks of a death (%s)" % [missing])
	t.check(not kill.has("guise") and not kill.has("ember"), "guise and ember are not killers")
	var want := PackedStringArray()
	for k in PowerBook.keys():
		var f := PowerBook.family(k)
		if (f in ["strike", "fire", "death"] and k != "guise" and k != "ember") or k in ["doom", "hellspark", "houndgate", "breath", "cage"]:
			want.append(k)
	t.check(kill == want, "Kill follows the spec's families (%s vs %s)" % [kill, want])


static func _named(t) -> void:
	t.check(MissionVerbs.named_in("Kill or lead its guards (red)") == PackedStringArray(["kill", "lead"]), "named_in finds Kill and Lead")
	t.check(MissionVerbs.named_in("Keep it burning").is_empty(), "burning is not Burn")
	t.check(MissionVerbs.named_in("Burn the refuge (gold) now") == PackedStringArray(["burn"]), "Burn the refuge")
	t.check(MissionVerbs.named_in("HOLD, SEAL").size() == 2 and MissionVerbs.named_in("").is_empty(), "any case; empty is empty")
	# A mention that forbids the verb is not a claim that it works (pre-flight I10).
	t.check(MissionVerbs.named_in("Do not kill a contact").is_empty() and MissionVerbs.named_in("Never burn it").is_empty(), "'do not kill', 'never burn' name nothing")
	t.check(MissionVerbs.named_in("Kill none, hold them") == PackedStringArray(["hold"]) and MissionVerbs.named_in("Kill no one").is_empty(), "'kill none' and 'kill no one' name nothing")
	t.check(MissionVerbs.named_in("Hold or scare, do not kill") == PackedStringArray(["scare", "hold"]), "a negation stays inside its clause (%s)" % [MissionVerbs.named_in("Hold or scare, do not kill")])
	t.check(MissionVerbs.named_in("Do not kill them, lead him") == PackedStringArray(["lead"]) and MissionVerbs.named_in("Kill, do not hold") == PackedStringArray(["kill"]), "the clause ends at a comma")


static func _legend_rows(t) -> void:
	var rows := MissionVerbs.legend_rows(PackedStringArray(["whisper", "smite"]))
	t.check(rows.size() == 12, "twelve legend rows")
	var lead: Array = rows[2]
	t.check(lead[0] == "Lead" and lead[2] == ["Mind Whisper"] and (lead[3] as Array).is_empty(), "Lead: Mind Whisper is equipped (%s)" % [lead])
	var scare: Array = rows[1]
	t.check((scare[2] as Array).has("Smite") and not (scare[3] as Array).has("Smite") and not (scare[2] as Array).has("Mind Whisper"),
		"Scare: Smite equipped, the rest not (%s)" % [scare[2]])
	var none := MissionVerbs.legend_rows(PackedStringArray())
	t.check((none[0][2] as Array).is_empty() and not (none[0][3] as Array).is_empty(), "no loadout: every name is in the others")
