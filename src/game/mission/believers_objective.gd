class_name BelieversObjective
extends Objective
## Mira's House (v0.10): at dawn, NEED Believers alive and out of the house win the night ("believers"); fewer lose it
## ("few").

const NEED := 5


func _init() -> void:
	label = "Believers"
	reason = "believers"


func check(rules: Rules) -> Status:
	var d := rules.director as MirasHouseDirector
	if d == null or rules.time_left > 0.0:
		return Status.PENDING
	if d.believers_outside() >= NEED:
		reason = "believers"
		return Status.DONE
	reason = "few"
	return Status.FAILED


func hud_text(rules: Rules) -> String:
	var d := rules.director as MirasHouseDirector
	return "Believers %d / %d" % [d.believers_outside() if d != null else 0, NEED]
