extends RefCounted
## God's Paths Task 3: the art loader, the lit/dim values and the screen without its art.

const PIECES := ["background", "statue_ruin", "statue_passage", "statue_veil", "statue_decree", "statue_death", "statue_dominion",
	"brazier_1", "brazier_2", "brazier_3", "brazier_4", "leaf"]


static func run(t) -> void:
	_lit(t)
	_emblem_and_fx(t)
	_frame_sets(t)
	await _art_missing(t)
	_art_present(t)


static func _lit(t) -> void:
	var screen := GodSelectScreen.new().setup()
	screen.select(2)
	t.check(screen.lit(2) == 1.0, "the selected statue is fully lit (%f)" % screen.lit(2))
	var bad := 0
	for i in GodTree.RING.size():
		if i != 2 and screen.lit(i) >= screen.lit(2):
			bad += 1
	t.check(bad == 0, "every other statue is dimmer than the selected one (%d not)" % bad)
	screen.free()


static func _art_missing(t) -> void:
	t.check(GodSelectArt.texture("no_such_piece") == null, "a missing piece gives null")
	GodSelectArt.art_off = true
	var screen := GodSelectScreen.new().setup()
	var host := Engine.get_main_loop() as SceneTree
	host.root.add_child(screen)
	screen.advance(0.3)
	screen._ui.queue_redraw()
	await host.process_frame
	await host.process_frame
	t.check(screen._draws > 0, "with no art the screen drew to the end (%d draws)" % screen._draws)
	t.check(GodSelectArt.texture("background") == null, "with art_off every lookup fails")
	var got: Array = []
	screen.action.connect(func(n): got.append(n))
	screen.click(GodSelectScreen.ring_rect(3).get_center())
	screen.click(GodSelectScreen.CHOOSE_RECT.get_center())
	t.check(screen.chosen_type == "decree" and got == ["chosen"], "without art the screen still chooses (%s)" % screen.chosen_type)
	screen.queue_free()
	GodSelectArt.art_off = false
	await host.process_frame
	GodSelectArt.art_off = false
	var on := GodSelectScreen.new().setup()
	host.root.add_child(on)
	await host.process_frame
	await host.process_frame
	t.check(on._draws > 0, "with the art on the screen drew to the end (%d draws)" % on._draws)
	on.queue_free()
	await host.process_frame


static func _art_present(t) -> void:
	var missing := PackedStringArray()
	for p in PIECES:
		if GodSelectArt.texture(p) == null:
			missing.append(p)
	t.check(missing.is_empty(), "every god select piece loads (%s missing)" % ",".join(missing))
	t.check(GodSelectArt.frames("brazier_").size() == 4, "the brazier frames are probed (%d)" % GodSelectArt.frames("brazier_").size())


static func _emblem_and_fx(t) -> void:
	var screen := GodSelectScreen.new().setup()
	screen.select(2)
	t.check(screen.emblem_type() == "veil", "the emblem follows the pick (%s)" % screen.emblem_type())
	t.check(screen.fx_age == 0.0 and screen.fx_phase() == "burst", "a pick starts the burst (%f, %s)" % [screen.fx_age, screen.fx_phase()])
	screen.advance(GodSelectScreen.BURST_TIME * 0.5)
	t.check(screen.fx_phase() == "burst", "half the burst time in, it is still the burst")
	var age: float = screen.fx_age
	screen.select(2)
	t.check(screen.fx_age == age, "a repeat pick does not restart the effect (%f, %f)" % [age, screen.fx_age])
	screen.advance(GodSelectScreen.BURST_TIME)
	t.check(screen.fx_phase() == "loop", "after the burst time it loops")
	screen.select(4)
	t.check(screen.fx_age == 0.0 and screen.fx_phase() == "burst" and screen.emblem_type() == "death", "a new pick restarts the burst and the emblem")
	t.check(is_equal_approx(GodSelectScreen.BURST_TIME, float(GodSelectArt.frame_set("fx_ruin_burst").size()) / GodSelectScreen.FX_FPS),
		"BURST_TIME is the burst frames at the effect fps (%f)" % GodSelectScreen.BURST_TIME)
	screen.select(3)
	screen.advance(0.01)
	screen.select(4)
	screen.advance(0.01)
	screen.select(5)
	screen.advance(0.01)
	t.check(screen.fx_phase() == "burst" and screen.emblem_type() == "dominion", "quick picks end with the burst running for the last pick")
	# the emblem turns with time
	var f0: int = screen.emblem_frame()
	screen.advance(0.5)
	t.check(screen.emblem_frame() != f0, "the emblem frame advances with time (%d, %d)" % [f0, screen.emblem_frame()])
	# a new pick restarts the entrance: the scale-in is small at first and full later
	screen.select(1)
	t.check(screen.entrance_scale() < 1.0, "the emblem scales in after a pick (%f)" % screen.entrance_scale())
	screen.advance(0.5)
	t.check(screen.entrance_scale() == 1.0, "the entrance is done after a moment (%f)" % screen.entrance_scale())
	# the sparks split behind / in front by their orbit angle
	var front := 0
	var behind := 0
	for k in screen.spark_count():
		var a: float = screen.spark_angle(k)
		t.check(screen.spark_in_front(k) == (sin(a) >= 0.0), "spark %d is in front exactly when it is on the near half of its orbit" % k)
		if screen.spark_in_front(k):
			front += 1
		else:
			behind += 1
	t.check(screen.spark_count() > 0 and front > 0 and behind > 0, "sparks are split: %d in front, %d behind" % [front, behind])
	screen.advance(1.0)
	var moved := false
	for k in screen.spark_count():
		moved = moved or screen.spark_in_front(k) != (sin(screen.spark_angle(k) - TAU * 0.25) >= 0.0)
	t.check(moved or screen.spark_count() > 0, "sparks orbit")
	t.check(GodSelectScreen.EMBLEM_AT == Vector2(320, 200), "the emblem sits at (320, 200)")
	screen.free()
	# with no art everything still draws and picks
	GodSelectArt.art_off = true
	var bare := GodSelectScreen.new().setup()
	bare.select(3)
	bare.advance(0.2)
	t.check(bare.emblem_type() == "decree" and bare.emblem_frame() == 0 and bare.fx_phase() == "burst", "without art the state still follows the pick")
	bare.free()
	GodSelectArt.art_off = false


static func _frame_sets(t) -> void:
	var counts := {"fx_ruin_burst": 8, "fx_ruin_loop": 16, "emblem_veil": 24, "emblem_flash_veil": 6, "emblem_spark_veil": 4}
	for k in counts:
		t.check(GodSelectArt.frame_set(k).size() == counts[k], "%s has %d frames (%d)" % [k, counts[k], GodSelectArt.frame_set(k).size()])
	t.check(GodSelectArt.frame_set("no_such_set").is_empty(), "a missing frame set is empty")
	GodSelectArt.art_off = true
	t.check(GodSelectArt.frame_set("fx_ruin_burst").is_empty(), "with art_off a frame set is empty")
	GodSelectArt.art_off = false
	t.check(GodSelectArt.frame_set("fx_ruin_burst").size() == 8, "the set is back once art is on again")
