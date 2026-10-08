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
##          engineers ("fire" for a team at a fire), the fires burning, burned down and doused, the buildings down;
##          --burn (v0.08.2) makes it fire-heavy: BURN_HOUSES standing houses set burning at 30 s and again at 60 s
##          (the houses the casts leave whole only ever burn this way: every fire-kind hit kills a house outright)
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
##          then when the Citadel fell, the ending, escapes, buildings, the score and the DP left at the end (if any);
##          `--aim=rich` (v0.10 M5) aims each cast as Act III's caster does (_richest()); the start line prints the
##          loadout's cost against the campaign's Night 4 budget (12 DP, 6 slots).
##   miras  (v0.10 M2) Mira's House, --case=none (nothing cast) or play (whisper the grieving in when nobody of the
##          Faith watches the door; Discord on the nearest watcher).
##   lanterns  (v0.10 M3) Broken Lanterns, --case=none (nothing cast) or play (Heaven Splitter, Dragonfire Parade and
##          Silent Doom: lay the Splitter through two shrines where it can, else one, crossing the fewest people; doom
##          the called bellkeeper and the flame-bearer while a shrine drains; the Parade only when the Splitter would
##          come too late for dawn), or bonus (play, but the last shrine is struck only once ten kneel by it, or
##          when dawn would come too soon to wait). --seed= picks the town.
##   flame  (v0.10 M4) The Vigil Flame, --case=none (nothing cast) or play (Mind Whisper, Discord, Will-o'-Wisp: a wisp
##          to draw bystanders off the lantern, one Discord on the bearer and the acolytes, then Wren whispered to it;
##          with the flame, reading the beams' paths ahead, a wisp to draw off a beam coming at him, else a whisper
##          out of its way; Discord at the Temple's door in the last 20 s). --seed= picks the town.
##   feast  (v0.10 M5) the campaign's Night 3 alone, at its 4 slots and 10 DP: `--path=festival|procession` (the
##          Festival unless it says the Procession), `--bell=rang` for a town Night 1 warned, `--case=none` (nothing cast)
##          or `play` (the night's act policy, as `night --act2=play`). It drafts NIGHT_LOADOUTS[path], or `--loadout=`.
##          Prints the loadout's cost against the budget, then the result. --seed= picks the town.
##   warning (v0.08 M5) The Warning played against its messenger, one case per Authority, --case= one of:
##            none       nothing cast (the bell should ring at about 0:25)
##            doom       Silent Doom on the messenger whenever nobody would see it (now, nor where he falls)
##            whisper    Mind Whisper: the running messenger sent 8 units straight back toward the gate
##            discord    Discord on the running messenger
##            mix        Whisper, Discord and Silent Doom: Doom whenever he is alone, else Whisper and Discord in turn
##          each whenever its slot allows it (never forced), looked at every 0.1 s -- and Mind Whisper only while the
##          messenger is not shaking the last one off (v0.08.1: the aim rings him red); a line for every cast and every
##          change of phase or messenger, a report every 5 s, then the ending, the relays, Unseen and "Solved by".
##          v0.08.1 left Thornwall out of The Warning's pool, and its case with it; any other case is refused.
##   tax    (v0.11 M2) The Tax Collector (three collectors, one after another), --case=none (nothing cast) or play (Silent
##          Doom on the bellkeeper once called; else Silent Doom on the first collector in the street with nobody but those
##          who would fall with him near enough to see it; else Mind Whisper sends a lone onlooker away). --seed= picks the
##          town; --board plays the board's version (its wishes heard) and stops at the main objective.
##   harvest  (v0.11 M2) Spoiled Harvest, --case=none or play (the granaries with their grain in, fewest loads first: Silent
##          Doom on a watchman on guard, then Ember on the granary; spare time, Silent Doom on the watchmen of the next
##          granary when its grain is due within HARVEST_PRE; with nothing else, Silent Doom on a carter walking to a granary
##          with two loads or fewer left). --seed=, --board as tax.
##   night  (v0.09) The Long Night forced through its acts: `--path=festival|procession`, `--act1=win|lose|skip`,
##          `--act2=…`, `--act3=…`; each act ends as asked (skip lets it run to its clock); prints each act's result, the
##          town's tier at each act's start, and the night's result. Before the first handover the time scale is dipped
##          to 0.3 and a Heaven Splitter is still falling: the next act must start at 1.0 with nothing credited,
##          every cooldown ready and no power still playing (a `handover` line). `--prince=unseen|seen|escaped` is a test aid (v0.09 Task 8):
##          it overwrites what the Procession decided, once Act II-B is over, so Act III's town can be raised by any
##          outcome even when the act was ended by force. `--festival=broken|held` is a test aid (v0.09): it
##          overwrites what the Festival decided, once Act II-A is over, so Act III's town can be raised by any outcome
##          even when the act was ended by force. `--shots` (v0.09
##          Task 13) photographs Act II-A's market at 30, 50 and 95 s into it (captures/behaviour_festival_<s>.png, and
##          the Mayor close up at 95 s; Task 16: Act II-B's blessing and dock at 65 and 125 s,
##          captures/behaviour_procession_<s>.png); `--calm-handover` skips the dipped time scale and the falling Heaven Splitter,
##          so Act II starts in a quiet town (for photographs). `--act1|2|3=play` (Task 18) plays that act with a scripted
##          policy instead of forcing it (see the NIGHT_LOADOUTS and _play_act()): Act I the Warning's mix, the Festival
##          Silent Doom on the Mayor at 95 s then Discord on the densest cluster, the Procession Doom on the Prince when
##          nobody would see it (`--doom-seen` also dooms him, seen, on the dock's leg), Act III the greedy Last Judgement
##          caster; each act is drafted its own loadout. A played night skips the handover aid (its Heaven Splitter would fall
##          on the Prince at the Citadel's door). Task 19: Act III's caster aims each cast where it takes the most of
##          what City Stability still counts (_richest(); `--act3-aim=fixed` keeps Task 18's eight fixed targets), and
##          `--act3-loadout=a,b,c` drafts Act III other powers; its reports carry stability's parts and the act's
##          escapes, and the Procession's end line counts the looks with no soldier, and nobody, within the witness
##          distance.
## --difficulty=<tier> plays any scenario at that tier (default Organized; rite, engineers and boats: Prepared).

const SEED := 7
## How many houses `siege --burn` sets burning each time (v0.08.2).
const BURN_HOUSES := 6

## Seconds into Act II-A that `night --shots` photographs, and the ground point it looks at (the fountain).
const FESTIVAL_SHOTS := [30.0, 50.0, 95.0]
const FESTIVAL_LOOK_AT := Vector2(1.0, 4.0)
## Seconds into Act II-B that `night --shots` photographs (the blessing, the dock), the zoom, and how far from the Prince
## towards the boarding point the camera looks (0 on him, 1 at the ship).
const PROCESSION_SHOTS := [[65.0, 2.5, 0.0], [125.0, 1.6, 0.6]]

## What each act drafts when `night` plays it (v0.09 Task 18), simulating Prepare's re-draft between acts (each fits its
## act's slots and DP, v0.09.1: Act I 3 / 6, Act II 4 / 10, Act III 4 / 14). Act I's is the Warning's mix (3 DP); the
## Festival needs only the Mayor's Doom and a Discord (3 DP); the Procession adds a Mind Whisper (4 DP); Act III is the
## four heaviest it can afford (Task 19: Heaven Splitter, Nuclear Nova, Judgement of the Ancients, Cinderfall Barrage:
## 2 + 4 + 4 + 4 = 14 DP).
const NIGHT_LOADOUTS := {"omen": ["whisper", "doom", "discord"], "festival": ["doom", "discord"],
	"procession": ["whisper", "doom", "discord"], "judgement": ["heaven", "nova", "judgement", "cinder"]}
## The Festival's Silent Doom on the Mayor is cast from this second of the act (inside his address, 90 s to 120 s).
const FESTIVAL_DOOM_AT := 95.0
## How far Mind Whisper sends an attendant of the Prince's from him (the Procession's policy), in ground units.
const PROCESSION_SENT := 8.0
## Act III's aim (Task 19, _richest()): how far round a point counts (ground units).
const RICH_R := 3.0
## A policy looks at the town every this many frames (0.1 s at 60 fps), as the Warning's does.
const LOOK_FRAMES := 6
## The tax policy's margin beyond Crowd.DOOM_WITNESS for an onlooker's walk (v0.11 M2, _tax_unseen()).
const TAX_MARGIN := 0.2
## The harvest policy clears the next granary's watchmen when its grain is due within this many seconds (v0.11 M2): sooner, the relief
## (HarvestDirector.RELIEF_AFTER) walks in before the fire has burned its 10 s.
const HARVEST_PRE := 20.0
## The Broken Lanterns policy (v0.10 M3): how far round a shrine counts the people a Dragonfire Parade there would burn.
const LANTERN_CROWD_R := 3.0
## The Heaven Splitter the policy lays (its line's reach and width, its core), the farthest apart two shrines may stand
## for one line to break both, and how many directions it weighs for a single shrine (over a half turn: the line runs
## both ways).
const HEAVEN_FX := preload("res://src/fx/set2/heaven_splitter.gd")
const LANTERN_PAIR_REACH := 9.0
const LANTERN_DIRS := 8
## The Dragonfire Parade burns a street, so the policy sends it only when the Splitter would come too late for the shrine
## it breaks to drain before dawn, with this many seconds to spare.
const LANTERN_DRAGON_SPARE := 5.0
## `bonus` waits for the kneelers only while the night still leaves this many seconds beyond a drain and that spare.
const LANTERN_BONUS_SPARE := 10.0
## The Vigil Flame policy (v0.10 M4): how near the lantern a Faithful counts as a watcher of the swap (Crowd.DOOM_WITNESS
## and a margin for his walk), how far from the Temple's door Wren must be for its Discord (its searching beam must not
## find him), and how far the policy moves him, or a wisp from a beam.
const FLAME_WATCH_R := 3.0
const FLAME_DANGER := 4.5
const FLAME_DODGE := 5.0
## Bystanders this near the lantern, going about their day, could wander into the swap: a wisp FLAME_STRAY_LURE beyond
## them (well within its reach of them all) draws them off first.
const FLAME_STRAY_R := 5.0
const FLAME_STRAY_LURE := 3.0
## The carry reads the beams' paths ahead: FLAME_LOOKAHEAD seconds for a beam coming onto Wren (within POOL_R and
## FLAME_MARGIN), FLAME_PLAN for where a whisper sends him (his walk there and his linger), in FLAME_STEP steps; it
## weighs FLAME_DIRS spots round him (or round the beam, for a wisp).
const FLAME_LOOKAHEAD := 3.0
const FLAME_MARGIN := 1.0
const FLAME_PLAN := 12.0
const FLAME_STEP := 0.5
const FLAME_DIRS := 8
## How far inside Discord's reach the policy keeps those it means to take, for their walk while the cast lands.
const FLAME_DISCORD_MARGIN := 0.2
## The campaign's Night 3 (v0.10 M5, spec §4.2): its slots, and the budget of a run that won Nights 1 and 2 with no bonus.
const FEAST_SLOTS := 4
const FEAST_DP := CampaignDef.START_DP + 2 * CampaignDef.WIN_DP
## Night 4, Last Judgement in the campaign (spec §4.3): its slots, and the budget of a run that won Nights 1-3, no bonus.
const FINALE_SLOTS := 6
const FINALE_DP := CampaignDef.START_DP + 3 * CampaignDef.WIN_DP

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
	elif scenario == "miras":
		powers = PackedStringArray(["whisper", "doom", "discord"])
		mission.mission_id = MissionBook.MIRAS_HOUSE
	elif scenario == "lanterns":
		powers = PackedStringArray(["heaven", "dragon", "doom"])
		mission.mission_id = MissionBook.BROKEN_LANTERNS
	elif scenario == "flame":
		powers = PackedStringArray(["whisper", "discord", "wisp"])
		mission.mission_id = MissionBook.VIGIL_FLAME
	elif scenario == "feast":
		var wanted := Battlefield.arg_value(args, "--loadout")
		powers = PackedStringArray(wanted.split(",")) if wanted != "" else PackedStringArray(NIGHT_LOADOUTS[_feast_path()])
		mission.mission_id = "feast_" + _feast_path()
		mission.bell_rang = Battlefield.arg_value(args, "--bell") == "rang"
	elif scenario == "night":
		powers = PackedStringArray(["whisper", "doom", "discord"])
		mission.mission_id = MissionBook.LONG_NIGHT
	elif scenario == "tax":
		powers = PackedStringArray(["doom", "whisper", "discord"])
		mission.mission_id = MissionBook.TAX_COLLECTOR
	elif scenario == "harvest":
		powers = PackedStringArray(["ember", "doom", "discord"])
		mission.mission_id = MissionBook.SPOILED_HARVEST
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
			await _siege("--burn" in args)
		"gates":
			await _gates("--hazard" in args, "--shots" in args)
		"judgement":
			await _judgement()
		"miras":
			await _miras(Battlefield.arg_value(args, "--case"))
		"lanterns":
			await _lanterns(Battlefield.arg_value(args, "--case"))
		"flame":
			await _flame(Battlefield.arg_value(args, "--case"))
		"feast":
			await _feast(Battlefield.arg_value(args, "--case"))
		"night":
			await _night()
		"tax":
			await _tax(Battlefield.arg_value(args, "--case"))
		"harvest":
			await _harvest(Battlefield.arg_value(args, "--case"))
		"warning":
			var case_arg := Battlefield.arg_value(args, "--case")
			if WARNING_CASES.has(case_arg if case_arg != "" else "none"):
				await _warning(case_arg if case_arg != "" else "none")
			else:
				print("BEHAVIOUR warning no case=%s (cases: %s; Thornwall is not in The Warning's pool since v0.08.1)"
					% [case_arg, ", ".join(WARNING_CASES.keys())])
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


func _siege(burn: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var rules: Rules = mission._rules
	var citadel: Citadel = mission._town.citadel
	var o := TownLayout.CITADEL_ORIGIN
	# The default loadout: heaven, tsunami, cinder, nova.
	# The time now, for the rite's lines (a lambda keeps a copy of a local float, not the variable).
	var now := [0.0]
	var ended := false
	if crowd.rite != null:
		crowd.rite.broken.connect(func(why: String) -> void: print("BEHAVIOUR siege t=%d rite broken: %s" % [roundi(now[0]), why]))
		crowd.rite.ended.connect(func(why: String) -> void: print("BEHAVIOUR siege t=%d rite ended: %s" % [roundi(now[0]), why]))
		crowd.rite.completed.connect(func() -> void: print("BEHAVIOUR siege t=%d rite completed" % roundi(now[0])))
	var casts := [[0.0, 0, Vector2(-10.0, 3.0)], [15.0, 2, Vector2(-9.0, 5.0)], [30.0, 3, o], [45.0, 1, Vector2(5.0, -3.0)],
		[60.0, 0, o + Vector2(0.0, 2.5)], [75.0, 2, Vector2(10.0, 10.0)], [90.0, 3, o], [105.0, 0, Vector2(2.0, 12.0)]]
	var t := 0.0
	while t <= 130.0:
		while not casts.is_empty() and t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			_force_cast(int(c[1]), c[2], Vector2(1, 0.3).normalized())
		if burn and (t == 10.0 or t == 40.0):
			var lit := 0
			var k := 0
			for st in mission._bf.ctx.env.structures():
				if st.kind == Structure.Kind.HOUSE and st.role == &"house" and not st.destroyed \
						and not crowd.fires.is_burning(st):
					k += 1
					if k % 5 == 0 and lit < BURN_HOUSES:
						crowd.fires.ignite(st, 0.4)
						lit += 1
			print("BEHAVIOUR siege t=%d set %d houses burning" % [roundi(t), lit])
		if int(t) % 15 == 0:
			var teams := []
			if crowd.engineers != null:
				for team: Dictionary in crowd.engineers.teams:
					var at_fire := false
					for m in team.members:
						at_fire = at_fire or (is_instance_valid(m) and (m as Person).mind == Person.Mind.ASSIST)
					teams.append(("fire" if at_fire else "idle") if (team.job as Dictionary).is_empty()
						else String(EngineerManager.Job.keys()[team.job.type]).to_lower())
			print("BEHAVIOUR siege t=%d stage=%s alarm=%d escaped=%d alive=%d citadel=%.0f%% stability=%.0f%% clock=%s rite=%s boats=%d engineers=%s jobs=%d fires=%d burned=%d doused=%d buildings=%d over=%s" % [
				roundi(t), crowd.alarms.stage_name(), roundi(crowd.alarm), crowd.escaped_count, crowd.alive_citizens(),
				100.0 * citadel.fraction(), 100.0 * rules.stability.total(), UiTheme.clock(rules.time_left),
				BanishingRite.State.keys()[crowd.rite.state] if crowd.rite != null else "-",
				crowd.ferry.carried if crowd.ferry != null else 0, teams,
				crowd.engineers.jobs().size() if crowd.engineers != null and crowd.engineers.active else -1,
				crowd.fires.fires.size(), crowd.fires.burned_down, crowd.fires.doused_out, rules.buildings_down,
				rules.over_reason])
		if not ended and rules.over_reason != "":
			ended = true
			print("BEHAVIOUR siege over t=%d reason=%s escaped=%d citadel=%.0f%% clock=%s" % [roundi(t), rules.over_reason,
				crowd.escaped_count, 100.0 * citadel.fraction(), UiTheme.clock(rules.time_left)])
		await _frames(60)
		t += 1.0
		now[0] = t
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
	var rich := Battlefield.arg_value(OS.get_cmdline_user_args(), "--aim") == "rich"
	print("BEHAVIOUR judgement start aim=%s %s" % ["rich" if rich else "ring", _budget(rules, FINALE_SLOTS, FINALE_DP)])
	while not rules.finished and frames < JUDGEMENT_MAX_FRAMES:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		if t < 5.0 or frames % 6 != 0:
			continue
		for slot in rules.loadout.size():
			if rules.refusal(slot) == "":
				var at: Vector2 = _richest(rules, mission._bf.ctx.env, mission._crowd) if rich \
					else JUDGEMENT_TARGETS[next % JUDGEMENT_TARGETS.size()]
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
	"mix": ["whisper", "discord", "doom"]}
## How far straight back toward the gate the whisper sends the messenger.
const WARNING_WHISPER_BACK := 8.0


## Mira's House (v0.10 M2), played by a simple policy with Mind Whisper, Silent Doom and Discord: every tenth of a
## second, a report on its way is stopped first -- Silent Doom on a carrier nobody would see die, else a whisper sending
## them away from the Temple, else Discord on them --
## then Discord on the nearest Faithful within sight of the door (or walking up to it), else a whisper sending the
## nearest unread grieving citizen in reach to the door. `none` casts nothing.
## Nobody living would see `p` die (Silent Doom's witness rule), for the miras policy.
func crowd_alone(p: Person) -> bool:
	return mission._crowd.nearest_witness(p.ground_pos, p) == null


func _miras(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as MirasHouseDirector
	var slots := {}
	for slot in rules.loadout.size():
		if rules.key(slot) != "":
			slots[rules.key(slot)] = slot
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	var t := 0.0
	var frames := 0
	var report_at := 10.0
	while not rules.finished and frames < max_frames:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		if t >= report_at:
			report_at += 10.0
			print("BEHAVIOUR miras t=%d believers=%d inside=%d gaze=%d reports=%d" % [roundi(t), d.believers_outside(),
				d.inside().size(), roundi(d.gaze.value), d.reports_started])
		if which != "play" or frames % 6 != 0:
			continue
		var stopped := false
		for r: TempleReport in d.reports:
			var c := r.carrier
			if not is_instance_valid(c) or not c.is_alive() or c.mind == Person.Mind.CONFUSED:
				continue
			if slots.has("doom") and rules.refusal(slots.doom) == "" and crowd_alone(c):
				rules.cast(slots.doom, c.ground_pos)
				stopped = true
				break
			if slots.has("whisper") and rules.refusal(slots.whisper) == "" and not c.shaken() 					and c.mind != Person.Mind.WHISPERED:
				var away := c.ground_pos + (c.ground_pos - d.temple_door).normalized() * MindWhisperFx.REACH
				rules.cast(slots.whisper, c.ground_pos, {"target": c, "to": away})
				stopped = true
				break
			if slots.has("discord") and rules.refusal(slots.discord) == "":
				rules.cast(slots.discord, c.ground_pos)
				stopped = true
				break
		if stopped:
			continue
		var watcher := d.faithful_seeing(d.door, MirasHouseDirector.SIGHT + 1.5)
		if watcher != null and slots.has("discord") and rules.refusal(slots.discord) == "":
			rules.cast(slots.discord, watcher.ground_pos)
			continue
		if d.faithful_seeing(d.door, MirasHouseDirector.SIGHT) != null:
			continue
		if not slots.has("whisper") or rules.refusal(slots.whisper) != "":
			continue
		var best: Person = null
		for g in d.grieving:
			if not is_instance_valid(g) or not g.is_alive() or g.inside or d.believers.has(g) or g.shaken():
				continue
			if g.ground_pos.distance_to(d.door) > MindWhisperFx.REACH:
				continue
			if best == null or g.ground_pos.distance_to(d.door) < best.ground_pos.distance_to(d.door):
				best = g
		if best != null:
			rules.cast(slots.whisper, best.ground_pos, {"target": best, "to": d.door})
	var res := rules.result()
	print("BEHAVIOUR miras result won=%s reason=%s time=%.1f believers=%d gaze=%d reports=%d" % [res.won, res.reason,
		float(res.time), d.believers_outside(), roundi(d.gaze.value), d.reports_started])


## Broken Lanterns (v0.10 M3), played every LOOK_FRAMES the way a careful player would (Task 8). Silent Doom takes the
## bellkeeper once he is called; else, while a shrine drains, the flame-bearer, wherever he is (the flame passes to an
## acolyte, so up to three casts end the relighting). The Heaven Splitter's line breaks every unguarded shrine it
## crosses, so it is laid through two standing shrines when two stand within one line's reach (from their midpoint),
## else on one shrine's centre (its core kills the Knights beside it), turned whichever way crosses the fewest people:
## each seen death feeds the Gaze. The Dragonfire Parade burns a street, so it goes out only when the Splitter's
## cooldown would leave too little night for a shrine to drain, on the standing shrine with the fewest people near.
## `bonus` plays the same, but holds its Ruin off the kneelers' shrine until ten kneel by it (Through the faithful), or
## until dawn is too near to wait. `none` casts nothing.
func _lanterns(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as BrokenLanternsDirector
	var crowd: Crowd = mission._crowd
	var slots := {}
	for slot in rules.loadout.size():
		if rules.key(slot) != "":
			slots[rules.key(slot)] = slot
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	var t := 0.0
	var frames := 0
	var report_at := 10.0
	while not rules.finished and frames < max_frames:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		if t >= report_at:
			report_at += 10.0
			print("BEHAVIOUR lanterns t=%d drained=%d broken=%d relit=%d praying=%d gaze=%d knights=%d" % [roundi(t),
				d.drained_count(), d.drain_left.size(), d.relit, d.praying_count(), roundi(d.gaze.value), d.living_knights()])
		if not which in ["play", "bonus"] or frames % LOOK_FRAMES != 0:
			continue
		if _slot_ready(rules, slots, "doom"):
			var mark := _lantern_doom_target(d, crowd)
			if mark != null:
				rules.cast(slots.doom, mark.ground_pos)
				continue
		if which == "bonus" and d.kneel_shrine != null and not d.kneel_shrine.destroyed \
				and d.kneeling_near() < ThroughFaithfulObjective.NEED and rules.time_left \
				> BrokenLanternsDirector.DRAIN_SECONDS + LANTERN_DRAGON_SPARE + LANTERN_BONUS_SPARE:
			continue
		if _slot_ready(rules, slots, "heaven"):
			var line := _lantern_line(d, crowd)
			if not line.is_empty():
				rules.cast(slots.heaven, line[0], {"dir": line[1]})
				continue
		if _slot_ready(rules, slots, "dragon") and slots.has("heaven") and rules.cooldown_left(int(slots.heaven)) \
				> rules.time_left - BrokenLanternsDirector.DRAIN_SECONDS - LANTERN_DRAGON_SPARE:
			var target := _lantern_target(d, crowd)
			if target != null:
				rules.cast(slots.dragon, target.center())
	var res := rules.result()
	var bonus: bool = not res.bonuses.is_empty() and bool(res.bonuses[0].earned)
	print("BEHAVIOUR lanterns result won=%s reason=%s time=%.1f drained=%d relit=%d gaze=%d bonus=%s" % [res.won,
		res.reason, float(res.time), d.drained_count(), d.relit, roundi(d.gaze.value), bonus])


func _slot_ready(rules: Rules, slots: Dictionary, key: String) -> bool:
	return slots.has(key) and rules.refusal(int(slots[key])) == ""


## A scenario's outcome (v0.11 M2): off the board, how the mission ended; with --board, a held night's main objective counts
## as won, at its own time.
func _outcome(rules: Rules) -> String:
	if rules.main_done:
		return "won=true reason=%s time=%.1f" % [rules._main.reason, rules.main_time]
	var res := rules.result()
	return "won=%s reason=%s time=%.1f" % [res.won, res.reason, float(res.time)]


## The board's night (v0.11 M2, --board): its tier and the wishes heard, printed before the scripted player starts.
func _board_line() -> void:
	var night := mission.descent()
	if night == null:
		return
	var heard := PackedStringArray()
	for w in night.wishes:
		heard.append(w.def.id)
	print("BEHAVIOUR board tier=%d wishes=%s" % [night.tier, ",".join(heard)])


## The bell's state by name, or "none" for a town without one (v0.11 M2 reports).
func _bell_state(crowd: Crowd) -> String:
	return BellNetwork.State.keys()[crowd.bell.state] if crowd.bell != null else "none"


## Each collector's state by its initial (W waiting, A walking, V visiting, F fleeing, H hiding, S safe, D dead) and leg, in
## order (v0.11 M2 tax reports): "A1 W0 W0".
func _tax_states(d: AssassinateDirector) -> String:
	var out := PackedStringArray()
	for q in d.quarries:
		out.append("%s%d" % ["WAVFHSD"[q.state], q.leg])
	return " ".join(out)


## A Silent Doom cast on `p` now would go unseen (v0.11 M2, the tax policy): everyone else out of doors either falls with him
## (within SilentDoom.RADIUS of him now) or stays beyond Crowd.DOOM_WITNESS (and TAX_MARGIN) of where he falls T_STRIKE later,
## both now and where they will be then (each read along his heading at his pace, as _warning_alone() reads the messenger).
func _tax_unseen(p: Person, crowd: Crowd) -> bool:
	var fall := p.ground_pos + _tax_lead(p)
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for o in group:
			if not is_instance_valid(o) or o == p or not o.is_alive() or o.inside:
				continue
			if o.ground_pos.distance_to(p.ground_pos) <= SilentDoom.RADIUS:
				continue
			var reach := Crowd.DOOM_WITNESS + TAX_MARGIN
			if o.ground_pos.distance_to(fall) <= reach or (o.ground_pos + _tax_lead(o)).distance_to(fall) <= reach:
				return false
	return true


## How far `p` walks in a Silent Doom's T_STRIKE (v0.11 M2): along his heading at his pace while he has somewhere to go.
func _tax_lead(p: Person) -> Vector2:
	return _warning_heading(p) * p.walk_speed * SilentDoom.T_STRIKE if p.has_goal() else Vector2.ZERO


## The Tax Collector (v0.11 M2), played every LOOK_FRAMES: Silent Doom on the bellkeeper once he is called (a seen death
## elsewhere would ring the bell); else, for the first collector in the street with nobody but those within SilentDoom.RADIUS
## of him (who fall with him) near enough to see, Silent Doom on him; else, for the first with one lone onlooker -- a citizen,
## not shaking off a whisper -- that onlooker whispered six units away from him. `none` casts nothing.
func _tax(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as AssassinateDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	_board_line()
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	var t := 0.0
	var frames := 0
	var report_at := 10.0
	while not rules.finished and not rules.main_done and frames < max_frames:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		if t >= report_at:
			report_at += 10.0
			print("BEHAVIOUR tax t=%d states=%s killed=%d witnesses=%d bell=%s" % [roundi(t), _tax_states(d), d.killed(),
				d.witnesses().size(), _bell_state(crowd)])
		if which != "play" or frames % LOOK_FRAMES != 0:
			continue
		var bell := crowd.bell
		if bell != null and bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING] \
				and WarningDirector._alive(bell.keeper) and _slot_ready(rules, slots, "doom"):
			rules.cast(slots.doom, bell.keeper.ground_pos)
			continue
		for q in d.quarries:
			if q.dead or not WarningDirector._alive(q.target) or q.target.inside:
				continue
			var seeing := d.witnesses(q)
			if _tax_unseen(q.target, crowd):
				if _slot_ready(rules, slots, "doom"):
					print("BEHAVIOUR tax t=%.1f doom %s" % [t, q.label])
					rules.cast(slots.doom, q.target.ground_pos)
					break
				continue
			if seeing.size() == 1 and not seeing[0].soldier and not seeing[0].shaken() and _slot_ready(rules, slots, "whisper"):
				var lone := seeing[0]
				var away := lone.ground_pos + (lone.ground_pos - q.target.ground_pos).normalized() * 6.0
				rules.cast(slots.whisper, lone.ground_pos, {"target": lone, "to": away})
				break
	var r := d.report()
	print("BEHAVIOUR tax result %s states=%s killed=%d seen=%d alarms=%d target=%s" % [_outcome(rules), _tax_states(d),
		int(r.killed), int(r.seen), int(r.alarms), String(r.target)])


## Spoiled Harvest (v0.11 M2, Task 3 fix round 2: watchmen, grain arriving one granary at a time), played every LOOK_FRAMES.
## The granaries with their grain in, fewest loads first, the first that can be acted on: a watchman on guard, Silent Doom on
## him; none on guard and it not alight, Ember on it. With nothing else to do, the next granary whose grain is due within
## HARVEST_PRE: Silent Doom on a watchman of its on guard (cleared much earlier, a relief walks in). With nothing else, a granary
## down to two loads or fewer, Silent Doom on its carter nearest his door who is walking to it (empty-handed). `none` casts
## nothing.
func _harvest(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as HarvestDirector
	var slots := _slots(rules)
	_board_line()
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	var t := 0.0
	var frames := 0
	var report_at := 10.0
	while not rules.finished and not rules.main_done and frames < max_frames:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		if t >= report_at:
			report_at += 10.0
			print("BEHAVIOUR harvest t=%d granaries=%s spoiled=%d" % [roundi(t), _harvest_states(d), d.razed_count()])
		if which != "play" or frames % LOOK_FRAMES != 0:
			continue
		var order := d.targets.duplicate()
		order.sort_custom(func(a: Structure, b: Structure) -> bool: return int(d.loads[a]) < int(d.loads[b]))
		var cast := false
		for s: Structure in order:
			if d.razed(s) or not d.has_grain(s):
				continue
			var name := String(HarvestDirector.STORE_NAMES[d.targets.find(s)])
			if d.guarding(s):
				if _slot_ready(rules, slots, "doom"):
					print("BEHAVIOUR harvest t=%.1f doom a watchman of the %s granary" % [t, name])
					rules.cast(slots.doom, d.guards(s)[0].ground_pos)
					cast = true
					break
			elif not d.burning(s) and _slot_ready(rules, slots, "ember"):
				print("BEHAVIOUR harvest t=%.1f ember the %s granary" % [t, name])
				rules.cast(slots.ember, s.center())
				cast = true
				break
		if not cast and _slot_ready(rules, slots, "doom"):
			for s: Structure in order:
				if not d.razed(s) and not d.has_grain(s) and d.grain_left(s) <= HARVEST_PRE and d.guarding(s):
					print("BEHAVIOUR harvest t=%.1f doom a watchman of the %s granary (grain in %.0f s)" % [t,
						HarvestDirector.STORE_NAMES[d.targets.find(s)], d.grain_left(s)])
					rules.cast(slots.doom, d.guards(s)[0].ground_pos)
					cast = true
					break
		if cast or not _slot_ready(rules, slots, "doom"):
			continue
		for s in order:
			if d.razed(s) or not d.has_grain(s) or int(d.loads[s]) > 2:
				continue
			var mark: Person = null
			for c: Variant in d.carters[s]:
				if WarningDirector._alive(c) and not d._hauling.has((c as Person).get_instance_id()) 						and (mark == null or (c as Person).ground_pos.distance_to(d.doors[s]) < mark.ground_pos.distance_to(d.doors[s])):
					mark = c
			if mark != null:
				rules.cast(slots.doom, mark.ground_pos)
				break
	print("BEHAVIOUR harvest result %s spoiled=%d emptied=%s" % [_outcome(rules), d.razed_count(), d.emptied != null])


## Each granary's state for the harvest reports (v0.11 M2): x spoiled; else its loads left (e for an empty one waiting for its
## grain), then how many watchmen are on guard and how many are away ("2" or "1+1"), then * while it burns: "5:2,e:1+1,e:2".
func _harvest_states(d: HarvestDirector) -> String:
	var out := PackedStringArray()
	for s in d.targets:
		if d.razed(s):
			out.append("x")
			continue
		var on := d.guards(s).size()
		var off := d.watchmen(s).size() - on
		out.append("%s:%d%s%s" % [str(int(d.loads[s])) if d.has_grain(s) else "e", on, "+%d" % off if off > 0 else "",
			"*" if d.burning(s) else ""])
	return ",".join(out)


## Whom the Broken Lanterns policy strikes down quietly: the bellkeeper once called, or the flame-bearer while he is
## turned aside for a draining shrine; else null.
func _lantern_doom_target(d: BrokenLanternsDirector, crowd: Crowd) -> Person:
	var bell := crowd.bell
	if bell != null and bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING] \
			and is_instance_valid(bell.keeper) and bell.keeper.is_alive():
		return bell.keeper
	var v := d.vigil
	if v != null and v.active and v.detour != Vector2.INF and is_instance_valid(v.bearer) and v.bearer.is_alive():
		return v.bearer
	return null


## Where the Broken Lanterns policy lays its Heaven Splitter: [origin, direction], or [] with no shrine standing. A pair
## of unguarded standing shrines within LANTERN_PAIR_REACH is struck from their midpoint along the line between them;
## a single shrine from its centre, turned to the LANTERN_DIRS direction crossing the fewest people. The most shrines
## win, then the fewest people in the line.
func _lantern_line(d: BrokenLanternsDirector, crowd: Crowd) -> Array:
	var standing := d.standing_shrines()
	var best := []
	var best_n := 0
	var best_people := 0
	for i in standing.size():
		var a := standing[i]
		for j in range(i + 1, standing.size()):
			var b := standing[j]
			if d.guarded(a) or d.guarded(b) or a.center().distance_to(b.center()) > LANTERN_PAIR_REACH:
				continue
			var mid := (a.center() + b.center()) * 0.5
			var dir := (b.center() - a.center()).normalized()
			var people := _lane_people(crowd, mid, dir)
			if best.is_empty() or best_n < 2 or people < best_people:
				best = [mid, dir]
				best_n = 2
				best_people = people
		if best_n >= 2:
			continue
		for k in LANTERN_DIRS:
			var dir := Vector2.from_angle(PI * float(k) / float(LANTERN_DIRS))
			var people := _lane_people(crowd, a.center(), dir)
			if best.is_empty() or people < best_people:
				best = [a.center(), dir]
				best_n = 1
				best_people = people
	return best


## The living people out in the open that a Heaven Splitter from `origin` along `dir` strikes with its core and line.
func _lane_people(crowd: Crowd, origin: Vector2, dir: Vector2) -> int:
	var n := 0
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if not is_instance_valid(p) or not p.is_alive() or p.inside:
				continue
			var rel := p.ground_pos - origin
			if rel.length() <= HEAVEN_FX.CORE_KILL or (absf(rel.dot(dir)) <= HEAVEN_FX.LINE_LENGTH * 0.5
					and absf(rel.dot(dir.orthogonal())) <= HEAVEN_FX.LINE_HALF_WIDTH + 0.2):
				n += 1
	return n


## The shrine the Dragonfire Parade takes: the standing one with the fewest people within LANTERN_CROWD_R; else null.
func _lantern_target(d: BrokenLanternsDirector, crowd: Crowd) -> Structure:
	var best: Structure = null
	var best_n := 0
	for s in d.standing_shrines():
		var n := 0
		for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
			for p in group:
				if is_instance_valid(p) and p.is_alive() and not p.inside \
						and p.ground_pos.distance_to(s.center()) <= LANTERN_CROWD_R:
					n += 1
		if best == null or n < best_n:
			best = s
			best_n = n
	return best


## The Vigil Flame (v0.10 M4), played every LOOK_FRAMES by a simple policy with Mind Whisper, Discord and Will-o'-Wisp.
## Before the swap (_flame_swap): bystanders drawn off by a wisp, the bearer and his acolytes held by one Discord, then
## Wren whispered to the lantern. With the flame (_flame_carry): a beam due to come onto Wren drawn off by a wisp, else
## Wren whispered out of its way; in the clock's last 20 s, Discord at the Temple's door gives the searching beam a
## noise far from him. `none` casts nothing.
func _flame(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as VigilFlameDirector
	var slots := {}
	for slot in rules.loadout.size():
		if rules.key(slot) != "":
			slots[rules.key(slot)] = slot
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	var t := 0.0
	var frames := 0
	var report_at := 10.0
	while not rules.finished and frames < max_frames:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		if t >= report_at:
			report_at += 10.0
			print("BEHAVIOUR flame t=%d phase=%s touches=%d praying=%d reports=%d gaze=%d beams=%d" % [roundi(t),
				_flame_phase(d), d.touches, d.praying_count(), d.reports_started, roundi(d.gaze.value), d.searchlight.beams()])
		if which != "play" or frames % LOOK_FRAMES != 0:
			continue
		if not d.appeared or not is_instance_valid(d.wren) or not d.wren.is_alive() or d.home:
			continue
		if not d.swapped:
			_flame_swap(rules, d, slots)
		else:
			_flame_carry(rules, d, slots)
	var res := rules.result()
	var bonus: bool = not res.bonuses.is_empty() and bool(res.bonuses[0].earned)
	print("BEHAVIOUR flame result won=%s reason=%s time=%.1f swapped=%s seen=%s touches=%d gaze=%d bonus=%s" % [res.won,
		res.reason, float(res.time), d.swapped, d.swap_seen, d.touches, roundi(d.gaze.value), bonus])


func _flame_phase(d: VigilFlameDirector) -> String:
	if d.home:
		return "home"
	if d.swapped:
		return "carry"
	if d.swapping:
		return "swap"
	return "watch" if d.appeared else "wait"


## Before the swap: the Faithful who could see it are the acolytes (wherever they are: they walk back to the bearer's
## side) and anyone else within FLAME_WATCH_R of the lantern. Bystanders going about their day within FLAME_STRAY_R
## are drawn off by a Will-o'-Wisp beyond them; once one Discord can take the watchers and, while he walks on, the
## bearer, it does (it blinds them and holds the lantern still); with nobody left to see, Wren is whispered to the
## lantern.
func _flame_swap(rules: Rules, d: VigilFlameDirector, slots: Dictionary) -> void:
	var lantern := d.flame_at()
	if lantern == Vector2.INF or d.swapping:
		return
	var bearer: Person = d.vigil.bearer if d.vigil != null and MissionDirector._alive(d.vigil.bearer) else null
	var walking: Array[Person] = d.vigil.walkers() if d.vigil != null and d.vigil.active else ([] as Array[Person])
	var watchers: Array[Person] = []
	var strays := Vector2.ZERO
	var n_strays := 0
	for f in d.faithful:
		if f == bearer or d.faithful_seeing(f.ground_pos, 0.01, bearer) != f:
			continue
		var gap := f.ground_pos.distance_to(lantern)
		if walking.has(f) or gap <= FLAME_WATCH_R:
			watchers.append(f)
		if not walking.has(f) and f.mind in Person.LURABLE and gap <= FLAME_STRAY_R:
			strays += f.ground_pos
			n_strays += 1
	var w := d.wren
	if n_strays > 0 and _slot_ready(rules, slots, "wisp"):
		strays /= float(n_strays)
		var from := strays - lantern if strays.distance_to(lantern) > 0.5 else lantern - w.ground_pos
		var away := from.normalized() if from.length() > 0.01 else Vector2.RIGHT
		var lure := mission._crowd._grid.nearest_walkable(strays + away * FLAME_STRAY_LURE)
		rules.cast(slots.wisp, lure if lure != Vector2.INF else strays + away * FLAME_STRAY_LURE)
		return
	var held := bearer == null or bearer.mind in MissionDirector.BLIND
	if not watchers.is_empty() or not held:
		var take: Array[Vector2] = []
		if not held:
			take.append(lantern)
		for f in watchers:
			take.append(f.ground_pos)
		var mid := Vector2.ZERO
		for at in take:
			mid += at / float(take.size())
		var one := true
		for at in take:
			one = one and at.distance_to(mid) <= DiscordFx.DISCORD_R - FLAME_DISCORD_MARGIN
		if one and _slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, mid)
			return
		if not watchers.is_empty():
			return
	if w.mind != Person.Mind.WHISPERED and not w.shaken() and _slot_ready(rules, slots, "whisper"):
		rules.cast(slots.whisper, w.ground_pos, {"target": w, "to": lantern})


## With the flame: Discord at the Temple's door in the last 20 s (the searching beam's noise, far from Wren); else, a
## beam due to come within FLAME_MARGIN of Wren on his way in the next FLAME_LOOKAHEAD seconds (its sweep is slow and
## plain to see) is drawn off by a Will-o'-Wisp beyond it where the fewest Faithful stand (the drawn kneel in its
## light), or Wren is whispered out of its way, if that is safer than walking on over FLAME_PLAN seconds (a whispered
## boy strolls there, then lingers): where he stands, or one of FLAME_DIRS spots half FLAME_DODGE or FLAME_DODGE round
## him; of those the beams keep clear of him, the one that costs him the least time to Mira's shrine, else the clearest.
func _flame_carry(rules: Rules, d: VigilFlameDirector, slots: Dictionary) -> void:
	var w := d.wren
	var light := d.searchlight
	if rules.time_left <= Searchlight.SEARCH_LAST + 1.0 and w.ground_pos.distance_to(d.temple_door) > FLAME_DANGER \
			and _slot_ready(rules, slots, "discord"):
		rules.cast(slots.discord, d.temple_door)
		return
	if _flame_clear(light, w, Vector2.INF, FLAME_LOOKAHEAD) > Searchlight.POOL_R + FLAME_MARGIN:
		return
	var grid := mission._crowd._grid
	if light.decoy_beam < 0 and _slot_ready(rules, slots, "wisp"):
		var beam := light.aim(_flame_threat(light, w))
		var lure := Vector2.INF
		var fewest := 0
		for k in FLAME_DIRS:
			var at := grid.nearest_walkable(beam + Vector2.from_angle(TAU * float(k) / float(FLAME_DIRS)) * FLAME_DODGE)
			if at == Vector2.INF or at.distance_to(w.ground_pos) < FLAME_DODGE + Searchlight.POOL_R:
				continue
			var n := 0
			for f in d.faithful:
				if MissionDirector._alive(f) and f.ground_pos.distance_to(at) <= WillOWisp.LURE_REACH:
					n += 1
			if lure == Vector2.INF or n < fewest:
				lure = at
				fewest = n
		if lure != Vector2.INF:
			rules.cast(slots.wisp, lure)
			return
	if w.mind == Person.Mind.WHISPERED or w.shaken() or not _slot_ready(rules, slots, "whisper"):
		return
	var walk_on := _flame_clear(light, w, Vector2.INF, FLAME_PLAN)
	var spots: Array[Vector2] = [w.ground_pos]
	for reach: float in [FLAME_DODGE * 0.5, FLAME_DODGE]:
		for k in FLAME_DIRS:
			var to := grid.nearest_walkable(w.ground_pos + Vector2.from_angle(TAU * float(k) / float(FLAME_DIRS)) * reach)
			if to != Vector2.INF:
				spots.append(to)
	var stroll := DummyEnemy.WALK_SPEED * w.pace
	var run := Person.PANIC_SPEED * w.pace
	var best := Vector2.INF
	var best_clear := 0.0
	var best_cost := 0.0
	for to in spots:
		var clear := _flame_clear(light, w, to, FLAME_PLAN)
		if clear <= walk_on:
			continue
		var cost := w.ground_pos.distance_to(to) / stroll + MindWhisperFx.LINGER + to.distance_to(d.shrine) / run
		var safe := clear > Searchlight.POOL_R + FLAME_MARGIN
		var was_safe := best_clear > Searchlight.POOL_R + FLAME_MARGIN
		var better := (not was_safe and clear > best_clear) if not safe else (not was_safe or cost < best_cost)
		if best == Vector2.INF or better:
			best = to
			best_clear = clear
			best_cost = cost
	if best != Vector2.INF:
		rules.cast(slots.whisper, w.ground_pos, {"target": w, "to": best})


## Where Wren will be `ahead` seconds on: whispered to `to` (Vector2.INF: not), strolling straight there; else walking
## his own path at his duty's pace, or standing while off his duty.
func _flame_wren_at(w: Person, to: Vector2, ahead: float) -> Vector2:
	if to != Vector2.INF:
		var stroll := DummyEnemy.WALK_SPEED * w.pace * ahead
		return w.ground_pos.move_toward(to, stroll)
	if w.mind != Person.Mind.DUTY:
		return w.ground_pos
	var left := w.walk_speed * ahead
	var at := w.ground_pos
	for k in range(w._leg, w._path.size()):
		var leg := at.distance_to(w._path[k])
		if leg >= left:
			return at.move_toward(w._path[k], left)
		left -= leg
		at = w._path[k]
	return at


## Where beam i's pool will be `ahead` seconds on, read off its plain path: on its decoy while that holds it, at the
## searched noise, else on its sweep; Vector2.INF while it is not yet lit.
func _flame_beam_at(light: Searchlight, i: int, ahead: float) -> Vector2:
	if ahead <= 0.0:
		return light.aim(i)
	if i == light.decoy_beam and ahead < light.decoy_left:
		return light.decoy
	if i == light.search_beam:
		return light.noise
	var t := light.beam_age(i) + ahead
	return light.sweep_point(i, t) if light.on and t >= 0.0 else Vector2.INF


## How near any beam's pool comes to Wren over the next `ahead` seconds, whispered to `to` or (Vector2.INF) not.
func _flame_clear(light: Searchlight, w: Person, to: Vector2, ahead: float) -> float:
	var out := INF
	var t := 0.0
	while t <= ahead:
		var at := _flame_wren_at(w, to, t)
		for i in Searchlight.MAX_BEAMS:
			var p := _flame_beam_at(light, i, t)
			if p != Vector2.INF:
				out = minf(out, p.distance_to(at))
		t += FLAME_STEP
	return out


## The lit beam that comes nearest Wren on his way over the next FLAME_LOOKAHEAD seconds.
func _flame_threat(light: Searchlight, w: Person) -> int:
	var best := 0
	var best_gap := INF
	for i in light.beams():
		var t := 0.0
		while t <= FLAME_LOOKAHEAD:
			var p := _flame_beam_at(light, i, t)
			var gap := p.distance_to(_flame_wren_at(w, Vector2.INF, t)) if p != Vector2.INF else INF
			if gap < best_gap:
				best = i
				best_gap = gap
			t += FLAME_STEP
	return best


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
			var order := ["whisper", "discord"]
			if which == "mix" and last_delay == "whisper":
				order = ["discord", "whisper"]
			for k: String in order:
				if k == "whisper" and m.shaken():
					continue  # v0.08.1: he shakes it off; the aim shows him in red
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


func _warning_mind(p: Variant) -> String:
	if not is_instance_valid(p) or not p.is_alive():
		return "DEAD"
	return Person.Mind.keys()[p.mind]


## Which way the person is heading: toward the waypoint it is walking to, else its goal, else (1, 0).
func _warning_heading(p: Person) -> Vector2:
	var next := p._target if p._target.distance_to(p.ground_pos) > 0.05 else p.goal()
	var h := next - p.ground_pos if next != Vector2.INF else Vector2.ZERO
	return h.normalized() if h.length() > 0.01 else Vector2(1, 0)


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


## The Feast's act (`--path=`): the Festival unless it says the Procession.
func _feast_path() -> String:
	return "procession" if Battlefield.arg_value(OS.get_cmdline_user_args(), "--path") == "procession" else "festival"


## The campaign's Night 3 alone (v0.10 M5): nothing cast, or the act played by the night's policy; then its result.
func _feast(which: String) -> void:
	var path := _feast_path()
	print("BEHAVIOUR feast start path=%s bell=%s town=%s %s" % [path, mission.bell_rang, mission._crowd.profile.tier_name(),
		_budget(mission._rules, FEAST_SLOTS, FEAST_DP)])
	var done := [false]
	mission.finished.connect(func(r: Dictionary) -> void:
		print("BEHAVIOUR feast result won=%s reason=%s time=%.1f bonuses=%s" % [r.won, r.reason, float(r.time), _earned(r)])
		done[0] = true)
	if which == "play":
		_play_act(path)  # a coroutine left running beside the loop, until the act is over
	while not done[0]:
		await _frames(1)


## The drafted loadout against a budget: "loadout=a,b dp=3/10 slots=2/4 fits=true".
func _budget(rules: Rules, slots: int, dp: int) -> String:
	var keys := PackedStringArray()
	var cost := 0
	for i in rules.loadout.size():
		keys.append(rules.key(i))
		cost += int(rules.power(i).get("dp", 0))
	return "loadout=%s dp=%d/%d slots=%d/%d fits=%s" % [",".join(keys), cost, dp, keys.size(), slots,
		cost <= dp and keys.size() <= slots]


## Each bonus of a result and whether it was earned: "Before the bell:yes".
func _earned(r: Dictionary) -> String:
	var out := PackedStringArray()
	for b: Dictionary in r.get("bonuses", []):
		out.append("%s:%s" % [b.get("label", ""), "yes" if bool(b.get("earned", false)) else "no"])
	return ",".join(out)


## The Long Night (v0.09) forced through its acts, each ended as the command line asks (see the usage).
func _night() -> void:
	var args := OS.get_cmdline_user_args()
	var path := Battlefield.arg_value(args, "--path")
	path = path if path != "" else "festival"
	var outcome := {"omen": Battlefield.arg_value(args, "--act1"), "festival": Battlefield.arg_value(args, "--act2"),
		"procession": Battlefield.arg_value(args, "--act2"), "judgement": Battlefield.arg_value(args, "--act3")}
	# A played night has its own casts to hand over, and the aid's Heaven Splitter would fall on the Prince in his first second.
	var calm_handover := "--calm-handover" in OS.get_cmdline_user_args() or "play" in outcome.values()
	var done := [false]
	var acts := [0]
	mission.act_over.connect(func(r: Dictionary) -> void:
		print("BEHAVIOUR night act=%s won=%s reason=%s time=%.1f prince=%s" % [mission.act().id, r.won, r.reason, float(r.time),
			mission.night().prince])
		# Test aid: the Procession decides the Prince's outcome itself now; this forces it, over what it decided.
		var prince := Battlefield.arg_value(OS.get_cmdline_user_args(), "--prince")
		if prince != "" and mission.act().id == "procession":
			mission.night().prince = prince
			print("BEHAVIOUR night prince forced to %s" % prince)
		var festival := Battlefield.arg_value(OS.get_cmdline_user_args(), "--festival")
		if festival != "" and mission.act().id == "festival":
			mission.night().festival = festival
			print("BEHAVIOUR night festival forced to %s" % festival)
		acts[0] += 1)
	mission.finished.connect(func(r: Dictionary) -> void:
		print("BEHAVIOUR night end won=%s reason=%s path=%s acts=%d score=%d rank=%s" % [r.won, r.reason, r.path,
			(r.acts as Array).size(), int(r.score), r.rank])
		done[0] = true)
	var seen := -1
	while not done[0]:
		if acts[0] != seen:
			seen = acts[0]
			if seen > 0:
				await _frames(10)
				if seen == 1 and not calm_handover:
					# Review focus 4: the act ends with the time scale dipped and a power still falling. Put in the
					# world by the old act's caster: its Rules is over and refuses a cast, and the night has no Heaven.
					Engine.time_scale = 0.3
					var heaven := load(String(PowerBook.get_power("heaven").path)) as GDScript
					mission._rules.caster.call(heaven, TownLayout.CITADEL_ORIGIN, {"dir": Vector2(1, 0)})
				mission.next_act(_loadout_for_next(outcome, path), path)
				if seen == 1:
					var rules: Rules = mission._rules
					var ready := true
					for i in rules.loadout.size():
						ready = ready and rules.cooldown_left(i) == 0.0
					# The old act's powers end with it (v0.09 final review): none of its effects is still playing.
					var playing := 0
					for c in mission._bf.ctx.overhead.get_children():
						playing += 1 if c is FxTimeline and not (c as FxTimeline).finished else 0
					print("BEHAVIOUR night handover time_scale=%.2f buildings=%d cooldowns=%s powers=%d" % [Engine.time_scale,
						rules.buildings_down, "ready" if ready else "waiting", playing])
				mission._intro_left = 0.0
				mission._rules.set_process(true)
			print("BEHAVIOUR night start act=%s town=%s" % [mission.act().id, mission._crowd.profile.tier_name()])
			if "--shots" in OS.get_cmdline_user_args() and mission.act().id == "festival":
				_festival_shots()  # a coroutine left running beside the loop
			if "--shots" in OS.get_cmdline_user_args() and mission.act().id == "procession":
				_procession_shots()
			var how := String(outcome.get(mission.act().id, ""))
			if how == "play":
				_play_act(mission.act().id)  # a coroutine left running beside the loop, until the act is over
			await _frames(60)
			_force_act(how)
		await _frames(1)


## The loadout the next act is drafted when the policy plays it (Prepare's re-draft, simulated), else none: the act's own
## default stands, as it did before the policies.
func _loadout_for_next(outcome: Dictionary, path: String) -> PackedStringArray:
	var ids := mission.act().next
	var id := path if path != "" and ids.has(path) else String(ids[0])
	if String(outcome.get(id, "")) != "play":
		return PackedStringArray()
	var asked := Battlefield.arg_value(OS.get_cmdline_user_args(), "--act3-loadout")
	if id == "judgement" and asked != "":
		return PackedStringArray(asked.split(","))
	return PackedStringArray(NIGHT_LOADOUTS[id])


## Play the act that is running with its scripted policy (`--actN=play`), until it is over.
func _play_act(id: String) -> void:
	match id:
		"omen":
			await _warning("mix")
		"festival":
			await _play_festival()
		"procession":
			await _play_procession()
		"judgement":
			await _play_judgement()


## The act's powers by key, to their slots.
func _slots(rules: Rules) -> Dictionary:
	var slots := {}
	for slot in rules.loadout.size():
		if rules.key(slot) != "":
			slots[rules.key(slot)] = slot
	return slots


## The Festival (Act II-A): from FESTIVAL_DOOM_AT, Silent Doom on the Mayor (a death the crowd panics at whether it is
## seen or not); then Discord on the densest cluster of goers, whenever it is ready. `t` is the act's own clock.
func _play_festival() -> void:
	var rules: Rules = mission._rules
	var d := rules.director as FestivalDirector
	var slots := _slots(rules)
	var casts := {}
	var doom_done := false
	var frames := 0
	var report_at := 15.0
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	while is_instance_valid(rules) and rules == mission._rules and not rules.finished and frames < max_frames:
		await process_frame
		frames += 1
		var t := d.timeline.elapsed()
		if t >= report_at:
			report_at += 15.0
			print("BEHAVIOUR night play festival t=%d lost=%d/%d mayor=%s" % [roundi(t), d.count(), d.need,
				_warning_mind(d.mayor)])
		if frames % LOOK_FRAMES != 0 or t < FESTIVAL_DOOM_AT:
			continue
		if not doom_done:
			if not WarningDirector._alive(d.mayor):
				doom_done = true  # nobody to doom (or the Mayor is dead already): on to the Discord
			elif slots.has("doom") and rules.refusal(slots.doom) == "":
				var at := d.mayor.ground_pos
				if rules.cast(slots.doom, at, {}) != null:
					doom_done = true
					casts["doom"] = int(casts.get("doom", 0)) + 1
					print("BEHAVIOUR night play festival t=%.1f cast doom at %s on the Mayor" % [t, at.snapped(Vector2(0.1, 0.1))])
			continue
		if slots.has("discord") and rules.refusal(slots.discord) == "":
			var at := _densest(d.goers)
			if at != Vector2.INF and rules.cast(slots.discord, at, {}) != null:
				casts["discord"] = int(casts.get("discord", 0)) + 1
				print("BEHAVIOUR night play festival t=%.1f cast discord at %s" % [t, at.snapped(Vector2(0.1, 0.1))])
		# A Heaven Splitter, when the draft has one (v0.10 M5: the Feast's richer policy within 10 DP), at the densest knot
		# of goers. The night's own Festival loadout has none, so `night` plays as before.
		if slots.has("heaven") and rules.refusal(slots.heaven) == "":
			var hat := _densest(d.goers)
			if hat != Vector2.INF and rules.cast(slots.heaven, hat, {"dir": Vector2(1, 0)}) != null:
				casts["heaven"] = int(casts.get("heaven", 0)) + 1
				print("BEHAVIOUR night play festival t=%.1f cast heaven at %s" % [t, hat.snapped(Vector2(0.1, 0.1))])
	print("BEHAVIOUR night play festival end lost=%d/%d casts=%s" % [d.count(), d.need, casts])


## The centre of the thickest knot of these living people (those within DiscordFx.DISCORD_R of one of them), or INF.
func _densest(people: Array[Person]) -> Vector2:
	var best := Vector2.INF
	var best_n := 0
	for a in people:
		if not WarningDirector._alive(a) or a.inside:
			continue
		var sum := Vector2.ZERO
		var n := 0
		for b in people:
			if WarningDirector._alive(b) and not b.inside and b.ground_pos.distance_to(a.ground_pos) <= DiscordFx.DISCORD_R:
				sum += b.ground_pos
				n += 1
		if n > best_n:
			best_n = n
			best = sum / float(n)
	return best


## The Procession (Act II-B): Silent Doom on the Prince whenever nobody would see it (now, nor where he will have walked
## to), else Mind Whisper to send off whoever near him can hear it. His escort are soldiers, who hear neither Mind Whisper
## nor Discord, so the nearest attendant or onlooker (a citizen) within sight of him is the one sent, PROCESSION_SENT
## units straight away from him. `--doom-seen` (an aid for measuring the act's other end) also dooms him, seen, once he is
## on the dock's leg.
func _play_procession() -> void:
	var rules: Rules = mission._rules
	var crowd: Crowd = mission._crowd
	var d := rules.director as ProcessionDirector
	var slots := _slots(rules)
	var seen_ok := "--doom-seen" in OS.get_cmdline_user_args()
	var casts := {}
	# Looks taken while he walked; of them, with no soldier within Crowd.DOOM_WITNESS of him; with nobody (alone).
	var looks := [0, 0, 0]
	var frames := 0
	var report_at := 15.0
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	while is_instance_valid(rules) and rules == mission._rules and not rules.finished and frames < max_frames:
		await process_frame
		frames += 1
		var t := d.timeline.elapsed()
		var p: Variant = d.prince
		var alive := WarningDirector._alive(p) and not d.boarded
		if t >= report_at:
			report_at += 15.0
			var w: Person = crowd.nearest_witness(p.ground_pos, p) if alive else null
			var near_now := _witnesses(crowd, p) if alive else Vector2i.ZERO
			var seen_by := "none"
			if w != null:
				seen_by = "%s %.1f" % [_warning_who(w, crowd), w.ground_pos.distance_to(p.ground_pos)]
			print("BEHAVIOUR night play procession t=%d leg=%d prince=%s witness=%s soldiers=%d citizens=%d" % [roundi(t),
				d.leg, _warning_mind(p), seen_by, near_now.x, near_now.y])
		if frames % LOOK_FRAMES != 0 or not alive:
			continue
		var alone: bool = _warning_alone(p, crowd)
		var near := _witnesses(crowd, p)
		looks[0] += 1
		looks[1] += 1 if near.x == 0 else 0
		looks[2] += 1 if alone else 0
		if slots.has("doom") and rules.refusal(slots.doom) == "" and (alone or (seen_ok and d.leg >= ProcessionDirector.DOCK_LEG)):
			if rules.cast(slots.doom, p.ground_pos, {}) != null:
				casts["doom"] = int(casts.get("doom", 0)) + 1
				print("BEHAVIOUR night play procession t=%.1f cast doom at %s on the Prince (%s, %s)" % [t,
					p.ground_pos.snapped(Vector2(0.1, 0.1)), _warning_mind(p), "alone" if alone else "seen"])
			continue
		if alone or not slots.has("whisper") or rules.refusal(slots.whisper) != "":
			continue
		var who := _nearest_hearer(crowd, p)
		if who == null:
			continue  # only soldiers about him: nobody to send
		var away: Vector2 = who.ground_pos - p.ground_pos
		if away.length() < 0.1:
			away = Vector2(1, 0)
		var to := MindWhisperFx.clamp_to(crowd._grid, who.ground_pos, who.ground_pos + away.normalized() * PROCESSION_SENT)
		if rules.cast(slots.whisper, who.ground_pos, {"to": to, "target": who}) != null:
			casts["whisper"] = int(casts.get("whisper", 0)) + 1
			print("BEHAVIOUR night play procession t=%.1f cast whisper on %s to %s" % [t, _warning_who(who, crowd),
				to.snapped(Vector2(0.1, 0.1))])
	print("BEHAVIOUR night play procession end prince=%s casts=%s looks=%d no_soldier=%d alone=%d" % [d.report().prince,
		casts, looks[0], looks[1], looks[2]])


## How many soldiers (x) and citizens (y) are within Crowd.DOOM_WITNESS of `of`, out of doors and alive.
func _witnesses(crowd: Crowd, of: Person) -> Vector2i:
	var n := Vector2i.ZERO
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and not p.inside \
				and p.ground_pos.distance_to(of.ground_pos) <= Crowd.DOOM_WITNESS:
			n.x += 1
	for p in crowd.citizens:
		if is_instance_valid(p) and p != of and p.is_alive() and not p.inside \
				and p.ground_pos.distance_to(of.ground_pos) <= Crowd.DOOM_WITNESS:
			n.y += 1
	return n


## The nearest living citizen out of doors within Crowd.DOOM_WITNESS of `of` who is not shaking off a whisper, or null.
func _nearest_hearer(crowd: Crowd, of: Person) -> Person:
	var best: Person = null
	for c in crowd.citizens:
		if is_instance_valid(c) and c != of and c.is_alive() and not c.inside and not c.shaken() \
				and c.ground_pos.distance_to(of.ground_pos) <= Crowd.DOOM_WITNESS \
				and (best == null or c.ground_pos.distance_squared_to(of.ground_pos) < best.ground_pos.distance_squared_to(of.ground_pos)):
			best = c
	return best


## Act III: the Last Judgement's greedy caster, with this act's loadout (see _judgement()).
func _play_judgement() -> void:
	var rules: Rules = mission._rules
	var town: Town = mission._town
	var d := rules.director
	var casts := {}
	var fixed := Battlefield.arg_value(OS.get_cmdline_user_args(), "--act3-aim") == "fixed"
	var next := 0
	var frames := 0
	var report_at := 15.0
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	while is_instance_valid(rules) and rules == mission._rules and not rules.finished and frames < max_frames:
		await process_frame
		frames += 1
		var t := d.timeline.elapsed() if d != null else 0.0
		if t >= report_at:
			report_at += 15.0
			print("BEHAVIOUR night play judgement t=%d citadel=%d%% stability=%s escaped=%d buildings=%d stage=%s" % [
				roundi(t), roundi(town.citadel.fraction() * 100.0), _stability(rules), rules.escaped_this_act(),
				rules.buildings_down, mission._crowd.alarms.stage_name()])
		if t < 5.0 or frames % LOOK_FRAMES != 0:
			continue
		for slot in rules.loadout.size():
			if rules.refusal(slot) == "":
				var at: Vector2 = JUDGEMENT_TARGETS[next % JUDGEMENT_TARGETS.size()] if fixed \
					else _richest(rules, mission._bf.ctx.env, mission._crowd)
				next += 1
				if rules.cast(slot, at, {"dir": Vector2(0.2, 1.0).normalized()}) != null:
					casts[rules.key(slot)] = int(casts.get(rules.key(slot), 0)) + 1
					print("BEHAVIOUR night play judgement t=%.1f cast %s at %s" % [t, rules.key(slot),
						at.snapped(Vector2(0.1, 0.1))])
				break
	print("BEHAVIOUR night play judgement end t=%.1f citadel_fell=%s stability=%s escaped=%d casts=%s" % [
		d.timeline.elapsed() if d != null else 0.0, town.citadel.is_fallen(), _stability(rules),
		rules.escaped_this_act(), casts])


## Where a cast would take the most of what City Stability still counts (Act III's policy, Task 19): each standing
## building and each living person out of doors weighs its share of its part's breaking point (Stability's own weights),
## and a part already broken weighs nothing. The point is a building's centre or a person, whichever has the most within
## RICH_R.
func _richest(rules: Rules, env: EnvironmentField, crowd: Crowd) -> Vector2:
	var st := rules.stability
	var pts: Array[Vector2] = []
	var ws: Array[float] = []
	for b in env.structures():
		if b.destroyed:
			continue
		var w := 0.0
		if Stability.INFRA_ROLES.has(b.role) and st.infrastructure > 0.0:
			w = Stability.W_INFRASTRUCTURE * b.footprint.get_area() / (st._infra_area * Stability.INFRASTRUCTURE_BROKEN)
		elif Stability.RESOURCE_ROLES.has(b.role) and st.resources > 0.0:
			w = Stability.W_RESOURCES / (float(st._resource_count) * Stability.RESOURCES_BROKEN)
		elif b.role == &"barracks" and st._barracks_count > 0:
			w = Stability.W_MILITARY * (1.0 - Stability.MILITARY_SOLDIER_SHARE) / float(st._barracks_count)
		elif b.role == &"citadel" and st.leadership > 0.0:
			w = Stability.W_LEADERSHIP * st.leadership
		if w > 0.0:
			pts.append(b.footprint.get_center())
			ws.append(w)
	var per_citizen := 0.0
	if st.population > 0.0 and crowd.spawned_citizens > 0:
		per_citizen = Stability.W_POPULATION / (float(crowd.spawned_citizens) * Stability.POPULATION_BROKEN)
	var per_soldier := 0.0
	if float(crowd.killed_soldiers) < float(crowd.spawned_soldiers) * Stability.SOLDIERS_BROKEN:
		per_soldier = Stability.W_MILITARY * Stability.MILITARY_SOLDIER_SHARE \
			/ (float(crowd.spawned_soldiers) * Stability.SOLDIERS_BROKEN)
	for p in crowd.citizens + crowd.soldiers:
		var w := per_soldier if is_instance_valid(p) and p.soldier else per_citizen
		if w > 0.0 and is_instance_valid(p) and p.is_alive() and not p.inside:
			pts.append(p.ground_pos)
			ws.append(w)
	var best := TownLayout.CITADEL_ORIGIN
	var best_w := -1.0
	for c in pts:
		var sum := 0.0
		for j in pts.size():
			if pts[j].distance_squared_to(c) <= RICH_R * RICH_R:
				sum += ws[j]
		if sum > best_w:
			best_w = sum
			best = c
	return best


## City stability and its five parts, in percent: total (population, infrastructure, leadership, military, resources).
func _stability(rules: Rules) -> String:
	var s := rules.stability
	return "%d%%(p%d i%d l%d m%d r%d)" % [roundi(s.total() * 100.0), roundi(s.population * 100.0),
		roundi(s.infrastructure * 100.0), roundi(s.leadership * 100.0), roundi(s.military * 100.0),
		roundi(s.resources * 100.0)]


## Act II-A's capture aid (v0.09 Task 13): a frame of the market at FESTIVAL_SHOTS' marks of the act -- the bonfires lit
## and the crowd packing (0:30, 0:50), the Mayor on the fountain (1:35) -- and the festival's count at each.
func _festival_shots() -> void:
	var bf: Battlefield = mission._bf
	var rules: Rules = mission._rules
	for mark: float in FESTIVAL_SHOTS:
		while is_instance_valid(rules) and not rules.finished and rules.director != null and rules.director.timeline.elapsed() < mark:
			await process_frame
		if not is_instance_valid(rules) or rules.finished:
			return
		bf.camera.zoom = Vector2.ONE * 1.5
		bf.camera.position = Iso.ground_to_screen(FESTIVAL_LOOK_AT).round()
		await _frames(3)
		await bf.save_capture("behaviour_festival_%d.png" % roundi(mark))
		var mayor := (rules.director as FestivalDirector).mayor
		if mark == FESTIVAL_SHOTS[-1] and mayor != null:
			# The address: a close-up of the Mayor himself, alone (the others hidden for the frame), to see his chain sit
			# on the chest.
			var hidden: Array[Person] = []
			for p: Person in mission._crowd.citizens + mission._crowd.soldiers:
				if is_instance_valid(p) and p != mayor and p.visible:
					p.visible = false
					hidden.append(p)
			bf.camera.zoom = Vector2.ONE * 8.0
			bf.camera.position = Iso.ground_to_screen(mayor.ground_pos).round() + Vector2(0.0, -10.0)
			await _frames(3)
			await bf.save_capture("behaviour_festival_%d_mayor.png" % roundi(mark))
			for p in hidden:
				if is_instance_valid(p):
					p.visible = true
		var d := rules.director as FestivalDirector
		print("BEHAVIOUR night festival shot t=%d count=%d need=%d mayor=%s" % [roundi(mark), d.count(), d.need,
			d.mayor.mind if d.mayor != null else "none"])


## Act II-B's capture aid (v0.09 Task 16): a frame at PROCESSION_SHOTS' marks of the act, the camera near the Prince -- at the
## steps for the blessing, at the dock for the ship -- with his leg and the onlookers at each.
func _procession_shots() -> void:
	var bf: Battlefield = mission._bf
	var rules: Rules = mission._rules
	for shot: Array in PROCESSION_SHOTS:
		var mark: float = shot[0]
		while is_instance_valid(rules) and not rules.finished and rules.director != null and rules.director.timeline.elapsed() < mark:
			await process_frame
		if not is_instance_valid(rules) or rules.finished:
			return
		var d := rules.director as ProcessionDirector
		var look: Vector2 = d.route[d.route.size() - 1]
		if is_instance_valid(d.prince):
			look = d.prince.ground_pos.lerp(look, float(shot[2]))
		bf.camera.zoom = Vector2.ONE * float(shot[1])
		bf.camera.position = Iso.ground_to_screen(look).round()
		await _frames(3)
		await bf.save_capture("behaviour_procession_%d.png" % roundi(mark))
		print("BEHAVIOUR night procession shot t=%d leg=%d prince=%s to_look=%.1f onlookers=%d escorts=%d" % [roundi(mark), d.leg,
			d.prince.ground_pos if is_instance_valid(d.prince) else "gone", d.prince.ground_pos.distance_to(look) \
			if is_instance_valid(d.prince) else -1.0, d.onlookers.size(), d.escorts.size()])


## End the current act as asked: "win", "lose", or anything else to let it run.
func _force_act(how: String) -> void:
	var rules: Rules = mission._rules
	if how == "win":
		rules.force_end(true, "forced")
	elif how == "lose":
		if mission.act().id == "omen":
			mission._crowd.ring_bell()  # a lost Act I is a rung bell, as the night reads it
		rules.force_end(false, "forced")


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
