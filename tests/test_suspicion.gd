extends RefCounted
## Town Suspicion: the arithmetic of Suspicion (signs, memory, fade, the latch) and each power's look.

const DT := 0.1


static func run(t) -> void:
	_arithmetic(t)
	_flat_and_none(t)
	_fade(t)
	_latch(t)
	_looks(t)


## Each power's look (PowerBook.look()).
static func _looks(t) -> void:
	var want := {"smite": &"lightning", "ember": &"fire", "tornado": &"storm", "tempest": &"storm", "shatter": &"quake",
		"tsunami": &"flood", "breath": &"miasma", "disorder": Suspicion.NONE}
	for key in want:
		t.check(PowerBook.look(key) == want[key], "%s looks like %s" % [key, want[key]])
	var natural := 0
	var unnatural := 0
	var loud_unnatural := true
	for p: Dictionary in PowerBook.POWERS:
		var l := PowerBook.look(p.key)
		if Suspicion.BASE.has(l):
			natural += 1
		elif l == Suspicion.UNNATURAL:
			unnatural += 1
			loud_unnatural = loud_unnatural and not p.get("quiet", false)
	t.check(natural == 7, "seven powers have a natural look (%d)" % natural)
	t.check(unnatural == 29 and loud_unnatural, "29 powers are unnatural, all of them loud (%d)" % unnatural)
	t.check(PowerBook.look("") == Suspicion.NONE, "a cast with no power (the sandbox) has no look")
	t.check(PowerBook.look("nonesuch") == Suspicion.NONE, "an unknown key has no look")


## Advances `s` by `secs` in DT steps.
static func _wait(s: Suspicion, secs: float) -> void:
	for i in int(round(secs / DT)):
		s.advance(DT)


static func _arithmetic(t) -> void:
	var s := Suspicion.new()
	s.sign(&"lightning")
	t.near(s.value, 20.0, 0.01, "one lightning adds 20")
	t.check(s.state() == &"calm", "one lightning leaves the town calm")

	s = Suspicion.new()
	var ups := [0]
	s.uneasy.connect(func() -> void: ups[0] += 1)
	s.sign(&"lightning")
	_wait(s, 30.0)
	s.sign(&"lightning")
	t.near(s.value, 54.0, 0.01, "lightning at 0 and 30 s: 20 - 6 + 40 = 54")
	t.check(s.state() == &"uneasy" and ups[0] == 1, "54 is uneasy, and the signal came once")

	s = Suspicion.new()
	var knew := []
	s.became_known.connect(func(why: String) -> void: knew.append(why))
	s.sign(&"lightning")
	_wait(s, 30.0)
	s.sign(&"lightning")
	_wait(s, 29.0)
	var third := s.sign(&"lightning")
	t.near(third, 60.0, 0.01, "the third lightning inside the minute adds 60")
	t.check(s.known and is_equal_approx(s.value, 100.0), "lightning at 0, 30, 59 s: the town knows, value 100")
	t.check(knew.size() == 1 and knew[0] != "" and s.reason != "", "became_known came once, with a reason")

	s = Suspicion.new()
	var want := [20.0, 21.6, 23.2, 24.8, 26.4]
	var ok := true
	var calm := true
	for i in 5:
		if i > 0:
			_wait(s, 61.0)
		s.sign(&"lightning")
		ok = ok and absf(s.value - want[i]) < 0.01
		calm = calm and s.state() == &"calm"
	t.check(ok, "lightning every 61 s: 20, 21.6, 23.2, 24.8, 26.4")
	t.check(calm, "a bolt every 61 s never makes the town uneasy")

	s = Suspicion.new()
	s.sign(&"lightning")
	_wait(s, 10.0)
	s.sign(&"storm")
	t.near(s.value, 57.5, 0.01, "lightning then storm at 10 s: 20 + 25 x 1.5 = 57.5")
	_wait(s, 10.0)
	s.sign(&"quake")
	t.check(s.known, "then a quake at 20 s: the town knows")

	s = Suspicion.new()
	s.wary = 1.5
	s.sign(&"lightning")
	t.near(s.value, 30.0, 0.01, "wary 1.5: one lightning adds 30")
	s = Suspicion.new()
	s.wary = 0.8
	s.sign(&"lightning")
	t.near(s.value, 16.0, 0.01, "wary 0.8: one lightning adds 16")

	s = Suspicion.new()
	s.sign(Suspicion.UNNATURAL)
	t.check(s.known and s.reason == "an unnatural power", "an unnatural sign: known at once, reason named")


static func _flat_and_none(t) -> void:
	var s := Suspicion.new()
	s.sign(&"lightning")
	_wait(s, 14.0)
	var none_added := s.sign(Suspicion.NONE)
	t.check(none_added == 0.0 and is_equal_approx(s.value, 20.0) and s.recent().size() == 1,
		"a sign with no look adds nothing and enters no memory")
	_wait(s, 2.0)
	t.check(s.value < 20.0, "and does not restart the fade's wait (it began 15 s after the lightning)")

	s = Suspicion.new()
	s.sign(&"lightning")
	s.add(40.0)
	t.near(s.value, 60.0, 0.01, "add(40) after one lightning: 60")
	t.check(s.recent().size() == 1 and s.recent()[0][0] == &"lightning", "add leaves no memory entry")
	s.add(40.0)
	t.check(s.known, "another add(40): the town knows")
	s.add(40.0)
	t.check(s.known and is_equal_approx(s.value, 100.0), "a further add changes nothing")


static func _fade(t) -> void:
	var s := Suspicion.new()
	s.sign(&"lightning")
	_wait(s, 30.0)
	s.sign(&"lightning")
	var ups := [0]
	s.uneasy.connect(func() -> void: ups[0] += 1)
	_wait(s, 15.0)
	t.near(s.value, 54.0, 0.01, "no fade for 15 s")
	_wait(s, 10.0)
	t.near(s.value, 50.0, 0.01, "then 0.4 a second")
	_wait(s, 200.0)
	t.near(s.value, 0.0, 0.001, "the value never falls below 0")
	t.check(s.state() == &"calm", "calm again")
	s.add(50.0)
	t.check(ups[0] == 1, "uneasy fires again after falling under 40 and rising past it")


static func _latch(t) -> void:
	var s := Suspicion.new()
	s.sign(Suspicion.UNNATURAL)
	_wait(s, 300.0)
	t.check(s.known and is_equal_approx(s.value, 100.0), "a town that knows does not fade")
	s.know("x")
	t.check(s.reason == "an unnatural power", "the first reason wins")

	s = Suspicion.new()
	t.check(s.explains(&"lightning") and s.explains(&"collapse"), "lightning and collapse are explained")
	t.check(not s.explains(&"plague") and not s.explains(&"doom"), "plague and doom are not")
	s.know("x")
	t.check(not s.explains(&"lightning"), "nothing is explained once the town knows")
	s.reset()
	t.check(s.value == 0.0 and not s.known and s.reason == "" and s.recent().is_empty(), "reset() forgets everything")
	t.check(s.explains(&"lightning"), "and explains again")
