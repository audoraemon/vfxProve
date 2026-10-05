class_name CampaignState
extends RefCounted
## Where a Lantern campaign stands (v0.10, spec §3): the night to play next, the Divine Power the god has regained,
## Halcyon's bites, the path tally, and Night 1's bell. record() takes each night's result and moves the campaign on.

## The night to play next, from 0 (Night 1).
var night := 0
## The loadout budget the god has regained.
var dp := CampaignDef.START_DP
var bites := 0
## Path -> the path nights played on it, won or lost.
var tally := {"faith": 0, "theft": 0, "ruin": 0}
## The path of the most recent path night ("" before Night 2): a tie goes to it.
var last_path := ""
## Night 1's bell rang: Night 3's act starts in a warned town.
var bell_rang := false
var nights_won := 0
## "" while the campaign runs, else the ending it reached (CampaignDef.ENDINGS).
var ending := ""


func slots() -> int:
	return int(CampaignDef.night(night).slots)


## The missions tonight offers, [{mission, path}]: one, or a choice card.
func options() -> Array:
	return CampaignDef.night(night).options


## The strongest path, a tie going to the most recent path night; "" before any path night.
func path() -> String:
	var best := ""
	var most := 0
	for p in CampaignDef.PATHS:
		var n := int(tally.get(p, 0))
		if n > most or (n == most and n > 0 and p == last_path):
			best = p
			most = n
	return best


func title() -> String:
	return String(CampaignText.TITLES.get(path(), CampaignText.TITLES[""]))


## The memory fragment the ending opens with: The Vision before the Faith and Theft endings (on the Ruin path it was
## shown before Night 4), none before Eaten.
func ending_fragment() -> String:
	return "vision" if ending == CampaignDef.NEW_FAITH or ending == CampaignDef.FALSE_LANTERN else ""


## A mission tonight offers, ready for Prepare: a fresh def with the night's slots and the god's budget. A night's
## first act carries Night 1's bell, so the Feast's Prepare shows the town the act will meet.
func mission(id: String) -> MissionDef:
	var def := MissionBook.get_mission(id)
	def.slots = slots()
	def.dp_capacity = dp
	if def.has_acts():
		var n := NightState.new()
		n.bell_rang = bell_rang
		def.first_act().night = n
	return def


## Take tonight's result (Rules.result(), or NightState.result() for a Feast) for the mission played, and move on (spec
## §3): a path night counts for its path; a win adds DP and its bonus one more; a loss is a bite. Returns what changed,
## for the results: {won, dp_gain, bite, dp, bites, ending, path}.
func record(mission_id: String, result: Dictionary) -> Dictionary:
	var won := bool(result.get("won", false))
	var p := CampaignDef.path_of(night, mission_id)
	if p != "":
		tally[p] = int(tally.get(p, 0)) + 1
		last_path = p
	if night == 0:
		bell_rang = String(result.get("reason", "")) == "bell"
	var gain := 0
	if won:
		gain = CampaignDef.WIN_DP + (CampaignDef.BONUS_DP if _bonus_earned(result) else 0)
		dp += gain
		nights_won += 1
	else:
		bites += 1
		dp = maxi(CampaignDef.MIN_DP, dp - CampaignDef.BITE_DP)
	_advance(won)
	return {"won": won, "dp_gain": gain, "bite": not won, "dp": dp, "bites": bites, "ending": ending, "path": p}


## On to the next night, or to an ending: the third bite ends it; a won finale is the Kataclysm and a lost one is played
## again; after Night 3 the Faith and Theft paths reach their endings and the Ruin path goes on to the finale.
func _advance(won: bool) -> void:
	if bites >= CampaignDef.MAX_BITES:
		ending = CampaignDef.EATEN
		return
	if night == CampaignDef.FINALE:
		if won:
			ending = CampaignDef.KATACLYSM
		return
	var p := path()
	if night == CampaignDef.FINALE - 1 and p != "" and p != CampaignDef.RUIN:
		ending = CampaignDef.ending_for(p)
		return
	night += 1


## At most one bonus counts toward DP a night (spec §3.1).
static func _bonus_earned(result: Dictionary) -> bool:
	for b in result.get("bonuses", []):
		if bool((b as Dictionary).get("earned", false)):
			return true
	return false
