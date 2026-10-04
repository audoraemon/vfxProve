class_name FestivalObjective
extends Objective
## Act II-A's win (v0.09): the festival is broken -- FESTIVAL_NEED of its goers dead or fled (FestivalDirector).


func _init() -> void:
	label = "Break the festival"
	reason = "festival"


func check(rules: Rules) -> Status:
	var director := rules.director as FestivalDirector
	return Status.DONE if director != null and director.broken() else Status.PENDING


func hud_text(rules: Rules) -> String:
	var director := rules.director as FestivalDirector
	return label if director == null else "%s %d/%d" % [label, director.count(), director.need]
