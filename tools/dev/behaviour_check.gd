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
##   bell   a strike in the west after 20 s of calm; --kill-keeper kills the bellkeeper first (quietly): the Bell
##          Tower's state, the stage and the alarm every 2 s over 30 s
##   fire   three houses set burning in the west quarter after 20 s of calm: fires, intensity, responders over 40 s
##   rite   (Prepared) City Emergency called after 20 s of calm: the Banishing Rite's state, the ring, its progress and
##          the manifestation's clock every 5 s over 90 s; --interrupt quietly kills three of the ring's clergy 10 s
##          into the chant (as Silent Doom will): the rite breaks, and the rest regather after the cooldown
##   engineers  (Prepared) City Emergency called after 20 s of calm, then a Heaven Splitter on the Citadel and the
##          bridge brought down: the Citadel's health, the bridge and each team's job every 5 s over 60 s
##   boats  (Prepared) an evacuation called after 20 s of calm: evacuees by chosen way out (south road, east road,
##          dock), the boats' state, load and crowd, and escapes, over 40 s; --cut-bridge brings the bridge down at 5 s
##   quiet  (loadout Silent Doom, Blight, Heaven Splitter, Nuclear Nova) after 20 s of calm: Silent Doom on the
##          bellkeeper, Blight on the Bell Tower and on the Main Gate, then at 30 s a Heaven Splitter in the west: the
##          alarm, the stage, the bell and the dead every 5 s over 60 s; --shots photographs the rot and the doom
##   opening  (v0.05 M7) stealth against loud: the same four loud casts from 30 s (Heaven Splitter in the west and the
##          north-west, Cinderfall Barrage, Heaven Splitter at the Citadel), and with --quiet a quiet opening first at 20 s
##          (Silent Doom on the bellkeeper, Blight on the Bell Tower and the Main Gate): the alarm, the stage, the bell
##          and the escapes every 5 s over 100 s, then the stage history
##   siege  (v0.05 M7) one scripted siege for comparing the difficulty tiers (--difficulty=): eight casts over 105 s
##          from 20 s (the first in the west, clear of the Bell Tower), then a report every 15 s to 150 s -- escapes, the Citadel, the clock, the rite, the boats, the
##          engineers
##   clip   (v0.06) a power's preview clip for the draft, recorded in the town rather than the sandbox (whose dummy
##          troopers cannot be lured or confused): --power=<key> [--at=x,y] [--snap] [--seconds=s]
##          [--setup=rite|evac]; --snap aims at the citizen nearest --at (a whisper always does, and sends them
##          (2.2, -2.2) on, across the screen, the camera halfway: recorded with --at=0,11 --snap --seconds=8, the
##          open paving south of the market);
##          Prepared, the power in slot 1, cast after 20 s of calm (and the setup), PowerBook.CLIP_FRAMES frames over
##          its run into assets/clips/<key>.png
##   powers (v0.06) the new powers measured against doing without, Prepared, loadout wisp, thorns, discord,
##          pestilence; --case= one of:
##            plague / combo  Pestilence on the market crowd at 26 s, alone or after a Will-o'-Wisp there at 20 s:
##                            sick and dead every 10 s to 90 s
##            wall / nowall   an evacuation called at 20 s, and at 25 s a Thornwall across the Main Gate's mouth (or
##                            not): escapes by way out every 10 s to 60 s
##            discord / rite  City Emergency at 20 s, the rite chanting; at 35 s Discord on its ring (or not): the
##                            rite's state every 5 s to 90 s
##   soldiers (v0.07) each soldier role against doing without, --case= one of (Prepared):
##            each case first prints how many soldiers have the role (the "no" cases print 0: they prove themselves)
##            marshals / nomarshals  an evacuation called at 20 s: escapes by way out and the gates' queues every 10 s to 60 s
##            escort / noescort      the bellkeeper killed 3 s into its climb: the bell's state every 2 s to 50 s
##            rescue / norescue      the cathedral filled to its capacity, then it falls: trapped, saved, lost every 5 s to 80 s
##   judgement (v0.08) Last Judgement played greedily with the default loadout: from 5 s, each slot is cast the moment
##          its rules allow it, at the next of a fixed ring of targets closing on the Citadel; a report every 30 s,
##          then when the Citadel fell, the ending, escapes, buildings, the score and the DP left at the end (if any)
##   warning (v0.08 M5) The Warning played against its messenger, one case per Authority, --case= one of:
##            none       nothing cast (the bell should ring at about 0:25)
##            doom       Silent Doom on the messenger whenever nobody would see it (now, nor where he falls)
##            whisper    Mind Whisper: the running messenger sent 8 units straight back toward the gate
##            discord    Discord on the running messenger
##            thornwall  Thornwall across the street 3 units ahead of the running messenger
##            mix        Whisper, Discord and Silent Doom: Doom whenever he is alone, else Whisper and Discord in turn
##          each whenever its slot allows it (never forced), looked at every 0.1 s; a line for every cast and every
##          change of phase or messenger, a report every 5 s, then the ending, the relays, Unseen and "Solved by"
## --difficulty=<tier> plays any scenario at that tier (default Organized; rite, engineers and boats: Prepared).

const SEED := 7

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
	# A fixed seed (--seed=, default SEED): without a scripted flag the mission seeds itself from the clock.
	var seed_arg := Battlefield.arg_value(args, "--seed")
	var tier := Battlefield.arg_value(args, "--difficulty")
	if tier == "" and scenario in ["rite", "engineers", "boats", "clip", "powers", "soldiers"]:
		tier = "prepared"
	if tier != "":
		mission.difficulty = ResponseProfile.tier_named(tier)
	var powers := PackedStringArray()
	if scenario == "quiet":
		powers = PackedStringArray(["doom", "blight", "heaven", "nova"])
	elif scenario == "powers":
		powers = PackedStringArray(["wisp", "thorns", "discord", "pestilence"])
	elif scenario == "clip":
		powers = PackedStringArray([Battlefield.arg_value(args, "--power"), "heaven", "cinder", "nova"])
	elif scenario == "opening":
		powers = PackedStringArray(["doom", "blight", "heaven", "cinder"])
	elif scenario == "warning":
		var case_arg := Battlefield.arg_value(args, "--case")
		powers = PackedStringArray(WARNING_CASES.get(case_arg if case_arg != "" else "none", ["whisper"]))
		mission.mission_id = MissionBook.WARNING
	mission.start(powers, int(seed_arg) if seed_arg != "" else SEED)
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
		"bell":
			await _bell("--kill-keeper" in args, "--shots" in args)
		"rite":
			await _rite("--interrupt" in args, "--shots" in args)
		"engineers":
			await _engineers("--shots" in args)
		"boats":
			await _boats("--cut-bridge" in args, "--shots" in args)
		"quiet":
			await _quiet("--shots" in args)
		"opening":
			await _opening("--quiet" in args)
		"powers":
			await _powers(Battlefield.arg_value(args, "--case"))
		"soldiers":
			await _soldiers(Battlefield.arg_value(args, "--case"))
		"clip":
			await _clip(Battlefield.arg_value(args, "--power"), Battlefield.arg_value(args, "--at"),
				Battlefield.arg_value(args, "--seconds"), Battlefield.arg_value(args, "--setup"))
		"siege":
			await _siege()
		"gates":
			await _gates("--hazard" in args, "--shots" in args)
		"judgement":
			await _judgement()
		"warning":
			var case_arg := Battlefield.arg_value(args, "--case")
			await _warning(case_arg if case_arg != "" else "none")
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


func _bell(kill_keeper: bool, shots: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	if kill_keeper and crowd.bell.keeper != null:
		crowd._field.kill(crowd.bell.keeper, &"test")
	mission._rules.cast(0, Vector2(-10.0, 3.0), {"dir": Vector2(1, 0)})
	var t := 0.0
	var shot := false
	while t < 30.0:
		await _frames(2 * 60)
		t += 2.0
		var k: Person = crowd.bell.keeper
		var where := "-" if k == null or not is_instance_valid(k) else "%s mind=%s goal=%s foot=%.1f" % [k.ground_pos.round(),
			Person.Mind.keys()[k.mind], k.goal().round(), k.ground_pos.distance_to(crowd.bell.foot)]
		print("BEHAVIOUR bell t=%d state=%s progress=%.1f stage=%s alarm=%d rung=%s keeper %s" % [roundi(t),
			BellNetwork.State.keys()[crowd.bell.state], crowd.bell.progress, crowd.alarms.stage_name(), roundi(crowd.alarm),
			crowd.alarms.bell_rung, where])
		if shots and not shot and crowd.bell.state == BellNetwork.State.CLIMBING:
			shot = true
			var bf: Battlefield = mission._bf
			bf.camera.zoom = Vector2.ONE * 1.0
			bf.camera.position = (Iso.ground_to_screen(TownLayout.BELL_TOWER.get_center()) + Vector2(0, -20)).round()
			await _frames(2)
			await bf.save_capture("behaviour_bell.png")


func _rite(interrupt: bool, shots: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var rules: Rules = mission._rules
	crowd.add_alarm(AlarmManager.CITY_ALARM)
	var t := 0.0
	var struck := false
	var shot := false
	while t < 90.0:
		await _frames(5 * 60)
		t += 5.0
		var r := crowd.rite
		if interrupt and not struck and r.state == BanishingRite.State.CHANTING and r.progress >= 10.0:
			struck = true
			for e in r.circle.slice(0, 3):
				crowd._field.kill(e[0], &"test")
			r.step(0.0)
			print("BEHAVIOUR rite t=%d three of the clergy killed" % roundi(t))
		print("BEHAVIOUR rite t=%d state=%s ring=%d called=%d progress=%.1f clergy=%d cathedral=%d%% time_left=%.1f stage=%s" % [
			roundi(t), BanishingRite.State.keys()[r.state], r.in_ring(), r.circle.size(), r.progress, r.living_clergy(),
			roundi(100.0 * r.cathedral.hp / r.cathedral.max_hp) if is_instance_valid(r.cathedral) else 0, rules.time_left,
			crowd.alarms.stage_name()])
		if shots and not shot and r.state == BanishingRite.State.CHANTING and r.progress >= 5.0:
			shot = true
			var bf: Battlefield = mission._bf
			bf.camera.zoom = Vector2.ONE * 1.0
			bf.camera.position = (Iso.ground_to_screen(r.centre) + Vector2(0, -30)).round()
			await _frames(2)
			await bf.save_capture("behaviour_rite.png")


func _engineers(shots: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var rules: Rules = mission._rules
	var town: Town = mission._town
	crowd.add_alarm(AlarmManager.CITY_ALARM)
	rules.cast(0, town.citadel.origin, {"dir": Vector2(1, 0)})
	var bridge := town.bridge
	bridge.destroy(bridge.center(), &"nova")
	var e := crowd.engineers
	var t := 0.0
	var shots_taken := {}
	while t < 60.0:
		await _frames(5 * 60)
		t += 5.0
		var parts := []
		for team: Dictionary in e.teams:
			var job: Dictionary = team.job
			parts.append("standby" if job.is_empty() else "%s%s %d%%%s" % ["rebuild " if job.rebuild else "",
				EngineerManager.Job.keys()[job.type], roundi(100.0 * e.job_fraction(team)), " working" if team.working else ""])
		print("BEHAVIOUR engineers t=%d citadel=%.1f%% cap=%.0f%% bridge=%s teams=%s stage=%s" % [roundi(t),
			100.0 * town.citadel.fraction(), 100.0 * town.citadel.repair_cap() / town.citadel.max_health,
			"down" if bridge.destroyed else "standing", parts, crowd.alarms.stage_name()])
		if shots:
			for team: Dictionary in e.teams:
				var job: Dictionary = team.job
				if not team.working or job.is_empty():
					continue
				var name := "behaviour_engineers_%s.png" % ("rebuild" if job.rebuild else String(EngineerManager.Job.keys()[job.type]).to_lower())
				if shots_taken.has(name):
					continue
				shots_taken[name] = true
				var bf: Battlefield = mission._bf
				bf.camera.zoom = Vector2.ONE * 1.0
				bf.camera.position = (Iso.ground_to_screen(job.site) + Vector2(0, -40)).round()
				await _frames(2)
				await bf.save_capture(name)
	if shots:
		var bf: Battlefield = mission._bf
		bf.camera.position = (Iso.ground_to_screen(bridge.center()) + Vector2(0, -40)).round()
		await _frames(2)
		await bf.save_capture("behaviour_engineers_after.png")


func _boats(cut_bridge: bool, shots: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	crowd.alarms.bell_rung = true
	crowd.alarms.update(AlarmManager.CITY_ALARM, 0, crowd._clock)
	crowd.alarms._city_at = crowd._clock - AlarmManager.REGROUP_SECONDS
	crowd.add_alarm(100.0)
	var f := crowd.ferry
	var t := 0.0
	for mark in [1.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0]:
		await _frames(roundi((mark - t) * 60.0))
		t = mark
		if cut_bridge and t == 5.0:
			mission._town.bridge.destroy(mission._town.bridge.center(), &"nova")
		var by_exit := {}
		for p: Person in crowd.citizens:
			if not is_instance_valid(p) or p.state == DummyEnemy.State.DEAD or p.mind != Person.Mind.FLEE or p.inside:
				continue
			var k := "south" if p.goal() == TownLayout.EXITS[0] else ("east" if p.goal() == TownLayout.EXITS[1]
				else ("dock" if p.goal() == f.board_at else "none"))
			by_exit[k] = int(by_exit.get(k, 0)) + 1
		print("BEHAVIOUR boats t=%d by exit %s boats=%s aboard=%d waiting=%d trips=%d carried=%d escaped=%d bridge=%s" % [
			roundi(t), by_exit, RiverFerry.State.keys()[f.state], f.aboard.size(), f.waiting(), f.trips, f.carried,
			crowd.escaped_count, "down" if mission._town.bridge.destroyed else "up"])
		if shots and (t == 15.0 or t == 25.0):
			var bf: Battlefield = mission._bf
			bf.camera.zoom = Vector2.ONE * 1.0
			var at := f.board_at if t == 15.0 else TownLayout.POSTERN_AT
			bf.camera.position = (Iso.ground_to_screen(at) + Vector2(0, -30)).round()
			await _frames(2)
			await bf.save_capture("behaviour_boats.png" if t == 15.0 else "behaviour_postern.png")


func _quiet(shots: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var rules: Rules = mission._rules
	var gate: Structure = mission._town.gates[0]
	var keeper: Person = crowd.bell.keeper
	var casts := [[0.0, 0, keeper.ground_pos if keeper != null else Vector2.ZERO, "doom on the bellkeeper"],
		[2.0, 1, crowd.bell.tower.center(), "blight on the Bell Tower"],
		[4.0, 1, gate.center() - Vector2(0, 0.5), "blight on the Main Gate"],
		[10.0, 2, Vector2(-10.0, 3.0), "Heaven Splitter in the west"]]
	var t := 0.0
	var shot := {}
	var bf: Battlefield = mission._bf
	if shots:
		# The aim previews: Silent Doom rings who it would take, Blight outlines what it would ruin.
		for slot in [0, 1]:
			var aim_at: Vector2 = keeper.ground_pos if slot == 0 else crowd.bell.tower.center() + Vector2(0.6, 0.6)
			mission._aim.pick(slot)
			bf.camera.zoom = Vector2.ONE * 1.5
			bf.camera.position = (Iso.ground_to_screen(aim_at) + Vector2(0, -16)).round()
			await _frames(2)
			# The mission aims wherever the mouse is, every frame: put the mouse on the target.
			bf.get_viewport().warp_mouse(bf.get_viewport().get_canvas_transform() * Iso.ground_to_screen(aim_at))
			await _frames(3)
			await bf.save_capture("behaviour_aim_%s.png" % ["doom", "blight"][slot])
		mission._aim.unfocus()
	while t <= 60.0:
		while not casts.is_empty() and t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			rules._cooldowns[int(c[1])] = 0.0
			rules._playing = null
			rules.cast(int(c[1]), c[2], {"dir": Vector2(1, 0)})
			print("BEHAVIOUR quiet t=%.1f %s" % [t, c[3]])
			if shots and int(c[1]) == 0:
				bf.camera.zoom = Vector2.ONE * 1.5
				bf.camera.position = (Iso.ground_to_screen(c[2]) + Vector2(0, -16)).round()
				await _frames(roundi(SilentDoom.T_STRIKE * 60.0) - 6)
				await bf.save_capture("behaviour_doom.png")
		print("BEHAVIOUR quiet t=%.1f alarm=%.1f stage=%s bell=%s keeper=%s killed=%d threats=%d gate=%s" % [t,
			crowd.alarm, crowd.alarms.stage_name(), BellNetwork.State.keys()[crowd.bell.state],
			"alive" if is_instance_valid(keeper) and keeper.is_alive() else "dead", crowd.killed_citizens,
			crowd.threats.active_count(), "jammed" if gate.blighted else "open"])
		if shots and t >= 5.0 and not shot.has("rot"):
			shot["rot"] = true
			bf.camera.zoom = Vector2.ONE * 1.0
			bf.camera.position = (Iso.ground_to_screen(crowd.bell.tower.center()) + Vector2(0, -30)).round()
			await _frames(2)
			await bf.save_capture("behaviour_blight.png")
		var step := 2.0 if t < 4.0 else 5.0
		await _frames(roundi(step * 60.0))
		t += step


## Cast slot `slot` at `at` now, whatever its cooldown or another power still playing. `extra` joins the direction
## in the cast's extra (v0.08: a Mind Whisper's "to" and "target").
func _force_cast(slot: int, at: Vector2, dir := Vector2(1, 0), extra := {}) -> FxTimeline:
	var rules: Rules = mission._rules
	rules._cooldowns[slot] = 0.0
	rules._playing = null
	var all := {"dir": dir}
	all.merge(extra)
	return rules.cast(slot, at, all)


## A power's draft preview, recorded in the town: the camera close on the cast, the HUD hidden, CLIP_FRAMES frames
## spread over `seconds` (default: the effect's run), each the screen's middle at half size, as the sandbox's clips.
func _clip(key: String, at_arg: String, seconds_arg: String, setup: String) -> void:
	var at := Vector2(0.8, 2.0)
	if at_arg != "":
		var xy := at_arg.split(",")
		at = Vector2(float(xy[0]), float(xy[1]))
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	if setup == "rite":
		crowd.add_alarm(AlarmManager.CITY_ALARM)
		await _frames(20 * 60)
	elif setup == "evac":
		crowd.alarms.bell_rung = true
		crowd.alarms.update(AlarmManager.CITY_ALARM, 0, crowd._clock)
		crowd.alarms._city_at = crowd._clock - AlarmManager.REGROUP_SECONDS
		crowd.add_alarm(100.0)
		await _frames(10 * 60)
	# A Mind Whisper (v0.08) always snaps: it is cast on someone.
	var whisper := key == "whisper"
	var who: Person = null
	if "--snap" in OS.get_cmdline_user_args() or whisper:
		# Aim at the citizen nearest the point asked for (a queue forms where it will, not where it was guessed).
		var best := INF
		var near := at
		for p: Person in crowd.citizens:
			if is_instance_valid(p) and p.is_alive() and not p.inside and p.ground_pos.distance_to(at) < best:
				best = p.ground_pos.distance_to(at)
				near = p.ground_pos
				who = p
		at = near
	var extra := {}
	# The camera's ground point: the cast, or for a whisper halfway along the walk, so the walk stays in frame.
	var look := at
	if whisper:
		var to := MindWhisperFx.clamp_to(crowd._grid, at, at + Vector2(2.2, -2.2))
		extra = {"to": to, "target": who}
		look = at.lerp(to, 0.5)
	var bf: Battlefield = mission._bf
	mission._hud.visible = false
	bf.camera.zoom = Vector2.ONE * 1.5
	bf.camera.position = (Iso.ground_to_screen(look) + Vector2(0, -10 if whisper else -16)).round()
	bf.camera.reset_smoothing()
	await _frames(2)
	var fx := _force_cast(0, at, Vector2(1, 0), extra)
	var run := float(seconds_arg) if seconds_arg != "" else (fx.duration if fx != null else 4.0)
	var crop := PowerBook.CLIP_SIZE * 2
	var rows := ceili(float(PowerBook.CLIP_FRAMES) / PowerBook.CLIP_COLUMNS)
	var sheet := Image.create(PowerBook.CLIP_SIZE.x * PowerBook.CLIP_COLUMNS, PowerBook.CLIP_SIZE.y * rows, false,
		Image.FORMAT_RGBA8)
	var t := 0.0
	for i in PowerBook.CLIP_FRAMES:
		var due := run * (float(i) + 0.5) / float(PowerBook.CLIP_FRAMES)
		await _frames(maxi(roundi((due - t) * 60.0), 0))
		t = due
		await RenderingServer.frame_post_draw
		var img := bf.get_viewport().get_texture().get_image()
		var from := Vector2i((img.get_width() - crop.x) / 2, (img.get_height() - crop.y) / 2)
		var frame := img.get_region(Rect2i(from, crop))
		frame.convert(Image.FORMAT_RGBA8)
		frame.resize(PowerBook.CLIP_SIZE.x, PowerBook.CLIP_SIZE.y, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, PowerBook.CLIP_SIZE), Vector2i(PowerBook.clip_frame(i).position))
		if i == PowerBook.CLIP_FRAMES / 2 or i == PowerBook.CLIP_FRAMES - 1:
			_clip_report(key, at, t)
	var out := ProjectSettings.globalize_path(PowerBook.clip_path(key))
	sheet.save_png(out)
	print("BEHAVIOUR clip ", out)


func _opening(quiet: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var gate: Structure = mission._town.gates[0]
	var keeper: Person = crowd.bell.keeper
	var casts: Array = []
	if quiet:
		casts.append_array([[0.0, 0, keeper.ground_pos if keeper != null else Vector2.ZERO],
			[2.0, 1, crowd.bell.tower.center()], [4.0, 1, gate.center() - Vector2(0, 0.5)]])
	casts.append_array([[10.0, 2, Vector2(-10.0, 3.0)], [25.0, 2, Vector2(-9.0, -11.0)], [40.0, 3, Vector2(-9.0, 9.0)],
		[55.0, 2, Vector2(-10.5, -8.0)]])
	var t := 0.0
	while t <= 100.0:
		while not casts.is_empty() and t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			_force_cast(int(c[1]), c[2])
		if int(t) % 5 == 0:
			print("BEHAVIOUR opening t=%d alarm=%.1f stage=%s bell=%s escaped=%d alive=%d" % [roundi(t), crowd.alarm,
				crowd.alarms.stage_name(), BellNetwork.State.keys()[crowd.bell.state], crowd.escaped_count,
				crowd.alive_citizens()])
		await _frames(60)
		t += 1.0
	for h in crowd.alarms.history:
		print("BEHAVIOUR stage at %.1f: %s (%s)" % [float(h[0]), AlarmManager.NAMES[h[1]], h[2]])


func _siege() -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var rules: Rules = mission._rules
	var citadel: Citadel = mission._town.citadel
	var o := TownLayout.CITADEL_ORIGIN
	# The default loadout: heaven, tsunami, cinder, nova.
	if crowd.rite != null:
		crowd.rite.broken.connect(func(why: String) -> void: print("BEHAVIOUR siege rite broken: %s" % why))
		crowd.rite.ended.connect(func(why: String) -> void: print("BEHAVIOUR siege rite ended: %s" % why))
		crowd.rite.completed.connect(func() -> void: print("BEHAVIOUR siege rite completed"))
	var casts := [[0.0, 0, Vector2(-10.0, 3.0)], [15.0, 2, Vector2(-9.0, 5.0)], [30.0, 3, o], [45.0, 1, Vector2(5.0, -3.0)],
		[60.0, 0, o + Vector2(0.0, 2.5)], [75.0, 2, Vector2(10.0, 10.0)], [90.0, 3, o], [105.0, 0, Vector2(2.0, 12.0)]]
	var t := 0.0
	while t <= 130.0:
		while not casts.is_empty() and t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			_force_cast(int(c[1]), c[2], Vector2(1, 0.3).normalized())
		if int(t) % 15 == 0:
			var teams := []
			if crowd.engineers != null:
				for team: Dictionary in crowd.engineers.teams:
					teams.append("idle" if (team.job as Dictionary).is_empty() else String(EngineerManager.Job.keys()[team.job.type]).to_lower())
			print("BEHAVIOUR siege t=%d stage=%s alarm=%d escaped=%d alive=%d citadel=%.0f%% stability=%.0f%% clock=%s rite=%s boats=%d engineers=%s jobs=%d over=%s" % [
				roundi(t), crowd.alarms.stage_name(), roundi(crowd.alarm), crowd.escaped_count, crowd.alive_citizens(),
				100.0 * citadel.fraction(), 100.0 * rules.stability.total(), UiTheme.clock(rules.time_left),
				BanishingRite.State.keys()[crowd.rite.state] if crowd.rite != null else "-",
				crowd.ferry.carried if crowd.ferry != null else 0, teams,
				crowd.engineers.jobs().size() if crowd.engineers != null and crowd.engineers.active else -1, rules.over_reason])
		await _frames(60)
		t += 1.0
	for h in crowd.alarms.history:
		print("BEHAVIOUR stage at %.1f: %s (%s)" % [float(h[0]), AlarmManager.NAMES[h[1]], h[2]])


func _powers(which: String) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var market := Vector2(0.8, 2.0)
	match which:
		"plague", "combo":
			if which == "combo":
				_force_cast(0, market)
			await _frames(6 * 60)
			var at := _nearest_citizen(market)
			_force_cast(3, at)
			print("BEHAVIOUR powers %s pestilence at %s" % [which, at.round()])
			for k in 7:
				await _frames(10 * 60)
				print("BEHAVIOUR powers %s t=%d sick=%d plague_dead=%d alarm=%.1f stage=%s" % [which, 26 + 10 * (k + 1),
					crowd.plague.sick.size(), crowd.plague.deaths, crowd.alarm, crowd.alarms.stage_name()])
		"wall", "nowall":
			var by_exit := {}
			crowd.escaped.connect(func(p: Person) -> void:
				var k := "south" if p.goal() == TownLayout.EXITS[0] else ("east" if p.goal() == TownLayout.EXITS[1]
					else ("boat" if crowd.ferry != null and p.goal() == crowd.ferry.board_at else "other"))
				by_exit[k] = int(by_exit.get(k, 0)) + 1)
			crowd.alarms.bell_rung = true
			crowd.alarms.update(AlarmManager.CITY_ALARM, 0, crowd._clock)
			crowd.alarms._city_at = crowd._clock - AlarmManager.REGROUP_SECONDS
			crowd.add_alarm(100.0)
			await _frames(5 * 60)
			if which == "wall":
				_force_cast(1, Vector2(2.7, 14.25), Vector2(1, 0))
			for k in 4:
				await _frames(10 * 60)
				var queues := []
				for g in mission._town.gates:
					queues.append(crowd.waiting_at(g) if g.walkable else -1)
				print("BEHAVIOUR powers %s t=%d escaped=%d by way out %s queues(main,side,postern)=%s" % [which,
					25 + 10 * (k + 1), crowd.escaped_count, by_exit, queues])
		"discord", "rite":
			crowd.add_alarm(AlarmManager.CITY_ALARM)
			for k in 14:
				await _frames(5 * 60)
				var t := 25 + 5 * k
				if which == "discord" and t == 35:
					_force_cast(2, crowd.rite.centre)
				print("BEHAVIOUR powers %s t=%d rite=%s in_ring=%d progress=%.1f clock=%s" % [which, t,
					BanishingRite.State.keys()[crowd.rite.state], crowd.rite.in_ring(), crowd.rite.progress,
					UiTheme.clock(mission._rules.time_left)])


func _soldiers(which: String) -> void:
	var crowd: Crowd = mission._crowd
	var roles := {"marshals": Person.Corps.MARSHAL, "nomarshals": Person.Corps.MARSHAL, "escort": Person.Corps.ESCORT,
		"noescort": Person.Corps.ESCORT, "rescue": Person.Corps.RESCUE, "norescue": Person.Corps.RESCUE}
	if not roles.has(which):
		print("BEHAVIOUR soldiers: --case= one of %s" % [roles.keys()])
		return
	# The "no" cases take the role away from its soldiers: they keep v0.06's ways.
	if which.begins_with("no"):
		for p in crowd.soldiers:
			if p.corps == roles[which]:
				p.corps = Person.Corps.NONE
		if which == "norescue":
			crowd.rescue.squads.clear()
	var in_role := 0
	for p in crowd.soldiers:
		if p.corps == roles[which]:
			in_role += 1
	print("BEHAVIOUR soldiers %s t=0 %s soldiers=%d%s" % [which, String(Person.Corps.keys()[roles[which]]).to_lower(),
		in_role, " squads=%d" % crowd.rescue.squads.size() if which.ends_with("rescue") else ""])
	await _frames(20 * 60)
	match which:
		"marshals", "nomarshals":
			# Escapes by the way out each took (as the powers scenario's wall case names them).
			var by_exit := {}
			crowd.escaped.connect(func(p: Person) -> void:
				var k := "south" if p.goal() == TownLayout.EXITS[0] else ("east" if p.goal() == TownLayout.EXITS[1]
					else ("boat" if crowd.ferry != null and p.goal() == crowd.ferry.board_at else "other"))
				by_exit[k] = int(by_exit.get(k, 0)) + 1)
			crowd.alarms.bell_rung = true
			crowd.alarms.update(AlarmManager.CITY_ALARM, 0, crowd._clock)
			crowd.alarms._city_at = crowd._clock - AlarmManager.REGROUP_SECONDS
			crowd.add_alarm(100.0)
			for k in 4:
				await _frames(10 * 60)
				var queues := []
				for g in mission._town.gates:
					queues.append(crowd.waiting_at(g) if g.walkable else -1)
				print("BEHAVIOUR soldiers %s t=%d escaped=%d by way out %s queues(main,side,postern)=%s" % [which,
					20 + 10 * (k + 1), crowd.escaped_count, by_exit, queues])
		"escort", "noescort":
			crowd.alarms.stage = AlarmManager.Stage.CONCERN
			crowd._on_stage(AlarmManager.Stage.LOCAL_EMERGENCY, "test")
			var killed := false
			# Stepped by half seconds so that the kill falls on a set point of the climb; a line every 2 s.
			for k in 60:
				await _frames(30)
				var bell := crowd.bell
				if not killed and bell.state == BellNetwork.State.CLIMBING and bell.progress >= 3.0:
					killed = true
					var near := INF
					for g in crowd.escorts.guards.get("bell", []):
						if is_instance_valid(g):
							near = minf(near, g.ground_pos.distance_to(bell.keeper.ground_pos))
					crowd._field.kill(bell.keeper, &"test")
					print("BEHAVIOUR soldiers %s t=%.1f the bellkeeper killed %.1f s into its climb, nearest escort %s" % [
						which, 20.0 + 0.5 * float(k + 1), bell.progress, ("%.1f away" % near) if near < INF else "none"])
				if k % 4 != 3:
					continue
				var who := "none"
				if is_instance_valid(bell.keeper):
					who = "dead" if not bell.keeper.is_alive() else ("soldier" if bell.keeper.soldier else "citizen")
				print("BEHAVIOUR soldiers %s t=%d bell=%s progress=%.1f keeper=%s rung=%s" % [which, 20 + 2 * ((k + 1) / 4),
					BellNetwork.State.keys()[bell.state], bell.progress, who, crowd.alarms.bell_rung])
			if not killed:
				print("BEHAVIOUR soldiers %s no kill: the bell never climbed" % which)
		"rescue", "norescue":
			var cathedral: Structure = null
			for s in crowd.shelters.shelters.keys():
				if s.role == &"temple" and s.art_tag == &"cathedral":
					cathedral = s
			# Citizens taken into the cathedral, up to its capacity, as if they had run there, then it falls (the
			# collapse's usual consequences follow). `crushed` counts those of them the collapse killed outright.
			var sheltered := []
			for p in crowd.citizens:
				if sheltered.size() < ShelterManager.capacity(cathedral) and p.is_alive() and not p.inside:
					crowd.shelters._enter(p, cathedral)
					(crowd.shelters.shelters[cathedral].inside as Array).append(p)
					sheltered.append(p)
			print("BEHAVIOUR soldiers %s t=20 %d sheltered in the cathedral, then it falls" % [which, sheltered.size()])
			cathedral.destroy(cathedral.center(), &"nova")
			for k in 12:
				await _frames(5 * 60)
				var dead := 0
				for p in sheltered:
					if not is_instance_valid(p) or not p.is_alive():
						dead += 1
				print("BEHAVIOUR soldiers %s t=%d trapped=%d saved=%d lost=%d crushed=%d" % [which, 20 + 5 * (k + 1),
					crowd.rescue.trapped.size(), crowd.rescue.rescued, crowd.rescue.died, dead - crowd.rescue.died])


func _nearest_citizen(at: Vector2) -> Vector2:
	var best := INF
	var near := at
	for p: Person in mission._crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and not p.inside and p.ground_pos.distance_to(at) < best:
			best = p.ground_pos.distance_to(at)
			near = p.ground_pos
	return near


## What the power is doing halfway through its clip, for the record.
func _clip_report(key: String, at: Vector2, t: float) -> void:
	var crowd: Crowd = mission._crowd
	var near := 0
	var watching := 0
	for p: Person in crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and p.ground_pos.distance_to(at) <= 2.5:
			near += 1
			if p.mind == Person.Mind.OBSERVE:
				watching += 1
	var queues := []
	for g in mission._town.gates:
		queues.append(crowd.waiting_at(g) if g.walkable else -1)
	var confused := 0
	for p: Person in crowd.citizens:
		if is_instance_valid(p) and p.mind == Person.Mind.CONFUSED:
			confused += 1
	print("BEHAVIOUR clip %s t=%.1f within 2.5: %d citizens, %d watching; confused=%d sick=%d plague_dead=%d alarm=%.1f threats=%d queues(main,side,postern)=%s escaped=%d" % [
		key, t, near, watching, confused, crowd.plague.sick.size() if crowd.plague != null else 0,
		crowd.plague.deaths if crowd.plague != null else 0, crowd.alarm, crowd.threats.active_count(), queues,
		crowd.escaped_count])


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


## The judgement scenario's targets, cast in turn (v0.08): a ring closing on the Citadel.
const JUDGEMENT_TARGETS := [Vector2(-9.0, -11.0), Vector2(0.8, 2.2), Vector2(-12.0, 1.0), Vector2(-4.0, -6.0),
	TownLayout.CITADEL_ORIGIN, Vector2(-6.0, -12.0), Vector2(4.0, -4.0), Vector2(-10.5, -8.0)]
## A cap on the judgement scenario's frames, so a run ends even if the mission does not: twice the mission's clock.
const JUDGEMENT_MAX_FRAMES := int(Rules.MISSION_SECONDS * 2.0 * 60.0)


## Written only against what exists both before and after v0.08 M2 (refusal(), cast(), loadout, an optional `dp`),
## so the same scenario measures both sides of the change. `t` is game time, the mission's own seconds: a hit's
## hit-stop slows Engine.time_scale, so counting frames alone would run ahead of the mission's clock.
func _judgement() -> void:
	var rules: Rules = mission._rules
	var town: Town = mission._town
	var fell_at := -1.0
	var next := 0
	var t := 0.0
	var frames := 0
	var report_at := 30.0
	while not rules.finished and frames < JUDGEMENT_MAX_FRAMES:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		if t < 5.0 or frames % 6 != 0:
			continue
		for slot in rules.loadout.size():
			if rules.refusal(slot) == "":
				var at: Vector2 = JUDGEMENT_TARGETS[next % JUDGEMENT_TARGETS.size()]
				next += 1
				rules.cast(slot, at, {"dir": Vector2(0.2, 1.0).normalized()})
				break
		if fell_at < 0.0 and town.citadel.is_fallen():
			fell_at = t
		if t >= report_at:
			report_at += 30.0
			print("BEHAVIOUR judgement t=%d citadel=%d%% stability=%d%% escaped=%d buildings=%d stage=%s" % [
				roundi(t), roundi(town.citadel.fraction() * 100.0), roundi(rules.stability.total() * 100.0),
				mission._crowd.escaped_count, rules.buildings_down, mission._crowd.alarms.stage_name()])
	if fell_at < 0.0 and town.citadel.is_fallen():
		fell_at = t
	var dp_left: Variant = rules.get("dp")
	print("BEHAVIOUR judgement end t=%.1f citadel_fell=%.1f won=%s reason=%s escaped=%d buildings=%d score=%d rank=%s dp_left=%s" % [
		t, fell_at, rules.won, rules.over_reason, mission._crowd.escaped_count, rules.buildings_down, rules.score(),
		rules.rank(), str(dp_left)])


## The warning scenario's loadout for each case (v0.08 M5). "none" drafts Mind Whisper and never casts it: an empty
## loadout would fall back to the mission's default, and the HUD has no look for an empty slot.
const WARNING_CASES := {"none": ["whisper"], "doom": ["doom"], "whisper": ["whisper"], "discord": ["discord"],
	"thornwall": ["thorns"], "mix": ["whisper", "discord", "doom"]}
## How far straight back toward the gate the whisper sends the messenger.
const WARNING_WHISPER_BACK := 8.0
## How far ahead of the messenger, along his way, the Thornwall grows across his street.
const WARNING_THORN_AHEAD := 3.0


## The Warning, played by one policy against the director's messenger (whoever carries the warning now: the
## watchman, a relay's witness, or the keeper once told). Every cast goes through Rules.cast() with what the real aim
## would give it, and only when the slot allows it. `t` is game time, as in _judgement().
func _warning(which: String) -> void:
	var rules: Rules = mission._rules
	var crowd: Crowd = mission._crowd
	var director := rules.director as WarningDirector
	var slots := {}
	for slot in rules.loadout.size():
		if rules.key(slot) != "":
			slots[rules.key(slot)] = slot
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	var casts := {}
	var last_delay := ""  # mix: the power that last held him, so the other goes next
	var t := 0.0
	var frames := 0
	var report_at := 5.0
	var seen_phase := -1
	var seen_messenger: Person = null
	while not rules.finished and frames < max_frames:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		if director.phase != seen_phase or director.messenger != seen_messenger:
			seen_phase = director.phase
			seen_messenger = director.messenger
			print("BEHAVIOUR warning t=%.1f event phase=%s messenger=%s relays=%d" % [t,
				WarningDirector.Phase.keys()[director.phase], _warning_who(director.messenger, crowd), director.relays])
		if t >= report_at:
			report_at += 5.0
			print("BEHAVIOUR warning t=%d phase=%s messenger_mind=%s relays=%d bell=%s stage=%s" % [roundi(t),
				WarningDirector.Phase.keys()[director.phase], _warning_mind(director.messenger), director.relays,
				BellNetwork.State.keys()[crowd.bell.state] if crowd.bell != null else "none",
				crowd.alarms.stage_name()])
		if frames % 6 != 0 or which == "none":
			continue
		var m := director.messenger
		if not is_instance_valid(m) or not m.is_alive() or director.warning_dead:
			continue
		var running := m.mind == Person.Mind.DUTY
		var key := ""
		var at := m.ground_pos
		var extra := {}
		if slots.has("doom") and rules.refusal(slots.doom) == "" and _warning_alone(m, crowd):
			key = "doom"
		elif running:
			var order := ["whisper", "discord", "thorns"]
			if which == "mix" and last_delay == "whisper":
				order = ["discord", "whisper"]
			for k: String in order:
				if slots.has(k) and rules.refusal(slots[k]) == "":
					key = k
					break
		if key == "":
			continue
		match key:
			"whisper":
				var back := director.gate_spot - m.ground_pos
				if back.length() < 0.5:
					back = -_warning_heading(m)
				var to := MindWhisperFx.clamp_to(crowd._grid, m.ground_pos,
					m.ground_pos + back.normalized() * WARNING_WHISPER_BACK)
				extra = {"to": to, "target": m}
			"thorns":
				var ahead := _warning_ahead(m, WARNING_THORN_AHEAD)
				at = ahead[0]
				var h: Vector2 = ahead[1]
				extra = {"dir": Vector2(-h.y, h.x)}
		if rules.cast(slots[key], at, extra) != null:
			casts[key] = int(casts.get(key, 0)) + 1
			if key in ["whisper", "discord"]:
				last_delay = key
			var sent := (" to %s" % (extra.to as Vector2).snapped(Vector2(0.1, 0.1))) if extra.has("to") else ""
			print("BEHAVIOUR warning t=%.1f cast %s at %s on %s (%s)%s" % [t, key, at.snapped(Vector2(0.1, 0.1)),
				_warning_who(m, crowd), _warning_mind(m), sent])
	var res := rules.result()
	var unseen := false
	for b: Dictionary in res.bonuses:
		unseen = unseen or bool(b.earned)
	print("BEHAVIOUR warning end case=%s won=%s reason=%s time=%.1f relays=%d unseen=%s solved_by=%s casts=%s" % [
		which, rules.won, rules.over_reason, float(res.time), int(res.get("relays", 0)), unseen,
		",".join(res.get("solved_by", PackedStringArray())), casts])


## Nobody would see Silent Doom take the person: nobody within Crowd.DOOM_WITNESS of them now, nor of where they will
## have run to when it strikes (SilentDoom.T_STRIKE on, along their way) -- the victims are fixed at the cast, but the
## witnesses are judged where they fall.
func _warning_alone(p: Person, crowd: Crowd) -> bool:
	var lead := _warning_heading(p) * p.walk_speed * SilentDoom.T_STRIKE if p.has_goal() else Vector2.ZERO
	return crowd.nearest_witness(p.ground_pos, p) == null and crowd.nearest_witness(p.ground_pos + lead, p) == null


## Who carries the warning, for the scenario's lines: the watchman, the keeper, or a citizen's (soldier's) index.
func _warning_who(p: Person, crowd: Crowd) -> String:
	if not is_instance_valid(p):
		return "none"
	if crowd.bell != null and p == crowd.bell.keeper:
		return "keeper"
	if p.profile != null and p.profile.role == CitizenProfile.Role.WATCHMAN:
		return "watchman"
	return ("soldier#%d" % crowd.soldiers.find(p)) if p.soldier else ("citizen#%d" % crowd.citizens.find(p))


func _warning_mind(p: Person) -> String:
	if not is_instance_valid(p) or not p.is_alive():
		return "DEAD"
	return Person.Mind.keys()[p.mind]


## Which way the person is heading: toward the waypoint it is walking to, else its goal, else (1, 0).
func _warning_heading(p: Person) -> Vector2:
	var next := p._target if p._target.distance_to(p.ground_pos) > 0.05 else p.goal()
	var h := next - p.ground_pos if next != Vector2.INF else Vector2.ZERO
	return h.normalized() if h.length() > 0.01 else Vector2(1, 0)


## The point `ahead` units on along the person's way (its waypoint, then the rest of its path), and the way the path
## runs there.
func _warning_ahead(p: Person, ahead: float) -> Array:
	var pts := PackedVector2Array([p._target])
	for i in range(p._leg, p._path.size()):
		pts.append(p._path[i])
	var from := p.ground_pos
	var left := ahead
	var h := _warning_heading(p)
	for q in pts:
		var span := q - from
		if span.length() < 0.01:
			continue
		h = span.normalized()
		if span.length() >= left:
			return [from + h * left, h]
		left -= span.length()
		from = q
	return [from + h * left, h]


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
