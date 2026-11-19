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
		
	audio_play_sound(_sound, 1, false, _gain * _audio_group_vol * global.vol_master * (1 - global.muted), 0,  1 + random_range(-_pitch_range, _pitch_range));
}

/// @func sfx_play_layered(_sound, _audio_group, _pitch, _gain)
/// @desc Plays a sound on top of any copies already playing (sfx_play stops them first), at an exact pitch: for
///       sounds that should pile up, like coins landing one after another.
function sfx_play_layered(_sound, _audio_group, _pitch = 1, _gain = 1) {
	var _vol = 1;
	switch (_audio_group) {
		case AUDIO_GROUP.UI:	_vol = global.vol_ui; break;
		case AUDIO_GROUP.MUSIC: _vol = global.vol_music; break;
		case AUDIO_GROUP.SFX:	_vol = global.vol_sfx; break;
	}
	audio_play_sound(_sound, 1, false, _gain * _vol * global.vol_master * (1 - global.muted), 0, _pitch);
}
