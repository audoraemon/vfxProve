extends RefCounted
## The old Endless Night draft kept behind one switch (Ruling R10): GodNight.draft is false by default (the Might gauge night); true brings back
## acb82b96's night -- the draftable pool, no gauge, the drafted loadout carried and saved, the SLOT Faith row, the editable Prepare and the
## draft wording. Every test that turns the switch on turns it off again before it returns (the suites share one process).

const TYPE := "ruin"
const FILE := "user://test_god_draft_switch.cfg"


## A god in memory: its type's tier 1 and 2 keys learned, the first one sealed for two nights, a drafted loadout of the next two.
static func _god(sealed := true) -> GodSlot:
	var s := GodSlot.make(1, TYPE, 5)
	s.tier = 2
	for k in GodTree.keys_for(TYPE, 2):
		s.learned[k] = 1
	if sealed:
		s.seal(s.in_tree()[0])
		s.seal_nights = 2
	var tree := s.draftable()
	s.loadout = PackedStringArray([tree[0], tree[1]])
	return s


static func _outcome(cast: PackedStringArray) -> Dictionary:
	return {"won": true, "reason": "warning", "time": 80.0, "cast": cast,
		"descend": {"tier": 1, "main": true, "main_reward": 10, "wishes": [], "earned": 30, "ascended": true}}


static func _labels(m: Menu) -> Array:
	var out := []
	for item: Dictionary in m.items:
		out.append(String(item.label))
	return out


static func run(t) -> void:
	_default(t)
	_def(t)
	_loadout_and_bank(t)
	_faith(t)
	_screens(t)
	await _mission(t)
	_round_trip(t)
	t.check(not GodNight.draft, "the switch is off again after the suite")


static func _default(t) -> void:
	t.check(not GodNight.draft, "GodNight.draft is false by default")


static func _def(t) -> void:
	var god := _god()
	var sealed := god.sealed
	t.check(sealed != "" and god.in_tree().has(sealed) and not god.draftable().has(sealed), "the fixture seals a key that is in the tree")
	for id in ["warning", RiteBook.FIRST_TASTE]:
		GodNight.draft = true
		var d := GodNight.def_for(god, id)
		GodNight.draft = false
		var g := GodNight.def_for(god, id)
		t.check(d != null and g != null, "%s: a def in each mode" % id)
		if d == null or g == null:
			continue
		t.check(d.pool == god.draftable() and not Array(d.pool).has(sealed), "%s draft: the pool is draftable(), the sealed key out (%s)" % [id, d.pool])
		t.check(not d.gauge() and d.might_capacity == 0 and d.sealed == "" and d.god_type == "", "%s draft: no gauge, no seal, no type" % id)
		t.check(d.slots == god.slots() and d.dp_capacity == god.max_might(), "%s draft: the god's slots and Might budget" % id)
		t.check(g.pool == god.in_tree() and Array(g.pool).has(sealed), "%s gauge: the pool is in_tree(), the sealed key in" % id)
		t.check(g.gauge() and g.sealed == sealed and g.god_type == TYPE, "%s gauge: the gauge, the seal and the type" % id)
	GodNight.draft = true
	var acted := GodNight.def_for(god, "warning")
	GodNight.draft = false
	var acts_ok := acted != null
	for a: ActDef in (acted.acts if acted != null else []):
		acts_ok = acts_ok and not a.gauge() and a.pool == god.draftable()
	t.check(acts_ok, "draft: every act carries the draftable pool and no gauge")


static func _loadout_and_bank(t) -> void:
	var god := _god()
	t.check(GodNight.night_loadout(god) == god.in_tree(), "gauge: the night starts with the whole tree")
	GodNight.draft = true
	var kept := GodNight.night_loadout(god)
	t.check(kept == god.loadout and kept != god.in_tree() and not kept.has(god.sealed), "draft: the night starts with the saved loadout (%s)" % [kept])
	kept.append("x")
	t.check(god.loadout.size() == 2, "draft: the loadout is a copy")
	var drafted := PackedStringArray([god.draftable()[0]])
	var cast := PackedStringArray([god.draftable()[1], god.draftable()[2]])
	var out := _outcome(cast)
	t.check(GodNight.carried_keys(drafted, out) == drafted, "draft: carried_keys() is the drafted loadout")
	var res := GodNight.bank(god, "warning", GodNight.carried_keys(drafted, out), out)
	GodNight.draft = false
	t.check(res.has("night") and int(god.carried.get(drafted[0], 0)) == 1 and not god.carried.has(cast[0]), "draft: bank() counts the drafted keys (%s)" % [god.carried])
	t.check(god.loadout == drafted, "draft: bank() writes the drafted loadout (%s)" % [god.loadout])
	var other := _god()
	var before := other.loadout.duplicate()
	t.check(GodNight.carried_keys(drafted, out) == cast, "gauge: carried_keys() is outcome.cast")
	GodNight.bank(other, "warning", GodNight.carried_keys(drafted, out), out)
	t.check(int(other.carried.get(cast[0], 0)) == 1 and int(other.carried.get(cast[1], 0)) == 1 and not other.carried.has(drafted[0]),
		"gauge: bank() counts what was cast (%s)" % [other.carried])
	t.check(other.loadout == before, "gauge: bank() leaves the loadout alone (%s)" % [other.loadout])
	# A rite banks the same way.
	GodNight.draft = true
	var rite := _god()
	GodNight.bank(rite, RiteBook.FIRST_TASTE, drafted, {"won": false, "cast": cast})
	GodNight.draft = false
	t.check(rite.loadout == drafted and int(rite.carried.get(drafted[0], 0)) == 1 and not rite.carried.has(cast[0]), "draft: a rite carries and saves the drafted keys")
	var rite_g := _god()
	var rite_before := rite_g.loadout.duplicate()
	GodNight.bank(rite_g, RiteBook.FIRST_TASTE, cast, {"won": false, "cast": cast})
	t.check(rite_g.loadout == rite_before and int(rite_g.carried.get(cast[0], 0)) == 1, "gauge: a rite carries what was cast and leaves the loadout")


static func _faith(t) -> void:
	for mode in [false, true]:
		GodNight.draft = mode
		var god := _god()
		god.faith = 1000
		var screen := FaithScreen.new().setup(god)
		var name := "+1 SLOT" if mode else "FASTER MIGHT"
		t.check(screen.row_line("slot").begins_with(name + "   150 Faith"), "faith (draft %s): the slot row reads %s (%s)" % [mode, name, screen.row_line("slot")])
		t.check(screen.row_line("might").begins_with("+1 MIGHT"), "faith (draft %s): the Might row keeps its name" % mode)
		var want_slot := "Slots in a draft: %d" % god.slots() if mode else "Full refill: %d s" % int(god.refill_seconds())
		t.check(screen.effect_line("slot") == want_slot, "faith (draft %s): the slot detail (%s)" % [mode, screen.effect_line("slot")])
		t.check(screen.effect_line("might") == ("Might to spend: %d" if mode else "Might gauge: %d") % god.max_might(), "faith (draft %s): the Might detail (%s)" % [mode, screen.effect_line("might")])
		var slots := god.slots()
		var refill := god.refill_seconds()
		t.check(screen.buy("slot"), "faith (draft %s): the slot row is bought" % mode)
		t.check(god.slots() == slots + 1 and god.refill_seconds() < refill and int(god.bought.slot) == 1 and is_equal_approx(god.refill_seconds(), MightPool.refill_for(1)),
			"faith (draft %s): one count gives a slot and a faster refill (%d slots, %.1f s)" % [mode, god.slots(), god.refill_seconds()])
		screen.free()
	GodNight.draft = false
	t.check(GodSlot.VERSION == 1, "the god file version stays 1")


static func _prepare(god: GodSlot, id: String) -> PrepareScreen:
	var prep := PrepareScreen.new()
	prep.god = god
	prep.setup(GodNight.def_for(god, id), god.loadout if GodNight.draft else GodNight.night_loadout(god))
	return prep


static func _row(prep: PrepareScreen, label: String) -> String:
	for r: Array in prep.brief_rows():
		if r[0] == label:
			return String(r[1])
	return ""


static func _screens(t) -> void:
	var god := _god()
	GodNight.draft = true
	var prep := _prepare(god, "warning")
	t.check(not prep.read_only and prep.confirm_label == "MANIFEST" and can_draft_pick(prep), "draft: Endless Prepare is the editable draft (%s)" % prep.confirm_label)
	t.check(prep.draft.picks == god.loadout and prep.draft.slots == god.slots() and prep.draft.capacity == god.max_might(), "draft: the saved loadout is preselected inside the budget (%s)" % [prep.draft.picks])
	t.check(prep.draft.refusal(god.sealed) == "pool", "draft: the sealed key is not in the pool, so never a pick (%s)" % prep.draft.refusal(god.sealed))
	t.check(_row(prep, "TEMPLE") == "Its fall resets every cooldown, once" and _row(prep, "LOADOUT") != "All your abilities, each cast paid in Might", "draft: the old TEMPLE and LOADOUT rows (%s)" % _row(prep, "LOADOUT"))
	t.check(prep.budget_text() != "" and prep.hint_text().begins_with("Pick up to"), "draft: the slot and Might meter and the pick hint")
	prep.draft.picks = PackedStringArray()
	t.check(not prep.can_manifest(), "draft: nothing drafted cannot be confirmed")
	prep.free()
	var hub := GodHub.new().setup(god)
	t.check(hub.can_descend(), "draft hub: a god with a draftable key can descend")
	hub.free()
	var only := GodSlot.make(1, TYPE, 5)
	only.learned = {}
	only.learned[GodTree.keys_for(TYPE, 1)[0]] = 1
	only.seal(only.in_tree()[0])
	only.seal_nights = 2
	var blocked := GodHub.new().setup(only)
	t.check(not blocked.can_descend() and blocked.blocked_line() == GodHub.BLOCKED_DRAFT and GodHub.BLOCKED_DRAFT.begins_with("Nothing to draft"),
		"draft hub: only a sealed key blocks the descent, with the draft wording (%s)" % blocked.blocked_line())
	blocked.free()
	t.check(Game.awaken_target(only) == "", "draft: Awaken opens nothing with only a sealed key")
	var card := InterludeScreen.new()
	card.endless = true
	card.setup({"mission": "omen", "won": true, "goal": {"label": "x", "done": true}, "bonuses": [], "time": 21.4}, [MissionBook.long_night().act("festival")], NightState.new())
	t.check(_labels(card._menu) == ["Choose powers", "Abandon night"], "draft: the Endless interlude says Choose powers (%s)" % [_labels(card._menu)])
	card.free()
	GodNight.draft = false
	prep = _prepare(god, "warning")
	t.check(prep.read_only and prep.confirm_label == "DESCEND" and prep.can_manifest(), "gauge: Endless Prepare is the read-only briefing (%s)" % prep.confirm_label)
	t.check(_row(prep, "TEMPLE") != "Its fall resets every cooldown, once" and prep.budget_text() == "" and prep.hint_text() == PrepareScreen.HINT_BRIEFING, "gauge: the briefing's rows, no meter")
	prep.free()
	hub = GodHub.new().setup(god)
	t.check(hub.can_descend(), "gauge hub: descends")
	hub.free()
	blocked = GodHub.new().setup(only)
	t.check(blocked.can_descend() and blocked.blocked_line() == "" and GodHub.BLOCKED.begins_with("Nothing to cast"), "gauge hub: a sealed key still descends (it shows locked)")
	blocked.free()
	card = InterludeScreen.new()
	card.endless = true
	card.setup({"mission": "omen", "won": true, "goal": {"label": "x", "done": true}, "bonuses": [], "time": 21.4}, [MissionBook.long_night().act("festival")], NightState.new())
	t.check(_labels(card._menu) == ["Briefing", "Abandon night"], "gauge: the Endless interlude says Briefing (%s)" % [_labels(card._menu)])
	card.free()


## True when a power card can be clicked into the draft (the draft is editable).
static func can_draft_pick(prep: PrepareScreen) -> bool:
	var keys := prep.shown()
	if keys.is_empty():
		return false
	var before := prep.draft.picks.duplicate()
	var at := 0
	while at < keys.size() - 1 and (keys[at] == prep.god.sealed or before.has(keys[at])):
		at += 1
	prep.click(PrepareScreen.cell_rect(at, keys.size()).get_center())
	var changed := prep.draft.picks != before
	prep.draft.picks = before
	return changed


static func _mission(t) -> void:
	var god := _god()
	City.use(&"aldermere")
	GodNight.draft = true
	var m: Mission = load("res://scenes/mission.tscn").instantiate()
	m.autostart = false
	m.mission_id = "warning"
	m.board = true
	m.night_def = func() -> MissionDef: return GodNight.def_for(god, "warning")
	m.levels = god.learned.duplicate()
	m.restart_locked = true
	t.root.add_child(m)
	if not m.is_prewarmed:
		await m.prewarmed
	m.start(GodNight.night_loadout(god), 7)
	var r: Rules = m._rules
	t.check(r.might == null and m._hud != null and m._hud.bar == null, "draft night: no Might pool, no ability bar")
	t.check(Array(r.loadout) == Array(god.loadout) and not Array(r.loadout).has(god.sealed), "draft night: the drafted loadout is the six slots' kit (%s)" % [r.loadout])
	var bad := ""
	for i in r.loadout.size():
		var why := r.refusal(i)
		if why == "might" or why == "sealed":
			bad = why
	t.check(bad == "", "draft night: no power is refused for Might or a seal (%s)" % bad)
	var cast := r.cast(0, Vector2.ZERO)
	t.check(cast != null and r.refusal(0) != "might", "draft night: a cast goes through and pays no gauge")
	GodNight.draft = false
	m.queue_free()
	await t.process_frame


static func _round_trip(t) -> void:
	var abs_file := ProjectSettings.globalize_path(FILE)
	# A draft night writes its loadout; the file reads back in gauge mode and plays a gauge night.
	GodNight.draft = true
	var god := _god(false)
	god.faith = 500
	god.buy("slot")
	var drafted := PackedStringArray([god.draftable()[2]])
	var out := _outcome(PackedStringArray())
	GodNight.bank(god, "warning", GodNight.carried_keys(drafted, out), out)
	GodNight.draft = false
	t.check(god.write(FILE) == OK, "the draft night's god file is written")
	var back := GodSlot.read(FILE)
	t.check(back != null and back.loadout == drafted and int(back.bought.slot) == 1 and int(back.carried.get(drafted[0], 0)) == 1, "the file keeps the loadout, the slot count and the carried")
	if back != null:
		var d := GodNight.def_for(back, "warning")
		t.check(d.gauge() and d.pool == back.in_tree() and GodNight.night_loadout(back) == back.in_tree() and is_equal_approx(d.might_refill, MightPool.refill_for(1)),
			"read in gauge mode: a gauge night of the whole tree, the one count as a faster refill")
		var cast_out := _outcome(PackedStringArray([back.in_tree()[0]]))
		GodNight.bank(back, "warning", GodNight.carried_keys(back.loadout, cast_out), cast_out)
		t.check(back.loadout == drafted and int(back.carried.get(back.in_tree()[0], 0)) == 1, "a gauge night then counts what was cast and keeps the loadout")
		t.check(back.write(FILE) == OK, "and writes the file")
	# And back: read in draft mode, the saved loadout is the night's kit and the count is a slot.
	GodNight.draft = true
	var again := GodSlot.read(FILE)
	if again != null:
		var d2 := GodNight.def_for(again, "warning")
		t.check(not d2.gauge() and d2.pool == again.draftable() and GodNight.night_loadout(again) == drafted and d2.slots == again.slots() and again.slots() == GodSlot.BASE_SLOTS + 1,
			"read in draft mode: the draft night of the saved loadout, the one count as a slot")
	else:
		t.check(false, "the file reads back")
	GodNight.draft = false
	DirAccess.remove_absolute(abs_file)
