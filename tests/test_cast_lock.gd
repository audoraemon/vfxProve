extends RefCounted
## v0.06: a lingering power locks the other slots only for its `busy` seconds, not its whole run; one without
## `busy` keeps the whole-duration lock.


static func run(t) -> void:
	var rules := Rules.new()
	var fx := FxTimeline.new()
	fx.duration = 25.0
	rules._playing = fx
	t.check(is_equal_approx(rules.busy_left(), 25.0), "without busy, the whole run locks (%.1f)" % rules.busy_left())
	fx.busy = 1.0
	t.check(is_equal_approx(rules.busy_left(), 1.0), "with busy, only that long (%.1f)" % rules.busy_left())
	fx.t = 1.5
	t.check(rules.busy_left() == 0.0, "and then the slots are free while it lingers")
	fx.free()
	rules.free()
