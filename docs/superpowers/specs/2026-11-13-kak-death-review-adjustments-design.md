# KAK Death powers: review adjustments (2026-11-13)

Source: the user's review in the Discord #ideas post "Death's Abilities Review and Need some adjust" (2026-11-13),
plus their answers to four follow-up questions on the same day. This amends
`docs/superpowers/specs/2026-11-12-kak-death-authority-powers-design.md`; where the two disagree, this document wins.

Branch: `god/death-review`, cut from `origin/feat/god-progression` a00ca40b (Death + Decree trees). Lands on
feat/god-progression. Not Develop-Main.

## Why

The user played the ten Death powers. The common complaint: the effects look small, cute or unclear, and two powers
(Raise SPIRIT possession, Corpse Guise) are not understood. The tree should feel dangerous and frightening, and every
power should show the player what it will touch before the click.

## Goals

- Every Death power reads clearly before and during the cast.
- The big powers (Tier 4-5) look and feel like a cataclysm.
- Walking Corpse becomes the Death tree's controllable power (like Mind Whisper).

## Non-goals

- No change to the tree layout (`GodTree.TABLE` Death row), costs, cooldowns or the levels system, except where a
  change below needs a new number.
- No new powers.

## Anti-goals

- No frame-rate cliff. Pale Reign's horde and Grave Tide must hold frame rate in the 220-person town (budget as the
  Doors of the Dead: 1-5 ms a frame for the effect's own cost).
- No luck: ghosts, wraiths and the giant pick targets by rule (nearest; soldiers first where stated).
- Silent powers (Corpse Guise, Walking Corpse) still never raise the town's alarm.

## Changes, per power

### Raise the Dead `raise` (Tier 1)
1. **Body indicator.** While aiming, every body (remain) inside the cast ring is highlighted (a pale outline or glow
   plus a small marker), so the player sees which bodies will rise. Bodies outside the ring are not highlighted.
2. **Faster zombies.** Zombies move at about a living person's walk speed, or a little faster when they chase.
   Today they shamble at 0.6x.
3. **SPIRIT mode loses possession.** A raised spirit no longer possesses anyone. It haunts: it frightens people
   near it, and the panic it spreads is its effect. The follow-up "possess" order and its wheel entry are removed
   from Raise. The shared possession code (MindWhisperFx.order with seconds) stays, because Walking Corpse uses
   the same controls.

### Grave Call `gravecall` (Tier 2)
1. **Two-point targeting.** The first click sets the start (a marker stays on the ground). A line then links the start
   to the cursor, showing the path to the target. The second click sets the target. Esc or right-click cancels.
2. **Scarier spirits.** The three small ghosts are replaced by bigger, frightening spirits: taller, darker, with
   trailing shrouds, hollow eyes and a cold aura. Use a new PixelLab sprite (one "wraith" sheet, reused by Gate Below
   and Pale Reign). Keep the effect on people the same or stronger.

### Corpse Guise `guise` (Tier 3, silent)
User's choice: keep the hide role and make it clearer.
1. A grey shroud over each hidden person, plus a clear icon above them (a closed eye or a skull) for the whole 25 s.
2. The blurb says plainly what it does: "Hide up to 4 of the faithful as the walking dead; guards, watchmen and
   inquisitors do not see them for 25 s."
3. Aiming shows which people in the ring will be hidden (same style as Raise's body indicator).

### Walking Corpse `walker` (Tier 3, silent)
1. **Controllable like Mind Whisper.** The risen corpse takes orders through the follow-up wheel (the same order
   wheel and follow-up hooks Mind Whisper uses). At least: walk to a spot, enter a building (bringing plague in when
   the body is sick, as today), and attack a person (a quiet kill that leaves a body). The builder picks the exact
   order list from what Mind Whisper's wheel already supports.
2. **Indicator.** A symbol above the walker (a Death sigil) for its whole life, so the player knows it is theirs.
3. **Time out.** When its time runs out it lies down and becomes a body again, where it stands (as today).

### The Gate Below `gatebelow` (Tier 4)
1. **New look.** Drop the stretched pit sprite. The effect is a ground effect: a dark rift on the ground with many
   arms reaching up across the whole area, grabbing and dragging people down. The arms are many small instances, not
   one stretched image. Proportions must look right at every zoom.
2. **Wraiths that matter.** Today the wraiths follow soldiers and nothing happens. Fix it: a wraith that reaches a
   soldier kills or breaks him (the builder picks: kill on contact, or a short terror then death), and the wraiths are
   bigger and frightening (the new wraith sprite), not cute.

### Pale Reign `pale` (Tier 4)
User's choice: ghost horde.
1. Kills faster, lasts longer and takes more lives than today (the builder sets new numbers and records them).
2. **Ghost horde.** Pale ghosts pour out and run through the district's streets. A living person a ghost passes
   through drops dead (a whole-body death, so the body can rise). Every death adds one more ghost to the horde, so it
   snowballs, up to a cap that holds frame rate.
3. The existing grey drain and scoped hush stay.

### The Pale Serpent `serpent` (Tier 5)
User's choice: soul aura.
1. **Seamless body.** The head joins the body with no visible gap or seam at every angle and turn.
2. **About 2x larger.** Bigger head, body and shadow; a wider kill lane. Keep the final circle the user likes.
3. **Soul aura.** A cold glow and soul wisps trail behind it; the souls of those it kills stream into its body.

### Grave Tide `gravetide` (Tier 5)
User's choice: ground slam.
1. **Longer life** for the Bone Giant (the builder sets the new time).
2. **Assembly.** When it comes out, bones fly together one by one, fast, into the giant.
3. **Landing impact.** Dust, cracks and a shockwave when it lands.
4. **Ground slam.** Every few seconds it slams the ground: a shockwave ring, dust and cracks. Soldiers in the radius
   die; other people are knocked back and panic.

## Left to the builder
- Exact numbers (speeds, radii, times, caps). Record each in the rulings doc as a ruling.
- Walking Corpse's exact order list, within what the follow-up wheel supports.
- The wraith's kill rule.
- Art: PixelLab for the new wraith sheet and any other sprites the user's notes need (the user's standing choice);
  code-drawn effects are fine for rifts, auras, shockwaves and dust.

## Checks
- Every changed power keeps its tests passing; new behaviour gets tests (indicators, zombie speed, no possession,
  two-point Grave Call, controllable walker, wraith kill, horde snowball and cap, serpent seam, giant slam).
- Death bots and references that change are re-recorded; Death Hunts and Tier nights still win.
- The full gate (4 parts) passes and crowd_check prints -535548941.
- A frame-rate bench for Pale Reign's horde and Grave Tide in the 220-person town.
