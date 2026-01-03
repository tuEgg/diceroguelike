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

if (!oHammer.over_button) && (!oScissors.over_button) {
	button_hovered = false;
}

button_scale = lerp(button_scale, button_hovered ? 1.2 : 1.0, 0.2);