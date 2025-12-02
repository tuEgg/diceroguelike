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
	
	draw_set_alpha(0.8);
	draw_set_color(c_black);
	draw_rectangle(container_x, container_y, container_x + container_width, container_y + container_height, false);

	// Draw title
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);	
	draw_set_font(ftBigger);
	draw_outline_text(string(chosen_event.name), c_black, c_white, 2, container_x + padding, container_y + padding, 1, 1, 0);
	
	// Draw description
	draw_set_font(ftBig);
	var text = event_complete >= 0 ? string(chosen_option.result) : string(chosen_event.description);
	draw_outline_text(text, c_black, c_white, 2, container_x + padding, container_y + padding + row_h * 1, 1, 1, 0, container_width - padding * 2);
	
	var xx = container_x + padding;
	var yy = container_y + container_height - padding;
		
	// Draw options
	for (var i = ds_list_size(chosen_event.options) - 1; i >= 0; i--) {
		var _w = container_width - padding * 2;
		var _h = row_h;
		
		var option = chosen_event.options[| i];
		
		options_hover[| i] = mouse_hovering(xx, yy - _h, _w, _h, false);
		
		options_scale[| i] = lerp(options_scale[| i], !event_selected * options_hover[| i] ? 1.1 : 1.0, 0.2);
		
		var hover_col = !event_selected * options_hover[| i] ? make_color_rgb(155, 255, 155) : c_white;
		
		var option_alpha = event_selected ? 0.2 : 1.0;
		
		draw_sprite_ext(sButtonWide, 0, xx, yy - _h, options_scale[| i] * 1.15, options_scale[| i] * 1.15, 0, c_dkgray, option_alpha);
		
		draw_set_font(ftDefault);
		draw_set_valign(fa_top);	
	 
		
		draw_outline_text(string(option.description), c_black, hover_col, 2, xx + padding/2, yy - _h/2 - 10, options_scale[| i], option_alpha, 0, _w);
		
		if (options_hover[| i]) {
			if (mouse_check_button_pressed(mb_left) && !event_selected) {
				option.effect();
				event_selected = true;
			}
		}
		
		yy -= row_h + padding/2;
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
		queue_tooltip(mouse_x, mouse_y, "Walk the plank", "Drag a die here to make the pirate walk the plank", undefined, 0, undefined);
		if (mouse_check_button_released(mb_left)) {
			var dice_dragged = false;
			with (instance_nearest(xx, yy, oDice)) {
				if (distance_to_point(xx, yy) < 20) {
					dice_dragged = true;
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

var hover_exit = (event_complete >= 0) * mouse_hovering(gui_w - 150, gui_h - 200, exit_scale * sprite_get_width(sButtonSmall) * 0.75, exit_scale * sprite_get_height(sButtonSmall) * 0.75, true);

if (hover_exit && exit_col == c_red) {
	if (mouse_check_button_pressed(mb_left)) {
		exiting = true;
	}
	exit_scale = lerp(exit_scale, 1.2, 0.2);
} else {
	exit_scale = lerp(exit_scale, 1.0, 0.2);
}

draw_set_font(ftBigger);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_sprite_ext(sButtonSmall, 0, gui_w - 150, gui_h - 200, exit_scale*0.75, exit_scale*0.75, 0, exit_col, 1.0);
draw_outline_text("Exit", c_black, c_white, 2, gui_w - 150, gui_h - 200, 1, 1, 0);