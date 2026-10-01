extends RefCounted
## v0.06 Discord: the confused forget their task for a while, then pick up again -- the rite breaks when its ring is
## confused, the bellkeeper drops the climb and is called again later, an engineer downs tools and goes back, an
## evacuee leaves the queue and flees again after; soldiers keep their heads, and nothing is a danger to the town.


static func _crowd() -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)
	crowd.spawn()
	return [crowd, env, world, field]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[2] as Node).free()


## Walk `p` straight to its goal.
static func _arrive(p: Person) -> void:
	if p.goal() != Vector2.INF:
		p.ground_pos = p.goal()
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


static func run(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]

	# Who it takes: citizens, not soldiers; and it is no danger the town can see.
	var at := Vector2(0.8, 2.0)
	var c: Person = crowd.citizens[0]
	c.ground_pos = at
	var s: Person = crowd.soldiers[0]
	s.ground_pos = at + Vector2(0.3, 0.0)
	var taken := DiscordFx.taken(field, at)
	t.check(c in taken and s not in taken, "Discord takes citizens, not soldiers")
	s.confuse(15.0)
	t.check(s.mind != Person.Mind.CONFUSED, "a soldier keeps its head")
	crowd.on_cast(at, Vector2.ZERO, 0.0, "discord")
	t.check(crowd.threats.active_count() == 0, "it is no danger the town can see")
	c.mind = Person.Mind.CALM
	c.confuse(DiscordFx.DISCORD_TIME)
	t.check(c.mind == Person.Mind.CONFUSED and c.intent() == Person.Intent.CONFUSED, "a confused citizen forgets its day")
	c._think(DiscordFx.DISCORD_TIME + 0.1)
	t.check(c.mind == Person.Mind.RECOVER, "then picks it up again")

	# The rite: its ring confused, it breaks.
	var rite := crowd.rite
	rite.begin()
	for e in rite.circle:
		_arrive(e[0])
	rite.step(0.1)
	var chanting := rite.state == BanishingRite.State.CHANTING
	for k in rite.circle.size() - 1:
		(rite.circle[k][0] as Person).confuse(DiscordFx.DISCORD_TIME)
	rite.step(0.1)
	t.check(chanting and rite.state == BanishingRite.State.COOLDOWN, "confusing the clergy breaks the rite")

	# The bell: the climb dropped, the bellkeeper called again once it comes to.
	var bell := crowd.bell
	bell.call_keeper()
	_arrive(bell.keeper)
	bell.step(0.1)
	var climbing := bell.state == BellNetwork.State.CLIMBING
	bell.keeper.confuse(DiscordFx.DISCORD_TIME)
	bell.step(0.1)
	var waiting := bell.state == BellNetwork.State.WAITING
	bell.keeper._think(DiscordFx.DISCORD_TIME + 0.1)
	bell.step(BellNetwork.RETRY + 0.1)
	t.check(climbing and waiting and bell.state == BellNetwork.State.CALLED,
		"the bellkeeper drops the climb, and is called again once it comes to")

	# The engineers: one confused, the work stops; come to, it goes back.
	var e := crowd.engineers
	var house: Structure = null
	for st in (made[1] as EnvironmentField).structures():
		if st.role == &"house" and st.art_tag == &"" and (house == null
				or st.center().distance_to(e.base) < house.center().distance_to(e.base)):
			house = st
	house.hp = house.max_hp * 0.4
	e.begin()
	e.step(0.1)
	var team: Dictionary = e.teams[0]
	for i in team.members.size():
		var m: Person = team.members[i]
		m.ground_pos = team.spots[i]
		m._goal = Vector2.INF
		m._path = PackedVector2Array()
	e.step(0.1)
	var worked: bool = team.working
	var member: Person = team.members[0]
	member.confuse(DiscordFx.DISCORD_TIME)
	e.step(0.1)
	var stopped: bool = not team.working
	member._think(DiscordFx.DISCORD_TIME + 0.1)
	e.step(0.1)
	t.check(worked and stopped and member.mind == Person.Mind.DUTY, "an engineer downs tools, then goes back to work")

	# An evacuee: out of the queue while confused, fleeing again after.
	var ev: Person = crowd.citizens[50]
	ev.mind = Person.Mind.FLEE
	ev.queue_spot = ev.ground_pos
	ev.confuse(DiscordFx.DISCORD_TIME)
	var left_queue := ev.queue_spot == Vector2.INF and ev.mind == Person.Mind.CONFUSED and not ev.has_escaped()
	ev._think(DiscordFx.DISCORD_TIME + 0.1)
	t.check(left_queue and ev.mind == Person.Mind.FLEE, "an evacuee wanders out of the queue, then flees again")
	_done(made)
