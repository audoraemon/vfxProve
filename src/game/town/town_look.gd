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
		# Clean sunlight (round 2): the grass green and the stones grey, barely warm; the grade's tone split lights it.
		return Color(1.04, 1.0, 0.92)
	return Color.WHITE


## LightField.tint: what sprites and decor take as the world's light.
static func light_tint(look) -> Color:
	match look:
		Town.Look.DAY:
			# Clear sun, a little warm: no global orange (round 2), the warmth is in the lit faces (grade's tone split).
			return Color(1.06, 1.0, 0.90)
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
	return Color(0.14, 0.17, 0.38, 0.58)


## The contact shadows (TownShadows' contact group, dithered): a dark band at every building's base and under every
## tree, a little darker than the cast shadows; NIGHT's a deep blue.
static func contact_colour(look) -> Color:
	if look == Town.Look.NIGHT:
		return Color(0.02, 0.03, 0.10, 0.6)
	return Color(0.10, 0.06, 0.08, 0.72)


## DAY's soft tree shadows (TownShadows): a wide faint band, then a smaller core, each {scale, colour}; a dark green-slate
## with low alpha, so the two add up to about 0.3 in the core.
static func tree_shadow_bands(_look) -> Array[Dictionary]:
	return [{"scale": 1.0, "colour": Color(0.04, 0.15, 0.12, 0.20)}, {"scale": 0.6, "colour": Color(0.04, 0.15, 0.12, 0.20)}]


## The colour grade's uniforms for a look (TownGrade, town_grade.gdshader): lift (added), gain (multiplied), then warm
## highlights and cool darks split at `split` luminance over `spread`; keep_lit saves bright warm pixels (windows, flames)
## from the grade.
static func grade(look) -> Dictionary:
	if look == Town.Look.NIGHT:
		return {"lift": Vector3(0.0, 0.01, 0.04), "gain": Vector3(0.44, 0.48, 0.68),
			"warm": Vector3(1.10, 1.02, 0.95), "cool": Vector3(0.96, 1.0, 1.08), "split": 0.45, "spread": 0.3,
			"keep_lit": 0.85, "calm": 0.85}
	# DAY (round 2): clean colour, no global orange. A light warm/cool split, then the sun's tone split on lit content
	# (local_*: a face brighter than round it turns warm and brighter, a darker one cool and deeper), a saturation and a
	# contrast lift, and the shoulder so sunlit paving does not clip.
	return {"lift": Vector3(0.0, 0.0, 0.0), "gain": Vector3(1.02, 1.0, 0.98),
		"warm": Vector3(1.06, 1.02, 0.94), "cool": Vector3(0.92, 0.97, 1.08), "split": 0.42, "spread": 0.25,
		"keep_lit": 0.0, "calm": 0.0, "shoulder": 0.30, "knee": 0.50,
		"local_amt": 1.1, "local_lod": 3.0, "local_dead": 0.06, "local_warm": Vector3(1.08, 1.0, 0.86), "local_cool": Vector3(0.86, 0.94, 1.12),
		"saturation": 1.08, "contrast": 1.12, "pivot": 0.42}


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
	var out := {"vignette": 0.26, "haze": 0.45, "haze_sat": 0.85, "haze_col": Vector3(0.92, 0.89, 0.80), "haze_start": 3.0, "haze_end": city.border() + 10.0,
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


## The look's sprite-shader settings (SpriteView.look_params, structure_sprite.gdshader; round 3): NIGHT's windows burn
## with a hot core and a halo. Nothing in CURRENT.
static func sprite_params(look) -> Dictionary:
	if look == Town.Look.NIGHT:
		return {"window_hot": 0.9}
	return {}


## A window's pool on the ground in front (TownPools) against its round-2 strength: NIGHT's windows throw a brighter fan.
static func window_pool(look) -> float:
	return 1.7 if look == Town.Look.NIGHT else 1.0


## The light map (TownPools' buffer, multiplied in by TownGrade): how strongly it lights the art, and its warm colour. At
## NIGHT the lamps, torches and windows light what stands near them; by DAY they only warm their own doorsteps a touch.
static func light_gain(look) -> float:
	if look == Town.Look.NIGHT:
		return 3.0
	if look == Town.Look.DAY:
		return 0.15
	return 0.0


static func light_warm(look) -> Vector3:
	if look == Town.Look.NIGHT:
		# Deep lamp orange, as the reference's lit streets.
		return Vector3(1.0, 0.62, 0.30)
	return Vector3(1.0, 0.86, 0.66)


## How the light map's light meets the graded colour (town_grade.gdshader light_replace, light_mono, light_floor; round
## 3): NIGHT's lamplight replaces the cool moon grade where it falls and lights the luminance, so stone reads amber, not
## pink. DAY: none (the shader's defaults, off).
static func light_mix(look) -> Dictionary:
	if look == Town.Look.NIGHT:
		return {"light_replace": 0.8, "light_mono": 0.55, "light_floor": 0.16, "light_boost": 2.4,
			"light_knee": 0.62, "light_bend": 1.6, "light_pow": 2.0}
	return {}


## The glow (TownBloom, town_bloom.gdshader): the brightness a pixel blooms from, how warm it must be, the halo's strength
## and tint. NIGHT blooms from its flames and windows strongly; DAY lightly from its highlights.
static func bloom(look) -> Dictionary:
	if look == Town.Look.NIGHT:
		# Round 3: the threshold sits over the lamplit ground's brightest (the grade's light_knee), so only flames and
		# windows bloom and the pools never smear.
		return {"threshold": 0.9, "knee": 0.1, "warm_only": 1.0, "strength": 1.0, "tint": Vector3(1.0, 0.78, 0.5)}
	return {"threshold": 0.8, "knee": 0.15, "warm_only": 0.0, "use_lum": 1.0, "strength": 0.25, "tint": Vector3(1.0, 0.93, 0.80)}
