extends RefCounted
## World Map + Conquer Progress Task 1: the conquer arithmetic (percent, population, unlock, conquered, bank, fill target).


static func run(t) -> void:
	_percent(t)
	_population(t)
	_unlock(t)
	_conquered(t)
	_bank_clean(t)
	_bank_caught(t)
	_bank_failed(t)
	_bank_abandoned(t)
	_bank_clamps(t)
	_fill_target(t)


static func _slot() -> GodSlot:
	return GodSlot.make(1, "ruin", 7)


static func _roll(town: String, alive: int, named := 0, fill := 0, lost := 0) -> Dictionary:
	return {"town": town, "carried_alive": alive, "named": named, "fill": fill, "lost": lost}


static func _percent(t) -> void:
	var rows := [[0, 220, 0], [1, 220, 0], [132, 220, 60], [219, 220, 99], [220, 220, 100], [500, 220, 100], [-3, 220, 0], [5, 0, 0]]
	for r: Array in rows:
		t.check(Conquest.percent(r[0], r[1]) == r[2], "percent(%d, %d) == %d (%d)" % [r[0], r[1], r[2], Conquest.percent(r[0], r[1])])


static func _population(t) -> void:
	t.check(Conquest.population("aldermere") == Crowd.CITIZENS and Crowd.CITIZENS == 220, "Aldermere holds 220")
	t.check(Conquest.population("capital") == CapitalCity.new().citizens(), "the Capital holds its citizens()")
	t.check(Conquest.population("nowhere") == 0, "an unknown town holds 0")
	t.check(Conquest.towns() == PackedStringArray(["aldermere", "capital"]), "towns() are the two real ones (%s)" % [Conquest.towns()])


static func _unlock(t) -> void:
	var s := _slot()
	t.check(Conquest.is_open(s, "aldermere") and not Conquest.is_open(s, "capital"), "only Aldermere starts open")
	t.check(Conquest.opener_of("capital") == "aldermere" and Conquest.opener_of("aldermere") == "", "opener_of")
	s.believers["aldermere"] = 131
	t.check(not Conquest.is_open(s, "capital"), "131 does not open the Capital")
	var r := Conquest.bank(s, _roll("aldermere", 132), false)
	t.check(s.opened.has("capital") and r.opened == PackedStringArray(["capital"]), "132 (60%%) opens the Capital (%s)" % [r.get("opened")])
	var r2 := Conquest.bank(s, _roll("aldermere", 10), false)
	t.check(s.opened.has("capital") and r2.opened.is_empty() and Conquest.is_open(s, "capital"), "a fall to 10 never closes it")


static func _conquered(t) -> void:
	var s := _slot()
	s.believers["aldermere"] = 220
	t.check(Conquest.conquered(s, "aldermere") and Conquest.bonus(s) == 5, "220 conquers Aldermere, bonus 5")
	s.believers["capital"] = Conquest.population("capital")
	t.check(Conquest.bonus(s) == 10 and Conquest.conquered_towns(s).size() == 2, "both full: bonus 10")
	s.believers["aldermere"] = 219
	t.check(not Conquest.conquered(s, "aldermere"), "219 is not conquered")


static func _bank_clean(t) -> void:
	var s := _slot()
	s.believers["aldermere"] = 10
	var r := Conquest.bank(s, _roll("aldermere", 10, 2, 6), true)
	t.check(r.count == 18 and r.converts == 8 and r.before == 10 and s.believers["aldermere"] == 18, "clean: 10+2+6 = 18, 8 converts (%s)" % [r])


static func _bank_caught(t) -> void:
	var s := _slot()
	var r := Conquest.bank(s, _roll("aldermere", 10, 1, 3), true)
	t.check(r.count == 14, "caught: 10+1+3 = 14 (%d)" % r.count)


static func _bank_failed(t) -> void:
	var s := _slot()
	var r := Conquest.bank(s, _roll("aldermere", 7, 2, 6, 3), false)
	t.check(r.count == 7 and r.converts == 0 and r.lost == 3, "failed: only the carried who lived count (%s)" % [r])


static func _bank_abandoned(t) -> void:
	var s := _slot()
	var r := Conquest.bank(s, _roll("aldermere", 10 - 4, 0, 0, 4), false)
	t.check(r.count == 6 and r.converts == 0, "abandoned: 10 carried, 4 died -> 6 (%s)" % [r])


static func _bank_clamps(t) -> void:
	var s := _slot()
	var r := Conquest.bank(s, _roll("aldermere", 219, 0, 6), true)
	t.check(r.count == 220 and r.conquered and r.converts == 1, "219 + 6 clamps to 220 (%s)" % [r])
	var s2 := _slot()
	var bad := Conquest.bank(s2, _roll("nowhere", 5, 1, 1), true)
	t.check(bad.is_empty() and s2.believers.is_empty() and s2.opened == PackedStringArray(["aldermere"]), "an unknown town banks nothing")


static func _fill_target(t) -> void:
	t.check(Conquest.fill_target(false, false) == 0 and Conquest.fill_target(true, false) == 3 and Conquest.fill_target(true, true) == 6, "fill_target 0 / 3 / 6")
