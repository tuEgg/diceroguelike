hovered_slot_1 = false;
hovered_slot_2 = false;
	
for (var i = 0; i < wb_list_size; i++) {
	
	var slot_x = start_x + (i * (wb_tile_padding + wb_tile_size));
	var slot_y = start_y;
	
	var hovering_slot = !oRunManager.holding_item * mouse_hovering(slot_x, slot_y, wb_tile_size, wb_tile_size, true);
	
	if (oRunManager.holding_item) hovering_slot = false;
	
	if (i == 0 && workbench_slot[i].dice != undefined) {
		workbench_slot[i].xx = slot_x;
		workbench_slot[i].yy = slot_y;
	}
	
	if (hovering_slot) {
		wb_scale[i] = lerp(wb_scale[i], 1.2, 0.2);
		// a core dropped here is placed by oRunManager when it's let go (workbench_take_core)
	} else {
		wb_scale[i] = lerp(wb_scale[i], 1.0, 0.2);
	}
	
	if (hovering_slot && i == 0) {
		hovered_slot_1 = true;
	}
	
	if (hovering_slot && i == 1) {
		hovered_slot_2 = true;
	}
	
	slot_alpha = 1.0;
	if (instance_exists(oDice)) {
		if (i == 2) {
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
		var hovering_core = !oRunManager.holding_item * mouse_hovering(slot_x, slot_y, core_w * core_scale, core_h * core_scale, true);
		
		if (hovering_core) {
			core_scale = lerp(core_scale, 1.2, 0.2);
			
			// Pick core back up: a fresh click while the bench is idle. (Holding the button was enough before, and the
			// Drill is used over this very slot: once it vanished mid-press the core was picked up and the drill
			// then crafted with no core, B122.)
			if ((mouse_check_button_pressed(mb_left) && crafting_state == "waiting") || (workbench_slot[i].dice != undefined)) {
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
	
	// Draw name underneath (with the Cutters the bench reads "Dice = Basic coin + Remainder")
	var _cut_mode = (button_text == "Cut");
	var _label = string(workbench_slot[i].name);
	var _cut_labels = ["Dice", "Basic coin", "Remainder"];
	if (_cut_mode) _label = _cut_labels[i];
	draw_set_font(ftBigger);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_outline_text(_label, c_black, c_white, 2, slot_x, slot_y + wb_tile_size / 2 + 30, 1, 1.0, 0);

	// what the Cutters will do with the die in the first slot
	if (_cut_mode && i == 2 && crafting_state == "waiting") {
		var _note = "Keeps the die's effects";
		var _note_col = c_ltgray;
		var _src = workbench_slot[0].dice;
		if (_src != undefined) {
			if (_src.dice_value <= 2) {
				_note = "A coin can't be cut"; _note_col = c_red;
			} else if (_src.dice_value - 2 == 2 && _src.distribution != "") {
				_note = "Becomes a coin: its core is lost"; _note_col = c_red;
			} else if (_src.dice_value - 2 == 2) {
				_note = "Becomes a coin, keeps its effects";
			}
		}
		draw_set_font(ftDefault);
		draw_outline_text(_note, c_black, _note_col, 2, slot_x, slot_y + wb_tile_size / 2 + 66, 1, 1.0, 0);
	}

	// the die's distribution, just above its box (coins have none worth showing)
	var _bar_y = slot_y - wb_tile_size / 2 - 8 - (wb_scale[i] - 1) * wb_tile_size / 2;
	if (i == 0 || i == 2) {
		var _die_here = workbench_slot[i].dice;
		if (_die_here != undefined && _die_here.dice_value > 2) {
			draw_dice_distribution(_die_here, slot_x, _bar_y, true);
			if (_die_here.distribution != "") {
				draw_set_font(ftDefault);
				draw_outline_text(string(_die_here.distribution), c_black, c_white, 2, slot_x, _bar_y - 64, 1, 1, 0); // above the distribution (55px tall)
			}
		}
	}

	if (workbench_slot[1].core != undefined && i == 1) {
		var d = core_preview_die();
		d.distribution = workbench_slot[i].core.distribution;

		draw_dice_distribution(d, slot_x, _bar_y, true);
		draw_set_font(ftDefault);
		draw_outline_text(string(d.distribution), c_black, c_white, 2, slot_x, _bar_y - 64, 1, 1, 0);
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
			case "Drill":
				if (workbench_slot[0].dice != undefined && workbench_slot[1].core != undefined) {
					craft_col = c_lime;
				}
			break;
			case "Cut":
				if (workbench_slot[0].dice != undefined && workbench_slot[1].core == undefined && workbench_slot[1].dice == undefined && workbench_slot[2].dice == undefined) {
					craft_col = c_lime;
				}
			break;
			case "Combine":
				if (workbench_slot[0].dice != undefined && workbench_slot[1].dice != undefined && workbench_slot[1].core == undefined && workbench_slot[2].dice == undefined) {
					craft_col = c_lime;
				}
			break;
		}
	
		button_text_w = string_width(button_text);
		
		var angle = 0;
	
		if (error_shake) {
		    // Advance the wave
		    error_wobble_phase += 0.5; // speed of wobble

		    // Reduce the amplitude smoothly
		    error_wobble_amp = lerp(error_wobble_amp, 0, 0.2);

		    // Apply wobble
		    angle = sin(error_wobble_phase) * error_wobble_amp;

		    // Kill shake when basically settled
		    if (error_wobble_amp < 0.1) {
		        error_shake = false;
		        error_wobble_amp = 30;
		        angle = 0;
		    }
		}

		draw_sprite_ext(sButtonSmall, 0, gui_w/2, start_y + 280, (0.2 + button_text_w / 120) * (0.75 * button_scale), 0.75 * button_scale, angle, ui_button_col(craft_col), 1.0);
		draw_outline_text(button_text, c_black, c_white, 2, gui_w/2, start_y + 280, button_scale, 1, 0); // the label grows with the button
	break;
	
	case "hammered":
		if (bang_timer == 15 && (workbench_slot[0].dice == undefined || workbench_slot[1].dice == undefined)) { crafting_state = "waiting"; break; }
		if (bang_timer == 15) {
			sfx_play(soShieldMedium, AUDIO_GROUP.SFX, 0.1, 0.8); // placeholder until there's a hammer sound
			var new_dice = clone_die(workbench_slot[0].dice, "");
			
			new_dice.dice_value += workbench_slot[1].dice.dice_value;
			die_size_changed(new_dice); // a hammered coin is no longer a coin
			
			// gain something from second die
			workbench_slot[2].dice = new_dice;
			workbench_slot[0].dice = undefined;
			workbench_slot[1].dice = undefined;
			with (oDice) if (in_slot) instance_destroy();
			// (the rest of your hand stays: more crafts may follow with other tools)
			
			//show_debug_message("New dice created.");
			
			// Spawn instance
			var xx = workbench_slot[2].xx;
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
	
	case "drilled":
		// the ingredients must still be on the bench (otherwise give up the craft rather than crash)
		if (workbench_slot[0].dice == undefined || workbench_slot[1].core == undefined) { crafting_state = "waiting"; break; }
		sfx_play(choose(soRubble1, soRubble2, soRubble3, soRubble4), AUDIO_GROUP.SFX, 0.1, 0.8); // placeholder drill sound
		var new_dice = clone_die(workbench_slot[0].dice, "");
		new_dice.distribution = workbench_slot[1].core.distribution;
		workbench_slot[2].dice = new_dice;
		workbench_slot[0].dice = undefined;
		workbench_slot[1].core = undefined;
		with (oDice) if (in_slot) instance_destroy();
		// (the rest of your hand stays: more crafts may follow with other tools)
			
		//show_debug_message("New dice created.");
			
		// Spawn instance
		var xx = workbench_slot[2].xx;
		var die_inst = instance_create_layer(xx, start_y, "Instances", oDice);
		die_inst.struct = new_dice;
		die_inst.action_type = new_dice.action_type;
		die_inst.dice_amount = new_dice.dice_amount;
		die_inst.dice_value  = new_dice.dice_value;
		die_inst.possible_type = new_dice.possible_type;
		die_inst.target_x = xx;
		die_inst.target_y = start_y;
		die_inst.still = true;
		
		particle_emit(gui_w/2, start_y + 280, "burst", c_green, 150);
		
		crafting_state = "finished";
	break;
	
	case "cut":
		if (workbench_slot[0].dice == undefined) { crafting_state = "waiting"; break; }
		sfx_play(choose(soSwordLight1, soSwordLight2, soSwordLight3), AUDIO_GROUP.SFX, 0.15, 0.8); // placeholder snip sound
		var new_dice = clone_die(workbench_slot[0].dice, "");
		new_dice.dice_value = workbench_slot[0].dice.dice_value - 2;

		die_size_changed(new_dice); // cut down to a d2, it plays as a coin
		if (new_dice.dice_value == 2) new_dice.distribution = ""; // a coin has no core: the core is lost (the bench warns)
		
		var base_coin = global.dice_d2_none;
		
		switch(workbench_slot[0].dice.action_type) {
			case "ATK":
				base_coin = global.dice_d2_atk;
			break;
			case "BLK":
				base_coin = global.dice_d2_blk;
			break;
			case "INTEL":
				base_coin = global.dice_d2_intel;
			break;
			case "HEAL":
				base_coin = global.dice_d2_heal;
			break;
		}
		
		var new_coin = clone_die(base_coin, "");
		new_coin.dice_value = 2;
		
		workbench_slot[0].dice = undefined;
		workbench_slot[1].dice = new_coin;
		workbench_slot[2].dice = new_dice;
		with (oDice) if (in_slot) instance_destroy();
		// (the rest of your hand stays: more crafts may follow with other tools)
			
		//show_debug_message("New dice created.");
			
		// Spawn instance
		var coin_xx = workbench_slot[1].xx;
		var coin_inst = instance_create_layer(coin_xx, start_y, "Instances", oDice);
		coin_inst.struct = new_coin;
		coin_inst.action_type = new_coin.action_type;
		coin_inst.dice_amount = new_coin.dice_amount;
		coin_inst.dice_value  = new_coin.dice_value;
		coin_inst.possible_type = new_coin.possible_type;
		coin_inst.target_x = coin_xx;
		coin_inst.target_y = start_y;
		coin_inst.still = true;
		
		var die_xx = workbench_slot[2].xx;
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

// before anything else: choose the dice to work on (the bag opens on request, not by itself)
if (pick_pending) {
	var _pw = 560, _ph = 170;
	var _px = gui_w / 2 - _pw / 2, _py = max(start_y - wb_tile_size - 230, 200); // below the toolbag's tools (they drop down to about y 180)
	ui_panel(_px, _py, _px + _pw, _py + _ph);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(ftDefault);
	var _n = workbench_dice_allowance();
	draw_outline_text("Take up to " + string(_n) + ((_n == 1) ? " die" : " dice") + " from your bag to work on.", c_black, c_white, 2, gui_w / 2, _py + 44, 1, 1, 0);
	var _pick = ui_button(gui_w / 2, _py + 108, 260, 64, pick_scale, "Open the bag", global.ui_primary);
	pick_scale = _pick.scale;
	if (_pick.click) workbench_open_picker();
}

// "Dice + Core = Output", or with the Cutters "Dice = Basic coin + Remainder"
var _cutting = (button_text == "Cut");
draw_outline_text(_cutting ? "=" : "+", c_black, c_white, 2, gui_w/2 - wb_tile_size/2 - wb_tile_padding/2, start_y, 1, 1.0, 0);
draw_outline_text(_cutting ? "+" : "=", c_black, c_white, 2, gui_w/2 + wb_tile_size/2 + wb_tile_padding/2, start_y, 1, 1.0, 0);

// the mouse, while a tool is in hand: hold left over Craft to use it, right click to put it down
var _tool_in_hand = "";
if (instance_exists(oDrill) && oDrill.is_dragging) _tool_in_hand = "drill";
if (instance_exists(oHammer) && oHammer.is_dragging) _tool_in_hand = "smash";
if (instance_exists(oScissors) && oScissors.is_dragging) _tool_in_hand = "cut";
if (_tool_in_hand != "" && progress_get("workbench_hints_done") != true) { // until a tool has crafted once (workbench_tool_used)
	var _hint_y = start_y - wb_tile_size - 70; // above the bench, clear of the dice in hand
	draw_mouse_hint(gui_w/2 - 230, _hint_y, "left", (_tool_in_hand == "drill") ? "Hold over the Drill button" : "Click the " + button_text + " button");
	draw_mouse_hint(gui_w/2 + 90, _hint_y, "right", "Put the tool down");
}

// Draw exit button
var exit_col = c_dkgray;
if	(workbench_slot[2].dice == undefined && instance_number(oDice) == 0 && instance_number(oDiceParticle) == 0) ||
	(workbench_slot[0].dice == undefined && workbench_slot[1].core == undefined && workbench_slot[1].dice == undefined && workbench_slot[2].dice == undefined) exit_col = c_red;

var exit_ready = (exit_col == c_red) && !oRunManager.is_dealing_dice && !oRunManager.holding_item;
// the room's commit action, bottom right (ui_primary, UI rework)
var exit_btn = ui_primary(gui_w - 44 - 140, gui_h - 40 - 48, 280, 96, "Continue", exit_ready, "Take the dice off the bench first (click a finished die).");
if (exit_btn.click) exiting = true;