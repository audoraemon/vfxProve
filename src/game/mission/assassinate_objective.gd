class_name AssassinateObjective
extends Objective
## The Assassinate type's main objective (v0.11 M2, spec §7.1, every target by the controller's Task 2 ruling): DONE the moment
## the last target dies (reason `killed`: "collector" for The Tax Collector); FAILED when any reaches the safe place (reason
## `away`: "taxes"). AssassinateDirector judges both.

## The reasons for a win and a loss (v0.11 M2).
var _killed := ""
var _away := ""


## `text` is the HUD's label; `killed` and `away` the reasons for a win and a loss (v0.11 M2).
func _init(text := "Kill the targets", killed := "killed", away := "escaped") -> void:
	label = text
	_killed = killed
	_away = away
	reason = killed


## DONE once every target is dead, FAILED once one is safe, else PENDING (v0.11 M2).
func check(rules: Rules) -> Status:
	var d := rules.director as AssassinateDirector
	if d == null:
		return Status.PENDING
	if d.all_fallen():
		reason = _killed
		return Status.DONE
	if d.any_safe():
		reason = _away
		return Status.FAILED
	return Status.PENDING


## "Kill the collectors: 1 / 3", "...: 1 / 3, he hides" (the current target flees or hides), "...: 1 / 3, rounds done" (he
## makes for the safe place); the label alone once all are dead or one is safe (v0.11 M2).
func hud_text(rules: Rules) -> String:
	var d := rules.director as AssassinateDirector
	if d == null or d.all_fallen() or d.any_safe() or d.quarries.is_empty():
		return label
	var count := "%s: %d / %d" % [label, d.killed(), d.quarries.size()]
	var q := d.current()
	if q == null:
		return count
	if q.state == AssassinateDirector.State.FLEEING or q.state == AssassinateDirector.State.HIDING:
		return "%s, he hides" % count
	if q.state != AssassinateDirector.State.WAITING and q.leg >= q.stops.size():
		return "%s, rounds done" % count
	return count
