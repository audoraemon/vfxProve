class_name GazeObjective
extends Objective
## Halcyon's Gaze full (v0.10): the Lantern looks, and the night is lost. Waits while the mission's director has no Gaze.


func _init() -> void:
	label = "Halcyon's Gaze"
	reason = "gaze"


func check(rules: Rules) -> Status:
	var g := _gaze(rules)
	return Status.FAILED if g != null and g.is_full() else Status.PENDING


func hud_text(rules: Rules) -> String:
	var g := _gaze(rules)
	return "" if g == null else "Halcyon's Gaze %d%%" % roundi(g.fraction() * 100.0)


static func _gaze(rules: Rules) -> GazeMeter:
	return rules.director.gaze if rules != null and rules.director != null else null
