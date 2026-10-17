class_name LanternEyeDirector
extends HuntDirector
## The Lantern's Eye (v0.11 M6, Tier 5, mission spec §1; Anchors + Hunt): Halcyon's Searchlight sweeps the town from the Temple's spire
## all night, both beams lit from 0:00. The Inquisition hangs three great mirrors on the wall towers to aim it, one at a time on the Hunt
## type's chain (STEP_AT, CHAIN): each tower is a step's standard (Decision 213), the standing wall tower nearest its point, never the
## bell tower, a wish's or another mirror's (_tower_near(), Decision 214). The towers are stone tonight (_stone()): their own health
## never moves. A party of PARTY watchmen stands on posts POST_GAP apart along each tower's town-side face from the start, on guard
## within GUARD_REACH of the tower (plan decision 277). While one stands guard a blow only shakes the tower; unguarded it strikes the
## mirror's glass (MIRROR_HP, held here; _unguarded_blow()) and is heard (shield_hits). A blow strikes the glass at most BLOW_MAX, and
## the strokes of one Heaven Splitter are one blow (HEAVEN_GAP), so a mirror takes two Smites, or a Heaven Splitter and a Smite (the
## controller's ruling). At 0 the mirror shatters and its WRIGHTS, waiting inside the tower, come out to posts at its foot: REHANG
## seconds of one wright's work hangs a new glass at full health, and they go back in. Left shattered DRAIN seconds it is gone for good
## -- the Hunt's _break(): its party goes home and the next mirror comes on the chain. While a mirror stands unshattered the light
## hunts: every cast it hears (not a whisper, UNHEARD) draws the nearest beam, held HOLD seconds (Searchlight.hunt, hold); a
## Will-o'-Wisp is a decoy. A cast aimed inside a lit pool adds SEEN_CAST to the director's own Gaze, quiet or hunting (plan decision
## 279); a seen death adds GazeMeter.SEEN_DEATH; each rise has its banner. All three standing unshattered together for EYE_OPENS loses
## ("THE EYE OPENS", _found()); the third gone wins (HuntObjective). Every held person is kept from the town's flight by
## MissionDirector._hold_all().

## The Searchlight's spire: the Temple's centre (v0.11 M6, TownLayout.TEMPLE's), as The Vigil Flame's.
const SPIRE := Vector2(0.8, -8.7)
## Each mirror tower is the standing wall tower nearest its point, in the order the mirrors go up (v0.11 M6, Decision 214).
const TOWER_POINTS := [Vector2(0.0, -15.65), Vector2(15.65, 0.0), Vector2(-8.0, 15.65)]
## Each mirror tower's words on the banners, the strip and the tour (v0.11 M6).
const TOWER_WORDS := ["the north tower", "the east tower", "the south-west tower"]
## Each mirror's time at the latest, in the timeline's seconds (v0.11 M6, mission spec §1; tuned by the gate in the spec's order: CHAIN
## (30-45), STEP_AT[0] (40-60), DRAIN (15-20), MIRROR_HP (90-135), PARTY (2-3); EYE_OPENS (20-30) if doing nothing does not lose).
const STEP_AT := [40.0, 115.0, 180.0]
## Seconds after a mirror is gone for good that the next goes up at the latest (v0.11 M6).
const CHAIN := 30.0
## Watchmen in each tower's party (v0.11 M6).
const PARTY := 3
## How far apart a party's posts stand along the tower's face, and how far out from it the foot lies (v0.11 M6).
const POST_GAP := 2.4
const POST_OUT := 1.0
## How near the tower's footprint a guard stands guard (v0.11 M6).
const GUARD_REACH := 2.0
## Where a post may stand when its own spot along the face is walled in (v0.11 M6, _free_spot(): the east tower's town side is built up
## against its face): within POST_REACH of the tower, more than POST_SEP from the tower's other posts of its kind (one Doom takes one,
## Crowd.DOOM_WITNESS), the nearest such ground within POST_SEARCH of its own spot, looked for every POST_STEP.
const POST_REACH := 1.9
const POST_SEP := 2.2
const POST_SEARCH := 3.0
const POST_STEP := 0.25
## Seconds after he left that a guard back on his feet walks back, and after he fell that a relief takes his post (v0.11 M6).
const RETURN_AFTER := 20.0
const RELIEF_AFTER := 30.0
## A mirror's glass (v0.11 M6): its health; the most one blow takes off it (a Smite's worth); how long after a Heaven Splitter's first
## stroke on it the cast's later strokes only shake the tower (its whole effect, T_AFTER 4.3 s, falls inside), and their damage kind.
const MIRROR_HP := 90.0
const BLOW_MAX := SmiteFx.DAMAGE
const HEAVEN_GAP := 5.0
const HEAVEN_KIND := &"lightning"
## Seconds a shattered mirror lasts before it is gone for good (v0.11 M6).
const DRAIN := 20.0
## Wrights at each tower, how far apart their posts stand, and how near his post one stands at work (v0.11 M6).
const WRIGHTS := 2
const WRIGHT_GAP := 2.4
const WRIGHT_REACH := 1.2
## Which towers' wrights work from the tower's quiet side, out of the town beyond its outer face, and how far beyond that face (v0.11 M6,
## the controller's fix-round ruling): the south-west tower's foot is a busy street, where onlookers stopped by every Smite would see a
## wright fall, and the wall's own soldiers stand at its outer face, so the posts lie WRIGHT_OUT past it, more than a witness from them.
const QUIET_SIDE := [false, false, true]
const WRIGHT_OUT := 2.6
## Seconds of one wright's work that hang a new glass (v0.11 M6).
const REHANG := 10.0
## Seconds all three mirrors stand together before the Eye opens (v0.11 M6).
const EYE_OPENS := 30.0
## The light (v0.11 M6): how long a drawn beam holds its noise; what a seen cast adds to the Gaze; the casts it does not hear.
const HOLD := 8.0
const SEEN_CAST := 20.0
const UNHEARD := ["whisper"]
## How near zero the Eye's countdown counts as run out (v0.11 M6, plan decision 278).
const EYE_EPS := 0.001
## Where the camera rests (v0.11 M6, Decision 247): the spire just above the centre, the north tower at the upper right.
const CAMERA_AT := Vector2(0.0, -6.0)
## A shattered mirror's tag, orange (v0.11 M6).
const MARK_PLACE := Color("ff9a3a")
## The banners when the Gaze rises (v0.11 M6, the controller's ruling: every rise has one): a cast seen in the light, a death seen.
const SEEN_CAST_BANNER := "THE EYE SEES YOUR HAND"
const SEEN_DEATH_BANNER := "THE EYE SEES A DEATH"
## Blight on a mirror (v0.11.1, spec §7.3): its glass clouds; a guard holds it.
const BLIGHT_BANNER := "BLIGHT - THE MIRROR CLOUDS"
const BLIGHT_GUARDED := "THEIR GUARD KEEPS IT"

## The three towers, in order (v0.11 M6).
var towers: Array[Structure] = []
## Each tower's foot: 1.0 out from the middle of its town-side face, walkable (v0.11 M6).
var feet: Array[Vector2] = []
## Each tower's own damage filter before tonight, given back at teardown (v0.11 M6).
var _own_filters: Array[Callable] = []
## Each tower's guards' posts and wrights' posts, planned once (v0.11 M6, _plan_posts()): Arrays of Vector2, one each per tower.
var _guard_posts: Array = []
var _wright_posts: Array = []
## Each mirror's glass (v0.11 M6).
var glass: Array[float] = []
## Each mirror shattered now (v0.11 M6).
var shattered: Array[bool] = []
## Seconds of each shattered mirror's drain left (v0.11 M6).
var drain_left: Array[float] = []
## Seconds of one wright's work toward each shattered mirror's new glass (v0.11 M6).
var hang_work: Array[float] = []
## The night's second of the Heaven Splitter stroke each mirror's glass last took (v0.11 M6; -INF before any).
var _heaven_at: Array[float] = []
## Each mirror's wrights, HuntDirector.Guard records (v0.11 M6, plan decision 280).
var wrights: Array = []
## The light (v0.11 M6).
var searchlight: Searchlight
## The last cast the light heard: the Hunt's quarry, never tagged (v0.11 M6).
var last_cast := Vector2.INF
## How many casts the light saw (v0.11 M6).
var seen_casts := 0
## The Eye opened: the loss (v0.11 M6).
var eye_open := false
## The night's second the three began to stand together, -1 when they do not; which of the Eye's countdowns runs (v0.11 M6).
var _eye_since := -1.0
var _eye_run := 0
## The Temple, for the spire's tag (v0.11 M6).
var temple: Structure
## Everyone the director made a wright, kept off the workshop's hiring (v0.11 M6).
var _hired: Array = []
## The light's drawing (v0.11 M6; never in tests).
var _fx: SearchlightFx


## The plan (v0.11 M6): the Eye's own Gaze; the Hunt's knobs and words; each tower chosen, stone tonight, and its step; the light.
func _plan() -> void:
	gaze = GazeMeter.new()
	has_head = false
	chain = CHAIN
	guard_reach = GUARD_REACH
	return_after = RETURN_AFTER
	relief_after = RELIEF_AFTER
	shield_hits = true
	standard_label = "MIRROR"
	guard_label = "GUARD"
	next_label = "NEXT MIRROR"
	count_word = "mirrors"
	lost_word = "eye_open"
	for s: Structure in town._built:
		if is_instance_valid(s) and s.role == &"temple":
			temple = s
			break
	var taken: Array = []
	for i in TOWER_POINTS.size():
		var tw := _tower_near(TOWER_POINTS[i], taken)
		if tw == null:
			push_warning("LanternEyeDirector: no tower for %s" % TOWER_WORDS[i])
			continue
		taken.append(tw)
		towers.append(tw)
		feet.append(_foot(tw))
		_plan_posts(towers.size() - 1)
		_own_filters.append(tw.damage_filter)
		tw.damage_filter = _stone
		steps.append(_step(String(TOWER_WORDS[i]), feet.back(), Rect2(), float(STEP_AT[i]), PARTY))
		glass.append(MIRROR_HP)
		shattered.append(false)
		drain_left.append(0.0)
		hang_work.append(0.0)
		_heaven_at.append(-INF)
	searchlight = Searchlight.new().setup(SPIRE)
	searchlight.hold = HOLD


## The Hunt's setup, then each tower's wrights indoors, the light lit with both beams and the casts heard (v0.11 M6).
func _begin() -> void:
	super()
	for i in steps.size():
		var crew: Array = []
		for k in WRIGHTS:
			var w := Guard.new()
			w.post = _wright_post(i, k)
			var near := _lay_near(w.post, 1, _in_use())
			if not near.is_empty():
				var p := near[0]
				_make_wright(p)
				w.man = p
				_set_down(p, w.post)
				p.go_duty(w.post)
				_take_inside(p, towers[i])
			crew.append(w)
		wrights.append(crew)
	searchlight.light(Searchlight.SECOND_AFTER)
	_show_light()
	rules.cast_made.connect(_on_cast)


## The standing wall tower nearest `spot` (v0.11 M6, a copy of The Bell-Ringers' _tower_near(), not shared): RuinWish.fits(s, "tower")
## -- never the bell tower -- not a wish's (reserved_places) and none of `exclude`; null for none.
func _tower_near(spot: Vector2, exclude: Array) -> Structure:
	var best: Structure = null
	for s: Structure in town._built:
		if not is_instance_valid(s) or s.destroyed or not RuinWish.fits(s, "tower") or reserved_places.has(s) or exclude.has(s):
			continue
		if best == null or s.center().distance_squared_to(spot) < best.center().distance_squared_to(spot):
			best = s
	return best


## The way out of tower `tw`'s town-side face (v0.11 M6): of its four faces, the one turned most toward the town's middle.
func _face(tw: Structure) -> Vector2:
	var inward := tw.center().direction_to(TownLayout.MAP.get_center())
	var best := Vector2.ZERO
	for dir: Vector2 in [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT]:
		if best == Vector2.ZERO or dir.dot(inward) > best.dot(inward):
			best = dir
	return best


## How far tower `tw`'s middle lies from its face along `dir` (v0.11 M6).
func _depth(tw: Structure, dir: Vector2) -> float:
	var half := tw.footprint.size * 0.5
	return absf(dir.x) * half.x + absf(dir.y) * half.y


## Tower `tw`'s foot (v0.11 M6): POST_OUT beyond the middle of its town-side face, on walkable ground.
func _foot(tw: Structure) -> Vector2:
	var dir := _face(tw)
	return _walkable(tw.center() + dir * (_depth(tw, dir) + POST_OUT))


## The way along tower `i`'s town-side face (v0.11 M6).
func along(i: int) -> Vector2:
	var out := _face(towers[i])
	return Vector2(-out.y, out.x)


## A point just off tower `i`'s outer face, away from the town (v0.11 M6, for the scripted player's Smite): within a Smite's reach of it.
func outer_face(i: int) -> Vector2:
	var out := -_face(towers[i])
	return towers[i].center() + out * (_depth(towers[i], out) + 0.3)


## Tower `i`'s posts, planned once (v0.11 M6): its party's -- the foot, then POST_GAP to either side of it along the face -- and its
## wrights' -- WRIGHT_GAP apart, at the foot, or on a QUIET_SIDE tower WRIGHT_OUT beyond the outer face -- each its own spot or, walled
## in, the nearest free one (_free_spot()).
func _plan_posts(i: int) -> void:
	var guards: Array[Vector2] = []
	for k in PARTY:
		var side := 0.0 if k == 0 else (-1.0 if k % 2 == 1 else 1.0) * POST_GAP * float((k + 1) / 2)
		guards.append(_free_spot(i, feet[i] + along(i) * side, guards, POST_REACH))
	var quiet: bool = i < QUIET_SIDE.size() and QUIET_SIDE[i]
	var face := _face(towers[i])
	var door := towers[i].center() - face * (_depth(towers[i], face) + WRIGHT_OUT) if quiet else feet[i]
	var crew: Array[Vector2] = []
	for k in WRIGHTS:
		crew.append(_free_spot(i, door + along(i) * WRIGHT_GAP * (float(k) - 0.5 * float(WRIGHTS - 1)), crew,
			WRIGHT_OUT + POST_STEP if quiet else POST_REACH))
	_guard_posts.append(guards)
	_wright_posts.append(crew)


## Ground for a post of tower `i` meant for `spot` (v0.11 M6): `spot` itself when it fits (_post_fits()); else the nearest such point
## within POST_SEARCH of it (every POST_STEP); else `spot` made walkable.
func _free_spot(i: int, spot: Vector2, taken: Array[Vector2], reach: float) -> Vector2:
	if _post_fits(i, spot, taken, reach):
		return spot
	var best := Vector2.INF
	var n := roundi(POST_SEARCH / POST_STEP)
	for dy in range(-n, n + 1):
		for dx in range(-n, n + 1):
			var g := spot + Vector2(dx, dy) * POST_STEP
			var nearer := best == Vector2.INF or g.distance_squared_to(spot) < best.distance_squared_to(spot)
			if nearer and g.distance_to(spot) <= POST_SEARCH and _post_fits(i, g, taken, reach):
				best = g
	return best if best != Vector2.INF else _walkable(spot)


## `g` will do for a post of tower `i` (v0.11 M6): walkable, outside the tower and within `reach` of it (POST_REACH at its foot), more
## than POST_SEP from each of `taken`.
func _post_fits(i: int, g: Vector2, taken: Array[Vector2], reach: float) -> bool:
	if crowd._grid != null and not crowd._grid.walkable(g):
		return false
	var gap := towers[i].distance_to(g)
	if gap <= 0.0 or gap > reach:
		return false
	for o in taken:
		if o.distance_to(g) <= POST_SEP:
			return false
	return true


## The `k`th guard's post of tower `i` (v0.11 M6, planned by _plan_posts()).
func _party_post(i: int, k: int) -> Vector2:
	return _guard_posts[i][k]


## The `k`th wright's post of tower `i` (v0.11 M6, planned by _plan_posts()).
func _wright_post(i: int, k: int) -> Vector2:
	return _wright_posts[i][k]


## `p` in the apron and cap, kept from the town's workshop (v0.11 M6, The Crown's Bread's way).
func _make_wright(p: Person) -> void:
	p.profile.role = CitizenProfile.Role.ENGINEER
	_hired.append(p)
	if crowd.engineers != null and not crowd.engineers.not_hired.has(p):
		crowd.engineers.not_hired.append(p)


## Everyone at the night's work (v0.11 M6): the Hunt's, and every wright.
func _in_use() -> Array:
	var out := super()
	for crew: Array in wrights:
		for w: Guard in crew:
			out.append(w.man)
	return out


## Guard `g` of tower `i` stands guard (v0.11 M6, plan decision 277): alive, out of doors, not held by the god, within guard_reach of the
## tower -- before its mirror goes up too.
func _guarding(i: int, g: Guard) -> bool:
	if not _alive(g.man) or i >= towers.size() or not is_instance_valid(towers[i]):
		return false
	var p := g.man as Person
	return not p.inside and not p.mind in BLIND and towers[i].distance_to(p.ground_pos) <= guard_reach


## Step `i`'s standard is its tower (v0.11 M6); null without one (the step then counts broken).
func _raise_standard(i: int) -> Structure:
	return towers[i] if i < towers.size() else null


## Structure.damage_filter for a tower tonight (v0.11 M6): stone, a blow only shakes it.
func _stone(s: Structure, _amount: float, _source: Vector2, _kind: StringName) -> void:
	s.shake(SHAKE)


## An unguarded blow on a tower (v0.11 M6, mission spec §6.2): with its mirror up and whole it strikes the glass -- at most BLOW_MAX, a
## Heaven Splitter's later strokes within HEAVEN_GAP of its first only shaking the tower -- the tower scorched, shaken and heard as any
## struck building, its own health unmoved; at 0 the mirror shatters. Else it only shakes the tower.
func _unguarded_blow(s: Structure, amount: float, _source: Vector2, kind: StringName) -> void:
	var i := _step_of(s)
	if i < 0 or steps[i].broken or shattered[i]:
		s.shake(SHAKE)
		return
	if kind == HEAVEN_KIND:
		if _clock - _heaven_at[i] < HEAVEN_GAP:
			s.shake(SHAKE)
			return
		_heaven_at[i] = _clock
	var blow := minf(amount, BLOW_MAX)
	glass[i] = maxf(glass[i] - blow, 0.0)
	s.mark_hit(blow / s.max_hp, kind)
	if shield_hits:
		s.hit.emit(s, blow, kind)
	if glass[i] <= 0.0:
		_shatter(i)


## The standing mirror whose tower lies within BlightFx.REACH of `at` (v0.11.1), or -1: raised, not gone, not shattered. A shattered one
## has no glass to cloud. Only reads.
func _mirror_near(at: Vector2) -> int:
	var best := -1
	var best_gap := BlightFx.REACH
	for i in steps.size():
		if i >= towers.size() or not is_instance_valid(towers[i]) or not steps[i].raised or steps[i].broken or shattered[i]:
			continue
		var gap := towers[i].distance_to(at)
		if gap <= best_gap:
			best_gap = gap
			best = i
	return best


## A standing mirror's tower point within BlightFx.REACH of `at` (v0.11.1, spec §7.3): the tower's middle; INF for none. Guarded or not --
## Blight lands on a guarded one and does nothing (blight_takes()). Only reads.
func blight_target(at: Vector2) -> Vector2:
	var i := _mirror_near(at)
	return towers[i].center() if i >= 0 else Vector2.INF


## Blight takes a mirror no guard holds (v0.11.1, spec §7.3, Decision 29): a guarded one only shakes. Only reads.
func blight_takes(at: Vector2) -> bool:
	var i := _mirror_near(at)
	return i >= 0 and not guarded(i)


## Blight landed on the mirror at `at` (v0.11.1): an unguarded one's glass clouds and it shatters as after the last blow -- its drain
## starts and its wrights come out (_shatter()); the town's alarm as any Blight (the base). False for a guarded one.
func blighted(at: Vector2) -> bool:
	var i := _mirror_near(at)
	if i < 0 or not super(at):
		return false
	glass[i] = 0.0
	_shatter(i)
	return true


## The banner for a Blight on the mirror at `at` (v0.11.1): "BLIGHT - THE MIRROR CLOUDS" once its glass is gone, else, a guard holding it,
## "THEIR GUARD KEEPS IT". Only reads.
func blight_words(at: Vector2) -> String:
	var j := -1
	for i in steps.size():
		if i < towers.size() and is_instance_valid(towers[i]) and steps[i].raised and not steps[i].broken and towers[i].distance_to(at) <= BlightFx.REACH:
			j = i
	if j < 0:
		return ""
	return BLIGHT_BANNER if shattered[j] or not guarded(j) else BLIGHT_GUARDED


## Mirror `i` shatters (v0.11 M6): its drain starts, and its wrights come out of the tower to their posts on duty.
func _shatter(i: int) -> void:
	if shattered[i] or steps[i].broken:
		return
	shattered[i] = true
	glass[i] = 0.0
	drain_left[i] = DRAIN
	hang_work[i] = 0.0
	rules.banner.emit("THE MIRROR SHATTERS")
	for w: Guard in wrights[i]:
		w.away = 0.0
		if _alive(w.man) and (w.man as Person).inside:
			_bring_out(w.man as Person, w.post)
			_keep_from_flight(w.man as Person, true)  # Crowd._evacuate() runs the indoors too, if he was not on duty
			(w.man as Person).go_duty(w.post)


## Mirror `i` is hung again (v0.11 M6): full glass, standing, its wrights back inside the tower for the next time.
func _rehang(i: int) -> void:
	shattered[i] = false
	glass[i] = MIRROR_HP
	hang_work[i] = 0.0
	drain_left[i] = 0.0
	rules.banner.emit("THE MIRROR IS HUNG AGAIN")
	for w: Guard in wrights[i]:
		if _alive(w.man) and not (w.man as Person).inside:
			(w.man as Person).go_duty(w.post)
			_take_inside(w.man as Person, towers[i])


## Mirror `i` is gone for good (v0.11 M6): its wrights go home (out first if inside), and the Hunt breaks its step -- its party home, the
## next on the chain; the third gone puts the light out.
func _gone(i: int) -> void:
	if steps[i].broken:
		return
	shattered[i] = false
	for w: Guard in wrights[i]:
		if _alive(w.man) and (w.man as Person).inside:
			_bring_out(w.man as Person, w.post)
			_keep_from_flight(w.man as Person, true)
		_release(w)
	_break(i)
	if broken_all():
		searchlight.put_out()


## Wright `w` is at work (v0.11 M6): alive, out of doors, not held by the god, within WRIGHT_REACH of his post.
func _working(w: Guard) -> bool:
	if not _alive(w.man):
		return false
	var p := w.man as Person
	return not p.inside and not p.mind in BLIND and p.ground_pos.distance_to(w.post) <= WRIGHT_REACH


## Some mirror stands raised and whole (v0.11 M6): the light hunts.
func _hunting() -> bool:
	for i in steps.size():
		if steps[i].raised and not steps[i].broken and not shattered[i]:
			return true
	return false


## All three mirrors stand raised and whole together (v0.11 M6): the Eye's countdown runs.
func _all_standing() -> bool:
	if steps.size() < TOWER_POINTS.size():
		return false
	for i in steps.size():
		if not steps[i].raised or steps[i].broken or shattered[i]:
			return false
	return true


## How many mirrors are shattered now (v0.11 M6). Only reads.
func shattered_now() -> int:
	var n := 0
	for i in steps.size():
		n += 1 if shattered[i] and not steps[i].broken else 0
	return n


## Seconds until the Eye opens while the three stand together; EYE_OPENS while they do not (v0.11 M6).
func eye_left() -> float:
	return maxf(EYE_OPENS - (_clock - _eye_since), 0.0) if _eye_since >= 0.0 else EYE_OPENS


## One step (v0.11 M6): the Hunt's (the timeline, the chain, the parties), the Gaze's deaths (a seen one's banner), then every frame the
## mirrors' drains and glass, the Eye's countdown and the light.
func step(delta: float) -> void:
	super(delta)
	var was := gaze.value
	gaze.judge_deaths(crowd)
	if gaze.value > was:
		rules.banner.emit(SEEN_DEATH_BANNER)
	if found or broken_all():
		return
	_step_mirrors(delta)
	_step_eye()
	_step_light(delta)


## Each shattered mirror (v0.11 M6): its wrights at work add to the new glass, REHANG of one wright's work hanging it; else its drain
## runs, and at 0 it is gone for good.
func _step_mirrors(delta: float) -> void:
	for i in steps.size():
		if not shattered[i] or steps[i].broken:
			continue
		var working := 0
		for w: Guard in wrights[i]:
			working += 1 if _working(w) else 0
		hang_work[i] += delta * float(working)
		if hang_work[i] >= REHANG:
			_rehang(i)
			continue
		drain_left[i] -= delta
		if drain_left[i] <= 0.0:
			_gone(i)


## The Eye's countdown (v0.11 M6, plan decision 278): starts when the three stand together, its run shown on the strip; stops when one
## falls; at 0 the Eye opens -- found, its banner once.
func _step_eye() -> void:
	if not _all_standing():
		_eye_since = -1.0
		return
	if _eye_since < 0.0:
		_eye_since = _clock
		_eye_run += 1
		var run := _eye_run
		timeline.add(timeline.elapsed() + EYE_OPENS / timeline.stretch_factor(), "eye_%d" % run, "The Eye opens", Callable(),
			func() -> bool: return _eye_run == run and _eye_since >= 0.0 and eye_left() > EYE_EPS)
	if eye_left() <= EYE_EPS and not found:
		eye_open = true
		found = true
		rules.banner.emit(_found_banner())


## The light (v0.11 M6): hunting while a mirror stands, its noise forgotten when it goes quiet; swept on.
func _step_light(delta: float) -> void:
	if not searchlight.on:
		return
	var now := _hunting()
	if now != searchlight.hunt:
		searchlight.hunt = now
		if not now:
			searchlight.noise = Vector2.INF
	searchlight.step(delta, rules.time_left)


## A cast (Rules.cast_made, v0.11 M6): aimed in a lit pool it is seen -- SEEN_CAST on the Gaze, heard or not; a Wisp is a decoy; while a
## mirror stands, a heard cast is the light's noise.
func _on_cast(_slot: int, key: String, at: Vector2) -> void:
	if not searchlight.on:
		return
	if searchlight.touches(at):
		seen_casts += 1
		gaze.add(SEEN_CAST)
		rules.banner.emit(SEEN_CAST_BANNER)
	if key in UNHEARD or not _hunting():
		if key == "wisp":
			searchlight.lure(at)
		return
	last_cast = at
	searchlight.hear(at)
	if key == "wisp":
		searchlight.lure(at)


## A death (v0.11 M6): the Hunt's, and noted for the Gaze (seen or not, Crowd.nearest_witness() decides).
func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	super(e, kind)
	gaze.note_death(e.ground_pos)


## Every held person kept from the town's flight by the one rule (v0.11 M6): the Hunt's, and the wrights of every mirror not gone; then
## the wrights at their posts by their own rule.
func _keep_held(evacuating: bool) -> void:
	super(evacuating)
	var people: Array = []
	for i in wrights.size():
		if steps[i].broken:
			continue
		for w: Guard in wrights[i]:
			people.append(w.man)
	_hold_all(people, evacuating)
	_keep_wrights(evacuating)


## A shattered mirror's wrights at their work (v0.11 M6): one at work is kept on duty there; one off his post but alive walks back
## RETURN_AFTER after he left (his away clock moves a TICK a look), or at once at the first look after the evacuation began.
func _keep_wrights(evacuating: bool) -> void:
	for i in wrights.size():
		if not shattered[i] or steps[i].broken:
			continue
		for w: Guard in wrights[i]:
			if not _alive(w.man) or (w.man as Person).inside:
				continue
			if _working(w):
				w.away = 0.0
				if (w.man as Person).mind != Person.Mind.DUTY:
					_recall_to(w.man, w.post, evacuating)
				continue
			w.away += TICK
			if w.away >= RETURN_AFTER or evacuating:
				_recall_to(w.man, w.post, evacuating)


## The light drawn, when the director has the battlefield's effects (v0.11 M6; never in tests).
func _show_light() -> void:
	if ctx != null and ctx.overhead != null and not is_instance_valid(_fx):
		_fx = FxTimeline.cast(SearchlightFx, ctx, searchlight.spire, {"light": searchlight}) as SearchlightFx


## The Eye's quarry: the god's last heard cast (v0.11 M6); never tagged.
func _quarry_point() -> Vector2:
	return last_cast


## The hunt has found its quarry: the Eye opened (v0.11 M6).
func _found() -> bool:
	return eye_open


## The opening banner (v0.11 M6).
func _opening_banner() -> String:
	return "THE LANTERN'S EYE"


## The strip's and the banner's words when mirror `i` goes up (v0.11 M6).
func _step_label(i: int) -> String:
	return "A mirror goes up on %s" % steps[i].words


## The banner when a mirror is gone for good (v0.11 M6).
func _broken_banner(_i: int) -> String:
	return "THE MIRROR IS GONE"


## The banner when the Eye opens (v0.11 M6).
func _found_banner() -> String:
	return "THE EYE OPENS"


## The map tags, most important first (v0.11 M6, mission spec §1): the Eye's countdown on the spire while it runs; the current mirror,
## gold and pointed at ("- GUARDED", or "- SHATTERED n" orange); each other standing mirror, gold; the next mirror's tower with its
## sooner time, grey, pointed at; GUARD on each guard on guard, a red diamond on a relief walking in, a small red mark on one away;
## WRIGHT on each wright out of doors. The beams are drawn, not tagged.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if found or broken_all():
		return out
	if _eye_since >= 0.0:
		out.append(MapTag.place(SPIRE, MARK_WATCHED, "THE EYE OPENS IN %d" % ceili(eye_left()), temple.height if temple != null else 0.0, true))
	var cur := current()
	for i in steps.size():
		if not steps[i].raised or steps[i].broken:
			continue
		var tw := towers[i]
		if shattered[i]:
			out.append(MapTag.place(tw.center(), MARK_PLACE, "MIRROR - SHATTERED %d" % ceili(maxf(drain_left[i], 0.0)), tw.height, i == cur))
		else:
			out.append(MapTag.place(tw.center(), MARK_TARGET, "MIRROR - GUARDED" if i == cur and guarded(i) else "MIRROR", tw.height, i == cur))
	var n := next_step()
	if n >= 0:
		out.append(MapTag.place(towers[n].center(), MARK_NOT_YET, "%s %s" % [next_label, UiTheme.clock(due_in(n))], towers[n].height, true))
	for i in steps.size():
		if steps[i].broken:
			continue
		for g: Guard in steps[i].party:
			if not _alive(g.man) or (g.man as Person).inside:
				continue
			var p := g.man as Person
			if _guarding(i, g):
				out.append(MapTag.person(p.ground_pos, MARK_WATCHED, guard_label))
			elif g.relief:
				out.append(MapTag.person(p.ground_pos, MARK_WATCHED))
			else:
				out.append(MapTag.pip(p.ground_pos, MARK_WATCHED))
		for w: Guard in wrights[i]:
			if _alive(w.man) and not (w.man as Person).inside:
				out.append(MapTag.person((w.man as Person).ground_pos, MARK_WATCHED, "WRIGHT"))
	return out


## The hint's phase (v0.11 M6, plan decision 303): "eye" while the countdown runs; "shattered" while a mirror drains; "guarded" or
## "open" for the current mirror; "waiting" once one is gone and the next is still to go up; else "".
func hint_phase() -> String:
	if found or broken_all():
		return ""
	if _eye_since >= 0.0:
		return "eye"
	if shattered_now() > 0:
		return "shattered"
	var cur := current()
	if cur >= 0:
		return "guarded" if guarded(cur) else "open"
	if broken_count() > 0 and next_step() >= 0:
		return "waiting"
	return ""


## The seconds the hint counts down (v0.11 M6): the Eye's in "eye", the first draining mirror's in "shattered"; else 0.
func hint_seconds() -> float:
	match hint_phase():
		"eye":
			return eye_left()
		"shattered":
			for i in steps.size():
				if shattered[i] and not steps[i].broken:
					return maxf(drain_left[i], 0.0)
	return 0.0


## The tour (v0.11 M6, mission spec §1): the north tower, the spire, the east tower.
func tour() -> Array:
	var out := []
	if not towers.is_empty():
		out.append([towers[0].center(), "The north tower. A mirror goes up here at %s: shatter it and keep it shattered %d s." % [
			UiTheme.clock(float(STEP_AT[0])), roundi(DRAIN)]])
	out.append([SPIRE, "Halcyon's Searchlight. While a mirror stands, its beams hunt your casts. A cast in the light is seen."])
	if towers.size() > 1:
		out.append([towers[1].center(), "The east and south-west towers: the next mirrors. If all three stand at once, the Eye opens."])
	return out


## What the results show (v0.11 M6): the Hunt's, the casts the light saw and the Gaze.
func report() -> Dictionary:
	var out := super()
	out["seen_casts"] = seen_casts
	out["gaze"] = gaze.value
	return out


## Lets go of the casts, the light and its drawing, then the Hunt's (which puts the stone filter back), then each tower's own filter and
## the workshop's list (v0.11 M6). Safe to call twice.
func teardown() -> void:
	if is_instance_valid(rules) and rules.cast_made.is_connected(_on_cast):
		rules.cast_made.disconnect(_on_cast)
	if searchlight != null:
		searchlight.put_out()
	if is_instance_valid(_fx):
		_fx.end_now()
	_fx = null
	if ctx != null and ctx.impact != null:
		ctx.impact.dim(0.0, 4.0)
	super()
	for i in towers.size():
		if is_instance_valid(towers[i]):
			towers[i].damage_filter = _own_filters[i]
	if is_instance_valid(crowd) and crowd.engineers != null:
		for v: Variant in _hired:
			crowd.engineers.not_hired.erase(v)
