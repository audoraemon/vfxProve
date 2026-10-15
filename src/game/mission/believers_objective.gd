class_name BelieversObjective
extends Objective
## Mira's House (v0.10): NEED Believers alive and out of the house win the night ("believers"); fewer at dawn lose it
## ("few"). Four, not the spec's starting five (Task 7: a scripted policy reached 3-7 Believers, most often 4).
## v0.11 M1 (no waiting, spec §7.3): won the moment the fourth Believer walks out, not at dawn.
## v0.11 M2: the number is the director's (MirasHouseDirector.need): NEED at Mira's House, three at First Prayers.
## v0.11 M5: its label and reasons are given (The Sermon's "Turn the crowd", "sermon", "sermon_over"), and it fails at once with the
## director's own loss (MirasHouseDirector.lost_reason(): The Sermon's "flock") when there is one.

const NEED := 4

## The reasons for a win, and for dawn with too few (v0.11 M5).
var _won := "believers"
var _few := "few"


func _init(text := "Believers", won := "believers", few := "few") -> void:
	label = text
	_won = won
	_few = few
	reason = won


func check(rules: Rules) -> Status:
	var d := rules.director as MirasHouseDirector
	if d == null:
		return Status.PENDING
	if d.believers_outside() >= d.need:
		reason = _won
		return Status.DONE
	var lost := d.lost_reason()
	if lost != "":
		reason = lost
		return Status.FAILED
	if rules.time_left > 0.0:
		return Status.PENDING
	reason = _few
	return Status.FAILED


## "Believers 3 / 4"; v0.11 M5: "<label> 3 / 8".
func hud_text(rules: Rules) -> String:
	var d := rules.director as MirasHouseDirector
	return "%s %d / %d" % [label, d.believers_outside() if d != null else 0, d.need if d != null else NEED]
