extends RefCounted
## An act's timed events (v0.09): they fire once each, in time order, whenever they were added; the strip shows what is next.

## What the events saw: ids in the order `fired` gave them, and how often a callback ran.
var _seen: Array[String] = []
var _calls := 0


static func run(t) -> void:
	var s = load("res://tests/test_events.gd").new()
	s._order(t)
	s._big_step(t)
	s._upcoming(t)
	s._callback(t)
	s._late(t)
	s._ties(t)
	s._guarded(t)


func _record(id: String, _label: String) -> void:
	_seen.append(id)


func _count() -> void:
	_calls += 1


func _order(t) -> void:
	var tl := EventTimeline.new()
	_seen.clear()
	tl.fired.connect(_record)
	tl.add(30.0, "c", "Third").add(10.0, "a", "First").add(20.0, "b", "Second")
	tl.step(5.0)
	t.check(_seen.is_empty() and tl.fired_ids().is_empty(), "nothing fires before its time (%s)" % [_seen])
	tl.step(6.0)
	t.check(_seen == ["a"], "the first fires at 10 s (%s)" % [_seen])
	tl.step(10.0)
	t.check(_seen == ["a", "b"], "the next at 20 s, though it was added last-but-one (%s)" % [_seen])
	tl.step(10.0)
	tl.step(10.0)
	t.check(_seen == ["a", "b", "c"] and tl.fired_ids() == PackedStringArray(["a", "b", "c"]),
		"each fires once, in time order, and fired_ids() lists them (%s)" % [_seen])
	t.near(tl.elapsed(), 41.0, 0.001, "the timeline knows how long the act has run")


func _big_step(t) -> void:
	var tl := EventTimeline.new()
	_seen.clear()
	tl.fired.connect(_record)
	tl.add(90.0, "z", "Z").add(5.0, "x", "X").add(45.0, "y", "Y")
	tl.step(100.0)
	t.check(_seen == ["x", "y", "z"], "one big step fires every due event, in order (%s)" % [_seen])


func _upcoming(t) -> void:
	var tl := EventTimeline.new()
	tl.add(45.0, "a", "A").add(90.0, "b", "B").add(120.0, "c", "C")
	tl.step(10.0)
	var up := tl.upcoming(2)
	t.check(up.size() == 2 and up[0].id == "a" and up[1].id == "b", "upcoming(2) lists the next two (%s)" % [up])
	t.near(float(up[0]["in"]), 35.0, 0.001, "with the seconds to go")
	t.near(float(up[1]["in"]), 80.0, 0.001, "for each")
	t.check(tl.upcoming().size() == 2 and tl.upcoming(3).size() == 3 and tl.upcoming(9).size() == 3,
		"and the count is the asker's (%d)" % tl.upcoming(9).size())
	tl.step(40.0)
	t.check(tl.upcoming(2).size() == 2 and tl.upcoming(2)[0].id == "b", "a fired event leaves the list (%s)" % [tl.upcoming(2)])
	tl.step(200.0)
	t.check(tl.upcoming(2).is_empty(), "after all have fired it is empty")


func _callback(t) -> void:
	var tl := EventTimeline.new()
	_calls = 0
	tl.add(10.0, "a", "A", _count)
	tl.add(12.0, "b", "B")
	tl.step(11.0)
	tl.step(11.0)
	tl.step(11.0)
	t.check(_calls == 1, "an event's callback runs once (%d)" % _calls)
	t.check(tl.fired_ids().size() == 2, "and one with no callback still fires (%s)" % [tl.fired_ids()])


func _late(t) -> void:
	var tl := EventTimeline.new()
	_seen.clear()
	tl.fired.connect(_record)
	tl.step(50.0)
	tl.add(20.0, "late", "Late")
	t.check(_seen.is_empty(), "adding does not fire")
	tl.step(0.1)
	t.check(_seen == ["late"], "an event added after its time fires on the next step (%s)" % [_seen])


func _ties(t) -> void:
	# sort_custom is not stable: events due together must still fire in the order they were added.
	var tl := EventTimeline.new()
	_seen.clear()
	tl.fired.connect(_record)
	var want: Array[String] = []
	for i in 40:
		want.append("e%d" % i)
		tl.add(10.0 if i % 3 != 0 else 5.0, "e%d" % i, "E")
	want.sort_custom(func(a: String, b: String) -> bool:
		var ia := int(a.substr(1))
		var ib := int(b.substr(1))
		var ta := 5.0 if ia % 3 == 0 else 10.0
		var tb := 5.0 if ib % 3 == 0 else 10.0
		return ia < ib if ta == tb else ta < tb)
	tl.step(20.0)
	t.check(_seen == want, "events due together fire in the order they were added (%s)" % [_seen.slice(0, 8)])


var _ok := true


func _guard() -> bool:
	return _ok


func _guarded(t) -> void:
	var tl := EventTimeline.new()
	_seen.clear()
	_calls = 0
	_ok = true
	tl.fired.connect(_record)
	tl.add(10.0, "g", "Guarded", _count, _guard).add(20.0, "p", "Plain")
	t.check(tl.upcoming(2).size() == 2, "a guard that holds leaves its event listed")
	_ok = false
	t.check(tl.upcoming(2).size() == 1 and tl.upcoming(2)[0].id == "p", "a guard that fails takes it off the list at once (%s)" % [tl.upcoming(2)])
	tl.step(11.0)
	t.check(_calls == 0 and _seen.is_empty() and tl.fired_ids().is_empty(), "and when due it runs nothing and says nothing (%d, %s)" % [_calls, _seen])
	_ok = true
	tl.step(10.0)
	t.check(_calls == 0 and _seen == ["p"], "it stays dropped though the guard holds again; the others fire (%s)" % [_seen])
	var held := EventTimeline.new()
	_calls = 0
	held.add(5.0, "h", "Held", _count, _guard)
	held.step(6.0)
	t.check(_calls == 1 and held.fired_ids() == PackedStringArray(["h"]), "a guard that holds lets it fire as before")
