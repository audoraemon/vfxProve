class_name WalkingCorpseFx
extends FxTimeline
## Walking Corpse (Death, Tier III, quiet; spec 5.4): two clicks -- a body (the remain within Remains.PICK_R of `origin`, a
## hidden one too: Rules refuses a first click with none, "NO DEAD THERE", before any cooldown), then where it should go
## (extra["to"]). The remain is taken off the ground (Remains.take()) and the body gets up: a ZOMBIE-breed Visitor wearing the
## dead person's own design with no grey (Color.WHITE) and no eyes (alpha 0), so it passes for living. It walks there by the
## streets (Animal.route_to()) at a person's walk pace, for at most WALK_LIFE. It hunts nobody, bites nobody, frightens
## nobody and is no danger the town registers; its Visitors pack is never stepped, so no soldier is drawn to it or strikes
## it. It walks like anyone else.
## When it gets there -- or cannot get any nearer, or WALK_LIFE runs out -- it lies down where it stands: Remains.move() puts
## the remain back on the ledger there with its clock restarted. A second click inside (or at the door of) a shelter or a
## house sends it to that building's door (door_of()); getting there it goes in and lies hidden (Remain.hidden): off the
## street drawing and out of every other power's reach, though Walking Corpse can walk it back out. A plague body that goes
## into a shelter brings the plague inside: up to INFECT_MOST of those sheltering there fall sick (Person.infect()), the
## nearest to the door first, a tie by instance id. No luck anywhere.
## Quiet: no alarm, no fright, no panic -- only q_walker, a shuffle of cloth and a joint's creak nobody turns at.

const WALK_LIFE := 40.0
const INFECT_MOST := 3
## The body takes this long to get up before it walks (it rises where it lay).
const T_RISE := 0.6
## Within this of where it was sent, it has got there and lies down.
const ARRIVE := 0.1
## Lying down within this of a building's door, it has gone in (hidden).
const IN_DOOR_R := 0.4
## A second click this near a shelter's or a house's footprint (inside it is 0) sends the body in at its door.
const DOOR_REACH := ShelterManager.DOOR_REACH
## The roles of the buildings it can go into (besides every shelter).
const INDOOR_ROLES: Array[StringName] = [&"house"]
## Lingering after it lies down: the effect ends this long after.
const SETTLE := 0.6
## Ash and grave dust, cold to nothing (Death's palette).
const DUST := [Color(0.85, 0.82, 0.74, 0.4), Color(0.6, 0.6, 0.6, 0.28), Color(0.42, 0.42, 0.44, 0.14), Color(0.3, 0.3, 0.32, 0.0)]

## The walker's pack (never stepped: the effect drives it), the walker, the remain it carries, the building it goes into (null
## for the open street), whether it has lain down, and whom it infected.
var visitors: Visitors
var walker: Animal
var remain: Remains.Remain
var building: Structure
var shelter: Structure
var laid := false
var infected: Array[Person] = []

## Where it walks: the second click on walkable ground, or the building's door.
var dest := Vector2.INF
var _grid: WalkGrid


## The shelter or house a second click at `to` sends the body into: the nearest standing one within DOOR_REACH of it (a tie
## by instance id), or null for the open street.
static func indoors_at(env: EnvironmentField, crowd: Crowd, to: Vector2) -> Structure:
	if env == null:
		return null
	var best: Structure = null
	var best_d := INF
	for s in env.near(to, DOOR_REACH + 4.0):
		if not is_instance_valid(s) or s.destroyed or not _enterable(s, crowd):
			continue
		var d := s.distance_to(to)
		if d > DOOR_REACH:
			continue
		if d < best_d or (d == best_d and best != null and s.get_instance_id() < best.get_instance_id()):
			best = s
			best_d = d
	return best


static func _enterable(s: Structure, crowd: Crowd) -> bool:
	if s.role in INDOOR_ROLES:
		return true
	if crowd != null and crowd.shelters != null:
		return crowd.shelters.shelters.has(s)
	return ShelterManager.is_shelter(s)


## Where the body goes in at building `s`: its door (EveryDoorFx.door_of(): the first face opening onto the street), on
## walkable ground; Vector2.INF when there is none.
static func door_of(s: Structure, grid: WalkGrid) -> Vector2:
	var door := EveryDoorFx.door_of(s, grid)
	if grid == null:
		return door
	return grid.nearest_walkable(door)


func _build() -> void:
	busy = T_RISE
	var rem: Remains = ctx.crowd.remains if ctx.crowd != null else null
	# The row's "reaches_hidden": a body walked indoors can be walked back out (Rules lets the cast through on the same flag).
	var reach_hidden := bool(PowerBook.get_power("walker").get("reaches_hidden", false))
	remain = rem.pick(origin, false, reach_hidden) if rem != null else null
	if remain == null:
		duration = 0.1  # no body there: Rules refuses such a click before it comes here
		return
	rem.take(remain)
	duration = WALK_LIFE + SETTLE
	_grid = ctx.crowd._grid
	var to: Vector2 = extra.get("to", remain.pos)
	building = indoors_at(ctx.env, ctx.crowd, to)
	if building != null:
		dest = door_of(building, _grid)
		if dest == Vector2.INF:
			building = null
	if building == null:
		dest = _grid.nearest_walkable(to) if _grid != null else to
		if dest == Vector2.INF:
			dest = remain.pos  # nowhere to walk to: it gets up and lies down again where it was
	shelter = building if building != null and ctx.crowd.shelters != null and ctx.crowd.shelters.shelters.has(building) else null
	# It gets up where it lay, in its own look: no grey, no eyes. It hunts nobody (seek 0) and bites nobody.
	var parent: Node2D = ctx.world if ctx.world != null else ctx.overhead
	visitors = Visitors.new().setup(ctx.field, ctx.crowd, _grid, parent)
	var pace := DummyEnemy.WALK_SPEED / (Animal.DOG_SPEED * Animal.RUN)
	walker = visitors.summon(remain.pos, Animal.Breed.ZOMBIE, 1, pace, 0.0, 0.0, 1.0, false)
	walker.wear(remain.design, remain.facing, Color.WHITE, Color(0, 0, 0, 0))
	visitors.give(walker, {"no_bite": true})
	ctx.play(&"q_walker", remain.pos)
	if DominionParts.staged(self):
		FxParts.smoke(self, Iso.ground_to_screen(remain.pos), 5.0, 10.0, T_RISE, Vector2(6, 14), Vector2(1, 3), Vector2(0.5, 1.0),
			Color(0, 0, 0, 0), DUST)


func _fx_process(delta: float) -> void:
	if laid or remain == null:
		return
	if not is_instance_valid(walker) or not walker.is_alive():
		# Carried off by another power (Heaven's Door takes a pack's walkers): the body is gone with it.
		laid = true
		walker = null
		duration = minf(duration, t + SETTLE)
		return
	walker.tick_visual(delta)
	if t >= WALK_LIFE:
		_lie_down()
		return
	if t < T_RISE:
		return
	var done := walker.route_to(dest, delta, _grid)
	if done or walker.ground_pos.distance_to(dest) <= ARRIVE:
		_lie_down()


## It lies down where it stands: the remain goes back on the ledger there, its clock restarted. At the building's door it goes
## in, hidden, and a plague body infects those sheltering there. `torn_down` (the effect freed without its end): the body is
## only put back -- no plague brought in, no dust raised, the pack only queued for freeing.
func _lie_down(torn_down := false) -> void:
	if laid:
		return
	laid = true
	var at := walker.ground_pos if is_instance_valid(walker) else remain.pos
	var inside := is_instance_valid(building) and at.distance_to(dest) <= IN_DOOR_R
	if inside:
		at = dest
	var rem: Remains = ctx.crowd.remains if is_instance_valid(ctx.crowd) else null
	if is_instance_valid(rem):
		rem.move(remain, at, inside)
	if torn_down:
		visitors.clear(true)
		walker = null
		return
	if inside and remain.sick and shelter != null:
		_bring_plague()
	if DominionParts.staged(self):
		FxParts.smoke(self, Iso.ground_to_screen(at), 5.0, 10.0, 0.3, Vector2(6, 14), Vector2(1, 3), Vector2(0.5, 1.0),
			Color(0, 0, 0, 0), DUST)
	visitors.clear()
	walker = null
	duration = minf(duration, t + SETTLE)


## Up to INFECT_MOST of those sheltering in `shelter` who are not sick yet fall sick, the nearest to the door first (a tie by
## instance id).
func _bring_plague() -> void:
	var near: Array[Person] = []
	for e in (ctx.crowd.shelters.shelters[shelter].inside as Array):
		var p := e as Person
		if is_instance_valid(p) and p.is_alive() and p.sick_left <= 0.0:
			near.append(p)
	near.sort_custom(func(a: Person, b: Person) -> bool:
		var da := a.ground_pos.distance_squared_to(dest)
		var db := b.ground_pos.distance_squared_to(dest)
		return da < db if da != db else a.get_instance_id() < b.get_instance_id())
	for p in near:
		if infected.size() >= INFECT_MOST:
			break
		if p.infect(PlagueManager.PLAGUE_LIFE):
			infected.append(p)


## Cut short while it walks (the act ends): it lies down where it is, so the body is never lost.
func _finish() -> void:
	if _can_lie_down():
		_lie_down()
	if visitors != null:
		visitors.clear()
	super()


## Freed without _finish (Battlefield.clear_effects() on a restart): the body is put back down where it had got to, as when cut
## short, so it is never lost while the ledger is still there (a ledger already freed with its crowd takes it with it); the
## walker is gone, the pack only queued for freeing (its parents may be mid-teardown). After _finish there is nothing left to do.
func _exit_tree() -> void:
	if _can_lie_down():
		_lie_down(true)
	if visitors != null:
		visitors.clear(true)
	walker = null
	super()


## Still walking, with a ledger to put the body back on. A walker already gone (another power carried it off) took the body.
func _can_lie_down() -> bool:
	return not laid and remain != null and is_instance_valid(ctx.crowd) and is_instance_valid(ctx.crowd.remains) \
		and is_instance_valid(walker)
