save_settings();

// each room begins under an ink wash that sweeps away (room_wipe_draw, F65)
global.room_wipe_start = current_time;

apply_resolution();

//show_debug_message("Surface width: " + string(surface_get_width(application_surface)));
//show_debug_message("Window width: " + string(window_get_width()));