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
	gold_reward: 35,
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
	gold_reward: 30,
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
	gold_reward: 35,
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

bounty_condition_dice = {
	icon: sDice,
	index: 3,
	scale: 1,
	color: global.color_heal,
	text: "<4", // undefined or a text/number to draw on the slot
	description: "without using more than 3 dice in a slot",
	gold_reward: 45,
	failed: false,
	trigger: function(event, data) {
		if (event == "on_dice_played_to_slot") {
			if (ds_list_size(data._slot.dice_list) > 3) {
				failed = true;
			}
		}
	}
}
ds_list_add(condition_list, bounty_condition_dice);

bounty_condition_intel = {
	icon: sIntelEye,
	index: 2,
	scale: 1,
	color: global.color_intel,
	text: "", // undefined or a text/number to draw on the slot
	description: "without gaining intel after the first turn",
	gold_reward: 55,
	failed: false,
	trigger: function(event, data) {
		if (event == "on_turn_start") {
			if (data.intel > 0 && data.turn_count > 1) {
				failed = true;
			}
		}
	}
}
ds_list_add(condition_list, bounty_condition_intel);

bounty = [];
generate_bounties(2);

bounty_scale[0] = 0.8;
bounty_scale[1] = 0.8;
bounty_offset[0] = 0;
bounty_offset[1] = 0;

bounty_highlighted = -1;
bounty_selected = -1;
bounty_taken = -1;

var potion_list = ds_list_create();
potion_scale = 1;
generate_item_rewards(potion_list, global.master_item_list, 1, "consumable", "common");
potion = potion_list[| 0];
ds_list_destroy(potion_list);