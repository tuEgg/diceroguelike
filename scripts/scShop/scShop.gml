// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
#macro SHOP_NUM_DICE 4
#macro SHOP_NUM_CONSUMABLES 4
#macro SHOP_NUM_KEEPSAKES 3
#macro SHOP_NUM_TOOLS 1

/// @desc Fill the shop's shelves. A shop node rolls its stock once, as it is entered (see enter_node),
///       so Continue shows the same shelves. A shop reached any other way (debug menu) rolls fresh stock.
function stock_shop() {
	shop_dice_options = ds_list_create();
	shop_dice_scale = ds_list_create();
	shop_consumable_options = ds_list_create();
	shop_consumable_scale = ds_list_create();
	shop_keepsake_options = ds_list_create();
	shop_keepsake_scale = ds_list_create();
	shop_tool_options = ds_list_create();
	shop_tool_scale = ds_list_create();
	
	var _node = oWorldManager.current_node;
	var _stock = (_node != undefined && variable_struct_exists(_node, "shop_stock") && is_struct(_node.shop_stock)) ? _node.shop_stock : roll_shop_stock();
	
	for (var i = 0; i < array_length(_stock.dice); i++) {
		var _die = get_die_by_name(_stock.dice[i]);
		if (_die != undefined) ds_list_add(shop_dice_options, clone_die(_die, ""));
	}
	for (var i = 0; i < array_length(_stock.items); i++) {
		var _item = get_item_by_name(_stock.items[i]);
		if (_item != undefined) ds_list_add(shop_consumable_options, clone_item(_item));
	}
	for (var i = 0; i < array_length(_stock.keepsakes); i++) {
		var _keepsake = get_keepsake_by_id(_stock.keepsakes[i]);
		if (_keepsake != undefined) ds_list_add(shop_keepsake_options, clone_keepsake(_keepsake));
	}
	for (var i = 0; i < array_length(_stock.tools); i++) {
		var _tool = undefined;
		with (oRunManager) _tool = get_tool_by_name(_stock.tools[i]);
		// only offer a tool that's still for sale (not already owned)
		if (_tool != undefined && ds_list_find_index(global.master_tool_list, _tool) != -1) ds_list_add(shop_tool_options, _tool);
	}
	
	repeat(ds_list_size(shop_dice_options)) ds_list_add(shop_dice_scale, 0.1);
	repeat(ds_list_size(shop_consumable_options)) ds_list_add(shop_consumable_scale, 0.1);
	repeat(ds_list_size(shop_keepsake_options)) ds_list_add(shop_keepsake_scale, 0.1);
	repeat(ds_list_size(shop_tool_options)) ds_list_add(shop_tool_scale, 0.1);
}

/// @desc Roll a shop's stock with the shop's odds and return it as names, which can be saved.
/// @returns {struct} { dice: [die names], items: [item names], keepsakes: [keepsake ids], tools: [tool names] }
function roll_shop_stock() {
	var _stock = { dice: [], items: [], keepsakes: [], tools: [] };
	var _list = ds_list_create();
	
	generate_dice_rewards(_list, global.master_dice_list, SHOP_NUM_DICE, "all", "all", rmShop);
	for (var i = 0; i < ds_list_size(_list); i++) array_push(_stock.dice, _list[| i].name);
	ds_list_clear(_list);
	
	generate_item_rewards(_list, global.master_item_list, SHOP_NUM_CONSUMABLES, "none", "all", rmShop);
	for (var i = 0; i < ds_list_size(_list); i++) array_push(_stock.items, _list[| i].name);
	ds_list_clear(_list);
	
	generate_keepsake_rewards(_list, global.shop_keepsake_list, SHOP_NUM_KEEPSAKES);
	for (var i = 0; i < ds_list_size(_list); i++) array_push(_stock.keepsakes, _list[| i]._id);
	ds_list_clear(_list);
	
	if (ds_list_size(global.master_tool_list) > 0) {
		generate_tool_rewards(_list, global.master_tool_list, SHOP_NUM_TOOLS);
		for (var i = 0; i < ds_list_size(_list); i++) array_push(_stock.tools, _list[| i].name);
	}
	
	ds_list_destroy(_list);
	return _stock;
}

/// @func generate_dice_rewards(_reward_list, _item_list, _num)
/// @param _for_room  roll with the odds of this room (the shop rolls its stock on the map, as you enter it)
function generate_dice_rewards(_reward_list, _item_list, _num, _rarity = "all", _filter = "all", _for_room = room) {
	//show_debug_message("Generating dice rewards");
	
	var total_dice = ds_list_size(_item_list);
	var indices_dice_common = ds_list_create();
	var indices_dice_uncommon = ds_list_create();
	var indices_dice_rare = ds_list_create();
	
	// fill list with all possible indices
	for (var i = 0; i < total_dice; i++) {
		switch (_item_list[| i].rarity) {
			case "common":
			ds_list_add(indices_dice_common, clone_die(_item_list[| i], ""));
			break;
					
			case "uncommon":
			ds_list_add(indices_dice_uncommon, clone_die(_item_list[| i], ""));
			break;
					
			case "rare":
			ds_list_add(indices_dice_rare, clone_die(_item_list[| i], ""));
			break;
		}
	}

	// shuffle to randomize order
	ds_list_shuffle(indices_dice_common);
	ds_list_shuffle(indices_dice_uncommon);
	ds_list_shuffle(indices_dice_rare);
	
	// set rarity likelihood
	var common_dice_chance = 200;
	var uncommon_dice_chance = clamp(40 + (round(global.player_luck - 50)/2), 10, 200);
	var rare_dice_chance = max(1, 1 + (round(global.player_luck - 50))/10);
	
	if (_for_room == rmCombat) {
		if (oCombat.all_enemies_spared || oWorldManager.current_node_type == NODE_TYPE.ALIGNMENT) {
			uncommon_dice_chance = 200;
			rare_dice_chance = 200;
		}
	}
	
	if (_for_room == rmBounty) {
		uncommon_dice_chance = 200;
		rare_dice_chance = 100;
	}
	
	if (_for_room == rmShop) {
		uncommon_dice_chance = 80;
		rare_dice_chance = 20;
	}

	// pick up to 3 unique entries
	var num_rewards = _num;
			
	// used for deduping and storing what dice we used
	var _picked = []; // every die offered so far (B163: only the first two were checked, so a 4th could repeat the 3rd)

	var _attempts = 0; // safety net so an impossible filter can never freeze the game
	do {
		_attempts++;
		if (oRunManager.active_bounty != undefined && oWorldManager.current_node_type == NODE_TYPE.ELITE) {
			if (oRunManager.active_bounty.complete) {
				// third item is always a dice, so add that here
				if (oRunManager.active_bounty.rewards[2] != undefined) {
					ds_list_add(_reward_list, clone_die(oRunManager.active_bounty.rewards[2], ""));
					oRunManager.active_bounty.rewards[2] = undefined;
				
					continue;
				}
			}
		}
		
		// Variable used to check which item to generate
		var chance;
		
		switch (_rarity) {
			case "common":
				// Random number but make common rewards less likely on each subsequent slot
				chance = common_dice_chance;
			break;
			case "uncommon":
				// Random number but make common rewards less likely on each subsequent slot
				chance = uncommon_dice_chance;
			break;
			case "rare":
				// Random number but make common rewards less likely on each subsequent slot
				chance = rare_dice_chance;
			break;
			default:
				chance = irandom_range(1, 200);
			break;
		}
				
		if (chance <= rare_dice_chance) {
			var rare_index = irandom(ds_list_size(indices_dice_rare)-1);
			var die_struct = indices_dice_rare[| rare_index ];
			if (die_struct == undefined) continue; // that rarity pool is empty
				
			if (!array_contains(_picked, die_struct)) {
				switch (_filter) {
					case "coin":
						if (die_struct.dice_value != 2) {
							continue;
						} else {
							array_push(_picked, die_struct);
				
							ds_list_add(_reward_list, clone_die(die_struct, ""));
						}
					break;
					
					default:
						array_push(_picked, die_struct);
				
						ds_list_add(_reward_list, clone_die(die_struct, ""));
					break;
				}
			}
			continue;
		} else if (chance <= uncommon_dice_chance) {
			var uncommon_index = irandom(ds_list_size(indices_dice_uncommon)-1);
			var die_struct = indices_dice_uncommon[| uncommon_index ];
			if (die_struct == undefined) continue; // that rarity pool is empty
				
			if (!array_contains(_picked, die_struct)) {
				switch (_filter) {
					case "coin":
						if (die_struct.dice_value != 2) {
							continue;
						} else {
							array_push(_picked, die_struct);
				
							ds_list_add(_reward_list, clone_die(die_struct, ""));
						}
					break;
					
					default:
						array_push(_picked, die_struct);
				
						ds_list_add(_reward_list, clone_die(die_struct, ""));
					break;
				}
			}

			continue;
		} else if (chance <= common_dice_chance) {
			var common_index = irandom(ds_list_size(indices_dice_common)-1);
			var die_struct = indices_dice_common[| common_index ];
			if (die_struct == undefined) continue; // that rarity pool is empty
				
			if (!array_contains(_picked, die_struct)) {
				switch (_filter) {
					case "coin":
						if (die_struct.dice_value != 2) {
							continue;
						} else {
							array_push(_picked, die_struct);
				
							ds_list_add(_reward_list, clone_die(die_struct, ""));
						}
					break;
					
					default:
						array_push(_picked, die_struct);
				
						ds_list_add(_reward_list, clone_die(die_struct, ""));
					break;
				}
			}
					
			continue;
		}
	}
	until (ds_list_size(_reward_list) == num_rewards || _attempts >= 500);

	// clean up lists
	ds_list_destroy(indices_dice_common);
	ds_list_destroy(indices_dice_uncommon);
	ds_list_destroy(indices_dice_rare);
}

/// @param _for_room  roll with the odds of this room (the shop rolls its stock on the map, as you enter it)
function generate_item_rewards(_reward_list, _item_list, _num, _filter = "none", _rarity = "all", _for_room = room) {
	show_debug_message("Generating item rewards");
	var total_items = ds_list_size(_item_list);
	var indices_items_common = ds_list_create();
	var indices_items_uncommon = ds_list_create();
	var indices_items_rare = ds_list_create();			
			
	// fill list with all possible indices
	for (var i = 0; i < total_items; i++) {
		switch (_item_list[| i].rarity) {
			case "common":
			ds_list_add(indices_items_common, clone_item(_item_list[| i]));
			break;
					
			case "uncommon":
			ds_list_add(indices_items_uncommon, clone_item(_item_list[| i]));
			break;
					
			case "rare":
			ds_list_add(indices_items_rare, clone_item(_item_list[| i]));
			break;
		}
	}

	// shuffle to randomize order
	ds_list_shuffle(indices_items_common);
	ds_list_shuffle(indices_items_uncommon);
	ds_list_shuffle(indices_items_rare);
	
	// set item rarity chance
	var common_item_chance = 200;
	var uncommon_item_chance = clamp(60 + (round(global.player_luck - 50)/2), 10, 200);
	var rare_item_chance = clamp(10 + (round(global.player_luck - 50)/5), 1, 200);
	
	if (_for_room == rmCombat && oCombat.all_enemies_spared) {
		uncommon_item_chance = 200;
		rare_item_chance = 150;
	}
	
	if (_for_room == rmShop) {
		uncommon_item_chance = clamp(80 + (round(global.player_luck - 50)/2), 10, 200);
		rare_item_chance = clamp(20 + (round(global.player_luck - 50)/5), 1, 200);
	}

	// pick up to 3 unique entries
	var num_rewards = _num;

	var _attempts = 0; // safety net so an impossible filter can never freeze the game
	do {
		_attempts++;
		if (oRunManager.active_bounty != undefined) {
			if (oRunManager.active_bounty.complete) {
				// third item is always a dice, so add that here
				if (oRunManager.active_bounty.rewards[0] != undefined) {
					ds_list_add(_reward_list, clone_item(oRunManager.active_bounty.rewards[0]));
					oRunManager.active_bounty.rewards[0] = undefined;
				
					continue;
				}
			}
		}
		
		// Variable used to check which item to generate
		var chance;
		
		switch (_rarity) {
			case "common":
				// Random number but make common rewards less likely on each subsequent slot
				chance = common_item_chance;
			break;
			case "uncommon":
				// Random number but make common rewards less likely on each subsequent slot
				chance = uncommon_item_chance;
			break;
			case "rare":
				// Random number but make common rewards less likely on each subsequent slot
				chance = rare_item_chance;
			break;
			default:
				chance = irandom_range(1, 200 - ds_list_size(_reward_list) * 20 );
			break;
		}
		
		show_debug_message("Rolled item chance is: " + string(chance));
				
		if (chance <= rare_item_chance) {
			var item_struct = indices_items_rare[| irandom(ds_list_size(indices_items_rare)-1) ];
			if (item_struct == undefined) continue; // that rarity pool is empty
			
			show_debug_message("Item struct generated: " + string(item_struct));
			
			switch(_filter) {				
				case "consumable":
					if (item_struct.type != "consumable") {
						continue;
					} else {
						ds_list_add(_reward_list, clone_item(item_struct)); 
						ds_list_delete( indices_items_rare, ds_list_find_index( indices_items_rare, item_struct));
						show_debug_message("Added a rare consumable to the rewards.");
					}
				break;
				
				case "core":
					if (item_struct.type != "core") {
						continue;
					} else {
						ds_list_add(_reward_list, clone_item(item_struct)); 
						ds_list_delete( indices_items_rare, ds_list_find_index( indices_items_rare, item_struct));
						show_debug_message("Added a rare core to the rewards.");
					}
				break;
				
				default:
					ds_list_add(_reward_list, clone_item(item_struct)); 
					ds_list_delete( indices_items_rare, ds_list_find_index( indices_items_rare, item_struct));
					show_debug_message("Added a rare item to the rewards.");
				continue;
			}
		} else if (chance <= uncommon_item_chance) {
			var item_struct = indices_items_uncommon[| irandom(ds_list_size(indices_items_uncommon)-1) ];
			if (item_struct == undefined) continue; // that rarity pool is empty
			switch(_filter) {
				case "consumable":
					if (item_struct.type != "consumable") {
						continue;
					} else {
						ds_list_add(_reward_list, clone_item(item_struct)); 
						ds_list_delete( indices_items_uncommon, ds_list_find_index( indices_items_uncommon, item_struct));
						show_debug_message("Added an uncommon consumable to the rewards.");
					}
				break;
				
				case "core":
					if (item_struct.type != "core") {
						continue;
					} else {
						ds_list_add(_reward_list, clone_item(item_struct)); 
						ds_list_delete( indices_items_uncommon, ds_list_find_index( indices_items_uncommon, item_struct));
						show_debug_message("Added an uncommon core to the rewards.");
					}
				break;
				
				default:
					ds_list_add(_reward_list, clone_item(item_struct)); 
					ds_list_delete( indices_items_uncommon, ds_list_find_index( indices_items_uncommon, item_struct));
					show_debug_message("Added an uncommon item to the rewards.");
				continue;
			}
		} else if (chance <= common_item_chance) {
			// Generate a random item
			var item_struct = indices_items_common[| irandom(ds_list_size(indices_items_common)-1) ];
			if (item_struct == undefined) continue; // that rarity pool is empty
			
			var rand_num_100 = irandom(100);
			var coin_chance = 10;
			
			if (item_struct.name == "Coins" || rand_num_100 < coin_chance) {
				if (_for_room == rmShop || _for_room == rmEvent) { // we don't want to generate coins as a reward in shops or events
					continue;
				} else {
					item_struct = clone_item(oRunManager.item_coins);
					item_struct.amount = irandom_range(30, 45);
				}
			}
			
			switch(_filter) {
				case "consumable":
					if (item_struct.type != "consumable") {
						continue;
					} else {
						ds_list_add(_reward_list, clone_item(item_struct)); 
						ds_list_delete( indices_items_common, ds_list_find_index( indices_items_common, item_struct));
						show_debug_message("Added a common consumable to the rewards.");
					}
				break;
				
				case "core":
					if (item_struct.type != "core") {
						continue;
					} else {
						ds_list_add(_reward_list, clone_item(item_struct)); 
						ds_list_delete( indices_items_common, ds_list_find_index( indices_items_common, item_struct));
						show_debug_message("Added a common core to the rewards.");
					}
				break;
				
				default:
					ds_list_add(_reward_list, clone_item(item_struct)); 
					ds_list_delete( indices_items_common, ds_list_find_index( indices_items_common, item_struct));
					show_debug_message("Added a common item to the rewards.");
				continue;
			}
			continue;
		}
			    
	}
	until (ds_list_size(_reward_list) == num_rewards || _attempts >= 500);
	
	ds_list_destroy(indices_items_common);
	ds_list_destroy(indices_items_uncommon);
	ds_list_destroy(indices_items_rare);
}

function generate_keepsake_rewards(_reward_list, _keepsake_list, _num) {
	show_debug_message("Generating keepsake rewards");
	var total_keepsakes = ds_list_size(_keepsake_list);
	var indices_keepsakes = ds_list_create();		
			
	// fill list with all possible keepsakes
	for (var i = 0; i < total_keepsakes; i++) {
		// never offer a keepsake the player already owns, or the one a completed bounty is about to hand over
		var _candidate = _keepsake_list[| i];
		var _skip = false;
		for (var k = 0; k < ds_list_size(oRunManager.keepsakes); k++) {
			if (oRunManager.keepsakes[| k]._id == _candidate._id) _skip = true;
		}
		if (oRunManager.active_bounty != undefined && oRunManager.active_bounty.complete && oRunManager.active_bounty.rewards[1] != undefined) {
			if (oRunManager.active_bounty.rewards[1]._id == _candidate._id) _skip = true;
		}
		if (_skip) continue;
		
		ds_list_add(indices_keepsakes, clone_keepsake(_keepsake_list[| i]));
	}

	// shuffle to randomize order
	ds_list_shuffle(indices_keepsakes);

	// pick up to 3 unique entries
	var num_rewards = _num;

	var _attempts = 0; // safety net so an impossible filter can never freeze the game
	do {
		_attempts++;
		if (oRunManager.active_bounty != undefined) {
			if (oRunManager.active_bounty.complete) {
				if (oRunManager.active_bounty.rewards[1] != undefined) {
					ds_list_add(_reward_list, clone_keepsake(oRunManager.active_bounty.rewards[1]));
					oRunManager.active_bounty.rewards[1] = undefined;
				
					continue;
				}
			}
		}
		
		var rand_index = irandom(ds_list_size(indices_keepsakes)-1);
		
		var keepsake_struct = indices_keepsakes[| rand_index];
		if (keepsake_struct == undefined) break; // pool has run dry, return what we have
		ds_list_add(_reward_list, clone_keepsake(keepsake_struct));
		ds_list_delete( indices_keepsakes, ds_list_find_index( indices_keepsakes, keepsake_struct));
		continue;  
	}
	until (ds_list_size(_reward_list) == num_rewards || _attempts >= 500);
	
	ds_list_destroy(indices_keepsakes);
}

function generate_tool_rewards(_reward_list, _tool_list, _num) {
	show_debug_message("Generating tool rewards");
	var total_tools = ds_list_size(_tool_list);
	var indices_tools = ds_list_create();
			
	// fill list with all possible keepsakes
	for (var i = 0; i < total_tools; i++) {
		ds_list_add(indices_tools, _tool_list[| i]);
	}

	// shuffle to randomize order
	ds_list_shuffle(indices_tools);

	// pick up to X unique entries
	var num_rewards = _num;

	var _attempts = 0; // safety net so an impossible filter can never freeze the game
	do {
		_attempts++;
		var rand_index = irandom(ds_list_size(indices_tools)-1);
		
		var tool_struct = indices_tools[| rand_index];
		if (tool_struct == undefined) break; // pool has run dry, return what we have
		ds_list_add(_reward_list, tool_struct);
		ds_list_delete( indices_tools, ds_list_find_index( indices_tools, tool_struct));
		
		continue;  
	}
	until (ds_list_size(_reward_list) == num_rewards || _attempts >= 500);
	
	ds_list_destroy(indices_tools);
}

/// @func clone_keepsake(_item_struct)
function clone_keepsake(_src)
{
    var c = variable_clone(_src); // shallow clone of base-level fields

    return c;
}