extends RefCounted
## God's Paths Task 3: the art loader, the lit/dim values and the screen without its art.

const PIECES := ["background", "statue_ruin", "statue_passage", "statue_veil", "statue_decree", "statue_death", "statue_dominion",
	"brazier_1", "brazier_2", "brazier_3", "brazier_4", "leaf"]


static func run(t) -> void:
	_lit(t)
	_emblem_and_fx(t)
	_frame_sets(t)
	await _partial_art(t)
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
	for g in GodTree.RING:
		t.check(GodSelectArt.frame_set("fx_%s_burst" % g).size() == GodSelectScreen.BURST_FRAMES, "%s's burst set has BURST_FRAMES frames" % g)
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
	# a new pick restarts the entrance: nothing at first, the first scale-in step soon after, full later
	screen.select(1)
	t.check(screen.entrance_scale() == 0.0, "the emblem is hidden right after a pick (%f)" % screen.entrance_scale())
	screen.advance(0.1)
	t.check(is_equal_approx(screen.entrance_scale(), 0.35), "0.1 s in, the scale-in is at its first step (%f)" % screen.entrance_scale())
	screen.advance(0.5)
	t.check(screen.entrance_scale() == 1.0, "the entrance is done after a moment (%f)" % screen.entrance_scale())
	# sparks: split in front / behind, at known angles, and they orbit
	var front := 0
	for k in screen.spark_count():
		front += 1 if screen.spark_in_front(k) else 0
	t.check(front > 0 and front < screen.spark_count(), "sparks are split: %d in front of %d" % [front, screen.spark_count()])
	var fresh := GodSelectScreen.new().setup()
	fresh._sparks[0][0] = 0.25
	fresh._sparks[1][0] = 0.75
	t.check(fresh.spark_in_front(0) and not fresh.spark_in_front(1), "a spark at the front of its orbit is in front, one at the back is behind")
	var before: Array = []
	for k in fresh.spark_count():
		before.append(fresh.spark_angle(k))
	fresh.advance(1.0)
	var moved := 0
	for k in fresh.spark_count():
		moved += 1 if not is_equal_approx(fresh.spark_angle(k), before[k]) else 0
	t.check(moved == fresh.spark_count(), "every spark orbits as time passes (%d moved)" % moved)
	fresh.free()
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


## Partial art: with the Decree loop and flash missing, the screen still draws, still picks, and the pieces that exist still show.
static func _partial_art(t) -> void:
	GodSelectArt.blocked = ["fx_decree_loop", "emblem_flash_decree"]
	var host := Engine.get_main_loop() as SceneTree
	var screen := GodSelectScreen.new().setup()
	host.root.add_child(screen)
	screen.select(3)
	t.check(GodSelectArt.frame_set("fx_decree_loop").is_empty() and GodSelectArt.frame_set("emblem_flash_decree").is_empty(),
		"the blocked sets read as missing")
	t.check(not GodSelectArt.frame_set("emblem_decree").is_empty() and not GodSelectArt.frame_set("fx_decree_burst").is_empty(),
		"the unblocked emblem and burst still load")
	await host.process_frame
	await host.process_frame
	var d0: int = screen._draws
	screen.advance(GodSelectScreen.BURST_TIME + 0.5)
	screen._ui.queue_redraw()
	await host.process_frame
	await host.process_frame
	t.check(screen._draws > d0 and screen.fx_phase() == "loop", "with the loop and flash missing the screen still draws (%d -> %d)" % [d0, screen._draws])
	var got: Array = []
	screen.action.connect(func(n): got.append(n))
	screen.click(GodSelectScreen.ring_rect(4).get_center())
	screen.click(GodSelectScreen.CHOOSE_RECT.get_center())
	t.check(screen.chosen_type == "death" and got == ["chosen"], "a pick still chooses with partial art (%s)" % screen.chosen_type)
	screen.queue_free()
	GodSelectArt.blocked = []
	await host.process_frame


static func _frame_sets(t) -> void:
	var counts := {"fx_ruin_burst": 8, "fx_ruin_loop": 16, "emblem_veil": 24, "emblem_flash_veil": 6, "emblem_spark_veil": 4}
	for k in counts:
		t.check(GodSelectArt.frame_set(k).size() == counts[k], "%s has %d frames (%d)" % [k, counts[k], GodSelectArt.frame_set(k).size()])
	t.check(GodSelectArt.frame_set("no_such_set").is_empty(), "a missing frame set is empty")
	GodSelectArt.art_off = true
	t.check(GodSelectArt.frame_set("fx_ruin_burst").is_empty(), "with art_off a frame set is empty")
	GodSelectArt.art_off = false
	t.check(GodSelectArt.frame_set("fx_ruin_burst").size() == 8, "the set is back once art is on again")
