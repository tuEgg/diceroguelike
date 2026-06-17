if (cutscene_index != -1) {
	var cutscene = cutscenes[cutscene_index];

	switch (cutscene_state) {
		case CUTSCENE_STATE.STARTED:
			// Play voiceover at the start of the scene
			if (cutscene.voiceover != undefined) {
				sfx_play(cutscene.voiceover, AUDIO_GROUP.MUSIC);
			}
	
			// Play music at the start of the scene
			if (cutscene.music != undefined) {
				sfx_play(cutscene.music, AUDIO_GROUP.MUSIC);
			}
	
			cutscene_state = CUTSCENE_STATE.PLAYING;
			global.all_input_disabled = true;
		break;
	
		case CUTSCENE_STATE.PLAYING:
			cutscene_timer++;
			
			if (keyboard_check(vk_escape)) {
				skip_timer++;
			}
			
			if (keyboard_check_released(vk_escape)) {
				skip_timer = 0;
			}
			
			// if we reach the end of the cutscene timer or we skip, end the scene
			if (skip_timer >= 0.5 * game_get_speed(gamespeed_fps) || cutscene_timer > cutscene.length * game_get_speed(gamespeed_fps)) {
			
				// stop the music
				if (cutscene.music != undefined) {
					if (audio_is_playing(cutscene.music)) {
						audio_stop_sound(cutscene.music);
					}
				}
			
				// stop the voiceover
				if (cutscene.voiceover != undefined) {
					if (audio_is_playing(cutscene.voiceover)) {
						audio_stop_sound(cutscene.voiceover);
					}
				}
			
				// end the cutscene
				cutscene_state = CUTSCENE_STATE.FINISHED;
			}
		break;
	
		case CUTSCENE_STATE.FINISHED:
			global.all_input_disabled = false;
			cutscene_index = -1;
			scene_index = 0;
		break;
	}
}