class_name JudgementDirector
extends LastJudgementDirector
## Act III of The Long Night (v0.09): Last Judgement in the town the night has made. It starts the night's carry-overs --
## a broken festival's crowd still fleeing into gates it jams, marshals already at the gates, a rallied or a leaderless
## Citadel -- and runs the act's windows: the clergy gather, the boats sail, the last ferry leaves. Its tags and how-to-win
## phases are Last Judgement's (LastJudgementDirector); its tour is its own.

## How long a broken festival's crowd keeps every gate jammed.
const JAM_SECONDS := 40.0
## The act's windows, in seconds from its start.
const RITE_AT := 90.0
const BOATS_AT := 120.0
const LAST_FERRY_AT := 150.0


func _begin() -> void:
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	var n := night if night != null else NightState.new()
	if n.festival == "broken":
		for g in town.gates:
			if is_instance_valid(g) and g.walkable:
				crowd.hold_gate(g, JAM_SECONDS)
		for p in n.festival_broke:
			if is_instance_valid(p) and p.is_alive():
				p.flee()
	elif n.festival == "held" and crowd.marshals != null:
		crowd.marshals.begin()
	if n.prince == "escaped":
		crowd.rally()
	elif n.prince == "unseen":
		crowd.forgo_rally()
	if crowd.rite != null and crowd.rite.state == BanishingRite.State.IDLE:
		timeline.add(RITE_AT, "rite", "The clergy gather", func() -> void: crowd.rite.begin(),
			func() -> bool: return crowd.rite.state == BanishingRite.State.IDLE)
	if crowd.ferry != null and crowd.ferry.state != RiverFerry.State.ENDED:
		timeline.add(BOATS_AT, "boats", "The boats sail", func() -> void: crowd.ferry.begin(),
			func() -> bool: return crowd.ferry.state == RiverFerry.State.MOORED)
		timeline.add(LAST_FERRY_AT, "last_ferry", "The last ferry leaves", func() -> void: crowd.ferry.close("the last ferry"),
			func() -> bool: return crowd.ferry.state != RiverFerry.State.ENDED)


func step(delta: float) -> void:
	timeline.step(delta)


func teardown() -> void:
	timeline = null  # its banner and guard lambdas hold this director: let both go


## The tour (board tags, spec §4): the Citadel, then the Main Gate.
func tour() -> Array:
	var out := []
	if town != null and is_instance_valid(town.citadel) and is_instance_valid(town.citadel.keep):
		out.append([town.citadel.keep.center(), "The Citadel. Bring it down before dawn."])
	if town != null and not town.gates.is_empty() and is_instance_valid(town.gates[0]):
		out.append([town.gates[0].center(), "The gates. Too many escaping loses the night."])
	return out
