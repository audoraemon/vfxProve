class_name StarfallDirector
extends MissionDirector
## The Warning on the tier board (the Warning rework, spec 2): from 0:00 three watchmen stand at three posts, one star falls over the town (OMEN_AT), and
## each watchman sets off for the bellkeeper at his own time (STARS' first field), unless he has been stopped first. Each watchman is a WarningDirector
## of his own -- the post, the run, the relay, the unseen kill -- with the rework's flags on (holds_post, quiet_omen, dreams_stop, lead_key,
## bell_breaks, besides W1-W3): the stars' set-offs and the omen are in MISSION seconds (W-R13), so a toll brings the later ones sooner. The main
## objective (StarsObjective) is all three warnings stopped. v0.11.2: a Herald night -- the toll turns the Lantern, and the warning's carrier runs
## for the Temple (HeraldObjective loses the night only if one gets in); a blighted or fallen bell tower breaks the bell and buys time (W-R3).
## Each later runner starts nearer the bell (spec 8): the postern, the Main Gate, then the Side Gate.

## Each watchman: [seconds into the night he sets off (first guess), his post just inside his gate, the gate's name for the banner].
const STARS := [
	[20.0, Vector2(-5.75, 14.9), "THE POSTERN"],
	[40.0, Vector2(2.7, 14.5), "THE MAIN GATE"],
	[60.0, Vector2(14.5, 9.0), "THE SIDE GATE"],
]

## The mission second the one star falls over the town (first guess): each watchman looks up at it (STARE), then keeps his post.
const OMEN_AT := 1.0

## The town's posts and set-off times (v0.12, spec 1.5): seeded from the consts above, which are Aldermere's; a town's overrides replace them.
## (`stars` below is the list of warnings, so the schedule is `star_falls`.)
## The names a town's overrides may set (Overrides): the var above, which setup reads and never assigns.
const TOWN_VARS := ["star_falls"]
var star_falls: Array = STARS

## The three warnings, in the order they set off; each is set up on the first step (its `rules` is null until then).
var stars: Array[WarningDirector] = []
## Mission seconds into the night (v0.11.2: the schedule runs on the mission clock's rate; each warning's own run is real time).
var _clock := 0.0
## The one star has fallen (and each live watchman has looked up at it).
var _omen_done := false
## The warnings have been set up (the first step, after NightRules has made the town its own).
var _set_up := false


func _begin() -> void:
	for i in star_falls.size():
		var s: Array = star_falls[i]
		var w := WarningDirector.new()
		w.post = s[1]
		w.post_name = String(s[2])
		w.rework_reach = true  # (the Warning rework, W-R1) the new why_not reach, on the board only
		w.walls_stop = true  # (god T1R, spec 4.1) a carrier out of the walls, or one who reaches a keeper who heard ALL IS WELL, stops the warning
		w.lie_stops = true
		w.gate_keeps = true  # (god T1R fix round, D26) W3: a death just outside his gate draws the staring watchman out; the postern's has its key
		w.holds_post = true  # (the Warning rework, spec 3) he keeps his post until his set-off
		w.quiet_omen = true  # this director plays the one star
		w.dreams_stop = true  # a Discord on him at his post: he dreamt it
		w.lead_key = true  # K2: a whisper led through the postern's key
		w.bell_breaks = true  # W-R3: a blighted tower breaks the bell
		w.broken_said = i > 0  # (W-R16) THE BELL IS BROKEN shows once: only the first warning says it
		stars.append(w)


## Sets the warnings up on the first step, in STARS order, each leaving the others' people alone; then the one omen at OMEN_AT and each set-off at its time
## (mission seconds), for each watchman still at his post.
func step(delta: float) -> void:
	_clock += mission_delta(delta)
	if not _set_up:
		_set_up = true
		for w in stars:
			if not w.warning_dead:
				w.reserved = _reserved_for(w)
				w.setup(rules, crowd, town, ctx, night)
	for w in stars:
		if w.rules != null:
			w.step(delta)
	if not _omen_done and _clock >= OMEN_AT:
		_omen()
	for i in stars.size():
		if stars[i].at_post() and _clock >= float(star_falls[i][0]):
			stars[i].set_off()
	_say_broken()


## The one star over the Main Gate's post (the middle post), the banners, and each live watchman's look-up (his own `_omen()`, quiet).
func _omen() -> void:
	_omen_done = true
	var at := _walkable(star_falls[mini(1, star_falls.size() - 1)][1])
	if ctx != null:
		FxTimeline.cast(FallingStarFx, ctx, at + Vector2(0.0, 0.8))
	rules.banner.emit("A STAR FALLS OVER THE TOWN")
	rules.banner.emit("STOP THE WARNINGS")
	for w in stars:
		if w.rules != null and not w.warning_dead and not w.omen_fallen:
			w._omen()


## THE BELL IS BROKEN, once (W-R16): the first warning says it in its own step; if it has been stopped by then (it never steps again), the director does.
func _say_broken() -> void:
	var w := stars[0]
	if w.rules != null and w.warning_dead and not w.broken_said and w.herald_night() and w.bell_broken():
		w.broken_said = true
		rules.banner.emit(WarningDirector.BROKEN_BANNER)


## Mission seconds until star `i`'s watchman sets off (never below 0): INF once he has set off or been stopped. Before the warnings are set up it is the
## schedule's. Only reads.
func sets_off_in(i: int) -> float:
	var w := stars[i]
	if w.warning_dead:
		return INF
	if w.rules != null and not w.at_post():
		return INF
	return maxf(0.0, float(star_falls[i][0]) - _clock)


## The seconds the task line counts: the soonest set-off still to come, else 0.
func step_seconds() -> float:
	var best := INF
	for i in stars.size():
		best = minf(best, sets_off_in(i))
	return best if best < INF else 0.0


## Who a star about to be set up must leave alone (v0.11 M1): this director's reserved people -- the wishers and wish
## targets -- and the watchman and messenger of every star already set up and still alive, so one kill never ends two.
func _reserved_for(next: WarningDirector) -> Array[Person]:
	var out: Array[Person] = reserved.duplicate()
	for w in stars:
		if w.rules != null:
			for p: Variant in w.leaving:  # (god T1R) a stopped carrier walking off the map is nobody's watchman
				if is_instance_valid(p) and not out.has(p):
					out.append(p as Person)
		if w == next or w.rules == null or w.warning_dead:
			continue
		# Variants: a runner killed on an earlier star may be freed by now (_alive() rules the same way).
		for p: Variant in [w.watchman, w.messenger]:
			if is_instance_valid(p) and not out.has(p):
				out.append(p as Person)
	return out


## How many warnings have been stopped (killed unseen with their messenger).
func stopped() -> int:
	var n := 0
	for w in stars:
		n += 1 if w.warning_dead else 0
	return n


## StarsObjective's count (v0.11 M3 final review): the warnings stopped, of the night's stars.
func stars_stopped() -> int:
	return stopped()


## StarsObjective's count (v0.11 M3 final review): one warning for each star.
func stars_total() -> int:
	return stars.size()


## The warning that has set off and lives, the latest of them first (a watchman still at his post is not running); null for none.
func running() -> WarningDirector:
	for i in range(stars.size() - 1, -1, -1):
		var w := stars[i]
		if w.rules != null and not w.warning_dead and w.phase != WarningDirector.Phase.OVER and not w.at_post():
			return w
	return null


## The tags (spec 6.1), most important first: each live watchman's own -- "WATCHMAN - SETS OFF IN m:ss" until he sets off, then his carrier tag -- the
## bellkeeper and the bell tower once (not per warning), the Temple's door unless the Lantern draws its own, then the witnesses.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	var live: Array[WarningDirector] = []
	var herald := false
	var broken := false
	var running_to_keeper := false
	var keeper_carries := false
	for i in range(stars.size() - 1, -1, -1):
		var w := stars[i]
		if w.rules == null or w.warning_dead or w.phase == WarningDirector.Phase.OVER or not WarningDirector._alive(w.messenger):
			continue
		live.append(w)
		herald = herald or w.herald_open()
		broken = broken or w.bell_broken()
		running_to_keeper = running_to_keeper or w.phase == WarningDirector.Phase.RUN
		if w.crowd.bell != null and w.messenger == w.crowd.bell.keeper:
			keeper_carries = true
		if w.at_post():
			out.append(MapTag.person(w.messenger, WarningDirector.MARK_MESSENGER, "WATCHMAN - SETS OFF IN %s" % UiTheme.clock(sets_off_in(stars.find(w))), true))
		else:
			out.append_array(w.carrier_tags())
	var bell := crowd.bell
	if bell != null and not herald and not broken:
		var keeper: Person = bell.keeper if WarningDirector._alive(bell.keeper) else null
		if keeper != null and not keeper_carries and not keeper.inside and not live.is_empty():
			out.append(MapTag.person(keeper, WarningDirector.MARK_KEEPER, live[0]._keeper_label(), running_to_keeper))
		if is_instance_valid(bell.tower) and not bell.tower.destroyed and not live.is_empty():
			out.append(MapTag.place(bell.tower.center(), WarningDirector.MARK_WATCHED, "BELL TOWER", bell.tower.height, false))
	if rules.lantern == null or not rules.lantern.herald_running():
		out.append(MapTag.place(lantern_door(), LanternWatch.MARK_TEMPLE, "TEMPLE", 0.0, false))
	for w in live:
		out.append_array(w.witness_tags())
	return out


## The hint's phase (spec 6.2), the most urgent live warning first; never "": herald (a Herald runs), bell (the keeper carries it), relay (a witness does),
## running (a watchman has set off), broken (the bell is broken and only watchmen at their posts remain), else posts.
func hint_phase() -> String:
	var order := ["herald", "bell", "relay"]
	for ph: String in order:
		for w in stars:
			if w.rules != null and not w.warning_dead and w.hint_phase() == ph:
				return ph
	var posts := true
	var broken := false
	for w in stars:
		if w.rules == null or w.warning_dead or w.phase == WarningDirector.Phase.OVER:
			continue
		broken = broken or w.bell_broken()
		if not w.at_post():
			return "running"
	return "broken" if broken else "posts"


## Every phase hint_phase() can return (spec 6.2).
func hint_phases() -> PackedStringArray:
	return PackedStringArray(["herald", "bell", "relay", "running", "broken", "posts"])


## Mission clarity (spec 5.1, review focus 3): the banner of the first warning a cast reaches and will not stop -- unless the cast could stop
## any warning it reaches (the watchmen stand close: a kill that stops one is "" though it lands near another's carrier). A warning
## a kill has just stopped counts too: its carrier's body is where the kill fell. Then (W-R3, I6) Blight on the bell tower says what it does:
## TOLLED first, SOONER if any live warning would be sooner by the broken bell, else TIME. Only reads.
func why_not(key: String, at: Vector2) -> String:
	var text := ""
	for w in stars:
		if w.rules == null:
			continue
		var reach := w._carrier_reach(key, at)
		if reach == WarningDirector.Reach.MAYBE:
			return ""
		if reach == WarningDirector.Reach.NOT and text == "":
			text = WarningDirector.STOPS_BANNER
	var bell := _bell_why(key, at)
	return bell if bell != "" else text


## The honest banner for Blight on the tower, over every warning (each answers for its own carrier): TOLLED, else SOONER if any says so, else TIME; "" for none.
func _bell_why(key: String, at: Vector2) -> String:
	var text := ""
	for w in stars:
		if w.rules == null:
			continue
		var said := w.bell_why(key, at)
		if said == WarningDirector.BELL_TOLLED:
			return said
		if said == WarningDirector.BELL_SOONER or text == "":
			text = said
	return text


## The tour (spec 6.3): each post, the bellkeeper, then the Temple's door.
func tour() -> Array:
	var out := []
	for s: Array in star_falls:
		out.append([_walkable(s[1]), "%s's watchman. He sets off for the bellkeeper at %s." % [String(s[2]).capitalize(), UiTheme.clock(float(s[0]))]])
	var bell := crowd.bell
	if bell != null and _alive(bell.keeper):
		out.append([bell.keeper.ground_pos, "The bellkeeper. Warned, he rings the bell: the Lantern turns, and he runs for the Temple."])
	out.append([lantern_door(), "The Temple. A warning that reaches it loses the night."])
	return out


## The toll fell (v0.11.2, spec 4.6): every warning that is up hears of it (a Herald's errand is the Temple); a star yet to fall finds the
## Lantern already tolled when its watchman runs.
func on_toll() -> void:
	for w in stars:
		if w.rules != null:
			w.on_toll()


## `p` is the Herald of one of the warnings that are up (v0.11.2).
func claims_herald(p: Person) -> bool:
	for w in stars:
		if w.rules != null and w.claims_herald(p):
			return true
	return false


## One of the warnings runs for the Temple as a Herald (v0.11.2).
func herald_open() -> bool:
	for w in stars:
		if w.rules != null and w.herald_open():
			return true
	return false


## Loss warning: each of the stars' own threats (a Herald, a witness's word), its id numbered by the star it is, so a second one running is a
## new warning; then the base's.
func threats() -> Array[Dictionary]:
	var out := super()
	for i in stars.size():
		if stars[i].rules != null:
			out.append_array(NightThreat.suffixed(stars[i].threats(), str(i)))
	return out


## The soonest of the Heralds' arrivals, in mission seconds (v0.11.2).
func herald_eta() -> float:
	var best := INF
	for w in stars:
		if w.rules != null:
			best = minf(best, w.herald_eta())
	return best


## The results' report (v0.11 M1): the warnings stopped, the relays all three made, and how they were stopped (out, lie, dreamt).
func report() -> Dictionary:
	var relays := 0
	var out := 0
	var lies := 0
	var dreamt := 0
	for w in stars:
		relays += w.relays
		out += 1 if w.stopped_how == "out" else 0
		lies += 1 if w.stopped_how == "lie" else 0
		dreamt += 1 if w.stopped_how == "dreamt" else 0
	return {"stopped": stopped(), "relays": relays, "out": out, "lies": lies, "dreamt": dreamt}


func teardown() -> void:
	for w in stars:
		if w.rules != null:
			w.teardown()
