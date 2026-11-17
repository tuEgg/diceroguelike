// the new run offering is a popup: keep the map behind it locked even after the bag or settings hand back the base layer
if (new_run_offering && global.ui_layer == UI_LAYER.BASE) global.ui_layer = UI_LAYER.POPUP;

// Tab works like Escape: in a fullscreen web build the browser keeps Escape for itself (it leaves fullscreen)
key_escape = keyboard_check_pressed(vk_escape) || keyboard_check_pressed(vk_tab);

// Escape closes Settings (back to the pause menu), then the bag, then opens or closes the pause menu (F35)
if (key_escape && global.ui_layer != UI_LAYER.DEBUG && run_over == undefined) {
	if (global.show_settings) {
		with (oSettingsMenu) exit_settings();
	} else if (show_bag_contents) {
		show_bag_contents = false;
		global.ui_layer = UI_LAYER.BASE;
	} else if (paused) {
		pause_close();
	} else if (oCutsceneManager.cutscene_state == CUTSCENE_STATE.FINISHED) {
		pause_open();
	}
}

// the pause menu holds the layer, also after Settings (opened from it) hands back the base layer
if (paused && !global.show_settings) global.ui_layer = UI_LAYER.SETTINGS;

// Restart shortcut only works when run from the IDE, never in an exported build
key_restart = keyboard_check_pressed(ord("R")) && DEBUG_TOOLS;
if key_restart game_restart();

// testing keys, listed on the F1 menu's Hotkeys tab
if (DEBUG_TOOLS) {
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
			enter_node(clone_node_static(node_combat)); // a copy, so the template never remembers an encounter
		}
	}
	
	key_elite = keyboard_check_pressed(ord("L"));
	if (key_elite) {
		with (oWorldManager) {
			enter_node(clone_node_static(node_elite)); // a copy, so the template never remembers an encounter
		}
	}
	
	key_alignment = keyboard_check_pressed(ord("A"));
	if (key_alignment) {
		with (oWorldManager) {
			enter_node(clone_node_static(node_alignment)); // a copy, so the template never remembers an encounter
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
			if (!ds_safe_exists(filtered_list, ds_type_list)) filtered_list = ds_list_create();
			
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
			if (ds_safe_exists(filtered_list, ds_type_list)) ds_list_destroy(filtered_list);
		}
	}
}

// oCombat only exists in combat, hp can also hit zero in events
if (global.player_hp <= 0 && run_over == undefined) {
	if (!instance_exists(oCombat) || oCombat.state != CombatState.PLAYER_DEAD) {
		lose_run();
	}
}

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
	queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), error_message, error_description);
} else {
	error_message = "";
	error_description = "";
}

global.player_alignment = clamp(global.player_alignment, 0, 100);

//if (mouse_check_button_pressed(mb_left)) {
//	particle_emit( device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), choose("rise"), c_red);
//}