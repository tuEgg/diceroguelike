// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @function apply_buff(_target, _template, _duration, _amount, _remove_next_turn, _source, [_permanent])
function apply_buff(_target, _template, _duration, _amount, _remove_next_turn, _source, _permanent = false) {
	switch (_template._id) {
		case "bind": case "barnacle_bind": sfx_play(soRope, AUDIO_GROUP.SFX, 0.05, 0.9); break;
		case "spines": sfx_play(soThorns, AUDIO_GROUP.SFX, 0.05, 0.9); break;
	}

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
			var _existing = _target_list[| d];

			// Permanent and temporary versions of the same buff are kept apart, so one can never change how long the other lasts
			if (_existing.template._id != _template._id || _existing.permanent != _permanent) continue;

			if (_template.stackable) {
				// Stacks only merge when they will run out together, otherwise the new stack is tracked on its own
				if (_existing.remove_next_turn != _remove_next_turn) continue;

				_existing.amount += _amount;
			} else {
				_existing.remaining += _duration;
			}
			return;
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
	    desc: "Attack dice roll 1.",
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
	    desc: "Fewer plays this turn.",
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
				    _ctx.bonus_dice -= 1; // adjust, never overwrite, other effects change this too
				}
	        }
	    ]
	};
	
	debuff_bind = {
	    _id: "bind",
		name: "Bind",
	    duration: 1,  // lasts 1 full turn
		amount: 1,
	    desc: "A random slot doesn't act this turn.",
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
				    oCombat.locked_slot = SLOT_PICK_AT_RESOLVE; // picked when your turn ends (combat_pick_debuffed_slots): you start with one slot now
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
					
						enemy_set_intent(_ctx.target, stunned); // through the helper, so its shown numbers update too
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
	    desc: "Halves one slot's total this turn.",
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
				    oCombat.bound_slot = SLOT_PICK_AT_RESOLVE; // picked when your turn ends (combat_pick_debuffed_slots)
				}
	        }
	    ]
	};
	
	debuff_overwhelm = {
	    _id: "overwhelm",
		name: "Overwhelm",
	    duration: 1,  // lasts 1 full turn
		amount: 1,
	    desc: "Lowers your ink. Your target is locked on this enemy this turn.",
	    icon_index: 2,
		debuff: true,
		color: c_red,
		stackable: true, // if false, increase duration when adding more, otherwise increase amount
		remove_next_turn: true,		 // applied on the enemy's turn, it lasts through your next turn
		removal_event: "on_round_end",
	    effects: [
	        {
	            trigger: "on_turn_start",
	            modify: function(_ctx) {
				    oCombat.player_intel -= _ctx.debuff.amount;
					// find the enemy that cast it now: its old index goes stale once an enemy dies or flees (crash, 2026-11-22)
					var _src = _ctx.debuff.source_info.source;
					var _i = is_struct(_src) ? ds_list_find_index(oCombat.room_enemies, _src) : -1;
					if (_i == -1) return; // it's gone: nothing to lock onto
					oCombat.enemy_target_index = _i;
					oCombat.target_locked = true; // can't change target this turn

					particle_emit(_src.pos_x, _src.pos_y, "rise", global.color_intel, 42);
				}
	        }
	    ]
	};
	
	buff_shiny_scales = {
	    _id: "shiny_scales",
		name: "Shiny Scales",
	    duration: 1,  // lasts 1 full turn
		amount: 1,
	    desc: "Adds a Coin to its attack each time it takes damage.",
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
	    desc: "Deals 1 damage back when hit.",
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
	    desc: "Keep a die for next turn.",
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
				    _ctx.bonus_dice += _ctx.debuff.amount; // one extra die per stack, on top of other bonuses
				}
	        }
	    ]
	};
	
	buff_intel = {
	    _id: "intel",
		name: "Queued ink",
	    duration: 1,  // lasts 1 full turn
		amount: 1,
	    desc: "Ink carried into next turn.",
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
	
	// insight for each of the next 2 turns (Radar die). Its own buff so it stacks only with more of the same: merged into
	// "Queued insight" it would either cut the 2 turns to 1 or make the whole queue last 2 (Jared, 2026-11-20)
	buff_intel_lasting = {
	    _id: "intel_lasting",
		name: "Lasting ink",
	    duration: 2,
		amount: 1,
	    desc: "Gain ink at the start of each turn.",
	    icon_index: 2,
		debuff: false,
		color: make_color_rgb(230, 190, 40),
		stackable: true, // more of it adds to the amount (it all runs out together)
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
	    desc: "Attacks deal +1 per Might.",
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
						_ctx._d_amount += _ctx.debuff.amount;
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
	    desc: "Block gains +1 per Balance.",
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
				    if (_ctx.action_type == "BLK") _ctx._d_amount += _ctx.debuff.amount;
				}
	        },
	    ]
	};
	
	passive_turtle_shell = {
	    _id: "turtle_shell",
		name: "Turtle Shell",
	    duration: 1,  // lasts 1 full turn
		amount: 0,
	    desc: "Keeps its block between turns.",
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
	    desc: "3 layers: each hit deals 2 less damage. A layer breaks at 10, 15 and 20 total damage, stunning the Conch.",
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
	    desc: "When it dies, its partner takes revenge.",
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

	// the ones a player meets by name, explained wherever their name is written (glossary_terms, F137)
	global.status_glossary = [debuff_mock, debuff_barnacle_bind, debuff_bind, debuff_stunned, debuff_rot, debuff_overwhelm, buff_reserve, buff_might, buff_balance];
}

/// @func die_is_mocked(_die)
/// @desc You're Mocked and this die can attack: its attack can't roll above 1 (B133). Marked on the die in hand, and the
///       reroll hover warns that rerolling won't help.
function die_is_mocked(_die) {
	if (room != rmCombat || !is_struct(_die) || string_pos("ATK", string(_die.possible_type)) == 0) return false;
	if (!variable_global_exists("player_debuffs") || !ds_safe_exists(global.player_debuffs, ds_type_list)) return false;
	for (var d = 0; d < ds_list_size(global.player_debuffs); d++) {
		if (global.player_debuffs[| d].template._id == "mock") return true;
	}
	return false;
}

/// @func draw_mock_mark(_x, _y, _scale)
/// @desc A Mocked die's mark (B133): a small red ink tag reading "Mock", tilted like a stamp. Returns its hover box.
function draw_mock_mark(_x, _y, _scale = 1) {
	draw_set_font(ftDescriptions);
	var _w = string_width("Mock") + 14 * _scale, _h = 24 * _scale;
	draw_set_color(global.ui_col.ink);
	draw_roundrect_ext(_x - _w / 2 - 2, _y - _h / 2 - 2, _x + _w / 2 + 2, _y + _h / 2 + 2, 8, 8, false);
	draw_set_color(global.color_attack);
	draw_roundrect_ext(_x - _w / 2, _y - _h / 2, _x + _w / 2, _y + _h / 2, 7, 7, false);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(global.ui_col.paper_hi);
	draw_text(_x, _y, "Mock");
	draw_set_color(c_white);
	return { x1: _x - _w / 2, y1: _y - _h / 2, x2: _x + _w / 2, y2: _y + _h / 2 };
}

/// @func buff_tooltip_text(_inst)
/// @desc A buff or debuff's tooltip text: its description, then how long it lasts and its strength, only when they
///       mean something ("2 turns left", "Lasts all fight", "Strength 3").
function buff_tooltip_text(_inst) {
	var _desc = string(_inst.template.desc);
	if (string_char_at(_desc, string_length(_desc)) != ".") _desc += ".";
	var _bits = [];
	if (_inst.permanent) array_push(_bits, "Lasts all fight");
	else if (_inst.remaining == 1) array_push(_bits, "1 turn left");
	else if (_inst.remaining > 1) array_push(_bits, string(_inst.remaining) + " turns left");
	if (_inst.amount != 0) array_push(_bits, "Strength " + string(_inst.amount));
	if (array_length(_bits) == 0) return _desc;
	var _line = _bits[0];
	for (var i = 1; i < array_length(_bits); i++) _line += ", " + _bits[i];
	return _desc + " [subtext]" + _line + ".";
}
