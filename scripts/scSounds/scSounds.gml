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

/// @func sfx_group_gain(_audio_group)
/// @desc The volume a sound in this group plays at: the group's slider, the master slider, muted or not.
function sfx_group_gain(_audio_group) {
	var _vol = 1;
	switch (_audio_group) {
		case AUDIO_GROUP.UI:	_vol = global.vol_ui; break;
		case AUDIO_GROUP.MUSIC: _vol = global.vol_music; break;
		case AUDIO_GROUP.SFX:	_vol = global.vol_sfx; break;
	}
	return _vol * global.vol_master * (1 - global.muted);
}

/// @func sfx_loop(_handle, _on, _sound, _audio_group, _gain)
/// @desc Keeps a looping sound going while _on is true and stops it when it isn't. Pass the handle it returned last
///       time (-1 to start with); keep what it returns. (The quill scratching while you draw in the ink view.)
function sfx_loop(_handle, _on, _sound, _audio_group, _gain = 1) {
	var _playing = (_handle != -1) && audio_is_playing(_handle);
	if (_on && !_playing) return audio_play_sound(_sound, 1, true, _gain * sfx_group_gain(_audio_group), 0, 1 + random_range(-0.04, 0.04));
	if (!_on && _playing) audio_stop_sound(_handle);
	return _on ? _handle : -1;
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
