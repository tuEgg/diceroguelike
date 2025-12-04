/// process_action(_target, _dice_amount, _dice_value, _bonus_amount, _source, _type, _slot_number, _slot_die, _num, _flat_damage)
/// _target: "enemy" or "player"
/// _dice_amount: base amount of dice
/// _dice_value: highest roll of dice
/// _bonus_amount: the bonus value to add to the roll
/// _source: "enemy" or "player" (attacker or caster)
/// _type: "atk" or "heal"

function process_action(_target, _dice_amount, _dice_value, _bonus_amount, _source, _type, _slot_number = -1, _slot_die = undefined, _num = 0) {
	show_debug_message("this dice has a value of: "+string(_dice_value));

    // --- Roll total amount ---
    var amount = 0;
	var slot_bonus_amount = _bonus_amount;
	var _keepsake_dice_bonus_amount = 0;
	
	repeat (_dice_amount) {
		// Roll starts at default range
		var _min_roll = 1;
		var _max_roll = _dice_value;
		var final_roll = amount;
		
		// Player tweaks numbers differently from enemy
		if (_source == "player") {
			var dice_output = get_dice_output(_slot_die, _slot_number, false);
			
			_min_roll = dice_output.min_roll;			
			_max_roll = dice_output.max_roll;
			_keepsake_dice_bonus_amount = dice_output.keepsake_dice_bonus_amount;
			var _prev_slot_type = dice_output.previous_slot_type;
			
			// Create our array for weighted rolling
			var distribution_array = [];
		
			// depending on distribution, use the array or not
			define_dice_distributions(_slot_die.distribution, _min_roll, _max_roll, distribution_array);
			show_debug_message("---" + string(_min_roll));
			show_debug_message("dice MINIMUM roll is " + string(_min_roll));
			show_debug_message("---" + string(_min_roll));
			
			// Our new weighted roll values, will be a range from 1 to the sum of the entire distribution array
			var weight_min = 1;
			var weight_max = 0;
			for (var d = 0; d < array_length(distribution_array); d++) {
				weight_max += distribution_array[d];
			}
		
			// Roll between all the values in the array
			var weighted_roll = irandom_range(weight_min, weight_max);
			
			// used for determining which numbers can actually be rolled when taking into account distribution
			var actual_possible_numbers = [];
		
			// Assign a value to that rolled weighted value, 1,2,3 = 1; 4,5,6,7 = 2; 8,9,10,11,12 = 3; 13,14,15,16,17,18 = 4; for a d4
			for (var d = 0; d < array_length(distribution_array); d++) {
				// remove this arrays value
				weighted_roll -= distribution_array[d];
				
				// add to our actual possible numbers array any entry that isn't empty (aka its a number that can be rolled)
				if (distribution_array[d] != 0)	{
					array_push(actual_possible_numbers, d + _min_roll );
					show_debug_message("Adding  " + string( d + _min_roll ) + " to the list of actual possible numbers for this die");
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
						die: _slot_die,
						min_roll: actual_possible_numbers[0], // first row in distribution array that isn't zero,
						//max_roll: actual_possible_numbers[ array_length(actual_possible_numbers) - 1] // first row in distribution array that isn't zero -- THIS isn't possible yet because we need to continue looping through the numbers after we find our actual number to check for what our real max is
					}
					
					combat_trigger_effects("after_roll_die", ctx, _slot_die);
					
					final_roll = ctx._d_amount;
					
					// die statistics
					_slot_die.statistics.times_played_this_combat++;
					
					ds_list_add(_slot_die.statistics.roll_history, final_roll);
					
					break;
				}
			}
		} else {
			final_roll = irandom_range( _min_roll, _max_roll );
		}
		
		amount = final_roll + slot_bonus_amount + _keepsake_dice_bonus_amount; // add the roll, the slot bonus and the keepsake/dice bonus to create the final amount.
		
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
		show_debug_message("dice amount is zero - this is for flat damage - setting value to "+string(_dice_value));
	}

    var inst_color = c_red; // default color for damage

    // --- DAMAGE ---
    switch (_type) {
		case "ATK":
        
			var block_used = 0;
	        var final_damage = amount;

	        // Player attacking enemy
	        if (_target == "enemy") {
			
	            // If the enemy has block
	            if (enemy_block_amount > 0) {
	                block_used = min(enemy_block_amount, amount);
	                enemy_block_amount -= block_used;
	                final_damage -= block_used;

	                var num = spawn_floating_number("enemy", block_used, -1, c_aqua, -1, -1, _num);
					num.x += 20;
					num.y += 20;
	            }

	            // Deal any remaining damage
	            if (final_damage > 0) {
	                enemy_hp = max(0, enemy_hp - final_damage);
	                spawn_floating_number("enemy", final_damage, -1, c_red, -1, -1, _num);
	            }

	            inst_color = c_red;
	        }

	        // Enemy attacking player
	        else if (_target == "player") {
	            if (player_block_amount > 0) {
	                block_used = min(player_block_amount, amount);
	                player_block_amount -= block_used;
	                final_damage -= block_used;

	                var num = spawn_floating_number("player", block_used, -1, c_aqua, -1, -1, _num);
					num.x += 20;
					num.y += 20;
	            }

	            if (final_damage > 0) {
	                global.player_hp = max(0, global.player_hp - final_damage);
	                spawn_floating_number("player", final_damage, -1, c_red, -1, -1, _num);
				
	            }

	            inst_color = c_red;
	        }
		break;

	    // --- BLOCK ---
	    case "BLK":
	        if (_target == "enemy") {
				enemy_turns_since_last_block = 0;
	            enemy_block_amount += amount;
	        } else if (_target == "player") {
	            player_block_amount += amount;
	        }

	        spawn_floating_number(_target, amount, -1, c_aqua, 1, -1, _num);
	        inst_color = c_aqua;
		break;

	    // --- HEAL ---
	    case "HEAL":
	        if (_target == "enemy") {
	            enemy_hp = min(enemy_max_hp, enemy_hp + amount);
	            add_feed_entry("Enemy heals " + string(amount) + " HP!");
	        } else if (_target == "player") {
	            global.player_hp = min(global.player_max_hp, global.player_hp + amount);
	            add_feed_entry("You heal " + string(amount) + " HP!");
	        }

	        spawn_floating_number(_target, amount, -1, c_lime, 1);
	        inst_color = c_lime;
		break;
		
		case "DEBUFF":
			if (_target == "player") {
			    apply_buff(global.player_debuffs, enemy_intent.debuff, enemy_intent.debuff.duration, 1);
			}
		break;
		
		case "INTEL":
			apply_buff(global.player_debuffs, oRunManager.buff_intel, 1, amount);
			var num = spawn_floating_number("player", amount, -1, global.color_intel, 1, -1, _num);
			num.x += 20;
			num.y -= 20;
		break;
	}
}


function spawn_floating_number(_target, _amount, _txt, _inst_color, _num_sign, _slot_number = -1, _number = -1) {
	// Spawn floating number
    var inst_x, inst_y;
	
	var offset_x = 30 * (sin(_number*30));
	var offset_y = (_number * 30);
	
    switch (_target) {
		case "enemy":
        inst_x = global.enemy_x + offset_x;
        inst_y = global.enemy_y + offset_y;
		break;
		
		case "player":
        inst_x = global.player_x + offset_x;
        inst_y = global.player_y + offset_y;
		break;
		
		case "slot":
		inst_x = slot_positions[| _slot_number].x + GUI_LAYOUT.ACTION_TILE_W/2 + random_range(-50, 50);
		inst_y = slot_positions[| _slot_number].y - 80 + random_range(-50, 50);
		break;
		
		default:
		inst_x = display_get_gui_width()/2;
		inst_y = display_get_gui_height()/2;
    }

    var inst = instance_create_layer(inst_x, inst_y, "Instances", oDamageText);
	inst.txt = _txt;
    inst.amount = _amount;
    inst.color_main = _inst_color;
	inst.num_sign = _num_sign;
	
	return inst;
}

/// @desc Returns the index of the hovered action slot or -1 if none
function get_hovered_action_slot() {
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);

    var aq_list_size = ds_list_size(action_queue);
    var aq_tile_w = GUI_LAYOUT.ACTION_TILE_W;
    var aq_tile_padding = GUI_LAYOUT.ACTION_TILE_PADDING;
    var aq_total_w = ((aq_list_size + 1) * aq_tile_w) + ((aq_list_size - 1) * aq_tile_padding);
    var aq_start_x = display_get_gui_width() / 2 - (aq_total_w / 2);
    var aq_start_y = display_get_gui_height() / 2;

    for (var i = 0; i < aq_list_size; i++) {
        var base_x = aq_start_x + (i * (aq_tile_w + aq_tile_padding));
        var base_y = aq_start_y;
        var base_w = aq_tile_w;
        var base_h = aq_tile_w;
        var current_scale = tile_scale[| i];

        var draw_w = base_w * current_scale;
        var draw_h = base_h * current_scale;
        var draw_x = base_x + (base_w - draw_w) / 2;
        var draw_y = base_y + (base_h - draw_h) / 2;

        if (mx > draw_x && mx < draw_x + draw_w && my > draw_y && my < draw_y + draw_h) {
            return i;
        }
    }
	
    return -1; // no slot hovered
}

/// @param die_id  The instance ID of the dropped die
/// @param slot_index  The index of the hovered slot

function apply_dice_to_slot(_die, _slot_i) {
    var die  = _die;
    var slot = action_queue[| _slot_i];
	var stats = get_slot_stats(slot, _slot_i);

    var reject_dice = false;

    var is_queue_all  = (slot.possible_type == "All");
    var is_queue_none = (slot.possible_type == "None");
    var is_dice_none  = (die.struct.possible_type == "None");
	var is_dice_exclusive = string_has_keyword(die.struct.description, "Exclusive");
	var is_slot_exclusive = string_has_keyword(die.struct.description, "Exclusive");
	var is_dice_coin = false;
	if (die.struct.dice_value == 2) is_dice_coin = true;
	var dice_keyword_list = string_split(die.struct.possible_type, " ");
	var dice_has_match_with_slot = false;
	var dice_has_more_than_one_type = false;
	
	// Find current index in opts
	for (var n = 0; n < array_length(dice_keyword_list); n++) {
	    if (string_pos(dice_keyword_list[n], slot.possible_type)) {
	        dice_has_match_with_slot = true;
	        break;
	    }
	}
	
	if (dice_has_match_with_slot && array_length(dice_keyword_list) > 1) {
		dice_has_more_than_one_type = true;
	}
	
	if (dice_played >= dice_allowed_per_turn) {
		if (!string_has_keyword(die.struct.description, "coin")) {
			reject_dice = true;	
			dice_played_scale = 1.4;
			dice_played_color = c_red;
			return;
		}
	}

    //-----------------------------------------
    // CASE 1: Dice has a specific colour/type
    //-----------------------------------------
	
	if (!is_dice_none) {
	    if (is_queue_none) {
	        // --- Empty slot, becomes colored slot
			slot.current_action_type = die.struct.action_type;
	        slot.possible_type = die.struct.possible_type;

	        var die_copy = clone_die(die.struct, "base"); // coloured dice added to empty slots become base die
	        ds_list_add(slot.dice_list, die_copy);
			
			var history_copy = clone_die(die.struct, "temporary");
			ds_list_add(global.sacrifice_history, history_copy ); // persistent record
	    }
	    else if (is_queue_all) {
	        reject_dice = true;
	    }
	    else if (dice_has_match_with_slot) {
			if (is_dice_exclusive || is_slot_exclusive) {
				reject_dice = true;
			} else {
		        // Only accept dice as strong or stronger
		        if (die.struct.dice_value >= stats.value || is_dice_coin) {
		            var die_copy = clone_die(die.struct, string_has_keyword(die.struct.description, "sticky") ? "base" : "temporary");
		            ds_list_add(slot.dice_list, die_copy);
				
					// Add possible type if this slot does not have it
					if (dice_has_more_than_one_type) {
					
						// only add new unique types
						var parts = string_split(die.possible_type, " ");
						var total = array_length(parts);
						//show_debug_message("This slot has types "+string(slot.possible_type));

						for (var i = 0; i < total; i++) {
							if (string_pos(string(parts[i]), slot.possible_type) > 0) {
								//show_debug_message("This slot already has "+string(parts[i]));
							} else {
								slot.possible_type = string_concat(slot.possible_type, " ", parts[i]);
								//show_debug_message("This slot doesn't have "+string(parts[i])+" so we added it.");
							}
						}
					}

		            stats.amount += die_copy.dice_amount;
		            stats.value   = max(die_copy.dice_value, stats.value);
		            //show_debug_message("Adding coloured dice to coloured slot.");
		        } else {
		            reject_dice = true;
		        }
			}
	    }
	    else {
	        reject_dice = true;
	    }
	}

	//-----------------------------------------
	// CASE 2: Dice is generic (no color)
	//-----------------------------------------
	else {
	    if (is_queue_all) {
	        var die_copy = clone_die(die.struct, string_has_keyword(die.struct.description, "sticky") ? "base" : "temporary");
	        ds_list_add(slot.dice_list, die_copy);

	        stats.amount += die_copy.dice_amount;
	        stats.value   = max(die_copy.dice_value, stats.value);
	    }
	    else if (!is_queue_none) {
			if (is_dice_exclusive || is_slot_exclusive) {
				reject_dice = true;
			} else {
		        if (die.struct.dice_value >= stats.value) {
		            var die_copy = clone_die(die.struct, string_has_keyword(die.struct.description, "sticky") ? "base" : "temporary");
		            ds_list_add(slot.dice_list, die_copy);

		            stats.amount += die_copy.dice_amount;
		        } else {
		            reject_dice = true;
		        }
			}
	    }
	    else {
	        reject_dice = true;
	    }
	}

    //-----------------------------------------
    // Result
    //-----------------------------------------
    if (!reject_dice) {
        add_feed_entry("You used a dice!");
		if (!string_has_keyword(die.struct.description, "coin")) dice_played++;
		dice_played_scale = 1.2;
		dice_played_color = c_green;
		
		// Let keepsakes/dice adjust roll range
		combat_trigger_effects("on_die_played", { dice_object: die }, die.struct);
		
		// die statistics
		die.struct.statistics.times_played_this_combat++;
		
		instance_destroy(die);
    }
}

/// is_mouse_over_discard_button()
function is_mouse_over_discard_button() {
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);

    // Bottom-right button area (adjust as needed)
    var btn_w = GUI_LAYOUT.DISCARD_W;
    var btn_h = GUI_LAYOUT.DISCARD_H;
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
    var die_copy = clone_die(die_struct, "temporary");

    // --- 3. Add to discard pile
    ds_list_add(global.discard_pile, die_copy);

    // --- 4. Cleanup visuals
    instance_destroy(die);

    // --- 5. Combat feed + reset state
    if (instance_exists(oCombat)) oCombat.is_discarding = false;
    //with (oCombat) add_feed_entry("You discarded a dice!");
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
    var die_copy = clone_die(die_struct, "temporary");

    // --- 3. Add to discard pile
    ds_list_add(global.dice_bag, die_copy);

    // --- 4. Cleanup visuals
    instance_destroy(die);
}



function sacrifice_die(_die) {
	if (dice_played >= dice_allowed_per_turn) {
		if (!string_has_keyword(_die.struct.description, "coin")) {
			dice_played_scale = 1.4;
			dice_played_color = c_red;
			return;
		}
	}
	
	if (!string_has_keyword(_die.struct.description, "coin")) dice_played++;
	dice_played_scale = 1.2;
	dice_played_color = c_green;
	
    var die = _die;
    var die_struct = die.struct;

    // Clone before adding
	var _perm = "temporary";
	if (die_struct.action_type == "None") {
		_perm = "temporary none"; // used for tracking sacrificed history of dice used to create slots that become temporary
		//show_debug_message("Added TEMPORARY NONE to sack history");
	}
	var die_copy = clone_die(die_struct, _perm);
    ds_list_add(global.sacrifice_list, die_copy);
	//show_debug_message("Added dice to list, new length is: "+string(ds_list_size(global.sacrifice_list)));
	
    var history_copy  = clone_die(die_struct, _perm);
	ds_list_add(global.sacrifice_history, history_copy ); // persistent record
	
	particle_emit( die.x, die.y, choose("burst"), die.struct.color);
	
    instance_destroy(die);

    sacrificies_til_new_action_tile--;
	
	update_sacrificed_type_array();

    if (sacrificies_til_new_action_tile > 0) return;

    // === Time to create new slot ===
	var type_list = ds_list_create();
	var highest_val = 4;
	var all_generic = true;

	// Analyse all sacrificed dice
	for (var j = 0; j < ds_list_size(global.sacrifice_list); j++) {
	    var listed_die = global.sacrifice_list[| j];

	    if (listed_die.action_type != "None") {
	        all_generic = false;
	    }

	    // Only add unique types
	    if (ds_list_find_index(type_list, listed_die.possible_type) < 0) {
			if (string_pos(" ", listed_die.possible_type)) {
				var parts = string_split(listed_die.possible_type, " ");
				var total = array_length(parts);

				for (var i = 0; i < total; i++) {
				    if (ds_list_find_index(type_list, string(parts[i])) < 0) {
						ds_list_add(type_list, string(parts[i]));
					}
				}
			} else {
				ds_list_add(type_list, listed_die.possible_type);
			}
	    }

	    highest_val = max(highest_val, listed_die.dice_value);
	}

	// --- Now build possible_type string ---
	var possible_type_str = "";

	// If all sacrificed dice were generic
	if (all_generic) {
	    possible_type_str = "None"; // or "All" if you want full flexibility
	} else {
	    // Remove "None" from type_list if there are colored dice
	    for (var i = ds_list_size(type_list) - 1; i >= 0; i--) {
	        if (type_list[| i] == "None") {
	            ds_list_delete(type_list, i);
	        }
	    }

	    // Combine remaining types into a string
	    for (var t = 0; t < ds_list_size(type_list); t++) {
	        if (possible_type_str != "") possible_type_str += " ";
	        possible_type_str += type_list[| t];
	    }
	}

    // --- Determine the slot's starting action type ---
	// Find the first non-generic (non-"None") die in the sacrifice list
	var starting_action_type = "None";
	for (var j = 0; j < ds_list_size(global.sacrifice_list); j++) {
	    var listed_die = global.sacrifice_list[| j];
	    if (listed_die.action_type != "None") {
	        starting_action_type = listed_die.action_type;
	        break; // stop at the first non-"None"
	    }
	}

	// --- Create the new slot ---
	var new_slot = {
	    dice_list: ds_list_create(),
	    current_action_type: starting_action_type,
	    possible_type: possible_type_str,
		bonus_amount: 0,						// bonus dice, on top of rolled dice - 1d4 + 2 for example
		buffed: 0,								// Whether or not this slot is buffed and if so, for how many turns, this decreases by 1 at the end of each round
		pre_buff_amount: 0						// Used to keep track of bonus_amount before we get buffed
	};


    // Add sacrificed dice as base copies
    for (var j = 0; j < ds_list_size(global.sacrifice_list); j++) {
        var src = global.sacrifice_list[| j];
		var _perm = "base";
		
		// "none" dice cannot be permanent
		if (global.sacrifice_list[| j].action_type == "None") _perm = "temporary";
		
        var base_copy = clone_die(src, _perm);
        ds_list_add(new_slot.dice_list, base_copy);
    }

    ds_list_add(action_queue, new_slot);
    var slot = ds_list_size(action_queue) + 1;
	sacrificies_til_new_action_tile = global.fib_lookup[slot];

    ds_list_destroy(type_list);
    ds_list_clear(global.sacrifice_list);
	//show_debug_message("New slot created");
	type_array = [];
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
    var highest_value = 0;
	var different = false;

    for (var i = 0; i < ds_list_size(_slot.dice_list); i++) {
        var die_struct = _slot.dice_list[| i];
		
		var dice_values = get_dice_output(die_struct, _num, true);
		
		low += dice_values.min_roll + dice_values.keepsake_dice_bonus_amount;
		high += dice_values.max_roll + dice_values.keepsake_dice_bonus_amount;
		
		if (die_struct.action_type != "None!") { 
			total_amount += die_struct.dice_amount;
		}
		if (i > 0 && highest_value != die_struct.dice_value) different = true; // set to true if there are different types
        highest_value = max(highest_value, die_struct.dice_value);
    }

    return {
        low_roll: low + _slot.bonus_amount, // used for displaying the minimum roll of this slot
        high_roll: high + _slot.bonus_amount, // used for displaying the maximum roll of this slot
        amount: total_amount, // used for displaying the number of dice in this slot
        value: highest_value, // used for displaying the highest value dice in this slot -- we need to fix for 1d6 + 1d4, right now it shows as 2d6
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
    if (is_real(types) && ds_exists(types, ds_type_list)) {
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


/// @function can_place_dice_in_slot(_die_struct, _slot)
/// @returns {bool}
function can_place_dice_in_slot(_die_struct, _slot, _num)
{
    var die  = _die_struct;
    var slot = _slot;
    var stats = get_slot_stats(slot, _num);

    var is_queue_all  = (slot.possible_type == "All");
    var is_queue_none = (slot.possible_type == "None");
    var is_dice_none  = (die.possible_type == "None"); // note: die.struct.possible_type in apply_dice_to_slot()

    //-----------------------------------------
    // CASE 1: Dice has a specific colour/type
    //-----------------------------------------
    if (!is_dice_none) {
        if (is_queue_none) {
            // Empty slot: any colored die can go in
            return true;
        }
        else if (is_queue_all) {
            // Can't place colored dice into an All slot
            return false;
        }
        else if (string_pos(die.action_type, slot.possible_type) > 0) {
            // Same type — only if equal or stronger value
            return (die.dice_value >= stats.value);
        }
        else {
            // Different color entirely
            return false;
        }
    }

    //-----------------------------------------
    // CASE 2: Dice is generic (no color)
    //-----------------------------------------
    else {
        if (is_queue_all) {
            // Generic dice are allowed in All slots
            return true;
        }
        else if (!is_queue_none) {
            // Generic dice can be added to colored slots if equal or stronger
            return (die.dice_value >= stats.value);
        }
        else {
            // Empty slot but generic dice — invalid
            return false;
        }
    }
}

/// @function win_fight();
function win_fight() {
	// show enemy fading out
	enemy_alpha = lerp(enemy_alpha, 0.0, 0.1);
	enemy_intent_alpha = lerp(enemy_intent_alpha, 0, 0.1);
	
	if (enemy_alpha <= 0.2) {
			
		if (!show_rewards) {
			// Earn some credits, regardless of secondary rewards
			gain_coins(global.enemy_x, global.enemy_y, enemy.bounty);
				
			// pop up rewards screen - dice reward - offered 3 dice, choose 1 to keep and credits
			reward_dice_options = ds_list_create();
			reward_consumable_options = ds_list_create();
			
			generate_dice_rewards(reward_dice_options, global.master_dice_list, 3);
			generate_item_rewards(reward_consumable_options, global.master_item_list, 3);
			
			repeat(3) ds_list_add(reward_scale, 0.1);
			
			// Show dice every combat, show consumables at a 40% chance, gaining 10% chance every time they don't appear, losing 10% when they do.
			ds_list_add(reward_list, "dice");
			
			// Add consumables starting at a chance
			var con_chance = irandom_range(1, 100);
			if (con_chance <= oRunManager.show_consumables_chance) {
				ds_list_add(reward_list, "consumables");
				oRunManager.show_consumables_chance -= 30;
			} else {
				oRunManager.show_consumables_chance += 20;
			}
		}
		
		show_rewards = true;
		
		if (rewards_all_taken) {
			// wait for all rewards to be taken and/or button skipped and then fade transition back to the main room
			room_goto(rmMap);
		}
	}
}

/// @function get_action_name(_slot, _num);
function get_action_name(_slot, _num) {
	var stats = get_slot_stats(_slot, _num);
	var action_type = _slot.current_action_type;
	var total_amount = stats.amount;
	var highest_value = stats.value;
	
	var label = "";
	
	switch (action_type) {
		case "All":
			label = "No action";
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
		        case 6: label = "Gather intel"; break;
		        case 8: label = "Build a case"; break;
		        default: label = "Sleuth"; break;
		    }
		break;

		
		default:
			label = "No action";
	}
	
	return label;
}

function discard_dice_in_play() {
	with (oDice) {
		if (can_discard) {
		    // Cache everything before we destroy the dice
		    var start_x = x;
		    var start_y = y;
		    var d_struct = struct; // local reference to the die’s struct
		
			if (room == rmCombat) {
				trigger_die_effects_single(d_struct, "on_not_used", {});
			}

		    // Pick color by action type
		    var col = get_dice_color(d_struct.action_type);

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

/// @func combat_trigger_effects(_event, _ctx, _die_struct)
function combat_trigger_effects(_event, _ctx, _die_struct = undefined) {

    // 1) dice effects	
	if (_die_struct == undefined) {
		dice_trigger_effects(_event, _ctx);
	} else {
		trigger_die_effects_single(_die_struct, _event, _ctx)
	}

    // 2) keepsake effects
    runmanager_trigger_keepsakes(_event, _ctx);

    // 3) player debuffs
    trigger_debuff_list(global.player_debuffs, _event, _ctx);

    // 4) enemy debuffs
    trigger_debuff_list(global.enemy_debuffs, _event, _ctx);
}

function trigger_debuff_list(_list, _event, _ctx) {
	var list_size = ds_list_size(_list); 
	
    for (var i = list_size - 1; i >= 0 ; i--) {
        var inst = _list[| i];
        var debuff = inst.template; // <-- reference to original

        for (var e = 0; e < array_length(debuff.effects); e++) {
            var eff = debuff.effects[e];

            if (eff.trigger == _event && is_callable(eff.modify)) {
				
				// pass the amount through to the context
				_ctx.buff_amount = inst.amount;
				
				// run the event
                eff.modify(_ctx);
				
				// when it comes to triggering things on dice rolls, we need this to only decrease on the final dice roll
				if (eff.trigger != "on_roll_die") {
					//show_debug_message("Lowering debuff duration for non on_roll_die events");
					inst.remaining--;
				    if (inst.remaining <= 0) {
						if (inst.template == oRunManager.buff_intel) {
							// Update intel when this is destroyed
							oCombat.player_intel = inst.amount;
						}
				        ds_list_delete(_list, i);
				    }
				}
            }
        }
    }
}

function decrease_debuff_duration(_list, _event, _ctx) {
	show_debug_message("Debuff list size: "+string(ds_list_size(_list)));
	
	var list_size = ds_list_size(_list);
	
    for (var i = list_size - 1; i >= 0 ; i--) {
        var inst = _list[| i];
        var debuff = inst.template; // <-- reference to original

        for (var e = 0; e < array_length(debuff.effects); e++) {
            var eff = debuff.effects[e];

            if (eff.trigger == _event) {
				show_debug_message("Lowering debuff duration for on_roll_die events");
				// when it comes to triggering things on dice rolls, we need this to only decrease on the final dice roll
				inst.remaining--;
				
				if (inst.remaining <= 0) {
				    ds_list_delete(_list, i);
				}
            }
        }
    }
}

function eject_dice_in_slot(_slot, _slot_pos, _all) {
	
	var j = 0;
	while (j < ds_list_size(_slot.dice_list)) {
		var die = _slot.dice_list[| j];		
		die.rolled_value = -1;

		if (string_pos("temporary", die.permanence) > 0 || (string_has_keyword(die.description, "Loose")) || _all == true) {
					
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
			var start_x = _slot_pos.x + (_slot_pos.w / 2);
			var start_y = _slot_pos.y + (_slot_pos.h / 2);

			// Spawn particle
			var p = instance_create_layer(start_x, start_y, "Instances", oDiceParticle);
			p.target_x = oCombat.gui_w - 150;  // discard button target
			p.target_y = oCombat.gui_h - 130;
			p.color_main = die.color;

			// Clone the die struct so the particle has its own independent copy
			p.die_struct = clone_die(die, "");

			// Remove from slot
			ds_list_delete(_slot.dice_list, j);
					
			//// END OF HELPER
					
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