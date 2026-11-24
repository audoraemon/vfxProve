# KAK Mission Clarity: Summary

Goal: every mission step and hint says exactly what to do, in one verb vocabulary. A cast that lands on a target but does not count says why, in a short banner. No rule, number, timing, tag or reference changed. All 233 reference rows stay byte-identical.

Spec: `docs/superpowers/specs/2026-11-19-kak-mission-clarity.md`. Plan: `docs/superpowers/plans/2026-11-19-kak-mission-clarity.md`. Rulings: `docs/KAK_Mission_Clarity_Rulings.md`.

## What was built

- `MissionVerbs` (`src/game/mission/mission_verbs.gd`): one table of twelve verbs and the powers that do each. Steps, hints, tests and the legend all read it.
- `MissionDirector.why_not(key, at)`: a read-only question each director answers. The HUD shows the answer as a banner through `WhyNotGate` (the same text waits 30 s to repeat, and any banner waits 4 s).
- `hint_phases()` and read-only `hint_seconds()` / `step_seconds()` overrides, so a hint can name its phase and count down.
- A test kit (`tests/clarity_kit.gd`) that casts the real power through `Rules.cast()`. Each verb a text names has a case that proves it. Each why-not has a case that shows the claim is true.
- Six group suites: `test_clarity_assassinate`, `_convert`, `_intercept`, `_hunt`, `_escort`, `_raze`. Also `test_why_not`, `test_mission_verbs` and `test_legend`.

## The twelve verbs and their powers

Powers are listed by key, in book order. The table is `MissionVerbs.VERBS`.

| Verb | What it does | Powers |
|---|---|---|
| Kill | they die, by any power | 30 keys: doom, smite, deathmark, raise, hellspark, breath, heaven, scatter, houndgate, gravecall, tornado, pestilence, walker, dragon, tsunami, gravity, laser, orbital, cinder, judgement, glacial, solaris, gatebelow, tempest, shatter, pale, cage, serpent, gravetide, nova |
| Scare | citizens run from a loud power near them | every power that is not quiet. Soldiers are not frightened by ordinary loud casts |
| Lead | one walks where you click | whisper |
| Lure | they walk to a light or a body and stare | deathmark, windfall, wisp |
| Confuse | they wander, blind, and drop their task | discord |
| Hold | the god's hand on a mind: they drop their task | 19 keys: whisper, deathmark, windfall, wisp, discord, belllies, congregation, oath, echo, turncoat, clearmind, saint, priority, verdict, anathema, sanctuary, voice, schism, fargate |
| Burn | sets a building alight | ember, dragon, cinder |
| Strike | a blow on a building or thing | 14 keys: smite, heaven, scatter, tornado, tsunami, gravity, laser, orbital, judgement, glacial, solaris, tempest, shatter, nova |
| Rot | rots a building or a thing | blight |
| Seal | NO LEAVING on a door | noleave |
| Banish | sets them down outside the walls | mirror, skylift |
| Calm | ALL IS WELL: the town stands down | belllies |

Ember is not a Kill power. It only lights a building, and the fire is the town's.

## The legend's third page

`H` opens the legend of marks. `H` again turns to page 2, and again to page 3, "WHAT YOUR POWERS DO". Page 3 lists the twelve verbs and, for each, the powers in this night's loadout that do it (a long list is cut with "+N"). The counter reads "n / 3". `Mission.open_legend()` passes the loadout to the panel.

## Why-not banners by mission

A banner shows only when a cast lands on a target and does not count, and no other verb in that cast counted. Banners are upper case and short (the convert group's run 28-36 characters).

**Assassinate**
- The Informer: TOO EARLY - NO WORD YET; THEY WALK BACK TO HIS DOOR; ONLY CONFUSE OR LEAD TURNS HIM.
- The Tax Collector: HE IS INDOORS - WAIT AT THE DOOR; SEAL A DOOR HE WENT IN AT; TOO SOON - SEAL AS HE COMES OUT; HIS GUARD (BLUE) STOPS THE MOB.
- The Bishop: HIS KNIGHTS (RED) BEAT IT OUT.
- Expel the Inquisitor: A WARDEN ONLY HIDES - KILL HIM; STILL SHAKEN - SCARE HIM AGAIN SOON.

**Convert and rite**
- First Prayers: TOO FAR TO PULL THE FAITHFUL, and Mira's House's HELD banner.
- Mira's House and The Sermon: HELD, HE STILL SEES - CONFUSE HIM (The Sermon keeps only the held-sentry cause).
- The Vigil Flame: AN ACOLYTE (RED) WOULD SEE; ONLY WREN (BLUE) CAN TAKE IT.
- The Relic Run: NO LURE YET - PIP MUST FOLLOW YOU.
- Broken Lanterns: A KNIGHT (BLUE) SHIELDS IT; HE STILL STANDS BY IT - LEAD HIM OFF.
- The First Taste: HELD, HE ONLY LOSES TIME.

**Intercept**
- The Warning: HE STOPS, BUT KEEPS THE WARNING.
- Bell-Ringers: CONFUSED, HE STILL SEES - LEAD HIM (a mate), and the Warning banner for a carrier.
- Silence the Witness: the carrier banner only.
- Starfall: the Warning banner, over every warning out (any cast that could stop one says nothing).
- The Festival: ONLY FEAR OR DEATH BREAKS THEM.
- Market Panic: THE WARDEN STANDS FAST; A WARDEN (RED) STEADIES THEM; and the Festival banner.
- The Procession: THAT ONLY HALTS HIM - KILL HIM.

**Hunt**
- The Heretic Hunt: GUARDED (RED) - IT ONLY SHAKES; HELD, HE STILL GUARDS - LEAD HIM OFF.
- The Lantern's Eye: HELD, HE STILL WORKS - LEAD HIM OFF.
- Break the Hunt: HIS ESCORT (RED) STEADIES HIM, and the Hunt banners.

**Escort**
- The Lost Lamb: HE IS HELD - FREE HIM FIRST; TOO FAR - HE ANSWERS A NEAR LIGHT.
- The Prisoner: BOUND - SHE CANNOT HEAR YOU; PAST FEAR WHILE SHE IS BOUND.
- Face Halcyon: BOUND - HE CANNOT HEAR YOU; STILL GUARDED - HOLD MORE ESCORTS.
- Exodus and Hide the Faithful: none (a whisper on a believer is not ignored by the code).

**Raze**
- Spoiled Harvest: NO GRAIN YET - THE FIRE GOES OUT; A WATCHMAN (RED) PUTS IT OUT; LURED, HE STILL WATCHES IT; KILLING THE CARTER SPOILS NOTHING. Rot keeps the existing BlightFx banners.
- The Crown's Bread: AN ENGINEER (RED) MENDS IT; LURED, HE STILL MENDS IT; STONE - STRIKE IT, FIRE DOES NOTHING.
- The Armoury: ARMED MEN (RED) GUARD IT; NOT MUSTERING - IT TAKES NO HARM; STONE - STRIKE IT, FIRE DOES NOTHING.
- The Heart of Faith: A KNIGHT (RED) PUTS IT OUT; IN HIS LITTER - KILL HIS BEARERS; NOT IN USE - THE FIRE GOES OUT.
- Last Judgement and Judgement: none (copy only).

## Open questions for you (Q1-Q8, as asked)

These are rule changes the text would need. None was made.

- **Q1 The Informer before word.** Should a contact be workable before word reaches him (or his company stay where you put them)? Today nothing counts and the text can only say "wait". The user's own case.
- **Q2 One "held" rule.** "A held man sees nothing / stops guarding" is four rules: `held_by_god()` (Escort, Exodus, Bishop, Armoury, Heart, the Hunts' escorts), `MissionDirector.BLIND` (Faithful sight, the Informer's onlookers, the Hunt guards and wrights), `GUARD_MINDS` (Harvest, Market Panic, Crown's Bread: a lured man still guards) and distance alone (Broken Lanterns' Knights). One rule would let "Hold" mean the same everywhere.
- **Q3 Witnesses.** Unseen kills in the Warning, Bell-Ringers, Procession and Assassinate count held minds as witnesses (`Crowd.nearest_witness()`); the Hunts' mates and Faithful do not.
- **Q4 Market Panic wardens are fearless** on guard, unlike Harvest's watchmen whose numbers they copy: Scare never removes one.
- **Q5 The Relic Run's Wisp rule**: a Wisp draws the watch only once Pip is led by light or oath -- hard to say in a line.
- **Q6 The Relic Run's `citadel` phase**: once the last halt passes unswapped, nothing the player does saves the relic (unless Task 4 finds that a cart stood by its dead hands lets Pip board). The lessons forbid a dead end.
  - Task 4 tested it. Past the last halt no halt ever begins, so Pip cannot board, even at a cart stood by its three dead hands (all three killed, 34 s run). It is a dead end. The step now says so plainly: "The relic is lost at the Citadel". Removing the dead end is a rule change and is yours to decide.
- **Q7 The Tax Collector `inside`**: 20 s indoors with nothing to do but Seal; most loadouts only wait.
- **Q8 Hidden consequences**: a loud power near a waiting Bell-Ringers post sends its ringer at once; a cast by the counting-house door smokes the next collector out. They are rules, not why-nots; a banner for them would be a new feature.

## A fix made on the way

Controller fix e31dcca6's parent (clarity/t3): a Skylift on the Informer's contact before word now says TOO EARLY - NO WORD YET (the user's own report); on his company it still says nothing (pre-flight I1).

## Tour captions that still name a power (for a later pass)

Grepping every `tour()` string for power names finds two:

- Exodus: "At %s, whisper its lamp to the postern; the rest follow." The verb is Lead.
- The Informer: "Turn him with a whisper: do not kill him." The verb is Lead.

The Lantern's Eye tour says "mirror" and "shatter". That is the Halcyon mirror in the town, not a power, so it is fine.

## Not done here

- No rule changed, so no reference moved. The full suite, FLOW and the 233 references are run by the controller.
- A quiet-machine rerun of the frame-time checks (test_pale, decree_cage, horde, tide) is still owed. They fail only under load.
