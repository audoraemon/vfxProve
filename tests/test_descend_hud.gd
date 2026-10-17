extends RefCounted
## v0.11 M1 the mission HUD on the board (spec §5.1-§5.2, §6): the wishes' rows under the how-to-win plate; THE NIGHT IS
## YOURS, the ASCEND plate above the slots and the hint switching to the wishes or the ascent; the wishes' tags after the
## director's; a waiting wish's tag answers a click; the ascent's light; the Tier 5 Gaze readable while the rite shows
## (review focus 1).

const DT := 0.05


static func run(t) -> void:
	_rows(t)
	_ascend(t)
	_tags(t)
	_rise(t)
	_gaze_display(t)
	_intro_display(t)
	_collapsed_board(t)
	Hud.reset_session()


static func _world(def: MissionDef) -> Dictionary:
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
	var hud := Hud.new().setup(rules, crowd, town, null)
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director,
		"descent": descent, "hud": hud}


static func _done(s: Dictionary) -> void:
	(s.hud as Hud).free()
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


static func _stop_all(s: Dictionary) -> void:
	for w in (s.d as StarfallDirector).stars:
		w.warning_dead = true
	(s.rules as Rules).advance(DT)


static func _rows(t) -> void:
	Hud.details = true  # the expanded rows, as v0.11 drew them (v0.11.1: collapsed is the default)
	var s := _world(TierBook.board("warning"))
	var hud: Hud = s.hud
	var d: Descent = s.descent
	var rows := hud.wish_rows()
	t.check(rows.size() == d.wishes.size() and rows.size() == 2 and String(rows[0][1]) == "open"
		and String(rows[0][0]) == d.wishes[0].hud_text(s.rules), "the wishes heard, each a row, open (%s)" % [rows])
	d.wishes[0].status = Objective.Status.DONE
	d.wishes[1].status = Objective.Status.FAILED
	t.check(String(hud.wish_rows()[0][1]) == "granted" and String(hud.wish_rows()[1][1]) == "failed", "granted ticks, failed crosses")
	t.check(hud.wishes_top() >= hud.hint_rect().end.y, "under the how-to-win plate")
	var before := hud._signature()
	hud.praying = true
	t.check(hud._signature() != before, "the prayers plate going up redraws the HUD")
	_done(s)


static func _ascend(t) -> void:
	Hud.details = true
	var s := _world(TierBook.board("warning"))
	var hud: Hud = s.hud
	var rules: Rules = s.rules
	t.check(not hud.ascend_shown() and hud.hint_text() == MissionHints.line("warning", (s.d as StarfallDirector).hint_phase()),
		"no ASCEND before the main objective (review focus 4); the mission's own hint")
	_stop_all(s)
	var r := hud.ascend_rect()
	t.check(hud.ascend_shown() and is_equal_approx(r.get_center().x, 320.0) and r.end.y <= Hud.SLOT_TOP - Hud.PLATE_H - 3.0,
		"main objective done: the ASCEND plate, centred above the slots and their modes (%s)" % r)
	t.check(hud.hint_text() == MissionHints.WISHES_LINE, "the hint turns to the wishes still open")
	for w in (s.descent as Descent).wishes:
		w.status = Objective.Status.FAILED
	t.check(hud.hint_text() == MissionHints.ASCEND_LINE, "with none open, to the ascent")
	var fits := Hud.hint_lines(MissionHints.WISHES_LINE).size() <= Hud.HINT_LINES and Hud.hint_lines(MissionHints.ASCEND_LINE).size() == 1
	t.check(fits, "both fit the plate")
	rules.ascend()
	t.check(not hud.ascend_shown(), "ascended: the plate goes")
	_done(s)


static func _tags(t) -> void:
	var s := _world(TierBook.board("warning"))
	var hud: Hud = s.hud
	var all := hud.all_tags()
	var own := (s.d as StarfallDirector).tags()
	t.check(all.size() == own.size() + (s.descent as Descent).tags().size() and all.back().color == Wish.COLOR
		and all[0].label == own[0].label, "the director's tags first, then the wishes' in blue")
	var rescue := RescueWish.new()
	for d in WishBook.pool():
		if d.id == "child":
			rescue.def = d
	var r := RandomNumberGenerator.new()
	r.seed = 3
	rescue.choose(s.crowd, s.town, r, [])
	# The wisher and the soldier stood well away, so only the child's tag is under the clicks below.
	rescue.wisher.ground_pos = rescue.child.ground_pos + Vector2(10.0, 0.0)
	rescue.soldier.ground_pos = rescue.child.ground_pos + Vector2(0.0, 10.0)
	(s.descent as Descent).wishes.assign([rescue])
	var child_tag := rescue.tags()[0]
	var at := Hud.tag_point(child_tag, Transform2D.IDENTITY)
	t.check(hud.wish_at(at) == 0 and hud.wish_at(at + Vector2(Hud.ENGAGE_PX + 3.0, 0.0)) == -1,
		"a click on the waiting wish's tag finds it; one beside it does not")
	rescue.engage()
	t.check(hud.wish_at(at) == -1, "engaged, it answers no more clicks")
	var bare := MissionDirector.new()
	(s.rules as Rules).director = bare
	(s.descent as Descent).wishes.clear()
	t.check(not Hud.tags_shown(s.rules), "nothing tagged: nothing shown")
	(s.rules as Rules).director = s.d
	_done(s)


static func _rise(t) -> void:
	var s := _world(TierBook.board("warning"))
	var hud: Hud = s.hud
	t.check(not hud.rising(), "no light before the ascent")
	hud.rise(Vector2(2.0, 3.0))
	t.check(hud.rising(), "the ascent's light rises")
	hud.advance(Hud.RISE_SECONDS + 0.1)
	t.check(not hud.rising(), "and is gone after its two seconds")
	_done(s)


## v0.11.1 §1.1: collapsed, the wishes are one summary row (never none), and a scored panel is shorter, without its legend row.
static func _collapsed_board(t) -> void:
	Hud.details = false
	var s := _world(TierBook.board("warning"))
	var hud: Hud = s.hud
	var d: Descent = s.descent
	t.check(hud.wish_summary() == "Wishes: 0 of 2 granted" and hud.wish_rows_shown().size() == 1
		and hud.wishes_rect().size.y == 5.0 + Hud.ROW_H, "collapsed: one wish row (%s)" % hud.wish_summary())
	d.wishes[0].status = Objective.Status.DONE
	d.wishes[1].status = Objective.Status.FAILED
	t.check(hud.wish_summary() == "Wishes: 1 of 2 granted", "a failed wish still counts in the N (%s)" % hud.wish_summary())
	t.check(hud.wish_rows().size() == 2, "the prayers' plate still has every wish")
	var small := hud.stack_rect()
	hud.toggle_details()
	t.check(hud.wish_rows_shown().size() == 2 and hud.stack_rect().size.y > small.size.y, "TAB: every wish row, and the keepout grows")
	Hud.details = false
	_done(s)
	var j := _world(TierBook.board("last_judgement"))
	var jh: Hud = j.hud
	t.check(jh.objective_panel().size.y == 46.0 and jh.objective_rect() == Hud.OBJECTIVE_PANEL_SHORT,
		"a scored panel collapsed: shorter, no legend row")
	t.check(jh.objective_panel().encloses(jh.cue_rect()) and jh.cue_rect().has_area(), "its cue sits on the Escaped line, inside the panel")
	t.check(jh.hint_top() == Hud.OBJECTIVE_PANEL_SHORT.end.y + 4.0 and not jh.hint_shown(), "the hint (hidden until play) starts under it")
	var short_keepout := jh.stack_rect()
	Hud.details = true
	t.check(jh.objective_panel() == Hud.OBJECTIVE_PANEL and jh.cue_text() == Hud.LESS_TEXT and jh.hint_shown()
		and jh.stack_rect().size.y > short_keepout.size.y, "expanded: today's panel and the plate, the keepout grown")
	Hud.details = false
	_done(j)


static func _gaze_display(t) -> void:
	var s := _world(TierBook.board("last_judgement"))
	var hud: Hud = s.hud
	var crowd: Crowd = s.crowd
	t.check(hud.gaze_bar_shown() and hud.gaze_readout() == "Gaze 0%", "Tier 5: the Gaze bar, and its readout in the panel")
	crowd.rite.state = BanishingRite.State.GATHERING
	t.check(hud.rite_text() != "" and not hud.gaze_bar_shown() and hud.gaze_readout() == "Gaze 0%",
		"the rite gathering takes the bar's place; the panel still reads the Gaze (review focus 1)")
	crowd.rite.state = BanishingRite.State.ENDED
	_done(s)
	var plain := _world(TierBook.board("warning"))
	t.check(not (plain.hud as Hud).gaze_bar_shown() and (plain.hud as Hud).gaze_readout() == "", "no Gaze below Tier 5")
	_done(plain)


## v0.11.1 (spec §2): during the intro the HUD is the clock, the slots and one message -- no objective stack, so its keepout is empty
## and the tags spread into the corner; the prayers plate is its own message and shows only when `praying` is.
static func _intro_display(t) -> void:
	var s := _world(TierBook.board("warning"))
	var hud: Hud = s.hud
	t.check(not hud.intro and hud.stack_rect().has_area(), "play: the stack is drawn and measured")
	var before := hud._signature()
	hud.intro = true
	t.check(hud.stack_rect() == Rect2(), "the intro: no stack, so no keepout")
	t.check(hud._signature() != before, "the intro landing redraws the HUD")
	t.check(not hud.praying, "the prayers wait for their own hold")
	hud.intro = false
	t.check(hud.stack_rect().has_area(), "and the stack is back once the intro lands")
	_done(s)
