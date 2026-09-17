extends SceneTree
## Dev preview: renders TsunamiWave in isolation at rise, curl and full stages.
## Usage (writes captures/wave_preview.png): godot --path . -s tools/dev/preview_wave.gd

func _init() -> void:
	var root2 := Node2D.new()
	get_root().add_child(root2)
	var bg := ColorRect.new()
	bg.color = Color("5a564e")
	bg.size = Vector2(2000, 2000)
	bg.position = Vector2(-1000, -1000)
	root2.add_child(bg)
	var cam := Camera2D.new()
	root2.add_child(cam)
	cam.make_current()
	var stages := [[0.35, 0.0], [0.75, 0.5], [1.0, 1.0]]
	var xs := [-210.0, 0.0, 210.0]
	for i in stages.size():
		var w := TsunamiWave.new()
		w.dir = Vector2(1, 0)
		w.width = 5.4
		w.max_height = 140.0
		w.height = stages[i][0]
		w.curl = stages[i][1]
		w.seed = 0.37
		w.position = Vector2(xs[i], 110)
		w.scale = Vector2(0.95, 0.95)
		root2.add_child(w)
	for f in 30:
		await process_frame
	get_root().get_texture().get_image().save_png("res://captures/wave_preview.png")
	quit()
