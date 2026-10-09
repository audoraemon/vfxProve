class_name InformerDirector
extends AssassinateDirector
## The Informer (v0.11 M3, Tier 2, mission spec §3; Assassinate, reused): an informer carries the god's believers' names to the
## Temple. He keeps to cellars and back lanes -- indoors, untouchable and untagged -- until the player has worked through his four
## contacts, the chandler, the weaver, the potter and the carpenter, each a lay citizen kept on duty at his house's door (a quiet
## one: the controller's Task 4 fix ruling) with his COMPANY about him. Word reaches each contact when the informer visits: the
## chandler at VISIT_AT[0], each next at his own time or CHAIN_WAIT after the one before is turned, whichever is sooner. A Mind
## Whisper on the contact after his visit, while no one else out of doors within SPEAK_SEEN sees it (held minds see nothing), turns
## him: he names the next contact, and the last names the hiding place -- the informer bursts out of the carpenter's house and runs
## for the Temple's door, and AssassinateDirector's rules hold with no guards (a loud power within ALARM_REACH or a fright sends him
## back in to hide HIDE_SECONDS; fire on the house flushes him out; with it alight or down, an alarm sends him on). Any death of his
## wins. The names reach the Temple -- he gets in, or FOUND_LIMIT passes after the last visit without him found, well before dawn
## -- and the night is lost; so it is, "THE TRAIL GOES COLD", when a contact dies, or is gone from the town, before he is turned.
## Every contact is tagged DO NOT KILL from the start (the controller's Task 4 ruling): the one to work on bright and pointed at,
## the others pale.

## One contact (v0.11 M3): a plain record, so the director holds no cycle.
class Contact:
	extends RefCounted
	## His trade, for the banners and the tour.
	var trade := ""
	## His house, and its door, where he is kept.
	var house: Structure
	var door := Vector2.INF
	## He, and his company with each one's spot (Variants: any may be a body freed after its death fade).
	var man: Variant = null
	var company: Array = []
	var spots: Array[Vector2] = []
	## Word has reached him, and when; he is turned, and when (-1 until then).
	var word := false
	var word_at := -1.0
	var turned := false
	var turned_at := -1.0


## The contacts' points, in the order he visits them (v0.11 M3, Decision 22): behind the Temple to the north-east, the south-west
## quarter by the west wall, the south quarter west of the Main Gate's road, and east of it toward the carpenter's yard -- each a
## dwelling whose door stands in a quiet lane, clear of the soldiers' posts on ten towns of ten (the controller's Task 4 fix ruling:
## the spec's first chandler and weaver doors, by the market's corner and among the south-west's idlers, had four to six passers-by
## within SPEAK_SEEN at almost every moment, so an unseen whisper meant waiting on the traffic; its carpenter's door, by the
## south-east tower, had a wall post within sight on two towns of ten).
const CONTACT_SPOTS := [Vector2(6.0, -12.4), Vector2(-13.7, 12.6), Vector2(-1.4, 13.8), Vector2(6.2, 13.8)]
## The contacts' trades, in the same order (v0.11 M3).
const TRADES := ["chandler", "weaver", "potter", "carpenter"]
## The strip's words for the later contacts, not yet known by trade (v0.11 M3).
const ORDINALS := ["second", "third", "fourth", "fifth"]
## Where the informer lodges -- the resident nearest it, in the dwelling nearest it (v0.11 M3).
const LODGING_AT := Vector2(-3.5, -12.0)
## The Temple's door, where he takes the names (v0.11 M3): The Lost Lamb's.
const TEMPLE_DOOR := LostLambDirector.TEMPLE_DOOR
## Mission spec §3's numbers (v0.11 M3), tuned by Task 4's gate in its order: COMPANY (2-3), CHAIN_WAIT (30-45), VISIT_AT, the
## carpenter's point in CONTACT_SPOTS (the chase), HIDE_SECONDS. When word reaches each contact at the latest: the first wait 45 s,
## the last visit at 4:05, so doing nothing loses at 5:05 (FOUND_LIMIT after it), before dawn.
const VISIT_AT := [45.0, 115.0, 180.0, 245.0]
## How long after one contact is turned word reaches the next at the latest (v0.11 M3, the chain rule).
const CHAIN_WAIT := 45.0
## How many stand with each contact, and how far from his door (v0.11 M3).
const COMPANY := 3
const COMPANY_R := 1.2
## How near an onlooker sees a whisper on a contact (v0.11 M3).
const SPEAK_SEEN := 2.0
## How long after the last visit the names reach the Temple by the back lanes (v0.11 M3).
const FOUND_LIMIT := 60.0
## How long he hides once alarmed, and how near a loud cast alarms him (v0.11 M3).
const HIDE_SECONDS := 20.0
const ALARM_REACH := 4.0
## Where the camera rests (v0.11 M3, Decision 30): the Temple's door above the centre and the chandler at the top right; once each
## is the one to work on, the weaver's and the potter's arrows on the left edge below the HUD stack, and the carpenter at the bottom
## left corner. Task 7's photograph moved it from (4, -2) to (3, -3): at the old spot the chandler's tag sat 9 px above the tags'
## frame, so the first contact showed as an arrow at the top edge with his label adrift from his company's red diamonds; now his
## tag is drawn over his door.
const CAMERA_AT := Vector2(3.0, -3.0)
## The tag of the contact to work on before word reaches him is grey (v0.11 M3); once it has, orange (MARK_PLACE).
const MARK_WAITING := Color("9a948a")
## The tags of the contacts after him are pale, the same grey but faint (v0.11 M3, the controller's Task 4 ruling): warned, not
## yet the one to work on.
const MARK_PALE := Color("9a948a", 0.55)
## The banner when a whisper on a contact is seen (v0.11 M3, decision 56).
const SEEN_BANNER := "SEEN - HE SAYS NOTHING"

## The contacts, in the order he visits them (v0.11 M3).
var contacts: Array[Contact] = []
## The informer's lodging, where he waits unseen (v0.11 M3).
var lodging: Structure
## He is found (the last contact turned) (v0.11 M3).
var found := false
## The trail is cold: a contact died, or left the town, before he was turned (v0.11 M3).
var cold := false
## Seconds to the next look at the contacts and their company (v0.11 M3).
var _keep_in := 0.0


## The contacts, their company and houses; the hiding place (the carpenter's house) and the lodging; the numbers (v0.11 M3). The
## informer is the one quarry: no stops, no guards, never sent by his time (scheduled false), never smoked out.
func _plan() -> void:
	var temple := _walkable(TEMPLE_DOOR)
	var houses: Array = []
	var claimed: Array = []
	for i in CONTACT_SPOTS.size():
		var h := _contact_house(CONTACT_SPOTS[i], temple, houses)
		if h == null:
			continue
		houses.append(h)
		var c := Contact.new()
		c.trade = String(TRADES[i])
		c.house = h
		c.door = _open_door(h, temple)
		var crew := _lay_near(c.door, 1 + COMPANY, claimed)
		if crew.is_empty():
			continue
		claimed.append_array(crew)
		c.man = crew[0]
		_hold_place(crew[0], c.door)
		for k in range(1, crew.size()):
			var spot := _company_spot(c, k - 1, crew.size() - 1)
			c.company.append(crew[k])
			c.spots.append(spot)
			_hold_place(crew[k], spot)
		contacts.append(c)
	if not contacts.is_empty():
		hideout = contacts[contacts.size() - 1].house
	lodging = _house_near(LODGING_AT, houses)
	safe_at = TEMPLE_DOOR
	hide_seconds = HIDE_SECONDS
	alarm_reach = ALARM_REACH
	smoke_out = false
	hideout_label = "HIDING PLACE"
	safe_label = "TEMPLE"
	var stops: Array[Structure] = []
	var q := _add_quarry("INFORMER", 0.0, stops, 0)
	q.scheduled = false


## The night's setup (v0.11 M3): the Assassinate type's (_plan(); the informer appointed and taken in at the hiding place), then the
## hiding place's door re-chosen as one the Temple's street reaches, the informer moved to his lodging to wait unseen -- on duty
## there, so a town that evacuates while he hides never sends him running for its gates once he is found -- and each visit and the
## names' deadline put on the strip.
func _begin() -> void:
	super()
	if hideout != null:
		var door := _open_door(hideout, safe_at)
		if door != Vector2.INF:
			hide_door = door
	var q := quarries[0]
	if _alive(q.target) and lodging != null:
		q.inside_of = lodging
		q.target.ground_pos = lodging.center()
		q.target.go_duty(lodging.center())
	for i in contacts.size():
		timeline.add(float(VISIT_AT[i]), "visit_%d" % i, _visit_label(i), _visit.bind(i),
			func() -> bool: return not contacts[i].word and not cold)
	if not contacts.is_empty():
		timeline.add(float(VISIT_AT[contacts.size() - 1]) + FOUND_LIMIT, "names", "The names reach the Temple", _names_in,
			func() -> bool: return not found and not cold and quarries[0].state != State.SAFE)


## The dwelling for the contact near `spot` (v0.11 M3, the controller's Task 4 fix ruling: quiet doors): as _house_reached() picks,
## but passing over any whose door a soldier's post watches (_watched()) -- a soldier hears no whisper and feels no Discord, so one
## standing guard there would see every whisper on the contact all night (a wall post by the first carpenter's door did); the
## nearest reachable one when every house tried is watched, and null for none.
func _contact_house(spot: Vector2, from: Vector2, exclude: Array) -> Structure:
	var skip := exclude.duplicate()
	var first: Structure = null
	for i in HOUSE_TRIES:
		var h := _house_reached(spot, from, skip)
		if h == null:
			break
		if first == null:
			first = h
		if not _watched(_open_door(h, from)):
			return h
		skip.append(h)
	return first


## Some living soldier's post lies within SPEAK_SEEN of `door` (v0.11 M3). Only reads.
func _watched(door: Vector2) -> bool:
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and p.post != Vector2.INF and p.post.distance_to(door) <= SPEAK_SEEN:
			return true
	return false


## The `k`th of `n` spots for `c`'s company (v0.11 M3, pre-flight cosmetic 7): COMPANY_R from his door on a half ring facing the
## street, away from his house. A full ring round the door puts about one spot in three inside the house, and the walk grid snaps it
## off behind the house or down the lane, out of his sight (the potter's door put one 2.06 from him).
func _company_spot(c: Contact, k: int, n: int) -> Vector2:
	var out := (c.door - c.house.center()).angle()
	return _walkable(c.door + Vector2.from_angle(out + PI * ((float(k) + 0.5) / float(maxi(n, 1)) - 0.5)) * COMPANY_R)


## The resident nearest his lodging, none of the contacts nor their company (v0.11 M3, mission spec §3).
func _appoint_target(_q: Quarry) -> Person:
	return _citizen_near(LODGING_AT, CitizenProfile.Role.RESIDENT, _appointed() + _claimed())


## The contacts and their company (v0.11 M3), for the informer's choice to leave out.
func _claimed() -> Array:
	var out: Array = []
	for c in contacts:
		out.append(c.man)
		out.append_array(c.company)
	return out


## `p` set down at `at` and kept there on duty (v0.11 M3, decision 54): the town's regroup and evacuation pass him by.
func _hold_place(p: Person, at: Vector2) -> void:
	_set_down(p, at)
	p.go_duty(at)


## The night's opening banner (v0.11 M3).
func _opening_banner() -> String:
	return "FIND THE INFORMER"


## The strip's and the banner's words when word reaches contact `i` (v0.11 M3): the chandler by name; the later ones are not yet
## known, so "his second contact", "his third", "his fourth".
func _visit_label(i: int) -> String:
	if i == 0:
		return "Word reaches the %s" % contacts[i].trade
	return "Word reaches his %s contact" % ORDINALS[mini(i, ORDINALS.size()) - 1]


## Word reaches contact `i` (v0.11 M3): he can be turned now. The last one's visit starts the names' deadline, which the strip shows.
func _visit(i: int) -> void:
	var c := contacts[i]
	if c.word:
		return
	c.word = true
	c.word_at = _clock
	if i == contacts.size() - 1:
		timeline.expect("names", c.word_at + FOUND_LIMIT)


## The second into the night word reaches contact `i` at the latest (v0.11 M3, Decision 23): his own time, or CHAIN_WAIT after the
## one before was turned if that is sooner.
func visit_at(i: int) -> float:
	var at := float(VISIT_AT[i]) * timeline.stretch_factor()
	if i > 0 and contacts[i - 1].turned_at >= 0.0:
		at = minf(at, contacts[i - 1].turned_at + CHAIN_WAIT)
	return at


## Seconds until word reaches contact `i` at the latest; 0 once it has (v0.11 M3).
func visit_in(i: int) -> float:
	return 0.0 if contacts[i].word else maxf(visit_at(i) - _clock, 0.0)


## One step (v0.11 M3): the Assassinate type's (the timeline; the informer once found), then the visits' chain, the names' deadline
## and, every TICK, the contacts and their company kept at their places.
func step(delta: float) -> void:
	super(delta)
	if found or cold or contacts.is_empty():
		return
	for i in range(1, contacts.size()):
		if not contacts[i].word and contacts[i - 1].turned_at >= 0.0 and _clock >= visit_at(i):
			rules.banner.emit(_visit_label(i).to_upper())
			_visit(i)
	var last := contacts[contacts.size() - 1]
	if last.word and _clock >= last.word_at + FOUND_LIMIT and quarries[0].state != State.SAFE:
		rules.banner.emit("THE NAMES REACH THE TEMPLE")
		_names_in()
	_keep_in -= delta
	if _keep_in <= 0.0:
		_keep_in = TICK
		_keep()


## The names reach the Temple by the back lanes (v0.11 M3, Decision 28): he was not found in time. He counts as safe, so
## AssassinateObjective fails with its own reason ("names").
func _names_in() -> void:
	var q := quarries[0]
	if found or q.state == State.SAFE:
		return
	q.state = State.SAFE


## The contacts not yet turned, and their company, are kept at their places (v0.11 M3, Decision 25): one moved off (a whisper, a
## fright) walks back once on his own feet, and none is let flee the town (the final review: at the first look after it began to
## evacuate, the ones it sent running are called back; a whisper it found one under ends with him on his feet). There is no relief
## for one who falls. A contact gone from the town without a death (Crowd.escape(): his body freed at once) takes the trail with
## him as a dead one does, so the night ends at once instead of waiting out the names' deadline with nothing left to do.
func _keep() -> void:
	var evacuating := _evacuation_began()
	for c in contacts:
		if c.turned:
			continue
		if not _alive(c.man):
			_go_cold()
			return
		_back_to(c.man, c.door, evacuating)
		for k in c.company.size():
			_back_to(c.company[k], c.spots[k], evacuating)


## `v` goes back to `at`, on duty, if he stands out of doors on his own feet away from it (v0.11 M3); first he is kept from the
## town's flight (the final review, MissionDirector._keep_from_flight(): `evacuating` at the first look after it began).
func _back_to(v: Variant, at: Vector2, evacuating := false) -> void:
	if not _alive(v):
		return
	var p := v as Person
	if p.inside:
		return
	_keep_from_flight(p, evacuating)
	if not (p.mind in WarningDirector.RESUMABLE or p.mind == Person.Mind.DUTY):
		return
	if p.mind != Person.Mind.DUTY or p.anchor.distance_to(at) > GUARD_MOVE:
		p.go_duty(at)


## A power cast (v0.11 M3, Decision 24): a Mind Whisper on the contact to turn now, after his visit, turns him while no one else
## out of doors within SPEAK_SEEN sees it -- else the banner says he was seen, and nothing comes of it. The whisper is his own when
## he has just heard it (his full LINGER left), so one on a companion beside him -- or a cast near him while an older whisper still
## holds him -- neither turns him nor reads as seen. Then the Assassinate type's (once he is found, a loud cast near him alarms him;
## the hiding place is never smoked out).
func _on_cast(slot: int, key: String, at: Vector2) -> void:
	if key == "whisper" and not found and not cold:
		var c := contact_now()
		if c != null and c.word and _alive(c.man):
			var man := c.man as Person
			if man.mind == Person.Mind.WHISPERED and man.whispered_left() >= MindWhisperFx.LINGER - 0.01 \
					and at.distance_to(man.ground_pos) <= MindWhisperFx.PICK_R:
				if onlookers(c).is_empty():
					_turn(c)
				else:
					rules.banner.emit(SEEN_BANNER)
	super(slot, key, at)


## `c` is turned (v0.11 M3): he names the next contact -- the strip shows his visit's chained time -- or, the last, the hiding
## place, and the informer is found. He and his company go back to their day.
func _turn(c: Contact) -> void:
	c.turned = true
	c.turned_at = _clock
	var crew: Array = [c.man]
	crew.append_array(c.company)
	for v: Variant in crew:
		if _alive(v) and (v as Person).mind == Person.Mind.DUTY:
			crowd.off_duty(v as Person)
	var i := contacts.find(c)
	if i + 1 < contacts.size():
		var next := contacts[i + 1]
		rules.banner.emit("THE %s NAMES THE %s" % [c.trade.to_upper(), next.trade.to_upper()])
		timeline.expect("visit_%d" % (i + 1), visit_at(i + 1))
	else:
		rules.banner.emit("THE %s NAMES HIS HIDING PLACE" % c.trade.to_upper())
		_found()


## The informer is found (v0.11 M3, Decision 27): he bursts out of the hiding place and runs, on duty, for the Temple's door.
func _found() -> void:
	found = true
	var q := quarries[0]
	if q.state != State.WAITING or not _alive(q.target):
		return
	if hideout != null:
		q.inside_of = hideout
		q.target.ground_pos = hideout.center()
	_set_out(q)
	rules.banner.emit("THE INFORMER IS FOUND")


## A death in the field (v0.11 M3): a contact not yet turned takes the trail with him and the night is lost (Decision 26); then the
## Assassinate type's (the informer's death judged).
func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	for c in contacts:
		# Variant: his body may be freed by now; comparing it is safe, passing it on as a Person is not.
		var man: Variant = c.man
		if not c.turned and man == e:
			_go_cold()
	super(e, kind)


## The trail goes cold (v0.11 M3): once, with its banner.
func _go_cold() -> void:
	if cold:
		return
	cold = true
	rules.banner.emit("THE TRAIL GOES COLD")


## His seen death cries murder in the town's words (v0.11 M3 final review): he has no guards to cry it.
func _seen_banner() -> String:
	return "THE TOWN CRIES MURDER"


## The night is lost: a contact died, or left the town, before he was turned (v0.11 M3).
func lost_reason() -> String:
	return "cold" if cold else ""


## The contact to work on now: the first not yet turned; null once all are (v0.11 M3).
func contact_now() -> Contact:
	for c in contacts:
		if not c.turned:
			return c
	return null


## How many contacts are turned (v0.11 M3).
func turned_count() -> int:
	var n := 0
	for c in contacts:
		n += 1 if c.turned else 0
	return n


## Everyone who would see a whisper on `c`'s contact (v0.11 M3, Decision 24): living, out of doors, within SPEAK_SEEN of him, and
## not held by the god (MissionDirector.BLIND: a confused or whispered mind sees nothing). Only reads.
func onlookers(c: Contact) -> Array[Person]:
	var out: Array[Person] = []
	if c == null or not _alive(c.man) or (c.man as Person).inside:
		return out
	var at := (c.man as Person).ground_pos
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and p != c.man and p.is_alive() and not p.inside and not p.mind in BLIND \
					and p.ground_pos.distance_to(at) <= SPEAK_SEEN:
				out.append(p)
	return out


## The HUD's line (v0.11 M3, mission spec §3): "Find the informer: contacts turned 1 / 3" until he is found; then "Kill the
## informer", with ", he hides" while he hides and ", he runs for the Temple" while he flees with no hiding place (the place named
## from safe_label, as AssassinateObjective's own running text is: Task 1's ruling).
func hud_line() -> String:
	if not found:
		return "Find the informer: contacts turned %d / %d" % [turned_count(), contacts.size()]
	var q := quarries[0]
	if fleeing_to_safe(q):
		return "Kill the informer, he runs for the %s" % safe_label.capitalize()
	if q.state == State.FLEEING or q.state == State.HIDING:
		return "Kill the informer, he hides"
	return "Kill the informer"


## The map tags (v0.11 M3, mission spec §3, the controller's Task 4 ruling), most important first. Before he is found: the contact
## to work on, pointed at from the edge -- orange "CONTACT - DO NOT KILL" once word has reached him, grey "NO WORD YET - DO NOT
## KILL" before -- and a red diamond on everyone who would see a whisper on him; then each contact after him, pale, unpointed, "NO
## WORD YET - DO NOT KILL" (the final review: so too one whose visit has come, as he cannot be worked yet), so every contact whose
## death loses the night is warned from the start. Once found: the informer, pointed at (INFORMER, or INFORMER - INSIDE over the
## door while he hides), the Temple's door (red, pointed at) and a red diamond on whoever would see a Doom on him. None once the
## trail is cold, the names are in, or he is dead.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if cold or any_safe() or quarries.is_empty():
		return out
	var q := quarries[0]
	if found:
		if q.dead or not _alive(q.target):
			return out
		out.append(_target_tag(q))
		out.append(MapTag.place(safe_at, MARK_WATCHED, safe_label, 0.0, true))
		for p in witnesses(q):
			out.append(MapTag.person(p.ground_pos, MARK_WATCHED))
		return out
	var c := contact_now()
	if c == null:
		return out
	if _alive(c.man) and not (c.man as Person).inside:
		out.append(MapTag.person((c.man as Person).ground_pos, MARK_PLACE if c.word else MARK_WAITING, _contact_label(c), true))
		for p in onlookers(c):
			out.append(MapTag.person(p.ground_pos, MARK_WATCHED))
	for o in contacts:
		if o == c or o.turned or not _alive(o.man) or (o.man as Person).inside:
			continue
		out.append(MapTag.person((o.man as Person).ground_pos, MARK_PALE, _contact_label(o)))
	return out


## A contact's tag words (v0.11 M3, the controller's Task 4 ruling): each says plainly not to kill him; CONTACT only for the one to
## work on now once word has reached him (the final review: a later one, past his visit, cannot be worked yet).
func _contact_label(c: Contact) -> String:
	return "CONTACT - DO NOT KILL" if c.word and c == contact_now() else "NO WORD YET - DO NOT KILL"


## The hint's phase (v0.11 M3): before he is found, "waiting" while word has not reached the contact to work on, else ""; once
## found, "running" while he flees with no hiding place, "hiding" while he flees to it or hides, else "found". "" once over.
func hint_phase() -> String:
	if cold or any_safe() or quarries.is_empty():
		return ""
	var q := quarries[0]
	if found:
		if q.dead or not _alive(q.target):
			return ""
		if fleeing_to_safe(q):
			return "running"
		if q.state == State.FLEEING or q.state == State.HIDING:
			return "hiding"
		return "found"
	var c := contact_now()
	return "waiting" if c != null and not c.word else ""


## The tour (mission spec §3, the controller's ruling on Decision 26): the first contact -- how many there are, and the plain warning
## not to kill him; the Temple.
func tour() -> Array:
	var out := []
	if not contacts.is_empty() and _alive(contacts[0].man):
		var many: String = ["no", "one", "two", "three", "four", "five"][mini(contacts.size(), 5)]
		out.append([(contacts[0].man as Person).ground_pos, "The %s, first of the informer's %s contacts. Word reaches him at %s. Turn him with a whisper: do not kill him." % [
			contacts[0].trade, many, UiTheme.clock(float(VISIT_AT[0]))]])
	out.append([safe_at, "The Temple. The informer takes your believers' names here."])
	return out


## The results' report (v0.11 M3): the Assassinate type's, the contacts turned, and whether the trail went cold.
func report() -> Dictionary:
	var r := super()
	r["turned"] = turned_count()
	r["cold"] = cold
	return r
