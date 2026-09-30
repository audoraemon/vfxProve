extends SceneTree
## Scripted citizen-behaviour scenarios (v0.04), on the real mission at a fixed step (run with --fixed-fps 60), so
## each prints the same numbers every run. Each ends with a checksum of everyone's position and mind.
##
## usage: godot --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=calm
##   [--seconds=60] [--shots]
##   calm   nothing cast: where citizens are, by kind of place, every 20 s; --shots saves captures at the end
##   strike after 20 s of calm, one Heaven Splitter in the market: intents by distance from it, over 30 s
##   escalate  three casts across town, 15 s apart: the alarm stage, the bell and everyone's intents every 5 s
##   gates  an evacuation called after 20 s of calm; --hazard puts a lasting danger on the Main Gate's approach at
##          5 s: evacuees by chosen exit, reroutes and queues over 40 s
##   fire   three houses set burning in the west quarter after 20 s of calm: fires, intensity, responders over 40 s

var mission: Mission


func _initialize() -> void:
	mission = load("res://scenes/mission.tscn").instantiate()
	root.add_child(mission)
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var scenario := Battlefield.arg_value(args, "--scenario")
	var seconds := float(Battlefield.arg_value(args, "--seconds")) if Battlefield.arg_value(args, "--seconds") != "" \
		else 60.0
	while not mission.is_prewarmed or not mission.started():
		await process_frame
	mission._intro_left = 0.0
	mission._rules.set_process(true)
	match scenario:
		"calm", "":
			await _calm(seconds, "--shots" in args)
		"strike":
			await _strike("--shots" in args)
		"escalate":
			await _escalate()
		"fire":
			await _fire("--shots" in args)
		"gates":
			await _gates("--hazard" in args, "--shots" in args)
	print("BEHAVIOUR checksum=%d" % _checksum())
	quit()


func _calm(seconds: float, shots: bool) -> void:
	var t := 0.0
	while t < seconds:
		await _frames(20 * 60)
		t += 20.0
		print("BEHAVIOUR calm t=%d %s" % [roundi(t), _places()])
	if shots:
		var bf: Battlefield = mission._bf
		for shot in [["behaviour_market.png", Vector2(0.8, 2.0), 1.0], ["behaviour_town.png", Vector2(0, 2), 0.3],
				["behaviour_farms.png", Vector2(2.0, 24.0), 0.5]]:
			bf.camera.zoom = Vector2.ONE * float(shot[2])
			bf.camera.position = Iso.ground_to_screen(shot[1]).round()
			await _frames(3)
			await bf.save_capture(shot[0])


func _strike(shots: bool) -> void:
	await _frames(20 * 60)
	var at := Vector2(0.8, 2.0)
	mission._rules.cast(0, at, {"dir": Vector2(1, 0)})
	var t := 0.0
	for mark in [0.5, 2.0, 5.0, 10.0, 20.0, 30.0]:
		await _frames(roundi((mark - t) * 60.0))
		t = mark
		print("BEHAVIOUR strike t=%.1f %s" % [t, _bands(at)])
		if shots and is_equal_approx(mark, 2.0):
			var bf: Battlefield = mission._bf
			bf.camera.zoom = Vector2.ONE * 0.6
			bf.camera.position = Iso.ground_to_screen(at).round()
			await _frames(2)
			await bf.save_capture("behaviour_strike.png")


func _escalate() -> void:
	await _frames(20 * 60)
	var casts := [[0.0, 0, Vector2(0.8, 2.0)], [15.0, 2, Vector2(-9.0, 5.0)], [30.0, 1, Vector2(7.0, -3.0)]]
	var t := 0.0
	var crowd: Crowd = mission._crowd
	while t <= 60.0:
		while not casts.is_empty() and t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			mission._rules.dp = Rules.DP_MAX
			mission._rules._cooldowns[int(c[1])] = 0.0
			mission._rules._playing = null
			mission._rules.cast(int(c[1]), c[2], {"dir": Vector2(1, 0.3).normalized()})
		var intents := {}
		for p: Person in crowd.citizens:
			if is_instance_valid(p) and p.state != DummyEnemy.State.DEAD:
				var k: String = Person.Intent.keys()[p.intent()]
				intents[k] = int(intents.get(k, 0)) + 1
		print("BEHAVIOUR escalate t=%d stage=%s alarm=%d bell=%s escaped=%d %s" % [roundi(t), crowd.alarms.stage_name(),
			roundi(crowd.alarm), crowd.alarms.bell_rung, crowd.escaped_count, intents])
		await _frames(5 * 60)
		t += 5.0
	for h in crowd.alarms.history:
		print("BEHAVIOUR stage at %.1f: %s (%s)" % [float(h[0]), AlarmManager.NAMES[h[1]], h[2]])


func _fire(shots: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var lit := 0
	for st in mission._bf.ctx.env.structures():
		if lit < 3 and st.kind == Structure.Kind.HOUSE and st.role == &"house" and st.center().distance_to(Vector2(-12, 3)) < 3.5:
			crowd.fires.ignite(st, 0.4)
			lit += 1
	var t := 0.0
	for mark in [2.0, 5.0, 10.0, 15.0, 20.0, 30.0, 40.0]:
		await _frames(roundi((mark - t) * 60.0))
		t = mark
		var parts := []
		var crew := 0
		for st in crowd.fires.fires.keys():
			parts.append("%.2f" % crowd.fires.intensity(st))
			crew += (crowd.fires.fires[st].responders as Array).size()
		var assisting := 0
		for p: Person in crowd.citizens:
			if is_instance_valid(p) and p.mind == Person.Mind.ASSIST:
				assisting += 1
		print("BEHAVIOUR fire t=%d fires=%d intensity=[%s] responders=%d stage=%s" % [roundi(t), crowd.fires.fires.size(),
			", ".join(parts), assisting, crowd.alarms.stage_name()])
		if shots and t == 10.0:
			var bf: Battlefield = mission._bf
			bf.camera.zoom = Vector2.ONE * 1.0
			bf.camera.position = Iso.ground_to_screen(Vector2(-12, 2.5)).round()
			await _frames(2)
			await bf.save_capture("behaviour_fire.png")


func _gates(hazard: bool, shots := false) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	crowd.alarms.bell_rung = true
	crowd.alarms.update(AlarmManager.CITY_ALARM, 0, crowd._clock)
	crowd.alarms._city_at = crowd._clock - AlarmManager.REGROUP_SECONDS
	crowd.add_alarm(100.0)
	var t := 0.0
	var placed := false
	for mark in [1.0, 5.0, 6.0, 10.0, 20.0, 30.0, 40.0]:
		await _frames(roundi((mark - t) * 60.0))
		t = mark
		if hazard and not placed and t >= 5.0:
			placed = true
			crowd.threats.register(Vector2(2.7, 11.5), 2.5, 0.8, 60.0, 8.0, 12.0, &"test")
		var by_exit := {}
		var rerouting := 0
		for p: Person in crowd.citizens:
			if not is_instance_valid(p) or p.state == DummyEnemy.State.DEAD or p.mind != Person.Mind.FLEE:
				continue
			var k := "south" if p.goal() == TownLayout.EXITS[0] else ("east" if p.goal() == TownLayout.EXITS[1] else "none")
			by_exit[k] = int(by_exit.get(k, 0)) + 1
			if p.intent() == Person.Intent.REROUTE:
				rerouting += 1
		var queues := []
		for g in crowd.evac.gates:
			queues.append(crowd.waiting_at(g))
		if shots and t == 10.0:
			var bf: Battlefield = mission._bf
			bf.camera.zoom = Vector2.ONE * 0.6
			bf.camera.position = Iso.ground_to_screen(Vector2(6.0, 9.0)).round()
			await _frames(2)
			await bf.save_capture("behaviour_gates.png")
		print("BEHAVIOUR gates t=%d by exit %s rerouting=%d queues(main,side)=%s escaped=%d" % [roundi(t), by_exit,
			rerouting, queues, crowd.escaped_count])


## Living citizens' intents, by distance band (ground units) from `at`.
func _bands(at: Vector2) -> String:
	var bands := [[0.0, 6.0], [6.0, 12.0], [12.0, 20.0], [20.0, 999.0]]
	var parts := []
	for b in bands:
		var counts := {}
		for p: Person in mission._crowd.citizens:
			if not is_instance_valid(p) or p.state == DummyEnemy.State.DEAD:
				continue
			var d := p.ground_pos.distance_to(at)
			if d >= float(b[0]) and d < float(b[1]):
				var k: String = Person.Intent.keys()[p.intent()]
				counts[k] = int(counts.get(k, 0)) + 1
		parts.append("%d-%d:%s" % [b[0], mini(int(b[1]), 99), counts])
	return " ".join(parts)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Citizens by the kind of place they are nearest (within 1.5 units), or "walking"/"elsewhere".
func _places() -> Dictionary:
	var anchors := TownLayout.anchors()
	var out := {}
	for p: Person in mission._crowd.citizens:
		if not is_instance_valid(p) or p.state == DummyEnemy.State.DEAD:
			continue
		var kind := "walking" if p.has_goal() else "elsewhere"
		if kind == "elsewhere":
			var best := 1.5
			for k in anchors:
				for g: Vector2 in anchors[k]:
					var d := g.distance_to(p.ground_pos)
					if d < best:
						best = d
						kind = k
		out[kind] = int(out.get(kind, 0)) + 1
	return out


func _checksum() -> int:
	var h := 17
	for p: Person in mission._crowd.citizens + mission._crowd.soldiers:
		if is_instance_valid(p):
			h = (h * 31 + roundi(p.ground_pos.x * 100.0)) % 1000000007
			h = (h * 31 + roundi(p.ground_pos.y * 100.0)) % 1000000007
			h = (h * 31 + int(p.mind)) % 1000000007
	return h
