class_name TheSwallowingDarkFx
extends FxTimeline
## The Swallowing Dark (Veil, Tier V; spec 5.9): a black circle opens at the click and grows from its centre at GROW a second, from 0
## to its light FULL_R (VeilRules: 10), or, cast in the dark, from the radius of the dusk patch it was cast in (Dusk.r_at()) to its dark
## FULL_R (14). Nobody sees it grow: it registers no danger, frightens nobody, raises no alarm; one who walks out in time lives. At full
## size everything inside is gone without a sound: every person (Crowd.take(p, &"void"): no body, no voice, no remain), every animal
## and visitor, every lying remain, every decor piece whose `at` is inside, and every building whose footprint lies wholly inside
## (wholly_inside()) by Eminent Domain's quiet path (EnvironmentField.remove(s, true, true): the walk grid opens, no rubble), together
## with whoever shelters in it. Spared: a building MissionKeeps.spared() names (the Citadel and Temple, the hallowed, the mission's own)
## and the town's own gates, bridges, postern, dock and fountain, which its managers go on using (as Eminent Domain keeps them). A
## blighted foothold that goes is healed first (BlightFx.heal()), so no foothold points at a removed building. The removals are spread
## over frames, PER_FRAME at most each (BUILDINGS_PER_FRAME of them buildings), outermost first (an inward fold). The emptied ground is dusk for VeilRules.DUSK_TIME and
## stays bare dark earth (a ground mark left for the mission). Nothing of it is remembered: no incident, no search, no count.
## With no crowd (the VFX Sandbox) it grows at the light size and takes the town's buildings and decor only.

## Growth in ground units a second.
const GROW := 0.5
## At most this many removals in one frame.
const PER_FRAME := 12
## Of which at most this many buildings: each EnvironmentField.remove() rebuilds the field's whole spatial index (about 10 ms on a
## loaded machine), so two a frame keep the worst frame of the fold near the bench's aim (under 50 ms).
const BUILDINGS_PER_FRAME := 2
## The circle has opened (the rim drawn) this long after the cast: the other slots unlock then (ruling C16).
const T_OPEN := 0.5
## The fold's drawing after full size.
const FOLD := 0.6
## The silent kill kind (Crowd.SILENT_KINDS).
const KIND := &"void"

## This cast's sizes: where it starts, where it ends, and when it gets there.
var start_r := 0.0
var full_r := 10.0
var t_full := 20.0
## Whether full size has been reached (the removals begun).
var swallowed := false
## How many things it has taken so far (people, animals, remains, decor, buildings).
var removed := 0
## The removals still to make: [kind, thing, structure or pack].
var _queue: Array = []
## The buildings the dark takes (fixed at full size): a person sheltering is taken only with one of these.
var _gone := {}
var _disc: SwallowDisc


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
	full_r = VeilParts.size(self, "swallow", "FULL_R")
	if VeilParts.dark(self) and ctx.crowd != null and ctx.crowd.dusk != null:
		start_r = minf(ctx.crowd.dusk.r_at(origin), full_r)
	t_full = (full_r - start_r) / GROW
	busy = T_OPEN
	duration = t_full + FOLD
	at(t_full, _swallow)
	ctx.play(&"v_swallow", origin)
	if ctx.ground != null:
		_disc = SwallowDisc.new()
		_disc.at = origin
		_disc.r = start_r
		track(_disc, ctx.ground)


## The circle's radius now.
func radius() -> float:
	return minf(start_r + GROW * t, full_r)


## How many removals are still to make.
func left() -> int:
	return _queue.size()


func _fx_process(_delta: float) -> void:
	if is_instance_valid(_disc):
		_disc.r = radius()
		_disc.open = clampf(t / T_OPEN, 0.0, 1.0)
		_disc.fold = clampf((t - t_full) / FOLD, 0.0, 1.0) if swallowed else 0.0
		_disc.queue_redraw()
	if not swallowed:
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


## Full size: what is inside is fixed now and taken over the next frames; the ground is left dusk and bare.
func _swallow() -> void:
	swallowed = true
	_queue = _inside()
	VeilParts.land(self, origin, full_r)
	ctx.play(&"v_swallow_take", origin)
	if ctx.ground != null:
		var mark := BareEarth.new()
		mark.at = origin
		mark.r = full_r
		ctx.ground.add_child(mark)  # not tracked: the bare earth stays for the mission


## Everything to take, outermost first (then by instance id): no rng decides it.
func _inside() -> Array:
	var r := full_r
	var crowd: Crowd = ctx.crowd
	var groups: Array = []  # [distance, id, entries]
	# Buildings wholly inside, minus the spared.
	var keep: Array = []
	var town: Town = crowd._town if crowd != null else null
	if is_instance_valid(town):
		keep.append_array(town.gates)
		keep.append_array(town.bridges)
		keep.append_array([town.bridge, town.postern, town.dock, town.fountain])
	var director: MissionDirector = ctx.rules.director if ctx.rules != null else null
	var gone := {}
	if ctx.env != null:
		for s in ctx.env.structures():
			if not is_instance_valid(s) or s.taken or keep.has(s) or not wholly_inside(s, origin, r):
				continue
			if MissionKeeps.spared(s, crowd, director):
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
				crowd.shelters.release(p)
			elif p.ground_pos.distance_to(origin) > full_r:
				return
			if crowd.take(p, KIND):
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
					crowd.shelters.release(p)
					crowd.take(p, KIND)
			crowd.shelters.shelters.erase(s)
	ctx.env.remove(s, true, true)
	removed += 1


## The growing circle: a flat black disc with a thin silver rim, drawn on the ground over its art (ground units: ctx.ground is
## Iso.BASIS). At full size the rim folds inward and the disc fades onto the bare earth left beneath.
class SwallowDisc extends Node2D:
	var at := Vector2.ZERO
	var r := 0.0
	var open := 0.0
	var fold := 0.0

	func _init() -> void:
		z_index = 2

	func _draw() -> void:
		if r <= 0.0:
			return
		var a := open * (1.0 - fold)
		draw_circle(at, r, Color(VeilParts.BLACK, 0.96 * a))
		draw_arc(at, r, 0.0, TAU, 64, Color(VeilParts.SILVER, 0.85 * a), 0.06)
		if fold > 0.0:
			# The soundless fold: the rim draws in to the middle.
			draw_arc(at, r * (1.0 - fold), 0.0, TAU, 64, Color(VeilParts.SILVER, 0.9 * (1.0 - fold)), 0.08)


## Bare dark earth where the dark closed: one flat disc on the ground, kept for the mission.
class BareEarth extends Node2D:
	var at := Vector2.ZERO
	var r := 0.0

	func _init() -> void:
		z_index = 1

	func _draw() -> void:
		draw_circle(at, r, Color("1a1410", 0.92))
		draw_circle(at, r * 0.97, Color("120d0b", 0.5))
