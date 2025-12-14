// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @function apply_buff(_target_list, _template, _duration, _amount, _remove_next_turn, _source, [_permanent])
function apply_buff(_target_list, _template, _duration, _amount, _remove_next_turn, _source, _permanent = false) {

    var inst = {
        template: _template,   // <-- reference, NOT a clone
        remaining: _duration,
		permanent: _permanent,
		amount: _amount,
		remove_next_turn: _remove_next_turn,
		source_info: _source
    };
	
	// see if this debuff already exists and extend it if so
	if (ds_list_size(_target_list) > 0) {
		for (var d = 0; d < ds_list_size(_target_list); d++) {
			if (_target_list[| d].template == _template) {
				if (_template.stackable) {
					_target_list[| d].amount += _amount;
					_target_list[| d].remove_next_turn = true;
				} else {
					_target_list[| d].remaining += _duration;
				}
				return;
			}
		}
	}

    ds_list_add(_target_list, inst);
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
	    effects: [
	        {
	            trigger: "on_roll_die",
	            modify: function(_ctx) {
				    if (_ctx.max_roll > 1 && _ctx.action_type == "ATK") _ctx.max_roll = 1;
				}
	        },
			{
				trigger:"on_player_turn_end",
				modify: function() {
					// this exists purely to remove the buff at the end of the turn, rather than on roll die, MUST be added to every on_roll_die event
				}
			}
	    ]
	};
	
	debuff_bind = {
	    _id: "barnacle_bind",
		name: "Barnacle Bind",
	    duration: 1,  // lasts 1 full turn
		amount: 1,
	    desc: "Lowers the amount of playable dice this turn",
	    icon_index: 1,
		debuff: true,
		color: c_aqua,
		stackable: false, // if false, increase duration when adding more, otherwise increase amount
		remove_next_turn: false,
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
		remove_next_turn: false,
	    effects: [
	        {
	            trigger: "on_turn_start",
	            modify: function(_ctx) {
				    oCombat.locked_slot = irandom( ds_list_size(oCombat.action_queue) - 1);
				}
	        }
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
		remove_next_turn: false,
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
	    effects: [
	        {
	            trigger: "on_turn_start",
	            modify: function(_ctx) {
				    oCombat.player_intel -= _ctx.stack_amount;
					oCombat.enemy_target_index = _ctx.source_index; 
				}
	        }
	    ]
	};
	
	buff_shiny_scales = {
	    _id: "shiny_scales",
		name: "Shiny Scales",
	    duration: 1,  // lasts 1 full turn
		amount: 1,
	    desc: "Gains 1 more attack dice if it takes damage on its turn",
	    icon_index: 6,
		debuff: true,
		color: c_aqua,
		stackable: false, // if false, increase duration when adding more, otherwise increase amount
		remove_next_turn: true,
	    effects: [
	        {
	            trigger: "on_enemy_turn_end",
	            modify: function(_ctx) {
					show_debug_message("end of turn is triggering");
					show_debug_message("_ctx.owner.taken_damage_this_turn: " +string(_ctx.owner.taken_damage_this_turn) );
					
					if (_ctx.owner.taken_damage_this_turn) {
						show_debug_message("We took damage this turn");
						_ctx.owner.data.moves[| 1].dice_amount += 1; 
					}
					
					// Reset damage taken flag this turn
					_ctx.owner.taken_damage_this_turn = false;
				}
	        },
			{
	            trigger: "on_take_damage",
	            modify: function(_ctx) {
				    _ctx.target.taken_damage_this_turn = true;
					
					show_debug_message("We have taken damage");
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
	    effects: [
	        {
	            trigger: "on_turn_start",
	            modify: function(_ctx) {
					oCombat.player_intel += _ctx.stack_amount;
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
	    effects: [
	        {
	            trigger: "on_roll_die",
	            modify: function(_ctx) {
				    if (_ctx.action_type == "ATK") {
						_ctx._d_amount += _ctx.stack_amount;
					}
				}
	        },
			{
				trigger:"on_player_turn_end",
				modify: function() {
					// this exists purely to remove the buff at the end of the turn, rather than on roll die
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
	    effects: [
	        {
	            trigger: "on_roll_die",
	            modify: function(_ctx) {
				    if (_ctx.action_type == "BLK") _ctx._d_amount += _ctx.stack_amount;
				}
	        },
			{
				trigger:"on_player_turn_end",
				modify: function() {
					// this exists purely to remove the buff at the end of the turn, rather than on roll die
				}
			}
	    ]
	};
}