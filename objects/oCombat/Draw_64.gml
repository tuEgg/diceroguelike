gui_w = display_get_gui_width();
gui_h = display_get_gui_height();

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

// Draw enemy sprite
draw_sprite_ext(sEnemies, 0, global.enemy_x, global.enemy_y + 80, 1, 1, 0, c_white, enemy_alpha);

// Draw player sprite
draw_sprite_ext(sEnemies, 0, global.player_x, global.player_y + 80, 1, 1, 0, c_white, 1.0);

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

draw_set_font(ftBagInfo);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
dice_played_scale = lerp(dice_played_scale, 1.0, 0.05);
dice_played_color = merge_colour(dice_played_color, c_white, 0.05);
var played_dice_string = string(dice_played) + "/" + string(dice_allowed_per_turn);
draw_outline_text(played_dice_string, c_black, dice_played_color, 2, aq_start_x - aq_tile_w/2 - aq_tile_padding + 12, aq_start_y + aq_tile_w/2 - 40, dice_played_scale, 1.0, 0);

var played_dice_hover = mouse_hovering(aq_start_x - aq_tile_w/2 - aq_tile_padding + 12, aq_start_y + aq_tile_w/2 - 40, string_width(played_dice_string), string_height(played_dice_string), true);

if (played_dice_hover && !show_rewards) queue_tooltip(mouse_x, mouse_y, "Played dice", "You have played " + played_dice_string + " total dice this turn");

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
if (play_btn.click && state == CombatState.PLAYER_INPUT) {
    add_feed_entry("You clicked PLAY!");
    state = CombatState.RESOLVE_ROUND;
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
	switch (action_queue_type) {
		case "ATK":
		draw_col = make_colour_rgb(255, 15, 0);
		break;
		case "BLK":
		draw_col = c_aqua;
		break;
		case "HEAL":
		draw_col = c_lime;
		break;
		default:
		draw_col = c_white;
	}
	
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

    // --- Highlight the active action slot during RESOLVE_ROUND ---
	if (state == CombatState.RESOLVE_ROUND && !enemy_turn_done) {
	    if (i == action_index - 1) {
	        slot_index = 0;
	    }
	}

	// Draw the main slot sprite
	draw_sprite_ext(sActionSlot, slot_index, draw_x, draw_y, current_scale, current_scale, 0, draw_col, 1.0);
	
	var stats = get_slot_stats(action_queue[| i], i);
	var _low_roll = stats.low_roll;
	var _high_roll = stats.high_roll;
	var total_amount = stats.amount;
	var highest_value = stats.value;
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
		
		// Build unique types from global.sacrifice_list (as before)
		var type_array = [];
		
		for (var s = 0; s < ds_list_size(global.sacrifice_list); s++) {
		    var die_struct = global.sacrifice_list[| s];
			
			var poss_types = string_split(die_struct.possible_type, " ");
			var total = array_length(poss_types);
			
			for (var t = 0; t < total; t++) {
				if (!array_contains(type_array, poss_types[t])) {
					array_push(type_array, poss_types[t]);
				}
			}
		}
		
		draw_action_type_bars(last_x, last_y + last_h + 30, last_w, type_array, action_queue[| i].current_action_type);
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
	            default:     _col = make_color_rgb(160, 160, 160); break; // grey (generic)
	        }

	        draw_set_alpha(1.0);
			
			var _index = 0;
			if (die_struct.dice_value == 2) _index = 2;
			if (die_struct.dice_value == 6) _index = 1;

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
				draw_text(xx_top - 3, yy_top + 2, string(die_struct.rolled_value));
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

// Show enemy intent
if (enemy_intent_alpha > 0.05) {
    var text = enemy_intent_text;
    var col  = enemy_intent_color;

    var xx = global.enemy_x; // enemy position on screen
    var yy = global.enemy_y - 200;  // slightly above their head

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

	// Draw attack value
	draw_set_font(ftTopBar);
	var text_w = string_width(text);
	var index = 0;
	switch (enemy_intent_color) {
		
	    case c_red: index = 0; break;
	    case c_aqua: index = 1;  break;
	    case c_lime: index = 2;  break;
		default: index = 3; 
	}
	
	draw_sprite_ext(sIntentIcons, index, xx - text_w/2, yy, enemy_intent_scale, enemy_intent_scale, 0, col, enemy_intent_alpha);
    draw_outline_text(text, c_black, c_white, 2, xx + text_w/2, yy, enemy_intent_scale, enemy_intent_alpha);
	
	// Draw attack name
	draw_set_font(ftBag);
	draw_outline_text(string(enemy_intent.move_name), c_black, c_white, 2, xx, yy - 50, enemy_intent_scale, enemy_intent_alpha);
	
	if (mouse_hovering(xx, yy - 20, 200, 70, true) && !show_rewards) {
		if (enemy_intent.action_type == "DEBUFF") {
			queue_tooltip(mouse_x, mouse_y, enemy_intent.debuff.name, enemy_intent.debuff.desc, undefined, 0, undefined);
		} else {
			queue_tooltip(mouse_x, mouse_y, get_dice_name_and_bonus(enemy_intent, enemy_intent.bonus_amount), string(enemy_intent.move_name), undefined, 0, undefined);
		}
	}
}


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
draw_sprite_ext(sHealthBar, 1, p_bar_x, p_bar_y, p_hp_ratio, 1, 0, p_hp_color, enemy_alpha);
draw_sprite_ext(sHealthBar, 0, p_bar_x, p_bar_y, 1, 1, 0, c_white, enemy_alpha);

// Text label
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
draw_set_font(ftBagInfo);
draw_outline_text(string_format(global.player_hp, 0, 0) + " / " + string(global.player_max_hp), c_black, c_white, 2, p_bar_x + p_bar_w / 2, p_bar_y + p_bar_h / 2, 1, 1.0, 0);

// Draw debuffs
var d_x = 0;
var d_padding = 10;

for (var d = 0; d < ds_list_size(player_debuffs); d++) {
	var _debuff = player_debuffs[| d];
	var col = c_green;
	if (_debuff.template.debuff) col = c_red;
	draw_sprite_ext(sDebuffIcon, _debuff.template.icon_index, p_bar_x + d_x, p_bar_y + p_bar_h + 20, 1, 1, 0, col, 1.0);
	draw_set_font(ftDefault);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_outline_text(string(_debuff.remaining), c_black, c_white, 2, p_bar_x + d_x + sprite_get_width(sDebuffIcon), p_bar_y + p_bar_h + 20 + sprite_get_height(sDebuffIcon), 1, 1, 0);
	
	if (mouse_hovering(p_bar_x + d_x, p_bar_y + p_bar_h + 20, sprite_get_width(sDebuffIcon), sprite_get_height(sDebuffIcon), false)) {
		queue_tooltip(mouse_x, mouse_y, _debuff.template.name, _debuff.template.desc, undefined, 0, undefined);
	}
	
	d_x += sprite_get_width(sDebuffIcon) + d_padding;
}


// =========================================================
// ENEMY HEALTH BAR (right side)
// =========================================================
var e_bar_w = sprite_get_width(sHealthBar);
var e_bar_h = sprite_get_height(sHealthBar);
var e_bar_x = global.enemy_x - e_bar_w/2; // mirror enemy bar
var e_bar_y = global.enemy_y + 80;

// Smooth animation
enemy_hp_display = lerp(enemy_hp_display, enemy_hp, 0.1);
enemy_hp_display = clamp(enemy_hp_display, 0, enemy_max_hp);

var e_hp_ratio = clamp(enemy_hp_display / enemy_max_hp, 0, 1);
var e_hp_color = merge_color(c_grey, c_red, e_hp_ratio);

// Current HP
draw_sprite_ext(sHealthBar, 1, e_bar_x, e_bar_y, e_hp_ratio, 1, 0, e_hp_color, enemy_alpha);
draw_sprite_ext(sHealthBar, 0, e_bar_x, e_bar_y, 1, 1, 0, c_white, enemy_alpha);

// Text label
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
draw_outline_text(string_format(enemy_hp, 0, 0) + " / " + string(enemy_max_hp), c_black, c_white, 2, e_bar_x + e_bar_w / 2, e_bar_y + e_bar_h / 2, 1, 1.0, 0);

// Draw enemy name
// Outline
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(ftDefault);
draw_outline_text(string(enemy.name), c_black, c_white, 2, global.enemy_x, global.enemy_y + 150, 1, 1);

// Draw enemy block
if (enemy_block_amount > 0) {
	var block_x = global.enemy_x + 150;
	var block_y = e_bar_y + 25;
	var block_radius = 30;
	draw_set_color(c_blue);
	draw_sprite_ext(sIntentIcons, 1, block_x, block_y, 1, 1, 0, c_aqua, 1.0);
	draw_set_color(c_white);
	draw_set_alpha(enemy_alpha);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(ftDefault);
	draw_outline_text(string(enemy_block_amount), c_black, c_white, 2, block_x, block_y - 4, 1, 1.0, 0);
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
	
	draw_set_alpha(0.1);
	draw_set_color(c_white);
	draw_rectangle(gui_w/2 - reward_width/2, gui_h/2 - reward_height/2, gui_w/2 + reward_width/2, gui_h/2 + reward_height/2, false);
	draw_set_alpha(1.0);
	
	draw_set_alpha(1.0);
	draw_set_color(c_white);
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	draw_set_font(ftBagInfo);
	draw_text(gui_w/2, gui_h/2 - (reward_height/2) + 50, "Rewards!");
	
	draw_set_font(ftDefault);
	draw_text(gui_w/2, gui_h/2 - (reward_height/2) + 150, "Choose a dice to add");
	
	for (var r = 0; r < ds_list_size(reward_options); r++) {
	    var die = reward_options[| r];

	    // --- Layout ---
	    var reward_w = 120;
	    var reward_h = 70;
	    var reward_padding = 120;
	    var reward_total_w = (ds_list_size(reward_options) * reward_w) + ((ds_list_size(reward_options) - 1) * reward_padding);
	    var reward_x = gui_w / 2 - (reward_total_w / 2);
	    var base_x = reward_x + (r * (reward_w + reward_padding));
	    var base_y = gui_h/2 - (reward_height/2) + 200;
	    var base_w = reward_w;
	    var base_h = reward_h;

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
	    var spr_index = 0
		if (die.dice_value == 6) spr_index = 1;
		if (die.dice_value == 2) spr_index = 2;

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
		
		draw_dice_keywords(die, btn.x + btn.w / 2, btn.y + btn.h / 2, 1);

	    // --- Draw name ---
	    var label = string(die.name);
	    draw_set_color(c_white);
	    draw_set_alpha(alpha);
	    draw_set_halign(fa_center);
	    draw_set_valign(fa_middle);
	    draw_set_font(ftDefault);
	    draw_text(btn.x + btn.w / 2, btn.y + btn.h + 20, label);

	    //// --- Draw description ---
		//draw_set_font(ftSmall);
		//draw_set_halign(fa_left);
	    //var desc = die.description;
		//var xx = btn.x + btn.w/2;
		//var _description_parsed = parse_text_with_keywords(desc);
		//for (var i = 0; i < array_length(_description_parsed); i++) {
		//    draw_set_colour(_description_parsed[i].colour);
		//    draw_text(xx - string_width(desc)/2, btn.y + btn.h + 40, _description_parsed[i].text);
		//    xx += string_width(_description_parsed[i].text);
		//}
		
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
	
	draw_set_color(c_white);
	draw_set_font(ftDefault);
	draw_set_valign(fa_top);
	draw_set_halign(fa_center);
	draw_text(gui_w/2, gui_h/2 - (reward_height/2) + 400, "Bounty reward");
	
	var credits_btn = draw_gui_button(
	    gui_w/2 - 100,                 // x
	    gui_h/2 - (reward_height/2) + 450,                 // y
	    200, 50,                       // base size
	    reward_credits_hover,          // current scale
	    "Doubloons: " + string(reward_credits),
	    make_color_rgb(200, 200, 0), ftTopBar,
	    !rewards_credits_taken,         // active
		true
	);

	// Update animation
	reward_credits_hover = credits_btn.scale;
		
	if (!rewards_credits_taken && credits_btn.click) {
		oRunManager.credits += enemy.bounty;
		rewards_credits_taken = true;
	}
	
	var skip_btn = draw_gui_button(
	    gui_w/2 - 100,                 // x
	    gui_h/2 + (reward_height/2) + 50,                 // y
	    200, 50,                       // base size
	    reward_skip_hover,          // current scale
	    "Skip",
	    make_color_rgb(125, 125, 125), ftTopBar,
	    !rewards_all_taken && !instance_exists(oDiceParticle),         // active
		true
	);

	// Update animation
	reward_skip_hover = skip_btn.scale;
		
	if (!rewards_all_taken && skip_btn.click) {
		rewards_all_taken = true;
	}
}

// Draw discard bag either side (draw bag in oRunManager)
draw_sprite(sDiceBag, 1, gui_w - 60 - sprite_get_width(sDiceBag), gui_h - 40);
draw_set_font(ftBag);
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
draw_set_font(ftBagInfo);
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
        var colr;
        switch (die_struct.action_type) {
            case "ATK":  colr = c_red; break;
            case "HEAL": colr = c_lime; break;
            case "BLK":  colr = c_aqua; break;
            default:     colr = c_white; break;
        }

        // Choose image index based on dice type
        var frame = 0;
        switch (die_struct.dice_value) {
            case 2: frame = 2; break;
            case 4: frame = 0; break;
            case 6: frame = 1; break;
            default: frame = 0; break;
        }

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