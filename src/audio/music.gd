class_name Music
extends Node
## Background music, played by orchestral samples (tools/audio/music/, tools/audio/music_render.py): a dark choral theme on
## the title and the draft, its own piece on God's Paths (the god select: a base and, over it, the picked god's school), and in the
## mission a calm piece for the town as it is (CALM: by day, by night, the Capital's own), a tension stem as it starts to
## slip, and a battle loop in three stems -- base, drums, lead -- layered in as the city falls (the music pass). Not positional, not
## tied to a battlefield, and alive across every screen change so one track can fade into the next. Built the way
## UiSound is: one node under the scene tree's root, made the first time music is asked for, silent headless.

const THEME := &"music_theme"
const BATTLE := [&"music_battle_base", &"music_battle_drums", &"music_battle_lead"]
## The mission's calm pieces: the town by day, the town by night, the Capital by day, and the moods' own -- the festival's
## dance and the rite's chant (calm_cue()).
const CALM := [&"music_town_day", &"music_town_night", &"music_capital_day", &"music_calm_festival", &"music_calm_rite"]
## A mood's own calm piece, in place of the town's (MissionDirector.music_mood()).
const MOOD_CALM := {&"festival": &"music_calm_festival", &"rite": &"music_calm_rite"}
## The chase (music by situation): two stems in step, the run and its drums, played while a mission's pursuit is on
## (mood &"chase") in place of the calm piece, the tension and the battle -- until the city is falling (CHASE_UNTIL), when the
## battle takes over.
const CHASE := [&"music_chase_base", &"music_chase_drums"]
const CHASE_UNTIL := 0.66
## What raises the music (music by situation): the heat is the most of the city's fall, the alarm's stage (ALARM_HEAT, by
## AlarmManager.Stage) and the crowd's panic (PANIC_HEAT at full panic), so a cast that sends people running brings the
## tension and the battle in before a single building falls. It rises at once and cools by COOL_RATE a second.
const ALARM_HEAT := [0.0, 0.12, 0.25, 0.4, 0.55, 1.0]
const PANIC_HEAT := 0.75
const COOL_RATE := 0.03
## The dread before the fight: the battle's harmony and length, started with its stems so it stays in step.
const TENSION := &"music_tension"
## The music's level under everything else (v0.11.2: -10 -> -16, the playtest's "too loud"; its own bus, so the Options slider moves it).
const DB := -16.0
const BUS := &"Music"
## Seconds for a track or a layer to fade fully in or out.
const FADE := 1.2
## How far the music drops while the pause menu is up.
const DUCK_DB := -12.0
## Stingers (natural sound pass 6): short orchestral cues for a moment -- the night begins, its main objective is done,
## won, lost -- played over the music at STING_DB above it, while the loops dip by STING_DIP_DB so it stands clear.
const STINGS := [&"music_sting_start", &"music_sting_objective", &"music_sting_win", &"music_sting_lose"]
const STING_DB := 3.0
## God's Paths (the god select): a temple piece (PATHS, 64 beats) and, over it, one layer per school (PATH_LAYERS, 16 beats on the
## same four-bar progression, so each fits any block of the base); the layer of the god picked now fades in, the others out.
const PATHS := &"music_paths"
const PATH_LAYERS := {
	"ruin": &"music_paths_ruin", "passage": &"music_paths_passage", "veil": &"music_paths_veil",
	"decree": &"music_paths_decree", "death": &"music_paths_death", "dominion": &"music_paths_dominion",
}
const STING_DIP_DB := -8.0

static var _node: Music

var _theme: AudioStreamPlayer
var _stems: Array[AudioStreamPlayer] = []
var _calm: Array[AudioStreamPlayer] = []
var _tension: AudioStreamPlayer
var _paths: AudioStreamPlayer
var _layers: Dictionary = {}  ## school type -> its layer's player
var _paths_gain := 0.0
var _layer_gain: Dictionary = {}  ## school type -> its layer's gain (0..1)
var _path := ""  ## the school type picked on God's Paths
var _calm_gain: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
var _chase: Array[AudioStreamPlayer] = []
var _chase_gain := 0.0
var _mood := &""  ## the mission's mood now (MissionDirector.music_mood())
var _tension_gain := 0.0
## Current gain (0..1) of the theme and of each stem, eased toward their targets.
var _theme_gain := 0.0
var _stem_gain: Array[float] = [0.0, 0.0, 0.0]
var _want := &""
var _intensity := 0.0
var _ducked := false
var _sting: AudioStreamPlayer
## Seconds the current stinger still plays, and how far the loops sit under it now.
var _sting_left := 0.0
var _sting_dip := 0.0
var _pending: AudioStream  ## a stinger asked for before the node was in the tree
## Latched by stop_all(): once true, _process() neither fades nor restarts a player -- without this a stem
## stopped for the quit path's audio-thread wait would just be started right back up next frame.
var _stopped := false


## What should be playing: &"theme", &"paths", &"battle", or &"" for silence. Fades from whatever is playing now.
static func play(track: StringName) -> void:
	var m := _instance()
	if m != null:
		m._switch(track)


## The god picked on God's Paths (a GodTree.RING type): its school's layer plays over the paths piece.
static func set_path(type: String) -> void:
	var m := _instance()
	if m != null:
		m._path = type


## Each school layer's volume while `track` plays with `type` picked: full for that school on God's Paths, else silent.
static func layer_gains(track: StringName, type: String) -> Dictionary:
	var out := {}
	for k: String in PATH_LAYERS:
		out[k] = 1.0 if track == &"paths" and k == type else 0.0
	return out


## The mission's mood now: &"" (the town's own), &"chase", &"festival" or &"rite".
static func set_mood(mood: StringName) -> void:
	var m := _instance()
	if m != null:
		m._mood = mood


## The music's heat from the situation: the city's fall (0..1), the alarm's stage (AlarmManager.Stage) and the crowd's panic (0..1).
static func heat(fall: float, stage: int, panic: float) -> float:
	return clampf(maxf(fall, maxf(float(ALARM_HEAT[clampi(stage, 0, ALARM_HEAT.size() - 1)]), panic * PANIC_HEAT)), 0.0, 1.0)


## The heat after `dt` seconds of the situation at `target`: up at once, down by COOL_RATE a second.
static func cool(was: float, target: float, dt: float) -> float:
	return target if target >= was else maxf(target, was - COOL_RATE * dt)


## Whether the chase plays: the mood is the chase and the city is not yet falling.
static func chasing(mood: StringName, intensity: float) -> bool:
	return mood == &"chase" and intensity < CHASE_UNTIL


## How far the city has fallen, 0 (standing) to 1 (falling): how many battle layers are in.
static func set_intensity(x: float) -> void:
	var m := _instance()
	if m != null:
		m._intensity = clampf(x, 0.0, 1.0)


## Plays one of STINGS over the music (and over silence, on the results).
static func sting(cue: StringName) -> void:
	var m := _instance()
	if m != null and STINGS.has(cue):
		m._play_sting(cue)


static func set_ducked(on: bool) -> void:
	var m := _instance()
	if m != null:
		m._ducked = on


static func is_ducked() -> bool:
	return is_instance_valid(_node) and _node._ducked


static func current() -> StringName:
	return _node._want if is_instance_valid(_node) else &""


## Each battle stem's volume at an intensity: the base from a fifth of the way, the drums from a third, the lead from
## two thirds, each fading in so the music thickens rather than switches. Before the base the town's calm piece and the
## tension stem play (calm_gain(), tension_gain()).
static func stem_gains(intensity: float) -> Array[float]:
	return [clampf((intensity - 0.2) / 0.13, 0.0, 1.0), clampf((intensity - 0.33) / 0.17, 0.0, 1.0),
		clampf((intensity - 0.66) / 0.17, 0.0, 1.0)]


## The calm piece's volume: full while the city stands, gone by the time the battle's base is in.
static func calm_gain(intensity: float) -> float:
	return 1.0 - smoothstep(0.08, 0.3, intensity)


## The tension stem's volume: in as the city starts to slip, and kept under the battle after.
static func tension_gain(intensity: float) -> float:
	return smoothstep(0.06, 0.22, intensity)


## Which of CALM the mission plays: a mood's own piece, else the town by night, else the Capital's own by day, else the town by day.
static func calm_cue(night: bool, capital: bool, mood := &"") -> StringName:
	if MOOD_CALM.has(mood):
		return MOOD_CALM[mood]
	return CALM[1] if night else (CALM[2] if capital else CALM[0])


## Force every player silent at once, latched so nothing restarts it. Call this before the quit path's
## audio-thread wait -- the same reason Crowd's panic bed is stopped before Battlefield.quit()'s wait, and
## UiSound.stop_all() before Game's: a loop still playing when the process quits leaks its playback.
static func stop_all() -> void:
	if is_instance_valid(_node):
		_node._stop_all()


static func _instance() -> Music:
	if DisplayServer.get_name() == "headless":
		return null  # no audio, and a node made during the headless suite would outlive it
	if not is_instance_valid(_node):
		var tree := Engine.get_main_loop() as SceneTree
		if tree == null or tree.root == null:
			return null
		_node = Music.new()
		_node.name = "Music"
		tree.root.add_child.call_deferred(_node)
	return _node


func _ready() -> void:
	_sting = AudioStreamPlayer.new()
	_sting.bus = BUS
	add_child(_sting)
	if _pending != null:
		_start_sting(_pending)
		_pending = null
	_theme = _player(THEME)
	for cue: StringName in BATTLE:
		_stems.append(_player(cue))
	for cue: StringName in CALM:
		_calm.append(_player(cue))
	_tension = _player(TENSION)
	for cue: StringName in CHASE:
		_chase.append(_player(cue))
	_paths = _player(PATHS)
	for k: String in PATH_LAYERS:
		_layers[k] = _player(PATH_LAYERS[k])
		_layer_gain[k] = 0.0


func _player(cue: StringName) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = Sfx.load_stream(cue)
	p.volume_db = -80.0
	p.bus = BUS
	add_child(p)
	return p


func _play_sting(cue: StringName) -> void:
	if _stopped:
		return
	var stream := Sfx.load_stream(cue)
	if stream == null:
		return
	_sting_left = stream.get_length()
	if _sting == null:
		_pending = stream  # _ready() plays it
		return
	_start_sting(stream)


func _start_sting(stream: AudioStream) -> void:
	_sting.stream = stream
	_sting.volume_db = DB + STING_DB + (DUCK_DB if _ducked else 0.0)
	_sting.play()


func _switch(track: StringName) -> void:
	if track == _want:
		return
	_want = track
	if not is_inside_tree():
		return  # _process picks the wish up once the node is in
	if track == &"battle":
		_start_battle()
	elif track == &"theme" and not _theme.playing:
		_theme.play(0.0)
	elif track == &"paths" and not _paths.playing:
		_start_paths()


func _process(delta: float) -> void:
	if _theme == null or _stopped:
		return
	if _want == &"battle" and not _stems[0].playing:
		_start_battle()
	elif _want == &"theme" and not _theme.playing:
		_theme.play(0.0)
	elif _want == &"paths" and not _paths.playing:
		_start_paths()
	var step := delta / FADE
	_theme_gain = move_toward(_theme_gain, 1.0 if _want == &"theme" else 0.0, step)
	var targets: Array[float] = [0.0, 0.0, 0.0]
	var chase := _want == &"battle" and chasing(_mood, _intensity)
	if _want == &"battle" and not chase:
		targets = stem_gains(_intensity)
	for i in _stems.size():
		_stem_gain[i] = move_toward(_stem_gain[i], float(targets[i]), step)
	var battle := _want == &"battle"
	var calm := calm_cue(TownLook.active == Town.Look.NIGHT, City.current().id() == &"capital", _mood) if battle and not chase else &""
	for i in _calm.size():
		_calm_gain[i] = move_toward(_calm_gain[i], calm_gain(_intensity) if CALM[i] == calm else 0.0, step)
		if _calm_gain[i] > 0.0 and not _calm[i].playing:
			_calm[i].play(0.0)
	_tension_gain = move_toward(_tension_gain, tension_gain(_intensity) if battle and not chase else 0.0, step)
	_chase_gain = move_toward(_chase_gain, 1.0 if chase else 0.0, step)
	if _chase_gain > 0.0 and not _chase[0].playing:
		for p in _chase:
			p.play(0.0)  # together, so the two stems stay in step
	_sting_left = maxf(_sting_left - delta, 0.0)
	_sting_dip = move_toward(_sting_dip, STING_DIP_DB if _sting_left > 0.5 else 0.0, 24.0 * delta if _sting_left > 0.5 else 4.0 * delta)
	var duck := (DUCK_DB if _ducked else 0.0) + _sting_dip
	_apply(_theme, _theme_gain, duck)
	for i in _stems.size():
		_apply(_stems[i], _stem_gain[i], duck)
	for i in _calm.size():
		_apply(_calm[i], _calm_gain[i], duck)
		if _calm_gain[i] <= 0.0 and _calm[i].playing:
			_calm[i].stop()
	_apply(_tension, _tension_gain, duck)
	for p in _chase:
		_apply(p, _chase_gain, duck)
	if _chase_gain <= 0.0 and _chase[0].playing:
		for p in _chase:
			p.stop()
	_paths_gain = move_toward(_paths_gain, 1.0 if _want == &"paths" else 0.0, step)
	_apply(_paths, _paths_gain, duck)
	var lg := layer_gains(_want, _path)
	for k: String in _layers:
		_layer_gain[k] = move_toward(float(_layer_gain[k]), float(lg[k]), step)
		_apply(_layers[k], float(_layer_gain[k]), duck)
	if _want != &"paths" and _paths_gain <= 0.0 and _paths.playing:
		for p: AudioStreamPlayer in [_paths] + _layers.values():
			p.stop()  # the layers run with the base all along, to stay in step; they stop with it
	# A track faded right out stops, so nothing plays silently forever -- except a battle stem while the battle
	# is on, which must keep running to stay in step.
	if _theme_gain <= 0.0 and _theme.playing:
		_theme.stop()
	if _want != &"battle" and maxf(_stem_gain.max(), _tension_gain) <= 0.0 and _stems[0].playing:
		for p in _stems:
			p.stop()
		_tension.stop()


## Starts the three battle stems and the tension stem together: identical lengths keep them in step all mission.
func _start_battle() -> void:
	for p in _stems:
		p.play(0.0)
	_tension.play(0.0)


## Starts the paths piece and every school layer together: the layers' 16 beats divide the base's 64, so they stay in step.
func _start_paths() -> void:
	_paths.play(0.0)
	for p: AudioStreamPlayer in _layers.values():
		p.play(0.0)


func _apply(p: AudioStreamPlayer, gain: float, duck: float) -> void:
	p.volume_db = DB + duck + (linear_to_db(gain) if gain > 0.0005 else -80.0)


func _stop_all() -> void:
	_stopped = true
	if _theme != null:
		_theme.stop()
	if _sting != null:
		_sting.stop()
	for p in _stems + _calm + _chase:
		p.stop()
	if _tension != null:
		_tension.stop()
	if _paths != null:
		_paths.stop()
	for p: AudioStreamPlayer in _layers.values():
		p.stop()
