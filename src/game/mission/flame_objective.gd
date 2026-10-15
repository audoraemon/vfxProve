class_name FlameObjective
extends Objective
## The Vigil Flame (v0.10): Halcyon's flame at Mira's shrine wins the night ("flame"); the bearer home at the Temple with
## the real flame ("kept"), or Wren dead or never come ("wren"), loses it. Its line tells the player where the flame is.
## v0.11 M5: its label and reasons are given (The Relic Run's "The relic", "relic", "relic_kept", "pip"), and the director's own HUD line
## (VigilFlameDirector.hud_line()) shows in place of its own when there is one.

## The reasons for the win, for the flame (or relic) kept, and for the boy lost (v0.11 M5).
var _won := "flame"
var _kept := "kept"
var _lost := "wren"


func _init(text := "The flame", won := "flame", kept := "kept", lost := "wren") -> void:
	label = text
	_won = won
	_kept = kept
	_lost = lost
	reason = won


func check(rules: Rules) -> Status:
	var d := rules.director as VigilFlameDirector
	if d == null:
		return Status.PENDING
	if d.home:
		reason = _won
		return Status.DONE
	if d.kept:
		reason = _kept
		return Status.FAILED
	if d.wren_lost():
		reason = _lost
		return Status.FAILED
	return Status.PENDING


func hud_text(rules: Rules) -> String:
	var d := rules.director as VigilFlameDirector
	var line := d.hud_line() if d != null else ""
	if line != "":
		return line
	if d == null or not d.appeared:
		return "The flame: in its lantern"
	if d.home:
		return "The flame: home"
	if d.swapped:
		var at := d.flame_at()
		return "The flame to Mira's shrine: %d" % roundi(at.distance_to(d.shrine)) if at != Vector2.INF else "The flame: lost"
	if d.swapping:
		return "Swapping %d / %d s" % [ceili(VigilFlameDirector.SWAP_SECONDS - d.swap_left), roundi(VigilFlameDirector.SWAP_SECONDS)]
	return "The flame: swap it"
