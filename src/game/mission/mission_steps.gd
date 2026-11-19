class_name MissionSteps
extends RefCounted
## The task line (HUD): the one short "do this now" step under a mission's objectives, kept in view when TAB is collapsed. Data-driven, as
## MissionHints is, and keyed the same way: by the played mission's or act's id, each with its ordered steps. A step is the one the player
## is on while the director sits in one of its `ph` phases (MissionDirector.hint_phase(), the very state the how-to-win line reads); the
## step with no `ph` is the default for every phase the others do not claim. A step is therefore done when the director has left its phase,
## and the next one shows itself. Nothing here decides or changes anything: it only reads Rules, the objectives' rows and the director.
##
## A step: {"t": the imperative label (MAX_LABEL chars at most), "ph": [phases], "c": the live counter}. The counter is "n" (the n / m
## of the first objective row that has one: "0/3"), "s" (the seconds MissionDirector.step_seconds() counts down: "0:35"), or none.

const MAX_LABEL := 32
const COUNT_NONE := ""
const COUNT_N := "n"
const COUNT_S := "s"

## Once a board night's main objective is done (Hud.hint_key(): the wishes, or the ascent), and a Herald running (the Lantern's instant loss).
const ASCEND := {"t": "Ascend when ready: press F"}
const WISHES := {"t": "Grant the open wishes", "c": "w"}
const HERALD := {"t": "Kill the Herald in time"}

const FESTIVAL := [
	{"t": "Kill or scatter the crowd", "c": "n"},
	{"t": "Strike the packed crowd", "ph": ["packed"], "c": "n"},
	{"t": "Kill the Mayor at the fountain", "ph": ["address"], "c": "n"},
]

const PROCESSION := [
	{"t": "Kill the Prince before he boards"},
	{"t": "Strike the Prince at the steps", "ph": ["blessing"]},
	{"t": "Kill him before he boards", "ph": ["dock"]},
]

## Steps by mission or act id, in the order they come.
## (The Feast plays The Long Night's act, so its ids share the acts' steps.)
const STEPS := {
	# --- clarity block: intercept ---
	# The Warning and its acts (The Omen shares the Warning's), and the board's Starfall.
	"warning": [
		{"t": "Kill the messenger unseen"},
		{"t": "Kill the witness unseen", "ph": ["relay"]},
		{"t": "Kill the messenger unseen", "ph": ["stars", "running"], "c": "n"},
		{"t": "Kill the ringer unseen", "ph": ["bell"], "c": "n"},
		{"t": "Watch the next star's gate", "ph": ["waiting"], "c": "n"},
	],
	"omen": [
		{"t": "Kill the messenger unseen"},
		{"t": "Kill the witness unseen", "ph": ["relay"]},
		{"t": "Kill the ringer unseen", "ph": ["bell"]},
	],
	"long_night": [
		{"t": "Stop the messenger unseen"},
	],
	# Tier 2.
	"bell_ringers": [
		{"t": "Kill a ringer unseen", "c": "n"},
		{"t": "Draw his mates off first", "ph": ["mates"], "c": "n"},
		{"t": "Kill the witness unseen", "ph": ["relay"], "c": "n"},
		{"t": "Pull him off the bell", "ph": ["climbing"], "c": "n"},
		{"t": "Stop the bellkeeper", "ph": ["bell"], "c": "n"},
		{"t": "Wait for the next ringer", "ph": ["waiting"], "c": "n"},
	],
	"silence_witness": [
		{"t": "Kill a witness out of sight", "c": "n"},
		{"t": "Stop the mate running on", "ph": ["relay"], "c": "n"},
		{"t": "Stop him before the Temple", "ph": ["near"], "c": "n"},
	],
	"festival": FESTIVAL,
	"feast_festival": FESTIVAL,
	"market_panic": [
		{"t": "Strike the wardens first"},
		{"t": "Remove the last wardens", "ph": ["steadied"]},
		{"t": "Scatter the crowd", "ph": ["open"], "c": "n"},
		{"t": "Strike the crowd on the way", "ph": ["coming"], "c": "n"},
	],
	"procession": PROCESSION,
	"feast_procession": PROCESSION,

	# --- clarity block: assassinate ---
	"informer": [
		{"t": "Turn the contact unseen", "c": "n"},
		{"t": "Draw his company away", "ph": ["waiting"], "c": "n"},
		{"t": "Kill him before the Temple", "ph": ["found", "running"], "c": "n"},
		{"t": "Smoke him out: burn the house", "ph": ["hiding"], "c": "n"},
	],
	# Tier 1.
	"tax_collector": [
		{"t": "Stop the tax collector", "c": "n"},
		{"t": "Seal his door, draw guards off", "ph": ["inside"], "c": "n"},
		{"t": "Burn the counting-house", "ph": ["hiding"], "c": "n"},
		{"t": "Kill him before the Citadel", "ph": ["running", "safe"], "c": "n"},
		{"t": "Be ready for the next collector", "ph": ["next"], "c": "n"},
	],
	# Tier 4.
	"bishop": [
		{"t": "Burn the bishop's refuge", "c": "n"},
		{"t": "Kill the Knights before he comes", "ph": ["waiting"], "c": "s"},
		{"t": "Kill the refuge's Knights", "ph": ["guarded"], "c": "n"},
		{"t": "Set the refuge alight", "ph": ["open"], "c": "n"},
		{"t": "Keep it burning", "ph": ["burning"], "c": "n"},
		{"t": "Kill him before the Citadel", "ph": ["square", "running"]},
	],
	"expel_inquisitor": [
		{"t": "Stop a lantern-warden", "c": "n"},
		{"t": "Kill or frighten the captain", "ph": ["captain"], "c": "n"},
		{"t": "Stop him before the Citadel", "ph": ["near"], "c": "n"},
	],

	# --- clarity block: escort ---
	"lost_lamb": [
		{"t": "Get the acolyte to the gate"},
		{"t": "Clear his road to the gate", "ph": ["running"]},
		{"t": "Lure him on to the west gate", "ph": ["led"]},
		{"t": "Stop the soldier taking him", "ph": ["caught"]},
		{"t": "Draw the watch off the gate", "ph": ["gate"]},
		{"t": "Send him through the gate", "ph": ["clear"]},
	],
	"prisoner": [
		{"t": "Lead her to the postern"},
		{"t": "Remove both gaolers", "ph": ["bound"]},
		{"t": "Stop the man taking her back", "ph": ["caught"]},
		{"t": "Turn the hounds from her", "ph": ["hounds"]},
		{"t": "Draw the watch off the postern", "ph": ["gate"]},
		{"t": "Send her through the postern", "ph": ["clear"]},
	],
	"exodus": [
		{"t": "Lead the household to a gate", "c": "n"},
		{"t": "Stop the man taking him", "ph": ["caught"], "c": "n"},
		{"t": "Turn the searchers away", "ph": ["hounds"], "c": "n"},
		{"t": "Draw the Inquisitors off", "ph": ["gate"], "c": "n"},
		{"t": "Lead them to another gate", "ph": ["shut"], "c": "n"},
		{"t": "Clear the next road", "ph": ["waiting"], "c": "s"},
	],
	"hide_faithful": [
		{"t": "Clear the watch from their road", "c": "n"},
		{"t": "Keep searchers off the household", "ph": ["trail"], "c": "n"},
		{"t": "Stop the man seizing him", "ph": ["seized"], "c": "n"},
	],
	"face_halcyon": [
		{"t": "Break a believer's escort", "c": "n"},
		{"t": "Break his escort at the pyre", "ph": ["pyre"], "c": "n"},
		{"t": "Free them quietly", "ph": ["gaze"], "c": "n"},
	],

	# --- clarity block: raze ---
	"spoiled_harvest": [
		{"t": "Scare its watch before the grain", "ph": ["empty"], "c": "s"},
		{"t": "Scare its watchmen, then burn", "c": "n"},
		{"t": "Kill or lead the watchman (red)", "ph": ["watchman"]},
		{"t": "Keep it burning", "ph": ["burning"], "c": "n"},
	],
	# Tier 3.
	"crowns_bread": [
		{"t": "Be at the next target (grey)", "c": "s"},
		{"t": "Kill or lead its engineers (red)", "ph": ["not_yet"], "c": "s"},
		{"t": "Kill or lead its engineers (red)", "ph": ["engineers"], "c": "n"},
		{"t": "Burn or strike it (gold) down", "ph": ["open"], "c": "n"},
	],
	"armoury": [
		{"t": "Be at the next target (grey)", "c": "s"},
		{"t": "Kill or hold its watch (red)", "ph": ["not_yet"], "c": "s"},
		{"t": "Kill or hold its armed men (red)", "ph": ["guarded"], "c": "n"},
		{"t": "Strike the barracks (gold)", "ph": ["stone"], "c": "n"},
		{"t": "Burn or strike it (gold) down", "ph": ["open"], "c": "n"},
	],
	"heart_of_faith": [
		{"t": "Kill the Knights (red), burn it", "c": "n"},
		{"t": "Kill or hold its Knights (red)", "ph": ["not_yet"], "c": "s"},
		{"t": "Kill or hold its Knights (red)", "ph": ["guarded"], "c": "n"},
		{"t": "Burn it (gold) now", "ph": ["open"], "c": "n"},
		{"t": "Keep it burning", "ph": ["burning"], "c": "n"},
		{"t": "Kill Odran's bearers (red)", "ph": ["coming", "litter"], "c": "s"},
		{"t": "Kill Odran (gold) on the steps", "ph": ["on_foot"]},
		{"t": "Kill or scare Odran (gold) now", "ph": ["rite"], "c": "s"},
	],
	"judgement": [
		{"t": "Strike the Citadel (gold) down"},
		{"t": "Kill or scare the clergy (red)", "ph": ["rite"]},
		{"t": "Kill and burn: break stability", "ph": ["fallen"]},
	],
	"last_judgement": [
		{"t": "Strike the Citadel (gold) down"},
		{"t": "Kill or scare the clergy (red)", "ph": ["rite"]},
		{"t": "Kill and burn: break stability", "ph": ["fallen"]},
	],

	# --- clarity block: hunt ---
	"heretic_hunt": [
		{"t": "Kill or lead its guards (red)", "c": "n"},
		{"t": "Strike or rot it (gold) now", "ph": ["open"], "c": "n"},
		{"t": "Be at the next standard (grey)", "ph": ["waiting"], "c": "s"},
		{"t": "Be at the captain's road", "ph": ["coming"], "c": "s"},
		{"t": "Kill the captain (gold)", "ph": ["captain"]},
		{"t": "Kill the captain (gold) now", "ph": ["searching"]},
	],
	# Tier 5.
	"lantern_eye": [
		{"t": "Kill or lead its guards (red)", "c": "n"},
		{"t": "Strike or rot the mirror (gold)", "ph": ["open"], "c": "n"},
		{"t": "Lead or kill the wrights (red)", "ph": ["shattered"], "c": "s"},
		{"t": "Be at the next mirror (grey)", "ph": ["waiting"], "c": "s"},
		{"t": "Strike or rot a mirror now", "ph": ["eye"], "c": "s"},
	],
	"break_hunt": [
		{"t": "Kill or scare a bearer (gold)", "c": "n"},
		{"t": "Kill or scare the new bearer", "ph": ["carried"], "c": "n"},
		{"t": "Kill or scare a bearer (gold)", "ph": ["taken"], "c": "n"},
	],

	# --- clarity block: convert ---
	"first_prayers": [
		{"t": "Lead the poor (gold) to the well", "c": "n"},
		{"t": "Lead the Faithful (red) away", "ph": ["watched"], "c": "n"},
	],
	# The Lantern campaign.
	"miras_house": [
		{"t": "Lead the grieving (gold) to Mira", "c": "n"},
		{"t": "Ascend, or wait for dawn", "ph": ["four"]},
		{"t": "Keep believers (orange) alive", "ph": ["burning"], "c": "n"},
	],
	"sermon": [
		{"t": "Lead a listener (gold) in", "c": "n"},
		{"t": "Confuse or scare the preacher", "ph": ["rapt"], "c": "n"},
		{"t": "Lead the latecomers (gold) in", "ph": ["coming"], "c": "n"},
		{"t": "Lead or confuse the sentries", "ph": ["watched"], "c": "n"},
		{"t": "Kill the runner (red) unseen", "ph": ["report"]},
		{"t": "No more seen deaths", "ph": ["seen"]},
		{"t": "Kill the bellkeeper (red) unseen", "ph": ["bell"]},
	],
	"vigil_flame": [
		{"t": "Lead the acolytes off", "c": "s"},
		{"t": "Lead Wren (blue) to the flame", "ph": ["wren"]},
		{"t": "Lead Wren (blue) to the flame", "ph": ["homeward"]},
		{"t": "Lead Wren to the shrine (orange)", "ph": ["carry"]},
	],
	"relic_run": [
		{"t": "Lead Pip (blue) to the halt"},
		{"t": "Lead or kill the watch (red)", "ph": ["moving"]},
		{"t": "Lead or kill the watch (red)", "ph": ["watched"]},
		{"t": "Lead or kill the watch (red)", "ph": ["aboard"]},
		{"t": "Lead Pip home (orange), unlit", "ph": ["carry"]},
		{"t": "Lead Pip (blue) to the last halt", "ph": ["last_halt"]},
		{"t": "The relic is lost at the Citadel", "ph": ["citadel"]},
		{"t": "Kill the runner (red) unseen", "ph": ["report"]},
		{"t": "No more seen deaths", "ph": ["seen"]},
		{"t": "Kill the bellkeeper (red) unseen", "ph": ["bell"]},
	],
	"broken_lanterns": [
		{"t": "Strike a lantern (gold) down", "c": "n"},
		{"t": "Lead or kill its Knight (blue)", "ph": ["knights"], "c": "n"},
	],
	# The rite and the Lantern Hunts (god progression).
	"first_taste": [
		{"t": "Press C, click a lamplighter", "c": "n"},
		{"t": "Hold or kill the Watch (red)", "ph": ["drag"], "c": "n"},
		{"t": "Kill or scare the marchers (red)", "ph": ["march"], "c": "n"},
		{"t": "Kill or scare a kneeler (red)", "ph": ["cleanse"]},
	],

	# --- the rest (free play, the Lantern campaign) ---
	# Free play: nothing to win, so the HUD draws no line (Rules.free_play), but the table is whole.
	"capital_sandbox": [
		{"t": "Play freely"},
	],
	"remembrance": [
		{"t": "Try the power"},
	],
}

static var _count_re: RegEx = null


## The steps of mission or act `id` (a composite `<id>@<city>` is its base's); empty for an unknown one.
static func steps(id: String) -> Array:
	return STEPS.get(MissionBook.split_city(id)[0], [])


## Whether `step` names `phase` (a step with no `ph` is the default, taken when no step names it: index_for()).
static func _claims(step: Dictionary, phase: String) -> bool:
	return step.has("ph") and phase in (step["ph"] as Array)


## The index in `steps` of the step to show in `phase`: the first that names the phase, else the first with none; -1 for no steps.
static func index_for(list: Array, phase: String) -> int:
	for i in list.size():
		if _claims(list[i], phase):
			return i
	for i in list.size():
		if not (list[i] as Dictionary).has("ph"):
			return i
	return -1


## The director's phase now: what the how-to-win line keys on.
static func _phase(rules: Rules) -> String:
	return rules.director.hint_phase() if rules.director != null else ""


## The step for the night as it stands, as {"t": label, "count": counter text or "", "index": its place in the mission's steps, "of": how
## many steps it has}; empty for none (no mission, a night in free play, nothing to say).
static func current(rules: Rules) -> Dictionary:
	if rules == null or rules.mission == null or rules.free_play:
		return {}
	var list := steps(rules.mission.id)
	if list.is_empty():
		return {}
	var step: Dictionary
	var index := -1
	# The Herald (the Lantern's instant loss) outranks everything, as the how-to-win line does (Hud.hint_key()).
	if rules.lantern != null and rules.lantern.hint_phase() in ["herald", "herald_silent"]:
		step = HERALD
	elif rules.main_done and rules.descent != null:
		step = WISHES if _open_wishes(rules) else ASCEND
	else:
		index = index_for(list, _phase(rules))
		if index < 0:
			return {}
		step = list[index]
	return {"t": String(step["t"]), "count": _count(rules, String(step.get("c", COUNT_NONE))), "index": index, "of": list.size()}


## The task line's text: the label, then its counter when it has one; "" for none.
static func line(rules: Rules) -> String:
	var cur := current(rules)
	if cur.is_empty():
		return ""
	var count := String(cur["count"])
	return String(cur["t"]) if count == "" else "%s %s" % [cur["t"], count]


## A step's counter. "n": the n/m of the first objective row that has one; "s": the director's wait as a clock; "w": wishes granted/heard.
static func _count(rules: Rules, kind: String) -> String:
	match kind:
		COUNT_N:
			return _objective_count(rules)
		COUNT_S:
			var secs := rules.director.step_seconds() if rules.director != null else 0.0
			return UiTheme.clock(secs) if secs > 0.0 else ""
		"w":
			var heard := 0
			var granted := 0
			for w in rules.descent.wishes:
				heard += 1
				if w.status == Objective.Status.DONE:
					granted += 1
			return "%d/%d" % [granted, heard]
	return ""


## "n/m" from the first objective whose HUD row holds "n / m" (or "n/m"); "" when none does.
static func _objective_count(rules: Rules) -> String:
	if _count_re == null:
		_count_re = RegEx.create_from_string("(\\d+)\\s*/\\s*(\\d+)")
	for o in rules.objectives:
		var hit := _count_re.search(o.hud_text(rules))
		if hit != null:
			return "%s/%s" % [hit.get_string(1), hit.get_string(2)]
	return ""


## A wish of the night is still open (Hud._open_wishes()).
static func _open_wishes(rules: Rules) -> bool:
	for w in rules.descent.wishes:
		if w.status == Objective.Status.PENDING:
			return true
	return false
