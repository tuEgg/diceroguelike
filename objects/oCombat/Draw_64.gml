gui_w = display_get_gui_width();
gui_h = display_get_gui_height();

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

var tooltip = "";

var aq_list_size = ds_list_size(action_queue);
var aq_tile_w = 140;
var aq_tile_padding = 20;
var aq_total_w = ((aq_list_size + 1) * aq_tile_w) + ((aq_list_size) * aq_tile_padding);
var aq_start_x = gui_w / 2 - (aq_total_w / 2);
var aq_start_y = gui_h / 2;

// Keep tile_scale list synced with action_queue size
if (ds_list_size(tile_scale) < aq_list_size) {
    repeat(aq_list_size - ds_list_size(tile_scale)) ds_list_add(tile_scale, 1.0);
} else if (ds_list_size(tile_scale) > aq_list_size) {
    repeat(ds_list_size(tile_scale) - aq_list_size) ds_list_delete(tile_scale, ds_list_size(tile_scale) - 1);
}

// Used for sending slot positions to Step event
if (!variable_instance_exists(id, "slot_positions")) {
    slot_positions = ds_list_create();
}
ds_list_clear(slot_positions);

draw_set_font(ftBig);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
dice_played_scale = lerp(dice_played_scale, 1.0, 0.05);
dice_played_color = merge_colour(dice_played_color, c_white, 0.05);
var played_dice_string = string(dice_allowed_per_turn - dice_played);
draw_outline_text(played_dice_string, c_black, dice_played_color, 2, aq_start_x - aq_tile_w/2 - aq_tile_padding - 8, aq_start_y + aq_tile_w/2 - 40, dice_played_scale, 1.0, 0);
draw_sprite_ext(sDice, 3, aq_start_x - aq_tile_w/2 - aq_tile_padding + 32, aq_start_y + aq_tile_w/2 - 40, 0.5, 0.5, 0, c_white, 1.0);

var played_dice_hover = mouse_hovering(aq_start_x - aq_tile_w/2 - aq_tile_padding + 12, aq_start_y + aq_tile_w/2 - 40, 100, 50, true);

if (played_dice_hover && !show_rewards) queue_tooltip(mouse_x, mouse_y, "Played dice", "You can play " + string(dice_allowed_per_turn - dice_played) + " more dice this turn");

// --- Play Button ---
var btn_x = aq_start_x - 150;
var btn_y = aq_start_y + 70;
var btn_w = 130;
var btn_h = sprite_get_height(sEndTurn);

// Determine label dynamically
var label_text = (state == CombatState.PLAYER_INPUT)
    ? "END TURN"
    : "PENDING";
	
var label_col = (state == CombatState.PLAYER_INPUT)
    ? c_lime
    : c_dkgray;

// Draw button using helper
var play_btn = draw_gui_button(
    btn_x,
    btn_y,
    btn_w,
    btn_h,
    btn_scale,
    label_text,
    c_green,
    ftDefault,
    (state == CombatState.PLAYER_INPUT) && !show_rewards,         // active
	false
);

// Update animation state
btn_scale = play_btn.scale;

draw_sprite_ext(sEndTurn, 0, btn_x + sprite_get_width(sEndTurn)/2, btn_y + sprite_get_height(sEndTurn)/2, btn_scale, btn_scale, 0, label_col, 1);
draw_set_color(c_white);
draw_set_font(ftDefault);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_outline_text(label_text, c_black, c_white, 2, btn_x + sprite_get_width(sEndTurn)/2 - 40, btn_y + sprite_get_height(sEndTurn)/2, btn_scale, btn_scale, 0);

// Click handling
if (play_btn.click && state == CombatState.PLAYER_INPUT && !is_dealing_dice) {
    actions_submitted = true;
}

for (var i = 0; i < aq_list_size; i++) {
	var base_x = aq_start_x + (i * (aq_tile_w + aq_tile_padding));
	var base_y = aq_start_y;
	var base_w = aq_tile_w;
	var base_h = aq_tile_w;
	
    var current_scale = tile_scale[| i];
    var draw_w = base_w * current_scale;
    var draw_h = base_h * current_scale;
    var draw_x = base_x + (base_w - draw_w) / 2;
    var draw_y = base_y + (base_h - draw_h) / 2;

    // Hover check based on *scaled* rectangle
    var hover = (mx > draw_x && mx < draw_x + draw_w && my > draw_y && my < draw_y + draw_h && !show_rewards);

    // Smooth scale update
    var target_scale = hover ? 1.2 : 1.0;
    current_scale = lerp(current_scale, target_scale, 0.2);
    tile_scale[| i] = current_scale;

    // Redefine draw size after updating scale (for visual accuracy)
    draw_w = base_w * current_scale;
    draw_h = base_h * current_scale;
    draw_x = base_x + (base_w - draw_w) / 2;
    draw_y = base_y + (base_h - draw_h) / 2;
	
	// Store GUI coordinates for use elsewhere (e.g., oStep)
	var pos_struct = {
	    x: draw_x,
	    y: draw_y,
	    w: draw_w,
	    h: draw_h
	};
	ds_list_add(slot_positions, pos_struct);
	
	var action_queue_type = action_queue[| i].current_action_type;
	
	// Tile colours based on action type
	draw_col = get_dice_color(action_queue_type);
	
	// --- Determine alpha for this slot ---
	var draw_alpha_val = 0.5;
	var col = c_white;

	// Check if any dice are being dragged
	var dragged_die_inst = noone;
	with (oDice) {
	    if (is_dragging) {
	        dragged_die_inst = id;
	        break; // stop once we find one
	    }
	}

	if (dragged_die_inst != noone) {
	    var grabbed_die_struct = dragged_die_inst.struct;

	    if (!can_place_dice_in_slot(grabbed_die_struct, action_queue[| i], i)) {
	        // Fade invalid targets
	        draw_alpha_val = 0.1;
	        col = c_white;
	    } else {
	        // Highlight valid targets slightly
	        draw_alpha_val = 0.5;
	        col = make_color_rgb(160, 255, 160); // light green tint
	    }
	}
	
	var slot_index = 1;
	
	if (locked_slot == i) draw_col = c_dkgray;
	if (bound_slot == i) {
		var _slot_pos = oCombat.slot_positions[| oCombat.bound_slot];
					
		var start_x = _slot_pos.x + (_slot_pos.w / 2);
		var start_y = _slot_pos.y + (_slot_pos.h / 2);
					
		particle_emit(start_x, start_y, "constant", c_green, 1);
	}

    // --- Highlight the active action slot during RESOLVE_ROUND ---
	if (state == CombatState.RESOLVE_ROUND && !enemies_turn_done) {
	    if (i == action_index - 1) {
	        slot_index = 0;
		}
	}
	

	// Draw the main slot sprite
	draw_sprite_ext(sActionSlot, slot_index, draw_x, draw_y, current_scale, current_scale, 0, draw_col, 1.0);
	
	// If slot locked, kill self
	if (locked_slot == i) {
		draw_sprite_ext(sRewardChain, 0, draw_x + draw_w/2, draw_y + draw_h/2, current_scale * 0.75, current_scale * 0.75, 0, c_white, 1.0);
	}
	
	var stats = get_slot_stats(action_queue[| i], i);
	var _low_roll = stats.low_roll;
	var _high_roll = stats.high_roll;
	var total_amount = stats.amount;
	var highest_value = stats.highest_value;
	var different_dice = stats.differing_types;

	var slot_amount = total_amount;
	var slot_value = highest_value;
	var slot_possible_type = action_queue[| i].possible_type;

    // Draw label
	var label = get_action_name(action_queue[| i], i);
    draw_set_color(c_black);
    draw_set_alpha(1.0);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
	draw_set_font(ftDefault);
    draw_outline_text(label, c_black, c_white, 2, draw_x + draw_w / 2, draw_y + draw_h / 2 - (draw_h/10), 1, 1, 0);
	
	// Draw dice outcome
	if (label != "") {
		draw_set_font(ftDefault);
	    draw_outline_text( "(" + string(_low_roll) + "-" + string(_high_roll) + ")", c_black, c_white, 2, draw_x + draw_w / 2, draw_y + draw_h - 35, 1, 1, 0);
	}
	
	// Change action style based on possibilities
	if (hover && mouse_check_button_pressed(mb_right) && state == CombatState.PLAYER_INPUT) {
	    var slot = action_queue[| i];
	    var opts;

	    if (slot.possible_type == "All") {
	        opts = ["ATK", "BLK", "HEAL"];
	    } else {
	        opts = string_split(slot.possible_type, " ");
	    }

	    // Find current index in opts
	    var current_index = -1;
	    for (var n = 0; n < array_length(opts); n++) {
	        if (opts[n] == slot.current_action_type) {
	            current_index = n;
	            break;
	        }
	    }

	    // Move to next option
	    var next_index = (current_index + 1) mod array_length(opts);
	    slot.current_action_type = opts[next_index];
	}
	
	// Hover info
	if (hover) {
		//tooltip = "Upgrade slot to " + string(slot.dice_amount) + "d" + string(slot.dice_value) + " " + string(slot.action_type);
		
		var new_amount = grabbed_amount + slot_amount;
		var new_value = max(grabbed_value, slot_value);
		
		if (is_placing) {
			var s = slot_possible_type;
			var add_text = "Add " + string(grabbed_amount) + "d" + string(grabbed_value) +
				            " (" + string(new_amount) + "d" + string(new_value) + ")";

			// --- ATK / BLK / HEAL ---
			if (string_pos("ATK", s) > 0 || string_pos("BLK", s) > 0 || string_pos("HEAL", s) > 0) {
				if (string_pos(grabbed_type, s) > 0) {
				    if (slot_value > grabbed_value) {
						tooltip = "Can't upgrade bigger dice";
					} else {
						tooltip = add_text;
					}
				} else if (grabbed_type == "None") {
					if (slot_value > grabbed_value) {
						tooltip = "Can't upgrade bigger dice";
					} else {
						tooltip = add_text;
					}
				} else {
					// fix above so   if (grabbed_value != 2)
					tooltip = "Cannot replace slot";
				}
			}

			// --- None ---
			else if (s == "None") {
				if (grabbed_type == "None") {
				    tooltip = "Can't upgrade empty slots";
				} else {
				    tooltip = "Upgrade to " + string(grabbed_amount) + "d" +
				                string(grabbed_value) + " " + string(grabbed_type);
				}
			}

			// --- All ---
			else if (s == "All") {
				if (grabbed_type != "None") {
				    tooltip = "Can't replace 'All'";
				} else {
				    tooltip = add_text;
				}
			}
		} else {
			
			var _bonus = "";
			switch (sign(action_queue[| i].bonus_amount)) {
				case 1:
				_bonus = "+" + string(action_queue[| i].bonus_amount);
				break;
				case -1:
				_bonus = string(action_queue[| i].bonus_amount);
				break;
			}
			
			switch (action_queue_type) {
				case "ATK":
				tooltip = string(slot_amount) + "d" + string(slot_value) + _bonus + " Attack";
				break;
				case "BLK":
				tooltip = string(slot_amount) + "d" + string(slot_value) + _bonus + " Block";
				break;
				case "HEAL":
				tooltip = string(slot_amount) + "d" + string(slot_value) + _bonus + " Heal";
				break;
				case "INTEL":
				tooltip = string(slot_amount) + "d" + string(slot_value) + _bonus + " Intel";
				break;
				case "None":
					if (slot_possible_type != "All") {
						tooltip = "Drag dice here to change action type";
					} else {
						tooltip = "Right click to change effect";
					}
				break;		
				default:
				tooltip = "Right click to change effect";
				break;
			}
			
			if (different_dice) tooltip = "Different dice";
		}
		
	    draw_set_color(c_black);
	    draw_set_alpha(0.7);
	    draw_set_halign(fa_center);
	    draw_set_valign(fa_middle);
		draw_set_font(ftDefault);
		draw_text(draw_x + draw_w / 2, draw_y - draw_h / 2, string(tooltip));
	}
	
	// Apply potions that trigger on_played_to_slot
	if (hover) {
		for (var c = 0; c < array_length(oRunManager.items); c++) {
			var item = oRunManager.items[c];
			if (item != undefined) {
				if (item.type == "consumable" && item.dragging && item.effects.trigger == "on_played_to_slot" && !show_rewards) {
					if (mouse_check_button_released(mb_left)) {
						var context = {
							_slot: action_queue[| i],
							_ind: i
						}
						if (item.effects.flags(context)) {
							trigger_item_effects(item, "on_played_to_slot", context);
							oRunManager.items[c] = undefined;
						}
					}
				}
			}
		}
	}
	
	// Draw "make new action" tile after the last action slot
	if (i == ds_list_size(action_queue) - 1) {
		
		var c_scale = last_action_scale;
	    var last_w = base_w * c_scale;
	    var last_h = base_h * c_scale;
		var lx = aq_start_x + ( (i+1) * (aq_tile_w + aq_tile_padding) );
	    var last_x = lx + ((base_w - last_w) / 2);
	    var last_y = base_y + ((base_h - last_h) / 2);

	    // Hover check basesd on *scaled* rectangle
	    last_hover = (mx > last_x && mx < last_x + last_w && my > last_y && my < last_y + last_h && !show_rewards);

	    // Smooth scale update
	    var t_scale = last_hover ? 1.2 : 1.0;
	    c_scale = lerp(c_scale, t_scale, 0.2);
	    last_action_scale = c_scale;
		
	    last_w = base_w * c_scale;
	    last_h = base_h * c_scale;
	    last_x = lx + ((base_w - last_w) / 2);
	    last_y = base_y + ((base_h - last_h) / 2);

		draw_sprite_ext(sActionSlot, 2, last_x, last_y, c_scale, c_scale, 0, c_white, 1);

		// Draw text
	    draw_set_halign(fa_center);
	    draw_set_valign(fa_middle);
		draw_set_font(ftDefault);
		draw_outline_text("Sacrifice \n" + string(sacrificies_til_new_action_tile)+" dice", c_black, c_white, 2, last_x + last_w / 2, last_y + last_h / 2, 1, 1, 0);
		
		draw_action_type_bars(last_x, last_y + last_h + 30, last_w, type_array, "None");
	}
	
	// === Draw icons ABOVE each slot for number of dice loaded ===
	var slot = action_queue[| i];
	var dice_count = ds_list_size(slot.dice_list);

	if (dice_count > 0) {
	    var cx_top = draw_x + (draw_w / 2);
	    var cy_top = draw_y - 20; // slightly above tile
	    var spacing_top = 32;

	    for (var d = 0; d < dice_count; d++) {
	        var die_struct = slot.dice_list[| d];
	        var xx_top = cx_top - ((dice_count - 1) * spacing_top / 2) + (d * spacing_top);
	        var yy_top = cy_top;

	        // Color by action type
	        var _col;
	        switch (die_struct.action_type) {
	            case "ATK":  _col = make_color_rgb(255, 80, 80); break;   // red
	            case "HEAL": _col = make_color_rgb(80, 255, 100); break;  // green
	            case "BLK":  _col = make_color_rgb(100, 180, 255); break; // blue
				case "INTEL": _col = make_color_rgb(210, 210, 0); break;
	            default:     _col = make_color_rgb(160, 160, 160); break; // grey (generic)
	        }

	        draw_set_alpha(1.0);

			var _index = get_dice_index(die_struct.dice_value);

	        // Outline ones that are permanent
			if (die_struct.permanence == "base") {
				draw_sprite_ext(sDiceIcon, _index, xx_top, yy_top, 1.15, 1.15, 0, c_black, 1);
			}
			
			var dice_hovered = mouse_hovering(xx_top, yy_top, sprite_get_width(sDiceIcon), sprite_get_height(sDiceIcon), true);
			
			if (dice_hovered && !show_rewards) {
				queue_tooltip(mouse_x, mouse_y, die_struct.name, die_struct.description, undefined, 0, die_struct);
			}

	        // Draw sprite
			draw_sprite_ext(sDiceIcon, _index, xx_top, yy_top, 1, 1, 0, _col, 1);
			
			// Draw keyword icons above
			draw_dice_keywords(die_struct, xx_top + 3, yy_top - 34, 1);
			
			// Draw rolled value
			if (die_struct.rolled_value != -1) {
				draw_set_font(ftSmall);
				draw_set_color(c_black);
				
				var off_x = -3;
				var off_y = 3;
				
				switch (_index) {
					case 1:
					off_y = 2;
					break;
					case 2:
					off_x = -2;
					off_y = 1;
					break;
					case 3:
					off_x = 0;
					off_y = -1;
					break;
				}
				draw_text(xx_top + off_x, yy_top + off_y, string(die_struct.rolled_value));
			}
	    }
	}


	// === Draw colored bars BELOW each slot for possible action types ===
	var pos_type = slot.possible_type;
	var types = (pos_type == "All") ? ["ATK", "BLK", "HEAL"] : string_split(pos_type, " ");
	draw_action_type_bars(draw_x, draw_y + draw_h + 30, draw_w, types, action_queue_type);
}

// Entry feed
//var feed_x_pos = 50;
//var feed_y_pos = gui_h/2 - 200;
//var feed_line_height = 24;

//draw_set_font(ftDefault);
//draw_set_color(c_white);
//draw_set_halign(fa_left);
//draw_set_valign(fa_top);

//for (var i = 0; i < ds_list_size(combat_feed); i++) {
//    draw_colored_text(feed_x_pos, feed_y_pos + (i * feed_line_height), combat_feed[| i]);
//}

// --- Discard Button ---
var disc_x = gui_w - GUI_LAYOUT.DISCARD_W - 40;
var disc_y = gui_h - GUI_LAYOUT.DISCARD_H - 40;
var disc_w = GUI_LAYOUT.DISCARD_W;
var disc_h = GUI_LAYOUT.DISCARD_H;

// Dynamic label + color
var disc_color = is_discarding ? c_red : c_dkgray;

// Draw button via helper
var disc_btn = draw_gui_button(
    disc_x,
    disc_y,
    disc_w,
    disc_h,
    disc_btn_scale,
    "",
    disc_color,
    ftDefault,
    !show_rewards,         // active
	false
);

// Update animation
disc_btn_scale = disc_btn.scale;

// ---------------
// Draw enemy data
// ---------------

for (var e = 0; e < ds_list_size(room_enemies); e++) {
	var enemy_data = room_enemies[| e].data;
	var enemy = room_enemies[| e];
	
	var hover_enemy = mouse_hovering(enemy.pos_x, enemy.pos_y - 40, 230, 320, true);
	enemy.scale = lerp(enemy.scale, hover_enemy ? enemy.target_scale : enemy.start_scale, 0.2);
	enemy.info_alpha = lerp(enemy.info_alpha, hover_enemy ? 1.0 : 0, 0.4);
	
	if (hover_enemy && mouse_check_button_pressed(mb_left) && state == CombatState.PLAYER_INPUT && intel_level >= 2) {
		enemy_target_index = e;
	}
	
	// Draw enemy focus if we're the targeted enemy
	if (e == enemy_target_index) {
	
		var alpha_min = 0.2;
		var alpha_max = 0.33;
		var alpha_speed = 0.03;

		var pulse_alpha = alpha_min + (sin(oWorldManager.time * alpha_speed) * 0.5 + 0.5) * (alpha_max - alpha_min);

		draw_sprite_ext(sEnemyFocus, 0, enemy.pos_x, enemy.pos_y + 60, 1, 1, 0, c_white, enemy.alpha * pulse_alpha);
		draw_sprite_ext(sEnemyFocus, 0, enemy.pos_x, enemy.pos_y + 60, 0.9, 1, 0, c_white, enemy.alpha * pulse_alpha);
		draw_sprite_ext(sEnemyFocus, 0, enemy.pos_x, enemy.pos_y + 60, 1.2, 0.5, 0, c_white, enemy.alpha * pulse_alpha * 0.3);
	}
	
	// Draw enemy sprite
	draw_sprite_ext(sEnemies, 0, enemy.pos_x, enemy.pos_y + 70, enemy.scale, enemy.scale, 0, c_white, enemy.alpha);

	// Show enemy intent
	if (enemy.intent.alpha > 0.05) {
		var reveal_intent_single = false;
		var reveal_intent_all = false;
		if (intel_level >= 1) reveal_intent_single = true;
		if (intel_level >= 2) reveal_intent_all = true;
	
	    var col  = ((reveal_intent_single && e == enemy_target_index) || reveal_intent_all) ? enemy.intent.color : c_dkgray;
			
	    var text = ((reveal_intent_single && e == enemy_target_index) || reveal_intent_all) ? enemy.intent.text : "";
		
	

	    var xx = enemy.pos_x; // enemy position on screen
	    var yy = enemy.pos_y - 10 - (enemy.scale * 180);  // slightly above their head
		
		// Draw dice in move
		if ((reveal_intent_single && e == enemy_target_index) || reveal_intent_all) {
			for (var d = 0; d < enemy.intent.move.dice_amount; d++) {
				draw_sprite_ext(sDiceIcon, get_dice_index(enemy.intent.move.dice_value), xx - (((enemy.intent.move.dice_amount) * 40)/2) + (d * 40), yy - 10, 1, 1, 0, get_dice_color(enemy.intent.move.action_type), enemy.info_alpha * enemy.intent.alpha);
				
				if (d == enemy.intent.move.dice_amount - 1) {
					draw_set_font(ftBigger);
					draw_set_halign(fa_center);
					draw_set_valign(fa_middle);
					draw_outline_text("+" + string(enemy.intent.move.bonus_amount), c_black, get_dice_color(enemy.intent.move.action_type), 2, xx - (((enemy.intent.move.dice_amount) * 40)/2) + ((d+1) * 45), yy - 10, 1, enemy.info_alpha * enemy.intent.alpha, 0);
				}
			}
		}

	    draw_set_halign(fa_left);
	    draw_set_valign(fa_middle);

		// Draw attack value
		draw_set_font(ftTopBar);
		var text_w = string_width(text) + 10 + (sprite_get_width(sIntentIcons) * enemy.intent.scale);
		var index = 0;
		switch (col) {
		
		    case c_red: index = 0; break;
		    case c_aqua: index = 1;  break;
		    case c_lime: index = 2;  break;
		    case c_white: index = 3;  break;
		    case c_dkgray: index = 4;  break;
			default: index = 4; 
		}
		
		var sprite = sIntentIcons;
		var icon_x = xx - text_w/2 + 5 + ((sprite_get_width(sprite) / 2) * enemy.intent.scale);
		var text_x = icon_x + ((sprite_get_width(sprite) / 2) * enemy.intent.scale) + 10;
		var bonus_scale = 1;
		
		// enemy move is a debuff, draw sDebuffIcon, _debuff.template.icon_index instead of the standard icon
		if (enemy.intent.move.action_type == "DEBUFF" || enemy.intent.move.action_type == "BUFF") {
			if (reveal_intent_all) || (reveal_intent_single && e == enemy_target_index) {
				sprite = sDebuffIcon;
				index = enemy.intent.move.debuff.icon_index;
				bonus_scale = 1.5;
				icon_x = xx;
				col = enemy.intent.move.debuff.color;
			}
		}
	
		draw_sprite_ext(sprite, index, icon_x, yy, enemy.intent.scale * bonus_scale,  enemy.intent.scale * bonus_scale, 0, col, enemy.intent.alpha - enemy.info_alpha);
	    draw_outline_text(text, c_black, c_white, 2, text_x, yy, enemy.intent.scale, enemy.intent.alpha - enemy.info_alpha);
	
	    draw_set_halign(fa_center);
	
		// Draw attack name
		draw_set_font(ftBigger);
		var move_name = ((reveal_intent_single && e == enemy_target_index) || reveal_intent_all) ? string(enemy.intent.move.move_name) : "???";
		draw_outline_text(move_name, c_black, c_white, 2, xx, yy - 50, enemy.intent.scale, enemy.info_alpha * enemy.intent.alpha);
	
		if (mouse_hovering(xx, yy - 10, 220, 90, true) && !show_rewards) {
			if (enemy.intent.move.action_type == "DEBUFF" || enemy.intent.move.action_type == "BUFF") {
				queue_tooltip(mouse_x, mouse_y, enemy.intent.move.debuff.name, enemy.intent.move.debuff.desc, undefined, 0, undefined);
			} else {
				if (reveal_intent_all) {
					queue_tooltip(mouse_x, mouse_y, get_dice_name_and_bonus(enemy.intent.move, enemy.intent.move.bonus_amount), move_name, undefined, 0, undefined);
				} else if (reveal_intent_single && e == enemy_target_index) {
					queue_tooltip(mouse_x, mouse_y, get_dice_name_and_bonus(enemy.intent.move, enemy.intent.move.bonus_amount), move_name, undefined, 0, undefined);
				} else {
					queue_tooltip(mouse_x, mouse_y, "???", "Enemy intentions not revealed", undefined, 0, undefined);
				}
			}
		}
	}

	// =========================================================
	// ENEMY HEALTH BAR (right side)
	// =========================================================

	var bar_scale = enemy.bar_scale;
	
	var e_bar_w = sprite_get_width(sHealthBar) * bar_scale;
	var e_bar_h = sprite_get_height(sHealthBar) * bar_scale;
	var e_bar_x = enemy.pos_x - e_bar_w/2; // mirror enemy bar
	var e_bar_y = enemy.pos_y + 80;

	// Smooth animation
	enemy.hp_display = lerp(enemy.hp_display, enemy.hp, 0.1);
	enemy.hp_display = clamp(enemy.hp_display, 0, enemy.max_hp);

	var e_hp_ratio = clamp(enemy.hp_display / enemy.max_hp, 0, 1);
	var e_hp_color = merge_color(c_grey, c_red, e_hp_ratio);

	// Current HP
	draw_sprite_ext(sHealthBar, 1, e_bar_x, e_bar_y, e_hp_ratio * bar_scale, bar_scale, 0, e_hp_color, enemy.alpha);
	draw_sprite_ext(sHealthBar, 0, e_bar_x, e_bar_y, bar_scale, bar_scale, 0, c_white, enemy.alpha);

	// Text label
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_set_font(ftDefault);
	draw_outline_text(string_format(enemy.hp, 0, 0) + " / " + string(enemy.max_hp), c_black, c_white, 2, e_bar_x + e_bar_w / 2, e_bar_y + e_bar_h / 2, 1, enemy.alpha, 0);
	
	// Draw enemy name
	// Outline
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(ftDefault);
	draw_outline_text(string(enemy_data.name), c_black, c_white, 2, enemy.pos_x, enemy.pos_y + 50 + (enemy.scale * 100), 1, enemy.info_alpha * enemy.alpha);
		
	// Draw enemy block
	if (enemy.block_amount > 0) {
		var block_x = enemy.pos_x + e_bar_w/2;
		var block_y = e_bar_y + e_bar_h/2 + 2;
		var block_radius = 30;
		draw_set_color(c_blue);
		draw_sprite_ext(sIntentIcons, 1, block_x, block_y, bar_scale * 1.5, bar_scale * 1.5, 0, c_aqua, 1.0);
		draw_set_color(c_white);
		draw_set_alpha(enemy.alpha);
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_set_font(ftDefault);
		draw_outline_text(string(enemy.block_amount), c_black, c_white, 2, block_x, block_y - 4, 1, enemy.alpha, 0);
	}
	
	// Draw enemy debuffs
	var d_x = 10;
	var d_y = e_bar_y + e_bar_h + 5;
	var d_padding = 15;

	for (var d = 0; d < ds_list_size(enemy.debuffs); d++) {
		var _debuff = enemy.debuffs[| d];
		
		var col = _debuff.template.color;
		draw_sprite_ext(sDebuffIcon, _debuff.template.icon_index, e_bar_x + d_x + sprite_get_width(sDebuffIcon)/2, d_y + sprite_get_height(sDebuffIcon)/2, 1, 1, 0, col, 1.0);
		draw_set_font(ftDefault);
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		if (!_debuff.permanent) draw_outline_text(string(_debuff.remaining), c_black, c_white, 2, e_bar_x + d_x + sprite_get_width(sDebuffIcon), d_y + sprite_get_height(sDebuffIcon)/1.2, 1, 1, 0);
		draw_outline_text(string(_debuff.amount), c_black, c_red, 2, e_bar_x + d_x, d_y + sprite_get_height(sDebuffIcon)/1.2, 1, 1, 0);
	
		if (mouse_hovering(e_bar_x + d_x, d_y, sprite_get_width(sDebuffIcon), sprite_get_height(sDebuffIcon), false)) {
			queue_tooltip(mouse_x, mouse_y, _debuff.template.name, _debuff.template.desc, undefined, 0, undefined);
		}
	
		d_x += sprite_get_width(sDebuffIcon) + d_padding;
	}

}

// Draw player sprite
draw_sprite_ext(sEnemies, 0, global.player_x, global.player_y + 80, 1, 1, 0, c_white, 1.0);

// =========================================================
// PLAYER HEALTH BAR (left side)
// =========================================================
var p_bar_w = sprite_get_width(sHealthBar);
var p_bar_h = sprite_get_height(sHealthBar);
var p_bar_x = global.player_x - p_bar_w/2; // mirror enemy bar
var p_bar_y = global.player_y + 80;

// Smooth animation
player_hp_display = lerp(player_hp_display, global.player_hp, 0.1);
player_hp_display = clamp(player_hp_display, 0, global.player_max_hp);

var p_hp_ratio = clamp(player_hp_display / global.player_max_hp, 0, 1);
var p_hp_color = merge_color(c_red, c_red, p_hp_ratio);

// Current HP
draw_sprite_ext(sHealthBar, 1, p_bar_x, p_bar_y, p_hp_ratio, 1, 0, p_hp_color, 1.0);
draw_sprite_ext(sHealthBar, 0, p_bar_x, p_bar_y, 1, 1, 0, c_white, 1.0 );

// Text label
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
draw_set_font(ftDefault);
draw_outline_text(string_format(global.player_hp, 0, 0) + " / " + string(global.player_max_hp), c_black, c_white, 2, p_bar_x + p_bar_w / 2, p_bar_y + p_bar_h / 2, 1, 1.0, 0);

// Draw player debuffs
var d_x = 9;
var d_y = p_bar_y + p_bar_h + 5;
var d_padding = 22;

for (var d = 0; d < ds_list_size(global.player_debuffs); d++) {
	var _debuff = global.player_debuffs[| d];
	var col = _debuff.template.color;
	draw_sprite_ext(sDebuffIcon, _debuff.template.icon_index, p_bar_x + d_x + sprite_get_width(sDebuffIcon)/2, d_y + sprite_get_height(sDebuffIcon)/2, 1, 1, 0, col, 1.0);
	draw_set_font(ftDefault);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_outline_text(string(_debuff.remaining), c_black, c_white, 2, p_bar_x + d_x + sprite_get_width(sDebuffIcon), d_y + sprite_get_height(sDebuffIcon)/1.2, 1, 1, 0);
	draw_outline_text(string(_debuff.amount), c_black, c_red, 2, p_bar_x + d_x, d_y + sprite_get_height(sDebuffIcon)/1.2, 1, 1, 0);

	if (mouse_hovering(p_bar_x + d_x, d_y, sprite_get_width(sDebuffIcon), sprite_get_height(sDebuffIcon), false)) {
		queue_tooltip(mouse_x, mouse_y, _debuff.template.name, _debuff.template.desc, undefined, 0, undefined);
	}
	
	d_x += sprite_get_width(sDebuffIcon) + d_padding;
}

// Draw player block
if (player_block_amount > 0) {
	var block_x = global.player_x - 155;
	var block_y = p_bar_y + 25;
	var block_radius = 30;
	draw_set_color(c_blue);
	draw_sprite_ext(sIntentIcons, 1, block_x, block_y, 1, 1, 0, c_aqua, 1.0);
	draw_set_color(c_white);
	draw_set_alpha(1.0);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(ftDefault);
	draw_outline_text(string(player_block_amount), c_black, c_white, 2, block_x, block_y - 4, 1, 1.0, 0);
}

// Draw intel level
draw_sprite_ext(sIntelEye, global.player_intel_data[| intel_level].index, global.player_x, global.player_y - 180, intel_scale, intel_scale, 0, c_white, intel_alpha);
draw_outline_text(string(global.player_intel_data[| intel_level].name), c_black, global.color_intel, 2, global.player_x, global.player_y - 220, intel_scale, 1.0, 0);
var intel_hover = mouse_hovering(global.player_x, global.player_y - 190, sprite_get_width(sIntelEye) * 2, sprite_get_height(sIntelEye) * 2, true);

intel_scale = intel_hover ? lerp(intel_scale, 1.2, 0.2) : lerp(intel_scale, 1.0, 0.2);

if (player_intel > 0) {
	draw_outline_text(string(player_intel), c_black, c_white, 2, global.player_x + 30, global.player_y - 170, intel_scale, 1.0, 0);
}

if (intel_hover) queue_tooltip(mouse_x, mouse_y, "Intel level: "+string(global.player_intel_data[| intel_level].name), "Resets each turn. " + string(global.player_intel_data[| intel_level].description), undefined, 0, undefined);

/// DEBUG
if (debug_mode) {
	if (keyboard_check(vk_control)) {
	    draw_set_color(c_black);
		draw_set_font(ftDefault);
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
		draw_set_alpha(1.0);
	    draw_text(10, 10, "Last action slot hovered: " + string(last_hover));
	    draw_text(10, 30, "Is placing: " + string(is_placing));
	    draw_text(10, 50, "Is discarding: " + string(is_discarding));
	
		draw_set_alpha(0.3);
		draw_set_color(c_black);
		draw_rectangle(global.dice_safe_area_x1, global.dice_safe_area_y1, global.dice_safe_area_x2, global.dice_safe_area_y2, false);
	}
}

// show rewards
if (show_rewards) {
	draw_set_alpha(0.9);
	draw_set_color(c_black);
	draw_rectangle(0, 70, gui_w, gui_h, false);
	
	var reward_width = 1200;
	var reward_height = 550;
	
	draw_set_alpha(1.0);
	
	draw_set_alpha(1.0);
	draw_set_color(c_white);
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	draw_set_font(ftBigger);
	draw_outline_text("Rewards!", c_black, c_white, 2, gui_w/2, gui_h/2 - 350, 1, 1, 0);
	draw_set_font(ftDefault);
	draw_outline_text(string(rewards_stage) + "/" + string(ds_list_size(reward_list)), c_black, c_white, 2, gui_w/2, gui_h/2 - 300, 1, 1, 0);
	
	switch(reward_list[| rewards_stage - 1 ]) {
		case "dice":
			draw_set_font(ftDefault);
			draw_outline_text("Choose one die", c_black, c_white, 2, gui_w/2, gui_h/2 - 100, 1, 1, 0);
	
			for (var r = 0; r < ds_list_size(reward_dice_options); r++) {
			    var die = reward_dice_options[| r];

			    // --- Layout ---
			    var reward_w = 120;
			    var reward_h = 70;
			    var reward_padding = 120;
			    var reward_total_w = (ds_list_size(reward_dice_options) * reward_w) + ((ds_list_size(reward_dice_options) - 1) * reward_padding);
			    var reward_x = gui_w / 2 - (reward_total_w / 2);
			    var base_x = reward_x + (r * (reward_w + reward_padding));
			    var base_y = gui_h/2;
			    var base_w = reward_w;
			    var base_h = reward_h;
				
				// Draw background sprite
				var btn_col = make_colour_rgb(52, 55, 73);
				switch (die.rarity) {
					case "uncommon":
					btn_col = make_colour_rgb(42, 90, 85);
					break;
					
					case "rare":
					btn_col = make_colour_rgb(85, 42, 90);
					break;
				}
				var wobble = sin(((current_time / 1000) + r) * 3) * 3;
				draw_sprite_ext(sRewardFrame, 0, base_x + base_w/2, base_y + base_w/2 - 10, reward_scale[| r] * 0.95, reward_scale[| r] * 0.95, wobble, btn_col, 1.0);

			    // --- Draw dice sprite using hoverable scaling ---
			    var btn = draw_gui_button(
			        base_x, base_y,
			        base_w, base_h,
			        reward_scale[| r],
			        "", // no text (we’ll draw sprite manually)
			        die.color,
			        ftDefault,
			        !rewards_dice_taken,         // active
					false
			    );

			    // Update scale for animation
			    reward_scale[| r] = btn.scale;

			    // --- Choose sprite index based on dice value ---
			    var spr_index = get_dice_index( die.dice_value );

			    // --- Draw the dice sprite ---
			    var alpha = rewards_dice_taken ? 0.2 : 1.0;
			    draw_sprite_ext(
			        sDice,
			        spr_index,
			        btn.x + btn.w / 2,
			        btn.y + btn.h / 2,
			        btn.scale,
			        btn.scale,
			        0,
			        die.color,
			        alpha
			    );
		
				draw_dice_keywords(die, btn.x + btn.w / 2, btn.y + btn.h / 2, 1, alpha);

			    // --- Draw name ---
			    var label = string(die.name);
			    draw_set_color(c_white);
			    draw_set_alpha(alpha);
			    draw_set_halign(fa_center);
			    draw_set_valign(fa_middle);
			    draw_set_font(ftDefault);
			    draw_text(btn.x + btn.w / 2, btn.y + btn.h + 20, label);
		
				if (btn.hover) {
					queue_tooltip( mouse_x, mouse_y, die.name, die.description, undefined, 0, die);
				}

			    // --- Click logic: Take reward ---
			    if (!rewards_dice_taken && btn.click) {
			        var p = instance_create_layer(btn.x + btn.w / 2, btn.y + btn.h / 2, "Instances", oDiceParticle);
			        p.target_x = GUI_LAYOUT.PLAY_W;
			        p.target_y = gui_h - GUI_LAYOUT.PLAY_H / 2;
			        p.color_main = die.color;
			        p.die_struct = clone_die(die, "");

			        rewards_dice_taken = true;
			        global.bag_size++;
			    }
		
				// Need to add keepsake rewards on some fights, certainly on boss fights
		
				// Below code adds keepsakes
				//ds_list_add(keepsakes, get_keepsake_by_id("lucky_coin"));
			}
		break;
		
		case "consumables":
			draw_set_font(ftDefault);
			draw_outline_text("Choose two items", c_black, c_white, 2, gui_w/2, gui_h/2 - 100, 1, 1, 0);
	
			for (var r = 0; r < ds_list_size(reward_consumable_options); r++) {
			    var consumable = reward_consumable_options[| r];

			    // --- Layout ---
			    var reward_w = 120;
			    var reward_h = 70;
			    var reward_padding = 120;
			    var reward_total_w = (ds_list_size(reward_consumable_options) * reward_w) + ((ds_list_size(reward_consumable_options) - 1) * reward_padding);
			    var reward_x = gui_w / 2 - (reward_total_w / 2);
			    var base_x = reward_x + (r * (reward_w + reward_padding));
			    var base_y = gui_h/2;
			    var base_w = reward_w;
			    var base_h = reward_h;
				
				// Draw background sprite
				
				// Draw background sprite
				var btn_col = make_colour_rgb(52, 55, 73);
				switch (consumable.rarity) {
					case "uncommon":
					btn_col = make_colour_rgb(42, 90, 85);
					break;
					
					case "rare":
					btn_col = make_colour_rgb(85, 42, 90);
					break;
				}
				
				var wobble = sin(((current_time / 1000) + r) * 3) * 3;
				draw_sprite_ext(sRewardFrame, 0, base_x + base_w/2, base_y + base_w/2 - 10, reward_scale[| r] * 0.95, reward_scale[| r] * 0.95, wobble, btn_col, 1.0);

			    // --- Draw dice sprite using hoverable scaling ---
			    var btn = draw_gui_button(
			        base_x, base_y,
			        base_w, base_h,
			        reward_scale[| r],
			        "", // no text (we’ll draw sprite manually)
			        c_white,
			        ftDefault,
			        !consumable.taken,         // active
					false
			    );

			    // Update scale for animation
			    reward_scale[| r] = btn.scale;

			    // --- Draw the dice sprite ---
			    var alpha = 1.0
				if (consumable.taken) alpha = 0.2;
				
				var col = c_white;
				if (rewards_consumables_locked == r) col = c_black;
				
				// Draw consumable sprite
				
			    draw_sprite_ext(
			        consumable.sprite,
			        consumable.index,
			        btn.x + btn.w / 2,
			        btn.y + btn.h / 2,
			        btn.scale,
			        btn.scale,
			        0,
			        col,
			        alpha
			    );

			    // --- Draw name ---
			    var label = string(consumable.name);
			    draw_set_halign(fa_center);
			    draw_set_valign(fa_middle);
			    draw_set_font(ftDefault);
			    draw_outline_text(label, c_black, col, 2, btn.x + btn.w / 2, btn.y + btn.h + 20, 1, alpha, 0);
				
				// Draw chains over locked item
				
				if (rewards_consumables_locked == r) {
					draw_sprite_ext(
				        sRewardChain,
				        consumable.index,
				        btn.x + btn.w / 2,
				        btn.y + btn.h / 2 + 10,
				        btn.scale,
				        btn.scale,
				        wobble,
				        c_white,
				        1.0
				    );
				}
				
				// Draw quantity
				if (consumable.amount > 1) {
					draw_set_font(ftBig);
					draw_outline_text(consumable.amount, c_black, col, 2, btn.x + btn.w - 20, btn.y + btn.h - 20, 1, alpha, 0);
				}
		
				if (btn.hover) {
					var die = undefined;
					if (string_pos("Core", consumable.name) > 0) {
						die = clone_die(global.dice_d6_atk, "");
						die.distribution = consumable.distribution;
					}
					queue_tooltip( mouse_x, mouse_y, consumable.name, consumable.description, undefined, 0, die);
				}
				
				// check for item free

			    // Take first reward
			    if (rewards_consumables_first_taken == -1 && btn.click) {
					if (consumable.name != "Coins") {
						var first_free_slot = -1;
						for (var n = 0; n < array_length(oRunManager.items); n++) {
							if (oRunManager.items[n] == undefined) {
								first_free_slot = n;
								break;
							}
						}
						if (first_free_slot != -1) {
							var gained_item = gain_item(consumable);
							if (gained_item) {
								rewards_consumables_first_taken = r;
							}
						}
					} else {
						gain_coins(mouse_x, mouse_y, consumable.amount);
						consumable.taken = true;
						rewards_consumables_first_taken = r;
					}
					
			    }

			    // Take second reward
			    if (rewards_consumables_first_taken != -1 && !rewards_consumables_second_taken && btn.click && r != rewards_consumables_locked && !consumable.taken) {
					if (consumable.name != "Coins") {
						var first_free_slot = -1;
						for (var n = 0; n < array_length(oRunManager.items); n++) {
							if (oRunManager.items[n] == undefined) {
								first_free_slot = n;
								break;
							}
						}
						if (first_free_slot != -1) {
							oRunManager.items[n] = clone_item(consumable);
							oRunManager.items_hover_scale[n] = 1.2;
							consumable.taken = true;
							rewards_consumables_second_taken = true;
						}
					} else {
						gain_coins(mouse_x, mouse_y, consumable.amount);
						consumable.taken = true;
						rewards_consumables_second_taken = true;
					}
					
					
			    }
			}
				
			// After taking the first consumable reward
			if (rewards_consumables_first_taken != -1) {
				
				// Lock a random slot
				if (rewards_consumables_locked == -1) {	
					var available_items = [];
					
					// By looping through the rewards
					for (var r = 0; r < ds_list_size(reward_consumable_options); r++) {
						if (r != rewards_consumables_first_taken) {
							array_push(available_items, r);
						}
					}
					
					// and choosing a random one
					rewards_consumables_locked = available_items[choose(0,1)];
				}
			}
		break;
	}
	
	var next_x = gui_w - 300;
	var next_y = gui_h/2;
	
	var next_hover = mouse_hovering(next_x, next_y, sprite_get_width(sButtonSmall), sprite_get_height(sButtonSmall), true);
	
	var next_btn_col = c_lime;
	if (rewards_stage == ds_list_size(reward_list)) next_btn_col = c_red;
	if (instance_number(oDiceParticle) > 0) next_btn_col = c_dkgray;
	
	draw_sprite_ext(
		sButtonSmall,
		0,
	    next_x,                 // x
	    next_y,                 // y
	    reward_next_hover * 0.65,                      
	    reward_next_hover * 0.65,          // current scale
	    0,
	    next_btn_col,
	    1.0
	);
	
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_outline_text(rewards_stage == ds_list_size(reward_list) ? "Exit" : "Next", c_black, c_white, 2, next_x, next_y, reward_next_hover, 1.0, 0);

	// Update animation
	reward_next_hover = lerp(reward_next_hover, next_hover && !instance_exists(oDiceParticle) ? 1.2 : 1.0, 0.2);
	
	if (next_hover && mouse_check_button_pressed(mb_left) && instance_number(oDiceParticle) == 0) {
		if (rewards_stage < ds_list_size(reward_list)) {
			if (reward_list[| rewards_stage] == "dice") rewards_dice_taken = true;
			rewards_stage++;
			for (var s = 0; s < ds_list_size(reward_scale); s++) {
				reward_scale[| s] = 0.1;
			}
		} else {
			rewards_all_taken = true;
		}
		show_debug_message("Rewards taken: " + string(rewards_all_taken));
	}
}

// Draw discard bag either side (draw bag in oRunManager)
draw_sprite(sDiceBag, 1, gui_w - 60 - sprite_get_width(sDiceBag), gui_h - 40);
draw_set_font(ftBigger);
draw_set_valign(fa_bottom)
draw_set_halign(fa_right);
draw_outline_text("DISCARD", c_black, c_white, 2, gui_w - 10 - sprite_get_width(sDiceBag), gui_h - 33, 1, 1, 0);

// --- Draw discard count ---
draw_set_color(c_maroon);
draw_circle(gui_w - 70, gui_h - 55, 20, false);
draw_set_color(c_white);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
draw_set_font(ftBig);
draw_text(gui_w - 70, gui_h - 55, string(ds_list_size(global.discard_pile)));

// Draw discard preview
var disc_bag_x = gui_w - GUI_LAYOUT.BAG_X - GUI_LAYOUT.BAG_W;
var disc_bag_y = gui_h - GUI_LAYOUT.BAG_Y - GUI_LAYOUT.BAG_H;
var disc_bag_w = GUI_LAYOUT.BAG_W;
var disc_bag_h = GUI_LAYOUT.BAG_H;
disc_bag_hover = (mx > disc_bag_x && mx < disc_bag_x + disc_bag_w && my > disc_bag_y && my < disc_bag_y + disc_bag_h);

if (disc_bag_hover) {
    var disc_bag_bg_offset = 200;
	var disc_bag_bg_w = 420;
	var disc_bag_bg_h = 180;
    draw_set_color(c_black);
    draw_set_alpha(0.3);
	draw_roundrect(gui_w - disc_bag_bg_offset - disc_bag_bg_w, gui_h - disc_bag_bg_offset, gui_w - disc_bag_bg_offset, gui_h - disc_bag_bg_offset - disc_bag_bg_h, false);

    // === Draw dice from bag ===
    var dice_per_row = 5;
	var dice_scale = 1;
    var dice_spacing = 80 * dice_scale;
	var padding = 50 * dice_scale;
    var start_x = gui_w - disc_bag_bg_offset - disc_bag_bg_w + padding;
    var start_y = gui_h - disc_bag_bg_offset - disc_bag_bg_h + padding;

    for (var i = 0; i < ds_list_size(global.discard_pile); i++) {
        var die_struct = global.discard_pile[| i];

        // Position in grid
        var col = i mod dice_per_row;
        var row = i div dice_per_row;

        var xx = start_x + (col * dice_spacing);
        var yy = start_y + (row * dice_spacing);

        // Choose color based on action type
        var colr = get_dice_color(die_struct.action_type);

        // Choose image index based on dice type
        var frame = get_dice_index(die_struct.dice_value);

        // Draw dice sprite
        draw_set_alpha(1);
        draw_set_color(colr);
        draw_sprite_ext(sDice, frame, xx, yy, dice_scale, dice_scale, 0, colr, 1);
		draw_dice_keywords(die_struct, xx, yy, 1);

        // Optional: outline or count number
        //draw_set_color(c_black);
        //draw_set_alpha(0.5);
        //draw_rectangle(xx - 32, yy - 32, xx + 32, yy + 32, false);
    }
}