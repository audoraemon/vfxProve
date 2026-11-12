class_name RiteFlameObjective
extends Objective
## The rite's second objective (god P3, MS §1 "Objectives", plan P3-10): "The shrine's flame" is lost -- reason `cleansed` -- the moment the
## director's clergy have cleansed Mira's shrine (RiteDirector.flame_out). It never reports DONE: the shards are the win. It sits between the shards and
## Dawn in the list, so a last shard and a full cleanse in the same frame is a win (the winning strike never also loses, MS §6).


func _init() -> void:
	label = "The shrine's flame"
	reason = "cleansed"


func check(rules: Rules) -> Status:
	var d := rules.director as RiteDirector
	if d != null and d.flame_out:
		return Status.FAILED
	return Status.PENDING


func hud_text(rules: Rules) -> String:
	var d := rules.director as RiteDirector
	if d != null and d.flame_out:
		return "The shrine's flame: out"
	return label
