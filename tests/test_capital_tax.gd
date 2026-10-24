extends RefCounted
## v0.12 Task 10 (spec 2.2): the Tax Collector in the Capital. The overrides file `capital_missions/tax_collector.gd` is valid (every
## key takes), the Capital hosts the mission, the counting-house is the Great Market's weigh-house, the eight debtors' dwellings are
## distinct old-town houses whose doors are reached, the key walks stay within 0.75-1.35x of Aldermere's (D26), the intro camera keeps
## the first tags clear of the HUD stack, the tour's words are the town's, and the designed waits are inside the rules.

const Kit := preload("res://tests/test_tier2_groundwork.gd")
const ID := "tax_collector"
const CAPITAL_ID := "tax_collector@capital"
## D26: the Capital's key walks against Aldermere's, as a ratio.
const BAND_LO := 0.75
const BAND_HI := 1.35


static func run(t) -> void:
	City.use(&"aldermere")
	_overrides_valid(t)
	_hostable(t)
	var ald := _night(&"aldermere", MissionBook.tax_collector())
	var cap := _night(&"capital", MissionBook.get_mission(CAPITAL_ID))
	_counting_house(t, cap)
	_spots_land(t, cap)
	_walk_parity(t, ald, cap)
	_camera_clear(t, cap)
	_tour_true(t, cap)
	_waits(t, cap)
	City.use(&"aldermere")
	t.check(City.current().id() == &"aldermere", "the Capital tax test leaves Aldermere the active city")


## A town (the active city `city`), the mission's director set up in it, and the numbers the tests read, then the world let go.
static func _night(city: StringName, def: MissionDef) -> Dictionary:
	City.use(city)
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = City.current().map()
	var node := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, node, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var d := def.make_director() as TaxCollectorDirector
	d.setup(rules, crowd, town, null)
	var out := {"city": city, "camera": def.camera(), "intro_from": def.intro_from, "hideout": d.hideout.art_tag,
		"hideout_at": d.hideout.center(), "door": d.hide_door, "safe": d.safe_at, "gate": Places.point(&"citadel_gate"),
		"set_out": d.set_out_at.duplicate(), "chain_wait": d.chain_wait, "tour": d.tour(), "rounds": d.rounds.duplicate(true),
		"counting_spot": d.counting_spot, "firsts": [], "lasts": [], "doors": [], "centres": [], "quarries": d.quarries.size(),
		"guards": d.guards.duplicate(), "fits": true}
	out["door_to_gate"] = _walk(grid, d.hide_door, d.safe_at)
	for q in d.quarries:
		var prev: Vector2 = d.hide_door
		out.firsts.append(_walk(grid, d.hide_door, q.stop_doors[0]) if not q.stop_doors.is_empty() else -1.0)
		out.lasts.append(_walk(grid, q.stop_doors.back(), d.safe_at) if not q.stop_doors.is_empty() else -1.0)
		var legs := []
		for door: Vector2 in q.stop_doors:
			legs.append(_walk(grid, prev, door))
			prev = door
		out.doors.append_array(q.stop_doors)
		for s: Structure in q.stops:
			out.centres.append(s.center())
			out.fits = out.fits and RuinWish.fits(s, "house")
		out["legs_%d" % q.index] = legs
	Kit.done({"rules": rules, "crowd": crowd, "field": field, "env": env, "town": town, "world": node})
	City.use(&"aldermere")
	return out


## The length of the walk the people use from `a` to `b`: the sum of the segments of `grid.path()`; -1.0 for no route.
static func _walk(grid: WalkGrid, a: Vector2, b: Vector2) -> float:
	var path := grid.path(a, b)
	if path.is_empty():
		return -1.0
	var total := 0.0
	var prev := a
	for p in path:
		total += prev.distance_to(p)
		prev = p
	return total


static func _overrides_valid(t) -> void:
	var cap := City.by_id(&"capital")
	var ov := cap.mission_overrides(ID)
	t.check(not ov.is_empty() and ov.keys().all(func(k: Variant) -> bool: return String(k) in Overrides.KEYS),
		"the Capital has a tax_collector overrides file with only the def and director sections")
	var def := MissionBook.tax_collector()
	var bad := Overrides.apply(def, ov.get("def", {}))
	t.check(bad.is_empty() and def.camera_at == ov.def.camera_at and def.intro_from == ov.def.intro_from,
		"the def overrides apply and read back (camera_at and intro_from together; bad=%s)" % [bad])
	var d := TaxCollectorDirector.new()
	bad = Overrides.apply(d, ov.get("director", {}), Overrides.town_vars(d))
	t.check(bad.is_empty(), "the director overrides apply to a fresh director, all of them town vars (bad=%s)" % [bad])
	for key: Variant in ov.director:
		t.check(typeof(d.get(String(key))) == typeof(ov.director[key]) and d.get(String(key)) == ov.director[key],
			"the director's %s reads back as the override, of the seeded type" % key)
	var made := MissionBook.get_mission(CAPITAL_ID).make_director() as TaxCollectorDirector
	t.check(made.counting_tag == &"gpt_weighhouse" and made.rounds.size() == 3 and made.counting_spot != Vector2.INF,
		"a director made for tax_collector@capital carries the town's counting-house and rounds")
	var plain := MissionBook.tax_collector().make_director() as TaxCollectorDirector
	t.check(plain.counting_tag == TaxCollectorDirector.COUNTING_TAG and plain.rounds == TaxCollectorDirector.ROUNDS,
		"Aldermere's own director keeps its consts")


static func _hostable(t) -> void:
	var cap := City.by_id(&"capital")
	t.check(MissionBook.hostable(ID, cap), "the Capital hosts the Tax Collector (its needs are met and it has the overrides)")
	t.check(MissionBook.town_missions(&"capital").has(CAPITAL_ID), "the Capital's DEV list offers tax_collector@capital")
	t.check(MissionBook.is_dev(CAPITAL_ID), "a Capital night is a dev night")
	t.check(Mission.hosting_error(MissionBook.get_mission(CAPITAL_ID), &"capital") == "", "starting it in the Capital is not refused")


static func _counting_house(t, cap: Dictionary) -> void:
	t.check(cap.hideout == &"gpt_weighhouse", "the Capital's counting-house is the weigh-house building (%s)" % [cap.hideout])
	t.check((cap.hideout_at as Vector2).distance_to(cap.counting_spot) < 2.0,
		"the weigh-house stands at the counting spot (%s vs %s)" % [cap.hideout_at, cap.counting_spot])
	t.check(cap.quarries == 3 and cap.guards == [2, 1, 1], "three collectors with Aldermere's guards (2, 1, 1)")
	t.check(cap.gate == Vector2(0.0, -22.6) and (cap.safe as Vector2).distance_to(cap.gate) <= 0.6,
		"the taxes' goal is the Keep's gate (0, -22.6), not an Aldermere point (%s)" % [cap.safe])


## Every debtor's dwelling is a distinct old-town house the street reaches from the counting-house, at its spot; their doors are
## spread (> 1.6 apart); nothing was dropped.
static func _spots_land(t, cap: Dictionary) -> void:
	var spots: Array = []
	for r: Array in cap.rounds:
		spots.append_array(r)
	var houses: Array = cap.centres
	t.check(spots.size() == 8 and houses.size() == 8, "eight debtor spots resolve to eight dwellings (%d spots, %d houses)" % [spots.size(), houses.size()])
	var seen := {}
	var near := true
	for i in mini(spots.size(), houses.size()):
		near = near and (spots[i] as Vector2).distance_to(houses[i]) <= 0.6
		seen[houses[i]] = true
	t.check(near and seen.size() == houses.size(), "each spot lies on its own dwelling's centre (within 0.6), none shared")
	t.check(cap.fits, "every debtor's dwelling is one RuinWish.fits() accepts")
	var spread := true
	var doors: Array = cap.doors
	for i in doors.size():
		for j in range(i + 1, doors.size()):
			spread = spread and (doors[i] as Vector2).distance_to(doors[j]) > 1.6
	t.check(spread, "the debtors' doors are more than 1.6 apart")
	var inner := true
	for c: Vector2 in houses:
		inner = inner and absf(c.x) < 21.0 and c.y > -18.0 and c.y < 3.0
	t.check(inner, "every debtor lives inside the old town's wall ring, north of the river")


## D26: the key walks, printed for both towns; each within 0.75-1.35x of Aldermere's.
static func _walk_parity(t, ald: Dictionary, cap: Dictionary) -> void:
	print("  tax parity: door->gate A %.1f C %.1f | first legs A %s C %s | last->gate A %s C %s" % [ald.door_to_gate, cap.door_to_gate,
		_fmt(ald.firsts), _fmt(cap.firsts), _fmt(ald.lasts), _fmt(cap.lasts)])
	_in_band(t, "door -> Citadel gate", ald.door_to_gate, cap.door_to_gate)
	for i in 3:
		_in_band(t, "round %d: door -> first debtor" % i, ald.firsts[i], cap.firsts[i])
		_in_band(t, "round %d: last debtor -> Citadel gate" % i, ald.lasts[i], cap.lasts[i])


static func _in_band(t, what: String, a: float, c: float) -> void:
	var r := c / a if a > 0.0 else -1.0
	t.check(a > 0.0 and c > 0.0 and r >= BAND_LO and r <= BAND_HI, "walk parity, %s: Aldermere %.1f, Capital %.1f (x%.2f, band %.2f-%.2f)" % [
		what, a, c, r, BAND_LO, BAND_HI])


static func _fmt(a: Array) -> String:
	return "[" + ", ".join(a.map(func(v: float) -> String: return "%.1f" % v)) + "]"


## At the intro's resting camera, the counting-house's tag, its door, the first debtor's door and the Citadel's gate (or their edge
## arrows) are clear of the HUD stack grown by its pad; the intro starts near its end.
static func _camera_clear(t, cap: Dictionary) -> void:
	var zone := Rect2(Kit.STACK.position, Kit.STACK.size + Vector2(Hud.STACK_PAD, Hud.STACK_PAD))
	var cam: Vector2 = cap.camera
	var clear := true
	for g: Vector2 in [cap.hideout_at, cap.door, cap.doors[0], cap.safe]:
		clear = clear and Kit.clear_of_stack(g, cam, zone)
	t.check(clear, "at the intro camera %s the weigh-house, its door, the first debtor and the Keep's gate are clear of the padded stack" % [cam])
	t.check((cap.intro_from as Vector2).is_equal_approx(cam + Vector2(0.0, 6.0)),
		"the intro starts 6 south of the camera (%s -> %s)" % [cap.intro_from, cam])
	t.check(cam.distance_to(cap.hideout_at) < 12.0, "the camera rests on the counting-house (%.1f from it)" % cam.distance_to(cap.hideout_at))


## The tour names the town's own times and places.
static func _tour_true(t, cap: Dictionary) -> void:
	var tour: Array = cap.tour
	var text := ""
	for stop: Array in tour:
		text += String(stop[1]) + " | "
	var so: Array = cap.set_out
	t.check(tour.size() == 3 and text.contains(UiTheme.clock(so[0])) and text.contains(UiTheme.clock(so[1])) and text.contains(UiTheme.clock(so[2])),
		"the tour names the set-out times (%s)" % [text])
	t.check((tour[0][0] as Vector2).distance_to(cap.door) < 0.01 and (tour[2][0] as Vector2).distance_to(cap.safe) < 0.01,
		"the tour's first stop is the weigh-house's door and its last the Keep's gate")


## Designed waits: each set-out at most 60 s after the one before; the chain at most 50 s; Aldermere's times kept.
static func _waits(t, cap: Dictionary) -> void:
	var so: Array = cap.set_out
	var ok := float(so[0]) <= 60.0
	for i in range(1, so.size()):
		ok = ok and float(so[i]) - float(so[i - 1]) <= 60.0
	t.check(ok and float(cap.chain_wait) <= 50.0, "no designed wait over 60 s (set out %s, chain %.0f)" % [so, cap.chain_wait])
