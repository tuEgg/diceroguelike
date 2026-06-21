global.setting_width = display_get_gui_width() / 7; // used for determining how wide to draw the setting sliders and dropdowns

if (global.show_settings) {

	var gui_w = display_get_gui_width();
	var gui_h = display_get_gui_height();

	// cover background
	draw_set_color(global.color_bg);
	draw_set_alpha(1.0);
	draw_rectangle(0, 0, gui_w, gui_h, false);
	
	var total_settings_w = display_get_gui_width() * 0.7;
	var total_settings_h = display_get_gui_height() * 0.5;
	var settings_x = gui_w / 2 - total_settings_w / 2;
	var settings_y = gui_h / 2 - total_settings_h / 2;
	var cat_w = 170;
	var cat_h = 70;
	var inner_settings_padding = display_get_gui_width() / 40; // 30 pixels on 1920px width screen
	var setting_h = 60;
	
	// settings background
	draw_set_color(c_black);
	draw_set_alpha(1.0);
	draw_rectangle(settings_x, settings_y, settings_x  + total_settings_w, settings_y  + total_settings_h, true);
	draw_rectangle(settings_x + 1, settings_y + 1, settings_x  + total_settings_w - 1, settings_y  + total_settings_h - 1, true);
	draw_set_alpha(0.5);
	draw_rectangle(settings_x, settings_y, settings_x  + total_settings_w, settings_y  + total_settings_h, false);
	
	// draw categories
	for (var i = 0; i < array_length(categories); i++) {
		var category = categories[i];
		var cat_x = settings_x - cat_w/2;
		var cat_y = settings_y + (cat_h*i) + cat_h/2;
		
		var col = c_dkgray;
		if (i == category_index) col = c_aqua;
		
		var category_btn = draw_gui_button(cat_x, cat_y, cat_w, cat_h, category.scale, category.name, col, ftBig, true, true, UI_LAYER.SETTINGS);
		
		category.scale = category_btn.scale;
		
		if (category_btn.click) {
			category_index = i;
		}
		
		if (category_index == i) {
			// draw category settings
			for (var s = 0; s < array_length(category.settings); s++) {
				var setting = category.settings[s];
				var set_x = cat_x + cat_w + (inner_settings_padding*1.5);
				var set_y = settings_y + (setting_h * s) + inner_settings_padding;
			
				draw_setting_title(setting.name, set_x, set_y);
			
				switch (setting.type) {
					case "slider":
						draw_setting_slider(setting, set_x + (display_get_gui_width() / 8), set_y);
					break;
					
					case "toggle":
						draw_setting_toggle(setting, set_x + (display_get_gui_width() / 8), set_y);
					break;
					
					case "dropdown":
						draw_setting_dropdown(setting, set_x + (display_get_gui_width() / 8), set_y);
					break;
				}
			}
		}
	}
	
	// draw save/cancel settings button
	var cancel_txt = "Exit";
	
	check_settings(); // check every frame if settings have changed
	
	if (settings_changed) {
		cancel_txt = "Cancel";
		
		var save_btn = draw_gui_button(settings_x - cat_w/2, gui_h / 2 + total_settings_h / 2 - cat_h*1.5, cat_w, cat_h, save_scale, "Save", c_lime, ftBig, true, true, UI_LAYER.SETTINGS);
		save_scale = save_btn.scale;
	
		if (save_btn.click) {
			// save settings		
			save_settings();
		
			exit_settings();
		}
	}
	
	var cancel_btn = draw_gui_button(settings_x - cat_w/2, gui_h / 2 + total_settings_h / 2 - cat_h/2, cat_w, cat_h, cancel_scale, cancel_txt, c_red, ftBig, true, true, UI_LAYER.SETTINGS);
	cancel_scale = cancel_btn.scale;
	
	if (cancel_btn.click) {
		// load settings to override changes		
		load_settings();
		
		exit_settings();
		
	}
	
	// draw quit game button
	var quit_btn = draw_gui_button(settings_x + total_settings_w - cat_w/2, gui_h / 2 + total_settings_h / 2 - cat_h/2, cat_w, cat_h, quit_scale, "Main Menu", c_dkgray, ftBig, true, true, UI_LAYER.SETTINGS);
	quit_scale = quit_btn.scale;
	
	if (quit_btn.click) {
		room = rmMainMenu;
		exit_settings();
	}
}