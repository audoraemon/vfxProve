class_name GodTreeDev
extends RefCounted
## The dev fill for the god tree (god P1, spec §15, Ruling P2): enough keys in the tree's shape to test and script Endless Night with,
## kept apart from GodTree.TABLE so the real fill is never touched. GodTree merges it over the real table's empty spots only when
## GodTree.dev_fill is on (Endless Night entered from the DEV tab, and tests that turn it on). Test and scripted play only;
## *tunable*, not the user's fill.

## Same shape as GodTree.TABLE: type -> five tiers of two keys, "" for a spot left empty.
const TABLE := {
	"ruin": [["smite", "ember"], ["heaven", "tornado"], ["dragon", "gravity"], ["laser", "orbital"], ["cinder", "judgement"]],
	"death": [["deathmark", "pestilence"], ["glacial", "solaris"], ["", ""], ["", ""], ["", ""]],
	"veil": [["doom", "blight"], ["tsunami", "nova"], ["", ""], ["", ""], ["", ""]],
	"passage": [["thorns", "mirror"], ["", ""], ["", ""], ["", ""], ["", ""]],
	"decree": [["noleave", "belllies"], ["magnify", "abolition"], ["", ""], ["", ""], ["", ""]],
	"dominion": [["whisper", "wisp"], ["discord", "madness"], ["oath", "echo"], ["turncoat", "hatred"], ["priority", "verdict"]],
}
