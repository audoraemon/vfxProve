extends RefCounted
## The HUD's words and states: the clock's format, the objective and status lines, what each slot says about
## itself, and the banner queue. The look itself is judged from captures, not from here.


const Kit := preload("res://tests/test_tier2_groundwork.gd")
const GOLD := Color("d8b23a")
const RED := Color("c8342a")


static func run(t) -> void:
	t.check(UiTheme.clock(240.0) == "4:00", "four minutes reads 4:00 (%s)" % UiTheme.clock(240.0))
	t.check(UiTheme.clock(29.4) == "0:30", "a part-second rounds up, so the clock never sits on 0:00 early (%s)" % UiTheme.clock(29.4))
	t.check(UiTheme.clock(0.0) == "0:00" and UiTheme.clock(-3.0) == "0:00", "and it floors at 0:00")
	var f := UiTheme.font()
	t.check(f != null and (f.base_font as FontFile).antialiasing == TextServer.FONT_ANTIALIASING_NONE, "the pixel font has no smoothing")

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
	Hud.details = true  # v0.11.1: these checks measure the expanded HUD, today's plates

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

	# Each slot is a card with the power's name beside its icon; since v0.08 a compact one (100 wide at six slots), and it widens when the row has
	# room, so the name fits whole: at four slots the card is as wide as the row lets it.
	t.check(hud.slot_rect(0).size.x == hud.slot_w() and hud.slot_w() > Hud.SLOT_W and hud.slot_w() <= Hud.SLOT_W_MAX
		and hud.slot_rect(0).size.y == Hud.SLOT_SIZE, "a slot is a %d x %d card, wider than the crowded %d (%s)" % [int(hud.slot_w()),
		int(Hud.SLOT_SIZE), int(Hud.SLOT_W), hud.slot_rect(0).size])
	t.check(hud.slot_name(0) == "Heaven Splitter" and hud.slot_name(3) == "Nuclear Nova" and hud.slot_name_lines(0).size() == 1,
		"and carries its power's whole name (%s, %s)" % [hud.slot_name(0), hud.slot_name(3)])
	_slot_names(t)
	# Four slots sit centred on the screen.
	t.check(is_equal_approx(hud.slot_rect(0).position.x, float(UiScale.DESIGN.x) - hud.slot_rect(3).end.x),
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

	# What the HUD sounds (the interface cues): a banner rings ui_notice as it comes on screen, not while it waits.
	UiSound.asked.clear()
	rules.banner.emit("ONE")
	rules.banner.emit("TWO")
	hud.advance(0.0)
	t.check(_heard() == "ui_notice", "a banner rings as it shows, the next waits its turn (%s)" % _heard())
	hud.advance(Hud.BANNER_SECONDS + 0.1)
	t.check(_heard() == "ui_notice,ui_notice", "and rings when its turn comes (%s)" % _heard())
	hud.advance(Hud.BANNER_SECONDS + 0.1)
	# A refused whisper's banner comes with the buzz, and rings nothing more.
	UiSound.asked.clear()
	rules.refuse(1, "nobody")
	hud.advance(0.0)
	t.check(_heard() == "ui_buzz", "a refused cast's banner only buzzes (%s)" % _heard())
	hud.advance(Hud.BANNER_SECONDS + 0.1)
	# The Divine Surge rings ui_surge, and its banner (sent straight after, as Rules does) is quiet; the next one rings.
	UiSound.asked.clear()
	rules.surged.emit()
	rules.banner.emit("DIVINE SURGE")
	rules.banner.emit("AFTER")
	hud.advance(0.0)
	hud.advance(Hud.BANNER_SECONDS + 0.1)
	t.check(_heard() == "ui_surge,ui_notice", "the surge rings once and the banner after it rings its own (%s)" % _heard())
	hud.advance(Hud.BANNER_SECONDS + 0.1)
	# Slots that come off their cooldowns on the same frame ring ui_ready once.
	UiSound.asked.clear()
	rules.recharged.emit(0)
	rules.recharged.emit(2)
	t.check(_heard() == "ui_ready", "two slots back at once ring once (%s)" % _heard())
	UiSound.asked.clear()

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
		if r.position.x < 0.0 or r.end.x > float(UiScale.DESIGN.x) or r.end.y > 360.0:
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
	_anchors_800x450(t, hud)
	_spacing_owners(t, rules, crowd, town)
	_labels_clear_of_plates(t, hud)
	_crisp_source(t)
	_spaced_hints(t)

	# The marks over people (v0.10; M5 made them bigger and outlined, so they read on the cobbles): a diamond MARK_R each
	# way from its centre.
	var shape := Hud.mark_shape(Vector2(100.0, 100.0))
	t.check(Hud.MARK_R >= 4.0 and shape.size() == 4 and shape[0] == Vector2(100.0, 100.0 - Hud.MARK_R)
		and shape[2] == Vector2(100.0, 100.0 + Hud.MARK_R) and Hud.MARK_EDGE.a > 0.5,
		"a mark is a diamond %d px each way, with a dark edge (%s)" % [int(Hud.MARK_R), shape])

	# The Warning (v0.08): the objective panel in place of the Citadel's, the messenger's marker and its edge arrow.
	_warning(t, env, field, crowd, town)
	Hud.reset_session()
	_lantern_clock(t)
	Hud.reset_session()

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
	Hud.details = true
	var rows := hud.objective_rows()
	t.check(rows == [["Stop the warning", ""], ["Dawn 2:00", ""], ["Unseen", "ok"]],
		"The Warning's panel: the warning, dawn's clock (v0.11 M1), and Unseen ticked (%s)" % [rows])
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
	_collapsed(t, hud, crowd, rules)
	director.timeline = null
	t.check(hud.event_rows() == [], "and goes with the timeline")

	hud.free()
	rules.teardown()
	rules.free()


## v0.11.1 §1: collapsed, an unscored mission shows its main objective, the strip's next event and the alarm stage; TAB brings back all.
static func _collapsed(t, hud: Hud, crowd: Crowd, rules: Rules) -> void:
	Hud.details = false
	t.check(hud.rows_shown().size() == 1 and String(hud.rows_shown()[0][0]) == "Stop the warning",
		"collapsed: the main objective row only (%s)" % [hud.rows_shown()])
	t.check(not hud.hint_shown() and hud.hint_rect() == Rect2() and hud.hint_text() != "",
		"collapsed: no how-to-win plate before play begins (the line is still there to flash)")
	t.check(hud.wishes_rect() == Rect2() and hud.wish_summary() == "", "no wishes off the board: no row, no summary")
	t.check(hud.event_rows().size() == 1 and hud.status_text() == crowd.alarms.stage_name(),
		"the strip one row, the status the stage (%s, %s)" % [hud.event_rows(), hud.status_text()])
	t.check(hud.cue_text() == Hud.MORE_TEXT and hud.cue_rect().has_area() and hud.cue_rect().end.x <= hud.objective_rect().end.x,
		"the cue reads TAB more, inside the objective plate")
	var small := hud.stack_rect()
	var short_sig := hud._signature()
	hud.toggle_details()
	t.check(Hud.details and hud.rows_shown().size() == 3 and hud.hint_shown() and hud.stack_rect().size.y > small.size.y
		and hud.event_rows().size() == 2 and hud.cue_text() == Hud.LESS_TEXT and hud.status_text().contains("Citizens"),
		"TAB: everything, and the keepout grows")
	t.check(hud._signature() != short_sig, "the redraw signature knows the key")
	hud.toggle_details()
	t.check(not Hud.details, "TAB again: collapsed")
	var tab := InputEventKey.new()
	tab.physical_keycode = KEY_TAB
	tab.pressed = true
	var tab_echo := tab.duplicate() as InputEventKey
	tab_echo.echo = true
	var tab_up := tab.duplicate() as InputEventKey
	tab_up.pressed = false
	var other_key := tab.duplicate() as InputEventKey
	other_key.physical_keycode = KEY_H
	t.check(Mission.toggles_details(tab) and not Mission.toggles_details(tab_echo) and not Mission.toggles_details(tab_up)
		and not Mission.toggles_details(other_key), "TAB pressed toggles; an echo, a release or another key does not")
	var alt_tab := tab.duplicate() as InputEventKey
	alt_tab.alt_pressed = true
	var ctrl_tab := tab.duplicate() as InputEventKey
	ctrl_tab.ctrl_pressed = true
	t.check(not Mission.toggles_details(alt_tab) and not Mission.toggles_details(ctrl_tab), "Alt+TAB and Ctrl+TAB do not")
	_flash_rules(t, hud, crowd, rules)
	Hud.reset_session()


## v0.11.1 §1.1: the how-to-win line flashes for HINT_FLASH when play begins and when its unfilled words change; a ticking {n} never does.
static func _flash_rules(t, hud: Hud, crowd: Crowd, rules: Rules) -> void:
	Hud.details = false
	hud.advance(Hud.HINT_FLASH * 3.0)
	t.check(not hud.hint_shown(), "play not begun: the line stays hidden whatever its words do")
	hud.play_began()
	t.check(hud.hint_shown() and hud.hint_rect().has_area(), "the hint flashes when play begins")
	hud.advance(Hud.HINT_FLASH - 0.5)
	t.check(hud.hint_shown(), "and holds for HINT_FLASH")
	hud.advance(0.6)
	t.check(not hud.hint_shown() and hud.hint_rect() == Rect2(), "then collapses")
	# A phase change is a new instruction: it shows itself again, collapsed (spec decision 5).
	var def: MissionDef = rules.mission
	var old_id := def.id
	var stub := _PhaseDirector.new()
	stub.rules = rules
	var old := rules.director
	rules.director = stub
	def.id = "heretic_hunt"
	stub.phase = "coming"
	stub.secs = 30.0
	hud.advance(0.1)
	t.check(hud.hint_shown() and hud.hint_text().contains("30"), "a new phase flashes the line, its seconds filled (%s)" % hud.hint_text())
	hud.advance(Hud.HINT_FLASH + 0.1)
	t.check(not hud.hint_shown(), "and it collapses again")
	stub.secs = 29.0
	hud.advance(0.1)
	t.check(not hud.hint_shown(), "a ticking {n} (the same words, new seconds) never re-flashes it")
	stub.phase = ""
	hud.advance(0.1)
	t.check(hud.hint_shown() == (hud.hint_text() != ""), "the words changing back flash again (when there are words)")
	hud.advance(Hud.HINT_FLASH + 0.1)
	# A fresh Hud reads the same session value: details is static.
	Hud.details = true
	var other := Hud.new().setup(rules, crowd, null, null)
	t.check(Hud.details and other.cue_text() == Hud.LESS_TEXT, "TAB state survives a fresh HUD (a restart or the next act)")
	other.free()
	Hud.reset_session()
	t.check(not Hud.details, "reset_session() collapses again")
	rules.director = old
	def.id = old_id


## A Lantern whose Bearer phase, tags and strip rows the test sets (Task 10 fills the real ones).
class _StubLantern extends LanternWatch:
	var phase := ""
	var rows: Array[Dictionary] = []
	var marks: Array[MapTag] = []

	func _bearer_phase() -> String:
		return phase

	func _bearer_rows() -> Array[Dictionary]:
		return rows

	func _bearer_tags() -> Array[MapTag]:
		return marks


## A Lantern with a Herald running (the phase only).
class _HeraldLantern extends LanternWatch:
	func hint_phase() -> String:
		return "herald"


## A director whose hint phase and seconds the test sets.
class _PhaseDirector extends MissionDirector:
	var phase := ""
	var secs := 0.0

	func hint_phase() -> String:
		return phase

	func hint_seconds() -> float:
		return secs


## The interface cues asked for since the test last cleared them, in order.
static func _heard() -> String:
	return ",".join(PackedStringArray(UiSound.asked))


## v0.11.2 Task 12 (spec 5.1-5.3): the Lantern on the HUD. The clock's ring and badge (collapsed or not), the Lantern's line first on the
## how-to-win plate, its tags on the map layer and its rows merged into the strip (soonest first).
static func _lantern_clock(t) -> void:
	var def := MissionBook.bell_ringers()
	def.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [HeraldObjective.new()]
		return out
	var s := Kit.world(def, MissionDirector.new())
	var rules: Rules = s.rules
	var lw := _StubLantern.new()
	lw.setup(rules, s.crowd, s.town, null, "watch")
	rules.lantern = lw
	var hud := Hud.new().setup(rules, s.crowd, s.town, null)
	Hud.details = false  # collapsed: TAB never hides the clock's ring
	t.check(hud.clock_badge() == "" and hud.clock_ring().a == 0.0, "Asleep: no badge, no ring")
	var asleep := hud._signature()
	lw.on_toll()
	t.check(hud.clock_badge() in ["x1.5", "×1.5"] and hud.clock_ring() == GOLD,
		"Stirring: the badge x1.5 and the gold ring, collapsed (%s)" % hud.clock_badge())
	t.check(hud.clock_badge().begins_with("×") == UiTheme.font().has_char(0xD7), "the multiplication sign when the font has it, else x")
	var stirring := hud._signature()
	t.check(stirring != asleep, "the stage is in the redraw signature")
	Hud.details = true
	t.check(hud.clock_badge() in ["x1.5", "×1.5"] and hud.clock_ring() == GOLD, "and expanded")
	lw.burn()
	t.check(hud.clock_badge() in ["x2.0", "×2.0"] and hud.clock_ring() == RED, "Burning: x2.0 and the red ring (%s)" % hud.clock_badge())
	t.check(hud._signature() != stirring, "Burning redraws the clock")
	lw.blind()
	t.check(hud.clock_badge() == "" and hud.clock_ring().a == 0.0, "Blind: no badge, no ring")
	# A night with no Lantern: nothing.
	rules.lantern = null
	t.check(hud.clock_badge() == "" and hud.clock_ring().a == 0.0, "no Lantern, no badge")
	rules.lantern = lw

	# The Lantern's hint comes first; "" gives the director's own line back.
	var own := MissionHints.line(def.id)
	var fresh := _StubLantern.new()
	fresh.setup(rules, s.crowd, s.town, null, "watch")
	rules.lantern = fresh
	t.check(hud.hint_key() == own and own != "", "no phase: the mission's own line")
	fresh.on_toll()
	t.check(fresh.hint_phase() == "stirring" and hud.hint_key() == MissionHints.LANTERN["stirring"], "Stirring, the Bearer not out: the stirring line")
	fresh.phase = "walking"
	t.check(fresh.hint_phase() == "bearer" and hud.hint_key() == MissionHints.LANTERN["bearer"], "the Bearer walks: the bearer line")
	fresh.burn()
	t.check(hud.hint_key() == MissionHints.LANTERN["burning"], "Burning, 8 s: the burning line beats the Bearer's")
	t.check(hud.hint_text() == MissionHints.LANTERN["burning"], "and hint_text() gives the same words")
	fresh.phase = "vigil"
	fresh.step(LanternWatch.BURN_HINT + 1.0)
	t.check(fresh.hint_phase() == "" and hud.hint_key() == own, "at the vigil, after the burning hint: the mission's own line returns")
	rules.lantern = lw

	# Ruling C17: a director's own phase line (an instant loss) outranks the Lantern's counterplay lines, not the Herald's.
	var old_dir := rules.director
	var old_id := def.id
	var pd := _PhaseDirector.new()
	rules.director = pd
	def.id = "tax_collector"
	var third := _StubLantern.new()
	third.setup(rules, s.crowd, s.town, null, "watch")
	rules.lantern = third
	third.on_toll()
	pd.phase = "running"
	t.check(third.hint_phase() == "stirring" and hud.hint_key() == String(MissionHints.LINES["tax_collector.running"]),
		"a tolled night with the collector running: his line, not the Lantern's stirring one")
	third.phase = "walking"
	t.check(hud.hint_key() == String(MissionHints.LINES["tax_collector.running"]), "... nor the Bearer's")
	third.burn()
	t.check(hud.hint_key() == String(MissionHints.LINES["tax_collector.running"]), "... nor the burning one")
	pd.phase = ""
	t.check(hud.hint_key() == MissionHints.LANTERN["burning"], "the director on its default line: the Lantern's line shows")
	pd.phase = "nowhere"
	t.check(hud.hint_key() == MissionHints.LANTERN["burning"], "a phase with no line of its own is the default one")
	var herald := _HeraldLantern.new()
	herald.setup(rules, s.crowd, s.town, null, "herald")
	rules.lantern = herald
	pd.phase = "running"
	t.check(hud.hint_key() == MissionHints.LANTERN["herald"], "a Herald running keeps the plate whatever the director says")
	rules.lantern = lw
	rules.director = old_dir
	def.id = old_id

	# The strip: the Lantern's rows merge with the timeline's, soonest first; collapsed shows the soonest only.
	var director: MissionDirector = s.d
	var timeline := EventTimeline.new()
	timeline.add(30.0, "dawn", "Dawn")
	director.timeline = timeline
	lw.rows = [{"in": 12.0, "label": "The Lantern-Bearer sets out"}]
	Hud.details = true
	t.check(hud.event_rows() == [["0:12", "The Lantern-Bearer sets out"], ["0:30", "Dawn"]],
		"a bearer row in 12 s comes before the timeline's in 30 s (%s)" % [hud.event_rows()])
	Hud.details = false
	t.check(hud.event_rows() == [["0:12", "The Lantern-Bearer sets out"]], "collapsed: only the soonest (%s)" % [hud.event_rows()])
	lw.rows = [{"in": 40.0, "label": "The Herald reaches the Temple"}]
	t.check(hud.event_rows() == [["0:30", "Dawn"]], "a later Lantern row waits behind the timeline's (%s)" % [hud.event_rows()])
	director.timeline = null
	t.check(hud.event_rows() == [["0:40", "The Herald reaches the Temple"]], "with no timeline the Lantern's rows still show (%s)" % [hud.event_rows()])
	lw.rows = [{"in": INF, "clock": "--:--", "label": "The Bearer waits for the Herald"}]
	t.check(hud.event_rows() == [["--:--", "The Bearer waits for the Herald"]], "a row with no countdown shows its own words (%s)" % [hud.event_rows()])
	director.timeline = timeline
	Hud.details = true
	t.check(hud.event_rows() == [["0:30", "Dawn"], ["--:--", "The Bearer waits for the Herald"]], "and sorts after the timed ones (%s)" % [hud.event_rows()])
	director.timeline = null
	lw.rows = []
	t.check(hud.event_rows().is_empty(), "and none when it has none")

	# Tags: the Lantern's join the map layer after the director's.
	t.check(not Hud.tags_shown(rules) and hud.all_tags().is_empty(), "no tags yet")
	lw.marks = [MapTag.person(Vector2(3.0, 4.0), GOLD, "LANTERN-BEARER - KEEPS THE VIGIL", true)]
	t.check(Hud.tags_shown(rules) and hud.all_tags().size() == 1 and hud.all_tags()[0].label == "LANTERN-BEARER - KEEPS THE VIGIL",
		"a Lantern tag is on the layer, and the layer is shown")
	hud.free()
	Kit.done(s)


## Every power's name on its card (the pixel font's spaces are wider now): the widest card shows each whole in at most two lines; the narrowest (six slots at 640)
## breaks it at its words, and trims letters only from a word that is itself wider than the room.
static func _slot_names(t) -> void:
	var was := UiTheme.word_spacing
	UiTheme.word_spacing = true
	var wide_room := Hud.SLOT_W_MAX - Hud.SLOT_SIZE - 6.0
	var not_whole := ""
	var too_wide := ""
	var cut_without_cause := ""
	for p: Dictionary in PowerBook.POWERS:
		var power_name := String(p.name)
		var lines := Hud.name_lines(power_name, wide_room)
		if " ".join(lines) != power_name or lines.size() > Hud.NAME_LINES:
			not_whole += " " + power_name
		var narrow := Hud.name_lines(power_name, Hud.NAME_ROOM)
		for l in narrow:
			if UiTheme.width(l, UiTheme.TEXT_S) > Hud.NAME_ROOM:
				too_wide += " " + power_name
		if " ".join(narrow) != power_name:
			# Cut: fair only when a word is wider than the room, or the words need more than two lines.
			var longest_word := 0.0
			for word in power_name.split(" "):
				longest_word = maxf(longest_word, UiTheme.width(word, UiTheme.TEXT_S))
			var all_lines := UiTheme.wrap(power_name, Hud.NAME_ROOM, UiTheme.TEXT_S)
			if longest_word <= Hud.NAME_ROOM and all_lines.size() <= Hud.NAME_LINES:
				cut_without_cause += " " + power_name
	UiTheme.word_spacing = was
	t.check(not_whole == "", "at the widest card every power's name is whole, in at most two lines (not:%s)" % not_whole)
	t.check(too_wide == "", "and at the narrowest no line runs past the room (wide:%s)" % too_wide)
	t.check(cut_without_cause == "", "a name is cut at the narrowest only when a word is wider than the room or it needs three lines (%s)" % cut_without_cause)


## A Hud on an 800 x 450 area (Task 5): the slot row keeps its distance from the bottom edge and its centre, the status line its margin from the
## right edge, the chain, ascend and caption plates and the arrows' frame their distance from the bottom; at 640 x 360 every rect is today's.
static func _anchors_800x450(t, hud: Hud) -> void:
	var top_now := hud.slot_rect(0).position.y
	t.check(is_equal_approx(top_now, Hud.SLOT_TOP) and is_equal_approx(hud.status_right(), 640.0 - Hud.STATUS_MARGIN),
		"at 640 x 360 the slot row and the status line are where they were (%s, %s)" % [top_now, hud.status_right()])
	var chain_y := hud.chain_rect().position.y
	var ascend_y := hud.ascend_rect().position.y
	var caption_y := hud.caption_top()
	var frame_end := Hud.tag_frame(Vector2(640.0, 360.0)).end.y
	hud.size = Vector2(800.0, 450.0)
	var last := hud.slot_rect(3)
	var bottom_gap := 360.0 - Hud.SLOT_TOP - Hud.SLOT_SIZE
	t.check(is_equal_approx(last.end.y, 450.0 - bottom_gap), "800 x 450: the slot row's bottom is the same distance from the edge (%s)" % last.end.y)
	t.check(absf((hud.slot_rect(0).position.x + last.end.x) * 0.5 - 400.0) <= 0.5, "and it is centred on x 400 (%.1f .. %.1f)" % [hud.slot_rect(0).position.x, last.end.x])
	t.check(is_equal_approx(hud.status_right(), 800.0 - Hud.STATUS_MARGIN), "the status line's right edge follows the area's (%s)" % hud.status_right())
	var dy := 90.0
	t.check(is_equal_approx(hud.chain_rect().position.y, chain_y + dy) and is_equal_approx(hud.ascend_rect().position.y, ascend_y + dy)
		and is_equal_approx(hud.caption_top(), caption_y + dy), "the chain plate, the ASCEND plate and the tour's caption keep their distance from the bottom")
	t.check(is_equal_approx(hud.ascend_rect().get_center().x, 400.0), "the ASCEND plate is centred on the area (%s)" % hud.ascend_rect())
	t.check(is_equal_approx(Hud.tag_frame(Vector2(800.0, 450.0)).end.y, frame_end + dy)
		and is_equal_approx(Hud.tag_frame(Vector2(800.0, 450.0)).end.x, 800.0 - Hud.EDGE_MARGIN), "the arrows' frame follows the area's edges")
	t.check(Hud.slot_top_in(Vector2(800.0, 450.0)) == Hud.SLOT_TOP + dy, "slot_top_in gives the same row top")
	# The top-centre blocks follow the area's middle, the status plate its right edge.
	hud.push_banner("THE BRIDGE HAS FALLEN")
	hud.push_subtitle("Venn. She lit Mira's pyre.")
	var lines := RiteBook.plate_lines(RiteBook.FIRST_TASTE)
	hud.show_rite_plate(lines)
	t.check(is_equal_approx(hud.clock_rect(800.0).get_center().x, 400.0) and absf(hud.banner_rect(800.0).get_center().x - 400.0) <= 0.5
		and absf(hud.subtitle_rect(800.0).get_center().x - 400.0) <= 0.5 and absf(hud.rite_plate_rect().get_center().x - 400.0) <= 1.0,
		"800 x 450: the clock, the banner, Cael's plate and the rite's plate are centred on x 400")
	t.check(is_equal_approx(hud.rite_plate_rect().position.y, Hud.RITE_PLATE_TOP + dy * 0.5) and is_equal_approx(hud.status_rect().end.x, 800.0 - Hud.STATUS_MARGIN + 4.0),
		"the rite's plate stays in the area's middle and the status plate keeps the right margin (%s, %s)" % [hud.rite_plate_rect(), hud.status_rect()])
	hud.show_rite_plate(PackedStringArray())
	hud.advance(10.0)
	hud.advance(10.0)
	hud.size = Vector2.ZERO


## The HUD's source names only crisp sizes: no old SIZE_ constant, and every UiTheme text/width/wrap/fit call spells its size out (the default is the 13 px one).
## The same for the other in-mission overlays.
static func _crisp_source(t) -> void:
	var bad := PackedStringArray()
	for path in ["res://src/game/ui/hud.gd", "res://src/game/ui/legend_panel.gd", "res://src/game/ui/memory_overlay.gd", "res://src/game/ui/behaviour_overlay.gd",
			"res://src/game/ui/zoom_readout.gd", "res://src/game/ui/fps_meter.gd"]:
		bad.append_array(uncrisp_calls(FileAccess.get_file_as_string(path), path.get_file()))
	t.check(bad.is_empty(), "the HUD and its overlays use only TEXT_S/L sizes, every call naming its own (%s)" % ", ".join(bad))
	# The lint sees what it should: the old way of writing it is caught.
	t.check(uncrisp_calls("UiTheme.text(self, at, s, UiTheme.SIZE_BODY)", "x").size() == 2
		and uncrisp_calls("UiTheme.width(s)", "x").size() == 1 and uncrisp_calls("UiTheme.wrap(s, 10.0)", "x").size() == 1
		and uncrisp_calls("UiTheme.fit(s, 10.0)", "x").size() == 1 and uncrisp_calls("UiTheme.text(self, at, s, 13)", "x").size() == 1
		and uncrisp_calls("UiTheme.text(self, at, s, UiTheme.TEXT_S, col)", "x").is_empty()
		and uncrisp_calls("UiTheme.width(s, UiTheme.TEXT_L)", "x").is_empty(), "the lint catches a left-out or an old size")


## The arguments of every UiTheme.text/width/wrap/fit call in `src` that do not name a crisp size, as "file:call". A size held in `size_px` or
## returned by banner_size() is trusted by name: both only ever give TEXT_L or TEXT_S (a known gap of this lint).
static func uncrisp_calls(code: String, file: String) -> PackedStringArray:
	var out := PackedStringArray()
	var kept := PackedStringArray()
	for line in code.split("\n"):
		var cut := line.find("#")
		while cut >= 0 and line.left(cut).count("\"") % 2 == 1:
			cut = line.find("#", cut + 1)
		kept.append(line if cut < 0 else line.left(cut))
	var src := "\n".join(kept)
	var needs := {"text": 3, "width": 1, "wrap": 2, "fit": 2}  # the index of the size argument
	for fn: String in needs:
		var marker := "UiTheme.%s(" % fn
		var at := src.find(marker)
		while at >= 0:
			var args := _args(src, at + marker.length())
			var idx: int = needs[fn]
			if args.size() <= idx or not (args[idx].contains("TEXT_") or args[idx] == "size_px" or args[idx].begins_with("banner_size(")):
				out.append("%s:%s" % [file, marker + ",".join(args).left(30)])
			at = src.find(marker, at + marker.length())
	if src.contains("UiTheme.SIZE_"):
		out.append("%s:SIZE_" % file)
	return out


## The top-level arguments of a call whose "(" has just been passed at `from`.
static func _args(src: String, from: int) -> PackedStringArray:
	var out := PackedStringArray()
	var depth := 0
	var cur := ""
	var i := from
	while i < src.length():
		var c := src[i]
		if c == "(" or c == "[":
			depth += 1
		elif c == ")" or c == "]":
			if depth == 0:
				break
			depth -= 1
		elif c == "," and depth == 0:
			out.append(cur.strip_edges())
			cur = ""
			i += 1
			continue
		cur += c
		i += 1
	if cur.strip_edges() != "":
		out.append(cur.strip_edges())
	return out


## With the wider spaces on (the HUD turns them on), every how-to-win line still fits the plate's lines.
static func _spaced_hints(t) -> void:
	var was := UiTheme.word_spacing
	UiTheme.word_spacing = true
	var long := PackedStringArray()
	for key: String in MissionHints.LINES:
		if UiTheme.wrap(String(MissionHints.LINES[key]), Hud.HINT_W, UiTheme.TEXT_S).size() > Hud.HINT_LINES:
			long.append(key)
	for phase: String in MissionHints.LANTERN:
		if UiTheme.wrap(String(MissionHints.LANTERN[phase]), Hud.HINT_W, UiTheme.TEXT_S).size() > Hud.HINT_LINES:
			long.append("lantern." + phase)
	for line in [MissionHints.WISHES_LINE, MissionHints.ASCEND_LINE]:
		if UiTheme.wrap(line, Hud.HINT_W, UiTheme.TEXT_S).size() > Hud.HINT_LINES:
			long.append(line.left(20))
	# The strip never starts left of EVENTS_LEFT_MIN, so no hint plate (2 + its width) runs under it.
	var under := PackedStringArray()
	var every: Array[String] = [MissionHints.WISHES_LINE, MissionHints.ASCEND_LINE]
	for key: String in MissionHints.LINES:
		every.append(String(MissionHints.LINES[key]))
	for phase: String in MissionHints.LANTERN:
		every.append(String(MissionHints.LANTERN[phase]))
	for line in every:
		if 2.0 + Hud.hint_width(Hud.hint_lines(line)) > Hud.EVENTS_LEFT_MIN:
			under.append(line.left(20))
	UiTheme.word_spacing = was
	t.check(under.is_empty(), "the how-to-win plate ends before the events strip's least left edge (%s)" % ", ".join(under))
	t.check(long.is_empty(), "with the wider spaces on, every how-to-win line fits %d lines of %d px (too long: %s)" % [Hud.HINT_LINES, int(Hud.HINT_W), ", ".join(long)])


## The HUD holds the wider spaces as one owner among others (Task 5 fix round): a new Hud set up and the old one freed (a multi-act night) leaves them on, a second
## owner (the skill tree) coming and going never clears the HUD's, and one owner acquiring twice still releases once.
static func _spacing_owners(t, rules: Rules, crowd: Crowd, town: Town) -> void:
	var a := Hud.new().setup(rules, crowd, town, null)
	t.check(UiTheme.word_spacing, "a HUD set up turns the wider spaces on")
	var b := Hud.new().setup(rules, crowd, town, null)  # the next act's, built before the old one is freed
	a.free()
	t.check(UiTheme.word_spacing, "the old HUD freed under the new one: the spaces stay on")
	var tree := Node.new()  # stands in for the skill tree
	UiTheme.spacing_acquire(tree)
	UiTheme.spacing_acquire(tree)
	UiTheme.spacing_release(tree)
	t.check(UiTheme.word_spacing, "a tree opening and closing over a HUD does not clear its spaces (a double acquire counts once)")
	tree.free()
	b.free()
	t.check(UiTheme.word_spacing, "and the first HUD of the test, still alive, holds them")


## No tag label sits under the clock, the status plate, a banner's bar or Cael's plate: tag_layout() is given them as taken plates.
static func _labels_clear_of_plates(t, hud: Hud) -> void:
	hud.push_banner("THE BRIDGE HAS FALLEN")
	hud.push_subtitle("Venn. She lit Mira's pyre.")
	var plates := hud.overlay_rects()
	t.check(plates.size() == 4 and plates.has(hud.banner_rect(640.0)) and plates.has(hud.subtitle_rect(640.0)) and plates.has(hud.clock_rect(640.0))
		and plates.has(hud.status_rect()), "the clock, the status, the banner and Cael's plates are the HUD's overlay plates (%d)" % plates.size())
	var tags: Array[MapTag] = []
	for p in [hud.banner_rect(640.0).get_center() + Vector2(0.0, 26.0), hud.subtitle_rect(640.0).get_center() + Vector2(0.0, 30.0), Vector2(320.0, 40.0)]:
		tags.append(MapTag.person(Iso.screen_to_ground(p), GOLD, "TAX COLLECTOR - INSIDE", true))
	var layout := Hud.tag_layout(tags, Transform2D.IDENTITY, Vector2(640.0, 360.0), Rect2(), plates)
	var bad := 0
	for e: Dictionary in layout:
		if bool(e.show):
			for r in plates:
				if (e.label as Rect2).intersects(r):
					bad += 1
	t.check(bad == 0, "with a banner and Cael's line up, no tag label that shows lies under a plate (%d)" % bad)
	hud.advance(10.0)
	hud.advance(10.0)
