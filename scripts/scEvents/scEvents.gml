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
			description: "Lose 10 gold. Gain 5 alignment and the Deckhand's Token keepsake.",
			hover: function() {
				queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), oRunManager.ks_deckhands_token.name, oRunManager.ks_deckhands_token.desc, sKeepsake, oRunManager.ks_deckhands_token.sub_image);
			},
			effect: function(_context) {
				if (oRunManager.credits >= 10) {
					gain_alignment(5);
					oRunManager.credits -= 10;
					gain_keepsake(oRunManager.ks_deckhands_token);
					oEventManager.event_complete = 0;
					oEventManager.event_selected = true;
				} else {
					throw_error("Not enough gold", "You need 10 gold.");
				}
			},
			result: "Pirate Pete has joined your crew."
		}
		event_prisoner_opt_2 = {
			title: "Make him walk the plank",
			description: "Lose 7 alignment and remove a die from your bag.",
			effect: function(_context) {
				gain_alignment(-7);
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
			description: "Gain a random item and 30 gold.",
			effect: function(_context) {
				ev_gold(30);
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
			description: "Gain 5 alignment, lose 7 health, upgrade a random block or heal die.",
			effect: function(_context) {
				global.player_hp -= 7;
				gain_alignment(5);
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
				die_size_changed(rand_die);
				
				particle_emit( 115, 1000, "rise", rand_die.color);
				spawn_floating_number("bag", 0, rand_die.name + " upgraded", rand_die.color, 0, -1, 0);
				
				ds_list_destroy(heal_block_list);
				
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "You share your stores with the crew."
		}
		event_storm_opt_2 = {
			title: "Cut rations for everyone",
			description: "Lose 4 alignment. Gain the Starver's Efficiency keepsake.",
			hover: function() {
				queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), oRunManager.ks_starvers_efficiency.name, oRunManager.ks_starvers_efficiency.desc, sKeepsake, oRunManager.ks_starvers_efficiency.sub_image);
			},
			effect: function(_context) {
				gain_alignment(-4);
				gain_keepsake(oRunManager.ks_starvers_efficiency);
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "A hard decision."
		}
		event_storm_opt_3 = {
			title: "Let the crew solve it for themselves",
			description: "Next fight, gain 1 extra play each turn.",
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
			description: "Upgrade a die of your choice.",
			effect: function(_context) {
				// (Jared, 2026-11-24: one of your choosing, not 2 random attack dice)
				ev_pick(1, "Choose a die to upgrade", "upgrade", function(_die) { ev_upgrade_die(_die, 1); });
				ev_done(1);
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
			description: "Lose 10 gold. Gain the Small Sail keepsake.",
			hover: function() {
				queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), oRunManager.ks_small_sail.name, oRunManager.ks_small_sail.desc, sKeepsake, oRunManager.ks_small_sail.sub_image);
			},
			effect: function(_context) {
				if (oRunManager.credits >= 10) {
					oRunManager.credits -= 10;
					gain_keepsake(oRunManager.ks_small_sail);
					oEventManager.event_complete = 0;
					oEventManager.event_selected = true;
				} else {
					throw_error("Not enough gold", "You need 10 gold.");
				}
			},
			result: "Sail replaced and you are on your way."
		}
		event_sails_opt_2 = {
			title: "Repair the sail",
			description: "Lose a random item. Gain the Rope of Repair keepsake.",
			hover: function() {
				queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), oRunManager.ks_rope_of_repair.name, oRunManager.ks_rope_of_repair.desc, sKeepsake, oRunManager.ks_rope_of_repair.sub_image);
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
					
					oRunManager.items[item_pool[rand]] = undefined; // rand indexes the pool of filled slots, not the item slots
					gain_keepsake(oRunManager.ks_rope_of_repair);
					oEventManager.event_complete = 1;
					oEventManager.event_selected = true;
				} else {
					throw_error("No items", "You need an item to give up.");
				}
			},
			result: "Sail repaired, it should hold out."
		}
		event_sails_opt_3 = {
			title: "Continue with the tear",
			description: "Lose 5 max health.",
			effect: function(_context) {
				global.player_max_hp -= 5;
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
		description: "Your latest plunder has been sold and shared amongst the crew, everyone has their fair share.",
		options: ds_list_create(),
	}
		event_bounty_opt_1 = {
			title: "Demand a bigger share",
			description: "Gain 120 gold and lose 7 alignment.",
			effect: function(_context) {
				gain_coins(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), 120);
				gain_alignment(-7);
				
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "The crew fork over more of the bounty, morale seems lower."
		}
		event_bounty_opt_2 = {
			title: "Take your fair share",
			description: "Gain 80 gold.",
			effect: function(_context) {
				gain_coins(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), 80);
				
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "You take your share of the bounty."
		}
		event_bounty_opt_3 = {
			title: "Take a smaller share to boost morale",
			description: "Gain 40 gold and 7 alignment.",
			effect: function(_context) {
				gain_coins(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), 40);
				gain_alignment(7);
				
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
			description: "Gain a random die.",
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
			result: "Inside, wrapped in an old letter, a die you'd forgotten about. It goes in the bag."
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
					throw_error("Item slots full", "Right click an item to drop it.");
				}
			},
			result: "An old family heirloom, still humming with power. A new core for the workbench."
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
					throw_error("Item slots full", "Right click an item to drop it.");
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
			description: "Gain a random keepsake. 50% chance to lose 8 health.",
			effect: function(_context) {
				// Generate a random keepsake
				var keepsake_options = ds_list_create();
				generate_keepsake_rewards(keepsake_options, global.rollable_keepsake_list, 1);
				gain_keepsake(keepsake_options[| 0], global.rollable_keepsake_list);
				ds_list_destroy(keepsake_options);
				
				var take_damage = irandom(1);
				
				if (take_damage) global.player_hp -= 8;
				
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
				
			},
			result: "You rummage through the pile and pull out something that catches the light."
		}
		event_plunder_opt_2 = {
			title: "Get the crew to find something for you",
			description: "Gain a random rare core.",
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
					throw_error("Item slots full", "Right click an item to drop it.");
				}
			},
			result: "The crew digs through the hoard and comes back with a rare core."
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
			description: "Choose a die to gain +2 max roll.",
			effect: function(_context) {
				oRunManager.dice_selection = 1;
				oRunManager.dice_selection_message = "Choose a die to gain +2 max roll";
				oRunManager.dice_selection_event = function(_die) {
					_die.dice_value += 2;
					die_size_changed(_die);
					
					particle_emit(115, 1000, "rise", get_dice_color(_die.possible_type), 30);
					spawn_floating_number("bag", 0, _die.name + " +2 max roll", _die.color, 0, -1, 0);
				}
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "The shipwright fits the roundshot. The die hits harder now."
		}
		event_gunner_opt_2 = {
			title: "Chainshot",
			description: "Choose a die to gain +1 min roll.",
			effect: function(_context) {
				oRunManager.dice_selection = 1;
				oRunManager.dice_selection_message = "Choose a die to gain +1 min roll";
				oRunManager.dice_selection_filter = "min_room";
				oRunManager.dice_selection_event = function(_die) {
					_die.min_roll_bonus += 1;

					particle_emit(115, 1000, "rise", get_dice_color(_die.possible_type), 30);
					spawn_floating_number("bag", 0, _die.name + " +1 min roll", _die.color, 0, -1, 0);
				}
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "The chainshot steadies the die. Its rolls won't fall so low."
		}
		event_gunner_opt_3 = {
			title: "Grapeshot",
			description: "Choose a die to gain a random core.",
			effect: function(_context) {
				oRunManager.dice_selection = 1;
				oRunManager.dice_selection_message = "Choose a die to gain a random core";
				oRunManager.dice_selection_event = function(_die) {
					_die.distribution = get_random_distribution();
					
					particle_emit(115, 1000, "rise", get_dice_color(_die.possible_type), 30);
					spawn_floating_number("bag", 0, _die.name + " " + string(_die.distribution) + " core applied", _die.color, 0, -1, 0);
				}
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "The grapeshot scatters, and settles into the die as a new core."
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
			description: "With a shop keepsake, gain 7 max health and heal to full.",
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
					global.player_max_hp += 7;
					var amount = global.player_max_hp - global.player_hp;
					process_action("player", 0, amount, 0, "player", undefined, "HEAL");
					
					oEventManager.event_complete = 0;
					oEventManager.event_selected = true;
				} else {
					throw_error("No shop keepsake", "You need a keepsake from a shop.");
				}
			},
			result: "The albatross eats from your hand. You feel stronger for the kindness."
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
				
				gain_alignment(-7); // matches the option text
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "You cut the cord and take the trinket. The bird screams as it leaves."
		}
		event_albatross_opt_3 = {
			title: "Offer your blessings to the Albatross",
			description: "Gain 5 alignment and 5 luck.",
			effect: function(_context) {
				gain_alignment(5);
				global.player_luck += 5;
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "The albatross bows its head and takes off over the waves. Fortune follows it."
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
				
				gain_alignment(-4);
					
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "You pocket the penny. The water ripples, as if something below noticed."
		}
		event_wishing_well_opt_2 = {
			title: "Make a wish",
			description: "Remove a coin from your bag. Gain 10 luck.",
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
						spawn_floating_number("bag", 0, _die.name + " tossed", _die.color, 0, -1, 0);
					}
					
					oEventManager.event_complete = 1;
					oEventManager.event_selected = true;
				} else {
					throw_error("No coins", "You need a coin in your bag.");
				}
			},
			result: "The coin drops into the dark. You feel luck turn in your favour."
		}
		event_wishing_well_opt_3 = {
			title: "Leave it",
			description: "Nothing happens.",
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
		description: "In a dream you find yourself on an island. You take a stroll along a rocky outcropping before being pulled below the surface of the water. A mermaid meets your face as you exhale bubbles that cover the view of her for a moment. As the sea stills her beauty captures you.",
		options: ds_list_create(),
	}
		event_mermaid_opt_1 = {
			title: "Offer her a treasure and leave",
			description: "Remove a die from your bag.",
			effect: function(_context) {
				oRunManager.dice_selection = 1;
				oRunManager.dice_selection_message = "Choose a die to remove";
				oRunManager.dice_selection_event = function(_die) {
					var die_index = ds_list_find_index(global.dice_bag, _die);
						
					particle_emit(115, 1000, "burst", get_dice_color(global.dice_bag[| die_index].possible_type), 30);
					spawn_floating_number("bag", 0, _die.name + " removed", _die.color, 0, -1, 0);
					
					ds_list_delete(global.dice_bag, die_index);
				}
					
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "She takes your offering and slips back beneath the waves."
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
			result: "Her song washes over you, and your wounds close as you listen."
		}
		event_mermaid_opt_3 = {
			title: "Venture into the depths with her",
			description: "Lose 5 max health. Gain a random rare die.",
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
			result: "You follow her down into the dark, and come back up changed, with something rare in hand."
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
			description: "For the rest of the voyage, every fight gives an item, but you can't visit shops.",
			effect: function(_context) {
				oRunManager.dutchman_taken = true;
				
				// Remove any upcoming shop nodes
				with (oWorldManager) {
					for (var p = 0; p < ds_list_size(chosen_pages); p++) {
						var page = chosen_pages[| p];
						for (var n = 0; n < page.num_nodes; n++) {
							var node = page.nodes[| n];
							if (node.type == NODE_TYPE.SHOP && !node.cleared) {
								// Convert the node in place, all_nodes and next_node hold references to it
								node.type = node_combat.type;
								node.name = node_combat.name;
								node.subimg = node_combat.subimg;
								node.text = node_combat.text;
								node.linked_room = node_combat.linked_room;
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
			result: "The ghost ship sails straight through you. The crew won't talk about it, but the sea seems kinder now."
		}
		event_dutchman_opt_2 = {
			title: "Steer to avoid the Dutchman",
			description: "Luck decides. Success: gain a random keepsake. Failure: lose a random die and 5 health.",
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
					
					particle_emit(115, 1000, "burst", get_dice_color(global.dice_bag[| rand_die_index].possible_type), 30);
					spawn_floating_number("bag", 0, global.dice_bag[| rand_die_index].name + " removed", global.dice_bag[| rand_die_index].color, 0, -1, 0);
					
					ds_list_delete(global.dice_bag, rand_die_index);
					
					global.player_hp -= 5;
				}
				
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "You heave the wheel hard over as the Dutchman looms out of the fog."
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
			description: "Remove a die from your bag.",
			effect: function(_context) {
				oRunManager.dice_selection = 1;
				oRunManager.dice_selection_message = "Choose a die to remove";
				oRunManager.dice_selection_event = function(_die) {
					var die_index = ds_list_find_index(global.dice_bag, _die);
						
					particle_emit(115, 1000, "burst", get_dice_color(global.dice_bag[| die_index].possible_type), 30);
					spawn_floating_number("bag", 0, global.dice_bag[| die_index].name + " removed", global.dice_bag[| die_index].color, 0, -1, 0);
					
					ds_list_delete(global.dice_bag, die_index);
				}
					
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "You gather up what you can. One die rolls away for good."
		}
		event_rough_tides_opt_2 = {
			title: "Ink has spilled over your parchment",
			description: "Turn a die into a random one.",
			effect: function(_context) {
				oRunManager.dice_selection = 1;
				oRunManager.dice_selection_message = "Choose a die to transform";
				oRunManager.dice_selection_event = function(_die) {
					var die_index = ds_list_find_index(global.dice_bag, _die);
						
					particle_emit(115, 1000, "burst", get_dice_color(_die.possible_type), 30);
					
					// Generate a random dice
					var dice_options = ds_list_create();
					generate_dice_rewards(dice_options, global.master_dice_list, 1, "", "");
				
					var die_struct = dice_options[| 0];
				
					ds_list_destroy(dice_options);
					
					global.dice_bag[| die_index] = clone_die(die_struct, "");

					spawn_floating_number("bag", 0, _die.name + "\nreplaced with\n" + die_struct.name, die_struct.color, 0, -1, 0);
				}
					
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "The ink dries into a new shape. The die is not what it was."
		}
		event_rough_tides_opt_3 = {
			title: "Something on the floor",
			description: "Copy a die.",
			effect: function(_context) {
				oRunManager.dice_selection = 1;
				oRunManager.dice_selection_message = "Choose a die to duplicate";
				oRunManager.dice_selection_event = function(_die) {
						
					particle_emit(115, 1000, "burst", get_dice_color(_die.possible_type), 30);
					spawn_floating_number("bag", 0, _die.name + " duplicated", _die.color, 0, -1, 0);
					
					ds_list_add(global.dice_bag, clone_die(_die, ""));
				}
					
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "Under the desk you find a twin of one of your dice."
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
			result: "You follow the Plough. Your old loyalties fall away and fortune smiles on you."
		}
		event_constellation_opt_2 = {
			title: "Cassiopeia",
			description: "Lose 12 alignment and gain 3 luck.",
			effect: function(_context) {
				gain_alignment(-12);
				global.player_luck += 3;
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "You follow Cassiopeia into darker waters. Luck comes, at a price."
		}
		event_constellation_opt_3 = {
			title: "Lyra",
			description: "Gain 12 alignment and 3 luck.",
			effect: function(_context) {
				gain_alignment(12);
				global.player_luck += 3;
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "You follow Lyra's light. The crew sleeps easy tonight."
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
			description: "Gain a random tool.",
			effect: function(_context) {
				if (ds_list_size(global.master_tool_list) > 0) {
					// Generate a random tool
					var tool_options = ds_list_create();
					generate_tool_rewards(tool_options, global.master_tool_list, 1);
					ds_list_add(oRunManager.tools, tool_options[| 0]);
					// take it out of the pool so it can't be offered again
					var _tool_index = ds_list_find_index(global.master_tool_list, tool_options[| 0]);
					if (_tool_index != -1) ds_list_delete(global.master_tool_list, _tool_index);
					ds_list_add(oRunManager.tools_scale, 0.5);
					oRunManager.show_tools = true;
					ds_list_destroy(tool_options);
					
					oEventManager.event_complete = 0;
					oEventManager.event_selected = true;
				} else {
					throw_error("No tools left", "You have every tool.");
				}
			},
			result: "The shipwright hammers the ingot into a new tool for the workbench."
		}
		event_shipwright_opt_2 = {
			title: "Enhance your buckle",
			description: "Gain the Toolbelt keepsake.",
			hover: function() {
				queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), oRunManager.ks_toolbelt.name, oRunManager.ks_toolbelt.desc, sKeepsake, oRunManager.ks_toolbelt.sub_image);
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
						throw_error("Already owned", "You already have the Toolbelt.");
				} else {
					gain_keepsake(get_keepsake_by_id("toolbelt"), global.rollable_keepsake_list);
				
					oEventManager.event_complete = 1;
					oEventManager.event_selected = true;
				}
			},
			result: "The shipwright works the ingot into your belt. Room for more supplies."
		}
		event_shipwright_opt_3 = {
			title: "Leave it",
			description: "Nothing happens.",
			effect: function(_context) {
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "You leave the ingot with the crew. They'll put it to good use."
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
		description: "The call of distant Sirens can be heard through the early morning mist. Your sailors are already beginning to falter.",
		options: ds_list_create(),
	}
	
		// How many dice each upgrades follows your compass (Jared, 2026-11-19): merciful for the song, ruthless for the
		// cannons. 1 each at neutral, then 2 / 0 at 75, 3 / 0 at 90 (sirens_upgrade_count). The option says what you'd get.
		event_sirens_opt_1 = {
			title: "Sing a song of your own",
			description: function() { return sirens_option_text("ink", sirens_upgrade_count(global.player_alignment - 50)); },
			effect: function(_context) {
				sirens_upgrade("INTEL", sirens_upgrade_count(global.player_alignment - 50), global.color_intel);
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "You sing back at the sirens with all you've got. The crew joins in, and the mist parts."
		}
		event_sirens_opt_2 = {
			title: "Fire the cannons",
			description: function() { return sirens_option_text("attack", sirens_upgrade_count(50 - global.player_alignment)); },
			effect: function(_context) {
				sirens_upgrade("ATK", sirens_upgrade_count(50 - global.player_alignment), global.color_attack);
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "You blast the rocks where they sit. The song breaks off into screams."
		}
		event_sirens_opt_3 = {
			title: "Succumb to the song",
			description: "Lose 5 health, or none with Protective Rigging. Go straight to the shop.",
			effect: function(_context) {
				fail_sirens();
				
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "You let the song pull you in. The ship grinds onto the rocks near a trading post."
		}
	ds_list_add(event_sirens.options, event_sirens_opt_1);
	ds_list_add(event_sirens.options, event_sirens_opt_2);
	ds_list_add(event_sirens.options, event_sirens_opt_3);
	ds_list_add(global.master_event_list, event_sirens);

	// --------------------------
	// EVENT (v0.2, F23)
	// --------------------------

	event_crate = {
		name: "A floating crate",
		description: "A crate bobs alongside the hull, lashed shut and stamped with a merchant's mark. The crew hook it aboard and look to you.",
		options: ds_list_create(),
	}
		event_crate_opt_1 = {
			title: "Pry it open",
			description: "Gain 60 gold.",
			effect: function(_context) {
				gain_coins(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), 60);
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "Coins spill across the deck. Someone back home is having a bad week."
		}
		event_crate_opt_2 = {
			title: "Break it up for planks",
			description: "Heal 20% of your max health.",
			effect: function(_context) {
				if (global.player_hp < global.player_max_hp) process_action("player", 0, ceil(global.player_max_hp * 0.2), 0, "player", undefined, "HEAL");
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "The crew patch the hull with it, and you rest easier for it."
		}
	ds_list_add(event_crate.options, event_crate_opt_1);
	ds_list_add(event_crate.options, event_crate_opt_2);
	ds_list_add(global.master_event_list, event_crate);

	event_tattooist = {
		name: "The tattooist",
		description: "In a quiet port a weathered tattooist offers to ink the crew. \"Every mark is a promise,\" she says, needle already in hand.",
		options: ds_list_create(),
	}
		event_tattooist_opt_1 = {
			title: "An anchor (40 gold)",
			description: "Lose 40 gold. Give a die +2 min roll.", // (Jared, 2026-11-24: +1 for 40 gold was worse than the gunner's free Chainshot)
			effect: function(_context) {
				if (oRunManager.credits < 40) {
					throw_error("Not enough gold", "You need 40 gold.");
					return;
				}
				oRunManager.credits -= 40;
				oRunManager.dice_selection = 1;
				oRunManager.dice_selection_message = "Choose a die to gain +2 min roll";
				oRunManager.dice_selection_filter = "min_room";
				oRunManager.dice_selection_event = function(_die) {
					// never past its highest roll: a d4 already at +2 only gains 1
					var _gain = min(2, _die.dice_value - 1 - _die.min_roll_bonus);
					_die.min_roll_bonus += _gain;
					particle_emit(115, 1000, "rise", get_dice_color(_die.possible_type), 30);
					spawn_floating_number("bag", 0, _die.name + " +" + string(_gain) + " min roll", _die.color, 0, -1, 0);
				}
				oEventManager.event_complete = 0;
				oEventManager.event_selected = true;
			},
			result: "The anchor sits heavy on your arm. That die won't roll so low again."
		}
		event_tattooist_opt_2 = {
			title: "A swallow (free)",
			description: "Gain 5 alignment and 3 luck.",
			effect: function(_context) {
				gain_alignment(5);
				global.player_luck += 3;
				oEventManager.event_complete = 1;
				oEventManager.event_selected = true;
			},
			result: "A swallow for a safe return. Your compass leans a little kinder."
		}
		event_tattooist_opt_3 = {
			title: "Politely decline",
			description: "Nothing happens.",
			effect: function(_context) {
				oEventManager.event_complete = 2;
				oEventManager.event_selected = true;
			},
			result: "She shrugs and goes back to her needles."
		}
	ds_list_add(event_tattooist.options, event_tattooist_opt_1);
	ds_list_add(event_tattooist.options, event_tattooist_opt_2);
	ds_list_add(event_tattooist.options, event_tattooist_opt_3);
	ds_list_add(global.master_event_list, event_tattooist);

	// =====================================================================
	// CHAPTER 2 EVENTS (2026-11-24: each chapter has its own events, stronger each chapter; event_chapter)
	// built from the ev_* helpers below define_events
	// =====================================================================

	var _ev = { name: "The smugglers' cove", description: "Lanterns in a hidden cove. Smugglers, and a hold full of goods that aren't theirs.", options: ds_list_create() };
	ds_list_add(_ev.options, {
		title: "Buy the lot (90 gold)",
		description: "Lose 90 gold. Gain 2 random keepsakes.",
		effect: function(_context) { if (!ev_pay(90)) return; ev_give_keepsakes(2); ev_done(0); },
		result: "They count your gold twice, then hand over the crates.",
	});
	ds_list_add(_ev.options, {
		title: "Take it by force",
		description: "Lose 15 health and 8 alignment. Gain a random keepsake and 80 gold.",
		effect: function(_context) { ev_hurt(15); gain_alignment(-8); ev_give_keepsakes(1); ev_gold(80); ev_done(1); },
		result: "Steel settles it. The smugglers scatter into the dark.",
	});
	ds_list_add(_ev.options, {
		title: "Sail on",
		description: "Nothing happens.",
		effect: function(_context) { ev_done(2); },
		result: "Some cargo is better left alone.",
	});
	ds_list_add(global.master_event_list, _ev);

	_ev = { name: "The master shipwright", description: "A shipwright famous in every port offers you a day's work. One job, she says.", options: ds_list_create() };
	ds_list_add(_ev.options, {
		title: "Rebuild your dice",
		description: "Upgrade 2 dice of your choice.",
		effect: function(_context) {
			ev_pick(2, "Choose 2 dice to upgrade", "upgrade", function(_die) { ev_upgrade_die(_die, 1); });
			ev_done(0);
		},
		result: "She works through the night. Two dice come back bigger.",
	});
	ds_list_add(_ev.options, {
		title: "Lighten the hold",
		description: "Remove up to 3 dice from your bag.",
		effect: function(_context) { if (!ev_remove_pick(3)) return; ev_done(1); },
		result: "What's left rolls truer.",
	});
	ds_list_add(_ev.options, {
		title: "Patch the hull",
		description: "Gain 12 max health.",
		effect: function(_context) { ev_max_hp(12); ev_done(2); },
		result: "New planks, tarred and tight.",
	});
	ds_list_add(global.master_event_list, _ev);

	_ev = { name: "The governor's ball", description: "An invitation to the governor's ball, delivered to the wrong captain.", options: ds_list_create() };
	ds_list_add(_ev.options, {
		title: "Charm the governor",
		description: "Gain 10 alignment and a random rare die.",
		effect: function(_context) { gain_alignment(10); ev_give_dice(1, "rare"); ev_done(0); },
		result: "The governor toasts your health and sends you off with a gift.",
	});
	ds_list_add(_ev.options, {
		title: "Rob the guests",
		description: "Lose 12 alignment. Gain 150 gold.",
		effect: function(_context) { gain_alignment(-12); ev_gold(150); ev_done(1); },
		result: "You leave before the last dance, pockets heavy.",
	});
	ds_list_add(global.master_event_list, _ev);

	_ev = { name: "The old fortress", description: "An abandoned fortress on the cliffs, its gates rusted open.", options: ds_list_create() };
	ds_list_add(_ev.options, {
		title: "Raid the armoury",
		description: "Lose 12 health. Gain a random tool, or 100 gold if you have them all.",
		effect: function(_context) { ev_hurt(12); if (!ev_give_tool()) ev_gold(100); ev_done(0); },
		result: "A rotten floor gives way, but you climb out with your prize.",
	});
	ds_list_add(_ev.options, {
		title: "Raid the powder store",
		description: "Give up to 3 dice of your choice +1 min roll.",
		effect: function(_context) {
			ev_pick(3, "Choose up to 3 dice to gain +1 min roll", "min_room", function(_die) { ev_min_roll(_die, 1); });
			ev_done(1);
		},
		result: "Dry powder, still good. Your shots won't fall short.",
	});
	ds_list_add(_ev.options, {
		title: "Leave it",
		description: "Nothing happens.",
		effect: function(_context) { ev_done(2); },
		result: "The gulls can have it.",
	});
	ds_list_add(global.master_event_list, _ev);

	_ev = { name: "A ghost ship", description: "A ship with no crew drifts alongside, every lantern lit.", options: ds_list_create() };
	ds_list_add(_ev.options, {
		title: "Board her",
		description: "Lose 8 max health. Gain a random rare die and a random keepsake.",
		effect: function(_context) { ev_max_hp(-8); ev_give_dice(1, "rare"); ev_give_keepsakes(1); ev_done(0); },
		result: "Cold hands on your shoulders the whole way round. You take what you can.",
	});
	ds_list_add(_ev.options, {
		title: "Burn her",
		description: "Gain 8 alignment and 8 luck.",
		effect: function(_context) { gain_alignment(8); global.player_luck += 8; ev_done(1); },
		result: "She burns green, and something sighs as she sinks.",
	});
	ds_list_add(global.master_event_list, _ev);

	_ev = { name: "The whirlpool", description: "The sea turns in a slow circle, and the ship turns with it.", options: ds_list_create() };
	ds_list_add(_ev.options, {
		title: "Ride it through",
		description: "Luck decides. Success: gain 2 random keepsakes. Failure: lose 20 health.",
		effect: function(_context) { if (ev_luck()) ev_give_keepsakes(2); else ev_hurt(20); ev_done(0); },
		result: "The ship spins out of the far side, and the crew counts heads.",
	});
	ds_list_add(_ev.options, {
		title: "Throw cargo overboard",
		description: "Remove up to 2 dice from your bag.",
		effect: function(_context) { if (!ev_remove_pick(2)) return; ev_done(1); },
		result: "Lighter, the ship pulls clear of the edge.",
	});
	ds_list_add(global.master_event_list, _ev);

	_ev = { name: "A merchant convoy", description: "Three fat merchant ships, slow and lightly guarded.", options: ds_list_create() };
	ds_list_add(_ev.options, {
		title: "Escort them",
		description: "Gain 90 gold and 5 alignment.",
		effect: function(_context) { ev_gold(90); gain_alignment(5); ev_done(0); },
		result: "They pay well for safe passage.",
	});
	ds_list_add(_ev.options, {
		title: "Trade (60 gold)",
		description: "Lose 60 gold. Gain a random rare core.",
		effect: function(_context) {
			if (get_first_free_item_slot() == -1) { throw_error("Item slots full", "Right click an item to drop it."); return; }
			if (!ev_pay(60)) return;
			ev_give_item("core", "rare");
			ev_done(1);
		},
		result: "Their best piece, wrapped in silk.",
	});
	ds_list_add(_ev.options, {
		title: "Plunder them",
		description: "Lose 12 alignment. Gain 160 gold and a random potion.",
		effect: function(_context) { gain_alignment(-12); ev_gold(160); ev_give_item("potion", "all"); ev_done(2); },
		result: "Their holds are lighter now, and so is your conscience.",
	});
	ds_list_add(global.master_event_list, _ev);

	_ev = { name: "The lighthouse keeper", description: "A lighthouse on a rock, and an old keeper glad of the company.", options: ds_list_create() };
	ds_list_add(_ev.options, {
		title: "Stay the night",
		description: "Heal 50% of your max health.",
		effect: function(_context) { ev_heal(0.5); ev_done(0); },
		result: "Warm stew and a dry bed. You wake a new captain.",
	});
	ds_list_add(_ev.options, {
		title: "Take his charts",
		description: "Gain 10 luck. Next fight, gain 1 extra play each turn.",
		effect: function(_context) { global.player_luck += 10; oRunManager.bonus_dice_next_combat = 1; ev_done(1); },
		result: "His charts mark every rock and current for a hundred miles.",
	});
	ds_list_add(global.master_event_list, _ev);

	// =====================================================================
	// CHAPTER 3 EVENTS: big effects and big choices
	// =====================================================================

	_ev = { name: "The Pirate King's hoard", description: "The Pirate King is dead and his hoard unguarded. The tide is coming in. You can carry one thing out.", options: ds_list_create() };
	ds_list_add(_ev.options, {
		title: "The crown",
		description: "Lose 15 max health. Gain 3 random keepsakes.",
		effect: function(_context) { ev_max_hp(-15); ev_give_keepsakes(3); ev_done(0); },
		result: "It's heavier than it looks. Everything worth having is.",
	});
	ds_list_add(_ev.options, {
		title: "The gold",
		description: "Gain 300 gold.",
		effect: function(_context) { ev_gold(300); ev_done(1); },
		result: "As much as the boat will hold, and then a little more.",
	});
	ds_list_add(_ev.options, {
		title: "His dice",
		description: "Gain 2 random rare dice.",
		effect: function(_context) { ev_give_dice(2, "rare"); ev_done(2); },
		result: "The dice of a king. They feel warm.",
	});
	ds_list_add(global.master_event_list, _ev);

	_ev = { name: "The volcano forge", description: "A forge built into the mouth of a volcano, hot enough to melt anchors.", options: ds_list_create() };
	ds_list_add(_ev.options, {
		title: "Temper every blade",
		description: "Lose 10 max health. Upgrade every attack die in your bag.",
		effect: function(_context) {
			ev_max_hp(-10);
			for (var d = 0; d < ds_list_size(global.dice_bag); d++) if (global.dice_bag[| d].action_type == "ATK") ev_upgrade_die(global.dice_bag[| d], 1);
			ev_done(0);
		},
		result: "Burns up both arms. Every blade aboard comes out glowing.",
	});
	ds_list_add(_ev.options, {
		title: "Temper one",
		description: "Upgrade a die of your choice 3 times.",
		effect: function(_context) {
			ev_pick(1, "Choose a die to upgrade 3 times", "upgrade", function(_die) { ev_upgrade_die(_die, 3); });
			ev_done(1);
		},
		result: "Three days at the anvil, on one die.",
	});
	ds_list_add(global.master_event_list, _ev);

	_ev = { name: "A duel at dawn", description: "A rival captain challenges you to a duel on the beach. Both crews are watching.", options: ds_list_create() };
	ds_list_add(_ev.options, {
		title: "Accept",
		description: "Luck decides. Success: gain 2 random keepsakes and 200 gold. Failure: lose 30 health.",
		effect: function(_context) { if (ev_luck()) { ev_give_keepsakes(2); ev_gold(200); } else ev_hurt(30); ev_done(0); },
		result: "Pistols at twenty paces. One of you walks away.",
	});
	ds_list_add(_ev.options, {
		title: "Send someone in your place",
		description: "Lose 10 alignment. Gain a random keepsake.",
		effect: function(_context) { gain_alignment(-10); ev_give_keepsakes(1); ev_done(1); },
		result: "Your stand-in wins. The crew remembers who didn't fight.",
	});
	ds_list_add(global.master_event_list, _ev);

	_ev = { name: "The cartographers' guild", description: "Mapmakers who chart more than coastlines. For a price, they'll redraw yours.", options: ds_list_create() };
	ds_list_add(_ev.options, {
		title: "Copy your best (100 gold)",
		description: "Lose 100 gold. Copy 2 dice of your choice.",
		effect: function(_context) {
			if (!ev_pay(100)) return;
			ev_pick(2, "Choose 2 dice to copy", "none", function(_die) {
				ds_list_add(global.dice_bag, clone_die(_die, ""));
				spawn_floating_number("bag", 0, _die.name + " copied", _die.color, 0, -1, 0);
				particle_emit(115, 1000, "burst", get_dice_color(_die.possible_type), 30);
			});
			ev_done(0);
		},
		result: "Drawn so true you can't tell which is the original.",
	});
	ds_list_add(_ev.options, {
		title: "Redraw the chart",
		description: "Turn up to 3 dice of your choice into random rare dice.",
		effect: function(_context) {
			ev_pick(3, "Choose up to 3 dice to redraw", "none", function(_die) {
				var _at = ds_list_find_index(global.dice_bag, _die);
				if (_at == -1) return;
				var _opts = ds_list_create();
				generate_dice_rewards(_opts, global.master_dice_list, 1, "rare", "");
				if (ds_list_size(_opts) > 0) {
					global.dice_bag[| _at] = clone_die(_opts[| 0], "");
					spawn_floating_number("bag", 0, _die.name + "\nbecomes\n" + _opts[| 0].name, _opts[| 0].color, 0, -1, 0);
					particle_emit(115, 1000, "burst", get_dice_color(_opts[| 0].possible_type), 30);
				}
				ds_list_destroy(_opts);
			});
			ev_done(1);
		},
		result: "Fresh ink, new shapes. Your bag is not what it was.",
	});
	ds_list_add(global.master_event_list, _ev);

	_ev = { name: "The kraken", description: "Arms as thick as the mainmast rise out of the water on every side.", options: ds_list_create() };
	ds_list_add(_ev.options, {
		title: "Fight it off",
		description: "Lose 25 health. Gain 2 random keepsakes.",
		effect: function(_context) { ev_hurt(25); ev_give_keepsakes(2); ev_done(0); },
		result: "It sinks back into the deep, leaving wreckage and treasure on your deck.",
	});
	ds_list_add(_ev.options, {
		title: "Feed it the cargo",
		description: "Lose half your gold.",
		effect: function(_context) { oRunManager.credits -= floor(oRunManager.credits / 2); ev_done(1); },
		result: "It takes the bait, and the gold, and lets you pass.",
	});
	ds_list_add(global.master_event_list, _ev);

	_ev = { name: "Calypso's bargain", description: "The sea goddess rises from the waves and names her price.", options: ds_list_create() };
	ds_list_add(_ev.options, {
		title: "Ask for power",
		description: "Lose 20 max health. Every die in your bag gets +1 min roll.",
		effect: function(_context) {
			ev_max_hp(-20);
			for (var d = 0; d < ds_list_size(global.dice_bag); d++) ev_min_roll(global.dice_bag[| d], 1, false);
			spawn_floating_number("bag", 0, "Every die +1 min roll", c_white, 0, -1, 0);
			ev_done(0);
		},
		result: "Something leaves you, and something enters every die you own.",
	});
	ds_list_add(_ev.options, {
		title: "Ask for fortune",
		description: "Gain 20 luck and 150 gold.",
		effect: function(_context) { global.player_luck += 20; ev_gold(150); ev_done(1); },
		result: "She laughs, and the sea is kinder to you from now on.",
	});
	ds_list_add(_ev.options, {
		title: "Refuse her",
		description: "Gain 10 alignment.",
		effect: function(_context) { gain_alignment(10); ev_done(2); },
		result: "Few refuse a goddess. The crew looks at you differently.",
	});
	ds_list_add(global.master_event_list, _ev);

	_ev = { name: "The edge of the map", description: "The charts end here. Beyond this line, nothing is drawn.", options: ds_list_create() };
	ds_list_add(_ev.options, {
		title: "Sail into the blank",
		description: "Luck decides. Success: gain a random rare die, a random keepsake and 150 gold. Failure: lose 15 max health.",
		effect: function(_context) { if (ev_luck()) { ev_give_dice(1, "rare"); ev_give_keepsakes(1); ev_gold(150); } else ev_max_hp(-15); ev_done(0); },
		result: "Days of fog, then land no map has ever shown.",
	});
	ds_list_add(_ev.options, {
		title: "Turn back",
		description: "Heal 40% of your max health.",
		effect: function(_context) { ev_heal(0.4); ev_done(1); },
		result: "Familiar water. The crew sleeps easy for the first time in weeks.",
	});
	ds_list_add(global.master_event_list, _ev);

	_ev = { name: "Davy Jones' locker", description: "The drowned crews of a hundred ships, held under the waves. They reach for your hull.", options: ds_list_create() };
	ds_list_add(_ev.options, {
		title: "Free them",
		description: "Gain 15 alignment and 15 max health.",
		effect: function(_context) { gain_alignment(15); ev_max_hp(15); ev_done(0); },
		result: "A hundred voices thank you as they rise.",
	});
	ds_list_add(_ev.options, {
		title: "Take their dice",
		description: "Lose 15 alignment. Gain 2 random rare dice.",
		effect: function(_context) { gain_alignment(-15); ev_give_dice(2, "rare"); ev_done(1); },
		result: "They won't be needing them. They watch you go.",
	});
	ds_list_add(global.master_event_list, _ev);
}

/// Shared by the Siren event options. Lives at script level so the option structs can call it.
/// @func sirens_upgrade_count(_lean)
/// @desc The Siren's Call: how many dice an option upgrades. _lean is how far your alignment leans its way from neutral
///       (50): toward merciful for the song, toward ruthless for the cannons, negative the other way.
///       1 near neutral, 2 from 25 its way (alignment 75 / 25), 3 from 40 (90 / 10), and 0 from 25 the other way.
function sirens_upgrade_count(_lean) {
	if (_lean >= 40) return 3;
	if (_lean >= 25) return 2;
	if (_lean > -25) return 1;
	return 0;
}

/// @func event_chapter(_name)
/// @desc Which chapter's pool an event belongs to (2026-11-24: each chapter has its own events, stronger each chapter).
///       enter_node draws from the current chapter's pool, then earlier chapters' if it has run dry.
function event_chapter(_name) {
	switch (_name) {
		case "The smugglers' cove": case "The master shipwright": case "The governor's ball": case "The old fortress":
		case "A ghost ship": case "The whirlpool": case "A merchant convoy": case "The lighthouse keeper":
			return 2;
		case "The Pirate King's hoard": case "The volcano forge": case "A duel at dawn": case "The cartographers' guild":
		case "The kraken": case "Calypso's bargain": case "The edge of the map": case "Davy Jones' locker":
			return 3;
	}
	return 1;
}

// ---------------------------------------------------------------------
// Shared effects for event options (2026-11-24, used by the chapter 2 and 3 events). The ones that can be refused
// (not enough gold, a small bag) say why and return false, so the option stays open.
// ---------------------------------------------------------------------

/// @func ev_done(_option) - the event is over; its text becomes that option's result
function ev_done(_option) {
	oEventManager.event_complete = _option;
	oEventManager.event_selected = true;
}

/// @func ev_pay(_gold)
function ev_pay(_gold) {
	if (oRunManager.credits < _gold) { throw_error("Not enough gold", "You need " + string(_gold) + " gold."); return false; }
	oRunManager.credits -= _gold;
	return true;
}

/// @func ev_gold(_amount) - coins fly from the mouse to your purse
function ev_gold(_amount) {
	gain_coins(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _amount);
}

/// @func ev_hurt(_amount) - as the older events: hitting zero here ends the run (oRunManager Step)
function ev_hurt(_amount) {
	global.player_hp -= _amount;
}

/// @func ev_heal(_fraction) - heals a share of max health
function ev_heal(_fraction) {
	if (global.player_hp >= global.player_max_hp) return;
	process_action("player", 0, ceil(global.player_max_hp * _fraction), 0, "player", undefined, "HEAL");
	trigger_keepsake_visual();
}

/// @func ev_max_hp(_amount) - gained max health is also gained as health; lost max health caps your health
function ev_max_hp(_amount) {
	global.player_max_hp = max(1, global.player_max_hp + _amount);
	if (_amount > 0) global.player_hp += _amount;
	global.player_hp = min(global.player_hp, global.player_max_hp);
}

/// @func ev_luck() - a luck roll, as the Dutchman's (luck 50 is even odds)
function ev_luck() {
	return irandom_range(1, 100) <= global.player_luck;
}

/// @func ev_give_keepsakes(_n)
function ev_give_keepsakes(_n) {
	repeat (_n) {
		var _opts = ds_list_create();
		generate_keepsake_rewards(_opts, global.rollable_keepsake_list, 1);
		if (ds_list_size(_opts) > 0) gain_keepsake(_opts[| 0], global.rollable_keepsake_list);
		ds_list_destroy(_opts);
	}
}

/// @func ev_give_dice(_n, _rarity) - dealt onto the event as the older events do; a click sends each to the bag
function ev_give_dice(_n, _rarity) {
	var _targets = generate_valid_targets(_n, 100);
	for (var i = 0; i < _n; i++) {
		var _opts = ds_list_create();
		generate_dice_rewards(_opts, global.master_dice_list, 1, _rarity, "");
		if (ds_list_size(_opts) > 0) {
			var _ds = _opts[| 0];
			var _inst = instance_create_layer(display_get_gui_width() / 2, display_get_gui_height() + 100, "Instances", oDice);
			_inst.struct = _ds;
			_inst.action_type = _ds.action_type;
			_inst.dice_amount = _ds.dice_amount;
			_inst.dice_value = _ds.dice_value;
			_inst.possible_type = _ds.possible_type;
			_inst.can_discard = true;
			if (i < array_length(_targets)) { _inst.target_x = _targets[i][0]; _inst.target_y = _targets[i][1]; }
		}
		ds_list_destroy(_opts);
	}
}

/// @func ev_give_item(_filter, _rarity) - a core or potion into a free item slot (nothing if they're full)
function ev_give_item(_filter, _rarity) {
	if (get_first_free_item_slot() == -1) return false;
	var _opts = ds_list_create();
	generate_item_rewards(_opts, global.master_item_list, 1, _filter, _rarity);
	if (ds_list_size(_opts) > 0) gain_item(_opts[| 0]);
	ds_list_destroy(_opts);
	return true;
}

/// @func ev_give_tool() - a random tool from the pool; false if you have them all
function ev_give_tool() {
	if (ds_list_size(global.master_tool_list) == 0) return false;
	var _opts = ds_list_create();
	generate_tool_rewards(_opts, global.master_tool_list, 1);
	var _ok = ds_list_size(_opts) > 0;
	if (_ok) {
		ds_list_add(oRunManager.tools, _opts[| 0]);
		var _at = ds_list_find_index(global.master_tool_list, _opts[| 0]);
		if (_at != -1) ds_list_delete(global.master_tool_list, _at);
		ds_list_add(oRunManager.tools_scale, 0.5);
		oRunManager.show_tools = true;
	}
	ds_list_destroy(_opts);
	return _ok;
}

/// @func ev_pick(_n, _message, _filter, _fn) - opens the dice picker for up to _n dice; _fn(die) runs on each
function ev_pick(_n, _message, _filter, _fn) {
	oRunManager.dice_selection = _n;
	oRunManager.dice_selection_up_to = (_n > 1); // never stuck with fewer dice that fit than it asks for
	oRunManager.dice_selection_message = _message;
	oRunManager.dice_selection_filter = _filter;
	oRunManager.dice_selection_event = _fn;
}

/// @func ev_remove_pick(_n) - pick up to _n dice to remove; never takes the bag below 6
function ev_remove_pick(_n) {
	var _room = ds_list_size(global.dice_bag) - 6;
	if (_room <= 0) { throw_error("Bag too small", "Your bag can't go below 6 dice."); return false; }
	_n = min(_n, _room);
	ev_pick(_n, "Choose up to " + string(_n) + ((_n == 1) ? " die" : " dice") + " to remove", "none", function(_die) {
		var _at = ds_list_find_index(global.dice_bag, _die);
		if (_at == -1) return;
		particle_emit(115, 1000, "burst", get_dice_color(_die.possible_type), 30);
		spawn_floating_number("bag", 0, _die.name + " removed", _die.color, 0, -1, 0);
		ds_list_delete(global.dice_bag, _at);
	});
	oRunManager.dice_selection_up_to = true;
	return true;
}

/// @func ev_upgrade_die(_die, _times) - one size up each time (+2 sides), never a coin, never past a d12
function ev_upgrade_die(_die, _times) {
	var _done = 0;
	repeat (_times) {
		if (_die.dice_value == 2 || _die.dice_value >= 12) break;
		_die.dice_value += 2;
		_done++;
	}
	if (_done == 0) return;
	die_size_changed(_die);
	particle_emit(115, 1000, "rise", get_dice_color(_die.possible_type), 30);
	spawn_floating_number("bag", 0, _die.name + " upgraded" + ((_done > 1) ? " x" + string(_done) : ""), _die.color, 0, -1, 0);
}

/// @func ev_min_roll(_die, _amount, [_show]) - raises its lowest roll, never past its highest
function ev_min_roll(_die, _amount, _show = true) {
	var _gain = min(_amount, _die.dice_value - 1 - _die.min_roll_bonus);
	if (_gain <= 0) return;
	_die.min_roll_bonus += _gain;
	if (_show) {
		particle_emit(115, 1000, "rise", get_dice_color(_die.possible_type), 30);
		spawn_floating_number("bag", 0, _die.name + " +" + string(_gain) + " min roll", _die.color, 0, -1, 0);
	}
}

/// @func event_is_sea(_name)
/// @desc Is this a sea event (drawn at sea stops) rather than an island one? (2026-11-24: the pools are split)
function event_is_sea(_name) {
	switch (_name) {
		case "A Great Storm": case "Clear skies": case "Broken sails": case "A bird flies aboard": case "The Flying Dutchman":
		case "Rough tides": case "The constellation": case "The Siren's Call": case "A floating crate":
		case "A ghost ship": case "The whirlpool": case "A merchant convoy": case "The lighthouse keeper":
		case "The kraken": case "Calypso's bargain": case "The edge of the map": case "Davy Jones' locker":
			return true;
	}
	return false;
}

/// @func sirens_option_text(_type_word, _count)
/// @desc What a Siren's Call option will do, with your alignment's count in it.
function sirens_option_text(_type_word, _count) {
	var _rule = (_type_word == "ink") ? "More the higher your alignment." : "More the lower your alignment.";
	if (_count <= 0) return "Nothing at your alignment. " + _rule;
	return "Upgrade " + string(_count) + " " + _type_word + ((_count == 1) ? " die" : " dice") + " at random. " + _rule;
}

/// @func sirens_upgrade(_type, _count, _col)
/// @desc Upgrades _count random dice of _type in the bag by one size (+2: a d4 becomes a d6). Coins and d12s are left
///       alone. With none of that type, any die can be upgraded instead, so the song is never wasted.
function sirens_upgrade(_type, _count, _col) {
	var _pool = [];
	for (var d = 0; d < ds_list_size(global.dice_bag); d++) {
		var _die = global.dice_bag[| d];
		if (_die.action_type == _type && _die.dice_value != 2 && _die.dice_value < 12) array_push(_pool, _die);
	}
	if (array_length(_pool) == 0) {
		for (var d = 0; d < ds_list_size(global.dice_bag); d++) {
			var _die = global.dice_bag[| d];
			if (_die.dice_value != 2 && _die.dice_value < 12) array_push(_pool, _die);
		}
	}
	var _done = 0;
	while (_done < _count && array_length(_pool) > 0) {
		var _i = irandom(array_length(_pool) - 1);
		var _up = _pool[_i];
		array_delete(_pool, _i, 1);
		_up.dice_value += 2;
		die_size_changed(_up);
		spawn_floating_number("bag", 0, _up.name + " upgraded", _up.color, 0, -1, 0);
		_done++;
	}
	if (_done > 0) particle_emit(115, 1000, "rise", _col);
	return _done;
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
		throw_error("Not enough health", "This would sink you.");
	}
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
	
	// An event node that was entered before (then the game was closed) shows the same event again
	var _node = oWorldManager.current_node;
	if (_node != undefined && variable_struct_exists(_node, "event_name") && is_string(_node.event_name) && _node.event_name != "") {
		var _remembered = event_index_by_name(_node.event_name);
		if (_remembered != -1) rand = _remembered;
	}
	
	// The F1 debug menu can ask for a specific event
	var _debug_index = debug_take_forced_event_index();
	if (_debug_index != -1) rand = _debug_index;
	
	event = global.master_event_list[| rand];

	chosen_event = event;
	ds_list_delete(global.master_event_list, rand);
}

/// @desc Index of an event in global.master_event_list by name, rebuilding the list once if it has
///       already been drawn this run. Returns -1 if there's no such event.
function event_index_by_name(_name) {
	repeat (2) {
		for (var i = 0; i < ds_list_size(global.master_event_list); i++) {
			if (global.master_event_list[| i].name == _name) return i;
		}
		define_events();
	}
	return -1;
}
