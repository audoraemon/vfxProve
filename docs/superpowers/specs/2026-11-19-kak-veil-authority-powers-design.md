# KAK Veil authority powers: design

Date: 2026-11-19. Status: draft, waiting on the user's approval.
Picks: the user's Veil Tree Picker (https://claude.ai/artifact/JCNBWoM8DovHzUGEGtDKEW, ArtifactData `picks/veil`).
Research: the Darkness pathway of the novel *Lord of the Mysteries* (Sleepless, Midnight Poet, Nightmare, Nightwatcher,
Horror Bishop, Servant of Concealment, the Evernight Goddess).
Sister specs: `2026-11-12-kak-death-authority-powers-design.md`, `2026-11-12-kak-decree-authority-powers-design.md`.

## 1. Intent

The user's words: "Veil holding a power like Darkness, Hiding, Silence, Night ... this god should own the most silence
abilities. But should have trade off like an ability radius."

The Veil god is the god of the dark and the quiet. Its powers raise no alarm; the town does not know a god is at work.
Other gods are loud and wide. Veil is unnoticed and exact, and it pays for that with reach: its powers are small when
cast in the open and full size when cast in the dark. So a Veil god lays the dark first and strikes inside it, and the
dark grows from cast to cast.

What the user liked and did not like while picking (it decides the tone): they brought the void (a circle that grows
unseen, then everything in it is gone) and asked for Evernight to have teeth. Soft powers that only put people to sleep or
make them forget did not meet their expectation. Veil's big powers take things, silently and for good.

## 2. The tree (the user's picks)

| Tier | Spot 0 | Spot 1 |
|---|---|---|
| 1 | Silent Doom `doom` (built; gains the light/dark sizes) | Blight `blight` (built, **reworked**) |
| 2 | **Slumber** `slumber` (new) | **Cloak of Night** `cloak` (new) |
| 3 | Unseen Hour `unseen` (built, in no spot until now; gains the light/dark sizes) | **Dreamless** `dreamless` (new) |
| 4 | **Dread of the Dark** `dread` (new) | **Shadow Play** `shadowplay` (new) |
| 5 | **The Swallowing Dark** `swallow` (new) | **Evernight** `evernight` (new) |

Seven new powers, one rework, two built powers resized. Might at level 1: doom 1, blight 2, slumber 3, cloak 3, unseen 3,
dreamless 3, dread 4, shadowplay 5, swallow 6, evernight 6. Per tier: 3, 6, 6, 9, 12 (caps 6 / 8 / 10 / 13 / 16).
Every Veil power is quiet (`"quiet": true`, `"authority": "veil"`).

`GodTree.TABLE.veil` becomes
`[["doom","blight"],["slumber","cloak"],["unseen","dreamless"],["dread","shadowplay"],["swallow","evernight"]]`.

## 3. Goals, non-goals, anti-goals

**Goals**
- The law of the Veil (§4) as one shared piece every Veil power reads.
- The seven new powers and the Blight rework at level 1, playable from the VFX Sandbox, Remembrance and a god's slots.
  Each has its own look, its own sound, a skill-tree blurb and a HUD shape line.
- Silent Doom and Unseen Hour take the light/dark sizes; their light size is exactly today's.
- Veil still wins its five Tier 1 nights and Hunt 1 with Silent Doom and Blight (the board's bar: wins >= 2/3, idle <= 45 s).

**Non-goals (this phase)**
- Levels 2-5 and the level-5 twists. They come after, as with Death and Decree.
- Veil bots for Tiers 2-5 and new Veil Hunt 2-5 loadouts. Those rows keep their present loadouts (dev keys) until the
  levels phase.
- Painted ability icons for the seven new powers (the icon recipe is its own task). A flat placeholder icon is enough.
- New missions.

**Anti-goals: these would make it a failure even if it technically works**
- A Veil power that raises the town's alarm, registers a danger, or makes anyone scream. Veil is silent.
- Luck. Who is taken, who sleeps, which torch is lit: all by rule (nearest, farthest, then instance id), never random.
- A power that only makes people sleep or forget at Tier 4-5. The big powers take something.
- Dusk that changes anything for a god who carries no Veil power: every reference row that casts no Veil power must
  stay byte-identical.
- A frame-rate cliff. The Swallowing Dark and Evernight must hold the frame rate in the 220-person town (cast/base
  avg_ms ratio <= 1.55, the bar Pale Reign and the Serpent met).
- Veil's automatic takes killing the people the god must keep alive (§5.9, the spared).

## 4. Shared piece: the law of the Veil

**Small in the light, full in the dark.** Every Veil power has two sizes. Which one a cast gets is decided once, at the
moment of the cast, from the ground under the click (for a drag: under its start).

**What counts as dark** (`Crowd.in_dark(at: Vector2) -> bool`):
1. a dusk patch covers `at` (below);
2. Unseen Hour's veil covers `at` (`Crowd.is_veiled(at)`);
3. the mission is a NIGHT mission (`NightRules.is_night(look)`) — everywhere outdoors;
4. Evernight is up — everywhere.

**Dusk.** Every Veil cast leaves a dusk patch where it lands: a circle of `DUSK_R = 3.0` (or the power's own area when
that is larger) for `DUSK_TIME = 20.0` s, laid when the power lands, not when it is aimed. The next cast inside it is
full size and leaves its own patch. Let the dusk fade and the god starts small again.
- People standing in dusk see `NightRules.NIGHT_SIGHT` (0.6) as far, and a thing inside dusk is seen from 0.6 as far.
  This scales every sight the crowd uses, the witness reach (`Crowd.doom_witness()`) included.
- Dusk is quiet: it registers no danger, raises no alarm, frightens nobody. People walk through it as they would.
- Lamps and lit windows inside a dusk patch dim (the lighting look only; no rule reads it).
- Only Unseen Hour's veil hides everything. Dusk only shortens sight and sizes Veil's powers.
- **Only with Veil.** The dusk ledger exists only when the night's loadout (or the VFX Sandbox / Remembrance) carries a
  power whose `PowerBook` authority is `veil` (`doom`, `blight` and `unseen` carry it today). The trigger is the power,
  not the god's type: a neighbour god who carries Silent Doom gets the same dusk and the same two sizes. Missions that
  carry no such power run exactly as today.
- **One scale, never two.** A sight line is shortened to 0.6 once if the viewer or the thing seen is in the dark (dusk
  or a NIGHT mission). It is never 0.36.
- Drawn: a soft-edged violet-black darkening of the ground (Unseen Hour's `DUSK` `3b1470` family), in one cheap layer.
  The player sees dusk clearly; it must read at a glance where the dark is.

**Showing the size.** While aiming a Veil power the cursor ring is drawn at the size the cast would get there: the small
ring over lit ground, the full ring over dark ground, with a short tag (`LIGHT` / `DARK`). The skill-tree detail and the
HUD shape line give both numbers.

**Constants** live in one file (`src/game/veil_rules.gd`, as `NightRules` does for the night). All numbers in this
document are first drafts for level 1.

## 5. The powers (level 1)

Sizes are written light / dark. "Taken" means killed with no body, no sound and no remain; the kill is the god's.
New kill kinds (`&"void"`, `&"night"`, `&"dreamt"`, `&"shadow"`) leave no body and are added to the powers' credit
(`POWER_KINDS`). Dreamless's found body is kind `&"dreamless"` and does leave a remain.

### 5.1 Silent Doom `doom` (built)
Reach 0.8 / 1.6. Nothing else changes: victims fixed at the cast, fall `T_STRIKE` later, the witness rule as today.

### 5.2 Blight `blight` (rework; the user's call: both parts)
Might 2, cooldown 20 s (36 s until the second review pass, 2026-11-22), aim: click a building or a person. What a click picks, in order: (1) a mission's own blight
target (`MissionDirector.blight_target()`), as today; (2) the building whose footprint is under the click; (3) the
nearest person within 0.5; (4) the nearest building within today's `REACH` of 1. So a click on a building always takes
the building, and today's routes, which click buildings, pick what they picked before.

- **On a building, any standing building** (not only one with a use): it rots grey-green, its lights go out, and its
  use is gone exactly as today (`EnvironmentField.blight()`; everything that reads `Structure.blighted` is unchanged).
  The ground within 3 / 5 of its centre is dusk until the mission ends, not for 20 s. It is the god's lasting foothold.
  At most 3 blighted buildings at once: a fourth heals the oldest (`unblight()`, its lights return, its dusk ends).
  A mission-blighted thing (a standard, a mirror, a granary) is not a building and does not count toward the 3.
- **On a person:** they fall ill without a sound, walk home (no home: the nearest house that takes people in), go
  inside and stay in bed for the rest of the mission. It is not a death: nothing to witness, no alarm, no kill credit.
  The sick are alive and are counted among the living, as the citizens a NIGHT mission keeps indoors are; they are
  simply not on the street or at their post.
  A soldier leaves his post for the barracks; a carter drops his load; a messenger's errand ends. Dark: that person
  and the 2 nearest within 2.
  - **Quarry is not sent home.** A person a mission's director is built around (the tax collector, the warning's
    messenger, an inquisitor, the lamb's shepherd and the like) is ill for 20 s instead: half pace, nothing dropped,
    then well again. Blight must not be a one-click win. A new director question, `quarry(p: Person) -> bool`, default
    false, answers it; each director that has such a person overrides it. The god's own believers are never quarry and
    are not made ill at all (the cast passes over them).
- Today's fizzle ("nothing of use in reach") goes: with neither a person nor a building in reach it refuses the cast.

### 5.3 Slumber `slumber` (new, Tier 2)
Might 3, cooldown 40 s, aim: click. Everyone in a circle of 1.5 / 3.5 sleeps where they stand for 20 s
(`Person.sleep()`): citizens, watchmen, soldiers. Light: a loud blow or a hurt wakes a sleeper, as with Curfew.
Dark: a deep sleep that noise does not wake; only a hurt does. Decree's Curfew stays as built, outside the tree.

### 5.4 Cloak of Night `cloak` (new, Tier 2)
Might 3, cooldown 45 s, aim: click. The 3 / 8 people nearest the click within 2 / 4 are hidden for 25 s. Everything
that looks past Death's Corpse Guise looks past them (the watch, the search, inquisitors, the witness check, a
soldier's choice of whom to fight): one shared question, "is this person hidden from the watch", answered by guise or
cloak. Differences from the Guise: the cloaked walk normally and are drawn under a dark shimmer, not grey and
shambling; Death's undead do not spare them. Made for hiding the god's believers and for walking someone out past a
gate. The Guise's readers are moved onto the shared question in one pass that changes no behaviour: every Death row
must still match its reference.

### 5.5 Unseen Hour `unseen` (built)
Circle 5 for 20 s / circle 7 for 30 s. Its veil counts as dark (§4). Nothing else changes.

### 5.6 Dreamless `dreamless` (new, Tier 3)
Might 3, cooldown 35 s, aim: click. The nearest 1 within 1 / the nearest 4 within 2 sit down against the nearest wall
as if to rest, and do not wake. For 20 s the town sees only people resting: no witness, no crowd. Then they are found
like any other dead (kind `&"dreamless"`, a body). Anyone already asleep when it lands (Slumber, Curfew, Shadow Play,
a night sleeper) is taken at once instead (`&"dreamt"`): never found.

### 5.7 Dread of the Dark `dread` (new, Tier 4)
Might 4, cooldown 70 s, aim: click. For 25 s every piece of dark ground (§4) within 6 / 12 of the click is dreaded:
- nobody outside will step into it; routes treat it as closed, so the dark works as a wall;
- everyone already inside freezes where they stand, silent: they cannot walk, flee, shout, ring, fight or seize.
With no dark ground in reach the cast is refused. It turns the dusk the god has laid into a trap, and it sets up
Dreamless, Silent Doom and the Swallowing Dark. In a NIGHT mission or under Evernight everywhere is dark, so the whole
circle of 12 is dreaded: that is intended. Someone whose only road is closed waits at its edge until the dread ends.

### 5.8 Shadow Play `shadowplay` (new, Tier 4)
Might 5, cooldown 90 s, aim: click. Everyone in a circle of 3 / 6 becomes their own shadow for 30 s.
- The person is asleep and hidden; what walks is the shadow, drawn as the person's dark silhouette. It goes on with
  the person's task: the post looks manned, the patrol still walks, the queue still stands. Directors and the town
  count the post as held.
- A shadow sees nothing and does nothing: it witnesses nothing, reports nothing, raises no alarm, and a soldier's
  shadow does not chase, fight or seize. The owner counts as asleep (Dreamless takes them at once).
- At the end the shadow lies down where it is and the person wakes there, remembering nothing.
- Dark: the soldiers' shadows do not lie down. They walk off and fade, and those soldiers are taken (`&"shadow"`).
- A shadow is not afraid of the dark: Dread neither stops it nor freezes it.

**When states meet** (all Veil powers): taken beats everything; asleep (Slumber, Shadow Play) beats frozen (Dread),
so a frozen person hit by Slumber sleeps; a sleeper is not frozen again. The Swallowing Dark and Evernight take
sleepers, the frozen and shadows' owners alike.

### 5.9 The Swallowing Dark `swallow` (new, Tier 5; the user's void idea)
Might 6, once a descent, aim: click. A black circle opens at the click and grows from its centre at 0.5 a second.
Light: from 0 out to 10 (20 s). Dark: it starts at the radius of the dusk patch it was cast in and grows out to 14.
- Nobody sees it grow: no danger, no fright, nobody runs from it. Someone walking through may walk out in time.
- When it reaches full size, everything inside is gone without a sound: every person (`&"void"`), every animal, every
  prop and piece of decor, and every building whose footprint lies wholly inside the circle. No bodies, no rubble: bare
  dark ground, and the walk grid opens where the buildings stood. Nobody remembers what stood there: no alarm, no
  search, no one counts the missing.
- A building the mission needs standing is spared (`MissionKeeps.needs_standing`), and so is a mission's own object.
- Buildings leave by the quiet path Eminent Domain already uses (`EnvironmentField.remove(s, true, true)`): the field
  lets go of them, the walk grid is told, no rubble is laid.
- The emptied ground stays dusk for 20 s.
- The removals may be spread over a few frames to hold the frame rate. The bar is the average ratio (§3); the worst
  single frame of the cast is reported with it, aiming under 50 ms.

**The spared.** The Swallowing Dark is aimed, so it takes whoever is inside, the god's own believers too. Evernight's
automatic takes (5.10: the lone, a torch put out, no dawn) never take the spared: a person whose
`profile.faith` is `CitizenProfile.Faith.BELIEVER` (the god's own; `FAITHFUL` are the church's and are not spared), or
one a new director question, `keeps_alive(p: Person) -> bool` (default false), answers for. `keeps_alive` and Blight's
`quarry` (5.2) are two separate questions.

### 5.10 Evernight `evernight` (new, Tier 5; the user's call: all four parts)
Might 6, once a descent, aim: cast (no target needed; the wave starts at the click). Night rolls out from the click in a
wave over 3 s and every lamp dies street by street; the town wears the NIGHT lighting look. It lasts 60 s, then dawn
returns over 3 s. Cast in a NIGHT mission: 90 s, and part 2 takes one every 1.5 s.

1. **The night is yours.** Everywhere is dark (§4), so every Veil power is full size anywhere. While it lasts the
   cooldown clocks of Veil-authority powers run twice as fast, for a cooldown already running and for a new one
   alike; a once-a-descent power is not touched. The whole town is under Unseen Hour's rule: no cast is seen, no death or
   collapse raises the alarm or brings anyone, nothing is counted against the god.
2. **The dark takes the lone.** Every 2 s, of the living people outdoors, outside every torch's light and not spared,
   the one whose nearest neighbour is farthest away is taken (`&"night"`); a tie goes to the lower instance id.
3. **Islands of light.** When the night falls, up to 6 soldiers light torches: those with the most citizens within 6 of
   them (ties by instance id), each standing where he is. A torch lights a circle of 2.5. Citizens within 10 of a torch
   walk to it and huddle; whoever stands in its light is safe from part 2. Any Veil cast whose area touches a torch
   puts it out, and everyone who stood in its light is taken at once. A torch-bearer who dies or is taken drops his torch:
   it goes out the same way.
4. **No dawn for some.** At dawn the town forgets the night: no alarm, no search, no count of the missing. Whoever is
   inside a blighted building, or asleep inside a dusk patch, at dawn never wakes (`&"night"`).

Expected toll, played well: 60 to 100 people (Grave Tide takes about 150, Heaven's Door about 65).

## 6. Looks and sounds

- Palette: Unseen Hour's violet and dusk (`b98cff`, `3b1470`) with black and a thin silver for edges; Evernight adds
  stars and a pale moon in the sky wash. No green (that is Death's and Blight's rot), no gore, no fire.
- All code-drawn with the effect kit (`FxTimeline`, `FxParts`, `PixelParticles`), as Unseen Hour is. No PixelLab.
- Each power has its own cast sound and, where it lasts, a loop. They are quiet sounds: breath, cloth, a held note, a
  lamp guttering. Sources follow the rules the Death and Decree powers followed; nothing Sonniss-derived goes in the
  repository.
- The god must always see where the dark is and what a cast took; the town must see nothing.

## 7. Tier 1 routes and references

- Silent Doom's and Blight's light behaviour on the things today's routes use is unchanged, so Veil's five Tier 1
  nights and Hunt 1 should still be won. They are re-run; a route that fails is fixed in its bot, not by weakening the
  rework.
- Rows that cast a Veil power will move (dusk makes the second cast larger): they are re-recorded once the gate passes.
  Every other row must match the references file untouched.
- Hunt 2-5 Veil rows keep their dev loadouts this phase (non-goal).

## 8. Approaches

1. **A dusk ledger in the crowd, read by every Veil power (picked).** One small manager holds the patches; `in_dark()`
   is the single question; a shared helper gives each effect its light or dark numbers. It follows how Remains (Death)
   and LawZone (Decree) were built, keeps the rule in one place, and lets the ledger not exist when no Veil power is
   carried.
2. Each power checks Unseen Hour's veil and the night look itself. Less new code, but the rule is copied ten times and
   there is no dusk, so a Tier 1 god in a day mission has no dark at all. Rejected with the user (option C of the
   dark's source).
3. A town-wide light map sampled per cell, with lamps as light sources. The most faithful picture, but it costs a
   texture update each frame and makes "is this dark" depend on art. Rejected: too costly for what the rule needs.

## 9. Constraints

- Godot 4.7.2 GDScript. Powers are reusable effects under `src/fx/veil/` (the built three stay in `src/fx/quiet/`),
  never hard-coded into `Person` or a citizen agent; people expose small hooks, effects use them.
- Branch `god/veil-powers`, worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-veil`, cut from `feat/Develop-Main` `acb82b96`
  (it already holds all of `feat/god-progression`). It lands on `feat/god-progression` by fast-forward; pushes and any
  merge into `feat/Develop-Main` wait for the user's word.
- Checks before landing: the whole suite, every reference row, FLOW alone on a quiet machine, the level-1 bench for the
  two Tier 5 powers.
- Every new power needs a `PowerBook` row with a blurb (the blurb test counts keys) and a place in the Upgrades grid.

## 10. Left to the builder

- Exact timings inside a cast (gather, land, fade), particle counts, the look of each effect within §6.
- How the freeze (5.7), the shadow (5.8) and the sickness (5.2) are held on a person, using the hooks the Death and
  Decree twists already added where they fit.
- Which soldiers' duties end when they walk to barracks sick, mission by mission; any mission-specific ruling is
  written down in a rulings document (`docs/KAK_God_Veil_Rulings.md`).
- Test names and the split into tasks.

## 11. Amendments after reading the code (2026-11-19)

These replace the text above where they differ.

1. **Blight raises no alarm.** Today a blighted building adds `Crowd.BLIGHT_ALARM` (1.0). The rework drops it, for a
   building and for a mission's own target alike: a Veil power raises no alarm (§3). The 30 s gate jam stays; it is the
   gate's use gone, not an alarm.
2. **Evernight does not switch the town's art look.** The game can only change the DAY/NIGHT look by rebuilding the
   mission. Evernight draws its night by easing the light field's ambient and tint to the night values, muting the
   lamps and laying a starred sky wash, and eases them back at dawn.
3. **Dusk does not dim lamps.** The light field cannot dim one light. The dusk layer darkens the ground itself;
   Blight removes its building's light outright.
4. **"The ledger exists only with Veil" does not isolate rows by itself.** Silent Doom is in 22 missions' default
   loadouts. What keeps other rows identical is that an empty ledger changes nothing; a row that casts a Veil power
   moves and is re-recorded.
5. **A sick person walks to their home point.** People have no home building, only the point in front of their house.
   They walk there (a soldier: to the barracks yard) and are then kept indoors as a NIGHT mission keeps its citizens.
6. **"Inside a blighted building" at Evernight's dawn** means: sheltering in one.
7. **The Upgrades grid is widened** to hold the seven new locked powers.
8. **Each new power gets a preview clip** (the draft screen's test requires one per power) and a generated flat icon.

Departures the build ruled (2026-11-20; rulings file `docs/KAK_God_Veil_Rulings.md`):

9. **Dread of the Dark lays its dusk when the dread lifts** (C18, VC1), not when it lands. A patch laid at the landing would itself
   be dark ground in reach and freeze everyone within 3 of every click, in the light too, against 5.7's "turns the dusk the god has
   laid into a trap".
10. **The Swallowing Dark keeps the town's gates, bridges, postern, dock and fountain** (VA5), besides what `MissionKeeps` spares,
    as Eminent Domain does: the town's managers go on using them, and a bridge taken out of the walk grid would close the river.
11. **Shadow Play's kill kind is `&"shade"`** (C12, V11), not `&"shadow"`: the Pale Serpent already owns `&"shadow"` (a body and a
    remain). The shadowed person's status key stays `&"shadow"`.
12. **Each new power sets `busy` to its landing time** (C16), so the other slots unlock once it has landed. Silent Doom, Blight and
    Unseen Hour keep the lock they have today (level 1 in the light is today).
13. **Evernight lays no dusk patch of its own** (VC7): the whole town is its dark while it lasts (`Dusk.everywhere`), and a patch at
    the click would only put out the torches near it.
