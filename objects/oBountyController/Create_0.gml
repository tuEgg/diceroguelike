exit_scale = 1.0;
reroll_scale = 1.0;
reroll_col = global.color_block;

condition_list = ds_list_create();

bounty_condition_slots = {
	icon: sActionSlotCentered,
	index: 1,
	scale: 0.5,
	color: global.color_attack,
	text: "<5", // undefined or a text/number to draw on the slot
	description: "without making more than 4 slots.",
	gold_reward: 75,
	failed: false,
	trigger: function(event, data) {
		if (event == "on_new_slot_created") {
			if (ds_list_size(oCombat.action_queue) > 4) {
				failed = true;
			}
		}
	}
}
ds_list_add(condition_list, bounty_condition_slots);

bounty_condition_potion = {
	icon: sConsumables,
	index: 1,
	scale: 1.25,
	color: c_white,
	text: "", // undefined or a text/number to draw on the slot
	description: "without using any potions",
	gold_reward: 70,
	failed: false,
	trigger: function(event, data) {
		if (event == "on_consumable_used") {
			failed = true;
		}
	}
}
ds_list_add(condition_list, bounty_condition_potion);

bounty_condition_block = {
	icon: sIntentIcons,
	index: 1,
	scale: 1.25,
	color: global.color_block,
	text: "", // undefined or a text/number to draw on the slot
	description: "without ever having more than 12 block",
	gold_reward: 70,
	failed: false,
	trigger: function(event, data) {
		if (event == "on_player_block_gained") {
			if (oCombat.player_block_amount > 12) {
				failed = true;
			}
		}
	}
}
ds_list_add(condition_list, bounty_condition_block);

bounty = [];
generate_bounties(2);

bounty_scale[0] = 0.8;
bounty_scale[1] = 0.8;
bounty_offset[0] = 0;
bounty_offset[1] = 0;

bounty_highlighted = -1;
bounty_selected = -1;
bounty_taken = -1;