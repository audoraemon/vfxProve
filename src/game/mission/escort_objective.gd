class_name EscortObjective
extends Objective
## The Escort type's main objective (v0.11 M2, spec §7.1): DONE the moment the charge is out (reason `out`); FAILED when he
## is taken back (`taken`) or dies (`dead`). EscortDirector judges each. Those are the defaults: a mission passes its own
## reasons (The Lost Lamb's are `lamb_out`, `lamb_taken` and `lamb`), as the results' titles are keyed by reason and the
## defaults have none.
## v0.11 M6 (mission spec §6.1): `need` -- with 1 (the default) today's checks; with more, DONE once that many are out
## (EscortDirector.out_count()) and FAILED only through the director's lost_reason(), so a single seizure never ends a many-charge night.

## The reasons a win, a taking back and a death give (v0.11 M2).
var _out := ""
var _taken := ""
var _dead := ""
## How many charges must get out (v0.11 M6): 1 by default.
var need := 1


## The label, the reasons for each ending, and how many must get out (v0.11 M2; v0.11 M6 `p_need`).
func _init(text := "Lead him out", out := "out", taken := "taken", dead := "dead", p_need := 1) -> void:
	label = text
	_out = out
	_taken = taken
	_dead = dead
	need = p_need
	reason = out


## DONE the moment he is out; FAILED when he is taken back or dies (v0.11 M2), judged by EscortDirector.
func check(rules: Rules) -> Status:
	var d := rules.director as EscortDirector
	if d == null:
		return Status.PENDING
	if need > 1:
		# v0.11 M6: many charges -- done at `need` out, failed only by the director's own loss (Exodus's count and its gates).
		if d.out_count() >= need:
			reason = _out
			return Status.DONE
		var why := d.lost_reason()
		if why != "":
			reason = why
			return Status.FAILED
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
	var lost := d.lost_reason()  # v0.11 M4: the director's own loss (The Prisoner's "prisoner_inside")
	if lost != "":
		reason = lost
		return Status.FAILED
	return Status.PENDING


## The label (v0.11 M2), or "...: caught" while he is held. v0.11 M4: the director's HUD line in its place when it has one.
func hud_text(rules: Rules) -> String:
	var d := rules.director as EscortDirector
	if d != null and d.hud_line() != "":
		return d.hud_line()
	return "%s: caught" % label if d != null and d.held else label
