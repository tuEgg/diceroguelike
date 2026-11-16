// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function enemy_create(_name, _index, _shadow_scale, _max_hp, _bounty, _starting_block, _moves_array, _move_order, _elite = false, _passive = undefined)
{
    var e = {
        name: _name,
        max_hp: _max_hp,
        current_hp: _max_hp,
        bounty: _bounty,
		starting_block: _starting_block,
        moves: ds_list_create(),
		move_order: _move_order,
		elite: _elite,
		passive: _passive,
		index: _index, // sEnemies index to draw in the room
		shadow_scale: _shadow_scale
    };
    
    // Copy all moves into its list
    for (var i = 0; i < array_length(_moves_array); i++) {
		ds_list_add(e.moves, _moves_array[i]);
    }
    
    return e;
}

function define_enemies() {
	// Create a global enemy list to hold all types
	global.enemy_list = ds_list_create();

	// -------------------------------
	// VOYAGE 1 ENEMIES
	// -------------------------------

	// Basic enemy that does attacks and defends
	var pirate_ruffian_moves = [
	    { dice_amount: 1, dice_value: 8, action_type: "ATK", bonus_amount: 1, move_name: "Pointed Cutlass" },
	    { dice_amount: 2, dice_value: 2, action_type: "BLK", bonus_amount: 3, move_name: "Block" },
	];
	var pirate_ruffian = enemy_create("Pirate Ruffian", 0, 1, 23, 7, 0, pirate_ruffian_moves, "pseudo_random");
	ds_list_add(global.enemy_list, pirate_ruffian);
	
	// Weak enemy that always copies the players last intent
	var parrot_moves = [
	    { dice_amount: 3, dice_value: 2, action_type: "MIMIC", bonus_amount: 1, move_name: "Mimic" },
	    { dice_amount: 3, dice_value: 2, action_type: "MIMIC", bonus_amount: 1, move_name: "Mimic" },
	];
	var parrot = enemy_create("Parrot", 7, 0.5, 10, 5, 0, parrot_moves, "pseudo_random");
	ds_list_add(global.enemy_list, parrot);
	
	// Spends 2 turns charging, third turn dealing big damage, then runs away on the final turn
	var peg_leg_moves = [
	    { dice_amount: 1, dice_value: 1, action_type: "NONE", bonus_amount: 0, move_name: "Stretching" },
	    { dice_amount: 1, dice_value: 1, action_type: "NONE", bonus_amount: 0, move_name: "Removing Leg" },
	    { dice_amount: 2, dice_value: 4, action_type: "ATK", bonus_amount: 14, move_name: "Throwing Leg" },
	    { dice_amount: 1, dice_value: 2, action_type: "EXIT", bonus_amount: 2, move_name: "Escaping" },
	];
	var peg_leg = enemy_create("Peg-leg", 0, 1, 18, 20, 0, peg_leg_moves, "ordered");
	ds_list_add(global.enemy_list, peg_leg);
	
	// Pack enemy that does attacks and defends
	var seagull_moves = [
	    { dice_amount: 2, dice_value: 2, action_type: "ATK", bonus_amount: -1, move_name: "Peck" },
	    { dice_amount: 1, dice_value: 2, action_type: "BLK", bonus_amount: 2, move_name: "Evade" },
	];
	var seagull = enemy_create("Seagull", 2, 0.5, 8, 8, 0, seagull_moves, "pseudo_random");
	ds_list_add(global.enemy_list, seagull);
	
	// Basic enemy that has attack, defend and a disabling debuff
	var baby_kraken_moves = [
	    { dice_amount: 2, dice_value: 2, action_type: "ATK", bonus_amount: 2, move_name: "Tentacle Whip" },
	    { dice_amount: 3, dice_value: 2, action_type: "BLK", bonus_amount: 0, move_name: "Coil" },
	    { dice_amount: 1, dice_value: 1, action_type: "DEBUFF", bonus_amount: 0, move_name: "Bind", debuff: debuff_bind, amount: 1, duration: 1 },
	];
	var baby_kraken = enemy_create("Baby Kraken", 3, 1, 26, 16, 0, baby_kraken_moves, "pseudo_random");
	ds_list_add(global.enemy_list, baby_kraken);
	
	// Basic enemy that has attack and defend.
	var deckhand_moves = [
	    { dice_amount: 1, dice_value: 6, action_type: "ATK", bonus_amount: 3, move_name: "Slash" }, // Slash
	    { dice_amount: 1, dice_value: 4, action_type: "BLK", bonus_amount: 4, move_name: "Duck" }  // Duck
	];
	var deckhand = enemy_create("Deckhand", 0, 1, 29, 15, 0, deckhand_moves, "pseudo_random");
	ds_list_add(global.enemy_list, deckhand);

	// Moderate enemy that has a debuff
	var thug_moves = [
	    { dice_amount: 2, dice_value: 4, action_type: "ATK", bonus_amount: 5, move_name: "Heavy Swing" }, // Heavy Swing
	    { dice_amount: 1, dice_value: 1, action_type: "DEBUFF", bonus_amount: 0, move_name: "Mock", debuff: debuff_mock, amount: 1, duration: 1 }, // Mock
	    { dice_amount: 1, dice_value: 4, action_type: "BLK", bonus_amount: 4, move_name: "Parry" }  // Duck
	];
	var thug = enemy_create("Thug", 1, 1, 36, 17, 0, thug_moves, "pseudo_random");
	ds_list_add(global.enemy_list, thug);

	// Comes in a pair with Bill, has a debuff, and a passive.
	var elizabeak_moves = [
	    { dice_amount: 1, dice_value: 1, action_type: "DEBUFF", bonus_amount: 0, move_name: "Flutter", debuff: buff_might, amount: -2, duration: 1, weight: 30},
	    { dice_amount: 2, dice_value: 2, action_type: "BLK/ATK", bonus_amount: 3, move_name: "Flap", weight: 70 },
	    { dice_amount: 2, dice_value: 2, action_type: "HEAL", bonus_amount: 3, move_name: "Rest", use_trigger: "HEALTH 50", weight: 0 },
	];
	var elizabeak = enemy_create("Elizabeak", 2, 1, 16, 8, 0, elizabeak_moves, "weighted", false, passive_heartache);
	ds_list_add(global.enemy_list, elizabeak);
	
	// Comes in a pair with Elizabeak, has a buff, and a passive.
	var bill_moves = [
	    { dice_amount: 2, dice_value: 3, action_type: "ATK", bonus_amount: 2, move_name: "Heavy Swing" }, // Heavy Swing
	    { dice_amount: 1, dice_value: 1, action_type: "BUFF", bonus_amount: 0, move_name: "Sharpen Cutlass", debuff: buff_might, amount: 1, duration: -1 }, // Mock
	    { dice_amount: 1, dice_value: 4, action_type: "BLK", bonus_amount: 4, move_name: "Parry" }  // Duck
	];
	var bill = enemy_create("Bill", 0, 1, 20, 17, 0, bill_moves, "pseudo_random", false, passive_heartache);
	ds_list_add(global.enemy_list, bill);
	
	// Moderate enemy with a first turn buff!
	var pufferfish_moves = [
	    { dice_amount: 3, dice_value: 4, action_type: "ATK", bonus_amount: 5, move_name: "Eject Spines", weight: 50 }, // Heavy Swing
	    { dice_amount: 1, dice_value: 1, action_type: "BUFF", bonus_amount: 0, move_name: "Inflate Spines", weight: 0, use_trigger: "FIRST", debuff: buff_spines, amount: 1, duration: -1 }, // Mock
	    { dice_amount: 2, dice_value: 4, action_type: "BLK", bonus_amount: 2, move_name: "Roll", weight: 50 }  // Duck
	];
	var pufferfish = enemy_create("Pufferfish", 0, 1, 36, 17, 0, pufferfish_moves, "weighted");
	ds_list_add(global.enemy_list, pufferfish);

	// Moderate enemy that aims, fires, reloads on a cycle.
	var gunner_moves = [
	    { dice_amount: 2, dice_value: 4, action_type: "BLK", bonus_amount: 5, move_name: "Take Aim" }, // Aim
	    { dice_amount: 3, dice_value: 4, action_type: "ATK", bonus_amount: 6, move_name: "Volley Fire" }, // Volley Fire
	    { dice_amount: 0, dice_value: 0, action_type: "NONE", bonus_amount: 0, move_name: "Reload" } // Reload
	];
	var gunner = enemy_create("Corsair Gunner", 5, 1, 35, 19, 0, gunner_moves, "ordered");
	ds_list_add(global.enemy_list, gunner);

	// Moderate enemy that builds up block over time, doesn't lose it between turns.
	var turtle_moves = [
	    { dice_amount: 2, dice_value: 2, action_type: "BLK", bonus_amount: 6, move_name: "Withdraw" }, // Aim
	    { dice_amount: 4, dice_value: 2, action_type: "ATK", bonus_amount: 4, move_name: "Claw" }, // Volley Fire
	    { dice_amount: 2, dice_value: 4, action_type: "BLK/ATK", bonus_amount: 1, move_name: "Rapid Spin" }, // Volley Fire
	];
	var turtle = enemy_create("Turtle", 0, 1, 20, 18, 32, turtle_moves, "pseudo_random", false, passive_turtle_shell);
	ds_list_add(global.enemy_list, turtle);
	
	// Support enemy that heals others and debuffs the player.
	var barrel_of_fish_moves = [
	    { dice_amount: 1, dice_value: 1, action_type: "DEBUFF", bonus_amount: 0, move_name: "Rot", debuff: debuff_rot, weight: 25, amount: 1, duration: 1  },
	    { dice_amount: 2, dice_value: 2, action_type: "HEAL", bonus_amount: 4, move_name: "Feeding Frenzy", weight: 25, target: "other" },
	    { dice_amount: 2, dice_value: 2, action_type: "ATK", bonus_amount: 0, move_name: "Snap", weight: 50 }
	];
	var barrel_of_fish = enemy_create("Barrel o' Fish", 4, 1, 15, 10, 0, barrel_of_fish_moves, "weighted");
	ds_list_add(global.enemy_list, barrel_of_fish);

	// Pack enemy that gets stronger when attacked, and messes with player focus.
	var driftnet_fish_moves = [
	    { dice_amount: 1, dice_value: 1, action_type: "BUFF", bonus_amount: 0, move_name: "Shiny Scales", debuff: buff_shiny_scales, amount: 1, duration: -1, weight: 0, use_trigger: "FIRST" },
	    { dice_amount: 1, dice_value: 2, action_type: "ATK", bonus_amount: 3, move_name: "Snap", weight: 75 },
	    { dice_amount: 2, dice_value: 2, action_type: "DEBUFF", bonus_amount: 1, move_name: "Overwhelm", debuff: debuff_overwhelm, weight: 25, amount: 3, duration: 1 }
	];
	var driftnet_fish = enemy_create("Driftnet Fish", 6, 1, 18, 10, 0, driftnet_fish_moves, "weighted");
	ds_list_add(global.enemy_list, driftnet_fish);
	
	// -------------------------------
	// ELITES
	// -------------------------------
	
	// Elite that buffs others and summons minions to the fight.
	var pirate_captain_moves = [
	    { dice_amount: 1, dice_value: 1, action_type: "BUFF", bonus_amount: 0, move_name: "Command", debuff: buff_might, weight: 20, use_trigger: "FIRST", target: "other", amount: 1, duration: 1 }, // Command
	    { dice_amount: 3, dice_value: 4, action_type: "ATK", bonus_amount: 6, move_name: "Pistol Shot", weight: 40 }, // Take Cover
	    { dice_amount: 3, dice_value: 2, action_type: "BLK", bonus_amount: 8, move_name: "Take Cover", weight: 40 }, // Pistol Shot
	    { dice_amount: 1, dice_value: 1, action_type: "SUMMON", bonus_amount: 0, move_name: "Open Barrel", weight: 0, summon: "Barrel o' Fish", use_trigger: "HEALTH 50" } // Pistol Shot
	];
	var pirate_captain = enemy_create("Pirate Captain", 0, 1.2, 70, 45, 0, pirate_captain_moves, "weighted", true);
	ds_list_add(global.enemy_list, pirate_captain);
	
	// Elite that disrupts intel, echoes attacks, and has 3 protective layers that block damage. The layers block 2/3/4 flat damage per attack but once the conch takes 10/12/14 damage in a single turn a layer is broken.
	var giant_conch_moves = [
	    { dice_amount: 1, dice_value: 1, action_type: "BUFF", bonus_amount: 0, move_name: "Command", debuff: buff_might, weight: 20, use_trigger: "FIRST", target: "other", amount: 1, duration: 1 }, // Command
		//{ dice_amount: 3, dice_value: 2, action_type: "ATK", bonus_amount: 4, move_name: "Wrap", weight: 100 },
	    //{ dice_amount: 3, dice_value: 2, action_type: "BLK", bonus_amount: 4, move_name: "Shield", weight: 40 }
	];
	var giant_conch = enemy_create("Giant Conch", 0, 1.25, 40, 50, 0, giant_conch_moves, "weighted", true, passive_conch_layers);
	ds_list_add(global.enemy_list, giant_conch);
	
	//// Elite that buffs others and summons minions to the fight.
	//var pirate_captain_moves = [
	//    { dice_amount: 1, dice_value: 1, action_type: "BUFF", bonus_amount: 0, move_name: "Command", debuff: buff_might, weight: 20, use_trigger: "FIRST", target: "other", amount: 1, duration: 2 }, // Command
	//    { dice_amount: 3, dice_value: 4, action_type: "ATK", bonus_amount: 6, move_name: "Pistol Shot", weight: 40 }, // Take Cover
	//    { dice_amount: 3, dice_value: 2, action_type: "BLK", bonus_amount: 8, move_name: "Take Cover", weight: 40 }, // Pistol Shot
	//    { dice_amount: 1, dice_value: 1, action_type: "SUMMON", bonus_amount: 0, move_name: "Open Barrel", weight: 0, summon: "Barrel o' Fish", use_trigger: "HEALTH 50" } // Pistol Shot
	//];
	//var pirate_captain = enemy_create("Pirate Captain", 0, 1, 70, 45, 0, pirate_captain_moves, "weighted", true);
	//ds_list_add(global.enemy_list, pirate_captain);


	// -------------------------------
	// BOSSES
	// -------------------------------

	var titan_moves = [
	    { dice_amount: 2, dice_value: 6, action_type: "ATK", bonus_amount: 6, move_name: "Crushing Slam" }, // Crushing Slam
	    { dice_amount: 2, dice_value: 6, action_type: "BLK", bonus_amount: 6, move_name: "Harden Shell" }, // Harden Shell
	    { dice_amount: 1, dice_value: 6, action_type: "DEBUFF", bonus_amount: 0, move_name: "Barnacle Bind", debuff: debuff_barnacle_bind, amount: 1, duration: 1 } // Barnacle Bind
	];
	var titan = enemy_create("Barnacle Titan", 0, 1.5, 125, 151, 0, titan_moves, "pseudo_random");
	ds_list_add(global.enemy_list, titan);
}

/// @func enemy_copy_for_fight(_enemy)
/// @desc Returns a copy of an enemy definition with its own move list and its own move structs.
///       The buff templates the moves point at are shared on purpose, apply_buff clones those itself.
function enemy_copy_for_fight(_enemy) {
	var _copy = {};
	var _names = variable_struct_get_names(_enemy);
	for (var i = 0; i < array_length(_names); i++) {
		variable_struct_set(_copy, _names[i], variable_struct_get(_enemy, _names[i]));
	}
	
	_copy.moves = ds_list_create();
	for (var m = 0; m < ds_list_size(_enemy.moves); m++) {
		var _move = _enemy.moves[| m];
		var _move_copy = {};
		var _move_names = variable_struct_get_names(_move);
		for (var i = 0; i < array_length(_move_names); i++) {
			variable_struct_set(_move_copy, _move_names[i], variable_struct_get(_move, _move_names[i]));
		}
		ds_list_add(_copy.moves, _move_copy);
	}
	
	return _copy;
}


/// @func enemy_set_intent(_enemy, _move)
/// @desc Sets what an enemy will do this turn, and rolls its dice now. The rolls are kept on the intent so
///       intel level II can show the exact result in advance, and the enemy's turn uses those same rolls.
function enemy_set_intent(_enemy, _move) {
	_enemy.intent.move = _move;
	_enemy.intent.fumbled = false; // a new intent hasn't been outguessed

	_enemy.intent.rolls = [];
	repeat (max(0, _move.dice_amount)) {
		array_push(_enemy.intent.rolls, irandom_range(1, max(1, _move.dice_value)));
	}

	// the range shown at intel level I (and the name shown for moves with no numbers)
	if (_move.action_type == "DEBUFF" || _move.action_type == "BUFF") {
		_enemy.intent.text = "";
	} else if (_move.action_type == "NONE" || _move.action_type == "EXIT") {
		_enemy.intent.text = _move.move_name;
	} else {
		_enemy.intent.text = string(_move.dice_amount + _move.bonus_amount) + "-" + string((_move.dice_amount * _move.dice_value) + _move.bonus_amount);
	}
}

/// @func intent_has_numbers(_move)
/// @desc Attacks, blocks and heals have numbers to reveal; buffs, debuffs, waiting and fleeing don't.
function intent_has_numbers(_move) {
	return !(_move.action_type == "DEBUFF" || _move.action_type == "BUFF" || _move.action_type == "NONE" || _move.action_type == "EXIT");
}

/// @func intent_exact_value(_enemy)
/// @desc What the enemy's move will come to, from the rolls made when the intent was set, plus its bonus and
///       any of its own buffs that change rolls (Might, Balance). Shown at intel level II.
function intent_exact_value(_enemy) {
	var _total = intent_rolled_value(_enemy);
	return intent_is_fumbled(_enemy) ? _total div 2 : _total;
}

/// @func intent_is_fumbled(_enemy)
/// @desc Has the player outguessed this enemy's intent this turn (it does half)?
function intent_is_fumbled(_enemy) {
	return variable_struct_exists(_enemy.intent, "fumbled") && _enemy.intent.fumbled;
}

/// @func intent_rolled_value(_enemy)
/// @desc What the enemy's move comes to before any fumble: rolls + bonus + its own roll buffs.
function intent_rolled_value(_enemy) {
	var _move = _enemy.intent.move;
	var _type = string_split(_move.action_type, "/")[0];
	if (_type == "MIMIC") _type = oCombat.player_last_action_type;

	var _total = 0;
	for (var i = 0; i < array_length(_enemy.intent.rolls); i++) {
		var _ctx = { _d_amount: _enemy.intent.rolls[i], action_type: _type, owner: _enemy, target: _enemy };
		trigger_debuff_list(_enemy.debuffs, "on_roll_die", _ctx); // on_roll_die only adjusts the roll, it never counts buffs down
		_total += _ctx._d_amount;
	}
	return _total + _move.bonus_amount;
}

/// @func intent_number_text(_enemy, _intel_level)
/// @desc The number shown beside an enemy's intent: "?" with no intel, the range at level I, the exact result from level II.
function intent_number_text(_enemy, _intel_level) {
	if (!intent_has_numbers(_enemy.intent.move)) return _enemy.intent.text;
	if (_intel_level >= 2) return string(intent_exact_value(_enemy));
	if (_intel_level >= 1) {
		if (!intent_is_fumbled(_enemy)) return _enemy.intent.text;
		var _move = _enemy.intent.move;
		return string((_move.dice_amount + _move.bonus_amount) div 2) + "-" + string(((_move.dice_amount * _move.dice_value) + _move.bonus_amount) div 2);
	}
	return "?";
}



// =====================================================================
// PICKING AND PLANNING MOVES
// Each turn an enemy follows the move it planned last turn, then plans the next one, so intel level III can
// show it. Triggered moves (FIRST, HEALTH 50, PRIORITY, Stunned) still override the plan when they fire.
// =====================================================================

/// @func enemy_pick_move_index(_enemy, _latest_extra)
/// @desc Choose the index of an enemy's next move by its move_order. _latest_extra is a move to count as the
///       most recent one (this turn's, when planning next turn), or undefined.
function enemy_pick_move_index(_enemy, _latest_extra) {
	var _data = _enemy.data;
	var _index = 0;

	if (_data.move_order == "true_random") {
		_index = irandom(ds_list_size(_data.moves) - 1);
	} else if (_data.move_order == "ordered") {
		// the move after the current one (reading only: planning a turn ahead must not move the enemy along)
		if (_enemy.move_number < ds_list_size(_data.moves) - 1) {
			_index = _enemy.move_number + 1;
		} else {
			_index = 0;
		}
	} else if (_data.move_order == "weighted") {
		var num_moves = ds_list_size(_data.moves);

		var weighted = [];
		array_resize(weighted, num_moves);

		for (var i = 0; i < num_moves; i++) {
		    weighted[i] = {
		        value: i,
		        weight: _data.moves[| i].weight  // or 1 if no weight
		    };
		}

		_index = choose_weighting_list(weighted);

	} else if (_data.move_order == "pseudo_random") {
		// look through three latest moves, don't allow for 4 in a row, and weight odds to something else after every move
		var latest_moves = [];
		var move_index_avoid = -1;
		var move_index_completely_avoid = -1;
		var move_index = irandom(ds_list_size(_data.moves) - 1);
		
		// Add last 3 moves name to array; NEED TO FIX SO THAT IT FLEXES TO LIST SIZE
		if (_latest_extra != undefined) array_push(latest_moves, _latest_extra); // planning next turn: this turn's move is the latest
		var num_previous_moves = ds_list_size(_enemy.move_history);
		for (var m = num_previous_moves; m > max(0, num_previous_moves - 3) && array_length(latest_moves) < 3; m--) {
			var move = _enemy.move_history[| m - 1];
		
			array_push(latest_moves, move);
		}
	
		if (array_length(latest_moves) > 0) {
			// only counts once we have three moves of history and every one of them matches
			var all_same = (array_length(latest_moves) == 3);
		
			for (var o = 0; o < array_length(latest_moves); o++) {
				if (latest_moves[o] != latest_moves[0]) {
					all_same = false;
				}
			}
			// If all three moves are the same
			if (all_same) {
				for (var i = 0; i < ds_list_size(_data.moves); i++) {
					if (latest_moves[0].move_name == _data.moves[| i].move_name) move_index_completely_avoid = i;
				}
			} else {
				// just avoid the last move
				for (var i = 0; i < ds_list_size(_data.moves); i++) {
					if (latest_moves[0].move_name == _data.moves[| i].move_name) {
						move_index_avoid = i;
					}
				}
			}
	
			// If we are avoiding a move
			if (move_index_completely_avoid != -1) {
				// Randomise until we don't get that index
				var rand_index;
				
				do {
					rand_index = irandom(ds_list_size(_data.moves) - 1);
				} until (rand_index != move_index_completely_avoid);
				
				move_index = rand_index;
			// otherwise
			} else if (move_index_avoid != -1) {
				// randomise twice and if the first one is our index, take the second regardless
				var rand_1 = irandom(ds_list_size(_data.moves) - 1);
				var rand_2 = irandom(ds_list_size(_data.moves) - 1);
		
				if (rand_1 == move_index_avoid) {
					move_index = rand_2;
				} else {
					move_index = rand_1;
				}
			}
		}
	
		_index = move_index;
	}

	return _index;
}

/// @func enemy_plan_next_move(_enemy)
/// @desc Decide now what the enemy will do next turn (after its current intent).
function enemy_plan_next_move(_enemy) {
	var _index = enemy_pick_move_index(_enemy, _enemy.intent.move);
	_enemy.planned_move = _enemy.data.moves[| _index];
}

/// @func enemy_can_rewrite_intent(_enemy)
/// @desc Intel level IV: can this enemy's intent be rewritten? Forced moves (triggers, Stunned) can't, and
///       nor can an enemy with only one move to choose from.
function enemy_can_rewrite_intent(_enemy) {
	if (variable_struct_exists(_enemy.intent.move, "use_trigger")) return false;
	return array_length(enemy_rewrite_options(_enemy)) > 0;
}

/// @func enemy_rewrite_options(_enemy)
/// @desc The moves a rewritten intent can become: the enemy's own untriggered moves, other than the current one.
function enemy_rewrite_options(_enemy) {
	var _options = [];
	var _moves = _enemy.data.moves;
	for (var i = 0; i < ds_list_size(_moves); i++) {
		var _move = _moves[| i];
		if (_move == _enemy.intent.move || _move.move_name == _enemy.intent.move.move_name) continue;
		if (variable_struct_exists(_move, "use_trigger")) continue;
		array_push(_options, i);
	}
	return _options;
}

/// @func enemy_rewrite_intent(_enemy)
/// @desc Intel level IV: the enemy chooses again, a different move, rolled fresh. Its plan for next turn is redone too.
function enemy_rewrite_intent(_enemy) {
	var _options = enemy_rewrite_options(_enemy);
	if (array_length(_options) == 0) return false;
	var _index = _options[irandom(array_length(_options) - 1)];
	_enemy.move_number = _index;
	enemy_set_intent(_enemy, _enemy.data.moves[| _index]);
	enemy_plan_next_move(_enemy);
	return true;
}

/// @func intent_icon(_move)
/// @desc The sprite, frame and colour for a move's intent icon (used for the small next-turn icon).
function intent_icon(_move) {
	var _type = string_split(_move.action_type, "/")[0];
	switch (_type) {
		case "ATK": return { sprite: sIntentIcons, index: 0, col: global.color_attack };
		case "BLK": return { sprite: sIntentIcons, index: 1, col: global.color_block };
		case "HEAL": return { sprite: sIntentIcons, index: 2, col: global.color_heal };
		case "EXIT": return { sprite: sIntentIcons, index: 5, col: c_orange };
		case "DEBUFF": case "BUFF":
			if (variable_struct_exists(_move, "debuff")) return { sprite: sDebuffIcon, index: _move.debuff.icon_index, col: _move.debuff.color };
			return { sprite: sIntentIcons, index: 3, col: c_white };
		case "NONE": return { sprite: sIntentIcons, index: 3, col: c_white };
	}
	return { sprite: sIntentIcons, index: 4, col: c_dkgray };
}


/// @func intel_try_outguess(_slot_number, _dice_list_index)
/// @desc Intel's this-turn effect. As an intel slot resolves, if its total so far is at least the targeted
///       enemy's intended number (before any fumble), that enemy fumbles: its move does half this turn.
///       Only attacks, blocks and heals can be outguessed, and each intent only once.
function intel_try_outguess(_slot_number, _dice_list_index) {
	if (_slot_number < 0) return;
	with (oCombat) {
		if (enemy_target_index < 0 || enemy_target_index >= ds_list_size(room_enemies)) return;
		var _enemy = room_enemies[| enemy_target_index];
		if (_enemy.dead || !intent_has_numbers(_enemy.intent.move) || intent_is_fumbled(_enemy)) return;

		var _slot = action_queue[| _slot_number];
		var _total = 0;
		for (var d = 0; d <= min(_dice_list_index, ds_list_size(_slot.dice_list) - 1); d++) {
			var _die = _slot.dice_list[| d];
			if (variable_struct_exists(_die, "rolled_value")) _total += _die.rolled_value;
		}

		if (_total >= intent_rolled_value(_enemy)) {
			_enemy.intent.fumbled = true;
			spawn_floating_number(_enemy, 0, "Outguessed!", c_orange, 0);
			particle_emit(_enemy.pos_x, _enemy.pos_y - 100, "burst", c_orange);
			add_feed_entry("Your intel outguessed " + string(_enemy.data.name) + ": " + string(_enemy.intent.move.move_name) + " does half.");
		}
	}
}
