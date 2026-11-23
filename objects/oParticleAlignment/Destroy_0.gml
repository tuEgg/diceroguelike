// a mote landed (or timed out): the compass moves one step its way, kept within 0 (ruthless) to 100 (merciful)
global.player_alignment = clamp(global.player_alignment + negative, 0, 100);
// each mote chimes as it lands: rising through a gain, falling through a loss
var _p = (negative > 0) ? min(1.45, 0.9 + order * 0.035) : max(0.6, 1.1 - order * 0.035);
sfx_play_layered(soAlignment, AUDIO_GROUP.SFX, _p + random_range(-0.01, 0.01), 0.35);
