class_name LastJudgementDirector
extends MissionDirector
## Last Judgement's director (board tags): it runs no actors and changes nothing; it only points out what the mission is
## about -- the Citadel to bring down, the gates the town escapes by, and the town's answers while they run (the
## Banishing Rite, the boats) -- and says which how-to-win line fits. Judgement, its act in The Long Night, is one
## (JudgementDirector).

## The map tags' colours (board tags, spec §2): the Citadel gold; the ways out and the rite red.
const MARK_CITADEL := Color("d8b23a")
const MARK_WATCHED := Color("c8342a")


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
