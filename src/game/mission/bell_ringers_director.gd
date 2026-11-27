class_name BellRingersDirector
extends MissionDirector
## The Bell-Ringers (v0.11 M3, Tier 2, mission spec §1; Intercept, after StarfallDirector's pattern, which is untouched): three
## watch posts on the walls -- the wall towers nearest POST_SPOTS, never a reserved one, each with a town-side door the bell's
## foot reaches -- send a ringer each for the bell, his mates (RingerDirector.MATES) at his heels. The north-east post sends its
## ringer at SET_OUT_AT[0]; each next post at its own time or CHAIN_WAIT after the warning before it is stopped, whichever is
## sooner; a loud power cast within POST_SIGHT of a waiting post sends its ringer at once. Each warning is a RingerDirector (The
## Warning's relay and unseen kill; the ringer rings the bell himself); a relay never picks another warning's people
## (claimed_besides()). The posts and the bell tower are stone tonight: a blow only shakes them. All three warnings stopped wins
## (StarsObjective). v0.11.2: the bell tolling -- rung by a ringer, a relay or the town's own bellkeeper -- does not lose: it turns the Lantern and the ringer
## who rang runs for the Temple as the Herald (HeraldObjective loses the night only if one gets in). The posts' times (SET_OUT_AT, CHAIN_WAIT) are MISSION seconds.

## Where the posts stand (the wall tower nearest each) (v0.11 M3, mission spec §1).
const POST_SPOTS := [Vector2(6.6, -15.65), Vector2(-8.0, 15.65), Vector2(15.65, -8.0)]
## The names a town's overrides may set (Overrides, v0.12): the town vars below, seeded from POST_SPOTS, POST_NAMES and SET_OUT_AT; setup reads them and never assigns them.
const TOWN_VARS := ["post_spots", "post_names", "set_out_at"]
## The posts' names on the banners, the strip and the tour (v0.11 M3).
const POST_NAMES := ["north-east", "south-west", "east"]
## Seconds into the night each post sends its ringer at the latest (v0.11 M3, Decision 8): the spec's first guesses, kept by Task
## 2's gate. The knobs it may tune are these (the first at most 40), RingerDirector.OUT_PAUSE, the mates' spacing and POST_SIGHT.
const SET_OUT_AT := [40.0, 110.0, 180.0]
## Seconds after a warning is stopped by which the next post sends its ringer (v0.11 M3, the chain rule; Decision 8).
const CHAIN_WAIT := 45.0
## How near a waiting post a loud power must be cast to send its ringer at once (v0.11 M3, Decision 9).
const POST_SIGHT := 6.0
## How many of the towers nearest a spot are tried for one whose door the bell's foot reaches (v0.11 M3, Decision 4).
const TOWER_TRIES := 6
## How hard a blow shakes the posts and the bell tower (v0.11 M3, Decision 5).
const STONE_SHAKE := 2.0
## Where the camera rests (v0.11 M3, Decision 30): the north-east post top right, the bell tower below the centre, the east post
## at the right; the south-west post's arrow on the left edge, below the HUD stack.
const CAMERA_AT := Vector2(6.0, -5.0)
## A waiting post's tag colour, orange (v0.11 M3); the next post and the carriers are gold, the tower red and the town's
## bellkeeper steel blue (WarningDirector's).
const MARK_POST := Color("ff9a3a")

## Where this town's posts stand (a town var, POST_SPOTS in Aldermere): the wall tower nearest each.
var post_spots: Array = POST_SPOTS
## The posts' towers, in the order their ringers set out (v0.11 M3).
var posts: Array[Structure] = []
## Each post's door, where its ringer and his mates come out (v0.11 M3).
var doors: Array[Vector2] = []
## Each post's name (v0.11 M3): "north-east", "south-west", "east" in Aldermere (a town var, POST_NAMES). Seeded here from the const as the town's words;
## _begin keeps the names of the posts that stand, in their order.
var post_names: Array[String] = []
## The numbers a Lantern Hunt changes (god P5, MS H11, Ruling C1), each equal to its const and read in its place: when each post sends its ringer,
var tune_set_out_at: Array = SET_OUT_AT.duplicate()
## The town's name for it (a town var, SET_OUT_AT in Aldermere): the same array, so an override and a Hunt's change are one.
var set_out_at: Array:
	get:
		return tune_set_out_at
	set(v):
		tune_set_out_at = v
## and the seconds after the warning before it is stopped that the next post sends at the latest.
var tune_chain_wait := CHAIN_WAIT
## Each post's warning (v0.11 M3), set up at the start: its ringer and his mates wait inside until sent.
var ringers: Array[RingerDirector] = []
## The night's second each warning was first seen stopped, or -1 (v0.11 M3).
var _stopped_at: Array[float] = []
## The posts and the bell tower made stone tonight, given back at teardown (v0.11 M3, Decision 5).
var _stone: Array[Structure] = []
## Mission seconds into the night (v0.11 M3; v0.11.2: the posts' schedule runs on the mission clock's rate, a ringer's walk and stand are real time).
var _clock := 0.0


## Seeds the town's post names from the const (the town var: setup keeps those of the posts that stand).
func _init() -> void:
	post_names.assign(POST_NAMES)


## The night's setup (v0.11 M3): the three posts and their doors, the stone, each post's ringer and mates taken inside its tower,
## the ringers' times on the strip, and the casts watched.
func _begin() -> void:
	var bell := crowd.bell
	var foot := bell.foot if bell != null else _walkable(Places.at(&"bell_tower"))
	var words: Array[String] = post_names.duplicate()
	post_names.clear()
	for i in post_spots.size():
		var tried: Array = []
		tried.append_array(posts)
		for k in TOWER_TRIES:
			var tower := _tower_near(post_spots[i], tried)
			if tower == null:
				break
			var door := _town_door(tower, foot)
			if door != Vector2.INF:
				posts.append(tower)
				doors.append(door)
				post_names.append(String(words[i]))
				break
			tried.append(tower)
	for s in posts:
		_make_stone(s)
	if bell != null and is_instance_valid(bell.tower):
		_make_stone(bell.tower)
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	var keeper: Variant = bell.keeper if bell != null else null
	for i in posts.size():
		var r := RingerDirector.new()
		r.post = doors[i]
		r.post_name = "THE %s POST" % post_names[i].to_upper()
		r.tower = posts[i]
		r.own_keeper = keeper
		r.claimed = claimed_besides.bind(i)
		r.reserved = reserved.duplicate()
		r.setup(rules, crowd, town, ctx, night)
		ringers.append(r)
		_stopped_at.append(-1.0)
		timeline.add(float(tune_set_out_at[i]), "out_%d" % i, _out_label(i), _send.bind(i), func() -> bool: return r.waiting)
	rules.cast_made.connect(_on_cast)
	rules.banner.emit("THE WATCH POSTS ARE MANNED")


## The standing wall tower nearest `spot` (v0.11 M3: RuinWish.fits(s, "tower"), never the bell tower), not reserved (the
## watchtower wish's) and none of `exclude`; null for none.
func _tower_near(spot: Vector2, exclude: Array) -> Structure:
	var best: Structure = null
	for s: Structure in town._built:
		if not is_instance_valid(s) or s.destroyed or not RuinWish.fits(s, "tower") or reserved_places.has(s) or exclude.has(s):
			continue
		if best == null or s.center().distance_squared_to(spot) < best.center().distance_squared_to(spot):
			best = s
	return best


## `tower`'s town-side door (v0.11 M3, controller ruling on Decision 4): free ground off the face turned most toward the town's
## middle, if the bell's foot reaches it -- so no ringer starts outside the wall, and the east post's run is the shortest; else
## _open_door()'s first face with a route (Vector2.INF for none).
func _town_door(tower: Structure, foot: Vector2) -> Vector2:
	var half := tower.footprint.size * 0.5 + Vector2(0.5, 0.5)
	var inward := tower.center().direction_to(City.current().town().get_center())
	var best := Vector2.ZERO
	for off: Vector2 in [Vector2(0.0, half.y), Vector2(0.0, -half.y), Vector2(half.x, 0.0), Vector2(-half.x, 0.0)]:
		if best == Vector2.ZERO or off.normalized().dot(inward) > best.normalized().dot(inward):
			best = off
	var door := _walkable(tower.center() + best)
	if crowd._grid == null or not crowd._grid.path(foot, door).is_empty():
		return door
	return _open_door(tower, foot)


## `s` is stone tonight (v0.11 M3): every blow only shakes it, until teardown.
func _make_stone(s: Structure) -> void:
	s.damage_filter = _stone_hit
	_stone.append(s)


## Structure.damage_filter for the stone (v0.11 M3).
func _stone_hit(s: Structure, _amount: float, _source: Vector2, _kind: StringName) -> void:
	s.shake(STONE_SHAKE)


## The strip's and the banner's words when post `i` sends its ringer (v0.11 M3).
func _out_label(i: int) -> String:
	return "The %s post sends its ringer" % post_names[i]


## Post `i` sends its ringer (v0.11 M3): its time on the timeline, the chain, or a loud power by the post.
func _send(i: int) -> void:
	ringers[i].set_out()


## The people every warning but post `i`'s owns (v0.11 M3, controller ruling): their ringers, carriers and mates, as Variants.
## Post `i`'s relay never picks one of them (RingerDirector.claimed).
func claimed_besides(i: int) -> Array:
	var out: Array = []
	for k in ringers.size():
		if k != i:
			out.append_array(ringers[k].crew())
	return out


## The second into the night post `i` sends its ringer at the latest (v0.11 M3, Decision 8): its own time, or CHAIN_WAIT after the
## warning before it was stopped if that is sooner. One still running never brings it forward.
func out_at(i: int) -> float:
	var at := float(tune_set_out_at[i]) * timeline.stretch_factor()
	if i > 0 and _stopped_at[i - 1] >= 0.0:
		at = minf(at, _stopped_at[i - 1] + tune_chain_wait)
	return at


## One step (v0.11 M3): the timeline, the chain, then each warning; the second one is first seen stopped is kept, and the strip
## shown the next post's chained time.
func step(delta: float) -> void:
	_clock += mission_delta(delta)
	timeline.step(delta)
	for i in range(1, ringers.size()):
		if ringers[i].waiting and _stopped_at[i - 1] >= 0.0 and _clock >= out_at(i):
			rules.banner.emit(_out_label(i).to_upper())
			_send(i)
	for i in ringers.size():
		ringers[i].step(delta)
		if ringers[i].warning_dead and _stopped_at[i] < 0.0:
			_stopped_at[i] = _clock
			if i + 1 < ringers.size():
				timeline.expect("out_%d" % (i + 1), out_at(i + 1))


## A power cast (v0.11 M3, Decision 9): a loud one within POST_SIGHT of a post still waiting sends its ringer at once ("THE EAST
## POST SEES YOU"). Quiet powers never do.
func _on_cast(_slot: int, key: String, at: Vector2) -> void:
	if PowerBook.is_quiet(key):
		return
	for i in ringers.size():
		if ringers[i].waiting and at.distance_to(doors[i]) <= POST_SIGHT:
			rules.banner.emit("THE %s POST SEES YOU" % post_names[i].to_upper())
			_send(i)


## How many warnings are stopped (v0.11 M3).
func stopped() -> int:
	var n := 0
	for r in ringers:
		n += 1 if r.warning_dead else 0
	return n


## StarsObjective's count (v0.11 M3 final review): the warnings stopped, of the posts'.
func stars_stopped() -> int:
	return stopped()


## StarsObjective's count (v0.11 M3 final review): one warning for each post.
func stars_total() -> int:
	return ringers.size()


## The warnings out of doors and alive, in the posts' order (v0.11 M3).
func running() -> Array[RingerDirector]:
	var out: Array[RingerDirector] = []
	for r in ringers:
		if not r.waiting and not r.warning_dead and r.phase != WarningDirector.Phase.OVER:
			out.append(r)
	return out


## The next post still to send its ringer, by index; -1 once all have (v0.11 M3).
func next_post() -> int:
	for i in ringers.size():
		if ringers[i].waiting and not ringers[i].warning_dead:
			return i
	return -1


## The town has called its own bellkeeper (v0.11 M3): he holds the rope -- on his way, climbing, or waiting to try again -- and
## stands. Only reads.
func called() -> bool:
	var bell := crowd.bell
	if bell == null or not _alive(bell.keeper) or bell.keeper.inside:
		return false
	return bell.keeper.profile != null and bell.keeper.profile.role == CitizenProfile.Role.BELLKEEPER \
		and bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING, BellNetwork.State.WAITING]


## The posts' towers and the stone (the bell tower) are kept standing tonight (R45): a ringer waits inside each post.
func needs_standing(s: Structure) -> bool:
	return s != null and (posts.has(s) or _stone.has(s))


## The map tags (v0.11 M3, mission spec §1), most important first: every warning out of doors (its own), the latest first; the
## town's bellkeeper while called, pointed at from the edge; the next post still waiting (NEXT POST) and each other (WATCH POST),
## all pointed at (controller ruling: the south-west post's arrow shows from the start); the bell tower.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for i in range(ringers.size() - 1, -1, -1):
		out.append_array(ringers[i].tags())
	var bell := crowd.bell
	if called():
		out.append(MapTag.person(bell.keeper, WarningDirector.MARK_KEEPER, "BELLKEEPER", true))
	var next := next_post()
	for i in ringers.size():
		if not ringers[i].waiting:
			continue
		if i == next:
			out.append(MapTag.place(doors[i], WarningDirector.MARK_MESSENGER, "NEXT POST", 0.0, true))
		else:
			out.append(MapTag.place(doors[i], MARK_POST, "WATCH POST", 0.0, true))
	if bell != null and is_instance_valid(bell.tower) and not bell.tower.destroyed:
		out.append(MapTag.place(bell.tower.center(), WarningDirector.MARK_WATCHED, "BELL TOWER", bell.tower.height, false))
	return out


## The hint's phase (v0.11 M3): "bell" while the town's keeper is called; else the most pressing warning's -- (v0.11.2) "herald", then "climbing", then
## "relay", then "mates" (or "" for one running alone); with none out, "waiting" once one is stopped and a post still waits.
func hint_phase() -> String:
	if called():
		return "bell"
	var going := running()
	var best := ""
	for r in going:
		var p := r.hint_phase()
		if p == "herald" or (p == "climbing" and best != "herald") \
				or (p == "relay" and best != "climbing" and best != "herald") or (p == "mates" and best == ""):
			best = p
	if not going.is_empty():
		return best
	return "waiting" if stopped() > 0 and next_post() >= 0 else ""


## Every phase hint_phase() can return (Mission clarity, spec 6.1).
func hint_phases() -> PackedStringArray:
	return PackedStringArray(["", "bell", "herald", "climbing", "relay", "mates", "waiting"])


## Mission clarity (spec 5.1): the banner of the first warning out that a cast reaches and will not stop -- unless the cast could stop any
## warning it reaches (the Starfall rule: a kill that stops one is "" though it lands near another's mate). Only reads.
func why_not(key: String, at: Vector2) -> String:
	var text := ""
	for r in ringers:
		if r.rules == null or r.waiting:
			continue
		var reach := r._cast_reach(key, at)
		if reach == WarningDirector.Reach.MAYBE:
			return ""
		if reach == WarningDirector.Reach.NOT and text == "":
			text = r.why_not(key, at)
	return text


## The tour (mission spec §1): the three posts with their times (the later ones "by": the chain can bring them sooner), then the
## bell tower (v0.11 M3).
func tour() -> Array:
	var out := []
	for i in posts.size():
		var when := UiTheme.clock(float(tune_set_out_at[i]))
		var line := "The %s post. Its ringer runs for the bell at %s." % [post_names[i], when]
		if i == 1:
			line = "The %s post. Its ringer comes by %s." % [post_names[i], when]
		elif i >= 2:
			line = "The %s post. Its ringer comes by %s%s." % [post_names[i], when, ", by the shortest way" if _runs_shortest(i) else ""]
		out.append([doors[i], line])
	if crowd.bell != null:
		out.append([crowd.bell.foot, "The bell tower. A ringer who reaches it climbs and rings it himself."])
	return out


## Post `i`'s door is nearer the bell's foot by the real walk than every other post's (the tour says so only when it is true in this town).
func _runs_shortest(i: int) -> bool:
	if crowd.bell == null or crowd._grid == null:
		return true
	var mine := _run_length(doors[i], crowd.bell.foot)
	for k in doors.size():
		if k != i and _run_length(doors[k], crowd.bell.foot) < mine:
			return false
	return true


## The length of the grid walk `from` -> `to`.
func _run_length(from: Vector2, to: Vector2) -> float:
	var way := 0.0
	var at := from
	for step: Vector2 in crowd._grid.path(from, to):
		way += at.distance_to(step)
		at = step
	return way


## The toll fell (v0.11.2, spec 4.6): every ringer's warning hears of it (a Herald's errand is the Temple); one still inside his tower runs
## for the Temple when he is sent.
func on_toll() -> void:
	for r in ringers:
		if r.rules != null:
			r.on_toll()


## `p` is the Herald of one of the posts' warnings (v0.11.2).
func claims_herald(p: Person) -> bool:
	for r in ringers:
		if r.rules != null and r.claims_herald(p):
			return true
	return false


## One ringer's warning runs for the Temple as a Herald (v0.11.2).
func herald_open() -> bool:
	for r in ringers:
		if r.rules != null and r.herald_open():
			return true
	return false


## Loss warning: each of the ringers' own threats (a Herald, a witness's word), its id numbered by the ringer it is, so a second one running is a
## new warning; then the base's.
func threats() -> Array[Dictionary]:
	var out := super()
	for i in ringers.size():
		if ringers[i].rules != null:
			out.append_array(NightThreat.suffixed(ringers[i].threats(), str(i)))
	return out


## The soonest of the Heralds' arrivals, in mission seconds (v0.11.2).
func herald_eta() -> float:
	var best := INF
	for r in ringers:
		if r.rules != null:
			best = minf(best, r.herald_eta())
	return best


## The results' report (v0.11 M3): the warnings stopped, and the relays they made.
func report() -> Dictionary:
	var relays := 0
	for r in ringers:
		relays += r.relays
	return {"stopped": stopped(), "relays": relays}


## Lets go of the warnings, the stone, the casts and the timeline (v0.11 M3).
func teardown() -> void:
	for r in ringers:
		if r.rules != null:
			r.teardown()
	for s in _stone:
		if is_instance_valid(s):
			s.damage_filter = Callable()
	_stone.clear()
	if is_instance_valid(rules) and rules.cast_made.is_connected(_on_cast):
		rules.cast_made.disconnect(_on_cast)
	timeline = null  # its banner and guard lambdas hold this director: let both go


## Veil (spec 5.2): each post's warning's own people (RingerDirector.quarry()) -- Blight makes him ill for a while, not sent home (MissionDirector.quarry()).
func quarry(p: Person) -> bool:
	if p == null:
		return false
	for r in ringers:
		if r != null and r.quarry(p):
			return true
	return false
