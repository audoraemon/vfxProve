class_name LastJudgementDirector
extends MissionDirector
## Last Judgement's director (board tags): it runs no actors and changes nothing; it only points out what the mission is
## about -- the Citadel to bring down, the gates the town escapes by, and the town's answers while they run (the
## Banishing Rite, the boats) -- and says which how-to-win line fits. Judgement, its act in The Long Night, is one
## (JudgementDirector).

## The map tags' colours (board tags, spec §2): the Citadel gold; the ways out and the rite red.
const MARK_CITADEL := Color("d8b23a")
const MARK_WATCHED := Color("c8342a")


## The Citadel is the night's to bring down (R45 as amended; CitadelObjective): its parts are never spared from a power's side
## effects, budget or not.
func wants_down(s: Structure) -> bool:
	return s != null and s.role == &"citadel"


## The map tags (board tags, spec §2), most important first:
## - the Citadel, pointed at from the edge, until it falls;
## - the Banishing Rite, pointed at, while the clergy gather or chant;
## - the boats, pointed at, while they take people off;
## - each gate the town escapes by.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if town == null:
		return out
	var keep: Structure = town.citadel.keep if is_instance_valid(town.citadel) else null
	if is_instance_valid(keep) and not town.citadel.is_fallen():
		out.append(MapTag.place(keep.center(), MARK_CITADEL, "CITADEL", keep.height))
	if rite_running():
		out.append(MapTag.place(crowd.rite.centre, MARK_WATCHED, "BANISHING RITE"))
	var ferry: RiverFerry = crowd.ferry if crowd != null else null
	if ferry != null and ferry.board_at != Vector2.INF and ferry.open():
		out.append(MapTag.place(ferry.board_at, MARK_WATCHED, "BOATS"))
	for g in town.gates:
		if is_instance_valid(g):
			out.append(MapTag.place(g.center(), MARK_WATCHED, "GATE", g.height, false))
	return out


## The clergy gather for the rite or chant it.
func rite_running() -> bool:
	var rite: BanishingRite = crowd.rite if crowd != null else null
	return rite != null and rite.centre != Vector2.INF \
		and (rite.state == BanishingRite.State.GATHERING or rite.state == BanishingRite.State.CHANTING)


## The hint's phase (board tags, spec §3): "rite" while the rite runs, else "fallen" once the Citadel is down, else "".
func hint_phase() -> String:
	if rite_running():
		return "rite"
	return "fallen" if town != null and is_instance_valid(town.citadel) and town.citadel.is_fallen() else ""


## Every phase hint_phase() can return (Mission clarity, spec 6.1).
func hint_phases() -> PackedStringArray:
	return PackedStringArray(["", "rite", "fallen"])


## The loss warning looks at fleers no more than this many seconds from their way out (well past ThreatAlert.CLEAR_AT): a mass flight is
## hundreds of runners, and the far ones cannot be the warned escape.
const ESCAPE_LOOK := 25.0


## Loss warning: the last escapes the limit allows (EscapeLimitObjective: that many more out and the night is lost), `escape` at escape_eta().
## Only reads.
func threats() -> Array[Dictionary]:
	var out := super()
	var eta := escape_eta()
	if eta < INF:
		out.append(NightThreat.make(&"escape", "THE PEOPLE ESCAPE", "STOP THEM AT THE GATES", eta, _escape_at))
	return out


## The escapes still allowed before the limit fails the night (EscapeLimitObjective), 0 with no limit or the law of escape abolished.
func escapes_left() -> int:
	if not is_instance_valid(rules) or rules.is_abolished(Rules.LAW_ESCAPE):
		return 0
	for o in rules.objectives:
		if o is EscapeLimitObjective:
			return maxi((o as EscapeLimitObjective).limit - rules.escaped_this_act(), 0)
	return 0


## Mission seconds until the escape that fails the night: of every citizen fleeing for a way out by land (Person.has_escaped(): a FLEE at
## its goal; the boats carry theirs off on their own time and are not counted), the escapes_left()-th soonest walk there at the pace he
## runs now; INF with fewer than that within ESCAPE_LOOK of their way out, every door shut, or the main objective held. Only reads. The gates' queues are not counted,
## so the warning can come early, never late.
func escape_eta() -> float:
	var left := escapes_left()
	if left < 1 or crowd == null or crowd.doors_shut() or rules.main_done:
		return INF
	var soon: Array = []
	for p in crowd.citizens:
		if not is_instance_valid(p) or not p.is_alive() or p.inside or p.mind != Person.Mind.FLEE or p._goal == Vector2.INF:
			continue
		if p.evac != null and p.evac.is_boat_exit(p._goal):
			continue
		if p.ground_pos.distance_to(p._goal) > ESCAPE_LOOK * maxf(p.walk_speed, 0.05):
			continue  # farther than ESCAPE_LOOK even in a straight line: no card's time, and no road to sum
		soon.append([maxf(walk_left(p, p._goal) - Person.GOAL_REACH / maxf(p.walk_speed, 0.05), 0.0), p._goal])
	if soon.size() < left:
		return INF
	soon.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	_escape_at = soon[left - 1][1]
	return float(soon[left - 1][0]) * mission_delta(1.0)


## Where the escape escape_eta() last named happens (its way out).
var _escape_at := Vector2.INF


## Music by situation: the chant while the rite runs.
func music_mood() -> StringName:
	return &"rite" if rite_running() else &""
