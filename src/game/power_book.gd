class_name PowerBook
extends RefCounted
## The draftable powers: Might price, cooldown (seconds), how they are aimed, their effect script and icons, and
## their Authority (v0.08: the draft's tabs).
## Prices are the loadout budget (v0.08): a mission's draft may spend its Might capacity on them, and nothing
## is spent once the mission runs. Cooldowns follow spec §2's rule of thumb, the larger of the old cooldown and 3x
## the old DP cost. Aim "drag" = press at the start point, drag the direction, release; aim "whisper" (v0.08) = press
## on a person, drag to where they should go, release; aim "two clicks" = one click for each of the power's two places
## (Mirrorfold Passage, Divine Congregation). The quiet powers (v0.05, "quiet") register no danger for the
## town and raise no alarm when cast (Crowd.on_cast()): Silent Doom's deaths count only if someone saw them, Blight
## adds one alarm; a quiet power with an "alarm" unsettles the town by that much when cast. A power with "modes" is cast
## in one of them (Targeting: Q and E step through them; the effect is told which in extra["mode"]); a mode may aim
## its own way ("aim") and cover its own ground ("area").

const POWERS := [
	{"key": "doom", "name": "Silent Doom", "path": "res://src/fx/quiet/silent_doom.gd",
		"dp": 1, "cooldown": 10.0, "aim": "click", "shape": "everyone within reach struck down, unseen", "quiet": true,
		"authority": "veil"},
	{"key": "whisper", "name": "Mind Whisper", "path": "res://src/fx/dominion/mind_whisper.gd",
		"dp": 1, "cooldown": 8.0, "aim": "whisper",
		"shape": "send one person somewhere, then they linger 8 s; not the same one again for 20 s", "quiet": true,
		"authority": "dominion"},
	{"key": "smite", "name": "Smite", "path": "res://src/fx/ruin/smite.gd",
		"dp": 1, "cooldown": 10.0, "aim": "click", "shape": "one bolt: whoever stands there, and a blow to one building",
		"authority": "ruin"},
	{"key": "ember", "name": "Ember", "path": "res://src/fx/ruin/ember.gd",
		"dp": 1, "cooldown": 15.0, "aim": "click", "shape": "one spark that sets one building alight", "quiet": true,
		"authority": "ruin"},
	{"key": "deathmark", "name": "Death Mark", "path": "res://src/fx/death/death_mark.gd",
		"dp": 1, "cooldown": 20.0, "aim": "click", "shape": "one grows frail and slow, dies in 10 s; the body draws a crowd",
		"quiet": true, "authority": "death"},
	{"key": "noleave", "name": "Leaving Is Prohibited", "path": "res://src/fx/decree/leaving_is_prohibited.gd",
		"dp": 1, "cooldown": 20.0, "aim": "click", "shape": "nobody in the circle can leave it, 15 s",
		"quiet": true, "alarm": 0.5, "authority": "decree"},
	{"key": "wisp", "name": "Will-o'-Wisp", "path": "res://src/fx/control/will_o_wisp.gd",
		"dp": 2, "cooldown": 30.0, "aim": "click", "shape": "lures up to 25 calm people, 12 s", "quiet": true,
		"authority": "dominion"},
	{"key": "discord", "name": "Discord", "path": "res://src/fx/quiet/discord.gd",
		"dp": 2, "cooldown": 30.0, "aim": "click", "shape": "people forget their task, 15 s", "quiet": true,
		"authority": "dominion"},
	{"key": "belllies", "name": "The Bell Lies", "path": "res://src/fx/decree/the_bell_lies.gd",
		"dp": 2, "cooldown": 60.0, "aim": "click", "shape": "the bell tolls all is well, now and for 45 s; or calls the guard to a place; Q/E",
		"quiet": true, "authority": "decree", "modes": [
			{"key": "well", "name": "ALL IS WELL"}, {"key": "guard", "name": "CALL THE GUARD", "area": {"r": 1.5}}]},
	{"key": "heaven", "name": "Heaven Splitter", "path": "res://src/fx/set2/heaven_splitter.gd",
		"dp": 2, "cooldown": 30.0, "aim": "drag", "shape": "line + 8 fissures", "authority": "ruin"},
	{"key": "madness", "name": "Madness Bloom", "path": "res://src/fx/curse/madness_bloom.gd",
		"dp": 2, "cooldown": 40.0, "aim": "click", "shape": "a madness that grows, spreads and breaks into frenzy",
		"quiet": true, "alarm": 0.2, "authority": "dominion"},
	{"key": "blight", "name": "Blight", "path": "res://src/fx/quiet/blight.gd",
		"dp": 2, "cooldown": 36.0, "aim": "click", "shape": "ruins a well, bell, gate, dock or rite", "quiet": true,
		"authority": "veil"},
	{"key": "thorns", "name": "Thornwall", "path": "res://src/fx/control/thornwall.gd",
		"dp": 2, "cooldown": 42.0, "aim": "drag", "shape": "3-unit bramble wall, 25 s", "quiet": true,
		"authority": "passage"},
	{"key": "tornado", "name": "Tornado Tempest", "path": "res://src/fx/set2/tornado_tempest.gd",
		"dp": 3, "cooldown": 45.0, "aim": "click", "shape": "roaming vortex, 10 s", "authority": "ruin"},
	{"key": "pestilence", "name": "Pestilence", "path": "res://src/fx/curse/pestilence.gd",
		"dp": 3, "cooldown": 48.0, "aim": "click", "shape": "a fast plague spreading through crowds", "quiet": true,
		"authority": "death"},
	{"key": "dragon", "name": "Dragonfire Parade", "path": "res://src/fx/set2/dragonfire_parade.gd",
		"dp": 3, "cooldown": 54.0, "aim": "click", "shape": "cone, faces down-right on screen", "authority": "ruin"},
	{"key": "mirror", "name": "Mirrorfold Passage", "path": "res://src/fx/control/mirrorfold_passage.gd",
		"dp": 3, "cooldown": 54.0, "aim": "two clicks", "shape": "two faint mirrors: in at the first, out at the second, 30 s",
		"quiet": true, "authority": "passage"},
	{"key": "magnify", "name": "Magnify", "path": "res://src/fx/decree/magnify.gd",
		"dp": 3, "cooldown": 75.0, "aim": "click", "shape": "doubles what is already there: fires, cracks, madness, spells",
		"quiet": true, "alarm": 1.0, "authority": "decree"},
	{"key": "congregation", "name": "Divine Congregation", "path": "res://src/fx/dominion/divine_congregation.gd",
		"dp": 4, "cooldown": 60.0, "aim": "two clicks", "shape": "a district walks to the place of the first click, 25 s",
		"quiet": true, "alarm": 0.3, "authority": "dominion"},
	{"key": "oath", "name": "Oathbound", "path": "res://src/fx/dominion/oathbound.gd",
		"dp": 2, "cooldown": 45.0, "aim": "click", "shape": "binds up to four to stay, or to hold a place, 60 s; Q/E",
		"quiet": true, "authority": "dominion", "modes": [
			{"key": "remain", "name": "REMAIN"},
			{"key": "hold", "name": "HOLD A PLACE", "aim": "two clicks", "area": {"shape": "pick"}}]},
	{"key": "echo", "name": "Command Echo", "path": "res://src/fx/dominion/command_echo.gd",
		"dp": 2, "cooldown": 45.0, "aim": "click", "shape": "a command planted in a few that passes from one to the next; Q/E",
		"quiet": true, "alarm": 0.2, "authority": "dominion", "modes": [
			{"key": "home", "name": "GO HOME"},
			{"key": "go", "name": "GO THERE", "aim": "two clicks", "area": {"shape": "pick"}}]},
	{"key": "turncoat", "name": "Turncoat", "path": "res://src/fx/dominion/turncoat.gd",
		"dp": 3, "cooldown": 60.0, "aim": "click", "shape": "one turns on its own side: a soldier fights, another sabotages, 30 s",
		"quiet": true, "authority": "dominion"},
	{"key": "hatred", "name": "Manufactured Hatred", "path": "res://src/fx/dominion/manufactured_hatred.gd",
		"dp": 3, "cooldown": 60.0, "aim": "click", "shape": "a group comes to hate one kind, and goes for them; Q/E picks whom",
		"quiet": true, "alarm": 0.5, "authority": "dominion", "modes": [
			{"key": "soldier", "name": "THE GUARD"}, {"key": "clergy", "name": "THE CLERGY"},
			{"key": "engineer", "name": "THE ENGINEERS"}]},
	{"key": "priority", "name": "Rewrite Priority", "path": "res://src/fx/dominion/rewrite_priority.gd",
		"dp": 4, "cooldown": 75.0, "aim": "click", "shape": "a district puts one thing above all else, 25 s; Q/E picks it",
		"quiet": true, "alarm": 1.0, "authority": "dominion", "modes": [
			{"key": "work", "name": "WORK"}, {"key": "worship", "name": "WORSHIP"}, {"key": "hide", "name": "HIDE"},
			{"key": "escape", "name": "ESCAPE"}, {"key": "ignore", "name": "IGNORE"}]},
	{"key": "verdict", "name": "Mob Verdict", "path": "res://src/fx/dominion/mob_verdict.gd",
		"dp": 4, "cooldown": 90.0, "aim": "two clicks", "shape": "a district judges the one, or the building, of the first click",
		"quiet": true, "alarm": 2.0, "authority": "dominion"},
	{"key": "delusion", "name": "Collective Delusion", "path": "res://src/fx/dominion/collective_delusion.gd",
		"dp": 4, "cooldown": 90.0, "aim": "click", "shape": "a district believes a danger that is not there, or that all is well",
		"quiet": true, "authority": "dominion", "modes": [
			{"key": "danger", "name": "FALSE DANGER"}, {"key": "calm", "name": "ALL IS WELL", "area": {"r": 7.0}}]},
	{"key": "tsunami", "name": "Tsunami Breaker", "path": "res://src/fx/set2/tsunami_breaker.gd",
		"dp": 4, "cooldown": 60.0, "aim": "drag", "shape": "moving wall", "authority": "ruin"},
	{"key": "gravity", "name": "Gravity Distortion", "path": "res://src/fx/gravity_distortion.gd",
		"dp": 3, "cooldown": 60.0, "aim": "click", "shape": "pull field", "authority": "ruin"},
	{"key": "laser", "name": "Walking Laser Grid", "path": "res://src/fx/walking_laser_grid.gd",
		"dp": 3, "cooldown": 66.0, "aim": "drag", "shape": "moving lane", "authority": "ruin"},
	{"key": "orbital", "name": "Orbital Strike", "path": "res://src/fx/orbital_strike.gd",
		"dp": 3, "cooldown": 66.0, "aim": "click", "shape": "random bombardment", "authority": "ruin"},
	{"key": "cinder", "name": "Cinderfall Barrage", "path": "res://src/fx/set2/cinderfall_barrage.gd",
		"dp": 4, "cooldown": 75.0, "aim": "click", "shape": "volcano + stone rain", "authority": "ruin"},
	{"key": "judgement", "name": "Judgement of the Ancients", "path": "res://src/fx/set2/judgement_of_the_ancients.gd",
		"dp": 4, "cooldown": 90.0, "aim": "click", "shape": "8 punches + slam", "authority": "ruin"},
	{"key": "glacial", "name": "Glacial Cataclysm", "path": "res://src/fx/set2/glacial_cataclysm.gd",
		"dp": 4, "cooldown": 90.0, "aim": "click", "shape": "burst + freeze + ice", "authority": "ruin"},
	{"key": "solaris", "name": "Light of Solaris", "path": "res://src/fx/solaris/light_of_solaris.gd",
		"dp": 4, "cooldown": 105.0, "aim": "click", "shape": "5 s pillar of sunfire; leaves a pit that takes all who enter",
		"authority": "ruin"},
	{"key": "voice", "name": "Voice of God", "path": "res://src/fx/dominion/voice_of_god.gd",
		"dp": 5, "cooldown": 180.0, "aim": "click", "shape": "one command the whole town obeys; Q/E picks it",
		"quiet": true, "alarm": 6.0, "authority": "dominion", "modes": [
			{"key": "kneel", "name": "KNEEL"}, {"key": "halt", "name": "HALT"}, {"key": "flee", "name": "FLEE"},
			{"key": "gather", "name": "GATHER"}, {"key": "return", "name": "RETURN"}, {"key": "silence", "name": "SILENCE"},
			{"key": "judge", "name": "JUDGE"}]},
	{"key": "abolition", "name": "Abolition", "path": "res://src/fx/decree/abolition.gd",
		"dp": 5, "cooldown": 999.0, "aim": "click", "shape": "one law is void for 15 s: the clock (time stops), the escape limit, the ward; Q/E; once",
		"quiet": true, "alarm": 4.0, "authority": "decree", "modes": [
			{"key": "clock", "name": "THE CLOCK"}, {"key": "escape", "name": "THE ESCAPE LIMIT"},
			{"key": "ward", "name": "THE CITADEL'S WARD"}]},
	{"key": "schism", "name": "Divine Schism", "path": "res://src/fx/dominion/divine_schism.gd",
		"dp": 6, "cooldown": 999.0, "aim": "click", "shape": "two sides, each sure the other is the enemy; once a descent",
		"authority": "dominion", "modes": [
			{"key": "faction", "name": "FACTION SPLIT"}, {"key": "purge", "name": "PURGE", "area": {"r": 1.5}},
			{"key": "custom", "name": "CUSTOM", "aim": "two clicks", "area": {"shape": "regions", "r": 5.0}},
			{"key": "spreading", "name": "SPREADING", "area": {"r": 3.0}}]},
	{"key": "nova", "name": "Nuclear Nova", "path": "res://src/fx/nuclear_nova.gd",
		"dp": 4, "cooldown": 120.0, "aim": "click", "shape": "huge circle", "authority": "ruin"},
]
const ICON_DIR := "res://assets/pixellab/icons/"
## Preview clips for the draft: each power recorded once from the sandbox (bash tools/capture.sh --capture-clip)
## into one sprite sheet -- CLIP_FRAMES frames spread over the whole effect, CLIP_COLUMNS to a row.
const CLIP_DIR := "res://assets/clips/"
const CLIP_FRAMES := 16
const CLIP_COLUMNS := 4
const CLIP_SIZE := Vector2i(152, 86)
## How fast the draft plays a clip: 16 frames at 8 a second is a two-second time-lapse of the whole power.
const CLIP_FPS := 8.0


## How far each power is seen and heard, how severe it is and how long it stays dangerous (v0.04 local awareness):
## [sight, sound, severity, seconds]. People inside its area plus Person.THREAT_MARGIN run clear of it; within sight
## or earshot they stop and look; beyond that they go on with their day.
const REACH := {
	"heaven": [6.0, 9.0, 0.5, 3.0], "tornado": [8.0, 11.0, 0.6, 10.0], "dragon": [8.0, 11.0, 0.6, 5.0],
	"tsunami": [8.0, 12.0, 0.7, 5.0], "gravity": [6.0, 9.0, 0.6, 6.0], "laser": [7.0, 10.0, 0.6, 6.0],
	"orbital": [9.0, 14.0, 0.7, 6.0], "cinder": [10.0, 16.0, 0.8, 8.0], "judgement": [9.0, 14.0, 0.8, 6.0],
	"glacial": [8.0, 12.0, 0.7, 6.0], "solaris": [12.0, 16.0, 0.9, 6.5], "smite": [5.0, 9.0, 0.4, 2.0], "schism": [14.0, 18.0, 0.8, 8.0],
	"nova": [40.0, 40.0, 1.0, 4.0],
}
## When each loud power first kills (v0.11.2, spec §3.2): seconds after the cast, read from its effect script's own constants
## (tests/test_awareness.gd checks each). A loud power's danger counts from here (Crowd.on_cast()); the town looks at the
## build-up until then. Quiet powers (Ember too) register no danger and have none.
const IMPACT := {
	"smite": 0.35, "heaven": 1.4, "tornado": 1.0, "dragon": 1.2, "tsunami": 1.9, "gravity": 0.8, "laser": 2.0,
	"orbital": 1.45, "cinder": 1.2, "judgement": 2.0, "glacial": 1.2, "solaris": 1.2, "schism": 1.8, "nova": 2.3,
}
## For a cast with no known power (the sandbox, scripted tests): v0.03's single 7-unit fright, heard to 10.
const REACH_DEFAULT := [7.0, 10.0, 0.6, 4.0]


## Seconds from a loud power's cast to its first impact (IMPACT), 0.0 for any other key.
static func impact(key: String) -> float:
	return float(IMPACT.get(key, 0.0))


static func get_power(key: String) -> Dictionary:
	for p: Dictionary in POWERS:
		if p.key == key:
			return p
	return {}


## The highest ability level (god P1, spec §5.4): levels run 1 to MAX_LEVEL.
const MAX_LEVEL := 5
## The levels at which a power costs one more Might (spec §6): reaching 3 adds 1, reaching 5 adds 1.
const MIGHT_STEPS := [3, 5]
## What level_change() says for a power whose row has no `levels` table yet (god P1: no row has one).
const NO_LEVELS := "Level effects not set"
## The keys a level table holds besides stats: level 5's twist flag and its one-line text.
const TWIST_KEYS := ["twist", "twist_text"]


## What a power costs in Might at a level (spec §6): its `dp` plus one for each MIGHT_STEPS entry the level has reached.
## The level is clamped to 1-MAX_LEVEL; 0 for an unknown key. (The "dp" field keeps its name, ruling C1.)
static func might(key: String, level := 1) -> int:
	var p := get_power(key)
	if p.is_empty():
		return 0
	var lv := clampi(level, 1, MAX_LEVEL)
	var total := int(p.get("dp", 0))
	for step: int in MIGHT_STEPS:
		if step <= lv:
			total += 1
	return total


## True when the power's row has a `levels` table (an Array of MAX_LEVEL Dictionaries, index 0 = level 1, each mapping a stat name
## to the number its effect reads; index 4 also holds "twist": true and "twist_text").
static func has_levels(key: String) -> bool:
	return not _table(get_power(key)).is_empty()


## A row's levels table, or an empty Array when it has none.
static func _table(entry: Dictionary) -> Array:
	var t: Variant = entry.get("levels")
	return t as Array if t is Array else []


## The entry's value for `stat` at `level` (clamped 1-MAX_LEVEL) when it has a table naming that stat, else `base`.
static func stat_in(entry: Dictionary, level: int, stat: String, base: Variant) -> Variant:
	var table := _table(entry)
	if table.is_empty():
		return base
	var row: Variant = table[clampi(level, 1, table.size()) - 1]
	if row is Dictionary and (row as Dictionary).has(stat):
		return (row as Dictionary)[stat]
	return base


## A power's number for `stat` at `level`: its table's value, or `base` (the effect's own constant) without one.
static func level_stat(key: String, level: int, stat: String, base: Variant) -> Variant:
	return stat_in(get_power(key), level, stat, base)


## What an effect calls for each number its level may change: `PowerBook.stat(extra, "<key>", "<stat>", CONST)`. The level is
## extra["level"] (Rules.cast() puts it on every cast), 1 when absent. A power with no table plays exactly as it always did.
static func stat(extra: Dictionary, key: String, stat_name: String, base: Variant) -> Variant:
	return level_stat(key, int(extra.get("level", 1)), stat_name, base)


## The one-line twist a power gains at level 5, or "" for a power without one.
static func twist(key: String) -> String:
	return twist_in(get_power(key))


## The entry's level-5 twist text ("" when it has no table or no twist).
static func twist_in(entry: Dictionary) -> String:
	var table := _table(entry)
	if table.size() < MAX_LEVEL:
		return ""
	var top: Variant = table[MAX_LEVEL - 1]
	if top is Dictionary and bool((top as Dictionary).get("twist", false)):
		return String((top as Dictionary).get("twist_text", ""))
	return ""


## What reaching `level` changes for a power, as the tables give it: "radius 1.5 -> 1.7, damage 40 -> 46" (level 5 ends with the
## twist text); "" at level 1; NO_LEVELS for a power without a table.
static func level_change(key: String, level: int) -> String:
	return level_change_in(get_power(key), level)


## level_change() for a row given directly.
static func level_change_in(entry: Dictionary, level: int) -> String:
	var table := _table(entry)
	if table.is_empty():
		return NO_LEVELS
	if level < 2:
		return ""
	var lv := mini(level, table.size())
	var before: Dictionary = table[lv - 2]
	var after: Dictionary = table[lv - 1]
	var parts := PackedStringArray()
	for name: String in after:
		if TWIST_KEYS.has(name):
			continue
		if not before.has(name) or before[name] != after[name]:
			parts.append("%s %s -> %s" % [name, str(before.get(name, "?")), str(after[name])])
	if lv == MAX_LEVEL and twist_in(entry) != "":
		parts.append(twist_in(entry))
	return ", ".join(parts)


## What is wrong with a row's levels table; empty when valid: MAX_LEVEL tables, every stat named in all of them with one kind of
## value (numbers count as one kind), and the twist ("twist": true plus a non-empty "twist_text") at level 5 only.
static func levels_problems(entry: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var table := _table(entry)
	var label := String(entry.get("key", "?"))
	if table.size() != MAX_LEVEL:
		out.append("%s: needs %d level tables, has %d" % [label, MAX_LEVEL, table.size()])
		return out
	var names := {}
	for i in table.size():
		if not table[i] is Dictionary:
			out.append("%s: level %d is not a Dictionary" % [label, i + 1])
			return out
		for name: String in (table[i] as Dictionary):
			if not TWIST_KEYS.has(name):
				names[name] = true
	for name: String in names:
		var kind := -1
		for i in table.size():
			var row: Dictionary = table[i]
			if not row.has(name):
				out.append("%s: stat %s is missing at level %d" % [label, name, i + 1])
				continue
			var k := typeof(row[name])
			k = TYPE_FLOAT if k == TYPE_INT else k
			if kind >= 0 and k != kind:
				out.append("%s: stat %s changes type at level %d" % [label, name, i + 1])
			kind = k
	for i in table.size():
		var row: Dictionary = table[i]
		if i < MAX_LEVEL - 1:
			if row.has("twist") or row.has("twist_text"):
				out.append("%s: only level %d may carry a twist (level %d does)" % [label, MAX_LEVEL, i + 1])
		else:
			if not (row.has("twist") and row["twist"] == true):
				out.append("%s: level %d needs \"twist\": true" % [label, MAX_LEVEL])
			if String(row.get("twist_text", "")).strip_edges() == "":
				out.append("%s: level %d needs a twist_text" % [label, MAX_LEVEL])
	return out


## Decree rules the rules themselves: what is allowed, what is true, what is law (prohibit, distort, abolish).
## Dominion holds what was Disorder too: to command a mind and to break one are the same Authority.
## The Authorities (v0.08; before, the kinds): what a power commands, and the draft's tabs, in tab order.
const AUTHORITIES := ["ruin", "veil", "dominion", "passage", "decree", "death"]
## Their titles, index for index.
const AUTHORITY_TITLES := ["RUIN", "VEIL", "DOMINION", "PASSAGE", "DECREE", "DEATH"]


## The keys of an Authority's powers, in book order.
static func of_authority(authority: String) -> PackedStringArray:
	var out := PackedStringArray()
	for p: Dictionary in POWERS:
		if String(p.get("authority", "")) == authority:
			out.append(p.key)
	return out


## A power's Authority, or "" for an unknown key.
static func authority_of(key: String) -> String:
	return String(get_power(key).get("authority", ""))


## An Authority's title ("DEATH"), or "" for an unknown one.
static func authority_title(authority: String) -> String:
	var i := AUTHORITIES.find(authority)
	return String(AUTHORITY_TITLES[i]) if i >= 0 else ""


## A power's family (v0.11.1, spec §7.1): what it does, not its Authority (Decision 25). A mission's main step has a route in
## two families, loadout A's and loadout B's (RouteBook); the gate proves both.
const FAMILY := {
	"doom": "veil", "blight": "veil",
	"deathmark": "death", "pestilence": "death",
	"smite": "strike", "heaven": "strike", "tornado": "strike", "tsunami": "strike", "gravity": "strike", "laser": "strike",
	"orbital": "strike", "judgement": "strike", "glacial": "strike", "solaris": "strike", "nova": "strike",
	"ember": "fire", "dragon": "fire", "cinder": "fire",
	"whisper": "lead", "oath": "lead", "echo": "lead", "congregation": "lead", "priority": "lead", "voice": "lead",
	"wisp": "draw", "delusion": "draw",
	"discord": "hold",
	"madness": "turn", "turncoat": "turn", "hatred": "turn", "verdict": "turn", "schism": "turn",
	"noleave": "decree", "belllies": "decree", "magnify": "decree", "abolition": "decree",
	"thorns": "passage", "mirror": "passage",
}


## A power's family (FAMILY), or "" for an unknown key.
static func family(key: String) -> String:
	return String(FAMILY.get(key, ""))


## A quiet power (v0.05): its cast is no danger the town can see.
static func is_quiet(key: String) -> bool:
	return bool(get_power(key).get("quiet", false))


static func keys() -> PackedStringArray:
	var out := PackedStringArray()
	for p: Dictionary in POWERS:
		out.append(p.key)
	return out


## 84x84 painted icon (Prepare cards), or null when it has not been painted yet.
static func icon(key: String) -> Texture2D:
	return _texture(ICON_DIR + key + ".png")


## 42x42 copy for the HUD slots, or null when it has not been painted yet.
static func hud_icon(key: String) -> Texture2D:
	return _texture(ICON_DIR + "hud/" + key + ".png")


## A texture that may not exist yet (a new power before its icon is painted): null rather than a load error.
static func _texture(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


static func clip_path(key: String) -> String:
	return CLIP_DIR + key + ".png"


## The power's preview sheet, or null when it has not been recorded.
static func clip(key: String) -> Texture2D:
	var path := clip_path(key)
	return load(path) if ResourceLoader.exists(path) else null


## Where frame `i` sits in a sheet.
static func clip_frame(i: int) -> Rect2:
	return Rect2(Vector2(float(i % CLIP_COLUMNS) * CLIP_SIZE.x, float(i / CLIP_COLUMNS) * CLIP_SIZE.y), Vector2(CLIP_SIZE))
