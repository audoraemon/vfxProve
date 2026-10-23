extends RefCounted
## v0.12 Task 6: the five Tier 1 directors read their places and numbers from town vars seeded by their consts (spec 1.5, R31), so a
## town's override survives setup; the scripted policies read the director's vars, not its consts. Aldermere is exact: a fresh
## director's every var equals its const.

const Kit := preload("res://tests/test_tier2_groundwork.gd")

## The five scripts, and the consts each one now reads only through a var (its declaration and _init() excepted).
const SCRIPTS := {
	"res://src/game/mission/starfall_director.gd": ["STARS", "STOP_WAIT"],
	"res://src/game/mission/tax_collector_director.gd": ["COUNTING_TAG", "ROUNDS", "SET_OUT_AT", "GUARDS", "VISIT_SECONDS",
		"HIDE_SECONDS", "ALARM_REACH", "GUARD_R", "CHAIN_WAIT", "FLUSH_GAP"],
	"res://src/game/mission/harvest_director.gd": ["STORE_SPOTS", "STORE_NAMES", "GRAIN_AT", "CHAIN_AFTER", "LOADS"],
	"res://src/game/mission/lost_lamb_director.gd": ["START", "GATE_MOUTH", "EXIT", "POSTS", "GUARDHOUSE", "TEMPLE_DOOR", "BEATS",
		"CHARGE_PACE", "PATROL_SIZE", "HUNT_AT", "HUNTERS"],
	"res://src/game/mission/first_prayers_director.gd": ["SHRINE_AT", "POOR_SPOT", "PRAY_SECONDS", "MARKET_AT", "MARKET_SECONDS",
		"PRIESTS_AT", "PRIESTS_SECONDS", "FAITHFUL_LAY", "FETCH_R"],
}

## Policy consts and reads that must be gone from the scripted Tier 1 policies (behaviour_check.gd, routes/tier1_b.gd).
const POLICY_BANNED := ["FirstPrayersDirector.MARKET_AT", "FirstPrayersDirector.MARKET_SECONDS", "FirstPrayersDirector.PRIESTS_AT",
	"FirstPrayersDirector.PRIESTS_SECONDS", "FirstPrayersDirector.FETCH_R", "HarvestDirector.STORE_NAMES"]


static func run(t) -> void:
	City.use(&"aldermere")
	_seeded(t)
	_read_not_const(t)
	_policies_read_vars(t)
	_override_survives_setup(t)
	City.use(&"aldermere")
	t.check(City.current().id() == &"aldermere", "the town-vars test leaves Aldermere the active city")


## A fresh director of each of the five has every town var equal to its const (counting_spot INF until _plan()).
static func _seeded(t) -> void:
	var s := StarfallDirector.new()
	t.check(s.star_falls == StarfallDirector.STARS and s.stop_wait == StarfallDirector.STOP_WAIT, "starfall seeded")
	t.check(s.stars.is_empty(), "starfall's `stars` is still the list of warnings (empty before setup)")
	var x := TaxCollectorDirector.new()
	t.check(x.counting_tag == TaxCollectorDirector.COUNTING_TAG and x.counting_spot == Vector2.INF
		and x.rounds == TaxCollectorDirector.ROUNDS and x.set_out_at == TaxCollectorDirector.SET_OUT_AT
		and x.guards == TaxCollectorDirector.GUARDS, "tax collector's own town vars seeded")
	t.check(x.visit_seconds == TaxCollectorDirector.VISIT_SECONDS and x.hide_seconds == TaxCollectorDirector.HIDE_SECONDS
		and x.alarm_reach == TaxCollectorDirector.ALARM_REACH and x.guard_r == TaxCollectorDirector.GUARD_R
		and x.chain_wait == TaxCollectorDirector.CHAIN_WAIT and x.flush_gap == TaxCollectorDirector.FLUSH_GAP,
		"tax collector's base vars seeded in _init")
	var h := HarvestDirector.new()
	t.check(h.store_spots == HarvestDirector.STORE_SPOTS and h.store_names == HarvestDirector.STORE_NAMES
		and h.grain_at == HarvestDirector.GRAIN_AT and h.chain_after == HarvestDirector.CHAIN_AFTER
		and h.load_count == HarvestDirector.LOADS, "harvest seeded")
	t.check(h.loads.is_empty(), "harvest's `loads` is still the per-granary dictionary (empty before setup)")
	var l := LostLambDirector.new()
	t.check(l.charge_start == LostLambDirector.START and l.gate_at == LostLambDirector.GATE_MOUTH
		and l.exit_at == LostLambDirector.EXIT and l.return_to == LostLambDirector.TEMPLE_DOOR
		and l.guardhouse == LostLambDirector.GUARDHOUSE and l.hunt_at == LostLambDirector.HUNT_AT
		and l.hunt_size == LostLambDirector.HUNTERS and l.patrol_size == LostLambDirector.PATROL_SIZE
		and is_equal_approx(l.charge_pace, LostLambDirector.CHARGE_PACE), "lamb's base vars seeded in _init")
	t.check(l.watch_posts.size() == LostLambDirector.POSTS.size() and l.watch_posts[0] == LostLambDirector.POSTS[0]
		and l.watch_posts[1] == LostLambDirector.POSTS[1], "lamb's watch posts seeded (a typed array, by assign)")
	t.check(l.beat_spots == LostLambDirector.BEATS and l.beats.is_empty(), "lamb's beat spots seeded; `beats` built at _plan()")
	var p := FirstPrayersDirector.new()
	t.check(p.shrine_at == FirstPrayersDirector.SHRINE_AT and p.poor_spot == FirstPrayersDirector.POOR_SPOT
		and p.market_at == FirstPrayersDirector.MARKET_AT and p.market_seconds == FirstPrayersDirector.MARKET_SECONDS
		and p.priests_at == FirstPrayersDirector.PRIESTS_AT and p.priests_seconds == FirstPrayersDirector.PRIESTS_SECONDS
		and p.faithful_lay == FirstPrayersDirector.FAITHFUL_LAY and p.fetch_r == FirstPrayersDirector.FETCH_R
		and p.read_seconds == FirstPrayersDirector.PRAY_SECONDS, "first prayers seeded")


## Outside const, var and _init() lines (comments and string literals stripped) no listed const is read in a director's code.
static func _read_not_const(t) -> void:
	for path: String in SCRIPTS:
		var names: Array = SCRIPTS[path]
		var found := PackedStringArray()
		var in_init := false
		var quoted := RegEx.create_from_string("\"[^\"]*\"")
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			if line.begins_with("func "):
				in_init = line.begins_with("func _init(")
			var code := quoted.sub(line, "\"\"", true).get_slice("#", 0)
			if in_init or code.begins_with("const ") or code.begins_with("var "):
				continue
			for n: String in names:
				var re := RegEx.create_from_string("(?<![A-Za-z0-9_.])%s\\b" % n)
				if re.search(code) != null:
					found.append(n)
		t.check(found.is_empty(), "%s reads its town's values through vars (still reads %s)" % [path.get_file(), ", ".join(found)])


## The scripted policies read the director's vars: none of the banned consts, and the old LAMB_WAIT vector, in code.
static func _policies_read_vars(t) -> void:
	for path: String in ["res://tools/dev/behaviour_check.gd", "res://tools/dev/routes/tier1_b.gd"]:
		var found := PackedStringArray()
		var lamb_wait := RegEx.create_from_string("\\bLAMB_WAIT\\b")
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			var code := line.get_slice("#", 0)
			for banned: String in POLICY_BANNED:
				if code.contains(banned):
					found.append(banned)
			if lamb_wait.search(code) != null:
				found.append("LAMB_WAIT")
		t.check(found.is_empty(), "%s reads the director's town vars (still reads %s)" % [path.get_file(), ", ".join(found)])


## An override set before setup survives it, in each of the five (Kit.world sets the director up). The Lamb's snapped gate and exit
## still give the policy its (0, -4) wait exactly.
static func _override_survives_setup(t) -> void:
	var star := StarfallDirector.new()
	star.star_falls = [[5.0, Vector2(1.0, 2.0), "A"], [50.0, Vector2(3.0, 4.0), "B"]]
	star.stop_wait = 12.0
	t.check(star.fall_at(0) == 5.0 and star.star_falls.size() == 2, "starfall's override reads (fall_at, star_falls)")

	var h := HarvestDirector.new()
	h.grain_at = [30.0, 90.0, 150.0]
	h.load_count = 3
	var hs := Kit.world(MissionBook.spoiled_harvest(), h)
	t.check(h.grain_at == [30.0, 90.0, 150.0] and is_equal_approx(h.grain_due(0), 30.0 * h.timeline.stretch_factor()),
		"harvest's first grain is due at the overridden 30 s after setup")
	t.check(not h.targets.is_empty() and int(h.loads[h.targets[0]]) == 3, "harvest's load count survives setup")
	Kit.done(hs)

	var lamb := LostLambDirector.new()
	lamb.hunt_at = 120.0
	var ls := Kit.world(MissionBook.lost_lamb(), lamb)
	t.check(lamb.hunt_at == 120.0, "lamb's hunt_at survives setup")
	t.check(lamb.beats.size() == LostLambDirector.BEATS.size(), "lamb's beats are built from beat_spots at setup")
	t.check((lamb.gate_at - lamb.exit_at).normalized() * 4.0 == Vector2(0.0, -4.0),
		"Aldermere's snapped gate and exit still give the wait (0, -4) exactly (%s)" % str((lamb.gate_at - lamb.exit_at).normalized() * 4.0))
	Kit.done(ls)

	var tax := TaxCollectorDirector.new()
	tax.set_out_at = [10.0, 20.0, 30.0]
	tax.visit_seconds = 33.0
	var ts := Kit.world(MissionBook.tax_collector(), tax)
	t.check(tax.visit_seconds == 33.0, "tax collector's visit_seconds survives setup")
	t.check(not tax.quarries.is_empty() and tax.quarries[0].set_out_at == 10.0, "tax collector's overridden set-out reaches its quarries")
	Kit.done(ts)

	var pr := FirstPrayersDirector.new()
	pr.read_seconds = 20.0
	pr.market_at = 40.0
	var ps := Kit.world(MissionBook.first_prayers(), pr)
	t.check(pr.read_seconds == 20.0 and pr.market_at == 40.0, "first prayers' read_seconds and market_at survive setup")
	Kit.done(ps)
