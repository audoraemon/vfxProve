class_name VeilRules
extends RefCounted
## The law of the Veil (Veil authority powers spec §4): every Veil power is small when cast in the light and full size when cast in
## the dark (Crowd.in_dark(): a dusk patch, Unseen Hour's veil, a NIGHT mission, Evernight). Which size a cast gets is decided once,
## at the cast, from the ground under the click (Rules.cast() stamps extra["dark"]). Every Veil cast leaves a dusk patch where it
## lands (DUSK_R, or the power's own area when larger, for DUSK_TIME). Every number of the law lives here, as NightRules holds the
## night's.

## A dusk patch's least radius and how long it lasts.
const DUSK_R := 3.0
const DUSK_TIME := 20.0
## The same two by the casting power's level 1-5 (Veil ability levels spec 5.1); level 1 is DUSK_R and DUSK_TIME.
const DUSK_RS := [3.0, 3.25, 3.5, 3.75, 4.0]
const DUSK_TIMES := [20.0, 22.0, 24.0, 26.0, 28.0]
## At most this many blighted buildings hold lasting dusk at once (Blight's footholds).
const BLIGHT_MAX := 3
## key -> stat -> [light, dark]
const SIZES := {
	"doom": {"RADIUS": [0.8, 1.6]},
	"blight": {"DUSK_R": [3.0, 5.0], "ILL_MOST": [1, 3]},
	"slumber": {"RADIUS": [1.5, 3.5]},
	"cloak": {"MARK_R": [2.0, 4.0], "MOST": [3, 8]},
	"unseen": {"RADIUS": [5.0, 7.0], "VEIL_TIME": [20.0, 30.0]},
	"dreamless": {"REACH": [1.0, 2.0], "MOST": [1, 4]},
	"dread": {"REACH": [6.0, 12.0]},
	"shadowplay": {"RADIUS": [3.0, 6.0]},
	"swallow": {"FULL_R": [10.0, 14.0]},
	"evernight": {"NIGHT_TIME": [60.0, 90.0], "TAKE_EVERY": [2.0, 1.5]},
}
## The stat the aim ring shows, per key ("" = no ring change).
const RING := {"doom": "RADIUS", "slumber": "RADIUS", "cloak": "MARK_R", "unseen": "RADIUS", "dreamless": "REACH",
	"dread": "REACH", "shadowplay": "RADIUS", "swallow": "FULL_R"}


## True when the loadout carries a power whose PowerBook authority is "veil": only then does the dusk ledger run.
static func wants(loadout: PackedStringArray) -> bool:
	for k in loadout:
		if PowerBook.authority_of(String(k)) == "veil":
			return true
	return false


## The dusk patch's least radius at `level` (clamped 1-5).
static func dusk_r(level := 1) -> float:
	return float(DUSK_RS[clampi(level, 1, DUSK_RS.size()) - 1])


## How long a dusk patch lasts at `level` (clamped 1-5).
static func dusk_time(level := 1) -> float:
	return float(DUSK_TIMES[clampi(level, 1, DUSK_TIMES.size()) - 1])


## A Veil power's [light, dark] pair for `stat` at `level`: its levels table's, else SIZES' (a stat the table does not name, as
## Evernight's TAKE_EVERY); [] for a key or stat neither names.
static func pair(key: String, stat: String, level := 1) -> Array:
	var from_table: Variant = PowerBook.level_stat(key, level, stat, null)
	if from_table is Array and (from_table as Array).size() >= 2:
		return from_table
	var stats: Dictionary = SIZES.get(key, {})
	var base: Array = stats.get(stat, [])
	return base if base.size() >= 2 else []


## A Veil power's number for `stat` at `level`, its light or its dark size; 0.0 for a key or stat nothing names.
static func size(key: String, stat: String, dark: bool, level := 1) -> float:
	var both := pair(key, stat, level)
	if both.size() < 2:
		return 0.0
	return float(both[1] if dark else both[0])


## The tree's extra row for a Veil power at `level`: the dusk it leaves, `{"label", "old", "new"}`; {} below level 2, for Evernight
## (it lays none) and for a key that is not a Veil power.
static func dusk_row(key: String, level: int) -> Dictionary:
	if level < 2 or key == "evernight" or not SIZES.has(key):
		return {}
	var lv := mini(level, DUSK_RS.size())
	return {"label": "dusk", "old": _dusk_text(lv - 1), "new": _dusk_text(lv)}


static func _dusk_text(level: int) -> String:
	return "%s for %d s" % [str(dusk_r(level)), int(dusk_time(level))]
