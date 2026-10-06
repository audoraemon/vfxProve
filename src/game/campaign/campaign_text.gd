class_name CampaignText
extends RefCounted
## The Lantern campaign's words (v0.10, spec §5), kept apart from its logic so a writing change never touches it: Cael's
## memory fragments, his lines during the Night 2 missions, the choice cards' lines, the titles a path gives the god, and
## the endings. Every name is a placeholder the user may change.

## Cael's memory fragments by id: shown on the night screen before the night that names them (CampaignDef.NIGHTS), and
## The Vision before the Faith and Theft endings.
const FRAGMENTS := {
	"shrine": {"title": "The Shrine", "text": "I climbed to her shrine with the dusk bells behind me. Mira kept it " +
		"for a god no one remembered. I never learned your name. She knew it. Take what's left of me. Wake."},
	"pyre": {"title": "The Pyre", "text": "Odran read the order. Venn lit the wood. I stood on the Temple steps and " +
		"said nothing. She looked for me in the crowd. Tonight they carry his flame through the streets as if nothing " +
		"happened."},
	"lanterns": {"title": "The Lanterns", "text": "She hated the Feast. Every lantern is a prayer to him, she said, " +
		"and he never looks at who lights them. Tomorrow the whole town lights one."},
	"vision": {"title": "The Vision", "text": "My vision said a heretic kept the old shrine. Odran asked me who. I " +
		"told him. That is why I gave you my life. Not faith. Debt."},
}
## Cael's line on a Night 2 card, by mission (spec §5.3). Night 3's cards use The Long Night's own lines.
const CARD_LINES := {
	"miras_house": "She'd want them to know you. Let them find her words.",
	"vigil_flame": "He gave this town his light. Take it back.",
	"broken_lanterns": "Break his lanterns. Let him feel how small his town is.",
}
## Cael's lines during the Night 2 missions (spec §5.2), by mission and by the event that brings them: each is shown as a
## subtitle under the banners when its event happens (MissionDirector._say()). A mission or event with no line has none.
const CAEL_LINES := {
	"miras_house": {"venn": "Venn. She lit Mira's pyre.", "fire": "They're burning her again. Get them out."},
	"vigil_flame": {"wren": "The boy wants that lantern. Let him have it.",
		"light": "He's looking. Don't let him see the boy."},
	"broken_lanterns": {"drained": "Feel that? That was his.", "knights": "Odran's knights. He's frightened."},
}
## Who speaks in a mission: the HUD names him before each line.
const SPEAKER := "Cael"
## The god's title by its strongest path; "" before any path night.
const TITLES := {"": "The Forgotten", "faith": "The Prophet's God", "theft": "The Deceiver", "ruin": "The Kataclysm"}
## A path's name on its card.
const PATH_NAMES := {"faith": "Faith", "theft": "Theft", "ruin": "Ruin"}
## The endings (spec §5.4): a title, Cael's epilogue, and a note for the two that have no playable last night yet.
const ENDINGS := {
	"new_faith": {"title": "The New Faith", "text": "They pray at her shrine now, quietly, in the dark. They don't " +
		"know your name either. They call you hers.", "note": "A playable last night for this path comes later."},
	"false_lantern": {"title": "The False Lantern", "text": "The lanterns still burn and they still pray to him. " +
		"But it's you who hears them now, and he hasn't noticed yet.",
		"note": "A playable last night for this path comes later."},
	"kataclysm": {"title": "The Kataclysm", "text": "There's no one left to light a lantern. He's starving. So are " +
		"you. Was this what she prayed for?", "note": ""},
	"eaten": {"title": "Eaten", "text": "He found us. I'm sorry, Mira.", "note": ""},
}


## Cael's line for `event` in the mission `mission_id`, or "" when he has none.
static func cael_line(mission_id: String, event: String) -> String:
	var lines: Dictionary = CAEL_LINES.get(mission_id, {})
	return String(lines.get(event, ""))
