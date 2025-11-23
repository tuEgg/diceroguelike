var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// Get mouse position
var mx = device_mouse_x(0);
var my = device_mouse_y(0);

var hovered = position_meeting(mx, my, self);

if (hovered && !is_dragging) {
	queue_tooltip(mouse_x, mouse_y, "The Hammer", "Smash a new core into your dice using this", undefined, 0, undefined);
}

// --- Start dragging ---
if (!is_dragging && hovered && mouse_check_button_pressed(mb_left)) {
    is_dragging = true;
	drag_offset_x = mx - x;
	drag_offset_y = my - y;
	first_selected = true;
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
		image_angle = 60;
	} else {
		image_angle = lerp(image_angle, 0, 0.2);
	}
	
	// Check if as we smash the hammer we are over the craft button
	if (mouse_check_button_pressed(mb_left)) { 
		var over_button = mouse_hovering(gui_w/2 + 200, gui_h/2 + 280, gui_w/2 + 400, gui_h/2 + 280 + 122, false);
		if (over_button && oWorkbenchManager.workbench_slot[0].dice != undefined && oWorkbenchManager.workbench_slot[1].core != undefined) {
			oWorkbenchManager.craft = true;
		}
	}
} else {
	oRunManager.holding_item = false;
	x = lerp(x, xstart, 0.2);
	y = lerp(y, ystart, 0.2);
}

if (is_dragging && first_selected && mouse_check_button_released(mb_left)) {
	first_selected = false;
}