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

if (double_tap(key_exit)) game_end();

global.ui_scale = display_get_gui_width() / 1920;