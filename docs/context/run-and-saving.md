# Run state, saving and loading

## Where run state lives

- `oRunManager` (persistent, created in `rmMap`): `credits` (gold), `keepsakes` (ds_list), `items` (array, `max_items` slots), `tools` (ds_list) and `tools_scale`, `active_bounty`, `dutchman_taken`, `voyage`, `bonus_dice_next_combat`, `show_consumables_chance`, item/bag UI state, buff templates (`define_buffs_and_debuffs`).
- Globals: `global.player_hp`, `player_max_hp`, `player_alignment` (0–100), `player_luck` (50 normal), `hand_size`, `dice_bag`, `discard_pile`, `player_debuffs`, the master lists, `ui_layer`, `ui_scale`. About 130 globals in all; oRunManager's Create is the main place they start.
- `oWorldManager` holds map and chapter state (see map-and-chapters.md).

## Run lifecycle

- `start_run()` (scHelpers): from the main menu; if a save exists, asks before overwriting; goes to `rmMap` where the run objects are created.
- Continue sets `global.loading_game`; `oRunManager/Alarm_0` calls `load_game(1)` one step after creation. A new run instead sets `new_run_offering` (F04): oRunManager Draw GUI calls `offering_draw` (scHelpers): "The quartermaster's offer", a logbook page with three cards (`offering_card_draw`: the die, its effect, its core and how the core shapes its faces), a popup (map locked; Step re-asserts `UI_LAYER.POPUP`). Click a card to choose (`offer_selected`), then the button runs `offering_take`: the die flies to the bag with the core already fitted (no core item). Coins are never offered (oRunManager Create swaps them out). The flag is saved, so reloading before picking offers again.
- `lose_run()`: in combat sets `PLAYER_DEAD`; names the enemies still standing; then `run_end(false, cause)`. Beating the last chapter calls `run_end(true, ...)` from the chapter-end "Finish the voyage" button. `run_end` deletes the save and sets `oRunManager.run_over`; `run_summary_draw` (Draw GUI End) shows the stats until Back to the menu.
- Run stats (F05): `oRunManager.run_stats` (`run_stats_new`), bumped with `run_stat_add` / `run_stat_max` (fights/elites/bosses in `win_fight`, damage dealt and taken in `process_action`, dice played, gold in `oParticleCoin` Destroy). Saved with the run as `run_stats` (optional on load). Also optional: `shipwright_wait` (sea stop odds) and `ink_egg_found` (the ink easter egg, once a run).
- Pause (F35): Escape or Tab in a run (and the top bar's menu cog, F74) closes Settings, then the bag, then toggles `pause_open` / `pause_close` (oRunManager Step). `paused` holds `UI_LAYER.SETTINGS`; oCombat Step exits while paused. Settings opened from the pause menu returns to it.
- Returning to `rmMainMenu` destroys `oRunManager`, `oWorldManager`, `oBountyController` (`oMainMenu/Other_4`).

## Saving: scSaving

- File `save_slot_1.json` (JSON of one struct). `SAVE_VERSION` (2): `save_exists` and `load_game` ignore other versions and unreadable files.
- **When it saves**: map Room Start (`oRunManager/Other_4`), entering any node (`enter_node`, before the node is marked cleared), when a draft is rolled, on each draft pick, on Embark, at a new chapter.
- **What it saves**: HP, gold, alignment, luck, items, tools, keepsake ids (in order), dice bag (name, value, distribution, min_roll_bonus), chosen pages and `pages_shown` (with each node's remembered `encounter`, `event_roll`, `event_name`, `shop_stock`, `treasure_keepsake`), map counters and odds, encounter pools, chapter, boss flag, boat position, book page art, active bounty, bounty board, seen events, keepsake/tool pools, Dutchman, voyage, bonus dice, consumable chance.
- **Random numbers**: GameMaker can't read the RNG position, so each save reseeds with a new random seed and stores it; `load_game` sets it last.
- **Not saved on purpose**: keepsake `state` (per-turn/per-fight flags only); anything mid-room (quitting mid-fight returns to the map before that node).
- New fields: add to `save_game`, read in `load_game` behind `variable_struct_exists` so older saves still load. Use `""`/`-1` for "none" rather than `undefined` in node data.
- Lookups by name/id: `get_die_by_name` (it maps the old names "Intel", "Intel.", "Ink", "Ink.", "Inteli Die" to the new ones, so old saves load), `get_item_by_name`, `get_keepsake_by_id`, `get_tool_by_name` (call inside `with (oRunManager)`), `get_node_by_name`, `deserialise_die`.

## Settings

`settings.json` (resolution, volumes, fullscreen, `combat_speed_index`) via `save_settings` / `load_settings` / `check_settings`; UI in `oSettingsMenu` and `scSettings`. Debug settings live separately in `debug_settings.json` (see ui-and-debug.md).

`progress.json` (scSaving, PROGRESS): what this player has seen, apart from runs: `intro_seen`, `tutorial_done`, `tips_seen`. Loaded in oSettingsMenu Create (`progress_load`), read with `progress_get`, changed with `progress_set` (saves at once). One-time tips: `tip_seen(id)` / `tip_mark_seen(id)`. Settings > Gameplay > Tutorial next run calls `progress_set_tutorial` (on also clears the tips). The intro cutscene has `progress_key: "intro_seen"`, so it plays once ever.
