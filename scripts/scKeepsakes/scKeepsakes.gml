// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

function trigger_keepsake_visual() {
	var index = ds_list_find_index(oRunManager.keepsakes, self);
	if (index == -1) return; // a keepsake that isn't in the bar (yet)
	oRunManager.keepsake_scale[| index] = 2.0;
	self.flash_time = current_time; // its name floats up under its icon (oRunManager Draw GUI, F15)
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
	    desc: "Start each combat with 6 ink.",
		sub_image: 5,
	    trigger: function(event, data) {
	        if (event == "on_turn_start") {
	            if (oCombat.turn_count == 1) {
					oCombat.player_intel = max(oCombat.player_intel, 6); // never lowers insight you already had
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
	    desc: "Gain 10 max health.",
		sub_image: 28,
		price: 80,
	    trigger: function(event, data) {
	        if (event == "on_keepsake_acquired" && data.keepsake_id == _id) { // make sure we only trigger when we acquire THIS keepsake, not all keepsakes
				global.player_max_hp += 10; // F242: no health lost; the bar grows, you don't heal
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_lime_juice);
	ds_list_add(global.shop_keepsake_list, ks_lime_juice);
	
	ks_salted_pork = {
	    _id: "salted_pork",
	    name: "Salted Pork",
	    desc: "Heal 15% more when you rest.",
		sub_image: 29,
		price: 90,
	    trigger: function(event, data) {
	        if (event == "on_rest") { // make sure we only trigger when we acquire THIS keepsake, not all keepsakes
	            data.rest_amount += 0.15; // F242: was 10%
				
				trigger_keepsake_visual();
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_salted_pork);
	ds_list_add(global.shop_keepsake_list, ks_salted_pork);
	
	ks_pickled_cucumber = {
	    _id: "pickled_cucumber",
	    name: "Pickled Cucumber",
	    desc: "+1 play and draw 1 more on the first turn of combat.",
		sub_image: 33,
		price: 100,
	    trigger: function(event, data) {
	        if (event == "on_turn_start") {
	            if (oCombat.turn_count == 1) {
					data.bonus_dice += 1;
					if (!oCombat.is_dealing_dice) oCombat.dice_to_deal += 1; // F242: and a draw
								
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
	    desc: "+2 item slots.",
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
	    desc: "Attack dice get +1 max roll.",
	    sub_image: 30,
		price: 110,
	    trigger: function(event, data) {
			if (event == "on_roll_die") {
				if (data.die.action_type == "ATK") { // the die's own type, as dealt and as resolved (B163)
					data.max_roll += 1; // F242: no minus any more (it was worth nothing on average)
					
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
	    desc: "When you drink a potion, heal 3 and draw a die.",
	    sub_image: 31,
		price: 110,
	    trigger: function(event, data) {			
			if (event == "on_consumable_used") {
	            if (global.player_hp < global.player_max_hp) {
					var amount = 3;
					process_action("player", 0, amount, 0, "player", undefined, "HEAL");
					
					trigger_keepsake_visual();
				}
				// F242: and a die, in a fight
				if (room == rmCombat && instance_exists(oCombat)) { oCombat.dice_to_deal += 1; oCombat.is_dealing_dice = true; }
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_rations);
	ds_list_add(global.shop_keepsake_list, ks_rations);
	
	ks_water_barrel = {
	    _id: "water_barrel",
	    name: "Water Barrel",
	    desc: "Potions have a 50% chance not to be used up.",
	    sub_image: 32,
		price: 120,
	    trigger: function(event, data) {			
			if (event == "on_consumable_used") {
				var random_chance = irandom(9);
				
				if (random_chance <= 4) { // 50% (F242: was 30%)
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
	    desc: "Draw 1 more die each turn.",
		sub_image: 6,
	    trigger: function(event, data) {
	        if (event == "on_turn_start" && !oCombat.is_dealing_dice) { // F242: was 2 more on turn 1 only
				oCombat.dice_to_deal += 1;
				trigger_keepsake_visual();
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_small_sail);
	
	ks_rope_of_repair = {
	    _id: "rope_of_repair",
	    name: "Rope of Repair",
	    desc: "Heal 3 at the start of each combat.",
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
	    desc: "The first die in slot 1 gets +1.",
		sub_image: 8,
	    trigger: function(event, data) {
	        if (event == "on_roll_die") {
	            if (data.slot_num == 0 && data.die == oCombat.action_queue[| data.slot_num].dice_list[| 0]) {
					data._d_amount += 1; // a bonus, live in the slot (its roll is already made)
				
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
	    desc: "The first Block die dealt each turn rolls twice and keeps the higher.",
		sub_image: 43,
		state: { effect_used: false },
	    trigger: function(event, data) {
	        if (event == "on_roll_die") {
	            if (!self.state.effect_used && data.action_type == "BLK" && variable_struct_exists(data, "on_deal") && data.on_deal) { // as it's dealt (die_roll_faces)
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
	    desc: "After combat, gain 3 gold per slot.",
		sub_image: 9,
		state: { slots: 0 },
	    trigger: function(event, data) {
			// the most slots you had at a turn's end this fight (built slots are taken down before the fight ends, so it
			// always paid for 1: B163)
			if (event == "on_turn_start" && data.turn_count <= 1) self.state.slots = 0; // a new fight (one left early mustn't carry over)
			if (event == "on_player_turn_end") self.state.slots = max(self.state.slots, ds_list_size(oCombat.action_queue));
	        if (event == "on_combat_end") {
				var _n = max(self.state.slots, ds_list_size(oCombat.action_queue));
				var _sp = (ds_list_size(oCombat.slot_positions) > 0) ? oCombat.slot_positions[| 0] : { x: display_get_gui_width() / 2, y: display_get_gui_height() / 2 };
	            for (var i = 0; i < _n; i++) gain_coins(_sp.x + i * 40, _sp.y, 3);
				if (_n > 0) trigger_keepsake_visual();
				self.state.slots = 0;
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_black_purse);
	ds_list_add(global.rollable_keepsake_list, ks_black_purse);
	
	ks_shipwrights_draft = {
	    _id: "shipwrights_draft",
	    name: "Shipwright's Draft",
	    desc: "The first slot you build each turn gives 1 play.",
		sub_image: 10,
		state: { used: false },
	    trigger: function(event, data) {
	        if (event == "on_new_slot_created" && !self.state.used) { // F242: every build was free
	            oCombat.dice_allowed_this_turn_bonus++;
				self.state.used = true;
				trigger_keepsake_visual();
	        }
			if (event == "on_turn_start") self.state.used = false;
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_shipwrights_draft);
	ds_list_add(global.rollable_keepsake_list, ks_shipwrights_draft);
	
	ks_cannon_splitter = {
	    _id: "cannon_splitter",
	    name: "Cannon Splitter",
	    desc: "Your first attack slot each turn also hits other enemies for 75%.",
		sub_image: 11,
		state: {
			used: false,
			slot_num: -1,
		},
	    trigger: function(event, data) {
	        if (event == "after_slot_damage_calculated") {
	            if (data.type == "ATK" && data._slot_die != undefined && (!self.state.used || self.state.slot_num == data.slot_num)) {
	                with (oCombat) {
						// Deal flat damage to all enemies, we have to run this backwards in case any enemies die during this roll
						for (var i = ds_list_size(oCombat.room_enemies)-1; i >= 0 ; i--) {
							if (oCombat.room_enemies[| i].dead) continue;
							if (i != enemy_target_index) process_action(oCombat.room_enemies[| i], 0, floor(data.final_amount * 0.75), 0, "player", -1, "ATK", undefined, undefined, 0);
						}
					}
					self.state.used = true;
					self.state.slot_num = data.slot_num; // every die in this slot splashes, later attack slots don't
				
					trigger_keepsake_visual();
	            }
	        }
			
			if (event == "on_turn_start") {
	            self.state.used = false;
	            self.state.slot_num = -1;
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_cannon_splitter);
	ds_list_add(global.rollable_keepsake_list, ks_cannon_splitter);
	
	ks_bandage = {
	    _id: "bandage",
	    name: "Bandage",
	    desc: "When you're debuffed, your first slot gets +1 for the rest of combat.",
		sub_image: 14,
		state: {
			triggered: false,
		},
	    trigger: function(event, data) {
			
			if (event == "on_player_debuffed") {
				if (!self.state.triggered) {
					slot_add_bonus(oCombat.action_queue[| 0], "Bandage", 1, -1); // rest of the fight, stacks
				
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
	    desc: "The first die in each single-type slot gets +1.",
		sub_image: 13,
		state: {
		},
	    trigger: function(event, data) {
			// +1 to every slot that can only take one action type, worked out again whenever the queue changes
			if (event == "on_dice_played_to_slot" || event == "after_new_slot_created" || event == "on_turn_start" || event == "after_change_current_action") {
				for (var i = 0; i < ds_list_size(oCombat.action_queue); i++) {
					var _slot = oCombat.action_queue[| i];
					var _single = string_pos(" ", _slot.possible_type) == 0 && _slot.possible_type != "None" && _slot.possible_type != "";
					slot_set_bonus(_slot, "Single Focus", _single ? 1 : 0, "first"); // the slot's first die only, as its description says
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_single_focus);
	ds_list_add(global.rollable_keepsake_list, ks_single_focus);

	ks_repeater_rail = {
	    _id: "repeater_rail",
	    name: "Repeater Rail",
	    desc: "Each die in a slot gets +1 for every die before it.",
		sub_image: 12,
		state: { },
	    trigger: function(event, data) {
			// Q15 (2026-11-19): rewards stacking one slot, now slots are scarce. A die's place in its slot (die_index) is its
			// bonus; live in the slot's total (slot_get_total passes each die's index) and in the hover breakdown.
			if (event == "on_roll_die" && data.slot_num >= 0 && is_real(data.die_index) && data.die_index > 0) {
				data._d_amount += data.die_index;
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
	    desc: "Followthrough bonuses count twice.",
	    sub_image: 3,
		state: { effect_used: false, first_die: undefined },
	    trigger: function(event, data) {
	        if (event == "on_roll_die") {
				// only when a Followthrough die's effect actually fired this roll (its condition was met: it added to
				// the roll), and only the first time each turn. Previews show the doubled bonus while it's unused.
				if (!die_has_keyword(data.die, "Followthrough")) return; // every one now (F242), not just the first each turn
				var _fired = variable_struct_exists(data, "die_effects_added") && data.die_effects_added > 0;
				if (!_fired) return;
				data.repeat_followthrough = true;
				if (!data.read_only) {
					self.state.effect_used = true;
					trigger_keepsake_visual();
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
	    desc: "Each unused die gives 1 block at end of turn.",
	    sub_image: 4,
		state: { },
	    trigger: function(event, data) {			
			if (event == "on_not_used") {
				repeat (instance_number(oDice)) {
					with (oCombat) process_action("player", 0, 1, 0, "player", undefined, "BLK"); // F242: was 2
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
	    desc: "Stowaway effects also trigger when played.",
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
	    desc: "When a die builds a slot, its 'When played' effect triggers twice.",
	    sub_image: 17,
		state: { },
	    trigger: function(event, data) {
			// builders count as played now (F238), so their "when played" effect fires once anyway; Lead Line fires the
			// die's own once more, in the slot it built (it used to fire before the slot existed, so most dice did nothing)
			if (event == "on_builder_played" && die_has_effect_trigger(data._d_struct, "on_dice_played_to_slot")) {
				trigger_die_effects_single(data._d_struct, "on_dice_played_to_slot", data);
				trigger_keepsake_visual();
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_lead_line);
	ds_list_add(global.rollable_keepsake_list, ks_lead_line);
	
	ks_friendship_bracelet = {
	    _id: "friendship_bracelet",
	    name: "Friendship Bracelet",
	    desc: "Give a die Favourite.",
	    sub_image: 16,
		state: { },
	    trigger: function(event, data) {			
			if (event == "on_keepsake_acquired" && data.keepsake_id == _id) {
	            // Need to add choosing functionality
				oRunManager.dice_selection = 1;
				oRunManager.dice_selection_message = "Choose a die to gain Favourite.";
				oRunManager.dice_selection_event = function(_die) {
					die_add_keyword(_die, "Favourite"); // the keyword and its text together
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
	    desc: "When you play a max roll, its slot gets +2 this turn. When a die rolls its minimum, draw a die, at most twice a turn.",
	    sub_image: 20,
		state: { draws: 0, turn: -1 },
	    trigger: function(event, data) {
			// a valley: a die that rolls its lowest face draws you another (Q15), at most twice a turn so a run of 1s can't
			// chain on and on
			if (event == "on_die_rolled" && room == rmCombat && instance_exists(oCombat) && data.min_roll < data.max_roll && data.face <= data.min_roll) {
				if (self.state.turn != oCombat.turn_count) { self.state.turn = oCombat.turn_count; self.state.draws = 0; }
				if (self.state.draws < 2) {
					self.state.draws++;
					die_effect_popup(data._die_struct, "Valley!", global.color_gold);
					oCombat.dice_to_deal += 1;
					oCombat.is_dealing_dice = true;
					trigger_keepsake_visual();
				}
			}
			// rolled dice: the roll is known as it's played, so the bonus goes on its slot (live in the total)
			if (event == "on_dice_played_to_slot" && is_struct(data._d_struct) && is_struct(data._slot)) {
				var _out = get_dice_output(data._d_struct, -1, -1, true, "player");
				if (die_has_faces(data._d_struct) && die_face_total(data._d_struct) >= _out.max_roll) {
					slot_add_bonus(data._slot, "Topographic Map", 2, 1);
					trigger_keepsake_visual();
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_topographic_map);
	ds_list_add(global.rollable_keepsake_list, ks_topographic_map);
	
	ks_nav_chart = {
	    _id: "nav_chart",
	    name: "Navigation Chart",
	    desc: "When a die rolls its minimum, the next die you're dealt rolls twice and keeps the higher.",
	    sub_image: 19,
		state: { next_twice: false },
		is_armed: function() { return self.state.next_twice; }, // lit in the keepsake bar while waiting
	    trigger: function(event, data) {
			// rolled dice: a die rolls as it's dealt, so the minimum marks the next one dealt
			if (event == "on_die_rolled" && data.min_roll < data.max_roll && data.face <= data.min_roll) { // B163: guard as Balancing Compass has
				self.state.next_twice = true;
				trigger_keepsake_visual();
			}
			if (event == "on_roll_die" && self.state.next_twice && variable_struct_exists(data, "on_deal") && data.on_deal) {
				data.roll_twice = true;
				self.state.next_twice = false;
			}
			if (event == "on_player_turn_end") self.state.next_twice = false;
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_nav_chart);
	ds_list_add(global.rollable_keepsake_list, ks_nav_chart);
	
	ks_balancing_compass = {
	    _id: "balancing_compass",
	    name: "Balancing Compass",
	    desc: "When a die rolls its minimum, the next die you're dealt rolls its maximum.",
	    sub_image: 18,
		state: { next_max: false, landing: false },
		// lit in the keepsake bar while it's waiting for the next die (oRunManager Draw GUI)
		is_armed: function() { return self.state.next_max; },
	    trigger: function(event, data) {
			// rolled dice (Jared, 2026-11-20): dice roll as they're dealt, so a minimum now pays off on the next die dealt
			// (or rerolled with ink), not on the same die whenever it comes round again
			if (event == "on_combat_started") { self.state.next_max = false; self.state.landing = false; }
			if (event == "on_roll_die" && self.state.next_max && data.on_deal) {
				data.min_roll = data.max_roll; // it can only roll its max
				self.state.next_max = false;
				self.state.landing = true;
			}
			if (event == "on_die_rolled" && room == rmCombat && instance_exists(oCombat)) {
				// the max landing: say so over that die. (its min equals its max now, so it can't arm the compass again)
				if (self.state.landing) {
					self.state.landing = false;
					die_effect_popup(data._die_struct, "Balanced: max!", global.color_gold);
					trigger_keepsake_visual();
				} else if (data.min_roll < data.max_roll && data.face <= data.min_roll && !self.state.next_max) {
					self.state.next_max = true;
					die_effect_popup(data._die_struct, "Compass: next die max", global.color_gold);
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
	    desc: "Start each combat with a random extra die.",
	    sub_image: 1,
	    trigger: function(event, data) {
	        if (event == "on_turn_start") {
	            if (oCombat.turn_count == 1) {
					// Grab a random dice in the master dice list
					var d = clone_die(global.master_dice_list[| irandom(ds_list_size(global.master_dice_list)-1)], "");
					die_roll_faces(d); // it rolls as it comes, like every dealt die (it sat unrolled as "d4": B132, Molly's Surge die)

					var die_inst = instance_create_layer(display_get_gui_width()/2, display_get_gui_height(), "Instances", oDice);
					die_inst.struct = d;
					die_inst.roll_anim = 16; // it tumbles in, then shows its roll
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
				if (data.die.dice_value == 4) { // the die's size (B163: it read the max after other keepsakes, so bar order mattered)
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
	    desc: "+1 minimum roll on Block dice.",
	    sub_image: 39,
		state: { },
	    trigger: function(event, data) {			
			if (event == "on_roll_die") {
				if (data.die.action_type == "BLK") { // the die's own type (B163)
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
	    desc: "+1 minimum roll on Attack dice.",
	    sub_image: 40,
		state: { },
	    trigger: function(event, data) {			
			if (event == "on_roll_die") {
				if (data.die.action_type == "ATK") { // the die's own type (B163)
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
	    desc: "+1 minimum roll on Neutral dice.",
	    sub_image: 41,
		state: { },
	    trigger: function(event, data) {			
			if (event == "on_roll_die") {
				if (data.die.action_type == "None") {
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
	    desc: "+1 minimum roll on ink dice.",
	    sub_image: 42,
		state: { },
	    trigger: function(event, data) {			
			if (event == "on_roll_die") {
				if (data.die.action_type == "INTEL") { // the die's own type (B163)
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
	    desc: "Each coin you play gives 1 block.",
	    sub_image: 0,
		state: { },
	    trigger: function(event, data) {
			// F242: a Coin swarm payoff (it only nudged coins' odds)
			if (event == "on_dice_played_to_slot" && die_has_keyword(data._d_struct, "coin")) {
				with (oCombat) process_action("player", 0, 1, 0, "player", undefined, "BLK");
				trigger_keepsake_visual();
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_lucky_coin);
	ds_list_add(global.rollable_keepsake_list, ks_lucky_coin);
	
	ks_protective_rigging = {
	    _id: "protective_rigging",
	    name: "Protective Rigging",
	    desc: "Gain 1 block when you play a die.",
	    sub_image: 26,

	    trigger: function(event, data) {
	        // IMPORTANT: `self` here is the keepsake struct itself — no need for `var that`
	        switch (event) {
	            case "on_dice_played_to_slot":
					with (oCombat) {
						process_action("player", 0, 1, 0, "player", undefined, "BLK"); // F242: was 2, the strongest keepsake
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
	    desc: "When your bag runs out, deal 5 damage to all enemies and gain 3 gold.",
	    sub_image: 22,
	    trigger: function(event, data) {
	        // IMPORTANT: `self` here is the keepsake struct itself — no need for `var that`
	        switch (event) {
	            case "on_bag_empty":
					with (oCombat) {
						// Deal flat damage to all enemies, we have to run this backwards in case any enemies die during this roll
						for (var i = ds_list_size(oCombat.room_enemies)-1; i >= 0 ; i--) {
							if (oCombat.room_enemies[| i].dead) continue;
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
	    desc: "When a die rolls its minimum, deal that much damage to a random enemy.",
	    sub_image: 23,
	    trigger: function(event, data) {
	        // IMPORTANT: `self` here is the keepsake struct itself — no need for `var that`
	        switch (event) {
	            case "on_die_rolled": // when rolled: it hits as the die lands
					if (data.min_roll < data.max_roll && data.face > 0 && data.face <= data.min_roll) { // B163: a one-number die fired every roll
						data._d_amount = data.face; data.slot_bonus = 0; data.keepsake_bonus = 0; // the damage is the face
						// a random enemy still standing (B93: it could pick one already dead)
						var _alive = [];
						with (oCombat) {
							for (var e = 0; e < ds_list_size(room_enemies); e++) {
								if (!room_enemies[| e].dead) array_push(_alive, room_enemies[| e]);
							}
							if (array_length(_alive) > 0) {
								process_action(_alive[irandom(array_length(_alive) - 1)], 0, data._d_amount + data.slot_bonus + data.keepsake_bonus, 0, "player", -1, "ATK", undefined, undefined, 0);
							}
						}
						if (array_length(_alive) > 0) trigger_keepsake_visual();
	
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
	    desc: "Gain 1 ink next turn when you play a die.",
	    sub_image: 2,

	    trigger: function(event, data) {
	        // IMPORTANT: `self` here is the keepsake struct itself — no need for `var that`
	        switch (event) {

	            case "on_dice_played_to_slot":
					// insight gained during your turn arrives next turn, like an insight die's
					apply_buff("player", oRunManager.buff_intel, 1, 1, oRunManager.buff_intel.remove_next_turn, { source: "player", index: -1 });
					var num = spawn_floating_number("player", 1, -1, global.text_intel, 1, -1, 0);
					num.x += 20;
					num.y -= 20;
					particle_emit( num.x, num.y, "rise", global.text_intel);
					
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
	    desc: "+1 play and 1 fewer die drawn each turn.",
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
	    desc: "Start the first 2 turns of combat with 12 ink. Replaces the Looking Glass.",
		replaces: "looking_glass", // takes the starting keepsake's place in the keepsake bar
		sub_image: 35,
	    trigger: function(event, data) {
	        if (event == "on_turn_start") {
	            if (oCombat.turn_count <= 2) {
					oCombat.player_intel = max(oCombat.player_intel, 12);
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
	    desc: "Remove 2 dice from your bag.",
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
	    desc: "+1 play each turn while alignment is below 30 or above 70.",
		sub_image: 37,
	    trigger: function(event, data) {
	        if (event == "on_turn_start") {
				if (global.player_alignment < 30 || global.player_alignment > 70) { // F242: was 20 / 80
					data.bonus_dice += 1;
					
					trigger_keepsake_visual();
				}
	        }
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_medallion_of_the_deep);
	ds_list_add(global.boss_keepsake_list, ks_medallion_of_the_deep);

	// ===================================================================================================================
	// F242 content pass (Jared, 2026-11-23): new keepsakes (docs/design/content-pass.md). sub_image: placeholder art
	// borrowed from other keepsakes until Jared's art pass.
	// ===================================================================================================================
	ks_spirit_level = {
	    _id: "spirit_level",
	    name: "Spirit Level",
	    desc: "Dice that roll a middle face get +1.",
		sub_image: 21,
	    trigger: function(event, data) {
			if (event == "on_roll_die" && die_face_middle(die_face_total(data.die), data.min_roll, data.max_roll)) {
				data._d_amount += 1;
				if (!data.read_only) trigger_keepsake_visual();
			}
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_spirit_level);
	ds_list_add(global.rollable_keepsake_list, ks_spirit_level);

	ks_sounding_line = {
	    _id: "sounding_line",
	    name: "Sounding Line",
	    desc: "When a die rolls one below its max, draw a die.",
		sub_image: 17,
	    trigger: function(event, data) {
			if (event == "on_die_rolled" && data.max_roll - 1 > data.min_roll && data.face == data.max_roll - 1 && instance_exists(oCombat)) {
				oCombat.dice_to_deal += 1;
				oCombat.is_dealing_dice = true;
				trigger_keepsake_visual();
			}
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_sounding_line);
	ds_list_add(global.rollable_keepsake_list, ks_sounding_line);

	ks_sharpened_quill = {
	    _id: "sharpened_quill",
	    name: "Sharpened Quill",
	    desc: "Rerolls and redraws cost 2 ink.",
		sub_image: 42,
		price: 110,
	    trigger: function(event, data) { } // ink_cost_reroll reads it
	};
	ds_list_add(global.master_keepsake_list, ks_sharpened_quill);
	ds_list_add(global.shop_keepsake_list, ks_sharpened_quill);

	ks_captains_logbook = {
	    _id: "captains_logbook",
	    name: "Captain's Logbook",
	    desc: "Max ink 20. Rewriting an intent costs 4 ink.",
		sub_image: 42,
	    trigger: function(event, data) { } // intel_max and ink_cost_rewrite read it
	};
	ds_list_add(global.master_keepsake_list, ks_captains_logbook);
	ds_list_add(global.boss_keepsake_list, ks_captains_logbook);

	ks_iron_grip = {
	    _id: "iron_grip",
	    name: "Iron Grip",
	    desc: "While you have 10 or fewer dice, Might lasts until the end of the fight.",
		sub_image: 40,
		state: { might: 0 },
	    trigger: function(event, data) {
			// at the end of your turn, note your Might; it wears off at the round's end as usual, and comes back next turn
			if (event == "on_player_turn_end") {
				self.state.might = 0;
				for (var i = 0; i < ds_list_size(global.player_debuffs); i++) {
					var _b = global.player_debuffs[| i];
					if (_b.template._id == oRunManager.buff_might._id) self.state.might += _b.amount;
				}
			}
			if (event == "on_turn_start") {
				if (data.turn_count <= 1) self.state.might = 0; // a new fight
				else if (self.state.might > 0 && deck_size() <= 10) {
					apply_buff("player", oRunManager.buff_might, 1, self.state.might, false, { source: "player", index: -1 });
					trigger_keepsake_visual();
				}
				self.state.might = 0;
			}
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_iron_grip);
	ds_list_add(global.rollable_keepsake_list, ks_iron_grip);

	ks_war_drum = {
	    _id: "war_drum",
	    name: "War Drum",
	    desc: "Each turn, gain 1 Might for every die you have under 12.",
		sub_image: 11,
	    trigger: function(event, data) {
			if (event == "on_turn_start") {
				var _n = max(0, 12 - deck_size());
				if (_n > 0) {
					apply_buff("player", oRunManager.buff_might, 1, _n, false, { source: "player", index: -1 });
					trigger_keepsake_visual();
				}
			}
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_war_drum);
	ds_list_add(global.boss_keepsake_list, ks_war_drum);

	ks_heavy_rigging = {
	    _id: "heavy_rigging",
	    name: "Heavy Rigging",
	    desc: "Dice d8 or bigger get +2.",
		sub_image: 26,
	    trigger: function(event, data) {
			if (event == "on_roll_die" && data.die.dice_value >= 8) {
				data._d_amount += 2;
				if (!data.read_only) trigger_keepsake_visual();
			}
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_heavy_rigging);
	ds_list_add(global.rollable_keepsake_list, ks_heavy_rigging);

	ks_spiked_hull = {
	    _id: "spiked_hull",
	    name: "Spiked Hull",
	    desc: "When your Block fully stops an enemy's hit, deal 3 damage to it.",
		sub_image: 39,
		state: { busy: false },
	    trigger: function(event, data) {
			if (event == "on_hit_fully_blocked" && is_struct(data.enemy) && !data.enemy.dead && !self.state.busy) {
				self.state.busy = true; // its own hit can't set off another (an enemy with Spines hits back, you block it...)
				with (oCombat) process_action(data.enemy, 0, 3, 0, "player", -1, "ATK", undefined, undefined, 0);
				self.state.busy = false;
				trigger_keepsake_visual();
			}
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_spiked_hull);
	ds_list_add(global.rollable_keepsake_list, ks_spiked_hull);

	ks_weathervane = {
	    _id: "weathervane",
	    name: "Weathervane",
	    desc: "While alignment is below 30 or above 70, every die gets +1.",
		sub_image: 37,
	    trigger: function(event, data) {
			if (event == "on_roll_die" && (global.player_alignment < 30 || global.player_alignment > 70)) {
				data._d_amount += 1;
				if (!data.read_only) trigger_keepsake_visual();
			}
	    }
	};
	ds_list_add(global.master_keepsake_list, ks_weathervane);
	ds_list_add(global.rollable_keepsake_list, ks_weathervane);
	
	ks_cursed_heart = {
	    _id: "cursed_heart",
	    name: "Cursed Heart",
	    desc: "New slots cost 2 fewer pips.",
		sub_image: 38,
	    trigger: function(event, data) {
	        if (event == "on_combat_started") {
				oCombat.slot_cost_modifier -= 2; // pips (Jared, 2026-11-21: was +3)
					
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
		// some keepsakes replace another one, taking its exact spot in the keepsake bar
		var _replaced_index = -1;
		if (variable_struct_exists(_keepsake_struct, "replaces")) {
			for (var k = 0; k < ds_list_size(keepsakes); k++) {
				if (keepsakes[| k]._id == _keepsake_struct.replaces) {
					_replaced_index = k;
					break;
				}
			}
		}
		
		if (_replaced_index != -1) {
			keepsakes[| _replaced_index] = _keepsake_struct;
			if (_replaced_index < ds_list_size(keepsake_scale)) keepsake_scale[| _replaced_index] = 4.0; // same pop-in as a new keepsake
		} else {
			ds_list_add(keepsakes, _keepsake_struct);
		}
	
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
		
			if (index != -1) ds_list_delete( _list, index); // remove from future shop keepsakes
			show_debug_message("List length is now: " + string(ds_list_size(_list)));
		}
	}
	
	var ctx = {
		keepsake_id: _keepsake_struct._id,
	}
	
	runmanager_trigger_keepsakes("on_keepsake_acquired", ctx);
}