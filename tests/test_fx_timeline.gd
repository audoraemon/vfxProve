extends RefCounted


class Probe extends FxTimeline:
	var events: Array = []

	func _build() -> void:
		duration = 1.0
		at(0.5, func(): events.append("b"))
		at(0.1, func(): events.append("a"))


static func run(t) -> void:
	var p := Probe.new()
	var holder := Node.new()
	var part := Node.new()
	p._build()
	p.track(part, holder)
	for i in 36:
		p._process(1.0 / 60.0)
	t.check(p.events == ["a", "b"], "events fire in time order (%s)" % [p.events])
	t.check(not p.finished, "not finished at 0.6s")
	for i in 30:
		p._process(1.0 / 60.0)
	t.check(p.finished, "finished after duration")
	t.check(not is_instance_valid(part), "tracked part freed")
	holder.free()
	if is_instance_valid(p):
		p.free()
