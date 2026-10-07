class_name ResponseProfile
extends RefCounted
## How ready Aldermere is (v0.05): the difficulty the player picks on the Prepare screen, and the town responses it
## brings -- shown there as the Defense Profile. The town's managers read what they need from it (the fire brigade
## its crew and when it turns out; the bell, the rite, the engineers and the boats whether they exist at all and how
## fast they work). Harder tiers do not add hit points: the town organizes better.

enum Tier { UNPREPARED, ORGANIZED, PREPARED, GOD_RESISTANT }
const NAMES := ["Unprepared", "Organized", "Prepared", "God-Resistant"]
## One line each for the Prepare screen.
const BLURBS := [
	"A sleepy settlement: no bell, fires fought late.",
	"A watchful town: a bell and a fire brigade.",
	"A kingdom ready for you: engineers, boats and a rite.",
	"Everything faster: evacuates sooner, big boats.",
]
const DEFAULT := Tier.ORGANIZED
## Alarm stages, short enough for a Defense Profile line.
const SHORT_STAGE := ["Normal", "Concern", "Local Em.", "City Em.", "Evac.", "Collapse"]

var tier := DEFAULT
## A profile's own name when a mission sets it rather than a tier (v0.08: "Unaware"); "" for the tier's name.
var title := ""
## Its own line for the Prepare screen when a mission sets it (v0.08); "" for the tier's BLURBS line.
var note := ""
## The Bell Network (v0.05 M2): a bellkeeper who climbs the tower at the first Local Emergency, and how long the
## climb takes.
var bell := true
var bell_climb := 8.0
## The fire brigade: most responders per fire, and the alarm stage from which they turn out.
var fire_crew := 4
var fire_from := AlarmManager.Stage.LOCAL_EMERGENCY
## Engineers (M4): teams of two (0: none).
var engineer_teams := 0
## River boats at the dock (M5), and how many each sailing carries (v0.08.2: God-Resistant's are bigger).
var boats := false
var boat_load := 6
## Seconds between two people through the postern down to the dock (v0.08.2; God-Resistant's is quicker).
var postern_interval := 3.0
## Seconds from City Emergency to the evacuation, for families to regroup (v0.08.2; God-Resistant's town is quicker).
var regroup_seconds := 15.0
## The Banishing Rite at the cathedral (M3), how long it takes, and how many clergy it calls (v0.08.2: God-Resistant
## calls more of its clergy, so its ring is harder to scatter).
var rite := false
var rite_time := 45.0
var rite_clergy := 4
## The soldiers' roles (v0.07): marshals at each way out at the evacuation, escorts for each responder on duty, and
## rescue squads of Crowd.RESCUE_SQUAD. Every tier has them; harder towns have more.
var marshals_per_exit := 3
var escorts_per_duty := 1
var rescue_squads := 3


static func for_tier(t: Tier) -> ResponseProfile:
	var p := ResponseProfile.new()
	p.tier = t
	match t:
		Tier.UNPREPARED:
			p.bell = false
			p.fire_crew = 2
			p.fire_from = AlarmManager.Stage.CITY_EMERGENCY
			p.marshals_per_exit = 2
			p.rescue_squads = 2
		Tier.ORGANIZED:
			pass
		Tier.PREPARED:
			p.engineer_teams = 2
			p.boats = true
			p.rite = true
			p.marshals_per_exit = 4
			p.escorts_per_duty = 2
			p.rescue_squads = 4
		Tier.GOD_RESISTANT:
			p.bell_climb = 5.0
			p.fire_crew = 5
			p.engineer_teams = 3
			p.boats = true
			p.rite = true
			p.rite_time = 35.0
			p.boat_load = 10
			p.postern_interval = 1.5
			p.rite_clergy = 6
			p.regroup_seconds = 8.0
			p.marshals_per_exit = 5
			p.escorts_per_duty = 2
			p.rescue_squads = 5
	return p


## The Warning's town (v0.08, Tier 1): Organized's bell, fire brigade, marshals and rescue squads, but nobody escorts
## its responders -- a town that has never had to guard its bellkeeper.
static func unaware() -> ResponseProfile:
	var p := for_tier(Tier.ORGANIZED)
	p.title = "Unaware"
	p.note = "An evening like any other: nobody guards the bell."
	p.escorts_per_duty = 0
	return p


static func tier_named(name: String) -> Tier:
	var i := NAMES.map(func(n: String) -> String: return n.to_lower()).find(name.to_lower())
	return (i as Tier) if i >= 0 else DEFAULT


## How ready the town is, as a rank (v0.09: a night's town is only ever raised): Unprepared 0, Unaware 1,
## Organized 2, Prepared 3, God-Resistant 4.
func level() -> int:
	return 1 if title == "Unaware" else [0, 2, 3, 4][tier]


## The profile for a readiness rank (v0.11 M1: a board tier's floor), level() turned back: 0 Unprepared, 1 Unaware,
## 2 Organized, 3 Prepared, 4 and above God-Resistant.
static func for_level(rank: int) -> ResponseProfile:
	match rank:
		0:
			return for_tier(Tier.UNPREPARED)
		1:
			return unaware()
		2:
			return for_tier(Tier.ORGANIZED)
		3:
			return for_tier(Tier.PREPARED)
	return for_tier(Tier.GOD_RESISTANT)


## This profile, or `rank`'s when this one is less ready (v0.11 M1, spec §4: a mission may raise its tier's town, never lower
## it). A rank below 0 leaves it as it is.
func at_least(rank: int) -> ResponseProfile:
	return self if rank < 0 or level() >= rank else for_level(rank)


func tier_name() -> String:
	return title if title != "" else NAMES[tier]


## Its one line for the Prepare screen.
func blurb() -> String:
	return note if note != "" else BLURBS[tier]


## The Defense Profile: what the town will do, one short line each.
func lines() -> PackedStringArray:
	var out := PackedStringArray()
	out.append("Bell Network, %.0f s" % bell_climb if bell else "No alarm bell")
	out.append("Fire Brigade x%d (%s)" % [fire_crew, SHORT_STAGE[fire_from]])
	if engineer_teams > 0:
		out.append("Engineers: %d teams" % engineer_teams)
	if boats:
		out.append("River Boats x%d" % boat_load)
	if rite:
		out.append("Banishing Rite x%d, %.0f s" % [rite_clergy, rite_time])
	out.append("Marshals x%d, Escorts x%d, Rescue x%d" % [marshals_per_exit, escorts_per_duty, rescue_squads])
	return out
