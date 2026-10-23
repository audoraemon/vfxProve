class_name LanternWatch
extends RefCounted
## The Lantern Turns (v0.11.2, spec 4): what the bell's toll does on a Lantern night instead of losing it. The first toll lights the Temple's
## pale beam and the Lantern STIRS: dawn comes 1.5 times as fast. A loud power cast into the beam, or a death someone sees inside it, makes it
## BURN: 2.0 times as fast, a second beam. The Lantern-Bearer (LanternBearer) carries its flame to the bell tower; kill him and the Lantern goes
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
## Seams: `_bearer_*` are the Lantern-Bearer's (LanternBearer), `_herald_*` the Heralds' (TempleReport, and the warnings' own).

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
const HERALD_BANNER := "THE HERALD RUNS FOR THE TEMPLE"
const SILENT_BANNER := "THE BELL IS SILENT - THE WARNING RUNS FOR THE TEMPLE"
## The Herald's tag (spec 5.2): gold, as the Warning's carrier; the Temple's door orange, as every place.
const MARK_HERALD := Color("d8b23a")
const MARK_TEMPLE := Color("ff9a3a")
const STRIP_HERALD := "The Herald reaches the Temple"
## A strip row with no countdown shows this where the time would be (a Bearer waiting for a Herald, or with nobody free to carry the flame).
const NO_CLOCK := "--:--"

## The cues played at the Temple (catalogued in Sfx; a cue that is not in the catalogue is skipped).
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
## A Herald reached the Temple's door: the Lantern heard (hear(); HeraldObjective loses the night on it).
var heard := false
## The bell was silenced (cracked, its tower fallen) after it was called and before it tolled -- there will be no toll (latched from the bell's
## signal, which only a called bell emits; never set once the bell has tolled). On a Herald night the warnings run for the Temple on it
## (WarningDirector.heralding()).
var bell_silenced := false
## Herald reports running for the Temple that are not a warning's own: the keeper who rang with no warning delivered (a TempleReport
## each; the warnings' own Heralds are their directors', MissionDirector.herald_open()).
var heralds: Array[TempleReport] = []
## The Lantern-Bearer: null until he sets out (LanternBearer.AFTER mission seconds after the toll, or after the last Herald is gone on a Herald night).
var bearer: LanternBearer

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
## The mission second the Bearer sets out (tolled_at + LanternBearer.AFTER), set at the toll; on a Herald night it is pushed on while any Herald
## runs, so he sets out LanternBearer.AFTER seconds after the last Herald is gone (C16).
var _bearer_due := INF
## The first Herald's banner has been shown (once for the night, whoever runs first).
var _herald_said := false


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
		_bell.keeper_held = _keeper_is_herald
	rules.cast_made.connect(_on_cast)
	if c._field != null:
		c._field.enemy_killed.connect(_on_killed)
	return self


## The clock's rate in the present stage.
func rate() -> float:
	return float(RATES[stage])


## A Herald runs for the Temple's door and has not been stopped or got in: a report of the Lantern's own, or one of the night's warnings (the
## director's herald_open()).
func herald_running() -> bool:
	if _released:
		return false
	for h in heralds:
		if h.is_open():
			return true
	var d := rules.director if is_instance_valid(rules) else null
	return d != null and d.herald_open()


## A Herald reached the Temple's door: the Lantern hears, once. HeraldObjective loses the night on it; it is set in the same frame the Herald
## arrives, before the objectives are checked, so the night can never read as won in between (C7).
func hear() -> void:
	if heard or _released:
		return
	heard = true
	rules.banner.emit(HEARD_BANNER)


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
	if tolled:
		_bearer_step(delta)  # (the Bearer first: a death that blinds the Lantern must not also burn it in the same frame)
	_judge_deaths()
	_herald_step(delta)


## The line the how-to-win plate takes (MissionHints.LANTERN) by spec 5.3's precedence: a Herald running, then Burning for BURN_HINT seconds,
## then the Bearer walking, then Stirring until he sets out (or "seeking", when nobody was free to be the Bearer); "" gives the mission's own line back (at the vigil, when Blind, asleep).
func hint_phase() -> String:
	if herald_running():
		return "herald" if tolled else "herald_silent"
	if stage == Stage.BURNING and _burn_age < BURN_HINT:
		return "burning"
	var b := _bearer_phase()
	if b == "walking":
		return "bearer"
	if (stage == Stage.STIRRING or stage == Stage.BURNING) and b == "":
		return "seeking" if bearer != null and bearer.state == LanternBearer.State.WAITING else "stirring"
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
		_bell.keeper_held = Callable()
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


## The bell was silenced. Once it has tolled this changes nothing (C7: there was a toll, the Lantern turned, and a warning's errand is the
## Temple's door already); before, no toll will come, and on a Herald night the warnings run for the Temple on it (R13): they read `bell_silenced`
## themselves (WarningDirector.heralding()), and the first Herald's banner is _herald_step()'s, so nothing is started here.
func _on_silenced(_reason: String) -> void:
	if tolled or _released:
		return
	bell_silenced = true


func _show_light() -> void:
	if ctx != null and ctx.overhead != null and not is_instance_valid(_fx):
		_fx = FxTimeline.cast(SearchlightFx, ctx, light.spire, {"light": light, "pale": true, "dim": false}) as SearchlightFx


## A cue at the Temple, once it is catalogued.
func _sound(cue: StringName) -> void:
	if ctx != null and Sfx.CATALOG.has(cue):
		ctx.play(cue, light.spire)


# --- the Lantern-Bearer (Task 10) -----------------------------------------------------------------------------------------------------

## The toll fell: the Bearer sets out LanternBearer.AFTER mission seconds later.
func _bearer_schedule() -> void:
	_bearer_due = rules.mission_time() + LanternBearer.AFTER


## The Bearer sets out at his time and walks; his death (or a Blind Lantern) lets him go. Real time for the walk (D20).
func _bearer_step(delta: float) -> void:
	if stage == Stage.BLIND:
		if bearer != null and not bearer.dead():
			bearer.release()
		return
	if bearer == null:
		if herald_running():
			_bearer_due = rules.mission_time() + LanternBearer.AFTER  # he does not set out into a Herald's street: AFTER from the moment none runs (C16)
			return
		if rules.mission_time() < _bearer_due:
			return
		var d := rules.director
		var reserved: Array = d.reserved if d != null else []
		bearer = LanternBearer.new().setup(rules, crowd, door(), crowd.bell.foot if crowd.bell != null else door(), reserved,
			_busy)
		return
	bearer.step(delta)
	if bearer.dead():
		blind()


## A death, for the Bearer's judging.
func _bearer_killed(e: DummyEnemy) -> void:
	if bearer != null:
		bearer.on_killed(e)


## "" before he sets out, "walking" on the way to the tower, "vigil" at the tower, "dead".
func _bearer_phase() -> String:
	return bearer.phase() if bearer != null else ""


func _bearer_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if bearer != null:
		out.append_array(bearer.tags())
	return out


## The strip's rows, in mission seconds: before he sets out the wait, while he walks his real walk times the clock's rate (D21).
func _bearer_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not tolled or stage == Stage.BLIND:
		return out
	if bearer != null and bearer.state == LanternBearer.State.WAITING:
		out.append({"in": INF, "clock": NO_CLOCK, "label": "The Lantern seeks a Bearer"})  # nobody free to carry it: no countdown (C18)
	elif bearer == null and herald_running():
		out.append({"in": INF, "clock": NO_CLOCK, "label": "The Bearer waits for the Herald"})  # (C16)
	elif bearer == null:
		out.append({"in": maxf(0.0, _bearer_due - rules.mission_time()), "label": "The Lantern-Bearer sets out"})
	elif bearer.state == LanternBearer.State.WALKING:
		out.append({"in": bearer.seconds_left() * rules.clock_rate, "label": "The Bearer reaches the bell tower"})
	return out


## The act ends: the Bearer's and his escorts' slowing is undone.
func _bearer_teardown() -> void:
	if bearer != null:
		bearer.release()


## `p` is on the Bearer's errand (MissionDirector._report() leaves him be).
func has_errand(p: Variant) -> bool:
	return bearer != null and bearer.has_errand(p)


## `p` is already busy with a director's errand or a Herald's, or is one of the director's own Faithful watchers: not for the Bearer to take.
func _busy(p: Person) -> bool:
	var d := rules.director
	if d != null and (d.busy(p) or d.claims_herald(p) or d._carrying(p) or d.faithful.has(p)):
		return true
	for h in heralds:
		if h.carrier == p:
			return true
	return false


## The bellkeeper is a Herald running for the Temple (a warning's carrier, or the Lantern's own report): The Bell Lies' unrung bell must not
## send him back to the rope (BellNetwork.keeper_held; review-11's residual risk, C8). False before the toll and on a night with no Herald.
func _keeper_is_herald() -> bool:
	if not tolled or _released or _bell == null or not is_instance_valid(_bell.keeper):
		return false
	var k := _bell.keeper
	var d := rules.director if is_instance_valid(rules) else null
	if d != null and d.claims_herald(k):
		return true
	for h in heralds:
		if h.is_open() and h.carrier == k:
			return true
	return false


# (v0.11.2, ruling C10) The escorts are plain lay citizens on every night: converting them to Faithful on a gaze night made two hidden extra
# watchers, who stayed Faithful after the Lantern went blind. They still see a death as any citizen does.

# --- Task 11's seams (the Herald) -----------------------------------------------------------------------------------------------------

## The toll fell: on a Herald night the keeper who rang, if no warning claims him as its own carrier (MissionDirector.claims_herald()), is a Herald
## of his own -- a TempleReport at the Herald's pace, held HERALD_DESCEND seconds while he comes down the tower. His delivery has the Lantern
## hear. The warnings' own Heralds are their directors' (on_toll() has told them). A silenced bell tolls nothing and makes no report: the
## warning that called it is the Herald (WarningDirector.heralding()), and the banner is shown by _herald_step().
func _heralds_start() -> void:
	if kind != KIND_HERALD or not tolled:
		return
	var keeper: Variant = _bell.keeper if _bell != null else null
	if not is_instance_valid(keeper) or not (keeper as Person).is_alive():
		return
	var d := rules.director
	if d != null and d.claims_herald(keeper as Person):
		return
	var report := TempleReport.new(keeper as Person, door(), HERALD_SLOW, HERALD_DESCEND)
	report.skip = func(p: Person) -> bool:
		# A relay never picks one fleeing the town, a warning's own carrier (one kill never stops two Heralds), nor a wisher or a wish's target,
		# nor one on the Bearer's errand (C15).
		return p.mind == Person.Mind.FLEE or has_errand(p) or (is_instance_valid(d) and (d.claims_herald(p) or d.reserved.has(p)))
	heralds.append(report)


## One frame of the Lantern's own Heralds: each report is stepped, and the one that gets in is heard in the same frame; a carrier gone from the
## town ends his report. The first Herald of the night (a report or a warning's) shows the banner once.
func _herald_step(delta: float) -> void:
	for h in heralds:
		if not h.is_open():
			continue
		h.step(delta, crowd)
		if h.gone():
			h.dead = true
		elif h.delivered:
			hear()
	if not _herald_said and herald_running():
		_herald_said = true
		rules.banner.emit(HERALD_BANNER if tolled else SILENT_BANNER)


func _herald_killed(e: DummyEnemy) -> void:
	for h in heralds:
		h.on_killed(e)


## The Lantern's own Heralds, gold and pointed at (the warnings' carry theirs in their director's tags), and the Temple's door while any Herald runs.
func _herald_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if not herald_running():
		return out
	var rate := rules.clock_rate
	for h in heralds:
		if not h.is_open() or not is_instance_valid(h.carrier):
			continue
		var label := ""
		if h.descend_left() > 0.0:
			label = "HERALD - COMES DOWN IN %s" % UiTheme.clock(h.descend_left() * rate)
		else:
			label = "HERALD - AT THE TEMPLE IN %s" % UiTheme.clock(TempleReport.walk_seconds(h.carrier, h.door, h.slow) * rate)
		out.append(MapTag.person(h.carrier.ground_pos, MARK_HERALD, label, true))
	out.append(MapTag.place(door(), MARK_TEMPLE, "TEMPLE", 0.0, true))
	return out


## One strip row while a Herald runs: when the soonest reaches the Temple, in mission seconds.
func _herald_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var eta := INF
	var rate := rules.clock_rate
	for h in heralds:
		if h.is_open() and is_instance_valid(h.carrier):
			eta = minf(eta, (h.descend_left() + TempleReport.walk_seconds(h.carrier, h.door, h.slow)) * rate)
	if is_instance_valid(rules.director):
		eta = minf(eta, rules.director.herald_eta())
	if eta < INF:
		out.append({"in": eta, "label": STRIP_HERALD})
	return out


## The act ends: the reports' carriers get their pace and their day back.
func _herald_teardown() -> void:
	for h in heralds:
		h.unslow()
		if is_instance_valid(h.carrier) and is_instance_valid(crowd) and (h.carrier as Person).mind == Person.Mind.DUTY:
			crowd.off_duty(h.carrier)
