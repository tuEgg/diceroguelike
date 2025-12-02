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