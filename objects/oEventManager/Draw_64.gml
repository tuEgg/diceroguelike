if (options_scale == undefined || options_hover == undefined) {
    show_debug_message("ERROR: options lists are not initialised yet!");
}

var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

if (event_complete != -1) {
	chosen_option = chosen_event.options[| event_complete];
}

if (chosen_event != undefined) {

	var container_height = 650;
	var container_width = 800;
	var container_x = gui_w/2 - container_width/2;
	var container_y = gui_h/2 - container_height*(3/5);
	var padding = 40;
	var row_h = 50;
	
	// a logbook entry (UI rework): a page of paper, the event's name as its heading in ink, what happens in ink
	// under a ruled line, and the choices inked below as lines you can pick
	ui_paper(container_x, container_y, container_x + container_width, container_y + container_height, 23, global.ui_col.paper, 1);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_font(ftBigger);
	draw_set_color(global.ui_col.ink);
	draw_text(container_x + padding, container_y + padding, string(chosen_event.name));
	draw_set_color(global.ui_col.paper_shade);
	draw_line_width(container_x + padding, container_y + padding + 40, container_x + container_width - padding, container_y + padding + 40, 2);
	draw_set_color(c_white);

	// what happens (and, once chosen, how it turned out)
	draw_set_font(ftBig);
	var text = event_complete >= 0 ? string(chosen_option.result) : string(chosen_event.description);
	ui_paper_text(colorcode_text(text), container_x + padding, container_y + padding + row_h * 1 + 6, container_width - padding * 2);
	
	var xx = container_x + padding;
	var yy = container_y + container_height - padding;
		
	// Draw options
	for (var i = ds_list_size(chosen_event.options) - 1; i >= 0; i--) {
		draw_set_valign(fa_top);	
		
		var option = chosen_event.options[| i];
		// a description can be a function, worked out as it's shown (The Siren's Call says what your alignment gives)
		var _option_desc = is_callable(option.description) ? option.description() : option.description;
		
		var _w = container_width - padding * 4;
		
		draw_set_font(ftDefault);
		var _title_h = string_height_ext(option.title, font_get_size(draw_get_font()) * 1.2, _w);
		
		draw_set_font(ftDescriptions);
		var _desc_h = string_height_ext(_option_desc, font_get_size(draw_get_font()) * 1.2, _w);
		var _h = _title_h + _desc_h + padding;
		
		options_hover[| i] = mouse_hovering(xx, yy - _h, _w, _h, false);
		options_scale[| i] = lerp(options_scale[| i], !event_selected * options_hover[| i] ? 1.1 : 1.0, 0.2);
		
		var _picked_hover = !event_selected && options_hover[| i];
		var option_alpha = event_selected ? 0.35 : 1.0;

		// a choice: a slip of shaded paper with an ink rule down its left; hovered, it brightens with a brass rule
		var _ox1 = xx, _oy1 = yy - _h, _ox2 = xx + _w + padding, _oy2 = yy - padding / 4;
		draw_set_alpha(option_alpha);
		draw_set_color(_picked_hover ? global.ui_col.paper_hi : merge_colour(global.ui_col.paper, global.ui_col.paper_shade, 0.45));
		draw_roundrect_ext(_ox1, _oy1, _ox2, _oy2, 8, 8, false);
		draw_set_color(_picked_hover ? global.ui_col.brass : global.ui_col.ink);
		draw_rectangle(_ox1, _oy1 + 4, _ox1 + (_picked_hover ? 7 : 4), _oy2 - 4, false);
		draw_set_alpha(1);
		draw_set_color(c_white);

		draw_set_font(ftDefault);
		draw_outline_text(option.title, global.ui_col.paper_hi, global.ui_col.ink, 1, xx + padding/2, yy - _h + padding/2 - 1, 1, option_alpha, 0, _w);

		draw_set_font(ftDescriptions);
		var colored_desc = colorcode_text(_option_desc);
		global.ui_on_paper = true; // coloured words in their dark inks
		draw_outline_text(colored_desc, global.ui_col.paper_hi, global.ui_col.ink_soft, 1, xx + padding/2, yy - _h + padding/2 - 1 + _title_h, 1, option_alpha, 0, _w);
		global.ui_on_paper = false;
		
		if (options_hover[| i]) {
			if (mouse_check_button_pressed(mb_left) && !event_selected) {
				option.effect();
			}
			
			if (variable_struct_exists(option, "hover")) {
				option.hover();
			}
		}
		
		yy -= _h + padding/4;
	}
}


if (deleting_die > 0) {
	var xx = gui_w/2;
	var yy = gui_h/2 - 100;
	var size = sprite_get_width(sActionSlotCentered);
	
	var nearest_grabbed = 0;
	if (instance_exists(oDice)) {
		var nearest = instance_nearest(xx, yy, oDice);
		if nearest.is_dragging nearest_grabbed = 1;
	}
	
	delete_hover = mouse_hovering(xx, yy, size, size, true);
	delete_scale = lerp(delete_scale, delete_hover ? 1.2 : 1.0, 0.2);
	delete_alpha = deleting_die == 2 ? 0.2 : 1.0;
	
	draw_sprite_ext(sActionSlotCentered, 0, xx, yy, delete_scale, delete_scale, 0, c_dkgrey, delete_alpha);

	draw_set_font(ftDefault);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_outline_text("Make him walk", c_black, c_white, 2, xx , yy, 1, 1, 0, 100);

	if (delete_hover) {
		queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Walk the plank", "Drag a die here to make the pirate walk the plank", undefined, 0, undefined);
		if (mouse_check_button_released(mb_left)) {
			var dice_dragged = false;
			var die = instance_nearest(xx, yy, oDice);
			with (die) {
				if (distance_to_point(xx, yy) < 20) {
					dice_dragged = true;
					particle_emit(xx, yy, "burst", get_dice_color(die.possible_type));
					instance_destroy();
				}
			}
			if (dice_dragged) {
				deleting_die = 2; // set it to stage 2 = done
				discard_dice_in_play();
				event_complete = 1;
			}
		}
	}
}

// Draw exit button
var exit_col = c_dkgray;
if (event_complete >= 0) exit_col = c_red;

// the room's commit action, bottom right like End Turn and Embark (ui_primary, UI rework)
var exit_btn = ui_primary(gui_w - 44 - 140, gui_h - 40 - 48, 280, 96, "Continue", exit_col == c_red, "Choose an option first.");
if (exit_btn.click) exiting = true;