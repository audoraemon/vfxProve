class_name Ambience
extends Node
## The town's own sound between the events (natural sound pass 2): a looped bed for the time of day -- by day the town at
## a distance, birds and a breeze; by night crickets, wind and the town far off -- a fire bed that swells with how much
## of the town is burning, and now and then a call somewhere near the camera, a bird by day, by night a call or a
## creaking tree. Without it every sound starts from silence and sounds pasted on.
##
## It only listens: it reads the town's look (TownLook.active), the fires (Crowd.fires) and the panic the crowd's own bed
## follows (Crowd.panic_level()), and never touches the world. Crowd makes it beside the panic bed, and pauses and stops
## it with that bed. The beds play on the Ambience bus, which feeds SFX, so the Sounds slider rules them too.

const BUS := &"Ambience"
## Gain a second the beds ease by, so a change of look or a fire dying swells or fades instead of jumping.
const EASE := 0.35
## How far the time-of-day bed dips while the town panics: the panic bed takes over.
const PANIC_DIP := 0.6
## Summed fire intensity at which the fire bed is full (Crowd.fires: 1 is one building fully ablaze).
const FIRE_FULL := 3.0
## Seconds between calls, by day and by night; none while the town panics past CALL_QUIET.
const DAY_CALLS := Vector2(5.0, 14.0)
const NIGHT_CALLS := Vector2(8.0, 20.0)
const CALL_QUIET := 0.35
## How far from the screen's centre a call can be, in screen pixels at zoom 1.
const CALL_SPREAD := Vector2(300.0, 170.0)

var _crowd: Crowd
var _players := {}
var _gain := {"amb_day": 0.0, "amb_night": 0.0, "amb_fire": 0.0}
var _rng := RandomNumberGenerator.new()
var _next_call := 3.0
var _stopped := false


func setup(crowd: Crowd) -> Ambience:
	_crowd = crowd
	_rng.randomize()
	for cue: StringName in _gain:
		var p := AudioStreamPlayer.new()
		p.bus = BUS
		p.stream = Sfx.load_stream(cue)
		p.volume_db = -80.0
		add_child(p)
		_players[cue] = p
	return self


## What each bed is heading for: the time of day's bed (dipped under panic) and the fire bed.
static func targets(night: bool, panic: float, fire: float) -> Dictionary:
	var calm := 1.0 - PANIC_DIP * clampf(panic, 0.0, 1.0)
	return {"amb_day": 0.0 if night else calm, "amb_night": calm if night else 0.0,
		"amb_fire": clampf(fire / FIRE_FULL, 0.0, 1.0)}


func pause(paused: bool) -> void:
	for p: AudioStreamPlayer in _players.values():
		p.stream_paused = paused


## Silence for good (the mission is quitting): nothing restarts it.
func stop() -> void:
	_stopped = true
	for p: AudioStreamPlayer in _players.values():
		p.stop()


func _process(delta: float) -> void:
	if _stopped or _crowd == null:
		return
	var night: bool = TownLook.active == Town.Look.NIGHT
	var fire := 0.0
	if _crowd.fires != null:
		for f: Dictionary in _crowd.fires.fires.values():
			fire += float(f.get("intensity", 0.0))
	var want := targets(night, _crowd.panic_level(), fire)
	for cue: StringName in _gain:
		_gain[cue] = move_toward(_gain[cue], want[cue], EASE * delta)
		var p: AudioStreamPlayer = _players[cue]
		if _gain[cue] <= 0.001:
			if p.playing:
				p.stop()
			continue
		if not p.playing and not p.stream_paused:
			# Start somewhere in the loop, so a fresh mission does not always open on the same second of it.
			p.play(_rng.randf() * p.stream.get_length())
		p.volume_db = float(Sfx.CATALOG[cue].get("db", 0.0)) + linear_to_db(_gain[cue])
	_next_call -= delta
	if _next_call <= 0.0:
		var span := NIGHT_CALLS if night else DAY_CALLS
		_next_call = _rng.randf_range(span.x, span.y)
		if _crowd.panic_level() < CALL_QUIET and _crowd.sfx != null:
			_call(&"amb_night_call" if night else &"amb_bird")


## A call somewhere near the camera, so it is heard at its distance and side.
func _call(cue: StringName) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var off := Vector2(_rng.randf_range(-1.0, 1.0) * CALL_SPREAD.x, _rng.randf_range(-1.0, 1.0) * CALL_SPREAD.y) / cam.zoom
	_crowd.sfx.play(cue, Iso.screen_to_ground(cam.get_screen_center_position() + off))
