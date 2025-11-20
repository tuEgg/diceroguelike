key_escape = keyboard_check(vk_escape);
if key_escape game_end();

key_restart = keyboard_check(ord("R"));
if key_restart game_restart();

if (debug_mode) {
	key_workbench = keyboard_check(ord("W"));
	if (key_workbench) room_goto(rmWorkbench);
}