class_name VeilParts
extends RefCounted
## What every Veil effect shares (the law of the Veil, spec §4): its palette, whether this cast was made in the dark
## (Rules.cast() stamps extra["dark"]), its light or dark number for a stat (VeilRules.SIZES), and the dusk it leaves where it
## lands. Each works with no crowd (the VFX Sandbox): light size, nothing laid.

const VEIL := Color("b98cff")
const DUSK := Color("3b1470")
const SILVER := Color("cfd3e6")
const BLACK := Color("07050c")


## Whether the cast was made on dark ground (decided once, at the cast).
static func dark(fx: FxTimeline) -> bool:
	return bool(fx.extra.get("dark", false))


## The cast's number for `stat`: its dark size when cast in the dark, else its light size.
static func size(fx: FxTimeline, key: String, stat: String) -> float:
	return VeilRules.size(key, stat, dark(fx))


## Takes `p` without a trace (Crowd.take()), first letting him out of any shelter he is in (ShelterManager.release(): no-op for one
## not sheltering), so no shelter's list holds a taken person -- its next flush would set him visible and put him back in the field.
## The one release every Veil take of a shelterer uses (The Swallowing Dark, Evernight's dawn). False when nobody was taken.
static func take_out(crowd: Crowd, p: Person, kind: StringName) -> bool:
	if crowd == null or p == null or not is_instance_valid(p) or not p.is_alive():
		return false
	if crowd.shelters != null:
		crowd.shelters.release(p)
	return crowd.take(p, kind)


## Lays the dusk a Veil cast leaves where it lands: a patch of `r` (at least VeilRules.DUSK_R) at `at` for VeilRules.DUSK_TIME.
## Returns its id; 0 with no crowd or with the ledger off.
static func land(fx: FxTimeline, at: Vector2, r := VeilRules.DUSK_R) -> int:
	if fx.ctx == null or fx.ctx.crowd == null:
		return 0
	return fx.ctx.crowd.lay_dusk(at, maxf(r, VeilRules.DUSK_R), VeilRules.DUSK_TIME)
