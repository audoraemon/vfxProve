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
		"keep_lit": 0.0, "calm": 0.0}
