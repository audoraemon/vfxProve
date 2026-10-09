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


## DONE once every target is dead, FAILED once one is safe, else PENDING (v0.11 M2). v0.11 M3: FAILED too for the director's own
## loss (lost_reason()), with its reason.
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
	var why := d.lost_reason()
	if why != "":
		reason = why
		return Status.FAILED
	return Status.PENDING


## "Kill the collectors: 1 / 3", "...: 1 / 3, he hides" (the current target flees or hides), "...: 1 / 3, he runs for the
## Citadel" (he flees with no hiding place, final review), "...: 1 / 3, rounds done" (he makes for the safe place); the label
## alone once all are dead or one is safe (v0.11 M2). The running text names the director's safe place (safe_label: "Citadel").
## v0.11 M3: the director's own HUD line (hud_line()) in place of all of it when it has one.
func hud_text(rules: Rules) -> String:
	var d := rules.director as AssassinateDirector
	if d == null or d.all_fallen() or d.any_safe() or d.quarries.is_empty():
		return label
	var line := d.hud_line()
	if line != "":
		return line
	var count := "%s: %d / %d" % [label, d.killed(), d.quarries.size()]
	var q := d.current()
	if q == null:
		return count
	if d.fleeing_to_safe(q):
		return "%s, he runs for the %s" % [count, d.safe_label.capitalize()]
	if q.state == AssassinateDirector.State.FLEEING or q.state == AssassinateDirector.State.HIDING:
		return "%s, he hides" % count
	if q.state != AssassinateDirector.State.WAITING and q.leg >= q.stops.size():
		return "%s, rounds done" % count
	return count
