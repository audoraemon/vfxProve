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
## A ground footprint to outline (Mira's house); an empty Rect2 for none.
var outline := Rect2()


## A person: a diamond over the head, labelled if given, pointed at from the edge if asked.
static func person(p_at: Vector2, p_color: Color, p_label := "", p_edge := false) -> MapTag:
	var t := MapTag.new()
	t.at = p_at
	t.color = p_color
	t.label = p_label
	t.edge = p_edge
	return t


## One of a crowd: a small diamond, no label.
static func pip(p_at: Vector2, p_color: Color) -> MapTag:
	var t := person(p_at, p_color)
	t.size = PIP_SIZE
	return t


## A place: a labelled diamond `p_rise` world pixels up (a building's height; 0 on the ground) and PLACE_LIFT over that,
## pointed at from the edge unless told not to be.
static func place(p_at: Vector2, p_color: Color, p_label: String, p_rise := 0.0, p_edge := true) -> MapTag:
	var t := person(p_at, p_color, p_label, p_edge)
	t.rise = p_rise
	t.lift = PLACE_LIFT
	return t


## The HUD can draw it: its point is a real one (not Vector2.INF).
func valid() -> bool:
	return at.is_finite()
