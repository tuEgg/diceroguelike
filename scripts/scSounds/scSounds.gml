// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function sfx_play(_sound, _audio_group, _pitch_range = 0.00, _gain = 1) {
	if (audio_is_playing(_sound)) audio_stop_sound(_sound);
	
	var _audio_group_vol = 1;
	
	switch (_audio_group) {
		case AUDIO_GROUP.UI:	_audio_group_vol = global.vol_ui; break;
		case AUDIO_GROUP.MUSIC: _audio_group_vol = global.vol_music; break;
		case AUDIO_GROUP.SFX:	_audio_group_vol = global.vol_sfx; break;
	}
		
	audio_play_sound(_sound, 1, false, _gain * _audio_group_vol, 0,  1 + random_range(-_pitch_range, _pitch_range));
}