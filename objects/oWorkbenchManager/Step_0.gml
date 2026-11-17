gui_w = display_get_gui_width();
gui_h = display_get_gui_height();

mx = device_mouse_x_to_gui(0);
my = device_mouse_y_to_gui(0);

wb_list_size = array_length(workbench_slot);
wb_tile_size = sprite_get_width(sActionSlotCentered);
wb_tile_padding = 50;
	
start_x = gui_w/2 - wb_tile_padding - wb_tile_size;
start_y = gui_h/2 - 50;

workbench_slot[0].xx = start_x;
workbench_slot[0].yy = start_y;
workbench_slot[1].xx = start_x + (1 * (wb_tile_padding + wb_tile_size));
workbench_slot[1].yy = start_y;
workbench_slot[2].xx = start_x + (2 * (wb_tile_padding + wb_tile_size));
workbench_slot[2].yy = start_y;

if (exiting) {
	if (instance_exists(oDice)) {
		if (instance_exists(oDice)) {
			discard_dice_in_play();
		}
	} else if (instance_exists(oDiceParticle)) {
		
	} else {
		// Hand back a core left in the middle slot so it isn't lost on exit
		if (workbench_slot[1].core != undefined) {
			var _return_slot = -1;
			if (core_prev_item_slot != -1 && oRunManager.items[core_prev_item_slot] == undefined) {
				_return_slot = core_prev_item_slot;
			} else {
				for (var i = 0; i < array_length(oRunManager.items); i++) {
					if (oRunManager.items[i] == undefined) {
						_return_slot = i;
						break;
					}
				}
			}

			if (_return_slot != -1) {
				workbench_slot[1].core.dragging = false;
				oRunManager.items[_return_slot] = workbench_slot[1].core;
			}
			workbench_slot[1].core = undefined;
		}

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

// after a craft, once its results are back in your hand the bench is ready for the next tool
if (crafting_state != "waiting" && workbench_slot[1].dice == undefined && workbench_slot[2].dice == undefined && workbench_slot[0].dice == undefined && workbench_slot[1].core == undefined) {
	var _anim_done = (crafting_state != "hammered" || bang_timer <= 0) && (crafting_state != "snipped" || snipped_y >= 400);
	if (_anim_done) {
		crafting_state = "waiting";
		bang_timer = 15;
		snipped_x = 1;
		snipped_y = 1;
		snipped_angle = 0;
		button_text = "Craft";
	}
}
button_hovered = hovered;