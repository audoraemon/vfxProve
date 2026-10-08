class_name TierBook
extends RefCounted
## The god's five Awakening Tiers on the board (v0.11 M1, spec §3-§4): each tier's name and missions, and what it sets --
## the town's readiness, the base slots and Divine Power, the clock, the wishes heard and the believers' multiplier -- and
## the unlocking rule's count. First guesses, tuned per milestone. board() builds a board mission from a ★ mission.

## The tiers' names, Tier 1 first (2-4 are placeholders the user may rename).
const NAMES := ["Whisper", "Omen", "Wrath", "Reckoning", "Ascendance"]
## The board's missions on each tier, by id: spec §8's ★ missions (M2-M6 add the rest).
const MISSIONS := [["warning"], ["miras_house", "broken_lanterns"], ["vigil_flame", "festival"], ["procession"],
	["last_judgement", "long_night"]]
## The town's readiness on each tier, as ResponseProfile.level(): Unaware, Organized, Prepared, God-Resistant twice.
const READINESS := [1, 2, 3, 4, 4]
## The base slots and Divine Power on each tier; the upgrades add to them.
const SLOTS := [3, 3, 4, 5, 6]
const DP := [6, 8, 10, 13, 16]
## The clock (dawn) on each tier, in seconds.
const CLOCKS := [300.0, 330.0, 360.0, 390.0, 420.0]
## The wishes heard at each tier's descent, and the believers' multiplier.
const WISHES := [2, 2, 3, 3, 3]
const MULTIPLIERS := [1.0, 1.5, 2.0, 2.5, 3.0]
## Cleared missions of a tier that open the next (spec §3.2), fewer while a tier has fewer missions (before M6).
const NEED := 3
## The most slots a loadout can have: the HUD's row and the keys 1-6.
const MAX_SLOTS := 6
## The tier from which every mission keeps Halcyon's Gaze (spec §4), and the share of GazeMeter.SEEN_DEATH a seen death adds
## there: Broken Lanterns' share, a first guess for nights that kill hundreds.
const GAZE_TIER := 5
const GAZE_SHARE := 0.05
## Each board mission's type on its card (spec §3.1, §8).
const TYPES := {"warning": "Intercept", "miras_house": "Cult", "broken_lanterns": "Anchors", "vigil_flame": "Cult",
	"festival": "Break", "procession": "Kill", "last_judgement": "Destroy", "long_night": "Three acts"}
## The tags a mission declares for the wishes to filter on (spec §5.1): a wish listing one of them is never drawn there.
## unaware_town is not declared: board() derives it from the town's readiness (v0.11 M2).
const MISSION_TAGS := {"miras_house": ["spares_houses"]}
## The tag every board mission in an Unaware town carries (v0.11 M2), and that readiness on ResponseProfile.level()'s scale.
const UNAWARE_TAG := "unaware_town"
const UNAWARE_LEVEL := 1
## The board's Festival (spec §7.2): the need rises to FESTIVAL_NEED, more come (FESTIVAL_CROWD) so it can be met, and the
## guard closes the square at FESTIVAL_CLOSE, before dawn.
const FESTIVAL_NEED := 80
const FESTIVAL_CROWD := 120
const FESTIVAL_CLOSE := 270.0


## A tier's entry in `table`, tiers counted from 1 (outside 1-5, the nearest tier's).
static func _at(table: Array, tier: int) -> Variant:
	return table[clampi(tier, 1, table.size()) - 1]


static func tier_name(tier: int) -> String:
	return String(_at(NAMES, tier))


static func missions(tier: int) -> PackedStringArray:
	return PackedStringArray(_at(MISSIONS, tier))


static func readiness(tier: int) -> int:
	return int(_at(READINESS, tier))


static func slots(tier: int) -> int:
	return int(_at(SLOTS, tier))


static func dp(tier: int) -> int:
	return int(_at(DP, tier))


static func clock(tier: int) -> float:
	return float(_at(CLOCKS, tier))


static func wishes(tier: int) -> int:
	return int(_at(WISHES, tier))


static func multiplier(tier: int) -> float:
	return float(_at(MULTIPLIERS, tier))


## Cleared missions of `tier` that open the next: NEED, or all of them while the tier has fewer (spec §3.2).
static func need(tier: int) -> int:
	return mini(NEED, missions(tier).size())


## The tier the board mission `id` is on, or 0 when it is not on the board.
static func tier_of(id: String) -> int:
	for tier in range(1, NAMES.size() + 1):
		if missions(tier).has(id):
			return tier
	return 0


static func has(id: String) -> bool:
	return tier_of(id) > 0


## Every board mission, tier by tier.
static func all() -> PackedStringArray:
	var out := PackedStringArray()
	for tier in range(1, NAMES.size() + 1):
		out.append_array(missions(tier))
	return out


static func type_of(id: String) -> String:
	return String(TYPES.get(id, ""))


static func mission_tags(id: String) -> PackedStringArray:
	return PackedStringArray(MISSION_TAGS.get(id, []))


## Believers paid on `tier` for `base` (spec §4): times the tier's multiplier, rounded.
static func believers(base: int, tier: int) -> int:
	return roundi(float(base) * multiplier(tier))


## A board mission (v0.11 M1, spec §4, §7.2): the ★ mission `id` at its tier.
## - The tier's clock (The Long Night keeps its acts').
## - Its readiness as a floor.
## - The base slots and DP plus `state`'s upgrades (MAX_SLOTS at most).
## - Its event times stretched to the longer clock.
## - No bonuses: the wishes take their place.
## - Its mission tags, and at GAZE_TIER the Gaze objective.
## Null for an id not on the board. MissionBook's own missions are fresh copies each call, so nothing here reaches them.
static func board(id: String, state: DescendState = null) -> MissionDef:
	var tier := tier_of(id)
	if tier == 0:
		return null
	var m: MissionDef = checked(_from_act(id) if id == "festival" or id == "procession" else MissionBook.get_mission(id), id)
	if m == null:
		return null
	var own_clock := m.clock
	m.tier = tier
	m.tier_floor = readiness(tier)
	m.make_bonuses = Callable()
	m.mission_tags = mission_tags(id)
	# (v0.11 M2) Every Unaware board mission carries unaware_town, so the wishes that cannot sit in a sleeping town stay out.
	if m.response_profile(ResponseProfile.DEFAULT).level() <= UNAWARE_LEVEL and not m.mission_tags.has(UNAWARE_TAG):
		m.mission_tags.append(UNAWARE_TAG)
	_budget(m, tier, state)
	if not m.has_acts():
		m.clock = clock(tier)
		m.stretch = m.clock / own_clock
	match id:
		"warning":
			_warning(m)
		"festival":
			_festival(m)
		"last_judgement":
			m.goal = "Destroy the Citadel and break the city before dawn"
	if tier >= GAZE_TIER:
		_gaze(m)
	return m


## `m` when it really is the mission `id` (v0.11 M1), else an error and null: MissionBook.get_mission() falls back to Last
## Judgement for an id it does not know, which would put a board id on the wrong mission without a word.
static func checked(m: MissionDef, id: String) -> MissionDef:
	if m != null and m.id == id:
		return m
	push_error("TierBook: no mission built for the board id '%s' (got '%s')" % [id, m.id if m != null else "null"])
	return null


## The tier's slots and DP plus the upgrades bought, for the mission and each of its acts, which take its tier and floor.
static func _budget(m: MissionDef, tier: int, state: DescendState) -> void:
	m.slots = mini(slots(tier) + (state.slot_bought if state != null else 0), MAX_SLOTS)
	m.dp_capacity = dp(tier) + (state.dp_bought if state != null else 0)
	for a: ActDef in m.acts:
		a.tier = tier
		a.tier_floor = m.tier_floor
		a.slots = m.slots
		a.dp_capacity = m.dp_capacity


## The Festival or the Procession as a mission of its own (spec §8 rows 12 and 16): The Long Night's act -- its director,
## objectives and windows -- on a night of its own, in a town the floor raises. Its id is the act's.
static func _from_act(id: String) -> MissionDef:
	var a := MissionBook.long_night().act(id)
	var m := MissionDef.new()
	m.id = id
	m.name = a.name.trim_prefix("Act II: ")
	m.brief = a.brief
	m.goal = a.goal
	m.goal_label = a.goal_label
	m.lose = a.lose
	m.clock = a.clock
	m.profile = "unaware"
	m.pool = a.pool
	m.default_loadout = a.default_loadout
	m.intro_from = a.intro_from
	m.camera_at = a.camera_at
	m.intro_banner = m.name.to_upper()
	m.director = a.director
	m.make_objectives = a.make_objectives
	return m


## The board's Festival (spec §7.2): its windows stretched to the 4:30 close, the need and the crowd raised before the
## director gathers it, and the close a deadline -- dawn is the tier's.
static func _festival(m: MissionDef) -> void:
	m.stretch = FESTIVAL_CLOSE / FestivalDirector.CLOSE_AT
	m.goal = "Break the festival before the guard closes the square at %s" % UiTheme.clock(FESTIVAL_CLOSE)
	m.tune = func(d: MissionDirector) -> void:
		var f := d as FestivalDirector
		if f != null:
			f.need = FESTIVAL_NEED
			f.crowd_size = FESTIVAL_CROWD
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [FestivalObjective.new(), EventObjective.new("close", "Square closes", "closed")]
		return out


## The board's Warning (spec §7.2): three stars, three runners (StarfallDirector), all three to stop. No stretch: the stars
## keep the spec's own times.
static func _warning(m: MissionDef) -> void:
	m.director = StarfallDirector
	m.stretch = 1.0
	m.brief = PackedStringArray(["Three stars fall through the night.", "Each sends a runner to wake the bell."])
	m.goal = "Stop all three warnings before the bell tolls"
	m.goal_label = "The warnings die"
	m.lose = "The bell tolls, or dawn comes with a warning alive"
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [StarsObjective.new(), BellSilentObjective.new(), ClockObjective.new(false, "Dawn", "dawn")]
		return out


## Halcyon's Gaze in a Tier 5 mission (spec §4): a GazeObjective after its own objectives, in the mission and in each act. It
## waits while the director has no Gaze; the night's Descent gives one to a director that keeps none.
static func _gaze(m: MissionDef) -> void:
	m.make_objectives = _with_gaze(m.make_objectives)
	for a: ActDef in m.acts:
		a.make_objectives = _with_gaze(a.make_objectives)
		if a.make_act_objectives.is_valid():
			a.make_act_objectives = _with_gaze_for_night(a.make_act_objectives)


static func _with_gaze(make: Callable) -> Callable:
	return func() -> Array[Objective]:
		var out: Array[Objective] = []
		if make.is_valid():
			out.assign(make.call())
		out.append(GazeObjective.new())
		return out


static func _with_gaze_for_night(make: Callable) -> Callable:
	return func(n: NightState) -> Array[Objective]:
		var out: Array[Objective] = []
		out.assign(make.call(n))
		out.append(GazeObjective.new())
		return out
