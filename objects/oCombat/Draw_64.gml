var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

var tooltip = "";

aq_tile_w = 62.48177 * power(1.000414, gui_w); // using desmos graphic calculator, expontential regression at these values: 1600 = 120, 1920 = 140, 2560 = 180

var aq_list_size = ds_list_size(action_queue);
var aq_tile_padding = aq_tile_w / 7;
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

var played_dice_hover = mouse_hovering(aq_start_x - aq_tile_w/2 - aq_tile_padding + 12, aq_start_y + aq_tile_w/2 - 40, 100, 50, true);

if (played_dice_hover && !show_rewards) queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Played dice", "You can play " + string(dice_allowed_per_turn - dice_played) + " more dice this turn");

// --- Play Button ---
var btn_x = aq_start_x - 120 - (30 * global.ui_scale); // top left position of the button
var btn_y = aq_start_y + (70 * global.ui_scale);
var btn_w = 120 + ((20 * global.ui_scale));
var btn_h = sprite_get_height(sEndTurn);

var btn_scaler = btn_w / 140; // used to scale the button at different ui sizes

// Determine label dynamically
// Need to have it say "Dealing Dice" when its the start of a turn 
var label_text = "";
var label_col = c_dkgray;

switch (state) {
	case CombatState.PLAYER_INPUT:
		if (dice_to_deal > 0) {
			label_text = "DEALING DICE";
			label_col = c_dkgray;
		} else {
			label_text = "END TURN " + string(turn_count);
			label_col = global.ui_primary; // the screen's main go action, same green as Embark
		}
	break;
	
	default:
		label_text = "PENDING";
		label_col = c_dkgray;
}

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
	false,
	UI_LAYER.BASE,
	soSlotHover,
	noone
);

// Update animation state
btn_scale = play_btn.scale;

var end_text_pos = btn_x + (btn_w/2) - (20 * global.ui_scale);

// once your hand is empty, End Turn breathes so it is obvious what is next
var end_draw_scale = btn_scale;
if (state == CombatState.PLAYER_INPUT && dice_to_deal <= 0 && instance_number(oDice) == 0 && !show_rewards) end_draw_scale *= 1 + 0.05 * (0.5 + 0.5 * sin(current_time / 220));
draw_sprite_ext(sEndTurn, 0, btn_x + btn_w/2, btn_y + btn_h/2, end_draw_scale * btn_scaler, end_draw_scale * btn_scaler, 0, label_col, 1);
draw_set_color(c_white);
draw_set_font(ftDefault);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_outline_text(label_text, c_black, c_white, 2, end_text_pos, btn_y + (btn_h/2), btn_scale, btn_scale, 0);

// Draw playable dice

draw_set_font(ftBig);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
dice_played_scale = lerp(dice_played_scale, 1.0, 0.05);
dice_played_color = merge_colour(dice_played_color, c_white, 0.05);
// plays left this turn, as a row of pips: filled for each play left, hollow for each used (coins don't use one)
var _plays_total = max(dice_allowed_per_turn, dice_played);
var _plays_left = max(0, dice_allowed_per_turn - dice_played);
var _pip = 20 * dice_played_scale, _pip_gap = 7;
var _pips_w = _plays_total * _pip + (_plays_total - 1) * _pip_gap;
var _pips_x = end_text_pos + 8 - _pips_w / 2, _pips_y = aq_start_y + aq_tile_w/2 - 40;
draw_set_font(ftDefault);
draw_outline_text((_plays_left == 1) ? "1 play left" : string(_plays_left) + " plays left", c_black, dice_played_color, 2, end_text_pos + 8, _pips_y - 30, 1, 1.0, 0);
for (var _p = 0; _p < _plays_total; _p++) {
	var _px = _pips_x + _p * (_pip + _pip_gap);
	draw_set_color(c_black);
	draw_roundrect_ext(_px - 2, _pips_y - _pip / 2 - 2, _px + _pip + 2, _pips_y + _pip / 2 + 2, 6, 6, false);
	draw_set_color((_p < _plays_left) ? dice_played_color : make_color_rgb(60, 60, 70));
	draw_roundrect_ext(_px, _pips_y - _pip / 2, _px + _pip, _pips_y + _pip / 2, 5, 5, false);
}
draw_set_color(c_white);
draw_set_font(ftBig);

// Click handling
if (play_btn.click && state == CombatState.PLAYER_INPUT && !is_dealing_dice && tutorial_allows("end_turn")) {
    actions_submitted = true;
}
// the tutorial points here: the sprite as drawn, from its origin and scale
var _et_s = btn_scale * btn_scaler;
tut_end_turn = { x: btn_x + btn_w/2 - sprite_get_xoffset(sEndTurn) * _et_s, y: btn_y + btn_h/2 - sprite_get_yoffset(sEndTurn) * _et_s, w: sprite_get_width(sEndTurn) * _et_s, h: sprite_get_height(sEndTurn) * _et_s };

hovered_slot = -1;

// Draw action slots
for (var i = 0; i < aq_list_size; i++) {
	var base_x = aq_start_x + (i * (aq_tile_w + aq_tile_padding));
	var base_y = aq_start_y + (aq_tile_w/140);
	var base_w = aq_tile_w;
	var base_h = aq_tile_w;
	
    var current_scale = tile_scale[| i];
    var draw_w = base_w * current_scale * aq_tile_w/140;
    var draw_h = base_h * current_scale * aq_tile_w/140;
    var draw_x = base_x + (base_w - draw_w) / 2;
    var draw_y = base_y + (base_h - draw_h) / 2;

    // Hover check based on *scaled* rectangle
	var hover = mouse_hovering(draw_x, draw_y, draw_w, draw_h, false, soSlotHover, noone, !show_rewards, UI_LAYER.BASE, string(base_x) + "," + string(base_y));
    //var hover = (mx > draw_x && mx < draw_x + draw_w && my > draw_y && my < draw_y + draw_h && !show_rewards);
	
	if (hover) {
		hovered_slot = i;
	}
	
	if (global.ui_layer > UI_LAYER.BASE) hover = false;

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
	var draw_alpha_val = 1.0;
	var col = c_white;

	// Check if any dice are being dragged
	var dragged_die_inst = noone;
	with (oDice) {
	    if (is_dragging) {
	        dragged_die_inst = id;
	        break; // stop once we find one
	    }
	}
	
	var draw_playable_slots = false

	if (dragged_die_inst != noone) {
	    var grabbed_die_struct = dragged_die_inst.struct;

	    if (!can_place_dice_in_slot(grabbed_die_struct, action_queue[| i], i)) {
	        // Fade invalid targets
	        draw_alpha_val = 1.0;
	        col = c_white;
	    } else {
	        // Highlight valid targets slightly
	        draw_alpha_val = 1.0;
			draw_playable_slots = true;
	    }
	}
	
	var slot_index = 1;
	
	if (locked_slot == i) draw_col = c_dkgray;
	if (bound_slot == i && !show_rewards) {
		var _slot_pos = oCombat.slot_positions[| oCombat.bound_slot];
					
		var start_x = _slot_pos.x + (_slot_pos.w / 2);
		var start_y = _slot_pos.y + (_slot_pos.h / 2);
					
		particle_emit(start_x, start_y, "constant", c_green, 1);
	}

    // --- Highlight the active action slot during RESOLVE_ROUND ---
	if (state == CombatState.RESOLVE_ROUND && !enemies_turn_done) {
	    if (i == draw_action_index) {
	        slot_index = 0;
			
			// double up the sprite so the visual is more obvious
			draw_sprite_ext(sActionSlot, slot_index, draw_x, draw_y, current_scale * aq_tile_w/140, current_scale * aq_tile_w/140, 0, draw_col, 1.0);
		}
	}
	
	// Draw slot highlight if we can play to it
	//if (draw_playable_slots) {
	//	draw_sprite_ext(sActionSlotHighlight, slot_index, draw_x - 12, draw_y - 12, current_scale, current_scale, 0, c_white, 0.3);
	//}

	// Draw the main slot sprite
	//draw_wonky_rectangle(draw_x, draw_y, current_scale * aq_tile_w, current_scale * aq_tile_w, draw_col, c_black, draw_alpha_val, false, true);
	draw_sprite_ext(sActionSlot, slot_index, draw_x, draw_y, current_scale * aq_tile_w/140, current_scale * aq_tile_w/140, 0, draw_col, draw_alpha_val);
	
	// If slot locked, draw the chain
	if (locked_slot == i) {
		draw_sprite_ext(sRewardChain, 0, draw_x + draw_w/2, draw_y + draw_h/2, current_scale * 0.75 * aq_tile_w/140, current_scale * 0.75 * aq_tile_w/140, 0, c_white, 1.0);
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
	
	// Draw dice outcome (an empty slot has none to show)
	if (label != "" && !(_low_roll == 0 && _high_roll == 0)) {
		draw_set_font(ftDefault);
	    draw_outline_text( "(" + string(_low_roll) + "-" + string(_high_roll) + ")", c_black, c_white, 2, draw_x + draw_w / 2, draw_y + draw_h - 35, 1, 1, 0);
	}

	// where the slot's bonuses come from
	if (hover && array_length(action_queue[| i].bonuses) > 0 && !show_rewards && !is_placing) { // while dragging a die, the placement hint takes this spot
		queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Slot bonuses", slot_bonus_breakdown(action_queue[| i]));
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
		if (tutorial_active() && next_index != current_index) global.tut.switched = true; // the tutorial's right-click step
		
		if (next_index != current_index) {
			sfx_play(soSlotPlace, AUDIO_GROUP.UI, random_range(0.01, 0.05), 1);
			combat_trigger_effects("after_change_current_action", {});
		}
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

			// the same rule placing uses: say what will happen, or why it can't
			if (dragged_die_inst != noone) {
				var place_check = slot_placement_check(dragged_die_inst.struct, action_queue[| i], i);
				if (!place_check.ok) {
					tooltip = "Can't place here";
					queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Can't place here", place_check.reason);
				} else if (place_check.action == "claim") {
					tooltip = "Start a " + string(grabbed_amount) + "d" + string(grabbed_value) + " " + string(grabbed_type) + " slot";
				} else if (place_check.action == "replace") {
					tooltip = "Clear this slot and take it";
				} else {
					tooltip = add_text;
				}
			}
		} else {
			
			// the whole slot's flat bonus, like dice notation: 3 dice at +1 each read "3d4+3"
			var _slot_bonus = slot_total_bonus(action_queue[| i], slot_amount);
			var _bonus = "";
			switch (sign(_slot_bonus)) {
				case 1:
				_bonus = "+" + string(_slot_bonus);
				break;
				case -1:
				_bonus = string(_slot_bonus);
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
				tooltip = string(slot_amount) + "d" + string(slot_value) + _bonus + " Insight";
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
	
	// a potion that goes on a slot (Rigger's Tonic, Bilge-Purge) is being carried: every slot pulses where it can land.
	// The drop itself happens in oRunManager on release (combat_item_drop), so draw order doesn't matter.
	if (combat_carrying_slot_item() && !show_rewards) {
		var _pulse = 0.5 + 0.5 * sin(current_time / 180);
		var _grow = 6 + 4 * _pulse;
		draw_set_color(global.color_intel);
		draw_set_alpha(0.45 + 0.4 * _pulse);
		for (var _w = 0; _w < 3; _w++) draw_roundrect(draw_x - _grow - _w, draw_y - _grow - _w, draw_x + draw_w + _grow + _w, draw_y + draw_h + _grow + _w, true);
		draw_set_alpha(1);
	}
	
	// Draw "make new action" tile after the last action slot
	if (i == ds_list_size(action_queue) - 1) {
		
		var c_scale = last_action_scale;
	    var last_w = base_w * c_scale
	    var last_h = base_h * c_scale;
		var lx = aq_start_x + ( (i+1) * (aq_tile_w + aq_tile_padding) );
	    var last_x = lx + ((base_w - last_w) / 2);
	    var last_y = base_y + ((base_h - last_h) / 2);

	    // Hover check basesd on *scaled* rectangle
		last_hover = mouse_hovering(last_x, last_y, last_w, last_h, false, soSlotHover, noone, !show_rewards, UI_LAYER.BASE, string(lx));
		tut_last_tile = { x: last_x, y: last_y, w: last_w, h: last_h }; // the tutorial points here
	    //last_hover = (mx > last_x && mx < last_x + last_w && my > last_y && my < last_y + last_h && !show_rewards);

	    // Smooth scale update
	    var t_scale = last_hover ? 1.2 : 1.0;
	    c_scale = lerp(c_scale, t_scale, 0.2);
	    last_action_scale = c_scale;
		
	    last_w = base_w * c_scale;
	    last_h = base_h * c_scale;
	    last_x = lx + ((base_w - last_w) / 2);
	    last_y = base_y + ((base_h - last_h) / 2);

		draw_sprite_ext(sActionSlot, 2, last_x, last_y, c_scale * aq_tile_w/140, c_scale * aq_tile_w/140, 0, c_white, 1);

		// Draw text
	    draw_set_halign(fa_center);
	    draw_set_valign(fa_middle);
		draw_set_font(ftDefault);
		draw_outline_text("Sacrifice\n" + string(sacrificies_til_new_action_tile) + ((sacrificies_til_new_action_tile == 1) ? " die" : " dice"), c_black, c_white, 2, last_x + last_w / 2, last_y + last_h / 2, 1, 1, 0);
		
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
			
			// multitype dice blend their types' colours, like they do everywhere else
			if (string_pos(" ", die_struct.possible_type) > 0) _col = get_dice_color(die_struct.possible_type);

	        draw_set_alpha(1.0);

			var _index = get_dice_index(die_struct.dice_value);
			
			var _angle = 0;
			var this_dice_spin = 0;
			var this_dice_scale = 1;
			
			// Emphasise rolled dice
			if (d == draw_dice_index && state == CombatState.RESOLVE_ROUND && i == draw_action_index && !player_turn_done) {
				_angle = sin(((current_time / 1000) + 20) * 3.33) * 3;
				dice_spin = lerp(dice_spin, 360, 0.15);
				this_dice_spin =- dice_spin;
				this_dice_scale = 1 - ((360/this_dice_spin)*0.3);
				draw_sprite_ext(sDiceIcon, _index, xx_top, yy_top, lerp(1.5, abs(_angle) + 1.5, 0.2), lerp(1.5, abs(_angle) + 1.5, 0.2), _angle, _col, 0.4);
			}

	        // Outline ones that are sticky or played this turn
			if (die_struct.permanence == "sticky" || die_struct.permanence == "base") {
				draw_sprite_ext(sDiceIcon, _index, xx_top, yy_top, 1.15 * this_dice_scale, 1.15 * this_dice_scale, this_dice_spin, c_black, 1);
			}
			
			var dice_hovered = mouse_hovering(xx_top, yy_top, sprite_get_width(sDiceIcon), sprite_get_height(sDiceIcon), true);
			
			if (dice_hovered && !show_rewards) {
				queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), die_struct.name, die_description(die_struct), undefined, 0, die_struct);
			}

	        // Draw sprite
			draw_sprite_ext(sDiceIcon, _index, xx_top, yy_top, 1 * this_dice_scale, 1 * this_dice_scale, this_dice_spin, _col, 1);
			
			// Draw keyword icons above
			draw_dice_keywords(die_struct, xx_top + 3, yy_top - 34, 1);
			if (global.action_icons) draw_action_type_icon(die_struct.action_type, xx_top - 13, yy_top + 13, 0.8); // Settings > Display > Action icons on dice
			
			// Slot bonus badge in the die's bottom-right corner: every-die bonuses, plus first-die ones on the first die.
			// The keyword icons sit above the die and the rolled number in its middle, so the corner is free.
			var _die_bonus = slot.bonus_amount + (d == 0 ? slot.first_die_bonus : 0);
			if (_die_bonus != 0) {
				var _old_halign = draw_get_halign(); // put the alignment back after, the rolled number below relies on it
				var _old_valign = draw_get_valign();
				draw_set_font(ftSmall);
				draw_set_halign(fa_center);
				draw_set_valign(fa_middle);
				var _badge_col = _die_bonus > 0 ? c_lime : c_red;
				draw_outline_text((_die_bonus > 0 ? "+" : "") + string(_die_bonus), c_black, _badge_col, 2, xx_top + 12, yy_top + 12, this_dice_scale, 1, 0);
				draw_set_halign(_old_halign);
				draw_set_valign(_old_valign);
			}
			
			
			draw_set_font(ftSmall);
			draw_set_color(c_black);
				
			// used to offset the rolled numbers
			var off_x = -2;
			var off_y = 1;
				
			switch (_index) {
				case 1:
				off_x = -2;
				off_y = 3;
				break;
				case 2:
				off_x = -2;
				off_y = 1;
				break;
				case 3:
				case 4:
				case 5:
				off_x = 0;
				off_y = -1;
				break;
			}
			
			// Draw rolled value
			if (die_struct.rolled_value != -1) {
				draw_text(xx_top + off_x, yy_top + off_y, string(die_struct.rolled_value));
			} else if (die_struct.forced_roll != -1) {
				var _bonus = get_dice_output(die_struct, i, -1, true, "player").keepsake_dice_bonus_amount;
					
				draw_outline_text(string(die_struct.forced_roll + _bonus), c_black, c_white, 2, xx_top + off_x, yy_top + off_y, 1, 1, 0);
			}
			
			//if (die_struct.min_roll_bonus > 0) {
			//	draw_outline_text("+" + string(die_struct.min_roll_bonus) + " min", c_black, c_white, 2, xx_top + off_x, yy_top + off_y - 24, 1, 1, 0);
			//}
	    }
	}

	// === Draw colored bars BELOW each slot for possible action types ===
	var pos_type = slot.possible_type;
	var types = (pos_type == "All") ? ["ATK", "BLK", "HEAL"] : string_split(pos_type, " ");
	draw_action_type_bars(draw_x, draw_y + draw_h + 30, draw_w, types, action_queue_type);
}

// --- Discard Button ---
var disc_x = gui_w - global.gui.discard_w - 40;
var disc_y = gui_h - global.gui.discard_h - 40;
var disc_w = global.gui.discard_w;
var disc_h = global.gui.discard_h;

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

// with more than one enemy standing, the target is marked and the others say they can be clicked
var _living_enemies = 0;
for (var e = 0; e < ds_list_size(room_enemies); e++) if (!room_enemies[| e].dead) _living_enemies++;

for (var e = 0; e < ds_list_size(room_enemies); e++) {
	var enemy_data = room_enemies[| e].data;
	var enemy = room_enemies[| e];

	var hover_enemy = mouse_hovering(enemy.pos_x, enemy.pos_y - 40, 230, 320, true);
	enemy.scale = lerp(enemy.scale, hover_enemy ? enemy.start_scale : enemy.start_scale, 0.2);
	enemy.info_alpha = lerp(enemy.info_alpha, hover_enemy ? 1.0 : 0, 0.4);
	
	// you can always pick your target, unless Overwhelm has locked it this turn (and that target is still standing)
	if (hover_enemy && mouse_check_button_pressed(mb_left) && state == CombatState.PLAYER_INPUT && e != enemy_target_index) {
		var _lock_holds = target_locked && enemy_target_index >= 0 && enemy_target_index < ds_list_size(room_enemies) && !room_enemies[| enemy_target_index].dead;
		if (_lock_holds) {
			throw_error("Overwhelmed", "You can't change target this turn.");
		} else {
			enemy_target_index = e;
		}
	}
	
	// a faint focus on an enemy you could click to target
	if (e != enemy_target_index && hover_enemy && _living_enemies > 1 && state == CombatState.PLAYER_INPUT && !enemy.dead) {
		draw_sprite_ext(sEnemyFocus, 0, enemy.pos_x, enemy.pos_y + 60, 1, 1, 0, c_white, enemy.alpha * 0.12);
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
	draw_set_alpha(0.5 * enemy.alpha);
	draw_set_color(c_black);
	draw_ellipse(enemy.pos_x - 100 * enemy.data.shadow_scale, enemy.pos_y + 50, enemy.pos_x + 100 * enemy.data.shadow_scale, enemy.pos_y + 70, false);
	draw_sprite_ext(sEnemies, enemy.data.index, enemy.pos_x, enemy.pos_y + 60, enemy.scale, enemy.scale, 0, c_white, enemy.alpha);
	
	// X and Y coordinates for testing: turned off (flip to true when placing enemies)
	if (false) {
		var pos_data = "x: " + string(enemy.pos_x) + "\ny: " + string(enemy.pos_y);
		
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
		draw_set_font(ftDefault);
		draw_set_color(c_black);
		draw_set_alpha(0.5);
		draw_text(enemy.pos_x + 100, enemy.pos_y, pos_data);
		draw_set_alpha(1.0);
	}

	// Show enemy intent
	if (enemy.intent.alpha > 0.05) {
		// intents are always shown (range when Faded, exact when Legible), unless intel is below 0 (Blotted)
		var reveal_intent_single = !intel_is_blotted();
		var reveal_intent_all = !intel_is_blotted();
	
	    var text = intent_number_text(enemy, intel_level);

	    var xx = enemy.pos_x; // enemy position on screen
	    var yy = enemy.pos_y - 10 - (enemy.scale * 180);  // slightly above their head

		// Quill: an intent you can rewrite this turn pulses and glows, with a quill beside it, so it can't be missed
		var _rewritable = (intel_level >= 2 && !intel_is_blotted() && !intel_rewrite_used && state == CombatState.PLAYER_INPUT && !show_rewards && enemy_can_quill(enemy));
		var _quill_pulse = 0.5 + 0.5 * sin(current_time / 200);
		if (_rewritable) enemy.intent.scale = enemy.intent.start_scale * (1 + 0.12 * _quill_pulse);
		
		// Draw combined intents
		var intent_array = string_split(enemy.intent.move.action_type, "/");
		
		// (the dice behind a move used to show on hover; the hover tooltip says it in words now)

	    draw_set_halign(fa_left);
	    draw_set_valign(fa_middle);

		// Set index and text width
		draw_set_font(ftTopBar);
		var text_w = string_width(text) + 10 + (sprite_get_width(sIntentIcons) * enemy.intent.scale);
		
		var sprite = sIntentIcons;
		var icon_x = xx - text_w/2 + 5 + ((sprite_get_width(sprite) / 2) * enemy.intent.scale);
		var text_x = icon_x + ((sprite_get_width(sprite) / 2) * enemy.intent.scale) + 10;
		var bonus_scale = 1;

		var index = 4;
		var col = c_dkgray;
		
		var enemy_exiting = false;
		
		if (_rewritable) {
			var _glow_w = text_w / 2 + 18;
			draw_set_color(global.color_intel);
			draw_set_alpha(enemy.intent.alpha * (0.15 + 0.25 * _quill_pulse));
			draw_roundrect_ext(xx - _glow_w, yy - 30, xx + _glow_w, yy + 30, 20, 20, false);
			draw_set_alpha(1.0);
			draw_insight_icon("quill", xx - _glow_w - 24, yy - 4 * _quill_pulse, 1.1, enemy.intent.alpha);
		}

		// Draw enemy intent
		for (var i = 0; i < array_length(intent_array); i++) {
			
			if ((reveal_intent_single && e == enemy_target_index) || reveal_intent_all || intent_array[i] == "EXIT") {
				switch (intent_array[i]) {
					case "ATK": col = global.color_attack; index = 0; break;
					case "BLK": col = global.color_block; index = 1; break;
					case "HEAL": col = global.color_heal; index = 2; break;
					case "EXIT": col = c_orange; index = 5; enemy_exiting = true; break;
					case "DEBUFF": case "NONE": case "BUFF": col = c_white; index = 3; break;
					default: 
					col = c_dkgray; 
					index = 0;
				}
			}
		
			// enemy move is a debuff, draw sDebuffIcon, _debuff.template.icon_index instead of the standard icon
			if (intent_array[i] == "DEBUFF" || intent_array[i] == "BUFF") {
				if (reveal_intent_all) || (reveal_intent_single && e == enemy_target_index) {
					sprite = sDebuffIcon;
					index = enemy.intent.move.debuff.icon_index;
					bonus_scale = 1.5;
					icon_x = xx;
					col = enemy.intent.move.debuff.color;
				}
			}
			
			draw_sprite_ext(sprite, index, icon_x, yy, enemy.intent.scale * bonus_scale,  enemy.intent.scale * bonus_scale, 0, col, enemy.intent.alpha);
			
		}
		
		draw_outline_text(text, c_black, c_white, 2, text_x, yy, enemy.intent.scale, enemy.intent.alpha);

		// Quill: click an intent, then choose Reroll (the enemy picks a different move) or Halve (its numbers this turn)
		var _intent_hover = mouse_hovering(xx, yy, text_w + 20, 50, true);
		var _can_rewrite = (intel_level >= 2 && !intel_is_blotted() && !intel_rewrite_used && state == CombatState.PLAYER_INPUT && !show_rewards);
		if (!_can_rewrite && quill_menu_enemy == enemy) quill_menu_enemy = undefined;
		if (_can_rewrite && _intent_hover && quill_menu_enemy != enemy) {
			if (!enemy_can_quill(enemy)) {
				queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Quill: nothing to change", "This move is forced and has no numbers to halve.", undefined, 0, undefined);
			} else {
				queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Quill: rewrite intent", "Click to rewrite this intent, once per turn. Reroll: the enemy picks a different move. Halve: this move's numbers are halved.", undefined, 0, undefined);
				if (mouse_check_button_pressed(mb_left)) {
					quill_menu_enemy = enemy;
					quill_btn_scales = [1, 1];
				}
			}
		}

		// the choice, under the intent
		if (_can_rewrite && quill_menu_enemy == enemy) {
			var _qb_w = 120, _qb_h = 44;
			var _qb_y = yy + 34;
			var _reroll_ok = enemy_can_rewrite_intent(enemy);
			var _halve_ok = enemy_can_halve_intent(enemy);
			var _reroll = draw_gui_button(xx - _qb_w - 6, _qb_y, _qb_w, _qb_h, quill_btn_scales[0], "Reroll", global.color_intel, ftDefault, _reroll_ok, true);
			var _halve = draw_gui_button(xx + 6, _qb_y, _qb_w, _qb_h, quill_btn_scales[1], "Halve", global.color_intel, ftDefault, _halve_ok, true);
			quill_btn_scales[0] = _reroll.scale;
			quill_btn_scales[1] = _halve.scale;
			if (_reroll.hover) queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Reroll", "The enemy picks a different move, rolled fresh.", undefined, 0, undefined);
			if (_halve.hover) queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Halve", "This turn, this move's attack, block or heal is halved (rounded down).", undefined, 0, undefined);
			if (!_reroll_ok && mouse_hovering(xx - _qb_w - 6, _qb_y, _qb_w, _qb_h, false)) queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Can't reroll", "This move is forced, or the enemy has nothing else to choose.", undefined, 0, undefined);
			if (!_halve_ok && mouse_hovering(xx + 6, _qb_y, _qb_w, _qb_h, false)) queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Can't halve", "This move has no attack, block or heal to halve.", undefined, 0, undefined);

			if (_reroll.click && enemy_rewrite_intent(enemy)) {
				intel_rewrite_used = true;
				quill_menu_enemy = undefined;
				enemy.intent.scale = enemy.intent.start_scale * 1.4; // pop, so the change is noticed
				add_feed_entry("You rewrote " + string(enemy.data.name) + "'s intent: " + string(enemy.intent.move.move_name));
			} else if (_halve.click && enemy_halve_intent(enemy)) {
				intel_rewrite_used = true;
				quill_menu_enemy = undefined;
				enemy.intent.scale = enemy.intent.start_scale * 1.4;
				add_feed_entry("You halved " + string(enemy.data.name) + "'s " + string(enemy.intent.move.move_name));
			} else if (mouse_check_button_pressed(mb_left) && !_reroll.hover && !_halve.hover && !_intent_hover) {
				quill_menu_enemy = undefined; // clicked elsewhere: put the quill down
			}
		}
	
	    draw_set_halign(fa_center);
	
		// Draw attack name
		draw_set_font(ftBigger);
		var move_name = ((reveal_intent_single && e == enemy_target_index) || reveal_intent_all) ? string(enemy.intent.move.move_name) : "???";
		if (intent_is_halved(enemy)) {
			draw_set_font(ftDefault);
			draw_outline_text("Halved", c_black, global.color_intel, 2, xx, yy + 26, 1, enemy.intent.alpha, 0);
			draw_set_font(ftBigger);
		}
		// (the move's name used to appear above the intent on hover; it is the tooltip's title now)
	
		if (hover_enemy && !show_rewards) {
			if (enemy.intent.move.action_type == "DEBUFF" || enemy.intent.move.action_type == "BUFF") && (reveal_intent_all || (reveal_intent_single && e == enemy_target_index)) {
				queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), enemy.intent.move.debuff.name, enemy.intent.move.debuff.desc, undefined, 0, undefined);
			} else {
				if (enemy_exiting) {
					queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Exiting", "The enemy intents to escape", undefined, 0, undefined);
				} else if (reveal_intent_all || (reveal_intent_single && e == enemy_target_index)) {
					// plain words: what it will do and how much (the range when Faded, the exact number from Legible)
					queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), move_name, intent_hover_text(enemy, intel_level), undefined, 0, undefined);
				} else {
					queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Blotted", "Your insight is below 0, so the page is blotted and enemy intents are hidden.", undefined, 0, undefined);
				}
			}
		}
	}
	
	// =========================================================
	// ENEMY KILL/SPARE OPTIONS
	// =========================================================
	
	if (enemy.alignment_choices_shown) {
		spare_kill_alpha = lerp(spare_kill_alpha, 1.0, 0.1);
		
		var btn1_x = enemy.pos_x - 50;
		var btn1_y = enemy.pos_y + 50;
		var btn2_x = btn1_x + 100;
		var btn2_y = btn1_y;
		
		// kit buttons, fading in with the choice
		var _kill = ui_button(btn1_x, btn1_y, 96, 46, enemy.alignment_option_btn_1_scale, "Kill", global.ui_danger, true, "", UI_LAYER.BASE, spare_kill_alpha, ftDefault);
		var _spare = ui_button(btn2_x, btn2_y, 96, 46, enemy.alignment_option_btn_2_scale, "Spare", global.ui_primary, true, "", UI_LAYER.BASE, spare_kill_alpha, ftDefault);
		enemy.alignment_option_btn_1_scale = _kill.scale;
		enemy.alignment_option_btn_2_scale = _spare.scale;
		var btn_1_hover = _kill.hover;
		var btn_2_hover = _spare.hover;

		if (btn_1_hover) {
			queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Kill", "Your compass swings 5 toward ruthless. You take its bounty in gold" + ((oWorldManager.current_node_type == NODE_TYPE.ELITE) ? ", and it counts for a bounty contract." : "."));
			if (mouse_check_button_pressed(mb_left)) {
				enemy.killed = true;
				gain_alignment(-5);
				enemy.alignment_choices_shown = false;
			}
			// Proceed with killing the enemy
		}
		
		if (btn_2_hover) {
			queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Spare", "Your compass swings 5 toward merciful. It sails away and pays one and a half times its bounty in gold. Spare every enemy and an item reward is guaranteed.");
			if (mouse_check_button_pressed(mb_left)) {
				enemy.spared = true;
				enemy.alignment_choices_shown = false;
			}
			// Proceed with sparing the enemy
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
	var e_hp_color = merge_color(c_red, c_red, e_hp_ratio);

	// Current HP
	draw_sprite_ext(sHealthBar, 1, e_bar_x, e_bar_y, e_hp_ratio * bar_scale, bar_scale, 0, e_hp_color, enemy.alpha);
	draw_sprite_ext(sHealthBar, 0, e_bar_x, e_bar_y, bar_scale, bar_scale, 0, c_white, enemy.alpha);

	// Text label
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_set_font(ftDefault);
	draw_outline_text(string_format(enemy.hp, 0, 0) + " / " + string(enemy.max_hp), c_black, c_white, 2, e_bar_x + e_bar_w / 2, e_bar_y + e_bar_h / 2, 1, enemy.alpha, 0);

	// targeting: your attacks go to the marked enemy; any other one can be clicked to make it the target
	if (_living_enemies > 1 && !enemy.dead && !show_rewards) {
		var _mark_y = e_bar_y + e_bar_h + 22;
		if (e == enemy_target_index && enemy.info_alpha < 0.3) {
			var _tpulse = 0.5 + 0.5 * sin(current_time / 250);
			draw_set_font(ftDefault);
			draw_outline_text("Target", c_black, c_red, 2, enemy.pos_x, _mark_y, 1, enemy.alpha, 0);
			// arrows either side of the word, nudging in and out
			var _ax = 48 + 6 * _tpulse;
			draw_set_color(c_red);
			draw_set_alpha(enemy.alpha);
			draw_triangle(enemy.pos_x - _ax, _mark_y - 9, enemy.pos_x - _ax, _mark_y + 9, enemy.pos_x - _ax + 12, _mark_y, false);
			draw_triangle(enemy.pos_x + _ax, _mark_y - 9, enemy.pos_x + _ax, _mark_y + 9, enemy.pos_x + _ax - 12, _mark_y, false);
			draw_set_alpha(1);
		} else if (e != enemy_target_index && hover_enemy && state == CombatState.PLAYER_INPUT) {
			// under the name, which shows while hovered
			draw_set_font(ftDefault);
			draw_outline_text(target_locked ? "Target locked" : "Click to target", c_black, c_ltgray, 2, enemy.pos_x, _mark_y + 26, 1, enemy.alpha, 0);
		}
	}
	
	// Draw enemy name
	// Outline
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(ftDefault);
	// the name shows under the health bar while hovered, in the spot the "Target" marker uses (it replaces it)
	draw_outline_text(string(enemy_data.name), c_black, c_white, 2, enemy.pos_x, e_bar_y + e_bar_h + 22, 1, enemy.info_alpha * enemy.alpha);
		
	// Draw enemy block
	if (enemy.block_amount > 0) {
		var block_x = enemy.pos_x + e_bar_w/2;
		var block_y = e_bar_y + e_bar_h/2 + 2;
		var block_radius = 30;
		draw_set_color(c_blue);
		draw_sprite_ext(sIntentIcons, 1, block_x, block_y, bar_scale * 1.25, bar_scale * 1.25, 0, global.color_block, 1.0);
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
		
		var debuff_remaining_text = string(_debuff.remaining);
		
		if (!_debuff.permanent) {
			if (_debuff.remaining > 0) {
				debuff_remaining_text = string(_debuff.remaining);
			} else {
				debuff_remaining_text = "";
			}
		}
		
		draw_outline_text(debuff_remaining_text, c_black, c_white, 2, e_bar_x + d_x + sprite_get_width(sDebuffIcon), d_y + sprite_get_height(sDebuffIcon)/1.2, 1, 1, 0);
		if (_debuff.amount != 0) draw_outline_text(string(_debuff.amount), c_black, c_red, 2, e_bar_x + d_x, d_y + sprite_get_height(sDebuffIcon)/1.2, 1, 1, 0);
	
		if (mouse_hovering(e_bar_x + d_x, d_y, sprite_get_width(sDebuffIcon), sprite_get_height(sDebuffIcon), false)) {
			queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _debuff.template.name, buff_tooltip_text(_debuff), undefined, 0, undefined);
		}
	
		d_x += sprite_get_width(sDebuffIcon) + d_padding;
	}

}

// Draw player sprite
draw_set_alpha(0.5);
draw_set_color(c_black);
draw_ellipse( global.player_x - 100,  global.player_y + 50, global.player_x + 100,  global.player_y + 70, false);
	
draw_sprite_ext(sEnemies, 0, global.player_x, global.player_y + 60, -1, 1, 0, c_white, 1.0);

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
	if (!_debuff.permanent) draw_outline_text(string(_debuff.remaining), c_black, c_white, 2, p_bar_x + d_x + sprite_get_width(sDebuffIcon), d_y + sprite_get_height(sDebuffIcon)/1.2, 1, 1, 0);
	if (_debuff.amount != 0) draw_outline_text(string(_debuff.amount), c_black, c_red, 2, p_bar_x + d_x, d_y + sprite_get_height(sDebuffIcon)/1.2, 1, 1, 0);

	if (mouse_hovering(p_bar_x + d_x, d_y, sprite_get_width(sDebuffIcon), sprite_get_height(sDebuffIcon), false)) {
		queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _debuff.template.name, buff_tooltip_text(_debuff), undefined, 0, undefined);
	}
	
	d_x += sprite_get_width(sDebuffIcon) + d_padding;
}

// Draw player block
if (player_block_amount > 0) {
	var block_x = global.player_x - 155;
	var block_y = p_bar_y + 25;
	var block_radius = 30;
	draw_set_color(c_blue);
	draw_sprite_ext(sIntentIcons, 1, block_x, block_y, 1, 1, 0, global.color_block, 1.0);
	draw_set_color(c_white);
	draw_set_alpha(1.0);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(ftDefault);
	draw_outline_text(string(player_block_amount), c_black, c_white, 2, block_x, block_y - 4, 1, 1.0, 0);
}

insight_panel_open = false;
if (state != CombatState.PLAYER_DEAD) {
	// Draw intel level
	draw_intel = lerp(draw_intel, player_intel, 0.1);

	var arc_start = 180;
	// the ring runs from empty to full: below zero it would wrap round into an almost-full circle, above the max it would overflow
	var _intel_max = intel_max();
	var intel_fill = clamp(draw_intel / _intel_max, 0, 1);
	var arc_end = 181 + (intel_fill * 179);
	var _intel_ratio = clamp(player_intel / _intel_max, 0, 1);
	draw_arc_thick_deg_gradient(global.player_x, global.player_y - 175, 50, 60, arc_start, arc_end, 50, global.color_intel, make_color_rgb(210 - (_intel_ratio * 50), 210 - (_intel_ratio * 100), 0), 0.7);

	// a tick at each state (Faded at the start, Legible, Quill at the end)
	draw_set_alpha(1.0);
	draw_set_color(c_white);
	for (var i = 0; i < ds_list_size(global.player_intel_data); i++) {
		var _tick = 180 + (global.player_intel_data[| i].requirement / _intel_max) * 180;
		draw_arc_thick_deg(global.player_x, global.player_y - 175, 50, 60, (_tick - 2 + 360) mod 360, (_tick + 2) mod 360, 50);
	}

	var _intel_state = intel_state(intel_level);
	draw_insight_icon(_intel_state.icon, global.player_x, global.player_y - 180, intel_scale * 1.6, intel_alpha);
	draw_outline_text(string(_intel_state.name), c_black, intel_is_blotted() ? c_red : global.color_intel, 2, global.player_x, global.player_y - 230, intel_scale, 1.0, 0);
	var intel_hover = mouse_hovering(global.player_x, global.player_y - 190, 120, 120, true);
	insight_panel_open = intel_hover; // the panel itself draws in oRunManager Draw GUI End (insight_panel_draw), over the tutorial notes

	intel_scale = intel_hover ? lerp(intel_scale, 1.2, 0.2) : lerp(intel_scale, 1.0, 0.2);

	// the number shows when it isn't zero, negative intel (from Overwhelm) included
	if (player_intel != 0) {
		draw_outline_text(string(player_intel), c_black, player_intel < 0 ? c_red : c_white, 2, global.player_x + 30, global.player_y - 170, intel_scale, 1.0, 0);
	}

	if (intel_hover) {

		// the tooltip only says what matters now
		var _intel_tip = string(_intel_state.description);
		if (!intel_is_blotted() && intel_level < ds_list_size(global.player_intel_data) - 1) {
			var _next_state = global.player_intel_data[| intel_level + 1];
			_intel_tip += " " + string(_next_state.requirement - player_intel) + " more for " + string(_next_state.name) + ".";
		}
		queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Insight: " + string(_intel_state.name), _intel_tip, undefined, 0, undefined);
	}
}

/// PLAYER DEAD
if (state == CombatState.PLAYER_DEAD) {
	// the end-of-voyage summary (run_summary_draw, oRunManager Draw GUI End) covers the fight
	global.ui_layer = UI_LAYER.POPUP;
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
	draw_rectangle(0, ui_top_bar_h(), gui_w, gui_h, false); // the top bar stays in full colour
	
	var reward_width = 1200;
	var reward_height = 550;
	
	draw_set_alpha(1.0);
	
	draw_set_alpha(1.0);
	draw_set_color(c_white);
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	// a rule under the title (the panel behind the rewards was tried and taken out)
	ui_divider(gui_w/2 - 220, gui_w/2 + 220, gui_h/2 - 268);
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	draw_set_font(ftBigger);
	draw_outline_text("Rewards!", c_black, c_white, 2, gui_w/2, gui_h/2 - 350, 1, 1, 0);
	draw_set_font(ftDefault);
	draw_outline_text(string(rewards_stage) + "/" + string(ds_list_size(reward_list)), c_black, c_white, 2, gui_w/2, gui_h/2 - 300, 1, 1, 0);
	
	switch(reward_list[| rewards_stage - 1 ]) {
		case "keepsakes":
			draw_set_font(ftDefault);
			draw_outline_text("Choose one keepsake", c_black, c_white, 2, gui_w/2, gui_h/2 - 100, 1, 1, 0);
	
			for (var r = 0; r < ds_list_size(reward_keepsake_options); r++) {
			    var keepsake = reward_keepsake_options[| r];

			    // --- Layout ---
			    var reward_w = 120;
			    var reward_h = 70;
			    var reward_padding = 120;
			    var reward_total_w = (ds_list_size(reward_keepsake_options) * reward_w) + ((ds_list_size(reward_keepsake_options) - 1) * reward_padding);
			    var reward_x = gui_w / 2 - (reward_total_w / 2);
			    var base_x = reward_x + (r * (reward_w + reward_padding));
			    var base_y = gui_h/2;
			    var base_w = reward_w;
			    var base_h = reward_h;
				
				// Draw background sprite
				var btn_col = make_colour_rgb(52, 55, 73);
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
			        !rewards_keepsake_taken,         // active
					false,
					UI_LAYER.POPUP
			    );

			    // Update scale for animation
			    reward_scale[| r] = btn.scale;

			    // --- Choose sprite index based on dice value ---
			    var spr_index = keepsake.sub_image;

			    // --- Draw the keepsake sprite ---
			    var alpha = rewards_keepsake_taken ? 0.2 : 1.0;
			    draw_sprite_ext(
			        sKeepsake,
			        spr_index,
			        btn.x + btn.w / 2,
			        btn.y + btn.h / 2,
			        btn.scale,
			        btn.scale,
			        0,
			        c_white,
			        alpha
			    );

			    // --- Draw name ---
			    var label = string(keepsake.name);
			    draw_set_color(c_white);
			    draw_set_alpha(alpha);
			    draw_set_halign(fa_center);
			    draw_set_valign(fa_middle);
			    draw_set_font(ftDefault);
			    draw_text_ext(btn.x + btn.w / 2, btn.y + btn.h + 20 - 12 * (string_height_ext(label, -1, sprite_get_width(sRewardFrame) * 0.85) > string_height("A") * 1.5), label, -1, sprite_get_width(sRewardFrame) * 0.85); // long names wrap inside the frame
		
				if (btn.hover) {
					queue_tooltip( device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), keepsake.name, keepsake.desc, undefined, 0, undefined);
				}

			    // --- Click logic: Take reward ---
			    if (!rewards_keepsake_taken && btn.click) {
			        gain_keepsake(keepsake, global.rollable_keepsake_list);
					rewards_keepsake_taken = true;
			    }
			}
		break;
		
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
					false,
					UI_LAYER.POPUP
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
			        get_dice_color(die.possible_type),
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
			    draw_text_ext(btn.x + btn.w / 2, btn.y + btn.h + 20 - 12 * (string_height_ext(label, -1, sprite_get_width(sRewardFrame) * 0.85) > string_height("A") * 1.5), label, -1, sprite_get_width(sRewardFrame) * 0.85); // long names wrap inside the frame
		
				if (btn.hover) {
					queue_tooltip( device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), die.name, die_description(die), undefined, 0, die);
				}

			    // --- Click logic: Take reward ---
			    if (!rewards_dice_taken && btn.click) {
			        // the flying die is made next Step (combat Step), not here: creating an instance in the middle of drawing
			        // made the web build skip the reward overlay for a frame (the flash, B108)
			        pending_reward_die = { x: btn.x + btn.w / 2, y: btn.y + btn.h / 2, tx: global.gui.play_w, ty: gui_h - global.gui.play_h / 2, die: clone_die(die, "") };

			        rewards_dice_taken = true;
			        global.bag_size++;
			    }
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
				var btn_col = global.color_common;
				switch (consumable.rarity) {
					case "uncommon":
					btn_col = global.color_uncommon;
					break;
					
					case "rare":
					btn_col = global.color_rare;
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
					false,
					UI_LAYER.POPUP
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
			    draw_outline_text(label, c_black, col, 2, btn.x + btn.w / 2, btn.y + btn.h + 20 - 12 * (string_height_ext(label, -1, sprite_get_width(sRewardFrame) * 0.85) > string_height("A") * 1.5), 1, alpha, 0, sprite_get_width(sRewardFrame) * 0.85); // long names wrap inside the frame
				
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
						die = core_preview_die();
						die.distribution = consumable.distribution;
					}
					queue_tooltip( device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), consumable.name, consumable.description, undefined, 0, die);
				}
				
				// check for item free

			    // Take first reward
			    if (rewards_consumables_first_taken == -1 && btn.click) {
					if (consumable.name != "Coins") {
						var first_free_slot = get_first_free_item_slot();
						
						if (first_free_slot != -1) {
							var gained_item = gain_item(consumable);
							if (gained_item) {
								rewards_consumables_first_taken = r;
							}
						} else {
							throw_error("No space", "Right click to delete an existing item");
						}
					} else {
						gain_coins(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), consumable.amount);
						consumable.taken = true;
						rewards_consumables_first_taken = r;
					}
					
			    }

			    // Take second reward
			    if (rewards_consumables_first_taken != -1 && !rewards_consumables_second_taken && btn.click && r != rewards_consumables_locked && !consumable.taken) {
					if (consumable.name != "Coins") {
						var first_free_slot = get_first_free_item_slot();
						
						if (first_free_slot != -1) {
							var gained_item = gain_item(consumable);
							if (gained_item) {
								rewards_consumables_second_taken = true;
							}
						} else {
							throw_error("No space", "Right click to delete an existing item");
						}
					} else {
						gain_coins(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), consumable.amount);
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
					rewards_consumables_locked = available_items[irandom(array_length(available_items) -1 )];
				}
			}
		break;
	}
	
	var next_x = gui_w - 300;
	var next_y = gui_h/2;
	
	var next_hover = mouse_hovering(next_x, next_y, sprite_get_width(sButtonSmall), sprite_get_height(sButtonSmall), true, noone, soClick4, true, UI_LAYER.POPUP);
	
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
	    ui_button_col(next_btn_col), // Next is the go action (green), the last Exit a neutral one
	    1.0
	);
	
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(ftBig);
	draw_outline_text(rewards_stage == ds_list_size(reward_list) ? "Exit" : "Next", c_black, c_white, 2, next_x, next_y, reward_next_hover, 1.0, 0);

	// Update animation
	reward_next_hover = lerp(reward_next_hover, next_hover && !instance_exists(oDiceParticle) ? 1.2 : 1.0, 0.2);
	
	if (next_hover && mouse_check_button_pressed(mb_left) && instance_number(oDiceParticle) == 0) {
		if (rewards_stage < ds_list_size(reward_list)) {
			if (reward_list[| rewards_stage-1 ] == "dice") {
				rewards_dice_taken = true;
			}
			
			if (reward_list[| rewards_stage-1 ] == "keepsakes") {
				rewards_keepsake_taken = true;
			}
			
			rewards_stage++;
			
			for (var s = 0; s < ds_list_size(reward_scale); s++) {
				reward_scale[| s] = 0.1;
			}
		} else {
			rewards_all_taken = true;
		}
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
// the click area is the discard bag sprite as drawn above (bottom right)
var disc_bag_w = sprite_get_width(sDiceBag);
var disc_bag_h = sprite_get_height(sDiceBag);
var disc_bag_x = gui_w - 60 - sprite_get_width(sDiceBag) - sprite_get_xoffset(sDiceBag);
var disc_bag_y = gui_h - 40 - sprite_get_yoffset(sDiceBag);
disc_bag_hover = (mx > disc_bag_x && mx < disc_bag_x + disc_bag_w && my > disc_bag_y && my < disc_bag_y + disc_bag_h);

if (disc_bag_hover) {
    if (mouse_check_button_pressed(mb_left)) {
		oRunManager.show_bag_contents = 1 - oRunManager.show_bag_contents;
		oRunManager.bag_to_show = global.discard_pile;
	}
}

// the guided first fight's margin notes, on top of the combat UI
tutorial_draw();
