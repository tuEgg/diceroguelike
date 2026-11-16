# Run state, saving and loading

## Where run state lives

- `oRunManager` (persistent, created in `rmMap`): `credits` (gold), `keepsakes` (ds_list), `items` (array, `max_items` slots), `tools` (ds_list) and `tools_scale`, `active_bounty`, `dutchman_taken`, `voyage`, `bonus_dice_next_combat`, `show_consumables_chance`, item/bag UI state, buff templates (`define_buffs_and_debuffs`).
- Globals: `global.player_hp`, `player_max_hp`, `player_alignment` (0–100), `player_luck` (50 normal), `hand_size`, `dice_bag`, `discard_pile`, `player_debuffs`, the master lists, `ui_layer`, `ui_scale`. About 130 globals in all; oRunManager's Create is the main place they start.
- `oWorldManager` holds map and chapter state (see map-and-chapters.md).

## Run lifecycle

- `start_run()` (scHelpers): from the main menu; if a save exists, asks before overwriting; goes to `rmMap` where the run objects are created.
- Continue sets `global.loading_game`; `oRunManager/Alarm_0` calls `load_game(1)` one step after creation.
- `lose_run()`: deletes the save; in combat sets `PLAYER_DEAD`, otherwise back to the menu. Beating the last chapter also deletes the save.
- Returning to `rmMainMenu` destroys `oRunManager`, `oWorldManager`, `oBountyController` (`oMainMenu/Other_4`).

## Saving: scSaving

- File `save_slot_1.json` (JSON of one struct). `SAVE_VERSION` (2): `save_exists` and `load_game` ignore other versions and unreadable files.
- **When it saves**: map Room Start (`oRunManager/Other_4`), entering any node (`enter_node`, before the node is marked cleared), when a draft is rolled, on each draft pick, on Embark, at a new chapter.
- **What it saves**: HP, gold, alignment, luck, items, tools, keepsake ids (in order), dice bag (name, value, distribution, min_roll_bonus), chosen pages and `pages_shown` (with each node's remembered `encounter`, `event_roll`, `event_name`, `shop_stock`, `treasure_keepsake`), map counters and odds, encounter pools, chapter, boss flag, boat position, book page art, active bounty, bounty board, seen events, keepsake/tool pools, Dutchman, voyage, bonus dice, consumable chance.
- **Random numbers**: GameMaker can't read the RNG position, so each save reseeds with a new random seed and stores it; `load_game` sets it last.
- **Not saved on purpose**: keepsake `state` (per-turn/per-fight flags only); anything mid-room (quitting mid-fight returns to the map before that node).
- New fields: add to `save_game`, read in `load_game` behind `variable_struct_exists` so older saves still load. Use `""`/`-1` for "none" rather than `undefined` in node data.
- Lookups by name/id: `get_die_by_name`, `get_item_by_name`, `get_keepsake_by_id`, `get_tool_by_name` (call inside `with (oRunManager)`), `get_node_by_name`, `deserialise_die`.

## Settings

`settings.json` (resolution, volumes, fullscreen) via `save_settings` / `load_settings` / `check_settings`; UI in `oSettingsMenu` and `scSettings`. Debug settings live separately in `debug_settings.json` (see ui-and-debug.md).
