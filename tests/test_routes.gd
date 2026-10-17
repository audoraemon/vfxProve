extends RefCounted
## v0.11.1 second routes (spec §7): every power has a family, and every board mission has a loadout B that holds its own main-step
## power (another family from loadout A's), fits the mission's board slots and DP, draws from its board pool and differs from A.


static func _dp(keys: PackedStringArray) -> int:
	var n := 0
	for k in keys:
		n += int(PowerBook.get_power(k).get("dp", 0))
	return n


static func _in_pool(keys: PackedStringArray, pool: PackedStringArray) -> bool:
	for k in keys:
		if not pool.has(k):
			return false
	return true


static func run(t) -> void:
	for key in PowerBook.keys():
		t.check(PowerBook.family(key) != "", "%s has a family" % key)
	t.check(PowerBook.FAMILY.size() == PowerBook.keys().size(), "and the family table holds no key the book lacks (%d)" % PowerBook.FAMILY.size())
	t.check(PowerBook.family("nope") == "", "an unknown key has none")

	var ids := TierBook.all()
	t.check(ids.size() == 25 and RouteBook.ROUTES.size() == 25, "all 25 board missions have a row (%d)" % RouteBook.ROUTES.size())
	for id in ids:
		var r: Dictionary = RouteBook.ROUTES.get(id, {})
		t.check(not r.is_empty(), "%s has a second route" % id)
		if r.is_empty():
			continue
		var m := TierBook.board(id)
		var b := RouteBook.loadout_b(id)
		t.check(PowerBook.family(r.a) != "" and PowerBook.family(r.a) != PowerBook.family(r.b), "%s: two families for its main step" % id)
		t.check(b.has(r.b) and not b.has(r.a), "%s: B holds its own main power, not A's" % id)
		t.check(b.size() <= m.slots and _dp(b) <= m.dp_capacity,
			"%s: B fits %d slots / %d DP (%d / %d)" % [id, m.slots, m.dp_capacity, b.size(), _dp(b)])
		if id != "warning":  # Task 8 widens the board Warning's pool with Death Mark and removes this skip
			t.check(_in_pool(b, m.powers()), "%s: B is in the board pool" % id)
		t.check(b != m.default_loadout, "%s: B differs from A" % id)
		t.check(RouteBook.main_a(id) == r.a and RouteBook.main_b(id) == r.b, "%s: main_a / main_b read the row" % id)
	t.check(RouteBook.loadout_b("nope").is_empty() and RouteBook.main_b("nope") == "", "an unknown id has no route")

	# The Long Night: each act's own loadout B on the board night's slots and DP, in the act's pool.
	var night := TierBook.board("long_night")
	for act_id in ["omen", "festival", "procession", "judgement"]:
		var keys := PackedStringArray(RouteBook.ACTS_B.get(act_id, []))
		var a: ActDef = night.act(act_id)
		t.check(a != null and not keys.is_empty() and keys.size() <= a.slots and _dp(keys) <= a.dp_capacity and _in_pool(keys, a.powers()),
			"long_night %s: B fits %d slots / %d DP (%d / %d)" % [act_id, a.slots if a != null else 0, a.dp_capacity if a != null else 0,
				keys.size(), _dp(keys)])
		t.check(RouteBook.loadout_b_for_act("long_night", act_id) == keys, "long_night %s: loadout_b_for_act reads ACTS_B" % act_id)
	t.check(RouteBook.loadout_b_for_act("tax_collector", "omen") == RouteBook.loadout_b("tax_collector"), "a mission without acts has its own")

	# behaviour_check --route=b plays every board mission: its scenario -> id map plus the Festival and the Procession (by --path)
	# cover all 25 ids, and each tier file holds an act_ and a state_ function for each of its missions (a tier task never edits
	# behaviour_check.gd).
	var bc: GDScript = load("res://tools/dev/behaviour_check.gd")
	var map: Dictionary = bc.get_script_constant_map()
	var tiers: Array = map.get("TIER_B", [])
	var ids_by_scenario: Dictionary = map.get("ROUTE_IDS", {})
	var covered := {"festival": "feast", "procession": "feast"}
	for scenario in ids_by_scenario:
		covered[ids_by_scenario[scenario]] = scenario
	t.check(tiers.size() == 5, "five tier files for the B policies")
	for id in ids:
		t.check(covered.has(id), "%s: --route=b has a scenario for it" % id)
		var tier_n := TierBook.tier_of(id)
		if tiers.size() == 5 and covered.has(id):
			var label: String = id if covered[id] == "feast" else String(covered[id])
			var methods := []
			for m in (tiers[tier_n - 1] as GDScript).get_script_method_list():
				methods.append(String(m.name))
			t.check(methods.has("act_" + label) and methods.has("state_" + label), "%s: tier %d has act_%s and state_%s" % [id, tier_n, label, label])
