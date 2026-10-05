class_name JournalObjective
extends Objective
## Mira's House's bonus (v0.10): Cael's journal goes with the last Believer to finish reading it, and is saved when they
## are alive and out of the house at dawn.


func _init() -> void:
	label = "The journal"
	reason = "journal"


func check(rules: Rules) -> Status:
	var d := rules.director as MirasHouseDirector
	if d == null:
		return Status.PENDING
	var carrier := d.journal
	if carrier == null:
		return Status.FAILED if rules.time_left <= 0.0 else Status.PENDING
	if not (is_instance_valid(carrier) and carrier.is_alive()):
		return Status.FAILED
	if rules.time_left <= 0.0:
		return Status.DONE if not carrier.inside else Status.FAILED
	return Status.PENDING
