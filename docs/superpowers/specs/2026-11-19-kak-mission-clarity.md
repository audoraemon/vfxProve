# KAK Mission clarity (2026-11-19)

Source: the user's report, verbatim intent: "Some missions have an unclear description, like 'draw informer'. I tried to
draw them with Skylift and Discord but the mission isn't finished and the target is not acting somehow. Make every
mission more specific and clear the message: what exactly to do." Plus the user's three binding decisions (§0).

Base: `feat/Develop-Main` acb82b96. Lands on feat/Develop-Main. Plan:
`docs/superpowers/plans/2026-11-19-kak-mission-clarity.md`.

## 0. Binding rules

1. **Why-not banners.** A cast that lands on, or within reach of, a mission's target and does not count shows a short
   banner saying why ("TOO EARLY - NO WORD YET", "THEY WALK BACK TO HIS DOOR"). Each cause shows at most once per
   `WhyNotGate.REPEAT` (30 s). A cast far from every target shows nothing.
2. **Verbs only.** Steps (`MissionSteps`) and hints (`MissionHints`) name **verbs from one vocabulary** (§3), never a
   power ("Confuse the contact (orange)", not "Discord the contact"). Pressing C in the rite is a key, not a power, and
   stays. The H legend gets a third page listing each verb's powers, the player's equipped ones first (§4). The user did
   not ask for that page; it is ours, so it stays small.
3. **Keep the rules.** No mission mechanic, number or balance changes. All 233 reference rows (`tools/dev/refs/*.tsv`)
   stay byte-identical. When a text can only be made true by a rule change, it goes to §8 (open questions), not to the
   plan. New code is read-only: `why_not()`, `hint_phases()` and the new `hint_seconds()`/`step_seconds()` readouts.
4. Mission design lessons (memory `kak-mission-design-lessons`) still hold, and this spec applies their **Clarity**
   line: every step says what to do now, with the countdown where there is a wait and the tag colour of what it names.

### Copy rules (every task)

- **Step:** at most `MissionSteps.MAX_LABEL` (32) characters. It starts with a vocabulary verb, or with "Keep", "Be at",
  "Ambush" or "Ascend" when the move is to wait for a timed thing; a wait always carries a counter (`"c": "s"`). It names
  the tag colour of its target when it fits in 32.
- **Hint:** fits `Hud.HINT_LINES` (3) lines of `Hud.HINT_W` (236 px), as the existing fit test measures (about 125
  characters). It names every target with its tag colour, every way that counts in that phase as verbs, and `{n}` when
  the phase has a countdown (the director's `hint_seconds()`).
- **Banner:** upper case, at most 36 characters, plain words, the reason first ("STONE - FIRE DOES NOTHING").
- Colours are the tags' (`LegendPanel.MARKS`): gold, orange, red, blue (steel), grey. "unseen (red)" means: with none
  of the red-marked people near enough to see.
- A text that names a verb must be true in that phase for at least one power of that verb, proved by a Kit-world test
  (§6). When a test shows it is not, the copy changes, never the rule.

## 1. What the code does today (the Informer, the user's case)

`src/game/mission/informer_director.gd`:

- Phase `waiting` (word has not reached the contact): the step says "Draw his company away", the hint "Get his company
  (red) away before it does". Nothing the player does counts: word comes on a timer (`VISIT_AT` 45/115/180/245 s, or
  `CHAIN_WAIT` 45 s after the last turn), and `_keep()` walks the contact and his company back to their spots every
  `TICK`. Skylift (people "walk on to what they meant") and every draw are undone. No banner says so.
- After word (orange tag): `_on_cast()` turns him only for key `whisper` (a walk whisper at full `MindWhisperFx.LINGER`
  within `PICK_R`) or `discord` (full `DISCORD_TIME` within `DISCORD_R`), and only with no onlooker within `SPEAK_SEEN`
  (2.0) who is not `MissionDirector.BLIND` (whispered or confused). One Discord on the door confuses him and all his
  company (`COMPANY_HOLD` 1.0 < Discord's 1.2), so it turns him by itself. A lure, a fright or a Skylift on him counts
  for nothing and is silent; only "SEEN - HE SAYS NOTHING" exists.

The same kinds of trouble recur across the game (§5): steps that ask for something that does nothing yet, verbs that do
not say how ("draw", "clear", "remove", "stop", "strike" for a person), waits with no countdown, and four different
rules for "a held man sees nothing" behind one word.

## 2. Banners and the simulation (checked)

- `Rules.banner` is a plain signal. Its listeners: `Hud.push_banner` (display), `Mission`'s set-up hold list and its
  capture run's screenshot list (`mission.gd:587`, `:1509`). No director, no `behaviour_check` policy and no route reads
  a banner.
- `behaviour_check`'s checksum (`tools/dev/behaviour_check.gd:5505`) hashes every citizen's and soldier's position and
  mind. `state_digest` hashes structures and the environment field. Neither sees banners.
- So a why-not banner cannot move a reference **if `why_not()` only reads**: no rng, no `go_duty`, no timeline, no
  signal. It is routed straight to `Hud.push_banner`, not through `Rules.banner`, so the Kit worlds' banner lists, the
  capture shots and the directors' own banner tests do not change either.

## 3. The verb vocabulary (`MissionVerbs`, new, `src/game/mission/mission_verbs.gd`)

Twelve verbs. Each is one word, so a test can find it in a text (`\bword\b`, any case). Membership is fixed by what the
power's effect does to a person or building (the states the directors read), checked by a source test (§6.1).

| Verb | What it does (legend words) | Powers (keys) | Basis |
|---|---|---|---|
| Kill | they die, by any power | every key of `PowerBook.FAMILY` strike, fire and death but `guise`; plus `doom`, `hellspark`, `houndgate`, `breath`, `cage` | each fx kills (Task 1 reads each header; a key whose fx cannot kill is dropped) |
| Scare | they run from a loud power near them | every key with `PowerBook.is_quiet(key) == false` | the town's fright (`Crowd.on_cast`) |
| Lead | one walks where you click | `whisper` | `Person.whisper()` callers (Mind WHISPERED) |
| Lure | they walk to a light or a body and stare | `wisp`, `deathmark`, `windfall` | `Person.lure()` callers |
| Confuse | they wander, blind, and drop their task | `discord` | `Person.confuse()` callers |
| Hold | the god's hand on a mind: they drop their task and see nothing | every `Person.whisper/confuse/compel/lure` caller: `whisper`, `discord`, `wisp`, `deathmark`, `windfall`, `belllies`, `fargate`, `anathema`, `clearmind`, `echo`, `congregation`, `schism`, `verdict`, `oath`, `priority`, `sanctuary`, `saint`, `turncoat`, `voice` | `Person.held_by_god()` |
| Burn | sets a building alight | `FAMILY` fire: `ember`, `dragon`, `cinder` | fire family |
| Strike | a blow on a building or thing | `FAMILY` strike | strike family |
| Rot | rots a building or a thing | `blight` | `MissionDirector.blighted()` |
| Seal | NO LEAVING on a door | `noleave` | the Tax Collector's mob reads `NoLeaveFx` only |
| Banish | sets them down outside the walls | `skylift`, `mirror` | `DummyEnemy.fold()` callers; any way out counts |
| Calm | ALL IS WELL: the town stands down | `belllies` | The Bell Lies' ALL IS WELL |

Notes:
- Lead and Lure are kinds of Hold. A text says "Hold" only where the director's rule is `held_by_god()` (§5 marks it).
  Where the rule is `MissionDirector.BLIND` (whispered or confused only), the text says "Lead or confuse"; where it is
  `HarvestDirector.GUARD_MINDS` (a lured man still guards), it says "lead, confuse or scare". The four rules are open
  question Q2.
- "Unseen" is a condition, not a verb. "Keep", "Be at", "Ambush", "Ascend" and "Press C" are not verbs of the
  vocabulary and need no powers.
- API: `verbs() -> PackedStringArray` (table order), `powers(verb: String) -> PackedStringArray` (book order),
  `verbs_of(key: String) -> PackedStringArray`, `word(verb: String) -> String` (the capitalised word), `does(verb: String)
  -> String` (the legend words), `named_in(text: String) -> PackedStringArray` (the verbs a text names), and
  `legend_rows(loadout: PackedStringArray) -> Array` (§4).

## 4. The legend page

`src/game/ui/legend_panel.gd`: a third page, "WHAT YOUR POWERS DO". H cycles 1 -> 2 -> 3 -> close; the counter reads
"n / 3". One row per verb, in table order: the verb in gold, its legend words, then its powers by name -- the player's
equipped ones first in the HUD's text colour, the rest dim, cut to the row's room with "+N". A verb none of whose powers
is equipped stays, dim. `LegendPanel.setup(tags, loadout := PackedStringArray())`; `Mission.open_legend()` passes
`_rules.loadout`. The rows come from `MissionVerbs.legend_rows(loadout)`: `[[verb word, does, equipped names: Array,
other names: Array], ...]`. The footer and the two existing pages do not change.

## 5. The audit

Columns: **phase** (`hint_phase()`), **now** (step / the hint's problem part), **counts** (what the code at acb82b96
counts in that phase), **problems** (codes below), **new step**, **new hint**. Below each table: the why-not banners
(cause -> text). Groups follow the code's base classes; the plan orders the work worst first. Phases with no problem keep their copy ("keep").

Problem codes: **NE** asks for something with no effect; **VG** vague verb; **NT** missing time or countdown; **NC**
target named without its tag colour; **CX** contradicts the code; **PN** names a power; **SI** silent cast (lands on a
target, counts for nothing, no banner).

"(read-only)" marks a new `hint_seconds()`/`step_seconds()` readout a step or hint needs.

### 5.1 Intercept group (Warning base, Festival base, Procession)

**The Warning / Starfall / The Omen / The Long Night** (`warning`, `omen`, `long_night`; WarningDirector,
StarfallDirector). Counts in every running phase: a kill with nobody living within `Crowd.DOOM_WITNESS` (held minds
**do** witness: `Crowd.nearest_witness()`); W1 the carrier outside the walls (Banish); W2 ALL IS WELL when he would be
believed (Calm); W3 a death just outside the gate while the watchman stares. A fright, Discord or whisper only stops him
until he is on his feet again (`RESUMABLE`).

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" / stars | "Kill the messenger unseen"; stars hint packs three routes | kill unseen, banish, calm, W3 | NC, PN ("let the bell lie") | `Kill the messenger (gold) unseen` | stars: "Kill the messenger (gold) unseen (red), banish him, or calm the town. Or kill a man just outside his gate as he stares." |
| running | same step | kill unseen, banish, calm | NC, PN, SI (fright/confuse only delay) | `Kill or banish him (gold) now` | "The messenger (gold) runs for the bellkeeper (blue). Kill him unseen (red), banish him, or calm the town." |
| relay | "Kill the witness unseen" | kill unseen | NC | `Kill the witness (gold) unseen` | keep |
| bell | "Kill the ringer unseen" | kill unseen | NC | `Kill the ringer (gold) unseen` | keep |
| waiting | "Watch the next star's gate" | nothing until the next star; W3 at its stare | VG | `Be at the next gate (gold)` | keep |

`long_night`'s own step becomes `Kill the messenger (gold) unseen`.
Why-not: Scare, Confuse, Lead or Lure landing on the carrier -> `HE STOPS, BUT KEEPS THE WARNING`.

**The Bell-Ringers** (`bell_ringers`; BellRingersDirector, RingerDirector). Unseen = the Warning's rule (held mates
witness). Climbing: pulled off the rope by a whisper or a fright, or a kill unseen. A loud power near a waiting post
sends its ringer at once (consequence, not a why-not; Q8).

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Kill a ringer unseen" | kill unseen | NC | `Kill a ringer (gold) unseen` | keep |
| mates | "Draw his mates off first"; hint "Draw them off" | mates moved beyond `DOOM_WITNESS`, or killed | VG | `Lead or lure his mates (red) off` | "His mates (red) see him die and run on. Lead or lure them off, or kill them first." |
| relay | keep | kill unseen | NC | `Kill the witness (gold) unseen` | keep |
| climbing | "Pull him off the bell" | whisper or fright on the climber; kill unseen | VG, PN ("whisper") | `Lead or scare him off the bell` | "He climbs the bell (gold). Lead or scare him off the rope, or kill him unseen (red), before the bar fills." |
| bell | "Stop the bellkeeper" | the keeper stopped before the toll | VG | `Kill or hold the bellkeeper` | "The town calls its bellkeeper (blue). Kill or hold him, or the bell tolls and the Lantern turns." |
| waiting | "Wait for the next ringer" | nothing until the next post | VG | `Be at the next post (gold)` | keep |
| herald | no line (falls to the default) | the Herald's | -- | (the Lantern's HERALD step already shows) | -- |

Why-not: Confuse on a mate (he stays within sight) -> `CONFUSED, HE STILL SEES - LEAD HIM`.

**Silence the Witness** (`silence_witness`; SilenceWitnessDirector, WitnessDirector). Counts: a witness killed out of his
own mates' sight (a mate who is held does not see: `held_by_god`), or out of the walls.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Kill a witness out of sight" | kill out of the mates' sight, banish | NC | `Kill a witness (gold) unseen` | "A witness (gold) walks to the Temple with two mates (red). Kill him unseen by them, or hold them first." |
| relay | "Stop the mate running on" | kill, banish | VG | `Kill the mate (gold) running on` | "His mate saw it and runs on with the word (gold). Kill him too." |
| near | "Stop him before the Temple" | kill, banish | VG | `Kill the witness (gold) now` | "The witness (gold) nears the Temple. Kill or banish him now." |

Why-not: none new (a seen kill already shows `THE MATE RUNS ON`).

**The Festival / Market Panic** (`festival`, `feast_festival`; `market_panic`; FestivalDirector, MarketPanicDirector).
Festival: a goer breaks by a fright from the god or dies. Market Panic: a warden on guard (`GUARD_MINDS`, at his post)
is fearless and steadies every goer within `WARD_R` (no fright breaks them; a death still counts). A warden leaves guard
killed, led, confused or compelled; a lure counts only if the light is beyond `GUARD_REACH` of his post.

| mission.phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| festival "" | "Kill or scatter the crowd" | kill, scare | VG ("scatter"), NT (the close) | `Kill or scare the crowd (gold)` | "Kill or scare enough of the crowd (gold) before the guard closes the square in {n} s." (read-only: to the close) |
| festival.packed | "Strike the packed crowd" | kill, scare | VG | `Scare the packed crowd (gold)` | keep |
| festival.address | "Kill the Mayor at the fountain" | kill | NC | `Kill the Mayor (orange) now` | keep |
| market_panic "" | "Strike the wardens first" | wardens killed, led, confused, compelled | CX (a blow that does not kill does nothing to a fearless warden), VG | `Kill or lead wardens (red) off` | "Wardens (red) stand fast and steady the crowd (gold). Kill, lead or confuse them, then scare the crowd. 36 must break." |
| steadied | "Remove the last wardens" | as above | VG | `Lead off the last wardens (red)` | "A warden (red) still steadies the crowd near him. Kill, lead or confuse him; no fright breaks them there." |
| open | "Scatter the crowd" | kill, scare | VG | `Scare the crowd (gold) now` | keep |
| coming | "Strike the crowd on the way" | kill, scare away from wardens | VG | `Scare them (gold) on the way` | "More come to the fair (gold). Scare them on the way, away from the wardens (red), or when they arrive." |

Why-not: Scare landing only on steadied goers -> `A WARDEN (RED) STEADIES THEM`; Scare or Lure (light within
`GUARD_REACH`) on a warden on guard -> `THE WARDEN STANDS FAST`; Lead, Lure or Confuse on goers (Festival and Market) ->
`ONLY FEAR OR DEATH BREAKS THEM`.

**The Procession** (`procession`, `feast_procession`; ProcessionDirector). Counts: his death (judged seen/unseen); a
fright only halts the walk.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Kill the Prince before he boards" | kill | NC | `Kill the Prince (gold)` | keep |
| blessing | "Strike the Prince at the steps" | kill | VG, NT | `Kill him (gold) at the steps` + s (read-only: blessing left) | "The Prince (gold) holds at the cathedral steps for {n} s. Kill him while he stands still." |
| dock | "Kill him before he boards" | kill | NT | `Kill him (gold) before he boards` + s (read-only: to boarding) | "The Prince (gold) boards in {n} s, as soon as his ship is in. Kill him first." |

Why-not: Scare, Lead, Confuse or Lure on the Prince -> `THAT ONLY HALTS HIM - KILL HIM`.

### 5.2 Assassinate group (AssassinateDirector base)

**The Informer** (`informer`). See §1.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| waiting | "Draw his company away"; hint "Get his company (red) away before it does" | **nothing**; word on a timer; company walked back every `TICK` | NE, CX, NT, SI | `Word reaches him (grey) in` + s (read-only: `visit_in()`) | "Word reaches the contact (grey) in {n} s. Nothing turns him before then; his company (red) walks back to him." |
| "" | "Turn the contact unseen"; hint "Whisper or Discord" | Lead (whisper) or Confuse (discord) on him, no unheld onlooker within 2.0 | VG, NC, PN, SI (lure, scare, banish) | `Confuse the contact (orange)` | "Confuse the contact (orange) and his company (red) together, or lead him with none of them near. Do not kill a contact." |
| found / running | "Kill him before the Temple" | kill | NC | `Kill the informer (gold)` | keep |
| hiding | "Smoke him out: burn the house" | the house he hides in alight or down flushes him | NC | `Burn his hiding place (gold)` | "Alarmed, he hides (gold). Burn the house: the fire drives him out. Or wait for him." |

Why-not: any cast within reach of the contact or his company in `waiting` -> `TOO EARLY - NO WORD YET`; a Banish, Lure
or Hold (not lead/confuse) on the company after word -> `THEY WALK BACK TO HIS DOOR`; a cast on the contact after word
whose key is not whisper or discord -> `ONLY CONFUSE OR LEAD TURNS HIM`. (`SEEN - HE SAYS NOTHING` stays.)

**The Tax Collector** (`tax_collector`). Counts: kill (seen calls the bell), Banish (`walls_stop`), the counting-house
alight or down flushes every collector inside to the Citadel; a cast by its door while none is out smokes the next out;
Seal on a door he went in at, with no guard of his within `MOB_GUARD_R`, sets the debtors on him (`MOB_AFTER`).

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Stop the tax collector" | kill, banish | VG, NC | `Kill the collector (gold)` | "Kill each collector (gold) on his round, unseen (red) if you can: a seen kill rings the bell. Or banish him." |
| inside | "Seal his door, draw guards off"; hint names Leaving Is Prohibited | nothing reaches him for `visit_seconds` but Seal (one power) and fire on the house | NE (for every loadout without Seal), VG, PN, NT | `Ambush him at the door (orange)` + s (read-only: his visit left) | "He is in a debtor's house (orange) for {n} s. Be at the door. Seal it with his guards (blue) away: the debtors mob him." |
| hiding | "Burn the counting-house" | fire on it flushes all | NC | `Burn the counting-house (orange)` | "Alarmed, he hides in the counting-house (orange). Burn it: everyone inside runs for the Citadel (red)." |
| running / safe | keep | kill | -- | keep | keep |
| next | "Be ready for the next collector" | nothing until he sets out | NT, NC | `Ambush the next collector` + s (read-only: to set-out) | "One down. The next collector (gold) leaves the counting-house (orange) in {n} s." |

Why-not: Kill/Scare/Hold cast on a collector indoors whose house is neither alight nor down -> `HE IS INDOORS - WAIT AT THE
DOOR`; Seal not centred on a door he went in at -> `SEAL A DOOR HE WENT IN AT`; Seal holding him with a guard near ->
`HIS GUARD (BLUE) STOPS THE MOB`.

**The Bishop** (`bishop`). Knights on guard: alive, out of doors, within `GUARD_REACH`, not `held_by_god()`; they beat out
fire and turn blows aside. Burn each refuge with no Knight on guard; the Temple last; then kill him in the square.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | keep | burn unguarded refuge | NC | `Burn the bishop's refuge (gold)` | keep |
| waiting | "Kill the Knights before he comes" | Knights killed or held | VG (hold omitted) | `Kill or hold its Knights (red)` + s | "He reaches his next refuge in {n} s. Kill or hold its Knights (red) shortly before he comes." |
| guarded | "Kill the refuge's Knights"; hint names Discord | kill, hold | PN | `Kill or hold its Knights (red)` | "His Knights (red) beat out fire and turn blows aside. Kill or hold them: a held Knight walks back after." |
| open | "Set the refuge alight" | burn | NC | `Burn the refuge (gold) now` | keep |
| burning | keep | -- | -- | keep | keep |
| square / running | "Kill him before the Citadel" | kill | NC | `Kill the bishop (gold)` | keep |

Why-not: Burn or Strike on a refuge with a Knight on guard -> `HIS KNIGHTS (RED) BEAT IT OUT`.

**Expel the Inquisitor** (`expel_inquisitor`). Counts: a warden dead or out of the walls (a fright only sends him to hide
`EI_HIDE`); the captain dead, out of the walls, or frightened three times, one count per `EI_FRIGHT_GAP` (8 s).

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Stop a lantern-warden" | kill, banish | VG, NC | `Kill or banish a warden (gold)` | "Kill or banish each lantern-warden (gold). A fright only sends a warden to hide." |
| captain | keep | kill, banish, 3 frights 8 s apart | NC | `Kill or scare the captain (gold)` | "The captain (gold) walks his rounds. Kill him, or scare him three times, each 8 s or more apart." |
| near | "Stop him before the Citadel" | kill, banish | VG | `Kill the captain (gold) now` | "The captain (gold) nears the Citadel (red). Kill or banish him now." |

Why-not: Scare on a warden -> `A WARDEN ONLY HIDES - KILL HIM`; Scare on the captain within 8 s of the last count ->
`STILL SHAKEN - SCARE HIM AGAIN SOON`.

### 5.3 Escort group (EscortDirector base)

Shared rule: a watcher sees nothing while `held_by_god()`, frightened, indoors or of a corps; a seizer lets go the moment
he is off `DUTY` (killed, held, frightened). Hold is true here.

**The Lost Lamb** (`lost_lamb`). Counts: Lead (whisper) or Lure (a source within `CHARGE_LURE_R`); a startle within
`BOLT_REACH` (6) or `BOLT_AT` (1:00) makes him bolt for the gate unless led first.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Get the acolyte to the gate" | lead, lure, scare (bolt) | VG, NT (1:00) | `Lead or scare the acolyte (blue)` + s (read-only: to `BOLT_AT`) | "Lead or lure the acolyte (blue) to the west gate, or scare him: he bolts for it. At {n} s he bolts alone." |
| running | "Clear his road to the gate" | soldiers held, scared or killed | VG | `Hold the soldiers (red) ahead` | "He runs for the west gate. Hold, scare or kill the patrols and the watch (red) ahead of him." |
| led | "Lure him on to the west gate" | lead, lure | (lead omitted), PN | `Lead or lure him west (blue)` | "He holds where you left him. Lead or lure him on toward the west gate; soldiers (red) seize him on sight." |
| caught | "Stop the soldier taking him"; hint "Discord the soldier" | captor off duty: hold, scare, kill | VG, PN | `Hold or kill his captor (red)` | "He is caught. Hold, scare or kill the soldier taking him (red) before the Temple." |
| gate | "Draw the watch off the gate" | watch held or away; the change (read-only countdown) | VG, NT | `Hold the gate's watch (red)` + s (read-only: to the watch change) | "The watch (red) holds the gate. It changes in {n} s: bring him close, or hold the watch." |
| clear | "Send him through the gate" | lead | VG | `Lead him through the gate now` | keep |

Why-not: Lead or Lure on him while held -> `HE IS HELD - FREE HIM FIRST`; a Lure whose source is beyond `CHARGE_LURE_R`
of him -> `TOO FAR - HE ANSWERS A NEAR LIGHT`.

**The Prisoner** (`prisoner`). Bound: deaf, past fear, seen by no one; her two gaolers are lay watchmen held past fear,
so only kill, lead or confuse moves them; a blow or fire bringing the stocks down frees her. Free: as the Lamb, no bolt.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Lead her to the postern" | lead, lure | PN, NC | `Lead her (blue) to the postern` | "Lead or lure her (blue) toward the postern, and again before she stops. Watchmen (red) seize her on sight." |
| bound | "Remove both gaolers" | gaolers killed, led or confused, then stocks struck or burnt | VG | `Kill or lead both gaolers (red)` | "Kill, lead or confuse both gaolers (red), then burn the stocks (orange) or strike their far side." |
| caught | "Stop the man taking her back" | captor off duty | VG, PN | `Hold or kill her captor (red)` | "She is caught. Hold, scare or kill the man taking her (red), or strike once she is clear of him." |
| hounds | "Turn the hounds from her" | hold, scare, kill | VG | `Hold or kill the hounds (red)` | "The Citadel's hounds (red) follow her. Hold, scare or kill them before they see her." |
| gate | "Draw the watch off the postern" | as Lamb | VG, NT | `Hold the postern's watch (red)` + s | "The watch (red) holds the postern. It changes in {n} s: bring her close, or hold the watch." |
| clear | "Send her through the postern" | lead | VG | `Lead her through the postern` | keep |

Why-not: Scare on a gaoler while she is bound -> `PAST FEAR WHILE SHE IS BOUND`; Lead or Lure on her while bound ->
`BOUND - SHE CANNOT HEAR YOU`.

**Exodus** (`exodus`). Lead the lamp; the household follows. Watchers seize unless held, frightened or indoors.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Lead the household to a gate" | lead (the lamp); B route oath | PN, NC | `Lead each lamp (blue) to a gate` | "Lead each lamp (blue) to an open gate: the rest follow. Hold or kill Inquisitors (red) in the way. Ten must get out." |
| caught | hint names Discord | captor off duty | VG, PN | `Hold or kill his captor (red)` | "A believer is taken to the Temple. Hold, scare or kill the man taking him (red)." |
| hounds | "Turn the searchers away" | hold, scare, kill | VG | `Hold or kill the searchers (red)` | "The Temple's searchers (red) follow the household. Hold, scare or kill them before they see it." |
| gate | "Draw the Inquisitors off" | hold, scare, kill | VG, PN | `Hold the gate's watch (red)` | "Inquisitors (red) watch the gate. Hold, scare or kill them, then lead the household through." |
| shut | keep | lead | -- | `Lead them to an open gate` | keep |
| waiting | "Clear the next road" | watchers on the next road | VG | `Hold the next road's watch (red)` + s | keep |

Why-not: Lead on a household member who is not the lamp -> `LEAD THE LAMP (BLUE) - THEY FOLLOW` (only if the code shows
a non-lamp whisper is ignored; else none).

**Hide the Faithful** (`hide_faithful`). The households walk themselves. The watch is soldiers; the searchers lay
inquisitors (Seal holds one still: `law_held()`).

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Clear the watch from their road" | watch held, scared, killed | VG | `Hold or kill the watch (red)` | "Your believers (blue) walk out by themselves. Hold, scare or kill the watch (red) on their road to the gate." |
| trail | "Keep searchers off the household" | searchers held, scared, killed, sealed | VG | `Hold or kill the searchers (red)` | "The Inquisition found the trail. Hold, scare or kill its searchers (red) before they see the household." |
| seized | "Stop the man seizing him" | seizer off duty | VG | `Hold or kill his seizer (red)` | "A believer is seized. Hold, scare or kill his seizer (red) before he reaches the Temple." |

Why-not: Lead on a believer -> `THEY WALK BY THEMSELVES` (only if the code ignores it).

**Face Halcyon** (`face_halcyon`). A believer is freed when fewer than `FH_ESCORT_HOLD` of his escort are able (alive,
out of doors, with the procession, not held, not frail, not afraid). A seen death adds to the Gaze.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Break a believer's escort" | escorts held, scared, killed | VG, NC | `Hold or scare his escort (red)` | "Hold or scare a believer's escort (red) until too few stand: he runs free. A seen death feeds the Gaze." |
| pyre | "Break his escort at the pyre" | as above, before `FH_BURN` | VG, NT | `Hold the pyre's escort (red)` + s (read-only: burn left) | "A believer burns at the pyre in {n} s. Hold or scare his escort (red) now." |
| gaze | "Free them quietly" | as above, without seen deaths | VG | `Hold or scare, do not kill` | "Halcyon's Gaze is filling. Hold or scare the escorts (red); every seen death fills it more." |

Why-not: Hold/Scare on one escort while enough others stay able -> `STILL GUARDED - n MORE TO HOLD` (n read from the
escort count); Lead on a bound believer -> `BOUND - HE CANNOT HEAR YOU`.

### 5.4 Raze group (RazeDirector base, Last Judgement)

**Spoiled Harvest** (`spoiled_harvest`). A watchman on guard: alive, out of doors, in `GUARD_MINDS` (calm, recover,
**observe**, duty) within `GUARD_REACH` -> a lured man near the granary still guards. Fire on an empty granary is put
out and counts nothing. Burn 10 s or bring it down; Rot (unguarded, grain in); the carter banished, sickened, seized by
CALL THE GUARD, sealed `HELD_SPOIL` s, or frightened while carrying. Killing the carter never spoils.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Clear the watchmen, burn it" | watchmen removed, then burn or rot | VG, NC | `Scare its watchmen, then burn` | "Scare, lead, confuse or kill a granary's watchmen (red), then burn or rot it (gold). Or banish its carter (blue)." |
| empty | "Wait for the grain cart" + s | nothing on the granary until grain is in | VG | `Scare its watch before the grain` + s | "No grain yet: fire there is put out. The grain comes in {n} s: clear its watchmen (red) just before." |
| watchman | "Clear the watchman at the fire" | as "" | VG, PN | `Scare the watchman (red) off` | "A watchman (red) beats the fire out in 3 s. Scare, lead, confuse or kill every one first." |
| burning | keep | -- | -- | keep | keep |

Why-not: Burn or Rot on a granary with no grain -> `NO GRAIN YET - THE FIRE GOES OUT`; Burn with a watchman on guard ->
`A WATCHMAN (RED) PUTS IT OUT`; Lure with its light within `GUARD_REACH` of the granary -> `LURED, HE STILL WATCHES IT`;
Kill on a carter -> `KILLING THE CARTER SPOILS NOTHING`.

**The Crown's Bread** (`crowns_bread`). Engineers on guard as Harvest's watchmen. A target counts only in use; a fall
before its time counts only if still down then; the bridge takes blows, not fire.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Wait, then clear the engineers" + s | nothing until near its time | VG | `Be at the next target (grey)` + s | keep |
| not_yet | "Clear the engineers now" | engineers removed | VG | `Kill or lead its engineers (red)` + s | "Not in use yet (grey). Kill, lead, confuse or scare its engineers (red) just before; a fall counts if it stays down." |
| engineers | "Remove every engineer" | as above | VG | `Kill or lead its engineers (red)` | "Engineers (red) mend it and put out its fires. Kill, lead, confuse or scare every one first." |
| open | "Bring it down now" | burn or strike; the bridge strike only | VG | `Burn or strike it (gold) down` | "No engineer stands. Burn or strike it (gold) down now. The bridge takes blows, not fire." |

Why-not: Burn on the bridge -> `STONE - STRIKE IT, FIRE DOES NOTHING`; Burn/Strike with an engineer on guard ->
`AN ENGINEER (RED) MENDS IT`; Lure within `GUARD_REACH` -> `LURED, HE STILL MENDS IT`.

**The Armoury** (`armoury`). No harm before the horn (mustering); armed men on guard unless `OFF_GUARD` or held; the gate
barracks is stone.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Wait for the horn" + s | nothing | VG | `Be at the next target (grey)` + s | keep |
| not_yet | "Kill its night watch" | kill, hold | VG (hold omitted) | `Kill or hold its watch (red)` + s | "Not mustering yet (grey): it takes no harm. Kill or hold its night watch (red) just before its horn, in {n} s." |
| guarded | "Kill its armed men"; hint names Discord | kill, hold | PN | `Kill or hold its armed men (red)` | "Armed men (red) guard it: it takes no harm. Kill or hold them: a held man walks back after." |
| stone | "Strike the barracks, no fire" | strike | NC | `Strike the barracks (gold)` | "The gate barracks (gold) is stone: strike it, fire does nothing." |
| open | "Destroy it now" | burn, strike | VG | `Burn or strike it (gold) down` | keep |

Why-not: Burn/Strike before the horn -> `NOT MUSTERING - IT TAKES NO HARM`; with a guard on guard -> `ARMED MEN (RED) GUARD
IT`; Burn on the stone barracks -> `STONE - STRIKE IT, FIRE DOES NOTHING`.

**The Heart of Faith** (`heart_of_faith`). Knights as the Bishop's (`held_by_god` frees a post). Before its time a
target's fire goes out. Odran: hidden in the litter while two bearers live; at the steps on foot his rekindling restarts
on a whisper, Discord or a fright; his death wins once the flame is out.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Kill the Knights, then burn" | kill/hold Knights, burn | NC, VG | `Kill the Knights (red), burn it` | keep |
| not_yet | "Kill its Knights first" + s | kill, hold | VG | `Kill or hold its Knights (red)` + s | keep |
| guarded | hint names Discord | kill, hold | PN | `Kill or hold its Knights (red)` | "Lantern Knights (red) guard it: it takes no harm. Kill or hold them." |
| open | "Set it alight" | burn | NC | `Burn it (gold) now` | keep |
| coming / litter | "Kill Odran's bearers" | kill bearers | NC | `Kill Odran's bearers (red)` | keep |
| on_foot | keep | kill | NC | `Kill Odran (gold) on the steps` | keep |
| rite | "Kill Odran now"; hint "whisper him off" | kill; lead, confuse, scare restart it | PN | `Kill or scare Odran (gold) now` + s | "Odran (gold) rekindles the flame in {n} s. Kill him, or scare, lead or confuse him to start it again." |

Why-not: Burn before its time -> `NOT IN USE - THE FIRE GOES OUT`; Burn/Strike with a Knight on guard -> `A KNIGHT (RED)
PUTS IT OUT`; any cast on Odran in his litter -> `IN HIS LITTER - KILL HIS BEARERS`.

**Last Judgement / Judgement** (`last_judgement`, `judgement`). Counts: the Citadel destroyed; the rite broken when fewer
than `BanishingRite.HOLD` clergy stay in the ring (killed or frightened) or the cathedral drops under `MIN_HP`; after the
fall, stability (kills, ruin) and the escape count.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Bring the Citadel down" | strike, burn | VG, NC | `Strike the Citadel (gold) down` | keep |
| rite | "Break the Banishing Rite" | clergy killed or scared; cathedral struck | VG | `Kill or scare the clergy (red)` | "The clergy (red) chant the Banishing Rite. Kill or scare them off the steps, or strike the cathedral, or it cuts your time." |
| fallen | "Break the city's stability" | kills and ruin; escapes lose | VG | `Kill and burn: break stability` | keep |

Why-not: none.

### 5.5 Hunt group (HuntDirector base)

Shared rule: a guard guards while alive, out of doors, **not `BLIND`** (whispered or confused) and within `guard_reach`
-> a compelled or lured guard near the standard still guards. Hold is **not** true here.

**The Heretic Hunt** (`heretic_hunt`).

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" / guarded | "Clear a standard's guards" | guards killed, led, confused or lured far | VG | `Kill or lead its guards (red)` | guarded: "Its guards (red) hold the standard: blows only shake it. Kill, lead or confuse every one." |
| open | "Break the standard"; hint "blow or Blight" | strike, rot | VG, PN | `Strike or rot it (gold) now` | "The standard (gold) stands unguarded. Strike or rot it now, before a new guard comes." |
| waiting | "Clear the next guards" + s | -- | VG | `Be at the next standard (grey)` + s | keep |
| coming | "Be ready for the captain" + s | -- | NC | `Be on the captain's road` + s | keep |
| captain | "Kill the captain" | kill | NC | `Kill the captain (gold)` | keep |
| searching | "Kill him before the cellar" | kill | NC | `Kill the captain (gold) now` | keep |

Why-not: Strike on a guarded standard -> `GUARDED (RED) - IT ONLY SHAKES` (Rot keeps `THEIR GUARD KEEPS IT`); Lure
or a compel on a guard within reach -> `HELD, HE STILL GUARDS - LEAD HIM OFF`.

**The Lantern's Eye** (`lantern_eye`). Guards as above; an unguarded mirror takes two blows or one Blight (a Heaven
Splitter is one blow); shattered, its wrights (working unless `BLIND` or away) rehang it unless stopped for `DRAIN` s.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" / guarded | "Clear a mirror's guards" | as Heretic Hunt | VG | `Kill or lead its guards (red)` | guarded: "Its guards (red) hold the mirror: blows only shake the tower. Kill, lead or confuse every one." |
| open | "Shatter the mirror"; hint "Two blows or one Blight" | strike x2, rot | VG, PN | `Strike or rot the mirror (gold)` | "The mirror (gold) stands unguarded. Strike it twice or rot it once, where no beam shines." |
| shattered | "Keep it shattered" + s | wrights killed, led, confused | VG | `Lead or kill the wrights (red)` + s | "Its wrights (red) hang a new glass. Kill, lead or confuse them for {n} s and it is gone for good." |
| waiting | "Clear the next mirror's guards" | -- | VG | `Be at the next mirror (grey)` | keep |
| eye | "Shatter a mirror now" + s | strike, rot | VG | `Strike or rot a mirror now` + s | keep |

Why-not: as the Heretic Hunt; Lure on a wright within `WRIGHT_REACH` -> `HELD, HE STILL WORKS - LEAD HIM OFF`.

**Break the Hunt** (`break_hunt`). A bearer killed or frightened while no escort guards him breaks the standard; killed
while guarded, the escort takes it up; frightened while guarded, it only shakes him. An escort guards while alive,
out of doors, within `guard_reach`, not held, not fighting, not frail, not afraid. Banish breaks it.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Strike a bearer, no escort near" | kill/scare/banish a bearer alone | VG ("strike" a person), NC | `Kill or scare a bearer (gold)` | "Standards (gold) march on your houses (blue). Kill or scare a bearer when no escort (red) guards him: hold them first." |
| carried | "Strike the new bearer" | as above | VG | `Kill or scare the new bearer` | "An escort took up the standard (gold). Kill or scare him too, with no escort by him." |
| taken | "Do not lose another house" | as above | NE (no action) | `Kill or scare a bearer (gold)` | "A house is taken: one more and the hunt has won. Kill or scare a lone bearer (gold)." |

Why-not: Scare on a guarded bearer -> `HIS ESCORT (RED) STEADIES HIM`; Kill on a guarded bearer -> `AN ESCORT TAKES THE
STANDARD UP` (if no banner exists already).

### 5.6 Convert and rite group (MirasHouseDirector, VigilFlameDirector, Broken Lanterns, RiteDirector)

Shared rule: a Faithful sees while alive, out of doors, **not `BLIND`** (`MissionDirector._sees()`) -> only Lead or
Confuse blinds one.

**First Prayers** (`first_prayers`). The poor walk to the well by themselves (`POOR_OUT_AT` 80/170/240 s, `POOR_CHAIN`
50 s); a whispered or lured poor man at the door goes in too; a Wisp at the shrine fetches from `FETCH_R`. Faithful at
the door: fire within `FIRE_PULL` (7) pulls them off; ALL IS WELL stands them down; brambles hide the door; with none
left alive, all hurry in.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Wait for a believer to pray" | lead, lure (fetch), the walkers; door unwatched | VG, NT, NC | `Lead the poor (gold) to the well` | "Lead or lure the poor (gold) to the well (orange), or let them walk: the next sets out in {n} s. Three must pray unseen." |
| watched | "Draw the Faithful off the door"; hint names ALL IS WELL, brambles | burn near, calm, lead/confuse/kill Faithful, brambles | VG, PN | `Lead the Faithful (red) away` | "Faithful (red) watch the well. Burn a house by it, calm the town, or lead, confuse or kill them." |

Why-not: Lead or Lure on a poor man while the door is watched -> `WATCHED - HE WILL BE TURNED AWAY`; Lead or Lure on a
citizen who is not of the poor to the door -> `ONLY THE POOR (GOLD) PRAY HERE`; Burn on a house beyond `FIRE_PULL` of the
door -> `TOO FAR TO PULL THE FAITHFUL`; Hold (compel or lure) on a Faithful by the door -> `HELD, HE STILL SEES - CONFUSE
HIM`.

**Mira's House** (`miras_house`). Lead (whisper to any face) or Lure (light by the house); turned away and reported if a
Faithful sees.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Whisper a mourner to her door" | lead, lure the grieving | PN, NC | `Lead the grieving (gold) to Mira` | "Lead or lure a grieving (gold) to Mira's door (orange) while no Faithful (red) sees. Four must believe by dawn." |
| four | keep | -- | -- | keep | keep |
| burning | "Keep your believers alive" | -- | NC | `Keep believers (orange) alive` | keep |

Why-not: as First Prayers (`WATCHED - SHE WILL BE TURNED AWAY`, `ONLY THE GRIEVING (GOLD) GO IN`).

**The Sermon** (`sermon`). The preacher silenced while held (whisper, Discord, fright) or dead (unseen by his unheld
acolytes); rapt listeners are deaf (refusal "THEY HEAR ONLY HIM" exists); the door's sentries are Faithful (`BLIND`).

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Whisper the crowd to your door" | lead | PN, NC | `Lead a listener (gold) in` | "Silence the preacher (red), then lead his crowd (gold) to the god's house (orange) unseen. Eight must believe: kill none." |
| rapt | "Get the preacher aside"; hint names Discord | preacher led, confused, scared, or killed unseen | VG, PN | `Confuse or scare the preacher` | "He preaches: his crowd hears only him. Lead, confuse or scare him; kill him only unseen by his acolytes." |
| coming | "Whisper the latecomers in" | lead | PN | `Lead the latecomers (gold) in` | "More come to hear him (gold). Lead them on the way, before they come within his voice. Do not kill them." |
| watched | "Draw the sentries off the door" | sentries led, confused, killed | VG | `Lead or confuse the sentries` | "Sentries (red) watch the door: anyone seen going in is turned away. Lead, confuse or kill them first." |
| report | "Stop the runner unseen" | kill unseen | VG, NC | `Kill the runner (red) unseen` | keep |
| seen | keep | -- | -- | keep | keep |
| bell | "Stop the bellkeeper unseen" | kill unseen | VG, NC | `Kill the bellkeeper (red) unseen` | keep |

Why-not: Lure or a compel on a sentry by the door -> `HELD, HE STILL SEES - CONFUSE HIM`.

**The Vigil Flame** (`vigil_flame`). Wren comes at 0:50 (`WREN_AT`); whispered within `SWAP_REACH` of the lantern he
swaps it; a Faithful other than the bearer within `DOOM_WITNESS` who is not held sees it. At 1:30 the Vigil turns home
if unswapped. Carry: Wren walks to Mira's shrine under the Searchlight.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Draw the acolytes off the flame" | nothing to swap yet; acolytes held or away when he comes | VG, NT | `Hold the acolytes (red) for Wren` + s (read-only: to `WREN_AT`) | "Wren (blue) comes for the flame (gold) in {n} s. Its acolytes (red) would see him: hold them or lead them off first." |
| wren | "Lead Wren to the flame"; hint "Whisper or lure" | lead (lure: Task verifies) | PN | `Lead Wren (blue) to the flame` | "Lead Wren (blue) to the flame (gold) while no Faithful but its bearer is near him (red)." |
| homeward | "Swap the flame before the Temple" | as wren | VG | `Lead Wren (blue) to the flame` | keep |
| carry | "Walk Wren to Mira's shrine" | lead | VG | `Lead Wren to the shrine (orange)` | "Lead Wren to Mira's shrine (orange), west past the wall. Keep him out of the searchlight." |

Why-not: Lead on Wren while an unheld Faithful is within sight -> `AN ACOLYTE (RED) WOULD SEE`; Lead on anyone else to the
lantern -> `ONLY WREN (BLUE) CAN TAKE IT`.

**The Relic Run** (`relic_run`). Pip holds where a whisper leaves him; unwatched by the halted cart `BOARD` s he boards;
watched while a Faithful not held stands within `WATCH`; a Wisp draws the watch only once Pip is led by light or oath
(`PIP FOLLOWS THE GOD` banner).

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Bring Pip to the first halt" | lead | VG, NC | `Lead Pip (blue) to the halt` | "Lead Pip (blue) to the cart's first halt (orange). He slips aboard there and swaps the relic at the next." |
| moving | "Clear the next halt's wardens" | wardens held or away | VG | `Hold the next halt's watch (red)` | keep |
| watched | "Remove the watch at the halt"; hint "Once light or oath leads Pip, a Wisp draws the watch too" | watch held, killed | VG, PN | `Hold or kill the watch (red)` | "The watch (red) sees the cart. Hold or kill them: Pip works unseen. A lure draws them only once Pip follows you." |
| aboard | "Clear the watch for the swap" | as watched | VG | `Hold the watch at the next halt` | keep |
| carry | "Walk Pip home, out of light" | lead | VG, NC | `Lead Pip home (orange), unlit` | keep |
| last_halt | "Bring Pip to the last halt" | lead | VG | `Lead Pip (blue) to the last halt` | keep |
| citadel | "The cart makes for the Citadel" | nothing found (dead end) | NE | Task decides by test: `Kill the cart's three hands` if a stood cart lets Pip board, else `The relic is lost at the Citadel` (Q6) | keep |
| report | "Stop the runner unseen" | kill unseen | VG | `Kill the runner (red) unseen` | keep |
| seen / bell | keep / "Stop the bellkeeper unseen" | kill unseen | VG | keep / `Kill the bellkeeper (red) unseen` | keep |

Why-not: Lure on the watch before Pip follows -> `NO LURE YET - PIP MUST FOLLOW YOU`.

**Broken Lanterns** (`broken_lanterns`). A lantern is guarded while **any living Knight stands within `GUARD_REACH`**,
whatever his mind: only kill, Lead or Lure away moves the guard. A broken lantern drains 20 s unless the flame-bearer
reaches it.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| "" | "Break and drain a lantern" | strike/burn, then keep the bearer off | VG ("drain"), NC | `Strike a lantern (gold) down` | "Strike a lantern (gold) down, then keep the flame-bearer (gold) off it 20 s while it drains. Drain all six." |
| knights | "Draw off the lantern's Knight" | Knight killed, or led or lured beyond reach | VG | `Lead or kill its Knight (blue)` | "A Knight (blue) shields the lantern he stands by, held or not. Kill him, or lead or lure him away, then strike." |

Why-not: Confuse or a compel on a Knight within reach -> `HE STILL STANDS BY IT - LEAD HIM OFF`; Strike on a guarded
lantern -> `A KNIGHT (BLUE) SHIELDS IT` (if no banner exists). Task 4 confirms how the bearer is kept off and words "keep
the flame-bearer off" as verbs it proves.

**The First Taste** (`first_taste`). Chain (C) a lamplighter; a breaker grips unless held, frightened, Death-Marked,
sealed or Yank-stunned; a march stops for good when all but one marcher is killed or frightened (a held marcher only
loses time); two kneelers 12 s cleanse.

| phase | now | counts | problems | new step | new hint |
|---|---|---|---|---|---|
| chain ("") | keep | C on a marked lamplighter | -- | keep | keep |
| drag | "Keep the Watch off him" | breakers held, scared, sealed | VG | `Hold or scare the Watch (red)` | "Hold or scare the Watch (red) off him. Press C again to yank him on once." |
| march | "Stop the marching clergy" | marchers killed or scared | VG | `Kill or scare the marchers (red)` | "The clergy (red) march on the shrine: kill or scare all but one, or win first." |
| cleanse | "Strike a kneeler now" | kill or scare a kneeler | VG | `Kill or scare a kneeler (red)` | keep |

Why-not: Hold on a marcher -> `HELD, HE ONLY LOSES TIME`.

### 5.7 Totals

Problems found over 135 phase rows in 30 missions (35 step ids with their acts and feasts) (a code counted once per row; 8 rows have none):

| code | kind | count |
|---|---|---|
| VG | vague verb | 87 |
| NC | target without its tag colour | 43 |
| PN | names a power | 26 |
| NT | missing time or countdown | 12 |
| NE | asks for something with no effect | 4 |
| CX | contradicts the code | 2 |
| SI | silent cast | 3 rows flagged in the tables; 46 why-not causes in all (each a silent cast today) |

The five worst (most confusing first):

1. **The Informer, `waiting`** -- the step asks the player to draw the company away; nothing counts before word, the
   company walks back every half second, no countdown, no banner (NE, CX, NT, SI). The user's report.
2. **First Prayers, default** -- "Wait for a believer to pray" while the night needs the poor led to the well and the door
   kept clear; no countdown to the next walker (VG, NT).
3. **The Tax Collector, `inside`** -- the only step while he is indoors names one Decree power; every other loadout is
   told to do something it cannot, with no countdown to his coming out (NE, PN, NT).
4. **Market Panic, default** -- "Strike the wardens first": a warden on guard is fearless, so a blow that does not kill does
   nothing, and a lure near his post does nothing; frights on steadied goers are silent (CX, VG, SI).
5. **Broken Lanterns, `knights`** -- "Draw off the lantern's Knight": a confused or compelled Knight still shields it
   (distance alone), silently; the same trap in the Hunts' guards and wrights (VG, SI).

## 6. Shared design

### 6.1 The why-not hook

- `MissionDirector.why_not(key: String, at: Vector2) -> String` -- virtual, "" by default. Returns the banner for a cast of
  `key` at `at` that reaches one of this director's targets in the current phase and will not count; "" when it counts,
  or reaches none of them. **Only reads**: no rng, no state, no signal, no timeline. It reads state after the director's
  own cast handlers ran.
- `MissionDirector._cast_reaches(key: String, at: Vector2, g: Vector2) -> bool` -- `at.distance_to(g) <=
  Crowd._cast_radius(key) + WHY_MARGIN`; `const WHY_MARGIN := 1.0`. Every `why_not()` gates on it, so a cast far from
  every target says nothing.
- `MissionDirector.hint_phases() -> PackedStringArray` -- virtual, `[""]` by default: every phase `hint_phase()` can
  return. Read-only; used by the key-resolution test (§6.4).
- `WhyNotGate` (`src/game/ui/why_not_gate.gd`, RefCounted): `const REPEAT := 30.0`, `const GAP := 4.0`; `allow(text:
  String, now: float) -> bool` -- false for "", for the same text within `REPEAT` s, or for any why-not within `GAP` s of
  the last one shown.
- `Hud`: connects `Rules.cast_made` in `setup()` (after the director, which connected in its own set-up, so it reads the
  state after the cast was judged); handler `_on_cast_why(slot, key, at)` asks `_rules.director.why_not(key, at)`, then
  `_why.allow(text, _why_clock)`, then `push_banner(text, true)` (quiet: no sting, no buzz). `_why_clock` advances in
  `_process` by real delta. Free play shows none.
- A `why_not` reads `Rules.loadout` nowhere; it judges the key cast.

### 6.2 The verb vocabulary -- §3.

### 6.3 The legend page -- §4.

### 6.4 Tests

1. **Vocabulary** (`tests/test_mission_verbs.gd`): twelve verbs in table order; every key exists in `PowerBook.POWERS`;
   Burn equals `FAMILY` fire, Strike `FAMILY` strike; Scare equals the non-quiet keys; a source scan of each power's fx
   script (`PowerBook.get_power(key).path`) proves Lead = the `.whisper(` callers, Confuse = `.confuse(`, Lure = `.lure(`,
   Hold = the union of `.whisper(`/`.confuse(`/`.compel(`/`.lure(` callers, Banish = `.fold(` callers; `named_in()` finds
   "Kill or lead its guards (red)" -> [kill, lead] and nothing in "Keep it burning"; `legend_rows()` puts equipped first.
2. **Legend** (`tests/test_legend.gd`): three pages, H cycles 1-2-3-close, "n / 3"; page 3's rows fit the panel at
   640x360 and 960x495; equipped names first.
3. **Hook and gate** (`tests/test_why_not.gd`): the base returns ""; `WhyNotGate` repeat and gap; a stub director whose
   `why_not()` returns a text puts one quiet banner on the HUD per cause per 30 s; `""` puts none.
4. **Read-only** (`ClarityKit.assert_read_only`): in a mission's Kit world, every person's position, mind and `inside`,
   the director's `report()`, `hint_phase()`, `tags()` labels and `Rules.banner` emissions are identical before and after
   `why_not(key, g)` for one key per verb at every tag point.
5. **Per mission** (one file per group task): for every (mission, phase, verb) a step or hint of that phase names, a
   Kit-world case sets the phase, applies one power of that verb to the target as the power lands
   (`ClarityKit.apply()`), emits `cast_made`, steps the world and asserts the director's own progress (the n/m moves,
   the phase leaves, the guard count drops). For every why-not cause, a case asserts `why_not(key, at)` returns its
   text, and that the same cast far away returns "".
6. **Coverage** (`ClarityKit.check_coverage(t, ids, cases)`, per group): every verb `MissionVerbs.named_in()` finds in a
   step or hint of the group's missions has a case; every step fits `MAX_LABEL`; every colour word a step or hint names
   is the colour of a tag `tags()` draws in that phase's case.
7. **Keys resolve** (`tests/test_mission_steps.gd`, `_resolve`): every `"ph"` of every step and every `"<id>.<phase>"` of
   `MissionHints.LINES` is in that mission's director's `hint_phases()`; every phase in `hint_phases()` has a step (named
   or default). The existing `test_mission_hints.gd` SPEC table carries the new lines word for word.

The references: `bash tools/dev/refs_check.sh` (all 233 rows) at landing; per task, the touched scenarios'.

## 7. Non-goals

- No rule, number, timing, tag or objective change; no new tag. No change to the Lantern's own lines (`MissionHints.LANTERN`),
  the briefs, goals or lose lines, or the tour captions (a tour caption that names a power is listed in Task 9's notes for a
  later pass).
- No banner for a cast that counts, for a consequence that is not a "does not count" (Q8), or for a cast near nothing.
- The free-play missions (`capital_sandbox`, `remembrance`) keep their lines.

## 8. Open questions for the user (rule changes the text would need)

- **Q1 The Informer before word.** Should a contact be workable before word reaches him (or his company stay where you put
  them)? Today nothing counts and the text can only say "wait". The user's own case.
- **Q2 One "held" rule.** "A held man sees nothing / stops guarding" is four rules: `held_by_god()` (Escort, Exodus, Bishop,
  Armoury, Heart, the Hunts' escorts), `MissionDirector.BLIND` (Faithful sight, the Informer's onlookers, the Hunt
  guards and wrights), `GUARD_MINDS` (Harvest, Market Panic, Crown's Bread: a lured man still guards) and distance alone
  (Broken Lanterns' Knights). One rule would let "Hold" mean the same everywhere.
- **Q3 Witnesses.** Unseen kills in the Warning, Bell-Ringers, Procession and Assassinate count held minds as witnesses
  (`Crowd.nearest_witness()`); the Hunts' mates and Faithful do not.
- **Q4 Market Panic wardens are fearless** on guard, unlike Harvest's watchmen whose numbers they copy: Scare never removes
  one.
- **Q5 The Relic Run's Wisp rule**: a Wisp draws the watch only once Pip is led by light or oath -- hard to say in a line.
- **Q6 The Relic Run's `citadel` phase**: once the last halt passes unswapped, nothing the player does saves the relic
  (unless Task 4 finds that a cart stood by its dead hands lets Pip board). The lessons forbid a dead end.
- **Q7 The Tax Collector `inside`**: 20 s indoors with nothing to do but Seal; most loadouts only wait.
- **Q8 Hidden consequences**: a loud power near a waiting Bell-Ringers post sends its ringer at once; a cast by the
  counting-house door smokes the next collector out. They are rules, not why-nots; a banner for them would be a new
  feature.
