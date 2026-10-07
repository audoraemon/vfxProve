extends RefCounted
## The HUD's words and states: the clock's format, the objective and status lines, what each slot says about
## itself, and the banner queue. The look itself is judged from captures, not from here.


static func run(t) -> void:
	t.check(UiTheme.clock(240.0) == "4:00", "four minutes reads 4:00 (%s)" % UiTheme.clock(240.0))
	t.check(UiTheme.clock(29.4) == "0:30", "a part-second rounds up, so the clock never sits on 0:00 early (%s)" % UiTheme.clock(29.4))
	t.check(UiTheme.clock(0.0) == "0:00" and UiTheme.clock(-3.0) == "0:00", "and it floors at 0:00")
	var f := UiTheme.font()
	t.check(f != null and f.antialiasing == TextServer.FONT_ANTIALIASING_NONE, "the pixel font has no smoothing")

	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()
	var rules := Rules.new().setup(PackedStringArray(["heaven", "tsunami", "cinder", "nova"]), null, env, field,
		crowd, town)
	rules.caster = func(_script: GDScript, _ground: Vector2, _extra: Dictionary) -> FxTimeline:
		return null
	var aim := Targeting.new().setup(rules, crowd)
	var hud := Hud.new().setup(rules, crowd, town, aim)

	t.check(hud.objective_text().contains("Royal Citadel") and hud.objective_text().contains("100%"),
		"the objective names the Citadel and what is left of it (%s)" % hud.objective_text())
	# How to win (v0.10 M6): Last Judgement's line, under its objective panel.
	t.check(hud.hint_text() == MissionHints.line(MissionBook.LAST_JUDGEMENT) and hud.hint_text() != ""
		and hud.hint_top() == Hud.OBJECTIVE_PANEL.end.y + 4.0, "the how-to-win line, under the objectives (%s)" % hud.hint_text())
	t.check(hud.status_text().contains(str(Crowd.CITIZENS)) and hud.status_text().contains(str(Crowd.SOLDIERS)),
		"the status line counts the living (%s)" % hud.status_text())
	# The five-colour bar has a legend, and the figures top right wear the colour of the part they drive.
	t.check(Hud.LEGEND.size() == 5 and Hud.LEGEND[3][1] == 3, "the stability bar has a five-entry legend in part order")
	var segs := hud.status_segments()
	t.check(segs[0][1] == UiTheme.STABILITY_COLS[0] and segs[1][1] == UiTheme.STABILITY_COLS[3] and segs[2][1] == UiTheme.STABILITY_COLS[1],
		"citizens are Population's colour, soldiers Military's, destroyed Infrastructure's")

	# A slot says what it can do: ready, on cooldown, or waiting for the power now playing (v0.08: never "dp").
	aim.pick(0)
	t.check(hud.is_picked(0) and hud.slot_state(0) == "ready",
		"the picked slot is known as picked and still reports what it can do (%s)" % hud.slot_state(0))
	t.check(hud.slot_state(3) == "ready", "a slot nothing has fired is ready (%s)" % hud.slot_state(3))
	rules.cast(3, Vector2.ZERO)
	t.check(hud.slot_state(3) == "cooldown", "one that just fired is on cooldown (%s)" % hud.slot_state(3))
	t.check(hud.slot_state(2) == "ready", "and the others are still ready: nothing is spent (%s)" % hud.slot_state(2))
	var playing := FxTimeline.new()
	playing.duration = 8.0
	rules._playing = playing
	t.check(hud.slot_state(2) == "busy" and hud.slot_state(3) == "cooldown",
		"while a power plays, a ready slot waits for it and a cooling one still shows its cooldown (%s, %s)"
		% [hud.slot_state(2), hud.slot_state(3)])

	# A refused cast flashes its own slot red (the buzz that goes with it is milestone 5's).
	rules.cast(2, Vector2.ZERO)
	t.check(hud.flashing(2) and not hud.flashing(1), "a refused cast flashes its slot (%s)" % hud.flashing(2))
	hud.advance(Hud.FLASH_SECONDS + 0.1)
	t.check(not hud.flashing(2), "and the flash fades")
	rules._playing = null
	playing.free()

	# The slots answer to the mouse (spec §1: "keys 1-4 or click its slot").
	t.check(hud.slot_at(hud.slot_rect(2).get_center()) == 2, "a point on the third slot is the third slot")
	t.check(hud.slot_at(Vector2(4.0, 200.0)) == -1, "and a point on the town is no slot")

	# Each slot is a card with the power's name beside its icon (the user's second playtest); since v0.08 a compact
	# one, the name on one line cut to fit.
	t.check(hud.slot_rect(0).size.x == Hud.SLOT_W and hud.slot_rect(0).size.y == Hud.SLOT_SIZE,
		"a slot is a %d x %d card (%s)" % [int(Hud.SLOT_W), int(Hud.SLOT_SIZE), hud.slot_rect(0).size])
	t.check(hud.slot_name(0) == UiTheme.fit("Heaven Splitter", Hud.NAME_ROOM) and hud.slot_name(0).begins_with("Heaven")
		and hud.slot_name(3).begins_with("Nuclear"), "and carries its power's name (%s, %s)" % [hud.slot_name(0), hud.slot_name(3)])
	var too_long := ""
	for p: Dictionary in PowerBook.POWERS:
		var cut := UiTheme.fit(String(p.name), Hud.NAME_ROOM)
		if cut.length() < 3 or UiTheme.width(cut, UiTheme.SIZE_SMALL) > Hud.NAME_ROOM:
			too_long += " " + String(p.name)
	t.check(too_long == "", "every power's name fits a card on one line (too long:%s)" % too_long)
	# Four slots sit centred on the screen.
	t.check(is_equal_approx(hud.slot_rect(0).position.x, Hud.SCREEN_W - hud.slot_rect(3).end.x),
		"four slots are centred (%.0f .. %.0f)" % [hud.slot_rect(0).position.x, hud.slot_rect(3).end.x])

	# Banners queue up, show for their time and go.
	rules.banner.emit("CHAIN!")
	t.check(hud.banners().size() == 1 and hud.banners()[0] == "CHAIN!", "a banner from the rules is shown (%s)" % [hud.banners()])
	rules.banner.emit("THE BRIDGE HAS FALLEN")
	t.check(hud.banners().size() == 2, "and they queue rather than replace (%d)" % hud.banners().size())
	hud.advance(Hud.BANNER_SECONDS + 0.1)
	t.check(hud.banners().size() == 1, "the first one goes when its time is up (%d)" % hud.banners().size())
	hud.advance(Hud.BANNER_SECONDS + 0.1)
	t.check(hud.banners().is_empty(), "and so does the last (%d)" % hud.banners().size())
	# A Mind Whisper pressed on nobody (v0.08): the slot flashes and the banner says why.
	rules.refuse(1, "nobody")
	t.check(hud.flashing(1) and hud.banners() == PackedStringArray(["NO ONE TO WHISPER TO"]),
		"a whisper at nobody flashes its slot and says so (%s)" % [hud.banners()])
	hud.advance(Hud.BANNER_SECONDS + 0.1)
	# And at someone still shaking the last one off (v0.08.1): a banner of its own.
	rules.refuse(1, "shaken")
	t.check(hud.flashing(1) and hud.banners() == PackedStringArray(["THEY SHAKE OFF THE WHISPER"]),
		"a whisper at someone shaken flashes its slot and says so (%s)" % [hud.banners()])
	hud.advance(Hud.BANNER_SECONDS + 0.1)

	# Cael's lines (v0.10 M5): a queue of their own beside the banners, each up SUBTITLE_SECONDS in turn (review focus 1:
	# two close together and a banner with them -- none lost, none cut short, the banners at their own pace).
	rules.banner.emit("THE INQUISITOR SEARCHES")
	rules.subtitle.emit("Venn. She lit Mira's pyre.")
	rules.subtitle.emit("They're burning her again. Get them out.")
	t.check(hud.banners().size() == 1 and hud.subtitles() == PackedStringArray(["Venn. She lit Mira's pyre.",
		"They're burning her again. Get them out."]), "a line shows beside its banner, the next waits (%s)" % [hud.subtitles()])
	hud.advance(Hud.BANNER_SECONDS + 0.1)
	t.check(hud.banners().is_empty() and hud.subtitles().size() == 2, "a line outlasts its banner")
	hud.advance(Hud.SUBTITLE_SECONDS - Hud.BANNER_SECONDS)
	t.check(hud.subtitles() == PackedStringArray(["They're burning her again. Get them out."]),
		"then gives way to the next (%s)" % [hud.subtitles()])
	hud.advance(Hud.SUBTITLE_SECONDS - 0.1)
	t.check(hud.subtitles().size() == 1, "which lost none of its own time waiting")
	hud.advance(0.2)
	t.check(hud.subtitles().is_empty(), "and goes when its time is up")
	t.check(Hud.SUBTITLE_SECONDS > Hud.BANNER_SECONDS, "a line, a sentence to read, stays longer than a banner")
	# Its words fade with their plate, shadow and all (v0.10 M5 final review): a label's black shadow is COL_SHADOW as
	# drawn everywhere, scaled by the fade the line is drawn with -- else a bare black copy of the words shows before the
	# plate is up and stays after it has gone.
	t.check(UiTheme.shadow_color() == UiTheme.COL_SHADOW and UiTheme.shadow_color(1.0) == UiTheme.COL_SHADOW,
		"a label's shadow is COL_SHADOW unless it is told to fade")
	var faded := UiTheme.shadow_color(0.4)
	t.check(UiTheme.shadow_color(0.0).a == 0.0 and is_equal_approx(faded.a, UiTheme.COL_SHADOW.a * 0.4)
		and faded.r == UiTheme.COL_SHADOW.r and faded.g == UiTheme.COL_SHADOW.g and faded.b == UiTheme.COL_SHADOW.b,
		"and a faded one is the same black, less opaque, gone with the words (%s)" % faded)

	# Six powers (v0.08): six compact slots across the 640-px screen, none touching, each found by the mouse.
	var six_rules := Rules.new().setup(PackedStringArray(["doom", "heaven", "wisp", "thorns", "discord", "blight"]), null,
		env, field, crowd, town)
	var six := Hud.new().setup(six_rules, crowd, town, null)
	var six_bad := 0
	for i in 6:
		var r := six.slot_rect(i)
		if r.position.x < 0.0 or r.end.x > Hud.SCREEN_W or r.end.y > 360.0:
			six_bad += 100
		if i > 0 and r.intersects(six.slot_rect(i - 1)):
			six_bad += 10
		if six.slot_at(r.get_center()) != i:
			six_bad += 1
	t.check(six_bad == 0 and six.slot_rect(5).end.x - six.slot_rect(0).position.x == 620.0,
		"six slots make a 620-px row inside the screen, none touching, each under the mouse (%d, %.0f .. %.0f)"
		% [six_bad, six.slot_rect(0).position.x, six.slot_rect(5).end.x])
	six.free()
	six_rules.free()

	# The marks over people (v0.10; M5 made them bigger and outlined, so they read on the cobbles): a diamond MARK_R each
	# way from its centre.
	var shape := Hud.mark_shape(Vector2(100.0, 100.0))
	t.check(Hud.MARK_R >= 4.0 and shape.size() == 4 and shape[0] == Vector2(100.0, 100.0 - Hud.MARK_R)
		and shape[2] == Vector2(100.0, 100.0 + Hud.MARK_R) and Hud.MARK_EDGE.a > 0.5,
		"a mark is a diamond %d px each way, with a dark edge (%s)" % [int(Hud.MARK_R), shape])

	# The Warning (v0.08): the objective panel in place of the Citadel's, the messenger's marker and its edge arrow.
	_warning(t, env, field, crowd, town)

	hud.free()
	aim.free()
	rules.free()
	crowd.clear()
	field.clear()
	field.free()
	env.clear()
	env.free()
	town.free()
	crowd.free()
	world.free()


static func _warning(t, env: EnvironmentField, field: EnemyField, crowd: Crowd, town: Town) -> void:
	var def := MissionBook.warning()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := (def.director.new() as MissionDirector).setup(rules, crowd, town, null) as WarningDirector
	rules.director = director
	var hud := Hud.new().setup(rules, crowd, town, null)
	var rows := hud.objective_rows()
	t.check(rows == [["Stop the warning", ""], ["Omen fades 2:00", ""], ["Unseen", "ok"]],
		"The Warning's panel: the warning, the omen's clock, and Unseen ticked (%s)" % [rows])
	for i in AlarmManager.LOCAL_EVENTS:
		crowd.alarms.incident(TownLayout.MARKET_SQUARE.get_center())
	crowd.alarms.update(crowd.alarm, 0, 0.0)
	t.check(hud.objective_rows()[2] == ["Unseen", "x"], "and Unseen crossed after Local Emergency (%s)" % [hud.objective_rows()])
	crowd.alarms.reset()

	# Board tags: the messenger is a tag, pointed at from the edge (in place of v0.08's marker), and the HUD follows it.
	var first: MapTag = director.tags()[0] if not director.tags().is_empty() else null
	t.check(director.messenger != null and Hud.tags_shown(rules) and first != null and first.edge
		and first.at == director.messenger.ground_pos, "the messenger is tagged first, and pointed at")
	var messenger := director.messenger
	director.messenger = null
	t.check(not Hud.tags_shown(rules), "and nothing is tagged with no messenger")
	director.messenger = messenger

	# The event strip (v0.09): the next two timed events and their clocks; nothing with no timeline.
	t.check(director.timeline == null and hud.event_rows() == [], "a mission with no timeline has no event strip (%s)" % [hud.event_rows()])
	var timeline := EventTimeline.new()
	timeline.add(45.0, "bonfire", "The bonfire lights").add(90.0, "bell", "The bell tolls").add(150.0, "dawn", "Dawn")
	director.timeline = timeline
	timeline.step(10.0)
	t.check(hud.event_rows() == [["0:35", "The bonfire lights"], ["1:20", "The bell tolls"]],
		"the strip shows the next two events with their clocks (%s)" % [hud.event_rows()])
	timeline.step(40.0)
	t.check(hud.event_rows() == [["0:40", "The bell tolls"], ["1:40", "Dawn"]],
		"and moves on as they fire (%s)" % [hud.event_rows()])
	var before := hud._signature()
	timeline.step(1.0)
	t.check(hud._signature() != before, "the strip is in the redraw signature")
	director.timeline = null
	t.check(hud.event_rows() == [], "and goes with the timeline")

	hud.free()
	rules.teardown()
	rules.free()
