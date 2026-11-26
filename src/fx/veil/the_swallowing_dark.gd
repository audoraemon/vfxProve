class_name TheSwallowingDarkFx
extends FxTimeline
## The Swallowing Dark (Veil, Tier V; spec 5.9): a black circle opens at the click and grows from its centre at GROW a second, from 0
## to its light FULL_R (VeilRules: 10), or, cast in the dark, from the radius of the dusk patch it was cast in (Dusk.r_at()) to its dark
## FULL_R (14). Nobody sees it grow: it registers no danger, frightens nobody, raises no alarm; one who walks out in time lives. At full
## size everything inside is gone, unheard by the town: every person (Crowd.take(p, &"void"): no body, no voice, no remain), every animal
## and visitor, every lying remain, every decor piece whose `at` is inside, and every building whose footprint lies wholly inside
## (wholly_inside()) by Eminent Domain's quiet path (EnvironmentField.remove(s, true, true), batched: the walk grid opens, no rubble), with
## whoever shelters in it. Spared: a building MissionKeeps.spared() names (the Citadel and Temple, the hallowed, the mission's own),
## one the night wants down (director.wants_down(): the dark takes, it does not destroy, and a taken target is never razed) and the
## town's own gates, bridges, postern, dock and fountain, which its managers go on using (as Eminent Domain keeps them). A
## blighted foothold that goes is healed first (BlightFx.heal()), so no foothold points at a removed building. The removals are spread
## over frames, PER_FRAME at most each (BUILDINGS_PER_FRAME of them buildings), outermost first (an inward fold). The emptied ground is dusk for VeilRules.DUSK_TIME and
## stays bare dark earth (a ground mark left for the mission). Nothing of it is remembered: no incident, no search, no count.
## With no crowd (the VFX Sandbox) it grows at the light size and takes the town's buildings and decor only.

## Growth in ground units a second.
const GROW := 0.5
## At most this many removals in one frame.
const PER_FRAME := 24
## Of which at most this many buildings. They go by EnvironmentField's batch remove (remove(..., reindex = false): each struck from
## its own index cells, about 0.5 ms, where a full index rebuild is 6-14 ms), with one reindex() when the fold is done (VA10).
const BUILDINGS_PER_FRAME := 8
## The circle has opened (the rim drawn) this long after the cast: the other slots unlock then (ruling C16).
const T_OPEN := 0.5
## The fold's drawing after full size.
const FOLD := 0.6
## The silent kill kind (Crowd.SILENT_KINDS).
const KIND := &"void"

## The look (spec 6; looks only: nothing here decides who or what is taken, or when). The circle is a hole: a funnel on the ground
## (SH_HOLE) with an apron of APRON ground units round its rim whose dust and loose ground are drawn in over the edge, and TENDRILS
## of dark reaching up over the rim and curling inward (in the y-sorted world, so the town's houses stand in front of the far ones).
## For HEAVE before full size the ground heaves and the dark rises from it (VRD7): a rim of darkness (EvernightSky.Wall, RIM_H pixels
## tall) stands up at the circle's edge and closes in to the middle, everything behind it, ground, houses and people, going black
## (SH_UNDER, over the town), the tendrils pulled down with it. At full size the whole circle is under, so the fold's removals go
## unseen; over FOLD the black drains back into the ground from the edge inward (from DRAIN_FROM of the fold), leaving the bare earth
## (a shallow scorched bowl, BareEarth.SHADER).
const HEAVE := 1.4
const RIM_H := 210.0
const DRAIN_FROM := 0.4
const APRON := 2.2
const TENDRILS := 22
const SH_HOLE := preload("res://shaders/swallow_hole.gdshader")
const SH_UNDER := preload("res://shaders/swallow_under.gdshader")
## Dust and loose ground drawn in over the rim (spawns a second), and their colours: street dust going into the violet dark.
const DUST_RATE := 34.0
const CHUNK_RATE := 6.0
const DUST_LIFE := [Color(0.40, 0.35, 0.30, 0.9), Color(0.33, 0.29, 0.27, 0.85), Color(0.22, 0.13, 0.30, 0.65),
	Color(0.11, 0.05, 0.17, 0.35)]
const CHUNK_LIFE := [Color("4b4440"), Color("3a3432"), Color("261d2e"), Color(0.08, 0.04, 0.12, 0.6)]

## The sound (review pass 2, spec 4; sound only: nothing here decides who or what is taken, or when). The cast opens deep (v_swallow);
## a low rumble (CUE_LOOP, one voice) is held from the cast to the fold, swelling with the circle from RUMBLE_FROM_DB under its catalog
## level to full just before the fold; over the heave a rising inward rush (CUE_HEAVE) ends on the fold, scheduled from HEAVE and
## t_full (the look's own times); the fold hits (v_swallow_take). The rumble fades out in RUMBLE_FADE at the fold, and with the cast
## however it ends (_finish(), _exit_tree(), freed); a rush whose fold never comes goes with it. The town hears none of it.
const CUE_LOOP := &"v_swallow_loop"
const CUE_HEAVE := &"v_swallow_heave"
const RUMBLE_FROM_DB := -12.0
const RUMBLE_FADE := 0.25
## Level 5 (Veil twists 2, "The Moon's Face"): at the fold the circle is left pitted with MoonCraters (about a third of it), which hurt and take whoever stays in them.
const TWIST_KEY := "swallow"
## The meta a voice of this cast's carries (its instance id), so a voice handed to another cue or cast is left alone.
const VOICE_OWNER := &"swallow_cast"

## This cast's sizes: where it starts, where it ends, and when it gets there.
var start_r := 0.0
var full_r := 10.0
var t_full := 20.0
## This cast's growth a second, at its level (GROW at level 1).
var lv_grow := GROW
## Whether full size has been reached (the removals begun).
var swallowed := false
## How many things it has taken so far (people, animals, remains, decor, buildings).
var removed := 0
## The removals still to make: [kind, thing, structure or pack].
var _queue: Array = []
## The buildings the dark takes (fixed at full size): a person sheltering is taken only with one of these.
var _gone := {}
## Buildings removed by the batch path since the last full index rebuild.
var _batched := false
## The look's pieces (any may be missing in a bare context): the hole on the ground plane, the tendrils in the world, the dust and
## the loose ground over the town, the closing rim and the dark under it over everything.
var _hole: QuadFx
var _tendrils: Array[SwallowTendril] = []
var _dust: PixelParticles
var _chunks: PixelParticles
var _under: QuadFx
var _rim: EvernightSky.Wall
## The look's own scatter (seeded from the click: never the shared stream) and its spawn clock.
var _scatter := RandomNumberGenerator.new()
var _dust_due := 0.0
var _chunk_due := 0.0
var _heaved := false
var _folding := false
## The held rumble's voice and the heave's rush (null in a bare context, or once let go).
var _rumble: Variant = null
var _rush: Variant = null
## How far into the rush it was started (0 on time; more when the growth was shorter than the heave).
var rush_from := 0.0
## The level-5 twist (PowerBook.twist_at, once in _build()): the Moon's Face, craters laid at the fold (MoonCraters).
var _twist := false


## True when all four corners of `s`'s footprint lie within `r` of `at`.
static func wholly_inside(s: Structure, at: Vector2, r: float) -> bool:
	if s == null or not is_instance_valid(s):
		return false
	var f := s.footprint
	var rr := r * r
	for c in [f.position, Vector2(f.end.x, f.position.y), Vector2(f.position.x, f.end.y), f.end]:
		if (c as Vector2).distance_squared_to(at) > rr:
			return false
	return true


func _build() -> void:
	_twist = PowerBook.twist_at(extra, TWIST_KEY)
	lv_grow = PowerBook.stat(extra, "swallow", "GROW", GROW)
	full_r = VeilParts.size(self, "swallow", "FULL_R")
	if VeilParts.dark(self) and ctx.crowd != null and ctx.crowd.dusk != null:
		start_r = minf(ctx.crowd.dusk.r_at(origin), full_r)
	t_full = (full_r - start_r) / lv_grow
	busy = T_OPEN
	duration = t_full + FOLD
	at(t_full, _swallow)
	if t_full > 0.0:
		at(maxf(t_full - HEAVE, 0.0), _heave_sound)
	ctx.play(&"v_swallow", origin)
	_rumble = _own(ctx.play(&"v_swallow_loop", origin))
	_swell()
	_build_look()


## The look's pieces, each only where its layer exists (a bare test context has an overhead layer only).
func _build_look() -> void:
	_scatter.seed = _look_seed()
	# The fold's shaders drawn once now, all but unseen, so the renderer compiles them at the cast and not on the fold's frame.
	if ctx.ground != null:
		for sh: Shader in [SH_UNDER, EvernightSky.SH_WALL, BareEarth.SHADER]:
			var warm := FxParts.quad(self, sh, Vector2.ONE * 0.1, ctx.ground)
			warm.position = origin
			warm.modulate.a = 0.02
			warm.life = 0.2
	if ctx.ground != null:
		_hole = FxParts.quad(self, SH_HOLE, Vector2.ONE * (full_r + APRON) * 2.0, ctx.ground)
		_hole.position = origin
		_hole.z_index = 7  # over the town's lamp pools (absolute -4): light does not lie on a hole
		_hole.set_param("apron", APRON / (full_r + APRON))
		_hole.set_param("hole", 0.0)
		_hole.set_param("open", 0.0)
		_hole.set_param("seed", float(_look_seed() % 97))
		_hole.set_param("black", VeilParts.BLACK)
		_hole.set_param("dusk", VeilParts.DUSK)
		_hole.set_param("veil", VeilParts.VEIL)
		_hole.set_param("silver", VeilParts.SILVER)
	if ctx.world != null:
		for k in TENDRILS:
			var td := SwallowTendril.new()
			td.k = k
			td.height = 52.0 + 44.0 * fposmod(float(k) * 0.754878, 1.0)
			_tendrils.append(track(td, ctx.world) as SwallowTendril)
	if ctx.overhead_back != null:
		var sp := Iso.ground_to_screen(origin)
		_dust = _particles(PixelParticles.Shape.SQUARE, DUST_LIFE, sp, 1)
		_chunks = _particles(PixelParticles.Shape.CHUNK, CHUNK_LIFE, sp, 2)
		_chunks.gravity = 380.0
		_chunks.shadows = true
		# The dark under the closing rim: a quad over the circle's ellipse (and a margin) with the rim's wall just above it.
		var semi := Iso.radius_to_screen(full_r + 1.5)
		_under = FxParts.quad(self, SH_UNDER, semi * 2.0, ctx.overhead_back)
		_under.position = sp
		_under.z_index = 1
		_under.visible = false
		_under.set_param("center", origin)
		_under.set_param("seed", float(_look_seed() % 89))
		_under.set_param("black", VeilParts.BLACK)
		_under.set_param("dusk", VeilParts.DUSK)
		_under.set_param("veil", VeilParts.VEIL)
		_rim = EvernightSky.Wall.new()
		_rim.z_index = 2
		_rim.center = origin
		_rim.height = RIM_H
		_rim.rise_with_front = false
		_rim.mat.set_shader_parameter(&"black", VeilParts.BLACK)
		_rim.mat.set_shader_parameter(&"dusk", VeilParts.DUSK)
		_rim.mat.set_shader_parameter(&"veil", VeilParts.VEIL)
		_rim.mat.set_shader_parameter(&"silver", VeilParts.SILVER)
		track(_rim, ctx.overhead_back)


## A particle system over the town at `sp`, on its own seed (never the shared stream), kept until the cast ends.
func _particles(shape: PixelParticles.Shape, ramp: Array, sp: Vector2, salt: int) -> PixelParticles:
	var p := PixelParticles.new()
	p.rng.seed = _look_seed() + salt
	p.shape = shape
	p.ramp = PackedColorArray(ramp)
	p.position = sp
	p.auto_free = false
	track(p, ctx.overhead_back)
	return p


## The look's seed: from the click, so a replay looks the same.
func _look_seed() -> int:
	return absi(int(origin.x * 977.0) * 31 + int(origin.y * 613.0))


## The circle's radius now.
func radius() -> float:
	return minf(start_r + lv_grow * t, full_r)


## How many removals are still to make.
func left() -> int:
	return _queue.size()


func _fx_process(delta: float) -> void:
	_look(delta)
	if not swallowed:
		_swell()
		return
	var n := 0
	var built := 0
	while n < PER_FRAME and not _queue.is_empty():
		if _queue[0][0] == &"building":
			if built >= BUILDINGS_PER_FRAME:
				break
			built += 1
		_remove(_queue.pop_front())
		n += 1
	# The fold waits for the last removal (a slow frame rate).
	if not _queue.is_empty():
		duration = maxf(duration, t + 0.1)
	elif _batched:
		# The buildings went by the batch remove (each struck from its own index cells); one full rebuild closes the batch.
		_batched = false
		ctx.env.reindex()


## The look this frame, from the cast's own clock and radius (nothing per building or per person).
func _look(delta: float) -> void:
	var r := radius()
	var opened := clampf(t / T_OPEN, 0.0, 1.0)
	var folded := clampf((t - t_full) / FOLD, 0.0, 1.0) if swallowed else 0.0
	var closing := clampf((t - (t_full - HEAVE)) / HEAVE, 0.0, 1.0)
	var heave := closing * (1.0 - folded)
	# The rim's place: at the edge when the heave begins, in the middle at full size.
	var front := r * (1.0 - pow(closing, 1.15))
	if is_instance_valid(_hole):
		_hole.set_param("hole", r / (full_r + APRON))
		_hole.set_param("open", opened)
		_hole.set_param("heave", heave)
		_hole.set_param("fold", folded)
	var centre := Iso.ground_to_screen(origin)
	for td in _tendrils:
		if not is_instance_valid(td):
			continue
		var a := float(td.k) * TAU / float(TENDRILS) + 0.09 * sin(t * 0.3 + float(td.k))
		td.position = Iso.ground_to_screen(origin + Vector2.from_angle(a) * front * 0.985)
		td.inward = centre - td.position
		td.clock = t
		td.reach = opened * clampf(0.35 + r / 8.0, 0.35, 1.0) * (1.0 - closing) * (1.0 - folded)
		td.fade = opened * (1.0 - folded)
		td.queue_redraw()
	if heave > 0.0 and not _heaved:
		_heaved = true
		_heave_burst(r)
	if swallowed and not _folding:
		_folding = true
		if ctx.shake != null:
			ctx.shake.add_trauma(0.3)
	_pull_dust(delta, r, heave, folded)
	_under_look(r, front, closing, folded)


## The ground heaves: loose ground thrown up all round the rim (falling back in), and the camera feels it.
func _heave_burst(r: float) -> void:
	if ctx.shake != null:
		ctx.shake.add_trauma(0.35)
	if not is_instance_valid(_chunks):
		return
	for i in 40:
		var dir := Vector2.from_angle(_scatter.randf() * TAU)
		_chunks.burst(1, {"offset": Iso.ground_to_screen(dir * (r + _scatter.randf_range(-0.3, 0.8))),
			"velocity": -Iso.ground_to_screen(dir) * _scatter.randf_range(0.8, 2.0), "alt_speed": Vector2(70, 170),
			"life": Vector2(0.9, 1.5), "size": Vector2(2, 4)})


## Dust and loose ground drawn in from the apron over the rim while the circle grows (faster as the ground heaves).
func _pull_dust(delta: float, r: float, heave: float, folded: float) -> void:
	if not is_instance_valid(_dust) or swallowed or r <= 0.0:
		return
	_dust_due += DUST_RATE * (1.0 + 1.5 * heave) * minf(1.0, 0.3 + r / full_r) * delta
	_chunk_due += CHUNK_RATE * (1.0 + heave) * delta
	while _dust_due >= 1.0:
		_dust_due -= 1.0
		var dir := Vector2.from_angle(_scatter.randf() * TAU)
		_dust.burst(1, {"offset": Iso.ground_to_screen(dir * (r + _scatter.randf_range(0.2, APRON))),
			"velocity": -Iso.ground_to_screen(dir) * _scatter.randf_range(0.9, 1.6) * (1.0 + 1.5 * heave),
			"alt": Vector2(0, 3), "life": Vector2(1.4, 2.2), "size": Vector2(1, 2)})
	while _chunk_due >= 1.0:
		_chunk_due -= 1.0
		var dir := Vector2.from_angle(_scatter.randf() * TAU)
		_chunks.burst(1, {"offset": Iso.ground_to_screen(dir * (r + _scatter.randf_range(0.3, 1.6))),
			"velocity": -Iso.ground_to_screen(dir) * _scatter.randf_range(0.5, 0.9), "life": Vector2(1.6, 2.4),
			"size": Vector2(2, 3.5)})


## The dark rising from the ground: the rim stands up at the edge as the heave begins and closes in to the middle by full size, the
## circle going black behind it; over the fold the black drains back into the ground from the edge inward.
func _under_look(r: float, front: float, closing: float, folded: float) -> void:
	var drain := smoothstep(DRAIN_FROM, 1.0, folded)
	if is_instance_valid(_under):
		_under.visible = closing > 0.0 and drain < 1.0
		_under.set_param("edge", r)
		_under.set_param("front", front if closing < 1.0 else -2.0)
		_under.set_param("drain", drain)
	if is_instance_valid(_rim):
		_rim.front = front
		_rim.height = RIM_H * clampf(front / 3.0, 0.25, 1.0)
		_rim.amount = smoothstep(0.0, 0.12, closing) * (1.0 - smoothstep(0.85, 1.0, closing))
		_rim.queue_redraw()


## The rumble's level now: RUMBLE_FROM_DB under its catalog level at the cast, rising with the circle to full just before the fold.
func rumble_db() -> float:
	var grown := clampf(t / t_full, 0.0, 1.0) if t_full > 0.0 else 1.0
	return float(Sfx.CATALOG[CUE_LOOP].get("db", 0.0)) + lerpf(RUMBLE_FROM_DB, 0.0, grown)


func _swell() -> void:
	if _mine(_rumble, CUE_LOOP):
		(_rumble as AudioStreamPlayer2D).volume_db = rumble_db()


## The heave's rush, from HEAVE before the fold: its rise ends on the fold. Started late (a growth shorter than the heave, or a slow
## frame), it starts that far into the cue, so it still ends on the fold.
func _heave_sound() -> void:
	if swallowed or finished:
		return
	_rush = _own(ctx.play(&"v_swallow_heave", origin))
	var late := t - (t_full - HEAVE)
	if late > 0.02:
		rush_from = late
		if _mine(_rush, CUE_HEAVE) and (_rush as AudioStreamPlayer2D).playing:
			(_rush as AudioStreamPlayer2D).seek(late)


## A voice this cast just asked for, marked as its own (null stays null).
func _own(v: Variant) -> Variant:
	if v != null and is_instance_valid(v) and v is Node:
		(v as Node).set_meta(VOICE_OWNER, get_instance_id())
		return v
	return null


## True while `v` is still this cast's voice of `cue` (not freed, not handed to another cue or another cast by the pool). Untyped, so
## a voice freed with the pool (a torn-down stage) is read without an error.
func _mine(v: Variant, cue: StringName) -> bool:
	if v == null or not is_instance_valid(v) or not v is AudioStreamPlayer2D:
		return false
	var n := v as Node
	return n.get_meta(&"cue", &"") == cue and int(n.get_meta(VOICE_OWNER, 0)) == get_instance_id()


## Lets the rumble go (faded out over `seconds`); and the rush too when the fold never came. Sound only; safe to call twice.
func _sound_off(seconds: float) -> void:
	var voices := [[_rumble, CUE_LOOP]]
	if not swallowed:
		voices.append([_rush, CUE_HEAVE])
	_rumble = null
	if not swallowed:
		_rush = null
	for pair: Array in voices:
		var v: Variant = pair[0]
		if not _mine(v, pair[1]):
			continue
		if ctx != null and ctx.sfx != null and is_instance_valid(ctx.sfx):
			ctx.fade_out(v as Node, seconds)  # Sfx stops it at once when it is off the tree (a torn-down stage)
		else:
			(v as AudioStreamPlayer2D).stop()


func _finish() -> void:
	_sound_off(RUMBLE_FADE)
	super()


func _exit_tree() -> void:
	_sound_off(RUMBLE_FADE)
	super()


## Freed without finishing off the tree (no _exit_tree() comes): the look's pieces go too, and the rumble stops.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_sound_off(RUMBLE_FADE)
		_free_tracked(true)


## Full size: what is inside is fixed now and taken over the next frames; the ground is left dusk and bare.
func _swallow() -> void:
	swallowed = true
	_queue = _inside()
	VeilParts.land(self, origin, full_r)
	_sound_off(RUMBLE_FADE)
	ctx.play(&"v_swallow_take", origin)
	if ctx.ground != null:
		var mark := BareEarth.new()
		mark.at = origin
		mark.r = full_r
		ctx.ground.add_child(mark)  # not tracked: the bare earth stays for the mission (Battlefield.clear_effects() frees it)
		if _twist:
			var craters := MoonCraters.new()
			craters.circles = MoonCraters.place(origin, full_r, int(MoonCraters.COUNT[1 if VeilParts.dark(self) else 0]),
				hash(origin.round()), _crater_keep_out())
			craters.crowd = ctx.crowd
			craters.field = ctx.field
			craters.eye_layer = ctx.overhead_back if ctx.overhead_back != null else ctx.overhead
			ctx.ground.add_child(craters)  # not tracked, like the bare earth: it stays for the mission


## The town's own gates, bridges, postern, dock and fountain, which its managers go on using: neither the fold nor the craters touch them.
func _kept_structures() -> Array:
	var keep: Array = []
	var town: Town = ctx.crowd._town if ctx.crowd != null else null
	if is_instance_valid(town):
		keep.append_array(town.gates)
		keep.append_array(town.bridges)
		keep.append_array([town.bridge, town.postern, town.dock, town.fountain])
	return keep


## Whether the mission needs `s` standing: MissionKeeps lets a power that destroys fell what the night wants down; the dark only takes
## (no `destroyed`), and a taken target is never razed: the objective would be lost for good (final review, Critical 1).
func _needed(s: Structure) -> bool:
	var director: MissionDirector = ctx.rules.director if ctx.rules != null else null
	return MissionKeeps.spared(s, ctx.crowd, director) or (director != null and director.wants_down(s))


## Footprints (Rect2, padded) of everything the fold spares within the circle: the town's own structures and the mission's own. The craters
## are laid clear of them.
func _crater_keep_out() -> Array:
	var out: Array = []
	if ctx.env == null:
		return out
	var kept := _kept_structures()
	for s in ctx.env.structures():
		if not is_instance_valid(s) or s.taken:
			continue
		var f: Rect2 = s.footprint.grow(0.5)
		if not Rect2(origin - Vector2(full_r, full_r), Vector2(full_r, full_r) * 2.0).intersects(f):
			continue
		if kept.has(s) or _needed(s):
			out.append(f)
	return out


## Everything to take, outermost first (then by instance id): no rng decides it.
func _inside() -> Array:
	var r := full_r
	var crowd: Crowd = ctx.crowd
	var groups: Array = []  # [distance, id, entries]
	# Buildings wholly inside, minus the spared.
	var keep := _kept_structures()
	var gone := {}
	if ctx.env != null:
		for s in ctx.env.structures():
			if not is_instance_valid(s) or s.taken or keep.has(s) or not wholly_inside(s, origin, r):
				continue
			if _needed(s):
				continue
			gone[s] = true
	_gone = gone
	# Who shelters where: a sheltered person goes with a taken building and is out of reach in a standing one.
	var sheltered := {}
	if crowd != null and crowd.shelters != null:
		for s in crowd.shelters.shelters:
			for p in crowd.shelters.shelters[s].inside:
				if is_instance_valid(p):
					sheltered[p] = s
	var by_house := {}
	var people := {}
	if crowd != null:
		if ctx.field != null:
			for e in ctx.field.in_radius(origin, r):
				if e is Person:
					people[e] = true
		for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
			for p in group:
				if is_instance_valid(p) and p.is_alive() and p.ground_pos.distance_to(origin) <= r:
					people[p] = true
		for p: Person in people:
			if sheltered.has(p):
				var s: Structure = sheltered[p]
				if gone.has(s):
					if not by_house.has(s):
						by_house[s] = []
					(by_house[s] as Array).append(p)
				continue
			groups.append([p.ground_pos.distance_to(origin), p.get_instance_id(), [[&"person", p, null]]])
		if crowd.animals != null:
			for a in crowd.animals.in_radius(origin, r):
				groups.append([a.ground_pos.distance_to(origin), a.get_instance_id(), [[&"animal", a, crowd.animals]]])
		for v in crowd.visitors:
			if not is_instance_valid(v):
				continue
			for a in v.living():
				if a.ground_pos.distance_to(origin) <= r:
					groups.append([a.ground_pos.distance_to(origin), a.get_instance_id(), [[&"visitor", a, v]]])
		if crowd.remains != null:
			for b in crowd.remains.near(origin, r):
				groups.append([b.pos.distance_to(origin), b.get_instance_id(), [[&"remain", b, null]]])
	if ctx.env != null:
		for d in ctx.env.decor():
			if is_instance_valid(d) and d.at.distance_to(origin) <= r:
				groups.append([d.at.distance_to(origin), d.get_instance_id(), [[&"decor", d, null]]])
	for s: Structure in gone:
		var entries: Array = []
		var in_it: Array = by_house.get(s, [])
		in_it.sort_custom(func(x: Person, y: Person) -> bool: return x.get_instance_id() < y.get_instance_id())
		for p in in_it:
			entries.append([&"person", p, s])
		entries.append([&"building", s, null])
		groups.append([s.center().distance_to(origin), s.get_instance_id(), entries])
	groups.sort_custom(func(x: Array, y: Array) -> bool:
		if not is_equal_approx(float(x[0]), float(y[0])):
			return float(x[0]) > float(y[0])
		return int(x[1]) < int(y[1]))
	var out: Array = []
	for g in groups:
		out.append_array(g[2])
	return out


func _remove(entry: Array) -> void:
	var what: StringName = entry[0]
	var crowd: Crowd = ctx.crowd
	match what:
		&"person":
			var p: Person = entry[1]
			if not is_instance_valid(p) or not p.is_alive():
				return
			# Where he is now decides (C20): sheltering, only with a building the dark takes; out in the open or indoors at home, only
			# within the circle (one who walked out lives).
			var house := _shelter_of(p)
			if house != null:
				if not _gone.has(house):
					return  # out of reach in a standing building, whenever he went in
			elif p.ground_pos.distance_to(origin) > full_r:
				return
			if VeilParts.take_out(crowd, p, KIND):  # a shelterer is let out of his shelter first
				removed += 1
		&"animal":
			var a: Animal = entry[1]
			if is_instance_valid(a):
				(entry[2] as AnimalPack).take(a)
				removed += 1
		&"visitor":
			var a: Animal = entry[1]
			if is_instance_valid(a) and is_instance_valid(entry[2]):
				(entry[2] as Visitors).take(a)
				removed += 1
		&"remain":
			# Still lying inside, unhidden and on the ledger (not taken up or carried off since full size).
			if crowd.remains != null and crowd.remains.near(origin, full_r).has(entry[1]):
				crowd.remains.take(entry[1])
				removed += 1
		&"decor":
			var d: Decor = entry[1]
			if is_instance_valid(d) and ctx.env.decor().has(d):
				ctx.env.remove_decor(d)
				removed += 1
		&"building":
			_take_building(entry[1])


## The shelter `p` is inside now, else null.
func _shelter_of(p: Person) -> Structure:
	var crowd: Crowd = ctx.crowd
	if not p.inside or crowd == null or crowd.shelters == null:
		return null
	for s in crowd.shelters.shelters:
		if (crowd.shelters.shelters[s].inside as Array).has(p):
			return s
	return null


## A building goes whole: a foothold is healed first (its lasting dusk and its light), whoever came to shelter in it since goes with
## it, and the shelter forgets it; the field lets go of it and the walk grid opens where it stood (no rubble).
func _take_building(s: Structure) -> void:
	if not is_instance_valid(s) or s.taken or not ctx.env.structures().has(s):
		return
	var crowd: Crowd = ctx.crowd
	if crowd != null:
		if crowd.footholds.has(s):
			BlightFx.heal(crowd, ctx.env, s)
		if crowd.shelters != null and crowd.shelters.shelters.has(s):
			for p in (crowd.shelters.shelters[s].inside as Array).duplicate():
				if is_instance_valid(p) and (p as Person).is_alive():
					VeilParts.take_out(crowd, p, KIND)
			crowd.shelters.shelters.erase(s)
	ctx.env.remove(s, true, true, false)
	_batched = true
	removed += 1


## A tendril of the dark (screen pixels, standing on the rim; in the y-sorted world, so the houses before it hide its foot): it
## reaches up, curls in over the hole and sinks back, on its own phase. Drawn only; the cast sets where it stands each frame.
class SwallowTendril extends Node2D:
	const SEGMENTS := 8
	var k := 0
	## Its full height in pixels, toward the middle of the hole, the cast's clock, and how far it reaches now (0 = gone).
	var height := 40.0
	var inward := Vector2.ZERO
	var clock := 0.0
	var reach := 0.0
	## How strongly it shows (0 = gone).
	var fade := 1.0

	func _draw() -> void:
		var c := fposmod(clock * 0.42 + float(k) * 0.618034, 1.0)
		var grow := sin(c * PI)
		var span := height * grow * reach
		if span < 2.0:
			return
		var curl := smoothstep(0.2, 0.85, c)
		var inw := inward.normalized() if inward.length() > 0.01 else Vector2.UP
		var side := Vector2(-inw.y, inw.x)
		var pts := PackedVector2Array()
		for j in SEGMENTS + 1:
			var u := float(j) / float(SEGMENTS)
			pts.append(Vector2(0.0, -span * u * (1.0 - 0.5 * curl * u)) + inw * span * curl * u * u * 0.9
				+ side * sin(u * 4.0 + clock * 2.3 + float(k)) * 3.0 * u)
		for pass_i in 2:
			var col := Color(VeilParts.VEIL, 0.5 * fade) if pass_i == 0 else Color(VeilParts.BLACK, 0.95 * fade)
			var grow_w := 1.5 if pass_i == 0 else 0.0
			for j in SEGMENTS:
				var a := pts[j]
				var b := pts[j + 1]
				var nrm := (b - a).normalized()
				nrm = Vector2(-nrm.y, nrm.x)
				var wa := lerpf(7.0, 1.0, float(j) / float(SEGMENTS)) + grow_w
				var wb := lerpf(7.0, 1.0, float(j + 1) / float(SEGMENTS)) + grow_w
				draw_primitive(PackedVector2Array([(a - nrm * wa).round(), (b - nrm * wb).round(), (b + nrm * wb).round(),
					(a + nrm * wa).round()]), PackedColorArray([col, col, col, col]), PackedVector2Array())
		if grow > 0.5:
			draw_rect(Rect2(pts[SEGMENTS].round(), Vector2.ONE), Color(VeilParts.SILVER, 0.8 * fade))


## Bare dark earth where the dark closed: a shallow scorched bowl on the ground (its shader), kept for the mission. A lasting
## effect node (SolarisPit.GROUP): Battlefield.clear_effects() frees it on a restart, so it never lies on a fresh town.
class BareEarth extends Node2D:
	const SHADER := preload("res://shaders/swallow_earth.gdshader")
	static var _white: ImageTexture
	var at := Vector2.ZERO
	var r := 0.0

	func _init() -> void:
		z_index = 1
		add_to_group(SolarisPit.GROUP)
		var mat := ShaderMaterial.new()
		mat.shader = SHADER
		mat.set_shader_parameter("dusk", VeilParts.DUSK)
		mat.set_shader_parameter("veil", VeilParts.VEIL)
		material = mat

	func _draw() -> void:
		if _white == null:
			var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
			img.fill(Color.WHITE)
			_white = ImageTexture.create_from_image(img)
		(material as ShaderMaterial).set_shader_parameter("seed", fposmod(at.x * 3.7 + at.y * 1.9, 50.0))
		var span := r * 1.06
		draw_texture_rect(_white, Rect2(at - Vector2(span, span), Vector2(span, span) * 2.0), false)
