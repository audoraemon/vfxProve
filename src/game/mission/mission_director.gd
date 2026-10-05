class_name MissionDirector
extends RefCounted
## A mission's own actors and setup (v0.08): Rules steps it every frame of the mission, just before the objectives are
## checked, so it pauses and freezes with the mission. Last Judgement has none; The Warning's runs the omen, the
## watchman and the relay (WarningDirector).

var rules: Rules
var crowd: Crowd
var town: Town
## The battlefield's effect context, for the director's own effects (null in tests).
var ctx: FxContext
## The night this act belongs to (v0.09), or null for a single mission.
var night: NightState
## The act's timed events (v0.09), or null.
var timeline: EventTimeline
## Halcyon's Gaze (v0.10), for the campaign's Night 2 missions; null elsewhere.
var gaze: GazeMeter
## Halcyon's Faithful (v0.10), for the campaign's Night 2 missions: the people the director chose with _make_faithful().
var faithful: Array[Person] = []


func setup(r: Rules, c: Crowd, t: Town, x: FxContext, n: NightState = null) -> MissionDirector:
	rules = r
	crowd = c
	town = t
	ctx = x
	night = n
	_begin()
	return self


## Virtual: the mission's setup, once the town and its people exist.
func _begin() -> void:
	pass


## Virtual: one step of the mission.
func step(_delta: float) -> void:
	pass


## The ground point the HUD marks (The Warning's messenger), or Vector2.INF for none.
func marker() -> Vector2:
	return Vector2.INF


## Ground points the HUD marks with a small coloured diamond over the head (v0.10: Mira's House's grieving and
## Believers), as [Vector2, Color] pairs; none by default.
func marks() -> Array:
	return []


## What the director adds to the results (The Warning's "solved_by").
func report() -> Dictionary:
	return {}


## Virtual: what this act hands the next one, written into the night before the director is let go (v0.09).
func carry(_n: NightState) -> void:
	pass


## Virtual: let go of the world's signals.
func teardown() -> void:
	pass


## A point of walkable ground at or near `g` (`g` itself when the town has no walk grid, or none is free).
func _walkable(g: Vector2) -> Vector2:
	var w := crowd._grid.nearest_walkable(g) if crowd._grid != null else g
	return w if w != Vector2.INF else g


## Whether `p` still stands in the world: neither freed nor dead.
static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()


## Sorts the living citizens a Night 2 director may cast, into `clergy` and `lay`, in the crowd's order. Left out are the
## bell's keeper, anyone inside, and (from `lay`) the engineers and the bellkeeper.
func _sort_citizens(clergy: Array[Person], lay: Array[Person]) -> void:
	var keeper: Person = crowd.bell.keeper if crowd.bell != null else null
	for p in crowd.citizens:
		if not _alive(p) or p.profile == null or p.inside or p == keeper:
			continue
		if p.profile.role == CitizenProfile.Role.CLERGY:
			clergy.append(p)
		elif not p.profile.role in [CitizenProfile.Role.ENGINEER, CitizenProfile.Role.BELLKEEPER]:
			lay.append(p)


## Makes `p` one of Halcyon's Faithful.
func _make_faithful(p: Person) -> void:
	p.profile.faith = CitizenProfile.Faith.FAITHFUL
	faithful.append(p)


## Makes `count` of `pool` Faithful, spread evenly through it by stride (the middle of each stretch, from the front).
func _spread_faithful(pool: Array[Person], count: int) -> void:
	if pool.is_empty() or count <= 0:
		return
	var stride := maxi(1, pool.size() / count)
	var i := stride / 2
	var added := 0
	while i < pool.size() and added < count:
		_make_faithful(pool[i])
		added += 1
		i += stride


## Lets go of `handler` as the field's enemy_killed listener, if it is still one (for teardown()).
func _unhook_kills(handler: Callable) -> void:
	if is_instance_valid(crowd) and crowd._field != null and crowd._field.enemy_killed.is_connected(handler):
		crowd._field.enemy_killed.disconnect(handler)
