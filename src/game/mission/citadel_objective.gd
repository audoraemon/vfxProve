class_name CitadelObjective
extends Objective
## Last Judgement's win (v0.08; before, Rules._check_end()'s first test): the Citadel is down and the city's stability
## has reached zero.


func _init() -> void:
	label = "Destroy the Royal Citadel"
	reason = "citadel"


func check(rules: Rules) -> Status:
	var town := rules.town()
	if is_instance_valid(town) and is_instance_valid(town.citadel) and town.citadel.is_fallen() \
			and rules.stability.is_broken():
		return Status.DONE
	return Status.PENDING
