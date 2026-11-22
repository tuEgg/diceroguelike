# Rooms: shop, event, bounty, treasure, workbench

Each room has a manager object created by the room; most of its logic and clicks are in that object's Draw GUI. Exit buttons send you back to `rmMap`.

## Shop: `oShopManager`, `scShop`

- `stock_shop()` builds `shop_dice_options`, `shop_consumable_options`, `shop_keepsake_options`, `shop_tool_options` from `oWorldManager.current_node.shop_stock` (names) or rolls fresh (debug jumps). `roll_shop_stock()` rolls with shop odds and returns names.
- Reward generators (also used by combat rewards, bounties, treasure): `generate_dice_rewards`, `generate_item_rewards` (both take `_for_room` to choose odds), `generate_keepsake_rewards` (skips owned and the bounty's keepsake), `generate_tool_rewards`. Each has a 500-attempt safety net.

## Events: `oEventManager`, `scEvents`

- `define_events()` builds `global.master_event_list`: structs `{ name, description, options: ds_list }`, each option `{ title, description, effect(ctx), result }`. Effects set `oEventManager.event_complete` and `event_selected`; `alternate_exit` can redirect the exit (Sirens → shop). Alignment changes go through `gain_alignment(amount, x, y)` (scParticles): motes (oParticleAlignment) coloured by `alignment_colour` fly to `alignment_target()` and move the compass as they land. The Siren's Call upgrades by alignment: `sirens_upgrade_count`, `sirens_upgrade`. An option's `description` may be a function (worked out as it's drawn).
- After an option is chosen, the event text is replaced by that option's `result` line, so every option needs a real sentence there (never a placeholder).
- `generate_event()` picks the node's remembered `event_name`, or a debug-forced one, or random, and removes it from the list (seen events are saved).
- Hovering a choice explains the game words in it (`event_terms`: alignment, luck, shop keepsake, max health). Many option effects open a dice picker via `oRunManager.dice_selection` and `dice_selection_event`.
- Dice an event hands you are `oDice` in hand: a click sends one to the bag as an `oDiceParticle` (oDice Step, F149), except while the plank waits (`deleting_die == 1`), when they drag.

**Look (UI rework):** events draw as a paper page (`ui_paper`, `ui_paper_text`) with option slips; every room leaves through `ui_primary` "Continue" bottom right (`exit_btn` is its { hover, click }).

## Bounty board: `oBountyController` (persistent), `scBounties`

- Created once per run in `rmMap`; drawn only in `rmBounty`. Offers 2 contracts (intended) and a free potion, drawn as the "On the house" card bottom left (oBountyController Draw GUI: `potion`, a Take it button with `potion_btn_scale`, greyed when `oRunManager.has_space_for_item` is false; a Taken stamp after).
- Contract `{ enemy_name, condition, rewards [item, keepsake, die], elite_encounter, complete }`; conditions in `condition_list` have `trigger(event, data)` that sets `failed`. Taking one sets `oRunManager.active_bounty`; the bounty elite replaces `possible_elites` until fought.
- Rerolling the board (10 gold) clears `oRunManager.active_bounty`, so a contract can only be active while it is on the board. Contract names come from `generate_bounties` (Elite 1 and Elite 3 are both Pirate Captain fights).
- Saved with the run: `serialise_bounty_board` / `deserialise_bounty_board`.

## Treasure: `oTreasureManager`

One keepsake from the node's `treasure_keepsake` (or rolled), revealed by opening a chest. Continue with the chest closed or the keepsake untaken asks first: it reads "Leave it?" (danger frame) for 3 s (`exit_confirm` frames) and a second click leaves (B136).

## Workbench: `oWorkbenchManager` (the free bench, F224)

- **No slots** (Jared, 2026-11-22; mockup `docs/mockups/workbench-freeform.html`). The manager draws everything in Draw GUI and handles input in Step: a plank table (`table`), a pegboard rack on the right (`rack`) with the tools you own, the dice on the table as structs (`wb_dice`: { die, x, y, scale (springy, `sv`), rot, flash, hop, vx, vy, fly }), drawn by `wb_draw_die` with `draw_die`. No `oDice` instances here, and the old `oDrill` / `oHammer` / `oScissors` objects aren't created any more (their sprites are drawn; the objects only identify tools in `oRunManager.tools`).
- **Dice:** the bag icon (any time) or the note on the bench opens the picker for as many dice as you like (`workbench_open_picker`, up-to mode, the whole bag); `workbench_take_die` flies each onto a free spot (`fly`, staggered). Drag dice anywhere; they nudge apart so they never stack. Drop one on the bag to put it back. Continue sends every die on the table back (oDiceParticle adds each as it lands) and returns a loaded core to the top bar.
- **Tools** (`wb_tools`: kind, sprite, hx/hy = the working point: the drill's tip, the hammer's head, where the blades cross; `wb_tool_origin` / `wb_tool_box` work the sprite out from it at `wb_tool_k` scale). Grab one, carry it, let go: `wb_tool_target` says what it would do there (shown by the tool, with brass or red rings on the dice), and a valid drop starts `wb_job` (an animation whose craft happens on its impact frame). Right click or the rack puts a tool back. Misses cost nothing; each tool crafts once per visit (`workbench_tool_used` sets `used`: greyed on the rack with a paper "Used" tag).
- **Drill:** drag a core from the top bar onto the drill (`workbench_take_core`, called by oRunManager on release; `wb_socket` is the chuck), then drop the drill on a die (not a coin): it gets the core's `distribution`. **Hammer:** let go over the gap between two dice at most 200 px apart (`wb_pair_at`): same action type and 12 sides or fewer, they become one die (sizes added, `die_size_changed`) under the head; otherwise they jump apart. **Cutters:** drop on a die bigger than a coin: it loses 2 sides (`die_size_changed`; cut to a coin, its core is lost) and a fresh coin of its type hops out beside it.
- Tips: `workbench_bag` (the note), `workbench` (the rack), `workbench_drill` (`workbench_drill_waits`: an empty drill and a core in your items).
- **At sea (F02):** finishing a page (oWorldManager Step, when `nodes_til_page_cleared` hits 0) sets `oRunManager.can_visit_workbench`; whether a tool has work (`workbench_useful()`: the Hammer or Cutters, or the Drill with a core in your items) is checked when the buoy or strait shows; the map floats a buoy on the way to the next island (`sea_buoy_draw`, see map-and-chapters.md), or at a spread's end the buoy is one of the strait's stops; sailing past clears it.
