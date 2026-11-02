class_name GodTreeDev
extends RefCounted
## The dev fill for the god tree (god P1, spec §15, Ruling P2): enough keys in the tree's shape to test and script Endless Night with,
## kept apart from GodTree.TABLE so the real fill is never touched. GodTree merges it over the real table's empty spots only when
## GodTree.dev_fill is on (Endless Night entered from the DEV tab, and tests that turn it on). Test and scripted play only;
## *tunable*, not the user's fill.

## Same shape as GodTree.TABLE: type -> five tiers of two keys, "" for a spot left empty.
## Ruin's row mirrors the user's picks (2026-11-02) and puts Heaven Splitter, Gravity Distortion and Judgement in its empty spots;
## Death's and Veil's Tier 2 take Orbital Strike and Walking Laser Grid for Light of Solaris and Tsunami Breaker, now Ruin's.
const TABLE := {
	"ruin": [["smite", "ember"], ["tornado", "heaven"], ["solaris", "dragon"], ["tsunami", "cinder"], ["gravity", "judgement"]],
	"death": [["deathmark", "pestilence"], ["glacial", "orbital"], ["", ""], ["", ""], ["", ""]],
	"veil": [["doom", "blight"], ["laser", "nova"], ["", ""], ["", ""], ["", ""]],
	"passage": [["thorns", "mirror"], ["", ""], ["", ""], ["", ""], ["", ""]],
	"decree": [["noleave", "belllies"], ["magnify", "abolition"], ["", ""], ["", ""], ["", ""]],
	"dominion": [["whisper", "wisp"], ["discord", "madness"], ["oath", "echo"], ["turncoat", "hatred"], ["priority", "verdict"]],
}
