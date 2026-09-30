class_name BehaviourOverlay
extends Node
## F4 (v0.04 debug): what the town's people are thinking. In the world, a ring under every citizen in its intent's
## colour; on screen, the alarm stage, the bell, the last stage changes, each gate's queue and the route score an
## average evacuee gives it, and for the citizen nearest the mouse its role, intent, awareness, the dangers near it
## and a line to where it is going. Hidden until asked for; stays shown for the run once shown.

const TOGGLE_KEY := KEY_F4
## Ring colours by Person.Intent: routine, observe, local flee, regroup, evacuate, reroute, recover, assist.
const INTENT_COLS := [Color("7fc46a"), Color("e8e2d0"), Color("ff8a3a"), Color("6fa8c8"), Color("c8342a"),
	Color("d060e0"), Color("d8b23a"), Color("5ad0ff")]
## How near the mouse (ground units) a citizen must be to be the one described.
const PICK_REACH := 1.5

static var shown := false

var crowd: Crowd
var battlefield: Battlefield
var _world: Node2D
var _panel: Control


class World extends Node2D:
	var overlay: BehaviourOverlay

	func _draw() -> void:
		overlay._draw_world(self)


class Readout extends Control:
	var overlay: BehaviourOverlay

	func _draw() -> void:
		overlay._draw_panel(self)


func setup(c: Crowd, bf: Battlefield) -> BehaviourOverlay:
	crowd = c
	battlefield = bf
	return self


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_world = World.new()
	_world.overlay = self
	_world.z_index = 50
	battlefield.ctx.world.get_parent().add_child(_world)
	var layer := CanvasLayer.new()
	layer.layer = 99
	add_child(layer)
	_panel = Readout.new()
	_panel.overlay = self
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_panel)
	_apply()


func _exit_tree() -> void:
	if is_instance_valid(_world):
		_world.queue_free()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == TOGGLE_KEY:
		shown = not shown
		_apply()


func _apply() -> void:
	_world.visible = shown
	_panel.visible = shown


func _process(_delta: float) -> void:
	if shown:
		_world.queue_redraw()
		_panel.queue_redraw()


static func intent_color(i: Person.Intent) -> Color:
	return INTENT_COLS[i]


func _picked() -> Person:
	var at := battlefield.mouse_ground()
	var best: Person = null
	var best_d := PICK_REACH
	for p in crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and p.ground_pos.distance_to(at) < best_d:
			best_d = p.ground_pos.distance_to(at)
			best = p
	return best


func _draw_world(ci: CanvasItem) -> void:
	for p in crowd.citizens:
		if not is_instance_valid(p) or not p.is_alive():
			continue
		var at := Iso.ground_to_screen(p.ground_pos)
		ci.draw_arc(at, 4.0, 0.0, TAU, 10, intent_color(p.intent()), 1.0)
	var picked := _picked()
	if picked != null:
		var at := Iso.ground_to_screen(picked.ground_pos)
		ci.draw_arc(at, 7.0, 0.0, TAU, 14, Color.WHITE, 1.0)
		if picked.goal() != Vector2.INF:
			ci.draw_line(at, Iso.ground_to_screen(picked.goal()), Color(1, 1, 1, 0.6), 1.0)
		for t in crowd.threats.nearby(picked.ground_pos, 12.0):
			var c := Iso.ground_to_screen(t.at)
			var r := float(t.radius) * 32.0 * 1.414
			ci.draw_arc(c, r, 0.0, TAU, 32, Color(1, 0.4, 0.2, 0.8), 1.0)
			ci.draw_arc(c, float(t.sound) * 45.0, 0.0, TAU, 48, Color(1, 0.9, 0.4, 0.35), 1.0)


func _draw_panel(ci: Control) -> void:
	var lines: Array = []
	var a := crowd.alarms
	lines.append(["Stage: %s   alarm %d   bell %s" % [a.stage_name(), roundi(crowd.alarm),
		"rung" if a.bell_rung else "silent"], Hud.STAGE_COLS[a.stage]])
	for h in a.history:
		lines.append(["  %5.1fs  %s  (%s)" % [float(h[0]), AlarmManager.NAMES[h[1]], h[2]], UiTheme.COL_DIM])
	var counts := {}
	for p in crowd.citizens:
		if is_instance_valid(p) and p.is_alive():
			counts[p.intent()] = int(counts.get(p.intent(), 0)) + 1
	for k in Person.Intent.values():
		if counts.has(k):
			lines.append(["%s %d" % [Person.Intent.keys()[k].capitalize(), counts[k]], INTENT_COLS[k]])
	if crowd.evac != null:
		var names := ["Main", "Side"]
		for i in crowd.evac.gates.size():
			var g: Structure = crowd.evac.gates[i]
			var state := "destroyed" if not is_instance_valid(g) or g.destroyed else "open"
			lines.append(["%s Gate: %s, queue %d" % [names[mini(i, 1)], state,
				crowd.waiting_at(g) if is_instance_valid(g) else 0], UiTheme.COL_TEXT])
	var picked := _picked()
	if picked != null and picked.profile != null:
		lines.append(["%s: %s, %s" % [CitizenProfile.Role.keys()[picked.profile.role].capitalize(),
			Person.Intent.keys()[picked.intent()].capitalize(), Person.Awareness.keys()[picked.awareness].capitalize()],
			Color.WHITE])
		if picked.mind == Person.Mind.FLEE and crowd.evac != null:
			var sc := []
			for i in crowd.evac.exits.size():
				sc.append("%.0f" % crowd.evac.score(picked, i))
			lines.append(["  exit scores (south, east): %s" % ", ".join(sc), Color.WHITE])
	var y := 120.0
	var w := 0.0
	for l in lines:
		w = maxf(w, UiTheme.width(String(l[0]), UiTheme.SIZE_SMALL))
	ci.draw_rect(Rect2(4, y - 10, w + 8, UiTheme.LINE_SMALL * lines.size() + 4), Color(0, 0, 0, 0.6))
	for l in lines:
		UiTheme.text(ci, Vector2(8, y), String(l[0]), UiTheme.SIZE_SMALL, l[1])
		y += UiTheme.LINE_SMALL
