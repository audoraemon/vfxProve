class_name Objective
extends RefCounted
## One thing a mission asks of the player (v0.08): it reports PENDING, DONE or FAILED from the mission's state. A
## mission's primary objectives decide it in list order -- the first to report DONE wins it, the first to report FAILED
## loses it (Rules._check_end()) -- so a mission can be won more than one way (The Warning: kill the messenger unseen,
## or outlast the omen). Bonus objectives only report in the results.
## v0.11 M1: that is off the tier board. On the board the first DONE is the night's main objective and does not end it: the
## night is held open (Rules._hold()) until the god ascends or is caught (Rules._check_caught(): dawn, or any other primary
## objective failing but the main one and a `deadline`), the main win standing. Later milestones' objectives read this.

enum Status { PENDING, DONE, FAILED }

## Short, for the HUD's panel and the results.
var label := ""
## The ending this objective gives the mission when it decides it: "citadel", "escapes", "timeout", "warning", ...
var reason := ""
## A limit on the main objective alone (v0.11 M1: the board's Festival, its square closing before dawn): once a board night's
## main objective is done, a deadline no longer applies (Rules._check_caught()).
var deadline := false


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
