class_name EscortManager
extends RefCounted
## Escorts (v0.07): the patrol soldiers guard the town's responders while they are on duty -- the bellkeeper while the
## bell is called, climbed or waited for, the clergy while their rite gathers, chants or cools down, each engineer
## team while the engineers are out -- the profile's escorts_per_duty each, keeping within REACH. Near a guarded
## responder Silent Doom is seen (Crowd counts any living witness, soldiers too); a guarded responder confused near its
## escort comes to within STEADY_TIME; a bellkeeper killed before the bell rang is replaced by an escort
## (bell_stand_in(); BellNetwork climbs it slower), an engineer by one of its team's (engineer_stand_in()). When a duty
## ends its escorts go back to their posts.

## How near its charge an escort keeps (the point it stands round is re-set when its place is farther than this).
const REACH := 1.5
## How near a guarded responder an escort must be to steady it.
const STEADY_R := 2.0
## The longest a steadied responder stays confused.
const STEADY_TIME := 3.0
## How often the duties are looked at.
const EVERY := 0.5
## Where the escorts stand round what they guard.
const OFFSETS := [Vector2(0.8, 0.5), Vector2(-0.8, 0.5), Vector2(0.5, -0.8), Vector2(-0.5, -0.8)]

## A duty's key ("bell", "rite", "team:<id>") -> its escorts.
var guards := {}
var _crowd: Crowd
var _in := 0.0


func setup(crowd: Crowd) -> EscortManager:
	_crowd = crowd
	return self


## The duties now: key -> {"point": where to stand round, "guarded": the responders}.
func _duties() -> Dictionary:
	var out := {}
	var bell := _crowd.bell
	if bell != null and bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING, BellNetwork.State.WAITING]:
		# Kept while the keeper lies dead too: the bell looks for a stand-in on its next step (it may come after this
		# one, in the same frame as the death), and must find the escorts still on the duty.
		var alive := is_instance_valid(bell.keeper) and bell.keeper.is_alive()
		out["bell"] = {"point": bell.keeper.ground_pos if alive else bell.foot, "guarded": [bell.keeper] if alive else []}
	var rite := _crowd.rite
	if rite != null and rite.state in [BanishingRite.State.GATHERING, BanishingRite.State.CHANTING,
			BanishingRite.State.COOLDOWN]:
		var clergy: Array = []
		for e in rite.circle:
			if is_instance_valid(e[0]):
				clergy.append(e[0])
		out["rite"] = {"point": rite.centre, "guarded": clergy}
	var eng := _crowd.engineers
	if eng != null and eng.active:
		for team: Dictionary in eng.teams:
			var lead: Person = null
			for p in team.members:
				if is_instance_valid(p) and (p as Person).is_alive():
					lead = p
					break
			if lead != null:
				out["team:%d" % int(team.id)] = {"point": lead.ground_pos, "guarded": team.members}
	return out


func step(delta: float) -> void:
	_in -= delta
	if _in > 0.0:
		return
	_in = EVERY
	var duties := _duties()
	for key in guards.keys():
		if not duties.has(key):
			_release(guards[key])
			guards.erase(key)
	var per := _crowd.profile.escorts_per_duty
	for key in duties:
		var d: Dictionary = duties[key]
		var mine: Array = []
		for p in guards.get(key, []):
			if is_instance_valid(p) and (p as Person).is_alive():
				mine.append(p)
		guards[key] = mine  # (before the picking: _free_nearest() leaves out those already guarding)
		while mine.size() < per:
			var free := _free_nearest(d.point)
			if free == null:
				break
			mine.append(free)
		var point: Vector2 = d.point
		for i in mine.size():
			var p: Person = mine[i]
			if p.mind == Person.Mind.DUTY:
				continue  # it took over a duty (the bell, an engineer's place)
			if p.anchor.distance_to(point) > REACH or p.mind != Person.Mind.POST:
				p.send_to_post(_crowd._spot_near(point + OFFSETS[i % OFFSETS.size()], 0.2), false, true)  # at a run
		_steady(d.guarded, mine)


## Guarded responders confused near one of their escorts come to sooner.
func _steady(guarded: Array, mine: Array) -> void:
	for g in guarded:
		if not is_instance_valid(g) or (g as Person).mind != Person.Mind.CONFUSED:
			continue
		var gp: Person = g
		for p in mine:
			if (p as Person).ground_pos.distance_to(gp.ground_pos) <= STEADY_R:
				gp._confused_left = minf(gp._confused_left, STEADY_TIME)
				break


## Whether `p` is guarding a duty now (Crowd leaves it out of the patrols' investigations).
func guarding(p: Person) -> bool:
	for key in guards:
		if (guards[key] as Array).has(p):
			return true
	return false


## The nearest escort guarding nothing and on no duty of its own (a stand-in bellkeeper or engineer).
func _free_nearest(point: Vector2) -> Person:
	var taken := []
	for key in guards:
		taken.append_array(guards[key])
	var best: Person = null
	for p in _crowd.soldiers:
		if not is_instance_valid(p) or not p.is_alive() or p.corps != Person.Corps.ESCORT or taken.has(p) \
				or p.mind == Person.Mind.DUTY:
			continue
		if best == null or p.ground_pos.distance_squared_to(point) < best.ground_pos.distance_squared_to(point):
			best = p
	return best


func _release(mine: Array) -> void:
	for p in mine:
		if is_instance_valid(p) and (p as Person).is_alive():
			var s: Person = p
			s.send_to_post(s.post if s.post != Vector2.INF else s.ground_pos)


## A living escort of the bellkeeper to climb in its place, taken off the guard; null when there is none.
func bell_stand_in() -> Person:
	return _take("bell")


## A living escort of `team` to take a fallen engineer's place, taken off the guard; null when there is none.
func engineer_stand_in(team: Dictionary) -> Person:
	return _take("team:%d" % int(team.get("id", -1)))


func _take(key: String) -> Person:
	var mine: Array = guards.get(key, [])
	for i in mine.size():
		var p = mine[i]
		if is_instance_valid(p) and (p as Person).is_alive():
			mine.remove_at(i)
			return p
	return null


func clear() -> void:
	guards.clear()
