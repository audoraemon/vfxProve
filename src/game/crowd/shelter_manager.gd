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
	if _crowd.doors() != &"":
		return false  # every door shut or open (Every Door): no building takes anyone in
	if _crowd.in_law(p, LawZone.DISORDER):
		return false  # Decree's Disorder (LawZone): the door he makes for leads back out, before any roll
	if _crowd.in_law(p, LawZone.NO_DOORS):
		return false  # Decree's NO DOORS (LawZone): no door opens to him, before any roll
	if p.rng.randf() >= (CHANCE_SEVERE if kind in SEVERE else CHANCE):
		return false
	var best: Structure = null
	var best_d := REACH
	for s: Structure in shelters.keys():
		if not _usable(s) or s.center().distance_to(from) <= radius:
			continue
		var e: Dictionary = shelters[s]
		if (e.inside as Array).size() + (e.coming as Array).size() >= capacity(s) and not _hallowed(s):
			continue
		if _barred(s):
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
		and (_crowd.fires == null or not _crowd.fires.is_burning(s)) and _crowd.structure_mark(s) != &"cursed"


## A hallowed building (Anathema): everyone must be inside it, past its capacity, and stays whatever happens to it.
func _hallowed(s: Structure) -> bool:
	return is_instance_valid(s) and not s.destroyed and _crowd.structure_mark(s) == &"hallowed"


## Send `p` into `s` whatever its room (a hallowed building): true when it is on its way to the door.
func send_in(p: Person, s: Structure) -> bool:
	if not shelters.has(s) or not is_instance_valid(p) or not p.is_alive() or p.inside or _crowd.doors() != &"":
		return false
	if _barred(s) or _crowd.in_law(p, LawZone.NO_DOORS):
		return false  # Decree's NO DOORS (LawZone)
	shelters[s].coming.append(p)
	p.seek_shelter(s, _door(s, p.ground_pos))
	return true


## Decree's NO DOORS (LawZone) holds where `s` stands: nobody goes into it or comes out. False at once with no law laid.
func _barred(s: Structure) -> bool:
	return not _crowd.laws.is_empty() and is_instance_valid(s) and _crowd.law_at(s.center(), LawZone.NO_DOORS) != null


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
	# Every Door: shut, nobody goes in or comes out; open (or shut), nobody is taken in.
	var barred := _crowd.doors() != &""
	var shut := barred and _crowd.doors_shut()
	for s: Structure in shelters.keys():
		var e: Dictionary = shelters[s]
		var holy := _hallowed(s)
		# On their way in: arrive, or give up if the shelter stopped being one.
		var still: Array = []
		for p in e.coming:
			if not is_instance_valid(p) or not p.is_alive() or p.mind != Person.Mind.SHELTER or p.shelter != s:
				continue
			if barred or ((not _usable(s) or evacuating) and not holy) or _barred(s) or _crowd.in_law(p, LawZone.NO_DOORS):
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
		if holy or shut or _barred(s):
			# nobody leaves a hallowed house, nor any while every door is shut (Every Door) or barred by law (Decree's NO DOORS):
			# struck, burning or the town leaving, they stay
			e.clear = 0.0
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


## Every door bursts open at once (Every Door's OPEN): everyone inside every shelter is thrown `push` out of its door
## into the street (the nearest open ground there), knocked down, and comes round as anyone leaving would. Returns
## those thrown out.
func throw_out(push: float) -> Array[Person]:
	var out: Array[Person] = []
	for s: Structure in shelters.keys():
		out.append_array(throw_out_of(s, push))
	return out


## One building's door bursts open (Doors of the Dead): everyone sheltering in `s` is thrown out as throw_out() throws
## them. Returns those thrown out; none when nobody is in it.
func throw_out_of(s: Structure, push: float) -> Array[Person]:
	var out: Array[Person] = []
	if not shelters.has(s):
		return out
	var e: Dictionary = shelters[s]
	for v in e.inside:
		if not is_instance_valid(v):
			continue
		var p := v as Person
		_exit(p, s)
		var away := p.ground_pos - s.center()
		var to := p.ground_pos + (away.normalized() if away.length() > 0.01 else Vector2.DOWN) * push
		if p.grid != null:
			var w := p.grid.nearest_walkable(to)
			if w != Vector2.INF:
				to = w
		p.ground_pos = to
		p.leave_shelter(false)
		p.knock_down()
		out.append(p)
	e.inside = []
	e.clear = 0.0
	return out


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
