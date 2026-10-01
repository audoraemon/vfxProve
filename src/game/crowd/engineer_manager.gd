class_name EngineerManager
extends RefCounted
## The town's engineers (v0.05): teams of two from the workshop who mend what the god breaks, out from City
## Emergency. A team takes the job scoring highest on PRIORITY less DISTANCE_WEIGHT for each unit of the way there --
## the Citadel first, then the ways out (the gates, the bridge), then the Bell Tower and the cathedral, then houses --
## never one another team holds, and changes it only for one SWITCH_MARGIN better. Damaged standing buildings (under
## DAMAGED of their health) are healed RATE of their health a second while both of the team stand at the site; a
## fallen gate or bridge is rebuilt in REBUILD seconds, as it was. The Citadel mends only back to its last collapse:
## its fallen towers and walls stay down. Once the town evacuates the gates are left alone: a fallen gate lets the
## crowd out with no queue, and a rebuilt one would hold it back. A team that loses a member is lost, and the workshop sends out another
## REPLACE seconds later while it stands. Only towns whose profile has engineer_teams have engineers.

signal turned_out
signal rebuilt(s: Structure)
signal team_lost

enum Job { NONE, CITADEL, ROUTE, LANDMARK, HOUSE }
const PRIORITY := {Job.CITADEL: 100.0, Job.ROUTE: 80.0, Job.LANDMARK: 60.0, Job.HOUSE: 20.0}
const DISTANCE_WEIGHT := 2.0
const DAMAGED := 0.9
## The Citadel is a job once this share of its full health can be mended.
const CITADEL_DAMAGED := 0.02
const RATE := 0.05
const REBUILD := 20.0
const REPLACE := 60.0
## A replacement that finds nobody to send tries again this much later.
const RETRY := 5.0
## How near its place at the site each of the team must stand to work, and how far apart the two stand.
const WORK_REACH := 1.0
const PAIR_GAP := 0.45
## A site is this far out from the building's edge.
const SITE_OUT := 0.45
## Teams rethink their jobs this often.
const RETHINK := 2.0
const SWITCH_MARGIN := 20.0
## Minds a member can be called from (and goes back to work from after a fright).
const AVAILABLE := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.REGROUP]

## One dictionary per team: {"members": [Person, Person], "job": {} or a job (jobs()), "spots": [Vector2, Vector2],
## "progress": float (a rebuild's, 0..1), "working": bool}.
var teams: Array = []
var active := false
var workshop: Structure
## Where the teams wait for work, by the workshop.
var base := Vector2.INF
## Seconds until each lost team's replacement.
var replacing: Array[float] = []
var _think_in := 0.0
var _crowd: Crowd
var _env: EnvironmentField
var _grid: WalkGrid
var _town: Town


func setup(crowd: Crowd, env: EnvironmentField, grid: WalkGrid, town: Town, engineers: Array[Person],
		base_point: Vector2) -> EngineerManager:
	_crowd = crowd
	_env = env
	_grid = grid
	_town = town
	base = base_point
	for s in env.structures():
		if s.art_tag == &"workshop":
			workshop = s
			break
	for i in range(0, engineers.size() - 1, 2):
		teams.append(_team([engineers[i], engineers[i + 1]]))
	return self


func _team(members: Array) -> Dictionary:
	return {"members": members, "job": {}, "spots": [], "progress": 0.0, "working": false}


## City Emergency: the engineers turn out.
func begin() -> void:
	if active or teams.is_empty():
		return
	active = true
	_think_in = 0.0
	turned_out.emit()


func step(delta: float) -> void:
	if not active:
		return
	_check_losses()
	_replace(delta)
	_think_in -= delta
	if _think_in <= 0.0:
		_think_in = RETHINK
		_assign(true)
	else:
		_assign(false)
	for team in teams:
		_work(team, delta)


# --- Jobs -----------------------------------------------------------------------------------------------------------

## Every job there is now: {"type": Job, "target": Structure or Citadel, "site": Vector2, "rebuild": bool}.
func jobs() -> Array:
	var out: Array = []
	var c: Citadel = _town.citadel if is_instance_valid(_town) else null
	if is_instance_valid(c) and not c.is_fallen() and c.repair_cap() - c.health >= c.max_health * CITADEL_DAMAGED:
		var r := Rect2(c.origin, Vector2.ZERO)
		for p in c.parts:
			if is_instance_valid(p):
				r = r.merge(p.footprint)
		_add_job(out, Job.CITADEL, c, r, false)
	var routes: Array[Structure] = []
	if is_instance_valid(_town):
		if not _evacuating():
			routes.append_array(_town.gates)
		if is_instance_valid(_town.bridge):
			routes.append(_town.bridge)
	for s in routes:
		if is_instance_valid(s) and (s.destroyed or s.hp < s.max_hp * DAMAGED):
			_add_job(out, Job.ROUTE, s, s.footprint, s.destroyed)
	for s in _env.structures():
		if not is_instance_valid(s) or s.destroyed or s.hp >= s.max_hp * DAMAGED or s.damage_filter.is_valid():
			continue
		if _crowd.fires != null and _crowd.fires.is_burning(s):
			continue  # the fire brigade's first
		if s.role == &"temple" or s.art_tag == &"bell_tower":
			_add_job(out, Job.LANDMARK, s, s.footprint, false)
		elif s.role == &"house":
			_add_job(out, Job.HOUSE, s, s.footprint, false)
	return out


func _add_job(out: Array, type: Job, target: Object, rect: Rect2, rebuild: bool) -> void:
	var site := _site(rect)
	if site != Vector2.INF:
		out.append({"type": type, "target": target, "site": site, "rebuild": rebuild})


## Where to work on a building in `rect`: the middle of whichever side is walkable and nearest the market.
func _site(rect: Rect2) -> Vector2:
	var c := rect.get_center()
	var sides := [Vector2(c.x, rect.end.y + SITE_OUT), Vector2(c.x, rect.position.y - SITE_OUT),
		Vector2(rect.end.x + SITE_OUT, c.y), Vector2(rect.position.x - SITE_OUT, c.y)]
	var best := Vector2.INF
	var middle := TownLayout.MARKET_SQUARE.get_center()
	for g: Vector2 in sides:
		var w := g if _grid.walkable(g) else _grid.nearest_walkable(g, 3)
		if w != Vector2.INF and (best == Vector2.INF or w.distance_squared_to(middle) < best.distance_squared_to(middle)):
			best = w
	return best


func score(job: Dictionary, from: Vector2) -> float:
	return float(PRIORITY[job.type]) - DISTANCE_WEIGHT * from.distance_to(job.site)


func _evacuating() -> bool:
	return _crowd.alarms.stage >= AlarmManager.Stage.EVACUATION


## Is the job still there to do?
func _valid(job: Dictionary) -> bool:
	if job.is_empty() or not is_instance_valid(job.target):
		return false
	if job.type == Job.CITADEL:
		var c: Citadel = job.target
		return not c.is_fallen() and c.health < c.repair_cap()
	var s: Structure = job.target
	if s.kind == Structure.Kind.GATE and _evacuating():
		return false
	if job.rebuild:
		return s.destroyed
	return not s.destroyed and s.hp < s.max_hp


## Give each team without a job the best one free; on a rethink, a team with a job may move to one SWITCH_MARGIN
## better. Between rethinks only a team whose job just ended looks again (a team standing by waits for the next).
func _assign(rethink: bool) -> void:
	var needs := rethink
	for team in teams:
		if not team.job.is_empty() and not _valid(team.job):
			team.job = {}
			needs = true
	if not needs:
		return
	var all := jobs()
	for team in teams:
		if not team.job.is_empty() and not rethink:
			continue
		var from := _where(team)
		var best: Dictionary = {}
		var best_score := -INF
		for job: Dictionary in all:
			if _taken(job, team):
				continue
			var sc := score(job, from)
			if sc > best_score:
				best_score = sc
				best = job
		if best.is_empty():
			if team.job.is_empty():
				_stand_by(team)
			continue
		if team.job.is_empty() or (best.target != team.job.target and best_score > score(team.job, from) + SWITCH_MARGIN):
			_take(team, best)


func _taken(job: Dictionary, by: Dictionary) -> bool:
	for team in teams:
		if team != by and not team.job.is_empty() and team.job.target == job.target:
			return true
	return false


## Where a team is: its first living member.
func _where(team: Dictionary) -> Vector2:
	for p in team.members:
		if is_instance_valid(p) and (p as Person).is_alive():
			return (p as Person).ground_pos
	return base


func _take(team: Dictionary, job: Dictionary) -> void:
	team.job = job
	team.progress = 0.0
	team.working = false
	team.spots = _spots(job.site)
	for i in team.members.size():
		_send(team.members[i], team.spots[i])


## The two places at a site: the site and one beside it.
func _spots(site: Vector2) -> Array:
	var other := site + Vector2(PAIR_GAP, 0.0)
	if not _grid.walkable(other):
		other = site - Vector2(PAIR_GAP, 0.0)
	if not _grid.walkable(other):
		other = site
	return [site, other]


## Nothing to mend: wait by the workshop, on call.
func _stand_by(team: Dictionary) -> void:
	if base == Vector2.INF:
		return
	team.spots = _spots(base)
	for i in team.members.size():
		var p: Person = team.members[i]
		if is_instance_valid(p) and p.anchor != team.spots[i]:
			_send(p, team.spots[i])


func _send(p: Person, at: Vector2) -> void:
	if is_instance_valid(p) and p.is_alive() and (p.mind == Person.Mind.DUTY or p.mind in AVAILABLE):
		p.go_duty(at)


# --- Work -----------------------------------------------------------------------------------------------------------

func _work(team: Dictionary, delta: float) -> void:
	team.working = false
	var ready := true
	for i in team.members.size():
		var p: Person = team.members[i]
		var spot: Vector2 = team.spots[i] if i < team.spots.size() else base
		if p.mind != Person.Mind.DUTY:
			# Frightened off (or busy elsewhere): back to it once calm again.
			if p.mind in AVAILABLE and spot != Vector2.INF:
				p.go_duty(spot)
			ready = false
		elif p.has_goal() or p.ground_pos.distance_to(spot) > WORK_REACH:
			if not p.has_goal():
				p.go_duty(spot)  # knocked off its place
			ready = false
	if not ready or team.job.is_empty():
		return
	team.working = true
	var job: Dictionary = team.job
	if job.type == Job.CITADEL:
		var c: Citadel = job.target
		c.repair(RATE * c.keep.max_hp * delta)
	elif job.rebuild:
		team.progress += delta / REBUILD
		if team.progress >= 1.0:
			var s: Structure = job.target
			s.restore()
			team.job = {}
			team.working = false
			_think_in = 0.0
			rebuilt.emit(s)
	else:
		var s: Structure = job.target
		s.repair(RATE * s.max_hp * delta)


## How far along a team's job is, 0..1: a rebuild's progress, or the building's health.
func job_fraction(team: Dictionary) -> float:
	var job: Dictionary = team.job
	if job.is_empty() or not is_instance_valid(job.target):
		return 0.0
	if job.type == Job.CITADEL:
		var c: Citadel = job.target
		return clampf(c.health / maxf(c.repair_cap(), 1.0), 0.0, 1.0)
	if job.rebuild:
		return clampf(float(team.progress), 0.0, 1.0)
	var s: Structure = job.target
	return clampf(s.hp / s.max_hp, 0.0, 1.0)


func working() -> bool:
	for team in teams:
		if team.working:
			return true
	return false


# --- Losses ---------------------------------------------------------------------------------------------------------

## A team with a dead member is lost: the one left goes off duty, and the workshop sends another team later.
func _check_losses() -> void:
	var kept: Array = []
	for team in teams:
		var whole := true
		for p in team.members:
			whole = whole and is_instance_valid(p) and (p as Person).is_alive()
		if whole:
			kept.append(team)
			continue
		for p in team.members:
			if is_instance_valid(p):
				_crowd.off_duty(p)
		replacing.append(REPLACE)
		team_lost.emit()
	teams = kept


func _replace(delta: float) -> void:
	for i in replacing.size():
		replacing[i] -= delta
	var left: Array[float] = []
	for t in replacing:
		if t > 0.0:
			left.append(t)
		elif is_instance_valid(workshop) and not workshop.destroyed:
			var members := _recruit(2)
			if members.size() == 2:
				teams.append(_team(members))
			else:
				left.append(RETRY)
	replacing = left


## `n` citizens for a new team from the workshop: engineers off a team first, then craftsfolk, nearest the workshop.
func _recruit(n: int) -> Array:
	var on_team := []
	for team in teams:
		on_team.append_array(team.members)
	var pool: Array[Person] = []
	for p in _crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and p.profile != null and not p.inside and p.mind in AVAILABLE \
				and not on_team.has(p) and p.profile.role in [CitizenProfile.Role.ENGINEER, CitizenProfile.Role.CRAFT]:
			pool.append(p)
	var at := workshop.center() if is_instance_valid(workshop) else base
	pool.sort_custom(func(a: Person, b: Person) -> bool:
		if (a.profile.role == CitizenProfile.Role.ENGINEER) != (b.profile.role == CitizenProfile.Role.ENGINEER):
			return a.profile.role == CitizenProfile.Role.ENGINEER
		return a.ground_pos.distance_squared_to(at) < b.ground_pos.distance_squared_to(at))
	var out: Array = []
	for p in pool.slice(0, n):
		p.profile.role = CitizenProfile.Role.ENGINEER
		out.append(p)
	return out if out.size() == n else []


# --- Drawing --------------------------------------------------------------------------------------------------------

## Over the people: sparks between each working team, and a bar over what it mends (steel for a rebuild, green for
## health). Into `ci`, world space.
func draw(ci: CanvasItem) -> void:
	var t := float(Time.get_ticks_msec()) * 0.001
	for team in teams:
		if not team.working:
			continue
		var job: Dictionary = team.job
		var a := Iso.ground_to_screen(team.spots[0]) + Vector2(0, -8)
		var b := Iso.ground_to_screen(team.spots[1]) + Vector2(0, -8)
		for k in 5:
			var f := fmod(t * 7.0 + float(k) * 0.43, 1.0)
			var at := a.lerp(b, 0.5) + Vector2(sin(t * 23.0 + k * 2.1) * 5.0, -f * 7.0)
			ci.draw_rect(Rect2(at.round(), Vector2(2, 1) if k % 2 == 0 else Vector2(1, 1)), Color(1.0, 0.9, 0.55, 1.0 - f * 0.7))
		var top: Vector2
		if job.type == Job.CITADEL:
			var c: Citadel = job.target
			top = Iso.ground_to_screen(c.origin) + Vector2(0, -c.keep.max_height - 24.0)
		else:
			var s: Structure = job.target
			top = Iso.ground_to_screen(s.center()) + Vector2(0, -s.max_height - 16.0)
		var w := 24.0
		var r := Rect2(top - Vector2(w * 0.5, 0), Vector2(w, 3))
		ci.draw_rect(r.grow(1.0), Color(0, 0, 0, 0.75))
		var col := Color("9ab4d0") if job.rebuild else Color("7cd07a")
		ci.draw_rect(Rect2(r.position, Vector2(roundf(w * job_fraction(team)), 3)), col)
