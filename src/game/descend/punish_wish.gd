class_name PunishWish
extends Wish
## "Strike down the cruel tax collector", "Kill the informer, unseen" (v0.11 M1, spec §5.3, Punish): kill the marked citizen.
## params: "label", its tag's; "unseen", the kill must leave no living witness -- judged as The Warning judges
## (Crowd.nearest_witness(), once a Silent Doom's victims have all fallen) -- and a seen kill fails it. A target who leaves
## the town alive is beyond the god's reach: failed.
## v0.11 M4: "soldier" -- the target is a living soldier of no corps out of doors, not taken (soldiers()), at random; "edge" -- its tag
## pointed at from the screen's edge.

var target: Person
## Where the target fell, waiting to be judged; its death once judged, and whether anyone saw it.
var _fell_at := Vector2.INF
var _dead := false
var _seen := false


func choose(crowd: Crowd, town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	if bool(def.params.get("soldier", false)):
		# v0.11 M4: a soldier and a lay wisher, both checked before either is taken.
		var pool := soldiers(crowd, taken)
		if pool.is_empty() or Wish.lay(crowd, taken).is_empty() or not super(crowd, town, rng, taken):
			return false
		target = pool[rng.randi_range(0, pool.size() - 1)]
		taken.append(target)
		crowd._field.enemy_killed.connect(_on_killed)
		return true
	# Two people or none: checked before either is taken, so a failed choose leaves nobody in `taken`.
	if Wish.lay(crowd, taken).size() < 2 or not super(crowd, town, rng, taken):
		return false
	target = Wish.pick_lay(crowd, rng, taken)
	crowd._field.enemy_killed.connect(_on_killed)
	return true


## The soldiers a sergeant may be (v0.11 M4, mission spec §5): living, out of doors, of no corps, none of `taken` -- the pool
## MissionDirector._free_soldiers() draws from -- in the crowd's order. Each read as a Variant and through MissionDirector._alive()
## before any member (the final review): a body freed after its death fade aborts a typed loop.
static func soldiers(crowd: Crowd, taken: Array) -> Array[Person]:
	var out: Array[Person] = []
	for v: Variant in crowd.soldiers:
		if not MissionDirector._alive(v):
			continue
		var p := v as Person
		if not p.inside and p.corps == Person.Corps.NONE and not taken.has(p):
			out.append(p)
	return out


func people() -> Array[Person]:
	var out := super()
	if target != null:
		out.append(target)
	return out


func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	if e == target and not _dead and _fell_at == Vector2.INF:
		_fell_at = e.ground_pos


## Judges the death once the crowd has judged its own doomed, so a cast's victims never witness each other.
func step(_rules: Rules, _delta: float) -> void:
	if _fell_at == Vector2.INF or not _crowd._doomed.is_empty():
		return
	_dead = true
	_seen = bool(def.params.get("unseen", false)) and _crowd.nearest_witness(_fell_at) != null
	_fell_at = Vector2.INF


func _act(_rules: Rules) -> Status:
	if _dead:
		return Status.FAILED if _seen else Status.DONE
	if _fell_at == Vector2.INF and not is_instance_valid(target):
		return Status.FAILED
	return Status.PENDING


func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if MissionDirector._alive(target) and not target.inside:
		out.append(MapTag.person(target.ground_pos, COLOR, String(def.params.get("label", "")), bool(def.params.get("edge", false))))
	return out


func release() -> void:
	if is_instance_valid(_crowd) and _crowd._field != null and _crowd._field.enemy_killed.is_connected(_on_killed):
		_crowd._field.enemy_killed.disconnect(_on_killed)
