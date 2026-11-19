// a look-only die (combat_shuffle_effect) just lands with a puff
if (visual_only) { particle_emit(x, y, "burst", color_main, 8); exit; }

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