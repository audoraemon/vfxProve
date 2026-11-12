# KAK -- Dominion ability levels

Status: **approved by the user** (2026-11-09: "Ok let's do it"). Numbers are first guesses, to tune in play.

## Intent (the user's words)

"I want Dominion god to feel like puppet master that pulling string and dominate people to be direction of the god's will."

So every level lets the god hold **more people, for longer, and recast sooner**, and every level-5 twist is a **new way to
steer** the people already in its hand. No twist is a random roll; two twists remove luck the power has today.

## Frame (same as Ruin's levels, docs/superpowers/specs/2026-11-03-kak-ruin-ability-levels-design.md)

- Five levels per ability (`PowerBook.MAX_LEVEL`). Each level raises 2-3 of the ability's numbers.
- **Level 1 = today's numbers exactly.** Hunts, routes and references play at level 1, so none of them may move.
- Might cost: the base `dp` at levels 1-2, +1 at levels 3-4, +2 at level 5 (`PowerBook.MIGHT_STEPS`, already built).
- Data: each power's `PowerBook` row gets a `levels` table (index 0 = level 1). The table's cooldown stat is
  `"cooldown"`. The effect reads each number through `PowerBook.stat(extra, "<key>", "<STAT>", CONST)`; a twist is
  gated by `PowerBook.twist_at(extra, key)`. Level 5 carries `"twist": true` and `"twist_text"`.
- Stat names below are the effect's own constants. A stat used in a derived number is derived at cast time.

**cd** is the cooldown in seconds.

---

## Tier 1

### Mind Whisper (`whisper`, 1 Might, `src/fx/dominion/mind_whisper.gd`)
Grows: walk reach `REACH`, attack order `ATTACK_SECS`, cooldown.

| Lv | REACH | ATTACK_SECS | cd | Might |
|---|---|---|---|---|
| 1 | 10 | 10 | 8 | 1 |
| 2 | 11 | 11 | 7.5 | 1 |
| 3 | 12 | 12 | 7 | 2 |
| 4 | 13 | 13 | 6.5 | 2 |
| 5 | 14 | 14 | 6 | 3 |

**Twist -- Held String:** for 20 s after a whisper, that person can be whispered again at once; the 20 s
"not the same one again" wait (`Person.SHAKE_OFF`) does not apply to them. The cooldown and Might still apply.

### Discord (`discord`, 2 Might, quiet, `src/fx/quiet/discord.gd`)
Grows: circle `DISCORD_R`, forgetting `DISCORD_TIME`, cooldown.

| Lv | DISCORD_R | DISCORD_TIME | cd | Might |
|---|---|---|---|---|
| 1 | 1.2 | 15 | 30 | 2 |
| 2 | 1.3 | 16 | 28 | 2 |
| 3 | 1.4 | 17 | 26 | 3 |
| 4 | 1.5 | 18 | 24 | 3 |
| 5 | 1.6 | 20 | 22 | 4 |

**Twist -- Tangled Threads:** for the first 5 s, anyone living who comes within 1.0 of a person this Discord confused
forgets their task too (same forgetting time). One hop only: people caught this way do not pass it on.

## Tier 2

### Madness Bloom (`madness`, 2 Might, quiet, `src/fx/curse/madness_bloom.gd`; spread in `src/game/crowd/madness_manager.gd`)
Grows: cast circle `RADIUS`, starting madness `SEED` (they break sooner), cooldown.

| Lv | RADIUS | SEED | cd | Might |
|---|---|---|---|---|
| 1 | 1.5 | 0.02 | 40 | 2 |
| 2 | 1.65 | 0.04 | 38 | 2 |
| 3 | 1.8 | 0.06 | 36 | 3 |
| 4 | 1.95 | 0.08 | 34 | 3 |
| 5 | 2.1 | 0.10 | 32 | 4 |

**Twist -- Directed Frenzy:** everyone this Bloom seeds who reaches Broken goes into frenzy (never the stun or erratic
outcome of `BROKEN_WEIGHTS`), and their frenzy goes for the nearest soldier first, else as today. Applies to the people
the cast seeded, not to people they spread it to.

### Will-o'-Wisp (`wisp`, 2 Might, quiet, `src/fx/control/will_o_wisp.gd`)
Grows: lure cap `LURE_MAX`, lure time `WISP_TIME`, ENTHRALL hold `ENTHRALL_TIME`, cooldown. ENTHRALL keeps its own
75 s cooldown at every level (its mode cooldown wins, as today).

| Lv | LURE_MAX | WISP_TIME | ENTHRALL_TIME | cd | Might |
|---|---|---|---|---|---|
| 1 | 25 | 12 | 30 | 30 | 2 |
| 2 | 27 | 13 | 32 | 28 | 2 |
| 3 | 30 | 14 | 34 | 26 | 3 |
| 4 | 32 | 15 | 37 | 25 | 3 |
| 5 | 35 | 16 | 40 | 24 | 4 |

**Twist -- Procession:** while the light burns (either mode), the player can send it to a new spot; it drifts there at
walking pace and everyone it holds walks with it, keeping their ring. Sending it costs no Might and no cooldown.

## Tier 3

### Clear Mind (`clearmind`, 3 Might, quiet, `src/fx/dominion/clear_mind.gd`)
Grows: circle `RADIUS`, trance `TRANCE_TIME`, cooldown.

| Lv | RADIUS | TRANCE_TIME | cd | Might |
|---|---|---|---|---|
| 1 | 5.0 | 30 | 60 | 3 |
| 2 | 5.4 | 32 | 57 | 3 |
| 3 | 5.8 | 34 | 54 | 4 |
| 4 | 6.2 | 37 | 51 | 4 |
| 5 | 6.5 | 40 | 48 | 5 |

**Twist -- Sleepwalk:** while the trance holds, the player can send everyone in it to a spot: they walk there calmly,
still sensing nothing, and stay in the trance until it ends. Costs no Might and no cooldown. (The user's pick,
2026-11-09, replacing "Forgetting", which the trance already made almost invisible.)

### Saint or Sinner (`saint`, 3 Might, quiet, `src/fx/dominion/saint_or_sinner.gd`)
Grows: circle `RADIUS`, span `SPAN`, cooldown.

| Lv | RADIUS | SPAN | cd | Might |
|---|---|---|---|---|
| 1 | 6.0 | 30 | 60 | 3 |
| 2 | 6.4 | 32 | 57 | 3 |
| 3 | 6.8 | 34 | 54 | 4 |
| 4 | 7.2 | 37 | 51 | 4 |
| 5 | 7.5 | 40 | 48 | 5 |

**Twist -- Passed Mark:** SINNER: when the chosen falls, the mark jumps once to the nearest other living person within
3, and the mob goes on after them for what is left of the span. SAINT: whoever strikes the Saint, every guard goes
for them (not only `GUARDS_PER_THREAT`).

## Tier 4

### Sacred Sanctuary (`sanctuary`, 4 Might, quiet, `src/fx/dominion/sacred_sanctuary.gd`)
Grows: guards `MAX_GUARDS`, span `SPAN`, guard pickup reach `PICK_R`, cooldown.

| Lv | MAX_GUARDS | SPAN | PICK_R | cd | Might |
|---|---|---|---|---|---|
| 1 | 40 | 40 | 5.0 | 90 | 4 |
| 2 | 44 | 44 | 5.25 | 86 | 4 |
| 3 | 48 | 48 | 5.5 | 82 | 5 |
| 4 | 52 | 52 | 5.75 | 78 | 5 |
| 5 | 55 | 55 | 6.0 | 74 | 6 |

**Twist -- Pressed into Service:** an intruder the wall drives out does not run: they take a post on the wall and guard
it for the rest of the span (soldiers too; up to `MAX_GUARDS` in all).

### Anathema (`anathema`, 4 Might, quiet, `src/fx/dominion/anathema.gd`)
Grows: district `RADIUS`, span `SPAN`, cooldown.

| Lv | RADIUS | SPAN | cd | Might |
|---|---|---|---|---|
| 1 | 6.0 | 40 | 90 | 4 |
| 2 | 6.4 | 44 | 86 | 4 |
| 3 | 6.8 | 48 | 82 | 5 |
| 4 | 7.2 | 52 | 78 | 5 |
| 5 | 7.5 | 55 | 74 | 6 |

**Twist -- Spreading Mark:** 20 s in, the mark (CURSED or HALLOWED) spreads once to every building of a marked role
within 3 of a marked building, for the rest of the span. Never the Citadel.

## Tier 5 (Voice: long cooldown; Schism: once a night)

### Voice of God (`voice`, 5 Might, `src/fx/dominion/voice_of_god.gd`)
Grows: every command's length `COMMAND_X` (a multiplier on `COMMANDS`), gather cap `GATHER_CAPACITY`, cooldown.

| Lv | COMMAND_X | GATHER_CAPACITY | cd | Might |
|---|---|---|---|---|
| 1 | 1.0 | 150 | 180 | 5 |
| 2 | 1.1 | 160 | 170 | 5 |
| 3 | 1.2 | 175 | 160 | 6 |
| 4 | 1.3 | 185 | 150 | 6 |
| 5 | 1.4 | 200 | 140 | 7 |

**Twist -- Second Word:** while a command holds, the player can speak a second command (any of the seven) for no Might
and no cooldown; the same people take it up when the first one ends. Once per cast.

### Divine Schism (`schism`, 6 Might, `src/fx/dominion/divine_schism.gd`)
Grows: region `REGION`, fighters `MAX_FIGHTERS`, length `DURATION`. Still once a night (cooldown 999 at every level).

| Lv | REGION | MAX_FIGHTERS | DURATION | Might |
|---|---|---|---|---|
| 1 | 14 | 140 | 25 | 6 |
| 2 | 15 | 150 | 27 | 6 |
| 3 | 16 | 160 | 29 | 7 |
| 4 | 17 | 170 | 32 | 7 |
| 5 | 18 | 180 | 35 | 8 |

**Twist -- Turn the Tide:** while the sides fight, the player can click a fighter to move them to the other side, up to
10 times a cast, free. TUMULT has no sides, so the twist does nothing there.

---

## Notes for the builder

- Level 1 must change nothing: suite, all references and FLOW must be what they were (bread_play_3 already mismatches
  on the base, -133947279; it is not this work).
- Every listed stat is read through `PowerBook.stat()` instead of the constant; stats that live outside the effect
  (Madness's manager, `Person.SHAKE_OFF`, Voice's `COMMANDS` table) need the level carried to where they are read.
- Four twists act **while the power is still running** (Procession, Sleepwalk, Second Word, Turn the Tide): the
  player gives a follow-up order to a live cast. Build one shared way for a live cast to take a follow-up, rather than
  four. What the input is (clicking again with the power, a key) is the builder's call; keep it the same for all four
  and say it on the power's tooltip.
- A twist needs its own code and test. The stat rows are data.
- Might cap check: a Tier 5 pair at level 5 is Voice 7 + Schism 8 = 15, under the cap of 16.
- The skill tree's level text (`PowerBook.twist()`, `NO_LEVELS`) must show the Dominion twists once the tables exist.
</content>
</invoke>
