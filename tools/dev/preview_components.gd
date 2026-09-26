extends SceneTree
## Dev preview: every Aldermere component drawn alone on a flat magenta background at zoom 1 (one world pixel per
## image pixel), in the town's evening light, for measuring against the reference (captures/components/*.png).
## Glows are hidden so they do not bleed into the background.
## Usage: godot --path . --audio-driver Dummy -s tools/dev/preview_components.gd

const BG := Color(1, 0, 1)
const S := Structure.Kind
const D := Decor.Kind

## [name, kind, rect, height, role, tag, seed]; structures.
const STRUCTURES := [
	["cottage_wide", S.HOUSE, Rect2(0, 0, 0.95, 0.75), 17.0, &"house", &"", 11],
	["cottage_deep", S.HOUSE, Rect2(0, 0, 0.75, 0.95), 17.0, &"house", &"", 12],
	["tavern", S.HOUSE, Rect2(0, 0, 2.1, 1.4), 30.0, &"house", &"tavern", 13],
	["blacksmith", S.HOUSE, Rect2(0, 0, 1.5, 1.25), 20.0, &"house", &"smithy", 14],
	["barn", S.HOUSE, Rect2(0, 0, 1.2, 1.4), 20.0, &"farm", &"", 15],
	["temple", S.TEMPLE, Rect2(0, 0, 2.7, 3.1), 56.0, &"temple", &"", 16],
	["barracks", S.BARRACKS, Rect2(0, 0, 4.2, 1.9), 36.0, &"barracks", &"", 17],
	["stall_red", S.MARKET_STALL, Rect2(0, 0, 0.9, 0.7), 10.0, &"market", &"", 0],
	["stall_blue", S.MARKET_STALL, Rect2(0, 0, 0.9, 0.7), 10.0, &"market", &"", 1],
	["stall_cream", S.MARKET_STALL, Rect2(0, 0, 0.9, 0.7), 10.0, &"market", &"", 2],
	["fountain", S.FOUNTAIN, Rect2(0, 0, 0.9, 0.9), 14.0, &"decor", &"", 18],
	["corner_tower", S.KEEP, Rect2(0, 0, 1.5, 1.5), 50.0, &"tower", &"", 19],
	["wall_piece", S.CASTLE_WALL, Rect2(0, 0, 1.2, 0.6), 34.0, &"wall", &"", 20],
	["main_gate", S.GATE, Rect2(0, 0, 2.8, 1.0), 34.0, &"gate", &"", 21],
	["citadel_keep", S.KEEP, Rect2(0, 0, 2.0, 2.0), 118.0, &"citadel", &"keep", 22],
	["citadel_tower", S.KEEP, Rect2(0, 0, 1.3, 1.3), 84.0, &"citadel", &"", 23],
	["bridge", S.BRIDGE, Rect2(0, 0, 2.0, 2.4), 6.0, &"bridge", &"", 24],
	["field_a", S.FARM_FIELD, Rect2(0, 0, 2.6, 1.8), 3.0, &"farm", &"", 25],
	["field_b", S.FARM_FIELD, Rect2(0, 0, 2.6, 1.8), 3.0, &"farm", &"", 26],
	["tree_a", S.TREE, Rect2(0, 0, 0.7, 0.7), 26.0, &"decor", &"", 27],
	["tree_b", S.TREE, Rect2(0, 0, 0.7, 0.7), 26.0, &"decor", &"", 28],
	["torch", S.TORCH, Rect2(0, 0, 0.2, 0.2), 16.0, &"decor", &"", 29],
	["lamp", S.TORCH, Rect2(0, 0, 0.2, 0.2), 18.0, &"decor", &"lamp", 30],
]
## [name, kind, size, seed]; decor.
const DECOR := [
	["barrel", D.BARREL, Vector2.ZERO, 1], ["crates", D.CRATES, Vector2.ZERO, 2],
	["bench", D.BENCH, Vector2(0.5, 0.0), 3], ["fence", D.FENCE, Vector2(1.3, 0.0), 4],
	["garden", D.GARDEN, Vector2(0.7, 0.3), 5], ["bush", D.BUSH, Vector2.ZERO, 6], ["rock", D.ROCK, Vector2.ZERO, 7],
	["oak", D.OAK, Vector2.ZERO, 8], ["pine", D.PINE, Vector2.ZERO, 9], ["scarecrow", D.SCARECROW, Vector2.ZERO, 10],
	["signpost", D.SIGNPOST, Vector2.ZERO, 11], ["reeds", D.REEDS, Vector2.ZERO, 12],
	["flowers", D.FLOWERS, Vector2.ZERO, 13], ["bunting", D.BUNTING, Vector2(2.0, 0.0), 14],
]

var _cam: Camera2D
var _world: Node2D


func _init() -> void:
	RenderingServer.set_default_clear_color(BG)
	var root2 := Node2D.new()
	get_root().add_child(root2)
	_cam = Camera2D.new()
	_cam.zoom = Vector2.ONE
	root2.add_child(_cam)
	_cam.make_current()
	_world = Node2D.new()
	_world.y_sort_enabled = true
	root2.add_child(_world)
	var lights := LightField.new()
	lights.tint = Town.EVENING
	root2.add_child(lights)
	var dir := ProjectSettings.globalize_path("res://captures/components")
	DirAccess.make_dir_recursive_absolute(dir)
	for item in STRUCTURES:
		var sd: int = item[6]
		if item[0] == "field_b":
			# The first seed whose field grows cabbages rather than wheat.
			while Structure.new().setup(item[2], item[3], item[1], sd, item[4]).art.crop != 1:
				sd += 1
		var s := Structure.new().setup(item[2], item[3], item[1], sd, item[4], item[5])
		s.lights = lights
		_world.add_child(s)
		await _shoot(s, Iso.ground_to_screen((item[2] as Rect2).get_center()) + Vector2(0, -float(item[3]) * 0.5),
			dir.path_join(item[0] + ".png"))
		s.free()
	for item in DECOR:
		var d := Decor.new().setup(item[1], Vector2.ZERO, item[2], item[3])
		_world.add_child(d)
		await _shoot(d, Iso.ground_to_screen(item[2] * 0.5) + Vector2(0, -12), dir.path_join(item[0] + ".png"))
		d.free()
	quit()


func _shoot(n: Node, look: Vector2, path: String) -> void:
	_hide_glows(n)
	_cam.position = look.round()
	for f in 6:
		await process_frame
	_hide_glows(n)
	await process_frame
	get_root().get_texture().get_image().save_png(path)
	print("captured ", path.get_file())


func _hide_glows(n: Node) -> void:
	for c in n.get_children():
		if c is QuadFx:
			c.visible = false
		_hide_glows(c)
