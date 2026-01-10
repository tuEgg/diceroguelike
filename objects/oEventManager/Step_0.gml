if (exiting) {
	if (instance_exists(oDice)) {
		if (instance_exists(oDice)) {
			discard_dice_in_play();
		}
	} else if (instance_exists(oDiceParticle)) {
		
	} else {
		if (!alternate_exit) {
			room_goto(rmMap);
		} else {
			room_goto(alternate_exit);
			alternate_exit = false;
		}
	}
}