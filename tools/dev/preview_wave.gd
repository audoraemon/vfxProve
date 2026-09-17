extends SceneTree
## Dev preview: renders TsunamiWave in isolation for several directions. Usage (writes captures/wave_preview.png):
## godot --path . -s tools/dev/preview_wave.gd -- [curl] [height]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var root2 := Node2D.new()
	get_root().add_child(root2)
	var bg := ColorRect.new()
	bg.color = Color("8a8274")
	bg.size = Vector2(2000, 2000)
	bg.position = Vector2(-1000, -1000)
	root2.add_child(bg)
	var cam := Camera2D.new()
	root2.add_child(cam)
	cam.make_current()
	var dirs := [Vector2(1, 0), Vector2(1, 1), Vector2(0, -1)]
	var xs := [-200.0, 20.0, 230.0]
	for i in dirs.size():
		var w := TsunamiWave.new()
		w.dir = dirs[i]
		w.width = 5.4 if i == 0 else 3.5
		w.height = float(args[1]) if args.size() > 1 else 1.0
		w.curl = float(args[0]) if args.size() > 0 else 1.0
		w.position = Vector2(xs[i], 90)
		root2.add_child(w)
	for f in 20:
		await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png("res://captures/wave_preview.png")
	quit()
