// the voyage clock for the score's speed bonus: real time played, not while paused or after the voyage ended (a hidden
// browser tab sends one huge frame: capped)
if (!paused && run_over == undefined && room != rmMainMenu) run_stat_add("play_time", min(delta_time / 1000000, 0.25));

// juice: queued particle bursts are made here (not in Draw GUI); the screen shake eases off
particles_flush();
ghost_sweep_step(); // the Dutchman's spirits, if he is passing
if (variable_global_exists("shake")) global.shake = (global.shake < 0.4) ? 0 : global.shake * 0.82;

// coins: spending jingles once; gold coming in is a trickle, a quiet clink for each coin as it lands, at most one every
// 4 frames (so about six overlap at most), each a little higher than the last, so a big haul sounds like a pile filling up
if (coin_tick_cd > 0) coin_tick_cd--;
if (coin_streak_idle++ > 20) coin_streak = 0; // a pause: the next haul starts low again
if (credits != credits_heard) {
	if (credits < credits_heard) { sfx_play(soCoins, AUDIO_GROUP.SFX, 0.05, 0.9); credits_scale = max(credits_scale, 1.3); } // and the counter jumps
	else if (coin_tick_cd <= 0) {
		sfx_play_layered(soCoins, AUDIO_GROUP.SFX, min(1.35, 0.92 + coin_streak * 0.025) + random_range(-0.03, 0.03), 0.35);
		coin_streak++;
		coin_tick_cd = 4;
	}
	if (credits > credits_heard) coin_streak_idle = 0;
	credits_heard = credits;
}

// the new run offering is a popup: keep the map behind it locked even after the bag or settings hand back the base layer
if (new_run_offering && global.ui_layer == UI_LAYER.BASE) global.ui_layer = UI_LAYER.POPUP;

// Tab works like Escape: in a fullscreen web build the browser keeps Escape for itself (it leaves fullscreen)
key_escape = keyboard_check_pressed(vk_escape) || (keyboard_check_pressed(vk_tab) && room != rmCombat); // in a fight Tab is the ink view (oCombat Step)

// the map shown over a fight closes on Escape (or its Close button), before Escape can open the pause menu
if (global.map_peek && key_escape) { global.map_peek = false; if (run_over == undefined && !(instance_exists(oCombat) && oCombat.state == CombatState.PLAYER_DEAD)) global.ui_layer = UI_LAYER.BASE; key_escape = false; }
if (global.map_peek && room != rmCombat) { global.map_peek = false; if (run_over == undefined && !paused) global.ui_layer = UI_LAYER.BASE; } // never leave the layer locked behind it

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