# KAK: abilities restricted by Might (the Might gauge) — design

Date: 2026-11-19. Branch: `feat/might-gauge` (worktree `.claude/worktrees/might-gauge`, from Develop-Main `acb82b96`).
Source: Discord #ideas post "Ability restricted by Might" (id 1569502333677862932, tags OPEN, Adjust/Change).

Each choice below is marked **[user]** (the user decided it in the design conversation) or **[call]** (the designer's call; the
user has not been asked and may overrule it).

## 1. Intent and the why

Today a god picks up to six abilities on the Prepare screen before every night, inside a Might budget. The user's words: picking
abilities before descending "doesn't look like a god". A god should arrive with everything it has learned.

So, in Endless Night, the draft goes away. Every ability the god has learned is available in the night. What limits the god is a
**Might gauge**: it drops when an ability is cast and refills slowly. Each ability keeps its own Might price and its own cooldown.
Because a god can now hold many more than six abilities, the in-night ability bar is redesigned.

## 2. Goals, non-goals, anti-goals

Goals
- A god's night offers every learned ability, with no pick step.
- A Might gauge limits casting: spend on cast, slow refill.
- An ability bar that holds up to ten abilities per god type and stays out of the way when not needed.
- The Missions board (the dev/test board) and the campaign play exactly as today.
- The god bots still win their missions and Hunts while paying Might.

Non-goals
- Switching the Missions board or the campaign to the gauge. The design leaves that door open (the pool is a switch), nothing more.
- New abilities, new art, new sounds beyond one refusal line. No PixelLab work.
- Rebalancing missions. If bots fail, the gauge numbers are tuned, not the missions.
- Rebinding existing keys.

Anti-goals (a failure even if it works)
- The gauge makes a night a waiting game. The project's mission lessons say "no waiting"; a god that stands idle for long stretches
  because the gauge is empty is a failed tuning.
- A bar that covers the town. The bar must be smaller on screen than today's six cards when hidden, and one icon tall when shown.
- Reference runs without a god changing. The 304 rows of `tools/dev/refs/*.tsv` that carry no `--god` (the 286 board rows and
  the 18 `--case=none` Hunt and rite rows) must stay byte-identical.

## 3. How it works today (what the builder starts from)

- `Draft` / `PrepareScreen` (`src/game/draft.gd`, `src/game/ui/prepare_screen.gd`): the player picks up to `def.slots` powers whose
  summed `PowerBook.might(key, level)` fits `def.dp_capacity`. Refusals "dp", "slots", "pool".
- `GodNight.def_for(slot, id)` (`src/game/god/god_night.gd`) builds a god's night: `def.pool = slot.draftable()` (learned, in the
  tree, not sealed), `def.slots = slot.slots()`, `def.dp_capacity = slot.max_might()`. `_rite_def` does the same for the Awaken rite.
- `GodSlot` (`src/game/god/god_slot.gd`): `max_might()` = `TierBook.dp(tier)` (6, 8, 10, 13, 16) + `bought.might`; `slots()` =
  `BASE_SLOTS` (3) + `bought.slot`, capped at 6. `FAITH` rows: `slot` ("+1 SLOT", prices 150/300/450, limit 3), `might` ("+1 MIGHT",
  step 25, limit 6), `clock`, `respec`. `carried` counts the nights each ability was drafted; `seal_target()` seals the most carried
  ability after a lost Hunt; `sealed` / `seal_nights` hold the seal. `loadout` remembers the last draft.
- `Game` (`src/game/game.gd`): for a god's night it sets `mission.levels = god.learned.duplicate()` and starts the mission with the
  drafted loadout; `GodNight.bank(slot, id, drafted, outcome)` banks the night.
- `Rules` (`src/game/rules.gd`): `loadout`, per-slot `_cooldowns`, `refusal(slot)` ("over", "empty", "cooldown", "busy"),
  `cast(slot, ground, extra)`, `recast()` for a live power's follow-up, `free_play` (Remembrance: no cooldowns, no clock),
  `busy_left()` (one cataclysm at a time), and the Divine Surge (the Temple's fall resets every cooldown, once).
- `Mission` (`src/game/mission.gd`): `SLOT_KEYS := [KEY_1..KEY_6]` arm slot `i` of `_rules.loadout`. Other night keys in use:
  F, Esc, R, H, C, Tab, Space, Q, E (the armed power's modes, in `Targeting`), W, A, S, D, arrows, U, Enter, F1. Ctrl, Z, X, 7, 8, 9
  and 0 are free.
- `Hud` (`src/game/ui/hud.gd`): one draw-based Control. The slot row is cards of icon + name (`SLOT_SIZE` 42, `SLOT_W` 100-150,
  `SLOT_TOP` 316 on the 640x360 logical screen). Caption, ASCEND button, the rite's "C CHAIN" plate and other plates are placed
  relative to `slot_top()` / `slots_rect()`. `_on_cast_refused` flashes the slot and plays `ui_buzz`.
- Ability prices: `PowerBook.might(key, level)` = the row's `dp` (1-6) + 1 at level 3 + 1 at level 5. Cooldowns per level from
  `PowerBook.cooldown(key, level)`. Tier 1 abilities at level 1: cooldowns 8 s (whisper) to 36 s (blight), prices 1 or 2
  (discord, breath and blight cost 2).
- `GodTree`: six types in a ring, 5 tiers x 2 spots each (10 abilities a type). A god learns its own type (1 point) and its ring
  neighbours' (2 points), so a god holds at most three types.
- God bots: `tools/dev/behaviour_check.gd --god=<type>:<tier>` starts a `Mission` directly with a small loadout (the type's two
  Tier 1 keys for the five Tier 1 missions in `tools/dev/routes/god_t1.gd`; the file's `LOADOUT` for the five Hunts in
  `tools/dev/routes/god_hunts.gd`). They do not go through `GodNight` or Prepare. `tools/dev/refs/*.tsv` holds 204 rows that carry
  `--god`, and 18 `--case=none` rows (five Hunts and `first_taste`, three seeds each) that cast nothing.
- The god gates judge more than wins. `tools/dev/god_gate.sh` (through `gate.sh`) also fails a pair that stands idle over 45 s (60 s
  for three named pairs): the user's no-waiting limit. `tools/dev/hunt_gate.sh` also fails a Hunt whose pooled median time leaves
  180-240 s (140-200 s for Hunt 1), with Decree excepted on Hunts 2-4.

## 4. Constraints

- Other sessions edit `rules.gd`, `hud.gd`, `mission.gd`, `game.gd` and `prepare_screen.gd` often. Changes there must be small hooks;
  new behaviour goes in new files.
- Godot 4.7.2, GDScript, the project's style (doc comment on every member, statics that a suite can prove).
- Scripted windowed runs use `user://test_*` files, never the player's saves.
- FLOW (`--flow-test`) and refs need a quiet machine; a fresh worktree needs `--headless --path . --import` first.
- Landing follows the project's merge procedure: fetch, trial merge, gate the merged tree, then fast-forward and push.

## 5. Approaches

1. **Extend the existing night; new code in new files. (Picked.)** `Rules` gets an optional Might pool: on for a god's night, off
   everywhere else. A god's night loads every learned ability as its loadout. The gauge and the new bar are new files; the shared
   files get hooks only. Trade-off: the 204 `--god` reference rows are re-recorded, because bots now pay Might.
2. **A separate night for gods.** Copies of the rules and HUD used only in Endless Night. No shared file is edited, so no conflicts
   now. Trade-off: casting logic exists twice and drifts; every later ability, sound and HUD change is made in two places.
3. **Replace the loadout everywhere.** Ruled out by scope: the user chose Endless Night first.

**[user]** Approach 1. It conflicts least over time, and the board can be switched over later by turning the pool on there.

## 6. The design

### 6.1 Scope **[user]**

Endless Night only: a god's ordinary nights, Lantern Hunts and Awaken rites. The Missions board, the campaign, the skill tree's
test night and Remembrance keep today's behaviour (loadouts, no gauge).

### 6.2 The Might gauge **[user]**, details **[call]** where marked

- Size = the god's Might budget, `GodSlot.max_might()` (6, 8, 10, 13, 16 by tier, plus "+1 MIGHT" Faith purchases, up to +6).
- A night starts with a full gauge.
- A cast costs the ability's current Might price, `PowerBook.might(key, level)` at the god's learned level.
- A full refill always takes the same time, 60 s at base, whatever the size. So the refill rate is `size / refill_seconds` Might per
  second (0.10/s at size 6, 0.27/s at size 16).
- Cooldowns are unchanged. An ability must be off cooldown **and** affordable.
- The numbers live as constants in one new file (see 6.8): the base refill seconds, the Faith step, the floor.

Details, all **[call]**:
- The gauge is a float; the refill is continuous. The HUD shows whole Might as full segments and the fraction as a part-filled one.
- Might is spent at the same point the cooldown starts: a cast that `Rules.cast()` accepts. A refused cast spends nothing.
- A live power's follow-up (`Rules.recast()`: Called Bolts, Procession, Second Word, Turn the Tide) is free, as it starts no
  cooldown today. An armed power's modes (Q/E) cost the ability's price whatever the mode.
- The refill runs on the same clock as cooldowns (`Rules.advance(delta)`), so pause, hit-stop and the intro treat both alike.
- The Divine Surge (the Temple falls) also refills the gauge to full, with its cooldown reset.
- A night with acts: each act starts with a full gauge (each act builds its own `Rules` today).
- The Chain of the Forgotten (the rite's C power) stays free and outside the gauge.
- `Rules.free_play` (Remembrance, the tree's test night) never has a pool.
- New refusal reason `"might"`: the HUD flashes the tile, plays `ui_buzz` and shows the quiet banner "NOT ENOUGH MIGHT".
  Order in `Rules.refusal()`: "over", "empty", "sealed", "cooldown", "might", "busy". Cooldown stays ahead of Might because its
  seconds are already on the tile.

### 6.3 What a god brings **[user]**, details **[call]**

- **[user]** Every learned ability is available in the night; there is no pick.
- **[call]** The night's loadout is `slot.in_tree()`: every learned key that sits in a tree spot, in `GodTree.spots()` order, the
  sealed one included. A god with nothing learned gets `GodNight.NO_POWERS` as today.
- **[call]** Levels are the learned levels, as today (`mission.levels = god.learned`).
- **[call]** `GodSlot.loadout` (the remembered draft) is no longer read or written by a night. The field and its file key stay, so
  old files load and no migration is needed.

### 6.4 The seal **[call]** (told to the user, not objected to)

- A sealed ability stays on the bar with a lock and cannot be cast: `Rules.refusal()` returns `"sealed"`; the HUD says
  "SEALED BY THE LANTERN". It keeps its place on the bar so the other abilities' keys do not move for three nights.
- A lost Hunt seals the ability **cast on the most nights**. `GodSlot.carried` keeps its name and file key and now counts, per
  ability, the nights on which it was cast at least once. Old counts (nights drafted) carry over as they are. Ties break as today
  (higher Might, then earlier spot); fewer than two abilities in the tree still seals nothing.
- `Rules` records the keys cast this night; `GodNight.bank()` and `_bank_rite()` take that list where they take `drafted` today
  (the union across acts for a night with acts). A forfeit records nothing, as today.

### 6.5 The ability bar **[user]**, details **[call]**

The mockup the user chose from: `docs/superpowers/specs/assets/2026-11-19-might-gauge-bar-mockup.html` (option "B", layout 1; a
copy of the design session's page, so its icon links do not resolve: the icons are `assets/pixellab/icons/hud/*.png`).

**[user]**
- **Hidden by default.** A small strip at the bottom centre shows the armed ability (icon tile with its key, name, Might price) and
  the Might gauge (label, segments, "9 / 16"), with the hint "Ctrl: abilities".
- **Ctrl toggles the full bar.** The number keys still arm abilities while the bar is hidden.
- **Shown:** one row of up to ten icon-only tiles for **one god type**, on keys 1, 2, ... 9, 0, left to right. Above the row: one
  line with the armed ability's name, Might price and "ready" or its cooldown seconds; above that, the type tabs with their counts
  ("Z  DOMINION 4 | RUIN 10 | PASSAGE 3  X"); above that, the gauge.
- **Z and X** turn the page to the previous / next god type.
- Each tile shows its key (top left) and Might price (bottom right). Unaffordable: icon greyed, price in red. On cooldown: icon
  shaded with the seconds over it. Armed: gold outline.

Sketch, bar shown (640x360 logical screen, tiles 46 px in the mockup at 800 px wide; the builder scales to the HUD's units):

```
                      MIGHT [#########-······] 9 / 16
              Z   DOMINION 4  [RUIN 10]  PASSAGE 3   X
                  Tornado Tempest   2 Might   ready
   [1][2][3][4][5][6][7][8][9][0]      <- icons only, key top-left, cost bottom-right
```

Bar hidden:

```
        [3 icon] Tornado Tempest  2 Might   MIGHT [#########-······] 9 / 16        Ctrl: abilities
```

Details, all **[call]**:
- Pages: one per god type the god has learned at least one ability of. Tabs read as in the mockup, the god's own type in the
  middle: the ring neighbour before it on the left, the one after it on the right (`GodTree.neighbours(type)` order; a Ruin god
  sees DOMINION | RUIN | PASSAGE). Z turns left, X right, and both wrap around. With one type there are no tabs and Z/X do nothing.
- A page's tiles are that type's learned abilities in tree order (tier 1 to 5), packed from key 1 with no gaps. A newly learned
  ability can therefore shift later keys on its page; packed was preferred over fixed-by-spot because the user asked for a cleaner
  bar, and empty tiles are clutter.
- Each night opens on the own-type page with the bar hidden and nothing armed. With nothing armed the strip shows only the gauge
  and the hint.
- The number keys always address the current page, shown or hidden. Turning the page with Z/X works while hidden too; the strip
  then shows the page's name briefly (about 1.5 s) so the player knows where the keys now point. Turning the page does not disarm
  the armed ability.
- Mouse: clicking the strip opens the bar; clicking a tile arms it; clicking a tab turns to that page. Hovering a tile shows its
  name line, as the armed line does.
- A sealed tile shows a lock over a darkened icon.
- Both Ctrl keys toggle, on press, not on echo, and only when no other modifier combination is in play (Ctrl held for a
  Ctrl+key shortcut must not toggle: toggle on a Ctrl press that is released without another key in between, or simply on press if
  the game binds no Ctrl combinations in a night; builder's choice after checking).
- Everything the HUD places relative to the slot row today (caption, ASCEND, the "C CHAIN" plate, plates stacked above) is placed
  relative to the bar's current rectangle, which is the strip when hidden and the full bar when shown.
- The bar scales with the project's UI scale system (`ui_scale.gd`, any resolution) like the rest of the HUD, and its icons use the
  crisp icon path the slot cards use (`_slot_icons_big`).
- Where the pool is off (board, campaign, Remembrance) the HUD draws today's slot cards, unchanged, and keys 1-6 behave as today.

### 6.6 Prepare **[user]**, details **[call]**

**[user]** Prepare stays, as a briefing. The left side (the mission brief, the Hunt and rite headers, the seal note, gift effects) is
unchanged. The right side becomes a read-only list of the god's abilities by type, each with its Might price, plus the gauge size.
One DESCEND button.

Details, all **[call]**:
- Reuse the existing tabs and cards grid in a read-only mode: cards cannot be picked, the level picker is off (as it is for a god
  today), the loadout bar is not drawn, hover still plays the ability's preview. The sealed ability's card carries today's sealed
  note.
- In place of the loadout bar: one line, "Might N  ·  full refill in S s" (the god's size and refill time), and the DESCEND button
  where MANIFEST is. Enter descends, as it manifests today. There is no "pick at least one power" refusal.
- A night with acts shows the same read-only briefing between acts.
- The board's and campaign's Prepare are untouched.

### 6.7 Faith **[user]**, details **[call]**

**[user]**
- "+1 MIGHT" is unchanged in price and limit; it now means +1 gauge size.
- "+1 SLOT" becomes **"FASTER MIGHT"**: each purchase cuts the full refill by 5 s (60, 55, 50, 45). Same prices (150/300/450) and
  limit (3). A god's existing slot purchases convert one for one.

Details, all **[call]**:
- The row keeps its key `"slot"` in `FAITH` and in the god's file; only its name and meaning change. So existing purchases
  convert with no file change, `GodSlot.VERSION` stays 1, and an older build on another branch that opens the same god file still
  reads and writes the purchases instead of dropping an unknown key (up to 900 Faith). A comment on the row says why the key is
  not renamed. `GodSlot.slots()` and `BASE_SLOTS` stay only if something still needs them (the Hunt bots' loadout check does
  today); otherwise remove them with their tests.
- New `GodSlot.refill_seconds()` = base - step x `bought.slot`, never under the floor.
- Faith screen lines: "Full refill: 55 s" for the row, "Might gauge: 9" for "+1 MIGHT" (today "Might to spend: 9").

### 6.8 Where the code goes **[call]**

New files:
- `src/game/might_pool.gd` (`class_name MightPool`, RefCounted): `capacity`, `refill_seconds`, `value`; `advance(delta)`,
  `can_pay(cost)`, `pay(cost)`, `refill()`; the constants `REFILL_SECONDS := 60.0`, `REFILL_STEP := 5.0`, `REFILL_FLOOR := 30.0`;
  a static `for_god(slot)` and `for_tier(tier)` (the bots' pool: the tier's size, base refill).
- `src/game/ui/ability_bar.gd`: the strip and the bar, their layout rectangles, page state, hit-testing and drawing. It reads
  `Rules` and the pool; it owns no rules.
- Tests for both, and a windowed photograph (`--show=`) of the strip and of the bar for the review captures.

Hooks in shared files, kept as small as they can be:
- `rules.gd`: `var might: MightPool = null` (null = off), `var sealed := ""`, a list of keys cast; `refusal()` gains "sealed" and
  "might"; `cast()` pays; `advance()` advances the pool; the Divine Surge refills. With `might == null` and `sealed == ""` every
  code path is today's.
- `mission.gd`: carries the pool and the seal from the def/Game into `Rules` at `_build_act`; when the pool is on, number keys
  1-0 go through the bar's page, Ctrl/Z/X go to the bar. With the pool off, `SLOT_KEYS` behaves as today.
- `hud.gd`: when the pool is on, builds an `AbilityBar`, skips its own slot-row drawing and hit-testing, and answers `slot_top()` /
  `slots_rect()` from the bar. New banners for "might" and "sealed".
- `god_night.gd`: `_apply_god` sets the def's pool to `in_tree()` and marks the def as a gauge night with the god's size, refill
  time and seal; `bank()` / `_bank_rite()` take the cast keys.
- `mission_def.gd`: the fields that carry the gauge (size, refill seconds, sealed key); defaults mean "off".
- `game.gd`: a god's night starts with the def's full pool as its loadout and no draft; passes the cast keys to `bank()`; the FLOW
  steps that assert Prepare's "3 slots, 6 Might" style texts are updated.
- `prepare_screen.gd`: a read-only mode for a gauge night.
- `god_slot.gd`, `faith_screen.gd`: the renamed row, `refill_seconds()`, the texts.
- `tools/dev/behaviour_check.gd`: every `--god` run turns the pool on with `MightPool.for_tier(tier)`. Loadouts and policies stay.

### 6.9 Bots and balance **[user]** for the rule, **[call]** for the method

**[user]** The check is that the god bots still win. If some fail, tune the refill speed and the gauge size, not the missions.

**[call]**
- Bots keep their small loadouts and policies and pay Might from the tier's base gauge with no Faith upgrades. That is the weakest
  god of that tier, so a bot win means any real god can win.
- A bot that meets a `"might"` refusal waits and retries, as it does for a cooldown today; if a policy cannot do that, the policy
  gets the smallest change that lets it.
- The pass bar is the gates as they pass on `acb82b96`, not wins alone: `god_gate.sh` and `hunt_gate.sh` green, which includes
  the idle limit (the user's no-waiting rule) and the Hunts' median bands. Record both gates on the untouched tree first, so a
  pair that already fails there is not blamed on the gauge.
- Expected pressure, Tier 1: size 6 and 0.10 Might/s give about 36 Might over a 300 s night (6 + 30). Cooldowns alone already cap
  Death and Passage near 27 casts, so the gauge should not bind there. Dominion would spend about 57, Ruin about 50, Veil about
  46, and Decree's combo costs 3 a time. Expect the failures in those four types, not spread across Tier 1.
- Tuning order when a gate fails, staying inside the user's rule: first `REFILL_SECONDS`, from 60 down to 45 and no lower (under
  45 the third "FASTER MIGHT" purchase would hit the 30 s floor and buy nothing); then a flat bonus to every tier's gauge size.
  The Faith step (5 s) and floor (30 s) do not change.
- If those two numbers cannot bring a pair back inside the gates, stop and bring the user the bot results. Whether the idle limit,
  a Hunt band or a bot policy then gives is the user's decision, not the builder's.
- Any number other than the agreed 60 s and tier budget is reported to the user with the bot results before landing.
- After tuning, re-record the 204 `--god` rows. The other 304 rows must not change (no pool there); a changed one is a bug.

## 7. Testing and landing

- Unit suites: `MightPool` (spend, refill rate, clamp, refill, `for_god`, `for_tier`); `Rules` with a pool (refusal order, pay on
  accepted cast only, recast free, surge refills, `free_play` and null pool unchanged, sealed refusal, cast-keys list); `GodSlot`
  (the renamed row, an old file's purchases read as before, `refill_seconds()`, `seal_target()` by nights cast); `GodNight` (pool = `in_tree()`,
  gauge fields on the def and each act, `bank()` with cast keys); the bar (pages, key mapping, packed order, hidden/shown
  rectangles, hit-testing, sealed tile); Prepare's read-only mode; the Faith screen texts.
- Existing suites that assert slots, drafts or "+1 SLOT" in a god's night are updated, not deleted, unless what they prove no
  longer exists.
- FLOW on a quiet machine, with the Endless steps updated for the briefing.
- God gates: `tools/dev/god_gate.sh` and `tools/dev/hunt_gate.sh` (every type's Tier 1 policy on the five missions, every Hunt).
- Refs: `tools/dev/refs_check.sh`; the 304 rows without `--god` identical, the 204 `--god` rows re-recorded once the gates pass.
- Full suite: `bash tools/dev/run_suite_parallel.sh 6` (rerun a "NO RESULT" part alone with a longer timeout).
- Real screen captures of the strip and the bar at 1280x720 and one larger resolution, on the test save.
- After landing: Ledger (idea done, task entry, board refresh); Discord (#ideas post OPEN to DONE and closed, #god-changelog post).

## 8. Left to the builder

- Exact pixel layout of the strip and the bar in the HUD's units, within the mockup's proportions.
- How Ctrl-alone is detected (see 6.5).
- Field names on `MissionDef` and the exact signatures of the hooks.
- Whether `GodSlot.slots()` / `BASE_SLOTS` survive (see 6.7).
- The wording of the page-name flash on the hidden strip.
- Which existing photographs (`--show=`) of six slot cards in a god's night are replaced by bar photographs.

## 9. Risks

- **Balance** is the main one: Tier 1's small gauge may starve the bots. Mitigated by the constants in one file and the tuning
  order in 6.9.
- **Merge conflicts** in the five busy shared files: mitigated by hooks-only edits and by landing soon after the build.
- **Muscle memory**: packed tiles shift when an ability is learned (6.5). Accepted for a cleaner bar.
- **A long ability list in memory**: a god's night now holds up to 30 abilities in `Rules.loadout`; anything that scans the loadout
  each frame (HUD caches, `Remains.wants`) must stay cheap. The frame rate is CPU/draw-call bound, so profile if in doubt.
