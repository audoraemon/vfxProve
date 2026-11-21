class_name BlightFx
extends FxTimeline
## Blight (Veil authority powers spec §5.2, reworked from v0.05): a quiet rot that takes a building or a person. What a click takes,
## in order (pick()): a mission director's own thing within REACH (an unguarded standard, a mirror -- MissionDirector.blight_target();
## the director is told, blighted(), and the banner is its own words); the building whose footprint is under the click; the nearest
## person within PICK; the nearest building within REACH. With none of them Rules refuses the cast ("no_blight", refusal()).
## - A building -- any standing one, not only one with a use -- rots grey-green (a building with a use through
##   EnvironmentField.blight(), so everything that reads Structure.blighted loses its use as before), its light goes out, and the
##   ground within VeilRules "blight" DUSK_R (3 / 5 in the dark) of its middle is dusk until the mission ends: the god's foothold
##   (Crowd.footholds, oldest first). At most VeilRules.BLIGHT_MAX at once: one more heals the oldest (heal(): clean again, its
##   light back, its dusk gone). The foothold outlives the effect; it ends only by the cap or with Crowd.clear().
## - A person falls ill without a sound and walks home to bed (Person.send_home_sick()); in the dark the ILL_MOST - 1 nearest within
##   ILL_REACH of them too. A mission's quarry (MissionDirector.quarry()) is only ill for ILL_TIME (Person.make_ill()); the god's own
##   believers and whoever the mission keeps alive (Crowd.spared(): a director's keeps_alive, the Escort's charge) are passed over --
##   the pick, and the dark's others, go to the next by distance. Not a death: no witness, no alarm, no kill credit.
## Silent (spec 11.1): Blight raises no alarm, for a building and a director's thing alike. Everything happens at T_ROT; before it the
## cast has changed nothing, so an effect cut short leaves nothing behind.

const REACH := 1.0
## A person is taken within this of the click (when no building lies under it).
const PICK := 0.5
## In the dark the sick are the picked person and the nearest others within this of them.
const ILL_REACH := 2.0
## How long a quarry is ill (half pace).
const ILL_TIME := 20.0
const T_ROT := 0.8
const ROT := [Color("1c2416"), Color("3a4a2a"), Color("5c6a3a"), Color("8a9658")]
## A foothold's light: the light map's pool at its front is dimmed out (TownPools.dim(), the building's own source) within this.
const LIGHT_R := 0.25
## What a foothold keeps on its building: {"dusk": its lasting patch's id, "ledger": the Dusk it was laid in}.
const FOOTHOLD := &"blight_foothold"

## The marks this cast laid on the sick (Veil review; they outlive it: tests read them while it lives).
var marks: Array[Node] = []


## Whether Blight has a use to ruin in `s` (v0.05: the well and fountain, the Bell Tower, a gate or the postern, the dock, the
## cathedral). Such a building is blighted through EnvironmentField.blight(); Turncoat reads it too.
static func blightable(s: Structure) -> bool:
	return s.kind == Structure.Kind.FOUNTAIN or s.kind == Structure.Kind.GATE or s.art_tag == &"bell_tower" \
		or s.role == &"dock" or s.role == &"temple"


## Whether Blight can take `s` as a building (the rework: any standing building): one with a use (blightable()) or one with walls
## and windows (Structure.WINDOWED: a house, the barracks, the keep, a tower); standing, not taken away, not blighted already.
static func building(s: Structure) -> bool:
	return is_instance_valid(s) and not s.destroyed and not s.taken and not s.blighted \
		and (blightable(s) or s.kind in Structure.WINDOWED)


## What Blight's v0.05 rot would ruin at `at`: the nearest standing, unblighted structure with a use, or null (Turncoat's question).
static func target(env: EnvironmentField, at: Vector2) -> Structure:
	var best: Structure = null
	var best_d := REACH
	for s in env.structures():
		if not is_instance_valid(s) or s.destroyed or s.blighted or not blightable(s):
			continue
		var d := s.distance_to(at)
		if d <= best_d:
			best_d = d
			best = s
	return best


## What a Blight cast at `at` takes (the spec's order): {"kind": &"director" | &"building" | &"person" | &"none", "s": Structure,
## "p": Person, "at": Vector2 (the point it rots)}.
static func pick(ctx: FxContext, at: Vector2) -> Dictionary:
	if ctx == null:
		return {"kind": &"none", "s": null, "p": null, "at": at}
	var d: MissionDirector = ctx.rules.director if ctx.rules != null else null
	return choose(ctx.env, ctx.crowd, d, at)


## pick() from its parts (Targeting and Rules have no effect context). Each may be null. No luck: ties by instance id.
static func choose(env: EnvironmentField, crowd: Crowd, director: MissionDirector, at: Vector2) -> Dictionary:
	var out := {"kind": &"none", "s": null, "p": null, "at": at}
	if director != null:
		var mine := director.blight_target(at)
		if mine != Vector2.INF:
			out.kind = &"director"
			out.at = mine
			return out
	var under: Structure = null
	var near: Structure = null
	var near_d := INF
	if env != null:
		for s in env.structures():
			if not building(s):
				continue
			if s.contains(at):
				if under == null or s.get_instance_id() < under.get_instance_id():
					under = s
				continue
			var dd := s.distance_to(at)
			if dd <= REACH and (dd < near_d or (dd == near_d and s.get_instance_id() < near.get_instance_id())):
				near_d = dd
				near = s
	if under != null:
		out.kind = &"building"
		out.s = under
		out.at = under.center()
		return out
	var p := _nearest_person(crowd, at, PICK, [])
	if p != null:
		out.kind = &"person"
		out.p = p
		out.at = p.ground_pos
		return out
	if near != null:
		out.kind = &"building"
		out.s = near
		out.at = near.center()
	return out


## Whether Blight can make `p` ill: alive, out on the street, not sick already, not one of the god's own believers.
static func ill_able(p: Person) -> bool:
	return p != null and is_instance_valid(p) and p.is_alive() and not p.inside and not p.night_indoors and not p.home_sick \
		and not (p.profile != null and p.profile.faith == CitizenProfile.Faith.BELIEVER)


static func _nearest_person(crowd: Crowd, at: Vector2, reach: float, skip: Array) -> Person:
	if crowd == null:
		return null
	var best: Person = null
	var best_d := INF
	for p in crowd.citizens + crowd.soldiers:
		if not ill_able(p) or skip.has(p) or crowd.spared(p):
			continue
		var d := p.ground_pos.distance_to(at)
		if d > reach:
			continue
		if d < best_d or (d == best_d and p.get_instance_id() < best.get_instance_id()):
			best_d = d
			best = p
	return best


## Who falls ill when Blight takes `p`: `p`, then (the dark's ILL_MOST) the nearest others within ILL_REACH of them, by distance then
## instance id.
static func sick_with(crowd: Crowd, p: Person, most: int) -> Array[Person]:
	var out: Array[Person] = [p]
	while out.size() < most:
		var next := _nearest_person(crowd, p.ground_pos, ILL_REACH, out)
		if next == null:
			break
		out.append(next)
	return out


## Why a Blight cast at `ground` must be refused: "no_blight" when it would take nothing (pick()'s &"none"), else "". Rules.cast()
## asks before the cooldown, so a refused cast spends none. No rules or no crowd (the VFX Sandbox): never refused.
static func refusal(rules: Rules, ground: Vector2) -> String:
	if rules == null or rules._crowd == null:
		return ""
	var env: EnvironmentField = rules._env if rules._env != null else rules._crowd._env
	return "no_blight" if choose(env, rules._crowd, rules.director, ground).kind == &"none" else ""


## The director's point Blight would rot at `at` (v0.11.1), or Vector2.INF for none: no director, or none of its own in reach.
## Targeting rings it as it rings a structure.
static func director_target(ctx: FxContext, at: Vector2) -> Vector2:
	if ctx == null or ctx.rules == null or ctx.rules.director == null:
		return Vector2.INF
	return ctx.rules.director.blight_target(at)


## Blights `s` and makes it a foothold of `crowd`: its use gone as before (a building with a use through EnvironmentField.blight()),
## its light out, a lasting dusk of `r` round its middle; one past VeilRules.BLIGHT_MAX heals the oldest. With no crowd (the VFX
## Sandbox) it is only blighted.
static func plant(crowd: Crowd, env: EnvironmentField, s: Structure, r: float) -> void:
	if not is_instance_valid(s) or s.destroyed:
		return
	if blightable(s):
		env.blight(s)
	else:
		s.set_blighted(true)  # no use to lose: nothing in the town is told (no banner, no response)
	if crowd == null or crowd.footholds.has(s):
		return  # a gate that freed itself and is blighted again keeps the foothold it holds
	while crowd.footholds.size() >= VeilRules.BLIGHT_MAX:
		if is_instance_valid(crowd.footholds[0]):
			heal(crowd, env, crowd.footholds[0])
		else:
			crowd.footholds.remove_at(0)  # freed with its town: nothing left to heal
	TownPools.dim(s.get_instance_id(), s.footprint.end, LIGHT_R, 1.0)
	var id := crowd.lay_dusk(s.center(), r, -1.0)
	s.set_meta(FOOTHOLD, {"dusk": id, "ledger": crowd.dusk.get_instance_id() if crowd.dusk != null else 0})
	crowd.footholds.append(s)


## Ends the foothold `s`: clean again, its light back, its dusk gone, off Crowd.footholds.
static func heal(crowd: Crowd, env: EnvironmentField, s: Structure) -> void:
	if not is_instance_valid(s):
		return
	crowd.footholds.erase(s)
	if env != null:
		env.unblight(s)
	elif s.blighted:
		s.set_blighted(false)
	TownPools.undim(s.get_instance_id())
	var held: Dictionary = s.get_meta(FOOTHOLD, {})
	s.remove_meta(FOOTHOLD)
	if crowd.dusk != null and int(held.get("dusk", 0)) != 0 and int(held.get("ledger", 0)) == crowd.dusk.get_instance_id():
		crowd.dusk.end(int(held.dusk))


## Whether the building's light is on: its light-map pool is not dimmed out by a foothold.
static func lit(s: Structure) -> bool:
	return TownPools.dim_factor(s.footprint.end) > 0.0


func _build() -> void:
	duration = 1.6
	var took := pick(ctx, origin)
	var mine: Vector2 = took.at if took.kind == &"director" else Vector2.INF
	var s: Structure = took.s
	var picked: Person = took.p
	var sick: Array[Person] = []
	if picked != null:
		sick = sick_with(ctx.crowd, picked, int(VeilParts.size(self, "blight", "ILL_MOST")))
	var where: Vector2 = took.at
	var screen := Iso.ground_to_screen(where)
	ctx.play(&"q_blight", where)
	var gather := FxParts.particles(self, ctx.overhead, screen, PixelParticles.Shape.PUFF, ROT)
	gather.drag = 1.0
	gather.gravity = -10.0
	gather.burst(22, {"radius": 26.0, "speed": Vector2(14, 34), "dir": PixelParticles.Dir.INWARD, "alt": Vector2(2, 14),
		"alt_speed": Vector2(0, 10), "life": Vector2(0.6, 0.9), "size": Vector2(2, 4), "size_end_mul": 0.5})
	at(T_ROT, func() -> void:
		var spores := FxParts.particles(self, ctx.overhead, screen, PixelParticles.Shape.SQUARE, ROT)
		spores.gravity = -18.0
		spores.drag = 0.8
		spores.burst(16, {"radius": 18.0, "speed": Vector2(2, 8), "alt": Vector2(0, 20), "alt_speed": Vector2(4, 14),
			"life": Vector2(0.6, 0.8), "size": Vector2(1, 2)})
		if mine != Vector2.INF or (s != null and is_instance_valid(s) and not s.destroyed):
			ctx.play(&"q_blight_hit", where)
		if mine != Vector2.INF:
			var d: MissionDirector = ctx.rules.director if ctx.rules != null else null
			if d != null:
				d.blighted(mine)
				var words := d.blight_words(mine)
				if words != "":
					ctx.rules.banner.emit(words)
			VeilParts.land(self, where)
		elif s != null:
			if is_instance_valid(s) and not s.destroyed:
				plant(ctx.crowd, ctx.env, s, VeilParts.size(self, "blight", "DUSK_R"))
		elif picked != null:
			if not sick.is_empty() and is_instance_valid(sick[0]) and sick[0].is_alive():
				ctx.play(&"q_blight_ill", where)
			_make_ill(sick)
			VeilParts.land(self, where))


## The sick at T_ROT: none when the one the click took is gone; a quarry is only ill, the rest walk home to bed.
func _make_ill(sick: Array[Person]) -> void:
	if sick.is_empty() or not is_instance_valid(sick[0]) or not sick[0].is_alive():
		return
	var d: MissionDirector = ctx.rules.director if ctx.rules != null else null
	for p in sick:
		if not ill_able(p) or (ctx.crowd != null and ctx.crowd.spared(p)):
			continue
		if d != null and d.quarry(p):
			p.make_ill(ILL_TIME)
		else:
			p.send_home_sick()
		_mark(p)


## The mark of the sick (Veil review, spec 4): a sickness glyph over his head in the rot colour while he walks home (or, a quarry,
## while he is ill), and a faint drift of rot motes behind him. A badge another power set stays (VeilCastLooks.BlightMark). It
## outlives the cast (SolarisPit.GROUP) and frees itself, clearing the badge, when he is indoors, well or gone.
func _mark(p: Person) -> void:
	if ctx.overhead == null or not VeilCastLooks.BlightMark.ill(p):
		return
	var m := VeilCastLooks.BlightMark.new()
	m.start(p)
	ctx.overhead.add_child(m)
	marks.append(m)
