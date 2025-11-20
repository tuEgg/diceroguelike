// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function deal_single_die() {
    // --- Reshuffle if empty ---
    if (ds_list_size(global.dice_bag) == 0) {
        if (ds_list_size(global.discard_pile) > 0) {
            show_debug_message("Dice bag empty — reshuffling discard pile!");
            for (var i = 0; i < ds_list_size(global.discard_pile); i++) {
                var discard_die = global.discard_pile[| i];
                var die_copy = clone_die(discard_die, "temporary");
                ds_list_add(global.dice_bag, die_copy);
            }
            ds_list_clear(global.discard_pile);
        } else {
            show_debug_message("No dice left to deal — GAME OVER.");
            game_end();
            return;
        }
    }

    if (ds_list_size(global.dice_bag) == 0) {
        show_debug_message("No dice available even after reshuffle — GAME OVER.");
        game_end();
        return;
    }

    // --- Draw one die ---
	var trigger_data = {
		favourite: false,	
	};
	
	var die_struct = undefined;
	var index = 0;
		
	// Trigger on before dealt effects for every dice in the bag
	for (var d = 0; d < ds_list_size(global.dice_bag); d++) {
		trigger_die_effects_single(global.dice_bag[| d], "before_dice_dealt", trigger_data);
		// only check for favourites on first turn
		if (first_turn) {
			if (trigger_data.favourite == true) {
				die_struct = clone_die(global.dice_bag[| d], "");
				index = d;
				trigger_data.favourite = false;
			}
		}
	}
	
	// if we haven't set die_struct
	if (die_struct == undefined) {
	    index = irandom(ds_list_size(global.dice_bag) - 1);
	    var bag_die = global.dice_bag[| index];
	    die_struct = clone_die(bag_die, "");
	}
	
	// Trigger on dice dealt effects
	trigger_die_effects_single(die_struct, "on_dice_dealt", trigger_data);

    // Spawn instance
    var die_inst = instance_create_layer(200, room_height - 150, "Instances", oDice);
    die_inst.struct = die_struct;
    die_inst.action_type = die_struct.action_type;
    die_inst.dice_amount = die_struct.dice_amount;
    die_inst.dice_value  = die_struct.dice_value;
	die_inst.possible_type = die_struct.possible_type;

    var target = generate_valid_targets(1, 100) [0];
    die_inst.target_x = target[0];
    die_inst.target_y = target[1];

    // Remove from bag
    ds_list_delete(global.dice_bag, index);
}

function generate_dice_bag() {
	
	global.bag_size = 10;
	
	/// --- Ensure dice lists exist & are empty ---
	global.dice_bag = ds_list_create();
	global.discard_pile = ds_list_create();
	global.sacrifice_list = ds_list_create();
	global.sacrifice_history = ds_list_create();
	global.master_dice_list = ds_list_create(); // used to track 1 instance of each dice type, for offering random rewards

	// Define dice structs
	global.dice_all = make_die_struct(1, 4,"None", "All", "", "Multicolor die", "Counts as anything");
	global.dice_d4_none = make_die_struct(1, 4,"None", "None", "", "Generic die", "Upgrades slots 1d4");
	//ds_list_add(global.master_dice_list, global.dice_d4_none);
	global.dice_d6_atk = make_die_struct(1, 6,"ATK", "ATK", "", "Attack", "Deals 1d6 damage");
	ds_list_add(global.master_dice_list, global.dice_d6_atk);
	global.dice_d4_atk = make_die_struct(1, 4,"ATK", "ATK", "", "Attack", "Deals 1d4 damage");
	//ds_list_add(global.master_dice_list, global.dice_d4_atk);
	global.dice_d6_blk = make_die_struct(1, 6,"BLK", "BLK", "", "Block", "Blocks 1d6 damage");
	ds_list_add(global.master_dice_list, global.dice_d6_blk);
	global.dice_d4_blk = make_die_struct(1, 4,"BLK", "BLK", "", "Block", "Blocks 1d4 damage");
	//ds_list_add(global.master_dice_list, global.dice_d4_blk);
	global.dice_d4_heal = make_die_struct(1, 4,"HEAL", "HEAL", "", "Heal", "Heals 1d4 damage");
	ds_list_add(global.master_dice_list, global.dice_d4_heal);
	
	// Anchor Die: Gain +3 block if not used
	global.die_anchor = make_die_struct(
	    1, 6, "BLK", "BLK", "", "Anchor die",
	    "Stowaway: +3 block if not used.",
	    [
	        {
	            trigger: "on_not_used",
	            modify: function(_context) {
	                oCombat.player_block_amount += 3;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, global.die_anchor);
	
	// Anchor Die: Gain +3 block if not used
	global.die_slipstream = make_die_struct(
	    1, 6, "BLK", "BLK", "", "Slipstream die",
	    "Stowaway: Play 1 extra dice next turn.",
	    [
	        {
	            trigger: "on_not_used",
	            modify: function(_context) {
	                apply_buff(oCombat.player_debuffs, oRunManager.buff_reserve, 1);
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, global.die_slipstream);
	
	// Anchor Die: Gain +3 block if not used
	global.die_defensive = make_die_struct(
	    1, 2, "HEAL", "HEAL BLK", "", "Defensive coin",
	    "Coin. Favourite. Multitype: Can create HEAL and BLK slots.",
	    [
	        {
	            trigger: "before_dice_dealt",
	            modify: function(_context) {
	                _context.favourite = true;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, global.die_defensive);
	
	// Anchor Die: Gain +3 block if not used
	global.die_tidebreaker = make_die_struct(
	    1, 6, "ATK", "ATK", "", "Tidebreaker die",
	    "Followthrough: If previous slot was BLK, deal +2 damage.",
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					if (_context.previous_slot_action_type == "BLK" && _context.action_type == "ATK") {
	                    _context._d_amount += 2;
	                }
	            }
	        }
	    ],
		"loaded"
	);
	ds_list_add(global.master_dice_list, global.die_tidebreaker);
	
	// Anchor Die: Gain +3 block if not used
	global.die_pretty_penny = make_die_struct(
	    1, 2, "ATK", "ATK", "", "Pretty penny",
	    "Coin. Followthrough: If previous slot was HEAL, +1 bonus to this coin for the number of dice in this slot.",
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					if (_context.previous_slot_action_type == "HEAL") {
	                    _context._d_amount += ds_list_size(_context._slot.dice_list);
	                }
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, global.die_pretty_penny);
	

	// Add to bag
	repeat(3)		{ ds_list_add(global.dice_bag, global.dice_d4_atk); }
	repeat(3)		{ ds_list_add(global.dice_bag, global.dice_d4_blk); }
	repeat(0)		{ ds_list_add(global.dice_bag, global.die_defensive); }
	repeat(0)		{ ds_list_add(global.dice_bag, global.die_pretty_penny); }
	
	do { ds_list_add(global.dice_bag, global.dice_d4_none); }
	until (ds_list_size(global.dice_bag) == global.bag_size);
}

/// generate_valid_targets(num_dice, min_dist)
/// returns array of [x, y] positions spaced at least min_dist apart

function generate_valid_targets(_num, _min_dist) {
    var positions = [];
    var tries, xx, yy, valid;

    repeat (_num) {
        tries = 0;
        repeat (200) { // limit retries per dice target
            xx = random_range(global.dice_safe_area_x1, global.dice_safe_area_x2);
            yy = random_range(global.dice_safe_area_y1, global.dice_safe_area_y2);

            valid = true;
            for (var j = 0; j < array_length(positions); j++) {
                if (point_distance(positions[j][0], positions[j][1], xx, yy) < _min_dist) {
                    valid = false;
                    break;
                }
            }

            if (valid) break;
            tries++;
        }

        // fallback if no good spot found after 200 tries
        if (!valid) {
            xx = random_range(global.dice_safe_area_x1, global.dice_safe_area_x2);
            yy = random_range(global.dice_safe_area_y1, global.dice_safe_area_y2);
        }

        array_push(positions, [xx, yy]);
    }

    return positions;
}

/// @func make_die_struct(_amount, _value, _action, _poss, _perm, _name, _desc, _effects, _distribution)
/// @desc Always returns a new independent dice struct.
function make_die_struct(_amount, _value, _action, _poss, _perm, _name, _desc, _effects = [], _distribution = "") {
	var _col = c_white;
	switch (_action) {
		case "ATK":
		_col = c_red;
		break;
		case "BLK":
		_col = c_aqua;
		break;
		case "HEAL":
		_col = c_lime;
		break;
	}
    return {
        dice_amount: _amount,			// e.g. 1 for 1dX
        dice_value: _value,				// e.g. 6 for Xd6
        action_type: _action,			// "ATK", "BLK", "HEAL", "X"
        possible_type: _poss,			// or "All"/"None"
        permanence: _perm,				// "base" or "temporary"
		color: _col,
		name: _name,
		description: _desc,
		rolled_value: -1,
		effects: _effects,
		distribution: _distribution,
    };
}

/// @func clone_die(_die_struct, _perm)
function clone_die(_die_struct, _perm)
{
    var copy = variable_clone(_die_struct);
    copy.permanence = _perm;
    return copy;
}

/// @func get_dice_name(_die)
function get_dice_name(_die) {
	var amount = _die.dice_amount;
	var value = _die.dice_value;
	var type = _die.action_type;
	
	return string(amount) + "d" + string(value) + " " + string(type);
}

/// @func get_dice_name_and_bonus(_die, _bonus_amount)
function get_dice_name_and_bonus(_die, _bonus_amount) {
	var amount = _die.dice_amount;
	var value = _die.dice_value;
	var type = _die.action_type;
	
	var _bonus = "";
	switch (sign(_bonus_amount)) {
		case 1:
		_bonus = "+" + string(_bonus_amount);
		break;
		case -1:
		_bonus = string(_bonus_amount);
		break;
	}
	
	return string(amount) + "d" + string(value) +  _bonus + " " + string(type);
}

/// @func get_dice_output(_die, _slot_num)
/// @desc returns the minimum and maximum value of the dice based on ALL keepsakes, dice bonuses, slot bonuses etc.
/// @param _die	The die struct to be calculated from
/// @param _slot_num	The slot number this dice is in
function get_dice_output(_die, _slot_num) {
	
	var prev_slot_type = "";
	var slot = undefined;
	var action = "";
	
	if (_slot_num == undefined) {
		
	} else {
		if (_slot_num > 0) {
			prev_slot_type = oCombat.action_queue[| _slot_num-1].current_action_type;
		}
		slot = oCombat.action_queue[| _slot_num];
		action = oCombat.action_queue[| _slot_num].current_action_type;
	}
			
	// Pass roll data into the keepsake/dice effects
	var roll_data = {
		previous_slot_action_type: prev_slot_type,
		action_type: action,
		min_roll: 1,
		max_roll: _die.dice_value,
		_d_amount: 0,
		_slot: slot
	};

	// Let keepsakes/dice adjust roll range
	combat_trigger_effects("on_roll_die", roll_data, _die);

	// Pass effected data back into our roll.
	var _bonus_from_keepsakes = roll_data._d_amount;
	var _min = roll_data.min_roll;
	var _max = roll_data.max_roll;
			
	return {
		min_roll: _min,
		max_roll: _max,
		keepsake_dice_bonus_amount: _bonus_from_keepsakes
	};
	
}

function dice_trigger_effects(_event, _data) {
    // Iterate through all dice currently in play
    for (var s = 0; s < ds_list_size(action_queue); s++) {
        var slot = action_queue[| s];
        for (var d = 0; d < ds_list_size(slot.dice_list); d++) {
            var die = slot.dice_list[| d];
            if (is_undefined(die.effects)) continue;

            // Some dice have one effect, others multiple
            if (is_array(die.effects)) {
                for (var e = 0; e < array_length(die.effects); e++) {
                    var eff = die.effects[e];
                    if (eff.trigger == _event && is_callable(eff.modify)) {
                        eff.modify(_data);
                    }
                }
            } else {
                var eff = die.effects;
                if (eff.trigger == _event && is_callable(eff.modify)) {
                    eff.modify(_data);
                }
            }
        }
    }
}

function trigger_die_effects_single(_die_struct, _event, _data) {
    if (is_undefined(_die_struct.effects)) return;

    if (is_array(_die_struct.effects)) {
        for (var e = 0; e < array_length(_die_struct.effects); e++) {
            var eff = _die_struct.effects[e];
            if (eff.trigger == _event && is_callable(eff.modify)) {
                eff.modify(_data);
            }
        }
    } else {
        var eff = _die_struct.effects;
        if (eff.trigger == _event && is_callable(eff.modify)) {
            eff.modify(_data);
        }
    }
}

function draw_dice_keywords(_die_struct, _x, _y, _scale) {
    var desc = _die_struct.description;
    if (is_undefined(desc)) return;

    var found = get_keywords_in_string(desc);

    if (array_length(found) == 0) return;

    var icon_x = _x - 4;
    var icon_y = _y + 3;
    var icon_spacing = 35 * _scale;
	
	icon_x -= (array_length(found)-1) * icon_spacing / 2;

    for (var i = 0; i < array_length(found); i++) {
        var key = found[i];
        var data = global.keywords[$ key];

        if (!is_undefined(data.index)) {
            draw_sprite_ext(sKeywordIcons, data.index, icon_x, icon_y, _scale, _scale, 0, c_white, 1);
        }

        icon_x += icon_spacing;
    }
}

function draw_dice_distribution(_die, _x, _y) {
	var dice_output = get_dice_output(_die, undefined);
			
	var _min_roll = dice_output.min_roll;
	var _max_roll = dice_output.max_roll;
	
	var distribution_array = [];
	var xx = _x;
	var yy = _y;
	
	switch (_die.distribution) {
		case "":		
		// by default each array is [1, 1, 1, 1] for a d4 for example
		for (var d = _min_roll; d <= _max_roll; d++) {
			array_push(distribution_array, 1);
		}
		break;
				
		case "weighted":		
		// by default each array is [3, 4, 5, 6] for a d4 for example
		for (var d = _min_roll; d <= _max_roll; d++) {
			array_push(distribution_array, _max_roll - 2 + d);
		}
		break;
				
		case "loaded":		
		// by default each array is [1, 2, 3, 4] for a d4 for example
		for (var d = _min_roll; d <= _max_roll; d++) {
			array_push(distribution_array, d);
		}
		break;
	}
	
	var max_size = 0;
	var curr_size = 0;
	for (var i = 0; i < array_length(distribution_array); i++) {
		if (curr_size < distribution_array[i]) {
			max_size = distribution_array[i];
			curr_size = distribution_array[i];
		}
	}
	
	for (var i = 0; i < array_length(distribution_array); i++) {
		var bar_height = distribution_array[i]/max_size;
		draw_sprite_ext(sSmallBar, 0, xx + 50, yy + 7, 1, bar_height + 0.2, 0, c_white, 1.0);
		xx += sprite_get_width(sSmallBar);
	}
}