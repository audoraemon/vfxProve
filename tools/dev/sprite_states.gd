extends SceneTree
## Dev capture (PixelLab structures proof): each sprite building in a row of panels at zoom 1 in the town's evening
## light -- procedural, then sprite: intact, damaged, a blast's fall at 40%, ruins, a laser's cut mid-slide, gravity's
## fall at 50% -- saved to captures/sprite_states/<name>.png at 2x, nearest.
## Usage: godot --path . --audio-driver Dummy -s tools/dev/sprite_states.gd

const BG := Color("3b3a34")
const SCREEN_AT := Vector2(320, 340)
const END := Vector2(3, 3)
const PAD := 8
## [label, sprites on, damage kind ("" = none), seconds after the hit, crack first].
const PANELS := [
	["procedural", false, &"", 0.0, false],
	["intact", true, &"", 0.0, false],
	["damaged", true, &"", 0.0, true],
	# COLLAPSE_TIME is 0.8 s: 40% of the fall is 0.32 s.
	["blast_40", true, &"blast", 0.32, true],
	["ruins", true, &"stone", 1.5, true],
	["laser", true, &"laser", 0.45, true],
	["gravity_50", true, &"gravity", 0.4, true],
]

var _cam: Camera2D
var _world: Node2D
var _lights: LightField


func _init() -> void:
	RenderingServer.set_default_clear_color(BG)
	Structure.wind = 0.0
	var root2 := Node2D.new()
	get_root().add_child(root2)
	_cam = Camera2D.new()
	root2.add_child(_cam)
	_world = Node2D.new()
	root2.add_child(_world)
	_lights = LightField.new()
	_lights.tint = Town.EVENING
	root2.add_child(_lights)
	var out := ProjectSettings.globalize_path("res://captures/sprite_states")
	DirAccess.make_dir_recursive_absolute(out)
	var m := SpriteArt.manifest()
	for n: String in m:
		var e: Dictionary = m[n]
		var size := Vector2i(int(e.size[0]), int(e.size[1]))
		var fp := Vector2(e.footprint[0], e.footprint[1])
		var anchor := SpriteArt.default_anchor(Vector2(size), fp)
		var row := Image.create(PANELS.size() * (size.x + PAD) + PAD, size.y + PAD * 2, false, Image.FORMAT_RGBA8)
		row.fill(BG)
		for i in PANELS.size():
			var p: Array = PANELS[i]
			SpriteArt.set_enabled(p[1])
			var s := Structure.new().setup(Rect2(END - fp, fp), float(e.height), Structure.Kind[e.kind], int(e.seed),
				StringName(e.role), StringName(e.get("tag", "")))
			s.lights = _lights
			if p[1]:
				# The row's own sprite: a cottage's seed would pick either roof.
				s.sprite = SpriteArt.sprite(n).duplicate()
			_world.add_child(s)
			if p[4]:
				s.crack()
				s.scorch = 0.2
			if p[2] != &"":
				s.destroy(s.center() + Vector2(-2, -2), p[2])
				for f in int(float(p[3]) * 60.0):
					s._process(1.0 / 60.0)
			s.set_process(false)
			s.position = s.base_position()
			s.queue_redraw()
			_cam.position = s.position - (SCREEN_AT - Vector2(320, 180))
			for f in 4:
				await process_frame
			var shot := get_root().get_texture().get_image()
			row.blit_rect(shot, Rect2i(Vector2i(SCREEN_AT - anchor), size), Vector2i(PAD + i * (size.x + PAD), PAD))
			s.free()
		row.resize(row.get_width() * 2, row.get_height() * 2, Image.INTERPOLATE_NEAREST)
		row.save_png(out.path_join(n + ".png"))
		print("captured ", n)
	SpriteArt.set_enabled(true)
	root2.queue_free()
	await process_frame
	quit()
