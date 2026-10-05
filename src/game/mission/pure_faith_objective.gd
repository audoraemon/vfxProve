class_name PureFaithObjective
extends Objective
## Mira's House's bonus (v0.10): nobody dies tonight.


func _init() -> void:
	label = "Pure faith"
	reason = "pure"


func check(rules: Rules) -> Status:
	return Status.FAILED if rules.citizens_killed_this_act() + rules.soldiers_killed_this_act() > 0 else Status.PENDING
