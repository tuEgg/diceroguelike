switch (state) {
    case CombatState.START_TURN:
		// Pick a random move struct from the enemy's move list
		if (enemy.move_order = "random") {
			move_number = irandom(ds_list_size(enemy.moves) - 1);
		} else if (enemy.move_order = "order") {
			if (move_number < ds_list_size(enemy.moves) - 1) {
				move_number += 1;
			} else {
				move_number = 0;
			}
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
		
		dice_allowed_this_turn_bonus = turn_start_data.bonus_dice;
		
		dice_allowed_per_turn = dice_allowed_per_turn_original + dice_allowed_this_turn_bonus;
			
		// Deal 3 dice first turn, then 2 every turn after that
		dice_to_deal = first_turn ? 5 : 4;
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
				if (current_action == "BLK" || current_action == "HEAL") _target = _source;

	            deal_damage(_target, die.dice_amount, die.dice_value, slot.bonus_amount, _source, current_action, action_index, die, j);
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
			} else {
				// This is a TEMPORARY WORKAROUND for removing debuffs at the end of the player turn, other events may need to end here as well
				decrease_debuff_duration(global.player_debuffs, "on_roll_die", {});
				
				var _target = "player";
				var _source = "enemy";
				
	            add_feed_entry("Enemy uses " + string(enemy_intent.action_type) + ".");
				if (enemy_intent.action_type == "BLK" || enemy_intent.action_type == "HEAL") _target = _source;
	            deal_damage(_target, enemy_intent.dice_amount, enemy_intent.dice_value, enemy_intent.bonus_amount, _source, enemy_intent.action_type);


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
		
		// Eject temporary dice
		if (!ejected_dice) {
		    for (var i = 0; i < ds_list_size(action_queue); i++) {
		        var slot = action_queue[| i];
		        var slot_pos = slot_positions[| i]; // from Draw GUI
				slot.possible_type = "";

		        var j = 0;
		        while (j < ds_list_size(slot.dice_list)) {
		            var die = slot.dice_list[| j];
				
					die.rolled_value = -1;

		            if (string_pos("temporary", die.permanence) > 0) {
					
						//// THIS COULD SIT IN A HELPER -- EJECT DICE
						// Clean up sacrifice history
						if (ds_exists(global.sacrifice_history, ds_type_list)) {
						    for (var s = ds_list_size(global.sacrifice_history) - 1; s >= 0; s--) {
						        var die_struct = global.sacrifice_history[| s];

						        if (is_struct(die_struct)) {
						            if (die_struct.permanence == "temporary none") {
						                ds_list_delete(global.sacrifice_history, s);
						            }
						        }
						    }
						}
					
		                // Use stored GUI coords for particle spawn
		                var start_x = slot_pos.x + (slot_pos.w / 2);
		                var start_y = slot_pos.y + (slot_pos.h / 2);

		                // Spawn particle
						var p = instance_create_layer(start_x, start_y, "Instances", oDiceParticle);
						p.target_x = gui_w - 150;  // discard button target
						p.target_y = gui_h - 130;
						p.color_main = die.color;

						// Clone the die struct so the particle has its own independent copy
						p.die_struct = clone_die(die, "");

		                // Remove from slot
		                ds_list_delete(slot.dice_list, j);
					
						//// END OF HELPER
					
		            } else {
		                j++;
		            }
		        }
			
				for (var d = 0; d < ds_list_size(slot.dice_list); d++) {
					var die = slot.dice_list[| d];
				
					// only add new unique types
					var parts = string_split(die.possible_type, " ");
					var total = array_length(parts);

					for (var p = 0; p < total; p++) {
						if (string_pos(string(parts[p]), slot.possible_type) > 0) {
						} else {
							if (slot.possible_type == "") {
								slot.possible_type = parts[p];
								//show_debug_message(string(i)+" slot, setting possible type to "+string(parts[p]));
							} else {
								slot.possible_type = string_concat(slot.possible_type, " ", parts[p]);
								//show_debug_message(string(i)+" slot, adding possible types"+string(parts[p]));
							}
						}
					}	
				}
			
				if (ds_list_size(slot.dice_list) == 0) {
					slot.possible_type = "None";
				}
						
				// change the type if this action type isn't contained within the possible type
				if (slot.possible_type != "") {
					//show_debug_message(string(i)+" slot possible type is not empty");
					if (!string_pos(slot.current_action_type, slot.possible_type)) {
						var parts = string_split(slot.possible_type, " ");
						var total = array_length(parts);
				
						slot.current_action_type = parts[0];
						//show_debug_message(string(i)+" slot resetting action type to "+string(parts[0]));
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

				state = CombatState.START_TURN;
			}
		}
	break;

}

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