extends SceneTree
## Covered-outline render check (TagOutlines), windowed only (a headless run draws nothing):
##   Godot_v4.7.2-stable_win64.exe --path . --script res://tools/dev/outline_check.gd -- [--mission=lost_lamb] [--look=night|day]
##     [--zooms=0.5,0.85] [--rounds=2] [--out=DIR] [--debug] [--fps [--seconds=4]]
## Plays the mission hosted in a WorldView and, at each zoom, centres the camera on each tagged person in turn and freezes the mission. In
## the world viewport's own image (under the HUD, so a tag's diamond never counts): the outline's pixels (the layer shown vs hidden, in the
## tag's colour) must never fall where the body itself shows (the person drawn vs hidden), must all go when the person's occluders are
## hidden (the body in the open), and no outline pixel may lie outside an outlined body. Covered people must show some. Prints one line per
## sample and a verdict (exit 0 OK, 1 FAIL); with --out, saves the screen (HUD included) round each outlined person, 4x nearest, for a
## look (--debug: also its mask beside the world round it, and its occluders).

const LOADOUT := ["heaven", "tsunami", "cinder", "nova"]
## A body pixel "shows" where drawing the person changes it by more than this (largest channel): less is a trace through an occluder's
## soft edge or the person's foot shadow under one, counted apart (faint) and not a fault.
const SHOWS := 0.12


func _arg(name: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % name):
			return a.substr(name.length() + 3)
	return fallback


func _initialize() -> void:
	await process_frame
	var id := _arg("mission", "lost_lamb")
	var look := Town.look_from_args(OS.get_cmdline_user_args())
	var zooms := Array(_arg("zooms", "0.5,0.85").split(",")).map(func(s: String) -> float: return float(s))
	var out_dir := _arg("out", "")
	var rounds := int(_arg("rounds", "2"))
	City.use(&"aldermere")
	var wv := WorldView.new()
	root.add_child(wv)
	await process_frame
	var m: Mission = load("res://scenes/mission.tscn").instantiate()
	m.autostart = false
	m.mission_id = id
	m.board = true
	m.look_override = look
	wv.host(m)
	if not m.is_prewarmed:
		await m.prewarmed
	m.start(PackedStringArray(LOADOUT), 7)
	m.skip_intro()
	await _frames(30)
	var tol := Settings.live_zoom_out
	Settings.live_zoom_out = Settings.ZOOM_OUT_FAR
	var ol := m._outlines
	if "--fps" in OS.get_cmdline_user_args():
		await _fps(m, ol, zooms)
		Settings.live_zoom_out = tol
		quit(0)
		return
	var st := {"covered": 0, "outline_px": 0, "over_body": 0, "uncovered_px": 0, "elsewhere": 0, "shots": 0, "samples": 0, "faint": 0}
	var t0 := Time.get_ticks_msec()
	for z: float in zooms:
		m._bf.camera.zoom_to(z)
		for r in rounds:
			for w: Array in TagOutlines.wanted(m._hud.all_tags()):
				var p: Person = w[0]
				if not is_instance_valid(p):
					continue
				m.set_frozen(false)
				m._bf.camera.position = p.position
				m._pan(Vector2.ZERO)
				await _frames(4)
				m.set_frozen(true)
				Engine.time_scale = 0.0  # the shaders' clocks stop too: frames differ only by what a sample toggles
				await _frames(2)
				if is_instance_valid(p) and TagOutlines.wanted(m._hud.all_tags()).any(func(e: Array) -> bool: return e[0] == p):
					await _sample(wv, ol, p, w[1], z, id, out_dir, st)
				Engine.time_scale = 1.0
			m.set_frozen(false)
			await _frames(90)  # the night moves on between rounds
	print("outline_check %s look=%d: %d samples, %d covered with %d outline px; outline px over a visible body %d (over a faint trace %d); with the occluders hidden %d; outline px outside every outlined body %d; %.1f s" % [
		id, look, st.samples, st.covered, st.outline_px, st.over_body, st.faint, st.uncovered_px, st.elsewhere, (Time.get_ticks_msec() - t0) / 1000.0])
	var ok: bool = st.over_body == 0 and st.uncovered_px == 0 and st.elsewhere == 0 and st.covered > 0 and st.outline_px > 0
	print("outline_check: %s" % ("OK" if ok else "FAIL"))
	Settings.live_zoom_out = tol
	quit(0 if ok else 1)


## --fps: the frame rate with the outlines on and off (the layer's refresh skipped and its slots let go), alternating in the same run so the
## machine's load falls on both alike; the camera rests on the mission's spot at each zoom.
func _fps(m: Mission, ol: TagOutlines, zooms: Array) -> void:
	var secs := float(_arg("seconds", "4"))
	var cpu := [0.0]
	if RenderingServer.frame_pre_draw.is_connected(ol.refresh):
		RenderingServer.frame_pre_draw.disconnect(ol.refresh)
	var timed := func() -> void:
		var t := Time.get_ticks_usec()
		ol.refresh()
		cpu[0] += (Time.get_ticks_usec() - t) / 1000.0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	await _frames(30)
	for z: float in zooms:
		m._bf.camera.zoom_to(z)
		var sums := {true: 0.0, false: 0.0}
		var counts := {true: 0, false: 0}
		var lit := {true: 0, false: 0}
		cpu[0] = 0.0
		var masks := [0]
		for i in 6:
			var on := i % 2 == 0
			if on:
				if not RenderingServer.frame_pre_draw.is_connected(timed):
					RenderingServer.frame_pre_draw.connect(timed)
			else:
				if RenderingServer.frame_pre_draw.is_connected(timed):
					RenderingServer.frame_pre_draw.disconnect(timed)
				var none: Array[MapTag] = []
				ol.update(none)
			await _frames(10)
			var t0 := Time.get_ticks_usec()
			var n := 0
			while Time.get_ticks_usec() - t0 < int(secs * 1.0e6):
				await process_frame
				n += 1
				lit[on] += ol.outlined().size()
				if on:
					masks[0] += ol.masks_on()
			sums[on] += (Time.get_ticks_usec() - t0) / 1.0e6
			counts[on] += n
		print("fps zoom %.2f: outlines on %.1f fps (%.1f outlined a frame in %.1f masks, refresh %.2f ms a frame), off %.1f fps" % [z,
			counts[true] / sums[true], float(lit[true]) / maxf(counts[true], 1.0), float(masks[0]) / maxf(counts[true], 1.0),
			cpu[0] / maxf(counts[true], 1.0), counts[false] / sums[false]])


func _frames(n: int) -> void:
	for i in n:
		await process_frame


static func _shot(wv: WorldView) -> Image:
	return wv.viewport.get_texture().get_image()


static func _body_rect(ol: TagOutlines, p: Person, grow: float) -> Rect2i:
	return Rect2i((ol.device_xf() * (p.get_global_transform() * Transform2D(0.0, p._draw_origin)) * p.drawn_dst).grow(grow))


## One frozen sample of `p`: its outline pixels (the outline layer shown vs hidden), the pixels its body shows (it drawn vs hidden), the
## outline with its occluders hidden, and any outline pixel outside every outlined body.
func _sample(wv: WorldView, ol: TagOutlines, p: Person, col: Color, z: float, id: String, out_dir: String, st: Dictionary) -> void:
	st.samples += 1
	var rect := _body_rect(ol, p, 1.0).intersection(Rect2i(Vector2i.ZERO, wv.viewport.size))
	var covered := ol.outlined().any(func(e: Array) -> bool: return e[0] == p)
	var rects: Array[Rect2i] = []
	var cols: Array[Color] = []
	for o: Array in ol.outlined():
		rects.append(_body_rect(ol, o[0], 2.0))
		cols.append(o[1])
	var on := _shot(wv)
	ol.visible = false
	await _frames(2)
	var off := _shot(wv)
	p.visible = false
	await _frames(2)
	var bare := _shot(wv)
	p.visible = true
	ol.visible = true
	# The outline: what the layer adds, in the tag's colour.
	var outline := {}
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if on.get_pixel(x, y) != off.get_pixel(x, y) and _is(on.get_pixel(x, y), col):
				outline[Vector2i(x, y)] = true
	var over := 0
	var faint := 0
	var marked := on.duplicate() as Image
	for q: Vector2i in outline:
		var d := _diff(off.get_pixel(q.x, q.y), bare.get_pixel(q.x, q.y))
		if d > SHOWS:
			over += 1  # the body itself shows here: an outline over a visible part
			marked.set_pixel(q.x, q.y, Color.GREEN)
		elif d > 0.0:
			faint += 1  # a trace of it through an occluder's soft edge or its own shadow under one
			marked.set_pixel(q.x, q.y, Color.YELLOW)
	st.faint += faint
	if (over > 0 or faint > 4) and out_dir != "":
		var g := Rect2i(Rect2(rect).grow(6.0)).intersection(Rect2i(Vector2i.ZERO, on.get_size()))
		var trio := Image.create(g.size.x * 3 + 4, g.size.y, false, Image.FORMAT_RGBA8)
		trio.fill(Color.MAGENTA)
		for k in 3:
			var src: Image = [marked, off, bare][k]
			var piece := src.get_region(g)
			piece.convert(Image.FORMAT_RGBA8)
			trio.blit_rect(piece, Rect2i(Vector2i.ZERO, g.size), Vector2i(k * (g.size.x + 2), 0))
		trio.resize(trio.get_width() * 6, trio.get_height() * 6, Image.INTERPOLATE_NEAREST)
		trio.save_png(out_dir.path_join("over_%s_z%.2f_%d.png" % [id, z, st.samples]))
	# Outline pixels anywhere else on screen: only outlined bodies may have any.
	var elsewhere := 0
	var a := on.duplicate() as Image
	var b := off.duplicate() as Image
	for r in rects:
		a.fill_rect(r, Color.BLACK)
		b.fill_rect(r, Color.BLACK)
	if a.get_data() != b.get_data():  # only then pixel by pixel
		for y in on.get_height():
			for x in on.get_width():
				if on.get_pixel(x, y) != off.get_pixel(x, y) and not rects.any(func(r: Rect2i) -> bool: return r.has_point(Vector2i(x, y))):
					elsewhere += 1
					if elsewhere <= 3:
						print("   elsewhere at %s: %s -> %s" % [Vector2i(x, y), off.get_pixel(x, y), on.get_pixel(x, y)])
	# The same body in the open: its occluders hidden, the outline must go.
	var occ := ol.occluders_of(p)
	var hidden: Array[CanvasItem] = []
	for it: Dictionary in occ:
		var n: CanvasItem = it.node
		if n.visible:
			n.visible = false
			hidden.append(n)
	await _frames(2)
	var open_on := _shot(wv)
	ol.visible = false
	await _frames(2)
	var open_off := _shot(wv)
	ol.visible = true
	for n in hidden:
		n.visible = true
	var open_px := 0
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if open_on.get_pixel(x, y) != open_off.get_pixel(x, y):
				open_px += 1
	if covered:
		st.covered += 1
		st.outline_px += outline.size()
	st.over_body += over
	st.uncovered_px += open_px
	st.elsewhere += elsewhere
	print("zoom %.2f %s#%d covered=%s outline_px=%d over_body=%d open_px=%d elsewhere=%d occluders=%d" % [z, col.to_html(false),
		p.get_instance_id() % 10000, covered, outline.size(), over, open_px, elsewhere, occ.size()])
	if out_dir != "" and outline.size() > 0 and int(st.shots) < 16:
		var shot := root.get_texture().get_image()
		var c := Rect2i(Rect2(rect).grow(24.0)).intersection(Rect2i(Vector2i.ZERO, shot.get_size()))
		if c.has_area():
			var crop := shot.get_region(c)
			crop.resize(c.size.x * 4, c.size.y * 4, Image.INTERPOLATE_NEAREST)
			crop.save_png(out_dir.path_join("outline_%s_z%.2f_%d.png" % [id, z, st.shots]))
			if "--debug" in OS.get_cmdline_user_args():
				_debug(ol, p, on, out_dir.path_join("debug_%s_z%.2f_%d" % [id, z, st.shots]))
			st.shots += 1


static func _diff(a: Color, b: Color) -> float:
	return maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b)))


static func _is(c: Color, col: Color) -> bool:
	return absf(c.r - col.r) < 0.012 and absf(c.g - col.g) < 0.012 and absf(c.b - col.b) < 0.012


## --debug: the slot's mask and the world (no HUD) round the body, side by side 4x, and the occluders it holds.
static func _debug(ol: TagOutlines, p: Person, img: Image, path: String) -> void:
	for s in ol._slots:
		if s.who != p:
			continue
		var mask := s.mask.vp.get_texture().get_image()
		var o: Vector2 = s.mask.origin
		var r := Rect2i(Vector2i(o), mask.get_size()).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		var w := img.get_region(r)
		var both := Image.create(r.size.x * 2 + 2, r.size.y, false, Image.FORMAT_RGBA8)
		both.fill(Color.MAGENTA)
		mask.convert(Image.FORMAT_RGBA8)
		w.convert(Image.FORMAT_RGBA8)
		both.blit_rect(w, Rect2i(Vector2i.ZERO, r.size), Vector2i.ZERO)
		both.blit_rect(mask, Rect2i(Vector2i.ZERO, r.size), Vector2i(r.size.x + 2, 0))
		both.resize(both.get_width() * 4, both.get_height() * 4, Image.INTERPOLATE_NEAREST)
		both.save_png(path + ".png")
		print("DEBUG %s person at %s z=%d dst=%s" % [path.get_file(), p.position, TagOutlines._z(p), p.drawn_dst])
		for it: Dictionary in ol.occluders_of(p):
			var n: CanvasItem = it.node
			var what := "-"
			if n is Structure:
				what = "Structure %s role=%s" % [Structure.Kind.keys()[(n as Structure).kind], (n as Structure).role]
			elif n is Decor:
				what = "Decor %s size=%s" % [Decor.Kind.keys()[(n as Decor).kind], (n as Decor).size]
			elif n is TownLookDecor.PropNode:
				what = "PropNode"
			print("   occ %s y=%.1f z=%d box=%s %s" % [n.name, it.y, it.z, it.box, what])
