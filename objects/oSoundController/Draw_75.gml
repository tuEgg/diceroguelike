if (global.is_hovering != global.was_hovering) {
	if (global.hovering_sound != noone) {
		sfx_play(global.hovering_sound, AUDIO_GROUP.UI, random_range(0.01, 0.05));
		global.hovering_sound = noone
	}
}

if (mouse_check_button_pressed(mb_left)) {
	if (global.clicking_sound != noone) {
		sfx_play(global.clicking_sound, AUDIO_GROUP.UI, random_range(0.01, 0.05));
	}
}