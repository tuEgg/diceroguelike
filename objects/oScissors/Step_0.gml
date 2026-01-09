var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// Get mouse position
var mx = device_mouse_x(0);
var my = device_mouse_y(0);

var hovered = position_meeting(mx, my, self);

if (hovered && !is_dragging) {
	queue_tooltip(mouse_x, mouse_y, "The Cutters", "Cut two faces off of one of your die", undefined, 0, undefined);
}

// --- Start dragging ---
if (!is_dragging && hovered && mouse_check_button_pressed(mb_left) && !oRunManager.holding_item) {
    is_dragging = true;
	drag_offset_x = mx - x;
	drag_offset_y = my - y;
	first_selected = true;
	oWorkbenchManager.button_text = "Cut";
}

if (is_dragging && mouse_check_button_pressed(mb_right)) {
	is_dragging = false;
}

// --- Dragging movement ---
if (is_dragging) {
	oRunManager.holding_item = true;
    x = mx;
    y = my;
	
	// Smash the hammer
	if (mouse_check_button(mb_left) && !first_selected) {
		image_index = 1;
	} else {
		image_index = 0;
	}
	
	over_button = mouse_hovering(916, 937, 1160-916, 150, false);
	
	if (over_button) {
		oWorkbenchManager.button_hovered = true;
	}
	
	// Check if as we smash the hammer we are over the craft button
	if (mouse_check_button_pressed(mb_left)) {
		var x1 = x - 183;
		var y1 = y - 423;
		var x2 = x + 53;
		var y2 = y - 160;
	
		if (over_button) {
			if (oWorkbenchManager.workbench_slot[0].dice != undefined && oWorkbenchManager.workbench_slot[1].core == undefined && oWorkbenchManager.workbench_slot[1].dice == undefined && oWorkbenchManager.workbench_slot[2].dice == undefined) {
				oWorkbenchManager.crafting_state = "cut";
			} else {
				oWorkbenchManager.error_shake = true;
			}
		}
	}
} else {
	x = lerp(x, xstart, 0.2);
	y = lerp(y, ystart, 0.2);
	over_button = false;
}

if (is_dragging && first_selected && mouse_check_button_released(mb_left)) {
	first_selected = false;
}