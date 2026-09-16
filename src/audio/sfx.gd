class_name Sfx
extends Node
## Cue catalog + pooled positional playback. Effects call play() with a ground position.

const BUS := &"SFX"
const POOL_SIZE := 32
const MAX_DISTANCE := 900.0

## cue -> {path | variants, db, voices, jitter, loop}
## `variants: n` expands path "..._%d.wav" to 1..n, picked at random per play.
const CATALOG := {
	&"nova_alarm": {"path": "res://assets/audio/nova/nova_alarm.wav", "db": -4.0},
	&"nova_lock": {"path": "res://assets/audio/nova/nova_lock.wav", "db": -6.0},
	&"nova_descent": {"path": "res://assets/audio/nova/nova_descent.wav", "db": -2.0},
	&"nova_crack": {"path": "res://assets/audio/nova/nova_crack.wav", "db": 0.0},
	&"nova_boom": {"path": "res://assets/audio/nova/nova_boom.wav", "db": 0.0},
	&"nova_shockwave": {"path": "res://assets/audio/nova/nova_shockwave.wav", "db": -3.0},
	&"nova_rumble": {"path": "res://assets/audio/nova/nova_rumble.wav", "db": -4.0},
	&"nova_swell": {"path": "res://assets/audio/nova/nova_swell.wav", "db": -2.0},
	&"nova_geiger": {"path": "res://assets/audio/nova/nova_geiger.wav", "db": -8.0, "loop": true},
	&"orb_target": {"path": "res://assets/audio/orbital/orb_target.wav", "db": -6.0},
	&"orb_charge": {"path": "res://assets/audio/orbital/orb_charge.wav", "db": -9.0, "voices": 4, "jitter": 0.06},
	&"orb_hit": {"path": "res://assets/audio/orbital/orb_hit_%d.wav", "variants": 4, "db": -3.0, "voices": 4, "jitter": 0.08},
	&"orb_embers": {"path": "res://assets/audio/orbital/orb_embers.wav", "db": -10.0, "loop": true},
	&"grav_field": {"path": "res://assets/audio/gravity/grav_field.wav", "db": -5.0},
	&"grav_drone": {"path": "res://assets/audio/gravity/grav_drone.wav", "db": -6.0, "loop": true},
	&"grav_suction": {"path": "res://assets/audio/gravity/grav_suction.wav", "db": -3.0},
	&"grav_compress": {"path": "res://assets/audio/gravity/grav_compress.wav", "db": -4.0},
	&"grav_implode": {"path": "res://assets/audio/gravity/grav_implode.wav", "db": 0.0},
	&"grav_arc": {"path": "res://assets/audio/gravity/grav_arc.wav", "db": -12.0, "voices": 3, "jitter": 0.15},
	&"grav_shimmer": {"path": "res://assets/audio/gravity/grav_shimmer.wav", "db": -8.0},
	&"laser_scan": {"path": "res://assets/audio/laser/laser_scan.wav", "db": -8.0},
	&"laser_thrusters": {"path": "res://assets/audio/laser/laser_thrusters.wav", "db": -6.0},
	&"laser_ignite": {"path": "res://assets/audio/laser/laser_ignite.wav", "db": -3.0},
	&"laser_hum": {"path": "res://assets/audio/laser/laser_hum.wav", "db": -9.0, "loop": true},
	&"laser_fire": {"path": "res://assets/audio/laser/laser_fire.wav", "db": -9.0, "loop": true},
	&"laser_sizzle": {"path": "res://assets/audio/laser/laser_sizzle_%d.wav", "variants": 3, "db": -8.0, "voices": 3, "jitter": 0.1},
	&"laser_powerdown": {"path": "res://assets/audio/laser/laser_powerdown.wav", "db": -5.0},
	&"laser_depart": {"path": "res://assets/audio/laser/laser_depart.wav", "db": -7.0},
}

static var _cache := {}
## Playback speed from the user's slow-mo, independent of hit-stop dips in Engine.time_scale.
static var speed := 1.0

var _pool: Array[AudioStreamPlayer2D] = []
var _rng := RandomNumberGenerator.new()


static func paths_for(cue: StringName) -> PackedStringArray:
	var entry: Dictionary = CATALOG[cue]
	var out := PackedStringArray()
	if entry.has("variants"):
		for i in range(1, int(entry.variants) + 1):
			out.append(entry.path % i)
	else:
		out.append(entry.path)
	return out


## Loads (cached) one stream for the cue; random variant when the cue has several.
static func load_stream(cue: StringName, rng: RandomNumberGenerator = null) -> AudioStream:
	var paths := paths_for(cue)
	var path := paths[rng.randi() % paths.size()] if rng != null else paths[0]
	if _cache.has(path):
		return _cache[path]
	var stream: AudioStreamWAV = load(path)
	if stream != null and CATALOG[cue].get("loop", false):
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	_cache[path] = stream
	return stream


static func clear_cache() -> void:
	_cache.clear()


func _ready() -> void:
	_rng.randomize()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer2D.new()
		p.bus = BUS
		p.max_distance = MAX_DISTANCE
		p.attenuation = 1.0
		add_child(p)
		_pool.append(p)


func play(cue: StringName, ground_pos: Vector2, db_offset := 0.0) -> AudioStreamPlayer2D:
	if not CATALOG.has(cue):
		push_warning("Unknown sfx cue: %s" % cue)
		return null
	var entry: Dictionary = CATALOG[cue]
	var p := _acquire(cue, int(entry.get("voices", 2)))
	if p.has_meta(&"fade"):
		var tween: Tween = p.get_meta(&"fade")
		if tween != null and tween.is_valid():
			tween.kill()
		p.remove_meta(&"fade")
	p.stop()
	p.stream = load_stream(cue, _rng)
	p.position = Iso.ground_to_screen(ground_pos)
	p.volume_db = float(entry.get("db", 0.0)) + db_offset
	var jitter: float = entry.get("jitter", 0.0)
	p.set_meta(&"cue", cue)
	p.set_meta(&"base_pitch", 1.0 + _rng.randf_range(-jitter, jitter))
	p.set_meta(&"pitch_mul", 1.0)
	p.set_meta(&"started", Time.get_ticks_msec())
	p.pitch_scale = _pitch_for(p)
	p.play()
	return p


func fade_out(p: AudioStreamPlayer2D, seconds: float) -> void:
	if p == null or not is_instance_valid(p) or not p.playing:
		return
	var tween := create_tween()
	tween.tween_property(p, "volume_db", -60.0, seconds)
	tween.tween_callback(p.stop)
	p.set_meta(&"fade", tween)


## Multiplies the voice's pitch (on top of jitter and slow-mo).
func set_voice_pitch(p: AudioStreamPlayer2D, mul: float) -> void:
	if p != null and is_instance_valid(p):
		p.set_meta(&"pitch_mul", mul)


func stop_all(prefix: String) -> void:
	for p in _pool:
		if p.playing and String(p.get_meta(&"cue", &"")).begins_with(prefix):
			p.stop()


func _process(_delta: float) -> void:
	for p in _pool:
		if p.playing:
			p.pitch_scale = _pitch_for(p)


func _pitch_for(p: AudioStreamPlayer2D) -> float:
	var mul := float(p.get_meta(&"base_pitch", 1.0)) * float(p.get_meta(&"pitch_mul", 1.0))
	return maxf(mul * speed, 0.05)


## Free voice, or steal the oldest voice of this cue once its voice limit is reached,
## or steal the oldest voice overall.
func _acquire(cue: StringName, voices: int) -> AudioStreamPlayer2D:
	var same: Array[AudioStreamPlayer2D] = []
	var free_voice: AudioStreamPlayer2D = null
	var oldest: AudioStreamPlayer2D = null
	for p in _pool:
		if not p.playing:
			if free_voice == null:
				free_voice = p
			continue
		if p.get_meta(&"cue", &"") == cue:
			same.append(p)
		if oldest == null or int(p.get_meta(&"started", 0)) < int(oldest.get_meta(&"started", 0)):
			oldest = p
	if same.size() >= voices:
		same.sort_custom(func(a, b): return int(a.get_meta(&"started", 0)) < int(b.get_meta(&"started", 0)))
		return same[0]
	return free_voice if free_voice != null else oldest
