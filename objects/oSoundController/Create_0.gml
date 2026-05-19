global.vol_master = 1;
global.vol_sfx = 1;
global.vol_music = 1;
global.vol_ui = 0.5;
global.muted = false;

audio_group_load(audiogroup_UI);
audio_group_load(audiogroup_music);
audio_group_load(audiogroup_sfx);

global.was_hovering = noone;
global.is_hovering = noone;
global.hovering_sound = noone; //change to other sounds for certain objects
global.clicking_sound = noone;

enum AUDIO_GROUP {
	UI = 0,
	MUSIC = 1,
	SFX = 2,
}