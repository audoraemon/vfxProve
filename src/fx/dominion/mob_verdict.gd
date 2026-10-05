class_name MobVerdictFx
extends FxTimeline
## Mob Verdict (Dominion, Tier IV): a district judges. Two clicks: the first the judged -- the person within PICK_R of
## it, else the building it is on or beside (CongregationFx.place_for()) -- the second the middle of the mob's circle
## (RADIUS). After T_CAST everyone in the circle, nearest first up to MAX_MOB and any role but the judged, turns on it
## for VERDICT_TIME:
##   a person    they go for it and strike until it falls (Person.fight(), TARGET_ONLY), each as what it is.
##   a building  they run to its walls, each to a spot of its own, and tear at it: every HIT_EVERY each one at the walls
##               deals MOB_DAMAGE, MAX_AT_WALLS of them at most (damage kind `mob`); when it comes down they are let go.
## They are not mad: they go for nothing else. Quiet when cast, but for the book entry's "alarm"; what the mob does is
## seen. The cast locks the other slots until it has landed.

const RADIUS := 7.0
const MAX_MOB := 60
const PICK_R := 1.0
const VERDICT_TIME := 25.0
const T_CAST := 1.2
const CIVIL_BLOW := 0.34
const HIT_EVERY := 1.0
const MOB_DAMAGE := 1.0
## At most this many can get at the walls at once.
const MAX_AT_WALLS := 25
## How near the walls, and how near its own spot there, one must be to tear at them.
const AT_WALLS := 1.8
const AT_SPOT := 0.5
const WILL := 0.8
const MARK := Color("ff7048")

## The judged: a person, or a building; and where.
var judged: Person
var building: Structure
var judged_at := Vector2.ZERO
var mob: Array[Person] = []

var _hit_in := HIT_EVERY


func _build() -> void:
	duration = T_CAST + VERDICT_TIME + 0.5
	busy = T_CAST + 0.5
	var near := DominionParts.near(ctx.field, origin, PICK_R, 1)
	if not near.is_empty():
		judged = near[0]
		judged_at = judged.ground_pos
	else:
		var place := CongregationFx.place_for(ctx.env, origin)
		building = place.structure
		judged_at = place.at
	at(T_CAST, _judge)
	ctx.play(&"hs_charge", origin, -6.0)
	if DominionParts.staged(self):
		var over: Variant = judged if judged != null else judged_at
		var brand := DominionParts.icon(self, over, DominionParts.BLADE, DominionParts.CRIMSON, T_CAST + VERDICT_TIME, 48.0)
		brand.px = 3
		DominionParts.ground_sigil(self, extra.get("to", origin), RADIUS, MARK, T_CAST, 1.0)
		DominionParts.pulse(self, judged_at, 2.0, DominionParts.CRIMSON, 0.8, T_CAST + 1.0)


func _judge() -> void:
	var center: Vector2 = extra.get("to", origin)
	var spots: Array[Vector2] = []
	var candidates := DominionParts.near(ctx.field, center, RADIUS, MAX_MOB + 1)
	candidates.erase(judged)
	candidates = candidates.slice(0, MAX_MOB)
	if building != null and is_instance_valid(building) and not candidates.is_empty():
		spots = CongregationFx.spots_for(candidates[0].grid, {"structure": building, "at": judged_at}, candidates.size())
	var links: DominionParts.Links = DominionParts.links(self) if DominionParts.staged(self) else null
	for i in candidates.size():
		var p := candidates[i]
		if judged != null:
			if not is_instance_valid(judged) or not judged.is_alive():
				break
			p.set_badge(DominionParts.BLADE, MARK, VERDICT_TIME)
			p.fight(judged, VERDICT_TIME, Person.SOLDIER_BLOW if p.soldier else CIVIL_BLOW, Person.FightRule.TARGET_ONLY)
		elif building != null:
			if i >= spots.size():
				break
			p.compel(spots[i], VERDICT_TIME, WILL, MARK, true, &"", DominionParts.BLADE)
		else:
			break
		mob.append(p)
		if links != null:
			links.add(p, Iso.ground_to_screen(judged_at) + Vector2(0, -40), MARK)
	if judged != null and is_instance_valid(judged):
		judged.set_badge(DominionParts.BLADE, DominionParts.CRIMSON, VERDICT_TIME)
	ctx.play(&"cit_shout", judged_at)
	ctx.play(&"hs_strike", judged_at, -8.0)
	if DominionParts.staged(self):
		ctx.shake.add_trauma(0.3)
		DominionParts.pulse(self, judged_at, 2.4, DominionParts.CRIMSON, 1.0, 1.0)


## How many of the mob stand at the building's walls.
func at_walls() -> int:
	var n := 0
	for p in mob:
		if is_instance_valid(p) and p.is_alive() and p.mind == Person.Mind.COMPELLED \
				and building.distance_to(p.ground_pos) <= AT_WALLS \
				and (not p.has_goal() or p.ground_pos.distance_to(p.goal()) <= AT_SPOT):
			n += 1  # there and standing: at its own spot by the walls, not passing by on the way
	return mini(n, MAX_AT_WALLS)


func _fx_process(delta: float) -> void:
	if building == null or t < T_CAST or mob.is_empty():
		return
	_hit_in -= delta
	if _hit_in > 0.0:
		return
	_hit_in = HIT_EVERY
	if not is_instance_valid(building) or building.destroyed:
		# It is down: the verdict is carried out.
		for p in mob:
			if is_instance_valid(p):
				p.release_compulsion()
		mob.clear()
		duration = minf(duration, t + 1.0)
		return
	var n := at_walls()
	if n > 0:
		building.damage(float(n) * MOB_DAMAGE, judged_at, &"mob")
		if DominionParts.staged(self) and is_instance_valid(building):
			building.shake(0.5)
			FxParts.smoke(self, Iso.ground_to_screen(judged_at), 12.0, 14.0, 0.4, Vector2(10, 30), Vector2(2, 4), Vector2(0.5, 0.9),
				Color(0, 0, 0, 0), FxParts.DUST_LIFE)
