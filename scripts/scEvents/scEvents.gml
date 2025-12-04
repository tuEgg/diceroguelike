function define_events() {
	global.master_event_list = ds_list_create();
	
	// --------------------------
	// EVENT
	// --------------------------
	
	event_prisoner = {
		name: "Pirate Prisoner",
		description: "Your crew drags aboard a snarling pirate bound at the wrists. He claims he was only following orders. The men look to you for judgement.",
		options: ds_list_create(),
	}
		event_prisoner_opt_1 = {
			description: "Recruit him as a deckhand. -10 gold, + alignment, + keepsake.",
			effect: function(_context) {
				if (oRunManager.credits >= 10) {
					global.player_alignment += 5;
					oRunManager.credits -= 10;
					ds_list_add(oRunManager.keepsakes, oRunManager.ks_message_in_a_bottle);
					oEventManager.event_complete = 0;
					oEventManager.event_selected = true;
				} else {
					throw_error("Need more credits", "10 needed to complete this event.");
				}
			},
			result: "Pirate Pete has joined your crew."
		}
		event_prisoner_opt_2 = {
			description: "Make him walk the plank. - alignment, - dice.",
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
				
				oEventManager.event_selected = true;
			},
			result: "Pirate Pete walked the plank."
		}
		event_prisoner_opt_3 = {
			description: "Drop him off at the next port. + random item.",
			effect: function(_context) {
				var consumable_options = ds_list_create();
				
				generate_item_rewards(consumable_options, global.master_item_list, 1);
				
				gain_item(consumable_options[| 0]);
				
				ds_list_destroy(consumable_options);
				
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "Pirate Pete will be dropped off at the next port."
		}
	ds_list_add(event_prisoner.options, event_prisoner_opt_1);
	ds_list_add(event_prisoner.options, event_prisoner_opt_2);
	ds_list_add(event_prisoner.options, event_prisoner_opt_3);
	ds_list_add(global.master_event_list, event_prisoner);
	
	
	// --------------------------
	// EVENT
	// --------------------------
	
	event_storm = {
		name: "A Great Storm",
		description: "Storms ruined a week’s worth of salted pork. Hunger has the crew restless, and the quartermaster demands a ruling.",
		options: ds_list_create(),
	}
		event_storm_opt_1 = {
			description: "Share your personal stores. + alignment, -7 hp, upgrade a random block or heal die.",
			effect: function(_context) {
				global.player_hp -= 7;
				global.player_alignment += 5;
				// search through all dice, add block and heals to a temporary ds list, return a random index, upgrade that index's dice value +2, then destroy the list
				
				var heal_block_list = ds_list_create();
					
				for (var d = 0; d < ds_list_size(global.dice_bag); d++) {
					var die = global.dice_bag[| d];
					
					if (die.action_type == "HEAL" || die.action_type == "BLK") {
						ds_list_add(heal_block_list, die);
					}
				}
				
				var rand_ind = irandom(ds_list_size(heal_block_list)-1);
				var rand_die = heal_block_list[| rand_ind];
				
				rand_die.dice_value += 2;
				
				particle_emit( 115, 1000, choose("rise"), rand_die.color);
				
				ds_list_destroy(heal_block_list);
				
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "You share your stores with the crew."
		}
		event_storm_opt_2 = {
			description: "Cut rations for everyone. - alignment, + keepsake.",
			effect: function(_context) {
				global.player_alignment -= 4;
				ds_list_add(oRunManager.keepsakes, oRunManager.ks_ghost_lantern);
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "A hard decision."
		}
		event_storm_opt_3 = {
			description: "Let the crew solve it for themselves. +1 dice playable next combat.",
			effect: function(_context) {
				oRunManager.bonus_dice_next_combat = 1;
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "The crew decided to throw a man overboard."
		}
	ds_list_add(event_storm.options, event_storm_opt_1);
	ds_list_add(event_storm.options, event_storm_opt_2);
	ds_list_add(event_storm.options, event_storm_opt_3);
	ds_list_add(global.master_event_list, event_storm);
	
	
	// --------------------------
	// EVENT
	// --------------------------
	
	event_upgrade = {
		name: "Clear skies.",
		description: "Clear skies ahead after a long night of travel, a chance to rest as the journey continues.",
		options: ds_list_create(),
	}
		event_upgrade_opt_1 = {
			description: "Get some much needed sleep. +5 max hp, heal to full.",
			effect: function(_context) {
				global.player_max_hp += 5;
				global.player_hp = global.player_max_hp;
				
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "You feel well rested."
		}
		event_upgrade_opt_2 = {
			description: "Take this opportunity to sharpen your blades. Upgrade all of your attack dice.",
			effect: function(_context) {
				// search through all dice, add block and heals to a temporary ds list, return a random index, upgrade that index's dice value +2, then destroy the list
					
				for (var d = 0; d < ds_list_size(global.dice_bag); d++) {
					var die = global.dice_bag[| d];
					
					if (die.action_type == "ATK") {
						die.dice_value += 2;
						particle_emit( 115, 1000, choose("rise"), die.color);
					}
				}
				
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "Blades sharpened, ready for the long trip ahead."
		}
	ds_list_add(event_upgrade.options, event_upgrade_opt_1);
	ds_list_add(event_upgrade.options, event_upgrade_opt_2);
	ds_list_add(global.master_event_list, event_upgrade);
}

function generate_event() {
	var event = undefined;
	
	var rand = irandom(ds_list_size(global.master_event_list) - 1);
	
	event = global.master_event_list[| rand];
	
	chosen_event = event;
}