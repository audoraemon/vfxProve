extends RefCounted
## The Results screen's words: the right ending for each way a mission ends, and scores written the way the
## spec writes them.


static func run(t) -> void:
	t.check(ResultsScreen.title_for(true, "citadel") == "THE CITY HAS FALLEN", "a win reads THE CITY HAS FALLEN")
	t.check(ResultsScreen.title_for(false, "escapes") == "THE PEOPLE ESCAPED", "the escape reads THE PEOPLE ESCAPED")
	t.check(ResultsScreen.title_for(false, "timeout") == "MANIFESTATION ENDED", "the clock reads MANIFESTATION ENDED")

	t.check(ResultsScreen.thousands(12450) == "12,450", "scores get a thousands comma (%s)" % ResultsScreen.thousands(12450))
	t.check(ResultsScreen.thousands(999) == "999" and ResultsScreen.thousands(0) == "0", "small ones do not")
	t.check(ResultsScreen.thousands(1234567) == "1,234,567", "and big ones get every comma (%s)" % ResultsScreen.thousands(1234567))
	t.check(ResultsScreen.thousands(-3000) == "-3,000", "a negative keeps its sign in front (%s)" % ResultsScreen.thousands(-3000))
