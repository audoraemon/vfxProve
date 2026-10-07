class_name ActDef
extends MissionDef
## One act of a mission played in acts (v0.09): everything a MissionDef has -- clock, objectives, bonuses, director,
## camera, banner -- plus the town it wants given the night so far, and the acts that may follow it. Rules, the HUD and
## Prepare take an ActDef wherever they take a MissionDef.

## The acts that may follow, by id: none (the last act), one, or two (the choice card).
var next := PackedStringArray()
## func(night: NightState) -> ResponseProfile: the town this act wants. Crowd.raise_profile() never lowers it.
var make_town: Callable
## func(night: NightState) -> Array[Objective], for objectives that depend on the night (Act III's escape limit).
## When unset, MissionDef's make_objectives / make_bonuses are used.
var make_act_objectives: Callable
var make_act_bonuses: Callable
## func(night: NightState) -> String: the choice card's line on how the town will meet the player.
var make_card_line: Callable
## The act's timed events, one short line each, for the choice card ("1:30 The Mayor's address").
var events_text := PackedStringArray()
## The night so far; Mission sets it before Rules.setup() asks for the objectives.
var night: NightState


## The town this act wants (v0.09), at least as ready as the board's tier sets (v0.11 M1, tier_floor).
func town(n: NightState) -> ResponseProfile:
	var own: ResponseProfile = make_town.call(n) if make_town.is_valid() else ResponseProfile.unaware()
	return own.at_least(tier_floor)


## The town this act will play, whatever difficulty is passed: the night sets it, so Prepare's strip between acts shows
## the town the act really meets (a rung bell: Organized), not The Long Night's first, sleeping one.
func response_profile(_chosen: ResponseProfile.Tier) -> ResponseProfile:
	return town(night if night != null else NightState.new())


func is_last() -> bool:
	return next.is_empty()


func card_line(n: NightState) -> String:
	return String(make_card_line.call(n)) if make_card_line.is_valid() else ""


func objectives() -> Array[Objective]:
	if not make_act_objectives.is_valid():
		return super()
	var out: Array[Objective] = []
	out.assign(make_act_objectives.call(night if night != null else NightState.new()))
	return out


func bonuses() -> Array[Objective]:
	if not make_act_bonuses.is_valid():
		return super()
	var out: Array[Objective] = []
	out.assign(make_act_bonuses.call(night if night != null else NightState.new()))
	return out
