extends RefCounted
## God's Chamber transitions polish (step 8): the camera's move into a station and back (a log-space zoom whose focus pans to the
## screen's centre, the layers dollying at their own rates), the page-side fade (ChamberPageFade: the page fades in from the colour the
## zoom ended in and out to it on Back), skip at every phase, the transitions-off path left as it was, each station's signature (one
## swell, within the comfort limits, its particles on their own random) and the transition sounds (catalogued, fired at their moments,
## silent with transitions off).

const PIXEL_AA := preload("res://src/core/pixel_aa.gdshader")
const STATION_CUES := {"tree": &"chamber_riffle", "faith": &"chamber_coin", "descend": &"chamber_unroll", "awaken": &"chamber_groan"}


static func run(t) -> void:
	GodTree.dev_fill = true
	_log_zoom(t)
	_focus_centre(t)
	_layer_scales(t)
	_room_aa(t)
	_page_fade_curves(t)
	_page_fade_node(t)
	_colour_continuity(t)
	_skip_room(t)
	_skip_page(t)
	_routes(t)
	_off_path(t)
	_signatures(t)
	_own_random(t)
	_sound_catalog(t)
	_sound_moments(t)
	_flood_cap(t)
	_edge_veil(t)
	_prewarm(t)
	GodChamber.transitions = false
	GodTree.dev_fill = false


static func _slot() -> GodSlot:
	var god := GodSlot.make(1, "ruin", 7)
	god.tier = 1
	god.level = 10
	god.divine_power = god.need()  # capped: the Rite Door is lit
	return god


static func _make(from := "", on := true) -> GodChamber:
	GodChamber.transitions = on
	var ch := GodChamber.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(ch)
	ch.setup(_slot(), "", false, from)
	return ch


static func _click(at: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	return e


static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	return e


## The zoom is interpolated in log space: scale = ZOOM_TO ^ depth, depth a strong ease-out going in (after the anticipation) and a soft
## settle coming back, never past either end.
static func _log_zoom(t) -> void:
	var ch := _make()
	var cue := GodChamber.CUE_TIME
	var out := GodChamber.OUT_TIME
	t.check(is_equal_approx(GodChamber.OUT_TIME, 0.45) and is_equal_approx(GodChamber.BACK_TIME, 0.4) and is_equal_approx(cue, 0.1),
		"the timings: anticipation 0.1 s, out 0.45 s, back 0.4 s")
	for u: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var d := 1.0 - pow(1.0 - u, 4.0)
		t.check(is_equal_approx(GodChamber.out_depth(u), d), "out depth at u=%.2f is the quartic ease-out (%f)" % [u, GodChamber.out_depth(u)])
		ch.pose_transition("tree", false, cue + out * u)
		t.check(absf(ch.zoom() - exp(d * log(GodChamber.ZOOM_TO))) < 1e-4, "out zoom at u=%.2f is exp(lerp(ln 1, ln 2.2, e)) (%f vs %f)"
			% [u, ch.zoom(), exp(d * log(GodChamber.ZOOM_TO))])
		var b := pow(1.0 - u, 3.0)
		t.check(is_equal_approx(GodChamber.back_depth(u), b), "back depth at u=%.2f is the cubic settle (%f)" % [u, GodChamber.back_depth(u)])
		ch.pose_transition("tree", true, GodChamber.BACK_TIME * u)
		t.check(absf(ch.zoom() - exp(b * log(GodChamber.ZOOM_TO))) < 1e-4, "back zoom at u=%.2f in log space (%f)" % [u, ch.zoom()])
	ch.pose_transition("tree", false, cue * 0.5)
	t.check(ch.zoom() == 1.0 and ch.in_transition(), "during the anticipation the room has not moved yet (%f)" % ch.zoom())
	var lo := 9.0
	var hi := 0.0
	var mono := true
	var last := 0.0
	for i in 121:
		ch.pose_transition("faith", false, (cue + out) * i / 120.0)
		mono = mono and ch.zoom() >= last - 1e-6
		last = ch.zoom()
		hi = maxf(hi, ch.zoom())
	last = 99.0
	for i in 121:
		ch.pose_transition("faith", true, GodChamber.BACK_TIME * i / 120.0)
		mono = mono and ch.zoom() <= last + 1e-6
		last = ch.zoom()
		lo = minf(lo, ch.zoom())
	t.check(mono and hi <= GodChamber.ZOOM_TO + 1e-5 and lo >= 1.0 - 1e-5, "no overshoot either way (max %f, min %f, monotonic %s)" % [hi, lo, mono])
	# A strong ease-out: half the time in, most of the way there.
	ch.pose_transition("tree", false, cue + out * 0.3)
	t.check(ch.zoom() > pow(GodChamber.ZOOM_TO, 0.7), "a third of the way through the time the zoom is past 70%% of its log range (%f)" % ch.zoom())
	ch.free()


## The station's focus pans to the screen's centre while zooming: at rest it is where it is drawn, at the end of the zoom (and the start
## of the way back) it is the frame's centre, whatever the mouse's parallax.
static func _focus_centre(t) -> void:
	var centre := ChamberLayout.FRAME.get_center()
	for key: String in ChamberLayout.ORDER:
		var ch := _make()
		var focus: Vector2 = ChamberLayout.STATIONS[key].focus
		var layer: String = ChamberLayout.STATIONS[key].layer
		for m: Vector2 in [Vector2.ZERO, Vector2(1, -1), Vector2(-0.6, 0.4)]:
			ch._mouse01 = m
			var f := focus + ChamberLayout.shift(layer, m)
			ch.pose_transition(key, false, GodChamber.CUE_TIME + GodChamber.OUT_TIME)
			var at := ch.layer_transform(layer) * f
			t.check(at.distance_to(centre) < 0.01, "%s %s: the focus ends at the screen's centre (%s)" % [key, m, at])
			ch.pose_transition(key, true, 0.0)
			at = ch.layer_transform(layer) * f
			t.check(at.distance_to(centre) < 0.01, "%s %s: and the way back starts there (%s)" % [key, m, at])
			ch.pose_transition(key, false, GodChamber.CUE_TIME + GodChamber.OUT_TIME * 0.5)
			var mid := ch.layer_transform(layer) * f
			var d := GodChamber.out_depth(0.5)
			t.check(mid.distance_to(f.lerp(centre, d)) < 0.01, "%s %s: half way the focus has panned with the depth (%s)" % [key, m, mid])
			ch.pose_transition(key, true, GodChamber.BACK_TIME)
			t.check(ch.layer_transform(layer).is_equal_approx(Transform2D.IDENTITY) and ch.layer_transform("desk").is_equal_approx(Transform2D.IDENTITY),
				"%s %s: back at rest every layer is drawn as it is" % [key, m])
		ch.free()


## The depth dolly: the layers scale about the same focus at rates ordered by their parallax factor (the desk fastest, the wall slowest;
## the station's own layer is the zoom).
static func _layer_scales(t) -> void:
	var ch := _make()
	ch.pose_transition("descend", false, GodChamber.CUE_TIME + GodChamber.OUT_TIME * 0.4)
	var s := {}
	for layer: String in ChamberLayout.LAYERS:
		s[layer] = ch.layer_scale(layer)
	t.check(s.wall < s.stations and s.stations < s.table and s.table < s.desk, "mid zoom: wall < stations < table < desk (%s)" % [s])
	t.check(is_equal_approx(s.wall, ch.zoom()), "the stations' own layer (the wall) is the zoom (%f)" % s.wall)
	var centre := ChamberLayout.FRAME.get_center()
	ch.pose_transition("descend", false, GodChamber.CUE_TIME + GodChamber.OUT_TIME)
	var f: Vector2 = ChamberLayout.STATIONS.descend.focus
	t.check((ch.layer_transform("desk") * f).distance_to(centre) < 0.01, "every layer scales about the same focus (the desk's maps it to the centre too)")
	t.check(ch.layer_scale("desk") > GodChamber.ZOOM_TO * 1.3, "the desk rushes past (%f)" % ch.layer_scale("desk"))
	ch.pose_transition("descend", false, 0.0)
	var rest := true
	for layer: String in ChamberLayout.LAYERS:
		rest = rest and ch.layer_scale(layer) == 1.0
	t.check(rest, "at the press every layer is at 1")
	ch.free()


## Crisp pixels: while the room moves it is drawn on its own canvas item through the project's pixel_aa shader with linear sampling; at
## rest that item has no material and nearest sampling, so the room at rest is drawn exactly as before.
static func _room_aa(t) -> void:
	var ch := _make()
	var room := ch.room_canvas()
	t.check(room != null and room.get_parent() == ch._ui and room.show_behind_parent, "the room has its own canvas item behind the bar")
	t.check(room.material == null, "at rest: no material")
	ch._press("tree")
	var mat := room.material as ShaderMaterial
	t.check(mat != null and mat.shader == PIXEL_AA and room.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR,
		"during the zoom: pixel_aa with linear sampling")
	ch.free()
	ch = _make("faith")
	room = ch.room_canvas()
	t.check(room.material != null, "the way back too")
	ch.skip()
	t.check(room.material == null and room.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR, "and at rest again the plain draw")
	ch.free()


## The page fade's curves: in from the colour over IN_TIME (quick, then soft), out to it over OUT_TIME.
static func _page_fade_curves(t) -> void:
	t.check(is_equal_approx(ChamberPageFade.IN_TIME, 0.2) and is_equal_approx(ChamberPageFade.OUT_TIME, 0.15), "page fade: in 0.2 s, out 0.15 s")
	t.check(ChamberPageFade.alpha_in(0.0) == 1.0 and ChamberPageFade.alpha_in(1.0) == 0.0 and is_equal_approx(ChamberPageFade.alpha_in(0.5), 0.25),
		"in: 1 -> 0, a quarter at half way (%f)" % ChamberPageFade.alpha_in(0.5))
	t.check(ChamberPageFade.alpha_out(0.0) == 0.0 and ChamberPageFade.alpha_out(1.0) == 1.0 and is_equal_approx(ChamberPageFade.alpha_out(0.5), 0.25),
		"out: 0 -> 1, a quarter at half way (%f)" % ChamberPageFade.alpha_out(0.5))
	var mono := true
	for i in 20:
		mono = mono and ChamberPageFade.alpha_in((i + 1) / 20.0) <= ChamberPageFade.alpha_in(i / 20.0)
		mono = mono and ChamberPageFade.alpha_out((i + 1) / 20.0) >= ChamberPageFade.alpha_out(i / 20.0)
	t.check(mono, "both curves are one-way (no flash)")


static func _fade(on := true) -> ChamberPageFade:
	GodChamber.transitions = on
	var f := ChamberPageFade.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(f)
	return f


## The node: its colour is the station's end colour, its alpha follows the curve, it blocks the mouse while it plays, and the end of a
## fade out calls what follows exactly once.
static func _page_fade_node(t) -> void:
	var f := _fade()
	f.fade_in("tree")
	t.check(f.busy() and f.alpha() == 1.0 and f.color().is_equal_approx(GodChamber.end_color("tree")), "fade in starts opaque in the tree's colour")
	t.check(f.cover().mouse_filter == Control.MOUSE_FILTER_STOP and f.layer > 10, "it covers the page (layer %d) and takes the mouse" % f.layer)
	f.advance(ChamberPageFade.IN_TIME * 0.5)
	t.check(is_equal_approx(f.alpha(), ChamberPageFade.alpha_in(0.5)), "half way: the curve's alpha (%f)" % f.alpha())
	f.advance(ChamberPageFade.IN_TIME)
	t.check(not f.busy() and f.alpha() == 0.0 and f.cover().mouse_filter == Control.MOUSE_FILTER_IGNORE, "at the end: clear, the page takes the mouse")
	f.free()
	f = _fade()
	var calls := []
	f.fade_out("faith", func() -> void: calls.append("back"))
	t.check(f.busy() and f.alpha() == 0.0 and Color(f.color(), 1.0).is_equal_approx(GodChamber.end_color("faith")), "fade out starts clear in the altar's colour")
	f.advance(ChamberPageFade.OUT_TIME * 0.5)
	t.check(calls.is_empty() and is_equal_approx(f.alpha(), ChamberPageFade.alpha_out(0.5)), "half way: nothing yet, the curve's alpha")
	f.advance(ChamberPageFade.OUT_TIME)
	f.advance(1.0)
	t.check(calls == ["back"] and f.alpha() == 1.0, "at the end: opaque, and what follows is called once (%s)" % [calls])
	f.free()


## One continuous motion: the zoom ends in the station's end colour, the page fades in from it, the page fades out to it and the room's
## way back starts from it.
static func _colour_continuity(t) -> void:
	for key: String in ChamberLayout.ORDER:
		var ch := _make()
		ch.pose_transition(key, false, GodChamber.CUE_TIME + GodChamber.OUT_TIME)
		var end := ch.fade_color()
		t.check(ch.fade() == 1.0 and end.a == 1.0 and Color(end, 1.0).is_equal_approx(GodChamber.end_color(key)),
			"%s: the zoom ends opaque in the station's end colour (%s)" % [key, end])
		var hue: Color = GodChamber.FADE_COLORS[key]
		var e := GodChamber.end_color(key)
		t.check(e.v > 0.15 and (hue.s < 0.5 or absf(wrapf(e.h - hue.h, -0.5, 0.5)) < 0.06), "%s: the end colour is the station's own (%s vs %s)" % [key, e, hue])
		ch.pose_transition(key, true, 0.0)
		t.check(ch.fade() == 1.0 and Color(ch.fade_color(), 1.0).is_equal_approx(GodChamber.end_color(key)), "%s: the way back starts in it" % key)
		var frame := GodChamber.end_frame(key)
		t.check(frame.color == GodChamber.end_color(key) and frame.focus == ChamberLayout.STATIONS[key].focus and frame.zoom == GodChamber.ZOOM_TO
			and frame.centre == ChamberLayout.FRAME.get_center(), "%s: the end frame a page can match (%s)" % [key, frame])
		ch.free()
	# The fade's colour depends only on how far it has come, so the way back passes through the zoom's colours.
	var a := _make()
	var b := _make("tree")
	a._press("tree")
	var same := true
	for i in 60:
		b.advance(GodChamber.BACK_TIME / 60.0)
		while a.in_transition() and a.fade() < b.fade() and a.fade() < 1.0:
			a.advance(1.0 / 600.0)
		if absf(a.fade() - b.fade()) < 0.01 and a.fade() > 0.0:
			same = same and absf(a.fade_color().r - b.fade_color().r) < 0.02 and absf(a.fade_color().b - b.fade_color().b) < 0.02
	t.check(same, "the way back passes through the same colours as the way in")
	a.free()
	b.free()


## Skip in the room: a click or key during the anticipation or the zoom finishes it (the action is sent once); during the way back it is
## at rest at once; nothing is clickable during a transition.
static func _skip_room(t) -> void:
	for when: float in [0.05, GodChamber.CUE_TIME + 0.2]:
		for by_key in [false, true]:
			var ch := _make()
			var got := []
			ch.action.connect(func(w: String) -> void: got.append(w))
			ch._on_gui_input(_click(ch.menu_rect("tree").get_center()))
			ch.advance(when)
			t.check(got.is_empty(), "%.2f s in: nothing sent yet" % when)
			if by_key:
				ch._unhandled_input(_key(KEY_F))
			else:
				ch._on_gui_input(_click(ch.menu_rect("faith").get_center()))
			t.check(got == ["tree"] and ch.fade() == 1.0, "%.2f s in, %s: skipped to the end, tree sent once, never faith (%s)"
				% [when, "a key" if by_key else "a click", got])
			ch.free()
	var back := _make("descend")
	back.advance(GodChamber.BACK_TIME * 0.3)
	back._unhandled_input(_key(KEY_T))
	t.check(not back.in_transition() and back.zoom() == 1.0 and back.fade() == 0.0, "a key on the way back puts the room at rest")
	back.free()


## Skip on the page: any click or key during the fade in shows the page at once; during the fade out it goes on to the room at once.
static func _skip_page(t) -> void:
	for ev: InputEvent in [_click(Vector2(320, 180)), _key(KEY_SPACE)]:
		var f := _fade()
		f.fade_in("descend")
		f.advance(0.05)
		f._input(ev)
		t.check(not f.busy() and f.alpha() == 0.0, "%s during the fade in: the page at once" % ev.get_class())
		f.free()
		f = _fade()
		var calls := []
		f.fade_out("tree", func() -> void: calls.append(1))
		f.advance(0.03)
		f._input(ev)
		f._input(ev)
		f.advance(1.0)
		t.check(calls == [1] and f.alpha() == 1.0, "%s during the fade out: on to the room at once, once (%s)" % [ev.get_class(), calls])
		f.free()
	var f := _fade()
	f._input(_key(KEY_SPACE))
	t.check(not f.busy(), "an idle fade takes no input")
	f.free()


## Which actions fade a page in or out, and from or to which station: arriving from the room's zoom (hub:<station>), leaving by a page's
## Back (tree:back, faith:back, world:back; Prepare's back only when it was opened by the Rite Door).
static func _routes(t) -> void:
	GodChamber.transitions = true
	var want := {"hub:tree": "tree", "hub:faith": "faith", "hub:descend": "descend", "hub:awaken": "awaken", "hub:title": "", "world:descend": "",
		"results:tree": ""}
	for a: String in want:
		t.check(ChamberPageFade.arrival(a) == want[a], "arrival %s -> \"%s\" (%s)" % [a, want[a], ChamberPageFade.arrival(a)])
	var back := {"tree:back": "tree", "faith:back": "faith", "world:back": "descend", "prepare:hub": "", "results:continue": "", "pause:abandon": ""}
	for a: String in back:
		t.check(ChamberPageFade.departure(a, "") == back[a], "departure %s -> \"%s\"" % [a, back[a]])
	t.check(ChamberPageFade.departure("prepare:hub", "awaken") == "awaken" and ChamberPageFade.departure("prepare:hub", "descend") == "",
		"Prepare's back zooms back to the Rite Door only when the door opened it")
	var ch := _make("awaken")
	t.check(ch.in_transition() and ch.zoom() == GodChamber.ZOOM_TO, "the room comes back from the Rite Door too")
	ch.free()


## Transitions off (FLOW, --capture, headless): no route fades, the room sends in the same call with the same sound before it, and no
## transition sound plays.
static func _off_path(t) -> void:
	GodChamber.transitions = false
	for a: String in ["hub:tree", "hub:faith", "hub:descend", "hub:awaken"]:
		t.check(ChamberPageFade.arrival(a) == "", "off: %s fades nothing in" % a)
	for a: String in ["tree:back", "faith:back", "world:back"]:
		t.check(ChamberPageFade.departure(a, "tree") == "" and ChamberPageFade.departure("prepare:hub", "awaken") == "", "off: %s fades nothing out" % a)
	for key: String in ChamberLayout.ORDER:
		var ch := _make("", false)
		var got := []
		var heard := []
		ch.action.connect(func(w: String) -> void:
			got.append(w)
			heard.append(UiSound.asked.back()))
		UiSound.asked.clear()
		ch._press(key)
		t.check(got == [key] and not ch.in_transition() and heard == [&"ui_click"], "off: %s is sent in the same call, after ui_click (%s %s)" % [key, got, heard])
		t.check(Array(UiSound.asked) == [&"ui_click"], "off: %s plays no transition sound (%s)" % [key, UiSound.asked])
		ch.free()
	var back := _make("tree", false)
	t.check(not back.in_transition() and back.zoom() == 1.0 and back.room_canvas().material == null, "off: back from tree is at rest, plain draw")
	back.free()


## The signatures: each station's flare is one swell (it only rises while going in and only falls coming back), it has started by the
## end of the anticipation, its pieces stay within 0..1 and no light flashes (each piece turns at most once: up, then down).
static func _signatures(t) -> void:
	for key: String in ChamberLayout.ORDER:
		var ch := _make()
		ch._press(key)
		var mono := true
		var last := 0.0
		var steps := 132
		var seen := {}  # piece id -> [last alpha, turns, rising]
		var bounded := true
		var kinds := {}
		for i in steps:
			var f := ch.signature()
			mono = mono and f >= last - 1e-6 and f >= 0.0 and f <= 1.0
			last = f
			for p: Dictionary in ch.signature_pieces():
				var a := float(p.alpha)
				bounded = bounded and a >= 0.0 and a <= 1.0
				kinds[p.get("kind", "")] = true
				var id: String = p.id
				if seen.has(id):
					var s: Array = seen[id]
					var rising := a > float(s[0]) + 1e-4
					var falling := a < float(s[0]) - 1e-4
					if (rising and s[2] == -1) or (falling and s[2] == 1):
						s[1] = int(s[1]) + 1
					if rising:
						s[2] = 1
					elif falling:
						s[2] = -1
					s[0] = a
				else:
					seen[id] = [a, 0, 0]
			if i == int(GodChamber.CUE_TIME * 240.0):
				t.check(ch.zoom() == 1.0 and ch.signature() > 0.2, "%s: by the end of the anticipation the flare shows, the room still (%f)" % [key, ch.signature()])
			ch.advance(1.0 / 240.0)
		var turns := 0
		for id: String in seen:
			turns = maxi(turns, int(seen[id][1]))
		t.check(mono and last > 0.95, "%s: going in, the flare is one rising swell to its top (%f)" % [key, last])
		t.check(bounded and turns <= 1, "%s: every piece stays in 0..1 and turns at most once, no strobe (%d)" % [key, turns])
		t.check(seen.size() >= 2, "%s: the signature draws something (%d pieces)" % [key, seen.size()])
		var want: String = {"tree": "bloom", "faith": "ember", "descend": "bloom", "awaken": "bloom"}[key]
		t.check(kinds.has(want), "%s: it has its %s (%s)" % [key, want, kinds.keys()])
		ch.free()
		var back := _make(key)
		last = 2.0
		mono = true
		for i in 100:
			mono = mono and back.signature() <= last + 1e-6
			last = back.signature()
			back.advance(GodChamber.BACK_TIME / 96.0)
		t.check(mono and back.signature() == 0.0, "%s: coming back it only fades, to nothing at rest" % key)
		back.free()
	var rest := _make()
	t.check(rest.signature() == 0.0 and rest.signature_pieces().is_empty(), "at rest: no signature")
	rest.free()


## The particles' random is their own: the same moment gives the same embers, and the game's random is not touched.
static func _own_random(t) -> void:
	var ch := _make()
	ch.pose_transition("faith", false, 0.3)
	var a := ch.signature_pieces()
	ch.pose_transition("faith", false, 0.3)
	t.check(str(a) == str(ch.signature_pieces()), "the same moment draws the same embers")
	seed(4242)
	var expect := randi()
	seed(4242)
	for i in 60:
		ch.pose_transition("faith", false, i / 100.0)
		ch.signature_pieces()
	t.check(randi() == expect, "drawing the signature never touches the game's random")
	ch.free()


## The transition sounds are in the catalog with their files, on the UI bus, and the four stations each have their own.
static func _sound_catalog(t) -> void:
	var cues: Array = [GodChamber.WHOOSH, GodChamber.WHOOSH_BACK]
	for key: String in STATION_CUES:
		t.check(GodChamber.STATION_CUES.get(key, &"") == STATION_CUES[key], "%s's own sound is %s" % [key, STATION_CUES[key]])
		cues.append(STATION_CUES[key])
	t.check(GodChamber.WHOOSH == &"chamber_whoosh" and GodChamber.WHOOSH_BACK == &"chamber_whoosh_back", "the whooshes' cues")
	for cue: StringName in cues:
		var ok: bool = Sfx.CATALOG.has(cue) and not Sfx.paths_for(cue).is_empty()
		for path in Sfx.paths_for(cue):
			ok = ok and ResourceLoader.exists(path) and FileAccess.file_exists("res://tools/audio/foley/" + path.trim_prefix("res://assets/audio/").trim_suffix(".wav") + ".json")
		t.check(ok, "%s is catalogued, built and has its recipe" % cue)


## Fired at their moments: the press plays the whoosh and the station's own sound with the click (once, a skip adds nothing); the page's
## fade out plays the reverse whoosh; the room's way back adds nothing of its own; transitions off, none of them.
static func _sound_moments(t) -> void:
	for key: String in ChamberLayout.ORDER:
		var ch := _make()
		UiSound.asked.clear()
		ch._press(key)
		t.check(Array(UiSound.asked) == [&"ui_click", GodChamber.WHOOSH, STATION_CUES[key]], "%s: the press plays click, whoosh, its own sound (%s)" % [key, UiSound.asked])
		ch.skip()
		ch.advance(1.0)
		t.check(UiSound.asked.size() == 3, "%s: the skip and the end add nothing (%s)" % [key, UiSound.asked])
		ch.free()
	var f := _fade()
	UiSound.asked.clear()
	f.fade_in("tree")
	f.advance(1.0)
	t.check(UiSound.asked.is_empty(), "the page's fade in is silent (the press's sounds carry it)")
	f.fade_out("tree", func() -> void: pass)
	t.check(Array(UiSound.asked) == [GodChamber.WHOOSH_BACK], "the page's fade out plays the reverse whoosh (%s)" % [UiSound.asked])
	f.free()
	UiSound.asked.clear()
	var back := _make("tree")
	back.advance(1.0)
	t.check(UiSound.asked.is_empty(), "the room's way back plays nothing more (%s)" % [UiSound.asked])
	back.free()


## Review fix 1: the Rite Door's flood stays warm gold, never near-white: every colour its cover passes through (the room's fade, the
## page's fade, the flood and the crack's light) has no channel above COVER_CAP, and it is still a bright warm gold (r > g > b).
static func _flood_cap(t) -> void:
	var cap := GodChamber.COVER_CAP
	t.check(cap <= 0.82 and cap >= 0.75, "the cap is about 80%% (%f)" % cap)
	var hi := 0.0
	var ch := _make()
	for back in [false, true]:
		for i in 61:
			var span := GodChamber.CUE_TIME + GodChamber.OUT_TIME if not back else GodChamber.BACK_TIME
			ch.pose_transition("awaken", back, span * i / 60.0)
			var c := ch.fade_color()
			hi = maxf(hi, maxf(c.r, maxf(c.g, c.b)))
			for p: Dictionary in ch.signature_pieces():
				if p.kind == "bloom":
					var b: Color = p.color
					hi = maxf(hi, maxf(b.r, maxf(b.g, b.b)))
	ch.free()
	var f := _fade()
	for out in [false, true]:
		for i in 11:
			f.pose("awaken", out, (ChamberPageFade.OUT_TIME if out else ChamberPageFade.IN_TIME) * i / 10.0)
			var c := f.color()
			hi = maxf(hi, maxf(c.r, maxf(c.g, c.b)))
	f.free()
	t.check(hi <= cap + 1e-6, "no cover of the Rite Door's goes above the cap (max channel %f, cap %f)" % [hi, cap])
	var e := GodChamber.end_color("awaken")
	t.check(e.v >= cap - 0.05 and e.r > e.g and e.g > e.b, "its end colour is a bright warm gold (%s)" % e)


## Review fix 2: where the zoom would show the painting's dark sides (beyond ChamberLayout.LIT) or past the room's edge that the window
## did not show at rest, the station's end colour covers it, opaque, from the moment it would enter the frame, at 16:9 and 21:9, going
## in and coming back; the dark sides a very wide window already shows at rest are covered too, the colour rising with the depth (full
## by VEIL_SOFT_D); nothing is veiled at rest.
static func _edge_veil(t) -> void:
	var exposed_seen := {}
	for area: Vector2i in [Vector2i(1280, 720), Vector2i(2560, 1080)]:
		UiScale.set_test_area(area)
		for key: String in ChamberLayout.ORDER:
			for m: Vector2 in [Vector2.ZERO, Vector2(0.8, -0.3)]:
				var ch := _make()
				ch._mouse01 = m
				var back := UiScale.backdrop(ch._ui)
				var sh := ChamberLayout.shift("wall", m).x
				var safe_l := minf(ChamberLayout.LIT.position.x, back.position.x - sh) + sh
				var safe_r := maxf(ChamberLayout.LIT.end.x, back.end.x - sh) + sh
				var ok := true
				var worst := ""
				for back_way in [false, true]:
					for i in 121:
						var span := GodChamber.BACK_TIME if back_way else GodChamber.CUE_TIME + GodChamber.OUT_TIME
						ch.pose_transition(key, back_way, span * i / 120.0)
						var tr := ch.layer_transform("wall")
						var el := (tr * Vector2(safe_l, 0.0)).x
						var er := (tr * Vector2(safe_r, 0.0)).x
						var v := ch.veil_edges()
						var lit_l := (tr * Vector2(ChamberLayout.LIT.position.x + sh, 0.0)).x
						var lit_r := (tr * Vector2(ChamberLayout.LIT.end.x + sh, 0.0)).x
						var s := ch.veil_soft_edges()
						var d := GodChamber.back_depth(i / 120.0) if back_way else GodChamber.out_depth((span * i / 120.0 - GodChamber.CUE_TIME) / GodChamber.OUT_TIME)
						var want := 0.0 if d <= 0.0 else smoothstep(0.0, GodChamber.VEIL_SOFT_D, d)
						if d > 0.0 and (lit_l > back.position.x + 0.01 and s.x < minf(lit_l, back.end.x) - 0.01) or d > 0.0 and (lit_r < back.end.x - 0.01 and s.y > maxf(lit_r, back.position.x) + 0.01) \
								or absf(ch.veil_soft_alpha() - want) > 1e-4:
							ok = false
							worst = "soft %s vs lit %f..%f, alpha %f want %f" % [s, lit_l, lit_r, ch.veil_soft_alpha(), want]
						if el > back.position.x + 0.01:
							exposed_seen["%s %s" % [area, key]] = true
							if v.x < el - 0.01 or ch.veil_alpha() < 1.0:
								ok = false
								worst = "left %f > veil %f" % [el, v.x]
						if er < back.end.x - 0.01:
							exposed_seen["%s %s" % [area, key]] = true
							if v.y > er + 0.01 or ch.veil_alpha() < 1.0:
								ok = false
								worst = "right %f < veil %f" % [er, v.y]
				t.check(ok, "%s %s %s: the dark edge never shows uncovered (%s)" % [area, key, m, worst])
				ch.pose_transition(key, true, GodChamber.BACK_TIME)
				var rest := ch.veil_edges()
				t.check(rest.x <= back.position.x + 0.01 and rest.y >= back.end.x - 0.01 and ch.veil_soft_alpha() == 0.0 and ch.veil_alpha() == 0.0,
					"%s %s: at rest nothing is veiled (%s)" % [area, key, rest])
				t.check(ch.veil_color() == GodChamber.end_color(key), "%s: the veil is the station's end colour" % key)
				ch.free()
		UiScale.clear_test_area()
	t.check(exposed_seen.has("(1280, 720) tree") and exposed_seen.has("(1280, 720) faith"), "the Tree and the Altar do reach the dark sides at 16:9 (%s)" % [exposed_seen.keys()])
	t.check(not exposed_seen.has("(1280, 720) awaken") and not exposed_seen.has("(1280, 720) descend"), "the Door and the Table never do at 16:9")


## The prewarm hook (ChamberPrewarm): each room with transitions calls it once from setup; headless it does nothing (no loads, no
## warm-up canvas items); forced, it asks for the transition's sounds, the tree's icons and (door open) Prepare's art, a second room asks
## for nothing again, and step() takes it all in. With transitions off it is never called.
static func _prewarm(t) -> void:
	ChamberPrewarm.reset()
	var calls := ChamberPrewarm.calls
	var ch := _make()
	t.check(ChamberPrewarm.calls == calls + 1, "prewarm: a room with transitions calls it once (%d)" % (ChamberPrewarm.calls - calls))
	t.check(ChamberPrewarm.requested == 0 and ChamberPrewarm.pending() == 0, "prewarm: headless, nothing is loaded")
	t.check(ch._warm.is_empty() and ch._ui.get_child_count() == 1, "prewarm: headless, no warm-up canvas item")
	ch.free()
	calls = ChamberPrewarm.calls
	ch = _make("", false)
	t.check(ChamberPrewarm.calls == calls, "prewarm: never called with transitions off")
	ch.free()
	ChamberPrewarm.force = true
	ch = _make()
	var whoosh := Sfx.paths_for(GodChamber.WHOOSH)[0]
	var tree: Dictionary = SkillTreeScreen.prewarm_paths(_slot())
	var prep := PrepareScreen.prewarm_paths()
	t.check(ChamberPrewarm.asked(whoosh) and ChamberPrewarm.asked(Sfx.paths_for(GodChamber.WHOOSH_BACK)[0]), "prewarm: the whooshes are asked for")
	var all_cues := true
	for cue: StringName in GodChamber.STATION_CUES.values():
		all_cues = all_cues and ChamberPrewarm.asked(Sfx.paths_for(cue)[0])
	t.check(all_cues, "prewarm: every station's sound is asked for")
	t.check(ChamberPrewarm.asked(tree.paths[0]) and ChamberPrewarm.asked(tree.paths[-1]), "prewarm: the tree's icons and clip are asked for")
	t.check(ChamberPrewarm.asked(prep[0]) and ChamberPrewarm.asked(prep[-1]), "prewarm: the door is open, so Prepare's art is asked for")
	var asked := ChamberPrewarm.requested
	t.check(asked > 0, "prewarm: forced, it loads (%d)" % asked)
	ch.free()
	ch = _make()
	t.check(ChamberPrewarm.requested == asked, "prewarm: a second room asks for nothing again (%d)" % (ChamberPrewarm.requested - asked))
	t.check(ChamberPrewarm.start(tree.paths, tree.grey) == 0, "prewarm: start() with the same paths asks for nothing")
	ch.free()
	var done := false
	for i in 2000:
		done = ChamberPrewarm.step(1000000)
		if done:
			break
		OS.delay_msec(2)
	t.check(done and ChamberPrewarm.pending() == 0 and ChamberPrewarm.held(whoosh) and ChamberPrewarm.held(tree.paths[0]),
		"prewarm: step() takes everything in and keeps it")
	t.check(Sfx.load_stream(GodChamber.WHOOSH) == ChamberPrewarm._held[whoosh], "prewarm: the sound plays from the kept stream")
	ChamberPrewarm.reset()
	var closed := _slot()
	closed.level = 5
	GodChamber.transitions = true
	ch = GodChamber.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(ch)
	ch.setup(closed)
	t.check(not ChamberPrewarm.asked(prep[0]) and ChamberPrewarm.asked(whoosh), "prewarm: the door closed, Prepare's art waits")
	ch.free()
	ChamberPrewarm.reset()
	ChamberPrewarm.force = false
