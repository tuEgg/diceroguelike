//if (keyboard_check_pressed(vk_space)) room_goto(rmMap);

if (keyboard_check_pressed(vk_alt)) {
	draw_debug = 1 - draw_debug;
	show_debug_message("UI Layer: " + string(global.ui_layer));
}