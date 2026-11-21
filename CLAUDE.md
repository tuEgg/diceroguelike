# Tides of Fortune

A dice-building roguelike in GameMaker (GML), by Jared (solo, hobby). Sailing theme: the run is a captain's logbook of 3 chapters; each chapter is 3 drafted spreads then a boss. Combat is built by playing dice into an action queue of slots.

**Start here every session:** read `KANBAN.md` (what's open, in testing, decided) and the context doc for the system you're about to touch (table below). Only open the big `.gml` files once a context doc has told you where to look.

## How we work

- Claude can't run GameMaker. Every change is unverified until Jared play-tests it.
- **Branches (agreed 2026-11-19):** `main` is what's live on itch.io, tagged per upload (`v0.1.1`, `v0.1.2`...). `dev` is the next version (v0.2). New work goes on a short branch off `dev` and merges into `dev`. A bug in the live build gets a `hotfix/...` branch off `main`; once approved it merges into `main`, is tagged, and `main` is merged into `dev`. Release: `dev` into `main`, tag, upload. `GAME_VERSION` (scSaving) is the number in the menus: `0.2.0-dev` on dev, the plain number on main.
- Commit in themed batches, each with a short "how to test" list for Jared. Merge and push **only when Jared approves**. Remote is HTTPS; pushing opens a browser sign-in once.
- **Update `KANBAN.md` in the same commit as the work.** Jared's dashboard (`tools/kanban`, `node tools/kanban/server.js`, localhost:4747) renders it: each `## ` heading is a column, table rows with an ID are cards, the IN TESTING table badges cards in testing, approved cards move to the DONE table.
- **Update the matching `docs/context/*.md` in the same commit** when you change how a system works (new function, moved responsibility, new rule). Keep them short and true; delete what goes stale.
- **Game text is as short and clear as it can be** (Jared, 2026-11-21). Tooltips, notes, buttons and descriptions say what a thing does and nothing more: no restating where it is or when it comes up, no "click to..." the screen already shows, no hedged asides in brackets. "Remove a die from your bag." not "Choose a die to throw overboard, so the ones you want come up more often." Over-explaining reads as written by AI.
- Match the surrounding code: tabs, `var` locals, `_underscore` params, lowercase comments that say why. Most `.gml` files are CRLF; keep a file's line endings (edit with tools that preserve them).
- `debug_mode` is only F6 runs. Use the `DEBUG_TOOLS` macro (scDebug) for anything testing-only: true whenever run from the IDE, never in exported builds.

## Map of the code

| Area | Context doc | Main files |
|---|---|---|
| Combat: turn loop, rolling, slots, buffs, enemies | `docs/context/combat.md` | `objects/oCombat`, `scripts/scCombatScripts`, `scDebuffs`, `scEnemies` |
| Dice, keepsakes, items, the effect events they hook | `docs/context/dice-keepsakes-items.md` | `scDice`, `scKeepsakes`, `scItems`, `objects/oDice` |
| World map, book, chapters, nodes, encounters | `docs/context/map-and-chapters.md` | `objects/oWorldManager`, `scripts/scMap` |
| Rooms: shop, event, bounty, treasure, workbench | `docs/context/rooms.md` | `scShop`, `scEvents`, `scBounties`, `oShopManager`, `oEventManager`, `oBountyController`, `oTreasureManager`, `oWorkbenchManager`, `oHammer/oScissors/oDrill` |
| Run state, saving and loading | `docs/context/run-and-saving.md` | `objects/oRunManager`, `scripts/scSaving`, `scHelpers` (start/lose run) |
| UI helpers, display, debug menu and hotkeys | `docs/context/ui-and-debug.md` | `scHelpers`, `scDisplay`, `scSettings`, `scDebug`, `objects/oDebugger` |

## Big-picture rules that bite

- **Input and game logic often live in Draw GUI events** (immediate-mode UI). A click is handled where the button is drawn. Draw order (object depth) decides what gets the click.
- **Persistent managers:** `oRunManager`, `oWorldManager`, `oBountyController`, `oCutsceneManager` live in `rmMap` and persist; returning to `rmMainMenu` destroys the first three (fresh run). `oDebugger`, `oSettingsMenu`, `oSoundController`, `oMainMenu` start in `rmMainMenu`.
- **Never mutate shared definitions.** Enemies are copied per fight (`enemy_copy_for_fight`), buffs are cloned by `apply_buff`, dice by `clone_die`. Write to the copy.
- **Slot bonuses go through `slot_add_bonus` / `slot_set_bonus`**, never `slot.bonus_amount` directly.
- **Saves are versioned** (`SAVE_VERSION` in scSaving). Add new save fields as optional on load (`variable_struct_exists`) rather than bumping the version, unless old saves truly can't load.
- **Use `ds_safe_exists(id, type)`, never `ds_exists`.** Freed lists are set to `undefined`, and the web build stops with an error on `ds_exists(undefined)` (desktop just returns false).
- `KANBAN.md` IDs: B = bug, T = tech debt, F = feature, H = housekeeping, M = map work, Q = open question.
