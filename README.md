# kak-board

This branch holds only the data for the KAK project board in the Discord `#board` channel. It has no game code; the game is on `feat/Develop-Main`.

- `board/board.py`: builds the board and sends it to Discord.
- `board/board.json`: the last board's data (tasks, branches, recent changes).
- `board/payload.json`: the Discord messages built from that data.
- `board/state.json`: the ids of the board messages in `#board`. The Action writes this file.
- `.github/workflows/discord-board.yml`: runs on each push to this branch and edits the board messages in place.

## Refreshing the board (Claude, after any Dev Ledger update)

The worktree is `C:/BURIN_NITRO/Godot/GIT/vfxProve-board`.

1. Dump the Ledger with the ArtifactData tool (Ledger URL: https://claude.ai/artifact/6zL2bsrt3H1Vnehk1RkfiK):
   - `list` with collection `tasks`, `query.limit` 1000 and `out_dir` `C:/BURIN_NITRO/Godot/GIT/vfxProve-board/dump`
   - `get` with collection `meta`, doc_id `project` and the same `out_dir`
2. Run:

   ```bash
   python C:/BURIN_NITRO/Godot/GIT/vfxProve-board/board/board.py publish --dump C:/BURIN_NITRO/Godot/GIT/vfxProve-board/dump
   ```

   This builds the board from the dump and from every local and pushed branch. If anything changed, it commits and pushes `kak-board`.

A Ledger task's optional `branch` field puts it under that branch's section. Tasks with no `branch`, or with a branch that is no longer active, are listed under `feat/Develop-Main`.

The repo is public, so `board.json` is too. It holds task titles, branch names and their latest commit subjects. It does not hold task notes.
