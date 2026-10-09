class_name WarningDirector
extends MissionDirector
## The Warning (v0.08, Tier 1): the god's first stirring. At OMEN_AT a star falls over the Main Gate; the watchman
## stares at it for STARE seconds, then runs (a DUTY, at the run) to the bellkeeper -- wherever the keeper is now,
## re-aimed every RETARGET -- to tell them. The keeper climbs and rings the bell, and the mission is lost. The player
## wins by killing whoever carries the warning (the messenger) with nobody living near enough to see it
## (Crowd.DOOM_WITNESS); dawn with the warning alive loses (v0.11 M1, spec §7.3: no waiting). A death that is seen
## passes the warning to the nearest witness, who runs on with it. If the keeper is dead, the messenger climbs the tower in their place.
## The bell holds for the relay (BellNetwork.hold_on_death) rather than falling silent when its keeper dies.
##
## A frightened, confused (Discord) or whispered messenger drops the errand and picks it up again once back on its
## feet (RESUMABLE); only the relay itself overrides a fright -- the witness "runs on".

enum Phase { OMEN, STARE, RUN, DELIVERED, OVER }

const OMEN_AT := 2.0
const STARE := 4.0
const RETARGET := 0.5
## The watchman's post: the Main Gate's inner side (TownLayout.MAIN_GATE's centre, 0.6 inside its north face),
## snapped to walkable ground in gate_spot.
const GATE_SPOT := Vector2(2.7, 14.5)
## How near the messenger must come to the keeper to tell them.
const DELIVER_REACH := 0.8
## A cast within this of the messenger or the keeper counts as delaying the warning, for "Solved by".
const DELAY_REACH := 3.0
## A goal is only re-aimed when the keeper has moved this far from it (a fresh path every half second for nothing
## costs a path-find).
const RETARGET_MOVE := 0.3
## Minds the messenger picks the errand up again from: back on its feet after a fright, Discord or Mind Whisper.
const RESUMABLE := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.REGROUP]
## Minds a relay leaves alone: the god's own hold on the witness wears off first.
const HELD := [Person.Mind.CONFUSED, Person.Mind.WHISPERED]
## The map tags' colours (board tags, spec §2): the warning's carrier gold, the bellkeeper steel blue, the tower and
## anyone near enough to see the carrier die red.
const MARK_MESSENGER := Color("d8b23a")
const MARK_KEEPER := Color("8fb8e8")
const MARK_WATCHED := Color("c8342a")

var phase := Phase.OMEN
var watchman: Person
var messenger: Person
var warning_dead := false
var relays := 0
## The power credited with the messenger's death (a key; "" for none).
var killed_by := ""
## Authority -> true for every power cast near the warning while it lived.
var delayed_by := {}
var gate_spot := Vector2.INF
## Where the watchman keeps his post, snapped to walkable ground in gate_spot, and the gate's name for the star's banner
## (v0.11 M1: the board's three stars fall over three gates). Set before setup(); the Main Gate's by default.
var post := GATE_SPOT
var post_name := "THE MAIN GATE"
## The star has fallen (it falls at OMEN_AT whatever the phase: a relay before it skips the stare, not the omen).
var omen_fallen := false
var _clock := 0.0
var _retarget_in := 0.0
## Where the messenger fell, waiting to be judged once the cast's other victims have fallen too.
var _fell_at := Vector2.INF


func _begin() -> void:
	var free := crowd._grid.nearest_walkable(post) if crowd._grid != null else post
	gate_spot = free if free != Vector2.INF else post
	if crowd.bell != null:
		crowd.bell.hold_on_death = true
	watchman = _appoint_watchman()
	messenger = watchman
	crowd._field.enemy_killed.connect(_on_killed)
	rules.cast_made.connect(_on_cast)


## The citizen standing nearest the gate (not the bellkeeper, the clergy, the engineers or anyone reserved -- a wisher, a
## wish target, an earlier star's runner) keeps the gate tonight.
## Null in a town with nobody to spare.
func _appoint_watchman() -> Person:
	var keeper: Person = crowd.bell.keeper if crowd.bell != null else null
	var best: Person = null
	for p in crowd.citizens:
		if not _alive(p) or p.profile == null or p.inside or p == keeper or reserved.has(p):
			continue
		if p.profile.role in [CitizenProfile.Role.CLERGY, CitizenProfile.Role.ENGINEER, CitizenProfile.Role.BELLKEEPER]:
			continue
		if best == null or p.ground_pos.distance_to(gate_spot) < best.ground_pos.distance_to(gate_spot):
			best = p
	if best == null:
		return null
	best.profile.role = CitizenProfile.Role.WATCHMAN
	best.profile.work = gate_spot
	# Placed at the gate before the first frame, with whatever walk the routine gave them dropped.
	best.ground_pos = gate_spot
	best.anchor = gate_spot
	best._goal = Vector2.INF
	best._path = PackedVector2Array()
	best._target = gate_spot
	best.last_place = RoutineManager.Place.WORK
	best.stay_left = 60.0
	return best


func step(delta: float) -> void:
	if phase == Phase.OVER:
		return
	_clock += delta
	# Judged once the crowd has judged its own doomed (Crowd._settle_doom()), so a cast's victims never witness each
	# other and a witness the doom frightened is already frightened when the relay overrides it.
	if _fell_at != Vector2.INF and crowd._doomed.is_empty():
		_judge()
		if phase == Phase.OVER:
			return
	if not omen_fallen and _clock >= OMEN_AT:
		_omen()
	match phase:
		Phase.STARE:
			if _clock >= OMEN_AT + STARE:
				phase = Phase.RUN
				_retarget_in = RETARGET
				_run()
		Phase.RUN:
			_retarget_in -= delta
			if _retarget_in <= 0.0:
				_retarget_in = RETARGET
				_run()


func _omen() -> void:
	omen_fallen = true
	if phase == Phase.OMEN:
		phase = Phase.STARE
	if ctx != null:
		FxTimeline.cast(FallingStarFx, ctx, gate_spot + Vector2(0.0, 0.8))
	rules.banner.emit("A STAR FALLS OVER %s" % post_name)
	rules.banner.emit("STOP THE WARNING")
	if phase == Phase.STARE and _alive(watchman):
		watchman.observe(gate_spot + Vector2(0.0, 0.8), STARE)


## The messenger's way: to the keeper while the keeper lives, else to the tower's foot to climb it.
func _goal() -> Vector2:
	var bell := crowd.bell
	if bell != null and _alive(bell.keeper):
		return bell.keeper.ground_pos
	return bell.foot if bell != null else Vector2.INF


## Back on its feet (or, for a soldier, under any other order): the errand can be given again.
func _resumable(p: Person) -> bool:
	return p.mind in RESUMABLE or (p.soldier and p.mind != Person.Mind.DUTY)


## Virtual (v0.11 M3): the messenger rings the bell himself -- he tells no keeper, and at the tower's foot takes the rope whether
## or not the keeper lives (The Bell-Ringers' RingerDirector). False: The Warning's way.
func _rings_himself() -> bool:
	return false


## One look at the messenger. On the errand: tell the keeper when near enough, take the rope at the tower's foot when
## the keeper is dead, else follow the keeper. Off it: pick it up again once back on its feet -- or, for a relay
## (`relay`), at once unless Discord or Mind Whisper holds the witness. v0.11 M3: one who rings it himself (_rings_himself()) is
## never told off to a keeper and takes the rope at the foot.
func _run(relay := false) -> void:
	if not _alive(messenger) or _goal() == Vector2.INF:
		return
	var bell := crowd.bell
	var keeper_alive := bell != null and _alive(bell.keeper)
	var telling := keeper_alive and not _rings_himself()  # v0.11 M3: one who rings it himself tells no keeper
	var ready := _resumable(messenger) or (relay and not messenger.mind in HELD)
	if telling and messenger == bell.keeper:
		# The keeper carries it (a relay to the keeper): they need no telling, only to be on their feet to go.
		if messenger.mind == Person.Mind.DUTY or ready:
			_deliver()
		return
	if messenger.mind == Person.Mind.DUTY and not relay:
		if telling and messenger.ground_pos.distance_to(bell.keeper.ground_pos) <= DELIVER_REACH:
			_deliver()
		elif not telling and bell != null and not messenger.has_goal() \
				and messenger.ground_pos.distance_to(bell.foot) <= BellNetwork.FOOT_REACH:
			_take_rope()
		elif messenger.anchor.distance_to(_goal()) > RETARGET_MOVE or not messenger.has_goal():
			messenger.go_duty(_goal())
	elif ready:
		messenger.go_duty(_goal())  # the errand (again)


## The keeper is told: the bell is called, and the warning is the keeper's to carry now. (A bell already called -- by
## the town's own alarm -- carries on as it was; one silenced stays silent.)
func _deliver() -> void:
	var bell := crowd.bell
	var was := messenger
	messenger = bell.keeper
	bell.call_keeper()  # only an idle bell is called: one already called retries on its own
	if was != messenger:
		crowd.off_duty(was)
	phase = Phase.DELIVERED


## The keeper is dead and the messenger stands at the tower's foot: they climb in the keeper's place, slower.
func _take_rope() -> void:
	var bell := crowd.bell
	if bell.state == BellNetwork.State.RUNG or bell.state == BellNetwork.State.SILENCED:
		return  # nothing left to ring
	bell.replace_keeper(messenger)
	phase = Phase.DELIVERED


func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	if e == messenger and phase != Phase.OVER and _fell_at == Vector2.INF:
		_fell_at = e.ground_pos
		killed_by = rules.credited_key(kind)


## Judged after the death, once a cast's other victims are dead too (as Crowd._settle_doom()): nobody living near, and
## the warning dies; else the nearest witness carries it on -- to the keeper, or up the tower if the keeper is dead.
func _judge() -> void:
	var at := _fell_at
	_fell_at = Vector2.INF
	var witness := crowd.nearest_witness(at)
	if witness == null:
		warning_dead = true
		phase = Phase.OVER
		return
	relays += 1
	messenger = witness
	killed_by = ""
	rules.banner.emit("THE WARNING PASSES ON")
	phase = Phase.RUN
	_retarget_in = RETARGET
	_run(true)


func _on_cast(_slot: int, key: String, at: Vector2) -> void:
	if warning_dead or phase == Phase.OVER:
		return
	var near := _alive(messenger) and messenger.ground_pos.distance_to(at) <= DELAY_REACH
	var bell := crowd.bell
	near = near or (bell != null and _alive(bell.keeper) and bell.keeper.ground_pos.distance_to(at) <= DELAY_REACH)
	if near:
		delayed_by[PowerBook.authority_of(key)] = true


## Alive, and not freed: a fallen citizen frees itself when its fade ends, and the directors still hold it.
static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()


## The map tags (board tags, spec §2), most important first:
## - whoever carries the warning, pointed at from the edge: WATCHMAN before he runs, BELLKEEPER once the keeper has it,
##   else MESSENGER (in place of v0.08's marker);
## - the bellkeeper while someone else carries it, pointed at while the messenger runs to him;
## - the bell tower, while it stands;
## - from the run on, a red diamond on each person near enough to see the carrier die (Crowd.nearest_witness()'s rule).
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if phase == Phase.OVER or warning_dead or not _alive(messenger):
		return out
	var bell := crowd.bell
	var keeper: Person = bell.keeper if bell != null and _alive(bell.keeper) else null
	var label := "MESSENGER"
	if messenger == keeper:
		label = "BELLKEEPER"
	elif phase == Phase.OMEN or phase == Phase.STARE:
		label = "WATCHMAN"
	out.append(MapTag.person(messenger.ground_pos, MARK_MESSENGER, label, true))
	if keeper != null and keeper != messenger and not keeper.inside:
		out.append(MapTag.person(keeper.ground_pos, MARK_KEEPER, "BELLKEEPER", phase == Phase.RUN))
	if bell != null and is_instance_valid(bell.tower) and not bell.tower.destroyed:
		out.append(MapTag.place(bell.tower.center(), MARK_WATCHED, "BELL TOWER", bell.tower.height, false))
	if phase == Phase.RUN or phase == Phase.DELIVERED:
		for p in witnesses():
			out.append(MapTag.person(p.ground_pos, MARK_WATCHED))
	return out


## Everyone who would see the messenger die where they stand: living, out of doors, within Crowd.DOOM_WITNESS (the rule
## Crowd.nearest_witness() judges by). Only reads.
func witnesses() -> Array[Person]:
	var out: Array[Person] = []
	if not _alive(messenger):
		return out
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and p != messenger and p.is_alive() and not p.inside \
					and p.ground_pos.distance_to(messenger.ground_pos) <= Crowd.DOOM_WITNESS:
				out.append(p)
	return out


## The hint's phase (board tags, spec §3): "bell" once the warning has reached the bell, "relay" while a witness carries
## it on, else "".
func hint_phase() -> String:
	if phase == Phase.DELIVERED:
		return "bell"
	return "relay" if phase == Phase.RUN and relays > 0 else ""


## The tour (board tags, spec §4): the watchman at the gate, then the bellkeeper.
func tour() -> Array:
	var out := []
	if _alive(watchman):
		out.append([watchman.ground_pos, "The watchman. When the star falls, he runs to warn the town."])
	var bell := crowd.bell
	if bell != null and _alive(bell.keeper):
		out.append([bell.keeper.ground_pos, "The bellkeeper. Once warned, he rings the bell, and you lose."])
	return out


## "Solved by": a kill's Authority (v0.08; shown, not saved). v0.11 M1: the omen no longer fades into a win (spec §7.3: dawn
## with the warning alive loses), so the Authorities that only delayed a warning still alive are reported for the record
## alone -- a lost night shows NOBODY (ResultsScreen.solved_text()).
func report() -> Dictionary:
	var by := PackedStringArray()
	if warning_dead and killed_by != "":
		by.append(PowerBook.authority_title(PowerBook.authority_of(killed_by)))
	elif not warning_dead:
		for a in PowerBook.AUTHORITIES:
			if delayed_by.has(a):
				by.append(PowerBook.authority_title(a))
	return {"solved_by": by, "relays": relays}


func teardown() -> void:
	if is_instance_valid(crowd) and crowd._field != null and crowd._field.enemy_killed.is_connected(_on_killed):
		crowd._field.enemy_killed.disconnect(_on_killed)
	if is_instance_valid(rules) and rules.cast_made.is_connected(_on_cast):
		rules.cast_made.disconnect(_on_cast)
	# The bell waits for a relay only while the warning lives (v0.09: a crowd outlives an act).
	if is_instance_valid(crowd) and crowd.bell != null:
		crowd.bell.hold_on_death = false
