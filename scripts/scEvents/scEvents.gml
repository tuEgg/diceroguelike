function define_events() {
	global.master_event_list = ds_list_create();
	
	event_prisoner = {
		name: "Pirate Prisoner",
		description: "Your crew drags aboard a snarling pirate bound at the wrists. He claims he was only following orders. The men look to you for judgement.",
		options: ds_list_create(),
	}
		event_prisoner_opt_1 = {
			description: "Recruit him as a deckhand. -gold, +alignment, +keepsake.",
			effect: function(_context) {
				global.player_alignment += 5;
				oRunManager.credits -= 10;
				ds_list_add(oRunManager.keepsakes, oRunManager.ks_message_in_a_bottle);
				oEventManager.event_complete = 0;
			},
			result: "Pirate Pete has joined your crew."
		}
		event_prisoner_opt_2 = {
			description: "Make him walk the plank. -alignment and -dice.",
			effect: function(_context) {
				global.player_alignment -= 7;
				oEventManager.deleting_die = true;
				with (oRunManager) {
					if (!dice_dealt) {
						first_turn = true;
						dice_to_deal = global.hand_size;
						is_dealing_dice = true;
						dice_dealt = true;
					}
				}
				
			},
			result: "Pirate Pete walked the plank."
		}
		event_prisoner_opt_3 = {
			description: "Drop him off at the next port. +random item.",
			effect: function(_context) {
				var consumable_options = ds_list_create();
				
				generate_item_rewards(consumable_options, global.master_item_list, 1);
				
				gain_item(consumable_options[| 0]);
				
				ds_list_destroy(consumable_options);
				
				oEventManager.event_complete = 2;
			},
			result: "Pirate Pete will be dropped off at the next port."
		}
	ds_list_add(event_prisoner.options, event_prisoner_opt_1);
	ds_list_add(event_prisoner.options, event_prisoner_opt_2);
	ds_list_add(event_prisoner.options, event_prisoner_opt_3);
	ds_list_add(global.master_event_list, event_prisoner);
	
	
}

function generate_event() {
	var event = undefined;
	
	event = event_prisoner;
	
	chosen_event = event;
}