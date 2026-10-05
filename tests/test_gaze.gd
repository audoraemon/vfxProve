extends RefCounted
## v0.10 Halcyon's Gaze (spec §3.4): a meter from 0 to 100 that never falls; a seen death adds 10, prayer adds up to 6 a
## second, a report or the bell fills it; full, it fails the night. The HUD reads it; the results name the ending.


static func run(t) -> void:
	var g := GazeMeter.new()
	var fills := [0]
	g.filled.connect(func() -> void: fills[0] += 1)
	t.check(g.value == 0.0 and g.fraction() == 0.0 and not g.is_full(), "the Gaze starts at 0")
	g.seen_death()
	t.near(g.value, 10.0, 0.001, "a seen death adds 10")
	g.pray(3, 1.0)
	t.near(g.value, 13.0, 0.001, "three praying for a second add 3")
	g.pray(20, 1.0)
	t.near(g.value, 19.0, 0.001, "prayer is capped at 6 a second")
	g.add(-50.0)
	t.near(g.value, 19.0, 0.001, "the Gaze never falls")
	g.add(GazeMeter.SEARCHLIGHT)
	g.add(GazeMeter.SEARCHLIGHT)
	t.check(g.is_full() and g.value == GazeMeter.FULL and fills[0] == 1, "two searchlight touches fill it, once")
	g.fill()
	t.check(fills[0] == 1, "filling a full Gaze says nothing more")
	var h := GazeMeter.new()
	h.fill()
	t.check(h.is_full() and h.fraction() == 1.0, "a report fills it at once")

	# The objective, and the HUD's reading, through a director that has a Gaze.
	var d := MissionDirector.new()
	var rules := Rules.new()
	rules.director = d
	var o := GazeObjective.new()
	t.check(o.check(rules) == Objective.Status.PENDING and o.hud_text(rules) == "" and Hud.gaze_of(rules) == -1.0,
		"without a Gaze the objective waits, shows nothing, and the HUD draws no bar")
	d.gaze = GazeMeter.new()
	d.gaze.add(40.0)
	t.check(o.check(rules) == Objective.Status.PENDING and o.hud_text(rules) == "Halcyon's Gaze 40%",
		"the objective's line: %s" % o.hud_text(rules))
	t.near(Hud.gaze_of(rules), 0.4, 0.001, "the HUD's bar reads 40%")
	d.gaze.fill()
	t.check(o.check(rules) == Objective.Status.FAILED and o.reason == "gaze", "a full Gaze fails the night")
	t.check(MissionDirector.new().marks().is_empty(), "a director marks nobody by default")
	t.check(ResultsScreen.title_for(false, "gaze") == "THE LANTERN LOOKS" and ResultsScreen.title_for(true, "believers")
		== "THEY BELIEVE" and ResultsScreen.title_for(false, "few") == "TOO FEW BELIEVE", "the night's endings have titles")
	rules.free()
