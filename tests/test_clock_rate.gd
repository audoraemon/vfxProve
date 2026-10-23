extends RefCounted
## v0.11.2 Task 2: the mission clock's rate (review focus 4). One Rules field read by the clock and every EventTimeline;
## cooldowns, elapsed() and a person's walk stay real; 1.0 everywhere until a Lantern turns.

const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_rates(t)
	_timeline(t)
	_abolished(t)
	_director(t)
	_freed_clock(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.bell_ringers())


static func _rates(t) -> void:
	var s := _world()
	var r: Rules = s.rules
	t.check(is_equal_approx(r.clock_rate, 1.0), "a fresh Rules runs at rate 1")
	r.clock_rate = -3.0
	t.check(r.clock_rate == 0.0, "a negative rate clamps to 0")
	r.clock_rate = 2.0
	var t0 := r.time_left
	var slot := 0
	while slot < r.loadout.size() - 1 and r.key(slot) == "whisper":
		slot += 1  # Mind Whisper with no one to whisper to starts no cooldown
	var cast := r.cast(slot, Vector2(0.0, 8.0))
	t.check(cast == null and r.cooldown_left(slot) > 0.0, "the cast started the cooldown (a test caster hands nothing back)")
	var cd0 := r.cooldown_left(slot)
	r.advance(1.0)
	t.check(is_equal_approx(r.time_left, t0 - 2.0), "the clock runs at the rate")
	t.check(is_equal_approx(r.cooldown_left(slot), cd0 - 1.0), "a cooldown stays real")
	t.check(is_equal_approx(r.mission_time(), 2.0) and is_equal_approx(r.elapsed(), 1.0),
		"mission time doubles, elapsed is real")
	r.clock_rate = 1.0
	r.advance(1.0)
	t.check(is_equal_approx(r.mission_time(), 3.0), "the rate can fall back to 1")
	Kit.done(s)


static func _timeline(t) -> void:
	var r := Rules.new()
	var tl := EventTimeline.new()
	tl.clock = r
	var hit := [false]
	tl.add(10.0, "e", "E", func() -> void: hit[0] = true)
	tl.add(30.0, "far", "Far")
	r.clock_rate = 1.5
	tl.step(6.6)
	t.check(not hit[0], "not yet at 9.9 mission seconds")
	tl.step(0.1)
	t.check(hit[0], "fires at 10 mission seconds (6.67 real)")
	tl.step(0.0)
	r.clock_rate = 2.0
	var tl2 := EventTimeline.new()
	tl2.clock = r
	tl2.add(30.0, "far", "Far")
	tl2.step(6.7)
	t.check(is_equal_approx(float(tl2.upcoming(1)[0]["in"]), 30.0 - 13.4), "upcoming()'s in is mission seconds")
	t.check(is_equal_approx(tl2.seconds_to("far"), 30.0 - 13.4), "seconds_to() is mission seconds")
	# A stretched timeline at rate 2.0 against a stretch of 2.0 runs at real speed.
	var tl3 := EventTimeline.new().stretched(2.0)
	tl3.clock = r
	var hit3 := [false]
	tl3.add(10.0, "s", "S", func() -> void: hit3[0] = true)
	tl3.step(9.9)
	t.check(not hit3[0], "a stretched timeline at rate 2.0 is not early")
	tl3.step(0.2)
	t.check(hit3[0], "a stretched timeline at rate 2.0 runs at real speed: an event at 10 fires after 10 real seconds")
	# Without a clock the rate is 1.
	var tl4 := EventTimeline.new()
	var hit4 := [false]
	tl4.add(10.0, "n", "N", func() -> void: hit4[0] = true)
	tl4.step(9.9)
	t.check(not hit4[0], "no clock: rate 1")
	tl4.step(0.2)
	t.check(hit4[0], "no clock: fires at 10 real seconds")
	r.free()


static func _abolished(t) -> void:
	var s := _world()
	var r: Rules = s.rules
	r.abolish(Rules.LAW_CLOCK, 5.0)
	r.clock_rate = 2.0
	var t0 := r.time_left
	r.advance(1.0)
	t.check(is_equal_approx(r.time_left, t0), "Abolition's clock law still stops the clock at a rate")
	t.check(is_equal_approx(r.mission_time(), 0.0), "mission time stands still under Abolition")
	Kit.done(s)


static func _director(t) -> void:
	var s := _world()
	var d: MissionDirector = s.d
	var r: Rules = s.rules
	t.check(d.timeline.clock == r, "a director's timeline runs on its Rules")
	r.clock_rate = 2.0
	t.check(is_equal_approx(d.mission_delta(0.5), 1.0), "mission_delta() doubles at rate 2")
	d.timeline.step(1.0)
	t.check(is_equal_approx(d.timeline.elapsed(), 2.0), "the director's timeline ran double")
	var bare := MissionDirector.new()
	t.check(is_equal_approx(bare.mission_delta(0.5), 0.5), "mission_delta() with no rules is the real delta")
	t.check(bare._new_timeline().clock == null, "no rules: the timeline has no clock")
	Kit.done(s)


## Rules is a Node freed at next_act: a timeline that outlives it runs at rate 1, never on a freed object.
static func _freed_clock(t) -> void:
	var r := Rules.new()
	r.clock_rate = 2.0
	var tl := EventTimeline.new()
	tl.clock = r
	r.free()
	tl.step(1.0)
	t.check(is_equal_approx(tl.elapsed(), 1.0), "a freed Rules no longer speeds the timeline")
