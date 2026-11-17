class_name MapTag
extends RefCounted
## One thing the HUD points out on the map (v0.10 M6, spec §2.1): a coloured diamond over a ground point, raised by
## `rise` world pixels (a building's height) and then `lift` screen pixels, with a label above it if it has one, the
## outline of a ground footprint if it has one, and -- with `edge` -- an arrow at the screen's edge while it is off
## screen. A director makes them in MissionDirector.tags(); the HUD draws them (Hud._draw_tags()).

## A person's diamond sits this far above their feet (v0.10's marks); a place's, this far above its top (screen px).
const PERSON_LIFT := 22.0
const PLACE_LIFT := 8.0
## A diamond's half size, and a crowd pip's.
const SIZE := 4.0
const PIP_SIZE := 3.0

## The ground point (ground units).
var at := Vector2.ZERO
## The diamond's, the label's and the arrow's colour.
var color := Color.WHITE
## A few words in upper case; "" for a plain mark.
var label := ""
## World pixels above the ground point: a building's height (Structure.height), 0 for a person or a spot.
var rise := 0.0
## Screen pixels above that.
var lift := PERSON_LIFT
## The diamond's half size.
var size := SIZE
## Off screen, an arrow at the screen's edge points to it.
var edge := false
## The person the tag marks (2026-11-17 tag fix): its drawn body places the diamond over its head at any zoom (Hud.tag_point()), and
## the tag shows only while that body is drawn (drawn(), Hud.shown_tags()). Null for a spot or a place. A director makes it by handing
## MapTag.person() / pip() the Person itself, never its ground_pos: a point copied off a person is what let a tag float where nobody was drawn.
var who: DummyEnemy = null
## A ground footprint to outline (Mira's house); an empty Rect2 for none.
var outline := Rect2()
## A fill from 0 to 1 the HUD draws as a ring round the diamond (god P3, MS §2: a breaker's grip on a chained captive, the clergy's cleanse);
## -1 for none, the default, so every other tag draws as before.
var ring := -1.0


## A person: a diamond over the head, labelled if given, pointed at from the edge if asked. `p_at` is the Person (or any DummyEnemy) -- the
## tag then follows its drawn body (`who`) -- or, for a spot that is no one's body (a litter, a cart's lantern), a ground point.
static func person(p_at: Variant, p_color: Color, p_label := "", p_edge := false) -> MapTag:
	var t := MapTag.new()
	if p_at is DummyEnemy:
		t.who = p_at
		t.at = (p_at as DummyEnemy).ground_pos
	else:
		t.at = p_at
	t.color = p_color
	t.label = p_label
	t.edge = p_edge
	return t


## One of a crowd: a small diamond, no label.
static func pip(p_at: Variant, p_color: Color) -> MapTag:
	var t := person(p_at, p_color)
	t.size = PIP_SIZE
	return t


## A place: a labelled diamond `p_rise` world pixels up (a building's height; 0 on the ground) and PLACE_LIFT over that,
## pointed at from the edge unless told not to be.
static func place(p_at: Vector2, p_color: Color, p_label: String, p_rise := 0.0, p_edge := true) -> MapTag:
	var t := person(p_at, p_color, p_label, p_edge)  # a Vector2: never a person's
	t.rise = p_rise
	t.lift = PLACE_LIFT
	return t


## The HUD can draw it: its point is a real one (not Vector2.INF).
func valid() -> bool:
	return at.is_finite()


## Its person's body is drawn where the player can see it: true for a tag that marks no one; for a person, alive or still lying there
## (DummyEnemy.tag_drawn(): in the tree, visible, not faded out, not indoors).
func drawn() -> bool:
	return who == null or (is_instance_valid(who) and who.tag_drawn())


## The tags as the map shows them (2026-11-17 tag fix): each whose person is drawn as it is; one whose person has gone indoors (Person.inside:
## a shelter, a house, a cell -- its ground_pos is where it went in) as a labelled place there reading " - INSIDE", if it had a label, so
## the player is told where it went instead of seeing a diamond over no one; any other whose person is not drawn (freed, faded, hidden)
## left out. The directors' own lists are untouched. Out of the tree (a model world) every tag shows as made.
static func shown(tags: Array[MapTag]) -> Array[MapTag]:
	var out: Array[MapTag] = []
	for t in tags:
		if t.drawn():
			out.append(t)
		elif t.label != "" and is_instance_valid(t.who) and t.who.is_alive() and bool(t.who.get("inside")):
			var p := place(t.who.ground_pos, t.color, t.label + " - INSIDE", 0.0, t.edge)
			p.ring = t.ring
			out.append(p)
	return out
