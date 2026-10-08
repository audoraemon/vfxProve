class_name Mission
extends Node2D
## One mission of Kingdoms Amid Kataclysm: the battlefield, the town of Aldermere, its people, the rules, the
## aiming and the HUD. The player picks a power with 1-6, clicks or drags to cast it, pans with WASD or the
## middle button and zooms with the wheel. R starts a fresh mission. Milestone 4 puts the Title, Prepare,
## Pause and Results screens around this.

## The run is over, with everything the Results screen shows (Rules.result(); for a night, NightState.result()).
signal finished(result: Dictionary)
## An act of the night is over and another follows (v0.09): its Rules.result(). next_act() plays the next one.
signal act_over(result: Dictionary)
## Esc with nothing to cancel: whoever owns this mission decides what that means.
signal pause_pressed
## The effect shaders are compiled and the mission can start. start() before this would clear the effect
## layers under the prewarm while it is still using them.
signal prewarmed

## The four powers a mission starts with until the Prepare screen exists (milestone 4). Override on the
## command line: -- --loadout=heaven,gravity,judgement,nova
const DEFAULT_LOADOUT := ["heaven", "tsunami", "cinder", "nova"]
const PEOPLE := Crowd.CITIZENS + Crowd.SOLDIERS
const PAN_SPEED := 320.0
## Pan limits (screen px): the map is 60 x 60 units since the town scale upgrade. The furthest zoom out: below 0.5
## the pixel art shrinks past legibility -- cobbles shimmer and people vanish (playtest, 2026-09-27).
const PAN_MIN := Vector2(-1700, -900)
const PAN_MAX := Vector2(1700, 1000)
const ZOOM_MIN := 0.5
const ZOOM_MAX := 1.6
## A slot's hotkey: 1-6, for up to six slots (v0.08).
const SLOT_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]
## Grass, the same clear colour the debug scene uses.
const CLEAR := Color("6e8230")

## The mission opens with the camera sweeping in under its banner (Last Judgement: to the Citadel, MANIFEST), and
## the clock only starts when it arrives (spec §1). Where it sweeps from and to is the mission's (MissionDef).
const INTRO_SECONDS := 2.0
## The sweep starts as far out as the zoom goes.
const INTRO_FROM_ZOOM := ZOOM_MIN
## How close the camera rests for play.
const PLAY_ZOOM := 0.6
## The tour's stops sit this far below the screen's centre (v0.10 M6, screen px at PLAY_ZOOM), so a stop and its labels
## stay clear of the banners' bar and Cael's plate above the middle.
const TOUR_RAISE := 50.0

## The ending plays out in slow motion before the results: the last blow lands, the dust settles, then the
## numbers (playtest note 5: three seconds between the mission's end and the results). Real seconds, and the
## time scale the world runs at meanwhile.
const ENDING_SECONDS := 3.0
const ENDING_TIME_SCALE := 0.3
## The ascent's slow motion (v0.11 M1, spec §6: about 2 s) in place of the ending's ENDING_SECONDS, and its banner.
const ASCEND_SECONDS := 2.0
const ASCEND_BANNER := "YOU ASCEND"

## The scripted run: [seconds, slot, ground, drag direction or Vector2.ZERO].
## Spaced so each power has finished before the next is cast (Rules.busy_left()): Heaven 8.5 s, Cinderfall 12,
## Tsunami 9.5.
const TEST_CASTS := [
	[1.0, 0, Vector2(-9.0, -11.0), Vector2(0.2, 1.0)],
	[10.0, 2, Vector2(0.8, 2.2), Vector2.ZERO],
	[22.5, 1, Vector2(-12.0, 1.0), Vector2(1.0, 0.1)],
	[32.5, 3, TownLayout.CITADEL_ORIGIN, Vector2.ZERO],
]
const TEST_SHOTS := [0.5, 2.0, 12.0, 24.0, 34.0, 44.0]
## How many banner frames the scripted run takes before it stops bothering.
const BANNER_SHOTS := 3
const TEST_END := 34.0
## The Warning's scripted run (v0.08, --mission=warning --mission-test) casts nothing and lets the bell ring: frames
## of the start, the falling star, the watchman's run under his marker, and -- the camera turned west, to
## WARNING_LOOK_AT, between WARNING_LOOK_AWAY's two times -- the edge arrow pointing back at the messenger.
const WARNING_SHOTS := [0.5, 2.5, 9.0, 15.0]
const WARNING_LOOK_AWAY := [14.0, 16.0]
const WARNING_LOOK_AT := Vector2(-12.0, 8.0)
const WARNING_TEST_END := 45.0

var _bf: Battlefield
var _town: Town
var _grid: WalkGrid
var _crowd: Crowd
var _rules: Rules
var _aim: Targeting
var _hud: Hud
## F4: the citizens' intents, the alarm stage and the gates (v0.04 debug).
var _overlay: BehaviourOverlay
## The difficulty (v0.05): Game sets it before start(); a standalone run reads --difficulty=<name>.
var difficulty := ResponseProfile.DEFAULT
## The mission to play (v0.08): Game sets it before start(); a standalone run reads --mission=<id>.
var mission_id := MissionBook.LAST_JUDGEMENT
## A night that starts with its town already warned (v0.10: the campaign's Feast after a rung Night 1). Game sets it
## before start(); a mission without acts ignores it.
var bell_rang := false
## A night on the tier board (v0.11 M1): Game sets it before start() for every mission played outside the campaign. The
## mission is then TierBook.board()'s version with `descend`'s upgrades, and its night has a Descent.
var board := false
var descend: DescendState
## The seed the board night's wishes are drawn from (Descent.seed_for()): Game sets it, and an R restart keeps it.
var wish_seed := 0
## The board night being played (v0.11 M1), or null off the board.
var _descent: Descent
## The mission being played, and its director (null for a mission without scripted actors).
var _def: MissionDef
var _director: MissionDirector
## A mission played in acts (v0.09): the night so far and the act being played; both null for a single mission.
var _night: NightState
var _act: ActDef
## The town's response managers whose banners are wired, by instance id: each is wired once (_wire_responses()).
var _wired := {}
## Banners raised while an act was being built, before its HUD was there to show them (v0.09: Act III's carry-overs --
## SOLDIERS RALLY, THE SOLDIERS TAKE THE GATES): shown once its intro has begun (_show_held_banners()).
var _held_banners: Array[String] = []
var _pressing := false
## A scripted run (--mission-test, --bench) has no mouse: the cursor sits whereever the desktop left it, which
## is off the map, so the aim preview follows the script instead of it.
var _scripted := false
## True when the mission runs on its own (play.bat before milestone 4, the scripted runs, the bench) and
## starts itself. Game sets it false before adding the node, then calls start() with the drafted loadout.
var autostart := true
## True once _ready() has finished compiling the effect shaders.
var is_prewarmed := false
## Seconds of intro left; 0 once the mission is under way.
var _intro_left := 0.0
## The intro's tour of a Night 2 mission's key places (v0.10 M6, spec §5), played in place of the sweep; null for a
## sweep, or once the camera has landed.
var _tour: IntroTour
## True from the last blow to Results: the slow-motion ending is playing out (note 9).
var _ending := false
## Seconds until the battle's layers are next fed how far the city has fallen.
var _music_in := 0.0


func _ready() -> void:
	RenderingServer.set_default_clear_color(CLEAR)
	_bf = Battlefield.new()
	_bf.name = "Battlefield"
	add_child(_bf)
	_bf.ctx.impact.dim_scale = 0.4
	_bf.ctx.field.bounds = TownLayout.MAP
	# Connected here and not in _start(): the field outlives a restart, so connecting per mission would stack
	# up a handler for every mission the player has played.
	_bf.ctx.env.structure_destroyed.connect(_on_structure_destroyed)
	_bf.ctx.env.structure_blighted.connect(_on_structure_blighted)
	var args := OS.get_cmdline_user_args()
	var scripted := "--mission-test" in args or "--bench" in args
	_scripted = scripted
	var seed_arg := Battlefield.arg_value(args, "--seed")
	var seed_value := int(seed_arg) if seed_arg != "" else (7 if scripted else Time.get_ticks_usec())
	if autostart:
		start(_loadout(args), seed_value)
	await FxParts.prewarm(_bf.ctx.distort)
	is_prewarmed = true
	prewarmed.emit()
	if "--mission-test" in args:
		_mission_test()
	elif "--bench" in args:
		# Both awaited: unawaited, quit()'s handful of frames beats bench()'s 9-second loop to
		# get_tree().quit() and the run ends before a bench[...] line is ever printed.
		var bench_act := Battlefield.arg_value(args, "--bench-act")
		var label := "mission"
		if bench_act != "":
			await _bench_jump(bench_act, args)
			label = "night-" + bench_act
		elif "--bench-beams" in args:
			await _bench_beams(args)
			label = "flame-beams"
		await _bf.bench(label)
		await _quit()


## Bench aid (v0.09): `--mission=long_night --bench --bench-act=festival|procession|judgement` skips the acts before the
## one named, then lets it run `--bench-after=SECONDS` (default 50) before the frames are timed, so the Festival's crowd
## is packed round the bonfire (it packs at 45 s). A night-only hook: the bench of every other mission is untouched.
func _bench_jump(act_id: String, args: PackedStringArray) -> void:
	while _act != null and _act.id != act_id and not _act.is_last():
		await get_tree().process_frame
		next_act(PackedStringArray(), act_id)
	var after := Battlefield.arg_value(args, "--bench-after")
	var secs := float(after) if after != "" else 50.0
	await get_tree().create_timer(secs).timeout


## Bench aid (v0.10 M4, spec §7): `--mission=vigil_flame --bench --bench-beams` lights Halcyon's Searchlight with both
## beams at once (VigilFlameDirector.bench_beams()), then lets it sweep `--bench-after=SECONDS` (default 5) so the dim,
## the cones and the pools are up before the frames are timed. The Vigil Flame only: every other bench is untouched.
func _bench_beams(args: PackedStringArray) -> void:
	var d := _director as VigilFlameDirector
	if d != null:
		d.bench_beams()
	var after := Battlefield.arg_value(args, "--bench-after")
	await get_tree().create_timer(float(after) if after != "" else 5.0).timeout


## A fresh mission: clear the world, build the town, spawn the people, hand out 100 DP and six minutes.
## `powers` is the drafted loadout in slot order; an empty array falls back to the command line's or the
## default four, so a standalone run still works.
func start(powers: PackedStringArray, seed_value: int) -> void:
	if _ending:
		# A start during the ending's slow motion (v0.09): that ending lets go once its wait is over (_play_ending()), so
		# the time scale it dipped is restored here.
		_ending = false
		_bf.ctx.impact.set_base_time_scale(1.0)
	if _director != null:
		_director.teardown()
		if is_instance_valid(_rules):
			_rules.director = null  # already let go: the old rules' teardown below must not do it twice
	_director = null
	if _descent != null:
		_descent.release()
		_descent = null
	_bf.reset(seed_value)
	for n: Node in [_town, _crowd, _rules, _aim, _hud, _overlay]:
		if is_instance_valid(n):
			if n is Town:
				(n as Town).teardown()
			elif n is Crowd:
				(n as Crowd).clear()
			elif n is Rules:
				# The old rules let the world go before the new ones take it: queue_free() is deferred, and a
				# frame with two Rules connected would count the next destroyed building twice.
				(n as Rules).teardown()
			# Parents may be mid-teardown here, so never free a tree-resident node immediately.
			if n.is_inside_tree():
				n.queue_free()
			else:
				n.free()
	_town = Town.new()
	_town.name = "Town"
	add_child(_town)
	_town.build(_bf.ctx.env, _bf.ground_plane, _bf.camera)
	_grid = WalkGrid.new().setup(_bf.ctx.env, _town)
	_crowd = Crowd.new()
	_crowd.name = "Crowd"
	add_child(_crowd)
	_crowd.setup(_bf.ctx.field, _bf.ctx.env, _town, _grid, _bf.ctx.world, seed_value)
	_bf.ctx.crowd = _crowd
	_crowd.sfx = _bf.ctx.sfx
	_town.sfx = _bf.ctx.sfx
	var args := OS.get_cmdline_user_args()
	_def = _mission_def(args)
	var on_board := _on_board(args)
	if autostart and wants_board(args):
		# A scripted run's --board (v0.11 M1): the night's seed is the first night's, as a fresh god's.
		wish_seed = Descent.seed_for(descend.night if descend != null else 0, _def.id)
	# A board night (v0.11 M1): its wishes, its Tier 5 Gaze and its ascent, handed to each act's Rules in _build_act().
	_descent = Descent.new().setup(_def, wish_seed) if on_board and TierBook.has(_def.id) else null
	_night = NightState.new() if _def.has_acts() else null
	if _night != null:
		_night.bell_rang = bell_rang
	_act = _def.first_act() if _night != null else null
	if _act != null:
		_act.night = _night
	var play: MissionDef = _act if _act != null else _def
	var tier := difficulty
	if autostart and Battlefield.arg_value(args, "--difficulty") != "":
		tier = ResponseProfile.tier_named(Battlefield.arg_value(args, "--difficulty"))
	_crowd.profile = _act.town(_night) if _act != null else _def.response_profile(tier)
	var wanted := Battlefield.arg_value(args, "--people")
	var people := int(wanted) if wanted != "" else PEOPLE
	var citizens := roundi(float(people) * float(Crowd.CITIZENS) / float(PEOPLE))
	_crowd.spawn(citizens, people - citizens)

	_wired.clear()
	_build_act(powers if not powers.is_empty() else _loadout(OS.get_cmdline_user_args()))
	_overlay = BehaviourOverlay.new().setup(_crowd, _bf)
	_overlay.name = "BehaviourOverlay"
	if "--behaviour" in OS.get_cmdline_user_args():
		BehaviourOverlay.shown = true
	add_child(_overlay)
	_begin_intro(play)
	_show_held_banners()


## One act's Rules, director, aim and HUD (v0.09): start() builds the first, next_act() each one after. The order the
## nodes are made in is Last Judgement's and The Warning's since v0.08 -- their instance order feeds the staggers.
func _build_act(loadout: PackedStringArray) -> void:
	var play: MissionDef = _act if _act != null else _def
	_rules = Rules.new()
	_rules.name = "Rules"
	add_child(_rules)
	_rules.setup(loadout, _bf.ctx, _bf.ctx.env, _bf.ctx.field, _crowd, _town, play)
	_bf.ctx.rules = _rules
	_rules.over.connect(_on_over)
	# Nothing shows a banner until the HUD below is made: the director's setup and the town's responses may raise some.
	var held: Array[String] = []
	var hold := func(text: String) -> void: held.append(text)
	_rules.banner.connect(hold)
	var made := play.make_director()
	if made != null:
		if _descent != null:
			# Before the director's setup() gathers or appoints anyone: the wishes are heard and their people reserved first.
			_descent.reserve(_rules, made)
		_director = made.setup(_rules, _crowd, _town, _bf.ctx, _night)
		_rules.director = _director
	if _descent != null:
		_descent.attach(_rules, _director)
	_wire_responses()

	_aim = Targeting.new()
	_aim.name = "Targeting"
	_bf.ground_plane.add_child(_aim)
	_aim.setup(_rules, _crowd)
	_aim.picked.connect(func(s: int) -> void:
		if s >= 0:
			UiSound.play(&"ui_focus"))

	_hud = Hud.new()
	_hud.name = "Hud"
	_bf.hud_layer.add_child(_hud)
	_hud.setup(_rules, _crowd, _town, _aim)
	_rules.banner.disconnect(hold)
	_held_banners = held


## The banners held while the act was built, after its intro's own (the HUD queues them).
func _show_held_banners() -> void:
	var held := _held_banners
	_held_banners = []
	for text in held:
		_rules.banner.emit(text)


## The town's responses announce themselves on the banner. Each lambda reads `_rules` when it fires, so the act being
## played shows it; each manager is wired once (v0.09: an act after the first, or a raised town, calls this again).
func _wire_responses() -> void:
	if _wire_once(_crowd):
		_crowd.rallied.connect(func(): _rules.banner.emit("SOLDIERS RALLY"))
	if _crowd.bell != null and _wire_once(_crowd.bell):
		_crowd.bell.climbing_started.connect(func():
			_rules.banner.emit(bell_hand(_crowd.bell) + " CLIMBS THE TOWER"))  # (after a takeover too)
		_crowd.bell.rung.connect(func(): _rules.banner.emit("THE BELL TOLLS - THE TOWN IS WARNED"))
		_crowd.bell.silenced.connect(func(_why: String): _rules.banner.emit("THE BELL IS SILENCED"))
		_crowd.bell.keeper_replaced.connect(func():
			_rules.banner.emit(bell_hand(_crowd.bell) + " TAKES THE BELL ROPE"))
	if _crowd.engineers != null and not _crowd.engineers.teams.is_empty() and _wire_once(_crowd.engineers):
		_crowd.engineers.turned_out.connect(func(): _rules.banner.emit("THE ENGINEERS TURN OUT"))
		_crowd.engineers.rebuilt.connect(func(s: Structure):
			var what := "THE DOCK" if s.role == &"dock" else ("THE BRIDGE" if s.kind == Structure.Kind.BRIDGE else
				("THE POSTERN" if s.art_tag == &"postern" else
				("THE MAIN GATE" if s.footprint == TownLayout.MAIN_GATE else "THE SIDE GATE")))
			_rules.banner.emit(what + " IS REBUILT"))
	if _crowd.ferry != null and _crowd.ferry.state != RiverFerry.State.ENDED and _wire_once(_crowd.ferry):
		_crowd.ferry.opened.connect(func(): _rules.banner.emit("BOATS TAKE PEOPLE FROM THE DOCK"))
		# Act III's last ferry announces itself (JudgementDirector's event), so it gets no second banner.
		_crowd.ferry.closed.connect(func(why: String):
			if why != "the last ferry":
				_rules.banner.emit("THE BOATS ARE STOPPED"))
	if _crowd.marshals != null and _wire_once(_crowd.marshals):
		_crowd.marshals.posted.connect(func(): _rules.banner.emit("THE SOLDIERS TAKE THE GATES"))
	if _crowd.rescue != null and _wire_once(_crowd.rescue):
		_crowd.rescue.first_rescue.connect(func(): _rules.banner.emit("SURVIVORS DUG FROM THE RUBBLE"))
	if _crowd.rite != null and _crowd.rite.state != BanishingRite.State.ENDED and _wire_once(_crowd.rite):
		var rite := _crowd.rite
		rite.gathering.connect(func(): _rules.banner.emit("THE CLERGY GATHER AT THE CATHEDRAL"))
		rite.started.connect(func(): _rules.banner.emit("THE BANISHING RITE BEGINS"))
		rite.broken.connect(func(_why: String): _rules.banner.emit("THE RITE IS BROKEN"))
		rite.ended.connect(func(_why: String): _rules.banner.emit("THE RITE IS ENDED"))
		rite.completed.connect(func():
			_rules.banner.emit("THE CLERGY BANISH YOU - %d s LOST" % roundi(_rules.banish())))


## True the first time a manager is asked about, and marks it wired.
func _wire_once(manager: Object) -> bool:
	var id := manager.get_instance_id()
	if _wired.has(id):
		return false
	_wired[id] = true
	return true


## The camera, the intro sweep and its banner for the mission or act about to be played.
func _begin_intro(play: MissionDef) -> void:
	if _scripted:
		# The scripted runs time their casts from the first frame and frame the town the way milestone 3 did,
		# so their captures and numbers stay comparable: no intro for them.
		_tour = null
		_intro_left = 0.0
		_bf.camera.zoom = Vector2.ONE * PLAY_ZOOM
		var framed := Vector2(0, -2) if play.id == MissionBook.LAST_JUDGEMENT else play.camera_at
		_bf.camera.position = Iso.ground_to_screen(framed).round()
	else:
		_rules.set_process(false)  # the clock waits for the camera
		_bf.camera.zoom = Vector2.ONE * INTRO_FROM_ZOOM
		_bf.camera.position = Iso.ground_to_screen(play.intro_from).round()
		var stops: Array = _director.tour() if _director != null else []
		_tour = IntroTour.new().setup(play.intro_from, raised(stops), play.camera_at) if not stops.is_empty() else null
		_intro_left = _tour.seconds() if _tour != null else INTRO_SECONDS
		if play.intro_banner != "":
			_rules.banner.emit(play.intro_banner)


## The next act of the night (v0.09), in the same town: the old act's director hands over what it carries and lets go,
## the old Rules let go of the world, and the act chosen (`path` after a choice card, else the only one) begins with a
## fresh Rules, director, aim and HUD -- every cooldown ready -- after its own intro sweep.
func next_act(powers: PackedStringArray, path := "") -> void:
	if _night == null or _act == null or _act.is_last():
		return
	var ids := _act.next
	var id := path if path != "" and ids.has(path) else String(ids[0])
	if ids.size() > 1:
		_night.path = id
	if _director != null:
		_director.carry(_night)
		_director.teardown()
		_rules.director = null
	_director = null
	if _descent != null:
		_descent.next_act(_rules)  # its seconds count toward the night's time
	_rules.teardown()
	_rules.queue_free()
	# Every power still playing ends here, with the act that cast it: an Act I Heaven Splitter must not fall on the
	# Prince or the Mayor during Act II's intro (v0.09 final review).
	_bf.end_powers()
	_aim.queue_free()
	_hud.queue_free()
	_pressing = false  # a press held over the old aim is not the new one's to release
	_act = _def.act(id)
	_act.night = _night
	# The town rises to the act's (never lowers): what turned on is wired for its banners and announced.
	var raised := _crowd.raise_profile(_act.town(_night))
	_wire_responses()
	Engine.time_scale = 1.0
	_bf.ctx.impact.set_base_time_scale(1.0)
	_ending = false
	_build_act(powers if not powers.is_empty() else _act.default_loadout)
	_begin_intro(_act)
	if not raised.is_empty():
		# After the act's own banner (the HUD queues them).
		_rules.banner.emit("THE TOWN PREPARES: " + ", ".join(raised).to_upper())
	_show_held_banners()


## The acts that may follow the one being played (v0.09): two for the choice card, one, or none after the last act or
## for a single mission.
func next_choices() -> Array:
	if _night == null or _act == null or _act.is_last():
		return []
	var out := []
	for id in _act.next:
		var a := _def.act(id)
		a.night = _night  # the interlude's card line and objectives read the night so far
		out.append(a)
	return out


## The night being played (v0.09), or null for a single mission.
func night() -> NightState:
	return _night


## The act being played (v0.09), or null for a single mission.
func act() -> ActDef:
	return _act


## The board night being played (v0.11 M1), or null.
func descent() -> Descent:
	return _descent


## The god ascends (v0.11 M1, spec §6): once a board night's main objective is done, F (or the ASCEND plate) ends it, won.
## False when there is nothing to ascend from: off the board, before the main objective, in the intro or the ending.
func ascend() -> bool:
	if not started() or _ending or in_intro() or _descent == null or not _rules.main_done or _rules.finished:
		return false
	return _rules.ascend()


## The ascent's key (spec §6): F pressed -- not an echo, nor a release. Nothing else in a mission uses it.
static func ascends(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo and event.physical_keycode == KEY_F
	return false


## True while the sweep is still landing: the world does not yet respond to input or run its clock.
## The running mission's rules (its clock, DP, stability), for whoever drives it. Null until started().
func rules() -> Rules:
	return _rules


func in_intro() -> bool:
	return _intro_left > 0.0


## The intro is a tour of the mission's key places (v0.10 M6), not the sweep.
func touring() -> bool:
	return in_intro() and _tour != null


## Ends the intro at once (v0.10 M6): the sweep or the tour lands, and the clock starts.
func skip_intro() -> void:
	if in_intro():
		_land()


## The intro is over (v0.10 M6): the camera rests on the mission's own spot, the tour's caption goes, and the clock starts.
func _land() -> void:
	var play: MissionDef = _act if _act != null else _def
	_intro_left = 0.0
	_tour = null
	_bf.camera.position = Iso.ground_to_screen(play.camera_at).round()
	_bf.camera.zoom = Vector2.ONE * PLAY_ZOOM
	if is_instance_valid(_hud):
		_hud.set_caption("")
	_rules.set_process(true)


## A press that skips the tour (v0.10 M6, spec §5): Space, Enter or a left click, pressed -- not an echo, nor a release.
static func skips_tour(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo and event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false


## The tour's stops with the camera looking TOUR_RAISE above each (v0.10 M6): each ground point moved up the screen by
## TOUR_RAISE at PLAY_ZOOM, its caption kept.
static func raised(stops: Array) -> Array:
	var out := []
	for s: Array in stops:
		var up := Iso.ground_to_screen(s[0] as Vector2) - Vector2(0.0, TOUR_RAISE / PLAY_ZOOM)
		out.append([Iso.screen_to_ground(up), s[1]])
	return out


## The mission to play: Game's choice, or for a standalone run the command line's --mission=<id> (v0.08); on the board, its
## tier's version (v0.11 M1).
func _mission_def(args: PackedStringArray) -> MissionDef:
	var wanted_mission := Battlefield.arg_value(args, "--mission") if autostart else ""
	return def_for(wanted_mission if wanted_mission != "" else mission_id, _on_board(args), descend)


## The mission for `id` (v0.11 M1): on the board, its tier's version (TierBook.board(), with `state`'s upgrades); else
## MissionBook's -- the campaign's, a standalone run's, a scripted run's.
static func def_for(id: String, on_board: bool, state: DescendState) -> MissionDef:
	if on_board and TierBook.has(id):
		return TierBook.board(id, state)
	return MissionBook.get_mission(id)


## This is a board night (v0.11 M1): Game said so, or a standalone run was given --board.
func _on_board(args: PackedStringArray) -> bool:
	return board or (autostart and wants_board(args))


## The command line asks for the board's version of the mission (v0.11 M1): `--mission=<id> --board --mission-test` (or --bench)
## plays the tier's clock, readiness and budget, its wishes and its ascent, as Game does.
static func wants_board(args: PackedStringArray) -> bool:
	return "--board" in args


## The drafted loadout: the command line's, or the mission's default. _ready() asks before start() has chosen the
## mission, so it is looked up here when there is none yet.
func _loadout(args: PackedStringArray) -> PackedStringArray:
	var wanted := Battlefield.arg_value(args, "--loadout")
	var def := _def if _def != null else _mission_def(args)
	var keys := PackedStringArray(def.default_loadout)
	if wanted != "":
		keys = PackedStringArray()
		for key in wanted.split(","):
			if PowerBook.get_power(key).is_empty():
				push_warning("Unknown power in --loadout: " + key)
			else:
				keys.append(key)
	return keys


func _on_structure_destroyed(s: Structure, _kind: StringName) -> void:
	if is_instance_valid(_town) and is_instance_valid(_rules) and s == _town.bridge:
		_rules.banner.emit("THE BRIDGE HAS FALLEN")


## Blight landed (v0.05): what it ruined, for the player -- the town itself is not told.
func _on_structure_blighted(s: Structure) -> void:
	if is_instance_valid(_rules):
		_rules.banner.emit(blight_banner(s))


## Who is on the bell rope, for its banners: the bellkeeper, a soldier who took it over (v0.07), or the watchman -- or
## a citizen the warning passed to -- climbing in a dead keeper's place (v0.08, The Warning).
static func bell_hand(bell: BellNetwork) -> String:
	if not is_instance_valid(bell.keeper):
		return "THE BELLKEEPER"
	var p := bell.keeper
	if p.soldier:
		return "A SOLDIER"
	if p.profile == null or p.profile.role == CitizenProfile.Role.BELLKEEPER:
		return "THE BELLKEEPER"
	return "THE WATCHMAN" if p.profile.role == CitizenProfile.Role.WATCHMAN else "A CITIZEN"


static func blight_banner(s: Structure) -> String:
	if s.art_tag == &"bell_tower":
		return "BLIGHT - THE BELL IS CRACKED"
	if s.role == &"temple":
		return "BLIGHT - THE CATHEDRAL IS DEFILED"
	if s.role == &"dock":
		return "BLIGHT - THE DOCK ROTS"
	if s.kind == Structure.Kind.GATE:
		var which := "THE POSTERN" if s.art_tag == &"postern" else (
			"THE MAIN GATE" if s.footprint == TownLayout.MAIN_GATE else "THE SIDE GATE")
		return "BLIGHT - %s IS JAMMED" % which
	return "BLIGHT - THE %s IS POISONED" % ("WELL" if s.art_tag == &"well" else "FOUNTAIN")


func _on_over(won: bool, reason: String) -> void:
	_rules.banner.emit(ASCEND_BANNER if _rules.ascended else ResultsScreen.title_for(won, reason))
	if _scripted:
		# The scripted runs have no Results screen to show, so they keep printing what they found.
		if _act != null:
			print("MISSION act=%s won=%s reason=%s time=%.1f" % [_act.id, won, reason, float(_rules.result().time)])
		if _rules.mission.scored:
			print("MISSION result won=%s reason=%s score=%d rank=%s" % [won, reason, _rules.score(), _rules.rank()])
			for line: Dictionary in _rules.stat_lines():
				print("  %-22s %8s %6d" % [line.label, line.value, line.points])
		else:
			var res := _rules.result()
			print("MISSION result won=%s reason=%s time=%.1f relays=%s" % [won, reason, float(res.time),
				res.get("relays", 0)])
	_play_ending()


func _play_ending() -> void:
	_ending = true
	_aim.unfocus()
	var ended := _rules
	if not _scripted:
		# The scripted runs keep milestone 3's timing: no slow motion for them.
		_bf.ctx.impact.set_base_time_scale(ENDING_TIME_SCALE)
		var wait := ASCEND_SECONDS if _rules.ascended else ENDING_SECONDS
		await get_tree().create_timer(wait, true, false, true).timeout
		if ended != _rules:
			# A start() or next_act() came during the slow motion (v0.09): it restored the time scale, and this ending
			# is no longer the one being played -- reporting it now would speak for the wrong mission or act.
			return
		_bf.ctx.impact.set_base_time_scale(1.0)
	var res := _rules.result()
	if _night == null:
		finished.emit(_with_descent(res))
		return
	_night.record(_act.id, res, _crowd)
	if _act.is_last():
		finished.emit(_with_descent(_night.result(res, _def.id, _def.scored)))
	else:
		act_over.emit(res)


## A board night's result (v0.11 M1) with its Descent's report merged in ("descend"); any other as it is.
func _with_descent(res: Dictionary) -> Dictionary:
	if _descent != null:
		res.merge(_descent.report(_rules))
	return res


func _unhandled_input(event: InputEvent) -> void:
	if not started():
		return
	if _ending:
		return  # the mission is over; nothing to aim or pause
	if in_intro() and not (event is InputEventKey and event.physical_keycode == KEY_ESCAPE):
		if touring() and skips_tour(event):
			get_viewport().set_input_as_handled()
			skip_intro()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var i := SLOT_KEYS.find(event.physical_keycode)
		if i >= 0 and i < _rules.loadout.size():
			_aim.pick(i)
		elif event.physical_keycode == KEY_R:
			start(PackedStringArray(), Time.get_ticks_usec())
		elif ascends(event):
			ascend()
		elif event.physical_keycode == KEY_ESCAPE:
			# Esc first calls off a held press, then unfocuses the power. With nothing focused it is the
			# pause menu's -- or, for a mission running on its own with no Game around it, still the way out.
			if _aim.cancel():
				pass  # a held press was called off
			elif _aim.slot >= 0:
				_aim.unfocus()
			elif autostart:
				_quit()
			else:
				# Handled here, so the same Esc cannot reach the pause menu it is about to open and close it again.
				get_viewport().set_input_as_handled()
				pause_pressed.emit()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		_pan(-event.relative / _bf.camera.zoom.x)
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var z := _bf.camera.zoom.x * (1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.1)
		_bf.camera.zoom = Vector2.ONE * clampf(z, ZOOM_MIN, ZOOM_MAX)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# Right-click first calls off a held press (note 10), and otherwise lets go of the focused power (note 7).
		if not _aim.cancel():
			_aim.unfocus()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# A click on a HUD slot focuses that power instead of casting into the town under it.
			var on_slot := _hud.slot_at(event.position)
			if on_slot >= 0 and on_slot < _rules.loadout.size():
				_aim.pick(on_slot)
				return
			_pressing = true
			_aim.press(_bf.mouse_ground())
		elif _pressing:
			_pressing = false
			_aim.release(_bf.mouse_ground())


func _process(delta: float) -> void:
	if not started():
		return
	if not _ending:
		_music_in -= delta
		if _music_in <= 0.0:
			_music_in = 0.5
			Music.set_intensity(1.0 - _rules.stability.total())
	if _intro_left > 0.0:
		_intro_left = maxf(0.0, _intro_left - delta)
		if _tour != null:
			_tour.step(delta)
			_bf.camera.position = Iso.ground_to_screen(_tour.camera()).round()
			_bf.camera.zoom = Vector2.ONE * lerpf(INTRO_FROM_ZOOM, PLAY_ZOOM, _tour.zoom_k())
			_hud.set_caption(_tour.caption())
		else:
			var k := 1.0 - _intro_left / INTRO_SECONDS
			var smooth := k * k * (3.0 - 2.0 * k)  # not "ease": that is a global function, and shadowing it warns
			var play: MissionDef = _act if _act != null else _def
			_bf.camera.position = Iso.ground_to_screen(play.intro_from.lerp(play.camera_at, smooth)).round()
			_bf.camera.zoom = Vector2.ONE * lerpf(INTRO_FROM_ZOOM, PLAY_ZOOM, smooth)
		if _intro_left <= 0.0:
			_land()
		return  # the camera is the intro's until it lands: no panning, no aiming
	var pan := Battlefield.key_pan_dir()
	if pan != Vector2.ZERO:
		# Pan in real time regardless of hit-stop, faster when zoomed out.
		var real_delta := delta / maxf(Engine.time_scale, 0.001)
		_pan(pan.normalized() * PAN_SPEED * real_delta / _bf.camera.zoom.x)
	if not _scripted:
		_aim.hover(_bf.mouse_ground())


func _pan(by: Vector2) -> void:
	_bf.camera.position = (_bf.camera.position + by).clamp(PAN_MIN, PAN_MAX)


## A fixed mission: four casts on a timetable, screenshots at the interesting moments, and one result line. The
## Warning's (v0.08) casts nothing: see WARNING_SHOTS.
func _mission_test() -> void:
	var judgement := _def.id == MissionBook.LAST_JUDGEMENT
	var prefix := "mission" if judgement else _def.id
	if judgement:
		# Aim the Nova at the Citadel and cast nothing: the first screenshot is the aim preview on a whole town.
		_aim.pick(3)
		_aim.hover(TownLayout.CITADEL_ORIGIN)
	var casts := TEST_CASTS.duplicate() if judgement else []
	var shots := TEST_SHOTS.duplicate() if judgement else WARNING_SHOTS.duplicate()
	var looks := [] if judgement else WARNING_LOOK_AWAY.duplicate()
	var framed := _bf.camera.position
	var end := TEST_END if judgement else WARNING_TEST_END
	# Banners are the one thing a fixed timetable cannot catch: they fire when the town happens to break. The
	# run takes its own shot a moment after each of the first few, so the layout is actually seen.
	var banner_shots: Array[String] = []
	_rules.banner.connect(func(text: String) -> void:
		if banner_shots.size() < BANNER_SHOTS:
			banner_shots.append(text)
	)
	var banners_taken := 0
	var t := 0.0
	while t < end:
		await get_tree().process_frame
		t += get_process_delta_time()
		if not looks.is_empty() and t >= float(looks[0]):
			looks.pop_front()
			_bf.camera.position = framed if looks.is_empty() else Iso.ground_to_screen(WARNING_LOOK_AT).round()
		while not casts.is_empty() and t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			var slot := int(c[1])
			var extra := {}
			if (c[3] as Vector2) != Vector2.ZERO:
				extra["dir"] = (c[3] as Vector2).normalized()
			# Aim first, so the captured frames show the preview and the picked slot the way a player would see
			# them. Nothing moves the mouse in a scripted run, and the cursor's own ground position is off-map.
			_aim.pick(slot)
			_aim.hover(c[2])
			_rules.cast(slot, c[2], extra)
		while not shots.is_empty() and t >= float(shots[0]):
			var at: float = shots.pop_front()
			await _bf.save_capture("%s_%04d.png" % [prefix, roundi(at * 100.0)])
		while banners_taken < banner_shots.size():
			banners_taken += 1
			await _bf.save_capture("%s_banner_%d.png" % [prefix, banners_taken])
			print("banner ", banners_taken, ": ", banner_shots[banners_taken - 1])
	print("MISSION test buildings=%d citizens=%d escaped=%d alarm=%d stability=%d%% citadel=%d%%" % [
		_rules.buildings_down, _crowd.alive_citizens(), _crowd.escaped_count, roundi(_crowd.alarm),
		roundi(_rules.stability.total() * 100.0), roundi(_town.citadel.fraction() * 100.0)])
	await _quit()


## Whether start() has run. Between add_child() and the end of the shader prewarm there is a battlefield but
## no town, rules or aim yet, and nothing in the mission may touch them.
func started() -> bool:
	return is_instance_valid(_rules)


## Battlefield.quit() stops its own Sfx pool and waits out the audio thread before it exits; the crowd's panic
## bed is not in that pool, so it is silenced first, or a bed still playing at that moment leaks its playback.
func _quit() -> void:
	if is_instance_valid(_crowd):
		_crowd.stop_bed()
	await _bf.quit()


## Stop the world without stopping the menu over it. The whole mission lives under this node, so pausing the
## subtree freezes the town, the crowd, the effects and the clock together.
func set_frozen(frozen: bool) -> void:
	process_mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
	if is_instance_valid(_crowd):
		_crowd.pause_bed(frozen)
