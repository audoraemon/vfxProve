class_name UiSound
extends Node
## Interface sounds (spec §8: synthesized like the effect audio). They are not in the world, so they are not
## positional, and they cannot hang off a battlefield -- the title, the draft and the results have none. One
## small pool of players under the scene tree's root, made the first time a sound plays and kept across every
## screen change, so a sting started on one screen finishes on the next.

## Every interface cue, so a test can prove each one exists.
const CUES := [&"ui_hover", &"ui_click", &"ui_focus", &"ui_buzz", &"ui_pause", &"ui_manifest", &"ui_win", &"ui_lose"]
const POOL := 6

static var _node: UiSound

var _players: Array[AudioStreamPlayer] = []
var _next := 0
## Sounds asked for before the pool reached the tree.
var _pending: Array = []


## Play an interface cue. Safe from anywhere, including before the pool exists.
static func play(cue: StringName, db_offset := 0.0) -> void:
	if DisplayServer.get_name() == "headless":
		return  # no audio to play, and a pool made during the headless test suite would outlive it and leak
	if not Sfx.CATALOG.has(cue):
		push_warning("Unknown ui sound: %s" % cue)
		return
	if not is_instance_valid(_node):
		var tree := Engine.get_main_loop() as SceneTree
		if tree == null or tree.root == null:
			return
		_node = UiSound.new()
		_node.name = "UiSound"
		# Deferred: a sound can be asked for while the root is still adding the main scene's children.
		tree.root.add_child.call_deferred(_node)
	if _node.is_inside_tree():
		_node._play(cue, db_offset)
	else:
		_node._pending.append([cue, db_offset])


## Stop whatever is playing, so a sting still ringing (the win/lose stings run past 2 seconds) does not hold
## the audio server's playback open when the process quits. Game calls this before get_tree().quit().
static func stop_all() -> void:
	if is_instance_valid(_node):
		for p in _node._players:
			p.stop()


func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = Sfx.BUS
		add_child(p)
		_players.append(p)
	for s: Array in _pending:
		_play(s[0], s[1])
	_pending.clear()


func _play(cue: StringName, db_offset: float) -> void:
	var entry: Dictionary = Sfx.CATALOG[cue]
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = Sfx.load_stream(cue)
	p.volume_db = float(entry.get("db", 0.0)) + db_offset
	p.play()
