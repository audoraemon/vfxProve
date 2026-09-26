extends SceneTree
## Dev: the crowd's own cost, without a renderer: the town, its lights and the full crowd built as the tests build
## them, then stepped as its ticker steps them (Crowd.step_people, then Crowd.advance) at 60 fps -- four seconds calm, then a cast in the market and twelve seconds of flight.
## Every person counts as on screen (no camera), so this is the worst case per person. Prints microseconds per
## person per frame for each phase, and a checksum of where everyone ended up, which must not change when the
## crowd's code is restructured without meaning to change what it does.
## Usage: godot --headless --path . -s tools/dev/crowd_bench.gd

const DT := 1.0 / 60.0
const CALM_FRAMES := 240
const FLEE_FRAMES := 720


func _init() -> void:
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
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()
	var calm := _run(crowd, CALM_FRAMES)
	crowd.on_cast(TownLayout.MARKET_SQUARE.get_center())
	var flee := _run(crowd, FLEE_FRAMES)
	print("crowd_bench people=%d calm=%.2fus flee=%.2fus (per person per frame; step %.2fms/%.2fms a frame) crowd=%.3fms" % [
		Crowd.CITIZENS + Crowd.SOLDIERS, calm.x, flee.x, calm.y, flee.y, flee.z])
	print("crowd_bench checksum=%s alive=%d escaped=%d" % [_checksum(crowd), crowd.alive_citizens(), crowd.escaped_count])
	quit()


## Steps everyone `frames` times; returns (us per person per frame, ms of people per frame, ms of crowd per frame).
func _run(crowd: Crowd, frames: int) -> Vector3:
	var people_us := 0
	var crowd_us := 0
	var person_frames := 0
	for f in frames:
		for p in crowd.citizens + crowd.soldiers:
			if is_instance_valid(p):
				person_frames += 1
		var t0 := Time.get_ticks_usec()
		crowd.step_people(DT)
		var t1 := Time.get_ticks_usec()
		crowd.advance(DT)
		var t2 := Time.get_ticks_usec()
		people_us += t1 - t0
		crowd_us += t2 - t1
	return Vector3(float(people_us) / person_frames, people_us / 1000.0 / frames, crowd_us / 1000.0 / frames)


func _checksum(crowd: Crowd) -> String:
	var h := 0
	for p in crowd.citizens + crowd.soldiers:
		if not is_instance_valid(p):
			continue
		h = (h * 31 + roundi(p.ground_pos.x * 1000.0)) % 1000000007
		h = (h * 31 + roundi(p.ground_pos.y * 1000.0)) % 1000000007
		h = (h * 31 + int(p.mind)) % 1000000007
	return str(h)
