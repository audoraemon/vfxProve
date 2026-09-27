extends SceneTree
## Whether the frame slows for good as a mission wears on. The mission starts as a player's would (intro skipped),
## the camera parks on the market, and each round casts the loadout's powers at spots round the town centre (DP and
## cooldowns refilled; the Citadel is never aimed at), waits for the effects to die down, then samples the frame and
## counts what has piled up: nodes, draw calls, buildings (standing, fallen, processing), people by state, fallen
## decor, lights, and the children of the effect and world layers.
##
## usage: godot --path . --disable-vsync -s tools/dev/profile_wear.gd -- [--rounds=6] [--settle=8] [--no-cast]
##   --no-cast  the same rounds with nothing cast: what time alone does

const SPOTS := [Vector2(0.8, 2.0), Vector2(-8.0, 6.0), Vector2(7.0, -2.0), Vector2(-3.0, 11.0), Vector2(-6.0, -3.0),
	Vector2(11.0, 3.0), Vector2(3.0, -8.0), Vector2(-11.0, 11.0)]

var mission: Mission
var frames := 180


func _initialize() -> void:
	mission = load("res://scenes/mission.tscn").instantiate()
	root.add_child(mission)
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var rounds := int(Battlefield.arg_value(args, "--rounds")) if Battlefield.arg_value(args, "--rounds") != "" else 6
	var settle := float(Battlefield.arg_value(args, "--settle")) if Battlefield.arg_value(args, "--settle") != "" \
		else 8.0
	var cast := not "--no-cast" in args
	while not mission.is_prewarmed or not mission.started():
		await process_frame
	mission._intro_left = 0.0
	mission._rules.set_process(true)
	var bf: Battlefield = mission._bf
	bf.camera.zoom = Vector2.ONE * Mission.PLAY_ZOOM
	bf.camera.position = Iso.ground_to_screen(Vector2(0.8, 2.0)).round()
	for i in 60:
		await process_frame
	await _sample("start")
	var spot := 0
	for r in rounds:
		if cast:
			for slot in mission._rules.loadout.size():
				mission._rules.dp = Rules.DP_MAX
				mission._rules._cooldowns[slot] = 0.0
				var at: Vector2 = SPOTS[spot % SPOTS.size()]
				spot += 1
				mission._rules.cast(slot, at, {"dir": Vector2(1.0, 0.3).normalized()})
				await _wait(1.0)
		await _wait(settle)
		await _sample("round %d" % (r + 1))
	# Where the worn town's draw calls go: hide one kind of thing at a time.
	var env: EnvironmentField = mission._bf.ctx.env
	var fallen: Array[Node] = []
	var standing: Array[Node] = []
	for st in env.structures():
		(fallen if st.destroyed else standing).append(st)
	var people: Array[Node] = []
	for p in mission._crowd.citizens + mission._crowd.soldiers:
		if is_instance_valid(p):
			people.append(p)
	var decor: Array[Node] = []
	for d in env.decor():
		decor.append(d)
	var fx: Array[Node] = [env.fx_back, env.fx_parent]
	for pair in [["fallen", fallen], ["standing", standing], ["people", people], ["decor", decor], ["fx layers", fx]]:
		for n: Node in pair[1]:
			if is_instance_valid(n):
				(n as CanvasItem).visible = false
		await _sample("-" + pair[0])
		for n: Node in pair[1]:
			if is_instance_valid(n):
				(n as CanvasItem).visible = true
	quit()


func _wait(seconds: float) -> void:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await process_frame


## Redraws of standing and fallen buildings during the current sample (each structure's draw signal).
var _redraws := [0, 0]
var _hooked := {}


func _hook_draws() -> void:
	for s in mission._bf.ctx.env.structures():
		if not _hooked.has(s):
			_hooked[s] = true
			s.draw.connect(func() -> void: _redraws[1 if s.destroyed else 0] += 1)


func _sample(label: String) -> void:
	_hook_draws()
	_redraws = [0, 0]
	var wall := 0.0
	var calls := 0.0
	var last := Time.get_ticks_usec()
	for i in frames:
		await process_frame
		var now := Time.get_ticks_usec()
		wall += (now - last) / 1000.0
		last = now
		calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var ms := wall / frames
	var redraws := [float(_redraws[0]) / frames, float(_redraws[1]) / frames]
	print("WEAR %-8s frame=%6.2fms (%5.1f fps) draws=%5d nodes=%d objects=%d" % [label, ms, 1000.0 / ms,
		roundi(calls / frames), Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.OBJECT_COUNT)])
	var env: EnvironmentField = mission._bf.ctx.env
	var down := 0
	var busy := 0
	var idle := 0
	for s in env.structures():
		if s.destroyed:
			down += 1
		if s.is_processing():
			busy += 1
		elif s.idle:
			idle += 1
	var fallen_decor := 0
	for d in env.decor():
		if is_instance_valid(d) and d.down:
			fallen_decor += 1
	var minds := {}
	var dead := 0
	for p: Person in mission._crowd.citizens + mission._crowd.soldiers:
		if not is_instance_valid(p):
			continue
		if p.state == DummyEnemy.State.DEAD:
			dead += 1
		else:
			var k: String = Person.Mind.keys()[p.mind]
			minds[k] = int(minds.get(k, 0)) + 1
	var lights: LightField = mission._bf.ctx.lights
	print("     structures=%d down=%d processing=%d idle=%d | decor=%d down=%d | people dead=%d %s | field units=%d" % [
		env.structures().size(), down, busy, idle, env.decor().size(), fallen_decor, dead, minds,
		mission._bf.ctx.field._enemies.size()])
	var ctx = mission._bf.ctx
	var layers := {"world": ctx.world, "ground": ctx.ground, "overhead": ctx.overhead,
		"overhead_back": ctx.overhead_back, "distort": ctx.distort, "fx_back": env.fx_back, "fx": env.fx_parent}
	var parts := []
	for k in layers:
		var n: Node = layers[k]
		if n != null:
			parts.append("%s=%d(%d deep)" % [k, n.get_child_count(), _count(n)])
	print("     redraws a frame: standing=%.1f fallen=%.1f" % redraws)
	print("     lights=%d dynamic=%d tweens=%d audio=%d | %s" % [lights._lights.size(), lights._dynamic.size(),
		get_processed_tweens().size(), _audio(root), " ".join(parts)])


func _count(n: Node) -> int:
	var c := n.get_child_count()
	for ch in n.get_children():
		c += _count(ch)
	return c


func _audio(n: Node) -> int:
	var c := 0
	for ch in n.get_children():
		if ch is AudioStreamPlayer or ch is AudioStreamPlayer2D:
			c += 1
		c += _audio(ch)
	return c
