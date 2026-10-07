class_name MissionHints
extends RefCounted
## How to win, in a line (v0.10 M6, spec §3): the HUD shows the line for the mission or act being played under its
## objectives, and a director's phase (MissionDirector.hint_phase()) can put another in its place. Kept apart from the
## logic, as CampaignText is, so a writing change never touches it. The colours named are the map tags' (spec §4).

## The Warning's lines, which its act in The Long Night shares (board tags: the colours are its tags').
const WARNING_LINE := "Kill the messenger (gold) with no one near (red) before he warns the bellkeeper (blue)."
const WARNING_RELAY := "Someone saw: a witness (gold) carries the warning on. Strike again where no one (red) is near."
const WARNING_BELL := "The bell is called. Kill its ringer (gold) unseen before the bell tolls."
## Last Judgement's lines for the rite and the fallen Citadel, which Judgement (its act in The Long Night) shares.
const RITE_LINE := "The clergy gather for the Banishing Rite (red). Break it, or it cuts your time short."
## Lines by the played mission's or act's id, and by "<id>.<phase>" for a phase's own. The Feast plays The Long Night's
## act, so it has the act's line.
const LINES := {
	"warning": WARNING_LINE,
	"warning.relay": WARNING_RELAY,
	"warning.bell": WARNING_BELL,
	"warning.waiting": "That warning is dead. Watch the next star's gate (gold): its watchman runs when it falls.",
	"omen": WARNING_LINE,
	"omen.relay": WARNING_RELAY,
	"omen.bell": WARNING_BELL,
	"festival": "Break the festival: kill or scatter enough of its crowd (gold) before the guard closes the square.",
	"festival.packed": "The bonfire packs the crowd (gold) round the fountain: one strike there breaks many.",
	"festival.address": "The Mayor (orange) speaks from the fountain. Kill him and the crowd round it panics.",
	"procession": "Kill the Prince (gold) before he boards. If no one near (red) sees it, the town is left leaderless.",
	"procession.blessing": "The Prince holds at the cathedral steps for the blessing. Strike while he stands still.",
	"procession.dock": "The Prince waits at the dock. He boards as soon as his ship is in: kill him first.",
	"judgement": "Bring the Citadel (gold) down before dawn, before too many of its people escape by the gates (red).",
	"judgement.rite": RITE_LINE,
	"judgement.fallen": "The Citadel is down. Break the city's stability before dawn, and keep its people in.",
	"last_judgement": "Destroy the Citadel (gold) and break the city in time. Fifty escaping by the gates (red) loses it.",
	"last_judgement.rite": RITE_LINE,
	"last_judgement.fallen": "The Citadel is down. Break the city's stability before time runs out. Fifty escaping loses it.",
	"miras_house": "Whisper a grieving (gold) to Mira's door while no Faithful (red) watches. Four must believe by dawn.",
	"miras_house.four": "Four believe. Keep the Believers (orange) alive until dawn, and the Gaze from filling.",
	"miras_house.burning": "Her house burns: no one can go in now. Keep your Believers (orange) alive until dawn.",
	"broken_lanterns": "Break a lantern (gold), then keep the flame-bearer off it for 20 s while it drains. Drain all six.",
	"broken_lanterns.knights": "A Knight (blue) shields the lantern he guards. Draw him off or kill him, then strike.",
	"vigil_flame": "Soon the boy Wren comes for the flame (gold). Its acolytes would see him: draw them off first.",
	"vigil_flame.wren": "Whisper Wren (blue) to the flame (gold) while no Faithful but its bearer is near him (red).",
	"vigil_flame.homeward": "The Vigil turns for home: have the flame swapped before its bearer reaches the Temple.",
	"vigil_flame.carry": "Walk Wren to Mira's shrine (orange), west past the wall. Keep him out of the searchlight.",
}


## The line for the mission or act `id` in `phase`: the phase's own if it has one, else the mission's, else "".
static func line(id: String, phase := "") -> String:
	if phase != "" and LINES.has(id + "." + phase):
		return String(LINES[id + "." + phase])
	return String(LINES.get(id, ""))
