class_name Sfx
extends Node
## Cue catalog + pooled positional playback. Effects call play() with a ground position.

const BUS := &"SFX"
const POOL_SIZE := 32
const MAX_DISTANCE := 900.0
## A cue that varies its pitch per play ("jitter") varies its level too, up to this many dB either way, so a sound
## heard over and over (a collapse, a yelp, a hit) never repeats exactly.
const LEVEL_JITTER_DB := 1.5

## cue -> {path | variants, db, voices, jitter, loop}
## `variants: n` expands path "..._%d.wav" to 1..n, picked at random per play.
const CATALOG := {
	&"nova_alarm": {"path": "res://assets/audio/ability/fire/nova_alarm.wav", "db": -4.0},
	&"nova_lock": {"path": "res://assets/audio/ability/fire/nova_lock.wav", "db": -3.2},
	&"nova_descent": {"path": "res://assets/audio/ability/fire/nova_descent.wav", "db": -2.3},
	&"nova_crack": {"path": "res://assets/audio/ability/fire/nova_crack.wav", "db": 2.9},
	&"nova_boom": {"path": "res://assets/audio/ability/fire/nova_boom.wav", "db": 3.0},
	&"nova_shockwave": {"path": "res://assets/audio/ability/fire/nova_shockwave.wav", "db": 0.1},
	&"nova_rumble": {"path": "res://assets/audio/ability/fire/nova_rumble.wav", "db": -6.4},
	&"nova_swell": {"path": "res://assets/audio/ability/fire/nova_swell.wav", "db": 0.5},
	&"nova_geiger": {"path": "res://assets/audio/ability/fire/nova_geiger.wav", "db": -8.0, "loop": true},
	&"orb_target": {"path": "res://assets/audio/ability/energy/orb_target.wav", "db": -4.3},
	&"orb_charge": {"path": "res://assets/audio/ability/energy/orb_charge.wav", "db": -5.3, "voices": 4, "jitter": 0.06},
	&"orb_hit": {"path": "res://assets/audio/ability/energy/orb_hit_%d.wav", "variants": 4, "db": 1.7, "voices": 4, "jitter": 0.08},
	&"orb_embers": {"path": "res://assets/audio/ability/energy/orb_embers.wav", "db": -9.4, "loop": true},
	&"grav_field": {"path": "res://assets/audio/ability/arcane/grav_field.wav", "db": -3.1},
	&"grav_drone": {"path": "res://assets/audio/ability/arcane/grav_drone.wav", "db": -7.2, "loop": true},
	&"grav_suction": {"path": "res://assets/audio/ability/arcane/grav_suction.wav", "db": -2.0},
	&"grav_compress": {"path": "res://assets/audio/ability/arcane/grav_compress.wav", "db": -5.6},
	&"grav_implode": {"path": "res://assets/audio/ability/arcane/grav_implode.wav", "db": 3.0},
	&"grav_arc": {"path": "res://assets/audio/ability/arcane/grav_arc.wav", "db": -17.4, "voices": 3, "jitter": 0.15},
	&"grav_shimmer": {"path": "res://assets/audio/ability/arcane/grav_shimmer.wav", "db": -5.6},
	&"laser_scan": {"path": "res://assets/audio/ability/energy/laser_scan.wav", "db": -7.4},
	&"laser_thrusters": {"path": "res://assets/audio/ability/energy/laser_thrusters.wav", "db": -6.4},
	&"laser_ignite": {"path": "res://assets/audio/ability/energy/laser_ignite.wav", "db": 2.5},
	&"laser_hum": {"path": "res://assets/audio/ability/energy/laser_hum.wav", "db": -7.5, "loop": true},
	&"laser_fire": {"path": "res://assets/audio/ability/energy/laser_fire.wav", "db": -13.2, "loop": true},
	&"laser_sizzle": {"path": "res://assets/audio/ability/energy/laser_sizzle_%d.wav", "variants": 3, "db": -8.3, "voices": 3, "jitter": 0.1},
	&"laser_powerdown": {"path": "res://assets/audio/ability/energy/laser_powerdown.wav", "db": -3.1},
	&"glac_rune": {"path": "res://assets/audio/ability/ice/glac_rune.wav", "db": 0.8},
	&"glac_erupt": {"path": "res://assets/audio/ability/ice/glac_erupt.wav", "db": 3.0},
	&"glac_freeze": {"path": "res://assets/audio/ability/ice/glac_freeze.wav", "db": -0.0},
	&"glac_peak": {"path": "res://assets/audio/ability/ice/glac_peak.wav", "db": 3.0},
	&"glac_wind": {"path": "res://assets/audio/ability/ice/glac_wind.wav", "db": -13.4, "loop": true},
	&"glac_shatter": {"path": "res://assets/audio/ability/ice/glac_shatter_%d.wav", "variants": 3, "db": -1.3, "voices": 4, "jitter": 0.12},
	&"hs_charge": {"path": "res://assets/audio/ability/holy/hs_charge.wav", "db": -5.3},
	&"hs_strike": {"path": "res://assets/audio/ability/holy/hs_strike.wav", "db": 0.7},
	&"hs_fissure": {"path": "res://assets/audio/ability/holy/hs_fissure.wav", "db": 3.0},
	&"hs_erupt": {"path": "res://assets/audio/ability/holy/hs_erupt.wav", "db": -0.3, "voices": 4, "jitter": 0.1},
	&"hs_static": {"path": "res://assets/audio/ability/holy/hs_static.wav", "db": -12.5, "loop": true},
	&"hs_rumble": {"path": "res://assets/audio/ability/holy/hs_rumble.wav", "db": -3.5},
	&"cf_rumble": {"path": "res://assets/audio/ability/fire/cf_rumble.wav", "db": -3.5},
	&"cf_rise": {"path": "res://assets/audio/ability/fire/cf_rise.wav", "db": 3.0},
	&"cf_erupt": {"path": "res://assets/audio/ability/fire/cf_erupt.wav", "db": 2.4},
	&"cf_lava": {"path": "res://assets/audio/ability/fire/cf_lava.wav", "db": -9.3, "loop": true},
	&"cf_fall": {"path": "res://assets/audio/ability/fire/cf_fall.wav", "db": -9.5, "voices": 3, "jitter": 0.15},
	&"cf_impact": {"path": "res://assets/audio/ability/fire/cf_impact.wav", "db": 3.0, "voices": 4, "jitter": 0.1},
	&"ts_surge": {"path": "res://assets/audio/ability/water/ts_surge.wav", "db": -2.8},
	&"ts_rise": {"path": "res://assets/audio/ability/water/ts_rise.wav", "db": 0.2},
	&"ts_roar": {"path": "res://assets/audio/ability/water/ts_roar.wav", "db": -1.5},
	&"ts_crash": {"path": "res://assets/audio/ability/water/ts_crash.wav", "db": 2.7},
	&"ts_drip": {"path": "res://assets/audio/ability/water/ts_drip.wav", "db": -2.8},
	&"tn_gust": {"path": "res://assets/audio/ability/wind/tn_gust.wav", "db": -6.7, "voices": 3, "jitter": 0.12},
	&"tn_form": {"path": "res://assets/audio/ability/wind/tn_form.wav", "db": -5.0},
	&"tn_wind": {"path": "res://assets/audio/ability/wind/tn_wind.wav", "db": -1.2, "loop": true},
	&"tn_dissipate": {"path": "res://assets/audio/ability/wind/tn_dissipate.wav", "db": -11.0},
	&"jg_rumble": {"path": "res://assets/audio/ability/holy/jg_rumble.wav", "db": -4.8},
	&"jg_hands": {"path": "res://assets/audio/ability/holy/jg_hands.wav", "db": -0.6},
	&"jg_rise": {"path": "res://assets/audio/ability/holy/jg_rise.wav", "db": 1.2},
	&"jg_punch": {"path": "res://assets/audio/ability/holy/jg_punch_%d.wav", "variants": 3, "db": 1.9, "voices": 3, "jitter": 0.08},
	&"jg_windup": {"path": "res://assets/audio/ability/holy/jg_windup.wav", "db": -3.6},
	&"jg_slam": {"path": "res://assets/audio/ability/holy/jg_slam.wav", "db": -0.4},
	&"jg_crumble": {"path": "res://assets/audio/ability/holy/jg_crumble.wav", "db": -5.9},
	&"dr_rumble": {"path": "res://assets/audio/ability/fire/dr_rumble.wav", "db": -5.3},
	&"dr_erupt": {"path": "res://assets/audio/ability/fire/dr_erupt.wav", "db": 3.0},
	&"dr_roar": {"path": "res://assets/audio/ability/fire/dr_roar.wav", "db": 3.0},
	&"dr_inhale": {"path": "res://assets/audio/ability/fire/dr_inhale.wav", "db": -1.0},
	&"dr_ignite": {"path": "res://assets/audio/ability/fire/dr_ignite.wav", "db": 3.0},
	&"dr_breath": {"path": "res://assets/audio/ability/fire/dr_breath.wav", "db": -4.0, "loop": true},
	&"dr_sink": {"path": "res://assets/audio/ability/fire/dr_sink.wav", "db": -5.5},
	&"laser_depart": {"path": "res://assets/audio/ability/energy/laser_depart.wav", "db": -6.5},
	# The quiet powers' own sounds, part I (v0.11.2 Task 13, spec 2.3; tools/audio/foley/ability/quiet/): a cast cue q_<key> each, and a q_<key>_hit
	# where the power has a moment of effect. Levels measured by tools/audio/loudness.py: every cast plays between the quiet floor and the loud median + 2.
	&"q_doom": {"path": "res://assets/audio/ability/quiet/q_doom.wav", "db": 0.6},
	&"q_doom_hit": {"path": "res://assets/audio/ability/quiet/q_doom_hit.wav", "db": 0.2, "voices": 3, "jitter": 0.06},
	&"q_blight": {"path": "res://assets/audio/ability/quiet/q_blight.wav", "db": 0.5},
	&"q_blight_hit": {"path": "res://assets/audio/ability/quiet/q_blight_hit.wav", "db": 1.5, "voices": 3, "jitter": 0.08},
	&"q_deathmark": {"path": "res://assets/audio/ability/quiet/q_deathmark.wav", "db": -0.2},
	&"q_deathmark_hit": {"path": "res://assets/audio/ability/quiet/q_deathmark_hit.wav", "db": -0.7},
	&"q_pestilence": {"path": "res://assets/audio/ability/quiet/q_pestilence.wav", "db": 1.2},
	&"q_ember": {"path": "res://assets/audio/ability/quiet/q_ember.wav", "db": -0.8},
	&"q_ember_hit": {"path": "res://assets/audio/ability/quiet/q_ember_hit.wav", "db": 2.8},
	&"q_noleave": {"path": "res://assets/audio/ability/quiet/q_noleave.wav", "db": 0.5},
	&"q_belllies": {"path": "res://assets/audio/ability/quiet/q_belllies.wav", "db": 1.2},
	&"q_magnify": {"path": "res://assets/audio/ability/quiet/q_magnify.wav", "db": -1.3},
	&"q_abolition": {"path": "res://assets/audio/ability/quiet/q_abolition.wav", "db": 1.0},
	&"q_thorns": {"path": "res://assets/audio/ability/quiet/q_thorns.wav", "db": -0.2},
	&"q_thorns_hit": {"path": "res://assets/audio/ability/quiet/q_thorns_hit.wav", "db": -1.6, "voices": 3, "jitter": 0.08},
	&"q_mirror": {"path": "res://assets/audio/ability/quiet/q_mirror.wav", "db": -0.7},
	&"q_mirror_hit": {"path": "res://assets/audio/ability/quiet/q_mirror_hit.wav", "db": -3.1, "voices": 3, "jitter": 0.08},
	&"q_madness": {"path": "res://assets/audio/ability/quiet/q_madness.wav", "db": -1.2},
	&"q_madness_hit": {"path": "res://assets/audio/ability/quiet/q_madness_hit.wav", "db": -0.8, "voices": 3, "jitter": 0.06},
	# The powers' sounds above are recordings over tools/audio/synth.py's renders (tools/audio/foley/ability/<element>/,
	# built by tools/audio/foley.py). Below, the rest, sorted by kind into assets/audio/<category>/:
	# Interface: made with GodotSfxr (tools/audio/sfxr/ui/, baked by tools/audio/sfxr_bake.gd).
	&"ui_hover": {"path": "res://assets/audio/ui/ui_hover.wav", "db": -20.0},
	&"ui_click": {"path": "res://assets/audio/ui/ui_click.wav", "db": -12.0},
	&"ui_focus": {"path": "res://assets/audio/ui/ui_focus.wav", "db": -14.5},
	&"ui_back": {"path": "res://assets/audio/ui/ui_back.wav", "db": -14.0},
	&"ui_buzz": {"path": "res://assets/audio/ui/ui_buzz.wav", "db": -10.0},
	&"ui_pause": {"path": "res://assets/audio/ui/ui_pause.wav", "db": -13.0},
	&"ui_resume": {"path": "res://assets/audio/ui/ui_resume.wav", "db": -13.0},
	&"ui_mode": {"path": "res://assets/audio/ui/ui_mode.wav", "db": -11.0},
	&"ui_ready": {"path": "res://assets/audio/ui/ui_ready.wav", "db": -16.0},
	&"ui_notice": {"path": "res://assets/audio/ui/ui_notice.wav", "db": -14.0},
	&"ui_surge": {"path": "res://assets/audio/ui/ui_surge.wav", "db": -6.0},
	&"ui_manifest": {"path": "res://assets/audio/ui/ui_manifest.wav", "db": 0.0},
	&"ui_win": {"path": "res://assets/audio/ui/ui_win.wav", "db": -5.0},
	&"ui_lose": {"path": "res://assets/audio/ui/ui_lose.wav", "db": -7.0},
	# Citizens and soldiers: recordings (tools/audio/foley/citizen/, built by tools/audio/foley.py).
	&"cit_yelp": {"path": "res://assets/audio/citizen/cit_yelp_%d.wav", "variants": 4, "db": -9.5, "voices": 4, "jitter": 0.12},
	&"cit_shout": {"path": "res://assets/audio/citizen/cit_shout_%d.wav", "variants": 3, "db": -10.0, "voices": 3, "jitter": 0.1},
	&"crowd_panic": {"path": "res://assets/audio/citizen/crowd_panic.wav", "db": -7.0, "loop": true},
	&"sol_rally": {"path": "res://assets/audio/citizen/sol_rally.wav", "db": -3.5},
	# A death on every kill (v0.11.2, DeathVoices): a citizen's cry and fall, a soldier's grunt and mail, a quiet body's slump,
	# and the roar of a crowd falling at once. Levels measured by tools/audio/loudness.py (spec 6.3 row 4): cit_death and sol_death at the loud median - 4, cit_fall at - 9, the wave under the median.
	&"cit_death": {"path": "res://assets/audio/citizen/cit_death_%d.wav", "variants": 5, "db": -4.4, "voices": 4, "jitter": 0.1},
	&"cit_fall": {"path": "res://assets/audio/citizen/cit_fall_%d.wav", "variants": 4, "db": 1.8, "voices": 3, "jitter": 0.1},
	&"sol_death": {"path": "res://assets/audio/citizen/sol_death_%d.wav", "variants": 3, "db": -4.2, "voices": 4, "jitter": 0.1},
	&"crowd_death_wave": {"path": "res://assets/audio/citizen/crowd_death_wave_%d.wav", "variants": 2, "db": -2.0, "voices": 2, "jitter": 0.08},
	# Buildings and the town: recordings (tools/audio/foley/building/). A building or tree coming down (Town plays them) is capped at four voices each, so a
	# stone rain felling a dozen things at once is a roar, not a pile-up.
	&"collapse_stone": {"path": "res://assets/audio/building/collapse_stone_%d.wav", "variants": 3, "db": -1.2, "voices": 4, "jitter": 0.08},
	&"collapse_timber": {"path": "res://assets/audio/building/collapse_timber_%d.wav", "variants": 3, "db": -0.3, "voices": 4, "jitter": 0.08},
	&"collapse_tree": {"path": "res://assets/audio/building/collapse_tree_%d.wav", "variants": 3, "db": -0.3, "voices": 4, "jitter": 0.1},
	&"town_bell": {"path": "res://assets/audio/building/town_bell.wav", "db": -1.5},
	# The Lantern (v0.11.2, LanternWatch plays them at the Temple): the toll's flare, the burn, and the Bearer's fall.
	&"lantern_flare": {"path": "res://assets/audio/building/lantern_flare.wav", "db": 0.6},
	&"lantern_burn": {"path": "res://assets/audio/building/lantern_burn.wav", "db": 1.3},
	&"lantern_blind": {"path": "res://assets/audio/building/lantern_blind.wav", "db": 0.5},
	# Music: real instrument samples (tools/audio/music/, rendered by tools/audio/music_render.py). Music plays these at its own level (Music.DB), so their db is not used.
	&"music_theme": {"path": "res://assets/audio/music/music_theme.wav", "db": 0.0, "loop": true},
	&"music_battle_base": {"path": "res://assets/audio/music/music_battle_base.wav", "db": 0.0, "loop": true},
	&"music_battle_drums": {"path": "res://assets/audio/music/music_battle_drums.wav", "db": 0.0, "loop": true},
	&"music_battle_lead": {"path": "res://assets/audio/music/music_battle_lead.wav", "db": 0.0, "loop": true},
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
	var jitter: float = entry.get("jitter", 0.0)
	var level_jitter := _rng.randf_range(-LEVEL_JITTER_DB, LEVEL_JITTER_DB) if jitter > 0.0 else 0.0
	p.volume_db = float(entry.get("db", 0.0)) + db_offset + level_jitter
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
