class_name PrinceObjective
extends Objective
## Act II-B's win (v0.09): the Prince is dead and his death judged, seen or not (ProcessionDirector). It is lost -- reason
## "sailed" -- if he gets away: boards the ship, or leaves the town any other way.


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
	if director.fallen() and director.judged:
		reason = "prince"
		return Status.DONE
	return Status.PENDING
