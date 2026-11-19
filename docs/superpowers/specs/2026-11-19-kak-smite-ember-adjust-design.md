# KAK Smite and Ember adjustments (2026-11-19)

Source: the user's Discord #ideas post "Abilities Adjustment" (2026-11-19) and their two answers the same day.
Branch `god/ruin-adjust`, cut from `origin/feat/Develop-Main` acb82b96. It merges into Develop-Main only on the user's
word.

## Why

- Smite's level 5 twist should let the player choose a bigger strike, with a cap so it is not overpowered.
- Ember should be able to set a person alight, not only a building.

## Approaches

There was one sensible way for each change, built on what exists.

- **Smite:** level 5 becomes a press-and-drag aim, as other drag powers (Earthshatter, Bramble) already aim. A short
  click still casts the normal bolt.
- **Ember on a person:** a new reusable crowd status, Burning, modelled on the Withering status (R36). It is not
  hard-coded into Person (the user's rule).

Rejected options:
- A "charge by holding" aim for Smite: no power uses one, and the aim code would need a new mode.
- Ember dealing a plain kill: the user chose "burns, runs, spreads".

## Smite `smite`, level 5 twist "Gathered Storm" (replaces "Forked Bolt"; the user's choice)

- Below level 5: unchanged.
- At level 5 the aim is a drag:
  - A press-and-release with no drag, or a twitch under `Targeting`'s dead zone, casts the normal level 5 bolt at the
    press.
  - Dragging grows the bolt at the press point. The scale is `s = 1 + drag_length / GROW_PER`, capped at
    `GROW_MAX = 2.5`. My call: `GROW_PER` about 1.5 units, so the full 2.5x comes at a drag of about 2.25 units.
  - Kill radius `KILL_R * s`. Every building within `HIT_R * s` takes `DAMAGE`. The bolt, flash and light are drawn
    `s` times larger.
  - The preview ring grows with the drag and stops at the cap.
- The fork (`FORK_R`, `_fork_target`, `forked_at`) is removed. The level row's `twist_text` becomes "Gathered Storm:
  drag to widen the bolt (2.5x at most)".
- Cooldown, DP and the level 1-4 rows are unchanged.

## Ember `ember`: people too (the user's choice: burns, runs, spreads)

- **Target:**
  - If a living person, not inside, stands within `PERSON_R` (my call: 0.6) of the click, the spark falls on the
    nearest such person.
  - Otherwise it falls on a building, as today.
  - Soldiers and citizens alike. Guised people are spared, as Death's undead spare them.
- **Burning**, a reusable status on the crowd (`Crowd.burn(p, seconds)`, `Person.burning()`), modelled on
  `Withering`:
  - **Length:** `BURN_FOR` (my call: 4 s).
  - **Flight:** he panics and runs, with no shelter roll. He screams; reuse an existing scream or fire voice.
  - **Spread:** every `SPREAD_EVERY` (0.5 s), a burnable building within `SPREAD_R` (0.8) of him is lit at Ember's start
    level through `FireManager.ignite`.
  - **Fright:** people within `SEE_R` (my call: 4) who can see him are frightened.
  - **Lapses:** if he goes indoors, dies of something else, or the status is cleared, the burning ends with no fire
    death.
  - **Death:** at the end he dies as `&"fire"`, the existing fire kill. Fire deaths leave no raisable body (the
    existing rule).
  - **Draw only:** flames on him.
- **Quiet:** Ember stays quiet when cast. The burning man is seen, so the fright and the alarm come from the sight of
  him, not from the cast.
- **Level 5 "Leaping Spark":** from a person, the second spark leaps to the nearest burnable thing within `LEAP_R` of
  him, as today.
- **Text:** the blurb becomes "One spark sets a building or a person alight." The shape text names both.

## Checks

- **Tests:**
  - Smite: a short click equals the old level 5 bolt without the fork; a drag of N grows to the right radius; the cap
    holds; buildings in the grown radius are hit.
  - Ember: a person under the click burns; a building is chosen when no person is near; the burning man runs, frightens
    others, lights a house he passes, and dies as fire at `BURN_FOR`; indoors he lapses; level 5 leaps from him; a
    guised person is not picked.
- **Bots and references:** rows that cast Smite at level 5 or Ember near people are re-gated and re-recorded, with
  reasons.
- **The full gate**, and crowd_check must print `-535548941`.
