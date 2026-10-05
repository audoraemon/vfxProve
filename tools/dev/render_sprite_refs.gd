extends SceneTree
## Dev tool (PixelLab structures proof): for every sprite in assets/pixellab/buildings/manifest.json, render today's
## procedural building on that sprite's canvas, anchored where SpriteArt anchors the sprite, in neutral light, without
## its ground shadow (the Structure draws that):
##   reference.png -- intact; the composition reference handed to PixelLab;
##   with --placeholders also intact.png, damaged.png (cracked, scorched) and ruins.png (collapsed), the stand-ins until
##   PixelLab's sprites replace them.
## Exits 1 if a render touches its canvas edge: grow that sprite's "size" in the manifest and run it again.
## Usage: godot --path . --audio-driver Dummy -s tools/dev/render_sprite_refs.gd -- [--placeholders]

## Each building is shot on both, to tell its pixels from the background (see _shoot).
const BG := Color(1, 0, 1)
const BG2 := Color(0, 1, 0)
## Where the front corner lands on the 640x360 screen: low and centred, so the tallest canvas fits above it.
const SCREEN_AT := Vector2(320, 340)
## The footprint's far end: a whole number on both axes puts the front corner on a whole pixel.
const END := Vector2(3, 3)

var _cam: Camera2D
var _world: Node2D
var _lights: LightField
var _bad := 0


func _init() -> void:
	RenderingServer.set_default_clear_color(BG)
	SpriteArt.set_enabled(false)
	Structure.wind = 0.0
	var root2 := Node2D.new()
	get_root().add_child(root2)
	# The only camera, so it is current once the tree runs.
	_cam = Camera2D.new()
	root2.add_child(_cam)
	_world = Node2D.new()
	root2.add_child(_world)
	_lights = LightField.new()
	root2.add_child(_lights)
	var shots := {"reference": &"intact"}
	if "--placeholders" in OS.get_cmdline_user_args():
		shots = {"reference": &"intact", "intact": &"intact", "damaged": &"damaged", "ruins": &"ruins"}
	var m := SpriteArt.manifest()
	for n: String in m:
		var e: Dictionary = m[n]
		var dir := ProjectSettings.globalize_path(SpriteArt.DIR + n)
		DirAccess.make_dir_recursive_absolute(dir)
		var size := Vector2i(int(e.size[0]), int(e.size[1]))
		var fp := Vector2(e.footprint[0], e.footprint[1])
		var anchor := SpriteArt.default_anchor(Vector2(size), fp)
		for file: String in shots:
			var s := Structure.new().setup(Rect2(END - fp, fp), float(e.height), Structure.Kind[e.kind], int(e.seed),
				StringName(e.role), StringName(e.get("tag", "")))
			s.lights = _lights
			_world.add_child(s)
			_pose(s, shots[file])
			var img: Image = await _shoot(s, anchor, size)
			s.free()
			if _touches_edge(img):
				printerr("CLIPPED: %s/%s touches its %dx%d canvas; grow its size" % [n, file, size.x, size.y])
				_bad += 1
			img.save_png(dir.path_join(file + ".png"))
			print("rendered ", n, "/", file)
	root2.queue_free()
	await process_frame
	quit(1 if _bad > 0 else 0)


## A fresh building put into the state a still shows.
func _pose(s: Structure, state: StringName) -> void:
	match state:
		&"damaged":
			s.crack()
			s.scorch = 0.35
		&"ruins":
			s.destroy(s.center() + Vector2(3, 3), &"stone")
			for i in 90:
				s._process(1.0 / 60.0)


## The building cut out of two shots, one on magenta and one on green: where they differ the art let the background
## through, which gives each pixel's coverage. Pixel art keeps no half-covered pixels: under half is dropped (the ground
## shadow, the faint edge of an outline), the rest is opaque in its own colour.
func _shoot(s: Structure, anchor: Vector2, size: Vector2i) -> Image:
	# The camera's centre is the screen's (320, 180): put the front corner (the node's position) at SCREEN_AT.
	_cam.position = s.position - (SCREEN_AT - Vector2(320, 180))
	var rect := Rect2i(Vector2i(SCREEN_AT - anchor), size)
	RenderingServer.set_default_clear_color(BG)
	for f in 6:
		await process_frame
	_hide_glows(s)
	await process_frame
	var on_bg := get_root().get_texture().get_image().get_region(rect)
	RenderingServer.set_default_clear_color(BG2)
	for f in 2:
		await process_frame
	var on_bg2 := get_root().get_texture().get_image().get_region(rect)
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in size.y:
		for x in size.x:
			var c1 := on_bg.get_pixel(x, y)
			var c2 := on_bg2.get_pixel(x, y)
			# BG - BG2 is (1, -1, 1): each channel's difference is the background's share.
			var through := clampf(((c1.r - c2.r) + (c2.g - c1.g) + (c1.b - c2.b)) / 3.0, 0.0, 1.0)
			var a := 1.0 - through
			if a < 0.5:
				continue
			img.set_pixel(x, y, Color(clampf((c1.r - BG.r * through) / a, 0.0, 1.0),
				clampf((c1.g - BG.g * through) / a, 0.0, 1.0), clampf((c1.b - BG.b * through) / a, 0.0, 1.0), 1.0))
	return img


func _touches_edge(img: Image) -> bool:
	var w := img.get_width()
	var h := img.get_height()
	for x in w:
		if img.get_pixel(x, 0).a > 0.0 or img.get_pixel(x, h - 1).a > 0.0:
			return true
	for y in h:
		if img.get_pixel(0, y).a > 0.0 or img.get_pixel(w - 1, y).a > 0.0:
			return true
	return false


func _hide_glows(n: Node) -> void:
	for c in n.get_children():
		if c is QuadFx:
			c.visible = false
		_hide_glows(c)
