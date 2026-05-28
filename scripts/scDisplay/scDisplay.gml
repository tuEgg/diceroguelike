function apply_resolution() {
    var _res = global.resolution_options[global.resolution_index];
    window_set_size(_res.w, _res.h);
    surface_resize(application_surface, _res.w, _res.h);
    display_set_gui_size(_res.w, _res.h);
    camera_set_view_size(view_camera[0], _res.w, _res.h);
    view_set_wport(0, _res.w);
    view_set_hport(0, _res.h);
    view_visible[0] = true;
    update_gui_layout();
	if (object_exists(oCombat)) {
		with (oCombat) define_combat_ui_sizes();
	}
	
	show_debug_message("Apply res: " + string(_res.w) + "x" + string(_res.h) + " | View: " + string(camera_get_view_width(view_camera[0])) + "x" + string(camera_get_view_height(view_camera[0])));
}

function update_gui_layout() {
    var _w = display_get_gui_width();
    var _h = display_get_gui_height();
    
    global.gui = {
        action_tile_w: _w / 16,
        action_tile_padding: _w / 96,
        play_w: _w / 9.6,
        play_h: _h / 10.8,
        discard_w: _w / 9.6,
        discard_h: _h / 4.9,
        bag_w: _w / 16,
        bag_h: _h / 8.3,
        bag_x: _w / 32,
        bag_x_deal: _w / 16,
        bag_y: _h - _h / 27 - _h / 8.3,
		bag_y_deal: _h - _h / 27 - _h / 16,
    };
}