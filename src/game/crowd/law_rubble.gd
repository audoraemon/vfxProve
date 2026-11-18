class_name LawRubble
extends RefCounted
## Law rubble (spec §4.3): what a Decree power leaves on the ground (Erasing Distance, Eminent Domain). A blocking pile of
## role `decree`: the walk grid closes its cells when it is laid (WalkGrid on structure_added), the town's engineers
## clear it as they clear a Windfall's stones (EngineerManager.CLEARABLE), and like any power's pile its fall is no
## incident (Crowd) and no demon claws at it (Visitors).
##
## One rubble look (Decree review R3): every pile is a heap of fallen structure. With the sprites on (SpriteArt) it wears
## the ruins still of a building set, fitted to its footprint (SpriteArt.set_for): the ruins of the building it came from
## when lay() is given one, else one of SETS picked by the hash of where it lies -- never a roll, so the same pile always
## looks the same. With the sprites off it is a heap of jagged stones and a couple of broken beams (heap_parts(),
## Structure draws it), never a crate box. A short dust puff rises as it is laid (look only).

const ROLE := &"decree"
## The small buildings whose ruins a pile wears when it came from no building of its own (or from one with no ruins art):
## cottage- and townhouse-sized sets whose ruins still is a heap, not a cleared plot. A missing set is skipped.
const SETS: Array[String] = ["cottage_red", "cottage_blue", "townhouse_a", "townhouse_b", "gpt_jail", "gpt_treasury",
	"gpt_granary"]
## ArtKit.hash01 salts: the set a pile wears, and whether it is drawn mirrored.
const SALT_SET := 97
const SALT_MIRROR := 98
## The ruins are drawn at the pile's footprint over the set's (summed sides), within these bounds.
const FIT_MIN := 0.5
const FIT_MAX := 1.4
## The dust puff: how many motes, per unit of the pile's longer side.
const DUST := 10


## Lays a pile `h` tall on `rect`; returns it. `from`: the building it came from (Erasing Distance's fold, Eminent
## Domain's tear), whose own ruins art it then wears; null for a generic heap.
static func lay(env: EnvironmentField, rect: Rect2, h: float, from: Structure = null) -> Structure:
	var s := env.add_structure(rect, h, Structure.Kind.CRATES, ROLE, art_tag_from(from))
	_puff(s)
	return s


## The tag a pile from `from` carries: the name of `from`'s sprite set when it has one with a ruins still (a strip, the
## town wall, cuts its art per piece and has none to lend), else &"" (a generic heap, art_name() picks by position). Read
## from the building's kind, role and tag (SpriteArt.name_for), so it is the same whether sprites are on or off now.
static func art_tag_from(from: Structure) -> StringName:
	if from == null or not is_instance_valid(from):
		return &""
	var n := SpriteArt.name_for(from)
	if n == "":
		return &""
	var m: Dictionary = SpriteArt.manifest().get(n, {})
	if m.is_empty() or bool(m.get("strip", false)):
		return &""
	return StringName(n)


## The sprite set pile `s` wears (SpriteArt.name_for): the set it is tagged with, else one of SETS by its position's
## hash; "" when none of them is in the manifest.
static func art_name(s: Structure) -> String:
	var tag := String(s.art_tag)
	if tag != "" and SpriteArt.manifest().has(tag):
		return tag
	var have: Array[String] = []
	for n in SETS:
		if SpriteArt.manifest().has(n):
			have.append(n)
	if have.is_empty():
		return ""
	return have[ArtKit.pick(spot_hash(s.footprint), SALT_SET, have.size())]


## A pile's own hash, from where it lies (never its rng: a pile's rng stream is the field's, and stays untouched).
static func spot_hash(rect: Rect2) -> int:
	return (int(roundf(rect.position.x * 64.0)) * 73856093) ^ (int(roundf(rect.position.y * 64.0)) * 19349663) \
		^ (int(roundf(rect.size.x * 64.0)) * 83492791)


## Whether pile `rect` draws its ruins mirrored (by its hash), so a row of heaps of one set does not look stamped.
static func mirrored(rect: Rect2) -> bool:
	return ArtKit.hash01(spot_hash(rect), SALT_MIRROR) < 0.5


## The scale the ruins of a set with footprint `fp` are drawn at on pile footprint `rect`: their sides summed (an iso
## picture's width), clamped to FIT_MIN..FIT_MAX.
static func fit(fp: Vector2, rect: Rect2) -> float:
	var own := fp.x + fp.y
	if own <= 0.0:
		return 1.0
	return clampf((rect.size.x + rect.size.y) / own, FIT_MIN, FIT_MAX)


## The procedural heap (sprites off), in the pile's own space (its front corner at the origin): [stones, beams, base].
## Base: the heap's dark jagged foot over its footprint. Stones: [polygon, shade 0..2 (top, right, left face)], back to
## front, rising toward the middle (a mound, not a carpet). Beams: [quad, shade], two broken timbers across the top. All
## from the pile's hash, so it is the same heap every time it is drawn.
static func heap_parts(rect: Rect2, h: float) -> Array:
	var seed_value := spot_hash(rect)
	var front := Iso.ground_to_screen(rect.end)
	var centre := Iso.ground_to_screen(rect.get_center()) - front
	var base := PackedVector2Array()
	for k in 10:
		var ang := TAU * float(k) / 10.0
		var r := 0.42 + 0.12 * ArtKit.hash01(seed_value, 100 + k)
		base.append(Iso.ground_to_screen(rect.get_center() + Vector2(cos(ang), sin(ang)) * rect.size * r) - front)
	var stones: Array = []
	var count := int(clampf(rect.get_area() * 28.0, 14.0, 28.0))
	for i in count:
		var u := 0.1 + 0.8 * ArtKit.hash01(seed_value, 200 + i * 3)
		var v := 0.1 + 0.8 * ArtKit.hash01(seed_value, 201 + i * 3)
		var g := rect.position + Vector2(u, v) * rect.size
		var mid := 1.0 - 2.0 * maxf(absf(u - 0.5), absf(v - 0.5))
		var lift := h * (0.1 + 0.9 * sqrt(maxf(mid, 0.0))) * (0.7 + 0.3 * ArtKit.hash01(seed_value, 202 + i * 3))
		var ground := Iso.ground_to_screen(g) - front
		var c := ground + Vector2(0.0, -lift)
		var size := 3.0 + 3.5 * ArtKit.hash01(seed_value, 400 + i)
		var poly := PackedVector2Array()
		for k in 5:
			var ang := TAU * float(k) / 5.0 + 0.6 * ArtKit.hash01(seed_value, 500 + i * 5 + k)
			var r := size * (0.6 + 0.4 * ArtKit.hash01(seed_value, 600 + i * 5 + k))
			poly.append(c + Vector2(cos(ang), sin(ang) * 0.7) * r)
		stones.append([poly, ArtKit.pick(seed_value, 700 + i, 3), ground.y])
	# Back to front by where each lies on the ground, so nearer stones overlap the far ones.
	stones.sort_custom(func(a: Array, b: Array) -> bool: return float(a[2]) < float(b[2]))
	var beams: Array = []
	for j in 2:
		var a := (0.15 + 0.7 * ArtKit.hash01(seed_value, 800 + j)) * PI
		var span := 14.0 + 8.0 * ArtKit.hash01(seed_value, 810 + j)
		var at := centre + Vector2((float(j) - 0.5) * 8.0, -h * (0.7 + 0.25 * float(j)))
		var d := Vector2(cos(a), sin(a) * 0.5) * span * 0.5
		var n := Vector2(-d.y, d.x).normalized() * 1.5
		beams.append([PackedVector2Array([at - d - n, at + d - n, at + d + n, at - d + n]), j])
	return [stones.map(func(st: Array) -> Array: return [st[0], st[1]]), beams, base]


## The dust a pile throws up as it lands (look only): on the field's back layer, seeded by the pile's hash, never its rng.
static func _puff(s: Structure) -> void:
	if s.fx_back == null:
		return
	var p := PixelParticles.new()
	p.rng.seed = spot_hash(s.footprint)
	p.shape = PixelParticles.Shape.PUFF
	p.ramp = PackedColorArray(FxParts.DUST_LIFE)
	p.position = s.position
	p.drag = 1.4
	s.fx_back.add_child(p)
	var side := maxf(s.footprint.size.x, s.footprint.size.y)
	p.burst(int(DUST * maxf(side, 0.5)), {
		"radius": side * FxParts.PX_PER_UNIT_MAJOR * 0.6, "dir": PixelParticles.Dir.OUTWARD, "speed": Vector2(15, 50),
		"alt": Vector2(0, maxf(s.height * 0.4, 4.0)), "alt_speed": Vector2(4, 18), "life": Vector2(0.6, 1.2),
		"size": Vector2(3, 7), "size_end_mul": 1.5,
	})
