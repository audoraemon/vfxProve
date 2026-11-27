extends RefCounted
## World Map + Conquer Progress, final review 2: a Mission run as an Endless conquest night (conquest = true). The carried believers are
## marked after the night's rules, a death through EnemyField.enemy_killed counts, the result's report() says so, an abandon takes
## carried_alive() into the god's town count, and a conquest night that carries 0 is exactly the same night with conquest off.

const LOADOUT := ["heaven", "tsunami", "cinder", "nova"]


static func run(t) -> void:
	await _marked_and_counted(t)
	await _zero_is_today(t)


## A lost_lamb Endless night in Aldermere carrying `carried` (conquest off: a plain god night), started with seed 7 and the NIGHT look.
static func _start(t, conquest: bool, carried: int) -> Mission:
	City.use(&"aldermere")
	var m: Mission = load("res://scenes/mission.tscn").instantiate()
	m.autostart = false
	m.mission_id = "lost_lamb"
	m.board = true
	m.look_override = Town.Look.NIGHT
	m.god_night = true
	m.conquest = conquest
	m.carried = carried
	m.believer_seed = 12345
	t.root.add_child(m)
	if not m.is_prewarmed:
		await m.prewarmed
	m.start(PackedStringArray(LOADOUT), 7)
	return m


static func _free(t, m: Mission) -> void:
	m.queue_free()
	await t.process_frame


## Everything the night's setup can have drawn a number for: the crowd's stream, every person's, who is indoors and each one's faith and spot.
static func _digest(m: Mission) -> String:
	var rows := PackedStringArray(["%d" % m._crowd._rng.state])
	for p in m._crowd.citizens:
		rows.append("%d/%s/%s/%d" % [p.rng.state, p.inside, p.ground_pos, p.profile.faith if p.profile != null else -1])
	return "|".join(rows).md5_text()


static func _marked_and_counted(t) -> void:
	var m: Mission = await _start(t, true, 12)
	var roll := m.believers()
	t.check(roll != null and roll.marked.size() == 12 and m.carried_alive() == 12, "conquest night: 12 carried, 12 marked and alive (%s)" % [m.carried_alive()])
	var plain: Mission = await _start(t, false, 12)
	t.check(plain.believers() == null and plain.carried_alive() == -1, "conquest off: no roll, carried_alive is -1")
	var seen := PackedInt32Array()
	var same_inside := true
	for i in m._crowd.citizens.size():
		var a: Person = m._crowd.citizens[i]
		var b: Person = plain._crowd.citizens[i]
		same_inside = same_inside and a.inside == b.inside and a.night_indoors == b.night_indoors
		if a.profile.faith == CitizenProfile.Faith.BELIEVER and roll.is_carried(a):
			seen.append(i)
	t.check(same_inside and seen.size() == 12, "the night's rules ran first: who is indoors is the same with or without the marks (%d marked)" % seen.size())
	t.check(not (plain._crowd.citizens as Array).any(func(p: Person) -> bool: return roll.is_carried(p)), "and no one is marked on the plain night")
	await _free(t, plain)
	# a death through the real path
	var field: EnemyField = m._crowd._field
	var victim: Person = roll.marked[0]
	field.kill(victim, &"test")
	t.check(roll.lost == 1 and m.carried_alive() == 11, "a marked death through EnemyField.enemy_killed: lost 1, 11 alive (%d, %d)" % [roll.lost, m.carried_alive()])
	field.enemy_killed.emit(victim, &"test")
	t.check(roll.lost == 1, "the same death twice still counts once")
	# the report at the end
	var res := m._final_result()
	var c: Dictionary = res.get("conquest", {})
	t.check(c.get("town", "") == "aldermere" and int(c.get("carried", -1)) == 12 and int(c.get("carried_alive", -1)) == 11 and int(c.get("lost", -1)) == 1
		and int(c.get("named", -1)) == 0 and int(c.get("fill", -1)) == 0, "the result's conquest report (%s)" % [c])
	# an abandon takes the believers still alive into the town's count
	var god := GodSlot.make(1, "ruin", 7)
	god.believers["aldermere"] = 12
	god.last_town = "aldermere"
	god.in_night = "lost_lamb"
	var out := GodNight.forfeit(god, m.carried_alive())
	t.check(Conquest.count_of(god, "aldermere") == 11 and int(out.conquest.count) == 11, "abandoned: the town's count is the 11 still alive (%s)" % [out.conquest])
	await _free(t, m)


## A conquest night carrying 0 is today's night: no generator, no draw, nothing marked -- the digest (taken the moment the night starts, before a
## frame can move anyone) equals the conquest-off night's.
static func _zero_is_today(t) -> void:
	var on: Mission = await _start(t, true, 0)
	var on_digest := _digest(on)
	t.check(on.believers() != null and on.believers().marked.is_empty() and on.carried_alive() == 0, "carrying 0: a roll that marked no one")
	await _free(t, on)
	var off: Mission = await _start(t, false, 0)
	var off_digest := _digest(off)
	await _free(t, off)
	var again: Mission = await _start(t, false, 0)
	t.check(_digest(again) == off_digest, "(the conquest-off night repeats itself: the digest is stable)")
	await _free(t, again)
	t.check(on_digest == off_digest, "carrying 0: crowd, person streams, indoors and faith equal the conquest-off night's")
	# and the counter-proof: carrying some moves the faith column
	var some: Mission = await _start(t, true, 12)
	t.check(_digest(some) != off_digest, "carrying 12 is not that night (the digest sees the marks)")
	await _free(t, some)
