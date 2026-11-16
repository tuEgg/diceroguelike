# Combat

Room `rmCombat`, object `oCombat` (not persistent). Created with the enemies `oWorldManager.room_enemies` holds (filled by `get_combat_enemies` in scMap, or by the debug menu via `debug_apply_pending_fight`).

## Turn loop: `oCombat/Step_0.gml`

`state` (enum `CombatState`): `START_TURN` → `PLAYER_INPUT` → `RESOLVE_ROUND` → `END_OF_ROUND` → back to `START_TURN`; `PLAYER_DEAD` on death.

- **START_TURN**: picks each enemy's intent (`move_order`: `true_random`, `ordered`, `weighted` via `choose_weighting_list`, `pseudo_random` = no 4 in a row). `use_trigger` on a move overrides: `FIRST` (turn 1), `HEALTH 50` (once, flagged `trigger_used` on the per-fight move copy), `PRIORITY`. Fires `on_turn_start`, sets intel (`debug_turn_intel()` + buffs), works out `intel_level`, deals dice (`dice_to_deal`).
- **PLAYER_INPUT**: waits for `actions_submitted` (Enter or the End Turn button in Draw GUI).
- **RESOLVE_ROUND**: discards dice still in hand, then each slot's dice roll one by one through `process_action`, then each enemy acts once, with delays between.
- **END_OF_ROUND**: ejects temporary/Loose dice (`eject_dice_in_slot`), `slot_tick_bonuses`, turns "base" dice into temporary (permanent dice leave on their second turn), fades out dead enemies, then `win_fight()` or `on_round_end` and the next turn.

`oCombat/Draw_64.gml` (~1500 lines) draws everything and handles most clicks: slots, dice in slots (with slot-bonus badges), enemies, intents, buffs, rewards screen.
- Intel: `player_intel` can go negative (Overwhelm). The intel ring above the player is clamped between empty and full; the number shows whenever intel isn't zero, red when negative.

## Rolling and damage: `process_action` (scCombatScripts)

`process_action(target, dice_amount, dice_value, bonus, source, source_index, type, slot_number, slot_die, dice_list_index)`

- Player rolls go through `get_dice_output` (fires `on_roll_die`: keepsakes and buffs adjust min/max/bonus), a weighted distribution (cores), `after_roll_die`, then add the slot's every-die bonus and, for the slot's first die, `first_die_bonus`.
- `get_dice_output` is also used for previews (hover, bag, slot ranges): previews pass `read_only` true so keepsakes and dice don't change state or pop, and a die not in a slot is previewed as its own action type so type bonuses show before it is played.
- Enemy rolls: plain range, then the roller's own buffs on `on_roll_die` (ctx `owner` and `target` are both the roller).
- Types: `ATK` (block absorbs post-modifier damage; `before_enemy_take_damage`, `on_enemy_take_damage`, death handling), `BLK`, `HEAL`, `DEBUFF`/`BUFF` (apply_buff to target, `remove_next_turn` true), `INTEL`, `SUMMON`. `dice_amount` 0 means flat damage of `dice_value`.

## Slots (the action queue)

`action_queue` is a ds_list of slot structs: `dice_list`, `current_action_type`, `possible_type` (space-separated types string), `bonus_amount`, `first_die_bonus`, `bonuses`.

- Placing: `apply_dice_to_slot` (real rule) and `can_place_dice_in_slot` (highlight) — they still disagree (KANBAN B35).
- Keyword rules in combat (Exclusive, Sticky, Loose ejection, Coin not counting as a played die) read the die's `keywords` via `die_has_keyword`, never its description.
- Sacrificing dice builds new slots: `sacrifice_die`.
- **Slot bonuses**: list of `{ source, amount, turns, scope }`. `scope` "each" (every die, the default) or "first" (first die only). Use `slot_add_bonus` / `slot_set_bonus` / `slot_remove_bonus`; `slot_tick_bonuses` at end of round; `slot_total_bonus(slot, dice)` for display; `slot_bonus_breakdown` for the hover box. `source` is shown to the player, so use the keepsake/item name.

## Buffs and debuffs: scDebuffs

- Templates are instance variables made by `define_buffs_and_debuffs()` on `oRunManager` (`oRunManager.buff_might` etc.).
- `apply_buff(target, template, duration, amount, remove_next_turn, source, permanent)` clones the template into `{ template, remaining, permanent, amount, remove_next_turn, source_info }` in `global.player_debuffs` or `enemy.debuffs`. Merges only with the same id **and** same permanence (and, if stackable, same `remove_next_turn`).
- `trigger_debuff_list(list, event, ctx)` fires effects, then counts down once per buff on its `removal_event`.
- Might/Balance check `owner == target`.

## Enemies: scEnemies

`define_enemies()` builds `global.enemy_list` via `enemy_create(...)` (moves are structs: `dice_amount, dice_value, action_type, bonus_amount, move_name`, optional `weight, use_trigger, debuff, amount, duration, target, summon`). `add_enemy_to_fight` calls `enemy_copy_for_fight` then `enemy_apply_chapter_scaling` (scMap). Per-fight lists are freed in `oCombat/CleanUp_0` via `fight_enemy_records`.

## Effect events

`combat_trigger_effects(event, ctx)` → dice in slots (or just `ctx._die_struct`), keepsakes (`runmanager_trigger_keepsakes`), player buffs, each enemy's buffs, bounty conditions. Event names are listed in `docs/context/dice-keepsakes-items.md`.
