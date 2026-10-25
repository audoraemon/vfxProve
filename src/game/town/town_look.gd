class_name TownLook
extends RefCounted
## The town's lighting looks and their constants (Town.Look: CURRENT, DAY, NIGHT). CURRENT is the game as it is; DAY and
## NIGHT are the lighting proof: they bake the ground neutral and let the look's nodes (shadows, grade, pools, mist)
## supply the colour. `look` below is an untyped Town.Look value (typing it would make Town and TownLook depend on each
## other).

## The look of the town being built, set by Town.build() and put back by Town.teardown(), for the static helpers that
## have no town in hand (TownDecor._bake_low()).
static var active = 0

## Every node a non-CURRENT look adds joins this group.
const GROUP := &"town_look"


## The ground (floor, plants, forest) is baked and modulated by this: today's gold in CURRENT, neutral otherwise.
static func ground_tint(look) -> Color:
	if look == Town.Look.CURRENT:
		return Town.GROUND_EVENING
	if look == Town.Look.DAY:
		# Low golden sun on the grass and the stones, a touch more than CURRENT's evening.
		return Color(1.10, 0.95, 0.70)
	return Color.WHITE


## LightField.tint: what sprites and decor take as the world's light.
static func light_tint(look) -> Color:
	match look:
		Town.Look.DAY:
			# Early sun: warm, a little gold.
			return Color(1.08, 0.98, 0.80)
		Town.Look.NIGHT:
			# Moonlight: cool blue-grey.
			return Color(0.80, 0.88, 1.0)
	return Town.EVENING


## LightField.ambient: 1 is normal.
static func ambient(look) -> float:
	if look == Town.Look.NIGHT:
		return 0.86
	return 1.0


## The darkness of the cast-shadow group (TownShadows): a cool slate at dawn, fainter and darker at night. People's foot
## shadows take it too (Person._draw_shadow).
static func shadow_colour(look) -> Color:
	if look == Town.Look.NIGHT:
		return Color(0.03, 0.05, 0.16, 0.30)
	return Color(0.20, 0.22, 0.40, 0.50)


## DAY's soft tree shadows (TownShadows): a wide faint band, then a smaller core, each {scale, colour}; a dark green-slate
## with low alpha, so the two add up to about 0.3 in the core.
static func tree_shadow_bands(_look) -> Array[Dictionary]:
	return [{"scale": 1.0, "colour": Color(0.04, 0.15, 0.12, 0.20)}, {"scale": 0.6, "colour": Color(0.04, 0.15, 0.12, 0.20)}]


## The colour grade's uniforms for a look (TownGrade, town_grade.gdshader): lift (added), gain (multiplied), then warm
## highlights and cool darks split at `split` luminance over `spread`; keep_lit saves bright warm pixels (windows, flames)
## from the grade.
static func grade(look) -> Dictionary:
	if look == Town.Look.NIGHT:
		return {"lift": Vector3(0.0, 0.01, 0.04), "gain": Vector3(0.50, 0.60, 0.84),
			"warm": Vector3(1.10, 1.02, 0.95), "cool": Vector3(0.90, 1.0, 1.18), "split": 0.45, "spread": 0.3,
			"keep_lit": 0.85, "calm": 0.85}
	return {"lift": Vector3(0.0, 0.0, 0.01), "gain": Vector3(1.02, 0.99, 0.92),
		"warm": Vector3(1.14, 1.03, 0.80), "cool": Vector3(0.92, 0.98, 1.06), "split": 0.40, "spread": 0.28,
		"keep_lit": 0.0, "calm": 0.0, "shoulder": 0.28, "knee": 0.45}


## The atmosphere of a look over the active city (TownGrade's uniforms, town_grade.gdshader atmosphere()): DAY's haze
## toward the map's edges, its sunbeams outside the walls (the same stripes as TownMist's in the town, beam_stripe()),
## a sun glow in the screen's top left, and a vignette (NIGHT's a little stronger, and nothing else).
static func atmosphere(look) -> Dictionary:
	if look == Town.Look.NIGHT:
		return {"vignette": 0.42}
	if look != Town.Look.DAY:
		return {}
	var city := City.current()
	var keeps := TownMist.keep_outs()
	var out := {"vignette": 0.32, "haze": 0.55, "haze_start": 3.0, "haze_end": city.border() + 10.0,
		"beam": 0.75, "beam_origin": beam_origin(), "beam_slant": BEAM_SLANT, "beam_period": BEAM_PERIOD,
		"beam_width": BEAM_WIDTH, "beam_keep": _rect4(city.town().grow(BEAM_PAD)), "sun": 0.75, "sun_at": Vector2(0.02, 0.0),
		"sun_radius": 0.5}
	for i in mini(keeps.size(), 2):
		out["keep_out" if i == 0 else "keep_out2"] = _rect4(keeps[i])
	return out


static func _rect4(r: Rect2) -> Vector4:
	return Vector4(r.position.x, r.position.y, r.size.x, r.size.y)


## The sunbeams' layout (world px), shared by the grade (outside the walls) and TownMist (the town's ground plane):
## stripes slanting BEAM_SLANT px right per px down, one every BEAM_PERIOD px across, each about BEAM_WIDTH px half-wide.
## The grade's beams keep BEAM_PAD ground units off the town rect.
const BEAM_SLANT := 0.55
const BEAM_PERIOD := 260.0
const BEAM_WIDTH := 70.0
const BEAM_PAD := 2.5


## Where the beams are laid out from: the active town's centre (world px).
static func beam_origin() -> Vector2:
	return Iso.ground_to_screen(City.current().town().get_center())


## Stripe n's centre (px across the beams from the origin's line, beam_u()) and half-width, as the shader lays it out.
static func beam_stripe(n: int) -> Vector2:
	var hk := fposmod(n * 0.6180340 + 0.31, 1.0)
	var hw := BEAM_WIDTH * (0.6 + 0.8 * fposmod((n + 3.0) * 0.6180340 + 0.31, 1.0))
	return Vector2(n * BEAM_PERIOD + (hk - 0.5) * BEAM_PERIOD * 0.3, hw)


## A point's place across the beams (world px), as the shader measures it.
static func beam_u(p: Vector2, origin: Vector2) -> float:
	return p.x - origin.x - (p.y - origin.y) * BEAM_SLANT


## Lit windows (SpriteView.window_boost): how far a window of a building's glow mask is pushed toward a hot lamp colour.
## NIGHT lights every one; DAY only faintly, as at dusk.
static func window_boost(look) -> float:
	if look == Town.Look.NIGHT:
		return 1.0
	if look == Town.Look.DAY:
		return 0.25
	return 0.0


## The light map (TownPools' buffer, multiplied in by TownGrade): how strongly it lights the art, and its warm colour. At
## NIGHT the lamps, torches and windows light what stands near them; by DAY they only warm their own doorsteps a touch.
static func light_gain(look) -> float:
	if look == Town.Look.NIGHT:
		return 1.6
	if look == Town.Look.DAY:
		return 0.15
	return 0.0


static func light_warm(_look) -> Vector3:
	return Vector3(1.0, 0.86, 0.66)


## The glow (TownBloom, town_bloom.gdshader): the brightness a pixel blooms from, how warm it must be, the halo's strength
## and tint. NIGHT blooms from its flames and windows strongly; DAY lightly from its highlights.
static func bloom(look) -> Dictionary:
	if look == Town.Look.NIGHT:
		return {"threshold": 0.7, "knee": 0.25, "warm_only": 1.0, "strength": 0.8, "tint": Vector3(1.0, 0.78, 0.5)}
	return {"threshold": 0.8, "knee": 0.15, "warm_only": 0.0, "use_lum": 1.0, "strength": 0.3, "tint": Vector3(1.0, 0.88, 0.66)}
