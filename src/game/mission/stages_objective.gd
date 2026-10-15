class_name StagesObjective
extends Objective
## A night of stages' main objective (v0.11 M6, mission spec §6.5; generic, M2 ruling 61): DONE the moment its director's stages are
## done (MissionDirector.stages_done(): The Heart of Faith's flame out and its High Priest dead), with the win's reason; FAILED with the
## director's own loss (MissionDirector.lost_reason(): The Heart's "blessed" and "kindled") when it has one. Its HUD row is the
## director's line (MissionDirector.hud_line()), else its label.

## The reason a win gives (v0.11 M6).
var _done := ""


## The label, and the win's reason (v0.11 M6).
func _init(text := "Finish the night", done := "stages") -> void:
	label = text
	_done = done
	reason = done


## DONE once the director's stages are done; FAILED once it names a loss (v0.11 M6).
func check(rules: Rules) -> Status:
	var d: MissionDirector = rules.director if rules != null else null
	if d == null:
		return Status.PENDING
	if d.stages_done():
		reason = _done
		return Status.DONE
	var lost := d.lost_reason()
	if lost != "":
		reason = lost
		return Status.FAILED
	return Status.PENDING


## The director's line, else the label (v0.11 M6).
func hud_text(rules: Rules) -> String:
	var d: MissionDirector = rules.director if rules != null else null
	var line := d.hud_line() if d != null else ""
	return line if line != "" else label
