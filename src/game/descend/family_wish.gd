class_name FamilyWish
extends Wish
## "Show yourself to my family" (v0.11 M1, spec §5.3, Sign): whisper three of the wisher's household -- the three lay citizens
## living nearest the wisher's home, within REACH of it, marked -- each once; the third granted. One dying before being shown
## fails it. The lists are untyped: a member may die and be freed while the wish still holds them.

## How many of the family must be shown, and how near the wisher's home they live.
const COUNT := 3
const REACH := 6.0
## The family's tag.
const LABEL := "FAMILY"

## The three to be shown, and those already whispered. Untyped: they may hold freed bodies.
var family := []
var shown := []


func choose(crowd: Crowd, _town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	_crowd = crowd
	var pool := Wish.lay(crowd, taken)
	if pool.is_empty():
		return false
	var start := rng.randi_range(0, pool.size() - 1)
	for k in pool.size():
		var w := pool[(start + k) % pool.size()]
		var near := _household(w, pool)
		if near.size() >= COUNT:
			wisher = w
			family = near.slice(0, COUNT)
			taken.append(wisher)
			taken.append_array(family)
			return true
	return false


## The lay citizens of `pool` but `w` living within REACH of `w`'s home, nearest first.
static func _household(w: Person, pool: Array[Person]) -> Array[Person]:
	var out: Array[Person] = []
	for p in pool:
		if p != w and p.profile.home.distance_to(w.profile.home) <= REACH:
			out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		return a.profile.home.distance_to(w.profile.home) < b.profile.home.distance_to(w.profile.home))
	return out


func people() -> Array[Person]:
	var out := super()
	for p: Variant in family:
		if p != null and is_instance_valid(p):
			out.append(p)
	return out


## Each member whispered counts once, shown.
func step(_rules: Rules, _delta: float) -> void:
	for p: Variant in family:
		if MissionDirector._alive(p) and (p as Person).mind == Person.Mind.WHISPERED and not shown.has(p):
			shown.append(p)


func _act(_rules: Rules) -> Status:
	if shown.size() >= COUNT:
		return Status.DONE
	for p: Variant in family:
		if not shown.has(p) and not MissionDirector._alive(p):
			return Status.FAILED
	return Status.PENDING


## "Show yourself to my family (+10) 1 / 3".
func hud_text(_rules: Rules) -> String:
	return "%s (+%d) %d / %d" % [def.text, reward, shown.size(), COUNT]


func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for p: Variant in family:
		if MissionDirector._alive(p) and not (p as Person).inside and not shown.has(p):
			out.append(MapTag.person((p as Person).ground_pos, COLOR, LABEL))
	return out
