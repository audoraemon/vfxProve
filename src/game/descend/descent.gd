class_name Descent
extends RefCounted
## One night on the tier board (v0.11 M1, spec §4-§6): its tier, Halcyon's Gaze at Tier 5 for a director that keeps none,
## the wishes heard at the descent (Task 6), and what the night earns. Mission makes one per board night and hands it to
## each act's Rules (attach()), which step it every frame before the objectives are checked and hold the night open once
## its main objective is done.

## The main objective's believers before the tier's multiplier (spec §4).
const MAIN_REWARD := 10
## Granted wishes lost on a night not ascended (spec §6), by the reason it ended; any clock's end is dawn's.
const LOST := {"gaze": "lost: Halcyon saw you", "bell": "lost: the bell tolled", "escapes": "lost: the people escaped"}
const LOST_DAWN := "lost: dawn came"
const LOST_ANY := "lost: the night was lost"
## The reasons that are a clock's end: dawn, Last Judgement's timeout, the Vigil Flame's, Broken Lanterns', the tide, Mira's
## too few.
const DAWNS := ["dawn", "timeout", "late", "relit", "tide", "few"]


## Halcyon's Gaze at Tier 5 (spec §4): a seen death adds TierBook.GAZE_SHARE of GazeMeter.SEEN_DEATH.
class TierGaze extends GazeMeter:
	func seen_death() -> void:
		add(GazeMeter.SEEN_DEATH * TierBook.GAZE_SHARE)


var def: MissionDef
var tier := 1
## The seed the wishes are drawn from (seed_for()).
var wish_seed := 0
## Tier 5's Gaze, shared by every act of the night; null below TierBook.GAZE_TIER.
var gaze: GazeMeter
## Seconds the night's earlier acts took (The Long Night), for the time to the main objective.
var _before := 0.0
var _crowd: Crowd


## The seed a board night's wishes are drawn from (spec §5.1): the nights played and the mission, so a restart -- or a night
## abandoned and begun again -- hears the same wishes, and a counted night redraws.
static func seed_for(night: int, id: String) -> int:
	return hash([night, id])


func setup(p_def: MissionDef, p_seed: int) -> Descent:
	def = p_def
	tier = maxi(p_def.tier, 1)
	wish_seed = p_seed
	return self


## `m` -- the mission, or the act being played -- holds the win (spec §6): a single mission does; a night only in its last act.
func holds(m: MissionDef) -> bool:
	return not (m is ActDef) or (m as ActDef).is_last()


## An act begins (Mission._build_act()): its Rules step this night, and at Tier 5 a director with no Gaze of its own gets
## the night's -- one Gaze for every act.
func attach(rules: Rules, director: MissionDirector) -> void:
	rules.descent = self
	_crowd = rules.crowd()
	if tier >= TierBook.GAZE_TIER and director != null and (director.gaze == null or director.gaze == gaze):
		if gaze == null:
			gaze = TierGaze.new()
			_crowd._field.enemy_killed.connect(_on_killed)
		director.gaze = gaze


## An act is over and another follows (The Long Night): its seconds count toward the night's time.
func next_act(rules: Rules) -> void:
	_before += rules.elapsed()


## One frame of the night, from Rules.advance(): Tier 5's Gaze judges the deaths noted.
func step(_rules: Rules, _delta: float) -> void:
	if gaze is TierGaze and _crowd != null:
		gaze.judge_deaths(_crowd)


func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	if gaze != null:
		gaze.note_death(e.ground_pos)


## Lets go of the world's signals (Mission.start() before a fresh night).
func release() -> void:
	if is_instance_valid(_crowd) and _crowd._field != null and _crowd._field.enemy_killed.is_connected(_on_killed):
		_crowd._field.enemy_killed.disconnect(_on_killed)


## A reward at the night's multiplier (spec §4).
func reward(base: int) -> int:
	return TierBook.believers(base, tier)


func main_reward() -> int:
	return reward(MAIN_REWARD)


## What the night banks (spec §6): nothing before the main objective; its believers once it is done; and, ascended, every
## granted wish's too (Task 6).
func earned(rules: Rules) -> int:
	return main_reward() if rules.main_done else 0


## Why granted wishes are lost (spec §6), from how the night ended; "" for an ascent.
func lost_text(rules: Rules) -> String:
	if rules.ascended:
		return ""
	var why := rules.caught if rules.main_done else rules.over_reason
	if why in DAWNS:
		return LOST_DAWN
	return String(LOST.get(why, LOST_ANY))


## The night's report for the results and the save (spec §6), merged into the result by Mission.
func report(rules: Rules) -> Dictionary:
	return {"descend": {"tier": tier, "main": rules.main_done, "main_time": _before + rules.main_time if rules.main_done else 0.0,
		"main_reward": main_reward(), "ascended": rules.ascended, "caught": rules.caught, "wishes": [],
		"lost_text": lost_text(rules), "earned": earned(rules), "kept": 0}}
