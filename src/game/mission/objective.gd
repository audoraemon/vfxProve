class_name Objective
extends RefCounted
## One thing a mission asks of the player (v0.08): it reports PENDING, DONE or FAILED from the mission's state. A
## mission's primary objectives decide it in list order -- the first to report DONE wins it, the first to report FAILED
## loses it (Rules._check_end()) -- so a mission can be won more than one way (The Warning: kill the messenger unseen,
## or outlast the omen). Bonus objectives only report in the results.

enum Status { PENDING, DONE, FAILED }

## Short, for the HUD's panel and the results.
var label := ""
## The ending this objective gives the mission when it decides it: "citadel", "escapes", "timeout", "warning", ...
var reason := ""


## Virtual: a look at the mission as it begins (v0.09), from Rules.setup() -- before the intro, which holds the Rules but
## not the town.
func begin(_rules: Rules) -> void:
	pass


## Virtual: where the objective stands now.
func check(_rules: Rules) -> Status:
	return Status.PENDING


## The HUD's line for it: the label, unless the objective has a number to show; "" keeps it off the panel.
func hud_text(_rules: Rules) -> String:
	return label
