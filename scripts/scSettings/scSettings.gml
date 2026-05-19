function draw_setting_title(_name, _x, _y) {
	draw_set_font(ftBig);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_outline_text(_name, c_black, c_white, 2, _x, _y, 1, 1.0, 0, -1);
}

function draw_setting_slider(_setting, _x, _y) {
	
	var slider_length = global.setting_width;
	var slider_w = 4;
	
	// draw line
	var _line_vertical_offset = 20;
	draw_set_color(c_white);
	draw_set_alpha(0.7);
	draw_line_width(_x, _y + _line_vertical_offset, _x + slider_length, _y + _line_vertical_offset, 4);
	
	// draw current value at the end of that line
	draw_set_font(ftBig);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_text(_x + slider_length + 30, _y + 5, string(_setting.get_value()));
	
	// draw the draggable dial that represents the value
	var _relative_value = _setting.get_value() / _setting.max_val ; // 0 to 1 value as a ratio of max
	var _relative_x_pos = _relative_value * slider_length;
	var dial_x = _x + _relative_x_pos;
	var dial_y = _y + _line_vertical_offset;
	
	draw_sprite_ext(sFrameSmall, 0, dial_x, dial_y, 0.35, 0.35, 0, c_white, 1.0);
	
	// allow player to drag the dial
	var _tolerance = 20;
	if (mouse_hovering(_x - _tolerance/2, _y + _line_vertical_offset - _tolerance/2, slider_length + _tolerance/2, slider_w + _tolerance/2, false, noone, soClick3)) {
		if (mouse_check_button_pressed(mb_left)) {
			starting_mouse_x = device_mouse_x_to_gui(0);
			
			var relative_mouse_x = device_mouse_x_to_gui(0) - _x;
			
			_setting.set_value(clamp(relative_mouse_x / slider_length, _setting.min_val, _setting.max_val));
		}
		
		if (mouse_check_button(mb_left)) {
			_setting.dragging = true;
		}
	}
	
	if (_setting.dragging) {
		
		var relative_mouse_x = device_mouse_x_to_gui(0) - _x;
			
		_setting.set_value(clamp(relative_mouse_x / slider_length, _setting.min_val, _setting.max_val));
		
		if (mouse_check_button_released(mb_left)) {
			_setting.dragging = false;
			starting_mouse_x = undefined;
		}
	}
}

function draw_setting_toggle(_setting, _x, _y) {
	var _size = 40;
	
	// draw outer rectangle
	draw_set_color(c_white);
	draw_set_alpha(1.0);
	draw_rectangle(_x + 1, _y + 1, _x + _size - 1, _y + _size -1, true);
	draw_rectangle(_x, _y, _x + _size, _y + _size, true);
	
	// draw toggled state
	if (_setting.get_value()) {
		draw_set_color(c_white);
		draw_set_alpha(0.8);
		draw_rectangle(_x + 5, _y + 5, _x + _size - 6, _y + _size - 6, false);
	}
	
	// changed toggle state
	if (mouse_hovering(_x, _y, _size, _size, false, noone, soClick3)) {
		if (mouse_check_button_pressed(mb_left)) {
			var new_value = 1 - _setting.get_value();
			_setting.set_value(new_value);
		}
	}
}

function draw_setting_dropdown(_setting, _x, _y) {
	var box_length = global.setting_width;
	var box_height = 40;
	
	// draw background box
	draw_set_color(c_white);
	draw_set_alpha(1.0);
	draw_rectangle(_x + 1, _y + 1, _x + box_length - 1, _y + box_height - 1, true);
	draw_rectangle(_x, _y, _x + box_length, _y + box_height, true);
	
	// draw dropdown arrow
	var tri_inset = 5;
	var tri_size = 30;
	draw_triangle(
		_x + box_length - tri_inset,
		_y + tri_inset,
		_x + box_length - tri_inset - tri_size,
		_y + tri_inset,
		_x + box_length - tri_inset - tri_size/2,
		_y + tri_inset + tri_size,
		false
	);
	
	// draw current setting title
	draw_set_font(ftBig);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_text(_x + 5, _y + 5, string(_setting.options[_setting.get_value()]));
	
	// activate dropdown
	if (mouse_hovering(_x, _y, box_length, box_height, false, noone, soClick3)) {
		if (mouse_check_button_pressed(mb_left)) {
			_setting.show_options = 1 - _setting.show_options;
		}
	}
	
	// draw other options
	if (_setting.show_options) {
		var choice_height = 40;
		var total_height = choice_height * array_length(_setting.options);
		draw_rectangle(_x + 1, _y + box_height + 1, _x + box_length - 1, _y + box_height + total_height - 1, true);
		draw_rectangle(_x, _y + box_height, _x + box_length, _y + box_height + total_height, true);
		
		for (var i = 0; i < array_length(_setting.options); i++) {
			var choice_x = _x + 5;
			var choice_y = _y + 5 + (choice_height * (i+1));
			
			// draw background on selected one
			if (i == _setting.get_value()) {
				draw_rectangle(_x + 5, choice_y + 5, _x + box_length - 6, choice_y + box_height - 6, false);
				draw_set_color(c_black);
			} else {
				draw_set_color(c_white);
			}
			
			draw_text(choice_x, choice_y, string(_setting.options[i]));
		
			if (mouse_hovering(choice_x, choice_y, box_length, box_height, false, noone, soClick3)) {
				if (mouse_check_button_pressed(mb_left)) {
					_setting.set_value(i);
				}
			}
		}
	}
}