// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function define_keepsakes() {
	global.master_keepsake_list = ds_list_create();


	// ------------------
	// STARTER KEEPSAKES
	// ------------------
	ks_looking_glass = {
	    _id: "looking_glass",
	    name: "Looking Glass",
	    desc: "Start each combat with 6 intel",
		sub_image: 0,
	    trigger: function(event, data) {
	        if (event == "on_turn_start") {
	            if (oCombat.turn_count == 1) oCombat.player_intel = 6;
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_looking_glass);
	
	// ------------------
	// EVENT KEEPSAKES
	// ------------------
	
	ks_small_sail = {
	    _id: "small_sail",
	    name: "Small Sail",
	    desc: "Draw 2 additional dice at the start of combat",
		sub_image: 0,
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
	
	ks_repaired_sail = {
	    _id: "repaired_sail",
	    name: "Repaired Sail",
	    desc: "Heal 1 at the start of each combat",
		sub_image: 0,
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
	ds_list_add(global.master_keepsake_list, ks_repaired_sail);
	
	ks_deckhands_token = {
	    _id: "deckhands_token",
	    name: "Deckhand's Token",
	    desc: "First dice in slot 1 gets +1 bonus",
		sub_image: 0,
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
		sub_image: 0,
	    trigger: function(event, data) {
	        if (event == "on_combat_end") {
	            for (var i = 0; i < ds_list_size(oCombat.action_queue); i++) {
					gain_coins(oCombat.slot_positions[| i].x, oCombat.slot_positions[| i].y, 3);
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_black_purse);
	
	ks_shipwrights_draft = {
	    _id: "shipwrights_draft",
	    name: "Shipwright's Draft",
	    desc: "When new slots are created, gain 1 more dice playable that turn",
		sub_image: 0,
	    trigger: function(event, data) {
	        if (event == "on_new_slot_created") {
	            oCombat.dice_allowed_this_turn_bonus++;
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_shipwrights_draft);
	
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
	
	ks_ghost_lantern = {
	    _id: "ghost_lantern",
	    name: "Ghost Lantern",
	    desc: "Not yet defined.",
	    sub_image: 4,

	    trigger: function(event, data) {
	        // IMPORTANT: `self` here is the keepsake struct itself — no need for `var that`
	        switch (event) {

	            case "on_turn_start":
				break;
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_ghost_lantern);
	
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