// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
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
	            if (oCombat.turn_count == 1) oCombat.player_intel = 6;
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
		price: 100,
	    trigger: function(event, data) {
	        if (event == "on_rest") { // make sure we only trigger when we acquire THIS keepsake, not all keepsakes
	            data.rest_amount += 0.10;
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
	            if (oCombat.turn_count == 0) {
					oCombat.dice_allowed_this_turn_bonus = 1;
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_pickled_cucumber);
	ds_list_add(global.shop_keepsake_list, ks_pickled_cucumber);
	
	
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
					}
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_small_sail);
	
	ks_rope_of_repair = {
	    _id: "rope_of_repair",
	    name: "Rope of Repair",
	    desc: "Heal 1 at the start of each combat",
		sub_image: 7,
	    trigger: function(event, data) {
	        if (event == "on_turn_start") {
	            if (global.player_hp < global.player_max_hp) {
					if (oCombat.turn_count == 1) {
						process_action( "player", 0, 1, 0, "player", undefined, "HEAL");
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
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_deckhands_token);
	
	ks_starvers_efficiency = {
	    _id: "starvers_efficiency",
	    name: "Starver's Efficiency",
	    desc: "The first block you play each turn rolls twice and takes the higher value",
		sub_image: 0,
		state: { effect_used: false },
	    trigger: function(event, data) {
	        if (event == "on_roll_die") {
	            if (!self.state.effect_used && data.action_type == "BLK" && !data.read_only) {
					data.roll_twice = true;
					self.state.effect_used = true;
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
	    desc: "At the end of combat gain 3 coins for every slot in your action queue",
		sub_image: 9,
	    trigger: function(event, data) {
	        if (event == "on_combat_end") {
	            for (var i = 0; i < ds_list_size(oCombat.action_queue); i++) {
					gain_coins(oCombat.slot_positions[| i].x, oCombat.slot_positions[| i].y, 3);
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
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_shipwrights_draft);
	ds_list_add(global.rollable_keepsake_list, ks_shipwrights_draft);
	
	ks_cannon_splitter = {
	    _id: "cannon_splitter",
	    name: "Cannon Splitter",
	    desc: "Your first attack slot hits all other enemies for 25%",
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
							if (i != enemy_target_index) process_action(oCombat.room_enemies[| i], 0, floor(data.final_amount / 4), 0, "player", -1, "ATK", undefined, undefined, 0);
						}
					}
					self.state.used = true;
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
			if (event == "on_dice_played_to_slot" || event == "on_new_slot_created")  {
				if (string_pos(" ", data._slot.possible_type) == 0) {
					data._slot.bonus_amount += 1;
					data._slot.buffed += 1;
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
	    desc: "Subsequent slots gain +1 to their first dice for every slot of the same type before them",
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
						show_debug_message("Slot buffed list amount " + string(i) + ":" + string(self.state.buffed_list[| i]));
						show_debug_message("Slot bonus amount " + string(i) + ":" + string(oCombat.action_queue[| i].bonus_amount));
					}
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
				oCombat.player_block_amount += 2 * instance_number(oDice);
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_lantern_of_patience);
	ds_list_add(global.rollable_keepsake_list, ks_lantern_of_patience);
	
	
	// ------------------
	// ROLL KEEPSAKES
	// ------------------
	
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
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_message_in_a_bottle);
	ds_list_add(global.rollable_keepsake_list, ks_message_in_a_bottle);
	
	ks_eye_patch = {
	    _id: "eye_patch",
	    name: "Eye patch",
	    desc: "Not yet defined.",
	    sub_image: 2,

	    trigger: function(event, data) {
	        // IMPORTANT: `self` here is the keepsake struct itself — no need for `var that`
	        switch (event) {

	            case "on_turn_start":
				break;
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_eye_patch);
	ds_list_add(global.rollable_keepsake_list, ks_eye_patch);
	
	//var ks_message_in_a_bottle = {
	//    _id: "message_in_a_bottle",
	//    name: "Message in a Bottle",
	//    desc: "Discover a random dice at the start of combat.",
	//    sub_image: 1,
	//    state: { last_type: "", streak: 0, buff_ready: false },

	//    trigger: function(event, data) {
	//        // IMPORTANT: `self` here is the keepsake struct itself — no need for `var that`
	//        switch (event) {

	//            case "on_action_used":
	//                if (is_undefined(data) || !variable_struct_exists(data, "action_type")) {
	//                    show_debug_message("⚠️ Invalid data passed to keepsake trigger: " + string(data));
	//                    break;
	//                }

	//                var t = data.action_type;
	//                if (t == self.state.last_type) {
	//                    self.state.streak++;
	//                    show_debug_message("Cutlass streak: " + string(self.state.streak));
	//                } else {
	//                    self.state.streak = 1;
	//                    self.state.last_type = t;
	//                }

	//                if (self.state.streak >= 3) {
	//                    self.state.streak = 0;
	//                    self.state.last_type = "";
	//                    self.state.buff_ready = true;
	//                    show_debug_message("Cutlass buff ready!");
	//                }
	//            break;

	//            case "on_roll_die":
	//                if (self.state.buff_ready && data.action_type == "ATK") {
	//                    show_debug_message("Cutlass buff triggered! +4 damage");
	//                    data._d_amount += 4;
	//                    self.state.buff_ready = false;
	//                }
	//            break;
				
	//			case "on_player_turn_end":
	//				self.state.streak = 0;
	//			break;
	//        }
	//    }
	//};
	//ds_list_add(oRunManager.keepsakes_master, ks_blooded_cutlass);
}

function get_keepsake_by_id(_id) {
	for (var k = 0; k < ds_list_size(global.master_keepsake_list); k++) {
		if (global.master_keepsake_list[| k]._id == _id) {
			return global.master_keepsake_list[| k];
		}
	}
}

function gain_keepsake(_keepsake_struct) {
	ds_list_add(oRunManager.keepsakes, _keepsake_struct);
	
	var ctx = {
		keepsake_id: _keepsake_struct._id,
	}
	
	runmanager_trigger_keepsakes("on_keepsake_acquired", ctx);
}