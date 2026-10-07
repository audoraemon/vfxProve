class_name BelieversObjective
extends Objective
## Mira's House (v0.10): NEED Believers alive and out of the house win the night ("believers"); fewer at dawn lose it
## ("few"). Four, not the spec's starting five (Task 7: a scripted policy reached 3-7 Believers, most often 4).
## v0.11 M1 (no waiting, spec §7.3): won the moment the fourth Believer walks out, not at dawn.

const NEED := 4


func _init() -> void:
	label = "Believers"
	reason = "believers"


func check(rules: Rules) -> Status:
	var d := rules.director as MirasHouseDirector
	if d == null:
		return Status.PENDING
	if d.believers_outside() >= NEED:
		reason = "believers"
		return Status.DONE
	if rules.time_left > 0.0:
		return Status.PENDING
	reason = "few"
	return Status.FAILED


func hud_text(rules: Rules) -> String:
	var d := rules.director as MirasHouseDirector
	return "Believers %d / %d" % [d.believers_outside() if d != null else 0, NEED]
