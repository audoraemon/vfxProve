class_name RuinWish
extends Wish
## "Burn the moneylender's house", "Bring down the watchtower" (v0.11 M1, spec §5.3, Ruin): destroy the marked building, by
## any means. params: "role" -- "house" or "tower" (fits()) -- and "label", its tag's.

var target: Structure


func choose(crowd: Crowd, town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	var pool: Array[Structure] = []
	for s: Structure in town._built:
		if is_instance_valid(s) and not s.destroyed and not taken.has(s) and fits(s, String(def.params.get("role", ""))):
			pool.append(s)
	if pool.is_empty() or not super(crowd, town, rng, taken):
		return false
	target = pool[rng.randi_range(0, pool.size() - 1)]
	taken.append(target)
	return true


## A building of `role`: "house" a dwelling (a HOUSE-kind house with no art tag, or a townhouse: not a tavern, smithy,
## workshop or carpenter's), "tower" a tower of the walls (not the bell tower).
static func fits(s: Structure, role: String) -> bool:
	match role:
		"house":
			return s.role == &"house" and s.kind == Structure.Kind.HOUSE and s.art_tag in [&"", &"townhouse"]
		"tower":
			return s.role == &"tower" and s.art_tag != &"bell_tower"
	return false


## Its target building (v0.11 M2), set aside from the director's own choices.
func places() -> Array[Structure]:
	var out: Array[Structure] = []
	if is_instance_valid(target):
		out.append(target)
	return out


func _act(_rules: Rules) -> Status:
	return Status.DONE if is_instance_valid(target) and target.destroyed else Status.PENDING


## Its building's tag, pointed at from the screen's edge (v0.11 M3 final review: an off-screen wish house was pointed at by
## nothing), until it is down.
func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if is_instance_valid(target) and not target.destroyed:
		out.append(MapTag.place(target.center(), COLOR, String(def.params.get("label", "")), target.height, true))
	return out
