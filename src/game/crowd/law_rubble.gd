class_name LawRubble
extends RefCounted
## Law rubble (spec §4.3): what a Decree power leaves on the ground (Erasing Distance, Eminent Domain). A blocking pile of
## role `decree`: the walk grid closes its cells when it is laid (WalkGrid on structure_added), the town's engineers
## clear it as they clear a Windfall's stones (EngineerManager.CLEARABLE), and like any power's pile its fall is no
## incident (Crowd) and no demon claws at it (Visitors).

const ROLE := &"decree"


## Lays a pile `h` tall on `rect`; returns it.
static func lay(env: EnvironmentField, rect: Rect2, h: float) -> Structure:
	return env.add_structure(rect, h, Structure.Kind.CRATES, ROLE)
