// for dealing dice
if (is_dealing_dice) {
	if (dice_deal_timer > 0) {
		dice_deal_timer--;
	} else {
		// Time to deal the next die
		if (dice_to_deal > 0) {
			deal_single_die();
			dice_to_deal--;
			dice_deal_timer = dice_deal_delay;
		} else {
			// Finished dealing all dice
			is_dealing_dice = false;
		}
	}
}