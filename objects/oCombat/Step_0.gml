// a reward die taken in Draw GUI flies to the bag from here (instances aren't created while drawing)
if (pending_reward_die != undefined) {
	var _rd = pending_reward_die;
	pending_reward_die = undefined;
	var _p = instance_create_depth(_rd.x, _rd.y, -10, oDiceParticle);
	_p.target_x = _rd.tx;
	_p.target_y = _rd.ty;
	_p.die_struct = _rd.die;
}

// the pause menu freezes the fight (F35); it is still drawn behind the menu
if (instance_exists(oRunManager) && oRunManager.paused) exit;

// Settings > Gameplay > Combat speed, also when changed mid-fight (F13)
action_delay = action_delay_base * combat_delay_scale();
dice_delay = dice_delay_base * combat_delay_scale();

switch (state) {
    case CombatState.START_TURN:
		turn_count++;
		player_turn_done = false;
		intel_rewrite_used = false;
		insight_revealed = false; // what insight bought last turn is gone
		for (var e = 0; e < ds_list_size(room_enemies); e++) room_enemies[| e].revealed = false; // exact values, per enemy
		rerolls_bought = 0;
		redraws_bought = 0;
		plays_bought = 0;
		quill_menu_enemy = undefined;
		target_locked = false; // Overwhelm locks it again in on_turn_start
		delayed_enemy_attack = false;
		
		if (turn_count == 1) {
			combat_trigger_effects("on_combat_started", {});
		}
		
		for (var e = 0; e < ds_list_size(room_enemies); e++) {
			var enemy_data = room_enemies[| e].data;
			var enemy = room_enemies[| e];
			
			if (enemy.dead) continue;
			
			// pick this turn's move by the enemy's move_order (triggers below can override it)
			enemy.move_number = enemy_pick_move_index(enemy);
			
			var _intent_move = enemy_data.moves[| enemy.move_number];
			
			// Overwrite the above with priority triggers
			for (var i = 0; i < ds_list_size(enemy_data.moves); i++) {
				var _move = enemy_data.moves[| i];
				if (variable_struct_exists(_move, "use_trigger")) {
					switch (_move.use_trigger) {
						case "FIRST":
							if (turn_count == 1) _intent_move = _move;
						break;
						
						case "HEALTH 50":
							if (enemy.hp <= enemy.max_hp/2 && !variable_struct_exists(_move, "trigger_used")) {
								_intent_move = _move;
								_move.trigger_used = true; // once per fight, this move struct belongs to this enemy only
							}
						break;
						
						case "PRIORITY":
							_intent_move = _move;
						break;
					}
				}
			}
			
			// sets the move and rolls its dice now, so intel can reveal the exact result
			enemy_set_intent(enemy, _intent_move);
			// and where in your queue it happens (the timeline, F193); each enemy keeps a letter and colour all fight
			enemy.intent.after_slot = enemy_move_point(_intent_move);
			if (!variable_struct_exists(enemy, "mark")) { enemy.mark = mark_next; mark_next++; }

			enemy_turns_remaining++;
			
			// debuffs that were set to remove_next_turn now get set to false and will be removed at the end of the turn
			for (var d = 0; d < ds_list_size(enemy.debuffs); d++) {
				enemy.debuffs[| d].remove_next_turn = false;
			}
		}
		
		// debuffs that were set to remove_next_turn now get set to false and will be removed at the end of the turn
		for (var d = 0; d < ds_list_size(global.player_debuffs); d++) {
			global.player_debuffs[| d].remove_next_turn = false;
		}
		
		// Reset player stats every turn
		dice_played_scale = 1.2;
		dice_played = 0;
		player_block_amount = 0;
		dice_allowed_this_turn_bonus = 0;
		ejected_dice = false;
		played_uids = [];
		rerolls_used = 0;
		redraws_used = 0;
		take_back_request = undefined;

		// ink carries over from last turn (never a debt: Blotted doesn't carry), plus the F1 debug amount (0 unless set)
		player_intel = max(0, player_intel) + debug_turn_intel();
		
		// Modify dice allowed this turn
		var turn_start_data = {
			bonus_dice: dice_allowed_this_turn_bonus,
			intel: player_intel,
			turn_count: turn_count,
		};
		
		combat_trigger_effects("on_turn_start", turn_start_data);
		// Balance earned last turn (Balanced die rolled its max)
		if (balance_next_turn > 0) { apply_buff("player", oRunManager.buff_balance, balance_next_turn, 1, false, { source: "player", index: -1 }); balance_next_turn = 0; }
		
		// capped at INSIGHT_MAX (12); it can go below 0 (Overwhelm), which hides enemy intents
		player_intel = min(player_intel, intel_max());
		insight_phase_done = false; // the inkwell pulses once the hand is dealt, if ink can do something (oCombat Step, PLAYER_INPUT)
		intel_level = insight_revealed ? INTEL_LEGIBLE : INTEL_FADED;
		//show_debug_message("Player intel amount: "+string(player_intel));
		//show_debug_message("Player intel level: "+string(intel_level));
		
		// intel no longer grants extra plays or draws: its levels reveal and change enemy intents instead
		dice_allowed_this_turn_bonus = turn_start_data.bonus_dice;
			
		// Deal 3 dice first turn, then 2 every turn after that
		dice_to_deal += global.hand_size;
		dice_deal_timer = 0;
		is_dealing_dice = true;
		
		for (var e = 0; e < ds_list_size(room_enemies); e++) {
			var enemy_data = room_enemies[| e].data;
			var enemy = room_enemies[| e];
			
			if (enemy.dead) continue;
		
		    // Animate in
		    enemy.intent.alpha = lerp(enemy.intent.alpha, 1, 0.2);
		    enemy.intent.scale = lerp(enemy.intent.scale, enemy.intent.start_scale, 0.3);
		}
		
		// (Rot used to make the rotten slot's dice temporary here; it halves the slot's total now: process_action)
		
		// Failsafe for targeting in case enemy_target_index is outside of the room_enemies size.
		if (enemy_target_index < 0 || enemy_target_index >= ds_list_size(room_enemies)) {
			enemy_target_index = irandom(ds_list_size(room_enemies) - 1);
		}
		
        state = CombatState.PLAYER_INPUT;
        break;

    case CombatState.PLAYER_INPUT:
		// a played die was clicked (oCombat Draw GUI): back to the hand
		if (take_back_request != undefined) {
			combat_take_back(take_back_request.slot, take_back_request.index);
			take_back_request = undefined;
		}

		// (the Space and Backspace testing keys now live in scDebug, debug_hotkeys)


        // Wait for player input
        if (actions_submitted) {
			
			combat_pick_debuffed_slots(); // Bind and Rot pick their slot now, from the ones you built
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
			
		function reset_die() {
			// Next action after delay
			action_index += 1;
			dice_index = 0;
			action_timer = 0;
		}
			
        if (action_timer <= 0) {

			// the timeline (F193): before slot N+1 starts, every enemy move set "after your slot N" happens
			var _due = (dice_index == 0 && dice_timer <= 0 && action_index > 0) ? combat_enemy_due(action_index) : -1;
			if (_due != -1) {
				combat_enemy_act(_due);
				action_timer = action_delay;
			} else
			// Skip over locked slots
			if (action_index != locked_slot) {
				var slot = action_queue[| action_index];
	            var current_action = slot.current_action_type;
			
				var _target = room_enemies[| enemy_target_index];
				var _source = "player";
				
			    if (dice_index < ds_list_size(slot.dice_list)) {
					// skip attacks if there's no enemies left
					if (current_action == "ATK" && enemies_left_this_combat == 0) {
						show_debug_message("No enemies left, skipping attack action");
						
				        reset_die();
					} else {
						if (dice_timer <= 0) {
							
					        var die = slot.dice_list[| dice_index];
							if (current_action == "BLK" || current_action == "HEAL" || current_action == "INTEL") _target = _source;
					
						    process_action(_target, die.dice_amount, die.dice_value, slot.bonus_amount, _source, undefined, current_action, action_index, die, dice_index);
							
							player_last_action_type = current_action;
							
							draw_action_index = action_index;
							draw_dice_index = dice_index;
							dice_spin = 0;
							
							dice_index++;
							dice_timer = dice_delay;
						} else {
							dice_timer -= 1;
						}
					}
				} else {
					// the slot's last die gets its full time in the spotlight (dice_timer) before moving on
					if (dice_timer > 0) dice_timer -= 1;
					else reset_die();
				}
			} else {
	            reset_die();
			}
        } else {
            action_timer -= 1;
        }

    // After player actions, handle enemy action once
    } else if (!enemies_turn_done) {
		
		// no extra wait here (the timeline): the rest act right after your last slot, as a move mid-queue does
		delayed_enemy_attack = true;

	    if (action_timer <= 0) {

			if (!player_turn_done) { // once, not once per enemy left
				player_turn_done = true;
				var player_turn_end_data = {
				};
				combat_trigger_effects("on_player_turn_end", player_turn_end_data);
			}
				
			// the rest of the enemies (their point is your last slot or past it, or they waited): one at a time
			// in their order on the track (an earlier point first), so it plays out as it reads
			var _next = -1, _next_p = infinity;
			for (var e = 0; e < ds_list_size(room_enemies); e++) {
				var enemy = room_enemies[| e];
				if (enemy.turn_done || enemy.dead) continue;
				var _ep = variable_struct_exists(enemy.intent, "after_slot") ? enemy.intent.after_slot : ENEMY_POINT_LAST;
				if (_ep < _next_p) { _next = e; _next_p = _ep; }
			}
			if (_next != -1) combat_enemy_act(_next); // one per tick, with action_delay between
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
		draw_action_index = 0;
		dice_index = 0;
		draw_dice_index = 0;
		dice_timer = 0;
		action_timer = 0;
        enemies_turn_done = false;
        actions_submitted = false;
	
		// ink is not reset: what you didn't spend carries into next turn (capped at the start of the turn)

		// Eject temporary dice and remove buffed timers
		if (!ejected_dice) {
		    for (var i = 0; i < ds_list_size(action_queue); i++) {
		        var slot = action_queue[| i];
		        var slot_pos = slot_positions[| i]; // from Draw GUI
				slot.possible_type = "";

				// rolled dice: everything played leaves at the end of the turn; a Sticky die stays one extra turn (and acts again)
				for (var d = 0; d < ds_list_size(slot.dice_list); d++) {
					var _sd = slot.dice_list[| d];
					if (_sd.permanence == "sticky" && !(variable_struct_exists(_sd, "sticky_held") && _sd.sticky_held)) _sd.sticky_held = true;
					else _sd.permanence = "temporary";
				}

				show_debug_message("enemies_to_fade_out: " + string(enemies_to_fade_out));
				show_debug_message("enemies_left_this_combat: " + string(enemies_left_this_combat));

				// Only eject all dice when we're out of enemies left this combat
		        if (enemies_to_fade_out > 0 && enemies_left_this_combat == 0) {
					// Eject all dice in slot
					eject_dice_in_slot(slot, slot_pos, true);
				} else {
					// Eject only temporary or loose dice from slots
					eject_dice_in_slot(slot, slot_pos, false);
				}
				
				// Count down timed slot bonuses (Rigger's Tonic and the like)
				slot_tick_bonuses(slot);

				// back to the types it was built with (an empty starting slot is untyped again)
				slot_recompute_types(slot);

				// set all dice in this slot to temporary
				for (var d = 0; d < ds_list_size(slot.dice_list); d++) {
					// turn every "base" dice into a temporary one at the end of the turn, note: sticky dice are "sticky" and are not affected by this
					show_debug_message(slot.dice_list[| d].name + ", " + slot.dice_list[| d].permanence);
					if (slot.dice_list[| d].permanence == "base") {
						slot.dice_list[| d].permanence = "temporary";
					}
				}
		    }
			
			// dice left on the new-slot tile (not enough to build it) go to the discard pile too
			combat_discard_slot_building();
			// the queue resets every turn (F193): built slots go, unless a Sticky die is holding one
			combat_queue_reset_built();

			ejected_dice = true;
		}

		if (instance_number(oDiceParticle) == 0) {
		
			if (enemies_to_fade_out > 0) {
				for (var e = ds_list_size(room_enemies) - 1; e >= 0; e--) {
					var enemy_data = room_enemies[| e].data;
					var enemy = room_enemies[| e];
				
					if (enemy.dead) {
						// fled when their leader fell (combat_enemies_flee): they just fade away, no gold and no kill/spare choice
						if (variable_struct_exists(enemy, "fled") && enemy.fled) {
							enemy.alpha = lerp(enemy.alpha, 0.0, 0.1);
							enemy.intent.alpha = lerp(enemy.intent.alpha, 0, 0.1);
							if (enemy.alpha <= 0.05) {
								enemies_to_fade_out--;
								enemy.alpha = 0;
								ds_list_delete(room_enemies, e);
								if (enemy_target_index > e) enemy_target_index--;
							}
							continue;
						}

						if (oWorldManager.current_node_type == NODE_TYPE.ALIGNMENT || oWorldManager.current_node_type == NODE_TYPE.ELITE) {
							if (!enemy.alignment_choices_shown && !enemy.spared && !enemy.killed) {
								enemy.alignment_choices_shown = true;
							}
							
							if (enemy.spared) {
								if (!enemy.looted) {
									gain_alignment(5);
								
									// Earn some credits, regardless of secondary rewards
									gain_coins(enemy.pos_x, enemy.pos_y, ceil(enemy_data.bounty / 3)); // a third of its bounty: killing pays (Q12)
									
									enemy.looted = true;
								} else {
									// show enemy fading back in and leaving
									enemy.alpha = lerp(enemy.alpha, 1.0, 0.1);
									enemy.intent.alpha = lerp(enemy.intent.alpha, 1.0, 0.1);
						
									if (enemy.alpha >= 0.95) {
										enemies_to_fade_out--;
										enemy.alpha = 1;
										particle_emit(enemy.pos_x, enemy.pos_y, "rise", make_color_rgb(20,20,20));
										ds_list_delete(room_enemies, e);
										if (enemy_target_index > e) enemy_target_index--;
									}
								}
							}
						}
						
						if (oWorldManager.current_node_type == NODE_TYPE.ALIGNMENT && enemy.killed || oWorldManager.current_node_type == NODE_TYPE.COMBAT || oWorldManager.current_node_type == NODE_TYPE.BOSS || oWorldManager.current_node_type == NODE_TYPE.ELITE && enemy.killed) {
							all_enemies_spared = false;
							
							if (!enemy.looted) {
								// Earn some credits, regardless of secondary rewards
								gain_coins(enemy.pos_x, enemy.pos_y, enemy_data.bounty);
							
								// Gain the gold reward if we complete the fight
								if (oRunManager.active_bounty != undefined) {
									if (oWorldManager.current_node_type == NODE_TYPE.ELITE && oRunManager.active_bounty.complete) {
										gain_coins(enemy.pos_x, enemy.pos_y, oRunManager.active_bounty.condition.gold_reward);
									}
								}
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
			}
			
			if (!enemies_to_fade_out) {
				// Reposition enemies based on changing fight conditions
				enemy_x_offset = -(460 * global.ui_scale) + (enemies_left_this_combat * (75 * global.ui_scale));
				enemy_y_offset = -(40 * global.ui_scale);
				
				if (enemies_left_this_combat == 0) {
					win_fight();
				} else {
					// END OF TURN VARIABLES TO SET
					locked_slot = -1;
					bound_slot = -1;
					
					for (var i = 0; i < ds_list_size(action_queue); i++) {
						var slot = action_queue[| i];
						for (var d = 0; d < ds_list_size(slot.dice_list); d++) {
							var die = slot.dice_list[| d];
	
							if (die.reset_after_next_roll != false && die.reset_this_turn == false) {
								die.reset_this_turn = true;
								show_debug_message("Resetting at the end of the round");
							}
						
							if (die.reset_after_next_roll == false && die.reset_this_turn) {
								die.reset_this_turn = false;
							}
						}
					}

					with (oDice) can_discard = true;
					
					// Process enemy block
					for (var e = 0; e < ds_list_size(room_enemies); e++) {
						var enemy_data = room_enemies[| e].data;
						var enemy = room_enemies[| e];
					
						enemy.turn_done = false;
						enemy.turns_since_last_block++;
						// (enemy block now lasts until that enemy acts again: combat_enemy_act)
					}
					
					var end_of_round_data = {
					};
					
					combat_trigger_effects("on_round_end", end_of_round_data);

					state = CombatState.START_TURN;
				}
			}
		}
	break;
	
	case CombatState.PLAYER_DEAD:
		discard_dice_in_play();
	break;
}
		
dice_allowed_per_turn = dice_allowed_per_turn_original + dice_allowed_this_turn_bonus + oRunManager.bonus_dice_next_combat + plays_bought;

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

// where each enemy stands: re-centred as enemies die or are summoned and as the queue grows, gliding there
enemy_layout_update();

// Move player based on starting position
global.player_xstart = 355 * global.ui_scale - ((ds_list_size(action_queue)-1) * global.ui_scale * 30);

global.player_x = lerp(global.player_x, global.player_xstart, 0.2);

if (insight_view) insight_view_age++;
// I opens and closes insight view
// the log doesn't open by itself: once the hand is dealt, the inkwell pulses for a few seconds if your ink can do
// something (combat_insight_phase_worth). Click the inkwell to open it.
if (state == CombatState.PLAYER_INPUT && !insight_phase_done && !is_dealing_dice && dice_to_deal <= 0 && !show_rewards) {
	insight_phase_done = true;
	if (combat_insight_phase_worth()) { ink_pulse = round(game_get_speed(gamespeed_fps) * 2.5); ink_waiting = true; }
}
// it keeps pulsing until you act: use your ink, play a die or end the turn (then it fades out)
if (ink_waiting && (insight_view || actions_submitted || dice_played > 0 || state != CombatState.PLAYER_INPUT)) ink_waiting = false;
if (ink_waiting) ink_pulse = max(ink_pulse, 21); else if (ink_pulse > 0) ink_pulse--;
if (insight_view) ink_pulse = 0;
// Enter confirms (closes the log), like the button that stands in for End Turn (it can't be reopened until next turn)
var _sealed_now = false;
if (keyboard_check_pressed(vk_enter) && insight_view && insight_view_age > 0) { combat_insight_view_set(false); _sealed_now = true; }
if (insight_view && (state != CombatState.PLAYER_INPUT || show_rewards || intel_is_blotted())) combat_insight_view_set(false);

if (keyboard_check_pressed(vk_enter) && !_sealed_now && state == CombatState.PLAYER_INPUT && !is_dealing_dice && !insight_view && tutorial_allows("end_turn")) {
    actions_submitted = true;
}

// intel can change mid-turn (keepsakes), so its state is kept up to date every frame
intel_level = insight_revealed ? INTEL_LEGIBLE : INTEL_FADED;

// the guided first fight moves on as its steps are done
// the hand is always one even row (combat_hand_row)
if (!show_rewards) combat_hand_row();

tutorial_step();
