for (var i = 0; i < array_length(backgrounds); i++) {
	if (room == backgrounds[i].room_name) {
		
		var _cw = camera_get_view_width(view_camera[0]);
		var _ch = camera_get_view_height(view_camera[0]);
		var bg_list = backgrounds[i].background_list;
		
		for (var b = 0; b < array_length(bg_list); b++) {
			var bg = bg_list[b];
			var animated = bg.animated;
			
			if (animated) {
				bg.xx++;
			}
			
			var scale_x = _cw / sprite_get_width(bg.sprite);
			var scale_y = _ch / sprite_get_height(bg.sprite);
			draw_sprite_ext(bg.sprite, 0, bg.xx, bg.yy, scale_x, scale_y, 0, c_white, 1.0);
		}
	}

}