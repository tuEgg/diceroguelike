/// process_action(_target, _dice_amount, _dice_value, _bonus_amount, _source, _source_index, _type, _slot_number, _slot_die, _dice_list_index)
/// _target: "enemy" or "player"
/// _dice_amount: base amount of dice
/// _dice_value: highest roll of dice
/// _bonus_amount: the bonus value to add to the roll
/// _source: "enemy" or "player" (attacker or caster)
/// _type: "atk" or "heal"

function process_action(_target, _dice_amount, _dice_value, _bonus_amount, _source, _source_index, _type, _slot_number = -1, _slot_die = undefined, _dice_list_index = 0) {
	//show_debug_message("this die has a value of: "+string(_dice_value));
	
	// Generate a unique id for this action process
	var roll_id = string_concat(_target, _dice_amount, _dice_value, _bonus_amount, _source, _source_index, _type, _slot_number, _slot_die, _dice_list_index);

    // --- Roll total amount ---
    var amount = 0;
	var slot_bonus_amount = _bonus_amount;
	var _keepsake_dice_bonus_amount = 0;
	var enemy_bonus_used_once = false;
	var first_die_bonus_used = false;
	var _enemy_roll_index = 0; // which of the enemy's pre-rolled dice is next
	var _face_index = 0; // rolled dice: which of the die's faces (rolled when dealt) is next
	
	repeat (_dice_amount) {
		// Roll starts at default range
		var _min_roll = 1;
		var _max_roll = _dice_value;
		var final_roll = amount;
		
		// Player tweaks numbers differently from enemy
		if (_source == "player") {
			var dice_output = get_dice_output(_slot_die, _slot_number, _dice_list_index, false, "player");
			
			_min_roll = dice_output.min_roll;			
			_max_roll = dice_output.max_roll;
			
			if (_min_roll > _max_roll) _min_roll = _max_roll;
			
			_keepsake_dice_bonus_amount = dice_output.keepsake_dice_bonus_amount;
			var _keepsake_weighting = dice_output.weighting; // currently only used to add weighting to coins from the Lucky Coin 
			var _prev_slot_type = dice_output.previous_slot_type;
			
			// Create our array for weighted rolling
			var distribution_array = [];
			
			var distr = _slot_die.distribution; // the distribution to check for, can be overridden by _keepsake_weighting
		
			if (_keepsake_weighting != "") {
				distr = _keepsake_weighting;
			}
		
			// depending on distribution, use the array or not
			define_dice_distributions(distr, _min_roll, _max_roll, distribution_array);
			
			//show_debug_message("---" + string(_min_roll));
			//show_debug_message("dice MINIMUM roll is " + string(_min_roll));
			//show_debug_message("---" + string(_min_roll));
			
			// Our new weighted roll values, will be a range from 1 to the sum of the entire distribution array
			var weight_min = 1;
			var weight_max = 0;
			for (var d = 0; d < array_length(distribution_array); d++) {
				weight_max += distribution_array[d];
			}
			// a squeezed range can leave a core's weights all zero (Mock caps attacks at 1, and "weighted" or "dome" give
			// a 1-1 range no weight): every face it can still roll counts the same then, so the roll always lands (B125)
			if (weight_max <= 0) {
				for (var d = 0; d < array_length(distribution_array); d++) distribution_array[d] = 1;
				weight_max = array_length(distribution_array);
			}

			// rolled dice: the number it rolled when dealt (die_roll_faces), kept within today's range
			var _face = -1;
			if (die_has_faces(_slot_die) && _face_index < array_length(_slot_die.faces)) _face = clamp(_slot_die.faces[_face_index], _min_roll, _max_roll);
			_face_index++;

			// Roll between all the values in the array
			var weighted_roll = irandom_range(weight_min, weight_max);
			var _rolled_twice = undefined; // both faces, when the die rolls twice and keeps the higher
			// roll advantage. A die that already rolled twice when dealt (Accurate) doesn't again; a keepsake's
			// "roll twice" (Navigation Chart, Starver's Efficiency) rolls once more and keeps the higher.
			if (_slot_die.roll_twice || (dice_output.roll_twice && !(_face != -1 && variable_struct_exists(_slot_die, "faces_twice") && _slot_die.faces_twice))) {
				var second_roll = irandom_range(weight_min, weight_max);
				var _first_face = (_face != -1) ? _face : weighted_to_face(distribution_array, weighted_roll, _min_roll);
				var _second_face = weighted_to_face(distribution_array, second_roll, _min_roll);
				_rolled_twice = [_first_face, _second_face];

				if (_face != -1) _face = max(_face, _second_face);
				else if (second_roll > weighted_roll) weighted_roll = second_roll;

				_slot_die.roll_twice = false; // reset after we roll twice
			}
			
			// Get roll amount if we are forcing (an effect's forced roll wins over the rolled face)
			var _force = (_slot_die.forced_roll != -1) ? _slot_die.forced_roll : _face;
			if (_force != -1) {
			    var _clamped_forced = clamp(_force, _min_roll, _max_roll);
			    // the forced face must have some weight, or the lookup below stops on an earlier face, or on none (B125)
			    var _fk = _clamped_forced - _min_roll;
			    if (_fk >= 0 && _fk < array_length(distribution_array) && distribution_array[_fk] <= 0) distribution_array[_fk] = 1;
			    weighted_roll = 0;
    
			    for (var d = 0; d < (_clamped_forced - _min_roll + 1); d++) {
			        weighted_roll += distribution_array[d];
			    }
			}
			
			// used for determining which numbers can actually be rolled when taking into account distribution
			var actual_possible_numbers = [];
		
			// Assign a value to that rolled weighted value, 1,2,3 = 1; 4,5,6,7 = 2; 8,9,10,11,12 = 3; 13,14,15,16,17,18 = 4; for a d4
			for (var d = 0; d < array_length(distribution_array); d++) {
				// remove this arrays value
				weighted_roll -= distribution_array[d];
				
				// add to our actual possible numbers array any entry that isn't empty (aka its a number that can be rolled)
				if (distribution_array[d] != 0)	{
					array_push(actual_possible_numbers, d + _min_roll );
					//show_debug_message("Adding  " + string( d + _min_roll ) + " to the list of actual possible numbers for this die");
				}
				
				//show_debug_message("---");
				//show_debug_message("Current array iteration index  " + string(d));
				//show_debug_message("Current array iteration value  " + string(distribution_array[d]));
				//show_debug_message("Weighted roll after subtraction is " + string(weighted_roll));
			
				// once we reach our number, assign the final roll value
				if (weighted_roll <= 0) {
					final_roll = d + _min_roll;
					
					var ctx = {
						_d_amount: final_roll,
						_p_slot_type: _prev_slot_type,
						_c_slot_type: _type,
						_slot_die: _slot_die,
						die: _slot_die,
						min_roll: (array_length(actual_possible_numbers) > 0) ? actual_possible_numbers[0] : _min_roll, // first row in distribution array that isn't zero (never read an empty list: B125)
						max_roll: _max_roll,
						slot_bonus: slot_bonus_amount,
						keepsake_bonus: _keepsake_dice_bonus_amount,
						// the slot's first-die bonus, if this is that die (Repeater Rail, Single Focus)
						first_bonus: (_dice_list_index == 0 && !first_die_bonus_used && _slot_number >= 0 && _slot_number < ds_list_size(oCombat.action_queue)) ? oCombat.action_queue[| _slot_number].first_die_bonus : 0,
						dice_index: _dice_list_index,
						_slot: oCombat.action_queue[| _slot_number],
						slot_num: _slot_number, 
						//max_roll: actual_possible_numbers[ array_length(actual_possible_numbers) - 1] // first row in distribution array that isn't zero -- THIS isn't possible yet because we need to continue looping through the numbers after we find our actual number to check for what our real max is
					}
					
					// rolled twice: show both faces, then the one kept
					if (is_array(_rolled_twice)) {
						roll_popup(_slot_number, _dice_list_index, "Rolled " + string(_rolled_twice[0]) + " and " + string(_rolled_twice[1]) + ", kept " + string(max(_rolled_twice[0], _rolled_twice[1])), global.color_intel);
					}

					combat_trigger_effects("after_roll_die", ctx);

					if (_slot_die.reset_after_next_roll != false && _slot_die.reset_this_turn) {
						_slot_die.reset_after_next_roll(_slot_die);
						_slot_die.reset_after_next_roll = false;
					}
					
					final_roll = ctx._d_amount + slot_bonus_amount + _keepsake_dice_bonus_amount;
					final_roll = max(0, final_roll); // a die never rolls below 0 (Splash's -2 on a 1)

					// bonuses that only apply to the first die in the slot (Repeater Rail)
					if (_dice_list_index == 0 && !first_die_bonus_used && _slot_number >= 0 && _slot_number < ds_list_size(oCombat.action_queue)) {
						final_roll += oCombat.action_queue[| _slot_number].first_die_bonus;
						first_die_bonus_used = true;
					}
					
					// die statistics
					_slot_die.statistics.times_played_this_combat++;
					
					array_push(_slot_die.statistics.roll_history, final_roll);
					
					break;
				}
			}
		} else {
			// an enemy uses the dice it rolled when its intent was set (shown when Legible)
			if (is_struct(_source) && variable_struct_exists(_source.intent, "rolls") && _enemy_roll_index < array_length(_source.intent.rolls) && _source.intent.move.dice_value == _dice_value) {
				final_roll = _source.intent.rolls[_enemy_roll_index];
			} else {
				final_roll = irandom_range( _min_roll, _max_roll );
			}
			_enemy_roll_index++;
			
			var ctx = {
				_d_amount: final_roll,
				action_type: _type,
				owner: _source,
				target: _source, // the roller, same meaning as for player rolls (buffs check owner == target)
			}
			
			// We need to make sure we update the visuals for enemy intent roll values with these buffs in mind.
			//show_debug_message("Rolled amound before buffs " + string(final_roll));
					
			trigger_debuff_list(_source.debuffs, "on_roll_die", ctx);
					
			final_roll = ctx._d_amount;
			//show_debug_message("Rolled amound after buffs " + string(final_roll));
			
			if (!enemy_bonus_used_once) {
				final_roll += slot_bonus_amount;
				enemy_bonus_used_once = true;
			}
		}
		
		amount += final_roll; // add the roll, the slot bonus and the keepsake/dice bonus to create the final amount.
			
		var ctx = {
			final_amount: amount,
			type: _type,
			_slot_die: _slot_die,
			slot_num: _slot_number,
		}
					
		combat_trigger_effects("after_slot_damage_calculated", ctx);
		
		// Set the rolled value of this dice to 
		if (_slot_die != undefined) {
			_slot_die.rolled_value = amount;
		}
		
		// Used for drawing numbers above slots
		//if (_slot_number != -1) {
		//	spawn_floating_number("slot", amount, -1, c_white, -1, _slot_number, _dice_amount);
		//}
	}
	
	// used for flat damage
	if (_dice_amount == 0) {
		amount = _dice_value;
		//show_debug_message("dice amount is zero - this is for flat damage - setting value to "+string(_dice_value));
	}

	// an intent the Quill halved: its attack, block or heal comes out at half
	if (is_struct(_source) && variable_struct_exists(_source, "intent") && intent_is_halved(_source) && (_type == "ATK" || _type == "BLK" || _type == "HEAL")) {
		amount = floor(amount / 2);
	}


    var inst_color = c_red; // default color for damage
	
	// If it's actions from the player
	if (_source == "player") {
		var snd_roll = choose(soDiceRolling1, soDiceRolling2, soDiceRolling3);
		sfx_play(snd_roll, AUDIO_GROUP.SFX, random_range(0.01, 0.05), 0.4);
	}

    // --- DAMAGE ---
    switch (_type) {
		case "ATK":
        
			var block_used = 0;
	        var final_damage = amount;

	        // Player attacking enemy
	        if (_target != "player") {
				
				if (_dice_amount > 0) {
					global.player_x += 50;
				}
					
				// before_enemy_take_damage is used to make adjustments before block is calculated
				var before_ctx = {
					source: _source,
					target: _target,
					owner: _target,
					amount: final_damage,
				};

				trigger_debuff_list(_target.debuffs, "before_enemy_take_damage", before_ctx);
				
				final_damage = before_ctx.amount;
				
				if (final_damage <= 0) {
					spawn_floating_number(_target, 0, -1, global.color_block, 1, -1, _dice_list_index);
				}
				
				//show_debug_message("Value of taken_damage_this_turn: " + string(_target.taken_damage_this_turn));
			
	            // If the enemy has block
	            if (_target.block_amount > 0) {
	                block_used = clamp(final_damage, 0, _target.block_amount);
	                _target.block_amount -= block_used;
	                final_damage -= block_used;
	
	                var num = spawn_floating_number(_target, block_used, -1, global.color_block, -1, -1, _dice_list_index);
					num.x += 20;
					num.y += 20;
	            }

	            // Deal any remaining damage
	            if (final_damage > 0) {
					
					// Only trigger debuffs/buffs on the enemy that actually took damage
					var ctx = {
					    source: _source,
					    target: _target,
					    owner: _target,
						amount: final_damage,
					};

					trigger_debuff_list(_target.debuffs, "on_enemy_take_damage", ctx);
					
	                _target.hp = max(0, _target.hp - final_damage);
	                spawn_floating_number(_target, final_damage, -1, c_red, -1, -1, _dice_list_index);
					run_stat_add("damage_dealt", final_damage);
					run_stat_max("biggest_hit", final_damage);
	            }

	            inst_color = c_red;
				
				// Enemy death event
				if (_target.hp <= 0 && !_target.dead) {
					//show_debug_message("Enemy target index: " + string(enemy_target_index));
					
					_target.dead = true;
					enemy_turns_remaining--;
					enemies_left_this_combat--;
							
					// Remove any debuffs from the enemy
					for (var d = ds_list_size(_target.debuffs) - 1; d >= 0 ; d--) {
						var inst = _target.debuffs[| d];
							ds_list_delete(_target.debuffs, d);
					}
					
					enemies_to_fade_out += 1;
					_target.alpha = 0.5;
					
					var possible_new_targets = ds_list_create();
					var new_target = undefined;
					
					for (var e = 0; e < ds_list_size(room_enemies); e++) {
						if (!room_enemies[| e].dead) ds_list_add(possible_new_targets, room_enemies[| e]);
					}
					
					new_target = possible_new_targets[| irandom(ds_list_size(possible_new_targets) - 1)];
					
					enemy_target_index = ds_list_find_index(room_enemies, new_target);
					
					ds_list_destroy(possible_new_targets);
					
					var context = {
						target: _target,
					};
					
					combat_trigger_effects("on_enemy_death", context);

					// when an elite or the boss falls, the rest of its crew flee: no gold, and the fight is won
					if (enemy_is_leader(_target)) combat_enemies_flee(_target);

					//show_debug_message("Enemies left this combat: " + string(enemies_left_this_combat));
					//show_debug_message("NEW Enemy target index: " + string(enemy_target_index));
				}
	        }

	        // Enemy attacking player
	        else {
				if (_dice_amount != 0) _source.pos_x -= 50;
				
	            if (player_block_amount > 0) {
	                block_used = clamp(final_damage, 0, player_block_amount);
	                player_block_amount -= block_used;
	                final_damage -= block_used;

	                var num = spawn_floating_number("player", block_used, -1, global.color_block, -1, -1, _dice_list_index);
					num.x += 40;
					num.y += 40;
	            }

	            if (final_damage > 0) {
	                global.player_hp = max(0, global.player_hp - final_damage);
	                spawn_floating_number("player", final_damage, -1, c_red, -1, -1, _dice_list_index);
					run_stat_add("damage_taken", final_damage);
				
	            }

	            inst_color = c_red;
	        }
				
			switch (amount) {
				case 1:
				case 2:
				case 3:
				case 4:
					var snd_atk = choose(soSwordLight1, soSwordLight2, soSwordLight3, soSwordLight4);
					sfx_play(snd_atk, AUDIO_GROUP.SFX, random_range(0.01, 0.05), 1.0);
				break;
					
				default:
					var snd_atk = choose(soSwordMedium1, soSwordMedium2);
					sfx_play(snd_atk, AUDIO_GROUP.SFX, random_range(0.01, 0.05), 1.0);
				break;
			}
		break;

	    // --- BLOCK ---
	    case "BLK":
	        if (_target != "player") {
				_target.turns_since_last_block = 0;
	            _target.block_amount += amount;
				
				// Animate shield
				var shield = instance_create_depth(_target.pos_x, _target.pos_y, depth, oSingleParticle);
				
	        } else if (_target == "player") {
	            player_block_amount += amount;
				
				var ctx = {
					block_gained: amount,
				}
				
				combat_trigger_effects("on_player_block_gained", ctx)
				
				// Animate shield
				var shield = instance_create_depth(global.player_x, global.player_y, depth, oSingleParticle);
	        }

	        spawn_floating_number(_target, amount, -1, global.color_block, 1, -1, _dice_list_index);
	        inst_color = global.color_block;
				
			switch (amount) {
				case 1:
				case 2:
				case 3:
				case 4:
					var snd_block = choose(soShieldLight1, soShieldLight2);
					sfx_play(snd_block, AUDIO_GROUP.SFX, random_range(0.01, 0.05), 1.0);
				break;
					
				default:
					var snd_block = choose(soShieldMedium, soShieldMedium);
					sfx_play(snd_block, AUDIO_GROUP.SFX, random_range(0.01, 0.05), 1.0);
				break;
			}
		break;

	    // --- HEAL ---
	    case "HEAL":
	        if (_target != "player") {
	            _target.hp = min(_target.max_hp, _target.hp + amount);
				particle_emit(_target.pos_x, _target.pos_y, "rise", c_lime);
				if (_target != _source) {
					particle_emit(_source.pos_x, _source.pos_y, "burst", c_lime);
				}
	        } else if (_target == "player") {
	            global.player_hp = min(global.player_max_hp, global.player_hp + amount);
				if (room == rmCombat) {
					particle_emit(global.player_x, global.player_y, "burst", c_lime);
				} else {
					particle_emit(global.heal_pos, 25, "burst", c_lime, 30);
				}
	        }
			
			if (room == rmCombat) {
				spawn_floating_number(_target, amount, -1, c_lime, 1);
			}
	        inst_color = c_lime;
		break;
		
		case "DEBUFF":
			if (_target == "player") {
				var _duration = _source.intent.move.duration;
				var _permanent = false;
				if (_source.intent.move.duration == -1) {
					_duration = 1;
					_permanent = true;
				}
				// enemy debuffs land after the player has acted, so they always last through the following turn
			    apply_buff("player", _source.intent.move.debuff, _duration, _source.intent.move.amount, true, { source: _source, index: _source_index }, _permanent);
				particle_emit(global.player_x, global.player_y, "burst", _source.intent.move.debuff.color);
				
				combat_trigger_effects( "on_player_debuffed", {});
			}
		break;
		
		case "BUFF":
			if (_target != "player") {
				var _duration = _source.intent.move.duration;
				var _permanent = false;
				if (_source.intent.move.duration == -1) {
					_duration = 1;
					_permanent = true;
				}
				// _target is the enemy itself, or an ally when the move targets "other"
			    apply_buff(_target, _source.intent.move.debuff, _duration, _source.intent.move.amount, true, { source: _source, index: _source_index }, _permanent);
			}
		break;
		
		case "INTEL":
			if (_source == "player") {
				// insight counts next turn
				apply_buff("player", oRunManager.buff_intel, 1, amount, oRunManager.buff_intel.remove_next_turn, { source: _source, index: _source_index });
				var num = spawn_floating_number("player", amount, -1, global.color_intel, 1, -1, _dice_list_index);
				num.x += 20;
				num.y -= 20;
			} else {
			    apply_buff("player", oRunManager.debuff_overwhelm, 1, 3, oRunManager.debuff_overwhelm.remove_next_turn, { source: _source, index: _source_index });
				particle_emit(global.player_x, global.player_y, "burst", oRunManager.debuff_overwhelm.color);
			}
		break;
		
		case "SUMMON":
			add_enemy_to_fight(enemy_find_by_name(_source.intent.move.summon));
			enemies_left_this_combat++;
			
			//global.enemy_x = display_get_gui_width() / 2 + 650 + (enemies_left_this_combat*110);
			//enemy_x_offset = -460 + (enemies_left_this_combat*80);
			//enemy_y_offset = -90;

			for (var e = 0; e < ds_list_size(room_enemies); e++) {
				var enemy_data = room_enemies[| e].data;
				var enemy = room_enemies[| e];
	
				enemy.pos_x = global.enemy_x - 200 + (enemy_x_offset * e);
				enemy.pos_x_start = global.enemy_x - 200 + (enemy_x_offset * e);
				enemy.pos_y = global.enemy_y + (enemy_y_offset * e);
				enemy.pos_y_start = global.enemy_y + (enemy_y_offset * e);
				enemy.start_scale = 1.0 - ((enemies_left_this_combat-1) * 0.1);
				enemy.target_scale = 1.08 - ((enemies_left_this_combat-1) * 0.1);
				enemy.bar_scale = 1.0 - ((enemies_left_this_combat-1) * 0.2);
			}
		break;
	}
}


function spawn_floating_number(_target, _amount, _txt, _inst_color, _num_sign, _slot_number = -1, _number = -1) {
	// Spawn floating number
    var inst_x, inst_y;
	
	var offset_x = 30 * (sin(_number*30));
	var offset_y = (_number * 30);
	
    switch (_target) {
		
		case "player":
        inst_x = global.player_x + offset_x;
        inst_y = global.player_y + offset_y;
		break;
		
		case "slot":
		inst_x = slot_positions[| _slot_number].x + global.gui.action_tile_w/2 + random_range(-50, 50);
		inst_y = slot_positions[| _slot_number].y - 80 + random_range(-50, 50);
		break;
		
		case "bag":
		inst_x = 165;
		inst_y = 1000;
		break;
		
		default:
		inst_x = _target.pos_x;
		inst_y = _target.pos_y;
    }

	inst_x += sin(instance_number(oDamageText) * 30) * 40;
	inst_y += instance_number(oDamageText) * 20;
	
    var inst = instance_create_layer(inst_x, inst_y, "Instances", oDamageText);
	inst.txt = _txt;
    inst.amount = _amount;
    inst.color_main = _inst_color;
	inst.num_sign = _num_sign;
	
	return inst;
}

/// @param die_id  The instance ID of the dropped die
/// @param slot_index  The index of the hovered slot

/// @func slot_placement_check(_die_struct, _slot, _slot_i)
/// @desc The one placement rule. Says whether this die can go in this slot right now, what placing it would do,
///       and if not, why (shown to the player). Used by the slot highlight, the hover hint and apply_dice_to_slot.
/// @returns {struct} { ok, action, reason }
///          action: "claim" (an empty slot takes the die's type), "replace" (an Exclusive die clears a slot of
///          another type and claims it), "add" (joins the slot)
function slot_placement_check(_die_struct, _slot, _slot_i) {
	var _no = function(_reason) { return { ok: false, action: "", reason: _reason }; };
	var _yes = function(_action) { return { ok: true, action: _action, reason: "" }; };

	// coins are free to play; everything else needs a play left this turn
	if (dice_played + 1 > dice_allowed_per_turn && !die_has_keyword(_die_struct, "coin")) {
		return _no("No plays left this turn. Coins are still free to play.");
	}

	// slots fill left to right: every slot before this one needs an action (a chained slot doesn't count)
	for (var j = 0; j < _slot_i; j++) {
		if (j == locked_slot) continue;
		if (!slot_has_action(action_queue[| j])) return _no("Slots fill in order: slot " + string(j + 1) + " needs an action first.");
	}

	var _slot_empty = (_slot.possible_type == "None");
	var _slot_all = (_slot.possible_type == "All");
	var _die_neutral = (_die_struct.possible_type == "None");
	var _die_exclusive = die_has_keyword(_die_struct, "Exclusive");
	var _slot_exclusive = false;
	for (var i = 0; i < ds_list_size(_slot.dice_list); i++) {
		if (die_has_keyword(_slot.dice_list[| i], "Exclusive")) _slot_exclusive = true;
	}
	// rolled dice: any size of die can join a slot (there used to be a "d6 or bigger" rule, with coins let off it)

	// does the die share a type with the slot?
	var _matches = false;
	var _die_types = string_split(_die_struct.possible_type, " ");
	for (var n = 0; n < array_length(_die_types); n++) {
		if (string_pos(_die_types[n], _slot.possible_type)) _matches = true;
	}

	// an Exclusive die always takes the whole slot: whatever is in it is ejected, as its keyword says. (A slot built by
	// sacrificing neutral dice has no type yet but does hold dice, so "claim" alone left them in.)
	if (_die_exclusive && !_die_neutral && ds_list_size(_slot.dice_list) > 0) return _yes("replace");

	if (!_die_neutral) {
		if (_slot_empty) return _yes("claim");
		if (_slot_all) return _no("Coloured dice can't go in an 'All' slot.");
		if (_matches) {
			if (_die_exclusive) return _no("Exclusive dice need a slot to themselves.");
			if (_slot_exclusive) return _no("This slot holds an Exclusive die, nothing can join it.");
			return _yes("add");
		}
		if (_die_exclusive) return _yes("replace");
		return _no("This die's type doesn't match this slot.");
	}

	// neutral dice join slots that already have a type, they can't start one
	if (_slot_all) return _yes("add");
	if (_slot_empty) return _no("Neutral dice can't start a slot. Play a coloured die here first.");
	if (_die_exclusive) return _no("Exclusive dice need a slot to themselves.");
	if (_slot_exclusive) return _no("This slot holds an Exclusive die, nothing can join it.");
	return _yes("add");
}

function apply_dice_to_slot(_die, _slot_i) {
    var die  = _die;
    var slot = action_queue[| _slot_i];

	// the same rule the highlight and hover hint use
	var check = slot_placement_check(die.struct, slot, _slot_i);
	var reject_dice = !check.ok;

	// a rejected drop says why, in the same words as the hover hint
	if (!check.ok) throw_error("Can't place here", check.reason);

	if (!check.ok && dice_played + 1 > dice_allowed_per_turn && !die_has_keyword(die.struct, "coin")) {
		// out of plays: flash the dice-played counter
		dice_played_scale = 1.4;
		dice_played_color = c_red;
		return;
	}

	if (check.ok) {
		var sticky = die_has_keyword(die.struct, "sticky");
		var _was_empty = (ds_list_size(slot.dice_list) == 0);

		switch (check.action) {
			case "replace":
				// an Exclusive die clears out the slot (any type), then claims it
				eject_dice_in_slot(oCombat.action_queue[| _slot_i], oCombat.slot_positions[| _slot_i], true);
			// fall through to claim
			case "claim":
				// an empty slot becomes the die's type, and the die stays a turn (base)
				slot.current_action_type = die.struct.action_type;
				slot.possible_type = die.struct.possible_type;
				ds_list_add(slot.dice_list, clone_die(die.struct, "base"));
			break;

			case "add":
				// coloured dice stay a turn (base), neutral dice leave at the end of this one (temporary)
				var permanence = (die.struct.possible_type == "None") ? "temporary" : "base";
				if (sticky) permanence = "sticky";
				ds_list_add(slot.dice_list, clone_die(die.struct, permanence));

				// a multitype die adds any types the slot doesn't have yet
				var parts = string_split(die.struct.possible_type, " ");
				if (array_length(parts) > 1) {
					for (var i = 0; i < array_length(parts); i++) {
						if (string_pos(string(parts[i]), slot.possible_type) == 0) {
							slot.possible_type = string_concat(slot.possible_type, " ", parts[i]);
						}
					}
				}

				// rolled dice: the first die in an empty built slot (Attack/Block...) picks its type for the turn
				if (_was_empty && die.struct.action_type != "None" && string_pos(die.struct.action_type, slot.possible_type) > 0) {
					slot.current_action_type = die.struct.action_type;
				}
			break;
		}

		// rolled dice: it can be taken back this turn (combat_take_back), unless it has a "when played" effect of its own
		var _added = slot.dice_list[| ds_list_size(slot.dice_list) - 1];
		_added.played_turn = turn_count;
		_added.play_locked = die_has_effect_trigger(die.struct, "on_dice_played_to_slot");
	}

    //-----------------------------------------
    // Result
    //-----------------------------------------
    if (!reject_dice) {
		var played_data = {
			_slot: slot,
			_slot_num: _slot_i,
			_d_struct: die.struct,
			_slot_die: die.struct,
			dice_object: die,
			duplicate_die: false
		};
		
		particle_emit(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "burst", get_dice_color(die.struct.possible_type), 30);

		// "when played" effects fire once per die per turn: a die taken back and played again doesn't fire them twice
		var _first_play = !array_contains(played_uids, die.struct.uid);
		if (_first_play) {
			array_push(played_uids, die.struct.uid);
			combat_trigger_effects("on_dice_played_to_slot", played_data);
			run_stat_add("dice_played", 1);
			die.struct.statistics.times_played_this_combat++;
		} else {
			// keepsakes that read the queue (Single Focus, Repeater Rail) still work it out again
			runmanager_trigger_keepsakes("after_change_current_action", {});
		}

		if (played_data.duplicate_die) {
			var die_copy2 = clone_die(die.struct, "temporary");
			die_copy2.uid = global._die_uid_counter++; // a duplicate is its own die, so the two never answer for each other's rolls
			die_copy2.reset_at_end_combat = function(_dice) {
				ds_list_delete(global.dice_bag, ds_list_find_index(global.dice_bag, _dice));
			}
			ds_list_add(slot.dice_list, die_copy2);
		}
	
        add_feed_entry("You used a die!");
		if (!die_has_keyword(die.struct, "coin")) dice_played += 1;
		dice_played_scale = 1.2;
		dice_played_color = c_green;

		var place_sound = choose(soRubble1, soRubble2, soRubble3, soRubble4);

		sfx_play(place_sound, AUDIO_GROUP.SFX, random_range(0.01, 0.05), 0.2);
		
		instance_destroy(die);
    }
}

/// is_mouse_over_discard_button()
function is_mouse_over_discard_button() {
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);

    // Bottom-right button area (adjust as needed)
    var btn_w = global.gui.discard_w;
    var btn_h = global.gui.discard_h;
    var btn_x = display_get_gui_width() - btn_w - 40;
    var btn_y = display_get_gui_height() - btn_h - 40;

    return (mx > btn_x && mx < btn_x + btn_w && my > btn_y && my < btn_y + btn_h);
}

function discard_dice(_die) {
    var die = _die;

    // --- 1. Determine which struct this die uses
    var die_struct;
    if (variable_instance_exists(die, "die_struct")) {
        die_struct = die.die_struct;
    } else {
        die_struct = die.struct;
    }

    // --- 2. Clone the struct before adding to discard pile
    var die_copy = clone_die(die_struct, "");
    die_clear_faces(die_copy); // rolled dice: it rolls fresh next time it's dealt

    // --- 3. Add to discard pile
    ds_list_add(global.discard_pile, die_copy);

    // --- 4. Cleanup visuals
    instance_destroy(die);

    // --- 5. Combat feed + reset state
    if (instance_exists(oCombat)) oCombat.is_discarding = false;
    //with (oCombat) add_feed_entry("You discarded a die!");
}

function add_dice_to_bag(_die) {
	var die = _die;

    // --- 1. Determine which struct this die uses
    var die_struct;
    if (variable_instance_exists(die, "die_struct")) {
        die_struct = die.die_struct;
    } else {
        die_struct = die.struct;
    }

    // --- 2. Clone the struct before adding to discard pile
    var die_copy = clone_die(die_struct, "");
    die_clear_faces(die_copy); // rolled dice: it rolls fresh next time it's dealt

    // --- 3. Add to discard pile
    ds_list_add(global.dice_bag, die_copy);

    // --- 4. Cleanup visuals
    instance_destroy(die);
}



/// @func sacrifice_die(_die)
/// @desc Rolled dice: a die dropped on the new-slot tile waits there (it uses a play, coins are free, and it can be taken
///       back) until enough dice on it (new_slot_min_dice) add up to new_slot_threshold. Then the slot is built (combat_try_build_slot).
function sacrifice_die(_die) {
	if (!combat_all_slots_have_action()) {
		throw_error("Fill your slots first", "A new slot can only be built once every slot you have has an action.");
		return;
	}
	// a slot built from one die (the first you build) takes just that die, and it has to reach the number on its own
	if (new_slot_min_dice() == 1) {
		var _face = die_face_total(_die.struct);
		if (_face == -1) _face = ceil(_die.struct.dice_value / 2);
		if (_face < new_slot_threshold()) {
			throw_error("Too low", "This slot needs one die of " + string(new_slot_threshold()) + " or more. This one rolled " + string(_face) + ".");
			return;
		}
	}
	if (dice_played + 1 > dice_allowed_per_turn && !die_has_keyword(_die.struct, "coin")) {
		dice_played_scale = 1.4;
		dice_played_color = c_red;
		throw_error("No plays left", "No plays left this turn. Coins are still free to play.");
		return;
	}
	if (!die_has_keyword(_die.struct, "coin")) dice_played += 1;
	dice_played_scale = 1.2;
	dice_played_color = c_green;

	var _copy = clone_die(_die.struct, "temporary");
	_copy.played_turn = turn_count; // it can be taken back until the slot is built (combat_take_back, slot -1)
	_copy.play_locked = false;
	ds_list_add(global.sacrifice_list, _copy);

	particle_emit(_die.x, _die.y, "burst", _die.struct.color);
	instance_destroy(_die);
	sfx_play(choose(soRubble1, soRubble2, soRubble3, soRubble4), AUDIO_GROUP.SFX, random_range(0.01, 0.05), 0.2);

	update_sacrificed_type_array();
	combat_try_build_slot();
}

/// @func new_slot_threshold()
/// @desc What the dice on the new-slot tile must add up to: 3 for slot 2, 6 for slot 3, 9 for slot 4... (Cursed Heart: +3).
function new_slot_threshold() {
	var _slot_number = ds_list_size(oCombat.action_queue) + 1;
	return max(3, 3 * (_slot_number - 1) + 3 * oCombat.slot_cost_modifier);
}

/// @func new_slot_min_dice()
/// @desc How many dice the new-slot tile needs at least: 1 for slot 2, 2 for slot 3, 3 for slot 4...
function new_slot_min_dice() {
	return max(1, ds_list_size(oCombat.action_queue));
}

/// @func new_slot_total()
/// @desc What the dice on the new-slot tile add up to (their rolled numbers).
function new_slot_total() {
	var _t = 0;
	if (!ds_safe_exists(global.sacrifice_list, ds_type_list)) return 0;
	for (var j = 0; j < ds_list_size(global.sacrifice_list); j++) {
		var _d = global.sacrifice_list[| j];
		var _f = die_face_total(_d);
		_t += (_f != -1) ? _f : ceil(_d.dice_value / 2); // a die that wasn't dealt (and so never rolled) counts half its size
	}
	return _t;
}

/// @func combat_try_build_slot()
/// @desc Builds a new slot once enough dice on the tile (new_slot_min_dice) reach the threshold. Their "when sacrificed" effects fire now,
///       and they become the slot's first dice for this turn (locked in), so this turn it has their types. Like every
///       slot it's empty and untyped again after End Turn; what it keeps is its place, worth a bonus (slot_set_position_bonus).
function combat_try_build_slot() {
	if (ds_list_size(global.sacrifice_list) < new_slot_min_dice() || new_slot_total() < new_slot_threshold() || !combat_all_slots_have_action()) return;

	combat_trigger_effects("on_new_slot_created", { slot_index: ds_list_size(action_queue) + 1 });

	// "when sacrificed" effects. They expect the die in hand (data.die.struct), so each gets a stand-in at the tile.
	var _tx = is_struct(new_tile_pos) ? new_tile_pos.x + new_tile_pos.w / 2 : gui_w / 2;
	var _ty = is_struct(new_tile_pos) ? new_tile_pos.y : gui_h / 2;
	var sacrifice_data = {};
	for (var j = 0; j < ds_list_size(global.sacrifice_list); j++) {
		var _d = global.sacrifice_list[| j];
		sacrifice_data = {
			die: { struct: _d, x: _tx, y: _ty, can_discard: false },
			_d_struct: _d,
			slot_index: ds_list_size(action_queue),
		};
		trigger_die_effects_single(_d, "on_sacrifice_die", sacrifice_data);
		runmanager_trigger_keepsakes("on_sacrifice_die", sacrifice_data);
	}

	// untyped like every slot (it resets each turn); this turn its types come from the dice in it (slot_recompute_types)
	var _new_slot = combat_new_slot("None");
	slot_set_position_bonus(_new_slot, ds_list_size(action_queue));
	var _first_type = "";

	// the dice that built it become its first dice and act this turn (discarded at End Turn like the rest). They're
	// locked in: taking one back would leave a slot built for free. The first coloured one picks the slot's type.
	for (var j = 0; j < ds_list_size(global.sacrifice_list); j++) {
		var _src = global.sacrifice_list[| j];
		var _in = clone_die(_src, (_src.possible_type == "None") ? "temporary" : "base");
		_in.played_turn = turn_count;
		_in.play_locked = true;
		_in.built_slot = true;
		ds_list_add(_new_slot.dice_list, _in);
		if (_first_type == "" && _src.action_type != "None") _first_type = _src.action_type;
	}
	slot_recompute_types(_new_slot);
	if (_first_type != "" && string_pos(_first_type, _new_slot.possible_type) > 0) _new_slot.current_action_type = _first_type;
	ds_list_clear(global.sacrifice_list);
	update_sacrificed_type_array();
	ds_list_add(action_queue, _new_slot);

	combat_trigger_effects("after_new_slot_created", sacrifice_data);
	particle_emit(_tx, _ty + 60, "burst", c_white, 30); // the new slot takes the tile's place
}

function update_sacrificed_type_array() {
	type_array = [];
	// Build unique types from global.sacrifice_list (as before)
	for (var s = 0; s < ds_list_size(global.sacrifice_list); s++) {
		var die_struct = global.sacrifice_list[| s];
			
		var poss_types = string_split(die_struct.possible_type, " ");
		var total = array_length(poss_types);
			
		for (var t = 0; t < total; t++) {
			if (!array_contains(type_array, poss_types[t])) {
				array_push(type_array, poss_types[t]);
				//show_debug_message("Possible slot types for last slot: "+string(total));
				//show_debug_message("Possible type size "+string(ds_list_size(global.sacrifice_list)));
				//show_debug_message("Sacrifice list size "+string(ds_list_size(global.sacrifice_list)));
			}
		}
	}
}

/// @func get_slot_stats(_slot, _num)
/// @desc Returns a struct with the live amount and highest value of all dice in this slot.
function get_slot_stats(_slot, _num) {
    var low = 0;
    var high = 0;
    var total_amount = 0;
    var _highest_value = 0;
    var _highest_value_base = 0;
	var different = false;

    for (var i = 0; i < ds_list_size(_slot.dice_list); i++) {
        var die_struct = _slot.dice_list[| i];
		var die_base = die_struct.permanence == "base" ? true : false;
		
		var dice_values = get_dice_output(die_struct, _num, -1, true, "player");
		
		// rolled dice: a die that has rolled counts its number, so the slot shows an exact total
		var _face = die_face_total(die_struct, dice_values.min_roll, dice_values.max_roll);
		low += ((_face != -1) ? _face : dice_values.min_roll) + dice_values.keepsake_dice_bonus_amount;
		high += ((_face != -1) ? _face : dice_values.max_roll) + dice_values.keepsake_dice_bonus_amount;
		
		if (die_struct.action_type != "None!") { 
			total_amount += die_struct.dice_amount;
		}
		
		if (i > 0 && _highest_value != die_struct.dice_value) different = true; // set to true if there are different types
        _highest_value = max(_highest_value, die_struct.dice_value);
		
		if (die_base) {
			_highest_value_base = max(_highest_value_base, die_struct.dice_value);
		}
    }

    return {
        low_roll: low + slot_total_bonus(_slot, total_amount), // used for displaying the minimum roll of this slot
        high_roll: high + slot_total_bonus(_slot, total_amount), // used for displaying the maximum roll of this slot
        amount: total_amount, // used for displaying the number of dice in this slot
        highest_value: _highest_value, // used for displaying the highest value dice in this slot -- we need to fix for 1d6 + 1d4, right now it shows as 2d6
		highest_value_base: _highest_value_base,
		differing_types: different
    };
}

/// @func draw_action_type_bars(_x, _y, _width, _types)
/// @desc Draw horizontal color bars for an array/list of action types.
/// @param _x        left coordinate
/// @param _y        top coordinate
/// @param _width    total width available for the bars
/// @param _types    array or ds_list of action type strings (e.g. ["ATK", "HEAL"])

/// @function draw_action_type_bars(_x, _y, _width, _types, _current_type)
/// @desc Draws colored bars for available action types. Highlights the current type.

function draw_action_type_bars(_x, _y, _width, _types, _current_type)
{
    var xx = _x;
    var yy = _y;
    var w = _width;
    var current_type = _current_type;

    // Default bar height
    var base_h = 12;
    var types = _types;

    // --- Detect and convert ds_list safely ---
    if (is_real(types) && ds_safe_exists(types, ds_type_list)) {
        var arr = array_create(ds_list_size(types));
        for (var i = 0; i < ds_list_size(types); i++) {
            arr[i] = types[| i];
        }
        types = arr;
    }

    // --- Safety: handle empty or "None" ---
    if (array_length(types) == 0 || (array_length(types) == 1 && types[0] == "None")) {
        types = ["None"];
    }

    var count = array_length(types);
    var bar_w = w / (count + 1);

    for (var i = 0; i < count; i++) {
        var type = types[i];
		var outline = false;

        // Color by type
        var col = get_dice_color(type);
		var index = 0;
		switch (type) {
			case "ATK": index = 1; break;
			case "BLK": index = 2; break;
			case "HEAL": index = 3; break;
			case "INTEL": index = 4; break;
		}

        // ✅ If this type matches the current slot type, make it taller
        if (type == current_type && current_type != "None") {
            outline = true;
        }

        var bar_x1 = xx + ((i+1) * bar_w);

        draw_set_color(col);
		draw_sprite_ext(sPossibleIcons, index, bar_x1, yy, 1, 1, 0, col, 1);
    }
}


/// @function can_place_dice_in_slot(_die_struct, _slot, _num)
/// @returns {bool} whether the slot highlights as a place this die can go: the same rule placing uses
function can_place_dice_in_slot(_die_struct, _slot, _num) {
	return slot_placement_check(_die_struct, _slot, _num).ok;
}

/// @function win_fight();
function win_fight() {
	
	if (!combat_end_effects_triggered) {
		var combat_end_data = {
		};
	
		combat_trigger_effects("on_combat_end", combat_end_data);
		
		combat_end_effects_triggered = true;
		
		// trigger bounty check
		if (oRunManager.active_bounty != undefined && oWorldManager.current_node_type == NODE_TYPE.ELITE) {
			if (!oRunManager.active_bounty.condition.failed) {
				oRunManager.active_bounty.complete = true;
			}
			
			var active_bounty_index = ds_list_find_index(oWorldManager.elite_list_before_bounty, oRunManager.active_bounty.elite_encounter);
			//show_debug_message("active bounty index: " + string(active_bounty_index));
			ds_list_delete(oWorldManager.elite_list_before_bounty, active_bounty_index);
			ds_list_copy(oWorldManager.possible_elites, oWorldManager.elite_list_before_bounty);
			ds_list_clear(oWorldManager.elite_list_before_bounty);
		}
		
		discard_dice_in_play(true);
		
		// --- Return discarded dice to bag ---
		if (ds_safe_exists(global.discard_pile, ds_type_list)) {
		    for (var i = 0; i < ds_list_size(global.discard_pile); i++) {
		        var discard_die = global.discard_pile[| i];
		        ds_list_add(global.dice_bag, clone_die(discard_die, ""));
		    }
		    ds_list_clear(global.discard_pile);
		}

		// When dice used to stay in slots, we did the below
		// --- Return historically sacrificed dice to bag ---
		//if (ds_safe_exists(global.sacrifice_history, ds_type_list)) {
		//    for (var j = 0; j < ds_list_size(global.sacrifice_history); j++) {
		//        var sac_die = global.sacrifice_history[| j];
		//        ds_list_add(global.dice_bag, clone_die(sac_die, ""));
		//    }
		//    ds_list_clear(global.sacrifice_history);
		//}
		
		// The new method for retrieving die is to eject all repeatedly until there are no dice left, then just return the sacrifice list die back to the bag
		if (ds_safe_exists(global.sacrifice_list, ds_type_list)) {
		    for (var j = 0; j < ds_list_size(global.sacrifice_list); j++) {
		        var sac_die = global.sacrifice_list[| j];
		        ds_list_add(global.dice_bag, clone_die(sac_die, ""));
		    }
		    ds_list_clear(global.sacrifice_list);
		}
	}
			
	if (!show_rewards && combat_end_effects_triggered) {
		// once per fight won, for the end-of-voyage summary
		run_stat_add("fights_won", 1);
		if (oWorldManager.current_node_type == NODE_TYPE.ELITE) run_stat_add("elites_won", 1);
		if (oWorldManager.current_node_type == NODE_TYPE.BOSS) run_stat_add("bosses_won", 1);

		// pop up rewards screen - dice reward - offered 3 dice, choose 1 to keep and credits
		reward_dice_options = ds_list_create();
		reward_consumable_options = ds_list_create();
		reward_keepsake_options = ds_list_create();
		
		if (oWorldManager.current_node_type != NODE_TYPE.ALIGNMENT) {
			generate_dice_rewards(reward_dice_options, global.master_dice_list, 3 );
		} else {
			generate_dice_rewards(reward_dice_options, global.alignment_dice_list, 2 );
		}
			
		repeat(3 + all_enemies_spared) ds_list_add(reward_scale, 0.1);
		
		if (oWorldManager.current_node_type == NODE_TYPE.ELITE || oWorldManager.current_node_type == NODE_TYPE.BOSS) {
			// bosses pay out from their own keepsake list
			var _keepsake_pool = (oWorldManager.current_node_type == NODE_TYPE.BOSS) ? global.boss_keepsake_list : global.rollable_keepsake_list;
			generate_keepsake_rewards(reward_keepsake_options, _keepsake_pool, 3);
			ds_list_add(reward_list, "keepsakes");
			ds_list_add(reward_list, "dice");
			generate_item_rewards(reward_consumable_options, global.master_item_list, 3);
			ds_list_add(reward_list, "consumables");
		} else {
			// Show dice every combat, show consumables at a 40% chance, gaining 10% chance every time they don't appear, losing 10% when they do.
			ds_list_add(reward_list, "dice");
			
			// Add consumables starting at a chance
			var con_chance = irandom_range(1, 100);

			// Show rewards if we meet the chance, and always show if we have the dutchman event taken, or we spared all enemies
			if (con_chance <= oRunManager.show_consumables_chance || oRunManager.dutchman_taken || all_enemies_spared) {
				var num_items = 3;
				if (all_enemies_spared) {
					if (oWorldManager.current_node_type == NODE_TYPE.ALIGNMENT) {
						num_items = 2;
					}
					if (oWorldManager.current_node_type == NODE_TYPE.BOSS || oWorldManager.current_node_type == NODE_TYPE.ELITE) {
						num_items = 3;
					}
				}
				
				generate_item_rewards(reward_consumable_options, global.master_item_list, num_items);
				ds_list_add(reward_list, "consumables");
				oRunManager.show_consumables_chance -= 30;
			} else {
				oRunManager.show_consumables_chance += 20 * round((global.player_luck - 50)/2);
			}
		}
			
		
	}
		
	show_rewards = true;
		
	if (rewards_all_taken) {
		// wait for all rewards to be taken and/or button skipped and then fade transition back to the main room
		room_goto(rmMap);
	}
}

/// @function get_action_name(_slot, _num);
function get_action_name(_slot, _num) {
	var stats = get_slot_stats(_slot, _num);
	var action_type = _slot.current_action_type;
	var total_amount = stats.amount;
	var highest_value = stats.highest_value;
	
	var label = "";
	
	switch (action_type) {
		case "All":
			label = "Empty";
		break;
		
		case "ATK":
		    switch (highest_value) {
		        case 4:
		            switch (total_amount) {
		                case 1: label = "Quick Slash"; break;
		                case 2: label = "Twin Strike"; break;
		                case 3: label = "Flurry\nof Blades"; break;
		                case 4: label = "Master\nDuelist"; break;
		                case 5: label = "Blade\nTornado"; break;
		                case 6: label = "Death\nby a thousand\ncuts"; break;
		            }
		        break;
        
		        case 6:
		            switch (total_amount) {
		                case 1: label = "Pistol Shot"; break;
		                case 2: label = "Double Tap"; break;
		                case 3: label = "Volley Fire"; break;
		                case 4: label = "Broadside\nBarrage"; break;
		                case 5: label = "Cannon\nBombardment"; break;
		                case 6: label = "Armada\nOnslaught"; break;
		            }
		        break;
        
		        case 8:
		            switch (total_amount) {
		                case 1: label = "Powerful\nSlash"; break;
		                case 2: label = "Heavy Swing"; break;
		                case 3: label = "Whirling\nOnslaught"; break;
		                case 4: label = "Captain's\nWrath"; break;
		            }
		        break;

		        default:
		            label = "Attack";
		    }
		break;
		
		case "BLK":
		    switch (highest_value) {
		        case 4:
		            switch (total_amount) {
		                case 1: label = "Sidestep"; break;
		                case 2: label = "Quick Parry"; break;
		                case 3: label = "Riposte"; break;
		                case 4: label = "Duelist's\nGuard"; break;
		                case 5: label = "Captain's\nShuffle"; break;
		                case 6: label = "Stand\nFirm"; break;
		            }
		        break;
        
		        case 6:
		            switch (total_amount) {
		                case 1: label = "Brace"; break;
		                case 2: label = "Raise Guard"; break;
		                case 3: label = "Hold\nthe Line"; break;
		                case 4: label = "Iron\nDefense"; break;
		                case 5: label = "Blockade"; break;
		                case 6: label = "Barricade"; break;
		            }
		        break;
        
		        case 8:
		            switch (total_amount) {
		                case 1: label = "Deflect"; break;
		                case 2: label = "Anchor Down"; break;
		                case 3: label = "Steel Wall"; break;
		                case 4: label = "Unbreakable"; break;
		            }
		        break;

		        default:
		            label = "Defend";
		    }
		break;
		
		case "HEAL":
		    switch (highest_value) {
		        case 4: label = "Bandage\nWound"; break;
		        case 6: label = "Swig of Rum"; break;
		        case 8: label = "Rally\nthe Crew"; break;
		        default: label = "Recover"; break;
		    }
		break;

		
		case "INTEL":
		    switch (highest_value) {
		        case 4: label = "Sleuth"; break;
		        case 6: label = "Gather insight"; break;
		        case 8: label = "Build a case"; break;
		        default: label = "Sleuth"; break;
		    }
		break;

		
		default:
			label = "No action";
	}
	
	return label;
}

function discard_dice_in_play(_all = false) {
	
	runmanager_trigger_keepsakes("on_not_used", {});
	
	with (oDice) {
		if (can_discard || _all) {
		    // Cache everything before we destroy the dice
		    var start_x = x;
		    var start_y = y;
		    var d_struct = struct; // local reference to the die’s struct
		
			if (room == rmCombat) {
				trigger_die_effects_single(d_struct, "on_not_used", {});
			}

		    // Pick color by action type
		    var col = get_dice_color(d_struct.possible_type);

		    // --- Spawn a particle before destroying the dice instance ---
		    var p = instance_create_layer(start_x, start_y, "Instances", oDiceParticle);

		    // Assign particle data BEFORE destroying the dice
		    p.die_struct = clone_die(d_struct, d_struct.permanence);
		    p.color_main = col;
			if (room == rmCombat) {
			    p.target_x = oCombat.gui_w - 150;  // discard button position
			    p.target_y = oCombat.gui_h - 130;
			} else {
				p.target_x = 60;
				p.target_y = 1040;
			}

		    // Finally destroy the dice instance
		    instance_destroy();
		}
	}
}

/// @func combat_trigger_effects(_event, _ctx, [_filter])
function combat_trigger_effects(_event, _ctx, _filter = "all") { // filter to either "player", a specific enemy, or "all"

    // 1) dice effects	
	if (room == rmCombat) {
		if (!variable_struct_exists(_ctx, "_die_struct")) {
			dice_trigger_effects(_event, _ctx);
		} else {
			trigger_die_effects_single(_ctx._die_struct, _event, _ctx)
		}
	}
   
	if (_filter == "player" || _filter == "all") {
		runmanager_trigger_keepsakes(_event, _ctx);
		
        // When checking player debuffs, the player is the owner
        _ctx.owner = "player"; 
        trigger_debuff_list(global.player_debuffs, _event, _ctx);
    }
		
	if (_filter != "player") {
        if (room == rmCombat) {
            for (var e = 0; e < ds_list_size(oCombat.room_enemies); e++) {
                var enemy = oCombat.room_enemies[| e];
                
                // CRITICAL: Set the owner to the specific enemy instance
                // This allows the debuff to know exactly who it is sitting on.
                _ctx.owner = enemy; 
                _ctx.owner_index = e;
                trigger_debuff_list(enemy.debuffs, _event, _ctx);
            }
        }
    }
	
	// 5) bounty conditions
	trigger_bounty(_event, _ctx);
}

function trigger_debuff_list(_list, _event, _ctx) {
    for (var i = ds_list_size(_list) - 1; i >= 0 ; i--) {
        var inst = _list[| i];
        var debuff = inst.template; 

        for (var e = 0; e < array_length(debuff.effects); e++) {
            var eff = debuff.effects[e];

            if (eff.trigger == _event && is_callable(eff.modify)) {
                // Attach the actual instance to the context
                _ctx.debuff = inst; 
                
                // Directly call the function
                eff.modify(_ctx);
			}
        }
		
		// Count down once per debuff (not once per effect), after its effects have fired
		if (debuff.removal_event == _event && !inst.permanent) {
			
			// Debuffs flagged remove_next_turn skip their first countdown, so they last through the following turn
			if (!inst.remove_next_turn) {
				inst.remaining--;
			}
			
			// Remove any debuffs which duration reaches zero
			if (inst.remaining <= 0) {
				// look the instance up again, an effect above may have added to this list
				var _index = ds_list_find_index(_list, inst);
				if (_index != -1) ds_list_delete(_list, _index);
			}
		}
    }
}

function eject_dice_in_slot(_slot, _slot_pos, _all) {
	
	var j = 0;
	while (j < ds_list_size(_slot.dice_list)) {
		var die = _slot.dice_list[| j];		
		die.rolled_value = -1;

		if (string_pos("temporary", die.permanence) > 0 || (die_has_keyword(die, "Loose")) || _all == true) {
				
			// Clean up sacrifice history
			if (ds_safe_exists(global.sacrifice_history, ds_type_list)) {
				for (var s = ds_list_size(global.sacrifice_history) - 1; s >= 0; s--) {
					var die_struct = global.sacrifice_history[| s];

					if (is_struct(die_struct)) {
						ds_list_delete(global.sacrifice_history, s);
					}
				}
			}
					
			// Use stored GUI coords for particle spawn
			var start_x = _slot_pos.x + (_slot_pos.w / 2);
			var start_y = _slot_pos.y + (_slot_pos.h / 2);

			// Spawn particle
			var p = instance_create_layer(start_x, start_y, "Instances", oDiceParticle);
			p.target_x = oCombat.gui_w - 150;  // discard button target
			p.target_y = oCombat.gui_h - 130;
			p.color_main = die.color;

			// Clone the die struct so the particle has its own independent copy
			p.die_struct = clone_die(die, "");
		
			var _context = {
				_ejected_die: die,
				_ejected_slot: _slot,
				_ejected_slot_pos_x: start_x,
				_ejected_slot_pos_y: start_y,
			}
		
			combat_trigger_effects("on_dice_ejected", _context);

			// Remove from slot
			ds_list_delete(_slot.dice_list, j);
		} else {
			j++;
		}
	}
	
	for (var d = 0; d < ds_list_size(_slot.dice_list); d++) {
		var die = _slot.dice_list[| d];
				
		// only add new unique types
		var parts = string_split(die.possible_type, " ");
		var total = array_length(parts);

		for (var p = 0; p < total; p++) {
			if (string_pos(string(parts[p]), _slot.possible_type) > 0) {
			} else {
				if (_slot.possible_type == "") {
					_slot.possible_type = parts[p];
					//show_debug_message(string(i)+" slot, setting possible type to "+string(parts[p]));
				} else {
					_slot.possible_type = string_concat(_slot.possible_type, " ", parts[p]);
					//show_debug_message(string(i)+" slot, adding possible types"+string(parts[p]));
				}
			}
		}	
	}
			
	if (ds_list_size(_slot.dice_list) == 0) {
		_slot.possible_type = "None";
	}
						
	// change the type if this action type isn't contained within the possible type
	if (_slot.possible_type != "") {
		//show_debug_message(string(i)+" slot possible type is not empty");
		if (!string_pos(_slot.current_action_type, _slot.possible_type)) {
			var parts = string_split(_slot.possible_type, " ");
			var total = array_length(parts);
				
			_slot.current_action_type = parts[0];
			//show_debug_message(string(i)+" slot resetting action type to "+string(parts[0]));
		}
	}
}

function add_enemy_to_fight(_enemy) {
	// Every enemy in a fight gets its own copy of its data and moves, so changes made mid-fight
	// (Shiny Scales, Stunned, used-up triggers) never reach other enemies or later fights
	_enemy = enemy_copy_for_fight(_enemy);
	enemy_apply_chapter_scaling(_enemy);
	
	var _rand_move = irandom(ds_list_size(_enemy.moves) - 1);
	
	enemy_template = {
		data: _enemy,
		intent: {
			move: _enemy.moves[| _rand_move],
			rolls: [],			// the move's dice, rolled when the intent is set (enemy_set_intent)
alpha: 0,
			start_scale: 0.75,	
			scale: 0.25,	
			text: "",
			color: c_white,
		},
		turns_since_last_block: 1,
		move_number: -1,
move_history: ds_list_create(),
		max_hp: _enemy.max_hp,
		hp: _enemy.current_hp, // debug_mode ? 1 : _enemy.current_hp,
		hp_display: _enemy.current_hp,
		block_amount: _enemy.starting_block,
		alpha: 1.0,
		dead: false,
		looted: false,
		turn_done: false,
		pos_x: global.enemy_x - (gui_w * 0.1) + (enemy_x_offset * ds_list_size(room_enemies)),
		pos_x_start: global.enemy_x - (gui_w * 0.1) + (enemy_x_offset * ds_list_size(room_enemies)),
		pos_y: global.enemy_y + (enemy_y_offset * ds_list_size(room_enemies)),
		pos_y_start: global.enemy_y + (enemy_y_offset * ds_list_size(room_enemies)),
		start_scale: 1.0 - ((enemies_left_this_combat-1) * 0.1),
		target_scale: 1.08 - ((enemies_left_this_combat-1) * 0.1),
		scale: 0.8,
		info_alpha: 1.0,
		bar_scale: 1.0 - ((enemies_left_this_combat-1) * 0.2),
		debuffs: ds_list_create(),
		taken_damage_this_turn: false,
		keep_block_between_turns: false,
		alignment_choices_shown: false, // have we shown them their alignment choices yet
		alignment_choice: "", // have they picked to either kill or spare
		alignment_option_btn_1_scale: 1,
		alignment_option_btn_2_scale: 1,
		spared: false,	// for alignment fights
		killed: false,	// for alignment fights
		
	}
	
	if (enemy_template.data.passive != undefined) {
		apply_buff(enemy_template, enemy_template.data.passive, enemy_template.data.passive.duration, enemy_template.data.passive.amount, false, { source: enemy_template, index: -1 }, true );
	}
	
	ds_list_add(room_enemies, enemy_template);
	array_push(fight_enemy_records, enemy_template); // kept for clean up, even after the enemy leaves room_enemies
}


function define_combat_ui_sizes() {
	aq_tile_w = 140; // size of an action queue tile, needed to be declared here to reposition enemies in fights. 140 is the default value

	global.enemy_x = (1600 * global.ui_scale) + (enemies_left_this_combat * (100 * global.ui_scale));
	global.enemy_y = 735 * global.ui_scale;
	global.player_x = 355 * global.ui_scale - (25 * global.ui_scale);
	global.player_xstart = global.player_x;
	global.player_y = global.enemy_y;

	enemy_x_offset = -460 + (enemies_left_this_combat*80);
	enemy_y_offset = -90;
}

// =====================================================================
// SLOT BONUSES
// A slot's flat bonuses are kept as separate entries, each tagged with where it came from, so keepsakes
// and items can't overwrite or undo each other. A bonus applies to every die in the slot ("each") unless
// its description says otherwise ("first", only the first die, like Repeater Rail).
// slot.bonus_amount is the "each" total and slot.first_die_bonus the "first" total, kept up to date by
// these functions and read by the rest of the game. Never write them directly.
// =====================================================================

/// @desc Add a bonus to a slot. Bonuses from the same source with the same lifetime stack into one.
/// @param _source  shown to the player in the slot's bonus breakdown, so use the keepsake or item name
/// @param _turns   rounds it lasts (1 = until the end of this round), or -1 for the rest of the fight
/// @param _scope   "each" (every die in the slot) or "first" (only the first die)
function slot_add_bonus(_slot, _source, _amount, _turns, _scope = "each") {
	for (var i = 0; i < array_length(_slot.bonuses); i++) {
		var _bonus = _slot.bonuses[i];
		if (_bonus.source == _source && _bonus.turns == _turns && _bonus.scope == _scope) {
			_bonus.amount += _amount;
			slot_refresh_bonus(_slot);
			return;
		}
	}
	array_push(_slot.bonuses, { source: _source, amount: _amount, turns: _turns, scope: _scope });
	slot_refresh_bonus(_slot);
}

/// @desc Set a source's bonus to exactly this amount, replacing what that source gave before.
///       For bonuses that depend on how the queue looks right now (Single Focus, Repeater Rail).
function slot_set_bonus(_slot, _source, _amount, _scope = "each") {
	slot_remove_bonus(_slot, _source);
	if (_amount != 0) array_push(_slot.bonuses, { source: _source, amount: _amount, turns: -1, scope: _scope });
	slot_refresh_bonus(_slot);
}

/// @desc Remove every bonus from this source.
function slot_remove_bonus(_slot, _source) {
	for (var i = array_length(_slot.bonuses) - 1; i >= 0; i--) {
		if (_slot.bonuses[i].source == _source) array_delete(_slot.bonuses, i, 1);
	}
	slot_refresh_bonus(_slot);
}

/// @desc End of round: count down timed bonuses and drop the ones that have run out.
function slot_tick_bonuses(_slot) {
	for (var i = array_length(_slot.bonuses) - 1; i >= 0; i--) {
		var _bonus = _slot.bonuses[i];
		if (_bonus.turns == -1) continue;
		_bonus.turns--;
		if (_bonus.turns <= 0) array_delete(_slot.bonuses, i, 1);
	}
	slot_refresh_bonus(_slot);
}

/// @desc Recalculate slot.bonus_amount (every die) and slot.first_die_bonus (first die only) from its bonuses.
function slot_refresh_bonus(_slot) {
	var _each = 0;
	var _first = 0;
	for (var i = 0; i < array_length(_slot.bonuses); i++) {
		if (_slot.bonuses[i].scope == "first") _first += _slot.bonuses[i].amount; else _each += _slot.bonuses[i].amount;
	}
	_slot.bonus_amount = _each;
	_slot.first_die_bonus = _first;
}

/// @desc The slot's bonuses as text for its hover box, one line per source.
function slot_bonus_breakdown(_slot) {
	var _text = "";
	for (var i = 0; i < array_length(_slot.bonuses); i++) {
		var _bonus = _slot.bonuses[i];
		var _sign = _bonus.amount >= 0 ? "+" : "";
		var _is_position = (string_copy(_bonus.source, 1, 5) == "Slot "); // slot_set_position_bonus: once, on the slot's total
		var _line = _bonus.source + ": " + _sign + string(_bonus.amount) + (_is_position ? " to its total" : (_bonus.scope == "first" ? " to the first die" : " to each die"));
		if (_bonus.turns > 0) _line += ", this round";
		_text += (_text == "" ? "" : "\n") + _line;
	}
	return _text;
}

/// @desc The slot's whole flat bonus for a roll of this many dice: every-die bonuses once per die, plus first-die ones once.
function slot_total_bonus(_slot, _dice_count) {
	if (_dice_count <= 0) return 0;
	return _slot.bonus_amount * _dice_count + _slot.first_die_bonus;
}

// =====================================================================
// TUTORIAL (F54 part 2)
// Until the player finishes or skips it (progress.json tutorial_done), the first fight is guided: a Pirate Ruffian
// (get_combat_enemies), a set first hand drawn from the player's own bag (deal_single_die), and logbook margin notes
// that point at one thing at a time. While a step waits for an action, only that action works (tutorial_allows,
// called where dice are dropped and where the turn is ended). A Skip button is always there.
// Runs inside oCombat: tutorial_begin (Create), tutorial_step (Step), tutorial_draw (end of Draw GUI).
// =====================================================================

/// @func tutorial_wanted()
/// @desc Should fights be guided? Until the tutorial has been finished or skipped once.
function tutorial_wanted() {
	return false; // rolled dice prototype: the guided fight teaches the old rules, so it's off until it's rewritten
	return !progress_get("tutorial_done");
}

/// @func tutorial_active()
function tutorial_active() {
	return variable_global_exists("tut") && is_struct(global.tut) && global.tut.active && room == rmCombat && instance_exists(oCombat);
}

/// @func tutorial_steps()
/// @desc The guided steps, over two turns. target: what the note points at. allow: the actions that work while it's
///       up ("all" for anything). die_types / slot: which dice and which slot ("newest" = the last slot). done: when it
///       moves on (steps with a button wait for it instead).
function tutorial_steps() {
	return [
		// turn 1: a slot, stacking, a slot from a sacrifice, generic dice, how long dice stay
		{
			id: "intent", target: "intent", allow: [], button: "Next",
			text: "Read your enemy first. Its intent shows what it will do this turn, and a range of how much. Insight dice give you ink for next turn: at the start of a turn your quill can spend 2 of it to show the exact number.",
		},
		{
			id: "claim", target: "slot0", allow: ["place"], die_types: ["ATK"], slot: 0,
			text: "Lay an Attack die in the empty slot. A slot takes the type of the first die laid in it.",
			done: function() { return oCombat.action_queue[| 0].current_action_type == "ATK"; },
		},
		{
			id: "stack", target: "slot0", allow: ["place"], die_types: ["ATK"], slot: 0,
			text: "Lay your other Attack die in the same slot. Dice in one slot roll together.",
			done: function() { return ds_list_size(oCombat.action_queue[| 0].dice_list) >= 2; },
		},
		{
			id: "sacrifice", target: "sacrifice", allow: ["sacrifice"], die_types: ["INTEL"],
			text: "Sacrificing a die builds a new slot, and the die stays in it. Sacrifice your Insight die here. Insight it rolls counts next turn.",
			done: function() { return ds_list_size(oCombat.action_queue) >= 2; },
		},
		{
			id: "generic", target: "slot0", allow: ["place"], die_types: ["None"], slot: 0,
			text: "Generic dice power up any slot. Lay the Generic die in your Attack slot.",
			done: function() {
				var _dice = oCombat.action_queue[| 0].dice_list;
				for (var i = 0; i < ds_list_size(_dice); i++) if (_dice[| i].action_type == "None") return true;
				return false;
			},
		},
		{
			id: "lasting", target: "slot0", allow: [], button: "Next",
			text: "Action dice stay in their slot for 2 turns, Generic dice for only 1. A bold outline means a die will still be here next turn.",
		},
		{
			id: "end_turn", target: "end_turn", allow: ["end_turn"],
			text: "You can play 4 dice a turn. When you end your turn your slots fire left to right, then the enemy acts. End your turn.",
			done: function() { return oCombat.turn_count >= 2; },
		},
		// turn 2: insight, a slot with two actions, right-click to switch
		{
			id: "insight", target: "insight", allow: [], button: "Next",
			text: "Your insight came in as ink, and the log is open. With the quill: reroll or redraw a die (3), see the enemy's exact numbers (2), or make it choose again (6). Seal the log to play your dice.",
		},
		{
			id: "two_types", target: "sacrifice", allow: ["sacrifice"], die_types: ["ATK", "BLK"],
			text: "Your next slot costs 2 sacrifices. Build it from an Attack die and a Block die, and it can do either.",
			done: function() { return ds_list_size(oCombat.action_queue) >= 3; },
		},
		{
			id: "switch", target: "newest", allow: [],
			text: "Right-click a slot with more than one action to switch between them. Switch your new slot now.",
			done: function() { return global.tut.switched; },
		},
		{
			id: "free", target: "", allow: "all", button: "Set sail",
			text: "The rest is yours, Captain. Dice left in your hand at the end of a turn are discarded, so use them well.",
		},
	];
}

/// @func tutorial_begin()
/// @desc oCombat Create: start the guided fight if the tutorial is still wanted.
function tutorial_begin() {
	global.tut = { active: false };
	if (!tutorial_wanted()) return;
	global.tut = {
		active: true,
		step: 0,
		steps: tutorial_steps(),
		hand: ["ATK", "ATK", "INTEL", "None", "BLK", "BLK"],	// turn 1's hand, drawn from the bag in this order
		hand2: ["ATK", "BLK"],									// turn 2 starts with these (the two-action slot), the rest are drawn as usual
		switched: false,										// set when a slot's action is switched by right-click
		note_alpha: 0,
	};
}

/// @func tutorial_finish()
/// @desc Finished or skipped: never guided again (unless Settings turns it back on).
function tutorial_finish() {
	if (variable_global_exists("tut") && is_struct(global.tut)) global.tut.active = false;
	if (!progress_get("tutorial_done")) progress_set("tutorial_done", true);
}

/// @func tutorial_skip()
/// @desc The Skip button: the tutorial is done, and the one-time tips are marked seen too (the player knows the game).
function tutorial_skip() {
	tutorial_finish();
	var _tips = tips_list();
	for (var i = 0; i < array_length(_tips); i++) {
		if (!array_contains(global.progress.tips_seen, _tips[i].id)) array_push(global.progress.tips_seen, _tips[i].id);
	}
	progress_save();
}

/// @func tutorial_current()
function tutorial_current() {
	if (!tutorial_active()) return undefined;
	if (global.tut.step >= array_length(global.tut.steps)) return undefined;
	return global.tut.steps[global.tut.step];
}

/// @func tutorial_next_hand_type()
/// @desc deal_single_die: the action type the guided first hand wants next, or "" for a normal draw.
function tutorial_next_hand_type() {
	if (!tutorial_active()) return "";
	var _hand = (oCombat.turn_count == 1) ? global.tut.hand : ((oCombat.turn_count == 2) ? global.tut.hand2 : []);
	if (array_length(_hand) == 0) return "";
	var _type = _hand[0];
	array_delete(_hand, 0, 1); // arrays are shared by reference, so this takes it off global.tut's list
	return _type;
}

/// @func tutorial_allows(_action, _die_struct, _slot_i)
/// @desc Can the player do this right now? Always true outside the guided steps. _action: "place", "sacrifice",
///       "discard" or "end_turn". When it says no, the player is told what the logbook is waiting for.
function tutorial_allows(_action, _die_struct = undefined, _slot_i = -1) {
	var _s = tutorial_current();
	if (_s == undefined || _s.allow == "all") return true;

	var _ok = array_contains(_s.allow, _action);
	if (_ok && variable_struct_exists(_s, "die_types") && _die_struct != undefined && !array_contains(_s.die_types, _die_struct.action_type)) _ok = false;
	if (_ok && _action == "place") {
		if (variable_struct_exists(_s, "slot")) {
			var _want = (_s.slot == "newest") ? ds_list_size(oCombat.action_queue) - 1 : _s.slot;
			if (_slot_i != _want) _ok = false;
		}
	}
	if (!_ok) throw_error("Not yet", "Follow the logbook: " + _s.text);
	return _ok;
}

/// @func tutorial_step()
/// @desc oCombat Step: move on when the current step's action is done; end with the fight.
function tutorial_step() {
	if (!tutorial_active()) return;

	// the fight ended (won, lost, or left): the tutorial counts as done
	if (oCombat.state == CombatState.PLAYER_DEAD || oCombat.show_rewards) { tutorial_finish(); return; }

	var _s = tutorial_current();
	if (_s == undefined) { tutorial_finish(); return; }
	if (variable_struct_exists(_s, "done") && _s.done()) {
		global.tut.step++;
		global.tut.note_alpha = 0;
	}
}

/// @func tutorial_target_rect(_target)
/// @desc Where a step points, in GUI pixels { x, y, w, h }, or undefined for nothing.
function tutorial_target_rect(_target) {
	with (oCombat) {
		switch (_target) {
			case "intent":
				if (ds_list_size(room_enemies) == 0) return undefined;
				var _e = room_enemies[| 0];
				var _iy = _e.pos_y - 10 - (_e.scale * 180);
				return { x: _e.pos_x - 90, y: _iy - 35, w: 180, h: 70 };
			case "slot0":
				if (ds_list_size(slot_positions) == 0) return undefined;
				return slot_positions[| 0];
			case "newest":
				if (ds_list_size(slot_positions) == 0) return undefined;
				return slot_positions[| ds_list_size(slot_positions) - 1];
			case "sacrifice":
				return variable_instance_exists(id, "tut_last_tile") ? tut_last_tile : undefined;
			case "end_turn":
				return variable_instance_exists(id, "tut_end_turn") ? tut_end_turn : undefined;
			case "insight":
				return { x: global.player_x - 60, y: global.player_y - 245, w: 120, h: 120 };
		}
	}
	return undefined;
}

/// @func tutorial_draw()
/// @desc End of oCombat Draw GUI: the highlight, the margin note with its arrow, Next and Skip. Input is handled here,
///       like the rest of the combat UI.
function tutorial_draw() {
	if (!tutorial_active()) return;
	var _s = tutorial_current();
	if (_s == undefined) return;
	if (oCombat.state != CombatState.PLAYER_INPUT || oCombat.show_rewards) return; // nothing to read while dice resolve

	// Skip, top right under the bar
	var _skip = draw_gui_button(display_get_gui_width() - 230, 90, 200, 50, 1, "Skip tutorial", global.ui_quiet, ftDefault, true, true, UI_LAYER.BASE);
	if (_skip.click) { tutorial_skip(); return; }

	if (tutorial_draw_note(_s.text, tutorial_target_rect(_s.target), variable_struct_exists(_s, "button") ? _s.button : "")) {
		global.tut.step++;
		global.tut.note_alpha = 0;
		if (global.tut.step >= array_length(global.tut.steps)) tutorial_finish();
	}
}

/// @func tutorial_draw_note(_text, _rect, _button)
/// @desc A logbook margin note: parchment with an ink edge, an arrow and a pulsing outline on _rect (or none if
///       undefined), and a button if _button isn't "". Returns true when the button is clicked. Used by the guided
///       fight and the map notes.
function tutorial_draw_note(_text, _r, _button) {
	if (!variable_global_exists("tut_note")) global.tut_note = { pulse: 0, alpha: 0, text: "" };
	var _n = global.tut_note;
	if (_n.text != _text) { _n.text = _text; _n.alpha = 0; } // a new note fades in
	_n.pulse += 0.08;
	_n.alpha = lerp(_n.alpha, 1, 0.15);
	var _a = _n.alpha;
	var _clicked = false;

	var _gw = display_get_gui_width(), _gh = display_get_gui_height();
	var _ink = make_color_rgb(40, 32, 24);
	var _paper = make_color_rgb(240, 228, 196);

	// the note's text and size
	draw_set_font(ftDefault);
	var _note_w = 460;
	var _pad = 18;
	var _text_h = string_height_ext(_text, 26, _note_w - _pad * 2);
	var _btn_h = (_button != "") ? 50 : 0;
	var _note_h = _text_h + _pad * 2 + _btn_h;

	// where it points, and where the note sits: above a target in the lower half, below one in the upper half
	var _nx = _gw / 2 - _note_w / 2, _ny = 100; // with nothing to point at, the note sits at the top, clear of popups
	var _tx = 0, _ty = 0;
	if (_r != undefined) {
		_tx = _r.x + _r.w / 2;
		_ty = _r.y + _r.h / 2;
		_nx = clamp(_tx - _note_w / 2, 20, _gw - _note_w - 20);
		_ny = (_ty > _gh / 2) ? _r.y - _note_h - 70 : _r.y + _r.h + 70;
		_ny = clamp(_ny, 150, _gh - _note_h - 20);

		// pulsing highlight round the target
		var _grow = 8 + 4 * sin(_n.pulse);
		draw_set_alpha(_a * (0.55 + 0.35 * sin(_n.pulse)));
		draw_set_color(global.color_intel);
		for (var _w = 0; _w < 3; _w++) draw_roundrect(_r.x - _grow - _w, _r.y - _grow - _w, _r.x + _r.w + _grow + _w, _r.y + _r.h + _grow + _w, true);

		// arrow from the note's edge to the target's edge
		var _ax = clamp(_tx, _nx + 30, _nx + _note_w - 30);
		var _ay = (_ny < _ty) ? _ny + _note_h : _ny;
		var _bx = _tx;
		var _by = (_ny < _ty) ? _r.y - _grow - 6 : _r.y + _r.h + _grow + 6;
		var _dir = point_direction(_ax, _ay, _bx, _by);
		draw_set_alpha(_a);
		draw_set_color(_ink);
		draw_line_width(_ax, _ay, _bx, _by, 5);
		draw_triangle(_bx, _by, _bx + lengthdir_x(20, _dir + 150), _by + lengthdir_y(20, _dir + 150), _bx + lengthdir_x(20, _dir - 150), _by + lengthdir_y(20, _dir - 150), false);
		draw_set_color(_paper);
		draw_line_width(_ax, _ay, _bx, _by, 2);
	}

	// the margin note: parchment with an ink edge
	draw_set_alpha(_a);
	draw_set_color(_ink);
	draw_roundrect_ext(_nx - 3, _ny - 3, _nx + _note_w + 3, _ny + _note_h + 3, 14, 14, false);
	draw_set_color(_paper);
	draw_roundrect_ext(_nx, _ny, _nx + _note_w, _ny + _note_h, 12, 12, false);
	draw_set_color(_ink);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_text_ext(_nx + _pad, _ny + _pad, _text, 26, _note_w - _pad * 2);

	// a note that waits for the player to read it has a button
	if (_btn_h > 0) {
		var _b = draw_gui_button(_nx + _note_w - 160 - _pad, _ny + _note_h - _btn_h - 8, 160, 42, 1, _button, global.ui_primary, ftDefault, true, true, (instance_exists(oCombat) && oCombat.insight_view) ? UI_LAYER.POPUP : UI_LAYER.BASE); // clickable in the insight phase too
		if (_b.click) _clicked = true;
	}

	draw_set_alpha(1);
	draw_set_color(c_white);
	return _clicked;
}

/// @func tutorial_map_notes()
/// @desc The map's notes for a first voyage, in order. Each is a one-time tip (progress.json tips_seen): shown while
///       its when() is true, marked seen once its done() is.
function tutorial_map_notes() {
	return [
		{
			id: "map_offering", target: "",
			text: "Every voyage begins with a gift from the quartermaster: a die with a core already fitted. A core changes which faces a die rolls most often. Cores you find later can be drilled into dice at the workbench.",
			when: function() { return oRunManager.new_run_offering; },
			done: function() { return !oRunManager.new_run_offering; },
		},
		{
			id: "map_draft", target: "pages",
			text: "This is the captain's logbook. Each page is a stretch of sea with stops on it: fights, shops, events. Choose 2 pages for this spread. Your first choice locks one of the others away, so choose with care.",
			when: function() { return oWorldManager.world_state == WORLD_STATE.DRAFTING && oWorldManager.pages_drafted < 2 && oWorldManager.pages_alpha > 0.5; },
			done: function() { return oWorldManager.pages_drafted >= 2; },
		},
		{
			id: "map_embark", target: "embark",
			text: "Embark to set sail on the pages you chose.",
			when: function() { return oWorldManager.world_state == WORLD_STATE.DRAFTING && oWorldManager.pages_drafted >= 2 && !oWorldManager.choices_locked; },
			done: function() { return oWorldManager.choices_locked; },
		},
		{
			id: "map_sail", target: "first_stop",
			text: "Click your first stop to sail there. Your first fight will walk you through the dice.",
			when: function() { return oWorldManager.world_state == WORLD_STATE.EXPLORING; },
			done: function() { return oWorldManager.node_to_move_to != undefined; },
		},
	];
}

/// @func tips_draw()
/// @desc oRunManager Draw GUI End, every room: the first note still to show, on top of everything. The map notes come
///       first (only while the tutorial is wanted), then the one-time tips (tips_list). One note at a time, never
///       during the guided fight, a cutscene, Settings, the bag view or a popup.
function tips_draw() {
	if (tutorial_active() || global.all_input_disabled || global.show_settings) return;
	if (instance_exists(oRunManager) && (oRunManager.show_bag_contents || oRunManager.paused || oRunManager.run_over != undefined)) return;

	// the map notes of a first voyage
	if (room == rmMap && instance_exists(oWorldManager) && tutorial_wanted()) {
		if (!variable_global_exists("tut_map_notes")) global.tut_map_notes = tutorial_map_notes();
		for (var i = 0; i < array_length(global.tut_map_notes); i++) {
			var _m = global.tut_map_notes[i];
			if (tip_seen(_m.id)) continue;
			if (_m.done()) { tip_mark_seen(_m.id); continue; }
			if (!_m.when()) continue;
			tutorial_draw_note(_m.text, tutorial_map_rect(_m.target), "");
			return;
		}
	}
	if (instance_exists(oRunManager) && oRunManager.new_run_offering) return; // the offering is a popup

	// one-time tips, the first time something comes up
	if (!variable_global_exists("tips")) global.tips = tips_list();
	for (var i = 0; i < array_length(global.tips); i++) {
		var _t = global.tips[i];
		if (_t.room != room || tip_seen(_t.id)) continue;
		if (variable_struct_exists(_t, "done") && _t.done()) { tip_mark_seen(_t.id); continue; }
		if (variable_struct_exists(_t, "when") && !_t.when()) continue;
		if (tutorial_draw_note(_t.text, tips_rect(_t.target), "Got it")) tip_mark_seen(_t.id);
		return;
	}
}

/// @func tips_combat_ready()
/// @desc A combat tip only shows while the player is planning (not while dice resolve or on the rewards screen).
function tips_combat_ready() {
	return instance_exists(oCombat) && oCombat.state == CombatState.PLAYER_INPUT && !oCombat.show_rewards && oCombat.dice_to_deal <= 0;
}

/// @func tips_list()
/// @desc The one-time tips (F54 part 3), shown once each (progress.json tips_seen) with a "Got it" button. room: where
///       it shows. when(): optional, it waits until true. done(): optional, counts as seen without being read
///       (the moment passed). target: what it points at (tips_rect).
function tips_list() {
	return [
		{
			id: "workbench_map", room: rmMap, target: "at_sea",
			text: "At sea. When you finish a page's island, you can stop at the workbench before the next one: choose dice from your bag and reshape them with your tools.",
			when: function() { return instance_exists(oWorldManager) && oWorldManager.world_state == WORLD_STATE.EXPLORING && oRunManager.can_visit_workbench; },
		},
		{
			id: "workbench_bag", room: rmWorkbench, target: "wb_pick",
			text: "The workbench. First choose what to work on: open your bag and take up to one die per tool you own.",
			when: function() { return instance_exists(oWorkbenchManager) && oWorkbenchManager.pick_pending; },
			done: function() { return instance_exists(oWorkbenchManager) && !oWorkbenchManager.pick_pending && oRunManager.dice_selection == false; },
		},
		{
			id: "workbench", room: rmWorkbench, target: "wb_slots",
			text: "Put a die in the first slot and drag a core from the top bar into the middle one. Each tool works once per visit; click a finished die to send it to your bag.",
			when: function() { return instance_exists(oWorkbenchManager) && !oWorkbenchManager.pick_pending && oRunManager.dice_selection == false; },
			done: function() { return instance_exists(oWorkbenchManager) && oWorkbenchManager.workbench_slot[0].dice != undefined && oWorkbenchManager.workbench_slot[1].core != undefined; },
		},
		{
			id: "workbench_toolbag", room: rmWorkbench, target: "toolbag",
			text: "Now click the Drill in your toolbag to lay it on the bench.",
			when: function() { return instance_exists(oWorkbenchManager) && oWorkbenchManager.workbench_slot[0].dice != undefined && oWorkbenchManager.workbench_slot[1].core != undefined && !instance_exists(oDrill); },
			done: function() { return instance_exists(oDrill); },
		},
		{
			id: "workbench_drill", room: rmWorkbench, target: "drill",
			text: "Click the Drill to pick it up, then hold left click over the Drill button until it bites. Right click puts the tool down.",
			when: function() { return instance_exists(oDrill) && !oDrill.is_dragging; },
			done: function() { return instance_exists(oWorkbenchManager) && oWorkbenchManager.crafting_state != "waiting"; },
		},
		{
			id: "spread_done", room: rmMap, target: "",
			text: "A spread is done. Choose one: Heal is always offered, beside two others that change each time (a core, removing or sharpening a die, gold). Or just continue. Then you choose the next two pages.",
			when: function() { return instance_exists(oWorldManager) && oWorldManager.world_state == WORLD_STATE.TURNING; },
		},
		{
			// the guided fight is off on this branch, so this teaches insight the first time you have some to spend
			id: "insight_spend", room: rmCombat, target: "insight",
			text: "The log is open. Your insight is ink: with the quill, reroll or redraw a die in your hand (" + string(INSIGHT_COST_REROLL) + " each), see an enemy's exact numbers (" + string(INSIGHT_COST_REVEAL) + ", or 1 each when there are several), or make it choose its move again (" + string(INSIGHT_COST_QUILL) + "). Seal the log (where End Turn is) to play. Ink you don't spend carries over.",
			when: function() { return instance_exists(oCombat) && oCombat.insight_view; },
		},
		{
			id: "blotted", room: rmCombat, target: "insight",
			text: "Blotted: your insight fell below 0, so enemy intents are hidden this turn.",
			when: function() { return tips_combat_ready() && intel_is_blotted(); },
		},
		{
			// rolled dice prototype: the guided fight is off, so this explains the new rules once
			id: "rolled_dice", room: rmCombat, target: "",
			text: "Your dice show what they rolled. Drag them into your slots, left to right: the first coloured die picks a slot's type. Click a die in a slot to take it back. End Turn discards everything.",
			when: function() { return tips_combat_ready() && oCombat.turn_count == 1; },
		},
		{
			// the second half: once every slot has something in it, building the next one
			id: "new_slot", room: rmCombat, target: "",
			text: "Every slot has an action, so you can build another: drop dice on the new-slot tile until they add up to its number. Later slots add more to their total.",
			when: function() { return tips_combat_ready() && tip_seen("rolled_dice") && combat_all_slots_have_action() && oCombat.state == CombatState.PLAYER_INPUT; },
		},
		{
			id: "multi_enemy", room: rmCombat, target: "target_enemy",
			text: "More than one enemy. Your attacks all go to your target, marked under its health bar. Click another enemy to change target any time before you end your turn.",
			when: function() { return tips_combat_ready() && !tutorial_active() && combat_living_enemies() >= 2; },
		},
		{
			id: "alignment_fight", room: rmCombat, target: "",
			text: "A crossroads fight. When the enemy falls you choose: Kill it or Spare it. Killing swings your compass (top bar) toward ruthless; sparing swings it toward merciful and pays more gold. Some events and keepsakes care where your compass points. The rewards here are alignment dice.",
			when: function() { return tips_combat_ready() && oWorldManager.current_node_type == NODE_TYPE.ALIGNMENT; },
		},
		{
			id: "kill_or_spare", room: rmCombat, target: "spare_buttons",
			text: "Kill or spare? Kill: compass toward ruthless, its bounty in gold. Spare: compass toward merciful, one and a half times the gold, and it sails away. Hover each button for more.",
			when: function() { return combat_spare_choice_enemy() != undefined; },
		},
		{
			id: "shop", room: rmShop, target: "",
			text: "A shop. Spend your gold on dice, keepsakes, items and tools. Keepsakes last the whole voyage.",
		},
		{
			id: "event", room: rmEvent, target: "",
			text: "Something happens on your voyage. Hover an option to see what it does, then choose one.",
		},
		{
			id: "bounty", room: rmBounty, target: "",
			text: "The bounty board. Take a contract to hunt a tougher enemy under a condition. Beat it while keeping to the condition to claim the rewards.",
		},
		{
			id: "treasure", room: rmTreasure, target: "",
			text: "Treasure! Open the chest for a keepsake: a lasting effect for the rest of the voyage.",
		},
	];
}

/// @func tips_rect(_target)
/// @desc Where a tip points, in GUI pixels, or undefined (the note sits at the top).
function tips_rect(_target) {
	switch (_target) {
		case "at_sea":
			var _gw = display_get_gui_width(), _gh = display_get_gui_height();
			return { x: _gw / 2 - 320, y: _gh - 230 - 90, w: 640, h: 230 }; // the map's "At sea" panel
		case "insight":
			return { x: global.player_x - 60, y: global.player_y - 245, w: 120, h: 120 };
		case "wb_pick":
			if (!instance_exists(oWorkbenchManager)) return undefined;
			with (oWorkbenchManager) return { x: display_get_gui_width() / 2 - 280, y: start_y - wb_tile_size - 230, w: 560, h: 170 };
			break;
		case "wb_slots":
			if (!instance_exists(oWorkbenchManager)) return undefined;
			with (oWorkbenchManager) return { x: start_x - wb_tile_size / 2, y: start_y - wb_tile_size / 2, w: wb_tile_size * 2 + wb_tile_padding, h: wb_tile_size };
			break;
		case "toolbag":
			// oRunManager Draw GUI draws the toolbag at gui width - 940, in the top bar
			return { x: display_get_gui_width() - 940 - 50, y: 10, w: 100, h: 100 };
		case "target_enemy":
			if (!instance_exists(oCombat) || oCombat.enemy_target_index < 0 || oCombat.enemy_target_index >= ds_list_size(oCombat.room_enemies)) return undefined;
			var _te = oCombat.room_enemies[| oCombat.enemy_target_index];
			return { x: _te.pos_x - 110, y: _te.pos_y - 120, w: 220, h: 260 };
		case "spare_buttons":
			var _se = combat_spare_choice_enemy();
			if (_se == undefined) return undefined;
			return { x: _se.pos_x - 110, y: _se.pos_y + 20, w: 220, h: 60 };
		case "drill":
			if (!instance_exists(oDrill)) return undefined;
			return { x: oDrill.x - 80, y: oDrill.y - 80, w: 160, h: 160 };
	}
	return undefined;
}

/// @func tutorial_map_rect(_target)
/// @desc Where a map note points, in GUI pixels, or undefined.
function tutorial_map_rect(_target) {
	with (oWorldManager) {
		switch (_target) {
			case "pages":
				var _n = ds_list_size(pages_shown);
				if (_n == 0) return undefined;
				var _pw = sprite_get_width(sMapParchment), _ph = sprite_get_height(sMapParchment);
				var _x1 = 99999, _x2 = -99999, _y1 = 99999, _y2 = -99999;
				for (var p = 0; p < _n; p++) {
					_x1 = min(_x1, page_pos[p].x - _pw / 2); _x2 = max(_x2, page_pos[p].x + _pw / 2);
					_y1 = min(_y1, page_pos[p].y - _ph / 2); _y2 = max(_y2, page_pos[p].y + _ph / 2);
				}
				return { x: _x1, y: _y1, w: _x2 - _x1, h: _y2 - _y1 };
			case "embark":
				var _ew = 240, _eh = 84; // the Embark kit button (oWorldManager Draw GUI)
				return { x: display_get_gui_width() * 3/4 - _ew / 2, y: display_get_gui_height() - 100 - _eh / 2, w: _ew, h: _eh };
			case "first_stop":
				// the first stop not yet cleared, in the order the pages were chosen
				for (var p = 0; p < ds_list_size(chosen_pages); p++) {
					var _nodes = chosen_pages[| p].nodes;
					for (var n = 0; n < ds_list_size(_nodes); n++) {
						var _node = _nodes[| n];
						if (_node.cleared || !variable_struct_exists(_node, "x")) continue; // not drawn yet: no position
						var _iw = sprite_get_width(sMapIcon) * _node.scale, _ih = sprite_get_height(sMapIcon) * _node.scale;
						return { x: _node.x - _iw / 2, y: _node.y - _ih / 2, w: _iw, h: _ih };
					}
				}
				return undefined;
			case "boat":
				var _bw = sprite_get_width(sMapShip), _bh = sprite_get_height(sMapShip);
				return { x: boat_data.x - _bw / 2, y: boat_data.y - _bh, w: _bw, h: _bh };
		}
	}
	return undefined;
}

/// @func insight_panel_draw()
/// @desc oRunManager Draw GUI End: while the insight eye is hovered, what your insight buys this turn and what each
///       costs (lit when you can afford it). Drawn after the tutorial notes and tips so it sits on top of them.
function insight_panel_draw() {
	if (!instance_exists(oCombat) || !oCombat.insight_panel_open) return;
	with (oCombat) {
		var _rows = [
			{ what: "See exact enemy intents", how: insight_revealed ? "Bought this turn" : "Click the eye", cost: INSIGHT_COST_REVEAL, done: insight_revealed },
			{ what: "One more reroll", how: "The + token above End Turn", cost: INSIGHT_COST_REROLL, done: false },
			{ what: "One more redraw", how: "The + token above End Turn", cost: INSIGHT_COST_REDRAW, done: false },
			{ what: "One more play", how: "The + token above End Turn", cost: INSIGHT_COST_PLAY, done: false },
			{ what: "Quill: reroll or halve an intent", how: "Click an enemy's intent", cost: INSIGHT_COST_QUILL, done: false },
		];
		var _pad = 16, _w = 440, _row_h = 42, _title_h = 64;
		var _h = _pad + _title_h + _row_h * array_length(_rows) + _pad;
		var _x = global.player_x - _w / 2;
		var _y = global.player_y - 250 - _h;

		draw_set_color(c_black);
		draw_set_alpha(0.8);
		draw_roundrect(_x - 1, _y - 1, _x + _w + 1, _y + _h + 1, false);
		draw_set_color(global.color_bg);
		draw_roundrect(_x, _y, _x + _w, _y + _h, false);
		draw_set_alpha(1);

		// title: your insight, and what it is
		draw_set_font(ftDefault);
		draw_set_valign(fa_middle);
		draw_set_halign(fa_left);
		draw_set_color(c_white);
		draw_text(_x + _pad, _y + _pad + 10, "Insight");
		draw_set_halign(fa_right);
		draw_set_color(player_intel < 0 ? c_red : global.color_intel);
		draw_text(_x + _w - _pad, _y + _pad + 10, string(player_intel));
		draw_set_font(ftDescriptions);
		draw_set_halign(fa_left);
		draw_set_color(make_color_rgb(200, 200, 210));
		draw_text(_x + _pad, _y + _pad + 38, intel_is_blotted() ? "Below 0 the page is smudged: enemy intents are hidden." : "Spend it this turn: it's gone at End Turn.");

		var _ry = _y + _pad + _title_h;
		for (var i = 0; i < array_length(_rows); i++) {
			var _row = _rows[i];
			var _ok = !_row.done && combat_insight_can(_row.cost);
			var _mid = _ry + _row_h / 2;
			// the cost, as a yellow coin
			draw_set_color(c_black);
			draw_circle(_x + _pad + 14, _mid, 15, false);
			draw_set_color(_ok ? global.color_intel : make_color_rgb(110, 100, 70));
			draw_circle(_x + _pad + 14, _mid, 13, false);
			draw_set_font(ftDefault);
			draw_set_halign(fa_center);
			draw_set_color(c_black);
			draw_text(_x + _pad + 14, _mid, string(_row.cost));
			// what, and how
			draw_set_halign(fa_left);
			draw_set_color(_row.done ? make_color_rgb(140, 200, 140) : (_ok ? c_white : make_color_rgb(150, 150, 160)));
			draw_text(_x + _pad + 40, _mid - 9, _row.what);
			draw_set_font(ftDescriptions);
			draw_set_color(make_color_rgb(170, 170, 180));
			draw_text(_x + _pad + 40, _mid + 11, _row.how);
			_ry += _row_h;
		}
		draw_set_alpha(1);
		draw_set_color(c_white);
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
	}
}

/// @func weighted_to_face(_distribution, _weighted, _min_roll)
/// @desc Which face a weighted roll lands on (the same walk process_action does), for showing both rolls of a roll-twice.
function weighted_to_face(_distribution, _weighted, _min_roll) {
	for (var d = 0; d < array_length(_distribution); d++) {
		_weighted -= _distribution[d];
		if (_weighted <= 0) return d + _min_roll;
	}
	return _min_roll + array_length(_distribution) - 1;
}

/// @func roll_popup(_slot_number, _dice_index, _text, _color)
/// @desc A short word over a rolling die when an effect changes its result ("Warrior!", "Rolled 2 and 5, kept 5").
function roll_popup(_slot_number, _dice_index, _text, _color) {
	if (!instance_exists(oCombat)) return;
	if (!is_real(_dice_index)) _dice_index = 0;
	if (!is_real(_slot_number)) _slot_number = -1;
	var _x = global.player_x, _y = global.player_y - 200;
	with (oCombat) {
		if (_slot_number != undefined && _slot_number >= 0 && ds_safe_exists(slot_positions, ds_type_list) && _slot_number < ds_list_size(slot_positions)) {
			_x = slot_positions[| _slot_number].x + global.gui.action_tile_w / 2;
			_y = slot_positions[| _slot_number].y - 60 - _dice_index * 26;
		}
	}
	var _inst = instance_create_layer(_x, _y, "Instances", oDamageText);
	_inst.txt = _text;
	_inst.amount = 0;
	_inst.color_main = _color;
	_inst.num_sign = 0;
	_inst.size = 0.6;
	return _inst;
}

/// @func combat_carrying_slot_item()
/// @desc Is the player carrying a potion that is used by dropping it on a slot?
function combat_carrying_slot_item() {
	if (!instance_exists(oRunManager)) return false;
	for (var c = 0; c < array_length(oRunManager.items); c++) {
		var _item = oRunManager.items[c];
		if (_item != undefined && _item.type == "consumable" && _item.dragging && is_struct(_item.effects) && variable_struct_exists(_item.effects, "trigger") && _item.effects.trigger == "on_item_played_to_slot") return true;
	}
	return false;
}

/// @func combat_slot_under_mouse()
/// @desc The index of the action slot under the mouse (as last drawn), or -1.
function combat_slot_under_mouse() {
	if (!instance_exists(oCombat) || !ds_safe_exists(oCombat.slot_positions, ds_type_list)) return -1;
	var _mx = device_mouse_x_to_gui(0), _my = device_mouse_y_to_gui(0);
	for (var i = 0; i < min(ds_list_size(oCombat.slot_positions), ds_list_size(oCombat.action_queue)); i++) {
		var _p = oCombat.slot_positions[| i];
		if (point_in_rectangle(_mx, _my, _p.x, _p.y, _p.x + _p.w, _p.y + _p.h)) return i;
	}
	return -1;
}

/// @func combat_item_drop(_item)
/// @desc A potion let go of in a fight: if it is used on a slot and the mouse is over one, use it there. Returns true when
///       used (the caller clears its top-bar slot). Called from oRunManager on release, so draw order doesn't matter.
function combat_item_drop(_item) {
	if (room != rmCombat || !instance_exists(oCombat) || oCombat.show_rewards) return false;
	if (!is_struct(_item.effects) || !variable_struct_exists(_item.effects, "trigger") || _item.effects.trigger != "on_item_played_to_slot") return false;
	var _i = combat_slot_under_mouse();
	if (_i == -1) return false;
	var _context = { _slot: oCombat.action_queue[| _i], _ind: _i };
	if (!_item.effects.flags(_context)) return false;
	trigger_item_effects(_item, "on_item_played_to_slot", _context);
	particle_emit(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "burst", global.color_intel);
	return true;
}

/// @func enemy_layout_update()
/// @desc Where each enemy stands, worked out every step from how many are in the fight now: the group is centred,
///       spread evenly (the first in the list on the right), nudged right as the action queue grows but kept on
///       screen, and staggered back so the left ones stand a little higher. Enemies glide there; sizes follow the
///       count, so the last enemy standing is full size and centred. New enemies snap into place on their first step.
function enemy_layout_update() {
	var _n = ds_list_size(room_enemies);
	if (_n == 0) return;
	var _ui = global.ui_scale;
	var _gw = display_get_gui_width();

	var _centre = 1480 * _ui;
	var _spacing = ((_n == 2) ? 300 : 240) * _ui;
	var _push = max(0, ds_list_size(action_queue) - 1) * aq_tile_w * _ui * 0.25;
	var _left = _centre - _spacing * (_n - 1) / 2 + _push;
	var _right = _centre + _spacing * (_n - 1) / 2 + _push;
	var _limit = _gw - 170 * _ui;
	if (_right > _limit) { _right = _limit; _left = min(_left, _right); } // squeeze rather than run off screen

	for (var e = 0; e < _n; e++) {
		var _enemy = room_enemies[| e];
		var _x = (_n == 1) ? _right : lerp(_right, _left, e / (_n - 1));
		var _y = global.enemy_y - 45 * _ui * e;
		_enemy.pos_x_start = _x;
		_enemy.pos_y_start = _y;
		_enemy.start_scale = 1.0 - ((_n - 1) * 0.1);
		_enemy.bar_scale = lerp(_enemy.bar_scale, 1.0 - ((_n - 1) * 0.2), 0.15);

		if (!variable_struct_exists(_enemy, "layout_placed")) {
			_enemy.layout_placed = true;
			_enemy.pos_x = _x;
			_enemy.pos_y = _y;
		} else {
			_enemy.pos_x = lerp(_enemy.pos_x, _x, 0.12);
			_enemy.pos_y = lerp(_enemy.pos_y, _y, 0.12);
		}
	}
}

/// @func combat_living_enemies()
function combat_living_enemies() {
	if (!instance_exists(oCombat)) return 0;
	var _n = 0;
	for (var e = 0; e < ds_list_size(oCombat.room_enemies); e++) if (!oCombat.room_enemies[| e].dead) _n++;
	return _n;
}

/// @func combat_spare_choice_enemy()
/// @desc The enemy showing the Kill / Spare buttons right now, or undefined.
function combat_spare_choice_enemy() {
	if (!instance_exists(oCombat)) return undefined;
	for (var e = 0; e < ds_list_size(oCombat.room_enemies); e++) {
		var _en = oCombat.room_enemies[| e];
		if (variable_struct_exists(_en, "alignment_choices_shown") && _en.alignment_choices_shown) return _en;
	}
	return undefined;
}

/// @func workbench_useful()
/// @desc Is there anything to do at the workbench? The Hammer and Cutters always have work; the Drill only with a core
///       to drill in. With nothing to do, the map doesn't offer the stop.
function workbench_useful() {
	var _drill = false;
	for (var i = 0; i < ds_list_size(oRunManager.tools); i++) {
		var _tool = oRunManager.tools[| i].object;
		if (_tool == oHammer || _tool == oScissors) return true;
		if (_tool == oDrill) _drill = true;
	}
	if (!_drill) return false;
	for (var i = 0; i < array_length(oRunManager.items); i++) {
		var _it = oRunManager.items[i];
		if (is_struct(_it) && variable_struct_exists(_it, "type") && _it.type == "core") return true;
	}
	return false;
}

/// @func workbench_dice_allowance()
/// @desc How many dice you may bring to the workbench (F02): one per tool you own, plus one with the Hammer.
function workbench_dice_allowance() {
	var _n = ds_list_size(oRunManager.tools);
	for (var i = 0; i < ds_list_size(oRunManager.tools); i++) if (oRunManager.tools[| i].object == oHammer) _n++;
	return max(1, _n);
}

/// @func workbench_take_die(_die)
/// @desc The dice picker's event at the workbench: a chosen die leaves the bag and lands in your hand on the bench.
function workbench_take_die(_die) {
	var _i = ds_list_find_index(global.dice_bag, _die);
	if (_i == -1) return;
	var _struct = clone_die(_die, "");
	_struct.selected = false;
	ds_list_delete(global.dice_bag, _i);
	var _inst = instance_create_depth(global.gui.bag_x_deal, global.gui.bag_y_deal, -8, oDice);
	_inst.struct = _struct;
	_inst.action_type = _struct.action_type;
	_inst.dice_amount = _struct.dice_amount;
	_inst.dice_value = _struct.dice_value;
	_inst.possible_type = _struct.possible_type;
	var _target = generate_valid_targets(1, 100)[0];
	_inst.target_x = _target[0];
	_inst.target_y = _target[1];
}

/// @func workbench_tool_used(_object)
/// @desc A tool has crafted: it's used up for this visit and goes back in the toolbag.
function workbench_tool_used(_object) {
	if (!instance_exists(oWorkbenchManager)) return;
	if (progress_get("workbench_hints_done") != true) progress_set("workbench_hints_done", true); // the tool mouse hints have done their job
	array_push(oWorkbenchManager.tools_used, _object);
	// it stays in hand for half a second (its last pose shows), then returns to the bench greyed out (the tool's Step)
	with (_object) {
		tool_used = true;
		used_timer = ceil(game_get_speed(gamespeed_fps) * 0.5);
	}
}

/// @func workbench_open_picker()
/// @desc Opens the bag to choose the dice for this workbench visit (from the prompt or the bag icon).
function workbench_open_picker() {
	if (!instance_exists(oWorkbenchManager) || !oWorkbenchManager.pick_pending) return;
	oWorkbenchManager.pick_pending = false;
	with (oRunManager) {
		dice_selection = workbench_dice_allowance();
		dice_selection_up_to = true;
		dice_selection_message = "Choose up to " + string(dice_selection) + ((dice_selection == 1) ? " die" : " dice") + " to work on";
		dice_selection_event = function(_die) { workbench_take_die(_die); };
		bag_to_show = global.dice_bag;
		show_bag_contents = true;
	}
}

// =====================================================================
// ROLLED DICE (prototype, docs/design-rolled-dice.md)
// =====================================================================

/// @func slot_set_position_bonus(_slot, _index)
/// @desc A slot's place in the queue is worth a flat bonus to its total, once (not per die): slot 1 +0, slot 2 +1,
///       slot 3 +2... So more slots are worth building, and which die goes where is a choice. Shown with its other
///       bonuses (the badge on its first die, the hover breakdown) and as "+N" on the slot.
function slot_set_position_bonus(_slot, _index) {
	slot_set_bonus(_slot, "Slot " + string(_index + 1), _index, "first");
	_slot.position_bonus = _index;
}

/// @func combat_new_slot(_types)
/// @desc A new, empty action slot. _types is what it was built with: "None" (a starting slot, typed by the first
///       coloured die played into it each turn) or the types of the dice that built it ("ATK BLK").
function combat_new_slot(_types) {
	return {
		dice_list: ds_list_create(),			// all dice currently in the slot
		current_action_type: (_types == "None") ? "None" : string_split(_types, " ")[0], // the slot's selected type
		possible_type: _types,					// allowed types
		defined_type: _types,					// the types it was built with, what it goes back to when empty (slot_recompute_types)
		bonus_amount: 0,						// total of the bonuses below, the "+2" in "1d4+2" (read only, see slot_add_bonus)
		bonuses: [],							// { source, amount, turns, scope } from keepsakes and items
		first_die_bonus: 0,						// total of the bonuses that only apply to the first die (read only)
	};
}

/// @func slot_has_action(_slot)
/// @desc A slot with dice in it and an action to do (generic dice alone have none). Slots fill left to right: a slot can
///       only take dice once every slot before it has one (slot_placement_check).
function slot_has_action(_slot) {
	return ds_list_size(_slot.dice_list) > 0 && (_slot.current_action_type != "None" || _slot.possible_type == "All");
}

/// @func combat_all_slots_have_action()
/// @desc Every slot (but a chained one) has an action: only then can a new slot be built.
function combat_all_slots_have_action() {
	for (var j = 0; j < ds_list_size(oCombat.action_queue); j++) {
		if (j == oCombat.locked_slot) continue;
		if (!slot_has_action(oCombat.action_queue[| j])) return false;
	}
	return true;
}

/// @func slot_recompute_types(_slot)
/// @desc A slot's types are the ones it was built with plus those of the dice in it. Empty, a starting slot is
///       untyped again. Keeps the selected type if it's still allowed.
function slot_recompute_types(_slot) {
	var _def = variable_struct_exists(_slot, "defined_type") ? _slot.defined_type : "None";
	var _types = [];
	if (_def != "None" && _def != "") _types = string_split(_def, " ");
	for (var d = 0; d < ds_list_size(_slot.dice_list); d++) {
		var _parts = string_split(_slot.dice_list[| d].possible_type, " ");
		for (var p = 0; p < array_length(_parts); p++) {
			if (_parts[p] != "None" && _parts[p] != "" && !array_contains(_types, _parts[p])) array_push(_types, _parts[p]);
		}
	}
	if (array_length(_types) == 0) {
		_slot.possible_type = "None";
		_slot.current_action_type = "None";
		return;
	}
	if (array_contains(_types, "All")) {
		_slot.possible_type = "All"; // a Multicolor die: any type, right-click picks
		return;
	}
	var _s = "";
	for (var t = 0; t < array_length(_types); t++) _s += ((_s == "") ? "" : " ") + _types[t];
	_slot.possible_type = _s;
	if (!array_contains(_types, _slot.current_action_type)) _slot.current_action_type = _types[0];
}

/// @func die_has_effect_trigger(_die, _trigger)
/// @desc Whether one of the die's own effects fires on _trigger.
function die_has_effect_trigger(_die, _trigger) {
	if (!is_struct(_die) || !variable_struct_exists(_die, "effects") || is_undefined(_die.effects)) return false;
	var _effs = is_array(_die.effects) ? _die.effects : [_die.effects];
	for (var e = 0; e < array_length(_effs); e++) {
		if (is_struct(_effs[e]) && variable_struct_exists(_effs[e], "trigger") && _effs[e].trigger == _trigger) return true;
	}
	return false;
}

/// @func die_can_take_back(_die)
/// @desc A die in a slot (or on the new-slot tile) that was played this turn and has no "when played" effect of its own.
function die_can_take_back(_die) {
	if (!is_struct(_die) || !instance_exists(oCombat)) return false;
	if (!variable_struct_exists(_die, "played_turn") || _die.played_turn != oCombat.turn_count) return false;
	return !(variable_struct_exists(_die, "play_locked") && _die.play_locked);
}

/// @func combat_no_die_dragged()
function combat_no_die_dragged() {
	var _none = true;
	with (oDice) if (is_dragging) _none = false;
	return _none;
}

/// @func combat_take_back(_slot_i, _index)
/// @desc Takes a die played this turn out of a slot (or off the new-slot tile, _slot_i -1) and back to the hand with the
///       same roll, giving its play back. Its "when played" effects don't fire again if it's replayed (played_uids).
function combat_take_back(_slot_i, _index) {
	var _slot = undefined;
	var _list = global.sacrifice_list;
	var _pos = new_tile_pos;
	if (_slot_i >= 0) {
		if (_slot_i >= ds_list_size(action_queue)) return;
		_slot = action_queue[| _slot_i];
		_list = _slot.dice_list;
		_pos = (_slot_i < ds_list_size(slot_positions)) ? slot_positions[| _slot_i] : undefined;
	}
	if (!ds_safe_exists(_list, ds_type_list) || _index < 0 || _index >= ds_list_size(_list)) return;
	var _die = _list[| _index];
	if (!die_can_take_back(_die)) return;

	// slots fill left to right: a slot can't lose its action while a later slot has dice in it
	if (_slot != undefined) {
		var _coloured_left = 0;
		for (var k = 0; k < ds_list_size(_list); k++) if (k != _index && _list[| k].possible_type != "None") _coloured_left++;
		if (_coloured_left == 0) {
			for (var j = _slot_i + 1; j < ds_list_size(action_queue); j++) {
				if (j != locked_slot && ds_list_size(action_queue[| j].dice_list) > 0) {
					throw_error("Take back later dice first", "Slots fill in order, so slot " + string(_slot_i + 1) + " can't be emptied while a later slot has dice.");
					return;
				}
			}
		}
	}
	ds_list_delete(_list, _index);

	// back in hand, flying from where it was
	var _sx = is_struct(_pos) ? _pos.x + _pos.w / 2 : display_get_gui_width() / 2;
	var _sy = is_struct(_pos) ? _pos.y : display_get_gui_height() / 2;
	var _inst = instance_create_layer(_sx, _sy, "Instances", oDice);
	_inst.struct = clone_die(_die, "");
	_inst.struct.played_turn = -1;
	_inst.action_type = _inst.struct.action_type;
	_inst.dice_amount = _inst.struct.dice_amount;
	_inst.dice_value = _inst.struct.dice_value;
	_inst.possible_type = _inst.struct.possible_type;
	_inst.can_discard = true;
	_inst.no_tumble = true; // same roll as before: no tumble on the way back
	var _target = generate_valid_targets(1, 100)[0];
	_inst.target_x = _target[0];
	_inst.target_y = _target[1];

	if (!die_has_keyword(_die, "coin")) dice_played = max(0, dice_played - 1);
	dice_played_scale = 1.2;
	dice_played_color = c_green;
	sfx_play(choose(soRubble1, soRubble2, soRubble3, soRubble4), AUDIO_GROUP.SFX, random_range(0.01, 0.05), 0.2);

	if (_slot != undefined) {
		slot_recompute_types(_slot);
		// a starting slot left with only neutral dice has no type: they come back too
		if (_slot.possible_type == "None") {
			for (var d = ds_list_size(_slot.dice_list) - 1; d >= 0; d--) {
				if (d < ds_list_size(_slot.dice_list) && die_can_take_back(_slot.dice_list[| d])) combat_take_back(_slot_i, d);
			}
		}
	} else {
		update_sacrificed_type_array();
	}

	// keepsakes that read the queue (Single Focus, Repeater Rail) work it out again
	runmanager_trigger_keepsakes("after_change_current_action", {});
}

/// @func combat_rerolls_total()
/// @desc Rerolls this turn: only the ones bought with insight.
function combat_rerolls_total() {
	return oCombat.rerolls_bought;
}

/// @func combat_redraws_total()
/// @desc Redraws this turn: only the ones bought with insight.
function combat_redraws_total() {
	return oCombat.redraws_bought;
}

/// @func combat_insight_can(_cost)
/// @desc Can you spend this much insight now? (your turn, enough of it, not Blotted)
function combat_insight_can(_cost) {
	return oCombat.state == CombatState.PLAYER_INPUT && !oCombat.show_rewards && !intel_is_blotted() && oCombat.player_intel >= _cost;
}

/// @func combat_insight_spend(_cost)
/// @desc Spends insight if you have it (a "-N" floats off the eye); otherwise says why not. True if spent.
function combat_insight_spend(_cost) {
	with (oCombat) {
		if (state != CombatState.PLAYER_INPUT || show_rewards) return false;
		if (intel_is_blotted() || player_intel < _cost) {
			throw_error("Not enough insight", "That costs " + string(_cost) + " insight. You have " + string(max(0, player_intel)) + ".");
			return false;
		}
		player_intel -= _cost;
		var _num = spawn_floating_number("player", _cost, -1, global.color_intel, -1, -1, 0);
		_num.x += 20;
		_num.y -= 20;
		sfx_play(soSlotPlace, AUDIO_GROUP.UI, random_range(0.01, 0.05), 1);
		return true;
	}
	return false;
}

/// @func combat_reveal_cost()
/// @desc Seeing one enemy's exact values: 2 when it's alone, 1 each when there are several.
function combat_reveal_cost() {
	return (combat_living_enemies() > 1) ? 1 : INSIGHT_COST_REVEAL;
}

/// @func enemy_intent_revealed(_enemy)
/// @desc Have you paid to see this enemy's exact values this turn?
function enemy_intent_revealed(_enemy) {
	return is_struct(_enemy) && variable_struct_exists(_enemy, "revealed") && _enemy.revealed;
}

/// @func combat_reveal_enemy(_enemy)
/// @desc Pays combat_reveal_cost to see this enemy's exact values this turn.
function combat_reveal_enemy(_enemy) {
	if (enemy_intent_revealed(_enemy)) return;
	with (oCombat) {
		if (combat_insight_spend(combat_reveal_cost())) {
			_enemy.revealed = true;
			insight_revealed = true; // someone's revealed: the eye opens wide
			intel_level = INTEL_LEGIBLE;
		}
	}
}

/// @func combat_buy(_what)
/// @desc Spend insight on: "reveal" (exact enemy intents this turn), "reroll", "redraw" or "play" (one more of each).
function combat_buy(_what) {
	with (oCombat) {
		switch (_what) {
			case "reveal":
				if (insight_revealed) return;
				if (combat_insight_spend(INSIGHT_COST_REVEAL)) {
					insight_revealed = true;
					intel_level = INTEL_LEGIBLE;
					add_feed_entry("You read the enemies' intent exactly.");
				}
			break;
			case "reroll": if (combat_insight_spend(INSIGHT_COST_REROLL)) rerolls_bought++; break;
			case "redraw": if (combat_insight_spend(INSIGHT_COST_REDRAW)) redraws_bought++; break;
			case "play":   if (combat_insight_spend(INSIGHT_COST_PLAY)) plays_bought++; break;
		}
	}
}

/// @func combat_reroll_die(_inst)
/// @desc Right-click a die in hand: for 3 insight it rolls again.
function combat_reroll_die(_inst) {
	if (state != CombatState.PLAYER_INPUT || show_rewards || !instance_exists(_inst) || !die_has_faces(_inst.struct)) return;
	// a reroll costs 3 insight, paid as you right-click
	if (!combat_insight_can(INSIGHT_COST_REROLL)) {
		throw_error("Not enough insight", "Rerolling a die costs " + string(INSIGHT_COST_REROLL) + " insight. You have " + string(max(0, player_intel)) + ".");
		return;
	}
	if (!combat_insight_spend(INSIGHT_COST_REROLL)) return;
	rerolls_used++;
	die_roll_faces(_inst.struct);
	_inst.roll_anim = 18; // it tumbles in place, then lands on the new roll
	particle_emit(_inst.x, _inst.y, "burst", get_dice_color(_inst.struct.possible_type), 20);
	sfx_play(choose(soRubble1, soRubble2, soRubble3, soRubble4), AUDIO_GROUP.SFX, random_range(0.01, 0.05), 0.2);
}

/// @func combat_discard_and_redraw(_inst)
/// @desc A die dropped on the discard pile in your turn: for 3 insight it's discarded and a new one is drawn. Without
///       the insight it's refused (it goes back to your hand) and says why.
function combat_discard_and_redraw(_inst) {
	if (state != CombatState.PLAYER_INPUT) return;
	if (!combat_insight_can(INSIGHT_COST_REDRAW)) {
		throw_error("Not enough insight", "Discarding a die draws a new one, for " + string(INSIGHT_COST_REDRAW) + " insight. You have " + string(max(0, player_intel)) + ".");
		return;
	}
	if (!combat_insight_spend(INSIGHT_COST_REDRAW)) return;
	discard_dice(_inst);
	dice_to_deal += 1;
	is_dealing_dice = true;
}

/// @func combat_discard_slot_building()
/// @desc End of turn: dice left on the new-slot tile (the slot wasn't built) go to the discard pile.
function combat_discard_slot_building() {
	if (!ds_safe_exists(global.sacrifice_list, ds_type_list)) return;
	for (var j = 0; j < ds_list_size(global.sacrifice_list); j++) {
		var _p = instance_create_layer(is_struct(new_tile_pos) ? new_tile_pos.x + new_tile_pos.w / 2 : gui_w / 2, is_struct(new_tile_pos) ? new_tile_pos.y : gui_h / 2, "Instances", oDiceParticle);
		_p.die_struct = clone_die(global.sacrifice_list[| j], "");
		_p.color_main = get_dice_color(_p.die_struct.possible_type);
		_p.target_x = gui_w - 150;
		_p.target_y = gui_h - 130;
	}
	ds_list_clear(global.sacrifice_list);
	update_sacrificed_type_array();
}

/// @func enemy_is_leader(_enemy)
/// @desc An elite, or the boss in a boss fight (its biggest enemy). When one falls the others flee (combat_enemies_flee).
function enemy_is_leader(_enemy) {
	if (!is_struct(_enemy) || !variable_struct_exists(_enemy, "data")) return false;
	if (variable_struct_exists(_enemy.data, "elite") && _enemy.data.elite) return true;
	if (instance_exists(oWorldManager) && oWorldManager.current_node_type == NODE_TYPE.BOSS) {
		for (var e = 0; e < ds_list_size(oCombat.room_enemies); e++) {
			if (oCombat.room_enemies[| e].max_hp > _enemy.max_hp) return false;
		}
		return true;
	}
	return false;
}

/// @func combat_enemies_flee(_leader)
/// @desc Every other enemy still standing flees: it counts as gone (the fight can be won), fades out, and gives no gold.
function combat_enemies_flee(_leader) {
	var _any = false;
	for (var e = 0; e < ds_list_size(room_enemies); e++) {
		var _en = room_enemies[| e];
		if (_en == _leader || _en.dead) continue;
		_en.dead = true;
		_en.fled = true;
		_en.looted = true; // no bounty
		enemy_turns_remaining--;
		enemies_left_this_combat--;
		enemies_to_fade_out += 1;
		ds_list_clear(_en.debuffs);
		particle_emit(_en.pos_x, _en.pos_y, "rise", c_white);
		_any = true;
	}
	if (_any) add_feed_entry("With their leader down, the rest flee!");
}

/// @func combat_turn_tokens_draw(_cx, _right_max, _y, _view)
/// @desc Your plays this turn, above End Turn, centred on _cx but never past _right_max (the slots): "N plays left",
///       then a brass token per play (dark once used; yellow if bought with insight), then a faded yellow pip for each
///       more play your insight could buy (4 each): click one to buy it. Out of plays with 4+ insight, a callout above
///       says so. Playing (or failing to) makes the tokens pulse green (or red). (_view is unused now.)
function combat_turn_tokens_draw(_cx, _right_max, _y, _view = false) {
	var _total = max(dice_allowed_per_turn, dice_played);
	var _left = max(0, dice_allowed_per_turn - dice_played);
	var _my_turn = (state == CombatState.PLAYER_INPUT && !show_rewards);
	var _buyable = 0; // plays can't be bought any more (insight rewrites the log, it doesn't add plays)
	var _r = 11, _gap = 5;
	var _dark = make_color_rgb(42, 29, 18);
	var _brass = make_color_rgb(232, 196, 106);
	var _spent = make_color_rgb(90, 69, 53);

	var _n = _total + _buyable;
	var _w = _n * (_r * 2) + max(0, _n - 1) * _gap + ((_buyable > 0) ? 8 : 0); // a little space before the buyable ones
	var _x0 = min(_cx - _w / 2, _right_max - _w);

	// "N plays left", as it was
	draw_set_font(ftDefault);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_outline_text((_left == 1) ? "1 play left" : string(_left) + " plays left", c_black, dice_played_color, 2, _x0 + _w / 2, _y - 30, 1, 1, 0);

	var _hover = mouse_hovering(_x0 - 4, _y - _r - 4, _total * (_r * 2 + _gap) + 8, _r * 2 + 8, false);
	var _s = dice_played_scale;
	var _ring = merge_colour(_dark, dice_played_color, clamp((dice_played_scale - 1) * 2.5, 0, 1));
	for (var t = 0; t < _total; t++) {
		var _tx = _x0 + _r + t * (_r * 2 + _gap);
		var _on = (t < _left);
		var _paid = (t >= _total - plays_bought); // bought with insight: the last ones
		var _fill = _on ? (_paid ? global.color_intel : _brass) : _spent;
		var _rr = _r * _s * (_hover ? 1.1 : 1);
		draw_set_color(_ring);
		draw_circle(_tx, _y, _rr + 3, false);
		draw_set_color(_fill);
		draw_circle(_tx, _y, _rr, false);
		draw_set_color(_on ? merge_colour(_fill, c_white, 0.35) : merge_colour(_fill, c_white, 0.1));
		draw_circle(_tx, _y - _rr * 0.35, _rr * 0.45, false);
		draw_set_color(_fill);
		draw_circle(_tx, _y - _rr * 0.15, _rr * 0.55, false);
	}
	if (_hover && !show_rewards) queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Plays", "Dice you can play this turn: " + string(_left) + " left. Coins are free to play.");

	// the plays your insight could buy: faded yellow pips, click to buy one
	for (var b = 0; b < _buyable; b++) {
		var _bx = _x0 + 8 + _r + (_total + b) * (_r * 2 + _gap);
		var _bhover = mouse_hovering(_bx - _r - 3, _y - _r - 3, _r * 2 + 6, _r * 2 + 6, false);
		var _br = _r * (_bhover ? 1.2 : 1);
		draw_set_alpha(_bhover ? 0.95 : 0.5);
		draw_set_color(_dark);
		draw_circle(_bx, _y, _br + 3, false);
		draw_set_color(_bhover ? make_color_rgb(150, 145, 130) : make_color_rgb(110, 105, 95)); // faded grey until bought (then a yellow token)
		draw_circle(_bx, _y, _br, false);
		draw_set_alpha(1);
		draw_set_color(global.color_intel);
		for (var k = 0; k < 8; k++) draw_arc_thick_deg(_bx, _y, _br + 1, _br + 3, k * 45, k * 45 + 25, 4); // a dashed edge: not yours yet
		if (_bhover) {
			queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Buy a play", "Spend " + string(INSIGHT_COST_PLAY) + " insight to play one more die this turn.", undefined, 0, undefined, INSIGHT_COST_PLAY, "insight");
			if (mouse_check_button_pressed(mb_left) && global.ui_layer == UI_LAYER.BASE && combat_no_die_dragged()) combat_buy("play");
		}
	}

	// out of plays, but insight could buy more: say so above the row
	if (_left == 0 && _buyable > 0) {
		var _name = "Out of plays";
		var _desc = "Spend " + string(INSIGHT_COST_PLAY) + " insight to play another die: click a yellow pip.";
		var _sz = draw_tooltip_box(0, 0, _name, _desc, undefined, 0, undefined, false, true);
		var _bx0 = clamp(_x0 + _w / 2 - _sz.w / 2, 10, display_get_gui_width() - _sz.w - 10);
		var _by0 = _y - 52 - _sz.h;
		draw_tooltip_box(_bx0, _by0, _name, _desc, undefined, 0, undefined, false, false);
		tooltip_cost_badge(_bx0 + _sz.w, _by0, INSIGHT_COST_PLAY, "insight");
	}
	draw_set_color(c_white);
	draw_set_alpha(1);
}

/// @func combat_token_symbol(_group, _x, _y, _r, _col)
/// @desc The symbol on a reroll token (a circling arrow) or a redraw token (an arrow up out of a line); plays have none.
function combat_token_symbol(_group, _x, _y, _r, _col) {
	draw_set_color(_col);
	if (_group == 1) {
		draw_arc_thick_deg(_x, _y, _r * 0.42, _r * 0.62, 50, 320, 20);
		var _hx = _x + lengthdir_x(_r * 0.52, 50), _hy = _y + lengthdir_y(_r * 0.52, 50);
		draw_triangle(_hx - _r * 0.38, _hy - _r * 0.05, _hx + _r * 0.3, _hy - _r * 0.22, _hx + _r * 0.02, _hy + _r * 0.42, false);
	} else if (_group == 2) {
		draw_line_width(_x, _y + _r * 0.35, _x, _y - _r * 0.25, max(2, _r * 0.18));
		draw_triangle(_x - _r * 0.36, _y - _r * 0.15, _x + _r * 0.36, _y - _r * 0.15, _x, _y - _r * 0.6, false);
		draw_line_width(_x - _r * 0.45, _y + _r * 0.5, _x + _r * 0.45, _y + _r * 0.5, max(2, _r * 0.16));
	}
}

// =====================================================================
// INSIGHT VIEW: the eye opens it; everything dims except what insight can buy
// =====================================================================

/// @func intent_verbs(_move)
/// @desc What an enemy's move does, in words for a sentence: "attack", "attack and block", "heal"...
function intent_verbs(_move) {
	var _parts = string_split(_move.action_type, "/");
	var _out = "";
	for (var i = 0; i < array_length(_parts); i++) {
		var _w = string_lower(_parts[i]);
		switch (_parts[i]) {
			case "ATK": _w = "attack"; break;
			case "BLK": _w = "block"; break;
			case "HEAL": _w = "heal"; break;
			case "BUFF": _w = "buff"; break;
			case "DEBUFF": _w = "debuff"; break;
		}
		_out += ((i == 0) ? "" : ((i == array_length(_parts) - 1) ? " and " : ", ")) + _w;
	}
	return _out;
}

/// @func combat_insight_phase_worth()
/// @desc Is there anything your ink could do right now? (the cheapest: a reveal, or a reroll or redraw at 3)
function combat_insight_phase_worth() {
	return combat_insight_can(min(combat_reveal_cost(), INSIGHT_COST_REROLL, INSIGHT_COST_REDRAW));
}

/// @func combat_redraw_die(_inst)
/// @desc In the insight phase: for 3 ink, a die in hand is discarded and a new one dealt (it rolls as it comes).
function combat_redraw_die(_inst) {
	if (!instance_exists(_inst) || !combat_insight_spend(INSIGHT_COST_REDRAW)) return;
	discard_dice(_inst);
	dice_to_deal += 1;
	is_dealing_dice = true;
}

/// @func combat_insight_view_set(_open)
/// @desc Opens or closes the insight phase. While it's open the rest of the screen ignores the mouse (UI_LAYER.POPUP).
function combat_insight_view_set(_open) {
	with (oCombat) {
		if (insight_view == _open) return;
		insight_view = _open;
		insight_view_age = 0; // frames open (oCombat Step): the click that opened it can't also close it
		global.ui_layer = _open ? UI_LAYER.POPUP : UI_LAYER.BASE;
		sfx_play(soSlotPlace, AUDIO_GROUP.UI, random_range(0.01, 0.05), 1);
	}
}

/// @func combat_insight_part_draw(_x1, _y1, _x2, _y2, _afford, _hover, _pulse, _cost, _label, _coin_left)
/// @desc One half of an intent in insight view: a yellow outline (grey if you can't afford it) and its cost on a coin at
///       its top corner (left or right). _label is unused (the hover says what it does).
function combat_insight_part_draw(_x1, _y1, _x2, _y2, _afford, _hover, _pulse, _cost, _label, _coin_left) {
	var _col = _afford ? global.color_intel : make_color_rgb(120, 110, 80);
	var _grow = _afford ? (_hover ? 4 : _pulse * 2) : 0;
	draw_set_color(_col);
	for (var k = 0; k < (_hover ? 4 : 2); k++) draw_roundrect_ext(_x1 - k - _grow, _y1 - k - _grow, _x2 + k + _grow, _y2 + k + _grow, 16, 16, true);
	var _cx = _coin_left ? _x1 : _x2, _cy = _y1;
	draw_set_color(c_black);
	draw_circle(_cx, _cy, 17, false);
	draw_set_color(_col);
	draw_circle(_cx, _cy, 14, false);
	draw_set_font(ftDefault);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_black);
	draw_text(_cx, _cy, string(_cost));
	// (no "Reroll" / "Exact" labels: the coins and the hovers say it)
}

/// @func combat_insight_view_draw()
/// @desc The insight phase, drawn first in oRunManager Draw GUI End (so the dice dim too): the screen darkens except
///       the enemy intents and the dice in your hand, which your quill can rewrite. Each intent is split in two: its
///       move (left) rerolled for 6, its numbers (right) shown exactly for 2 (1 each with several enemies). Each die
///       in hand is drawn again on top, edged in yellow: left-click rerolls it (3), right-click redraws it (3). Every
///       one has a tooltip with its cost tag; the cursor is a quill (cursor_draw). End Turn becomes "Seal the log",
///       the only way to end the phase (or Enter).
function combat_insight_view_draw() {
	if (!instance_exists(oCombat) || !oCombat.insight_view) return;
	with (oCombat) {
		var _gw = display_get_gui_width(), _gh = display_get_gui_height();
		var _top = ui_top_bar_h();
		var _pad = 14;

		// the overlay: dark, with the intents and your hand cut out of it (subtract blend), so they show at full colour
		if (!surface_exists(insight_surf)) insight_surf = surface_create(_gw, _gh);
		surface_set_target(insight_surf);
		draw_clear_alpha(c_black, 0.72);
		gpu_set_blendmode(bm_subtract);
		draw_set_color(c_white);
		for (var e = 0; e < ds_list_size(room_enemies); e++) {
			var _en = room_enemies[| e];
			if (_en.dead || !variable_struct_exists(_en, "intent_rect")) continue;
			var _ir = _en.intent_rect;
			draw_roundrect_ext(_ir.x - _ir.w / 2 - _pad, _ir.y - _ir.h / 2 - _pad, _ir.x + _ir.w / 2 + _pad, _ir.y + _ir.h / 2 + _pad, 18, 18, false);
		}
gpu_set_blendmode(bm_normal);
		surface_reset_target();
		draw_surface_part(insight_surf, 0, _top, _gw, _gh - _top, 0, _top); // the top bar stays as it is

		// the inkwell, on top, with your ink beside it
		var _ex = global.player_x, _ey = global.player_y - 180;
		draw_inkwell(_ex, _ey, 1.15, player_intel / INSIGHT_MAX, false);
		draw_set_font(ftDefault);
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_outline_text(string(player_intel), c_black, global.color_intel, 2, _ex + 44, _ey + 10, 1, 1, 0);

		// done writing: End Turn becomes "Seal the log", drawn lit on top where End Turn is (oCombat Draw GUI sets end_turn_draw)
		var _seal_click = false;
		if (variable_instance_exists(id, "end_turn_draw")) {
			var _et = end_turn_draw;
			var _sw = sprite_get_width(sEndTurn) * _et.s, _sh = sprite_get_height(sEndTurn) * _et.s;
			var _sx = _et.x - sprite_get_xoffset(sEndTurn) * _et.s, _sy = _et.y - sprite_get_yoffset(sEndTurn) * _et.s;
			var _seal_hov = mouse_hovering(_sx, _sy, _sw, _sh, false, soSlotHover, noone, true, UI_LAYER.POPUP);
			close_btn_scale = lerp(close_btn_scale, _seal_hov ? 1.08 : 1, 0.25);
			var _breathe = 1 + 0.03 * (0.5 + 0.5 * sin(current_time / 220));
			var _ss = close_btn_scale * _breathe * _et.s;
			draw_sprite_ext(sEndTurn, 0, _et.x, _et.y, _ss, _ss, 0, global.color_intel, 1);
			draw_set_font(ftDefault);
			draw_set_halign(fa_center);
			draw_set_valign(fa_middle);
			draw_outline_text("SEAL THE LOG", c_black, c_white, 2, _et.tx, _et.ty, close_btn_scale, 1, 0);
			if (_seal_hov) queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Seal the log", "Done rewriting: close the log and play your dice. It stays closed until next turn; ink you don't spend carries over.");
			_seal_click = _seal_hov && mouse_check_button_pressed(mb_left);
		}

		var _pulse = 0.5 + 0.5 * sin(current_time / 200);

		// each intent: the move (left, under its icon) rerolled for 6; the numbers (right) shown exactly
		for (var e = 0; e < ds_list_size(room_enemies); e++) {
			var _en = room_enemies[| e];
			if (_en.dead || !variable_struct_exists(_en, "intent_rect")) continue;
			var _ir = _en.intent_rect;
			var _x1 = _ir.x - _ir.w / 2 - _pad, _y1 = _ir.y - _ir.h / 2 - _pad, _x2 = _ir.x + _ir.w / 2 + _pad, _y2 = _ir.y + _ir.h / 2 + _pad;
			var _sx = variable_struct_exists(_ir, "split") ? _ir.split : _ir.x;

			var _ok = enemy_can_rewrite_intent(_en);
			var _afford = _ok && combat_insight_can(INSIGHT_COST_QUILL);
			var _lhover = mouse_hovering(_x1, _y1, _sx - _x1, _y2 - _y1, false, noone, soClick4, true, UI_LAYER.POPUP);
			combat_insight_part_draw(_x1, _y1, _sx - 2, _y2, _afford, _lhover, _pulse, INSIGHT_COST_QUILL, "", true);
			if (_lhover) {
				if (_ok) queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Reroll intent", "Spend " + string(INSIGHT_COST_QUILL) + " insight: " + string(_en.data.name) + " picks a different move, rolled fresh.", undefined, 0, undefined, INSIGHT_COST_QUILL, "insight");
				else queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Can't be rewritten", "This move is forced, or " + string(_en.data.name) + " has nothing else to choose.");
				if (mouse_check_button_pressed(mb_left) && _ok && combat_insight_spend(INSIGHT_COST_QUILL) && enemy_rewrite_intent(_en)) {
					_en.intent.scale = _en.intent.start_scale * 1.4; // pop, so the change is noticed
					add_feed_entry("You rewrote " + string(_en.data.name) + "'s intent: " + string(_en.intent.move.move_name));
				}
			}

			if (!enemy_intent_revealed(_en) && intent_has_numbers(_en.intent.move)) {
				var _rcost = combat_reveal_cost();
				var _rafford = combat_insight_can(_rcost);
				var _rhover = mouse_hovering(_sx, _y1, _x2 - _sx, _y2 - _y1, false, noone, soClick4, true, UI_LAYER.POPUP);
				combat_insight_part_draw(_sx + 2, _y1, _x2, _y2, _rafford, _rhover, _pulse, _rcost, "", false);
				if (_rhover) {
					queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Reveal exact numbers", "Spend " + string(_rcost) + " insight to reveal the exact value " + string(_en.data.name) + " intends to " + intent_verbs(_en.intent.move) + " with.", undefined, 0, undefined, _rcost, "insight");
					if (mouse_check_button_pressed(mb_left)) combat_reveal_enemy(_en);
				}
			}
		}

		// your dice in hand, lit above the dark: left-click rerolls (3), right-click redraws (3). Hovered: mouse hints above
		// it and a tooltip. (Not while it's still rolling in.)
		var _rr_can = combat_insight_can(INSIGHT_COST_REROLL), _rd_can = combat_insight_can(INSIGHT_COST_REDRAW);
		var _clicked = noone, _clicked_what = "";
		var _over_die = false;
		with (oDice) {
			if (still || in_slot) continue;
			var _r = 36 * scale * (1 + 0.22 * land_pop);
			var _face = tumbling ? flick_face : (die_has_faces(struct) ? die_face_total(struct) : -1);
			var _ready = !is_dragging && !tumbling && die_has_faces(struct);
			var _hov = _ready && mouse_hovering(x, y, 84, 84, true, noone, noone, true, UI_LAYER.POPUP);
			// a yellow edge (brighter when hovered), then the die itself, on top of the dark
			var _glow = (_rr_can || _rd_can) ? (_hov ? 1 : 0.55 + 0.25 * sin(current_time / 200)) : 0.25;
			draw_die_shape(x, y, _r * (_hov ? 1.22 : 1.16), dice_value, global.color_intel, tumble_angle, _glow);
			draw_die(x, y, _r * (_hov ? 1.08 : 1), dice_value, _face, get_dice_color(struct.possible_type), tumble_angle, 1);
			if (_hov) {
				_over_die = true;
				draw_mouse_hint(x - 78, y - _r - 46, "left", "Reroll", 0.6, _rr_can ? global.color_intel : make_color_rgb(90, 90, 100), _rr_can ? global.color_intel : make_color_rgb(150, 150, 160));
				draw_mouse_hint(x + 22, y - _r - 46, "right", "Redraw", 0.6, _rd_can ? global.color_intel : make_color_rgb(90, 90, 100), _rd_can ? global.color_intel : make_color_rgb(150, 150, 160));
				queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Reroll or redraw", "Left-click: spend " + string(INSIGHT_COST_REROLL) + " insight to roll this die again.\nRight-click: spend " + string(INSIGHT_COST_REDRAW) + " insight to discard it and draw a new die.", undefined, 0, undefined, INSIGHT_COST_REROLL, "insight");
				if (mouse_check_button_pressed(mb_left) && _rr_can) { _clicked = id; _clicked_what = "reroll"; }
				if (mouse_check_button_pressed(mb_right) && _rd_can) { _clicked = id; _clicked_what = "redraw"; }
			}
		}
		if (_clicked != noone) {
			if (_clicked_what == "reroll") combat_reroll_die(_clicked);
			else combat_redraw_die(_clicked);
		}

		// closing: only "Seal the log" (or Enter, End Turn's key: oCombat Step)
		if (insight_view_age > 0 && _seal_click) combat_insight_view_set(false);

		draw_set_color(c_white);
		draw_set_alpha(1);
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
	}
}
