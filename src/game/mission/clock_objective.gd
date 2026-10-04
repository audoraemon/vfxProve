class_name ClockObjective
extends Objective
## The manifestation's clock (v0.08): at 0:00 it fails the mission (Last Judgement), or -- `succeeds` -- wins it (The
## Warning: the omen fades with the bell still silent).

var succeeds := false


func _init(succeed := false, text := "", why := "timeout") -> void:
	succeeds = succeed
	label = text
	reason = why


func check(rules: Rules) -> Status:
	if rules.time_left > 0.0:
		return Status.PENDING
	return Status.DONE if succeeds else Status.FAILED


func hud_text(rules: Rules) -> String:
	return "" if label == "" else "%s %s" % [label, UiTheme.clock(rules.time_left)]
