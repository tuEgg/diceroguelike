if (room == rmMainMenu && !global.all_input_disabled) {
	var gui_w = display_get_gui_width();
	var gui_h = display_get_gui_height();
	var menu_x = gui_w/2;
	var menu_y = gui_h/2;
	var vertical_spacer = 100;
	var button_w = 170;
	var button_h = 70;
	
	// draw background gradient
	draw_sprite_ext(sMainMenuBG, 0, gui_w/2, gui_h/2, 1, 1, 0, c_white, 1.0);
	
	// draw logo
	draw_sprite(sLogo, 0, gui_w/2, gui_h/3);

	for (var i = 0; i < array_length(menu); i++) {
		var menu_item = draw_gui_button(menu_x - button_w/2, menu_y + (vertical_spacer * i) - button_h/2, button_w, button_h, menu[i].scale, menu[i].title, make_color_rgb(60, 78, 181), ftBig, menu[i].flag, "hover", noone, soClick4);
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