class_name Descent
extends RefCounted
## One night on the tier board (v0.11 M1, spec §4-§6): its tier, Halcyon's Gaze at Tier 5 for a director that keeps none,
## the wishes heard at the descent, and what the night earns. Mission makes one per board night and hands it to
## each act's Rules (attach()), which step it every frame before the objectives are checked and hold the night open once
## its main objective is done.

## The main objective's believers before the tier's multiplier (spec §4).
const MAIN_REWARD := 10
## Granted wishes lost on a night not ascended (spec §6), by the reason it ended; any clock's end is dawn's.
const LOST := {"gaze": "lost: Halcyon saw you", "bell": "lost: the bell tolled", "escapes": "lost: the people escaped"}
const LOST_DAWN := "lost: dawn came"
const LOST_ANY := "lost: the night was lost"
## The banners when a wish is granted, and when one fails (spec §5.1-§5.2).
const GRANTED_BANNER := "A WISH IS GRANTED"
const FAILED_BANNER := "A PRAYER GOES UNANSWERED"
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
## The wishes heard at the descent (spec §5), in the order drawn.
var wishes: Array[Wish] = []
## The wishes have been heard: only once a night, at its first act.
var _heard := false
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


## An act begins (Mission._build_act()): its Rules step this night and pass its casts to the wishes; at Tier 5 a director
## with no Gaze of its own gets the night's, one Gaze for every act; the first act hears the wishes (spec §5.1), and every
## act's director reserves the wishes' people.
func attach(rules: Rules, director: MissionDirector) -> void:
	rules.descent = self
	_crowd = rules.crowd()
	if not rules.cast_made.is_connected(_on_cast):
		rules.cast_made.connect(_on_cast)
	if tier >= TierBook.GAZE_TIER and director != null and (director.gaze == null or director.gaze == gaze):
		if gaze == null:
			gaze = TierGaze.new()
			_crowd._field.enemy_killed.connect(_on_killed)
		director.gaze = gaze
	if not _heard:
		_heard = true
		hear(rules.crowd(), rules.town())
	if director != null:
		for w in wishes:
			for p in w.people():
				if not director.reserved.has(p):
					director.reserved.append(p)


## The town prays (spec §5.1): TierBook.wishes(tier) wishes drawn with the night's seed, filtered by the mission's tags and by
## what the town can give, each paying its believers at the tier's multiplier.
func hear(crowd: Crowd, town: Town) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = wish_seed
	wishes = WishBook.draw(WishBook.pool(), TierBook.wishes(tier), def.mission_tags, crowd, town, rng)
	for w in wishes:
		w.reward = reward(w.def.reward)


## An act is over and another follows (The Long Night): its seconds count toward the night's time.
func next_act(rules: Rules) -> void:
	_before += rules.elapsed()


## One frame of the night, from Rules.advance(): Tier 5's Gaze judges the deaths noted, and each open wish runs and is judged
## -- granted (its wisher believes) or failed, each with its banner.
func step(rules: Rules, delta: float) -> void:
	if gaze is TierGaze and _crowd != null:
		gaze.judge_deaths(_crowd)
	for w in wishes:
		if w.status != Objective.Status.PENDING:
			continue
		w.step(rules, delta)
		match w.check(rules):
			Objective.Status.DONE:
				w.grant()
				rules.banner.emit(GRANTED_BANNER)
			Objective.Status.FAILED:
				rules.banner.emit(FAILED_BANNER)


func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	if gaze != null:
		gaze.note_death(e.ground_pos)


func _on_cast(_slot: int, key: String, at: Vector2) -> void:
	for w in wishes:
		if w.status == Objective.Status.PENDING:
			w.on_cast(key, at)


## The player engages the timed wish `i` (spec §5.2: its tag clicked); true when it was waiting and now runs.
func engage(i: int) -> bool:
	return i >= 0 and i < wishes.size() and wishes[i].engage()


## The wishes' tags (spec §5.1), each open wish's in turn.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for w in wishes:
		out.append_array(w.tags())
	return out


## Lets go of the world's signals (Mission.start() before a fresh night).
func release() -> void:
	for w in wishes:
		w.release()
	if is_instance_valid(_crowd) and _crowd._field != null and _crowd._field.enemy_killed.is_connected(_on_killed):
		_crowd._field.enemy_killed.disconnect(_on_killed)


## A reward at the night's multiplier (spec §4).
func reward(base: int) -> int:
	return TierBook.believers(base, tier)


func main_reward() -> int:
	return reward(MAIN_REWARD)


## What the night banks (spec §6): nothing before the main objective; its believers once it is done; and, ascended, every
## granted wish's too.
func earned(rules: Rules) -> int:
	if not rules.main_done:
		return 0
	var total := main_reward()
	if rules.ascended:
		for w in wishes:
			total += w.reward if w.status == Objective.Status.DONE else 0
	return total


## Why granted wishes are lost (spec §6), from how the night ended; "" for an ascent.
func lost_text(rules: Rules) -> String:
	if rules.ascended:
		return ""
	var why := rules.caught if rules.main_done else rules.over_reason
	if why in DAWNS:
		return LOST_DAWN
	return String(LOST.get(why, LOST_ANY))


## The night's report for the results and the save (spec §6), merged into the result by Mission: {"descend": {tier, main,
## main_time, main_reward, ascended, caught, wishes, lost_text, earned, kept}}. Each wish is {text, reward, state, lost}.
## `lost` marks a granted wish not banked; `kept` counts the banked ones.
func report(rules: Rules) -> Dictionary:
	var lost := lost_text(rules)
	var rows := []
	var kept := 0
	for w in wishes:
		var state := Wish.state_name(w.status)
		var gone := state == "granted" and lost != ""
		kept += 1 if state == "granted" and not gone else 0
		rows.append({"text": w.def.text, "reward": w.reward, "state": state, "lost": gone})
	return {"descend": {"tier": tier, "main": rules.main_done, "main_time": _before + rules.main_time if rules.main_done else 0.0,
		"main_reward": main_reward(), "ascended": rules.ascended, "caught": rules.caught, "wishes": rows, "lost_text": lost,
		"earned": earned(rules), "kept": kept}}
