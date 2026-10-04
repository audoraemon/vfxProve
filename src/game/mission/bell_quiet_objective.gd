class_name BellQuietObjective
extends Objective
## Act II's bonus (v0.09): the bell does not ring during the act. A bell already rung when the act begins (Act I's alarm)
## does not count against it; one that rings after that -- even during the intro, before the first check -- fails it
## for good (a rung bell stays rung).

## Whether the bell had rung when the act began: -1 not yet looked, 0 silent, 1 rung.
var _rung_at_start := -1


func _init() -> void:
	label = "Before the bell"
	reason = "bell_quiet"


func begin(rules: Rules) -> void:
	_rung_at_start = 1 if _rung(rules) else 0


func check(rules: Rules) -> Status:
	var rung := _rung(rules)
	if _rung_at_start < 0:
		_rung_at_start = 1 if rung else 0
	return Status.FAILED if rung and _rung_at_start == 0 else Status.PENDING


static func _rung(rules: Rules) -> bool:
	var crowd := rules.crowd()
	return is_instance_valid(crowd) and crowd.bell != null and crowd.bell.state == BellNetwork.State.RUNG
