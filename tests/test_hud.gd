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
