switch (state) {
    case CombatState.START_TURN:
		turn_count++;
		
		for (var e = 0; e < ds_list_size(room_enemies); e++) {
			var enemy_data = room_enemies[| e].data;
			var enemy = room_enemies[| e];
			
			if (enemy.dead) continue;
			
			// Pick a random move struct from the enemy's move list
			if (enemy_data.move_order == "true_random") {
				enemy.move_number = irandom(ds_list_size(enemy_data.moves) - 1);
			} else if (enemy_data.move_order == "ordered") {
				if (enemy.move_number < ds_list_size(enemy_data.moves) - 1) {
					enemy.move_number += 1;
				} else {
					enemy.move_number = 0;
				}
			} else if (enemy_data.move_order == "weighted") {
				var num_moves = ds_list_size(enemy_data.moves);

				var weighted = [];
				array_resize(weighted, num_moves);

				for (var i = 0; i < num_moves; i++) {
				    weighted[i] = {
				        value: i,
				        weight: enemy_data.moves[| i].weight  // or 1 if no weight
				    };
				}

				enemy.move_number = choose_weighting_list(weighted);

			} else if (enemy_data.move_order == "pseudo_random") {
				// look through three latest moves, don't allow for 4 in a row, and weight odds to something else after every move
				var latest_moves = [];
				var move_index_avoid = -1;
				var move_index_completely_avoid = -1;
				var move_index = irandom(ds_list_size(enemy_data.moves) - 1);
				
				// Add last 3 moves name to array; NEED TO FIX SO THAT IT FLEXES TO LIST SIZE
				var num_previous_moves = ds_list_size(enemy.move_history);
				for (var m = num_previous_moves; m > max(0, num_previous_moves - 3); m--) {
					var move = enemy.move_history[| m - 1];
				
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
						for (var i = 0; i < ds_list_size(enemy_data.moves); i++) {
							if (latest_moves[0].move_name == enemy_data.moves[| i].move_name) move_index_completely_avoid = i;
						}
					} else {
						// just avoid the last move
						for (var i = 0; i < ds_list_size(enemy_data.moves); i++) {
							if (latest_moves[0].move_name == enemy_data.moves[| i].move_name) {
								move_index_avoid = i;
							}
						}
					}
			
					// If we are avoiding a move
					if (move_index_completely_avoid != -1) {
						// Randomise until we don't get that index
						var rand_index;
						
						do {
							rand_index = irandom(ds_list_size(enemy_data.moves) - 1);
						} until (rand_index != move_index_completely_avoid);
						
						move_index = rand_index;
					// otherwise
					} else if (move_index_avoid != -1) {
						// randomise twice and if the first one is our index, take the second regardless
						var rand_1 = irandom(ds_list_size(enemy_data.moves) - 1);
						var rand_2 = irandom(ds_list_size(enemy_data.moves) - 1);
				
						if (rand_1 == move_index_avoid) {
							move_index = rand_2;
						} else {
							move_index = rand_1;
						}
					}
				}
			
				enemy.move_number = move_index;
			}
			
			enemy.intent.move = enemy_data.moves[| enemy.move_number];
			
			// Overwrite the above with priority triggers
			for (var i = 0; i < ds_list_size(enemy_data.moves); i++) {
				var _move = enemy_data.moves[| i];
				if (variable_struct_exists(_move, "use_trigger")) {
					switch (_move.use_trigger) {
						case "FIRST":
							if (turn_count == 1) enemy.intent.move = _move;
						break;
						
						case "HEALTH 50":
							if (enemy.hp <= enemy.max_hp/2 && _move.weight != -1) {
								enemy.intent.move = _move;
								_move.weight = -1;
							}
						break;
						
						case "PRIORITY":
							enemy.intent.move = _move;
						break;
					}
				}
			}
			
			enemy_turns_remaining++;
			
			// flag debuffs as not being applied this turn
			for (var d = 0; d < ds_list_size(enemy.debuffs); d++) {
				enemy.debuffs[| d].remove_next_turn = false;
			}
		}
		
		// flag debuffs as not being applied this turn
		for (var d = 0; d < ds_list_size(global.player_debuffs); d++) {
			global.player_debuffs[| d].remove_next_turn = false;
		}
		
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
		
		player_intel = debug_mode ? 12 : 0;
		
		combat_trigger_effects("on_turn_start", turn_start_data);
		
		player_intel = clamp(player_intel, 0, 12);
		
		for (var i = 0; i < ds_list_size(global.player_intel_data); i++) {
			if (player_intel >= global.player_intel_data[| i].requirement) {
				intel_level = i;
			}
		}
		//show_debug_message("Player intel amount: "+string(player_intel));
		//show_debug_message("Player intel level: "+string(intel_level));
		
		dice_allowed_this_turn_bonus = turn_start_data.bonus_dice + (intel_level div 4 > 0);
			
		// Deal 3 dice first turn, then 2 every turn after that
		dice_to_deal += (turn_count == 1 ? global.hand_size : global.hand_size - 1) + (intel_level div 3 > 0);
		dice_deal_timer = 0;
		is_dealing_dice = true;
		
		for (var e = 0; e < ds_list_size(room_enemies); e++) {
			var enemy_data = room_enemies[| e].data;
			var enemy = room_enemies[| e];
			
			if (enemy.dead) continue;
		
			// Show enemy intent
			if (enemy.intent.move.action_type == "DEBUFF") || (enemy.intent.move.action_type == "BUFF") {
				enemy.intent.text = "";
			} else if (enemy.intent.move.action_type == "NONE" || enemy.intent.move.action_type == "EXIT") {
				enemy.intent.text = enemy.intent.move.move_name;
			} else {
				enemy.intent.text = string(enemy.intent.move.dice_amount + enemy.intent.move.bonus_amount) + "-" + string((enemy.intent.move.dice_amount * enemy.intent.move.dice_value) + enemy.intent.move.bonus_amount);
			}

		    // Animate in
		    enemy.intent.alpha = lerp(enemy.intent.alpha, 1, 0.2);
		    enemy.intent.scale = lerp(enemy.intent.scale, enemy.intent.start_scale, 0.3);
		}
		
		// Make any bound slots dice all temporary
		for (var i = 0; i < ds_list_size(action_queue); i++) {
			if (i == bound_slot) {
				var slot = action_queue[| i];
				
				for (var d = 0; d < ds_list_size(slot.dice_list); d++) {
					slot.dice_list[| d].permanence = "temporary";
				}
			}
		}
		
        state = CombatState.PLAYER_INPUT;
        break;

    case CombatState.PLAYER_INPUT:
		
		if (debug_mode) {
			if keyboard_check_pressed(vk_space) {
				for (var i = 0; i < ds_list_size(room_enemies); i++) {
					process_action(room_enemies[| i], 1, 1, 20, "player", -1, "ATK", 0, global.dice_d4_atk, 1);
				}
			}
		}


        // Wait for player input
        if (actions_submitted) {
			
            state = CombatState.RESOLVE_ROUND;
        }
		
		for (var e = 0; e < ds_list_size(room_enemies); e++) {
			var enemy_data = room_enemies[| e].data;
			var enemy = room_enemies[| e];
			
			if (enemy.dead) continue;
			
			// Hold steady on enemy intent scaling and alpha
	        enemy.intent.alpha = lerp(enemy.intent.alpha, 1, 0.1);
	        enemy.intent.scale = lerp(enemy.intent.scale, enemy.intent.start_scale, 0.1);
		}
		
        break;

    case CombatState.RESOLVE_ROUND:
	
	// === Discard all loose dice visually at start of RESOLVE_ROUND ===
	discard_dice_in_play();

    // Run player actions one at a time
    if (action_index < ds_list_size(action_queue)) {
        if (action_timer <= 0) {
			
			// Skip over locked slots
			if (action_index != locked_slot && enemies_left_this_combat > 0) {
				var slot = action_queue[| action_index];
	            var current_action = slot.current_action_type;
			
				var _target = room_enemies[| enemy_target_index];
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

		            process_action(_target, die.dice_amount, die.dice_value, slot.bonus_amount, _source, undefined, current_action, action_index, die, j);
					j++;
					
					player_last_action_type = current_action;
				}
			}

            // Next action after delay
            action_index += 1;
            action_timer = action_delay;
        } else {
            action_timer -= 1;
        }

    // After player actions, handle enemy action once
    } else if (!enemies_turn_done) {
		
	    if (action_timer <= 0) {
			for (var e = 0; e < ds_list_size(room_enemies); e++) {
				var enemy_data = room_enemies[| e].data;
				var enemy = room_enemies[| e];
			
				if (enemy.turn_done || enemy.dead) {
					continue;
					
				} else {
					
					var intent_array = string_split(enemy.intent.move.action_type, "/");
					
					for (var i = 0; i < array_length(intent_array); i++) {
						var _source = enemy;
						var _target = "player";
						
						if (intent_array[i] == "MIMIC") {
							intent_array[i] = player_last_action_type;
						}
					
						if (variable_struct_exists(enemy.intent.move, "target")) {
							_target = enemy.intent.move.target;
						}
					
						if (_target == "other") {
							var _target_index;
						
							if (enemies_left_this_combat > 1) {
								do {
									_target_index = irandom(enemies_left_this_combat-1);
								} until (_target_index != e);
							} else {
								_target_index = e;
							}
						
							_target = room_enemies[| _target_index];
						
							show_debug_message("current enemy index: " + string(e));
							show_debug_message("current other target index: " + string(_target_index));
						} else if (intent_array[i] == "BLK" || intent_array[i] == "HEAL" || intent_array[i] == "BUFF") {
							_target = _source;
						}
				
			            ds_list_add(enemy.move_history, enemy.intent.move);
						
						if (intent_array[i] == "EXIT") {
							ds_list_delete(room_enemies, e);
							particle_emit(enemy.pos_x, enemy.pos_y, "rise", make_color_rgb(20,20,20));
							enemies_left_this_combat--;
						} else {
							process_action(_target, enemy.intent.move.dice_amount, enemy.intent.move.dice_value, enemy.intent.move.bonus_amount, _source, e, intent_array[i]);
						}
						
			            action_timer = action_delay;
						enemy.turn_done = true;
					}
					
					enemy_turns_remaining--;
					
					// Force exit every time we run, so that we loop through enemies with delay between
					break;
				}
	        }
		} else {
	        action_timer -= 1;
	    }
		
		if (enemy_turns_remaining <= 0) {
			enemies_turn_done = true;
			enemy_turns_remaining = 0;
		}
    // When everything’s done, reset and loop back to start
    } else {
		
		for (var e = 0; e < ds_list_size(room_enemies); e++) {
			var enemy_data = room_enemies[| e].data;
			var enemy = room_enemies[| e];
			
			// Hold steady on enemy intent scaling and alpha
	        enemy.intent.alpha = lerp(enemy.intent.alpha, 0, 0.2);
	        enemy.intent.scale = lerp(enemy.intent.scale, enemy.intent.start_scale, 0.1);
		}
			
        if (action_timer <= 0) {
			state = CombatState.END_OF_ROUND;
	
        } else {
            action_timer -= 1;
        }
    }
	
    break;
	
	case CombatState.END_OF_ROUND:
        action_index = 0;
        enemies_turn_done = false;
        actions_submitted = false;
	
		// Reset player intel 
		player_intel = 0;
		
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
		
			if (enemies_to_fade_out > 0) {
				for (var e = ds_list_size(room_enemies) - 1; e >= 0; e--) {
					var enemy_data = room_enemies[| e].data;
					var enemy = room_enemies[| e];
				
					if (enemy.dead) {
						if (!enemy.looted) {
							// Earn some credits, regardless of secondary rewards
							gain_coins(enemy.pos_x, enemy.pos_y, enemy_data.bounty);
							enemy.looted = true;
						} else {
							// show enemy fading out
							enemy.alpha = lerp(enemy.alpha, 0.0, 0.1);
							enemy.intent.alpha = lerp(enemy.intent.alpha, 0, 0.1);
						
							if (enemy.alpha <= 0.05) {
								enemies_to_fade_out--;
								enemy.alpha = 0;
								ds_list_delete(room_enemies, e);
								if (enemy_target_index > e) enemy_target_index--;
							}
						}
					}
				}
			}
			
			if (!enemies_to_fade_out) {
				if (enemies_left_this_combat == 0) {
					win_fight();
				} else {
					// END OF TURN VARIABLES TO SET
					locked_slot = -1;
					bound_slot = -1;
				
					// Trigger end of turn effects for keepsakes
					var turn_end_data = {
					};
					
					combat_trigger_effects("on_player_turn_end", turn_end_data);
					combat_trigger_effects("on_enemy_turn_end", turn_end_data);

					with (oDice) can_discard = true;
					
					// Process enemy block
					for (var e = 0; e < ds_list_size(room_enemies); e++) {
						var enemy_data = room_enemies[| e].data;
						var enemy = room_enemies[| e];
					
						enemy.turn_done = false;
						enemy.turns_since_last_block++;
						if (enemy.turns_since_last_block > 1 && !enemy.keep_block_between_turns) {
							enemy.block_amount = 0;
						}
					}

					state = CombatState.START_TURN;
				}
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

enemy_x_offset = -460 + (enemies_left_this_combat*80);
enemy_y_offset = -90;

for (var e = 0; e < ds_list_size(room_enemies); e++) {
	var enemy_data = room_enemies[| e].data;
	var enemy = room_enemies[| e];
	
	enemy.pos_x = lerp(enemy.pos_x, enemy.pos_x_start, 0.2);
}

global.player_x = lerp(global.player_x, global.player_xstart, 0.2);

if (keyboard_check_pressed(vk_enter) && state == CombatState.PLAYER_INPUT && !is_dealing_dice) {
    actions_submitted = true;
}