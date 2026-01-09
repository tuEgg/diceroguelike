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


button_scale = lerp(button_scale, button_hovered ? 1.2 : 1.0, 0.2);

var dragging = false;
var hovered = false;

if (instance_exists(oScissors)) {
    dragging |= oScissors.is_dragging;
	hovered |= oScissors.over_button;
}

if (instance_exists(oHammer)) {
    dragging |= oHammer.is_dragging;
	hovered |= oHammer.over_button;
}

if (instance_exists(oDrill)) {
    dragging |= oDrill.is_dragging;
	hovered |= oDrill.over_button;
}

oRunManager.holding_item = dragging;
button_hovered = hovered;