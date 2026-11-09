extends SceneTree
## Dev: measures where walkers get stuck, so a fix to the walk grid or the step rules can be proven before and after.
## Nothing in the game is changed; every line it prints starts `STALL ` (grep it), and each part ends with a
## `STALL total ...` line; the run ends with one `STALL summary ...` line per part. Three parts:
##   cells  -- the walk grid against the bodies' margin: open cells whose centre a body may not stand on
##             (EnvironmentField.blocked at 0.15), pairs of open 4-neighbour cells the grid joins but a body cannot
##             walk straight between (sampled every 0.05), and pinch cells (a one-cell-wide alley).
##   hounds -- twelve Visitors (Hound Gate's hellhound, at Hound Gate's speed, never biting) each chase one citizen
##             parked 8-15 units away, behind buildings where possible: reached or not, give-ups (Animal.blocked),
##             seconds without progress (< 0.02 over a 0.5 s window), and where it stalled longest.
##   people -- the mission crowd as crowd_check builds it, run frame by frame: `plain` (no casts) and `far` (every
##             10 s ten calm citizens are sent across town). Every 0.5 s a person out in the open, not queued, with a
##             goal beyond GOAL_REACH and free to walk, who has moved < 0.05 for 2 s, is stalled; each episode is
##             kept and the 40 longest printed, with what the person's plan looked like while it stood; the summary
##             counts the stuck watchdog's unsticks in the run (Person.unsticks).
## Usage: godot --headless --path . --fixed-fps 60 -s tools/dev/stall_probe.gd -- [--city=aldermere|capital]
##        [--part=cells|hounds|people|people_plain|people_far|all] [--seconds=N]
## A fourth part, --part=spot --at=x,y [--to=x,y], prints the grid around one point (to look at a spot a part found):
## the 7x7 cells about it (# solid, . open, m open but its centre inside a margin, @ the point's cell), what blocks
## there, nearest_walkable(), and the head of the path to --to with whether a straight step to its first waypoint
## crosses a margin.
## --seconds sets both the hounds' chase (default 20 per hound) and the people's run (default 120 per variant).
## Run with --fixed-fps 60: the people part counts frames, never the wall clock.

const MARGIN := 0.15
const SAMPLE := 0.05
const LIST := 40
const HOUNDS := 12
const HOUND_DT := 1.0 / 60.0
const HOUND_REACH := 0.6
const HOUND_WINDOW := 0.5
const HOUND_STILL := 0.02
const PEOPLE_SAMPLE := 30  # frames: 0.5 s
const PEOPLE_STILL := 0.05
const PEOPLE_STALL := 2.0
const FAR_EVERY := 600  # frames: 10 s
const FAR_FIRST := 300
const FAR_COUNT := 10
const FAR_MIN := 12.0
const FAR_MAX := 30.0

var _city := &"aldermere"
var _parts: Array[String] = []
var _hound_s := 20.0
var _people_s := 120.0
var _summaries: Array[String] = []

# People phase state.
var _phases: Array[String] = []
var _phase := ""
var _frame := 0
var _end_frame := 0
var _wait_frames := 0
var _w := {}  # the built world: env, town, grid, field, world, crowd
var _track := {}  # Person -> {anchor, since, ep}
var _episodes: Array[Dictionary] = []
var _far_goal := {}  # Person -> the far goal it was sent to
var _spots: Array[Vector2] = []
var _far_round := 0
var _far_sent := 0
## Person-samples free to walk with a far goal, and how many of those had moved since the last sample.
var _walking := 0
var _moved := 0
## Person.unsticks when the run began: the stuck watchdog's unsticks in it are the difference.
var _unsticks0 := 0
var _finished := false
## Nodes outside the tree freed once the crowd in the tree is gone.
var _later: Array[Node] = []
var _spot_at := Vector2.INF
var _spot_to := Vector2.INF


func _initialize() -> void:
	AnimalPack.enabled = false
	var part := "all"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--city="):
			_city = StringName(a.get_slice("=", 1))
		elif a.begins_with("--part="):
			part = a.get_slice("=", 1)
		elif a.begins_with("--at="):
			_spot_at = _vec(a.get_slice("=", 1))
		elif a.begins_with("--to="):
			_spot_to = _vec(a.get_slice("=", 1))
		elif a.begins_with("--seconds="):
			_hound_s = float(a.get_slice("=", 1))
			_people_s = _hound_s
	match part:
		"all":
			_parts = ["cells", "hounds", "people_plain", "people_far"]
		"people":
			_parts = ["people_plain", "people_far"]
		_:
			_parts = [part]
	print("STALL probe city=%s parts=%s hound_seconds=%.0f people_seconds=%.0f" % [_city, ",".join(_parts), _hound_s, _people_s])
	if "cells" in _parts:
		_run_cells()
	if "hounds" in _parts:
		_run_hounds()
	if "spot" in _parts:
		_run_spot()
	for p in _parts:
		if p.begins_with("people_"):
			_phases.append(p.trim_prefix("people_"))


func _process(_delta: float) -> bool:
	if _finished:
		return true
	if _phase == "":
		if _wait_frames > 0:
			_wait_frames -= 1
			return false
		for n in _later:
			if is_instance_valid(n):
				n.free()
		_later.clear()
		if _phases.is_empty():
			_finish()
			return true
		_phase = _phases.pop_front()
		_start_people(_phase)
		return false
	_frame += 1
	if _phase == "far" and _frame >= FAR_FIRST and (_frame - FAR_FIRST) % FAR_EVERY == 0:
		_send_far()
	if _frame % PEOPLE_SAMPLE == 0:
		_sample(float(_frame) / 60.0)
	if _frame >= _end_frame:
		_end_people()
		_phase = ""
		_wait_frames = 2
	return false


func _finish() -> void:
	for s in _summaries:
		print("STALL summary " + s)
	City.use(&"aldermere")
	_finished = true


# --- World --------------------------------------------------------------------

func _build(in_tree: bool) -> Dictionary:
	City.use(_city)
	var env := EnvironmentField.new()
	env.lights = LightField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.lights = env.lights
	field.bounds = City.current().map()
	var world := Node2D.new()
	if in_tree:
		root.add_child(world)
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	if in_tree:
		# After the world, as in the mission: the people are stepped before the crowd's own frame.
		root.add_child(crowd)
	crowd.spawn()
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd}


func _tear_down(b: Dictionary) -> void:
	(b.town as Town).teardown()
	(b.crowd as Crowd).clear()
	for k in ["world", "crowd", "town", "field", "env"]:
		var n: Node = b[k]
		if not is_instance_valid(n):
			continue
		if n.is_inside_tree():
			n.queue_free()
		elif _phase != "":
			_later.append(n)  # the crowd still in the tree steps once more this frame and reads the town
		else:
			n.free()


## The structure nearest `g` (by footprint), as "role/kind/art_tag @d".
static func _near_desc(env: EnvironmentField, g: Vector2) -> String:
	var best: Structure = null
	var best_d := INF
	for s: Structure in env.structures():
		if not is_instance_valid(s) or s.destroyed:
			continue
		var d := s.distance_to(g)
		if d < best_d:
			best_d = d
			best = s
	if best == null:
		return "none"
	return "%s/%s/%s@%.2f" % [best.role, Structure.Kind.keys()[best.kind], best.art_tag, best_d]


## Trap cells: solid on the grid, next to open ground (within two cells), holding a point (5x5 samples 0.1 apart) a
## body may stand on, from which the straight walk to nearest_walkable() enters a margin. [cell, point, nearest].
static func _traps(env: EnvironmentField, grid: WalkGrid) -> Array:
	var out: Array = []
	var reg := grid.grid.region
	for y in range(reg.position.y, reg.end.y):
		for x in range(reg.position.x, reg.end.x):
			var id := Vector2i(x, y)
			if _open(grid, id):
				continue
			var by_open := false
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					by_open = by_open or _open(grid, id + Vector2i(dx, dy))
			if not by_open:
				continue
			var c := grid.id_to_world(id)
			var tried := 0
			for k in 25:
				if tried >= 3:
					break
				var pt := c + Vector2(float(k % 5 - 2), float(k / 5 - 2)) * 0.1
				if env.blocked(pt, MARGIN):
					continue
				tried += 1
				var nw := grid.nearest_walkable(pt)
				if nw != Vector2.INF and _crosses(env, pt, nw):
					out.append([id, pt, nw])
					break
	return out


## The standing, unwalkable structures whose margin covers `g` (what env.blocked() hit), as "role/kind/tag footprint".
static func _blocker_desc(env: EnvironmentField, g: Vector2) -> String:
	var out: PackedStringArray = []
	for s: Structure in env.structures():
		if is_instance_valid(s) and not s.destroyed and not s.walkable and s.contains(g, MARGIN):
			out.append("%s/%s/%s %s" % [s.role, Structure.Kind.keys()[s.kind], s.art_tag, s.footprint])
	return "; ".join(out) if not out.is_empty() else "-"


## How many open cells run through `id` along x and along y (the alley's width there, in cells).
static func _widths(grid: WalkGrid, id: Vector2i) -> Vector2i:
	var out := Vector2i.ZERO
	for axis in 2:
		var step := Vector2i(1, 0) if axis == 0 else Vector2i(0, 1)
		var n := 1
		for sgn in [-1, 1]:
			var c: Vector2i = id + step * sgn
			while n < 40 and grid.grid.is_in_boundsv(c) and not grid.grid.is_point_solid(c):
				n += 1
				c += step * sgn
		out[axis] = n
	return out


static func _open(grid: WalkGrid, id: Vector2i) -> bool:
	return grid.grid.is_in_boundsv(id) and not grid.grid.is_point_solid(id)


## The open cells of the largest 4-connected region (the town people can walk), as a set.
static func _main_region(grid: WalkGrid) -> Dictionary:
	var seen := {}
	var best := {}
	var reg := grid.grid.region
	for y in range(reg.position.y, reg.end.y):
		for x in range(reg.position.x, reg.end.x):
			var id := Vector2i(x, y)
			if seen.has(id) or not _open(grid, id):
				continue
			var comp := {}
			var q: Array[Vector2i] = [id]
			seen[id] = true
			while not q.is_empty():
				var c: Vector2i = q.pop_back()
				comp[c] = true
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n: Vector2i = c + d
					if not seen.has(n) and _open(grid, n):
						seen[n] = true
						q.append(n)
			if comp.size() > best.size():
				best = comp
	return best


## Town spots: cell centres on a 2-unit lattice, in the main region, clear for a body, within 3 of a structure.
static func _town_spots(env: EnvironmentField, grid: WalkGrid, region: Dictionary) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var m := City.current().map()
	var y := m.position.y + 1.0
	while y < m.end.y - 1.0:
		var x := m.position.x + 1.0
		while x < m.end.x - 1.0:
			var id := grid.world_to_id(Vector2(x, y))
			var c := grid.id_to_world(id)
			if region.has(id) and not env.blocked(c, MARGIN) and not env.near(c, 3.0).is_empty():
				out.append(c)
			x += 2.0
		y += 2.0
	return out


# --- Part 1: cells --------------------------------------------------------------

func _run_cells() -> void:
	var b := _build(false)
	var env: EnvironmentField = b.env
	var grid: WalkGrid = b.grid
	var reg := grid.grid.region
	var open := 0
	var centre_blocked: Array[Vector2i] = []
	var cross: Array = []  # [a, b, first blocked point, both ends clear]
	var cross_clear := 0
	var pinch: Array[Vector2i] = []
	var by_struct := {}  # near desc (role/kind/tag) -> count of flagged cells/pairs
	for y in range(reg.position.y, reg.end.y):
		for x in range(reg.position.x, reg.end.x):
			var id := Vector2i(x, y)
			if not _open(grid, id):
				continue
			open += 1
			var c := grid.id_to_world(id)
			var c_bl := env.blocked(c, MARGIN)
			if c_bl:
				centre_blocked.append(id)
			if (not _open(grid, id + Vector2i(1, 0)) and not _open(grid, id - Vector2i(1, 0))) \
					or (not _open(grid, id + Vector2i(0, 1)) and not _open(grid, id - Vector2i(0, 1))):
				pinch.append(id)
			for d in [Vector2i(1, 0), Vector2i(0, 1)]:
				var n: Vector2i = id + d
				if not _open(grid, n):
					continue
				var e := grid.id_to_world(n)
				var hit := Vector2.INF
				var k := 0
				while float(k) * SAMPLE <= WalkGrid.CELL + 0.0001:
					var p := c.lerp(e, minf(float(k) * SAMPLE / WalkGrid.CELL, 1.0))
					if env.blocked(p, MARGIN):
						hit = p
						break
					k += 1
				if hit != Vector2.INF:
					var ends_clear := not c_bl and not env.blocked(e, MARGIN)
					if ends_clear:
						cross_clear += 1
					cross.append([id, n, hit, ends_clear])
	print("STALL cells city=%s open=%d centre_blocked=%d cross_blocked=%d cross_blocked_clear_ends=%d pinch=%d"
		% [_city, open, centre_blocked.size(), cross.size(), cross_clear, pinch.size()])
	for i in mini(LIST, centre_blocked.size()):
		var id := centre_blocked[i]
		var w := _widths(grid, id)
		print("STALL cell centre_blocked at=(%.2f,%.2f) id=%s width_x=%d width_y=%d near=%s blocker=%s"
			% [grid.id_to_world(id).x, grid.id_to_world(id).y, id, w.x, w.y, _near_desc(env, grid.id_to_world(id)),
			_blocker_desc(env, grid.id_to_world(id))])
	for i in mini(LIST, cross.size()):
		var r: Array = cross[i]
		var a := grid.id_to_world(r[0])
		var hit: Vector2 = r[2]
		print("STALL cell cross_blocked from=(%.2f,%.2f) to=(%.2f,%.2f) hit=(%.2f,%.2f) ends_clear=%s blocker=%s"
			% [a.x, a.y, grid.id_to_world(r[1]).x, grid.id_to_world(r[1]).y, hit.x, hit.y, r[3], _blocker_desc(env, hit)])
	for i in mini(LIST, pinch.size()):
		var id := pinch[i]
		var w := _widths(grid, id)
		print("STALL cell pinch at=(%.2f,%.2f) width_x=%d width_y=%d near=%s"
			% [grid.id_to_world(id).x, grid.id_to_world(id).y, w.x, w.y, _near_desc(env, grid.id_to_world(id))])
	# Where they gather: the structures most flagged cells and pairs lie by.
	for id in centre_blocked:
		var key := _blocker_desc(env, grid.id_to_world(id))
		by_struct[key] = int(by_struct.get(key, 0)) + 1
	for r: Array in cross:
		var key := _blocker_desc(env, r[2])
		by_struct[key] = int(by_struct.get(key, 0)) + 1
	var keys := by_struct.keys()
	keys.sort_custom(func(p, q): return int(by_struct[p]) > int(by_struct[q]))
	for i in mini(15, keys.size()):
		print("STALL cell hotspot n=%d structure=%s" % [by_struct[keys[i]], keys[i]])
	# The other way round: ground a body may stand on inside a cell the grid closed, from which the straight step to
	# where the grid sends it (nearest_walkable) runs into a margin -- a walker that drifts in there cannot walk out.
	var traps := _traps(env, grid)
	var trap_by := {}
	for i in traps.size():
		var r: Array = traps[i]
		var at: Vector2 = r[1]
		var nw: Vector2 = r[2]
		var key := _near_desc(env, at).get_slice("@", 0)
		trap_by[key] = int(trap_by.get(key, 0)) + 1
		if i < LIST:
			print("STALL cell trap at=(%.2f,%.2f) cell=%s grid_sends_to=(%.2f,%.2f) near=%s"
				% [at.x, at.y, r[0], nw.x, nw.y, _near_desc(env, at)])
	var tkeys := trap_by.keys()
	tkeys.sort_custom(func(p, q): return int(trap_by[p]) > int(trap_by[q]))
	for i in mini(10, tkeys.size()):
		print("STALL cell trap_by n=%d nearest=%s" % [trap_by[tkeys[i]], tkeys[i]])
	var line := "city=%s part=cells open=%d centre_blocked=%d cross_blocked=%d cross_blocked_clear_ends=%d pinch=%d traps=%d" \
		% [_city, open, centre_blocked.size(), cross.size(), cross_clear, pinch.size(), traps.size()]
	print("STALL total " + line)
	_summaries.append(line)
	_tear_down(b)


# --- Part 2: hounds --------------------------------------------------------------

func _run_hounds() -> void:
	var b := _build(false)
	var env: EnvironmentField = b.env
	var grid: WalkGrid = b.grid
	var field: EnemyField = b.field
	var crowd: Crowd = b.crowd
	var world: Node2D = b.world
	var region := _main_region(grid)
	var spots := _town_spots(env, grid, region)
	var prey: Person = crowd.citizens[0]
	for p in crowd.citizens + crowd.soldiers:
		p.inside = true  # out of every hound's sight but the one prey's
	prey.inside = false
	prey.mind = Person.Mind.CALM
	var mul := HoundGateFx.SPEED / (Animal.DOG_SPEED * Animal.RUN)
	var k := maxi(spots.size() / HOUNDS, 1)
	var reached := 0
	var reach_t := 0.0
	var giveups := 0
	var stalled := 0.0
	var worst: Array = []  # [stall seconds, at, hound index]
	for i in HOUNDS:
		var start: Vector2 = spots[(k / 2 + i * k) % spots.size()]
		var target := _hound_target(grid, spots, start, i)
		if target == Vector2.INF:
			print("STALL hound i=%d start=(%.2f,%.2f) no target 8-15 away" % [i, start.x, start.y])
			continue
		prey.ground_pos = target
		var line_clear := grid.clear_line(start, target)
		var path_n := grid.path(start, target).size()
		var visitors := Visitors.new().setup(field, crowd, grid, world)
		var a := visitors.summon(start, Animal.Breed.HELLHOUND, 99, mul, 30.0, 0.0, 1.0, false)
		var t := 0.0
		var got := -1.0
		var ups := 0
		var still := 0.0
		var run := 0.0
		var run_at := start
		var longest := 0.0
		var longest_at := start
		var win_from := a.ground_pos
		var win_t := 0.0
		var rule: Visitors.Rule = visitors._rules[a]
		var prev_skip := 0.0
		while t < _hound_s:
			prey.ground_pos = target
			visitors.step(HOUND_DT)
			t += HOUND_DT
			# A give-up (walk_to returned with Animal.blocked) is when Visitors leaves the prey alone SKIP_FOR.
			var skip_left: float = rule.skip_left
			if skip_left > prev_skip + 0.0001:
				ups += 1
			prev_skip = skip_left
			win_t += HOUND_DT
			if win_t >= HOUND_WINDOW - 0.0001:
				if a.ground_pos.distance_to(win_from) < HOUND_STILL:
					still += win_t
					if run == 0.0:
						run_at = win_from
					run += win_t
					if run > longest:
						longest = run
						longest_at = run_at
				else:
					run = 0.0
				win_from = a.ground_pos
				win_t = 0.0
			if a.ground_pos.distance_to(target) <= HOUND_REACH:
				got = t
				break
		var left := a.ground_pos.distance_to(target)
		print("STALL hound i=%d start=(%.2f,%.2f) target=(%.2f,%.2f) dist=%.1f line_clear=%s path_cells=%d reached=%s t=%.1f giveups=%d stalled_s=%.1f longest=%.1f at=(%.2f,%.2f) left=%.1f end=(%.2f,%.2f) near=%s"
			% [i, start.x, start.y, target.x, target.y, start.distance_to(target), line_clear, path_n,
			"yes" if got >= 0.0 else "no", got if got >= 0.0 else t, ups, still, longest, longest_at.x, longest_at.y,
			left, a.ground_pos.x, a.ground_pos.y, _near_desc(env, longest_at)])
		if got >= 0.0:
			reached += 1
			reach_t += got
		giveups += ups
		stalled += still
		worst.append([longest, longest_at, i])
		visitors.clear()
	var line := "city=%s part=hounds reached=%d/%d mean_t=%.1f giveups=%d stalled_s=%.1f" \
		% [_city, reached, HOUNDS, reach_t / maxf(float(reached), 1.0), giveups, stalled]
	print("STALL total " + line)
	_summaries.append(line)
	_tear_down(b)


## A spot 8-15 from `start` that people can walk to, behind buildings (no straight line) where there is one.
static func _hound_target(grid: WalkGrid, spots: Array[Vector2], start: Vector2, i: int) -> Vector2:
	var behind: Array[Vector2] = []
	var open: Array[Vector2] = []
	for s in spots:
		var d := s.distance_to(start)
		if d < 8.0 or d > 15.0:
			continue
		if grid.clear_line(start, s):
			open.append(s)
		else:
			behind.append(s)
	for pool: Array[Vector2] in [behind, open]:
		for j in pool.size():
			var s: Vector2 = pool[(i * 7 + j) % pool.size()]
			if not grid.path(start, s).is_empty():
				return s
	return Vector2.INF


# --- Part 3: people ---------------------------------------------------------------

func _start_people(variant: String) -> void:
	_w = _build(true)
	_frame = 0
	_end_frame = roundi(_people_s * 60.0)
	_track.clear()
	_episodes.clear()
	_far_goal.clear()
	_far_round = 0
	_far_sent = 0
	_walking = 0
	_moved = 0
	_unsticks0 = Person.unsticks
	_spots = _town_spots(_w.env, _w.grid, _main_region(_w.grid))
	print("STALL people city=%s variant=%s citizens=%d soldiers=%d seconds=%.0f"
		% [_city, variant, (_w.crowd as Crowd).citizens.size(), (_w.crowd as Crowd).soldiers.size(), _people_s])


## Ten calm citizens, picked by a fixed stride, each sent to a town spot FAR_MIN-FAR_MAX away that has a path.
func _send_far() -> void:
	var crowd: Crowd = _w.crowd
	var calm: Array[Person] = []
	for p in crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and not p.inside and p.mind == Person.Mind.CALM \
				and p.queue_spot == Vector2.INF:
			calm.append(p)
	if calm.is_empty():
		return
	var stride := maxi(calm.size() / FAR_COUNT, 1)
	for j in mini(FAR_COUNT, calm.size()):
		var p: Person = calm[(_far_round + j * stride) % calm.size()]
		var pool: Array[Vector2] = []
		for s in _spots:
			var d := s.distance_to(p.ground_pos)
			if d >= FAR_MIN and d <= FAR_MAX:
				pool.append(s)
		for tries in mini(6, pool.size()):
			var g: Vector2 = pool[(_far_round * 7 + j * 13 + tries) % pool.size()]
			p.set_goal(g)
			if not p._path.is_empty():
				_far_goal[p] = g
				_far_sent += 1
				break
	_far_round += 1


## Free to walk: alive, out, not queued or held, in a walking mind, on its feet.
static func _free_to_walk(p: Person) -> bool:
	if not is_instance_valid(p) or not p.is_alive() or p.inside or p.state != DummyEnemy.State.WANDER:
		return false
	if p.queue_spot != Vector2.INF or p.mind == Person.Mind.ASLEEP or p.mind == Person.Mind.HOLD or p.is_frozen():
		return false
	if p.wait > 0.0 or p._scream_left > 0.0 or p._down_left > 0.0 or p._getup_left > 0.0 or p._stumble > 0.0 \
			or p._startle_left > 0.0:
		return false
	return p._goal != Vector2.INF and p.ground_pos.distance_to(p._goal) > Person.GOAL_REACH


func _sample(now: float) -> void:
	var crowd: Crowd = _w.crowd
	var env: EnvironmentField = _w.env
	for p in crowd.citizens + crowd.soldiers:
		if not is_instance_valid(p):
			continue
		var tr: Dictionary = _track.get(p, {})
		if not _free_to_walk(p):
			_close(tr)
			_track.erase(p)
			continue
		_walking += 1
		if not tr.is_empty() and p.ground_pos != tr.get("last", Vector2.INF):
			_moved += 1
		if tr.is_empty() or p.ground_pos.distance_to(tr.anchor) >= PEOPLE_STILL or p._goal != tr.goal:
			_close(tr)
			_track[p] = {"anchor": p.ground_pos, "since": now, "goal": p._goal, "ep": {}, "last": p.ground_pos}
			continue
		tr.last = p.ground_pos
		if now - float(tr.since) < PEOPLE_STALL - 0.001:
			continue
		var ep: Dictionary = tr.ep
		if ep.is_empty():
			ep = {"who": p.get_instance_id(), "start": tr.since, "at": tr.anchor, "mind": Person.Mind.keys()[p.mind], "soldier": p.soldier,
				"path_empty0": p._path.is_empty(), "far": _far_goal.get(p, Vector2.INF) == p._goal,
				"goal": p._goal, "n": 0, "path_empty": 0, "holding": 0, "in_margin": 0, "target_blocked": 0,
				"idle": 0, "end": now, "leg": "%d/%d" % [p._leg, p._path.size()]}
			tr.ep = ep
		ep.end = now
		ep.n = int(ep.n) + 1
		ep.path_empty = int(ep.path_empty) + (1 if p._path.is_empty() else 0)
		ep.holding = int(ep.holding) + (1 if p._target.distance_to(p.ground_pos) < 0.01 else 0)
		ep.in_margin = int(ep.in_margin) + (1 if env.blocked(p.ground_pos, MARGIN) else 0)
		ep.target_blocked = int(ep.target_blocked) + (1 if env.blocked(p._target, MARGIN) else 0)
		ep.idle = int(ep.idle) + (1 if p._idle > 0.0 else 0)
		ep.target = p._target
		ep.leg_end = "%d/%d" % [p._leg, p._path.size()]


func _close(tr: Dictionary) -> void:
	if tr.is_empty() or (tr.ep as Dictionary).is_empty():
		return
	var ep: Dictionary = tr.ep
	ep.dur = float(ep.end) - float(ep.start)
	_episodes.append(ep)


func _end_people() -> void:
	for p in _track.keys():
		_close(_track[p])
	_track.clear()
	var env: EnvironmentField = _w.env
	_episodes.sort_custom(func(a, b): return float(a.dur) > float(b.dur))
	var people := {}
	var total := 0.0
	var over5 := 0
	var empty0 := 0
	var holding := 0
	var margin := 0
	var tblocked := 0
	var far := 0
	for ep in _episodes:
		people[ep.who] = true
		total += float(ep.dur)
		over5 += 1 if float(ep.dur) > 5.0 else 0
		empty0 += 1 if ep.path_empty0 else 0
		var n := maxf(float(ep.n), 1.0)
		holding += 1 if float(ep.holding) / n >= 0.5 else 0
		margin += 1 if float(ep.in_margin) / n >= 0.5 else 0
		tblocked += 1 if float(ep.target_blocked) / n >= 0.5 else 0
		far += 1 if ep.far else 0
	for i in mini(LIST, _episodes.size()):
		var ep: Dictionary = _episodes[i]
		var n := maxf(float(ep.n), 1.0)
		var at: Vector2 = ep.at
		var g: Vector2 = ep.goal
		var tg: Vector2 = ep.target
		print("STALL person variant=%s start=%.1f dur=%.1f at=(%.2f,%.2f) mind=%s soldier=%s far=%s goal=(%.1f,%.1f) goal_d=%.1f path_empty0=%s path_empty=%.0f%% holding=%.0f%% in_margin=%.0f%% target_blocked=%.0f%% idle=%.0f%% target=(%.2f,%.2f) leg=%s->%s near=%s"
			% [_phase, float(ep.start), float(ep.dur), at.x, at.y, ep.mind, ep.soldier, ep.far, g.x, g.y, at.distance_to(g),
			ep.path_empty0, 100.0 * float(ep.path_empty) / n, 100.0 * float(ep.holding) / n,
			100.0 * float(ep.in_margin) / n, 100.0 * float(ep.target_blocked) / n, 100.0 * float(ep.idle) / n,
			tg.x, tg.y, ep.leg, ep.leg_end, _near_desc(env, at)])
	var crowd: Crowd = _w.crowd
	var line := "city=%s part=people variant=%s seconds=%.0f episodes=%d people=%d stalled_s=%.1f over5s=%d path_empty_at_start=%d holding=%d in_margin=%d target_blocked=%d far_goal=%d far_sent=%d walking_samples=%d moved_samples=%d alive=%d escaped=%d unsticks=%d" \
		% [_city, _phase, _people_s, _episodes.size(), people.size(), total, over5, empty0, holding, margin, tblocked,
		far, _far_sent, _walking, _moved, crowd.alive_citizens(), crowd.escaped_count, Person.unsticks - _unsticks0]
	print("STALL total " + line)
	_summaries.append(line)
	_tear_down(_w)
	_w = {}


# --- Spot: one point looked at closely -------------------------------------------------

static func _vec(t: String) -> Vector2:
	return Vector2(float(t.get_slice(",", 0)), float(t.get_slice(",", 1)))


func _run_spot() -> void:
	var b := _build(false)
	var env: EnvironmentField = b.env
	var grid: WalkGrid = b.grid
	var at := _spot_at
	var id := grid.world_to_id(at)
	print("STALL spot at=(%.2f,%.2f) cell=%s centre=(%.2f,%.2f) walkable=%s blocked=%s blocker=%s near=%s"
		% [at.x, at.y, id, grid.id_to_world(id).x, grid.id_to_world(id).y, grid.walkable(at), env.blocked(at, MARGIN),
		_blocker_desc(env, at), _near_desc(env, at)])
	for dy in range(-3, 4):
		var row := ""
		for dx in range(-3, 4):
			var c := id + Vector2i(dx, dy)
			if dx == 0 and dy == 0:
				row += "@"
			elif not _open(grid, c):
				row += "#"
			elif env.blocked(grid.id_to_world(c), MARGIN):
				row += "m"
			else:
				row += "."
		print("STALL spot row y=%.2f %s" % [grid.id_to_world(id + Vector2i(0, dy)).y, row])
	var nw := grid.nearest_walkable(at)
	print("STALL spot nearest_walkable=(%.2f,%.2f) d=%.2f straight_blocked=%s" % [nw.x, nw.y, at.distance_to(nw),
		_crosses(env, at, nw)])
	for r: Structure in env.near(at, 1.0):
		print("STALL spot structure %s/%s/%s footprint=%s walkable=%s d=%.2f" % [r.role, Structure.Kind.keys()[r.kind],
			r.art_tag, r.footprint, r.walkable, r.distance_to(at)])
	if _spot_to != Vector2.INF:
		var path := grid.path(at, _spot_to)
		var head: PackedStringArray = []
		for k in mini(6, path.size()):
			head.append("(%.2f,%.2f)" % [path[k].x, path[k].y])
		print("STALL spot path to=(%.2f,%.2f) n=%d head=%s first_step_blocked=%s" % [_spot_to.x, _spot_to.y, path.size(),
			" ".join(head), _crosses(env, at, path[0]) if not path.is_empty() else false])
	_summaries.append("city=%s part=spot at=(%.2f,%.2f)" % [_city, at.x, at.y])
	_tear_down(b)


## Whether a straight walk from `a` to `b` enters a margin it did not start in (sampled every SAMPLE).
static func _crosses(env: EnvironmentField, a: Vector2, b: Vector2) -> bool:
	if a == Vector2.INF or b == Vector2.INF:
		return false
	var inside := env.blocked(a, MARGIN)
	var n := maxi(ceili(a.distance_to(b) / SAMPLE), 1)
	for k in range(1, n + 1):
		var on := env.blocked(a.lerp(b, float(k) / float(n)), MARGIN)
		if on and not inside:
			return true
		inside = on
	return false
