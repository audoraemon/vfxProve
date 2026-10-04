class_name DawnObjective
extends Objective
## Act III's bonus (v0.09): the Citadel falls before the last half minute. Once under DAWN_LEFT seconds remain the
## bonus is lost for good: the clock only runs down.

## The seconds left under which dawn has come.
const DAWN_LEFT := 30.0


func _init() -> void:
	label = "Dawn never comes"
	reason = "dawn"


func check(rules: Rules) -> Status:
	return Status.FAILED if rules.time_left < DAWN_LEFT else Status.PENDING


func hud_text(_rules: Rules) -> String:
	return "Dawn never comes"
