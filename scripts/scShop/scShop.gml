// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function stock_shop() {
	var num_dice = 4;
	var num_consumables = 3;
	var num_keepsakes = 3;
	
	shop_dice_options = ds_list_create();
	shop_dice_scale = ds_list_create();
	shop_consumable_options = ds_list_create();
	shop_consumable_scale = ds_list_create();
	shop_keepsake_options = ds_list_create();
	shop_keepsake_scale = ds_list_create();
	
	generate_dice_rewards(shop_dice_options, global.master_dice_list, num_dice);
	generate_item_rewards(shop_consumable_options, global.master_item_list, num_consumables);
	generate_keepsake_rewards(shop_keepsake_options, global.master_keepsake_list, num_keepsakes);
	
	repeat(num_dice) ds_list_add(shop_dice_scale, 0.1);
	repeat(num_consumables) ds_list_add(shop_consumable_scale, 0.1);
	repeat(num_keepsakes) ds_list_add(shop_keepsake_scale, 0.1);
}

/// @func generate_dice_rewards(_reward_list, _item_list, _num)
function generate_dice_rewards(_reward_list, _item_list, _num) {
	
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

	// pick up to 3 unique entries
	var num_rewards = _num;
			
	// used for deduping and storing what dice we used
	var die_1 = clone_die(global.dice_all, "");
	var die_2 = clone_die(global.dice_all, "");

	do {
		var chance = irandom_range(1, 200);
				
		if (chance <= 1) {
			var rare_index = irandom(ds_list_size(indices_dice_rare)-1);
			var die_struct = indices_dice_rare[| rare_index ];
				
			if (die_struct != die_1 && die_struct != die_2) {
				if (ds_list_size(_reward_list) == 0) die_1 = die_struct;
				if (ds_list_size(_reward_list) == 1) die_2 = die_struct;
				
				ds_list_add(_reward_list, clone_die(die_struct, ""));
			}
			continue;
		}
				
		if (chance <= 40) {
			var uncommon_index = irandom(ds_list_size(indices_dice_uncommon)-1);
			var die_struct = indices_dice_uncommon[| uncommon_index ];
				
			if (die_struct != die_1 && die_struct != die_2) {
				if (ds_list_size(_reward_list) == 0) die_1 = die_struct;
				if (ds_list_size(_reward_list) == 1) die_2 = die_struct;
				
				ds_list_add(_reward_list, clone_die(die_struct, ""));
			}

			continue;
		}
				
		if (chance <= 200) {
			var common_index = irandom(ds_list_size(indices_dice_common)-1);
			var die_struct = indices_dice_common[| common_index ];
				
			if (die_struct != die_1 && die_struct != die_2) {
				if (ds_list_size(_reward_list) == 0) die_1 = die_struct;
				if (ds_list_size(_reward_list) == 1) die_2 = die_struct;
				
				ds_list_add(_reward_list, clone_die(die_struct, ""));
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

function generate_item_rewards(_reward_list, _item_list, _num) {
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

	// pick up to 3 unique entries
	var num_rewards = _num;

	do {
		// Random number but make common rewards less likely on each subsequent slot
		var chance = irandom_range(1, 200 - ds_list_size(_reward_list) * 20 );
				
		if (chance <= 10) {
			var item_struct = indices_items_rare[| irandom(ds_list_size(indices_items_rare)-1) ];
			ds_list_add(_reward_list, clone_item(item_struct));
			show_debug_message("Added a rare item to the rewards.");
			continue;
		}
				
				
		if (chance <= 60) {
			var item_struct = indices_items_uncommon[| irandom(ds_list_size(indices_items_uncommon)-1) ];
			ds_list_add(_reward_list, clone_item(item_struct));
			show_debug_message("Added an uncommon item to the rewards.");
			continue;
		}
				
		if (chance <= 200) {
			var item_struct = indices_items_common[| irandom(ds_list_size(indices_items_common)-1) ];
			if (item_struct.name == "Coins") {
				if (room == rmShop || room = rmEvent) {
					continue;
				} else {
					item_struct.amount = irandom_range(12, 15);
				}
			}
			
			ds_list_add(_reward_list, clone_item(item_struct));
			show_debug_message("Added a common item to the rewards.");
			continue;
		}
			    
	}
	until (ds_list_size(_reward_list) == num_rewards);
	
	ds_list_destroy(indices_items_common);
	ds_list_destroy(indices_items_uncommon);
	ds_list_destroy(indices_items_rare);
}

function generate_keepsake_rewards(_reward_list, _item_list, _num) {
	var total_keepsakes = ds_list_size(_item_list);
	var indices_keepsakes = ds_list_create();		
			
	// fill list with all possible indices
	for (var i = 0; i < total_keepsakes; i++) {
		ds_list_add(indices_keepsakes, clone_item(_item_list[| i]));
	}

	// shuffle to randomize order
	ds_list_shuffle(indices_keepsakes);

	// pick up to 3 unique entries
	var num_rewards = _num;

	do {

		var item_struct = indices_keepsakes[| irandom(ds_list_size(indices_keepsakes)-1) ];
		ds_list_add(_reward_list, clone_item(item_struct));
		continue;
			    
	}
	until (ds_list_size(_reward_list) == num_rewards);
	
	ds_list_destroy(indices_keepsakes);
}