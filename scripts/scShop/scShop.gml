// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function stock_shop() {
	var num_dice = 4;
	var num_consumables = 4;
	var num_keepsakes = 3;
	var num_tools = 1;
	
	shop_dice_options = ds_list_create();
	shop_dice_scale = ds_list_create();
	shop_consumable_options = ds_list_create();
	shop_consumable_scale = ds_list_create();
	shop_keepsake_options = ds_list_create();
	shop_keepsake_scale = ds_list_create();
	shop_tool_options = ds_list_create();
	shop_tool_scale = ds_list_create();
	
	generate_dice_rewards(shop_dice_options, global.master_dice_list, num_dice);
	generate_item_rewards(shop_consumable_options, global.master_item_list, num_consumables);
	generate_keepsake_rewards(shop_keepsake_options, global.shop_keepsake_list, num_keepsakes);
	if (ds_list_size(global.master_tool_list) > 0) {
		generate_tool_rewards(shop_tool_options, global.master_tool_list, num_tools);
	}
	
	repeat(num_dice) ds_list_add(shop_dice_scale, 0.1);
	repeat(num_consumables) ds_list_add(shop_consumable_scale, 0.1);
	repeat(num_keepsakes) ds_list_add(shop_keepsake_scale, 0.1);
	repeat(num_tools) ds_list_add(shop_tool_scale, 0.1);
}

/// @func generate_dice_rewards(_reward_list, _item_list, _num)
function generate_dice_rewards(_reward_list, _item_list, _num, _rarity = "all", _filter = "all") {
	show_debug_message("Generating dice rewards");
	
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
	
	if (room == rmCombat) {
		if (oCombat.all_enemies_spared || oWorldManager.current_node_type == NODE_TYPE.ALIGNMENT) {
			uncommon_dice_chance = 200;
			rare_dice_chance = 200;
		}
	}
	
	if (room == rmBounty) {
		uncommon_dice_chance = 200;
		rare_dice_chance = 100;
	}
	
	if (room == rmShop) {
		uncommon_dice_chance = 80;
		rare_dice_chance = 20;
	}

	// pick up to 3 unique entries
	var num_rewards = _num;
			
	// used for deduping and storing what dice we used
	var die_1 = clone_die(global.dice_all, "");
	var die_2 = clone_die(global.dice_all, "");

	do {
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
				
			if (die_struct != die_1 && die_struct != die_2) {
				switch (_filter) {
					case "coin":
						if (die_struct.dice_value != 2) {
							continue;
						} else {
							if (ds_list_size(_reward_list) == 0) die_1 = die_struct;
							if (ds_list_size(_reward_list) == 1) die_2 = die_struct;
				
							ds_list_add(_reward_list, clone_die(die_struct, ""));
						}
					break;
					
					default:
						if (ds_list_size(_reward_list) == 0) die_1 = die_struct;
						if (ds_list_size(_reward_list) == 1) die_2 = die_struct;
				
						ds_list_add(_reward_list, clone_die(die_struct, ""));
					break;
				}
			}
			continue;
		} else if (chance <= uncommon_dice_chance) {
			var uncommon_index = irandom(ds_list_size(indices_dice_uncommon)-1);
			var die_struct = indices_dice_uncommon[| uncommon_index ];
				
			if (die_struct != die_1 && die_struct != die_2) {
				switch (_filter) {
					case "coin":
						if (die_struct.dice_value != 2) {
							continue;
						} else {
							if (ds_list_size(_reward_list) == 0) die_1 = die_struct;
							if (ds_list_size(_reward_list) == 1) die_2 = die_struct;
				
							ds_list_add(_reward_list, clone_die(die_struct, ""));
						}
					break;
					
					default:
						if (ds_list_size(_reward_list) == 0) die_1 = die_struct;
						if (ds_list_size(_reward_list) == 1) die_2 = die_struct;
				
						ds_list_add(_reward_list, clone_die(die_struct, ""));
					break;
				}
			}

			continue;
		} else if (chance <= common_dice_chance) {
			var common_index = irandom(ds_list_size(indices_dice_common)-1);
			var die_struct = indices_dice_common[| common_index ];
				
			if (die_struct != die_1 && die_struct != die_2) {
				switch (_filter) {
					case "coin":
						if (die_struct.dice_value != 2) {
							continue;
						} else {
							if (ds_list_size(_reward_list) == 0) die_1 = die_struct;
							if (ds_list_size(_reward_list) == 1) die_2 = die_struct;
				
							ds_list_add(_reward_list, clone_die(die_struct, ""));
						}
					break;
					
					default:
						if (ds_list_size(_reward_list) == 0) die_1 = die_struct;
						if (ds_list_size(_reward_list) == 1) die_2 = die_struct;
				
						ds_list_add(_reward_list, clone_die(die_struct, ""));
					break;
				}
			}
					
			continue;
		}
	}
	until (ds_list_size(_reward_list) == num_rewards);

	// clean up lists
	ds_list_destroy(indices_dice_common);
	ds_list_destroy(indices_dice_uncommon);
	ds_list_destroy(indices_dice_rare);
}

function generate_item_rewards(_reward_list, _item_list, _num, _filter = "none", _rarity = "all") {
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
	
	if (room == rmCombat && oCombat.all_enemies_spared) {
		uncommon_item_chance = 200;
		rare_item_chance = 150;
	}
	
	if (room == rmShop) {
		uncommon_item_chance = clamp(80 + (round(global.player_luck - 50)/2), 10, 200);
		rare_item_chance = clamp(20 + (round(global.player_luck - 50)/5), 1, 200);
	}

	// pick up to 3 unique entries
	var num_rewards = _num;

	do {
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
			var item_struct = indices_items_common[| irandom(ds_list_size(indices_items_common)-1) ];
			if (item_struct.name == "Coins") {
				if (room == rmShop || room = rmEvent) { // we don't want to generate coins as a reward in shops or events
					continue;
				} else {
					item_struct.amount = irandom_range(12, 15);
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
	until (ds_list_size(_reward_list) == num_rewards);
	
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
		ds_list_add(indices_keepsakes, clone_keepsake(_keepsake_list[| i]));
	}

	// shuffle to randomize order
	ds_list_shuffle(indices_keepsakes);

	// pick up to 3 unique entries
	var num_rewards = _num;

	do {
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
		ds_list_add(_reward_list, clone_keepsake(keepsake_struct));
		ds_list_delete( indices_keepsakes, ds_list_find_index( indices_keepsakes, keepsake_struct));
		continue;  
	}
	until (ds_list_size(_reward_list) == num_rewards);
	
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

	do {		
		var rand_index = irandom(ds_list_size(indices_tools)-1);
		
		var tool_struct = indices_tools[| rand_index];
		ds_list_add(_reward_list, tool_struct);
		ds_list_delete( indices_tools, ds_list_find_index( indices_tools, tool_struct));
		
		continue;  
	}
	until (ds_list_size(_reward_list) == num_rewards);
	
	ds_list_destroy(indices_tools);
}

/// @func clone_keepsake(_item_struct)
function clone_keepsake(_src)
{
    var c = variable_clone(_src); // shallow clone of base-level fields

    return c;
}