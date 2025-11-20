// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @function apply_buff(_target_list, _template, _duration)
function apply_buff(_target_list, _template, _duration) {

    var inst = {
        template: _template,   // <-- reference, NOT a clone
        remaining: _duration,
    };
	
	// see if this debuff already exists and extend it if so
	if (ds_list_size(_target_list) > 0) {
		for (var d = 0; d < ds_list_size(_target_list); d++) {
			if (_target_list[| d].template == _template) {
				_target_list[| d].remaining += _duration;
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
	    effects: [
	        {
	            trigger: "on_turn_start",
	            modify: function(_ctx) {
				    _ctx.bonus_dice = 1;
				}
	        }
	    ]
	};
}