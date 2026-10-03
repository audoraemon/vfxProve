class_name WarningObjective
extends Objective
## The Warning's win (v0.08): whoever carries the warning is dead, and nobody living saw it (WarningDirector).


func _init() -> void:
	label = "Stop the warning"
	reason = "warning"


func check(rules: Rules) -> Status:
	var director := rules.director as WarningDirector
	return Status.DONE if director != null and director.warning_dead else Status.PENDING
