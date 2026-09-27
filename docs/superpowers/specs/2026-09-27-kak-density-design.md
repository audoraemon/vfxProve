# KAK town density — design

The user asked for the town to be as dense as the Scale reference.

**Measured (2026-09-27), in the same patches of ground:**

| Same 8×8-unit area | Reference | Ours |
|---|---|---|
| West residential block | ~9 bigger two-storey houses, ~12 trees, ~20 people, fences, garden beds, lamps | ~16 small cottages, ~18 trees, ~3 people |
| Market | ~15 tightly packed stalls, ~35 people, lamps and crates | 12 stalls in wide rows, 0–2 people, 1 cart |
| South-east, by the gate | 3 big houses, a workshop, fenced gardens, ~15 trees, ~25 people | ~4 houses, ~4 trees, mostly bare paving |

- **Whole interior:**
  - Roofs cover 16% of the reference and 13% of ours.
  - Tree canopy is ~11.5% in both.
  - Open ground is 68% of ours, measured exactly from the layout, against an estimated 30–40% in the reference.
- **Where the gap is:** the house and tree counts are close. What differs:
  - people in the streets;
  - bare paving: the street margins, the market floor and the bottom of the town;
  - street life: props lining the streets;
  - building size: the reference has two-storey townhouses.

**Chosen with the user:**
- all four changes, and fill the empty space at the bottom of the town;
- keep 220 citizens.

## Constraints

- **The Main Gate's queue fan stays walkable.** It is `Crowd.queue_spots()`: rows from 2.2 to 5.4 units in front of the gate, up to ~9 units wide. The Side Gate's fan stays walkable too. A blocked cell drops queue spots, and a jammed gate breaks the escape pacing.
- **Decor inside the walls stands only on cells people cannot walk.** New props get small blocker rects, like `MARKET_PILES`.
- **Crowd changes are verified:**
  - `crowd_check` gets a new baseline, since the walk grid and anchors change on purpose;
  - `--crowd-test` still sees escapes at a similar rate;
  - the gate-queue tests pass.

## 1. People in the streets and the market

- **Anchors.** 40% of citizens (`PUBLIC_SHARE`) anchor in public ground instead of beside a home. Chosen by index, deterministic:
  - the market square's walkable floor;
  - the street centre lines, away from junctions;
  - the edges of the gate plazas, outside the queue fans.
- Their calm drift (`CALM_SPREAD`) and strolls are unchanged.
- In a panic they flee as before. They start nearer the centre, so the escape pacing is re-measured and reported.

## 2. Packing the market

- **Stalls.** The square's stalls go from 20 to ~30, in tighter rows (1.2 units apart instead of 2.2) that fill the square down to its south edge.
  - They keep clear of the fountain plaza and the north–south street through it.
  - They leave aisles at least 0.8 wide, so walking stays open.
- **Clutter.** Tables with goods, crates, barrels and baskets sit on blockers between the rows' ends, with lamp posts at the aisle heads.

## 3. Filling the open paving

- **Street margins.** `STREET_CLEAR` goes from 0.95 to 0.6: houses come closer to the streets. With 0.5-unit walk cells a street keeps its full width plus at least one cell of margin.
- **Townhouses.** ~30% of house spots with room become two-storey townhouses (1.3 × 0.95 units, 28–30 px walls).
  - They use the tavern's two-storey drawing, without its sign or awning, under slate or tile.
  - A new `townhouse` art tag, measured against the reference's townhouses with `match_components.py` to at least 85%.
- **The bottom of the town:**
  - **Gate plazas.** Keep-clear becomes the queue fan itself (a trapezoid) rather than the bigger rectangle, so houses and yards can fill the plazas' corners.
  - **A south quarter** fills the corners left of and right of the Main Gate's fan: townhouses, a carpenter's yard (an open timber shed with stacked logs, drawn like the workshop) and fenced gardens.
  - **The plaza floor** gets a paved rosette round a centre stone, worn tracks and moss. It is painted into the floor, so nothing blocks the queue.

## 4. Street life

- **Street props.** Along every street inside the walls, every ~3.5 units per side and staggered, a small blocker in the street margin carries a prop: a cart, a bench, a stack of crates with a barrel, a barrel pair, or a lamp post.
- **Kept clear:** junctions, gates, plazas, the market square and the queue fans.
- **Walking:** the street itself stays walkable; people step round the props.

## Measures and success

- **Density numbers:**
  - `tools/dev/match_density.py` (new, from the analysis script) reports the roof and canopy coverage, and the open-ground share of our interior from the layout.
  - The target is open ground from 68% down to ~50% or less.
- **Interior score:** `match_interior.py` stays at 90% or better.
- **Crowd:**
  - the crowd test still shows escapes (we expect a few more, from people starting nearer the centre);
  - the mission test is reported;
  - the gate-queue tests pass.
- **Frame rate:** benched against `kak-playtest-2`. The new structures add work; the budget is a loss of 5 fps or less.
- **Images:**
  - the overview beside the reference;
  - the bottom of the town before and after;
  - the market before and after.
