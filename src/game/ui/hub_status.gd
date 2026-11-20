class_name HubStatus
extends RefCounted
## The between-nights hub's words and decisions, apart from its drawing (God's Chamber Task 1): the lines, the Notice meter, the Hunt and
## seal lines, the stolen gifts, whether the god can Descend, what Awaken offers, and what one press does. GodChamber (the screen) draws and plays
## sounds from it. It holds no node and plays no sound.

## What the hub says when the god has nothing to draft (Ruling P8).
const BLOCKED := "Nothing to draft: the tree's Tier 1 is not filled yet"
## What the hub says when the Hunt is next (god P2, spec §10.2, Ruling P2-11; *my call*): `%s` is the Hunt's title.
const HUNT_DUE := "THE LANTERN HUNTS: the next night is the Hunt, %s"
## What the hub says of a sealed ability (spec §10.3, Ruling P2-11; *my call*): its name, the nights left.
const SEALED := "Sealed by the Lantern: %s, %s left"
## What the dev Awaken says while the Hunt is due (Ruling P2-4; *my call*).
const AWAKEN_HUNT := "The Lantern hunts: face the Hunt first"
## What a click on the dim Awaken button says when no rite is written for the god's level (god P3, MS §1; levels 20, 30 and 40 until P4).
const RITE_UNWRITTEN := "Rite not yet written"
## The hub's line of stolen gifts (god P3, MS §4 "Shown"): `%s` is the gifts' names, joined with ", ".
const GIFTS_LINE := "Stolen gifts: %s"

## What Awaken offers this god, fixed at setup like the buttons (GodNight.awaken_state(): "", "rite" or "unwritten").
var awaken := ""
var _slot: GodSlot


func _init(slot: GodSlot) -> void:
	_slot = slot
	awaken = GodNight.awaken_state(slot)


## The Divine Power bar's words: "n / need Divine Power"; at the level cap below level 50 "AWAKEN TO GROW"; at level 50 "MAX LEVEL"
## (spec §8).
static func bar_text(slot: GodSlot) -> String:
	if slot.level >= GodSlot.MAX_LEVEL:
		return "MAX LEVEL"
	if slot.capped():
		return "AWAKEN TO GROW"
	return "%d / %d Divine Power" % [slot.divine_power, slot.need()]


## The hub's lines, in order: the type's title, level and tier, the bar's words, ability points, Faith, Notice, and the night. The
## night counts from 1 (Ruling P24 adds the ability points).
func lines() -> PackedStringArray:
	return PackedStringArray([PowerBook.authority_title(_slot.type), "Level %d   %s" % [_slot.level, TierBook.tier_name(_slot.tier)],
		bar_text(_slot), "Ability points %d" % _slot.points, "Faith %d" % _slot.faith, "Lantern Notice %d%%" % _slot.notice,
		"Night %d" % (_slot.night + 1)])


## The town the god last played in and the percent of its people who believe: "Aldermere 0%" (World Map + Conquer Progress). Not one of
## lines(), so the indices of those stay as they were.
func town_line() -> String:
	return "%s %d%%" % [Conquest.town_name(_slot.last_town), Conquest.percent_of(_slot, _slot.last_town)]


## "Stolen gifts: The Watchful Bell" (the names joined with ", ") when the god has stolen any, else "" (god P3, MS §4). Drawn after lines(), so
## P1's line indices are unchanged.
func gifts_line() -> String:
	var names := PackedStringArray()
	for g in _slot.gifts:
		if RiteBook.gift_name(g) != "":
			names.append(RiteBook.gift_name(g))
	return "" if names.is_empty() else GIFTS_LINE % ", ".join(names)


## True when the Awaken button is on the row (god P3, MS §1): the god is capped below level 50.
func awaken_shown() -> bool:
	return awaken != ""


## True when the Awaken button is shown but dim: the god is capped and no rite is written for its level, and the Hunt is not next (the Hunt
## leads from Awaken as from Descend, so it is not dim then).
func awaken_dim() -> bool:
	return awaken_shown() and (not can_descend() or awaken == "unwritten" and GodNight.hunt_for(_slot).is_empty())


## The Notice as a fraction of a full meter, 0 to 1 (god P2, spec §10.1).
func notice_fill() -> float:
	return clampf(float(_slot.notice) / float(GodSlot.NOTICE_MAX), 0.0, 1.0)


## The Divine Power bar as a fraction, 0 to 1; full while the god is capped.
func bar_fill() -> float:
	return 1.0 if _slot.capped() else clampf(float(_slot.divine_power) / float(maxi(_slot.need(), 1)), 0.0, 1.0)


## "THE LANTERN HUNTS: ..." with the Hunt's title when the next night is the Hunt (Notice 100), else "" (god P2, spec §10.2).
func hunt_line() -> String:
	var hunt := GodNight.hunt_for(_slot)
	return "" if hunt.is_empty() else HUNT_DUE % String(hunt.title)


## "Sealed by the Lantern: <ability>, <n> nights left" while an ability is sealed, else "" (god P2, spec §10.3).
func seal_line() -> String:
	if _slot.sealed == "" or _slot.seal_nights <= 0:
		return ""
	return SEALED % [PowerBook.get_power(_slot.sealed).name, GodSlot.nights_text(_slot.seal_nights)]


## True when the god has an ability to draft; a god with none cannot Descend (Ruling P8).
func can_descend() -> bool:
	return not _slot.draftable().is_empty()


## BLOCKED when the god cannot Descend, else "".
func blocked_line() -> String:
	return "" if can_descend() else BLOCKED


## True when the god's Faith buys at least one Faith row now (no row refuses it).
func faith_affordable() -> bool:
	for row: Dictionary in GodSlot.FAITH:
		if _slot.faith_refusal(String(row.key)) == "":
			return true
	return false


## The hub's decision for one press, with no sound and no signal: {"emit": the action to send ("" for none), "buzz": true when the press
## is refused, "line": the one-off line to show ("" leaves it as it is)}. `what` is "descend", "awaken", "tree", "faith" or "title";
## `from_key` is true for the A key (the dev hook and the "rite not written" line belong to it as to the button); `dev` is the DEV build.
## A press with no emit and no buzz does nothing at all.
func press(what: String, from_key := false, dev := false) -> Dictionary:
	if what == "descend":
		return _result("descend")  # the World Map opens always; it says why a night cannot be had (Plan note 14)
	if what == "awaken":
		if not from_key and not can_descend():
			return _result("", true)  # nothing to draft: Awaken is blocked as Descend is (milestone review Minor 6)
		return _awaken_press(from_key, dev)
	return _result(what)


## Awaken, by its button or the A key (god P3, MS §1, §9.3). Not capped: only the dev hook, as in P2 (refused while the Hunt is due, Ruling
## P2-4). A rite written: "awaken" in any build (Game plays the Hunt first when it is due). No rite written: while the Hunt is due the
## same ("awaken"; the Hunt leads), else the dev hook on the key under --dev, else a buzz and RITE_UNWRITTEN.
func _awaken_press(from_key: bool, dev: bool) -> Dictionary:
	if not can_descend() and awaken != "":
		return _result("", true)
	var hunt_due := not GodNight.hunt_for(_slot).is_empty()
	if awaken == "":
		if not (from_key and dev):
			return _result()
		if hunt_due:
			return _result("", true, AWAKEN_HUNT)  # the Hunt cannot be skipped (Ruling P2-4): say so, emit nothing
		return _result("awaken_dev")
	if awaken == "rite" or hunt_due:
		return _result("awaken")
	if from_key and dev:
		return _result("awaken_dev")
	return _result("", true, RITE_UNWRITTEN)


static func _result(emit := "", buzz := false, line := "") -> Dictionary:
	return {"emit": emit, "buzz": buzz, "line": line}
