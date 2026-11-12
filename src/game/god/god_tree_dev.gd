class_name GodTreeDev
extends RefCounted
## The dev fill for the god tree (god P1, spec §15, Ruling P2): enough keys in the tree's shape to test and script Endless Night with,
## kept apart from GodTree.TABLE so the real fill is never touched. GodTree merges it over the real table's empty spots only when
## GodTree.dev_fill is on (Endless Night entered from the DEV tab, and tests that turn it on). Test and scripted play only;
## *tunable*, not the user's fill.

## Same shape as GodTree.TABLE: type -> five tiers of two keys, "" for a spot left empty.
## Ruin's row is the user's full tree (2026-11-02): no dev key left in it (Heaven Splitter, Gravity Distortion and Judgement are out);
## Death's and Veil's Tier 2 take Orbital Strike and Walking Laser Grid for Light of Solaris and Tsunami Breaker, now Ruin's.
## Dominion's other dev keys likewise sit under the user's picks (2026-11-06: the whole Dominion row is real), so none of them reaches play.
## Dominion's Tier 3 dev keys (Oathbound, Command Echo) sit under the user's Clear Mind and Saint or Sinner (2026-11-04), so they
## no longer reach play; the real table wins a filled spot.
const TABLE := {
	"ruin": [["smite", "ember"], ["tornado", "scatter"], ["solaris", "dragon"], ["tsunami", "cinder"], ["tempest", "shatter"]],
	"death": [["deathmark", "pestilence"], ["glacial", "orbital"], ["", ""], ["", ""], ["", ""]],
	"veil": [["doom", "blight"], ["laser", "nova"], ["", ""], ["", ""], ["", ""]],
	"passage": [["thorns", "mirror"], ["", ""], ["", ""], ["", ""], ["", ""]],
	"decree": [["noleave", "belllies"], ["magnify", "abolition"], ["", ""], ["", ""], ["", ""]],
	"dominion": [["whisper", "wisp"], ["discord", "madness"], ["oath", "echo"], ["turncoat", "hatred"], ["priority", "verdict"]],
}
