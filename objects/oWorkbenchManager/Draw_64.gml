var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

var wb_list_size = array_length(workbench_slot);
var wb_tile_size = sprite_get_width(sActionSlotCentered);
var wb_tile_padding = 50;
	
var start_x = gui_w/2 - wb_tile_padding - wb_tile_size;
var start_y = gui_h/2 - 50;

hovered_slot_1 = false;
	
for (var i = 0; i < wb_list_size; i++) {
	
	var slot_x = start_x + (i * (wb_tile_padding + wb_tile_size));
	var slot_y = start_y;
	
	var hovering_slot = mouse_hovering(slot_x, slot_y, wb_tile_size, wb_tile_size, true);
	
	if (oRunManager.holding_item) hovering_slot = false;
	
	if (i == 0 && workbench_slot[i].dice != undefined) {
		workbench_slot[i].xx = slot_x;
		workbench_slot[i].yy = slot_y;
	}
	
	if (hovering_slot) {
		wb_scale[i] = lerp(wb_scale[i], 1.2, 0.2);
		
		// Place core into slot
		for (var n = 0; n < array_length(oRunManager.items); n++) {
			if (oRunManager.items[n] != undefined) {
				if (oRunManager.items[n].dragging) {
					if (mouse_check_button_released(mb_left)) {
						if (workbench_slot[1].core == undefined) {
							if (i == 1 && oRunManager.items[n].type = "core") {
								workbench_slot[i].core = oRunManager.items[n];
								oRunManager.items[n] = undefined;
								core_prev_item_slot = n;
							}
						}
					}
				}
			}
		}
	} else {
		wb_scale[i] = lerp(wb_scale[i], 1.0, 0.2);
	}
	
	if (hovering_slot && i == 0) {
		hovered_slot_1 = true;
	}
	
	slot_alpha = 1.0;
	if (instance_exists(oDice)) {
		if (i == 1 || i == 2) {
			with (oDice) {
				if (is_dragging) {
					other.slot_alpha = 0.5;
				}
			}
		}
	}
	
	for (var t = 0; t < array_length(oRunManager.items); t++) {
		if (oRunManager.items[t] != undefined) {
			if (oRunManager.items[t].dragging) {
				if (i == 0 || i == 2) slot_alpha = 0.5;
				if (oRunManager.items[t].type != "core" && i == 1) slot_alpha = 0.5;
			}
		}
	}
	
	// Draw slot
	draw_sprite_ext(sActionSlotCentered, 0, slot_x, slot_y, wb_scale[i], wb_scale[i], 0, c_ltgray, slot_alpha);
	
	// Draw occupying core
	if (i == 1 && workbench_slot[i].core != undefined) {
		var core_w = sprite_get_width(sCores) * 1.5;
		var core_h = sprite_get_height(sCores) * 1.5;
		var hovering_core = mouse_hovering(slot_x, slot_y, core_w * core_scale, core_h * core_scale, true);
		
		if (hovering_core) {
			core_scale = lerp(core_scale, 1.2, 0.2);
			
			// Pick core back up
			if (mouse_check_button(mb_left)) {
				oRunManager.items[core_prev_item_slot] = workbench_slot[i].core;
				workbench_slot[i].core = undefined;
			}			
			
		} else {
			core_scale = lerp(core_scale, 1.0, 0.2);
		}
		
		if (workbench_slot[i].core != undefined) {
			draw_sprite_ext(sCores, workbench_slot[i].core.index, slot_x, slot_y, core_scale * 1.5, core_scale * 1.5, 0, c_white, slot_alpha);
		}
	}
	
	// Draw name underneath
	draw_set_font(ftBigger);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_outline_text(string(workbench_slot[i].name), c_black, c_white, 2, slot_x, slot_y + wb_tile_size / 2 + 30, 1, 1.0, 0);

	// Draw distribution
	if (i == 0 || i == 2) {
		if (workbench_slot[i].dice != undefined) {
			draw_dice_distribution(workbench_slot[i].dice, slot_x, slot_y - wb_tile_size/2 - (wb_scale[i]*15), true);
			
			draw_set_font(ftBig);
			draw_outline_text(string(workbench_slot[i].dice.distribution), c_black, c_white, 2, slot_x, slot_y - wb_tile_size, 1, 1, 0);
		}
	}
	
	if (workbench_slot[1].core != undefined && i == 1) {
		var d = clone_die(global.dice_d6_atk, "");
		d.distribution = workbench_slot[i].core.distribution;
		
		draw_dice_distribution(d, slot_x, slot_y - wb_tile_size/2, true);
		draw_set_font(ftBig);
		draw_outline_text(string(d.distribution), c_black, c_white, 2, slot_x, slot_y - wb_tile_size, 1, 1, 0);
	}
	
	// Draw output preview
	// NEED TO ADD THIS
}

var button_text_w = 100;

// Crafting states
switch (crafting_state) {
	case "waiting":
		var craft_col = c_dkgray;
		switch (button_text) {
			case "Craft":
				if (workbench_slot[0].dice != undefined && workbench_slot[1].core != undefined) {
					craft_col = c_lime;
				}
			break;
			case "Cut":
				if (workbench_slot[0].dice != undefined && workbench_slot[1].core == undefined && workbench_slot[1].dice == undefined && workbench_slot[2].dice == undefined) {
					craft_col = c_lime;
				}
			break;
		}
	
		button_text_w = string_width(button_text);
	
		draw_sprite_ext(sButtonSmall, 0, gui_w/2, start_y + 280, (0.2 + button_text_w / 120) * (0.75 * button_scale), 0.75 * button_scale, 0, craft_col, 1.0);
		draw_outline_text(button_text, c_black, c_white, 2, gui_w/2, start_y + 280, 1, 1, 0);
	break;
	
	case "hammered":
		if (bang_timer == 15) {
			var new_dice = clone_die(workbench_slot[0].dice, "");
			new_dice.distribution = workbench_slot[1].core.distribution;
			workbench_slot[2].dice = new_dice;
			workbench_slot[0].dice = undefined;
			workbench_slot[1].core = undefined;
			with (oDice) if (in_slot) instance_destroy();
			
			discard_dice_in_play();
			
			//show_debug_message("New dice created.");
			
			// Spawn instance
			var xx = start_x + (2 * (wb_tile_padding + wb_tile_size));
			var die_inst = instance_create_layer(xx, start_y, "Instances", oDice);
			die_inst.struct = new_dice;
			die_inst.action_type = new_dice.action_type;
			die_inst.dice_amount = new_dice.dice_amount;
			die_inst.dice_value  = new_dice.dice_value;
			die_inst.possible_type = new_dice.possible_type;
			die_inst.target_x = xx;
			die_inst.target_y = start_y;
			die_inst.still = true;
			
		}
		// Draw explosion and then create the die
		bang_timer--;
		
		if (bang_timer > 0) {
			draw_sprite(sBang, 0, gui_w/2, start_y + 280);
		}
	break;
	
	case "cut":
		var new_dice = clone_die(workbench_slot[0].dice, "");
		new_dice.dice_value = workbench_slot[0].dice.dice_value - 2;
		var new_coin = clone_die(workbench_slot[0].dice, "");
		new_coin.dice_value = 2;
		
		workbench_slot[0].dice = undefined;
		workbench_slot[1].dice = new_coin;
		workbench_slot[2].dice = new_dice;
		with (oDice) if (in_slot) instance_destroy();
			
		discard_dice_in_play();
			
		//show_debug_message("New dice created.");
			
		// Spawn instance
		var coin_xx = start_x + (1 * (wb_tile_padding + wb_tile_size));
		var coin_inst = instance_create_layer(coin_xx, start_y, "Instances", oDice);
		coin_inst.struct = new_coin;
		coin_inst.action_type = new_coin.action_type;
		coin_inst.dice_amount = new_coin.dice_amount;
		coin_inst.dice_value  = new_coin.dice_value;
		coin_inst.possible_type = new_coin.possible_type;
		coin_inst.target_x = coin_xx;
		coin_inst.target_y = start_y;
		coin_inst.still = true;
		
		var die_xx = start_x + (2 * (wb_tile_padding + wb_tile_size));
		var die_inst = instance_create_layer(die_xx, start_y, "Instances", oDice);
		die_inst.struct = new_dice;
		die_inst.action_type = new_dice.action_type;
		die_inst.dice_amount = new_dice.dice_amount;
		die_inst.dice_value  = new_dice.dice_value;
		die_inst.possible_type = new_dice.possible_type;
		die_inst.target_x = die_xx;
		die_inst.target_y = start_y;
		die_inst.still = true;
		
		crafting_state = "snipped";
	break;
	
	case "snipped":
		snipped_x += 3;
		snipped_y *= 1.13;
		
		snipped_y = min(snipped_y, 400);
		
		snipped_angle += max(2, snipped_y / 30);
		
		draw_sprite_ext(sButtonSmall, 1, gui_w/2 - snipped_x, start_y + 280 + snipped_y, (0.2 + button_text_w / 120) * (0.75 * button_scale), 0.75 * button_scale, snipped_angle, c_lime, 1.0);
		draw_sprite_ext(sButtonSmall, 2, gui_w/2 + snipped_x, start_y + 280 + snipped_y, (0.2 + button_text_w / 120) * (0.75 * button_scale), 0.75 * button_scale, -snipped_angle, c_lime, 1.0);
	break;
}

draw_outline_text("+", c_black, c_white, 2, gui_w/2 - wb_tile_size/2 - wb_tile_padding/2, start_y, 1, 1.0, 0);
draw_outline_text("=", c_black, c_white, 2, gui_w/2 + wb_tile_size/2 + wb_tile_padding/2, start_y, 1, 1.0, 0);

// Draw exit button
var exit_col = c_dkgray;
if	(workbench_slot[2].dice != undefined && instance_number(oDice) == 0 && instance_number(oDiceParticle) == 0) ||
	(workbench_slot[0].dice == undefined && workbench_slot[1].core == undefined && workbench_slot[2].dice == undefined) exit_col = c_red;

var hover_exit = mouse_hovering(gui_w - 150, gui_h - 200, exit_scale*sprite_get_width(sButtonSmall)*0.75, exit_scale*sprite_get_height(sButtonSmall)*0.75, true);

if (hover_exit && !oRunManager.is_dealing_dice && exit_col == c_red && !oRunManager.holding_item) {
	if (mouse_check_button_pressed(mb_left)) {
		exiting = true;
	}
	exit_scale = lerp(exit_scale, 1.2, 0.2);
} else {
	exit_scale = lerp(exit_scale, 1.0, 0.2);
}

draw_sprite_ext(sButtonSmall, 0, gui_w - 150, gui_h - 200, exit_scale*0.75, exit_scale*0.75, 0, exit_col, 1.0);
draw_outline_text("Exit", c_black, c_white, 2, gui_w - 150, gui_h - 200, 1, 1, 0);