if (room == rmMainMenu && !global.all_input_disabled) {
	var gui_w = display_get_gui_width();
	var gui_h = display_get_gui_height();
	var menu_x = gui_w/2;
	var menu_y = gui_h/2;
	var vertical_spacer = 100;
	var button_w = 170;
	var button_h = 70;
	
	// draw logo
	draw_sprite(sLogo, 0, gui_w/2, gui_h/3);
	
	if (show_run_warning == true) {
		// give a warning if we try to start a new run with one existing
		var warning_txt = "Are you sure you want to abandon your current run?";
		
		// Draw background
		var btn_w = gui_w / 9;
		var btn_h = gui_h / 14;
		var bg_x = gui_w / 2;
		var bg_y = gui_h * 0.66;
		var bg_w = btn_w * 2.5;
		var bg_h = gui_h / 5;
		//draw_set_color(global.color_bg);
		//draw_set_alpha(0.8);
		//draw_rectangle(bg_x - bg_w / 2, bg_y - bg_h / 2, bg_x + bg_w / 2, bg_y + bg_h / 2, false);
		
		// Draw warning text
		draw_set_halign(fa_center);
		draw_set_valign(fa_top);
		draw_outline_text(warning_txt, c_black, c_white, 2, bg_x, bg_y - gui_h / 14, 1, 1.0, 0, bg_w * 0.75);
		
		// Draw buttons
		var new_run_btn = draw_gui_button(bg_x - btn_w * 1.125, bg_y, btn_w, btn_h, proceed_new_scale, "Start new run", c_lime, ftBig, true, true);
		var cancel_btn = draw_gui_button(bg_x + btn_w * 0.125, bg_y, btn_w, btn_h, cancel_new_scale, "Cancel", c_red, ftBig, true, true);
		proceed_new_scale = new_run_btn.scale;
		cancel_new_scale = cancel_btn.scale;
		
		if (new_run_btn.click) {
			room_goto(rmMap);
			show_run_warning = false;
		}
		
		if (cancel_btn.click) {
			show_run_warning = false;
		}
	} else {
		for (var i = 0; i < array_length(menu); i++) {
		var menu_item = draw_gui_button(menu_x - button_w/2, menu_y + (vertical_spacer * i) - button_h/2, button_w, button_h, menu[i].scale, menu[i].title, make_color_rgb(60, 78, 181), ftBig, menu[i].flag, "hover", UI_LAYER.BASE, soClick1, soClick4);
		draw_set_color(c_white);
		draw_set_font(ftDefault);
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_outline_text(menu[i].title, c_black, c_white, 2, menu_x, menu_y + (vertical_spacer * i), menu[i].scale, menu[i].flag ? 1.0 : 0.25, 0);
		
		menu[i].scale = menu_item.scale;
		
		if (menu_item.click) {
			menu[i].action();
		}
	}
	}
}