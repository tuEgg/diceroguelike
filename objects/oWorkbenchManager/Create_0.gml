workbench_slot[0] = { dice: undefined,						name: "Dice", xx: 715, yy: 490 }; // dice input
workbench_slot[1] = { dice: undefined, core: undefined,		name: "Dice/Core", xx: 0, yy: 0 }; // dice OR core input
workbench_slot[2] = { dice: undefined,						name: "Output", xx: 0, yy: 0 }; // dice output

wb_scale[0] = 1.0;
wb_scale[1] = 1.0;
wb_scale[2] = 1.0;

core_scale = 1.0; // used to make the cores feel like an item (like the dice feels with hovering)

slot_alpha = 1.0;

hovered_slot_1 = false;
hovered_slot_2 = false;
core_prev_item_slot = -1;
crafting_state = "waiting"; // waiting, hammered, cut

bang_timer = 15;

exit_scale = 1.0;

exiting = false;

button_text = "Craft";
button_hovered = false;
button_scale = 1.0;

snipped_x = 1;
snipped_y = 1;
snipped_angle = 0;

with (oRunManager) {
	if (!dice_dealt) {
		turn_count = 1;
		dice_to_deal = global.hand_size;
		is_dealing_dice = true;
		dice_dealt = true;
	}
}

error_shake = false;
error_wobble_phase = 0;
error_wobble_amp = 30; // degrees

gui_w = display_get_gui_width();
gui_h = display_get_gui_height();

mx = device_mouse_x_to_gui(0);
my = device_mouse_y_to_gui(0);

wb_list_size = array_length(workbench_slot);
wb_tile_size = sprite_get_width(sActionSlotCentered);
wb_tile_padding = 50;
	
start_x = gui_w/2 - wb_tile_padding - wb_tile_size;
start_y = gui_h/2 - 50;