class_name PunishWish
extends Wish
## "Strike down the cruel tax collector", "Kill the informer, unseen" (v0.11 M1, spec §5.3, Punish): kill the marked citizen.
## params: "label", its tag's; "unseen", the kill must leave no living witness -- judged as The Warning judges
## (Crowd.nearest_witness(), once a Silent Doom's victims have all fallen) -- and a seen kill fails it. A target who leaves
## the town alive is beyond the god's reach: failed.

var target: Person
## Where the target fell, waiting to be judged; its death once judged, and whether anyone saw it.
var _fell_at := Vector2.INF
var _dead := false
var _seen := false


func choose(crowd: Crowd, town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	if not super(crowd, town, rng, taken):
		return false
	target = Wish.pick_lay(crowd, rng, taken)
	if target == null:
		return false
	crowd._field.enemy_killed.connect(_on_killed)
	return true


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
		out.append(MapTag.person(target.ground_pos, COLOR, String(def.params.get("label", ""))))
	return out


func release() -> void:
	if is_instance_valid(_crowd) and _crowd._field != null and _crowd._field.enemy_killed.is_connected(_on_killed):
		_crowd._field.enemy_killed.disconnect(_on_killed)
