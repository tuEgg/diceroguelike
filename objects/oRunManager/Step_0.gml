key_escape = keyboard_check(vk_escape);
if key_escape game_end();

key_restart = keyboard_check(ord("R"));
if key_restart game_restart();

if (debug_mode) {
	key_workbench = keyboard_check_pressed(ord("W"));
	if (key_workbench) room_goto(rmWorkbench);
	
	key_shop = keyboard_check_pressed(ord("S"));
	if (key_shop) room_goto(rmShop);
	
	key_shop = keyboard_check_pressed(ord("E"));
	if (key_shop) room_goto(rmEvent);
	
	key_dice_list = keyboard_check_pressed(ord("Q"));
	if (key_dice_list) {
		show_dice_list = 1 - show_dice_list;
		if (show_dice_list) {
			if (!ds_exists(filtered_list, ds_type_list)) filtered_list = ds_list_create();
			
			// Filter list
			filter = "none"
	
			for (var i = 0; i < ds_list_size(global.master_dice_list); i++) {
				switch (filter) {
					case "none":
					ds_list_add(filtered_list, global.master_dice_list[| i]);
					break;
				}
			}
		} else {
			if (ds_exists(filtered_list, ds_type_list)) ds_list_destroy(filtered_list);
		}
	}
	
	// Change filter
	if (show_dice_list) {
		if keyboard_check_pressed(ord("A")) {
			filter = "none";
		}
	}
}

if (global.player_hp <= 0) game_restart();

for (var i = 0; i < array_length(items); i++) {
	if (items[i] != undefined) {
		has_space_for_item = false;
		continue;
	} else {
		has_space_for_item = true;
		break;
	}
}