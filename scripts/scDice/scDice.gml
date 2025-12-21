// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @func deal_single_die( _can_discard_this_turn )
function deal_single_die( _can_discard_this_turn = true) {
	if (room == rmCombat) {
	    // --- Reshuffle if empty ---
	    if (ds_list_size(global.dice_bag) == 0) {
	        if (ds_list_size(global.discard_pile) > 0) {
	            //show_debug_message("Dice bag empty — reshuffling discard pile!");
	            for (var i = 0; i < ds_list_size(global.discard_pile); i++) {
	                var discard_die = global.discard_pile[| i];
	                var die_copy = clone_die(discard_die, "temporary");
	                ds_list_add(global.dice_bag, die_copy);
	            }
	            ds_list_clear(global.discard_pile);
	        } else {
	            //show_debug_message("No dice left to deal, stopping dealing.");
	            return;
	        }
	    }

	    if (ds_list_size(global.dice_bag) == 0) {
	        //show_debug_message("No dice available after reshuffle — GAME OVER.");
	        game_end();
	        return;
	    }
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
		if (turn_count == 1) {
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
	die_inst.can_discard = _can_discard_this_turn;

    var target = generate_valid_targets(1, 100) [0];
    die_inst.target_x = target[0];
    die_inst.target_y = target[1];

    // Remove from bag
    ds_list_delete(global.dice_bag, index);
	
	return die_inst;
}

function generate_dice_bag() {
	
	global.bag_size = 10;
	
	/// --- Ensure dice lists exist & are empty ---
	global.dice_bag = ds_list_create();
	global.discard_pile = ds_list_create();
	global.sacrifice_list = ds_list_create();
	global.sacrifice_history = ds_list_create();
	global.master_dice_list = ds_list_create(); // used to track 1 instance of each dice type, for offering random rewards

	// Define starter dice structs
	global.dice_all = make_die_struct(1, 4,"None", "All", "", "Multicolor die", "Counts as anything", "starter");
	global.dice_d4_none = make_die_struct(1, 4,"None", "None", "", "Generic die", "Upgrades slots 1d4", "starter");
	//ds_list_add(global.master_dice_list, clone_die(global.dice_d4_none, ""));
	global.dice_d6_atk = make_die_struct(1, 6,"ATK", "ATK", "", "Attack", "Deals 1d6 damage", "starter");
	//ds_list_add(global.master_dice_list, clone_die(global.dice_d6_atk, ""));
	global.dice_d4_atk = make_die_struct(1, 4,"ATK", "ATK", "", "Attack", "Deals 1d4 damage", "starter");
	//ds_list_add(global.master_dice_list, clone_die(global.dice_d4_atk, ""));
	global.dice_d6_blk = make_die_struct(1, 6,"BLK", "BLK", "", "Block", "Blocks 1d6 damage", "starter");
	//ds_list_add(global.master_dice_list, clone_die(global.dice_d6_blk, ""));
	global.dice_d4_blk = make_die_struct(1, 4,"BLK", "BLK", "", "Block", "Blocks 1d4 damage", "starter");
	//ds_list_add(global.master_dice_list, clone_die(global.dice_d4_blk, ""));
	global.dice_d4_intel = make_die_struct(1, 4,"INTEL", "INTEL", "", "Intel", "Provides 1d4 intel", "starter");
	//ds_list_add(global.master_dice_list, clone_die(global.dice_d4_intel, ""));
	
	// Anchor Die: Gain +3 block if not used
	global.die_anchor = make_die_struct(
	    1, 6, "BLK", "BLK", "", "Anchor die",
	    "Stowaway: +5 block if not used.",
		"common",
		60,
	    [
	        {
	            trigger: "on_not_used",
	            modify: function(_context) {
	                oCombat.player_block_amount += 5;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_anchor, ""));
	
	// Slipstream Die: Play 1 extra dice next turn.
	global.die_slipstream = make_die_struct(
	    1, 4, "ATK", "ATK", "", "Slipstream die",
	    "Stowaway: Play 1 extra dice next turn.",
		"common",
		70,
	    [
	        {
	            trigger: "on_not_used",
	            modify: function(_context) {
	                apply_buff(global.player_debuffs, oRunManager.buff_reserve, 1, 1, oRunManager.buff_reserve.remove_next_turn, { source: "player", index: -1 });
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_slipstream, ""));
	
	// Defensive Die: Coin. Favourite. Multitype: Can create HEAL and BLK slo
	global.die_defensive = make_die_struct(
	    1, 2, "HEAL", "HEAL BLK", "", "Defensive coin",
	    "Coin. Favourite. Multitype: Can create HEAL and BLK slots.",
		"rare",
		100,
	    [
	        {
	            trigger: "before_dice_dealt",
	            modify: function(_context) {
	                _context.favourite = true;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_defensive, ""));
	
	// Anchor Die: Gain +3 block if not used
	global.die_tidebreaker = make_die_struct(
	    1, 6, "ATK", "ATK", "", "Tidebreaker die",
	    "Followthrough: If previous slot was BLK, deal +2 damage to attacking rolls.",
		"common",
		80,
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
	ds_list_add(global.master_dice_list, clone_die(global.die_tidebreaker, ""));
	
	// Pretty penny
	global.die_power_penny = make_die_struct(
	    1, 2, "BLK", "BLK", "", "Power penny",
	    "Coin. +1 bonus to this coin for the number of dice in this slot.",
		"common",
		80,
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
	ds_list_add(global.master_dice_list, clone_die(global.die_power_penny, ""));
	
	// Invisible Die
	global.die_invisible = make_die_struct(
	    1, 4, "None", "None", "", "Invisible die",
	    "When Played: draw 1 dice and play +1 dice this turn.",
		"common",
		60,
	    [
	        {
	            trigger: "on_die_played",
	            modify: function(_context) {
					with (oRunManager) {
						deal_single_die();
					}
					oCombat.dice_allowed_this_turn_bonus++;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_invisible, ""));
	
	// Surge Die
	global.die_surge = make_die_struct(
	    1, 4, "BLK", "BLK", "", "Surge die",
	    "+1 bonus to this dice for every subsequent slot.",
		"uncommon",
		70,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					_context._d_amount = ds_list_size(oCombat.action_queue) - 1 - _context.slot_num;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_surge, ""));
	
	// Kill Coin
	global.die_kill_coin = make_die_struct(
	    1, 2, "ATK", "ATK", "", "Kill coin",
	    "Coin. +2 bonus if placed in the last slot in your queue.",
		"uncommon",
		70,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					_context._d_amount = 2 * (ds_list_size(oCombat.action_queue) - 1 == _context.slot_num);
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_kill_coin, ""));
	
	// Tidepusher die
	global.die_tidepusher = make_die_struct(
	    1, 4, "HEAL", "HEAL", "", "Tidepusher die",
	    "Exclusive. If this die rolls a 4, heal 1 more.",
		"rare",
		120,
	    [
	        {
	            trigger: "after_roll_die",
	            modify: function(_context) {
					if (_context._d_amount == 4) {
						_context._d_amount = 5;
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_tidepusher, ""));
	
	// Bulwark die
	global.die_bulwark = make_die_struct(
	    1, 8, "BLK", "BLK", "", "Bulwark die",
	    "Followthrough: If previous slot was block, deal double this die's minimum roll as damage to all enemies.",
		"rare",
		100,
	    [
	        {
	            trigger: "after_roll_die",
	            modify: function(_context) {
					if (_context._p_slot_type == "BLK") {
	                    with (oCombat) {
							// Deal flat damage to all enemies, we have to run this backwards in case any enemies die during this roll
							for (var i = oCombat.enemies_left_this_combat-1; i >= 0 ; i--) {
								process_action(oCombat.room_enemies[| i], 0, _context.min_roll * 2, 0, "player", -1, "ATK", undefined, undefined, 0);
								show_debug_message("Dealing damage to enemy index: " + string(i));
							}
							//show_debug_message("dealing damage to all enemies");
						}
	                }
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_bulwark, ""));
	
	// Bulwark die
	global.die_crescendo = make_die_struct(
	    1, 8, "ATK", "ATK", "", "Crescendo die",
	    "Increase this die's minimum roll by 1 (up to 4) each time it rolls (resets each combat).",
		"rare",
		110,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
	                _context.min_roll = min(_context.max_roll / 2, 1 + _context.die.statistics.times_played_this_combat);
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_crescendo, ""));
	
	// Squall die
	global.die_squall = make_die_struct(
	    1, 6, "None", "None", "", "Squall die",
	    "If this die rolls 5 or higher, draw a die.",
		"common",
		80,
	    [
	        {
	            trigger: "after_roll_die",
	            modify: function(_context) {
					if (_context._d_amount >= 5) {
						with (oRunManager) deal_single_die(false); // deal a dice that can't be discarded this turn
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_squall, ""));
	
	// Reed snap die
	global.die_reed_snap = make_die_struct(
	    1, 4, "BLK", "BLK", "", "Reed snap die",
	    "If this die rolls a 4, gain 2 block.",
		"common",
		60,
	    [
	        {
	            trigger: "after_roll_die",
	            modify: function(_context) {
					if (_context._d_amount == 4) {
						oCombat.player_block_amount += 2;
						var num = spawn_floating_number("player", 1, -1, c_aqua, 1, -1, 0);
						num.x += 20;
						num.y += 10;
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_reed_snap, ""));
	
	// Reed snap die
	global.die_blood_reef = make_die_struct(
	    1, 6, "ATK", "ATK", "", "Blood Reef die",
	    "If this deals damage, gain +2 damage but lose 1 HP.",
		"rare",
		110,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					if (_context.action_type == "ATK") {
						if (!_context.read_only) {
							global.player_hp--;
						}
						_context._d_amount += 2;
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_blood_reef, ""));
	
	// Slipstream Die
	global.die_muzzle = make_die_struct(
	    1, 4, "ATK", "ATK", "", "Muzzle die",
	    "Followthrough: +1 bonus to this dice for every previous slot",
		"uncommon",
		90,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					_context._d_amount = _context.slot_num;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_muzzle, ""));
	
	// Bilge Die
	global.die_bilge = make_die_struct(
	    1, 6, "None", "None", "", "Bilge die",
	    "Sticky. If this roll is even, heal 2.",
		"rare",
		110,
	    [
	        {
	            trigger: "after_roll_die",
	            modify: function(_context) {
					if (_context._d_amount mod 2 == 0) {
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
	ds_list_add(global.master_dice_list, clone_die(global.die_bilge, ""));
	
	// Sticky Die
	global.die_sticky = make_die_struct(
	    1, 4, "None", "None", "", "Sticky die",
	    "Sticky.",
		"uncommon",
		80,
		[]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_sticky, ""));
	
	// Fogcaller Die
	global.die_fogcaller = make_die_struct(
	    1, 4, "BLK", "BLK", "", "Fogcaller Die",
	    "Followthrough: Draw a dice if the previous slot contained a coin.",
		"common",
		70,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					if (_context.slot_num > 0 && !_context.read_only) {
						var prev_slot_list = oCombat.action_queue[| _context.slot_num - 1 ].dice_list;
						var prev_has_coin = false;
					
						for (var i = 0; i < ds_list_size(prev_slot_list); i++) {
							if (string_pos("Coin", string(prev_slot_list[| i].description)) > 0) {
								prev_has_coin = true;
								break;
							}
						}
					
						if (prev_has_coin) {
							with (oRunManager) deal_single_die(false);
						}
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_fogcaller, ""));
	
	// Deepdiver Die
	global.die_deepdiver = make_die_struct(
	    1, 6, "None", "None", "", "Deepdiver Die",
	    "When played: discard all remaining dice in play then draw 2 more.",
		"uncommon",
		80,
	    [
	        {
	            trigger: "on_die_played",
	            modify: function(_context) {
					with (oCombat) {
						_context.dice_object.can_discard = false;
						discard_dice_in_play();
						oCombat.dice_to_deal = 2;
						oCombat.is_dealing_dice = true;
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_deepdiver, ""));
	
	// Inteli Die
	global.die_intelli = make_die_struct(
	    1, 4, "INTEL", "INTEL", "", "Inteli Die",
	    "Gain +1 for each unique action in the action queue",
		"uncommon",
		80,
	    [
	        {
	            trigger: "on_roll_die",
	            modify: function(_context) {
					var type_str = "";
					for (var i = 0; i < ds_list_size(oCombat.action_queue); i++) {
						slot = oCombat.action_queue[| i];
						
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
	    "Multitype. Can create BLK and INTEL slots.",
		"uncommon",
		100,
		[]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_deflect, ""));
	
	global.die_bolster = make_die_struct(
	    1, 4, "BLK", "BLK", "", "Bolster Die",
	    "When sacrificed: gain block equal to double this die’s max value",
		"common",
		80,
	    [
	        {
	            trigger: "on_sacrifice_die",
	            modify: function(_context) {
					oCombat.player_block_amount = _context.die.struct.dice_value*2;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_bolster, ""));
	
	global.die_echo = make_die_struct(
	    1, 4, "None", "None", "", "Echo Die",
	    "When sacrificed: create another copy of this dice in the sacrificed slot",
		"rare",
		90,
	    [
	        {
	            trigger: "on_sacrifice_die",
	            modify: function(_context) {
					_context.duplicate_die = true;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_echo, ""));
	
	global.die_accurate = make_die_struct(
	    1, 4, "ATK", "ATK", "", "Accurate Die",
	    "Rolls itself twice and takes the higher of the two",
		"common",
		70,
	    [
	        {
				trigger: "on_roll_die",
	            modify: function(_context) {
					if (!_context.read_only) {
						_context.roll_twice = true;
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_echo, ""));
	
	global.die_barrel = make_die_struct(
	    1, 6, "BLK", "BLK", "", "Barrel Die",
	    "When sacrificed: generate a random potion",
		"rare",
		100,
	    [
	        {
	            trigger: "on_sacrifice_die",
	            modify: function(_context) {
					var consumable_options = ds_list_create();
					
					generate_item_rewards(consumable_options, global.master_item_list, 1, "consumable");
				
					gain_item(consumable_options[| 0]);
				
					ds_list_destroy(consumable_options);
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_barrel, ""));
	
	global.die_harvest = make_die_struct(
	    1, 6, "BLK", "BLK", "", "Harvest Die",
	    "At the end of combat gain 4 coins for each die in this slot",
		"common",
		85,
	    [
	        {
	            trigger: "on_combat_end",
	            modify: function(_context) {
					var slot_num;
					var amount;
					// loop through all slots
					for (var i = 0; i < ds_list_size(oCombat.action_queue); i++) {
						for (var d = 0; d < ds_list_size(oCombat.action_queue[| i].dice_list); d++) {
							if (oCombat.action_queue[| i].dice_list[| d].name == "Harvest Die") {
								slot_num = i;
								amount = ds_list_size(oCombat.action_queue[| i].dice_list) * 4;
							}
						}
					}
					
					gain_coins(oCombat.slot_positions[| slot_num].x, oCombat.slot_positions[| slot_num].y, amount);
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_harvest, ""));
	
	global.die_lookout = make_die_struct(
	    1, 6, "INTEL", "INTEL", "", "Lookout die",
	    "Stowaway: Gain 3 intel.",
		"common",
		70,
	    [
	        {
	            trigger: "on_not_used",
	            modify: function(_context) {
					var amount = 3;
	                apply_buff(global.player_debuffs, oRunManager.buff_intel, 1, amount, oRunManager.buff_intel.remove_next_turn, { source: "player", index: -1 });
					var num = spawn_floating_number("player", amount, -1, global.color_intel, 1, -1, 0);
					num.x += 20;
					num.y -= 20;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_lookout, ""));
	
	global.die_bouncing = make_die_struct(
	    1, 4, "ATK", "ATK", "", "Bouncing Die",
	    "When this die rolls to deal damage it has a chance to randomly change targets",
		"common",
		70,
	    [
	        {
				trigger: "on_roll_die",
	            modify: function(_context) {
					if (!_context.read_only && _context.action_type == "ATK") {
						// Find random enemy target
						var possible_new_targets = ds_list_create();
						var new_target = undefined;
					
						for (var e = 0; e < ds_list_size(oCombat.room_enemies); e++) {
							if (!oCombat.room_enemies[| e].dead) ds_list_add(possible_new_targets, oCombat.room_enemies[| e]);
						}
					
						new_target = possible_new_targets[| irandom(ds_list_size(possible_new_targets) - 1)];
					
						enemy_target_index = ds_list_find_index(oCombat.room_enemies, new_target);
					
						ds_list_destroy(possible_new_targets);
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_bouncing, ""));
	
	global.die_guerrilla_coin = make_die_struct(
	    1, 2, "INTEL", "INTEL", "", "Guerrilla Die",
	    "When sacrificed, deal damage to a random enemy equal to the amount of intel you have.",
		"common",
		70,
	    [
	        {
				trigger: "on_sacrifice_die",
	            modify: function(_context) {
					var target = irandom(ds_list_size(oCombat.room_enemies) - 1);
					
					with (oCombat) {
						process_action(oCombat.room_enemies[| target], 0, oCombat.player_intel, 0, "player", -1, "ATK");
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_guerrilla_coin, ""));
	
	global.die_radar = make_die_struct(
	    1, 6, "INTEL", "INTEL", "", "Radar die",
	    "When sacrificed, gain 3 intel for the next 2 turns.",
		"common",
		70,
	    [
	        {
	            trigger: "on_sacrifice_die",
	            modify: function(_context) {
					var amount = 3;
	                apply_buff(global.player_debuffs, oRunManager.buff_intel, 2, amount, oRunManager.buff_intel.remove_next_turn, { source: "player", index: -1 });
					var num = spawn_floating_number("player", amount, -1, global.color_intel, 1, -1, 0);
					num.x += 20;
					num.y -= 20;
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_radar, ""));
	
	global.die_offhand = make_die_struct(
	    1, 6, "ATK", "ATK", "", "Offhand die",
	    "Gain 1 might next turn if this dice rolls its minimum value",
		"common",
		60,
	    [
	        {
	            trigger: "after_roll_die",
	            modify: function(_context) {
					if (_context._d_amount == _context.min_roll) {
						apply_buff(global.player_debuffs, oRunManager.buff_might, 1, 1, true, { source: "player", index: -1 });
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_offhand, ""));
	
	global.die_balanced = make_die_struct(
	    1, 6, "BLK", "BLK", "", "Balanced die",
	    "Gain 1 balance next turn if this dice rolls a 3",
		"common",
		60,
	    [
	        {
	            trigger: "after_roll_die",
	            modify: function(_context) {
					if (_context._d_amount == 3) {
						apply_buff(global.player_debuffs, oRunManager.buff_balance, 1, 1, true, { source: "player", index: -1 });
					}
	            }
	        }
	    ]
	);
	ds_list_add(global.master_dice_list, clone_die(global.die_balanced, ""));
	
	
	// Add to bag
	repeat(2)		{ ds_list_add(global.dice_bag, clone_die(global.dice_d4_atk, "")); }
	repeat(2)		{ ds_list_add(global.dice_bag, clone_die(global.dice_d4_blk, "")); }
	repeat(1)		{ ds_list_add(global.dice_bag, clone_die(global.dice_d4_intel, "")); }
	repeat(1)		{ ds_list_add(global.dice_bag, clone_die(global.dice_d6_atk, "")); }
	repeat(1)		{ ds_list_add(global.dice_bag, clone_die(global.dice_d6_blk, "")); }
	
	do { ds_list_add(global.dice_bag, clone_die(global.dice_d4_none, "")); }
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
		statistics: {
			times_rolled_this_combat: 0,
			times_played_this_combat: 0,
			roll_history: [],			
		}
    };
}

/// @func clone_die(_die_struct, _perm)
function clone_die(_src, _perm)
{
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
	
	return string(amount) + "d" + string(value) +  _bonus + " " + string(type);
}

/// @func get_dice_output(_die, _slot_num, _read_only)
/// @desc returns the minimum and maximum value of the dice based on ALL keepsakes, dice bonuses, slot bonuses etc.
/// @param _die	The die struct to be calculated from
/// @param _slot_num	The slot number this dice is in
/// @param _read_only	Determine whether we are just reading to generate numbers, or actually running the code
function get_dice_output(_die, _slot_num, _read_only) {
	
	var prev_slot_type = "";
	var slot = undefined;
	var action = "";
	
	if (_slot_num == undefined || _slot_num == -1) {
		
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
		_slot: slot,
		slot_num: _slot_num,
		die: _die,
		read_only: _read_only,
		roll_twice: false,
		repeat_followthrough: false
	};

	// Let keepsakes/dice adjust roll range
	combat_trigger_effects("on_roll_die", roll_data, _die);
	
	return {
		min_roll: roll_data.min_roll,
		max_roll: roll_data.max_roll,
		keepsake_dice_bonus_amount: roll_data._d_amount * (roll_data.repeat_followthrough + 1), // double the bonuses if we're repeating followthrough
		previous_slot_type: roll_data.previous_slot_action_type,
		roll_twice: roll_data.roll_twice,
	};
	
}

function dice_trigger_effects(_event, _data) {
    // Iterate through all dice currently in play
    for (var s = 0; s < ds_list_size(oCombat.action_queue); s++) {
        var slot = oCombat.action_queue[| s];
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

function draw_dice_keywords(_die_struct, _x, _y, _scale, _alpha = 1.0) {
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
			draw_sprite_ext(sKeywordIcons, data.index, icon_x, icon_y, _scale, _scale, 0, c_white, _alpha);
        }

        icon_x += icon_spacing;
    }
}

function draw_dice_distribution(_die, _x, _y, _centered = false) {
	var dice_output = get_dice_output(_die, undefined, true);
			
	var _min_roll = dice_output.min_roll;
	var _max_roll = dice_output.max_roll;
	
	var distribution_array = [];
	var xx = _x;
	var yy = _y;
	
	if (_centered) {
		xx -= ((sprite_get_width(sSmallBar) * _die.dice_value) / 2) - sprite_get_width(sSmallBar) * 0.5;
	}
	
	define_dice_distributions(_die.distribution, _min_roll, _max_roll, distribution_array);
	
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
		draw_sprite_ext(sSmallBar, 0, xx, yy, 1, bar_height + 0.2, 0, c_white, 1.0);
		draw_set_font(ftSmall);
		draw_set_halign(fa_center);
		draw_text(xx, yy + 10, string(i + _min_roll));
		xx += sprite_get_width(sSmallBar);
	}
}

function draw_dice_history(_die, _x, _y, _centered = false) {
	var dice_output = get_dice_output(_die, undefined, true);
			
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

/// @func	define_dice_distributions(_die_dist, _min_roll, _max_roll, _array)
function define_dice_distributions(_die_dist, _min_roll, _max_roll, _array) {
	switch (_die_dist) {
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
		// array is [1, 2, 4, 8, 8, 4, 2, 1] for a d8
		for (var d = _min_roll; d <= _max_roll; d++) {
			var val;
			if (d <= _max_roll/2) {
				val = power(2, d - 1);
			} else {
				val = power(2, _max_roll - d);
			}
			array_push(_array, val);
		}
		break;
				
		case "dome":		
		// array is [0, 1, 3, 9, 9, 3, 1, 0] for a d8
		for (var d = _min_roll; d <= _max_roll; d++) {
			var val;
			if (d == _min_roll || d == _max_roll) {
				val = 0;
			} else {
				if (d <= _max_roll/2) {
					val = power(3, d - 2);
				} else {
					val = power(3, _max_roll - d - 1);
				}
			}
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

		// --- Fallbacks and Pulsing Blends --------------------------------------

		var blended;

		if (count == 0) {
		    blended = c_white;
		}
		else if (count == 1) {
		    blended = colours[0];
		}
		else {
		    // 2+ colours: pulse through all of them in a loop

		    // Pulse speed (tweak to taste)
		    var spd = 0.006;

		    // Normalized sine wave from 0..1
		    var t = (sin(current_time * spd) + 1) * 0.5;

		    // Index selection: smoothly moves between colour slots
		    // t spreads across (count-1) intervals
		    var pos = t * (count - 1);

		    var index_a = floor(pos);
		    var index_b = min(index_a + 1, count - 1);

		    var local_t = pos - index_a;

		    // Blend between those two colours only
		    blended = merge_colour(colours[index_a], colours[index_b], local_t);
		}
		
		return blended;
	} else {
		var _col;
		switch (_action) {
			case "ATK": _col = global.color_attack; break;
			case "BLK": _col = global.color_block; break;
			case "HEAL": _col = global.color_heal; break;
			case "INTEL": _col = global.color_intel; break;
		
			default: _col = c_white;
		}
		return _col;
	}
}

function get_dice_index(_value) {
	var _index;
	switch (_value) {
		case 2: _index = 2; break;
        case 4: _index = 0; break;
        case 6: _index = 1; break;
		case 8: _index = 3; break;
        default: _index = 0; break;
	}
	return _index;
}