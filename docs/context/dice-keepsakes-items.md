# Dice, keepsakes and items

All three are structs with effects that hook named events. Definitions are built once per run from `oRunManager/Create_0` (`generate_dice_bag`, `define_items`, `define_keepsakes`).

## Dice: scDice

- `make_die_struct(amount, value, action, possible_type, permanence, name, description, rarity, price, effects, distribution)`; fields also include `min_roll_bonus`, `rolled_value`, `forced_roll`, `roll_twice`, reset hooks, `statistics`, `uid`.
- Each die is a `global.die_*` template registered with `ds_list_add(global.master_dice_list, clone_die(global.die_x, ""))` right after it. Also `global.starter_dice_list`, `global.alignment_dice_list`.
- `clone_die(src, permanence)` deep-copies. **Copies keep the uid**; anything that makes a second live copy gives it `global._die_uid_counter++` (bag dice get fresh uids at every room start in `oRunManager/Other_4`).
- Effects that should only react to their own die check `_context.die.uid == _context._die_struct_source.uid` (or `_d_struct.uid` for `on_dice_played_to_slot`).
- Keywords (Coin, Sticky, Exclusive, Loose, Stowaway, Favourite, Multitype, Followthrough) are data: each die has a `keywords` array, set right after its definition (`global.die_x.keywords = ["Coin"];`). Check with `die_has_keyword(die, "Coin")`, add with `die_add_keyword(die, "Coin")` (also prefixes the description). Saved with each bag die. Icons (`draw_dice_keywords`) and a die's own tooltip keyword boxes read the list too; `string_has_keyword` is only for searching other text (keepsake and item descriptions).
- Show a die's text with `die_description(die)`, never `die.description` directly: descriptions can hold `{min}`, `{max}`, `{min2}`, `{max2}`, `{half}`, filled in from the die's current value and min_roll_bonus, so upgrades change the text too.
- `deal_single_die` draws from `global.dice_bag` (reshuffles the discard pile; the F1 menu can inject a die via `debug_take_next_die`). `oDice` is the in-hand instance (`struct` holds the die).
- Permanence strings: `"base"` (stays a turn), `"temporary"`, `"temporary none"`, `"sticky"`.
- Colour: `get_dice_color(die.possible_type)` (not `action_type`), so multitype dice blend their types' colours.

## Keepsakes: scKeepsakes

- Struct `{ _id, name, desc, sub_image, state, trigger: function(event, data) }`, optional `price`, `replaces` (id it swaps out in place, e.g. Deep Lens → Looking Glass).
- Lists: `global.master_keepsake_list` (all), `rollable_keepsake_list` (rewards/elites/treasure), `shop_keepsake_list`, `boss_keepsake_list`. Owned: `oRunManager.keepsakes` (ds_list, order = bar order).
- `gain_keepsake(ks, list_to_remove_from)` then fires `on_keepsake_acquired`. `get_keepsake_by_id` returns the master struct (shared).
- `runmanager_trigger_keepsakes(event, data)` calls every owned keepsake's `trigger`; each filters by event. `trigger_keepsake_visual()` pops its icon.
- Sprite: `sKeepsake`, frame `sub_image`.

## Items (consumables and cores): scItems

- Struct `{ sprite, index, name, description, type: "consumable"|"core", distribution, rarity, price, effects: { trigger, flags(), modify(ctx) } }`.
- Triggers: `on_clicked` (used from the item bar, `oRunManager/Draw_64`) or `on_item_played_to_slot` (dragged onto a slot, `oCombat/Draw_64`). `flags()` says whether it can be used right now.
- Owned: `oRunManager.items` array (length = `max_items`, `undefined` = empty slot). `gain_item`, `get_first_free_item_slot`, `get_item_by_name`.
- Cores change a die's `distribution` at the workbench (Drill).

## Event names (ctx fields vary)

Turn: `on_combat_started`, `on_turn_start` (bonus_dice, intel, turn_count), `on_player_turn_end`, `on_enemy_turn_start`, `on_enemy_turn_end`, `on_round_end`, `on_combat_end`.
Dice: `on_dice_dealt`, `on_dice_played_to_slot`, `on_roll_die` (min_roll, max_roll, _d_amount, read_only...), `after_roll_die`, `after_slot_damage_calculated`, `on_not_used`, `on_dice_ejected`, `on_sacrifice_die`, `on_new_slot_created`, `after_new_slot_created`, `after_change_current_action`, `on_bag_empty`.
Other: `on_enemy_death`, `on_player_block_gained`, `on_player_debuffed`, `on_debuff_acquired`, `on_consumable_used`, `on_keepsake_acquired`, `on_rest`. Buff-only: `before_enemy_take_damage`, `on_enemy_take_damage`.

`on_roll_die` runs during previews too (`read_only` true): effects must not change state unless `!read_only`.
