# Rooms: shop, event, bounty, treasure, workbench

Each room has a manager object created by the room; most of its logic and clicks are in that object's Draw GUI. Exit buttons send you back to `rmMap`.

## Shop: `oShopManager`, `scShop`

- `stock_shop()` builds `shop_dice_options`, `shop_consumable_options`, `shop_keepsake_options`, `shop_tool_options` from `oWorldManager.current_node.shop_stock` (names) or rolls fresh (debug jumps). `roll_shop_stock()` rolls with shop odds and returns names.
- Reward generators (also used by combat rewards, bounties, treasure): `generate_dice_rewards`, `generate_item_rewards` (both take `_for_room` to choose odds), `generate_keepsake_rewards` (skips owned and the bounty's keepsake), `generate_tool_rewards`. Each has a 500-attempt safety net.

## Events: `oEventManager`, `scEvents`

- `define_events()` builds `global.master_event_list`: structs `{ name, description, options: ds_list }`, each option `{ title, description, effect(ctx), result }`. Effects set `oEventManager.event_complete` and `event_selected`; `alternate_exit` can redirect the exit (Sirens → shop). Alignment changes go through `gain_alignment(amount, x, y)` (scParticles): motes (oParticleAlignment) coloured by `alignment_colour` fly to `alignment_target()` and move the compass as they land. The Siren's Call upgrades by alignment: `sirens_upgrade_count`, `sirens_upgrade`. An option's `description` may be a function (worked out as it's drawn).
- After an option is chosen, the event text is replaced by that option's `result` line, so every option needs a real sentence there (never a placeholder).
- `generate_event()` picks the node's remembered `event_name`, or a debug-forced one, or random, and removes it from the list (seen events are saved).
- Many option effects open a dice picker via `oRunManager.dice_selection` and `dice_selection_event`.
- Dice an event hands you are `oDice` in hand: a click sends one to the bag as an `oDiceParticle` (oDice Step, F149), except while the plank waits (`deleting_die == 1`), when they drag.

**Look (UI rework):** events draw as a paper page (`ui_paper`, `ui_paper_text`) with option slips; every room leaves through `ui_primary` "Continue" bottom right (`exit_btn` is its { hover, click }).

## Bounty board: `oBountyController` (persistent), `scBounties`

- Created once per run in `rmMap`; drawn only in `rmBounty`. Offers 2 contracts (intended) and a free potion, drawn as the "On the house" card bottom left (oBountyController Draw GUI: `potion`, a Take it button with `potion_btn_scale`, greyed when `oRunManager.has_space_for_item` is false; a Taken stamp after).
- Contract `{ enemy_name, condition, rewards [item, keepsake, die], elite_encounter, complete }`; conditions in `condition_list` have `trigger(event, data)` that sets `failed`. Taking one sets `oRunManager.active_bounty`; the bounty elite replaces `possible_elites` until fought.
- Rerolling the board (10 gold) clears `oRunManager.active_bounty`, so a contract can only be active while it is on the board. Contract names come from `generate_bounties` (Elite 1 and Elite 3 are both Pirate Captain fights).
- Saved with the run: `serialise_bounty_board` / `deserialise_bounty_board`.

## Treasure: `oTreasureManager`

One keepsake from the node's `treasure_keepsake` (or rolled), revealed by opening a chest. Continue with the chest closed or the keepsake untaken asks first: it reads "Leave it?" (danger frame) for 3 s (`exit_confirm` frames) and a second click leaves (B136).

## Workbench: `oWorkbenchManager`, tools `oHammer`, `oScissors`, `oDrill`

- Three slots: `workbench_slot[0]` die, `[1]` die or core, `[2]` output. Dice are dealt from the bag as `oDice` instances; drag tools onto the Craft button.
- A run starts with only the Drill (`oRunManager.tools`); the Hammer and Cutters sit in `global.master_tool_list` and are bought in shops (or the random-tool event), then leave the pool.
- Cores: the top bar (oRunManager Draw GUI) drags them; on release it calls `oWorkbenchManager.workbench_take_core(core, item_slot)`, which takes it if the mouse is over the empty middle slot. Done on the oRunManager side so draw order doesn't matter. A carried core or potion is drawn by `dragged_item_draw()` in oRunManager Draw GUI End, above every window.
- Dropping a die (`oDice/Step_0`, on release) works out the target slot from the mouse position there and then; a die can move between the two input slots or be dropped back on its own.
- Hammer merges two same-type dice; Cutters take faces off and output a coin; Drill applies a core's distribution. Each tool once per visit (`crafting_state`, `tools_used`). Hammer and Cutters call `die_size_changed`, so a die cut to a d2 becomes a coin (gains Coin) and a hammered coin stops being one; Cutters' output coin is a fresh d2 coin; a remainder cut down to a coin loses its core, and a coin can't be cut. With the Cutters (`button_text == "Cut"`) the slots read "Dice = Basic coin + Remainder" with a note under Remainder. While a tool is in hand, `draw_mouse_hint` shows what the left and right buttons do. First-visit tips (workbench, workbench_toolbag, workbench_drill) walk through it. Descriptions update by themselves (see dice-keepsakes-items.md).
- **At sea (F02):** finishing a page (oWorldManager Step, when `nodes_til_page_cleared` hits 0) sets `oRunManager.can_visit_workbench`; whether a tool has work (`workbench_useful()`: the Hammer or Cutters, or the Drill with a core in your items) is checked when the buoy or strait shows, so a core won at that last stop counts; the map floats a buoy on the way to the next island (`sea_buoy_draw`, see map-and-chapters.md), or at a spread's end the buoy is one of the strait's stops; sailing past clears it. On entering, a prompt on the bench (`pick_pending`, "Open the bag", or the bag icon) calls `workbench_open_picker`, which opens the bag's dice picker in "up to" mode (`dice_selection_up_to`) for `workbench_dice_allowance()` dice (one per tool, +1 with the Hammer); `workbench_take_die` moves each chosen die from the bag to your hand. Each tool crafts once per visit (`tools_used`; `workbench_tool_used` sets the tool's `tool_used`: it lingers in hand for half a second, then rests greyed at its spot and skips the rest of its Step). A craft no longer discards your hand; clicking a finished (still) die sends it to the bag (a particle that adds it when it lands), and the Step resets `crafting_state` to "waiting" once the bench is clear. Until the first craft (`workbench_can_change_dice()`: nothing in `tools_used`, not picking) a "Change dice" button left of the bench calls `workbench_change_dice()`: your hand goes back in the bag and the picker opens again (B134).
