extends SceneTree
## Dev capture (PixelLab people): every people design in a row of panels at zoom 1 in the town's evening light --
## procedural, then sprite: idle, walk, run, stumble, frozen, and the deaths (blast thrown mid-air, fire, gravity, laser,
## ice, a body down) -- saved to captures/people_states.png at 3x, nearest. Rows follow PeopleArt's designs.
## Usage: godot --path . --audio-driver Dummy -s tools/dev/people_states.gd

const BG := Color("6f6a58")
const CELL := Vector2i(40, 40)
const SCALE := 3
## [label, sprites on, pose, death kind, seconds after death].
const PANELS := [
	["procedural", false, &"walk", &"", 0.0],
	["idle", true, &"idle", &"", 0.0],
	["walk", true, &"walk", &"", 0.0],
	["run", true, &"run", &"", 0.0],
	["stumble", true, &"stumble", &"", 0.0],
	["frozen", true, &"frozen", &"", 0.0],
	["blast", true, &"dead", &"nova", 0.06],
	["fire", true, &"dead", &"fire", 0.6],
	["gravity", true, &"dead", &"gravity", 0.12],
	["laser", true, &"dead", &"laser", 0.3],
	["ice", true, &"dead", &"ice", 0.2],
	["down", true, &"dead", &"doom", 1.0],
]

var _cam: Camera2D
var _world: Node2D
var _grid: WalkGrid


func _init() -> void:
	RenderingServer.set_default_clear_color(BG)
	var root2 := Node2D.new()
	get_root().add_child(root2)
	_cam = Camera2D.new()
	root2.add_child(_cam)
	_world = Node2D.new()
	root2.add_child(_world)
	var lights := LightField.new()
	lights.tint = Town.EVENING
	root2.add_child(lights)
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	_grid = WalkGrid.new().setup(env, town)
	var rows: Array = []
	for d: String in PeopleArt.manifest().get("designs", {}):
		rows.append(d)
	rows.sort()
	var sheet := Image.create(PANELS.size() * CELL.x, rows.size() * CELL.y, false, Image.FORMAT_RGBA8)
	sheet.fill(BG)
	for r in rows.size():
		for c in PANELS.size():
			var p: Array = PANELS[c]
			SpriteArt.set_enabled(p[1])
			var who := _person(rows[r])
			who.lights = lights
			_world.add_child(who)
			_pose(who, p[2], p[3], p[4], c)
			who.set_process(false)
			who.queue_redraw()
			_cam.position = who.position + Vector2(0, -10)
			for f in 3:
				await process_frame
			var shot := get_root().get_texture().get_image()
			var at := Vector2i(320, 180) - CELL / 2
			sheet.blit_rect(shot, Rect2i(at, CELL), Vector2i(c * CELL.x, r * CELL.y))
			who.free()
		print("captured ", rows[r])
	SpriteArt.set_enabled(true)
	sheet.resize(sheet.get_width() * SCALE, sheet.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	var out := ProjectSettings.globalize_path("res://captures/people_states.png")
	sheet.save_png(out)
	print("saved ", out)
	root2.queue_free()
	await process_frame
	quit()


## A person dressed as `design`: the role or corps that wears it, and the look that picks it.
func _person(design: String) -> Person:
	var p := Person.new()
	p.rng.seed = 5
	p.bounds = TownLayout.MAP
	var soldier: bool = design in PeopleArt.SOLDIER
	p.setup_person(soldier, Vector2(2.7, 2.0), _grid)
	if soldier:
		p.corps = PeopleArt.SOLDIER.find(design)
	else:
		for role in PeopleArt.CITIZEN.size():
			var looks: Array = PeopleArt.CITIZEN[role]
			if design in looks:
				var prof := CitizenProfile.new()
				prof.role = role
				p.profile = prof
				p._look = (looks.find(design) + 0.5) / looks.size()
	return p


func _pose(p: Person, pose: StringName, kind: StringName, after: float, column: int) -> void:
	# Facing turns round the panels so every diagonal shows up.
	p._facing = 1 if column % 2 == 0 else -1
	p._back = column % 4 >= 2
	match pose:
		&"walk":
			p._stride = true
			p._anim = 0.15
		&"run":
			p._stride = true
			p.mind = Person.Mind.PANIC
			p._anim = 0.1
		&"stumble":
			p._stumble = 0.15
		&"frozen":
			p.freeze(1.0)
		&"dead":
			p.die(kind, p.ground_pos + Vector2(0.6, 0.3))
			var t := 0.0
			while t < after:
				p.tick(1.0 / 60.0)
				t += 1.0 / 60.0
