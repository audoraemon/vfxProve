class_name Crowd
extends Node
## The people of Aldermere: 110 citizens who wander their street, panic, flee to the exits and queue at the
## gates, and 50 soldiers who hold their posts until the alarm or the first blow on the Citadel sends them to
## ring it. Everyone is an ordinary unit in EnemyField, so every effect kills, knocks, pulls, freezes and lifts
## them as it does the sandbox's troopers. Numbers are the spec's starting values (§3).

signal escaped(person: Person)
signal alarm_changed(value: float)
## The bell tolled a lie (The Bell Lies): at the tower.
signal bell_lied(at: Vector2)
signal rallied

## What a lying bell takes off the alarm, and how long its hearers take heart (false_bell()).
const LIE_CALM := 8.0
const LIE_REASSURE := 8.0

## The town scale upgrade doubled the people along with the town (110 + 50 before).
const CITIZENS := 220
const SOLDIERS := 100
## Soldier posts: drilling in the yard, on the walls and gates, guarding the Citadel, patrolling in pairs.
const POST_YARD := 30
const POST_WALLS := 30
const POST_CITADEL := 20
const POST_PATROL := 20
## A rescue squad's size (v0.07).
const RESCUE_SQUAD := 3
const ALARM_BUILDING := 2.0
const ALARM_KILL := 0.5
const ALARM_CITADEL_HIT := 10.0
## The staged alarm (AlarmManager) replaced v0.03's rally at 25 and town-wide flight at 50: the soldiers rally at
## City Emergency (alarm 25) and citizens evacuate at the Evacuation stage.
## Soldiers sent to look at a district's emergency: how many, and for how long before they go back to their posts.
const INVESTIGATORS := 2
const INVESTIGATE_SECONDS := 20.0
## At City Emergency this share of citizens (and every merchant: the market closes) goes home to regroup.
const REGROUP_SHARE := 0.3
## A household regrouping at home leaves together at the evacuation once every member still regrouping is home,
## or after HOUSEHOLD_WAIT seconds. Farmhouse households are numbered from FARM_FAMILY.
const HOUSEHOLD_WAIT := 20.0
const HOME_REACH := 1.2
const FARM_FAMILY := 10000
## A cast this close frightens a citizen; a collapse this close does too.
const PANIC_CAST := 7.0
## Alarm from events counts this share of its worth before the bell has rung (_hear_alarm()).
const UNWARNED_ALARM := 0.5
## The quiet powers (v0.05). Silent Doom's deaths go unseen unless someone stands within DOOM_WITNESS of one: then
## those near it panic, and the death counts like any other. Blight adds BLIGHT_ALARM, and jams a gate for GATE_JAM
## seconds.
const DOOM_WITNESS := 2.0
const BLIGHT_ALARM := 1.0
const GATE_JAM := 30.0
## A Thornwall (v0.06) growing out of the street: this much alarm for a wall (its segments within THORN_WALL seconds
## of each other count once), and calm citizens within THORN_LOOK stop to look at it.
const THORN_ALARM := 1.0
const THORN_WALL := 1.0
const THORN_LOOK := 3.0
## A fallen building: its danger's radius past the footprint's reach, and how far it is seen and heard.
const COLLAPSE_RADIUS := 1.0
const COLLAPSE_SIGHT := 4.0
const COLLAPSE_SOUND := 6.0
const COLLAPSE_SECONDS := 3.0
## A frightened citizen's fright spreads to calm people within this, after SPREAD_DELAY seconds.
const SPREAD_REACH := 2.5
const SPREAD_DELAY := Vector2(0.5, 1.5)
## How often people walking into a lasting danger (a tornado, a fire) are checked for it.
const WATCH_HZ := 4.0
## One person through a gate this often. 0.6 s was the spec's starting value, calibrated against people who
## stalled at every path waypoint; once they really ran (milestone 5) 42 escaped in the first 34 s against a
## loss limit of 38. At 2 s the gates are the bottleneck the spec describes: crowds pile up in front of them.
const GATE_INTERVAL := 2.0
## The postern down to the dock (v0.05) is a narrow door: one person this often, about the boats' own pace -- by
## default; the profile sets it (ResponseProfile.postern_interval, v0.08.2).
const POSTERN_INTERVAL := 3.0
## How far beyond a gate's footprint its queue reaches, so people are held just before the arch as well.
const GATE_DOOR := 0.45
## A gate's waiting crowd: how far in front of the doorway it may reach, and how far apart two waiting people
## stand. People never collide, so without spots of their own a crowd of thirty stood on three pixels.
const QUEUE_REACH := 3.2
const QUEUE_SPACING := 0.34
## The waiting crowd forms this far inside the town from the doorway, where the wall does not hide it -- the
## camera looks from the south-east, and a 34-px wall covers about 2.1 units of ground behind it.
const QUEUE_DEPTH0 := 2.2
## Where the soldiers ring the Citadel.
const RING_RADIUS := 3.4
## A rallied soldier this far past RING_RADIUS still stands on the ring (v0.09.1): it garrisons the Citadel
## (Citadel.garrison) and is the reserve a dead marshal, escort or rescuer is replaced from (_refill()).
const RING_REACH := 1.0
## Voices: at most this many a second across the whole town, refilling steadily, so 160 people can never drown
## the powers. A cast is heard from at most VOICES_PER_CAST of the people it frightened, the nearest first.
const VOICE_BUDGET := 4.0
const VOICES_PER_CAST := 3

## The sound of a town running: a looping bed whose level follows how many citizens are running -- silent with
## none, full at BED_FULL -- easing at BED_EASE a second so it swells and fades instead of jumping.
const BED_FULL := 40.0
const BED_EASE := 1.5
const BED_DB := -8.0

var citizens: Array[Person] = []
var soldiers: Array[Person] = []
## How many were spawned, so milestone 3's stability can measure losses against the starting town.
var spawned_citizens := 0
## Where calm citizens go next (v0.04); made by spawn().
var routine: RoutineManager
## The dangers people know of (v0.04 local awareness).
var threats := ThreatManager.new()
## A frightened citizen's fright reaches the calm people beside it after a moment: [due clock, person].
var _spreads: Array = []
var _watch_in := 0.0
## The town's alarm in stages (v0.04).
var alarms := AlarmManager.new()
## Which way out each evacuee takes (v0.04); made by spawn().
var evac: EvacuationManager
## Fires and the citizens fighting them (v0.04 P1); made by setup().
var fires: FireManager
## How ready the town is (v0.05): which responses it has and how strong. Mission sets it before spawn().
var profile := ResponseProfile.for_tier(ResponseProfile.DEFAULT)
## Sturdy buildings people take cover in (v0.04 P2); made by spawn().
var shelters: ShelterManager
var _stage_in := 0.0
## Soldiers away looking at an incident: [soldier, post to return to, clock to return].
var _investigating: Array = []
## The Bell Tower and its bellkeeper (v0.05); made by spawn().
var bell: BellNetwork
## The clergy's Banishing Rite at the cathedral (v0.05); made by spawn().
var rite: BanishingRite
## The engineers from the workshop (v0.05); made by spawn().
var engineers: EngineerManager
## The river boats at the dock (v0.05); made by spawn().
var ferry: RiverFerry
## Pestilence's spread (v0.06); made by spawn().
var plague: PlagueManager
## Madness Bloom's madness (a Disorder status); made by spawn().
var madness: MadnessManager
## Voice of God's Silence: until this clock nobody can shout, pass a fright on, call for help or ring the bell.
var _hush_until := -INF
## Until when the bell lies (bell_lies()), on the crowd's clock.
var _bell_lies_until := -INF
## Seconds left of time standing still (freeze()).
var _freeze_left := 0.0
## The soldiers' roles (v0.07); made by spawn().
var marshals: MarshalManager
## The patrols' escorts for the responders (v0.07); made by spawn().
var escorts: EscortManager
## The rescue squads and the people trapped under collapsed shelters (v0.07); made by spawn().
var rescue: RescueManager
## The seed setup() was given, for managers that must not draw from the crowd's own rng (which would move everyone).
var _seed := 0
## Draw the town's responses: over the world (the bell's climb, the clergy's halos) and on the ground (the rite's
## ring, under the people and buildings).
var _drawer: Node2D
var _ground_drawer: Node2D
## Households waiting to leave together: family -> clock the evacuation found them.
var _households := {}
## Silent Doom's dead, judged for witnesses once all of a cast's victims have fallen (_settle_doom()).
var _doomed: Array[Person] = []
## Blighted gates -> the clock they free themselves at.
var _jams := {}
## Gates held shut (v0.09, hold_gate()) -> the clock they let people through again.
var _held := {}
## Where the engineers work from, found by spawn() (v0.09: raise_profile() may appoint them later).
var _workshop := Vector2.INF
## When the last thorn wall's alarm was raised.
var _thorn_alarm_at := -INF
var spawned_soldiers := 0
var alarm := 0.0
var escaped_count := 0
var killed_citizens := 0
var killed_soldiers := 0
## The battlefield's Sfx; null in tests, which still count what would have played.
var sfx: Node
var voices_played := 0
var _voice_tokens := VOICE_BUDGET
var _bed: AudioStreamPlayer
var _bed_level := 0.0
## Set by stop_bed(): once the mission is quitting, _update_bed() must not revive the bed even though the
## crowd (unlike the frozen pause) keeps processing for the few frames Battlefield.quit() waits out.
var _bed_stopped := false

var _field: EnemyField
var _env: EnvironmentField
var _town: Town
var _grid: WalkGrid
var _parent: Node2D
var _rng := RandomNumberGenerator.new()
## Gate -> the crowd clock time it may pass someone again.
var _gate_next := {}
## Gate -> its queue spots, nearest the doorway first. Built when the town is first asked about, per gate.
var _spots := {}
var _clock := 0.0
var _rallied := false
var _fled_all := false
var _citadel_hit := false
## Seconds until EnemyField.purge() runs again (about once a second; mirrors the gate clock's pacing).
var _purge_in := 1.0
## Steps the people (see Ticker).
var _ticker: Ticker


## Steps the whole crowd from one node in the world, placed just before the first person: people do not process
## on their own (Person.ticked), so the engine makes one call a frame instead of one per person.
## Draws the town's responses over the world: the Bell Tower's climb and ring (BellNetwork.draw()) and the Banishing
## Rite's ring (BanishingRite.draw()).
class ResponseDrawer extends Node2D:
	var crowd: Crowd
	## Drawing on the ground, under the people (the rite's ring), rather than over everything.
	var ground := false

	func _draw() -> void:
		if crowd == null:
			return
		if crowd.bell != null and not ground:
			crowd.bell.draw(self)
		if crowd.rite != null:
			if ground:
				crowd.rite.draw_ground(self)
			else:
				crowd.rite.draw_over(self)
		if crowd.engineers != null and not ground:
			crowd.engineers.draw(self)
		if crowd.rescue != null and not ground:
			crowd.rescue.draw(self)
		if crowd.plague != null and ground:
			crowd.plague.draw_ground(self)
		if crowd.madness != null:
			if ground:
				crowd.madness.draw_ground(self)
			else:
				crowd.madness.draw_over(self)

	## Whether anything is on show now.
	func showing() -> bool:
		return crowd != null and ((crowd.bell != null and (crowd.bell.state == BellNetwork.State.CLIMBING
			or crowd.bell.ring_show > 0.0)) or (crowd.rite != null and crowd.rite.glow > 0.0)
			or (crowd.engineers != null and crowd.engineers.working())
			or (crowd.rescue != null and not crowd.rescue.trapped.is_empty())
			or (crowd.plague != null and crowd.plague.any_in_open())
			or (crowd.madness != null and crowd.madness.any_in_open()))


class Ticker extends Node:
	var crowd: Crowd

	func _process(delta: float) -> void:
		crowd.step_people(delta)


func setup(field: EnemyField, env: EnvironmentField, town: Town, grid: WalkGrid, parent: Node2D,
		seed_value: int) -> Crowd:
	_field = field
	_env = env
	_town = town
	_grid = grid
	_parent = parent
	_rng.seed = seed_value
	_seed = seed_value
	env.structure_destroyed.connect(_on_structure_destroyed)
	env.structure_blighted.connect(_on_blighted)
	# A structure built or taken away (v0.06's thorns) may stand on a gate's queue: find the spots again.
	env.structure_added.connect(_on_structure_added)
	env.structure_removed.connect(func(_s: Structure) -> void: _spots.clear())
	alarms.stage_changed.connect(_on_stage)
	fires = FireManager.new().setup(self, env, seed_value + 17)
	field.enemy_killed.connect(_on_killed)
	if town.citadel != null:
		town.citadel.health_changed.connect(_on_citadel_health)
		town.citadel.fallen.connect(_on_citadel_fallen)
		town.citadel.garrison = ring_count  # (v0.09.1) the Citadel asks once per hit
	return self


func spawn(citizen_count := CITIZENS, soldier_count := SOLDIERS) -> void:
	alarms.regroup_seconds = profile.regroup_seconds  # God-Resistant evacuates sooner (v0.08.2)
	if not profile.boats and is_instance_valid(_town.postern) and _town.postern.walkable:
		_town.bar_postern()
		_grid.refresh(_town.postern)
	var homes: Array[Structure] = []
	for s in _env.structures():
		if s.role == &"house":
			homes.append(s)
	var anchors := _snapped_anchors()
	var at_home := 0
	for i in citizen_count:
		var home_i := at_home % maxi(homes.size(), 1)
		var home: Structure = homes[home_i] if not homes.is_empty() else null
		at_home += 1
		var profile := _profile(i, citizen_count, home, anchors)
		profile.family = home_i
		# Each starts somewhere in its day: at home, at work or at a leisure spot.
		var starts: Array[Vector2] = [profile.home]
		if profile.works():
			starts.append(profile.work)
		for g in profile.leisure:
			starts.append(g)
		var at := _spot_near(starts[_rng.randi_range(0, starts.size() - 1)], 0.3)
		var p := _add_person(false, at)
		p.anchor = at
		p.profile = profile
		citizens.append(p)
	for spot in _soldier_posts(soldier_count):
		soldiers.append(_add_person(true, spot))
	_assign_corps()
	routine = RoutineManager.new().setup(self, _rng.randi(), anchors.get("stall", []))
	evac = EvacuationManager.new().setup(self, _grid, _town, _rng.randi())
	var keeper := _appoint_bellkeeper(anchors)
	bell = BellNetwork.new().setup(self, _env, keeper, keeper.profile.work if keeper != null else Vector2.INF)
	rite = BanishingRite.new().setup(self, _env, _grid)
	_workshop = _nearest_of(anchors.get("craft", []), Vector2(TownLayout.WORKSHOP.get_center().x,
		TownLayout.WORKSHOP.end.y + 0.35))
	engineers = EngineerManager.new().setup(self, _env, _grid, _town, _appoint_engineers(_workshop), _workshop)
	ferry = RiverFerry.new().setup(self, _env, _grid, _field)
	plague = PlagueManager.new().setup(self, _field, _seed + 41)
	madness = MadnessManager.new().setup(self, _field, _seed + 43)
	marshals = MarshalManager.new().setup(self, _town, _grid)
	escorts = EscortManager.new().setup(self)
	rescue = RescueManager.new().setup(self, _field)
	if ferry.state != RiverFerry.State.ENDED:
		evac.add_boat_exit(ferry.board_at, ferry)
	if _drawer == null or not is_instance_valid(_drawer):
		_drawer = _response_drawer("ResponseDrawer", 60, false)
		_ground_drawer = _response_drawer("ResponseGround", -3, true)
	(_drawer as ResponseDrawer).crowd = self
	(_ground_drawer as ResponseDrawer).crowd = self
	shelters = ShelterManager.new().setup(self, _env, _field)
	for p in citizens:
		p.evac = evac
		p.shelters = shelters
	spawned_citizens = citizens.size()
	spawned_soldiers = soldiers.size()
	if _ticker == null:
		# Made after the people, so their instance ids (which stagger their timers) are what they always were, then
		# moved to just before the first of them: the crowd is stepped where its people used to be in the frame.
		_ticker = Ticker.new()
		_ticker.name = "CrowdTicker"
		_ticker.crowd = self
		_parent.add_child(_ticker)
		var first: Node = citizens[0] if not citizens.is_empty() else (soldiers[0] if not soldiers.is_empty() else null)
		if first != null and first.get_parent() == _parent:
			_parent.move_child(_ticker, first.get_index())


## The drawer over the people (z 60), where short-lived effects such as the plague's puffs go; null before spawn().
func overlay() -> Node2D:
	return _drawer if is_instance_valid(_drawer) else null


func _response_drawer(label: String, z: int, on_ground: bool) -> ResponseDrawer:
	var d := ResponseDrawer.new()
	d.name = label
	d.z_index = z
	d.ground = on_ground
	_parent.add_child(d)
	return d


func _nearest(pts: Array[Vector2], to: Vector2) -> Vector2:
	var best := pts[0]
	for g in pts:
		if g.distance_squared_to(to) < best.distance_squared_to(to):
			best = g
	return best


## TownLayout.anchors(), each point moved onto the nearest walkable cell.
func _snapped_anchors() -> Dictionary:
	var out := {}
	var raw := TownLayout.anchors()
	for k in raw:
		var pts: Array[Vector2] = []
		for g: Vector2 in raw[k]:
			var w := g if _grid.walkable(g) else _grid.nearest_walkable(g)
			if w != Vector2.INF:
				pts.append(w)
		out[k] = pts
	return out


## The `i`-th citizen's profile: its role (CitizenProfile.role_for()), its home in front of `home`, a workplace of
## its role's kinds, and 1-3 leisure spots among the nearest to home.
func _profile(i: int, n: int, home: Structure, anchors: Dictionary) -> CitizenProfile:
	var pr := CitizenProfile.new()
	pr.role = CitizenProfile.role_for(i, n)
	var h := home.center() if home != null else Vector2.ZERO
	# One exact point per house, so a household shares its home (spread 0: the point itself, or the nearest walkable).
	pr.home = _spot_near(h + Vector2(0.0, home.footprint.size.y * 0.5 + 0.35) if home != null else h, 0.0)
	if CitizenProfile.WORK.has(pr.role):
		var pool: Array[Vector2] = []
		for k: String in CitizenProfile.WORK[pr.role]:
			pool.append_array(anchors.get(k, []))
		if pr.role == CitizenProfile.Role.FARMER:
			# Farmers live out at the farmhouse nearest their field.
			if not pool.is_empty():
				pr.work = pool[_rng.randi_range(0, pool.size() - 1)]
				var barns: Array[Vector2] = anchors.get("barn", [])
				if not barns.is_empty():
					pr.home = _nearest(barns, pr.work)
					# A farmhouse's household (Crowd.spawn() gives townsfolk their house's index).
					pr.family = FARM_FAMILY + barns.find(pr.home)
				h = pr.home
		else:
			pool.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(h) < b.distance_squared_to(h))
			pool = pool.slice(0, CitizenProfile.WORK_NEAREST)
			if not pool.is_empty():
				pr.work = pool[_rng.randi_range(0, pool.size() - 1)]
	var near: Array[Vector2] = []
	for k: String in CitizenProfile.LEISURE:
		near.append_array(anchors.get(k, []))
	near.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(h) < b.distance_squared_to(h))
	near = near.slice(0, CitizenProfile.LEISURE_NEAREST)
	for k in _rng.randi_range(1, 3):
		if not near.is_empty():
			pr.leisure.append(near[_rng.randi_range(0, near.size() - 1)])
	return pr


## Walkable ground within `spread` of `about`, or the nearest walkable point to it.
func _spot_near(about: Vector2, spread: float) -> Vector2:
	for attempt in 8:
		var candidate := about + Vector2(_rng.randf_range(-spread, spread), _rng.randf_range(-spread, spread))
		if _grid.walkable(candidate):
			return candidate
	var free := _grid.nearest_walkable(about)
	return free if free != Vector2.INF else about


func _add_person(is_soldier: bool, at: Vector2) -> Person:
	var p := Person.new()
	p.ticked = true
	p.stagger = citizens.size() + soldiers.size()
	p.rng.seed = _rng.randi()
	_field.add(p)
	p.setup_person(is_soldier, at, _grid)
	p.env = _env
	p.field = _field
	_parent.add_child(p)
	return p


## A soldier come mid-mission (v0.10 M3: Broken Lanterns' Lantern Knights), standing at `at` as its post: one of the
## town's soldiers from now on, after those spawned, with no corps until its caller gives it one.
func add_soldier(at: Vector2) -> Person:
	var p := _add_person(true, at)
	p.post = at
	soldiers.append(p)
	return p


## The soldiers' roles (v0.07), from their posts (_soldier_posts() lays them out yard, walls, Citadel, patrols): the
## barracks yard's first profile.rescue_squads x RESCUE_SQUAD form the rescue squads, the walls' first
## profile.marshals_per_exit x ways out become marshals, and the patrols' first escort_cap() escort the responders. The
## Citadel's guard and anyone over the counts keep v0.06's ways (posts, investigations, the rally). Each remembers its
## post.
func _assign_corps() -> void:
	var exits := 2 + (2 if profile.boats else 0)
	var cap := escort_cap(profile)
	for i in soldiers.size():
		var p := soldiers[i]
		p.post = p.anchor
		if i < POST_YARD:
			if i < profile.rescue_squads * RESCUE_SQUAD:
				p.corps = Person.Corps.RESCUE
		elif i < POST_YARD + POST_WALLS:
			if i - POST_YARD < profile.marshals_per_exit * exits:
				p.corps = Person.Corps.MARSHAL
		elif i >= POST_YARD + POST_WALLS + POST_CITADEL:
			if i - (POST_YARD + POST_WALLS + POST_CITADEL) < cap:
				p.corps = Person.Corps.ESCORT


## How many escorts a town keeps (v0.09.1: by need): escorts_per_duty for each duty EscortManager can give them -- the
## bell, the rite and each engineer team the profile has. The other patrols keep no role, and rally.
static func escort_cap(pr: ResponseProfile) -> int:
	return pr.escorts_per_duty * ((1 if pr.bell else 0) + (1 if pr.rite else 0) + pr.engineer_teams)


## The spec's posting: the yard, the wall towers and gates, the Citadel, and street patrols in pairs.
func _soldier_posts(count: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in POST_YARD:
		out.append(_spot_near(TownLayout.BARRACKS_YARD.get_center(), 1.4))
	var guard_spots: Array[Vector2] = []
	for s in _env.structures():
		if s.role == &"tower" or s.role == &"gate":
			guard_spots.append(s.center())
	for i in POST_WALLS:
		var about: Vector2 = guard_spots[i % maxi(guard_spots.size(), 1)] if not guard_spots.is_empty() else Vector2.ZERO
		out.append(_spot_near(about, 1.2))
	for i in POST_CITADEL:
		var a := TAU * float(i) / float(POST_CITADEL)
		out.append(_spot_near(TownLayout.CITADEL_ORIGIN + Vector2(cos(a), sin(a)) * RING_RADIUS, 0.8))
	# Pairs walk the streets inside the walls; their posts are points spread along each street's centre line.
	var streets: Array[Rect2] = []
	for road: Rect2 in TownLayout.ROADS:
		if TownLayout.TOWN.encloses(road):
			streets.append(road)
	for i in POST_PATROL:
		var road := streets[(i / 2) % streets.size()]
		var along := (float((i / 2) / streets.size()) + 0.5) / ceilf(float(POST_PATROL / 2) / streets.size())
		var point := Vector2(road.get_center().x, lerpf(road.position.y, road.end.y, along)) if road.size.y > road.size.x \
			else Vector2(lerpf(road.position.x, road.end.x, along), road.get_center().y)
		out.append(_spot_near(point, 0.8))
	while out.size() > count:
		out.pop_back()
	while out.size() < count:
		out.append(_spot_near(TownLayout.BARRACKS_YARD.get_center(), 1.4))
	return out


## How loud the panic bed should be, 0 to 1, for this many running citizens.
static func bed_level_for(running: int) -> float:
	return clampf(float(running) / BED_FULL, 0.0, 1.0)


## The mission paused (or the results are up over it): hold the bed where it is.
func pause_bed(paused: bool) -> void:
	if _bed != null:
		_bed.stream_paused = paused


## Silence the bed outright (the mission is quitting): unlike pause_bed(), nothing resumes it -- the crowd keeps
## processing for the few frames Battlefield.quit() waits out, and without this latch a still-running citizen
## would have _update_bed() call play() right back. Battlefield.quit() stops its own Sfx pool and waits out the
## audio thread before it exits -- the bed is not in that pool, so it needs to be stopped before that wait, or
## a bed still playing at process exit leaks its audio playback.
func stop_bed() -> void:
	_bed_stopped = true
	if _bed != null:
		_bed.stop()


func alive_citizens() -> int:
	return _alive(citizens)


func alive_soldiers() -> int:
	return _alive(soldiers)


func _alive(list: Array[Person]) -> int:
	var n := 0
	for p in list:
		if is_instance_valid(p) and p.is_alive():
			n += 1
	return n


func _process(delta: float) -> void:
	advance(delta)


## One frame of every person, citizens then soldiers: the order they were spawned, which was the order the engine
## processed them in when each processed itself.
func step_people(delta: float) -> void:
	# While time stands still (freeze()) the living do not move or think; the dead still fall.
	var still := is_frozen()
	for p in citizens:
		if is_instance_valid(p) and not p.inside and not (still and p.is_alive()):
			p.frame(delta)
	for p in soldiers:
		if is_instance_valid(p) and not (still and p.is_alive()):
			p.frame(delta)


## Gate queues, escapes and the crowd clock. Runs from _process; tests call it directly.
func advance(delta: float) -> void:
	if _freeze_left > 0.0:
		_freeze_left -= delta
		return
	_clock += delta
	threats.step(delta)
	_spread_fright()
	_watch_in -= delta
	if _watch_in <= 0.0:
		_watch_in = 1.0 / WATCH_HZ
		_watch_threats()
	if routine != null:
		routine.step(delta)
	if evac != null:
		evac.step(delta)
	fires.step(delta)
	if shelters != null:
		shelters.step(delta)
	_stage_in -= delta
	if _stage_in <= 0.0:
		_stage_in = 0.5
		alarms.update(alarm, threats.active_count(), _clock)
	if bell != null:
		bell.step(delta)
	if rite != null:
		rite.step(delta)
	if engineers != null:
		engineers.step(delta)
	if ferry != null:
		ferry.step(delta)
	if plague != null:
		plague.step(delta)
	if madness != null:
		madness.step(delta)
	if marshals != null:
		marshals.step(delta)
	if escorts != null:
		escorts.step(delta)
	if rescue != null:
		rescue.step(delta)
	if is_instance_valid(_drawer):
		# Redrawn while something shows, and once more as it stops, to clear it.
		var showing := (_drawer as ResponseDrawer).showing()
		if showing or _drawer.get_meta("shown", false):
			_drawer.set_meta("shown", showing)
			_drawer.queue_redraw()
			if is_instance_valid(_ground_drawer):
				_ground_drawer.queue_redraw()
	_settle_doom()
	_free_jams()
	_tend_households()
	_return_investigators()
	_gates()
	_escapes()
	_prune_soldiers()
	_voice_tokens = minf(VOICE_BUDGET, _voice_tokens + VOICE_BUDGET * delta)
	_purge_in -= delta
	if _purge_in <= 0.0:
		_purge_in = 1.0
		_field.purge()
	_update_bed(delta)


## Rows fanned out in front of a gate's doorway on the town side, starting QUEUE_DEPTH0 in (beyond the wall's
## own shadow) and nearest that point first, walkable only. The crowd widens as it backs into the town, the way
## a real one does.
func queue_spots(gate: Structure) -> Array[Vector2]:
	if _spots.has(gate):
		return _spots[gate]
	var out_dir := outward_of(gate)
	var side := Vector2(-out_dir.y, out_dir.x)
	var face := gate.center() - out_dir * (absf(gate.footprint.size.dot(out_dir)) * 0.5 + GATE_DOOR)
	# Built as one continuous path, nearest row first and snaking left-right-left row to row (not always left
	# to right) -- not re-sorted by plain distance to face, which would let a row's far edge sort ahead of the
	# next row's near centre and zig-zag between the two sides of a single row. _gates() advances the whole
	# waiting crowd by one array index at a time as people are let through, so a neighbour in the fan has to be
	# a neighbour in this array too (in both directions, row to row as well as within one), or the person
	# handed that index has to cross the row -- or jump from one edge of the fan clear over to the other -- to
	# reach it.
	var spots: Array[Vector2] = []
	var row := 0
	var depth := QUEUE_DEPTH0
	while depth <= QUEUE_DEPTH0 + QUEUE_REACH:
		var half := 1.2 + depth * 0.6
		var count := int(half * 2.0 / QUEUE_SPACING) + 1
		var stagger := QUEUE_SPACING * 0.5 if row % 2 == 1 else 0.0
		var order := range(count) if row % 2 == 0 else range(count - 1, -1, -1)
		for i in order:
			var spot := face - out_dir * depth + side * (-half + stagger + QUEUE_SPACING * float(i))
			if _grid == null or _grid.walkable(spot):
				spots.append(spot)
		row += 1
		depth += QUEUE_SPACING * 0.87
	_spots[gate] = spots
	return spots


## The way out through a gate: straight across the wall it stands in, away from the town. (Its centre's direction
## from the town's middle only works for a gate in the middle of its wall; the Side Gate is not.)
static func outward_of(gate: Structure) -> Vector2:
	var c := gate.center()
	if absf(c.x) > absf(c.y):
		return Vector2(signf(c.x), 0.0)
	return Vector2(0.0, signf(c.y))


## How many people are waiting at a gate right now.
func waiting_at(gate: Structure) -> int:
	var n := 0
	var spots := queue_spots(gate)
	for p in citizens:
		if is_instance_valid(p) and p.queue_spot != Vector2.INF and spots.has(p.queue_spot):
			n += 1
	return n


func _gates() -> void:
	for gate in _town.gates:
		if not is_instance_valid(gate) or gate.destroyed:
			_release_all(gate)
			continue  # rubble is no bottleneck
		if not gate.walkable:
			continue  # a barred postern
		var centre := gate.center()
		var outward := outward_of(gate)
		var spots := queue_spots(gate)
		var face := centre - outward * (absf(gate.footprint.size.dot(outward)) * 0.5 + GATE_DOOR)
		# Each person this gate has released keeps its own pass until it is through (more than a third of the
		# way past the doorway's centre line), dead, no longer fleeing, or has wandered off -- unlike the old
		# single shared pass, several can be on their way out at once, so a slow one never looks like a jam.
		for p in citizens:
			if not is_instance_valid(p) or p.passing_gate != gate:
				continue
			var rel := p.ground_pos - centre
			if rel.dot(outward) > 0.3 or not p.is_alive() or p.mind != Person.Mind.FLEE \
					or p.ground_pos.distance_to(face) > QUEUE_DEPTH0 + QUEUE_REACH + 2.0:
				p.passing_gate = null
		# The waiting crowd: fleeing, in front of the doorway, not yet released.
		var crowd_here: Array[Person] = []
		for p in citizens:
			if not is_instance_valid(p) or not p.is_alive() or p.mind != Person.Mind.FLEE or p.passing_gate == gate:
				continue
			var rel := p.ground_pos - centre
			var in_front := rel.dot(outward) <= 0.0 \
				and p.ground_pos.distance_to(face) <= QUEUE_DEPTH0 + QUEUE_REACH + 0.5
			if in_front:
				crowd_here.append(p)
			elif spots.has(p.queue_spot):
				p.release_from_queue()  # it left this gate's crowd (thrown clear, or through)
		if crowd_here.is_empty():
			continue
		# Order by who joined the queue first, not by distance: a distance sort every tick re-ranked people as
		# they walked (two people converging from the same direction kept overtaking each other in "distance
		# to face", so the gate kept swapping which spot each of them was walking to, and neither ever
		# arrived). Arrival order does not have that problem, and unlike ordering by the spot each person
		# already holds, it also is not upset by queue_spots()'s own distance sort, which zig-zags between the
		# two sides of a row rather than running left to right -- two neighbours could hold spots on opposite
		# sides of the same row and, ordered by spot index, swap them outright the next time the queue shuffled
		# forward. A newcomer with no turn yet falls in after everyone already waiting, nearest the face first.
		crowd_here.sort_custom(func(a: Person, b: Person) -> bool:
			if a.queue_since < 0.0 and b.queue_since < 0.0:
				return a.ground_pos.distance_squared_to(face) < b.ground_pos.distance_squared_to(face)
			if a.queue_since < 0.0 or b.queue_since < 0.0:
				return b.queue_since < 0.0
			if not is_equal_approx(a.queue_since, b.queue_since):
				return a.queue_since < b.queue_since
			# Joined in the same tick (a burst of newcomers gets one queue_since between them): break the tie
			# by spawn order (stagger_key), which never changes, rather than leaving it to sort_custom's own stability --
			# that let two same-tick joiners flip order the next time the queue's composition changed.
			return a.stagger_key() < b.stagger_key())
		# The gate opens on the clock alone: each passer now keeps its own pass, so there is no "previous
		# passer must be gone" condition to also satisfy, only the interval -- and that alone still limits the
		# gate to one release per GATE_INTERVAL.
		var first := 0
		# A blighted gate is jammed (v0.05), a held one too (v0.09): its crowd waits, nobody passes.
		if _clock >= float(_gate_next.get(gate, -1.0)) and not gate.blighted \
				and _clock >= float(_held.get(gate, -1.0)):
			var interval := profile.postern_interval if gate.art_tag == &"postern" else GATE_INTERVAL
			# Marshals at the mouth (v0.07) let them through faster.
			_gate_next[gate] = _clock + interval / (marshals.speed_at(face) if marshals != null else 1.0)
			crowd_here[0].release_from_queue()
			crowd_here[0].passing_gate = gate
			first = 1
		for i in range(first, crowd_here.size()):
			var slot := i - first
			var p: Person = crowd_here[i]
			if p.queue_since < 0.0:
				p.queue_since = _clock
			p.queue_spot = spots[mini(slot, spots.size() - 1)]


## A gate that fell lets its whole crowd go, waiting or already walking through it.
func _release_all(gate: Structure) -> void:
	# Untyped: a gate that fell before anyone queued at it has no spots yet, and the [] default is an untyped Array.
	var spots: Array = _spots.get(gate, [])
	for p in citizens:
		if not is_instance_valid(p):
			continue
		if spots.has(p.queue_spot):
			p.release_from_queue()
		if p.passing_gate == gate:
			p.passing_gate = null


## Someone got away other than on foot through an exit: carried off by the river boats (RiverFerry, which has
## already taken it out of the field).
func escape(p: Person) -> void:
	escaped_count += 1
	escaped.emit(p)
	citizens.erase(p)
	p.queue_free()


func _escapes() -> void:
	# Rebuilt rather than erased in place: a citizen DummyEnemy frees itself when its death fade ends, and
	# Array.erase() on an already-freed object raises a TypedArray validation error instead of removing it.
	var remaining: Array[Person] = []
	for p in citizens:
		if not is_instance_valid(p):
			continue
		if p.is_alive() and p.has_escaped():
			escaped_count += 1
			escaped.emit(p)
			_field.remove(p)
			p.queue_free()
			continue
		remaining.append(p)
	citizens = remaining


## Drop freed soldiers from the roster, the same way _escapes() prunes citizens -- never Array.erase() a freed
## object, that raises a typed-array error. A dead-but-not-yet-freed corpse stays here; rally() filters those.
func _prune_soldiers() -> void:
	var remaining: Array[Person] = []
	for p in soldiers:
		if is_instance_valid(p):
			remaining.append(p)
	soldiers = remaining


func _update_bed(delta: float) -> void:
	if _bed_stopped:
		return  # the mission quit; nothing revives the bed after that, even a citizen still running
	var running := 0
	for p in citizens:
		if is_instance_valid(p) and p.is_alive() and (p.mind == Person.Mind.PANIC or p.mind == Person.Mind.FLEE):
			running += 1
	_bed_level = move_toward(_bed_level, bed_level_for(running), BED_EASE * delta)
	if sfx == null or DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	if _bed == null:
		_bed = AudioStreamPlayer.new()
		_bed.bus = Sfx.BUS
		_bed.stream = Sfx.load_stream(&"crowd_panic")
		add_child(_bed)
	if _bed_level <= 0.001:
		if _bed.playing:
			_bed.stop()
		return
	if not _bed.playing:
		_bed.play()
	_bed.volume_db = BED_DB + linear_to_db(_bed_level)


## One voice from `p`, if the budget allows it.
func _voice(p: Person, cue: StringName) -> void:
	if is_hushed():
		return
	if _voice_tokens < 1.0:
		return
	_voice_tokens -= 1.0
	voices_played += 1
	if sfx != null:
		sfx.play(cue, p.ground_pos)


## A few of the people just frightened near `at` cry out, nearest first.
func _yelp(frightened: Array[Person], at: Vector2) -> void:
	frightened.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(at) < b.ground_pos.distance_squared_to(at))
	for i in mini(frightened.size(), VOICES_PER_CAST):
		_voice(frightened[i], &"cit_yelp")


## A cast of power `key` landed (v0.04): it registers a threat (PowerBook.REACH), and the people it reaches react
## by how near they are -- inside its area plus Person.THREAT_MARGIN they run clear of it, within sight or earshot
## they stop and look, beyond that nobody notices. A lane power (`dir` set, `length` above zero) is a threat along
## its whole lane: a tsunami's far end runs through streets the player never pressed on.
func on_cast(ground: Vector2, dir := Vector2.ZERO, length := 0.0, key := "") -> void:
	if PowerBook.is_quiet(key):
		# Nothing for the town to see (v0.05): Silent Doom and Blight report their own effects. A quiet power may still
		# unsettle it a little (its book entry's "alarm": a congregation forming, a bloom of madness).
		var unease := float(PowerBook.get_power(key).get("alarm", 0.0))
		if unease > 0.0:
			add_alarm(unease)
		return
	var reach: Array = PowerBook.REACH.get(key, PowerBook.REACH_DEFAULT)
	var radius := _cast_radius(key)
	var points: Array[Vector2] = [ground]
	if dir != Vector2.ZERO and length > 0.0:
		var step := maxf(radius, 1.0)
		var along := step
		var unit := dir.normalized()
		while along < length:
			points.append(ground + unit * along)
			along += step
		points.append(ground + unit * length)
	for point in points:
		threats.register(point, radius, float(reach[2]), float(reach[3]), float(reach[0]), float(reach[1]),
			StringName(key))
	_react(points, radius, float(reach[1]), ground, StringName(key))


## A cast's danger radius: its area on the ground (Targeting.AREAS), or v0.03's fright less the margin.
static func _cast_radius(key: String) -> float:
	var a: Dictionary = Targeting.AREAS.get(key, {})
	if a.has("r"):
		return float(a.r) + float(a.get("roam", 0.0))
	if a.has("half"):
		return float(a.half) + 1.0
	return PANIC_CAST - Person.THREAT_MARGIN


## Something frightening at `at` of `radius` (a maddened citizen turning on the crowd): a danger the town knows of for
## `seconds`, seen to `sight` and heard to `sound`, and everyone in reach reacts now (_react()).
func fright(at: Vector2, radius: float, severity: float, seconds: float, sight: float, sound: float, kind: StringName) -> void:
	threats.register(at, radius, severity, seconds, sight, sound, kind)
	var points: Array[Vector2] = [at]
	_react(points, radius, sound, at, kind)


## Everyone reached by a danger at `points` of `radius`, heard as far as `sound`: the near run, the rest look.
func _react(points: Array[Vector2], radius: float, sound: float, yelp_at: Vector2, kind := &"") -> void:
	var frightened: Array[Person] = []
	for p in citizens:
		if not is_instance_valid(p) or not p.is_alive():
			continue
		var best := INF
		var at := Vector2.INF
		for point in points:
			var d := p.ground_pos.distance_to(point)
			if d < best:
				best = d
				at = point
		if p.inside:
			continue
		if best <= radius + Person.THREAT_MARGIN:
			var was := p.mind
			p.panic(at, radius, kind)
			if p.mind == Person.Mind.PANIC and was != Person.Mind.PANIC:
				frightened.append(p)
				_spreads.append([_clock + _rng.randf_range(SPREAD_DELAY.x, SPREAD_DELAY.y), p])
		elif best <= sound:
			p.observe(at)
	_yelp(frightened, yelp_at)


## Frights passed on: a moment after a citizen was frightened, the calm people beside it stop and look its way.
func _spread_fright() -> void:
	if is_hushed():
		_spreads.clear()  # nobody can pass a fright on
		return
	var due: Array = []
	var later: Array = []
	for s in _spreads:
		(due if float(s[0]) <= _clock else later).append(s)
	_spreads = later
	for s in due:
		# Checked before the typed assignment: assigning a freed person to a Person variable is an error.
		if not is_instance_valid(s[1]):
			continue
		var src: Person = s[1]
		for p in citizens:
			if is_instance_valid(p) and p != src and p.is_alive() and p.mind == Person.Mind.CALM \
					and p.ground_pos.distance_to(src.ground_pos) <= SPREAD_REACH:
				p.observe(src._threat)


## People who walk into a lasting danger (a tornado still spinning) run from it too.
func _watch_threats() -> void:
	if threats.active_count() == 0:
		return
	for p in citizens:
		if not is_instance_valid(p) or not p.is_alive():
			continue
		if not (p.mind == Person.Mind.CALM or p.mind == Person.Mind.OBSERVE or p.mind == Person.Mind.RECOVER
				or p.mind == Person.Mind.COMPELLED):
			continue  # the compelled keep their survival (unless held absolutely: Person.panic())
		for t in threats.nearby(p.ground_pos, Person.THREAT_MARGIN):
			p.panic(t.at, float(t.radius), t.kind)
			break


## What happened in town reaching the alarm (a collapse, a death, a hit on the Citadel): until the Bell Tower has
## rung, only those nearby know, so it counts UNWARNED_ALARM of its worth (v0.05) -- a town kept from its bell
## mobilizes slower. Once the bell has rung, everything counts in full.
func _hear_alarm(points: float) -> void:
	if is_hushed():
		return  # nobody can call for help
	add_alarm(points if alarms.bell_rung else points * UNWARNED_ALARM)


## Silence the town for `seconds` (Voice of God): no shouts, no fright passed from one to the next, no call for help
## -- what happens raises no alarm and brings no one to look -- and no bell.
func hush(seconds: float) -> void:
	_hush_until = maxf(_hush_until, _clock + seconds)


func is_hushed() -> bool:
	return _clock < _hush_until


## Time stands still in the town for `seconds` (Abolition's clock): nobody alive moves or thinks, and nothing of the
## town's own runs -- its clock, its fires, its bell, its sickness. What a power does to it meanwhile is still done.
func freeze(seconds: float) -> void:
	_freeze_left = maxf(_freeze_left, seconds)


func is_frozen() -> bool:
	return _freeze_left > 0.0


## The warning is taken back (The Bell Lies): the town is as if its bell had never rung -- no citizen holds itself in
## an emergency for the bell's sake, and the keeper is left to ring again.
func unring_bell() -> void:
	alarms.bell_rung = false
	for p in citizens:
		if is_instance_valid(p) and p.is_alive() and p.awareness == Person.Awareness.EMERGENCY:
			p.awareness = Person.Awareness.CONCERNED
	if bell != null:
		bell.unring()


## For `seconds` the bell lies (The Bell Lies): rung, it tolls that all is well (false_bell()).
func bell_lies(seconds: float) -> void:
	_bell_lies_until = maxf(_bell_lies_until, _clock + seconds)


func is_bell_lying() -> bool:
	return _clock < _bell_lies_until


## The bell tolls, and it says all is well: the town is not warned, its alarm falls by LIE_CALM, and every citizen
## who hears it -- all of them -- takes heart for LIE_REASSURE (Person.reassure()).
func false_bell(at := TownLayout.BELL_TOWER.get_center()) -> void:
	for p in citizens:
		if is_instance_valid(p) and p.is_alive():
			p.reassure(LIE_REASSURE)
	if sfx != null:
		sfx.play(&"town_bell", at)
	add_alarm(-LIE_CALM)
	bell_lied.emit(at)


func add_alarm(points: float) -> void:
	var before := alarm
	alarm = clampf(alarm + points, 0.0, 100.0)
	if alarm != before:
		alarm_changed.emit(alarm)
	alarms.update(alarm, threats.active_count(), _clock)


## A new alarm stage (AlarmManager.stage_changed): what the town does about it.
func _on_stage(stage: AlarmManager.Stage, _reason: String) -> void:
	match stage:
		AlarmManager.Stage.LOCAL_EMERGENCY:
			if bell != null:
				bell.call_keeper()
		AlarmManager.Stage.CITY_EMERGENCY:
			rally()
			_regroup()
			if rite != null:
				rite.begin()
			if engineers != null:
				engineers.begin()
		AlarmManager.Stage.EVACUATION, AlarmManager.Stage.COLLAPSE:
			# The boats first, so the first evacuees to plan their way out already see the dock.
			if ferry != null:
				ferry.begin()
			if marshals != null:
				marshals.begin()
			_evacuate()


## Everyone still in town makes for the gates.
func _evacuate() -> void:
	if _fled_all:
		return
	_fled_all = true
	for p in citizens:
		if not is_instance_valid(p) or not p.is_alive():
			continue
		if p.mind == Person.Mind.SHELTER:
			continue  # ShelterManager sends them to the gates
		if p.mind == Person.Mind.DUTY:
			continue  # the bellkeeper and the clergy stay at their duty (off_duty() sends them on after)
		if p.mind == Person.Mind.ASSIST and p.assist_stays:
			continue  # an engineer at a fire works on (v0.08.2), as at its other duties
		if p.mind == Person.Mind.REGROUP and p.profile != null:
			# A household waiting at home leaves together (_tend_households()).
			if not _households.has(p.profile.family):
				_households[p.profile.family] = _clock
			continue
		if p.mind == Person.Mind.WHISPERED:
			p.whisper_resume_flee()  # Mind Whisper (v0.08): it lingers first, then flees
			continue
		p.flee()
	var shouted := 0
	for p in citizens:
		if shouted >= 2:
			break
		if is_instance_valid(p) and p.is_alive():
			_voice(p, &"cit_shout")
			shouted += 1


## Households regrouped at home leave together: once every member still regrouping is home, or after a while.
func _tend_households() -> void:
	if _households.is_empty():
		return
	for fam in _households.keys():
		var members: Array[Person] = []
		var home_all := true
		for p in citizens:
			if is_instance_valid(p) and p.is_alive() and p.mind == Person.Mind.REGROUP and p.profile != null \
					and p.profile.family == fam:
				members.append(p)
				home_all = home_all and not p.has_goal() and p.ground_pos.distance_to(p.profile.home) <= HOME_REACH
		if members.is_empty():
			_households.erase(fam)
		elif home_all or _clock - float(_households[fam]) >= HOUSEHOLD_WAIT:
			for p in members:
				p.flee()
			_households.erase(fam)


## City Emergency: the market closes (merchants go home) and REGROUP_SHARE of the rest go home to wait with theirs.
func _regroup() -> void:
	for i in citizens.size():
		var p := citizens[i]
		if not is_instance_valid(p) or not p.is_alive() or p.profile == null:
			continue
		if p.mind != Person.Mind.CALM and p.mind != Person.Mind.RECOVER:
			continue
		var merchant := p.profile.role == CitizenProfile.Role.MERCHANT
		# Whole households regroup together, chosen by family.
		if merchant or float((absi(p.profile.family) * 37 + 11) % 100) < REGROUP_SHARE * 100.0:
			p.regroup(p.profile.home)


## Someone's duty is done (the bell rung, the rite over): to the gates if the town is evacuating, else home to wait
## with the family.
func off_duty(p: Person) -> void:
	if not is_instance_valid(p) or not p.is_alive() or p.mind != Person.Mind.DUTY:
		return
	if p.soldier:
		p.send_to_post(p.post if p.post != Vector2.INF else p.ground_pos)  # back to its post (v0.07)
		return
	if _fled_all:
		p.mind = Person.Mind.CALM
		p.flee()
	elif p.profile != null:
		p.regroup(p.profile.home)


## The engineers' teams (v0.05): the craftsfolk living nearest the workshop -- two for each of the profile's teams --
## take the role, working at the workshop (`at`). None when the profile has no engineers.
func _appoint_engineers(at: Vector2) -> Array[Person]:
	var out: Array[Person] = []
	var want := profile.engineer_teams * 2
	if want <= 0 or at == Vector2.INF:
		return out
	var pool: Array[Person] = []
	for p in citizens:
		if p.profile != null and p.profile.role == CitizenProfile.Role.CRAFT:
			pool.append(p)
	pool.sort_custom(func(a: Person, b: Person) -> bool:
		return a.profile.home.distance_squared_to(at) < b.profile.home.distance_squared_to(at))
	for p in pool.slice(0, want):
		p.profile.role = CitizenProfile.Role.ENGINEER
		p.profile.work = at
		out.append(p)
	return out


## The point of `pts` nearest `to`, or Vector2.INF when there are none.
func _nearest_of(pts: Array, to: Vector2) -> Vector2:
	var best := Vector2.INF
	for g: Vector2 in pts:
		if best == Vector2.INF or g.distance_squared_to(to) < best.distance_squared_to(to):
			best = g
	return best


## A Bell Tower needs its keeper (v0.05): the resident living nearest it takes the post, working at the tower's foot.
## None in an Unprepared town.
func _appoint_bellkeeper(anchors: Dictionary) -> Person:
	var foot: Array = anchors.get("bell", [])
	if not profile.bell or foot.is_empty():
		return null
	var best: Person = null
	for p in citizens:
		if p.profile != null and p.profile.role == CitizenProfile.Role.RESIDENT and (best == null
				or p.profile.home.distance_to(foot[0]) < best.profile.home.distance_to(foot[0])):
			best = p
	if best != null:
		best.profile.role = CitizenProfile.Role.BELLKEEPER
		best.profile.work = foot[0]
	return best


## The Bell Tower rings (BellNetwork): every citizen learns of the danger, and the town calls City Emergency and the
## evacuation sooner.
func ring_bell(at := TownLayout.BELL_TOWER.get_center()) -> void:
	alarms.bell_rung = true
	for p in citizens:
		if is_instance_valid(p) and p.is_alive():
			p.awareness = maxi(p.awareness, Person.Awareness.EMERGENCY) as Person.Awareness
	if sfx != null:
		sfx.play(&"town_bell", at)
	alarms.update(alarm, threats.active_count(), _clock)


## A district's first local emergency: the two nearest patrolling soldiers go to look, and return after a while. A Lantern
## Knight (v0.10 M3) never does: _prune_soldiers() slides the soldiers added after the spawn down the roster, into the
## patrols' index range, so the range alone no longer says who patrols.
func _investigate(at: Vector2) -> void:
	if _rallied:
		return
	var first := POST_YARD + POST_WALLS + POST_CITADEL
	var pool: Array[Person] = []
	for i in range(first, mini(first + POST_PATROL, soldiers.size())):
		var p := soldiers[i]
		if is_instance_valid(p) and p.is_alive() and p.mind == Person.Mind.POST \
				and p.corps != Person.Corps.KNIGHT and not (escorts != null and escorts.guarding(p)):
			pool.append(p)
	pool.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_to(at) < b.ground_pos.distance_to(at))
	var spot := at if _grid.walkable(at) else _grid.nearest_walkable(at)
	if spot == Vector2.INF:
		return
	for k in mini(INVESTIGATORS, pool.size()):
		_investigating.append([pool[k], pool[k].anchor, _clock + INVESTIGATE_SECONDS])
		pool[k].send_to_post(_spot_near(spot, 0.8))


func _return_investigators() -> void:
	var kept: Array = []
	for e in _investigating:
		if not is_instance_valid(e[0]):
			continue
		var p: Person = e[0]
		if _clock < float(e[2]):
			kept.append(e)
		elif p.is_alive() and p.mind == Person.Mind.POST and not (escorts != null and escorts.guarding(p)):
			p.send_to_post(e[1])  # (one since taken as an escort stays with its duty)
	_investigating = kept


## Every soldier leaves its post for a slot on the Citadel's ring. Only soldiers without a role (v0.07): the others have
## their own work.
func rally() -> void:
	if _rallied:
		return
	_rallied = true
	var living: Array[Person] = []
	for p in soldiers:
		if is_instance_valid(p) and p.is_alive() and p.corps == Person.Corps.NONE:
			living.append(p)
	for i in living.size():
		var p := living[i]
		var a := TAU * float(i) / float(maxi(living.size(), 1))
		p.send_to_post(_spot_near(TownLayout.CITADEL_ORIGIN + Vector2(cos(a), sin(a)) * RING_RADIUS, 0.6), true)
	if sfx != null:
		sfx.play(&"sol_rally", TownLayout.CITADEL_ORIGIN)
	rallied.emit()


## Whether `p` stands on the rally ring (v0.09.1): a living soldier without a role, rallied, and within RING_RADIUS +
## RING_REACH of the Citadel.
func on_ring(p: Person) -> bool:
	return is_instance_valid(p) and p.soldier and p.is_alive() and p.corps == Person.Corps.NONE \
		and p.mind == Person.Mind.RALLY \
		and p.ground_pos.distance_to(TownLayout.CITADEL_ORIGIN) <= RING_RADIUS + RING_REACH


## How many soldiers stand on the rally ring (v0.09.1): the Citadel's garrison, asked once per hit on it.
func ring_count() -> int:
	if not _rallied:
		return 0
	var n := 0
	for p in soldiers:
		if on_ring(p):
			n += 1
	return n


## The reserve (v0.09.1): once the soldiers have rallied, a marshal, escort or rescuer killed is replaced by the living
## soldier on the ring nearest it. That soldier takes the role and the dead one's post, and the role's manager puts it
## to work: a marshal at its way out, an escort on the duty it guarded (or one short of escorts), a rescuer in its squad.
## One replacement for each death; with the ring empty, nobody.
func _refill(dead: Person) -> void:
	if not _rallied or not dead.corps in [Person.Corps.MARSHAL, Person.Corps.ESCORT, Person.Corps.RESCUE]:
		return
	var best: Person = null
	for p in soldiers:
		if on_ring(p) and (best == null
				or p.ground_pos.distance_squared_to(dead.ground_pos) < best.ground_pos.distance_squared_to(dead.ground_pos)):
			best = p
	if best == null:
		return
	best.corps = dead.corps
	best.post = dead.post
	match dead.corps:
		Person.Corps.MARSHAL:
			if marshals != null:
				marshals.refill(best, dead)
		Person.Corps.ESCORT:
			if escorts != null:
				escorts.refill(best, dead)
		Person.Corps.RESCUE:
			if rescue != null:
				rescue.refill(best, dead)


## Raise the town's readiness mid-mission (v0.09, between the acts of a night): never lower. Responses the old profile
## lacked turn on -- the rite, the boats (and the postern), the engineers, more marshals -- unless their building is
## gone (a fallen or defiled cathedral, a ruined or defiled dock: that response stays ended); ones already due by the
## alarm stage start at once. The escorts follow the new duties (v0.09.1, _raise_escorts(); not announced). The rescue
## squads are not raised: RescueManager groups its squads at setup. Returns what turned on.
func raise_profile(p: ResponseProfile) -> PackedStringArray:
	var on := PackedStringArray()
	if p.level() <= profile.level():
		return on
	profile = p
	alarms.regroup_seconds = p.regroup_seconds
	if bell != null and bell.state in [BellNetwork.State.IDLE, BellNetwork.State.WAITING]:
		bell.climb = p.bell_climb
	if p.rite and rite != null and rite.off_by_profile and _standing(rite.cathedral):
		rite = BanishingRite.new().setup(self, _env, _grid)
		if rite.state != BanishingRite.State.ENDED:
			on.append("rite")
	if p.boats and ferry != null and ferry.off_by_profile and _standing(ferry.dock):
		if is_instance_valid(_town.postern) and not _town.postern.walkable and not _town.postern.destroyed:
			_town.open_postern()
			_grid.refresh(_town.postern)
		ferry = RiverFerry.new().setup(self, _env, _grid, _field)
		if ferry.state != RiverFerry.State.ENDED:
			evac.add_boat_exit(ferry.board_at, ferry)
			on.append("boats")
	if p.engineer_teams > 0 and engineers != null and engineers.teams.is_empty():
		engineers = EngineerManager.new().setup(self, _env, _grid, _town, _appoint_engineers(_workshop), _workshop)
		if not engineers.teams.is_empty():
			on.append("engineers")
	if _raise_marshals() > 0:
		on.append("marshals")
	if alarms.stage >= AlarmManager.Stage.CITY_EMERGENCY:
		if on.has("rite"):
			rite.begin()
		if on.has("engineers"):
			engineers.begin()
	_raise_escorts()  # (unannounced: the duties that need them are)
	if alarms.stage >= AlarmManager.Stage.EVACUATION:
		if on.has("boats"):
			ferry.begin()
		if marshals != null:
			marshals.begin()
	return on


## A response's building is there to use (raise_profile()): found, standing and not blighted.
static func _standing(s: Structure) -> bool:
	return is_instance_valid(s) and not s.destroyed and not s.blighted


## More marshals for a raised profile: soldiers on the walls without a role take it, in post order, up to the new count.
func _raise_marshals() -> int:
	var exits := 2 + (2 if profile.boats else 0)
	var want := profile.marshals_per_exit * exits
	var have := 0
	for p in soldiers:
		if is_instance_valid(p) and p.is_alive() and p.corps == Person.Corps.MARSHAL:
			have += 1
	var added := 0
	for i in range(POST_YARD, mini(POST_YARD + POST_WALLS, soldiers.size())):
		if have + added >= want:
			break
		var p := soldiers[i]
		if is_instance_valid(p) and p.is_alive() and p.corps == Person.Corps.NONE:
			p.corps = Person.Corps.MARSHAL
			added += 1
	return added


## More escorts for a raised profile (v0.09.1): patrols without a role take it, in post order, up to the new
## escort_cap().
func _raise_escorts() -> int:
	var want := escort_cap(profile)
	var have := 0
	for p in soldiers:
		if is_instance_valid(p) and p.is_alive() and p.corps == Person.Corps.ESCORT:
			have += 1
	var added := 0
	var first := POST_YARD + POST_WALLS + POST_CITADEL
	for i in range(first, mini(first + POST_PATROL, soldiers.size())):
		if have + added >= want:
			break
		var p := soldiers[i]
		if is_instance_valid(p) and p.is_alive() and p.corps == Person.Corps.NONE:
			p.corps = Person.Corps.ESCORT
			added += 1
	return added


## Hold a gate shut for `seconds` (v0.09: the festival's crowd jams the gates): its queue waits, nobody passes.
func hold_gate(g: Structure, seconds: float) -> void:
	_held[g] = _clock + seconds


## The leaderless town (v0.09: the Prince died unseen): the soldiers never rally on the Citadel.
func forgo_rally() -> void:
	_rallied = true


func clear() -> void:
	if is_instance_valid(_ticker):
		if _ticker.is_inside_tree():
			_ticker.queue_free()
		else:
			_ticker.free()
	_ticker = null
	for p in citizens + soldiers:
		if is_instance_valid(p):
			if p.is_inside_tree():
				p.queue_free()
			else:
				p.free()
	citizens.clear()
	soldiers.clear()
	threats.clear()
	_spreads.clear()
	alarms.reset()
	fires.clear()
	if shelters != null:
		shelters.clear()
	_households.clear()
	_doomed.clear()
	_jams.clear()
	_held.clear()
	_thorn_alarm_at = -INF
	_hush_until = -INF
	_bell_lies_until = -INF
	_freeze_left = 0.0
	_investigating.clear()
	for d in [_drawer, _ground_drawer]:
		if is_instance_valid(d):
			(d as Node).queue_free()
	_drawer = null
	_ground_drawer = null
	bell = null
	rite = null
	engineers = null
	ferry = null
	if plague != null:
		plague.clear()
	plague = null
	if madness != null:
		madness.clear()
	madness = null
	if marshals != null:
		marshals.clear()
	marshals = null
	if escorts != null:
		escorts.clear()
	escorts = null
	if rescue != null:
		rescue.clear()
	rescue = null
	_gate_next.clear()
	_spots.clear()
	alarm = 0.0
	escaped_count = 0
	killed_citizens = 0
	killed_soldiers = 0
	spawned_citizens = 0
	spawned_soldiers = 0
	_rallied = false
	_fled_all = false
	_citadel_hit = false
	_clock = 0.0
	_purge_in = 1.0
	_voice_tokens = VOICE_BUDGET
	voices_played = 0


func _on_structure_destroyed(s: Structure, _kind: StringName) -> void:
	if s.role == &"thorns":
		return  # a bramble burnt or blasted away: no incident, nothing to flee
	if s.role != &"citadel":
		_hear_alarm(ALARM_BUILDING)
	var at := s.center()
	if s.role != &"citadel" and not is_hushed() and alarms.incident(at):
		_investigate(at)
	var radius := s.footprint.size.length() * 0.5 + COLLAPSE_RADIUS
	threats.register(at, radius, 0.4, COLLAPSE_SECONDS, COLLAPSE_SIGHT, COLLAPSE_SOUND, &"collapse")
	var points: Array[Vector2] = [at]
	_react(points, radius, COLLAPSE_SOUND, at, &"collapse")
	if is_instance_valid(_town) and s == _town.bridge:
		# The south route just closed: everyone already walking it needs a new plan.
		for p in citizens:
			if is_instance_valid(p) and p.is_alive() and p.mind == Person.Mind.FLEE:
				p.replan()


func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	var p := e as Person
	if p == null:
		return
	if p.soldier:
		killed_soldiers += 1
		_refill(p)
	else:
		killed_citizens += 1
	if kind == &"doom":
		_doomed.append(p)  # seen or not, judged once the cast's other victims have fallen too
		return
	if not is_hushed() and alarms.incident(p.ground_pos):
		_investigate(p.ground_pos)
	_hear_alarm(ALARM_KILL)


## The nearest living person -- citizen or soldier, not inside -- within DOOM_WITNESS of `at`, or null: who saw a death
## there (v0.08: Silent Doom's witness rule, and The Warning's relay). `exclude` is never chosen.
func nearest_witness(at: Vector2, exclude: Person = null) -> Person:
	var best: Person = null
	var best_d := DOOM_WITNESS
	for group: Array[Person] in [citizens, soldiers]:
		for p in group:
			if not is_instance_valid(p) or p == exclude or not p.is_alive() or p.inside:
				continue
			var d := p.ground_pos.distance_to(at)
			if d <= best_d:
				best = p
				best_d = d
	return best


## Silent Doom's dead (v0.05), judged after all of a cast's victims have fallen (so they never witness each other):
## nobody living within DOOM_WITNESS, and the town never knows; otherwise those near panic at a small danger and the
## death raises the alarm like any other. The seen victims are reacted to together (v0.07.1): with no cap a cast can
## take a crowd, and a witness among them would otherwise panic -- and plan a fresh path -- once for each.
func _settle_doom() -> void:
	if _doomed.is_empty():
		return
	var dead := _doomed
	_doomed = []
	var seen_at: Array[Vector2] = []
	for v in dead:
		if not is_instance_valid(v):
			continue
		var at := v.ground_pos
		var seen := nearest_witness(at) != null
		if not seen:
			continue
		threats.register(at, 0.6, 0.3, 3.0, DOOM_WITNESS, DOOM_WITNESS + 1.0, &"doom")
		seen_at.append(at)
		if alarms.incident(at):
			_investigate(at)
		_hear_alarm(ALARM_KILL)
	if not seen_at.is_empty():
		_react(seen_at, 0.6, DOOM_WITNESS + 1.0, seen_at[0], &"doom")


## Something built mid-mission (v0.06): the gate spots are found again round it; a thorn wall is noticed.
func _on_structure_added(s: Structure) -> void:
	_spots.clear()
	if s.role != &"thorns":
		return
	if _clock - _thorn_alarm_at > THORN_WALL:
		_thorn_alarm_at = _clock
		add_alarm(THORN_ALARM)
	for p in citizens:
		if is_instance_valid(p) and p.is_alive() and p.ground_pos.distance_to(s.center()) <= THORN_LOOK:
			p.observe(s.center())


## Blight (v0.05): one alarm, and a gate jams for GATE_JAM seconds.
func _on_blighted(s: Structure) -> void:
	add_alarm(BLIGHT_ALARM)
	if s.kind == Structure.Kind.GATE:
		_jams[s] = _clock + GATE_JAM


func _free_jams() -> void:
	if _jams.is_empty():
		return
	for g in _jams.keys():
		if _clock >= float(_jams[g]):
			_jams.erase(g)
			if is_instance_valid(g):
				_env.unblight(g)


## The Citadel reports every hit that takes health; the first one is the alarm bell.
func _on_citadel_health(_fraction: float) -> void:
	if _citadel_hit:
		return
	_citadel_hit = true
	_hear_alarm(ALARM_CITADEL_HIT)
	rally()


## Order breaks down (the Citadel fell, or stability ran out; Rules calls this).
func order_collapses() -> void:
	if alarms.collapsed:
		return
	alarms.collapsed = true
	alarms.update(alarm, threats.active_count(), _clock)


func _on_citadel_fallen() -> void:
	order_collapses()
	for p in soldiers:
		if is_instance_valid(p) and p.is_alive() and p.corps == Person.Corps.NONE:
			p.hold_ground()
