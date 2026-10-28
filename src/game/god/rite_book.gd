class_name RiteBook
extends RefCounted
## The Awaken rites and the gifts they steal, as data rows (god P3, mission spec MS §1 "data rows in a new RiteBook", §4; plan Ruling P3-1).
## A rite is a mission the god plays once at its level cap to cross into the next tier; winning it raises the tier, gives AWAKEN_POINTS and
## steals one gift that works on every later Endless night. P4 appends the rites for levels 20, 30 and 40. All statics; nothing is written
## here (GodNight banks the outcome, GodSlot holds the gifts).

## The first rite's mission id (MissionBook.FIRST_TASTE).
const FIRST_TASTE := "first_taste"
## The first stolen gift: the Lantern's bell takes longer to climb (MS §4).
const WATCHFUL_BELL := "watchful_bell"
## What the Watchful Bell multiplies a bell's climb time by (MS §4, R12; *tunable*): 20% longer.
const WATCHFUL_CLIMB := 1.2

## The rites, by the god level that opens them (a god at the cap of its tier plays the rite for that level). `shards` is what the director must
## bring, `victims` how many people are marked, `answer` the opposition that has the answer (the Temple's clergy), `gift` the gift id won,
## `plate` the Prepare briefing and `lose_line` how it is lost. P4 appends 20/30/40.
const RITES := [
	{"level": 10, "id": FIRST_TASTE, "name": "The First Taste", "shards": 3, "victims": 5, "answer": "clergy", "gift": WATCHFUL_BELL,
		"plate": "Halcyon's lamplighters keep his light in the streets. Drag three to Mira's shrine.",
		"lose_line": "The clergy cleanse the shrine, or dawn comes first."},
]

## The gifts a rite steals: the name the hub and results show, the effect line, what the plate says was stolen and the numbers it carries.
const GIFTS := {
	WATCHFUL_BELL: {"name": "The Watchful Bell", "effect": "The bell takes 20% longer to ring",
		"stolen": "a bell ringer takes 20% longer to start the toll", "climb": WATCHFUL_CLIMB},
}


## True when `id` is a rite's mission id.
static func has(id: String) -> bool:
	for r: Dictionary in RITES:
		if r.id == id:
			return true
	return false


## The row of rite `id` (a copy), or {} when there is none.
static func row(id: String) -> Dictionary:
	for r: Dictionary in RITES:
		if r.id == id:
			return r.duplicate()
	return {}


## The row of the rite a god at `level` plays, or {} when none is written for that level.
static func at_level(level: int) -> Dictionary:
	for r: Dictionary in RITES:
		if int(r.level) == level:
			return r.duplicate()
	return {}


## The rite's mission def (MissionBook.get_mission), or null for an id that is not a rite (no error: unlike TierBook.board, a non-rite is an
## ordinary question here).
static func def(id: String) -> MissionDef:
	if not has(id):
		return null
	return TierBook.checked(MissionBook.get_mission(id), id)


## The gift's name, "" for an unknown id.
static func gift_name(id: String) -> String:
	return String(GIFTS.get(id, {}).get("name", ""))


## The gift's effect line, "" for an unknown id.
static func gift_effect(id: String) -> String:
	return String(GIFTS.get(id, {}).get("effect", ""))


## The win plate's lines (MS §5): the tier crossed into, the points, and the gift stolen. Empty for a non-rite.
@warning_ignore("integer_division")
static func plate_lines(id: String) -> PackedStringArray:
	var r := row(id)
	if r.is_empty():
		return PackedStringArray()
	var next_tier: int = int(r.level) / GodSlot.LEVELS_PER_TIER + 1
	var gift: Dictionary = GIFTS.get(r.gift, {})
	return PackedStringArray(["AWAKENED - %s" % TierBook.tier_name(next_tier).to_upper(), "+%d ability points" % GodSlot.AWAKEN_POINTS,
		"Stolen: %s - %s" % [gift.get("name", ""), gift.get("stolen", "")]])


## The product of the known gifts' climb scales: what Crowd.climb_scale becomes on a night (MS §4). Exactly 1.0 for no gifts or unknown ids.
static func climb_scale(gifts: PackedStringArray) -> float:
	var scale := 1.0
	for g in gifts:
		if GIFTS.has(g) and GIFTS[g].has("climb"):
			scale *= float(GIFTS[g].climb)
	return scale
