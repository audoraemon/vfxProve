class_name RewritePriorityFx
extends FxTimeline
## Rewrite Priority (Dominion, Tier IV): for PRIORITY_TIME a district puts one thing above all else. Everyone within
## RADIUS of the click, nearest first up to MAX_PEOPLE -- any role -- takes it up after T_CAST, through the people's
## own generic pieces, and their own judgement does the rest. The priority is the cast's mode:
##   WORK     each goes to its work and stays at it (one with no work, home; a soldier, its post).
##   WORSHIP  each goes to the cathedral, to a spot of its own.
##   HIDE     each goes home and stays in.
##   ESCAPE   each drops what it was doing and makes for a way out (citizens; an escape counts as any other).
##   IGNORE   nothing frightens them and nothing makes them look (Person.fearless_left): they go on with their day.
## Work, Worship and Hide are compulsions of WILL: an evacuation does not call them away; a danger on top of them does.
## Quiet, but for the book entry's "alarm". The cast locks the other slots until it has landed.

const RADIUS := 7.0
const MAX_PEOPLE := 80
const PRIORITY_TIME := 25.0
const T_CAST := 1.0
const WILL := 0.8
const ICON_SECONDS := 4.0
const GLYPHS := {"work": DominionParts.HAMMER, "worship": DominionParts.CROSS, "hide": DominionParts.ROOF,
	"escape": DominionParts.ARROW, "ignore": DominionParts.SHUT_EYE}

var priority := "work"
var people: Array[Person] = []


func _build() -> void:
	priority = String(extra.get("mode", "work"))
	if not GLYPHS.has(priority):
		priority = "work"
	duration = T_CAST + PRIORITY_TIME + 0.5
	busy = T_CAST + 0.5
	at(T_CAST, _rewrite)
	ctx.play(&"hs_charge", origin, -8.0)
	if DominionParts.staged(self):
		# The compass over the district, the chosen priority's sign at its heart.
		DominionParts.sky_sigil(self, origin, 130.0, 130.0, DominionParts.GOLD, T_CAST, 2.5)
		DominionParts.ground_sigil(self, origin, RADIUS, DominionParts.GOLD, T_CAST, 1.5)
		var glyph: Array[int] = []
		glyph.assign(GLYPHS[priority])
		var icon := DominionParts.icon(self, origin, glyph, Color("fff6d8"), T_CAST + 3.0, 130.0)
		icon.px = 4


func _rewrite() -> void:
	people = DominionParts.near(ctx.field, origin, RADIUS, MAX_PEOPLE)
	var glyph: Array[int] = []
	glyph.assign(GLYPHS[priority])
	var spots: Array[Vector2] = []
	if priority == "worship":
		var cathedral: Array = City.current().anchors().get("cathedral", [])
		var place := CongregationFx.place_for(ctx.env, cathedral[0] if not cathedral.is_empty() else origin)
		var grid: WalkGrid = people[0].grid if not people.is_empty() else null
		spots = CongregationFx.spots_for(grid, place, people.size())
	var links: DominionParts.Links = DominionParts.links(self) if DominionParts.staged(self) else null
	for i in people.size():
		var p := people[i]
		match priority:
			"work":
				var to := DominionParts.home_of(p)
				if not p.soldier and p.profile != null and p.profile.works():
					to = p.profile.work
				p.compel(to, PRIORITY_TIME, WILL, DominionParts.GOLD, false, &"", glyph)
			"worship":
				p.compel(spots[i] if i < spots.size() else DominionParts.home_of(p), PRIORITY_TIME, WILL, DominionParts.GOLD,
					false, &"", glyph)
			"hide":
				p.compel(DominionParts.home_of(p), PRIORITY_TIME, WILL, DominionParts.GOLD, false, &"", glyph)
			"escape":
				p.set_badge(glyph, DominionParts.GOLD, ICON_SECONDS)
				if not p.soldier:
					p.release_from_queue()
					p.mind = Person.Mind.CALM
					p.flee()
			"ignore":
				p.set_badge(glyph, DominionParts.GOLD, ICON_SECONDS)
				p.fearless_left = maxf(p.fearless_left, PRIORITY_TIME)
		if links != null:
			links.add(p, Iso.ground_to_screen(origin) + Vector2(0, -130), DominionParts.GOLD)
	ctx.play(&"jg_rise", origin, -8.0)
	if DominionParts.staged(self):
		DominionParts.pulse(self, origin, RADIUS, DominionParts.GOLD, 0.6, 1.5)
		var wave := FxParts.shockwave(self, origin, RADIUS, VoiceOfGodFx.SOLAR)
		wave.set_param("thickness", 0.06)
		wave.tween_param("progress", 0.05, 1.0, 0.6, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		wave.tween_param("fade", 1.0, 0.0, 0.25, 0.4)
		wave.life = 0.7
