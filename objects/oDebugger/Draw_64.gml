if (draw_debug) {
	var debug_x = 30;
	var debug_y = 130;
	var debug_w = 300;
	var debug_entry_h = 40;
	var debug_h = array_length(global.debug) * debug_entry_h;
	var padding = 10;
	
	draw_set_font(ftBig);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	
	draw_set_color(c_black);
	draw_set_alpha(0.7);
	draw_rectangle(debug_x - padding, debug_y - padding, debug_x + debug_w + padding, debug_y + debug_h + padding, false);
	
	draw_set_color(c_white);
	draw_set_alpha(1.0);
	for (var i = 0; i < array_length(global.debug); i++) {
		draw_text(debug_x, debug_y + (i*debug_entry_h), string(global.debug[i].name) + ", " + string(global.debug[i].value));
	}
}