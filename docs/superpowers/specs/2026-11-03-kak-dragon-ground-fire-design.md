# KAK -- Dragonfire Parade leaves burning ground

Status: **design approved by the user** (2026-11-03, in chat). This note makes it precise. Numbers marked *guess* are
first guesses to tune in play; calls I made where the design is silent are marked *(my call)*.

## 1. The design in one paragraph

The strip Dragonfire's breath sweeps catches fire: about 8 **ground-fire patches** along the beam's path, laid as the beam
passes, at full strength. The town treats a patch as it treats a burning house: a danger people run from and route round.
Whoever runs or is pushed in burns -- the harm builds with time inside, about 1.5 s inside kills, a quick dash across leaves
them scorched and fleeing but alive; no random chance. A patch touching a burnable building can set it alight, the way
building fires spread today. Left alone a patch burns down and goes out in about 40 s. Calm citizens nearby turn out as for
a house fire, but gather round the patch's edge (never stepping in) and beat it out -- no water, no well: 3 helpers about
5 s, 1 helper about 15 s; while a patch is at full strength they wait a step back until it has burned down a little. Every
Dragonfire level lays ground; longer breaths lay more; Second Breath (level 5) lays a second strip.

## 2. Numbers

| Name | Value | Meaning |
|---|---|---|
| `GroundFire.RADIUS` | 0.7 *guess* | a patch's burning radius (ground units) |
| `PATCH_RATE` | `8.0 / BREATH_TIME` = 3.333/s | patches per second of breath (Dragonfire) |
| patches per breath | `roundi(PATCH_RATE * lv_breath_time)` | L1 8, L2 9, L3 9, L4 10, L5 11 (+11 for Second Breath) |
| `PATCH_NEAR` / `PATCH_FAR` | 2.0 / 9.5 *(my call)* | how far along the beam a patch lies (the old flames lay 1.4-9.9) |
| `BURN_DOWN` | 0.025 /s (1/40) *guess* | strength lost a second untended: 1.0 -> 0 in 40 s |
| `BEAT` | 0.06 /s per beater *guess* | strength a beater takes off a second |
| `BEAT_FROM` | 0.9 *(my call)* | "full strength" is strength above this; beaters wait until it falls to it (4 s untended) |
| `CREW` | 3 (and never more than `ResponseProfile.fire_crew`) *(my call)* | beaters per patch |
| `BURN_KILL` | 1.5 s *guess* | seconds inside that kill |
| `HARM_TICK` | 0.1 s *(my call; as SolarisPit and the Lava Pool)* | how often the fire looks for who is in it |
| `COOL` | 0.5 s a second *(my call)* | how fast heat taken leaves a person once out |
| `SCORCH_SHOW` | 8.0 s *(my call)* | how long a scorched person shows soot |
| `THREAT_PAD` | 0.3 *(my call)* | the danger's radius is `RADIUS + THREAT_PAD` = 1.0 |
| `TOUCH` | 0.3 *(my call)* | a building "touches" a patch when its footprint is within `RADIUS + TOUCH` of the centre |
| `SPREAD` | `FireManager.SPREAD` (0.08) | chance a second, at full strength, to catch a touching burnable (x `WIND_GROW` in a tornado's wind) |
| `BEAT_GAP` / `WAIT_GAP` | 0.35 / 1.0 *(my call)* | the beat ring and the wait ring: `RADIUS + gap` from the centre |
| `BEAT_SWING` | 0.6 s *(my call)* | a beater swings (the fight swing, `SWING_SHOW`) this often |
| `RENEW` | `FireManager.RENEW` (3.0 s) | how often a patch's danger is renewed |

The rates: a patch loses `maxf(BURN_DOWN, beaters * BEAT)` a second *(my call: the beaters replace the burning-down, they do
not add to it -- that is the only linear rule that gives both of the design's times)*. From `BEAT_FROM` (0.9): 1 beater
0.9 / 0.06 = **15 s**, 2 beaters 7.5 s, 3 beaters 0.9 / 0.18 = **5 s**. Untended from 1.0: **40 s**.

A dash: a panicked person runs at `Person.PANIC_SPEED` 1.6, so straight across a patch (1.4) is 0.875 s inside: scorched,
alive. A knocked-down person lies `DOWN_SECONDS + GETUP_SECONDS` = 1.7 s: pushed in and knocked flat, they burn to death.

## 3. GroundFire (one type)

`GroundFire` (`src/game/crowd/ground_fire.gd`, `class_name GroundFire`, `RefCounted`) is plain state plus the rules that need
no town: `id`, `at`, `radius`, `strength` (1.0 at laying), `out`, `beaten`, `owned` (true when a `FireManager` keeps it),
`crew` (its beaters), `threat_id`, `renew_in`, `base_angle` (the ring's first slot), and

- `burn_down(dt, beaters)` -- the rate rule above; at 0 it is `out`.
- `static scorch(field, patches, heat, dt)` -- the harm rule (section 5), shared by the town and the no-town path.

States: **burning** (`strength > 0`; "full strength" while `> BEAT_FROM`), then **out**, either **beaten** (it reached 0
with at least one beater beating) or **burned out**. It never grows, never moves, and never spreads to other ground *(my
call)*.

**Who keeps it.** In a town, `FireManager` (`Crowd.fires`) keeps every patch in `patches` (lay order) and steps it with the
town's fires: burn-down, harm, danger, catching buildings, beaters. Fires stay keyed by `Structure` exactly as today: the
patches are a separate list, so nothing that reads `fires` (missions, rescue squads, engineers, routes) changes. With no
town (the sandbox, staged tests) the patch's sprite steps it itself: burn-down and harm only (no danger, no buildings, no
beaters) *(my call)*.

**The Lava Pool is not converted** *(my call)*: its rule is different on purpose (lava kills on contact, cannot be beaten
out, R13 of the Ruin levels) and changing it would move Cinderfall's level 5. `GroundFire` is written so a later power can
use it.

## 4. Laying (Dragonfire)

- Breath `b` lays `n = roundi(PATCH_RATE * lv_breath_time)` patches. Patch `i` (0..n-1) is laid on the first frame the
  breath's progress `k` (`(t - _breath_start) / lv_breath_time`) reaches `(i + 0.5) / n`, on the beam's current angle,
  at `PATCH_NEAR + (PATCH_FAR - PATCH_NEAR) * fposmod(phase + i * 0.618034, 1.0)` along it (a golden-ratio scatter: no two
  patches in a row lie at the same distance). `phase` is 0.5 for the first breath and 0.0 for Second Breath's, so the two
  strips interleave *(my call)*.
- **No random numbers**: where a patch lies depends only on the arc and the clock, never on `ctx.rng` *(my call)*. The old
  decorative `_fire_patch()` flames (two every 0.09 rad of sweep, burning to the effect's end, drawing on `ctx.rng`) are
  **replaced** by the patches, which are their lasting form.
- A point inside a river (`City.current().rivers()`) or outside `ctx.field.bounds` gets no patch *(my call)*; anywhere else
  does, including over a building (which it may then set alight).
- `strips: Array` (one `Array[GroundFire]` per breath) and `patches_laid` are public, for tests.
- Every level lays ground; the patch's own numbers are level-free *(my call)*: a higher level lays more because its breath
  is longer (and its sweep wider).

## 5. Burn harm and "scorched"

Every `HARM_TICK`, for every patch (lay order) and everyone alive in the field within its `radius` (field order), not
`inside` a building: that person is **in the fire** this tick (once, however many patches overlap). Each person's heat is a
number of seconds kept in a `heat` dictionary (`{DummyEnemy: {"heat": float, "in": bool}}`, insertion order):

- In the fire: `heat += HARM_TICK`. At `heat >= BURN_KILL - 0.001` (float drift) they die, `field.kill(e, &"fire", at)`.
- Entering (not in last tick) a living `Person` is frightened by it: `panic(at, radius + THREAT_PAD, &"fire", false)` -- the
  new `startle := false` skips the startle freeze (nobody freezes standing in fire) *(my call)*; `panic()`'s own rules
  still apply (a Dominion, the fearless, the fleeing keep their course). A `Person` in the fire gets
  `scorched_left = SCORCH_SHOW`.
- Out of the fire: `heat -= COOL * HARM_TICK`; at 0 the entry is dropped. A second dash soon after a first is more
  dangerous.
- **Scorched**: `Person.scorched_left > 0` draws the person darkened toward soot (the `flash()` overlay path with a soot
  colour at about 0.45, fading with `scorched_left`) *(my call)*. It changes nothing else: their flight is the panic they
  already have.
- Fire kills a soldier or a Knight as it kills a citizen (health is for blows) *(my call)*. Anyone in a patch burns, beaters
  included.

## 6. Danger and routing (like a burning house)

- At laying, and every `RENEW` after, a patch registers `threats.register(at, radius + THREAT_PAD, 0.5, RENEW + 0.5, 5.0,
  7.0, &"fire")` -- a burning house's numbers. So: calm people who wander within the danger plus `Person.THREAT_MARGIN` run
  from it (`Crowd._watch_threats()`), every path bends round it (`EvacuationManager._weigh_danger()`, the grid weight), the
  routine does not send anyone onto it. A veiled patch (Unseen Hour) registers nothing (the manager's `blind`), as today.
- When a patch goes out its danger ends at once: new `ThreatManager.end(id)` moves it to the recent impacts exactly as
  expiry does *(my call: otherwise beaters standing down would be frightened by a fire they just put out)*.

## 7. Buildings catching

Each `FireManager` step (`HZ`, 4 a second), a patch rolls `rng.randf() < strength * SPREAD * (WIND_GROW if windy) * dt`
(today's building rule); on a hit the first standing burnable (`FireManager.burns()`) within `radius + TOUCH` of its centre
(`env.near` order) that is not already burning is `ignite(s, START)`. The roll uses a **separate** generator
`_patch_rng`, seeded at setup from the manager's seed + 1 *(my call)*, so building fires elsewhere draw exactly the numbers
they draw today.

## 8. Beaters

- **Who turns out.** In `FireManager._recruit()` (every 1 s), after the building fires *(my call: a house comes first)*, under
  the same rules as the brigade -- the alarm stage at least the profile's `fire_from` and below Evacuation, the patch not
  veiled -- each burning patch short of `mini(CREW, profile.fire_crew)` beaters takes the nearest calm citizens: `CALM` or
  `RECOVER`, with a profile, alive, not inside, not in a patch, within `RECRUIT_REACH` (10). Sorted by distance, ties by
  their order in `Crowd.citizens` *(my call: `sort_custom` is not stable)*. Soldiers, rescue squads and engineers do not beat
  ground fires *(my call)*; nothing reads patches but `FireManager`.
- **Person.** `beat(patch)`: `mind = ASSIST` (so `intent()` is `ASSIST` and threats do not frighten it, as a bucket carrier),
  `assist_patch = patch`, `assist_fire = null`, `assist_beating = false`. `stand_down()` and the hold's `ASSIST` case clear
  `assist_patch` and `assist_beating` too.
- **Where they stand.** Slot `k` of a crew (0..CREW-1) lies at angle `base_angle + k * TAU / CREW`; `base_angle` is the
  angle from the centre to the first recruit. Beat spot: `at + dir * (radius + BEAT_GAP)`; wait spot: `radius + WAIT_GAP`.
  A spot is good if walkable (`Crowd._spot_near(spot, 0.1)`), within `radius + BEAT_GAP + 0.3` of the centre (beat) and not
  within `radius + 0.2` of any burning patch; otherwise the slot turns by `TAU / 8`, up to 8 tries; none, the recruit is
  not sent. **No goal is ever inside a patch.**
- **The round** (every frame, `_tend_beaters()`): walking, wait. Arrived: while the patch is at full strength
  (`> BEAT_FROM`), go to (or stay at) the wait spot, not beating; once it is not, go to the beat spot; there,
  `assist_beating = true`, face the patch and swing every `BEAT_SWING`. A beater counts toward the rate only while beating
  and within `radius + BEAT_GAP + Person.GOAL_REACH` of the centre.
- **Standing down.** The patch out (beaten or burned out) -> every beater `stand_down()`; the evacuation (not `assist_stays`)
  -> stand down; a beater whose mind changed (frightened off by a cast, in a patch itself) leaves the crew, and the next
  recruitment replaces it.
- Counters (for the behaviour reports): `patches_laid`, `patches_beaten`, `patches_burned_out`.

## 9. Visuals and sound

`GroundFireSprite` (`src/fx/set2/ground_fire_sprite.gd`, `class_name`, `Node2D`, group `fx_lasting` as `SolarisPit` and
Earthshatter's `Fissure`), made by Dragonfire for each patch and **not** tracked by the effect, so it outlives the cast:

- In `ctx.world` (y-sorted with people and buildings): two `FlameSprite`s (set2), sized 0.8-1.2, their `strength` following
  `sqrt(patch.strength)`; an ember `PixelParticles` (`FxParts.EMBER_LIFE`, about `5 * strength` a second) and a thin smoke
  `PixelParticles` (`FxParts.SMOKE_LIFE`), both built directly (FxParts' helpers need a live `FxTimeline`).
- A ground node in `ctx.ground`: a scorch decal (`FxParts.SH_DECAL`, Dragonfire's fissure palette `ff6a1a`/`ffd27a`, `heat`
  = strength) and a light pool (`FxParts.SH_LIGHT`, `FIRE_LIGHT`, radius 1.2, intensity `0.7 * strength`, flickering),
  registered with `ctx.lights`.
- Out: beaten -> a grey smoke puff (8 particles); either way the flames shrink over 0.6 s, the scorch fades over 6 s, then the
  sprite frees itself. `FireManager.clear()` puts every patch out (so sprites go); `Battlefield.clear_effects()` frees the
  sprites and calls `crowd.fires.clear_patches()` so no unseen fire is left *(my call)*.
- Its particles' generator is seeded from the patch's `id`, never from `ctx.rng`.
- **Sound** *(my call; no new assets)*: one `orb_embers` loop (-6 dB) per strip, played at the strip's first patch and faded
  (1.0 s) by that patch's sprite when every patch of its strip is out. Dragonfire's existing `laser_fire` burn voice at the
  sink is kept. Beating has no cue of its own.

## 10. What changes, and what must not

- **Level 1 changes on purpose.** Every reference row whose run casts Dragonfire moves and is re-recorded with the reason;
  every mission gate whose loadout drafts Dragonfire is re-run and must pass its bar.
  - Rows (12 expected): `lanterns_b_play_1-3` (`routes_t2.tsv`), `lanterns_toll_1-3` (`lantern_night2.tsv`),
    `judgement_b_play_1-3` and `night_b_play_1-3` (`routes_t5.tsv`; the night's only if its Judgement act casts it).
    `lanterns_none` (`references.tsv`) never casts and must not move.
  - Gates: Broken Lanterns route a (`gate.sh lanterns`), its toll case, its route b; Last Judgement route b; The Long Night
    route b. No Hunt, rite, Tier 1 route or Capital run drafts Dragonfire (`grep '"dragon"'` over `tools/dev/routes`,
    `src/game/mission`, `tools/dev/behaviour_check.gd`).
- **Nothing else may move**: `digest` `61267b7e90524d800bf1c3473a71146b`, `crowd_check` `-935602679`, every non-Dragon row.
  With no patch laid, `FireManager` does exactly what it does today (same calls, same `_rng` draws, same order).
- Deterministic: no `randf()`, no wall clock; field order, lay order, citizen order.

## 11. Out of scope (ideas for later)

Water powers or rain putting patches out; Magnify raising a patch; patches spreading over ground; the Lava Pool as a
`GroundFire`; a beating sound; rescue squads and engineers beating ground fires.
