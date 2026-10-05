class_name ShrinesObjective
extends Objective
## Broken Lanterns (v0.10): every one of Halcyon's shrines drained wins the night ("drained").


func _init() -> void:
	label = "Shrines drained"
	reason = "drained"


func check(rules: Rules) -> Status:
	var d := rules.director as BrokenLanternsDirector
	if d == null or d.shrines.is_empty():
		return Status.PENDING
	return Status.DONE if d.drained_count() >= d.shrines.size() else Status.PENDING


func hud_text(rules: Rules) -> String:
	var d := rules.director as BrokenLanternsDirector
	return "Shrines drained %d / %d" % [d.drained_count() if d != null else 0, d.shrines.size() if d != null else 6]
