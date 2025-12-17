// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function enemy_create(_name, _index, _max_hp, _bounty, _moves_array, _move_order, _elite = false, _passive = undefined)
{
    var e = {
        name: _name,
        max_hp: _max_hp,
        current_hp: _max_hp,
        bounty: _bounty,
        moves: ds_list_create(),
		move_order: _move_order,
		elite: _elite,
		passive: _passive,
		index: _index // sEnemies index to draw in the room
    };
    
    // Copy all moves into its list
    for (var i = 0; i < array_length(_moves_array); i++) {
		ds_list_add(e.moves, _moves_array[i]);
    }
    
    return e;
}

function enemy_definitions() {
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
	var pirate_ruffian = enemy_create("Pirate Ruffian", 0, 21, 7, pirate_ruffian_moves, "pseudo_random");
	ds_list_add(global.enemy_list, pirate_ruffian);
	
	// Weak enemy that always copies the players last intent
	var parrot_moves = [
	    { dice_amount: 3, dice_value: 2, action_type: "MIMIC", bonus_amount: 1, move_name: "Mimic" },
	    { dice_amount: 3, dice_value: 2, action_type: "MIMIC", bonus_amount: 1, move_name: "Mimic" },
	];
	var parrot = enemy_create("Parrot", 0, 10, 5, parrot_moves, "pseudo_random");
	ds_list_add(global.enemy_list, parrot);
	
	// Spends 2 turns charging, third turn dealing big damage, then runs away on the final turn
	var peg_leg_moves = [
	    { dice_amount: 1, dice_value: 1, action_type: "NONE", bonus_amount: 0, move_name: "Stretching" },
	    { dice_amount: 1, dice_value: 1, action_type: "NONE", bonus_amount: 0, move_name: "Removing Leg" },
	    { dice_amount: 2, dice_value: 4, action_type: "ATK", bonus_amount: 14, move_name: "Throwing Leg" },
	    { dice_amount: 1, dice_value: 2, action_type: "EXIT", bonus_amount: 2, move_name: "Running Away" },
	];
	var peg_leg = enemy_create("Peg-leg", 0, 30, 20, peg_leg_moves, "ordered");
	ds_list_add(global.enemy_list, peg_leg);
	
	// Pack enemy that does attacks and defends
	var seagull_moves = [
	    { dice_amount: 2, dice_value: 2, action_type: "ATK", bonus_amount: -1, move_name: "Peck" },
	    { dice_amount: 1, dice_value: 2, action_type: "BLK", bonus_amount: 2, move_name: "Evade" },
	];
	var seagull = enemy_create("Seagull", 0, 8, 8, seagull_moves, "pseudo_random");
	ds_list_add(global.enemy_list, seagull);
	
	// Basic enemy that has attack, defend and a disabling debuff
	var baby_kraken_moves = [
	    { dice_amount: 2, dice_value: 2, action_type: "ATK", bonus_amount: 2, move_name: "Tentacle Whip" },
	    { dice_amount: 3, dice_value: 2, action_type: "BLK", bonus_amount: 0, move_name: "Coil" },
	    { dice_amount: 1, dice_value: 1, action_type: "DEBUFF", bonus_amount: 0, move_name: "Bind", debuff: debuff_bind, amount: 1, duration: 1 },
	];
	var baby_kraken = enemy_create("Baby Kraken", 0, 26, 16, baby_kraken_moves, "pseudo_random");
	ds_list_add(global.enemy_list, baby_kraken);
	
	// Basic enemy that has attack and defend.
	var deckhand_moves = [
	    { dice_amount: 1, dice_value: 6, action_type: "ATK", bonus_amount: 3, move_name: "Slash" }, // Slash
	    { dice_amount: 1, dice_value: 4, action_type: "BLK", bonus_amount: 4, move_name: "Duck" }  // Duck
	];
	var deckhand = enemy_create("Deckhand", 0, 29, 15, deckhand_moves, "pseudo_random");
	ds_list_add(global.enemy_list, deckhand);

	// Moderate enemy that has a debuff
	var thug_moves = [
	    { dice_amount: 2, dice_value: 4, action_type: "ATK", bonus_amount: 5, move_name: "Heavy Swing" }, // Heavy Swing
	    { dice_amount: 1, dice_value: 1, action_type: "DEBUFF", bonus_amount: 0, move_name: "Mock", debuff: debuff_mock, amount: 1, duration: 1 }, // Mock
	    { dice_amount: 1, dice_value: 4, action_type: "BLK", bonus_amount: 4, move_name: "Parry" }  // Duck
	];
	var thug = enemy_create("Thug", 1, 36, 17, thug_moves, "pseudo_random");
	ds_list_add(global.enemy_list, thug);

	// Comes in a pair with Bill, has a debuff, and a passive.
	var elizabeak_moves = [
	    { dice_amount: 1, dice_value: 1, action_type: "DEBUFF", bonus_amount: 0, move_name: "Flutter", debuff: buff_might, amount: -2, duration: 1, weight: 30},
	    { dice_amount: 2, dice_value: 2, action_type: "BLK/ATK", bonus_amount: 3, move_name: "Flap", weight: 70 },
	    { dice_amount: 2, dice_value: 2, action_type: "HEAL", bonus_amount: 3, move_name: "Rest", use_trigger: "HEALTH 50", weight: 0 },
	];
	var elizabeak = enemy_create("Elizabeak", 0, 16, 8, elizabeak_moves, "weighted", false, passive_heartache);
	ds_list_add(global.enemy_list, elizabeak);
	
	// Comes in a pair with Elizabeak, has a buff, and a passive.
	var bill_moves = [
	    { dice_amount: 2, dice_value: 3, action_type: "ATK", bonus_amount: 2, move_name: "Heavy Swing" }, // Heavy Swing
	    { dice_amount: 1, dice_value: 1, action_type: "BUFF", bonus_amount: 0, move_name: "Sharpen Cutlass", debuff: buff_might, amount: 1, duration: -1 }, // Mock
	    { dice_amount: 1, dice_value: 4, action_type: "BLK", bonus_amount: 4, move_name: "Parry" }  // Duck
	];
	var bill = enemy_create("Bill", 0, 20, 17, bill_moves, "pseudo_random", false, passive_heartache);
	ds_list_add(global.enemy_list, bill);
	
	// Moderate enemy with a first turn buff!
	var pufferfish_moves = [
	    { dice_amount: 3, dice_value: 4, action_type: "ATK", bonus_amount: 5, move_name: "Eject Spines", weight: 50 }, // Heavy Swing
	    { dice_amount: 1, dice_value: 1, action_type: "BUFF", bonus_amount: 0, move_name: "Inflate Spines", weight: 0, use_trigger: "FIRST", debuff: buff_spines, amount: 1, duration: -1 }, // Mock
	    { dice_amount: 2, dice_value: 4, action_type: "BLK", bonus_amount: 2, move_name: "Roll", weight: 50 }  // Duck
	];
	var pufferfish = enemy_create("Pufferfish", 0, 36, 17, pufferfish_moves, "weighted");
	ds_list_add(global.enemy_list, pufferfish);

	// Moderate enemy that aims, fires, reloads on a cycle.
	var gunner_moves = [
	    { dice_amount: 2, dice_value: 4, action_type: "BLK", bonus_amount: 5, move_name: "Take Aim" }, // Aim
	    { dice_amount: 3, dice_value: 4, action_type: "ATK", bonus_amount: 6, move_name: "Volley Fire" }, // Volley Fire
	    { dice_amount: 0, dice_value: 0, action_type: "NONE", bonus_amount: 0, move_name: "Reload" } // Reload
	];
	var gunner = enemy_create("Corsair Gunner", 0, 55, 19, gunner_moves, "ordered");
	ds_list_add(global.enemy_list, gunner);

	// Moderate enemy that builds up block over time, doesn't lose it between turns.
	var turtle_moves = [
	    { dice_amount: 2, dice_value: 2, action_type: "BLK", bonus_amount: 6, move_name: "Withdraw" }, // Aim
	    { dice_amount: 4, dice_value: 2, action_type: "ATK", bonus_amount: 4, move_name: "Claw" }, // Volley Fire
	    { dice_amount: 2, dice_value: 4, action_type: "BLK/ATK", bonus_amount: 1, move_name: "Rapid Spin" }, // Volley Fire
	];
	var turtle = enemy_create("Turtle", 0, 48, 18, turtle_moves, "pseudo_random", false, passive_turtle_shell);
	ds_list_add(global.enemy_list, turtle);
	
	// Support enemy that heals others and debuffs the player.
	var barrel_of_fish_moves = [
	    { dice_amount: 1, dice_value: 1, action_type: "DEBUFF", bonus_amount: 0, move_name: "Rot", debuff: debuff_rot, weight: 25, amount: 1, duration: 1  },
	    { dice_amount: 2, dice_value: 2, action_type: "HEAL", bonus_amount: 4, move_name: "Feeding Frenzy", weight: 25, target: "other" },
	    { dice_amount: 2, dice_value: 2, action_type: "ATK", bonus_amount: 0, move_name: "Snap", weight: 50 }
	];
	var barrel_of_fish = enemy_create("Barrel o' Fish", 0, 15, 10, barrel_of_fish_moves, "weighted");
	ds_list_add(global.enemy_list, barrel_of_fish);

	// Pack enemy that gets stronger when attacked, and messes with player focus.
	var driftnet_fish_moves = [
	    { dice_amount: 1, dice_value: 1, action_type: "BUFF", bonus_amount: 0, move_name: "Shiny Scales", debuff: buff_shiny_scales, amount: 1, duration: -1, weight: 0, use_trigger: "FIRST" },
	    { dice_amount: 2, dice_value: 2, action_type: "ATK", bonus_amount: 4, move_name: "Snap", weight: 75 },
	    { dice_amount: 2, dice_value: 2, action_type: "DEBUFF", bonus_amount: 1, move_name: "Overwhelm", debuff: debuff_overwhelm, weight: 25, amount: 3, duration: 1 }
	];
	var driftnet_fish = enemy_create("Driftnet Fish", 0, 18, 10, driftnet_fish_moves, "weighted");
	ds_list_add(global.enemy_list, driftnet_fish);
	
	// Elite that buffs others and summons minions to the fight.
	var pirate_captain_moves = [
	    { dice_amount: 1, dice_value: 1, action_type: "BUFF", bonus_amount: 0, move_name: "Command", debuff: buff_might, weight: 20, use_trigger: "FIRST", target: "other", amount: 1, duration: 2 }, // Command
	    { dice_amount: 3, dice_value: 4, action_type: "ATK", bonus_amount: 6, move_name: "Pistol Shot", weight: 40 }, // Take Cover
	    { dice_amount: 3, dice_value: 2, action_type: "BLK", bonus_amount: 8, move_name: "Take Cover", weight: 40 }, // Pistol Shot
	    { dice_amount: 1, dice_value: 1, action_type: "SUMMON", bonus_amount: 0, move_name: "Open Barrel", weight: 0, summon: "Barrel o' Fish", use_trigger: "HEALTH 50" } // Pistol Shot
	];
	var pirate_captain = enemy_create("Pirate Captain", 0, 70, 45, pirate_captain_moves, "weighted", true);
	ds_list_add(global.enemy_list, pirate_captain);


	// -------------------------------
	// TIER 3 — SEA MONSTROSITIES
	// -------------------------------

	var titan_moves = [
	    { dice_amount: 2, dice_value: 6, action_type: "ATK", bonus_amount: 6, move_name: "Crushing Slam" }, // Crushing Slam
	    { dice_amount: 2, dice_value: 6, action_type: "BLK", bonus_amount: 6, move_name: "Harden Shell" }, // Harden Shell
	    { dice_amount: 1, dice_value: 6, action_type: "DEBUFF", bonus_amount: 0, move_name: "Barnacle Bind", debuff: debuff_bind } // Mock
	];
	var titan = enemy_create("Barnacle Titan", 0, 125, 151, titan_moves, "pseudo_random");
	ds_list_add(global.enemy_list, titan);
}