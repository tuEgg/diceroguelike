var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// Get mouse position
var mx = device_mouse_x(0);
var my = device_mouse_y(0);

var hovered = position_meeting(mx, my, self);

if (hovered && !is_dragging) {
	queue_tooltip(mouse_x, mouse_y, "The Drill", "Drill a new core into your dice using this", undefined, 0, undefined);
}

// --- Start dragging ---
if (!is_dragging && hovered && mouse_check_button_pressed(mb_left) && !oRunManager.holding_item) {
    is_dragging = true;
	drag_offset_x = mx - x;
	drag_offset_y = my - y;
	first_selected = true;
	oWorkbenchManager.button_text = "Drill";
}

if (is_dragging && mouse_check_button_pressed(mb_right)) {
	is_dragging = false;
	drill_change_time = drill_change_time_start;
}

// --- Dragging movement ---
if (is_dragging) {
	oRunManager.holding_item = true;
    x = mx;
    y = my;
	
	// Smash the hammer
	if (mouse_check_button(mb_left) && !first_selected) {
		drill_timer++
		
		if (drill_timer == drill_change_time) {
			if (drill_change_time <= drill_change_time_min) {
				if (image_index == 1 | image_index == 2) image_index = 0;
				if (image_index == 4 | image_index == 5) image_index = 3;
				image_index += 2;
			}
			image_index++;
			drill_timer = 0;
			drill_change_time = max( drill_change_time - 1, drill_change_time_min);
		}
	} else {
		image_xscale = 1;
		drill_change_time = drill_change_time_start;
	}
	
	over_button = mouse_hovering(gui_w/2, gui_h/2 - 40, 160, 80, true);
	
	if (over_button) {
		oWorkbenchManager.button_hovered = true;
	}
	
	// Check if as we smash the hammer we are over the craft button
	if (mouse_check_button(mb_left)) { 
		if (over_button) {
			particle_emit(mouse_x, mouse_y + 270, "burst", c_grey, 1);
		
			if (oWorkbenchManager.workbench_slot[0].dice != undefined && oWorkbenchManager.workbench_slot[1].core != undefined) {
				if (drill_change_time <= drill_change_time_min) {
					oWorkbenchManager.crafting_state = "drilled";
				}
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