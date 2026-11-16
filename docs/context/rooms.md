# Rooms: shop, event, bounty, treasure, workbench

Each room has a manager object created by the room; most of its logic and clicks are in that object's Draw GUI. Exit buttons send you back to `rmMap`.

## Shop: `oShopManager`, `scShop`

- `stock_shop()` builds `shop_dice_options`, `shop_consumable_options`, `shop_keepsake_options`, `shop_tool_options` from `oWorldManager.current_node.shop_stock` (names) or rolls fresh (debug jumps). `roll_shop_stock()` rolls with shop odds and returns names.
- Reward generators (also used by combat rewards, bounties, treasure): `generate_dice_rewards`, `generate_item_rewards` (both take `_for_room` to choose odds), `generate_keepsake_rewards` (skips owned and the bounty's keepsake), `generate_tool_rewards`. Each has a 500-attempt safety net.

## Events: `oEventManager`, `scEvents`

- `define_events()` builds `global.master_event_list`: structs `{ name, description, options: ds_list }`, each option `{ title, description, effect(ctx), result }`. Effects set `oEventManager.event_complete` and `event_selected`; `alternate_exit` can redirect the exit (Sirens → shop).
- After an option is chosen, the event text is replaced by that option's `result` line, so every option needs a real sentence there (never a placeholder).
- `generate_event()` picks the node's remembered `event_name`, or a debug-forced one, or random, and removes it from the list (seen events are saved).
- Many option effects open a dice picker via `oRunManager.dice_selection` and `dice_selection_event`.

## Bounty board: `oBountyController` (persistent), `scBounties`

- Created once per run in `rmMap`; drawn only in `rmBounty`. Offers 2 contracts (intended) and a free potion.
- Contract `{ enemy_name, condition, rewards [item, keepsake, die], elite_encounter, complete }`; conditions in `condition_list` have `trigger(event, data)` that sets `failed`. Taking one sets `oRunManager.active_bounty`; the bounty elite replaces `possible_elites` until fought.
- Rerolling the board (10 gold) clears `oRunManager.active_bounty`, so a contract can only be active while it is on the board. Contract names come from `generate_bounties` (Elite 1 and Elite 3 are both Pirate Captain fights).
- Saved with the run: `serialise_bounty_board` / `deserialise_bounty_board`.

## Treasure: `oTreasureManager`

One keepsake from the node's `treasure_keepsake` (or rolled), revealed by opening a chest.

## Workbench: `oWorkbenchManager`, tools `oHammer`, `oScissors`, `oDrill`

- Three slots: `workbench_slot[0]` die, `[1]` die or core, `[2]` output. Dice are dealt from the bag as `oDice` instances; drag tools onto the Craft button.
- Dropping a die (`oDice/Step_0`, on release) works out the target slot from the mouse position there and then; a die can move between the two input slots or be dropped back on its own.
- Hammer merges two same-type dice; Cutters take faces off and output a coin; Drill applies a core's distribution. One craft per visit (`crafting_state`). Hammer and Cutters call `die_size_changed`, so a die cut to a d2 becomes a coin (gains Coin) and a hammered coin stops being one; Cutters' output coin is a fresh d2 coin. Descriptions update by themselves (see dice-keepsakes-items.md).
- Reached from the map's "Visit the workbench" button after each node (`oRunManager.can_visit_workbench`); whether that stays is open (KANBAN F02/Q8).
