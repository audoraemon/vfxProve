class_name BrokenLanternsDirector
extends MissionDirector
## Broken Lanterns (v0.10 M3, the Ruin path's Night 2): Halcyon's six wayside shrines anchor his protection over the
## town. Break them before the Vigil relights them, and drink what was in them. A broken shrine is drained once it has
## stayed broken DRAIN_SECONDS. The flame-bearer walks the Vigil round the six, turns aside for a broken shrine, and
## relights it if he reaches it first (it stands again). A drained shrine is gone for good. All six drained win the
## night. A death someone sees adds to Halcyon's Gaze, and the bell fills it. Task 6 adds the Faithful's prayer at the
## standing shrines, the Lantern Knights at 1:30 and the kneelers at the last shrine. The shrines are this mission's
## own: placed here, never in the shared town layout, and taken away with the town (Town._built).

## Where the six shrines stand, in the Vigil's order (ground units; each is moved to the nearest open ground). Each
## stands well beyond GUARD_REACH of the Temple's door, where the Knights come out, so no Knight guards one by
## standing there.
const SHRINE_SPOTS := [Vector2(5.5, -4.8), Vector2(10.2, -8.8), Vector2(12.0, 9.2), Vector2(0.5, 13.0),
	Vector2(-7.0, 10.0), Vector2(-7.5, -4.0)]
## A shrine's footprint and height (a stone post, Structure.Kind.SHRINE), and its role. The role is not one of
## Rules.BUILDING_ROLES, so a shrine is never a building in the tally, the chain or the score.
const SHRINE_SIZE := Vector2(0.4, 0.4)
const SHRINE_H := 22.0
const ROLE := &"shrine"
## Where the bearer stands to relight a shrine (from its centre), and how near its footprint he must be.
const RELIGHT_OFF := Vector2(0.0, 0.7)
const RELIGHT_REACH := 1.2
## A broken shrine is drained once it has stayed broken this long.
const DRAIN_SECONDS := 20.0
## How many Faithful there are besides the clergy (spec §4.1: about 20 devout citizens).
const FAITHFUL := 20
## Where the camera opens: the market, between the shrines.
const CAMERA_AT := Vector2(1.0, 2.0)
## The marks over the shrines: standing (Halcyon's gold), and broken but not yet drained (ember).
const MARK_LIT := Color(0.95, 0.82, 0.42, 0.9)
const MARK_DRAINING := Color("ff9a3a")

var shrines: Array[Structure] = []
var faithful: Array[Person] = []
var vigil: VigilRoute
var temple_door := Vector2.INF
## Broken shrines not yet drained -> seconds left before they are.
var drain_left := {}
## Drained shrines (-> true): gone for good.
var drained := {}
## How many times the flame has relit a shrine.
var relit := 0
## Shrine -> where the bearer stands to relight it.
var _relight_at := {}


func _begin() -> void:
	gaze = GazeMeter.new()
	temple_door = _walkable(Vector2(TownLayout.TEMPLE.get_center().x, TownLayout.TEMPLE.end.y + 0.6))
	_place_shrines()
	_choose_faithful()
	_start_vigil()
	crowd._field.enemy_killed.connect(_on_killed)
	timeline = EventTimeline.new()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	_add_events()
	rules.banner.emit("BREAK THE SIX LANTERNS")


func _place_shrines() -> void:
	for spot: Vector2 in SHRINE_SPOTS:
		var at := _walkable(spot)
		var s := crowd._env.add_structure(Rect2(at - SHRINE_SIZE * 0.5, SHRINE_SIZE), SHRINE_H, Structure.Kind.SHRINE, ROLE)
		s.damage_filter = _shield
		s.broken.connect(_on_broken)
		town._built.append(s)  # the town takes it away with its own buildings (Town.teardown())
		shrines.append(s)
		_relight_at[s] = _walkable(at + RELIGHT_OFF)


func _walkable(g: Vector2) -> Vector2:
	var w := crowd._grid.nearest_walkable(g) if crowd._grid != null else g
	return w if w != Vector2.INF else g


## The clergy, and FAITHFUL lay citizens spread through the rest, are Halcyon's Faithful.
func _choose_faithful() -> void:
	var keeper: Person = crowd.bell.keeper if crowd.bell != null else null
	var lay: Array[Person] = []
	for p in crowd.citizens:
		if not _alive(p) or p.profile == null or p.inside or p == keeper:
			continue
		if p.profile.role == CitizenProfile.Role.CLERGY:
			_make_faithful(p)
		elif not p.profile.role in [CitizenProfile.Role.ENGINEER, CitizenProfile.Role.BELLKEEPER]:
			lay.append(p)
	if lay.is_empty():
		return
	var stride := maxi(1, lay.size() / FAITHFUL)
	var i := stride / 2
	var added := 0
	while i < lay.size() and added < FAITHFUL:
		_make_faithful(lay[i])
		added += 1
		i += stride


func _make_faithful(p: Person) -> void:
	p.profile.faith = CitizenProfile.Faith.FAITHFUL
	faithful.append(p)


## The flame-bearer and his two acolytes are the clergy nearest the Temple's door (else any Faithful). They walk the six
## shrines round and round from the first, turning aside for broken ones, the flame passing on if the bearer falls.
func _start_vigil() -> void:
	var pool: Array[Person] = faithful.duplicate()
	pool.sort_custom(func(a: Person, b: Person) -> bool:
		var ca := a.profile.role == CitizenProfile.Role.CLERGY
		var cb := b.profile.role == CitizenProfile.Role.CLERGY
		if ca != cb:
			return ca
		return a.ground_pos.distance_to(temple_door) < b.ground_pos.distance_to(temple_door))
	if pool.is_empty():
		return
	var route := PackedVector2Array()
	for s in shrines:
		route.append(relight_point(s))
	var acolytes: Array[Person] = []
	acolytes.assign(pool.slice(1, 3))
	vigil = VigilRoute.new().setup(route, pool[0], acolytes)
	vigil.loop = true
	vigil.pass_flame = true
	vigil.flame_passed.connect(func(_to: Person) -> void:
		rules.banner.emit("AN ACOLYTE TAKES UP THE FLAME")
		_sync_detour())
	vigil.start()


func step(delta: float) -> void:
	timeline.step(delta)
	gaze.judge_deaths(crowd)
	if vigil != null:
		vigil.step(delta)
	_drain(delta)
	_relight()
	_prayers_step(delta)
	if crowd.bell != null and crowd.bell.state == BellNetwork.State.RUNG:
		gaze.fill()


## A shrine broke: it drains from the start (a relit shrine broken again starts over).
func _on_broken(s: Structure) -> void:
	if drained.has(s):
		return
	drain_left[s] = DRAIN_SECONDS
	rules.banner.emit("A LANTERN BREAKS")
	_broke(s)
	_sync_detour()


func _drain(delta: float) -> void:
	for s: Structure in drain_left.keys():
		drain_left[s] = float(drain_left[s]) - delta
		if float(drain_left[s]) > 0.0:
			continue
		drain_left.erase(s)
		drained[s] = true
		rules.banner.emit("A LANTERN IS DRAINED (%d / %d)" % [drained.size(), shrines.size()])
		_drained_one(s)
		_sync_detour()


## The flame-bearer at a broken shrine not yet drained relights it: it stands again, whole.
func _relight() -> void:
	if vigil == null or not vigil.active or not _alive(vigil.bearer):
		return
	for s: Structure in drain_left.keys():
		if s.distance_to(vigil.bearer.ground_pos) > RELIGHT_REACH:
			continue
		drain_left.erase(s)
		s.restore()
		relit += 1
		rules.banner.emit("THE FLAME RELIGHTS A LANTERN")
		_relit(s)
		_sync_detour()


## The bearer turns aside for the nearest broken shrine not yet drained, or goes back to his round when there is none.
func _sync_detour() -> void:
	if vigil == null or not vigil.active:
		return
	var from := vigil.bearer.ground_pos if _alive(vigil.bearer) else temple_door
	var best := Vector2.INF
	for s: Structure in drain_left.keys():
		var p := relight_point(s)
		if best == Vector2.INF or from.distance_to(p) < from.distance_to(best):
			best = p
	if best != vigil.detour:
		vigil.divert(best)


## Structure.damage_filter for every shrine: a guarded shrine (Task 6: a Lantern Knight beside it) only shakes; any
## other takes the blow as a structure does, cracking and then breaking.
func _shield(s: Structure, amount: float, source: Vector2, kind: StringName) -> void:
	if guarded(s):
		s.shake(2.5)
		return
	s.hp -= amount
	s.mark_hit(amount / s.max_hp, kind)
	if s.hp <= 0.0:
		s.destroy(source, kind)
	elif s.hp < s.max_hp * Structure.CRACK_AT:
		s.crack()


func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	gaze.note_death(e.ground_pos)


func relight_point(s: Structure) -> Vector2:
	var p: Vector2 = _relight_at.get(s, s.center())
	return p


func draining(s: Structure) -> bool:
	return drain_left.has(s)


func is_drained(s: Structure) -> bool:
	return drained.has(s)


func drained_count() -> int:
	return drained.size()


func standing_shrines() -> Array[Structure]:
	var out: Array[Structure] = []
	for s in shrines:
		if not s.destroyed:
			out.append(s)
	return out


func marks() -> Array:
	var out := []
	for s in shrines:
		if not s.destroyed:
			out.append([s.center(), MARK_LIT])
		elif drain_left.has(s):
			out.append([s.center(), MARK_DRAINING])
	return out


## The HUD's arrow: the flame-bearer, while he is on his way to relight a shrine.
func marker() -> Vector2:
	if vigil == null or not vigil.active or vigil.detour == Vector2.INF or not _alive(vigil.bearer):
		return Vector2.INF
	return vigil.bearer.ground_pos


func report() -> Dictionary:
	return {"drained": drained.size(), "relit": relit}


func teardown() -> void:
	if is_instance_valid(crowd) and crowd._field != null and crowd._field.enemy_killed.is_connected(_on_killed):
		crowd._field.enemy_killed.disconnect(_on_killed)
	for s in shrines:
		if is_instance_valid(s) and s.broken.is_connected(_on_broken):
			s.broken.disconnect(_on_broken)
	vigil = null
	timeline = null


## Task 6 fills these in: the Lantern Knights' event; prayer and the Knights, each step; a shrine broken, relit or
## drained; and the Knights' guard.
func _add_events() -> void:
	pass


func _prayers_step(_delta: float) -> void:
	pass


func _broke(_s: Structure) -> void:
	pass


func _relit(_s: Structure) -> void:
	pass


func _drained_one(_s: Structure) -> void:
	pass


func guarded(_s: Structure) -> bool:
	return false


static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()
