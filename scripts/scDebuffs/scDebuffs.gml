// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @function apply_buff(_target, _template, _duration, _amount, _remove_next_turn, _source, [_permanent])
function apply_buff(_target, _template, _duration, _amount, _remove_next_turn, _source, _permanent = false) {

    var inst = {
        template: clone_buff(_template),   // <-- reference, NOT a clone
        remaining: _duration,
		permanent: _permanent,
		amount: _amount,
		remove_next_turn: _remove_next_turn,
		source_info: _source
    };
	
	var _target_list;
	switch (_target) {
		case "player":
			_target_list = global.player_debuffs;
		break;
		default:
			_target_list = _target.debuffs;
	}
	
	
	// see if this debuff already exists and extend it if so
	if (ds_list_size(_target_list) > 0) {
		for (var d = 0; d < ds_list_size(_target_list); d++) {
			if (_target_list[| d].template._id == _template._id) {
				if (_template.stackable) {
					_target_list[| d].amount += _amount;
				} else {
					_target_list[| d].remaining += _duration;
				}
				return;
			}
		}
	}

    ds_list_add(_target_list, inst);
	
	var data = {
		newly_acquired_debuff: inst,
		target: _target
	};
					
	combat_trigger_effects("on_debuff_acquired", data);
}

/// @func clone_buff(_src)
function clone_buff(_src) {
	// Shallow clone of base-level fields
	var c = variable_clone(_src);

	// --- Deep copy effects array (you already do this) ---
	if (variable_struct_exists(c, "effects") && is_array(c.effects)) {
	    var new_arr = array_create(array_length(c.effects));
	    for (var i = 0; i < array_length(c.effects); i++) {
	        if (is_struct(c.effects[i])) {
	            new_arr[i] = variable_clone(c.effects[i]);
	        } else {
	            new_arr[i] = c.effects[i];
	        }
	    }
	    c.effects = new_arr;
	}

	return c;
}

function define_buffs_and_debuffs() {
	debuff_mock = {
	    _id: "mock",
		name: "Mock",
	    duration: 1,  // lasts 1 full turn
		amount: 1,
	    desc: "Attacks cannot roll higher than 1.",
	    icon_index: 0,
		debuff: true,
		color: c_red,
		stackable: false, // if false, increase duration when adding more, otherwise increase amount,
		remove_next_turn: true, // if true, remove at the end of the following turn, otherwise remove at the end of this turn
		removal_event: "on_round_end",
	    effects: [
	        {
	            trigger: "on_roll_die",
	            modify: function(_ctx) {
				    if (_ctx.max_roll > 1 && _ctx.action_type == "ATK") _ctx.max_roll = 1;
				}
	        }
	    ]
	};
	
	debuff_barnacle_bind = {
	    _id: "barnacle_bind",
		name: "Barnacle Bind",
	    duration: 1,  // lasts 1 full turn
		amount: 1,
	    desc: "Lowers the amount of playable dice this turn",
	    icon_index: 1,
		debuff: true,
		color: c_aqua,
		stackable: false, // if false, increase duration when adding more, otherwise increase amount
		remove_next_turn: true,
		removal_event: "on_round_end",
	    effects: [
	        {
	            trigger: "on_turn_start",
	            modify: function(_ctx) {
				    _ctx.bonus_dice = -1;
				}
	        }
	    ]
	};
	
	debuff_bind = {
	    _id: "bind",
		name: "Bind",
	    duration: 1,  // lasts 1 full turn
		amount: 1,
	    desc: "Prevents a random slot from firing this turn",
	    icon_index: 5,
		debuff: true,
		color: c_dkgray,
		stackable: false, // if false, increase duration when adding more, otherwise increase amount
		remove_next_turn: true,
		removal_event: "on_round_end",
	    effects: [
	        {
	            trigger: "on_turn_start",
	            modify: function(_ctx) {
				    oCombat.locked_slot = irandom( ds_list_size(oCombat.action_queue) - 1);
				}
	        }
	    ]
	};
	
	debuff_stunned = {
	    _id: "stunned",
		name: "Stunned",
	    duration: 1,  // lasts 1 full turn
		amount: 1,
	    desc: "Cannot act this turn.",
	    icon_index: 5,
		debuff: true,
		color: c_white,
		stackable: false, // if false, increase duration when adding more, otherwise increase amount
		remove_next_turn: false,
		removal_event: "on_round_end",
	    effects: [
	        {
	            trigger: "on_debuff_acquired",
	            modify: function(_ctx) {
					if (_ctx.owner != _ctx.target) return;
					
					if (_ctx.newly_acquired_debuff.template._id == "stunned") {
						show_debug_message("Adding stunned to enemy pool");
						var stunned = { dice_amount: 0, dice_value: 0, action_type: "NONE", bonus_amount: 0, move_name: "Stunned", use_trigger: "PRIORITY", weight: 100};
						ds_list_add(_ctx.target.data.moves, stunned);
						
						particle_emit( oCombat.room_enemies[| _ctx.owner_index].pos_x, oCombat.room_enemies[| _ctx.owner_index].pos_y, "ring", c_white, 55);
					
						_ctx.target.intent.move = stunned;
					}
				}
	        },
	        {
	            trigger: "on_enemy_turn_end",
	            modify: function(_ctx) {
					show_debug_message(string(_ctx.owner));
					show_debug_message(string(_ctx.target));
					if (_ctx.owner != _ctx.target) return;
					
					show_debug_message("Removing stunned from enemy pool");
					var last_move_index = ds_list_size(_ctx.owner.data.moves) - 1;
					ds_list_delete(_ctx.owner.data.moves, last_move_index);
				}
	        },
	    ]
	};
	
	debuff_rot = {
	    _id: "rot",
		name: "Rot",
	    duration: 1,  // lasts 1 full turn
		amount: 1,
	    desc: "Eject all base dice from this slot this turn",
	    icon_index: 5,
		debuff: true,
		color: c_green,
		stackable: false, // if false, increase duration when adding more, otherwise increase amount
		remove_next_turn: true,
		removal_event: "on_round_end",
	    effects: [
	        {
	            trigger: "on_turn_start",
	            modify: function(_ctx) {
				    oCombat.bound_slot = irandom( ds_list_size(oCombat.action_queue) - 1);
					
					var _slot_pos = oCombat.slot_positions[| oCombat.bound_slot];
					
					var start_x = _slot_pos.x + (_slot_pos.w / 2);
					var start_y = _slot_pos.y + (_slot_pos.h / 2);
					
					particle_emit(start_x, start_y, "burst", c_green);
				}
	        }
	    ]
	};
	
	debuff_overwhelm = {
	    _id: "overwhelm",
		name: "Overwhelm",
	    duration: 1,  // lasts 1 full turn
		amount: 1,
	    desc: "Lowers the players intel and forces the player to target this creature",
	    icon_index: 2,
		debuff: true,
		color: c_red,
		stackable: true, // if false, increase duration when adding more, otherwise increase amount
		remove_next_turn: false,
		removal_event: "on_turn_start",
	    effects: [
	        {
	            trigger: "on_turn_start",
	            modify: function(_ctx) {
				    oCombat.player_intel -= _ctx.debuff.amount;
					oCombat.enemy_target_index = _ctx.debuff.source_info.index; 
					
					particle_emit( oCombat.room_enemies[| oCombat.enemy_target_index].pos_x, oCombat.room_enemies[| oCombat.enemy_target_index].pos_y, "rise", global.color_intel, 42);
				}
	        }
	    ]
	};
	
	buff_shiny_scales = {
	    _id: "shiny_scales",
		name: "Shiny Scales",
	    duration: 1,  // lasts 1 full turn
		amount: 1,
	    desc: "Driftnet fish gains a coin to their attack roll every time they take take damage",
	    icon_index: 6,
		debuff: false,
		color: c_aqua,
		stackable: false, // if false, increase duration when adding more, otherwise increase amount
		remove_next_turn: true,
		removal_event: "on_round_end",
	    effects: [
	        {
	            trigger: "on_enemy_turn_end",
	            modify: function(_ctx) {
					if (_ctx.owner != _ctx.target) return;
					
					if (_ctx.owner.taken_damage_this_turn) {
						_ctx.owner.data.moves[| 1].dice_amount += 1; 
					}
					
					// Reset damage taken flag this turn
					_ctx.owner.taken_damage_this_turn = false;
				}
	        },
			{
			    trigger: "on_enemy_take_damage",
			    modify: function(_ctx) {
			        if (_ctx.owner != _ctx.target) return;
			        _ctx.owner.taken_damage_this_turn = true;
			    }
			}
	    ]
	};
	
	buff_spines = {
	    _id: "spines",
		name: "Spines",
	    duration: 1,  // lasts 1 full turn
		amount: 1,
	    desc: "Every time the Pufferfish takes damage it deals 1 back.",
	    icon_index: 7,
		debuff: false,
		color: make_color_rgb(100, 60, 0),
		stackable: false, // if false, increase duration when adding more, otherwise increase amount
		remove_next_turn: true,
		removal_event: "on_round_end",
	    effects: [
			{
	            trigger: "on_enemy_take_damage",
	            modify: function(_ctx) {
				    // Needed to make this damage work properly
					with (oCombat) {
						process_action("player", 0, 1, 0, _ctx.owner, -1, "ATK");
					}
				}
	        }
	    ]
	};
	
	buff_reserve = {
	    _id: "reserve",
		name: "Reserve",
	    duration: 1,  // lasts 1 full turn
		amount: 1,
	    desc: "Carry a dice to next turn.",
	    icon_index: 1,
		debuff: false,
		color: c_lime,
		stackable: true, // if false, increase duration when adding more, otherwise increase amount
		remove_next_turn: false,
		removal_event: "on_turn_start",
	    effects: [
	        {
	            trigger: "on_turn_start",
	            modify: function(_ctx) {
				    _ctx.bonus_dice = 1;
				}
	        }
	    ]
	};
	
	buff_intel = {
	    _id: "intel",
		name: "Queued intel",
	    duration: 1,  // lasts 1 full turn
		amount: 1,
	    desc: "Preparing intel for next turn.",
	    icon_index: 2,
		debuff: false,
		color: make_color_rgb(210, 210, 0),
		stackable: true, // if false, increase duration when adding more, otherwise increase amount
		remove_next_turn: false,
		removal_event: "on_turn_start",
	    effects: [
	        {
	            trigger: "on_turn_start",
	            modify: function(_ctx) {
					oCombat.player_intel += _ctx.debuff.amount;
				}
	        }
	    ]
	};
	
	buff_might = {
	    _id: "might",
		name: "Might",
	    duration: 1,  // lasts 1 full turn
		amount: 1,
	    desc: "Boost Attacks by 1 per point of Might",
	    icon_index: 3,
		debuff: false,
		color: c_orange,
		stackable: true, // if false, increase duration when adding more, otherwise increase amount
		remove_next_turn: false,
		removal_event: "on_round_end",
	    effects: [
	        {
	            trigger: "on_roll_die",
	            modify: function(_ctx) {
				    if (_ctx.action_type == "ATK") {
						if (_ctx.owner != _ctx.target) return;
						_ctx._d_amount += _ctx.stack_amount;
					}
				}
	        }
	    ]
	};
	
	buff_balance = {
	    _id: "balance",
		name: "Balance",
	    duration: 1,  // lasts 1 full turn
		amount: 1,
	    desc: "Boost Block by 1 per point of Balance",
	    icon_index: 4,
		debuff: false,
		color: c_blue,
		stackable: true, // if false, increase duration when adding more, otherwise increase amount
		remove_next_turn: false,
		removal_event: "on_round_end",
	    effects: [
	        {
	            trigger: "on_roll_die",
	            modify: function(_ctx) {
					if (_ctx.owner != _ctx.target) return;
				    if (_ctx.action_type == "BLK") _ctx._d_amount += _ctx.stack_amount;
				}
	        },
	    ]
	};
	
	passive_turtle_shell = {
	    _id: "turtle_shell",
		name: "Turtle Shell",
	    duration: 1,  // lasts 1 full turn
		amount: 0,
	    desc: "Doesn't lose block between turns",
	    icon_index: 8,
		debuff: false,
		color: make_colour_rgb(40, 150, 60),
		stackable: false, // if false, increase duration when adding more, otherwise increase amount
		remove_next_turn: false,
		removal_event: "on_round_end",
	    effects: [
	        {
	            trigger: "on_enemy_turn_end",
	            modify: function(_ctx) {
					_ctx.owner.keep_block_between_turns = true;
				}
	        }
	    ]
	};
	
	passive_conch_layers = {
		_id: "conch_layers",
		name: "Conch Layer",
	    duration: 3,  // lasts 1 full turn
		amount: 10,
	    desc: "Has 3 protective layers that reduce flat damage by 2 per hit. Dealing 10/15/20 damage in total will break a layer, causing the Conch to be stunned.",
	    icon_index: 8,
		debuff: false,
		color: make_colour_rgb(60, 180, 240),
		stackable: true, // if false, increase duration when adding more, otherwise increase amount
		remove_next_turn: false,
		removal_event: "on_round_end",
	    effects: [
	        {
				trigger: "before_enemy_take_damage",
	            modify: function(_ctx) {
					_ctx.amount -= 2;
				}
	        },
			{
				state: {
					layers_broken: 0,
				},
	            trigger: "on_enemy_take_damage",
	            modify: function(_ctx) {
					_ctx.debuff.amount -= _ctx.amount;
					
					if (_ctx.debuff.amount <= 0) {
						apply_buff(_ctx.target, oRunManager.debuff_stunned, 1, 1, oRunManager.debuff_stunned.remove_next_turn, { source: "player", index: -1 }, false);
						self.state.layers_broken += 1;
						_ctx.debuff.remaining -= 1;
						_ctx.debuff.amount = ((self.state.layers_broken * 5) + 10);
					}
				}
	        },
			
	    ]
	};
	
	passive_heartache = {
	    _id: "heartache",
		name: "Heart Ache",
	    duration: 1,  // lasts 1 full turn
		amount: 0,
	    desc: "When this enemy dies, its partner is rallied in heartache.",
	    icon_index: 9,
		debuff: false,
		color: make_colour_rgb(160, 50, 30),
		stackable: false, // if false, increase duration when adding more, otherwise increase amount
		remove_next_turn: false,
		removal_event: "on_round_end",
	    effects: [
	        {
	            trigger: "on_enemy_death",
	            modify: function(_ctx) {
					if (oCombat.enemies_left_this_combat != 0) {
						for (var i = 0; i < ds_list_size(oCombat.room_enemies); i++) {
							if (oCombat.room_enemies[| i] != _ctx.target) {
								show_debug_message("Adding move to enemy pool");
								var vengeance = { dice_amount: 2, dice_value: 2, action_type: "BLK/ATK", bonus_amount: 6, move_name: "Vengeance", use_trigger: "PRIORITY", weight: 100 };
								
								ds_list_add(oCombat.room_enemies[| i].data.moves, vengeance);
							}
						}
					}
				}
	        }
	    ]
	};
}