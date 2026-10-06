extends RefCounted
## v0.10 M6 the intro's tour (spec §5): IntroTour's timeline -- a move to each stop, a hold under its caption, a move on to
## where play begins, the zoom coming in over the first move, skip() landing it; Mission.skips_tour() takes Space, Enter
## and a left click, and nothing else (review focus 4); each Night 2 director's stops, a stop with no one to show left
## out (review focus 3); the HUD's caption.

const A := Vector2(0.0, 0.0)
const B := Vector2(10.0, 0.0)
const C := Vector2(10.0, 10.0)
const D := Vector2(0.0, 10.0)


static func run(t) -> void:
	_timeline(t)
	_skips(t)
	_raised(t)
	_stops(t)


static func _timeline(t) -> void:
	var tour := IntroTour.new().setup(A, [[B, "one"], [C, "two"]], D)
	var move := IntroTour.MOVE_SECONDS
	var hold := IntroTour.HOLD_SECONDS
	t.near(tour.seconds(), 3.0 * move + 2.0 * hold, 0.001, "three moves and two holds")
	t.check(tour.camera() == A and tour.caption() == "one" and tour.zoom_k() == 0.0 and not tour.done(),
		"it opens where the intro starts, on its way to the first stop, under its caption")
	tour.step(move * 0.5)
	t.check(tour.camera().x > 0.0 and tour.camera().x < 10.0 and tour.zoom_k() > 0.0 and tour.zoom_k() < 1.0,
		"half way there, zooming in (%s)" % tour.camera())
	tour.step(move * 0.5 + hold * 0.5)
	t.check(tour.camera() == B and tour.caption() == "one" and tour.zoom_k() == 1.0, "holding at the first stop")
	tour.step(hold * 0.5 + move + 0.01)
	t.check(tour.camera().distance_to(C) < 0.01 and tour.caption() == "two", "then at the second, under its caption")
	tour.step(hold)
	t.check(tour.caption() == "" and not tour.done(), "on the way to play: no caption")
	tour.step(move)
	t.check(tour.done() and tour.camera() == D, "it ends where play begins")
	tour.step(5.0)
	t.check(tour.done() and tour.camera() == D, "and stays there")
	var skipped := IntroTour.new().setup(A, [[B, "one"]], D)
	skipped.skip()
	t.check(skipped.done() and skipped.camera() == D and skipped.caption() == "", "skip() lands it at once")
	t.near(IntroTour.new().setup(A, [], D).seconds(), move, 0.001, "with no stops it is one move")


static func _key(code: Key, pressed := true, echo := false) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = pressed
	e.echo = echo
	return e


static func _button(index: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = index
	e.pressed = true
	return e


static func _skips(t) -> void:
	t.check(Mission.skips_tour(_key(KEY_SPACE)) and Mission.skips_tour(_key(KEY_ENTER))
		and Mission.skips_tour(_key(KEY_KP_ENTER)) and Mission.skips_tour(_button(MOUSE_BUTTON_LEFT)),
		"Space, Enter and a left click skip the tour")
	t.check(not Mission.skips_tour(_key(KEY_SPACE, true, true)) and not Mission.skips_tour(_key(KEY_SPACE, false))
		and not Mission.skips_tour(_key(KEY_ESCAPE)) and not Mission.skips_tour(_key(KEY_1))
		and not Mission.skips_tour(_button(MOUSE_BUTTON_RIGHT)) and not Mission.skips_tour(_button(MOUSE_BUTTON_WHEEL_UP))
		and not Mission.skips_tour(InputEventMouseMotion.new()),
		"a held key, a release, Esc, a slot's key, the right button, the wheel and a move do not (review focus 4)")


## The tour looks above each stop (v0.10 M6): raised by TOUR_RAISE screen pixels at play zoom, its caption kept.
static func _raised(t) -> void:
	var stops := Mission.raised([[B, "one"], [C, "two"]])
	var up := Iso.ground_to_screen(B) - Iso.ground_to_screen(stops[0][0] as Vector2)
	t.check(stops.size() == 2 and String(stops[0][1]) == "one" and String(stops[1][1]) == "two"
		and absf(up.x) < 0.01 and absf(up.y - Mission.TOUR_RAISE / Mission.PLAY_ZOOM) < 0.01,
		"each stop raised straight up the screen by TOUR_RAISE at play zoom, its caption kept (%s)" % up)


## A Night 2 mission's world, as its own tests build it.
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
	crowd.profile = ResponseProfile.unaware()
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := (def.director.new() as MissionDirector).setup(rules, crowd, town, null)
	rules.director = director
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director}


static func _done(s: Dictionary) -> void:
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


static func _stops(t) -> void:
	t.check(MissionDirector.new().tour().is_empty(), "a director tours nothing by default: the sweep plays")

	var s := _world(MissionBook.miras_house())
	var m: MirasHouseDirector = s.d
	var stops := m.tour()
	t.check(stops.size() == 3 and stops[0][0] == m.door and stops[1][0] == m.temple_door
		and stops[2][0] == m.venn.ground_pos and String(stops[0][1]) == "Mira's house. Her journal is inside."
		and String(stops[1][1]) == "The Temple. Faithful who see you run here."
		and String(stops[2][1]) == "Venn, the Inquisitor. She searches from 0:40.",
		"Mira's House tours her door, the Temple and the Inquisitor")
	var hud := Hud.new().setup(s.rules, s.crowd, s.town, null)
	hud.set_caption("Mira's house. Her journal is inside.")
	t.check(hud.caption() == "Mira's house. Her journal is inside.", "the HUD holds the tour's caption")
	hud.set_caption("")
	t.check(hud.caption() == "", "and lets it go")
	hud.free()
	(s.crowd as Crowd)._field.kill(m.venn, &"doom")
	t.check(m.tour().size() == 2, "the Inquisitor dead, her stop is left out (review focus 3)")
	_done(s)

	var s2 := _world(MissionBook.broken_lanterns())
	var b: BrokenLanternsDirector = s2.d
	var bs := b.tour()
	t.check(bs.size() == 3 and bs[0][0] == b.standing_shrines()[0].center() and bs[1][0] == b.vigil.bearer.ground_pos
		and bs[2][0] == b.temple_door and String(bs[0][1]) == "A lantern. Break it, then let it drain."
		and String(bs[1][1]) == "The flame-bearer relights broken lanterns."
		and String(bs[2][1]) == "Lantern Knights come out at 1:30.",
		"Broken Lanterns tours a lantern, the flame-bearer and the Temple")
	_done(s2)

	var s3 := _world(MissionBook.vigil_flame())
	var v: VigilFlameDirector = s3.d
	var vs := v.tour()
	t.check(vs.size() == 3 and vs[0][0] == v.vigil.bearer.ground_pos and vs[1][0] == v.shrine and vs[2][0] == v.temple_door
		and String(vs[0][1]) == "Halcyon's flame, carried by the Vigil."
		and String(vs[1][1]) == "Mira's shrine. The flame must come here."
		and String(vs[2][1]) == "The Temple. The flame must not go home.",
		"the Vigil Flame tours the flame, Mira's shrine and the Temple")
	_done(s3)
