var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// Get mouse position
var mx = device_mouse_x(0);
var my = device_mouse_y(0);

var hovered = position_meeting(mx, my, self);

if (hovered && !is_dragging) {
	queue_tooltip(mouse_x, mouse_y, "The Hammer", "Smash two dice together using this", undefined, 0, undefined);
}

// --- Start dragging ---
if (!is_dragging && hovered && mouse_check_button_pressed(mb_left) && !oRunManager.holding_item) {
    is_dragging = true;
	drag_offset_x = mx - x;
	drag_offset_y = my - y;
	first_selected = true;
	oWorkbenchManager.button_text = "Craft";
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
	
	over_button = mouse_hovering(gui_w/2 + 200, gui_h/2 + 260, 280, 160, false);
	
	if (over_button) {
		oWorkbenchManager.button_hovered = true;
	}
	
	// Check if as we smash the hammer we are over the craft button
	if (mouse_check_button(mb_left)) { 
		if (over_button) {
			if (oWorkbenchManager.workbench_slot[0].dice != undefined && oWorkbenchManager.workbench_slot[1].core != undefined) {
				oWorkbenchManager.crafting_state = "hammered";
			} else {
				oWorkbenchManager.error_shake = true;
			}
		}
		
	}
} else {
	x = lerp(x, xstart, 0.2);
	y = lerp(y, ystart, 0.2);
	image_angle = lerp(image_angle, 0, 0.2);
	over_button = false;
}

if (is_dragging && first_selected && mouse_check_button_released(mb_left)) {
	first_selected = false;
}