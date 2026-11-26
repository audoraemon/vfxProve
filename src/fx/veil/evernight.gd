class_name EvernightFx
extends FxTimeline
## Evernight (Veil, Tier 5; spec 5.10): a doomsday. Night runs out from the click over WAVE seconds (a dark front at map-width / WAVE)
## and every lamp dies; it holds for 60 s (90 s cast in a NIGHT mission), then dawn returns over DAWN seconds. Four parts:
## 1. The night is the god's: everywhere is dark (Dusk.everywhere: every Veil power is full size anywhere), people see 0.6 as far (once,
##    never 0.36), the whole town is under Unseen Hour's rule (Crowd.veil_all()) and the Veil's cooldown clocks run twice as fast
##    (Rules.haste; never a once-a-descent power's).
## 2. The dark takes the lone (Veil review 2): every 2 s (1.5 in a NIGHT mission) a group is taken, TAKE_FIRST at the first take rising
##    evenly to TAKE_LAST at the last (take_count()). Each group is claimed one take ahead (at the fall, then after every take but the
##    last): the loneliest_n() living out of doors, outside every torch's light, not spared (Crowd.spared()), takeable and not already
##    claimed (whose nearest neighbour is farthest away first; a tie: the lower instance id). At the take each claimed one who still
##    qualifies is taken (`&"night"`); one who does not is let go (he may be claimed again). Nobody claimed is held or told. The look:
##    the dark eats the claimed where they stand and each taken leaves his shadow on the ground (EvernightMarks).
## 3. Islands of light: when the night falls up to TORCHES soldiers light torches where they stand (bearers(): the most citizens within
##    TORCH_COUNT_R first); each lights TORCH_R, and the calm citizens within TORCH_CALL walk to the nearest and huddle. Whoever stands in
##    a torch's light is safe from part 2. Dusk laid over a torch (any Veil cast) puts it out and takes everyone in its light; a bearer
##    who dies or is taken drops his torch the same way.
## 4. No dawn for some: at dawn whoever shelters in a blighted building (Crowd.footholds) or sleeps inside a dusk patch (a shadow's
##    owner counts as asleep) never wakes; a shelterer is let out of his shelter first (VeilParts.take_out()).
## The town forgets the night: every take is silent (no alarm, no search, no count). The town's art look is not switched (spec 11.2):
## the night is the light field's ambient and tint eased to the NIGHT values, the static lamps muted (LightField.mute()) and a starred
## wash with a pale moon over the ground, all eased back at dawn. Everything it switches on is undone in _finish() AND _exit_tree(); the town-wide parts
## are kept in a ledger of owners on the crowd and on the light field (instance ids, no statics), so two casts never undo each other.
## Evernight lays no dusk patch of its own: the whole town is its dark (ruling VC7).

## The night runs out from the click for this long; dawn returns over DAWN.
const WAVE := 3.0
const DAWN := 3.0
## At most this many torches; each lights TORCH_R; a bearer is picked by the citizens within TORCH_COUNT_R; citizens within TORCH_CALL
## of a torch walk to it.
const TORCHES := 6
const TORCH_R := 2.5
const TORCH_COUNT_R := 6.0
const TORCH_CALL := 10.0
## A take collects this many at the first take, rising evenly to this many at the last (rounded; one take alone: TAKE_FIRST).
const TAKE_FIRST := 5
const TAKE_LAST := 10
## The puffs of each taken one's wisp (11 when one was taken at a time; up to 10 wisps a take now).
const WISP_PUFFS := 7
## The kill kind of every take (Crowd.SILENT_KINDS).
const KIND := &"night"
## The Veil's cooldown clocks run this many times as fast while the night lasts.
const HASTE := 2.0
## The ledgers' meta keys: the night's (on the crowd) and the look's (on the light field).
const NIGHT_KEY := &"evernight_night"
const LOOK_KEY := &"evernight_look"
## A torch's light.
const TORCH_COLOR := Color(1.0, 0.72, 0.40)
const TORCH_GLOW := 1.3
## Huddle slots round a torch reach at most this far from it.
const HUDDLE := 1.8
## The cells of loneliest()'s neighbour search.
const CELL := 4.0
## With no city map and no field bounds, the night's ground is a square this far round the click on each side.
const BARE_HALF := 30.0
## Level 5 (VS 7, "The False Light"): the torches' light is a false, cold blue (FALSE_COLOR in the light field, the glow and the warm island).
## Nothing happens to anyone in it all night; in the last FLARE_EYE seconds before the dawn every huddler and bearer is eyed (open-ended,
## refreshed for newcomers), and at the dawn each burning torch flares black and takes its huddle_of() (no body, ids in `flared`) before the
## dawn's own takes. Only _dawn() flares: a cast cut short (_end_night()) never does. The light's radius is TORCH_R throughout (torch_r()).
const FALSE_COLOR := Color(0.55, 0.75, 1.0)
const FLARE_EYE := 5.0
const FLARE_BURST := 14
const TWIST_KEY := "evernight"
## The look's front runs out as (t / WAVE) to this power: slow by the click, fast across the town (VRD1).
const FRONT_EASE := 1.7

## This cast's night: 60 s, or 90 in a NIGHT mission; a take every take_every s; dawn begins at t_dawn.
var night_time := 60.0
var take_every := 2.0
## This cast's last take's size and its torch count, at its level (TAKE_LAST and TORCHES at level 1).
var lv_take_last := TAKE_LAST
var lv_torches := TORCHES
var t_dawn := WAVE + 60.0
## The level-5 twist (PowerBook.twist_at, once in _build()) and the radius the shade was last given.
var _twist := false
var _island := TORCH_COLOR
var _eye_next := 0.0
## The torches: {"at", "bearer" (instance id), "light" (LightField id, 0 = none), "out", "n" (huddle slots handed out)}.
var torches: Array[Dictionary] = []
## The instance ids this cast took, in order.
var taken: Array[int] = []
## Level 5: the ids the dawn's flare took (also in `taken`).
var flared: Array[int] = []
## The instance ids claimed for the next take, in the order claimed.
var claimed: Array[int] = []
## The takes scheduled this night (K in take_count()).
var takes := 0
## The shadows the takes left (one node on the ground layer, made at the first), and the claims' looks (instance id -> Claim).
var stains: EvernightMarks.Stains
var _claim_looks := {}
## The look on the ground: the wash, its stars, the wave front, the torches' rings.
var wash: NightWash
## The crowd's town-wide veil this cast laid (Crowd.veil_all()), 0 when none.
var _veil := 0
## Whether this cast is an owner of the night's ledger / the look's ledger.
var _night_on := false
var _look_on := false
## Whether the night has ended (dawn came or the cast was cut short): no more takes, torches or calls.
var _over := false
## The citizens called to a torch: instance id -> torch index.
var _called := {}
## The crowd and light field this cast joined (kept: ctx may be torn down first).
var _crowd: Crowd
var _lights: LightField
## The held night's sound (v_evernight_loop), from the fall to the end of the night; faded out at dawn.
var _hush: Node
## The look over the town (EvernightSky; spec 7): the night multiplied over the view, the air (mist, stars, motes), the wall of
## the front, a glow per torch (by torch index). Each is missing where its layer is (a bare context has none of them).
var _shade: EvernightSky.View
var _air: EvernightSky.View
var _wall: EvernightSky.Wall
var _glows: Array = []


## Up to TORCHES living soldiers out of doors who light torches: those with the most living citizens out of doors within
## TORCH_COUNT_R first, a tie by the lower instance id (no luck). One a mission holds (Crowd.held_by_mission(): a seizer with his
## charge) is never posted with a torch.
static func bearers(crowd: Crowd, most := TORCHES) -> Array[Person]:
	var out: Array[Person] = []
	if crowd == null:
		return out
	var rows: Array = []
	for s in crowd.soldiers:
		if not is_instance_valid(s) or not s.is_alive() or s.inside or crowd.held_by_mission(s):
			continue
		var n := 0
		for c in crowd.citizens:
			if is_instance_valid(c) and c.is_alive() and not c.inside and c.ground_pos.distance_to(s.ground_pos) <= TORCH_COUNT_R:
				n += 1
		rows.append([n, s.get_instance_id(), s])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0] if a[0] != b[0] else a[1] < b[1])
	for r in rows.slice(0, most):
		out.append(r[2])
	return out


## The one the dark takes next: loneliest_n()'s first (null when there is no one).
static func loneliest(crowd: Crowd, lit: Array, light_r := TORCH_R) -> Person:
	var one := loneliest_n(crowd, lit, 1, {}, light_r)
	return one[0] if not one.is_empty() else null


## The `n` the dark claims next: of the living out of doors, outside every light in `lit` (torch centres, TORCH_R), not spared and not in
## `skip` (instance ids), those whose nearest living neighbour out of doors is farthest away first (none at all: the farthest); a tie
## goes to the lower instance id. One take() cannot take (takeable()) is passed over. Everyone living out of doors still counts as a
## neighbour (the claimed, the lit, the spared). One pass that measures every candidate and sorts (it runs once a take).
static func loneliest_n(crowd: Crowd, lit: Array, n: int, skip: Dictionary, light_r := TORCH_R) -> Array[Person]:
	var picked: Array[Person] = []
	if crowd == null or n <= 0:
		return picked
	var out: Array[Person] = []
	var lo := Vector2(INF, INF)
	var hi := -lo
	for p in crowd.citizens + crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and not p.inside:
			out.append(p)
			lo = lo.min(p.ground_pos)
			hi = hi.max(p.ground_pos)
	if out.is_empty():
		return picked
	var cells := {}
	for p in out:
		var key := Vector2i(floori(p.ground_pos.x / CELL), floori(p.ground_pos.y / CELL))
		if not cells.has(key):
			cells[key] = []
		(cells[key] as Array).append(p)
	var rings := int(ceil(maxf(hi.x - lo.x, hi.y - lo.y) / CELL)) + 1
	var rows: Array = []
	for p in out:
		if skip.has(p.get_instance_id()) or _in_light(p.ground_pos, lit, light_r) or crowd.spared(p) or not takeable(p):
			continue
		rows.append([_nearest(p, cells, rings, -1.0), p.get_instance_id(), p])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0] if a[0] != b[0] else a[1] < b[1])
	for r: Array in rows.slice(0, n):
		picked.append(r[2])
	return picked


## The distance from `p` to his nearest neighbour in `cells`, searched ring by ring outward; -1 as soon as one is found nearer than
## `floor_d` (he cannot be the loneliest); INF when he has none.
static func _nearest(p: Person, cells: Dictionary, rings: int, floor_d: float) -> float:
	var c := Vector2i(floori(p.ground_pos.x / CELL), floori(p.ground_pos.y / CELL))
	var nd := INF
	for r in rings + 1:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var list: Array = cells.get(c + Vector2i(dx, dy), [])
				for q: Person in list:
					if q != p:
						nd = minf(nd, p.ground_pos.distance_to(q.ground_pos))
		if nd < floor_d:
			return -1.0
		if nd <= float(r) * CELL:
			return nd
	return nd


## Whether Crowd.take() can take `p`: no Deathless hook on him (Corpse Guise, level 5: Person.deathless, which die() asks before a
## death and which spares him). The hook itself is not called -- asking it spends the guise -- so one with a hook is passed over.
static func takeable(p: Person) -> bool:
	return not p.deathless.is_valid()


static func _in_light(at: Vector2, lit: Array, r := TORCH_R) -> bool:
	for c: Vector2 in lit:
		if c.distance_to(at) <= r:
			return true
	return false


func _build() -> void:
	_twist = PowerBook.twist_at(extra, TWIST_KEY)
	_crowd = ctx.crowd if ctx != null and ctx.crowd != null and is_instance_valid(ctx.crowd) else null
	_lights = ctx.lights if ctx != null and ctx.lights != null and is_instance_valid(ctx.lights) else null
	var night := _crowd != null and _crowd.night_mission
	lv_take_last = PowerBook.stat(extra, "evernight", "TAKE_LAST", TAKE_LAST)
	lv_torches = PowerBook.stat(extra, "evernight", "TORCHES", TORCHES)
	night_time = VeilRules.size("evernight", "NIGHT_TIME", night, VeilParts.level(self))
	take_every = VeilRules.size("evernight", "TAKE_EVERY", night, VeilParts.level(self))
	t_dawn = WAVE + night_time
	duration = t_dawn + DAWN
	busy = WAVE
	_join_look()
	if ctx != null:
		ctx.play(&"v_evernight", origin)
	at(WAVE, _fall)
	takes = 0
	while float(takes + 1) * take_every < night_time - 0.001:
		takes += 1
		if _crowd != null:
			at(WAVE + float(takes) * take_every, _take.bind(takes))
	at(t_dawn, _dawn)
	var parent: Node2D = ctx.ground if ctx != null and ctx.ground != null else null
	if parent != null:
		wash = NightWash.new()
		wash.fx_id = get_instance_id()
		wash.center = origin
		wash.map = _map()
		wash.place_moon()
		track(wash, parent)
	_build_sky()


## The look over the town (ctx.overhead_back, but at absolute z: EvernightSky.Z_SHADE / Z_AIR, over the world and under the aim, VRF1):
## the shade, the air over it and the wall over both. The town's own NIGHT look is darkened once already, so the shade is lighter there.
## Every cast builds its own; only the sky's owner shows them (_sky_owner(), VRF2).
func _build_sky() -> void:
	if ctx == null or ctx.overhead_back == null:
		return
	assert(TORCHES <= EvernightSky.SHADE_TORCHES, "evernight_shade.gdshader's torches[] is too small for TORCHES")
	var on_night: bool = TownLook.active == Town.Look.NIGHT
	_shade = EvernightSky.View.new(EvernightSky.SH_SHADE)
	_shade.z_as_relative = false
	_shade.z_index = EvernightSky.Z_SHADE
	_shade.set_param(&"night", EvernightSky.NIGHT_ON_NIGHT if on_night else EvernightSky.NIGHT)
	_shade.set_param(&"edge_night", EvernightSky.NIGHT_ON_NIGHT_EDGE if on_night else EvernightSky.NIGHT_EDGE)
	_shade.set_param(&"torch_r", TORCH_R)
	_shade.set_param(&"moon_uv", EvernightSky.MOON_UV)
	_shade.set_param(&"moon_light", EvernightSky.MOON_LIGHT)
	_shade.set_param(&"center", origin)
	track(_shade, ctx.overhead_back)
	_air = EvernightSky.View.new(EvernightSky.SH_AIR)
	_air.z_as_relative = false
	_air.z_index = EvernightSky.Z_AIR
	_air.set_param(&"center", origin)
	_air.set_param(&"silver", VeilParts.SILVER)
	_air.set_param(&"veil", VeilParts.VEIL)
	_air.set_param(&"black", VeilParts.BLACK)
	track(_air, ctx.overhead_back)
	_wall = EvernightSky.Wall.new()
	_wall.z_as_relative = false
	_wall.z_index = EvernightSky.Z_AIR  # after the air in the tree: over it
	_wall.center = origin
	_wall.mat.set_shader_parameter(&"black", VeilParts.BLACK)
	_wall.mat.set_shader_parameter(&"dusk", VeilParts.DUSK)
	_wall.mat.set_shader_parameter(&"veil", VeilParts.VEIL)
	_wall.mat.set_shader_parameter(&"silver", VeilParts.SILVER)
	track(_wall, ctx.overhead_back)


## The ground the night covers: the active city's map; with none (a CityDef with no map), the field's bounds, as Eminent Domain and
## Tempest read them; with no field either (a bare context), a square of BARE_HALF round the click.
func _map() -> Rect2:
	var m := City.current().map()
	if m.size != Vector2.ZERO:
		return m
	if ctx != null and ctx.field != null and ctx.field.bounds.size != Vector2.ZERO:
		return ctx.field.bounds
	return Rect2(origin - Vector2(BARE_HALF, BARE_HALF), Vector2(BARE_HALF, BARE_HALF) * 2.0)


## The night falls everywhere: the dark, the sight, the veil, the haste; the torches are lit and the calm walk to them.
func _fall() -> void:
	if not _live() or _over:
		return
	_join_night()
	if ctx != null:
		_hush = ctx.play(&"v_evernight_loop", origin)
	_veil = _crowd.veil_all(night_time + DAWN)
	for b in bearers(_crowd, lv_torches):
		var light := _lights.add_static(b.ground_pos, TORCH_R, torch_color(), TORCH_GLOW, 0.35) if _live_lights() else 0
		torches.append({"at": b.ground_pos, "bearer": b.get_instance_id(), "light": light, "out": false, "n": 0})
		b.send_to_post(b.ground_pos)  # he stands where he is, holding it up
		_glow_for(b.ground_pos)
	_call_to_torches()
	if _crowd.dusk != null and not _crowd.dusk.laid.is_connected(_on_laid):
		_crowd.dusk.laid.connect(_on_laid)
	if takes >= 1:
		_claim(1)


## How many take `k` (1..takes) collects: TAKE_FIRST at the first rising evenly to the level's TAKE_LAST at the last, rounded.
func take_count(k: int) -> int:
	if takes <= 1:
		return TAKE_FIRST
	var f := float(clampi(k, 1, takes) - 1) / float(takes - 1)
	return roundi(lerpf(float(TAKE_FIRST), float(lv_take_last), f))


## The centres of the torches still burning.
func lit() -> Array:
	var out: Array = []
	for tc in torches:
		if not tc.out:
			out.append(tc.at)
	return out


## The light's radius: TORCH_R always (level 5's torches are false, not smaller).
func torch_r() -> float:
	return TORCH_R


## The torches' colour: warm at levels 1-4, FALSE_COLOR at level 5.
func torch_color() -> Color:
	return FALSE_COLOR if _twist else TORCH_COLOR


## Level 5: the living, out of doors, not spared within TORCH_R of torch `tc`, plus its bearer (when living, out of doors, not spared).
func huddle_of(tc: Dictionary) -> Array[Person]:
	var out: Array[Person] = []
	if not _live():
		return out
	var seen := {}
	var b := instance_from_id(int(tc.bearer)) as Person
	if b != null and b.is_alive() and not b.inside and not _crowd.spared(b):
		out.append(b)
		seen[b.get_instance_id()] = true
	for p in _crowd.citizens + _crowd.soldiers:
		if not is_instance_valid(p) or not p.is_alive() or p.inside or seen.has(p.get_instance_id()) or _crowd.spared(p):
			continue
		if (tc.at as Vector2).distance_to(p.ground_pos) <= TORCH_R:
			out.append(p)
			seen[p.get_instance_id()] = true
	out.sort_custom(func(x: Person, y: Person) -> bool: return x.get_instance_id() < y.get_instance_id())
	return out


## Level 5, the last FLARE_EYE seconds: every huddler and bearer of a burning torch is eyed (open-ended; released in _end_night()).
func _eye_huddles() -> void:
	if not _twist or _over or not _live() or t < t_dawn - FLARE_EYE or t >= t_dawn or t < _eye_next:
		return
	_eye_next = t + 0.25
	for tc in torches:
		if not tc.out:
			for p in huddle_of(tc):
				PaleEye.mark(self, p, TWIST_KEY, INF)


## Level 5, at the dawn: each burning torch flares black and takes its huddle (no body); the torch goes out.
func _flare() -> void:
	for tc in torches:
		if tc.out:
			continue
		var group := huddle_of(tc)
		tc.out = true
		_drop_light(tc)
		_flare_look(tc.at)
		for p in group:
			var where := p.ground_pos
			if VeilParts.take_out(_crowd, p, KIND):
				taken.append(p.get_instance_id())
				flared.append(p.get_instance_id())
				_wisp(where, taken.size())


## The black flare at a torch (the look only).
func _flare_look(at_g: Vector2) -> void:
	if ctx != null and ctx.overhead != null:
		EvernightSky.flare(self, ctx.overhead, Iso.ground_to_screen(at_g) + Vector2(0, -EvernightSky.HELD), 7717 + 29 * flared.size(), FLARE_BURST)


## The dark claims the group for take `k`: the take_count(k) loneliest not already claimed. Nothing is done to them; the look marks them.
func _claim(k: int) -> void:
	var skip := {}
	for id in claimed:
		skip[id] = true
	var wait := WAVE + float(k) * take_every - t
	for p in loneliest_n(_crowd, lit(), take_count(k) - claimed.size(), skip, torch_r()):
		claimed.append(p.get_instance_id())
		_claim_look(p, wait)


## Take `k`: every one claimed for it who is still alive, out of doors, outside every burning torch's light, not spared and takeable
## is taken, in the order claimed; the rest are let go. Then the next group is claimed (not after the last take).
func _take(k: int) -> void:
	if not _live() or _over:
		return
	_watch_bearers()
	var light := lit()
	var reach := torch_r()
	var group := claimed.duplicate()
	claimed.clear()
	for id: int in group:
		var p := instance_from_id(id) as Person
		var ok := p != null and p.is_alive() and not p.inside and not _in_light(p.ground_pos, light, reach) and not _crowd.spared(p) \
			and takeable(p)
		var where := p.ground_pos if p != null else Vector2.ZERO
		if ok and _crowd.take(p, KIND):
			taken.append(id)
			_wisp(where, taken.size())
			_stain(where, id)
			_drop_claim_look(id, true)
		else:
			_drop_claim_look(id, false)
	if k < takes:
		_claim(k + 1)
	_call_to_torches()


## The dark eating one claimed (the look; over the night's shade, under the aim). Only where a screen layer is (none headless).
func _claim_look(p: Person, wait: float) -> void:
	if ctx == null or ctx.overhead_back == null or not is_instance_valid(ctx.overhead_back):
		return
	var c := EvernightMarks.Claim.new(p, wait)
	_claim_looks[p.get_instance_id()] = track(c, ctx.overhead_back)


## His claim's look ends: taken, it goes with him; let go, it falls away.
func _drop_claim_look(id: int, was_taken: bool) -> void:
	var c: Variant = _claim_looks.get(id)
	_claim_looks.erase(id)
	if c == null or not is_instance_valid(c):
		return
	if was_taken:
		(c as Node).queue_free()
	else:
		(c as EvernightMarks.Claim).let_go()


## His shadow where he was taken (the look; on the ground layer, all of them one node).
func _stain(at_g: Vector2, id: int) -> void:
	if ctx == null or ctx.ground == null or not is_instance_valid(ctx.ground):
		return
	if stains == null or not is_instance_valid(stains):
		stains = EvernightMarks.Stains.new()
		stains.fx_id = get_instance_id()
		track(stains, ctx.ground)
	stains.add(at_g, id)


## A torch's glow (the look): over the town, where the torch is held up. Index-matched to `torches`.
func _glow_for(at_g: Vector2) -> void:
	if ctx == null or ctx.overhead == null:
		_glows.append(null)
		return
	var g := EvernightSky.TorchGlow.new(4217 + 31 * _glows.size())
	g.position = Iso.ground_to_screen(at_g) + Vector2(0, -EvernightSky.HELD)
	_glows.append(track(g, ctx.overhead))


## A brief dark wisp rising where one was taken (the look; one small burst a person, WISP_PUFFS: takes come in groups now).
func _wisp(at_g: Vector2, n: int) -> void:
	if ctx != null and ctx.overhead != null:
		EvernightSky.wisp(self, ctx.overhead, Iso.ground_to_screen(at_g), 9011 + 13 * n, WISP_PUFFS)


## The calm citizens out of doors within TORCH_CALL of a burning torch walk to the nearest and huddle in its light (once each, again if
## their torch goes out). One a mission holds (Crowd.held_by_mission()) is left to his mission.
func _call_to_torches() -> void:
	var burning: Array[int] = []
	for i in torches.size():
		if not torches[i].out:
			burning.append(i)
	if burning.is_empty():
		return
	var ps: Array[Person] = []
	for c in _crowd.citizens:
		if not is_instance_valid(c) or not c.is_alive() or c.inside or c.is_asleep() or c.mind != Person.Mind.CALM or c.home_sick 				or _crowd.held_by_mission(c):
			continue
		var called: int = int(_called.get(c.get_instance_id(), -1))
		if called >= 0 and not torches[called].out:
			continue
		ps.append(c)
	# Nearest first (a tie by instance id), so the slots nearest the light go to those already near it.
	var near := func(p: Person) -> Array:
		var bi := -1
		var bd := INF
		for i in burning:
			var d: float = (torches[i].at as Vector2).distance_to(p.ground_pos)
			if d < bd:
				bd = d
				bi = i
		return [bi, bd]
	var rows: Array = []
	for p in ps:
		var n: Array = near.call(p)
		if float(n[1]) <= TORCH_CALL:
			rows.append([float(n[1]), p.get_instance_id(), p, int(n[0])])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0] if a[0] != b[0] else a[1] < b[1])
	for r: Array in rows:
		var p: Person = r[2]
		var i: int = r[3]
		var tc := torches[i]
		var k := int(tc.n)
		tc.n = k + 1
		var slot: Vector2 = tc.at + Vector2.from_angle(float(k) * 2.39996) * minf(0.6 + 0.3 * sqrt(float(k)), HUDDLE)
		if p.grid != null:
			var w := p.grid.nearest_walkable(slot)
			slot = w if w != Vector2.INF and w.distance_to(tc.at) <= TORCH_R - 0.3 else tc.at
		p.walk_to(slot)
		_called[p.get_instance_id()] = i


## A bearer dead or taken drops his torch: it goes out.
func _watch_bearers() -> void:
	for i in torches.size():
		if torches[i].out:
			continue
		var b := instance_from_id(int(torches[i].bearer)) as Person
		if b == null or not b.is_alive():
			put_out(i)


## Dusk laid over a burning torch (a Veil cast) puts it out.
func _on_laid(at_g: Vector2, r: float) -> void:
	if _over or not _live():
		return
	for i in torches.size():
		if not torches[i].out and (torches[i].at as Vector2).distance_to(at_g) <= r + TORCH_R:
			put_out(i)


## Torch `i` goes out: its light is gone and everyone who stood in it (not the spared) is taken at once.
func put_out(i: int) -> void:
	var tc := torches[i]
	if tc.out:
		return
	tc.out = true
	_drop_light(tc)
	if not _live():
		return
	var in_light: Array[Person] = []
	for e in ctx.field.in_radius(tc.at, torch_r()) if ctx.field != null else []:
		var p := e as Person
		if p != null and p.is_alive() and not p.inside and not _crowd.spared(p):
			in_light.append(p)
	in_light.sort_custom(func(a: Person, b: Person) -> bool: return a.get_instance_id() < b.get_instance_id())
	for p in in_light:
		var where := p.ground_pos
		if _crowd.take(p, KIND):
			taken.append(p.get_instance_id())
			_wisp(where, taken.size())
			_stain(where, p.get_instance_id())


func _drop_light(tc: Dictionary) -> void:
	if int(tc.light) != 0 and _live_lights():
		_lights.remove(int(tc.light))
	tc.light = 0


## Dawn: who shelters in a blighted building or sleeps inside a dusk patch never wakes (a shadow's owner counts as asleep, spec 5.8;
## one indoors is passed over); then the night ends.
func _dawn() -> void:
	if _live() and not _over:
		if _twist:
			_flare()
		var gone: Array[Person] = []
		for p in _crowd.citizens + _crowd.soldiers:
			if not is_instance_valid(p) or not p.is_alive() or _crowd.spared(p):
				continue
			var blighted := p.inside and p.shelter != null and is_instance_valid(p.shelter) and _crowd.footholds.has(p.shelter)
			var dreaming := not p.inside and (p.is_asleep() or p.is_shadow()) and _crowd.dusk != null and _crowd.dusk.covers(p.ground_pos)
			if blighted or dreaming:
				gone.append(p)
		for p in gone:
			# Let out of his shelter first (the release The Swallowing Dark uses): a shelter's next flush must not raise a body.
			var where := p.ground_pos
			if VeilParts.take_out(_crowd, p, KIND):
				taken.append(p.get_instance_id())
				_wisp(where, taken.size())
	_end_night()


## The night ends (dawn, or the cast cut short): no more takes; the torches are put away (nobody taken), the bearers go back to their
## posts, the veil lifts and this cast leaves the night's ledger. Safe to call twice and with the crowd freed.
func _end_night() -> void:
	_over = true
	if _twist:
		PaleEye.release(self)
	for id: int in claimed:
		_drop_claim_look(id, false)
	claimed.clear()
	for tc in torches:
		_drop_light(tc)
		if not tc.out:
			tc.out = true
			tc.dawn = true  # the look's glow and island fade with the night (look_lit(), VRF5d); the rules see it out now
			var b := instance_from_id(int(tc.bearer)) as Person
			if b != null and b.is_alive() and b.anchor.is_equal_approx(tc.at):
				b.send_to_post(b.post if b.post != Vector2.INF else b.ground_pos)
	if _crowd != null and is_instance_valid(_crowd):
		if _crowd.dusk != null and _crowd.dusk.laid.is_connected(_on_laid):
			_crowd.dusk.laid.disconnect(_on_laid)
		if _veil != 0:
			_crowd.end_veil_all(_veil)
	_veil = 0
	_leave_night()
	_hush_off()


## The held night's sound fades out over the dawn (sound only). A pool voice already handed to another cue is left alone.
func _hush_off() -> void:
	var v := _hush
	_hush = null
	if v == null or not is_instance_valid(v) or v.get_meta(&"cue", &"") != &"v_evernight_loop":
		return
	if ctx != null and ctx.sfx != null and is_instance_valid(ctx.sfx) and ctx.sfx.is_inside_tree():
		ctx.fade_out(v, DAWN)
	elif v is AudioStreamPlayer2D:
		(v as AudioStreamPlayer2D).stop()


func _live() -> bool:
	return _crowd != null and is_instance_valid(_crowd)


func _live_lights() -> bool:
	return _lights != null and is_instance_valid(_lights)


## The town-wide night (owners on the crowd): the first owner saves the town as it was and darkens it; the last puts it back.
func _join_night() -> void:
	if _night_on or not _live():
		return
	_night_on = true
	var g: Dictionary = _crowd.get_meta(NIGHT_KEY, {})
	if g.is_empty():
		var rules: Rules = ctx.rules if ctx != null and ctx.rules != null and is_instance_valid(ctx.rules) else null
		g = {"owners": {}, "everywhere": _crowd.dusk != null and _crowd.dusk.everywhere, "sight": _crowd.sight_scale, "rules": rules,
			"had_haste": rules != null and rules.haste.has("veil"), "haste": rules.haste.get("veil", 1.0) if rules != null else 1.0}
		_crowd.set_meta(NIGHT_KEY, g)
		if _crowd.dusk != null:
			_crowd.dusk.everywhere = true
		_crowd.sight_scale = minf(_crowd.sight_scale, NightRules.NIGHT_SIGHT)
		if rules != null:
			rules.haste["veil"] = HASTE
	(g.owners as Dictionary)[get_instance_id()] = true


func _leave_night() -> void:
	if not _night_on:
		return
	_night_on = false
	if not _live() or not _crowd.has_meta(NIGHT_KEY):
		return
	var g: Dictionary = _crowd.get_meta(NIGHT_KEY)
	(g.owners as Dictionary).erase(get_instance_id())
	if not (g.owners as Dictionary).is_empty():
		return
	_crowd.remove_meta(NIGHT_KEY)
	if _crowd.dusk != null:
		_crowd.dusk.everywhere = bool(g.everywhere)
	_crowd.sight_scale = float(g.sight)
	var rules: Variant = g.rules
	if rules != null and is_instance_valid(rules):
		if bool(g.had_haste):
			(rules as Rules).haste["veil"] = g.haste
		else:
			(rules as Rules).haste.erase("veil")


## The look (owners on the light field): the first owner saves the light as it was; the lowest-id owner eases it each frame; the last
## puts it back.
func _join_look() -> void:
	if _look_on or not _live_lights():
		return
	_look_on = true
	var g: Dictionary = _lights.get_meta(LOOK_KEY, {})
	if g.is_empty():
		g = {"owners": [], "amb_base": _lights.ambient, "amb_last": _lights.ambient, "tint": _lights.tint, "tint_last": _lights.tint,
			"mute": 1.0}
		_lights.set_meta(LOOK_KEY, g)
	(g.owners as Array).append(get_instance_id())


func _leave_look() -> void:
	if not _look_on:
		return
	_look_on = false
	if not _live_lights() or not _lights.has_meta(LOOK_KEY):
		return
	var g: Dictionary = _lights.get_meta(LOOK_KEY)
	(g.owners as Array).erase(get_instance_id())
	if not (g.owners as Array).is_empty():
		# The next night takes the sky over now, before this frame is drawn: no frame without a sky, never two (VRF2).
		var next := instance_from_id(int((g.owners as Array)[0])) as EvernightFx
		if next != null and not next.is_queued_for_deletion():
			next._sky_look()
		return
	_lights.remove_meta(LOOK_KEY)
	if is_equal_approx(_lights.ambient, float(g.amb_last)):
		_lights.ambient = float(g.amb_base)
	if _lights.tint.is_equal_approx(g.tint_last):
		_lights.tint = g.tint
	if float(g.mute) < 1.0:
		_lights.mute(1.0)


## The night's strength 0..1: rises over the wave, full through the night, falls over the dawn.
func strength() -> float:
	if t < WAVE:
		return clampf(t / WAVE, 0.0, 1.0)
	if t < t_dawn:
		return 1.0
	return clampf(1.0 - (t - t_dawn) / DAWN, 0.0, 1.0)


func _fx_process(_delta: float) -> void:
	var s := strength()
	if _look_on and _live_lights():
		var g: Dictionary = _lights.get_meta(LOOK_KEY, {})
		if not g.is_empty() and (g.owners as Array)[0] == get_instance_id():
			# The light follows the darkest of the nights sharing it (VRF2): one night's dawn under another's night eases nothing.
			s = _shared_strength()
			# The battlefield sets the ambient afresh each frame (its dim); a value it set is the new base.
			if not is_equal_approx(_lights.ambient, float(g.amb_last)):
				g.amb_base = _lights.ambient
			_lights.ambient = float(g.amb_base) * lerpf(1.0, TownLook.ambient(Town.Look.NIGHT), s)
			g.amb_last = _lights.ambient
			_lights.tint = (g.tint as Color).lerp(TownLook.light_tint(Town.Look.NIGHT), s)
			g.tint_last = _lights.tint
			var share := 1.0 - s
			if share != float(g.mute):
				_lights.mute(share)
				g.mute = share
	if not _over and t >= WAVE and _live():
		_watch_bearers()
	_eye_huddles()
	if stains != null and is_instance_valid(stains):
		stains.set_fade(strength() if t >= t_dawn else 1.0)
	if wash != null and is_instance_valid(wash):
		wash.strength = strength()
		wash.front = _look_map().size.x * t / WAVE
		wash.lit = look_lit()
		wash.queue_redraw()
	_sky_look()


## The front's reach for the look: out from the click over WAVE to the map's farthest corner, slow near the click and fast across
## the town beyond (eased, so the god sees the wall rise and stand before it runs: VRD1); at dawn it rolls back to the click over
## DAWN the same way.
func look_front() -> float:
	var reach := _reach(_look_map())
	if t < t_dawn:
		return reach * pow(clampf(t / WAVE, 0.0, 1.0), FRONT_EASE) + (6.0 if t >= WAVE else 0.0)
	return reach * pow(clampf(1.0 - (t - t_dawn) / DAWN, 0.0, 1.0), FRONT_EASE)


## The map the look covers (the wash's, read once at the cast).
func _look_map() -> Rect2:
	return wash.map if wash != null and is_instance_valid(wash) else _map()


## From the click to the map's farthest corner, and a little past it.
func _reach(m: Rect2) -> float:
	var reach := 4.0
	for c in [m.position, m.end, Vector2(m.position.x, m.end.y), Vector2(m.end.x, m.position.y)]:
		reach = maxf(reach, (c as Vector2).distance_to(origin) + 4.0)
	return reach


## The torches the look still shows: those burning, and (VRF5d) those the dawn put away, fading with the night over DAWN. The rules
## read lit() alone.
func look_lit() -> Array:
	var out: Array = []
	var dawning := strength() > 0.0
	for tc in torches:
		if not tc.out or (bool(tc.get("dawn", false)) and dawning):
			out.append(tc.at)
	return out


## The wall's amount for this cast's own front: it stands while the night runs out and while it rolls back.
func _wall_amount() -> float:
	var reach := _reach(_look_map())
	if t < t_dawn:
		return smoothstep(0.0, 0.15, t) * (1.0 - smoothstep(reach - 4.0, reach + 2.0, look_front()))
	var k := (t - t_dawn) / DAWN
	return smoothstep(0.0, 0.1, k) * (1.0 - smoothstep(0.9, 1.0, k))


## Whether this cast shows the sky (VRF2): one sky at a time, the light look's owner's (the first in LOOK_KEY's ledger, the one that
## eases the light); a cast with no ledger (no light field) is alone and shows its own.
func _sky_owner() -> bool:
	if not _look_on or not _live_lights():
		return true
	var owners: Array = _lights.get_meta(LOOK_KEY, {}).get("owners", [])
	return owners.is_empty() or owners[0] == get_instance_id()


## The nights sharing this one's look (the ledger's live owners), this one first.
func _sharing() -> Array[EvernightFx]:
	var out: Array[EvernightFx] = [self]
	if _look_on and _live_lights():
		for id in (_lights.get_meta(LOOK_KEY, {}).get("owners", []) as Array):
			var o := instance_from_id(int(id)) as EvernightFx
			if o != null and o != self:
				out.append(o)
	return out


## The darkest of the nights sharing the look.
func _shared_strength() -> float:
	var s := 0.0
	for c in _sharing():
		s = maxf(s, c.strength())
	return s


## The look over the town this frame, shown by the sky's owner only (the others' pieces hidden): the shade and the air follow the
## farthest front of the nights sharing it (its cast leads: its centre, its wall), with every burning torch's island; the moon at the
## darkest night's strength. Each cast's torch glows are its own, out with their torch, fading over the dawn (VRF5d).
func _sky_look() -> void:
	var own := _sky_owner()
	var moon: NightMoon = wash.moon if wash != null and is_instance_valid(wash) and is_instance_valid(wash.moon) else null
	for n in [_shade, _air, _wall, moon]:
		if n != null and is_instance_valid(n):
			(n as CanvasItem).visible = own
	_glows_look()
	if not own:
		return
	var casts := _sharing()
	var lead: EvernightFx = self
	var s := 0.0
	var pts := PackedVector2Array()
	for c in casts:
		s = maxf(s, c.strength())
		if c.look_front() > lead.look_front():
			lead = c
		for p: Vector2 in c.look_lit():
			var dup := false
			for q in pts:
				dup = dup or q.distance_to(p) < 0.01
			if not dup and pts.size() < TORCHES:
				pts.append(p)
	var front := lead.look_front()
	for v in [_shade, _air]:
		if v != null and is_instance_valid(v):
			(v as EvernightSky.View).set_param(&"front", front)
			(v as EvernightSky.View).set_param(&"center", lead.origin)
	if _shade != null and is_instance_valid(_shade):
		var island := TORCH_COLOR
		for c in casts:
			if c._twist:
				island = FALSE_COLOR
		if island != _island:
			_island = island
			_shade.set_param(&"warm", EvernightSky.island_of(island))
		var arr := PackedVector2Array(pts)
		arr.resize(TORCHES)
		_shade.set_param(&"torches", arr)
		_shade.set_param(&"torch_count", pts.size())
	if _wall != null and is_instance_valid(_wall):
		_wall.front = front
		_wall.center = lead.origin
		_wall.amount = lead._wall_amount()
		_wall.queue_redraw()
	if moon != null:
		moon.strength = s
		moon.queue_redraw()


func _glows_look() -> void:
	var fade := strength()
	for i in _glows.size():
		var g: Variant = _glows[i]
		if g != null and is_instance_valid(g) and i < torches.size():
			var dawned := bool(torches[i].get("dawn", false))
			(g as EvernightSky.TorchGlow).lit = not torches[i].out or (dawned and fade > 0.0)
			(g as EvernightSky.TorchGlow).fade = fade if dawned else 1.0
			(g as EvernightSky.TorchGlow).false_light = _twist


func _finish() -> void:
	_end_night()
	_leave_look()
	super()


func _exit_tree() -> void:
	_end_night()
	_leave_look()
	super()


## Freed without finishing (an effect layer torn down outside the tree): the night still ends and the light comes back.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_end_night()
		_leave_look()
		_free_tracked(true)  # the look's pieces too (off the tree no _exit_tree() comes)


## The look on the ground (ground units: ctx.ground already carries Iso.BASIS, so the wash has none of its own -- it once did, and
## was drawn a basis too far, off the town): a faint silver ring round each burning torch, so the god sees the islands of light, and
## the pale moon in the sky (a child "Moon"). The night over the town itself is EvernightSky's (the cast's shade, air and wall).
class NightWash extends Node2D:
	## Where the moon first hangs, as a share of the map, before it finds the camera's sky.
	const MOON_AT := Vector2(0.14, 0.10)
	var fx_id := 0
	var center := Vector2.ZERO
	var map := Rect2()
	var strength := 0.0
	var front := 0.0
	var lit: Array = []
	## The ring's radius (level 5 shrinks it).
	var torch_r := EvernightFx.TORCH_R
	## The pale moon (a child named "Moon"): drawn in code, freed with the wash.
	var moon: NightMoon

	func _init() -> void:
		z_index = 3
		moon = NightMoon.new()
		moon.name = "Moon"
		add_child(moon)

	## Hangs the moon over its fixed place on the map (in world pixels: the moon is top-level); once in the tree it keeps to the sky.
	func place_moon() -> void:
		moon.position = Iso.ground_to_screen(map.position + MOON_AT * map.size)

	## Its cast freed without finishing: it goes too.
	func _process(_delta: float) -> void:
		if instance_from_id(fx_id) == null:
			queue_free()

	func _draw() -> void:
		if strength <= 0.0:
			return
		for c: Vector2 in lit:
			draw_arc(c, torch_r, 0.0, TAU, 32, Color(VeilParts.SILVER, 0.4 * strength), 0.08)


## Evernight's pale moon, part of the night's sky: hung at a fixed place in the camera's view (EvernightSky.MOON_UV: screen-anchored,
## VRD3), the same size at any zoom, above the night's shade (its light lifts the dark round it) and under the drifting mist, which
## crosses it. No hard rim: a wide glow falling off in many faint steps, and a face (painted once into a small texture) only a little
## brighter than its glow, soft at its edge, its seas mottled in, a waning crescent of the night's own colour over one side. Drawn
## only; no art file, no luck (the mottling is a fixed hash).
class NightMoon extends Node2D:
	const R := 15
	static var _face: ImageTexture
	var strength := 0.0

	func _init() -> void:
		top_level = true
		z_as_relative = false
		z_index = EvernightSky.Z_AIR  # the air's z: over the shade (Z_SHADE), under the aim (5); the same z as the air, as before VRF1

	func _process(_delta: float) -> void:
		if not is_inside_tree() or strength <= 0.0:
			return
		var ct := get_canvas_transform()
		global_position = (ct.affine_inverse() * (get_viewport_rect().size * EvernightSky.MOON_UV)).round()
		scale = Vector2.ONE / maxf(ct.get_scale().x, 0.01)

	## The moon's face: a soft disc, mottled seas, a crescent shadow, in a (2R+4)-pixel square.
	static func face() -> ImageTexture:
		if _face != null:
			return _face
		var size := R * 2 + 4
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		var c := Vector2(size, size) * 0.5
		var shadow_at := c + Vector2(R * 0.62, R * 0.22)
		var dusk := VeilParts.DUSK.darkened(0.45)
		for y in size:
			for x in size:
				var p := Vector2(x, y) + Vector2(0.5, 0.5)
				var d := p.distance_to(c) / float(R)
				if d > 1.08:
					continue
				var edge := clampf((1.08 - d) / 0.22, 0.0, 1.0)
				var cell := Vector2(floorf(x / 3.0), floorf(y / 3.0))
				var h := fposmod(sin(cell.x * 12.9898 + cell.y * 78.233) * 43758.5453, 1.0)
				var h2 := fposmod(sin(floorf(x / 6.0) * 39.346 + floorf(y / 6.0) * 11.135) * 24634.6345, 1.0)
				var lum := 0.86 - 0.10 * h2 - 0.05 * h - 0.06 * d
				var col := Color(lum * 0.97, lum * 0.98, lum * 1.06)
				var sh := clampf((float(R) * 0.98 - p.distance_to(shadow_at)) / (float(R) * 0.35), 0.0, 1.0)
				col = col.lerp(dusk, sh * 0.8)
				img.set_pixel(x, y, Color(col, edge * lerpf(0.55, 0.35, sh)))
		_face = ImageTexture.create_from_image(img)
		return _face

	func _draw() -> void:
		if strength <= 0.0:
			return
		var s := strength
		# The glow: many faint discs, wide to narrow, so it falls off softly into the night.
		for k in 10:
			var f := float(k) / 9.0
			draw_circle(Vector2.ZERO, float(R) * lerpf(6.0, 1.1, f), Color(0.78, 0.80, 0.92, 0.022 * s))
		var tex := face()
		draw_texture(tex, -tex.get_size() * 0.5, Color(1, 1, 1, s))
