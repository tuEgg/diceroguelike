if (global.show_settings) {
	global.ui_layer = UI_LAYER.SETTINGS;
}

if (global.double_tap_timer > 0) {
	global.double_tap_timer--;
	
	if (global.double_tap_timer <= 0) {
		global.double_tap_last_key = undefined;
	}
}

var key_exit = vk_escape;

// a web build can't quit (and Escape leaves fullscreen there), so only the desktop build quits on double Escape
if (!IS_BROWSER && double_tap(key_exit)) game_end();

// web builds refit the canvas when the page changes size
browser_check_resize();

global.ui_scale = display_get_gui_width() / 1920;