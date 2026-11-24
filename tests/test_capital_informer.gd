extends RefCounted
## Plan "The Capital at every tier", Task 6: the Informer in the Capital (spec 6.1.5). The four contacts' houses are four distinct standing dwellings
## of the old town (the ones RuinWish.fits calls a house), none the informer's lodging nor Mira's house; the town's overrides
## (src/game/town/cities/capital_missions/informer.gd) are valid and hold after setup, the Temple's door the director reads is the Capital's (the
## safe place too); the carpenter's door and the lodging each walk to it in Aldermere's band (real grid walks); the tour, goal, brief, hints
## and tags tell the truth about the Capital; the intro camera keeps the contacts clear of the padded HUD stack; the policy reads the director.

const ID := "informer"
const Cap := preload("res://tests/capital_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")
## Mira's house in the Capital, the east tenement: never a contact nor the lodging (spec 5).
const MIRA_HOUSE := Vector2(23.26, -11.25)
## Aldermere-only place words: the contacts' quarters, the carpenter's yard, the market's corner (comments of the director, never a line read).
const ALDERMERE_WORDS := ["north-east", "south-west", "south quarter", "carpenter's yard", "market's corner", "main gate", "cathedral", "east tavern"]


static func run(t) -> void:
	City.use(&"aldermere")
	Cap.overrides_valid(t, ID)
	Cap.hostable(t, ID)
	_seeded(t)
	_policy_reads_vars(t)
	var cap := Cap.town(&"capital")
	var ald := Cap.town(&"aldermere")
	var ov: Dictionary = City.by_id(&"capital").mission_overrides(ID)
	var dov: Dictionary = ov.get("director", {})
	var cs: Array = dov.get("contact_spots", [])
	var vs: Array = dov.get("visit_at", [])
	t.check(cs.size() == 4, "the Capital names four contact spots (%d)" % cs.size())
	t.check(vs.is_empty() or vs.size() == 4, "visit_at, if the Capital sets it, has one time per contact (%d)" % vs.size())
	var spots := {}
	for i in cs.size():
		spots["contact %d" % (i + 1)] = cs[i]
	Cap.spots_land(t, cap, spots, 4.0)
	Cap.spots_land(t, cap, {"lodging": dov.get("lodging_at", Vector2(INF, INF)), "Temple door": dov.get("temple_door_at", Vector2(INF, INF))}, 2.0)
	_starts(t, cap, ald)
	Cap.drop(cap)
	Cap.drop(ald)
	Cap.release()
	_camera_clear(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the Capital Informer test leaves Aldermere active")


## A fresh director holds every town var at its const; its town vars are the five; Aldermere's mission is untouched.
static func _seeded(t) -> void:
	var d := InformerDirector.new()
	t.check(d.contact_spots == InformerDirector.CONTACT_SPOTS, "a fresh director's contact_spots is CONTACT_SPOTS (Aldermere's)")
	t.check(d.lodging_at == InformerDirector.LODGING_AT, "a fresh director's lodging_at is LODGING_AT")
	t.check(d.temple_door_at == InformerDirector.TEMPLE_DOOR, "a fresh director's temple_door_at is TEMPLE_DOOR")
	t.check(d.visit_at == InformerDirector.VISIT_AT, "a fresh director's visit_at is VISIT_AT")
	t.check(d.safe_at == InformerDirector.TEMPLE_DOOR, "a fresh director's safe_at is seeded to TEMPLE_DOOR in _init()")
	t.check(Overrides.town_vars(d) == ["contact_spots", "lodging_at", "temple_door_at", "visit_at", "safe_at"], "the Informer's town vars (%s)" % [Overrides.town_vars(d)])
	t.check(InformerDirector.TRADES == ["chandler", "weaver", "potter", "carpenter"] and InformerDirector.ORDINALS[0] == "second", "TRADES and ORDINALS stay consts")
	t.check(InformerDirector.CHAIN_WAIT == 45.0 and InformerDirector.VISIT_AT == [45.0, 115.0, 180.0, 245.0], "CHAIN_WAIT and VISIT_AT are untouched")
	t.check(MissionBook.informer().camera_at == InformerDirector.CAMERA_AT, "Aldermere's camera is still CAMERA_AT")
	# The other Assassinate missions do not take the Informer's seed: each assigns its safe place in _plan() as before.
	t.check(AssassinateDirector.new().safe_at == Vector2.INF
		and TaxCollectorDirector.new().safe_at == Vector2.INF, "the other Assassinate missions' safe_at starts unset, as it did")


## Source without its `#` comments, so a const named in a comment is not a read.
static func _code(src: String) -> String:
	var out := PackedStringArray()
	for line in src.split("\n"):
		var at := line.find("#")
		out.append(line.substr(0, at) if at >= 0 else line)
	return "\n".join(out)


## _plan, _begin, the lodging's resident, the visits and the tour read the vars; the policy reads the director, no const and no TownLayout coordinate.
static func _policy_reads_vars(t) -> void:
	var src := FileAccess.get_file_as_string("res://src/game/mission/informer_director.gd")
	var at := src.find("func _init()")
	var body := _code(src.substr(at)) if at >= 0 else ""
	t.check(at >= 0 and body.length() > 3000, "the Informer's code after its consts is found and sliced (%d chars)" % body.length())
	var bad := false
	for c in ["CONTACT_SPOTS", "LODGING_AT", "TEMPLE_DOOR", "VISIT_AT", "TownLayout."]:
		bad = bad or c in body
	t.check(not bad, "the Informer reads its places and times from the vars, not the consts")
	t.check("temple_door_at" in body and "contact_spots" in body and "lodging_at" in body and "visit_at" in body, "the Informer reads all four vars")
	var plan_at := src.find("func _plan()")
	var plan_end := src.find("\nfunc _begin()")
	t.check(plan_at >= 0 and plan_end > plan_at, "_plan is found and sliced")
	var plan := _code(src.substr(plan_at, plan_end - plan_at)) if plan_at >= 0 and plan_end > plan_at else ""
	t.check(plan.length() > 500 and not "safe_at =" in plan, "_plan no longer assigns safe_at (it is seeded in _init())")
	var bc := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd")
	var policy := ""
	var found := true
	var fns := ["func _informer(", "func _informer_act(", "func _informer_takes_contact(", "func _informer_discord(", "func _informer_off("]
	for fn: String in fns:
		var f := bc.find(fn)
		found = found and f >= 0
		if f < 0:
			continue
		var rest := bc.substr(f + fn.length())
		var end := rest.find("\nfunc ")
		found = found and end > 0
		policy += rest.substr(0, end) if end > 0 else ""
	policy = _code(policy)
	t.check(found and policy.length() > 1500, "the informer policy functions are all found and sliced (%d chars)" % policy.length())
	t.check(not "CONTACT_SPOTS" in policy and not "LODGING_AT" in policy and not "TEMPLE_DOOR" in policy and not "VISIT_AT" in policy
		and not "TownLayout." in policy and not "CAMERA_AT" in policy, "the informer policy reads no place const, CAMERA_AT or TownLayout coordinate")


static func _starts(t, cap: Dictionary, ald: Dictionary) -> void:
	var ov: Dictionary = City.by_id(&"capital").mission_overrides(ID)
	var dov: Dictionary = ov.get("director", {})
	var d := Cap.starts(t, ID) as InformerDirector
	if d == null:
		return
	t.check(d.contact_spots == dov.get("contact_spots", []) and d.lodging_at == dov.get("lodging_at", Vector2.INF)
		and d.temple_door_at == dov.get("temple_door_at", Vector2.INF), "the director reads back the Capital's contact spots, lodging and Temple door after setup")
	t.check(d.safe_at.distance_to(dov.get("safe_at", Vector2.INF)) < 1.5 and dov.get("safe_at", Vector2.INF) == dov.get("temple_door_at", Vector2.INF),
		"the safe place is the Capital's Temple door (%s) and survives setup (%s)" % [dov.get("safe_at"), d.safe_at])
	if dov.has("visit_at"):
		t.check(d.visit_at == dov.visit_at, "the director reads back the Capital's visit times")
	var def := MissionBook.get_mission("%s@capital" % ID)
	t.check(def.camera_at == Vector2(2.0, -10.0) and def.intro_from == Vector2(2.0, -4.0), "camera_at and intro_from are overridden together (C9)")
	t.check(d.contacts.size() == 4 and d.lodging != null, "four contacts stand, with a lodging (%d)" % d.contacts.size())
	t.check(d.visit_at.size() == d.contacts.size(), "one visit time per contact (%d for %d)" % [d.visit_at.size(), d.contacts.size()])
	if d.contacts.size() != 4 or d.lodging == null:
		return
	_spots_land(t, d)
	_walk_parity(t, d, cap, ald)
	City.use(&"capital")
	_words_true(t, d, def)


## Four distinct dwellings RuinWish.fits calls a house, standing, none the lodging, none Mira's house; each near the spot it was asked for;
## each contact's door a walkable place with his company about it.
static func _spots_land(t, d: InformerDirector) -> void:
	var distinct := {}
	for i in d.contacts.size():
		var c: InformerDirector.Contact = d.contacts[i]
		distinct[c.house] = true
		var at: Vector2 = d.contact_spots[i]
		t.check(RuinWish.fits(c.house, "house") and not c.house.destroyed, "%s's house %s is a standing dwelling" % [c.trade, c.house.center()])
		t.check(c.house != d.lodging, "%s's house is not the lodging" % c.trade)
		t.check(c.house.center().distance_to(MIRA_HOUSE) > 1.0, "%s's house is not Mira's house" % c.trade)
		t.check(c.house.center().distance_to(at) <= 3.5, "%s's house %s is near his spot %s (%.1f)" % [c.trade, c.house.center(), at, c.house.center().distance_to(at)])
		t.check(c.door != Vector2.INF and c.man != null and c.company.size() == InformerDirector.COMPANY, "%s has his door and his company of %d" % [c.trade, InformerDirector.COMPANY])
		print("CAPITAL informer contact %d %s: house %s door %s" % [i + 1, c.trade, c.house.center(), c.door])
	t.check(distinct.size() == 4, "the four contacts are four distinct houses (%d)" % distinct.size())
	t.check(RuinWish.fits(d.lodging, "house") and d.lodging.center().distance_to(MIRA_HOUSE) > 1.0, "the lodging is a standing dwelling, not Mira's house")
	print("CAPITAL informer lodging %s, Temple door %s" % [d.lodging.center(), d.safe_at])
	t.check(d.hideout == d.contacts[d.contacts.size() - 1].house, "the carpenter's house is the hiding place")
	var q: AssassinateDirector.Quarry = d.quarries[0]
	t.check(q.target != null and q.inside_of == d.lodging, "the informer waits in his lodging")
	var points: Array = []
	for c: InformerDirector.Contact in d.contacts:
		points.append(c.door)
	Cap.spread(t, points)


## The carpenter's door to the Temple door, and the lodging to the door, Capital against Aldermere on the real grids (band 0.75-1.35).
static func _walk_parity(t, d: InformerDirector, cap: Dictionary, ald: Dictionary) -> void:
	City.use(&"aldermere")
	var a := Kit.world(MissionBook.informer())
	var ad: InformerDirector = a.d
	t.check(ad.hide_door != Vector2.INF and ad.lodging != null, "Aldermere's informer has his hiding place and lodging")
	Cap.parity(t, "the carpenter's door to the Temple door", Cap.walk(cap.grid, d.hide_door, d.safe_at), Cap.walk(ald.grid, ad.hide_door, ad.safe_at))
	Cap.parity(t, "the lodging to the Temple door", Cap.walk(cap.grid, d.lodging.center(), d.safe_at), Cap.walk(ald.grid, ad.lodging.center(), ad.safe_at))
	Kit.done(a)
	City.use(&"capital")


## Every line the player reads in the Capital names no place of Aldermere; Aldermere's own words are unchanged.
static func _words_true(t, d: InformerDirector, def: MissionDef) -> void:
	var said := PackedStringArray()
	for stop: Array in d.tour():
		said.append(String(stop[1]))
	var read := PackedStringArray(said)
	read.append_array(def.brief)
	read.append_array([def.goal, def.goal_label, def.lose])
	for key in ["", ".waiting", ".found", ".hiding", ".running"]:
		read.append(String(MissionHints.LINES.get(ID + key, "")))
	for tag: MapTag in d.tags():
		read.append(tag.label)
	t.check(said.size() == 2 and def.brief.size() == 2 and read.size() >= 13 and not String(read[0]).is_empty(), "the Capital's lines are found (%d, %d tour stops)" % [read.size(), said.size()])
	var wrong: Array = []
	for line in read:
		for place in ALDERMERE_WORDS:
			if place in String(line).to_lower():
				wrong.append(line)
	t.check(wrong.is_empty(), "no line the player reads in the Capital names a place of Aldermere (%s)" % [wrong])
	t.check(said.size() == 2 and "chandler" in said[0] and "four" in said[0] and "Temple" in said[1], "the tour names the chandler, his four contacts, and the Temple (%s)" % [said])
	var ald := MissionBook.get_mission(ID)
	t.check(ald.brief.size() == 2 and ald.brief[0] == "An informer carries your believers' names." and ald.brief[1] == "Find him by his contacts. Kill him."
		and ald.goal == def.goal and ald.lose == def.lose and ald.camera_at == InformerDirector.CAMERA_AT
		and String(MissionHints.LINES.get(ID, "")).begins_with("Whisper or Discord the contact"), "Aldermere's own board lines and camera are unchanged")


## Every contact's arrow, the Temple's door and the hiding place are clear of the padded HUD stack at the camera's resting place and at the intro's start.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := MissionBook.get_mission("%s@capital" % ID)
	var cap := Cap.town(&"capital")
	var d := Cap.starts(t, ID) as InformerDirector
	var at: Array = [d.safe_at]
	for c: InformerDirector.Contact in d.contacts:
		at.append(c.door)
	Cap.camera_clear(t, def, at)
	Cap.release()
	Cap.drop(cap)
	City.use(&"aldermere")
