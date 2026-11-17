// true in a web build (HTML5 / GX.games): no window to resize or quit, and the page decides the size
#macro IS_BROWSER (os_browser != browser_not_a_browser)

function apply_resolution() {
	// in a browser the game always draws at 1920x1080 and the canvas is fitted, 16:9, into the page
	if (IS_BROWSER) {
		apply_browser_resolution();
		return;
	}

	// B83: everything is laid out for 1920x1080 (GUI and camera stay that size at every resolution), and only the
	// window and the render surface take the chosen size; GameMaker scales the picture up. So fixed 1080p positions
	// (shop, bounty board, tools, cutscene, backgrounds, particles...) land in the same place at 1440p.
    var _res = global.resolution_options[global.resolution_index];
	var _w = 1920, _h = 1080;
    window_set_size(_res.w, _res.h);
    surface_resize(application_surface, _res.w, _res.h);
    display_set_gui_size(_w, _h);
    camera_set_view_size(view_camera[0], _w, _h);
    view_set_wport(0, _res.w);
    view_set_hport(0, _res.h);
    view_visible[0] = true;
	global.ui_scale = 1;
    update_gui_layout();
	if (instance_exists(oCombat)) {
		with (oCombat) define_combat_ui_sizes();
	}
	
	//show_debug_message("Apply res: " + string(_res.w) + "x" + string(_res.h) + " | View: " + string(camera_get_view_width(view_camera[0])) + "x" + string(camera_get_view_height(view_camera[0])));
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
/// @func apply_browser_resolution()
/// @desc Web builds: the GUI, view and application surface stay 1920x1080 (the layout is built for it), and the canvas
///       is the biggest 16:9 box that fits the browser page. Called again by browser_check_resize when the page changes.
function apply_browser_resolution() {
	var _w = 1920, _h = 1080;
	var _bw = max(1, browser_width), _bh = max(1, browser_height);
	var _fit = min(_bw / _w, _bh / _h);
	window_set_size(max(1, floor(_w * _fit)), max(1, floor(_h * _fit)));
	surface_resize(application_surface, _w, _h);
	display_set_gui_size(_w, _h);
	camera_set_view_size(view_camera[0], _w, _h);
	view_set_wport(0, _w);
	view_set_hport(0, _h);
	view_visible[0] = true;
	update_gui_layout();
	if (instance_exists(oCombat)) {
		with (oCombat) define_combat_ui_sizes();
	}
	global.browser_fit_w = _bw;
	global.browser_fit_h = _bh;
}

/// @func browser_check_resize()
/// @desc Web builds: refit the canvas when the page (or itch.io's frame, or fullscreen) changes size. Call every step.
function browser_check_resize() {
	if (!IS_BROWSER) return;
	if (!variable_global_exists("browser_fit_w") || global.browser_fit_w != browser_width || global.browser_fit_h != browser_height) {
		apply_browser_resolution();
	}
}
