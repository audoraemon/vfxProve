extends RefCounted
## God P5 Task 2 (plan Task 2, MS H11, ruling C1): the `tune_` vars of the Exodus, Ringer and Bell Ringers directors -- each equals its
## const on a fresh director (so nothing moves by default), and a Hunt that sets one changes the night in the const's place: a small
## Exodus (three believers a house, five needed, no gate shuts, no searcher), the Ringer's mates standing and running further to the side.
## A source scan keeps every `tune_` name declared once across the bases and their subclasses (a duplicate is a parse error).

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")

## The `tune_` names each base declares (C1): the plan's list.
const EXODUS_VARS := ["tune_out_at", "tune_shut_at", "tune_hounds", "tune_per_house", "tune_believer_pace", "tune_need", "tune_chain",
	"tune_gate_watch", "tune_quiet", "tune_beats"]
const RINGER_VARS := ["tune_mates", "tune_mate_gap", "tune_mate_side", "tune_out_pause"]
const BELL_VARS := ["tune_set_out_at", "tune_chain_wait"]


## An Exodus whose numbers a Hunt changed (god P5, MS H11): three believers a house in two houses, five needed, no gate shuts, no searcher.
class SmallExodus extends ExodusDirector:
	func _init() -> void:
		tune_per_house = 3
		tune_need = 5
		tune_shut_at = []
		tune_hounds = 0

	## Its own plan: the base's, then only the first two households (two house points).
	func _plan() -> void:
		super()
		while households.size() > 2:
			households.pop_back()


static func run(t) -> void:
	_defaults_exodus(t)
	_defaults_ringer(t)
	_defaults_bell_ringers(t)
	_exodus_small(t)
	_ringer_side(t)
	_names_free(t)


static func _defaults_exodus(t) -> void:
	var d := ExodusDirector.new()
	t.check(d.tune_out_at == ExodusDirector.OUT_AT and d.tune_shut_at == ExodusDirector.SHUT_AT and d.tune_hounds == ExodusDirector.HOUNDS \
			and d.tune_per_house == ExodusDirector.PER_HOUSE and is_equal_approx(d.tune_believer_pace, ExodusDirector.BELIEVER_PACE) \
			and d.tune_need == ExodusDirector.NEED and is_equal_approx(d.tune_chain, ExodusDirector.CHAIN) \
			and d.tune_gate_watch == ExodusDirector.GATE_WATCH and is_equal_approx(d.tune_quiet, ExodusDirector.QUIET) \
			and d.tune_beats == ExodusDirector.BEATS,
		"a fresh Exodus director's tune_ vars equal its consts (%s %s %s %s)" % [d.tune_out_at, d.tune_shut_at, d.tune_need, d.tune_beats])
	d.tune_out_at.append(1.0)
	d.tune_beats.clear()
	t.check(ExodusDirector.OUT_AT.size() == 3 and ExodusDirector.BEATS.size() == 2 and ExodusDirector.new().tune_out_at.size() == 3,
		"a tune_ array is its own copy: changing one never changes the const or another director (%s)" % [ExodusDirector.OUT_AT])


static func _defaults_ringer(t) -> void:
	var r := RingerDirector.new()
	t.check(r.tune_mates == RingerDirector.MATES and is_equal_approx(r.tune_mate_gap, RingerDirector.MATE_GAP) \
			and is_equal_approx(r.tune_mate_side, RingerDirector.MATE_SIDE) and is_equal_approx(r.tune_out_pause, RingerDirector.OUT_PAUSE),
		"a fresh Ringer director's tune_ vars equal its consts (%d %.2f %.2f %.2f)" % [r.tune_mates, r.tune_mate_gap, r.tune_mate_side, r.tune_out_pause])


static func _defaults_bell_ringers(t) -> void:
	var b := BellRingersDirector.new()
	b.tune_set_out_at.append(1.0)
	t.check(b.tune_chain_wait == BellRingersDirector.CHAIN_WAIT and BellRingersDirector.SET_OUT_AT.size() == 3 \
			and BellRingersDirector.new().tune_set_out_at == BellRingersDirector.SET_OUT_AT,
		"a fresh Bell Ringers director's tune_ vars equal its consts, each array its own copy (%s %s)" % [b.tune_chain_wait, BellRingersDirector.SET_OUT_AT])


## Three believers a house in two houses, five needed, no gate shuts, no searcher; `lost_reason()` judges against five.
static func _exodus_small(t) -> void:
	var s := Kit.world(MissionBook.exodus(), SmallExodus.new())
	var d: SmallExodus = s.d
	var in_house := true
	for h: ExodusDirector.Household in d.households:
		in_house = in_house and h.members.size() == 3 and h.searchers.is_empty()
	t.check(d.households.size() == 2 and d.charges.size() == 6 and in_house,
		"a small Exodus appoints 6 believers in 2 households of 3, with no searcher (%d believers, %d households)" % [d.charges.size(), d.households.size()])
	var shuts := 0
	var outs := 0
	for e: Dictionary in d.timeline._events:
		shuts += 1 if String(e.id).begins_with("shut_") else 0
		outs += 1 if String(e.id).begins_with("out_") else 0
	t.check(shuts == 0 and outs == 2, "no gate shuts and each household still comes out (%d shuts, %d outs)" % [shuts, outs])
	var rid: String = d.lost_reason()
	t.check(rid == "" and d.hud_line().begins_with("Lead them out 0 / 5, 1 to spare"),
		"six believers against five needed is not yet lost: \"%s\", \"%s\"" % [rid, d.hud_line()])
	var shut_tag := false
	for tag in d.tags():
		shut_tag = shut_tag or tag.label.contains("SHUT IN")
	t.check(not shut_tag, "no gate shut-in tag on a night where no gate shuts")
	var cs: Array = d.charges.duplicate()
	(s.crowd as Crowd)._field.kill((cs[0] as EscortDirector.Charge).man, &"doom")
	Kit.run_for(s, DT * 2.0)
	t.check(d.lost_reason() == "", "five believers left of five needed is not lost (\"%s\")" % d.lost_reason())
	(s.crowd as Crowd)._field.kill((cs[1] as EscortDirector.Charge).man, &"doom")
	Kit.run_for(s, DT * 2.0)
	t.check(d.lost_reason() == "exodus_few", "four left of five needed is lost: exodus_few (\"%s\")" % d.lost_reason())
	Kit.done(s)


## The mates stand at the door and run at the carrier's heels `tune_mate_side` to either side, `tune_mate_gap` behind.
static func _ringer_side(t) -> void:
	var s := Kit.world(MissionBook.bell_ringers())
	var d: BellRingersDirector = s.d
	var r := d.ringers[0]
	r.tune_mate_gap = 1.5
	r.tune_mate_side = 0.85
	var at: Vector2 = r._walkable(r.gate_spot)
	var spots: Array[Vector2] = r._door_spots(at)
	var ring_ok := spots.size() == 2
	for p in spots:
		ring_ok = ring_ok and absf(p.distance_to(at) - 1.5) < 0.2
	t.check(ring_ok, "two door spots stand round the ringer at tune_mate_gap, 1.5 (%s from %s)" % [spots, at])
	var open := Vector2.ZERO
	var heel0: Vector2 = r._heel(open, Vector2.RIGHT, 0)
	var heel1: Vector2 = r._heel(open, Vector2.RIGHT, 1)
	t.check(absf(heel0.distance_to(heel1) - 1.7) < 0.05 and absf(heel0.x - (open.x - 1.5)) < 0.05,
		"two heels run 2 x tune_mate_side = 1.7 apart, 1.5 behind (%s, %s, %.2f)" % [heel0, heel1, heel0.distance_to(heel1)])
	r.tune_mates = 3
	r.tune_out_pause = 1.0
	t.check(r.tune_mates == 3 and is_equal_approx(r.tune_out_pause, 1.0), "the mates' count and the door pause are vars")
	Kit.done(s)


## No `tune_` name is declared twice across the bases and their subclasses (a parse error: "member already exists"), and the plan's
## names are each declared in their own base.
static func _names_free(t) -> void:
	var seen := {}
	var dup: Array[String] = []
	var dir := DirAccess.open("res://src/game/mission")
	var files: Array[String] = []
	if dir != null:
		for f in dir.get_files():
			if f.ends_with(".gd"):
				files.append(f)
	for f in files:
		var text := FileAccess.get_file_as_string("res://src/game/mission/%s" % f)
		for line in text.split("\n"):
			if line.begins_with("var tune_"):
				var name := line.trim_prefix("var ").split(" ")[0].split(":")[0]
				if seen.has(name):
					dup.append("%s in %s and %s" % [name, seen[name], f])
				seen[name] = f
	t.check(not files.is_empty() and dup.is_empty(), "no tune_ name is declared twice in the mission directors (%s)" % [dup])
	var home := true
	for n: String in EXODUS_VARS:
		home = home and seen.get(n, "") == "exodus_director.gd"
	for n: String in RINGER_VARS:
		home = home and seen.get(n, "") == "ringer_director.gd"
	for n: String in BELL_VARS:
		home = home and seen.get(n, "") == "bell_ringers_director.gd"
	t.check(home and seen.size() == EXODUS_VARS.size() + RINGER_VARS.size() + BELL_VARS.size(),
		"the 16 tune_ vars sit each in its own base (%d found)" % seen.size())
