extends SceneTree
## Dev: an exact check that the crowd still does what it did. The town and the full crowd are built as the tests
## build them, but in the tree, so the engine steps them frame by frame as the game does (run with --fixed-fps 60:
## every frame is 1/60 s, and nothing here reads the wall clock, unlike the mission's hitstop). Four seconds calm,
## a cast in the market, twelve seconds of flight; then a checksum of where everyone stands. Compare it before and
## after a change that should not change what the crowd does.
## Usage: godot --headless --path . --fixed-fps 60 -s tools/dev/crowd_check.gd

const CAST_AT := 240
const END_AT := 960

var _crowd: Crowd
var _frame := 0


func _initialize() -> void:
	var env := EnvironmentField.new()
	env.lights = LightField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.lights = env.lights
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	root.add_child(world)
	_crowd = Crowd.new().setup(field, env, town, grid, world, 5)
	# After the world, as in the mission: the people are stepped before the crowd's own frame.
	root.add_child(_crowd)
	_crowd.spawn()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == CAST_AT:
		_crowd.on_cast(TownLayout.MARKET_SQUARE.get_center())
	if _frame >= END_AT:
		var h := 0
		for p in _crowd.citizens + _crowd.soldiers:
			if not is_instance_valid(p):
				continue
			h = (h * 31 + roundi(p.ground_pos.x * 1000.0)) % 1000000007
			h = (h * 31 + roundi(p.ground_pos.y * 1000.0)) % 1000000007
			h = (h * 31 + int(p.mind)) % 1000000007
		print("crowd_check checksum=%d alive=%d escaped=%d" % [h, _crowd.alive_citizens(), _crowd.escaped_count])
		return true
	return false
