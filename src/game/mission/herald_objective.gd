class_name HeraldObjective
extends Objective
## "Stop the Herald" (v0.11.2, spec 4.6 and 4.10): the loss on a Herald night. The bell tolled and its ringer (or a warning's messenger)
## runs for the Temple; once one has reached the door the Lantern has heard (LanternWatch.heard) and the night is lost, reason `lantern`.
## It follows the night's main objective in the list; the main one (Warning, Stars) is not DONE while a Herald runs or has been heard
## (WarningObjective, StarsObjective), so a Herald who gets in can never be read as a win first. It replaces BellSilentObjective, which
## lost the night outright on the toll.


func _init() -> void:
	label = "Stop the Herald"
	reason = "lantern"


func check(rules: Rules) -> Status:
	return Status.FAILED if rules.lantern != null and rules.lantern.heard else Status.PENDING


## Shown only while a Herald runs (the HUD's panel has nothing to say before the toll).
func hud_text(rules: Rules) -> String:
	return label if rules.lantern != null and rules.lantern.herald_running() else ""
