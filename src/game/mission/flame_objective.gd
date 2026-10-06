class_name FlameObjective
extends Objective
## The Vigil Flame (v0.10): Halcyon's flame at Mira's shrine wins the night ("flame"); the bearer home at the Temple with
## the real flame ("kept"), or Wren dead or never come ("wren"), loses it. Its line tells the player where the flame is.


func _init() -> void:
	label = "The flame"
	reason = "flame"


func check(rules: Rules) -> Status:
	var d := rules.director as VigilFlameDirector
	if d == null:
		return Status.PENDING
	if d.home:
		reason = "flame"
		return Status.DONE
	if d.kept:
		reason = "kept"
		return Status.FAILED
	if d.wren_lost():
		reason = "wren"
		return Status.FAILED
	return Status.PENDING


func hud_text(rules: Rules) -> String:
	var d := rules.director as VigilFlameDirector
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
