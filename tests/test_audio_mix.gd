extends RefCounted
## v0.11.2 Task 3: the buses (Music and UI beside Master and SFX), the music's new level, and the cues' buses.


static func run(t) -> void:
	_buses(t)


static func _buses(t) -> void:
	var missing := false
	for b in ["Master", "SFX", "Music", "UI"]:
		var found := AudioServer.get_bus_index(b) >= 0
		missing = missing or not found
		t.check(found, "bus %s exists (the layout default_bus_layout.tres did not load if all are missing)" % b)
	if missing:
		return
	t.check(AudioServer.get_bus_send(AudioServer.get_bus_index("Music")) == &"Master", "Music sends to Master")
	t.check(AudioServer.get_bus_send(AudioServer.get_bus_index("UI")) == &"Master", "UI sends to Master")
	t.check(AudioServer.get_bus_send(AudioServer.get_bus_index("SFX")) == &"Master", "SFX still sends to Master")
	t.check(AudioServer.get_bus_effect_count(0) >= 2, "Master keeps its compressor and limiter")
	t.check(Music.DB == -16.0 and Music.BUS == &"Music" and UiSound.BUS == &"UI" and Sfx.BUS == &"SFX",
		"levels and buses (Music %f, %s, %s, %s)" % [Music.DB, Music.BUS, UiSound.BUS, Sfx.BUS])
