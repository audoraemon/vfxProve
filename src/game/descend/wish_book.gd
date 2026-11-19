class_name WishBook
extends RefCounted
## The wishes a board night may hear (v0.11 M1, spec §5): the pool, and the draw. The draw is seeded, so a restart hears the
## same. It is filtered: a wish whose tags clash with the mission's, or whose targets the town cannot give, is left out, and
## a mission with too few eligible wishes offers what it can, possibly none.


## The pool (spec §5.3): M1's eight in the spec's order, then v0.11 M2's two for Tier 1, v0.11 M3's two for Omen, v0.11 M4's two for Wrath and v0.11 M5's two for Reckoning (mission spec §6) and v0.11 M6's two for Ascendance (§5).
static func pool() -> Array[WishDef]:
	var out: Array[WishDef] = [
		WishDef.make("moneylender", "Burn the moneylender's house", "ruin", 10, RuinWish,
			{"role": "house", "label": "MONEYLENDER"}, PackedStringArray(["spares_houses"])).with_how("Destroy the MONEYLENDER house, by any means"),
		WishDef.make("watchtower", "Bring down the watchtower", "ruin", 15, RuinWish, {"role": "tower", "label": "WATCHTOWER"}).with_how("Destroy the WATCHTOWER, by any means"),
		WishDef.make("tax_collector", "Strike down the cruel tax collector", "punish", 10, PunishWish,
			{"label": "TAX COLLECTOR", "unseen": false}, PackedStringArray(["hunts_tax_collector"])).with_how("Kill the TAX COLLECTOR"),
		WishDef.make("informer", "Kill the informer, unseen", "punish", 15, PunishWish, {"label": "INFORMER", "unseen": true},
			PackedStringArray(["hunts_informer"])).with_how("Kill the INFORMER with no one left to see it"),
		WishDef.make("child", "Save my child", "rescue", 15, RescueWish, {}, PackedStringArray(["unaware_town"])).with_how("Kill or turn the SOLDIER before he drags THE CHILD off"),
		WishDef.make("brother", "Lead my brother out", "mercy", 10, MercyWish, {}, PackedStringArray(["shuts_gates"])).with_how("Mind Whisper the BROTHER to a town gate", "whisper"),
		WishDef.make("sign", "Show me a sign", "sign", 5, SignWish).with_how("Cast any power near the WISH, out of doors"),
		WishDef.make("family", "Show yourself to my family", "sign", 10, FamilyWish).with_how("Cast a power where each FAMILY member sees it"),
		WishDef.make("bailiff", "Stop the bailiff", "rescue", 15, BailiffWish).with_how("Kill or turn the BAILIFF before he reaches the door"),
		WishDef.make("neighbours", "Let my neighbours believe", "faith", 10, NeighboursWish).with_how("Mind Whisper each NEIGHBOUR to the WISH", "whisper"),
		WishDef.make("bully", "Scare off the bully, unharmed", "fright", 10, FrightWish, {}, PackedStringArray(["unaware_town"]), 2).with_how("Frighten the BULLY without hurting him"),
		WishDef.make("pressed", "Free the pressed man", "rescue", 15, PressedWish, {},
			PackedStringArray(["unaware_town", "razes_barracks"]), 2).with_how("Kill or turn the PRESS-GANG before they take him"),
		WishDef.make("barn", "Burn the tithe barn", "ruin", 10, RuinWish, {"role": "barn", "label": "TITHE BARN"},
			PackedStringArray(["razes_bread"]), 3).with_how("Destroy the TITHE BARN, by any means"),
		WishDef.make("sergeant", "Strike down the cruel sergeant", "punish", 15, PunishWish,
			{"label": "SERGEANT", "unseen": false, "soldier": true, "edge": true}, PackedStringArray(), 3).with_how("Kill the SERGEANT"),
		WishDef.make("heretic", "Save the heretic from the pyre", "rescue", 15, PressedWish,
			{"goal": "temple", "son_label": "HERETIC", "guard_label": "TEMPLE GUARD"}, PackedStringArray(["burns_temple", "unaware_town"]), 4).with_how("Kill or turn the TEMPLE GUARD before the pyre"),
		WishDef.make("family_out", "Lead my family out", "mercy", 15, MercyWish, {"count": 3}, PackedStringArray(["shuts_gates"]), 4).with_how("Mind Whisper each FAMILY member to a town gate", "whisper"),
		WishDef.make("zealot", "Strike down the zealot, unseen", "punish", 15, PunishWish,
			{"label": "ZEALOT", "unseen": true, "clergy": true, "edge": true}, PackedStringArray(), 5).with_how("Kill the ZEALOT with no one left to see it"),
		WishDef.make("priest", "Turn the doubting priest", "faith", 15, NeighboursWish,
			{"count": 1, "clergy": true, "label": "DOUBTING PRIEST", "edge": true, "route": 30.0}, PackedStringArray(), 5).with_how("Mind Whisper the DOUBTING PRIEST to the WISH", "whisper"),
	]
	return out


## The wishes a night of `tier` may hear (v0.11 M3, controller ruling 3): the pool's, in its order, but those whose min_tier is
## higher. Left out before the draw shuffles, so a Tier 1 night shuffles exactly M2's ten and hears what it always heard.
static func pool_for(tier: int) -> Array[WishDef]:
	var out: Array[WishDef] = []
	for d in pool():
		if d.min_tier <= tier:
			out.append(d)
	return out


## Up to `count` wishes for a night (spec §5.1), tried in an order `rng` shuffles. A wish whose clashes meet `tags` is
## skipped, as is one whose choose() finds no targets in the town, and (2026-11-19) one that needs a power `powers` lacks
## (WishDef.needs). An empty `powers` is "not known" and skips nothing. No two share a person or a building.
static func draw(defs: Array[WishDef], count: int, tags: PackedStringArray, crowd: Crowd, town: Town,
		rng: RandomNumberGenerator, powers := PackedStringArray()) -> Array[Wish]:
	var order: Array[WishDef] = defs.duplicate()
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := order[i]
		order[i] = order[j]
		order[j] = swap
	var out: Array[Wish] = []
	var taken := []
	for d in order:
		if out.size() >= count:
			break
		if clashes(d, tags) or not grantable(d, powers):
			continue
		var w := d.instance()
		if w.choose(crowd, town, rng, taken):
			out.append(w)
	return out


## The night's loadout `powers` can grant `d`: it needs no power, or `powers` holds it, or `powers` is empty (not known).
static func grantable(d: WishDef, powers: PackedStringArray) -> bool:
	return d.needs == "" or powers.is_empty() or powers.has(d.needs)


## The wish lists a tag the mission declares.
static func clashes(d: WishDef, tags: PackedStringArray) -> bool:
	for tag in d.clashes:
		if tags.has(tag):
			return true
	return false
