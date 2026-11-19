// The struct is the die; these copies are kept in step with it every frame, so an upgrade made while the die is in hand (Artisan's Ember, an event) can't leave them out of date
if (is_struct(struct)) {
	action_type = struct.action_type;
	dice_amount = struct.dice_amount;
	dice_value = struct.dice_value;
	possible_type = struct.possible_type;
}

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

image_index = get_dice_index(dice_value);

// rolled dice: it tumbles while it flies out of the bag (and after a reroll), flicking through faces, then lands on its roll
if (room == rmCombat && is_struct(struct) && die_has_faces(struct)) {
	if (roll_anim > 0) roll_anim--;
	var _was_tumbling = tumbling;
	tumbling = (roll_anim > 0) || (!has_rolled && !no_tumble && !is_dragging);
	if (tumbling) {
		tumble_angle += 26;
		flick_timer--;
		if (flick_timer <= 0) {
			flick_face = irandom_range(1, max(1, dice_value));
			flick_timer = 3;
		}
	} else {
		tumble_angle += angle_difference(0, tumble_angle) * 0.35; // settles square
		if (_was_tumbling) land_pop = 1;
		land_pop = lerp(land_pop, 0, 0.18);
	}
}

// Get mouse position
var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

// Define sprite bounds
var half_w = sprite_width * 0.5;
var half_h = sprite_height * 0.5;
var left   = x - half_w;
var right  = x + half_w;
var top    = y - half_h;
var bottom = y + half_h;

// --- Hover detection (exclusive) ---
var hovered_local = (mx > left && mx < right && my > top && my < bottom);
if (oRunManager.holding_item || global.ui_layer != UI_LAYER.BASE) hovered_local = false;

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
// dragged over the discard pile: it swells and wobbles (oDice Draw GUI) so it's clear letting go discards it
over_discard = (room == rmCombat && is_dragging && is_mouse_over_discard_button());
if (over_discard) hover_target = 1.7;
scale = lerp(scale, hover_target, hover_speed);

// --- Start dragging ---
if (!is_dragging && hovered && mouse_check_button_pressed(mb_left)) {
	if (!still) {
	    is_dragging = true;
	    drag_offset_x = mx - x;
	    drag_offset_y = my - y;
	} else if (room == rmWorkbench) {
		// a finished die (or the Cutters' coin) goes into your bag: it flies there and is added when it lands
		with (oWorkbenchManager) {
			for (var s = 1; s <= 2; s++) if (workbench_slot[s].dice == other.struct) workbench_slot[s].dice = undefined;
		}
		var _p = instance_create_depth(x, y, -13, oDiceParticle);
		_p.die_struct = clone_die(struct, struct.permanence);
		_p.color_main = get_dice_color(struct.possible_type);
		_p.target_x = 60;
		_p.target_y = 1040;
		instance_destroy();
	}
}

// rolled dice: right-click a die in hand to reroll it (once per turn, free)
if (room == rmCombat && hovered && !is_dragging && mouse_check_button_pressed(mb_right) && instance_exists(oCombat)) {
	with (oCombat) combat_reroll_die(other.id);
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
			if (hovered_slot != -1) {
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
				var _die = other;

				// Which slot is the mouse over right now? Worked out here rather than read from the hover flags,
				// which are set in Draw GUI and so can be a frame behind.
				var _mx = device_mouse_x_to_gui(0);
				var _my = device_mouse_y_to_gui(0);
				var _target = -1;
				for (var s = 0; s < 2; s++) {
					if (abs(_mx - workbench_slot[s].xx) <= wb_tile_size / 2 && abs(_my - workbench_slot[s].yy) <= wb_tile_size / 2) _target = s;
				}

				// Dropped back on its own slot: it stays where it was
				if (_target != -1 && _die.in_slot == _target + 1) {
					_die.x = workbench_slot[_target].xx;
					_die.y = workbench_slot[_target].yy;
				} else {
					var _reason = "";
					if (_target == -1) _reason = "none";
					else if (workbench_slot[_target].dice != undefined) _reason = "full";
					else if (_target == 0 && _die.struct.dice_value == 2) _reason = "coin";
					else if (_target == 1 && workbench_slot[1].core != undefined) _reason = "core";

					if (_reason == "coin") throw_error("Can't upgrade coins", "Coins are are too small to receive a core");
					if (_reason == "core") throw_error("Core already here", "Remove the core before placing a dice here");

					// leave the slot it was in (moving between slots is allowed)
					if (_die.in_slot > 0) {
						workbench_slot[_die.in_slot - 1].dice = undefined;
						_die.in_slot = false;
					}

					if (_reason == "") {
						workbench_slot[_target].dice = _die.struct;
						_die.x = workbench_slot[_target].xx;
						_die.y = workbench_slot[_target].yy;
						_die.in_slot = _target + 1;
					}
				}
			}
	    }
	}
}

// --- Safety net (B123): a die in hand that's off screen, or still drifting long after it was dealt, is placed in the hand area
if (!is_dragging && !in_slot && !still) {
	stray_timer = (variable_instance_exists(id, "stray_timer") ? stray_timer : 0) + 1;
	var _off = (x < -40 || y < -40 || x > display_get_gui_width() + 40 || y > display_get_gui_height() + 40);
	if ((_off && has_rolled) || (!has_rolled && stray_timer > game_get_speed(gamespeed_fps) * 3)) {
		var _spot = generate_valid_targets(1, 100)[0];
		x = _spot[0]; y = _spot[1];
		target_x = x; target_y = y;
		speed = 0;
		has_rolled = true;
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
        // the guided first fight only lets through what its current step asks for (tutorial_allows)
        if (is_mouse_over_discard_button()) {
            if (tutorial_allows("discard", struct)) with (combat) {
				discard_dice(other.id);
				combat_redraw_after_discard(); // rolled dice: the first discard each turn draws a new die
			}
        } else if (oCombat.last_hover) {
			if (!die_has_keyword(struct, "exclusive") && tutorial_allows("sacrifice", struct)) {
				with (combat) sacrifice_die(other.id);
			}
		} else {
			with (combat) {
				//show_debug_message("Slot released: "+string(slot_i));
	            if (hovered_slot != -1 && tutorial_allows("place", other.struct, hovered_slot)) {
	                 apply_dice_to_slot(other.id, hovered_slot);
	            }
			}
        }
    }
	
	is_dragging = false;
	
	combat = instance_find(oCombat, 0);
    if (combat != noone) {
		oCombat.is_placing = false;
		oCombat.is_discarding = false;
	}
}