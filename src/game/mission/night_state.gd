class_name NightState
extends RefCounted
## What carries between the acts of a night (v0.09): each act's result, the path chosen after Act I, and the outcomes
## that shape the next town (the bell rang; the festival broke or held; the Prince died unseen, seen, or escaped).

## Points for each act won and each bonus earned, on top of the last act's score (the night's rank).
const ACT_POINTS := 2000
const BONUS_POINTS := 500
## Act III's escape limit when the Prince escaped: the kingdom rallied.
const PRINCE_ESCAPED_LIMIT := 40
## Score floors for the night's rank, best first; under the last one is a D. Starting values, tuned in Task 19.
const NIGHT_RANKS := [[20000, "S"], [15000, "A"], [10000, "B"], [5000, "C"]]

## One dictionary per act played: its Rules.result() plus "act" (the act's id).
var results: Array[Dictionary] = []
## The path chosen on the choice card: "festival" or "procession" ("" before the choice).
var path := ""
var bell_rang := false
## "broken" or "held" once the Festival is over.
var festival := ""
## "unseen", "seen" or "escaped" once the Procession is over.
var prince := ""
## The festival-goers who broke and still live when the Festival ends (Act III sends them fleeing).
var festival_broke: Array[Person] = []


## Keep an act's result and read what it changed. A town whose bell has rung stays warned.
func record(act_id: String, result: Dictionary, crowd: Crowd) -> void:
	var r := result.duplicate(true)
	r["act"] = act_id
	results.append(r)
	if crowd != null and (crowd.alarms.bell_rung or (crowd.bell != null and crowd.bell.state == BellNetwork.State.RUNG)):
		bell_rang = true
	if result.has("festival"):
		festival = String(result.festival)
	if result.has("prince"):
		prince = String(result.prince)


func act_result(id: String) -> Dictionary:
	for r in results:
		if String(r.get("act", "")) == id:
			return r
	return {}


func acts_won() -> int:
	var n := 0
	for r in results:
		n += 1 if bool(r.get("won", false)) else 0
	return n


func bonuses_earned() -> int:
	var n := 0
	for r in results:
		for b in r.get("bonuses", []):
			n += 1 if bool((b as Dictionary).get("earned", false)) else 0
	return n


func escape_limit() -> int:
	return PRINCE_ESCAPED_LIMIT if prince == "escaped" else Rules.ESCAPE_LIMIT


func night_score(final_score: int) -> int:
	return final_score + acts_won() * ACT_POINTS + bonuses_earned() * BONUS_POINTS


static func rank_for(score: int) -> String:
	for r: Array in NIGHT_RANKS:
		if score >= int(r[0]):
			return String(r[1])
	return "D"


## The night's result for the Results screen and the save: the last act decides won and reason; the score is the night's.
## `final` is the last act's Rules.result(), already recorded with record().
func result(final: Dictionary, mission_id: String) -> Dictionary:
	var acts := []
	var time := 0.0
	for r in results:
		acts.append({"act": r.act, "won": bool(r.get("won", false)), "reason": String(r.get("reason", "")),
			"bonuses": r.get("bonuses", []), "time": float(r.get("time", 0.0))})
		time += float(r.get("time", 0.0))
	var score := night_score(int(final.get("score", 0)))
	return {"mission": mission_id, "won": bool(final.get("won", false)), "reason": String(final.get("reason", "")),
		"time": time, "acts": acts, "path": path, "score": score, "rank": rank_for(score),
		"lines": final.get("lines", []), "bonuses": final.get("bonuses", []),
		"goal": {"label": "The night is yours", "done": bool(final.get("won", false))}}
