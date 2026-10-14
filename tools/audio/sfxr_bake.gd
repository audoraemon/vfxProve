extends SceneTree
## Bakes the sounds made with GodotSfxr (res://addons/godot_sfxr) into the WAVs the game plays.
##
## Sources live in tools/audio/sfxr/<category>/ and bake to assets/audio/<category>/<cue>.wav:
## - <cue>.tres: one SfxrAudioStream, one sfxr sound. Open it in the editor and its settings show in the inspector;
##   change any of them and the plugin rebuilds the sound and plays it. Baked as it was last built (8-bit).
## - <cue>.score.json: a score of sfxr notes mixed into one 16-bit WAV, for what one sfxr sound cannot be on its own:
##   music, chords, a bell's partials, a crowd, a building coming down. Each part plays one voice from
##   tools/audio/sfxr/voices/ (an SfxrAudioStream, auditioned in the inspector like any other) at the notes' pitches.
##
## Score format (every time is in beats when "bpm" is set, else in seconds):
##   {"length": 16.0, "bpm": 120, "loop": true, "peak_db": -1.0,   -- or "rms_db": -13.0 (capped at peak -0.3 dB)
##    "parts": [{"voice": "lead", "gain": 0.5,
##               "echo": {"delay": 0.75, "feedback": 0.35, "count": 2},
##               "notes": [{"t": 0, "p": "D4", "hold": 1.5, "gain": 0.8, "attack": 0.1, "decay": 1.0}, ...]}]}
##   "p" is a note name (C4, F#3, Bb2) or a frequency in Hz, and leaves the voice's own pitch when absent. "hold" is
##   how long the note sounds before its decay (attack plus sustain); "attack" and "decay" replace the voice's own.
##   A looped score wraps what runs past its end back to its start, so the loop has no seam. A part's "echo" plays
##   each of its notes again "count" times, "delay" apart, each "feedback" times as loud: sfxr has no reverb.
##
##   godot --headless --path . -s tools/audio/sfxr_bake.gd                    # every sound
##   godot --headless --path . -s tools/audio/sfxr_bake.gd -- --only ui_back  # one cue
##   godot --headless --path . -s tools/audio/sfxr_bake.gd -- --rebuild       # rebuild each .tres from its settings
##
## Then import (godot --headless --editor --path . --import) so a new WAV gets its .import file.
##
## The game never loads the addon: it plays the baked WAVs like every other cue (src/audio/sfx.gd). --rebuild saves
## the rebuilt sound back into its resource, so the two stay one sound. A noise wave is random, so a rebuild of one,
## or any score with a noise voice, never comes out quite the same twice.

const SRC_DIR := "res://tools/audio/sfxr/"
const VOICES := "voices"
const OUT_DIR := "res://assets/audio/"
const SR := 44100
## GodotSfxr writes signed 8-bit samples, and one at full scale wraps round to -128 (a click). A baked sound
## must stay under it: lower its sample_params/sound_vol until it does.
const CLIP_BYTE := 0x80
const NOISE := 3
const NOTE_NAMES := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}

var _voices := {}
var _cache := {}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var rebuild := args.has("--rebuild")
	var only := ""
	var at := args.find("--only")
	if at >= 0 and at + 1 < args.size():
		only = args[at + 1]
	var baked := 0
	var failed := 0
	for category in DirAccess.get_directories_at(SRC_DIR):
		if category == VOICES:
			continue
		var src_dir := SRC_DIR + category + "/"
		for file in DirAccess.get_files_at(src_dir):
			var score := file.ends_with(".score.json")
			if not score and file.get_extension() != "tres":
				continue
			var cue := file.trim_suffix(".score.json") if score else file.get_basename()
			if only != "" and cue != only:
				continue
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR + category))
			var out := OUT_DIR + category + "/" + cue + ".wav"
			var ok := _bake_score(src_dir + file, out, cue) if score else _bake_one(src_dir + file, out, cue, rebuild)
			if ok:
				baked += 1
			else:
				failed += 1
	if baked == 0 and failed == 0:
		printerr("nothing to bake in %s%s" % [SRC_DIR, (" named " + only) if only != "" else ""])
		failed = 1
	quit(1 if failed > 0 else 0)


## One SfxrAudioStream, baked as it was last built (or rebuilt first).
func _bake_one(src: String, out: String, cue: String, rebuild: bool) -> bool:
	var sound := ResourceLoader.load(src, "", ResourceLoader.CACHE_MODE_IGNORE) as AudioStreamWAV
	if sound == null or not sound.has_method("build_sfx"):
		printerr("%s: not an SfxrAudioStream" % src)
		return false
	if rebuild or sound.data.is_empty():
		sound.build_sfx()
		if ResourceSaver.save(sound, src) != OK:
			printerr("%s: could not save the rebuilt sound" % src)
			return false
	var peak := 0
	var clipped := 0
	for b in sound.data:
		if b == CLIP_BYTE:
			clipped += 1
		peak = maxi(peak, absi(b - 256 if b > 127 else b))
	if clipped > 0:
		printerr("%s: %d samples clip; lower its sound_vol" % [src, clipped])
		return false
	# A RIFF chunk of odd length needs a pad byte that save_to_wav does not write, and Godot's importer then
	# seeks past the end of the file. One silent sample more keeps an 8-bit sound's chunk even.
	if sound.data.size() % 2 == 1:
		var even := sound.data
		even.append(0)
		sound.data = even
	if sound.save_to_wav(ProjectSettings.globalize_path(out)) != OK:
		printerr("%s: could not write %s" % [src, out])
		return false
	print("%-20s %6.3f s  peak %3d%%  -> %s" % [cue, sound.get_length(), roundi(peak / 1.28), out])
	return true


## A score of sfxr notes, mixed, normalized and written as 16-bit.
func _bake_score(src: String, out: String, cue: String) -> bool:
	var spec: Variant = JSON.parse_string(FileAccess.get_file_as_string(src))
	if not (spec is Dictionary) or not spec.has("length") or not spec.has("parts"):
		printerr("%s: not a score (needs length and parts)" % src)
		return false
	var unit := 60.0 / float(spec.bpm) if spec.has("bpm") else 1.0
	var n := roundi(float(spec.length) * SR)
	var loop := bool(spec.get("loop", false))
	var mix := PackedFloat32Array()
	mix.resize(n)
	for part: Dictionary in spec.parts:
		var voice := _voice(String(part.get("voice", "")))
		if voice == null:
			printerr("%s: no voice %s in %s%s/" % [src, part.get("voice", ""), SRC_DIR, VOICES])
			return false
		var part_gain := float(part.get("gain", 1.0))
		var echo: Dictionary = part.get("echo", {})
		var repeats := int(echo.get("count", 0))
		for note: Dictionary in part.get("notes", []):
			var samples := _render(voice, note, unit)
			if samples.is_empty():
				printerr("%s: a note of %s could not be rendered (%s)" % [src, part.voice, note])
				return false
			for k in repeats + 1:
				var gain := part_gain * float(note.get("gain", 1.0)) * pow(float(echo.get("feedback", 0.0)), k)
				var t := float(note.get("t", 0.0)) + k * float(echo.get("delay", 0.0))
				_add(mix, samples, roundi(t * unit * SR), gain, loop)
	if not loop:
		var fade := mini(roundi(0.005 * SR), n)
		for i in fade:
			mix[n - 1 - i] *= float(i) / float(fade)
	var peak := 0.0
	var energy := 0.0
	for x in mix:
		peak = maxf(peak, absf(x))
		energy += x * x
	var rms := sqrt(energy / maxf(n, 1))
	if peak <= 0.0:
		printerr("%s: the score is silent" % src)
		return false
	var scale := db_to_linear(float(spec.get("peak_db", -1.0))) / peak
	if spec.has("rms_db"):
		scale = minf(db_to_linear(float(spec.rms_db)) / rms, db_to_linear(-0.3) / peak)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, clampi(roundi(mix[i] * scale * 32767.0), -32768, 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SR
	wav.data = bytes
	if wav.save_to_wav(ProjectSettings.globalize_path(out)) != OK:
		printerr("%s: could not write %s" % [src, out])
		return false
	print("%-20s %6.3f s  peak %5.1f dB  rms %5.1f dB  -> %s" % [cue, float(n) / SR, linear_to_db(peak * scale),
		linear_to_db(rms * scale), out])
	return true


## Mixes `samples` into `mix` from `start`; a loop wraps what runs past the end back to the start.
static func _add(mix: PackedFloat32Array, samples: PackedFloat32Array, start: int, gain: float, loop: bool) -> void:
	var n := mix.size()
	for i in samples.size():
		var j := start + i
		if j >= n:
			if not loop:
				return
			j %= n
		mix[j] += samples[i] * gain


## A voice from tools/audio/sfxr/voices/, loaded once.
func _voice(name: String) -> AudioStreamWAV:
	if not _voices.has(name):
		var path := SRC_DIR + VOICES + "/" + name + ".tres"
		var v: AudioStreamWAV = null
		if ResourceLoader.exists(path):
			v = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as AudioStreamWAV
			if v != null:
				v.set_meta("voice", name)
		_voices[name] = v if v != null and v.has_method("build_sfx") else null
	return _voices[name]


## One note of a voice as floats. A tonal note is the same every time, so it is built once.
func _render(voice: AudioStreamWAV, note: Dictionary, unit: float) -> PackedFloat32Array:
	var key := "%s|%s|%s|%s|%s" % [voice.get_instance_id(), note.get("p", ""), note.get("hold", ""),
		note.get("attack", ""), note.get("decay", "")]
	if voice.wave_type != NOISE and _cache.has(key):
		return _cache[key]
	var v := voice.duplicate() as AudioStreamWAV
	if note.has("p"):
		var hz := _hz(note.p)
		if hz <= 3.6:
			return PackedFloat32Array()
		v.p_base_freq = sqrt(hz / 3528.0 - 0.001)
	if note.has("attack"):
		v.p_env_attack = _env(float(note.attack) * unit)
	if note.has("hold"):
		var attack_s: float = v.p_env_attack * v.p_env_attack * 100000.0 / SR
		v.p_env_sustain = _env(maxf(float(note.hold) * unit - attack_s, 0.001))
	if note.has("decay"):
		v.p_env_decay = _env(float(note.decay) * unit)
	v.build_sfx()
	var out := PackedFloat32Array()
	out.resize(v.data.size())
	var clipped := 0
	for i in v.data.size():
		out[i] = _sample(v.data[i])
		clipped += 1 if v.data[i] == CLIP_BYTE else 0
	if clipped > 0:
		printerr("voice %s clips %d samples at %s; lower its sound_vol" % [voice.get_meta("voice", "?"), clipped, note])
	_cache[key] = out
	return out


## GodotSfxr's byte back to a sample. It stores a level u (0..255, 128 silent) as u + 128 below the middle and as
## u - 127 from it, so silence comes out as 1; undone here, or every note would add a step of DC to the mix.
static func _sample(b: int) -> float:
	if b == CLIP_BYTE:
		return -1.0
	return float(b - 1) / 128.0 if b < CLIP_BYTE else float(b - 256) / 128.0


## sfxr's envelope setting for a stage this many seconds long (it runs p^2 * 100000 samples, at most 1.0).
static func _env(seconds: float) -> float:
	return clampf(sqrt(maxf(seconds, 0.0) * SR / 100000.0), 0.0, 1.0)


## A note name (C4, F#3, Bb2) or a number, in Hz.
static func _hz(p: Variant) -> float:
	if p is float or p is int:
		return float(p)
	var s := String(p).strip_edges()
	var re := RegEx.create_from_string("^([A-Ga-g])([#b]?)(-?\\d)$")
	var m := re.search(s)
	if m == null:
		return 0.0
	var semis: int = NOTE_NAMES[m.get_string(1).to_upper()]
	semis += 1 if m.get_string(2) == "#" else (-1 if m.get_string(2) == "b" else 0)
	var midi := 12 * (int(m.get_string(3)) + 1) + semis
	return 440.0 * pow(2.0, (midi - 69) / 12.0)
