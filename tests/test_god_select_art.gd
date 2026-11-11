extends RefCounted
## God's Paths Task 3: the art loader, the lit/dim values, the rays that slide to the pick, and the screen without its art.

const PIECES := ["background", "statue_ruin", "statue_passage", "statue_veil", "statue_decree", "statue_death", "statue_dominion",
	"swirl", "brazier_1", "brazier_2", "brazier_3", "brazier_4", "leaf", "rays"]


static func run(t) -> void:
	_lit(t)
	_rays(t)
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


static func _rays(t) -> void:
	var screen := GodSelectScreen.new().setup()
	var old_x := screen.ray_x
	screen.select(1)
	screen.advance(GodSelectScreen.RAY_TIME * 0.5)
	var to_x := GodSelectScreen.statue_anchor(1).x
	t.check(screen.ray_x > old_x and screen.ray_x < to_x, "half way through, the rays are between the old and new statue (%.1f)" % screen.ray_x)
	screen.advance(GodSelectScreen.RAY_TIME)
	t.check(absf(screen.ray_x - to_x) < 0.5, "after RAY_TIME the rays are on the new statue (%.1f)" % screen.ray_x)
	screen.select(3)
	screen.advance(0.01)
	screen.select(4)
	screen.advance(0.01)
	screen.select(5)
	screen.advance(GodSelectScreen.RAY_TIME)
	t.check(absf(screen.ray_x - GodSelectScreen.statue_anchor(5).x) < 0.5, "quick picks end on the last one (%.1f)" % screen.ray_x)
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
	t.check(GodSelectArt.texture("background") == null, "with art_off every lookup fails")
	var got: Array = []
	screen.action.connect(func(n): got.append(n))
	screen.click(GodSelectScreen.ring_rect(3).get_center())
	screen.click(GodSelectScreen.CHOOSE_RECT.get_center())
	t.check(screen.chosen_type == "decree" and got == ["chosen"], "without art the screen still chooses (%s)" % screen.chosen_type)
	screen.queue_free()
	GodSelectArt.art_off = false
	await host.process_frame


static func _art_present(t) -> void:
	var missing := PackedStringArray()
	for p in PIECES:
		if GodSelectArt.texture(p) == null:
			missing.append(p)
	t.check(missing.is_empty(), "every god select piece loads (%s missing)" % ",".join(missing))
	t.check(GodSelectArt.frames("brazier_").size() == 4, "the brazier frames are probed (%d)" % GodSelectArt.frames("brazier_").size())
