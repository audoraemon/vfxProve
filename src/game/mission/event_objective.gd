class_name EventObjective
extends Objective
## A deadline set by the director's timeline (v0.11 M1, spec §7.2): FAILED once the event `event_id` has come -- the board's
## Festival, its square closing at 4:30 with dawn at 6:00. A deadline is on the main objective alone (Objective.deadline).

var event_id := ""


func _init(id := "", text := "", why := "") -> void:
	event_id = id
	label = text
	reason = why
	deadline = true


func check(rules: Rules) -> Status:
	var tl := _timeline(rules)
	return Status.FAILED if tl != null and tl.has_come(event_id) else Status.PENDING


## "Square closes 3:12": the real seconds until the event, as the clock reads them; "" with no label or no timeline.
func hud_text(rules: Rules) -> String:
	var tl := _timeline(rules)
	if label == "" or tl == null:
		return ""
	return "%s %s" % [label, UiTheme.clock(tl.seconds_to(event_id))]


static func _timeline(rules: Rules) -> EventTimeline:
	return rules.director.timeline if rules != null and rules.director != null else null
