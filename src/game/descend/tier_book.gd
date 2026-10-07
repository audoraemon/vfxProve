class_name TierBook
extends RefCounted
## The god's five Awakening Tiers on the board (v0.11 M1, spec §3-§4): each tier's name and missions, and what it sets --
## the town's readiness, the base slots and Divine Power, the clock, the wishes heard and the believers' multiplier -- and
## the unlocking rule's count. First guesses, tuned per milestone. board() builds a board mission from a ★ mission.

## The tiers' names, Tier 1 first (2-4 are placeholders the user may rename).
const NAMES := ["Whisper", "Omen", "Wrath", "Reckoning", "Ascendance"]
## The board's missions on each tier, by id: spec §8's ★ missions (M2-M6 add the rest).
const MISSIONS := [["warning"], ["miras_house", "broken_lanterns"], ["vigil_flame", "festival"], ["procession"],
	["last_judgement", "long_night"]]
## The town's readiness on each tier, as ResponseProfile.level(): Unaware, Organized, Prepared, God-Resistant twice.
const READINESS := [1, 2, 3, 4, 4]
## The base slots and Divine Power on each tier; the upgrades add to them.
const SLOTS := [3, 3, 4, 5, 6]
const DP := [6, 8, 10, 13, 16]
## The clock (dawn) on each tier, in seconds.
const CLOCKS := [300.0, 330.0, 360.0, 390.0, 420.0]
## The wishes heard at each tier's descent, and the believers' multiplier.
const WISHES := [2, 2, 3, 3, 3]
const MULTIPLIERS := [1.0, 1.5, 2.0, 2.5, 3.0]
## Cleared missions of a tier that open the next (spec §3.2), fewer while a tier has fewer missions (before M6).
const NEED := 3
## The most slots a loadout can have: the HUD's row and the keys 1-6.
const MAX_SLOTS := 6
## The tier from which every mission keeps Halcyon's Gaze (spec §4), and the share of GazeMeter.SEEN_DEATH a seen death adds
## there: Broken Lanterns' share, a first guess for nights that kill hundreds.
const GAZE_TIER := 5
const GAZE_SHARE := 0.05
## Each board mission's type on its card (spec §3.1, §8).
const TYPES := {"warning": "Intercept", "miras_house": "Cult", "broken_lanterns": "Anchors", "vigil_flame": "Cult",
	"festival": "Break", "procession": "Kill", "last_judgement": "Destroy", "long_night": "Three acts"}
## The tags a mission declares for the wishes to filter on (spec §5.1): a wish listing one of them is never drawn there.
const MISSION_TAGS := {"warning": ["unaware_town"], "miras_house": ["spares_houses"]}


## A tier's entry in `table`, tiers counted from 1 (outside 1-5, the nearest tier's).
static func _at(table: Array, tier: int) -> Variant:
	return table[clampi(tier, 1, table.size()) - 1]


static func tier_name(tier: int) -> String:
	return String(_at(NAMES, tier))


static func missions(tier: int) -> PackedStringArray:
	return PackedStringArray(_at(MISSIONS, tier))


static func readiness(tier: int) -> int:
	return int(_at(READINESS, tier))


static func slots(tier: int) -> int:
	return int(_at(SLOTS, tier))


static func dp(tier: int) -> int:
	return int(_at(DP, tier))


static func clock(tier: int) -> float:
	return float(_at(CLOCKS, tier))


static func wishes(tier: int) -> int:
	return int(_at(WISHES, tier))


static func multiplier(tier: int) -> float:
	return float(_at(MULTIPLIERS, tier))


## Cleared missions of `tier` that open the next: NEED, or all of them while the tier has fewer (spec §3.2).
static func need(tier: int) -> int:
	return mini(NEED, missions(tier).size())


## The tier the board mission `id` is on, or 0 when it is not on the board.
static func tier_of(id: String) -> int:
	for tier in range(1, NAMES.size() + 1):
		if missions(tier).has(id):
			return tier
	return 0


static func has(id: String) -> bool:
	return tier_of(id) > 0


## Every board mission, tier by tier.
static func all() -> PackedStringArray:
	var out := PackedStringArray()
	for tier in range(1, NAMES.size() + 1):
		out.append_array(missions(tier))
	return out


static func type_of(id: String) -> String:
	return String(TYPES.get(id, ""))


static func mission_tags(id: String) -> PackedStringArray:
	return PackedStringArray(MISSION_TAGS.get(id, []))


## Believers paid on `tier` for `base` (spec §4): times the tier's multiplier, rounded.
static func believers(base: int, tier: int) -> int:
	return roundi(float(base) * multiplier(tier))
