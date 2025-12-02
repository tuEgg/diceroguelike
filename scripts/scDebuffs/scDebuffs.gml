// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @function apply_buff(_target_list, _template, _duration, _amount)
function apply_buff(_target_list, _template, _duration, _amount) {

    var inst = {
        template: _template,   // <-- reference, NOT a clone
        remaining: _duration,
		amount: _amount
    };
	
	// see if this debuff already exists and extend it if so
	if (ds_list_size(_target_list) > 0) {
		for (var d = 0; d < ds_list_size(_target_list); d++) {
			if (_target_list[| d].template == _template) {
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
}

function define_buffs_and_debuffs() {
	debuff_mock = {
	    _id: "mock",
		name: "Mock",
	    duration: 1,  // lasts 1 full turn
	    desc: "Attacks cannot roll higher than 2.",
	    icon_index: 0,
		debuff: true,
		color: c_red,
		stackable: false, // if false, increase duration when adding more, otherwise increase amount
	    effects: [
	        {
	            trigger: "on_roll_die",
	            modify: function(_ctx) {
				    if (_ctx.max_roll > 2 && _ctx.action_type == "ATK") _ctx.max_roll = 2;
				}
	        }
	    ]
	};
	
	debuff_bind = {
	    _id: "barnacle_bind",
		name: "Barnacle Bind",
	    duration: 1,  // lasts 1 full turn
	    desc: "1 less dice next turn",
	    icon_index: 1,
		debuff: true,
		color: c_aqua,
		stackable: false, // if false, increase duration when adding more, otherwise increase amount
	    effects: [
	        {
	            trigger: "on_turn_start",
	            modify: function(_ctx) {
				    _ctx.bonus_dice = -1;
				}
	        }
	    ]
	};
	
	buff_reserve = {
	    _id: "reserve",
		name: "Reserve",
	    duration: 1,  // lasts 1 full turn
	    desc: "Carry a dice to next turn.",
	    icon_index: 1,
		debuff: false,
		color: c_lime,
		stackable: true, // if false, increase duration when adding more, otherwise increase amount
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
	    desc: "Preparing intel for next turn.",
	    icon_index: 2,
		debuff: false,
		color: c_white,
		stackable: true, // if false, increase duration when adding more, otherwise increase amount
	    effects: [
	        {
	            trigger: "on_turn_start",
	            modify: function(_ctx) {
				}
	        }
	    ]
	};
	
	buff_might = {
	    _id: "might",
		name: "Might",
	    duration: 1,  // lasts 1 full turn
	    desc: "Boost Attacks by 1 per point of Might",
	    icon_index: 3,
		debuff: false,
		color: c_white,
		stackable: true, // if false, increase duration when adding more, otherwise increase amount
	    effects: [
	        {
	            trigger: "on_roll_die",
	            modify: function(_ctx) {
				    if (_ctx.action_type == "ATK") _ctx._d_amount += _ctx.buff_amount;
				}
	        }
	    ]
	};
	
	buff_balance = {
	    _id: "balance",
		name: "Balance",
	    duration: 1,  // lasts 1 full turn
	    desc: "Boost Block by 1 per point of Balance",
	    icon_index: 4,
		debuff: false,
		color: c_white,
		stackable: true, // if false, increase duration when adding more, otherwise increase amount
	    effects: [
	        {
	            trigger: "on_roll_die",
	            modify: function(_ctx) {
				    if (_ctx.action_type == "BLK") _ctx._d_amount += _ctx.buff_amount;
				}
	        }
	    ]
	};
}