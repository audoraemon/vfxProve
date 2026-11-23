extends RefCounted
## The Might gauge through the real route (Task 9a): a Mission node in a tree, started as Game starts a god's Endless Night
## (GodNight.def_for as night_def, night_loadout), then next_act(). Nothing here is built by hand, unlike test_might_night.

const TYPE := "ruin"


## A god in memory (never a file): its type's tier 1 and 2 keys, and its neighbours' tier 1 keys, learned, so the bar has pages.
static func _god(sealed := "") -> GodSlot:
	var s := GodSlot.make(1, TYPE, 5)
	var keys := GodTree.keys_for(TYPE, 2)
	for n: String in GodTree.neighbours(TYPE):
		keys.append_array(GodTree.keys_for(n, 1))
	for k in keys:
		s.learned[k] = 1
	if sealed != "":
		s.sealed = sealed
		s.seal_nights = 2
	return s


## The night of `id` for `god` as Game._build_mission builds it, started in the tree; the caller frees it. `god` null: a board night.
static func _start(t, god: GodSlot, id: String) -> Mission:
	City.use(&"aldermere")
	var m: Mission = load("res://scenes/mission.tscn").instantiate()
	m.autostart = false
	m.mission_id = id
	m.board = true
	if god != null:
		m.night_def = func() -> MissionDef: return GodNight.def_for(god, id)
		m.levels = god.learned.duplicate()
		m.wish_seed = GodNight.wish_seed(god, id)
		m.restart_locked = true
	t.root.add_child(m)
	if not m.is_prewarmed:
		await m.prewarmed
	m.start(GodNight.night_loadout(god) if god != null else PackedStringArray(["heaven", "tsunami", "cinder", "nova"]), 7)
	return m


static func _free(t, m: Mission) -> void:
	m.queue_free()
	await t.process_frame


## The first board id whose god night has a second act.
static func _acted(god: GodSlot) -> String:
	for id in TierBook.all():
		var d := GodNight.def_for(god, id)
		if d != null and d.has_acts():
			return id
	return ""


## The slot holding `key` in the mission's loadout, or -1.
static func _slot_of(m: Mission, key: String) -> int:
	for i in m._rules.loadout.size():
		if m._rules.key(i) == key:
			return i
	return -1


static func run(t) -> void:
	await _route(t)
	await _sealed(t)
	await _board(t)


static func _route(t) -> void:
	var god := _god()
	var id := _acted(god)
	t.check(id != "", "a board night with a second act exists (%s)" % id)
	if id == "":
		return
	var m: Mission = await _start(t, god, id)
	var r: Rules = m._rules
	var p: MightPool = r.might
	t.check(p != null and is_equal_approx(p.capacity, float(god.max_might())) and is_equal_approx(p.value, p.capacity)
		and is_equal_approx(p.refill_seconds, god.refill_seconds()), "start(): a full pool of the god's size and refill")
	var bar: AbilityBar = m._hud.bar if m._hud != null else null
	t.check(bar != null and not bar.open, "start(): the bar is there and hidden")
	if bar == null:
		await _free(t, m)
		return
	var own: Dictionary = bar.pages()[bar.page] if bar.page < bar.pages().size() else {}
	t.check(String(own.get("type", "")) == god.type and bar.pages().size() >= 2, "start(): on the god's own type page (%s)" % str(own.get("type")))
	var all := true
	for k in god.in_tree():
		all = all and _slot_of(m, k) >= 0
	t.check(all, "start(): the loadout holds every key of the tree")
	# A real cast.
	var key := ""
	for k in god.in_tree():
		if PowerBook.might(k, 1) <= int(p.capacity) and _slot_of(m, k) >= 0 and r.refusal(_slot_of(m, k)) == "":
			key = k
			break
	t.check(key != "", "an affordable power is castable (%s)" % key)
	var slot := _slot_of(m, key)
	var cost := PowerBook.might(key, int(r.levels.get(key, 1)))
	var before := p.value
	var cast := r.cast(slot, m._act.camera() if m._act != null else Vector2.ZERO)
	t.check(cast != null, "the cast went through")
	t.near(p.value, before - cost, 0.001, "the cast lowered the pool by the power's Might (%d)" % cost)
	t.check(m.cast_keys().has(key), "cast_keys() holds the cast key")
	# A drained pool refuses.
	var other := -1
	for i in r.loadout.size():
		if i != slot and r.key(i) != r.sealed:
			other = i
			break
	p.value = 0.0
	t.check(other >= 0 and r.refusal(other) != "" and (r.cooldown_left(other) > 0.0 or r.refusal(other) == "might" or r.busy_left() > 0.0),
		"drained: refused (%s)" % r.refusal(other))
	var pricey := -1
	for i in r.loadout.size():
		if r.cooldown_left(i) <= 0.0 and r.might_cost(i) > 0:
			pricey = i
			break
	r.finished = false
	t.check(pricey >= 0 and (r.refusal(pricey) == "might" or r.refusal(pricey) == "busy"), "drained pool: a ready power is refused for Might (or the running cast)")
	if pricey >= 0 and r.busy_left() <= 0.0:
		t.check(r.refusal(pricey) == "might", "drained pool, nothing running: refusal is 'might'")
	# Open the bar, turn a page, go to the next act.
	bar.toggle()
	bar.turn(1)
	var open_page := bar.page
	t.check(bar.open, "the bar opened")
	m.next_act(GodNight.night_loadout(god))
	var r2: Rules = m._rules
	var p2: MightPool = r2.might
	t.check(r2 != r and p2 != null and p2 != p, "next_act(): new Rules with a new pool")
	t.check(p2 != null and is_equal_approx(p2.capacity, float(god.max_might())) and is_equal_approx(p2.value, p2.capacity)
		and is_equal_approx(p2.refill_seconds, god.refill_seconds()), "next_act(): full again, the same capacity and refill")
	var bar2: AbilityBar = m._hud.bar if m._hud != null else null
	t.check(bar2 != null and bar2 != bar and bar2.open and bar2.page == open_page, "next_act(): the bar's open and page are kept (page %d)" % open_page)
	t.check(m.cast_keys().has(key), "next_act(): the first act's key is still in cast_keys()")
	var s2 := _slot_of(m, key)
	if s2 >= 0 and r2.refusal(s2) == "":
		r2.cast(s2, Vector2.ZERO)
	t.check(m.cast_keys().count(key) == 1, "the same key cast again in act two is counted once (%d)" % m.cast_keys().count(key))
	await _free(t, m)


static func _sealed(t) -> void:
	var probe := _god()
	var key: String = probe.in_tree()[0]
	var god := _god(key)
	var m: Mission = await _start(t, god, "warning")
	var s := _slot_of(m, key)
	t.check(s >= 0, "a sealed key is in the loadout")
	t.check(s >= 0 and m._rules.refusal(s) == "sealed", "and refused as sealed")
	t.check(s >= 0 and m._hud.bar != null and m._hud.bar.tile_state(s) == "sealed", "and its tile reads sealed")
	await _free(t, m)


static func _board(t) -> void:
	var m: Mission = await _start(t, null, "warning")
	t.check(m._rules.might == null, "a board night: no pool")
	t.check(m._hud.bar == null, "a board night: no bar")
	await _free(t, m)
