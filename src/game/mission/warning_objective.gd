class_name WarningObjective
extends Objective
## The Warning's win (v0.08): whoever carries the warning is dead, and nobody living saw it (WarningDirector).


func _init() -> void:
	label = "Stop the warning"
	reason = "warning"


func check(rules: Rules) -> Status:
	if rules.lantern != null and rules.lantern.blocks_win():
		return Status.PENDING  # v0.11.2: a Herald still runs, or got in -- HeraldObjective loses it, never this one first
	var director := rules.director as WarningDirector
	return Status.DONE if director != null and director.warning_dead else Status.PENDING
