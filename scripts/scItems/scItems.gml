// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function define_items() {
	global.master_item_list = ds_list_create();
	
	item_coins = {
		sprite: sCoin,
		index: 0,
		name: "Coins",
		description: "Spend in shops.",
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
		description: "Rolls high more often.",
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
		description: "Rolls high much more often.",
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
		description: "Mostly rolls its minimum or maximum.",
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
		description: "Only rolls its minimum or maximum.",
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
		description: "Rolls middle values more often.",
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
		name: "Dome Core",
		description: "Nearly always rolls middle values.",
		type: "core",
		dragging: false,
		distribution: "dome",
		taken: false,
		amount: 1,
		rarity: "rare",
		price: 75
	}
	ds_list_add(global.master_item_list, clone_item(item_core_dome));
	
	// the alignment pair (F151, 2026-11-19), in Odd and Even's place (parity barely moved a die): your compass shapes
	// the roll, read live as it rolls (core_alignment_lean)
	item_core_odd = {
		sprite: sCores,
		index: 6,
		name: "Compass Core",
		description: "The lower your alignment, the more it rolls its lowest or highest. The higher, the more it rolls its middle.",
		type: "core",
		dragging: false,
		distribution: "compass",
		taken: false,
		amount: 1,
		rarity: "uncommon",
		price: 50
	}
	ds_list_add(global.master_item_list, clone_item(item_core_odd));
	
	item_core_even = {
		sprite: sCores,
		index: 7,
		name: "Lodestone Core",
		description: "At the lowest alignment it only rolls its lowest or highest. At the highest, only its middle.",
		type: "core",
		dragging: false,
		distribution: "lodestone",
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
		description: "Rolls its second highest or lowest more often.",
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
		description: "Only rolls its second highest or lowest.",
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
		description: "Every die in a slot gets +2 this turn.",
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
				// +1 on every die in this slot until the end of this round
				slot_add_bonus(_context._slot, "Rigger's Tonic", 2, 1); // F24: was +1
			}
		},
		price: 25
	}
	ds_list_add(global.master_item_list, clone_item(item_consumable_riggers_tonic));
	
	item_consumable_bilge_purge_flask = {
		sprite: sConsumables,
		index: 1,
		name: "Bilge-Purge Flask",
		description: "Empty a slot. Gain 3 plays this turn.",
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
					throw_error("This slot is empty", "Use it on a slot with dice in it.");
				}
				return dice_exist * oCombat.state == CombatState.PLAYER_INPUT;
			},
			modify: function(_context) {
				// eject dice in this slot
				var num_dice = ds_list_size(_context._slot.dice_list);
				eject_dice_in_slot(_context._slot, oCombat.slot_positions[| _context._ind], true);
				oCombat.dice_allowed_this_turn_bonus += 3; // on top of any other bonus plays this turn
				
				particle_emit( device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "burst", c_aqua);
			}
		},
		price: 25
	}
	ds_list_add(global.master_item_list, clone_item(item_consumable_bilge_purge_flask));
	
	item_consumable_artisans_ember_draught = {
		sprite: sConsumables,
		index: 2,
		name: "Artisan's Ember Draught",
		description: "A random die in your hand gets +4 max roll this combat.",
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
				if (instance_number(oDice) > 0) {
					{ // one die in hand, every die equally likely
						var dice = instance_find(oDice, irandom(instance_number(oDice) - 1));
						dice.scale = 1.5;
						dice.struct.dice_value += 4;
						dice.dice_value += 4;
						die_size_changed(dice.struct);
						dice.struct.reset_at_end_combat = function(_dice) {
							_dice.dice_value -= 4;
							die_size_changed(_dice);
						}
						particle_emit( dice.x, dice.y, "burst", get_dice_color(dice.possible_type));
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
		description: "Gain 1 play per enemy this turn, minimum 2.",
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
				oCombat.dice_allowed_this_turn_bonus += max(2, ds_list_size(oCombat.room_enemies)); // F24: at least 2
				oCombat.dice_played_scale = 1.5;
				particle_emit( device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "burst", c_teal);
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
		description: "Copy a random die in your hand for this combat.",
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
				var dice = instance_find(oDice, irandom(instance_number(oDice) - 1));
				
				dice.scale = 1.5;
						
				var die_struct = clone_die(dice.struct, "");
				die_struct.uid = global._die_uid_counter++; // the copy is its own die

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
						
				particle_emit( die_inst.x, die_inst.y, "burst", get_dice_color(die_inst.possible_type));
			}
		},
		price: 40
	}
	ds_list_add(global.master_item_list, clone_item(item_consumable_mirage_brew));
	
	item_consumable_crows_nest_clarity = {
		sprite: sConsumables,
		index: 5,
		name: "Crow's Nest Clarity",
		description: "Gain 10 ink next turn.",
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
					var amount = 10;
					apply_buff("player", oRunManager.buff_intel, 1, amount, oRunManager.buff_intel.remove_next_turn, { source: "player", index: -1 });
					num = spawn_floating_number("player", amount, -1, global.text_intel, 1, -1, 0);
					num.x += 20;
					num.y -= 20;
					particle_emit( num.x, num.y, "rise", global.text_intel);
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
		description: "Gain 3 Might this turn.",
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
				apply_buff("player", oRunManager.buff_might, 1, 3, false, { source: "player", index: -1 }); // this turn only (2026-11-20; was +3 all fight)
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
		description: "Gain 3 Balance for the rest of combat.",
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
				apply_buff("player", oRunManager.buff_balance, -1, 3, oRunManager.buff_balance.remove_next_turn, { source: "player", index: -1 }, true); // F24: was 2
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
		description: "Draw 4 dice. In combat, gain 1 play.",
		type: "consumable",
		dragging: false,
		distribution: "",
		taken: false,
		amount: 1,
		rarity: "common",
		effects: {
			trigger: "on_clicked",
			flags: function() {
				var dice_exist = false;
				if (room == rmCombat) {
					dice_exist = !oCombat.show_rewards && oCombat.state == CombatState.PLAYER_INPUT;
				} else if (room == rmWorkbench) {
					dice_exist = ds_list_size(global.dice_bag) > 0;
				} else if (room == rmEvent) {
					dice_exist = (instance_number(oDice) != 0);
				}
				return dice_exist;
			},
			modify: function(_context) {
				if (room == rmCombat && instance_exists(oCombat)) oCombat.dice_allowed_this_turn_bonus += 1; // F24: a play for them
				if (room == rmWorkbench) {
					// the free bench (F224) has no hand: 4 random dice from the bag fly onto the table
					repeat (4) if (ds_list_size(global.dice_bag) > 0) workbench_take_die(global.dice_bag[| irandom(ds_list_size(global.dice_bag) - 1)]);
					particle_emit(global.gui.bag_x, global.gui.bag_y, "burst", c_purple);
					return;
				}
				with (oRunManager) {
					dice_to_deal = 4;
					is_dealing_dice = true;
					particle_emit( global.gui.bag_x, global.gui.bag_y, "burst", c_purple);
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
		description: "Heal 40% of your max health.",
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
				var heal_amount = ceil(global.player_max_hp * 0.4); // F24: was 30%
				global.player_hp = min(global.player_max_hp, global.player_hp + heal_amount);
				var _hs = ui_health_spot();
				particle_emit(_hs.x, _hs.y, "burst", c_lime); // where your health is in the top bar
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
	
	c.show_item_delete_confirmation = false;
	c.item_delete_confirmation_scale = 1.0;
	c.item_delete_confirmation_progress = 0;

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
	var first_free_slot = get_first_free_item_slot();
	
	show_debug_message(first_free_slot);
	
	if (first_free_slot != -1) {
		oRunManager.items[first_free_slot] = clone_item(_consumable);
		oRunManager.items_hover_scale[first_free_slot] = 1.2;
		_consumable.taken = true;
	}
	
	return true;
}

/// @func pending_item_draw()
/// @desc oRunManager Draw GUI End: an item you've found with no slot free (oRunManager.pending_item; the wreck, Jared
///       2026-11-22: not turned into Calm water any more). Its card waits mid-screen until you delete an item to make room
///       (it's then taken) or sail past it.
function pending_item_draw() {
	with (oRunManager) {
		if (pending_item == undefined) return;
		if (get_first_free_item_slot() != -1) {
			gain_item(pending_item);
			pending_item = undefined;
			return;
		}
		var _gw = display_get_gui_width(), _gh = display_get_gui_height();
		var _w = 280, _h = item_card_layout(pending_item, _w).h;
		var _cy = _gh / 2 - 20;
		draw_set_font(ftDefault);
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_outline_text("Item slots full", c_black, c_white, 2, _gw / 2, _cy - _h / 2 - 40, 1, 1, 0);
		draw_item_card(pending_item, _gw / 2, _cy, _w, _h, 1, false, false);
		draw_set_font(ftDefault);
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_outline_text("Right-click an item to delete it.", c_black, c_white, 2, _gw / 2, _cy + _h / 2 + 30, 1, 1, 0);
		var _b = ui_primary(_gw / 2, _cy + _h / 2 + 90, 220, 64, "Sail past", true);
		if (_b.click) pending_item = undefined;
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
	}
}

function get_first_free_item_slot() {
	var free_slot = -1;
	
	for (var n = 0; n < array_length(oRunManager.items); n++) {
		if (oRunManager.items[n] == undefined) {
			free_slot = n;
			show_debug_message("free slot: " + string(n));
			break;
		}
	}
	
	return free_slot;
}

function get_item_by_name(_name) {
	// cores renamed in a save from before 2026-11-19 (Odd and Even became the alignment pair)
	if (_name == "Odd Core") _name = "Compass Core";
	if (_name == "Even Core") _name = "Lodestone Core";
    for (var i = 0; i < ds_list_size(global.master_item_list); i++) {
        if (global.master_item_list[| i].name == _name) {
            return global.master_item_list[| i];
        }
    }
    return undefined;
}