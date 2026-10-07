# KAK v0.11: The Tiers (design)

Date: 2026-10-08. Status: approved in chat, section by section. Builds on v0.10 (campaign, M6 objective tags) and v0.09.1
(the other session's board-tag work at `92e0dcc`).

## 1. Why

The board has three missions. The god's five Awakening Tiers exist only as a number on a card. v0.11 turns the board
into a five-tier difficulty select, after Helldivers 2:

- **Tiers:** the player picks a tier, then one of its five missions. That makes 25 missions, each at least five minutes
  of play.
- **Wishes:** each descent, 2 or 3 random wishes heard from citizens are optional secondary objectives that pay
  **believers**.
- **Ascending:** once the main objective is done, the god may ascend at once or stay for the wishes, at the risk of
  losing what they earned.
- **Upgrades:** believers carry over between missions and buy the god's upgrades.
- **Unlocking:** clearing missions opens the next tier.
- **Nights:** every board mission played is a night.

**The no-waiting rule** (the user's rule, binding on every mission and wish):

- Everything finishes by acting.
- No objective waits for dawn.
- A timed wait is 60 s at most.

## 2. Scope and order

| Milestone | Builds | Playable at its end |
|---|---|---|
| **M1 Framework** | The tier board, save, tier scaling, Prepare with tier budget and upgrades, ASCEND and results, believers, the Upgrades screen, wishes (8 in the pool), the 8 existing missions put on their tiers, the no-waiting changes (§7.3) | All 5 tiers, 8 missions |
| **M2 Whisper** | Missions 2-5, with the new types Assassinate and Escort | Tier 1 complete |
| **M3 Omen** | Missions 8-10 | Tier 2 complete |
| **M4 Wrath** | Missions 13-15, with the new type Hunt | Tier 3 complete |
| **M5 Reckoning** | Missions 17-20 | Tier 4 complete |
| **M6 Ascendance** | Missions 23-25 | All 25 |

- This spec gives the framework in full and the 25 missions as sketches.
- Each tier milestone (M2-M6) opens with a short mission spec for the user's approval: exact numbers, events, twists,
  wishes added. Then its plan follows.
- **Unchanged:** the Lantern campaign, except that the no-waiting changes to The Warning and Mira's House (§7.3) reach
  its Night 1 and Night 2 too, because they share the directors.

## 3. The tier board and progression

### 3.1 The board

- **Entry:** the title's **Missions** button opens the tier board. `Campaign` is unchanged.
- **Tabs:** five tier tabs. The names of Tiers 2-4 are placeholders the user may rename.

  | Tier | Name |
  |---|---|
  | 1 | Whisper |
  | 2 | Omen |
  | 3 | Wrath |
  | 4 | Reckoning |
  | 5 | Ascendance |

- **Cards:** each tab shows its missions as cards: name, type (Destroy, Kill, Cult, Intercept, Break, Protect), a two-line
  brief, best result, and a tick once cleared.
- **Header:** `Night N`, the believer total, and an **Upgrades** button.
- **Locked tabs:** a locked tier shows a padlock and the rule, e.g. "Clear 3 Omen missions".
- Choosing a card opens Prepare (§4).

### 3.2 Unlocking

- **Tier 1** is open from the start.
- **Tier T+1** opens once 3 of Tier T's missions are cleared.
  - **While tiers are short** (before M6): if Tier T has fewer than 3 missions, all of them must be cleared.
  - "Cleared" means the main objective was done in some night, whether the god ascended or was caught after it.
- A tier never closes again.

### 3.3 Nights

- Every board mission played to its end, won or lost, adds 1 to the night counter.
- An abandoned night (Pause > Missions) or a restart does not count.
- The counter has no story effect yet.

### 3.4 Believers and upgrades

Believers carry over between missions. They are added to only when banked (§6). The Upgrades screen spends them on:

| Upgrade | Price | Limit |
|---|---|---|
| +1 DP | 25 × n believers for the n-th | 6 (+6 DP) |
| +1 slot | 150 believers | 1 |
| Unlock a power | 15 × its DP cost (3 DP = 45, 4 DP = 60, 5 DP = 75, 6 DP = 90) | — |

- **Starting powers:** the powers costing 1 or 2 DP start unlocked. That is 15 of 38 today.
- **Locked powers** show greyed out in the board's draft, with their price.
- **Board only:** upgrades apply to board missions only. The campaign keeps its own DP rules.
- **First guesses:** the prices are first guesses, tuned in M2 against a played Tier 1.

### 3.5 Save

- **The new section:** `[descend]` holds the night counter, believers, the highest open tier, the cleared missions, the
  upgrades bought, the powers unlocked, and per-mission bests.
- **Bests per mission:** cleared, fastest clear (seconds to the main objective) and most wishes granted in one night.
- **A save without the section** starts the board fresh.
- **Old bests:** a v0.10 save's board bests for The Warning, The Long Night and Last Judgement carry over to their ★
  missions as cleared and best time.
- `[campaign]` is untouched.

## 4. What each tier sets

| Tier | Town readiness | Base slots / DP | Clock (dawn) | Wishes heard | Believer multiplier |
|---|---|---|---|---|---|
| 1 Whisper | Unaware | 3 / 6 | 5:00 | 2 | ×1 |
| 2 Omen | Organized | 3 / 8 | 5:30 | 2 | ×1.5 |
| 3 Wrath | Prepared | 4 / 10 | 6:00 | 3 | ×2 |
| 4 Reckoning | God-Resistant | 5 / 13 | 6:30 | 3 | ×2.5 |
| 5 Ascendance | God-Resistant, plus Halcyon's Gaze in every mission | 6 / 16 | 7:00 | 3 | ×3 |

- **Readiness** uses today's `ResponseProfile` profiles. A mission may raise it, never lower it, as The Long Night's acts
  already do.
- **Prepare:** board missions drop the difficulty picker.
- **Budget:** a board mission's slots and DP are its tier's base plus the upgrades bought.
- **Time:** the clock is at least 5:00 everywhere. A mission's main objective is designed to take 3-4 minutes.
- **Believers**, times the tier's multiplier and rounded: 10 for the main objective, 5-15 per wish by its difficulty.
- **The Gaze at Tier 5:** in every Tier 5 mission, a seen death adds to Halcyon's Gaze and a full Gaze loses the night.
  Missions that already keep a Gaze, such as Mira's House, keep their own at every tier.
- **First guesses:** each tier milestone tunes its numbers with scripted test players, as v0.10 did.

## 5. Wishes

### 5.1 Hearing them

- **When:** at the descent, before the clock starts, a plate reads "The town prays…" over the wishes drawn. In a Night 2
  mission this happens during its tour.
- **How many:** the tier's count (2 or 3), drawn at random from the pool.
  - The draw uses the night's seed, so a restart of the same night hears the same wishes.
  - A new night redraws.
- **Eligibility:** a wish is drawn only if its needs are met.
  - Its target exists: a building of its role, or a citizen of its kind.
  - Its tags do not clash with the mission's. A mission declares tags such as `kills_clergy` or `burns_market`; a wish
    lists the tags it cannot sit beside.
  - A mission with too few eligible wishes offers what it can, possibly none.
- **The wisher:** each wish has one, a real citizen chosen when it is drawn and tagged on the map in the wish colour
  (soft blue, `Color("8fb8ff")`) with the label `WISH`.
- **Failing:** if the wisher dies before the wish is granted, it fails ("Their prayer goes unanswered").

### 5.2 Doing them

- **On the HUD:** wishes are listed under the how-to-win line, e.g. `☐ Burn the moneylender's house (+10)`.
  - A granted wish ticks and turns its wisher into a Believer.
  - A failed one is crossed out.
- **Map tags:** a wish's target carries a wish-coloured tag with a short label, such as `MONEYLENDER` or `THE CHILD`.
- **No waiting:** a wish is granted the moment its act is done.
- **Timed wishes** (the Rescue kind) wait until the player engages: clicking the wish's tag, or casting at its target.
  Then they run a timer of 60 s or less.
- **Any time:** wishes can be done before or after the main objective.

### 5.3 The pool at M1 (8 wishes)

| Wish | Kind | Act | Reward | Needs / clashes |
|---|---|---|---|---|
| Burn the moneylender's house | Ruin | Destroy the marked house | 10 | a house; clashes with `spares_houses` |
| Bring down the watchtower | Ruin | Destroy the marked tower | 15 | a watchtower; — |
| Strike down the cruel tax collector | Punish | Kill the marked citizen | 10 | a lay citizen; — |
| Kill the informer, unseen | Punish | Kill the marked citizen, unseen (no living witness, as The Warning judges) | 15 | a lay citizen; — |
| Save my child | Rescue | Once engaged, a soldier drags the child toward the Citadel's gate. Stop or turn him within 45 s | 15 | a soldier and a child-age citizen; clashes with `unaware_town` |
| Lead my brother out | Mercy | Whisper the marked citizen to any exit; he escapes | 10 | a lay citizen; — |
| Show me a sign | Sign | Cast any power within 4 units of the wisher while they live and see it | 5 | none; — |
| Show yourself to my family | Sign | Whisper three of the wisher's household (marked) | 10 | three citizens near the wisher's home; — |

- **More wishes come with each tier milestone,** e.g. "Stop the bailiff" (Rescue: stop him reaching the wisher's home
  within 50 s) and "Let my neighbours believe" (Faith).
- **Under the hood:**
  - `WishDef` is the data. `WishBook` is the pool, with its filters.
  - A wish at run time reuses the `Objective` pattern: `check(rules) -> Status`, `hud_text()`.
  - Its targets come from the director's world, chosen by `WishBook` at the descent.

## 6. Ascending and the results

- **Before the main objective:** no ASCEND button.
  - A loss (bell, Gaze, escape limit, dawn) gives no believers and still counts as a night.
  - Pause > Missions abandons the night without counting it.
- **Main objective done:**
  - The banner `THE NIGHT IS YOURS` shows.
  - An **ASCEND** plate appears above the slots, which can be clicked, or the **F** key does the same
    (nothing else in a mission uses it).
  - The clock keeps running, and every way of losing still applies.
  - The how-to-win line switches to the open wishes, or to "Ascend when you are ready" if there are none.
- **Ascending:**
  - A short rise of light over the god's last cast spot (about 2 s, using the ending's slow motion), then the results.
  - **Banked:** the main objective's believers plus every granted wish's.
- **Caught after the main objective** (bell, Gaze, escape limit or dawn first):
  - The main win stands and its believers are banked.
  - The granted wishes' believers are lost. The results show them struck through: "lost: Halcyon saw you" / "lost: dawn
    came".
- **The results screen:**
  - The main objective's tick, and each wish (granted, failed or lost).
  - Believers earned and the new total.
  - `Night N`.
  - Tier progress, e.g. "Omen 2 / 3 cleared: one more opens Wrath".
  - Bests beaten.
  - Buttons: **Board**, **Again**, **Upgrades**.

## 7. Mission types

### 7.1 The ten types

Each type is one director, set up per mission (targets, district, counts, event times, twist).

| Type | Director | Shape |
|---|---|---|
| Intercept | `WarningDirector`, generalised | Someone runs to raise the alarm; stop them and their relays. |
| Break | `FestivalDirector`, generalised | Kill or scatter enough of a gathering before the guard arrives. |
| Ambush | `ProcessionDirector`, generalised | A VIP walks a route to an exit; kill him on the way. |
| Raze | `LastJudgementDirector` / `JudgementDirector`, generalised | Destroy the named structures (any role, or the Citadel) while repair crews work. |
| Convert | `MirasHouseDirector`, generalised | Lead people to a holy place unseen; won the moment enough believe. |
| Anchors | `BrokenLanternsDirector`, generalised | Break several anchors and keep each broken 20 s. |
| Steal | `VigilFlameDirector`, generalised | A mortal hand swaps a sacred object unseen and carries it to a drop-off. |
| **Assassinate** (new, M2) | `AssassinateDirector` | A named target moves between guarded spots on a schedule; find and kill him, with a bonus if unseen. |
| **Escort** (new, M2) | `EscortDirector` | Lead a believer or a group out past the watch; any wait at a gate is under 60 s. |
| **Hunt** (new, M4) | `HuntDirector` | Hunters sweep district by district toward your hidden believers; break the hunt (their standards, their captain) before they arrive. |

Every type reports `tags()`, `hint_phase()` and `tour()` (M6), and the mission tags that wishes filter on (§5.1).

### 7.2 Board versions of the existing missions

The eight ★ missions keep their directors and rules. On the board they take their tier's clock, readiness and budget.

- **Timelines:** their event times stretch in proportion to the longer clock, so their windows still fall inside the
  night.
- **Too-short main objectives:** a mission whose main objective takes under 3 minutes gets more to do.
  - **The Warning:** three stars fall through the night, at three gates, each sending a runner (0:10, 1:30, 3:00).
    Stop all three warnings.
  - **The Festival:** the need rises (first guess: from 50 to 80 goers), with the square closing at 4:30.

### 7.3 The no-waiting changes (M1; they also reach the campaign)

- **Mira's House** wins the moment the fourth Believer walks out of the house. Today it wins at dawn.
- **The Warning** is won only by stopping the warning, actively. Holding out until the omen fades no longer wins; at the
  clock's end the night is lost, as at any other dawn.
- **References:** these changes move the Mira's House and Warning reference checksums once, on purpose, in M1. The plan
  names the new values.

## 8. The 25 missions (sketches; ★ = exists today)

| # | Tier | Mission | Type | Main objective | Twist / pressure |
|---|---|---|---|---|---|
| 1 | Whisper | ★The Warning | Intercept | Stop three warnings (§7.2) | Each later runner starts nearer the bell. |
| 2 | Whisper | The Tax Collector | Assassinate | Kill the tax collector | He makes his rounds with two guards and hides in the counting-house if alarmed. |
| 3 | Whisper | Spoiled Harvest | Raze | Burn the three granary stores | Carts carry the grain to the Citadel; a store emptied cannot be spoiled. |
| 4 | Whisper | The Lost Lamb | Escort | Lead a runaway acolyte out through the west gate | The watch changes at the gate (a wait under 60 s); patrols cross his path. |
| 5 | Whisper | First Prayers | Convert | Lead three of the poor to the old well shrine unseen | Few Faithful, but the shrine sits by the market. |
| 6 | Omen | ★Mira's House | Convert | Four believe (§7.3) | Venn, the shout, the Vigil, the fire. |
| 7 | Omen | ★Broken Lanterns | Anchors | All six shrines drained | The Vigil relights them; the Knights come. |
| 8 | Omen | The Bell-Ringers | Intercept | Stop three runners from three watch posts | Any of them can ring the bell. |
| 9 | Omen | Market Panic | Break | Scatter the market fair | A smaller Festival; the guard closes the market. |
| 10 | Omen | The Informer | Assassinate | Kill the informer before he reaches the Temple | He carries your believers' names; find him by the three contacts he visits. |
| 11 | Wrath | ★The Vigil Flame | Steal | The flame home at Mira's shrine | Wren, the swap, the Searchlight. |
| 12 | Wrath | ★The Festival | Break | Break the festival (§7.2) | The bonfire, the Mayor's address. |
| 13 | Wrath | The Crown's Bread | Raze | Destroy the granary, the mill and the bridge | Engineers repair what is damaged. |
| 14 | Wrath | The Prisoner | Escort | Break her stocks at the Citadel, lead her out | The guards change at the gate (a wait under 60 s). |
| 15 | Wrath | The Heretic Hunt | Hunt | Break the hunt: three lantern-standards and its captain | The Inquisitors sweep toward your believers' cellar. |
| 16 | Reckoning | ★The Procession | Ambush | Kill the Prince before he sails | The blessing, the dock. |
| 17 | Reckoning | The Bishop | Assassinate | Kill the bishop | Lantern Knights guard him; set the Temple alight to draw him into the square. |
| 18 | Reckoning | The Armoury | Raze | Destroy the armoury and two barracks | The muster horn: soldiers arm faster each minute. |
| 19 | Reckoning | The Sermon | Convert | Turn eight of the preacher's crowd | The Faithful watch, and the preacher must be silenced first. |
| 20 | Reckoning | The Relic Run | Steal | Swap the relic while its cart halts | It halts at two checkpoints, each a window under 60 s. |
| 21 | Ascendance | ★Last Judgement | Raze | Destroy the Citadel and break the city | The escape limit. |
| 22 | Ascendance | ★The Long Night | three acts | Win the night | The acts' own (≈10 min). |
| 23 | Ascendance | The Lantern's Eye | Anchors + Hunt | Shatter the three tower mirrors that aim Halcyon's Searchlight | The beam hunts the god's casts. |
| 24 | Ascendance | Exodus | Escort | Lead ten believers out | The Inquisition closes the gates one by one. |
| 25 | Ascendance | The Heart of Faith | Raze + Assassinate | Put out the Great Temple's flame, then kill High Priest Odran | Two stages; Lantern Knights, the Gaze. |

How the types spread:

- Destroy (Raze): 6.
- Kill (Assassinate, Ambush): 6.
- Cult (Convert, Steal): 5.
- Intercept and Break: 5.
- Protect (Escort, Hunt): 5.
- Anchors: 2.

Each tier milestone may adjust its missions' details in its own mission spec. It changes neither the type, the main
objective nor the no-waiting rule without the user's approval.

## 9. Testing and gates

- **Per mission,** as with the Night 2 missions:
  - unit tests of its director;
  - a behaviour scenario where doing nothing loses and a scripted player wins at least 2 runs in 3;
  - a scripted clear of the main objective in 3-4 minutes.
- **Framework:**
  - unit tests for the tier rules, unlocking, the save (including a v0.10 save), believers banking and losing, upgrade
    prices, wish drawing (seeded, filtered, clashes) and each M1 wish;
  - a FLOW section: board → locked tab → Prepare → ASCEND → results, and caught-after-main → results.
- **Gates every milestone:**
  - the state digest, `crowd_check` and the exact behaviour checksums;
  - any reference that moves is named and traced before landing (in M1: The Warning's and Mira's House's, by §7.3);
  - the full suite, and FLOW with 0 failures.
- **Frame rate:** a bench of one mission per tier against the previous release.

## 10. Out of scope (for v0.11)

- Story for the board nights.
- New towns: all 25 missions are in Aldermere.
- New art: text and drawn shapes, as M6.
- Helldivers-style random modifiers.
- Co-op.

The tier names (2-4), prices, rewards and clocks are first guesses, tuned per milestone.
