class_name MissionKeeps
extends RefCounted
## Mission buildings, one rule (Death second review, R45 as amended; the user's "a Death night is never lost to a hidden side
## effect"): what a power's side effects -- Grave Tide's claws and slams (Visitors trait `spare`) -- ask before they wreck a
## building. It changes nothing but Crowd.structure_mark()'s lazy erasing of a lapsed mark.


## Whether `s` is spared tonight. Never one the night's goal wants down (`director.wants_down()`: Raze's targets, the granaries,
## Broken Lanterns' shrines, the Bishop's refuges, the stocks, Last Judgement's Citadel -- a fall there is the god's work, not a
## loss), however hallowed or filtered. Otherwise spared: the Citadel and the Temple (by role), a building hallowed now
## (Crowd.structure_mark()), one with a damage filter (the Citadel's budget, a director's stone or refuge), one the night has
## set aside (`reserved_places`), and one its director needs standing (`needs_standing()`). A null director: the generic rules only.
static func spared(s: Structure, crowd: Crowd, director: MissionDirector) -> bool:
	if s == null or not is_instance_valid(s):
		return false
	if director != null and director.wants_down(s):
		return false
	if s.role == &"citadel" or s.role == &"temple":
		return true
	if crowd != null and crowd.structure_mark(s) == AnathemaFx.HALLOWED:
		return true
	if s.damage_filter.is_valid():
		return true
	if director == null:
		return false
	return director.reserved_places.has(s) or director.needs_standing(s)
