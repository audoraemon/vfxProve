extends SceneTree
## Dev preview: citizens and soldiers, walking and standing, at 1x and 4x.
## Usage (writes captures/people_preview.png): godot --path . --audio-driver Dummy -s tools/dev/preview_people.gd


func _init() -> void:
	RenderingServer.set_default_clear_color(Color("6a8e3a"))
	var root2 := Node2D.new()
	get_root().add_child(root2)
	var cam := Camera2D.new()
	cam.position = Vector2(0, -10)
	root2.add_child(cam)
	# No make_current() call: a SceneTree script's add_child() during _init() defers node entry past this
	# function, so the camera is not "inside_tree" yet and the call would only fail. Camera2D.enabled defaults
	# true, so it becomes current on its own once it actually enters the tree during the settle wait below.
	# Row Y is a holder origin in root2 space, not scaled by the holder's own 4x -- so the two 4x rows need a
	# wider gap than the two 1x rows or their taller sprites overlap; column spacing is likewise divided by the
	# row's scale so every row keeps the same 48px on-screen stride instead of the 4x rows spilling past the
	# 640px viewport at a raw 48-unit stride.
	var rows := [[false, 1.0, -70.0], [true, 1.0, -30.0], [false, 4.0, 30.0], [true, 4.0, 130.0]]
	# Posed mannequins, not a live simulation: a CALM citizen's own drift (1.4 ground units) would carry it
	# well outside its 48px column before the capture, and a SceneTree script's add_child() during _init()
	# defers _ready()/_process() past this function, so at least one tick lands no matter how early processing
	# is disabled here. Let it settle, then pin every slot back and freeze it for the shot.
	var people: Array[Person] = []
	var slots: Array[Vector2] = []
	var anims: Array[float] = []
	var facings: Array[int] = []
	for row in rows:
		var holder := Node2D.new()
		holder.scale = Vector2.ONE * float(row[1])
		holder.position = Vector2(0, float(row[2]))
		root2.add_child(holder)
		for i in 6:
			var p := Person.new()
			p.rng.seed = 40 + i
			p.bounds = Rect2(-50, -50, 100, 100)
			var sx := (-120.0 + i * 48.0) / float(row[1])
			var gpos := Iso.screen_to_ground(Vector2(sx, 0.0))
			p.setup_person(row[0], gpos, null)
			p._facing = 1 if i % 2 == 0 else -1
			# 0.25 clears both body types' leg-step boundary (1/6 for the citizen's 6-frame cycle, 1/5 for
			# the soldier's 5-frame one), so this group's pose reliably differs from the i<3 standing group.
			p._anim = 0.0 if i < 3 else 0.25
			holder.add_child(p)
			people.append(p)
			slots.append(gpos)
			anims.append(p._anim)
			facings.append(p._facing)
	for f in 20:
		await process_frame
	for i in people.size():
		var p := people[i]
		p.ground_pos = slots[i]
		p.position = Iso.ground_to_screen(slots[i]).round()
		p._anim = anims[i]
		p._facing = facings[i]
		p.set_process(false)
		p.queue_redraw()
	for f in 3:
		await process_frame
	var dir := ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(dir)
	get_root().get_texture().get_image().save_png(dir.path_join("people_preview.png"))
	print("captured people_preview.png")
	quit()
