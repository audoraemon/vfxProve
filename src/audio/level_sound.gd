class_name LevelSound
extends RefCounted
## A power is heard heavier as it climbs its levels (skill-tree sound pass). While a power's own code runs (its _build,
## its events, its frame; FxTimeline sets FxContext.level), every cue it plays is LEVEL_DB louder and LEVEL_PITCH lower
## per level above 1, so a level-5 power sounds bigger and its tail longer. From WEIGHT_FROM on, its main cue (MAIN) also
## carries its school's weight (WEIGHT): a low swell and a long tail under it, stronger at level 5.

const LEVEL_DB := 0.5
const LEVEL_PITCH := 0.015
const WEIGHT_FROM := 4
## The weight's offset from the main cue's own call at WEIGHT_FROM; each level above adds WEIGHT_STEP.
const WEIGHT_DB := -6.0
const WEIGHT_STEP := 3.0

## Each school's weight: a low swell in its own palette, played under a high-level power's main cue.
const WEIGHT := {
	"ruin": &"lvl_ruin", "passage": &"lvl_passage", "veil": &"lvl_veil",
	"decree": &"lvl_decree", "death": &"lvl_death", "dominion": &"lvl_dominion",
}

## Every skill-tree power's main cue and school: its loudest played cue (`python tools/audio/loudness.py --table`), or its cast
## where that is a loop or plays only sometimes (Tornado, the Serpent, the Wisp, SAINT, Evernight).
const MAIN := {
	"smite": [&"smite_strike", "ruin"], "ember": [&"q_ember_hit", "ruin"], "tornado": [&"tn_form", "ruin"], "scatter": [&"scatter_boom", "ruin"], "solaris": [&"solar_blaze", "ruin"], "dragon": [&"dr_ignite", "ruin"], "tsunami": [&"ts_rise", "ruin"], "cinder": [&"cf_rise", "ruin"], "tempest": [&"sky_clap", "ruin"], "shatter": [&"quake_open", "ruin"],
	"skylift": [&"q_skylift", "passage"], "windfall": [&"wf_impact", "passage"], "houndgate": [&"hg_doors", "passage"], "hellspark": [&"hm_ignite", "passage"], "deep": [&"deep_burst", "passage"], "mirror": [&"q_mirror", "passage"], "allroads": [&"q_allroads", "passage"], "foldward": [&"q_foldward", "passage"], "deaddoors": [&"dead_door", "passage"], "heavendoor": [&"hd_land", "passage"],
	"doom": [&"q_doom", "veil"], "blight": [&"q_blight", "veil"], "slumber": [&"v_slumber", "veil"], "cloak": [&"v_cloak", "veil"], "unseen": [&"q_unseen", "veil"], "dreamless": [&"v_dreamless", "veil"], "dread": [&"v_dread", "veil"], "shadowplay": [&"v_shadowplay", "veil"], "swallow": [&"v_swallow_take", "veil"], "evernight": [&"v_evernight", "veil"],
	"noleave": [&"q_noleave", "decree"], "breath": [&"br_hush", "decree"], "redefine": [&"q_redefine", "decree"], "bound": [&"q_bound", "decree"], "erase": [&"er_crash", "decree"], "disorder": [&"di_bell", "decree"], "eminent": [&"ed_roar", "decree"], "fenced": [&"fe_posts", "decree"], "cage": [&"cg_shut", "decree"], "sealed": [&"q_sealed_hit", "decree"],
	"deathmark": [&"q_deathmark_hit", "death"], "raise": [&"raise_rise", "death"], "pestilence": [&"q_pestilence", "death"], "gravecall": [&"gravecall_rise", "death"], "guise": [&"q_guise", "death"], "walker": [&"q_walker", "death"], "gatebelow": [&"gatebelow_open", "death"], "pale": [&"pale_drone", "death"], "serpent": [&"serpent_rise", "death"], "gravetide": [&"gravetide_rise", "death"],
	"whisper": [&"q_whisper", "dominion"], "discord": [&"q_discord", "dominion"], "madness": [&"q_madness", "dominion"], "wisp": [&"q_wisp", "dominion"], "clearmind": [&"q_clearmind", "dominion"], "saint": [&"q_saint", "dominion"], "sanctuary": [&"q_sanctuary", "dominion"], "anathema": [&"q_anathema", "dominion"], "voice": [&"dom_speak", "dominion"], "schism": [&"dom_break", "dominion"],
}

static var _key_by_path: Dictionary = {}


## The power key an effect script belongs to ("" for an effect that is not a power).
static func key_of(script: Script) -> String:
	if script == null:
		return ""
	if _key_by_path.is_empty():
		for p: Dictionary in PowerBook.POWERS:
			_key_by_path[String(p.get("path", ""))] = String(p.key)
	return _key_by_path.get(script.resource_path, "")


## The cue under which a high level is heard, and its weight: [main cue, weight cue], or [&"", &""].
static func main_and_weight(key: String) -> Array:
	if not MAIN.has(key):
		return [&"", &""]
	var row: Array = MAIN[key]
	return [row[0], WEIGHT.get(row[1], &"")]


## The level's offset and pitch for a cue a power plays at `level`.
static func db_for(level: int) -> float:
	return LEVEL_DB * float(clampi(level, 1, PowerBook.MAX_LEVEL) - 1)


static func pitch_for(level: int) -> float:
	return 1.0 - LEVEL_PITCH * float(clampi(level, 1, PowerBook.MAX_LEVEL) - 1)


## The weight's offset over the main cue's call, at `level` (only from WEIGHT_FROM).
static func weight_db(level: int) -> float:
	return WEIGHT_DB + WEIGHT_STEP * float(clampi(level, 1, PowerBook.MAX_LEVEL) - WEIGHT_FROM)
