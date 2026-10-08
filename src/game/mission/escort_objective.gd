class_name EscortObjective
extends Objective
## The Escort type's main objective (v0.11 M2, spec §7.1): DONE the moment the charge is out (reason `out`); FAILED when he
## is taken back (`taken`) or dies (`dead`). EscortDirector judges each.

## The reasons a win, a taking back and a death give (v0.11 M2).
var _out := ""
var _taken := ""
var _dead := ""


## The label, and the reasons for each ending (v0.11 M2).
func _init(text := "Lead him out", out := "out", taken := "taken", dead := "dead") -> void:
	label = text
	_out = out
	_taken = taken
	_dead = dead
	reason = out


## DONE the moment he is out; FAILED when he is taken back or dies (v0.11 M2), judged by EscortDirector.
func check(rules: Rules) -> Status:
	var d := rules.director as EscortDirector
	if d == null:
		return Status.PENDING
	if d.escaped:
		reason = _out
		return Status.DONE
	if d.taken:
		reason = _taken
		return Status.FAILED
	if d.charge_lost():
		reason = _dead
		return Status.FAILED
	return Status.PENDING


## The label (v0.11 M2), or "...: caught" while he is held.
func hud_text(rules: Rules) -> String:
	var d := rules.director as EscortDirector
	return "%s: caught" % label if d != null and d.held else label
