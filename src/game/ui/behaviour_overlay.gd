class_name BehaviourOverlay
extends Node
## F4 (v0.04 debug): what the town's people are thinking. In the world, a ring under every citizen in its intent's
## colour; on screen, the alarm stage, the bell, the last stage changes, each gate's queue and the route score an
## average evacuee gives it, the garrison on the Citadel's ring (v0.09.1), the plague while anyone is sick, and for
## the citizen nearest the mouse its role, intent, awareness, the dangers near it and a line to where it is going.
## Hidden until asked for; stays shown for the run once shown.

const TOGGLE_KEY := KEY_F4
## Ring colours by Person.Intent: routine, observe, local flee, regroup, evacuate, reroute, recover, assist, shelter,
## confused, gather, frenzy.
const INTENT_COLS := [Color("7fc46a"), Color("e8e2d0"), Color("ff8a3a"), Color("6fa8c8"), Color("c8342a"),
	Color("d060e0"), Color("d8b23a"), Color("5ad0ff"), Color("b0b0ff"), Person.COL_DISCORD,
	Person.COL_WHISPER, Color("ffd86a"), Color("ff3838")]
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
		if not is_instance_valid(p) or not p.is_alive() or p.inside:
			continue
		var at := Iso.ground_to_screen(p.ground_pos)
		ci.draw_arc(at, 4.0, 0.0, TAU, 10, intent_color(p.intent()), 1.0)
		# The compelled: the path to where they are drawn. The maddened: the value and its stage over the head.
		if p.mind == Person.Mind.COMPELLED and p.goal() != Vector2.INF:
			ci.draw_line(at, Iso.ground_to_screen(p.goal()), Color(INTENT_COLS[Person.Intent.GATHER], 0.5), 1.0)
		_draw_statuses(ci, p, at)
	if crowd.madness != null:
		for l: Array in crowd.madness.links:
			ci.draw_line(Iso.ground_to_screen(l[0]), Iso.ground_to_screen(l[1]), Color(0.8, 0.3, 0.6, 0.8), 1.0)
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and p.mind == Person.Mind.FIGHT:
			_draw_statuses(ci, p, Iso.ground_to_screen(p.ground_pos))
	if crowd.engineers != null:
		for team: Dictionary in crowd.engineers.teams:
			if (team.job as Dictionary).is_empty():
				continue
			for p in team.members:
				if is_instance_valid(p):
					ci.draw_line(Iso.ground_to_screen((p as Person).ground_pos), Iso.ground_to_screen(team.job.site),
						Color(0.6, 0.75, 0.9, 0.8), 1.0)
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


## A status's value and stage over the head (madness), and a fighter's line to whom it is going for.
func _draw_statuses(ci: CanvasItem, p: Person, at: Vector2) -> void:
	if p.statuses.has(MadnessManager.STATUS):
		var v: float = p.statuses[MadnessManager.STATUS]
		var stage := MadnessManager.stage_of(v)
		UiTheme.text(ci, at + Vector2(-10, -26), "%.2f %s" % [v, MadnessManager.STAGE_NAMES[stage]], UiTheme.SIZE_SMALL,
			MadnessManager.COL_STAGES[stage])
	if p.mind == Person.Mind.FIGHT and is_instance_valid(p.fight_target):
		ci.draw_line(at, Iso.ground_to_screen(p.fight_target.ground_pos), Color(1, 0.2, 0.2, 0.8), 1.0)


func _draw_panel(ci: Control) -> void:
	var lines: Array = []
	var a := crowd.alarms
	lines.append(["%s: %s" % [crowd.profile.tier_name(), ", ".join(crowd.profile.lines())], UiTheme.COL_GOLD])
	var bell := "none"
	if crowd.bell != null:
		bell = BellNetwork.State.keys()[crowd.bell.state].capitalize()
		if crowd.bell.state == BellNetwork.State.CLIMBING:
			bell += " %.0f/%.0f s" % [crowd.bell.progress, crowd.bell.climb]
	lines.append(["Stage: %s   alarm %d   bell %s" % [a.stage_name(), roundi(crowd.alarm), bell], Hud.STAGE_COLS[a.stage]])
	if crowd.rite != null and crowd.profile.rite:
		var r := crowd.rite
		lines.append(["Rite: %s   %d/%d in ring   %.0f/%.0f s   clergy %d" % [BanishingRite.State.keys()[r.state].capitalize(),
			r.in_ring(), BanishingRite.NEED, r.progress, r.duration, r.living_clergy()], UiTheme.COL_GOLD])
	if crowd.engineers != null and crowd.profile.engineer_teams > 0:
		var e := crowd.engineers
		for i in e.teams.size():
			var team: Dictionary = e.teams[i]
			var what := "standing by"
			if not (team.job as Dictionary).is_empty():
				var job: Dictionary = team.job
				what = "%s %s %d%%  score %d" % ["rebuilding" if job.rebuild else "mending",
					EngineerManager.Job.keys()[job.type].capitalize(), roundi(100.0 * e.job_fraction(team)),
					roundi(e.score(job, e._where(team)))]
			lines.append(["Engineers %d: %s%s" % [i + 1, what, ", working" if team.working else ""], Color("9ab4d0")])
		if not e.replacing.is_empty():
			lines.append(["Engineers: %d lost, next in %.0f s" % [e.replacing.size(), e.replacing.min()], Color("9ab4d0")])
	if crowd.ferry != null and crowd.profile.boats:
		var f := crowd.ferry
		lines.append(["Boats: %s   aboard %d/%d   waiting %d   %d trips, %d carried" % [
			RiverFerry.State.keys()[f.state].capitalize(), f.aboard.size(), f.capacity, f.waiting(), f.trips, f.carried],
			Color("8ac8e8")])
	if crowd.marshals != null and crowd.marshals.active:
		var parts := []
		for e in crowd.marshals.exits():
			parts.append("x%.2f" % crowd.marshals.speed_at(e[0]))
		lines.append(["Marshals at the ways out: %s" % ", ".join(parts), Color("e06060")])
	if crowd.escorts != null and not crowd.escorts.guards.is_empty():
		var parts := []
		for key in crowd.escorts.guards:
			parts.append("%s %d" % [key, (crowd.escorts.guards[key] as Array).size()])
		lines.append(["Escorts: %s" % ", ".join(parts), Color("e8e4dc")])
	if crowd.rescue != null:
		var digging := 0
		for sq in crowd.rescue.squads:
			if sq.site != null:
				digging += 1
		lines.append(["Rescue: %d squads, %d digging; trapped %d, saved %d, lost %d" % [crowd.rescue.squads.size(), digging,
			crowd.rescue.trapped.size(), crowd.rescue.rescued, crowd.rescue.died], Color("c0a070")])
	var ring := crowd.ring_count()
	if ring > 0:
		lines.append(["Garrison -%d%%: %d on the ring" % [roundi(Citadel.cut_for(ring) * 100.0), ring], Color("b8bcc4")])
	if crowd.plague != null and not crowd.plague.sick.is_empty():
		var plague := crowd.plague
		var sick_soldiers := 0
		for p in plague.sick:
			if is_instance_valid(p) and p.soldier:
				sick_soldiers += 1
		lines.append(["Plague: %d sick (%d soldiers), %d dead, %d puffs" % [plague.sick.size(), sick_soldiers,
			plague.deaths, plague.puffs_alive()], Person.SICK_MOTE])
	if crowd.madness != null and not crowd.madness.afflicted.is_empty():
		var m := crowd.madness
		var by_stage := [0, 0, 0, 0]
		for p: Person in m.afflicted:
			if is_instance_valid(p) and p.is_alive():
				by_stage[MadnessManager.stage_of(m.value_of(p))] += 1
		lines.append(["Madness: %d afflicted (%d uneasy, %d disturbed, %d unstable, %d broken), %d broken in all, alarm +%.1f" % [
			m.afflicted.size(), by_stage[0], by_stage[1], by_stage[2], by_stage[3], m.broken, m.alarm_generated],
			MadnessManager.COL_STAGES[2]])
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
		var names := ["Main Gate", "Side Gate", "Postern"]
		for i in crowd.evac.gates.size():
			var g: Structure = crowd.evac.gates[i]
			var state := "destroyed" if not is_instance_valid(g) or g.destroyed else "open"
			lines.append(["%s: %s, queue %d" % [names[mini(i, 2)], state,
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
