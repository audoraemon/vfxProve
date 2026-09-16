class_name FxTimeline
extends Node2D
## Base for staged effects. Subclasses schedule callbacks with at() in _build().

var ctx: FxContext
## Cast point in ground units.
var origin := Vector2.ZERO
var extra := {}
var t := 0.0
var duration := 5.0
var finished := false

var _events: Array = []
var _tracked: Array[Node] = []


static func cast(script: GDScript, c: FxContext, at_ground: Vector2, extra_data := {}) -> FxTimeline:
	var fx: FxTimeline = script.new()
	fx.ctx = c
	fx.origin = at_ground
	fx.extra = extra_data
	c.overhead.add_child(fx)
	fx._build()
	return fx


## Virtual: schedule stages.
func _build() -> void:
	pass


## Virtual: per-frame work after events fire.
func _fx_process(_delta: float) -> void:
	pass


func at(time: float, fn: Callable) -> void:
	var i := _events.bsearch_custom(time, func(e, v): return e[0] <= v)
	_events.insert(i, [time, fn])


func track(node: Node, parent: Node) -> Node:
	parent.add_child(node)
	_tracked.append(node)
	return node


func ground_screen(g: Vector2) -> Vector2:
	return Iso.ground_to_screen(g)


func _process(delta: float) -> void:
	if finished:
		return
	t += delta
	while not _events.is_empty() and _events[0][0] <= t:
		var ev: Array = _events.pop_front()
		ev[1].call()
	_fx_process(delta)
	if t >= duration:
		_finish()


func _finish() -> void:
	finished = true
	_free_tracked()
	queue_free()


func _exit_tree() -> void:
	# Parents may be mid-teardown here, so never free immediately.
	_free_tracked(true)


func _free_tracked(deferred := false) -> void:
	for n in _tracked:
		if not is_instance_valid(n):
			continue
		if deferred or n.is_inside_tree():
			n.queue_free()
		else:
			n.free()
	_tracked.clear()
