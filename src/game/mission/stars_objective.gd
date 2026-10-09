class_name StarsObjective
extends Objective
## The board's Warning (v0.11 M1, spec §7.2): every one of its three warnings stopped (StarfallDirector). v0.11 M3: The
## Bell-Ringers' too (BellRingersDirector), in its own words; tally() reads any director's count (MissionDirector.stars_stopped()).

## The HUD's words before the count (v0.11 M3).
var count_text := "Warnings stopped"


## `text` is the label, `why` the reason a win gives, `counted` the HUD's words (v0.11 M3: The Bell-Ringers' "Stop the ringers",
## "ringers", "Ringers stopped"); the defaults are the board Warning's.
func _init(text := "Stop the warnings", why := "warning", counted := "Warnings stopped") -> void:
	label = text
	reason = why
	count_text = counted


func check(rules: Rules) -> Status:
	var n := tally(rules.director)
	return Status.DONE if n.y > 0 and n.x >= n.y else Status.PENDING


func hud_text(rules: Rules) -> String:
	var n := tally(rules.director)
	return "%s %d / %d" % [count_text, n.x, n.y if n.y > 0 else StarfallDirector.STARS.size()]


## The warnings stopped (x) and in all (y) of `d` (v0.11 M3): its own count (the final review: MissionDirector.stars_stopped() and
## stars_total(), the board Warning's stars or The Bell-Ringers' posts); (0, 0) for a director that keeps none, or none.
static func tally(d: MissionDirector) -> Vector2i:
	if d == null:
		return Vector2i.ZERO
	return Vector2i(d.stars_stopped(), d.stars_total())
