class_name ThroughFaithfulObjective
extends Objective
## Broken Lanterns' bonus (v0.10): the last shrine breaks with at least NEED of its kneelers still within
## BrokenLanternsDirector.BONUS_REACH of it. They are counted the step before the blow, so a strike through them still
## counts them.

const NEED := 10


func _init() -> void:
	label = "Through the faithful"
	reason = "faithful"


func check(rules: Rules) -> Status:
	var d := rules.director as BrokenLanternsDirector
	if d == null or d.drained_count() < d.shrines.size():
		return Status.PENDING
	return Status.DONE if d.last_kneelers >= NEED else Status.FAILED
