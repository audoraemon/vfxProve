class_name UnseenHandsObjective
extends Objective
## The Vigil Flame's bonus (v0.10): no beam of the Searchlight ever touches Wren.


func _init() -> void:
	label = "Unseen hands"
	reason = "unseen_hands"


func check(rules: Rules) -> Status:
	var d := rules.director as VigilFlameDirector
	return Status.FAILED if d != null and d.touches > 0 else Status.PENDING
