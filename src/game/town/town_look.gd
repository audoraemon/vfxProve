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
	return Color.WHITE


## LightField.tint: what sprites and decor take as the world's light.
static func light_tint(look) -> Color:
	match look:
		Town.Look.DAY:
			# Early sun: warm, a little gold.
			return Color(1.06, 0.97, 0.86)
		Town.Look.NIGHT:
			# Moonlight: cool blue-grey.
			return Color(0.56, 0.66, 0.96)
	return Town.EVENING


## LightField.ambient: 1 is normal.
static func ambient(look) -> float:
	if look == Town.Look.NIGHT:
		return 0.72
	return 1.0
