class_name SilenceWitnessDirector
extends BellRingersDirector
## Silence the witness (god P5, MS §3, Ruling P5-12, C2, C3; Tier 2, a Lantern Hunt of the Intercept type): four witnesses who saw the god work run for
## the Temple, a witness and his two mates (a WitnessDirector, a RingerDirector with the bell taken out) from each of four quiet district houses,
## one set out after another on The Bell-Ringers' timeline and chain. The Hunt's rule: only his own mates carry the word on -- a witness killed in
## sight of one of them is replaced by that mate (`THE MATE RUNS ON`); killed in sight of anyone else, or of no one, the word dies with him. A witness
## stopped (dead with no mate to carry it, or out of the walls) counts; four stopped win (WitnessObjective); one within TempleReport.REACH of the
## Temple's door loses (`word`), warned by his countdown tag, a strip row and, at SW_NEAR_WARN seconds out, a banner. The bell does not decide it: the
## town's own bellkeeper may still ring after a seen death and that toll only turns the Lantern (MissionDef.lantern = watch).
##
## Numbers (SW_ prefix, C2: BellRingersDirector's and RingerDirector's names are never redeclared) are first guesses (*fg*) tuned by the gate; they are
## copied into the base's `tune_` vars and the witnesses' vars (MS H11). This director replaces BellRingersDirector._begin() (it builds
## RingerDirector.new()); the posts, doors and post_names the base keeps hold the houses, their doors and their names.

## Where each district's house is looked for (MS §3: one per district; the dwelling nearest, whose door the street reaches, quiet) *fg*: west,
## south-west, south-east, north-east.
const SW_HOUSE_POINTS := [Vector2(-11.5, 2.0), Vector2(-11.0, 12.5), Vector2(12.5, 12.0), Vector2(12.5, -11.0)]
## The houses' names on the banners, the strip and the tour.
const SW_HOUSE_NAMES := ["west", "south-west", "south-east", "north-east"]
## Seconds into the night each witness is sent at the latest *fg* (MS §3: 0:20, 1:15, 2:10, 3:05).
const SW_OUT_AT := [20.0, 75.0, 130.0, 185.0]
## Seconds after a witness is stopped by which the next is sent (the chain rule, MS §0).
const SW_CHAIN := 45.0
## How near a waiting house a loud power must be cast to send its witness at once (equal to the base's POST_SIGHT).
const SW_POST_SIGHT := 6.0
## Seconds the witness and his mates stand at the door before he walks.
const SW_OUT_PAUSE := 3.0
## How many mates walk with a witness.
const SW_MATES := 2
## How far behind the witness his mates walk, and stand at the door.
const SW_MATE_GAP := 1.2
## How far to either side of his way they walk *fg*: the pair 1.7 apart, more than two Silent Doom radii.
const SW_MATE_SIDE := 0.85
## The share of his own pace the witness walks at *fg* (35-50 s to the Temple).
const SW_WITNESS_PACE := 0.65
## At this many mission seconds from the Temple's door the banner `A WITNESS NEARS THE TEMPLE` shows.
const SW_NEAR_WARN := 15.0
## No beat of the town's patrols passes within this of a house's door (quiet: nobody to see him set out) -- LostLambDirector.BEATS are Aldermere's.
const SW_QUIET := 3.5
## The town's patrol beats a quiet house keeps clear of.
const SW_BEATS := LostLambDirector.BEATS
## The street from the Temple's door to a house's door, the length wanted (MS §3: 22-32 units).
const SW_STREET := Vector2(22.0, 32.0)
## How many dwellings nearest a house's point are tried for one that is quiet and at the right distance.
const SW_HOUSE_TRIES := 10
## Where the camera rests *(my call)*: the west house and the Temple on screen, the other houses' arrows clear of the HUD stack, the strip and the slots.
const SW_CAMERA_AT := Vector2(-6.5, -4.0)
## The word that reaches the Temple loses `word`.
const SW_LOST := "word"

## The witnesses stopped whose banner `THE WITNESS IS SILENT  n/4` has been shown.
var _announced: Array[bool] = []


## The numbers into the base's vars (MS H11): the witnesses' times and the chain.
func _init() -> void:
	tune_set_out_at = SW_OUT_AT.duplicate()
	tune_chain_wait = SW_CHAIN


## The night's setup (replaces BellRingersDirector._begin(), which builds RingerDirector.new()): the four houses and their doors, stone tonight, each
## with a WitnessDirector (its witness and mates inside), the times on the strip, and the casts watched. The bell tower is left as it is.
func _begin() -> void:
	var bell := crowd.bell
	var from := lantern_door()
	var keeper: Variant = bell.keeper if bell != null else null
	for i in SW_HOUSE_POINTS.size():
		var house := _witness_house(SW_HOUSE_POINTS[i], from, posts)
		if house == null:
			continue
		var door := _quiet_door(house, from)
		if door == Vector2.INF:
			door = _open_door(house, from)
		posts.append(house)
		doors.append(door)
		post_names.append(String(SW_HOUSE_NAMES[i]))
	for s in posts:
		_make_stone(s)
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	for i in posts.size():
		var r := WitnessDirector.new()
		r.post = doors[i]
		r.post_name = "THE %s HOUSE" % post_names[i].to_upper()
		r.tower = posts[i]
		r.own_keeper = keeper
		r.claimed = claimed_besides.bind(i)
		r.reserved = reserved.duplicate()
		r.tune_mates = SW_MATES
		r.tune_mate_gap = SW_MATE_GAP
		r.tune_mate_side = SW_MATE_SIDE
		r.tune_out_pause = SW_OUT_PAUSE
		r.walls_stop = true
		r.witness_pace = SW_WITNESS_PACE
		r.near_warn = SW_NEAR_WARN
		r.setup(rules, crowd, town, ctx, night)
		ringers.append(r)
		_stopped_at.append(-1.0)
		_announced.append(false)
		timeline.add(float(tune_set_out_at[i]), "out_%d" % i, _out_label(i), _send.bind(i), func() -> bool: return r.waiting)
	rules.cast_made.connect(_on_cast)
	rules.banner.emit("SILENCE THE WITNESS")


## The dwelling nearest `at` for a witness: a door the street reaches from `from` that is quiet (_quiet_door()), its street length SW_STREET, none of
## `skip`, never a wish's (_house_near()). None of the SW_HOUSE_TRIES nearest in range (Aldermere's north-east has none): the quiet one whose street
## comes closest to the range; else the first the street reaches; null for none.
func _witness_house(at: Vector2, from: Vector2, skip: Array) -> Structure:
	var tried := skip.duplicate()
	var quiet: Structure = null
	var quiet_miss := INF
	var reachable: Structure = null
	for k in SW_HOUSE_TRIES:
		var h := _house_near(at, tried)
		if h == null:
			break
		tried.append(h)
		var door := _quiet_door(h, from)
		if door != Vector2.INF:
			var run := _street(from, door)
			var miss := maxf(SW_STREET.x - run, run - SW_STREET.y)
			if miss <= 0.0:
				return h
			if miss < quiet_miss:
				quiet = h
				quiet_miss = miss
		elif reachable == null and _open_door(h, from) != Vector2.INF:
			reachable = h
	return quiet if quiet != null else reachable


## The first door of `h` -- its front, its back, then a side -- that the street reaches from `from` and that is quiet; Vector2.INF for none. Only reads.
func _quiet_door(h: Structure, from: Vector2) -> Vector2:
	var half := h.footprint.size * 0.5 + Vector2(0.5, 0.5)
	for off: Vector2 in [Vector2(0.0, half.y), Vector2(0.0, -half.y), Vector2(half.x, 0.0), Vector2(-half.x, 0.0)]:
		var door := _walkable(h.center() + off)
		if _quiet(door) and (crowd._grid == null or not crowd._grid.path(from, door).is_empty()):
			return door
	return Vector2.INF


## No beat of SW_BEATS passes within SW_QUIET of `door`. Only reads.
func _quiet(door: Vector2) -> bool:
	for b: Array in SW_BEATS:
		if Geometry2D.get_closest_point_to_segment(door, b[0], b[1]).distance_to(door) <= SW_QUIET:
			return false
	return true


## The length of the street (the walk grid's way) from `from` to `to`; INF with none.
func _street(from: Vector2, to: Vector2) -> float:
	if crowd._grid == null:
		return from.distance_to(to)
	var path := crowd._grid.path(from, to)
	if path.is_empty():
		return INF
	var n := 0.0
	var at := from
	for q in path:
		n += at.distance_to(q)
		at = q
	return n


## The strip's and the banner's words when house `i` sends its witness.
func _out_label(i: int) -> String:
	return "The %s witness sets out" % post_names[i]


## House `i` sends its witness (the timeline, the chain, or a loud power by it): the Ringer's set_out(), which the witness walks on at his pace.
func _send(i: int) -> void:
	ringers[i].set_out()


## A power cast (BellRingersDirector's rule, in the Hunt's words): a loud one within SW_POST_SIGHT of a house still waiting sends its witness at once
## ("THE WEST HOUSE SEES YOU"). Quiet powers never do.
func _on_cast(_slot: int, key: String, at: Vector2) -> void:
	if PowerBook.is_quiet(key):
		return
	for i in ringers.size():
		if ringers[i].waiting and at.distance_to(doors[i]) <= SW_POST_SIGHT:
			rules.banner.emit("THE %s HOUSE SEES YOU" % post_names[i].to_upper())
			_send(i)


## One step: the base's (the timeline, the chain, each witness), then the banner for each witness newly stopped.
func step(delta: float) -> void:
	super(delta)
	for i in ringers.size():
		if ringers[i].warning_dead and not _announced[i]:
			_announced[i] = true
			rules.banner.emit("THE WITNESS IS SILENT  %d/%d" % [stopped(), ringers.size()])


## Word has reached the Temple: a witness, alive and out of doors, within TempleReport.REACH of its door.
func word_in() -> bool:
	for r in ringers:
		if (r as WitnessDirector).in_temple:
			return true
	return false


## `word` once a witness reaches the Temple's door (WitnessObjective loses the night on it), else "".
func lost_reason() -> String:
	return SW_LOST if word_in() else ""


## The soonest of the walking witnesses to reach the Temple, in mission seconds; INF for none walking.
func word_eta() -> float:
	var best := INF
	for r in ringers:
		best = minf(best, (r as WitnessDirector).eta())
	return best


## The strip's row (MS §3): the soonest witness's time to the Temple.
func strip_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var eta := word_eta()
	if eta < INF:
		out.append({"in": eta, "label": "Word reaches the Temple"})
	return out


## The map tags (MS §3), most important first: each witness out of doors with his mates (the latest first), each house still waiting with its
## countdown (orange), the Temple's door (orange). No bellkeeper and no bell-tower tag.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for i in range(ringers.size() - 1, -1, -1):
		out.append_array(ringers[i].tags())
	for i in ringers.size():
		if ringers[i].waiting:
			out.append(MapTag.place(doors[i], MARK_POST, "WITNESS OUT IN %s" % UiTheme.clock(timeline.seconds_to("out_%d" % i)), 0.0, true))
	out.append(MapTag.place(lantern_door(), MARK_POST, "TEMPLE", 0.0, true))
	return out


## The hint's phase: "near" while a witness is within SW_NEAR_WARN of the Temple, "relay" while a mate runs on, else "" (the mission's own line).
func hint_phase() -> String:
	var best := ""
	for r in running():
		var p := r.hint_phase()
		if p == "near":
			return p
		if p == "relay":
			best = p
	return best


## The tour (MS §3): the four houses with their times (the later ones "by": the chain can bring them sooner), then the Temple's door.
func tour() -> Array:
	var out := []
	for i in posts.size():
		var when := UiTheme.clock(float(tune_set_out_at[i]))
		var line := "The %s house. Its witness walks for the Temple at %s, two mates at his heels." % [post_names[i], when]
		if i >= 1:
			line = "The %s house. Its witness comes by %s." % [post_names[i], when]
		out.append([doors[i], line])
	out.append([lantern_door(), "The Temple. A witness who reaches its door loses the night."])
	return out


## The results' report: the base's keys (stopped, relays) and the Hunt's.
func report() -> Dictionary:
	var out := super()
	out["word"] = word_in()
	out["witnesses"] = ringers.size()
	return out
