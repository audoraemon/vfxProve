# KAK -- Skill Tree wheel and Remembrance

Status: **design agreed in chat with the user (2026-11-10)**, awaiting approval of this document. Branch `god/skill-tree-ui`
(cut from feat/god-progression c732803f). Lands on feat/god-progression, not Develop-Main.

## Intent (the user's words)

"It's too messy and lot's of information. I can't focus what's the important part and I can't see ability preview for make
decision to select it." ... "I want to see how's the ability works and if possible I want to try using it ... on a real in
game city. Maybe we'll explain that it's a city in god's remembrance? It'll be free to try any ability you selected."
... "please act as an professional UI Designer to make this page clear and good visualize ... beautiful and looks modern for game."

So the page has two jobs: **show one clear focus**, and **let the player see and try a power before spending points on it**.

The user's reference concept image (a stone wheel for the main Authority with tiers as rings, the two neighbours as side
statues, a detail strip along the bottom) set the layout. The user picked "A. The wheel" over a one-tier-at-a-time layout,
and approved the polished mockup ("Looks good"): `docs/superpowers/mockups/2026-11-10-skill-tree-wheel.html` (it was drawn
in the brainstorm companion; its `/files/` images were the game's own icons, font and the Will-o'-Wisp clip).

## Goals

1. The Skill Tree reads at a glance: one bright focus (the centred Authority's wheel), everything else quieter.
2. A selected power explains itself in one place: preview clip, what it is, what the next level gives, the level-5 twist.
3. **Remembrance**: from the tree, play any shown power in a real city, free, before buying it.

## Non-goals

- No new art pass: no painted backdrop, statues or stone wheel like the reference. Gradients, light and the existing icons only.
  (A painted frame can come later; the layout must not depend on it.)
- No loadout row on this page (the reference's 6-slot row): powers are drafted before each night, as today.
- No change to what learning costs, the ring/neighbour rules, the tiers or the levels tables.

## Anti-goals (a failure even if it works)

- The page still shows a wall of numbers on every power.
- Remembrance changes the god's save in any way (points, levels, Notice, Faith, bests, the night count, the seal) or counts
  as a night.
- A click on a power spends points by accident.

## Constraints

- The game draws at 640x360 (`project.godot` viewport, stretch "viewport"), pixel font `UiTheme.font()` (Pixelify Sans,
  no smoothing), palette in `src/game/ui/ui_theme.gd`. The page is drawn the way the current one is (a Control's `_draw`),
  at that size.
- Today's page: `src/game/ui/skill_tree_screen.gd` (SkillTreeScreen, Screen.TREE in `src/game/game.gd`). Its rules stay:
  `GodTree.neighbours()`, `GodSlot.refusal()/cost()/learn()/level_of()/might_of()`, `PowerBook.level_change()/twist()`,
  the `action` signal ("learned", "back"), Esc leaves.
- Existing tests that drive the screen (`spot_lines`, `detail_lines`, `learn_at`, `hit`, header/column text) will change with
  the new layout; rewrite them to the new page, keep their intent (refusal reasons, x2 neighbour cost, locked tier text).
- Endless Night only: the tree is reached from the god's hub. Remembrance never runs outside Endless Night.

## The page (decided with the user)

Layout at 640x360, matching the approved mockup:

- **Top bar.** Left: "SKILL TREE" and the god's tier and level. Centre: an Authority switcher, three chips: left neighbour,
  the centred Authority (larger, lit in its colour), right neighbour; the neighbours' chips carry "x2". Right: ability points.
- **The wheel (centre, the focus).** One Authority at a time: the god's own when the page opens. Five oval rings, **Tier I
  innermost, Tier V outermost**, two powers on each ring, a glowing core in the middle. Tier numerals I-V sit on a spoke at
  the top. The ring of the god's current tier glows; rings above it are dashed and their powers dim with a lock.
- **A power node** shows only: its icon (`SkillTreeScreen.spot_icon()`), a short name under it, and five level ticks.
  States: learned (gold ring + ticks), learnable (the Authority's colour), tier-locked (dim, grey icon, lock), not chosen yet
  (dashed empty socket), selected (bright halo). No numbers on nodes.
- **Side panels (the neighbours).** Two tall dim panels, left and right: the Authority's name in its colour, "x2 cost", and a
  small 2x5 grid of its powers' icons (same states, smaller). Clicking a panel or its chip **centres** that Authority: its
  powers fill the wheel. The three Authorities on the page never change: the god's own type and its two ring neighbours
  (far types never appear, as today). The chips keep ring order (left neighbour, own, right neighbour) and the lit chip is
  the centred one; the two side panels show the other two, in chip order. While a neighbour is centred its prices show
  doubled. A small power in a side panel can also be clicked to select it directly without centring (the user's guess,
  accepted).
- **Clicking a power selects it.** It never spends points. Points are spent only by the Raise button.
- **The detail panel (bottom, 102 px).** Left to right:
  1. The preview clip, 152x86, looping (the power's existing draft clip: `PowerBook` `CLIP_DIR`, 16 frames, 4 a row,
     `CLIP_FPS`). A power without a clip shows its large icon instead.
  2. Name (big), tags (Authority, Tier, Quiet/Loud), two lines of description.
  3. "LEVEL n -> n+1": only the stats that change at the next level, old -> new (new in green), and Might old -> new; then the
     level-5 twist line (name + one line). At level 5: "MAX" and the twist. Unlearned: "LEARN", level 1's numbers.
  4. Two buttons stacked: **REMEMBRANCE** ("try it, free"; cool blue) and **RAISE** / **LEARN** (solid gold, with the cost in
     points). When the god can't buy, the gold button greys and says why with the existing reasons (`REFUSALS`: "Awaken to
     Tier 3", "Not enough ability points", "Already at level 5", ...).
- **Colour rules.** Each Authority has one hue (Dominion violet, Ruin ember, Death green; the other three types get their own).
  **Gold always means "yours or buyable"**: learned rings, points, the Raise button. Remembrance is the only blue.
- Hover gives the existing UI sounds; a refusal buzzes as today.

## Remembrance (decided with the user)

- The REMEMBRANCE button opens a **real city as a memory**: "a night the god remembers". Real people, soldiers and buildings
  react exactly as in a night.
- It plays **the selected power**, at **a level the player picks (1-5)**, so the level-5 twist can be seen before buying.
  Any shown power can be remembered: the god's own, a neighbour's, one in a locked tier, one not yet learned.
- **Free and repeatable**: no Might cost, **no cooldown**, cast as often as you like. Nothing is won, lost or banked.
- A soft memory look (a pale edge, mist, or a desaturated tint) so it never reads as a real night.
- Leaving (Esc / a Leave button) returns to the Skill Tree **with the same power selected and the same Authority centred**.
- The city: the Capital (the `capital_sandbox` free-play mission in `src/game/mission/mission_book.gd` is the starting
  point: the Capital, no objectives, a free-play clock), or the town the god last played (*my call: the Capital; see below*).

## Settled after the builder check (*my calls*, from the conversation's intent)

- **What runs.** One power: the selected one, in a single slot, at the picked level (`mission.levels = {key: level}`, loadout
  `[key]`). The level can be changed while inside (1-5 picker on screen). To try another power, leave and pick it.
- **No clock, no win, no loss, no Results screen, no god-file write.** Remembrance is not an Endless night: it never goes
  through `_in_endless`'s banking, `_write_god`, Notice, seals or the night count. Esc opens a small pause with Resume and
  Leave; Leave returns to the tree. This is the main risk to the "never touches the save" anti-goal: a test must prove the
  god file is byte-identical after a Remembrance.
- **The city's state.** No seeding of special targets: the Capital as it is, with its people, soldiers and buildings. A
  power's own follow-ups (Procession, Sleepwalk, Second Word, Turn the Tide, the Sinner's mob) work because the power makes
  their state itself. A **Day/Night toggle** on the Remembrance screen sets the look and the night rules (`NightRules`), since
  both matter to how powers play. No Hunt state, no Dragon ground beyond what Dragonfire itself makes.
- **Powers without level tables** (today only Ruin and Dominion have them; `PowerBook.has_levels()`): the level picker shows
  level 1 only, and the panel's level column says "Levels to come" (`PowerBook.NO_LEVELS`) instead of LEVEL n -> n+1.
- **Empty spots** (a type whose tree is not filled yet, e.g. Death's Tiers 2-5): a dashed empty socket, "Not chosen yet" in
  the panel, no buttons.
- **Locks and prices for a centred neighbour.** Tier locks follow the god's tier for every Authority; the gold button shows
  the doubled price (`GodSlot.cost()` already doubles it).
- **First open.** The god's own Authority centred; selected: the first learned power below level 5 in tier order, else the
  first learnable one, else Tier I's first. The centred Authority and the selection are kept in memory for the session only,
  so Leave from Remembrance (and Back from the Faith screen, if it comes through the tree) lands where the player was.
- **Input.** Mouse, as today, plus Esc. Q/E (or the arrow chips) switch the centred Authority. No controller focus order.
- **Hit testing.** A node's hit area is its 24 px circle; nodes must not overlap (the ring layout guarantees it).

## Left to the builder

- How the level is picked in Remembrance (a 1-5 picker on the Remembrance screen, or keys) -- keep it on screen and obvious.
- How "no cooldown, no Might" is done (a Rules/Mission flag for Remembrance), as long as no real night can reach it.
- The memory look's exact form.
- The two-line descriptions: start from each power's `shape` text in `PowerBook`, rewritten short; the twist line from
  `PowerBook.twist()`.
- The colours of Decree, Passage and Veil.
- Node angles on the rings (the mockup used 60/120/30/150/90 degrees for tiers I-V and the opposite side +180) -- any spread
  that keeps names from overlapping.

## Calls I made (the user can overrule)

- The Capital is the remembered city.
- The side-panel behaviour: the three Authorities are always the god's type and its two ring neighbours; centring one swaps
  it with the wheel.
- A power without a clip shows its large icon.
- No painted art in this pass.
