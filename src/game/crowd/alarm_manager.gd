class_name AlarmManager
extends RefCounted
## The town's alarm in stages (v0.04), instead of one number that at 50 sends everyone to the gates. The alarm
## value (kills, collapses, hits on the Citadel) still counts; with the incidents per district and the cathedral
## bell it decides the stage, which only ever rises:
##   Normal -> Concern (any danger) -> Local Emergency (a district with LOCAL_EVENTS incidents) -> City Emergency
##   (alarm CITY_ALARM, or CITY_DISTRICTS districts in local emergency) -> Evacuation (REGROUP_SECONDS on, alarm
##   EVAC_BELL once the bell has rung, EVAC_NO_BELL without it) -> Collapse (the Citadel falls, or stability down to COLLAPSE_STABILITY).
## The crowd acts on each new stage (Crowd._on_stage()): soldiers investigate, the bell, regrouping, evacuation.

signal stage_changed(stage: Stage, reason: String)

enum Stage { NORMAL, CONCERN, LOCAL_EMERGENCY, CITY_EMERGENCY, EVACUATION, COLLAPSE }
const NAMES := ["Normal", "Concern", "Local Emergency", "City Emergency", "Evacuation", "Collapse"]

## Tuned by behaviour_check.gd's escalate scenario: one Heaven Splitter into the packed market (about 20 stalls and
## 40 people) reaches alarm 50-60 on its own, and must not empty the town by itself.
const LOCAL_EVENTS := 4
const CITY_ALARM := 35.0
## Once the Bell Tower has rung (v0.05), the town calls City Emergency and the evacuation sooner.
const CITY_ALARM_BELL := 25.0
const CITY_DISTRICTS := 2
const EVAC_BELL := 60.0
const EVAC_NO_BELL := 90.0
## Seconds after City Emergency before any evacuation: time for families to regroup and the bell to ring. By default;
## the profile sets it (ResponseProfile.regroup_seconds, v0.08.2: God-Resistant's town is quicker), as regroup_seconds.
const REGROUP_SECONDS := 15.0
const COLLAPSE_STABILITY := 0.25
## The last few stage changes, for the debug overlay: [clock, stage, reason].
const HISTORY := 5

var stage := Stage.NORMAL
var bell_rung := false
var collapsed := false
var regroup_seconds := REGROUP_SECONDS
var history: Array = []
## When City Emergency began (-1: not yet).
var _city_at := -1.0
## District index -> incidents (collapses, deaths) there.
var _events := {}


## The district (City.current().districts() index) a ground point is in, or the nearest one.
static func district_of(g: Vector2) -> int:
	var best := 0
	var best_d := INF
	var districts := City.current().districts()
	for i in districts.size():
		var d: Rect2 = districts[i]
		if d.has_point(g):
			return i
		var dist := d.get_center().distance_to(g)
		if dist < best_d:
			best_d = dist
			best = i
	return best


## A collapse or a death at `g`. True when it just put its district into local emergency.
func incident(g: Vector2) -> bool:
	var d := district_of(g)
	_events[d] = int(_events.get(d, 0)) + 1
	return int(_events[d]) == LOCAL_EVENTS


func districts_in_emergency() -> int:
	var n := 0
	for d in _events:
		if int(_events[d]) >= LOCAL_EVENTS:
			n += 1
	return n


## The stage the numbers call for now; the stage rises to it, one step at a time, each announced.
func update(alarm: float, dangers: int, clock: float) -> void:
	var target := Stage.NORMAL
	var reason := ""
	if dangers > 0 or not _events.is_empty():
		target = Stage.CONCERN
		reason = "danger in town"
	if districts_in_emergency() >= 1:
		target = Stage.LOCAL_EMERGENCY
		reason = "a district in emergency"
	var city_at := CITY_ALARM_BELL if bell_rung else CITY_ALARM
	if alarm >= city_at or districts_in_emergency() >= CITY_DISTRICTS:
		target = Stage.CITY_EMERGENCY
		reason = "alarm %d" % roundi(alarm) if alarm >= city_at else "%d districts in emergency" % districts_in_emergency()
	var regrouped := _city_at >= 0.0 and clock - _city_at >= regroup_seconds
	if regrouped and ((bell_rung and alarm >= EVAC_BELL) or alarm >= EVAC_NO_BELL):
		target = Stage.EVACUATION
		reason = "the bell rang, alarm %d" % roundi(alarm) if bell_rung and alarm < EVAC_NO_BELL else "alarm %d" % roundi(alarm)
	if collapsed:
		target = Stage.COLLAPSE
		reason = "order breaks down"
	while stage < target:
		stage = (stage + 1) as Stage
		if stage == Stage.CITY_EMERGENCY:
			_city_at = clock
		history.append([clock, stage, reason])
		if history.size() > HISTORY:
			history.pop_front()
		stage_changed.emit(stage, reason)


func stage_name() -> String:
	return NAMES[stage]


func reset() -> void:
	stage = Stage.NORMAL
	bell_rung = false
	collapsed = false
	_city_at = -1.0
	history.clear()
	_events.clear()
