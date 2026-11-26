# KAK Might Gauge — Rulings and Results

Discord idea "Ability restricted by Might" (2026-11-19). Spec: docs/superpowers/specs/2026-11-19-kak-might-gauge-design.md;
plan: docs/superpowers/plans/2026-11-19-kak-might-gauge.md. Collected from the milestone workspace (.sdd/rulings.md).

## What it does

In an Endless Night a god no longer picks a few abilities before the descent. Every ability learned in the tree comes along, and
each cast is paid from a Might gauge that refills over time.

- Gauge size: the tier's Might (6 / 8 / 10 / 13 / 16), plus one for each "+1 MIGHT" bought with Faith.
- Refill: empty to full in 60 s whatever the size. The Faith row that used to buy a slot is now "FASTER MIGHT", 5 s less per
  purchase.
- An ability's cost is the Might cost it already had. Cooldowns are unchanged. A cast with too little Might is refused ("might").
- The ability bar replaces the six slot cards: Ctrl opens and closes it, Z and X turn its pages (one page per tree type), keys
  1-9 and 0 cast. Closed, it is a thin strip that still shows the armed ability and the gauge.
- Prepare is a read-only briefing with DESCEND. The night's sealed ability stays on the bar, locked.
- The Temple's fall resets every cooldown and refills the gauge, once.
- The board, the campaign and Remembrance carry no gauge and play exactly as before.

## The old draft is hidden, not removed

`GodNight.draft` (a static var, false by default) brings back every Endless behaviour from before the gauge: the editable Prepare
draft inside a Might budget and a slot count, the six slot cards, no gauge and no bar, the "+1 SLOT" Faith row. The command line
flag `--god-draft` turns it on for one run; no menu shows it. The save file is the same in both modes. To bring the draft back for
good, set the default to true (or add a menu option that sets it).

## Rulings

- R1: per task only the focused suites ran; the whole suite, the references and the god gates ran once at Task 9 and again at
  landing.
- R2: the baseline gates ran from a second worktree detached at acb82b96, so the tree under them did not change.
- R3: `AbilityBar.TILE` is 42.0, not the plan's 36.0, and every icon is placed with `UiIcon.native_rect`, so a pixel icon is drawn
  at a native multiple and never stretched. `STRIP_TILE` stays 28.0. Ten tiles are 456 units wide.
- R4: FLOW's steps were updated while the baseline gates ran and FLOW itself was run afterwards, alone.
- R5: a left click inside the open bar's rectangle that is not a tile or a tab is swallowed; it never casts into the town under
  the bar.
- R6 (fix wave after the final review):
  1. A tile whose power takes a follow-up click is framed gold and never greyed as "busy".
  2. FLOW's click guard treats the bar as HUD.
  3. The bar's open state and page carry across `next_act()`.
  4. The interlude button in an Endless night reads "Briefing".
  5. Hub text when nothing can be cast: "Nothing to cast: the tree's Tier 1 is not filled yet". Prepare's Temple row in a
     briefing: "Its fall resets every cooldown and refills your Might, once".
  6. `Hud._signature()` skips the per-slot loop when the bar is present.
  7. `Rules.cast()` pays `PowerBook.might(key, level)` at the level the cooldown uses.
  8. An old-style god file (a bought slot, a six-key loadout, a sealed key, carried counts) loads into a gauge night: refill
     45 s, the sealed key on the bar as "sealed", the old loadout not used.
- R7, replaced by R8: the baseline was to stop after the five Tier 1 missions; it was left running and played the Hunts too.
- R8: the pass bar for the gauge is "no pair worse than its baseline row", not "gate green", because several gates are red on the
  untouched tree (see below).
- R9: no number is tuned. The gauge stays the tier's Might and 60 s.
- R10 (the user, 2026-11-23: "please don't remove the current feature that use might to pick abilities just hide it"): the old
  draft stays behind `GodNight.draft` / `--god-draft`, as described above. Tests cover both modes.

## Results

### Gates: the gauge against the untouched tree (acb82b96)

All ten god gates give the same table and the same checksums with the gauge as without it (105 Tier 1 rows and 105 Hunt rows; the
one differing row is a baseline run that timed out under load).

| Gate | Untouched tree | With the gauge |
|---|---|---|
| Warning, Tax, Harvest, Lamb (Tier 1) | 6/6 PASS | 6/6 PASS |
| Prayers (Tier 1) | FAIL: Passage idle 78 s (limit 60), Decree idle 86 s (limit 45) | the same |
| Hunt: hide_faithful | FAIL 3/6: Ruin idle 55 s, Veil 68 s, Passage 47 s (limit 45) | the same |
| Hunt: silence_witness | FAIL: pooled median 168 s (band 180-240) | the same |
| Hunt: expel_inquisitor | FAIL: pooled median 154 s (band 180-240) | the same |
| Hunt: break_hunt | FAIL 4/5: Dominion idle 115 s, median 177 s | the same |
| Hunt: face_halcyon | FAIL 5/6: Ruin 2/3, idle 65 s | the same |

The red gates are red before the gauge and are not its doing. They are open work on the main branch.

### Why nothing moved

The scripted bots spend 6 to 14 Might in a mission and seldom empty the gauge. Probe: Prayers as Dominion spends 11 Might in
205 s and its gauge never falls under 3.26 of 6; Tax as Ruin spends 6, lowest 4.07. So the gates cannot say how the gauge feels to
a player who casts as fast as the cooldowns allow. That needs play by hand.

### References

508 recorded games. Two `--god` rows moved because the gauge empties there (Dominion, Tier 1, seed 2, 24 Might spent, the gauge
at 0): Prayers 263.1 s to 252.6 s and First Taste 187.3 s to 187.8 s, both still won. They are re-recorded. No row without `--god`
moved.

### Landing checks (2026-11-23, merged with Develop-Main e78af8e2: Town Suspicion, loss warning, music by situation)

- References: 508 of 508 exact, the two re-recorded rows included (22 rows timed out under machine load in the first pass and
  matched when run again).
- Suite: 23583 checks, 1 red: Decree Cage's level 5 frame-time check (all-frames p95 2.4-2.5 ms against 2 ms). It fails the same
  way on untouched Develop-Main e78af8e2 on the same loaded machine (p95 2.05-2.58 ms), so it is machine load, not the gauge.
- FLOW: 211 checks, 0 failures.
- Trial merge with origin/feat/Develop-Main: clean.

## Not done

- No number was tuned; the balance of 60 s and the tier budget is untested by a human player.
- FLOW has no steps for the hidden draft mode; its unit tests cover it (tests/test_god_draft_switch.gd).
- No bench was run: the machine was never quiet, and a board mission carries no gauge.
