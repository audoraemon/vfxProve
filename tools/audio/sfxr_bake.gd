extends SceneTree
## Bakes the interface sounds made with GodotSfxr (res://addons/godot_sfxr) into the WAVs the game plays.
##
## Each sound's source is an SfxrAudioStream resource in tools/audio/sfxr/. Open one in the editor and its sfxr
## settings show in the inspector; change any of them and the plugin rebuilds the sound and plays it. Save the
## resource, then run this to write assets/audio/ui/<name>.wav from what was heard:
##
##   godot --headless --path . -s tools/audio/sfxr_bake.gd                       # every sound, as last built
##   godot --headless --path . -s tools/audio/sfxr_bake.gd -- --rebuild          # build each from its settings first
##   godot --headless --path . -s tools/audio/sfxr_bake.gd -- --only ui_back
##
## Then import (godot --headless --editor --path . --import) so a new WAV gets its .import file.
##
## The game never loads the addon: it plays the baked WAVs like every other cue (src/audio/sfx.gd), so the addon is
## an editing tool only. --rebuild saves the rebuilt sound back into its resource, so the two stay one sound. A noise
## wave is random, so a rebuild of one never comes out quite the same twice.

const SRC_DIR := "res://tools/audio/sfxr/"
const OUT_DIR := "res://assets/audio/ui/"
## GodotSfxr writes signed 8-bit samples, and one at full scale wraps round to -128 (a click). A baked sound
## must stay under it: lower its sample_params/sound_vol until it does.
const CLIP_BYTE := 0x80


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var rebuild := args.has("--rebuild")
	var only := ""
	var at := args.find("--only")
	if at >= 0 and at + 1 < args.size():
		only = args[at + 1]
	var baked := 0
	var failed := 0
	for file in DirAccess.get_files_at(SRC_DIR):
		if file.get_extension() != "tres":
			continue
		var cue := file.get_basename()
		if only != "" and cue != only:
			continue
		var src := SRC_DIR + file
		var sound := ResourceLoader.load(src, "", ResourceLoader.CACHE_MODE_IGNORE) as AudioStreamWAV
		if sound == null or not sound.has_method("build_sfx"):
			printerr("%s: not an SfxrAudioStream" % src)
			failed += 1
			continue
		if rebuild or sound.data.is_empty():
			sound.build_sfx()
			if ResourceSaver.save(sound, src) != OK:
				printerr("%s: could not save the rebuilt sound" % src)
				failed += 1
				continue
		var peak := 0
		var clipped := 0
		for b in sound.data:
			if b == CLIP_BYTE:
				clipped += 1
			peak = maxi(peak, absi(b - 256 if b > 127 else b))
		if clipped > 0:
			printerr("%s: %d samples clip; lower its sound_vol" % [src, clipped])
			failed += 1
			continue
		# A RIFF chunk of odd length needs a pad byte that save_to_wav does not write, and Godot's importer then
		# seeks past the end of the file. One silent sample more keeps an 8-bit sound's chunk even.
		if sound.data.size() % 2 == 1:
			var even := sound.data
			even.append(0)
			sound.data = even
		var out := OUT_DIR + cue + ".wav"
		if sound.save_to_wav(ProjectSettings.globalize_path(out)) != OK:
			printerr("%s: could not write %s" % [src, out])
			failed += 1
			continue
		baked += 1
		print("%-12s %5.3f s  peak %3d%%  -> %s" % [cue, sound.get_length(), roundi(peak / 1.28), out])
	if baked == 0 and failed == 0:
		printerr("nothing to bake in %s%s" % [SRC_DIR, (" named " + only) if only != "" else ""])
		failed = 1
	quit(1 if failed > 0 else 0)
