class_name QuietSuccessionObjective
extends Objective
## Act II-B's bonus (v0.09): the Prince dies unseen. Pending until his death is judged (ProcessionDirector), then lost if
## anyone living was near enough to see it.


func _init() -> void:
	label = "A quiet succession"
	reason = "quiet_succession"


func check(rules: Rules) -> Status:
	var director := rules.director as ProcessionDirector
	if director == null or not director.judged:
		return Status.PENDING
	return Status.PENDING if director.unseen else Status.FAILED
