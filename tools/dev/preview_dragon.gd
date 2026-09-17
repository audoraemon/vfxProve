extends SceneTree
## Dev preview: renders FireDragon in isolation facing both ways.
## Usage (writes captures/dragon_preview.png): godot --path . -s tools/dev/preview_dragon.gd -- [jaw] [wings]

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
	for i in 2:
		var d := FireDragon.new()
		d.rise = 1.0
		d.jaw = float(args[0]) if args.size() > 0 else 1.0
		d.wings = float(args[1]) if args.size() > 1 else 1.0
		d.aim = Vector2(160, -110) if i == 0 else Vector2(-150, -60)
		d.position = Vector2(-150 + i * 300, 170)
		root2.add_child(d)
	for f in 20:
		await process_frame
	get_root().get_texture().get_image().save_png("res://captures/dragon_preview.png")
	quit()
