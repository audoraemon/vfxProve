class_name NeighboursWish
extends Wish
## "Let my neighbours believe" (v0.11 M2, mission spec §5, Faith): whisper three of the wisher's neighbours -- the three lay
## citizens living nearest the wisher's home within REACH, not of the household, marked -- to within NEAR of the wisher; each
## so brought believes (CitizenProfile.Faith.BELIEVER), and the third grants it. One dying before believing fails it. The lists
## are untyped: a neighbour may die and be freed while the wish still holds them.
## v0.11 M6: params "count" (COUNT by default), "clergy" -- the one brought is a cleric out of doors whose street walk to the wisher is at
## most "route" units, the nearest so ("Turn the doubting priest") -- "label" (LABEL) and "edge" (false). The defaults keep Let my
## neighbours believe exact.

## How many must believe (v0.11 M2).
const COUNT := 3
## How near the wisher's home a neighbour lives (v0.11 M2).
const REACH := 8.0
## How near the wisher a whisper must bring a neighbour (v0.11 M2).
const NEAR := 2.0
## The neighbours' tag (v0.11 M2).
const LABEL := "NEIGHBOUR"
## How much shorter than the straight distance a street walk can measure (v0.11 M6's final review): the walk grid's path runs between
## cell centres, each end up to a cell off the person, so _priest_for() skips a cleric whose straight distance is beyond the route, or
## no nearer than the best walk so far, by more than this -- never one the walk itself would have taken.
const WALK_SLACK := 2.0

## The three to be brought. Untyped: they may hold freed bodies (v0.11 M2).
var neighbours := []
## Those who believe, in the order they came. Untyped, as `neighbours` is (v0.11 M2).
var believing := []


## A lay wisher with a home and _count() neighbours -- or, with "clergy", a cleric within "route" of street (v0.11 M6) -- false when no
## one in the town has them (v0.11 M2). Wishers are tried from a random start.
func choose(crowd: Crowd, _town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	_crowd = crowd
	var pool := Wish.lay(crowd, taken)
	if pool.is_empty():
		return false
	var start := rng.randi_range(0, pool.size() - 1)
	var clergy := bool(def.params.get("clergy", false))
	for k in pool.size():
		var w := pool[(start + k) % pool.size()]
		if clergy:
			var priest := _priest_for(w, crowd, taken)
			if priest == null:
				continue
			wisher = w
			neighbours = [priest]
			taken.append(wisher)
			taken.append(priest)
			return true
		if w.profile.home == Vector2.INF:
			continue
		var near := _neighbours_of(w, pool, crowd._grid)
		if near.size() >= _count():
			wisher = w
			neighbours = near.slice(0, _count())
			taken.append(wisher)
			taken.append_array(neighbours)
			return true
	return false


## How many must believe (v0.11 M6): the "count" param, COUNT by default.
func _count() -> int:
	return int(def.params.get("count", COUNT)) if def != null else COUNT


## The tag on each who has yet to believe (v0.11 M6): the "label" param, LABEL by default.
func _label() -> String:
	return String(def.params.get("label", LABEL)) if def != null else LABEL


## The cleric for wisher `w` (v0.11 M6): living, out of doors, none of `taken`, whose street walk to `w` is the shortest and at most the
## "route" param; null for none. With no walk grid, the straight distance. One whose straight distance alone rules him out is skipped
## before his walk is measured (WALK_SLACK).
func _priest_for(w: Person, crowd: Crowd, taken: Array) -> Person:
	var reach := float(def.params.get("route", 0.0))
	var best: Person = null
	var best_walk := INF
	for v: Variant in crowd.citizens:
		if not MissionDirector._alive(v) or v == w:
			continue
		var p := v as Person
		if p.inside or p.profile == null or p.profile.role != CitizenProfile.Role.CLERGY or taken.has(p):
			continue
		var walk := p.ground_pos.distance_to(w.ground_pos)
		if (reach > 0.0 and walk - WALK_SLACK > reach) or walk - WALK_SLACK >= best_walk:
			continue  # the straight distance prefilter: no street walk is that much shorter (the final review)
		if crowd._grid != null:
			var path := crowd._grid.path(p.ground_pos, w.ground_pos)
			if path.is_empty():
				continue
			walk = 0.0
			for k in range(path.size() - 1):
				walk += path[k].distance_to(path[k + 1])
		if (reach <= 0.0 or walk <= reach) and walk < best_walk:
			best = p
			best_walk = walk
	return best


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
	if believing.size() >= _count():
		return Status.DONE
	for p: Variant in neighbours:
		if not believing.has(p) and not MissionDirector._alive(p):
			return Status.FAILED
	return Status.PENDING


## "Let my neighbours believe (+10) 1 / 3".
func hud_text(_rules: Rules) -> String:
	return "%s (+%d) %d / %d" % [def.text, reward, believing.size(), _count()]


## The label on each who has yet to believe (v0.11 M2: NEIGHBOUR; v0.11 M6: _label(), pointed at from the edge with "edge").
func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for p: Variant in neighbours:
		if MissionDirector._alive(p) and not (p as Person).inside and not believing.has(p):
			out.append(MapTag.person((p as Person).ground_pos, COLOR, _label(), bool(def.params.get("edge", false))))
	return out
