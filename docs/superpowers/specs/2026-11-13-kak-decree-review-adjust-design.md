# Decree review adjustments — design (2026-11-13)

Source: the user's Discord review, #ideas post "Decree's Abilities Review and Need some adjust" (1570686744595271690):

> some abilities needs to leave bodies
> Redefine — Criminal => everyone around should run away and guards try pursuit and attack them
> Erasing Distance — fold to the start, not the middle; fold buildings too; everything in its path merges into where it starts
> Eminent — more detailed rubble (piles of fallen structure), shared by every ability that needs rubble; buildings must
>   not just disappear: an effect first, or crash and move aside
> The Sealed Verdict — more effects, shorter delay

Base: feat/god-progression a00ca40b (Decree + Death merged). Branch god/decree-powers.

## Rulings (the user said "read and implement"; these fill what the post leaves open)

**R1 Bodies.** Decree's kills leave whole bodies: kinds `choke` (Breathing), `verdict` (Sealed), `bound` (Bound in
Law) and a new kind `crushed` (Closing Cage bars and end crush, Erasing Distance fold). Each is added to
`Remains.BODY_KINDS` (Death's Raise the Dead / Walker / Grave Tide can use them — Death is Decree's ring neighbour) and
the body lies `DummyEnemy.BODY_HOLD` (20 s) before it fades, as Death Mark's does. `crushed` is new so the town's own
`collapse` (a house falling on its shelterers: ShelterManager, RescueManager) keeps its look and timing. Wherever the
town reacts to `collapse` by kind, `crushed` reacts the same. `crushed` is loud (not in DeathVoices.QUIET_KINDS).
Rules.POWER_KINDS: cage and erase → `crushed`. Eminent Domain still kills nobody.
Cost if wrong: more bodies on the ground for 20 s (a little more draw); Death synergy may be stronger than wanted.

**R2 Redefine — CRIMINAL.** While the law holds: every non-guard person out of doors within `FLEE_R` = 4 of the
criminal runs away from him (a local flee, re-checked every `LawMark.LOOK`; never an escape off the map and no count
changes); every guard within `PURSUE_R` = 8 (was `SIGHT` 3) goes for him and pursues (the existing TARGET_ONLY law
fight) until the law ends or he dies. A NOBODY criminal is unseen (unchanged precedence). OFFICER / NOBODY unchanged.
Cost if wrong: radii are tuning.

**R3 One rubble look.** Every pile of fallen structure a power leaves (law rubble: Erasing Distance, Eminent Domain)
draws as a heap of real ruins art — the `ruins.png` of a small building set from `assets/pixellab/buildings/` (picked
by the pile's position hash from a fixed list of small sets, never a roll), fitted to the pile's footprint, with a dust
puff when it is laid. `LawRubble.lay(env, rect, h, from := null)`: given `from` (the building it came from) the heap
wears that building's own ruins art. Procedural fallback (jagged stone chunks + beams, not a crate box) when sprite art
is off. Windfall / Skylift heaps are piles of goods, not fallen structure: unchanged. Gameplay of the pile (blocking,
engineers clear it, role `decree`) unchanged.
Cost if wrong: art choice; easy to swap the list.

**R4 Erasing Distance folds to its start.** Stage 2 drags everything within `CRUSH_W` of the line — people, decor and
every building the line crosses — along the line to the press point (origin) over `T_FOLD`. Buildings slide toward the
origin, shrinking and crumbling as they go (drawn by the effect), and are removed whole when they arrive (as Eminent
removes, keep_node, Structure.taken); a building whose health another owns (the Citadel) is dealt the blow instead.
People caught are crushed at the start (kind `crushed`; their bodies lie piled there). At the close everything merges
at the start: one mound of law rubble clustered round the origin (never on a standing building or water; anyone
standing where a heap lands is pushed out first), sized by what was taken (1 heap + 1 per building + 1 per 3 decor,
capped), each building heap wearing that building's own ruins art (R3). The line itself is left bare, its cells open to
walk (WalkGrid.open_street, the river excepted). Buildings within `CRACK_W` still crack; the spring-back throw stays.
No heaps along the line any more. Never a roll.
Cost if wrong: Erasing no longer walls a street (it now opens one and blocks the start).

**R5 Eminent Domain — buildings crash and move aside.** At the tear each torn building is shoved to the nearer side
of the strip over `T_SHOVE` = 0.5 s: its art slides outward, tilts and crumbles (the set's collapse frames when it has
them), with dust bursts and flung debris. Where it stops it becomes its own rubble heap (R3, its own ruins art) along
the street edge; generic heaps fill only the gaps between. Decor in the strip is flung aside (spinning out) rather than
vanishing. The street stays bare; nobody dies (unchanged).
Cost if wrong: a busier edge; heaps placed by building size, so the side wall is less even.

**R6 The Sealed Verdict — shorter, richer.** `COUNTDOWN` 60 → 30 s. Kill rules unchanged; the town still sees nothing
before the stroke. More effects, player-only before the stroke: a brass ledger page beside the circle inking a tally of
the souls inside (live count), gilt script chains turning round the rim, rune ticks counting down, over the last 5 s
the district darkens (overlay) and a brass bell shape descends. At the stroke: a great seal stamps down at the centre
(flash, shock ring, a burnt seal glyph left on the ground fading over 4 s), a gilt line from the seal to each who dies,
and a soul wisp rising from each (up to `FLECKS`). Cooldown unchanged (once a descent).
Cost if wrong: 30 s may make it too strong on short nights.

## Done looks like

Each power's clip (`behaviour_check --scenario=clip`) re-made for Redefine, Erasing, Eminent, Sealed (and Cage if its
look changes); Decree refs re-recorded; full gate (4 parts + crowd_check -535548941) green; landed on
feat/god-progression after a trial merge; #god-changelog post; Ledger + #board; the Discord post OPEN → DONE.
