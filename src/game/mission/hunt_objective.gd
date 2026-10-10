class_name HuntObjective
extends Objective
## The Hunt type's main objective (v0.11 M4, mission spec §3.1): DONE the moment every standard is broken and the head is down
## (reason `done`: The Heretic Hunt's "hunt"); FAILED the moment the hunt finds its quarry (HuntDirector.lost_reason(): "cellar"). It
## takes its label and its win reason in _init(), as every M2/M3 generic objective (M2 ruling 61).

## The reason a win gives (v0.11 M4).
var _done := ""


## The label, and the win's reason (v0.11 M4).
func _init(text := "Break the hunt", done := "hunt") -> void:
	label = text
	_done = done
	reason = done


## DONE once every standard is broken and the head is down; FAILED once the hunt finds its quarry (v0.11 M4).
func check(rules: Rules) -> Status:
	var d := rules.director as HuntDirector
	if d == null:
		return Status.PENDING
	if d.broken_all() and d.head_down():
		reason = _done
		return Status.DONE
	var lost := d.lost_reason()
	if lost != "":
		reason = lost
		return Status.FAILED
	return Status.PENDING


## "Break the hunt: standards 1 / 3", and ", kill the captain" once he is out and alive (v0.11 M4, decision 112).
func hud_text(rules: Rules) -> String:
	var d := rules.director as HuntDirector
	if d == null:
		return label
	var text := "%s: %s %d / %d" % [label, d.count_word, d.broken_count(), d.steps.size()]
	if d.has_head and d.head_out and not d.head_down():
		text += ", " + d.head_word
	return text
