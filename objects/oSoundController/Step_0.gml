global.was_hovering = global.is_hovering;
global.is_hovering = noone;

if (global.was_hovering != noone && global.is_hovering == noone) {
	global.clicking_sound = noone;
	global.hovering_sound = noone;
}