# People animations, phase 1: madness — design

**Date:** 2026-10-23
**Branch:** `feat/people-anim`, worktree `C:\BURIN_NITRO\Godot\GIT\vfxProve-people-anim`, cut from `feat/Develop-Main` 5233168.

## Why

Citizens have only six animations: idle, walk, run, crouch, the death fall, and the turn. Everything they do under a power looks like walking or running. The user wants them to feel alive, starting with **Madness Bloom**.

The user describes the moment this way. Maddened citizens "hold their head with two hands and screaming, then running to attack others like a zombie for a while". The people they catch are "knocked over then stand back up", or they run away screaming.

This is phase 1 of the Tier 1 list. Pray, point and shout, look up and cower are phase 2, after the PixelLab plan refills on 2 November.

## Decisions (user, 2026-10-23)

- **Art source:** PixelLab, through the existing pipeline. The people designs are PixelLab characters; their ids are in `assets/pixellab/people/characters.json`. The tools are `tools/dev/pixellab_api.py char-anim` and `tools/dev/make_people_atlas.py --import`.
- **Budget:**
  - The plan has 81 generations left, plus a daily bonus of up to 20, until the 2 November reset.
  - Generate **2 directions** per animation. The other 2 are mirrored copies.
  - **Reuse existing frames** wherever possible.
  - **Phase it:** madness first now, the rest after the refill.
- **Victims** get knocked over, lie down briefly, then stand back up and run away as they do now.

## What the player sees

| Moment | Who | Animation | How it is made |
|---|---|---|---|
| Madness breaks (stage Broken, outcome Frenzy) | the maddened citizen | **Scream**: both hands clutch the head, mouth open, about 1 s, played once; plus a scream sound | PixelLab custom (v3): "clutching head with both hands, screaming, staggering" |
| Frenzy, the existing 15 s fight | the maddened citizen | **Lurch**: a zombie walk, arms reaching forward, used instead of walk/run while chasing | PixelLab template `scary-walk` |
| A blow lands (`Person` fight swing, `_swing_in`) | any citizen fighting: madness, Manufactured Hatred, Turncoat, Mob Verdict, Discord, Divine Schism | **Swing**: one punch or club swing, played once per blow | PixelLab template `cross-punch` |
| A blow lands | a soldier fighting | **Soldier attack**: a spear or weapon thrust | PixelLab custom (v3): "thrusting a spear forward" |
| Hit by a blow | the victim | **Knocked down**: falls back and lies still | Reuse the existing death fall, frames held on the ground |
| After lying down | the victim | **Get up**: back onto their feet, then runs off as today | Reuse the death fall played in reverse |

Erratic and stunned madness outcomes keep their current look; they are phase 2 or Tier 2.

## Behaviour changes (my call)

These change gameplay timing a little, so the deterministic checksums change.

1. **The scream holds the maddened citizen in place for about 1 s** before the frenzy hunt starts. The 15 s frenzy is unchanged in length; it starts after the scream.
2. **A fight blow knocks a citizen victim down.** They lie about 1.0 s, get up in about 0.6 s, then react as now: run from the attacker, or fight back if a soldier.
   - The existing short knock-back slide still happens first.
   - A blow that kills plays the death fall as now, with no get-up.
   - A soldier victim is not knocked down; soldiers stay on their feet.
3. Nothing else changes: who goes mad, damage, durations, and who flees.

Every changed checksum is re-recorded with the reason, as each milestone does. The digest (structures) must stay the same. FLOW must pass.

## Engine

- **`PeopleArt.ANIMS`** grows from 5 to 9: `idle walk run stumble death scream lurch swing getup`.
  - The soldier attack is a soldier design's `swing`, so a design has one swing slot.
  - `knocked` is not a new row: it is `death` frames held on the last frame. `getup` is built from `death` reversed at atlas time.
  - The pose code packs the animation index in 3 bits today (`code >> 2 & 7`), so it widens to 4 bits.
- **FPS and holds:** scream and swing play once and hold their last frame; lurch and getup loop or run once as fits.
- **`Person._sprite_pose_code()`** picks the new animations from state:
  - scream while its hold timer runs;
  - lurch while the mind is FIGHT, the fight's kind is madness, and the person is striding;
  - swing for a short window after a blow;
  - knocked or getup while the down timer runs.
- **Missing art:** a design without one of the new rows falls back as today (the atlas tool gives a missing state the idle). Any design or state not generated (for example a soldier's scream) shows the old look, never a hole.

## Atlas tool

- **`make_people_atlas.py`:**
  - `STATES` gains the new rows.
  - On `--import`, it **mirrors** each generated direction into its missing pair, left-right:
    - south-east to south-west;
    - north-east to north-west.

    The builder chooses which pair to generate and mirrors the other.
  - It writes `getup` as `death` reversed.
- **Accepted cost of mirroring:** a mirrored frame's light comes from the other side. At 24 px this barely shows.

## Generation budget (phase 1)

| What | Designs | Generations |
|---|---|---|
| scream | 13 citizen designs × 2 directions | 26 |
| lurch | 13 × 2 | 26 |
| swing | 13 × 2 | 26 |
| soldier attack | 4 soldier designs (guard, marshal, escort, rescue) × 2 | 8 |
| **Total** | | **86** |

- That fits 81 plus the daily bonus, with a little room for re-rolls.
- **Pilot first:** one design (resident_a), all four animations. The user approves the look before the other 16 are spent.
- **If the budget runs out mid-way,** the finished designs ship and the rest keep the old look until 2 November.
- `knocked` and `getup` cost nothing.

## Out of scope (phase 2, after 2 November)

- **Pray / kneel:** Divine Congregation, rites, chapel visits.
- **Point and shout:** alarms, The Bell Lies.
- **Look up:** Falling Star, Solaris.
- **Cower:** the existing crouch for now.
- Generating the mirrored directions properly, if the light flip ever shows.

## Pass when

1. The user approves the pilot on resident_a, then the whole crowd, in captures and the sandbox.
2. In a Madness Bloom in Aldermere:
   - a breaking citizen screams;
   - a frenzied one lurches and swings;
   - victims fall, get up and flee.
3. Other fight powers show the swing.
4. All tests pass, with 0 failures and 0 SCRIPT ERROR.
5. The digest and FLOW are unchanged.
6. The changed behaviour checksums are re-recorded with reasons.
7. The frame rate stays within about 3 fps of Develop-Main.

## Rules settled after review (my calls)

1. **Who gets knocked down.**
   - Only a citizen who is **not fighting** is knocked down, which is the user's picture of the bystander. Two fighters (mad against mad, a Discord brawl) trade blows standing; they only flash and slide, as now.
   - A downed person can't be targeted. An attacker picks someone else, so nobody is beaten to death on the ground.
2. **Down is a timer layered over the person's state, like the stumble.**
   - It starts when the knock-back slide ends.
   - While down, the person doesn't move or path, and its fright, panic and stumble timers pause, as in a stumble. Its other timers (fearless, badge, repath, swing) keep counting.
   - It ends with the get-up, then the person's normal reaction to the blow: flee from the attacker.
3. **The scream** is a hold timer in the same way. Freeze, death and a knock-back override it, and a screaming person can be killed. The frenzy's 15 s starts when the scream ends.
4. **Custom animations** (scream, soldier thrust) use PixelLab's custom mode ("v3") on the existing character id, one direction per job. At this sprite size that costs 1 generation per direction, the same as a template.
   - The MCP tool `animate_character` supports it.
   - `pixellab_api.py char-anim` may gain a `--mode v3 --action` option, or the frames can be fetched after an MCP call. That choice is the builder's.
5. **Budget guard.** The pilot measures the real cost. If it bills more than 1.5× the estimate, stop and report before spending more.
6. **The pilot is a hard stop.** Build and show resident_a's four animations, then wait for the user's approval before generating the other designs. The plan therefore has two stages.
7. **The soldier attack is the `swing` row of the soldier designs** (guard, marshal, escort, rescue). The stand-in designs (watchman, mayor, noble, knight) use their parent design's rows through `PeopleArt.STAND_INS`.
8. **Checksums.**
   - Only scenarios with fights or madness may change: calm stays exact, and so do digest, crowd_check and FLOW.
   - Re-record each changed scenario twice, with its reason.
   - Any other change is a regression to fix.

## Left to the builder

- Exact frame counts, FPS and hold times within the spirit above.
- Which direction pair to generate.
- The scream sound: an existing sound or the new sound library (`C:\BURIN_NITRO\SoundLibrary`, licence rules in memory).
- Tests for each trigger.
