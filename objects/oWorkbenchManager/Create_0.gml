workbench_slot[0] = { dice: undefined, name: "Dice", xx: 715, yy: 490 }; // dice input
workbench_slot[1] = { dice: undefined, core: undefined, name: "Core", xx: 0, yy: 0 }; // core input
workbench_slot[2] = { dice: undefined, name: "Output", xx: 0, yy: 0 }; // dice output

wb_scale[0] = 1.0;
wb_scale[1] = 1.0;
wb_scale[2] = 1.0;

core_scale = 1.0; // used to make the cores feel like an item (like the dice feels with hovering)

slot_alpha = 1.0;

hovered_slot_1 = false;
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