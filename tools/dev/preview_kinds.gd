extends SceneTree
## Dev preview: the Aldermere building kinds standing, then destroyed (fields burn flat, trees are felled).
## Usage (writes captures/kinds_standing.png and captures/kinds_destroyed.png):
##   godot --path . --audio-driver Dummy -s tools/dev/preview_kinds.gd


func _init() -> void:
	RenderingServer.set_default_clear_color(Color("5d7a3a"))
	var root2 := Node2D.new()
	get_root().add_child(root2)
	var cam := Camera2D.new()
	cam.position = Vector2(30, 0)
	cam.zoom = Vector2(0.9, 0.9)
	root2.add_child(cam)
	cam.make_current()
	var world := Node2D.new()
	world.y_sort_enabled = true
	root2.add_child(world)
	var fx := Node2D.new()
	fx.z_index = 10
	root2.add_child(fx)
	var env := EnvironmentField.new()
	env.world_parent = world
	env.fx_parent = fx
	env.fx_back = fx
	root2.add_child(env)
	var items := [
		[Rect2(-4.0, -4.0, 2.7, 3.1), 56.0, Structure.Kind.TEMPLE],
		[Rect2(-0.5, -4.0, 4.2, 1.9), 36.0, Structure.Kind.BARRACKS],
		[Rect2(-4.0, 0.2, 2.8, 1.0), 40.0, Structure.Kind.GATE],
		[Rect2(4.6, -4.0, 1.0, 2.6), 40.0, Structure.Kind.GATE],
		[Rect2(0.0, 0.0, 0.9, 0.7), 10.0, Structure.Kind.MARKET_STALL],
		[Rect2(1.2, 0.0, 0.9, 0.7), 10.0, Structure.Kind.MARKET_STALL],
		[Rect2(2.4, 0.0, 0.9, 0.7), 10.0, Structure.Kind.MARKET_STALL],
		[Rect2(4.2, 0.0, 2.0, 2.4), 6.0, Structure.Kind.BRIDGE],
		[Rect2(-4.0, 2.4, 2.6, 1.8), 3.0, Structure.Kind.FARM_FIELD],
		[Rect2(-0.8, 2.4, 0.7, 0.7), 26.0, Structure.Kind.TREE],
		[Rect2(0.4, 2.9, 0.7, 0.7), 29.0, Structure.Kind.TREE],
		[Rect2(1.6, 2.4, 1.3, 0.95), 22.0, Structure.Kind.HOUSE],
		[Rect2(3.3, 2.6, 1.3, 1.3), 84.0, Structure.Kind.KEEP],
	]
	var built: Array[Structure] = []
	for item in items:
		built.append(env.add_structure(item[0], item[1], item[2]))
	for f in 30:
		await process_frame
	_save("kinds_standing.png")
	for s in built:
		s.destroy(s.center() + Vector2(0.6, 0.6), &"cinder")
	for f in 150:
		await process_frame
	_save("kinds_destroyed.png")
	quit()


func _save(file_name: String) -> void:
	var dir := ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(dir)
	get_root().get_texture().get_image().save_png(dir.path_join(file_name))
	print("captured ", file_name)
