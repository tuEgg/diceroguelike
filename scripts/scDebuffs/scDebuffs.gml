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
	
	
	// see if this buff already exists and merge into it (docs/design/buffs-plan.md, 2026-11-24). Permanent and temporary
	// copies are always kept apart, so one can never change how long the other lasts.
	var _kind = buff_kind(_template);
	if (ds_list_size(_target_list) > 0) {
		for (var d = 0; d < ds_list_size(_target_list); d++) {
			var _existing = _target_list[| d];
			if (_existing.template._id != _template._id || _existing.permanent != _permanent) continue;

			if (_kind == "amount") {
				// an amount buff just grows (Might +1 and Might +1 is Might +2); a temporary one only merges with another
				// that runs out at the same time, otherwise the newer one is its own icon
				// (the flag only decides when a temporary one expires: a permanent one never counts down, and START_TURN
				// resets the flag on every buff, so ignoring it is what lets Command keep stacking from turn 2)
				if (!_permanent && _existing.remove_next_turn != _remove_next_turn) continue;
				_existing.amount += _amount;
			} else {
				// an effect buff or debuff doesn't stack: Bind on a Bind lasts the longer of the two, and if the new one
				// should last through your next turn, so does the merged one (it used to add the durations)
				_existing.remaining = max(_existing.remaining, _duration);
				_existing.remove_next_turn = _existing.remove_next_turn || _remove_next_turn;
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
				    oCombat.locked_slot = combat_bind_pick(); // picked now and shown all turn, built or not (Jared, 2026-11-24)
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
				    oCombat.bound_slot = combat_bind_pick(); // picked now and shown all turn, as Bind (Jared, 2026-11-24)
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
	    desc: "Each hit deals as much less damage as it has layers left. A layer breaks at 10, 15 and 20 total damage, stunning the Conch.",
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
					// each hit loses as many points as there are layers left: 3, then 2, then 1 (2026-11-24; it was a flat 2)
					_ctx.amount = max(0, _ctx.amount - _ctx.debuff.remaining);
				}
	        },
			{
	            trigger: "on_enemy_take_damage",
	            modify: function(_ctx) {
					_ctx.debuff.amount -= _ctx.amount;
					
					if (_ctx.debuff.amount <= 0) {
						apply_buff(_ctx.target, oRunManager.debuff_stunned, 1, 1, oRunManager.debuff_stunned.remove_next_turn, { source: "player", index: -1 }, false);
						_ctx.debuff.remaining -= 1;
						if (_ctx.debuff.remaining <= 0) {
							// the last layer is gone: the shell goes. (It is a permanent buff, which the usual countdown
							// never removes, so it stayed on, still blunting hits and stunning, 2026-11-24.)
							var _at = ds_list_find_index(_ctx.target.debuffs, _ctx.debuff);
							if (_at != -1) ds_list_delete(_ctx.target.debuffs, _at);
						} else {
							_ctx.debuff.amount = 10 + 5 * (3 - _ctx.debuff.remaining); // the next layer: 15, then 20 (kept on the buff, not a struct shared between fights)
						}
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
	global.status_glossary = [debuff_mock, debuff_barnacle_bind, debuff_bind, debuff_stunned, debuff_rot, buff_reserve, buff_might, buff_balance];
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
	draw_set_font(font_tip());
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

/// @func buff_kind(_template)
/// @desc "amount" or "effect" (docs/design/buffs-plan.md). An amount buff is a number that stacks and has no turn counter
///       (Might, Balance, queued ink, kept dice): a permanent copy and a temporary one are separate icons, each with its
///       amount. An effect has no amount, doesn't stack, and shows the turns it has left (Bind, Rot, Mock, Stunned...).
function buff_kind(_template) {
	switch (_template._id) {
		case "might": case "balance": case "intel": case "reserve": return "amount";
	}
	return "effect";
}

/// @func buff_total(_list, _id)
/// @desc { total, permanent, temporary }: the amounts of one buff across a target's list.
function buff_total(_list, _id) {
	var _t = { total: 0, permanent: 0, temporary: 0 };
	for (var i = 0; i < ds_list_size(_list); i++) {
		var _b = _list[| i];
		if (_b.template._id != _id) continue;
		if (_b.permanent) _t.permanent += _b.amount; else _t.temporary += _b.amount;
		_t.total += _b.amount;
	}
	return _t;
}

/// @func buff_icon_text(_inst)
/// @desc { text, col }: what a buff's icon says (2026-11-24). Amount buffs: their amount, "+3" green or "-2" red. Effects:
///       the turns left, nothing when permanent (except a shell, which shows its layers).
function buff_icon_text(_inst) {
	if (buff_kind(_inst.template) == "amount") {
		if (_inst.amount == 0) return { text: "", col: c_white };
		return { text: ((_inst.amount > 0) ? "+" : "") + string(_inst.amount), col: (_inst.amount > 0) ? c_lime : c_red };
	}
	if (_inst.template._id == "conch_layers") return { text: string(max(0, _inst.remaining)), col: c_white }; // the layers left
	if (_inst.permanent || _inst.remaining <= 0) return { text: "", col: c_white };
	return { text: string(_inst.remaining), col: c_white };
}

/// @func buff_icon_draw(_x, _y, _inst, _list, _is_player)
/// @desc One buff or debuff icon with its number and hover tooltip, at its top left; returns its width. Used for the
///       player's row and for each enemy's (oCombat Draw GUI). A permanent one wears a brass ring.
function buff_icon_draw(_x, _y, _inst, _list, _is_player) {
	var _w = sprite_get_width(sDebuffIcon), _h = sprite_get_height(sDebuffIcon);
	var _cx = _x + _w / 2, _cy = _y + _h / 2;
	// ink coming: the inkwell, as you click for the ink view (Jared, 2026-11-22)
	if (_is_player && (_inst.template._id == "intel" || _inst.template._id == "intel_lasting")) draw_inkwell(_cx, _cy, 0.7, 1, false);
	else draw_sprite_ext(sDebuffIcon, _inst.template.icon_index, _cx, _cy, 1, 1, 0, _inst.template.color, 1.0);
	if (_inst.permanent) {
		draw_set_color(global.ui_col.brass);
		draw_set_alpha(0.9);
		draw_circle(_cx, _cy, _w * 0.56, true);
		draw_circle(_cx, _cy, _w * 0.56 + 1, true);
		draw_set_alpha(1);
		draw_set_color(c_white);
	}
	var _t = buff_icon_text(_inst);
	if (_t.text != "") {
		draw_set_font(ftDefault);
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_outline_text(_t.text, c_black, _t.col, 2, _x + _w, _y + _h / 1.2, 1, 1, 0);
	}
	if (mouse_hovering(_x, _y, _w, _h, false)) {
		queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _inst.template.name, buff_tooltip_text(_inst, _list), undefined, 0, undefined);
	}
	return _w;
}

/// @func buff_status_line(_name)
/// @desc What you currently have of a buff or debuff, for its glossary box: "" if nothing, else "\nYou have: ...".
function buff_status_line(_name) {
	if (!variable_global_exists("player_debuffs") || !ds_safe_exists(global.player_debuffs, ds_type_list)) return "";
	var _line = "";
	for (var i = 0; i < ds_list_size(global.player_debuffs); i++) {
		var _b = global.player_debuffs[| i];
		if (_b.template.name != _name) continue;
		if (buff_kind(_b.template) == "amount") {
			var _t = buff_total(global.player_debuffs, _b.template._id);
			_line = "\nYou have " + string(_t.total) + ((_t.permanent != 0 && _t.temporary != 0) ? " (" + string(_t.permanent) + " permanent, " + string(_t.temporary) + " this turn)." : ((_t.permanent != 0) ? ", all fight." : ", this turn only."));
		} else {
			_line = "\nYou have it" + ((_b.permanent || _b.remaining <= 0) ? ", all fight." : ((_b.remaining == 1) ? ": 1 turn left." : ": " + string(_b.remaining) + " turns left."));
		}
		break;
	}
	return _line;
}

/// @func buff_tooltip_text(_inst, [_list])
/// @desc A buff or debuff's tooltip text: its description, then (2026-11-24) for an amount buff its amount, whether it
///       lasts all fight or this turn only and, with _list, the total across its permanent and temporary copies; for an
///       effect the turns it has left.
function buff_tooltip_text(_inst, _list = undefined) {
	var _desc = string(_inst.template.desc);
	if (string_char_at(_desc, string_length(_desc)) != ".") _desc += ".";
	var _bits = [];
	if (buff_kind(_inst.template) == "amount") {
		if (_inst.amount != 0) array_push(_bits, ((_inst.amount > 0) ? "+" : "") + string(_inst.amount));
		array_push(_bits, _inst.permanent ? "Lasts all fight" : "This turn only");
		if (ds_safe_exists(_list, ds_type_list)) {
			var _t = buff_total(_list, _inst.template._id);
			if (_t.permanent != 0 && _t.temporary != 0) array_push(_bits, "Total " + string(_t.total) + ": " + string(_t.permanent) + " permanent, " + string(_t.temporary) + " this turn");
		}
	} else {
		if (_inst.template._id == "conch_layers") array_push(_bits, string(max(0, _inst.remaining)) + ((_inst.remaining == 1) ? " layer left" : " layers left"));
		else if (_inst.permanent) array_push(_bits, "Lasts all fight");
		else if (_inst.remaining == 1) array_push(_bits, "1 turn left");
		else if (_inst.remaining > 1) array_push(_bits, string(_inst.remaining) + " turns left");
	}
	if (array_length(_bits) == 0) return _desc;
	var _line = _bits[0];
	for (var i = 1; i < array_length(_bits); i++) _line += ", " + _bits[i];
	return _desc + " [subtext]" + _line + ".";
}
