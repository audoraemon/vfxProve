# KAK v0.10 M6: Objective Clarity (design)

Date: 2026-10-07. Status: approved in chat ("yes please" to the three-part design); landed as `kak-v010-m6`. The
words below are as shipped: the final review dropped elapsed times ("0:50") from three strings, since they sit beside a
countdown clock. Builds on
`2026-10-05-kak-v010-lantern-campaign-design.md`.

## 1. Why

The first playtest of v0.10 could not tell which house is Mira's, who the Inquisitor is, or how to win. In the
player's words: "Every mission should have indicators to let the player see clearly, and briefly describe the
objective in game too." M6 makes each Night 2 objective visible on the map, says how to win in one line on the HUD,
and opens each Night 2 mission with a short camera tour of its key places.

Three parts:

1. **Map tags:** labelled marks on the map, with arrows at the screen's edge for anything off screen. One shared HUD
   layer, fed by each mission's director. The board missions can adopt it later.
2. **How to win:** one short line under the objectives, for every mission and act, changing with the mission's
   phase.
3. **The tour:** before the clock starts, the camera visits each key place of a Night 2 mission with a caption.
   Space, Enter or a click skips it.

Text and drawn shapes only: no new art, no PixelLab.

## 2. Map tags

### 2.1 MapTag

`MapTag` (`src/game/mission/map_tag.gd`, RefCounted) is one thing the HUD points out:

| Field | Meaning |
|---|---|
| `at: Vector2` | The ground point (ground units). |
| `color: Color` | The diamond's, the label's and the arrow's colour. |
| `label: String` | Upper case, a few words; `""` for a plain mark. |
| `rise: float` | World pixels above the ground point: a building's height (`Structure.height`), 0 for a person. |
| `lift: float` | Screen pixels above that: 22 for a person (as v0.10's marks, `Hud.MARK_LIFT`), 8 for a place. |
| `size: float` | The diamond's half size: 4 (`Hud.MARK_R`), or 3 for a crowd pip. |
| `edge: bool` | Off screen, an arrow at the screen's edge points to it. |
| `outline: Rect2` | A ground footprint to outline (Mira's house); an empty `Rect2()` for none. |

Constructors: `MapTag.person(at, color, label := "", edge := false)`, `MapTag.pip(at, color)` and
`MapTag.place(at, color, label, rise := 0.0, edge := true)`.

### 2.2 The director's side

`MissionDirector.tags() -> Array[MapTag]` replaces v0.10's `marks()`, which goes. `tags()` only reads: it changes no
state and draws no random numbers, so every behaviour checksum stays the same. A tag is only made for a living, valid
person and a finite point.

`marker()` stays for The Warning. The three Night 2 directors drop their `marker()` overrides, because their tags
carry edge arrows instead.

### 2.3 The HUD's side

- `Hud.tags_shown(rules)` replaces `marks_shown()`: while any tag shows, the HUD redraws every frame.
- **On the map** (drawn first, under the rest of the HUD, as v0.10's marks):
  - the outline, if any: the footprint's ground diamond, 1 px, in the tag's colour;
  - the diamond, with a dark edge, at the ground point raised by `rise` (world) and `lift` (screen);
  - the label, centred above the diamond, in the tag's colour on a dark plate (`SIZE_SMALL`), kept inside the
    screen.
- **Label overlap:** labels are placed in tag order. A label whose plate would overlap one already placed is skipped,
  but its diamond still shows. So a director lists its most important tags first.
- **Edge arrows:** a tag with `edge` whose diamond is off screen gets an arrow at the edge (`Hud.edge_arrow()`), in
  its colour on a dark disc, with its label beside it inside the screen. Arrows are drawn last, over the HUD, as The
  Warning's marker is. Arrow labels obey the same overlap rule.

## 3. How to win

- `MissionHints` (`src/game/mission/mission_hints.gd`) keeps the lines apart from the logic, as `CampaignText` does.
  - `const LINES` is keyed by the id of the played mission or act, and by `"<id>.<phase>"` for a phase's line.
  - `static func line(id: String, phase := "") -> String` returns the phase's line if there is one, else the id's,
    else `""`.
- `MissionDirector.hint_phase() -> String` is virtual and returns `""` by default.
- `Hud.hint_text()` is `MissionHints.line(rules.mission.id, phase)`.
  - It is drawn under the objective panel (scored missions) or the objective rows (unscored), on a dark plate.
  - Wrapped to `HINT_W` (228 px), at most `HINT_LINES` (3) lines, `SIZE_SMALL`, pale gold.
- **Lines** (the colour names match the tags):

| Key | Line |
|---|---|
| `warning`, `omen` | Stop the messenger (gold arrow) before the bell tolls, or hold out until the omen fades. |
| `festival` | Break the festival: kill or scatter fifty of its crowd before the guard closes the square. |
| `procession` | Kill the Prince before he boards his ship. If no one sees him die, the town is left leaderless. |
| `judgement` | Bring the Citadel down before dawn, before too many of its people escape. |
| `last_judgement` | Destroy the Citadel and break the city before time runs out. Fifty escaping loses it. |
| `miras_house` | Whisper a grieving (gold) to Mira's door while no Faithful (red) watches. Four must believe by dawn. |
| `miras_house.four` | Four believe. Keep the Believers (orange) alive until dawn, and the Gaze from filling. |
| `miras_house.burning` | Her house burns: no one can go in now. Keep your Believers (orange) alive until dawn. |
| `broken_lanterns` | Break a lantern (gold), then keep the flame-bearer off it for 20 s while it drains. Drain all six. |
| `broken_lanterns.knights` | A Knight (blue) shields the lantern he guards. Draw him off or kill him, then strike. |
| `vigil_flame` | Soon the boy Wren comes for the flame (gold). Its acolytes would see him: draw them off first. |
| `vigil_flame.wren` | Whisper Wren (blue) to the flame (gold) while no Faithful but its bearer is near him (red). |
| `vigil_flame.homeward` | The Vigil turns for home: have the flame swapped before its bearer reaches the Temple. |
| `vigil_flame.carry` | Walk Wren to Mira's shrine (orange), west past the wall. Keep him out of the searchlight. |

The Feast plays The Long Night's act, so its rules carry the act's id (`festival` or `procession`). Its line is the
act's.

## 4. Each Night 2 mission's tags

The tags are listed in order, most important first, because label overlap keeps the first.

### 4.1 Mira's House

- **The house:** a place tag at its centre, label `MIRA'S HOUSE`, gold.
  - `rise` is the house's height, `edge` is on, and the footprint is outlined.
  - Shown until the house is destroyed.
- **The door:** a place tag at `door` (rise 0).
  - `DOOR - CLEAR` (green, `UiTheme.STABILITY_COLS[0]`) while no Faithful sees it.
  - `DOOR - WATCHED` (red, `UiTheme.COL_BAD`) while one does (`faithful_seeing(door, SIGHT)`).
  - No edge arrow (the house has one). Hidden once the house burns.
- **Report runners:** each open report's carrier, a person tag `TO THE TEMPLE`, red, with an edge arrow.
- **The crying Believer:** a person tag `CRYING OUT`, orange, with an edge arrow (in place of `marker()`).
- **The Inquisitor:** Venn, a person tag `INQUISITOR`, violet (`Color("c070ff")`); edge arrow while she searches.
- **The Temple:** a place tag at the Temple's door, `TEMPLE`, red, with an edge arrow, only while a report runs.
- **Watchers:** each Faithful who sees the door (within `SIGHT`, out, alive, not held by the god): a red diamond, no
  label.
- **The grieving and the Believers:** pale gold and orange diamonds, as in v0.10.
- **Hint phases:** `burning` once the house burns or falls; else `four` with four or more Believers out; else `""`.

### 4.2 Broken Lanterns

- **Each standing shrine:** a place tag, `rise` `SHRINE_H`, with an edge arrow.
  - `GUARDED` (steel blue, `Color("8fb8e8")`) while a Knight guards it (`guarded(s)`); else `LANTERN`, gold.
- **Each broken shrine still draining:** `DRAINING 12` (whole seconds left, rounded up), ember, with an edge arrow.
- **A drained shrine:** no tag.
- **The flame-bearer:** a person tag `FLAME-BEARER`, gold. The edge arrow shows only while he is on his way to
  relight a shrine (in place of `marker()`).
- **Each living Knight:** a person tag `KNIGHT`, steel blue, no edge arrow.
- **Hint phases:** `knights` while any Knight lives; else `""`.

### 4.3 The Vigil Flame

- **Wren:** from his arrival until the flame is home, a person tag `WREN`, light blue (`MARK_WREN`), with an edge
  arrow (in place of `marker()`).
- **The flame:** while it is still in its lantern, a person tag `HALCYON'S FLAME`, gold, with an edge arrow, at the
  lantern (`_lantern`).
- **Mira's shrine:** a place tag `MIRA'S SHRINE`, orange, with an edge arrow.
- **The Temple:** a place tag `TEMPLE`, red, with an edge arrow, while the Vigil goes home with the real flame
  (`homeward` and not `swapped`).
- **Witnesses:** after Wren arrives and before the swap, each Faithful other than the bearer within
  `Crowd.DOOM_WITNESS` of Wren (out, alive, not held by the god): a red diamond.
- **Hint phases:**
  - `carry` once swapped (until home);
  - else `homeward` while the Vigil goes home;
  - else `wren` once he has come;
  - else `""`.

## 5. The tour

- **`IntroTour`** (`src/game/mission/intro_tour.gd`, RefCounted) is a pure timeline.
  - `setup(from: Vector2, stops: Array, to: Vector2) -> IntroTour`. Each stop is `[Vector2, String]`: a ground point
    and its caption.
  - Legs: from `from` to each stop in turn, then to `to`. Each leg takes `MOVE_SECONDS` (1.0) with a smoothstep, and
    the camera holds `HOLD_SECONDS` (1.6) at each stop.
  - `step(delta)`; `camera() -> Vector2` (a ground point); `caption() -> String` (the stop's caption while moving to
    it and holding there, `""` on the last leg); `zoom_k() -> float` (0 to 1 over the first leg, then 1); `done()`;
    `skip()`; `seconds()` (the total).
- **`MissionDirector.tour() -> Array`** is virtual and empty by default. A stop whose person or point is missing is
  left out.
- **The mission** (`mission.gd`):
  - A non-scripted start whose director has a tour plays the tour in place of the 2 s sweep.
  - The zoom eases from `INTRO_FROM_ZOOM` to `PLAY_ZOOM` over the first leg. The clock waits, as it does for the
    sweep.
  - The HUD shows the caption (`Hud.set_caption()`).
  - Space, Enter or a left click skips to the play position. The skipping click casts nothing. Esc pauses, as during
    the sweep.
  - `Mission.skip_intro()` ends a sweep or a tour at once. The `--show` photos of play call it, so they keep showing
    play. A new `--show=tour` photographs Mira's House's tour at its second stop.
- **The caption** sits on a dark plate centred above the slot row, in `SIZE_BODY`, with a dim `SPACE TO SKIP` in
  `SIZE_SMALL` under it.
- **Tours** (the camera then lands on the mission's `camera_at`):
  - Mira's House:
    1. the door, "Mira's house. Her journal is inside.";
    2. the Temple's door, "The Temple. Faithful who see you run here.";
    3. Venn, "Venn, the Inquisitor. Soon she searches the houses.".
  - Broken Lanterns:
    1. the first standing shrine, "A lantern. Break it, then let it drain.";
    2. the flame-bearer, "The flame-bearer relights broken lanterns.";
    3. the Temple's door, "The Temple. Lantern Knights come out of it later.".
  - The Vigil Flame:
    1. the lantern, "Halcyon's flame, carried by the Vigil.";
    2. Mira's shrine, "Mira's shrine. The flame must come here.";
    3. the Temple's door, "The Temple. The flame must not go home.".
- **When it plays:** on every start of these missions, retries included. The skip makes that cheap.

## 6. Out of scope

- Tags for the board missions (The Long Night's acts, Last Judgement). The other session adopts `tags()`.
- The Warning keeps its marker.
- No change to any director's rules, balance or timings. Tags, hints and tours only read.
- No new art.

## 7. Gates

- Tests: all pass, with the new checks.
- FLOW: 86 or more checks, 0 failures.
- State digest, `crowd_check` and the 10 exact behaviour checksums: identical to `kak-v0.10`.
- Night 2 references:
  - Mira's House play checksum: `-200101558`.
  - Broken Lanterns none seed 1 checksum: `424350965`.
  - Vigil Flame none seed 1: same outcome.
  - Feast play seed 1: same outcome.
- Mission test: unchanged.
- Photos: `--show=miras`, `lanterns`, `flame` and `tour` read clearly.
