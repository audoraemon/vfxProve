class_name FestivalObjective
extends Objective
## Act II-A's win (v0.09): the festival is broken -- FESTIVAL_NEED of its goers dead or fled (FestivalDirector).


## `text` is the HUD's label and `why` the reason a win gives (v0.11 M3: Market Panic's "Scatter the fair", "fair"); the defaults
## are the Festival's.
func _init(text := "Break the festival", why := "festival") -> void:
	label = text
	reason = why


func check(rules: Rules) -> Status:
	var director := rules.director as FestivalDirector
	return Status.DONE if director != null and director.broken() else Status.PENDING


func hud_text(rules: Rules) -> String:
	var director := rules.director as FestivalDirector
	return label if director == null else "%s %d/%d" % [label, director.count(), director.need]
