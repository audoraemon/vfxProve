extends RefCounted
## The task line (MissionSteps, Hud.task_rect()): every mission and act has steps, the labels are short, the current step follows the director's
## state, the line is up in both detail modes and meets none of the HUD's other plates at 640x360 and 960x495.

const Kit := preload("res://tests/test_tier2_groundwork.gd")
const ClarityKit := preload("res://tests/clarity_kit.gd")


## A director that sits in the phase a test sets, counting down the seconds it sets.
class PhaseStub extends MissionDirector:
	var phase := ""
	var secs := 0.0

	func hint_phase() -> String:
		return phase

	func step_seconds() -> float:
		return secs


static func run(t) -> void:
	_coverage(t)
	_resolve(t)
	_advance(t)
	_modes(t)
	_layout(t)
	Hud.reset_session()
	UiScale.clear_test_area()


## Every mission and act the game can play, by id.
static func _all_ids() -> PackedStringArray:
	var defs: Array = []
	defs.append_array(MissionBook.all())
	defs.append_array(MissionBook.campaign_missions())
	defs.append_array(MissionBook.tier_missions())
	defs.append_array(MissionBook.dev_missions())
	defs.append_array(MissionBook.rite_missions())
	defs.append_array(MissionBook.hunt_missions())
	defs.append(MissionBook.remembrance())
	defs.append(MissionBook.feast("festival"))
	defs.append(MissionBook.feast("procession"))
	var out := PackedStringArray()
	for d: MissionDef in defs:
		if not out.has(d.id):
			out.append(d.id)
		if d.has_acts():
			for a in d.acts:
				if not out.has(a.id):
					out.append(a.id)
	return out


static func _coverage(t) -> void:
	var ids := _all_ids()
	t.check(ids.size() >= 35, "the test sees the game's missions and acts (%d)" % ids.size())
	var missing := PackedStringArray()
	var long := PackedStringArray()
	var no_default := PackedStringArray()
	var odd := PackedStringArray()
	var wide := PackedStringArray()
	var room := Hud.HINT_W - Hud.TASK_PAD - 6.0
	for id in ids:
		var list := MissionSteps.steps(id)
		if list.is_empty():
			missing.append(id)
			continue
		if MissionSteps.steps(MissionBook.city_id(id, &"capital")) != list:
			odd.append(id + " (city)")
		var has_default := false
		for step: Dictionary in list:
			var label := String(step.get("t", ""))
			if label == "" or label.length() > MissionSteps.MAX_LABEL:
				long.append("%s: %s" % [id, label])
			if not step.has("ph"):
				has_default = true
			elif (step["ph"] as Array).is_empty() or (step["ph"] as Array).has(""):
				odd.append(id + " (empty phase)")
			if not String(step.get("c", "")) in ["", MissionSteps.COUNT_N, MissionSteps.COUNT_S]:
				odd.append(id + " (counter)")
			if UiTheme.width(label + " 00/00", UiTheme.TEXT_S) > room or UiTheme.width(label + " 10:00", UiTheme.TEXT_S) > room:
				wide.append("%s: %s" % [id, label])
		if not has_default:
			no_default.append(id)
	t.check(missing.is_empty(), "every mission and act has steps (missing: %s)" % ", ".join(missing))
	t.check(long.is_empty(), "every label is 1-%d characters (%s)" % [MissionSteps.MAX_LABEL, "; ".join(long)])
	t.check(no_default.is_empty(), "every mission has a default step (%s)" % ", ".join(no_default))
	t.check(odd.is_empty(), "the tables are well formed (%s)" % ", ".join(odd))
	t.check(wide.is_empty(), "label and counter fit the plate (%s)" % "; ".join(wide))
	var unhinted := PackedStringArray()
	for key: String in MissionHints.LINES:
		if not key.contains(".") and MissionSteps.steps(key).is_empty():
			unhinted.append(key)
	t.check(unhinted.is_empty(), "every mission with a how-to-win line has steps (%s)" % ", ".join(unhinted))
	t.check(MissionSteps.steps("nowhere").is_empty() and MissionSteps.current(null).is_empty(), "an unknown mission has none; no rules, no line")
	t.check(MissionDirector.new().step_seconds() == 0.0, "a director counts nothing by default")


## Every key resolves (Mission clarity, spec 6.4.7): each phase a step or a hint line names is one the mission's directors can be in
## (hint_phases(), the union over every def that plays the id, a city twin's included), and every phase they can be in has a step (a
## named one or the default).
static func _resolve(t) -> void:
	var bad := PackedStringArray()
	var checked := 0
	for id in _all_ids():
		var phases := ClarityKit.phases_of(id)
		var list := MissionSteps.steps(id)
		var twin := MissionSteps.steps(MissionBook.city_id(id, &"capital"))
		if twin != list:
			bad.append("%s: its Capital twin has other steps" % id)
		for step: Dictionary in list:
			for ph: String in step.get("ph", []):
				checked += 1
				if not phases.has(ph):
					bad.append("%s: step phase '%s'" % [id, ph])
		for key: String in MissionHints.LINES:
			if key.begins_with(id + ".") and not phases.has(key.substr(id.length() + 1)):
				bad.append("%s: hint '%s'" % [id, key])
		for ph in phases:
			checked += 1
			if MissionSteps.index_for(list, ph) < 0:
				bad.append("%s: phase '%s' has no step" % [id, ph])
	t.check(checked > 100 and bad.is_empty(), "every step and hint key is a phase of its director, every phase has a step (%d checked; %s)" % [checked, "; ".join(bad)])


static func _stub_world(def: MissionDef) -> Dictionary:
	var stub := PhaseStub.new()
	return Kit.world(def, stub)


## The steps follow the phases, one function per mission, each in its group's block (Mission clarity, pre-flight I9: a group task edits only
## its own block's functions, so the six merge without touching one function).
## The dispatcher names groups only: a group adds its missions inside its own `_advance_<group>()`, never here.
static func _advance(t) -> void:
	_advance_escort(t)
	_advance_assassinate(t)
	_advance_raze(t)
	_advance_convert(t)
	_advance_intercept(t)
	_advance_hunt(t)


# --- clarity block: intercept ---
static func _advance_intercept(t) -> void:
	_advance_board(t)


## A board night whose main objective is done: the wishes, then the ascent (as the how-to-win line does).
static func _advance_board(t) -> void:
	var b := _board_world(TierBook.board("warning"))
	var rules: Rules = b.rules
	rules.main_done = true
	var descent: Descent = b.descent
	var open := descent.wishes.size()
	t.check(open > 0 and MissionSteps.line(rules) == "Grant the open wishes 0/%d" % open, "main objective done, wishes open (%s)" % MissionSteps.line(rules))
	for w in descent.wishes:
		w.status = Objective.Status.DONE
	t.check(MissionSteps.line(rules) == "Ascend when ready: press F", "every wish settled: the ascent (%s)" % MissionSteps.line(rules))
	_board_done(b)


# --- clarity block: assassinate ---
static func _advance_assassinate(t) -> void:
	_advance_tax(t)


static func _advance_tax(t) -> void:
	var s := _stub_world(MissionBook.tax_collector())
	var d: PhaseStub = s.d
	var seen := PackedStringArray()
	for phase in ["inside", "hiding", "running", "next"]:
		d.phase = phase
		seen.append(String(MissionSteps.current(s.rules)["t"]))
	t.check(seen == PackedStringArray(["Seal his door, draw guards off", "Burn the counting-house", "Kill him before the Citadel",
		"Be ready for the next collector"]), "The Tax Collector's steps follow its phases (%s)" % [seen])
	var cur := MissionSteps.current(s.rules)
	t.check(int(cur["of"]) == 5 and int(cur["index"]) == 4, "a step knows its place (%s)" % [cur])
	Kit.done(s)


# --- clarity block: escort ---
static func _advance_escort(t) -> void:
	_advance_lamb(t)


static func _advance_lamb(t) -> void:
	# Scripted phases: each step shows while the director sits in its phase, and the next one when it moves on.
	var s := _stub_world(MissionBook.lost_lamb())
	var d: PhaseStub = s.d
	var seen := PackedStringArray()
	for phase in ["", "running", "led", "caught", "gate", "clear"]:
		d.phase = phase
		seen.append(MissionSteps.line(s.rules))
	t.check(seen == PackedStringArray(["Get the acolyte to the gate", "Clear his road to the gate", "Lure him on to the west gate",
		"Stop the soldier taking him", "Draw the watch off the gate", "Send him through the gate"]), "The Lost Lamb's steps follow its phases (%s)" % [seen])
	d.phase = "unknown"
	t.check(MissionSteps.line(s.rules) == "Get the acolyte to the gate", "a phase no step names gives the default step")
	Kit.done(s)


# --- clarity block: raze ---
static func _advance_raze(t) -> void:
	_advance_harvest(t)


static func _advance_harvest(t) -> void:
	# The seconds count down, then drop once there are none.
	var s := _stub_world(MissionBook.spoiled_harvest())
	var d: PhaseStub = s.d
	d.phase = "empty"
	d.secs = 35.0
	t.check(MissionSteps.line(s.rules) == "Wait for the grain cart 0:35", "the grain cart's wait counts down (%s)" % MissionSteps.line(s.rules))
	d.secs = 0.0
	t.check(MissionSteps.line(s.rules) == "Wait for the grain cart", "with no seconds left, no count (%s)" % MissionSteps.line(s.rules))
	d.phase = ""
	t.check(MissionSteps.line(s.rules).begins_with("Clear the watchmen, burn it"), "grain in, the watchmen come first (%s)" % MissionSteps.line(s.rules))
	d.phase = "burning"
	t.check(MissionSteps.line(s.rules).begins_with("Keep it burning"), "then keep it burning (%s)" % MissionSteps.line(s.rules))
	s.rules.free_play = true
	t.check(MissionSteps.line(s.rules) == "", "free play has no task line")
	Kit.done(s)

	# The real Spoiled Harvest: the line is what the director's own phase says, and the counter is the objective's.
	s = Kit.world(MissionBook.spoiled_harvest())
	var harvest: HarvestDirector = s.d
	t.check(harvest.hint_phase() == "empty" and MissionSteps.line(s.rules).begins_with("Wait for the grain cart 1:"),
		"at its start, no grain yet: the wait (%s)" % MissionSteps.line(s.rules))
	Kit.run_for(s, 70.0)
	t.check(harvest.hint_phase() != "empty" and MissionSteps.line(s.rules).contains(" 0/3") and not MissionSteps.line(s.rules).begins_with("Wait"),
		"once its grain is in, the step moves on, with Granaries spoiled 0/3 (%s / %s)" % [harvest.hint_phase(), MissionSteps.line(s.rules)])
	Kit.done(s)


# --- clarity block: convert ---
static func _advance_convert(t) -> void:
	_advance_prayers(t)


static func _advance_prayers(t) -> void:
	# A counter read from the objective: First Prayers' believers.
	var s := Kit.world(MissionBook.first_prayers())
	t.check(MissionSteps.line(s.rules) == "Lead the poor (gold) to the well 0/3", "First Prayers: %s" % MissionSteps.line(s.rules))
	Kit.done(s)


# --- clarity block: hunt ---
static func _advance_hunt(t) -> void:
	# The hunts' steps follow the director's phase; the waits count down.
	var s := _stub_world(MissionBook.heretic_hunt())
	var d: PhaseStub = s.d
	d.phase = "waiting"
	d.secs = 35.0
	t.check(MissionSteps.line(s.rules) == "Be at the next standard (grey) 0:35", "the Heretic Hunt's wait counts down (%s)" % MissionSteps.line(s.rules))
	d.phase = "coming"
	d.secs = 20.0
	t.check(MissionSteps.line(s.rules) == "Be at the captain's road 0:20", "and the captain's: %s" % MissionSteps.line(s.rules))
	d.phase = "captain"
	t.check(MissionSteps.line(s.rules) == "Kill the captain (gold)", "then he is the target (%s)" % MissionSteps.line(s.rules))
	d.phase = "open"
	t.check(MissionSteps.line(s.rules).begins_with("Strike or rot it (gold) now"), "an open standard: strike or rot (%s)" % MissionSteps.line(s.rules))
	Kit.done(s)
	s = _stub_world(MissionBook.lantern_eye())
	d = s.d
	d.phase = "shattered"
	d.secs = 12.0
	t.check(MissionSteps.line(s.rules) == "Lead or kill the wrights (red) 0:12", "the Lantern's Eye: the wrights, counted (%s)" % MissionSteps.line(s.rules))
	d.phase = "waiting"
	d.secs = 30.0
	t.check(MissionSteps.line(s.rules) == "Be at the next mirror (grey) 0:30", "and the next mirror's wait (%s)" % MissionSteps.line(s.rules))
	Kit.done(s)
	s = _stub_world(MissionBook.break_hunt())
	d = s.d
	d.phase = "carried"
	t.check(MissionSteps.line(s.rules).begins_with("Kill or scare the new bearer"), "Break the Hunt: the new bearer (%s)" % MissionSteps.line(s.rules))
	Kit.done(s)



static func _board_world(def: MissionDef) -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := def.make_director().setup(rules, crowd, town, null)
	rules.director = director
	var descent := Descent.new().setup(def, 7)
	descent.attach(rules, director)
	rules.descent = descent
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director, "descent": descent}


static func _board_done(s: Dictionary) -> void:
	(s.descent as Descent).release()
	var rules: Rules = s.rules
	rules.teardown()
	rules.free()
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


## The line is up collapsed and expanded, under the objectives (collapsed) or the how-to-win plate (expanded), and is part of the keepout.
static func _modes(t) -> void:
	for def: MissionDef in [MissionBook.tax_collector(), MissionBook.first_prayers(), MissionBook.last_judgement()]:
		var s := Kit.world(def)
		var hud := Hud.new().setup(s.rules, s.crowd, s.town, null)
		var line := MissionSteps.line(s.rules)
		for open: bool in [false, true]:
			Hud.details = open
			hud.advance(0.0)
			var plate := hud.task_rect()
			t.check(line != "" and hud.task_text() == line and plate.has_area(), "%s, details %s: the task line is up (%s)" % [def.id, open, line])
			t.check(hud.stack_rect().encloses(plate) and hud._signature().contains(line),
				"%s, details %s: it is in the keepout and the redraw signature" % [def.id, open])
		Hud.details = false
		hud.advance(0.0)
		var under := hud.objective_panel().end.y + 4.0 if def.scored else 2.0 + 5.0 + Hud.ROW_H * float(hud.rows_shown().size()) + 4.0
		t.check(not hud.hint_shown() and is_equal_approx(hud.task_rect().position.y, under), "%s: collapsed, it sits under the objectives (%s vs %s)" % [def.id, hud.task_rect(), under])
		Hud.details = true
		hud.advance(0.0)
		t.check(hud.hint_shown() and hud.task_rect().position.y >= hud.hint_rect().end.y + 4.0, "%s: expanded, it sits under the how-to-win plate" % def.id)
		hud.free()
		Kit.done(s)
	Hud.reset_session()


## Nothing the HUD draws meets it: the slot row, the objectives, the how-to-win and wishes plates, the strip, the clock, the status line, a banner
## and Cael's plate; at 640x360 and at 960x495, collapsed and expanded, with the hint flashing.
static func _layout(t) -> void:
	for area: Vector2i in [Vector2i(640, 360), Vector2i(960, 495)]:
		UiScale.set_test_area(area)
		var view := Vector2(area)
		var bad := PackedStringArray()
		var checked := 0
		var defs: Array = [MissionBook.tax_collector(), MissionBook.spoiled_harvest(), MissionBook.sermon(), MissionBook.heart_of_faith(),
			MissionBook.last_judgement(), MissionBook.miras_house(), MissionBook.market_panic()]
		for def: MissionDef in defs:
			var s := Kit.world(def)
			var hud := Hud.new().setup(s.rules, s.crowd, s.town, null)
			hud.play_began()
			hud.push_banner("ODRAN COMES OUT")
			hud.push_subtitle("Cael: the cart is at the gate and the watchmen are looking away.")
			for open: bool in [false, true]:
				Hud.details = open
				hud.advance(0.0)
				var plate := hud.task_rect()
				var against: Array[Rect2] = [hud.objective_rect(), hud.hint_rect(), hud.wishes_rect(), hud.events_rect(view.x), hud.clock_rect(view.x),
					hud.status_rect(), hud.banner_rect(view.x), hud.subtitle_rect(view.x)]
				for i in s.rules.loadout.size():
					against.append(hud.slot_rect(i))
				if hud.ascend_shown():
					against.append(hud.ascend_rect())
				if hud.chain_shown():
					against.append(hud.chain_rect())
				checked += 1
				if not plate.has_area():
					bad.append("%s: no plate" % def.id)
					continue
				if plate.position.x < 0.0 or plate.end.x > view.x or plate.end.y >= hud.caption_top() or plate.end.y >= hud.slot_top():
					bad.append("%s (details %s): off its room %s" % [def.id, open, plate])
				for r in against:
					if r.has_area() and r.intersects(plate):
						bad.append("%s (details %s): %s meets %s" % [def.id, open, plate, r])
			hud.free()
			Kit.done(s)
		t.check(checked == defs.size() * 2 and bad.is_empty(), "%dx%d: the task line meets no plate (%d checked; %s)" % [area.x, area.y, checked, "; ".join(bad)])
		UiScale.clear_test_area()
	Hud.reset_session()
