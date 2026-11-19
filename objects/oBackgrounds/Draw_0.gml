for (var i = 0; i < array_length(backgrounds); i++) {
	if (room == backgrounds[i].room_name) {
		
		var _cw = camera_get_view_width(view_camera[0]);
		var _ch = camera_get_view_height(view_camera[0]);
		var bg_list = backgrounds[i].background_list;
		
		for (var b = 0; b < array_length(bg_list); b++) {
			var bg = bg_list[b];
			var animated = bg.animated;
			
			var scale_x = _cw / 1920;
			var scale_y = _ch / 1080;
			
			if (animated) {
				bg.xx += 0.75;
				
				if (bg.xx > 1920) {
					bg.xx = bg.xx_start;
				}
				
				// draw a second copy to the left
				draw_sprite_ext(bg.sprite, 0, bg.xx - sprite_get_width(bg.sprite), bg.yy, scale_x, scale_y, 0, c_white, 1.0);
			}
			
			draw_sprite_ext(bg.sprite, 0, bg.xx, bg.yy, scale_x, scale_y, 0, c_white, 1.0);
		}
	}

}

// the UI rework (docs/design-ui-rework.md): in a fight only the backdrop recedes, toward dusk, so the actors, dice and
// paper on top (all drawn in Draw GUI) keep their full colour; and your hand gets a felt tray along the bottom
if (room == rmCombat && variable_global_exists("ui_col")) {
	var _vw = camera_get_view_width(view_camera[0]), _vh = camera_get_view_height(view_camera[0]);
	draw_set_color(global.ui_col.table_dim);
	draw_set_alpha(0.42);
	draw_rectangle(0, 0, _vw, _vh, false);
	// the tray: from just above where dealt dice land, to the bottom
	var _ty = (global.dice_safe_area_y1 - 40) * _vh / display_get_gui_height();
	draw_set_color(global.ui_col.felt);
	draw_set_alpha(0.72);
	draw_rectangle(0, _ty, _vw, _vh, false);
	draw_set_alpha(0.22);
	draw_set_color(global.ui_col.rule);
	draw_line_width(0, _ty, _vw, _ty, 3);
	draw_set_alpha(1);
	draw_set_color(c_white);
}
