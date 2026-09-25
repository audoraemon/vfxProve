class_name Music
extends Node
## Background music, synthesized like every other sound: a brooding theme on the title and the draft, and in the
## mission a battle loop in three stems -- base, drums, lead -- layered in as the city falls. Not positional, not
## tied to a battlefield, and alive across every screen change so one track can fade into the next. Built the way
## UiSound is: one node under the scene tree's root, made the first time music is asked for, silent headless.

const THEME := &"music_theme"
const BATTLE := [&"music_battle_base", &"music_battle_drums", &"music_battle_lead"]
## The music's level under everything else.
const DB := -10.0
## Seconds for a track or a layer to fade fully in or out.
const FADE := 1.2
## How far the music drops while the pause menu is up.
const DUCK_DB := -12.0

static var _node: Music

var _theme: AudioStreamPlayer
var _stems: Array[AudioStreamPlayer] = []
## Current gain (0..1) of the theme and of each stem, eased toward their targets.
var _theme_gain := 0.0
var _stem_gain: Array[float] = [0.0, 0.0, 0.0]
var _want := &""
var _intensity := 0.0
var _ducked := false
## Latched by stop_all(): once true, _process() neither fades nor restarts a player -- without this a stem
## stopped for the quit path's audio-thread wait would just be started right back up next frame.
var _stopped := false


## What should be playing: &"theme", &"battle", or &"" for silence. Fades from whatever is playing now.
static func play(track: StringName) -> void:
	var m := _instance()
	if m != null:
		m._switch(track)


## How far the city has fallen, 0 (standing) to 1 (falling): how many battle layers are in.
static func set_intensity(x: float) -> void:
	var m := _instance()
	if m != null:
		m._intensity = clampf(x, 0.0, 1.0)


static func set_ducked(on: bool) -> void:
	var m := _instance()
	if m != null:
		m._ducked = on


static func current() -> StringName:
	return _node._want if is_instance_valid(_node) else &""


## Each battle stem's volume at an intensity: the base always; the drums from a third of the way, the lead from
## two thirds, each fading in over a sixth so the music thickens rather than switches.
static func stem_gains(intensity: float) -> Array[float]:
	return [1.0, clampf((intensity - 0.33) / 0.17, 0.0, 1.0), clampf((intensity - 0.66) / 0.17, 0.0, 1.0)]


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
	_theme = _player(THEME)
	for cue: StringName in BATTLE:
		_stems.append(_player(cue))


func _player(cue: StringName) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = Sfx.load_stream(cue)
	p.volume_db = -80.0
	add_child(p)
	return p


func _switch(track: StringName) -> void:
	if track == _want:
		return
	_want = track
	if not is_inside_tree():
		return  # _process picks the wish up once the node is in
	if track == &"battle":
		# Start all three stems together, so identical lengths keep them in step for the whole mission.
		for p in _stems:
			p.play(0.0)
	elif track == &"theme" and not _theme.playing:
		_theme.play(0.0)


func _process(delta: float) -> void:
	if _theme == null or _stopped:
		return
	if _want == &"battle" and not _stems[0].playing:
		for p in _stems:
			p.play(0.0)
	elif _want == &"theme" and not _theme.playing:
		_theme.play(0.0)
	var step := delta / FADE
	_theme_gain = move_toward(_theme_gain, 1.0 if _want == &"theme" else 0.0, step)
	var targets: Array[float] = [0.0, 0.0, 0.0]
	if _want == &"battle":
		targets = stem_gains(_intensity)
	for i in _stems.size():
		_stem_gain[i] = move_toward(_stem_gain[i], float(targets[i]), step)
	var duck := DUCK_DB if _ducked else 0.0
	_apply(_theme, _theme_gain, duck)
	for i in _stems.size():
		_apply(_stems[i], _stem_gain[i], duck)
	# A track faded right out stops, so nothing plays silently forever -- except a battle stem while the battle
	# is on, which must keep running to stay in step.
	if _theme_gain <= 0.0 and _theme.playing:
		_theme.stop()
	if _want != &"battle" and _stem_gain.max() <= 0.0 and _stems[0].playing:
		for p in _stems:
			p.stop()


func _apply(p: AudioStreamPlayer, gain: float, duck: float) -> void:
	p.volume_db = DB + duck + (linear_to_db(gain) if gain > 0.0005 else -80.0)


func _stop_all() -> void:
	_stopped = true
	if _theme != null:
		_theme.stop()
	for p in _stems:
		p.stop()
