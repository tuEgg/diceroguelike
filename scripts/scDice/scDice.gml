// Script assets have changed for v2.3.0 see
// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @func deal_single_die( _can_discard_this_turn )
function deal_single_die( _can_discard_this_turn = true) {
	combat_seed_next(); // which die comes and what it rolls repeat on a reload (a no-op outside a fight)
	// The F1 debug menu can ask for a specific die to be dealt next
	var _debug_die = debug_take_next_die();
	
	if (room == rmCombat) {
		if (ds_list_size(global.dice_bag) == 1) {
			combat_trigger_effects("on_bag_empty", {});
		}
	}
		
	// --- Reshuffle if empty ---
	if (_debug_die == undefined && ds_list_size(global.dice_bag) == 0) {
			
	    // outside a fight the discard pile has been freed (oCombat CleanUp), so only a live one can be reshuffled (B109)
	    if (ds_safe_exists(global.discard_pile, ds_type_list) && ds_list_size(global.discard_pile) > 0) {
	        //show_debug_message("Dice bag empty — reshuffling discard pile!");
	        // in a fight, you see it happen: the spent dice fly out of the discard pile and back into the bag
	        if (room == rmCombat) combat_shuffle_effect(ds_list_size(global.discard_pile));
	        for (var i = 0; i < ds_list_size(global.discard_pile); i++) {
	            var discard_die = global.discard_pile[| i];
	            var die_copy = clone_die(discard_die, "");
	            ds_list_add(global.dice_bag, die_copy);
	        }
	        ds_list_clear(global.discard_pile);
	    } else {
	        //show_debug_message("No dice left to deal, stopping dealing.");
			if (room == rmCombat) {
				oCombat.dice_to_deal = 0;
			} else {
				oRunManager.dice_to_deal = 0;
			}
	        return;
			
	    }
	}

    // --- Draw one die ---
	var trigger_data = {
		favourite: false,
	};
	
	var die_struct = undefined;
	var index = 0;
		
	// Favourites only jump the queue on the first turn of a fight (and always at the workbench)
	var _first_turn = (room == rmCombat && instance_exists(oCombat)) ? (oCombat.turn_count <= 1) : true;
	
	// Check for favourites and deal them first
	for (var d = 0; d < ds_list_size(global.dice_bag); d++) {
		// only check for favourites on first turn
		if (_first_turn) {
			var fave = die_has_keyword(global.dice_bag[| d], "Favourite");
			if (fave) {
				die_struct = clone_die(global.dice_bag[| d], "");
				index = d;
			}
		}
	}
	
	// the guided first fight deals a set hand, taken from the bag so the bag stays right
	var _tut = (room == rmCombat) ? tutorial_next_hand_type() : undefined;
	if (is_struct(_tut) && _debug_die == undefined) {
		for (var d = 0; d < ds_list_size(global.dice_bag); d++) {
			if (global.dice_bag[| d].action_type == _tut.type) {
				die_struct = clone_die(global.dice_bag[| d], "");
				index = d;
				// it lands on the face the step needs (die_roll_faces uses forced_roll once, then clears it)
				if (_tut.face > 0) die_struct.forced_roll = _tut.face;
				break;
			}
		}
	}

	// a debug die doesn't come out of the bag
	if (_debug_die != undefined) {
		die_struct = clone_die(_debug_die, "");
		die_struct.uid = global._die_uid_counter++;
		index = -1;
	}
	
	// if we haven't set die_struct
	if (die_struct == undefined) {
	    index = irandom(ds_list_size(global.dice_bag) - 1);
	    var bag_die = global.dice_bag[| index];
	    die_struct = clone_die(bag_die, "");
	}
	
	// Trigger on dice dealt effects
	trigger_die_effects_single(die_struct, "on_dice_dealt", trigger_data);

	// rolled dice: a die rolls as it's dealt, and shows its number in hand (docs/design-rolled-dice.md)
	if (room == rmCombat) die_roll_faces(die_struct);

    // Spawn instance
    var die_inst = instance_create_layer(global.gui.bag_x_deal, global.gui.bag_y_deal, "Instances", oDice);
    die_inst.struct = die_struct;
    die_inst.action_type = die_struct.action_type;
    die_inst.dice_amount = die_struct.dice_amount;
    die_inst.dice_value  = die_struct.dice_value;
	die_inst.possible_type = die_struct.possible_type;
	die_inst.can_discard = _can_discard_this_turn;

	// rolled dice: it tumbles as it flies out of the bag, then lands on its roll (oDice Step)
	if (room == rmCombat && die_has_faces(die_struct)) die_inst.roll_anim = 12;
	if (room == rmCombat) sfx_play(choose(soDiceRolling1, soDiceRolling2, soDiceRolling3), AUDIO_GROUP.SFX, random_range(0.01, 0.05), 0.4);

    var target = generate_valid_targets(1, 100) [0];
	// in a fight a dealt die flies to its own spot in the row as it will be once the whole deal is in (dice still to
	// come counted), so it lands where it stays (combat_hand_row keeps the row)
	if (room == rmCombat) {
		var _in_hand = 0;
		with (oDice) if (!still && !in_slot) _in_hand++;
		var _coming = instance_exists(oCombat) ? max(0, oCombat.dice_to_deal - 1) : 0; // dice_to_deal counts this one until after
		var _rp = combat_hand_row_pos(_in_hand - 1, _in_hand + _coming);
		target = [_rp.x, _rp.y];
	}
    die_inst.target_x = target[0];
    die_inst.target_y = target[1];

    // Remove from bag
    if (index != -1) ds_list_delete(global.dice_bag, index);
	
	return die_inst;
}

/// @func die_roll_faces(_die)
/// @desc Rolled dice: rolls a die when it's dealt and keeps the result on it (faces, one per die in a "2d4").
///       Uses its range and weighting as it is in hand. A die that rolls twice (Accurate) does it now and keeps the
///       higher (faces_twice). process_action resolves these faces instead of rolling again.
function die_roll_faces(_die) {
	var _out = get_dice_output(_die, -1, -1, true, "player", true);
	var _min = _out.min_roll, _max = _out.max_roll;
	var _dist = [];
	define_dice_distributions((_out.weighting != "") ? _out.weighting : _die.distribution, _min, _max, _dist);
	var _weight = 0;
	for (var d = 0; d < array_length(_dist); d++) _weight += _dist[d];
	_die.faces = [];
	_die.faces_twice = _out.roll_twice;
	repeat (max(1, _die.dice_amount)) {
		var _face = (_weight > 0) ? weighted_to_face(_dist, irandom_range(1, _weight), _min) : irandom_range(_min, _max);
		if (_out.roll_twice) {
			var _second = (_weight > 0) ? weighted_to_face(_dist, irandom_range(1, _weight), _min) : irandom_range(_min, _max);
			_face = max(_face, _second);
		}
		array_push(_die.faces, _face);
	}
	// a forced face (Balancing Compass: "its max next time") lands now, as it's dealt
	if (variable_struct_exists(_die, "forced_roll") && _die.forced_roll != -1) {
		for (var f = 0; f < array_length(_die.faces); f++) _die.faces[f] = clamp(_die.forced_roll, _min, _max);
		_die.forced_roll = -1;
	}
	// "when rolled" effects (docs/design-port-dice-keepsakes.md): the die's own (on_die_rolled) and keepsakes'
	if (room == rmCombat && instance_exists(oCombat)) {
		if (_min < _max && die_face_total(_die) <= _min) oCombat.min_rolls_this_turn++; // Undertow die (F242)
		combat_trigger_effects("on_die_rolled", { _die_struct: _die, face: die_face_total(_die), min_roll: _min, max_roll: _max });
	}
}

/// @func die_effect_popup(_die, _text, _col)
/// @desc A die's "when rolled" effect firing: a word over it in your hand (or where dice are dealt, as it comes out).
function die_effect_popup(_die, _text, _col) {
	die_jiggle(_die); // and the die wobbles (F40)
	var _x = global.gui.bag_x_deal, _y = global.gui.bag_y_deal - 60;
	with (oDice) if (struct == _die) { _x = x; _y = y - 60; }
	var _inst = instance_create_layer(_x, _y, "Instances", oDamageText);
	_inst.txt = _text;
	_inst.amount = 0;
	_inst.color_main = _col;
	_inst.num_sign = 0;
	_inst.size = 0.6;
}

/// @func die_has_faces(_die)
/// @desc Whether a die has been rolled (die_roll_faces) and is waiting to be used.
function die_has_faces(_die) {
	return is_struct(_die) && variable_struct_exists(_die, "faces") && is_array(_die.faces) && array_length(_die.faces) > 0;
}

/// @func die_face_total(_die, [_min], [_max])
/// @desc The die's rolled number (all its faces added up), each kept within _min.._max if given. -1 if not rolled.
function die_face_total(_die, _min = -1, _max = -1) {
	if (!die_has_faces(_die)) return -1;
	var _t = 0;
	for (var i = 0; i < array_length(_die.faces); i++) {
		var _f = _die.faces[i];
		if (_min != -1) _f = clamp(_f, min(_min, _max), _max);
		_t += _f;
	}
	return _t;
}

/// @func die_clear_faces(_die)
/// @desc A used or discarded die forgets its roll, so it rolls fresh next time it's dealt.
function die_clear_faces(_die) {
	if (is_struct(_die)) { _die.faces = undefined; _die.faces_twice = false; }
}

function generate_dice_bag() {
	
	global._die_uid_counter = 0;
	
	global.bag_size = 10;
	
	/// --- Ensure dice lists exist & are empty ---
	global.dice_bag = ds_list_create();
	global.discard_pile = ds_list_create();
	global.sacrifice_list = ds_list_create(); // used to track the dice sacrificed to make a new slot
	global.sacrifice_history = ds_list_create(); // used to track ALL dice that have been sacrificed 
	global.starter_dice_list = ds_list_create(); // used to track starter dice for game loading
	global.master_dice_list = ds_list_create(); // used to track 1 instance of each dice type, for offering random rewards
	global.alignment_dice_list = ds_list_create(); // used to track 1 instance of each dice type, for offering random rewards

	// Define starter dice structs
	global.dice_all = make_die_struct(1, 4,"None", "All", "", "Multicolor die", "Counts as anything", "starter");
	
	global.dice_d2_none = make_die_struct(1, 2,"None", "None", "", "Generic.", "Coin. Upgrades any action type", "template");
	global.dice_d2_none.keywords = ["Coin"];
	global.dice_d2_atk = make_die_struct(1, 2,"ATK", "ATK", "", "Attack.", "Coin. Deals damage", "template");
	global.dice_d2_atk.keywords = ["Coin"];
	global.dice_d2_blk = make_die_struct(1, 2,"BLK", "BLK", "", "Block.", "Coin. Blocks damage", "template");
	global.dice_d2_blk.keywords = ["Coin"];
	global.dice_d2_intel = make_die_struct(1, 2,"INTEL", "INTEL", "", "Ink.", "Coin. Provides ink", "template");
	global.dice_d2_intel.keywords = ["Coin"];
	global.dice_d2_heal = make_die_struct(1, 2,"HEAL", "HEAL", "", "Heal.", "Coin. Overboard. Heals", "template");
	global.dice_d2_heal.keywords = ["Coin", "Overboard"];
	
	global.dice_d4_none = make_die_struct(1, 4,"None", "None", "", "Generic die", "Upgrades any action type", "starter");
	ds_list_add(global.starter_dice_list, clone_die(global.dice_d4_none, ""));
	global.dice_d6_none = make_die_struct(1, 6,"None", "None", "", "Generic die", "Upgrades any action type", "starter");
	ds_list_add(global.starter_dice_list, clone_die(global.dice_d6_none, ""));
	global.dice_d6_atk = make_die_struct(1, 6,"ATK", "ATK", "", "Attack", "Deals damage", "starter");
	ds_list_add(global.starter_dice_list, clone_die(global.dice_d6_atk, ""));
	global.dice_d4_atk = make_die_struct(1, 4,"ATK", "ATK", "", "Attack", "Deals damage", "starter");
	ds_list_add(global.starter_dice_list, clone_die(global.dice_d4_atk, ""));
	global.dice_d6_blk = make_die_struct(1, 6,"BLK", "BLK", "", "Block", "Blocks damage", "starter");
	ds_list_add(global.starter_dice_list, clone_die(global.dice_d6_blk, ""));
	global.dice_d4_blk = make_die_struct(1, 4,"BLK", "BLK", "", "Block", "Blocks damage", "starter");
	ds_list_add(global.starter_dice_list, clone_die(global.dice_d4_blk, ""));
	global.dice_d4_intel = make_die_struct(1, 4,"INTEL", "INTEL", "", "Ink", "Provides ink", "starter");
	ds_list_add(global.starter_dice_list, clone_die(global.dice_d4_intel, ""));
	global.dice_d4_heal = make_die_struct(1, 4,"HEAL", "HEAL", "", "Heal", "Overboard. Heals", "starter");
	global.dice_d4_heal.keywords = ["Overboard"];
	
	// Anchor Die: Gain +3 block if not used
	global.die_anchor = make_die_struct(
	    1, 6, "BLK", "BLK", "", "Anchor die",
	    "Stowaway: Gain block equal to half its roll.",
		"uncommon", // free value is never common (F242)
		30,
	    [
	        {
	            trigger: "on_not_used",
	            modify: function(_context) {
					// half its rolled number, rounded up (every halved value in the game rounds up, Jared 2026-11-24)
					var _src = _context._die_struct_source;
					var _roll = die_face_total(_src);
					if (_roll == -1) _roll = ceil(_src.dice_value / 2); // never rolled: its average-ish
					with (oCombat) {
						process_action("player", 0, ceil(_roll / 2), 0, "player", undefined, "BLK");
					}
	            }
	        }
	    ]
	);
	global.die_anchor.keywords = ["Stowaway"];
	ds_list_add(global.master_dice_list, clone_die(global.die_anchor, ""));
	
	// Slipstream Die: Play 1 extra dice next turn.
	global.die_slipstream = make_die_struct(
	    1, 4, "ATK", "ATK", "", "Slipstream die",
	    "Stowaway: Play 1 extra die next turn.",
		"uncommon", // F242
		40,
	    [
	        {
	            trigger: "on_not_used",
	            modify: function(_context) {
	                apply_buff("player", oRunManager.buff_reserve, 1, 1, oRunManager.buff_reserve.remove_next_turn, { source: "player", index: -1 });
	            }
	        }
	    ]
	);
	global.die_slipstream.keywords = ["Stowaway"];
	ds_list_add(global.master_dice_list, clone_die(global.die_slipstream, ""));
	
	// Defensive Die: Coin. Favourite. Multitype: Can create HEAL and BLK slo
	global.die_defensive = make_die_struct(
	    1, 2, "BLK", "BLK", "", "Defensive coin",
	    "Coin. Favourite. When played: your leftover Block carries into your next turn.",
		"rare",
		70,
	    [
	        {
	            trigger: "on_dice_played_to_slot",
	            modify: function(_context) {
					if (_context._d_struct.uid != _context._die_struct_source.uid) return;
					oCombat.block_carries = true; // F242: START_TURN keeps what's left of your Block
	            }
	        }
	    ]
	);
	global.die_defensive.keywords = ["Coin", "Favourite"];
	ds_list_add(global.master_dice_list, clone_die(global.die_defensive, ""));
	
	// Anchor Die: Gain +3 block if not used
	global.die_tidebreaker = make_die_struct(
	    1, 6, "ATK", "ATK", "", "Tidebreaker die",
	    "Followthrough: +2 damage if the slot before is Block.",
		"common",
		50,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					if (_context.previous_slot_action_type == "BLK" && _context.action_type == "ATK") {
	                    _context._d_amount += 2;
	                }
	            }
	        }
	    ]
	);
	global.die_tidebreaker.keywords = ["Followthrough"];
	ds_list_add(global.master_dice_list, clone_die(global.die_tidebreaker, ""));
	
	// Pretty penny
	global.die_power_penny = make_die_struct(
	    1, 2, "BLK", "BLK", "", "Power penny",
	    "Coin. +1 for each die in its slot.",
		"uncommon", // a coin with an effect (F242)
		50,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					if (_context._slot != undefined) {
						_context._d_amount += ds_list_size(_context._slot.dice_list);
					}
	            }
	        }
	    ]
	);
	global.die_power_penny.keywords = ["Coin"];
	ds_list_add(global.master_dice_list, clone_die(global.die_power_penny, ""));
	
	// Invisible Die
	global.die_invisible = make_die_struct(
	    1, 4, "None", "None", "", "Invisible die",
	    "When played: draw 1 die and gain 1 play.",
		"uncommon", // F242
		30,
	    [
	        {
	            trigger: "on_dice_played_to_slot",
	            modify: function(_context) {
					with (oRunManager) {
						if (_context._d_struct.uid == _context._die_struct_source.uid) {
							deal_single_die();
							oCombat.dice_allowed_this_turn_bonus++;
						}
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_invisible, ""));
	
	// Surge Die
	global.die_surge = make_die_struct(
	    1, 4, "BLK", "BLK", "", "Surge die",
	    "+1 for each slot after it.",
		"uncommon",
		40,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					// only once it is in a slot: in hand or a menu there are no slots after it to count
					if (_context.slot_num >= 0) _context._d_amount = ds_list_size(oCombat.action_queue) - 1 - _context.slot_num;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_surge, ""));
	
	// Kill Coin
	global.die_kill_coin = make_die_struct(
	    1, 2, "ATK", "ATK", "", "Kill coin",
	    "Coin. +2 in the last slot.",
		"uncommon",
		40,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					// the last slot, or the new-slot tile (which becomes the last slot: die_tile_effect_amount)
					if (_context.slot_num >= 0) _context._d_amount = 2 * (_context.slot_num >= ds_list_size(oCombat.action_queue) - 1);
	            }
	        }
	    ]
	);
	global.die_kill_coin.keywords = ["Coin"];
	ds_list_add(global.master_dice_list, clone_die(global.die_kill_coin, ""));
	
	// Tidepusher die
	global.die_tidepusher = make_die_struct(
	    1, 6, "BLK", "BLK", "", "Tidepusher die",
	    "Overboard. This turn, heal 1 each time your Block fully stops a hit.",
		"rare",
		90,
	    [
	        {
	            trigger: "after_roll_die", // as its slot resolves (F242: healing is rare and on a trigger)
	            modify: function(_context) {
					if (_context.die.uid != _context._die_struct_source.uid) return;
					oCombat.heal_on_full_block += 1;
					roll_popup(_context.slot_num, _context.dice_index, string(_context._die_struct_source.name) + "!", c_white);
	            }
	        }
	    ]
	);
	global.die_tidepusher.keywords = ["Overboard"];
	ds_list_add(global.master_dice_list, clone_die(global.die_tidepusher, ""));
	
	// Bulwark die
	global.die_bulwark = make_die_struct(
	    1, 8, "BLK", "BLK", "", "Bulwark die",
	    "Followthrough: If the slot before is Block, deal your Block as damage to all enemies.",
		"rare",
		70,
	    [
	        {
	            trigger: "after_roll_die",
	            modify: function(_context) {
					if (_context._p_slot_type == "BLK" && _context.die.uid == _context._die_struct_source.uid) {
						roll_popup(_context.slot_num, _context.dice_index, string(_context._die_struct_source.name) + "!", c_white); // F40: show the effect firing
	                    with (oCombat) {
							// Deal flat damage to all enemies, we have to run this backwards in case any enemies die during this roll
							for (var i = ds_list_size(oCombat.room_enemies)-1; i >= 0 ; i--) {
								if (oCombat.room_enemies[| i].dead) continue;
								process_action(oCombat.room_enemies[| i], 0, max(0, player_block_amount), 0, "player", -1, "ATK", undefined, undefined, 0); // your Block (F242)
								show_debug_message("Dealing damage to enemy index: " + string(i));
							}
							//show_debug_message("dealing damage to all enemies");
						}
	                }
	            }
	        }
	    ]
	);
	global.die_bulwark.keywords = ["Followthrough"];
	ds_list_add(global.master_dice_list, clone_die(global.die_bulwark, ""));
	
	// Bulwark die
	global.die_crescendo = make_die_struct(
	    1, 8, "ATK", "ATK", "", "Crescendo die",
	    "+1 for each time it's been played this fight.",
		"rare",
		80,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
	                _context._d_amount += _context.die.statistics.times_played_this_combat; // F242: no cap, grows all fight
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_crescendo, ""));
	
	// Squall die
	global.die_squall = make_die_struct(
	    1, 6, "None", "None", "", "Squall die",
	    "If it rolls 5 or higher, draw a die.",
		"common",
		50,
	    [
	        {
	            trigger: "on_die_rolled", // when rolled: the extra die comes as it lands
	            modify: function(_context) {
					if (_context.face >= 5) {
						die_effect_popup(_context._die_struct, "Squall!", c_white);
						oCombat.dice_to_deal += 1;
						oCombat.is_dealing_dice = true;
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_squall, ""));
	
	// Reed snap die
	global.die_reed_snap = make_die_struct(
	    1, 4, "BLK", "BLK", "", "Reed snap die",
	    "If it rolls 4 or higher, gain 2 block.",
		"common",
		30,
	    [
	        {
	            trigger: "after_roll_die",
	            modify: function(_context) {
					if (_context._d_amount >= 4 && _context.die.uid == _context._die_struct_source.uid) {
						roll_popup(_context.slot_num, _context.dice_index, string(_context._die_struct_source.name) + "!", c_white); // F40: show the effect firing
						with (oCombat) {
							process_action("player", 0, 2, 0, "player", undefined, "BLK");
						}
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_reed_snap, ""));
	
	// Reed snap die
	global.die_blood_reef = make_die_struct(
	    1, 6, "ATK", "ATK", "", "Blood Reef die",
	    "When it's dealt: gain 1 Might, lose 3 health.",
		"rare",
		80,
	    [
	        {
	            trigger: "on_dice_dealt", // F242 (Jared): the first real Might engine piece
	            modify: function(_context) {
					if (room != rmCombat) return;
					global.player_hp = max(1, global.player_hp - 3);
					apply_buff("player", oRunManager.buff_might, 1, 1, false, { source: "player", index: -1 });
					spawn_floating_number("player", 3, -1, c_red, -1, -1, 0);
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_blood_reef, ""));
	
	// Slipstream Die
	global.die_muzzle = make_die_struct(
	    1, 4, "ATK", "ATK", "", "Muzzle die",
	    "Followthrough: +1 for each slot before it.",
		"uncommon",
		60,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					if (_context.slot_num > -1) {
						_context._d_amount = _context.slot_num;
					}
	            }
	        }
	    ]
	);
	global.die_muzzle.keywords = ["Followthrough"];
	ds_list_add(global.master_dice_list, clone_die(global.die_muzzle, ""));
	
	// Bilge Die
	global.die_bilge = make_die_struct(
	    1, 6, "None", "None", "", "Bilge die",
	    "Sticky. If its total is even, heal 2.",
		"rare",
		80,
	    [
	        {
	            trigger: "after_roll_die",
	            modify: function(_context) {
					// the total the player sees on the die: the roll plus the slot's and keepsakes' bonuses
					var _total = _context._d_amount + _context.slot_bonus + _context.keepsake_bonus + _context.first_bonus;
					if (_total mod 2 == 0 && _context.die.uid == _context._die_struct_source.uid) {
						roll_popup(_context.slot_num, _context.dice_index, string(_context._die_struct_source.name) + "!", c_white); // F40: show the effect firing
						global.player_hp = min(global.player_max_hp, global.player_hp + 2);
						particle_emit(global.player_x, global.player_y, "burst", c_lime);
						var num = spawn_floating_number("player", 2, -1, c_lime, 1, -1, 0);
						num.x += 20;
						num.y += 10;
					}
	            }
	        }
	    ]
	);
	global.die_bilge.keywords = ["Sticky"];
	ds_list_add(global.master_dice_list, clone_die(global.die_bilge, ""));
	
	// Sticky Die
	global.die_sticky = make_die_struct(
	    1, 4, "None", "None", "", "Sticky die",
	    "Sticky.",
		"uncommon",
		50,
		[]
	);
	global.die_sticky.keywords = ["Sticky"];
	ds_list_add(global.master_dice_list, clone_die(global.die_sticky, ""));
	
	// Fogcaller Die
	global.die_fogcaller = make_die_struct(
	    1, 4, "BLK", "BLK", "", "Fogcaller Die",
	    "Followthrough: if the slot before it holds a coin, +1 and draw a die.",
		"common",
		40,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					if (_context.slot_num > 0) {
						var prev_slot_list = oCombat.action_queue[| _context.slot_num - 1 ].dice_list;
						var prev_has_coin = false;
					
						for (var i = 0; i < ds_list_size(prev_slot_list); i++) {
							if (die_has_keyword(prev_slot_list[| i], "Coin")) {
								prev_has_coin = true;
								_context._d_amount += 1;
								break;
							}
						}
							
					}
	            }
	        },
			{
				// the draw: when it's played into a slot after one holding a coin (not at End Turn, where it was wasted)
	            trigger: "on_dice_played_to_slot",
	            modify: function(_context) {
					if (_context._d_struct.uid != _context._die_struct_source.uid || _context._slot_num <= 0) return;
					var _prev = oCombat.action_queue[| _context._slot_num - 1].dice_list;
					for (var i = 0; i < ds_list_size(_prev); i++) {
						if (die_has_keyword(_prev[| i], "Coin")) {
							oCombat.dice_to_deal += 1;
							oCombat.is_dealing_dice = true;
							break;
						}
					}
	            }
	        }
	    ]
	);
	global.die_fogcaller.keywords = ["Followthrough"];
	ds_list_add(global.master_dice_list, clone_die(global.die_fogcaller, ""));
	
	// Deepdiver Die
	global.die_deepdiver = make_die_struct(
	    1, 6, "None", "None", "", "Deepdiver Die",
	    "When rerolled or redrawn with ink, draw a die.",
		"uncommon",
		50,
	    [
	        {
	            trigger: "on_die_inked", // rerolled or redrawn with ink (combat_reroll_die, combat_redraw_die)
	            modify: function(_context) {
					die_effect_popup(_context._die_struct, "Deepdiver!", c_white);
					oCombat.dice_to_deal += 1;
					oCombat.is_dealing_dice = true;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_deepdiver, ""));
	
	// Inteli Die
	global.die_intelli = make_die_struct(
	    1, 4, "INTEL", "INTEL", "", "Inkwell Die",
	    "+1 for each action type in your queue.",
		"uncommon",
		50,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					if (room != rmCombat) exit;
					
					var type_str = "";
					for (var i = 0; i < ds_list_size(oCombat.action_queue); i++) {
						var slot = oCombat.action_queue[| i];
						if (slot.current_action_type == "None") continue; // an empty slot has no type yet

						if (string_pos(slot.current_action_type, type_str) == 0) {
							if (type_str != "") type_str += ",";
							type_str += string(slot.current_action_type);
						}
					}
					
					var types = string_split(type_str, ",");
					_context._d_amount += array_length(types);
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_intelli, ""));
	
	// Deflect Die
	global.die_deflect = make_die_struct(
	    1, 6, "BLK", "BLK INTEL", "", "Deflect Die",
	    "Multitype. Block or Ink. +2 while you hold 6 or more ink.",
		"uncommon",
		70,
		[
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					if (instance_exists(oCombat) && oCombat.player_intel >= 6) _context._d_amount += 2; // F242
	            }
	        }
		]
	);
	global.die_deflect.keywords = ["Multitype"];
	ds_list_add(global.master_dice_list, clone_die(global.die_deflect, ""));
	
	global.die_bolster = make_die_struct(
	    1, 4, "BLK", "BLK", "", "Bolster Die",
	    "When it builds a slot: gain {max} block.",
		"common",
		50,
	    [
	        {
	            trigger: "on_sacrifice_die",
	            modify: function(_context) {
					with (oCombat) {
						process_action("player", 0, _context.die.struct.dice_value, 0, "player", undefined, "BLK"); // 1 x size (F242: it was 2 x, a top-five die as a common)
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_bolster, ""));
	
	global.die_echo = make_die_struct(
	    1, 4, "None", "None", "", "Echo Die",
	    "When played: a copy joins its slot.",
		"rare",
		60,
	    [
	        {
	            trigger: "on_dice_played_to_slot",
	            modify: function(_context) {
					if (_context._d_struct.uid == _context._die_struct_source.uid) {
						_context.duplicate_die = true;
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_echo, ""));
	
	global.die_accurate = make_die_struct(
	    1, 4, "ATK", "ATK", "", "Accurate Die",
	    "Rolls twice and keeps the higher.",
		"common",
		40,
	    [
	        {
				trigger: "on_roll_die",
	            modify: function(_context) {
					// it rolls twice as it's dealt (rolled dice), or when it resolves if it wasn't dealt
					if (!_context.read_only || (variable_struct_exists(_context, "on_deal") && _context.on_deal)) {
						_context.roll_twice = true;
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_accurate, ""));
	
	global.die_barrel = make_die_struct(
	    1, 6, "BLK", "BLK", "", "Barrel Die",
	    "When it builds a slot: gain a random potion.",
		"rare",
		70,
	    [
	        {
			    trigger: "on_sacrifice_die",
			    modify: function(_context) {
			        var consumable_options = ds_list_create();
			        for (var i = 0; i < ds_list_size(global.master_item_list); i++) {
			            if (global.master_item_list[| i].type == "consumable") {
			                ds_list_add(consumable_options, global.master_item_list[| i]);
			            }
			        }
			        if (ds_list_size(consumable_options) > 0) {
			            var picked = consumable_options[| irandom(ds_list_size(consumable_options) - 1)];
			            // with full item slots it can't be kept in a fight: say so instead of losing it silently (B163)
			            if (get_first_free_item_slot() == -1) throw_error("Item slots full", "The Barrel's potion was lost.");
			            else gain_item(clone_item(picked));
			        }
			        ds_list_destroy(consumable_options);
			    }
			}
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_barrel, ""));
	
	global.die_harvest = make_die_struct(
	    1, 6, "BLK", "BLK", "", "Harvest Die",
	    "Gain 1 gold when played or when it builds a slot.",
		"common",
		50,
	    [
			{
	            trigger: "on_dice_played_to_slot",
	            modify: function(_context) {
					if (_context._d_struct.uid == _context._die_struct_source.uid) {
						gain_coins(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), 1);
					}
	            }
	        },
			{
	            trigger: "on_sacrifice_die",
	            modify: function(_context) {
					if (_context._d_struct.uid == _context._die_struct_source.uid) {
						gain_coins(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), 1);
					}
	            }
	        },
			
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_harvest, ""));
	
	global.die_lookout = make_die_struct(
	    1, 6, "INTEL", "INTEL", "", "Lookout die",
	    "Stowaway: Gain 3 ink next turn.",
		"uncommon", // F242
		40,
	    [
	        {
	            trigger: "on_not_used",
	            modify: function(_context) {
					var amount = 3;
	                apply_buff("player", oRunManager.buff_intel, 1, amount, oRunManager.buff_intel.remove_next_turn, { source: "player", index: -1 });
					var num = spawn_floating_number("player", amount, -1, global.text_intel, 1, -1, 0);
					num.x += 20;
					num.y -= 20;
	            }
	        }
	    ]
	);
	global.die_lookout.keywords = ["Stowaway"];
	ds_list_add(global.master_dice_list, clone_die(global.die_lookout, ""));
	
	global.die_bouncing = make_die_struct(
	    1, 4, "ATK", "ATK", "", "Bouncing Die",
	    "When attacking: half its roll also hits another enemy.",
		"common",
		40,
	    [
	        {
	            trigger: "after_roll_die", // owner-only: its own roll (F242: it switched your target, for good)
	            modify: function(_context) {
					if (_context._c_slot_type != "ATK") return;
					var _hit = floor(_context._d_amount / 2);
					if (_hit <= 0) return;
					with (oCombat) {
						var _others = [];
						for (var i = 0; i < ds_list_size(room_enemies); i++) if (i != enemy_target_index && !room_enemies[| i].dead) array_push(_others, room_enemies[| i]);
						if (array_length(_others) > 0) process_action(_others[irandom(array_length(_others) - 1)], 0, _hit, 0, "player", -1, "ATK", undefined, undefined, 0);
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_bouncing, ""));
	
	global.die_guerrilla_coin = make_die_struct(
	    1, 2, "INTEL", "INTEL", "", "Guerrilla Coin",
	    "Coin. When it builds a slot: deal half your ink as damage to a random enemy.",
		"uncommon", // a coin with an effect (F242)
		40,
	    [
	        {
				trigger: "on_sacrifice_die",
	            modify: function(_context) {
					// half your ink, to a random enemy still standing
					var _alive = [];
					with (oCombat) for (var e = 0; e < ds_list_size(room_enemies); e++) if (!room_enemies[| e].dead) array_push(_alive, room_enemies[| e]);
					var _dmg = floor(max(0, oCombat.player_intel) / 2);
					if (array_length(_alive) > 0 && _dmg > 0) with (oCombat) process_action(_alive[irandom(array_length(_alive) - 1)], 0, _dmg, 0, "player", -1, "ATK");
	            }
	        }
	    ]
	);
	global.die_guerrilla_coin.keywords = ["Coin"];
	ds_list_add(global.master_dice_list, clone_die(global.die_guerrilla_coin, ""));
	
	global.die_radar = make_die_struct(
	    1, 6, "INTEL", "INTEL", "", "Radar die",
	    "When played: gain ink equal to its roll.",
		"common",
		40,
	    [
	        {
	            trigger: "on_dice_played_to_slot", // the ink arrives now, not next turn (Jared, 2026-11-24)
	            modify: function(_context) {
					if (_context._d_struct.uid != _context._die_struct_source.uid || !instance_exists(oCombat)) return;
					var _roll = die_face_total(_context._d_struct);
					if (_roll == -1) _roll = ceil(_context._d_struct.dice_value / 2);
					var _gain = min(_roll, max(0, intel_max() - oCombat.player_intel));
					oCombat.player_intel += _gain;
					die_effect_popup(_context._d_struct, "+" + string(_roll) + " ink", global.text_intel);
					var num = spawn_floating_number("player", _gain, -1, global.text_intel, 1, -1, 0);
					num.x += 20;
					num.y -= 20;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_radar, ""));
	
	global.die_offhand = make_die_struct(
	    1, 6, "ATK", "ATK", "", "Offhand die",
	    "If it rolls {min}, gain 1 Might.",
		"common",
		30,
	    [
	        {
	            trigger: "on_die_rolled", // when rolled: the Might counts for this turn's queue
	            modify: function(_context) {
					if (_context.face == _context.min_roll) {
						die_effect_popup(_context._die_struct, "Might!", c_white);
						apply_buff("player", oRunManager.buff_might, 1, 1, false, { source: "player", index: -1 });
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_offhand, ""));
	
	global.die_balanced = make_die_struct(
	    1, 6, "BLK", "BLK", "", "Balanced die",
	    "If it rolls {max}, gain 1 Balance.",
		"common",
		30,
	    [
	        {
	            trigger: "on_die_rolled", // the moment it rolls (Jared, 2026-11-24: it used to wait for next turn)
	            modify: function(_context) {
					if (_context.face == _context.max_roll && instance_exists(oCombat)) {
						die_effect_popup(_context._die_struct, "Balance", c_white);
						apply_buff("player", oRunManager.buff_balance, 1, 1, false, { source: "player", index: -1 });
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_balanced, ""));
	
	global.die_holy = make_die_struct(
	    1, 8, "None", "None", "", "Holy die",
	    "Alignment: The higher your alignment, the higher its minimum roll.",
		"rare",
		70,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					_context.min_roll += global.alignment_stage;
	            }
	        }
	    ]
	);
	ds_list_add(global.alignment_dice_list, clone_die(global.die_holy, ""));
	ds_list_add(global.master_dice_list, clone_die(global.die_holy, "")); // also in the rare pool (F242)
	
	global.die_unholy = make_die_struct(
	    1, 6, "None", "None", "", "Unholy die",
	    "Alignment: The lower your alignment, the higher its maximum roll.",
		"rare",
		70,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					_context.max_roll += (6 - global.alignment_stage);
	            }
	        }
	    ]
	);
	ds_list_add(global.alignment_dice_list, clone_die(global.die_unholy, ""));
	ds_list_add(global.master_dice_list, clone_die(global.die_unholy, "")); // also in the rare pool (F242)
	
	global.die_ninja = make_die_struct(
	    1, 4, "BLK", "BLK", "", "Ninja die",
	    "Followthrough: +2 if the slot before is ink.",
		"common",
		40,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					if (_context.previous_slot_action_type == "INTEL") {
	                    _context._d_amount += 2;
	                }
	            }
	        }
	    ]
	);
	global.die_ninja.keywords = ["Followthrough"];
	ds_list_add(global.master_dice_list, clone_die(global.die_ninja, ""));
	
	global.die_warrior = make_die_struct(
	    1, 4, "ATK", "ATK", "", "Warrior die",
	    "Rolls of {min} become {max}.",
		"common",
		30,
	    [
	        {
	            trigger: "on_die_rolled", // when rolled: the face itself becomes its max, so the slot shows it
	            modify: function(_context) {
					if (_context.face <= _context.min_roll) {
						var _d = _context._die_struct;
						for (var f = 0; f < array_length(_d.faces); f++) _d.faces[f] = _context.max_roll;
						die_effect_popup(_d, "Warrior!", c_orange);
	                }
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_warrior, ""));
	
	global.die_assassin = make_die_struct(
	    1, 6, "ATK", "ATK INTEL", "", "Assassin Die",
	    "Multitype. Attack or Ink. +1 minimum roll per 2 ink.",
		"rare",
		70,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					// only in a fight, this also runs when the die is shown in the bag or shop
					if (instance_exists(oCombat)) _context.min_roll = min(_context.min_roll + floor(max(0, oCombat.player_intel) / 2), _context.max_roll - 1); // B163: never up to its max
	            }
	        }
	    ]
	);
	global.die_assassin.keywords = ["Multitype"];
	ds_list_add(global.master_dice_list, clone_die(global.die_assassin, ""));
	
	global.die_last_stand = make_die_struct(
	    1, 6, "ATK", "ATK", "", "Last Stand Die",
	    "+1 minimum roll per 20% health missing.",
		"uncommon",
		60,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					_context.min_roll += round((global.player_hp/global.player_max_hp) * -5 + 5);
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_last_stand, ""));
	
	global.die_splash = make_die_struct(
	    1, 10, "BLK", "BLK", "", "Splash Die",
	    "-1 on every roll, never below 1.",
		"common",
		60,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					_context._d_amount = (die_face_total(_context.die) > 1) ? -1 : 0; // F242: was -2, minimum 0
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_splash, ""));

	// --- v0.2 dice (F21) ---
	// Gunpowder: when it rolls, every other enemy takes 2 (at roll time, so enemies only ever fall while the queue resolves)
	global.die_gunpowder = make_die_struct(
	    1, 4, "ATK", "ATK", "", "Gunpowder die",
	    "When attacking: every other enemy takes 2 damage.",
		"common",
		40,
	    [
	        {
	            trigger: "after_roll_die", // owner-only: fires for this die's own roll (die_fire_effects)
	            modify: function(_context) {
					if (_context._c_slot_type != "ATK") return; // only as an attack
					with (oCombat) {
						for (var i = 0; i < ds_list_size(room_enemies); i++) {
							if (i != enemy_target_index && !room_enemies[| i].dead) process_action(room_enemies[| i], 0, 2, 0, "player", -1, "ATK", undefined, undefined, 0);
						}
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_gunpowder, ""));

	// Tidecaller: a high heal also raises your guard
	global.die_tidecaller = make_die_struct(
	    1, 6, "BLK", "BLK", "", "Tidecaller die",
	    "Overboard. If it rolls 5 or higher, also heal 3.",
		"uncommon",
		50,
	    [
	        {
	            trigger: "after_roll_die",
	            modify: function(_context) {
					if (_context._d_amount >= 5) {
						with (oCombat) process_action("player", 0, 3, 0, "player", undefined, "HEAL"); // F242: healing on a trigger
						roll_popup(_context.slot_num, _context.dice_index, "Tidecaller!", global.color_heal);
					}
	            }
	        }
	    ]
	);
	global.die_tidecaller.keywords = ["Overboard"];
	ds_list_add(global.master_dice_list, clone_die(global.die_tidecaller, ""));

	// ===================================================================================================================
	// F242 content pass (Jared, 2026-11-23): new dice for the seven archetypes and the core shapes (docs/design/content-pass.md)
	// ===================================================================================================================

	// --- core shapes (section 5)
	global.die_plumb_line = make_die_struct(
	    1, 6, "BLK", "BLK", "", "Plumb Line die",
	    "+2 if it rolls a middle face.",
		"common",
		40,
	    [
	        {
	            trigger: "on_roll_die", // Bell and Dome's payoff
	            modify: function(_context) {
					if (die_face_middle(die_face_total(_context.die), _context.min_roll, _context.max_roll)) _context._d_amount += 2;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_plumb_line, ""));

	global.die_grapnel = make_die_struct(
	    1, 6, "ATK", "ATK", "", "Grapnel die",
	    "If it rolls one below its max, it counts as its max +2.",
		"uncommon",
		50,
	    [
	        {
	            trigger: "on_roll_die", // Dual and Tower's payoff
	            modify: function(_context) {
					if (_context.max_roll - 1 > _context.min_roll && die_face_total(_context.die) == _context.max_roll - 1) _context._d_amount += 3;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_grapnel, ""));

	// --- Full ink
	global.die_inkpot = make_die_struct(
	    1, 4, "INTEL", "INTEL", "", "Inkpot die",
	    "When played: +2 max ink this fight.",
		"common",
		40,
	    [
	        {
	            trigger: "on_dice_played_to_slot",
	            modify: function(_context) {
					if (_context._d_struct.uid != _context._die_struct_source.uid || !instance_exists(oCombat)) return;
					oCombat.ink_max_bonus += 2; // intel_max
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_inkpot, ""));

	global.die_calligrapher = make_die_struct(
	    1, 6, "INTEL", "INTEL", "", "Calligrapher's die",
	    "+1 for each ink action this turn.",
		"uncommon",
		50,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					if (instance_exists(oCombat)) _context._d_amount += oCombat.ink_actions_this_turn;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_calligrapher, ""));

	// --- Infinite might
	global.die_grit = make_die_struct(
	    1, 4, "ATK", "ATK", "", "Grit die",
	    "If it rolls {max}, gain 1 Might.",
		"common",
		40,
	    [
	        {
	            trigger: "on_die_rolled", // when rolled: the Might counts for this turn's queue (like Offhand)
	            modify: function(_context) {
					if (_context.min_roll < _context.max_roll && _context.face == _context.max_roll) {
						die_effect_popup(_context._die_struct, "Might!", c_white);
						apply_buff("player", oRunManager.buff_might, 1, 1, false, { source: "player", index: -1 });
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_grit, ""));

	// --- Valleys
	global.die_undertow = make_die_struct(
	    1, 6, "ATK", "ATK", "", "Undertow die",
	    "+1 for each die that rolled its minimum this turn.",
		"uncommon",
		50,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					if (instance_exists(oCombat)) _context._d_amount += oCombat.min_rolls_this_turn;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_undertow, ""));

	global.die_riptide = make_die_struct(
	    1, 4, "ATK", "ATK", "", "Riptide die",
	    "If it rolls {min}, it counts as double its max.",
		"rare",
		80,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					var _f = die_face_total(_context.die);
					if (_context.min_roll < _context.max_roll && _f >= 0 && _f <= _context.min_roll) _context._d_amount += _context.max_roll * 2 - _f;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_riptide, ""));

	// --- Coin swarm: plain common coins (just "doesn't use a play"), and payoffs that count coins
	global.die_cutlass_coin = make_die_struct(1, 2, "ATK", "ATK", "", "Cutlass coin", "Coin. ", "common", 20, []);
	global.die_cutlass_coin.keywords = ["Coin"];
	ds_list_add(global.master_dice_list, clone_die(global.die_cutlass_coin, ""));
	global.die_buckler_coin = make_die_struct(1, 2, "BLK", "BLK", "", "Buckler coin", "Coin. ", "common", 20, []);
	global.die_buckler_coin.keywords = ["Coin"];
	ds_list_add(global.master_dice_list, clone_die(global.die_buckler_coin, ""));
	global.die_inkblot_coin = make_die_struct(1, 2, "INTEL", "INTEL", "", "Inkblot coin", "Coin. ", "common", 20, []);
	global.die_inkblot_coin.keywords = ["Coin"];
	ds_list_add(global.master_dice_list, clone_die(global.die_inkblot_coin, ""));

	global.die_purser = make_die_struct(
	    1, 6, "BLK", "BLK", "", "Purser's die",
	    "+1 for each coin played this turn.",
		"uncommon",
		50,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					if (instance_exists(oCombat)) _context._d_amount += oCombat.coins_played_this_turn;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_purser, ""));

	global.die_doubloon = make_die_struct(
	    1, 2, "ATK", "ATK", "", "Doubloon",
	    "Coin. +1 for each other coin in its slot.",
		"rare",
		70,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					if (!variable_struct_exists(_context, "_slot") || !is_struct(_context._slot)) return;
					var _l = _context._slot.dice_list, _n = 0;
					for (var i = 0; i < ds_list_size(_l); i++) if (_l[| i] != _context.die && die_has_keyword(_l[| i], "coin")) _n++;
					_context._d_amount += _n;
	            }
	        }
	    ]
	);
	global.die_doubloon.keywords = ["Coin"]; // every coin is a d2 (Jared, 2026-11-24: it was a d4 that stayed a coin)
	ds_list_add(global.master_dice_list, clone_die(global.die_doubloon, ""));

	// --- Heavy hitters
	global.die_broadside = make_die_struct(
	    1, 8, "ATK", "ATK", "", "Broadside die",
	    "+2 in slot 3 or later.",
		"uncommon",
		60,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					if (_context.slot_num >= 2) _context._d_amount += 2;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_broadside, ""));

	global.die_carronade = make_die_struct(
	    1, 12, "ATK", "ATK", "", "Carronade die",
	    "Uses 2 plays.",
		"rare",
		80,
	    []
	);
	global.die_carronade.heavy_play = true; // die_play_cost
	ds_list_add(global.master_dice_list, clone_die(global.die_carronade, ""));

	// --- Fortress
	global.die_barnacle = make_die_struct(
	    1, 4, "BLK", "BLK", "", "Barnacle die",
	    "Followthrough: +2 if the slot before is Block.",
		"common",
		40,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					if (_context.previous_slot_action_type == "BLK" && _context.action_type == "BLK") _context._d_amount += 2;
	            }
	        }
	    ]
	);
	global.die_barnacle.keywords = ["Followthrough"];
	ds_list_add(global.master_dice_list, clone_die(global.die_barnacle, ""));

	// --- Alignment extremes: a push you can repeat
	global.die_mercy = make_die_struct(
	    1, 4, "BLK", "BLK", "", "Mercy die",
	    "When played: +1 alignment.",
		"common",
		30,
	    [
	        {
	            trigger: "on_dice_played_to_slot",
	            modify: function(_context) {
					if (_context._d_struct.uid != _context._die_struct_source.uid) return;
					gain_alignment(1);
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_mercy, ""));

	global.die_cutthroat = make_die_struct(
	    1, 4, "ATK", "ATK", "", "Cutthroat die",
	    "When played: -1 alignment.",
		"common",
		30,
	    [
	        {
	            trigger: "on_dice_played_to_slot",
	            modify: function(_context) {
					if (_context._d_struct.uid != _context._die_struct_source.uid) return;
					gain_alignment(-1);
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_cutthroat, ""));

	// Ballast: a heavy die that never rolls low
	global.die_ballast = make_die_struct(
	    1, 8, "BLK", "BLK", "", "Ballast die",
	    "Never rolls below 4.",
		"uncommon",
		55,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					_context.min_roll = max(_context.min_roll, 4);
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_ballast, ""));
	
	// Add to bag - STARTING DICE SET HERE
	repeat(3)		{ ds_list_add(global.dice_bag, clone_die(global.dice_d4_atk, "")); }
	repeat(3)		{ ds_list_add(global.dice_bag, clone_die(global.dice_d4_blk, "")); }
	repeat(2)		{ ds_list_add(global.dice_bag, clone_die(global.dice_d4_intel, "")); }
	//repeat(1)		{ ds_list_add(global.dice_bag, clone_die(global.die_warrior, "")); }
	//repeat(1)		{ ds_list_add(global.dice_bag, clone_die(global.die_offhand, "")); }
	
	do { ds_list_add(global.dice_bag, clone_die(global.dice_d4_none, "")); }
	until (ds_list_size(global.dice_bag) == global.bag_size);
}

/// generate_valid_targets(num_dice, min_dist)
/// returns array of [x, y] positions in the hand area, spaced at least min_dist from each other and from the dice
/// already in hand (their targets), so dealt dice never overlap. If the area is too full for a random spot, it takes
/// the point of a fine grid that is furthest from everything.
function generate_valid_targets(_num, _min_dist) {
    var positions = [];

	// the dice already dealt (on their way or resting) count as taken
	var taken = [];
	with (oDice) {
		if (variable_instance_exists(id, "target_x") && !is_undefined(target_x)) array_push(taken, [target_x, target_y]);
		else array_push(taken, [x, y]);
	}

	var x1 = global.dice_safe_area_x1, x2 = global.dice_safe_area_x2;
	var y1 = global.dice_safe_area_y1, y2 = global.dice_safe_area_y2;

    repeat (_num) {
		var best_x = random_range(x1, x2), best_y = random_range(y1, y2);
		var found = false;
        repeat (200) {
            var xx = random_range(x1, x2);
            var yy = random_range(y1, y2);
			if (generate_target_clearance(xx, yy, positions, taken) >= _min_dist) {
				best_x = xx; best_y = yy; found = true;
				break;
			}
        }

        // too full for a random spot: the grid point with the most room
        if (!found) {
			var best_room = -1;
			for (var gx = x1; gx <= x2; gx += 20) {
				for (var gy = y1; gy <= y2; gy += 20) {
					var room_here = generate_target_clearance(gx, gy, positions, taken);
					if (room_here > best_room) { best_room = room_here; best_x = gx; best_y = gy; }
				}
			}
        }

        array_push(positions, [best_x, best_y]);
    }

    return positions;
}

/// @func generate_target_clearance(_x, _y, _a, _b)
/// @desc Distance from (_x, _y) to the nearest point in either list of [x, y].
function generate_target_clearance(_x, _y, _a, _b) {
	var nearest = 100000;
	for (var j = 0; j < array_length(_a); j++) nearest = min(nearest, point_distance(_a[j][0], _a[j][1], _x, _y));
	for (var j = 0; j < array_length(_b); j++) nearest = min(nearest, point_distance(_b[j][0], _b[j][1], _x, _y));
	return nearest;
}

/// @func die_has_trigger(_die, _trigger)
/// @desc Does this die have an effect of its own on this event? (e.g. "on_die_inked": Deepdiver, lit up in the ink view)
function die_has_trigger(_die, _trigger) {
	if (!is_struct(_die) || !variable_struct_exists(_die, "effects") || !is_array(_die.effects)) return false;
	for (var i = 0; i < array_length(_die.effects); i++) {
		var _e = _die.effects[i];
		if (is_struct(_e) && variable_struct_exists(_e, "trigger") && _e.trigger == _trigger) return true;
	}
	return false;
}

/// @func make_die_struct(_amount, _value, _action, _poss, _perm, _name, _desc, _rarity, [_price], [_effects], [_distribution])
/// @desc Always returns a new independent dice struct.
function make_die_struct(_amount, _value, _action, _poss, _perm, _name, _desc, _rarity, _price = 0, _effects = undefined, _distribution = "") {
	if (_effects == undefined) {
		_effects =
		[
			{
				trigger: "",
				modify: function() {
				}
			}
		];
	}
	
	var _col = get_dice_color(_action);
	
    return {
        dice_amount: _amount,			// e.g. 1 for 1dX
        dice_value: _value,				// e.g. 6 for Xd6
        action_type: _action,			// "ATK", "BLK", "HEAL", "X"
        possible_type: _poss,			// or "All"/"None"
        permanence: _perm,				// "base" or "temporary"
		color: _col,
		name: _name,
		description: _desc,
		rarity: _rarity,
		price: _price,
		effects: _effects,
		distribution: _distribution,
		rolled_value: -1,
		reset_at_end_combat: false,		// if not false, at the end of combat, reset to the type of dice defined here
		reset_after_next_roll: false,		// if not false, at the end of combat, reset to the type of dice defined here
		reset_this_turn: false,
		forced_roll: -1,
		roll_twice: false,
		min_roll_bonus: 0,
		selected: false,				// used for dice selection events in the bag
		statistics: {
			times_rolled_this_combat: 0,
			times_played_this_combat: 0,
			roll_history: [],			
		},
		uid: global._die_uid_counter++, // random id assigned to this die
		keywords: [], // keyword names this die has (Coin, Sticky...), the source of truth for keyword rules and icons
    };
	
}

/// @func clone_die(_die_struct, _perm)
function clone_die(_src, _perm)
{
    // Shallow clone of base-level fields
    var c = variable_clone(_src);
	c.built_slot = false; // only the copy that built a slot this turn carries it (it stayed on, so a die padlocked in slot 1 next turn)

    // --- Deep copy effects array (you already do this) ---
    if (variable_struct_exists(c, "effects")) {
		if is_array(c.effects) {
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
    }

    if (variable_struct_exists(c, "statistics") && is_struct(c.statistics)) {
	    var s_src = _src.statistics;

	    var hist_new = [];
	    if (is_array(s_src.roll_history)) {
	        hist_new = array_create(array_length(s_src.roll_history));
	        for (var i = 0; i < array_length(s_src.roll_history); i++) {
	            hist_new[i] = s_src.roll_history[i];
	        }
	    }

	    c.statistics = {
	        times_rolled_this_combat: s_src.times_rolled_this_combat,
	        times_played_this_combat: s_src.times_played_this_combat,
	        roll_history: hist_new
	    };
	}

    // Set permanence override
    c.permanence = _perm;

    return c;
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
	
	return string(amount) + "d" + string(value) +  _bonus + " " + action_type_label(type);
}

/// @func get_dice_output(_die, _slot_num, _die_index, _read_only, _owner)
/// @desc returns the minimum and maximum value of the dice based on ALL keepsakes, dice bonuses, slot bonuses etc.
/// @param _die			The die struct to be calculated from
/// @param _slot_num	The slot number this dice is in
/// @param _die_index	The dice_list index this dice is
/// @param _read_only	Determine whether we are just reading to generate numbers, or actually running the code
/// @param _owner		Whether its player owned or owned by the enemy
function get_dice_output(_die, _slot_num, _die_index, _read_only, _owner, _on_deal = false) {
	// "not in a slot" is always -1 from here on, so dice effects can compare slot_num safely
	if (_slot_num == undefined) _slot_num = -1;
	
	var prev_slot_type = "";
	var slot = undefined;
	var action = "";
	
	if (_slot_num == undefined || _slot_num == -1) {
		// not in a slot yet (in hand, the bag, a shop): preview it as its own type, so type bonuses (Weapon Polish, Might...) show
		action = _die.action_type;
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
		min_roll: 1 + _die.min_roll_bonus,
		max_roll: _die.dice_value,
		_d_amount: 0,
		_die_struct: _die,
		_slot: slot,
		slot_num: _slot_num,
		die_index: _die_index,
		die: _die,
		read_only: _read_only,
		on_deal: _on_deal, // rolled dice: being rolled as it's dealt (read only, but Accurate still rolls twice)
		roll_twice: false,
		repeat_followthrough: false,
		target: _owner,
		weighting: ""
	};

	// Let keepsakes/dice adjust roll range
	combat_trigger_effects("on_roll_die", roll_data);
	
	if (roll_data.min_roll > roll_data.max_roll) roll_data.min_roll = roll_data.max_roll;
	
	return {
		min_roll: roll_data.min_roll,
		max_roll: roll_data.max_roll,
		// a repeated Followthrough (Chainmaster's Anchor) adds the die's own effect once more, not every keepsake's bonus too
		keepsake_dice_bonus_amount: roll_data._d_amount + (roll_data.repeat_followthrough ? (variable_struct_exists(roll_data, "die_effects_added") ? roll_data.die_effects_added : 0) : 0),
		previous_slot_type: roll_data.previous_slot_action_type,
		roll_twice: roll_data.roll_twice,
		weighting: roll_data.weighting
	};
	
}

/// @func die_bonus_breakdown(_die, _slot_num, _die_index)
/// @desc What a die in a slot comes to, source by source (F146), as lines for its tip: what it rolled, then its own
///       effect, each keepsake and each of your buffs or debuffs that changes it, then the slot's bonuses, then the sum.
///       Fires each source on its own read-only copy of get_dice_output's roll data (keep the two in step), so a
///       source's share is what it added. A first-die bonus (the slot's place bonus is one) shows only on its first die.
function die_bonus_breakdown(_die, _slot_num, _die_index) {
	if (!die_has_faces(_die) || _slot_num < 0 || !instance_exists(oCombat)) return "";
	var _slot = oCombat.action_queue[| _slot_num];
	var _make = function(_die, _slot, _slot_num, _die_index) {
		return {
			previous_slot_action_type: (_slot_num > 0) ? oCombat.action_queue[| _slot_num - 1].current_action_type : "",
			action_type: _slot.current_action_type, min_roll: 1 + _die.min_roll_bonus, max_roll: _die.dice_value,
			_d_amount: 0, _die_struct: _die, _slot: _slot, slot_num: _slot_num, die_index: _die_index, die: _die,
			read_only: true, on_deal: false, roll_twice: false, repeat_followthrough: false, target: "player", weighting: ""
		};
	};
	var _face = die_face_total(_die);
	var _lines = ["Rolled " + string(_face)];
	var _sum = _face;
	// its own effect
	var _ctx = _make(_die, _slot, _slot_num, _die_index);
	trigger_die_effects_single(_die, "on_roll_die", _ctx);
	if (_ctx._d_amount != 0) { array_push(_lines, "Its effect " + ((_ctx._d_amount > 0) ? "+" : "") + string(_ctx._d_amount)); _sum += _ctx._d_amount; }
	// each keepsake
	for (var k = 0; k < ds_list_size(oRunManager.keepsakes); k++) {
		var _ks = oRunManager.keepsakes[| k];
		if (is_undefined(_ks.trigger)) continue;
		_ctx = _make(_die, _slot, _slot_num, _die_index);
		_ks.trigger("on_roll_die", _ctx);
		if (_ctx._d_amount != 0) { array_push(_lines, string(_ks.name) + " " + ((_ctx._d_amount > 0) ? "+" : "") + string(_ctx._d_amount)); _sum += _ctx._d_amount; }
	}
	// each of your buffs and debuffs (Might, Balance...)
	for (var b = 0; b < ds_list_size(global.player_debuffs); b++) {
		var _inst = global.player_debuffs[| b];
		var _one = ds_list_create();
		ds_list_add(_one, _inst);
		_ctx = _make(_die, _slot, _slot_num, _die_index);
		_ctx.owner = "player";
		// on_roll_die never counts a buff down (intent_exact_value relies on that too)
		trigger_debuff_list(_one, "on_roll_die", _ctx);
		ds_list_destroy(_one);
		if (_ctx._d_amount != 0) { array_push(_lines, string(_inst.template.name) + " " + ((_ctx._d_amount > 0) ? "+" : "") + string(_ctx._d_amount)); _sum += _ctx._d_amount; }
	}
	// the slot's bonuses: every die's, and the first die's (its place bonus is one: "Slot 2 +1", once per slot)
	for (var i = 0; i < array_length(_slot.bonuses); i++) {
		var _bn = _slot.bonuses[i];
		if (_bn.amount == 0 || (_bn.scope == "first" && _die_index != 0)) continue;
		array_push(_lines, string(_bn.source) + " " + ((_bn.amount > 0) ? "+" : "") + string(_bn.amount));
		_sum += _bn.amount;
	}
	var _out = "";
	for (var l = 0; l < array_length(_lines); l++) _out += ((l == 0) ? "" : "\n") + _lines[l];
	if (array_length(_lines) > 1) _out += "\n= " + string(_sum);
	return _out;
}

/// @func dice_trigger_effects(_event, _data)
/// @desc Fire _event on every die in the action queue (a broadcast: after_roll_die, on_dice_played_to_slot,
///       on_dice_ejected). Each die's effects are owner-only by default here: they fire only when the die the event is
///       about (effect_subject_die) is that die. An effect can set owner_only: false to react to other dice. (T03)
function dice_trigger_effects(_event, _data) {
	for (var s = 0; s < ds_list_size(oCombat.action_queue); s++) {
		var slot = oCombat.action_queue[| s];
		for (var d = 0; d < ds_list_size(slot.dice_list); d++) {
			die_fire_effects(slot.dice_list[| d], _event, _data, true);
		}
	}
}

/// @func trigger_die_effects_single(_die_struct, _event, _data)
/// @desc Fire _event on one die (it is the die the event is about: rolling, sacrificing, dealt, not used).
function trigger_die_effects_single(_die_struct, _event, _data) {
	// a stowaway going off: a barrel rolls out of the hold
	if (_event == "on_not_used" && room == rmCombat && die_has_effect_trigger(_die_struct, "on_not_used")) sfx_play(soBarrel, AUDIO_GROUP.SFX, 0.05, 0.8);
	die_fire_effects(_die_struct, _event, _data, false);
}

/// @func die_fire_effects(_die, _event, _data, _broadcast)
/// @desc The one place a die's effects fire (T03). Sets _data._die_struct_source to the die, and skips an owner-only
///       effect (owner_only: true, or by default in a broadcast) when the event is about another die. Effects can
///       still check uids themselves; that stays harmless.
function die_fire_effects(_die, _event, _data, _broadcast = false) {
	if (!is_struct(_die) || !variable_struct_exists(_die, "effects") || is_undefined(_die.effects)) return;
	// what this die's own effects add to the roll bonus (_d_amount), kept on the context as die_effects_added so
	// keepsakes can tell whether the die's effect actually did something (Chainmaster's Anchor)
	var _before = (variable_struct_exists(_data, "_d_amount") && is_real(_data._d_amount)) ? _data._d_amount : 0;
	var _effs = is_array(_die.effects) ? _die.effects : [_die.effects];
	for (var e = 0; e < array_length(_effs); e++) {
		var eff = _effs[e];
		if (!is_struct(eff) || eff.trigger != _event || !is_callable(eff.modify)) continue;
		var _owner_only = variable_struct_exists(eff, "owner_only") ? eff.owner_only : _broadcast;
		if (_owner_only) {
			var _subject = effect_subject_die(_data);
			if (is_struct(_subject) && variable_struct_exists(_subject, "uid") && _subject.uid != _die.uid) continue;
		}
		_data._die_struct_source = _die; // the die whose effect is firing
		eff.modify(_data);
	}
	if (variable_struct_exists(_data, "_d_amount") && is_real(_data._d_amount)) _data.die_effects_added = _data._d_amount - _before;
}

/// @func effect_subject_die(_data)
/// @desc The die an event is about, from whichever field its context uses (ejected, played, rolled...), or undefined.
function effect_subject_die(_data) {
	var _fields = ["_ejected_die", "_d_struct", "die", "_slot_die", "_die_struct"];
	for (var i = 0; i < array_length(_fields); i++) {
		if (variable_struct_exists(_data, _fields[i]) && is_struct(_data[$ _fields[i]])) return _data[$ _fields[i]];
	}
	return undefined;
}

/// @func die_bottom_edge(_sides, _r)
/// @desc How far below its centre a code-drawn die's lowest edge is (draw_die at radius _r): keyword icons sit centred on it.
function die_bottom_edge(_sides, _r) {
	if (_sides <= 2) return _r * 1.07;
	var _pts = die_shape_points(_sides, _r * 1.07); // the outline
	var _lo = 0;
	for (var i = 0; i < array_length(_pts); i++) _lo = max(_lo, _pts[i][1]);
	return _lo;
}

/// @func draw_dice_keywords(_die_struct, _x, _y, _scale, _alpha, _where)
/// @desc A die's keyword icons (draw_keyword_icon), centred in a row on _x, _y: callers put _y on the die's bottom edge
///       (die_bottom_edge) so the roundels overlap it by half. Only keywords whose icon_on includes _where. Returns
///       where each was drawn: [{ key, x, y, r }].
function draw_dice_keywords(_die_struct, _x, _y, _scale, _alpha = 1.0, _where = "hand") {
    // icons come from the die's keywords list, only those worth an icon _where the die is (the keyword's icon_on)
    var found = [];
    var key_names = variable_struct_get_names(global.keywords);
    for (var k = 0; k < array_length(key_names); k++) {
        var key = key_names[k];
        var _on = variable_struct_exists(global.keywords[$ key], "icon_on") ? global.keywords[$ key].icon_on : [];
        if (!array_contains(_on, _where)) continue;
        if (die_has_keyword(_die_struct, key)) array_push(found, key);
    }

    var _drawn = [];
    if (array_length(found) == 0) return _drawn;

    var icon_x = _x;
    var icon_y = _y;
    var icon_spacing = 33 * _scale; // the roundels (30 px at scale 1) nearly touch
	
	icon_x -= (array_length(found)-1) * icon_spacing / 2;

    for (var i = 0; i < array_length(found); i++) {
        var key = found[i];
        var data = global.keywords[$ key];

        draw_keyword_icon(key, icon_x, icon_y, _scale, _alpha);
        array_push(_drawn, { key: key, x: icon_x, y: icon_y, r: 15 * _scale });

        icon_x += icon_spacing;
    }
    return _drawn;
}

/// @func draw_dice_distribution(_die, _x, _y, [_centered], [_scale], [_paper], [_fit_w])
/// @desc How likely each face of a die is (its core): a bar per face rising from one baseline, the tallest face full
///       height, its number under the line, all on a dark plate so it reads over anything. A face it can't roll is a
///       flat stub with a dimmed number. _y is the bottom of the whole graphic (numbers included), so it sits on top of
///       whatever is below it; _x its left edge, or its centre with _centered. _scale makes it bigger (1: 14px bars).
///       A core's preview (core_preview) shows the core's own shape on a plain d6: keepsakes don't touch it.
///       _fit_w > 0: the bars widen to fill that width (bag cards, F156), whatever the die's size.
function draw_dice_distribution(_die, _x, _y, _centered = false, _scale = 1, _paper = false, _fit_w = -1, _plate = false) {
	var _min_roll = 1;
	var _max_roll = _die.dice_value;
	if (!variable_struct_exists(_die, "core_preview")) {
		var dice_output = get_dice_output(_die, undefined, -1, true, "player");
		_min_roll = dice_output.min_roll;
		_max_roll = dice_output.max_roll;
	}
	var _dist = [];
	define_dice_distributions(_die.distribution, _min_roll, _max_roll, _dist);
	var _n = array_length(_dist);
	if (_n == 0) return;
	var _top = 0;
	for (var i = 0; i < _n; i++) _top = max(_top, _dist[i]);
	if (_top <= 0) _top = 1; // all zero (a squeezed range, B125): flat stubs, not 0/0

	// on paper (the cards) the numbers get more room under the line (Jared, 2026-11-24)
	var _bw = 14 * _scale, _gap = 3 * _scale, _bh = 30 * _scale, _num_h = _paper ? max(22 * _scale, 19) : 15 * _scale, _pad = 5 * _scale; // (paper: the Charter numbers keep a readable strip even on a small graphic)
	// fitted to a width: bars fill it, but never fatter than 36 px (a standard bar, so a d4 and a d6 read the same and
	// a coin's two aren't huge); a d10 or d12 simply gets thinner to stay inside it
	if (_fit_w > 0) { _gap = 4 * _scale; _bw = min((_fit_w - (_n - 1) * _gap) / _n, 36 * _scale); }
	var _w = _n * _bw + (_n - 1) * _gap;
	var _x0 = _centered ? _x - _w / 2 : _x;
	var _base = _y - _pad - _num_h; // the line the bars stand on
	var _bar_col = _paper ? global.ui_col.ink_soft : make_color_rgb(242, 210, 74);

	// on paper, _plate lays a small paper chip under it (the workbench: dice stand on wood, not on a card)
	if (_paper && _plate) ui_paper(_x0 - 10, _base - _bh - 10, _x0 + _w + 10, _y + 6, round(_x * 0.37) + 11, global.ui_col.paper, draw_get_alpha());
	// the plate (on paper there's none: the bars are inked straight onto it)
	if (!_paper) {
		draw_set_alpha(0.85);
		draw_set_color(make_color_rgb(20, 22, 30));
		draw_roundrect_ext(_x0 - _pad, _base - _bh - _pad, _x0 + _w + _pad, _y, 8 * _scale, 8 * _scale, false);
		draw_set_alpha(1);
	}

	draw_set_font((_scale >= 1.4 || _paper) ? ftDescriptions : ftTiny); // the numbers in Charter on paper
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	for (var i = 0; i < _n; i++) {
		var _bx = _x0 + i * (_bw + _gap);
		var _h = (_dist[i] > 0) ? max(3 * _scale, _bh * _dist[i] / _top) : 2 * _scale;
		draw_set_color((_dist[i] > 0) ? _bar_col : (_paper ? global.ui_col.paper_shade : make_color_rgb(90, 90, 100)));
		draw_rectangle(_bx, _base - _h, _bx + _bw - 1, _base, false);
		draw_set_color(_paper ? ((_dist[i] > 0) ? global.ui_col.ink : global.ui_col.paper_shade) : ((_dist[i] > 0) ? c_white : make_color_rgb(110, 110, 120)));
		draw_text(_bx + _bw / 2, _base + _num_h * (_paper ? 0.58 : 0.5) + 1, string(i + _min_roll));
	}
	// the baseline
	draw_set_color(_paper ? global.ui_col.ink : make_color_rgb(150, 150, 160));
	draw_line_width(_x0 - 2 * _scale, _base + 1, _x0 + _w + 2 * _scale, _base + 1, max(1, _scale));
	draw_set_color(c_white);
}

function draw_dice_history(_die, _x, _y, _centered = false) {
	var dice_output = get_dice_output(_die, undefined, -1, true, "player");
			
	var _min_roll = dice_output.min_roll;
	var _max_roll = dice_output.max_roll;
	
	var roll_stats = [];
	var xx = _x;
	var yy = _y;
	
	if (_centered) {
		xx -= ((sprite_get_width(sSmallBar) * _die.dice_value) / 2) - sprite_get_width(sSmallBar) * 0.5;
	}
	
	repeat (_die.dice_value) {
		array_push(roll_stats, 0);
	}
	
	for (var i = 0; i < array_length(_die.statistics.roll_history); i++) {
		roll_stats[_die.statistics.roll_history[i] - _min_roll] += 1;
	}
	
	var max_size = 0;
	var curr_size = 0;
	for (var i = 0; i < array_length(roll_stats); i++) {
		if (curr_size < roll_stats[i]) {
			max_size = roll_stats[i];
			curr_size = roll_stats[i];
		}
	}
	
	for (var i = 0; i < array_length(roll_stats); i++) {
		var bar_height = roll_stats[i]/max_size;
		draw_sprite_ext(sSmallBar, 0, xx, yy, 1, bar_height + 0.2, 0, c_white, 1.0);
		draw_set_font(ftSmall);
		draw_set_halign(fa_center);
		draw_text(xx, yy + 10, string(i + _min_roll));
		xx += sprite_get_width(sSmallBar);
	}
}

/// @func core_alignment_lean()
/// @desc Where the compass leans, for the alignment cores: -1 fully ruthless (alignment 0), 0 even (50), +1 fully merciful (100).
function core_alignment_lean() {
	return clamp((global.player_alignment - 50) / 20, -1, 1); // full lean at 30 and 70 (F242: it was 0 and 100, flat in a normal run)
}

/// @func	define_dice_distributions(_die_dist, _min_roll, _max_roll, _array)
function define_dice_distributions(_die_dist, _min_roll, _max_roll, _array) {
	switch (_die_dist) {
		case "compass":
		case "lodestone":
		// the alignment pair (F151): at 50 every face is even; ruthless (0) leans to the edges, merciful (100) to the middle.
		// Lodestone leans all the way (at the extremes the other faces can't come up); Compass about two-thirds of the way.
		var _lean = core_alignment_lean();
		var _strength = (_die_dist == "lodestone") ? 1 : 0.65;
		for (var d = _min_roll; d <= _max_roll; d++) {
			var _p = (_max_roll > _min_roll) ? (d - _min_roll) / (_max_roll - _min_roll) : 0.5;
			var _middle = 1 - abs(2 * _p - 1); // 1 in the middle, 0 at the edges
			array_push(_array, max(0, round(10 + 10 * _strength * _lean * (2 * _middle - 1))));
		}
		break;

		case "":		
		// by default each array is [1, 1, 1, 1] for a d4 for example
		for (var d = _min_roll; d <= _max_roll; d++) {
			array_push(_array, 1);
		}
		break;
				
		case "weighted":		
		// array is [3, 4, 5, 6] for a d4
		for (var d = _min_roll; d <= _max_roll; d++) {
			array_push(_array, _max_roll - 2 + d);
		}
		break;
				
		case "loaded":		
		// array is [1, 2, 3, 4] for a d4
		for (var d = _min_roll; d <= _max_roll; d++) {
			array_push(_array, d);
		}
		break;
				
		case "edge":		
		// array is [8, 1, 1, 8] for a d4
		for (var d = _min_roll; d <= _max_roll; d++) {
			if (d == _min_roll) || (d == _max_roll) {
				array_push(_array, 7);
			} else {
				array_push(_array, 2);
			}
		}
		break;
				
		case "binary":		
		// array is [1, 0, 0, 1] for a d4 
		for (var d = _min_roll; d <= _max_roll; d++) {
			if (d == _min_roll) || (d == _max_roll) {
				array_push(_array, 1);
			} else {
				array_push(_array, 0);
			}
		}
		break;
				
		case "bell":		
		// array is [1, 2, 4, 8, 8, 4, 2, 1] for a d8; shaped over the die's own range (B163: a raised min tipped it low)
		for (var d = _min_roll; d <= _max_roll; d++) {
			var _k = d - _min_roll, _rn = _max_roll - _min_roll;
			var val = (_k <= _rn / 2) ? power(2, _k) : power(2, _rn - _k);
			array_push(_array, val);
		}
		break;
				
		case "dome":		
		// array is [0, 1, 3, 9, 9, 3, 1, 0] for a d8; shaped over the die's own range (B163)
		for (var d = _min_roll; d <= _max_roll; d++) {
			var _k = d - _min_roll, _rn = _max_roll - _min_roll;
			var val;
			if (_k == 0 || _k == _rn) val = 0;
			else val = (_k <= _rn / 2) ? power(3, _k - 1) : power(3, _rn - _k - 1);
			array_push(_array, val);
		}
		break;		
				
		case "odd":		
		// array is [1, 0, 1, 0] for a d4
		for (var d = _min_roll; d <= _max_roll; d++) {
			if (d mod 2 == 1) {
				array_push(_array, 3);
			} else {
				array_push(_array, 1);
			}
		}
		break;	
				
		case "even":		
		// array is [1, 0, 1, 0] for a d4
		for (var d = _min_roll; d <= _max_roll; d++) {
			if (d mod 2 == 1) {
				array_push(_array, 1);
			} else {
				array_push(_array, 3);
			}
		}
		break;	
				
		case "dual":		
		// array is [1, 3, 1, 1, 3, 1] for a d6
		for (var d = _min_roll; d <= _max_roll; d++) {
			if (d ==  _min_roll + 1 || d == _max_roll - 1) {
				array_push(_array, 3);
			} else {
				array_push(_array, 1);
			}
		}
		break;	
				
		case "tower":		
		// array is [0, 1, 0, 0, 1, 0] for a d6
		for (var d = _min_roll; d <= _max_roll; d++) {
			if (d ==  _min_roll + 1 || d == _max_roll - 1) {
				array_push(_array, 1);
			} else {
				array_push(_array, 0);
			}
		}
		break;
	}
}

function get_dice_color(_action) {
	
	if (string_pos(" ", _action) > 0) {
		var attack_type_colours = {
		    "ATK":  global.color_attack,
		    "BLK":  global.color_block,
		    "HEAL": global.color_heal,
			"INTEL": global.color_intel,
		};

		// --- Split the incoming type string
		var parts = string_split(_action, " ");
		var total = array_length(parts);

		// --- Collect valid colours
		var colours = [];
		var count = 0;

		for (var i = 0; i < total; i++) {
		    var token = string_upper(parts[i]);

		    if (variable_struct_exists(attack_type_colours, token)) {
		        array_push(colours, attack_type_colours[$ token]);
		        count++;
		    }
		}

		// a multitype die is drawn split diagonally in its colours (die_colours); one colour stands for it in text and
		// particles: its first type's (it used to pulse between them)
		if (count == 0) return c_white;
		return colours[0];
	} else {
		var _col;
		switch (_action) {
			case "ATK": _col = global.color_attack; break;
			case "BLK": _col = global.color_block; break;
			case "HEAL": _col = global.color_heal; break;
			case "INTEL": _col = global.color_intel; break;
		
			default: _col = variable_global_exists("ui_col") ? global.ui_col.bone : c_ltgray; // neutral dice: bone
		}
		return _col;
	}
}

/// @func die_colours(_possible_type)
/// @desc A die's colours for drawing: one for a single type, one per type for a multitype die ("ATK INTEL": attack red
///       and insight yellow), which draw_die and draw_die_shape split diagonally. An array.
function die_colours(_possible_type) {
	if (string_pos(" ", _possible_type) == 0) return [get_dice_color(_possible_type)];
	var _out = [];
	var _parts = string_split(_possible_type, " ");
	for (var i = 0; i < array_length(_parts); i++) {
		var _p = string_upper(_parts[i]);
		if (_p == "ATK" || _p == "BLK" || _p == "HEAL" || _p == "INTEL") array_push(_out, get_dice_color(_p));
	}
	if (array_length(_out) == 0) array_push(_out, get_dice_color(_possible_type));
	return _out;
}

/// @func colours_merge(_col, _to, _amount)
/// @desc merge_colour for a colour or an array of colours (die_colours): each one merged the same way.
function colours_merge(_col, _to, _amount) {
	if (!is_array(_col)) return merge_colour(_col, _to, _amount);
	var _out = [];
	for (var i = 0; i < array_length(_col); i++) array_push(_out, merge_colour(_col[i], _to, _amount));
	return _out;
}

/// @func draw_split_polygon(_x, _y, _pts, _cols, _angle)
/// @desc A convex polygon (_pts around 0,0, [x, y] each) filled in diagonal bands, one per colour, the split running
///       from bottom left to top right (first colour top left), turned with the shape by _angle. Clips each band out of
///       the polygon (two half-planes) and fans it.
function draw_split_polygon(_x, _y, _pts, _cols, _angle) {
	var _n = array_length(_cols);
	// how far along the diagonal each corner is (x + y: top left is low)
	var _lo = infinity, _hi = -infinity;
	for (var i = 0; i < array_length(_pts); i++) { var _d = _pts[i][0] + _pts[i][1]; _lo = min(_lo, _d); _hi = max(_hi, _d); }
	var _c = dcos(_angle), _s = dsin(_angle);
	for (var b = 0; b < _n; b++) {
		var _a0 = (b == 0) ? -infinity : lerp(_lo, _hi, b / _n);
		var _a1 = (b == _n - 1) ? infinity : lerp(_lo, _hi, (b + 1) / _n);
		var _poly = _pts;
		// keep x + y >= _a0, then x + y <= _a1
		for (var side = 0; side < 2; side++) {
			var _lim = (side == 0) ? _a0 : _a1;
			if (abs(_lim) == infinity) continue;
			var _clip = [];
			var _m = array_length(_poly);
			for (var i = 0; i < _m; i++) {
				var _p = _poly[i], _q = _poly[(i + 1) mod _m];
				var _dp = (_p[0] + _p[1] - _lim) * ((side == 0) ? 1 : -1);
				var _dq = (_q[0] + _q[1] - _lim) * ((side == 0) ? 1 : -1);
				if (_dp >= 0) array_push(_clip, _p);
				if ((_dp >= 0) != (_dq >= 0)) {
					var _t = _dp / (_dp - _dq);
					array_push(_clip, [lerp(_p[0], _q[0], _t), lerp(_p[1], _q[1], _t)]);
				}
			}
			_poly = _clip;
		}
		var _k = array_length(_poly);
		if (_k < 3) continue;
		draw_set_color(_cols[b]);
		draw_primitive_begin(pr_trianglelist);
		for (var i = 1; i < _k - 1; i++) {
			var _v = [_poly[0], _poly[i], _poly[i + 1]];
			for (var j = 0; j < 3; j++) draw_vertex(_x + _v[j][0] * _c + _v[j][1] * _s, _y - _v[j][0] * _s + _v[j][1] * _c);
		}
		draw_primitive_end();
	}
}

function get_dice_index(_value) {
	var _index = _value/2 - 1;

	return _index;
}

/// @func die_has_keyword(_die, _keyword)
/// @desc Does this die have the keyword? Reads the die's keywords list (case doesn't matter), never its description.
function die_has_keyword(_die, _keyword) {
	if (!is_struct(_die) || !variable_struct_exists(_die, "keywords")) return false;
	var _wanted = string_lower(_keyword);
	for (var i = 0; i < array_length(_die.keywords); i++) {
		if (string_lower(_die.keywords[i]) == _wanted) return true;
	}
	return false;
}

/// @func die_add_keyword(_die, _keyword)
/// @desc Give a die a keyword (an upgrade, Friendship Bracelet...). Adds it to the die's keywords and to the
///       front of its description, so the rules, the icons and the text all agree.
function die_add_keyword(_die, _keyword) {
	if (die_has_keyword(_die, _keyword)) return;
	array_insert(_die.keywords, 0, _keyword);
	_die.description = _keyword + ". " + _die.description;
}


/// @func die_description(_die)
/// @desc The text to show for a die. Descriptions can hold its numbers as tokens, filled in from the die
///       as it is now, so the text stays right after an upgrade: {min} and {max} (its lowest and highest
///       roll), {min2} and {max2} (double them) and {half} (half its highest roll).
function die_description(_die) {
	var _text = _die.description;
	if (string_pos("{", _text) == 0) return _text;
	
	var _max = _die.dice_value;
	var _min = min(1 + _die.min_roll_bonus, _max);
	_text = string_replace_all(_text, "{min2}", string(_min * 2));
	_text = string_replace_all(_text, "{max2}", string(_max * 2));
	_text = string_replace_all(_text, "{half}", string(floor(_max / 2)));
	_text = string_replace_all(_text, "{min}", string(_min));
	_text = string_replace_all(_text, "{max}", string(_max));
	return _text;
}

/// @func die_remove_keyword(_die, _keyword)
/// @desc Take a keyword off a die, and its "Keyword. " sentence off the front of its description if it has one.
function die_remove_keyword(_die, _keyword) {
	for (var i = array_length(_die.keywords) - 1; i >= 0; i--) {
		if (string_lower(_die.keywords[i]) == string_lower(_keyword)) array_delete(_die.keywords, i, 1);
	}
	var _prefix = _keyword + ". ";
	if (string_pos(_prefix, _die.description) == 1) _die.description = string_delete(_die.description, 1, string_length(_prefix));
}

/// @func die_size_changed(_die)
/// @desc Call after anything changes a die's size (Hammer, Cutters, events, Artisan's Ember...).
///       A die is a coin exactly when it is a d2, so the Coin keyword (rules, icon, text) follows its size.
///       Its description's numbers need nothing: die_description reads the size when shown.
function die_size_changed(_die) {
	if (_die.dice_value == 2) die_add_keyword(_die, "Coin");
	else die_remove_keyword(_die, "Coin"); // upgraded past a d2, it's no longer a coin (the Doubloon too)
}

/// @func action_type_label(_type)
/// @desc An action type as the player reads it. Intel is called Insight on screen; the code keeps "INTEL".
function action_type_label(_type) {
	// full words, never the code's short names (Jared, 2026-11-23: no BLK or ATK in front of players); a multitype
	// die's types read "Attack or Ink"
	var _parts = string_split(string(_type), " ");
	var _out = "";
	for (var i = 0; i < array_length(_parts); i++) {
		var _w = _parts[i];
		switch (_w) {
			case "ATK": _w = "Attack"; break;
			case "BLK": _w = "Block"; break;
			case "HEAL": _w = "Heal"; break;
			case "INTEL": case "INK": _w = "Ink"; break;
			case "None": _w = "Generic"; break;
		}
		if (_w == "") continue;
		_out += ((_out == "") ? "" : " or ") + _w;
	}
	return _out;
}

/// @func core_preview_die()
/// @desc A plain d6 used to preview a core's distribution (set its .distribution). Marked so keepsakes and slot
///       bonuses never change the preview (draw_dice_distribution).
function core_preview_die() {
	var _d = clone_die(global.dice_d6_atk, "");
	_d.possible_type = "None";
	_d.action_type = "None";
	_d.core_preview = true;
	return _d;
}

// =====================================================================
// DICE DRAWN IN CODE (rolled dice prototype): a shape per size and real pips
// =====================================================================

/// @func die_shape_points(_sides, _r)
/// @desc The corners of a die's outline around (0,0), radius _r: d4 a triangle, d6 a square, d8 a diamond, d10 a
///       pentagon, d12 a hexagon (a coin is a circle, no points). An array of [x, y].
function die_shape_points(_sides, _r) {
	var _n = 4, _start = 45, _rr = _r;
	switch (_sides) {
		case 4:  _n = 3; _start = -90; _rr = _r * 1.18; break; // a triangle looks small at the same radius
		case 6:  _n = 4; _start = 45;  _rr = _r * 1.08; break;
		case 8:  _n = 4; _start = -90; _rr = _r * 1.15; break;
		case 10: _n = 5; _start = -90; break;
		case 12: _n = 6; _start = -90; break;
		default: _n = 6; _start = -90; break; // anything else: a hexagon
	}
	var _pts = [];
	for (var i = 0; i < _n; i++) {
		var _a = _start + i * 360 / _n;
		array_push(_pts, [lengthdir_x(_rr, -_a), lengthdir_y(_rr, -_a)]);
	}
	// centred on its own box, so a d4 (point up, flat base) sits level with a d6 beside it (Jared, 2026-11-22: d6s sat lower)
	var _off = die_shape_yoff(_sides, _r);
	for (var i = 0; i < _n; i++) _pts[i][1] += _off;
	return _pts;
}

/// @func die_shape_yoff(_sides, _r)
/// @desc How far down die_shape_points moves a shape to centre its box on the die's y. The shape's own centre (where
///       its pips go) moves with it: a d4's is 0.3 of _r below the die's y.
function die_shape_yoff(_sides, _r) {
	switch (_sides) {
		case 4:  return _r * 1.18 * 0.25;            // a triangle point up: from -1.18r to +0.59r
		case 10: return _r * (1 - dcos(36)) / 2;     // a pentagon point up
		default: return 0;                           // squares, diamonds, hexagons: already centred
	}
}

/// @func draw_die_shape(_x, _y, _r, _sides, _col, _angle, _alpha)
/// @desc A die's filled outline (no pips): a circle for a coin, a polygon otherwise. _angle in degrees. _col can be an
///       array of colours (die_colours): a multitype die, split diagonally (draw_split_polygon).
function draw_die_shape(_x, _y, _r, _sides, _col, _angle = 0, _alpha = 1) {
	if (is_array(_col) && array_length(_col) == 1) _col = _col[0];
	draw_set_alpha(_alpha);
	if (is_array(_col)) {
		var _pts = [];
		if (_sides <= 2) { for (var i = 0; i < 28; i++) array_push(_pts, [lengthdir_x(_r, i * 360 / 28), lengthdir_y(_r, i * 360 / 28)]); }
		else _pts = die_shape_points(_sides, _r);
		draw_split_polygon(_x, _y, _pts, _col, _angle);
		draw_set_alpha(1);
		return;
	}
	draw_set_color(_col);
	if (_sides <= 2) {
		draw_circle(_x, _y, _r, false);
	} else {
		var _pts = die_shape_points(_sides, _r);
		var _n = array_length(_pts);
		draw_primitive_begin(pr_trianglelist);
		for (var i = 0; i < _n; i++) {
			var _a = _pts[i], _b = _pts[(i + 1) mod _n];
			draw_vertex(_x, _y);
			draw_vertex(_x + _a[0] * dcos(_angle) + _a[1] * dsin(_angle), _y - _a[0] * dsin(_angle) + _a[1] * dcos(_angle));
			draw_vertex(_x + _b[0] * dcos(_angle) + _b[1] * dsin(_angle), _y - _b[0] * dsin(_angle) + _b[1] * dcos(_angle));
		}
		draw_primitive_end();
	}
	draw_set_alpha(1);
}

/// @func die_pip_layout(_face)
/// @desc Where the pips go for a face, on a grid from -1 to 1: the classic 1-6, then 7-9 filling the 3x3. [] past 9.
function die_pip_layout(_face) {
	switch (_face) {
		case 1: return [[0, 0]];
		case 2: return [[-1, -1], [1, 1]];
		case 3: return [[-1, -1], [0, 0], [1, 1]];
		case 4: return [[-1, -1], [1, -1], [-1, 1], [1, 1]];
		case 5: return [[-1, -1], [1, -1], [0, 0], [-1, 1], [1, 1]];
		case 6: return [[-1, -1], [1, -1], [-1, 0], [1, 0], [-1, 1], [1, 1]];
		case 7: return [[-1, -1], [1, -1], [-1, 0], [0, 0], [1, 0], [-1, 1], [1, 1]];
		case 8: return [[-1, -1], [0, -1], [1, -1], [-1, 0], [1, 0], [-1, 1], [0, 1], [1, 1]];
		case 9: return [[-1, -1], [0, -1], [1, -1], [-1, 0], [0, 0], [1, 0], [-1, 1], [0, 1], [1, 1]];
	}
	return [];
}

/// @func die_is_special(_d)
/// @desc Any die that isn't a starter (common, uncommon or rare): it wears a ring in its rarity colour (draw_die).
function die_is_special(_d) {
	return is_struct(_d) && variable_struct_exists(_d, "rarity") && (_d.rarity == "common" || _d.rarity == "uncommon" || _d.rarity == "rare");
}

/// @func die_look(_d)
/// @desc A die's signature look until it has its own art (F42; Jared picked B+D, 2026-11-20): "ghost" (Invisible:
///       see-through, dashed edge), "echo" (a faint copy behind it), "ink" (Deepdiver: an ink blot), "waves" (Surge),
///       or "". By name, so saved dice get it too. Add one here for a die people mix up.
function die_look(_d) {
	if (!is_struct(_d) || !variable_struct_exists(_d, "name")) return "";
	switch (_d.name) {
		case "Invisible die": return "ghost";
		case "Echo Die": return "echo";
		case "Deepdiver Die": return "ink";
		case "Surge die": return "waves";
	}
	return "";
}

/// @func die_style(_d)
/// @desc A die's style, drawn round it by draw_die: "ink" for ink dice (Jared, 2026-11-22: all dice get one some day; ink
///       first), "" for the rest.
function die_style(_d) {
	if (!is_struct(_d) || !variable_struct_exists(_d, "possible_type")) return "";
	if (_d.possible_type == "INTEL") return "ink";
	return "";
}

/// @func die_slosh(_die, _x, _y)
/// @desc How an ink die's ink lags as it moves: { vx, vy }, smoothed, per die (by uid) in global.die_slosh. A die that
///       jumps (not drawn for a while, or a big leap) starts still.
function die_slosh(_die, _x, _y) {
	if (!variable_global_exists("die_slosh")) global.die_slosh = {};
	if (!is_struct(_die) || !variable_struct_exists(_die, "uid")) return { vx: 0, vy: 0 };
	var _k = string(_die.uid);
	var _s = global.die_slosh[$ _k];
	var _t = current_time;
	if (_s == undefined || _t - _s.t > 200 || point_distance(_s.x, _s.y, _x, _y) > 300) {
		_s = { x: _x, y: _y, vx: 0, vy: 0, t: _t };
		global.die_slosh[$ _k] = _s;
		return _s;
	}
	if (_t - _s.t >= 8) { // once a frame, however many times it's drawn
		var _f = 16 / max(1, _t - _s.t); // per 60fps frame
		_s.vx = lerp(_s.vx, (_x - _s.x) * _f, 0.25);
		_s.vy = lerp(_s.vy, (_y - _s.y) * _f, 0.25);
		_s.x = _x; _s.y = _y; _s.t = _t;
	}
	return _s;
}

/// @func die_ink_blob(_x, _y, _r, _sides, _angle, _alpha, _die, _sl, _mul, _col)
/// @desc The ink die's wet outline as a filled blob at _mul times its radius (1.12 the rim): points round the shape, each
///       pushed out by a ripple and by the slosh (_sl, die_slosh). The ink rim and the rarity ring both use it, so they
///       swell and trail together (Jared, 2026-11-24: the ring used to sit still behind the ink).
function die_ink_blob(_x, _y, _r, _sides, _angle, _alpha, _die, _sl, _mul, _col) {
	var _sp = min(point_distance(0, 0, _sl.vx, _sl.vy), 40);
	var _dx = (_sp > 0.01) ? -_sl.vx / _sp : 0, _dy = (_sp > 0.01) ? -_sl.vy / _sp : 0; // behind it
	var _t = current_time / 1000;
	var _seed = is_struct(_die) && variable_struct_exists(_die, "uid") ? _die.uid * 1.7 : 0;
	// the outline, many points round it, each pushed out by a ripple and by the slosh
	var _base = [];
	if (_sides <= 2) { for (var i = 0; i < 24; i++) array_push(_base, [lengthdir_x(_r * (_mul - 0.02), i * 15), lengthdir_y(_r * (_mul - 0.02), i * 15)]); }
	else {
		var _pts = die_shape_points(_sides, _r * _mul), _n = array_length(_pts);
		for (var i = 0; i < _n; i++) {
			var _p = _pts[i], _q = _pts[(i + 1) mod _n];
			for (var k = 0; k < 6; k++) array_push(_base, [lerp(_p[0], _q[0], k / 6), lerp(_p[1], _q[1], k / 6)]);
		}
	}
	var _cyo = die_shape_yoff(_sides, _r);
	var _far = (_sides == 6) ? 2 : 1; // a d6's body covers most of the rim, so its slosh reaches further out (Jared, 2026-11-22)
	var _m = array_length(_base);
	var _ring = array_create(_m);
	for (var i = 0; i < _m; i++) {
		var _px = _base[i][0], _py = _base[i][1];
		var _len = max(0.001, point_distance(0, _cyo, _px, _py));
		var _nx = _px / _len, _ny = (_py - _cyo) / _len;
		var _rip = (sin(_t * 2.6 + i * 0.9 + _seed) * 0.6 + sin(_t * 4.1 - i * 0.5 + _seed) * 0.4) * _r * 0.06; // a slow swell round it
		var _lag = max(0, _nx * _dx + _ny * _dy) * _sp * _r * 0.012; // the side away from where it's going
		var _push = (_r * 0.03 + _rip) * _far + _lag; // hugs its own edge (Jared: not a border)
		var _ox = _px + _nx * _push, _oy = _py + _ny * _push;
		_ring[i] = [die_rot_x(_x, _ox, _oy, _angle), die_rot_y(_y, _ox, _oy, _angle)];
	}
	var _cx = die_rot_x(_x, 0, _cyo, _angle), _cy = die_rot_y(_y, 0, _cyo, _angle);
	draw_set_alpha(_alpha);
	draw_set_color(_col);
	draw_primitive_begin(pr_trianglelist); // a list, not a fan: the web build is fussy about fans
	for (var i = 0; i < _m; i++) {
		var _q = _ring[(i + 1) mod _m];
		draw_vertex(_cx, _cy);
		draw_vertex(_ring[i][0], _ring[i][1]);
		draw_vertex(_q[0], _q[1]);
	}
	draw_primitive_end();
	draw_set_alpha(1);
	draw_set_color(c_white);
}

/// @func die_style_ink(_x, _y, _r, _sides, _angle, _alpha, _die, [_sl])
/// @desc An ink die's wet edge: an ink rim, rippling, bulging out behind as it moves (the ink sloshing), a few drops
///       trailing when it's quick. Drawn over the black outline, under the body. _sl: its slosh if draw_die already
///       stepped it this frame (die_slosh moves it on each call).
function die_style_ink(_x, _y, _r, _sides, _angle, _alpha, _die, _sl = undefined) {
	if (_sl == undefined) _sl = die_slosh(_die, _x, _y);
	die_ink_blob(_x, _y, _r, _sides, _angle, _alpha, _die, _sl, 1.12, make_color_rgb(62, 70, 124)); // ink, lit a little: it shows against the black outline
	// drops thrown off behind it when it's quick
	var _sp = min(point_distance(0, 0, _sl.vx, _sl.vy), 40);
	if (_sp > 9) {
		var _dx = -_sl.vx / _sp, _dy = -_sl.vy / _sp;
		var _t = current_time / 1000;
		var _seed = is_struct(_die) && variable_struct_exists(_die, "uid") ? _die.uid * 1.7 : 0;
		var _cyo = die_shape_yoff(_sides, _r);
		draw_set_alpha(_alpha);
		draw_set_color(make_color_rgb(62, 70, 124));
		var _drops = min(3, floor(_sp / 6));
		for (var d = 1; d <= _drops; d++) {
			var _dd = _r * (1.15 + d * 0.28);
			var _wob = sin(_t * 6 + d * 2.1 + _seed) * _r * 0.12;
			draw_circle(_x + _dx * _dd - _dy * _wob, _y + _dy * _dd + _dx * _wob + _cyo, max(1.5, _r * (0.13 - d * 0.03)), false);
		}
		draw_set_alpha(1);
		draw_set_color(c_white);
	}
}

/// @func die_rot_x(_x, _px, _py, _angle) / die_rot_y
/// @desc A point on a die (offset _px, _py from its centre) turned by its angle, as draw_die turns its pips.
function die_rot_x(_x, _px, _py, _angle) { return _x + _px * dcos(_angle) + _py * dsin(_angle); }
function die_rot_y(_y, _px, _py, _angle) { return _y - _px * dsin(_angle) + _py * dcos(_angle); }

/// @func draw_die(_x, _y, _r, _sides, _face, _col, [_angle], [_alpha], [_die])
/// @desc A die drawn in code: its shape by size, filled with its type colour (or die_colours, split), a shadow and outline, and _face as pips
///       (1-9; a numeral from 10, or 0). _face -1: not rolled, shows its size ("d6"). _r is about half its width.
///       _die (its struct, optional): a non-starter gets a ring in its rarity colour, and a few dice their signature
///       look (die_look). Pass it wherever a real die is drawn.
function draw_die(_x, _y, _r, _sides, _face, _col, _angle = 0, _alpha = 1, _die = undefined) {
	var _look = die_look(_die);
	var _a0 = _alpha; // the ring and outline stay solid on a see-through die
	if (_look == "ghost") _alpha *= 0.5;

	// echo: a faint copy of itself just behind, up and to the right
	if (_look == "echo") {
		var _ex = die_rot_x(_x, _r * 0.2, -_r * 0.16, _angle), _ey = die_rot_y(_y, _r * 0.2, -_r * 0.16, _angle);
		draw_die_shape(_ex, _ey, _r * 1.07, _sides, make_color_rgb(20, 20, 26), _angle, _alpha * 0.4);
		draw_die_shape(_ex, _ey, _r * 0.95, _sides, _col, _angle, _alpha * 0.4);
	}

	// shadow, (a rarity ring,) outline, body, and a lighter inner face for a little depth
	draw_die_shape(_x + _r * 0.08, _y + _r * 0.12, _r * 1.06, _sides, c_black, _angle, _alpha * 0.35);
	var _ink_sl = (die_style(_die) == "ink") ? die_slosh(_die, _x, _y) : undefined; // stepped once a frame, shared by the ring and the rim
	if (die_is_special(_die)) {
		if (_ink_sl != undefined) { // an ink die: its ring swells and trails with the ink, not still behind it
			die_ink_blob(_x, _y, _r, _sides, _angle, _a0, _die, _ink_sl, 1.3, make_color_rgb(20, 20, 26));
			die_ink_blob(_x, _y, _r, _sides, _angle, _a0, _die, _ink_sl, 1.22, rarity_colour(_die.rarity));
		} else {
			draw_die_shape(_x, _y, _r * 1.3, _sides, make_color_rgb(20, 20, 26), _angle, _a0);
			draw_die_shape(_x, _y, _r * 1.22, _sides, rarity_colour(_die.rarity), _angle, _a0);
		}
	}
	draw_die_shape(_x, _y, _r * 1.07, _sides, make_color_rgb(20, 20, 26), _angle, (_look == "ghost") ? _a0 * 0.35 : _alpha);
	// its style (die_style): over the outline, under the body, so it shows. Ink sloshes.
	if (_ink_sl != undefined) die_style_ink(_x, _y, _r, _sides, _angle, _alpha, _die, _ink_sl);
	draw_die_shape(_x, _y, _r, _sides, colours_merge(_col, c_black, 0.18), _angle, _alpha);
	draw_die_shape(_x, _y - _r * 0.04, _r * 0.86, _sides, _col, _angle, _alpha);
	if (_look != "") die_look_draw(_look, _x, _y, _r, _sides, _col, _angle, _a0);

	// pips (or a number) on the face: light pips on dark colours, dark on light (a split die: by its colours' average)
	var _cols = is_array(_col) ? _col : [_col];
	var _lum = 0;
	for (var c = 0; c < array_length(_cols); c++) _lum += (0.299 * colour_get_red(_cols[c]) + 0.587 * colour_get_green(_cols[c]) + 0.114 * colour_get_blue(_cols[c])) / array_length(_cols);
	var _light = (_lum < 150); // light pips on a dark body
	var _pip_col = _light ? make_color_rgb(250, 248, 240) : make_color_rgb(30, 28, 36);
	var _ring_col = _light ? make_color_rgb(20, 20, 26) : make_color_rgb(250, 248, 240);
	// how far the pips spread: the inside of each shape (a triangle's is small)
	var _spread = _r * 0.42, _cy = 0;
	switch (_sides) {
		case 2:  _spread = _r * 0.36; break;
		case 4:  _spread = _r * 0.27; _cy = _r * 0.02 + die_shape_yoff(4, _r); break; // the triangle's centre (its centroid)
		case 8:  _spread = _r * 0.34; break;
		case 10: _spread = _r * 0.38; _cy = die_shape_yoff(10, _r); break;
	}
	var _pips = (_face >= 1 && _face <= 6) ? die_pip_layout(_face) : []; // pips up to 6, a digit above (Jared, 2026-11-24)
	if (array_length(_pips) > 0) {
		var _pr = max(2, _r * ((_face > 6) ? 0.125 : 0.165) * ((_sides == 4) ? 0.85 : 1)); // chunky enough to count at a glance
		draw_set_alpha(_alpha);
		for (var i = 0; i < array_length(_pips); i++) {
			var _px = _pips[i][0] * _spread, _py = _pips[i][1] * _spread + _cy;
			var _wx = _x + _px * dcos(_angle) + _py * dsin(_angle);
			var _wy = _y - _px * dsin(_angle) + _py * dcos(_angle);
			draw_set_color(_ring_col);
			draw_circle(_wx, _wy, _pr + 1, false);
			draw_set_color(_pip_col);
			draw_circle(_wx, _wy, _pr, false);
		}
		draw_set_alpha(1);
	} else {
		var _txt = (_face < 0) ? "d" + string(_sides) : string(_face);
		draw_set_font((_r >= 30) ? ftBig : ((_r >= 22) ? ftDefault : ftSmall));
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		// the offset to the shape's centre turns with the die (it was added straight down, so a tumbling d4's text
		// drifted off it), and a touch lower: fa_middle centres the font's whole line, digits sit high in it
		var _oy = _cy + string_height(_txt) * 0.07;
		draw_outline_text(_txt, _ring_col, _pip_col, 2, _x + _oy * dsin(_angle), _y + _oy * dcos(_angle), 1, _alpha, _angle);
	}
	draw_set_color(c_white);
}

/// @func die_look_draw(_look, _x, _y, _r, _sides, _col, _angle, _alpha)
/// @desc draw_die's signature looks (die_look), over the body and under the pips. Kept inside the shape's inscribed
///       circle (half the radius for a d4's triangle) so they fit every size.
function die_look_draw(_look, _x, _y, _r, _sides, _col, _angle, _alpha) {
	var _in = (_sides == 4) ? _r * 0.48 : _r * 0.72; // the room inside the shape
	var _cy = ((_sides == 4) ? _r * 0.02 : 0) + die_shape_yoff(_sides, _r);
	switch (_look) {
		case "ghost":
			// a dashed pale edge round it
			var _pts = (_sides <= 2) ? [] : die_shape_points(_sides, _r * 1.07);
			if (_sides <= 2) for (var i = 0; i < 28; i++) array_push(_pts, [lengthdir_x(_r * 1.07, i * 360 / 28), lengthdir_y(_r * 1.07, i * 360 / 28)]);
			draw_set_alpha(_alpha * 0.9);
			draw_set_color(make_color_rgb(235, 232, 220));
			var _n = array_length(_pts), _dash = max(3, _r * 0.22);
			for (var i = 0; i < _n; i++) {
				var _p = _pts[i], _q = _pts[(i + 1) mod _n];
				var _len = point_distance(_p[0], _p[1], _q[0], _q[1]);
				for (var d = 0; d < _len; d += _dash * 1.8) {
					var _t0 = d / _len, _t1 = min(1, (d + _dash) / _len);
					var _ax = lerp(_p[0], _q[0], _t0), _ay = lerp(_p[1], _q[1], _t0), _bx = lerp(_p[0], _q[0], _t1), _by = lerp(_p[1], _q[1], _t1);
					draw_line_width(die_rot_x(_x, _ax, _ay, _angle), die_rot_y(_y, _ax, _ay, _angle), die_rot_x(_x, _bx, _by, _angle), die_rot_y(_y, _bx, _by, _angle), max(1.5, _r * 0.07));
				}
			}
			break;
		case "waves":
			// three white swells across its face
			draw_set_alpha(_alpha * 0.4);
			draw_set_color(c_white);
			for (var row = -1; row <= 1; row++) {
				var _wy = row * _in * 0.5;
				var _half = sqrt(max(0, _in * _in - _wy * _wy));
				var _steps = 10, _px = -_half, _py = _wy + _cy;
				for (var k = 1; k <= _steps; k++) {
					var _nx = -_half + 2 * _half * k / _steps;
					var _ny = _wy + _cy + sin(k / _steps * pi * 3) * _r * 0.07;
					draw_line_width(die_rot_x(_x, _px, _py, _angle), die_rot_y(_y, _px, _py, _angle), die_rot_x(_x, _nx, _ny, _angle), die_rot_y(_y, _nx, _ny, _angle), max(1.5, _r * 0.07));
					_px = _nx; _py = _ny;
				}
			}
			break;
		case "ink":
			// an ink blot in the lower right of its face, with a splash beside it: a wash, not a hole (Jared: too dark)
			draw_set_alpha(_alpha * 0.35);
			draw_set_color(make_color_rgb(40, 52, 96));
			var _bx = _in * 0.45, _by = _in * 0.45 + _cy;
			draw_circle(die_rot_x(_x, _bx, _by, _angle), die_rot_y(_y, _bx, _by, _angle), _in * 0.5, false);
			draw_circle(die_rot_x(_x, _bx - _in * 0.55, _by + _in * 0.1, _angle), die_rot_y(_y, _bx - _in * 0.55, _by + _in * 0.1, _angle), _in * 0.14, false);
			draw_circle(die_rot_x(_x, _bx + _in * 0.05, _by - _in * 0.6, _angle), die_rot_y(_y, _bx + _in * 0.05, _by - _in * 0.6, _angle), _in * 0.1, false);
			break;
	}
	draw_set_alpha(1);
	draw_set_color(c_white);
}

/// @func dice_particle_draw()
/// @desc oDiceParticle Draw: the die flying to the bag (or from a reward), drawn in code like every die (split if
///       multitype; its sprite's scale as the radius).
function dice_particle_draw() {
	if (!variable_instance_exists(id, "die_struct") || !is_struct(die_struct)) { draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, 1.0); return; }
	var _r = 36 * image_xscale;
	draw_die(x, y, _r, die_struct.dice_value, -1, die_colours(die_struct.possible_type), image_angle, 1, die_struct);
}
