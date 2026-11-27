# KAK God's Chamber: design (milestone 1, the working room)

Date: 2026-11-19. Source: the user's Discord #ideas post "God's Chamber" (2026-11-18), the concept image shared in chat, and the
answers given in chat on 2026-11-19. Branch: `feat/god-chamber` (worktree `vfxProve-chamber`), cut from feat/Develop-Main acb82b96.

## 1. Goal

Between nights the god game shows a plain text hub (`GodHub`). Replace it with a room, the God's Chamber: a fixed-view, layered
2D scene whose objects are the ways on. Clicking an object zooms toward it and opens the page that exists today. This milestone
builds the room's function with placeholder ("greybox") art, so the layout and the feel can be played and changed before any art
is painted.

Success: a player can do everything the hub does today, from the room, with no extra click per night; the user has played it and
settled the layout; the whole test suite, all replay references and the windowed play-through pass.

## 2. Scope

In this milestone:

- A new screen `GodChamber` that replaces `GodHub` on `Game.Screen.HUB`.
- Four stations: World table (Descend), Ability Tree, Faith altar, Rite door (Awaken).
- A slim top bar with the god's status, and the hub's warning lines.
- Zoom-and-fade transitions between the room and its pages.
- Greybox art drawn by code, with a texture hook for the final art.

Not in this milestone (later steps, each with its own spec where noted):

- Final painted art (step 6; the user paints with the ChatGPT pipeline from this milestone's layout).
- Idle life and state objects in the room: flames, portal, candles per milestone (step 7).
- The World Map page and Conquer Progress (step 8; own spec). Until then the World table is Descend.
- Per-god room variants (step 9).
- The tier board, campaign and title menus: untouched.

## 3. Rules that do not change

The Chamber emits the same `action(name)` signal as the hub, with the same names: "descend", "awaken", "tree", "faith", "title",
"awaken_dev". `Game._on_hub_action` and the `hub:*` routes stay as they are. Saves, the god's file, the Hunt, the rites and the
draft are untouched. Every refusal the hub gives today is kept, word for word:

- Nothing to draft: Descend and Awaken buzz; `GodHub.BLOCKED` is shown.
- Capped with no rite written and no Hunt due: Awaken buzzes and shows `RITE_UNWRITTEN`.
- Dev build, A key, not capped: the dev Awaken hook; refused with `AWAKEN_HUNT` while the Hunt is due.

## 4. Structure

| Unit | File | Job |
|---|---|---|
| `HubStatus` | `src/game/ui/hub_status.gd` (new, RefCounted) | The hub's words and state, moved out of `GodHub` unchanged: `lines()`, `bar_text()`, `gifts_line()`, `notice_fill()`, `hunt_line()`, `seal_line()`, `can_descend()`, `blocked_line()`, `awaken_state`, `awaken_dim()`, and the constants `BLOCKED`, `HUNT_DUE`, `SEALED`, `AWAKEN_HUNT`, `RITE_UNWRITTEN`, `GIFTS_LINE`. |
| `ChamberLayout` | `src/game/ui/chamber_layout.gd` (new, static data) | The room's size, the layers, and one row per station: key, name, rect, zoom focus, layer, hotkeys. The only place a position is written. |
| `GodChamber` | `src/game/ui/god_chamber.gd` (new, Node) | The screen: input, hover, badges, the top bar, the transitions, drawing. Emits `action`. |
| `ChamberArt` | `src/game/ui/chamber_art.gd` (new, static) | Draws one layer or station: its texture if `res://assets/chamber/<name>.png` exists, else the greybox shape. |
| `GodHub` | `src/game/ui/god_hub.gd` | Deleted. `tests/test_faith_hub.gd` moves to `HubStatus` and `GodChamber`. |

`Game` builds `GodChamber` where it built `GodHub`, and passes one more value: the station the player is coming back from
("tree", "faith" or ""), so the room can start zoomed on it and pull back.

## 5. The room

- Coordinates are the UI layer's 640 x 360 design units (`UiScale.design_frame`), drawn at the real screen resolution.
- The room is 840 x 360 units: 100 units wider than the frame on each side, so a 21:9 window shows more room and a 16:9 window
  shows the middle 640. Stations all sit inside the middle 640.
- Four layers, back to front, each with a parallax factor: back wall 0.25, stations 0.5, table 0.75, desk 1.0. The mouse's offset
  from the screen centre moves a layer by at most `PARALLAX_MAX` (6 units) times its factor. Parallax moves the picture only:
  hit rects follow their layer, so what is drawn is what is clicked.

### Stations

| Key | Name shown | Place (first layout) | Action | Keys |
|---|---|---|---|---|
| `descend` | World Table | centre, on the table layer | "descend" | Enter, 1 |
| `tree` | Ability Tree | left | "tree" | T, 2 |
| `faith` | Faith Altar | right | "faith" | F, 3 |
| `awaken` | Rite Door | back wall, left of centre | "awaken" | A, 4 |

The first layout's rects follow the concept image; they are data and are expected to move after the user's play test.

Station states:

- **Idle:** drawn plain, no label.
- **Hover:** a 1-unit gold outline around the station's rect and its name plate under it; `ui_hover` plays once on entering.
- **Dim:** drawn at 45% brightness. `descend` is dim when there is nothing to draft; `awaken` is dim when `awaken_dim()`.
  A click on a dim station buzzes and shows its reason, as the hub does.
- **Rite door, not capped:** the door is drawn closed and dark, has no hover and no label, and a click does nothing. The A key
  keeps the dev hook. When the god is capped the door is lit and behaves as a station.
- **Badge:** a red "!" disc at the station's top-right corner. `tree` has it while the god has unspent ability points; `faith`
  while the god can afford at least one row of `GodSlot.FAITH`; `awaken` while a rite is ready or the Hunt leads from Awaken.

### Top bar

A 22-unit strip across the top, anchored to the real screen edges (it does not shift with parallax):

- Left: the god type's title, then "Level n" and the tier's name.
- Centre: the Divine Power bar with `bar_text()` inside it.
- Right: ability points (gold when above 0), Faith, the Lantern Notice meter with its percent, "Night n", and a small Title button.

Under the bar, centred, in red and only when they apply: the Hunt line, the sealed-ability line. At the bottom, centred: the
one-off line (wrapped to 600 units), the blocked line, the stolen-gifts line in gold, and the keys hint in dim text.

## 6. Transitions

- **Out:** a click or hotkey on an open station plays `ui_click`, then the room scales about the station's zoom focus from 1.0
  to `ZOOM_TO` (2.2) over `ZOOM_TIME` (0.35 s, ease in-out) while a black fade rises from 0 to 1 over the last 40% of it. At the
  end the Chamber emits the action and `Game` shows the page.
- **Back:** when `Game` rebuilds the Chamber after "tree:back" or "faith:back" it passes that station's key; the room starts at
  `ZOOM_TO` on it, fully faded, and plays the same motion in reverse.
- **Skip:** any click or key during a transition finishes it at once (out: the action is emitted; back: the room is at rest).
- **Input:** stations take no new action while a transition plays, other than the skip.
- **Off switch:** `GodChamber.transitions` (static, default true). `Game` sets it false for FLOW, for `--capture`, and when run
  headless; tests set it as they need. With it false, actions are emitted in the same call as the click, as the hub does today.
- Title (Esc or its button) and the dev Awaken do not zoom: they act at once.

## 7. Art hook

`ChamberArt.draw(canvas, name, rect, state)` looks for `res://assets/chamber/<name>.png` (names: `wall`, `table`, `desk`,
`descend`, `tree`, `faith`, `awaken`, `awaken_closed`). Found: the texture is drawn in the rect, nearest-neighbour. Not found:
the greybox shape, a flat silhouette in the station's own colour with a darker base, enough to tell the four apart. Step 6 only
adds PNG files and, if the painted sizes differ, edits `ChamberLayout`.

## 8. Errors and edge cases

- A missing or unreadable texture falls back to the greybox; nothing is logged per frame.
- A window resize or aspect change while the room is open re-lays the bar and keeps the stations clickable (the existing UI
  resolution tests' sizes: 1280x720, 1920x1080, 2560x1080, 1024x768).
- A transition in flight when the screen is torn down (pause, quit to title) is dropped without emitting.
- The mouse outside the window, or a window narrower than 16:9, clamps parallax to its maximum.

## 9. Tests

- `tests/test_hub_status.gd`: the status checks from `test_faith_hub.gd`, against `HubStatus`.
- `tests/test_god_chamber.gd`:
  - every station's rect is inside the middle 640 x 360, no two overlap, none is under the top bar;
  - click and each hotkey emit the right action; a dim station buzzes, emits nothing and shows its reason;
  - the Rite door: closed and dead when not capped; lit when capped; dim with `RITE_UNWRITTEN`; the dev A key;
  - badges follow points, affordable Faith and the rite;
  - parallax moves hit rects with their layer (a click on the drawn station hits at both mouse extremes);
  - transitions: the action arrives after `ZOOM_TIME`, not before; a second input skips; with `transitions` false it is immediate;
    arriving from "tree" starts zoomed and ends at rest; teardown mid-flight emits nothing;
  - the bar and stations at the four window sizes above.
- FLOW (`Game`'s scripted play-through) and `tools/dev/real_path_probe.gd`: their hub steps use the Chamber; step count unchanged.
- Landing gates: `run_suite_parallel.sh 8`, `refs_check.sh` (no row should move: the room changes no night), windowed FLOW alone.

## 10. Order of work

1. `HubStatus` moved out of `GodHub`, tests moved; `GodHub` still draws with it. No behaviour change.
2. `ChamberLayout`, `ChamberArt` greybox, `GodChamber` with stations, top bar, hotkeys, badges; `Game` builds it; `GodHub` deleted;
   FLOW and the probe updated.
3. Parallax and transitions.
4. The user plays it; layout changes go into `ChamberLayout`.
5. Land on feat/Develop-Main after the gates.
