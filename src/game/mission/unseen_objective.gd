class_name UnseenObjective
extends Objective
## The Warning's bonus (v0.08): the town never reaches Local Emergency. The alarm's stage only rises, so once it has
## the bonus is lost for good.


func _init() -> void:
	label = "Unseen"
	reason = "unseen"


func check(rules: Rules) -> Status:
	var crowd := rules.crowd()
	if is_instance_valid(crowd) and crowd.alarms.stage >= AlarmManager.Stage.LOCAL_EMERGENCY:
		return Status.FAILED
	return Status.PENDING
