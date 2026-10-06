class_name MissionHints
extends RefCounted
## How to win, in a line (v0.10 M6, spec §3): the HUD shows the line for the mission or act being played under its
## objectives, and a director's phase (MissionDirector.hint_phase()) can put another in its place. Kept apart from the
## logic, as CampaignText is, so a writing change never touches it. The colours named are the map tags' (spec §4).

## The Warning's line, which its act in The Long Night shares.
const WARNING_LINE := "Stop the messenger (gold arrow) before the bell tolls, or hold out until the omen fades."
## Lines by the played mission's or act's id, and by "<id>.<phase>" for a phase's own. The Feast plays The Long Night's
## act, so it has the act's line.
const LINES := {
	"warning": WARNING_LINE,
	"omen": WARNING_LINE,
	"festival": "Break the festival: kill or scatter fifty of its crowd before the guard closes the square.",
	"procession": "Kill the Prince before he boards his ship. If no one sees him die, the town is left leaderless.",
	"judgement": "Bring the Citadel down before dawn, before too many of its people escape.",
	"last_judgement": "Destroy the Citadel and break the city before time runs out. Fifty escaping loses it.",
	"miras_house": "Whisper a grieving (gold) to Mira's door while no Faithful (red) watches. Four must believe by dawn.",
	"miras_house.four": "Four believe. Keep the Believers (orange) alive until dawn, and the Gaze from filling.",
	"miras_house.burning": "Her house burns: no one can go in now. Keep your Believers (orange) alive until dawn.",
	"broken_lanterns": "Break a lantern (gold), then keep the flame-bearer off it for 20 s while it drains. Drain all six.",
	"broken_lanterns.knights": "A Knight (blue) shields the lantern he guards. Draw him off or kill him, then strike.",
	"vigil_flame": "At 0:50 the boy Wren comes for the flame (gold). Its acolytes would see him: draw them off first.",
	"vigil_flame.wren": "Whisper Wren (blue) to the flame (gold) while no Faithful but its bearer is near him (red).",
	"vigil_flame.homeward": "The Vigil turns for home: have the flame swapped before its bearer reaches the Temple.",
	"vigil_flame.carry": "Walk Wren to Mira's shrine (orange), west past the wall. Keep him out of the searchlight.",
}


## The line for the mission or act `id` in `phase`: the phase's own if it has one, else the mission's, else "".
static func line(id: String, phase := "") -> String:
	if phase != "" and LINES.has(id + "." + phase):
		return String(LINES[id + "." + phase])
	return String(LINES.get(id, ""))
