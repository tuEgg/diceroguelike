// a click sound belongs to what is under the mouse right now: it used to stay set after a silent hover (no hover
// sound), so clicking empty space later still played it (Jared, 2026-11-24). One frame of memory, for what draws late.
global.clicking_sound_prev = global.clicking_sound;
global.clicking_sound = noone;
global.was_hovering = global.is_hovering;
global.is_hovering = noone;

if (global.was_hovering != noone && global.is_hovering == noone) {
	global.clicking_sound = noone;
	global.hovering_sound = noone;
}