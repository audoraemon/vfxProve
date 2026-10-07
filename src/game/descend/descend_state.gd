class_name DescendState
extends RefCounted
## Where the god stands on the tier board (v0.11 M1, spec §3): the nights played, the believers banked, the highest tier
## open, the missions cleared, the upgrades bought and the powers unlocked, and each mission's bests. It is the save's
## [descend] section; [campaign] is the Lantern campaign's and never touched here.

const SECTION := "descend"
## The upgrades (spec §3.4, first guesses): the n-th +1 DP costs DP_STEP x n believers, DP_LIMIT at most; the one +1 slot
## costs SLOT_PRICE; unlocking a power costs UNLOCK_PER_DP x its DP. A power costing STARTING_DP or less starts unlocked.
const DP_STEP := 25
const DP_LIMIT := 6
const SLOT_PRICE := 150
const SLOT_LIMIT := 1
const UNLOCK_PER_DP := 15
const STARTING_DP := 2
## The v0.10 board missions whose wins carry over to their ★ missions as cleared (spec §3.5).
const CARRIED := ["warning", "long_night", "last_judgement"]

## Board nights played to their end, won or lost (spec §3.3).
var night := 0
var believers := 0
## The highest tier open (spec §3.2); a tier never closes again.
var open_tier := 1
## Missions whose main objective was done in some night, ascended or caught after it.
var cleared := PackedStringArray()
var dp_bought := 0
var slot_bought := 0
## Powers bought on the Upgrades screen; the starting ones are never listed.
var unlocked := PackedStringArray()
## Per mission (spec §3.5): seconds from the night's start to its main objective at its fastest clear, and the most wishes
## granted and banked in one night.
var fastest := {}
var most_wishes := {}


## The power starts unlocked: it costs STARTING_DP or less (15 of today's 38).
static func starting(key: String) -> bool:
	var p := PowerBook.get_power(key)
	return not p.is_empty() and int(p.dp) <= STARTING_DP


func is_unlocked(key: String) -> bool:
	return starting(key) or unlocked.has(key)


## Every power still locked, in PowerBook's order: greyed in the board's draft (spec §3.4).
func locked() -> PackedStringArray:
	var out := PackedStringArray()
	for key in PowerBook.keys():
		if not is_unlocked(key):
			out.append(key)
	return out


## The next +1 DP's price: DP_STEP x n for the n-th.
func dp_price() -> int:
	return DP_STEP * (dp_bought + 1)


static func unlock_price(key: String) -> int:
	return UNLOCK_PER_DP * int(PowerBook.get_power(key).get("dp", 0))


## What `what` costs: "dp", "slot", or a power key.
func price(what: String) -> int:
	match what:
		"dp":
			return dp_price()
		"slot":
			return SLOT_PRICE
	return unlock_price(what)


## Why `what` cannot be bought, or "" when it can: "limit" (none left to buy), "unknown" (no such power), "owned" (a power
## already unlocked), "believers" (too few).
func refusal(what: String) -> String:
	if what == "dp":
		if dp_bought >= DP_LIMIT:
			return "limit"
	elif what == "slot":
		if slot_bought >= SLOT_LIMIT:
			return "limit"
	elif PowerBook.get_power(what).is_empty():
		return "unknown"
	elif is_unlocked(what):
		return "owned"
	if believers < price(what):
		return "believers"
	return ""


## Buys `what`, spending its price; false, and nothing spent, when refusal() says why not.
func buy(what: String) -> bool:
	if refusal(what) != "":
		return false
	believers -= price(what)
	match what:
		"dp":
			dp_bought += 1
		"slot":
			slot_bought += 1
		_:
			unlocked.append(what)
	return true


## How many of `tier`'s missions are cleared.
func cleared_in(tier: int) -> int:
	var n := 0
	for id in TierBook.missions(tier):
		n += 1 if cleared.has(id) else 0
	return n


func is_open(tier: int) -> bool:
	return tier >= 1 and tier <= open_tier


## Opens every tier the rule now opens (spec §3.2: Tier T+1 once TierBook.need(T) of Tier T's missions are cleared), never
## closing one. Returns the highest tier newly opened, or 0.
func refresh_open() -> int:
	var was := open_tier
	while open_tier < TierBook.NAMES.size() and cleared_in(open_tier) >= TierBook.need(open_tier):
		open_tier += 1
	return open_tier if open_tier > was else 0


## A locked tier's rule (spec §3.1): "Clear 3 Omen missions" -- how many of the tier before it.
static func lock_text(tier: int) -> String:
	var n := TierBook.need(tier - 1)
	return "Clear %d %s mission%s" % [n, TierBook.tier_name(tier - 1), "" if n == 1 else "s"]


## The results' tier line (spec §6): "Omen 1 / 2 cleared: one more opens Wrath", "...: Wrath is open", or for the last tier
## its count alone.
func progress_line(tier: int) -> String:
	var n := cleared_in(tier)
	var need := TierBook.need(tier)
	var head := "%s %d / %d cleared" % [TierBook.tier_name(tier), mini(n, need), need]
	if tier >= TierBook.NAMES.size():
		return head
	var next := TierBook.tier_name(tier + 1)
	if is_open(tier + 1):
		return "%s: %s is open" % [head, next]
	var left := need - n
	return "%s: %s" % [head, ("one more opens " + next) if left == 1 else ("%d more open %s" % [left, next])]


## Banks a finished board night for the mission `id` (spec §3.3, §6) and returns what changed, for the results. `outcome` is
## Descent.report()'s "descend": `main` (its main objective done), `main_time` (seconds from the night's start to it),
## `earned` (the believers it banks; Descent has already counted a loss or a caught night out) and `kept` (wishes granted and
## banked). Every night counts, won or lost.
func bank(id: String, outcome: Dictionary) -> Dictionary:
	night += 1
	var earned := maxi(int(outcome.get("earned", 0)), 0)
	believers += earned
	var main := bool(outcome.get("main", false))
	var first := main and not cleared.has(id)
	if first:
		cleared.append(id)
	var bests := PackedStringArray()
	var time := float(outcome.get("main_time", 0.0))
	if main and time > 0.0 and (not fastest.has(id) or time < float(fastest[id])):
		fastest[id] = time
		bests.append("Fastest clear %s" % UiTheme.clock(time))
	var kept := int(outcome.get("kept", 0))
	if kept > int(most_wishes.get(id, 0)):
		most_wishes[id] = kept
		bests.append("Most wishes granted: %d" % kept)
	var opened := refresh_open()
	return {"believers": earned, "total": believers, "night": night, "cleared": main, "first_clear": first, "opened": opened,
		"progress": progress_line(maxi(TierBook.tier_of(id), 1)), "bests": bests}


func write(cfg: ConfigFile) -> void:
	cfg.set_value(SECTION, "night", night)
	cfg.set_value(SECTION, "believers", believers)
	cfg.set_value(SECTION, "open_tier", open_tier)
	cfg.set_value(SECTION, "cleared", cleared)
	cfg.set_value(SECTION, "dp_bought", dp_bought)
	cfg.set_value(SECTION, "slot_bought", slot_bought)
	cfg.set_value(SECTION, "unlocked", unlocked)
	cfg.set_value(SECTION, "fastest", fastest)
	cfg.set_value(SECTION, "most_wishes", most_wishes)


## The board as the file holds it (spec §3.5); a fresh board when the file has no [descend] section. A hand-edited value out
## of range is pulled back into it, and an unknown mission or power is dropped.
static func read(cfg: ConfigFile) -> DescendState:
	var s := DescendState.new()
	if not cfg.has_section(SECTION):
		return s
	s.night = maxi(int(cfg.get_value(SECTION, "night", 0)), 0)
	s.believers = maxi(int(cfg.get_value(SECTION, "believers", 0)), 0)
	s.open_tier = clampi(int(cfg.get_value(SECTION, "open_tier", 1)), 1, TierBook.NAMES.size())
	for id in _strings(cfg.get_value(SECTION, "cleared", PackedStringArray())):
		if TierBook.has(id) and not s.cleared.has(id):
			s.cleared.append(id)
	s.dp_bought = clampi(int(cfg.get_value(SECTION, "dp_bought", 0)), 0, DP_LIMIT)
	s.slot_bought = clampi(int(cfg.get_value(SECTION, "slot_bought", 0)), 0, SLOT_LIMIT)
	for key in _strings(cfg.get_value(SECTION, "unlocked", PackedStringArray())):
		if not PowerBook.get_power(key).is_empty() and not starting(key) and not s.unlocked.has(key):
			s.unlocked.append(key)
	var times = cfg.get_value(SECTION, "fastest", {})
	if times is Dictionary:
		for id in times:
			if TierBook.has(String(id)) and (times[id] is float or times[id] is int) and float(times[id]) > 0.0:
				s.fastest[String(id)] = float(times[id])
	var counts = cfg.get_value(SECTION, "most_wishes", {})
	if counts is Dictionary:
		for id in counts:
			if TierBook.has(String(id)) and counts[id] is int:
				s.most_wishes[String(id)] = maxi(int(counts[id]), 0)
	s.refresh_open()
	return s


## A list read from the file, as strings; anything else reads as none.
static func _strings(v: Variant) -> PackedStringArray:
	return PackedStringArray(v) if v is PackedStringArray or v is Array else PackedStringArray()


## A v0.10 save, with no [descend] section (spec §3.5): its board wins of The Warning, The Long Night and Last Judgement
## carry over to their ★ missions as cleared, and the tiers open by the rule. v0.10 kept no times, so no fastest clear comes.
func carry_over(save: SaveFile) -> void:
	for id: String in CARRIED:
		if bool(save.best(id).get("won", false)) and not cleared.has(id):
			cleared.append(id)
	refresh_open()
