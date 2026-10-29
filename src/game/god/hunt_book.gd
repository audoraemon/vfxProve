class_name HuntBook
extends RefCounted
## The five Lantern Hunts as data rows (god P5, mission spec MS §1, R1; plan Ruling P5-1). A Hunt is the Lantern's night: the god's Notice
## reached 100 and the Lantern sends its own mission, one per god tier, played once and never drawn by chance. The titles and plates are
## P2's, unchanged (open issue 9, controller ruling C9); each id is a MissionBook mission built on its tier's frame (MissionBook.hide_faithful()
## and on). All statics; nothing is written here (GodNight draws, builds and banks the Hunt, GodSlot holds the id while it is played).

## The Hunts, index = god tier - 1 (MS §1): `tier`, the MissionBook `id`, the Hunt's `title` and the Prepare `plate`.
const HUNTS := [
	{"tier": 1, "id": MissionBook.HIDE_FAITHFUL, "title": "Hide the faithful", "plate": "Lead your believers out before the inquisitors reach them"},
	{"tier": 2, "id": MissionBook.SILENCE_WITNESS, "title": "Silence the witness", "plate": "Stop the runner carrying word of you to the Lantern"},
	{"tier": 3, "id": MissionBook.EXPEL_INQUISITOR, "title": "Expel the inquisitor", "plate": "Drive out or kill the Lantern's captain in the town"},
	{"tier": 4, "id": MissionBook.BREAK_HUNT, "title": "Break the hunt", "plate": "Smash their standards before they reach your believers"},
	{"tier": 5, "id": MissionBook.FACE_HALCYON, "title": "Face Halcyon", "plate": "His Gaze is on the whole town, and a seen death fills it"},
]


## True when `id` is a Lantern Hunt's mission id.
static func has(id: String) -> bool:
	for h: Dictionary in HUNTS:
		if h.id == id:
			return true
	return false


## The row of Hunt `id` (a copy), or {} when there is none.
static func row(id: String) -> Dictionary:
	for h: Dictionary in HUNTS:
		if h.id == id:
			return h.duplicate()
	return {}


## The row of the Hunt a god of `tier` faces (a copy); a tier outside 1-5 is clamped to the nearest.
static func at_tier(tier: int) -> Dictionary:
	var row_at: Dictionary = HUNTS[clampi(tier, 1, HUNTS.size()) - 1]
	return row_at.duplicate()


## Every Hunt's mission id, in tier order.
static func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for h: Dictionary in HUNTS:
		out.append(String(h.id))
	return out


## The Hunt's mission def on its tier's frame (MissionBook), or null for an id that is not a Hunt (no error: a non-Hunt is an ordinary
## question here, as RiteBook.def). Like TierBook.board() it adds the Unaware tag where the town's readiness is Unaware (Tier 1); the god's
## slots, Might, pool, gifts and clock are GodNight's. It lists no Gaze of its own: Hunt 5's director keeps it (MS §6).
static func def(id: String) -> MissionDef:
	if not has(id):
		return null
	var m := TierBook.checked(MissionBook.get_mission(id), id)
	if m == null:
		return null
	if m.response_profile(ResponseProfile.DEFAULT).level() <= TierBook.UNAWARE_LEVEL and not m.mission_tags.has(TierBook.UNAWARE_TAG):
		m.mission_tags.append(TierBook.UNAWARE_TAG)
	return m
