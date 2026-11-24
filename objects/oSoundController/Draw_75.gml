if (global.is_hovering != global.was_hovering) {
	if (global.hovering_sound == soPaper5) {
		// the slots' paper rustle (Jared, 2026-11-23): 30% quieter, a wider pitch spread and a little volume spread so
		// it doesn't sound the same each time, and not again within 70 ms, so flicking across slots doesn't rattle
		if (current_time - paper_hover_last > 70) {
			sfx_play(soPaper5, AUDIO_GROUP.UI, 0.08, 0.7 * random_range(0.85, 1));
			paper_hover_last = current_time;
		}
		global.hovering_sound = noone;
	} else if (global.hovering_sound != noone) {
		sfx_play(global.hovering_sound, AUDIO_GROUP.UI, random_range(0.01, 0.05));
		global.hovering_sound = noone
	}
}

if (mouse_check_button_pressed(mb_left)) {
	// what is under the mouse now, or was a frame ago (things drawn after this event set theirs for the next frame)
	var _click_snd = (global.clicking_sound != noone) ? global.clicking_sound : global.clicking_sound_prev;
	if (_click_snd != noone) {
		sfx_play(_click_snd, AUDIO_GROUP.UI, random_range(0.01, 0.05));
	}
}