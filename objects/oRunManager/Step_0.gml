key_escape = keyboard_check_pressed(vk_escape);
if key_escape {
	if (bag_hover_locked) {
		bag_hover_locked = false;
	} else {
		game_end();
	}
}

key_restart = keyboard_check(ord("R"));
if key_restart game_restart();

if (debug_mode) {
	key_workbench = keyboard_check_pressed(ord("W"));
	if (key_workbench) room_goto(rmWorkbench);
	
	key_shop = keyboard_check_pressed(ord("S"));
	if (key_shop) room_goto(rmShop);
	
	key_shop = keyboard_check_pressed(ord("E"));
	if (key_shop) room_goto(rmEvent);
	
	key_bounty = keyboard_check_pressed(ord("B"));
	if (key_bounty) room_goto(rmBounty);
	
	key_combat = keyboard_check_pressed(ord("C"));
	if (key_combat) {		
		with (oWorldManager) {
			enter_node(node_combat);
		}
	}
	
	key_elite = keyboard_check_pressed(ord("L"));
	if (key_elite) {
		with (oWorldManager) {
			enter_node(node_elite);
		}
	}
	
	key_alignment = keyboard_check_pressed(ord("A"));
	if (key_alignment) {
		with (oWorldManager) {
			enter_node(node_alignment);
		}
	}
	
	key_treasure = keyboard_check_pressed(ord("T"));
	if (key_treasure) room_goto(rmTreasure);
	
	key_treasure = keyboard_check_pressed(ord("G"));
	if (key_treasure) {
		for (var i = 0; i < ds_list_size(global.master_keepsake_list); i++) {
			gain_keepsake(global.master_keepsake_list[| i]);
		}
	}
	
	key_map = keyboard_check_pressed(ord("X"));
	if (key_map) {		
		room_goto(rmMap);
	}
	
	key_dice_list = keyboard_check_pressed(ord("Q"));
	if (key_dice_list) {
		show_dice_list = 1 - show_dice_list;
		if (show_dice_list) {
			if (!ds_exists(filtered_list, ds_type_list)) filtered_list = ds_list_create();
			
			// Filter list
			filter = "bag";
			var _list = global.master_dice_list;
			
			switch (filter) {				
				case "bag":
					_list = global.dice_bag;
				break;
				
			}
			
			for (var i = 0; i < ds_list_size(_list); i++) {
				ds_list_add(filtered_list, _list[| i]);
			}
		} else {
			if (ds_exists(filtered_list, ds_type_list)) ds_list_destroy(filtered_list);
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

if (error_timer > 0) {
	error_timer--;
	queue_tooltip(mouse_x, mouse_y, error_message, error_description);
} else {
	error_message = "";
	error_description = "";
}

global.main_input_disabled = bag_hover_locked;

//if (mouse_check_button_pressed(mb_left)) {
//	particle_emit( mouse_x, mouse_y, choose("rise"), c_red);
//}