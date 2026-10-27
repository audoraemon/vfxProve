class_name GodNight
extends RefCounted
## One Endless Night night for a god (god P1, spec §9.1, §8, §7): which mission the night is (a seeded draw that never repeats the last
## one), the mission as this god plays it (its slots, Might, drafted abilities and Faith clock), what a finished night banks (Divine Power,
## Faith, the god's bests, the carried abilities) and what an abandoned one costs. God P2 (spec §10) adds the Lantern: every night moves
## the Notice, a full Notice makes the next night the Hunt, and a lost Hunt seals an ability. All statics; the god's save slot is the only thing
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
## The Notice a lost night adds, in percent (god P2, spec §10.1, Ruling P2-1; a forfeit is a lost night).
const NOTICE_LOST := 25
## The Notice a won night adds when the god was caught after the main objective (Ruling P2-1, P2-2).
const NOTICE_CAUGHT := 10
## The Notice a clean win (the god ascended) adds: negative (Ruling P2-1, P2-2).
const NOTICE_CLEAN := -5
## The Notice a lost Awaken rite will add (spec §10.1); unused until P3 (Ruling P2-1).
const NOTICE_LOST_RITE := 25
## The Notice after a won Hunt: set, not added (spec §10.3, Ruling P2-6).
const HUNT_WON_NOTICE := 0
## The Notice after a lost Hunt: set, not added (spec §10.3, Ruling P2-6).
const HUNT_LOST_NOTICE := 50
## Bonus Faith a won Hunt pays, times the god tier (spec §10.3, Ruling P2-6; *tunable*).
const HUNT_FAITH := 50
## The five Hunts, index = god tier - 1 (spec §10.2, Ruling P2-5): the stand-in mission each is played as, with the Hunt's own title and
## plate. P5 replaces the stand-ins with real Hunts.
const HUNTS := [
	{"id": MissionBook.LOST_LAMB, "title": "Hide the faithful", "plate": "Lead your believers out before the inquisitors reach them"},
	{"id": MissionBook.BELL_RINGERS, "title": "Silence the witness", "plate": "Stop the runner carrying word of you to the Lantern"},
	{"id": MissionBook.INFORMER, "title": "Expel the inquisitor", "plate": "Drive out or kill the Lantern's captain in the town"},
	{"id": MissionBook.ARMOURY, "title": "Break the hunt", "plate": "Smash their standards before they reach your believers"},
	{"id": MissionBook.HEART_OF_FAITH, "title": "Face Halcyon", "plate": "His Gaze is on the whole town, and a seen death fills it"},
]
## The line a forfeit that raised the Notice adds: `%d` is the change (Ruling P2-11; *my call*).
const NOTICE_UP := "Lantern Notice +%d%%."
## The line a seal that ran out adds: `%s` is the ability's name.
const UNSEALED := "%s is no longer sealed."
## The line for a Hunt left once its clock had started: `%d` is the night's number.
const HUNT_ABANDONED := "Night %d was abandoned: the Hunt is lost."
## What a lost Hunt's forfeit says it sealed: the ability's name, the nights.
const SEALS := "The Lantern seals %s for %s."
## What a lost Hunt's forfeit says when there was nothing to seal (Ruling P2-8).
const NOTHING_SEALED := "The Lantern found nothing to seal."
## The Notice after a Hunt's forfeit, shown: `%d` is the Notice.
const NOTICE_AT := "Lantern Notice %d%%."


## The seed of this god's next draw (Ruling P17): the god's own seed and the night it is on, so quitting from Prepare and coming
## back draws the same night, and two gods do not share draws.
static func night_seed(slot: GodSlot) -> int:
	return hash([slot.seed, slot.night])


## The seed of the night's wishes for mission `id` (Ruling P17): stable for the same slot, night and mission.
static func wish_seed(slot: GodSlot, id: String) -> int:
	return hash([slot.seed, slot.night, id])


## The Lantern Hunt this god faces next, or {} when the Notice is below 100 (spec §10.2, Ruling P2-3): HUNTS' entry for the god's tier
## plus `"tier"`. Derived from the Notice, so quitting and coming back gives the same Hunt.
static func hunt_for(slot: GodSlot) -> Dictionary:
	if not slot.hunt_due():
		return {}
	var out: Dictionary = HUNTS[clampi(slot.tier, 1, HUNTS.size()) - 1].duplicate()
	out["tier"] = slot.tier
	return out


## What the Hunt would seal, said before it is played (spec §10.3, Ruling P2-7; the pause menu and Prepare show it).
static func hunt_stake(slot: GodSlot) -> String:
	var target := slot.seal_target()
	if target == "":
		return "The Lantern has nothing to seal"
	return "The Lantern will seal %s for %s" % [PowerBook.get_power(target).name, GodSlot.nights_text(GodSlot.SEAL_NIGHTS)]


## The Notice a night moves it by, from a report's "descend" (spec §10.1, Ruling P2-1, P2-2): a night without the main objective is lost,
## a win the god ascended from is clean, any other win was caught after the main objective.
static func notice_delta(d: Dictionary) -> int:
	if not bool(d.get("main", false)):
		return NOTICE_LOST
	return NOTICE_CLEAN if bool(d.get("ascended", false)) else NOTICE_CAUGHT


## The next night's mission (spec §9.1): the Hunt when the Notice is full (it cannot be skipped: no seed, no no-repeat; Ruling P2-4),
## else one of the god's tier missions (TierBook.missions()), never the last one played, picked by a generator seeded with
## night_seed(). Nothing changes, so the same slot gives the same night until one counts.
static func draw(slot: GodSlot) -> String:
	var hunt := hunt_for(slot)
	if not hunt.is_empty():
		return String(hunt.id)
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


## Banks a finished night (spec §7, §8, §9.1, §10; Ruling P16, P2-1 to P2-10): a seal ticks, the night counts, `id` is the last mission,
## Faith comes 1:1 from the believers banked, Divine Power from divine_power(), the mission's bests are kept (not a Hunt's), each drafted
## ability is carried once more, and then the Notice moves -- or, for the Hunt (the Notice was 100 at the start), is set: a win sets 0
## and pays HUNT_FAITH x tier, a loss seals the most-carried ability chosen BEFORE this draft was counted and sets 50.
## `outcome` is a result with Descent.report()'s "descend". Returns what the results show: {"divine_power", "levels", "points", "lost",
## "capped", "level", "bar": [divine_power, need], "believers", "faith", "faith_total", "notice", "notice_change", "night", "bests",
## "hunt" ({} or {"tier", "id", "title", "won", "faith", "sealed", "seal_nights"}), "unsealed" (a key whose seal ended, or ""),
## "hunt_next"}.
static func bank(slot: GodSlot, id: String, drafted: PackedStringArray, outcome: Dictionary) -> Dictionary:
	var d: Dictionary = outcome.get("descend", {})
	var hunt := hunt_for(slot)
	var target := slot.seal_target() if not hunt.is_empty() else ""
	var notice_before := slot.notice
	var unsealed := slot.tick_seal()
	slot.night += 1
	slot.last_mission = id
	slot.in_night = ""
	var earned := maxi(int(d.get("earned", 0)), 0)
	var faith := earned * GodSlot.FAITH_PER_BELIEVER
	slot.faith += faith
	var dp := divine_power(d)
	var gained := slot.gain_dp(dp)
	var bests := PackedStringArray()
	if hunt.is_empty():  # a Hunt keeps no best (Ruling P2-10)
		bests = _keep_bests(slot, id, d)
	for key in drafted:
		slot.carried[key] = int(slot.carried.get(key, 0)) + 1
	slot.loadout = drafted.duplicate()
	var hunt_result := {}
	if hunt.is_empty():
		slot.add_notice(notice_delta(d))
	else:
		var won := bool(d.get("main", false))
		var bonus := 0
		if won:
			slot.notice = HUNT_WON_NOTICE
			bonus = HUNT_FAITH * slot.tier
			slot.faith += bonus
		else:
			slot.seal(target)
			slot.notice = HUNT_LOST_NOTICE
			if target != "":
				unsealed = ""  # the new seal replaces the one that just ran out (Ruling P2-9)
		hunt_result = _hunt_result(hunt, won, bonus, target)
	return {"divine_power": dp, "levels": gained.levels, "points": gained.points, "lost": gained.lost, "capped": gained.capped,
		"level": slot.level, "bar": [slot.divine_power, slot.need()], "believers": earned, "faith": faith, "faith_total": slot.faith,
		"notice": slot.notice, "notice_change": slot.notice - notice_before, "night": slot.night, "bests": bests,
		"hunt": hunt_result, "unsealed": unsealed, "hunt_next": hunt.is_empty() and slot.hunt_due()}


## The "hunt" entry of bank()'s and forfeit()'s result: the Hunt as played, how it ended, and what it sealed (spec §10.3).
static func _hunt_result(hunt: Dictionary, won: bool, bonus: int, target: String) -> Dictionary:
	return {"tier": hunt.tier, "id": hunt.id, "title": hunt.title, "won": won, "faith": bonus,
		"sealed": "" if won else target, "seal_nights": GodSlot.SEAL_NIGHTS if (target != "" and not won) else 0}


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


## A night left once its clock had started is a lost one (spec §9.1, §10, Ruling P9, P2-1): it counts, the mission is the last played,
## nothing is earned, a seal ticks, and the Notice goes up by NOTICE_LOST -- or, if the Hunt was due, the Hunt is lost: the most-carried
## ability is sealed and the Notice is set to 50 (Ruling P2-6). Returns {"night": the new count, "line": the line the hub shows,
## "notice", "notice_change", "hunt" (as bank()'s, never won), "unsealed", "hunt_next"}.
static func forfeit(slot: GodSlot) -> Dictionary:
	var hunt := hunt_for(slot)
	var target := slot.seal_target() if not hunt.is_empty() else ""
	var notice_before := slot.notice
	var unsealed := slot.tick_seal()
	slot.night += 1
	if slot.in_night != "":
		slot.last_mission = slot.in_night
	slot.in_night = ""
	var hunt_result := {}
	var line := ""
	if hunt.is_empty():
		var change := slot.add_notice(NOTICE_LOST)
		line = ABANDONED % slot.night
		if change > 0:
			line += " " + NOTICE_UP % change
		if unsealed != "":
			line += " " + UNSEALED % PowerBook.get_power(unsealed).name
	else:
		slot.seal(target)
		slot.notice = HUNT_LOST_NOTICE
		if target != "":
			unsealed = ""  # the new seal replaces the one that just ran out (Ruling P2-9)
		hunt_result = _hunt_result(hunt, false, 0, target)
		var seals := NOTHING_SEALED
		if target != "":
			seals = SEALS % [PowerBook.get_power(target).name, GodSlot.nights_text(GodSlot.SEAL_NIGHTS)]
		line = HUNT_ABANDONED % slot.night + " " + seals + " " + NOTICE_AT % slot.notice
	return {"night": slot.night, "line": line, "notice": slot.notice, "notice_change": slot.notice - notice_before,
		"hunt": hunt_result, "unsealed": unsealed, "hunt_next": hunt.is_empty() and slot.hunt_due()}
