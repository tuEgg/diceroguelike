if (exiting) {
	if (instance_exists(oDice)) {
		if (instance_exists(oDice)) {
			discard_dice_in_play();
		}
	} else if (instance_exists(oDiceParticle)) {
		
	} else {
		room_goto(rmMap);
	}
}