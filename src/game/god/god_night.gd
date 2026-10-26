class_name GodNight
extends RefCounted
## One Endless Night night for a god (god P1, spec §9.1, §8, §7): which mission the night is (a seeded draw that never repeats the last
## one), the mission as this god plays it (its slots, Might, drafted abilities and Faith clock), what a finished night banks (Divine Power,
## Faith, the god's bests, the carried abilities) and what an abandoned one costs. All statics; the god's save slot is the only thing
## written, and never the board's save (C7). Game owns the flow around these; Mission only gets the two hooks `night_def` and
## `restart_locked`.

## Divine Power a cleared main objective earns, times the night's mission tier (spec §8; *tunable*).
const MAIN_DP := 80
## Divine Power one banked wish earns, times the night's mission tier (spec §8; *tunable*).
const WISH_DP := 20
## The pool of a god with nothing to draft (Ruling P8): no power is allowed. An empty pool would mean every power
## (MissionDef.powers()), which would hand an empty god the whole book.
const NO_POWERS := "none"
## The line for a night left once its clock had started (Ruling P9, spec §9.1; *my call*): `%d` is the night's number.
const ABANDONED := "Night %d was abandoned: a lost night."


## The seed of this god's next draw (Ruling P17): the god's own seed and the night it is on, so quitting from Prepare and coming
## back draws the same night, and two gods do not share draws.
static func night_seed(slot: GodSlot) -> int:
	return hash([slot.seed, slot.night])


## The seed of the night's wishes for mission `id` (Ruling P17): stable for the same slot, night and mission.
static func wish_seed(slot: GodSlot, id: String) -> int:
	return hash([slot.seed, slot.night, id])


## The next night's mission (spec §9.1): one of the god's tier missions (TierBook.missions()), never the last one played, picked by a
## generator seeded with night_seed(). Nothing changes, so the same slot gives the same night until one counts.
static func draw(slot: GodSlot) -> String:
	var pool := PackedStringArray()
	for id in TierBook.missions(slot.tier):
		if id != slot.last_mission:
			pool.append(id)
	if pool.is_empty():  # a tier with one mission: nothing else to draw
		pool = TierBook.missions(slot.tier)
	var rng := RandomNumberGenerator.new()
	rng.seed = night_seed(slot)
	return pool[rng.randi_range(0, pool.size() - 1)]


## The mission `id` as `slot`'s god plays it (spec §9.1): the board's version at the god's tier with the god's slots, Might and
## drafted abilities, and the Faith clock added to the night's clock after the board stretched its events (Ruling P7: the events keep
## the tier's times and only dawn comes later). A night with acts has the clock added to each act. Null for an id not on the board.
static func def_for(slot: GodSlot, id: String) -> MissionDef:
	var def := TierBook.board(id, null)
	if def == null:
		return null
	var pool := slot.draftable()
	if pool.is_empty():
		pool = PackedStringArray([NO_POWERS])
	var extra := slot.extra_clock()
	_apply_god(def, slot, pool)
	if def.has_acts():
		for a: ActDef in def.acts:
			_apply_god(a, slot, pool)
			a.clock += extra
	else:
		def.clock += extra
	return def


## The god's numbers on one def (the mission or an act).
static func _apply_god(def: MissionDef, slot: GodSlot, pool: PackedStringArray) -> void:
	def.slots = slot.slots()
	def.dp_capacity = slot.max_might()
	def.pool = pool.duplicate()


## Divine Power a night earns (spec §8, Ruling P22): from a report's "descend", the main objective's `MAIN_DP x tier` and `WISH_DP x
## tier` per banked wish (`kept`). A night with no main objective earns none; one caught after it has kept no wishes, so the main's only.
static func divine_power(d: Dictionary) -> int:
	if not bool(d.get("main", false)):
		return 0
	var tier := maxi(int(d.get("tier", 1)), 1)
	return MAIN_DP * tier + WISH_DP * tier * maxi(int(d.get("kept", 0)), 0)


## Banks a finished night (spec §7, §8, §9.1; Ruling P16): the night counts, `id` is the last mission, Faith comes 1:1 from the
## believers banked, Divine Power from divine_power(), the mission's bests are kept, and each drafted ability is carried once more.
## `outcome` is a result with Descent.report()'s "descend". Returns what the results show: {"divine_power", "levels", "points", "lost",
## "capped", "level", "bar": [divine_power, need], "believers", "faith", "faith_total", "notice", "notice_change", "night", "bests"}.
static func bank(slot: GodSlot, id: String, drafted: PackedStringArray, outcome: Dictionary) -> Dictionary:
	var d: Dictionary = outcome.get("descend", {})
	slot.night += 1
	slot.last_mission = id
	slot.in_night = ""
	var earned := maxi(int(d.get("earned", 0)), 0)
	var faith := earned * GodSlot.FAITH_PER_BELIEVER
	slot.faith += faith
	var dp := divine_power(d)
	var gained := slot.gain_dp(dp)
	var bests := _keep_bests(slot, id, d)
	for key in drafted:
		slot.carried[key] = int(slot.carried.get(key, 0)) + 1
	slot.loadout = drafted.duplicate()
	return {"divine_power": dp, "levels": gained.levels, "points": gained.points, "lost": gained.lost, "capped": gained.capped,
		"level": slot.level, "bar": [slot.divine_power, slot.need()], "believers": earned, "faith": faith, "faith_total": slot.faith,
		"notice": slot.notice, "notice_change": 0, "night": slot.night, "bests": bests}


## The mission's bests (as DescendState writes them, for this god): cleared on a main objective done, the fastest clear and the
## most wishes banked kept when beaten. Returns the text of each new best.
static func _keep_bests(slot: GodSlot, id: String, d: Dictionary) -> PackedStringArray:
	var best: Dictionary = slot.bests.get(id, {"cleared": false, "fastest": 0.0, "most_wishes": 0}).duplicate()
	var texts := PackedStringArray()
	var main := bool(d.get("main", false))
	var time := float(d.get("main_time", 0.0))
	if main:
		best["cleared"] = true
	if main and time > 0.0 and (float(best.fastest) <= 0.0 or time < float(best.fastest)):
		best["fastest"] = time
		texts.append("Fastest clear %s" % UiTheme.clock(time))
	var kept := int(d.get("kept", 0))
	if kept > int(best.most_wishes):
		best["most_wishes"] = kept
		texts.append("Most wishes granted: %d" % kept)
	slot.bests[id] = best
	return texts


## A night left once its clock had started is a lost one (spec §9.1, Ruling P9): it counts, the mission is the last played, nothing
## is earned (P2 adds the Notice). Returns {"night": the new count, "line": ABANDONED % night}.
static func forfeit(slot: GodSlot) -> Dictionary:
	slot.night += 1
	if slot.in_night != "":
		slot.last_mission = slot.in_night
	slot.in_night = ""
	return {"night": slot.night, "line": ABANDONED % slot.night}
