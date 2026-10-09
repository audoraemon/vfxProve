class_name NeighboursWish
extends Wish
## "Let my neighbours believe" (v0.11 M2, mission spec §5, Faith): whisper three of the wisher's neighbours -- the three lay
## citizens living nearest the wisher's home within REACH, not of the household, marked -- to within NEAR of the wisher; each
## so brought believes (CitizenProfile.Faith.BELIEVER), and the third grants it. One dying before believing fails it. The lists
## are untyped: a neighbour may die and be freed while the wish still holds them.

## How many must believe (v0.11 M2).
const COUNT := 3
## How near the wisher's home a neighbour lives (v0.11 M2).
const REACH := 8.0
## How near the wisher a whisper must bring a neighbour (v0.11 M2).
const NEAR := 2.0
## The neighbours' tag (v0.11 M2).
const LABEL := "NEIGHBOUR"

## The three to be brought. Untyped: they may hold freed bodies (v0.11 M2).
var neighbours := []
## Those who believe, in the order they came. Untyped, as `neighbours` is (v0.11 M2).
var believing := []


## A lay wisher with a home and COUNT neighbours; false when no one in the town has them (v0.11 M2). Wishers are tried from a
## random start.
func choose(crowd: Crowd, _town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	_crowd = crowd
	var pool := Wish.lay(crowd, taken)
	if pool.is_empty():
		return false
	var start := rng.randi_range(0, pool.size() - 1)
	for k in pool.size():
		var w := pool[(start + k) % pool.size()]
		if w.profile.home == Vector2.INF:
			continue
		var near := _neighbours_of(w, pool, crowd._grid)
		if near.size() >= COUNT:
			wisher = w
			neighbours = near.slice(0, COUNT)
			taken.append(wisher)
			taken.append_array(neighbours)
			return true
	return false


## The lay citizens of `pool` but `w` living within REACH of `w`'s home and not of `w`'s household, nearest first. With a
## `grid`, one with no route to `w` where each stands (shut in a courtyard by the buildings round it: a whisper could never
## lead them out) is left out.
static func _neighbours_of(w: Person, pool: Array[Person], grid: WalkGrid) -> Array[Person]:
	var out: Array[Person] = []
	for p in pool:
		if p == w or p.profile.home == Vector2.INF or p.profile.home.distance_to(w.profile.home) > REACH:
			continue
		if w.profile.family >= 0 and p.profile.family == w.profile.family:
			continue
		if grid != null and grid.path(w.ground_pos, p.ground_pos).is_empty():
			continue
		out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		return a.profile.home.distance_to(w.profile.home) < b.profile.home.distance_to(w.profile.home))
	return out


## The wisher and the neighbours whose bodies are still there (v0.11 M2).
func people() -> Array[Person]:
	var out := super()
	for p: Variant in neighbours:
		if p != null and is_instance_valid(p):
			out.append(p)
	return out


## Each neighbour whispered to within NEAR of the living wisher believes, once.
func step(_rules: Rules, _delta: float) -> void:
	if not MissionDirector._alive(wisher) or wisher.inside:
		return
	for p: Variant in neighbours:
		if MissionDirector._alive(p) and not believing.has(p) and (p as Person).mind == Person.Mind.WHISPERED \
				and (p as Person).ground_pos.distance_to(wisher.ground_pos) <= NEAR:
			believing.append(p)
			(p as Person).profile.faith = CitizenProfile.Faith.BELIEVER


## Granted at COUNT believers; failed when a neighbour is gone before he believed (v0.11 M2).
func _act(_rules: Rules) -> Status:
	if believing.size() >= COUNT:
		return Status.DONE
	for p: Variant in neighbours:
		if not believing.has(p) and not MissionDirector._alive(p):
			return Status.FAILED
	return Status.PENDING


## "Let my neighbours believe (+10) 1 / 3".
func hud_text(_rules: Rules) -> String:
	return "%s (+%d) %d / %d" % [def.text, reward, believing.size(), COUNT]


## NEIGHBOUR on each who has yet to believe (v0.11 M2).
func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for p: Variant in neighbours:
		if MissionDirector._alive(p) and not (p as Person).inside and not believing.has(p):
			out.append(MapTag.person((p as Person).ground_pos, COLOR, LABEL))
	return out
