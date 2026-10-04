class_name JudgementDirector
extends MissionDirector
## Act III of The Long Night (v0.09): Last Judgement in the town the night has made. It starts the night's carry-overs --
## a broken festival's crowd still fleeing into gates it jams, marshals already at the gates, a rallied or a leaderless
## Citadel -- and runs the act's windows: the clergy gather, the boats sail, the last ferry leaves.

## How long a broken festival's crowd keeps every gate jammed.
const JAM_SECONDS := 40.0
## The act's windows, in seconds from its start.
const RITE_AT := 90.0
const BOATS_AT := 120.0
const LAST_FERRY_AT := 150.0


func _begin() -> void:
	timeline = EventTimeline.new()
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
