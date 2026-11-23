// a look-only die (combat_shuffle_effect) just lands with a puff
if (visual_only) {
	particle_emit(x, y, "burst", color_main, 8);
	// the shuffled dice drop into the bag: a soft rattle (Jared, 2026-11-23; each lands over the last, sfx_play cuts the one before)
	sfx_play(choose(soDiceRolling1, soDiceRolling2, soDiceRolling3), AUDIO_GROUP.SFX, 0.08, 0.2);
	exit;
}

if (room == rmCombat) {
	if (oCombat.show_rewards) {
		add_dice_to_bag(id);
	} else {
		discard_dice(id);
		//show_debug_message("Dice Discarded");
	}
	
} else {
	add_dice_to_bag(id);
}