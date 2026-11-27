# Veil abilities review: previews and stronger effects (design)

Source: the user's Discord #ideas post "Veil Abilities Adjustment" (2026-11-21), with the word "read from discord and implement".
Branch `god/veil-review`, cut from `god/veil-powers` b58ba4f2. The design choices below are Claude's reading of the post; each
is marked so the user can overrule it after looking.

## 1. What the user asked (verbatim)

- Adding target preview on Slumber, Cloak of Night, Dreamless and Shadow Play.
- Can we add more visual effect on casting Slumber, Cloak of Night, Unseen Hour, Dreamless, Shadow Play, Dread of the Dark.
- Blight: if person got blight I want to have some indicator to show above their head.
- Unseen Hour: can we add more vfx like a transparent dark blanket or something cover area above to make it like it was covered
  the area.
- Dread of the Dark: I barely see any vfx or animation on this ability. Can you make it like a darkness spreading and forming
  into some kind of a wall.
- The Swallowing Dark: can you add more vfx to make it have more dimension or more powerful than this because currently it's like
  a normal dark circle on a flat ground. Do something like a darkness swallow the whole area from the ground.
- Evernight: make it more powerful, more vfx to show it's really have a darkness cover the city, add more atmosphere or sparkle,
  some particle effects around the city.

## 2. The rule of this round: looks only

No power's rules change: who is affected, when, for how long, every size, every cooldown, every sound cue's moment. A reference
row must not move (all 508 hold on b58ba4f2). Everything added is drawing: nodes, particles, lights, colours, a badge. The Veil
stays silent: no new sound that reads as an alarm, no fright, no danger. Where a look needs a number the rules already hold (a
radius, a time), it reads it from the effect or `VeilRules`, never a second copy.

The Veil's palette stays: violet-black dusk, cold silver, pale eyes. No green (rot is Blight's own and Death's), no fire, no gore.

Cost: each power's cast keeps the frame cost bar of the build (mission bench, cast / base `avg_ms` at most 1.55; rulings VA9,
VC10). Town-wide looks (Evernight) use a few large pieces, never one node per person or per building.

Every new piece is torn down with its cast (`_finish()` and `_exit_tree()`), survives a bare test context (a plain `Node2D`
for `ctx.overhead`, null `ctx.ground` / `ctx.impact` / `ctx.crowd`), and shows at both sizes.

## 3. Target preview (Slumber, Cloak of Night, Dreamless, Shadow Play)

While the power is aimed, the people a click here would take are ringed, as Silent Doom's are today, and the ring follows the
light or dark size under the cursor. Each uses the power's own pick function with the same radius and count the cast will use, so
the preview and the cast can never disagree:
- Slumber: `SlumberFx.sleepers_at`. Cloak of Night: `CloakOfNightFx.marked_at` (the 3, or 8 in the dark). Dreamless:
  `DreamlessFx.victims_at` (the 1, or 4 in the dark); one already asleep or a shadow, whom the cast takes at once, is ringed in the
  kill colour. Shadow Play: `ShadowPlayFx.shadows_at`; in the dark a soldier, whose shadow is taken at the end, is ringed in the
  kill colour.
- Found on the way and fixed with it: Blight's preview in the dark shows one person where three fall ill ("blight" has no ring
  entry, so the dark test is never true).

## 4. Blight: a mark above the head

A person Blight makes ill carries a small sickness glyph above the head (the game's own badge, as the Death Mark's skull) in
Blight's rot colour, from the moment he is struck until he is indoors (or, for a mission's quarry made ill, while he is ill).
A faint drift of rot motes follows him on the way home. Nothing else about him changes.

## 5. Stronger casts

Each cast should read in three beats: the gather at the click, the landing over the reach, and a lasting sign on those it holds.
- **Slumber**: a low wave of violet mist rolls out from the click to the edge of the reach; heavy silver dust sinks onto each
  sleeper; a closed-eye glyph blinks once over the middle.
- **Cloak of Night**: at the click a dark cloth unfurls, and a strand flies from it to each person it will hide, then wraps him;
  the shimmer he keeps is a little stronger at its edge so the player can find his own cloaked people.
- **Dreamless**: a slow dark breath sinks at the click; over each one who sits, a thin silver thread rises and thins out for as
  long as he rests, and snaps when he is found.
- **Shadow Play**: a dark ripple crosses the ground and each shadow peels up from its owner's feet (a stretched silhouette that
  stands up), instead of only turning black.
- **Unseen Hour**: a wide, thin, dark blanket hangs over the whole veiled area for as long as the veil lasts: it is thrown from
  the click, settles with a slow ripple, hangs with a soft sagging edge and a faint weave, and lifts at the end. People and
  buildings under it stay readable (it is a veil, not a lid).
- **Dread of the Dark**: the dark spreads over the dreaded ground from the click outwards, and at its border rises into a wall: a
  ring of tall, shifting pillars of darkness with the pale eyes in it, standing for the whole dread and sinking when it lifts. The
  frozen stay marked under the feet.

## 6. The Swallowing Dark

The circle becomes a hole, not a disc: an inner drop (darker rings sinking toward the middle, a lit silver lip on the far side,
a slow inward swirl), tendrils of dark that reach up over the rim and curl inward as it grows, dust and loose ground drawn in
across the edge. At the fold the ground heaves: the dark rises as a low dome over the whole circle, what stands inside sinks
into it, and it closes downward, leaving the bare earth. Still unseen by the town (no fright, no alarm).

## 7. Evernight

The night must be seen to fall on the whole city: the dark front crosses the map as a towering wall of night, not a tint; the
sky wash is deeper (the town is still playable: people and torches read); slow dark mist drifts over the roofs; stars glitter
and a few fall; motes of dark rise from the ground across the town; the torches' light gets a warm flickering halo with sparks;
each take is marked by a brief dark wisp rising where the lone one stood; the dawn rolls back the same way the night came.

## 8. Tools

`tools/dev/behaviour_check.gd --scenario=clip` learns to: run by night (`--look=night` no longer read as a camera offset), cast
inside dusk (`--setup=dark`), leave the committed skill-tree sheet alone (`--no-sheet`), and make its frame folder. The skill
tree's ten Veil clips are re-recorded at the end, from the new looks.

## 9. Not in this round

Sound, rules, levels 2-5, painted icons, the Sandbox's capture table, Silent Doom's look.
