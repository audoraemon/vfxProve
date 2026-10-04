class_name PrinceObjective
extends Objective
## Act II-B's win (v0.09): the Prince is dead (ProcessionDirector). It is lost -- reason "sailed" -- if he boards the ship.


func _init() -> void:
	label = "Stop the Prince"
	reason = "prince"


func check(rules: Rules) -> Status:
	var director := rules.director as ProcessionDirector
	if director == null:
		return Status.PENDING
	if director.boarded:
		reason = "sailed"
		return Status.FAILED
	if director.fallen():
		reason = "prince"
		return Status.DONE
	return Status.PENDING
