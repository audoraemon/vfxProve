class_name TaxCollectorDirector
extends AssassinateDirector
## The Tax Collector (v0.11 M2, Tier 1, spec §1 and §8 row 2, as the controller's Task 2 ruling reshapes it): three collectors
## -- the tax collector and his two deputies, the residents nearest the counting-house, made nobles for the night so their
## capes and crowns pick them out -- count in the counting-house (the workshop hall, east quarter) with their guards at its
## door. The collector walks his round of three debtors' houses from 0:45; each deputy walks his own two at his own time, or
## CHAIN_WAIT after the one before him dies, whichever is sooner. 25 s indoors at each debtor, then each takes the taxes to
## the Citadel's gate, which loses the night. Alarmed one hides 30 s in the counting-house. All three dead wins; a seen kill
## calls the bell (AssassinateDirector._judge()).

## The counting-house is the building with this art tag (v0.11 M2).
const COUNTING_TAG := &"workshop"
## Each collector's debtors live in the dwellings nearest these points whose doors the street reaches (_house_reached()), in
## his order (v0.11 M2): the collector's the south-east quarter by the gate plaza, the south-west and the west (spec §1); the
## first deputy's the north-east and the north-west blocks; the second deputy's the east block by the barracks and the south
## quarter.
const ROUNDS := [
	[Vector2(6.5, 11.5), Vector2(-8.0, 11.5), Vector2(-10.0, 2.5)],
	[Vector2(6.0, -10.4), Vector2(-3.4, -10.4)],
	[Vector2(6.2, 5.4), Vector2(-3.5, 12.5), Vector2(-7.6, 5.4)],
]
## The tags' words for each collector (v0.11 M2).
const LABELS := ["TAX COLLECTOR", "DEPUTY", "DEPUTY"]
## The Citadel's gate (v0.11 M2), where the taxes go: RescueWish.GATE's point.
const CITADEL_GATE := RescueWish.GATE
## First guesses (spec §1 and the ruling), tuned in this order if the scripted clear misses its window (v0.11 M2): when each
## collector sets out at the latest; how long after one dies the next sets out at the latest (30-50 s); a visit; a hiding;
## the alarm's reach; how many guards walk with each, and how near.
const SET_OUT_AT := [45.0, 105.0, 165.0]
const CHAIN_WAIT := 45.0
const VISIT_SECONDS := 15.0
const HIDE_SECONDS := 30.0
const ALARM_REACH := 4.0
const GUARDS := [2, 1, 1]
const GUARD_R := 0.6


## The counting-house, the three collectors' rounds and the numbers (v0.11 M2).
func _plan() -> void:
	hideout = _counting_house()
	var door := _front_of(hideout)
	var taken: Array = [hideout]
	for i in ROUNDS.size():
		var stops: Array[Structure] = []
		for spot: Vector2 in ROUNDS[i]:
			var h := _house_reached(spot, door, taken)
			if h != null:
				stops.append(h)
				taken.append(h)
		_add_quarry(String(LABELS[i]), float(SET_OUT_AT[i]), stops, int(GUARDS[i]))
	safe_at = CITADEL_GATE
	visit_seconds = VISIT_SECONDS
	hide_seconds = HIDE_SECONDS
	alarm_reach = ALARM_REACH
	guard_r = GUARD_R
	chain_wait = CHAIN_WAIT
	hideout_label = "COUNTING-HOUSE"
	stop_label = "DEBTOR"
	safe_label = "CITADEL"
	next_label = "NEXT COLLECTOR"


## The workshop hall; else the dwelling nearest it (v0.11 M2). A wish never takes it: Ruin wishes take only plain dwellings and
## towers.
func _counting_house() -> Structure:
	for s: Structure in town._built:
		if is_instance_valid(s) and s.art_tag == COUNTING_TAG and not s.destroyed:
			return s
	return _house_near(TownLayout.WORKSHOP.get_center())


## The resident nearest the counting-house's door not yet a collector, made a noble for the night (v0.11 M2).
func _appoint_target(_q: Quarry) -> Person:
	var p := _citizen_near(hide_door, CitizenProfile.Role.RESIDENT)
	if p != null:
		p.profile.role = CitizenProfile.Role.NOBLE
	return p


## The night's opening banner (v0.11 M2).
func _opening_banner() -> String:
	return "THE TAX COLLECTORS MAKE THEIR ROUNDS"


## The strip's and the banner's words when `q` sets out (v0.11 M2).
func _set_out_label(q: Quarry) -> String:
	return "The tax collector sets out" if q.index == 0 else "A deputy sets out"


## The banner when `q` is alarmed and hides (v0.11 M2).
func _hide_banner(q: Quarry) -> String:
	return "THE TAX COLLECTOR HIDES" if q.index == 0 else "A DEPUTY HIDES"


## The banner when a collector reaches the Citadel's gate (v0.11 M2).
func _safe_banner() -> String:
	return "THE TAXES ARE IN"


## The tour (spec §1, v0.11 M2): the counting-house and when they set out (the deputies "by" their times: the chain can bring
## them sooner), the collector's first debtor, the Citadel.
func tour() -> Array:
	var out := []
	if hide_door != Vector2.INF:
		out.append([hide_door, "The counting-house. The tax collector sets out at %s, his deputies by %s and %s." % [
			UiTheme.clock(SET_OUT_AT[0]), UiTheme.clock(SET_OUT_AT[1]), UiTheme.clock(SET_OUT_AT[2])]])
	if not quarries.is_empty() and not quarries[0].stop_doors.is_empty():
		out.append([quarries[0].stop_doors[0], "His first debtor. He goes in to collect, then walks on."])
	if safe_at != Vector2.INF:
		out.append([safe_at, "The Citadel. A collector whose rounds are done takes the taxes in."])
	return out
