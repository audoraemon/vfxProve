class_name LanternWatch
extends RefCounted
## The Lantern Turns (v0.11.2, spec 4): what the bell's toll does on a Lantern night instead of losing it. The first toll lights the Temple's
## pale beam and the Lantern STIRS: dawn comes 1.5 times as fast. A loud power cast into the beam, or a death someone sees inside it, makes it
## BURN: 2.0 times as fast, a second beam. The Lantern-Bearer (Task 10) carries its flame to the bell tower; kill him and the Lantern goes
## BLIND for the rest of the act, the clock back to 1.0. On a Herald night (Task 11) the bell's ringer runs for the Temple instead: a Herald
## who gets in has the Lantern HEAR, and the night is lost (HeraldObjective).
##
## It lives on Rules (`Rules.lantern`, R38), not on the director: directors often override step() without super, and the clock and the HUD
## read it. Rules sets `clock_rate = rate()` every frame and steps this after the director. Mission builds one when the mission's `lantern`
## is not "" (MissionDef.lantern: herald, watch or gaze).
##
## Clocks: the Lantern's own times (`tolled_at`, the Bearer's AFTER) are MISSION seconds (Rules.mission_time(), which Abolition's clock law
## stops), while the strip's EventTimelines keep stepping through Abolition as they always have (a deliberate difference, v0.11.2 pre-flight);
## its reflexes -- the beam's sweep and hold, a hint's seconds, a walker's pace -- are real time.
##
## Seams: Task 10 fills `_bearer_*` and Task 11 fills `_herald_*` (each a no-op here), so this file's shape is fixed by Task 7.

signal stage_changed(stage: int)

enum Stage { ASLEEP, STIRRING, BURNING, BLIND }

## The three kinds of Lantern night (MissionDef.lantern).
const KIND_HERALD := "herald"
const KIND_WATCH := "watch"
const KIND_GAZE := "gaze"

## The clock's rate in each stage (indexed by Stage): Asleep, Stirring, Burning, Blind.
const RATES := [1.0, 1.5, 2.0, 1.0]
## What the toll adds to the Gaze on a gaze night (it used to fill it).
const GAZE_TOLL := 40.0
## Seconds a beam stays where it heard a noise before it goes back to its sweep (Searchlight.hold).
const BEAM_HOLD := 6.0
## Seconds the burning hint holds the how-to-win line after the Lantern burned.
const BURN_HINT := 8.0
## A Herald comes down the bell tower this long (real seconds) before he walks, and walks this fraction of his pace (Task 11).
const HERALD_DESCEND := 5.0
const HERALD_SLOW := 0.4

const TOLL_BANNER := "THE BELL TOLLS - THE LANTERN TURNS"
const BURN_BANNER := "THE LANTERN BURNS - DAWN RUSHES"
const BLIND_BANNER := "THE LANTERN IS BLIND - DAWN SLOWS"
const HEARD_BANNER := "THE LANTERN HEARS"

## The cues played at the Temple (catalogued by Task 13; nothing plays until they exist).
const CUE_FLARE := &"lantern_flare"
const CUE_BURN := &"lantern_burn"
const CUE_BLIND := &"lantern_blind"

var kind := ""
var stage := Stage.ASLEEP
## The bell has tolled (latched: an unring and a second toll change nothing, R23), and the mission second it did.
var tolled := false
var tolled_at := -1.0
## The Lantern's own pale beam from the Temple's spire: it hunts every noise it hears and holds each BEAM_HOLD seconds.
var light: Searchlight
## A Herald reached the Temple's door: the Lantern heard (Task 11 sets it; HeraldObjective loses the night on it).
var heard := false
## The bell was silenced (cracked, its tower fallen) after it was called -- there will be no toll (latched from the bell's signal; Task 11 reads it).
var bell_silenced := false
## Herald reports running for the Temple that are not a warning's own (the keeper who rang with no warning delivered), Task 11.
var heralds: Array[TempleReport] = []
## The Lantern-Bearer (Task 10: a LanternBearer); null until he sets out.
var bearer: RefCounted

var rules: Rules
var crowd: Crowd
var town: Town
var ctx: FxContext

var _bell: BellNetwork
var _fx: SearchlightFx
## Seconds (real) since the Lantern burned, for the hint.
var _burn_age := INF
## Deaths waiting to be judged, as [ground point, whether a beam covered it when it fell]: judged once the crowd has settled a cast's victims.
var _deaths: Array = []
var _released := false


func setup(r: Rules, c: Crowd, t: Town, x: FxContext, k: String) -> LanternWatch:
	rules = r
	crowd = c
	town = t
	ctx = x
	kind = k
	light = Searchlight.new().setup(TownLayout.TEMPLE.get_center())
	light.hunt = true
	light.hold = BEAM_HOLD
	light.beam_cap = 1
	_bell = c.bell
	if _bell != null:
		_bell.rung.connect(on_toll)
		_bell.silenced.connect(_on_silenced)
	rules.cast_made.connect(_on_cast)
	if c._field != null:
		c._field.enemy_killed.connect(_on_killed)
	return self


## The clock's rate in the present stage.
func rate() -> float:
	return float(RATES[stage])


## A Herald runs for the Temple's door and has not been stopped (Task 11 adds the warnings that herald).
func herald_running() -> bool:
	for h in heralds:
		if h.is_open():
			return true
	return false


## A Herald runs, or got in: the night's main objective (Warning, Stars) may not read DONE, whatever else is true (HeraldObjective loses
## a night the Lantern heard; the main one must never be read as a win before it).
func blocks_win() -> bool:
	return heard or herald_running()


## The first toll (R23: latched). Banner, the Temple's flare, one pale beam, Stirring; a gaze night's Gaze rises GAZE_TOLL; the director
## and the Bearer's and Heralds' seams are told. Blind is final: a Lantern that has gone blind turns no more.
func on_toll() -> void:
	if tolled or stage == Stage.BLIND or _released:
		return
	tolled = true
	tolled_at = rules.mission_time()
	_set_stage(Stage.STIRRING)
	light.beam_cap = 1
	light.light()
	_show_light()
	rules.banner.emit(TOLL_BANNER)
	_sound(CUE_FLARE)
	var director := rules.director
	if kind == KIND_GAZE and director != null and director.gaze != null:
		director.gaze.add(GAZE_TOLL)
	if director != null:
		director.on_toll()
	_bearer_schedule()
	_heralds_start()


## The Lantern burns: 2.0 times as fast, a second beam. It never falls back, and a blind one cannot (R23). A Lantern not yet tolled is
## tolled first -- this is how a test forces the stage.
func burn() -> void:
	if stage == Stage.BURNING or stage == Stage.BLIND or _released:
		return
	if not tolled:
		on_toll()
	if stage != Stage.STIRRING:
		return
	_set_stage(Stage.BURNING)
	_burn_age = 0.0
	light.beam_cap = Searchlight.MAX_BEAMS
	light.age = maxf(light.age, Searchlight.SECOND_AFTER)  # the second beam lights now, not after its own 30 s
	light.step(0.0, rules.time_left)  # ... and takes its place at once, so no frame draws it nowhere
	rules.banner.emit(BURN_BANNER)
	_sound(CUE_BURN)


## The Bearer is dead: the clock back to 1.0, the beams fade, for the rest of the act (R23). Whatever the stage was.
func blind() -> void:
	if stage == Stage.BLIND or _released:
		return
	_set_stage(Stage.BLIND)
	light.put_out()
	rules.banner.emit(BLIND_BANNER)
	_sound(CUE_BLIND)


## One frame (Rules.advance(), after the director). The beam's sweep is real time; the deaths are judged once the crowd has settled
## a cast's victims, as GazeMeter.judge_deaths() does.
func step(delta: float) -> void:
	if _released:
		return
	if light.on:
		light.step(delta, rules.time_left)
	_burn_age += delta
	_judge_deaths()
	if tolled:
		_bearer_step(delta)
	_herald_step(delta)


## The line the how-to-win plate takes (MissionHints.LANTERN) by spec 5.3's precedence: a Herald running, then Burning for BURN_HINT seconds,
## then the Bearer walking, then Stirring until he sets out; "" gives the mission's own line back (at the vigil, when Blind, asleep).
func hint_phase() -> String:
	if herald_running():
		return "herald"
	if stage == Stage.BURNING and _burn_age < BURN_HINT:
		return "burning"
	var b := _bearer_phase()
	if b == "walking":
		return "bearer"
	if (stage == Stage.STIRRING or stage == Stage.BURNING) and b == "":
		return "stirring"
	return ""


## What the HUD points out for the Lantern: the Heralds first (the instant loss), then the Bearer and his escorts.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	out.append_array(_herald_tags())
	out.append_array(_bearer_tags())
	return out


## The strip's rows for the Lantern, soonest first: {"in": mission seconds, "label": String}.
func strip_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append_array(_bearer_rows())
	out.append_array(_herald_rows())
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["in"]) < float(b["in"]))
	return out


## The clock's badge: "x1.5" while Stirring, "x2.0" while Burning, else "" (the HUD swaps the "x" for the multiplication sign when its font has one).
func badge() -> String:
	match stage:
		Stage.STIRRING:
			return "x1.5"
		Stage.BURNING:
			return "x2.0"
	return ""


## The Temple's door (rules.director's lantern_door(), else the same point for a night with no director).
func door() -> Vector2:
	return rules.director.lantern_door() if rules.director != null else MissionDirector.lantern_door_in(crowd)


## Let go: the world's signals, the beam and its drawing, and the Bearer's and Heralds' people.
func teardown() -> void:
	if _released:
		return
	_released = true
	if _bell != null:
		if _bell.rung.is_connected(on_toll):
			_bell.rung.disconnect(on_toll)
		if _bell.silenced.is_connected(_on_silenced):
			_bell.silenced.disconnect(_on_silenced)
	if is_instance_valid(rules) and rules.cast_made.is_connected(_on_cast):
		rules.cast_made.disconnect(_on_cast)
	if is_instance_valid(crowd) and crowd._field != null and crowd._field.enemy_killed.is_connected(_on_killed):
		crowd._field.enemy_killed.disconnect(_on_killed)
	light.put_out()
	if is_instance_valid(_fx):
		_fx.end_now()
	_fx = null
	_bearer_teardown()
	_herald_teardown()
	heralds.clear()
	_deaths.clear()


func _set_stage(s: Stage) -> void:
	stage = s
	stage_changed.emit(int(s))


## A cast (Rules.cast_made): a loud power is heard by the beam, and burns the Lantern when it is cast into a beam. A quiet one is neither
## heard nor seen (D19): it does nothing to the stage.
func _on_cast(_slot: int, key: String, at: Vector2) -> void:
	if _released or not light.on or PowerBook.is_quiet(key):
		return
	var burns := stage == Stage.STIRRING and light.touches(at)
	light.hear(at)
	if burns:
		burn()


## A death (the field's enemy_killed): the beam hears it at once; whether it burns the Lantern is judged later, once the crowd has decided
## who saw it (_judge_deaths()).
func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	if _released:
		return
	_bearer_killed(e)
	_herald_killed(e)
	if not light.on:
		return
	var at := e.ground_pos
	light.hear(at)
	if stage == Stage.STIRRING:
		_deaths.append([at, light.touches(at)])


## Each death noted that a beam covered when it fell burns the Lantern if someone living saw it (Crowd.nearest_witness()). It waits while the
## crowd is still judging a Silent Doom's victims, so a cast's victims never witness each other.
func _judge_deaths() -> void:
	if _deaths.is_empty() or not is_instance_valid(crowd) or not crowd._doomed.is_empty():
		return
	var burns := false
	for d: Array in _deaths:
		if bool(d[1]) and crowd.nearest_witness(d[0] as Vector2) != null:
			burns = true
	_deaths.clear()
	if burns:
		burn()


func _on_silenced(_reason: String) -> void:
	bell_silenced = true


func _show_light() -> void:
	if ctx != null and ctx.overhead != null and not is_instance_valid(_fx):
		_fx = FxTimeline.cast(SearchlightFx, ctx, light.spire, {"light": light, "pale": true, "dim": false}) as SearchlightFx


## A cue at the Temple, once it is catalogued.
func _sound(cue: StringName) -> void:
	if ctx != null and Sfx.CATALOG.has(cue):
		ctx.play(cue, light.spire)


# --- Task 10's seams (the Lantern-Bearer) ---------------------------------------------------------------------------------------------

## The toll fell: schedule the Bearer to set out BEARER_AFTER mission seconds later.
func _bearer_schedule() -> void:
	pass


func _bearer_step(_delta: float) -> void:
	pass


## A death, for the Bearer's judging (a TempleReport's on_killed()).
func _bearer_killed(_e: DummyEnemy) -> void:
	pass


## "" before he sets out, "walking" on the way to the tower, "vigil" at the tower, "dead".
func _bearer_phase() -> String:
	return ""


func _bearer_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	return out


func _bearer_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	return out


## The act ends: the Bearer's and his escorts' slowing is undone.
func _bearer_teardown() -> void:
	pass


# --- Task 11's seams (the Herald) -----------------------------------------------------------------------------------------------------

## The toll fell (or the bell was silenced): the keeper who rang, if no director claims him, becomes a TempleReport Herald.
func _heralds_start() -> void:
	pass


func _herald_step(_delta: float) -> void:
	pass


func _herald_killed(_e: DummyEnemy) -> void:
	pass


func _herald_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	return out


func _herald_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	return out


func _herald_teardown() -> void:
	pass
