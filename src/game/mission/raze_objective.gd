class_name RazeObjective
extends Objective
## The Raze type's main objective (v0.11 M2, spec §7.1): DONE the moment every target is razed (reason `razed`: "spoiled"
## for Spoiled Harvest); FAILED the moment the director says the night is lost (RazeDirector.lost_reason(): "emptied").

## The reason a win gives (v0.11 M2).
var _razed := ""


func _init(text := "Raze the targets", razed := "razed") -> void:
	label = text
	_razed = razed
	reason = razed


## DONE once every target is razed; FAILED the moment the director says the night is lost (v0.11 M2).
func check(rules: Rules) -> Status:
	var d := rules.director as RazeDirector
	if d == null:
		return Status.PENDING
	if d.all_razed():
		reason = _razed
		return Status.DONE
	var lost := d.lost_reason()
	if lost != "":
		reason = lost
		return Status.FAILED
	return Status.PENDING


## "Granaries spoiled 1 / 3" (v0.11 M2); v0.11 M5: the director's own line (RazeDirector.hud_line()) in its place when it has one.
func hud_text(rules: Rules) -> String:
	var d := rules.director as RazeDirector
	var line := d.hud_line() if d != null else ""
	if line != "":
		return line
	return "%s %d / %d" % [label, d.razed_count() if d != null else 0, d.targets.size() if d != null else 0]
