extends RefCounted
## 2026-11-17 tag fix: a map tag on a person sits on that person's drawn body and shows only while the body is drawn (Hud.tag_faults(), the
## invariant), across real missions, the zoom range (0.35 .. 1.6) and two screen areas, hosted in a WorldView and not; a tag over a person
## gone indoors becomes an honest "- INSIDE" place, one over a person not drawn goes; and the wheel zooms about the screen's centre.

## The scripted run: missions (board nights; Lost Lamb at NIGHT, the user's report), areas (UI units, k, fit) and zooms.
const MISSIONS := [["lost_lamb", Town.Look.NIGHT], ["tax_collector", -1], ["first_prayers", -1], ["warning", -1]]
const AREAS := [[Vector2i(640, 360), 1, 1.0], [Vector2i(960, 495), 2, 1.375]]
const ZOOMS := [0.35, 0.85, 1.6]
## Frames run at each area and zoom, and how often the invariant is checked among them.
const FRAMES := 24
const EVERY := 6
const LOADOUT := ["heaven", "tsunami", "cinder", "nova"]


static func run(t) -> void:
	await t.process_frame  # the root is live only after the first frame
	_unit(t)
	await _missions(t)
	await _unhosted(t)
	await _wheel_centre(t)


## A Mission for `id` at `look` (-1: none), on the board, seed 7, under `parent` (hosted when a WorldView is given); the caller frees it.
static func _start(t, id: String, look: int, wv: WorldView) -> Mission:
	City.use(&"aldermere")
	var m: Mission = load("res://scenes/mission.tscn").instantiate()
	m.autostart = false
	m.mission_id = id
	m.board = true
	m.look_override = look
	if wv != null:
		wv.host(m)
	else:
		t.root.add_child(m)
	if not m.is_prewarmed:
		await m.prewarmed
	m.start(PackedStringArray(LOADOUT), 7)
	m.skip_intro()
	await t.process_frame
	return m


static func _only(tags: Array[MapTag], tag: MapTag) -> bool:
	return tags.size() == 1 and tags[0] == tag


static func _people(m: Mission) -> Array:
	var out: Array = []
	out.append_array(m._crowd.citizens)
	out.append_array(m._crowd.soldiers)
	return out


## The invariant over a few frames; returns [faults, tags on people checked].
static func _check_frames(t, m: Mission, frames: int) -> Array:
	var faults := PackedStringArray()
	var seen := 0
	for f in frames:
		await t.process_frame
		if f % EVERY != EVERY - 1 or not is_instance_valid(m) or m._hud == null:
			continue
		var tags := m._hud.all_tags()
		for tag in tags:
			if tag.who != null:
				seen += 1
		faults.append_array(Hud.tag_faults(tags, m._hud._world_xf(), _people(m)))
	return [faults, seen]


static func _missions(t) -> void:
	var was := Settings.live_zoom_out
	Settings.live_zoom_out = Settings.ZOOM_OUT_FAR
	WorldView.test_host = true
	for spec: Array in MISSIONS:
		var wv := WorldView.new()
		t.root.add_child(wv)
		await t.process_frame
		var m := await _start(t, String(spec[0]), int(spec[1]), wv)
		var faults := PackedStringArray()
		var seen := 0
		for a: Array in AREAS:
			wv._on_layout({"area": a[0], "k": a[1], "fit": a[2]})
			for z: float in ZOOMS:
				m._bf.camera.zoom_to(z)
				m._bf.sim_zoom = z * Mission.SIM_PLAY_ZOOM / Mission.PLAY_ZOOM
				m._pan(Vector2.ZERO)
				var got: Array = await _check_frames(t, m, FRAMES)
				for line in got[0] as PackedStringArray:
					faults.append("%s %s zoom %.2f: %s" % [spec[0], a[0], z, line])
				seen += int(got[1])
		t.check(seen > 0, "%s: tags on people were checked (%d)" % [spec[0], seen])
		t.check(faults.is_empty(), "%s: every tag on a person sits on its drawn body, which is drawn (%d faults: %s)" % [spec[0],
			faults.size(), "; ".join(faults.slice(0, 4))])
		wv.get_parent().remove_child(wv)
		wv.free()
		await t.process_frame
	WorldView.test_host = false
	Settings.live_zoom_out = was


## Unhosted (the references' and the suite's way): the world in the root, the same invariant.
static func _unhosted(t) -> void:
	var m := await _start(t, "lost_lamb", Town.Look.NIGHT, null)
	t.check(WorldView.of(m) == null, "unhosted: the mission is in the root")
	var got: Array = await _check_frames(t, m, FRAMES)
	t.check(int(got[1]) > 0 and (got[0] as PackedStringArray).is_empty(), "unhosted: every tag on a person sits on its drawn body (%d checked, %s)" % [
		got[1], "; ".join(got[0] as PackedStringArray)])
	m.queue_free()
	await t.process_frame


## The pieces: where a person's diamond goes at any zoom, a lifted body, a hidden one, one indoors, and a tag made from a copied point.
static func _unit(t) -> void:
	var p := Person.new()
	p.ground_pos = Vector2(3.0, 2.0)
	p.position = Iso.ground_to_screen(p.ground_pos).round()
	var tag := MapTag.person(p, Color.RED, "WREN", true)
	t.check(tag.who == p and tag.at == p.ground_pos and tag.lift == MapTag.PERSON_LIFT, "MapTag.person(a Person) marks the person and its point")
	var spot := MapTag.person(Vector2(1.0, 1.0), Color.RED)
	t.check(spot.who == null and spot.at == Vector2(1.0, 1.0), "MapTag.person(a point) is a spot, as before")
	# Out of the tree (a model world: no screen) a tag is what its director made: shown, at its ground point with the old lift.
	var list: Array[MapTag] = [tag, spot]
	t.check(MapTag.shown(list).size() == 2, "out of the tree a tag on a body is shown as made")
	var model := (Iso.ground_to_screen(p.ground_pos) - Vector2(0.0, MapTag.PERSON_LIFT)).round()
	t.check(Hud.tag_point(tag, Transform2D.IDENTITY) == model, "out of the tree its diamond is at its ground point, as before (%s)" % model)
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(p)
	p.position = Iso.ground_to_screen(p.ground_pos).round()
	var feet := p.position
	for z: float in [0.35, 0.85, 1.6, 2.2]:
		var xf := Transform2D(0.0, Vector2(z, z), 0.0, Vector2(100.0, 50.0))
		var c := Hud.tag_point(tag, xf)
		var head := xf * (feet - Vector2(0.0, p.tag_head()))
		t.check(absf(c.x - head.x) <= 1.0 and absf(c.y - (head.y - tag.size - Hud.PERSON_GAP)) <= 1.0,
			"zoom %.2f: the diamond's lower tip is just over the drawn head (%s, head %s)" % [z, c, head])
	p._lift = 30.0
	var up := Hud.tag_point(tag, Transform2D.IDENTITY)
	p._lift = 0.0
	t.check(absf(Hud.tag_point(tag, Transform2D.IDENTITY).y - up.y - 30.0) <= 1.0, "a body a power lifts takes its diamond up with it")
	p.soldier = true
	t.check(p.tag_head() == Person.TAG_HEAD_SOLDIER and p.tag_head() > DummyEnemy.TAG_HEAD, "a soldier's head stands higher")
	p.soldier = false
	# In the tree: drawn, hidden, faded, indoors.
	t.check(MapTag.shown(list).size() == 2 and MapTag.shown(list)[0] == tag, "drawn: shown as it is")
	p.visible = false
	t.check(_only(MapTag.shown(list), spot), "hidden: not shown")
	p.visible = true
	p.modulate.a = 0.0
	t.check(_only(MapTag.shown(list), spot), "faded out: not shown")
	p.modulate.a = 1.0
	p.inside = true
	p.visible = false
	var shown := MapTag.shown(list)
	t.check(shown.size() == 2 and shown[0].who == null and shown[0].label == "WREN - INSIDE" and shown[0].at == p.ground_pos
		and shown[0].lift == MapTag.PLACE_LIFT and shown[0].edge, "indoors: an honest place where it went in, WREN - INSIDE, still pointed at")
	var bare: Array[MapTag] = [MapTag.person(p, Color.RED)]
	t.check(MapTag.shown(bare).is_empty(), "indoors, a tag without a label simply goes")
	p.inside = false
	p.visible = true
	# The invariant itself: a tag made from the point and not the person is caught; a sound one is not; one placed with another camera is.
	var copied: Array[MapTag] = [MapTag.person(p.ground_pos, Color.RED, "COPY")]
	t.check(Hud.tag_faults(copied, Transform2D.IDENTITY, [p]).size() == 1, "a tag made from a person's copied point is a fault")
	var sound: Array[MapTag] = [tag]
	t.check(Hud.tag_faults(sound, Transform2D.IDENTITY, [p]).is_empty(), "a tag on its person's body is not (%s)" % Hud.tag_faults(sound, Transform2D.IDENTITY, [p]))
	t.check(Hud.tag_faults(sound, Transform2D(0.0, Vector2(1.5, 1.5), 0.0, Vector2(40.0, 0.0)), [p]).size() == 1,
		"a tag placed with a camera the body is not drawn with is a fault")
	p.ground_pos += Vector2(1.0, 0.0)
	t.check(Hud.tag_faults(sound, Transform2D.IDENTITY, [p]).size() >= 1, "a tag whose point is stale is a fault")
	p.inside = true
	p.visible = false
	t.check(Hud.tag_faults(sound, Transform2D.IDENTITY, [p]).size() >= 1, "a raw tag over a body indoors is a fault (all_tags() never shows it)")
	tree.root.remove_child(p)
	p.free()


## The wheel zooms about the screen's centre (2026-11-17): the world point under the centre is the same before and after a step in or out,
## away from the map's edges, at 640x360 and 960x495; at an edge, where the view must stay on the drawn ground, a step out moves the camera
## and the step back in returns it to the centre the player had.
static func _wheel_centre(t) -> void:
	var was := Settings.live_zoom_out
	Settings.live_zoom_out = Settings.ZOOM_OUT_FAR
	WorldView.test_host = true
	var wv := WorldView.new()
	t.root.add_child(wv)
	await t.process_frame
	var m := await _start(t, "warning", -1, wv)
	for a: Array in AREAS:
		wv._on_layout({"area": a[0], "k": a[1], "fit": a[2]})
		m._bf.camera.zoom_to(Mission.PLAY_ZOOM)
		m._bf.camera.position = Mission.pan_limits().get_center()  # the middle of the town: no step reaches an edge
		m._pan(Vector2.ZERO)
		await t.process_frame
		var mid := Vector2(a[0]) * 0.5
		var drift := 0.0
		for step: bool in [true, true, false, false, false, true]:
			var before := m.world_xf().affine_inverse() * mid
			m.wheel_zoom(step)
			await t.process_frame
			drift = maxf(drift, (m.world_xf().affine_inverse() * mid).distance_to(before))
		t.check(drift < 0.6, "%s: a wheel step keeps the world point under the screen's centre (drift %.2f px)" % [a[0], drift])
		# At the edge: far out the view is pulled onto the ground; back in, the kept centre returns.
		m._bf.camera.zoom_to(Mission.PLAY_ZOOM)
		m._bf.camera.position = Mission.clamp_view(Iso.ground_to_screen(Vector2(4.0, 30.0)), m._bf.camera.zoom.x, Vector2(a[0]))
		var start := m._bf.camera.position
		var moved := false
		for i in 8:
			m.wheel_zoom(false)
			moved = moved or m._bf.camera.position != start
		for i in 8:
			m.wheel_zoom(true)
		t.check(moved and m._bf.camera.position.distance_to(start) < 0.01 and absf(m._bf.camera.logical_zoom() - Mission.PLAY_ZOOM) < 0.001,
			"%s: at the edge a step out is pulled onto the ground and the way back in ends where it began (%s, %s)" % [a[0], start,
			m._bf.camera.position])
	wv.get_parent().remove_child(wv)
	wv.free()
	await t.process_frame
	WorldView.test_host = false
	Settings.live_zoom_out = was
