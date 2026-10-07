class_name StarsObjective
extends Objective
## The board's Warning (v0.11 M1, spec §7.2): every one of its three warnings stopped (StarfallDirector).


func _init() -> void:
	label = "Stop the warnings"
	reason = "warning"


func check(rules: Rules) -> Status:
	var d := rules.director as StarfallDirector
	return Status.DONE if d != null and not d.stars.is_empty() and d.stopped() >= d.stars.size() else Status.PENDING


func hud_text(rules: Rules) -> String:
	var d := rules.director as StarfallDirector
	return "Warnings stopped %d / %d" % [d.stopped() if d != null else 0, StarfallDirector.STARS.size()]
