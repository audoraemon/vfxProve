class_name ShelterManager
extends RefCounted
## Taking cover (v0.04 P2): a citizen frightened by a danger may duck into a sturdy building nearby -- the cathedral,
## a tavern, the barracks, the workshop, a townhouse -- instead of running, if it has room. Inside, people are out
## of reach of every effect and out of sight. They come out once no danger has been near for a while, or when the
## town evacuates (then they make for the gates). A building hit hard (under half health) or set burning throws
## them out running; one that collapses kills those inside, or traps some under its rubble for the rescue squads (v0.07).
## A full cathedral is a target.

## Chance a frightened citizen seeks cover, by what frightened it: storms of stone, wind and blast send most people
## indoors, a strike they can outrun far fewer.
const SEVERE := [&"tornado", &"cinder", &"judgement", &"nova", &"orbital", &"collapse"]
const CHANCE_SEVERE := 0.8
const CHANCE := 0.3
## How far a frightened citizen will go for cover, and capacity per unit of floor (clamped).
const REACH := 5.0
const PER_AREA := 6.0
const CAPACITY := Vector2i(4, 20)
## Out when no danger has been within CLEAR_REACH for CLEAR_SECONDS.
const CLEAR_REACH := 8.0
const CLEAR_SECONDS := 5.0
## How near its door a citizen must be to go in.
const DOOR_REACH := 0.6
const HZ := 4.0
## A building under this share of its health throws its sheltering people out.
const FLUSH_HP := 0.5

var _crowd: Crowd
var _env: EnvironmentField
var _field: EnemyField
## Building -> {"inside": Array[Person], "coming": Array[Person], "clear": float}
var shelters := {}
var _step_in := 0.0


func setup(crowd: Crowd, env: EnvironmentField, field: EnemyField) -> ShelterManager:
	_crowd = crowd
	_env = env
	_field = field
	for s in env.structures():
		if is_shelter(s):
			shelters[s] = {"inside": [], "coming": [], "clear": 0.0}
	return self


static func is_shelter(s: Structure) -> bool:
	return s.role == &"temple" or s.kind == Structure.Kind.BARRACKS \
		or s.art_tag in [&"tavern", &"workshop", &"townhouse"]


static func capacity(s: Structure) -> int:
	return clampi(roundi(s.footprint.get_area() * PER_AREA), CAPACITY.x, CAPACITY.y)


func occupants(s: Structure) -> int:
	return (shelters[s].inside as Array).size() if shelters.has(s) else 0


func total_inside() -> int:
	var n := 0
	for s in shelters:
		n += (shelters[s].inside as Array).size()
	return n


## A citizen frightened by `kind` at `from` (radius `radius`): seek cover? True when it is on its way to a door.
func try_shelter(p: Person, from: Vector2, radius: float, kind: StringName) -> bool:
	if p.rng.randf() >= (CHANCE_SEVERE if kind in SEVERE else CHANCE):
		return false
	var best: Structure = null
	var best_d := REACH
	for s: Structure in shelters.keys():
		if not _usable(s) or s.center().distance_to(from) <= radius:
			continue
		var e: Dictionary = shelters[s]
		if (e.inside as Array).size() + (e.coming as Array).size() >= capacity(s):
			continue
		var d := s.distance_to(p.ground_pos)
		if d < best_d:
			best_d = d
			best = s
	if best == null:
		return false
	shelters[best].coming.append(p)
	p.seek_shelter(best, _door(best, p.ground_pos))
	return true


func _usable(s: Structure) -> bool:
	return is_instance_valid(s) and not s.destroyed and s.hp >= s.max_hp * FLUSH_HP \
		and (_crowd.fires == null or not _crowd.fires.is_burning(s))


func _door(s: Structure, from: Vector2) -> Vector2:
	var dir := (from - s.center()).normalized() if from.distance_to(s.center()) > 0.01 else Vector2.DOWN
	return _crowd._spot_near(s.center() + dir * (s.footprint.size.length() * 0.5 + 0.3), 0.2)


func step(delta: float) -> void:
	_step_in -= delta
	if _step_in > 0.0:
		return
	var dt := 1.0 / HZ
	_step_in = dt
	var evacuating := _crowd.alarms.stage >= AlarmManager.Stage.EVACUATION
	for s: Structure in shelters.keys():
		var e: Dictionary = shelters[s]
		# On their way in: arrive, or give up if the shelter stopped being one.
		var still: Array = []
		for p in e.coming:
			if not is_instance_valid(p) or not p.is_alive() or p.mind != Person.Mind.SHELTER or p.shelter != s:
				continue
			if not _usable(s) or evacuating:
				p.leave_shelter(evacuating)
				continue
			if not p.has_goal() and p.ground_pos.distance_to(p.shelter_door) <= DOOR_REACH:
				_enter(p, s)
				(e.inside as Array).append(p)
			elif not p.has_goal():
				p.leave_shelter(false)
			else:
				still.append(p)
		e.coming = still
		if (e.inside as Array).is_empty():
			continue
		if not is_instance_valid(s) or s.destroyed:
			# Some of those inside are trapped under the rubble for the rescue squads (v0.07); the rest die.
			var trapped: Array = []
			for p in e.inside:
				if not is_instance_valid(p):
					continue
				if _crowd.rescue != null and is_instance_valid(s) and (p as Person).rng.randf() < RescueManager.TRAPPED_SHARE:
					trapped.append(p)
					continue
				_exit(p, s)
				_field.kill(p, &"collapse", s.center())
			if not trapped.is_empty():
				_crowd.rescue.trap(trapped, s)
			e.inside = []
			continue
		if not _usable(s):
			_flush(s, e, true)
			continue
		if evacuating:
			_flush(s, e, false)
			continue
		var danger := not _crowd.threats.nearby(s.center(), CLEAR_REACH).is_empty()
		e.clear = 0.0 if danger else float(e.clear) + dt
		if float(e.clear) >= CLEAR_SECONDS:
			_flush(s, e, false)


## The others sheltering in the same building as `p` (v0.06: the plague passes between them).
func occupants_with(p: Person) -> Array:
	for s in shelters:
		var inside: Array = shelters[s].inside
		if inside.has(p):
			var out := inside.duplicate()
			out.erase(p)
			return out
	return []


## Take `p` out of whatever shelter it is in, back onto the street where it stood.
func release(p: Person) -> void:
	for s in shelters:
		var inside: Array = shelters[s].inside
		if inside.has(p):
			inside.erase(p)
			_exit(p, s)
			p.leave_shelter(false)
			return


## Everyone out of `s`: running from it (`fright`), or on their way (to the gates when the town evacuates).
func _flush(s: Structure, e: Dictionary, fright: bool) -> void:
	for p in e.inside:
		if not is_instance_valid(p):
			continue
		_exit(p, s)
		if fright:
			p.leave_shelter(false)
			p.panic(s.center(), s.footprint.size.length() * 0.5)
		else:
			p.leave_shelter(_crowd.alarms.stage >= AlarmManager.Stage.EVACUATION)
	e.inside = []
	e.clear = 0.0


func _enter(p: Person, s: Structure) -> void:
	p.inside = true
	p.visible = false
	p.ground_pos = s.center()
	_field.remove(p)


func _exit(p: Person, s: Structure) -> void:
	p.inside = false
	p.visible = true
	p.ground_pos = p.shelter_door if p.shelter_door != Vector2.INF else _door(s, s.center() + Vector2.DOWN)
	_field.add(p)


func clear() -> void:
	shelters.clear()
