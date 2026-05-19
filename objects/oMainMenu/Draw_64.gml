if (room == rmMainMenu && !global.all_input_disabled) {
	var menu_x = 100;
	var menu_y = display_get_gui_height()/3;
	var vertical_spacer = 100;

	for (var i = 0; i < array_length(menu_scale); i++) {
		var menu_item = draw_gui_button(menu_x, menu_y + (vertical_spacer * i), 160, 50, menu_scale[i], menu_titles[i], c_dkgray, ftBig, menu_active[i], true, noone, soClick4);
		menu_scale[i] = menu_item.scale;
		
		if (menu_item.click) {
			menu_actions[i]();
		}
	}
}