switch (state) {
    case CombatState.START_TURN:
		// Pick a random move struct from the enemy's move list
		if (enemy.move_order = "true_random") {
			move_number = irandom(ds_list_size(enemy.moves) - 1);
		} else if (enemy.move_order = "order") {
			if (move_number < ds_list_size(enemy.moves) - 1) {
				move_number += 1;
			} else {
				move_number = 0;
			}
		} else if (enemy.move_order = "random") {
			// look through three latest moves, don't allow for 4 in a row, and weight odds to something else after every move
			var latest_moves = [];
			var move_index_avoid = -1;
			var move_index_completely_avoid = -1;
			var move_index = irandom(ds_list_size(enemy.moves) - 1);
				
			// Add last 3 moves name to array; NEED TO FIX SO THAT IT FLEXES TO LIST SIZE
			var num_previous_moves = ds_list_size(enemy_move_history);
			for (var m = num_previous_moves; m > max(0, num_previous_moves - 3); m--) {
				var move = enemy_move_history[| m - 1];
				
				array_push(latest_moves, move);
			}
			
			if (array_length(latest_moves) > 0) {
				var all_same = false;
				
				for (var o = 0; o < array_length(latest_moves); o++) {
					if (latest_moves[o] != latest_moves[0]) {
						all_same = false;
					} else {
						all_same = true;
					}
				}
				// If all three moves are the same
				if (all_same) {
					for (var i = 0; i < ds_list_size(enemy.moves); i++) {
						if (latest_moves[0].move_name == enemy.moves[| i].move_name) move_index_completely_avoid = i;
					}
				} else {
					// just avoid the last move
					for (var i = 0; i < ds_list_size(enemy.moves); i++) {
						if (latest_moves[0].move_name == enemy.moves[| i].move_name) move_index_avoid = i;
					}
				}
			
				// If we are avoiding a move
				if (move_index_completely_avoid != -1) {
					// Randomise until we don't get that index
					do {
						var rand_index = irandom(ds_list_size(enemy.moves) - 1);
					} until (rand_index != move_index_completely_avoid);
					move_index = rand_index;
				// otherwise
				} else if (move_index_avoid != -1) {
					// randomise twice and if the first one is our index, take the second regardless
					var rand_1 = irandom(ds_list_size(enemy.moves) - 1);
					var rand_2 = irandom(ds_list_size(enemy.moves) - 1);
				
					if (rand_1 == move_index_avoid) {
						move_index = rand_2;
					} else {
						move_index = rand_1;
					}
				}
			}
			
			move_number = move_index;
		}
		enemy_intent = enemy.moves[| move_number];

        add_feed_entry("=== Start of Turn ===");
        add_feed_entry("You draw 3 dice.");
		
		// Reset player stats every turn
		dice_played_scale = 1.2;
		dice_played = 0;
		player_block_amount = 0;
		dice_allowed_this_turn_bonus = 0;
		ejected_dice = false;
		
		// Modify dice allowed this turn
		var turn_start_data = {
			bonus_dice: dice_allowed_this_turn_bonus
		};
		combat_trigger_effects("on_turn_start", turn_start_data);
		
		dice_allowed_this_turn_bonus = turn_start_data.bonus_dice + (intel_level div 4 > 0);
		
		for (var i = 0; i < ds_list_size(global.player_intel_data); i++) {
			if (player_intel >= global.player_intel_data[| i].requirement) {
				intel_level = i;
			}
		}
		//show_debug_message("Player intel amount: "+string(player_intel));
		//show_debug_message("Player intel level: "+string(intel_level));
			
		// Deal 3 dice first turn, then 2 every turn after that
		dice_to_deal = first_turn ? global.hand_size : global.hand_size - 1 + (intel_level div 3 > 0);
		dice_deal_timer = 0;
		is_dealing_dice = true;

        add_feed_entry("The enemy will "+string(enemy_intent.action_type)+".");
		
		// Show enemy intent
		if (enemy_intent.action_type == "DEBUFF") {
			enemy_intent_text = "DEBUFF";
		} else if (enemy_intent.action_type == "NONE") {
			enemy_intent_text = "Recharging";
		} else {
			enemy_intent_text = string(enemy_intent.dice_amount + enemy_intent.bonus_amount) + "-" + string((enemy_intent.dice_amount * enemy_intent.dice_value) + enemy_intent.bonus_amount);
		}
			
	    // Color by type
	    switch (enemy_intent.action_type) {
	        case "ATK":  enemy_intent_color = c_red; break;
	        case "BLK":  enemy_intent_color = c_aqua; break;
	        case "HEAL": enemy_intent_color = c_lime; break;
			default: enemy_intent_color = c_white;
	    }

	    // Animate in
	    enemy_intent_alpha = lerp(enemy_intent_alpha, 1, 0.2);
	    enemy_intent_scale = lerp(enemy_intent_scale, 1.2, 0.3);
		
        state = CombatState.PLAYER_INPUT;
        break;

    case CombatState.PLAYER_INPUT:

        // Pretend to wait for player input
        if (actions_submitted) {
	
			// Reset player intel just before we process actions
			player_intel = 0;
			show_debug_message("Player intel set to 0, new player intel is: "+string(player_intel));
			
            state = CombatState.RESOLVE_ROUND;
        }
		
		// Hold steady on enemy intent scaling and alpha
        enemy_intent_alpha = lerp(enemy_intent_alpha, 1, 0.1);
        enemy_intent_scale = lerp(enemy_intent_scale, 1, 0.1);
		
        break;

    case CombatState.RESOLVE_ROUND:
    // If we’re just entering this state
    if (action_index == 0 && action_timer == 0 && !enemy_turn_done) {
        add_feed_entry("=== Resolving Round ===");
    }
	
	// === Discard all loose dice visually at start of RESOLVE_ROUND ===
	discard_dice_in_play();

    // Run player actions one at a time
    if (action_index < ds_list_size(action_queue)) {
        if (action_timer <= 0) {
			var slot = action_queue[| action_index];
            var current_action = slot.current_action_type;
			
			var _target = "enemy";
			var _source = "player";
			
			var j = 0;
			
			var action_data = ({
			    action_type: current_action,
				_d_amount: 0
			});

			combat_trigger_effects("on_action_used", action_data);
			
	        while (j < ds_list_size(slot.dice_list)) {
	            var die = slot.dice_list[| j];
				if (current_action == "BLK" || current_action == "HEAL" || current_action == "INTEL") _target = _source;

	            process_action(_target, die.dice_amount, die.dice_value, slot.bonus_amount, _source, current_action, action_index, die, j);
				j++;
			}

            // Next action after delay
            action_index += 1;
            action_timer = action_delay;
        } else {
            action_timer -= 1;
        }

    // After player actions, handle enemy action once
    } else if (!enemy_turn_done) {
		
        if (action_timer <= 0) {
			if (enemy_hp <= 0) {
				
				state = CombatState.END_OF_ROUND;
			} else {var _target = "player";
				var _source = "enemy";
				
	            add_feed_entry("Enemy uses " + string(enemy_intent.action_type) + ".");
				ds_list_add(enemy_move_history, enemy_intent);
				
				if (enemy_intent.action_type == "BLK" || enemy_intent.action_type == "HEAL") _target = _source;
	            process_action(_target, enemy_intent.dice_amount, enemy_intent.dice_value, enemy_intent.bonus_amount, _source, enemy_intent.action_type);


	            enemy_turn_done = true;			
	            action_timer = action_delay;
				}
        } else {
            action_timer -= 1;
        }

    // When everything’s done, reset and loop back to start
    } else {
			
		// Fade out enemy intent at end of round
	    enemy_intent_alpha = lerp(enemy_intent_alpha, 0, 0.2);
	    enemy_intent_scale = lerp(enemy_intent_scale, 0.8, 0.1);
			
        if (action_timer <= 0) {
			// This is a TEMPORARY WORKAROUND for removing debuffs at the end of the player turn, other events may need to end here as well
			decrease_debuff_duration(global.player_debuffs, "on_roll_die", {});
				
            state = CombatState.END_OF_ROUND;
	
        } else {
            action_timer -= 1;
        }
    }
	
    break;
	
	case CombatState.END_OF_ROUND:
        action_index = 0;
        enemy_turn_done = false;
        actions_submitted = false;
		first_turn = false;
		
		// Eject temporary dice and remove buffed timers
		if (!ejected_dice) {
		    for (var i = 0; i < ds_list_size(action_queue); i++) {
		        var slot = action_queue[| i];
		        var slot_pos = slot_positions[| i]; // from Draw GUI
				slot.possible_type = "";

				// Eject dice in slot, but not ALL of them (just the temporary or loose ones)
		        eject_dice_in_slot(slot, slot_pos, false);
				
				// Count down buff timers
				if (slot.buffed > 0) {
					slot.buffed -= 1;
					
					if (slot.buffed == 0) {
						slot.bonus_amount = slot.pre_buff_amount;
					}
				}
		    }
			
			ejected_dice = true;
		}

		if (instance_number(oDiceParticle) == 0) {
			if (enemy_hp <= 0) {
				win_fight();
			} else {
				
				// END OF TURN VARIABLES TO SET
				enemy_turns_since_last_block ++;
				if (enemy_turns_since_last_block > 1) {
					enemy_block_amount = 0;
				}
				
				// Trigger end of turn effects for keepsakes
				var turn_end_data = {};
				combat_trigger_effects("on_turn_end", turn_end_data);

				with (oDice) can_discard = true;

				state = CombatState.START_TURN;
			}
		}
	break;

}
		
dice_allowed_per_turn = dice_allowed_per_turn_original + dice_allowed_this_turn_bonus + oRunManager.bonus_dice_next_combat;

if (is_dealing_dice) {
	if (dice_deal_timer > 0) {
		dice_deal_timer--;
	} else {
		// Time to deal the next die
		if (dice_to_deal > 0) {
		    deal_single_die();
		    dice_to_deal--;
		    dice_deal_timer = dice_deal_delay;
		} else {
		    // Finished dealing all dice
		    is_dealing_dice = false;
		    add_feed_entry("All dice dealt!");
		}
	}
}

if (ds_list_size(feed_queue) > 0) {
    feed_timer -= 1;
    if (feed_timer <= 0) {
        // Move one message from queue to feed
        var msg = ds_list_find_value(feed_queue, 0);
        ds_list_delete(feed_queue, 0);
        ds_list_add(combat_feed, msg);

        // Keep feed capped at 20 lines
        if (ds_list_size(combat_feed) > 10) {
            ds_list_delete(combat_feed, 0);
        }

        feed_timer = feed_delay; // reset delay
    }
}