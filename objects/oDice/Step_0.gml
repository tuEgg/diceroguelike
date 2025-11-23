if (!still) {
	if distance_to_point(target_x, target_y) < 150 && !has_rolled {
		speed = lerp(speed, 0, 0.15);
		if abs(speed) < 1.0 {
			has_rolled = true;
			target_x = x;
			target_y = y;
			speed = 0;
		}
	}
}


switch (dice_value) {
	case 2:
	image_index = 2;
	break;
	
	case 4:
	image_index = 0;
	break;
	
	case 6:
	image_index = 1;
	break;
}

// Get mouse position
var mx = device_mouse_x(0);
var my = device_mouse_y(0);

// Define sprite bounds
var half_w = sprite_width * 0.5;
var half_h = sprite_height * 0.5;
var left   = x - half_w;
var right  = x + half_w;
var top    = y - half_h;
var bottom = y + half_h;

// --- Hover detection (exclusive) ---
var hovered_local = (mx > left && mx < right && my > top && my < bottom);
if (oRunManager.holding_item) hovered_local = false;

// If nothing else is hovered OR this dice is already the hovered one
if (hovered_local && (global.hovered_dice_id == noone || global.hovered_dice_id == id)) {
    global.hovered_dice_id = id;
	depth = -10;
    hovered = true;
} else {
    // If this dice isn’t the currently hovered one, disable hover
    if (global.hovered_dice_id != id) {
		depth = -8;
		hovered = false;
	}
}

// --- Clear hover when mouse leaves all dice ---
if (!hovered_local && global.hovered_dice_id == id) {
    global.hovered_dice_id = noone;
}

// --- Smooth scaling ---
hover_target = hovered ? hover_scale : 1.0;
scale = lerp(scale, hover_target, hover_speed);

// --- Start dragging ---
if (!is_dragging && hovered && mouse_check_button_pressed(mb_left)) {
	if (!still) {
	    is_dragging = true;
	    drag_offset_x = mx - x;
	    drag_offset_y = my - y;
	} else if (room == rmWorkbench) {
		discard_dice_in_play();
	}
}

// --- Dragging movement ---
if (is_dragging) {
    x = mx - drag_offset_x;
    y = my - drag_offset_y;
	
	var combat = instance_find(oCombat, 0);
    if (combat != noone) {

	    // Stop dragging on release
	    if (mouse_check_button_released(mb_left) && !oCombat.is_discarding && !oCombat.is_placing && !oCombat.last_hover) {
	        is_dragging = false;
	    }
		
		combat.grabbed_amount = other.dice_amount;
		combat.grabbed_value  = other.dice_value;
		combat.grabbed_type   = other.possible_type;
				
        // Update is_discarding live during drag
        combat.is_discarding = is_mouse_over_discard_button();
		with (oCombat) { 
			if (get_hovered_action_slot() != -1) {
				combat.is_placing = true;
			}
		}
    }
	
	var workbench = instance_find(oWorkbenchManager, 0);
	if (workbench != noone) {

	    // Stop dragging on release
	    if (mouse_check_button_released(mb_left)) {
	        is_dragging = false;
		
			with (oWorkbenchManager) { 
				if (hovered_slot_1) {
					workbench_slot[0].dice = other.struct;
					other.x = workbench_slot[0].xx;
					other.y = workbench_slot[0].yy;
					other.in_slot = true;
				} else {
					other.in_slot = false;
					workbench_slot[0].dice = undefined;
				}
			}
	    }
	}
}

// --- Snap back smoothly when not dragging ---
if (!is_dragging && has_rolled && !in_slot && !still) {

	// Only if we are out of bounds of the safe area
	if (x > global.dice_safe_area_x2 || x < global.dice_safe_area_x1 || y > global.dice_safe_area_y2 || y < global.dice_safe_area_y1) {
		x = lerp(x, target_x, snap_speed);
	    y = lerp(y, target_y, snap_speed);
	}
}

if (is_dragging && mouse_check_button_released(mb_left)) {	
    var combat = instance_find(oCombat, 0);
    if (combat != noone) {
        if (is_mouse_over_discard_button()) {
            with (combat) discard_dice(other.id);
        } else if (oCombat.last_hover) {
			with (combat) sacrifice_die(other.id);
		} else {
			with (combat) {
	            var slot_i = get_hovered_action_slot();
				//show_debug_message("Slot released: "+string(slot_i));
	            if (slot_i != -1) {
	                 apply_dice_to_slot(other.id, slot_i);
	            }
			}
        }
    }
	
	is_dragging = false;
	
	var combat = instance_find(oCombat, 0);
    if (combat != noone) {
		oCombat.is_placing = false;
		oCombat.is_discarding = false;
	}
}