class_name StarfallDirector
extends MissionDirector
## The Warning on the tier board (v0.11 M1, spec §7.2): three stars fall through the night, each over a gate, and each sends
## that gate's watchman running to the bellkeeper. Each star is a WarningDirector of its own -- the omen, the stare, the run,
## the relay, the unseen kill -- set up WarningDirector.OMEN_AT before its star, so its watchman is appointed then. The main
## objective (StarsObjective) is all three warnings stopped. v0.11.2: a Herald night -- the toll turns the Lantern, and the warning's carrier runs for the
## Temple (HeraldObjective loses the night only if one gets in); the stars' times and STOP_WAIT are MISSION seconds, so dawn's haste brings them sooner.
## Each later runner starts nearer the bell (spec §8): the postern, the Main Gate, then the Side Gate.

## Each star: [seconds into the night it falls, the watchman's post just inside its gate, the gate's name for the banner].
const STARS := [
	[10.0, Vector2(-5.75, 14.9), "THE POSTERN"],
	[90.0, Vector2(2.7, 14.5), "THE MAIN GATE"],
	[180.0, Vector2(14.5, 9.0), "THE SIDE GATE"],
]

## How long after one warning is stopped the next star falls at the latest (v0.11 M1, the no-wait-over-60-s rule): a later
## star falls at its scheduled time or this long after the previous warning was stopped, whichever is sooner.
const STOP_WAIT := 30.0

## The town's stars and wait (v0.12, spec 1.5): seeded from the consts above, which are Aldermere's; a town's overrides replace them.
## (`stars` below is the list of warnings, so the schedule is `star_falls`.)
var star_falls: Array = STARS
var stop_wait: float = STOP_WAIT

## The three warnings, in the order their stars fall; each is set up when its time comes (its `rules` is null until then).
var stars: Array[WarningDirector] = []
## Mission seconds into the night (v0.11.2: the stars' schedule runs on the mission clock's rate; each warning's own stare and run are real time).
var _clock := 0.0
## The night's second each star's warning was first seen stopped, or -1 while it has not been (v0.11 M1); one per star.
var _stopped_at: Array[float] = []


func _begin() -> void:
	for s: Array in star_falls:
		var w := WarningDirector.new()
		w.post = s[1]
		w.post_name = String(s[2])
		stars.append(w)
		_stopped_at.append(-1.0)


## Sets up each star's warning OMEN_AT before it falls -- unless it is already stopped -- and steps those set up. The
## second a warning is first seen stopped is kept: the next star falls no later than STOP_WAIT after it.
func step(delta: float) -> void:
	_clock += mission_delta(delta)
	for i in stars.size():
		var w := stars[i]
		if w.rules == null:
			if not w.warning_dead and _clock >= fall_at(i) - WarningDirector.OMEN_AT:
				w.reserved = _reserved_for(w)
				w.setup(rules, crowd, town, ctx, night)
		else:
			w.step(delta)
		if w.warning_dead and _stopped_at[i] < 0.0:
			_stopped_at[i] = _clock


## The second into the night star `i` falls (v0.11 M1): its scheduled time, or STOP_WAIT after the previous warning was stopped
## if that is sooner. A previous warning not yet stopped never brings it forward, and the first star is never earlier.
func fall_at(i: int) -> float:
	var at := float(star_falls[i][0])
	if i > 0 and _stopped_at[i - 1] >= 0.0:
		at = minf(at, _stopped_at[i - 1] + stop_wait)
	return at


## Who a star about to be set up must leave alone (v0.11 M1): this director's reserved people -- the wishers and wish
## targets -- and the watchman and messenger of every star already set up and still alive, so one kill never ends two.
func _reserved_for(next: WarningDirector) -> Array[Person]:
	var out: Array[Person] = reserved.duplicate()
	for w in stars:
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


## The warning running now: the latest star set up whose warning lives; null between stars.
func running() -> WarningDirector:
	for i in range(stars.size() - 1, -1, -1):
		var w := stars[i]
		if w.rules != null and not w.warning_dead and w.phase != WarningDirector.Phase.OVER:
			return w
	return null


## The next star still to fall, by index; -1 once all have fallen (or been stopped).
func next_star() -> int:
	for i in stars.size():
		if not stars[i].omen_fallen and not stars[i].warning_dead:
			return i
	return -1


## The tags (v0.11 M1): every set-up warning's own (WarningDirector.tags()), the latest first; and the next star's gate,
## pointed at from the edge, until it falls.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for i in range(stars.size() - 1, -1, -1):
		if stars[i].rules != null:
			out.append_array(stars[i].tags())
	var next := next_star()
	if next >= 0:
		out.append(MapTag.place(star_falls[next][1], WarningDirector.MARK_MESSENGER, "NEXT STAR", 0.0, true))
	return out


## The hint's phase (v0.11 M1): the running warning's ("relay", "bell" or its own ""), else "waiting" between stars.
func hint_phase() -> String:
	var w := running()
	if w != null:
		return w.hint_phase()
	return "waiting" if stopped() > 0 and next_star() >= 0 else ""


## The tour (v0.11 M1): the three gates the stars fall over, then the bellkeeper. v0.11 M2 (M1 final review): the first star
## falls at its time; a later one may fall sooner (STOP_WAIT), so it falls "by" its time.
func tour() -> Array:
	var out := []
	for i in star_falls.size():
		var s: Array = star_falls[i]
		out.append([_walkable(s[1]), "%s. A star falls here %s %s." % [String(s[2]).capitalize(), "at" if i == 0 else "by",
			UiTheme.clock(float(s[0]))]])
	var bell := crowd.bell
	if bell != null and _alive(bell.keeper):
		out.append([bell.keeper.ground_pos, "The bellkeeper. Warned, he rings the bell: the Lantern turns, and he runs for the Temple."])
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


## The soonest of the Heralds' arrivals, in mission seconds (v0.11.2).
func herald_eta() -> float:
	var best := INF
	for w in stars:
		if w.rules != null:
			best = minf(best, w.herald_eta())
	return best


## The results' report (v0.11 M1): the warnings stopped, and the relays all three made.
func report() -> Dictionary:
	var relays := 0
	for w in stars:
		relays += w.relays
	return {"stopped": stopped(), "relays": relays}


func teardown() -> void:
	for w in stars:
		if w.rules != null:
			w.teardown()
