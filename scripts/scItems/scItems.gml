// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function define_items() {
	global.master_item_list = ds_list_create();
	
	item_coins = {
		sprite: sCoin,
		index: 0,
		name: "Coins",
		description: "Used to buy shit",
		type: "money",
		dragging: false,
		distribution: "",
		taken: false,
		amount: 1,
		rarity: "common",
		price: 0
	}
	ds_list_add(global.master_item_list, clone_item(item_coins));
	
	item_core_weighted = {
		sprite: sCores,
		index: 0,
		name: "Weighted Core",
		description: "Increases the odds of a dice rolling higher numbers",
		type: "core",
		dragging: false,
		distribution: "weighted",
		taken: false,
		amount: 1,
		rarity: "uncommon",
		price: 50
	}
	ds_list_add(global.master_item_list, clone_item(item_core_weighted));

	item_core_loaded = {
		sprite: sCores,
		index: 1,
		name: "Loaded Core",
		description: "Greatly increases the odds of a dice rolling higher numbers",
		type: "core",
		dragging: false,
		distribution: "loaded",
		taken: false,
		amount: 1,
		rarity: "rare",
		price: 75
	}
	ds_list_add(global.master_item_list, clone_item(item_core_loaded));

	item_core_edge = {
		sprite: sCores,
		index: 2,
		name: "Edge Core",
		description: "Dice will roll its minimum or maximum value most of the time",
		type: "core",
		dragging: false,
		distribution: "edge",
		taken: false,
		amount: 1,
		rarity: "uncommon",
		price: 50
	}
	ds_list_add(global.master_item_list, clone_item(item_core_edge));
	
	item_core_binary = {
		sprite: sCores,
		index: 3,
		name: "Binary Core",
		description: "Dice will always roll either its minimum or maximum value",
		type: "core",
		dragging: false,
		distribution: "binary",
		taken: false,
		amount: 1,
		rarity: "rare",
		price: 75
	}
	ds_list_add(global.master_item_list, clone_item(item_core_binary));
	
	item_core_bell = {
		sprite: sCores,
		index: 4,
		name: "Bell Core",
		description: "Dice will roll on a bell curve, emphasising middle values",
		type: "core",
		dragging: false,
		distribution: "bell",
		taken: false,
		amount: 1,
		rarity: "uncommon",
		price: 50
	}
	ds_list_add(global.master_item_list, clone_item(item_core_bell));
	
	item_core_dome = {
		sprite: sCores,
		index: 5,
		name: "Binary Core",
		description: "Dice will nearly always roll their middle values",
		type: "core",
		dragging: false,
		distribution: "dome",
		taken: false,
		amount: 1,
		rarity: "rare",
		price: 75
	}
	ds_list_add(global.master_item_list, clone_item(item_core_dome));
	
	item_core_odd = {
		sprite: sCores,
		index: 6,
		name: "Odd Core",
		description: "Dice will roll odd numbers more often",
		type: "core",
		dragging: false,
		distribution: "odd",
		taken: false,
		amount: 1,
		rarity: "uncommon",
		price: 50
	}
	ds_list_add(global.master_item_list, clone_item(item_core_odd));
	
	item_core_even = {
		sprite: sCores,
		index: 7,
		name: "Even Core",
		description: "Dice will roll even numbers more often",
		type: "core",
		dragging: false,
		distribution: "even",
		taken: false,
		amount: 1,
		rarity: "rare",
		price: 75
	}
	ds_list_add(global.master_item_list, clone_item(item_core_even));
	
	item_core_dual = {
		sprite: sCores,
		index: 8,
		name: "Dual Core",
		description: "Dice will roll their second highest/lowest values more often",
		type: "core",
		dragging: false,
		distribution: "dual",
		taken: false,
		amount: 1,
		rarity: "uncommon",
		price: 50
	}
	ds_list_add(global.master_item_list, clone_item(item_core_dual));
	
	item_core_tower = {
		sprite: sCores,
		index: 9,
		name: "Tower Core",
		description: "Dice will only roll their second highest or lowest values",
		type: "core",
		dragging: false,
		distribution: "tower",
		taken: false,
		amount: 1,
		rarity: "rare",
		price: 75
	}
	ds_list_add(global.master_item_list, clone_item(item_core_tower));
	
	item_consumable_riggers_tonic = {
		sprite: sConsumables,
		index: 0,
		name: "Riggers Tonic",
		description: "Choose a slot to gain +2 on all rolls for next turn",
		type: "consumable",
		dragging: false,
		distribution: "",
		taken: false,
		amount: 1,
		rarity: "common",
		effects: {
			trigger: "on_item_played_to_slot",
			flags: function() {
				var dice_exist = true;
				if (room != rmCombat) {
					dice_exist = false;
				} else if (room == rmCombat && oCombat.show_rewards) {
					dice_exist = false;
				} else {
					dice_exist = true;
				}
				return dice_exist * oCombat.state == CombatState.PLAYER_INPUT;
			},
			modify: function(_context) {
				// give this specific slot +1 to all rolls next turn
				_context._slot.pre_buff_amount = _context._slot.bonus_amount;
				_context._slot.bonus_amount += 2;
				_context._slot.buffed += 1;
			}
		},
		price: 25
	}
	ds_list_add(global.master_item_list, clone_item(item_consumable_riggers_tonic));
	
	item_consumable_bilge_purge_flask = {
		sprite: sConsumables,
		index: 1,
		name: "Bilge-Purge Flask",
		description: "Completely empty a slot, ejecting and discarding all dice within it and gaining that many dice to play this turn.",
		type: "consumable",
		dragging: false,
		distribution: "",
		taken: false,
		amount: 1,
		rarity: "common",
		effects: {
			trigger: "on_item_played_to_slot",
			flags: function(_context) {
				var dice_exist = true;
				if (ds_list_size(_context._slot.dice_list) == 0) {
					dice_exist = false;
					throw_error("This slot is empty", "Try playing this to a slot with dice in it");
				}
				return dice_exist * oCombat.state == CombatState.PLAYER_INPUT;
			},
			modify: function(_context) {
				// eject dice in this slot
				var num_dice = ds_list_size(_context._slot.dice_list);
				eject_dice_in_slot(_context._slot, oCombat.slot_positions[| _context._ind], true);
				oCombat.dice_allowed_this_turn_bonus = num_dice;
				
				particle_emit( mouse_x, mouse_y, "burst", c_aqua);
			}
		},
		price: 25
	}
	ds_list_add(global.master_item_list, clone_item(item_consumable_bilge_purge_flask));
	
	item_consumable_artisans_ember_draught = {
		sprite: sConsumables,
		index: 2,
		name: "Artisan's Ember Draught",
		description: "Upgrade a random dice in play +4 for the rest of combat",
		type: "consumable",
		dragging: false,
		distribution: "",
		taken: false,
		amount: 1,
		rarity: "common",
		effects: {
			trigger: "on_clicked",
			flags: function() {
				var dice_exist = true;
				if (instance_number(oDice) == 0) dice_exist = false;
				if (room != rmCombat) {
					dice_exist = false;
				} else if (room == rmCombat && oCombat.show_rewards) {
					dice_exist = false;
				} else {
					dice_exist = true * oCombat.state == CombatState.PLAYER_INPUT;
				}
				return dice_exist;
			},
			modify: function(_context) {
				// select a random die in play and upgrade it
				var upgrade_chance = instance_number(oDice);
				for (var i = 0; i < upgrade_chance; i++) {
					var n = irandom_range(i, upgrade_chance);
					if (n == upgrade_chance) {
						dice = instance_find(oDice, i);
						dice.scale = 1.5;
						dice.struct.dice_value += 4;
						dice.dice_value += 4;
						dice.struct.reset_at_end_combat = function(_dice) {
							_dice.dice_value -= 4;
						}
						particle_emit( dice.x, dice.y, "burst", get_dice_color((dice.action_type)));
						break;
					}
				}
			}
		},
		price: 40
	}
	ds_list_add(global.master_item_list, clone_item(item_consumable_artisans_ember_draught));
	
	item_consumable_corsairs_gambit = {
		sprite: sConsumables,
		index: 3,
		name: "Corsair's Gambit",
		description: "Gain +1 playable dice this turn for every enemy",
		type: "consumable",
		dragging: false,
		distribution: "",
		taken: false,
		amount: 1,
		rarity: "common",
		effects: {
			trigger: "on_clicked",
			flags: function() {
				var dice_exist = true;
				if (room != rmCombat) {
					dice_exist = false;
				} else if (room == rmCombat && oCombat.show_rewards) {
					dice_exist = false;
				} else {
					dice_exist = true * oCombat.state == CombatState.PLAYER_INPUT;
				}
				return dice_exist;
			},
			modify: function(_context) {
				// select a random die in play and upgrade it
				oCombat.dice_allowed_this_turn_bonus += ds_list_size(oCombat.room_enemies);
				oCombat.dice_played_scale = 1.5;
				particle_emit( mouse_x, mouse_y, "burst", c_teal);
				// when we eventually have multiple enemies, use a loop
				//for (var i = 0; i < num_enemies; i++) {
				//}
			}
		},
		price: 50
	}
	ds_list_add(global.master_item_list, clone_item(item_consumable_corsairs_gambit));
	
	item_consumable_mirage_brew = {
		sprite: sConsumables,
		index: 4,
		name: "Mirage Brew",
		description: "Gain a copy of a random dice in play for the remainder of combat",
		type: "consumable",
		dragging: false,
		distribution: "",
		taken: false,
		amount: 1,
		rarity: "common",
		effects: {
			trigger: "on_clicked",
			flags: function() {
				
				var dice_exist = true;
				
				if (instance_number(oDice) == 0) dice_exist = false;
				if (room != rmCombat) {
					dice_exist = false;
				} else if (room == rmCombat && oCombat.show_rewards) {
					dice_exist = false;
				} else {
					dice_exist = true * oCombat.state == CombatState.PLAYER_INPUT;
				}
				return dice_exist;
			},
			modify: function(_context) {
				// select a random die in play and upgrade it
				var dupe_chance = instance_number(oDice);
				for (var i = 0; i < dupe_chance; i++) {
					var n = irandom_range(i, dupe_chance);
					if (n == dupe_chance) {
						dice = instance_find(oDice, i);
						dice.scale = 1.5;
						
						var die_struct = clone_die(dice.struct, "");

						// Spawn instance
					    var die_inst = instance_create_layer(dice.x + choose(-50,0, 50), dice.y + choose(-50, 50), "Instances", oDice);
					    die_inst.struct = die_struct;
					    die_inst.action_type = die_struct.action_type;
					    die_inst.dice_amount = die_struct.dice_amount;
					    die_inst.dice_value  = die_struct.dice_value;
						die_inst.possible_type = die_struct.possible_type;
						die_inst.can_discard = true;

					    var target = generate_valid_targets(1, 100) [0];
					    die_inst.target_x = target[0];
					    die_inst.target_y = target[1];

						die_inst.struct.reset_at_end_combat = function(_dice) {
							ds_list_delete(global.dice_bag, ds_list_find_index(global.dice_bag, _dice));
						}
						
						particle_emit( die_inst.x, die_inst.y, "burst", get_dice_color((die_inst.action_type)));
						break;
					}
				}
			}
		},
		price: 40
	}
	ds_list_add(global.master_item_list, clone_item(item_consumable_mirage_brew));
	
	item_consumable_crows_nest_clarity = {
		sprite: sConsumables,
		index: 5,
		name: "Crow's Nest Clarity",
		description: "Gain 12 Intel for next turn",
		type: "consumable",
		dragging: false,
		distribution: "",
		taken: false,
		amount: 1,
		rarity: "common",
		effects: {
			trigger: "on_clicked",
			flags: function() {
				var dice_exist = true;
				if (room != rmCombat) {
					dice_exist = false;
				} else if (room == rmCombat && oCombat.show_rewards) {
					dice_exist = false;
				} else {
					dice_exist = true * oCombat.state == CombatState.PLAYER_INPUT;
				}
				return dice_exist
			},
			modify: function(_context) {
				with (oCombat) {
					var amount = 12;
					apply_buff(global.player_debuffs, oRunManager.buff_intel, 1, amount, oRunManager.buff_intel.remove_next_turn, { source: "player", index: -1 });
					num = spawn_floating_number("player", amount, -1, global.color_intel, 1, -1, 0);
					num.x += 20;
					num.y -= 20;
					particle_emit( num.x, num.y, "rise", global.color_intel);
				}
			}
		},
		price: 30
	}
	ds_list_add(global.master_item_list, clone_item(item_consumable_crows_nest_clarity));
	
	item_consumable_grog_of_grit = {
		sprite: sConsumables,
		index: 6,
		name: "Grog of Grit",
		description: "Gain +1 might this turn.",
		type: "consumable",
		dragging: false,
		distribution: "",
		taken: false,
		amount: 1,
		rarity: "common",
		effects: {
			trigger: "on_clicked",
			flags: function() {
				var dice_exist = true;
				if (room != rmCombat) {
					dice_exist = false;
				} else if (room == rmCombat && oCombat.show_rewards) {
					dice_exist = false;
				} else {
					dice_exist = true * oCombat.state == CombatState.PLAYER_INPUT;
				}
				return dice_exist;
			},
			modify: function(_context) {
				apply_buff(global.player_debuffs, oRunManager.buff_might, 1, 1, oRunManager.buff_might.remove_next_turn, { source: "player", index: -1 });
				particle_emit( global.player_x, global.player_y, "rise", c_orange);
			}
		},
		price: 35
	}
	ds_list_add(global.master_item_list, clone_item(item_consumable_grog_of_grit));
	
	item_consumable_captains_brew = {
		sprite: sConsumables,
		index: 7,
		name: "Captain's Brew",
		description: "Gain +1 balance this turn.",
		type: "consumable",
		dragging: false,
		distribution: "",
		taken: false,
		amount: 1,
		rarity: "common",
		effects: {
			trigger: "on_clicked",
			flags: function() {
				var dice_exist = true;
				if (room != rmCombat) {
					dice_exist = false;
				} else if (room == rmCombat && oCombat.show_rewards) {
					dice_exist = false;
				} else {
					dice_exist = true * oCombat.state == CombatState.PLAYER_INPUT;
				}
				return dice_exist;
			},
			modify: function(_context) {
				apply_buff(global.player_debuffs, oRunManager.buff_balance, 1, 1, oRunManager.buff_balance.remove_next_turn, { source: "player", index: -1 });
				particle_emit( global.player_x, global.player_y, "rise", c_blue);
			}
		},
		price: 35
	}
	ds_list_add(global.master_item_list, clone_item(item_consumable_captains_brew));
	
	item_consumable_navigators_brew = {
		sprite: sConsumables,
		index: 8,
		name: "Navigator's Brew",
		description: "Draw 3 dice",
		type: "consumable",
		dragging: false,
		distribution: "",
		taken: false,
		amount: 1,
		rarity: "common",
		effects: {
			trigger: "on_clicked",
			flags: function() {
				var dice_exist = true;
				if (room != rmCombat && room != rmWorkbench) {
					dice_exist = false;
					if (room == rmEvent && instance_number(oDice) != 0) {
						dice_exist = true;
					}
				} else if (room == rmCombat && oCombat.show_rewards) {
					dice_exist = false;
				} else {
					dice_exist = true * oCombat.state == CombatState.PLAYER_INPUT;
				}
				return dice_exist;
			},
			modify: function(_context) {
				with (oRunManager) {
					dice_to_deal = 3;
					is_dealing_dice = true;
					particle_emit( GUI_LAYOUT.BAG_X, display_get_gui_height() - GUI_LAYOUT.BAG_Y, "burst", c_purple);
				}
			}
		},
		price: 35
	}
	ds_list_add(global.master_item_list, clone_item(item_consumable_navigators_brew));
	
	item_consumable_healing_flask = {
		sprite: sConsumables,
		index: 9,
		name: "Healing Flask",
		description: "Heal 16hp",
		type: "consumable",
		dragging: false,
		distribution: "",
		taken: false,
		amount: 1,
		rarity: "common",
		effects: {
			trigger: "on_clicked",
			flags: function() {
				if (global.player_hp < global.player_max_hp) {
					return true;
				} else {
					return false;
				}
			},
			modify: function(_context) {
				global.player_hp = min(global.player_max_hp, global.player_hp + 16);
				particle_emit(650, 25, "burst", c_lime);
			}
		},
		price: 40
	}
	ds_list_add(global.master_item_list, clone_item(item_consumable_healing_flask));
}

/// @func clone_item(_item_struct)
function clone_item(_src)
{
    var c = variable_clone(_src); // shallow clone of base-level fields

    return c;
}

function trigger_item_effects(_item, _event, _data) {
    if (is_undefined(_item.effects)) return;

    if (is_array(_item.effects)) {
        for (var e = 0; e < array_length(_item.effects); e++) {
            var eff = _item.effects[e];
            if (eff.trigger == _event && is_callable(eff.modify)) {
                eff.modify(_data);
            }
        }
    } else {
        var eff = _item.effects;
        if (eff.trigger == _event && is_callable(eff.modify)) {
            eff.modify(_data);
        }
    }
}

function gain_item(_consumable) {
	var first_free_slot = -1;
	for (var n = 0; n < array_length(oRunManager.items); n++) {
		if (oRunManager.items[n] == undefined) {
			first_free_slot = n;
			break;
		}
	}
	if (first_free_slot != -1) {
		oRunManager.items[first_free_slot] = clone_item(_consumable);
		oRunManager.items_hover_scale[first_free_slot] = 1.2;
		_consumable.taken = true;
	}
	
	return true;
}