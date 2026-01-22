// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

function trigger_keepsake_visual() {
	var index = ds_list_find_index(oRunManager.keepsakes, self);
	oRunManager.keepsake_scale[| index] = 2.0;
}

function define_keepsakes() {
	global.master_keepsake_list = ds_list_create(); // all keepsakes
	global.rollable_keepsake_list = ds_list_create(); // keepsakes that aren't starters, events, boss or shop keepsakes, that can be rolled in events amd acquired from elites
	global.shop_keepsake_list = ds_list_create();
	global.boss_keepsake_list = ds_list_create(); // keepsakes that are acquired from completing a voyage

	// ------------------
	// STARTER KEEPSAKES
	// ------------------
	ks_looking_glass = {
	    _id: "looking_glass",
	    name: "Looking Glass",
	    desc: "Start each combat with 6 intel",
		sub_image: 5,
	    trigger: function(event, data) {
	        if (event == "on_turn_start") {
	            if (oCombat.turn_count == 1) {
					oCombat.player_intel = 6;
					trigger_keepsake_visual();
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_looking_glass);
	
	// ------------------
	// SHOP KEEPSAKES
	// ------------------
	ks_lime_juice = {
	    _id: "lime_juice",
	    name: "Lime Juice",
	    desc: "Lose 5hp and gain 10 max hp",
		sub_image: 28,
		price: 80,
	    trigger: function(event, data) {
	        if (event == "on_keepsake_acquired" && data.keepsake_id == _id) { // make sure we only trigger when we acquire THIS keepsake, not all keepsakes
	            global.player_hp -= 5;
				global.player_max_hp += 10;
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_lime_juice);
	ds_list_add(global.shop_keepsake_list, ks_lime_juice);
	
	ks_salted_pork = {
	    _id: "salted_pork",
	    name: "Salted Pork",
	    desc: "Heal 10% more every time you rest",
		sub_image: 29,
		price: 90,
	    trigger: function(event, data) {
	        if (event == "on_rest") { // make sure we only trigger when we acquire THIS keepsake, not all keepsakes
	            data.rest_amount += 0.10;
				
				trigger_keepsake_visual();
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_salted_pork);
	ds_list_add(global.shop_keepsake_list, ks_salted_pork);
	
	ks_pickled_cucumber = {
	    _id: "pickled_cucumber",
	    name: "Pickled Cucumber",
	    desc: "+1 playable die during first turn of combat",
		sub_image: 33,
		price: 100,
	    trigger: function(event, data) {
	        if (event == "on_turn_start") {
	            if (oCombat.turn_count == 1) {
					data.bonus_dice += 1;
				
					trigger_keepsake_visual();
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_pickled_cucumber);
	ds_list_add(global.shop_keepsake_list, ks_pickled_cucumber);
	
	ks_toolbelt = {
	    _id: "toolbelt",
	    name: "Toolbelt",
	    desc: "Gain +2 item slots",
		sub_image: 25,
		price: 100,
	    trigger: function(event, data) {
	        if (event == "on_keepsake_acquired" && data.keepsake_id == _id) { // make sure we only trigger when we acquire THIS keepsake, not all keepsakes
	            oRunManager.max_items += 2;
				repeat(2) {
					array_push(oRunManager.items, undefined);
					array_push(oRunManager.items_hover, false);
					array_push(oRunManager.items_hover_scale, 1.0);
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_toolbelt);
	ds_list_add(global.shop_keepsake_list, ks_toolbelt);
	
	ks_rum = {
	    _id: "rum",
	    name: "Rum",
	    desc: "All attacks gain +1 max roll and -1 min roll",
	    sub_image: 30,
		price: 110,
	    trigger: function(event, data) {			
			if (event == "on_roll_die") {
				if (data.action_type == "ATK") {
					data.min_roll -= 1;
					data.max_roll += 1;
					
					if (!data.read_only) {
						trigger_keepsake_visual();
					}
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_rum);
	ds_list_add(global.shop_keepsake_list, ks_rum);
	
	ks_rations = {
	    _id: "rations",
	    name: "Rations",
	    desc: "When you drink a potion, heal 3 hitpoints",
	    sub_image: 31,
		price: 110,
	    trigger: function(event, data) {			
			if (event == "on_consumable_used") {
	            if (global.player_hp < global.player_max_hp) {
					var amount = 3;
					process_action("player", 0, amount, 0, "player", undefined, "HEAL");
					
					trigger_keepsake_visual();
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_rations);
	ds_list_add(global.shop_keepsake_list, ks_rations);
	
	ks_water_barrel = {
	    _id: "water_barrel",
	    name: "Water Barrel",
	    desc: "Potions have a 30% chance to not be consumed",
	    sub_image: 32,
		price: 120,
	    trigger: function(event, data) {			
			if (event == "on_consumable_used") {
				var random_chance = irandom(9);
				
				if (random_chance <= 2) {
					data.use_potion = false;
					trigger_keepsake_visual();
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_water_barrel);
	ds_list_add(global.shop_keepsake_list, ks_water_barrel);
	
	
	// ------------------
	// EVENT KEEPSAKES
	// ------------------
	
	ks_small_sail = {
	    _id: "small_sail",
	    name: "Small Sail",
	    desc: "Draw 2 additional dice at the start of combat",
		sub_image: 6,
	    trigger: function(event, data) {
	        if (event == "on_turn_start") {
	            if (oCombat.turn_count == 1) {
					if (!oCombat.is_dealing_dice) {
						oCombat.dice_to_deal += 2;
				
						trigger_keepsake_visual();
					}
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_small_sail);
	
	ks_rope_of_repair = {
	    _id: "rope_of_repair",
	    name: "Rope of Repair",
	    desc: "Heal 3 health at the start of each combat",
		sub_image: 7,
	    trigger: function(event, data) {
	        if (event == "on_turn_start") {
	            if (global.player_hp < global.player_max_hp) {
					if (oCombat.turn_count == 1) {
						process_action( "player", 0, 3, 0, "player", undefined, "HEAL");
				
						trigger_keepsake_visual();
					}
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_rope_of_repair);
	
	ks_deckhands_token = {
	    _id: "deckhands_token",
	    name: "Deckhand's Token",
	    desc: "First dice in slot 1 gets +1 bonus",
		sub_image: 8,
	    trigger: function(event, data) {
	        if (event == "on_roll_die") {
	            if (data.slot_num == 0 && data.die == oCombat.action_queue[| data.slot_num].dice_list[| 0]) {
					data.min_roll++;
					data.max_roll++;
				
					if (!data.read_only) {				
						trigger_keepsake_visual();
					}
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_deckhands_token);
	
	ks_starvers_efficiency = {
	    _id: "starvers_efficiency",
	    name: "Starver's Efficiency",
	    desc: "The first block you play each turn rolls twice and takes the higher value",
		sub_image: 43,
		state: { effect_used: false },
	    trigger: function(event, data) {
	        if (event == "on_roll_die") {
	            if (!self.state.effect_used && data.action_type == "BLK" && !data.read_only) {
					data.roll_twice = true;
					self.state.effect_used = true;
				
					trigger_keepsake_visual();
				}
	        }
			
			if (event == "on_player_turn_end") {
	            self.state.effect_used = false;
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_starvers_efficiency);
	
	// ------------------
	// SLOT KEEPSAKES
	// ------------------
	
	ks_black_purse = {
	    _id: "black_purse",
	    name: "Black Purse",
	    desc: "At the end of combat gain 3 gold for every slot in your action queue",
		sub_image: 9,
	    trigger: function(event, data) {
	        if (event == "on_combat_end") {
	            for (var i = 0; i < ds_list_size(oCombat.action_queue); i++) {
					gain_coins(oCombat.slot_positions[| i].x, oCombat.slot_positions[| i].y, 3);
				
					trigger_keepsake_visual();
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_black_purse);
	ds_list_add(global.rollable_keepsake_list, ks_black_purse);
	
	ks_shipwrights_draft = {
	    _id: "shipwrights_draft",
	    name: "Shipwright's Draft",
	    desc: "When new slots are created, gain 1 more dice playable that turn",
		sub_image: 10,
	    trigger: function(event, data) {
	        if (event == "on_new_slot_created") {
	            oCombat.dice_allowed_this_turn_bonus++;
				
				trigger_keepsake_visual();
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_shipwrights_draft);
	ds_list_add(global.rollable_keepsake_list, ks_shipwrights_draft);
	
	ks_cannon_splitter = {
	    _id: "cannon_splitter",
	    name: "Cannon Splitter",
	    desc: "Your first attack slot hits all other enemies for 75%",
		sub_image: 11,
		state: {
			used: false,
		},
	    trigger: function(event, data) {
	        if (event == "after_slot_damage_calculated") {
	            if (data.type == "ATK" && !self.state.used) {
	                with (oCombat) {
						// Deal flat damage to all enemies, we have to run this backwards in case any enemies die during this roll
						for (var i = oCombat.enemies_left_this_combat-1; i >= 0 ; i--) {
							if (i != enemy_target_index) process_action(oCombat.room_enemies[| i], 0, floor(data.final_amount * 0.75), 0, "player", -1, "ATK", undefined, undefined, 0);
						}
					}
					self.state.used = true;
				
					trigger_keepsake_visual();
	            }
	        }
			
			if (event == "on_turn_start") {
	            self.state.used = false;
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_cannon_splitter);
	ds_list_add(global.rollable_keepsake_list, ks_cannon_splitter);
	
	ks_bandage = {
	    _id: "bandage",
	    name: "Bandage",
	    desc: "Every time you are debuffed, the first slot in your queue gains +1 for the remainder of combat",
		sub_image: 14,
		state: {
			triggered: false,
		},
	    trigger: function(event, data) {
			
			if (event == "on_player_debuffed") {
				if (!self.state.triggered) {
					oCombat.action_queue[| 0].bonus_amount += 1;
				
					trigger_keepsake_visual();
					//self.state.triggered = true; // uncomment this if we want it to only trigger the first time we are debuffed
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_bandage);
	ds_list_add(global.rollable_keepsake_list, ks_bandage);
	
	ks_single_focus = {
	    _id: "single_focus",
	    name: "Single Focus",
	    desc: "Slots with only one possible action type gain +1",
		sub_image: 13,
		state: {
		},
	    trigger: function(event, data) {
			if (event == "on_dice_played_to_slot")  {
				if (data._slot > -1) {
					if (string_pos(" ", data._slot.possible_type) == 0) {
						data._slot.bonus_amount += 1;
						data._slot.buffed += 1;
					}
				}
	        }
			
			if (event == "after_new_slot_created") {
				var slot = oCombat.action_queue[| ds_list_size(oCombat.action_queue) -1];
				
				if (string_pos(" ", slot.possible_type) == 0) {
					slot.bonus_amount += 1;
					slot.buffed += 1;
				}
			}
			
			if (event == "on_turn_start")  {
				for (var i = 0; i < ds_list_size(oCombat.action_queue); i++) {
					var _slot = oCombat.action_queue[| i];
					if (string_pos(" ", _slot.possible_type) == 0 && _slot.possible_type != "None") {
						_slot.bonus_amount += 1;
						_slot.buffed += 1;
					}
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_single_focus);
	ds_list_add(global.rollable_keepsake_list, ks_single_focus);

	ks_repeater_rail = {
	    _id: "repeater_rail",
	    name: "Repeater Rail",
	    desc: "Slots gain +1 to their first dice for every slot of the same type before them",
		sub_image: 12,
		state: { buffed_list: ds_list_create() },
	    trigger: function(event, data) {
	        switch (event) {
				case "on_turn_start":
					for (var i = 0; i < ds_list_size(self.state.buffed_list); i++) {
						if (self.state.buffed_list[| i] > 0) {
							var slot = oCombat.action_queue[| i];
							slot.bonus_amount -= self.state.buffed_list[| i];
							self.state.buffed_list[| i] = 0;
						}
					}
				case "after_new_slot_created":
				case "on_dice_played_to_slot":
					ds_list_clear(self.state.buffed_list);
					
					repeat (ds_list_size(oCombat.action_queue)) {
						ds_list_add(self.state.buffed_list, 0);
					}
					
					show_debug_message(ds_list_size(self.state.buffed_list));
				break;
				
				case "after_change_current_action":
					for (var i = 0; i < ds_list_size(self.state.buffed_list); i++) {
						if (self.state.buffed_list[| i] > 0) {
							var slot = oCombat.action_queue[| i];
							slot.bonus_amount -= self.state.buffed_list[| i];
							self.state.buffed_list[| i] = 0;
						}
					}
				break;
				
		        case "on_roll_die":
					var last_type = "";
					var streak = 0;
					
					if (room == rmCombat) {
						for (var i = 0; i < ds_list_size(oCombat.action_queue); i++) {
							var slot = oCombat.action_queue[| i];
							var bonus_before = slot.bonus_amount;
							
							if (slot.current_action_type == last_type) {
								streak++;
							} else {
								streak = 0;
							}
							
							if (self.state.buffed_list[| i] == 0) {
								self.state.buffed_list[| i] = streak;
								slot.bonus_amount = self.state.buffed_list[| i];
							}
							
							last_type = slot.current_action_type;
							//show_debug_message("Slot buffed list amount " + string(i) + ":" + string(self.state.buffed_list[| i]));
							//show_debug_message("Slot bonus amount " + string(i) + ":" + string(oCombat.action_queue[| i].bonus_amount));
						}
					}
		        break;
				
				case "on_combat_end":
					ds_list_clear(self.state.buffed_list);
				break;
			}
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_repeater_rail);
	ds_list_add(global.rollable_keepsake_list, ks_repeater_rail);
	
	// ------------------
	// KEYWORD KEEPSAKES
	// ------------------
	
	ks_chainmasters_anchor = {
	    _id: "chainmasters_anchor",
	    name: "Chainmaster's Anchor",
	    desc: "First Followthrough effect each turn triggers twice.",
	    sub_image: 3,
		state: { effect_used: false, first_die: undefined },
	    trigger: function(event, data) {
	        if (event == "on_roll_die") {
				if (string_has_keyword(data.die.description, "Followthrough")) {
					if (self.state.first_die == undefined) {
						self.state.first_die = data.die;
					}
					
					if (data.die == self.state.first_die) {
						data.repeat_followthrough = true;
					}
					
					if (!data.read_only && !self.state.effect_used) {
						self.state.effect_used = true;
				
						trigger_keepsake_visual();
					}
				}
			}
			
			if (event == "on_player_turn_end") {
	            self.state.effect_used = false;
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_chainmasters_anchor);
	ds_list_add(global.rollable_keepsake_list, ks_chainmasters_anchor);
	
	ks_lantern_of_patience = {
	    _id: "lantern_of_patience",
	    name: "Lantern of Patience",
	    desc: "Each unused die grants +2 block at the end of turn",
	    sub_image: 4,
		state: { },
	    trigger: function(event, data) {			
			if (event == "on_not_used") {
				repeat (instance_number(oDice)) {
					with (oCombat) process_action("player", 0, 2, 0, "player", undefined, "BLK");
				}
				
				trigger_keepsake_visual();
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_lantern_of_patience);
	ds_list_add(global.rollable_keepsake_list, ks_lantern_of_patience);
	
	ks_windbound_charm = {
	    _id: "windbound_charm",
	    name: "Windbound Charm",
	    desc: "Stowaway effects also trigger when played",
	    sub_image: 15,
		state: { },
	    trigger: function(event, data) {			
			if (event == "on_dice_played_to_slot") {
				trigger_die_effects_single(data._d_struct, "on_not_used", data);
				
				trigger_keepsake_visual();
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_windbound_charm);
	ds_list_add(global.rollable_keepsake_list, ks_windbound_charm);
	
	ks_lead_line = {
	    _id: "lead_line",
	    name: "Lead Line",
	    desc: "'When played' effects also trigger twice when sacrificed",
	    sub_image: 17,
		state: { },
	    trigger: function(event, data) {			
			if (event == "on_sacrifice_die") {
				data._slot = -1;
				data._slot_num = -1;
				data._d_struct = data.die.struct;
				data.dice_object = data.die;
				data._die_struct = data.die.struct;
				
				repeat (2) {
					combat_trigger_effects("on_dice_played_to_slot", data);
				}
				
				trigger_keepsake_visual();
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_lead_line);
	ds_list_add(global.rollable_keepsake_list, ks_lead_line);
	
	ks_friendship_bracelet = {
	    _id: "friendship_bracelet",
	    name: "Friendship Bracelet",
	    desc: "On pickup, choose a die in your bag to gain Favourite",
	    sub_image: 16,
		state: { },
	    trigger: function(event, data) {			
			if (event == "on_keepsake_acquired" && data.keepsake_id == _id) {
	            // Need to add choosing functionality
				oRunManager.dice_selection = 1;
				oRunManager.dice_selection_message = "Choose 1 dice to add Favourite to.";
				oRunManager.dice_selection_event = function(_die) {
					var old_desc = _die.description;
					_die.description = "Favourite. " + old_desc;
				}
				
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_friendship_bracelet);
	ds_list_add(global.rollable_keepsake_list, ks_friendship_bracelet);
	
	
	// ------------------
	// ROLL KEEPSAKES
	// ------------------
	
	ks_topographic_map = {
	    _id: "topographic_map",
	    name: "Topographic Map",
	    desc: "If a die rolls its max, the next dice in that slot has its minimum roll increased by 2.",
	    sub_image: 20,
		state: { },
	    trigger: function(event, data) {			
			if (event == "after_roll_die") {
				if (data._d_amount == data.max_roll) {
					// next dice in sequence roll_twice = true
					if (data.dice_index != ds_list_size(data._slot.dice_list) - 1) {
						var next_die = data._slot.dice_list[| data.dice_index+1];
						
						if (next_die.dice_value != 2) {
							next_die.reset_after_next_roll = function(_dice) {
								_dice.min_roll_bonus -= 2;
							}
							next_die.min_roll_bonus += 2;
						} else {
							next_die.reset_after_next_roll = function(_dice) {
								_dice.min_roll_bonus -= 1;
							}
							next_die.min_roll_bonus += 1;
						}
						
						next_die.reset_this_turn = true;
				
						trigger_keepsake_visual();
					}
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_topographic_map);
	ds_list_add(global.rollable_keepsake_list, ks_topographic_map);
	
	ks_nav_chart = {
	    _id: "nav_chart",
	    name: "Navigation Chart",
	    desc: "Every time a die rolls its minimum, roll the next die twice.",
	    sub_image: 19,
		state: { },
	    trigger: function(event, data) {			
			if (event == "after_roll_die") {
				if (data._d_amount == data.min_roll) {
					// next dice in sequence roll_twice = true
					if (data.dice_index != ds_list_size(data._slot.dice_list) - 1) {
						data._slot.dice_list[| data.dice_index+1].roll_twice = true;
				
						trigger_keepsake_visual();
					} else if (data.slot_num != ds_list_size(oCombat.action_queue) -1) {
						oCombat.action_queue[| data.slot_num + 1].dice_list[| 0].roll_twice = true;
				
						trigger_keepsake_visual();
					}
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_nav_chart);
	ds_list_add(global.rollable_keepsake_list, ks_nav_chart);
	
	ks_balancing_compass = {
	    _id: "balancing_compass",
	    name: "Balancing Compass",
	    desc: "After a dice rolls its minimum, guarantee it rolls its maximum next turn.",
	    sub_image: 18,
		state: { },
	    trigger: function(event, data) {			
			if (event == "after_roll_die") {
				if (data._d_amount == data.min_roll) {
					data.die.reset_after_next_roll = function(_dice) {
						_dice.forced_roll = -1;
					}
					data.die.forced_roll = data.max_roll;
					data.die.reset_this_turn = false;
					show_debug_message("this die's forced roll is set to: " + string(data.die.forced_roll));
				
					trigger_keepsake_visual();
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_balancing_compass);
	ds_list_add(global.rollable_keepsake_list, ks_balancing_compass);
	
	// ------------------
	// DICE KEEPSAKES
	// ------------------
	
	ks_message_in_a_bottle = {
	    _id: "message_in_a_bottle",
	    name: "Message in a Bottle",
	    desc: "Gain a random dice at the start of combat.",
	    sub_image: 1,
	    trigger: function(event, data) {
	        if (event == "on_turn_start") {
	            if (oCombat.turn_count == 1) {
					// Grab a random dice in the master dice list
					var d = clone_die(global.master_dice_list[| irandom(ds_list_size(global.master_dice_list)-1)], "");
					
					var die_inst = instance_create_layer(display_get_gui_width()/2, display_get_gui_height(), "Instances", oDice);
					die_inst.struct = d;
					die_inst.action_type = d.action_type;
					die_inst.dice_amount = d.dice_amount;
					die_inst.dice_value  = d.dice_value;
					die_inst.possible_type = d.possible_type;
					die_inst.can_discard = true;

					var target = generate_valid_targets(1, 100) [0];
					die_inst.target_x = target[0];
					die_inst.target_y = target[1];
					
					die_inst.struct.reset_at_end_combat = function(_dice) {
						ds_list_delete(global.dice_bag, ds_list_find_index(global.dice_bag, _dice));
					}
				
					trigger_keepsake_visual();
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_message_in_a_bottle);
	ds_list_add(global.rollable_keepsake_list, ks_message_in_a_bottle);
	
	ks_polished_sextant = {
	    _id: "polished_sextant",
	    name: "Polished Sextant",
	    desc: "+1 minimum roll on all d4s.",
	    sub_image: 21,
		state: { },
	    trigger: function(event, data) {			
			if (event == "on_roll_die") {
				if (data.max_roll == 4) {
					data.min_roll += 1;
					
					if (!data.read_only) {
						trigger_keepsake_visual();
					}
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_polished_sextant);
	ds_list_add(global.rollable_keepsake_list, ks_polished_sextant);
	
	ks_shield_plating = {
	    _id: "shield_plating",
	    name: "Shield Plating",
	    desc: "+1 minimum roll on all Block die.",
	    sub_image: 39,
		state: { },
	    trigger: function(event, data) {			
			if (event == "on_roll_die") {
				if (data.action_type == "BLK") {
					data.min_roll += 1;
					
					if (!data.read_only) {
						trigger_keepsake_visual();
					}
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_shield_plating);
	ds_list_add(global.rollable_keepsake_list, ks_shield_plating);
	
	ks_weapon_polish = {
	    _id: "weapon_polish",
	    name: "Weapon Polish",
	    desc: "+1 minimum roll on all Attack die.",
	    sub_image: 40,
		state: { },
	    trigger: function(event, data) {			
			if (event == "on_roll_die") {
				if (data.action_type == "ATK") {
					data.min_roll += 1;
					
					if (!data.read_only) {
						trigger_keepsake_visual();
					}
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_weapon_polish);
	ds_list_add(global.rollable_keepsake_list, ks_weapon_polish);
	
	ks_crossword_puzzle = {
	    _id: "crossword_puzzle",
	    name: "Crossword Puzzle",
	    desc: "+1 minimum roll on all Neutral die.",
	    sub_image: 41,
		state: { },
	    trigger: function(event, data) {			
			if (event == "on_roll_die") {
				if (data.action_type == "None") {
					data.min_roll += 1;
					
					if (!data.read_only) {
						trigger_keepsake_visual();
					}
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_crossword_puzzle);
	ds_list_add(global.rollable_keepsake_list, ks_crossword_puzzle);
	
	ks_book_of_secrets = {
	    _id: "book_of_secrets",
	    name: "Book of Secrets",
	    desc: "+1 minimum roll on all Intel die.",
	    sub_image: 42,
		state: { },
	    trigger: function(event, data) {			
			if (event == "on_roll_die") {
				if (data.action_type == "INTEL") {
					data.min_roll += 1;
					
					if (!data.read_only) {
						trigger_keepsake_visual();
					}
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_book_of_secrets);
	ds_list_add(global.rollable_keepsake_list, ks_book_of_secrets);
	
	ks_lucky_coin = {
	    _id: "lucky_coin",
	    name: "Lucky Coin",
	    desc: "Coins roll 2s twice as often as 1s",
	    sub_image: 0,
		state: { },
	    trigger: function(event, data) {			
			if (event == "on_roll_die") {
				if (data.max_roll == "2") {
					data.weighting = "loaded";
					
					if (!data.read_only) {
						trigger_keepsake_visual();
					}
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_lucky_coin);
	ds_list_add(global.rollable_keepsake_list, ks_lucky_coin);
	
	ks_protective_rigging = {
	    _id: "protective_rigging",
	    name: "Protective Rigging",
	    desc: "Gain +2 block every time you play a die.",
	    sub_image: 26,

	    trigger: function(event, data) {
	        // IMPORTANT: `self` here is the keepsake struct itself — no need for `var that`
	        switch (event) {
	            case "on_dice_played_to_slot":
					with (oCombat) {
						process_action("player", 0, 2, 0, "player", undefined, "BLK");
					}
					
					trigger_keepsake_visual();
				break;
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_protective_rigging);
	ds_list_add(global.rollable_keepsake_list, ks_protective_rigging);
	
	ks_captains_ledger = {
	    _id: "captains_ledger",
	    name: "Captain's Ledger",
	    desc: "Whenever you draw the last die from your bag, deal 5 damage to all enemies and gain 3 gold.",
	    sub_image: 22,
	    trigger: function(event, data) {
	        // IMPORTANT: `self` here is the keepsake struct itself — no need for `var that`
	        switch (event) {
	            case "on_bag_empty":
					with (oCombat) {
						// Deal flat damage to all enemies, we have to run this backwards in case any enemies die during this roll
						for (var i = oCombat.enemies_left_this_combat-1; i >= 0 ; i--) {
							process_action(oCombat.room_enemies[| i], 0, 5, 0, "player", -1, "ATK", undefined, undefined, 0);
						}
					}
					gain_coins(200, display_get_gui_height() - 100, 3);
					trigger_keepsake_visual();
				break;
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_captains_ledger);
	ds_list_add(global.rollable_keepsake_list, ks_captains_ledger);
	
	ks_rusty_rudder = {
	    _id: "rusty_rudder",
	    name: "Rusty Rudder",
	    desc: "Whenever a die rolls its minimum value, deal equal damage to a random enemy.",
	    sub_image: 23,
	    trigger: function(event, data) {
	        // IMPORTANT: `self` here is the keepsake struct itself — no need for `var that`
	        switch (event) {
	            case "after_roll_die":
					if (data._d_amount == data.min_roll) {
						with (oCombat) {
							var rand_index = irandom(ds_list_size(room_enemies) - 1);
							process_action(room_enemies[| rand_index], 0, data._d_amount + data.slot_bonus + data.keepsake_bonus, 0, "player", -1, "ATK", undefined, undefined, 0);
						}
						
						trigger_keepsake_visual();
	
					}
				break;
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_rusty_rudder);
	ds_list_add(global.rollable_keepsake_list, ks_rusty_rudder);
	
	// ------------------
	// OTHER KEEPSAKES
	// ------------------	
	
	ks_eye_patch = {
	    _id: "eye_patch",
	    name: "Eye patch",
	    desc: "Gain 1 intel every time you play a die.",
	    sub_image: 2,

	    trigger: function(event, data) {
	        // IMPORTANT: `self` here is the keepsake struct itself — no need for `var that`
	        switch (event) {

	            case "on_dice_played_to_slot":
					oCombat.player_intel += 1;
					var num = spawn_floating_number("player", 1, -1, global.color_intel, 1, -1, 0);
					num.x += 20;
					num.y -= 20;
					particle_emit( num.x, num.y, "rise", global.color_intel);
					
					trigger_keepsake_visual();
				break;
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_eye_patch);
	ds_list_add(global.rollable_keepsake_list, ks_eye_patch);
	
	// ------------------
	// BOSS KEEPSAKES
	// ------------------	
	
	ks_krakens_grasp = {
	    _id: "krakens_grasp",
	    name: "Kraken's Grasp",
	    desc: "+1 dice playable per turn, draw 1 less dice per turn",
		sub_image: 34,
	    trigger: function(event, data) {
	        if (event == "on_turn_start") {
	            data.bonus_dice += 1;
				oCombat.dice_to_deal -= 1;
				
				trigger_keepsake_visual();
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_krakens_grasp);
	ds_list_add(global.boss_keepsake_list, ks_krakens_grasp);
	
	ks_deep_lens = {
	    _id: "deep_lens",
	    name: "Deep Lens",
	    desc: "Start the first 2 turns of combat with 12 Intel, replaces starting keepsake",
		sub_image: 35,
	    trigger: function(event, data) {
	        if (event == "on_turn_start") {
	            if (oCombat.turn_count <= 2) {
					oCombat.player_intel = 12;
					trigger_keepsake_visual();
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_deep_lens);
	ds_list_add(global.boss_keepsake_list, ks_deep_lens);
	
	ks_scavengers_tear = {
	    _id: "scavengers_tear",
	    name: "Scavenger's Tear",
	    desc: "Choose 2 dice to remove from your bag",
		sub_image: 36,
	    trigger: function(event, data) {
	        if (event == "on_keepsake_acquired" && data.keepsake_id == _id) {
				oRunManager.dice_selection = 2;
				oRunManager.dice_selection_message = "Choose 2 dice to remove";
				oRunManager.dice_selection_event = function(_die) {
					var _ind = ds_list_find_index(global.dice_bag, _die);
					
					ds_list_delete(global.dice_bag, _ind);
				}
				
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_scavengers_tear);
	ds_list_add(global.boss_keepsake_list, ks_scavengers_tear);
	
	ks_medallion_of_the_deep = {
	    _id: "medallion_of_the_deep",
	    name: "Medallion of the Sea",
	    desc: "+1 dice playable per turn if you have extreme alignment",
		sub_image: 37,
	    trigger: function(event, data) {
	        if (event == "on_turn_start") {
				if (global.player_alignment < 20 || global.player_alignment > 80) {
					data.bonus_dice += 1;
					
					trigger_keepsake_visual();
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_medallion_of_the_deep);
	ds_list_add(global.boss_keepsake_list, ks_medallion_of_the_deep);
	
	ks_cursed_heart = {
	    _id: "cursed_heart",
	    name: "Cursed Heart",
	    desc: "Slots cost 1 more die to create",
		sub_image: 38,
	    trigger: function(event, data) {
	        if (event == "on_combat_started") {
				oCombat.slot_cost_modifier += 1;
					
				trigger_keepsake_visual();
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_cursed_heart);
	ds_list_add(global.boss_keepsake_list, ks_cursed_heart);
}

function get_keepsake_by_id(_id) {
	for (var k = 0; k < ds_list_size(global.master_keepsake_list); k++) {
		if (global.master_keepsake_list[| k]._id == _id) {
			return global.master_keepsake_list[| k];
		}
	}
}

/// @func gain_keepsake(_keepsake_struct, _list)
/// @param _list	The list to remove this keepsake from
function gain_keepsake(_keepsake_struct, _list = undefined) {
	with (oRunManager) {
		ds_list_add(keepsakes, _keepsake_struct);
	
		if (_list != undefined) {
			show_debug_message("Removing keepsake from list: " + string(_list));
			var keepsake_id  = string(_keepsake_struct._id);
			
			show_debug_message("Item to remove: " + string(keepsake_id));
			var index = -1;
			
			for (var i = 0; i < ds_list_size(_list); i++) {
				if (_list[| i]._id == keepsake_id) {
					index = i;
					break;
				}
			}
			
			show_debug_message("Index found " + string(index));
		
			ds_list_delete( _list, index); // remove from future shop keepsakes
			show_debug_message("List length is now: " + string(ds_list_size(_list)));
		}
	}
	
	var ctx = {
		keepsake_id: _keepsake_struct._id,
	}
	
	runmanager_trigger_keepsakes("on_keepsake_acquired", ctx);
}