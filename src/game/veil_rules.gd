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


## A Veil power's number for `stat`, its light or its dark size (SIZES); 0.0 for a key or stat SIZES does not name.
static func size(key: String, stat: String, dark: bool) -> float:
	var stats: Dictionary = SIZES.get(key, {})
	var pair: Array = stats.get(stat, [])
	if pair.size() < 2:
		return 0.0
	return float(pair[1] if dark else pair[0])
