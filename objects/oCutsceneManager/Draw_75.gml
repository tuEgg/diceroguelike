if (cutscene_state == CUTSCENE_STATE.PLAYING) {
	var cutscene = cutscenes[cutscene_index];
	
	var gui_w = display_get_gui_width();
	var gui_h = display_get_gui_height();
	
	// Draw black background
	draw_set_alpha(1.0);
	draw_set_color(c_black);
	draw_rectangle(0, 0, gui_w, gui_h, false);
			
	// Pass through cutscene images
	// Check total seconds passed this cutscene
	var seconds_passed = cutscene_timer / game_get_speed(gamespeed_fps);

	var _elapsed = 0;
	scene_index = 0;
	for (var i = 0; i < array_length(cutscene.scenes); i++) {
	    _elapsed += cutscene.scenes[i].duration;
	    if (seconds_passed < _elapsed) {
	        scene_index = i;
	        break;
	    }
	}

	var active_scene = cutscene.scenes[scene_index];
	draw_sprite_ext(active_scene.image, 0, 0, 0, 1, 1, 0, c_white, 1.0);
	
	// Draw skip option after 3 seconds
	if (cutscene_timer > game_get_speed(gamespeed_fps) * 3) {
		if (skip_alpha < 1) skip_alpha += 0.01;
	
		draw_set_color(c_white);
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
		draw_set_font(ftBig);
		draw_set_alpha(skip_alpha);
		draw_text(50, 50, "Hold Escape to skip");
		draw_set_alpha(1.0);
	}
}