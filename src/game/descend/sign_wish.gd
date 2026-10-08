class_name SignWish
extends Wish
## "Show me a sign" (v0.11 M1, spec §5.3, Sign): any power cast within REACH of the wisher while they live and can see it --
## out of doors -- grants it.

const REACH := 4.0

var _seen := false


func on_cast(_key: String, at: Vector2) -> void:
	if MissionDirector._alive(wisher) and not wisher.inside and wisher.ground_pos.distance_to(at) <= REACH:
		_seen = true


func _act(_rules: Rules) -> Status:
	return Status.DONE if _seen else Status.PENDING
