# Veil review, second pass (2026-11-22)

The user played `god/veil-review` (132347af) on the other PC and wrote three points in chat. This pass builds them on the same
branch. Design choices below that the user did not state are mine and marked (mine).

## 1. The user's words

- "Blight - cooldown is too long for Tier 1 ability"
- "The swollowing Dark - need more powerful sound effect"
- "Evernight - I want to have some preview effect before remove people make it like darkness eating them and leave shadow on the
  ground. And I want it to remove them more frequently not just one people. Maybe 2 seconds 5 -10 people"

## 2. What changes, and what does not

Unlike the first pass, this one changes rules, but only these two: Blight's cooldown, and how many Evernight takes at a time
(with the claim that comes before each take). Every other rule of every power stays. Reference rows that cast Blight would move
at the new cooldown; the scripted nights keep Blight's old 36 s pace instead, so none moves (ruling VR2B2 in
`docs/KAK_God_Veil_Rulings.md`, which replaced the first plan of recording them again); rows that cast no Veil power must not move. No reference row casts
Evernight or The Swallowing Dark.

## 3. Blight

Cooldown 36 s -> 20 s (mine: the other Tier 1 powers run 10 to 20 s: Silent Doom 10, Smite 10, Ember 15, Death Mark 20, Leaving
Is Prohibited 20, Skylift 20). The v0.07 floor of 25 s in `tests/test_power_book.gd` no longer binds Blight: the Veil build
remade it into another power (no alarm, footholds of dusk, the sick sent home).

## 4. The Swallowing Dark: a sound that matches the look

Today: a breathy 3 s cast cue and a 2.4 s take cue, about 20 s of silence between them. New (mine, the shapes):

- The cast: a deep opening (a sub drop, stone groaning, a long inhale), not a breath.
- While the circle grows: a held low rumble that swells as it grows and stops with the cast.
- The heave before the fold: a rising inward rush that ends on the fold.
- The fold: the big hit. A sub boom, an implosion that sucks inward, earth collapsing, a long dark tail. Music and ambience
  duck under it as they do under the other doomsdays.
- The town still does not hear it (no alarm, no fright): the sound is the player's.
- The blurb's "gone without a sound" becomes untrue and is reworded.
- Sources: CC0 or public domain from the sound library only, built as foley recipes like the other Veil cues. Never Sonniss.

## 5. Evernight: the dark claims many, eats them, and leaves their shadows

- **How many.** A take every 2 s (1.5 in a NIGHT mission) as today, but each take collects a group: 5 at the first take, rising
  evenly to 10 at the last (mine: the user's "5 - 10" read as a night that grows hungrier; no luck in it).
- **The claim (the preview).** When the night has fallen, and again at every take but the last, the dark claims the next group:
  the loneliest people out of doors, outside every torch's light, not spared, not already claimed (the same pick as today, the
  N loneliest instead of the one). A claimed person shows it for the whole wait: the dark climbs him from the ground, a pool of
  shadow spreads under his feet, he darkens as it eats him.
- **The take.** At the next take every claimed person still out of doors, outside torchlight and not spared is taken (silent,
  as today). One who reached a torch's light, went indoors, was spared or died meanwhile is let go: his dark fades and leaves
  nothing (mine: the torches' rule stays whole; a claimed person is not held in place).
- **The shadow.** Where each was taken, his shadow stays on the ground: a dark body-sized stain, for the rest of the night,
  fading with the dawn.
- The wisp at each take stays. The torches, the call to the torches, the dawn's rule (no dawn for some), the night's length
  and its other parts do not change.
- Cost: the stains are one drawn piece for the whole town; the claims are at most 10 small followers. The bench bar holds
  (cast / base at most 1.55, alone and with Unseen Hour or Dread inside it).

## 6. Tools and documents

Evernight's and The Swallowing Dark's skill-tree clips are recorded again if their looks changed. The power book's lines, the
summary and the rulings say what is true now.

## 7. Not in this pass

Holding the claimed in place; a sound for each take of Evernight; levels 2-5; anything from the first pass's "For your eye" list
the user did not raise.
