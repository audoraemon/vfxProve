class_name BellSilentObjective
extends Objective
## The Warning's loss (v0.08): the bell rings and the town is warned. Nothing to show on the HUD's panel -- the bell's
## own climb bar and banners tell it.


func _init() -> void:
	label = "Keep the bell silent"
	reason = "bell"


func check(rules: Rules) -> Status:
	var crowd := rules.crowd()
	if is_instance_valid(crowd) and crowd.bell != null and crowd.bell.state == BellNetwork.State.RUNG:
		return Status.FAILED
	return Status.PENDING


func hud_text(_rules: Rules) -> String:
	return ""
