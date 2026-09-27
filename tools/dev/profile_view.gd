extends SceneTree
## Where one view of the mission spends its frame. The mission starts as a player's would (the intro skipped), the
## camera parks on --at at --zoom, and each sample averages --frames frames: the frame's wall time, the scripts'
## process time, the renderer's CPU time and the draw calls. First with everything, then with one category at a time
## hidden (its draw cost) or frozen (its script cost), then everything again to show how far the machine drifted.
##
## usage: godot --path . --disable-vsync -s tools/dev/profile_view.gd -- [--at=0.8,2] [--zoom=0.6] [--frames=240]
##   --at      the ground point the camera centres on (default: the market)
##   --zoom    camera zoom (default: Mission.PLAY_ZOOM)
##   --only=a,b  just these categories

const CATEGORIES := [
	"people:hide", "crowd:freeze", "stalls:hide", "houses:hide", "trees:hide", "lamps:hide", "other_structures:hide",
	"structures:freeze", "decor:hide", "decor_low:hide", "decor_goods:hide", "decor_trees:hide", "floor:hide", "forest:hide", "smoke:hide", "hud:hide",
]

## Decor low enough to paint into the floor (people are never hidden behind it), and the goods piled by buildings.
const DECOR_LOW := [Decor.Kind.FLOWERS, Decor.Kind.BUSH, Decor.Kind.GARDEN, Decor.Kind.ROCK, Decor.Kind.REEDS]
const DECOR_GOODS := [Decor.Kind.BARREL, Decor.Kind.CRATES, Decor.Kind.TABLE, Decor.Kind.BENCH, Decor.Kind.LOGS,
	Decor.Kind.CART, Decor.Kind.PILE]

var mission: Mission
var frames := 240


func _initialize() -> void:
	mission = load("res://scenes/mission.tscn").instantiate()
	root.add_child(mission)
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var at := Vector2(0.8, 2.0)
	var at_arg := Battlefield.arg_value(args, "--at")
	if at_arg != "":
		var xy := at_arg.split(",")
		at = Vector2(float(xy[0]), float(xy[1]))
	var zoom_arg := Battlefield.arg_value(args, "--zoom")
	var zoom := float(zoom_arg) if zoom_arg != "" else Mission.PLAY_ZOOM
	var frames_arg := Battlefield.arg_value(args, "--frames")
	if frames_arg != "":
		frames = int(frames_arg)
	var only_arg := Battlefield.arg_value(args, "--only")
	var cats: Array = CATEGORIES if only_arg == "" else Array(only_arg.split(","))
	while not mission.is_prewarmed or not mission.started():
		await process_frame
	# Past the intro, as a player would be, with the clock running.
	mission._intro_left = 0.0
	mission._rules.set_process(true)
	var bf: Battlefield = mission._bf
	bf.camera.zoom = Vector2.ONE * zoom
	bf.camera.position = Iso.ground_to_screen(at).round()
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	for i in 90:
		await process_frame
	print("PROFILE at=%s zoom=%.2f frames=%d" % [at, zoom, frames])
	var base := await _sample("all")
	var busy := 0
	var idle := 0
	var all := mission._bf.ctx.env.structures()
	for st in all:
		if st.is_processing():
			busy += 1
		elif st.idle:
			idle += 1
	print("structures: %d processing, %d idle in view, %d of %d asleep off screen" % [busy, idle,
		all.size() - busy - idle, all.size()])
	var seen := 0
	var calm := 0
	for p: Person in mission._crowd.citizens + mission._crowd.soldiers:
		if is_instance_valid(p) and p._seen:
			seen += 1
			if p.unhurried():
				calm += 1
	print("people: %d on screen, %d of them unhurried (every %d frames)" % [seen, calm, Person.CALM_EVERY])
	for c in cats:
		var cat := String(c).get_slice(":", 0)
		var how := String(c).get_slice(":", 1)
		var nodes := _nodes(cat)
		for n: Node in nodes:
			_toggle(n, how, false)
		await _sample("-%s %s (%d)" % [cat, how, nodes.size()], base)
		for n: Node in nodes:
			_toggle(n, how, true)
	await _sample("all again", base)
	quit()


func _toggle(n: Node, how: String, on: bool) -> void:
	if how == "hide":
		if n is CanvasItem:
			(n as CanvasItem).visible = on
		elif n is CanvasLayer:
			(n as CanvasLayer).visible = on
	else:
		n.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


func _nodes(cat: String) -> Array[Node]:
	var out: Array[Node] = []
	var crowd: Crowd = mission._crowd
	match cat:
		"people":
			for p in crowd.citizens + crowd.soldiers:
				out.append(p)
		"crowd":
			out.append(crowd._ticker)
			for p in crowd.citizens + crowd.soldiers:
				out.append(p)
		"hud":
			out.append(mission._bf.hud_layer)
		"structures":
			for s in mission._bf.ctx.env.structures():
				out.append(s)
		"stalls", "houses", "trees", "lamps", "other_structures":
			for s in mission._bf.ctx.env.structures():
				var k := "other_structures"
				if s.kind == Structure.Kind.MARKET_STALL:
					k = "stalls"
				elif s.kind == Structure.Kind.HOUSE:
					k = "houses"
				elif s.kind == Structure.Kind.TREE:
					k = "trees"
				elif s.kind == Structure.Kind.TORCH:
					k = "lamps"
				if k == cat:
					out.append(s)
		_:
			_collect(root, cat, out)
	return out


func _collect(n: Node, cat: String, out: Array[Node]) -> void:
	for c in n.get_children():
		var hit := false
		match cat:
			"decor": hit = c is Decor
			"decor_low": hit = c is Decor and (c as Decor).kind in DECOR_LOW
			"decor_goods": hit = c is Decor and (c as Decor).kind in DECOR_GOODS
			"decor_trees": hit = c is Decor and (c as Decor).kind in [Decor.Kind.OAK, Decor.Kind.PINE]
			"floor": hit = c is TownFloor
			"forest": hit = c is ForestLayer
			"smoke": hit = c is ChimneySmoke
		if hit:
			out.append(c)
		else:
			_collect(c, cat, out)


func _sample(label: String, base: Dictionary = {}) -> Dictionary:
	for i in 20:
		await process_frame
	var vp := root.get_viewport_rid()
	var wall := 0.0
	var process := 0.0
	var render := 0.0
	var calls := 0.0
	var last := Time.get_ticks_usec()
	for i in frames:
		await process_frame
		var now := Time.get_ticks_usec()
		wall += (now - last) / 1000.0
		last = now
		process += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		render += RenderingServer.viewport_get_measured_render_time_cpu(vp)
		calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var r := {"wall": wall / frames, "process": process / frames, "render": render / frames, "calls": calls / frames}
	var line := "%-30s frame=%6.2fms (%5.1f fps) process=%6.2fms render_cpu=%6.2fms draws=%5d" % [label, r.wall,
		1000.0 / r.wall, r.process, r.render, roundi(r.calls)]
	if not base.is_empty():
		line += "   saves frame=%5.2f process=%5.2f render=%5.2f draws=%4d" % [base.wall - r.wall,
			base.process - r.process, base.render - r.render, roundi(base.calls - r.calls)]
	print(line)
	return r
