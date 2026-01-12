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
			title: "Recruit him as a deckhand",
			description: "Lose 10 gold, gain 5 alignment, and gain the Deckhand's Token keepsake.",
			hover: function() {
				queue_tooltip(mouse_x, mouse_y, oRunManager.ks_deckhands_token.name, oRunManager.ks_deckhands_token.desc, sKeepsake, oRunManager.ks_deckhands_token.sub_image);
			},
			effect: function(_context) {
				if (oRunManager.credits >= 10) {
					global.player_alignment += 5;
					oRunManager.credits -= 10;
					gain_keepsake(oRunManager.ks_deckhands_token);
					oEventManager.event_complete = 0;
					oEventManager.event_selected = true;
				} else {
					throw_error("Need more credits", "10 needed to complete this event.");
				}
			},
			result: "Pirate Pete has joined your crew."
		}
		event_prisoner_opt_2 = {
			title: "Make him walk the plank",
			description: "Lose 7 alignment and remove a die from your bag.",
			effect: function(_context) {
				global.player_alignment -= 7;
				oEventManager.deleting_die = true;
				with (oRunManager) {
					if (!dice_dealt) {
						turn_count = 1;
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
			title: "Drop him off at the next port",
			description: "Gain a random item.",
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
		description: "Storms ruined a week's worth of salted pork. Hunger has the crew restless, and the quartermaster demands a ruling.",
		options: ds_list_create(),
	}
		event_storm_opt_1 = {
			title: "Share your personal stores",
			description: "Gain 5 alignment, lose 7 health, and upgrade a random block or heal die.",
			effect: function(_context) {
				global.player_hp -= 7;
				global.player_alignment += 5;
				// search through all dice, add block and heals to a temporary ds list, return a random index, upgrade that index's dice value +2, then destroy the list
				
				var heal_block_list = ds_list_create();
					
				for (var d = 0; d < ds_list_size(global.dice_bag); d++) {
					var die = global.dice_bag[| d];
					
					// only heal and block dice, avoid coins
					if (die.action_type == "HEAL" || die.action_type == "BLK") && (die.dice_value != 2) {
						ds_list_add(heal_block_list, die);
					}
				}
				
				// Fail safe in case we have no heal or block die
				if (ds_list_size(heal_block_list) == 0) {
				    ds_list_destroy(heal_block_list);
				    oEventManager.event_complete = 0;
				    oEventManager.event_selected = true;
				    return;
				}
				
				var rand_ind = irandom(ds_list_size(heal_block_list)-1);
				var rand_die = heal_block_list[| rand_ind];
				
				rand_die.dice_value += 2;
				
				particle_emit( 115, 1000, "rise", rand_die.color);
				
				ds_list_destroy(heal_block_list);
				
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "You share your stores with the crew."
		}
		event_storm_opt_2 = {
			title: "Cut rations for everyone",
			description: "Lose 4 alignment, and gain the Starver's Efficiency keepsake.",
			hover: function() {
				queue_tooltip(mouse_x, mouse_y, oRunManager.ks_starvers_efficiency.name, oRunManager.ks_starvers_efficiency.desc, sKeepsake, oRunManager.ks_starvers_efficiency.sub_image);
			},
			effect: function(_context) {
				global.player_alignment -= 4;
				gain_keepsake(oRunManager.ks_starvers_efficiency);
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "A hard decision."
		}
		event_storm_opt_3 = {
			title: "Let the crew solve it for themselves",
			description: "Gain 1 dice playable every turn next combat.",
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
		name: "Clear skies",
		description: "Clear skies ahead after a long night of travel, a chance to rest as the journey continues.",
		options: ds_list_create(),
	}
		event_upgrade_opt_1 = {
			title: "Get some much needed sleep",
			description: "Gain 5 max health and heal to full.",
			effect: function(_context) {
				global.player_max_hp += 5;
				if (global.player_hp < global.player_max_hp) {
					var amount = global.player_max_hp - global.player_hp;
					process_action("player", 0, amount, 0, "player", undefined, "HEAL");
					
					trigger_keepsake_visual();
				}
				
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "You feel well rested."
		}
		event_upgrade_opt_2 = {
			title: "Take this opportunity to sharpen your blades",
			description: "Upgrade 2 random attack dice.",
			effect: function(_context) {
				// search through all dice, add block and heals to a temporary ds list, return a random index, upgrade that index's dice value +2, then destroy the list
				
				var attack_list = ds_list_create();
				
				for (var d = 0; d < ds_list_size(global.dice_bag); d++) {
					var die = global.dice_bag[| d];
					
					if (die.action_type == "ATK" && die.dice_value < 12 && die.dice_value != 2) {
						ds_list_add(attack_list, d);
					}
				}
				
				// Fail safe in case we have no attack die
				if (ds_list_size(attack_list) == 0) {
				    ds_list_destroy(attack_list);
				    oEventManager.event_complete = 1;
				    oEventManager.event_selected = true;
				    return;
				}
				
				repeat (min(ds_list_size(attack_list), 2)) {
					var rand_index = irandom(ds_list_size(attack_list) - 1);
					
					var die = global.dice_bag[| attack_list[| rand_index]];
					
					die.dice_value += 2;
					particle_emit( 115, 1000, "rise", die.color);
					
					ds_list_delete(attack_list, rand_index);
				}
				
				ds_list_destroy(attack_list);
				
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "Blades sharpened, ready for the long trip ahead."
		}
	ds_list_add(event_upgrade.options, event_upgrade_opt_1);
	ds_list_add(event_upgrade.options, event_upgrade_opt_2);
	ds_list_add(global.master_event_list, event_upgrade);
	
	
	// --------------------------
	// EVENT
	// --------------------------
	
	event_sails = {
		name: "Broken sails",
		description: "One of the sails has a tear in it, travel will be difficult without making repairs or replacing it.",
		options: ds_list_create(),
	}
		event_sails_opt_1 = {
			title: "Use the backup sail",
			description: "Lose 10 coins to gain the Small Sail keepsake.",
			hover: function() {
				queue_tooltip(mouse_x, mouse_y, oRunManager.ks_small_sail.name, oRunManager.ks_small_sail.desc, sKeepsake, oRunManager.ks_small_sail.sub_image);
			},
			effect: function(_context) {
				if (oRunManager.credits >= 10) {
					oRunManager.credits -= 10;
					gain_keepsake(oRunManager.ks_small_sail);
					oEventManager.event_complete = 0;
					oEventManager.event_selected = true;
				} else {
					throw_error("Need more credits", "10 needed to complete this event.");
				}
			},
			result: "Sail replaced and you are on your way."
		}
		event_sails_opt_2 = {
			title: "Repair the sail",
			description: "Lose a random consumable to gain the Rope of Repair keepsake.",
			hover: function() {
				queue_tooltip(mouse_x, mouse_y, oRunManager.ks_rope_of_repair.name, oRunManager.ks_rope_of_repair.desc, sKeepsake, oRunManager.ks_rope_of_repair.sub_image);
			},
			effect: function(_context) {

				var item_pool = [];
				for (var i = 0; i < array_length(oRunManager.items); i++) {
					if (oRunManager.items[i] != undefined) {
						array_push(item_pool, i);
					}
				}
				
				if (array_length(item_pool) != 0) {
				
					var rand = irandom(array_length(item_pool) - 1);
					
					oRunManager.items[rand] = undefined;
					gain_keepsake(oRunManager.ks_rope_of_repair);
					oEventManager.event_complete = 1;
					oEventManager.event_selected = true;
				} else {
					throw_error("No consumables to sacrifice", "At least 1 is needed to complete this event.");
				}
			},
			result: "Sail repaired, it should hold out."
		}
		event_sails_opt_3 = {
			title: "Continue with the tear",
			description: "Proceed as you are and lose 2 max health.",
			effect: function(_context) {
				global.player_max_hp -= 2;
				if (global.player_hp > global.player_max_hp) global.player_hp = global.player_max_hp;
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "You take the risk to proceed as you are."
		}
	ds_list_add(event_sails.options, event_sails_opt_1);
	ds_list_add(event_sails.options, event_sails_opt_2);
	ds_list_add(event_sails.options, event_sails_opt_3);
	ds_list_add(global.master_event_list, event_sails);
	
	
	// --------------------------
	// EVENT
	// --------------------------
	
	event_bounty = {
		name: "Dividing up the bounty",
		description: "Your latest plunder has been sold and shared amongst the crew, everyone has their fair share. What will you do?",
		options: ds_list_create(),
	}
		event_bounty_opt_1 = {
			title: "Demand a bigger share",
			description: "Gain 120 gold and lose 7 alignment.",
			effect: function(_context) {
				gain_coins(mouse_x, mouse_y, 120);
				global.player_alignment -= 7;
				
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "The crew fork over more of the bounty, morale seems lower."
		}
		event_bounty_opt_2 = {
			title: "Take your fair share",
			description: "Gain 80 gold.",
			effect: function(_context) {
				gain_coins(mouse_x, mouse_y, 80);
				
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "You take your share of the bounty."
		}
		event_bounty_opt_3 = {
			title: "Take a smaller share to boost morale",
			description: "Gain 40 gold and 7 alignment.",
			effect: function(_context) {
				gain_coins(mouse_x, mouse_y, 40);
				global.player_alignment += 7;
				
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "You half your cut and share the rest with the crew, they seem pleased."
		}
	ds_list_add(event_bounty.options, event_bounty_opt_1);
	ds_list_add(event_bounty.options, event_bounty_opt_2);
	ds_list_add(event_bounty.options, event_bounty_opt_3);
	ds_list_add(global.master_event_list, event_bounty);
	
	
	// --------------------------
	// EVENT
	// --------------------------
	
	event_trunk = {
		name: "A Hidden Trunk",
		description: "You tidy up your quarters, and discover a small trunk under the bed you left there months ago. You open it - excited as you remember what's inside. What do you see?",
		options: ds_list_create(),
	}
		event_trunk_opt_1 = {
			title: "A token from an ex lover",
			description: "Gain a random dice.",
			effect: function(_context) {
				
				// Generate a random dice
				var dice_options = ds_list_create();
				generate_dice_rewards(dice_options, global.master_dice_list, 1);
				
				var die_struct = dice_options[| 0];
				
				var die_inst = instance_create_layer(display_get_gui_width()/2, display_get_gui_height() + 100, "Instances", oDice);
				die_inst.struct = die_struct;
			    die_inst.action_type = die_struct.action_type;
			    die_inst.dice_amount = die_struct.dice_amount;
			    die_inst.dice_value  = die_struct.dice_value;
				die_inst.possible_type = die_struct.possible_type;
				die_inst.can_discard = true;

				var target = generate_valid_targets(1, 100) [0];
				die_inst.target_x = target[0];
				die_inst.target_y = target[1];
				
				ds_list_destroy(dice_options);
					
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
				
			},
			result: "Result"
		}
		event_trunk_opt_2 = {
			title: "An heirloom from a time gone by",
			description: "Gain a random core.",
			effect: function(_context) {
				if (get_first_free_item_slot() != -1) {
					
					// Generate a random core
					var consumable_options = ds_list_create();
					generate_item_rewards(consumable_options, global.master_item_list, 1, "core");
					gain_item(consumable_options[| 0]);
					ds_list_destroy(consumable_options);
					
					oEventManager.event_complete = 1;
					oEventManager.event_selected = true;
					
				} else {
					throw_error("No free slots", "Make space by destroying an item (right click)");
				}
			},
			result: "Result"
		}
		event_trunk_opt_3 = {
			title: "A tonic you were saving for a special day",
			description: "Gain a random potion.",
			effect: function(_context) {
				if (get_first_free_item_slot() != -1) {
					
					// Generate a random potion
					var consumable_options = ds_list_create();
					generate_item_rewards(consumable_options, global.master_item_list, 1, "consumable");
					gain_item(consumable_options[| 0]);
					ds_list_destroy(consumable_options);
					
					oEventManager.event_complete = 2;
					oEventManager.event_selected = true;
					
				} else {
					throw_error("No free slots", "Make space by destroying an item (right click)");
				}
			},
			result: "Today is the day!"
		}
	ds_list_add(event_trunk.options, event_trunk_opt_1);
	ds_list_add(event_trunk.options, event_trunk_opt_2);
	ds_list_add(event_trunk.options, event_trunk_opt_3);
	ds_list_add(global.master_event_list, event_trunk);
	
	
	// --------------------------
	// EVENT
	// --------------------------
	
	event_plunder = {
		name: "Some old loot",
		description: "The crew dug some old loot up from a previous plunder.",
		options: ds_list_create(),
	}
		event_plunder_opt_1 = {
			title: "Stick your hand in and pull something out",
			description: "Gain a random keepsake, 50% chance to lose 5 health.",
			effect: function(_context) {
				// Generate a random keepsake
				var keepsake_options = ds_list_create();
				generate_keepsake_rewards(keepsake_options, global.rollable_keepsake_list, 1);
				gain_keepsake(keepsake_options[| 0], global.rollable_keepsake_list);
				ds_list_destroy(keepsake_options);
				
				var take_damage = irandom(1);
				
				if (take_damage) global.player_hp -= 5;
				
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
				
			},
			result: "Result"
		}
		event_plunder_opt_2 = {
			title: "Get the crew to find something for you",
			description: "Gain a random rare dice core",
			effect: function(_context) {
				if (get_first_free_item_slot() != -1) {
					
					// Generate a random core
					show_debug_message("generating a core");
					var consumable_options = ds_list_create();
					generate_item_rewards(consumable_options, global.master_item_list, 1, "core", "rare");
					gain_item(consumable_options[| 0]);
					ds_list_destroy(consumable_options);
					
					oEventManager.event_complete = 1;
					oEventManager.event_selected = true;
					
				} else {
					throw_error("No free slots", "Make space by destroying an item (right click)");
				}
			},
			result: "Result"
		}
	ds_list_add(event_plunder.options, event_plunder_opt_1);
	ds_list_add(event_plunder.options, event_plunder_opt_2);
	ds_list_add(global.master_event_list, event_plunder);
	
	
	// --------------------------
	// EVENT
	// --------------------------
	
	event_gunner = {
		name: "Spare Ammunition",
		description: "The gunner found some spare ammunition lying around, and is offering it to you before selling the rest. Which will you take?",
		options: ds_list_create(),
	}
		event_gunner_opt_1 = {
			title: "Roundshot",
			description: "Choose a dice to gain +2 max roll.",
			effect: function(_context) {
				oRunManager.dice_selection = 1;
				oRunManager.dice_selection_message = "Choose a dice to gain +2 max roll";
				oRunManager.dice_selection_event = function(_die) {
					_die.dice_value += 2;
					
					particle_emit(115, 1000, "rise", get_dice_color(_die.action_type), 30);
				}
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
		event_gunner_opt_2 = {
			title: "Chainshot",
			description: "Choose a dice to gain +1 min roll.",
			effect: function(_context) {
				oRunManager.dice_selection = 1;
				oRunManager.dice_selection_message = "Choose a dice to gain +1 min roll";
				oRunManager.dice_selection_event = function(_die) {
					_die.min_roll_bonus += 1;
					
					particle_emit(115, 1000, "rise", get_dice_color(_die.action_type), 30);
				}
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
		event_gunner_opt_3 = {
			title: "Grapeshot",
			description: "Choose a dice to gain a random core.",
			effect: function(_context) {
				oRunManager.dice_selection = 1;
				oRunManager.dice_selection_message = "Choose a dice to gain a random core";
				oRunManager.dice_selection_event = function(_die) {
					_die.distribution = get_random_distribution();
					
					particle_emit(115, 1000, "rise", get_dice_color(_die.action_type), 30);
				}
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
	ds_list_add(event_gunner.options, event_gunner_opt_1);
	ds_list_add(event_gunner.options, event_gunner_opt_2);
	ds_list_add(event_gunner.options, event_gunner_opt_3);
	ds_list_add(global.master_event_list, event_gunner);
	
	
	// --------------------------
	// EVENT
	// --------------------------
	
	event_albatross = {
		name: "A bird flies aboard",
		description: "An albatross flies aboard your ship, there is seemingly no land around for hundreds of miles. It has something hanging from its neck.",
		options: ds_list_create(),
	}
		event_albatross_opt_1 = {
			title: "Offer it some food",
			description: "If you have a shop relic, heal to full and gain 7 max health.",
			effect: function(_context) {
				var player_has_shop_keepsake = false;
				
				for (var i = 0; i < ds_list_size(oRunManager.keepsakes); i++) {
					var keepsake = oRunManager.keepsakes[| i];
					if (keepsake._id == "lime_juice")
					|| (keepsake._id == "salted_pork")
					|| (keepsake._id == "pickled_cucumber")
					|| (keepsake._id == "toolbelt")
					|| (keepsake._id == "rum")
					|| (keepsake._id == "rations")
					|| (keepsake._id == "water_barrel") {
						player_has_shop_keepsake = true;
					}
				}
				
				// Example of conditional event
				if (player_has_shop_keepsake) {
					oEventManager.event_complete = 0;
					oEventManager.event_selected = true;
				} else {
					throw_error("No shop relic found", "You can't take this option without a shop relic");
				}
			},
			result: "Result"
		}
		event_albatross_opt_2 = {
			title: "Take the object hanging around its neck",
			description: "Gain a random keepsake and lose 7 alignment.",
			effect: function(_context) {
				// Generate a random keepsake
				var keepsake_options = ds_list_create();
				generate_keepsake_rewards(keepsake_options, global.rollable_keepsake_list, 1);
				gain_keepsake(keepsake_options[| 0], global.rollable_keepsake_list);
				ds_list_destroy(keepsake_options);
				
				global.player_alignment -= 7;
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
		event_albatross_opt_3 = {
			title: "Offer your blessings to the Albatross",
			description: "Gain 5 alignment and 5 luck.",
			effect: function(_context) {
				global.player_alignment += 5;
				global.player_luck += 5;
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
	ds_list_add(event_albatross.options, event_albatross_opt_1);
	ds_list_add(event_albatross.options, event_albatross_opt_2);
	ds_list_add(event_albatross.options, event_albatross_opt_3);
	ds_list_add(global.master_event_list, event_albatross);
	
	
	// --------------------------
	// EVENT
	// --------------------------
	
	event_wishing_well = {
		name: "The Wishing Well",
		description: "Your crew stops at a small island to gather resources and rest. Progress halts for a day or two as they find something hidden in a dark cave. It lights up the far end of a cavern. As you approach, you realise it's a wishing well.",
		options: ds_list_create(),
	}
		event_wishing_well_opt_1 = {
			title: "Reach into the water and steal a penny",
			description: "Gain a random coin and lose 4 alignment.",
			effect: function(_context) {
				// Generate a random dice
				var dice_options = ds_list_create();
				generate_dice_rewards(dice_options, global.master_dice_list, 1, "", "coin");
				
				var die_struct = dice_options[| 0];
				
				var die_inst = instance_create_layer(display_get_gui_width()/2, display_get_gui_height() + 100, "Instances", oDice);
				die_inst.struct = die_struct;
			    die_inst.action_type = die_struct.action_type;
			    die_inst.dice_amount = die_struct.dice_amount;
			    die_inst.dice_value  = die_struct.dice_value;
				die_inst.possible_type = die_struct.possible_type;
				die_inst.can_discard = true;

				var target = generate_valid_targets(1, 100) [0];
				die_inst.target_x = target[0];
				die_inst.target_y = target[1];
				
				ds_list_destroy(dice_options);
				
				global.player_alignment -= 4;
					
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
		event_wishing_well_opt_2 = {
			title: "Make a wish",
			description: "Remove a coin from your bag and gain improved luck for the run.",
			effect: function(_context) {
				// initialize variables
				var player_has_coin = false;
				
				// discover if the player has a coin
				for (var i = 0; i < ds_list_size(global.dice_bag); i++) {
					var dice = global.dice_bag[| i];
					if (dice.dice_value == 2) {
						player_has_coin = true;
						break;
					}
				}
				
				// if the player has a coin, delete it and give them permanent luck, otherwise throw an error
				if (player_has_coin) {
					oRunManager.dice_selection = 1;
					oRunManager.dice_selection_filter = "coin";
					oRunManager.dice_selection_message = "Choose a coin to toss into the well";
					oRunManager.dice_selection_event = function(_die) {
						var die_index = ds_list_find_index(global.dice_bag, _die);
						ds_list_delete(global.dice_bag, die_index);
						
						global.player_luck += 10;
						
						particle_emit(115, 1000, "burst", c_red, 30);
					}
					
					oEventManager.event_complete = 1;
					oEventManager.event_selected = true;
				} else {
					throw_error("No coins found in bag", "You cannot take this option without at least 1 coin in your bag");
				}
			},
			result: "Result"
		}
		event_wishing_well_opt_3 = {
			title: "Leave it",
			description: "Do nothing and leave.",
			effect: function(_context) {
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "You leave."
		}
	ds_list_add(event_wishing_well.options, event_wishing_well_opt_1);
	ds_list_add(event_wishing_well.options, event_wishing_well_opt_2);
	ds_list_add(event_wishing_well.options, event_wishing_well_opt_3);
	ds_list_add(global.master_event_list, event_wishing_well);
	
	
	// --------------------------
	// EVENT
	// --------------------------
	
	event_mermaid = {
		name: "An island dream",
		description: "In a dream you find yourself on an island. You take a stroll along a rocky outcropping before being pulled below the surface of the water. A mermaid meets your face as you exhale bubbles that cover the view of her for a moment. As the sea stills her beauty captures you. What will you do?",
		options: ds_list_create(),
	}
		event_mermaid_opt_1 = {
			title: "Offer her a treasure and leave",
			description: "Choose a die from your bag to remove.",
			effect: function(_context) {
				oRunManager.dice_selection = 1;
				oRunManager.dice_selection_message = "Choose a die to remove";
				oRunManager.dice_selection_event = function(_die) {
					var die_index = ds_list_find_index(global.dice_bag, _die);
						
					particle_emit(115, 1000, "burst", get_dice_color(global.dice_bag[| die_index].action_type), 30);
					ds_list_delete(global.dice_bag, die_index);
				}
					
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
		event_mermaid_opt_2 = {
			title: "Listen to her song",
			description: "Heal 40% of your max health.",
			effect: function(_context) {
				if (global.player_hp < global.player_max_hp) {
					var amount = global.player_max_hp * 0.4;
					process_action("player", 0, amount, 0, "player", undefined, "HEAL");
					
					trigger_keepsake_visual();
				}
				
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
		event_mermaid_opt_3 = {
			title: "Venture into the depths with her",
			description: "Lose 5 max health and gain a random rare dice",
			effect: function(_context) {
				// Generate a random dice
				var dice_options = ds_list_create();
				generate_dice_rewards(dice_options, global.master_dice_list, 1, "rare", "");
				
				var die_struct = dice_options[| 0];
				
				var die_inst = instance_create_layer(display_get_gui_width()/2, display_get_gui_height() + 100, "Instances", oDice);
				die_inst.struct = die_struct;
			    die_inst.action_type = die_struct.action_type;
			    die_inst.dice_amount = die_struct.dice_amount;
			    die_inst.dice_value  = die_struct.dice_value;
				die_inst.possible_type = die_struct.possible_type;
				die_inst.can_discard = true;

				var target = generate_valid_targets(1, 100) [0];
				die_inst.target_x = target[0];
				die_inst.target_y = target[1];
				
				ds_list_destroy(dice_options);
				
				global.player_max_hp -= 5;
				if (global.player_hp > global.player_max_hp) global.player_hp = global.player_max_hp;
				
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
	ds_list_add(event_mermaid.options, event_mermaid_opt_1);
	ds_list_add(event_mermaid.options, event_mermaid_opt_2);
	ds_list_add(event_mermaid.options, event_mermaid_opt_3);
	ds_list_add(global.master_event_list, event_mermaid);
	
	
	// --------------------------
	// EVENT
	// --------------------------
	
	event_dutchman = {
		name: "The Flying Dutchman",
		description: "A fog lasts for days on your journey. In the distance, echoes of drowned sailors and crashing waves, despite a mostly calm sea. In the dead of night after the 5th day, the crows nest watch shouts down in terror - The Flying Dutchman breaks through the fog.",
		options: ds_list_create(),
	}
		event_dutchman_opt_1 = {
			title: "Let the Dutchman sail through you",
			description: "For the rest of this voyage: Guarantee item rewards every combat but lose the ability to port at shops.",
			effect: function(_context) {
				oRunManager.dutchman_taken = true;
				
				// Remove any upcoming shop nodes
				with (oWorldManager) {
					for (var p = 0; p < ds_list_size(chosen_pages); p++) {
						var page = chosen_pages[| p];
						for (var n = 0; n < page.num_nodes; n++) {
							var node = page.nodes[| n];
							if (node.type == NODE_TYPE.SHOP && !node.cleared) {
								chosen_pages[| p].nodes[| n] = clone_node_static(node_combat);
							}
						}
					}
				}
				
				for (var i = 300; i < room_width - 300; i++) {
					particle_emit(i, display_get_gui_height() - irandom(30), "rise", make_color_rgb(70, 180, 110), 1);
				}
				
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
		event_dutchman_opt_2 = {
			title: "Steer to avoid the Dutchman",
			description: "On success gain a random keepsake, on a failure lose a random die and 5 health.",
			effect: function(_context) {
				var success = irandom_range(1, 100);
				
				if (success <= global.player_luck) {
					// Generate a random keepsake
					var keepsake_options = ds_list_create();
					generate_keepsake_rewards(keepsake_options, global.rollable_keepsake_list, 1);
					gain_keepsake(keepsake_options[| 0], global.rollable_keepsake_list);
					ds_list_destroy(keepsake_options);
					
				} else {
					var rand_die_index = irandom(ds_list_size(global.dice_bag) - 1);
					
					particle_emit(115, 1000, "burst", get_dice_color(global.dice_bag[| rand_die_index].action_type), 30);
					
					ds_list_delete(global.dice_bag, rand_die_index);
					
					global.player_hp -= 5;
				}
				
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
	ds_list_add(event_dutchman.options, event_dutchman_opt_1);
	ds_list_add(event_dutchman.options, event_dutchman_opt_2);
	ds_list_add(global.master_event_list, event_dutchman);
	
	
	// --------------------------
	// EVENT
	// --------------------------
	
	event_rough_tides = {
		name: "Rough tides",
		description: "Rough tides rise up and batter the hull of your ship. Your men sail the ship through and you come out the other side mostly unscathed. Later when you return to your desk, you find:",
		options: ds_list_create(),
	}
		event_rough_tides_opt_1 = {
			title: "Your bag has spilled out over the desk",
			description: "Choose a die to remove from your bag.",
			effect: function(_context) {
				oRunManager.dice_selection = 1;
				oRunManager.dice_selection_message = "Choose a die to remove";
				oRunManager.dice_selection_event = function(_die) {
					var die_index = ds_list_find_index(global.dice_bag, _die);
						
					particle_emit(115, 1000, "burst", get_dice_color(global.dice_bag[| die_index].action_type), 30);
					
					ds_list_delete(global.dice_bag, die_index);
				}
					
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
		event_rough_tides_opt_2 = {
			title: "Ink has spilled over your parchment",
			description: "Choose a die to transform.",
			effect: function(_context) {
				oRunManager.dice_selection = 1;
				oRunManager.dice_selection_message = "Choose a die to transform";
				oRunManager.dice_selection_event = function(_die) {
					var die_index = ds_list_find_index(global.dice_bag, _die);
						
					particle_emit(115, 1000, "burst", get_dice_color(_die.action_type), 30);
					
					// Generate a random dice
					var dice_options = ds_list_create();
					generate_dice_rewards(dice_options, global.master_dice_list, 1, "", "");
				
					var die_struct = dice_options[| 0];
				
					ds_list_destroy(dice_options);
					
					global.dice_bag[| die_index] = clone_die(die_struct, "");
				}
					
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
		event_rough_tides_opt_3 = {
			title: "Something on the floor",
			description: "Choose a die to duplicate.",
			effect: function(_context) {
				oRunManager.dice_selection = 1;
				oRunManager.dice_selection_message = "Choose a die to duplicate";
				oRunManager.dice_selection_event = function(_die) {
						
					particle_emit(115, 1000, "burst", get_dice_color(_die.action_type), 30);
					
					ds_list_add(global.dice_bag, clone_die(_die, ""));
				}
					
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
	ds_list_add(event_rough_tides.options, event_rough_tides_opt_1);
	ds_list_add(event_rough_tides.options, event_rough_tides_opt_2);
	ds_list_add(event_rough_tides.options, event_rough_tides_opt_3);
	ds_list_add(global.master_event_list, event_rough_tides);
	
	
	// --------------------------
	// EVENT
	// --------------------------
	
	event_constellation = {
		name: "The constellation",
		description: "The seas have calmed and the skies have cleared. As the sun sets and night stills the sky alights with a million stars, which constellation will you follow?",
		options: ds_list_create(),
	}
		event_constellation_opt_1 = {
			title: "The Plough",
			description: "Reset your alignment and gain 10 luck.",
			effect: function(_context) {
				global.player_alignment = 50;
				global.player_luck += 10;
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
				
			},
			result: "Result"
		}
		event_constellation_opt_2 = {
			title: "Cassiopeia",
			description: "Lose 12 alignment and gain 3 luck.",
			effect: function(_context) {
				global.player_alignment -= 12;
				global.player_luck += 3;
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
		event_constellation_opt_3 = {
			title: "Lyra",
			description: "Gain 12 alignment and 3 luck.",
			effect: function(_context) {
				global.player_alignment += 12;
				global.player_luck += 3;
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
	ds_list_add(event_constellation.options, event_constellation_opt_1);
	ds_list_add(event_constellation.options, event_constellation_opt_2);
	ds_list_add(event_constellation.options, event_constellation_opt_3);
	ds_list_add(global.master_event_list, event_constellation);
	
	
	// --------------------------
	// EVENT
	// --------------------------
	
	event_shipwright = {
		name: "A precious ingot",
		description: "Late one evening the shipwright comes to you with a precious ingot he found buried within the latest hoard. 'What shall I craft with it sir?'",
		options: ds_list_create(),
	}
		event_shipwright_opt_1 = {
			title: "Fashion a new tool",
			description: "Gain a random tool for the workbench.",
			effect: function(_context) {
				if (ds_list_size(global.master_tool_list) > 0) {
					// Generate a random tool
					var tool_options = ds_list_create();
					generate_tool_rewards(tool_options, global.master_tool_list, 1);
					ds_list_add(oRunManager.tools, tool_options[| 0]);
					ds_list_add(oRunManager.tools_scale, 0.5);
					oRunManager.show_tools = true;
					ds_list_destroy(tool_options);
					
					oEventManager.event_complete = 0;
					oEventManager.event_selected = true;
				} else {
					throw_error("You already have every tool", "There are no more tools available to acquire"); 
				}
			},
			result: "Result"
		}
		event_shipwright_opt_2 = {
			title: "Enhance your buckle",
			description: "Gain the toolbelt keepsake.",
			hover: function() {
				queue_tooltip(mouse_x, mouse_y, oRunManager.ks_toolbelt.name, oRunManager.ks_toolbelt.desc, sKeepsake, oRunManager.ks_toolbelt.sub_image);
			},
			effect: function(_context) {
				var has_toolbelt = false;
				
				for (var i = 0; i < ds_list_size(oRunManager.keepsakes); i++) {
					var keepsake = oRunManager.keepsakes[| i];
					
					if (keepsake._id == "toolbelt") {
						has_toolbelt = true;
						break;
					}
				}
				
				if (has_toolbelt) {
						throw_error("You already have the toolbelt", "You cannot have duplicate keepsakes");
				} else {
					gain_keepsake(get_keepsake_by_id("toolbelt"), global.rollable_keepsake_list);
				
					oEventManager.event_complete = 1;
					oEventManager.event_selected = true;
				}
			},
			result: "Result"
		}
		event_shipwright_opt_3 = {
			title: "Leave it",
			description: "Save the resources for the men.",
			effect: function(_context) {
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
	ds_list_add(event_shipwright.options, event_shipwright_opt_1);
	ds_list_add(event_shipwright.options, event_shipwright_opt_2);
	ds_list_add(event_shipwright.options, event_shipwright_opt_3);
	ds_list_add(global.master_event_list, event_shipwright);
	
	
	// --------------------------
	// EVENT
	// --------------------------
	
	event_sirens = {
		name: "The Siren's Call",
		description: "The call of distant Sirens can be heard through the early morning mist. Your sailors are already beginning to falter. What will you do?",
		options: ds_list_create(),
	}
	
	function fail_sirens() {
		var has_rigging = false;
				
		for (var i = 0; i < ds_list_size(oRunManager.keepsakes); i++) {
			var keepsake = oRunManager.keepsakes[| i];
					
			if (keepsake._id == "protective_rigging") {
				has_rigging = true;
				break;
			}
		}
				
		var hp_to_lose = has_rigging ? 0 : 5;
				
		if (global.player_hp > hp_to_lose) {
			global.player_hp -= hp_to_lose;
					
			// change this so that we go to the shop on pressing exit
			oEventManager.alternate_exit = rmShop;
		} else {
			throw_error("This would kill you", "At least try first!.");
		}
	}
		event_sirens_opt_1 = {
			title: "Sing a song of your own",
			description: "Higher chance of success the higher your alignment. If successful, upgrade all of your intel die.",
			effect: function(_context) {
				var random_num = irandom_range(1, 100);
				if (random_num <= global.player_alignment) {
					var intel_list = ds_list_create();
					
					for (var d = 0; d < ds_list_size(global.dice_bag); d++) {
						var die = global.dice_bag[| d];
					
						// only intel dice, avoid coins
						if (die.action_type == "INTEL") && (die.dice_value != 2) {
							ds_list_add(intel_list, die);
						}
					}
				
					// Fail safe in case we have no heal or block die
					if (ds_list_size(intel_list) == 0) {
					    ds_list_destroy(intel_list);
					    oEventManager.event_complete = 0;
					    oEventManager.event_selected = true;
					    return;
					}
				
					for (var i = 0; i < ds_list_size(intel_list); i++) {
						var intel_die = intel_list[| i];
						
						intel_die.dice_value += 2;
					}
				
					particle_emit(115, 1000, "rise", global.color_intel);
				
					ds_list_destroy(intel_list);
				} else {
					fail_sirens();
				}
				
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
		event_sirens_opt_2 = {
			title: "Block your ears",
			description: "Higher chance of success the more block dice you have. If successful, upgrade all of your block die.",
			effect: function(_context) {
				var random_num = irandom_range(1, 100);
				var block_num = 0;
				
				for (var d = 0; d < ds_list_size(global.dice_bag); d++) {
					var die = global.dice_bag[| d];
					
					// only intel dice, avoid coins
					if (die.action_type == "BLOCK") {
						block_num++;
					}
				}
				
				if (random_num <= 35 + (block_num * 5)) {
					var block_list = ds_list_create();
					
					for (var d = 0; d < ds_list_size(global.dice_bag); d++) {
						var die = global.dice_bag[| d];
					
						// only intel dice, avoid coins
						if (die.action_type == "BLK") && (die.dice_value != 2) {
							ds_list_add(block_list, die);
						}
					}
				
					// Fail safe in case we have no heal or block die
					if (ds_list_size(block_list) == 0) {
					    ds_list_destroy(block_list);
					    oEventManager.event_complete = 0;
					    oEventManager.event_selected = true;
					    return;
					}
				
					for (var i = 0; i < ds_list_size(block_list); i++) {
						var block_die = block_list[| i];
						
						block_die.dice_value += 2;
					}
				
					particle_emit(115, 1000, "rise", global.color_block);
				
					ds_list_destroy(block_list);
				} else {
					fail_sirens();
				}
				
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
		event_sirens_opt_3 = {
			title: "Succumb to the song",
			description: "Crash on the rocks, lose 5 health (0 if you have protective rigging) and go straight to the shop. On failure of other events this option will be auto-selected.",
			effect: function(_context) {
				fail_sirens();
				
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "Result"
		}
	ds_list_add(event_sirens.options, event_sirens_opt_1);
	ds_list_add(event_sirens.options, event_sirens_opt_2);
	ds_list_add(event_sirens.options, event_sirens_opt_3);
	ds_list_add(global.master_event_list, event_sirens);
}

function generate_event() {
	var event = undefined;
	var rand;
	
	if (ds_list_size(global.master_event_list) > 0) {
		rand = irandom(ds_list_size(global.master_event_list) - 1);
	} else {
		define_events();
		rand = irandom(ds_list_size(global.master_event_list) - 1);
	}
	
	event = global.master_event_list[| rand];

	chosen_event = event;
	ds_list_delete(global.master_event_list, rand);
}