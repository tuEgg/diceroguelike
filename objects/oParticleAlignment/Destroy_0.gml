// a mote landed (or timed out): the compass moves one step its way, kept within 0 (ruthless) to 100 (merciful)
global.player_alignment = clamp(global.player_alignment + negative, 0, 100);
